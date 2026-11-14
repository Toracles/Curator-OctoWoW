local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0) The main character and the rerolls, from the release of WoW Forever. The collection is the account's,
-- its characters are not all alike:
-- * the main character (db.main: its name, its GUID): the first one Curator meets on WoW Forever. It earns
--   everything from level 1. Another character takes its place from that character, once in RR.CHANGE_EVERY at most
--   (the first time whenever the player likes: the main chosen without asking may not be the right one).
-- * a reroll: any other character, under level RR.LEVEL. A quarter of everything it earns by playing: the points of
--   its own bars (RR:Bar), the boosters, the cards found on the creatures, the experience and the rubies of what it
--   does. All it earns waits in its chest (c.chest), which opens at level RR.LEVEL, or when the character becomes the
--   main: its boosters go to their albums, its cards to the collection, its experience and its rubies to the
--   collector. A character deleted before takes its chest with it: the chest goes with the GUID of the character, and
--   one made again under the same name starts with none (RR:Bind).
-- * what the account does with what it has (the trades, the reseller, the rewards claimed of the levels and of the war
--   board) and what is counted for the account already (the stamp of an inn a day, the visas, a treat of Hallow's
--   End): as it is, on any character (Rewards.lua: R.ACCOUNT_REASONS). After its test, his word: but a reroll opens
--   nothing, no booster, display or case (RR:NoOpening); and later, his word again: it does no quest of the
--   collector, uses no booster to choose, signs no contract and does no achievement (RR:Blocks).
-- * the golden quest: closed to a reroll; its tranche follows the highest character of the account (Golden.lua).
-- The quarters are whole things, never fractions in the save: each kind of thing keeps the quarters it is owed
-- toward the next whole one (c.rq), so that one in four of them comes; the bars of a reroll keep hundredths of a point
-- (whole numbers).
-- (1.14.0) The release of WoW Forever (RR:Release, RR:Migrate): the first session on a realm of WoW Forever (not one of
-- its beta). Its beta ended in chaos: Curator starts over for everyone, as a new collection. A collection of the beta
-- keeps the cards of its limited editions (Hallow's End, the Hardcup Saison 3) and the boosters of Hallow's End not
-- opened yet, the achievements Beta tester, Pioneer and Hardcup Survivor, and the codes of the website already used;
-- all the rest starts again from zero (its level, its talents, its rubies, its other cards and boosters, its other
-- achievements), the leaderboard of the website with it (the code of the collection says it, Export.lua). The
-- characters of the beta are forgotten (WoW Forever deleted them). A save of the beta put back after it stops Curator.
-------------------------------------------------------------------------------
local RR = {}
ns.Reroll = RR

RR.LEVEL = 15                 -- under it, a reroll earns a quarter of everything, in its chest
RR.SHARE = 4                  -- a quarter: one in four
RR.CHANGE_EVERY = 30 * 86400  -- the main changes once in this time at most

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b = pcall(fn, unpack(arg, 1, arg.n))
	if ok and not Secret(a) then
		return a, b
	end
	return nil
end

-- A table and all it holds, copied (the save lent to the tests of the author).
function RR.Copy(t, seen)
	if type(t) ~= "table" then
		return t
	end
	seen = seen or {}
	if seen[t] then
		return seen[t]
	end
	local out = {}
	seen[t] = out
	for k, v in pairs(t) do
		out[RR.Copy(k, seen)] = RR.Copy(v, seen)
	end
	return out
end

-------------------------------------------------------------------------------
-- Who is who
-------------------------------------------------------------------------------
-- The rules on: the save went through the release of WoW Forever (or the author tries them: RR.test).
function RR:Active()
	local db = ns.db
	if not db then
		return false
	end
	if self.test ~= nil then
		return self.test == true
	end
	return self:Through(db)
end

function RR:Guid()
	local g = Safe(UnitGUID, "player")
	return (type(g) == "string" and g ~= "") and g or nil
end

-- The level of this character (the one the game just gave it, before the game itself says it).
function RR:Level()
	local lv = Safe(UnitLevel, "player")
	lv = type(lv) == "number" and lv or 0
	return math.max(lv, self.levelSeen or 0)
end

-- What this character did and earned (Rewards.lua), nil before the save is there.
function RR:Char()
	return ns.db and ns.Rewards and ns.Rewards:Char() or nil
end

function RR:Main()
	local m = ns.db and ns.db.main
	return type(m) == "table" and m or nil
end

function RR:IsMain()
	local m = self:Main()
	local g = self:Guid()
	return m ~= nil and g ~= nil and m.g == g
end

-- A reroll now: the rules on, a main known, this character not it, under RR.LEVEL. (The author's test: whatever.)
function RR:IsReroll()
	if self.forceReroll then
		return true
	end
	if not self:Active() then
		return false
	end
	if not self:Main() or self:IsMain() then
		return false
	end
	local lv = self:Level()
	return lv > 0 and lv < self.LEVEL
end

-- The name of the main, as the player knows it (its first name).
function RR:MainName()
	local m = self:Main()
	local k = m and tostring(m.k or "") or ""
	return CuratorOctoFull.Match(k, "^([^%-]+)") or k
end

-- (1.14.0, after its test, his word) A reroll opens nothing: no booster of any kind, no display, no case. They are the
-- account's, and wait for the main character, or for this one at level RR.LEVEL (a reroll no more). The previews of the
-- author (/curator test) are no boosters of the account: they open anywhere.
function RR:NoOpening()
	return self:IsReroll()
end

-- Why nothing opens, in the words of the player (the main named).
function RR:Why()
	local main = self:MainName()
	if main == "" then
		return string.format(L["This character is a reroll: it opens no booster, display or case until level %d."], self.LEVEL)
	end
	return string.format(L["This character is a reroll: it opens no booster, display or case. Open them with your main character, %s, or with this one from level %d."], main, self.LEVEL)
end

-- Asked to open one on a reroll: said in the chat (once in a few seconds: a click on each booster says it once).
function RR:SayNoOpening()
	local now = (GetTime and GetTime()) or 0
	if not self.saidAt or now - self.saidAt > 3 then
		self.saidAt = now
		ns.Print(self:Why())
	end
	if ns.Play and ns.SND then
		ns.Play(ns.SND.close)
	end
end

-- (1.14.0, after its test, his word, later) What else a reroll does not do at all, until level RR.LEVEL:
-- * "quests", the quests of the collector: what it does counts for none of them, it claims none of their rewards and
--   changes none of them (Quests.lua; the rewards of the quests done whose period ends come to the account as they
--   are: Q:Renew);
-- * "choice", the boosters to choose: it puts none in an album (Level.lua: LV:Assign) and buys none (Rubies.lua);
-- * "contracts": it signs none, of cards (Contract.lua) or of cases (Cases.lua);
-- * "achievements": what it does counts for none of them (their counters: Pvp.lua, Rewards.lua, Quests.lua, Front.lua,
--   Duel.lua), it earns none and claims none of their rewards (Achievements.lua: those reached come with the next look
--   on the main, or on this character from level RR.LEVEL).
RR.BLOCKS = { quests = true, choice = true, contracts = true, achievements = true }

function RR:Blocks(what)
	return self.BLOCKS[what] == true and self:IsReroll()
end

-- What this character does by playing counts for the achievements (their counters, ns.Stats: the PvP, the
-- battlegrounds, the dungeons and the raids done, the cards found on the creatures, the duels, the front): not on a
-- reroll. (What the account does with what it has, as it is: the trades, the contracts of the main, the inns...)
function RR:Counts()
	return not self:Blocks("achievements")
end

-- Why, in the words of the player: the main named (without one known, the level only).
local WHY_NOT = {
	quests = {
		"This character is a reroll: until level %d, what it does counts for no quest of the collector, and it claims none of their rewards.",
		"This character is a reroll: what it does counts for no quest of the collector, and it claims none of their rewards. Do them with your main character, %s, or with this one from level %d.",
	},
	choice = {
		"This character is a reroll: until level %d, it cannot use the boosters to choose (put them in an album, buy them).",
		"This character is a reroll: it cannot use the boosters to choose (put them in an album, buy them). Use them with your main character, %s, or with this one from level %d.",
	},
	contracts = {
		"This character is a reroll: until level %d, it signs no contract, of cards or of cases.",
		"This character is a reroll: it signs no contract, of cards or of cases. Sign them with your main character, %s, or with this one from level %d.",
	},
	achievements = {
		"This character is a reroll: until level %d, what it does counts for no achievement, and it claims none of their rewards.",
		"This character is a reroll: what it does counts for no achievement, and it claims none of their rewards. Earn them with your main character, %s, or with this one from level %d.",
	},
}

function RR:WhyNot(what)
	local t = WHY_NOT[what]
	if not t then
		return self:Why()
	end
	local main = self:MainName()
	if main == "" then
		return string.format(L[t[1]], self.LEVEL)
	end
	return string.format(L[t[2]], main, self.LEVEL)
end

-- Asked of a reroll: said in the chat (once in a few seconds for each thing: a click on each card says it once).
function RR:SayNot(what)
	local now = (GetTime and GetTime()) or 0
	self.saidNot = self.saidNot or {}
	if not self.saidNot[what] or now - self.saidNot[what] > 3 then
		self.saidNot[what] = now
		ns.Print(self:WhyNot(what))
	end
	if ns.Play and ns.SND then
		ns.Play(ns.SND.close)
	end
end

-- All the rules of a reroll at once (the window of a new reroll, the page of its chest); short: without the main.
function RR:Rules(short)
	local main = self:MainName()
	if short or main == "" then
		return string.format(L["Until level %d, a reroll opens nothing (no booster, display or case), does no quest of the collector, chooses no reward, signs no contract and counts for no achievement."], self.LEVEL)
	end
	return string.format(L["Until level %d, a reroll opens nothing (no booster, display or case), does no quest of the collector, chooses no reward, signs no contract and counts for no achievement: your main character, %s, does all of that."], self.LEVEL, main)
end

-- The highest level among the characters of the account Curator met (since the release: the characters of the beta
-- forgotten) and this one.
function RR:HighestLevel()
	local top = self:Level()
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		local lv = type(c) == "table" and tonumber(c.level) or nil
		if lv and lv > top then
			top = lv
		end
	end
	return top
end

-- Can this character become the main now? true, or false and the seconds left (0: it is the main, or nothing to
-- change).
function RR:CanChange()
	if not self:Active() or self:IsMain() then
		return false, 0
	end
	local m = self:Main()
	local last = m and tonumber(m.c)
	if not last then
		return true, 0
	end
	local left = last + self.CHANGE_EVERY - Now()
	if left <= 0 then
		return true, 0
	end
	return false, left
end

-- This character becomes the main (auto: the first one met, without asking; it does not count as a change).
-- Its chest opens: the main has none.
function RR:SetMain(auto)
	local db = ns.db
	local g = self:Guid()
	if not (db and g) then
		return false
	end
	local old = self:Main()
	if not auto and not self:CanChange() then
		return false
	end
	db.main = { k = (ns.Guild and ns.Guild:Me()) or "?", g = g, t = Now(), c = (not auto) and Now() or (old and old.c) or nil }
	local c = self:Char()
	if c then
		c.asked = c.asked or Now()
	end
	ns.Fire("MAIN_CHANGED", auto == true)
	self:Check()
	ns.Fire("CHANGED")
	return true
end

-- (1.14.3, his word of November 6: "Reset les personnages principaux pour cette maj"; a player's: "I put a lock as my
-- main by mistake and now I have no main") The choice of the main given back, once for each save: the wait of
-- RR.CHANGE_EVERY gone (the next change free, as the first one), and each reroll asked again at its next login (the
-- window of the main, UI/Reroll.lua). Who is the main stays as it is until the player says otherwise: a character
-- logged first after the update is never made the main for it. (db.mainReset: done.)
RR.RESET = 1
function RR:ResetChoice(db)
	if not db or (tonumber(db.mainReset) or 0) >= self.RESET then
		return false
	end
	db.mainReset = self.RESET
	if type(db.main) ~= "table" then
		return false
	end
	db.main.c = nil
	for _, c in pairs(type(db.chars) == "table" and db.chars or {}) do
		if type(c) == "table" then
			c.asked = nil
		end
	end
	return true
end

-- The answer of the window: this character stays a reroll (asked: it is not asked again).
function RR:KeepReroll()
	local c = self:Char()
	if c then
		c.asked = c.asked or Now()
	end
	ns.Fire("MAIN_CHANGED", false)
end

-------------------------------------------------------------------------------
-- The quarters
-------------------------------------------------------------------------------
-- n of a kind of things (key) a reroll earns: a quarter of them, whole, the quarters owed kept toward the next one.
-- Not a reroll: n.
function RR:Quarter(key, n)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 or not self:IsReroll() then
		return n
	end
	local c = self:Char()
	if not c then
		return 0
	end
	c.rq = type(c.rq) == "table" and c.rq or {}
	local q = (tonumber(c.rq[key]) or 0) + n
	local whole = math.floor(q / self.SHARE)
	q = q - whole * self.SHARE
	c.rq[key] = q > 0 and q or nil
	return whole
end

-- The points of a bar a reroll earns.
function RR:Points(points)
	return (tonumber(points) or 0) / self.SHARE
end

-- The bars of a reroll: its own, kept in hundredths of a point (whole numbers in the save).
function RR:Bar(kind)
	local c = self:Char()
	local v = c and (kind == "dungeon" and c.rdbar or c.rbar)
	return math.max(0, (tonumber(v) or 0) / 100)
end

function RR:SetBar(kind, points)
	local c = self:Char()
	if not c then
		return
	end
	local v = math.max(0, math.floor((tonumber(points) or 0) * 100 + 0.5))
	if kind == "dungeon" then
		c.rdbar = v > 0 and v or nil
	else
		c.rbar = v > 0 and v or nil
	end
end

-------------------------------------------------------------------------------
-- The chest
-------------------------------------------------------------------------------
-- The chest of this character (made when something goes into it), nil when it has none.
function RR:Chest(make)
	local c = self:Char()
	if not c then
		return nil
	end
	if type(c.chest) ~= "table" then
		if not make then
			return nil
		end
		c.chest = { t = Now() }
	end
	return c.chest
end

local function Changed()
	ns.Fire("CHEST_CHANGED")
end

-- Boosters into the chest: of an album (s), or (s nil) of a zone to choose.
function RR:StashPacks(s, n)
	n = math.floor(tonumber(n) or 0)
	-- (1.14.0: the cards changed by another addon this session: nothing into the chest; Guard.lua)
	if n > 0 and ns.Guard and not ns.Guard:Allow(s) then
		return
	end
	local ch = n > 0 and self:Chest(true)
	if not ch then
		return
	end
	if s then
		ch.packs = type(ch.packs) == "table" and ch.packs or {}
		ch.packs[s.key] = (tonumber(ch.packs[s.key]) or 0) + n
	else
		self:StashChoice("zone", n)
		return
	end
	Changed()
end

-- Boosters to choose into the chest (kind: "zone", "dungeon", "raid").
function RR:StashChoice(kind, n)
	n = math.floor(tonumber(n) or 0)
	if n > 0 and ns.Guard and not ns.Guard:Allow() then
		return
	end
	local ch = n > 0 and self:Chest(true)
	if not ch then
		return
	end
	ch.choice = type(ch.choice) == "table" and ch.choice or {}
	ch.choice[kind] = (tonumber(ch.choice[kind]) or 0) + n
	Changed()
end

-- A card into the chest: its finish, its corruption, how it came (the letter of the journal: "f" found, "e" a place
-- explored).
function RR:StashCard(card, finish, corruption, how)
	if card and ns.Guard and not ns.Guard:Allow(card.series, card) then
		return
	end
	local ch = card and card.key and self:Chest(true)
	if not ch then
		return
	end
	ch.cards = type(ch.cards) == "table" and ch.cards or {}
	ch.cards[CuratorOctoFull.Length(ch.cards) + 1] = { k = card.key, f = finish or nil, c = tonumber(corruption) or nil, h = how or nil }
	Changed()
end

-- (1.14.0) Cases of an edition into the chest (Cases.lua: the chance of a reroll, a quarter of it).
function RR:StashCase(case, n)
	n = math.floor(tonumber(n) or 0)
	if n > 0 and ns.Guard and not ns.Guard:Allow() then
		return
	end
	local ch = n > 0 and type(case) == "string" and self:Chest(true)
	if not ch then
		return
	end
	ch.cases = type(ch.cases) == "table" and ch.cases or {}
	ch.cases[case] = (tonumber(ch.cases[case]) or 0) + n
	Changed()
end

function RR:StashXP(n)
	n = math.floor(tonumber(n) or 0)
	if n > 0 and ns.Guard and not ns.Guard:Allow() then
		return
	end
	local ch = n > 0 and self:Chest(true)
	if not ch then
		return
	end
	ch.xp = (tonumber(ch.xp) or 0) + n
	Changed()
end

function RR:StashRubies(n)
	n = math.floor(tonumber(n) or 0)
	if n > 0 and ns.Guard and not ns.Guard:Allow() then
		return
	end
	local ch = n > 0 and self:Chest(true)
	if not ch then
		return
	end
	ch.rubies = (tonumber(ch.rubies) or 0) + n
	Changed()
end

-- Experience a character earns by playing: in the chest of a reroll (a quarter of it, quarter), else the collector's.
function RR:Gain(n, why, quarter)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 then
		return 0
	end
	if not self:IsReroll() then
		return ns.Level and ns.Level:Gain(n, why) or 0
	end
	if quarter then
		n = self:Quarter("xp:" .. tostring(why or ""), n)
	end
	self:StashXP(n)
	return 0
end

-- Rubies a character earns by playing (the talents of the collector): as Gain.
function RR:Rubies(n, id, quarter)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 then
		return 0
	end
	if not self:IsReroll() then
		return ns.Talents and ns.Talents:Rubies(n, id) or 0
	end
	if quarter then
		n = self:Quarter("rubies:" .. tostring(id or ""), n)
	end
	self:StashRubies(n)
	return 0
end

-- A card in the chest of this character already.
function RR:Holds(card)
	local ch = card and self:Chest()
	for _, x in ipairs((ch and ch.cards) or {}) do
		if x.k == card.key then
			return true
		end
	end
	return false
end

-- What a chest holds: { packs (boosters of albums), choice (boosters to choose), boosters (both), cards, xp, rubies,
-- albums = { { s, n } } (the largest first), cases (1.14.0: of every edition) }.
function RR:Contents(ch)
	ch = ch or self:Chest()
	local out = { packs = 0, choice = 0, boosters = 0, cards = 0, xp = 0, rubies = 0, albums = {}, list = {}, cases = 0 }
	if type(ch) ~= "table" then
		return out
	end
	for key, n in pairs(type(ch.packs) == "table" and ch.packs or {}) do
		n = tonumber(n) or 0
		local s = ns.SeriesByKey(key)
		if s and n > 0 then
			out.packs = out.packs + n
			out.albums[CuratorOctoFull.Length(out.albums) + 1] = { s = s, n = n }
		end
	end
	table.sort(out.albums, function(a, b)
		if a.n ~= b.n then
			return a.n > b.n
		end
		return a.s.key < b.s.key
	end)
	for _, n in pairs(type(ch.choice) == "table" and ch.choice or {}) do
		out.choice = out.choice + math.max(0, tonumber(n) or 0)
	end
	out.boosters = out.packs + out.choice
	for _, x in ipairs(type(ch.cards) == "table" and ch.cards or {}) do
		local card = ns.Cards[x.k or ""]
		if card then
			out.cards = out.cards + 1
			out.list[CuratorOctoFull.Length(out.list) + 1] = { card = card, finish = x.f }
		end
	end
	out.xp = math.max(0, tonumber(ch.xp) or 0)
	out.rubies = math.max(0, tonumber(ch.rubies) or 0)
	for _, n in pairs(type(ch.cases) == "table" and ch.cases or {}) do
		out.cases = out.cases + math.max(0, math.floor(tonumber(n) or 0))
	end
	return out
end

-- The chest of this character opens: all it holds goes to the account, the points of its own bars to the bars of the
-- account. What came (RR:Contents), nil when there was nothing at all.
function RR:Open()
	local db = ns.db
	local c = self:Char()
	if not (db and c) then
		return nil
	end
	-- (1.14.0: the cards changed by another addon this session: the chest stays closed; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil
	end
	local ch = c.chest
	local world, dungeon = (tonumber(c.rbar) or 0) / 100, (tonumber(c.rdbar) or 0) / 100
	c.chest, c.rbar, c.rdbar, c.rq = nil, nil, nil, nil
	if type(ch) ~= "table" and world <= 0 and dungeon <= 0 then
		return nil
	end
	local out = self:Contents(ch)
	for _, a in ipairs(out.albums) do
		ns.AddPacks(a.s, a.n)
	end
	if ns.Level then
		for kind, n in pairs(type(ch) == "table" and type(ch.choice) == "table" and ch.choice or {}) do
			n = math.floor(tonumber(n) or 0)
			if n > 0 then
				ns.Level:AddChoice(kind, n)
			end
		end
	end
	for _, x in ipairs((type(ch) == "table" and type(ch.cards) == "table") and ch.cards or {}) do
		local card = ns.Cards[x.k or ""]
		if card then
			ns.Collection:Grant(card, x.f, x.h, x.c)
		end
	end
	-- (1.14.0: its cases, among those to open: Cases.lua)
	if ns.Cases and type(ch) == "table" and type(ch.cases) == "table" then
		for case, n in pairs(ch.cases) do
			ns.Cases:Add(case, n)
		end
		ns.Fire("CASES_CHANGED")
	end
	if out.xp > 0 and ns.Level then
		ns.Level:Gain(out.xp, "chest")
	end
	if out.rubies > 0 and ns.Rubies then
		out.rubies = ns.Rubies:Gain(out.rubies, "talent", { talent = "chest" })
	end
	-- (the points of its own bars, on the bars of the account: the world's may give a booster of the place)
	local R = ns.Rewards
	if world > 0 then
		local bar = (tonumber(db.bar) or 0) + world
		local whole = math.floor(bar / ns.PACK_POINTS)
		db.bar = math.floor((bar - whole * ns.PACK_POINTS) * 10 + 0.5) / 10
		if whole > 0 and R then
			R:Give(R:WorldSeries(), whole, "chest", false, true, true)
		end
	end
	if dungeon > 0 then
		db.dbar = math.min(math.floor(((tonumber(db.dbar) or 0) + dungeon) * 10 + 0.5) / 10, ns.PACK_POINTS - 0.1)
	end
	c.opened = Now()
	ns.Fire("CHEST_OPENED", out)
	ns.Fire("CHANGED")
	return out
end

-- The chest of a character that is no reroll any more (its level, the main now): opened.
function RR:Check()
	if not ns.db or self.forceReroll then
		return
	end
	local c = self:Char()
	if c and (c.chest or c.rbar or c.rdbar or c.rq) and not self:IsReroll() then
		self:Open()
	end
end

-- A level the game just gave (Rewards.lua, before its points).
function RR:OnLevel(level)
	level = tonumber(level)
	if level and not Secret(level) then
		self.levelSeen = math.max(self.levelSeen or 0, level)
	end
	self:Check()
end

-------------------------------------------------------------------------------
-- The release of WoW Forever
-------------------------------------------------------------------------------
-- A realm of WoW Forever (not one of its beta: "Classic Beta PvE 2"), once its beta is over (RR.AFTER, the time of the
-- server: no release before). (1.14.0, his word: on its client only, Beta.lua; a realm of Classic Era is no realm of WoW
-- Forever, even for the author's build or the test build there: /curator test sortie shows the release on a copy.)
RR.AFTER = 1792627200 -- 2026-10-22 00:00 UTC
function RR:OnForever()
	if Now() < self.AFTER then
		return false
	end
	if ns.Beta and ns.Beta.ForeverClient and not ns.Beta:ForeverClient() then
		return false
	end
	local realm = Safe(GetRealmName)
	if type(realm) ~= "string" or realm == "" then
		return false
	end
	return not string.find(string.lower(realm), "beta", 1, true)
end

-- What the release keeps of a collection of the beta: the cards of these albums (the limited editions: Hallow's End,
-- the Hardcup Saison 3), their copies and their seals, and their boosters not opened yet (its displays among them:
-- only Hallow's End has any); these achievements, and the title of one of them; the codes of the website already used
-- (db.gifts, untouched: never twice), its settings, and the id the website knows it by (db.cid: what the collection
-- held at the end of the beta is all it may keep there, lib/forever.ts of the website).
RR.KEEP = { hallow = true, hardcup = true }
RR.KEEP_ACH = { beta = true, pioneer = true, hardcup = true }
-- (1.14.0, his word: no booster of welcome, at the release either)
-- the mark of this release (db.forever.w): a mark without it (a test build of before) does not count
RR.WIPE = 1

-- A card of an album the release keeps.
function RR.Kept(key)
	local card = type(key) == "string" and ns.Cards and ns.Cards[key]
	return (card and card.series and RR.KEEP[card.series.key] == true) or false
end

-- The save went through the release.
function RR:Through(db)
	db = db or ns.db
	return type(db) == "table" and type(db.forever) == "table" and db.forever.w == self.WIPE
end

-- What the release keeps, taken from the save before it is emptied.
local function Keep(db)
	local k = { cards = {}, copies = {}, sealed = {}, packs = {}, displays = {}, cased = {}, ach = {} }
	local copies = type(db.copies) == "table" and db.copies or {}
	local sealed = type(db.sealed) == "table" and db.sealed or {}
	for key, e in pairs(type(db.cards) == "table" and db.cards or {}) do
		if RR.Kept(key) then
			k.cards[key], k.copies[key], k.sealed[key] = e, copies[key], sealed[key]
		end
	end
	local cased = type(db.cased) == "table" and type(db.cased.d) == "table" and db.cased.d or {}
	for key in pairs(RR.KEEP) do
		k.packs[key] = type(db.packs) == "table" and db.packs[key] or nil
		k.displays[key] = type(db.displays) == "table" and db.displays[key] or nil
		k.cased[key] = cased[key]
	end
	for id in pairs(RR.KEEP_ACH) do
		k.ach[id] = type(db.ach) == "table" and db.ach[id] or nil
	end
	-- (Hardcup Survivor: its count, the cards of the Hardcup that came with the code, Gifts.lua)
	k.hardcup = type(db.stats) == "table" and db.stats.hardcup or nil
	local AC = ns.Achievements
	local x = db.title and AC and AC.SPECIAL_BY and AC.SPECIAL_BY[db.title]
	k.title = (x and RR.KEEP_ACH[x.ach] and k.ach[x.ach]) and db.title or nil
	k.cid = db.cid
	return k
end

-- What the release keeps, put back into the save emptied.
local function PutBack(db, k)
	for key, e in pairs(k.cards) do
		db.cards[key] = e
	end
	if next(k.copies) then
		db.copies = type(db.copies) == "table" and db.copies or {}
		for key, list in pairs(k.copies) do
			db.copies[key] = list
		end
	end
	if next(k.sealed) then
		db.sealed = type(db.sealed) == "table" and db.sealed or {}
		for key, g in pairs(k.sealed) do
			db.sealed[key] = g
		end
	end
	for key, n in pairs(k.packs) do
		db.packs[key] = n
	end
	if next(k.displays) then
		db.displays = type(db.displays) == "table" and db.displays or {}
		for key, n in pairs(k.displays) do
			db.displays[key] = n
		end
	end
	if next(k.cased) then
		db.cased = type(db.cased) == "table" and db.cased or {}
		db.cased.d = type(db.cased.d) == "table" and db.cased.d or {}
		for key, n in pairs(k.cased) do
			db.cased.d[key] = n
		end
	end
	for id, t in pairs(k.ach) do
		db.ach[id] = t
	end
	if k.hardcup then
		db.stats.hardcup = k.hardcup
	end
	db.title = k.title
	db.cid = k.cid
end

-- What a collection started over leaves besides its cards (Core.lua: ns.EmptyCollection): the trades under way and the
-- boosters they held, what the other players showed, the luck of the boosters, the shops and the quests of the day, the
-- cases (to open, their keys, the cards they gave), the contracts under way, what Hallow's End counted (its gift of
-- welcome given stays given), the rubies of the week and their ledger, the messages to deliver, the talents, the
-- characters and their chests. The release (RR:Migrate); (1.14.0, his word) /curator reset confirm (Core.lua:
-- ns.ResetCollection).
function RR:EmptyRest(db)
	db.trades, db.held, db.met, db.guild = {}, {}, {}, {}
	db.luck, db.daily, db.resell, db.dispShop, db.cases = nil, nil, nil, nil, nil
	db.kLog, db.cap100 = nil, nil
	db.qmend, db.qrr, db.questClaims = nil, nil, nil
	db.hallow = { welcome = type(db.hallow) == "table" and db.hallow.welcome or nil }
	db.ruby = { back = type(db.ruby) == "table" and db.ruby.back or nil }
	if type(db.wire) == "table" then
		db.wire.out = {}
	end
	db.talents = {}
	if ns.Talents then
		ns.Talents.pending = nil
	end
	db.chars, db.main = {}, nil
end

-- The collection goes through the release (once): emptied as a new one, but for what the release keeps (RR.KEEP,
-- RR.KEEP_ACH; a test collection keeps nothing of it, nor one started over from the window of a suspended Curator:
-- nothing), the characters of the beta forgotten, the boosters of welcome again. early: at the loading of the save,
-- before anything reads it (RR:Release): nothing told to the rest yet.
function RR:Migrate(early, nothing)
	local db = ns.db
	if not db or self:Through(db) then
		return false
	end
	local xp = math.max(0, math.floor(tonumber(db.xp) or 0))
	local LV = ns.Level
	local lvl = (LV and LV.Of and (LV.Of(xp))) or 1
	-- (a new collection: nothing to tell of the release)
	local had = (type(db.cards) == "table" and next(db.cards) ~= nil) or xp > 0 or (tonumber(db.opened) or 0) > 0
	-- (what I gave in a trade I accepted, held until the other side confirms: back to me first, Trade.lua; the release
	-- keeps of it what it keeps)
	if not nothing and ns.Trade and ns.Trade.GiveBackAll then
		ns.Trade:GiveBackAll()
	end
	local k = (not nothing and not db.test) and Keep(db) or nil
	-- (Core.lua: the cards, the boosters, the levels, the achievements, the rubies, the copies, the quests, the trades
	-- of the inns and the PvP, the duels, the golden quest, the journal; the achievements Beta tester and Pioneer stay)
	ns.EmptyCollection(db, true)
	self:EmptyRest(db)
	if k then
		PutBack(db, k)
	else
		db.title = nil
	end
	db.welcomed, db.welcomePacks = false, nil
	db.forever = { t = Now(), xp = xp, lvl = lvl, w = self.WIPE, v = ns.version }
	self.migrated = had and xp or nil
	self.settle = true
	if not early then
		ns.Fire("FOREVER_RESET", xp)
		ns.Fire("TALENTS_CHANGED")
		ns.Fire("CLAIMS_CHANGED")
		ns.Fire("CHANGED")
	end
	return true
end

-- A save of the beta put back after the release, its mark copied into it: what the release let go is there again, of
-- before it went through (none can be: the release took it all): a card of an album it does not keep, or one of its
-- copies; an achievement it does not keep; a line of the journal (the release empties it). Past RR.STALE_MARGIN only
-- (a clock of the server read a little off: the beta closed days before the release). Curator stops for it as for a
-- save edited outside the game (Beta.lua, B:Suspended): its window says so, and how to start over.
RR.STALE_MARGIN = 86400
function RR:Stale(db)
	db = db or ns.db
	local t = self:Through(db) and tonumber(db.forever.t)
	if not t then
		return false
	end
	t = t - self.STALE_MARGIN
	local copies = type(db.copies) == "table" and db.copies or {}
	for key, e in pairs(type(db.cards) == "table" and db.cards or {}) do
		if ns.Cards and ns.Cards[key] and not RR.Kept(key) then
			if type(e) == "table" and type(e.t) == "number" and e.t < t then
				return true
			end
			for _, c in ipairs(type(copies[key]) == "table" and copies[key] or {}) do
				if type(c) == "table" and type(c.t) == "number" and c.t < t then
					return true
				end
			end
		end
	end
	for id, at in pairs(type(db.ach) == "table" and db.ach or {}) do
		if not RR.KEEP_ACH[id] and type(at) == "number" and at < t then
			return true
		end
	end
	for _, line in ipairs(type(db.journal) == "table" and db.journal or {}) do
		local at = type(line) == "string" and tonumber(CuratorOctoFull.Match(line, "^(%d+),"))
		if at and at < t then
			return true
		end
	end
	return false
end

-- At the loading of the save (Core.lua: its cards made, before anything reads the collection): the release, once, on a
-- realm of WoW Forever; past it, a save of the beta put back in its place stops Curator. A save edited outside the
-- game stays as it is: suspended, it starts over from its window.
function RR:Release()
	local db = ns.db
	if not db or db.edited then
		return
	end
	if not self:Through(db) then
		if self:OnForever() then
			self:Migrate(true)
		end
	elseif self:Stale(db) then
		db.edited = true
		db.editedWhy = { k = "stale", t = Now(), v = ns.version }
	end
end

-- (1.14.0, later) A collection started over from the window of a suspended Curator (Core.lua, ns.ResetCollection) on a
-- realm of WoW Forever, the release not gone through yet: it goes through now, keeping nothing, so that it does not
-- come again at the next login and take what this session gives.
function RR:StartedOver()
	local db = ns.db
	if db and not self:Through(db) and self:OnForever() then
		self:Migrate(false, true)
		self.migrated = nil
	end
end

-------------------------------------------------------------------------------
-- At the login
-------------------------------------------------------------------------------
-- The record of this character goes with its GUID: one made again under the same name (the other one deleted)
-- starts anew, without the chest of the one before.
function RR:Bind()
	local c = self:Char()
	local g = self:Guid()
	if not (c and g) then
		return
	end
	if c.guid and c.guid ~= g then
		for k in pairs(c) do
			c[k] = nil
		end
		c.quests, c.obj, c.skills = {}, {}, {}
	end
	c.guid = g
end

function RR:OnLogin()
	-- (a login: a character of its own, its level as the game says it)
	self.levelSeen, self.ask, self.firstMain = nil, nil, nil
	local db = ns.db
	if not db or (ns.Beta and ns.Beta:Over()) then
		return
	end
	-- (at the loading of the save as a rule, RR:Release; here should the realm not have been known then)
	if not self:Through(db) and self:OnForever() then
		self:Migrate()
	end
	-- (the session of the release: its mark no later than this moment, before which nothing is earned; RR:Stale)
	if self.settle and self:Through(db) then
		db.forever.t = math.min(tonumber(db.forever.t) or Now(), Now())
	end
	self.settle = nil
	self:Bind()
	if not self:Active() then
		return
	end
	-- (1.14.3: the choice of the main given back, once)
	if self:ResetChoice(db) then
		self.resetSaid = true
	end
	local c = self:Char()
	if not self:Main() then
		-- (the first character met on WoW Forever: the main, without asking)
		self:SetMain(true)
		self.firstMain = true
	elseif c and not c.asked and self:IsReroll() then
		self.ask = true
	end
	self:Check()
end

ns.On("LOGIN", function()
	RR:OnLogin()
end)

-- What it says at the login: the release went through; who is the main; a reroll and its chest.
ns.On("LOGIN", function()
	if not ns.Delay then
		return
	end
	ns.Delay(7, function()
		if not ns.db then
			return
		end
		if RR.migrated then
			ns.Print(L["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."])
			RR.migrated = nil
		end
		if not RR:Active() then
			return
		end
		-- (1.14.3: the choice of the main given back, said once)
		if RR.resetSaid then
			RR.resetSaid = nil
			if not RR.firstMain then
				ns.Print(string.format(L["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."], RR:MainName()))
			end
		end
		if RR.firstMain then
			RR.firstMain = nil
			ns.Print(string.format(L["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."], RR:MainName(), RR.LEVEL))
		elseif RR:IsReroll() then
			local got = RR:Contents()
			ns.Print(string.format(L["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"], RR.LEVEL, got.boosters, got.cards))
		end
		if RR.ask then
			RR.ask = nil
			if ns.RerollUI then
				ns.RerollUI:Ask()
			end
		end
	end, RR)
end)
