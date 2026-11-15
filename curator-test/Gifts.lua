local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.12.0) The gift codes of the author: boosters to choose (of a zone, a dungeon, a raid) and rubies, for
-- one player, once. The author makes a code on his computer (npm run gift, in the website: signed with the
-- key of the news of the front, FEED_PRIVATE_KEY), the player pastes it in the game (UI/Gift.lua: the
-- boosters of the inventory, or /curator gift). The addon believes a code only signed by that key (Front.lua: F:Check,
-- its public half in Data/FeedKey.lua), for this player (a character, Name-Realm; a Battle.net account, its
-- BattleTag; a collection, its id: Export.lua), before its date, and never twice (db.gifts: the id of each
-- code used, when).
-- The code: CG1.<its text, base64url>.<the signature of the text, base64url>. Its text, a thing a line:
--   gift 1 / id <letters and digits> / to <who> / zone <n> / dungeon <n> / raid <n> / rubies <n> / xp <n> /
--   until <time> / note <a word of the author>
-- (1.12.1) xp: the experience of the collector (the purse of XP of the Hardcup Saison 3, from the website: a code
-- for each album, for its Battle.net account). 1.12.0 does not know it: it refuses such a code, and says to update.
-- (1.13.0) cards <album> <place>:<copies>:<thunderforged>:<titanforged>,...: the cards of an album of a limited
-- edition (the Hardcup Saison 3, its cards brought from WoW Classic with the purse of XP: the same code), each by its
-- place in its album (from 1), its copies and the forged ones among them. Only an album of a limited edition (no
-- other card comes from a code); 1.12.1 does not know the line: it says to update.
-- (1.13.0) displays <album> <n>: displays of 16 boosters of an album that can have them (Displays.lua, D.Eligible: the
-- zones, an event and, since the first test of 1.13.0, the dungeons and the raids), a line for each album; an album
-- this version does not know: it says to update.
-- (a later form of the text says gift 2: this version does not read it, and says to update Curator)
-------------------------------------------------------------------------------
local G = {}
ns.Gifts = G

G.PREFIX = "CG1"
G.KINDS = { "zone", "dungeon", "raid" }
G.MAX_BOOSTERS = 99 -- of each kind, in one code
G.MAX_RUBIES = 100000
G.MAX_XP = 500000 -- (1.12.1) of the collector, in one code
G.MAX_COPIES = 999 -- (1.13.0) of a card, in one code
G.MAX_CODE = 3000 -- the letters of a code (its signature alone: 342)
G.NOTE_MAX = 160

local KIND = {}
for _, k in ipairs(G.KINDS) do
	KIND[k] = true
end
-- what a gift gives, said (the words of the boosters to choose, Locale.lua)
-- (1.14.0, his word: a reward to choose among three, the booster of its kind one of them: Level.lua, LV:AddChoice)
local ONE = { zone = "1 reward to choose (a booster of a zone among the three)", dungeon = "1 reward to choose (a booster of a dungeon among the three)", raid = "1 reward to choose (a booster of a raid among the three)" }
local MANY = { zone = "%d rewards to choose (each with a booster of a zone among the three)", dungeon = "%d rewards to choose (each with a booster of a dungeon among the three)", raid = "%d rewards to choose (each with a booster of a raid among the three)" }

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Secret(v)
	return issecretvalue ~= nil and issecretvalue(v) or false
end

local function Known(v)
	return type(v) == "string" and not Secret(v) and v ~= ""
end

-------------------------------------------------------------------------------
-- Base64url (the code) and hexadecimal (the signature, as Front.lua takes it)
-------------------------------------------------------------------------------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local VAL = {}
for i = 1, 64 do
	VAL[CuratorOctoFull.Byte(B64, i)] = i - 1
end

local function Unbase64(s)
	if type(s) ~= "string" or s == "" or CuratorOctoFull.Mod(CuratorOctoFull.Length(s) , 4) == 1 then
		return nil
	end
	local out, acc, bits = {}, 0, 0
	for i = 1, CuratorOctoFull.Length(s) do
		local v = VAL[CuratorOctoFull.Byte(s, i)]
		if not v then
			return nil
		end
		acc, bits = acc * 64 + v, bits + 6
		if bits >= 8 then
			bits = bits - 8
			local p = 2 ^ bits
			local byte = math.floor(acc / p)
			out[CuratorOctoFull.Length(out) + 1] = string.char(byte)
			acc = acc - byte * p
		end
	end
	return table.concat(out)
end
G.Unbase64 = Unbase64

local function Hex(bytes)
	return (string.gsub(bytes, ".", function(c)
		return string.format(("%02x"), CuratorOctoFull.Byte(c))
	end))
end

-------------------------------------------------------------------------------
-- Who the code is for
-------------------------------------------------------------------------------
-- (its ASCII capitals made small, without its spaces, hyphens, apostrophes and dots: "Argent Dawn" and
-- "ArgentDawn" are one realm)
local function Fold(s)
	return (string.gsub(string.gsub(s, "[%s%-'%.]", ""), "[A-Z]", string.lower))
end

local function Lower(s)
	return (string.gsub(s, "[A-Z]", string.lower))
end

local function BattleTag()
	if BNGetInfo then
		local ok, _, tag = pcall(BNGetInfo)
		if ok and Known(tag) then
			return tag
		end
	end
	return nil
end

-- What the code is for: "char", "bnet" or "cid".
function G.Kind(to)
	if type(to) ~= "string" then
		return nil
	end
	if CuratorOctoFull.Length(to) == 16 and not string.find(to, "[^0-9a-fA-F]") then
		return "cid"
	elseif string.find(to, "#", 1, true) then
		return "bnet"
	elseif string.find(to, "^[^%-]+%-.+$") then
		return "char"
	end
	return nil
end

-- The code is for this player: this character, this Battle.net account, this collection.
function G:ForMe(to)
	local kind = G.Kind(to)
	if kind == "cid" then
		local id = ns.Export and ns.Export.Id and ns.Export:Id()
		return Known(id) and id == Lower(to)
	elseif kind == "bnet" then
		local tag = BattleTag()
		return tag ~= nil and Lower(tag) == Lower(to)
	elseif kind == "char" then
		local name, realm = CuratorOctoFull.Match(to, "^([^%-]+)%-(.+)$")
		local me = UnitName and UnitName("player")
		if not Known(me) then
			return false
		end
		if Fold(name) ~= Fold(me) then
			return false
		end
		-- (its realm; 1.13.1: on OctoWoW, its surname, where the game gives the realm of other characters)
		local _, surname = UnitName("player")
		if UnitFullName then
			local ok, _, second = pcall(UnitFullName, "player")
			if ok and Known(second) then
				surname = second
			end
		end
		for _, r in ipairs({ GetNormalizedRealmName and GetNormalizedRealmName(), GetRealmName and GetRealmName(), surname }) do
			if Known(r) and Fold(r) == Fold(realm) then
				return true
			end
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- A code read
-------------------------------------------------------------------------------
-- (1.13.0) The cards of a line "cards": { series, cards = { { card, n, s, h } }, copies }, or nil and why: "version" (an
-- album this version does not know: a later one), "damaged" (not an album of a limited edition, a place it does not
-- have, a card twice, more forged copies than copies).
local function ReadCards(v)
	local key, list = CuratorOctoFull.Match(v, "^(%w+) ([%d:,]+)$")
	if not key then
		return nil, "damaged"
	end
	local s = ns.SeriesByKey and ns.SeriesByKey(key)
	if not s then
		return nil, "version"
	end
	if not s.limited then
		return nil, "damaged"
	end
	local out, seen = { series = s, cards = {}, copies = 0 }, {}
	for part in CuratorOctoFull.Gmatch((list .. ","), "([^,]*),") do
		local num, n, sh, h = CuratorOctoFull.Match(part, "^(%d+):(%d+):(%d+):(%d+)$")
		num, n, sh, h = tonumber(num), tonumber(n), tonumber(sh), tonumber(h)
		if not num or not s.list[num] or seen[num] or n < 1 or n > G.MAX_COPIES or sh + h > n then
			return nil, "damaged"
		end
		seen[num] = true
		out.cards[CuratorOctoFull.Length(out.cards) + 1] = { card = s.list[num], n = n, s = sh, h = h }
		out.copies = out.copies + n
	end
	if CuratorOctoFull.Length(out.cards) == 0 then
		return nil, "damaged"
	end
	return out
end

-- The gift of a code, or nil and why: "damaged" (cut, changed, not signed by the author), "version" (a later
-- form: Curator to update), "nokey" (this build knows no key). { id, to, give = { zone = n, ... }, ends,
-- note }.
function G:Read(code)
	if type(code) ~= "string" then
		return nil, "damaged"
	end
	code = string.gsub(code, "%s+", "")
	if code == "" or CuratorOctoFull.Length(code) > self.MAX_CODE then
		return nil, "damaged"
	end
	local head, p, s = CuratorOctoFull.Match(code, "^(%w+)%.([%w%-_]+)%.([%w%-_]+)$")
	if not head then
		return nil, "damaged"
	end
	if head ~= self.PREFIX then
		return nil, CuratorOctoFull.Match(head, "^CG%d+$") and "version" or "damaged"
	end
	local text, sig = Unbase64(p), Unbase64(s)
	if not text or not sig then
		return nil, "damaged"
	end
	local key = self.key or ns.FEED_KEY
	if type(key) ~= "table" or not (ns.Front and ns.Front.Check) then
		return nil, "nokey"
	end
	if not ns.Front:Check(text, Hex(sig), key) then
		return nil, "damaged"
	end
	local g = { give = {} }
	local first = true
	for line in CuratorOctoFull.Gmatch((text .. "\n"), "([^\n]*)\n") do
		if first then
			if line ~= "gift 1" then
				return nil, CuratorOctoFull.Match(line, "^gift %d+$") and "version" or "damaged"
			end
			first = false
		elseif line ~= "" then
			local k, v = CuratorOctoFull.Match(line, "^(%l+) (.+)$")
			if not k then
				return nil, "damaged"
			elseif k == "id" then
				if not string.find(v, "^%w+$") or CuratorOctoFull.Length(v) < 6 or CuratorOctoFull.Length(v) > 24 then
					return nil, "damaged"
				end
				g.id = v
			elseif k == "to" then
				if not G.Kind(v) or CuratorOctoFull.Length(v) > 80 or string.find(v, "[%c|]") then
					return nil, "damaged"
				end
				g.to = v
			elseif k == "until" then
				g.ends = tonumber(v)
				if not g.ends then
					return nil, "damaged"
				end
			elseif k == "note" then
				-- (never an escape of the game in it)
				g.note = string.sub(string.gsub(v, "[%c|]", ""), 1, self.NOTE_MAX)
			elseif k == "cards" then
				local c, why = ReadCards(v)
				if not c then
					return nil, why
				end
				g.give.cards = g.give.cards or {}
				if g.give.cards[c.series.key] then
					return nil, "damaged"
				end
				g.give.cards[c.series.key] = c
			elseif k == "displays" then
				-- (1.13.0) displays of 16 boosters of an album that can have them (Displays.lua, D.Eligible)
				local key, n = CuratorOctoFull.Match(v, "^(%w+) (%d+)$")
				n = tonumber(n)
				if not key or not n or n < 1 then
					return nil, "damaged"
				end
				local s = ns.SeriesByKey and ns.SeriesByKey(key)
				if not s then
					return nil, "version"
				end
				local D = ns.Displays
				if not (D and D.Eligible(s)) then
					return nil, "damaged"
				end
				g.give.displays = g.give.displays or {}
				if g.give.displays[s.key] then
					return nil, "damaged"
				end
				g.give.displays[s.key] = math.min(n, D.MAX_GIFT)
			elseif KIND[k] or k == "rubies" or k == "xp" then
				local n = tonumber(v)
				if not n or n ~= math.floor(n) or n < 1 then
					return nil, "damaged"
				end
				g.give[k] = math.min(n, (k == "rubies" and self.MAX_RUBIES) or (k == "xp" and self.MAX_XP) or self.MAX_BOOSTERS)
			else
				-- (a thing this version does not know: nothing given rather than half of it)
				return nil, "version"
			end
		end
	end
	if first or not g.id or not g.to or next(g.give) == nil then
		return nil, "damaged"
	end
	return g
end

-- The letters of a signature in a code (base64url: 342 for a key of 2048 bits), nil: no key.
function G:SigLetters()
	local key = self.key or ns.FEED_KEY
	if type(key) ~= "table" or type(key.n) ~= "string" then
		return nil
	end
	return math.ceil((CuratorOctoFull.Length(key.n) / 2) * 4 / 3)
end

-- (1.13.0) The cards of a gift, album by album, in the order of the albums.
function G:Cards(g)
	local out = {}
	if type(g.give.cards) == "table" then
		for _, s in ipairs(ns.Series or {}) do
			if g.give.cards[s.key] then
				out[CuratorOctoFull.Length(out) + 1] = g.give.cards[s.key]
			end
		end
	end
	return out
end

-- (1.13.0) The displays of a gift: { { series, n } }, in the order of the albums.
function G:Displays(g)
	local out = {}
	if type(g.give.displays) == "table" then
		for _, s in ipairs(ns.Series or {}) do
			local n = g.give.displays[s.key]
			if n then
				out[CuratorOctoFull.Length(out) + 1] = { series = s, n = n }
			end
		end
	end
	return out
end

-- The lines of what a gift gives, in the language of the player.
function G:Lines(g)
	local out = {}
	-- (1.13.0) its displays of 16 boosters, album by album
	for _, x in ipairs(self:Displays(g)) do
		local name = ns.Collection and ns.Collection:SeriesName(x.series) or x.series.key
		out[CuratorOctoFull.Length(out) + 1] = x.n == 1 and string.format(L["%s: 1 display of 16 boosters"], name) or string.format(L["%s: %d displays of 16 boosters"], name, x.n)
	end
	-- (1.13.0) the cards of an album of a limited edition first: how many cards, how many copies
	for _, c in ipairs(self:Cards(g)) do
		local name = ns.Collection and ns.Collection:SeriesName(c.series) or c.series.key
		local line = CuratorOctoFull.Length(c.cards) == 1 and string.format(L["%s: 1 card"], name) or string.format(L["%s: %d cards"], name, CuratorOctoFull.Length(c.cards))
		if c.copies > CuratorOctoFull.Length(c.cards) then
			line = line .. " " .. string.format(L["(%d copies)"], c.copies)
		end
		out[CuratorOctoFull.Length(out) + 1] = line
	end
	for _, kind in ipairs(self.KINDS) do
		local n = g.give[kind]
		if n then
			out[CuratorOctoFull.Length(out) + 1] = n == 1 and L[ONE[kind]] or string.format(L[MANY[kind]], n)
		end
	end
	if g.give.rubies then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["+%s rubies"], ns.Num and ns.Num(g.give.rubies) or tostring(g.give.rubies))
	end
	-- (1.12.1) the experience of the collector
	if g.give.xp then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["+%s XP"], ns.Num and ns.Num(g.give.xp) or tostring(g.give.xp))
	end
	return out
end

-- Whether a code can be redeemed here, and why not: "closed" (Curator closed: a beta past its day, an
-- update missed, a collection suspended or banned), "used", "expired", "other" (for another player), or
-- one of G:Read. The gift read, whatever the answer once it is read.
function G:Check(code)
	local db = ns.db
	if not db or (ns.Beta and ns.Beta:Over()) then
		return false, "closed"
	end
	local g, why = self:Read(code)
	if not g then
		return false, why
	end
	if type(db.gifts) == "table" and db.gifts[g.id] then
		return false, "used", g
	end
	if g.ends and Now() > g.ends then
		return false, "expired", g
	end
	if not self:ForMe(g.to) then
		return false, "other", g
	end
	return true, nil, g
end

-- The code redeemed: its boosters to choose and its rubies given, its id kept (never twice). True and the
-- gift, or false, why and the gift when it was read (G:Check).
function G:Redeem(code)
	local ok, why, g = self:Check(code)
	if not ok then
		return false, why, g
	end
	-- (1.14.0: the cards changed by another addon this session: the code stays to use; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard", g
	end
	local db = ns.db
	if type(db.gifts) ~= "table" then
		db.gifts = {}
	end
	db.gifts[g.id] = Now()
	for _, kind in ipairs(self.KINDS) do
		local n = g.give[kind]
		if n and ns.Level then
			ns.Level:AddChoice(kind, n)
		end
	end
	if g.give.rubies and ns.Rubies then
		ns.Rubies:Gain(g.give.rubies, "gift")
	end
	-- (1.12.1) the experience of the collector: its levels reached, their rewards on the track, to claim
	if g.give.xp and ns.Level then
		ns.Level:Gain(g.give.xp, "gift")
	end
	-- (1.13.0) its displays of 16 boosters, to open (Displays.lua)
	if ns.Displays then
		for _, x in ipairs(self:Displays(g)) do
			ns.Displays:Add(x.series, x.n, "gift")
		end
	end
	-- (1.13.0) the cards of a limited edition: each copy into its album, in its finish, new there; a line of the journal
	-- for each card and finish worth one (how "c": a gift code; who: its id). Nothing else: no experience, no quest, no
	-- card found counted (the album is the gift; its experience came with the purse).
	local C = ns.Collection
	local cards = self:Cards(g)
	-- (1.13.0: each copy tells it came with this code: Copies.lua)
	if ns.Copies and CuratorOctoFull.Length(cards) > 0 then
		ns.Copies:SetContext({ w = "c", p = tostring(g.id) })
	end
	for _, c in ipairs(cards) do
		for _, x in ipairs(c.cards) do
			local plain = x.n - x.s - x.h
			for _ = 1, x.s do
				C:Add(x.card, "shiny")
			end
			for _ = 1, x.h do
				C:Add(x.card, "holo")
			end
			for _ = 1, plain do
				C:Add(x.card)
			end
			if x.s > 0 then
				C:Log(x.card, "shiny", "c", g.id)
			end
			if x.h > 0 then
				C:Log(x.card, "holo", "c", g.id)
			end
			if plain > 0 then
				C:Log(x.card, nil, "c", g.id)
			end
		end
	end
	if ns.Copies then
		ns.Copies:SetContext(nil)
	end
	if CuratorOctoFull.Length(cards) > 0 then
		ns.Fire("CHANGED")
	end
	local st = ns.Stats and ns.Stats()
	if st then
		st.gifts = (tonumber(st.gifts) or 0) + 1
		-- (1.13.0: the cards of the Hardcup Saison 3, its players: their achievement and their title, Achievements.lua)
		for _, c in ipairs(cards) do
			if c.series and c.series.limited == "hardcup" then
				st.hardcup = (tonumber(st.hardcup) or 0) + 1
			end
		end
	end
	ns.Fire("GIFT_REDEEMED", g)
	return true, nil, g
end

-- The codes used: how many.
function G:Used()
	local n = 0
	local db = ns.db
	if db and type(db.gifts) == "table" then
		for _ in pairs(db.gifts) do
			n = n + 1
		end
	end
	return n
end
