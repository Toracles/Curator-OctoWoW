local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

-- The alerts of the game, at the top of the screen: a card or a booster comes as the loot of the
-- game comes (its toast), an achievement as the achievements of the game come (their banner). One
-- at a time, the next ones wait their turn.
local T = { queue = {} }
ns.Toast = T

local HOLD = 4.05      -- as the game's alerts: shown, then a slow fade
local FADE = 1.5
local LOOT_W, LOOT_H = 276, 96
local ACH_W, ACH_H = 300, 101
-- an achievement of mine: its medallion over the band, rays behind it, its points
local TROPHY_W, TROPHY_H = 520, 150
local BAND_X, BAND_H = 64, 92
-- the ribbon of a new title, by the rank of the title
local TITLE_BANNER = { "Rank", "Rank", "Epic", "Epic", "Legendary", "Mythic", "Thunder", "Titan" }

-- The square of a pack's art that stands for its album (the place, its emblem).
local PACK_CROP = { 30 / 256, 226 / 256, 110 / 512, 306 / 512 }

local function Fit(fs, text, width, size, minSize)
	ns.SetFont(fs, size)
	fs:SetText(text)
	while size > minSize and ns.TextWidth(fs) > width do
		size = size - 0.5
		ns.SetFont(fs, size)
	end
end

-- The toast of the loot: its parchment, an item (here a card or the album of a booster), a label
-- and a name.
local function BuildLoot(f)
	local l = CreateFrame("Frame", nil, f)
	l:SetAllPoints()
	l.bg = l:CreateTexture(nil, "BACKGROUND")
	l.bg:SetTexture("Interface\\LootFrame\\LootToast")
	l.bg:SetTexCoord(0.28222656, 0.55175781, 0.578125, 0.953125)
	CuratorOctoFull.SetSize(l.bg, LOOT_W, LOOT_H)
	l.bg:SetPoint("CENTER")
	-- the item: the album of a booster, in the border of its quality
	l.icon = l:CreateTexture(nil, "BORDER")
	CuratorOctoFull.SetSize(l.icon, 52, 52)
	l.icon:SetPoint("TOPLEFT", 22, -23)
	l.border = l:CreateTexture(nil, "ARTWORK", nil, 1)
	if not S.Atlas(l.border, "loottoast-itemborder-gold", true) then
		l.border:SetTexture("Interface\\Common\\WhiteIconFrame")
		CuratorOctoFull.SetSize(l.border, 52, 52)
	end
	l.border:SetPoint("CENTER", l.icon, "CENTER")
	-- or a small card
	local card = ns.NewCard(l, "small")
	card:SetScale(0.4)
	card:SetPoint("CENTER", l, "TOPLEFT", 48 / 0.4, -49 / 0.4)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.5)
	l.card = card
	-- the texts keep to the toast: made smaller first, then cut by the client; the last line may
	-- take two lines
	l.textW = 170
	l.label = S.Text(l, "GameFontNormal", "LEFT")
	l.label:SetPoint("TOPLEFT", 81, -23)
	-- (over the box of the name: it may go a little further right)
	l.labelW = l.textW + 8
	l.label:SetWidth(l.labelW)
	CuratorOctoFull.SetWordWrap(l.label, false)
	l.name = S.Text(l, "GameFontNormalMed3", "LEFT")
	l.name:SetPoint("TOPLEFT", 84, -41)
	l.name:SetWidth(l.textW)
	CuratorOctoFull.SetWordWrap(l.name, false)
	l.line = S.Text(l, "GameFontHighlightSmall", "LEFT")
	l.line:SetPoint("TOPLEFT", l.name, "BOTTOMLEFT", 0, -3)
	l.line:SetWidth(l.textW)
	CuratorOctoFull.SetWordWrap(l.line, true)
	CuratorOctoFull.SetMaxLines(l.line, 2)
	l.line:SetTextColor(0.8, 0.8, 0.8)
	-- the glow and the light that crosses it as it comes
	l.glow = l:CreateTexture(nil, "OVERLAY")
	if not S.Atlas(l.glow, "loottoast-glow") then
		CuratorOctoFull.ColorTexture(l.glow, 1, 0.9, 0.6, 0.25)
	end
	CuratorOctoFull.SetSize(l.glow, 286, 109)
	l.glow:SetPoint("CENTER")
	l.glow:SetBlendMode("ADD")
	l.glow:SetAlpha(0)
	l.shine = l:CreateTexture(nil, "OVERLAY", nil, 1)
	l.shine:SetTexture("Interface\\LootFrame\\LootToast")
	l.shine:SetTexCoord(0.56347656, 0.73046875, 0.57421875, 0.8671875)
	l.shine:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(l.shine, 171, 75)
	l.shine:SetAlpha(0)
	return l
end

-- The banner of the achievements: its banner line, the icon in its frame, the points on the shield.
local function BuildAch(f)
	local a = CreateFrame("Frame", nil, f)
	a:SetAllPoints()
	a.bg = a:CreateTexture(nil, "BACKGROUND")
	if not S.Atlas(a.bg, "ui-achievement-alert-background", true) then
		a.bg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
		a.bg:SetTexCoord(0, 0.605, 0, 0.703)
		CuratorOctoFull.SetSize(a.bg, ACH_W, ACH_H)
	end
	a.bg:SetPoint("CENTER")
	a.unlocked = S.Text(a, "GameFontBlackTiny")
	a.unlocked:SetPoint("TOP", 7, -23)
	CuratorOctoFull.SetSize(a.unlocked, 200, 12)
	a.name = S.Text(a, "GameFontHighlight")
	a.name:SetPoint("TOP", a.unlocked, "BOTTOM", 0, 0)
	CuratorOctoFull.SetSize(a.name, 155, 36)
	CuratorOctoFull.SetWordWrap(a.name, true)
	-- the icon (dark under the icons that are not square)
	a.iconBg = a:CreateTexture(nil, "ARTWORK", nil, -1)
	CuratorOctoFull.ColorTexture(a.iconBg, 0.02, 0.03, 0.06, 1)
	CuratorOctoFull.SetSize(a.iconBg, 52, 52)
	a.iconBg:SetPoint("CENTER", a, "TOPLEFT", 35, -52)
	a.icon = a:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(a.icon, 52, 52)
	a.icon:SetPoint("CENTER", a.iconBg, "CENTER")
	a.frame = a:CreateTexture(nil, "OVERLAY")
	if not S.Atlas(a.frame, "ui-achievement-iconframe", true) then
		a.frame:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
		a.frame:SetTexCoord(0, 0.5625, 0, 0.5625)
		CuratorOctoFull.SetSize(a.frame, 72, 72)
	end
	a.frame:SetPoint("CENTER", a.iconBg, "CENTER", -1, 2)
	a.shield = a:CreateTexture(nil, "ARTWORK")
	if not S.Atlas(a.shield, "ui-achievement-shield-1", true) then
		a.shield:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Shields")
		a.shield:SetTexCoord(0, 0.5, 0, 0.5)
		CuratorOctoFull.SetSize(a.shield, 64, 64)
	end
	a.shield:SetPoint("TOPRIGHT", -7, -21)
	a.points = S.Text(a, "GameFontNormal")
	a.points:SetPoint("CENTER", a.shield, "CENTER", 3, 3)
	a.glow = a:CreateTexture(nil, "OVERLAY", nil, 1)
	if not S.Atlas(a.glow, "ui-achievement-alert-glow-glow", true) then
		CuratorOctoFull.ColorTexture(a.glow, 1, 0.9, 0.6, 0.25)
		CuratorOctoFull.SetSize(a.glow, 400, 171)
	end
	a.glow:SetPoint("CENTER")
	a.glow:SetBlendMode("ADD")
	a.glow:SetAlpha(0)
	a.shine = a:CreateTexture(nil, "OVERLAY", nil, 2)
	if not S.Atlas(a.shine, "ui-achievement-alert-glow-shine", true) then
		CuratorOctoFull.ColorTexture(a.shine, 1, 1, 1, 0.3)
		CuratorOctoFull.SetSize(a.shine, 67, 85)
	end
	a.shine:SetBlendMode("ADD")
	a.shine:SetAlpha(0)
	return a
end

-- An achievement earned: its medallion of gold (its icon inside, rays of gold turning behind it), a band
-- with its name and what it asked, its points on a medal of gold flying to the count of all of them; a
-- new title on its ribbon.
local function BuildTrophy(f)
	local Hud = ns.Hud
	local t = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(t, TROPHY_W, TROPHY_H)
	t:SetPoint("CENTER")
	t.rays = t:CreateTexture(nil, "BACKGROUND")
	t.rays:SetTexture(MEDIA .. "Rays")
	t.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(t.rays, 300, 300)
	t.rays:SetPoint("CENTER", t, "LEFT", 70, 4)
	t.rays:SetVertexColor(1, 0.8, 0.35)
	t.glow = t:CreateTexture(nil, "BACKGROUND", nil, 1)
	t.glow:SetTexture(MEDIA .. "Glow")
	t.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(t.glow, 220, 220)
	t.glow:SetPoint("CENTER", t, "LEFT", 70, 4)
	t.glow:SetVertexColor(1, 0.8, 0.4)
	-- the band (it unrolls from the medallion)
	local band = CreateFrame("Frame", nil, t)
	band:SetPoint("LEFT", t, "LEFT", BAND_X, 0)
	CuratorOctoFull.SetSize(band, TROPHY_W - BAND_X, BAND_H)
	if band.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(band, true)
	end
	t.band = band
	local inner = CreateFrame("Frame", nil, band)
	inner:SetPoint("TOPLEFT")
	CuratorOctoFull.SetSize(inner, TROPHY_W - BAND_X, BAND_H)
	inner.bg = Hud.Sliced(inner, "TrophyBanner", BAND_H, 0, "BACKGROUND")
	t.inner = inner
	t.label = Hud.Text(inner, 11, "OUTLINE")
	t.label:SetPoint("TOPLEFT", 64, -16)
	t.label:SetTextColor(1, 0.82, 0.38)
	t.label:SetJustifyH("LEFT")
	t.name = Hud.Text(inner, 17, "")
	t.name:SetPoint("TOPLEFT", t.label, "BOTTOMLEFT", 0, -5)
	t.name:SetJustifyH("LEFT")
	t.name:SetTextColor(1, 0.97, 0.88)
	CuratorOctoFull.SetWordWrap(t.name, false)
	t.desc = Hud.Text(inner, 10, "")
	t.desc:SetPoint("TOPLEFT", t.name, "BOTTOMLEFT", 0, -5)
	t.desc:SetJustifyH("LEFT")
	t.desc:SetTextColor(0.78, 0.76, 0.84)
	CuratorOctoFull.SetWordWrap(t.desc, false)
	-- its points on a medal of gold; the count of all of them under it
	t.pts = inner:CreateTexture(nil, "ARTWORK")
	t.pts:SetTexture(MEDIA .. "TierMedal")
	t.pts:SetVertexColor(1, 0.8, 0.32)
	CuratorOctoFull.SetSize(t.pts, 46, 46)
	t.pts:SetPoint("CENTER", inner, "RIGHT", -42, 8)
	t.ptsText = Hud.Text(inner, 13, "OUTLINE", "OVERLAY", 2)
	t.ptsText:SetPoint("CENTER", t.pts, "CENTER", 0, -2)
	t.total = Hud.Text(inner, 9, "OUTLINE")
	t.total:SetPoint("TOP", t.pts, "BOTTOM", 0, 1)
	t.total:SetTextColor(0.85, 0.82, 0.9)
	t.fly = Hud.Text(t, 15, "OUTLINE", "OVERLAY", 4)
	t.fly:SetTextColor(1, 0.86, 0.4)
	t.fly:SetAlpha(0)
	-- the light that passes over the band
	t.shine = inner:CreateTexture(nil, "OVERLAY", nil, 3)
	t.shine:SetTexture(MEDIA .. "Sheen")
	t.shine:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(t.shine, 160, 160)
	t.shine:SetAlpha(0)
	-- the medallion and its icon
	local m = CreateFrame("Frame", nil, t)
	CuratorOctoFull.SetSize(m, 116, 116)
	m:SetPoint("CENTER", t, "LEFT", 70, 4)
	m:SetFrameLevel(band:GetFrameLevel() + 6)
	t.medal = m
	m.iconBg = m:CreateTexture(nil, "ARTWORK", nil, -1)
	m.iconBg:SetTexture(MEDIA .. "CircleMask")
	m.iconBg:SetVertexColor(0.02, 0.02, 0.05)
	CuratorOctoFull.SetSize(m.iconBg, 66, 66)
	m.iconBg:SetPoint("CENTER", 0, -1)
	m.icon = Hud.RoundIcon(m, 62)
	m.icon:SetPoint("CENTER", 0, -1)
	m.tex = m:CreateTexture(nil, "OVERLAY")
	m.tex:SetTexture(MEDIA .. "AchMedal")
	m.tex:SetAllPoints()
	m.ring = m:CreateTexture(nil, "OVERLAY", nil, 2)
	m.ring:SetTexture(MEDIA .. "Ring")
	m.ring:SetBlendMode("ADD")
	m.ring:SetPoint("CENTER")
	m.ring:SetVertexColor(1, 0.86, 0.5)
	m.ring:SetAlpha(0)
	-- a new title: its ribbon under the band
	local rb = CreateFrame("Frame", nil, t)
	CuratorOctoFull.SetSize(rb, 340, 60)
	rb:SetPoint("TOP", t, "BOTTOM", 30, 26)
	rb:SetFrameLevel(band:GetFrameLevel() + 4)
	rb.tex = rb:CreateTexture(nil, "ARTWORK")
	rb.tex:SetAllPoints()
	rb.text = Hud.Text(rb, 13, "OUTLINE")
	rb.text:SetPoint("CENTER", 0, 1)
	rb:Hide()
	t.ribbon = rb
	t.sparks = ns.Particles:New(t, 40, "Spark")
	t.stars = ns.Particles:New(t, 20, "Twinkle")
	t:Hide()
	return t
end

function T:Build()
	if self.frame then
		return
	end
	local f = CreateFrame("Button", "CuratorToast", UIParent)
	CuratorOctoFull.SetSize(f, ACH_W, ACH_H)
	-- (1.14.3, the players' word: where the player moved them, UI/Live.lua: V:Mover)
	local x, y = 0, -110
	if ns.Live and ns.Live.AlertsAt then
		x, y = ns.Live:AlertsAt()
	end
	f:SetPoint("TOP", UIParent, "TOP", x, y)
	-- above the booster scene too: an achievement shows on the screen of the cards revealed
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(200)
	f:Hide()
	f.loot = BuildLoot(f)
	f.ach = BuildAch(f)
	f.trophy = BuildTrophy(f)
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(f, "OnClick", function(_, button)
		local item = T.current
		T:Next(true)
		if button == "LeftButton" and item and item.onClick then
			item.onClick()
		end
	end)
	-- as the game's alerts: the mouse over it keeps it shown (1.13.0, after its third test: a reminder to save, its left
	-- click through a macro of the game, which alone still reloads the interface: UI/Save.lua)
	CuratorOctoFull.SetScript(f, "OnEnter", function()
		T.paused = true
		local SV = ns.Save
		if SV and SV.Cover and T.current and T.current.save then
			SV:Cover(f, SV.TOAST)
		end
	end)
	CuratorOctoFull.SetScript(f, "OnLeave", function()
		T.paused = false
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		T.t = (T.t or 0) + elapsed
		local card = f.loot.card
		if card:IsShown() then
			card:Tick(T.t)
		end
		if f.trophy:IsShown() then
			CuratorOctoFull.SetRotation(f.trophy.rays, T.t * 0.35)
		end
		T:Step(elapsed)
	end)
	self.frame = f
end

-- The alerts wait for the end of the entrance of a card, and of the screens of an album complete and
-- of a level.
function T:Waits()
	return (ns.Cinematic and ns.Cinematic:IsPlaying()) or (ns.Complete and ns.Complete:Showing())
		or (ns.LevelUp and ns.LevelUp:Showing()) or false
end

-- item: { title, name, color, line, card, finish, pack, icon, points, sound, onClick, hold }
-- (while a scene of its own is on the screen, the alerts wait for its end: see Resume)
function T:Push(item)
	CuratorOctoFull.Insert(self.queue, item)
	if not self.current and not self:Waits() then
		self:Next()
	end
end

-- The scene is over: the alerts that waited come.
function T:Resume()
	if not self.current and CuratorOctoFull.Length(self.queue) > 0 and not self:Waits() then
		self:Next()
	end
end

-- A screen comes over everything (an album complete, a level): the alert shown waits with the others,
-- to come again from its start once it is gone (see Resume).
function T:Hold()
	local item = self.current
	if not (self.frame and item) then
		return
	end
	ns.CancelOwner(self)
	CuratorOctoFull.Insert(self.queue, 1, item)
	self.current, self.state, self.paused = nil, nil, false
	self.frame:Hide()
end

-- The loot toast of an item: its label, its name (in the colour of its quality) and its line.
function T:ShowLoot(item)
	local f = self.frame
	local l = f.loot
	CuratorOctoFull.SetSize(f, LOOT_W, LOOT_H)
	l:Show()
	f.ach:Hide()
	f.trophy:Hide()
	Fit(l.label, item.title or "", l.labelW, 12, 8)
	Fit(l.name, item.name or "", l.textW, 14, 10)
	local c = item.color or { 1, 1, 1 }
	l.name:SetTextColor(c[1], c[2], c[3])
	-- on one line when it fits there at a smaller size, else on two, the texts above a little
	-- higher to make room
	Fit(l.line, item.line or "", l.textW, 10, 8.5)
	local two = ns.TextWidth(l.line) > l.textW
	if two then
		Fit(l.line, item.line or "", l.textW * 2 - 24, 10, 8.5)
	end
	l.label:SetPoint("TOPLEFT", 81, two and -19 or -23)
	l.name:SetPoint("TOPLEFT", 84, two and -35 or -41)
	l.line:SetPoint("TOPLEFT", l.name, "BOTTOMLEFT", 0, two and -2 or -3)
	if item.card then
		l.icon:Hide()
		l.border:Hide()
		l.card:Show()
		l.card:SetCard(item.card, { owned = true, finish = item.finish, corrupt = item.corrupt, pattern = item.pt, wear = item.wear })
		l.card:ShowSide("front")
	else
		l.card:Hide()
		l.icon:Show()
		l.border:Show()
		if item.tex then
			-- an icon (a quest)
			ns.SetIcon(l.icon, item.tex)
		else
			l.icon:SetTexture(MEDIA .. (item.pack or "PackElwynn") .. "Bottom")
			l.icon:SetTexCoord(PACK_CROP[1], PACK_CROP[2], PACK_CROP[3], PACK_CROP[4])
			l.icon:SetVertexColor(1, 1, 1)
		end
		CuratorOctoFull.SetDesaturated(l.icon, item.dim and true or false)
	end
	return l
end

-- The banner of an achievement: "Achievement earned", its name, its icon, its points.
function T:ShowAch(item)
	local f = self.frame
	local a = f.ach
	CuratorOctoFull.SetSize(f, ACH_W, ACH_H)
	a:Show()
	f.loot:Hide()
	f.loot.card:Hide()
	f.trophy:Hide()
	Fit(a.unlocked, item.title or "", 200, 9, 7)
	a.unlocked:SetTextColor(0, 0, 0)
	S.SetFontObject(a.name, "GameFontHighlight")
	a.name:SetText(item.name or "")
	ns.SetIcon(a.icon, item.icon)
	a.points:SetText(item.points and tostring(item.points) or "")
	CuratorOctoFull.SetShown(a.shield, item.points ~= nil)
	return a
end

-- An achievement of mine: its medallion, its band, its points (item.before, item.after: the points of
-- all of them before and after it; item.title2: a new title, item.rank2 its rank).
function T:ShowTrophy(item)
	local f = self.frame
	local t = f.trophy
	CuratorOctoFull.SetSize(f, TROPHY_W, TROPHY_H)
	t:Show()
	f.loot:Hide()
	f.loot.card:Hide()
	f.ach:Hide()
	t.sparks:Clear()
	t.stars:Clear()
	t.label:SetText(item.title or "")
	t.name:SetText(item.name or "")
	Fit(t.name, item.name or "", TROPHY_W - BAND_X - 64 - 90, 17, 11)
	t.desc:SetText(item.line or "")
	Fit(t.desc, item.line or "", TROPHY_W - BAND_X - 64 - 90, 10, 8)
	ns.Hud.SetIcon(t.medal.icon, item.icon)
	t.ptsText:SetText("+" .. (item.points or 0))
	t.total:SetText(string.format(L["%d points"], item.before or 0))
	t.fly:SetAlpha(0)
	t.ribbon:Hide()
	return t
end

-- The medallion comes down in a flash, the band unrolls from it, the points fly to their count, a new
-- title comes on its ribbon.
function T:PlayTrophy(item)
	local f = self.frame
	local t = f.trophy
	local m = t.medal
	local full = TROPHY_W - BAND_X
	t.band:SetWidth(1)
	t.rays:SetAlpha(0)
	t.glow:SetAlpha(0)
	for _, x in ipairs({ t.label, t.name, t.desc, t.pts, t.ptsText, t.total }) do
		x:SetAlpha(0)
	end
	ns.Tween(0.34, function(e, raw)
		local k = 2.2 - 1.2 * e
		m:SetScale(k)
		m:ClearAllPoints()
		m:SetPoint("CENTER", t, "LEFT", 70 / k, 4 / k)
		m:SetAlpha(math.min(1, raw * 3))
	end, function()
		m:SetScale(1)
		m:ClearAllPoints()
		m:SetPoint("CENTER", t, "LEFT", 70, 4)
		t.sparks:Burst(70 - TROPHY_W / 2, 4, { 1, 0.86, 0.45 }, 22, 220, 0.7, 16)
		t.stars:Burst(70 - TROPHY_W / 2, 4, { 1, 0.9, 0.6 }, 8, 160, 0.9, 20)
		ns.Tween(0.6, function(e, raw)
			local k = 60 + 200 * e
			CuratorOctoFull.SetSize(m.ring, k, k)
			m.ring:SetAlpha((1 - raw) * 0.9)
		end, nil, Ease.outCubic, T)
	end, Ease.inQuad, self)
	ns.Tween(0.5, function(e)
		t.rays:SetAlpha(0.55 * e)
		t.glow:SetAlpha(0.6 * e)
	end, nil, Ease.outQuad, self, 0.25)
	-- the band unrolls
	ns.Tween(0.4, function(e)
		t.band:SetWidth(math.max(1, full * e))
	end, nil, Ease.outCubic, self, 0.3)
	for k, x in ipairs({ t.label, t.name, t.desc, t.pts, t.ptsText, t.total }) do
		local k, x = k, x; ns.Tween(0.3, function(e)
			x:SetAlpha(e)
		end, nil, Ease.outQuad, self, 0.45 + 0.05 * k)
	end
	-- a light passes over the band
	ns.Tween(0.9, function(_, raw)
		t.shine:ClearAllPoints()
		t.shine:SetPoint("CENTER", t.inner, "LEFT", -60 + (full + 120) * raw, 0)
		t.shine:SetAlpha(math.sin(math.pi * raw) * 0.6)
	end, nil, Ease.inOutQuad, self, 0.7)
	-- the points fly to the count of all of them, which climbs
	local before, after = item.before or 0, item.after or 0
	ns.Delay(1.05, function()
		t.fly:SetText("+" .. (item.points or 0))
		local x0, y0 = TROPHY_W / 2 - 42, 8
		ns.Tween(0.45, function(e, raw)
			t.fly:ClearAllPoints()
			t.fly:SetPoint("CENTER", t, "CENTER", x0, y0 + 10 * math.sin(math.pi * raw) - 22 * e)
			t.fly:SetAlpha(raw < 0.8 and 1 or (1 - raw) / 0.2)
		end, function()
			t.fly:SetAlpha(0)
			ns.Play(ns.SND.coins)
			ns.Tween(0.45, function(e)
				t.total:SetText(string.format(L["%d points"], math.floor(before + (after - before) * e + 0.5)))
			end, nil, Ease.outCubic, T)
			t.sparks:Burst(x0, y0 - 24, { 1, 0.86, 0.45 }, 10, 90, 0.5, 12)
		end, Ease.outQuad, T)
	end, self)
	-- a new title on its ribbon
	if item.title2 then
		local rb = t.ribbon
		rb.tex:SetTexture(MEDIA .. "Banner" .. ((item.special and "Titan") or TITLE_BANNER[item.rank2 or 1] or "Rank"))
		local col = item.special and ns.Achievements.PRESTIGE or ns.Achievements:RankColour(item.rank2 or 1)
		-- (in its outline, smaller until it fits the ribbon)
		local size = 13
		ns.SetFont(rb.text, size, "OUTLINE")
		rb.text:SetText(string.format(L["New title: %s"], item.title2))
		while size > 9 and ns.TextWidth(rb.text) > 290 do
			size = size - 0.5
			ns.SetFont(rb.text, size, "OUTLINE")
		end
		rb.text:SetTextColor(1, 0.97, 0.88)
		ns.Delay(1.6, function()
			rb:SetAlpha(0)
			rb:Show()
			ns.Play(ns.SND.rankUp)
			ns.Tween(0.4, function(e, raw)
				rb:SetScale(1.6 - 0.6 * e)
				rb:SetAlpha(math.min(1, raw * 3))
			end, function()
				rb:SetScale(1)
				t.stars:Burst(30, -TROPHY_H / 2 - 4, col, 12, 200, 0.9, 20)
			end, Ease.outBack, T)
		end, self)
	end
end

function T:Next(now)
	self:Build()
	local f = self.frame
	ns.CancelOwner(self)
	if now and self.current then
		f:Hide()
	end
	self.current = CuratorOctoFull.Remove(self.queue, 1)
	local item = self.current
	if not item then
		f:Hide()
		return
	end
	if item.trophy then
		self:ShowTrophy(item)
		ns.Play(item.sound or ns.SND.ach)
		f:SetAlpha(0)
		f:Show()
		self.state, self.clock, self.paused = "in", 0, false
		-- (it holds longer: there is more to see)
		self.hold = CuratorOctoFull.Length(self.queue) >= 2 and HOLD - 1 or HOLD + 1.2
		self:PlayTrophy(item)
		return
	end
	local part = item.icon and self:ShowAch(item) or self:ShowLoot(item)
	ns.Play(item.sound or ns.SND.cardFlip)
	-- comes in (a quick fade), the glow flashes and a light crosses it
	f:SetAlpha(0)
	f:Show()
	self.state, self.clock, self.paused = "in", 0, false
	-- a long line of toasts goes a little faster (1.12.1: a reminder to save holds its own time, UI/Save.lua)
	self.hold = item.hold or (CuratorOctoFull.Length(self.queue) >= 2 and HOLD - 2 or HOLD)
	part.glow:SetAlpha(0)
	ns.Tween(0.7, function(e, raw)
		part.glow:SetAlpha(raw < 0.3 and raw / 0.3 or (1 - (raw - 0.3) / 0.7))
	end, function()
		part.glow:SetAlpha(0)
	end, Ease.linear, self)
	local travel = item.icon and 240 or 165
	part.shine:SetAlpha(0)
	ns.Tween(0.85, function(e, raw)
		part.shine:ClearAllPoints()
		part.shine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", (item.icon and 0 or -10) + travel * e, item.icon and 8 or 12)
		part.shine:SetAlpha(math.min(1, raw * 5) * (raw > 0.4 and (1 - (raw - 0.4) / 0.6) or 1))
	end, function()
		part.shine:SetAlpha(0)
	end, Ease.outQuad, self, 0.2)
	if item.card then
		ns.Delay(0.3, function()
			f.loot.card:Animate(self)
		end, self)
	end
end

-- In, held (longer while the mouse is over it), then the slow fade of the game's alerts.
function T:Step(elapsed)
	local f = self.frame
	if not self.current or not self.state then
		return
	end
	self.clock = self.clock + elapsed
	if self.state == "in" then
		f:SetAlpha(math.min(1, self.clock / 0.2))
		if self.clock >= 0.2 then
			self.state, self.clock = "hold", 0
		end
	elseif self.state == "hold" then
		f:SetAlpha(1)
		if self.paused then
			self.clock = 0
		elseif self.clock >= self.hold then
			self.state, self.clock = "out", 0
		end
	elseif self.state == "out" then
		if self.paused then
			self.state, self.clock = "hold", 0
			return
		end
		f:SetAlpha(1 - math.min(1, self.clock / FADE))
		if self.clock >= FADE then
			self.state = nil
			f:Hide()
			T.current = nil
			T:Next()
		end
	end
end

-------------------------------------------------------------------------------
-- What shows a toast
-------------------------------------------------------------------------------
-- "Épique · Holographique  ·  Forêt d'Elwynn"
local function Line(card, finish, pattern)
	local r = ns.RARITY[card.rarity]
	local f = C:FinishName(card, finish)
	-- (1 November, his word: the pattern of a titanforged card told by the masters of the mages only, Mages.lua; a card
	-- just found is never certified yet)
	return L[r.label] .. (f and (" · " .. f) or "") .. "  ·  " .. C:SeriesName(card.series)
end
T.Line = Line

ns.On("GUILD_PULL", function(sender, card, finish)
	-- (1.14.3, the players' word: the guild turned off in the options, nothing of it; its epic cards and better only, when
	-- asked: UI/Live.lua, V:Allows)
	if ns.Live and not ns.Live:Allows(card and card.rarity or 0) then
		return
	end
	-- (the card of a booster the guild is watching shows on its panel: UI/Live.lua)
	if ns.Live and ns.Live:Claim(sender, card, finish) then
		return
	end
	T:Push({
		title = string.format(L["%s got"], ns.Guild:Short(sender)),
		name = C:Name(card),
		color = ns.RARITY[card.rarity].text,
		line = Line(card, finish),
		card = card,
		finish = finish,
		sound = ns.SND.reveal[card.rarity] or ns.SND.cardFlip,
		onClick = function()
			ns.Album:ShowMember(sender, card.series)
		end,
	})
end)

ns.On("CARD_FOUND", function(card, finish, new, _, chest)
	-- (1.14.0: a card a talent gave, or found on the creature marked: its name)
	local TL = ns.Talents
	local proc = TL and TL.cardProc
	if proc and proc.card ~= card then
		proc = nil
	end
	if TL then
		TL.cardProc = nil
	end
	-- (1.14.0: the card of a reroll, in its chest: Reroll.lua)
	local RR = ns.Reroll
	-- (1.14.0: a titanforged card, the pattern of the copy that just came, Copies.lua)
	local CP, pt = ns.Copies, nil
	local last = CP and CP.last
	-- (31 October, his word: the very copy found, its wear on it; a click shows it, that copy, in the album)
	local mine = not chest and last and CP:Get(card.key, last.i) == last and last or nil
	if finish == "holo" and mine then
		pt = CP.Pattern(last)
	end
	local wear = mine and ns.Wear and ns.Wear.Of(mine) or nil
	local ci = mine and mine.i or nil
	T:Push({
		title = proc and string.format(L["%s: a card!"], TL:Name(proc.id)) or (new and L["Card found! New!"] or L["Card found!"]),
		name = C:Name(card),
		color = ns.RARITY[card.rarity].text,
		line = chest and string.format(L["In this character's chest: it opens at level %d."], RR and RR.LEVEL or 15) or Line(card, finish, pt),
		card = card,
		finish = finish,
		pt = pt,
		wear = wear,
		sound = ns.SND.reveal[card.rarity] or ns.SND.shiny,
		onClick = function()
			if chest and ns.RerollUI then
				ns.RerollUI:ShowChest()
				return
			end
			if ci and ns.Album.ShowCopy then
				return ns.Album:ShowCopy(card, ci)
			end
			ns.Album:ShowSeries(card.series)
		end,
	})
	if card.rarity >= 3 or finish then
		ns.Guild:Announce(card, finish)
	end
end)

-- The booster bar full: a booster of the album of the place (where no album lives: a booster of a
-- zone to choose). (1.9.0: the one of a full bar comes with the sound of a quest done)
ns.On("PACK_EARNED", function(s, n, reason, bar, chest)
	local sound = bar and ns.SND.questDone or ns.SND.open
	local title = n > 1 and string.format(L["Boosters earned: %d"], n) or L["Booster earned"]
	if reason == "dungeon" then
		title = L["Dungeon complete! Booster earned"]
	elseif reason == "raid" then
		title = L["Raid complete! Booster earned"]
	elseif reason == "first" then
		-- (1.4: the first time this character completes the place)
		title = L["First clear! Bonus booster"]
	elseif ns.Talents and ns.Talents.BY[reason or ""] then
		-- (1.14.0: a booster a talent gives: Contract of the Week, Treasure Map)
		title = string.format(L["%s: a booster!"], ns.Talents:Name(reason))
	end
	-- (1.14.0: the boosters of a reroll, in its chest: Reroll.lua; the bonus of Hallow's End says it in its own alert)
	if chest then
		if reason == "hallow" then
			return
		end
		local RR = ns.Reroll
		T:Push({
			title = title,
			name = s and C:SeriesName(s) or L["A reward to choose"],
			color = { 1, 1, 1 },
			line = string.format(L["In this character's chest: it opens at level %d."], RR and RR.LEVEL or 15),
			pack = s and s.pack or nil,
			tex = (not s) and { "PackZoneChoice" } or nil,
			sound = sound,
			onClick = function()
				if ns.RerollUI then
					ns.RerollUI:ShowChest()
				end
			end,
		})
		return
	end
	if reason == "inn" then
		-- (1.8.0: a loyalty card full, Inns.lua)
		title = L["Loyalty card full! Booster earned"]
	elseif reason == "passport" or reason == "pay" or reason == "bounty" or reason == "wanted" or reason == "treat"
		or reason == "hallow" then
		-- (1.8.0: a step of the travel passport, the pay of the week, a bounty: their own alerts, UI/Inns.lua,
		-- UI/Pvp.lua; 1.12.0: the boosters of Hallow's End, UI/Hallow.lua)
		return
	end
	if not s then
		T:Push({
			title = title,
			name = L["A reward to choose"],
			color = { 1, 1, 1 },
			line = L["Choose it among three: the inventory, Boosters."],
			tex = { "PackZoneChoice" },
			sound = sound,
			onClick = function()
				ns.Album:ShowBoosters()
			end,
		})
		return
	end
	T:Push({
		title = title,
		name = C:SeriesName(s),
		color = { 1, 1, 1 },
		line = string.format(L["Boosters: %d"], ns.Packs(s)),
		pack = s.pack,
		sound = sound,
		onClick = function()
			ns.OpenBooster({ series = s })
		end,
	})
end)

-- The dungeons and the raids gave their boosters of the day.
ns.On("DAILY_LIMIT", function(s)
	T:Push({
		title = L["Daily limit reached"],
		name = L["Dungeons and raids"],
		color = { 1, 1, 1 },
		line = L["Their boosters come back after the daily reset."],
		pack = s and s.pack,
		dim = true,
		sound = ns.SND.close,
	})
end)

ns.On("ACH_EARNED", function(a, before, after)
	local AC = ns.Achievements
	-- (an album complete has a screen of its own: UI/Complete.lua)
	if a.series and ns.Complete then
		return
	end
	before = before or 0
	after = after or (before + a.pts)
	-- a new title with these points
	local female = CuratorOctoFull.Select(2, pcall(function()
		return UnitSex("player") == 3
	end)) == true
	local _, r0 = AC:Title(before, female)
	local title2, r1 = AC:Title(after, female)
	-- (1.5.0: an achievement that gives a title of prestige says it on the ribbon)
	local special = AC:SpecialOf(a)
	T:Push({
		trophy = true,
		title = L["ACHIEVEMENT EARNED"],
		name = AC:Name(a),
		line = AC:Desc(a, AC.lastSnapshot),
		points = a.pts,
		before = before,
		after = after,
		icon = a.icon,
		title2 = (special and AC:SpecialName(special.key, female)) or (r1 > r0 and title2) or nil,
		rank2 = r1,
		special = special ~= nil,
		sound = ns.SND.ach,
		onClick = function()
			ns.Album:ShowAchievement(a)
		end,
	})
end)

-- A quest done: its board, its rewards, what it was.
local DONE_TITLE = {
	daily = "Daily quest done!", weekly = "Weekly quest done!", monthly = "Monthly quest done!",
	dungeonDaily = "Dungeon quest done!", dungeonWeekly = "Dungeon quest done!",
	raidWeekly = "Raid quest done!", raidMonthly = "Raid quest done!",
	pvpDaily = "PvP quest done!", pvpWeekly = "PvP quest done!", pvpMonthly = "PvP quest done!",
	hallowDaily = "Quest of Hallow's End done!", hallowWeekly = "Quest of Hallow's End done!",
	palDaily = "Quest of the discovery done!", palWeekly = "Quest of the discovery done!",
}
-- (1.9.0) While the cards of a booster or of a contract are turned over, a quest they completed waits
-- for their end to say so: its toast would tell what is coming (a rare card, a new one, a forged one).
local function Revealing()
	local B = ns.Booster
	return B ~= nil and B.Showing ~= nil and B:Showing() and B.state ~= nil and B.state ~= "done"
end
-- (the owner of the waits: not the toasts', whose own delays a new toast cancels)
local WAITING = {}
function T:AfterReveal(fn, tries)
	tries = tries or 0
	if Revealing() and tries < 240 then
		ns.Delay(0.5, function()
			T:AfterReveal(fn, tries + 1)
		end, WAITING)
		return
	end
	fn()
end

ns.On("QUEST_DONE", function(board, q)
	T:AfterReveal(function()
		T:QuestDone(board, q)
	end)
end)

function T:QuestDone(board, q)
	local Q = ns.Quests
	T:Push({
		title = L[DONE_TITLE[board.key] or "Daily quest done!"],
		name = L["Rewards to claim!"],
		color = { 1, 0.82, 0 },
		line = Q:RewardShort(board, q),
		tex = Q.Icon(q.k),
		sound = ns.SND.questDone,
		onClick = function()
			-- (1.12.0: the quests of Hallow's End are on its page; 1.14.0: those of the discovery of the Paladin Collection
			-- Case No. 1 on its own)
			if board.section == "discovery" and ns.Album.ShowDiscovery then
				return ns.Album:ShowDiscovery()
			end
			ns.Album:ShowQuests(board.section == "general" and board.key or board.section)
		end,
	})
end

-- The rewards of quests done and not claimed, given when their period ended (or, 1.11.0, when the quests of
-- their page changed): what they gave.
local function QuestRewards(auto, title, line)
	local parts = { string.format(L["+%s XP"], ns.Num(auto.xp or 0)) }
	local packs = (auto.zone or 0) + (auto.dungeon or 0) + (auto.raid or 0)
	if packs > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = packs == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], packs)
	end
	-- (1.12.0) the boosters of Hallow's End of its quests
	if (auto.hallow or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Boosters of Hallow's End: %d"], auto.hallow)
	end
	if (auto.pts or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%s pts"], ns.Num(auto.pts))
	end
	-- (1.11.0) their rubies
	if (auto.r or 0) > 0 and ns.Rubies then
		parts[CuratorOctoFull.Length(parts) + 1] = ns.Rubies.Gem(12) .. " " .. string.format(L["+%s rubies"], ns.Num(auto.r))
	end
	T:Push({
		title = title,
		name = table.concat(parts, "  ·  "),
		color = { 1, 0.82, 0 },
		line = line,
		tex = { "XPOrb" },
		sound = ns.SND.coins,
		onClick = function()
			ns.Album:ShowQuests()
		end,
	})
end
ns.On("QUESTS_AUTOCLAIMED", function(auto)
	QuestRewards(auto, L["Quest rewards claimed for you"], L["Their quests ended before you claimed them."])
end)
ns.On("QUESTS_REROLL_CLAIMED", function(got)
	QuestRewards(got, L["Quest rewards claimed for you"], L["Claimed before their quests changed."])
end)

-- A level of collector gained elsewhere than on the screens that show it (the rewards of quests ended
-- before they were claimed): the banner of the achievements, the emblem of the rank, the level on its
-- shield.
function T:LevelUp(level)
	local r = ns.Level.RankOf(level)
	self:Push({
		title = L["Collector level!"],
		name = string.format(L["Level %d"], level),
		points = level,
		icon = { "RankIcons", { ns.Level.IconCoords(r) } },
		sound = ns.SND.levelUp,
		onClick = function()
			ns.Album:ShowProfile("track")
		end,
	})
end

-- A level gained: while a booster is opened, the end of the booster shows it (its toast if that end is
-- not seen); rewards claimed on the page of the quests, once they have landed; the rewards of quests
-- given at the end of their period, its toast; else its screen at once.
ns.On("LEVEL_UP", function(level, before, why)
	before = before or (level - 1)
	local B = ns.Booster
	if B and B.Showing and B:Showing() and B.xp0 then
		B.pendingLevel = math.max(B.pendingLevel or 0, level)
		return
	end
	local A = ns.Album
	if A and A.questBusy then
		local p = A.pendingLevel
		A.pendingLevel = { from = p and math.min(p.from, before) or before, to = level }
		return
	end
	if why == "auto" or not ns.LevelUp then
		T:LevelUp(level)
		return
	end
	ns.LevelUp:Play(before, level)
end)

-------------------------------------------------------------------------------
-- The trades: an offer that came, a trade made or undone, the boosters free to open; the fine cards
-- the guild gets in trades
-------------------------------------------------------------------------------
-- "You receive 2 · You give 1", "A gift for you!"
local function TradeLine(rec)
	local TR = ns.Trade
	local give, take = TR:Count(rec.give), TR:Count(rec.take)
	if give == 0 and take > 0 then
		return L["A gift for you!"]
	elseif take == 0 then
		return string.format(L["Asked of you: %d"], give)
	end
	return string.format(L["You receive %d  ·  You give %d"], take, give)
end

-- (not while that trade is on the screen: the page shows it)
local function Shown(rec)
	local A = ns.Album
	return A and A.frame and A.frame:IsShown() and A.mode == "guild" and A.ed ~= nil and A.ed.id == rec.id
end

-- The first card that comes in a trade (its finest), for the toast. (1.14.0: a corrupted one, the corruption of its
-- copies that came, the highest.)
local function FirstCard(items)
	local best
	for _, it in ipairs(items or {}) do
		local card = it.k and ns.Cards[it.k]
		if card and (not best or C:Score(card, it.f) > C:Score(best.card, best.f)) then
			best = { card = card, f = it.f }
			if it.f == "corrupt" and ns.Copies then
				for _, id in ipairs(type(it.got) == "table" and it.got or {}) do
					local r = ns.Copies:Get(it.k, id)
					local k = r and tonumber(r.cor)
					if k and (not best.cor or k > best.cor) then
						best.cor = k
					end
				end
			end
		end
	end
	return best
end

ns.On("TRADE_IN", function(rec, changed)
	if Shown(rec) then
		return
	end
	T:Push({
		title = changed and L["Trade offer changed"] or L["Trade offer"],
		name = ns.Guild:Short(rec.with),
		color = { 1, 0.82, 0 },
		line = TradeLine(rec),
		tex = { "Swap" },
		sound = ns.SND.questDone,
		onClick = function()
			ns.Album:ShowTrade(rec.id)
		end,
	})
end)

ns.On("TRADE_DONE", function(rec)
	-- (1.8.0: the stake of a duel: its own alerts, UI/Duel.lua)
	if Shown(rec) or rec.duel then
		return
	end
	local best = FirstCard(rec.take)
	T:Push({
		title = L["Trade done!"],
		name = best and C:Name(best.card) or ns.Guild:Short(rec.with),
		color = best and ns.RARITY[best.card.rarity].text or { 1, 0.82, 0 },
		line = string.format(L["Trade with %s"], ns.Guild:Short(rec.with)) .. "  ·  " .. TradeLine(rec),
		card = best and best.card,
		finish = best and best.f,
		corrupt = best and best.cor,
		tex = (not best) and { "Swap" } or nil,
		sound = ns.SND.coins,
		onClick = function()
			ns.Album:ShowTrade(rec.id)
		end,
	})
end)

ns.On("TRADE_NO", function(rec, why)
	if Shown(rec) or rec.duel or not (why == "declined" or why == "cancelled" or why == "gone") then
		return
	end
	local title = (why == "declined" and L["Offer refused"]) or (why == "cancelled" and L["Offer withdrawn"]) or L["Trade impossible"]
	T:Push({
		title = title,
		name = ns.Guild:Short(rec.with),
		color = { 1, 0.82, 0 },
		line = why == "gone" and L["Something of the trade was no longer there."] or TradeLine(rec),
		tex = { "Swap" },
		dim = true,
		sound = ns.SND.close,
		onClick = function()
			ns.Album:ShowTrade(rec.id)
		end,
	})
end)

ns.On("TRADE_REVERSED", function(rec)
	T:Push({
		title = L["Trade undone"],
		name = ns.Guild:Short(rec.with),
		color = { 1, 0.45, 0.4 },
		line = string.format(L["Not saved by %s (their game closed first): what you gave came back."], ns.Guild:Short(rec.with)),
		tex = { "Swap" },
		dim = true,
		sound = ns.SND.close,
		onClick = function()
			ns.Album:ShowTrade(rec.id)
		end,
	})
end)

ns.On("TRADE_CONFIRMED", function(rec)
	local n, s = 0, nil
	for _, it in ipairs(rec.take or {}) do
		if it.b then
			n = n + it.n
			s = s or ns.SeriesByKey(it.b)
		end
	end
	if n == 0 then
		return
	end
	T:Push({
		title = n == 1 and L["A booster to open"] or string.format(L["%d boosters to open"], n),
		name = s and C:SeriesName(s) or "",
		color = { 1, 1, 1 },
		line = string.format(L["From your trade with %s, now saved on their side."], ns.Guild:Short(rec.with)),
		pack = s and s.pack,
		sound = ns.SND.open,
		onClick = function()
			ns.Album:ShowBoosters()
		end,
	})
end)

ns.On("GUILD_TRADE", function(sender, card, finish, partner, gift)
	-- (1.14.3: as the pulls of the guild, UI/Live.lua: V:Allows)
	if ns.Live and not ns.Live:Allows(card and card.rarity or 0) then
		return
	end
	T:Push({
		title = string.format(L["%s received"], ns.Guild:Short(sender)),
		name = C:Name(card),
		color = ns.RARITY[card.rarity].text,
		line = string.format((gift and L["A gift from %s"] or L["In a trade with %s"]), partner and ns.Guild:Short(partner) or "?"),
		card = card,
		finish = finish,
		sound = ns.SND.reveal[card.rarity] or ns.SND.cardFlip,
		onClick = function()
			ns.Album:ShowMember(sender, card.series)
		end,
	})
end)

ns.On("GUILD_ACH", function(sender, a)
	-- (1.14.3: the guild turned off in the options, UI/Live.lua: V:Allows)
	if ns.Live and not ns.Live:Allows() then
		return
	end
	local AC = ns.Achievements
	T:Push({
		title = string.format(L["%s earned"], ns.Guild:Short(sender)),
		name = AC:Name(a),
		points = a.pts,
		icon = a.icon,
		sound = ns.SND.cardFlip,
		onClick = function()
			ns.Players:Show(sender)
		end,
	})
end)
