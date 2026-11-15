local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local E = ns.Expertise
local RB = ns.Rubies

-------------------------------------------------------------------------------
-- (1.11.0) The expertise of the cards on the screen (Expertise.lua). A card appraised is sealed in its case
-- (UI/Card.lua: the slab), its label printed: shown big in the album it is shown in its case, in the
-- showcase of a profile too (another player's: their grades come with it); on the pages of the album it
-- wears the tab of its grade. At a banker, the card shown big gets the button to have it appraised, once:
-- the room darkens, the expert looks at it (its centering, its corners, its edges, its surface: a mark
-- each, counted on his report), gives his verdict (its grade comes down on the card), and the case comes
-- down on it, its grade printed on its label. A click skips it. A small window of Curator beside the
-- banker's leads to the album.
-------------------------------------------------------------------------------
local XU = {}
ns.ExpertiseUI = XU

local GOLD = S.GOLD
local ARM = 3                     -- (seconds) a click arms the button, a second click within confirms
local SLAB_ZOOM = 0.8             -- a card in its case, shown big: smaller, its case fits
local SLAB_ZOOMS = { 0.66, 1.02 } -- how far and how close then
local CARD_ZOOMS = { 0.85, 1.25 } -- (a card without a case: as the album attaches it)
XU.SLAB_ZOOM, XU.SLAB_ZOOMS, XU.CARD_ZOOMS = SLAB_ZOOM, SLAB_ZOOMS, CARD_ZOOMS -- (UI/Seal.lua: its reliquary)
local SHOW_K = 0.82              -- a card of the showcase in its case: smaller on its stand
local CYAN = { 0.55, 0.9, 1 }     -- the light of the expert's lamp
local INK = { 0.13, 0.09, 0.05 }  -- the ink of a label
local DIM, DIM_SCENE = 0.62, 0.86 -- how dark the room of the detail is, and during an appraisal
local SPOT, SPOT_SCENE = 0.32, 0.62
-- the moments of an appraisal (seconds): the room darkens, the four looks, the numbers roll, the verdict
-- alone, the case
local INTRO, LOOK, GAP, ROLL, HOLD, SEAL = 0.45, 0.95, 0.1, 0.75, 0.75, 1.95
local CER = {}  -- the owner of the animations of an appraisal (all of them stopped when it ends)
-- The sound of the lamp lit (a precast of the holy light: a sound the game loops), stopped by time or when the
-- appraisal ends, whatever ends it.
local LAMP = 1.6
local function StopLamp(cer)
	local h = cer and cer.lamp
	if h then
		cer.lamp = nil
		if StopSound then
			pcall(StopSound, h, 400)
		end
	end
end
local FADE = {} -- the owner of the room coming back after it

-- The narrow font of the printers of labels (the default font of a client in another script).
local LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }
local function LabelFont(fs, size, flags)
	if LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] then
		fs:SetFont("Fonts\\ARIALN.TTF", size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
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
	t:SetTexture(MEDIA .. file)
	if blend then
		t:SetBlendMode(blend)
	end
	if color then
		t:SetVertexColor(color[1], color[2], color[3])
	end
	t:Hide()
	return t
end

-------------------------------------------------------------------------------
-- The tab of a grade: a small label (its paper, the band of its grade, its word, its number)
-------------------------------------------------------------------------------
function XU.Tab(parent, w, h)
	local t = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(t, w, h)
	t.glow = t:CreateTexture(nil, "BACKGROUND")
	t.glow:SetTexture(MEDIA .. "Glow")
	t.glow:SetBlendMode("ADD")
	t.glow:SetPoint("TOPLEFT", -w * 0.35, h * 1.1)
	t.glow:SetPoint("BOTTOMRIGHT", w * 0.35, -h * 1.1)
	t.glow:SetAlpha(0)
	t.shade = t:CreateTexture(nil, "BACKGROUND", nil, 1)
	CuratorOctoFull.ColorTexture(t.shade, 0, 0, 0, 0.5)
	t.shade:SetPoint("TOPLEFT", 1, -2)
	t.shade:SetPoint("BOTTOMRIGHT", 2, -2)
	t.paper = t:CreateTexture(nil, "ARTWORK")
	t.paper:SetTexture(MEDIA .. "SlabLabel")
	t.paper:SetAllPoints()
	t.band = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.band:SetTexture(MEDIA .. "SlabBand")
	t.band:SetAllPoints()
	-- (the word left of the line of the label, the number right of it)
	t.word = t:CreateFontString(nil, "OVERLAY")
	t.wordSize, t.room = math.max(6, h * 0.4), w - h * 1.45
	LabelFont(t.word, t.wordSize, "")
	t.word:SetPoint("LEFT", t, "LEFT", h * 0.3, 0)
	t.word:SetPoint("RIGHT", t, "RIGHT", -h * 1.15, 0)
	t.word:SetJustifyH("CENTER")
	CuratorOctoFull.SetWordWrap(t.word, false)
	t.word:SetShadowOffset(0, 0)
	t.num = t:CreateFontString(nil, "OVERLAY")
	LabelFont(t.num, math.max(8, h * 0.7), "")
	t.num:SetPoint("CENTER", t, "RIGHT", -h * 0.62, 0)
	t.num:SetShadowOffset(0, 0)
	function t:SetGrade(g)
		if not g then
			self:Hide()
			return
		end
		local c = E.Color(g)
		self.band:SetVertexColor(c[1], c[2], c[3])
		-- (its word smaller when it is long)
		local size = self.wordSize
		LabelFont(self.word, size, "")
		self.word:SetText(E.Upper(E.Word(g)))
		-- (its whole width: GetStringWidth stops at the width of its box)
		-- (1.13.0: never smaller than the game can show it)
		local least = math.max(6, self.wordSize * 0.66)
		while size > least and ns.TextWidth(self.word) > self.room do
			size = size - 0.25
			LabelFont(self.word, size, "")
		end
		-- (1.13.0: a tab too small for its word even so, the smallest cards: its number only)
		if ns.TextWidth(self.word) > self.room then
			self.word:SetText("")
		end
		self.word:SetTextColor(INK[1], INK[2], INK[3])
		-- (1.13.0: a copy restored, its grade with its decimals, smaller to fit)
		local ns0 = math.max(8, self:GetHeight() * 0.7)
		LabelFont(self.num, ns0, "")
		self.num:SetText(E.Text(g))
		local nsz = ns0
		while nsz > ns0 * 0.6 and ns.TextWidth(self.num) > self:GetHeight() * 1.1 do
			nsz = nsz - 0.25
			LabelFont(self.num, nsz, "")
		end
		if g >= E.MAX then
			self.num:SetTextColor(0.72, 0.5, 0.06)
		else
			self.num:SetTextColor(INK[1], INK[2], INK[3])
		end
		self.glow:SetVertexColor(c[1], c[2], c[3])
		self.glow:SetAlpha(g >= E.MAX and 0.75 or 0)
		self:Show()
	end
	t:Hide()
	return t
end

-- The cards of the pages of the album: the tab of their grade over their top.
function A:PaintGrade(c, g)
	if not g then
		if c.grade then
			c.grade:Hide()
		end
		return
	end
	local t = c.grade
	if not t then
		-- (over its top edge, above the pennant of a new card)
		local w = c.W or 112
		t = XU.Tab(c, w * 0.64, w * 0.17)
		t:SetPoint("CENTER", c, "TOP", 0, 4)
		t:SetFrameLevel(c:GetFrameLevel() + 12)
		c.grade = t
	end
	t:SetGrade(g)
end

-------------------------------------------------------------------------------
-- The detail of a card: its case, what its expertise says, its button
-------------------------------------------------------------------------------
-- What the panel of the detail says of its expertise: the tab of its grade, when and its certificate, its
-- four marks; not appraised yet, the button (mine only).
local function BuildBlock(d)
	local tw = d.textW
	local ap = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(ap, tw, 44)
	ap:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	ap.tab = XU.Tab(ap, 92, 22)
	ap.tab:SetPoint("TOPLEFT", 0, 0)
	ap.line = S.Text(ap, "GameFontHighlight", "LEFT")
	CuratorOctoFull.SetWordWrap(ap.line, false)
	ap.marks = S.Text(ap, "GameFontHighlightSmall", "LEFT")
	ap.marks:SetPoint("TOPLEFT", 0, -30)
	ap.marks:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(ap.marks, true)
	local b = S.Button(ap, "", 180, 22)
	b:SetPoint("TOPRIGHT", 0, 0)
	if b.SetMotionScriptsWhileDisabled then
		b:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:AppraiseClick()
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:AppraiseTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self)
		if self.armed and GetTime() - self.armed >= ARM then
			self.armed = nil
			A:PaintAppraise()
		end
	end)
	ap.button = b
	-- (1.14.0, Glance, a talent of the Archivist: the grade it would get, seen before; nothing paid)
	local gl = S.Button(ap, L["Glance"], 96, 22)
	gl:SetPoint("RIGHT", b, "LEFT", -6, 0)
	if gl.SetMotionScriptsWhileDisabled then
		gl:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(gl, "OnClick", function()
		A:GlanceClick()
	end)
	CuratorOctoFull.SetScript(gl, "OnEnter", function(self)
		A:GlanceTooltip(self)
	end)
	CuratorOctoFull.SetScript(gl, "OnLeave", function()
		GameTooltip:Hide()
	end)
	gl:Hide()
	ap.glance = gl
	d.appr = ap
	-- (the name the other pieces know it by)
	d.appraise = b
end

-- The expert's tools on the card, his verdict over it (over the card and its case).
local function BuildLab(d)
	local c = d.card
	local W, H = c.W, c.H
	local lab = CreateFrame("Frame", nil, d)
	lab:SetAllPoints()
	lab:SetFrameLevel(c:GetFrameLevel() + 16)
	lab:Hide()
	d.lab = lab
	-- the centering: two lines up and down, two across, closing on the borders; a cross in its middle
	lab.cal = {}
	for i = 1, 4 do
		local up = i <= 2
		local t = Tex(lab, up and "Beam" or "Flare", "OVERLAY", 1, "ADD", CYAN)
		if up then
			CuratorOctoFull.SetSize(t, 26, H + 36)
		else
			CuratorOctoFull.SetSize(t, W + 48, 24)
		end
		lab.cal[i] = t
	end
	lab.cross = Tex(lab, "Ring", "OVERLAY", 0, "ADD", CYAN)
	lab.hairX = Tex(lab, "Flare", "OVERLAY", 0, "ADD", CYAN)
	CuratorOctoFull.SetSize(lab.hairX, W * 0.86, 12)
	lab.hairY = Tex(lab, "Beam", "OVERLAY", 0, "ADD", CYAN)
	CuratorOctoFull.SetSize(lab.hairY, 12, H * 0.86)
	lab.tagX = Hud.Text(lab, 13, "OUTLINE")
	lab.tagX:SetTextColor(CYAN[1], CYAN[2], CYAN[3])
	lab.tagY = Hud.Text(lab, 13, "OUTLINE")
	lab.tagY:SetTextColor(CYAN[1], CYAN[2], CYAN[3])
	-- the corners: a ring closing on each, a star
	lab.rings, lab.stars = {}, {}
	for i = 1, 4 do
		lab.rings[i] = Tex(lab, "Shock", "OVERLAY", 2, "ADD", CYAN)
		lab.stars[i] = Tex(lab, "Twinkle", "OVERLAY", 3, "ADD")
	end
	-- the edges: a light running round them, its trail; the edges it passed lit
	lab.edges = {}
	for i = 1, 4 do
		local across = CuratorOctoFull.Mod(i , 2) == 1
		local t = Tex(lab, across and "Flare" or "Beam", "OVERLAY", 1, "ADD", CYAN)
		if across then
			CuratorOctoFull.SetSize(t, W + 34, 18)
		else
			CuratorOctoFull.SetSize(t, 18, H + 34)
		end
		lab.edges[i] = t
	end
	lab.runner = Tex(lab, "Glow", "OVERLAY", 4, "ADD", { 0.86, 0.97, 1 })
	CuratorOctoFull.SetSize(lab.runner, 46, 46)
	lab.trail = {}
	for i = 1, 8 do
		local t = Tex(lab, "Spark", "OVERLAY", 3, "ADD", CYAN)
		local s = 26 - i * 2
		CuratorOctoFull.SetSize(t, s, s)
		lab.trail[i] = t
	end
	-- the surface: the beam of the lamp from top to bottom, the loupe over it
	lab.scan = Tex(lab, "ScanLine", "OVERLAY", 2, "ADD", CYAN)
	CuratorOctoFull.SetSize(lab.scan, W + 44, 54)
	lab.lens = Tex(lab, "Glow", "OVERLAY", 5, "ADD", { 0.86, 0.95, 1 })
	CuratorOctoFull.SetSize(lab.lens, 118, 118)
	lab.loupe = Tex(lab, "Loupe", "OVERLAY", 6)
	CuratorOctoFull.SetSize(lab.loupe, 132, 132)
	-- the verdict: a flash, the ring of the blow, the grade over the card (then flying onto its label)
	lab.flash = Tex(lab, "Glow", "OVERLAY", -2, "ADD")
	CuratorOctoFull.SetSize(lab.flash, W * 2.3, H * 2)
	lab.shock = Tex(lab, "Shock", "OVERLAY", 2, "ADD")
	local f = CreateFrame("Frame", nil, lab)
	CuratorOctoFull.SetSize(f, 1, 1)
	f:SetFrameLevel(lab:GetFrameLevel() + 3)
	-- (a shade behind it: read over any card)
	f.shade = f:CreateTexture(nil, "BACKGROUND")
	f.shade:SetTexture(MEDIA .. "Glow")
	f.shade:SetVertexColor(0, 0, 0)
	CuratorOctoFull.SetSize(f.shade, 230, 200)
	f.shade:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.num = Hud.Text(f, 60, "THICKOUTLINE")
	f.num:SetPoint("CENTER", f, "CENTER", 0, 12)
	f.word = Hud.Text(f, 20, "OUTLINE")
	f.word:SetPoint("TOP", f.num, "BOTTOM", 0, -2)
	f:Hide()
	lab.slam = f
	lab.sparks = ns.Particles:New(lab, 70)
	lab.twinkles = ns.Particles:New(lab, 30, "Twinkle")
	lab.dust = ns.Particles:New(lab, 14, "Puff", "BLEND")
end

-- The report of the expert, in the place of what there is to know of the card (beside it).
local function BuildReport(d)
	local tw = d.textW
	local rep = CreateFrame("Frame", nil, d)
	rep:SetFrameLevel(d.card:GetFrameLevel() + 16)
	CuratorOctoFull.SetSize(rep, tw, 372)
	rep.x, rep.y = d.textX, -54
	rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x, rep.y)
	rep:Hide()
	rep.title = Hud.Text(rep, 12, "")
	rep.title:SetPoint("TOPLEFT", 0, 0)
	rep.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	rep.name = S.Text(rep, "GameFontHighlightLarge", "LEFT")
	rep.name:SetPoint("TOPLEFT", rep.title, "BOTTOMLEFT", 0, -7)
	rep.name:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(rep.name, false)
	rep.cert = S.Text(rep, "GameFontDisableSmall", "LEFT")
	rep.cert:SetPoint("TOPLEFT", rep.name, "BOTTOMLEFT", 0, -6)
	rep.rule = S.Divider(rep, tw, 0.9)
	rep.rule:SetPoint("TOPLEFT", 0, -66)
	rep.rows = {}
	for i, key in ipairs(E.MARKS) do
		local r = CreateFrame("Frame", nil, rep)
		CuratorOctoFull.SetSize(r, tw, 30)
		r:SetPoint("TOPLEFT", 0, -78 - (i - 1) * 36)
		r.lit = r:CreateTexture(nil, "BACKGROUND")
		r.lit:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.lit, CYAN[1], CYAN[2], CYAN[3], 0.12)
		r.lit:SetAlpha(0)
		r.label = S.Text(r, "GameFontHighlight", "LEFT")
		r.label:SetPoint("LEFT", 8, 0)
		r.label:SetWidth(116)
		CuratorOctoFull.SetWordWrap(r.label, false)
		r.label:SetText(L[key])
		r.bar = Hud.XPBar(r, tw - 128 - 54, 12, CYAN)
		r.bar:SetPoint("LEFT", 128, 0)
		r.num = Hud.Text(r, 20, "OUTLINE")
		r.num:SetPoint("RIGHT", r, "RIGHT", -8, 0)
		r.num:SetJustifyH("RIGHT")
		rep.rows[i] = r
	end
	rep.rule2 = S.Divider(rep, tw, 0.9)
	rep.rule2:SetPoint("TOPLEFT", 0, -78 - 4 * 36 - 2)
	local v = CreateFrame("Frame", nil, rep)
	CuratorOctoFull.SetSize(v, tw, 56)
	v:SetPoint("TOPLEFT", 0, -78 - 4 * 36 - 12)
	v.label = S.Text(v, "GameFontNormal", "LEFT")
	v.label:SetPoint("LEFT", 8, 0)
	v.label:SetWidth(116)
	CuratorOctoFull.SetWordWrap(v.label, false)
	v.glow = Tex(v, "Glow", "BACKGROUND", 0, "ADD")
	CuratorOctoFull.SetSize(v.glow, 220, 100)
	v.num = Hud.Text(v, 46, "THICKOUTLINE")
	v.num:SetPoint("LEFT", v, "LEFT", 128, 0)
	v.glow:SetPoint("CENTER", v.num, "CENTER", 30, 0)
	v.word = Hud.Text(v, 22, "OUTLINE")
	v.word:SetPoint("LEFT", v.num, "RIGHT", 14, -2)
	rep.v = v
	rep.quote = S.Text(rep, "GameFontHighlight", "LEFT")
	rep.quote:SetPoint("TOPLEFT", v, "BOTTOMLEFT", 8, -10)
	rep.quote:SetWidth(tw - 16)
	CuratorOctoFull.SetWordWrap(rep.quote, true)
	rep.quote:SetTextColor(0.92, 0.87, 0.74)
	rep.stars = ns.Particles:New(rep, 24, "Twinkle")
	d.report = rep
end

-- Over everything during an appraisal: a click skips it; the wheel does not bring the card closer.
local function BuildCatch(d)
	local b = CreateFrame("Button", nil, d)
	b:SetAllPoints()
	b:SetFrameLevel(d.card:GetFrameLevel() + 24)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		XU:Skip()
	end)
	b:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(b, "OnMouseWheel", function() end)
	b.hint = S.Text(b, "GameFontDisableSmall")
	b.hint:SetPoint("CENTER", d.hint, "CENTER", 0, 0)
	b.hint:SetText(L["Click to skip"])
	b:Hide()
	d.catch = b
end

function XU:BuildDetail(d)
	if d.appr then
		return
	end
	-- where the card sits at rest (UI/Album.lua), how far above its middle the middle of its case is
	local _, _, _, sx, sy = d.seat:GetPoint(1)
	d.seatX, d.seatY = sx or 176, sy or 26
	local box = ns.SlabRects(d.card.W, d.card.H)
	d.slabLift = (box[2] + box[4]) / 2
	d.liftK, d.shake = 1, 0
	-- (the left of what there is to know, its width)
	local _, _, _, tx = d.name:GetPoint(1)
	d.textX = tx or 348
	d.textW = d.name:GetWidth() or 374
	if d.textW < 100 then
		d.textW = 374
	end
	BuildBlock(d)
	BuildLab(d)
	BuildReport(d)
	BuildCatch(d)
	-- what steps aside during an appraisal
	d.infoParts = { d.name, d.gem, d.rar, d.replay, d.line, d.rule, d.copies, d.shiny, d.found, d.set, d.num, d.spare, d.trade,
		d.pin, d.link, d.pinNote, d.appr, d.hint }
	local onUpdate = d:GetScript("OnUpdate")
	CuratorOctoFull.SetScript(d, "OnUpdate", function(self, elapsed)
		if onUpdate then
			onUpdate(self, elapsed)
		end
		XU:Seat(self, elapsed)
	end)
	d:HookScript("OnHide", function()
		XU:EndCeremony(true)
	end)
end

-- The card in its seat: a card in its case lower (the middle of its case where the middle of the card was),
-- shaken by a blow.
function XU:Seat(d, elapsed)
	local c = d.card
	local z = (c.turn and c.turn.zoom) or 1
	local lift = c.slabInfo and (d.slabLift * z * (d.liftK or 1)) or 0
	local jx, jy = 0, 0
	local sh = d.shake or 0
	if sh > 0.05 then
		d.shake = sh * math.exp(-(elapsed or 0) * 9)
		jx, jy = (math.random() - 0.5) * 2 * sh, (math.random() - 0.5) * 2 * sh
	elseif sh ~= 0 then
		d.shake = 0
	end
	local x, y = d.seatX + jx, d.seatY - lift + jy
	if x ~= d.atX or y ~= d.atY then
		d.atX, d.atY = x, y
		d.seat:ClearAllPoints()
		d.seat:SetPoint("CENTER", d, "LEFT", x, y)
	end
end

do
	local buildDetail = A.BuildDetail
	function A:BuildDetail(...)
		local r = buildDetail(self, unpack(arg, 1, arg.n))
		if self.detail then
			XU:BuildDetail(self.detail)
		end
		return r
	end

	local showDetail = A.ShowDetail
	function A:ShowDetail(...)
		XU:EndCeremony(true)
		local r = showDetail(self, unpack(arg, 1, arg.n))
		XU:PaintDetail("show")
		return r
	end

	local hideDetail = A.HideDetail
	function A:HideDetail(...)
		XU:EndCeremony(true)
		local d = self.detail
		if d and d.appraise then
			d.appraise.armed = nil
		end
		return hideDetail(self, unpack(arg, 1, arg.n))
	end
end

-- The card shown big as it is: in its case when it was appraised (mine), at the zoom of its case (how:
-- "show" at once, "after" easing to it, else as it is); what its expertise says.
function XU:PaintDetail(how)
	local d = A.detail
	if not (d and d.appr and d.shown) then
		return
	end
	if not self.cer then
		local card = d.shown
		local c = d.card
		local mine = A.mode ~= "member" and ns.Collection:Owned(card)
		-- (1.13.0: the copy chosen, in its case when it was appraised and its case is closed: UI/Copies.lua)
		local CU = ns.CopiesUI
		local rec = mine and CU and CU:Selected(card) or nil
		local info
		if rec then
			info = (ns.Copies.Grade(rec) and rec.sl ~= false) and E:LabelOf(card, nil, nil, nil, rec.i) or nil
		else
			info = (mine and E:Grade(card)) and E:LabelOf(card) or nil
		end
		c:SlabAlpha(1)
		c:SetSlab(info)
		local t = c.turn
		if t then
			local z = info and SLAB_ZOOMS or CARD_ZOOMS
			t.min, t.max = z[1], z[2]
			local at = info and SLAB_ZOOM or 1
			if how == "show" then
				t.zoom, t.zoomTo = at, at
				t.holder:SetScale(at)
			elseif how == "after" then
				t.zoomTo = at
			else
				t.zoomTo = math.max(t.min, math.min(t.max, t.zoomTo or at))
			end
		end
		d.liftK = 1
		self:Seat(d, 0)
	end
	A:PaintAppraise()
end

-- What the panel says of its expertise, its button (another player's card: nothing of it).
function A:PaintAppraise()
	local d = self.detail
	if not (d and d.appr and d.shown) then
		return
	end
	local ap = d.appr
	local card = d.shown
	local mine = self.mode ~= "member" and ns.Collection:Owned(card)
	CuratorOctoFull.SetShown(ap, mine and true or false)
	d.set:ClearAllPoints()
	if not mine then
		d.set:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", -2, -22)
		return
	end
	d.set:SetPoint("TOPLEFT", ap, "BOTTOMLEFT", -2, -14)
	local b = ap.button
	-- (1.13.0: what the expertise says of the copy chosen, UI/Copies.lua; its button for that copy)
	local CU = ns.CopiesUI
	local rec = CU and CU:Selected(card)
	local id = rec and rec.i or nil
	local x = E:Record(card, id)
	local g = x and x.sl and E:Grade(card, id) or nil
	ap.line:ClearAllPoints()
	if g then
		ap.tab:SetGrade(g)
		ap.line:SetPoint("LEFT", ap.tab, "RIGHT", 12, 0)
		ap.line:SetWidth(d.textW - 104)
		local parts = {}
		if tonumber(x.t) then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Appraised on %s"], date("%d/%m/%Y", x.t))
		end
		local cert = tonumber(x.c)
		if cert then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["No. %s"], E.CertText(cert))
		end
		ap.line:SetText(table.concat(parts, "  ·  "))
		ap.line:SetTextColor(0.86, 0.86, 0.86)
		local m = E:Marks(card, id)
		local text = m and E.MarksText(m) or ""
		local rs = rec and type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) or 0
		if rs > 0 then
			text = text .. "\n|cffa8d8ff" .. (rs == 1 and L["Restored once"] or string.format(L["Restored %d times"], rs)) .. "|r"
		end
		ap.marks:SetText(text)
		ap.marks:SetTextColor(0.78, 0.8, 0.86)
		b.armed = nil
		b:Hide()
		return
	end
	ap.tab:Hide()
	ap.line:SetPoint("TOPLEFT", 0, -4)
	ap.line:SetWidth(d.textW - 190)
	-- (1.13.0: its case opened at an enchanter, Restore.lua: appraised again, its new grade known then)
	local opened = x ~= nil and not x.sl
	ap.line:SetText(opened and L["Its case opened"] or L["Not appraised"])
	ap.line:SetTextColor(opened and 0.72 or 0.7, opened and 0.86 or 0.7, opened and 1 or 0.74)
	if opened then
		ap.marks:SetText(L["Restored: appraised again at a banker, its new grade is known then."])
	else
		ap.marks:SetText(E:AtBank() and L["The expert of the bank appraises this copy: once, for good."] or L["At a banker, an expert appraises this copy: once, for good."])
	end
	ap.marks:SetTextColor(0.62, 0.64, 0.7)
	-- (1.14.0, Glance: the grade seen, what its appraisal will give; the button to look, while it is not seen)
	local TL = ns.Talents
	local seen = x == nil and rec and tonumber(rec.pk) or nil
	if seen then
		ap.line:SetText(string.format(L["Glance: it would get %s"], E.Label(seen / 100)))
		ap.line:SetTextColor(0.86, 0.86, 0.86)
		local m = E.DecodeMarks(rec.pm)
		local text = (m and TL and TL:Rank("glance3") >= 1) and (E.MarksText(m) .. "\n") or ""
		ap.marks:SetText(text .. L["Appraised, it gets exactly that. Or keep it as it is: you pay nothing."])
	end
	local gl = ap.glance
	local can = TL ~= nil and TL:Has("glance") and not seen and not opened
	-- (a copy restored, with Certified Expert at its second rank: its true grade told, its case closed again)
	if TL and TL:Has("glance") and opened and TL:Rank("glance3") >= 2 then
		can = true
	end
	CuratorOctoFull.SetShown(gl, can and true or false)
	if can then
		CuratorOctoFull.SetEnabled(gl, TL:Ready("glance") and E:AtBank())
		ap.line:SetWidth(d.textW - 296)
	end
	b:Show()
	local ok, why = E:CanAppraise(card, id)
	b.why = why
	-- (1 November, his word: « Aller voir un maître des mages pour certifier votre titanforged ! »)
	if why == "cert" then
		ap.marks:SetText(L["Go see a master of the mages to certify your titanforged!"])
		ap.marks:SetTextColor(0.55, 0.85, 1)
	end
	local price = RB.Text(E:Price(card), 13)
	if b.armed and GetTime() - b.armed < ARM then
		b:SetLabel(L["Confirm"] .. " · " .. price)
	else
		b:SetLabel(L["Appraise"] .. " · " .. price)
	end
	CuratorOctoFull.SetEnabled(b, ok and true or false)
end

-- (1.14.0) Glance: what it does, why it cannot now.
function A:GlanceTooltip(b)
	local TL = ns.Talents
	if not TL then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(TL:Name("glance"), 0.52, 0.8, 1)
	GameTooltip:AddLine(TL:Text("glance", 1), 1, 1, 1, true)
	if not E:AtBank() then
		GameTooltip:AddLine(L["At a banker: open your bank, then this card in your album."], 1, 0.45, 0.4, true)
	elseif not TL:Ready("glance") then
		GameTooltip:AddLine(string.format(L["Ready in %s"], ns.Duration(TL:Left("glance"))), 0.62, 0.62, 0.66)
	else
		GameTooltip:AddLine(L["Click: look at this copy (nothing paid)."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function A:GlanceClick()
	local d = self.detail
	local card = d and d.shown
	if not card or XU.cer or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	if not E:AtBank() then
		ns.Play(ns.SND.close)
		return
	end
	local rec = ns.CopiesUI and ns.CopiesUI:Selected(card)
	local seen, why = E:Glance(card, rec and rec.i or nil)
	if not seen then
		ns.Play(ns.SND.close)
		if why == "ready" then
			ns.Print(L["%s recharges: ready in %s."], ns.Talents:Name("glance"), ns.Duration(ns.Talents:Left("glance")))
		end
		return
	end
	ns.Play(ns.SND.cardFlip)
	ns.Play(ns.SND.hover[math.max(2, math.min(6, math.floor((seen.grade or 1) / 2)))] or ns.SND.click)
	if seen.resealed then
		ns.Print(L["Glance: its case closed again, its grade printed: %s."], E.Label(seen.grade))
	else
		ns.Print(L["Glance: this copy would get %s."], E.Label(seen.grade))
	end
	GameTooltip:Hide()
	self:PaintAppraise()
end

local WHY = {
	bank = "At a banker: open your bank, then this card in your album.",
	done = "Appraised already: a copy is appraised once.",
	corrupt = "A corrupted card is never appraised: a Master of Warlocks can seal it.",
	away = "At an enchanter: appraised once it is back.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
	-- (1 November, his word: a titanforged copy, its certificate of a master of the mages first, Mages.lua)
	cert = "Go see a master of the mages to certify your titanforged!",
}

function A:AppraiseTooltip(b)
	local d = self.detail
	local card = d and d.shown
	if not card then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L["The expertise of a card"], 1, 1, 1)
	GameTooltip:AddLine(L["An expert looks at its centering, its corners, its edges and its surface, a mark from 1 to 10 each, and gives it its grade, a 10 rarely. Once, for good: the card is sealed in its case, its label printed, in your album and in your showcase."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(E:Price(card), 13)), 1, 0.82, 0.25)
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

function A:AppraiseClick()
	local d = self.detail
	local card = d and d.shown
	local b = d and d.appraise
	if not (card and b) or XU.cer then
		return
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	-- (1.13.0: the copy chosen, UI/Copies.lua)
	local rec = ns.CopiesUI and ns.CopiesUI:Selected(card)
	local id = rec and rec.i or nil
	local ok, why = E:CanAppraise(card, id)
	if not ok then
		ns.Play(ns.SND.close)
		b.why = why
		self:AppraiseTooltip(b)
		return
	end
	if not (b.armed and GetTime() - b.armed < ARM) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintAppraise()
		self:AppraiseTooltip(b)
		return
	end
	b.armed = nil
	-- (its grade saved before the scene: nothing tells it meanwhile, the achievements wait for its end)
	XU.busy = true
	local res = E:Appraise(card, id)
	if not res then
		XU.busy = nil
		ns.Play(ns.SND.close)
		self:PaintAppraise()
		return
	end
	GameTooltip:Hide()
	XU:Begin(res)
	XU.busy = nil
end

-------------------------------------------------------------------------------
-- The appraisal on the screen
-------------------------------------------------------------------------------
-- (a piece of the scene on the card: from the middle of the card, in its points at its size)
local function On(d, t, x, y)
	t:ClearAllPoints()
	t:SetPoint("CENTER", d.seat, "CENTER", x, y)
end

-- The middle of the card from the middle of the detail (where the particles of the scene start from).
local function CardAt(d)
	local w = d:GetWidth()
	if not w or w < 100 then
		w = 762
	end
	return (d.atX or d.seatX) - w / 2, d.atY or d.seatY
end

-- Pieces of the scene faded out, then put away.
local function FadeOut(list, dur)
	local from = {}
	for i, t in ipairs(list) do
		from[i] = t:GetAlpha()
	end
	ns.Tween(dur or 0.2, function(e)
		for i, t in ipairs(list) do
			t:SetAlpha(from[i] * (1 - e))
		end
	end, function()
		for _, t in ipairs(list) do
			t:Hide()
		end
	end, Ease.outQuad, CER)
end

-- A number drawn from the certificate (the same card shows the same measures).
local function Seed(res)
	local s = math.floor(tonumber(res.cert) or 0)
	if s == 0 then
		local key = res.card and res.card.key or ""
		for i = 1, CuratorOctoFull.Length(key) do
			s = CuratorOctoFull.Mod((s * 31 + CuratorOctoFull.Byte(key, i)) , 1000003)
		end
	end
	return s
end

-- The centering a mark shows: how far from 50 / 50 the worse of its two sides is, the other no worse.
local OFF = { [10] = { 0, 2 }, [9] = { 3, 5 }, [8] = { 6, 9 }, [7] = { 10, 13 }, [6] = { 14, 18 }, [5] = { 19, 23 },
	[4] = { 24, 28 }, [3] = { 29, 33 }, [2] = { 34, 38 }, [1] = { 39, 43 } }
local function Ratios(mark, seed)
	local r = OFF[mark] or OFF[5]
	local a = r[1] + CuratorOctoFull.Mod(seed , (r[2] - r[1] + 1))
	local b = CuratorOctoFull.Mod(math.floor(seed / 7) , (a + 1))
	if CuratorOctoFull.Mod(math.floor(seed / 3) , 2) == 0 then
		a, b = b, a
	end
	return 50 + a, 50 - a, 50 + b, 50 - b
end

-- A point of the edges of a card (w x h, from its middle): u from 0 to 1, from its top left, clockwise.
local function Perimeter(u, w, h)
	local s = (CuratorOctoFull.Mod(u , 1)) * 2 * (w + h)
	if s < w then
		return -w / 2 + s, h / 2
	end
	s = s - w
	if s < h then
		return w / 2, h / 2 - s
	end
	s = s - h
	if s < w then
		return w / 2 - s, -h / 2
	end
	return -w / 2, -h / 2 + (s - w)
end

-- Where the grade and the hologram of its label are, from the middle of the card at its size.
function XU:LabelSpot(c)
	local sl = c.slab
	if sl and sl.gradeAt then
		return sl.gradeAt[1], sl.gradeAt[2], sl.gradeAt[3]
	end
	return c.W * 0.39, c.H * 0.62, 31
end

function XU:HoloSpot(c)
	local sl = c.slab
	if sl and sl.holoAt then
		return sl.holoAt[1], sl.holoAt[2]
	end
	return c.W * 0.48, c.H * 0.56
end

-- (1.14.0, after its second test) The card the detail shows: of a booster (d.shown), or of a case (d.caseShown,
-- UI/CaseDetail.lua); its name; the light of its rarity.
local function Shown(d)
	return d and (d.shown or d.caseShown)
end
XU.Shown = Shown
local function NameOf(res)
	return res.name or ns.Collection:Name(res.card)
end

-- It begins (the appraisal done: res, Expertise.lua E:Appraise; a card of a case: UI/CaseDetail.lua, its name, the
-- label of its case and the light of its rank with it): the room darkens, what there is to know of the card steps aside,
-- the report of the expert takes its place.
function XU:Begin(res)
	local d = A.detail
	if not (d and d.lab and d:IsShown() and Shown(d) == res.card) then
		ns.Print(L["%s appraised: %s."], NameOf(res), E.Label(res.grade))
		return
	end
	self:EndCeremony(true)
	ns.CancelOwner(FADE)
	local c = d.card
	local cer = { res = res, card = res.card, seed = Seed(res), rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), halo = d.halo:GetAlpha() }
	self.cer = cer
	A.appraising = true
	-- (the card held still, facing, at its size)
	cer.hold = { yaw = 0, pitch = 0 }
	if c.turn then
		c.turn.hold = cer.hold
		c.turn.zoomTo = 1
	end
	d.liftK = 1
	GameTooltip:Hide()
	d.catch:Show()
	d.lab:Show()
	-- the report: the card, its certificate, the four looks to come
	local rep = d.report
	rep.title:SetText(E.Upper(L["Expertise"]))
	rep.name:SetText(NameOf(res))
	rep.cert:SetText(res.cert and string.format(L["Certificate No. %s"], E.CertText(res.cert)) or "")
	-- (1.13.0: a copy restored, appraised again: its grade of before)
	if res.again and res.before then
		rep.cert:SetText(rep.cert:GetText() .. "  ·  " .. string.format(L["Before: %s"], E.Text(res.before)))
	end
	for _, r in ipairs(rep.rows) do
		r.bar:SetProgress(0)
		r.bar.bar:SetStatusBarColor(CYAN[1], CYAN[2], CYAN[3])
		r.num:SetText("")
		r.num:SetTextColor(1, 1, 1)
		r.label:SetTextColor(0.55, 0.56, 0.6)
		r.lit:SetAlpha(0)
	end
	local v = rep.v
	v.label:SetText(L["Grade"])
	v.label:SetAlpha(0.35)
	v.num:SetText("")
	v.word:SetText("")
	v.glow:Hide()
	rep.quote:SetText("")
	rep:SetAlpha(0)
	rep:Show()
	ns.Play(ns.SND.open)
	local _, lamp = ns.Play(ns.SND.charge)
	cer.lamp = lamp
	ns.Delay(LAMP, function()
		StopLamp(cer)
	end)
	ns.Tween(0.4, function(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM + (DIM_SCENE - DIM) * e)
		d.spot:SetAlpha(SPOT + (SPOT_SCENE - SPOT) * e)
		d.rays:SetAlpha(cer.rays * (1 - 0.7 * e))
		d.rays2:SetAlpha(cer.rays2 * (1 - 0.7 * e))
		for _, p in ipairs(d.infoParts) do
			p:SetAlpha(1 - e)
		end
		rep:SetAlpha(e)
		rep:ClearAllPoints()
		rep:SetPoint("TOPLEFT", d, "TOPLEFT", rep.x + 28 * (1 - e), rep.y)
	end, nil, Ease.outQuad, CER)
	-- the four looks, the numbers rolling, the verdict, the case
	local t = INTRO
	for i = 1, 4 do
		local i = i; ns.Delay(t, function()
			XU:Look(i)
		end, CER)
		t = t + LOOK + GAP
	end
	ns.Delay(t, function()
		XU:Roll()
	end, CER)
	t = t + ROLL
	ns.Delay(t, function()
		XU:Slam()
	end, CER)
	t = t + HOLD + (res.grade >= E.MAX and 0.8 or 0)
	ns.Delay(t, function()
		XU:Seal()
	end, CER)
	t = t + SEAL
	ns.Delay(t, function()
		XU:EndCeremony()
	end, CER)
end

-- One of the four looks: its row of the report lit, the expert's tools on the card, its bar filling and
-- its mark counted up to what he gives.
function XU:Look(i)
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local rep = d.report
	local r = rep.rows[i]
	local mark = (cer.res.marks and cer.res.marks[i]) or cer.res.grade
	cer.look = i
	r.label:SetTextColor(1, 1, 1)
	ns.Tween(0.2, function(e)
		r.lit:SetAlpha(e)
	end, nil, Ease.outQuad, CER)
	ns.Play(ns.SND.page)
	if i == 1 then
		self:Centering(mark)
	elseif i == 2 then
		self:Corners()
	elseif i == 3 then
		self:Edges()
	else
		self:Surface()
	end
	local shown = 0
	ns.Tween(LOOK - 0.2, function(e)
		r.bar:SetProgress(e * mark / E.MAX)
		local n = math.floor(e * mark + 0.5)
		if n > shown then
			shown = n
			r.num:SetText(tostring(n))
			ns.Play(ns.SND.tick)
		end
	end, function()
		-- its mark, in its colour
		local col = E.Color(mark)
		r.num:SetText(tostring(mark))
		r.num:SetTextColor(col[1], col[2], col[3])
		r.bar.bar:SetStatusBarColor(col[1], col[2], col[3])
		r.bar:SetProgress(mark / E.MAX)
		r.bar:Flash(0.9)
		ns.Play(ns.SND.stamp)
		if mark >= E.MAX then
			ns.Play(ns.SND.shiny)
			local w = rep:GetWidth()
			if not w or w < 100 then
				w = d.textW
			end
			rep.stars:Burst(w / 2 - 20, 186 - 93 - (i - 1) * 36, { 1, 0.9, 0.55 }, 7, 70, 0.7, 20)
		end
		ns.Tween(0.3, function(e)
			r.lit:SetAlpha(1 - e)
			r.label:SetTextColor(1 - 0.14 * e, 1 - 0.14 * e, 1 - 0.12 * e)
		end, nil, Ease.outQuad, CER)
	end, Ease.outCubic, CER, 0.12)
end

-- The centering: the lines close on the borders of the frame (as far off as the card is), the cross in its
-- middle breathes, the measures show.
function XU:Centering(mark)
	local cer, d = self.cer, A.detail
	local lab, c = d.lab, d.card
	local W, H = c.W, c.H
	local lx, rx, ty, by = Ratios(mark, cer.seed)
	-- (the borders: the frame of the window of the creature, a little off as the card is)
	local bx, bt, bb = W * 24 / 366, H * 24 / 512, H * 194 / 512
	local offX, offY = (lx - 50) / 50 * bx, (ty - 50) / 50 * bt
	local from = { -W / 2, W / 2, H / 2, -H / 2 }
	local goal = { -W / 2 + bx + offX, W / 2 - bx + offX, H / 2 - bt - offY, -H / 2 + bb - offY }
	for _, t in ipairs(lab.cal) do
		t:SetAlpha(0)
		t:Show()
	end
	ns.Tween(0.55, function(e, raw)
		for k, t in ipairs(lab.cal) do
			local p = from[k] + (goal[k] - from[k]) * e
			if k <= 2 then
				On(d, t, p, 0)
			else
				On(d, t, 0, p)
			end
			t:SetAlpha(0.95 * math.min(1, raw * 4))
		end
	end, nil, Ease.inOutCubic, CER)
	for _, t in ipairs({ lab.cross, lab.hairX, lab.hairY }) do
		On(d, t, 0, 0)
		t:SetAlpha(0)
		t:Show()
	end
	ns.Tween(LOOK - 0.15, function(_, raw)
		local p = 0.5 + 0.5 * math.sin(raw * math.pi * 4)
		local a = math.min(1, raw * 5) * (1 - raw ^ 6)
		lab.cross:SetAlpha(a * (0.45 + 0.4 * p))
		local s = 50 + 12 * p
		CuratorOctoFull.SetSize(lab.cross, s, s)
		lab.hairX:SetAlpha(0.3 * a)
		lab.hairY:SetAlpha(0.3 * a)
	end, nil, Ease.linear, CER)
	-- the measures: left / right over the card, top / bottom under it
	lab.tagX:SetText(string.format(("%d : %d"), lx, rx))
	lab.tagY:SetText(string.format(("%d : %d"), ty, by))
	lab.tagX:ClearAllPoints()
	lab.tagX:SetPoint("BOTTOM", d.seat, "CENTER", 0, H / 2 + 8)
	lab.tagY:ClearAllPoints()
	lab.tagY:SetPoint("TOP", d.seat, "CENTER", 0, -H / 2 - 8)
	lab.tagX:SetAlpha(0)
	lab.tagY:SetAlpha(0)
	ns.Tween(0.25, function(e)
		lab.tagX:SetAlpha(e)
		lab.tagY:SetAlpha(e)
	end, function()
		ns.Play(ns.SND.tick)
	end, Ease.outQuad, CER, 0.5)
	ns.Delay(LOOK - 0.1, function()
		FadeOut(lab.cal, 0.2)
		FadeOut({ lab.cross, lab.hairX, lab.hairY }, 0.15)
		ns.Tween(0.2, function(e)
			lab.tagX:SetAlpha(1 - e)
			lab.tagY:SetAlpha(1 - e)
		end, nil, Ease.outQuad, CER)
	end, CER)
end

-- The corners: a ring closes on each, one after the other, a star on it.
function XU:Corners()
	local d = A.detail
	local lab, c = d.lab, d.card
	local cx, cy = c.W / 2 - 13, c.H / 2 - 13
	local at = { { -cx, cy }, { cx, cy }, { cx, -cy }, { -cx, -cy } }
	for k = 1, 4 do
		local k = k; local ring, star = lab.rings[k], lab.stars[k]
		On(d, ring, at[k][1], at[k][2])
		On(d, star, at[k][1], at[k][2])
		ring:SetAlpha(0)
		star:SetAlpha(0)
		ring:Show()
		star:Show()
		ns.Tween(0.42, function(e, raw)
			local s = 88 - 50 * e
			CuratorOctoFull.SetSize(ring, s, s)
			ring:SetAlpha(math.min(1, raw * 3))
			local tw = math.sin(raw * math.pi)
			CuratorOctoFull.SetSize(star, 12 + 32 * tw, 12 + 32 * tw)
			star:SetAlpha(tw)
			CuratorOctoFull.SetRotation(star, raw * 1.6)
		end, function()
			ns.Play(ns.SND.tick)
		end, Ease.outCubic, CER, 0.05 + (k - 1) * 0.19)
	end
	ns.Delay(LOOK - 0.1, function()
		FadeOut(lab.rings, 0.22)
		FadeOut(lab.stars, 0.15)
	end, CER)
end

-- The edges: a light runs round them, its trail behind it; each edge lights as it passes.
function XU:Edges()
	local d = A.detail
	local lab, c = d.lab, d.card
	local W, H = c.W - 4, c.H - 4
	local edges = lab.edges
	On(d, edges[1], 0, H / 2)
	On(d, edges[2], W / 2, 0)
	On(d, edges[3], 0, -H / 2)
	On(d, edges[4], -W / 2, 0)
	for _, t in ipairs(edges) do
		t:SetAlpha(0)
		t:Show()
	end
	lab.runner:SetAlpha(0)
	lab.runner:Show()
	for _, t in ipairs(lab.trail) do
		t:SetAlpha(0)
		t:Show()
	end
	ns.Play(ns.SND.whoosh)
	local P = 2 * (W + H)
	local ends = { W / P, (W + H) / P, (2 * W + H) / P, 1 }
	ns.Tween(0.85, function(u, raw)
		local x, y = Perimeter(u, W, H)
		local a = math.min(1, raw * 6, (1 - raw) * 6)
		On(d, lab.runner, x, y)
		lab.runner:SetAlpha(a)
		for k, t in ipairs(lab.trail) do
			local tx, ty = Perimeter(math.max(0, u - k * 0.012), W, H)
			On(d, t, tx, ty)
			t:SetAlpha((1 - k / 9) * a * 0.85)
		end
		local start = 0
		for k, t in ipairs(edges) do
			t:SetAlpha(0.6 * math.max(0, math.min(1, (u - start) / (ends[k] - start))))
			start = ends[k]
		end
	end, function()
		lab.runner:Hide()
		for _, t in ipairs(lab.trail) do
			t:Hide()
		end
		FadeOut(edges, 0.22)
	end, Ease.inOutQuad, CER)
end

-- The surface: the beam of the lamp passes from its top to its bottom, the loupe over it.
function XU:Surface()
	local d = A.detail
	local lab, c = d.lab, d.card
	local W, H = c.W, c.H
	for _, t in ipairs({ lab.scan, lab.loupe, lab.lens }) do
		t:SetAlpha(0)
		t:Show()
	end
	ns.Tween(LOOK - 0.1, function(_, raw)
		local a = math.min(1, raw * 5, (1 - raw) * 5)
		On(d, lab.scan, 0, H / 2 - H * raw)
		lab.scan:SetAlpha(0.9 * a)
		-- (the loupe: a figure of eight over the card)
		local ang = raw * math.pi * 2
		local x, y = W * 0.27 * math.sin(ang), H * 0.2 * math.sin(2 * ang)
		On(d, lab.lens, x, y)
		On(d, lab.loupe, x + 20, y - 20)
		lab.loupe:SetAlpha(a)
		lab.lens:SetAlpha(0.32 * a)
	end, function()
		lab.scan:Hide()
		lab.loupe:Hide()
		lab.lens:Hide()
	end, Ease.linear, CER)
end

-- What the card tells while the numbers roll, as a booster tells its finest card: its light climbs the
-- colours of the grades up to its own (the iron, the bronze of a 7, the silver of a 9, the gold of a 10).
local TELLS = { { 1, E.IRON, 2 }, { 7, E.COLORS[7], 3 }, { 9, E.COLORS[9], 5 }, { 10, E.COLORS[10], 6 } }

-- The numbers roll on the report, slower and slower; the card warms, its light climbing.
function XU:Roll()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local g = cer.res.grade
	local v = d.report.v
	local c = d.card
	ns.Tween(0.2, function(e)
		v.label:SetAlpha(0.35 + 0.65 * e)
	end, nil, Ease.outQuad, CER)
	local steps = {}
	for _, x in ipairs(TELLS) do
		if g >= x[1] then
			steps[CuratorOctoFull.Length(steps) + 1] = x
		end
	end
	local col, told = steps[1][2], 0
	local last, n = -1, 0
	ns.Tween(ROLL, function(_, raw)
		local step = math.floor(14 * (1 - (1 - raw) ^ 2))
		if step ~= last then
			last = step
			local x = math.random(1, E.MAX - 1)
			if x >= n then
				x = x + 1
			end
			n = x
			v.num:SetText(tostring(n))
			v.num:SetTextColor(0.72, 0.72, 0.76)
			ns.Play(ns.SND.tick)
		end
		-- (its light a colour higher at each step it reaches)
		local k = math.min(CuratorOctoFull.Length(steps), 1 + math.floor(raw * CuratorOctoFull.Length(steps)))
		if k > told then
			told = k
			col = steps[k][2]
			ns.Play(ns.SND.tell[steps[k][3]])
			if steps[k][1] >= E.MAX then
				ns.Play(ns.SND.rumble)
			end
		end
		c.hot:SetVertexColor(col[1], col[2], col[3])
		c.hot:SetAlpha((0.12 + 0.2 * told / CuratorOctoFull.Length(TELLS)) * raw)
	end, nil, Ease.linear, CER)
end

-- The verdict: its grade comes down on the card (a blow, by its grade), on the report too; the expert's
-- word, letter by letter.
function XU:Slam()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local g = cer.res.grade
	local col = E.Color(g)
	local lab, rep = d.lab, d.report
	cer.slammed = true
	local v = rep.v
	v.num:SetText(E.Text(g))
	v.num:SetTextColor(col[1], col[2], col[3])
	v.word:SetText(E.Word(g))
	v.word:SetTextColor(col[1], col[2], col[3])
	v.glow:SetVertexColor(col[1], col[2], col[3])
	v.glow:SetAlpha(0)
	v.glow:Show()
	ns.Tween(0.8, function(_, raw)
		v.glow:SetAlpha(0.9 * math.min(1, raw * 6) * (1 - raw))
	end, nil, Ease.linear, CER)
	local f = lab.slam
	f.num:SetText(E.Text(g))
	f.num:SetTextColor(col[1], col[2], col[3])
	f.word:SetText(E.Upper(E.Word(g)))
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
		XU:Blow(g)
	end, Ease.inQuad, CER)
	self:Type(rep.quote, string.format(L["“%s”"], E.Says(g)), 1.1, 0.3)
end

-- The blow of the verdict: a flash, a ring, the card shaken; a 10 in gold and a fanfare, a poor grade a dull
-- thud and dust.
function XU:Blow(g)
	local d = A.detail
	local lab, c = d.lab, d.card
	local col = E.Color(g)
	local x, y = CardAt(d)
	On(d, lab.flash, 0, 0)
	lab.flash:SetVertexColor(col[1], col[2], col[3])
	lab.flash:SetAlpha(0.8)
	lab.flash:Show()
	ns.Tween(0.6, function(_, raw)
		lab.flash:SetAlpha(0.8 * (1 - raw))
	end, function()
		lab.flash:Hide()
	end, Ease.outQuad, CER)
	On(d, lab.shock, 0, 0)
	lab.shock:SetVertexColor(col[1], col[2], col[3])
	lab.shock:Show()
	ns.Tween(0.55, function(e, raw)
		local s = 60 + 540 * e
		CuratorOctoFull.SetSize(lab.shock, s, s)
		lab.shock:SetAlpha(1 - raw)
	end, function()
		lab.shock:Hide()
	end, Ease.outCubic, CER)
	c.hot:SetVertexColor(col[1], col[2], col[3])
	ns.Tween(0.5, function(e)
		c.hot:SetAlpha(0.6 * (1 - e))
	end, nil, Ease.outQuad, CER)
	d.shake = (g >= 9 or g <= 2) and 9 or 6
	if g >= E.MAX then
		ns.Play(ns.SND.titanStrike)
		ns.Play(ns.SND.titanFanfare)
		lab.sparks:Burst(x, y, col, 50, 340, 1.1, 22)
		lab.twinkles:Burst(x, y, { 1, 0.95, 0.75 }, 16, 230, 1.2, 30)
		-- the gold of a 10 behind the card, a rain of gold
		d.rays:SetVertexColor(1, 0.82, 0.3)
		d.rays2:SetVertexColor(1, 0.82, 0.3)
		d.halo:SetVertexColor(1, 0.82, 0.3)
		ns.Tween(0.6, function(e)
			d.rays:SetAlpha(0.75 * e)
			d.rays2:SetAlpha(0.45 * e)
			d.halo:SetAlpha(0.3 + 0.35 * e)
		end, nil, Ease.outQuad, CER)
		for k = 1, 3 do
			local k = k; ns.Delay(0.3 * k, function()
				lab.twinkles:Rise(x - 170, x + 170, y - 240, { 1, 0.86, 0.4 }, 5, 440, 2.2, 22)
			end, CER)
		end
	elseif g >= 8 then
		ns.Play(ns.SND.levelSting)
		lab.sparks:Burst(x, y, col, 34, 280, 0.9, 18)
		lab.twinkles:Burst(x, y, col, 10, 180, 1, 24)
	elseif g >= 5 then
		ns.Play(ns.SND.stamp)
		ns.Play(ns.SND.reveal[3])
		lab.sparks:Burst(x, y, col, 18, 200, 0.7, 14)
	else
		ns.Play(ns.SND.stamp)
		ns.Play(ns.SND.cardLand)
		lab.dust:Burst(x, y - 40, { 0.52, 0.5, 0.47 }, 10, 120, 1.1, 70, 0.6, 1.6)
	end
end

-- A text written letter by letter.
function XU:Type(fs, text, dur, delay)
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

-- The case: the card goes down a little, smaller (the room of its label), the case comes down on it, its
-- grade flies onto its label.
function XU:Seal()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local lab = d.lab
	local info = cer.res.label or E:LabelOf(cer.card, nil, nil, nil, cer.res.id)
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
	local f = lab.slam
	local lx, ly, size = self:LabelSpot(c)
	local s1 = math.max(0.1, size * SLAB_ZOOM / 60)
	ns.Tween(0.42, function(e, raw)
		local z = (t and t.zoom) or SLAB_ZOOM
		local s = 1 + (s1 - 1) * e
		-- (the number, 12 points over the middle of its frame, flies to the grade of the label)
		local nx, ny = lx * z * e, 12 + (ly * z - 12) * e
		f:SetScale(s)
		f:ClearAllPoints()
		f:SetPoint("CENTER", d.seat, "CENTER", nx / s, ny / s - 12)
		f.word:SetAlpha(1 - math.min(1, raw * 2.5))
		f.shade:SetAlpha(0.8 * (1 - math.min(1, raw * 2)))
	end, function()
		XU:Stamp(cer.res.grade)
	end, Ease.inQuad, CER, 0.22)
end

-- Its grade lands on its label: a stamp, the hologram catches the light, the card turns a little in its
-- case (the light running over the acrylic).
function XU:Stamp(g)
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local lab, c = d.lab, d.card
	local col = E.Color(g)
	local f = lab.slam
	ns.Tween(0.15, function(e)
		f:SetAlpha(1 - e)
	end, function()
		f:Hide()
	end, Ease.outQuad, CER)
	c:SlabAlpha(1)
	local z = (c.turn and c.turn.zoom) or SLAB_ZOOM
	local lx, ly = self:LabelSpot(c)
	On(d, lab.shock, lx * z, ly * z)
	lab.shock:SetVertexColor(col[1], col[2], col[3])
	lab.shock:Show()
	ns.Tween(0.4, function(e, raw)
		local s = 20 + 130 * e
		CuratorOctoFull.SetSize(lab.shock, s, s)
		lab.shock:SetAlpha(1 - raw)
	end, function()
		lab.shock:Hide()
	end, Ease.outCubic, CER)
	ns.Play(ns.SND.seal)
	ns.Play(ns.SND.cardLand)
	local x, y = CardAt(d)
	lab.sparks:Burst(x + lx * z, y + ly * z, col, 14, 130, 0.6, 12)
	d.shake = 4
	ns.Delay(0.25, function()
		ns.Play(ns.SND.holo)
		local hx, hy = XU:HoloSpot(c)
		lab.twinkles:Burst(x + hx * z, y + hy * z, { 1, 1, 1 }, 5, 50, 0.6, 26)
	end, CER)
	ns.Tween(1.0, function(_, raw)
		local k = math.sin(raw * math.pi)
		cer.hold.yaw = 0.34 * k * (1 - raw * 0.3)
		cer.hold.pitch = -0.1 * k
	end, function()
		cer.hold.yaw, cer.hold.pitch = 0, 0
	end, Ease.linear, CER, 0.3)
end

-- A click during it: at once to the end (the card in its case).
function XU:Skip()
	if not self.cer then
		return
	end
	ns.Play(ns.SND.stamp)
	self:EndCeremony()
end

-- It ends: the scene put away, the card in its case, the room as it was (quick: at once, the detail closing or
-- another card shown), said in the chat.
function XU:EndCeremony(quick)
	local cer = self.cer
	if not cer then
		return
	end
	self.cer = nil
	A.appraising = false
	StopLamp(cer)
	ns.CancelOwner(CER)
	local d = A.detail
	local c = d.card
	local lab = d.lab
	for _, t in ipairs({ lab.cross, lab.hairX, lab.hairY, lab.runner, lab.scan, lab.loupe, lab.lens, lab.flash, lab.shock }) do
		t:Hide()
	end
	for _, list in ipairs({ lab.cal, lab.rings, lab.stars, lab.edges, lab.trail }) do
		for _, t in ipairs(list) do
			t:Hide()
		end
	end
	lab.tagX:SetText("")
	lab.tagY:SetText("")
	lab.slam:Hide()
	lab.sparks:Clear()
	lab.dust:Clear()
	if quick then
		lab.twinkles:Clear()
	end
	d.catch:Hide()
	d.shake = 0
	d.liftK = 1
	if c.turn then
		c.turn.hold = nil
	end
	c.hot:SetAlpha(0)
	-- the light behind the card: of its rarity again (of its rank, a card of a case)
	local r = ns.RARITY[cer.card.rarity] or ns.RARITY[1]
	local glow = cer.res.glow or r.glow
	d.rays:SetVertexColor(glow[1], glow[2], glow[3])
	d.rays2:SetVertexColor(1, 0.78, 0.36)
	d.halo:SetVertexColor(glow[1], glow[2], glow[3])
	local here = d:IsShown() and Shown(d) == cer.card
	if here then
		if d.caseShown and ns.CaseDetail then
			ns.CaseDetail:PaintCard(d, "after")
			ns.CaseDetail:PaintPanel(d)
		else
			self:PaintDetail("after")
		end
	end
	local rep = d.report
	local from = { dim = DIM_SCENE, spot = d.spot:GetAlpha(), rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), halo = d.halo:GetAlpha(), rep = rep:GetAlpha() }
	local function Room(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, from.dim + (DIM - from.dim) * e)
		d.spot:SetAlpha(from.spot + (SPOT - from.spot) * e)
		d.rays:SetAlpha(from.rays + (cer.rays - from.rays) * e)
		d.rays2:SetAlpha(from.rays2 + (cer.rays2 - from.rays2) * e)
		d.halo:SetAlpha(from.halo + (cer.halo - from.halo) * e)
		for _, p in ipairs(d.infoParts) do
			p:SetAlpha(e)
		end
		rep:SetAlpha(from.rep * (1 - e))
	end
	if quick or not here then
		Room(1)
		rep:Hide()
		lab:Hide()
	else
		ns.Tween(0.4, Room, function()
			rep:Hide()
			lab:Hide()
		end, Ease.outQuad, FADE)
	end
	ns.Print(L["%s appraised: %s."], NameOf(cer.res), E.Label(cer.res.grade))
end

-------------------------------------------------------------------------------
-- The showcase of a profile: its cards in their cases (another player's too: their grades come with it)
-------------------------------------------------------------------------------
-- A card of the stage in its case (info: E:LabelOf), smaller on its stand, or out of it.
function XU:Stand(st, c, info)
	if not c.standK then
		return
	end
	local k = c.standK * (info and SHOW_K or 1)
	local w, h = c.W * k, c.H * k
	local margin = 0
	if info then
		local box = ns.SlabRects(c.W, c.H)
		margin = (-box[2] - c.H / 2) * k
	end
	c:SetScale(k)
	c:ClearAllPoints()
	c:SetPoint("TOPLEFT", st, "TOPLEFT", (c.standX - w / 2) / k, (c.standBottom + margin + h) / k)
	c:SetSlab(info)
	if c.floor then
		CuratorOctoFull.SetSize(c.floor, w * (info and 1.4 or 1.2), 26)
	end
end

do
	local paintOverview = A.PaintOverview
	function A:PaintOverview(data, ...)
		local r = paintOverview(self, data, unpack(arg, 1, arg.n))
		local page = self.frame and self.frame.prof
		local st = page and page.stage
		if st and st.cards then
			local showcase = data and data.showcase or {}
			for i, c in ipairs(st.cards) do
				local v = showcase[i]
				local info
				-- (1.14.0, after its second test: a card of a case stands in its own case, UI/CaseShow.lua)
				if v and v.card then
					if data.mine then
						info = E:Grade(v.card) and E:LabelOf(v.card) or nil
					elseif v.grade then
						-- (1.14.0: their Signature, their Luxury Case)
						local by = v.sig and self.member and ns.Guild and ns.Guild.Short and ns.Guild:Short(self.member) or nil
						info = E:LabelOf(v.card, v.grade, v.marks, v.cert, nil, { by = by, lux = v.lux })
					end
				end
				XU:Stand(st, c, info)
			end
		end
		return r
	end

	-- (another player's card in its case: its grade, its marks, its certificate in its tooltip; mine say it
	-- with the lines of a card, UI/Links.lua)
	local enter = A.ProfileCardEnter
	function A:ProfileCardEnter(c, ...)
		local r = enter(self, c, unpack(arg, 1, arg.n))
		local info = c.slabInfo
		if info and self.member and c.shown and GameTooltip:IsShown() then
			GameTooltip:AddLine(string.format(L["Appraised: %s"], E.Label(info.grade)), 1, 1, 1)
			if info.marks then
				GameTooltip:AddLine(E.MarksText(info.marks), 0.78, 0.8, 0.86, true)
			end
			if info.cert then
				GameTooltip:AddLine(string.format(L["Certificate No. %s"], E.CertText(info.cert)), 0.62, 0.62, 0.66)
			end
			GameTooltip:Show()
		end
		return r
	end
end

-------------------------------------------------------------------------------
-- At a banker: the window of Curator beside his
-------------------------------------------------------------------------------
-- The cards of the collection appraised, and those still to be.
function XU:Counts()
	local C = ns.Collection
	local done, left = 0, 0
	for _, s in ipairs(ns.Series or {}) do
		for _, card in ipairs(s.list or {}) do
			if C:Owned(card) then
				if E:Appraised(card) then
					done = done + 1
				else
					left = left + 1
				end
			end
		end
	end
	return done, left
end

function XU:Panel()
	if self.panel then
		return self.panel
	end
	local f = CreateFrame("Frame", "CuratorBankPanel", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, 260, 150)
	f:SetFrameStrata("HIGH")
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
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetTexture(MEDIA .. "Loupe")
	CuratorOctoFull.SetSize(f.icon, 34, 34)
	f.icon:SetPoint("TOPLEFT", 14, -12)
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 8, -2)
	f.title:SetText(L["Curator: the expertise"])
	f.sub = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.sub:SetWidth(180)
	CuratorOctoFull.SetWordWrap(f.sub, true)
	f.text = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.text:SetPoint("TOPLEFT", f.icon, "BOTTOMLEFT", 2, -8)
	f.text:SetWidth(232)
	CuratorOctoFull.SetWordWrap(f.text, true)
	f.text:SetTextColor(0.85, 0.85, 0.85)
	f.text:SetText(L["Have your cards appraised: open your album, click a card, then Appraise."])
	f.count = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.count:SetPoint("TOPLEFT", f.text, "BOTTOMLEFT", 0, -6)
	f.count:SetWidth(232)
	f.count:SetTextColor(0.7, 0.86, 1)
	f.open = Hud.ClaimButton(f, 200, 28, L["Open my album"])
	f.open:SetPoint("BOTTOM", 0, 12)
	CuratorOctoFull.SetScript(f.open, "OnClick", function()
		ns.Play(ns.SND.click)
		if not (A.frame and A.frame:IsShown()) then
			A:Toggle()
		end
		if A.mode ~= "mine" and A.mode ~= "contents" then
			A:SetMode("contents")
		end
	end)
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	self.panel = f
	return f
end

function XU:PaintPanel()
	local f = self.panel
	if not (f and f:IsShown()) then
		return
	end
	f.sub:SetText(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 12)))
	local done, left = self:Counts()
	S.SetFontObject(f.count, "GameFontHighlightSmall")
	f.count:SetText(string.format(L["Cards appraised: %d · still to appraise: %d"], done, left))
	-- (a little smaller when it is too long for its line: the counts of a big collection, a long language)
	local face, size, flags = f.count:GetFont()
	while face and size and size > 8 and ns.TextWidth(f.count) > 232 do
		size = size - 0.5
		f.count:SetFont(face, size, flags or "")
	end
end

function XU:ShowPanel(show)
	if not show then
		if self.panel then
			self.panel:Hide()
		end
		return
	end
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return
	end
	local f = self:Panel()
	f:ClearAllPoints()
	local bank = rawget(_G, "BankFrame")
	if bank and bank.IsShown and bank:IsShown() then
		f:SetPoint("TOPLEFT", bank, "TOPRIGHT", 8, 0)
	else
		f:SetPoint("LEFT", UIParent, "LEFT", 420, 80)
	end
	f:Show()
	self:PaintPanel()
end

ns.On("BANK_CHANGED", function(open)
	XU:ShowPanel(open)
	if A.detail and A.detail:IsShown() and not (XU.cer or XU.busy) then
		A:PaintAppraise()
	end
end)

ns.On("RUBIES_CHANGED", function()
	XU:PaintPanel()
	if A.detail and A.detail:IsShown() and not (XU.cer or XU.busy) then
		A:PaintAppraise()
	end
end)

ns.On("CARD_APPRAISED", function()
	XU:PaintPanel()
end)
