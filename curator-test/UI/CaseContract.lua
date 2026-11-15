local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local B = ns.Booster
local CR = ns.CrateUI

-------------------------------------------------------------------------------
-- (1.14.0, after its second test: « les contrats de caisses sur le bureau du notaire ») The contracts of the cards of
-- the cases on the desk of the notary (UI/Contract.lua), as the contracts of the boosters and never with them: ten cards
-- of a rank for one of the next, up to Covert (Cases.lua: CS:Contract). The same desk: on the left its ladder, from the
-- rare cards at its foot to the classified ones, the priceless card at its top out of reach (it comes out of a case
-- only), the copy kept of each card; in the middle the deed, its ten places in a ring around the card it promises, face
-- down (the back of its case), sealed once it is full; under the ring, where the new card comes from (the collection of
-- one of the cards given, as many chances as cards of it), the condition it will have (the average of the ten, as far as
-- their conditions tell it) and its finish (drawn as a case draws it), Sign and its quill; on the right the drawer of the
-- copies to spare (never an appraised one), a line a card, its collection, its copies; the collections they are taken
-- from, their order, Fill and Clear. A button under the desk goes from one desk to the other (A.ctKind: "case", else the
-- desk of the boosters).
-- Signed, the scene of the contracts (UI/Contract.lua, in the frame of the boosters): the parchment, the cards of the
-- cases melting into it, the seal, the fire; the new card rises out of it face down, a click turns it over in the light
-- of its rank (the thunder over a thunderforged card, the prism through a titanforged one), said in the chat.
-------------------------------------------------------------------------------
local G = A.CT
local GOLD = S.GOLD
-- the ladder: a rung a contract (a rank for the next one, rare to classified), the priceless card at its top
local RUNGS = 4
-- the cards of the cases of the desk: made this wide, scaled to their places
local BASE_W = ns.CARD_SIZES.small[1]
local BASE_H = BASE_W * 717 / 512
-- the gems of the ranks (UI/CaseDetail.lua: the same)
local GEM = { { "Gem3" }, { "Gem4" }, { "Gem4", { 1, 0.6, 0.86 } }, { "Gem6" }, { "Gem5" } }
local FIN_INK = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.86, 0.46 } }
local FIN_RANK = { titan = 2, thunder = 1 }
-- why a contract is not signed
local WHY = {
	count = "Ten cards of one rank are needed.",
	rank = "Ten cards of one rank are needed.",
	closed = "Curator is closed: no contract can be signed.",
	card = "One of these cards is not yours any more.",
	top = "No contract goes past Covert: a priceless card comes out of a case only.",
}

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Pct(p)
	local v = p * 100
	if math.abs(v - math.floor(v + 0.5)) < 0.05 then
		return string.format(("%d%%"), math.floor(v + 0.5))
	end
	return string.format(("%.1f%%"), v)
end

-- The words of a rank on a dark ground; on the parchment, its ink (its colour, darker).
local function Words(tier)
	local r = CR.RANKS[tier] or CR.RANKS[1]
	return r.text or r.color
end
local function Ink(tier)
	local c = (CR.RANKS[tier] or CR.RANKS[1]).color
	return { c[1] * 0.62, c[2] * 0.62, c[3] * 0.62 }
end

-- "10 × Rare  »  1 × Restricted", in the colours of the ranks (ink: written on the parchment).
local function Deal(rank, ink)
	local CS = ns.Cases
	local a, b = rank, math.min(CR.TOP, rank + 1)
	local ca, cb = ink and Ink(a) or Words(a), ink and Ink(b) or Words(b)
	return string.format(("%d × |cff%s%s|r  »  %d × |cff%s%s|r"), CS.CONTRACT, Hex(ca), L[CR.RANKS[a].label], 1, Hex(cb), L[CR.RANKS[b].label])
end

-- The name of the collection of an edition.
local function Coll(case)
	local CS = ns.Cases
	return L[(CS.COLLECTION and CS.COLLECTION[case]) or "Paladin Collection 2026"]
end

-- The gem of a rank on a texture.
local function Gem(tex, tier)
	local g = GEM[tier] or GEM[1]
	tex:SetTexture(MEDIA .. g[1])
	local t = g[2] or { 1, 1, 1 }
	tex:SetVertexColor(t[1], t[2], t[3])
end

-- The back of the cards of an edition, as the deed and the flights show it.
local function BackOf(case)
	local def = ns.Crates and ns.Crates[case]
	return def and def.art and def.art.back
end

local function Why(why)
	if why == "guard" and ns.Guard and ns.Guard.SHORT then
		return L[ns.Guard.SHORT]
	end
	-- (1.14.0, after its test, his word: this character a reroll, its words name the main: Reroll.lua)
	if why == "reroll" and ns.Reroll then
		return ns.Reroll:WhyNot("contracts")
	end
	return WHY[why or ""] and L[WHY[why]] or nil
end

-------------------------------------------------------------------------------
-- What is seen of a copy won: never the grade hidden in its condition
-------------------------------------------------------------------------------
-- How fine it looks: appraised, its grade (told); else nothing (31 October, his word: its condition never told, nor by
-- the order of its copies: it shows on it, its wear).
local function Looks(w)
	if w.ap then
		return 100 + (tonumber(w.g) or 0)
	end
	return 0
end

-- Plainer (a before b): the plainest first, the oldest of them first.
local function Plainer(a, b)
	local la, lb = Looks(a), Looks(b)
	if la ~= lb then
		return la < lb
	end
	local fa, fb = FIN_RANK[a.f or ""] or 0, FIN_RANK[b.f or ""] or 0
	if fa ~= fb then
		return fa < fb
	end
	return (a.i or 0) < (b.i or 0)
end

-- What is told of it: appraised, its grade; its finish before it; else a plain copy (31 October, his word: never its
-- condition in words, it shows on the card).
local function Said(w)
	local E = ns.Expertise
	local text = (w.ap and E) and E.Label(w.g) or nil
	if w.f and CR.FINISH_NAME[w.f] then
		local fin = "|cff" .. Hex(FIN_INK[w.f]) .. L[CR.FINISH_NAME[w.f]] .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or "") .. "|r"
		text = text and (fin .. "  ·  " .. text) or fin
	end
	return text or L["Normal copy"]
end


-- The number of a card in its collection (the order of its case), to sort the drawer album by album.
local NUMBERS = {}
local function Number(desc)
	local m = NUMBERS[desc.case]
	if not m then
		m = {}
		local own = ns.CrateItems and ns.CrateItems:Case(desc.case)
		local n = 0
		for r = 1, CR.TOP - 1 do
			for _, e in ipairs(own and own[r] or {}) do
				n = n + 1
				m[e.key] = n
			end
		end
		if own then
			NUMBERS[desc.case] = m
		end
	end
	return (desc.entry and m[desc.entry.key]) or 999
end

-- A card of a case of the desk dressed as a copy (w) or as its card (desc), set again only when it changes.
local function Dress(c, w, desc)
	local CD = ns.CaseDetail
	local sig = w and (tostring(w.i) .. ":" .. tostring(w.f) .. ":" .. ns.Cases.WearKey(w)) or desc.key
	if c.sig == sig then
		return
	end
	c.sig = sig
	local pick
	if w then
		desc = CD.DescOf(w)
		pick = CD.PickOf(desc, w)
	else
		pick = CD.PickOf(desc, nil)
	end
	c:Set(pick, CR.RANKS)
	local back = BackOf(desc.case)
	c:SetBack(back)
	c:SetLive(false)
end

-- Its name in the colour of its rank, its collection and its rank, what it is.
local function CardLines(tip, desc, w)
	local CD = ns.CaseDetail
	local tc = Words(desc.tier)
	tip:AddLine(CD.Name(desc), tc[1], tc[2], tc[3])
	tip:AddLine(Coll(desc.case) .. "  ·  " .. L[CR.RANKS[desc.tier].label], 0.7, 0.7, 0.72)
	local line = CD.Line(desc, w)
	if line ~= "" then
		tip:AddLine(line, 0.86, 0.86, 0.88, true)
	end
end

-------------------------------------------------------------------------------
-- The contract being written
-------------------------------------------------------------------------------
-- The desk of the cases is the one shown.
local function Case()
	return A.ctKind == "case" and ns.Cases ~= nil
end

-- Its rank, the copies given (their numbers, in the order given), why it was not signed.
function A:CctState()
	local st = self.cct
	if not st then
		st = { rank = 1, ids = {} }
		self.cct = st
	end
	return st
end

-- The copies to spare of the cards of a rank (of an edition; nil: of all of them), a line a card: { desc, case, tier,
-- list (its copies to spare, the plainest first), spare }. The copies to spare of a card: those not appraised, one kept
-- of each card when the player keeps one (its finest: an appraised copy before them). won: the copies won, when known.
function A:CctSpare(rank, case, won)
	local CS = ns.Cases
	local CD = ns.CaseDetail
	local by = {}
	for _, w in ipairs(won or CS:Won()) do
		if w.e and not w.w and tonumber(w.r) == rank and (not case or w.c == case) then
			local k = tostring(w.c) .. ":" .. tostring(w.e)
			local g = by[k]
			if not g then
				g = { all = 0, free = {} }
				by[k] = g
			end
			g.all = g.all + 1
			-- (1 November: a card at an enchanter stays out of them, Restore.lua)
			if not w.ap and type(w.aw) ~= "table" then
				g.free[CuratorOctoFull.Length(g.free) + 1] = w
			end
		end
	end
	local keep = (ns.db and ns.db.keepOne) and 1 or 0
	local out = {}
	for _, g in pairs(by) do
		table.sort(g.free, Plainer)
		local n = math.max(0, math.min(CuratorOctoFull.Length(g.free), g.all - keep))
		if n > 0 then
			local list = {}
			for i = 1, n do
				list[i] = g.free[i]
			end
			local desc = CD.DescOf(list[1])
			out[CuratorOctoFull.Length(out) + 1] = { desc = desc, case = desc.case, tier = rank, list = list, spare = n }
		end
	end
	return out
end

-- The contract as the copies are now: those given still won and still to spare, of its rank, once each, ten at most.
-- Its copies won by their numbers too.
function A:CctCheck(st)
	local CS = ns.Cases
	local won = CS:Won()
	local byId = {}
	for _, w in ipairs(won) do
		byId[w.i] = w
	end
	local room = {}
	for _, it in ipairs(self:CctSpare(st.rank, nil, won)) do
		for _, w in ipairs(it.list) do
			room[w.i] = true
		end
	end
	local keep, seen = {}, {}
	for _, id in ipairs(st.ids) do
		if room[id] and not seen[id] and CuratorOctoFull.Length(keep) < CS.CONTRACT then
			keep[CuratorOctoFull.Length(keep) + 1] = id
			seen[id] = true
		end
	end
	st.ids = keep
	return st, byId, won
end

-- The lines of the drawer, in its order: the most copies to spare first (the default), album by album, by name (then
-- collection by collection, in the order of the collection).
function A:CctList(st, won)
	local CS = ns.Cases
	local CD = ns.CaseDetail
	local list = self:CctSpare(st.rank, self.cctCase, won)
	local order = {}
	for i, ed in ipairs(CS:Editions()) do
		order[ed] = i
	end
	for _, it in ipairs(list) do
		it.at = Number(it.desc)
		it.ed = order[it.case] or 99
		it.name = CD.Name(it.desc) or ""
	end
	local sort = self.cctSort or "count"
	table.sort(list, function(a, b)
		if sort == "count" and a.spare ~= b.spare then
			return a.spare > b.spare
		end
		if sort == "name" and a.name ~= b.name then
			return a.name < b.name
		end
		if a.ed ~= b.ed then
			return a.ed < b.ed
		end
		if a.at ~= b.at then
			return a.at < b.at
		end
		return a.desc.key < b.desc.key
	end)
	return list
end

-- The collections the cards are taken from: all of them, or one of those with copies to spare in this rank.
local function Collections(rank)
	local CS = ns.Cases
	local list = { false }
	local won = CS:Won()
	for _, ed in ipairs(CS:Editions()) do
		if CuratorOctoFull.Length(A:CctSpare(rank, ed, won)) > 0 then
			list[CuratorOctoFull.Length(list) + 1] = ed
		end
	end
	return list
end

-------------------------------------------------------------------------------
-- The pieces of the desk that are the cases' own
-------------------------------------------------------------------------------
-- A rung of their ladder: the gem of the rank it gives in its medallion, the gem of the rank it takes, the copies to
-- spare on a chip, what it takes, what it gives, the contracts its copies make and how far the next one is. The last
-- one, at the top: the priceless card, out of reach, its padlock. Lit when chosen.
local function NewRung(page, r)
	local locked = r >= RUNGS
	local from, to = CR.RANKS[r], CR.RANKS[math.min(CR.TOP, r + 1)]
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, G.LAD_W, G.RUNG_H)
	b:SetPoint("TOPLEFT", 0, -2 - (RUNGS - r) * (G.RUNG_H + G.RUNG_GAP))
	Hud.Panel(b, G.RUNG_H)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 4, -4)
	b.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.07)
	local mx = 8 + G.MED / 2
	b.light = b:CreateTexture(nil, "BORDER", nil, 2)
	b.light:SetTexture(MEDIA .. "Glow")
	b.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.light, G.MED * 2, G.MED * 2)
	b.light:SetPoint("CENTER", b, "LEFT", mx, 0)
	b.light:SetVertexColor(to.color[1], to.color[2], to.color[3])
	b.light:SetAlpha(0)
	b.node = b:CreateTexture(nil, "ARTWORK")
	b.node:SetTexture(MEDIA .. "TrackNodeBig")
	CuratorOctoFull.SetSize(b.node, G.MED, G.MED)
	b.node:SetPoint("CENTER", b, "LEFT", mx, 0)
	b.gemTo = b:CreateTexture(nil, "ARTWORK", nil, 2)
	Gem(b.gemTo, math.min(CR.TOP, r + 1))
	CuratorOctoFull.SetSize(b.gemTo, 18, 18)
	b.gemTo:SetPoint("CENTER", b.node, "CENTER")
	b.gemFrom = b:CreateTexture(nil, "ARTWORK", nil, 3)
	Gem(b.gemFrom, r)
	CuratorOctoFull.SetSize(b.gemFrom, 12, 12)
	b.gemFrom:SetPoint("CENTER", b.node, "BOTTOMLEFT", 6, 6)
	local tx = 8 + G.MED + 9
	local tw = G.LAD_W - tx - 6
	local fc, tc = Words(r), Words(math.min(CR.TOP, r + 1))
	b.from = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.from:SetPoint("TOPLEFT", tx, -7)
	b.from:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.from, false)
	b.from:SetTextColor(fc[1], fc[2], fc[3])
	G.Fit(b.from, L[from.label], 10, tw)
	b.to = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.to:SetPoint("TOPLEFT", b.from, "BOTTOMLEFT", 0, -1)
	b.to:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.to, false)
	b.to:SetTextColor(tc[1], tc[2], tc[3])
	G.Fit(b.to, "» " .. L[to.label], 10, tw)
	b.makes = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.makes:SetPoint("TOPLEFT", b.to, "BOTTOMLEFT", 0, -2)
	b.makes:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.makes, false)
	b.rank, b.tw, b.locked = r, tw, locked
	if locked then
		-- the priceless card: it comes out of a case, never out of a contract
		CuratorOctoFull.SetDesaturated(b.node, true)
		b.node:SetVertexColor(0.6, 0.6, 0.62)
		CuratorOctoFull.SetDesaturated(b.gemTo, true)
		b.gemTo:SetAlpha(0.55)
		CuratorOctoFull.SetDesaturated(b.gemFrom, true)
		b.gemFrom:SetAlpha(0.55)
		b.lock = b:CreateTexture(nil, "OVERLAY", nil, 2)
		b.lock:SetTexture(MEDIA .. "Lock")
		CuratorOctoFull.SetSize(b.lock, 20, 20)
		b.lock:SetPoint("CENTER", b.node, "TOPRIGHT", -2, -4)
		b.from:SetAlpha(0.65)
		b.to:SetAlpha(0.65)
		G.Fit(b.makes, L["Must be earned"], 10, tw)
		b.makes:SetTextColor(G.DIM[1], G.DIM[2], G.DIM[3])
	else
		b.chip = b:CreateTexture(nil, "OVERLAY")
		b.chip:SetTexture(MEDIA .. "CircleMask")
		b.chip:SetVertexColor(0.03, 0.03, 0.05)
		b.chip:SetAlpha(0.92)
		CuratorOctoFull.SetSize(b.chip, 24, 17)
		b.chip:SetPoint("CENTER", b.node, "TOPRIGHT", 1, -4)
		b.count = Hud.Text(b, 10, "OUTLINE", "OVERLAY", 2)
		b.count:SetPoint("CENTER", b.chip, "CENTER", 0, 0)
		b.bar = Hud.XPBar(b, tw, 6, { 1, 0.74, 0.22 })
		b.bar:SetPoint("TOPLEFT", b.makes, "BOTTOMLEFT", 0, -3)
		b.bar.text:SetText("")
	end
	function b:SetSelected(on)
		self.on = on
		if not self.locked then
			local k = on and 1 or 0.72
			self.node:SetVertexColor(k, k, k)
			self.gemTo:SetAlpha(on and 1 or 0.8)
		end
		Hud.Each(self.glow, "SetAlpha", on and 0.85 or 0)
		if not on then
			self.light:SetAlpha(0)
		end
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:CctRank(r)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:CctRungTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end

-- (1 November, 11 h 47, his word: « mais tu as oublié le contrat des caisses ») An exchange of the cases at the top of
-- the desk redone (UI/Contract.lua, A:BuildDesk): its medallion (the gem of the rank it gives, the gem of the rank it
-- takes), what it takes and what it gives, the contracts its copies make. Lit when chosen.
local function NewCaseTile(page, r, w)
	local D = A.CTB
	local to = math.min(CR.TOP, r + 1)
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, w, D.TILE_H)
	Hud.Panel(b, D.TILE_H)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 4, -4)
	b.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.07)
	local med = 30
	local col = CR.RANKS[to].color
	b.light = b:CreateTexture(nil, "BORDER", nil, 2)
	b.light:SetTexture(MEDIA .. "Glow")
	b.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.light, med * 2, med * 2)
	b.light:SetPoint("CENTER", b, "LEFT", 7 + med / 2, 0)
	b.light:SetVertexColor(col[1], col[2], col[3])
	b.light:SetAlpha(0)
	b.node = b:CreateTexture(nil, "ARTWORK")
	b.node:SetTexture(MEDIA .. "TrackNodeBig")
	CuratorOctoFull.SetSize(b.node, med, med)
	b.node:SetPoint("CENTER", b, "LEFT", 7 + med / 2, 0)
	b.gemTo = b:CreateTexture(nil, "ARTWORK", nil, 2)
	Gem(b.gemTo, to)
	CuratorOctoFull.SetSize(b.gemTo, 16, 16)
	b.gemTo:SetPoint("CENTER", b.node, "CENTER")
	b.gemFrom = b:CreateTexture(nil, "ARTWORK", nil, 3)
	Gem(b.gemFrom, r)
	CuratorOctoFull.SetSize(b.gemFrom, 11, 11)
	b.gemFrom:SetPoint("CENTER", b.node, "BOTTOMLEFT", 5, 5)
	local tx = 7 + med + 6
	local tw = w - tx - 8
	b.deal = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.deal:SetPoint("TOPLEFT", tx, -8)
	b.deal:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.deal, false)
	G.Fit(b.deal, string.format(("|cff%s%s|r |cff9a9aa4»|r |cff%s%s|r"), Hex(Words(r)), L[CR.RANKS[r].label], Hex(Words(to)), L[CR.RANKS[to].label]), 10, tw)
	b.makes = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.makes:SetPoint("TOPLEFT", b.deal, "BOTTOMLEFT", 0, -3)
	b.makes:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.makes, false)
	b.rank, b.tw = r, tw
	function b:SetSelected(on)
		self.on = on
		local k = on and 1 or 0.72
		self.node:SetVertexColor(k, k, k)
		self.gemTo:SetAlpha(on and 1 or 0.8)
		Hud.Each(self.glow, "SetAlpha", on and 0.85 or 0)
		if not on then
			self.light:SetAlpha(0)
		end
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:CctRank(r)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:CctRungTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end

-- Made the first time the desk of the cases shows, on the desk redone (f.ctb): its exchanges at the top (a rank for
-- the next one, rare to classified: the priceless card comes out of a case only, its tooltip says so), the note in the
-- place of the finishes, a card of a case in each place of the deed and each line of the list.
function A:BuildCaseDesk(page)
	if page.caseRungs then
		return
	end
	local D = A.CTB
	local CS = ns.Cases
	local n = math.max(1, (CS and CS.CONTRACT_TOP or RUNGS) - 1)
	local tw = (G.PAGE_W - (n - 1) * D.TILE_GAP) / n
	page.caseRungs = {}
	for r = 1, n do
		local b = NewCaseTile(page, r, tw)
		b:SetPoint("TOPLEFT", (r - 1) * (tw + D.TILE_GAP), -2)
		page.caseRungs[r] = b
	end
	-- (the name of before: the rail of their ladder, nothing to show)
	page.caseRail = page:CreateTexture(nil, "BACKGROUND")
	page.caseRail:Hide()
	-- in the place of the finishes: what never goes into a contract of the cases (all it is, under the mouse)
	local note = CreateFrame("Frame", nil, page)
	note:SetPoint("TOPLEFT", page, "TOPLEFT", 2, D.CHIPS_Y)
	CuratorOctoFull.SetSize(note, G.PAGE_W - 170, D.CHIP_H)
	note.text = S.Text(note, "GameFontHighlightSmall", "LEFT")
	note.text:SetPoint("LEFT", 4, 0)
	note.text:SetWidth(G.PAGE_W - 178)
	CuratorOctoFull.SetWordWrap(note.text, false)
	note.text:SetTextColor(0.84, 0.8, 0.72)
	note:EnableMouse(true)
	CuratorOctoFull.SetScript(note, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L["Contracts of the cases"], 1, 1, 1)
		GameTooltip:AddLine(L["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."], 0.85, 0.85, 0.85, true)
		GameTooltip:AddLine(L["The appraised copies stay in your album: they never go into a contract."], GOLD[1], GOLD[2], GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(note, "OnLeave", function()
		GameTooltip:Hide()
	end)
	function note:SetText(t)
		G.Fit(self.text, t, 11, G.PAGE_W - 178)
	end
	note:Hide()
	page.caseNote = note
	-- the places of the deed, the lines of the list: a card of a case each, beside the card of the boosters
	for _, sl in ipairs(page.band.slots) do
		local c = ns.CrateCard.New(sl, BASE_W)
		c:SetScale(G.SLOT_W / BASE_W)
		c:SetPoint("CENTER", sl, "CENTER", 0, 0)
		c:Hide()
		sl.crate = c
		-- (the words of the place over it)
		local top = sl.n:GetParent()
		top:SetFrameLevel(c:GetFrameLevel() + 16)
	end
	local h = G.ROW_H - 6
	for _, row in ipairs(page.drawer.rows) do
		local c = ns.CrateCard.New(row, BASE_W)
		local k = h / BASE_H
		c:SetScale(k)
		c:SetPoint("LEFT", row, "LEFT", 6 / k, 0)
		c:Hide()
		row.crate = c
	end
	-- the exchange chosen breathes, as those of the boosters
	CuratorOctoFull.HookScript(page, "OnUpdate", function(self)
		if not self.caseOn then
			return
		end
		for _, b in ipairs(self.caseRungs) do
			if b.on then
				b.light:SetAlpha(0.45 + 0.2 * math.sin((self.t or 0) * 3))
			end
		end
	end)
	-- the menu under the ring: the collections, or the albums
	local menu = page.band.albums
	if menu.SetTooltip then
		menu:SetTooltip(function(tooltip)
			if Case() then
				tooltip:AddLine(L["All collections"], 1, 1, 1)
				tooltip:AddLine(L["The cards of every collection of the cases, or of one only (the arrows of the title too)."], GOLD[1], GOLD[2], GOLD[3], true)
			else
				tooltip:AddLine(L["All albums"], 1, 1, 1)
				tooltip:AddLine(L["The cards of every album, or of one only (the arrows of the title too)."], GOLD[1], GOLD[2], GOLD[3], true)
			end
		end)
	end
	-- Fill: what it takes here
	CuratorOctoFull.HookScript(page.drawer.tools.fill, "OnEnter", function(self)
		if Case() then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Fill"], 1, 1, 1)
			GameTooltip:AddLine(L["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end
	end)
end

-- The pieces of one desk shown, those of the other hidden (on: the desk of the cases). (1 November: on the desk redone,
-- f.ctb: its exchanges, the note in the place of the finishes; no register, no talent, one contract at a time.)
local function Pieces(page, on)
	if not page then
		return
	end
	if on then
		A:BuildCaseDesk(page)
	end
	local D = A.CTB
	local had = page.caseOn or false
	page.caseOn = on
	for _, b in ipairs(page.tiles) do
		CuratorOctoFull.SetShown(b, not on)
	end
	for _, b in pairs(page.fin) do
		CuratorOctoFull.SetShown(b, not on)
	end
	CuratorOctoFull.SetShown(page.regButton, not on)
	if on and A.ctPanel == "register" then
		A:DeskPanel(nil)
	end
	local deed = page.band
	CuratorOctoFull.SetShown(deed.acts, not on)
	CuratorOctoFull.SetShown(deed.mult, not on)
	if on then
		deed.clauseBtn:Hide()
		deed.cond:SetText("")
	end
	CuratorOctoFull.SetShown(deed.clauseIcon, not on)
	deed.clause:ClearAllPoints()
	if on then
		deed.clause:SetPoint("TOPLEFT", deed.from, "BOTTOMLEFT", 0, -12)
		deed.clause:SetWidth(D.SIDE_W)
	else
		deed.clause:SetPoint("TOPLEFT", deed.clauseIcon, "TOPRIGHT", 4, -2)
		deed.clause:SetWidth(D.SIDE_W - 22)
	end
	if page.caseRungs then
		for _, b in ipairs(page.caseRungs) do
			CuratorOctoFull.SetShown(b, on)
		end
		CuratorOctoFull.SetShown(page.caseNote, on)
		if not on then
			for _, sl in ipairs(deed.slots) do
				sl.crate:Hide()
				sl.cw = nil
			end
			for _, row in ipairs(page.drawer.rows) do
				row.crate:Hide()
				row.citem = nil
			end
		end
	end
	if had and not on then
		-- (the deed as the boosters have it: the back of their cards, their gems, their ink)
		deed.back:SetTexture(MEDIA .. "Back_S")
		deed.back:SetTexCoord(0, G.TEX_R, 0, 1)
		deed.gem:SetVertexColor(1, 1, 1)
		deed.getGem:SetVertexColor(1, 1, 1)
		deed.from:SetTextColor(G.INK[1], G.INK[2], G.INK[3])
	end
	if had ~= on then
		-- (the seal of a full deed comes down again for the contract shown)
		deed.full = nil
		deed.stamp:Hide()
		deed.stampGlow:SetAlpha(0)
	end
end

-- The button under the desk, from one desk to the other (made the first time the desk shows).
local function Switch()
	local f = A.frame
	if f.ctSwitch then
		return f.ctSwitch
	end
	local b = S.Button(f, "", 220, 22)
	b:SetPoint("BOTTOMRIGHT", -8, 4)
	b.icon = b:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(b.icon, 16, 16)
	b.icon:SetPoint("LEFT", 8, 0)
	CuratorOctoFull.SetScript(b, "OnClick", function()
		ns.Play(ns.SND.page)
		A.ctKind = (not Case()) and "case" or nil
		A.ctConfirm = nil
		GameTooltip:Hide()
		A:Refresh()
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		if Case() then
			GameTooltip:AddLine(L["Contracts of the boosters"], 1, 1, 1)
			GameTooltip:AddLine(L["Ten copies of a rarity make a card of the next one, up to legendary. Ten copies of a single album give a card that album is missing."], 0.8, 0.8, 0.8, true)
		else
			GameTooltip:AddLine(L["Contracts of the cases"], 1, 1, 1)
			GameTooltip:AddLine(L["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."], 0.8, 0.8, 0.8, true)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	f.ctSwitch = b
	-- (the album closed: the desk of the boosters the next time the contracts open by their tab)
	CuratorOctoFull.HookScript(f, "OnHide", function()
		A.ctKind = nil
	end)
	return b
end

local function PaintSwitch()
	local b = A.frame and A.frame.ctSwitch
	if not b then
		return
	end
	local case = Case()
	b:SetText(case and L["Contracts of the boosters"] or L["Contracts of the cases"])
	local icon = case and "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" or ns.CaseDetail.IconOf({ case = ns.Cases.EDITION })
	Hud.SetIcon(b.icon, { icon })
	local w = b.label and S.Width and S.Width(b.label, 0) or 150
	b:SetWidth(math.max(200, math.min(280, math.ceil(w) + 56)))
end

-------------------------------------------------------------------------------
-- Opened, chosen, filled
-------------------------------------------------------------------------------
-- The desk of the cases as it was left (after a contract signed: the next one filled).
function A:ShowCaseDesk()
	if not ns.Cases then
		return
	end
	self:Build()
	self.ctKind = "case"
	self.ctConfirm = nil
	if self.frame:IsShown() then
		self:SetMode("contract")
	else
		self:Open("contract")
	end
end

-- The copies of a card of a case to exchange into a contract (desc: its card; all those it has to spare, ten at most),
-- or the contracts of a collection (edition: the lowest rank it has enough copies to spare of for one; nil: all of them).
function A:CaseContractFor(desc, edition)
	local CS = ns.Cases
	if not CS then
		return
	end
	self:Build()
	if desc and not desc.weapon and (desc.tier or 99) < CS.CONTRACT_TOP then
		local st = { rank = desc.tier, ids = {} }
		for _, it in ipairs(self:CctSpare(desc.tier)) do
			if it.desc == desc then
				for _, w in ipairs(it.list) do
					if CuratorOctoFull.Length(st.ids) < CS.CONTRACT then
						st.ids[CuratorOctoFull.Length(st.ids) + 1] = w.i
					end
				end
			end
		end
		self.cct, self.cctCase = st, nil
		if CuratorOctoFull.Length(st.ids) > 0 then
			ns.Play(ns.SND.ink)
		end
	else
		local won = CS:Won()
		local best, most, mostN = nil, nil, 0
		for r = 1, CS.CONTRACT_TOP - 1 do
			local n = 0
			for _, it in ipairs(self:CctSpare(r, edition, won)) do
				n = n + it.spare
			end
			if n >= CS.CONTRACT and not best then
				best = r
			end
			if n > mostN then
				most, mostN = r, n
			end
		end
		self.cct, self.cctCase = { rank = best or most or 1, ids = {} }, (edition and CS:Known(edition)) and edition or nil
	end
	self.cctPage = 1
	self:ShowCaseDesk()
end

-- A rung clicked: a contract of that rank (the priceless card at the top: never).
function A:CctRank(r)
	local CS = ns.Cases
	if r >= CS.CONTRACT_TOP then
		ns.Play(ns.SND.close)
		return
	end
	local st = self:CctState()
	if st.rank ~= r then
		self.cct = { rank = r, ids = {} }
		self.cctPage = 1
		self.ctConfirm = nil
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

function A:CctSetCase(ed)
	if (ed or nil) == self.cctCase then
		return
	end
	self.cctCase = ed or nil
	-- (1 November: the contract written again from that collection, filled by itself)
	self.cct = { rank = self:CctState().rank, ids = {} }
	self.ctConfirm = nil
	self.cctPage = 1
	ns.Play(ns.SND.page)
	self:Refresh()
end

-- The empty places filled: the cards with the most copies to spare first (of the collections chosen), their plainest
-- copies first, never a forged one (quiet: no sound, no flight, the page as it is).
function A:CctFill(quiet)
	local CS = ns.Cases
	local st, _, won = self:CctCheck(self:CctState())
	local before = CuratorOctoFull.Length(st.ids)
	local inside = {}
	for _, id in ipairs(st.ids) do
		inside[id] = true
	end
	local list = self:CctSpare(st.rank, self.cctCase, won)
	table.sort(list, function(a, b)
		if a.spare ~= b.spare then
			return a.spare > b.spare
		end
		return a.desc.key < b.desc.key
	end)
	for _, it in ipairs(list) do
		for _, w in ipairs(it.list) do
			if CuratorOctoFull.Length(st.ids) >= CS.CONTRACT then
				break
			end
			if not inside[w.i] and not w.f then
				st.ids[CuratorOctoFull.Length(st.ids) + 1] = w.i
				inside[w.i] = true
			end
		end
	end
	local n = CuratorOctoFull.Length(st.ids) - before
	if quiet then
		return n
	end
	st.why = nil
	if n > 0 then
		ns.Play(ns.SND.ink)
		self.ctConfirm = nil
	else
		ns.Play(ns.SND.close)
	end
	self:Refresh()
	-- a few fly from the list into the ring (1 November: the desk redone, the list shown)
	local page = self.frame.ctb
	local back = BackOf(self.cctCase or CS.EDITION)
	for k = 1, math.min(n, 6) do
		local src = page and page.drawer:IsShown() and page.drawer.rows[k]
		local dst = page and page.band.slots[math.min(G.SLOTS, before + k)]
		if src and dst and src:IsShown() and dst:IsShown() then
			local col = CR.RANKS[st.rank].color
			Hud.Fly(back and (MEDIA .. back) or (MEDIA .. "Back_S"), src.crate, dst, 24, 0.36, nil, col, (k - 1) * 0.05,
				back and { coords = { 0, 1, 0, 717 / 1024 }, ratio = 717 / 512 } or G.CARD_FLY)
		end
	end
	return n
end

function A:CctClear()
	ns.Play(ns.SND.click)
	local st = self:CctState()
	st.ids, st.why = {}, nil
	-- (1 November: emptied by hand, it stays so)
	st.manual = true
	self.ctConfirm = nil
	self:Refresh()
end

-- A place of the ring clicked: its copy back in the drawer.
function A:CctTake(i)
	local st = self:CctState()
	if st.ids[i] then
		CuratorOctoFull.Remove(st.ids, i)
		st.why = nil
		-- (1 November: taken back by hand, not filled again by itself)
		st.manual = true
		self.ctConfirm = nil
		ns.Play(ns.SND.cardFlip)
		GameTooltip:Hide()
		self:Refresh()
	end
end

-- A line of the drawer clicked: its plainest copy not given yet into the contract (a shift-click: all of them, as the
-- contract takes them), a right click takes the last one given back.
function A:CctRowClick(row, button)
	local it = row.citem
	if not it then
		return
	end
	local CS = ns.Cases
	local st = self:CctCheck(self:CctState())
	st.why = nil
	-- (1 November: chosen by hand, not filled by itself any more)
	st.manual = true
	local mine = {}
	for _, w in ipairs(it.list) do
		mine[w.i] = true
	end
	local added = 0
	if button == "RightButton" then
		for i = CuratorOctoFull.Length(st.ids), 1, -1 do
			if mine[st.ids[i]] then
				CuratorOctoFull.Remove(st.ids, i)
				ns.Play(ns.SND.cardFlip)
				break
			end
		end
	else
		local inside = {}
		for _, id in ipairs(st.ids) do
			inside[id] = true
		end
		local all = IsShiftKeyDown and IsShiftKeyDown()
		for _, w in ipairs(it.list) do
			if CuratorOctoFull.Length(st.ids) >= CS.CONTRACT then
				break
			end
			if not inside[w.i] then
				st.ids[CuratorOctoFull.Length(st.ids) + 1] = w.i
				inside[w.i] = true
				added = added + 1
				if not all then
					break
				end
			end
		end
		ns.Play(added > 0 and ns.SND.ink or ns.SND.close)
	end
	self.ctConfirm = nil
	self:Refresh()
	-- the card flies into its place of the ring, which takes it with a pop
	if added > 0 then
		local page = self.frame.ctb
		local sl = page.band.slots[math.min(G.SLOTS, CuratorOctoFull.Length(st.ids))]
		local col = CR.RANKS[it.tier].color
		local back = BackOf(it.case)
		local card = sl.crate
		Hud.Fly(back and (MEDIA .. back) or (MEDIA .. "Back_S"), row.crate, sl, 28, 0.32, function()
			Hud.Burst(sl, col, 10, 90, 12)
			local base = G.SLOT_W / BASE_W
			ns.Tween(0.25, function(e)
				card:SetScale(base * (1.3 - 0.3 * e))
			end, function()
				card:SetScale(base)
			end, Ease.outBack, A)
		end, col, 0, back and { coords = { 0, 1, 0, 717 / 1024 }, ratio = 717 / 512 } or G.CARD_FLY)
	end
	if row:IsMouseOver() then
		self:CctRowTooltip(row)
	end
end

-- Two clicks to sign (the first asks to confirm, for a few seconds); signed, the album closes and the scene of the
-- contract plays (B:OpenCaseContract), the next contract ready (the same rank, filled with what is left).
function A:CctSign()
	local CS = ns.Cases
	local st, byId = self:CctCheck(self:CctState())
	if CuratorOctoFull.Length(st.ids) < CS.CONTRACT then
		return
	end
	-- (1.14.0, after its test, his word: a reroll signs none, the chat says why: Reroll.lua)
	if ns.Reroll and ns.Reroll:Blocks("contracts") then
		ns.Reroll:SayNot("contracts")
		return
	end
	local ok, why = CS:CanContract(st.ids)
	if not ok then
		st.why = why
		ns.Play(ns.SND.close)
		return self:Refresh()
	end
	if not (self.ctConfirm and GetTime() - self.ctConfirm < 4) then
		self.ctConfirm = GetTime()
		ns.Play(ns.SND.click)
		self:Refresh()
		ns.Delay(4.05, function()
			if A.ctConfirm and GetTime() - A.ctConfirm >= 4 then
				A.ctConfirm = nil
				if A.frame:IsShown() and A.mode == "contract" then
					A:Refresh()
				end
			end
		end, self)
		return
	end
	self.ctConfirm = nil
	local ids, given = {}, {}
	for i, id in ipairs(st.ids) do
		ids[i] = id
		given[i] = byId[id]
	end
	local rec, why2 = CS:Contract(ids)
	if not rec then
		st.why = why2
		ns.Play(ns.SND.close)
		return self:Refresh()
	end
	self.cct = { rank = st.rank, ids = {} }
	self:CctFill(true)
	self:Hide()
	B:OpenCaseContract(rec, given)
end

-------------------------------------------------------------------------------
-- Tooltips
-------------------------------------------------------------------------------
function A:CctRungTooltip(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Deal(b.rank, false), 1, 1, 1)
	if b.locked then
		GameTooltip:AddLine(L["No contract goes past Covert: a priceless card comes out of a case only."], 1, 0.6, 0.6, true)
		GameTooltip:Show()
		return
	end
	GameTooltip:AddLine(string.format(L["Copies to spare: %d"], b.found or 0), 1, 1, 1)
	if b.rank == RUNGS - 1 then
		GameTooltip:AddLine(L["No contract goes past Covert: a priceless card comes out of a case only."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:AddLine(L["Click: a contract of this rank"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

function A:CctRowTooltip(row)
	local it = row.citem
	if not it then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	CardLines(GameTooltip, it.desc)
	local used = it.used or 0
	GameTooltip:AddLine(string.format(L["To spare: %d"], it.spare - used), 1, 1, 1)
	if used > 0 then
		GameTooltip:AddLine(string.format(L["In the contract: %d"], used), 1, 0.86, 0.45)
	end
	-- its copies to spare: their conditions, the plainest first (the next one given first)
	local parts = {}
	for k, w in ipairs(it.list) do
		if k <= 5 then
			parts[CuratorOctoFull.Length(parts) + 1] = Said(w)
		end
	end
	if CuratorOctoFull.Length(it.list) > 5 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%d more"], CuratorOctoFull.Length(it.list) - 5)
	end
	GameTooltip:AddLine(string.format(L["Its copies to spare: %s"], table.concat(parts, ", ")), 0.8, 0.86, 1, true)
	GameTooltip:AddLine(L["Click: into the contract · Right click: take it back"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:AddLine(L["Shift-click: all its copies"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
	self:CctPaintRow(row, true)
end

function A:CctSlotTooltip(sl)
	local w = sl.cw
	if not w then
		return
	end
	local CD = ns.CaseDetail
	local desc = CD.DescOf(w)
	GameTooltip:SetOwner(sl, "ANCHOR_RIGHT")
	CardLines(GameTooltip, desc, w)
	GameTooltip:AddLine(Said(w), 1, 1, 1)
	local day = tonumber(w.t) and tonumber(w.t) > 0 and date("%d/%m/%Y", w.t) or nil
	GameTooltip:AddLine(ns.Cases.How(w) .. (day and ("  ·  " .. day) or ""), 0.62, 0.62, 0.66)
	GameTooltip:AddLine(L["Click: take it back"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

-- A line of the drawer: its bar and its light of gold while some of its copies are in the contract.
function A:CctPaintRow(row, hover)
	local it = row.citem
	local used = it and it.used or 0
	row.mark:SetAlpha(used > 0 and 1 or 0)
	row.glow:SetAlpha(used > 0 and (hover and G.HOVER or G.PICKED) or 0)
	if used > 0 then
		row.left:SetTextColor(1, 0.82, 0.32)
	else
		row.left:SetTextColor(1, 0.92, 0.75)
	end
end

-------------------------------------------------------------------------------
-- What the desk shows
-------------------------------------------------------------------------------
-- The exchanges at the top: each with the copies to spare of its rank (of every collection), the contracts they make;
-- the one chosen lit. In the place of the finishes, what never goes into a contract of the cases.
function A:CctLadder(page, st, won)
	local CS = ns.Cases
	for r, b in ipairs(page.caseRungs) do
		local n = 0
		for _, it in ipairs(self:CctSpare(r, nil, won)) do
			n = n + it.spare
		end
		b.found = n
		local text, enough = G.Makes(n, CS.CONTRACT)
		G.Fit(b.makes, text, 10, b.tw)
		if enough then
			b.makes:SetTextColor(G.GOLDEN[1], G.GOLDEN[2], G.GOLDEN[3])
		else
			b.makes:SetTextColor(G.DIM[1], G.DIM[2], G.DIM[3])
		end
		b:SetSelected(r == st.rank)
	end
	page.caseNote:SetText(L["The appraised copies stay in your album: they never go into a contract."])
end

-- The deed of the desk: its head, its places in the ring (a copy given each), the card it promises (sealed when it is
-- full); on its right, the cards given (by itself or by hand), what comes, where from, the condition and the finish it
-- will have; Sign at the foot.
function A:CctDeed(page, st, byId)
	local CS = ns.Cases
	local D = A.CTB
	local deed = page.band
	local cap = CS.CONTRACT
	local count = CuratorOctoFull.Length(st.ids)
	local full = count >= cap
	local up = math.min(CR.TOP, st.rank + 1)
	deed.title:SetText(L["Exchange contract"])
	G.Fit(deed.deal, Deal(st.rank, true), 12, D.DEED_W - 90)
	-- its places, in a ring
	for i, sl in ipairs(deed.slots) do
		CuratorOctoFull.SetShown(sl, i <= G.SLOTS)
		local x, y = D.RingXY(i, G.SLOTS)
		sl:ClearAllPoints()
		sl:SetPoint("CENTER", deed, "TOPLEFT", x, y)
		sl.group, sl.rest = nil, nil
		sl.card:Hide()
		sl.card.card = nil
		sl.more:SetText("")
		sl.n:SetText("")
		local w = byId[st.ids[i]]
		sl.cw = w
		if w then
			Dress(sl.crate, w)
			sl.crate:Show()
			sl.plus:Hide()
			sl.bg:SetAlpha(1)
		else
			sl.crate:Hide()
			CuratorOctoFull.SetShown(sl.plus, not full)
			sl.bg:SetAlpha(full and 0.45 or 1)
		end
	end
	-- the card it promises: the back of its case, the gem of its rank, its light, the lights of the copies given
	local first = byId[st.ids[1]]
	local back = BackOf((first and first.c) or self.cctCase or CS.EDITION)
	if back then
		deed.back:SetTexture(MEDIA .. back)
		deed.back:SetTexCoord(0, 1, 0, 717 / 1024)
	end
	Gem(deed.gem, up)
	local col = CR.RANKS[up].color
	deed.backGlow:SetVertexColor(col[1], col[2], col[3])
	if not full then
		deed.backGlow:SetAlpha(0.2 + 0.25 * count / cap)
	end
	for i, d in ipairs(deed.dots) do
		local a = math.pi / 2 - (i - 1) * 2 * math.pi / G.DOTS
		d:ClearAllPoints()
		d:SetPoint("CENTER", deed, "TOPLEFT", D.RING_X + G.DOT_R * math.cos(a), D.RING_Y + 4 + G.DOT_R * math.sin(a))
		d.glow:ClearAllPoints()
		d.glow:SetPoint("CENTER", d, "CENTER")
		CuratorOctoFull.SetShown(d, i <= G.DOTS)
		local on = i <= count
		if on then
			d:SetVertexColor(1, 0.84, 0.4)
			d:SetAlpha(1)
		else
			d:SetVertexColor(G.INK_SOFT[1], G.INK_SOFT[2], G.INK_SOFT[3])
			d:SetAlpha(0.5)
		end
		d.glow:SetAlpha(on and 0.55 or 0)
	end
	deed.ring:SetVertexColor(1, 0.86, 0.42)
	if deed.ringTw then
		ns.CancelTween(deed.ringTw)
		deed.ringTw = nil
	end
	if full and not deed.full and deed:IsVisible() then
		deed.ring:SetAlpha(0)
		deed.ringTw = ns.Tween(0.45, function(e)
			deed.ring:SetAlpha(e)
		end, function()
			deed.ringTw = nil
		end, Ease.outQuad, A)
	elseif full then
		deed.ring:SetAlpha(1)
	else
		deed.ring:SetAlpha(0)
	end
	G.Fit(deed.count, full and L["Ready to sign"] or string.format(L["%d / %d cards"], count, cap), 11, 92)
	if full and not deed.full then
		if deed:IsVisible() then
			Hud.Stamp(deed.stamp, 46, 0.05, function()
				ns.Play(ns.SND.seal)
				Hud.Burst(deed.stamp, { 1, 0.5, 0.4 }, 12, 100, 14)
			end, A)
		else
			CuratorOctoFull.SetSize(deed.stamp, 46, 46)
			deed.stamp:SetAlpha(1)
			deed.stamp:Show()
		end
	elseif not full then
		deed.stamp:Hide()
		deed.stampGlow:SetAlpha(0)
	end
	deed.full = full
	deed.glow:SetAlpha(full and 0.3 or 0.1)
	deed.glow:SetVertexColor(col[1], col[2], col[3])
	-- the collection the cards are taken from, the cards changed by hand
	deed.albums:GenerateMenu()
	deed.change:SetText(self.ctPanel == "drawer" and L["Close"] or L["Change the cards"])
	-- on its right: the cards given, chosen by itself or by hand
	if count == 0 and CuratorOctoFull.Length(self:CctSpare(st.rank, self.cctCase)) == 0 then
		deed.how:SetText(L["No card of this rank yet: they come out of the cases."])
	elseif count == 0 then
		deed.how:SetText(L["Choose ten cards of the same rank: click a card to put it in the contract."])
	else
		deed.how:SetText(st.manual and L["The cards you chose"] or L["Your least precious duplicates, chosen for you"])
	end
	-- what comes: its rank
	Gem(deed.getGem, up)
	local ink = Ink(up)
	deed.get:SetText(L[CR.RANKS[up].label])
	deed.get:SetTextColor(ink[1], ink[2], ink[3])
	-- where it comes from (the collections of the copies given, as many chances as copies of each); why the contract
	-- was not signed
	local why = st.why and Why(st.why)
	if why then
		deed.from:SetText(why)
		deed.from:SetTextColor(0.62, 0.14, 0.1)
	elseif count == 0 then
		deed.from:SetText("")
		deed.from:SetTextColor(G.INK[1], G.INK[2], G.INK[3])
	else
		local n, order = {}, {}
		for _, id in ipairs(st.ids) do
			local w = byId[id]
			if w then
				if not n[w.c] then
					order[CuratorOctoFull.Length(order) + 1] = w.c
				end
				n[w.c] = (n[w.c] or 0) + 1
			end
		end
		local parts = {}
		for _, ed in ipairs(order) do
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(("%s %d %%"), Coll(ed), math.floor(n[ed] / count * 100 + 0.5))
		end
		deed.from:SetText(string.format(L["The new card comes from: %s"], table.concat(parts, " · ")))
		deed.from:SetTextColor(G.INK[1], G.INK[2], G.INK[3])
	end
	-- the condition it will have, its finish
	local ws = {}
	for _, id in ipairs(st.ids) do
		ws[CuratorOctoFull.Length(ws) + 1] = byId[id]
	end
	local all = CuratorOctoFull.Length(ws) > 0
	for _, w in ipairs(ws) do
		if not w.ap then
			all = false
		end
	end
	local cond = all and L["Clause of the experts: all appraised, it comes appraised."] or L["Clause of the condition: the average wear of the copies given."]
	local _, fins = CS:Odds()
	local fp = {}
	for _, x in ipairs(fins or {}) do
		fp[x[1]] = x[2]
	end
	deed.clause:SetText(cond .. "\n\n" .. string.format(L["Its finish, drawn as a case draws it: titanforged %s, thunderforged %s."], Pct(fp.titan or 0), Pct(fp.thunder or 0)))
	deed.clause:SetTextColor(G.INK_SOFT[1], G.INK_SOFT[2], G.INK_SOFT[3])
	deed.clause.ok = false
	deed.cond:SetText("")
	-- (1.14.0, after its test, his word: a reroll signs none; why in the place of what comes, Reroll.lua: RR:Blocks)
	if ns.Reroll and ns.Reroll:Blocks("contracts") then
		deed.clause:SetText(ns.Reroll:WhyNot("contracts"))
		deed.clause:SetTextColor(0.62, 0.14, 0.1)
	end
	-- Sign
	local ok = full and CS:CanContract(st.ids) and true or false
	local confirming = ok and self.ctConfirm and GetTime() - self.ctConfirm < 4
	page.sign:SetLabel(confirming and L["Confirm?"] or L["Sign the contract"])
	CuratorOctoFull.SetEnabled(page.sign, ok)
	page.sign:SetPulse(ok)
	CuratorOctoFull.SetDesaturated(page.sign.quill, not ok)
	page.sign.quill:SetAlpha(ok and 1 or 0.6)
end

-- The list beside the deed (when shown): the cards with copies to spare (of the collection chosen), in its order, a
-- page of them; Fill and Clear.
function A:CctDrawer(page, st, won)
	local CS = ns.Cases
	local CD = ns.CaseDetail
	local D = A.CTB
	local dr = page.drawer
	if not dr:IsShown() then
		return
	end
	local list = self:CctList(st, won)
	local inside = {}
	for _, id in ipairs(st.ids) do
		inside[id] = true
	end
	local total = 0
	for _, it in ipairs(list) do
		total = total + it.spare
	end
	dr.total:SetText(ns.Num(total))
	dr.total.label = string.format(L["Copies to spare: %d"], total)
	for _, b in ipairs(dr.sorts) do
		local on = (self.cctSort or "count") == b.key
		Hud.Each(b.glow, "SetAlpha", on and 0.8 or 0)
		local c = on and { 1, 1, 1 } or GOLD
		b.text:SetTextColor(c[1], c[2], c[3])
	end
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / D.ROWS))
	self.cctPage = math.max(1, math.min(self.cctPage or 1, pages))
	local nameW = D.PANEL_W - 12 - (8 + (G.ROW_H - 6) * A.U.CW / A.U.CH + 6) - 40
	for i, row in ipairs(dr.rows) do
		local it = list[(self.cctPage - 1) * D.ROWS + i]
		row.card:Hide()
		row.card.card, row.item = nil, nil
		if it then
			row:Show()
			Dress(row.crate, nil, it.desc)
			row.crate:Show()
			local tc = Words(it.tier)
			S.Fit(row.name, CD.Name(it.desc) or "?", nameW, 11, 8)
			row.name:SetTextColor(tc[1], tc[2], tc[3])
			S.Fit(row.album, Coll(it.case), nameW, 10, 8)
			local used = 0
			for _, w in ipairs(it.list) do
				if inside[w.i] then
					used = used + 1
				end
			end
			it.used = used
			local left = it.spare - used
			row.left:SetText("x" .. left)
			row.used:SetText(used > 0 and ("+" .. used) or "")
			row:SetAlpha(left > 0 and 1 or 0.5)
			row.citem = it
			self:CctPaintRow(row, row:IsMouseOver())
		else
			row:Hide()
			row.crate:Hide()
			row.citem = nil
		end
	end
	dr.empty:SetText(CuratorOctoFull.Length(list) == 0 and L["No card of this rank yet: they come out of the cases."] or "")
	dr.pages:SetText(string.format(("%d / %d"), self.cctPage, pages))
	CuratorOctoFull.SetEnabled(dr.prev, self.cctPage > 1)
	CuratorOctoFull.SetEnabled(dr.next, self.cctPage < pages)
	local free = false
	for _, it in ipairs(list) do
		for _, w in ipairs(it.list) do
			free = free or (not inside[w.i] and not w.f)
		end
	end
	CuratorOctoFull.SetEnabled(dr.tools.fill, CuratorOctoFull.Length(st.ids) < CS.CONTRACT and free)
	CuratorOctoFull.SetEnabled(dr.tools.clear, CuratorOctoFull.Length(st.ids) > 0)
end

function A:RefreshCaseContract()
	local f = self.frame
	self:BuildDesk()
	local page = f.ctb
	local CS = ns.Cases
	-- (1 November, his word: filled by itself, the plainest copies first, as the contract of the boosters; not once
	-- chosen by hand)
	local st0 = self:CctState()
	if not st0.manual and CuratorOctoFull.Length(st0.ids) < CS.CONTRACT then
		self:CctFill(true)
	end
	local st, byId, won = self:CctCheck(self:CctState())
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	f.wait:Hide()
	f.boosters:Hide()
	f.gauge:Hide()
	f.open:Hide()
	-- (the list has its own pages)
	self:ShowPager(false)
	-- title: the collection the cards are taken from, or all of them; the bar of the head: the contract filling up
	self:SetTitle(self.cctCase and Coll(self.cctCase) or L["Exchange contract"], Deal(st.rank, false))
	self:SetBar(CuratorOctoFull.Length(st.ids), CS.CONTRACT, string.format(L["%d / %d cards"], CuratorOctoFull.Length(st.ids), CS.CONTRACT))
	page.keep:SetChecked(ns.db.keepOne and true or false)
	self:CctLadder(page, st, won)
	self:CctDeed(page, st, byId)
	self:CctDrawer(page, st, won)
end

-------------------------------------------------------------------------------
-- The desk of the boosters, wrapped: what is the cases' own goes to them
-------------------------------------------------------------------------------
do
	local refresh = A.RefreshContract
	function A:RefreshContract(...)
		local case = Case()
		-- (1 November: the desk redone, the same for both, UI/Contract.lua: A:BuildDesk)
		self:BuildDesk()
		Pieces(self.frame.ctb, case)
		PaintSwitch()
		if case then
			return self:RefreshCaseContract()
		end
		return refresh(self, unpack(arg, 1, arg.n))
	end

	local showPage = A.ShowContractPage
	function A:ShowContractPage(shown, ...)
		showPage(self, shown, unpack(arg, 1, arg.n))
		if shown or (self.frame and self.frame.ctSwitch) then
			CuratorOctoFull.SetShown(Switch(), (shown and ns.Cases ~= nil) and true or false)
		end
	end

	local contractPage = A.ContractPage
	function A:ContractPage(delta, ...)
		if not Case() then
			return contractPage(self, delta, unpack(arg, 1, arg.n))
		end
		local list = self:CctList(self:CctState())
		local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / A.CTB.ROWS))
		local p = math.max(1, math.min(pages, (self.cctPage or 1) + delta))
		if p ~= self.cctPage then
			self.cctPage = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
	end

	local step = A.StepContractAlbum
	function A:StepContractAlbum(delta, ...)
		if not Case() then
			return step(self, delta, unpack(arg, 1, arg.n))
		end
		local list = Collections(self:CctState().rank)
		local cur = 1
		for i, ed in ipairs(list) do
			if ed == (self.cctCase or false) then
				cur = i
			end
		end
		self.cctCase = list[CuratorOctoFull.Mod((cur - 1 + delta) , CuratorOctoFull.Length(list)) + 1] or nil
		self.cctPage = 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end

	local setSort = A.SetContractSort
	function A:SetContractSort(key, ...)
		if not Case() then
			return setSort(self, key, unpack(arg, 1, arg.n))
		end
		if (self.cctSort or "count") == key then
			return
		end
		self.cctSort = key
		self.cctPage = 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end

	local menu = A.ContractAlbumsMenu
	function A:ContractAlbumsMenu(root, ...)
		if not Case() then
			return menu(self, root, unpack(arg, 1, arg.n))
		end
		for _, ed in ipairs(Collections(self:CctState().rank)) do
			root:CreateRadio(ed and Coll(ed) or L["All collections"], function(x)
				return (A.cctCase or false) == x
			end, function(x)
				A:CctSetCase(x or nil)
			end, ed)
		end
	end

	local fill = A.FillContract
	function A:FillContract(...)
		if Case() then
			return self:CctFill()
		end
		return fill(self, unpack(arg, 1, arg.n))
	end

	local clear = A.ClearContract
	function A:ClearContract(...)
		if Case() then
			return self:CctClear()
		end
		return clear(self, unpack(arg, 1, arg.n))
	end

	local sign = A.SignContract
	function A:SignContract(...)
		if Case() then
			return self:CctSign()
		end
		return sign(self, unpack(arg, 1, arg.n))
	end

	local take = A.TakeContract
	function A:TakeContract(i, ...)
		if Case() then
			return self:CctTake(i)
		end
		return take(self, i, unpack(arg, 1, arg.n))
	end

	local slotTip = A.SlotContractTooltip
	function A:SlotContractTooltip(sl, i, ...)
		if Case() then
			return self:CctSlotTooltip(sl)
		end
		return slotTip(self, sl, i, unpack(arg, 1, arg.n))
	end

	local choose = A.ChooseContractCopies
	function A:ChooseContractCopies(...)
		if Case() then
			return
		end
		return choose(self, unpack(arg, 1, arg.n))
	end

	local rowClick = A.ContractRowClick
	function A:ContractRowClick(row, button, ...)
		if Case() then
			return self:CctRowClick(row, button)
		end
		return rowClick(self, row, button, unpack(arg, 1, arg.n))
	end

	local rowTip = A.ContractRowTooltip
	function A:ContractRowTooltip(row, ...)
		if Case() then
			return self:CctRowTooltip(row)
		end
		return rowTip(self, row, unpack(arg, 1, arg.n))
	end

	local paintRow = A.PaintRow
	function A:PaintRow(row, hover, ...)
		if Case() then
			return self:CctPaintRow(row, hover)
		end
		return paintRow(self, row, hover, unpack(arg, 1, arg.n))
	end
end

-- (a case opened, a card appraised, a contract signed: the desk as the cards are now)
ns.On("CASES_CHANGED", function()
	local f = A.frame
	if f and f:IsShown() and A.mode == "contract" and Case() then
		A:Refresh()
	end
end)

-------------------------------------------------------------------------------
-- The scene of a contract of the cards of the cases, in the frame of the boosters (UI/Contract.lua: B:ContractTimeline
-- plays it, B.mode "caseContract")
-------------------------------------------------------------------------------
local SC = B.CT
-- the card that comes: its width, its place (from the middle of the scene)
local WON_W = 210
local WON_H = WON_W * 717 / 512
local WON_Y = 60

-- The sounds of a rank turned over (as a card comes out of a case, UI/Crate.lua).
local function Fanfare(tier)
	local S_ = ns.SND
	local list = ({
		{ S_.reveal[3] },
		{ S_.reveal[4] },
		{ S_.reveal[5], S_.impact[4] },
		{ S_.reveal[6], S_.impact[5], S_.rumble },
	})[tier] or {}
	for _, snd in ipairs(list) do
		ns.Play(snd)
	end
end

local function FontOf(parent, size)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	ns.SetFont(fs, size, "OUTLINE")
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 0.8)
	return fs
end

-- A copy given, around the parchment (its card made the first time): as it was given.
function B:CaseGiven(i, w)
	local ct = self.frame.ct
	ct.crates = ct.crates or {}
	local c = ct.crates[i]
	if not c then
		c = ns.CrateCard.New(ct, BASE_W)
		c:Hide()
		ct.crates[i] = c
	end
	c.sig = nil
	Dress(c, w)
	c.tier = tonumber(w.r) or 1
	c.hot:SetAlpha(0)
	return c
end

-- The card that comes, its place to click, its words (made the first time).
function B:CaseWonCard()
	local s = self.frame
	local ct = s.ct
	if ct.won then
		return ct.won
	end
	local st = s.stage
	local c = ns.CrateCard.New(st, WON_W)
	c:SetFrameLevel(st:GetFrameLevel() + 3)
	c:Hide()
	c.slotX, c.slotY, c.lift = 0, WON_Y, 0
	ct.won = c
	local hit = CreateFrame("Button", nil, st)
	CuratorOctoFull.SetSize(hit, WON_W, WON_H)
	hit:SetFrameLevel(c:GetFrameLevel() + 24)
	hit:SetPoint("CENTER", c, "CENTER")
	CuratorOctoFull.SetScript(hit, "OnClick", function()
		B:CaseReveal()
	end)
	CuratorOctoFull.SetScript(hit, "OnEnter", function()
		B:CaseHover(true)
	end)
	CuratorOctoFull.SetScript(hit, "OnLeave", function()
		B:CaseHover(false)
	end)
	hit:Hide()
	ct.wonHit = hit
	-- its words under it: its name, its rank and its collection, its condition and its finish
	ct.wonName = FontOf(ct, 21)
	ct.wonName:SetPoint("CENTER", s, "CENTER", 0, WON_Y - WON_H / 2 - 34)
	ct.wonRank = FontOf(ct, 13)
	ct.wonRank:SetPoint("TOP", ct.wonName, "BOTTOM", 0, -5)
	ct.wonExtra = FontOf(ct, 13)
	ct.wonExtra:SetPoint("TOP", ct.wonRank, "BOTTOM", 0, -4)
	for _, fs in ipairs({ ct.wonName, ct.wonRank, ct.wonExtra }) do
		fs:SetAlpha(0)
	end
	-- (waiting face down, a click anywhere turns it over: not the click that cut the ceremony short)
	CuratorOctoFull.HookScript(s, "OnMouseDown", function()
		if B.state == "caseCard" and GetTime() - (B.caseReadyAt or 0) > 0.2 then
			B:CaseReveal()
		end
	end)
	return c
end

-- The card where it is (its float, how far it rises under the mouse).
local function Place(self, c)
	local k = c:GetScale()
	if not k or k <= 0 then
		k = 1
	end
	c:ClearAllPoints()
	c:SetPoint("CENTER", self.frame.stage, "CENTER", 0, (WON_Y + (c.lift or 0) + (c.bob or 0)) / k)
end

-- The card that came, dressed face down: the back of its case.
function B:CaseDress()
	local c = self:CaseWonCard()
	local res = self.result
	c.sig = nil
	Dress(c, res.rec)
	c:SetLive(false)
	c.hot:SetAlpha(0)
	c.lift, c.bob, c.free = 0, 0, false
	return c
end

-- The scene as it was: no card of a case, no words (B:ContractReset).
function B:CaseContractReset()
	local ct = self.frame and self.frame.ct
	if not (ct and ct.won) then
		return
	end
	ns.CancelOwner(ct.won)
	ct.won:SetPose(0, 0)
	ct.won:SetScale(1)
	ct.won:Hide()
	ct.wonHit:Hide()
	for _, fs in ipairs({ ct.wonName, ct.wonRank, ct.wonExtra }) do
		fs:SetAlpha(0)
	end
end

-- A contract of the cards of the cases signed (rec: the card that came; given: the copies given, as they were): the
-- scene of the contract, its card face down at its end.
function B:OpenCaseContract(rec, given)
	if not rec then
		return
	end
	self:Build()
	local s = self.frame
	self:BuildContractScene()
	self.opts = {}
	self:ApplySize()
	self:ResetScene()
	self.mode = "caseContract"
	self.picks = {}
	local CD = ns.CaseDetail
	local up = tonumber(rec.r) or 2
	local rank = math.max(1, up - 1)
	local desc = CD.DescOf(rec)
	-- (its copies now: one, a new card)
	local copies = CuratorOctoFull.Length(CD:Copies(desc))
	self.result = { rank = rank, up = up, given = given or {}, rec = rec, desc = desc, n = 1, new = copies <= 1, copies = copies,
		line = Deal(rank, true) }
	local def = ns.Crates and ns.Crates[rec.c]
	self:SetBackdrop({ studio = (def and def.art and def.art.studio) or "StudioScarlet" })
	s.halo:SetVertexColor(1, 0.85, 0.6)
	s.pack:Hide()
	s.title:SetText(L["Exchange contract"])
	s.subtitle:SetText(Deal(rank, false))
	s.counter:SetText("")
	s.hint:SetText("")
	for _, c in ipairs(self.cards) do
		c:Hide()
	end
	self:CaseWonCard()
	self.state = "contract"
	if not s:IsShown() then
		s:SetAlpha(0)
		s:Show()
		ns.Tween(0.25, function(e)
			s:SetAlpha(e)
		end, nil, Ease.outQuad, self)
	end
	self:ContractTimeline()
end

-- Out of the fire, the new card rises to its place, face down, wavering.
function B:CaseContractDeal()
	if self.state ~= "contract" then
		return
	end
	local s = self.frame
	s.ct.paper:Hide()
	self.state = "caseDeal"
	local c = self:CaseDress()
	local col = CR.RANKS[self.result.up].color
	local y0 = SC.CT_Y
	ns.Play(ns.SND.whoosh)
	c:SetAlpha(0)
	c:SetPose(math.pi, 0)
	c:Show()
	local nextSpark = 0
	ns.Tween(0.6, function(e, raw)
		local k = 0.4 + 0.6 * e
		local y = y0 + (WON_Y - y0) * e
		c:SetScale(k)
		c:ClearAllPoints()
		c:SetPoint("CENTER", s.stage, "CENTER", 0, y / k)
		c:SetAlpha(math.min(1, raw * 4))
		-- (its back to the eye all the way: it wavers, it never shows its face)
		c:SetPose(math.pi + 0.55 * math.sin(raw * math.pi * 3) * (1 - e), 0.16 * math.sin(raw * math.pi))
		if raw >= nextSpark then
			nextSpark = raw + 0.08
			self.particles:Burst(0, y, col, 1, 30, 0.45, 20, 1, 0.3)
		end
	end, function()
		c:SetScale(1)
		c:SetPose(math.pi, 0)
		Place(self, c)
		ns.Play(ns.SND.cardLand)
		self:Ring(0, WON_Y - WON_H / 2 + 10, col, 320, 0.45, 0.5, 0, "Shock", 0.3)
		self.puffs:Burst(0, WON_Y - WON_H / 2, { 0.5, 0.42, 0.32 }, 2, 50, 0.6, 50, 0.3, 1.4)
		self:CaseWaiting()
	end, Ease.outCubic, self)
end

-- The ceremony cut short: the card at its place at once, face down.
function B:CaseContractReady()
	if self.state ~= "contract" then
		return
	end
	local s = self.frame
	s.ct.paper:Hide()
	local c = self:CaseDress()
	c:SetScale(1)
	c:SetAlpha(1)
	c:SetPose(math.pi, 0)
	c:Show()
	Place(self, c)
	self:CaseWaiting()
end

-- It waits to be turned over: its light behind it for the finest ranks, the hint.
function B:CaseWaiting()
	local s = self.frame
	local ct = s.ct
	local c = ct.won
	local up = self.result.up
	self.state = "caseCard"
	self.caseReadyAt = GetTime()
	c.free = true
	ct.wonHit:Show()
	if up >= 3 then
		local col = CR.RANKS[up].color
		local r1 = s.rays
		r1:SetVertexColor(col[1], col[2], col[3])
		r1.on, r1.card = true, c
		B.U.GlowTo(r1, up >= 4 and 0.32 or 0.2, 0.6, self)
	end
	s.hint:SetText(L["Click the card to reveal it"])
	B.U.FadeIn(s.hint, 0.3, self)
end

-- Under the mouse: face down, a light on it; turned over, its story.
function B:CaseHover(on)
	local ct = self.frame and self.frame.ct
	local c = ct and ct.won
	if not c then
		return
	end
	if self.state == "caseCard" then
		c.hot:SetVertexColor(1, 0.95, 0.85)
		B.U.GlowTo(c.hot, on and 0.14 or 0, 0.15, self)
	elseif self.state == "caseDone" and on then
		local res = self.result
		GameTooltip:SetOwner(ct.wonHit, "ANCHOR_RIGHT")
		CardLines(GameTooltip, res.desc, res.rec)
		GameTooltip:AddLine(Said(res.rec), 1, 1, 1)
		GameTooltip:AddLine(L["From an exchange contract"], 0.62, 0.62, 0.66)
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

-- A click: it turns over, rising a little toward the eye.
function B:CaseReveal()
	if self.state ~= "caseCard" then
		return
	end
	local s = self.frame
	local ct = s.ct
	local c = ct.won
	self.state = "caseReveal"
	c.free = false
	ct.wonHit:Hide()
	GameTooltip:Hide()
	s.hint:SetText("")
	c.hot:SetAlpha(0)
	ns.Play(ns.SND.cardFlip)
	local y = WON_Y + (c.lift or 0) + (c.bob or 0)
	ns.Tween(0.45, function(e, raw)
		local lift = math.sin(raw * math.pi)
		c:SetPose(math.pi * (1 - e), 0.22 * lift)
		local k = 1 + 0.08 * lift
		c:SetScale(k)
		c:ClearAllPoints()
		c:SetPoint("CENTER", s.stage, "CENTER", 0, (y + (WON_Y - y) * e + 14 * lift) / k)
	end, function()
		c:SetScale(1)
		c:SetPose(0, 0)
		c.lift, c.bob = 0, 0
		c.free = true
		Place(self, c)
		c:SetLive(true)
		self:CaseRevealed()
	end, Ease.outCubic, self)
end

-- Turned over: the light of its rank, its finish (the thunder, the prism), in the chat; its words, then the buttons.
function B:CaseRevealed()
	local s = self.frame
	local ct = s.ct
	local c = ct.won
	local res = self.result
	local rec, desc = res.rec, res.desc
	local tier = res.up
	local col = CR.RANKS[tier].color
	local x, y = 0, WON_Y
	Fanfare(tier)
	c.hot:SetVertexColor(1, 1, 1)
	c.hot:SetAlpha(0.6)
	B.U.GlowTo(c.hot, 0, 0.5, self)
	self:Ring(x, y, col, 420 + 80 * tier, 0.55, 0.7, 0, "Shock")
	self.particles:Burst(x, y, col, 14 + 6 * tier, 220, 0.8, 16)
	self.stars:Burst(x, y, col, 4 + 2 * tier, 160, 0.9, 18)
	if tier >= 3 then
		self:Flash(col, 0.18 + 0.08 * (tier - 3), 0.45)
		self:Shake(0.3, 3 + 3 * (tier - 3))
		self:Punch(0.02 + 0.01 * (tier - 3), 0.35)
	end
	local r1 = s.rays
	r1:SetVertexColor(col[1], col[2], col[3])
	r1.on, r1.card = true, c
	B.U.GlowTo(r1, ({ 0.2, 0.28, 0.4, 0.55 })[tier] or 0.3, 0.6, self)
	-- its finish: the thunder strikes a thunderforged card, the light of the prism goes through a titanforged one
	if rec.f == "thunder" then
		ns.Delay(0.25, function()
			self:Thunderstrike(c, x, y)
		end, self)
	elseif rec.f == "titan" and self.TitanStrike then
		ns.Delay(0.25, function()
			self:TitanStrike(c, x, y)
		end, self)
	end
	-- its creature, its spell, its armour: its sound (the cards of the case of the month)
	if desc.entry and ns.CrateItems and ns.CrateItems.Play then
		ns.Delay(0.4, function()
			ns.CrateItems:Play(desc.entry, self)
		end, self)
	end
	self:CaseTold()
	-- its words: its name in the colour of its rank, its rank and its collection, its condition and its finish
	local tc = Words(tier)
	ct.wonName:SetText(ns.CaseDetail.Name(desc))
	ct.wonName:SetTextColor(tc[1], tc[2], tc[3])
	ct.wonRank:SetText(L[CR.RANKS[tier].label] .. "  ·  " .. Coll(rec.c))
	ct.wonRank:SetTextColor(col[1], col[2], col[3])
	ct.wonExtra:SetText(Said(rec))
	ct.wonExtra:SetTextColor(0.92, 0.92, 0.94)
	for k, fs in ipairs({ ct.wonName, ct.wonRank, ct.wonExtra }) do
		local k, fs = k, fs; ns.Tween(0.3, function(e)
			fs:SetAlpha(e)
		end, nil, Ease.outQuad, self, 0.3 + 0.12 * (k - 1))
	end
	ns.Delay(0.95, function()
		self:CaseDone()
	end, self)
end

-- The card that came, in the chat, once (turned over, or the scene closed before).
function B:CaseTold()
	local res = self.result
	if self.mode ~= "caseContract" or not (res and res.rec) or res.told then
		return
	end
	res.told = true
	local rec = res.rec
	local tier = tonumber(rec.r) or 1
	local what = "|cff" .. Hex(Words(tier)) .. (ns.CaseDetail.Name(res.desc) or "?") .. "|r"
	-- (31 October: its finish, its grade when it came appraised; never its condition in words)
	local parts = {}
	if rec.f and CR.FINISH_NAME[rec.f] then
		parts[CuratorOctoFull.Length(parts) + 1] = L[CR.FINISH_NAME[rec.f]] .. (ns.Mages and ns.Mages.Tag(rec, true, true) and ("  ·  " .. ns.Mages.Tag(rec, true, true)) or "")
	end
	if rec.ap and ns.Expertise then
		parts[CuratorOctoFull.Length(parts) + 1] = ns.Expertise.Label(rec.g)
	end
	if CuratorOctoFull.Length(parts) > 0 then
		ns.Print(L["Out of an exchange contract: %s (%s, %s)."], what, L[CR.RANKS[tier].label], table.concat(parts, ", "))
	else
		ns.Print(L["Out of an exchange contract: %s (%s)."], what, L[CR.RANKS[tier].label])
	end
end

-- The end: a new card or its copies, then New contract, Album, Close.
function B:CaseDone()
	if self.state ~= "caseReveal" then
		return
	end
	local s = self.frame
	local res = self.result
	self.state = "caseDone"
	s.ct.wonHit:Show()
	s.summary:SetText(res.new and L["New card!"] or string.format(L["Copies: %d"], res.copies or 1))
	B.U.FadeIn(s.summary, 0.3, self)
	CuratorOctoFull.SetEnabled(s.again, true)
	s.again:SetLabel(L["New contract"])
	s.album:SetLabel(L["Album"])
	B.U.FadeIn(s.album, 0.3, self)
	B.U.FadeIn(s.close, 0.3, self)
	s.again:Show()
	s.again:SetAlpha(1)
end

-- Album: the card that came, big, in the album of its collection (UI/CaseDetail.lua).
function B:CaseAlbum()
	local rec = self.result and self.result.rec
	local Al = ns.Album
	if rec and Al.ShowCaseCopy and Al:ShowCaseCopy(rec.i) then
		return
	end
	if Al.ShowCases then
		Al:ShowCases(rec and rec.c)
	end
end

do
	-- (every frame: the card waiting floats, rises a little under the mouse)
	local tick = B.Tick
	function B:Tick(elapsed, ...)
		tick(self, elapsed, unpack(arg, 1, arg.n))
		if self.mode ~= "caseContract" then
			return
		end
		local ct = self.frame.ct
		local c = ct and ct.won
		if not (c and c:IsShown() and c.free) then
			return
		end
		local waiting = self.state == "caseCard"
		local want = (waiting and ct.wonHit:IsMouseOver()) and 10 or 0
		c.lift = (c.lift or 0) + (want - (c.lift or 0)) * math.min(1, elapsed * 10)
		c.bob = waiting and math.sin((self.t or 0) * 1.7) * 2.5 or 0
		Place(self, c)
	end

	-- (the scene closed before the card was turned over: in the chat all the same)
	local cleanup = B.Cleanup
	function B:Cleanup(...)
		self:CaseTold()
		return cleanup(self, unpack(arg, 1, arg.n))
	end
end
