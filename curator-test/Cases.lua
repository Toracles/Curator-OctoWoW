local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- (1.14.0, after its first test) What the draws and the grades use, taken as this file loads: a function of the game
-- put in its place later (a /run, another addon) changes nothing here. The draw of chance of the game (math.random), as
-- the game gives it; already replaced when this file loads (by an addon loaded before Curator): a draw of its own.
local ipairs, pairs, type, tonumber, tostring, pcall = ipairs, pairs, type, tonumber, tostring, pcall
local floor, max, min = math.floor, math.max, math.min
local byte = string.byte
local random
do
	local r = math.random
	if type(r) == "function" and (not issecurevariable or issecurevariable(math, "random")) then
		random = r
	else
		-- (the minimal standard of Park and Miller, exact in the numbers of Lua; seeded from the clock)
		local seed = CuratorOctoFull.Mod(floor(((GetTime and GetTime()) or 0) * 1000 + ((time and time()) or 0)) , 2147483646) + 1
		random = function(a, b)
			seed = CuratorOctoFull.Mod((seed * 16807) , 2147483647)
			local u = seed / 2147483647
			if not a then
				return u
			end
			if not b then
				a, b = 1, a
			end
			return a + floor(u * (b - a + 1))
		end
	end
end
-- (whether the game has an item: its own function, as it was when this file loaded)
local ItemExists
do
	local f = C_Item and C_Item.DoesItemExistByID
	if type(f) == "function" and (not issecurevariable or issecurevariable(C_Item, "DoesItemExistByID")) then
		ItemExists = f
	end
end

-------------------------------------------------------------------------------
-- (1.14.0) The cases, for real: the case of the month (its first edition, the case of the Paladin Collection No. 1:
-- Data/CratePaladin.lua) drops, as the cases of CS2, and opens with a key of its edition.
-- * Where they come from: one chance in a hundred on each creature that gives experience (Rewards.lua: the kills that
--   count, ACTIVITY "kill"), four in a hundred on each quest turned in, the game's (the first time: ACTIVITY "quest")
--   and Curator's (a quest of a board claimed, those claimed at the end of their period, a golden quest turned in). No
--   limit of a day: the key is the brake. A reroll under its level (Reroll.lua) a quarter of the chance, its case in its
--   chest, as everything it earns.
-- * A key of its edition, bought for CS.KEY_PRICE rubies (none given): one key, one case.
-- * Opened (UI/Crate.lua, its band and its card): a case and a key go, the card is drawn here, from what this file took
--   for itself as the files loaded (the cards of each case, its ranks and their chances, the weapons of legend, the
--   finishes, the grades: never from the tables of the windows, within reach of another addon), kept at once, and only
--   then shown: the band runs to it. A card of a case is none of the albums: no contract of the albums, no booster takes
--   it (the Bourse and the reseller do: Market.lua, Reseller.lua).
-- * (1.14.0, after its first test) Its cards are cards of the inventory (UI/CaseInventory.lua) and of an album of their
--   own, the collection of their edition (UI/CaseAlbum.lua), never mixed with the cards of the boosters:
--   - appraised at a banker (CS:Appraise): the grade it came with, hidden in its condition (a mint card is a 9 or a 10),
--     told, its marks and its certificate printed, in its case; never drawn again. (1 November, his word) Restored at
--     the enchanters as the copies of the albums are (Restore.lua: its quote, the flaws he mends; w0, wx, wa, hm, rr,
--     aw, dq on its record): appraised, its appraisal is no more when it is left there, its new grade hidden until it
--     is appraised again.
--   - exchanged by contract between them only (CS:Contract): ten cards of a rank for one of the next, up to the covert
--     rank (a priceless card comes out of a case only); its edition one of those of the cards given (as many chances as
--     cards of it), its card among those of its rank; its grade the mean of theirs; its finish drawn as a case draws it.
-- What is kept, under the seal of the save: db.cases = { n = { [case] = to open }, keys = { [case] = keys },
-- won = { { i = its number, c = its case, r = its rank (1 to 5), e = its card (the key of its entry: "s" a spell, "n" a
-- figure, "a" an armour) or w = its weapon (its item, l its line, cl its class, fa its side), f = its finish ("thunder",
-- "titan"), q = its grade (1 to 10) as it is kept, mixed with its number (CS.Grade tells it; appraised: g = its grade, as
-- it is), t = when, h = how it came ("k": a contract; nil: a case), ap = appraised (its marks m, its certificate ce, when
-- at); (1.14.0, his idea) pt its pattern, titanforged (1 to 19683, Patterns.lua: drawn once, kept with it) } ... },
-- next = the number of the next card, opened = { [case] = opened }, got =
-- { [case] = come } }; the counters (ns.Stats: casesGot, casesOpened, caseKeys, caseContracts; appraised, grade10).
-------------------------------------------------------------------------------
local CS = {}
ns.Cases = CS

-- a key of a case, in rubies
CS.KEY_PRICE = 999
-- the chance of a case: a creature that gives experience, a quest turned in
CS.KILL = 0.01
CS.QUEST = 0.04
-- the case that drops now (the case of the month), and the collection its cards are of
CS.EDITION = "paladin1"
CS.COLLECTION = { paladin1 = "Paladin Collection 2026" }
-- the ranks (UI/Crate.lua, CR.RANKS): the last one, the priceless cards (the weapons of legend)
CS.TOP = 5

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) The grade a card came with, hidden in its condition until it is appraised
-------------------------------------------------------------------------------
-- the conditions of a card: the lowest grade of each, its word (as the window of the cases shows them, UI/Crate.lua)
CS.CONDITION = { { 9, "Mint" }, { 7, "Excellent" }, { 5, "Good" }, { 3, "Worn" }, { 1, "Poor" } }

-- The word of the condition of a grade; the step of a word (1: Mint ... 5: Poor).
local function WordOf(g)
	g = tonumber(g) or 1
	for _, c in ipairs(CS.CONDITION) do
		if g >= c[1] then
			return c[2]
		end
	end
	return CS.CONDITION[CuratorOctoFull.Length(CS.CONDITION)][2]
end
CS.WordOf = WordOf

function CS.Step(word)
	for i, c in ipairs(CS.CONDITION) do
		if c[2] == word then
			return i
		end
	end
	return CuratorOctoFull.Length(CS.CONDITION)
end

-- (kept in the save mixed with the number of its card, its edition and when it came: never as it is; a number from 0 to
-- 9 of the card)
local SALT = 40961
local function Mix(rec)
	local s = tostring(floor(tonumber(rec.i) or 0)) .. ":" .. tostring(rec.c) .. ":" .. tostring(floor(tonumber(rec.t) or 0))
	local h = SALT
	for k = 1, CuratorOctoFull.Length(s) do
		h = CuratorOctoFull.Mod((h * 33 + byte(s, k)) , 1000003)
	end
	return CuratorOctoFull.Mod(h , 10)
end

-- The grade of a card won (its record, the save's own): appraised, as it is; else from what is kept of it.
local function Grade(rec)
	if rec.ap or rec.q == nil then
		return max(1, min(10, floor(tonumber(rec.g) or 5)))
	end
	return CuratorOctoFull.Mod((floor(tonumber(rec.q) or 0) - Mix(rec)) , 10) + 1
end
CS.Grade = Grade

-- Its grade kept hidden (its number, its edition, when it came: set before).
local function Hide(rec, g)
	rec.q = CuratorOctoFull.Mod((max(1, min(10, floor(tonumber(g) or 5))) - 1 + Mix(rec)) , 10)
	rec.g = nil
end
-- (1 November, the cards of the cases restored too: Restore.lua hides the grade the enchanter left)
CS.HideGrade = Hide

-------------------------------------------------------------------------------
-- (31 October, his word: the cards of the cases worn as those of the boosters, their condition no more in words) The
-- wear of a card won, as Wear.lua gives the one of a copy of the albums (UI/Wear.lua draws it on the card): its seed (wv:
-- from what never changes of it, wherever it goes: its edition, its card, the moment it first came out; sold at the
-- Bourse, its buyer sees the very card the seller had), its four marks (those of its appraisal; else from its grade and
-- its seed, as Wear.lua makes those of a copy: exactly what the expert will find).
-------------------------------------------------------------------------------
local function WearSeed(w)
	local str = "case wear:" .. tostring(w.c) .. ":" .. tostring(w.e or ("w" .. tostring(w.w))) .. ":"
		.. tostring(floor(tonumber(w.ot or w.t) or 0))
	local a = 5381
	for k = 1, CuratorOctoFull.Length(str) do
		a = CuratorOctoFull.Mod((a * 33 + byte(str, k)) , 2147483647)
	end
	return CuratorOctoFull.Mod(a , 999998) + 1
end
CS.WearSeed = WearSeed

-- (31 October, the review of the night: the four marks of a card never appraised tell its grade, their lowest; they never
-- leave the save in plain text, veiled by its seed as its grade is mixed with its number in the save: what leaves this
-- file, a token, a link, a showcase carry them veiled; CS.WearOf lifts the veil)
local VEIL = "123456789A"
local function VeilKey(seed, i)
	local h = CuratorOctoFull.Mod(((CuratorOctoFull.Mod(floor(tonumber(seed) or 0) , 1000000)) * 7919 + i * 104729) , 2147483647)
	return CuratorOctoFull.Mod((CuratorOctoFull.Mod((h * 48271) , 2147483647)) , 10)
end
local function Veil(wm, seed, lift)
	if type(wm) ~= "string" or CuratorOctoFull.Length(wm) ~= 4 then
		return nil
	end
	local out = {}
	for i = 1, 4 do
		local v = string.find(VEIL, string.sub(wm, i, i), 1, true)
		if not v then
			return nil
		end
		local k = VeilKey(seed, i)
		local n = lift and (CuratorOctoFull.Mod((v - 1 - k) , 10)) or (CuratorOctoFull.Mod((v - 1 + k) , 10))
		out[i] = string.sub(VEIL, n + 1, n + 1)
	end
	return table.concat(out)
end
function CS.Veil(wm, seed)
	return Veil(wm, seed, false)
end
function CS.Unveil(wm, seed)
	return Veil(wm, seed, true)
end

local function ValidMarks(m)
	if type(m) ~= "table" then
		return false
	end
	for i = 1, 4 do
		local v = tonumber(m[i])
		if not (v and v >= 1 and v <= 10) then
			return false
		end
	end
	return true
end

-- Its four marks: appraised, those printed; else from its grade and its seed.
local function MarksOf(w, g, seed)
	local E, W = ns.Expertise, ns.Wear
	if w.ap and E and E.DecodeMarks then
		local m = E.DecodeMarks(w.m)
		if ValidMarks(m) then
			return m
		end
	end
	g = max(1, min(10, floor(tonumber(g) or 5)))
	if W and W.MarksFor and W.Rng then
		return W.MarksFor(g, W.Rng((tonumber(seed) or 1) + 77))
	end
	return { g, g, g, g }
end

-- The word of the condition of a card won: what leaves this file (cw), else its grade (appraised: as it is; the save's
-- own record: from what is kept).
function CS.Word(w)
	if w.ap then
		return WordOf(w.g)
	end
	if w.cw then
		return w.cw
	end
	return WordOf(Grade(w))
end

-------------------------------------------------------------------------------
-- What the draws take, kept here (out of reach of the other addons)
-------------------------------------------------------------------------------
-- The cards of each case, by rank, taken as this file loads (Data/Crate*.lua loaded before it, and nothing of another
-- addon since): the keys of their entries, as CrateItems.lua makes them.
local ENTRIES = {}
for key, def in pairs(ns.Crates or {}) do
	if type(key) == "string" and type(def) == "table" then
		local e = { {}, {}, {}, {} }
		for _, s in ipairs(type(def.spells) == "table" and def.spells or {}) do
			e[1][CuratorOctoFull.Length(e[1]) + 1] = "s" .. tostring(s[1])
		end
		for _, m in ipairs(type(def.masters) == "table" and def.masters or {}) do
			e[2][CuratorOctoFull.Length(e[2]) + 1] = "n" .. tostring(m[1])
		end
		for _, h in ipairs(type(def.heroes) == "table" and def.heroes or {}) do
			e[3][CuratorOctoFull.Length(e[3]) + 1] = "n" .. tostring(h[1])
		end
		-- (1.14.0, the Paladin collection redone: the figures of the covert rank, as the heroes)
		for _, h in ipairs(type(def.covert) == "table" and def.covert or {}) do
			e[4][CuratorOctoFull.Length(e[4]) + 1] = "n" .. tostring(h[1])
		end
		for _, s in ipairs(type(def.sets) == "table" and def.sets or {}) do
			e[4][CuratorOctoFull.Length(e[4]) + 1] = "a" .. tostring(s[1])
		end
		-- (its own weapons of legend, its priceless cards: none of another case, nor another of the list)
		if type(def.priceless) == "table" then
			local own = {}
			for _, w in ipairs(def.priceless) do
				local id = type(w) == "table" and tonumber(w[1]) or nil
				if id then
					own[id] = true
				end
			end
			e.priceless = own
		end
		ENTRIES[key] = e
	end
end
-- The grades of the expert (Expertise.lua, loaded before this file), as they are for everyone.
local GRADES = {}
for i, o in ipairs((ns.Expertise and ns.Expertise.ODDS) or { { 5, 1 } }) do
	GRADES[i] = { o[1], o[2] }
end
-- The chances of the ranks, the finishes, the weapons of legend (UI/Crate.lua, loaded after this file): taken when the
-- save loads (CS:Take, Core.lua: before any addon loaded after Curator runs), else those of CS2.
local TIERS, FINISHES, WEAPONS
local DEFAULT_TIERS = { { 1, 0.7992 }, { 2, 0.1598 }, { 3, 0.032 }, { 4, 0.0064 }, { 5, 0.0026 } }
local DEFAULT_FINISHES = { { "titan", 0.02 }, { "thunder", 0.08 } }

function CS:Take()
	if TIERS then
		return
	end
	local CR = ns.CrateUI
	TIERS, FINISHES, WEAPONS = {}, {}, {}
	for i, t in ipairs((CR and type(CR.TIERS) == "table" and CR.TIERS) or DEFAULT_TIERS) do
		TIERS[i] = { t[1], t[2] }
	end
	for i, f in ipairs((CR and type(CR.FINISHES) == "table" and CR.FINISHES) or DEFAULT_FINISHES) do
		FINISHES[i] = { f[1], f[2] }
	end
	for i, line in ipairs((CR and type(CR.WEAPONS) == "table" and CR.WEAPONS) or {}) do
		local l = {}
		for j, w in ipairs(line) do
			l[j] = { id = w.id, class = w.class, faction = w.faction }
		end
		WEAPONS[i] = l
	end
end

-- (the author's tests: the same draws as the players')
CS.Entries = function(case)
	return ENTRIES[case]
end

-- (the page of the statistics, Rates.lua) The chances the draws use, copies: the ranks, the finishes, the grades.
function CS:Odds()
	self:Take()
	local function Copy(list)
		local out = {}
		for i, x in ipairs(list) do
			out[i] = { x[1], x[2] }
		end
		return out
	end
	return Copy(TIERS), Copy(FINISHES), Copy(GRADES)
end

-- (1.14.0, his idea) The pattern of a titanforged card of a case (nil: none, not titanforged), one drawn, and the one
-- of a card that had none (of before; drawn from the collection and its number: the same after a game closed before it
-- saves).
local function PatternNo(v)
	v = tonumber(v)
	local max = (ns.Patterns and ns.Patterns.MAX) or 19683
	if v and v == floor(v) and v >= 1 and v <= max then
		return v
	end
	return nil
end

function CS.Pattern(w)
	if type(w) ~= "table" or w.f ~= "titan" then
		return nil
	end
	return PatternNo(w.pt)
end

local function DrawPattern()
	return random(1, (ns.Patterns and ns.Patterns.MAX) or 19683)
end
CS.DrawPattern = DrawPattern

local function DerivedPattern(w)
	local cid = ns.db and ns.db.cid
	local i = tonumber(w.i)
	if type(cid) ~= "string" or cid == "" or not i then
		return DrawPattern()
	end
	local str = "case pattern:" .. cid .. ":" .. tostring(floor(i))
	local a = 5381
	for k = 1, CuratorOctoFull.Length(str) do
		a = CuratorOctoFull.Mod((a * 33 + CuratorOctoFull.Byte(str, k)) , 2147483647)
	end
	return CuratorOctoFull.Mod(a , ((ns.Patterns and ns.Patterns.MAX) or 19683)) + 1
end

-- Each titanforged card its pattern, no other one.
local function Patterns(c)
	for _, w in ipairs(c.won) do
		if type(w) == "table" then
			if w.f == "titan" then
				if not PatternNo(w.pt) then
					w.pt = DerivedPattern(w)
				end
			elseif w.pt ~= nil then
				w.pt = nil
			end
		end
	end
end

-------------------------------------------------------------------------------
-- The save
-------------------------------------------------------------------------------
-- (the list of the cards won whose numbers were looked at: a mark of this session, never in the save)
local numbered
local function Db()
	local db = ns.db
	if not db then
		return nil
	end
	local c = db.cases
	if type(c) ~= "table" then
		c = {}
		db.cases = c
	end
	for _, k in ipairs({ "n", "keys", "opened", "got" }) do
		if type(c[k]) ~= "table" then
			c[k] = {}
		end
	end
	if type(c.won) ~= "table" then
		c.won = {}
	end
	-- (the cards won before they had a number: one each, once)
	if numbered ~= c.won then
		local top = 0
		for _, w in ipairs(c.won) do
			if type(w) == "table" and type(w.i) == "number" and w.i > top then
				top = w.i
			end
		end
		c.next = max(floor(tonumber(c.next) or 1), top + 1)
		for _, w in ipairs(c.won) do
			if type(w) == "table" and type(w.i) ~= "number" then
				w.i = c.next
				c.next = c.next + 1
			end
		end
		-- (the grades of the cards not appraised, kept as they were before: hidden, once)
		for _, w in ipairs(c.won) do
			if type(w) == "table" and not w.ap and w.q == nil and w.g ~= nil then
				Hide(w, w.g)
			end
		end
		numbered = c.won
		-- (1.14.0: the patterns of the titanforged ones)
		Patterns(c)
		-- (31 October: the seed of the wear of each, derived from what never changes of it; once again for all, the seeds of
		-- the first test drawn otherwise)
		local again = (tonumber(c.wearSeeds) or 0) < 2
		for _, w in ipairs(c.won) do
			if type(w) == "table" and (again or not tonumber(w.wv)) then
				w.wv = WearSeed(w)
			end
		end
		c.wearSeeds = 2
	end
	return c
end
CS.Db = Db

-- The number of the next card won.
local function NextId(c)
	local id = max(1, floor(tonumber(c.next) or 1))
	c.next = id + 1
	return id
end

-- A copy of a record (what leaves this file: never the save's own table).
local function Copy(rec)
	local out = {}
	for k, v in pairs(rec) do
		out[k] = v
	end
	return out
end
CS.Copy = Copy

-- What leaves this file of a card won: a copy; its grade only once appraised (else the word of its condition, cw: the
-- windows of the game are within reach of a /run).
local function Public(rec)
	local out = Copy(rec)
	out.q = nil
	-- (1 November: what the enchanter left of its marks, told at its next appraisal only)
	out.hm = nil
	-- (31 October: its wear, its seed and its marks, as UI/Wear.lua draws it; never its grade in words)
	if not tonumber(rec.wv) then
		rec.wv = WearSeed(rec)
	end
	out.wv = rec.wv
	local E = ns.Expertise
	out.wm = E and E.EncodeMarks and Veil(E.EncodeMarks(MarksOf(rec, Grade(rec), rec.wv)), rec.wv) or nil
	if not rec.ap then
		out.g = nil
		out.cw = WordOf(Grade(rec))
	end
	return out
end
CS.Public = Public

-- (31 October) The wear of a card of a case as UI/Wear.lua draws it ({ g, m, seed }; nil: none): what left this file
-- (its seed, its marks), else what is known of it (a card of another player, of the Bourse: its condition, its grade).
local GRADE_OF_WORD = { Mint = 9, Excellent = 7, Good = 5, Worn = 3, Poor = 1 }
function CS.WearOf(w)
	if type(w) ~= "table" then
		return nil
	end
	local seed = tonumber(w.wv)
	if not seed then
		seed = WearSeed(w)
	end
	local E = ns.Expertise
	-- (1 November, restored at an enchanter, Restore.lua: its pieces laid for good as they were the first time, w0 veiled
	-- by its seed; those he mended gone, wx; what went wrong at his bench, wa)
	local w0 = type(w.w0) == "string" and E and E.DecodeMarks and E.DecodeMarks(Veil(w.w0, seed, true)) or nil
	if ValidMarks(w0) then
		return { g = min(w0[1], w0[2], w0[3], w0[4]), m = w0, seed = seed, x = type(w.wx) == "string" and w.wx or nil,
			a = type(w.wa) == "string" and w.wa or nil }
	end
	-- (its marks as they travel: veiled by its seed)
	local m = E and E.DecodeMarks and w.wm and E.DecodeMarks(Veil(w.wm, seed, true)) or nil
	if not ValidMarks(m) then
		-- (its grade: appraised, as told; of the Bourse, as it travels; the save's own, hidden in it; else its condition)
		local g
		if w.ap and tonumber(w.g) then
			g = tonumber(w.g)
		elseif tonumber(w.grade) then
			g = tonumber(w.grade)
		elseif w.q ~= nil or tonumber(w.g) then
			g = Grade(w)
		else
			g = (w.cw and GRADE_OF_WORD[w.cw]) or 8
		end
		m = MarksOf(w, g, seed)
	end
	local g = min(m[1], m[2], m[3], m[4])
	return { g = g, m = m, seed = seed }
end

-- (what its wear looks like, in a word: a card drawn again only when it changed)
function CS.WearKey(w)
	local x = CS.WearOf(w)
	return x and (table.concat(x.m, "") .. ":" .. tostring(x.seed) .. ":" .. tostring(x.x or "") .. ":" .. tostring(x.a or "")) or ""
end

-- The card won of that number: its place in the list, its record (the save's own).
local function Find(id)
	local c = Db()
	id = tonumber(id)
	if not (c and id) then
		return nil
	end
	for i, w in ipairs(c.won) do
		if type(w) == "table" and w.i == id then
			return i, w
		end
	end
	return nil
end

local function Int(v)
	v = floor(tonumber(v) or 0)
	return v > 0 and v or 0
end

-- (1 November, the cards of the cases restored too) The record of a card won, the save's own (Restore.lua only: the
-- enchanter works on it as Market.lua sells it).
function CS.Own(id)
	local _, w = Find(id)
	return w
end

-- A case of this key: one of the editions there are.
function CS:Known(case)
	return type(case) == "string" and ENTRIES[case] ~= nil
end

-- The cases of an edition waiting to be opened, its keys.
function CS:Count(case)
	local c = Db()
	return c and Int(c.n[case or self.EDITION]) or 0
end

function CS:Keys(case)
	local c = Db()
	return c and Int(c.keys[case or self.EDITION]) or 0
end

-- Every case waiting, of every edition.
function CS:Total()
	local c = Db()
	local n = 0
	for _, v in pairs(c and c.n or {}) do
		n = n + Int(v)
	end
	return n
end

-- The editions of which there is something (a case, a key, a card won), the edition of now first.
function CS:Editions()
	local c = Db()
	local seen, out = {}, {}
	local function Add(k)
		if self:Known(k) and not seen[k] then
			seen[k] = true
			out[CuratorOctoFull.Length(out) + 1] = k
		end
	end
	Add(self.EDITION)
	for _, t in ipairs({ c and c.n or {}, c and c.keys or {} }) do
		for k in pairs(t) do
			Add(k)
		end
	end
	for _, w in ipairs(c and c.won or {}) do
		Add(w.c)
	end
	return out
end

-- The cards won, of an edition (nil: all of them), the oldest first: copies of the records.
function CS:Won(case)
	local c = Db()
	local out = {}
	for _, w in ipairs(c and c.won or {}) do
		if type(w) == "table" and (not case or w.c == case) then
			out[CuratorOctoFull.Length(out) + 1] = Public(w)
		end
	end
	return out
end

-- How many copies of each card of an edition were won: { [entry key] = { n, thunder, titan, step, word } }, and the
-- weapons ({ [item] = the same }): the finest condition among them (its step, 1: Mint; its word), never a grade hidden.
function CS:Owned(case)
	local cards, weapons = {}, {}
	for _, w in ipairs(self:Won(case)) do
		local t
		if w.e then
			t = cards
		elseif w.w then
			t = weapons
		end
		local k = w.e or w.w
		if t and k then
			local o = t[k] or { n = 0, thunder = 0, titan = 0, step = CuratorOctoFull.Length(CS.CONDITION) }
			o.n = o.n + 1
			if w.f == "thunder" then
				o.thunder = o.thunder + 1
			elseif w.f == "titan" then
				o.titan = o.titan + 1
			end
			o.step = min(o.step, CS.Step(CS.Word(w)))
			o.word = CS.CONDITION[o.step][2]
			t[k] = o
		end
	end
	return cards, weapons
end

-- The cards of the collection of an edition won (each counted once), of how many there are; the weapons of legend won.
function CS:Progress(case)
	case = case or self.EDITION
	local e = ENTRIES[case]
	local cards, weapons = self:Owned(case)
	local owned, total, nw = 0, 0, 0
	for r = 1, 4 do
		for _, key in ipairs(e and e[r] or {}) do
			total = total + 1
			if cards[key] then
				owned = owned + 1
			end
		end
	end
	for _, o in pairs(weapons) do
		nw = nw + o.n
	end
	return owned, total, nw
end

-- A card won, by its number: a copy of its record (nil: none of that number).
function CS:Card(id)
	local _, w = Find(id)
	return w and Public(w) or nil
end

-- How fine a card won looks, to show it first (never by a grade hidden): appraised (its grade), its condition, forged
-- (titanforged, thunderforged).
local FIN_SCORE = { titan = 2, thunder = 1 }
function CS.Score(w)
	-- (31 October, the review of the night: its condition never told but by the expert, nor by the order of its copies:
	-- appraised, its grade; else nothing, its finish only)
	local seen = w.ap and (100 + (tonumber(w.g) or 0)) or 0
	return seen * 10 + (FIN_SCORE[w.f or ""] or 0)
end

-- The finest copy won of a card of an edition (key: its entry; weapon: true, a weapon of legend of that line), a copy of
-- its record, else nil.
function CS:Best(case, key, line)
	local best, bs
	for _, w in ipairs(self:Won(case)) do
		if (line and w.w and w.l == line) or (not line and w.e == key) then
			local s = CS.Score(w)
			if not best or s > bs or (s == bs and (w.i or 0) > (best.i or 0)) then
				best, bs = w, s
			end
		end
	end
	return best
end

-------------------------------------------------------------------------------
-- The keys
-------------------------------------------------------------------------------
-- (1.14.0) What a key costs: Key Ring, a talent of the Gambler, makes it cheaper.
function CS:KeyPrice()
	return (ns.Rubies and ns.Rubies.Price) and ns.Rubies:Price(self.KEY_PRICE, "key") or self.KEY_PRICE
end

-- (1.14.0) Master Key: once a week, a case opens without a key.
local function MasterKey()
	local TL = ns.Talents
	return TL ~= nil and TL.Ready ~= nil and TL:Ready("masterkey")
end
-- A key of an edition bought (n of them): their rubies paid. True, else false and why ("rubies", "guard", "closed",
-- "case").
function CS:BuyKey(case, n)
	case = case or self.EDITION
	n = max(1, floor(tonumber(n) or 1))
	local c = Db()
	if not c or Closed() then
		return false, "closed"
	end
	if not self:Known(case) then
		return false, "case"
	end
	if not ns.Rubies then
		return false, "closed"
	end
	local ok, why = ns.Rubies:Spend(self:KeyPrice() * n, "casekey")
	if not ok then
		return false, why
	end
	c.keys[case] = Int(c.keys[case]) + n
	local st = ns.Stats()
	st.caseKeys = Int(st.caseKeys) + n
	ns.Fire("CASES_CHANGED")
	return true
end

-------------------------------------------------------------------------------
-- The drops
-------------------------------------------------------------------------------
-- A case of the edition of now comes (how: "kill", "quest", "board", "golden"; a reroll: into its chest). True when one
-- came.
function CS:Give(how, n, case)
	n = max(1, floor(tonumber(n) or 1))
	case = case or self.EDITION
	local c = Db()
	if not c or Closed() or not self:Known(case) then
		return false
	end
	-- (1.14.0: the cards changed by another addon this session: nothing comes; Guard.lua)
	if ns.Guard and not ns.Guard:Allow() then
		return false
	end
	local RR = ns.Reroll
	local chest = RR ~= nil and RR:IsReroll() and RR.StashCase ~= nil
	if chest then
		RR:StashCase(case, n)
	else
		self:Add(case, n)
	end
	ns.Fire("CASE_DROPPED", case, n, how, chest or nil)
	ns.Fire("CASES_CHANGED")
	return true
end

-- Cases of an edition among those to open (a drop; the chest of a reroll that opens: Reroll.lua).
function CS:Add(case, n)
	n = floor(tonumber(n) or 0)
	local c = Db()
	if not c or n <= 0 or not self:Known(case) then
		return
	end
	c.n[case] = Int(c.n[case]) + n
	c.got[case] = Int(c.got[case]) + n
	local st = ns.Stats()
	st.casesGot = Int(st.casesGot) + n
end

-- A chance of a case (p: of each try; a reroll, a quarter of it), tries times.
function CS:Chance(p, how, tries)
	if not ns.db or Closed() then
		return 0
	end
	local RR = ns.Reroll
	if RR and RR:IsReroll() then
		p = RR:Points(p)
	end
	-- (1.14.0, Nose for Cases: more often)
	local TL = ns.Talents
	if TL and TL.Has and TL:Has("cratenose") then
		p = p * (1 + TL:V("cratenose"))
	end
	-- (1.14.0: the Ironforge Ale, a dish of the day of the innkeepers, twice as often on the creatures and the quests;
	-- Lodging.lua)
	if ns.Lodging then
		p = p * ns.Lodging:CaseMult(how)
	end
	local got = 0
	for _ = 1, max(1, floor(tonumber(tries) or 1)) do
		if random() < p then
			got = got + 1
		end
	end
	if got > 0 then
		self:Give(how, got)
	end
	return got
end

local function Safely(fn, ...)
	local ok, err = pcall(fn, unpack(arg, 1, arg.n))
	if not ok and geterrorhandler then
		geterrorhandler()(err)
	end
end

-- (a creature that gives experience: Rewards.lua; a quest of the game, turned in the first time)
ns.On("ACTIVITY", function(kind, n)
	if kind == "kill" then
		Safely(CS.Chance, CS, CS.KILL, "kill", n)
	elseif kind == "quest" then
		Safely(CS.Chance, CS, CS.QUEST, "quest", n)
	end
end)
-- (a quest of a board of Curator claimed, those claimed at the end of their period, a golden quest turned in)
ns.On("QUEST_CLAIMED", function()
	Safely(CS.Chance, CS, CS.QUEST, "board", 1)
end)
ns.On("QUESTS_AUTOCLAIMED", function(auto)
	local n = type(auto) == "table" and floor(tonumber(auto.n) or 0) or 0
	if n > 0 then
		Safely(CS.Chance, CS, CS.QUEST, "board", n)
	end
end)
ns.On("GOLDEN_DONE", function()
	Safely(CS.Chance, CS, CS.QUEST, "golden", 1)
end)

-------------------------------------------------------------------------------
-- The opening
-------------------------------------------------------------------------------
local function Roll(list)
	local x = random()
	for _, t in ipairs(list) do
		if x < t[2] then
			return t[1]
		end
		x = x - t[2]
	end
	return nil
end

-- Whether the game has an item (a weapon of another time it does not have is never drawn).
local function Exists(id)
	if ItemExists then
		local ok, yes = pcall(ItemExists, id)
		return not ok or yes ~= false
	end
	return true
end

-- A weapon of legend: a line, each as likely as another, then one of its versions the game has. (1.14.0, the Paladin
-- collection redone: a case with weapons of its own, one of them, each as likely as another.)
local function DrawWeapon(case)
	local own = ENTRIES[case] and ENTRIES[case].priceless
	if own then
		local mine = {}
		for i, line in ipairs(WEAPONS) do
			for _, w in ipairs(line) do
				if own[w.id] then
					mine[CuratorOctoFull.Length(mine) + 1] = { id = w.id, class = w.class, faction = w.faction, line = i }
				end
			end
		end
		if CuratorOctoFull.Length(mine) > 0 then
			return mine[random(CuratorOctoFull.Length(mine))]
		end
	end
	for _ = 1, 40 do
		local i = random(CuratorOctoFull.Length(WEAPONS))
		local known = {}
		for _, w in ipairs(WEAPONS[i]) do
			if Exists(w.id) then
				known[CuratorOctoFull.Length(known) + 1] = w
			end
		end
		if CuratorOctoFull.Length(known) > 0 then
			local w = known[random(CuratorOctoFull.Length(known))]
			return { id = w.id, class = w.class, faction = w.faction, line = i }
		end
	end
	local w = WEAPONS[1] and WEAPONS[1][1]
	return w and { id = w.id, class = w.class, faction = w.faction, line = 1 } or nil
end

-- Whether a case of an edition can be opened now: nil, or why not ("none": no case, "key": no key, "closed").
function CS:CanOpen(case)
	case = case or self.EDITION
	if not ns.db or Closed() then
		return false, "closed"
	end
	if not self:Known(case) then
		return false, "case"
	end
	-- (1.14.0, after its test: a reroll opens no case, Reroll.lua)
	if ns.Reroll and ns.Reroll:NoOpening() then
		return false, "reroll"
	end
	if self:Count(case) <= 0 then
		return false, "none"
	end
	if self:Keys(case) <= 0 and not MasterKey() then
		return false, "key"
	end
	return true
end

-- A case of an edition opened: a case and a key go, its card is drawn and kept. What came (a copy of its record), else
-- nil and why ("none", "key", "guard", "closed", "case").
function CS:Open(case)
	case = case or self.EDITION
	local ok, why = self:CanOpen(case)
	if not ok then
		return nil, why
	end
	-- (1.14.0: the cards changed by another addon this session: the case and its key stay; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	self:Take()
	local c = Db()
	local tier = Roll(TIERS) or 1
	local rec = { i = NextId(c), c = case, r = tier, t = Now(), f = Roll(FINISHES) }
	-- (1.14.0: titanforged, its pattern)
	rec.pt = rec.f == "titan" and DrawPattern() or nil
	-- (31 October, Card Sleeves, a talent of the Archivist: a grade better now and then)
	local g0 = Roll(GRADES) or 5
	if ns.Talents and ns.Talents.Sleeves then
		g0 = ns.Talents:Sleeves(g0) or g0
	end
	Hide(rec, g0)
	if tier >= self.TOP then
		local w = DrawWeapon(case)
		if not w then
			tier = 1
			rec.r = 1
		else
			rec.w, rec.l, rec.cl, rec.fa = w.id, w.line, w.class, w.faction
		end
	end
	if not rec.w then
		local list = ENTRIES[case][tier]
		if not (list and CuratorOctoFull.Length(list) > 0) then
			return nil, "case"
		end
		rec.e = list[random(CuratorOctoFull.Length(list))]
	end
	c.n[case] = Int(c.n[case]) - 1
	-- (1.14.0, Master Key: no key of the edition left, the key of the week)
	local TL = ns.Talents
	if Int(c.keys[case]) <= 0 and MasterKey() then
		TL:Use("masterkey")
		rec.mk = true
	else
		c.keys[case] = Int(c.keys[case]) - 1
	end
	c.opened[case] = Int(c.opened[case]) + 1
	c.won[CuratorOctoFull.Length(c.won) + 1] = rec
	local st = ns.Stats()
	st.casesOpened = Int(st.casesOpened) + 1
	local out = Public(rec)
	-- (1.14.0, the Gambler: Kitty, rubies for each case opened; Till Money, a part of a key back for a card of the lowest
	-- rank)
	if TL and TL:Spec() == "gambler" then
		if TL:Has("kitty") then
			TL:Rubies(30 * TL:Rank("kitty"), "kitty")
		end
		if TL:Has("cashback") and tier == 1 then
			TL:Rubies(math.floor(self:KeyPrice() * TL:V("cashback")), "cashback")
		end
	end
	ns.Fire("CASE_OPENED", case, Public(rec))
	ns.Fire("CASES_CHANGED")
	return out
end

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) The expertise of a card of a case, at a banker (Expertise.lua)
-------------------------------------------------------------------------------
-- the price of an appraisal of a card of each rank: the price of the expert for the rarity of the albums so placed
-- (Expertise.lua: E.PRICE; a rare card of a case as an uncommon card of the albums, a priceless one as a mythic one)
CS.APPRAISE = { 2, 3, 4, 5, 6 }

-- The price of an appraisal of a card won (its rank; the talents of the expertise may lower it: Rubies.lua).
function CS:AppraisePrice(w)
	local E = ns.Expertise
	local base = (E and E.PRICE and E.PRICE[self.APPRAISE[tonumber(w and w.r) or 1] or 2]) or 800
	return (ns.Rubies and ns.Rubies.Price) and ns.Rubies:Price(base, "expertise") or base
end

-- Whether a card won can be appraised now: true, or false and why ("closed", "card": none of that number, "done":
-- appraised already, "away": at an enchanter, "cert": titanforged, not certified by a master of the mages (Mages.lua),
-- "bank": not at a banker, "rubies").
function CS:CanAppraise(id)
	if not ns.db or Closed() then
		return false, "closed"
	end
	local _, w = Find(id)
	if not w then
		return false, "card"
	end
	-- (1 November: at an enchanter)
	if type(w.aw) == "table" then
		return false, "away"
	end
	if w.ap then
		return false, "done"
	end
	-- (1 November, his word: a titanforged card, its certificate of a master of the mages first, Mages.lua)
	if ns.Mages and ns.Mages.Needs(w, true) then
		return false, "cert"
	end
	local E = ns.Expertise
	if not (E and E:AtBank()) then
		return false, "bank"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:AppraisePrice(w))) then
		return false, "rubies"
	end
	return true
end

-- A number of certificate for a card won (its number and the moment: eight digits).
local function CertFor(w)
	local h = 11
	local s = "case:" .. tostring(w.i) .. ":" .. tostring(Now())
	for i = 1, CuratorOctoFull.Length(s) do
		h = CuratorOctoFull.Mod((h * 31 + byte(s, i)) , 99999989)
	end
	return CuratorOctoFull.Mod((h + random(0, 9999)) , 100000000)
end

-- A card won appraised: its rubies paid, the grade it came with told (never drawn again), its four marks and its
-- certificate printed, in its case. What came: a copy of its record (and price), else nil and why (as CanAppraise,
-- "guard").
function CS:Appraise(id)
	local ok, why = self:CanAppraise(id)
	if not ok then
		return nil, why
	end
	-- (1.14.0: the cards changed by another addon this session: nothing paid, nothing appraised; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	local _, w = Find(id)
	local price = self:AppraisePrice(w)
	local paid, err = ns.Rubies:Spend(price, "expertise")
	if not paid then
		return nil, err
	end
	local E = ns.Expertise
	local g = Grade(w)
	-- (31 October: the marks its wear shows, exactly; its seed first, for a card of before)
	if not tonumber(w.wv) then
		w.wv = WearSeed(w)
	end
	local marks = MarksOf(w, g, w.wv)
	-- (1 November: restored at an enchanter, its true marks as his work left them, Restore.lua: told now)
	local hm = type(w.hm) == "string" and E and E.DecodeMarks and E.DecodeMarks(Veil(w.hm, w.wv, true)) or nil
	if ValidMarks(hm) then
		marks = hm
	end
	w.hm = nil
	w.g, w.q = g, nil
	w.ap = true
	w.m = E and E.EncodeMarks and E.EncodeMarks(marks) or nil
	w.ce = CertFor(w)
	w.at = Now()
	local st = ns.Stats()
	st.appraised = Int(st.appraised) + 1
	if g >= 10 then
		-- (a card restored before: its 10 is not of nature)
		if type(w.rr) == "table" and CuratorOctoFull.Length(w.rr) > 0 then
			st.restored10 = Int(st.restored10) + 1
		else
			st.grade10 = Int(st.grade10) + 1
		end
	end
	local out = Copy(w)
	out.price = price
	ns.Fire("CASE_APPRAISED", out)
	ns.Fire("CASES_CHANGED")
	if ns.Achievements and ns.Achievements.Queue then
		ns.Achievements:Queue()
	end
	return out
end

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) The contracts of the cards of the cases: between them only
-------------------------------------------------------------------------------
-- the cards a contract takes, the rank it gives at most (covert: a priceless card comes out of a case only)
CS.CONTRACT = 10
CS.CONTRACT_TOP = 4

-- Whether these cards won (their numbers) make a contract: true and their rank, or false and why ("closed", "count":
-- not CS.CONTRACT of them, "card": one is not won (or twice), "rank": not all of one rank, "top": a rank no contract
-- goes past; 1.14.0, after its test, his word: "reroll", this character is one, Reroll.lua: RR:Blocks).
function CS:CanContract(ids)
	if not ns.db or Closed() then
		return false, "closed"
	end
	if ns.Reroll and ns.Reroll:Blocks("contracts") then
		return false, "reroll"
	end
	if type(ids) ~= "table" or CuratorOctoFull.Length(ids) ~= self.CONTRACT then
		return false, "count"
	end
	local seen, rank = {}, nil
	for _, id in ipairs(ids) do
		local _, w = Find(id)
		if not w or seen[w.i] then
			return false, "card"
		end
		seen[w.i] = true
		-- (1.14.0: a card bought at the Bourse waits its quarantine: Market.lua)
		if w.mq and (tonumber(w.mq) or 0) > Now() then
			return false, "market"
		end
		-- (1 November: at an enchanter, Restore.lua)
		if type(w.aw) == "table" then
			return false, "away"
		end
		local r = tonumber(w.r) or 0
		if rank and r ~= rank then
			return false, "rank"
		end
		rank = r
	end
	if not rank or rank + 1 > self.CONTRACT_TOP then
		return false, "top"
	end
	return true, rank
end

-- What a contract of that rank may give (case: of that edition; nil: the edition of now): the entries of the next rank.
function CS:Outcomes(rank, case)
	local e = ENTRIES[case or self.EDITION]
	return e and e[(tonumber(rank) or 0) + 1] or {}
end

-- A contract signed: the cards given go, one of the next rank comes (its edition: one of theirs, as many chances as
-- cards of it; its card among those of that rank of its edition; its grade the mean of theirs; its finish drawn as a case
-- draws it). What came: a copy of its record, else nil and why (as CanContract, "guard").
function CS:Contract(ids)
	local ok, rank = self:CanContract(ids)
	if not ok then
		return nil, rank
	end
	-- (1.14.0: the cards changed by another addon this session: nothing given, nothing comes; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	self:Take()
	local c = Db()
	local given, sum = {}, 0
	local gone = {}
	-- (31 October, the contracts redone: every card given appraised, the one that comes appraised too: the clause of the
	-- experts)
	local certified = CuratorOctoFull.Length(ids) > 0
	for _, id in ipairs(ids) do
		local _, w = Find(id)
		given[CuratorOctoFull.Length(given) + 1] = w
		gone[w.i] = true
		sum = sum + Grade(w)
		if not w.ap then
			certified = false
		end
	end
	local from = given[random(CuratorOctoFull.Length(given))]
	local list = ENTRIES[from.c] and ENTRIES[from.c][rank + 1]
	if not (list and CuratorOctoFull.Length(list) > 0) then
		return nil, "top"
	end
	local rec = { i = NextId(c), c = from.c, r = rank + 1, e = list[random(CuratorOctoFull.Length(list))], t = Now(), h = "k", f = Roll(FINISHES) }
	rec.pt = rec.f == "titan" and DrawPattern() or nil
	local g = max(1, min(10, floor(sum / CuratorOctoFull.Length(given) + 0.5)))
	-- (31 October, Fine Print, a talent of the Smuggler: a step better than their average now and then)
	if g < 10 and ns.Talents and ns.Talents.FinePrint and ns.Talents:FinePrint() then
		g = g + 1
	end
	Hide(rec, g)
	if certified then
		local E = ns.Expertise
		rec.wv = WearSeed(rec)
		rec.g, rec.q, rec.ap = g, nil, true
		rec.m = E and E.EncodeMarks and E.EncodeMarks(MarksOf(rec, g, rec.wv)) or nil
		rec.ce = CertFor(rec)
		rec.at = Now()
		-- (1 November: titanforged, appraised only with its certificate of the mages, Mages.lua: the contract of experts
		-- writes it too)
		if rec.f == "titan" then
			rec.tc = { t = rec.at, m = 0 }
		end
		if ns.GradeTold then
			ns.GradeTold(g)
		end
	end
	local keep = {}
	for _, w in ipairs(c.won) do
		if not (type(w) == "table" and gone[w.i]) then
			keep[CuratorOctoFull.Length(keep) + 1] = w
		end
	end
	keep[CuratorOctoFull.Length(keep) + 1] = rec
	c.won = keep
	local st = ns.Stats()
	st.caseContracts = Int(st.caseContracts) + 1
	local out = Public(rec)
	local copies = {}
	for i, w in ipairs(given) do
		copies[i] = Public(w)
	end
	ns.Fire("CASE_CONTRACT", Public(rec), copies)
	ns.Fire("CASES_CHANGED")
	return out
end

-------------------------------------------------------------------------------
-- (1.14.0) The Bourse Gentepression (Market.lua): the cases and the cards of the cases that leave or come as they are
-------------------------------------------------------------------------------
-- Cases of an edition out of those to open (n below 0) or back among them, as they are: no drop counted. False when
-- there are not so many to take.
function CS:Move(case, n)
	n = floor(tonumber(n) or 0)
	local c = Db()
	if not c or n == 0 or not self:Known(case) then
		return false
	end
	if n < 0 and Int(c.n[case]) < -n then
		return false
	end
	local v = Int(c.n[case]) + n
	c.n[case] = v > 0 and v or nil
	ns.Fire("CASES_CHANGED")
	return true
end

-- (1.14.0, a player's word) Keys of an edition out (n below 0: sold to the reseller, Reseller.lua) or in. False when
-- there are not so many to take.
function CS:MoveKeys(case, n)
	n = floor(tonumber(n) or 0)
	local c = Db()
	if not c or n == 0 or not self:Known(case) then
		return false
	end
	if n < 0 and Int(c.keys[case]) < -n then
		return false
	end
	local v = Int(c.keys[case]) + n
	c.keys[case] = v > 0 and v or nil
	ns.Fire("CASES_CHANGED")
	return true
end

-- A card won out of the collection: its record, the save's own, out of the list (nil: none of that number).
function CS:TakeWon(id)
	local c = Db()
	local i, w = Find(id)
	if not (c and i) then
		return nil
	end
	CuratorOctoFull.Remove(c.won, i)
	ns.Fire("CASES_CHANGED")
	return w
end

-- A card won back as it was (its record: its number kept, the next ones after it). False when that number is there.
function CS:PutWon(rec)
	local c = Db()
	if not (c and type(rec) == "table" and type(rec.i) == "number") or Find(rec.i) then
		return false
	end
	c.won[CuratorOctoFull.Length(c.won) + 1] = rec
	c.next = max(floor(tonumber(c.next) or 1), rec.i + 1)
	ns.Fire("CASES_CHANGED")
	return true
end

-- (1.14.0) How a card of a case came, in words: an exchange contract, the Bourse, else a case.
function CS.How(w)
	local L = ns.L
	if w and w.h == "k" then
		return L["From an exchange contract"]
	elseif w and w.h == "m" then
		return L["Bought at the Exchange"]
	end
	return L["Out of a case"]
end

-- The true grade of a card won (its record, the save's own): what travels with it to the market, never shown there
-- before it is appraised.
function CS.TrueGrade(rec)
	return Grade(rec)
end

-- A card of a case come from the Bourse (it: { edition, rank, entry or weapon = { item, line, cls, side }, f = nil,
-- "thunder" or "titan", grade, ap = { m, ce, at } or nil, ot, oh }): a number of here, its grade hidden again with it
-- (appraised: as it was told), "m" as how it came, where it came from first kept (ot, oh). Its record (the save's own).
function CS:Receive(it)
	local c = Db()
	if not (c and type(it) == "table" and self:Known(it.edition)) then
		return nil
	end
	local rec = { i = NextId(c), c = it.edition, r = it.rank, t = Now(), h = "m", f = it.f, ot = it.ot, oh = it.oh }
	-- (1.14.0: titanforged, the pattern it had; none told, one of here)
	if rec.f == "titan" then
		rec.pt = PatternNo(it.pt) or DerivedPattern(rec)
	end
	if it.weapon then
		rec.w, rec.l = it.weapon.item, it.weapon.line
		rec.cl = (it.weapon.cls ~= nil and it.weapon.cls ~= "") and it.weapon.cls or nil
		rec.fa = (it.weapon.side ~= nil and it.weapon.side ~= "") and it.weapon.side or nil
	else
		rec.e = it.entry
	end
	if it.ap then
		rec.ap, rec.g, rec.m, rec.ce, rec.at = true, max(1, min(10, floor(tonumber(it.grade) or 5))), it.ap.m, it.ap.ce, it.ap.at
	else
		Hide(rec, it.grade)
	end
	-- (1 November, his word: the very same card at its buyer's: restored, what the enchanter did to it, Wear.lua: its
	-- marks of then and after veiled by its seed, the same here, made of what never changes of it)
	local x = it.wear and ns.Wear and ns.Wear.Unpack and ns.Wear.Unpack(it.wear, true)
	if x then
		rec.w0, rec.wx, rec.wa, rec.hm = x.w0, x.wx, x.wa, x.hm
		rec.wv = WearSeed(rec)
	end
	-- (1 November, his idea: titanforged, its certificate of a master of the mages with it, Mages.lua)
	local tc = it.tc and rec.f == "titan" and ns.Mages and ns.Mages.Unpack(it.tc)
	if tc then
		rec.tc = tc
	end
	c.won[CuratorOctoFull.Length(c.won) + 1] = rec
	ns.Fire("CASES_CHANGED")
	return rec
end
