local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.11.0) The rubies: the money of the collector. They come from playing, never from the duplicates: the
-- quests (each board its own: Quests.lua), the achievements (for each of their points, with their
-- experience), the levels of the collector (and more for a new rank), the golden quests; (1.14.0) each quest of the
-- game turned in, after the money it gives (RB:OfTurnIn). They buy the
-- contract of reconversion of the talents (Talents.lua), a quest changed for another (Quests.lua), a rumor
-- of the tavern about the card chosen (Tavern.lua), a booster to choose (here, a few a week) and the
-- expertise of a card (Expertise.lua). They are the account's, as the collection, and do not go into the
-- trades. What is kept: db.rubies (how many), db.ruby (the boosters bought this week, the catch-up of
-- 1.11.0) and the counters of their achievements (ns.Stats: rubies earned and spent, quests changed,
-- rumors and boosters bought, cards appraised), all of it under the seal of the save. (1.12.0) The reseller, at the
-- vendors of general goods, sells cards for them, and buys back the copies to spare for a few, a few a day (the
-- only rubies that come from duplicates: Reseller.lua); the antiquarian of 1.11.0 is gone.
-------------------------------------------------------------------------------
local RB = {}
ns.Rubies = RB

RB.ICON = ns.MEDIA .. "Ruby"
-- (1.13.0, after its second test: the economy redone around one purchase, the display of a zone (25 000, Displays.lua),
-- the week of a player of 3 to 5 hours a day at most; everything ten times as much, or about, and a guard against the
-- players of twelve hours a day: RB.GUARD. Before: 2, 25, 200, 400; the boosters to choose 750, 1500, 3000.)
-- what they come from
RB.PER_POINT = 20   -- an achievement claimed: for each of its points
RB.PER_LEVEL = 250  -- a level of collector claimed on the track
RB.PER_RANK = 2000  -- and more for a new rank (every five levels)
RB.GOLDEN = 4000    -- a golden quest turned in
-- (1.14.0, his word, after a player's: an album complete must be worth the chase) the achievement of an album complete,
-- of a zone, of a dungeon, of a raid (instead of its points), with a level of experience and a golden booster
-- (Achievements.lua: AC:XP, AC:Claim); the albums of an event or of a limited edition keep their points
RB.ALBUM = { zone = 5000, dungeon = 10000, raid = 20000 }
-- (1.14.0, his word) A quest of the game turned in (Rewards.lua): rubies after the money it gives, its coppers, under a
-- square root (the first quests give a few coppers, those of level 60 several gold, their experience paid in money: the
-- same quest ten thousand times more at the end than at the start, never ten thousand times its rubies), RB.TURNIN_DIV of
-- it a ruby, between RB.TURNIN_MIN and RB.TURNIN_MAX: 1 for 50 coppers, 2 for a silver, 6 for 10, 14 for 50, 28 for two
-- gold, 49 for six. Once a quest and a character, a quarter in the chest of a reroll (Reroll.lua), and their own guard of
-- the week (below).
RB.TURNIN_DIV = 5
RB.TURNIN_MIN, RB.TURNIN_MAX = 1, 50
-- the boosters to choose they buy, of each kind; RB.PACK_WEEK of them a week, every kind together (a little dearer
-- for each booster than in a display, which takes sixteen at once)
RB.PACK = { zone = 2000, dungeon = 7500, raid = 20000 }
RB.PACK_WEEK = 2
-- (the catch-up of 1.11.0: what a quest of each section and period gives, for those done before the rubies existed)
RB.BACK_QUEST = { q_day = 80, q_week = 600, q_month = 2500, q_dungeon = 120, q_raid = 1500, q_pvp = 80 }
-- (1.13.0, after its second test) The guard: the only rubies that grow without end with the time played, those of the
-- reseller (the copies sold to him) and of the talents, are paid in full up to RB.GUARD a week (the week of the quests:
-- Wednesday 5:00 in Paris), then at RB.GUARD_RATE. The quests, the levels, the achievements always in full. (1.14.0) The
-- quests of the game turned in grow with the time played too: a guard of their own, RB.TURNIN_GUARD a week in full.
RB.GUARD = 4000
RB.TURNIN_GUARD = 4000
-- (1.14.0) The guard of this collection: raised by Deep Pockets, a talent of the Smuggler (the guard of the reseller and of
-- the talents; pool "turnin": the guard of the quests of the game, RB.TURNIN_GUARD).
function RB:GuardMax(pool)
	if pool == "turnin" then
		return self.TURNIN_GUARD
	end
	local TL = ns.Talents
	local k = (TL and TL.GuardBonus) and TL:GuardBonus() or 0
	return math.floor(self.GUARD * (1 + k) + 0.5)
end
RB.GUARD_RATE = 0.25
-- the rubies under a guard, and which one: "main" (the reseller, the talents), (1.14.0) "turnin" (the quests of the game)
RB.GUARDED = { resold = "main", talent = "main", turnin = "turnin" }
-- the ledger: the last comings and goings kept
RB.LOG_MAX = 30

local function Db()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.ruby) ~= "table" then
		db.ruby = {}
	end
	return db
end

-- Nothing to earn nor to spend: a beta past its day, an update missed, a collection suspended or banned.
local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-- How many rubies the collection has.
function RB:Balance()
	local db = ns.db
	return db and math.max(0, math.floor(tonumber(db.rubies) or 0)) or 0
end

function RB:Has(n)
	return self:Balance() >= math.max(0, math.floor(tonumber(n) or 0))
end

-- Rubies earned (why: "quest", "auto", "ach", "level", "golden", "back", "talent", "gift"...; ctx: the quest they come
-- from, { kind, period, section }). How many came (0: none); the talents may add to them (Talents.lua:
-- TL:RubyGain).
function RB:Gain(n, why, ctx)
	n = math.floor(tonumber(n) or 0)
	local db = Db()
	if not db or n <= 0 or Closed() then
		return 0
	end
	-- (1.14.0: the cards changed by another addon this session: no ruby earned, those given back aside; Guard.lua)
	if why ~= "back" and ns.Guard and not ns.Guard:Allow() then
		return 0
	end
	local TL = ns.Talents
	-- (1.12.0: the rubies of a gift code are what the author gave, no talent adds to them; nor to those the author
	-- gives himself, UI/Admin.lua; nor to the few the reseller pays for a copy, Reseller.lua)
	if TL and TL.RubyGain and why ~= "back" and why ~= "gift" and why ~= "admin" and why ~= "resold" then
		n = math.max(n, math.floor(TL:RubyGain(n, why, ctx) + 0.5))
	end
	-- (1.13.0, after its second test: the guard of the week, for the reseller and the talents; 1.14.0: its own for the
	-- quests of the game turned in)
	local pool = self.GUARDED[why]
	if pool then
		n = self:Guard(n, pool == true and "main" or pool)
		if n <= 0 then
			return 0
		end
	end
	db.rubies = self:Balance() + n
	local st = ns.Stats()
	st.rubyEarned = (tonumber(st.rubyEarned) or 0) + n
	self:Log(n, (why == "talent" and type(ctx) == "table" and ctx.talent) and ("t:" .. ctx.talent) or why)
	ns.Fire("RUBIES_CHANGED", n, why)
	if ns.Achievements and ns.Achievements.Queue then
		ns.Achievements:Queue()
	end
	return n
end

-------------------------------------------------------------------------------
-- (1.13.0, after its second test) The guard of the week: the rubies of the reseller and of the talents in full up to
-- RB.GUARD, then at RB.GUARD_RATE (the tenths that do not make a ruby yet wait for the next ones). What is kept:
-- db.ruby.guard = { w = the week, n = the rubies of the week counted (before the guard), f = the part of a ruby left }.
-- (1.14.0) The guard of the quests of the game turned in, the same in db.ruby.qguard (pool "turnin"; nil: "main").
-------------------------------------------------------------------------------
local function Week()
	return ns.Quests and ns.Quests.ResetKey and ns.Quests:ResetKey("week") or nil
end
local POOL = { main = "guard", turnin = "qguard" }

function RB:GuardState(pool)
	local db = Db()
	if not db then
		return nil
	end
	local field = POOL[pool or "main"] or POOL.main
	local w = Week()
	local g = db.ruby[field]
	if type(g) ~= "table" or g.w ~= w then
		g = { w = w, n = 0, f = 0 }
		db.ruby[field] = g
	end
	g.n = math.max(0, tonumber(g.n) or 0)
	g.f = math.max(0, math.min(0.999, tonumber(g.f) or 0))
	return g
end

-- What is left this week in full (0: the rest at the rate).
function RB:GuardLeft(pool)
	local g = self:GuardState(pool)
	return g and math.max(0, self:GuardMax(pool) - g.n) or self:GuardMax(pool)
end

-- What n rubies of the reseller or of the talents would pay now (the guard taken into account), without paying them.
function RB:Guarded(n, pool)
	n = math.max(0, tonumber(n) or 0)
	local left = self:GuardLeft(pool)
	local full = math.min(left, n)
	local g = self:GuardState(pool)
	return full + math.floor((n - full) * self.GUARD_RATE + (g and g.f or 0))
end

-- n rubies of the reseller or of the talents (or of the quests of the game, pool "turnin"): what they pay, counted in the
-- week (the first time past the guard, said once in the chat).
function RB:Guard(n, pool)
	local g = self:GuardState(pool)
	if not g then
		return n
	end
	local max = self:GuardMax(pool)
	local left = math.max(0, max - g.n)
	local full = math.min(left, n)
	local rest = (n - full) * self.GUARD_RATE + g.f
	local paid = full + math.floor(rest)
	g.f = rest - math.floor(rest)
	g.n = g.n + n
	-- (reached, to the ruby: said once)
	if left > 0 and n >= left then
		ns.Fire("RUBY_GUARD", pool or "main")
		if pool == "turnin" then
			ns.Print(L["The rubies of the quests of the game: the %s of the week paid in full are reached. Until the weekly reset (Wednesday, 5:00 in Paris), they pay a quarter."], RB.Text(max))
		else
			ns.Print(L["The rubies of the reseller and of your talents: the %s of the week paid in full are reached. Until the weekly reset (Wednesday, 5:00 in Paris), they pay a quarter."], RB.Text(max))
		end
	end
	return paid
end

-- Rubies spent (why: "respec", "swap", "rumor", "pack", "expertise"; 1.12.0: "seal", "purify"). False and why: "closed", "rubies"
-- (not enough of them).
function RB:Spend(n, why)
	-- (1.14.0: the cards changed by another addon this session: nothing bought, nothing paid; Guard.lua)
	if (tonumber(n) or 0) > 0 and ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard"
	end
	n = math.floor(tonumber(n) or 0)
	local db = Db()
	if not db or Closed() then
		return false, "closed"
	end
	if n < 0 then
		return false, "rubies"
	end
	if self:Balance() < n then
		return false, "rubies"
	end
	if n == 0 then
		return true
	end
	db.rubies = self:Balance() - n
	local st = ns.Stats()
	st.rubySpent = (tonumber(st.rubySpent) or 0) + n
	self:Log(-n, why)
	ns.Fire("RUBIES_CHANGED", -n, why)
	if ns.Achievements and ns.Achievements.Queue then
		ns.Achievements:Queue()
	end
	return true
end

-- (1.11.0) The ledger: the last comings and goings, the latest last ({ t = when, n = how many: less than 0
-- spent, w = what they came from or bought }).
function RB:Log(n, why)
	local db = Db()
	if not db then
		return
	end
	local log = db.ruby.log
	if type(log) ~= "table" then
		log = {}
		db.ruby.log = log
	end
	log[CuratorOctoFull.Length(log) + 1] = { t = CuratorOctoFull.ServerTime(), n = n, w = type(why) == "string" and why or "?" }
	while CuratorOctoFull.Length(log) > self.LOG_MAX do
		CuratorOctoFull.Remove(log, 1)
	end
end

function RB:Ledger()
	local db = ns.db
	local log = db and type(db.ruby) == "table" and db.ruby.log
	return type(log) == "table" and log or {}
end

-- A price in rubies after the talents (what: "reroll", "rumor", "pack", "expertise", "respec", "resell"): a price
-- above 0 stays at 1 at least.
function RB:Price(base, what)
	base = math.max(0, math.floor(tonumber(base) or 0))
	if base == 0 then
		return 0
	end
	local TL = ns.Talents
	local k = (TL and TL.RubyDiscount) and TL:RubyDiscount(what) or 0
	k = math.max(0, math.min(0.9, k))
	return math.max(1, math.floor(base * (1 - k) + 0.5))
end

-- A count of rubies with their gem, for a text ("|T...|t 1 250"); size: of the gem.
function RB.Text(n, size)
	size = size or 14
	return string.format(("|T%s:%d:%d:0:0:64:64:2:62:2:62|t %s"), RB.ICON, size, size, ns.Num(n))
end

-- The gem alone, for a text.
function RB.Gem(size)
	size = size or 14
	return string.format(("|T%s:%d:%d:0:0:64:64:2:62:2:62|t"), RB.ICON, size, size)
end

-------------------------------------------------------------------------------
-- What they come from
-------------------------------------------------------------------------------
-- The rubies of an achievement (for each of its points).
function RB:OfAchievement(a)
	-- (1.14.0: the talents of the achievements of a kind, Talents.lua: TL:AchBonus)
	local k = (a and ns.Talents and ns.Talents.AchBonus) and ns.Talents:AchBonus(a, "rubies") or 1
	-- (1.14.0: an album complete, of a zone, a dungeon or a raid)
	local kind = a and ns.Achievements and ns.Achievements.AlbumKind and ns.Achievements:AlbumKind(a)
	if kind and self.ALBUM[kind] then
		return math.floor(self.ALBUM[kind] * k + 0.5)
	end
	return math.floor((a and tonumber(a.pts) or 0) * self.PER_POINT * k + 0.5)
end

-- (1.14.0, his word) The rubies of a quest of the game turned in, after the money it gives (its coppers; nil, or a value
-- the game keeps secret: the least).
function RB:OfTurnIn(money)
	money = tonumber(money) or 0
	local n = money > 0 and math.floor(math.sqrt(money) / self.TURNIN_DIV + 0.5) or 0
	return math.max(self.TURNIN_MIN, math.min(self.TURNIN_MAX, n))
end

-- The rubies of a level of collector claimed on the track (more for a new rank).
function RB:OfLevel(level)
	level = tonumber(level) or 0
	if level < 2 then
		return 0
	end
	return self.PER_LEVEL + ((CuratorOctoFull.Mod(level , 5) == 0) and self.PER_RANK or 0)
end

-------------------------------------------------------------------------------
-- The boosters to choose they buy
-------------------------------------------------------------------------------
-- The boosters bought this week (the week of the quests: Wednesday 5:00 in Paris).
function RB:PacksThisWeek()
	local db = Db()
	if not db then
		return 0
	end
	local w = ns.Quests and ns.Quests:ResetKey("week") or nil
	local p = db.ruby.packs
	if type(p) ~= "table" or p.w ~= w then
		return 0
	end
	return math.max(0, tonumber(p.n) or 0)
end

-- How many a week (the talents can add one), and the price of one of a kind.
function RB:PackWeek()
	local TL = ns.Talents
	return self.PACK_WEEK + ((TL and TL.PackWeekBonus) and TL:PackWeekBonus() or 0)
end

function RB:PackPrice(kind)
	local base = self.PACK[kind or ""]
	if not base then
		return nil
	end
	local TL = ns.Talents
	if TL and TL.FreePack and TL:FreePack() then
		return 0
	end
	return self:Price(base, "pack")
end

function RB:PacksLeft()
	return math.max(0, self:PackWeek() - self:PacksThisWeek())
end

-- A booster to choose of a kind can be bought now: true, or false and why ("closed", "kind", "week": the
-- boosters of the week bought already, "album": no album can get one of that kind yet, "rubies"; 1.14.0, after its
-- test, his word: "reroll", this character is one, Reroll.lua: RR:Blocks).
-- (1.14.0, his word) The boosters to choose are sold no more: the counter keeps its ledger only (UI/Rubies.lua).
RB.PACKS_SOLD = false

function RB:CanBuyPack(kind)
	if Closed() then
		return false, "closed"
	end
	-- (1.14.0, his word: no booster to choose any more, none sold)
	if not self.PACKS_SOLD then
		return false, "closed"
	end
	if ns.Reroll and ns.Reroll:Blocks("choice") then
		return false, "reroll"
	end
	local price = self:PackPrice(kind)
	if not price then
		return false, "kind"
	end
	if self:PacksLeft() <= 0 then
		return false, "week"
	end
	local LV = ns.Level
	if not (LV and CuratorOctoFull.Length(LV:Eligible(kind)) > 0) then
		return false, "album"
	end
	if not self:Has(price) then
		return false, "rubies"
	end
	return true
end

-- Buys a booster to choose of a kind (it waits with the others, to be put in an album). True, or false and why.
function RB:BuyPack(kind)
	local ok, why = self:CanBuyPack(kind)
	if not ok then
		return false, why
	end
	local price = self:PackPrice(kind)
	if price > 0 then
		local paid, err = self:Spend(price, "pack")
		if not paid then
			return false, err
		end
	elseif ns.Talents and ns.Talents.UseFreePack then
		ns.Talents:UseFreePack()
	end
	local db = Db()
	local w = ns.Quests and ns.Quests:ResetKey("week") or nil
	db.ruby.packs = { w = w, n = self:PacksThisWeek() + 1 }
	local st = ns.Stats()
	st.rubyPacks = (tonumber(st.rubyPacks) or 0) + 1
	ns.Level:AddChoice(kind, 1)
	ns.Fire("RUBY_PACK", kind, price)
	ns.Fire("CLAIMS_CHANGED")
	return true, price
end

-------------------------------------------------------------------------------
-- (1.11.0) The catch-up: at the first login with the rubies, what was done before gives what it would
-- have given (the achievements and the levels claimed, the quests done since 1.9.0, the golden quests)
-------------------------------------------------------------------------------
-- What the collection did before the rubies would have given (the quests whose rewards still wait are
-- not counted: their rubies come when they are claimed). The total, and its parts.
function RB:Backpay()
	local db = ns.db
	if not db then
		return 0, {}
	end
	local parts = { ach = 0, level = 0, quest = 0, golden = 0 }
	local AC = ns.Achievements
	if AC and AC.Build then
		AC:Build()
		local claimed = type(db.achClaimed) == "table" and db.achClaimed or {}
		for _, a in ipairs(AC.list or {}) do
			if claimed[a.id] then
				parts.ach = parts.ach + self:OfAchievement(a)
			end
		end
	end
	for lv, on in pairs(type(db.levelClaims) == "table" and db.levelClaims or {}) do
		if on == true and type(lv) == "number" then
			parts.level = parts.level + self:OfLevel(lv)
		end
	end
	local st = type(db.stats) == "table" and db.stats or {}
	local count = {}
	for key in pairs(self.BACK_QUEST) do
		count[key] = math.max(0, tonumber(st[key]) or 0)
	end
	-- (the quests done whose rewards wait: counted when done, their rubies come with their claim)
	local Q = ns.Quests
	if Q and Q.Claimable then
		for _, it in ipairs(Q:Claimable()) do
			local b = it.board
			local key = "q_" .. (b.section == "general" and b.period or b.section)
			if count[key] and count[key] > 0 then
				count[key] = count[key] - 1
			end
		end
	end
	for key, n in pairs(count) do
		parts.quest = parts.quest + n * self.BACK_QUEST[key]
	end
	parts.golden = math.max(0, tonumber(st.golden) or 0) * self.GOLDEN
	return parts.ach + parts.level + parts.quest + parts.golden, parts
end

-- Once: the catch-up given (said in the chat and by a toast when there is some). A collection suspended or
-- banned waits (it starts over before it plays again).
function RB:CatchUp()
	local db = Db()
	if not db or db.ruby.back then
		return
	end
	if ns.Beta and (ns.Beta:Suspended() or ns.Beta:Banned()) then
		return
	end
	-- (1.14.0: the cards changed by another addon this session: the catch-up waits for the next login; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return
	end
	local total, parts = self:Backpay()
	db.ruby.back = { t = CuratorOctoFull.ServerTime(), n = total, v = ns.version }
	if total <= 0 then
		return
	end
	-- (not a gain of the session: the counters of the achievements take it all the same)
	db.rubies = self:Balance() + total
	local st = ns.Stats()
	st.rubyEarned = (tonumber(st.rubyEarned) or 0) + total
	ns.Fire("RUBIES_CHANGED", total, "back")
	ns.Fire("RUBIES_BACKPAY", total, parts)
	ns.Print(L["The rubies are here: %s for what you already did (your quests, your achievements, your levels). Spend them on your talents, your quests, the rumors of the inns, boosters and the expertise of your cards."], RB.Text(total))
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
ns.On("LOGIN", function()
	-- (after the first check of the achievements: the catch-up counts what was claimed)
	ns.Delay(3, function()
		RB:CatchUp()
	end, RB)
end)

-- (Core.lua: the collection emptied) the rubies go with the levels and the achievements they came from; the
-- catch-up stays given.
ns.On("COLLECTION_EMPTIED", function(db)
	if type(db) == "table" then
		db.rubies = 0
		if type(db.ruby) == "table" then
			db.ruby.packs = nil
		end
	end
end)
