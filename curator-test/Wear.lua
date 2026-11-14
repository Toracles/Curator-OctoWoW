local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (his idea, 31 October) The wear of the copies: each copy comes in a condition of its own, drawn once when it comes and
-- kept with it, hidden: its grade and its four marks (centering, corners, edges, surface), as the expert will find
-- them (Expertise.lua: an appraisal tells exactly that). It shows on the card, never in words: corners whitened, edges
-- rubbed, scratches that catch the light, a fold... (UI/Wear.lua), each copy its own pieces, from its seed. The grade a
-- tendency, never a reading: the best ones look alike, the worst ones are rare.
-- What is kept on a copy (Copies.lua): wv its seed (1 to 999999: where its pieces are, how big, which way), wq its
-- condition, mixed with its seed (never as it is in the save).
-- His odds (1 November, his word: « totalement random », 80 % of 7 or 8 before): twenty levels, 1 the most worn, 20 new
-- (at 2 h 13, his word again: by bands, W.BANDS). Each level its four marks: their mean from 1 to 10 in nineteen equal
-- steps (20: all four 10); the grade the expert finds, their mean to the tenth: 1; 1,5; 2; 2,5; 3; 3,3; 3,8; ... 8,5; 9;
-- 9,5; 10.
-------------------------------------------------------------------------------
local W = {}
ns.Wear = W

local floor = math.floor

W.LEVELS = 20
-- (1 November, 2 h 13, his word: « je pense que j'ai abusé ») The levels by bands, each level of a band as likely as
-- the others of it: { first, last, the chance of the band }: 18 to 20, 10 %; 14 to 17, 70 %; 1 to 13, 20 %.
W.BANDS = { { 1, 13, 0.20 }, { 14, 17, 0.70 }, { 18, 20, 0.10 } }
-- A level, by a random of 0 to 1.
function W.Level(x)
	x = math.max(0, math.min(0.999999, tonumber(x) or 0))
	local acc = 0
	for _, b in ipairs(W.BANDS) do
		if x < acc + b[3] then
			local n = b[2] - b[1] + 1
			return math.max(b[1], math.min(b[2], b[1] + floor((x - acc) / b[3] * n)))
		end
		acc = acc + b[3]
	end
	return W.LEVELS
end
-- The chance of a level.
function W.LevelChance(level)
	for _, b in ipairs(W.BANDS) do
		if level >= b[1] and level <= b[2] then
			return b[3] / (b[2] - b[1] + 1)
		end
	end
	return 0
end
-- The sum of the four marks of a level (4 to 40).
function W.SumOf(level)
	level = math.max(1, math.min(W.LEVELS, floor(tonumber(level) or 1)))
	if level >= W.LEVELS then
		return 40
	end
	return floor((1 + (level - 1) * 9 / (W.LEVELS - 1)) * 4 + 0.5)
end
-- Its whole grade (what is kept with its marks, the grade of a card of a case): the mean of its marks, rounded; a 10
-- only when all four are 10.
function W.WholeOf(sum)
	sum = tonumber(sum) or 4
	if sum >= 40 then
		return 10
	end
	return math.max(1, math.min(9, floor(sum / 4 + 0.5)))
end
function W.Whole(m)
	return W.WholeOf(m[1] + m[2] + m[3] + m[4])
end
-- The grade the expert finds: the mean of its marks, to its tenth (a 10 only when all four are 10).
function W.Exact(m)
	local s = m[1] + m[2] + m[3] + m[4]
	if s >= 40 then
		return 10
	end
	return math.max(1, math.min(9.9, floor(s / 4 * 10 + 0.5) / 10))
end
-- The four marks of a level (rnd: which marks get the steps over the others, and now and then one a step better and
-- another a step worse: the same mean).
function W.MarksOfLevel(level, rnd)
	local sum = W.SumOf(level)
	if sum >= 40 then
		return { 10, 10, 10, 10 }
	end
	local base, extra = floor(sum / 4), CuratorOctoFull.Mod(sum , 4)
	local m = { base, base, base, base }
	local idx = { 1, 2, 3, 4 }
	for i = 4, 2, -1 do
		local j = 1 + CuratorOctoFull.Mod(floor(rnd() * i) , i)
		idx[i], idx[j] = idx[j], idx[i]
	end
	for k = 1, extra do
		m[idx[k]] = m[idx[k]] + 1
	end
	if rnd() < 0.5 then
		local up, down = idx[4], idx[1]
		if m[up] < 10 and m[down] > 1 and m[up] + 1 - (m[down] - 1) <= 2 then
			m[up], m[down] = m[up] + 1, m[down] - 1
		end
	end
	-- (never all four 10 but at the last level)
	if m[1] + m[2] + m[3] + m[4] < 40 and m[1] == 10 and m[2] == 10 and m[3] == 10 and m[4] == 10 then
		m[1] = 9
	end
	return m
end
-- The whole grades as the twenty levels give them: { grade, its chance }, the finest first (Expertise.lua: the odds of
-- the cards of the cases, the statistics: E.ODDS made of them here, Expertise.lua loaded before this file and Cases.lua
-- after it).
W.ODDS = {}
do
	local n = {}
	for level = 1, W.LEVELS do
		local g = W.WholeOf(W.SumOf(level))
		n[g] = (n[g] or 0) + W.LevelChance(level)
	end
	for g = 10, 1, -1 do
		if n[g] and n[g] > 0 then
			W.ODDS[CuratorOctoFull.Length(W.ODDS) + 1] = { g, floor(n[g] * 1000000 + 0.5) / 1000000 }
		end
	end
	local E = ns.Expertise
	if E then
		E.ODDS = {}
		for i, o in ipairs(W.ODDS) do
			E.ODDS[i] = { o[1], o[2] }
		end
	end
end

-------------------------------------------------------------------------------
-- (1 November, 2 h 49, his word: « je veux que la carte vendue ait la même note, sinon ça n'a aucun sens ») The wear of
-- a copy as it travels (a trade, the Bourse): its seed and its condition (mixed with its seed, as the save keeps it),
-- what the enchanters did to it (the marks its pieces are laid by, the flaws mended, his mishaps, its true marks after):
-- the very same card on the other side, its very same grade. Written "<wv>-<wq>-<w0>-<wx>-<wa>-<hm>" (the last four
-- empty for a copy never restored: "<wv>-<wq>"): wv, wq in base 36; w0, hm four marks (1 to 9, A: 10); wx the flaws
-- mended as a field of bits (five a letter, base 32); wa his mishaps, ten letters each (its kind, where, how big, its
-- turn, its look). A card of a case (Cases.lua): its seed and its grade travel already, the rest only ("-" first).
-------------------------------------------------------------------------------
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local function To36(n, width)
	n = math.max(0, floor(tonumber(n) or 0))
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = floor(n / 36)
	until n == 0
	while width and CuratorOctoFull.Length(s) < width do
		s = "0" .. s
	end
	return s
end
local function From36(s)
	return type(s) == "string" and s ~= "" and CuratorOctoFull.Match(s, "^[0-9a-z]+$") and tonumber(s, 36) or nil
end

-- (the flaws mended, "3,17,22": a field of bits, five a letter)
local function BitsOf(list)
	local ids = {}
	local top = 0
	for x in CuratorOctoFull.Gmatch(tostring(list or ""), "%d+") do
		local n = tonumber(x)
		if n and n >= 1 and n <= 640 then
			ids[n] = true
			top = math.max(top, n)
		end
	end
	if top == 0 then
		return ""
	end
	local out = {}
	for j = 0, floor((top - 1) / 5) do
		local v = 0
		for b = 0, 4 do
			if ids[j * 5 + b + 1] then
				v = v + 2 ^ b
			end
		end
		out[CuratorOctoFull.Length(out) + 1] = string.sub(B36, v + 1, v + 1)
	end
	return table.concat(out)
end
local function ListOf(bits)
	if bits == "" then
		return nil
	end
	if not CuratorOctoFull.Match(bits, "^[0-9a-v]+$") or CuratorOctoFull.Length(bits) > 128 then
		return false
	end
	local ids = {}
	for j = 1, CuratorOctoFull.Length(bits) do
		local v = tonumber(string.sub(bits, j, j), 32)
		for b = 0, 4 do
			if CuratorOctoFull.Mod(floor(v / 2 ^ b) , 2) == 1 then
				ids[CuratorOctoFull.Length(ids) + 1] = (j - 1) * 5 + b + 1
			end
		end
	end
	return CuratorOctoFull.Length(ids) > 0 and table.concat(ids, ",") or nil
end

-- (his mishaps, "fox:x:y:size:turn:look;...": ten letters each)
local KIND_LETTER = { fox = "f", water = "w", stain = "s" }
local LETTER_KIND = { f = "fox", w = "water", s = "stain" }
local function MishapsOf(wa)
	local out = {}
	for part in CuratorOctoFull.Gmatch(tostring(wa or ""), "[^;]+") do
		local kind, x, y, sz, rot, v = CuratorOctoFull.Match(part, "^(%a+):(%d+):(%d+):(%d+):(%d+):(%d+)$")
		local k = kind and KIND_LETTER[kind]
		if k then
			out[CuratorOctoFull.Length(out) + 1] = k .. To36(math.min(1295, tonumber(x)), 2) .. To36(math.min(1295, tonumber(y)), 2) .. To36(math.min(1295, tonumber(sz)), 2)
				.. To36(math.min(1295, tonumber(rot)), 2) .. To36(math.min(35, tonumber(v)), 1)
		end
	end
	return table.concat(out)
end
local function WaOf(s)
	if s == "" then
		return nil
	end
	if CuratorOctoFull.Mod(CuratorOctoFull.Length(s) , 10) ~= 0 or CuratorOctoFull.Length(s) > 60 then
		return false
	end
	local out = {}
	for i = 1, CuratorOctoFull.Length(s), 10 do
		local p = string.sub(s, i, i + 9)
		local kind = LETTER_KIND[string.sub(p, 1, 1)]
		local x, y, sz, rot, v = From36(string.sub(p, 2, 3)), From36(string.sub(p, 4, 5)), From36(string.sub(p, 6, 7)), From36(string.sub(p, 8, 9)), From36(string.sub(p, 10, 10))
		if not (kind and x and y and sz and rot and v and x <= 1000 and y <= 1000 and v >= 1) then
			return false
		end
		out[CuratorOctoFull.Length(out) + 1] = string.format(("%s:%d:%d:%d:%d:%d"), kind, x, y, sz, rot, v)
	end
	return table.concat(out, ";")
end

local function Marks4(s)
	return type(s) == "string" and CuratorOctoFull.Match(s, "^[1-9A][1-9A][1-9A][1-9A]$") or nil
end

-- What travels of the wear of a copy (rec: its record; nil: none known). case: a card of a case (its seed and its grade
-- travel already: what the enchanters did only, nil when nothing).
function W.Pack(rec, case)
	if type(rec) ~= "table" then
		return nil
	end
	local w0, hm = Marks4(rec.w0) or "", Marks4(rec.hm) or ""
	local wx, wa = BitsOf(rec.wx), MishapsOf(rec.wa)
	local restored = w0 ~= "" or wx ~= "" or wa ~= "" or hm ~= ""
	if case then
		return restored and table.concat({ "", w0, wx, wa, hm }, "-") or nil
	end
	local seed, q = tonumber(rec.wv), tonumber(rec.wq)
	if not (seed and q and seed >= 1 and seed <= 999999 and q >= 0 and q < 100000) then
		return nil
	end
	local head = To36(seed) .. "-" .. To36(q)
	if not restored then
		return head
	end
	return table.concat({ head, w0, wx, wa, hm }, "-")
end

-- Back from what travelled: { wv, wq, w0, wx, wa, hm } (nil: not one, or not written its one way).
function W.Unpack(s, case)
	if type(s) ~= "string" or CuratorOctoFull.Length(s) > 200 or not CuratorOctoFull.Match(s, "^[0-9a-zA-Z%-]*$") then
		return nil
	end
	local f = {}
	for part in CuratorOctoFull.Gmatch((s .. "-"), "([^-]*)-") do
		f[CuratorOctoFull.Length(f) + 1] = part
	end
	local out = {}
	local at
	if case then
		if CuratorOctoFull.Length(f) ~= 5 or f[1] ~= "" then
			return nil
		end
		at = 2
	else
		if CuratorOctoFull.Length(f) ~= 2 and CuratorOctoFull.Length(f) ~= 6 then
			return nil
		end
		local seed, q = From36(f[1]), From36(f[2])
		if not (seed and q and seed >= 1 and seed <= 999999 and q < 100000) then
			return nil
		end
		out.wv, out.wq = seed, q
		if CuratorOctoFull.Length(f) == 2 then
			return W.Pack(out) == s and out or nil
		end
		at = 3
	end
	local w0, wx, wa, hm = f[at], f[at + 1], f[at + 2], f[at + 3]
	if (w0 ~= "" and not Marks4(w0)) or (hm ~= "" and not Marks4(hm)) then
		return nil
	end
	local ids, mis = ListOf(wx), WaOf(wa)
	if ids == false or mis == false then
		return nil
	end
	out.w0 = w0 ~= "" and w0 or nil
	out.hm = hm ~= "" and hm or nil
	out.wx, out.wa = ids, mis
	-- (its one way of writing)
	if W.Pack(out, case) ~= s then
		return nil
	end
	return out
end

-- A random of its own, the same for the same seed (a Park-Miller generator).
function W.Rng(seed)
	local s = CuratorOctoFull.Mod(floor(tonumber(seed) or 1) , 2147483646) + 1
	return function()
		s = CuratorOctoFull.Mod((s * 16807) , 2147483647)
		return (s - 1) / 2147483646
	end
end

local function Hash(str)
	local a = 5381
	for k = 1, CuratorOctoFull.Length(str) do
		a = CuratorOctoFull.Mod((a * 33 + CuratorOctoFull.Byte(str, k)) , 2147483647)
	end
	return a
end
W.Hash = Hash

-- A grade by the odds (rnd: a number of 0 to 1).
function W.Draw(x)
	for _, o in ipairs(W.ODDS) do
		x = x - o[2]
		if x < 0 then
			return o[1]
		end
	end
	return W.ODDS[CuratorOctoFull.Length(W.ODDS)][1]
end

-- Its four marks: its grade its worst mark (his word: an 8 looks like an 8), one of the others a step better now and
-- then (the mean still rounds to its grade, as the expert counts it).
function W.MarksFor(g, rnd)
	g = math.max(1, math.min(10, g))
	if g >= 10 then
		return { 10, 10, 10, 10 }
	end
	local m = { g, g, g, g }
	if rnd() < 0.5 then
		m[1 + CuratorOctoFull.Mod(floor(rnd() * 4) , 4)] = g + 1
	end
	return m
end

-- (its condition in the save: its grade and its marks as a number, mixed with its seed)
local function Code(g, m)
	return (g - 1) * 10000 + (m[1] - 1) * 1000 + (m[2] - 1) * 100 + (m[3] - 1) * 10 + (m[4] - 1)
end

local function Mix(seed)
	return CuratorOctoFull.Mod((floor(tonumber(seed) or 0) * 7919 + 4099) , 100000)
end

local function Valid(g, m)
	if not (g and g >= 1 and g <= 10 and type(m) == "table") then
		return false
	end
	for i = 1, 4 do
		if not (m[i] and m[i] >= 1 and m[i] <= 10) then
			return false
		end
	end
	return true
end

function W.Store(rec, g, m)
	rec.wq = CuratorOctoFull.Mod((Code(g, m) + Mix(rec.wv)) , 100000)
end

-- Its hidden condition (grade, marks), or nil.
function W.Hidden(rec)
	local q = type(rec) == "table" and tonumber(rec.wq)
	local seed = rec and tonumber(rec.wv)
	if not (q and seed) then
		return nil
	end
	local c = CuratorOctoFull.Mod((floor(q) - Mix(seed)) , 100000)
	local g = floor(c / 10000) + 1
	local m = { CuratorOctoFull.Mod(floor(c / 1000) , 10) + 1, CuratorOctoFull.Mod(floor(c / 100) , 10) + 1, CuratorOctoFull.Mod(floor(c / 10) , 10) + 1, CuratorOctoFull.Mod(c , 10) + 1 }
	if not Valid(g, m) then
		return nil
	end
	return g, m
end

-- A copy that comes now (Copies.lua: Fresh): its seed, its condition drawn, by a random of its own (the one of the game
-- left as it was: what else draws draws as before).
local freshN = 0
function W.Fresh(rec)
	freshN = freshN + 1
	local cid = ns.db and ns.db.cid
	local clock = (debugprofilestop and floor(debugprofilestop() * 1000)) or 0
	local rnd = W.Rng(Hash("fresh:" .. tostring(cid) .. ":" .. tostring(rec.i) .. ":" .. tostring(rec.t) .. ":" .. freshN .. ":" .. clock))
	for _ = 1, 3 do
		rnd()
	end
	rec.wv = floor(rnd() * 999998) + 1
	-- (1 November, his word: twenty levels as likely as each other)
	local level = W.Level(rnd())
	-- (31 October, Card Sleeves, a talent of the Archivist: a grade better now and then: two levels)
	local TL = ns.Talents
	if TL and TL.Sleeves and (TL:Sleeves(1) or 1) > 1 then
		level = math.min(W.LEVELS, level + 2)
	end
	local m = W.MarksOfLevel(level, rnd)
	W.Store(rec, W.Whole(m), m)
end

-- A copy of before (or one a trade brought without): its condition, once, the same each time (a game closed before
-- it saves gives it the same again): from its appraisal when it has one, else drawn from the collection, its card and
-- its number.
function W.Derive(key, rec)
	local cid = ns.db and ns.db.cid
	local str = "wear:" .. tostring(cid) .. ":" .. tostring(key) .. ":" .. tostring(rec.i)
	local rnd = W.Rng(Hash(str))
	rec.wv = floor(rnd() * 999998) + 1
	local g, m
	local E = ns.Expertise
	local shown = tonumber(rec.g)
	if shown and shown >= 100 and shown <= 1000 then
		g = math.max(1, math.min(10, floor(shown / 100 + 0.5)))
		m = E and E.DecodeMarks and E.DecodeMarks(rec.m) or nil
		if not Valid(g, m) then
			m = W.MarksFor(g, rnd)
		end
	else
		m = W.MarksOfLevel(W.Level(rnd()), rnd)
		g = W.Whole(m)
	end
	W.Store(rec, g, m)
end

-- (Copies.lua, Reconcile) Every copy its condition.
function W:Fill(key, list)
	for _, r in ipairs(list) do
		if type(r) == "table" and not W.Hidden(r) then
			W.Derive(key, r)
		end
	end
end

-- What a copy shows (nil: nothing known): { g, m, seed }. Restored at an enchanter: what the enchanters made of it (its
-- true grade, Restore.lua; its marks as the expert found them once appraised again); else the condition it came in (its
-- appraisal finds exactly that: a talent of the expert that judges it a little better changes nothing of it).
function W.Of(rec)
	if type(rec) ~= "table" then
		return nil
	end
	local seed = tonumber(rec.wv)
	local E = ns.Expertise
	local hg = tonumber(rec.hg)
	-- (31 October, the enchanter redone, Restore.lua: a copy mended flaw by flaw: its pieces laid as they were the first
	-- time (w0, its marks then), those he mended gone (wx), what went wrong at his bench (wa); its grade what is left of
	-- it, hidden until its next appraisal (hg))
	local w0 = rec.w0 and E and E.DecodeMarks and E.DecodeMarks(rec.w0) or nil
	if w0 and Valid(math.min(w0[1], w0[2], w0[3], w0[4]), w0) then
		local g = (hg and hg >= 100 and hg <= 1000) and math.max(1, math.min(10, floor(hg / 100 + 0.5))) or math.min(w0[1], w0[2], w0[3], w0[4])
		return { g = g, m = w0, seed = seed or Hash(tostring(rec.i)), x = type(rec.wx) == "string" and rec.wx or nil,
			a = type(rec.wa) == "string" and rec.wa or nil }
	end
	if type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0 and hg and hg >= 100 and hg <= 1000 then
		local g = math.max(1, math.min(10, floor(hg / 100 + 0.5)))
		local m = rec.sl ~= false and E and E.DecodeMarks and E.DecodeMarks(rec.m) or nil
		if not Valid(g, m) then
			m = W.MarksFor(g, W.Rng((seed or 1) + 77))
		end
		return { g = g, m = m, seed = seed or Hash(tostring(rec.i)) }
	end
	local g, m = W.Hidden(rec)
	if g then
		return { g = g, m = m, seed = seed }
	end
	local shown = tonumber(rec.g)
	if shown and shown >= 100 and shown <= 1000 then
		g = math.max(1, math.min(10, floor(shown / 100 + 0.5)))
		m = E and E.DecodeMarks and E.DecodeMarks(rec.m) or nil
		if Valid(g, m) then
			return { g = g, m = m, seed = seed or Hash(tostring(rec.i)) }
		end
	end
	return nil
end

-- (31 October) The true condition of a copy as the expert would find it now: its grade, its four marks (restored flaw
-- by flaw: what is left of its wear; restored before: its true grade; else the condition it came in; else what its
-- appraisal said); nil: nothing known.
function W.True(rec)
	if type(rec) ~= "table" then
		return nil
	end
	local E = ns.Expertise
	local hg = tonumber(rec.hg)
	if hg and hg >= 100 and hg <= 1000 then
		local m = rec.hm and E and E.DecodeMarks and E.DecodeMarks(rec.hm)
		if not m then
			local g = math.max(1, math.min(10, floor(hg / 100 + 0.5)))
			m = W.MarksFor(g, W.Rng((tonumber(rec.wv) or 1) + 77))
		end
		return hg / 100, m
	end
	local g, m = W.Hidden(rec)
	if g then
		return g, m
	end
	local shown = tonumber(rec.g)
	if shown and shown >= 100 and shown <= 1000 then
		local gg = math.max(1, math.min(10, floor(shown / 100 + 0.5)))
		m = E and E.DecodeMarks and E.DecodeMarks(rec.m)
		if not Valid(gg, m) then
			m = W.MarksFor(gg, W.Rng((tonumber(rec.wv) or 1) + 77))
		end
		return shown / 100, m
	end
	return nil
end

-- (31 October, the contracts redone: Contract.lua) The condition of what comes of copies given: their marks averaged,
-- each to its whole; its grade their mean (a 10: all four 10). nil: none known.
function W.Average(list)
	local sum, n = { 0, 0, 0, 0 }, 0
	for _, rec in ipairs(list or {}) do
		local _, m = W.True(rec)
		if m then
			n = n + 1
			for i = 1, 4 do
				sum[i] = sum[i] + m[i]
			end
		end
	end
	if n == 0 then
		return nil
	end
	local m = {}
	for i = 1, 4 do
		m[i] = math.max(1, math.min(10, floor(sum[i] / n + 0.5)))
	end
	local g = floor((m[1] + m[2] + m[3] + m[4]) / 4 + 0.5)
	if g >= 10 and not (m[1] == 10 and m[2] == 10 and m[3] == 10 and m[4] == 10) then
		g = 9
	end
	return math.max(1, math.min(10, g)), m
end

-- What the copy a card shows first shows (the album, a page of the collection; the copy shown big first, UI/Copies.lua).
function W:Shown(card, finish)
	if not card then
		return nil
	end
	local CU, CP = ns.CopiesUI, ns.Copies
	local rec
	if CU and CU.Default then
		local ok, r = pcall(CU.Default, CU, card, finish)
		rec = ok and r or nil
	end
	if not rec and CP then
		rec = CP:List(card.key)[1]
	end
	return W.Of(rec)
end

-- A copy by its number.
function W:ById(key, id)
	local CP = ns.Copies
	return id and CP and W.Of(CP:Get(key, id)) or nil
end

-- (for the author's tests: /curator test usure; a booster seen before, Collection.lua) A condition of that grade (nil:
-- drawn), from that seed.
function W.Test(g, seed)
	local rnd = W.Rng(seed)
	if not g then
		local m = W.MarksOfLevel(W.Level(rnd()), rnd)
		return { g = W.Whole(m), m = m, seed = floor(rnd() * 999998) + 1 }
	end
	return { g = g, m = W.MarksFor(g, rnd), seed = floor(rnd() * 999998) + 1 }
end
