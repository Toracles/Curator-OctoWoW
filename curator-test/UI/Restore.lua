local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local C = ns.Collection
local E = ns.Expertise
local R = ns.Restore
local RB = ns.Rubies
local XU = ns.ExpertiseUI

-------------------------------------------------------------------------------
-- (1.13.0) The restoration on the screen (Restore.lua). At an enchanter (his window of dialogue, or his window of a
-- trainer), a small window of Curator beside his: the copies at the enchanters, those ready, the button to pick them
-- up (his words, a little light), the way to the album. In the album, a card of mine shown big gets, for its copy
-- chosen (UI/Copies.lua), the block of the restoration in the place of the expert's: what the copy is, the four
-- times with their prices and what they can give, the button. The copy left: the room darkens, its case opens when it
-- was in one, the circle of the enchanters lights behind it, his runes around it, his words; then it is away (its
-- chip dimmed, its story says until when).
-------------------------------------------------------------------------------
local RU = { sel = {} }
ns.RestoreUI = RU

local GOLD = S.GOLD
local ARCANE = { 0.62, 0.56, 1 }
local ARCANE_HI = { 0.82, 0.78, 1 }
local ARM = 3                     -- (seconds) a click arms the button, a second click within confirms
local DIM, DIM_SCENE = 0.62, 0.86
local SPOT, SPOT_SCENE = 0.32, 0.62
local CER = {}  -- the owner of the animations of the scene
local FADE = {} -- the owner of the room coming back after it
local ICON = "Interface\\Icons\\Trade_Engraving"
-- the moments of the scene (seconds): the room darkens, the case opens, the circle and the runes, his words, the end
local INTRO, OPEN, CIRCLE, WORDS, HOLD = 0.45, 0.6, 0.7, 1.3, 1.2

local function Day(t)
	t = tonumber(t)
	return (t and t > 0) and date("%d/%m/%Y", t) or "?"
end

local function Clock(t)
	t = tonumber(t)
	return (t and t > 0) and date("%H:%M", t) or "?"
end

-- (a button as wide as its words, in every language: at least w)
local function Wide(b, w)
	local fs = b.label or (b.GetFontString and b:GetFontString())
	local tw = (fs and ns.TextWidth) and ns.TextWidth(fs) or 0
	b:SetWidth(math.max(w, math.floor(tw + 30)))
	return b
end

-- The letters of a text (UTF-8: a letter can be several bytes).
local function Chars(s)
	local out = {}
	for ch in CuratorOctoFull.Gmatch(tostring(s or ""), "[%z\1-\127\194-\244][\128-\191]*") do
		out[CuratorOctoFull.Length(out) + 1] = ch
	end
	return out
end

local function Tex(parent, file, layer, sub, blend, color)
	local t = parent:CreateTexture(nil, layer or "OVERLAY", nil, sub)
	t:SetTexture(string.find(file, "\\") and file or (MEDIA .. file))
	if blend then
		t:SetBlendMode(blend)
	end
	if color then
		t:SetVertexColor(color[1], color[2], color[3])
	end
	t:SetAlpha(0)
	t:Hide()
	return t
end

-- (a piece of the scene on the card: from the middle of the card)
local function On(d, t, x, y)
	t:ClearAllPoints()
	t:SetPoint("CENTER", d.seat, "CENTER", x, y)
end

-- The middle of the card from the middle of the detail (where the particles start from).
local function CardAt(d)
	local w = d:GetWidth()
	if not w or w < 100 then
		w = 762
	end
	return (d.atX or d.seatX or 176) - w / 2, d.atY or d.seatY or 26
end

-- The copy chosen of the card shown big (mine), and the card.
local function Chosen()
	local d = A.detail
	local card = d and d.shown
	if not (card and A.mode ~= "member" and C:Owned(card)) then
		return nil, card
	end
	local CU = ns.CopiesUI
	return CU and CU:Selected(card) or nil, card
end

-- (1 November, 2 h 13, his word: the cards of the cases restored too) What the block works on: the copy chosen of the
-- card of a booster shown big, or the copy chosen of a card of a case (UI/CaseDetail.lua): { card (a card of a booster;
-- of a case: its card as UI/CaseDetail.lua knows it, CD.Desc), id, rec (its record; of a case: its copy as Cases.lua
-- gives it), case }.
local function Target()
	local d = A.detail
	if not d or A.mode == "member" then
		return nil
	end
	if d.caseShown then
		local CD = ns.CaseDetail
		local w = CD and CD:Selected(d.caseShown)
		return w and { case = true, card = d.caseShown, id = w.i, rec = w } or nil
	end
	local rec, card = Chosen()
	return rec and card and { card = card, id = rec.i, rec = rec } or nil
end
RU.Target = Target

-- (the work of the enchanter, whatever the card: Restore.lua, R:... for a copy of the albums, R:...Case for a card of a
-- case)
local function TPlan(t, sel)
	if t.case then
		return R:CasePlan(t.id, sel)
	end
	return R:Plan(t.card, t.rec, sel)
end
local function TPrice(t, sel)
	if t.case then
		return R:CasePrice(t.id, sel)
	end
	return R:Price(t.card, t.rec, sel)
end
local function TQuoted(t)
	if t.case then
		return R:CaseQuoted(t.id)
	end
	return R:Quoted(t.rec)
end
local function TQuotePrice(t)
	if t.case then
		return R:CaseQuotePrice(t.id)
	end
	return R:QuotePrice(t.card, t.rec)
end
local function TCanQuote(t)
	if t.case then
		return R:CanQuoteCase(t.id)
	end
	return R:CanQuote(t.card, t.id)
end
local function TCanRestore(t, sel)
	if t.case then
		return R:CanRestoreCase(t.id, sel)
	end
	return R:CanRestore(t.card, t.id, sel)
end
local function TTitan(t)
	if t.case then
		return R.CaseTitan(t.rec)
	end
	return R.Titan(t.rec)
end
-- (what it did, its card with it: of a case, its card as the detail knows it)
local function Carded(res, t)
	if res and t.case then
		res.card = t.card
	end
	return res
end
local function TQuote(t)
	if t.case then
		local q, why = R:QuoteCase(t.id)
		return Carded(q, t), why
	end
	return R:Quote(t.card, t.id)
end
local function TQuoteOf(t)
	if t.case then
		return Carded(R:CaseQuoteOf(t.id), t)
	end
	return R:QuoteOf(t.card, t.id)
end
local function TRestore(t, sel)
	if t.case then
		local res, why = R:RestoreCase(t.id, sel)
		return Carded(res, t), why
	end
	return R:Restore(t.card, t.id, sel)
end
local function TPickUp(t)
	if t.case then
		local res, why = R:PickUpCase(t.id)
		return Carded(res, t), why
	end
	return R:PickUp(t.card, t.id)
end

-- The name of a card (of a booster; of a case: its card as the detail knows it).
local function NameOf(card)
	if type(card) == "table" and card.isCase then
		local CD = ns.CaseDetail
		return CD and CD.Name(card) or ""
	end
	return C:Name(card)
end
RU.NameOf = NameOf

-- Its number among its copies ("#2"; nil: one alone, or not known).
local function IndexOf(card, id)
	if type(card) == "table" and card.isCase then
		local CD = ns.CaseDetail
		for i, w in ipairs(CD and CD:Copies(card) or {}) do
			if w.i == id then
				return i
			end
		end
		return nil
	end
	local CU = ns.CopiesUI
	return CU and CU:Index(card, id) or nil
end

-- Whether the detail shows this card (of a booster or of a case).
local function Showing(d, card)
	return d ~= nil and card ~= nil and (d.shown == card or d.caseShown == card)
end

-- The detail shown again after the enchanter (a card of a case: as its own file paints it).
local function Repaint(d, card)
	if type(card) == "table" and card.isCase then
		local CD = ns.CaseDetail
		if CD and CD.Repaint then
			CD:Repaint("after")
		end
		return
	end
	if XU then
		XU:PaintDetail("after")
	end
	A:PaintCopies(card)
end

-- Whether the block of the restoration takes the place of the expert's: at an enchanter, a card of mine shown big.
local function Shown()
	return R:AtEnchanter() and Target() ~= nil
end
RU.Shown = Shown

-------------------------------------------------------------------------------
-- The block of the detail
-------------------------------------------------------------------------------
local WHY = {
	corrupt = "A corrupted copy cannot be restored: a Master of Priests purifies it first.",
	sealed = "A copy sealed by a warlock stays in its reliquary: it cannot be restored.",
	away = "At an enchanter already: pick it up first.",
	enchanter = "At an enchanter: talk to him, then show this card in your album.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
	card = "Not one of your copies.",
	kinds = "Choose what he mends: its corners, its edges, its scratches...",
	nothing = "None of the flaws chosen on this copy.",
	ready = "Not ready yet: the runes are still at work.",
	-- (1 November, his word: the quote)
	quote = "Ask for his quote first: he looks at the copy and says what he can do.",
	quoted = "Its quote is done: choose what he mends.",
	-- (1 November, 12 h 56: appraised as it is, nothing he can mend on it)
	flawless = "Nothing left that he can mend on it.",
}
RU.WHY = WHY

-- (1 November, 12 h 56, his copy restored ten times: 2 · 10 · 10 · 10, its grade 8) Appraised as it is, its centring under
-- 10: why it stays there, said ("" otherwise).
local function Centring(t)
	local m = R.MarksNow and R.MarksNow(t.rec, t.case) or nil
	if m and (tonumber(m[1]) or 10) < 10 then
		return "\n" .. L["Its centring is how it was cut: no enchanter mends it."]
	end
	return ""
end

-- (1 November, 12 h 56: ten restorations the same day) Its restorations in a line: each day once; more than two days,
-- the last one.
local function Restorations(rs)
	local days, seen = {}, {}
	for _, x in ipairs(rs) do
		local d = Day(type(x) == "table" and x[1])
		if not seen[d] then
			seen[d] = true
			days[CuratorOctoFull.Length(days) + 1] = d
		end
	end
	if CuratorOctoFull.Length(rs) == 1 then
		return string.format(L["Restored once (%s)"], days[1])
	elseif CuratorOctoFull.Length(days) <= 2 then
		return string.format(L["Restored %d times (%s)"], CuratorOctoFull.Length(rs), table.concat(days, ", "))
	end
	return string.format(L["Restored %d times, the last on %s"], CuratorOctoFull.Length(rs), days[CuratorOctoFull.Length(days)])
end
RU.Restorations = Restorations

local function BuildBlock(d)
	local tw = d.textW or 374
	local v = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(v, tw, 120)
	v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	-- its head: the mark of the enchanters, what the copy has had
	v.icon = v:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(v.icon, 22, 22)
	v.icon:SetPoint("TOPLEFT", 0, 0)
	v.icon:SetTexture(ICON)
	v.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	v.ring = v:CreateTexture(nil, "OVERLAY")
	v.ring:SetTexture(MEDIA .. "RestoreCircle")
	CuratorOctoFull.SetSize(v.ring, 30, 30)
	v.ring:SetPoint("CENTER", v.icon, "CENTER")
	v.ring:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
	v.ring:SetBlendMode("ADD")
	v.title = Hud.Text(v, 12, "")
	v.title:SetPoint("LEFT", v.icon, "RIGHT", 10, 5)
	v.title:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	v.line = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.line:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -2)
	v.line:SetWidth(tw - 34)
	CuratorOctoFull.SetWordWrap(v.line, false)
	-- what to know
	v.note = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.note:SetPoint("TOPLEFT", v.icon, "BOTTOMLEFT", 0, -10)
	v.note:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(v.note, true)
	v.note:SetSpacing(2)
	-- (31 October, his word: the enchanter redone) what he mends, by kind: each its flaws on the copy, its odds; the
	-- mouse over one, its flaws lit on the card
	v.times = {}
	local CU = ns.CopiesUI
	for i, t in ipairs(R.TREAT) do
		local i, t = i, t; local b = CU.Chip(v, function(self)
			RU:Choose(self.key)
		end)
		b.key = t.key
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			RU:KindTooltip(self)
			RU:Light(self.key)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
			RU:Light(nil)
		end)
		v.times[i] = b
	end
	v.gain = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.gain:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(v.gain, false)
	v.gain:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	-- the button: left (arm, then confirm), or picked up
	local b = S.Button(v, "", 200, 22)
	if b.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(b, true)
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		RU:Click()
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		RU:Tooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self, elapsed)
		if self.armed and GetTime() - self.armed >= ARM then
			self.armed = nil
			RU:Paint()
		end
		-- (a copy away: its time counted down)
		self.t = (self.t or 0) + elapsed
		if self.t >= 1 then
			self.t = 0
			if v.away then
				RU:Paint()
			end
		end
	end)
	v.button = b
	-- (1 November, his word: « un bouton "voir le devis" avec tous les spec de ce qu'a dit l'enchanteur »)
	local view = Wide(S.Button(v, L["See the quote"], 150, 22), 150)
	CuratorOctoFull.SetScript(view, "OnClick", function()
		RU:ToggleQuote()
	end)
	CuratorOctoFull.SetScript(view, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["The quote of the enchanter"], ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		GameTooltip:AddLine(L["Everything he said of this copy: each flaw, where it is, how bad, his odds, its price, each kind of work and all of it. The mouse over a line shows its flaw on the card."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(view, "OnLeave", function()
		GameTooltip:Hide()
	end)
	view:Hide()
	v.view = view
	v:Hide()
	d.rest = v
end

-- The enchanter's tools over the card (behind it: his circle; over it: his runes, the light, the sparks), his words
-- in the place of what there is to know.
local function BuildScene(d)
	local c = d.card
	local W, H = c.W, c.H
	d.restCircle = Tex(d, "RestoreCircle", "BORDER", 5, "ADD", ARCANE)
	d.restGlow = Tex(d, "Glow", "BORDER", 4, "ADD", ARCANE)
	local fx = CreateFrame("Frame", nil, d)
	fx:SetAllPoints()
	fx:SetFrameLevel(c:GetFrameLevel() + 16)
	fx:Hide()
	d.restFx = fx
	fx.runes = Tex(fx, "TitanRunes", "OVERLAY", 1, "ADD", ARCANE_HI)
	CuratorOctoFull.SetSize(fx.runes, W * 1.22, H * 1.16)
	fx.flash = Tex(fx, "Glow", "OVERLAY", -2, "ADD", ARCANE)
	CuratorOctoFull.SetSize(fx.flash, W * 2.3, H * 2)
	fx.shock = Tex(fx, "Shock", "OVERLAY", 2, "ADD", ARCANE_HI)
	fx.sparks = ns.Particles:New(fx, 60)
	fx.motes = ns.Particles:New(fx, 40, "Twinkle")
	-- his words, in the place of what there is to know
	local tw = d.textW or 374
	local rep = CreateFrame("Frame", nil, d)
	rep:SetFrameLevel(c:GetFrameLevel() + 16)
	CuratorOctoFull.SetSize(rep, tw, 300)
	rep.x, rep.y = d.textX or 348, -54
	rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x, rep.y)
	rep:Hide()
	rep.title = Hud.Text(rep, 12, "")
	rep.title:SetPoint("TOPLEFT", 0, 0)
	rep.title:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	rep.name = S.Text(rep, "GameFontHighlightLarge", "LEFT")
	rep.name:SetPoint("TOPLEFT", rep.title, "BOTTOMLEFT", 0, -7)
	rep.name:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(rep.name, false)
	rep.sub = S.Text(rep, "GameFontDisableSmall", "LEFT")
	rep.sub:SetPoint("TOPLEFT", rep.name, "BOTTOMLEFT", 0, -6)
	rep.sub:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(rep.sub, false)
	rep.rule = S.Divider(rep, tw, 0.9)
	rep.rule:SetPoint("TOPLEFT", 0, -66)
	rep.time = S.Text(rep, "GameFontNormalLarge", "LEFT")
	rep.time:SetPoint("TOPLEFT", 8, -84)
	rep.time:SetWidth(tw - 16)
	rep.ready = S.Text(rep, "GameFontHighlight", "LEFT")
	rep.ready:SetPoint("TOPLEFT", rep.time, "BOTTOMLEFT", 0, -8)
	rep.ready:SetWidth(tw - 16)
	rep.ready:SetTextColor(0.8, 0.8, 0.86)
	rep.rule2 = S.Divider(rep, tw, 0.9)
	rep.rule2:SetPoint("TOPLEFT", 0, -150)
	rep.who = S.Text(rep, "GameFontNormal", "LEFT")
	rep.who:SetPoint("TOPLEFT", 8, -166)
	rep.who:SetWidth(tw - 16)
	rep.quote = S.Text(rep, "GameFontHighlight", "LEFT")
	rep.quote:SetPoint("TOPLEFT", rep.who, "BOTTOMLEFT", 0, -8)
	rep.quote:SetWidth(tw - 16)
	CuratorOctoFull.SetWordWrap(rep.quote, true)
	rep.quote:SetTextColor(0.92, 0.88, 1)
	d.restRep = rep
	-- (a click skips it; the wheel does not bring the card closer)
	local b = CreateFrame("Button", nil, d)
	b:SetAllPoints()
	b:SetFrameLevel(c:GetFrameLevel() + 24)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		RU:Skip()
	end)
	b:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(b, "OnMouseWheel", function() end)
	b.hint = S.Text(b, "GameFontDisableSmall")
	if d.hint then
		b.hint:SetPoint("CENTER", d.hint, "CENTER", 0, 0)
	end
	b.hint:SetText(L["Click to skip"])
	b:Hide()
	d.restCatch = b
end

function RU:BuildDetail(d)
	if d.rest or not d.appr then
		return
	end
	BuildBlock(d)
	BuildScene(d)
	-- (the block steps aside with what there is to know, during an appraisal and a rite)
	if d.infoParts then
		d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = d.rest
	end
	CuratorOctoFull.HookScript(d, "OnHide", function()
		RU:End(true)
	end)
end

-- A kind of flaws chosen, or put back (a key of R.TREAT).
function RU:Choose(key)
	if self.cer or not R.TREAT_BY[key] then
		return
	end
	self.sel[key] = (not self.sel[key]) or nil
	local d = A.detail
	if d and d.rest then
		d.rest.button.armed = nil
	end
	ns.Play(ns.SND.click)
	self:Paint()
end

-- The flaws of a kind lit on the card shown big (nil: none lit): their pieces in the colour of the enchanters, breathing.
function RU:Light(key)
	local d = A.detail
	local c = d and d.card
	if not (c and c.wearFlaws) then
		return
	end
	local t = key and R.TREAT_BY[key]
	self.lit = t and key or nil
	for _, f in ipairs(c.wearFlaws) do
		local on = t and t.kinds[f.kind] ~= nil and not f.gone
		for _, p in ipairs(f.pieces or {}) do
			if on then
				p:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
			else
				p:SetVertexColor(1, 1, 1)
			end
		end
	end
	c.restLit = t and key or nil
end

-- What the block says, its buttons; where what comes under it goes.
function RU:Paint()
	local d = A.detail
	local v = d and d.rest
	if not v then
		return
	end
	if self.cer then
		return
	end
	self:PaintQuoteButton()
	if not Shown() then
		v:Hide()
		v.away = nil
		return
	end
	local t = Target()
	local rec, card = t.rec, t.card
	local tw = d.textW or 374
	-- (in the place of the expert's block, and of the masters')
	d.appr:Hide()
	if d.void then
		d.void:Hide()
	end
	v:ClearAllPoints()
	v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	v:Show()
	v.title:SetText(E.Upper(L["Restoration"]))
	-- its head: what it has had (a card of a case: its restorations, rr; its rank is r)
	local rs = (t.case and rec.rr) or (not t.case and rec.r) or {}
	rs = type(rs) == "table" and rs or {}
	local head = CuratorOctoFull.Length(rs) == 0 and L["Never restored"] or Restorations(rs)
	v.line:SetText(head)
	v.line:SetTextColor(0.86, 0.86, 0.9)
	local b = v.button
	local away = type(rec.aw) == "table"
	v.away = away or nil
	local last
	-- (1 November, his word: « voir le devis »: his quote again, every word of it)
	local quotedNow = (not away) and TQuoted(t) or false
	CuratorOctoFull.SetShown(v.view, quotedNow and true or false)
	if away then
		-- away: until when, and the button when it is ready
		local ready = R:Ready(rec)
		v.note:SetText(R:AwayText(rec) .. "\n|cffa9a9b4" .. L["Pick it up at any enchanter once it is ready."] .. "|r")
		v.note:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		for _, t in ipairs(v.times) do
			t:Hide()
		end
		v.gain:Hide()
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", 0, -12)
		b.mode = "pick"
		b.armed = nil
		b:SetLabel(L["Pick it up"])
		b.why = (not ready) and "ready" or nil
		CuratorOctoFull.SetEnabled(b, ready and true or false)
		b:Show()
		last = b
	else
		-- what the copy is: appraised (its case opened when it is left), its case opened already, never appraised
		local note
		local can
		if t.case then
			-- (a card of a case: appraised, its appraisal is no more once it is left; restored, its new grade at its next
			-- appraisal)
			if rec.ap then
				note = string.format(L["Appraised %s: its case is opened when it is left with the enchanter."], E.Text(tonumber(rec.g) or 1))
			elseif type(rec.rr) == "table" and CuratorOctoFull.Length(rec.rr) > 0 then
				note = L["Restored: its new grade is known at its next appraisal at a banker."]
			else
				note = L["Never appraised: its grade is known at its first appraisal."]
			end
			can = true
		else
			local CP = ns.Copies
			local g = CP.Grade(rec)
			if rec.ws then
				note = L[WHY.sealed]
			elseif rec.f == "c" then
				note = L[WHY.corrupt]
			elseif g and rec.sl ~= false then
				note = string.format(L["Appraised %s: its case is opened when it is left with the enchanter."], E.Text(g / 100))
			elseif g then
				note = L["Its case opened: appraised again at a banker, its new grade is known then."]
			else
				note = L["Never appraised: its grade is known at its first appraisal."]
			end
			can = rec.f ~= "c" and not rec.ws
		end
		-- (1 November, his word: nothing of its flaws before his quote, paid; 12 h 56: appraised as it is, nothing he can
		-- mend on it, no quote to pay for)
		local quoted = can and quotedNow
		local flawless = can and not quoted and CuratorOctoFull.Select(2, TCanQuote(t)) == "flawless"
		if flawless then
			note = "|cffa8d8ff" .. L[WHY.flawless] .. "|r" .. Centring(t)
		elseif can and not quoted then
			note = note .. "\n|cffa9a9b4" .. L["He says nothing of a card before he has looked at it: ask for his quote. It is paid, and good for one job."] .. "|r"
		elseif quoted then
			note = note .. "\n|cffa9a9b4" .. string.format(L["Quote of %s: %d flaws found."], Day(type(rec.dq) == "table" and rec.dq.t), TPlan(t, {}).all) .. " "
				.. L["He mends the flaws you choose, each by its odds: what he mends is gone for good, what he misses stays, and now and then his work leaves a mark. Its new grade stays hidden until its next appraisal."] .. "|r"
		end
		v.note:SetText(note)
		v.note:SetTextColor(0.8, 0.8, 0.86)
		local asking = can and not quoted and not flawless
		if flawless then
			for _, tb in ipairs(v.times) do
				tb:Hide()
			end
			can = false
		end
		if asking then
			for _, tb in ipairs(v.times) do
				tb:Hide()
			end
			v.gain:Hide()
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", 0, -12)
			b.mode = "quote"
			local okQ, whyQ = TCanQuote(t)
			b.why = whyQ
			local qp = RB.Text(TQuotePrice(t), 13)
			if b.armed and GetTime() - b.armed < ARM then
				b:SetLabel(L["Confirm"] .. " · " .. qp)
			else
				b:SetLabel(L["Ask for a quote"] .. " · " .. qp)
			end
			CuratorOctoFull.SetEnabled(b, okQ and true or false)
			b:Show()
			last = b
			can = false
		end
		-- (the kinds of flaws, on two rows: each its flaws on the copy, its odds)
		local plan = can and TPlan(t, self.sel) or nil
		local x, row, rowW = 0, 0, (d.textW or 374)
		for i, t in ipairs(v.times) do
			local tr = R.TREAT[i]
			local by = plan and plan.by[tr.key]
			if can and by then
				local label = L[tr.name] .. " · " .. by.n
				ns.CopiesUI.PaintChip(t, label, nil, self.sel[tr.key] and by.n > 0, by.n == 0)
				if x > 0 and x + t:GetWidth() > rowW then
					x, row = 0, row + 1
				end
				t:ClearAllPoints()
				t:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", x, -10 - row * 24)
				x = x + t:GetWidth() + 6
			else
				t:Hide()
			end
		end
		if can then
			v.gain:ClearAllPoints()
			v.gain:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", 0, -10 - (row + 1) * 24 - 2)
			if plan.n > 0 then
				local odds = 0
				for _, f in ipairs(plan.flaws) do
					odds = odds + f.odds
				end
				v.gain:SetText(string.format(L["%d flaws to mend · about %s of them · %s"], plan.n, R.Pct(odds / plan.n), R.TimeText(plan.secs)))
			elseif plan.all == 0 then
				v.gain:SetText(L["Not a flaw to mend on it."] .. Centring(t))
			else
				v.gain:SetText(L["Choose what he mends."])
			end
			v.gain:Show()
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", v.gain, "BOTTOMLEFT", 0, -10)
			b.mode = "give"
		end
		-- (1 November, 12 h 56: nothing to mend on it: no button at 0)
		if can and plan.all == 0 then
			b:Hide()
			b.armed = nil
			last = v.gain
		elseif can then
			local ok, why = TCanRestore(t, self.sel)
			b.why = why
			local price = RB.Text(TPrice(t, self.sel), 13)
			-- (1.14.0, Restoration Offered: for nothing, once a week)
			if R:Offered(plan.n) then
				price = L["offered"]
			end
			if b.armed and GetTime() - b.armed < ARM then
				b:SetLabel(L["Confirm"] .. " · " .. price)
			else
				b:SetLabel(L["Restore"] .. " · " .. price)
			end
			CuratorOctoFull.SetEnabled(b, ok and true or false)
			b:Show()
			last = b
		elseif not asking then
			v.gain:Hide()
			b:Hide()
			b.armed = nil
			last = v.note
		end
	end
	-- (1 November: « voir le devis », beside the button, or under the note)
	if v.view:IsShown() then
		v.view:ClearAllPoints()
		if b:IsShown() then
			v.view:SetPoint("LEFT", b, "RIGHT", 8, 0)
		elseif last == v.gain then
			-- (12 h 56: nothing to mend on it, under what he says of it)
			v.view:SetPoint("TOPLEFT", v.gain, "BOTTOMLEFT", 0, -10)
			last = v.view
		else
			v.view:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", 0, -12)
			last = v.view
		end
	end
	-- (its height: what it holds)
	local top = v:GetTop()
	local bottom = last and last:GetBottom()
	if top and bottom and top > bottom then
		v:SetHeight(top - bottom)
	end
	-- (what comes under it: the album of the card; of a card of a case, its collection)
	local under = t.case and d.caseSet or d.set
	under:ClearAllPoints()
	under:SetPoint("TOPLEFT", last or v, "BOTTOMLEFT", -2, -14)
	if tw then
		v:SetWidth(tw)
	end
end

-- A kind of flaws: what it mends, how many there are on the copy, his odds, what it costs alone.
function RU:KindTooltip(b)
	local tg = Target()
	local t = R.TREAT_BY[b.key]
	if not (t and tg) then
		return
	end
	local plan = TPlan(tg, { [b.key] = true })
	local by = plan.by[b.key]
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L[t.name], 1, 1, 1)
	GameTooltip:AddLine(L[R.TREAT_SAYS[b.key]], 0.85, 0.85, 0.85, true)
	if by.n > 0 then
		GameTooltip:AddLine(string.format(L["On this copy: %d · his odds: %s"], by.n, R.Pct(by.odds)), ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(TPrice(tg, { [b.key] = true }), 13)) .. "  ·  " .. R.TimeText(plan.secs), 1, 0.82, 0.25)
		GameTooltip:AddLine(self.sel[b.key] and L["Click to leave it."] or L["Click to choose it."], 0.4, 1, 0.4)
	else
		GameTooltip:AddLine(L["None on this copy."], 0.6, 0.6, 0.62)
	end
	GameTooltip:Show()
end

function RU:Tooltip(b)
	local tg = Target()
	if not tg then
		return
	end
	local rec = tg.rec
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	if b.mode == "pick" then
		GameTooltip:AddLine(L["Pick it up"], 1, 1, 1)
		if rec then
			GameTooltip:AddLine(R:AwayText(rec) or "", ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3], true)
		end
		if b.why and WHY[b.why] then
			GameTooltip:AddLine(L[WHY[b.why]], 1, 0.45, 0.4, true)
		end
		GameTooltip:Show()
		return
	end
	-- (1 November, his word: the quote, paid, before anything)
	if b.mode == "quote" then
		GameTooltip:AddLine(L["The quote of the enchanter"], ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		GameTooltip:AddLine(L["He takes the copy under his loupe and goes over it flaw by flaw: each one shown on the card, what it is, where, how bad, his odds, its price. Then you choose what he mends. A quote is good for one job: the copy left with him, ask again for the next one."], 0.85, 0.85, 0.85, true)
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(TQuotePrice(tg), 13)), 1, 0.82, 0.25)
		if TTitan(tg) then
			GameTooltip:AddLine(L["Titanforged: three times the price of its restoration."], 1, 0.84, 0.5, true)
		end
		if b.why and WHY[b.why] then
			GameTooltip:AddLine(L[WHY[b.why]], 1, 0.45, 0.4, true)
		elseif b.armed then
			GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
		end
		GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
		GameTooltip:Show()
		return
	end
	GameTooltip:AddLine(L["The restoration of a copy"], ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	GameTooltip:AddLine(L["The enchanter mends the flaws of the kinds you choose, one by one, each by its odds: a whitened corner is easy, a crease, a tear, the print torn off are hard. What he mends is gone from the card for good; what he misses stays, and now and then his solvent or his varnish leaves a mark of its own. He works while you are away too: pick it up at any enchanter. Its new grade stays hidden until its next appraisal at a banker, paid again. An appraised copy leaves its case."], 0.85, 0.85, 0.85, true)
	local plan = rec and TPlan(tg, self.sel)
	if plan and plan.n > 0 then
		GameTooltip:AddLine(string.format(L["%d flaws to mend"], plan.n) .. "  ·  " .. R.TimeText(plan.secs), 0.8, 0.8, 0.9)
	end
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(TPrice(tg, self.sel), 13)), 1, 0.82, 0.25)
	-- (1.14.0: the talents of the Archivist on this restoration)
	local TL = ns.Talents
	if TL and TL:Spec() == "archivist" then
		if plan and R:Offered(plan.n) then
			GameTooltip:AddLine(string.format(L["%s: this one for nothing (once a week)."], TL:Name("freerestore")), 0.52, 0.8, 1, true)
		end
		if TL:Ready("masterpiece") then
			GameTooltip:AddLine(string.format(L["%s: every flaw of this one mended (once a week)."], TL:Name("masterpiece")), 0.52, 0.8, 1, true)
		end
		local names = {}
		for _, id in ipairs({ "goldfinger", "patience", "restorer" }) do
			if TL:Has(id) then
				names[CuratorOctoFull.Length(names) + 1] = TL:Name(id)
			end
		end
		if CuratorOctoFull.Length(names) > 0 then
			GameTooltip:AddLine(string.format(L["Your talents on it: %s."], table.concat(names, ", ")), 0.52, 0.8, 1, true)
		end
	end
	if b.why and WHY[b.why] then
		GameTooltip:AddLine(L[WHY[b.why]], 1, 0.45, 0.4, true)
	elseif b.armed then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	GameTooltip:Show()
end

function RU:Click()
	local d = A.detail
	local v = d and d.rest
	local tg = Target()
	if not (v and tg) or self.cer or (XU and XU.cer) or (ns.SealUI and ns.SealUI.cer) then
		return
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	self:HideQuote()
	local b = v.button
	if b.mode == "pick" then
		-- (what changed shows by the scene of the return: the windows wait for it)
		self.busy = true
		local res, why = TPickUp(tg)
		self.busy = nil
		if not res then
			ns.Play(ns.SND.close)
			b.why = why
			self:Tooltip(b)
			return
		end
		GameTooltip:Hide()
		self:Back({ res })
		return
	end
	-- (1 November, his word: the quote first, paid: the scene of the loupe)
	if b.mode == "quote" then
		local okQ, whyQ = TCanQuote(tg)
		if not okQ then
			ns.Play(ns.SND.close)
			b.why = whyQ
			self:Tooltip(b)
			return
		end
		if not (b.armed and GetTime() - b.armed < ARM) then
			b.armed = GetTime()
			ns.Play(ns.SND.click)
			self:Paint()
			self:Tooltip(b)
			return
		end
		b.armed = nil
		self.busy = true
		local q = TQuote(tg)
		self.busy = nil
		if not q then
			ns.Play(ns.SND.close)
			self:Paint()
			return
		end
		GameTooltip:Hide()
		self:Examine(q)
		return
	end
	local ok, why = TCanRestore(tg, self.sel)
	if not ok then
		ns.Play(ns.SND.close)
		b.why = why
		self:Tooltip(b)
		return
	end
	if not (b.armed and GetTime() - b.armed < ARM) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:Paint()
		self:Tooltip(b)
		return
	end
	b.armed = nil
	self.busy = true
	local res = TRestore(tg, self.sel)
	self.busy = nil
	if not res then
		ns.Play(ns.SND.close)
		self:Paint()
		return
	end
	GameTooltip:Hide()
	self:Begin(res)
end

-------------------------------------------------------------------------------
-- The scene: the copy left with the enchanter
-------------------------------------------------------------------------------
-- A text written letter by letter.
function RU:Type(fs, text, dur, delay)
	local chars = Chars(text)
	local n = 0
	fs:SetText("")
	ns.Tween(dur, function(_, raw)
		local k = math.floor(raw * CuratorOctoFull.Length(chars) + 0.5)
		if k ~= n then
			n = k
			fs:SetText(table.concat(chars, "", 1, k))
		end
	end, function()
		fs:SetText(text)
	end, Ease.linear, CER, delay)
end

-- (1 November: the album closed in the middle of a scene hides its detail first, and the detail then never hears it:
-- the scene ends with the album; hooked once, the album's own script set long before)
local function HookAlbum()
	if RU.albumHooked or not (A.frame and CuratorOctoFull.HookScript) then
		return
	end
	RU.albumHooked = true
	CuratorOctoFull.HookScript(A.frame, "OnHide", function()
		RU:End(true)
	end)
end

function RU:Begin(res)
	local d = A.detail
	local name = NameOf(res.card)
	local line = R:Line(R.SAY_GIVE)
	if res.by then
		R:Say(line, res.by)
	end
	if not (d and d.restFx and d:IsShown() and Showing(d, res.card)) then
		self:Told(res)
		return
	end
	HookAlbum()
	self:End(true)
	self:HideQuote()
	ns.CancelOwner(FADE)
	local c = d.card
	local cer = { res = res, card = res.card, c = c, rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), halo = d.halo:GetAlpha() }
	self.cer = cer
	A.appraising = true
	cer.hold = { yaw = 0, pitch = 0 }
	if c.turn then
		c.turn.hold = cer.hold
		c.turn.zoomTo = c.slabInfo and (XU and XU.SLAB_ZOOM or 0.8) or 1
	end
	d.liftK = 1
	GameTooltip:Hide()
	d.restCatch:Show()
	d.restFx:Show()
	-- his words beside the card
	local rep = d.restRep
	rep.title:SetText(E.Upper(L["Restoration"]))
	rep.name:SetText(name)
	local idx = IndexOf(res.card, res.id)
	rep.sub:SetText((idx and string.format(L["The copy %s"], "#" .. idx) or "") .. (res.opened and ("  ·  " .. L["Its case opens"]) or ""))
	rep.time:SetText(string.format(L["Time: %s"], R.TimeText((res.ready or 0) - (GetServerTime and CuratorOctoFull.ServerTime() or time()))))
	rep.ready:SetText(string.format(L["Ready on %s at %s"], Day(res.ready), Clock(res.ready)))
	rep.who:SetText(res.by or L["The enchanter"])
	rep.quote:SetText("")
	rep:SetAlpha(0)
	rep:Show()
	ns.Play(ns.SND.open)
	ns.Tween(INTRO, function(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM + (DIM_SCENE - DIM) * e)
		d.spot:SetAlpha(SPOT + (SPOT_SCENE - SPOT) * e)
		d.rays:SetAlpha(cer.rays * (1 - 0.8 * e))
		d.rays2:SetAlpha(cer.rays2 * (1 - 0.8 * e))
		for _, p in ipairs(d.infoParts or {}) do
			p:SetAlpha(1 - e)
		end
		rep:SetAlpha(e)
		rep:ClearAllPoints()
		rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x + 28 * (1 - e), rep.y)
	end, nil, Ease.outQuad, CER)
	local t = INTRO
	-- its case opens (an appraised copy): it goes up, fades, the card comes back to its size
	if res.opened and c.slabInfo then
		ns.Delay(t, function()
			RU:OpenCase()
		end, CER)
		t = t + OPEN
	end
	ns.Delay(t, function()
		RU:Circle()
	end, CER)
	t = t + CIRCLE
	ns.Delay(t, function()
		RU:Words(line)
	end, CER)
	t = t + WORDS + HOLD
	ns.Delay(t, function()
		RU:End()
	end, CER)
end

function RU:OpenCase()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local fx = d.restFx
	ns.Play(ns.SND.sealBreak)
	On(d, fx.shock, 0, 0)
	fx.shock:Show()
	ns.Tween(0.45, function(e, raw)
		local s = 60 + 420 * e
		CuratorOctoFull.SetSize(fx.shock, s, s)
		fx.shock:SetAlpha(1 - raw)
	end, function()
		fx.shock:Hide()
	end, Ease.outCubic, CER)
	ns.Tween(0.5, function(e)
		c:SlabAlpha(1 - e)
		d.liftK = 1 - e
	end, function()
		c:SetSlab(nil)
		c:SlabAlpha(1)
		d.liftK = 1
		local tn = c.turn
		if tn then
			local z = XU and XU.CARD_ZOOMS or { 0.85, 1.25 }
			tn.min, tn.max = z[1], z[2]
			tn.zoomTo = 1
		end
		if XU then
			XU:Seat(d, 0)
		end
	end, Ease.inOutQuad, CER)
	local x, y = CardAt(d)
	fx.sparks:Burst(x, y + 120, ARCANE_HI, 16, 180, 0.7, 12)
end

-- The circle of the enchanters lights behind the card, turning; his runes around it, the light of the arcane rising.
function RU:Circle()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local fx = d.restFx
	ns.Play(ns.SND.reveal[3])
	ns.Play(ns.SND.shiny)
	local size = c.W * 1.9
	for _, t in ipairs({ d.restCircle, d.restGlow }) do
		On(d, t, 0, 0)
		CuratorOctoFull.SetSize(t, size, size)
		t:SetAlpha(0)
		t:Show()
	end
	CuratorOctoFull.SetSize(d.restGlow, size * 1.3, size * 1.3)
	On(d, fx.runes, 0, 0)
	fx.runes:SetAlpha(0)
	fx.runes:Show()
	On(d, fx.flash, 0, 0)
	fx.flash:SetAlpha(0.7)
	fx.flash:Show()
	ns.Tween(0.6, function(_, raw)
		fx.flash:SetAlpha(0.7 * (1 - raw))
	end, function()
		fx.flash:Hide()
	end, Ease.outQuad, CER)
	local rot = 0
	ns.Tween(CIRCLE + WORDS + HOLD + 0.4, function(e, raw)
		rot = raw * 2.4
		CuratorOctoFull.SetRotation(d.restCircle, rot)
		d.restCircle:SetAlpha(math.min(0.85, raw * 6))
		d.restGlow:SetAlpha(math.min(0.35, raw * 3))
		fx.runes:SetAlpha(math.min(0.9, raw * 5) * (0.75 + 0.25 * math.sin(raw * 20)))
	end, nil, Ease.linear, CER)
	local x, y = CardAt(d)
	c.hot:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
	ns.Tween(0.5, function(e)
		c.hot:SetAlpha(0.45 * (1 - e))
	end, nil, Ease.outQuad, CER)
	fx.sparks:Burst(x, y, ARCANE, 30, 240, 0.9, 16)
	for k = 0, 3 do
		ns.Delay(0.35 * k, function()
			fx.motes:Rise(x - 150, x + 150, y - 230, ARCANE_HI, 5, 380, 2, 18)
		end, CER)
	end
end

-- His words, letter by letter.
function RU:Words(line)
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	self:Type(d.restRep.quote, string.format(L["“%s”"], line), 1.0, 0)
end

-------------------------------------------------------------------------------
-- (1 November, his word: « il faut faire payer un devis ») The quote on the screen: the enchanter takes the copy under
-- his loupe and goes over it flaw by flaw: each one lit on the card, named, where it is, how bad (the colour of its
-- line), his odds, its price; his quote written beside the card as he goes; then each kind of work, its flaws, his
-- odds, its price, and all of it with his time; his word on it.
-------------------------------------------------------------------------------
local QL = 12 -- (the lines of the quote shown at once)
local QHOLD = 2.6 -- (the quote read, before the room comes back)
-- (what each flaw is called: UI/Wear.lua, its kinds)
local KIND = {
	corner = "A worn corner", dogear = "A dog-ear", edge = "A rubbed edge", tear = "A nick in the edge", scratch = "A scratch",
	swipe = "A swirl of fine scratches", deep = "A deep scratch", fold = "A crease", bend = "A bend", crumple = "A crumpled patch",
	dent = "A dent", nail = "A fingernail mark", pin = "A pin hole", band = "The line of a rubber band", stain = "The ring of a mug",
	water = "A water stain", fox = "Foxing", grime = "Grime", speck = "A speck of ink", lint = "A hair", tape = "A strip of tape",
	sticker = "What a sticker left", tan = "The card yellowed", fade = "A side faded by the sun", loss = "The print torn off",
}
RU.KIND = KIND
local WHERE = {
	{ "at the top left", "at the top", "at the top right" },
	{ "on the left", "in the middle", "on the right" },
	{ "at the bottom left", "at the bottom", "at the bottom right" },
}
local EDGES = { "along the left edge", "along the right edge", "along the top edge", "along the bottom edge" }
-- (how bad: light, marked, severe, by the colour of its line)
local SEV = { "light", "marked", "severe" }
local SEV_INK = { { 0.8, 0.82, 0.86 }, { 1, 0.8, 0.36 }, { 1, 0.46, 0.34 } }

local function Severity(f)
	local s = tonumber(f.sev) or 0.5
	return s < 0.4 and 1 or (s < 1 and 2 or 3)
end
RU.Severity = Severity

-- Where a flaw is on the card, in words: its corner, its edge, else a ninth of the card (all of it: the card yellowed).
local function Where(f)
	local x, y = tonumber(f.x) or 0.5, tonumber(f.y) or 0.5
	if f.kind == "tan" then
		return "all over the card"
	end
	if f.cat == 3 then
		local d = { x, 1 - x, y, 1 - y }
		local k = 1
		for i = 2, 4 do
			if d[i] < d[k] then
				k = i
			end
		end
		return EDGES[k]
	end
	local col = x < 0.36 and 1 or (x > 0.64 and 3 or 2)
	local row = y < 0.36 and 1 or (y > 0.64 and 3 or 2)
	if f.cat == 2 then
		col, row = x < 0.5 and 1 or 3, y < 0.5 and 1 or 3
	end
	return WHERE[row][col]
end
RU.Where = Where

-- What a flaw is, in words (a mark of the bench of an enchanter: said so).
local function Named(f)
	if f.mishap then
		return L["A mark of an earlier restoration"]
	end
	return L[KIND[f.kind] or "A flaw"]
end
RU.Named = Named

-- (a price as the quote writes it: his prices lowered by the talents, to five)
local function Rubies(x, k)
	local n = math.floor((tonumber(x) or 0) * (k or 1) / 5 + 0.5) * 5
	return ns.Num(math.max(n, 0))
end

-- His word on a copy, by how many flaws he found on it (in English: L[...] says it in the language of the game).
function RU.Said(n)
	return n == 0 and "Not a flaw on it. Keep your rubies." or (n <= 6 and "Almost nothing: a steady hand, and it will look new."
		or (n <= 30 and "A few things to put right. Nothing I have not seen before." or "It has lived, this one. I can give it back a great deal."))
end

-- The flaws of a quote in the order he looks at them: its corners, its edges, its surface, from the top.
local function LookOrder(flaws)
	local list = {}
	for _, f in ipairs(flaws or {}) do
		list[CuratorOctoFull.Length(list) + 1] = f
	end
	table.sort(list, function(a, b)
		if a.cat ~= b.cat then
			return (a.cat or 4) < (b.cat or 4)
		end
		if math.abs((a.y or 0) - (b.y or 0)) > 0.04 then
			return (a.y or 0) < (b.y or 0)
		end
		return (a.x or 0) < (b.x or 0)
	end)
	return list
end

-- What he writes under the flaws of a quote: each kind of work (its flaws, his odds, its price), all of it (his time),
-- what makes it dear (k: his prices as the talents lower them). { { left, right, ink } }
local function SumLines(q, list, k)
	local lines = {}
	local n = CuratorOctoFull.Length(list)
	local odds = 0
	for _, f in ipairs(list) do
		odds = odds + (f.odds or 0)
	end
	for _, t in ipairs(R.TREAT) do
		local b = q.by and q.by[t.key]
		if b and b.n > 0 then
			lines[CuratorOctoFull.Length(lines) + 1] = { L[t.name] .. "  ·  " .. b.n, string.format(L["his odds %s"], R.Pct(b.odds)) .. "  ·  " .. Rubies(b.price, k), ARCANE_HI }
		end
	end
	if n > 0 then
		lines[CuratorOctoFull.Length(lines) + 1] = { " ", "" }
		lines[CuratorOctoFull.Length(lines) + 1] = { string.format(L["%d flaws to mend · about %s of them · %s"], n, R.Pct(odds / n), R.TimeText(q.secs or 0)), "", { 0.86, 0.86, 0.9 } }
		lines[CuratorOctoFull.Length(lines) + 1] = { L["Everything"], RB.Text(math.floor((q.all or 0) * k / 5 + 0.5) * 5, 12), GOLD }
		if q.titan then
			lines[CuratorOctoFull.Length(lines) + 1] = { L["Titanforged: three times the price of its restoration."], "", { 1, 0.84, 0.5 } }
		end
		-- (1 November, 14 h 20, his choice « C »: never more than it is worth at the Bourse, its quote counted)
		if q.capped and q.worth then
			lines[CuratorOctoFull.Length(lines) + 1] = { L["Never more than its value at the Exchange"], RB.Text(q.worth, 12), { 0.62, 0.86, 1 } }
		end
		if (q.few or 1) > 1 then
			lines[CuratorOctoFull.Length(lines) + 1] = { string.format(L["Each flaw x%s: the fewer a card has, the dearer each one."], R.Dec(q.few * 100)), "", { 0.7, 0.7, 0.76 } }
		end
	end
	return lines
end

local function BuildQuote(d)
	if d.quoteRep then
		return
	end
	local c = d.card
	local tw = d.textW or 374
	local q = CreateFrame("Frame", nil, d)
	q:SetFrameLevel(c:GetFrameLevel() + 16)
	CuratorOctoFull.SetSize(q, tw, 330)
	q.x, q.y = d.textX or 348, -46
	q:SetPoint("TOPLEFT", d, "TOPLEFT", q.x, q.y)
	q:Hide()
	q.title = Hud.Text(q, 12, "")
	q.title:SetPoint("TOPLEFT", 0, 0)
	q.title:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	q.name = S.Text(q, "GameFontHighlightLarge", "LEFT")
	q.name:SetPoint("TOPLEFT", q.title, "BOTTOMLEFT", 0, -7)
	q.name:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(q.name, false)
	q.sub = S.Text(q, "GameFontDisableSmall", "LEFT")
	q.sub:SetPoint("TOPLEFT", q.name, "BOTTOMLEFT", 0, -6)
	q.sub:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(q.sub, false)
	q.rule = S.Divider(q, tw, 0.9)
	q.rule:SetPoint("TOPLEFT", 0, -62)
	q.count = S.Text(q, "GameFontNormal", "LEFT")
	q.count:SetPoint("TOPLEFT", 4, -72)
	q.legend = S.Text(q, "GameFontDisableSmall", "RIGHT")
	q.legend:SetPoint("TOPRIGHT", -4, -74)
	q.lines = {}
	for i = 1, QL do
		local l = {}
		l.left = S.Text(q, "GameFontHighlightSmall", "LEFT")
		l.left:SetPoint("TOPLEFT", 4, -90 - (i - 1) * 15)
		l.left:SetWidth(tw - 118)
		CuratorOctoFull.SetWordWrap(l.left, false)
		l.right = S.Text(q, "GameFontHighlightSmall", "RIGHT")
		l.right:SetPoint("TOPRIGHT", -4, -90 - (i - 1) * 15)
		l.right:SetWidth(112)
		CuratorOctoFull.SetWordWrap(l.right, false)
		q.lines[i] = l
	end
	q.rule2 = S.Divider(q, tw, 0.9)
	q.rule2:SetPoint("TOPLEFT", 0, -90 - QL * 15 - 6)
	q.who = S.Text(q, "GameFontNormal", "LEFT")
	q.who:SetPoint("TOPLEFT", 4, -90 - QL * 15 - 18)
	q.who:SetWidth(tw - 8)
	q.words = S.Text(q, "GameFontHighlight", "LEFT")
	q.words:SetPoint("TOPLEFT", q.who, "BOTTOMLEFT", 0, -6)
	q.words:SetWidth(tw - 8)
	CuratorOctoFull.SetWordWrap(q.words, true)
	q.words:SetTextColor(0.92, 0.88, 1)
	d.quoteRep = q
	-- his loupe over the card, its light; a ring where a flaw is found
	local fx = d.restFx
	d.quoteLoupe = Tex(fx, "Loupe", "OVERLAY", 6)
	CuratorOctoFull.SetSize(d.quoteLoupe, 96, 96)
	d.quoteLens = Tex(fx, "Glow", "OVERLAY", 5, "ADD", ARCANE_HI)
	CuratorOctoFull.SetSize(d.quoteLens, 84, 84)
	d.quoteRings = {}
	for i = 1, 6 do
		d.quoteRings[i] = Tex(fx, "Shock", "OVERLAY", 3, "ADD", ARCANE_HI)
	end
end

-------------------------------------------------------------------------------
-- A line of the quote (left: what; right: his odds, its price): its right part as wide as its words need (the
-- odds and the price of a kind of work, longer in some languages), the left part what is left of the width (tw).
local function FitLine(left, right, tw, l, r)
	r = r or ""
	right:SetText(r)
	local rw = 0
	if r ~= "" then
		local w = ns.TextWidth and ns.TextWidth(right) or 0
		rw = math.max(112, math.min(tw - 90, math.floor(w + 6)))
	end
	right:SetWidth(math.max(1, rw))
	left:SetWidth(rw > 0 and (tw - rw - 14) or (tw - 10))
	left:SetText(l)
end

-- (1 November, 2 h 51, his word: « très précis sur où c'est, pas qu'un simple rond mais vraiment un truc qui indique
-- clairement où c'est ») Where a flaw is on the card shown big: four brackets around all of it (its pieces as they lie
-- on the card), closing in on it, a light inside, its pieces lit; from its line of the quote, a line to it. Kept on the
-- card each frame, whatever its size (the card zoomed, coming back to its size).
-------------------------------------------------------------------------------
local MARK_PAD, MARK_MIN = 3, 14

local function BuildMark(d)
	if d.quoteMark then
		return d.quoteMark
	end
	local c = d.card
	local m = CreateFrame("Frame", nil, d)
	m:SetAllPoints()
	m:SetFrameLevel(c:GetFrameLevel() + 22)
	m.bars = {}
	for i = 1, 8 do
		local t = m:CreateTexture(nil, "OVERLAY", nil, 7)
		CuratorOctoFull.ColorTexture(t, ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3], 1)
		m.bars[i] = t
	end
	m.fill = m:CreateTexture(nil, "OVERLAY", nil, 4)
	CuratorOctoFull.ColorTexture(m.fill, ARCANE[1], ARCANE[2], ARCANE[3], 0.16)
	m.glow = m:CreateTexture(nil, "OVERLAY", nil, 5)
	m.glow:SetTexture(MEDIA .. "Glow")
	m.glow:SetBlendMode("ADD")
	m.glow:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	m.line = m.CreateLine and m:CreateLine(nil, "OVERLAY", nil, 6) or nil
	if m.line then
		m.line:SetThickness(2)
		CuratorOctoFull.ColorTexture(m.line, ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3], 0.9)
	end
	m.dot = m:CreateTexture(nil, "OVERLAY", nil, 7)
	m.dot:SetTexture(MEDIA .. "Glow")
	m.dot:SetBlendMode("ADD")
	m.dot:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	CuratorOctoFull.SetSize(m.dot, 14, 14)
	CuratorOctoFull.SetScript(m, "OnUpdate", function(self, elapsed)
		RU:MarkPlace(self, elapsed)
	end)
	m:Hide()
	d.quoteMark = m
	return m
end

-- Its extent on the card (card units, from its middle, upward): its pieces as they lie, else around its spot.
local function Extent(c, f)
	local x1, y1, x2, y2
	for _, lf in ipairs(c.wearFlaws or {}) do
		if lf.id == f.id then
			for _, p in ipairs(lf.pieces or {}) do
				local r = p.rest
				if r and r[1] then
					-- (its picture has soft edges of nothing: a fifth of it taken off around)
					local ix, iy = (r[3] - r[1]) * 0.1, (r[4] - r[2]) * 0.1
					local a1, b1, a2, b2 = r[1] + ix, r[2] + iy, r[3] - ix, r[4] - iy
					x1, y1 = x1 and math.min(x1, a1) or a1, y1 and math.min(y1, b1) or b1
					x2, y2 = x2 and math.max(x2, a2) or a2, y2 and math.max(y2, b2) or b2
				end
			end
		end
	end
	local W, H = c.W or 264, c.H or 370
	if not x1 then
		local cx, cy = ((tonumber(f.x) or 0.5) - 0.5) * W, (0.5 - (tonumber(f.y) or 0.5)) * H
		local s = ((f.cat == 2) and 0.1 or 0.14) * W
		x1, y1, x2, y2 = cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2
	end
	-- (on the card, never too small to see)
	x1, x2 = math.max(-W / 2, x1 - MARK_PAD), math.min(W / 2, x2 + MARK_PAD)
	y1, y2 = math.max(-H / 2, y1 - MARK_PAD), math.min(H / 2, y2 + MARK_PAD)
	if x2 - x1 < MARK_MIN then
		local cx = (x1 + x2) / 2
		x1, x2 = cx - MARK_MIN / 2, cx + MARK_MIN / 2
	end
	if y2 - y1 < MARK_MIN then
		local cy = (y1 + y2) / 2
		y1, y2 = cy - MARK_MIN / 2, cy + MARK_MIN / 2
	end
	return x1, y1, x2, y2
end

-- A flaw marked on the card (f: a flaw of the quote; row: its line of the quote, the line drawn from it; nil: put away).
function RU:MarkFlaw(f, row)
	local d = A.detail
	if not d then
		return
	end
	local m = f and BuildMark(d) or d.quoteMark
	if not m then
		return
	end
	local c = d.card
	if not (f and c) then
		m:Hide()
		m.f, m.c, m.row = nil, nil, nil
		return
	end
	m.f, m.c, m.row = f, c, row
	m.x1, m.y1, m.x2, m.y2 = Extent(c, f)
	m.t = 0
	m:Show()
	self:MarkPlace(m, 0)
end

-- Each frame: the brackets where the flaw is now, closing in on it at first, then breathing.
function RU:MarkPlace(m, elapsed)
	local c = m.c
	if not (c and m.f and c:IsVisible()) then
		return
	end
	m.t = (m.t or 0) + (elapsed or 0)
	local close = math.min(1, m.t / 0.28)
	local e = 1 - (1 - close) * (1 - close)
	local es = c.GetEffectiveScale and CuratorOctoFull.GetEffectiveScale(c) or 1
	local em = m.GetEffectiveScale and CuratorOctoFull.GetEffectiveScale(m) or 1
	local k = (em > 0) and (es / em) or 1
	-- (the brackets from a little wider, closing in)
	local grow = 1 + 0.45 * (1 - e)
	local cx, cy = (m.x1 + m.x2) / 2, (m.y1 + m.y2) / 2
	local hw, hh = (m.x2 - m.x1) / 2 * grow, (m.y2 - m.y1) / 2 * grow
	local x1, x2, y1, y2 = (cx - hw) * k, (cx + hw) * k, (cy - hh) * k, (cy + hh) * k
	local len = math.max(5, math.min(12, (x2 - x1) / 3, (y2 - y1) / 3))
	local th = 2
	local corners = { { x1, y2, 1, -1 }, { x2, y2, -1, -1 }, { x1, y1, 1, 1 }, { x2, y1, -1, 1 } }
	for i, q in ipairs(corners) do
		local hb, vb = m.bars[i * 2 - 1], m.bars[i * 2]
		local x, y, sx, sy = q[1], q[2], q[3], q[4]
		hb:ClearAllPoints()
		hb:SetPoint("CENTER", c, "CENTER", x + sx * len / 2, y)
		CuratorOctoFull.SetSize(hb, len, th)
		vb:ClearAllPoints()
		vb:SetPoint("CENTER", c, "CENTER", x, y + sy * len / 2)
		CuratorOctoFull.SetSize(vb, th, len)
	end
	local a = (0.35 + 0.65 * e) * (close >= 1 and (0.78 + 0.22 * math.sin(m.t * 5)) or 1)
	for _, b in ipairs(m.bars) do
		b:SetAlpha(a)
	end
	m.fill:ClearAllPoints()
	m.fill:SetPoint("CENTER", c, "CENTER", cx * k, cy * k)
	CuratorOctoFull.SetSize(m.fill, math.max(2, (m.x2 - m.x1) * k), math.max(2, (m.y2 - m.y1) * k))
	m.fill:SetAlpha(e)
	m.glow:ClearAllPoints()
	m.glow:SetPoint("CENTER", c, "CENTER", cx * k, cy * k)
	CuratorOctoFull.SetSize(m.glow, (m.x2 - m.x1) * k * 2.2 + 24, (m.y2 - m.y1) * k * 2.2 + 24)
	m.glow:SetAlpha(0.55 * e)
	-- (from its line of the quote: a line to the side of it facing the line)
	local row = m.row
	if m.line and row and row:IsVisible() then
		local ex = (cx + (m.x2 - m.x1) / 2) * k
		m.line:ClearAllPoints()
		m.line:SetStartPoint("LEFT", row, -2, 0)
		m.line:SetEndPoint("CENTER", c, ex, cy * k)
		m.line:SetAlpha(0.9 * e)
		m.line:Show()
		m.dot:ClearAllPoints()
		m.dot:SetPoint("CENTER", row, "LEFT", -2, 0)
		m.dot:SetAlpha(e)
		m.dot:Show()
	else
		if m.line then
			m.line:Hide()
		end
		m.dot:Hide()
	end
end

-- The lines of the quote as they are now (the last ones while he looks; from the first once it is written).
function RU:QuoteLines(fromTop)
	local cer, d = self.cer, A.detail
	local q = d and d.quoteRep
	if not (cer and q) then
		return
	end
	local list = cer.lines or {}
	local first = fromTop and 1 or math.max(1, CuratorOctoFull.Length(list) - QL + 1)
	for i = 1, QL do
		local x = list[first + i - 1]
		local l = q.lines[i]
		if x then
			-- (a line without a price: all the width; with one, its price as wide as its words)
			FitLine(l.left, l.right, q:GetWidth() or 374, x[1], x[2])
			local ink = x[3] or SEV_INK[1]
			l.left:SetTextColor(ink[1], ink[2], ink[3])
			l.right:SetTextColor(ink[1], ink[2], ink[3])
			l.left:Show()
			l.right:Show()
		else
			l.left:SetText("")
			l.right:SetText("")
		end
	end
end

-- The quote: the room darkens, his loupe comes over the card, flaw by flaw (q: what R:Quote found).
function RU:Examine(q)
	local d = A.detail
	if not (d and d.restFx and d:IsShown() and Showing(d, q.card)) then
		self:QuoteTold(q)
		return
	end
	HookAlbum()
	self:End(true)
	self:HideQuote()
	ns.CancelOwner(FADE)
	BuildQuote(d)
	local c = d.card
	local cer = { quote = q, res = q, card = q.card, c = c, rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), halo = d.halo:GetAlpha(), lines = {} }
	self.cer = cer
	A.appraising = true
	cer.hold = { yaw = 0, pitch = 0 }
	if c.turn then
		c.turn.hold = cer.hold
		c.turn.zoomTo = c.slabInfo and (XU and XU.SLAB_ZOOM or 0.8) or 1
	end
	d.liftK = 1
	GameTooltip:Hide()
	d.restCatch:Show()
	d.restFx:Show()
	-- (the flaws on the card shown big, by their number: their pieces)
	cer.byId = {}
	for _, f in ipairs(c.wearFlaws or {}) do
		cer.byId[f.id] = f
	end
	-- (his prices as the talents lower them)
	cer.k = (ns.Rubies and ns.Rubies.Price) and (ns.Rubies:Price(100000, "restore") / 100000) or 1
	local rep = d.quoteRep
	rep.title:SetText(E.Upper(L["Quote"]))
	rep.name:SetText(NameOf(q.card))
	local idx = IndexOf(q.card, q.id)
	rep.sub:SetText((idx and string.format(L["The copy %s"], "#" .. idx) or "") .. (q.who and ((idx and "  ·  " or "") .. string.format(L["Examined by %s"], q.who)) or ""))
	local function Ink(i, w)
		local k = SEV_INK[i]
		return string.format(("|cff%02x%02x%02x%s|r"), math.floor(k[1] * 255), math.floor(k[2] * 255), math.floor(k[3] * 255), L[w])
	end
	rep.legend:SetText(Ink(1, SEV[1]) .. "  " .. Ink(2, SEV[2]) .. "  " .. Ink(3, SEV[3]))
	rep.count:SetText(L["He looks at it..."])
	rep.who:SetText("")
	rep.words:SetText("")
	self:QuoteLines()
	rep:SetAlpha(0)
	rep:Show()
	ns.Play(ns.SND.open)
	ns.Tween(INTRO, function(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM + (DIM_SCENE - DIM) * e)
		d.spot:SetAlpha(SPOT + (SPOT_SCENE - SPOT) * e)
		d.rays:SetAlpha(cer.rays * (1 - 0.8 * e))
		d.rays2:SetAlpha(cer.rays2 * (1 - 0.8 * e))
		for _, p in ipairs(d.infoParts or {}) do
			p:SetAlpha(1 - e)
		end
		rep:SetAlpha(e)
		rep:ClearAllPoints()
		rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x + 28 * (1 - e), rep.y)
	end, nil, Ease.outQuad, CER)
	-- the flaws in the order he looks at them: its corners, its edges, its surface, from the top
	local list = LookOrder(q.flaws)
	cer.list = list
	local n = CuratorOctoFull.Length(list)
	cer.dt = n > 0 and math.max(0.14, math.min(0.5, 12 / n)) or 0
	local t = INTRO
	ns.Delay(t, function()
		RU:LoupeIn()
	end, CER)
	t = t + 0.35
	for k = 1, n do
		local k = k; ns.Delay(t + (k - 1) * cer.dt, function()
			RU:Look(k)
		end, CER)
	end
	t = t + n * cer.dt + 0.35
	ns.Delay(t, function()
		RU:QuoteSum()
	end, CER)
	cer.tEnd = t + QHOLD + math.min(3, n * 0.03)
	ns.Delay(cer.tEnd, function()
		RU:End()
	end, CER)
end

-- His loupe comes over the card.
function RU:LoupeIn()
	local cer, d = self.cer, A.detail
	if not (cer and cer.quote) then
		return
	end
	cer.lx, cer.ly = 0, 0
	On(d, d.quoteLoupe, 0, 30)
	On(d, d.quoteLens, 0, 0)
	d.quoteLoupe:Show()
	d.quoteLens:Show()
	ns.Play(ns.SND.page)
	ns.Tween(0.3, function(e)
		d.quoteLoupe:SetAlpha(e)
		d.quoteLens:SetAlpha(0.35 * e)
	end, nil, Ease.outQuad, CER)
end

-- He finds the k-th flaw: his loupe over it, its pieces lit (those before, softer), a ring where it is, its line.
function RU:Look(k)
	local cer, d = self.cer, A.detail
	if not (cer and cer.quote and cer.list) then
		return
	end
	local f = cer.list[k]
	if not f then
		return
	end
	local c = d.card
	-- (on the card as it is shown: its size now, zoomed or not)
	local es = c.GetEffectiveScale and CuratorOctoFull.GetEffectiveScale(c) or 1
	local ef = d.restFx.GetEffectiveScale and CuratorOctoFull.GetEffectiveScale(d.restFx) or 1
	local k = (ef > 0) and (es / ef) or 1
	local x, y = ((tonumber(f.x) or 0.5) - 0.5) * c.W * k, (0.5 - (tonumber(f.y) or 0.5)) * c.H * k
	local x0, y0 = cer.lx or 0, cer.ly or 0
	cer.lx, cer.ly = x, y
	ns.Tween(math.min(0.24, cer.dt * 0.8), function(e)
		local px, py = x0 + (x - x0) * e, y0 + (y - y0) * e
		On(d, d.quoteLoupe, px + 14, py + 26)
		On(d, d.quoteLens, px, py)
	end, nil, Ease.outQuad, CER)
	-- (the one before: softer; this one: the light of the enchanters)
	local prev = cer.prev and cer.byId[cer.prev]
	if prev then
		for _, p in ipairs(prev.pieces or {}) do
			p:SetVertexColor(0.74, 0.7, 1)
		end
	end
	local on = cer.byId[f.id]
	if on then
		for _, p in ipairs(on.pieces or {}) do
			p:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		end
	end
	cer.prev = f.id
	local sev = Severity(f)
	cer.lines[CuratorOctoFull.Length(cer.lines) + 1] = { Named(f) .. ", " .. L[Where(f)], R.Pct(f.odds or 0) .. "  ·  " .. Rubies(f.price, cer.k), SEV_INK[sev] }
	self:QuoteLines()
	-- (1 November, his word: where it is, clearly: the brackets around it, a line from its line of the quote)
	local ql = d.quoteRep.lines[math.min(CuratorOctoFull.Length(cer.lines), QL)]
	self:MarkFlaw(f, ql and ql.left)
	d.quoteRep.count:SetText(string.format(L["%d flaws found"], k))
	if cer.dt >= 0.25 or CuratorOctoFull.Mod(k , 2) == 1 then
		ns.Play(ns.SND.tick)
	end
end

-- His quote written: each kind of work (its flaws, his odds, its price), all of it (his time), what makes it dear, his
-- word (fast: skipped to it).
function RU:QuoteSum(fast)
	local cer, d = self.cer, A.detail
	if not (cer and cer.quote) or cer.summed then
		return
	end
	cer.summed = true
	self:MarkFlaw(nil)
	local q = cer.quote
	local rep = d.quoteRep
	-- (every flaw he found, lit softly; his loupe away)
	for _, f in ipairs(cer.list or {}) do
		local on = cer.byId[f.id]
		for _, p in ipairs(on and on.pieces or {}) do
			p:SetVertexColor(0.74, 0.7, 1)
		end
	end
	local lp, ls = d.quoteLoupe, d.quoteLens
	if fast then
		lp:Hide()
		ls:Hide()
	else
		ns.Tween(0.3, function(e)
			lp:SetAlpha(1 - e)
			ls:SetAlpha(0.35 * (1 - e))
		end, function()
			lp:Hide()
			ls:Hide()
		end, Ease.outQuad, CER)
	end
	local n = CuratorOctoFull.Length((cer.list or {}))
	local lines = SumLines(q, cer.list or {}, cer.k)
	if n > 0 then
		rep.count:SetText(string.format(L["%d flaws found"], n))
	else
		rep.count:SetText(L["Not a flaw to mend on it."])
	end
	cer.lines = lines
	self:QuoteLines(true)
	rep.who:SetText(q.who or L["The enchanter"])
	local said = RU.Said(n)
	if fast then
		rep.words:SetText(string.format(L["“%s”"], L[said]))
	else
		self:Type(rep.words, string.format(L["“%s”"], L[said]), 0.9, 0.2)
	end
	ns.Play(ns.SND.stamp)
end

-- What the chat says of a quote.
function RU:QuoteTold(q)
	local n = CuratorOctoFull.Length((q.flaws or {}))
	local k = (ns.Rubies and ns.Rubies.Price) and (ns.Rubies:Price(100000, "restore") / 100000) or 1
	ns.Print(L["Quote for %s: %d flaws, %s rubies for all of them (%s)."], NameOf(q.card), n, Rubies(q.all, k), R.TimeText(q.secs or 0))
end

function RU:Skip()
	if not self.cer then
		return
	end
	-- (1 November: the quote, a first click shows it written, a second ends it)
	local cer = self.cer
	if cer.quote and not cer.summed then
		ns.CancelOwner(CER)
		local d = A.detail
		for _, r in ipairs(d.quoteRings or {}) do
			r:Hide()
		end
		cer.lines = {}
		self:QuoteSum(true)
		ns.Delay(QHOLD + 1.4, function()
			RU:End()
		end, CER)
		return
	end
	ns.Play(ns.SND.stamp)
	self:End()
end

-- What the chat says of a copy left.
function RU:Told(res)
	ns.Print(L["%s left with %s: ready in %s."], NameOf(res.card), res.by or L["the enchanter"],
		ns.Duration(math.max(60, (res.ready or 0) - (GetServerTime and CuratorOctoFull.ServerTime() or time()))))
end

-- It ends: the scene put away, the room as it was (quick: at once, the detail closing or another card shown), said in
-- the chat.
function RU:End(quick)
	local cer = self.cer
	if not cer then
		return
	end
	self.cer = nil
	A.appraising = false
	ns.CancelOwner(CER)
	local d = A.detail
	-- (the card of the scene: another may be shown now, of a booster or of a case)
	local c = cer.c or d.card
	local fx = d.restFx
	for _, t in ipairs({ fx.runes, fx.flash, fx.shock }) do
		t:Hide()
	end
	-- (1 November: the quote's loupe, its rings; the flaws back to their colours)
	for _, t in ipairs({ d.quoteLoupe, d.quoteLens }) do
		t:Hide()
	end
	for _, r in ipairs(d.quoteRings or {}) do
		r:Hide()
	end
	if cer.quote then
		self:Light(nil)
		self:MarkFlaw(nil)
	end
	fx.sparks:Clear()
	if quick then
		fx.motes:Clear()
	end
	d.restCatch:Hide()
	d.liftK = 1
	if c.turn then
		c.turn.hold = nil
	end
	c.hot:SetAlpha(0)
	-- (its case gone for good: the card out of it)
	if c.slabInfo and cer.res.opened then
		c:SetSlab(nil)
	end
	local here = d:IsShown() and Showing(d, cer.card)
	if here then
		Repaint(d, cer.card)
	end
	local rep = cer.quote and d.quoteRep or d.restRep
	local from = { dim = DIM_SCENE, spot = d.spot:GetAlpha(), rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), rep = rep:GetAlpha(),
		circle = d.restCircle:GetAlpha(), glow = d.restGlow:GetAlpha() }
	local function Room(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, from.dim + (DIM - from.dim) * e)
		d.spot:SetAlpha(from.spot + (SPOT - from.spot) * e)
		d.rays:SetAlpha(from.rays + (cer.rays - from.rays) * e)
		d.rays2:SetAlpha(from.rays2 + (cer.rays2 - from.rays2) * e)
		for _, p in ipairs(d.infoParts or {}) do
			p:SetAlpha(e)
		end
		rep:SetAlpha(from.rep * (1 - e))
		d.restCircle:SetAlpha(from.circle * (1 - e))
		d.restGlow:SetAlpha(from.glow * (1 - e))
	end
	local function Away()
		rep:Hide()
		fx:Hide()
		d.restCircle:Hide()
		d.restGlow:Hide()
		CuratorOctoFull.SetRotation(d.restCircle, 0)
	end
	if quick or not here then
		Room(1)
		Away()
	else
		ns.Tween(0.4, Room, Away, Ease.outQuad, FADE)
	end
	if cer.quote then
		self:QuoteTold(cer.quote)
	else
		self:Told(cer.res)
	end
	self:Paint()
end

-------------------------------------------------------------------------------
-- (1 November, 2 h 13, his word: « un bouton "voir le devis" avec tous les spec de ce qu'a dit l'enchanteur ») His
-- quote again, every word of it, beside the card shown big (a copy quoted, of a booster or of a case; at an enchanter
-- or not): each flaw (what it is, where, how bad by its colour, his odds, its price), each kind of work, all of it, his
-- time, who made it and when, his word; page by page (the wheel, the arrows); the mouse over a line, its flaw lit on
-- the card, a ring around it, all of it said in its tooltip.
-------------------------------------------------------------------------------
local VIEW_ROWS = 20

local function BuildView(d)
	if d.quoteView then
		return d.quoteView
	end
	-- (the rings: those of the scene)
	BuildQuote(d)
	local c = d.card
	local tw = d.textW or 374
	local v = CreateFrame("Frame", nil, d)
	v:SetFrameLevel(c:GetFrameLevel() + 18)
	CuratorOctoFull.SetSize(v, tw, 470)
	v.x, v.y = d.textX or 348, -40
	v:SetPoint("TOPLEFT", d, "TOPLEFT", v.x, v.y)
	v:EnableMouse(true)
	v:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(v, "OnMouseWheel", function(_, delta)
		RU:ViewPage(delta > 0 and -1 or 1)
	end)
	v:Hide()
	v.title = Hud.Text(v, 12, "")
	v.title:SetPoint("TOPLEFT", 0, 0)
	v.title:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	v.name = S.Text(v, "GameFontHighlightLarge", "LEFT")
	v.name:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -7)
	v.name:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(v.name, false)
	v.sub = S.Text(v, "GameFontDisableSmall", "LEFT")
	v.sub:SetPoint("TOPLEFT", v.name, "BOTTOMLEFT", 0, -6)
	v.sub:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(v.sub, false)
	v.rule = S.Divider(v, tw, 0.9)
	v.rule:SetPoint("TOPLEFT", 0, -62)
	v.count = S.Text(v, "GameFontNormal", "LEFT")
	v.count:SetPoint("TOPLEFT", 4, -72)
	v.legend = S.Text(v, "GameFontDisableSmall", "RIGHT")
	v.legend:SetPoint("TOPRIGHT", -4, -74)
	v.rows = {}
	for i = 1, VIEW_ROWS do
		local i = i; local r = CreateFrame("Button", nil, v)
		CuratorOctoFull.SetSize(r, tw - 4, 15)
		r:SetPoint("TOPLEFT", 2, -90 - (i - 1) * 15)
		r.hi = r:CreateTexture(nil, "BACKGROUND")
		r.hi:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.hi, ARCANE[1], ARCANE[2], ARCANE[3], 0.16)
		r.hi:Hide()
		r.left = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.left:SetPoint("LEFT", 2, 0)
		r.left:SetWidth(tw - 126)
		CuratorOctoFull.SetWordWrap(r.left, false)
		r.right = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.right:SetPoint("RIGHT", -2, 0)
		r.right:SetWidth(116)
		CuratorOctoFull.SetWordWrap(r.right, false)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			RU:ViewLight(self)
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			RU:ViewLight(nil)
		end)
		r:Hide()
		v.rows[i] = r
	end
	v.pager = S.Pager(v)
	CuratorOctoFull.SetScript(v.pager.prev, "OnClick", function()
		RU:ViewPage(-1)
	end)
	CuratorOctoFull.SetScript(v.pager.next, "OnClick", function()
		RU:ViewPage(1)
	end)
	v.rule2 = S.Divider(v, tw, 0.9)
	v.who = S.Text(v, "GameFontNormal", "LEFT")
	v.who:SetWidth(tw - 8)
	v.words = S.Text(v, "GameFontHighlight", "LEFT")
	v.words:SetPoint("TOPLEFT", v.who, "BOTTOMLEFT", 0, -6)
	v.words:SetWidth(tw - 8)
	CuratorOctoFull.SetWordWrap(v.words, true)
	v.words:SetTextColor(0.92, 0.88, 1)
	v.close = Wide(S.Button(v, L["Close the quote"], 170, 22), 170)
	v.close:SetPoint("TOPLEFT", v.words, "BOTTOMLEFT", 0, -10)
	CuratorOctoFull.SetScript(v.close, "OnClick", function()
		ns.Play(ns.SND.page)
		RU:HideQuote()
	end)
	d.quoteView = v
	return v
end

-- (his prices as the talents lower them)
local function PriceK()
	return (ns.Rubies and ns.Rubies.Price) and (ns.Rubies:Price(100000, "restore") / 100000) or 1
end

function RU:ToggleQuote()
	local d = A.detail
	if d and d.quoteView and d.quoteView:IsShown() then
		ns.Play(ns.SND.page)
		return self:HideQuote()
	end
	return self:ShowQuote()
end

-- His quote of the copy chosen, shown (nil: none, or no more true).
function RU:ShowQuote()
	local d = A.detail
	local tg = Target()
	if not (d and d:IsShown() and tg) or self.cer or (XU and XU.cer) or (ns.SealUI and ns.SealUI.cer) then
		return nil
	end
	local q = TQuoteOf(tg)
	if not q then
		return nil
	end
	local v = BuildView(d)
	local c = d.card
	local list = LookOrder(q.flaws)
	local k = PriceK()
	local lines = {}
	for _, f in ipairs(list) do
		local sev = Severity(f)
		lines[CuratorOctoFull.Length(lines) + 1] = { Named(f) .. ", " .. L[Where(f)], R.Pct(f.odds or 0) .. "  ·  " .. Rubies(f.price, k), SEV_INK[sev], f }
	end
	if CuratorOctoFull.Length(lines) > 0 then
		lines[CuratorOctoFull.Length(lines) + 1] = { " ", "" }
	end
	for _, x in ipairs(SumLines(q, list, k)) do
		lines[CuratorOctoFull.Length(lines) + 1] = x
	end
	local st = { q = q, list = list, lines = lines, page = 1, card = tg.card, id = tg.id, case = tg.case, c = c, k = k,
		hold = { yaw = 0, pitch = 0 } }
	self.view = st
	-- its head: the card, the copy, who looked at it and when
	v.title:SetText(E.Upper(L["Quote"]))
	v.name:SetText(NameOf(tg.card))
	local parts = {}
	local idx = IndexOf(tg.card, tg.id)
	if idx then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["The copy %s"], "#" .. idx)
	end
	if q.t then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Quoted on %s"], Day(q.t))
	end
	v.sub:SetText(table.concat(parts, "  ·  "))
	local function Ink(i, w)
		local kk = SEV_INK[i]
		return string.format(("|cff%02x%02x%02x%s|r"), math.floor(kk[1] * 255), math.floor(kk[2] * 255), math.floor(kk[3] * 255), L[w])
	end
	v.legend:SetText(Ink(1, SEV[1]) .. "  " .. Ink(2, SEV[2]) .. "  " .. Ink(3, SEV[3]))
	v.count:SetText(CuratorOctoFull.Length(list) > 0 and string.format(L["%d flaws found"], CuratorOctoFull.Length(list)) or L["Not a flaw to mend on it."])
	v.who:SetText(q.who or L["The enchanter"])
	v.words:SetText(string.format(L["“%s”"], L[RU.Said(CuratorOctoFull.Length(list))]))
	-- (as many lines a page as the room there is)
	local h = d:GetHeight()
	if not h or h < 240 then
		h = 560
	end
	st.per = math.max(6, math.min(VIEW_ROWS, math.floor((h + v.y - 90 - 150) / 15)))
	-- (its foot right under its last line: one page, as many lines as it has)
	local used = math.min(st.per, CuratorOctoFull.Length(lines))
	local yb = -90 - used * 15 - 2
	v.pager:ClearAllPoints()
	v.pager:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, yb)
	v.rule2:ClearAllPoints()
	v.rule2:SetPoint("TOPLEFT", 0, yb - 34)
	v.who:ClearAllPoints()
	v.who:SetPoint("TOPLEFT", 4, yb - 44)
	self:PaintView()
	-- what there is to know steps aside, the card held facing, still
	for _, p in ipairs(d.infoParts or {}) do
		p:SetAlpha(0)
	end
	if c.turn then
		c.turn.hold = st.hold
	end
	d.restFx:Show()
	GameTooltip:Hide()
	v:Show()
	ns.Play(ns.SND.page)
	return st
end

-- The lines of the page shown.
function RU:PaintView()
	local d = A.detail
	local v = d and d.quoteView
	local st = self.view
	if not (v and st) then
		return
	end
	local per = st.per or VIEW_ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(st.lines) / per))
	st.page = math.max(1, math.min(pages, st.page))
	local first = (st.page - 1) * per
	local tw = v:GetWidth() or 374
	for i, r in ipairs(v.rows) do
		local x = (i <= per) and st.lines[first + i] or nil
		r.hi:Hide()
		if x then
			FitLine(r.left, r.right, tw - 4, x[1], x[2])
			local ink = x[3] or SEV_INK[1]
			r.left:SetTextColor(ink[1], ink[2], ink[3])
			r.right:SetTextColor(ink[1], ink[2], ink[3])
			r.flaw = x[4]
			r:Show()
		else
			r.flaw = nil
			r:Hide()
		end
	end
	CuratorOctoFull.SetShown(v.pager, pages > 1)
	v.pager:Set(st.page, pages, string.format(L["Page %d / %d"], st.page, pages))
end

-- Another page (step: -1 the one before, 1 the next).
function RU:ViewPage(step)
	local st = self.view
	if not st then
		return
	end
	local was = st.page
	st.page = st.page + step
	self:PaintView()
	if st.page ~= was then
		ns.Play(ns.SND.page)
	end
	self:ViewLight(nil)
end

-- A line under the mouse (nil: none): its flaw lit on the card, a ring around it, all of it said in its tooltip.
function RU:ViewLight(row)
	local d = A.detail
	local st = self.view
	local v = d and d.quoteView
	if not (st and v and v:IsShown()) then
		return
	end
	local c = st.c
	for _, r in ipairs(v.rows) do
		CuratorOctoFull.SetShown(r.hi, r == row and r.flaw ~= nil)
	end
	for _, f in ipairs(c and c.wearFlaws or {}) do
		for _, p in ipairs(f.pieces or {}) do
			p:SetVertexColor(1, 1, 1)
		end
	end
	local f = row and row.flaw
	if not f then
		self:MarkFlaw(nil)
		GameTooltip:Hide()
		return
	end
	for _, x in ipairs(c and c.wearFlaws or {}) do
		if x.id == f.id then
			for _, p in ipairs(x.pieces or {}) do
				p:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
			end
		end
	end
	-- (where it is: the brackets around it, the line from its line)
	self:MarkFlaw(f, row)
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Named(f), 1, 1, 1)
	GameTooltip:AddLine(L[Where(f)], 0.86, 0.86, 0.9)
	local sev = Severity(f)
	local ink = SEV_INK[sev]
	GameTooltip:AddLine(L[SEV[sev]], ink[1], ink[2], ink[3])
	local t = R.TREAT_BY[f.t or ""]
	if t then
		GameTooltip:AddLine(L[t.name] .. "  ·  " .. string.format(L["his odds %s"], R.Pct(f.odds or 0)), ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	end
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(math.floor((f.price or 0) * (st.k or 1) / 5 + 0.5) * 5, 13)), 1, 0.82, 0.25)
	GameTooltip:Show()
end

-- His quote put away: the card as it was, what there is to know back.
function RU:HideQuote()
	local st = self.view
	self.view = nil
	local d = A.detail
	local v = d and d.quoteView
	if not v then
		return
	end
	local was = v:IsShown()
	v:Hide()
	if not (st or was) then
		return
	end
	GameTooltip:Hide()
	local c = st and st.c
	for _, f in ipairs(c and c.wearFlaws or {}) do
		for _, p in ipairs(f.pieces or {}) do
			p:SetVertexColor(1, 1, 1)
		end
	end
	if c and c.turn and c.turn.hold == st.hold then
		c.turn.hold = nil
	end
	for _, r in ipairs(d.quoteRings or {}) do
		r:Hide()
	end
	self:MarkFlaw(nil)
	if not self.cer and d.restFx then
		d.restFx:Hide()
	end
	for _, p in ipairs(d.infoParts or {}) do
		p:SetAlpha(1)
	end
end

-- (away from an enchanter: the button of his quote alone, under the buttons of the panel, for a copy quoted)
function RU:PaintQuoteButton()
	local d = A.detail
	if not d then
		return
	end
	local b = d.quoteAny
	local tg = (not self.cer) and Target() or nil
	local want = tg and not Shown() and TQuoted(tg) and type(tg.rec.aw) ~= "table"
	if not want then
		if b then
			b:Hide()
		end
		return
	end
	if not b then
		b = Wide(S.Button(d, L["See the quote"], 150, 22), 150)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			RU:ToggleQuote()
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["The quote of the enchanter"], ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
			GameTooltip:AddLine(L["Everything he said of this copy: each flaw, where it is, how bad, his odds, its price, each kind of work and all of it. The mouse over a line shows its flaw on the card."], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		d.quoteAny = b
		if d.infoParts then
			d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = b
		end
	end
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", d.pinNote or d.pin, "BOTTOMLEFT", d.pinNote and -2 or 0, -8)
	CuratorOctoFull.SetShown(b, d.pin:IsShown())
end

-------------------------------------------------------------------------------
-- Picked up
-------------------------------------------------------------------------------
-- Copies back (what R:PickUp did for each): his words, in his window, the chat; a little light on the window of
-- Curator; the card shown big told again.
function RU:Back(list)
	if not list or CuratorOctoFull.Length(list) == 0 then
		return
	end
	-- (1 November: a card of a case back, its card as the detail knows it)
	local CS, CD = ns.Cases, ns.CaseDetail
	for _, x in ipairs(list) do
		if x.case and not x.card and CS and CD then
			local w = CS:Card(x.id)
			x.card = w and CD.DescOf(w) or nil
		end
	end
	local line = R:Line(R.SAY_BACK)
	R:Say(line)
	if ns.Gossip and ns.Gossip.open then
		ns.Gossip:Say(line)
	end
	self.said = line
	ns.Play(ns.SND.holo)
	ns.Play(ns.SND.claim)
	if CuratorOctoFull.Length(list) == 1 and (list[1].n or 0) > 0 then
		local x = list[1]
		ns.Print(L["%s is back from the enchanter: %d of %d flaws mended%s. Have it appraised to see its new grade."], NameOf(x.card), x.mended or 0, x.n,
			(x.mishaps or 0) > 0 and L[", and a mark of his work"] or "")
	elseif CuratorOctoFull.Length(list) == 1 then
		ns.Print(L["%s is back from the enchanter: have it appraised to see what it gained."], NameOf(list[1].card))
	else
		ns.Print(L["%d copies back from the enchanter: have them appraised to see what they gained."], CuratorOctoFull.Length(list))
	end
	local p = self.panel
	if p and p:IsShown() then
		p:Raise()
		p.flash:SetAlpha(0.8)
		p.flash:Show()
		ns.Tween(0.8, function(_, raw)
			p.flash:SetAlpha(0.8 * (1 - raw))
		end, function()
			p.flash:Hide()
		end, Ease.outQuad, RU)
		p.sparks:Burst(0, 20, ARCANE_HI, 20, 140, 0.8, 12)
		p.sparks:Burst(0, 20, GOLD, 8, 90, 0.7, 10)
	end
	self:PaintPanel()
	local d = A.detail
	if d and d:IsShown() and (d.shown or d.caseShown) and not self.cer then
		local shownCard = d.shown or d.caseShown
		local function Done()
			if d.caseShown then
				Repaint(d, d.caseShown)
				return
			end
			if ns.CopiesUI and ns.CopiesUI.Apply then
				ns.CopiesUI:Apply(d)
			end
			if XU then
				XU:PaintDetail("after")
			end
			A:PaintCopies(d.shown)
		end
		-- (31 October, his word: the copy shown big is one of those back: the flaws he mended go from it before your
		-- eyes, in the light of the enchanters; 1 November: a card of a case too)
		local tg = Target()
		local res
		for _, x in ipairs(list) do
			if tg and x.card == shownCard and x.id == tg.id and (x.case and true or false) == (tg.case and true or false) then
				res = x
			end
		end
		local c = d.card
		local fading = {}
		if res and c and c.wearFlaws and res.gone and CuratorOctoFull.Length(res.gone) > 0 then
			local set = {}
			for _, id in ipairs(res.gone) do
				set[id] = true
			end
			for _, f in ipairs(c.wearFlaws) do
				if set[f.id] then
					for _, p in ipairs(f.pieces or {}) do
						if p:IsShown() then
							fading[CuratorOctoFull.Length(fading) + 1] = { p, p.base or p:GetAlpha() }
							p:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
						end
					end
				end
			end
		end
		if CuratorOctoFull.Length(fading) > 0 then
			self.fading = true
			ns.Tween(1.4, function(e)
				for _, x in ipairs(fading) do
					x[1].base = x[2] * (1 - e)
					x[1]:SetAlpha(x[1].base)
				end
			end, function()
				self.fading = nil
				Done()
			end, Ease.inQuad, RU)
		else
			Done()
		end
	end
end

-------------------------------------------------------------------------------
-- (1 November, 11 h 53, his word: « "récupérer" c'est pour une seule carte, puis y'a une animation et puis on voit le
-- avant et après. Puis UN BOUTON pour fermer. Jamais de "tout récupérer" [...] comme pour le contrat genre on clique sur
-- la carte pour l'inspect sa nouvelle carte ») A copy picked up from his window, one at a time, its return on the
-- screen: the place darkens, the circle of the enchanters lights, the copy comes in its light as it left him (every
-- flaw on it); his words; the flaws he mended light up and go, what went wrong at his bench comes; then the copy as it
-- was beside the copy as it is, Before and After, what he did under them. A click on either holds it up close (Back:
-- to the two of them). Close, the one way out: a click in the dark does nothing.
-------------------------------------------------------------------------------
local RET = {} -- the owner of the animations of the return
local RET_SIZE = "huge"
local RET_X, RET_Y = 180, 24 -- (the two cards, from the middle of the screen)
-- the moments (seconds): the place darkens, the copy comes, his words, the flaws mended go, its mishaps, the two cards
local R_IN, R_CARD, R_WORDS, R_MEND, R_GONE, R_MARK, R_SPLIT, R_SHOW = 0.35, 0.45, 1.1, 1.6, 1.2, 3.2, 3.55, 4.2

-- A card of the return (kind "case": a card of a case, UI/CrateCard.lua; else of a booster, UI/Card.lua), in a spot
-- of its own (placed) and a holder (scaled in place, without an offset).
local function RetCard(f, kind, x, y)
	local spot = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(spot, 1, 1)
	spot:SetPoint("CENTER", f, "CENTER", x, y)
	local holder = CreateFrame("Frame", nil, spot)
	CuratorOctoFull.SetSize(holder, 1, 1)
	holder:SetPoint("CENTER", spot, "CENTER")
	holder:SetFrameLevel(f:GetFrameLevel() + 10)
	local W = ns.CARD_SIZES[RET_SIZE][1]
	local c = kind == "case" and ns.CrateCard.New(holder, W) or ns.NewCard(holder, RET_SIZE)
	c:SetPoint("CENTER", holder, "CENTER")
	c.spot, c.holder = spot, holder
	-- (a click on it, once the two are shown: held up close)
	local hit = CreateFrame("Button", nil, holder)
	CuratorOctoFull.SetSize(hit, c:GetWidth(), c:GetHeight())
	hit:SetPoint("CENTER", holder, "CENTER")
	hit:SetFrameLevel(c:GetFrameLevel() + 30)
	hit:RegisterForClicks("LeftButtonUp")
	hit:Hide()
	c.hit = hit
	return c
end

-- Where a card of the return stands (x, y from the middle), how big, how clear.
local function Place(c, x, y, k, a)
	c.spot:ClearAllPoints()
	c.spot:SetPoint("CENTER", c.spot:GetParent(), "CENTER", x, y)
	c.holder:SetScale(math.max(0.05, k or 1))
	c:SetAlpha(a or 1)
	c.px, c.py = x, y
end

function RU:ReturnScene()
	local f = self.ret
	if f then
		return f
	end
	f = CreateFrame("Frame", "CuratorRestoreReturn", UIParent)
	f:SetAllPoints(UIParent)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	-- (nothing under it is clicked, a click in the dark does nothing, the wheel turns nothing)
	f:EnableMouse(true)
	f:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(f, "OnMouseWheel", function() end)
	f:Hide()
	f.dim = f:CreateTexture(nil, "BACKGROUND")
	f.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.dim, 0.01, 0.01, 0.03, 0.9)
	-- its light: the glow, the rays, the circle of the enchanters turning (on the card that comes back)
	f.lightSpot = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.lightSpot, 1, 1)
	f.lightSpot:SetPoint("CENTER", f, "CENTER", 0, RET_Y)
	local function Light(file, sub, color, size)
		local t = f:CreateTexture(nil, "BORDER", nil, sub)
		t:SetTexture(MEDIA .. file)
		t:SetBlendMode("ADD")
		t:SetVertexColor(color[1], color[2], color[3])
		CuratorOctoFull.SetSize(t, size, size)
		t:SetPoint("CENTER", f.lightSpot, "CENTER")
		t:SetAlpha(0)
		return t
	end
	f.glow = Light("Glow", 0, ARCANE, 760)
	f.rays = Light("Rays", 1, ARCANE, 820)
	f.circle = Light("RestoreCircle", 2, ARCANE, 520)
	-- the cards: the copy as it is (After, the one that comes back), the copy as it was (Before); of a booster or of a case
	f.cards = {}
	f.cases = {}
	-- over them: the runes, the flash, the sparks
	local fx = CreateFrame("Frame", nil, f)
	fx:SetAllPoints()
	fx:SetFrameLevel(f:GetFrameLevel() + 60)
	f.fx = fx
	f.runes = fx:CreateTexture(nil, "OVERLAY", nil, 1)
	f.runes:SetTexture(MEDIA .. "TitanRunes")
	f.runes:SetBlendMode("ADD")
	f.runes:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	CuratorOctoFull.SetSize(f.runes, ns.CARD_SIZES[RET_SIZE][1] * 1.24, ns.CARD_SIZES[RET_SIZE][2] * 1.17)
	f.runes:SetPoint("CENTER", f.lightSpot, "CENTER")
	f.runes:SetAlpha(0)
	f.flash = fx:CreateTexture(nil, "OVERLAY", nil, -2)
	f.flash:SetTexture(MEDIA .. "Glow")
	f.flash:SetBlendMode("ADD")
	f.flash:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
	CuratorOctoFull.SetSize(f.flash, 640, 760)
	f.flash:SetPoint("CENTER", f.lightSpot, "CENTER")
	f.flash:SetAlpha(0)
	f.sparks = ns.Particles:New(fx, 70)
	f.motes = ns.Particles:New(fx, 40, "Twinkle")
	-- the words: what it is, at the top; under the cards, Before and After, their flaws; what he did, his words
	local words = CreateFrame("Frame", nil, f)
	words:SetAllPoints()
	words:SetFrameLevel(f:GetFrameLevel() + 70)
	f.words = words
	f.title = Hud.Text(words, 13, "")
	f.title:SetPoint("CENTER", f, "CENTER", 0, 318)
	f.title:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	f.name = S.Text(words, "GameFontNormalHuge")
	f.name:SetPoint("CENTER", f, "CENTER", 0, 292)
	f.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.sub = S.Text(words, "GameFontDisable")
	f.sub:SetPoint("CENTER", f, "CENTER", 0, 266)
	local H2 = ns.CARD_SIZES[RET_SIZE][2] / 2
	local function Under(x)
		local t = S.Text(words, "GameFontNormalLarge")
		t:SetPoint("CENTER", f, "CENTER", x, RET_Y - H2 - 22)
		local n = S.Text(words, "GameFontHighlight")
		n:SetPoint("CENTER", f, "CENTER", x, RET_Y - H2 - 44)
		return t, n
	end
	f.beforeLabel, f.beforeFlaws = Under(-RET_X)
	f.afterLabel, f.afterFlaws = Under(RET_X)
	f.sum = S.Text(words, "GameFontNormalLarge")
	f.sum:SetPoint("CENTER", f, "CENTER", 0, RET_Y - H2 - 80)
	f.sum:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	f.quote = S.Text(words, "GameFontHighlight")
	f.quote:SetPoint("CENTER", f, "CENTER", 0, RET_Y - H2 - 106)
	f.quote:SetWidth(700)
	CuratorOctoFull.SetWordWrap(f.quote, true)
	f.quote:SetTextColor(0.92, 0.88, 1)
	f.hint = S.Text(words, "GameFontDisableSmall")
	f.hint:SetPoint("CENTER", f, "CENTER", 0, RET_Y - H2 - 132)
	f.hint:SetText(L["Click a card to look at it closely"])
	-- the one way out
	f.close = Hud.ClaimButton(words, 190, 34, L["Close"])
	f.close:SetPoint("CENTER", f, "CENTER", 0, RET_Y - H2 - 170)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		RU:EndReturn()
	end)
	-- (the cards that rise, the light that turns)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		CuratorOctoFull.SetRotation(self.circle, self.t * 0.9)
		CuratorOctoFull.SetRotation(self.rays, -self.t * 0.12)
		for _, c in ipairs(self.shown or {}) do
			if c:IsShown() and c.Tick then
				c:Tick(self.t)
			end
		end
	end)
	self.ret = f
	return f
end

-- The card of the return of this kind and of this place (1 After, 2 Before), made the first time.
function RU:RetCard(kind, i)
	local f = self:ReturnScene()
	local list = kind == "case" and f.cases or f.cards
	local c = list[i]
	if not c then
		c = RetCard(f, kind, i == 1 and RET_X or -RET_X, RET_Y)
		CuratorOctoFull.SetScript(c.hit, "OnClick", function()
			RU:RetInspect(i)
		end)
		CuratorOctoFull.SetScript(c.hit, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(i == 1 and L["After"] or L["Before"], 1, 1, 1)
			GameTooltip:AddLine(L["Click a card to look at it closely"], 0.4, 1, 0.4)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(c.hit, "OnLeave", function()
			GameTooltip:Hide()
		end)
		list[i] = c
	end
	return c
end

-- A card of the return dressed: the copy of its card (a booster's: card, rec; a case's: desc, w), with this wear on it.
local function Dress(c, x, wear)
	if x.case then
		local CD = ns.CaseDetail
		local pick = CD.PickOf(x.desc, x.w)
		pick.wear = wear
		c:Set(pick, ns.CrateUI and ns.CrateUI.RANKS)
		local def = ns.Crates and ns.Crates[x.desc.case]
		c:SetBack(def and def.art and def.art.back or nil)
		c:SetLive(true)
		return
	end
	local CP = ns.Copies
	c:SetCard(x.card, { owned = true, finish = CP.Finish(x.rec), pattern = CP.Pattern(x.rec), facing = 0, wear = wear })
	c:ShowSide("front")
end

-- (the flaws of a card, by what they are and where: a mishap of his known again after the card is laid anew)
local function FlawKey(fl)
	return string.format(("%s:%.3f:%.3f"), tostring(fl.kind), fl.x or 0, fl.y or 0)
end

-- A copy picked up (res: Restore.lua, R:PickUp or R:PickUpCase), its return on the screen. x: what it was ({ card,
-- rec } of a booster; { case = true, desc, w } of a case), before: its wear before he gave it back.
function RU:Return(res, x, before)
	local f = self:ReturnScene()
	ns.CancelOwner(RET)
	if f.ins then
		f.ins:Hide()
	end
	local kind = x.case and "case" or "card"
	for _, list in ipairs({ f.cards, f.cases }) do
		for _, c in ipairs(list) do
			c:Hide()
			c.hit:Hide()
		end
	end
	local after = x.case and ns.Cases.WearOf(x.w) or ns.Wear.Of(x.rec)
	local cA, cB = self:RetCard(kind, 1), self:RetCard(kind, 2)
	f.shown = { cA, cB }
	f.res, f.x, f.before, f.after = res, x, before, after
	Dress(cA, x, before)
	Dress(cB, x, before)
	Place(cA, 0, RET_Y, 0.82, 0)
	cA:Show()
	cB:Hide()
	f.lightSpot:ClearAllPoints()
	f.lightSpot:SetPoint("CENTER", f, "CENTER", 0, RET_Y)
	-- what it is
	local card = x.case and x.desc or x.card
	f.title:SetText(E.Upper(L["Restoration"]))
	f.name:SetText(NameOf(card))
	local idx = IndexOf(card, res.id)
	f.sub:SetText(idx and string.format(L["The copy %s"], "#" .. idx) or "")
	for _, t in ipairs({ f.beforeLabel, f.beforeFlaws, f.afterLabel, f.afterFlaws, f.sum, f.hint, f.quote }) do
		t:SetAlpha(0)
	end
	f.beforeLabel:SetText(L["Before"])
	f.afterLabel:SetText(L["After"])
	local nAfter = CuratorOctoFull.Length((x.case and R:CaseFlaws(x.w) or R:Flaws(x.rec)))
	f.beforeFlaws:SetText(string.format(L["Flaws: %d"], res.before or 0))
	f.afterFlaws:SetText(string.format(L["Flaws: %d"], nAfter))
	if (res.n or 0) > 0 then
		f.sum:SetText(string.format(L["%d of %d flaws mended"], res.mended or 0, res.n) .. ((res.mishaps or 0) > 0 and L[", and a mark of his work"] or ""))
	else
		f.sum:SetText(string.format(L["%s is back from the enchanter: have it appraised to see what it gained."], NameOf(card)))
	end
	f.quote:SetText("")
	f.words:SetAlpha(1)
	f.close:Hide()
	f.close:SetAlpha(0)
	for _, t in ipairs({ f.glow, f.rays, f.circle, f.runes, f.flash }) do
		t:SetAlpha(0)
	end
	f.t = 0
	f:SetAlpha(0)
	f:Show()
	f:Raise()
	-- (his window: nothing more to pick up until this one is closed)
	self:PaintPanel()
	-- (the alerts wait for its end, as for the other scenes)
	if ns.Toast and ns.Toast.Hold then
		ns.Toast:Hold()
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.open)
	ns.Tween(R_IN, function(e)
		f:SetAlpha(e)
	end, nil, Ease.outQuad, RET)
	-- the light of the enchanters
	ns.Tween(0.8, function(e)
		f.glow:SetAlpha(0.42 * e)
		f.rays:SetAlpha(0.22 * e)
		f.circle:SetAlpha(0.85 * e)
		f.runes:SetAlpha(0.8 * e)
	end, nil, Ease.outQuad, RET, R_IN * 0.6)
	-- the copy comes back in it, every flaw it left with on it
	ns.Delay(R_CARD, function()
		ns.Play(ns.SND.reveal[3])
		ns.Play(ns.SND.holo)
		f.flash:SetAlpha(0.8)
		ns.Tween(0.7, function(_, raw)
			f.flash:SetAlpha(0.8 * (1 - raw))
		end, nil, Ease.outQuad, RET)
		ns.Tween(0.6, function(e)
			Place(cA, 0, RET_Y, 0.82 + 0.18 * e, e)
		end, nil, Ease.outBack, RET)
		f.sparks:Burst(0, RET_Y, ARCANE, 34, 260, 0.9, 16)
		f.sparks:Burst(0, RET_Y, GOLD, 10, 160, 0.8, 12)
	end, RET)
	-- his words
	ns.Delay(R_WORDS, function()
		f.quote:SetAlpha(1)
		local line = self.said or R:Line(R.SAY_BACK)
		local text = string.format(L["“%s”"], line)
		local chars = Chars(text)
		local n = 0
		ns.Tween(1.0, function(_, raw)
			local k = math.floor(raw * CuratorOctoFull.Length(chars) + 0.5)
			if k ~= n then
				n = k
				f.quote:SetText(table.concat(chars, "", 1, k))
			end
		end, function()
			f.quote:SetText(text)
		end, Ease.linear, RET)
	end, RET)
	-- the flaws he mended light up, then go for good
	ns.Delay(R_MEND, function()
		local set = {}
		for _, id in ipairs(res.gone or {}) do
			set[id] = true
		end
		local fading = {}
		local W, H = cA:GetWidth(), cA:GetHeight()
		for _, fl in ipairs(cA.wearFlaws or {}) do
			if set[fl.id] then
				for _, p in ipairs(fl.pieces or {}) do
					if p:IsShown() then
						fading[CuratorOctoFull.Length(fading) + 1] = { p, p.base or p:GetAlpha() }
						p:SetVertexColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
					end
				end
				f.motes:Rise((fl.x - 0.5) * W - 12, (fl.x - 0.5) * W + 12, RET_Y + (0.5 - fl.y) * H, ARCANE_HI, 3, 70, 1.2, 12)
			end
		end
		f.fading = fading
		if CuratorOctoFull.Length(fading) > 0 then
			ns.Play(ns.SND.shiny)
			ns.Tween(R_GONE, function(e)
				for _, q in ipairs(fading) do
					q[1].base = q[2] * (1 - e)
					q[1]:SetAlpha(q[1].base)
				end
			end, nil, Ease.inQuad, RET, 0.35)
		end
	end, RET)
	-- the copy as it is now: what went wrong at his bench comes on it
	ns.Delay(R_MARK, function()
		self:RetAfter()
	end, RET)
	-- Before beside After
	ns.Delay(R_SPLIT, function()
		self:RetSplit()
	end, RET)
	ns.Delay(R_SHOW, function()
		self:RetShown()
	end, RET)
end

-- (R_MARK) The copy that came back laid with its wear as it is now; its new mishaps coming on it, in a flash of red.
function RU:RetAfter()
	local f = self.ret
	if not (f and f.res) then
		return
	end
	local cA = f.shown[1]
	local before = {}
	for _, fl in ipairs(cA.wearFlaws or {}) do
		if fl.mishap then
			before[FlawKey(fl)] = true
		end
	end
	if ns.WearUI and ns.WearUI.Set then
		ns.WearUI.Set(cA, f.after, true)
	end
	if cA.opts then
		cA.opts.wear = f.after
	end
	local W, H = cA:GetWidth(), cA:GetHeight()
	local came = 0
	for _, fl in ipairs(cA.wearFlaws or {}) do
		if fl.mishap and not before[FlawKey(fl)] then
			came = came + 1
			for _, p in ipairs(fl.pieces or {}) do
				local _, p = _, p; if p:IsShown() then
					local base = p.base or p:GetAlpha()
					p.base = 0
					p:SetAlpha(0)
					ns.Tween(0.6, function(e)
						p.base = base * e
						p:SetAlpha(p.base)
					end, nil, Ease.outQuad, RET, 0.15)
				end
			end
			f.sparks:Burst((fl.x - 0.5) * W, RET_Y + (0.5 - fl.y) * H, { 1, 0.42, 0.3 }, 10, 90, 0.6, 10)
		end
	end
	if came > 0 then
		ns.Play(ns.SND.sealBreak)
	end
end

-- (R_SPLIT) The copy that came back steps to the right, the copy as it left him comes on the left.
function RU:RetSplit()
	local f = self.ret
	if not (f and f.res) then
		return
	end
	local cA, cB = f.shown[1], f.shown[2]
	Place(cB, -RET_X + 50, RET_Y, 1, 0)
	cB:Show()
	ns.Play(ns.SND.cardFlip)
	ns.Tween(0.6, function(e)
		Place(cA, RET_X * e, RET_Y, 1, 1)
		Place(cB, -RET_X + 50 * (1 - e), RET_Y, 1, 0.92 * e)
		f.lightSpot:ClearAllPoints()
		f.lightSpot:SetPoint("CENTER", f, "CENTER", RET_X * e, RET_Y)
		f.runes:SetAlpha(0.8 * (1 - e))
		f.circle:SetAlpha(0.85 - 0.45 * e)
	end, nil, Ease.outCubic, RET)
end

-- (R_SHOW) Under them what each is, what he did; the cards to click; Close.
function RU:RetShown()
	local f = self.ret
	if not (f and f.res) then
		return
	end
	-- (the scene skipped to here: everything where it ends)
	ns.CancelOwner(RET)
	f:SetAlpha(1)
	local cA, cB = f.shown[1], f.shown[2]
	for _, q in ipairs(f.fading or {}) do
		q[1].base = 0
		q[1]:SetAlpha(0)
	end
	f.fading = nil
	Place(cA, RET_X, RET_Y, 1, 1)
	Place(cB, -RET_X, RET_Y, 1, 0.92)
	cB:Show()
	f.lightSpot:ClearAllPoints()
	f.lightSpot:SetPoint("CENTER", f, "CENTER", RET_X, RET_Y)
	f.glow:SetAlpha(0.42)
	f.rays:SetAlpha(0.22)
	f.circle:SetAlpha(0.4)
	f.runes:SetAlpha(0)
	f.flash:SetAlpha(0)
	local line = self.said or ""
	if (f.quote:GetText() or "") == "" and line ~= "" then
		f.quote:SetText(string.format(L["“%s”"], line))
	end
	f.quote:SetAlpha(1)
	f.close:Show()
	CuratorOctoFull.SetEnabled(f.close, true)
	ns.Tween(0.4, function(e)
		for _, t in ipairs({ f.beforeLabel, f.beforeFlaws, f.afterLabel, f.afterFlaws, f.sum, f.hint }) do
			t:SetAlpha(e)
		end
		f.close:SetAlpha(e)
	end, nil, Ease.outQuad, RET)
	if f.close.SetPulse then
		f.close:SetPulse(true)
	end
	cA.hit:Show()
	cB.hit:Show()
	f.ready = true
end

-- A card of the return held up close (1: After, 2: Before): turned with the mouse, the wheel brings it closer; Back to
-- the two of them, the one way back.
function RU:RetInspect(i)
	local f = self.ret
	if not (f and f.ready and f.x) then
		return
	end
	local ins = f.ins
	if not ins then
		ins = CreateFrame("Frame", nil, f)
		ins:SetAllPoints()
		ins:SetFrameLevel(f:GetFrameLevel() + 90)
		-- (a click beside the card does nothing: Back only)
		ins:EnableMouse(true)
		ins.dim = ins:CreateTexture(nil, "BACKGROUND")
		ins.dim:SetAllPoints()
		CuratorOctoFull.ColorTexture(ins.dim, 0.01, 0.01, 0.02, 0.9)
		ins.halo = ins:CreateTexture(nil, "BORDER")
		ins.halo:SetTexture(MEDIA .. "Glow")
		ins.halo:SetBlendMode("ADD")
		ins.halo:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
		ins.halo:SetAlpha(0.35)
		CuratorOctoFull.SetSize(ins.halo, 620, 720)
		ins.halo:SetPoint("CENTER", ins, "CENTER", 0, 20)
		ins.spot = CreateFrame("Frame", nil, ins)
		CuratorOctoFull.SetSize(ins.spot, 1, 1)
		ins.spot:SetPoint("CENTER", ins, "CENTER", 0, 20)
		ins.holder = CreateFrame("Frame", nil, ins.spot)
		CuratorOctoFull.SetSize(ins.holder, 1, 1)
		ins.holder:SetPoint("CENTER", ins.spot, "CENTER")
		ins.holder:SetFrameLevel(ins:GetFrameLevel() + 6)
		ins.cards = {}
		ins.title = S.Text(ins, "GameFontNormalHuge")
		ins.title:SetPoint("CENTER", ins, "CENTER", 0, 300)
		ins.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
		ins.sub = S.Text(ins, "GameFontNormalLarge")
		ins.sub:SetPoint("CENTER", ins, "CENTER", 0, 272)
		ins.sub:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
		ins.hint = S.Text(ins, "GameFontDisable")
		ins.hint:SetPoint("CENTER", ins, "CENTER", 0, -262)
		ins.hint:SetText(L["Drag to turn the card · Mouse wheel to zoom"])
		ins.back = S.Button(ins, L["Back"], 160, 28)
		ins.back:SetPoint("CENTER", ins, "CENTER", 0, -300)
		ins.back:SetFrameLevel(ins:GetFrameLevel() + 40)
		CuratorOctoFull.SetScript(ins.back, "OnClick", function()
			RU:RetUninspect()
		end)
		ins:EnableMouseWheel(true)
		CuratorOctoFull.SetScript(ins, "OnMouseWheel", function(_, delta)
			if ins.card then
				ns.Inspect:Zoom(ins.card, delta)
			end
		end)
		CuratorOctoFull.SetScript(ins, "OnUpdate", function(_, elapsed)
			ins.t = (ins.t or 0) + elapsed
			local c = ins.card
			if c then
				ns.Inspect:Update(c, elapsed)
				if c.Tick then
					c:Tick(ins.t)
				end
			end
		end)
		ins:Hide()
		f.ins = ins
	end
	local x = f.x
	local kind = x.case and "case" or "card"
	local c = ins.cards[kind]
	if not c then
		local W = ns.CARD_SIZES[RET_SIZE][1]
		c = kind == "case" and ns.CrateCard.New(ins.holder, W) or ns.NewCard(ins.holder, RET_SIZE)
		c:SetPoint("CENTER", ins.holder, "CENTER")
		ns.Inspect:Attach(c, ins.holder, { zoom = { 0.8, 1.45, 1 }, lean = kind ~= "case" })
		ins.cards[kind] = c
	end
	for _, o in pairs(ins.cards) do
		CuratorOctoFull.SetShown(o, o == c)
	end
	ins.card = c
	Dress(c, x, i == 1 and f.after or f.before)
	if ns.Inspect.Reset then
		ns.Inspect:Reset(c, 0, 1)
	end
	ins.title:SetText(f.name:GetText() or "")
	ins.sub:SetText(i == 1 and L["After"] or L["Before"])
	ins.which = i
	GameTooltip:Hide()
	ns.Play(ns.SND.cardFlip)
	ins:SetAlpha(0)
	ins:Show()
	-- (the two cards and their words step back meanwhile: the one held up close alone)
	local cA, cB = f.shown[1], f.shown[2]
	ns.Tween(0.2, function(e)
		ins:SetAlpha(e)
		f.words:SetAlpha(1 - e)
		cA:SetAlpha(1 - e)
		cB:SetAlpha(0.92 * (1 - e))
	end, nil, Ease.outQuad, ins)
end

-- Back from a card held up close to the two of them.
function RU:RetUninspect()
	local f = self.ret
	local ins = f and f.ins
	if not (ins and ins:IsShown()) then
		return
	end
	if ins.card and ins.card.turn then
		ins.card.turn.dragging = false
	end
	ns.Play(ns.SND.close)
	ns.CancelOwner(ins)
	ins:Hide()
	ins.which = nil
	f.words:SetAlpha(1)
	if f.shown then
		f.shown[1]:SetAlpha(1)
		f.shown[2]:SetAlpha(0.92)
	end
end

-- Its return closed (Close): the panel of the enchanter again, the next one ready to pick up.
function RU:EndReturn(quick)
	local f = self.ret
	if not (f and f:IsShown()) then
		return
	end
	ns.CancelOwner(RET)
	f.ready = nil
	if f.ins then
		ns.CancelOwner(f.ins)
		f.ins:Hide()
	end
	local function Gone()
		f:Hide()
		f.res, f.x, f.shown, f.fading = nil, nil, nil, nil
		f.sparks:Clear()
		f.motes:Clear()
		if ns.Toast and ns.Toast.Resume then
			ns.Toast:Resume()
		end
		RU:PaintPanel()
	end
	if quick then
		Gone()
		return
	end
	ns.Play(ns.SND.close)
	CuratorOctoFull.SetEnabled(f.close, false)
	ns.Tween(0.3, function(e)
		f:SetAlpha(1 - e)
	end, Gone, Ease.outQuad, RET)
end

-- A return on the screen.
function RU:Returning()
	return self.ret ~= nil and self.ret:IsShown()
end

-------------------------------------------------------------------------------
-- At an enchanter: the window of Curator beside his
-------------------------------------------------------------------------------
local PANEL_W = 270

function RU:Panel()
	if self.panel then
		return self.panel
	end
	local f = CreateFrame("Frame", "CuratorRestorePanel", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, PANEL_W, 196)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
	end
	f.ring = f:CreateTexture(nil, "ARTWORK")
	f.ring:SetTexture(MEDIA .. "RestoreCircle")
	f.ring:SetBlendMode("ADD")
	f.ring:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
	CuratorOctoFull.SetSize(f.ring, 46, 46)
	f.ring:SetPoint("TOPLEFT", 8, -6)
	f.icon = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.icon:SetTexture(ICON)
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetSize(f.icon, 28, 28)
	f.icon:SetPoint("CENTER", f.ring, "CENTER")
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("TOPLEFT", f.ring, "TOPRIGHT", 6, -6)
	f.title:SetText(L["Curator: the restoration"])
	f.sub = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.sub:SetWidth(PANEL_W - 80)
	f.text = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.text:SetPoint("TOPLEFT", 16, -58)
	f.text:SetWidth(PANEL_W - 32)
	CuratorOctoFull.SetWordWrap(f.text, true)
	f.text:SetTextColor(0.85, 0.85, 0.85)
	f.text:SetText(L["Have a copy restored: open your album, click a card, choose its copy, then Restore."])
	f.count = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.count:SetPoint("TOPLEFT", f.text, "BOTTOMLEFT", 0, -6)
	f.count:SetWidth(PANEL_W - 32)
	CuratorOctoFull.SetWordWrap(f.count, true)
	f.count:SetTextColor(ARCANE_HI[1], ARCANE_HI[2], ARCANE_HI[3])
	f.say = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.say:SetPoint("TOPLEFT", f.count, "BOTTOMLEFT", 0, -6)
	f.say:SetWidth(PANEL_W - 32)
	CuratorOctoFull.SetWordWrap(f.say, true)
	f.say:SetTextColor(1, 0.92, 0.66)
	f.pick = Hud.ClaimButton(f, 210, 28, "")
	f.pick:SetPoint("BOTTOM", 0, 40)
	CuratorOctoFull.SetScript(f.pick, "OnClick", function()
		RU:PickClick()
	end)
	f.open = S.Button(f, L["Open my album"], 210, 22)
	f.open:SetPoint("BOTTOM", 0, 13)
	CuratorOctoFull.SetScript(f.open, "OnClick", function()
		ns.Play(ns.SND.click)
		RU:OpenAlbum()
	end)
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	f.flash = f:CreateTexture(nil, "OVERLAY")
	f.flash:SetTexture(MEDIA .. "Glow")
	f.flash:SetBlendMode("ADD")
	f.flash:SetVertexColor(ARCANE[1], ARCANE[2], ARCANE[3])
	f.flash:SetPoint("TOPLEFT", -30, 30)
	f.flash:SetPoint("BOTTOMRIGHT", 30, -30)
	f.flash:Hide()
	local fxf = CreateFrame("Frame", nil, f)
	fxf:SetAllPoints()
	fxf:SetFrameLevel(f:GetFrameLevel() + 6)
	f.sparks = ns.Particles:New(fxf, 30)
	-- (the times counted down while it is shown)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		if self.t >= 1 then
			self.t = 0
			RU:PaintPanel()
		end
	end)
	self.panel = f
	return f
end

function RU:PaintPanel()
	local f = self.panel
	if not (f and f:IsShown()) then
		return
	end
	f.sub:SetText(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 12)))
	local away, ready = R:Counts()
	local lines = {}
	if away == 0 then
		lines[1] = L["None of your copies is at an enchanter."]
	else
		lines[1] = string.format(L["At the enchanters: %d · ready: %d"], away, ready)
		local shown = 0
		for _, x in ipairs(R:Away()) do
			if shown >= 3 then
				break
			end
			shown = shown + 1
			-- (1 November: a card of a case, its name as the detail knows it)
			local name
			if x.case then
				local w = ns.Cases and ns.Cases:Card(x.id)
				name = (w and ns.CaseDetail) and ns.CaseDetail.Name(ns.CaseDetail.DescOf(w)) or "?"
			else
				name = C:Name(x.card)
			end
			lines[CuratorOctoFull.Length(lines) + 1] = "· " .. name .. "  " .. (x.ready and ("|cff66ff66" .. L["ready"] .. "|r") or ns.Duration(x.left))
		end
		-- (the first ready first: the next one is the first of the list)
		if away > shown then
			lines[CuratorOctoFull.Length(lines) + 1] = "· " .. string.format(L["and %d more"], away - shown)
		end
	end
	f.count:SetText(table.concat(lines, "\n"))
	f.say:SetText(self.said and string.format(L["“%s”"], self.said) or "")
	-- (copies away, none ready: what the enchanter says of them. 1 November, his word: one card at a time)
	if ready == 0 and away > 0 then
		f.pick:SetLabel(L["Ask about my cards"])
	else
		f.pick:SetLabel(string.format(L["Pick up a card (%d ready)"], ready))
	end
	CuratorOctoFull.SetEnabled(f.pick, away > 0 and R:AtEnchanter() and not self:Returning())
	-- (its height: what it says)
	local h = 58 + (CuratorOctoFull.GetStringHeight(f.text) or 30) + 6 + (CuratorOctoFull.GetStringHeight(f.count) or 14) + 6 + (self.said and ((CuratorOctoFull.GetStringHeight(f.say) or 14) + 6) or 0) + 80
	f:SetHeight(math.max(176, math.floor(h)))
end

-- (1 November, his word: « "récupérer" c'est pour une seule carte ... Jamais de "tout récupérer" ») One copy picked up,
-- the first ready, its return on the screen (RU:Return); none ready: what he says of them.
function RU:PickClick()
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	if not R:AtEnchanter() then
		ns.Play(ns.SND.close)
		return
	end
	-- (one at a time: the one on the screen closed first)
	if self:Returning() then
		return
	end
	local x
	for _, it in ipairs(R:Away()) do
		if it.ready and not x then
			x = it
		end
	end
	if not x then
		ns.Play(ns.SND.click)
		local line = L[R.SAY_WAIT]
		R:Say(line)
		if ns.Gossip and ns.Gossip.open then
			ns.Gossip:Say(line)
		end
		self.said = line
		self:PaintPanel()
		return
	end
	-- (its wear as it left him: Before)
	local CS = ns.Cases
	local before = x.case and CS.WearOf(x.rec) or ns.Wear.Of(x.rec)
	self.busy = true
	local res
	if x.case then
		res = R:PickUpCase(x.id)
	else
		res = R:PickUp(x.card, x.rec.i)
	end
	self.busy = nil
	if not res then
		ns.Play(ns.SND.close)
		self:PaintPanel()
		return
	end
	self:Back({ res })
	local what
	if x.case then
		local w = CS:Card(x.id)
		what = w and { case = true, w = w, desc = ns.CaseDetail.DescOf(w) } or nil
	else
		what = { card = x.card, rec = x.rec }
	end
	if what then
		self:Return(res, what, before)
	end
end

-- The album, on the contents (or the inventory: UI/Inventory.lua, when there is one).
function RU:OpenAlbum()
	if not (A.frame and A.frame:IsShown()) then
		A:Toggle()
	end
	if ns.InventoryUI and ns.InventoryUI.Open then
		-- (1.13.0: the inventory on the copies at an enchanter, when there are some)
		local away = ns.Restore and CuratorOctoFull.Select(1, ns.Restore:Counts()) or 0
		local ok = pcall(ns.InventoryUI.Open, ns.InventoryUI, (tonumber(away) or 0) > 0 and "away" or nil)
		if ok then
			return
		end
	end
	if A.mode ~= "mine" and A.mode ~= "contents" then
		A:SetMode("contents")
	end
end

function RU:ShowPanel(show)
	if not show then
		if self.panel then
			self.panel:Hide()
		end
		self.said = nil
		return
	end
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return
	end
	local f = self:Panel()
	f:ClearAllPoints()
	local owner
	for _, name in ipairs({ "ClassTrainerFrame", "GossipFrame" }) do
		local w = rawget(_G, name)
		if not owner and w and w.IsShown and w:IsShown() then
			owner = w
		end
	end
	if owner then
		f:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 0)
	else
		f:SetPoint("LEFT", UIParent, "LEFT", 420, 80)
	end
	f:Show()
	-- (above the album when it is open: a click on either brings it to the front)
	f:Raise()
	self:PaintPanel()
end

-------------------------------------------------------------------------------
-- The lines of the enchanters in their window of dialogue
-------------------------------------------------------------------------------
ns.Gossip:Provide("enchanter", function()
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return {}
	end
	local lines = { {
		text = L["Restore a card"],
		icon = ICON,
		click = function()
			RU:OpenAlbum()
			ns.Gossip:Say(L[R.SAY_ASK])
		end,
	} }
	local _, ready = R:Counts()
	if ready > 0 then
		lines[CuratorOctoFull.Length(lines) + 1] = {
			-- (1 November, his word: one card at a time, its return on the screen)
			text = string.format(L["Pick up a restored card (%d ready)"], ready),
			icon = ICON,
			click = function()
				RU:PickClick()
			end,
		}
	end
	return lines
end)

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
do
	local buildDetail = A.BuildDetail
	function A:BuildDetail(...)
		local r = buildDetail(self, unpack(arg, 1, arg.n))
		if self.detail then
			RU:BuildDetail(self.detail)
		end
		return r
	end

	local showDetail = A.ShowDetail
	function A:ShowDetail(...)
		RU:End(true)
		RU:HideQuote()
		local d = self.detail
		if d and d.rest then
			d.rest.button.armed = nil
		end
		local r = showDetail(self, unpack(arg, 1, arg.n))
		RU:Paint()
		return r
	end

	local hideDetail = A.HideDetail
	function A:HideDetail(...)
		RU:End(true)
		RU:HideQuote()
		local d = self.detail
		if d and d.rest then
			d.rest.button.armed = nil
		end
		return hideDetail(self, unpack(arg, 1, arg.n))
	end

	-- (the block of the expert, and of the masters: in their place, at an enchanter, the block of the restoration)
	local paintAppraise = A.PaintAppraise
	function A:PaintAppraise(...)
		local r = paintAppraise(self, unpack(arg, 1, arg.n))
		RU:Paint()
		return r
	end
end

ns.On("ENCHANTER_CHANGED", function(on)
	RU:ShowPanel(on)
	local d = A.detail
	if d and d:IsShown() and not RU.cer and not (XU and XU.cer) then
		A:PaintAppraise()
		RU:PaintQuoteButton()
	end
end)

ns.On("RUBIES_CHANGED", function()
	RU:PaintPanel()
	if A.detail and A.detail:IsShown() and not (RU.cer or RU.busy) then
		RU:Paint()
	end
end)

ns.On("COPIES_CHANGED", function()
	RU:PaintPanel()
end)

ns.On("COPY_SELECTED", function()
	local d = A.detail
	if d and d.rest then
		d.rest.button.armed = nil
	end
	-- (another copy: its quote, not this one's)
	RU:HideQuote()
	RU:PaintQuoteButton()
end)
