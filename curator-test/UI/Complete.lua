local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease
local C = ns.Collection

-- An album complete, on the whole screen: the dark falls, rays of gold turn, the photo of its place
-- comes in its frame of gold, its name over it; the seal of gold comes down on it; its finest cards
-- come under it one after the other; the reward of its achievement, to claim at once (the bar of the
-- level fills) or later. A click anywhere (or Escape) goes on. The screen of a level waits for its end
-- (and it waits for the end of the screen of a level).
local AD = {}
ns.Complete = AD

local COVER_W, COVER_H = 440, 220
local COVER_Y = 70
local CARDS = 5
local CARD_SCALE = 0.82
local CARD_Y = -150
local GOLD = { 1, 0.8, 0.34 }

local function Tex(parent, layer, sub, file, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
	if blend then
		t:SetBlendMode(blend)
	end
	return t
end

local function FadeTo(r, a, dur, delay)
	local a0 = r:GetAlpha()
	return ns.Tween(dur, function(e)
		r:SetAlpha(a0 + (a - a0) * e)
	end, nil, Ease.outQuad, AD, delay)
end

function AD:Build()
	if self.frame then
		return
	end
	local Hud = ns.Hud
	local f = CreateFrame("Frame", "CuratorAlbumComplete", UIParent)
	f:SetAllPoints()
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(300)
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	tinsert(UISpecialFrames, "CuratorAlbumComplete")
	f.dark = Tex(f, "BACKGROUND")
	f.dark:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.dark, 0, 0, 0, 1)
	f.vig = Tex(f, "BACKGROUND", 1, "Vignette")
	f.vig:SetAllPoints()

	local st = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(st, 900, 700)
	st:SetPoint("CENTER", 0, 20)
	f.st = st
	local function at(t, w, h, x, y)
		CuratorOctoFull.SetSize(t, w, h or w)
		t:SetPoint("CENTER", st, "CENTER", x or 0, y or COVER_Y)
		return t
	end
	f.rays = at(Tex(st, "BACKGROUND", 2, "Rays", "ADD"), 1000)
	f.rays:SetVertexColor(1, 0.78, 0.32)
	f.rays2 = at(Tex(st, "BACKGROUND", 3, "Rays", "ADD"), 700)
	f.rays2:SetVertexColor(1, 0.9, 0.6)
	f.glow = at(Tex(st, "BORDER", 0, "Glow", "ADD"), 760, 520)
	f.glow:SetVertexColor(1, 0.76, 0.3)
	-- (over the photo and the cards: the seal, its light, its ring, the sparks)
	local top = CreateFrame("Frame", nil, st)
	top:SetAllPoints(st)
	top:SetFrameLevel(st:GetFrameLevel() + 30)
	f.top = top
	f.ring = Tex(top, "ARTWORK", 1, "Ring", "ADD")
	CuratorOctoFull.SetSize(f.ring, 200, 200)
	f.ring:SetPoint("CENTER", st, "CENTER", 0, COVER_Y)
	f.ring:SetVertexColor(1, 0.86, 0.5)

	-- the cover: the photo of the place in its frame of gold
	local cv = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(cv, COVER_W, COVER_H)
	cv:SetPoint("CENTER", st, "CENTER", 0, COVER_Y)
	f.cover = cv
	cv.photo = cv:CreateTexture(nil, "ARTWORK")
	cv.photo:SetAllPoints()
	cv.shade = cv:CreateTexture(nil, "ARTWORK", nil, 1)
	cv.shade:SetAllPoints()
	cv.shade:SetTexture(MEDIA .. "Vignette")
	cv.shade:SetAlpha(0.7)
	cv.lines = {}
	for k, p in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 3 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 3 }, { "TOPLEFT", "BOTTOMLEFT", 3, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 3, 0 } }) do
		local t = cv:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.ColorTexture(t, 1, 0.8, 0.36, 1)
		t:SetPoint(p[1], cv, p[1], 0, 0)
		t:SetPoint(p[2], cv, p[2], 0, 0)
		if p[3] > 0 then
			t:SetWidth(p[3])
		else
			t:SetHeight(p[4])
		end
		cv.lines[k] = t
	end
	cv.corners = {}
	for k, c in ipairs({ { "TOPLEFT", 0, 1, 0, 1, -14, 14 }, { "TOPRIGHT", 1, 0, 0, 1, 14, 14 }, { "BOTTOMLEFT", 0, 1, 1, 0, -14, -14 }, { "BOTTOMRIGHT", 1, 0, 1, 0, 14, -14 } }) do
		local t = cv:CreateTexture(nil, "OVERLAY", nil, 1)
		t:SetTexture(MEDIA .. "GoldCorner")
		t:SetTexCoord(c[2], c[3], c[4], c[5])
		CuratorOctoFull.SetSize(t, 96, 96)
		t:SetPoint(c[1], c[6], c[7])
		cv.corners[k] = t
	end
	-- a light passing over it
	cv.sheen = cv:CreateTexture(nil, "OVERLAY", nil, 2)
	cv.sheen:SetTexture(MEDIA .. "Sheen")
	cv.sheen:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(cv.sheen, 300, 300)
	cv.sheen:SetAlpha(0)
	if cv.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(cv, false)
	end

	-- its name over it, what it is under the name
	f.label = Hud.Text(st, 16, "OUTLINE")
	f.label:SetPoint("CENTER", st, "CENTER", 0, COVER_Y + COVER_H / 2 + 76)
	f.label:SetTextColor(1, 0.84, 0.4)
	f.name = Hud.Text(st, 34, "THICKOUTLINE")
	f.name:SetPoint("CENTER", st, "CENTER", 0, COVER_Y + COVER_H / 2 + 42)
	f.name:SetTextColor(1, 0.95, 0.82)
	-- the seal of gold, on its corner
	f.seal = Tex(top, "OVERLAY", 3, "AlbumSeal")
	CuratorOctoFull.SetSize(f.seal, 150, 150)
	f.seal:SetPoint("CENTER", st, "CENTER", COVER_W / 2 - 24, COVER_Y - COVER_H / 2 + 20)
	f.sealGlow = Tex(top, "OVERLAY", 2, "Glow", "ADD")
	CuratorOctoFull.SetSize(f.sealGlow, 260, 260)
	f.sealGlow:SetPoint("CENTER", f.seal, "CENTER")
	f.sealGlow:SetVertexColor(1, 0.8, 0.36)

	-- its finest cards
	f.cards = {}
	for i = 1, CARDS do
		local c = ns.NewCard(st, "small")
		c:SetScale(CARD_SCALE)
		c:EnableMouse(false)
		c:Hide()
		f.cards[i] = c
	end

	-- the reward of its achievement, the bar of the level, the buttons
	-- (1.14.0, his word: an album complete, a whole level, rubies by its kind and a golden booster to choose; its
	-- golden booster on a line of its own, under the rest)
	f.reward = Hud.Text(st, 15, "OUTLINE")
	f.reward:SetPoint("CENTER", st, "CENTER", 0, -248)
	f.reward:SetTextColor(1, 0.92, 0.7)
	f.gift = Hud.Text(st, 13, "OUTLINE")
	f.gift:SetPoint("CENTER", st, "CENTER", 0, -272)
	f.gift:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.xp = Hud.XPBar(st, 300, 14)
	f.xp:SetPoint("CENTER", st, "CENTER", 22, -298)
	f.emblem = Hud.Emblem(st, 40)
	f.emblem:SetPoint("RIGHT", f.xp, "LEFT", -8, 0)
	f.claim = Hud.ClaimButton(st, 200, 36, L["Claim"])
	f.claim:SetPoint("CENTER", st, "CENTER", -110, -340)
	CuratorOctoFull.SetScript(f.claim, "OnClick", function()
		AD:OnClaim()
	end)
	f.open = ns.Button(st, L["Open the album"], 200, 26)
	f.open:SetPoint("CENTER", st, "CENTER", 110, -340)
	CuratorOctoFull.SetScript(f.open, "OnClick", function()
		AD:OpenAlbum()
	end)
	f.hint = Hud.Text(st, 11, "")
	f.hint:SetPoint("CENTER", st, "CENTER", 0, -376)
	f.hint:SetTextColor(0.75, 0.75, 0.78)
	-- (1 November, his word: « SANS cliquer sur "Retour" impossible de retour »: a button goes on, a click beside no more)
	f.go = ns.Button(st, L["Continue"], 160, 24)
	f.go:SetPoint("CENTER", st, "CENTER", 0, -380)
	CuratorOctoFull.SetScript(f.go, "OnClick", function()
		if AD.ready then
			AD:Close()
		end
	end)
	f.go:Hide()

	f.sparks = ns.Particles:New(top, 90, "Spark")
	f.stars = ns.Particles:New(top, 50, "Twinkle")
	f.dust = ns.Particles:New(top, 16, "Puff", "BLEND")
	f.dust.alpha = 0.5

	CuratorOctoFull.SetScript(f, "OnMouseDown", function() end)
	CuratorOctoFull.SetScript(f, "OnHide", function(self)
		if self:IsShown() then
			self:Hide()
		end
		AD:Cleanup()
	end)
	f.t = 0
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		CuratorOctoFull.SetRotation(self.rays, self.t * 0.08)
		CuratorOctoFull.SetRotation(self.rays2, -self.t * 0.13)
		for _, c in ipairs(self.cards) do
			if c:IsShown() then
				c:Tick(self.t)
			end
		end
		if AD.live then
			self.glow:SetAlpha(0.42 * (0.85 + 0.15 * math.sin(self.t * 2)))
			self.sealGlow:SetAlpha(0.35 + 0.15 * math.sin(self.t * 2.6))
		end
	end)
end

-- The finest cards of an album: by rarity, then by their number.
local function Finest(s, n)
	local list = {}
	for r = CuratorOctoFull.Length(ns.RARITY), 1, -1 do
		for _, card in ipairs(s.byRarity[r] or {}) do
			list[CuratorOctoFull.Length(list) + 1] = card
			if CuratorOctoFull.Length(list) >= n then
				return list
			end
		end
	end
	return list
end

-- The screen of an album complete (a: its achievement).
function AD:Play(s, a)
	self:Build()
	-- (the screen of a level, or of another album, first: this one waits for its end)
	if (ns.LevelUp and ns.LevelUp:Showing()) or (self:Showing() and self.series ~= s) then
		self.waiting = self.waiting or {}
		self.waiting[CuratorOctoFull.Length(self.waiting) + 1] = { s, a }
		self:Poll()
		return
	end
	local f = self.frame
	ns.CancelOwner(self)
	-- (the alerts wait for its end)
	if ns.Toast and ns.Toast.Hold then
		ns.Toast:Hold()
	end
	f.sparks:Clear()
	f.stars:Clear()
	f.dust:Clear()
	self.series, self.ach = s, a
	self.ready, self.live, self.closing = false, false, false
	f:SetAlpha(1)
	GameTooltip:Hide()
	f:Show()
	f:Raise()
	f.t = 0
	f.dark:SetAlpha(0)
	f.vig:SetAlpha(0)
	FadeTo(f.dark, 0.8, 0.4)
	FadeTo(f.vig, 1, 0.4)
	for _, t in ipairs({ f.rays, f.rays2, f.glow, f.ring, f.cover, f.label, f.name, f.seal, f.sealGlow, f.reward, f.gift, f.xp, f.emblem, f.claim, f.open, f.hint }) do
		t:SetAlpha(0)
	end
	for _, c in ipairs(f.cards) do
		c:Hide()
	end
	ns.Play(ns.SND.rankUp)
	-- the cover comes, its light behind it, the rays wake
	local cv = f.cover
	cv.photo:SetTexture(MEDIA .. (s.studio or "StudioElwynn"))
	cv.photo:SetTexCoord(0, 1, 0, 1)
	ns.Tween(0.6, function(e, raw)
		local k = 0.8 + 0.2 * e
		cv:SetScale(k)
		cv:ClearAllPoints()
		cv:SetPoint("CENTER", f.st, "CENTER", 0, COVER_Y / k)
		cv:SetAlpha(math.min(1, raw * 2.5))
	end, function()
		cv:SetScale(1)
		cv:ClearAllPoints()
		cv:SetPoint("CENTER", f.st, "CENTER", 0, COVER_Y)
	end, Ease.outBack, self, 0.15)
	FadeTo(f.glow, 0.42, 0.6, 0.2)
	FadeTo(f.rays, 0.45, 0.8, 0.25)
	FadeTo(f.rays2, 0.3, 0.8, 0.35)
	-- its name
	f.label:SetText(L["ALBUM COMPLETE!"])
	-- (a long name: smaller until it fits the screen)
	local size = 34
	ns.SetFont(f.name, size, "THICKOUTLINE")
	f.name:SetText(C:SeriesName(s))
	while size > 20 and ns.TextWidth(f.name) > 820 do
		size = size - 1
		ns.SetFont(f.name, size, "THICKOUTLINE")
	end
	FadeTo(f.label, 1, 0.35, 0.45)
	ns.Tween(0.45, function(e, raw)
		f.name:SetAlpha(math.min(1, raw * 2))
		ns.SetFont(f.name, size + 10 * (1 - e), "THICKOUTLINE")
	end, function()
		ns.SetFont(f.name, size, "THICKOUTLINE")
	end, Ease.outCubic, self, 0.55)
	-- a light passes over the photo
	ns.Tween(1.1, function(_, raw)
		cv.sheen:ClearAllPoints()
		cv.sheen:SetPoint("CENTER", cv, "CENTER", -COVER_W / 2 - 120 + (COVER_W + 240) * raw, 0)
		cv.sheen:SetAlpha(math.sin(math.pi * raw) * 0.55)
	end, nil, Ease.inOutQuad, self, 0.7)
	-- the seal comes down on its corner
	local sx, sy = COVER_W / 2 - 24, COVER_Y - COVER_H / 2 + 20
	ns.Tween(0.28, function(e, raw)
		local k = 2.6 - 1.6 * e
		CuratorOctoFull.SetSize(f.seal, 150 * k, 150 * k)
		f.seal:SetAlpha(math.min(1, raw * 3))
	end, function()
		CuratorOctoFull.SetSize(f.seal, 150, 150)
		ns.Play(ns.SND.stamp)
		ns.Play(ns.SND.ach)
		f.ring:ClearAllPoints()
		f.ring:SetPoint("CENTER", f.st, "CENTER", sx, sy)
		ns.Tween(0.7, function(e, raw)
			local k = 120 + 700 * e
			CuratorOctoFull.SetSize(f.ring, k, k)
			f.ring:SetAlpha((1 - raw) * 0.9)
		end, nil, Ease.outCubic, AD)
		f.dust:Burst(sx, sy - 40, { 0.8, 0.72, 0.6 }, 6, 90, 0.8, 90, 0.3, 1.6)
		f.sparks:Burst(sx, sy, { 1, 0.86, 0.45 }, 30, 300, 0.8, 20)
		f.stars:Burst(sx, sy, { 1, 0.9, 0.6 }, 14, 240, 1.0, 26)
		FadeTo(f.sealGlow, 0.45, 0.3)
		AD.live = true
	end, Ease.inQuad, self, 1.25)
	-- its finest cards, one after the other
	local finest = Finest(s, CARDS)
	local n = CuratorOctoFull.Length(finest)
	local w = ns.CARD_SIZES.small[1] * CARD_SCALE
	for i, card in ipairs(finest) do
		local i, card = i, card; local c = f.cards[i]
		-- (1.14.0: titanforged, the pattern of my copy that shows it, Copies.lua)
		local fin = C:BestFinish(C:Entry(card))
		c:SetCard(card, { owned = true, finish = fin, pattern = fin == "holo" and ns.Copies and ns.Copies:PatternOf(card.key) or nil })
		c:ShowSide("front")
		c.phase = i * 0.37
		local x = (i - (n + 1) / 2) * (w + 18)
		local y = CARD_Y - math.abs(i - (n + 1) / 2) * 8
		c:SetAlpha(0)
		c:Show()
		local function place(k)
			c:ClearAllPoints()
			c:SetPoint("CENTER", f.st, "CENTER", x / CARD_SCALE, (y - 40 * (1 - k)) / CARD_SCALE)
		end
		place(0)
		ns.Tween(0.4, function(e, raw)
			place(e)
			c:SetAlpha(math.min(1, raw * 3))
		end, function()
			local col = ns.RARITY[card.rarity].glow
			f.sparks:Burst(x, y, col, 8, 140, 0.6, 14)
			if i == 1 then
				ns.Play(ns.SND.cardLand)
			end
			c.glow:SetVertexColor(col[1], col[2], col[3])
			c.glow:SetAlpha(card.rarity >= 4 and 0.5 or 0.2)
		end, Ease.outBack, self, 1.7 + 0.12 * (i - 1))
	end
	-- the reward of its achievement, the bar of the level
	local t1 = 1.7 + 0.12 * n + 0.3
	self:PaintReward()
	FadeTo(f.reward, 1, 0.35, t1)
	FadeTo(f.gift, 1, 0.35, t1 + 0.05)
	FadeTo(f.xp, 1, 0.35, t1 + 0.1)
	FadeTo(f.emblem, 1, 0.35, t1 + 0.1)
	-- (the buttons only come with their fade: not to be clicked unseen)
	f.claim:Hide()
	f.open:Hide()
	ns.Delay(t1 + 0.25, function()
		f.claim:Show()
		f.open:Show()
	end, self)
	FadeTo(f.claim, 1, 0.3, t1 + 0.25)
	FadeTo(f.open, 1, 0.3, t1 + 0.25)
	f.hint:SetText("")
	f.go:SetAlpha(0)
	ns.Delay(t1 + 0.8, function()
		f.go:Show()
	end, self)
	FadeTo(f.go, 1, 0.4, t1 + 0.8)
	ns.Delay(1.4, function()
		AD.ready = true
	end, self)
	-- stars falling all along
	for k = 0, 7 do
		ns.Delay(1.3 + k * 0.5, function()
			f.stars:Rise(-380, 380, -320, { 1, 0.86, 0.5 }, 3, 560, 2.6, 18)
		end, self)
	end
end

-- The reward of the achievement of the album: its experience to claim, or claimed; the bar of the level.
function AD:PaintReward(xp)
	local f = self.frame
	local AC, LV = ns.Achievements, ns.Level
	local a = self.ach
	local x = xp or LV:XP()
	local level, into, need = LV.Of(x)
	f.emblem:SetRank((LV.RankOf(level)))
	f.xp:SetProgress(need and into / need or 1)
	f.xp:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
	local parts = {}
	local album = a and AC:AlbumKind(a)
	if a then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["%d points"], a.pts)
		-- (1.14.0: an album complete, a whole level)
		parts[CuratorOctoFull.Length(parts) + 1] = string.format((album and L["+%s XP: a whole level"] or L["+%s XP"]), ns.Num(AC:XP(a)))
		-- (1.11.0) its rubies
		if ns.Rubies and AC:Rubies(a) > 0 then
			parts[CuratorOctoFull.Length(parts) + 1] = ns.Rubies.Gem(14) .. " " .. string.format(L["+%s rubies"], ns.Num(AC:Rubies(a)))
		end
	end
	f.reward:SetText(table.concat(parts, "   ·   "))
	local waiting = a and AC:Waiting(a)
	-- (1.14.0: its golden booster, into an album drawn at random (his word); claimed, which one)
	local icon = "|T" .. ns.Hud.PackIcon("golden") .. ":18:18|t "
	if album then
		local went = ns.Level and ns.Level.lastGolden
		f.gift:SetText(icon .. (waiting and ("+ " .. ns.Album:PackReward("golden", 1))
			or (went and string.format(L["The golden booster went to %s: the button of gold under the boosters."], ns.Collection:SeriesName(went))) or ""))
	else
		f.gift:SetText("")
	end
	f.claim:SetEnabled(waiting and true or false)
	f.claim:SetPulse(waiting and true or false)
	f.claim:SetLabel(waiting and L["Claim"] or L["Claimed"])
end

-- The experience of its achievement claimed: it flies into the bar of the level, which fills.
function AD:OnClaim()
	local f = self.frame
	local AC, LV = ns.Achievements, ns.Level
	local a = self.ach
	if not (a and AC:Waiting(a)) then
		return
	end
	local x0 = LV:XP()
	local xp = AC:Claim({ a })
	ns.Play(ns.SND.claim)
	self:PaintReward(x0)
	f.claim:SetEnabled(false)
	f.claim:SetPulse(false)
	-- (1.14.0: its golden booster gone to the boosters to choose, a spark of gold on its line)
	if AC:AlbumKind(a) and AC:Claimed(a) then
		f.sparks:Burst(0, -272, GOLD, 16, 130, 0.6, 14)
	end
	ns.Hud.Fly(ns.Hud.XP, f.reward, f.xp, 34, 0.6, function()
		ns.Play(ns.SND.orbHit)
		f.xp:Flash(0.9)
		local lv0 = LV.Of(x0)
		ns.Tween(0.6, function(e)
			local x = math.floor(x0 + xp * e + 0.5)
			local lv = LV.Of(x)
			if lv > lv0 then
				lv0 = lv
				f.xp:Flash(1)
				ns.Play(ns.SND.xpTick)
			end
			AD:PaintReward(x)
		end, function()
			AD:PaintReward()
		end, Ease.outCubic, AD)
	end, { 0.82, 0.62, 1 })
end

-- To the album (the screen of a booster under it goes).
function AD:OpenAlbum()
	local s = self.series
	self:Close()
	local B = ns.Booster
	if B and B.Showing and B:Showing() then
		B.frame:Hide()
	end
	if s and ns.Album then
		ns.Album:ShowSeries(s)
	end
end

function AD:Close()
	local f = self.frame
	if not (f and f:IsShown()) or self.closing then
		return
	end
	self.closing = true
	self.ready = false
	ns.Tween(0.3, function(e)
		f:SetAlpha(1 - e)
	end, function()
		f:Hide()
		f:SetAlpha(1)
	end, Ease.outQuad, self)
end

function AD:Cleanup()
	local f = self.frame
	ns.CancelOwner(self)
	f.sparks:Clear()
	f.stars:Clear()
	f.dust:Clear()
	for _, c in ipairs(f.cards) do
		c:Hide()
	end
	self.live, self.ready, self.closing = false, false, false
	f:SetAlpha(1)
	self:Poll()
	-- the alerts that waited (unless another album waits its turn)
	if not (self.waiting and CuratorOctoFull.Length(self.waiting) > 0) and ns.Toast and ns.Toast.Resume then
		ns.Toast:Resume()
	end
end

-- The albums waiting their turn (behind the screen of a level, or another album).
function AD:Poll()
	if self.polling or not (self.waiting and CuratorOctoFull.Length(self.waiting) > 0) then
		return
	end
	self.polling = true
	local function step()
		if (ns.LevelUp and ns.LevelUp:Showing()) or self:Showing() then
			ns.Delay(0.3, step, AD.waiting)
			return
		end
		self.polling = false
		local nxt = CuratorOctoFull.Remove(self.waiting, 1)
		if nxt then
			self:Play(nxt[1], nxt[2])
		end
	end
	ns.Delay(0.3, step, self.waiting)
end

function AD:Showing()
	return self.frame ~= nil and self.frame:IsShown()
end

-- An album complete: its achievement earned (once the cards that completed it were seen).
ns.On("ACH_EARNED", function(a)
	if a and a.series then
		AD:Play(a.series, a)
	end
end)
