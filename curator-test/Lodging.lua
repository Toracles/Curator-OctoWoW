local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0, after its test, his word: the innkeeper redone, he must matter in the game of each player) What the inns
-- give for the time played, beside the loyalty card (Inns.lua) and the life of the tavern (Tavern.lua):
-- * the rest of the collector: logged out in a place of rest (an inn, a capital: the game says so, IsResting), the
--   account rests, one creature of rest every LG.REST_EVERY seconds (100 every 8 hours), LG.REST_MAX at most; online
--   in a place of rest, the same. Rested, a creature defeated has twice the chance to give its card (Rewards.lua:
--   R:Find, through Tavern.lua: T:FindChance), one creature of rest spent for each creature that has a card there
--   (never a boss, a mythic card, a card of an event; never on a reroll: Reroll.lua). Never a booster: his word.
-- * the dish of the day: each innkeeper serves his own each day (LG:DishOf: the same all day, another at the next
--   inn), offered with the stamp of the day (Inns.lua: I:Stamp), one a day for the account. It lasts while the
--   collector plays (not on a reroll: it waits), longer as the loyalty of that innkeeper grows (LG.DISH_TIME); a new
--   one takes the place of the one before (the same dish: its time added). What it does (LG.DISHES): the cards of the
--   creatures, those of the elites and the rares of the world, the cases, the leads of the tavern, the cards the
--   collection is missing; never on a boss, a mythic card, a card of an event, nor on what a booster gives.
-- The rest, the dish and the lead of a card together count LG.CAP times at most.
-- What is kept, with the inns (db.inns, sealed with the rest of the save): rest = { n (creatures of rest), b (the
-- most at once), out (the moment of the logout), at (1: logged out in a place of rest) }; dish = { k (the dish), n
-- (its innkeeper), d (the day it was taken), left (its seconds left) }; tasted = { [dish] = the first time }.
-------------------------------------------------------------------------------
local LG = {}
ns.Lodging = LG
local I = ns.Inns

LG.REST_MAX = 300
LG.REST_EVERY = 288 -- seconds for a creature of rest: 100 every 8 hours
LG.REST_FIND = 2    -- rested: twice the chance
LG.CAP = 6          -- the rest, the dish and a lead together, at most
-- (the time of the dish: by the rank of loyalty at its innkeeper, passing guest to friend of the house)
LG.DISH_TIME = { 3600, 5400, 7200, 10800 }
-- The dishes: the item of the game whose icon they wear (else an icon of the game), what they do.
LG.DISHES = {
	{ key = "stew", name = "Hunter's Stew", item = 733, icon = "Interface\\Icons\\INV_Misc_Food_15", find = 2,
		text = "The cards of the creatures: twice as easy to find." },
	{ key = "pie", name = "Poacher's Pie", item = 724, icon = "Interface\\Icons\\INV_Misc_Food_14", elite = 3,
		text = "The elites and the rare creatures of the world: their card three times as easy to find." },
	{ key = "ale", name = "Ironforge Ale", item = 2686, icon = "Interface\\Icons\\INV_Drink_05", cases = 2,
		text = "Twice as many cases from the creatures and the quests you turn in." },
	{ key = "skewers", name = "Tracker's Skewers", item = 5472, icon = "Interface\\Icons\\INV_Misc_Food_19", lead = 2,
		text = "The cards of your leads: twice as easy to find again (six times in all)." },
	{ key = "biscuit", name = "Explorer's Biscuit", item = 4544, icon = "Interface\\Icons\\INV_Misc_Food_11", missing = 3,
		text = "The cards missing from your collection: three times as easy to find on their creatures." },
}
LG.BY = {}
for i, d in ipairs(LG.DISHES) do
	d.i = i
	LG.BY[d.key] = d
end

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- Nothing to earn: a beta past its day, a collection suspended, an update missed.
local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-- The rest and the dish wait on a reroll (Reroll.lua: it earns a quarter of everything, in its chest).
local function Waiting()
	local RR = ns.Reroll
	return RR ~= nil and RR.IsReroll ~= nil and RR:IsReroll() == true
end
LG.Waiting = Waiting

-- The place of rest the character stands in (an inn, a capital), as the game says it.
local function Resting()
	if not IsResting then
		return false
	end
	local ok, on = pcall(IsResting)
	return ok and on == true
end
LG.Resting = Resting

-- What the lodging keeps with the inns.
function LG:State()
	local s = I and I:State()
	if not s then
		return nil
	end
	if type(s.rest) ~= "table" then
		s.rest = {}
	end
	s.rest.n = math.max(0, math.min(self.REST_MAX, tonumber(s.rest.n) or 0))
	s.rest.b = math.max(math.floor(s.rest.n), tonumber(s.rest.b) or 0)
	if type(s.tasted) ~= "table" then
		s.tasted = {}
	end
	return s
end

-------------------------------------------------------------------------------
-- The rest
-------------------------------------------------------------------------------
-- The creatures of rest (whole ones), and the most there can be.
function LG:Rest()
	local s = self:State()
	return s and math.floor(s.rest.n) or 0, self.REST_MAX
end

function LG:Rested()
	return self:Rest() >= 1 and not Waiting()
end

-- Rest gained: so many seconds rested. The creatures of rest gained (whole ones, nil: none).
function LG:AddRest(seconds)
	local s = self:State()
	seconds = tonumber(seconds) or 0
	if not s or seconds <= 0 or Closed() then
		return nil
	end
	local before = s.rest.n
	s.rest.n = math.min(self.REST_MAX, before + seconds / self.REST_EVERY)
	if math.floor(s.rest.n) > (tonumber(s.rest.b) or 0) then
		s.rest.b = math.floor(s.rest.n)
	end
	local got = math.floor(s.rest.n) - math.floor(before)
	if got > 0 then
		ns.Fire("REST_CHANGED", math.floor(s.rest.n), got)
		return got
	end
	return nil
end

-- A creature of rest spent (a creature that has a card, defeated rested). True when there was one.
function LG:SpendRest()
	local s = self:State()
	if not s or s.rest.n < 1 or Waiting() then
		return false
	end
	s.rest.n = s.rest.n - 1
	local st = ns.Stats()
	st.restUsed = (tonumber(st.restUsed) or 0) + 1
	if s.rest.n < 1 then
		ns.Fire("REST_CHANGED", 0, 0)
	elseif CuratorOctoFull.Mod(math.floor(s.rest.n) , 10) == 0 then
		ns.Fire("REST_CHANGED", math.floor(s.rest.n), 0)
	end
	return true
end

-- The logout: when, and whether in a place of rest (the rest comes at the next login).
function LG:OnLogout()
	local s = self:State()
	if not s then
		return
	end
	s.rest.out = Now()
	s.rest.at = Resting() and 1 or nil
end

-- The login: the rest of the time away, when the logout was in a place of rest. What came (nil: nothing).
function LG:OnLogin()
	local s = self:State()
	if not s then
		return nil
	end
	local out, at = tonumber(s.rest.out), s.rest.at
	s.rest.out, s.rest.at = nil, nil
	if not (out and at) then
		return nil
	end
	local away = Now() - out
	if away <= 0 then
		return nil
	end
	local got = self:AddRest(away)
	if got then
		ns.Fire("REST_GAINED", got, math.floor(s.rest.n), away)
	end
	return got
end

-------------------------------------------------------------------------------
-- The dish of the day
-------------------------------------------------------------------------------
-- The dish an innkeeper serves this day (the same all day; another one tomorrow, another one at the next inn).
function LG:DishOf(npc, day)
	day = math.floor(tonumber(day) or (I:Today() or 0))
	local x = CuratorOctoFull.Mod((day * 31337 + (tonumber(npc) or 0) * 7919 + 101) , 2147483647)
	for _ = 1, 3 do
		x = CuratorOctoFull.Mod((x * 48271) , 2147483647)
	end
	return self.DISHES[CuratorOctoFull.Mod(x , CuratorOctoFull.Length(self.DISHES)) + 1]
end

-- The dish under way: its definition, its seconds left, its innkeeper, and true when it waits (a reroll). Nil: none.
function LG:Dish()
	local s = self:State()
	local d = s and s.dish
	if type(d) ~= "table" then
		return nil
	end
	local def = self.BY[d.k]
	local left = tonumber(d.left) or 0
	if not def or left <= 0 then
		return nil
	end
	return def, left, tonumber(d.n), Waiting()
end

-- The dish of this key, under way (and not waiting): its definition.
function LG:Active(key)
	local def, _, _, waiting = self:Dish()
	if def and not waiting and (key == nil or def.key == key) then
		return def
	end
	return nil
end

-- The time of the dish of an innkeeper, for the collector: by his loyalty there.
function LG:DishTime(npc)
	local _, r = I:Loyalty(npc)
	return self.DISH_TIME[math.max(1, math.min(CuratorOctoFull.Length(self.DISH_TIME), r))]
end

-- The dish of the day taken already (with the stamp of the day).
function LG:TakenToday()
	local s = self:State()
	return s ~= nil and type(s.dish) == "table" and s.dish.d == I:Today()
end

-- The dish of an innkeeper, offered with the stamp of the day (Inns.lua). What came: { def, npc, time (its seconds,
-- with what was left of the same dish), was (the dish it took the place of, still under way), more (its time added
-- to the same dish) } (nil when nothing can be earned).
function LG:Take(npc)
	local s = self:State()
	if not s or Closed() or type(npc) ~= "number" then
		return nil
	end
	local def = self:DishOf(npc)
	local t = self:DishTime(npc)
	local was, left = self:Dish()
	local out = { def = def, npc = npc }
	if was and was.key == def.key then
		t = t + left
		out.more = true
	elseif was then
		out.was = was
	end
	s.dish = { k = def.key, n = npc, d = I:Today(), left = t }
	out.time = t
	local first = s.tasted[def.key] == nil
	if first then
		s.tasted[def.key] = Now()
	end
	out.first = first
	local st = ns.Stats()
	st.dishes = (tonumber(st.dishes) or 0) + 1
	ns.Fire("DISH_TAKEN", out)
	ns.Fire("CHANGED")
	return out
end

-- The dishes tasted: how many of them.
function LG:Tasted()
	local s = self:State()
	local n = 0
	for key in pairs(s and s.tasted or {}) do
		if self.BY[key] then
			n = n + 1
		end
	end
	return n
end

-- The time played goes by for the dish (not on a reroll).
function LG:Tick(seconds)
	local s = self:State()
	local d = s and s.dish
	if type(d) ~= "table" or (tonumber(d.left) or 0) <= 0 or Waiting() then
		return
	end
	d.left = math.max(0, (tonumber(d.left) or 0) - seconds)
	if d.left <= 0 then
		local def = self.BY[d.k]
		d.left = 0
		ns.Fire("DISH_ENDED", def)
		ns.Fire("CHANGED")
	end
end

-- The time of a dish as the language writes it: "1 h 30 min", and a whole hour "2 h" (not "2 h 0 min").
function LG.Duration(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 3600 and sec < 86400 and math.floor(CuratorOctoFull.Mod(sec , 3600) / 60) == 0 then
		return string.format(L["%d h"], math.floor(sec / 3600))
	end
	return ns.Duration(sec)
end

-- The name, the effect and the icon of a dish, as the language writes them.
function LG:Name(def)
	return def and L[def.name] or ""
end

function LG:Text(def)
	return def and L[def.text] or ""
end

function LG:Icon(def)
	if not def then
		return nil
	end
	if def.item then
		local fn = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
		if fn then
			local ok, icon = pcall(fn, def.item)
			if ok and icon and icon ~= 0 and icon ~= "" then
				return icon
			end
		end
	end
	return def.icon
end

-------------------------------------------------------------------------------
-- What the rest and the dish do to the chance of a card on its creature (Tavern.lua: T:FindChance), with k what the
-- lead of the tavern did already (1: no lead). Never a boss, a mythic card, a card of an event; never on a reroll. The
-- times the chance is multiplied, LG.CAP at most (the rest is spent only when it adds something).
-------------------------------------------------------------------------------
function LG:FindMult(card, ctx, boss, k, lead)
	k = tonumber(k) or 1
	if not card or boss or (card.rarity or 0) >= 6 or (card.series and card.series.event) or Waiting() then
		return k
	end
	local def = self:Active()
	if def then
		if def.find then
			k = k * def.find
		elseif def.elite and not (card.series and card.series.dungeon) then
			local elite = ctx and (ctx.elite or ctx.rare)
			if elite == nil then
				elite = (ns.ELITE and ns.ELITE[card.npc]) or (ns.RARE and ns.RARE[card.npc]) or false
			end
			if elite then
				k = k * def.elite
			end
		elseif def.lead and lead then
			k = k * def.lead
		elseif def.missing and ns.Collection and not ns.Collection:Owned(card) then
			k = k * def.missing
		end
	end
	k = math.min(k, self.CAP)
	if k < self.CAP and self:Rested() and self:SpendRest() then
		k = math.min(k * self.REST_FIND, self.CAP)
	end
	return k
end

-- The chance of a case (Cases.lua: how, "kill" or "quest"): twice with the ale.
function LG:CaseMult(how)
	local def = (how == "kill" or how == "quest") and self:Active() or nil
	return (def and def.cases) or 1
end

-------------------------------------------------------------------------------
-- Wiring: the logout, the login, the time played (the dish), the rest online in a place of rest
-------------------------------------------------------------------------------
ns.On("LOGOUT", function()
	LG:OnLogout()
end)

ns.On("LOGIN", function()
	LG:OnLogin()
	LG.ticking = true
end)

local clock = CreateFrame("Frame")
clock.t, clock.rest = 0, 0
CuratorOctoFull.SetScript(clock, "OnUpdate", function(self, elapsed)
	if not (LG.ticking and ns.db) then
		return
	end
	self.t = self.t + elapsed
	if self.t >= 5 then
		local dt = self.t
		self.t = 0
		LG:Tick(dt)
		self.rest = self.rest + dt
		if self.rest >= 60 then
			local r = self.rest
			self.rest = 0
			if Resting() then
				LG:AddRest(r)
			end
		end
	end
end)
LG.clock = clock
