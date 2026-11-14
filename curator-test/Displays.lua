local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.13.0) The displays of boosters, and the protective cases.
-- * A display holds D.SIZE (16) boosters of one album, sealed in its box: opened, its boosters go to that album
--   (UI/Displays.lua: the box opens, its boosters fly out to the others). Of an album of the zones, of an event (a
--   limited edition, while its event lasts), and (after the first test of 1.13.0) of a dungeon or of a raid, far dearer
--   (their boosters come a few a day); never of the Hardcup Saison 3 (an album of no booster).
-- * Where they come from: the gift codes of the author (Gifts.lua: a line "displays <album> <n>"), the reseller (his
--   tab of the displays: D.PRICE rubies, D.PRICE_LIMITED for a limited edition, D.PRICE_DUNGEON, D.PRICE_RAID; his
--   shop changes every D.SHOP_DAYS days: three albums of the zones the player knows, a dungeon, a raid he knows, two
--   albums drawn among all of them, and the display of an event while it lasts), and now and then (D.BONUS) a quest of
--   the month claimed or a golden quest turned in (a display of the album of the golden booster, else of the place
--   you are in: of the zones only), a quest of the week of Hallow's End (a display of Hallow's End).
--   (1.14.0, his word) Of an album unlocked only (Level.lua: LV:Unlocked, a booster of it won by playing): the shop
--   draws its albums among those, he sells no other (D:CanBuy: "locked"), nor comes one now and then; a display
--   opened unlocks nothing.
-- * A protective case, at a banker, for rubies (D.CASE_DISPLAY): a display in its case is kept sealed, as a collector
--   keeps it, out of those to open; it is neither opened nor traded until it comes out of its case, at a banker, free.
--   (Since the first test of 1.13.0, of a display only: the boosters a test build put in their case come back among
--   those to open, D:Mend.)
-- What is kept, under the seal of the save: db.displays ([album key] = how many), db.cased = { d = the displays in
-- their case ([album key] = how many) }, db.dispShop = { p = the period of the shop, k = the keys of its albums }; the
-- counters of ns.Stats: displays (earned), displaysBought, displaysOpened, cased.
-------------------------------------------------------------------------------
local D = {}
ns.Displays = D

D.SIZE = 16              -- the boosters of a display
-- (1.13.0, after its second test: the economy redone around this one, the week of a player of 3 to 5 hours a day at
-- most, Rubies.lua; a limited edition 65 000 before, a dungeon 150 000, a raid 1 000 000)
-- (1 November, 14 h 20, his choice « C » after the simulation of the rubies: a display of a zone a week of a player of
-- three hours a day again, the rubies of the 1.14.0 come in more than before; 25 000 and 50 000 before)
D.PRICE = 35000          -- a display at the reseller (an album of the zones)
D.PRICE_LIMITED = 60000  -- a display of a limited edition (an album of an event, while it lasts)
D.PRICE_DUNGEON = 100000 -- a display of a dungeon (about a month of rubies)
D.PRICE_RAID = 300000    -- a display of a raid (about a season)
D.SHOP_DAYS = 3          -- the shop of the reseller changes every three days
D.SHOP = { zone = 3, dungeon = 1, raid = 1, any = 2 } -- its albums: of the zones, a dungeon, a raid (known), drawn
D.CASE_DISPLAY = 2500    -- a display in its case, at a banker
D.BONUS = 0.1            -- the chance of a display with a quest of the month, a golden quest, a quest of the week of
                         -- Hallow's End
D.MAX_GIFT = 20          -- the displays of an album a gift code gives at most

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

local function Int(v)
	return math.max(0, math.floor(tonumber(v) or 0))
end

-- What the save keeps (made when something is put there: a collection without any keeps nothing of it).
local function Db(make)
	local db = ns.db
	if not db then
		return nil
	end
	if make then
		if type(db.displays) ~= "table" then
			db.displays = {}
		end
		if type(db.cased) ~= "table" then
			db.cased = {}
		end
		if type(db.cased.d) ~= "table" then
			db.cased.d = {}
		end
	end
	return db
end

-- How many of an album in a table of the save (nil: none).
local function Get(t, key)
	return type(t) == "table" and Int(t[key]) or 0
end

-- n more (or less) of an album in a table of the save: none left, its key goes.
local function Bump(t, key, n)
	local v = Get(t, key) + n
	t[key] = v > 0 and v or nil
end

local function Changed()
	ns.Fire("DISPLAYS_CHANGED")
	ns.Fire("CHANGED")
end

-------------------------------------------------------------------------------
-- The albums of the displays
-------------------------------------------------------------------------------
-- An album its displays can be of: of the zones, of an event, of a dungeon or of a raid (never an album of no booster).
function D.Eligible(s)
	return type(s) == "table" and not s.limited and (s.kind == "zone" or s.kind == "dungeon" or s.event ~= nil) or false
end

-- An album the player knows: (1.14.0, his word) unlocked, a booster of it won by playing (Level.lua: LV:Unlocked; a
-- card of it found before, even bought from the reseller, an album drawn at random: not any more).
local function Known(s)
	local LV = ns.Level
	return s ~= nil and LV ~= nil and LV:Unlocked(s) or false
end
D.Known = Known

-- What kind of display: "zone", "event", "dungeon", "raid" (nil: none).
function D.Kind(s)
	if not D.Eligible(s) then
		return nil
	end
	if s.event then
		return "event"
	elseif s.kind == "dungeon" then
		return s.raid and "raid" or "dungeon"
	end
	return "zone"
end

-- An album a display earned now and then can be of: of the zones, or of an event (never a dungeon nor a raid).
function D.BonusEligible(s)
	local k = D.Kind(s)
	return k == "zone" or k == "event"
end

-- The event of an album of an event lasts now (its displays at the reseller only then).
function D.EventOn(s)
	if not (s and s.event) then
		return false
	end
	if s.event == "hallow" and ns.Hallow and ns.Hallow.On then
		return ns.Hallow:On() and true or false
	end
	return false
end

-- A display of an album earned now and then (a quest of the month, a golden quest): the album given when it can be
-- one, else the album of the place you are in, else the album of your start. (1.14.0, his word: an album unlocked
-- only, else the first of the zones unlocked; none: no display.)
function D:BonusAlbum(s)
	if self.BonusEligible(s) and Known(s) then
		return s
	end
	local here = ns.Rewards and ns.Rewards.ZoneSeries and ns.Rewards:ZoneSeries()
	if self.BonusEligible(here) and Known(here) then
		return here
	end
	local home = ns.HomeSeries and ns.HomeSeries()
	if self.BonusEligible(home) and Known(home) then
		return home
	end
	for _, x in ipairs(ns.Series or {}) do
		if x.kind == "zone" and Known(x) then
			return x
		end
	end
	return nil
end

-------------------------------------------------------------------------------
-- What there is
-------------------------------------------------------------------------------
function D:Count(s)
	local db = Db()
	return (db and s) and Get(db.displays, s.key) or 0
end

function D:CasedDisplays(s)
	local db = Db()
	return (db and s and type(db.cased) == "table") and Get(db.cased.d, s.key) or 0
end

-- Every display to open, of every album (those in their case left out).
function D:Total()
	local n = 0
	local db = Db()
	for _, v in pairs(db and type(db.displays) == "table" and db.displays or {}) do
		n = n + Int(v)
	end
	return n
end

-- The albums in the order of the contents of the album.
local function Order()
	if ns.Album and ns.Album.Order then
		return ns.Album:Order()
	end
	return ns.Series or {}
end

-- Every album with displays, in their case or not: { series, displays, casedDisplays }, in the order of the contents.
function D:All()
	local out = {}
	local db = Db()
	if not db then
		return out
	end
	for _, s in ipairs(Order()) do
		local x = { series = s, displays = self:Count(s), casedDisplays = self:CasedDisplays(s) }
		if x.displays + x.casedDisplays > 0 then
			out[CuratorOctoFull.Length(out) + 1] = x
		end
	end
	return out
end

-- A display (n of them) of an album comes (why: "gift", "reseller", "quest", "golden", "hallow"). How many came.
function D:Add(s, n, why)
	n = Int(n)
	if n <= 0 or not self.Eligible(s) then
		return 0
	end
	-- (1.14.0: its album as it must be, else none comes: Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return 0
	end
	local db = Db(true)
	if not db then
		return 0
	end
	Bump(db.displays, s.key, n)
	local st = ns.Stats()
	st.displays = (tonumber(st.displays) or 0) + n
	Changed()
	ns.Fire("DISPLAY_EARNED", s, n, why)
	return n
end

-------------------------------------------------------------------------------
-- At the reseller
-------------------------------------------------------------------------------
-- What a display costs, by its kind (a limited edition, a dungeon, a raid: dearer; the talents can lower it: RB:Price).
function D:Price(s)
	local k = self.Kind(s)
	local base = (k == "event" and self.PRICE_LIMITED) or (k == "dungeon" and self.PRICE_DUNGEON) or (k == "raid" and self.PRICE_RAID) or self.PRICE
	return ns.Rubies and ns.Rubies:Price(base, "display") or base
end

-- (the shop: a number of a text, the same text the same number; then drawn after it, Park and Miller)
local M = 2147483647
local function Hash(text)
	local h = 7
	for i = 1, CuratorOctoFull.Length(text) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(text, i)) , M)
	end
	return h > 0 and h or 1
end

-- The day of the quests (from 5:00 in Paris to the next 5:00), a number for each (the day its end falls in); the
-- period of the shop.
local function Today()
	local Q = ns.Quests
	if Q and Q.ResetPeriod then
		return math.floor(Q:ResetPeriod("day") / 86400)
	end
	return math.floor(((GetServerTime and CuratorOctoFull.ServerTime()) or time()) / 86400)
end

function D:ShopPeriod()
	return math.floor(Today() / self.SHOP_DAYS)
end

-- When the shop changes next (seconds from now).
function D:ShopLeft()
	local day = Today()
	local days = (self:ShopPeriod() + 1) * self.SHOP_DAYS - day
	local Q = ns.Quests
	local left = (Q and Q.ResetLeft) and Q:ResetLeft("day") or (86400 - CuratorOctoFull.Mod(((GetServerTime and CuratorOctoFull.ServerTime()) or time()) , 86400))
	return math.max(0, left + (days - 1) * 86400)
end

-- The albums of the shop (of a period, for a collection): its keys, drawn once and kept for the period in the save.
function D:ShopKeys()
	local db = ns.db
	if not db then
		return {}
	end
	local p = self:ShopPeriod()
	local kept = db.dispShop
	if type(kept) == "table" and kept.p == p and type(kept.k) == "table" and kept.v == 2 then
		return kept.k
	end
	local id = (ns.Export and ns.Export.Id and ns.Export:Id()) or "curator"
	local x = Hash("displays:" .. id .. ":" .. p)
	local function Pick(list)
		if CuratorOctoFull.Length(list) == 0 then
			return nil
		end
		x = CuratorOctoFull.Mod((x * 16807) , M)
		return CuratorOctoFull.Remove(list, (CuratorOctoFull.Mod(x , CuratorOctoFull.Length(list))) + 1)
	end
	local pools = { zone = { known = {}, other = {} }, dungeon = { known = {}, other = {} }, raid = { known = {}, other = {} } }
	for _, s in ipairs(Order()) do
		local k = self.Kind(s)
		local pool = k and pools[k]
		if pool then
			CuratorOctoFull.Insert(Known(s) and pool.known or pool.other, s)
		end
	end
	local out, taken = {}, {}
	local function Take(s)
		if s and not taken[s.key] then
			taken[s.key] = true
			out[CuratorOctoFull.Length(out) + 1] = s.key
			return true
		end
		return false
	end
	for _, kind in ipairs({ "zone", "dungeon", "raid" }) do
		local pool = pools[kind]
		for _ = 1, self.SHOP[kind] or 0 do
			-- (1.14.0, his word: of the albums unlocked only; none left: one fewer)
			Take(Pick(pool.known))
		end
	end
	-- two drawn among the others unlocked (those not taken yet)
	local rest = {}
	for _, kind in ipairs({ "zone", "dungeon", "raid" }) do
		for _, s in ipairs(pools[kind].known) do
			rest[CuratorOctoFull.Length(rest) + 1] = s
		end
	end
	table.sort(rest, function(a, b)
		return a.key < b.key
	end)
	for _ = 1, self.SHOP.any or 0 do
		Take(Pick(rest))
	end
	db.dispShop = { p = p, k = out, v = 2 }
	return out
end

-- The albums whose displays he sells now: those of his shop (its kinds in order: the zones, the dungeon, the raid, the
-- two drawn), and the albums of the events that last.
function D:ForSale()
	local out, seen = {}, {}
	for _, key in ipairs(self:ShopKeys()) do
		local s = ns.SeriesByKey and ns.SeriesByKey(key)
		if self.Eligible(s) and not s.event and not seen[s] and Known(s) then
			seen[s] = true
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	for _, s in ipairs(Order()) do
		if self.Kind(s) == "event" and self.EventOn(s) and not seen[s] and Known(s) then
			seen[s] = true
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end

-- In his shop now.
function D:InShop(s)
	for _, x in ipairs(self:ForSale()) do
		if x == s then
			return true
		end
	end
	return false
end

-- Whether a display of an album can be bought now: true, or false and why ("closed", "album": no display of it,
-- "locked": the album not unlocked, "event": its event does not last, "shop": not in his shop these days, "here": not
-- at the reseller, "rubies").
function D:CanBuy(s)
	if Closed() then
		return false, "closed"
	end
	if not self.Eligible(s) then
		return false, "album"
	end
	if s.event and not self.EventOn(s) then
		return false, "event"
	end
	if not Known(s) then
		return false, "locked"
	end
	if not self:InShop(s) then
		return false, "shop"
	end
	if not (ns.Reseller and ns.Reseller.here) then
		return false, "here"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:Price(s))) then
		return false, "rubies"
	end
	return true
end

-- A display bought: its rubies paid, it waits to be opened. True and the price; or false and why.
function D:Buy(s)
	local ok, why = self:CanBuy(s)
	if not ok then
		return false, why
	end
	local price = self:Price(s)
	local paid, err = ns.Rubies:Spend(price, "display")
	if not paid then
		return false, err
	end
	local st = ns.Stats()
	st.displaysBought = (tonumber(st.displaysBought) or 0) + 1
	self:Add(s, 1, "reseller")
	return true, price
end

-------------------------------------------------------------------------------
-- Opened
-------------------------------------------------------------------------------
-- Whether a display of an album can be opened now: true, or false and why ("closed", "none": no display of it to
-- open, "cased": only in its case; 1.14.0, after its test: "reroll", a reroll opens none, Reroll.lua).
function D:CanOpen(s)
	if Closed() then
		return false, "closed"
	end
	if not s then
		return false, "none"
	end
	if ns.Reroll and ns.Reroll:NoOpening() then
		return false, "reroll"
	end
	if self:Count(s) <= 0 then
		return false, self:CasedDisplays(s) > 0 and "cased" or "none"
	end
	return true
end

-- A display opened: its boosters into its album (saved at once: closing its ceremony early loses nothing). True, or
-- false and why.
function D:Open(s)
	local ok, why = self:CanOpen(s)
	if not ok then
		return false, why
	end
	-- (1.14.0: its album changed by another addon this session: it stays to open; Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return false, "guard"
	end
	local db = Db(true)
	Bump(db.displays, s.key, -1)
	-- (1.14.0, the Gambler: Display Chest, a booster more now and then; High Roller, Double or Nothing on the display)
	local n = self.SIZE
	local TL = ns.Talents
	local more, bet = 0, nil
	if TL and TL:Spec() == "gambler" then
		if TL:Has("displaybox") and math.random() < TL:V("displaybox") then
			more = 1
		end
		bet = TL:BetDisplay()
	end
	n = math.max(1, n + more + (bet and bet.delta or 0))
	-- (1.14.0, his word: a display opened unlocks nothing, Level.lua: LV:Unlocked)
	ns.AddPacks(s, n, true)
	local st = ns.Stats()
	st.displaysOpened = (tonumber(st.displaysOpened) or 0) + 1
	self.lastOpened = { s = s, n = n, more = more > 0 or nil, bet = bet }
	ns.Fire("DISPLAY_OPENED", s, n, bet)
	Changed()
	return true, nil, n
end

-------------------------------------------------------------------------------
-- (1.14.0) The Bourse Gentepression (Market.lua): a display that leaves or comes as it is
-------------------------------------------------------------------------------
-- n displays of an album out (n below 0) or in, in their case or not: nothing counted, nothing drawn. False when
-- there are not so many to take, or its album has none.
function D:Move(s, cased, n)
	n = math.floor(tonumber(n) or 0)
	if n == 0 or not self.Eligible(s) then
		return false
	end
	local db = Db(true)
	local t = cased and db.cased.d or db.displays
	if n < 0 and Get(t, s.key) < -n then
		return false
	end
	Bump(t, s.key, n)
	Changed()
	return true
end

-------------------------------------------------------------------------------
-- The protective cases, at a banker
-------------------------------------------------------------------------------
local function AtBank()
	return ns.Expertise ~= nil and ns.Expertise:AtBank()
end

-- What a case costs (kind: "display", the only one since the first test of 1.13.0).
function D:CasePrice(kind)
	local base = self.CASE_DISPLAY
	return ns.Rubies and ns.Rubies:Price(base, "case") or base
end

-- Whether a display of an album (kind "display") can go into its case now: true, or false and why ("closed", "kind":
-- anything else, a booster since the first test of 1.13.0, "album": an album of no booster, "none": none of it to put,
-- "bank": not at a banker, "rubies").
function D:CanCase(s, kind)
	if Closed() then
		return false, "closed"
	end
	if kind ~= "display" then
		return false, "kind"
	end
	if not s or s.limited then
		return false, "album"
	end
	if self:Count(s) <= 0 then
		return false, "none"
	end
	if not AtBank() then
		return false, "bank"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:CasePrice(kind))) then
		return false, "rubies"
	end
	return true
end

-- One into its case: its rubies paid. True and the price; or false and why.
function D:Case(s, kind)
	local ok, why = self:CanCase(s, kind)
	if not ok then
		return false, why
	end
	local price = self:CasePrice(kind)
	local paid, err = ns.Rubies:Spend(price, "case")
	if not paid then
		return false, err
	end
	local db = Db(true)
	Bump(db.displays, s.key, -1)
	Bump(db.cased.d, s.key, 1)
	local st = ns.Stats()
	st.cased = (tonumber(st.cased) or 0) + 1
	ns.Fire("CASED", s, kind)
	Changed()
	return true, price
end

-- Whether one can come out of its case now: true, or false and why ("closed", "kind", "none": none in its case,
-- "bank": not at a banker).
function D:CanUncase(s, kind)
	if Closed() then
		return false, "closed"
	end
	if kind ~= "display" then
		return false, "kind"
	end
	if not s then
		return false, "none"
	end
	if self:CasedDisplays(s) <= 0 then
		return false, "none"
	end
	if not AtBank() then
		return false, "bank"
	end
	return true
end

-- One out of its case, free: a booster back among those to open, a display among those to open. True, or false and
-- why.
function D:Uncase(s, kind)
	local ok, why = self:CanUncase(s, kind)
	if not ok then
		return false, why
	end
	local db = Db(true)
	Bump(db.cased.d, s.key, -1)
	Bump(db.displays, s.key, 1)
	ns.Fire("UNCASED", s, kind)
	Changed()
	return true
end

-------------------------------------------------------------------------------
-- The displays that come now and then
-------------------------------------------------------------------------------
-- A display, D.BONUS of the time, of an album (s: the one the reward is of; nil: the place you are in). What came
-- (nil: none).
function D:Bonus(s, why)
	if Closed() then
		return nil
	end
	-- (a quest of Hallow's End: a display of its album, none else)
	local album
	if why == "hallow" then
		album = Known(s) and s or nil
	else
		album = self:BonusAlbum(s)
	end
	if not self.BonusEligible(album) or math.random() >= self.BONUS then
		return nil
	end
	if self:Add(album, 1, why) > 0 then
		return album
	end
	return nil
end

-- (a quest claimed: of a board of the month, of the week of Hallow's End)
do
	local Q = ns.Quests
	local claim = Q and Q.Claim
	if claim then
		function Q:Claim(board, q, auto)
			local before = q and q.claimed
			local a, b, c, d, e = claim(self, board, q, auto)
			if board and q and not before and q.claimed then
				if board.period == "month" then
					D:Bonus(nil, "quest")
				elseif board.key == "hallowWeekly" then
					D:Bonus(ns.Hallow and ns.Hallow:Series(), "hallow")
				end
			end
			return a, b, c, d, e
		end
	end
end

-- (a golden quest turned in: a display of the album of its golden booster, when it can be one)
ns.On("GOLDEN_DONE", function(_, s)
	D:Bonus(s, "golden")
end)

-- (after the first test of 1.13.0) The cases are of the displays only: the boosters a test build put in their case come
-- back among those to open, once (db.cased.p goes). How many came back (0: none).
function D:Mend()
	local db = Db()
	local cased = db and type(db.cased) == "table" and db.cased or nil
	if not cased or cased.p == nil then
		return 0
	end
	local n = 0
	if type(cased.p) == "table" then
		db.packs = type(db.packs) == "table" and db.packs or {}
		for key, v in pairs(cased.p) do
			local k = Int(v)
			if k > 0 and type(key) == "string" then
				db.packs[key] = Int(db.packs[key]) + k
				n = n + k
			end
		end
	end
	cased.p = nil
	if n > 0 then
		ns.Print(L["Your boosters in their protective case are back among your boosters to open (%d): the cases now keep the displays only."], n)
		Changed()
	end
	return n
end

ns.On("LOGIN", function()
	D:Mend()
end)

-- (Core.lua: the collection emptied) the displays and the cases go with the boosters, when they go (a collection
-- started over entirely); a reset of the cards alone keeps them, as it keeps the boosters.
ns.On("COLLECTION_EMPTIED", function(db, full)
	if type(db) == "table" and full then
		db.displays, db.cased = nil, nil
	end
end)

-------------------------------------------------------------------------------
-- Their achievements (after those of 1.13.0 before them: Achievements.lua, AC.After1130)
-------------------------------------------------------------------------------
local AC = ns.Achievements
if AC and AC.After1130 and AC.Define then
	local function Stat(db, k)
		return type(db) == "table" and type(db.stats) == "table" and tonumber(db.stats[k]) or 0
	end
	AC.After1130(function()
		AC.Define({ id = "disp1", cat = "boosters", pts = 10, name = "Sixteen at Once", icon = { "DisplayIcon" }, goal = 1,
			value = function(_, db) return Stat(db, "displaysOpened") end,
			desc = function() return L["Open a display of 16 boosters."] end })
		AC.Define({ id = "case1", cat = "collection", pts = 5, name = "Mint Condition", icon = { "CaseIcon" }, goal = 1,
			value = function(_, db) return Stat(db, "cased") end,
			desc = function() return L["Put a display in its protective case, at a banker."] end })
	end)
end
