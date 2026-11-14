local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0) The Bourse Gentepression, the market of Curator: one market for the Horde and the Alliance of every realm
-- and region, held by the website of Curator, in rubies or in barter. A dealer in deposit: a thing put on sale leaves
-- the collection at once and waits in the save (in deposit, frozen: no trade, contract nor reseller takes it); the app
-- of Curator sends the save to the website after each save of the game, the website judges (one listing at a time,
-- lib/market/judge.ts) and gives its answers back in the news of the app (Feed.lua, every quarter of an hour), read here
-- at the next load of the game (a /reload, a login): its messages, numbered for this collection, applied once each, in
-- their order (an old Feed.lua kept on the disk delivers nothing twice).
-- * What goes: the copies of the cards of the albums (the Hallow's End and the Hardcup ones too), the corrupted copies
--   and the reliquaries (only here: the trades, the contracts and the reseller keep the rule of 1.12.0), the boosters of
--   an album, the displays (in their case too), the cases closed, the cards of the cases (a priceless one in the open).
--   Each thing with its story (MK.Pack). Never the golden boosters, the boosters to choose (until put in an album), the
--   keys of the cases (the reseller takes them back), the cards of the PvP, a copy at an enchanter, one staked on a
--   duel, one in quarantine. (1.14.0, a player's word: the copy signed by its innkeeper goes too.)
-- * A listing: a price in rubies, or a barter of 1 to 3 things precise (a card with its finish, from a grade; a booster
--   of an album; a display; a case of an edition), with or without rubies more; 1, 3, 5 or 7 days; a fee (a part of the
--   price by its days), given back with the price when it sells, lost when it comes back unsold. The commission of the
--   Cartel (10 %) goes out of the game. A purchase: the rubies (or the things of the barter) leave at once, on the way.
--   A buy order: rubies in deposit for a thing precise, at a price; the first who has it sells it with a click.
-- * What is bought waits MK.QUARANTINE days: no resale, no trade, no contract, no achievement before (the boosters, the
--   displays and the cases open at once: the website judged already).
-- * The rubies of a sale were moved, not made: no talent, no guard of the week, their own counter (no achievement of
--   the rubies earned or spent counts them).
-- * Who: with the pass of the collection (Pass.lua), as for the trades; at an auctioneer (UI/Market.lua); never a
--   collection of test, edited, of the author (his build gives cards: his test mode is on a copy).
-- What is kept, under the seal of the save (the website reads it there: lib/market/save.ts):
--   db.market = { cid = the collection it is of (a collection emptied gets a new id: its market goes with the old one),
--     n = the last number given, seq = the last message applied, t = when the news read last were made,
--     ls = { [n] = { it = pack, p = price (nil: barter only), tr = { asks }, cp = rubies more of a barter, d = days,
--       fee, t, ac = its line, rec = what came out (to put it back as it was) } },
--     bu = { [n] = { l = the listing aimed at, p = rubies on the way, gv = { packs given }, gr = { what came out }, t } },
--     od = { [n] = { k = spec, p = rubies, d, t } }, fl = { [n] = { o = the order, it = pack, rec, t } },
--     wd = { [n] = true } (withdrawals asked), pc = { [n] = price } (prices asked), fv = { [spec] = when } (stars),
--     qt = { [copy] = { k = card key, u = until } }, qp = { [spec] = { { u, n } } } (what waits its quarantine),
--     h = { { k = what, it = pack, p = rubies, t, w = who } } (the last ones), st = { counters },
--     mb = { { it = pack, w = who, d = days, t } } (what came and this version cannot take yet: tried again at each load) }
-- The texts the market carries are ASCII (a name: its bytes, ~XX each but the letters and the digits).
-------------------------------------------------------------------------------
local MK = { news = nil }
ns.Market = MK

MK.QUARANTINE = 7      -- days (the website may say otherwise)
MK.HISTORY = 60        -- the events kept for the pages Mes ventes and Mes achats
MK.TEXT_MAX = 120      -- a name escaped, at most (lib/market/items.ts: TEXT_MAX)
MK.PACK_MAX = 400      -- a pack, at most
MK.NEWS_MAX = 16384    -- the news of the market, at most (the app writes no longer text)
MK.ASKS = 3            -- the things a barter asks, at most
MK.ACCROCHES = 9       -- its lines (UI/Market.lua: their words)

local floor, max, min = math.floor, math.max, math.min
local byte, char, format = string.byte, string.char, string.format

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Int(v)
	return max(0, floor(tonumber(v) or 0))
end

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-------------------------------------------------------------------------------
-- Numbers and texts, as the website writes them
-------------------------------------------------------------------------------
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"

local function To36(n)
	n = Int(n)
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = floor(n / 36)
	until n == 0
	return s
end
MK.To36 = To36

-- (its one way of writing: no 0 first but the 0 itself, eight digits at most)
local function From36(s)
	if type(s) ~= "string" or not (s == "0" or CuratorOctoFull.Match(s, "^[1-9a-z][0-9a-z]*$")) or CuratorOctoFull.Length(s) > 8 then
		return nil
	end
	return tonumber(s, 36)
end
MK.From36 = From36

-- A whole number written in decimal its one way, between lo and hi (nil: not one).
local function Dec(s, lo, hi)
	if type(s) ~= "string" or not (s == "0" or CuratorOctoFull.Match(s, "^[1-9]%d*$")) or CuratorOctoFull.Length(s) > 10 then
		return nil
	end
	local v = tonumber(s)
	if v < lo or v > hi then
		return nil
	end
	return v
end
MK.Dec = Dec

local function Plain(c)
	return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
end

-- A text (its bytes) as the market carries it: the letters and the digits as they are, every other byte ~XX; cut
-- before the letter of UTF-8 that would pass MK.TEXT_MAX (its first byte and those that follow it, 0x80 to 0xBF).
function MK.Esc(s)
	s = type(s) == "string" and s or ""
	local out, n, i, len = {}, 0, 1, CuratorOctoFull.Length(s)
	while i <= len do
		local j = i + 1
		while j <= len do
			local c = byte(s, j)
			if c < 128 or c >= 192 then
				break
			end
			j = j + 1
		end
		local piece = {}
		for k = i, j - 1 do
			local c = byte(s, k)
			piece[CuratorOctoFull.Length(piece) + 1] = Plain(c) and char(c) or format("~%02X", c)
		end
		local p = table.concat(piece)
		if n + CuratorOctoFull.Length(p) > MK.TEXT_MAX then
			break
		end
		out[CuratorOctoFull.Length(out) + 1] = p
		n = n + CuratorOctoFull.Length(p)
		i = j
	end
	return table.concat(out)
end

-- The bytes of a text carried (nil: not written its one way).
function MK.Unesc(s)
	if type(s) ~= "string" or CuratorOctoFull.Length(s) > MK.TEXT_MAX or string.find(s, "[^%w~]") then
		return nil
	end
	local bad = false
	local t = string.gsub(s, "~(..)", function(h)
		if not CuratorOctoFull.Match(h, "^[0-9A-F][0-9A-F]$") then
			bad = true
			return ""
		end
		return char(tonumber(h, 16))
	end)
	if bad or string.find(t, "~", 1, true) or MK.Esc(t) ~= s then
		return nil
	end
	return t
end

-- A name carried ("-": none), as the player reads it.
function MK.Name(s)
	if s == nil or s == "-" or s == "" then
		return "?"
	end
	return MK.Unesc(s) or "?"
end

-------------------------------------------------------------------------------
-- The things and their packs (the same on the website: lib/market/items.ts)
--   c.<npc>.<f>.<g>.<m>.<ce>.<sl>.<hg>.<r>.<ot>.<ow>.<och>.<cor>.<seal>   a copy of a card of an album
--   b.<album>   d.<album>.<cased>   x.<edition>                          a booster, a display, a case
--   w.<edition>.<rank>.<what>.<f>.<grade>.<ap>.<ot>.<oh>                 a card of a case
-- f: n normal, s thunderforged, h titanforged, c corrupted (a case: n, t, T); g, hg: grades x100 (0: none); sl: 1 in its
-- case, 0 opened (empty: not appraised); r: "<t>-<d>-<a>" joined by "+"; ot, ow, och: where it came from first; cor: its
-- corruption; seal: "<rank>-<marks>-<pact>-<t>-<master>"; what: "e<entry>" or "i<item>-<line>-<class>-<side>"; ap:
-- "<marks>-<cert>-<at>"; base 36 for the times, the certificates, the pacts and the grades x100.
-- (1.14.0, his idea) A titanforged copy, its pattern after the rest: c.<npc>.h. ... .<seal>.<pattern> (1 to 19683,
-- Patterns.lua; no other copy has one). A copy with a pattern has a story of its own (never alike another: MK.Ident).
-- A titanforged card of a case too: w. ... .<oh>.<pattern>.
-------------------------------------------------------------------------------
local SERIES = "^[a-z0-9_]+$"
-- (an album, an edition: 40 characters at most)
local function Key(s)
	return type(s) == "string" and CuratorOctoFull.Length(s) <= 40 and CuratorOctoFull.Match(s, SERIES) ~= nil
end

local function Split(s, sep)
	local out = {}
	local from = 1
	while true do
		local i = string.find(s, sep, from, true)
		if not i then
			out[CuratorOctoFull.Length(out) + 1] = string.sub(s, from)
			return out
		end
		out[CuratorOctoFull.Length(out) + 1] = string.sub(s, from, i - 1)
		from = i + 1
	end
end
MK.Split = Split

local function PackCard(it)
	local r = {}
	for _, x in ipairs(it.r or {}) do
		r[CuratorOctoFull.Length(r) + 1] = To36(x[1]) .. "-" .. tostring(x[2]) .. "-" .. To36(x[3])
	end
	local seal = ""
	if it.seal then
		local s = it.seal
		seal = tostring(s.rank) .. "-" .. s.marks .. "-" .. To36(s.pact) .. "-" .. To36(s.t) .. "-" .. MK.Esc(s.master)
	end
	local parts = {
		"c", tostring(it.npc), it.f, To36(it.g), it.m or "", To36(it.ce), (it.sl == nil and "") or (it.sl and "1" or "0"),
		To36(it.hg), table.concat(r, "+"), To36(it.ot), it.ow or "", MK.Esc(it.och), (it.cor or 0) > 0 and tostring(it.cor) or "", seal,
	}
	-- (1.14.0: a titanforged copy, its pattern)
	if it.pt then
		parts[15] = tostring(it.pt)
	end
	-- (1 November, his word: the very same card at its buyer's: its wear, a sixteenth part, Wear.lua)
	if it.wear or it.tc then
		parts[15] = parts[15] or ""
		parts[16] = it.wear or ""
	end
	-- (1 November, his idea: a titanforged copy certified by a master of the mages, its certificate, a seventeenth part,
	-- Mages.lua; its wear then maybe empty)
	if it.tc then
		parts[17] = it.tc
	end
	return table.concat(parts, ".")
end

local function PackCrate(it)
	local what
	if it.entry then
		what = "e" .. it.entry
	else
		local w = it.weapon
		what = "i" .. tostring(w.item) .. "-" .. tostring(w.line) .. "-" .. ((w.cls ~= nil and w.cls ~= "") and w.cls or "0") .. "-" .. ((w.side ~= nil and w.side ~= "") and w.side or "0")
	end
	local ap = it.ap and (it.ap.m .. "-" .. To36(it.ap.ce) .. "-" .. To36(it.ap.at)) or ""
	local parts = { "w", it.edition, tostring(it.rank), what, it.f, tostring(it.grade), ap, To36(it.ot), it.oh or "" }
	-- (1.14.0: titanforged, its pattern)
	if it.pt then
		parts[10] = tostring(it.pt)
	end
	-- (1 November: restored at an enchanter, what he did to it, an eleventh part, Wear.lua)
	if it.wear or it.tc then
		parts[10] = parts[10] or ""
		parts[11] = it.wear or ""
	end
	-- (1 November, his idea: titanforged, certified by a master of the mages, a twelfth part, Mages.lua)
	if it.tc then
		parts[12] = it.tc
	end
	return table.concat(parts, ".")
end

-- The pack of a thing.
function MK.Pack(it)
	if type(it) ~= "table" then
		return nil
	end
	if it.k == "c" then
		return PackCard(it)
	elseif it.k == "b" then
		return "b." .. it.series
	elseif it.k == "d" then
		return "d." .. it.series .. "." .. (it.cased and "1" or "0")
	elseif it.k == "x" then
		return "x." .. it.edition
	elseif it.k == "w" then
		return PackCrate(it)
	end
	return nil
end

local function Grade100(s)
	local v = From36(s)
	if v == nil or not (v == 0 or (v >= 100 and v <= 1000)) then
		return nil
	end
	return v
end

local function ReadCard(f)
	if CuratorOctoFull.Length(f) ~= 14 and CuratorOctoFull.Length(f) ~= 15 and CuratorOctoFull.Length(f) ~= 16 and CuratorOctoFull.Length(f) ~= 17 then
		return nil
	end
	-- (1 November: a titanforged copy certified by a master of the mages, its certificate, a seventeenth part, Mages.lua:
	-- its pattern the fifteenth, its wear the sixteenth or nothing)
	local tc
	if CuratorOctoFull.Length(f) == 17 then
		local MG = ns.Mages
		if not (MG and MG.Unpack(f[17]) and f[15] ~= "") then
			return nil
		end
		tc = f[17]
		f[17] = nil
		if f[16] == "" then
			f[16] = nil
		end
	end
	-- (1 November: its wear, a sixteenth part, Wear.lua; its pattern then the fifteenth, or nothing)
	local wear
	if CuratorOctoFull.Length(f) == 16 then
		local W = ns.Wear
		if not (W and W.Unpack and W.Unpack(f[16])) then
			return nil
		end
		wear = f[16]
		if f[15] == "" then
			f[15] = nil
		end
		f[16] = nil
	end
	-- (1.14.0: a titanforged copy, its pattern, Patterns.lua)
	local pt
	if CuratorOctoFull.Length(f) == 15 then
		local P = ns.Patterns
		pt = CuratorOctoFull.Match(f[15], "^[1-9]%d?%d?%d?%d?$") and tonumber(f[15])
		if not (pt and pt <= ((P and P.MAX) or 19683) and f[3] == "h") then
			return nil
		end
	end
	local npc = Dec(f[2], 1, 99999999)
	local fin = f[3]
	local g, ce, hg, ot = Grade100(f[4]), From36(f[6]), Grade100(f[8]), From36(f[10])
	if not (npc and g and ce and hg and ot) or not (fin == "n" or fin == "s" or fin == "h" or fin == "c") then
		return nil
	end
	if f[5] ~= "" and not CuratorOctoFull.Match(f[5], "^[1-9A][1-9A][1-9A][1-9A]$") then
		return nil
	end
	if not (f[7] == "" or f[7] == "0" or f[7] == "1") then
		return nil
	end
	if (g > 0) ~= (f[7] ~= "") or (g == 0 and (f[5] ~= "" or ce ~= 0)) then
		return nil
	end
	local r = {}
	if f[9] ~= "" then
		local parts = Split(f[9], "+")
		if CuratorOctoFull.Length(parts) > 9 then
			return nil
		end
		for _, p in ipairs(parts) do
			local t, d, a = CuratorOctoFull.Match(p, "^([0-9a-z]+)%-([1-4])%-([0-9a-z]+)$")
			t, a = From36(t), From36(a)
			if not (t and a) or a > 1000 then
				return nil
			end
			r[CuratorOctoFull.Length(r) + 1] = { t, tonumber(d), a }
		end
	end
	if f[11] ~= "" and not CuratorOctoFull.Match(f[11], "^[a-z]$") then
		return nil
	end
	local och = MK.Unesc(f[12])
	if not och then
		return nil
	end
	local cor = 0
	if f[13] ~= "" then
		cor = Dec(f[13], 1, 100)
		if not cor then
			return nil
		end
	end
	if (fin == "c") ~= (cor > 0) or (fin == "c" and (g > 0 or hg > 0 or CuratorOctoFull.Length(r) > 0)) then
		return nil
	end
	local seal
	if f[14] ~= "" then
		local rank, marks, pact, t, master = CuratorOctoFull.Match(f[14], "^(%d+)%-([1-9A][1-9A][1-9A][1-9A])%-([0-9a-z]+)%-([0-9a-z]+)%-(.*)$")
		rank = Dec(rank, 1, 10)
		pact, t = From36(pact), From36(t)
		master = master and MK.Unesc(master)
		if not (rank and pact and t and master) or fin ~= "c" then
			return nil
		end
		seal = { rank = rank, marks = marks, pact = pact, t = t, master = master }
	end
	local sl
	if f[7] ~= "" then
		sl = f[7] == "1"
	end
	return { k = "c", npc = npc, f = fin, g = g, m = f[5], ce = ce, sl = sl, hg = hg, r = r, ot = ot, ow = f[11], och = och, cor = cor, seal = seal,
		pt = pt, wear = wear, tc = tc }
end

-- the letters of the entries of each rank of a case (the last one: a weapon). (1.14.0, the Paladin collection redone: a
-- figure in the covert rank too, as an armour was.)
local LETTER = { { s = true }, { n = true }, { n = true }, { a = true, n = true } }

local function ReadCrate(f)
	if CuratorOctoFull.Length(f) ~= 9 and CuratorOctoFull.Length(f) ~= 10 and CuratorOctoFull.Length(f) ~= 11 and CuratorOctoFull.Length(f) ~= 12 then
		return nil
	end
	-- (1 November: titanforged, certified by a master of the mages, a twelfth part, Mages.lua: its pattern the tenth, what
	-- the enchanter did to it the eleventh or nothing)
	local tc
	if CuratorOctoFull.Length(f) == 12 then
		local MG = ns.Mages
		if not (MG and MG.Unpack(f[12]) and f[10] ~= "") then
			return nil
		end
		tc = f[12]
		f[12] = nil
		if f[11] == "" then
			f[11] = nil
		end
	end
	-- (1 November: restored, what the enchanter did to it, an eleventh part, Wear.lua; its pattern then the tenth, or
	-- nothing)
	local wear
	if CuratorOctoFull.Length(f) == 11 then
		local W = ns.Wear
		if not (W and W.Unpack and W.Unpack(f[11], true)) then
			return nil
		end
		wear = f[11]
		if f[10] == "" then
			f[10] = nil
		end
		f[11] = nil
	end
	-- (1.14.0: titanforged, its pattern)
	local pt
	if CuratorOctoFull.Length(f) == 10 then
		local P = ns.Patterns
		pt = CuratorOctoFull.Match(f[10], "^[1-9]%d?%d?%d?%d?$") and tonumber(f[10])
		if not (pt and pt <= ((P and P.MAX) or 19683) and f[5] == "T") then
			return nil
		end
	end
	local edition, rank, grade, ot = f[2], Dec(f[3], 1, 5), Dec(f[6], 1, 10), From36(f[8])
	if not (Key(edition) and rank and grade and ot) then
		return nil
	end
	if not (f[5] == "n" or f[5] == "t" or f[5] == "T") or not (f[9] == "" or f[9] == "k") then
		return nil
	end
	local it = { k = "w", edition = edition, rank = rank, f = f[5], grade = grade, ot = ot, oh = f[9], pt = pt, wear = wear, tc = tc }
	local el, eid = CuratorOctoFull.Match(f[4], "^e([sna])([1-9]%d*)$")
	local wi, wl, wc, ws = CuratorOctoFull.Match(f[4], "^i([1-9]%d*)%-([1-9]%d?)%-([A-Z0]+)%-(%w+)$")
	if el and CuratorOctoFull.Length(eid) <= 7 then
		if rank == 5 or not LETTER[rank][el] then
			return nil
		end
		it.entry = el .. eid
	elseif wi and CuratorOctoFull.Length(wi) <= 7 then
		if rank ~= 5 or not (ws == "Alliance" or ws == "Horde" or ws == "0") or (wc ~= "0" and not (CuratorOctoFull.Match(wc, "^[A-Z]+$") and CuratorOctoFull.Length(wc) >= 2 and CuratorOctoFull.Length(wc) <= 12)) then
			return nil
		end
		it.weapon = { item = tonumber(wi), line = tonumber(wl), cls = wc ~= "0" and wc or "", side = ws ~= "0" and ws or "" }
	else
		return nil
	end
	if f[7] ~= "" then
		local m, ce, at = CuratorOctoFull.Match(f[7], "^([1-9A][1-9A][1-9A][1-9A])%-([0-9a-z]+)%-([0-9a-z]+)$")
		ce, at = From36(ce), From36(at)
		if not (m and ce and at) then
			return nil
		end
		it.ap = { m = m, ce = ce, at = at }
	end
	return it
end

-- A thing from its pack (nil: not one, or not written its one way).
function MK.Unpack(s)
	if type(s) ~= "string" or s == "" or CuratorOctoFull.Length(s) > MK.PACK_MAX or string.find(s, "[^%w%.%-%+~]") then
		return nil
	end
	local f = Split(s, ".")
	local it
	if f[1] == "c" then
		it = ReadCard(f)
	elseif f[1] == "b" and CuratorOctoFull.Length(f) == 2 and Key(f[2]) then
		it = { k = "b", series = f[2] }
	elseif f[1] == "d" and CuratorOctoFull.Length(f) == 3 and Key(f[2]) and (f[3] == "0" or f[3] == "1") then
		it = { k = "d", series = f[2], cased = f[3] == "1" }
	elseif f[1] == "x" and CuratorOctoFull.Length(f) == 2 and Key(f[2]) then
		it = { k = "x", edition = f[2] }
	elseif f[1] == "w" then
		it = ReadCrate(f)
	end
	if it and MK.Pack(it) == s then
		return it
	end
	return nil
end

-- The step of the condition of a grade (1 Mint ... 5 Poor: Cases.lua, CS.CONDITION).
local function Step(g)
	g = tonumber(g) or 1
	if g >= 9 then
		return 1
	elseif g >= 7 then
		return 2
	elseif g >= 5 then
		return 3
	elseif g >= 3 then
		return 4
	end
	return 5
end
MK.Step = Step

local function CrateWhat(it)
	return it.entry and ("e" .. it.entry) or ("i" .. tostring(it.weapon.item))
end

-- A copy with nothing of its own: never appraised, never restored, not corrupted (1.14.0: no pattern, Patterns.lua).
function MK.PlainCopy(it)
	return it.k == "c" and it.g == 0 and it.hg == 0 and CuratorOctoFull.Length((it.r or {})) == 0 and it.f ~= "c" and it.pt == nil
end

-- The spec of a thing alike others (nil: a thing of a story of its own).
function MK.Ident(it)
	if it.k == "c" then
		return MK.PlainCopy(it) and ("c." .. it.npc .. "." .. it.f) or nil
	elseif it.k == "w" then
		return (not it.ap and not it.pt) and ("w." .. it.edition .. "." .. CrateWhat(it) .. "." .. it.f .. "." .. Step(it.grade)) or nil
	end
	return MK.Pack(it)
end

-- What a thing is, whatever its story (its prices of the month).
function MK.Kind(it)
	if it.k == "c" then
		return "c." .. it.npc .. "." .. it.f
	elseif it.k == "w" then
		return "w." .. it.edition .. "." .. CrateWhat(it) .. "." .. it.f
	end
	return MK.Pack(it)
end

function MK.Spec(it)
	return MK.Ident(it) or MK.Kind(it)
end

-- What a barter or an order asks: c.<npc>.<f>[.<grade>], b.<album>, d.<album>.<cased>, x.<edition> (nil: not one).
function MK.ReadAsk(s)
	if type(s) ~= "string" or CuratorOctoFull.Length(s) > 60 then
		return nil
	end
	local f = Split(s, ".")
	if f[1] == "c" and (CuratorOctoFull.Length(f) == 3 or CuratorOctoFull.Length(f) == 4) then
		local npc = Dec(f[2], 1, 99999999)
		local mg = CuratorOctoFull.Length(f) == 4 and Dec(f[4], 1, 10) or 0
		if not (npc and mg) or not (f[3] == "n" or f[3] == "s" or f[3] == "h" or f[3] == "c") or (f[3] == "c" and mg > 0) then
			return nil
		end
		return { k = "c", npc = npc, f = f[3], min = mg }
	elseif f[1] == "b" and CuratorOctoFull.Length(f) == 2 and Key(f[2]) then
		return { k = "b", series = f[2] }
	elseif f[1] == "d" and CuratorOctoFull.Length(f) == 3 and Key(f[2]) and (f[3] == "0" or f[3] == "1") then
		return { k = "d", series = f[2], cased = f[3] == "1" }
	elseif f[1] == "x" and CuratorOctoFull.Length(f) == 2 and Key(f[2]) then
		return { k = "x", edition = f[2] }
	end
	return nil
end

function MK.AskText(a)
	if a.k == "c" then
		return "c." .. a.npc .. "." .. a.f .. ((a.min or 0) > 0 and ("." .. a.min) or "")
	elseif a.k == "b" then
		return "b." .. a.series
	elseif a.k == "d" then
		return "d." .. a.series .. "." .. (a.cased and "1" or "0")
	end
	return "x." .. a.edition
end

-- Whether a thing answers what is asked (from a grade: a copy appraised so, its grade shown).
function MK.Answers(it, a)
	if not (it and a) then
		return false
	end
	if a.k == "c" then
		return it.k == "c" and it.npc == a.npc and it.f == a.f and ((a.min or 0) == 0 or (it.sl == true and it.g >= a.min * 100))
	elseif a.k == "b" then
		return it.k == "b" and it.series == a.series
	elseif a.k == "d" then
		return it.k == "d" and it.series == a.series and it.cased == a.cased
	end
	return it.k == "x" and it.edition == a.edition
end

-------------------------------------------------------------------------------
-- The rules (as the news of the website say them; before any news: those of the document of the Bourse)
-------------------------------------------------------------------------------
MK.DEFAULT = {
	days = { { 1, 10 }, { 3, 20 }, { 5, 30 }, { 7, 40 } }, -- days, fee per thousand
	minFee = 10, commission = 10, minPct = 5, maxPct = 200, listingsMax = 50, buysPerDay = 50, pairPerWeek = 5,
	displaysPerWeek = 0, quarantine = 7,
	card = { 2000, 5000, 15000, 60000, 250000, 1000000 }, thunder = 2, titan = 3, top = 2,
	booster = { zone = 2000, dungeon = 7500, raid = 20000, event = 3000 },
	-- (1 November, 14 h 20, his choice « C »: as the reseller sells them, Displays.lua; 25 000 and 50 000 before)
	display = { zone = 35000, dungeon = 100000, raid = 300000, event = 60000 }, cased = 2500,
	case = 200, crate = { 100, 1000, 4000, 20000, 150000 },
}

function MK:Rules()
	local n = self:News()
	return (n and n.rules) or self.DEFAULT
end

-- The kind of an album for its boosters and displays: "zone", "dungeon", "raid", "event" (nil: none, the Hardcup).
function MK.AlbumKind(s)
	if type(s) ~= "table" or s.limited then
		return nil
	end
	if s.event then
		return "event"
	elseif s.kind == "zone" then
		return "zone"
	elseif s.kind == "dungeon" then
		return s.raid and "raid" or "dungeon"
	end
	return nil
end

-- Whether this version of Curator knows a thing (its card, its album, its edition): one it does not know is not offered
-- to it (a thing of a newer version: it could not take it).
function MK.Known(it)
	if type(it) ~= "table" then
		return false
	elseif it.k == "c" then
		return ns.Cards["c" .. it.npc] ~= nil
	elseif it.k == "b" or it.k == "d" then
		return MK.AlbumKind(ns.SeriesByKey(it.series)) ~= nil
	elseif it.k == "x" or it.k == "w" then
		return ns.Cases ~= nil and ns.Cases:Known(it.edition) or false
	end
	return false
end

-- (1.14.0, his word) A booster or a display (a thing, or what a barter or a buy order asks) of an album this collection
-- has not unlocked (Level.lua: LV:Unlocked, a booster of it won by playing): it is not bought here, nor asked for.
function MK:Locked(it)
	if type(it) ~= "table" or not (it.k == "b" or it.k == "d") then
		return false
	end
	local s = ns.SeriesByKey(it.series)
	local LV = ns.Level
	return not (s and LV and LV:Unlocked(s))
end

-- The value of reference of a thing (its price is held to it).
function MK:Ref(it)
	local r = self:Rules()
	if it.k == "c" then
		local card = ns.Cards["c" .. it.npc]
		local base = r.card[min(6, max(1, card and card.rarity or 1))]
		local fin = (it.f == "s" and r.thunder) or (it.f == "h" and r.titan) or 1
		local top = ((it.g == 1000 and it.sl == true) or (it.seal and it.seal.rank == 10)) and r.top or 1
		return base * fin * top
	elseif it.k == "b" or it.k == "d" then
		local k = self.AlbumKind(ns.SeriesByKey(it.series))
		if not k then
			return 0
		end
		if it.k == "b" then
			return r.booster[k] or 0
		end
		return (r.display[k] or 0) + (it.cased and r.cased or 0)
	elseif it.k == "x" then
		return r.case
	elseif it.k == "w" then
		local base = r.crate[min(5, max(1, it.rank))]
		local fin = (it.f == "t" and r.thunder) or (it.f == "T" and r.titan) or 1
		return base * fin * ((it.ap and it.grade == 10) and r.top or 1)
	end
	return 0
end

-- The value of reference of what is asked (a copy from a grade: as one of that grade).
function MK:RefAsk(a)
	local r = self:Rules()
	if a.k == "c" then
		local card = ns.Cards["c" .. a.npc]
		local base = r.card[min(6, max(1, card and card.rarity or 1))]
		local fin = (a.f == "s" and r.thunder) or (a.f == "h" and r.titan) or 1
		return base * fin * ((a.min or 0) == 10 and r.top or 1)
	end
	if a.k == "x" then
		return r.case
	end
	return self:Ref({ k = a.k, series = a.series, cased = a.cased })
end

-- The bounds of a price for a value of reference: lowest, highest (whole rubies). The Atelier may free them (a floor of
-- 0 %, a ceiling as high as it likes): a ruby at least, never more than a box of a price takes (nine digits).
MK.MAX_PRICE = 999999999
function MK:Bounds(ref)
	local r = self:Rules()
	local lo = min(MK.MAX_PRICE, max(1, math.ceil(ref * r.minPct / 100)))
	return lo, min(MK.MAX_PRICE, max(lo, floor(ref * r.maxPct / 100)))
end

-- The fee of a listing for so many days (base: its price; a barter, its value of reference); nil: not a duration.
function MK:Fee(base, days)
	for _, d in ipairs(self:Rules().days) do
		if d[1] == days then
			return max(self:Rules().minFee, floor(max(0, base) * d[2] / 1000))
		end
	end
	return nil
end

-- What a sale gives its seller: the rubies paid, less the commission.
function MK:Net(rubies)
	return rubies - floor(max(0, rubies) * self:Rules().commission / 100)
end

-------------------------------------------------------------------------------
-- The news of the market (Feed.lua; the website: lib/market/news.ts), believed only signed by the website
-------------------------------------------------------------------------------
local function Nums(s)
	local out = {}
	for v in CuratorOctoFull.Gmatch((s or ""), "[^,]+") do
		out[CuratorOctoFull.Length(out) + 1] = tonumber(v)
	end
	return out
end

-- The news in a text (nil: not news of the market).
function MK:Parse(text)
	if type(text) ~= "string" or CuratorOctoFull.Length(text) > self.NEWS_MAX then
		return nil
	end
	local lines = Split(text, "\n")
	if lines[1] ~= "curator-feed 1" or lines[2] ~= "market 1" then
		return nil
	end
	local d = self.DEFAULT
	local n = { msgs = {}, mine = {}, sel = {}, orders = {}, prices = {}, rules = {}, favs = {} }
	local r = n.rules
	for k, v in pairs(d) do
		r[k] = v
	end
	for i = 3, CuratorOctoFull.Length(lines) do
		local f = Split(lines[i], " ")
		local k = f[1]
		if k == "t" then
			n.t = Dec(f[2], 0, 4e9)
		elseif k == "v" then
			n.v = Dec(f[2], 0, 4e9)
		elseif k == "o" then
			n.open = f[2] == "1"
			n.opens = Dec(f[3] or "", 0, 4e9)
		elseif k == "y" and CuratorOctoFull.Length(f) == 4 then
			r.commission, r.minFee = tonumber(f[2]) or d.commission, tonumber(f[3]) or d.minFee
			local days = {}
			for dd, pm in CuratorOctoFull.Gmatch((f[4] .. ","), "(%d+):(%d+),") do
				days[CuratorOctoFull.Length(days) + 1] = { tonumber(dd), tonumber(pm) }
			end
			if CuratorOctoFull.Length(days) > 0 then
				r.days = days
			end
		elseif k == "z" and CuratorOctoFull.Length(f) == 8 then
			r.minPct, r.maxPct, r.listingsMax, r.buysPerDay = tonumber(f[2]), tonumber(f[3]), tonumber(f[4]), tonumber(f[5])
			r.pairPerWeek, r.displaysPerWeek, r.quarantine = tonumber(f[6]), tonumber(f[7]), tonumber(f[8])
		elseif k == "k" and CuratorOctoFull.Length(f) == 3 then
			local v = Nums(f[3])
			if f[2] == "card" and CuratorOctoFull.Length(v) == 6 then
				r.card = v
			elseif f[2] == "fin" and CuratorOctoFull.Length(v) == 3 then
				r.thunder, r.titan, r.top = v[1], v[2], v[3]
			elseif f[2] == "booster" and CuratorOctoFull.Length(v) == 4 then
				r.booster = { zone = v[1], dungeon = v[2], raid = v[3], event = v[4] }
			elseif f[2] == "display" and CuratorOctoFull.Length(v) == 5 then
				r.display, r.cased = { zone = v[1], dungeon = v[2], raid = v[3], event = v[4] }, v[5]
			elseif f[2] == "case" and CuratorOctoFull.Length(v) == 1 then
				r.case = v[1]
			elseif f[2] == "crate" and CuratorOctoFull.Length(v) == 5 then
				r.crate = v
			end
		elseif k == "m" and CuratorOctoFull.Length(f) >= 4 then
			local seq, cid = Dec(f[2], 1, 2e9), f[3]
			if seq and CuratorOctoFull.Match(cid, "^%x+$") and CuratorOctoFull.Length(cid) == 16 then
				local list = n.msgs[cid] or {}
				n.msgs[cid] = list
				local args = {}
				for j = 5, CuratorOctoFull.Length(f) do
					args[CuratorOctoFull.Length(args) + 1] = f[j]
				end
				list[CuratorOctoFull.Length(list) + 1] = { seq = seq, kind = f[4], args = args }
			end
		elseif k == "s" and CuratorOctoFull.Length(f) == 8 then
			n.mine[CuratorOctoFull.Length(n.mine) + 1] = {
				cid = f[2], n = Dec(f[3], 1, 2e9), shown = f[4] == "o", price = Dec(f[5], 1, 1e12), ends = Dec(f[6], 0, 4e9),
				id = Dec(f[7], 1, 1e15), order = f[8] == "o",
			}
		elseif k == "l" and CuratorOctoFull.Length(f) == 11 then
			local it = self.Unpack(f[11])
			local id = Dec(f[2], 1, 1e15)
			if it and id and self.Known(it) then
				local asks = {}
				if f[9] ~= "-" then
					for _, a in ipairs(Split(f[9], "+")) do
						asks[CuratorOctoFull.Length(asks) + 1] = self.ReadAsk(a)
					end
				end
				n.sel[CuratorOctoFull.Length(n.sel) + 1] = {
					id = id, ends = Dec(f[3], 0, 4e9) or 0, price = Dec(f[4], 1, 1e12), count = Dec(f[5], 1, 1e6) or 1,
					from = Dec(f[6], 1, 1e12), seller = f[7], ac = Dec(f[8], 0, 20), asks = asks, cp = Dec(f[10], 0, 1e12) or 0,
					pack = f[11], it = it,
				}
			end
		elseif k == "r" and CuratorOctoFull.Length(f) == 6 then
			local a = self.ReadAsk(f[6])
			local id = Dec(f[2], 1, 1e15)
			if a and id then
				n.orders[CuratorOctoFull.Length(n.orders) + 1] = { id = id, ends = Dec(f[3], 0, 4e9) or 0, price = Dec(f[4], 1, 1e12) or 0, buyer = f[5], spec = f[6], ask = a }
			end
		elseif k == "f" and CuratorOctoFull.Length(f) == 2 then
			-- (a favorite of the player: a star on the website, or in the game)
			if CuratorOctoFull.Length(f[2]) <= 60 then
				n.favs[f[2]] = true
			end
		elseif k == "q" and CuratorOctoFull.Length(f) == 5 then
			local pts = {}
			if f[5] ~= "-" then
				for dd, p in CuratorOctoFull.Gmatch((f[5] .. ","), "(%d+):(%d+),") do
					pts[CuratorOctoFull.Length(pts) + 1] = { tonumber(dd), tonumber(p) }
				end
			end
			n.prices[f[2]] = { median = Dec(f[3], 0, 1e12), n = Dec(f[4], 0, 1e9) or 0, pts = pts }
		end
	end
	if not n.t then
		return nil
	end
	for _, list in pairs(n.msgs) do
		table.sort(list, function(a, b)
			return a.seq < b.seq
		end)
	end
	return n
end

-- The news of the market of the Feed.lua loaded (the newest signed by the website), or nil: read once (Feed.lua
-- changes only when the game loads it again).
function MK:News()
	if self.test then
		return self.test.news
	end
	local list = ns.FEED
	if self.newsOf == list and self.newsRead then
		return self.news
	end
	self.newsOf, self.newsRead, self.news = list, true, nil
	local F, key = ns.Front, ns.FEED_KEY
	if not (F and F.Check and type(key) == "table" and type(list) == "table") then
		return nil
	end
	for _, e in ipairs(list) do
		local text, sig = type(e) == "table" and e[1], type(e) == "table" and e[2]
		if type(text) == "string" and type(sig) == "string" and CuratorOctoFull.Length(text) <= self.NEWS_MAX and CuratorOctoFull.Length(sig) <= 1024
			and string.find(text, "^curator%-feed 1\nmarket 1\n") then
			local n = self:Parse(text)
			if n and (not self.news or n.t > self.news.t) and F:Check(text, sig, key) then
				self.news = n
			end
		end
	end
	return self.news
end

-- (a new Feed.lua, the tests) read again at the next ask.
function MK:Forget()
	self.newsOf, self.newsRead, self.news = nil, nil, nil
end

-- Whether the news are good to list and to buy with now: true, or false and why ("app": none, "old": older than
-- those read before or past their days, "closed": the market closed, with when it opens).
function MK:Fresh()
	local n = self:News()
	if not n then
		return false, "app"
	end
	local m = self:Db()
	if m and n.t < Int(m.t) then
		return false, "old"
	end
	if n.v and n.v < Now() then
		return false, "old"
	end
	if not n.open then
		return false, "closed", n.opens
	end
	return true
end

-------------------------------------------------------------------------------
-- What the save keeps
-------------------------------------------------------------------------------
local function Fill(m)
	for _, k in ipairs({ "ls", "bu", "od", "fl", "wd", "pc", "fv", "qt", "qp", "h", "st", "mb" }) do
		if type(m[k]) ~= "table" then
			m[k] = {}
		end
	end
	m.n, m.seq, m.t = Int(m.n), Int(m.seq), Int(m.t)
end

-- db.market (make: made when it is not there; else nil for a collection that never used the market).
function MK:Db(make)
	local db = ns.db
	if not db then
		return nil
	end
	local m = db.market
	if type(m) ~= "table" then
		if not make then
			return nil
		end
		m = {}
		db.market = m
	end
	if m ~= self.filled then
		Fill(m)
		self.filled = m
	end
	-- (the market of this very collection: one of another id is the one of a collection emptied since, gone with it; the
	-- website believes a market only with the id of its save: lib/market/save.ts)
	local cid = type(db.cid) == "string" and db.cid or nil
	if cid and m.cid ~= nil and m.cid ~= cid then
		m = {}
		db.market = m
		Fill(m)
		self.filled = m
	end
	if cid and m.cid == nil then
		m.cid = cid
	end
	return m
end

local function NextN(m)
	m.n = Int(m.n) + 1
	return m.n
end

-- Something of the market changed: the windows follow.
local function Changed(what)
	ns.Fire("MARKET_CHANGED", what)
end

-- An event kept for the pages Mes ventes and Mes achats (k: "sold", "back", "bought", "refund", "listed", "order",
-- "filled", "unfilled", "ordered").
local function Note(m, k, pack, p, who)
	local h = m.h
	h[CuratorOctoFull.Length(h) + 1] = { k = k, it = pack, p = p, t = Now(), w = who }
	while CuratorOctoFull.Length(h) > MK.HISTORY do
		CuratorOctoFull.Remove(h, 1)
	end
end

local function Stat(m, k, n)
	m.st[k] = Int(m.st[k]) + (n or 1)
end

-- A deep copy of a table of the save (what came out of the collection, to put it back as it was).
local function Copy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = Copy(v)
	end
	return out
end

-------------------------------------------------------------------------------
-- The quarantine of what is bought
-------------------------------------------------------------------------------
-- A copy of a card bought, waiting (its number): until when (nil: free).
function MK:Quarantined(id)
	local m = self:Db()
	local q = m and id and m.qt[id]
	if type(q) == "table" and Int(q.u) > Now() then
		return Int(q.u)
	end
	return nil
end

-- The copies of a card bought that wait, by their finish ("normal", "shiny", "holo", "corrupt"): { [finish] = n }, and
-- when the last of them is free (Trade.lua counts them with those of the trades: T:CountLocks).
function MK:QuarantinedCopies()
	local m = self:Db()
	local out, now = {}, Now()
	for id, q in pairs(m and m.qt or {}) do
		if type(q) == "table" and Int(q.u) > now and type(q.k) == "string" then
			local rec = ns.Copies and ns.Copies:Get(q.k, id)
			if rec then
				out[CuratorOctoFull.Length(out) + 1] = { k = q.k, f = ns.Copies.Finish(rec) or "normal", u = Int(q.u) }
			else
				m.qt[id] = nil
			end
		elseif type(q) ~= "table" or Int(q.u) <= now then
			m.qt[id] = nil
		end
	end
	return out
end

-- How many things of a spec (b:<album>, d:<album>:<cased>, x:<edition>) wait their quarantine.
function MK:QuarantinedCount(spec)
	local m = self:Db()
	local list = m and m.qp[spec]
	if type(list) ~= "table" then
		return 0
	end
	local n, now, keep = 0, Now(), {}
	for _, x in ipairs(list) do
		if type(x) == "table" and Int(x.u) > now then
			n = n + Int(x.n)
			keep[CuratorOctoFull.Length(keep) + 1] = x
		end
	end
	m.qp[spec] = CuratorOctoFull.Length(keep) > 0 and keep or nil
	return n
end

local function Quarantine(m, spec, days)
	local list = m.qp[spec] or {}
	list[CuratorOctoFull.Length(list) + 1] = { u = Now() + days * 86400, n = 1 }
	m.qp[spec] = list
end

-------------------------------------------------------------------------------
-- The things of the collection: what each one is, what can go, out and back in
-------------------------------------------------------------------------------
local FIN = { s = "shiny", h = "holo", c = "corrupt" }   -- the finish of a pack, as the collection says it
local FK = { shiny = "s", holo = "h", corrupt = "c" }
local CRATE_F = { thunder = "t", titan = "T" }
local CRATE_FIN = { t = "thunder", T = "titan" }

-- A copy of a card of the collection as a thing of the market (key: the card's; rec: its record; nil: not one).
function MK:CardItem(key, rec)
	local npc = type(key) == "string" and tonumber(CuratorOctoFull.Match(key, "^c(%d+)$"))
	if not (npc and type(rec) == "table") then
		return nil
	end
	local CP = ns.Copies
	local f = rec.f == nil and "n" or rec.f
	local it = { k = "c", npc = npc, f = f, g = 0, m = "", ce = 0, hg = 0, r = {}, ot = 0, ow = "", och = "", cor = 0 }
	if f ~= "c" then
		local g = CP and CP.Grade(rec)
		if g then
			it.g = g
			it.m = (type(rec.m) == "string" and CuratorOctoFull.Match(rec.m, "^[1-9A][1-9A][1-9A][1-9A]$")) and rec.m or ""
			it.ce = Int(rec.ce)
			it.sl = rec.sl ~= false
		end
		local hg = tonumber(rec.hg)
		if hg and hg >= 100 and hg <= 1000 then
			it.hg = floor(hg)
		end
		for _, x in ipairs(type(rec.r) == "table" and rec.r or {}) do
			if CuratorOctoFull.Length(it.r) < 9 and type(x) == "table" then
				local a = Int(x[3])
				it.r[CuratorOctoFull.Length(it.r) + 1] = { Int(x[1]), max(1, min(4, Int(x[2]))), min(1000, a) }
			end
		end
	else
		it.cor = ns.Collection.Gauge(rec.cor)
		if rec.ws then
			local SL = ns.Masters
			local x = SL and SL:Record(ns.Cards[key], rec.i)
			if x then
				local marks = type(x.s) == "string" and CuratorOctoFull.Match(x.s, "^[1-9A][1-9A][1-9A][1-9A]$") or nil
				if marks then
					it.seal = { rank = max(1, min(10, Int(x.g))), marks = marks, pact = Int(x.c), t = Int(x.t), master = type(x.by) == "string" and x.by or "" }
				end
			end
		end
	end
	-- (1.14.0: a titanforged copy, its pattern)
	it.pt = CP and CP.Pattern(rec) or nil
	-- (1 November: its wear, the very same card at its buyer's)
	it.wear = ns.Wear and ns.Wear.Pack and ns.Wear.Pack(rec) or nil
	-- (1 November: titanforged, its certificate of the mages with it, Mages.lua)
	local MG = ns.Mages
	it.tc = it.pt and MG and MG.Pack(MG.Of(rec)) or nil
	local o = type(rec.o) == "table" and rec.o or { t = rec.t, w = rec.w, ch = rec.ch }
	it.ot = Int(o.t)
	it.ow = (type(o.w) == "string" and CuratorOctoFull.Match(o.w, "^[a-z]$")) and o.w or ""
	it.och = type(o.ch) == "string" and o.ch or ""
	-- (its one way of writing, the name cut as the website cuts it)
	it.och = MK.Unesc(MK.Esc(it.och)) or ""
	if it.seal then
		it.seal.master = MK.Unesc(MK.Esc(it.seal.master)) or ""
	end
	return it
end

-- A card of a case as a thing of the market (its record, the save's own).
function MK:CrateItem(w)
	local CS = ns.Cases
	if not (CS and type(w) == "table" and type(w.c) == "string") then
		return nil
	end
	local it = { k = "w", edition = w.c, rank = max(1, min(5, Int(w.r))), f = CRATE_F[w.f or ""] or "n", grade = CS.TrueGrade(w),
		ot = Int(w.ot or w.t), oh = (w.oh == "k" or (w.oh == nil and w.h == "k")) and "k" or "" }
	if it.rank == 5 then
		if not tonumber(w.w) then
			return nil
		end
		it.weapon = { item = floor(tonumber(w.w)), line = max(1, Int(w.l)), cls = type(w.cl) == "string" and w.cl or "", side = type(w.fa) == "string" and w.fa or "" }
	else
		if type(w.e) ~= "string" then
			return nil
		end
		it.entry = w.e
	end
	if w.ap then
		local m = type(w.m) == "string" and CuratorOctoFull.Match(w.m, "^[1-9A][1-9A][1-9A][1-9A]$")
		if not m then
			return nil
		end
		it.ap = { m = m, ce = Int(w.ce), at = Int(w.at) }
	end
	-- (1.14.0: titanforged, its pattern)
	it.pt = it.f == "T" and CS.Pattern and CS.Pattern(w) or nil
	-- (1 November: restored at an enchanter, what he did to it travels with it: Wear.lua)
	it.wear = ns.Wear and ns.Wear.Pack and ns.Wear.Pack(w, true) or nil
	-- (1 November: titanforged, its certificate of the mages with it, Mages.lua)
	local MG = ns.Mages
	it.tc = it.pt and MG and MG.Pack(MG.Of(w)) or nil
	return it
end

-- Why a copy of a card cannot go to the market now (nil: it can): those of Copies.lua (at an enchanter, came in a trade
-- not free yet, staked on a duel), and one bought here not free yet ("market"). A corrupted one can, a signed one too.
function MK:Stuck(key, rec)
	local CP = ns.Copies
	if not (CP and rec) then
		return "card"
	end
	local why = CP:Stuck(key, rec)
	if why == "corrupt" then
		why = (CP.Locked(rec) and "locked") or (ns.Duel and ns.Duel.StakedCopy and ns.Duel:StakedCopy(key, rec.i) and "staked") or nil
	end
	if not why and self:Quarantined(rec.i) then
		why = "market"
	end
	return why
end

-- The boosters of an album that can go: those to open, but those that wait (a trade, the market).
function MK:FreePacks(s)
	if not (s and self.AlbumKind(s)) then
		return 0
	end
	return max(0, ns.Packs(s) - self:QuarantinedCount("b:" .. s.key))
end

function MK:FreeDisplays(s, cased)
	local D = ns.Displays
	if not (D and s and D.Eligible(s)) then
		return 0
	end
	local n = cased and D:CasedDisplays(s) or D:Count(s)
	return max(0, n - self:QuarantinedCount("d:" .. s.key .. ":" .. (cased and "1" or "0")))
end

function MK:FreeCases(case)
	local CS = ns.Cases
	if not (CS and CS:Known(case)) then
		return 0
	end
	return max(0, CS:Count(case) - self:QuarantinedCount("x:" .. case))
end

-- Everything of the collection that can go to the market now: { { src, it, pack } } (src: { k = "c", key, id } a copy,
-- { k = "b", series }, { k = "d", series, cased }, { k = "x", edition }, { k = "w", id } a card of a case).
function MK:Sellable()
	local out = {}
	local db = ns.db
	if not db then
		return out
	end
	local CP = ns.Copies
	for _, x in ipairs(CP and CP:All() or {}) do
		if not self:Stuck(x.card.key, x.rec) then
			local it = self:CardItem(x.card.key, x.rec)
			local pack = it and self.Pack(it)
			if pack and CuratorOctoFull.Length(pack) <= self.PACK_MAX then
				out[CuratorOctoFull.Length(out) + 1] = { src = { k = "c", key = x.card.key, id = x.rec.i }, it = it, pack = pack, card = x.card, rec = x.rec }
			end
		end
	end
	for _, s in ipairs(ns.Series or {}) do
		if self:FreePacks(s) > 0 then
			local it = { k = "b", series = s.key }
			out[CuratorOctoFull.Length(out) + 1] = { src = { k = "b", series = s.key }, it = it, pack = self.Pack(it), n = self:FreePacks(s), series = s }
		end
		for _, cased in ipairs({ false, true }) do
			local n = self:FreeDisplays(s, cased)
			if n > 0 then
				local it = { k = "d", series = s.key, cased = cased }
				out[CuratorOctoFull.Length(out) + 1] = { src = { k = "d", series = s.key, cased = cased }, it = it, pack = self.Pack(it), n = n, series = s }
			end
		end
	end
	local CS = ns.Cases
	for _, case in ipairs(CS and CS:Editions() or {}) do
		local n = self:FreeCases(case)
		if n > 0 then
			local it = { k = "x", edition = case }
			out[CuratorOctoFull.Length(out) + 1] = { src = { k = "x", edition = case }, it = it, pack = self.Pack(it), n = n }
		end
	end
	local c = CS and CS.Db and CS.Db()
	for _, w in ipairs(c and c.won or {}) do
		-- (1 November: a card of a case at an enchanter stays: Restore.lua)
		if type(w) == "table" and not (w.mq and Int(w.mq) > Now()) and type(w.aw) ~= "table" then
			local it = self:CrateItem(w)
			local pack = it and self.Pack(it)
			if pack then
				out[CuratorOctoFull.Length(out) + 1] = { src = { k = "w", id = w.i }, it = it, pack = pack, won = CS.Public and CS.Public(w) or w }
			end
		end
	end
	return out
end

-- The thing of a source now (nil and why: not there, or it cannot go).
function MK:Thing(src)
	if type(src) ~= "table" then
		return nil, "thing"
	end
	if src.k == "c" then
		local rec = ns.Copies and ns.Copies:Get(src.key, src.id)
		if not rec then
			return nil, "thing"
		end
		local why = self:Stuck(src.key, rec)
		if why then
			return nil, why
		end
		return self:CardItem(src.key, rec)
	elseif src.k == "b" then
		local s = ns.SeriesByKey(src.series)
		return (self:FreePacks(s) > 0) and { k = "b", series = src.series } or nil, "thing"
	elseif src.k == "d" then
		local s = ns.SeriesByKey(src.series)
		return (self:FreeDisplays(s, src.cased) > 0) and { k = "d", series = src.series, cased = src.cased and true or false } or nil, "thing"
	elseif src.k == "x" then
		return (self:FreeCases(src.edition) > 0) and { k = "x", edition = src.edition } or nil, "thing"
	elseif src.k == "w" then
		local w = ns.Cases and ns.Cases:Card(src.id)
		local c = ns.Cases and ns.Cases.Db and ns.Cases.Db()
		for _, r in ipairs(c and c.won or {}) do
			if type(r) == "table" and r.i == src.id then
				if r.mq and Int(r.mq) > Now() then
					return nil, "market"
				end
				if type(r.aw) == "table" then
					return nil, "away"
				end
				return self:CrateItem(r)
			end
		end
		return nil, w and "thing" or "thing"
	end
	return nil, "thing"
end

-- A thing out of the collection (it goes in deposit): what came out, to put it back as it was (nil: it could not).
local function TakeOut(src)
	local db = ns.db
	if src.k == "c" then
		local CP, C, SL = ns.Copies, ns.Collection, ns.Masters
		local card, e = ns.Cards[src.key], db.cards[src.key]
		local rec = CP and CP:Get(src.key, src.id)
		if not (card and e and rec) then
			return nil
		end
		local fk = rec.f
		local out = { k = "c", key = src.key, f = fk, copy = Copy(rec) }
		if fk == "c" and rec.ws and SL then
			local list = SL:Seals(src.key)
			for i, x in ipairs(list) do
				if x.i == rec.i then
					out.seal = Copy(x)
					CuratorOctoFull.Remove(list, i)
					break
				end
			end
			SL:Db()[src.key] = CuratorOctoFull.Length(list) > 0 and list or nil
		end
		-- (the record goes first, its counts after it: Copies.lua)
		CP:Take(src.key, FIN[fk or ""], 1, { rec.i })
		e.n = max(0, Int(e.n) - 1)
		if fk == "s" then
			e.s = max(0, Int(e.s) - 1)
		elseif fk == "h" then
			e.h = max(0, Int(e.h) - 1)
		elseif fk == "c" then
			if not out.seal then
				local list = C:CorruptCopies(e)
				local v = C.Gauge(rec.cor)
				for i, x in ipairs(list) do
					if x == v then
						CuratorOctoFull.Remove(list, i)
						break
					end
				end
			end
			C:SyncCorrupt(card, e)
		end
		if e.n <= 0 and db.fresh then
			db.fresh[src.key] = nil
		end
		CP:Reconcile(src.key)
		ns.Fire("COPIES_CHANGED")
		return out
	elseif src.k == "b" then
		local s = ns.SeriesByKey(src.series)
		if not (s and MK:FreePacks(s) > 0) then
			return nil
		end
		db.packs[s.key] = max(0, Int(db.packs[s.key]) - 1)
		return { k = "b", series = s.key }
	elseif src.k == "d" then
		local s = ns.SeriesByKey(src.series)
		if not (s and MK:FreeDisplays(s, src.cased) > 0 and ns.Displays:Move(s, src.cased, -1)) then
			return nil
		end
		return { k = "d", series = s.key, cased = src.cased and true or false }
	elseif src.k == "x" then
		if not (MK:FreeCases(src.edition) > 0 and ns.Cases:Move(src.edition, -1)) then
			return nil
		end
		return { k = "x", edition = src.edition }
	elseif src.k == "w" then
		local w = ns.Cases and ns.Cases:TakeWon(src.id)
		return w and { k = "w", won = w } or nil
	end
	return nil
end

-- What came out back in, as it was.
local function PutBack(rec)
	local db = ns.db
	if type(rec) ~= "table" then
		return false
	end
	if rec.k == "c" then
		local CP, C, SL = ns.Copies, ns.Collection, ns.Masters
		local card = ns.Cards[rec.key]
		if not (card and CP and type(rec.copy) == "table") then
			return false
		end
		local e = db.cards[rec.key]
		if not e then
			e = { n = 0, s = 0, t = Now() }
			db.cards[rec.key] = e
		end
		local fk = rec.f
		if fk == "c" then
			if rec.seal and SL then
				local list = SL:Seals(rec.key)
				list[CuratorOctoFull.Length(list) + 1] = Copy(rec.seal)
				SL:Db()[rec.key] = list
			else
				local list = C:CorruptCopies(e)
				list[CuratorOctoFull.Length(list) + 1] = C.Gauge(rec.copy.cor)
			end
		end
		CP:Put(rec.key, { Copy(rec.copy) })
		e.n = Int(e.n) + 1
		if fk == "s" then
			e.s = Int(e.s) + 1
		elseif fk == "h" then
			e.h = Int(e.h) + 1
		elseif fk == "c" then
			C:SyncCorrupt(card, e)
		end
		CP:Reconcile(rec.key)
		ns.Fire("COPIES_CHANGED")
		return true
	elseif rec.k == "b" then
		db.packs[rec.series] = Int(db.packs[rec.series]) + 1
		return true
	elseif rec.k == "d" then
		local s = ns.SeriesByKey(rec.series)
		return s ~= nil and ns.Displays:Move(s, rec.cased, 1)
	elseif rec.k == "x" then
		return ns.Cases:Move(rec.edition, 1)
	elseif rec.k == "w" then
		return ns.Cases:PutWon(Copy(rec.won))
	end
	return false
end
MK.PutBack = PutBack
-- (1.14.0, a player's word: what the reseller buys leaves as a thing put on sale here does: Reseller.lua)
MK.TakeOut = TakeOut

-- A thing that came from the market (its pack read), into the collection: with its story, how it came ("m": the
-- market, who: the other side), in quarantine (days). What came: { card, rec } a copy, else true; nil: it could not.
local function Receive(it, who, days)
	local m = MK:Db(true)
	if it.k == "c" then
		local key = "c" .. it.npc
		local card = ns.Cards[key]
		local CP, C, SL = ns.Copies, ns.Collection, ns.Masters
		if not (card and CP) then
			return nil
		end
		local finish = FIN[it.f]
		local fk = CP.Key(finish)
		local r = { f = fk }
		if it.g > 0 then
			r.g, r.m, r.ce, r.sl = it.g, it.m ~= "" and it.m or nil, it.ce > 0 and it.ce or nil, it.sl ~= false
		end
		if it.hg > 0 then
			r.hg = it.hg
		end
		if CuratorOctoFull.Length(it.r) > 0 then
			r.r = Copy(it.r)
		end
		r.o = { t = it.ot > 0 and it.ot or nil, w = it.ow ~= "" and it.ow or nil, ch = it.och ~= "" and it.och or nil }
		-- (1.14.0: a titanforged copy, its pattern; one without gets one here, Copies.lua)
		if it.pt and fk == "h" then
			r.pt = it.pt
		end
		-- (1 November, his word: the very same card, its very same grade: its wear as its seller had it)
		local x = it.wear and ns.Wear and ns.Wear.Unpack and ns.Wear.Unpack(it.wear)
		if x then
			r.wv, r.wq, r.w0, r.wx, r.wa, r.hm = x.wv, x.wq, x.w0, x.wx, x.wa, x.hm
		end
		-- (1 November: its certificate of the mages, as its seller had it, Mages.lua)
		local tc = it.tc and r.pt and ns.Mages and ns.Mages.Unpack(it.tc)
		if tc then
			r.tc = tc
		end
		CP:Expect(key, r)
		CP:SetContext({ w = "m", p = who })
		CP.last = nil
		C:Add(card, finish, it.cor > 0 and it.cor or nil)
		local got = CP.last
		CP:SetContext(nil)
		CP.expect[key] = nil
		if not got then
			return nil
		end
		-- (a reliquary: its seal with it, its corruption out of those not sealed)
		if it.seal and SL and fk == "c" then
			local e = C:Entry(card)
			local list = C:CorruptCopies(e)
			for i, v in ipairs(list) do
				if v == it.cor then
					CuratorOctoFull.Remove(list, i)
					break
				end
			end
			local seals = SL:Seals(key)
			seals[CuratorOctoFull.Length(seals) + 1] = { g = it.seal.rank, s = it.seal.marks, c = it.seal.pact, k = it.cor, t = it.seal.t, by = it.seal.master, i = got.i }
			SL:Db()[key] = seals
			C:SyncCorrupt(card, e)
			CP:Reconcile(key)
		end
		C:Remember(card, finish, "m", who)
		if days > 0 then
			m.qt[got.i] = { k = key, u = Now() + days * 86400 }
		end
		ns.Fire("COPIES_CHANGED")
		return { card = card, rec = got }
	elseif it.k == "b" then
		local s = ns.SeriesByKey(it.series)
		if not (s and MK.AlbumKind(s)) then
			return nil
		end
		-- (1.14.0, his word: a booster of the Bourse unlocks nothing, Level.lua: LV:Unlocked)
		ns.db.packs[s.key] = Int(ns.db.packs[s.key]) + 1
		if days > 0 then
			Quarantine(m, "b:" .. s.key, days)
		end
		return true
	elseif it.k == "d" then
		local s = ns.SeriesByKey(it.series)
		if not (s and ns.Displays:Move(s, it.cased, 1)) then
			return nil
		end
		if days > 0 then
			Quarantine(m, "d:" .. s.key .. ":" .. (it.cased and "1" or "0"), days)
		end
		return true
	elseif it.k == "x" then
		if not ns.Cases:Move(it.edition, 1) then
			return nil
		end
		if days > 0 then
			Quarantine(m, "x:" .. it.edition, days)
		end
		return true
	elseif it.k == "w" then
		local w = ns.Cases:Receive({ edition = it.edition, rank = it.rank, entry = it.entry, weapon = it.weapon, f = CRATE_FIN[it.f],
			grade = it.grade, ap = it.ap, ot = it.ot, oh = it.oh, pt = it.pt, wear = it.wear, tc = it.tc })
		if not w then
			return nil
		end
		if days > 0 then
			w.mq = Now() + days * 86400
		end
		return { won = w }
	end
	return nil
end
MK.Receive = Receive

-- A thing that came from the market, into the collection; one this version cannot take now (its card, its album, its
-- edition unknown to it: an older Curator) waits in the mailbox of the market, tried again at each load, never lost.
-- True: it came now.
local function Deliver(m, pack, it, who, days)
	if it and Receive(it, who, days) then
		return true
	end
	if CuratorOctoFull.Length(m.mb) < 200 then
		m.mb[CuratorOctoFull.Length(m.mb) + 1] = { it = pack, w = who, d = days, t = Now() }
	end
	return false
end

-- What waits in the mailbox, tried again: how many came now, how many still wait.
function MK:Mailbox()
	local m = self:Db()
	if not (m and CuratorOctoFull.Length(m.mb) > 0) then
		return 0, 0
	end
	local came, left = 0, {}
	for _, x in ipairs(m.mb) do
		local it = type(x) == "table" and type(x.it) == "string" and self.Unpack(x.it) or nil
		if it and Receive(it, x.w, Int(x.d)) then
			came = came + 1
		elseif type(x) == "table" then
			left[CuratorOctoFull.Length(left) + 1] = x
		end
	end
	m.mb = left
	if came > 0 then
		Changed("mailbox")
		ns.Fire("CHANGED")
	end
	return came, CuratorOctoFull.Length(left)
end

-------------------------------------------------------------------------------
-- The rubies of the market: moved, not made (no talent, no guard; their own counters)
-------------------------------------------------------------------------------
local function RubiesOut(m, n)
	local RB = ns.Rubies
	n = Int(n)
	if n <= 0 then
		return true
	end
	if not (RB and RB:Has(n)) then
		return false
	end
	ns.db.rubies = RB:Balance() - n
	RB:Log(-n, "market")
	Stat(m, "rout", n)
	ns.Fire("RUBIES_CHANGED", -n, "market")
	return true
end

local function RubiesIn(m, n)
	local RB = ns.Rubies
	n = Int(n)
	if n <= 0 or not RB then
		return
	end
	ns.db.rubies = RB:Balance() + n
	RB:Log(n, "market")
	Stat(m, "rin", n)
	ns.Fire("RUBIES_CHANGED", n, "market")
end

-------------------------------------------------------------------------------
-- Who can use the market, and where
-------------------------------------------------------------------------------
-- (UI/Market.lua) at an auctioneer now: the only place where one lists and buys.
MK.at = false

-- Whether this collection can list and buy now: true, or false and why ("test", "edited", "beta": closed, "author":
-- the author's build (his test mode only), "guard", "pass" (and why there), and those of the news: "app", "old",
-- "closed" (and when it opens), "away": not at an auctioneer).
function MK:CanUse(anywhere)
	local db = ns.db
	if not db then
		return false, "test"
	end
	if db.edited then
		return false, "edited"
	end
	if Closed() then
		return false, "beta"
	end
	if db.test and not self.test then
		return false, "test"
	end
	if ns.Admin and not self.test then
		return false, "author"
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard"
	end
	if ns.Pass and not self.test then
		local ok, why = ns.Pass:Ok(false)
		if not ok then
			return false, "pass", why
		end
	end
	local ok, why, when = self:Fresh()
	if not ok then
		return false, why, when
	end
	if not anywhere and not self.at then
		return false, "away"
	end
	return true
end

-- My listings and orders at once (in the save).
function MK:Active()
	local m = self:Db()
	local n = 0
	for _ in pairs(m and m.ls or {}) do
		n = n + 1
	end
	for _ in pairs(m and m.od or {}) do
		n = n + 1
	end
	return n
end

-- The purchases of the day before (those on the way and those received).
function MK:BoughtToday()
	local m = self:Db()
	local n, since = 0, Now() - 86400
	for _, b in pairs(m and m.bu or {}) do
		if Int(b.t) > since then
			n = n + 1
		end
	end
	for _, h in ipairs(m and m.h or {}) do
		if h.k == "bought" and Int(h.t) > since then
			n = n + 1
		end
	end
	return n
end

-- The displays bought this week (on the way, received).
function MK:DisplaysThisWeek()
	local m = self:Db()
	local n, since = 0, Now() - 7 * 86400
	for _, h in ipairs(m and m.h or {}) do
		if h.k == "bought" and Int(h.t) > since and type(h.it) == "string" and string.sub(h.it, 1, 2) == "d." then
			n = n + 1
		end
	end
	return n
end

-------------------------------------------------------------------------------
-- What the player does
-------------------------------------------------------------------------------
-- What a barter asks, read (specs or asks); nil: one is not.
local function Asks(list)
	local out = {}
	for _, a in ipairs(list or {}) do
		local x = type(a) == "string" and MK.ReadAsk(a) or a
		if type(x) ~= "table" or x.k == nil then
			return nil
		end
		out[CuratorOctoFull.Length(out) + 1] = x
	end
	return out
end

-- A thing put on sale (src: a line of MK:Sellable), opts = { p = price (nil: barter only), tr = { asks }, cp = rubies
-- more with the barter, d = days, ac = its line (0 to MK.ACCROCHES - 1) }. Its number, or nil and why: as CanUse, and
-- "thing" (not there, or it cannot go: its why), "price" (out of the bounds: the lowest, the highest), "asks", "days",
-- "rubies" (the fee), "limit".
function MK:List(src, opts)
	local ok, why, w2 = self:CanUse()
	if not ok then
		return nil, why, w2
	end
	opts = opts or {}
	local it, w = self:Thing(src)
	if not it then
		return nil, "thing", w
	end
	local ref = self:Ref(it)
	if ref <= 0 then
		return nil, "thing"
	end
	local p = opts.p ~= nil and Int(opts.p) or nil
	local asks = Asks(opts.tr)
	if not asks or CuratorOctoFull.Length(asks) > self.ASKS then
		return nil, "asks"
	end
	if not p and CuratorOctoFull.Length(asks) == 0 then
		return nil, "price"
	end
	local cp = CuratorOctoFull.Length(asks) > 0 and Int(opts.cp) or 0
	local lo, hi = self:Bounds(ref)
	if p and (p < lo or p > hi) then
		return nil, "price", lo, hi
	end
	if CuratorOctoFull.Length(asks) > 0 then
		local asked = cp
		for _, a in ipairs(asks) do
			if self:Locked(a) then
				return nil, "unlock"
			end
			local r = self:RefAsk(a)
			if r <= 0 then
				return nil, "asks"
			end
			asked = asked + r
		end
		if asked < lo or asked > hi then
			return nil, "asks", lo, hi
		end
	end
	local d = Int(opts.d)
	local fee = self:Fee(p or ref, d)
	if not fee then
		return nil, "days"
	end
	if self:Active() >= self:Rules().listingsMax then
		return nil, "limit"
	end
	if not ns.Rubies:Has(fee) then
		return nil, "rubies", fee
	end
	local ac = opts.ac ~= nil and Int(opts.ac) or nil
	if ac and ac >= self.ACCROCHES then
		ac = nil
	end
	local pack = self.Pack(it)
	local m = self:Db(true)
	local rec = TakeOut(src)
	if not rec then
		return nil, "thing"
	end
	if not RubiesOut(m, fee) then
		PutBack(rec)
		return nil, "rubies", fee
	end
	local n = NextN(m)
	local tr
	if CuratorOctoFull.Length(asks) > 0 then
		tr = {}
		for i, a in ipairs(asks) do
			tr[i] = self.AskText(a)
		end
	end
	m.ls[n] = { it = pack, p = p, tr = tr, cp = cp > 0 and cp or nil, d = d, fee = fee, t = Now(), ac = ac, rec = rec }
	Note(m, "listed", pack, p)
	Changed("list")
	ns.Fire("CHANGED")
	return n
end

-- A withdrawal asked (a listing or an order of mine): it goes with the next save, the website confirms it if nobody
-- bought in between. False and why ("none", "away").
function MK:Withdraw(n)
	local m = self:Db()
	if not (m and (m.ls[n] or m.od[n])) then
		return false, "none"
	end
	if not self.at and not self.test then
		return false, "away"
	end
	m.wd[n] = true
	Changed("withdraw")
	return true
end

-- A lower price asked for a listing of mine (no new fee): within its bounds. False and why ("none", "price", "away").
function MK:Reprice(n, price)
	local m = self:Db()
	local l = m and m.ls[n]
	if not (l and l.p) then
		return false, "none"
	end
	if not self.at and not self.test then
		return false, "away"
	end
	local it = self.Unpack(l.it)
	if not it then
		return false, "none"
	end
	price = Int(price)
	local lo = self:Bounds(self:Ref(it))
	if price < lo or price >= Int(m.pc[n] or l.p) then
		return false, "price", lo
	end
	m.pc[n] = price
	Changed("price")
	return true
end

-- The price of a listing of mine now (the one asked last, else its own).
function MK:PriceOf(n)
	local m = self:Db()
	local l = m and m.ls[n]
	return l and (m.pc[n] or l.p) or nil
end

-- A thing come back unsold put on sale again, as it was listed (from the page Mes ventes): its number, or nil and why.
function MK:Relist(src, was)
	return self:List(src, was)
end

-- A buy order: rubies in deposit for a thing precise (spec), at its price, for so many days. Its number, or nil and why
-- (as List: "asks" for a spec that is not one, "price", "days", "rubies", "limit").
function MK:Order(spec, price, days)
	local ok, why, w2 = self:CanUse()
	if not ok then
		return nil, why, w2
	end
	local a = type(spec) == "string" and self.ReadAsk(spec) or spec
	if type(a) ~= "table" or a.k == nil then
		return nil, "asks"
	end
	if self:Locked(a) then
		return nil, "unlock"
	end
	local ref = self:RefAsk(a)
	if ref <= 0 then
		return nil, "asks"
	end
	price = Int(price)
	local lo, hi = self:Bounds(ref)
	if price < lo or price > hi then
		return nil, "price", lo, hi
	end
	if not self:Fee(price, Int(days)) then
		return nil, "days"
	end
	if self:Active() >= self:Rules().listingsMax then
		return nil, "limit"
	end
	local m = self:Db(true)
	if not RubiesOut(m, price) then
		return nil, "rubies", price
	end
	local n = NextN(m)
	m.od[n] = { k = self.AskText(a), p = price, d = Int(days), t = Now() }
	Note(m, "ordered", self.AskText(a), price)
	Changed("order")
	return n
end

-- A purchase of a listing of the selection (sel: its line in the news): its price in rubies, or the barter it asks
-- (give: the sources of the things given, one for each thing asked; the rubies more with them). Its number, or nil and
-- why (as CanUse, "mine", "price" (barter only), "give" (what is given does not answer), "rubies", "day", "cap").
function MK:Buy(sel, give)
	local ok, why, w2 = self:CanUse()
	if not ok then
		return nil, why, w2
	end
	if type(sel) ~= "table" or not sel.id then
		return nil, "gone"
	end
	if self:Locked(sel.it) then
		return nil, "unlock"
	end
	local r = self:Rules()
	if self:BoughtToday() >= r.buysPerDay then
		return nil, "day"
	end
	if sel.it and sel.it.k == "d" and r.displaysPerWeek > 0 and self:DisplaysThisWeek() >= r.displaysPerWeek then
		return nil, "cap"
	end
	local m = self:Db(true)
	local n
	if give then
		if CuratorOctoFull.Length((sel.asks or {})) == 0 or CuratorOctoFull.Length(give) ~= CuratorOctoFull.Length(sel.asks) then
			return nil, "give"
		end
		-- (each thing given answers one thing asked, each one once)
		local items, used = {}, {}
		for i, src in ipairs(give) do
			local it = self:Thing(src)
			if not it then
				return nil, "give"
			end
			items[i] = it
		end
		for _, a in ipairs(sel.asks) do
			local hit
			for i, it in ipairs(items) do
				if not used[i] and self.Answers(it, a) then
					hit = i
					break
				end
			end
			if not hit then
				return nil, "give"
			end
			used[hit] = true
		end
		local cp = Int(sel.cp)
		if not ns.Rubies:Has(cp) then
			return nil, "rubies", cp
		end
		local gv, gr = {}, {}
		for i, src in ipairs(give) do
			local rec = TakeOut(src)
			if not rec then
				for _, back in ipairs(gr) do
					PutBack(back)
				end
				return nil, "give"
			end
			gv[i], gr[i] = self.Pack(items[i]), rec
		end
		if not RubiesOut(m, cp) then
			for _, back in ipairs(gr) do
				PutBack(back)
			end
			return nil, "rubies", cp
		end
		n = NextN(m)
		m.bu[n] = { l = sel.id, p = cp, gv = gv, gr = gr, t = Now(), it = sel.pack }
	else
		local price = sel.price
		if not price then
			return nil, "price"
		end
		if not RubiesOut(m, price) then
			return nil, "rubies", price
		end
		n = NextN(m)
		m.bu[n] = { l = sel.id, p = price, t = Now(), it = sel.pack }
	end
	Changed("buy")
	ns.Fire("CHANGED")
	return n
end

-- A thing of mine sold to a buy order (order: its line in the news; src: the thing). Its number, or nil and why ("give":
-- the thing does not answer the order).
function MK:Fill(order, src)
	local ok, why, w2 = self:CanUse()
	if not ok then
		return nil, why, w2
	end
	if type(order) ~= "table" or not order.id then
		return nil, "gone"
	end
	local it, w = self:Thing(src)
	if not it then
		return nil, "thing", w
	end
	if not self.Answers(it, order.ask) then
		return nil, "give"
	end
	local m = self:Db(true)
	local pack = self.Pack(it)
	local rec = TakeOut(src)
	if not rec then
		return nil, "thing"
	end
	local n = NextN(m)
	m.fl[n] = { o = order.id, it = pack, rec = rec, t = Now(), p = order.price }
	Changed("fill")
	ns.Fire("CHANGED")
	return n
end

-- A star on a thing (its spec): first in the selection of the website (it reads them in the save).
function MK:Favorite(spec, on)
	if type(spec) ~= "string" or CuratorOctoFull.Length(spec) > 60 then
		return false
	end
	local m = self:Db(true)
	m.fv[spec] = on and Now() or nil
	Changed("favorite")
	return true
end

function MK:IsFavorite(spec)
	local m = self:Db()
	return m ~= nil and m.fv[spec] ~= nil
end

-------------------------------------------------------------------------------
-- The messages of the website, applied once each, in their order
-------------------------------------------------------------------------------
local APPLY = {}
MK.APPLY = APPLY

local function Days()
	return Int(MK:Rules().quarantine)
end

-- (the counters of the achievements of a thing sold: a legendary card, a sale of a million, the other side)
local function SoldStats(m, pack, price, cross, barter)
	Stat(m, "sold")
	local it = MK.Unpack(pack)
	local card = it and it.k == "c" and ns.Cards["c" .. it.npc]
	if card and (card.rarity or 0) >= 5 then
		m.st.legend = 1
	end
	if Int(price) >= 1000000 then
		m.st.big = 1
	end
	if cross and barter then
		m.st.cross = 1
	end
end

APPLY.no = function(m, a)
	local n = Dec(a[1] or "", 1, 2e9)
	local l = n and m.ls[n]
	if not l then
		return
	end
	PutBack(l.rec)
	RubiesIn(m, l.fee)
	m.ls[n], m.wd[n], m.pc[n] = nil, nil, nil
	Note(m, "refused", l.it, l.fee, a[2])
end

-- (each message of a thing gone says the very record it closes, as the website judged it: another thing under the same
-- number, in a copy of the save played aside, is never paid for it)
local function SameGiven(gv, a, from)
	local list = gv or {}
	if CuratorOctoFull.Length(a) - from + 1 ~= CuratorOctoFull.Length(list) then
		return false
	end
	for i = 1, CuratorOctoFull.Length(list) do
		if a[from + i - 1] ~= list[i] then
			return false
		end
	end
	return true
end

APPLY.sold = function(m, a)
	local n, rubies, price = Dec(a[1] or "", 1, 2e9), Dec(a[2] or "", 0, 1e13), Dec(a[3] or "", 0, 1e13)
	local days, fee, pack = Dec(a[6] or "", 1, 30), Dec(a[7] or "", 0, 1e13), a[8]
	local l = n and m.ls[n]
	if not (l and rubies and price and days and fee and pack) or l.it ~= pack or Int(l.d) ~= days or Int(l.fee) ~= fee then
		return
	end
	local who = MK.Name(a[4])
	RubiesIn(m, rubies)
	local barter = false
	for j = 9, CuratorOctoFull.Length(a) do
		barter = true
		Deliver(m, a[j], MK.Unpack(a[j]), who, Days())
	end
	m.ls[n], m.wd[n], m.pc[n] = nil, nil, nil
	Note(m, "sold", l.it, rubies, who)
	SoldStats(m, l.it, price, a[5] == "x", barter)
end

APPLY.back = function(m, a)
	local n = Dec(a[1] or "", 1, 2e9)
	local l = n and m.ls[n]
	if not l then
		return
	end
	PutBack(l.rec)
	m.ls[n], m.wd[n], m.pc[n] = nil, nil, nil
	Note(m, "back", l.it, 0, a[2])
end

APPLY.got = function(m, a)
	local n, refund = Dec(a[1] or "", 1, 2e9), Dec(a[2] or "", 0, 1e13)
	local aimed, paid = Dec(a[5] or "", 1, 1e15), Dec(a[6] or "", 0, 1e13)
	local b = n and m.bu[n]
	local pack = a[7] or ""
	local it = MK.Unpack(pack)
	if not (b and refund and aimed and paid and pack ~= "") or Int(b.l) ~= aimed or Int(b.p) ~= paid or not SameGiven(b.gv, a, 8) then
		return
	end
	local who = MK.Name(a[3])
	-- (a card that one of the albums lacked: the achievement Le bon filon)
	local card = it and it.k == "c" and ns.Cards["c" .. it.npc]
	local lacked = card and not ns.Collection:Owned(card)
	Deliver(m, pack, it, who, Days())
	RubiesIn(m, min(refund, Int(b.p)))
	m.bu[n] = nil
	Note(m, "bought", pack, Int(b.p) - min(refund, Int(b.p)), who)
	Stat(m, "bought")
	if lacked then
		Stat(m, "filon")
	end
	if a[4] == "x" and b.gv and CuratorOctoFull.Length(b.gv) > 0 then
		m.st.cross = 1
	end
end

APPLY.ref = function(m, a)
	local n = Dec(a[1] or "", 1, 2e9)
	local b = n and m.bu[n]
	if not b then
		return
	end
	RubiesIn(m, b.p)
	for _, rec in ipairs(b.gr or {}) do
		PutBack(rec)
	end
	m.bu[n] = nil
	Note(m, "refund", b.it, b.p, a[2])
end

APPLY.ogot = function(m, a)
	local n, price = Dec(a[1] or "", 1, 2e9), Dec(a[3] or "", 0, 1e13)
	local o = n and m.od[n]
	local pack = a[4] or ""
	local it = MK.Unpack(pack)
	if not (o and price and pack ~= "") or Int(o.p) ~= price then
		return
	end
	local who = MK.Name(a[2])
	local card = it and it.k == "c" and ns.Cards["c" .. it.npc]
	local lacked = card and not ns.Collection:Owned(card)
	Deliver(m, pack, it, who, Days())
	m.od[n], m.wd[n] = nil, nil
	Note(m, "bought", pack, o.p, who)
	Stat(m, "bought")
	if lacked then
		Stat(m, "filon")
	end
end

APPLY.oend = function(m, a)
	local n = Dec(a[1] or "", 1, 2e9)
	local o = n and m.od[n]
	if not o then
		return
	end
	RubiesIn(m, o.p)
	m.od[n], m.wd[n] = nil, nil
	Note(m, "unfilled", o.k, o.p, a[2])
end

APPLY.fsold = function(m, a)
	local n, rubies, price = Dec(a[1] or "", 1, 2e9), Dec(a[2] or "", 0, 1e13), Dec(a[3] or "", 0, 1e13)
	local order, pack = Dec(a[5] or "", 1, 1e15), a[6]
	local f = n and m.fl[n]
	if not (f and rubies and price and order and pack) or Int(f.o) ~= order or f.it ~= pack then
		return
	end
	local who = MK.Name(a[4])
	RubiesIn(m, rubies)
	m.fl[n] = nil
	Note(m, "sold", f.it, rubies, who)
	SoldStats(m, f.it, price, false, false)
end

APPLY.fno = function(m, a)
	local n = Dec(a[1] or "", 1, 2e9)
	local f = n and m.fl[n]
	if not f then
		return
	end
	PutBack(f.rec)
	m.fl[n] = nil
	Note(m, "back", f.it, 0, a[2])
end

-- The messages of the news for this collection, applied (those after the last one applied, in their order): how many,
-- and what they did ({ { kind, ... } } for the window of the news at the login). Nothing while Curator is stopped, for a
-- save edited or of test, or another addon changed the cards this session (they wait for the next load).
function MK:Apply()
	local db = ns.db
	if not db or db.edited or (db.test and not self.test) or Closed() then
		return 0
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return 0
	end
	local n = self:News()
	if not (n and type(db.cid) == "string") then
		return 0
	end
	local list = n.msgs[db.cid] or {}
	-- (a collection that never came to the market: nothing made for it while nothing comes)
	local m = self:Db(CuratorOctoFull.Length(list) > 0)
	if not m then
		return 0
	end
	local done, said = 0, {}
	for _, msg in ipairs(list) do
		if msg.seq == m.seq + 1 then
			local fn = APPLY[msg.kind]
			local before = CuratorOctoFull.Length(m.h)
			if fn then
				local ok, err = pcall(fn, m, msg.args)
				if not ok and geterrorhandler then
					pcall(geterrorhandler(), err)
				end
			end
			-- (applied, whatever it did: never twice)
			m.seq = msg.seq
			done = done + 1
			for i = before + 1, CuratorOctoFull.Length(m.h) do
				said[CuratorOctoFull.Length(said) + 1] = m.h[i]
			end
		end
	end
	if n.t > Int(m.t) then
		m.t = n.t
	end
	-- (what waited in the mailbox: this version may take it now)
	self:Mailbox()
	-- (a new price the website put on a listing: the listing at it, nothing more to ask)
	for _, s in ipairs(n.mine or {}) do
		local l = s.cid == db.cid and not s.order and s.n and m.ls[s.n]
		if l and m.pc[s.n] and s.price == m.pc[s.n] then
			l.p, m.pc[s.n] = m.pc[s.n], nil
			Changed("price")
		end
	end
	if done > 0 then
		Changed("apply")
		ns.Fire("CHANGED")
		if ns.Achievements and ns.Achievements.Queue then
			ns.Achievements:Queue()
		end
		ns.Fire("MARKET_NEWS", said)
	end
	return done, said
end

-- The state of a listing of mine, as the news say it: "online", "hidden", "waiting" (not seen by the website yet), and
-- its listing on the website (its end, its id).
function MK:StateOf(n, order)
	local news = self:News()
	local db = ns.db
	for _, s in ipairs(news and news.mine or {}) do
		if s.cid == (db and db.cid) and s.n == n and s.order == (order and true or false) then
			return s.shown and "online" or "hidden", s
		end
	end
	return "waiting"
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
ns.On("LOGIN", function()
	MK:Forget()
	MK:Apply()
	local _, left = MK:Mailbox()
	if left > 0 then
		ns.Print(left == 1 and L["A thing bought at the Exchange waits for an update of Curator to come into your collection."]
			or string.format(L["%d things bought at the Exchange wait for an update of Curator to come into your collection."], left))
	end
end)

-- (Core.lua: the collection emptied) its market goes with it: the collection gets a new id, and what waited in the
-- market (in deposit, on the way) was of the old one (the website never judges it again under the new one).
ns.On("COLLECTION_EMPTIED", function(db)
	if type(db) == "table" then
		db.market = nil
	end
	MK.filled = nil
end)
