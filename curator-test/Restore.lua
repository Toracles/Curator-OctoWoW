local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.13.0) The restoration of the copies, at the enchanters (the trainers of enchanting: Data/Enchanters.lua; one that
-- Curator does not know, by his title). A copy of the collection (not a corrupted one, nor one sealed by a warlock) is
-- left with an enchanter; he works in real time, the game closed too, and the copy is picked up at any enchanter. (31
-- October, his word: redone) He mends the flaws one sees on it, of the kinds chosen, each by its odds; its grade follows
-- what is left of its wear, told at its next appraisal at a banker, paid again (Expertise.lua: its true grade, rec.hg,
-- its true marks, rec.hm): the case of an appraised copy is opened when it is left there. Each restoration stays on the
-- copy (rec.r: when, how big a job (1 to 4), how much x100) and on its label (restored N times, the dates).
-- What is kept, on the copy (Copies.lua): see R.TREAT; the counters (ns.Stats: restoreGiven, restoreDone, flawsMended,
-- mishaps, flawless).
-------------------------------------------------------------------------------
local R = {}
ns.Restore = R

-- the price by rarity (common to mythic): the price of a flaw, times this
R.MULT = { 1, 3, 6, 10, 15, 21 }

-- what the enchanter says: when the copy is left with him, when it is picked up, when it is not ready yet
R.SAY_GIVE = {
	"Leave it with me. I will bring its colours back.",
	"A fine card. A few runes, a little patience, and it will shine again.",
	"Arcane dust and a steady hand: come back when it is time.",
}
R.SAY_BACK = {
	"I worked hard on it!",
	"Here it is, as fine as I could make it.",
	"Done! Have an expert look at it: you will see.",
	"Mind it: the enchantment is still fresh.",
}
R.SAY_WAIT = "Not yet: the runes are still at work."
R.SAY_ASK = "Show me the card you want restored."

local function Now()
	return GetServerTime and CuratorOctoFull.ServerTime() or time()
end

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Int(v)
	return math.floor(tonumber(v) or 0)
end

-------------------------------------------------------------------------------
-- The enchanters
-------------------------------------------------------------------------------
-- The title of a unit in its tooltip (the line under its name). The tooltip that reads it, made the first time only
-- (a client without its template: no title, nothing else changes).
local tip
local function Title(unit)
	if not (CreateFrame and UnitExists) then
		return nil
	end
	local okU, exists = pcall(UnitExists, unit)
	if not (okU and exists) then
		return nil
	end
	if tip == nil then
		local ok, f = pcall(CreateFrame, "GameTooltip", "CuratorRestoreTip", nil, "GameTooltipTemplate")
		tip = (ok and f) or false
	end
	if not tip then
		return nil
	end
	local ok = pcall(tip.SetOwner, tip, WorldFrame or UIParent, "ANCHOR_NONE") and pcall(tip.SetUnit, tip, unit)
	if not ok then
		return nil
	end
	local fs = _G["CuratorRestoreTipTextLeft2"]
	local okT, text = pcall(function()
		return fs and fs:GetText() or nil
	end)
	pcall(tip.Hide, tip)
	if not okT or type(text) ~= "string" or Secret(text) then
		return nil
	end
	return text
end
R.Title = Title

-- An enchanter (npc: his id; unit: the unit to read his title from, "npc" when none is given). Never an error: any NPC
-- the window of dialogue asks about (UI/Gossip.lua) gets an answer.
function R:IsEnchanter(npc, unit)
	if type(npc) == "number" and ns.ENCHANTERS and ns.ENCHANTERS[npc] then
		return true
	end
	local titles = ns.ENCHANTER_TITLES
	local okT, title = pcall(R.Title, unit or "npc")
	if not (titles and okT and type(title) == "string") then
		return false
	end
	title = string.gsub(string.gsub(string.gsub(title, "\194\160", " "), "^<", ""), ">$", "")
	local loc = (GetLocale and GetLocale()) or "enUS"
	for _, list in ipairs({ titles[loc] or {}, titles.enUS or {} }) do
		for _, t in ipairs(list) do
			if title == t then
				return true
			end
		end
	end
	return false
end

-- The enchanter talked to now (his name), or none.
function R:SetEnchanter(on, name, npc)
	on = on and true or false
	if not on then
		name, npc = nil, nil
	end
	if self.here == on and self.name == name then
		return
	end
	self.here, self.name, self.npc = on, name, npc
	ns.Fire("ENCHANTER_CHANGED", on)
end

function R:AtEnchanter()
	return self.here == true
end

-- His name, short (nil: none known).
function R:Who()
	return self.name
end

-------------------------------------------------------------------------------
-- (31 October, his word: the enchanter redone) His work: the flaws one sees on the copy
-------------------------------------------------------------------------------
-- No more a time and rubies for a gain drawn: the enchanter mends the flaws one sees on the copy (UI/Wear.lua), those of
-- the kinds the player chooses. Each one its odds (a whitened corner, easy; a crease, a tear, the print torn off, hard),
-- its price (by the rarity of the card: the harder, the dearer) and its time at his bench. What he mends is gone from
-- the card for good; what he misses stays, and now and then his solvent, his varnish, his runes leave a mark of their own
-- (a flaw like the others, mended in its turn). Its grade follows what is left of its wear: its four marks, its
-- centering never touched, its corners, its edges, its surface up by the weight of what is gone of them (all of it gone:
-- a 10), down by what his mishaps weigh; hidden until its next appraisal, as before. What is kept on the copy (Copies.lua):
-- w0 the marks its pieces were laid by (the first time it went to an enchanter: its pieces never move again), wx the
-- flaws mended, wa his mishaps, hg its true grade x100 and hm its true marks; rec.aw while it is away: { u, at, by, k (the
-- kinds chosen), n (the flaws worked on), ok (those mended), om (his mishaps mended), mi (his new ones), m (a
-- masterpiece) }.
R.TREAT = {
	{ key = "corners", name = "Corners", kinds = { corner = 0.8, dogear = 0.45 }, k = 1 },
	{ key = "edges", name = "Edges", kinds = { edge = 0.8, tear = 0.35 }, k = 1 },
	{ key = "scratches", name = "Scratches", kinds = { scratch = 0.7, swipe = 0.6, deep = 0.3 }, k = 1 },
	{ key = "creases", name = "Creases and dents", kinds = { fold = 0.3, bend = 0.6, crumple = 0.3, dent = 0.5, nail = 0.6, pin = 0.25, band = 0.55 },
		k = 1.3, mishap = "fox" },
	{ key = "stains", name = "Stains", kinds = { stain = 0.6, water = 0.4, fox = 0.5, grime = 0.8, speck = 0.85, lint = 0.95, tape = 0.45, sticker = 0.5 },
		k = 1, mishap = "water" },
	{ key = "paper", name = "The paper", kinds = { tan = 0.55, fade = 0.45, loss = 0.2 }, k = 1.5, mishap = "stain" },
}
R.TREAT_BY = {}
for _, t in ipairs(R.TREAT) do
	R.TREAT_BY[t.key] = t
end
-- (what each kind mends, in his words)
R.TREAT_SAYS = {
	corners = "Whitened, rounded or split corners, a dog-ear: rebuilt and inked again.",
	edges = "Rubbed and chipped edges, nicks and tears: inked again, the tears joined.",
	scratches = "Scratches, the marks of a table, gouges to the stock: polished out, filled.",
	creases = "Creases, a bend, a crumpled patch, dents, fingernail marks, a pin hole, the line of a rubber band: pressed flat under his runes.",
	stains = "The ring of a mug, water, foxing, grime, specks, a hair, tape, what a sticker left: cleaned away.",
	paper = "The card yellowed, a side faded by the sun, the print torn off: its paper and its colours brought back.",
}
R.PER = 40 -- (rubies: a flaw of a common card, as easy as it gets)
R.MISHAP = 0.12 -- (a flaw missed: the chance his work leaves a mark of its own, for the kinds that can)
R.MISHAPS = 6 -- (at most, on a copy)
R.MAX = 1000 -- (x100: a grade never past 10)
-- (1 November, his word: « il faut faire payer un devis ») The quote: the enchanter looks at the copy, flaw by flaw, and
-- says what he can do, for so many rubies (a third of an appraisal, by its rarity); without it he says nothing of its
-- flaws. One quote, one job: the copy left, it is used; its flaws changed, it is no more true.
R.QUOTE = { 150, 250, 450, 750, 1350, 2250 }
-- (his word: a titanforged card, ten times the price of its restoration; 1 November, 14 h 20, his choice after the
-- simulation of the rubies, « C » : three times, as the Bourse counts a titanforged copy)
R.TITAN = 3
-- (1 November, 14 h 20, his choice « C ») A restoration never costs more than the copy is worth at the Bourse (its value of
-- reference, Market.lua: MK:Ref, its finish and a 10 counted), its quote with it: the quote at most a tenth of that value,
-- the work the rest of it; past it, every flaw cheaper by the same part (R.ValueOf, R.CaseValueOf; PlanOf).
R.QUOTE_PART = 0.1
-- (his word: too cheap at the top) The few flaws of a fine card are the dearest: the price of each flaw times this, by
-- how many flaws are on the copy (what the quote shows of it, never its grade): { at least so many flaws, times }.
R.FEW = { { 45, 1 }, { 30, 1.2 }, { 19, 1.5 }, { 13, 2 }, { 7, 3 }, { 4, 5 }, { 2, 8 }, { 1, 12 } }
R.MIN_SECS = 3600 -- (his time: an hour at least)
function R.Few(n)
	n = tonumber(n) or 0
	for _, x in ipairs(R.FEW) do
		if n >= x[1] then
			return x[2]
		end
	end
	return 1
end

-- the size of a job (1 to 4: what the copy keeps of it, rec.r, as the Exchange carries it): its flaws
local function Size(n)
	return n <= 5 and 1 or (n <= 15 and 2 or (n <= 30 and 3 or 4))
end
R.Size = Size

function R.Valid(d)
	d = tonumber(d)
	if d and d >= 1 and d <= 4 and d == math.floor(d) then
		return d
	end
	return nil
end

-- The kinds chosen, as a list of their keys, in their order ("corners,stains" or { corners = true, ... } or a list).
function R.Kinds(sel)
	local on = {}
	if type(sel) == "string" then
		for k in CuratorOctoFull.Gmatch(sel, "[%a]+") do
			on[k] = true
		end
	elseif type(sel) == "table" then
		for k, v in pairs(sel) do
			if type(k) == "number" then
				on[v] = true
			elseif v then
				on[k] = true
			end
		end
	end
	local out = {}
	for _, t in ipairs(R.TREAT) do
		if on[t.key] then
			out[CuratorOctoFull.Length(out) + 1] = t.key
		end
	end
	return out
end

-- (the talents of the Archivist on his work: Golden Fingers, his odds better)
local function Better(odds)
	local TL = ns.Talents
	if TL and TL.Spec and TL:Spec() == "archivist" and TL:Has("goldfinger") then
		odds = odds + TL:V("goldfinger")
	end
	return math.max(0.02, math.min(0.97, odds))
end

-- The flaws of a wear as they lie on the card now (UI/Wear.lua): those still there, his mishaps among them.
local function FlawsOf(wear)
	local WU = ns.WearUI
	if not (wear and WU and WU.Flaws) then
		return {}
	end
	local out = {}
	for _, f in ipairs(WU.Flaws(wear)) do
		if not f.gone then
			out[CuratorOctoFull.Length(out) + 1] = f
		end
	end
	return out
end

-- The flaws of a copy as they lie on it now (its wear, UI/Wear.lua): those still there, his mishaps among them; and the
-- marks its pieces are laid by.
function R:Flaws(rec)
	local W = ns.Wear
	local wear = W and W.Of(rec)
	if not wear then
		return {}, nil
	end
	return FlawsOf(wear), wear
end

-- (1 November) The flaws of a card of a case (its record, the save's own: Cases.lua), and its wear.
function R:CaseFlaws(w)
	local CS = ns.Cases
	local wear = type(w) == "table" and CS and CS.WearOf and CS.WearOf(w) or nil
	if not wear then
		return {}, nil
	end
	return FlawsOf(wear), wear
end

local PlanOf

-- What a job would be (sel: the kinds): { flaws = the flaws worked on (each its odds: f.odds, its kind of work: f.t),
-- n, price, secs, by = { [key] = { n, odds (their mean) } }, all (every flaw still there) }.
function R:Plan(card, rec, sel)
	local flaws = (type(rec) == "table") and self:Flaws(rec) or {}
	return PlanOf(self, flaws, (card and card.rarity) or 1, R.Titan(rec), sel, R.ValueOf(card, rec))
end

-- (the job itself, whatever the card: its flaws, its rarity for his prices, titanforged; value: what the copy is worth at
-- the Bourse, his prices never past it, its quote counted)
function PlanOf(self, flaws, rarity, titanforged, sel, value)
	local kinds = {}
	for _, k in ipairs(R.Kinds(sel)) do
		kinds[k] = true
	end
	local mult = self.MULT[rarity or 1] or self.MULT[1]
	-- (1 November, his words: the few flaws of a fine card the dearest; a titanforged card ten times)
	local few = R.Few(CuratorOctoFull.Length(flaws))
	local titan = titanforged and R.TITAN or 1
	local plan = { flaws = {}, n = 0, price = 0, secs = 0, by = {}, all = CuratorOctoFull.Length(flaws), few = few, titan = titan > 1 or nil, every = {} }
	for _, t in ipairs(R.TREAT) do
		plan.by[t.key] = { n = 0, odds = 0, price = 0 }
	end
	for _, f in ipairs(flaws) do
		for _, t in ipairs(R.TREAT) do
			local o = t.kinds[f.kind]
			if o then
				local b = plan.by[t.key]
				local odds = Better(o)
				local fp = self.PER * mult * (0.6 + 2 * (1 - o)) * t.k * few * titan
				b.n, b.odds, b.price = b.n + 1, b.odds + odds, b.price + fp
				f.odds, f.t, f.price = odds, t.key, fp
				plan.every[CuratorOctoFull.Length(plan.every) + 1] = f
				if kinds[t.key] then
					plan.flaws[CuratorOctoFull.Length(plan.flaws) + 1] = f
					plan.n = plan.n + 1
					plan.price = plan.price + fp
				end
				break
			end
		end
	end
	for _, b in pairs(plan.by) do
		if b.n > 0 then
			b.odds = b.odds / b.n
		end
	end
	-- (1 November, 14 h 20, his choice « C »: every flaw of it dearer than the copy is worth, its quote counted: each one
	-- cheaper by the same part)
	if value then
		local every = 0
		for _, b in pairs(plan.by) do
			every = every + b.price
		end
		local cap = math.max(0, value - R.QuoteBase(rarity, value))
		if every > cap and every > 0 then
			local k = cap / every
			plan.price = plan.price * k
			for _, b in pairs(plan.by) do
				b.price = b.price * k
			end
			for _, f in ipairs(plan.every) do
				f.price = (f.price or 0) * k
			end
			plan.capped = true
		end
		plan.worth = value
	end
	plan.price = math.floor(plan.price / 5 + 0.5) * 5
	-- (his time: a quarter of an hour, and three minutes a flaw; an hour at least, eight at most; Enchanter's Patience,
	-- sooner)
	local secs = math.min(28800, math.max(R.MIN_SECS, 900 + 180 * plan.n))
	local TL = ns.Talents
	if TL and TL.Spec and TL:Spec() == "archivist" and TL:Has("patience") then
		secs = secs * (1 - TL:V("patience"))
	end
	plan.secs = math.max(60, math.floor(secs))
	return plan
end

function R:BasePrice(card, rec, sel)
	return self:Plan(card, rec, sel).price
end

-- (what a job costs: Restoration Offered, a talent of the Archivist, once a week for nothing up to so many flaws; the
-- talents that lower his prices)
local function PriceOf(self, plan)
	if plan and self:Offered(plan.n) then
		return 0
	end
	local base = plan and plan.price or 0
	return ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "restore") or base
end

function R:Price(card, rec, sel)
	return PriceOf(self, type(rec) == "table" and self:Plan(card, rec, sel) or nil)
end

-- (1.14.0) The restoration of the week offered: up to 8 flaws (rank 1), 16 (rank 2), 30 (rank 3).
R.OFFERED = { 8, 16, 30 }
function R:Offered(n)
	local TL = ns.Talents
	n = tonumber(n)
	if not (n and n > 0 and TL and TL.Ready and TL:Ready("freerestore")) then
		return false
	end
	return n <= (R.OFFERED[TL:Rank("freerestore")] or 0)
end

-- The cheapest work (what the rubies buy, in a word): a corner of a common card.
function R:From()
	return math.floor(self.PER * (0.6 + 2 * 0.2) + 0.5)
end

-- The marks of a copy once its flaws are as they are (m0: the marks its pieces were laid by; flaws: all of them, those
-- mended gone, his mishaps): its centering as it was; its corners, its edges, its surface up by the weight of what is
-- gone of them (all of it: 10), down half a step by each weight of his mishaps; whole marks, as the expert counts
-- them. Its grade: their mean, to its tenth (a 10 only when all four are).
function R.MarksAfter(m0, flaws)
	local tot, gone, add = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
	for _, f in ipairs(flaws or {}) do
		local c = f.cat
		if c and c >= 2 and c <= 4 then
			if f.mishap then
				if not f.gone then
					add[c] = add[c] + f.sev
				end
			else
				tot[c] = tot[c] + f.sev
				if f.gone then
					gone[c] = gone[c] + f.sev
				end
			end
		end
	end
	local m = { m0[1] }
	for c = 2, 4 do
		local v = m0[c]
		if tot[c] > 0 then
			v = v + (10 - v) * gone[c] / tot[c]
		end
		v = v - 0.5 * add[c]
		m[c] = math.max(1, math.min(10, math.floor(v + 1e-6)))
	end
	local g = (m[1] + m[2] + m[3] + m[4]) * 25
	if g < R.MAX then
		g = math.min(R.MAX - 10, math.floor(g / 10 + 0.5) * 10)
	end
	return m, g
end

-- A grade or a gain x100 to its tenth (one decimal), never up to 10 from under it (a 10 is reached, never rounded to).
function R.Tenth(n)
	n = tonumber(n)
	if not n then
		return nil
	end
	local t = math.floor(n / 10 + 0.5) * 10
	if n < R.MAX and t >= R.MAX then
		t = R.MAX - 10
	end
	return t
end

-- "3 h 12 min": his time, as the language writes it.
function R.TimeText(secs)
	secs = math.floor(tonumber(secs) or 0)
	if secs < 3600 then
		return string.format(L["%d min"], math.max(1, math.floor(secs / 60 + 0.5)))
	end
	local h, m = math.floor(secs / 3600), math.floor((CuratorOctoFull.Mod(secs , 3600)) / 60 + 0.5)
	if m >= 60 then
		h, m = h + 1, 0
	end
	return m > 0 and (string.format(L["%d h"], h) .. " " .. string.format(L["%d min"], m)) or string.format(L["%d h"], h)
end

-- "0,3", "1": a gain x100 with its decimal, as the language writes it.
function R.Dec(n)
	local v = math.floor((tonumber(n) or 0) / 10 + 0.5) / 10
	if v == math.floor(v) then
		return tostring(math.floor(v))
	end
	local s = string.format(("%.1f"), v)
	return (string.gsub(s, "%.", ns.L["."]))
end

-- "75 %": odds as the language writes them.
function R.Pct(x)
	return string.format(("%d %%"), math.floor((tonumber(x) or 0) * 100 + 0.5))
end

-------------------------------------------------------------------------------
-- The copies at the enchanters
-------------------------------------------------------------------------------
-- A copy away (its record): whether its work is done.
function R:Ready(rec, now)
	local aw = type(rec) == "table" and type(rec.aw) == "table" and rec.aw or nil
	return aw ~= nil and (now or Now()) >= Int(aw.u)
end

-- How long before it is ready (0: ready; nil: not away).
function R:Left(rec, now)
	local aw = type(rec) == "table" and type(rec.aw) == "table" and rec.aw
	if not aw then
		return nil
	end
	return math.max(0, Int(aw.u) - (now or Now()))
end

-- "At an enchanter: ready in 3 h 12 min" (UI/Copies.lua: the tooltip of a copy).
function R:AwayText(rec)
	local left = self:Left(rec)
	if not left then
		return nil
	end
	local by = type(rec.aw.by) == "string" and rec.aw.by ~= "" and rec.aw.by or nil
	if left <= 0 then
		return by and string.format(L["At %s: ready to pick up, at any enchanter"], by) or L["At an enchanter: ready to pick up"]
	end
	return by and string.format(L["At %s: ready in %s"], by, ns.Duration(left)) or string.format(L["At an enchanter: ready in %s"], ns.Duration(left))
end

-- Every copy at the enchanters: { { card, rec, ready, left } } (1 November: a card of a case, { case = true, id, rec
-- (the save's own), ready, left }), the first ready first.
function R:Away()
	local out = {}
	local db = ns.db
	local now = Now()
	for key, list in pairs(db and type(db.copies) == "table" and db.copies or {}) do
		local card = ns.Cards[key]
		for _, r in ipairs(card and type(list) == "table" and list or {}) do
			if type(r) == "table" and type(r.aw) == "table" then
				local left = self:Left(r, now)
				out[CuratorOctoFull.Length(out) + 1] = { card = card, rec = r, ready = left <= 0, left = left }
			end
		end
	end
	local CS = ns.Cases
	local c = db and CS and CS.Db and CS.Db()
	for _, w in ipairs(c and type(c.won) == "table" and c.won or {}) do
		if type(w) == "table" and type(w.aw) == "table" then
			local left = self:Left(w, now)
			out[CuratorOctoFull.Length(out) + 1] = { case = true, id = w.i, rec = w, ready = left <= 0, left = left }
		end
	end
	table.sort(out, function(a, b)
		if a.left ~= b.left then
			return a.left < b.left
		end
		return (a.rec.i or 0) < (b.rec.i or 0)
	end)
	return out
end

-- How many copies are away, how many of them are ready, and when the next one is (seconds; nil: none waits).
function R:Counts()
	local away, ready, next = 0, 0, nil
	for _, x in ipairs(self:Away()) do
		away = away + 1
		if x.ready then
			ready = ready + 1
		elseif not next or x.left < next then
			next = x.left
		end
	end
	return away, ready, next
end

-------------------------------------------------------------------------------
-- A copy left, picked up
-------------------------------------------------------------------------------
-- The copy of a card (id; nil: none).
local function CopyOf(card, id)
	local CP = ns.Copies
	return card and CP and id ~= nil and CP:Get(card.key, id) or nil
end

-- (1 November) A titanforged copy: its restoration dearer (R.TITAN).
function R.Titan(rec)
	return type(rec) == "table" and rec.f == "h"
end

-- (1 November, 14 h 20, his choice « C ») What a copy of an album is worth at the Bourse (nil: not known).
function R.ValueOf(card, rec)
	local MK = ns.Market
	if not (MK and MK.Ref and card and card.npc and type(rec) == "table") then
		return nil
	end
	local v = MK:Ref({ k = "c", npc = card.npc, f = rec.f or "n", g = tonumber(rec.g) or 0, sl = rec.sl })
	return (tonumber(v) or 0) > 0 and v or nil
end

-- What a card of a case is worth at the Bourse (nil: not known).
function R.CaseValueOf(w)
	local MK = ns.Market
	if not (MK and MK.Ref and type(w) == "table") then
		return nil
	end
	local f = (w.f == "titan" and "T") or (w.f == "thunder" and "t") or "n"
	local v = MK:Ref({ k = "w", rank = tonumber(w.r) or 1, f = f, ap = w.ap and true or nil, grade = tonumber(w.g) })
	return (tonumber(v) or 0) > 0 and v or nil
end

-- The quote of a rarity (R.QUOTE) for a copy of that value: at most a tenth of it, a ruby at least.
function R.QuoteBase(rarity, value)
	local base = R.QUOTE[rarity or 1] or R.QUOTE[1]
	if value then
		base = math.max(1, math.min(base, math.floor(value * R.QUOTE_PART)))
	end
	return base
end

-- (1 November, his word: the quote) What its flaws are now, in a word: a quote is true while they are what he saw.
local function QuoteKey(rec)
	return table.concat({ tostring(rec.wv), tostring(rec.wq), tostring(rec.w0), tostring(rec.wx), tostring(rec.wa) }, ":")
end

-- Whether a copy has its quote, still true.
function R:Quoted(rec)
	return type(rec) == "table" and type(rec.dq) == "table" and rec.dq.k == QuoteKey(rec)
end

-- What a quote costs (a third of an appraisal of its rarity; the talents that lower his prices lower it too).
-- (rec: the copy, its quote at most a tenth of what it is worth at the Bourse)
function R:QuotePrice(card, rec)
	local base = R.QuoteBase((card and card.rarity) or 1, rec and R.ValueOf(card, rec) or nil)
	return ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "restore") or base
end

-- Whether a quote can be asked for now: true, or false and why ("closed", "card", "sealed", "corrupt", "away",
-- "quoted": it has its quote, "clean": not a flaw on it, "enchanter", "rubies").
-- (1 November, 12 h 56: a copy restored ten times, 2 · 10 · 10 · 10) Its marks as the expert found it, appraised as it is
-- now (its case closed; a card of a case appraised since its last restoration): nil otherwise. Nothing he can mend on it:
-- its corners, its edges, its surface at 10 (its centring is how it was cut: no enchanter touches it).
function R.MarksNow(rec, case)
	local E = ns.Expertise
	if type(rec) ~= "table" or type(rec.m) ~= "string" or not (E and E.DecodeMarks) then
		return nil
	end
	if (case and not rec.ap) or (not case and rec.sl == false) then
		return nil
	end
	return E.DecodeMarks(rec.m)
end
function R.NothingToMend(m)
	return type(m) == "table" and (tonumber(m[2]) or 0) >= 10 and (tonumber(m[3]) or 0) >= 10 and (tonumber(m[4]) or 0) >= 10
end

function R:CanQuote(card, id)
	if Closed() then
		return false, "closed"
	end
	if not (card and ns.Collection:Owned(card)) then
		return false, "card"
	end
	local rec = CopyOf(card, id)
	if not rec then
		return false, "card"
	end
	if rec.ws then
		return false, "sealed"
	end
	if rec.f == "c" then
		return false, "corrupt"
	end
	if type(rec.aw) == "table" then
		return false, "away"
	end
	if self:Quoted(rec) then
		return false, "quoted"
	end
	-- (appraised as it is, nothing he can mend on it: no quote to pay for)
	if R.NothingToMend(R.MarksNow(rec)) then
		return false, "flawless"
	end
	if not self:AtEnchanter() then
		return false, "enchanter"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:QuotePrice(card, rec))) then
		return false, "rubies"
	end
	return true
end

-- The quote: its rubies paid, the copy looked at flaw by flaw (what he found, kept with it: rec.dq). What it found:
-- { card, id, price (of the quote), flaws (each: id, kind, cat, sev, x, y, odds, price, t: its kind of work, mishap),
-- by (each kind: n, odds, price), all (its price for every flaw), secs (his time for every flaw), few, titan, by
-- (his name) } (nil and why, as CanQuote).
function R:Quote(card, id)
	local ok, why = self:CanQuote(card, id)
	if not ok then
		return nil, why
	end
	local rec = CopyOf(card, id)
	local price = self:QuotePrice(card, rec)
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "restore")
		if not paid then
			return nil, err
		end
	end
	local all = {}
	for _, t in ipairs(R.TREAT) do
		all[t.key] = true
	end
	local plan = self:Plan(card, rec, all)
	local by = self.name
	if type(by) == "string" then
		by = string.sub(by, 1, 40)
	end
	-- (1 November, his word: « voir le devis »: who made it, kept with it)
	rec.dq = { t = Now(), k = QuoteKey(rec), w = by }
	local st = ns.Stats()
	st.quotes = (tonumber(st.quotes) or 0) + 1
	local res = { card = card, id = rec.i, price = price, flaws = plan.every, by = plan.by, all = plan.price, secs = plan.secs,
		few = plan.few, titan = plan.titan, capped = plan.capped, worth = plan.worth, who = by }
	ns.Fire("COPY_QUOTED", res)
	ns.Fire("COPIES_CHANGED", card)
	return res
end

-- (every kind of his work)
local function AllKinds()
	local all = {}
	for _, t in ipairs(R.TREAT) do
		all[t.key] = true
	end
	return all
end

-- (1 November, his word: « voir le devis ») A quote kept, as he made it: what R:Quote found (its flaws are what he saw
-- while it is true; his prices as they are now), when (t), by whom (who); nil: no quote, or no more true.
function R:QuoteOf(card, id)
	local rec = CopyOf(card, id)
	if not (rec and self:Quoted(rec)) then
		return nil
	end
	local plan = self:Plan(card, rec, AllKinds())
	return { card = card, id = rec.i, flaws = plan.every, by = plan.by, all = plan.price, secs = plan.secs, few = plan.few,
		titan = plan.titan, capped = plan.capped, worth = plan.worth, who = rec.dq.w, t = rec.dq.t }
end

-- Whether a copy can be restored now (sel: the kinds of flaws chosen): true, or false and why ("closed", "card": not a
-- copy of the collection, "corrupt", "sealed", "away": at an enchanter already, "kinds": no kind chosen, "nothing": no
-- flaw of those kinds on it, "enchanter": not at one, "rubies").
function R:CanRestore(card, id, sel)
	if Closed() then
		return false, "closed"
	end
	if not (card and ns.Collection:Owned(card)) then
		return false, "card"
	end
	local rec = CopyOf(card, id)
	if not rec then
		return false, "card"
	end
	if rec.ws then
		return false, "sealed"
	end
	if rec.f == "c" then
		return false, "corrupt"
	end
	if type(rec.aw) == "table" then
		return false, "away"
	end
	-- (1 November, his word: nothing without a quote)
	if not self:Quoted(rec) then
		return false, "quote"
	end
	if CuratorOctoFull.Length(R.Kinds(sel)) == 0 then
		return false, "kinds"
	end
	local plan = self:Plan(card, rec, sel)
	if plan.n == 0 then
		return false, "nothing"
	end
	if not self:AtEnchanter() then
		return false, "enchanter"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:Price(card, rec, sel))) then
		return false, "rubies"
	end
	return true
end

-- His work on a job (plan: R:Plan; rec: the record of the card, its mishaps on it, wa), done now as his odds say: what
-- the card keeps while it is away, { u, at, by, k, n, ok, om, mi, m, d }. (1.14.0, the Archivist: Restorer, a flaw
-- missed tried again now and then; Masterpiece, once a week, every flaw mended; Restoration Offered, for nothing)
function R.Work(plan, rec, sel, rnd, offered, now, by)
	local TL = ns.Talents
	local arch = TL and TL.Spec and TL:Spec() == "archivist"
	local master = false
	if arch and TL:Ready("masterpiece") then
		TL:Use("masterpiece")
		master = true
	end
	if offered and TL then
		TL:Use("freerestore")
	end
	local mended, mendedMishaps, mishaps = {}, {}, {}
	local count = 0
	for _ in CuratorOctoFull.Gmatch(tostring(rec.wa or ""), "[^;]+") do
		count = count + 1
	end
	for _, f in ipairs(plan.flaws) do
		local done = master or rnd() < f.odds
		if not done and arch and TL:Has("restorer") and rnd() < TL:V("restorer") then
			done = rnd() < f.odds
		end
		if done then
			if f.mishap then
				mendedMishaps[CuratorOctoFull.Length(mendedMishaps) + 1] = f.mishap
			else
				mended[CuratorOctoFull.Length(mended) + 1] = f.id
			end
		else
			-- (missed: now and then his work leaves a mark of its own, where he worked)
			local t = R.TREAT_BY[f.t]
			if t and t.mishap and count < R.MISHAPS and rnd() < R.MISHAP then
				count = count + 1
				local size = t.mishap == "fox" and (40 + 40 * rnd()) or (110 + 90 * rnd())
				local x = math.max(120, math.min(880, math.floor(f.x * 1000 + (rnd() - 0.5) * 120)))
				local y = math.max(120, math.min(880, math.floor(f.y * 1000 + (rnd() - 0.5) * 120)))
				mishaps[CuratorOctoFull.Length(mishaps) + 1] = string.format(("%s:%d:%d:%d:%d:%d"), t.mishap, x, y, math.floor(size), math.floor(rnd() * 628), 1 + math.floor(rnd() * 12))
			end
		end
	end
	return { u = now + plan.secs, at = now, by = by, k = table.concat(R.Kinds(sel), ","), n = plan.n,
		ok = CuratorOctoFull.Length(mended) > 0 and table.concat(mended, ",") or nil, om = CuratorOctoFull.Length(mendedMishaps) > 0 and table.concat(mendedMishaps, ",") or nil,
		mi = CuratorOctoFull.Length(mishaps) > 0 and table.concat(mishaps, ";") or nil, m = master or nil, d = Size(plan.n) }
end

-- What his work leaves on the card once picked up (rec: its record; aw: his work): the flaws he mended gone for good
-- (wx), his mishaps mended gone and his new ones on it (wa). What it did: the ids gone now (the scene shows them going),
-- his new mishaps, the flaws mended.
function R.Leave(rec, aw)
	local ids, seen = {}, {}
	for x in CuratorOctoFull.Gmatch(tostring(rec.wx or ""), "%d+") do
		local n = tonumber(x)
		if not seen[n] then
			seen[n] = true
			ids[CuratorOctoFull.Length(ids) + 1] = n
		end
	end
	local gone = {}
	for x in CuratorOctoFull.Gmatch(tostring(aw.ok or ""), "%d+") do
		local n = tonumber(x)
		if not seen[n] then
			seen[n] = true
			ids[CuratorOctoFull.Length(ids) + 1] = n
			gone[CuratorOctoFull.Length(gone) + 1] = n
		end
	end
	table.sort(ids)
	rec.wx = CuratorOctoFull.Length(ids) > 0 and table.concat(ids, ",") or nil
	local drop = {}
	for x in CuratorOctoFull.Gmatch(tostring(aw.om or ""), "%d+") do
		drop[tonumber(x)] = true
		gone[CuratorOctoFull.Length(gone) + 1] = 1000 + tonumber(x)
	end
	local kept, k = {}, 0
	for part in CuratorOctoFull.Gmatch(tostring(rec.wa or ""), "[^;]+") do
		k = k + 1
		if not drop[k] then
			kept[CuratorOctoFull.Length(kept) + 1] = part
		end
	end
	local new = 0
	for part in CuratorOctoFull.Gmatch(tostring(aw.mi or ""), "[^;]+") do
		if CuratorOctoFull.Length(kept) < R.MISHAPS then
			kept[CuratorOctoFull.Length(kept) + 1] = part
			new = new + 1
		end
	end
	rec.wa = CuratorOctoFull.Length(kept) > 0 and table.concat(kept, ";") or nil
	local mended = 0
	for _ in CuratorOctoFull.Gmatch(tostring(aw.ok or ""), "%d+") do
		mended = mended + 1
	end
	for _ in CuratorOctoFull.Gmatch(tostring(aw.om or ""), "%d+") do
		mended = mended + 1
	end
	return gone, new, mended
end

-- A copy left with the enchanter, the flaws of the kinds chosen to mend: its rubies paid, his work done now as his odds
-- say (told when it is picked up: the card is away meanwhile), its case opened when it was in one, its pieces laid for
-- good. What it did: { card, id, kinds, n, price, ready (when), opened (its case), by } (nil and why, as CanRestore).
-- (rnd: a random of 0 to 1, for the tests; the game's otherwise)
function R:Restore(card, id, sel, rnd)
	local ok, why = self:CanRestore(card, id, sel)
	if not ok then
		return nil, why
	end
	rnd = rnd or math.random
	local rec = CopyOf(card, id)
	local plan = self:Plan(card, rec, sel)
	local price = self:Price(card, rec, sel)
	local offered = self:Offered(plan.n)
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "restore")
		if not paid then
			return nil, err
		end
	end
	local now = Now()
	local by = self.name
	if type(by) == "string" then
		by = string.sub(by, 1, 40)
	end
	-- (its pieces laid for good: the marks they are laid by, kept)
	local _, wear = self:Flaws(rec)
	local E = ns.Expertise
	if wear and not rec.w0 and E and E.EncodeMarks then
		rec.w0 = E.EncodeMarks(wear.m)
		rec.wv = rec.wv or wear.seed
	end
	-- (his quote, used: one quote, one job)
	rec.dq = nil
	rec.aw = R.Work(plan, rec, sel, rnd, offered, now, by)
	local opened = ns.Copies.Grade(rec) ~= nil and rec.sl ~= false
	if ns.Copies.Grade(rec) then
		rec.sl = false
	end
	local st = ns.Stats()
	st.restoreGiven = (tonumber(st.restoreGiven) or 0) + 1
	local res = { card = card, id = rec.i, kinds = rec.aw.k, n = plan.n, price = price, ready = rec.aw.u, opened = opened or nil, by = by }
	ns.Fire("COPY_RESTORING", res)
	ns.Fire("COPIES_CHANGED", card)
	ns.Fire("CHANGED")
	return res
end

-- A copy picked up (its work done, at an enchanter): the flaws he mended gone from it, his mishaps on it, its true
-- grade what is left of its wear (hidden until its next appraisal). What it did: { card, id, times (its restorations
-- now), n (flaws worked on), mended, mishaps, before (its flaws before), gone (the ids of the flaws gone now: the scene
-- shows them going) } (nil and why: "closed", "card", "away": not away, "ready": not ready yet, "enchanter").
function R:PickUp(card, id)
	if Closed() then
		return nil, "closed"
	end
	local rec = CopyOf(card, id)
	if not rec then
		return nil, "card"
	end
	local aw = type(rec.aw) == "table" and rec.aw or nil
	if not aw then
		return nil, "away"
	end
	if not self:Ready(rec) then
		return nil, "ready"
	end
	if not self:AtEnchanter() then
		return nil, "enchanter"
	end
	-- (a work of before this night, left with a time: its gain on its grade, as it was)
	if aw.k == nil and tonumber(aw.a) then
		local a = math.max(0, math.min(R.MAX, Int(aw.a)))
		local base = tonumber(rec.hg) or tonumber(rec.g)
		if not (base and base >= 100 and base <= R.MAX) then
			local hidden = ns.Wear and ns.Wear.Hidden(rec)
			base = (hidden or 5) * 100
		end
		rec.hg = math.min(R.MAX, R.Tenth(math.floor(base)) + a)
		rec.r = type(rec.r) == "table" and rec.r or {}
		rec.r[CuratorOctoFull.Length(rec.r) + 1] = { Now(), self.Valid(aw.d) or 1, a }
		-- (1.14.0, Masterpiece: a copy restored to 10 by it, its achievement; the review of the night: kept for these too)
		if aw.m and rec.hg >= R.MAX and ns.Talents then
			ns.Talents:Summit("masterpiece")
		end
		rec.aw = nil
		local st = ns.Stats()
		st.restoreDone = (tonumber(st.restoreDone) or 0) + 1
		local res = { card = card, id = rec.i, times = CuratorOctoFull.Length(rec.r), n = 0, mended = 0, mishaps = 0, before = 0, gone = {} }
		ns.Fire("COPY_RESTORED", res)
		ns.Fire("COPIES_CHANGED", card)
		ns.Fire("CHANGED")
		return res
	end
	local before = CuratorOctoFull.Length((self:Flaws(rec)))
	-- (the flaws he mended: gone for good; his mishaps: those he mended gone, his new ones on it)
	local gone, new, mended = R.Leave(rec, aw)
	-- (its true grade: what is left of its wear)
	local E = ns.Expertise
	local m0 = E and E.DecodeMarks and E.DecodeMarks(rec.w0)
	local W, WU = ns.Wear, ns.WearUI
	local a = 0
	if m0 and W and WU and WU.Flaws then
		local m, g = R.MarksAfter(m0, WU.Flaws(W.Of(rec)))
		local hidden = W.Hidden(rec)
		local base = tonumber(rec.hg) or tonumber(rec.g) or (hidden and hidden * 100) or g
		-- (nothing of its marks changed: its grade as it was, not its mean to its tenth)
		if m[1] == m0[1] and m[2] == m0[2] and m[3] == m0[3] and m[4] == m0[4] and not rec.hm then
			g = math.floor(base)
		end
		-- (his work never takes a copy below what it was, but for his mishaps)
		if g < math.floor(base) and new == 0 then
			g = math.floor(base)
		end
		rec.hm = E.EncodeMarks(m)
		rec.hg = g
		a = math.max(0, g - math.floor(base))
	end
	rec.r = type(rec.r) == "table" and rec.r or {}
	rec.r[CuratorOctoFull.Length(rec.r) + 1] = { Now(), R.Valid(aw.d) or Size(Int(aw.n)), math.min(R.MAX, R.Tenth(a) or 0) }
	-- (1.14.0, Masterpiece: a copy restored to 10 by it, its achievement)
	if aw.m and tonumber(rec.hg) and rec.hg >= R.MAX and ns.Talents then
		ns.Talents:Summit("masterpiece")
	end
	rec.aw = nil
	local st = ns.Stats()
	st.restoreDone = (tonumber(st.restoreDone) or 0) + 1
	-- (31 October: the flaws mended, his mishaps, counted: the achievements of the wear)
	st.flawsMended = (tonumber(st.flawsMended) or 0) + mended
	st.mishaps = (tonumber(st.mishaps) or 0) + new
	if before > 0 and CuratorOctoFull.Length((self:Flaws(rec))) == 0 then
		st.flawless = (tonumber(st.flawless) or 0) + 1
	end
	local res = { card = card, id = rec.i, times = CuratorOctoFull.Length(rec.r), n = Int(aw.n), mended = mended, mishaps = new, before = before, gone = gone }
	ns.Fire("COPY_RESTORED", res)
	ns.Fire("COPIES_CHANGED", card)
	ns.Fire("CHANGED")
	return res
end

-------------------------------------------------------------------------------
-- (1 November, 2 h 13, his word: « il faut que les cartes de caisse peuvent être aussi restaurées ») The cards of the
-- cases at the enchanters: the same work as for a copy of the albums (his quote first, paid; the flaws of the kinds
-- chosen, each by its odds), on their records (Cases.lua, the save's own: CS.Own): w0 the marks its pieces are laid by
-- (veiled by its seed, as its marks travel), wx the flaws mended, wa his mishaps, hm its true marks once picked up
-- (veiled; told at its next appraisal), its grade hidden as before (whole, as the Bourse and the site know the grades
-- of these cards), rr its restorations ({ when, size of the job, gain x100 }), aw while it is away, dq its quote. His
-- prices: its rank as the expert prices it (Cases.lua: CS.APPRAISE, a rare card as an uncommon one of the albums...); a
-- titanforged one ten times. Appraised, its appraisal is no more when it is left with him: its case opened, its new
-- grade known at its next appraisal at a banker.
-------------------------------------------------------------------------------
local function CaseRec(id)
	local CS = ns.Cases
	return CS and CS.Own and id ~= nil and CS.Own(id) or nil
end

-- Its rarity for his prices (1 to 6).
function R.CaseRarity(w)
	local CS = ns.Cases
	return (CS and CS.APPRAISE and CS.APPRAISE[tonumber(w and w.r) or 1]) or 2
end

function R.CaseTitan(w)
	return type(w) == "table" and w.f == "titan"
end

-- (what its flaws are now, in a word: its seed, the marks they are laid by, those mended, his mishaps)
local function CaseKey(w)
	local CS = ns.Cases
	local wear = CS and CS.WearOf and CS.WearOf(w)
	return "c:" .. tostring(wear and wear.seed) .. ":" .. (wear and table.concat(wear.m, "") or "") .. ":" .. tostring(w.wx) .. ":" .. tostring(w.wa)
end

-- What a job on a card of a case would be (its number; sel: the kinds), as R:Plan.
function R:CasePlan(id, sel)
	local w = CaseRec(id)
	local flaws = w and self:CaseFlaws(w) or {}
	return PlanOf(self, flaws, R.CaseRarity(w), R.CaseTitan(w), sel, R.CaseValueOf(w))
end

function R:CasePrice(id, sel)
	return PriceOf(self, CaseRec(id) and self:CasePlan(id, sel) or nil)
end

function R:CaseQuoted(id)
	local w = CaseRec(id)
	return w ~= nil and type(w.dq) == "table" and w.dq.k == CaseKey(w)
end

function R:CaseQuotePrice(id)
	local w = CaseRec(id)
	local base = R.QuoteBase(R.CaseRarity(w), R.CaseValueOf(w))
	return ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "restore") or base
end

-- Whether a quote of a card of a case can be asked for now (as R:CanQuote: "closed", "card", "away", "quoted",
-- "enchanter", "rubies").
function R:CanQuoteCase(id)
	if Closed() then
		return false, "closed"
	end
	local w = CaseRec(id)
	if not w then
		return false, "card"
	end
	if type(w.aw) == "table" then
		return false, "away"
	end
	if self:CaseQuoted(id) then
		return false, "quoted"
	end
	if R.NothingToMend(R.MarksNow(w, true)) then
		return false, "flawless"
	end
	if not self:AtEnchanter() then
		return false, "enchanter"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:CaseQuotePrice(id))) then
		return false, "rubies"
	end
	return true
end

-- His quote of a card of a case, paid (as R:Quote: { case = true, id, price, flaws, by, all, secs, few, titan, who }).
function R:QuoteCase(id)
	local ok, why = self:CanQuoteCase(id)
	if not ok then
		return nil, why
	end
	local w = CaseRec(id)
	local price = self:CaseQuotePrice(id)
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "restore")
		if not paid then
			return nil, err
		end
	end
	-- (its seed kept on it, as what leaves Cases.lua does)
	local CS = ns.Cases
	if not tonumber(w.wv) and CS and CS.WearSeed then
		w.wv = CS.WearSeed(w)
	end
	local plan = self:CasePlan(id, AllKinds())
	local by = self.name
	if type(by) == "string" then
		by = string.sub(by, 1, 40)
	end
	w.dq = { t = Now(), k = CaseKey(w), w = by }
	local st = ns.Stats()
	st.quotes = (tonumber(st.quotes) or 0) + 1
	local res = { case = true, id = w.i, price = price, flaws = plan.every, by = plan.by, all = plan.price, secs = plan.secs,
		few = plan.few, titan = plan.titan, capped = plan.capped, worth = plan.worth, who = by }
	ns.Fire("CASES_CHANGED")
	return res
end

-- A quote of a card of a case kept, as he made it (as R:QuoteOf).
function R:CaseQuoteOf(id)
	local w = CaseRec(id)
	if not (w and self:CaseQuoted(id)) then
		return nil
	end
	local plan = self:CasePlan(id, AllKinds())
	return { case = true, id = w.i, flaws = plan.every, by = plan.by, all = plan.price, secs = plan.secs, few = plan.few,
		titan = plan.titan, capped = plan.capped, worth = plan.worth, who = w.dq.w, t = w.dq.t }
end

-- Whether a card of a case can be left with him now (as R:CanRestore).
function R:CanRestoreCase(id, sel)
	if Closed() then
		return false, "closed"
	end
	local w = CaseRec(id)
	if not w then
		return false, "card"
	end
	if type(w.aw) == "table" then
		return false, "away"
	end
	if not self:CaseQuoted(id) then
		return false, "quote"
	end
	if CuratorOctoFull.Length(R.Kinds(sel)) == 0 then
		return false, "kinds"
	end
	local plan = self:CasePlan(id, sel)
	if plan.n == 0 then
		return false, "nothing"
	end
	if not self:AtEnchanter() then
		return false, "enchanter"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:CasePrice(id, sel))) then
		return false, "rubies"
	end
	return true
end

-- A card of a case left with him (as R:Restore: { case = true, id, kinds, n, price, ready, opened, by }).
function R:RestoreCase(id, sel, rnd)
	local ok, why = self:CanRestoreCase(id, sel)
	if not ok then
		return nil, why
	end
	rnd = rnd or math.random
	local w = CaseRec(id)
	local CS, E = ns.Cases, ns.Expertise
	local plan = self:CasePlan(id, sel)
	local price = self:CasePrice(id, sel)
	local offered = self:Offered(plan.n)
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "restore")
		if not paid then
			return nil, err
		end
	end
	local now = Now()
	local by = self.name
	if type(by) == "string" then
		by = string.sub(by, 1, 40)
	end
	-- (its pieces laid for good: the marks they are laid by, kept, veiled by its seed)
	local _, wear = self:CaseFlaws(w)
	if wear and not w.w0 and E and E.EncodeMarks and CS.Veil then
		w.wv = w.wv or wear.seed
		w.w0 = CS.Veil(E.EncodeMarks(wear.m), w.wv)
	end
	w.dq = nil
	w.aw = R.Work(plan, w, sel, rnd, offered, now, by)
	-- (appraised: its case opened, its appraisal no more; its grade hidden again, as it was told)
	local opened = w.ap and true or nil
	if w.ap then
		local g = CS.Grade(w)
		w.ap, w.m, w.ce, w.at = nil, nil, nil, nil
		CS.HideGrade(w, g)
	end
	local st = ns.Stats()
	st.restoreGiven = (tonumber(st.restoreGiven) or 0) + 1
	local res = { case = true, id = w.i, kinds = w.aw.k, n = plan.n, price = price, ready = w.aw.u, opened = opened, by = by }
	ns.Fire("CASE_RESTORING", res)
	ns.Fire("CASES_CHANGED")
	ns.Fire("CHANGED")
	return res
end

-- A card of a case picked up (as R:PickUp: { case = true, id, times, n, mended, mishaps, before, gone }).
function R:PickUpCase(id)
	if Closed() then
		return nil, "closed"
	end
	local w = CaseRec(id)
	if not w then
		return nil, "card"
	end
	local aw = type(w.aw) == "table" and w.aw or nil
	if not aw then
		return nil, "away"
	end
	if not self:Ready(w) then
		return nil, "ready"
	end
	if not self:AtEnchanter() then
		return nil, "enchanter"
	end
	local CS, E, W, WU = ns.Cases, ns.Expertise, ns.Wear, ns.WearUI
	local before = CuratorOctoFull.Length((self:CaseFlaws(w)))
	local base = CS.Grade(w)
	local gone, new, mended = R.Leave(w, aw)
	-- (its true marks: what is left of its wear; its grade, whole, hidden until its next appraisal)
	local m0 = type(w.w0) == "string" and E and E.DecodeMarks and E.DecodeMarks(CS.Unveil(w.w0, w.wv)) or nil
	local g = base
	if m0 and W and WU and WU.Flaws then
		local m = R.MarksAfter(m0, WU.Flaws(CS.WearOf(w)))
		g = W.Whole(m)
		-- (his work never takes a card below what it was, but for his mishaps)
		if g < base and new == 0 then
			g = base
		end
		w.hm = CS.Veil(E.EncodeMarks(m), w.wv)
	end
	CS.HideGrade(w, g)
	w.rr = type(w.rr) == "table" and w.rr or {}
	w.rr[CuratorOctoFull.Length(w.rr) + 1] = { Now(), R.Valid(aw.d) or Size(Int(aw.n)), math.max(0, g - base) * 100 }
	if aw.m and g >= 10 and ns.Talents then
		ns.Talents:Summit("masterpiece")
	end
	w.aw = nil
	local st = ns.Stats()
	st.restoreDone = (tonumber(st.restoreDone) or 0) + 1
	st.flawsMended = (tonumber(st.flawsMended) or 0) + mended
	st.mishaps = (tonumber(st.mishaps) or 0) + new
	if before > 0 and CuratorOctoFull.Length((self:CaseFlaws(w))) == 0 then
		st.flawless = (tonumber(st.flawless) or 0) + 1
	end
	local res = { case = true, id = w.i, times = CuratorOctoFull.Length(w.rr), n = Int(aw.n), mended = mended, mishaps = new, before = before, gone = gone }
	ns.Fire("CASE_RESTORED", res)
	ns.Fire("CASES_CHANGED")
	ns.Fire("CHANGED")
	return res
end

-- Every copy ready, picked up (at an enchanter): what each did ({}: none).
function R:PickUpAll()
	local out = {}
	if not self:AtEnchanter() then
		return out
	end
	for _, x in ipairs(self:Away()) do
		if x.ready then
			local res
			if x.case then
				res = self:PickUpCase(x.id)
			else
				res = self:PickUp(x.card, x.rec.i)
			end
			if res then
				out[CuratorOctoFull.Length(out) + 1] = res
			end
		end
	end
	return out
end

-- A line of the enchanter (list: SAY_GIVE, SAY_BACK; one drawn), in his words.
function R:Line(list)
	if type(list) == "string" then
		return L[list]
	end
	list = list or self.SAY_BACK
	return L[list[math.random(CuratorOctoFull.Length(list))]]
end

-- What he says goes into the chat, as the game writes what an NPC says (here only: nothing is sent).
function R:Say(text, name)
	name = name or self.name
	if not (text and DEFAULT_CHAT_FRAME) then
		return
	end
	local fmt = rawget(_G, "CHAT_MONSTER_SAY_GET")
	local head = (type(fmt) == "string" and name) and string.format(fmt, name) or (name and (name .. ": ")) or ""
	local c = ChatTypeInfo and ChatTypeInfo.MONSTER_SAY
	DEFAULT_CHAT_FRAME:AddMessage(head .. text, c and c.r or 1, c and c.g or 1, c and c.b or 0.62)
end

-- (the copies as they should be: a copy away with what it needs, else given back as it was; since the first test of
-- 1.13.0, a grade restored and a gain with one decimal: those of a test build before, of two, to their tenth)
function R:Mend()
	local db = ns.db
	for _, list in pairs(db and type(db.copies) == "table" and db.copies or {}) do
		for _, r in ipairs(type(list) == "table" and list or {}) do
			if type(r) == "table" then
				for _, k in ipairs({ "g", "hg" }) do
					local v = tonumber(r[k])
					if v and v >= 100 and v <= R.MAX and CuratorOctoFull.Mod(v , 10) ~= 0 then
						r[k] = R.Tenth(v)
					end
				end
			end
			if type(r) == "table" and r.aw ~= nil then
				local aw = r.aw
				if type(aw) ~= "table" or not tonumber(aw.u) or not R.Valid(aw.d) or r.f == "c" or r.ws then
					r.aw = nil
				else
					aw.u, aw.d = Int(aw.u), R.Valid(aw.d)
					if aw.k == nil then
						aw.a = math.max(0, math.min(R.MAX, R.Tenth(Int(aw.a))))
					else
						-- (31 October: his work flaw by flaw, as it was kept)
						aw.k = type(aw.k) == "string" and aw.k or ""
						aw.n = Int(aw.n)
						for _, f in ipairs({ "ok", "om", "mi" }) do
							if aw[f] ~= nil and type(aw[f]) ~= "string" then
								aw[f] = nil
							end
						end
					end
					aw.at = tonumber(aw.at) and Int(aw.at) or nil
					if aw.by ~= nil and type(aw.by) ~= "string" then
						aw.by = nil
					end
				end
			end
			if type(r) == "table" and r.r ~= nil then
				local kept = {}
				for _, x in ipairs(type(r.r) == "table" and r.r or {}) do
					if type(x) == "table" and tonumber(x[1]) and R.Valid(x[2]) then
						kept[CuratorOctoFull.Length(kept) + 1] = { Int(x[1]), R.Valid(x[2]), math.max(0, math.min(R.MAX, R.Tenth(Int(x[3])))) }
					end
				end
				r.r = CuratorOctoFull.Length(kept) > 0 and kept or nil
			end
		end
	end
	-- (1 November: the cards of the cases at the enchanters, the same)
	local CS = ns.Cases
	local c = db and CS and CS.Db and CS.Db()
	for _, w in ipairs(c and type(c.won) == "table" and c.won or {}) do
		if type(w) == "table" and w.aw ~= nil then
			local aw = w.aw
			if type(aw) ~= "table" or not tonumber(aw.u) or not R.Valid(aw.d) then
				w.aw = nil
			else
				aw.u, aw.d = Int(aw.u), R.Valid(aw.d)
				aw.k = type(aw.k) == "string" and aw.k or ""
				aw.n = Int(aw.n)
				for _, f in ipairs({ "ok", "om", "mi" }) do
					if aw[f] ~= nil and type(aw[f]) ~= "string" then
						aw[f] = nil
					end
				end
				aw.at = tonumber(aw.at) and Int(aw.at) or nil
				if aw.by ~= nil and type(aw.by) ~= "string" then
					aw.by = nil
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- The achievements of the restorations: after those of 1.13.0 before them (Achievements.lua, AC.After1130)
-------------------------------------------------------------------------------
local AC = ns.Achievements
if AC and AC.After1130 and AC.Define then
	AC.After1130(function()
		local function Done(_, db)
			return tonumber(type(db.stats) == "table" and db.stats.restoreDone) or 0
		end
		local ENGRAVE = { "Interface\\Icons\\Trade_Engraving" }
		AC.Define({ id = "rst1", cat = "collection", pts = 10, name = "A Fresh Coat", icon = ENGRAVE, goal = 1, value = Done,
			desc = function() return L["A copy restored by an enchanter."] end })
		AC.Define({ id = "rst10", cat = "collection", pts = 25, name = "Patron of the Enchanters", icon = ENGRAVE, goal = 10, value = Done,
			desc = function() return string.format(L["%d copies restored by the enchanters."], 10) end })
		AC.Define({ id = "rst10g", cat = "collection", pts = 25, name = "Better Than New", icon = { "Interface\\Icons\\INV_Enchant_ShardBrilliantLarge" },
			goal = 1, value = function(_, db) return tonumber(type(db.stats) == "table" and db.stats.restored10) or 0 end,
			desc = function() return L["A restored copy appraised 10."] end })
	end)
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
-- (UI/Gossip.lua: an enchanter in the window of dialogue)
ns.On("NPC_TALK", function(role, npc, name)
	if role == "enchanter" then
		R:SetEnchanter(true, name, npc)
	end
end)
ns.On("NPC_LEFT", function()
	if not R.training then
		R:SetEnchanter(false)
	end
end)

-- (the window of a trainer of the game: an enchanter, his trainer's window open)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED" }) do
			pcall(self.RegisterEvent, self, e)
		end
		R:Mend()
	elseif event == "TRAINER_SHOW" then
		local npc = ns.Gossip and ns.Gossip:NpcId()
		if R:IsEnchanter(npc) then
			R.training = true
			local name
			if UnitName then
				local ok, n = pcall(UnitName, "npc")
				if ok and type(n) == "string" and not Secret(n) then
					name = n
				end
			end
			R:SetEnchanter(true, name, npc)
		end
	elseif event == "TRAINER_CLOSED" then
		if R.training then
			R.training = nil
			R:SetEnchanter(false)
		end
	end
end)
