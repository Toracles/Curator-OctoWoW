local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local E = ns.Expertise
local SL = ns.Masters
local RB = ns.Rubies
local C = ns.Collection
local XU = ns.ExpertiseUI

-------------------------------------------------------------------------------
-- (1.12.0) The corrupted cards and their masters on the screen (Seal.lua). Shown big in the album, a corrupted card
-- of mine tells its corrupted copies (one chosen: its corruption on the card), whether it is sealed (its rank, its
-- pact, its master) and gets its two buttons: Seal, at a Master of Warlocks; Purify, at a Master of Priests (in the
-- window of dialogue of a master: a line of Curator that opens the album on its corrupted cards).
-- * The seal: the room darkens, a circle of fel opens behind the card; the warlock's four rites (the runes traced
--   around it, a soul shard driven into it, the chains that bind it, the shadow drawn into it), a mark each on his
--   pact; its rank comes down on the card, the reliquary closes on it, its wax stamped.
-- * The purification: the room darkens, the Light falls on the card, a circle of holy runes under it; the corruption
--   is washed off as its gauge counts down; a plain copy again.
-- A sealed card wears the tab of its rank on the pages of the album, and its reliquary when it is shown big.
-------------------------------------------------------------------------------
local SU = {}
ns.SealUI = SU

local GOLD = S.GOLD
local FEL = { 0.42, 1, 0.3 }
local FEL_DIM = { 0.22, 0.6, 0.16 }
local VIOLET = { 0.68, 0.3, 1 }
local SHADOW = { 0.12, 0.04, 0.2 }
local HOLY = { 1, 0.9, 0.62 }
local BONE = { 0.9, 0.86, 0.76 }
local ARM = 3                     -- (seconds) a click arms a button, a second click within confirms
-- a card in its reliquary, shown big: smaller, its case fits; out of it, as the album attaches it (UI/Expertise.lua)
local SLAB_ZOOM = XU.SLAB_ZOOM or 0.8
local SLAB_ZOOMS = XU.SLAB_ZOOMS or { 0.66, 1.02 }
local CARD_ZOOMS = XU.CARD_ZOOMS or { 0.85, 1.25 }
local DIM, DIM_SCENE = 0.62, 0.86
local SPOT, SPOT_SCENE = 0.32, 0.62
local CHIPS = 6                   -- the corrupted copies shown to choose from
-- the moments of a seal (seconds): the room darkens, the four rites, the ranks roll, the verdict alone, the reliquary
local INTRO, RITE, GAP, ROLL, HOLD, CLOSE = 0.55, 1.0, 0.12, 0.75, 0.85, 1.9
-- the moments of a purification: the room darkens, the Light comes down, the corruption washed off, its blessing
local P_INTRO, P_LIGHT, P_WASH, P_HOLD = 0.5, 0.7, 2.0, 1.4
local CER = {}  -- the owner of the animations of a rite (all of them stopped when it ends)
local FADE = {} -- the owner of the room coming back after it

local SIGIL_ICON = "Interface\\Icons\\Spell_Shadow_SoulGem"
local HOLY_ICON = "Interface\\Icons\\Spell_Holy_Purify"

-- The narrow font of the labels, the letters of the grimoires (the default font of a client in another script).
local LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }
local function LabelFont(fs, size, flags)
	if LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] then
		fs:SetFont("Fonts\\ARIALN.TTF", size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
end
local function PactFont(fs, size, flags)
	if LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] then
		fs:SetFont("Fonts\\MORPHEUS.TTF", size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
end

local function Tex(parent, file, layer, sub, blend, color)
	local t = parent:CreateTexture(nil, layer or "OVERLAY", nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
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

-- The letters of a text (for a text written letter by letter).
local function Chars(s)
	local out = {}
	for ch in CuratorOctoFull.Gmatch(tostring(s or ""), "[%z\1-\127\194-\244][\128-\191]*") do
		out[CuratorOctoFull.Length(out) + 1] = ch
	end
	return out
end

-------------------------------------------------------------------------------
-- The tab of a rank: the pact in small, its demon left of its line, its rank right of it
-------------------------------------------------------------------------------
function SU.Tab(parent, w, h)
	local t = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(t, w, h)
	t.glow = t:CreateTexture(nil, "BACKGROUND")
	t.glow:SetTexture(MEDIA .. "Glow")
	t.glow:SetBlendMode("ADD")
	t.glow:SetPoint("TOPLEFT", -w * 0.35, h * 1.1)
	t.glow:SetPoint("BOTTOMRIGHT", w * 0.35, -h * 1.1)
	t.glow:SetAlpha(0)
	t.shade = t:CreateTexture(nil, "BACKGROUND", nil, 1)
	CuratorOctoFull.ColorTexture(t.shade, 0, 0, 0, 0.55)
	t.shade:SetPoint("TOPLEFT", 1, -2)
	t.shade:SetPoint("BOTTOMRIGHT", 2, -2)
	t.paper = t:CreateTexture(nil, "ARTWORK")
	t.paper:SetTexture(MEDIA .. "SealLabel")
	t.paper:SetAllPoints()
	t.band = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.band:SetTexture(MEDIA .. "SealBand")
	t.band:SetAllPoints()
	-- (its demon in the narrow letters of a label, small; its rank in those of a grimoire)
	t.word = t:CreateFontString(nil, "OVERLAY")
	t.wordSize, t.room = math.max(6, h * 0.4), w - h * 1.45
	LabelFont(t.word, t.wordSize, "")
	t.word:SetPoint("LEFT", t, "LEFT", h * 0.3, 0)
	t.word:SetPoint("RIGHT", t, "RIGHT", -h * 1.15, 0)
	t.word:SetJustifyH("CENTER")
	t.word:SetWordWrap(false)
	t.word:SetShadowOffset(0, 0)
	t.num = t:CreateFontString(nil, "OVERLAY")
	t.numSize = math.max(8, h * 0.62)
	PactFont(t.num, t.numSize, "")
	t.num:SetPoint("CENTER", t, "RIGHT", -h * 0.62, 0)
	t.num:SetShadowOffset(0, 0)
	function t:SetRank(g)
		if not g then
			self:Hide()
			return
		end
		local c = SL.Color(g)
		self.band:SetVertexColor(c[1], c[2], c[3])
		local size = self.wordSize
		LabelFont(self.word, size, "")
		self.word:SetText(E.Upper(SL.Word(g)))
		while size > self.wordSize * 0.6 and ns.TextWidth(self.word) > self.room do
			size = size - 0.25
			LabelFont(self.word, size, "")
		end
		-- (a demon of a long name on a small tab: its rank alone, rather than its name cut)
		if ns.TextWidth(self.word) > self.room * 1.04 then
			self.word:SetText("")
		end
		self.word:SetTextColor(BONE[1], BONE[2], BONE[3])
		local roman = SL.Roman(g)
		PactFont(self.num, self.numSize * (CuratorOctoFull.Length(roman) >= 4 and 0.72 or (CuratorOctoFull.Length(roman) == 3 and 0.84 or 1)), "")
		self.num:SetText(roman)
		self.num:SetTextColor(0.55 + 0.45 * c[1], 0.55 + 0.45 * c[2], 0.55 + 0.45 * c[3])
		self.glow:SetVertexColor(c[1], c[2], c[3])
		self.glow:SetAlpha(g >= SL.MAX and 0.75 or 0)
		self:Show()
	end
	t:Hide()
	return t
end

-- The cards of the pages of the album: a card sealed wears the tab of its rank over its top (one appraised, its
-- grade: UI/Expertise.lua).
do
	local paintGrade = A.PaintGrade
	function A:PaintGrade(c, g)
		paintGrade(self, c, g)
		local card = c.card
		local rank = (not g) and card and self.mode ~= "member" and SL:Rank(card) or nil
		local t = c.sealTab
		if rank and not t then
			local w = c.W or 112
			t = SU.Tab(c, w * 0.64, w * 0.17)
			t:SetPoint("CENTER", c, "TOP", 0, 4)
			t:SetFrameLevel(c:GetFrameLevel() + 12)
			c.sealTab = t
		end
		if t then
			t:SetRank(rank)
		end
	end
end

-------------------------------------------------------------------------------
-- The detail of a corrupted card: its copies, its seal, its two buttons
-------------------------------------------------------------------------------
-- The copy of a card kept in a case: "seal" (the one sealed, in its reliquary), "case" (the one appraised, in the
-- expert's case: a plain one), or nil. (1.13.0: the copy chosen, UI/Copies.lua.)
function SU:Kept(card)
	if not card then
		return nil
	end
	local CU = ns.CopiesUI
	local rec = CU and CU:Selected(card)
	if rec then
		if rec.ws then
			return "seal"
		elseif ns.Copies.Grade(rec) then
			return "case"
		end
		return nil
	end
	if SL:Record(card) then
		return "seal"
	end
	if E:Appraised(card) then
		return "case"
	end
	return nil
end

-- The copy of a card shown big: the corruption of a corrupted copy not sealed (the one clicked), or nil: its copy
-- kept in a case, shown first; else the most corrupted. (The one clicked gone, purified: the next one, else its copy
-- kept.) And what its copy kept is (SU:Kept). (1.13.0: the copy chosen among its copies, UI/Copies.lua: a corrupted
-- one not sealed, its corruption; else what it is, and the copy.)
function SU:Chosen(card)
	local CU = ns.CopiesUI
	local rec = CU and card and CU:Selected(card)
	if rec then
		if rec.f == "c" and not rec.ws then
			return ns.Collection.Gauge(rec.cor), nil, rec
		end
		return nil, self:Kept(card), rec
	end
	self.sel = self.sel or {}
	local list = SL:Copies(card)
	local kept = self:Kept(card)
	local want = card and self.sel[card.key]
	if type(want) == "number" then
		for _, v in ipairs(list) do
			if v == want then
				return v, kept
			end
		end
		if list[1] or not kept then
			return list[1], kept
		end
		return nil, kept
	end
	if kept then
		return nil, kept
	end
	return list[1], kept
end

-- Whether the card shown is one of mine with corrupted copies, or sealed (its block, not the expert's). (1.13.0: the
-- copy chosen is a corrupted one, sealed or not.)
local function Corrupted(card)
	if not (card and A.mode ~= "member" and C:Owned(card)) then
		return false
	end
	local CU = ns.CopiesUI
	local rec = CU and CU:Selected(card)
	if rec then
		return rec.f == "c"
	end
	local e = C:Entry(card)
	return (e and (tonumber(e.c) or 0) > 0) or SL:Record(card) ~= nil
end
SU.Corrupted = Corrupted

-- A chip of a copy to choose (k: its corruption; "kept": its copy in a case).
local function Chip(v)
	local b = CreateFrame("Button", nil, v)
	CuratorOctoFull.SetSize(b, 44, 18)
	b.edge = b:CreateTexture(nil, "BACKGROUND")
	b.edge:SetAllPoints()
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.bg:SetPoint("TOPLEFT", 1, -1)
	b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
	b.text = S.Text(b, "GameFontHighlightSmall")
	b.text:SetPoint("CENTER")
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		SU:Choose(self.k)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		SU:ChipTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end

-- (lit: the copy shown; color: its edge else)
local function PaintChip(b, text, lit, color)
	b.text:SetText(text)
	b:SetWidth(math.max(44, math.ceil(ns.TextWidth(b.text)) + 16))
	local c = lit and FEL or color or VIOLET
	CuratorOctoFull.ColorTexture(b.edge, c[1], c[2], c[3], lit and 0.95 or 0.55)
	if lit then
		CuratorOctoFull.ColorTexture(b.bg, 0.07, 0.16, 0.06, 0.95)
		b.text:SetTextColor(1, 1, 1)
	else
		CuratorOctoFull.ColorTexture(b.bg, 0.09, 0.04, 0.13, 0.95)
		b.text:SetTextColor(0.82, 0.74, 0.92)
	end
	b:Show()
end

local function BuildBlock(d)
	local tw = d.textW
	local v = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(v, tw, 22)
	v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	-- its head: the tab of its rank, when it was sealed (not sealed: what it is)
	v.tab = SU.Tab(v, 92, 22)
	v.tab:SetPoint("TOPLEFT", 0, 0)
	v.line = S.Text(v, "GameFontHighlight", "LEFT")
	v.line:SetWordWrap(false)
	-- its four marks and its pact (not sealed: what its masters do)
	v.marks = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.marks:SetWidth(tw)
	v.marks:SetWordWrap(true)
	v.marks:SetSpacing(2)
	-- the copies to choose from: its copy kept in a case first, its corrupted ones
	v.copiesLabel = S.Text(v, "GameFontDisableSmall", "LEFT")
	v.copiesLabel:SetText(L["Copies:"])
	v.kept = Chip(v)
	v.kept.k = "kept"
	v.chips = {}
	for i = 1, CHIPS do
		v.chips[i] = Chip(v)
	end
	v.more = S.Text(v, "GameFontDisableSmall", "LEFT")
	-- the two buttons: the seal, the purification
	local function Btn(kind)
		local b = S.Button(v, "", 160, 22)
		b.kind = kind
		if b.SetMotionScriptsWhileDisabled then
			b:SetMotionScriptsWhileDisabled(true)
		end
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			SU:Click(self)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			SU:Tooltip(self)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(b, "OnUpdate", function(self)
			if self.armed and GetTime() - self.armed >= ARM then
				self.armed = nil
				SU:Paint()
			end
		end)
		return b
	end
	v.seal = Btn("seal")
	v.purify = Btn("purify")
	-- (1.14.0, Golden Loupe with Glance, talents of the Archivist: the rank a seal would give, seen before it is paid)
	v.loupe = S.Button(v, L["Golden Loupe"], 160, 22)
	if v.loupe.SetMotionScriptsWhileDisabled then
		v.loupe:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(v.loupe, "OnClick", function()
		SU:LoupeClick()
	end)
	CuratorOctoFull.SetScript(v.loupe, "OnEnter", function(self)
		SU:LoupeTooltip(self)
	end)
	CuratorOctoFull.SetScript(v.loupe, "OnLeave", function()
		GameTooltip:Hide()
	end)
	v.loupe:Hide()
	v:Hide()
	d.void = v
end

-- The warlock's tools around the card (behind it: his circle; over it: his runes, the shard, the chains, the
-- verdict), and the Light of the priest.
local function BuildRite(d)
	local c = d.card
	local W, H = c.W, c.H
	-- behind the card (on the detail itself, over its spotlight): the circle, its glow
	d.riteCircle = Tex(d, "StrikeRunes", "BORDER", 5, "ADD", FEL)
	d.riteGlow = Tex(d, "Glow", "BORDER", 4, "ADD", FEL)
	d.riteBeam = Tex(d, "Beam", "BORDER", 6, "ADD", HOLY)
	-- over the card
	local r = CreateFrame("Frame", nil, d)
	r:SetAllPoints()
	r:SetFrameLevel(c:GetFrameLevel() + 16)
	r:Hide()
	d.rite = r
	r.runes = Tex(r, "TitanRunes", "OVERLAY", 1, "ADD", FEL)
	CuratorOctoFull.SetSize(r.runes, W * 1.22, H * 1.16)
	r.runner = Tex(r, "Glow", "OVERLAY", 4, "ADD", { 0.7, 1, 0.6 })
	CuratorOctoFull.SetSize(r.runner, 54, 54)
	r.shard = Tex(r, "Shard", "OVERLAY", 3, "ADD", VIOLET)
	CuratorOctoFull.SetSize(r.shard, 46, 46)
	r.shardGlow = Tex(r, "Glow", "OVERLAY", 2, "ADD", VIOLET)
	CuratorOctoFull.SetSize(r.shardGlow, 130, 130)
	r.chains = Tex(r, "ChainCross", "OVERLAY", 2)
	r.chains:SetVertexColor(0.62, 0.66, 0.6)
	r.flash = Tex(r, "Glow", "OVERLAY", -2, "ADD")
	CuratorOctoFull.SetSize(r.flash, W * 2.3, H * 2)
	r.shock = Tex(r, "Shock", "OVERLAY", 2, "ADD")
	local f = CreateFrame("Frame", nil, r)
	CuratorOctoFull.SetSize(f, 1, 1)
	f:SetFrameLevel(r:GetFrameLevel() + 3)
	f.shade = f:CreateTexture(nil, "BACKGROUND")
	f.shade:SetTexture(MEDIA .. "Glow")
	f.shade:SetVertexColor(0, 0, 0)
	CuratorOctoFull.SetSize(f.shade, 260, 200)
	f.shade:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.num = Hud.Text(f, 56, "THICKOUTLINE")
	f.num:SetPoint("CENTER", f, "CENTER", 0, 12)
	f.word = Hud.Text(f, 20, "OUTLINE")
	f.word:SetPoint("TOP", f.num, "BOTTOM", 0, -2)
	f:Hide()
	r.slam = f
	r.sparks = ns.Particles:New(r, 70)
	r.motes = ns.Particles:New(r, 40)
	r.smoke = ns.Particles:New(r, 24, "Puff", "BLEND")
end

-- The pact of the warlock (the blessing of the priest), in the place of what there is to know of the card.
local function BuildPact(d)
	local tw = d.textW
	local rep = CreateFrame("Frame", nil, d)
	rep:SetFrameLevel(d.card:GetFrameLevel() + 16)
	CuratorOctoFull.SetSize(rep, tw, 372)
	rep.x, rep.y = d.textX, -54
	rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x, rep.y)
	rep:Hide()
	rep.title = Hud.Text(rep, 12, "")
	rep.title:SetPoint("TOPLEFT", 0, 0)
	rep.name = S.Text(rep, "GameFontHighlightLarge", "LEFT")
	rep.name:SetPoint("TOPLEFT", rep.title, "BOTTOMLEFT", 0, -7)
	rep.name:SetWidth(tw)
	rep.name:SetWordWrap(false)
	rep.cert = S.Text(rep, "GameFontDisableSmall", "LEFT")
	rep.cert:SetPoint("TOPLEFT", rep.name, "BOTTOMLEFT", 0, -6)
	rep.cert:SetWidth(tw)
	rep.cert:SetWordWrap(false)
	rep.rule = S.Divider(rep, tw, 0.9)
	rep.rule:SetPoint("TOPLEFT", 0, -66)
	rep.rows = {}
	for i, key in ipairs(SL.MARKS) do
		local row = CreateFrame("Frame", nil, rep)
		CuratorOctoFull.SetSize(row, tw, 30)
		row:SetPoint("TOPLEFT", 0, -78 - (i - 1) * 36)
		row.lit = row:CreateTexture(nil, "BACKGROUND")
		row.lit:SetAllPoints()
		CuratorOctoFull.ColorTexture(row.lit, FEL[1], FEL[2], FEL[3], 0.1)
		row.lit:SetAlpha(0)
		row.label = S.Text(row, "GameFontHighlight", "LEFT")
		row.label:SetPoint("LEFT", 8, 0)
		row.label:SetWidth(116)
		row.label:SetWordWrap(false)
		row.label:SetText(L[key])
		row.bar = Hud.XPBar(row, tw - 128 - 58, 12, FEL)
		row.bar:SetPoint("LEFT", 128, 0)
		row.num = Hud.Text(row, 20, "OUTLINE")
		row.num:SetPoint("RIGHT", row, "RIGHT", -8, 0)
		row.num:SetJustifyH("RIGHT")
		rep.rows[i] = row
	end
	rep.rule2 = S.Divider(rep, tw, 0.9)
	rep.rule2:SetPoint("TOPLEFT", 0, -78 - 4 * 36 - 2)
	local v = CreateFrame("Frame", nil, rep)
	CuratorOctoFull.SetSize(v, tw, 56)
	v:SetPoint("TOPLEFT", 0, -78 - 4 * 36 - 12)
	v.label = S.Text(v, "GameFontNormal", "LEFT")
	v.label:SetPoint("LEFT", 8, 0)
	v.label:SetWidth(116)
	v.label:SetWordWrap(false)
	v.glow = v:CreateTexture(nil, "BACKGROUND")
	v.glow:SetTexture(MEDIA .. "Glow")
	v.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(v.glow, 220, 100)
	v.num = Hud.Text(v, 42, "THICKOUTLINE")
	v.num:SetPoint("LEFT", v, "LEFT", 128, 0)
	v.glow:SetPoint("CENTER", v.num, "CENTER", 30, 0)
	v.word = Hud.Text(v, 20, "OUTLINE")
	v.word:SetPoint("LEFT", v.num, "RIGHT", 14, -2)
	rep.v = v
	rep.quote = S.Text(rep, "GameFontHighlight", "LEFT")
	rep.quote:SetPoint("TOPLEFT", v, "BOTTOMLEFT", 8, -10)
	rep.quote:SetWidth(tw - 16)
	rep.quote:SetWordWrap(true)
	rep.quote:SetTextColor(0.86, 0.92, 0.8)
	rep.stars = ns.Particles:New(rep, 24, "Twinkle")
	d.pact = rep
end

-- Over everything during a rite: a click skips it; the wheel does not bring the card closer.
local function BuildCatch(d)
	local b = CreateFrame("Button", nil, d)
	b:SetAllPoints()
	b:SetFrameLevel(d.card:GetFrameLevel() + 24)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		SU:Skip()
	end)
	b:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(b, "OnMouseWheel", function() end)
	b.hint = S.Text(b, "GameFontDisableSmall")
	b.hint:SetPoint("CENTER", d.hint, "CENTER", 0, 0)
	b.hint:SetText(L["Click to skip"])
	b:Hide()
	d.riteCatch = b
end

function SU:BuildDetail(d)
	if d.void or not d.appr then
		return
	end
	BuildBlock(d)
	BuildRite(d)
	BuildPact(d)
	BuildCatch(d)
	-- (the block steps aside with what there is to know, during an appraisal and during a rite)
	d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = d.void
	d:HookScript("OnHide", function()
		SU:End(true)
	end)
end

do
	local buildDetail = A.BuildDetail
	function A:BuildDetail(...)
		local r = buildDetail(self, unpack(arg, 1, arg.n))
		if self.detail then
			SU:BuildDetail(self.detail)
		end
		return r
	end

	local showDetail = A.ShowDetail
	function A:ShowDetail(card, ...)
		SU:End(true)
		-- (shown again: its copy kept in a case first, else its most corrupted one)
		if SU.sel and card then
			SU.sel[card.key] = nil
		end
		return showDetail(self, card, unpack(arg, 1, arg.n))
	end

	local hideDetail = A.HideDetail
	function A:HideDetail(...)
		SU:End(true)
		local d = self.detail
		if d and d.void then
			d.void.seal.armed, d.void.purify.armed = nil, nil
		end
		return hideDetail(self, unpack(arg, 1, arg.n))
	end

	-- (the card shown big: a card sealed in its reliquary; the copy chosen on it)
	local paintDetail = XU.PaintDetail
	function XU:PaintDetail(how)
		paintDetail(self, how)
		SU:PaintCase(how)
	end

	-- (the expert's block: not for a corrupted card, the masters' block in its place)
	local paintAppraise = A.PaintAppraise
	function A:PaintAppraise()
		paintAppraise(self)
		SU:Paint()
	end
end

-- (the zoom of the card shown big: its range, where it goes; how: "show" at once, "after" easing to it, else as it is)
local function Zoom(c, range, at, how)
	local t = c.turn
	if not t then
		return
	end
	t.min, t.max = range[1], range[2]
	if how == "show" then
		t.zoom, t.zoomTo = at, at
		t.holder:SetScale(at)
	elseif how == "after" then
		t.zoomTo = at
	else
		t.zoomTo = math.max(t.min, math.min(t.max, t.zoomTo or at))
	end
end

-- (the look of the copy shown: its finish, its corruption)
local function Look(d, finish, k)
	local c = d.card
	local o = c.opts
	d.finish = finish
	if o and (o.finish ~= finish or o.corrupt ~= k or o.creep ~= nil) then
		o.finish, o.corrupt, o.creep = finish, k, nil
		c:SetFinish()
	end
end

-- The card shown big as its copy chosen: its copy sealed in its reliquary, at the zoom of a case; its copy appraised
-- in the expert's case (UI/Expertise.lua: a plain one); a corrupted copy out of any case, its corruption on it.
function SU:PaintCase(how)
	local d = A.detail
	if not (d and d.void and d.shown) or self.cer or XU.cer then
		return
	end
	local card = d.shown
	local c = d.card
	if not Corrupted(card) then
		return
	end
	local k, kept, rec = self:Chosen(card)
	if not k and kept == "seal" then
		c:SlabAlpha(1)
		c:SetSlab(SL:LabelOf(card, rec and rec.i or nil))
		Zoom(c, SLAB_ZOOMS, SLAB_ZOOM, how)
		d.liftK = 1
		XU:Seat(d, 0)
		Look(d, "corrupt", rec and ns.Collection.Gauge(rec.cor) or SL:Kept(card))
	elseif not k and kept == "case" then
		Look(d, rec and ns.Copies.Finish(rec) or (E:Record(card) or {}).f, nil)
	else
		if c.slabInfo then
			c:SetSlab(nil)
			Zoom(c, CARD_ZOOMS, 1, how)
			d.liftK = 1
			XU:Seat(d, 0)
		end
		Look(d, "corrupt", k)
	end
end

-- A copy chosen (k: a corrupted copy, its corruption; "kept": its copy kept in a case): shown big.
function SU:Choose(k)
	local d = A.detail
	local card = d and d.shown
	if not (card and k) or self.cer or XU.cer then
		return
	end
	self.sel = self.sel or {}
	self.sel[card.key] = k
	ns.Play(ns.SND.click)
	d.void.seal.armed, d.void.purify.armed = nil, nil
	XU:PaintDetail("after")
end

-- What the block says (another player's card, a card not corrupted: the expert's block, not this one). From the
-- top: its head (the tab of its rank, when it was sealed; not sealed: what it is), its marks and its pact (or what
-- its masters do), the copies to choose from, its buttons; what comes under it after them. (A card appraised before
-- its corrupted copies came: the expert's block stays, this one under it, without a head.)
function SU:Paint()
	local d = A.detail
	if not (d and d.void and d.appr and d.shown) then
		return
	end
	local v = d.void
	local card = d.shown
	if not Corrupted(card) then
		v:Hide()
		return
	end
	local tw = d.textW
	local list = SL:Copies(card)
	local chosen, kept, sel = self:Chosen(card)
	local x, rank = SL:Record(card, sel and sel.ws and sel.i or nil)
	if sel and not sel.ws then
		x, rank = nil, nil
	end
	-- (1.13.0: the copies chosen above, UI/Copies.lua: the chips of this block no more, nor its copy kept)
	if sel then
		list = {}
		kept = nil
	end
	local graded = kept == "case"
	CuratorOctoFull.SetShown(d.appr, graded)
	v:ClearAllPoints()
	if graded then
		v:SetPoint("TOPLEFT", d.appr, "BOTTOMLEFT", 0, -8)
	else
		v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	end
	v:Show()
	-- its head
	local y = 0
	v.line:ClearAllPoints()
	if rank then
		v.tab:SetRank(rank)
		v.line:SetPoint("LEFT", v.tab, "RIGHT", 12, 0)
		v.line:SetWidth(tw - 104)
		v.line:SetText(tonumber(x.t) and string.format(L["Sealed on %s"], date("%d/%m/%Y", x.t)) or L["Sealed"])
		v.line:SetTextColor(0.86, 0.86, 0.86)
		v.line:Show()
		y = -29
	elseif graded then
		v.tab:Hide()
		v.line:Hide()
	else
		v.tab:Hide()
		v.line:SetPoint("TOPLEFT", 0, -4)
		v.line:SetWidth(tw)
		v.line:SetText(L["Corrupted: not sealed"])
		v.line:SetTextColor(VIOLET[1] + 0.15, VIOLET[2] + 0.25, 1)
		v.line:Show()
		y = -25
	end
	-- its marks and its pact; or what its masters do
	v.marks:ClearAllPoints()
	v.marks:SetPoint("TOPLEFT", 0, y)
	if rank then
		local m = SL:Marks(card)
		local cert = E.CertText(x.c)
		local pact
		if type(x.by) == "string" and x.by ~= "" then
			pact = string.format(L["Pact No. %s: sealed by %s, at %d %%."], cert, x.by, C.Gauge(x.k))
		else
			pact = string.format(L["Pact No. %s: sealed at %d %%."], cert, C.Gauge(x.k))
		end
		v.marks:SetText(((m and SL.MarksText(m)) or "") .. "\n|cffa8b4a2" .. pact .. "|r")
		v.marks:SetTextColor(0.72, 0.9, 0.66)
	else
		local hint
		if sel then
			-- (1.13.0: the copy chosen, one corrupted copy among the others)
			if SL:AtMaster("warlock") then
				hint = L["The Master of Warlocks seals this copy: once, for good. A corrupted copy is never appraised."]
			elseif SL:AtMaster("priest") then
				hint = L["The Master of Priests purifies this copy: a plain copy again."]
			else
				hint = L["A Master of Warlocks seals this copy, once, for good; a Master of Priests purifies it."]
			end
		elseif graded then
			hint = SL:AtMaster("priest") and L["The Master of Priests purifies one of its copies: a plain copy again."]
				or L["An appraised card is never sealed: a Master of Priests purifies its corrupted copies."]
		elseif SL:AtMaster("warlock") then
			hint = L["The Master of Warlocks seals it: once, for good. A corrupted card is never appraised."]
		elseif SL:AtMaster("priest") then
			hint = L["The Master of Priests purifies one of its copies: a plain copy again."]
		else
			hint = L["A Master of Warlocks seals it, once, for good; a Master of Priests purifies a copy."]
		end
		v.marks:SetText(hint)
		v.marks:SetTextColor(0.66, 0.62, 0.74)
	end
	local last, gap = v.marks, -10
	-- the copies to choose from: its copy kept in a case first (when it has others to choose), its corrupted ones
	local any = CuratorOctoFull.Length(list) > 0
	v.copiesLabel:ClearAllPoints()
	v.copiesLabel:SetPoint("TOPLEFT", v.marks, "BOTTOMLEFT", 0, -13)
	CuratorOctoFull.SetShown(v.copiesLabel, any)
	local prev
	if any and kept then
		local b = v.kept
		if kept == "seal" then
			PaintChip(b, string.format(("%s · %d %%"), SL.Roman(rank), SL:Kept(card) or 0), chosen == nil, SL.Color(rank))
		else
			PaintChip(b, E.Label(E:Grade(card)), chosen == nil, { 0.7, 0.7, 0.74 })
		end
		b:ClearAllPoints()
		b:SetPoint("LEFT", v.copiesLabel, "RIGHT", 8, 0)
		prev = b
	else
		v.kept:Hide()
	end
	local at = self:ChosenIndex(list, chosen)
	for i, b in ipairs(v.chips) do
		local k = list[i]
		if k then
			b.k = k
			PaintChip(b, string.format(("%d %%"), k), i == at)
			b:ClearAllPoints()
			if prev then
				b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
			else
				b:SetPoint("LEFT", v.copiesLabel, "RIGHT", 8, 0)
			end
			prev = b
		else
			b:Hide()
		end
	end
	if CuratorOctoFull.Length(list) > CHIPS and prev then
		v.more:SetText(string.format(("+%d"), CuratorOctoFull.Length(list) - CHIPS))
		v.more:ClearAllPoints()
		v.more:SetPoint("LEFT", prev, "RIGHT", 6, 0)
		v.more:Show()
	else
		v.more:Hide()
	end
	if any then
		last, gap = v.copiesLabel, -14
	end
	-- the seal: a card neither sealed nor appraised, with a copy to seal
	local sb = v.seal
	local canSeal = (any and not kept) or (sel ~= nil and chosen ~= nil)
	sb:ClearAllPoints()
	sb:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, gap)
	CuratorOctoFull.SetShown(sb, canSeal)
	-- (1.14.0: the rank seen with the Golden Loupe, on the button)
	local seen = canSeal and chosen and SL.Peeked and SL:Peeked(card, chosen) or nil
	if canSeal then
		local ok, why = SL:CanSeal(card, chosen)
		sb.why = why
		local price = RB.Text(SL:SealPrice(card), 13)
		local word = (sb.armed and GetTime() - sb.armed < ARM) and L["Confirm"] or L["Seal"]
		if seen then
			word = word .. " (" .. SL.Roman(seen) .. ")"
		end
		sb:SetLabel(word .. " · " .. price)
		sb:SetEnabled(ok and true or false)
	else
		sb.armed = nil
	end
	-- the purification: a corrupted copy chosen, not the one kept in a case
	local pb = v.purify
	pb:ClearAllPoints()
	if canSeal then
		pb:SetPoint("LEFT", sb, "RIGHT", 10, 0)
	else
		pb:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, gap)
	end
	CuratorOctoFull.SetShown(pb, any or (sel ~= nil and chosen ~= nil))
	if chosen then
		local ok, why = SL:CanPurify(card, chosen)
		pb.why = why
		local price = RB.Text(SL:PurifyPrice(card, chosen), 13)
		pb:SetLabel(((pb.armed and GetTime() - pb.armed < ARM) and L["Confirm"] or L["Purify"]) .. " · " .. price)
		pb:SetEnabled(ok and true or false)
	elseif any then
		pb.why = kept
		pb.armed = nil
		pb:SetLabel(L["Purify"])
		pb:SetEnabled(false)
	else
		pb.armed = nil
	end
	if any or (sel ~= nil and chosen ~= nil) then
		last = canSeal and sb or pb
	end
	local TL = ns.Talents
	local loupe = canSeal and chosen ~= nil and not seen and TL ~= nil and TL:Has("goldloupe")
	CuratorOctoFull.SetShown(v.loupe, loupe and true or false)
	if loupe then
		v.loupe:ClearAllPoints()
		v.loupe:SetPoint("TOPLEFT", sb, "BOTTOMLEFT", 0, -6)
		v.loupe:SetEnabled(TL:Ready("glance") and SL:AtMaster("warlock") and true or false)
		last = v.loupe
	end
	-- what comes under it: its album
	d.set:ClearAllPoints()
	d.set:SetPoint("TOPLEFT", last, "BOTTOMLEFT", -2, last == v.marks and -16 or -14)
end

-- (1.14.0) The Golden Loupe: the rank of the seal of the copy chosen, seen before it is paid (Glance used).
function SU:LoupeTooltip(b)
	local TL = ns.Talents
	if not TL then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(TL:Name("goldloupe"), 0.52, 0.8, 1)
	GameTooltip:AddLine(TL:Text("goldloupe", 1), 1, 1, 1, true)
	if not SL:AtMaster("warlock") then
		GameTooltip:AddLine(L["At a Master of Warlocks: talk to him, then show this card in your album."], 1, 0.45, 0.4, true)
	elseif not TL:Ready("glance") then
		GameTooltip:AddLine(string.format(L["Glance recharges: ready in %s."], ns.Duration(TL:Left("glance"))), 0.62, 0.62, 0.66, true)
	else
		GameTooltip:AddLine(L["Click: look at this copy (nothing paid)."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function SU:LoupeClick()
	local d = A.detail
	local card = d and d.shown
	if not card or self.cer or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	local k = self:Chosen(card)
	if not (k and SL:AtMaster("warlock")) then
		ns.Play(ns.SND.close)
		return
	end
	local g = SL:Peek(card, k)
	if not g then
		ns.Play(ns.SND.close)
		return
	end
	ns.Play(ns.SND.cardFlip)
	ns.Print(L["Golden Loupe: this copy would be sealed %s."], SL.Label(g))
	GameTooltip:Hide()
	self:Paint()
end

-- (the chip of the copy chosen: the first one at that corruption)
function SU:ChosenIndex(list, k)
	for i, v in ipairs(list) do
		if v == k then
			return i
		end
	end
	return 0
end

local WHY = {
	master = { seal = "At a Master of Warlocks: talk to him, then show this card in your album.",
		purify = "At a Master of Priests: talk to him, then show this card in your album." },
	done = "Sealed already: choose another of its corrupted copies.",
	graded = "In the case of an expert already: it cannot be sealed.",
	copy = "No corrupted copy of it to seal or purify.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
	seal = "The copy sealed is never purified: choose another of its corrupted copies.",
	case = "The copy appraised is a plain one: choose one of its corrupted copies.",
}

-- The chips of the copies: a corrupted copy, or the one kept in a case.
function SU:ChipTooltip(b)
	local d = A.detail
	local card = d and d.shown
	if not card then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	if b.k == "kept" then
		local _, rank = SL:Record(card)
		if rank then
			GameTooltip:AddLine(string.format(L["Sealed: %s"], SL.Label(rank)), 1, 1, 1)
			GameTooltip:AddLine(string.format(L["A corrupted copy: %d %%"], SL:Kept(card) or 0), VIOLET[1] + 0.2, VIOLET[2] + 0.3, 1)
			GameTooltip:AddLine(L["Click to show it in its reliquary."], 0.85, 0.85, 0.85, true)
		else
			GameTooltip:AddLine(string.format(L["Appraised: %s"], E.Label(E:Grade(card))), 1, 1, 1)
			GameTooltip:AddLine(L["Click to show it in its case."], 0.85, 0.85, 0.85, true)
		end
	else
		GameTooltip:AddLine(string.format(L["A corrupted copy: %d %%"], tonumber(b.k) or 0), VIOLET[1] + 0.2, VIOLET[2] + 0.3, 1)
		GameTooltip:AddLine(L["Click to choose it: the one sealed or purified."], 0.85, 0.85, 0.85, true)
	end
	GameTooltip:Show()
end

function SU:Tooltip(b)
	local d = A.detail
	local card = d and d.shown
	if not card then
		return
	end
	local k = self:Chosen(card)
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	if b.kind == "seal" then
		GameTooltip:AddLine(L["The seal of a Master of Warlocks"], FEL[1], FEL[2], FEL[3])
		GameTooltip:AddLine(L["He traces his runes, gives a soul to the seal, binds it and shuts its shadow in, a mark from I to X each: the rank of the seal, the demon it would hold, from the Imp (I) to the Dark Titan (X), a X rarely. Once, for good: the card is shut in its reliquary, its pact written, in your album and in your showcase."], 0.85, 0.85, 0.85, true)
		if k then
			GameTooltip:AddLine(string.format(L["The copy sealed: %d %%."], k), VIOLET[1] + 0.2, VIOLET[2] + 0.3, 1)
		end
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(SL:SealPrice(card), 13)), 1, 0.82, 0.25)
	else
		GameTooltip:AddLine(L["The purification of a Master of Priests"], HOLY[1], HOLY[2], HOLY[3])
		GameTooltip:AddLine(L["The Light washes the Void off the copy chosen: a plain copy again, which can then be put in a contract or appraised. The more corrupted, the dearer."], 0.85, 0.85, 0.85, true)
		if k then
			GameTooltip:AddLine(string.format(L["The copy purified: %d %%."], k), VIOLET[1] + 0.2, VIOLET[2] + 0.3, 1)
			GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(SL:PurifyPrice(card, k), 13)), 1, 0.82, 0.25)
		end
	end
	local why = b.why and WHY[b.why]
	if type(why) == "table" then
		why = why[b.kind]
	end
	if why then
		GameTooltip:AddLine(L[why], 1, 0.45, 0.4, true)
	elseif b.armed then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	GameTooltip:Show()
end

function SU:Click(b)
	local d = A.detail
	local card = d and d.shown
	if not (card and b) or self.cer or XU.cer then
		return
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local k, kept, rec = self:Chosen(card)
	local seal = b.kind == "seal"
	local ok, why
	if not k then
		-- (its copy kept in a case chosen: not that one)
		ok, why = false, seal and "done" or kept
	elseif seal then
		ok, why = SL:CanSeal(card, k)
	else
		ok, why = SL:CanPurify(card, k)
	end
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
	local res
	-- (1.13.0: the very copy chosen, UI/Copies.lua, of two at the same corruption)
	local pick = rec and rec.i or nil
	if seal then
		res = SL:Seal(card, k, pick)
	else
		res = SL:Purify(card, k, pick)
	end
	self.busy = nil
	if not res then
		ns.Play(ns.SND.close)
		self:Paint()
		return
	end
	GameTooltip:Hide()
	if seal then
		-- (then shown in its reliquary; 1.13.0: the copy sealed chosen, UI/Copies.lua)
		self.sel = self.sel or {}
		self.sel[card.key] = "kept"
		if ns.CopiesUI and res.id then
			ns.CopiesUI.sel[card.key] = res.id
		end
		self:BeginSeal(res)
	else
		if ns.CopiesUI and res.id then
			ns.CopiesUI.sel[card.key] = res.id
		end
		self:BeginPurify(res)
	end
end

-------------------------------------------------------------------------------
-- The rites on the screen
-------------------------------------------------------------------------------
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
	return (d.atX or d.seatX) - w / 2, d.atY or d.seatY
end

-- A text written letter by letter.
function SU:Type(fs, text, dur, delay)
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

-- The room darkens, what there is to know of the card steps aside, the pact takes its place (title, colour of its
-- bars and of its words).
local function Open(self, d, res, title, cert, color)
	self:End(true)
	ns.CancelOwner(FADE)
	local c = d.card
	local cer = { res = res, card = res.card, rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), halo = d.halo:GetAlpha() }
	self.cer = cer
	A.appraising = true
	cer.hold = { yaw = 0, pitch = 0 }
	if c.turn then
		c.turn.hold = cer.hold
		c.turn.zoomTo = 1
	end
	d.liftK = 1
	d.riteCatch:Show()
	d.rite:Show()
	local rep = d.pact
	rep.title:SetText(E.Upper(title))
	rep.title:SetTextColor(color[1], color[2], color[3])
	rep.name:SetText(C:Name(res.card))
	rep.cert:SetText(cert or "")
	rep:SetAlpha(0)
	rep:Show()
	ns.Tween(0.45, function(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM + (DIM_SCENE - DIM) * e)
		d.spot:SetAlpha(SPOT + (SPOT_SCENE - SPOT) * e)
		d.rays:SetAlpha(cer.rays * (1 - 0.8 * e))
		d.rays2:SetAlpha(cer.rays2 * (1 - 0.8 * e))
		for _, p in ipairs(d.infoParts) do
			p:SetAlpha(1 - e)
		end
		rep:SetAlpha(e)
		rep:ClearAllPoints()
		rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x + 28 * (1 - e), rep.y)
	end, nil, Ease.outQuad, CER)
	return cer
end

-- The seal begins (Seal.lua SL:Seal done: res): the circle of fel behind the card, the pact beside it; then the
-- four rites, the ranks rolling, the verdict, the reliquary.
function SU:BeginSeal(res)
	local d = A.detail
	if not (d and d.rite and d:IsShown() and d.shown == res.card) then
		ns.Print(L["%s sealed: %s."], C:Name(res.card), SL.Label(res.grade))
		return
	end
	local cer = Open(self, d, res, L["The pact of the seal"], string.format(L["Pact No. %s"], E.CertText(res.cert)) .. (res.by and ("  ·  " .. string.format(L["Master: %s"], res.by)) or ""), FEL)
	cer.kind = "seal"
	local rep = d.pact
	for _, row in ipairs(rep.rows) do
		row:Show()
		row.bar:SetProgress(0)
		row.bar.bar:SetStatusBarColor(FEL[1], FEL[2], FEL[3])
		row.num:SetText("")
		row.num:SetTextColor(1, 1, 1)
		row.label:SetTextColor(0.55, 0.6, 0.55)
		row.lit:SetAlpha(0)
	end
	rep.rule:Show()
	rep.rule2:Show()
	local v = rep.v
	v:ClearAllPoints()
	v:SetPoint("TOPLEFT", 0, -78 - 4 * 36 - 12)
	v.label:SetText(L["Rank"])
	v.label:SetAlpha(0.35)
	v.num:SetText("")
	v.word:SetText("")
	v.glow:Hide()
	rep.quote:SetText("")
	ns.Play(ns.SND.open)
	ns.Play(ns.SND.tellDark[4])
	-- the circle of fel opens behind the card, turning
	local x, y = 0, 0
	On(d, d.riteCircle, x, y)
	On(d, d.riteGlow, x, y)
	d.riteCircle:SetVertexColor(FEL[1], FEL[2], FEL[3])
	d.riteGlow:SetVertexColor(FEL[1], FEL[2], FEL[3])
	d.riteCircle:Show()
	d.riteGlow:Show()
	ns.Tween(0.7, function(e)
		local s = 220 + 300 * e
		CuratorOctoFull.SetSize(d.riteCircle, s, s)
		d.riteCircle:SetAlpha(0.75 * e)
		CuratorOctoFull.SetSize(d.riteGlow, s * 1.4, s * 1.4)
		d.riteGlow:SetAlpha(0.32 * e)
	end, nil, Ease.outBack, CER)
	cer.spin = ns.Tween(60, function(_, raw)
		CuratorOctoFull.SetRotation(d.riteCircle, -raw * 60 * 0.35)
	end, nil, Ease.linear, CER)
	local t = INTRO
	for i = 1, 4 do
		local i = i; ns.Delay(t, function()
			SU:Rite(i)
		end, CER)
		t = t + RITE + GAP
	end
	ns.Delay(t, function()
		SU:Roll()
	end, CER)
	t = t + ROLL
	ns.Delay(t, function()
		SU:Slam()
	end, CER)
	t = t + HOLD + (res.grade >= SL.MAX and 0.8 or 0)
	ns.Delay(t, function()
		SU:Close()
	end, CER)
	t = t + CLOSE
	ns.Delay(t, function()
		SU:End()
	end, CER)
end

-- One of the four rites: its row lit, what the warlock does on the card, its bar filling and its mark counted.
function SU:Rite(i)
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local rep = d.pact
	local row = rep.rows[i]
	local mark = (cer.res.marks and cer.res.marks[i]) or cer.res.grade
	local r = d.rite
	local c = d.card
	local W, H = c.W, c.H
	local x, y = CardAt(d)
	row.label:SetTextColor(1, 1, 1)
	ns.Tween(0.2, function(e)
		row.lit:SetAlpha(e)
	end, nil, Ease.outQuad, CER)
	if i == 1 then
		-- the runes: traced around the card, a light running round them
		ns.Play(ns.SND.ignite)
		On(d, r.runes, 0, 0)
		r.runes:Show()
		r.runner:Show()
		ns.Tween(RITE - 0.15, function(e, raw)
			r.runes:SetAlpha(0.9 * e)
			local u = raw
			local s = (CuratorOctoFull.Mod(u , 1)) * 2 * (W + H) * 1.18
			local w2, h2 = W * 1.18, H * 1.12
			local px, py
			if s < w2 then
				px, py = -w2 / 2 + s, h2 / 2
			elseif s < w2 + h2 then
				px, py = w2 / 2, h2 / 2 - (s - w2)
			elseif s < 2 * w2 + h2 then
				px, py = w2 / 2 - (s - w2 - h2), -h2 / 2
			else
				px, py = -w2 / 2, -h2 / 2 + (s - 2 * w2 - h2)
			end
			On(d, r.runner, px, py)
			r.runner:SetAlpha(math.sin(raw * math.pi))
			if math.random() < 0.35 then
				r.sparks:Burst(x + px, y + py, FEL, 1, 60, 0.5, 12)
			end
		end, function()
			r.runner:Hide()
		end, Ease.linear, CER)
	elseif i == 2 then
		-- the soul: a shard rises from under the card and is driven into it
		ns.Play(ns.SND.tellDark[5])
		r.shard:Show()
		r.shardGlow:Show()
		ns.Tween(RITE - 0.25, function(e, raw)
			local py = -H * 0.75 + H * 0.75 * e
			On(d, r.shard, 0, py)
			On(d, r.shardGlow, 0, py)
			local s = 46 * (1 + 0.6 * (1 - e))
			CuratorOctoFull.SetSize(r.shard, s, s * 1.4)
			r.shard:SetAlpha(math.min(1, raw * 4) * (1 - raw ^ 6))
			r.shardGlow:SetAlpha(0.8 * math.min(1, raw * 4) * (1 - raw ^ 6))
		end, function()
			r.shard:Hide()
			r.shardGlow:Hide()
			-- (into the card: a flash of violet)
			On(d, r.flash, 0, 0)
			r.flash:SetVertexColor(VIOLET[1], VIOLET[2], VIOLET[3])
			r.flash:Show()
			ns.Tween(0.45, function(_, raw)
				r.flash:SetAlpha(0.55 * (1 - raw))
			end, function()
				r.flash:Hide()
			end, Ease.outQuad, CER)
			r.sparks:Burst(x, y, VIOLET, 16, 160, 0.7, 16)
			ns.Play(ns.SND.tellDark[3])
		end, Ease.inQuad, CER)
	elseif i == 3 then
		-- the bindings: chains closing on the card, crossed over it
		ns.Play(ns.SND.chains)
		On(d, r.chains, 0, 0)
		r.chains:Show()
		ns.Tween(0.45, function(e, raw)
			local k = 1.6 - 0.6 * e
			CuratorOctoFull.SetSize(r.chains, W * 1.05 * k, H * 1.05 * k)
			r.chains:SetAlpha(math.min(1, raw * 3))
		end, function()
			d.shake = 7
			ns.Play(ns.SND.chainHang)
			r.sparks:Burst(x, y, { 0.75, 0.8, 0.7 }, 12, 140, 0.5, 10)
		end, Ease.inQuad, CER)
		ns.Tween(0.4, function(e)
			r.chains:SetAlpha(1 - e)
		end, function()
			r.chains:Hide()
		end, Ease.inQuad, CER, RITE - 0.3)
	else
		-- the shadow: smoke and motes of the Void drawn into the card, its corruption pulsing
		ns.Play(ns.SND.tellDark[6])
		for k = 0, 3 do
			local k = k; ns.Delay(k * 0.16, function()
				r.smoke:Gather(x, y, SHADOW, 5, 220, 0.7, 120)
				r.motes:Gather(x, y, VIOLET, 6, 200, 0.6, 14)
			end, CER)
		end
		ns.Tween(RITE - 0.2, function(_, raw)
			c.hot:SetVertexColor(VIOLET[1], VIOLET[2], VIOLET[3])
			c.hot:SetAlpha(0.35 * math.sin(raw * math.pi))
		end, function()
			c.hot:SetAlpha(0)
		end, Ease.linear, CER)
	end
	local shown = 0
	ns.Tween(RITE - 0.2, function(e)
		row.bar:SetProgress(e * mark / SL.MAX)
		local n = math.floor(e * mark + 0.5)
		if n > shown then
			shown = n
			row.num:SetText(SL.Roman(n))
			ns.Play(ns.SND.tick)
		end
	end, function()
		local col = SL.Color(mark)
		row.num:SetText(SL.Roman(mark))
		row.num:SetTextColor(0.55 + 0.45 * col[1], 0.55 + 0.45 * col[2], 0.55 + 0.45 * col[3])
		row.bar.bar:SetStatusBarColor(col[1], col[2], col[3])
		row.bar:SetProgress(mark / SL.MAX)
		row.bar:Flash(0.9)
		ns.Play(ns.SND.stamp)
		if mark >= SL.MAX then
			ns.Play(ns.SND.shiny)
			local w = rep:GetWidth()
			if not w or w < 100 then
				w = d.textW
			end
			rep.stars:Burst(w / 2 - 20, 186 - 93 - (i - 1) * 36, FEL, 7, 70, 0.7, 20)
		end
		ns.Tween(0.3, function(e)
			row.lit:SetAlpha(1 - e)
			row.label:SetTextColor(1 - 0.14 * e, 1 - 0.1 * e, 1 - 0.14 * e)
		end, nil, Ease.outQuad, CER)
	end, Ease.outCubic, CER, 0.12)
end

-- The ranks roll on the pact, slower and slower; the circle turns faster, brighter.
function SU:Roll()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local v = d.pact.v
	ns.Tween(0.2, function(e)
		v.label:SetAlpha(0.35 + 0.65 * e)
	end, nil, Ease.outQuad, CER)
	local last, n = -1, 0
	ns.Play(ns.SND.tellDark[4])
	ns.Tween(ROLL, function(_, raw)
		local step = math.floor(14 * (1 - (1 - raw) ^ 2))
		if step ~= last then
			last = step
			local x = math.random(1, SL.MAX - 1)
			if x >= n then
				x = x + 1
			end
			n = x
			v.num:SetText(SL.Roman(n))
			v.num:SetTextColor(0.62, 0.7, 0.6)
			ns.Play(ns.SND.tick)
		end
		d.riteCircle:SetAlpha(0.75 + 0.25 * raw)
		d.riteGlow:SetAlpha(0.32 + 0.3 * raw)
	end, nil, Ease.linear, CER)
end

-- The verdict: its rank comes down on the card, on the pact too, the demon it would hold; the warlock's words.
function SU:Slam()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local g = cer.res.grade
	local col = SL.Color(g)
	local r, rep = d.rite, d.pact
	cer.slammed = true
	local v = rep.v
	v.num:SetText(SL.Roman(g))
	v.num:SetTextColor(0.55 + 0.45 * col[1], 0.55 + 0.45 * col[2], 0.55 + 0.45 * col[3])
	v.word:SetText(SL.Word(g))
	v.word:SetTextColor(col[1], col[2], col[3])
	v.glow:SetVertexColor(col[1], col[2], col[3])
	v.glow:SetAlpha(0)
	v.glow:Show()
	ns.Tween(0.8, function(_, raw)
		v.glow:SetAlpha(0.9 * math.min(1, raw * 6) * (1 - raw))
	end, nil, Ease.linear, CER)
	local f = r.slam
	f.num:SetText(SL.Roman(g))
	f.num:SetTextColor(0.55 + 0.45 * col[1], 0.55 + 0.45 * col[2], 0.55 + 0.45 * col[3])
	f.word:SetText(E.Upper(SL.Word(g)))
	f.word:SetTextColor(1, 1, 1)
	f.word:SetAlpha(1)
	f.shade:SetAlpha(0.8)
	f:ClearAllPoints()
	f:SetPoint("CENTER", d.seat, "CENTER", 0, 0)
	f:SetScale(2.8)
	f:SetAlpha(0)
	f:Show()
	ns.Tween(0.2, function(e, raw)
		f:SetScale(2.8 - 1.8 * e)
		f:SetAlpha(math.min(1, raw * 2.5))
	end, function()
		f:SetScale(1)
		f:SetAlpha(1)
		SU:Blow(g)
	end, Ease.inQuad, CER)
	self:Type(rep.quote, string.format(L["“%s”"], SL.Says(g)), 1.2, 0.3)
end

-- The blow of the verdict: a flash of fel, a ring, the card shaken; a X: the circle ablaze, the ground shaking.
function SU:Blow(g)
	local d = A.detail
	local r, c = d.rite, d.card
	local col = SL.Color(g)
	local x, y = CardAt(d)
	On(d, r.flash, 0, 0)
	r.flash:SetVertexColor(col[1], col[2], col[3])
	r.flash:SetAlpha(0.8)
	r.flash:Show()
	ns.Tween(0.6, function(_, raw)
		r.flash:SetAlpha(0.8 * (1 - raw))
	end, function()
		r.flash:Hide()
	end, Ease.outQuad, CER)
	On(d, r.shock, 0, 0)
	r.shock:SetVertexColor(col[1], col[2], col[3])
	r.shock:Show()
	ns.Tween(0.55, function(e, raw)
		local s = 60 + 540 * e
		CuratorOctoFull.SetSize(r.shock, s, s)
		r.shock:SetAlpha(1 - raw)
	end, function()
		r.shock:Hide()
	end, Ease.outCubic, CER)
	d.shake = (g >= 9 or g <= 2) and 9 or 6
	if g >= SL.MAX then
		ns.Play(ns.SND.rumble)
		ns.Play(ns.SND.titanFanfare)
		r.sparks:Burst(x, y, FEL, 50, 340, 1.1, 22)
		r.motes:Burst(x, y, VIOLET, 20, 260, 1.2, 18)
		d.rays:SetVertexColor(FEL[1], FEL[2], FEL[3])
		d.rays2:SetVertexColor(VIOLET[1], VIOLET[2], VIOLET[3])
		ns.Tween(0.6, function(e)
			d.rays:SetAlpha(0.7 * e)
			d.rays2:SetAlpha(0.45 * e)
			d.riteGlow:SetAlpha(0.62 + 0.3 * e)
		end, nil, Ease.outQuad, CER)
		for k = 1, 3 do
			ns.Delay(0.3 * k, function()
				r.motes:Rise(x - 170, x + 170, y - 240, FEL, 6, 440, 2.2, 18)
			end, CER)
		end
	elseif g >= 7 then
		ns.Play(ns.SND.levelSting)
		r.sparks:Burst(x, y, col, 34, 280, 0.9, 18)
		r.motes:Burst(x, y, VIOLET, 10, 180, 1, 16)
	elseif g >= 4 then
		ns.Play(ns.SND.stamp)
		ns.Play(ns.SND.tellDark[5])
		r.sparks:Burst(x, y, col, 18, 200, 0.7, 14)
	else
		ns.Play(ns.SND.stamp)
		ns.Play(ns.SND.cardLand)
		r.smoke:Burst(x, y - 40, { 0.3, 0.26, 0.32 }, 10, 120, 1.1, 70, 0.6, 1.6)
	end
end

-- The reliquary closes on the card: the card goes down a little (the room of its pact), the reliquary comes down,
-- its rank flies onto its pact, its wax stamped.
function SU:Close()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local r = d.rite
	local info = SL:LabelOf(cer.card)
	cer.sealing = true
	d.liftK = 0
	c:SlabAlpha(0)
	c:SetSlab(info)
	local t = c.turn
	if t then
		t.min, t.max = SLAB_ZOOMS[1], SLAB_ZOOMS[2]
		t.zoomTo = SLAB_ZOOM
	end
	ns.Play(ns.SND.whoosh)
	ns.Tween(0.5, function(e)
		d.liftK = e
	end, nil, Ease.inOutQuad, CER)
	ns.Tween(0.4, function(e)
		c:SlabAlpha(e)
	end, nil, Ease.outQuad, CER, 0.18)
	local f = r.slam
	local lx, ly, size = XU:LabelSpot(c)
	local s1 = math.max(0.1, size * SLAB_ZOOM / 56)
	ns.Tween(0.42, function(e, raw)
		local z = (t and t.zoom) or SLAB_ZOOM
		local s = 1 + (s1 - 1) * e
		local nx, ny = lx * z * e, 12 + (ly * z - 12) * e
		f:SetScale(s)
		f:ClearAllPoints()
		f:SetPoint("CENTER", d.seat, "CENTER", nx / s, ny / s - 12)
		f.word:SetAlpha(1 - math.min(1, raw * 2.5))
		f.shade:SetAlpha(0.8 * (1 - math.min(1, raw * 2)))
	end, function()
		SU:Stamp(cer.res.grade)
	end, Ease.inQuad, CER, 0.22)
	-- (the circle closes behind it)
	local a0, g0 = d.riteCircle:GetAlpha(), d.riteGlow:GetAlpha()
	ns.Tween(0.9, function(e)
		d.riteCircle:SetAlpha(a0 * (1 - e))
		d.riteGlow:SetAlpha(g0 * (1 - e))
	end, nil, Ease.inQuad, CER, 0.3)
end

-- Its rank lands on its pact: the wax stamped, its sigil lit, the card turns a little in its reliquary.
function SU:Stamp(g)
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local r, c = d.rite, d.card
	local col = SL.Color(g)
	local f = r.slam
	ns.Tween(0.15, function(e)
		f:SetAlpha(1 - e)
	end, function()
		f:Hide()
	end, Ease.outQuad, CER)
	c:SlabAlpha(1)
	local z = (c.turn and c.turn.zoom) or SLAB_ZOOM
	local lx, ly = XU:LabelSpot(c)
	On(d, r.shock, lx * z, ly * z)
	r.shock:SetVertexColor(col[1], col[2], col[3])
	r.shock:Show()
	ns.Tween(0.4, function(e, raw)
		local s = 20 + 130 * e
		CuratorOctoFull.SetSize(r.shock, s, s)
		r.shock:SetAlpha(1 - raw)
	end, function()
		r.shock:Hide()
	end, Ease.outCubic, CER)
	ns.Play(ns.SND.seal)
	ns.Play(ns.SND.cardLand)
	local x, y = CardAt(d)
	r.sparks:Burst(x + lx * z, y + ly * z, col, 14, 130, 0.6, 12)
	d.shake = 4
	ns.Delay(0.25, function()
		ns.Play(ns.SND.chainHang)
		local hx, hy = XU:HoloSpot(c)
		r.motes:Burst(x + hx * z, y + hy * z, VIOLET, 8, 60, 0.6, 18)
	end, CER)
	ns.Tween(1.0, function(_, raw)
		local k = math.sin(raw * math.pi)
		cer.hold.yaw = 0.34 * k * (1 - raw * 0.3)
		cer.hold.pitch = -0.1 * k
	end, function()
		cer.hold.yaw, cer.hold.pitch = 0, 0
	end, Ease.linear, CER, 0.3)
end

-- The purification begins (Seal.lua SL:Purify done: res): the Light comes down on the card, a circle of holy runes
-- under it; the corruption washed off as its gauge counts down; the priest's blessing.
function SU:BeginPurify(res)
	local d = A.detail
	if not (d and d.rite and d:IsShown() and d.shown == res.card) then
		ns.Print(L["%s purified: a plain copy again."], C:Name(res.card))
		return
	end
	local cer = Open(self, d, res, L["Purification"], string.format(L["Corruption: %d %%"], res.corrupt), HOLY)
	cer.kind = "purify"
	local rep = d.pact
	for _, row in ipairs(rep.rows) do
		row:Hide()
	end
	rep.rule2:Hide()
	local v = rep.v
	v:ClearAllPoints()
	v:SetPoint("TOPLEFT", 0, -84)
	v.label:SetText(L["Corruption"])
	v.label:SetAlpha(1)
	v.num:SetText(string.format(("%d %%"), res.corrupt))
	v.num:SetTextColor(VIOLET[1] + 0.15, VIOLET[2] + 0.25, 1)
	v.word:SetText("")
	v.glow:Hide()
	rep.quote:SetText("")
	ns.Play(ns.SND.open)
	local _, h = ns.Play(ns.SND.charge)
	cer.lamp = h
	local c = d.card
	-- the Light from above, a circle of holy runes under the card
	On(d, d.riteBeam, 0, 120)
	CuratorOctoFull.SetSize(d.riteBeam, 220, 900)
	d.riteBeam:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
	d.riteBeam:Show()
	On(d, d.riteCircle, 0, 0)
	On(d, d.riteGlow, 0, 0)
	d.riteCircle:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
	d.riteGlow:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
	d.riteCircle:Show()
	d.riteGlow:Show()
	ns.Tween(P_LIGHT, function(e)
		d.riteBeam:SetAlpha(0.75 * e)
		local s = 200 + 320 * e
		CuratorOctoFull.SetSize(d.riteCircle, s, s)
		d.riteCircle:SetAlpha(0.6 * e)
		CuratorOctoFull.SetSize(d.riteGlow, s * 1.5, s * 1.5)
		d.riteGlow:SetAlpha(0.4 * e)
	end, nil, Ease.outQuad, CER, P_INTRO * 0.5)
	cer.spin = ns.Tween(60, function(_, raw)
		CuratorOctoFull.SetRotation(d.riteCircle, raw * 60 * 0.25)
	end, nil, Ease.linear, CER)
	-- the corruption washed off, its gauge counting down; the Light rising from the card
	local x, y = CardAt(d)
	ns.Delay(P_INTRO + P_LIGHT, function()
		local r = d.rite
		ns.Play(ns.SND.titanStrike)
		c:PurgeCorruption(res.corrupt, P_WASH, CER)
		local shown = res.corrupt
		ns.Tween(P_WASH, function(e)
			local k = math.floor(res.corrupt * (1 - e) + 0.5)
			if k ~= shown then
				shown = k
				v.num:SetText(string.format(("%d %%"), k))
			end
			c.hot:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
			c.hot:SetAlpha(0.3 * math.sin(e * math.pi))
		end, function()
			c.hot:SetAlpha(0)
		end, Ease.inOutQuad, CER)
		for k = 0, 5 do
			local k = k; ns.Delay(k * (P_WASH / 6), function()
				r.smoke:Rise(x - 110, x + 110, y - 60, SHADOW, 3, 240, 1.4, 90)
				r.motes:Rise(x - 140, x + 140, y - 190, HOLY, 5, 380, 1.6, 16)
			end, CER)
		end
	end, CER)
	-- its blessing
	ns.Delay(P_INTRO + P_LIGHT + P_WASH, function()
		local r = d.rite
		ns.Play(ns.SND.holo)
		ns.Play(ns.SND.reveal[5])
		v.num:SetText("0 %")
		v.num:SetTextColor(HOLY[1], HOLY[2], HOLY[3])
		v.word:SetText(L["Purified!"])
		v.word:SetTextColor(HOLY[1], HOLY[2], HOLY[3])
		On(d, r.flash, 0, 0)
		r.flash:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
		r.flash:Show()
		ns.Tween(0.7, function(_, raw)
			r.flash:SetAlpha(0.8 * (1 - raw))
		end, function()
			r.flash:Hide()
		end, Ease.outQuad, CER)
		On(d, r.shock, 0, 0)
		r.shock:SetVertexColor(HOLY[1], HOLY[2], HOLY[3])
		r.shock:Show()
		ns.Tween(0.6, function(e, raw)
			local s = 60 + 560 * e
			CuratorOctoFull.SetSize(r.shock, s, s)
			r.shock:SetAlpha(1 - raw)
		end, function()
			r.shock:Hide()
		end, Ease.outCubic, CER)
		r.sparks:Burst(x, y, HOLY, 30, 260, 0.9, 18)
		d.shake = 4
		-- (the card as it is now: a plain copy, or its next corrupted copy)
		SU:Refit(cer.card)
		self:Type(rep.quote, string.format(L["“%s”"], L["The Light has washed the Void away. Go in peace, and keep it from the shadows."]), 1.1, 0.2)
	end, CER)
	ns.Delay(P_INTRO + P_LIGHT + P_WASH + P_HOLD + 0.8, function()
		SU:End()
	end, CER)
end

-- The copy purified as it is now, at its blessing: a plain one (then, the rite over, the card shown as the collection
-- has it: its next corrupted copy, its copy sealed, or a plain card).
function SU:Refit(card)
	local d = A.detail
	if not (d and d.shown == card) then
		return
	end
	local c = d.card
	local opts = c.opts or { owned = true, facing = 0.4 }
	opts.finish, opts.corrupt, opts.creep = nil, nil, nil
	d.finish = nil
	c:SetCard(card, opts)
end

-- A click during it: at once to the end.
function SU:Skip()
	if not self.cer then
		return
	end
	ns.Play(ns.SND.stamp)
	self:End()
end

-- It ends: the scene put away, the card as it is now, the room as it was (quick: at once), said in the chat.
function SU:End(quick)
	local cer = self.cer
	if not cer then
		return
	end
	self.cer = nil
	A.appraising = false
	if cer.lamp and StopSound then
		pcall(StopSound, cer.lamp, 400)
	end
	ns.CancelOwner(CER)
	local d = A.detail
	local c = d.card
	local r = d.rite
	for _, t in ipairs({ r.runes, r.runner, r.shard, r.shardGlow, r.chains, r.flash, r.shock }) do
		t:Hide()
	end
	r.slam:Hide()
	r.sparks:Clear()
	r.smoke:Clear()
	if quick then
		r.motes:Clear()
	end
	d.riteCatch:Hide()
	d.shake = 0
	d.liftK = 1
	if c.turn then
		c.turn.hold = nil
	end
	c.hot:SetAlpha(0)
	if c.purgeTw then
		ns.CancelTween(c.purgeTw)
		c.purgeTw = nil
	end
	local rr = ns.RARITY[cer.card.rarity] or ns.RARITY[1]
	d.rays:SetVertexColor(rr.glow[1], rr.glow[2], rr.glow[3])
	d.rays2:SetVertexColor(1, 0.78, 0.36)
	local here = d:IsShown() and d.shown == cer.card
	if here then
		if cer.kind == "purify" then
			self:Refit(cer.card)
		end
		XU:PaintDetail("after")
		-- (what the panel says of its copies, as they are now)
		A:PaintCopies(cer.card)
	end
	local rep = d.pact
	local from = { dim = DIM_SCENE, spot = d.spot:GetAlpha(), rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), rep = rep:GetAlpha(),
		circle = d.riteCircle:GetAlpha(), glow = d.riteGlow:GetAlpha(), beam = d.riteBeam:GetAlpha() }
	local function Room(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, from.dim + (DIM - from.dim) * e)
		d.spot:SetAlpha(from.spot + (SPOT - from.spot) * e)
		d.rays:SetAlpha(from.rays + (cer.rays - from.rays) * e)
		d.rays2:SetAlpha(from.rays2 + (cer.rays2 - from.rays2) * e)
		for _, p in ipairs(d.infoParts) do
			p:SetAlpha(e)
		end
		rep:SetAlpha(from.rep * (1 - e))
		d.riteCircle:SetAlpha(from.circle * (1 - e))
		d.riteGlow:SetAlpha(from.glow * (1 - e))
		d.riteBeam:SetAlpha(from.beam * (1 - e))
	end
	local function Away()
		rep:Hide()
		r:Hide()
		d.riteCircle:Hide()
		d.riteGlow:Hide()
		d.riteBeam:Hide()
		CuratorOctoFull.SetRotation(d.riteCircle, 0)
	end
	if quick or not here then
		Room(1)
		Away()
	else
		ns.Tween(0.4, Room, Away, Ease.outQuad, FADE)
	end
	if cer.kind == "seal" then
		ns.Print(L["%s sealed: %s."], C:Name(cer.card), SL.Label(cer.res.grade))
	else
		ns.Print(L["%s purified: a plain copy again."], C:Name(cer.card))
	end
end

-------------------------------------------------------------------------------
-- The masters: their lines in their window of dialogue
-------------------------------------------------------------------------------
-- The album on the corrupted cards: of the album of an event that has some (Hallow's End's first), mine.
function SU:OpenCorrupted()
	local target
	for _, s in ipairs(ns.Series or {}) do
		if s.event then
			for _, card in ipairs(s.list) do
				local e = C:Entry(card)
				if e and (tonumber(e.c) or 0) > 0 then
					target = s
					break
				end
			end
			target = target or ((ns.Hallow and ns.Hallow:Series() == s) and s) or target
		end
		if target and target.event then
			break
		end
	end
	if not target then
		return false
	end
	A:Open("mine", target)
	if A.CanFilter and A:CanFilter() then
		A.finish = "corrupt"
		A.page = 1
		A:Refresh()
	end
	return true
end

local function MasterLines(role)
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return {}
	end
	local seal = role == "warlock"
	return { {
		text = seal and L["Seal a corrupted card"] or L["Purify a corrupted card"],
		icon = seal and SIGIL_ICON or HOLY_ICON,
		click = function()
			local any = SU:OpenCorrupted()
			if seal then
				ns.Gossip:Say(any and L["Show me what the Void has touched. I will bind it in a seal nothing escapes."]
					or L["You carry no card touched by the Void. Come back when you do."])
			else
				ns.Gossip:Say(any and L["The Void has stained your cards. The Light can wash them clean, for a humble offering."]
					or L["None of your cards bears the stain of the Void. The Light be with you."])
			end
		end,
	} }
end

ns.Gossip:Provide("warlock", function()
	return MasterLines("warlock")
end)
ns.Gossip:Provide("priest", function()
	return MasterLines("priest")
end)

-- (a master talked to, or left: the buttons of the card shown say it)
ns.On("MASTER_CHANGED", function()
	if A.detail and A.detail:IsShown() then
		SU:Paint()
	end
end)

-- My showcase: a card sealed on its stand in its reliquary (one appraised, in its case: UI/Expertise.lua).
do
	local paintOverview = A.PaintOverview
	function A:PaintOverview(data, ...)
		local r = paintOverview(self, data, unpack(arg, 1, arg.n))
		local page = self.frame and self.frame.prof
		local st = page and page.stage
		if st and st.cards and data and data.mine then
			local showcase = data.showcase or {}
			for i, c in ipairs(st.cards) do
				local v = showcase[i]
				if v and v.card and not E:Grade(v.card) and SL:Rank(v.card) then
					XU:Stand(st, c, SL:LabelOf(v.card))
				end
			end
		end
		return r
	end
end
