local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.11.0) The expertise of the cards: at a banker (his window open), a card of the collection is appraised
-- once, for good, for rubies (Rubies.lua), by its rarity. The expert looks at four things, each graded from 1
-- to 10 (its centering, its corners, its edges, its surface), and gives the card its grade, from 1 (damaged)
-- to 10 (flawless), a 10 rarely. The card is sealed in its case (UI/Expertise.lua, UI/Card.lua: the slab),
-- its label printed: its name, its album, its number, its grade and its four marks, the number of its
-- certificate. Once appraised, a card is not appraised again: its grade is kept even while no copy of it is
-- in the collection (it shows again when one comes back). It shows on the card in the album (its medal), in
-- its case when it is shown big, in its tooltip, and to the other players with the showcase (Comm.lua).
-- What is kept: db.graded ([card key] = { g = the grade, s = its four marks ("9A9A": A for 10), c = its
-- certificate, t = when, f = the finish it had }), sealed with the save; the counters of the achievements
-- (ns.Stats: appraised, grade10).
-- (1.13.0) Each copy is appraised on its own, the duplicates too (Copies.lua: its grade x100, its marks, its
-- certificate, when, in its case): the card shows its finest copy appraised. A copy restored at an enchanter
-- (Restore.lua) leaves its case: its new grade (one decimal since the first test of 1.13.0, never past 10) is known
-- at its next appraisal, paid
-- again. An appraisal goes with its copy (a trade gives it with the copy); those of before 1.13.0 went on one of the
-- copies of their card, once (db.graded then goes). The counters: appraised and grade10 (the first appraisals: a 10 of
-- nature), reappraised and restored10 (after a restoration).
-------------------------------------------------------------------------------
local E = {}
ns.Expertise = E
local CertFor

-- the price of an appraisal, by rarity (common to mythic)
-- (1.13.0: twice as dear, the sale of the copies to the reseller has no limit now: 30, 50, 90, 160, 280, 450 before;
-- after its second test, the economy redone, about eight times as dear: 60, 100, 180, 320, 560, 900 before)
E.PRICE = { 500, 800, 1500, 2500, 4500, 7500 }
-- the chance of each grade (the best first)
-- (1 November, his word: the whole grades of the twenty levels of Wear.lua, by their bands: Wear.lua, loaded after this
-- file, puts its own here, W.ODDS; these until then: the cards of the cases draw theirs by them, Cases.lua)
E.ODDS = { { 10, 0.033333 }, { 9, 0.241667 }, { 8, 0.35 }, { 7, 0.190385 }, { 6, 0.030769 }, { 5, 0.030769 }, { 4, 0.030769 },
	{ 3, 0.046154 }, { 2, 0.030769 }, { 1, 0.015385 } }
E.MAX = 10
-- the word of each grade
E.WORDS = {
	[10] = "Flawless", [9] = "Mint", [8] = "Near Mint", [7] = "Excellent", [6] = "Very Good",
	[5] = "Good", [4] = "Fair", [3] = "Worn", [2] = "Poor", [1] = "Damaged",
}
-- the four things the expert looks at, in his order
E.MARKS = { "Centering", "Corners", "Edges", "Surface" }
-- what the expert says of the card, by its grade
E.SAYS = {
	[10] = "Not a scratch, not a speck. I have seen thousands of cards: this one is perfect.",
	[9] = "A breath away from perfection. A collector's piece.",
	[8] = "Very clean. A tiny mark on a corner, and that is all.",
	[7] = "A fine card. It has been handled, but with care.",
	[6] = "A good card. Its edges have lived a little.",
	[5] = "An honest card. It has been played with.",
	[4] = "Worn at the corners. It has stories to tell.",
	[3] = "Creased and scuffed. It has seen a tavern or two.",
	[2] = "Battered, but it holds together.",
	[1] = "Damaged. I grade it all the same: every card has its place.",
}
-- the colour of each grade: the gold of a 10, the silver of a 9, the bronze of 7 and 8, the iron below
E.COLORS = {
	[10] = { 1, 0.82, 0.3 }, [9] = { 0.86, 0.9, 1 }, [8] = { 0.95, 0.66, 0.4 }, [7] = { 0.88, 0.6, 0.38 },
}
E.IRON = { 0.66, 0.66, 0.7 }

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-- (before 1.13.0) The appraisals of a save not made over to its copies yet (Copies.lua: once, at the login).
function E:Db()
	local db = ns.db
	return db and type(db.graded) == "table" and db.graded or nil
end

-- (1.13.0) A grade as a number: whole (an appraisal), or with one decimal (a restoration, Restore.lua), from 1 to 10.
function E.Int(g)
	return g and math.floor(g + 1e-6) or nil
end

-- A copy's grade (its record x100: Copies.lua), as a number (nil: not appraised).
local function Of(rec)
	local g = ns.Copies and ns.Copies.Grade(rec)
	return g and g / 100 or nil
end
E.Of = Of

-- The copy shown of a card (id: that copy; nil: its finest appraised, Copies.lua), and its record.
local function CopyOf(card, id)
	local CP = ns.Copies
	if not (card and CP) then
		return nil
	end
	if id ~= nil then
		return CP:Get(card.key, id)
	end
	return CP:Featured(card.key)
end

-- The record of a card appraised, as before 1.13.0 ({ g = its grade, s = its marks, c = its certificate, t = when, f =
-- the finish of the copy, i = its number, sl = in its case }, and its grade; nil: not appraised): the copy id, or its
-- finest copy appraised in its case. Only the copies of the collection: an appraisal whose copy is gone goes with it.
function E:Record(card, id)
	local rec = CopyOf(card, id)
	local g = Of(rec)
	if not g then
		return nil
	end
	return { g = g, s = rec.m, c = rec.ce, t = rec.at, f = ns.Copies.Finish(rec), i = rec.i, sl = rec.sl ~= false, rec = rec }, g
end

-- The grade of a card of the collection (nil: none of its copies appraised): its finest copy, or the copy id.
function E:Grade(card, id)
	local _, g = self:Record(card, id)
	return g
end

-- Appraised: a copy of the card (id: that copy), its grade known.
function E:Appraised(card, id)
	return self:Record(card, id) ~= nil
end

-- A grade sent by another player (a number from 1 to 10, whole), or nil. (The marks: whole too.)
function E.Valid(v)
	local n = tonumber(v)
	if n and n >= 1 and n <= E.MAX and n == math.floor(n) then
		return n
	end
	return nil
end

-- (1.13.0) A grade of a copy restored too (one decimal at most: after the first test of 1.13.0, 6,5 rather than 6,47;
-- a grade of two decimals, sent by an older test build, rounded), or nil.
function E.ValidGrade(v)
	local n = tonumber(v)
	if not (n and n >= 1 and n <= E.MAX) then
		return nil
	end
	return math.floor(n * 10 + 0.5 + 1e-9) / 10
end

-- (1.13.0) "7", "7,5": a grade as the language writes it.
function E.Text(g)
	g = E.ValidGrade(g)
	if not g then
		return ""
	end
	if g == math.floor(g) then
		return tostring(math.floor(g))
	end
	local s = string.format(("%.1f"), g)
	return (string.gsub(s, "%.", ns.L["."]))
end

-- Four marks written as four letters ("9A9A": A for 10), and back.
function E.EncodeMarks(m)
	if type(m) ~= "table" or CuratorOctoFull.Length(m) ~= 4 then
		return nil
	end
	local out = {}
	for i = 1, 4 do
		local v = E.Valid(m[i])
		if not v then
			return nil
		end
		out[i] = v == 10 and "A" or tostring(v)
	end
	return table.concat(out)
end

function E.DecodeMarks(s)
	if type(s) ~= "string" or not CuratorOctoFull.Match(s, "^[1-9A][1-9A][1-9A][1-9A]$") then
		return nil
	end
	local out = {}
	for i = 1, 4 do
		local c = string.sub(s, i, i)
		out[i] = c == "A" and 10 or tonumber(c)
	end
	return out
end

-- The four marks of a card appraised (nil: none kept), and the number of its certificate (id: that copy; nil: its
-- finest).
function E:Marks(card, id)
	local x = self:Record(card, id)
	return x and E.DecodeMarks(x.s) or nil
end

function E:Cert(card, id)
	local x = self:Record(card, id)
	return x and tonumber(x.c) or nil
end

-- "0042 8817": a number of certificate as the label prints it.
function E.CertText(c)
	c = CuratorOctoFull.Mod(math.floor(tonumber(c) or 0) , 100000000)
	local s = string.format(("%08d"), c)
	return string.sub(s, 1, 4) .. " " .. string.sub(s, 5, 8)
end

function E.Word(g)
	g = E.Int(tonumber(g))
	return g and E.WORDS[g] and L[E.WORDS[g]] or ""
end

-- A word in capitals, as a label prints it: the accented letters of the Latin alphabets and the Cyrillic
-- ones too (string.upper changes only the letters without accents).
function E.Upper(s)
	s = string.upper(tostring(s or ""))
	s = string.gsub(s, "\195([\160-\190])", function(b)
		return "\195" .. (b == "\183" and b or string.char(CuratorOctoFull.Byte(b) - 32))
	end)
	s = string.gsub(s, "\208([\176-\191])", function(b)
		return "\208" .. string.char(CuratorOctoFull.Byte(b) - 32)
	end)
	s = string.gsub(s, "\209([\128-\143])", function(b)
		return "\208" .. string.char(CuratorOctoFull.Byte(b) + 32)
	end)
	s = string.gsub(s, "\209\145", "\208\129")
	return s
end

-- "Centering 9 · Corners 10 · Edges 9 · Surface 9".
function E.MarksText(m)
	if type(m) ~= "table" or CuratorOctoFull.Length(m) ~= 4 then
		return ""
	end
	local out = {}
	for i, key in ipairs(E.MARKS) do
		out[i] = string.format(("%s %d"), L[key], m[i])
	end
	return table.concat(out, "  ·  ")
end

function E.Says(g)
	g = E.Int(tonumber(g))
	return g and E.SAYS[g] and L[E.SAYS[g]] or ""
end

function E.Color(g)
	g = E.Int(tonumber(g))
	return (g and E.COLORS[g]) or E.IRON
end

-- "9 · Mint", in the colour of the grade (1.13.0: "8,35 · Near Mint", a copy restored).
function E.Label(g)
	if not E.ValidGrade(g) then
		return ""
	end
	local c = E.Color(g)
	return string.format(("|cff%02x%02x%02x%s · %s|r"), math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), E.Text(g), E.Word(g))
end

-- The price of an appraisal of a card (its rarity; the talents can lower it: Rubies.lua, RB:Price).
function E:BasePrice(card)
	return card and self.PRICE[card.rarity or 1] or self.PRICE[1]
end

function E:Price(card)
	local base = self:BasePrice(card)
	local price = ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "expertise") or base
	-- (1.14.0, Favored Client, a talent of the Archivist: once a day, half its price)
	if self:Favored() then
		price = math.max(1, math.ceil(price / 2))
	end
	return price
end

-- (1.14.0) The appraisal of the day at half its price (Favored Client) is still to come.
function E:Favored()
	local TL = ns.Talents
	return TL ~= nil and TL.Ready ~= nil and TL:Ready("favored")
end

-- The cheapest appraisal (what the rubies buy, in a word).
function E:From()
	return self:Price({ rarity = 1 })
end

-------------------------------------------------------------------------------
-- At a banker
-------------------------------------------------------------------------------
function E:AtBank()
	return self.atBank == true
end

function E:SetBank(open)
	open = open and true or false
	if self.atBank == open then
		return
	end
	self.atBank = open
	ns.Fire("BANK_CHANGED", open)
end

-- (1.13.0) The copy of a card appraised when none is chosen: one never appraised (or its case opened, Restore.lua), not
-- corrupted, not at an enchanter: its finest finish first, then the oldest. Its number, or nil.
function E:Next(card)
	local CP = ns.Copies
	local best, bs
	local SCORE = { h = 3, s = 2 }
	for _, r in ipairs(card and CP and CP:List(card.key) or {}) do
		if r.f ~= "c" and not CP.Away(r) and (not CP.Grade(r) or r.sl == false) then
			-- (1 November: a titanforged copy waiting for its certificate, Mages.lua: the last one)
			local waits = ns.Mages and ns.Mages.Needs(r)
			local sc = (waits and 0 or (SCORE[r.f or ""] or 1)) * 1e9 - (r.i or 0)
			if not best or sc > bs then
				best, bs = r, sc
			end
		end
	end
	return best and best.i or nil
end

-- Whether a copy of a card can be appraised now (id: its number; nil: E:Next): true, or false and why ("closed",
-- "card": not one of the collection (that copy), "done": appraised already, in its case, "corrupt": a corrupted copy
-- (1.12.0: never appraised, a Master of Warlocks seals it: Seal.lua), "away": at an enchanter (Restore.lua), "bank":
-- not at a banker, "rubies"). (1.13.0: each copy is appraised on its own; a copy restored, its case opened, is
-- appraised again: its new grade.) (1 November, his word: "cert", a titanforged copy without its certificate of a
-- master of the mages, Mages.lua: « le certificat est obligatoire ».)
function E:CanAppraise(card, id)
	if Closed() then
		return false, "closed"
	end
	if not (card and ns.Collection:Owned(card)) then
		return false, "card"
	end
	local CP = ns.Copies
	local rec
	if id ~= nil then
		rec = CP and CP:Get(card.key, id)
		if not rec then
			return false, "card"
		end
	else
		local nid = self:Next(card)
		rec = nid and CP:Get(card.key, nid)
		if not rec then
			-- (every copy appraised already, or corrupted, or away)
			for _, r in ipairs(CP and CP:List(card.key) or {}) do
				if r.f ~= "c" and not CP.Away(r) then
					return false, "done"
				end
			end
			for _, r in ipairs(CP and CP:List(card.key) or {}) do
				if CP.Away(r) then
					return false, "away"
				end
			end
			return false, "corrupt"
		end
	end
	if rec.f == "c" or rec.ws then
		return false, "corrupt"
	end
	if CP.Away(rec) then
		return false, "away"
	end
	if CP.Grade(rec) and rec.sl ~= false then
		return false, "done"
	end
	if ns.Mages and ns.Mages.Needs(rec) then
		return false, "cert"
	end
	if not self:AtBank() then
		return false, "bank"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:Price(card))) then
		return false, "rubies"
	end
	return true
end

-- The weights of the grades (the talents can make a 10 likelier: Talents.lua, TL:GradeOdds).
function E:Odds()
	local TL = ns.Talents
	local k10 = (TL and TL.GradeLuck) and TL:GradeLuck() or 0
	if k10 <= 0 then
		return self.ODDS
	end
	local out, total = {}, 0
	for i, o in ipairs(self.ODDS) do
		local w = o[2] * (o[1] == self.MAX and (1 + k10) or 1)
		out[i] = { o[1], w }
		total = total + w
	end
	for _, o in ipairs(out) do
		o[2] = o[2] / total
	end
	return out
end

-- A grade drawn by the expert (roll: a number from 0 to 1, drawn when it is not given).
function E:Draw(roll)
	local x = roll or math.random()
	local odds = self:Odds()
	for _, o in ipairs(odds) do
		x = x - o[2]
		if x < 0 then
			return o[1]
		end
	end
	return odds[CuratorOctoFull.Length(odds)][1]
end

-- The grade of an appraisal: one draw, or the best of several (1.14.0: Grand Conservator, once a week), and
-- Perfectionist (a 9 that becomes a 10 now and then); and whether more than one draw was made.
function E:DrawGrade()
	local TL = ns.Talents
	local n = 1 + ((TL and TL.GradeDraws) and TL:GradeDraws() or 0)
	local best = 0
	for _ = 1, n do
		best = math.max(best, self:Draw())
	end
	if TL and TL.GradeAfter then
		best = TL:GradeAfter(best)
	end
	return best, n > 1
end

-- (1.14.0, Steady Hand, a talent of the Archivist) The four marks of an appraisal, one of them raised a point now and
-- then: the grade the mean of the marks then rounds to (never lower than the one drawn).
function E:Steady(grade, marks)
	local TL = ns.Talents
	if not (TL and TL.Has and TL:Has("steady")) or math.random() >= TL:V("steady") then
		return grade, marks, false
	end
	local low
	for i, v in ipairs(marks) do
		if v < self.MAX and (not low or v < marks[low]) then
			low = i
		end
	end
	if not low then
		return grade, marks, false
	end
	marks[low] = marks[low] + 1
	local sum = 0
	for _, v in ipairs(marks) do
		sum = sum + v
	end
	return math.max(grade, math.floor(sum / 4 + 0.5)), marks, true
end

-- (1.14.0, Glance, a talent of the Archivist) The grade a copy would get, seen before it is appraised (and its marks,
-- with Certified Expert), the talent used: kept on the copy (rec.pk: the grade x100; rec.pm: its marks), its
-- appraisal gives exactly that. A copy restored, with Certified Expert at its second rank: its true grade told, and
-- the copy back in its case without paying its appraisal again. What was seen: { grade, marks, resealed }, or nil
-- and why ("ready", "card", "done", "corrupt", "away").
function E:Glance(card, id)
	local TL = ns.Talents
	if not (TL and TL:Ready("glance")) then
		return nil, "ready"
	end
	local CP = ns.Copies
	id = id or self:Next(card)
	local rec = card and id and CP and CP:Get(card.key, id)
	if not rec then
		return nil, "card"
	end
	if rec.f == "c" or rec.ws then
		return nil, "corrupt"
	end
	if CP.Away(rec) then
		return nil, "away"
	end
	if CP.Grade(rec) and rec.sl ~= false then
		return nil, "done"
	end
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return nil, "guard"
	end
	TL:Use("glance")
	local seeMarks = TL:Rank("glance3") >= 1
	-- (a copy restored: what the enchanters made of it)
	local hg = tonumber(rec.hg)
	if hg and hg >= 100 and hg <= 1000 and rec.sl == false then
		local grade = math.floor(hg / 10 + 0.5) / 10
		if TL:Rank("glance3") >= 2 then
			-- (its case closed again, its grade printed: no appraisal paid; 31 October, the review of the night: its marks
			-- what the enchanter left of its wear, as an appraisal would print them, its true grade the one printed)
			local marks = (rec.hm and E.DecodeMarks(rec.hm)) or self:MarksFor(math.floor(grade + 0.5))
			rec.g, rec.m, rec.ce, rec.at, rec.sl = math.floor(hg / 10 + 0.5) * 10, E.EncodeMarks(marks), CertFor(card), CuratorOctoFull.ServerTime(), true
			rec.hg, rec.hm = rec.g, rec.hm and rec.m or nil
			ns.Fire("COPIES_CHANGED", card)
			ns.Fire("CHANGED")
			return { grade = grade, marks = marks, resealed = true, id = rec.i }
		end
		return { grade = grade, id = rec.i }
	end
	if tonumber(rec.pk) then
		return { grade = rec.pk / 100, marks = seeMarks and E.DecodeMarks(rec.pm) or nil, id = rec.i }
	end
	-- (his idea, 31 October: the condition it came in, Wear.lua: what the glance sees)
	local hg0, hm0
	if ns.Wear then
		hg0, hm0 = ns.Wear.Hidden(rec)
	end
	if hg0 then
		-- (1 November, the twenty levels: the mean of its marks, to its tenth)
		local gx = (ns.Wear and ns.Wear.Exact) and ns.Wear.Exact(hm0) or hg0
		rec.pk, rec.pm = math.floor(gx * 100 + 0.5), E.EncodeMarks(hm0)
		ns.Fire("COPIES_CHANGED", card)
		return { grade = gx, marks = seeMarks and hm0 or nil, id = rec.i }
	end
	local g, many = self:DrawGrade()
	local marks = self:MarksFor(g)
	g, marks = self:Steady(g, marks)
	rec.pk, rec.pm = g * 100, E.EncodeMarks(marks)
	rec.pc = many or nil
	-- (Grand Conservator: its two draws made now, for this copy: used now, never twice in a week)
	if many and TL:Ready("conservator") then
		TL:Use("conservator")
	end
	ns.Fire("COPIES_CHANGED", card)
	return { grade = g, marks = seeMarks and marks or nil, id = rec.i }
end

-- Four marks for a grade: a 10 is perfect in everything; below, each mark a step around the grade, their
-- mean rounding to the grade, none more than a step under it.
function E:MarksFor(g)
	g = math.max(1, math.min(self.MAX, g))
	if g == self.MAX then
		return { 10, 10, 10, 10 }
	end
	for _ = 1, 40 do
		local m, sum, low = {}, 0, 99
		for i = 1, 4 do
			local r = math.random()
			local v = g
			if r < 0.3 then
				v = g + 1
			elseif r < 0.48 then
				v = g - 1
			end
			v = math.max(1, math.min(self.MAX, v))
			m[i], sum, low = v, sum + v, math.min(low, v)
		end
		if math.floor(sum / 4 + 0.5) == g and low >= g - 1 then
			return m
		end
	end
	return { g, g, g, g }
end

-- A number of certificate for a card (its key and the moment: eight digits).
function CertFor(card)
	local h = 7
	local s = (card.key or "") .. ":" .. tostring(CuratorOctoFull.ServerTime())
	for i = 1, CuratorOctoFull.Length(s) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(s, i)) , 99999989)
	end
	return CuratorOctoFull.Mod((h + math.random(0, 9999)) , 100000000)
end
-- (31 October: a certificate of its own, for a card a contract gives appraised, Contract.lua)
E.CertFor = function(card)
	return CertFor(card)
end

-- A copy of a card appraised (id: its number; nil: E:Next): its rubies paid, its grade and its four marks drawn, its
-- certificate. (1.13.0) A copy restored, its case opened (Restore.lua): appraised again, its new grade known now (what
-- the enchanters made of it), its marks and its certificate new. What it did: { card, grade, marks, cert, price, id,
-- again (appraised before: before, its grade then), restored (its restorations) } (nil and why, as CanAppraise).
function E:Appraise(card, id)
	local ok, why = self:CanAppraise(card, id)
	if not ok then
		return nil, why
	end
	local CP = ns.Copies
	id = id or self:Next(card)
	local rec = CP:Get(card.key, id)
	local price = self:Price(card)
	local paid, err = ns.Rubies:Spend(price, "expertise")
	if not paid then
		return nil, err
	end
	local TL = ns.Talents
	-- (1.14.0, Favored Client: the half price of the day, used)
	if self:Favored() then
		TL:Use("favored")
	end
	local before = CP.Grade(rec)
	local again = before ~= nil
	-- (the grade: drawn at its first appraisal; after, what its restorations made of it, x100; 1.14.0: the grade seen
	-- with Glance, as it was seen, its marks with it)
	local g100 = tonumber(rec.hg)
	local marks, conserv
	-- (31 October, the enchanter redone: a copy mended flaw by flaw, its true marks what is left of its wear)
	if g100 and g100 >= 100 and g100 <= 1000 and rec.hm then
		marks = E.DecodeMarks(rec.hm)
	end
	if not (g100 and g100 >= 100 and g100 <= 1000) then
		if before then
			g100 = before
		elseif tonumber(rec.pk) then
			g100 = tonumber(rec.pk)
			marks = E.DecodeMarks(rec.pm)
			conserv = rec.pc
		else
			-- (his idea, 31 October: the condition the copy came in, its wear on it, Wear.lua: the expert finds exactly
			-- that; Steady Hand a mark better now and then, Perfectionist a 9 a 10, Grand Conservator a grade better
			-- now and then: his eye at his best, its wear the same)
			local hg0, hm0
			if ns.Wear then
				hg0, hm0 = ns.Wear.Hidden(rec)
			end
			if hg0 then
				local g, m = hg0, { hm0[1], hm0[2], hm0[3], hm0[4] }
				local TL2 = ns.Talents
				if TL2 and TL2.GradeAfter then
					local g2 = TL2:GradeAfter(g)
					if g2 > g then
						g, m = g2, { 10, 10, 10, 10 }
					end
				end
				local many = TL2 and TL2.GradeDraws and TL2:GradeDraws() > 0
				if many and g < self.MAX and math.random() < 0.35 then
					g = g + 1
					for i = 1, 4 do
						m[i] = math.max(m[i], g)
					end
				end
				g, m = self:Steady(g, m)
				-- (1 November, the twenty levels: its grade the mean of its four marks, to its tenth, Wear.lua)
				local W = ns.Wear
				g100, marks, conserv = ((W and W.Exact) and W.Exact(m) or g) * 100, m, many
			else
				local g, many = self:DrawGrade()
				local m
				g, m = self:Steady(g, self:MarksFor(g))
				g100, marks, conserv = g * 100, m, many
			end
		end
	end
	rec.pk, rec.pm, rec.pc = nil, nil, nil
	-- (1.14.0, Grand Conservator: its appraisal of the week, used)
	if conserv and TL and TL.Ready and TL:Ready("conservator") then
		TL:Use("conservator")
	end
	-- (one decimal: a tenth, x100)
	g100 = math.max(100, math.min(1000, math.floor(g100 / 10 + 0.5) * 10))
	local grade = g100 / 100
	marks = marks or self:MarksFor(math.floor(grade + 0.5))
	local cert = CertFor(card)
	rec.g, rec.hg, rec.m, rec.ce, rec.at, rec.sl = g100, g100, E.EncodeMarks(marks), cert, CuratorOctoFull.ServerTime(), true
	local restored = type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) or 0
	local st = ns.Stats()
	if again then
		st.reappraised = (tonumber(st.reappraised) or 0) + 1
		if grade >= self.MAX then
			st.restored10 = (tonumber(st.restored10) or 0) + 1
		end
	else
		st.appraised = (tonumber(st.appraised) or 0) + 1
		-- (a copy restored before its first appraisal: its 10 is not of nature)
		if grade >= self.MAX and restored > 0 then
			st.restored10 = (tonumber(st.restored10) or 0) + 1
		elseif grade >= self.MAX then
			st.grade10 = (tonumber(st.grade10) or 0) + 1
		end
	end
	local res = { card = card, grade = grade, marks = marks, cert = cert, price = price, id = rec.i, again = again or nil,
		before = before and before / 100 or nil, restored = restored > 0 and restored or nil, conservator = conserv or nil }
	ns.Fire("COPIES_CHANGED", card)
	ns.Fire("CARD_APPRAISED", res)
	ns.Fire("CHANGED")
	-- (a card of the showcase, pinned or among the finest: its case there)
	for _, v in ipairs(ns.Collection:Showcase()) do
		if v.card == card then
			ns.Fire("SHOWCASE_CHANGED")
			break
		end
	end
	return res
end

-- What the label of a card appraised prints (nil: never appraised): its grade, its word, its marks, its
-- certificate. Mine: as it was appraised (id: that copy; nil: its finest); another player's card: the grade, the marks
-- and the certificate that came with their showcase (none of mine). (1.13.0) A copy restored: its restorations, their
-- dates (restored = { time, ... }).
function E:LabelOf(card, grade, marks, cert, id, extra)
	if not card then
		return nil
	end
	local restored
	-- (1.14.0, the Archivist: Signature, the name of the collector on the label; Luxury Case, a golden case for a 9 or a
	-- 10. Mine: as my talents are; another player's: as their showcase tells, extra = { by, lux })
	local by, lux
	if type(extra) == "table" then
		by, lux = extra.by, extra.lux
	end
	local mine = grade == nil
	local titan = type(extra) == "table" and type(extra.titan) == "table" and extra.titan or nil
	if grade == nil then
		local x, n = self:Record(card, id)
		if not x then
			return nil
		end
		grade, marks, cert = n, E.DecodeMarks(x.s), tonumber(x.c)
		titan = ns.Mages and ns.Mages.Label(x.rec) or nil
		local r = x.rec and x.rec.r
		if type(r) == "table" and CuratorOctoFull.Length(r) > 0 then
			restored = {}
			for i, v in ipairs(r) do
				restored[i] = type(v) == "table" and tonumber(v[1]) or 0
			end
		end
	end
	grade = E.ValidGrade(grade)
	if not grade then
		return nil
	end
	if mine then
		local TL = ns.Talents
		if TL and TL:Has("signature") then
			by = UnitName and UnitName("player") or nil
		end
		lux = TL ~= nil and TL:Has("luxury") and grade >= 9
	end
	local C = ns.Collection
	return {
		by = (type(by) == "string" and by ~= "") and string.sub(by, 1, 24) or nil,
		lux = lux and true or nil,
		grade = grade,
		text = E.Text(grade),
		word = E.Word(grade),
		name = C:Name(card),
		album = C:SeriesName(card.series),
		num = string.format(("#%d/%d"), card.num or 0, CuratorOctoFull.Length((card.series and card.series.list or {}))),
		rarity = card.rarity,
		marks = type(marks) == "table" and CuratorOctoFull.Length(marks) == 4 and marks or nil,
		cert = tonumber(cert),
		color = E.Color(grade),
		restored = restored,
		-- (1 November: a titanforged copy certified by a master of the mages, Mages.lua: its family and its number)
		titan = titan,
	}
end

-- (the appraisals of the first days of 1.11.0, a best grade without marks: kept, given their marks and
-- their certificate; anything else in their place goes; 1.13.0: those of a save of before, until they go on its
-- copies, Copies.lua)
function E:Mend()
	local g = self:Db()
	if not g or self.mended == g then
		return
	end
	self.mended = g
	for key, x in pairs(g) do
		if type(x) == "number" then
			x = { g = x }
			g[key] = x
		end
		local n = type(x) == "table" and math.floor(tonumber(x.g) or 0) or 0
		if n >= 1 and n <= self.MAX and type(key) == "string" then
			x.g = n
			if not E.DecodeMarks(x.s) then
				x.s = E.EncodeMarks(self:MarksFor(n))
			end
			if not tonumber(x.c) then
				x.c = CertFor({ key = key })
			end
			x.n = nil
		else
			g[key] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event, kind)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
			pcall(self.RegisterEvent, self, e)
		end
		E:Mend()
	elseif event == "BANKFRAME_OPENED" then
		E:SetBank(true)
	elseif event == "BANKFRAME_CLOSED" then
		E:SetBank(false)
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
		-- (the newer clients: the banker among the interactions)
		local banker = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
		if banker and kind == banker then
			E:SetBank(event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
		end
	end
end)

-- (Core.lua: the collection emptied) the grades go with the cards: a new collection, new appraisals (1.13.0: on the
-- copies, they go with them: Copies.lua).
ns.On("COLLECTION_EMPTIED", function(db)
	if type(db) == "table" then
		db.graded = nil
	end
end)
