local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.7.0) The code of a collection, to paste on the website of Curator: the collector, the character
-- that makes the code, the collection (each card owned: its copies, thunderforged and titanforged,
-- when it first came), the level, the achievements, the showcase and the journal (Collection.lua).
-- Made in the game, read by the website; the launcher of Curator reads it in the save (E:Save).
--
-- The text: E.PREFIX, then the bytes in base 64; the bytes end with their Adler-32 (4 bytes, the high
-- one first). A number is an unsigned LEB128 varint (7 bits a byte, the low ones first, the high bit
-- set while more follow); a string is its length in bytes (a varint), then its bytes (UTF-8).
--   format (1) · version of the addon · flags (1: a beta build, 2: a test collection, 4: a save edited
--     outside the game, 8: a tester of the beta, 16 (1.14.0): through the release of WoW Forever, its levels
--     started again) · server time of the code · id of the collector
--   the character: name · realm · GUID · region · faction (1 Alliance, 2 Horde, 0 other) · race id ·
--     class id · level
--   the collector: experience · boosters opened · contracts signed · cards found on creatures · on bosses
--   achievements: their count, then each: id · server time it was earned
--   showcase: its count, then each pinned card: npc
--   cards: their count, then each card owned, by npc: npc minus the npc before (the first: itself) ·
--     copies · thunderforged · titanforged · age + 1 (the server time of the code minus the time it
--     first came; 0: unknown)
--   journal: its count, then each line, the oldest first: seconds (the first: before the time of the
--     code; the others: after the line before) · npc · finish (0 normal, 1 thunderforged, 2
--     titanforged) · how (0 other, 1 a booster, 2 found on a creature, 3 a contract, 4 a trade, 5 in the
--     album before the journal, 6 a place explored, 7 a golden booster, 8 a golden quest turned in, 9 a card
--     bought for rubies: of the antiquarian, 1.11.0; of the reseller, 1.12.0; 10 a card of a gift code: of the
--     Hardcup Saison 3, 1.13.0, the id of the code as with whom) ·
--     booster (its number, 0 none) · with whom it was traded (7: the ticket of the golden quest; 8: its
--     ticket, tranche, album, week, creatures, gatherings, rares and dungeons, separated by colons)
-- Nothing in it draws a tirage (no math.random).
-------------------------------------------------------------------------------
local E = {}
ns.Export = E

E.PREFIX = "!CUR:1!"
E.FORMAT = 1
-- (1.10.0: g, a card of a golden booster, its ticket as with whom; q, a golden quest turned in, the NPC of its
-- leader, its ticket, tranche, album, week and counts as with whom, Golden.lua. A website or an app of
-- before reads them as "other".)
-- (1.13.0: c, a card of a gift code, the id of the code as with whom, Gifts.lua.)
-- (1.14.0: i, a card of an innkeeper, a bet or a signature, Tavern.lua and Inns.lua; x, a card given by the author;
-- p, a copy back from a trade that did not happen, Trade.lua, C:LogBack.)
-- (1.14.0, the Bourse: m, a copy bought at the market, the seller as with whom, Market.lua. The app 1.3.0 reads it as
-- "other"; the format of the code stays 1.)
-- (1.14.0, the rewards of the levels to choose: l, a card taken as the reward of a level, Level.lua: LV:Choose.)
E.HOW = { b = 1, f = 2, k = 3, t = 4, a = 5, e = 6, g = 7, q = 8, r = 9, c = 10, i = 11, x = 12, p = 13, m = 14, l = 15 }
local HOW = E.HOW
E.HOW_LETTERS = { "b", "f", "k", "t", "a", "e", "g", "q", "r", "c", "i", "x", "p", "m", "l" }

local byte, char, floor, concat, sort = string.byte, string.char, math.floor, table.concat, table.sort

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

-- A value of a call of the client, nil when the call fails or the value is secret.
local function Safe(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b, c = pcall(fn, unpack(arg, 1, arg.n))
	if not ok then
		return nil
	end
	if Secret(a) then
		a = nil
	end
	if Secret(b) then
		b = nil
	end
	if Secret(c) then
		c = nil
	end
	return a, b, c
end

-------------------------------------------------------------------------------
-- Bytes
-------------------------------------------------------------------------------
local function Varint(out, v)
	v = floor(tonumber(v) or 0)
	if v < 0 then
		v = 0
	end
	while v >= 128 do
		local low = CuratorOctoFull.Mod(v , 128)
		out[CuratorOctoFull.Length(out) + 1] = char(low + 128)
		v = (v - low) / 128
	end
	out[CuratorOctoFull.Length(out) + 1] = char(v)
end

local function Str(out, s)
	s = type(s) == "string" and s or tostring(s or "")
	Varint(out, CuratorOctoFull.Length(s))
	out[CuratorOctoFull.Length(out) + 1] = s
end

-- The Adler-32 of a string: its 4 bytes (the high one first) and its value.
local function Adler(s)
	local a, b = 1, 0
	local n = CuratorOctoFull.Length(s)
	for i = 1, n, 1024 do
		local bytes = { byte(s, i, math.min(i + 1023, n)) }
		for k = 1, CuratorOctoFull.Length(bytes) do
			a = CuratorOctoFull.Mod((a + bytes[k]) , 65521)
			b = CuratorOctoFull.Mod((b + a) , 65521)
		end
	end
	local v = b * 65536 + a
	return char(CuratorOctoFull.Mod(floor(v / 16777216) , 256), CuratorOctoFull.Mod(floor(v / 65536) , 256), CuratorOctoFull.Mod(floor(v / 256) , 256), CuratorOctoFull.Mod(v , 256)), v
end
E.Adler = Adler

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local ENC, DEC = {}, {}
for i = 1, 64 do
	local c = string.sub(B64, i, i)
	ENC[i - 1] = c
	DEC[byte(c)] = i - 1
end
local PAD = byte("=")

local function ToBase64(s)
	local out = {}
	for i = 1, CuratorOctoFull.Length(s), 3 do
		local a, b, c = byte(s, i, i + 2)
		local v = a * 65536 + (b or 0) * 256 + (c or 0)
		out[CuratorOctoFull.Length(out) + 1] = ENC[CuratorOctoFull.Mod(floor(v / 262144) , 64)] .. ENC[CuratorOctoFull.Mod(floor(v / 4096) , 64)]
			.. (b and ENC[CuratorOctoFull.Mod(floor(v / 64) , 64)] or "=") .. (c and ENC[CuratorOctoFull.Mod(v , 64)] or "=")
	end
	return concat(out)
end
E.ToBase64 = ToBase64

local function FromBase64(s)
	if CuratorOctoFull.Mod(CuratorOctoFull.Length(s) , 4) ~= 0 then
		return nil
	end
	local out = {}
	local last = CuratorOctoFull.Length(s) - 3
	for i = 1, CuratorOctoFull.Length(s), 4 do
		local c1, c2, c3, c4 = byte(s, i, i + 3)
		local pad3, pad4 = c3 == PAD, c4 == PAD
		-- (the padding: only at the very end, never a third sign alone)
		if (pad3 or pad4) and (i ~= last or (pad3 and not pad4)) then
			return nil
		end
		local v1, v2 = DEC[c1], DEC[c2]
		local v3 = pad3 and 0 or DEC[c3]
		local v4 = pad4 and 0 or DEC[c4]
		if not (v1 and v2 and v3 and v4) then
			return nil
		end
		local v = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
		local b1, b2, b3 = CuratorOctoFull.Mod(floor(v / 65536) , 256), CuratorOctoFull.Mod(floor(v / 256) , 256), CuratorOctoFull.Mod(v , 256)
		if pad3 then
			out[CuratorOctoFull.Length(out) + 1] = char(b1)
		elseif pad4 then
			out[CuratorOctoFull.Length(out) + 1] = char(b1, b2)
		else
			out[CuratorOctoFull.Length(out) + 1] = char(b1, b2, b3)
		end
	end
	return concat(out)
end
E.FromBase64 = FromBase64

-- Reads the bytes of a code: u() a number, str() a string; an error ("truncated") past the end.
local function Reader(s)
	local r = { i = 1 }
	local n = CuratorOctoFull.Length(s)
	function r.u()
		local v, m = 0, 1
		while true do
			local b = byte(s, r.i)
			if not b then
				error("truncated", 0)
			end
			r.i = r.i + 1
			if b < 128 then
				return v + b * m
			end
			v = v + (b - 128) * m
			m = m * 128
			if m > 2 ^ 49 then
				error("number", 0)
			end
		end
	end
	function r.str()
		local len = r.u()
		if r.i + len - 1 > n then
			error("truncated", 0)
		end
		local v = string.sub(s, r.i, r.i + len - 1)
		r.i = r.i + len
		return v
	end
	function r.count()
		-- (a count: never more than the bytes left, each item takes one at least)
		local c = r.u()
		if c > n - r.i + 1 then
			error("count", 0)
		end
		return c
	end
	function r.done()
		return r.i > n
	end
	return r
end

-------------------------------------------------------------------------------
-- The collector and the character
-------------------------------------------------------------------------------
-- The id of the collector: 16 hexadecimal digits, made once for the save (a new collection, emptied,
-- gets a new one). Drawn from the clock and the memory, not from math.random (the tirages stay the same).
function E:Id()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.cid) == "string" and CuratorOctoFull.Length(db.cid) == 16 and not string.find(db.cid, "[^0-9a-f]") then
		return db.cid
	end
	local parts = {
		tostring(Safe(GetServerTime) or 0), tostring(Safe(time) or 0), tostring(Safe(GetTime) or 0),
		tostring(Safe(debugprofilestop) or 0), tostring({}), tostring(db), tostring(Safe(UnitGUID, "player") or ""),
	}
	local sha = ns.Mandatory and ns.Mandatory.Sha256
	local h
	if sha then
		h = sha(concat(parts, "|"))
	else
		local _, v1 = Adler(concat(parts, "|"))
		local _, v2 = Adler(concat(parts, "#"):reverse())
		h = string.format(("%08x%08x"), v1, v2)
	end
	db.cid = string.sub(h, 1, 16)
	return db.cid
end

local FACTION = { Alliance = 1, Horde = 2 }

-- The character that makes the code.
function E:Character()
	local name = Safe(UnitName, "player")
	local _, _, race = Safe(UnitRace, "player")
	local _, _, class = Safe(UnitClass, "player")
	return {
		name = type(name) == "string" and name or "",
		realm = Safe(GetRealmName) or "",
		guid = Safe(UnitGUID, "player") or "",
		region = tonumber(Safe(GetCurrentRegion)) or 0,
		faction = FACTION[Safe(UnitFactionGroup, "player") or ""] or 0,
		race = tonumber(race) or 0,
		class = tonumber(class) or 0,
		level = tonumber(Safe(UnitLevel, "player")) or 0,
	}
end

-------------------------------------------------------------------------------
-- Made
-------------------------------------------------------------------------------
-- The bytes of the code (without their sum).
function E:Build(now)
	local db = ns.db
	if not db then
		return nil
	end
	local C = ns.Collection
	now = floor(tonumber(now) or Safe(GetServerTime) or 0)
	local out = {}
	Varint(out, E.FORMAT)
	Str(out, ns.version or "")
	local flags = 0
	if ns.Beta and ns.Beta.BETA then
		flags = flags + 1
	end
	-- (or a test build, never published: the one of WoW Classic Era, EraTest.lua. What is tried there never goes up
	-- to the website, which takes no code of a test collection)
	if db.test or ns.TEST_BUILD then
		flags = flags + 2
	end
	if db.edited then
		flags = flags + 4
	end
	if db.ach and db.ach.beta then
		flags = flags + 8
	end
	-- (1.14.0: the collection went through the release of WoW Forever: its levels started again from 1, Reroll.lua. The
	-- website takes its experience lower than the one it kept from before, and ranks it on the leaderboard of the
	-- release)
	if type(db.forever) == "table" then
		flags = flags + 16
	end
	Varint(out, flags)
	Varint(out, now)
	Str(out, self:Id())
	local ch = self:Character()
	Str(out, ch.name)
	Str(out, ch.realm)
	Str(out, ch.guid)
	Varint(out, ch.region)
	Varint(out, ch.faction)
	Varint(out, ch.race)
	Varint(out, ch.class)
	Varint(out, ch.level)
	local st = type(db.stats) == "table" and db.stats or {}
	Varint(out, db.xp)
	Varint(out, db.opened)
	Varint(out, db.contracts)
	Varint(out, st.found)
	Varint(out, st.bossFound)
	-- the achievements, by id
	local ach = {}
	for id, t in pairs(type(db.ach) == "table" and db.ach or {}) do
		if t then
			ach[CuratorOctoFull.Length(ach) + 1] = { id = tostring(id), t = tonumber(t) or 0 }
		end
	end
	sort(ach, function(a, b)
		return a.id < b.id
	end)
	Varint(out, CuratorOctoFull.Length(ach))
	for _, a in ipairs(ach) do
		Str(out, a.id)
		Varint(out, a.t)
	end
	-- the showcase, in its order (the cards still owned: C:Pins)
	local pins = {}
	for _, key in ipairs((C and C:Pins()) or (type(db.showcase) == "table" and db.showcase) or {}) do
		local card = ns.Cards[key]
		if card and card.npc then
			pins[CuratorOctoFull.Length(pins) + 1] = card.npc
		end
	end
	Varint(out, CuratorOctoFull.Length(pins))
	for _, npc in ipairs(pins) do
		Varint(out, npc)
	end
	-- the cards owned, by npc
	local cards = {}
	for key, e in pairs(type(db.cards) == "table" and db.cards or {}) do
		local card = ns.Cards[key]
		if card and card.npc and type(e) == "table" and (tonumber(e.n) or 0) > 0 then
			cards[CuratorOctoFull.Length(cards) + 1] = { npc = card.npc, e = e }
		end
	end
	sort(cards, function(a, b)
		return a.npc < b.npc
	end)
	Varint(out, CuratorOctoFull.Length(cards))
	local prev = 0
	for _, c in ipairs(cards) do
		local e = c.e
		Varint(out, c.npc - prev)
		prev = c.npc
		Varint(out, e.n)
		Varint(out, e.s)
		Varint(out, e.h)
		local t = tonumber(e.t)
		Varint(out, (t and t > 0) and (math.max(0, now - t) + 1) or 0)
	end
	-- the journal, the oldest first (as it was written among equal times)
	local lines = {}
	for i, line in ipairs(type(db.journal) == "table" and db.journal or {}) do
		local j = C and C:JournalLine(line)
		if j then
			j.i = i
			lines[CuratorOctoFull.Length(lines) + 1] = j
		end
	end
	sort(lines, function(a, b)
		if a.t ~= b.t then
			return a.t < b.t
		end
		return a.i < b.i
	end)
	Varint(out, CuratorOctoFull.Length(lines))
	local base
	for _, j in ipairs(lines) do
		local d
		if not base then
			d = math.max(0, now - j.t)
			base = now - d
		else
			d = math.max(0, j.t - base)
			base = base + d
		end
		Varint(out, d)
		Varint(out, j.npc)
		Varint(out, (j.f == "shiny" and 1) or (j.f == "holo" and 2) or 0)
		Varint(out, HOW[j.how or ""] or 0)
		Varint(out, j.booster or 0)
		Str(out, j.who or "")
	end
	return concat(out)
end

-- The code, as it is pasted on the website.
function E:Code(now)
	local body = self:Build(now)
	if not body then
		return nil
	end
	return E.PREFIX .. ToBase64(body .. Adler(body))
end

-------------------------------------------------------------------------------
-- Read (what the website does; here for the checks, and to read a code in the game)
-------------------------------------------------------------------------------
-- The code read: a table (see above), or nil and why: "empty", "prefix", "base64", "checksum",
-- "format", "truncated", "number", "count", "trailing".
function E:Decode(text)
	if type(text) ~= "string" or text == "" then
		return nil, "empty"
	end
	text = string.gsub(text, "%s", "")
	local p = E.PREFIX
	if string.sub(text, 1, CuratorOctoFull.Length(p)) ~= p then
		return nil, "prefix"
	end
	local raw = FromBase64(string.sub(text, CuratorOctoFull.Length(p) + 1))
	if not raw or CuratorOctoFull.Length(raw) < 5 then
		return nil, "base64"
	end
	local body, sum = string.sub(raw, 1, -5), string.sub(raw, -4)
	if Adler(body) ~= sum then
		return nil, "checksum"
	end
	local r = Reader(body)
	local ok, res = pcall(function()
		local d = {}
		d.format = r.u()
		if d.format ~= E.FORMAT then
			error("format", 0)
		end
		d.version = r.str()
		d.flags = r.u()
		d.time = r.u()
		d.id = r.str()
		local ch = {}
		ch.name = r.str()
		ch.realm = r.str()
		ch.guid = r.str()
		ch.region = r.u()
		ch.faction = r.u()
		ch.race = r.u()
		ch.class = r.u()
		ch.level = r.u()
		d.char = ch
		d.xp = r.u()
		d.opened = r.u()
		d.contracts = r.u()
		d.found = r.u()
		d.bossFound = r.u()
		d.ach = {}
		for _ = 1, r.count() do
			local id = r.str()
			d.ach[CuratorOctoFull.Length(d.ach) + 1] = { id = id, t = r.u() }
		end
		d.showcase = {}
		for _ = 1, r.count() do
			d.showcase[CuratorOctoFull.Length(d.showcase) + 1] = r.u()
		end
		d.cards = {}
		local npc = 0
		for _ = 1, r.count() do
			npc = npc + r.u()
			local c = { npc = npc }
			c.n = r.u()
			c.s = r.u()
			c.h = r.u()
			local age = r.u()
			c.t = age > 0 and (d.time - (age - 1)) or nil
			d.cards[CuratorOctoFull.Length(d.cards) + 1] = c
		end
		d.journal = {}
		local base
		for _ = 1, r.count() do
			local dt = r.u()
			base = base and (base + dt) or (d.time - dt)
			local j = { t = base }
			j.npc = r.u()
			local f = r.u()
			j.f = (f == 1 and "shiny") or (f == 2 and "holo") or nil
			j.how = E.HOW_LETTERS[r.u()]
			local booster = r.u()
			j.booster = booster > 0 and booster or nil
			local who = r.str()
			j.who = who ~= "" and who or nil
			d.journal[CuratorOctoFull.Length(d.journal) + 1] = j
		end
		if not r.done() then
			error("trailing", 0)
		end
		return d
	end)
	if not ok then
		return nil, res
	end
	return res
end

-- The collector has its id from the first load (the website and the launcher know it by it).
ns.On("LOADED", function()
	E:Id()
end)

-------------------------------------------------------------------------------
-- (1.7.0) Each time the game saves (a logout, a /reload), the code of the collection goes in a saved
-- variable of its own, CuratorExport: the launcher of Curator reads it there and sends it to the
-- website, the player has nothing to copy. It sits outside CuratorDB and its seal. Never in the way of
-- the save: a code that cannot be made leaves the one of before. The moment of the code goes in the
-- save, under its seal (db.exportAt): the launcher knows by it that the code was made with this very
-- save (a code of before, left there, is not checked against a collection that moved on since).
-------------------------------------------------------------------------------
function E:Save(now)
	local db = ns.db
	if type(db) ~= "table" then
		return false
	end
	local ok, code, at = pcall(function()
		local t = floor(tonumber(now) or CuratorOctoFull.ServerTime())
		return self:Code(t), t
	end)
	if ok and type(code) == "string" then
		CuratorOctoFullExport = code
		db.exportAt = at
		return true
	end
	db.exportAt = nil
	return false
end
