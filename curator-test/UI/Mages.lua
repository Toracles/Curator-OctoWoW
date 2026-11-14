local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local C = ns.Collection
local E = ns.Expertise
local RB = ns.Rubies
local MG = ns.Mages
local XU = ns.ExpertiseUI
local RU = ns.RestoreUI
local CD = ns.CaseDetail

-------------------------------------------------------------------------------
-- (1.14.0, 1 November, his idea of 2 h 22 and his « go go go » of 2 h 49) The masters of the mages on the screen
-- (Mages.lua). In the album, a titanforged copy of mine shown big (of a booster, or a card of a case), at a master of
-- the mages (his window of dialogue, or his window of training): the block of his certificate in the place of the
-- expert's, its price, its button. Certified: the room darkens, the runes of the mages turn behind the card, his light
-- reads it from top to bottom while its certificate is written beside it, line by line: its family comes out in its own
-- colours, its number counts up, its light, its foils, its metal; his seal comes down on it. Its certificate after,
-- anywhere (« Voir le certificat »): a document of the mages, its family in its colours turning as its light turns, its
-- colours in a band, each line said in its tooltip. In his window of dialogue: a line of Curator that opens the album
-- on the titanforged cards.
-------------------------------------------------------------------------------
local MU = {}
ns.MagesUI = MU

local GOLD = S.GOLD
local MAGE = { 0.41, 0.8, 0.94 }      -- the colour of the mages
local MAGE_HI = { 0.72, 0.92, 1 }
local ARCANE = { 0.66, 0.58, 1 }      -- the light of the arcane
local LINE_GOLD = { 0.86, 0.68, 0.32 }
local WAX = { 0.5, 0.34, 0.95 }       -- the wax of their seal, violet
local LABEL_INK = { 0.62, 0.68, 0.84 }
local ARM = 3
local DIM, DIM_SCENE = 0.62, 0.86
local SPOT, SPOT_SCENE = 0.32, 0.62
local CER = {}  -- the owner of the animations of the scene
local FADE = {} -- the owner of the room coming back after it
local ICON = "Interface\\Icons\\Spell_Holy_MagicalSentry"
-- the moments of the scene (seconds): the room darkens, the runes, a line of the certificate each, the seal, the end
local INTRO, ROW, SWEEP, HOLD = 0.45, 0.17, 0.95, 1.1
local LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }

local function Day(t)
	t = tonumber(t)
	return (t and t > 0) and date("%d/%m/%Y", t) or "?"
end

local function Clock(t)
	t = tonumber(t)
	return (t and t > 0) and date("%H:%M", t) or "?"
end

-- (a decimal number as the language writes it)
local function Dec(x, n)
	local s = string.format(("%." .. (n or 1) .. "f"), tonumber(x) or 0)
	return (string.gsub(s, "%.", ns.L["."]))
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

local function Hex(r, g, b)
	return string.format(("%02x%02x%02x"), math.floor(math.max(0, math.min(1, r)) * 255), math.floor(math.max(0, math.min(1, g)) * 255),
		math.floor(math.max(0, math.min(1, b)) * 255))
end

-- The letters of the grimoires (the default font of a client in another script).
local function Fancy(fs, size, flags)
	local file = (LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] and "Fonts\\MORPHEUS.TTF") or nil
	if file then
		fs:SetFont(file, size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
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

-- (1 November, 9 h 22, his word: « le son du sort est en boucle et ne s'arrête jamais ») The precast of the light, a
-- sound the game loops: stopped by time, and when the scene ends.
local LAMP = 1.4
local function StopLamp(cer)
	local h = cer and cer.lamp
	if h and StopSound then
		cer.lamp = nil
		pcall(StopSound, h, 400)
	end
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

-- The colours of the prism, round (h from 0 to 1).
local function Rainbow(h)
	h = (CuratorOctoFull.Mod(h , 1)) * 6
	local i = math.floor(h)
	local f = h - i
	if i == 0 then
		return 1, f, 0
	elseif i == 1 then
		return 1 - f, 1, 0
	elseif i == 2 then
		return 0, 1, f
	elseif i == 3 then
		return 0, 1 - f, 1
	elseif i == 4 then
		return f, 0, 1
	end
	return 1, 0, 1 - f
end

-- The colour of a pattern at a point of the round of its light (u: 0 to 1): its own colours, else those of the prism.
local function ColorAt(info, u)
	if info and info.tint and ns.Patterns then
		return ns.Patterns.Color(info.look, u)
	end
	local r, g, b = Rainbow(u)
	return 0.35 + 0.65 * r, 0.35 + 0.65 * g, 0.35 + 0.65 * b
end

-- What the block works on (UI/Restore.lua: the copy chosen of a card of a booster, or of a card of a case): { card, id,
-- rec, case }, nil: none.
local function Target()
	return RU and RU.Target and RU.Target() or nil
end
MU.Target = Target

local function TCan(t)
	if t.case then
		return MG:CanCertifyCase(t.id)
	end
	return MG:CanCertify(t.card, t.id)
end
local function TPrice(t)
	if t.case then
		return MG:CasePrice(t.rec)
	end
	return MG:Price(t.card)
end
local function TCertify(t)
	if t.case then
		return MG:CertifyCase(t.id)
	end
	return MG:Certify(t.card, t.id)
end

local function NameOf(card)
	if type(card) == "table" and card.isCase then
		return CD and CD.Name(card) or ""
	end
	return C:Name(card)
end

local function Showing(d, card)
	return d ~= nil and card ~= nil and (d.shown == card or d.caseShown == card)
end

-- The card shown big painted again (of a booster, of a case).
local function Repaint(d, card)
	if type(card) == "table" and card.isCase then
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

-- (the album closed in the middle of a scene hides its detail first: the scene ends with the album)
local function HookAlbum()
	if MU.albumHooked or not (A.frame and A.frame.HookScript) then
		return
	end
	MU.albumHooked = true
	A.frame:HookScript("OnHide", function()
		MU:End(true)
		MU:HideCert()
	end)
end

-- Whether the block of the master is the one shown: at a master of the mages, a titanforged copy of mine shown big (not
-- at an enchanter: his block first).
local function Shown()
	if not MG:AtMaster() then
		return false
	end
	if RU and RU.Shown and RU.Shown() then
		return false
	end
	local t = Target()
	return t ~= nil and MG.Pattern(t.rec, t.case) ~= nil
end
MU.Shown = Shown

-------------------------------------------------------------------------------
-- The block of the detail
-------------------------------------------------------------------------------
local WHY = {
	closed = "Curator is closed: nothing can be bought.",
	card = "Not one of your copies.",
	titan = "Only a titanforged card has a certificate of the mages.",
	done = "Certified already: its certificate stays with it.",
	away = "At an enchanter: certified once it is back.",
	master = "At a master of the mages: talk to one, then show this card in your album.",
	rubies = "Not enough rubies.",
}
MU.WHY = WHY
-- (what the expert says of a titanforged copy without it: UI/Expertise.lua, UI/CaseDetail.lua)
MU.CERT_WHY = "Go see a master of the mages to certify your titanforged!"

local function BuildBlock(d)
	local tw = d.textW or 374
	local v = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(v, tw, 120)
	v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	-- its head: the mark of the mages, what the copy is
	v.icon = v:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(v.icon, 22, 22)
	v.icon:SetPoint("TOPLEFT", 0, 0)
	v.icon:SetTexture(ICON)
	v.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	v.ring = v:CreateTexture(nil, "OVERLAY")
	v.ring:SetTexture(MEDIA .. "StrikeRunes")
	CuratorOctoFull.SetSize(v.ring, 36, 36)
	v.ring:SetPoint("CENTER", v.icon, "CENTER")
	v.ring:SetVertexColor(MAGE[1], MAGE[2], MAGE[3])
	v.ring:SetBlendMode("ADD")
	v.ring:SetAlpha(0.8)
	v.title = Hud.Text(v, 12, "")
	v.title:SetPoint("LEFT", v.icon, "RIGHT", 10, 5)
	v.title:SetTextColor(MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
	v.line = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.line:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -2)
	v.line:SetWidth(tw - 34)
	v.line:SetWordWrap(false)
	v.note = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.note:SetPoint("TOPLEFT", v.icon, "BOTTOMLEFT", 0, -10)
	v.note:SetWidth(tw)
	v.note:SetWordWrap(true)
	v.note:SetSpacing(2)
	local b = S.Button(v, "", 220, 22)
	if b.SetMotionScriptsWhileDisabled then
		b:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		MU:Click()
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		MU:Tooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self)
		if self.armed and GetTime() - self.armed >= ARM then
			self.armed = nil
			MU:Paint()
		end
	end)
	v.button = b
	CuratorOctoFull.SetScript(v, "OnUpdate", function(self, elapsed)
		self.rot = CuratorOctoFull.Mod(((self.rot or 0) + elapsed * 0.5) , (math.pi * 2))
		CuratorOctoFull.SetRotation(self.ring, self.rot)
	end)
	v:Hide()
	d.mage = v
end

-- A family named in its colour (its first colour, a little brighter).
local function FamilyText(info)
	local r, g, b = MG.Color(info)
	return "|cff" .. Hex(0.3 + 0.7 * r, 0.3 + 0.7 * g, 0.3 + 0.7 * b) .. L[info.name] .. "|r"
end

-- What the block says, its button; where what comes under it goes.
function MU:Paint()
	local d = A.detail
	local v = d and d.mage
	if not v or self.cer then
		return
	end
	self:PaintCertButton()
	if not Shown() then
		v:Hide()
		return
	end
	local t = Target()
	local rec = t.rec
	local tw = d.textW or 374
	-- (in the place of the expert's block, and of the masters')
	d.appr:Hide()
	if d.void then
		d.void:Hide()
	end
	if d.rest then
		d.rest:Hide()
	end
	v:ClearAllPoints()
	v:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", 0, -14)
	v:Show()
	v.title:SetText(E.Upper(L["Arcane certificate"]))
	local b = v.button
	local info = MG.Read(rec, t.case)
	if info then
		v.line:SetText(string.format(L["Certified by %s on %s"], info.by or L["a master of the mages"], Day(info.t)))
		v.line:SetTextColor(0.86, 0.9, 1)
		v.note:SetText(FamilyText(info) .. "  ·  " .. string.format(L["Pattern No. %s of %s"], ns.Num(info.n), ns.Num(info.max)) .. "\n|cffa9a9b4"
			.. string.format(L["Certificate No. %s"], E.CertText(info.no)) .. "|r")
		b.mode = "view"
		b.armed = nil
		b.why = nil
		b:SetLabel(L["See the certificate"])
		b:SetEnabled(true)
	else
		-- (its number, the master's to tell)
		v.line:SetText(L["Not certified"])
		v.line:SetTextColor(0.7, 0.72, 0.8)
		v.note:SetText(L["A master of the mages reads its foils, its light and its metal, and writes it all on its certificate. A titanforged card is appraised only with it."])
		b.mode = "certify"
		local ok, why = TCan(t)
		b.why = why
		local price = RB.Text(TPrice(t), 13)
		if b.armed and b.armedId == t.id and GetTime() - b.armed < ARM then
			b:SetLabel(L["Confirm"] .. " · " .. price)
		else
			b:SetLabel(L["Have it certified"] .. " · " .. price)
		end
		b:SetEnabled(ok and true or false)
	end
	v.note:SetTextColor(0.8, 0.8, 0.86)
	Wide(b, 200)
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", v.note, "BOTTOMLEFT", 0, -12)
	b:Show()
	-- (its height: what it holds)
	local top = v:GetTop()
	local bottom = b:GetBottom()
	if top and bottom and top > bottom then
		v:SetHeight(top - bottom)
	end
	v:SetWidth(tw)
	-- (what comes under it: the album of the card; of a card of a case, its collection)
	local under = t.case and d.caseSet or d.set
	if under then
		under:ClearAllPoints()
		under:SetPoint("TOPLEFT", b, "BOTTOMLEFT", -2, -14)
	end
end

function MU:Tooltip(b)
	local t = Target()
	if not t then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L["The certificate of the mages"], MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
	GameTooltip:AddLine(L["A master of the mages reads all that its pattern makes of it: its family, its number, its colours, its light, its foils, the metal of its frame. It is all written on its certificate, which stays with it, in a trade and at the Steamwheedle Exchange."], 0.85, 0.85, 0.85, true)
	if b.mode == "certify" then
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(TPrice(t), 13)), 1, 0.82, 0.25)
		local why = b.why == "guard" and ns.Guard and ns.Guard.SHORT or WHY[b.why or ""]
		if why then
			GameTooltip:AddLine(L[why], 1, 0.45, 0.4, true)
		elseif b.armed then
			GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
		end
		GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	end
	GameTooltip:Show()
end

-- A first click arms the button, a second within its seconds certifies the copy chosen: the scene of the master.
function MU:Click()
	local d = A.detail
	local b = d and d.mage and d.mage.button
	local t = Target()
	if not (b and t) or self.cer or (XU and XU.cer) or (RU and RU.cer) then
		return
	end
	if b.mode == "view" then
		ns.Play(ns.SND.page)
		return self:ToggleCert()
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local ok, why = TCan(t)
	if not ok then
		ns.Play(ns.SND.close)
		b.why = why
		self:Tooltip(b)
		return
	end
	if not (b.armed and b.armedId == t.id and GetTime() - b.armed < ARM) then
		b.armed, b.armedId = GetTime(), t.id
		ns.Play(ns.SND.click)
		self:Paint()
		self:Tooltip(b)
		return
	end
	b.armed, b.armedId = nil, nil
	-- (what is painted waits for the end of the scene)
	self.busy = true
	local res, err = TCertify(t)
	self.busy = nil
	if not res then
		ns.Play(ns.SND.close)
		b.why = err
		self:Paint()
		return
	end
	res.card = t.card
	GameTooltip:Hide()
	self:Begin(res)
end

-------------------------------------------------------------------------------
-- The certificate
-------------------------------------------------------------------------------
-- Its lines: { key of its label, what it says (info, case) -> text, swatches (info) -> { colours } or nil, its tooltip }.
local function Variant(k, of)
	if k == 1 then
		return string.format(L["The original (1 of %d)"], of)
	end
	return string.format(L["Variant %d of %d"], k, of)
end

-- (the colours of the prism, as a family without its own shows them)
local PRISM = { { 1, 0.2, 0.2 }, { 1, 0.65, 0.1 }, { 1, 1, 0.2 }, { 0.2, 1, 0.3 }, { 0.2, 0.6, 1 }, { 0.75, 0.3, 1 } }

local ROWS = {
	{ "Metal of the frame", function(i)
		return L[i.metal]
	end, function(i)
		return { i.metalColor }
	end, "The metal of its frame: the gold of the titans, or the metal of its family." },
	{ "Foil of the window", function(i)
		return Variant(i.window, i.holo)
	end, nil, "The foil over the window of its creature: one of 27. The first is the one of the first titanforged cards." },
	{ "Foil of the frame", function(i)
		return Variant(i.frame, i.holo)
	end, nil, "The foil of its frame: one of 27." },
	{ "Stardust", function(i)
		return Variant(i.dust, i.holo)
	end, nil, "The dust of stars over the card: one of 27." },
	{ "Its light", function(i)
		return string.format(L["A round in %s s"], Dec(i.round, 1)) .. "  ·  " .. L[MG.SpeedWord(i.speed)]
	end, nil, "How long its light takes to go round all its colours: its own pace, the pace of its family a little changed." },
	{ "Its way", function(i)
		return i.forward and L["In the order of its colours"] or L["Against the order of its colours"]
	end, nil, "Which way its light goes round its colours." },
	{ "Its flashes", function(i)
		return L[MG.SharpWord(i.sharp)]
	end, nil, "How sharp its lights are: soft, crisp as the prism, sharp, or in flashes." },
	{ "Where it starts", function(i)
		return string.format(L["At %d°"], i.start)
	end, nil, "Where its light starts its round, on the circle of its colours." },
	{ "Its stars", function(i)
		return L[MG.StarsWord(i.stars)] .. " (×" .. Dec(i.stars, 2) .. ")"
	end, function(i)
		return i.glints
	end, "How much dust of stars glitters on it, and the colours of its stars." },
	{ "Light of its creature", function(i)
		return L[MG.GloryWord(i.glory)]
	end, function(i)
		return i.spark and { i.spark } or nil
	end, "The light behind its creature, and the colour of its sparks." },
	{ "Brightness of its foil", function(i)
		return "×" .. Dec(i.power, 2)
	end, nil, "How bright its foil is, against the prism of the first titanforged cards." },
	{ "Its colours", function(i)
		return i.tint and string.format(L["%d colours"], CuratorOctoFull.Length(i.tint)) or L["All the colours of the prism"]
	end, function(i)
		return i.tint or PRISM
	end, "The colours its light goes through, in their order." },
}

local SW = 9 -- (a swatch)

local function Swatch(parent)
	local s = parent:CreateTexture(nil, "ARTWORK", nil, 2)
	CuratorOctoFull.SetSize(s, SW, SW)
	local e = parent:CreateTexture(nil, "ARTWORK", nil, 1)
	CuratorOctoFull.ColorTexture(e, 0, 0, 0, 0.9)
	e:SetPoint("TOPLEFT", s, "TOPLEFT", -1, 1)
	e:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 1, -1)
	s.edge = e
	return s
end

local function Line(parent, w, color, alpha)
	local t = parent:CreateTexture(nil, "BORDER", nil, 3)
	CuratorOctoFull.ColorTexture(t, color[1], color[2], color[3], alpha or 1)
	CuratorOctoFull.SetSize(t, w, 1)
	return t
end

-- (a corner of gold: its texture turned for each corner)
local CORNERS = {
	{ "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 }, { "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 },
}

-- The certificate itself, a document of the mages (parent: where it lives; tw: the width of its words; name: a global
-- name, for a window of its own). Placed by its owner (the detail of the album: BuildCert; a window: MU:CertWindow).
local function NewCert(parent, tw, name)
	local W = tw + 26
	local v = CreateFrame("Frame", name, parent)
	v.W = W
	CuratorOctoFull.SetSize(v, W, 520)
	v:EnableMouse(true)
	v:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(v, "OnMouseWheel", function() end)
	v:Hide()
	-- its paper: the night of the arcane, its stars, its edges in the shade; the sigil of the titans faint in it
	v.bg = v:CreateTexture(nil, "BACKGROUND", nil, 0)
	v.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(v.bg, 0.02, 0.025, 0.06, 0.97)
	v.neb = v:CreateTexture(nil, "BACKGROUND", nil, 1)
	v.neb:SetPoint("TOPLEFT", 3, -3)
	v.neb:SetPoint("BOTTOMRIGHT", -3, 3)
	v.neb:SetTexture(MEDIA .. "VoidNebula")
	v.neb:SetVertexColor(0.32, 0.42, 0.9)
	v.neb:SetAlpha(0.2)
	v.vig = v:CreateTexture(nil, "BACKGROUND", nil, 2)
	v.vig:SetAllPoints()
	v.vig:SetTexture(MEDIA .. "Vignette")
	v.vig:SetAlpha(0.9)
	v.sheen = v:CreateTexture(nil, "OVERLAY", nil, 7)
	v.sheen:SetTexture(MEDIA .. "Sheen")
	v.sheen:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(v.sheen, 200, 200)
	v.sheen:Hide()
	v.sigil = v:CreateTexture(nil, "BORDER", nil, 0)
	v.sigil:SetTexture(MEDIA .. "TitanSigil")
	v.sigil:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(v.sigil, 300, 300)
	v.sigil:SetVertexColor(MAGE[1], MAGE[2], MAGE[3])
	v.sigil:SetAlpha(0.06)
	-- its frame: a line of gold, a line of the mages inside it, its four corners of gold
	local function Frame(inset, color, alpha)
		local top = Line(v, 10, color, alpha)
		top:SetPoint("TOPLEFT", inset, -inset)
		top:SetPoint("TOPRIGHT", -inset, -inset)
		local bot = Line(v, 10, color, alpha)
		bot:SetPoint("BOTTOMLEFT", inset, inset)
		bot:SetPoint("BOTTOMRIGHT", -inset, inset)
		local l = v:CreateTexture(nil, "BORDER", nil, 3)
		CuratorOctoFull.ColorTexture(l, color[1], color[2], color[3], alpha)
		l:SetWidth(1)
		l:SetPoint("TOPLEFT", inset, -inset)
		l:SetPoint("BOTTOMLEFT", inset, inset)
		local r = v:CreateTexture(nil, "BORDER", nil, 3)
		CuratorOctoFull.ColorTexture(r, color[1], color[2], color[3], alpha)
		r:SetWidth(1)
		r:SetPoint("TOPRIGHT", -inset, -inset)
		r:SetPoint("BOTTOMRIGHT", -inset, inset)
	end
	Frame(3, LINE_GOLD, 0.95)
	Frame(7, MAGE, 0.3)
	for _, k in ipairs(CORNERS) do
		local t = v:CreateTexture(nil, "ARTWORK", nil, 5)
		t:SetTexture(MEDIA .. "GoldCorner")
		CuratorOctoFull.SetSize(t, 30, 30)
		t:SetTexCoord(k[2], k[3], k[4], k[5])
		t:SetPoint(k[1], v, k[1], 0, 0)
	end
	-- its head
	v.title = v:CreateFontString(nil, "OVERLAY")
	Fancy(v.title, 19, "")
	v.title:SetTextColor(1, 0.84, 0.5)
	v.title:SetShadowOffset(1, -1)
	v.title:SetShadowColor(0, 0, 0, 1)
	v.title:SetPoint("TOP", 0, -16)
	v.says = S.Text(v, "GameFontHighlightSmall", "CENTER")
	v.says:SetPoint("TOP", v.title, "BOTTOM", 0, -4)
	v.says:SetTextColor(LABEL_INK[1], LABEL_INK[2], LABEL_INK[3])
	v.rule1 = Line(v, W - 70, LINE_GOLD, 0.6)
	v.rule1:SetPoint("TOP", v.says, "BOTTOM", 0, -8)
	v.gem = v:CreateTexture(nil, "ARTWORK", nil, 6)
	v.gem:SetTexture(MEDIA .. "PrismShard")
	CuratorOctoFull.SetSize(v.gem, 26, 26)
	v.gem:SetPoint("CENTER", v.rule1, "CENTER", 0, 0)
	v.gemGlow = v:CreateTexture(nil, "ARTWORK", nil, 5)
	v.gemGlow:SetTexture(MEDIA .. "Glow")
	v.gemGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(v.gemGlow, 40, 40)
	v.gemGlow:SetPoint("CENTER", v.gem, "CENTER")
	v.gemGlow:SetAlpha(0.5)
	-- the card
	v.name = S.Text(v, "GameFontHighlightLarge", "CENTER")
	v.name:SetPoint("TOP", v.rule1, "BOTTOM", 0, -11)
	v.name:SetWidth(W - 60)
	v.name:SetWordWrap(false)
	v.sub = S.Text(v, "GameFontDisableSmall", "CENTER")
	v.sub:SetPoint("TOP", v.name, "BOTTOM", 0, -4)
	v.sub:SetWidth(W - 60)
	v.sub:SetWordWrap(false)
	-- its family, in its colours; the band of its colours under it, turning as its light turns
	v.famHit = CreateFrame("Button", nil, v)
	CuratorOctoFull.SetSize(v.famHit, W - 60, 50)
	v.famHit:SetPoint("TOP", v.sub, "BOTTOM", 0, -8)
	CuratorOctoFull.SetScript(v.famHit, "OnEnter", function(self)
		MU:FamilyTooltip(self)
	end)
	CuratorOctoFull.SetScript(v.famHit, "OnLeave", function()
		GameTooltip:Hide()
	end)
	v.famLabel = S.Text(v, "GameFontHighlightSmall", "CENTER")
	v.famLabel:SetPoint("TOP", v.famHit, "TOP", 0, 0)
	v.famLabel:SetTextColor(MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
	v.fam = v:CreateFontString(nil, "OVERLAY")
	Fancy(v.fam, 28, "")
	v.fam:SetShadowOffset(1, -1)
	v.fam:SetShadowColor(0, 0, 0, 1)
	v.fam:SetPoint("TOP", v.famLabel, "BOTTOM", 0, -3)
	v.famGlow = v:CreateTexture(nil, "ARTWORK", nil, 0)
	v.famGlow:SetTexture(MEDIA .. "Glow")
	v.famGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(v.famGlow, 260, 70)
	v.famGlow:SetPoint("CENTER", v.fam, "CENTER", 0, 0)
	v.famGlow:SetAlpha(0.25)
	v.band = {}
	local BW = W - 80
	v.bandN = 40
	for i = 1, v.bandN do
		local t = v:CreateTexture(nil, "ARTWORK", nil, 3)
		CuratorOctoFull.SetSize(t, BW / v.bandN + 0.6, 6)
		t:SetPoint("TOPLEFT", v.famHit, "BOTTOMLEFT", 10 + (i - 1) * BW / v.bandN, -2)
		CuratorOctoFull.ColorTexture(t, 1, 1, 1, 1)
		v.band[i] = t
	end
	v.bandTop = Line(v, BW + 2, LINE_GOLD, 0.7)
	v.bandTop:SetPoint("BOTTOMLEFT", v.band[1], "TOPLEFT", -1, 1)
	v.bandBot = Line(v, BW + 2, LINE_GOLD, 0.7)
	v.bandBot:SetPoint("TOPLEFT", v.band[1], "BOTTOMLEFT", -1, -1)
	-- its number
	v.num = v:CreateFontString(nil, "OVERLAY")
	Fancy(v.num, 17, "")
	v.num:SetTextColor(0.96, 0.96, 1)
	v.num:SetPoint("TOP", v.famHit, "BOTTOM", 0, -13)
	v.rank = S.Text(v, "GameFontHighlightSmall", "CENTER")
	v.rank:SetPoint("TOP", v.num, "BOTTOM", 0, -4)
	v.rank:SetWidth(W - 50)
	v.rank:SetTextColor(LABEL_INK[1], LABEL_INK[2], LABEL_INK[3])
	v.first = S.Text(v, "GameFontNormalSmall", "CENTER")
	v.first:SetPoint("TOP", v.rank, "BOTTOM", 0, -3)
	v.first:SetWidth(W - 50)
	v.first:SetTextColor(1, 0.82, 0.4)
	v.rule2 = Line(v, W - 44, LINE_GOLD, 0.45)
	-- what it is, line by line
	v.rows = {}
	for i, def in ipairs(ROWS) do
		local i, def = i, def; local r = CreateFrame("Button", nil, v)
		CuratorOctoFull.SetSize(r, W - 44, 14)
		r.hi = r:CreateTexture(nil, "BACKGROUND")
		r.hi:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.hi, MAGE[1], MAGE[2], MAGE[3], 0.12)
		r.hi:Hide()
		r.label = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.label:SetPoint("LEFT", 2, 0)
		r.label:SetTextColor(LABEL_INK[1], LABEL_INK[2], LABEL_INK[3])
		r.value = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.value:SetPoint("RIGHT", -2, 0)
		r.value:SetTextColor(0.96, 0.96, 1)
		r.sw = {}
		r.def = def
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			self.hi:Show()
			MU:RowTooltip(self)
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function(self)
			self.hi:Hide()
			GameTooltip:Hide()
		end)
		v.rows[i] = r
	end
	v.rule3 = Line(v, W - 44, LINE_GOLD, 0.45)
	-- its foot: who wrote it, when, its number; his seal, its hologram
	v.byLabel = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.byLabel:SetTextColor(LABEL_INK[1], LABEL_INK[2], LABEL_INK[3])
	v.by = v:CreateFontString(nil, "OVERLAY")
	Fancy(v.by, 15, "")
	v.by:SetTextColor(1, 0.84, 0.5)
	v.by:SetJustifyH("LEFT")
	v.by:SetPoint("TOPLEFT", v.byLabel, "BOTTOMLEFT", 0, -3)
	v.when = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.when:SetPoint("TOPLEFT", v.by, "BOTTOMLEFT", 0, -4)
	v.when:SetTextColor(0.8, 0.8, 0.86)
	v.no = S.Text(v, "GameFontDisableSmall", "LEFT")
	v.no:SetPoint("TOPLEFT", v.when, "BOTTOMLEFT", 0, -3)
	v.seal = v:CreateTexture(nil, "ARTWORK", nil, 4)
	v.seal:SetTexture(MEDIA .. "Seal")
	if v.seal.SetDesaturated then
		v.seal:SetDesaturated(true)
	end
	v.seal:SetVertexColor(WAX[1] * 1.5, WAX[2] * 1.5, WAX[3] * 1.5)
	CuratorOctoFull.SetSize(v.seal, 70, 70)
	v.sealRing = v:CreateTexture(nil, "ARTWORK", nil, 5)
	v.sealRing:SetTexture(MEDIA .. "StampRing")
	v.sealRing:SetBlendMode("ADD")
	v.sealRing:SetVertexColor(MAGE[1], MAGE[2], MAGE[3])
	CuratorOctoFull.SetSize(v.sealRing, 86, 86)
	v.sealRing:SetPoint("CENTER", v.seal, "CENTER")
	v.sealRing:SetAlpha(0)
	v.holo = v:CreateTexture(nil, "ARTWORK", nil, 4)
	v.holo:SetTexture(MEDIA .. "SlabHolo")
	CuratorOctoFull.SetSize(v.holo, 30, 30)
	v.holo:SetPoint("RIGHT", v.seal, "LEFT", -10, -4)
	v.holoTip = CreateFrame("Frame", nil, v)
	v.holoTip:SetAllPoints(v.holo)
	v.holoTip:EnableMouse(true)
	CuratorOctoFull.SetScript(v.holoTip, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Its hologram"], MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
		GameTooltip:AddLine(L["In the colours of its family, as its light goes round: the mark that the certificate is the masters' own."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(v.holoTip, "OnLeave", function()
		GameTooltip:Hide()
	end)
	v.close = Wide(S.Button(v, L["Close the certificate"], 170, 22), 170)
	CuratorOctoFull.SetScript(v.close, "OnClick", function()
		ns.Play(ns.SND.page)
		if v.onClose then
			v.onClose()
		end
	end)
	-- alive: its family in its colours, its band, its hologram turning as its light turns; the sigil turning slowly
	CuratorOctoFull.SetScript(v, "OnUpdate", function(self, elapsed)
		self.acc = (self.acc or 0) + elapsed
		self.rot = CuratorOctoFull.Mod(((self.rot or 0) + elapsed * 0.04) , (math.pi * 2))
		CuratorOctoFull.SetRotation(self.sigil, self.rot)
		if self.acc < 0.04 then
			return
		end
		self.acc = 0
		MU:Animate(self)
	end)
	return v
end

-- The certificate in the detail of the album, beside the card: in the place of what there is to know.
local function BuildCert(d)
	if d.certView then
		return d.certView
	end
	local v = NewCert(d, d.textW or 374)
	v:SetFrameLevel(d.card:GetFrameLevel() + 18)
	v.x, v.y = (d.textX or 348) - 13, -10
	v:SetPoint("TOPLEFT", d, "TOPLEFT", v.x, v.y)
	-- (never past the detail)
	v.room = function()
		local h = d:GetHeight() or 0
		return h > 200 and (h + v.y - 6) or nil
	end
	v.onClose = function()
		MU:HideCert()
	end
	d.certView = v
	return v
end

-- (the place of each piece of the certificate: its rows under its number, its foot under them)
local function Layout(v, info)
	local y = 0
	CuratorOctoFull.SetShown(v.first, info.first and true or false)
	local after = info.first and v.first or v.rank
	v.rule2:ClearAllPoints()
	v.rule2:SetPoint("TOP", after, "BOTTOM", 0, -10)
	for i, r in ipairs(v.rows) do
		r:ClearAllPoints()
		r:SetPoint("TOP", v.rule2, "BOTTOM", 0, -5 - (i - 1) * 14)
		y = i
	end
	v.rule3:ClearAllPoints()
	v.rule3:SetPoint("TOP", v.rows[y], "BOTTOM", 0, -8)
	v.byLabel:ClearAllPoints()
	v.byLabel:SetPoint("TOPLEFT", v.rule3, "BOTTOMLEFT", 2, -10)
	v.seal:ClearAllPoints()
	v.seal:SetPoint("TOPRIGHT", v.rule3, "BOTTOMRIGHT", -6, -4)
	v.close:ClearAllPoints()
	v.close:SetPoint("TOP", v.rule3, "BOTTOM", 0, -80)
	-- (its height: down to its button, never past the room it has)
	local top = v:GetTop()
	local bottom = v.close:GetBottom()
	if top and bottom and top > bottom then
		local room = v.room and v.room() or nil
		v:SetHeight(math.min(top - bottom + 14, room or 9999))
	end
	v.sigil:ClearAllPoints()
	v.sigil:SetPoint("CENTER", v.rule2, "BOTTOM", 0, -96)
end

-- Everything of a certificate written on it (info: MG.Read, with card, idx, case).
function MU:FillCert(v, info)
	v.info = info
	v.title:SetText(E.Upper(L["Arcane certificate"]))
	v.says:SetText(L["The masters of the mages attest what follows"])
	v.name:SetText(info.cardName or "")
	v.sub:SetText(info.subText or "")
	v.famLabel:SetText(E.Upper(L["Family"]))
	v.fam:SetText(L[info.name])
	local r, g, b = MG.Color(info)
	v.famGlow:SetVertexColor(r, g, b)
	v.gem:SetVertexColor(0.6 + 0.4 * r, 0.6 + 0.4 * g, 0.6 + 0.4 * b)
	v.gemGlow:SetVertexColor(r, g, b)
	v.num:SetText(string.format(L["Pattern No. %s"], ns.Num(info.n)) .. "  |cffa9a9b4" .. string.format(L["of %s"], ns.Num(info.max)) .. "|r")
	v.rank:SetText(string.format(L["No. %s of its family, of %s"], ns.Num(info.rank), ns.Num(info.size)) .. "  ·  "
		.. string.format(L["1 chance in %s"], ns.Num(info.max)))
	v.first:SetText(L["The original of its family: its look as it was made"])
	for _, row in ipairs(v.rows) do
		local def = row.def
		row.label:SetText(L[def[1]])
		row.value:SetText(def[2](info))
		for _, s in ipairs(row.sw) do
			s:Hide()
			s.edge:Hide()
		end
		local cols = def[3] and def[3](info) or nil
		if cols then
			local x = -6 - ns.TextWidth(row.value)
			for k = CuratorOctoFull.Length(cols), 1, -1 do
				local s = row.sw[k] or Swatch(row)
				row.sw[k] = s
				local col = cols[k]
				CuratorOctoFull.ColorTexture(s, col[1], col[2], col[3], 1)
				s:ClearAllPoints()
				s:SetPoint("RIGHT", row, "RIGHT", x - 2, 0)
				x = x - SW - 4
				s:Show()
				s.edge:Show()
			end
		end
	end
	v.byLabel:SetText(L["Certified by"])
	v.by:SetText(info.by or L["a master of the mages"])
	v.when:SetText(string.format(L["on %s at %s"], Day(info.t), Clock(info.t)))
	v.no:SetText(string.format(L["Certificate No. %s"], E.CertText(info.no)))
	Layout(v, info)
	self:Animate(v)
end

-- Alive: its family, its band, its hologram, at the pace and the way of its own light.
function MU:Animate(v)
	local info = v.info
	if not info then
		return
	end
	local t = GetTime()
	-- (its own pace, its own way; a card of a case, so slow, a little quicker here so that it is seen to turn)
	local base = (t / math.max(0.5, math.min(40, info.round))) * (info.forward and 1 or -1)
	-- (its family: a colour each letter, the round of its colours going over them)
	if not v.famTyping then
		local chars = v.famChars
		if not chars or v.famFor ~= info.name then
			chars = Chars(L[info.name])
			v.famChars, v.famFor = chars, info.name
		end
		local out = {}
		for i, ch in ipairs(chars) do
			local r, g, b = ColorAt(info, base + i * 0.06)
			out[CuratorOctoFull.Length(out) + 1] = "|cff" .. Hex(0.25 + 0.75 * r, 0.25 + 0.75 * g, 0.25 + 0.75 * b) .. ch .. "|r"
		end
		v.fam:SetText(table.concat(out))
	end
	for i, s in ipairs(v.band) do
		local r, g, b = ColorAt(info, base + i / v.bandN)
		CuratorOctoFull.ColorTexture(s, r, g, b, v.bandA or 1)
	end
	local r, g, b = ColorAt(info, base)
	v.holo:SetVertexColor(0.55 + 0.45 * r, 0.55 + 0.45 * g, 0.55 + 0.45 * b)
	v.famGlow:SetVertexColor(r, g, b)
	-- (a light sweeps over the certificate now and then, as over a foil)
	local sh = v.sheen
	if sh then
		local k = (CuratorOctoFull.Mod(t , 7)) / 1.6
		if k < 1 then
			local h = v:GetHeight() or 500
			sh:ClearAllPoints()
			sh:SetPoint("CENTER", v, "TOPLEFT", 110 + (v.W - 220) * k, -h * (0.2 + 0.6 * k))
			sh:SetAlpha(0.16 * math.sin(k * math.pi))
			sh:Show()
		else
			sh:Hide()
		end
	end
end

-- What a line of the certificate means.
function MU:RowTooltip(row)
	local v = row:GetParent()
	local info = v and v.info
	if not info then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L[row.def[1]], MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
	GameTooltip:AddLine(row.value:GetText() or "", 1, 1, 1)
	GameTooltip:AddLine(L[row.def[4]], 0.85, 0.85, 0.85, true)
	GameTooltip:Show()
end

-- Its family among the twelve.
function MU:FamilyTooltip(b)
	local v = b:GetParent()
	local info = v and v.info
	if not info then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L["The twelve families"], MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
	GameTooltip:AddLine(L["Each pattern belongs to one of twelve families, each as likely as the others: its colours, its light and the metal of its frame."], 0.85, 0.85, 0.85, true)
	for i, name in ipairs(MG.FAMILIES) do
		local here = i == info.family
		local look = ns.Patterns and ns.Patterns:Look(i)
		local fi = look and { tint = look.tint, look = look } or nil
		local out = {}
		for k, ch in ipairs(Chars(L[name])) do
			local r, g, bb = ColorAt(fi, (fi and fi.tint) and 0 or (k * 0.09))
			out[CuratorOctoFull.Length(out) + 1] = "|cff" .. Hex(0.3 + 0.7 * r, 0.3 + 0.7 * g, 0.3 + 0.7 * bb) .. ch .. "|r"
		end
		GameTooltip:AddDoubleLine((here and "> " or "   ") .. table.concat(out), L[MG.METALS[i]], 1, 1, 1, here and 1 or 0.62,
			here and 0.86 or 0.62, here and 0.5 or 0.66)
	end
	GameTooltip:Show()
end

-- The certificate of the copy chosen, shown beside the card (nil: none). reveal: written by the scene, line by line.
function MU:ShowCert(reveal)
	local d = A.detail
	local t = Target()
	if not (d and d:IsShown() and t) or (XU and XU.cer) or (RU and RU.cer) or (ns.SealUI and ns.SealUI.cer) then
		return nil
	end
	local info = MG.Read(t.rec, t.case)
	if not info then
		return nil
	end
	if RU then
		RU:HideQuote()
	end
	local v = BuildCert(d)
	info.cardName = NameOf(t.card)
	local parts = { L["Titanforged"] }
	if t.case then
		local CS = ns.Cases
		local coll = CS and CS.COLLECTION and CS.COLLECTION[t.card.case]
		if coll then
			parts[CuratorOctoFull.Length(parts) + 1] = L[coll]
		end
	else
		parts[CuratorOctoFull.Length(parts) + 1] = C:SeriesName(t.card.series)
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(("#%d/%d"), t.card.num or 0, CuratorOctoFull.Length((t.card.series and t.card.series.list or {})))
	end
	info.subText = table.concat(parts, "  ·  ")
	v:SetAlpha(1)
	v:Show()
	self:FillCert(v, info)
	self.cert = { card = t.card, id = t.id, case = t.case }
	-- what there is to know steps aside
	for _, p in ipairs(d.infoParts or {}) do
		p:SetAlpha(0)
	end
	GameTooltip:Hide()
	if not reveal then
		ns.Play(ns.SND.page)
	end
	return v
end

function MU:HideCert()
	local d = A.detail
	local v = d and d.certView
	local was = self.cert ~= nil or (v and v:IsShown())
	self.cert = nil
	if not v then
		return
	end
	v:Hide()
	v.famTyping = nil
	if was and not self.cer then
		for _, p in ipairs(d.infoParts or {}) do
			p:SetAlpha(1)
		end
	end
end

function MU:ToggleCert()
	local d = A.detail
	if d and d.certView and d.certView:IsShown() then
		return self:HideCert()
	end
	return self:ShowCert()
end

-------------------------------------------------------------------------------
-- (1 November, 9 h 22, his word: « quand on partage la carte dans le chat, qu'on voit le saphir etc ») The certificate of
-- a card shown by someone (a link of the chat, of a card of the albums or of a case): in a window of its own, beside
-- what shows the card (its window, UI/Links.lua; the window of the cases, UI/CaseView.lua).
-------------------------------------------------------------------------------
function MU:CertWindow()
	if self.win then
		return self.win
	end
	local v = NewCert(UIParent, 374, "CuratorCertificate")
	v:SetFrameStrata("FULLSCREEN_DIALOG")
	v:SetToplevel(true)
	v:SetClampedToScreen(true)
	v:SetMovable(true)
	v:RegisterForDrag("LeftButton")
	CuratorOctoFull.SetScript(v, "OnDragStart", v.StartMoving)
	CuratorOctoFull.SetScript(v, "OnDragStop", v.StopMovingOrSizing)
	v.onClose = function()
		MU:HideCertWindow()
	end
	v:Hide()
	if UISpecialFrames then
		tinsert(UISpecialFrames, "CuratorCertificate")
	end
	self.win = v
	return v
end

-- Shown, written (info: as MG.Read, its card's name and what it is with it), beside anchor (nil: right of the middle of
-- the screen).
function MU:ShowCertWindow(info, anchor)
	local v = self:CertWindow()
	v:ClearAllPoints()
	if type(anchor) == "table" and anchor.GetRight and anchor:GetRight() then
		v:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
	else
		v:SetPoint("LEFT", UIParent, "CENTER", 190, 0)
	end
	v.anchor = anchor
	v:SetAlpha(1)
	v:Show()
	if v.Raise then
		v:Raise()
	end
	self:FillCert(v, info)
	ns.Play(ns.SND.page)
	return v
end

-- Put away (anchor: only the one shown beside it).
function MU:HideCertWindow(anchor)
	local v = self.win
	if v and v:IsShown() and (anchor == nil or v.anchor == anchor) then
		v:Hide()
	end
end

-- (its name, what it is)
local function Named(info, name, parts)
	info.cardName = name or ""
	info.subText = table.concat(parts, "  ·  ")
	return info
end

-- A copy of a card of the albums shown in the chat: its card, its finish, its pattern, its certificate as it travels.
function MU:ShowCertOf(card, finish, pattern, tc, anchor)
	local x = type(tc) == "string" and MG.Unpack(tc)
	local pt = finish == "holo" and ns.Patterns and ns.Patterns.Number(pattern)
	local info = x and pt and card and MG.Info(pt)
	if not info then
		return nil
	end
	info.t, info.m = x.t, x.m
	info.by = MG.MasterName(x.m)
	info.no = MG.No(pt, x.t)
	return self:ShowCertWindow(Named(info, C:Name(card), { L["Titanforged"], C:SeriesName(card.series),
		string.format(("#%d/%d"), card.num or 0, CuratorOctoFull.Length((card.series and card.series.list or {}))) }), anchor)
end

-- A card of a case shown in the chat or in a showcase (its copy as the link tells it, UI/CaseShow.lua).
function MU:ShowCaseCertOf(w, anchor)
	local info = MG.Read(w, true)
	if not info then
		return nil
	end
	local CS = ns.Cases
	local desc = CD and CD.DescOf(w)
	local coll = CS and CS.COLLECTION and CS.COLLECTION[w.c]
	local parts = { L["Titanforged"] }
	if coll then
		parts[CuratorOctoFull.Length(parts) + 1] = L[coll]
	end
	return self:ShowCertWindow(Named(info, desc and CD.Name(desc) or "", parts), anchor or "case")
end

-- (away from a master: the button of its certificate, under the buttons of the panel, beside « Voir le devis »)
function MU:PaintCertButton()
	local d = A.detail
	if not d or not d.pin then
		return
	end
	local b = d.certAny
	local t = (not self.cer) and Target() or nil
	local want = t and not Shown() and MG.Read(t.rec, t.case) ~= nil
	if not want then
		if b then
			b:Hide()
		end
		return
	end
	if not b then
		b = Wide(S.Button(d, L["See the certificate"], 150, 22), 150)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			MU:ToggleCert()
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["The certificate of the mages"], MAGE_HI[1], MAGE_HI[2], MAGE_HI[3])
			GameTooltip:AddLine(L["All that a master of the mages read of this titanforged copy: its family, its number, its colours, its light, its foils, its metal."], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		d.certAny = b
		if d.infoParts then
			d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = b
		end
	end
	b:ClearAllPoints()
	if d.quoteAny and d.quoteAny:IsShown() then
		b:SetPoint("LEFT", d.quoteAny, "RIGHT", 8, 0)
	else
		b:SetPoint("TOPLEFT", d.pinNote or d.pin, "BOTTOMLEFT", d.pinNote and -2 or 0, -8)
	end
	CuratorOctoFull.SetShown(b, d.pin:IsShown())
end

-------------------------------------------------------------------------------
-- The scene
-------------------------------------------------------------------------------
-- The master's tools over the card: behind it, the runes of the mages turning and their light; over it, his light that
-- reads it, the rays of its colours, the sparks.
local function BuildScene(d)
	if d.mageFx then
		return
	end
	local c = d.card
	local W, H = c.W, c.H
	d.mageCircle = Tex(d, "StrikeRunes", "BORDER", 5, "ADD", MAGE)
	d.mageGlow = Tex(d, "Glow", "BORDER", 4, "ADD", ARCANE)
	local fx = CreateFrame("Frame", nil, d)
	fx:SetAllPoints()
	fx:SetFrameLevel(c:GetFrameLevel() + 16)
	fx:Hide()
	d.mageFx = fx
	fx.scan = Tex(fx, "ScanLine", "OVERLAY", 2, "ADD", MAGE_HI)
	CuratorOctoFull.SetSize(fx.scan, W * 1.25, 30)
	fx.scanGlow = Tex(fx, "Glow", "OVERLAY", 1, "ADD", MAGE)
	CuratorOctoFull.SetSize(fx.scanGlow, W * 1.3, 70)
	fx.prism = Tex(fx, "PrismRays", "OVERLAY", 0, "ADD")
	CuratorOctoFull.SetSize(fx.prism, W * 2.2, W * 2.2)
	fx.flash = Tex(fx, "Glow", "OVERLAY", -2, "ADD", ARCANE)
	CuratorOctoFull.SetSize(fx.flash, W * 2.3, H * 2)
	fx.sparks = ns.Particles:New(fx, 60)
	fx.motes = ns.Particles:New(fx, 40, "Twinkle")
	-- (a click skips it; the wheel does not bring the card closer)
	local b = CreateFrame("Button", nil, d)
	b:SetAllPoints()
	b:SetFrameLevel(c:GetFrameLevel() + 24)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		MU:Skip()
	end)
	b:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(b, "OnMouseWheel", function() end)
	b.hint = S.Text(b, "GameFontDisableSmall")
	if d.hint then
		b.hint:SetPoint("CENTER", d.hint, "CENTER", 0, 0)
	end
	b.hint:SetText(L["Click to skip"])
	b:Hide()
	d.mageCatch = b
end

-- A text written letter by letter (each letter in the colour of its pattern, as it comes).
function MU:TypeFamily(v, dur)
	local info = v.info
	local chars = Chars(L[info.name])
	v.famTyping = true
	v.fam:SetText("")
	local n = 0
	ns.Tween(dur, function(_, raw)
		local k = math.floor(raw * CuratorOctoFull.Length(chars) + 0.5)
		if k ~= n then
			n = k
			local out = {}
			for i = 1, k do
				local r, g, b = ColorAt(info, i * 0.06)
				out[CuratorOctoFull.Length(out) + 1] = "|cff" .. Hex(0.25 + 0.75 * r, 0.25 + 0.75 * g, 0.25 + 0.75 * b) .. chars[i] .. "|r"
			end
			v.fam:SetText(table.concat(out))
		end
	end, function()
		v.famTyping = nil
	end, Ease.linear, CER)
end

-- The pieces of the certificate the scene writes, hidden first (all: shown at once, the scene skipped).
local function Pieces(v)
	local list = { v.name, v.sub, v.famLabel, v.fam, v.num, v.rank, v.first, v.rule2, v.rule3, v.byLabel, v.by, v.when, v.no, v.seal,
		v.holo, v.close }
	for _, r in ipairs(v.rows) do
		list[CuratorOctoFull.Length(list) + 1] = r
	end
	return list
end

-- The scene begins (Mages.lua: MG:Certify done, res): the room darkens, the runes of the mages behind the card, the
-- certificate beside it; his light reads the card from top to bottom, twice, while its lines are written; its family
-- comes out in its colours, its number counts up; his seal comes down on it.
function MU:Begin(res)
	local d = A.detail
	if not (d and d:IsShown() and Showing(d, res.card)) then
		self:Told(res)
		return
	end
	HookAlbum()
	self:End(true)
	self:HideCert()
	if RU then
		RU:HideQuote()
	end
	ns.CancelOwner(FADE)
	BuildScene(d)
	local c = d.card
	local cer = { res = res, card = res.card, c = c, rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha() }
	self.cer = cer
	A.appraising = true
	cer.hold = { yaw = 0, pitch = 0 }
	if c.turn then
		c.turn.hold = cer.hold
		c.turn.zoomTo = c.slabInfo and (XU and XU.SLAB_ZOOM or 0.8) or 1
	end
	GameTooltip:Hide()
	d.mageCatch:Show()
	d.mageFx:Show()
	-- its certificate beside the card, to be written
	local v = self:ShowCert(true)
	if not v then
		self.cer = nil
		A.appraising = false
		d.mageCatch:Hide()
		d.mageFx:Hide()
		self:Told(res)
		return
	end
	cer.v = v
	for _, p in ipairs(Pieces(v)) do
		p:SetAlpha(0)
	end
	v.bandA = 0
	v.famTyping = true
	v.fam:SetText("")
	v:SetAlpha(0)
	ns.Play(ns.SND.open)
	ns.Tween(INTRO, function(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM + (DIM_SCENE - DIM) * e)
		d.spot:SetAlpha(SPOT + (SPOT_SCENE - SPOT) * e)
		d.rays:SetAlpha(cer.rays * (1 - 0.8 * e))
		d.rays2:SetAlpha(cer.rays2 * (1 - 0.8 * e))
		v:SetAlpha(e)
		v:ClearAllPoints()
		v:SetPoint("TOPLEFT", d, "TOPLEFT", v.x + 28 * (1 - e), v.y)
	end, nil, Ease.outQuad, CER)
	local t = INTRO
	ns.Delay(t, function()
		MU:Circle()
	end, CER)
	-- its card, its family, its number
	ns.Delay(t + 0.2, function()
		MU:Show(cer, { v.name, v.sub }, 0.35)
	end, CER)
	ns.Delay(t + 0.35, function()
		MU:Scan()
	end, CER)
	ns.Delay(t + 0.75, function()
		MU:Family()
	end, CER)
	ns.Delay(t + 1.35, function()
		MU:Count()
	end, CER)
	-- its lines, one after the other, as his light reads the card
	local rowsAt = t + 1.5
	for i, r in ipairs(v.rows) do
		local i, r = i, r; ns.Delay(rowsAt + (i - 1) * ROW, function()
			MU:Show(cer, { r }, 0.2)
			ns.Play(ns.SND.tick)
		end, CER)
	end
	local footAt = rowsAt + CuratorOctoFull.Length(v.rows) * ROW + 0.15
	ns.Delay(footAt, function()
		MU:Show(cer, { v.rule3, v.byLabel, v.by, v.when, v.no, v.holo }, 0.35)
	end, CER)
	ns.Delay(footAt + 0.45, function()
		MU:Stamp()
	end, CER)
	ns.Delay(footAt + 0.45 + HOLD, function()
		MU:End()
	end, CER)
end

-- Pieces of the certificate coming out.
function MU:Show(cer, list, dur)
	if self.cer ~= cer then
		return
	end
	ns.Tween(dur or 0.3, function(e)
		for _, p in ipairs(list) do
			p:SetAlpha(e)
		end
	end, nil, Ease.outQuad, CER)
end

-- The runes of the mages light behind the card, turning; the light of the arcane rising.
function MU:Circle()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local fx = d.mageFx
	local _, lamp = ns.Play(ns.SND.charge)
	cer.lamp = lamp
	-- (not the scene's own: stopped even when the scene is cut short)
	ns.Delay(LAMP, function()
		StopLamp(cer)
	end)
	local size = c.W * 2
	for _, t in ipairs({ d.mageCircle, d.mageGlow }) do
		On(d, t, 0, 0)
		CuratorOctoFull.SetSize(t, size, size)
		t:SetAlpha(0)
		t:Show()
	end
	CuratorOctoFull.SetSize(d.mageGlow, size * 1.25, size * 1.25)
	On(d, fx.flash, 0, 0)
	fx.flash:SetAlpha(0.6)
	fx.flash:Show()
	ns.Tween(0.6, function(_, raw)
		fx.flash:SetAlpha(0.6 * (1 - raw))
	end, function()
		fx.flash:Hide()
	end, Ease.outQuad, CER)
	ns.Tween(8, function(_, raw)
		CuratorOctoFull.SetRotation(d.mageCircle, -raw * 3.2)
		d.mageCircle:SetAlpha(math.min(0.8, raw * 8))
		d.mageGlow:SetAlpha(math.min(0.3, raw * 4))
	end, nil, Ease.linear, CER)
	local x, y = CardAt(d)
	fx.sparks:Burst(x, y, MAGE, 24, 220, 0.9, 14)
	for k = 0, 3 do
		ns.Delay(0.4 * k, function()
			fx.motes:Rise(x - 150, x + 150, y - 230, MAGE_HI, 5, 380, 2, 18)
		end, CER)
	end
end

-- His light reads the card, from top to bottom, twice; sparks where it goes.
function MU:Scan()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local c = d.card
	local fx = d.mageFx
	local H = c.H
	ns.Play(ns.SND.burst[2])
	fx.scan:Show()
	fx.scanGlow:Show()
	local x0, y0 = CardAt(d)
	local function Pass(k)
		ns.Tween(SWEEP, function(e)
			local y = H * 0.52 - H * 1.04 * e
			On(d, fx.scan, 0, y)
			On(d, fx.scanGlow, 0, y)
			local a = math.sin(e * math.pi)
			fx.scan:SetAlpha(0.95 * a)
			fx.scanGlow:SetAlpha(0.35 * a)
		end, function()
			if k == 2 then
				fx.scan:Hide()
				fx.scanGlow:Hide()
			end
		end, Ease.inOutQuad, CER)
		for j = 1, 4 do
			local j = j; ns.Delay(SWEEP * j / 5, function()
				fx.sparks:Burst(x0, y0 + H * 0.52 - H * 1.04 * j / 5, MAGE_HI, 4, 120, 0.5, 8)
			end, CER)
		end
	end
	Pass(1)
	ns.Delay(SWEEP + 0.1, function()
		Pass(2)
	end, CER)
end

-- Its family comes out: the rays of its colours over the card, its name written in them, its band lit.
function MU:Family()
	local cer, d = self.cer, A.detail
	if not cer then
		return
	end
	local v = cer.v
	local info = v.info
	local fx = d.mageFx
	ns.Play(ns.SND.holo)
	local r, g, b = MG.Color(info)
	fx.prism:SetVertexColor(0.5 + 0.5 * r, 0.5 + 0.5 * g, 0.5 + 0.5 * b)
	On(d, fx.prism, 0, 0)
	fx.prism:Show()
	ns.Tween(1.2, function(e, raw)
		fx.prism:SetAlpha(0.85 * math.sin(raw * math.pi))
		CuratorOctoFull.SetRotation(fx.prism, raw * 0.8)
	end, function()
		fx.prism:Hide()
	end, Ease.outQuad, CER)
	local x, y = CardAt(d)
	fx.sparks:Burst(x, y, { 0.5 + 0.5 * r, 0.5 + 0.5 * g, 0.5 + 0.5 * b }, 30, 260, 0.9, 16)
	self:Show(cer, { v.famLabel, v.fam }, 0.2)
	self:TypeFamily(v, 0.5)
	ns.Tween(0.6, function(e)
		v.bandA = e
	end, nil, Ease.outQuad, CER)
end

-- Its number counts up, from nothing to its own; its rank in its family.
function MU:Count()
	local cer = self.cer
	if not cer then
		return
	end
	local v = cer.v
	local info = v.info
	self:Show(cer, { v.num, v.rank, v.first, v.rule2 }, 0.25)
	local last = -1
	ns.Tween(0.8, function(_, raw)
		local n = math.max(1, math.floor(info.n * raw))
		if n ~= last then
			last = n
			v.num:SetText(string.format(L["Pattern No. %s"], ns.Num(n)) .. "  |cffa9a9b4" .. string.format(L["of %s"], ns.Num(info.max)) .. "|r")
		end
	end, function()
		v.num:SetText(string.format(L["Pattern No. %s"], ns.Num(info.n)) .. "  |cffa9a9b4" .. string.format(L["of %s"], ns.Num(info.max)) .. "|r")
		ns.Play(ns.SND.tick)
	end, Ease.outCubic, CER)
end

-- His seal comes down on the certificate: the wax pressed, a ring of the arcane.
function MU:Stamp()
	local cer = self.cer
	if not cer then
		return
	end
	local v = cer.v
	ns.Play(ns.SND.stamp)
	ns.Play(ns.SND.burst[3])
	v.seal:SetAlpha(0)
	ns.Tween(0.32, function(e)
		CuratorOctoFull.SetSize(v.seal, 70 * (2.1 - 1.1 * e), 70 * (2.1 - 1.1 * e))
		v.seal:SetAlpha(e)
	end, function()
		CuratorOctoFull.SetSize(v.seal, 70, 70)
		v.sealRing:SetAlpha(1)
		ns.Tween(0.6, function(e)
			CuratorOctoFull.SetSize(v.sealRing, 86 + 60 * e, 86 + 60 * e)
			v.sealRing:SetAlpha(1 - e)
		end, function()
			CuratorOctoFull.SetSize(v.sealRing, 86, 86)
			v.sealRing:SetAlpha(0)
		end, Ease.outQuad, CER)
	end, Ease.inQuad, CER)
	self:Show(cer, { v.close }, 0.3)
end

-- A click during it: at once to the end.
function MU:Skip()
	if not self.cer then
		return
	end
	ns.Play(ns.SND.stamp)
	self:End()
end

-- What the chat says of a copy certified.
function MU:Told(res)
	local info = res.info
	if not info then
		return
	end
	ns.Print(L["%s certified %s: %s, pattern %s of %s."], res.by or L["A master of the mages"], NameOf(res.card), L[info.name],
		ns.Num(info.n), ns.Num(info.max))
end

-- It ends: the scene put away, the room as it was, its certificate left written beside the card (quick: at once, the
-- detail closing or another card shown), said in the chat.
function MU:End(quick)
	local cer = self.cer
	if not cer then
		return
	end
	self.cer = nil
	A.appraising = false
	ns.CancelOwner(CER)
	StopLamp(cer)
	local d = A.detail
	local c = cer.c or d.card
	local fx = d.mageFx
	for _, t in ipairs({ fx.scan, fx.scanGlow, fx.prism, fx.flash }) do
		t:Hide()
	end
	fx.sparks:Clear()
	if quick then
		fx.motes:Clear()
	end
	d.mageCatch:Hide()
	if c.turn and c.turn.hold == cer.hold then
		c.turn.hold = nil
	end
	-- (its certificate whole)
	local v = cer.v
	if v then
		for _, p in ipairs(Pieces(v)) do
			p:SetAlpha(1)
		end
		v.bandA = 1
		v.famTyping = nil
		CuratorOctoFull.SetSize(v.seal, 70, 70)
		v.sealRing:SetAlpha(0)
		v:SetAlpha(1)
		v:ClearAllPoints()
		v:SetPoint("TOPLEFT", d, "TOPLEFT", v.x, v.y)
	end
	local here = d:IsShown() and Showing(d, cer.card)
	if here then
		Repaint(d, cer.card)
	end
	local from = { spot = d.spot:GetAlpha(), rays = d.rays:GetAlpha(), rays2 = d.rays2:GetAlpha(), circle = d.mageCircle:GetAlpha(),
		glow = d.mageGlow:GetAlpha() }
	local function Room(e)
		CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, DIM_SCENE + (DIM - DIM_SCENE) * e)
		d.spot:SetAlpha(from.spot + (SPOT - from.spot) * e)
		d.rays:SetAlpha(from.rays + (cer.rays - from.rays) * e)
		d.rays2:SetAlpha(from.rays2 + (cer.rays2 - from.rays2) * e)
		d.mageCircle:SetAlpha(from.circle * (1 - e))
		d.mageGlow:SetAlpha(from.glow * (1 - e))
	end
	local function Away()
		fx:Hide()
		d.mageCircle:Hide()
		d.mageGlow:Hide()
		CuratorOctoFull.SetRotation(d.mageCircle, 0)
	end
	if quick or not here then
		Room(1)
		Away()
		-- (the detail closing, or another card: its certificate with the scene)
		self:HideCert()
	else
		ns.Tween(0.5, Room, Away, Ease.outQuad, FADE)
		-- (its certificate stays to be read: what there is to know stays aside until it is closed)
		for _, p in ipairs(d.infoParts or {}) do
			p:SetAlpha(0)
		end
	end
	self:Told(cer.res)
	self:Paint()
end

-------------------------------------------------------------------------------
-- In the window of dialogue of a master: the album on the titanforged cards (1 November, his word: the inventory on its
-- forged copies, MU:Titans)
-------------------------------------------------------------------------------
-- The album of a titanforged copy of mine (one without its certificate first), on its titanforged cards; else the
-- collection of a case that has one. True: one found.
function MU:OpenTitans()
	local CP = ns.Copies
	local best, bestWaits
	for _, s in ipairs(ns.Series or {}) do
		for _, card in ipairs(s.list or {}) do
			for _, r in ipairs(CP and C:Owned(card) and CP:List(card.key) or {}) do
				if CP.Pattern(r) then
					local waits = MG.Of(r) == nil
					if not best or (waits and not bestWaits) then
						best, bestWaits = s, waits
					end
				end
			end
			if bestWaits then
				break
			end
		end
		if bestWaits then
			break
		end
	end
	if best then
		A:Open("mine", best)
		if A.SetFinish and A.finish ~= "holo" then
			A:SetFinish("holo")
		end
		return true
	end
	local CS = ns.Cases
	for _, w in ipairs(CS and CS.Won and CS:Won() or {}) do
		if CS.Pattern(w) then
			if A.ShowCases then
				A:ShowCases(w.c)
				if A.caseFin ~= "titan" and A.SetCaseFin then
					A:SetCaseFin("titan")
				end
			end
			return true
		end
	end
	return false
end

-- (1 November, his word: « quand on clique sur Faire certifier une carte titanforged que ça affiche l'inventaire dans
-- Forgés ») The inventory on its forged copies (UI/Inventory.lua; the cards of the cases with them). True: a titanforged
-- copy among them, or a titanforged card of a case.
function MU:Titans()
	local CP, CS = ns.Copies, ns.Cases
	local any = false
	for _, x in ipairs(CP and CP.All and CP:All() or {}) do
		if CP.Pattern(x.rec) then
			any = true
			break
		end
	end
	if not any then
		for _, w in ipairs(CS and CS.Won and CS:Won() or {}) do
			if CS.Pattern(w) then
				any = true
				break
			end
		end
	end
	local IU = ns.InventoryUI
	if IU and IU.Open then
		if IU.sell and IU.EndSell then
			IU:EndSell(true)
		end
		IU:Open("forged")
	else
		any = self:OpenTitans() and any
	end
	return any
end

ns.Gossip:Provide("mage", function()
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return {}
	end
	return { {
		text = L["Certify a titanforged card"],
		icon = ICON,
		click = function()
			local any = MU:Titans()
			ns.Gossip:Say(any and L["Show me your titanforged card. Each of its foils, each turn of its light has something to say, and I will write it all down."]
				or L["You carry no titanforged card. Come back when the titans have smiled on you."])
		end,
	} }
end)

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
function MU:BuildDetail(d)
	if d.mage or not d.appr then
		return
	end
	BuildBlock(d)
	-- (the block steps aside with what there is to know, during an appraisal, a rite, a view)
	if d.infoParts then
		d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = d.mage
	end
	d:HookScript("OnHide", function()
		MU:End(true)
		MU:HideCert()
	end)
end

do
	local buildDetail = A.BuildDetail
	function A:BuildDetail(...)
		local r = buildDetail(self, unpack(arg, 1, arg.n))
		if self.detail then
			MU:BuildDetail(self.detail)
		end
		return r
	end

	local showDetail = A.ShowDetail
	function A:ShowDetail(...)
		MU:End(true)
		MU:HideCert()
		local d = self.detail
		if d and d.mage then
			d.mage.button.armed = nil
		end
		return showDetail(self, unpack(arg, 1, arg.n))
	end

	local hideDetail = A.HideDetail
	function A:HideDetail(...)
		MU:End(true)
		MU:HideCert()
		return hideDetail(self, unpack(arg, 1, arg.n))
	end

	-- (the block of the expert, and of the masters: at a master of the mages, the block of the certificate in its
	-- place for a titanforged copy)
	local paintAppraise = A.PaintAppraise
	function A:PaintAppraise(...)
		local r = paintAppraise(self, unpack(arg, 1, arg.n))
		MU:Paint()
		return r
	end
end

-- (a card of a case shown big: the same, UI/CaseDetail.lua)
if CD then
	local paintAppraise = CD.PaintAppraise
	function CD:PaintAppraise(d, ...)
		local r = paintAppraise(self, d, unpack(arg, 1, arg.n))
		MU:Paint()
		return r
	end
	local select = CD.Select
	function CD:Select(d, id, ...)
		MU:HideCert()
		local dd = A.detail
		if dd and dd.mage then
			dd.mage.button.armed = nil
		end
		return CuratorOctoFull.Select(self, d, id, unpack(arg, 1, arg.n))
	end
end
if A.ShowCaseDetail then
	local show = A.ShowCaseDetail
	function A:ShowCaseDetail(...)
		MU:End(true)
		MU:HideCert()
		local d = self.detail
		if d and d.mage then
			d.mage.button.armed = nil
		end
		return show(self, unpack(arg, 1, arg.n))
	end
end

-- (the window of the cases: the card looked at put down, its certificate with it, UI/CaseView.lua)
do
	local CRU = ns.CrateUI
	if CRU and CRU.CloseInspect then
		local close = CRU.CloseInspect
		function CRU:CloseInspect(...)
			MU:HideCertWindow("case")
			return close(self, unpack(arg, 1, arg.n))
		end
	end
end

-- (the button of its certificate wherever the button of its quote is painted; its quote shown: its certificate put away)
if RU then
	local paintQuote = RU.PaintQuoteButton
	function RU:PaintQuoteButton(...)
		local r = paintQuote(self, unpack(arg, 1, arg.n))
		MU:PaintCertButton()
		return r
	end
	local showQuote = RU.ShowQuote
	function RU:ShowQuote(...)
		if MU.cer then
			return nil
		end
		MU:HideCert()
		return showQuote(self, unpack(arg, 1, arg.n))
	end
end

local function Again()
	local d = A.detail
	if not (d and d:IsShown()) or MU.cer or MU.busy or (XU and XU.cer) or (RU and RU.cer) then
		return
	end
	if d.caseShown and CD then
		CD:PaintAppraise(d)
	else
		A:PaintAppraise()
	end
end

-- (a master talked to, or left: the block of the card shown)
ns.On("MASTER_CHANGED", Again)
ns.On("RUBIES_CHANGED", function()
	if not MU.cer and not MU.busy then
		MU:Paint()
	end
end)
ns.On("COPY_SELECTED", function()
	local d = A.detail
	if d and d.mage then
		d.mage.button.armed = nil
	end
	MU:HideCert()
end)
