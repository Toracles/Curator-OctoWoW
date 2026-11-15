local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease

-- The pieces of the level of the collector and of its quests, in the style of the emblems: the bar of
-- experience (a frame of gold, a glossy violet fill, a spark at its end, a light passing over it), the
-- button to claim (gold, it breathes when a reward waits), the badge of the rewards waiting, the emblem
-- of a rank (its light breathing behind the higher ones), the icons of the rewards, and the light
-- that flies from a reward to where it goes.
local H = {}
ns.Hud = H

-- The icons of the rewards: the experience, a booster to choose of each kind.
H.XP = MEDIA .. "XPOrb"
-- (1.14.0: the golden booster of an album complete, to choose: Level.lua, the kind "golden")
H.PACK = { zone = MEDIA .. "PackZoneChoice", dungeon = MEDIA .. "PackDungeonChoice", raid = MEDIA .. "PackRaidChoice",
	golden = MEDIA .. "PackGoldenChoice",
	-- (1.14.0: the reward of a level, to choose among three: Level.lua, the kind "offer")
	offer = "Interface\\Icons\\INV_Box_02" }

function H.PackIcon(kind)
	return H.PACK[kind] or H.PACK.zone
end

-- A text in the font of the game, of a size (its outline: "OUTLINE", "THICKOUTLINE" or none).
function H.Text(parent, size, flags, layer, sub)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY", nil, sub)
	ns.SetFont(fs, size, flags)
	if not flags or flags == "" then
		fs:SetShadowOffset(1, -1)
		fs:SetShadowColor(0, 0, 0, 1)
	end
	return fs
end

-- A texture of 512 x 128 over a frame of this height: its ends (48 of 512) as they are, its middle
-- stretched; out: points past the frame on each side (a glow around it). The three pieces.
function H.Sliced(f, file, height, out, layer, sub, blend)
	out = out or 0
	local cap = 48 * (height + 2 * out) / 128
	local t = {}
	for i, u in ipairs({ { 0, 48 }, { 48, 464 }, { 464, 512 } }) do
		local x = f:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
		x:SetTexture(MEDIA .. file)
		x:SetTexCoord(u[1] / 512, u[2] / 512, 0, 1)
		if blend then
			x:SetBlendMode(blend)
		end
		t[i] = x
	end
	t[1]:SetPoint("TOPLEFT", -out, out)
	t[1]:SetPoint("BOTTOMLEFT", -out, -out)
	t[1]:SetWidth(cap)
	t[3]:SetPoint("TOPRIGHT", out, out)
	t[3]:SetPoint("BOTTOMRIGHT", out, -out)
	t[3]:SetWidth(cap)
	t[2]:SetPoint("TOPLEFT", t[1], "TOPRIGHT")
	t[2]:SetPoint("BOTTOMRIGHT", t[3], "BOTTOMLEFT")
	return t
end

-- (the glow of a card lies on its edge: this far past a frame of this height)
function H.GlowOut(height)
	return height * 0.077
end

-- A method called on each of a list of regions.
function H.Each(t, method, ...)
	for _, x in ipairs(t) do
		x[method](x, unpack(arg, 1, arg.n))
	end
end

-- The dark card of the pages (QuestCard) and its glow of gold (hidden): f.bg, f.glow.
function H.Panel(f, height, glowColor)
	f.bg = H.Sliced(f, "QuestCard", height, 0, "BACKGROUND")
	f.glow = H.Sliced(f, "QuestGlow", height, H.GlowOut(height), "BORDER", 0, "ADD")
	local c = glowColor or { 1, 0.8, 0.32 }
	H.Each(f.glow, "SetVertexColor", c[1], c[2], c[3])
	H.Each(f.glow, "SetAlpha", 0)
end

-- The dark card of the pages (QuestCard) on a frame of any size: its corners as they are (16 points
-- of the texture each, k points of the screen a point), its edges and its middle stretched; hollow:
-- without its middle (a frame around a picture). The pieces.
function H.Card(f, k, layer, sub, hollow)
	local c = 16
	local cw = c * (k or 0.75)
	local u = { 0, c / 512, 1 - c / 512, 1 }
	local v = { 0, c / 128, 1 - c / 128, 1 }
	local t = {}
	for row = 1, 3 do
		for col = 1, 3 do
			if not (hollow and row == 2 and col == 2) then
				local x = f:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
				x:SetTexture(MEDIA .. "QuestCard")
				x:SetTexCoord(u[col], u[col + 1], v[row], v[row + 1])
				t[(row - 1) * 3 + col] = x
			end
		end
	end
	t[1]:SetPoint("TOPLEFT")
	t[3]:SetPoint("TOPRIGHT")
	t[7]:SetPoint("BOTTOMLEFT")
	t[9]:SetPoint("BOTTOMRIGHT")
	for _, i in ipairs({ 1, 3, 7, 9 }) do
		CuratorOctoFull.SetSize(t[i], cw, cw)
	end
	t[2]:SetPoint("TOPLEFT", t[1], "TOPRIGHT")
	t[2]:SetPoint("BOTTOMRIGHT", t[3], "BOTTOMLEFT")
	t[8]:SetPoint("TOPLEFT", t[7], "TOPRIGHT")
	t[8]:SetPoint("BOTTOMRIGHT", t[9], "BOTTOMLEFT")
	t[4]:SetPoint("TOPLEFT", t[1], "BOTTOMLEFT")
	t[4]:SetPoint("BOTTOMRIGHT", t[7], "TOPRIGHT")
	t[6]:SetPoint("TOPLEFT", t[3], "BOTTOMLEFT")
	t[6]:SetPoint("BOTTOMRIGHT", t[9], "TOPRIGHT")
	if t[5] then
		t[5]:SetPoint("TOPLEFT", t[1], "BOTTOMRIGHT")
		t[5]:SetPoint("BOTTOMRIGHT", t[9], "TOPLEFT")
	end
	local list = {}
	for i = 1, 9 do
		if t[i] then
			list[CuratorOctoFull.Length(list) + 1] = t[i]
		end
	end
	return list
end

-- (1.6.0) The glow of gold of a card of any size (H.Card of the same k): the glow of QuestGlow in eight
-- pieces around it, past its frame, hidden; its colour. The pieces.
function H.CardGlow(f, k, color, layer, sub)
	-- (QuestGlow lies 1.154 times larger than QuestCard, its frame 8.5 points of the texture in)
	local s = (k or 0.75) * 1.154
	local c = 40
	local cw = c * s
	local out = 8.5 * s
	local u = { 0, c / 512, 1 - c / 512, 1 }
	local v = { 0, c / 128, 1 - c / 128, 1 }
	local t = {}
	for row = 1, 3 do
		for col = 1, 3 do
			if not (row == 2 and col == 2) then
				local x = f:CreateTexture(nil, layer or "BORDER", nil, sub)
				x:SetTexture(MEDIA .. "QuestGlow")
				x:SetTexCoord(u[col], u[col + 1], v[row], v[row + 1])
				x:SetBlendMode("ADD")
				t[(row - 1) * 3 + col] = x
			end
		end
	end
	t[1]:SetPoint("TOPLEFT", -out, out)
	t[3]:SetPoint("TOPRIGHT", out, out)
	t[7]:SetPoint("BOTTOMLEFT", -out, -out)
	t[9]:SetPoint("BOTTOMRIGHT", out, -out)
	for _, i in ipairs({ 1, 3, 7, 9 }) do
		CuratorOctoFull.SetSize(t[i], cw, cw)
	end
	t[2]:SetPoint("TOPLEFT", t[1], "TOPRIGHT")
	t[2]:SetPoint("BOTTOMRIGHT", t[3], "BOTTOMLEFT")
	t[8]:SetPoint("TOPLEFT", t[7], "TOPRIGHT")
	t[8]:SetPoint("BOTTOMRIGHT", t[9], "BOTTOMLEFT")
	t[4]:SetPoint("TOPLEFT", t[1], "BOTTOMLEFT")
	t[4]:SetPoint("BOTTOMRIGHT", t[7], "TOPRIGHT")
	t[6]:SetPoint("TOPLEFT", t[3], "BOTTOMLEFT")
	t[6]:SetPoint("BOTTOMRIGHT", t[9], "TOPRIGHT")
	local list = {}
	for i = 1, 9 do
		if t[i] then
			list[CuratorOctoFull.Length(list) + 1] = t[i]
		end
	end
	local col = color or { 1, 0.8, 0.32 }
	H.Each(list, "SetVertexColor", col[1], col[2], col[3])
	H.Each(list, "SetAlpha", 0)
	return list
end

-- An icon cut round, for a ring of gold (without the masks of the game: smaller, inside the ring).
function H.RoundIcon(parent, size, layer, sub)
	local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub)
	CuratorOctoFull.SetSize(t, size, size)
	if parent.CreateMaskTexture and t.AddMaskTexture then
		local m = CuratorOctoFull.CreateMaskTexture(parent)
		m:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		m:SetAllPoints(t)
		CuratorOctoFull.AddMaskTexture(t, m)
	else
		CuratorOctoFull.SetSize(t, size * 0.7, size * 0.7)
	end
	return t
end

-- A stamp coming down on a texture: from big and clear to its size, then land().
function H.Stamp(tex, size, delay, land, owner)
	CuratorOctoFull.SetSize(tex, size * 2.4, size * 2.4)
	tex:SetAlpha(0)
	tex:Show()
	ns.Tween(0.26, function(e, raw)
		local k = 2.4 - 1.4 * e
		CuratorOctoFull.SetSize(tex, size * k, size * k)
		tex:SetAlpha(math.min(1, raw * 3))
	end, function()
		CuratorOctoFull.SetSize(tex, size, size)
		tex:SetAlpha(1)
		if land then
			land()
		end
	end, Ease.inQuad, owner or H, delay)
end

-- An icon of the game on a texture, without its border (or a texture of the addon: { file,
-- coordinates, colour }).
function H.SetIcon(tex, icon)
	ns.SetIcon(tex, icon)
	-- (an icon of the game: by its path, or by its file number, the icon of an item)
	if (type(icon[1]) == "number" or string.find(icon[1], "\\", 1, true)) and not icon[2] then
		tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end

-------------------------------------------------------------------------------
-- The ring of progress (RingProgress: 64 steps of a ring of gold, 8 x 8 cells)
-------------------------------------------------------------------------------
-- ring:SetProgress(0 to 1).
function H.Ring(parent, size, layer, sub)
	local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub)
	t:SetTexture(MEDIA .. "RingProgress")
	CuratorOctoFull.SetSize(t, size, size)
	function t:SetProgress(p)
		local k = math.floor(math.max(0, math.min(1, p or 0)) * 63 + 0.5)
		-- (a ring not full shows not full)
		if k == 63 and (p or 0) < 1 then
			k = 62
		elseif k == 0 and (p or 0) > 0 then
			k = 1
		end
		local col, row = CuratorOctoFull.Mod(k , 8), math.floor(k / 8)
		self:SetTexCoord(col / 8, (col + 1) / 8, row / 8, (row + 1) / 8)
		self.p = p
	end
	t:SetProgress(0)
	return t
end

-------------------------------------------------------------------------------
-- The bar of experience
-------------------------------------------------------------------------------
-- The frame of the texture: 512 x 48, the channel inside it 497.6 x 21.6 from (7.2, 13.2); its ends
-- (24 of 512) stay as they are, its middle stretches.
local FRAME_W, FRAME_H, HOLE_X, HOLE_Y, HOLE_H, CAP = 512, 48, 7.2, 13.2, 21.6, 24

-- bar:SetProgress(0 to 1), bar.text; bar:Flash() lights it up for an instant. tint: the colour of the
-- fill when it is not the experience (it is greyed, then tinted).
function H.XPBar(parent, width, height, tint)
	height = height or 16
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, width, height)
	f.w, f.h, f.p = width, height, 0
	f.back = f:CreateTexture(nil, "BACKGROUND")
	f.back:SetTexture(MEDIA .. "XPBack")
	f.back:SetAllPoints()
	f.bar = CreateFrame("StatusBar", nil, f)
	f.bar:SetAllPoints()
	f.bar:SetStatusBarTexture(MEDIA .. "XPFill")
	f.bar:SetMinMaxValues(0, 1)
	f.bar:SetValue(0)
	if tint then
		local t = f.bar:GetStatusBarTexture()
		t:SetDesaturated(true)
		f.bar:SetStatusBarColor(tint[1], tint[2], tint[3])
	end
	-- a tick every tenth
	f.ticks = {}
	for i = 1, 9 do
		local t = f.bar:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.ColorTexture(t, 0, 0, 0, 0.32)
		CuratorOctoFull.SetSize(t, 1, math.max(2, height - 4))
		t:SetPoint("CENTER", f, "LEFT", width * i / 10, 0)
		f.ticks[i] = t
	end
	-- the light passing over the fill (cut to it)
	f.clip = CreateFrame("Frame", nil, f.bar)
	f.clip:SetPoint("TOPLEFT")
	f.clip:SetPoint("BOTTOMLEFT")
	f.clip:SetWidth(1)
	if f.clip.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(f.clip, true)
	end
	f.shine = f.clip:CreateTexture(nil, "OVERLAY")
	f.shine:SetTexture(MEDIA .. "XPShine")
	f.shine:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.shine, height * 4, height)
	f.shine:SetAlpha(0)
	f.flash = f.bar:CreateTexture(nil, "OVERLAY", nil, 2)
	CuratorOctoFull.ColorTexture(f.flash, 1, 1, 1, 1)
	f.flash:SetBlendMode("ADD")
	f.flash:SetPoint("TOPLEFT")
	f.flash:SetPoint("BOTTOMLEFT")
	f.flash:SetWidth(1)
	f.flash:SetAlpha(0)
	-- the frame over it: its ends and its middle
	local k = height / HOLE_H
	f.over = CreateFrame("Frame", nil, f)
	f.over:SetPoint("TOPLEFT", -HOLE_X * k, HOLE_Y * k)
	f.over:SetPoint("BOTTOMRIGHT", HOLE_X * k, -(FRAME_H - HOLE_Y - HOLE_H) * k)
	f.over:SetFrameLevel(f.bar:GetFrameLevel() + 3)
	local function piece(l, r)
		local t = f.over:CreateTexture(nil, "OVERLAY")
		t:SetTexture(MEDIA .. "XPFrame")
		t:SetTexCoord(l / FRAME_W, r / FRAME_W, 0, 1)
		return t
	end
	local capW = CAP * k
	f.left = piece(0, CAP)
	f.left:SetPoint("TOPLEFT")
	f.left:SetPoint("BOTTOMLEFT")
	f.left:SetWidth(capW)
	f.right = piece(FRAME_W - CAP, FRAME_W)
	f.right:SetPoint("TOPRIGHT")
	f.right:SetPoint("BOTTOMRIGHT")
	f.right:SetWidth(capW)
	f.mid = piece(CAP, FRAME_W - CAP)
	f.mid:SetPoint("TOPLEFT", f.left, "TOPRIGHT")
	f.mid:SetPoint("BOTTOMRIGHT", f.right, "BOTTOMLEFT")
	-- the spark at the end of the fill
	f.tip = f.over:CreateTexture(nil, "OVERLAY", nil, 2)
	f.tip:SetTexture(MEDIA .. "Twinkle")
	f.tip:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.tip, height * 2.4, height * 2.4)
	f.tip:SetVertexColor(0.86, 0.7, 1)
	f.tip:SetAlpha(0)
	-- (its text over the spark)
	f.text = H.Text(f.over, math.max(9, math.floor(height * 0.66 + 0.5)), "OUTLINE", "OVERLAY", 4)
	f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.text:SetTextColor(1, 1, 1)
	function f:SetProgress(p)
		p = math.max(0, math.min(1, p or 0))
		self.p = p
		self.bar:SetValue(p)
		local w = math.max(1, self.w * p)
		self.clip:SetWidth(w)
		self.flash:SetWidth(w)
		self.tip:ClearAllPoints()
		self.tip:SetPoint("CENTER", self, "LEFT", self.w * p, 0)
		CuratorOctoFull.SetShown(self.tip, p > 0.01 and p < 0.995)
	end
	function f:SetText(t)
		self.text:SetText(t or "")
	end
	-- another width (its ticks follow)
	function f:SetBarWidth(w)
		w = math.max(20, math.floor((tonumber(w) or self.w) + 0.5))
		if w == self.w then
			return
		end
		self.w = w
		self:SetWidth(w)
		for i, t in ipairs(self.ticks) do
			t:ClearAllPoints()
			t:SetPoint("CENTER", self, "LEFT", w * i / 10, 0)
		end
		self:SetProgress(self.p)
	end
	-- an instant of light over the fill (the experience landing in it)
	function f:Flash(strength)
		if self.flashTw then
			ns.CancelTween(self.flashTw)
		end
		local a0 = strength or 0.7
		self.flashTw = ns.Tween(0.45, function(_, raw)
			self.flash:SetAlpha(a0 * (1 - raw))
		end, function()
			self.flash:SetAlpha(0)
			self.flashTw = nil
		end, Ease.linear, self)
	end
	-- (1.14.0, a player's word: the lights of a bar can be turned off, UI/BoosterBar.lua: calm, the light no longer
	-- passes over it and its spark stays still)
	function f:SetCalm(on)
		self.calm = on and true or nil
		self.calmSet = nil
	end
	-- (each bar its own moment for the light that passes over it)
	H.phase = CuratorOctoFull.Mod(((H.phase or 0) + 1.37) , 3)
	f.t = H.phase
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		if self.calm then
			if not self.calmSet then
				self.calmSet = true
				self.shine:SetAlpha(0)
				self.tip:SetAlpha(0.7)
				CuratorOctoFull.SetRotation(self.tip, 0)
			end
			return
		end
		self.t = self.t + elapsed
		-- the light passes over the fill every three seconds
		local cyc = CuratorOctoFull.Mod(self.t , 3)
		if cyc < 1.1 and self.p > 0.04 then
			local u = cyc / 1.1
			local x = -self.h * 2 + (self.w * self.p + self.h * 4) * u
			self.shine:ClearAllPoints()
			self.shine:SetPoint("CENTER", self.clip, "LEFT", x, 0)
			self.shine:SetAlpha(math.sin(math.pi * u) * 0.75)
		else
			self.shine:SetAlpha(0)
		end
		self.tip:SetAlpha(0.55 + 0.35 * math.sin(self.t * 5))
		CuratorOctoFull.SetRotation(self.tip, self.t * 1.5)
	end)
	f:SetProgress(0)
	return f
end

-------------------------------------------------------------------------------
-- The button to claim
-------------------------------------------------------------------------------
-- Gold, rounded; lit under the mouse, it breathes while b:SetPulse(true).
function H.ClaimButton(parent, width, height, label)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, width, height)
	b.glow = b:CreateTexture(nil, "BACKGROUND")
	b.glow:SetTexture(MEDIA .. "ClaimGlow")
	b.glow:SetBlendMode("ADD")
	b.glow:SetPoint("TOPLEFT", -height * 0.45, height * 0.3)
	b.glow:SetPoint("BOTTOMRIGHT", height * 0.45, -height * 0.3)
	b.glow:SetVertexColor(1, 0.78, 0.3)
	b.glow:SetAlpha(0)
	b.bg = b:CreateTexture(nil, "ARTWORK")
	b.bg:SetTexture(MEDIA .. "Claim")
	b.bg:SetAllPoints()
	b.hot = b:CreateTexture(nil, "ARTWORK", nil, 1)
	b.hot:SetTexture(MEDIA .. "ClaimHot")
	b.hot:SetAllPoints()
	b.hot:SetAlpha(0)
	local size = math.max(10, math.floor(height * 0.42 + 0.5))
	b.text = H.Text(b, size, nil, "OVERLAY")
	b.text:SetPoint("CENTER", 0, 1)
	b.text:SetTextColor(0.24, 0.11, 0.01)
	b.text:SetShadowColor(1, 0.95, 0.75, 0.55)
	b.text:SetShadowOffset(0, -1)
	b.pulse = false
	-- (a long label, in some languages: smaller until it fits the button)
	function b:SetLabel(t)
		local k = size
		ns.SetFont(self.text, k)
		self.text:SetText(t)
		while k > 8 and ns.TextWidth(self.text) > width - 18 do
			k = k - 0.5
			ns.SetFont(self.text, k)
		end
	end
	b:SetLabel(label or L["Claim"])
	function b:GetText()
		return self.text:GetText()
	end
	function b:SetPulse(on)
		self.pulse = on and true or false
		if not on then
			self.glow:SetAlpha(0)
		end
	end
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		if self:IsEnabled() then
			self.hot:SetAlpha(1)
		end
		if self.tip then
			self.tip(self)
		end
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function(self)
		self.hot:SetAlpha(0)
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnMouseDown", function(self)
		if self:IsEnabled() then
			self.text:SetPoint("CENTER", 1, 0)
		end
	end)
	CuratorOctoFull.SetScript(b, "OnMouseUp", function(self)
		self.text:SetPoint("CENTER", 0, 1)
	end)
	local enable = b.SetEnabled or function(button, on)
        if on then button:Enable() else button:Disable() end
    end
	function b:SetEnabled(on)
		enable(self, on)
		self.bg:SetDesaturated(not on)
		self.bg:SetAlpha(on and 1 or 0.55)
		self.text:SetAlpha(on and 1 or 0.6)
		if not on then
			self.hot:SetAlpha(0)
			self.glow:SetAlpha(0)
		end
	end
	b.t = 0
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self, elapsed)
		if self.pulse and self:IsEnabled() then
			self.t = self.t + elapsed
			self.glow:SetAlpha(0.35 + 0.35 * math.sin(self.t * 4))
		end
	end)
	return b
end

-------------------------------------------------------------------------------
-- The badge of the rewards waiting
-------------------------------------------------------------------------------
-- badge:SetCount(n): hidden at 0, "9+" past 9; a pop when the count grows.
function H.Badge(parent, size)
	local b = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(b, size, size)
	b.tex = b:CreateTexture(nil, "OVERLAY")
	b.tex:SetTexture(MEDIA .. "Badge")
	b.tex:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.tex, size, size)
	b.text = H.Text(b, math.max(8, math.floor(size * 0.52 + 0.5)), "OUTLINE", "OVERLAY", 2)
	b.text:SetPoint("CENTER", 0, 0)
	b.text:SetTextColor(1, 1, 1)
	b.n = 0
	b:Hide()
	function b:SetCount(n)
		n = n or 0
		local grew = n > (self.n or 0)
		self.n = n
		CuratorOctoFull.SetShown(self, n > 0)
		self.text:SetText(n > 9 and "9+" or tostring(n))
		if grew and n > 0 then
			if self.tw then
				ns.CancelTween(self.tw)
			end
			local size0 = self:GetWidth()
			self.tw = ns.Tween(0.35, function(e)
				local k = 1 + 0.45 * math.sin(math.pi * e)
				CuratorOctoFull.SetSize(self.tex, size0 * k, size0 * k)
			end, function()
				CuratorOctoFull.SetSize(self.tex, size0, size0)
				self.tw = nil
			end, Ease.linear, self)
		end
	end
	return b
end

-------------------------------------------------------------------------------
-- The emblem of a rank
-------------------------------------------------------------------------------
-- emblem:SetRank(r); the light of the metal breathes behind the ranks with wings and beyond.
function H.Emblem(parent, size)
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, size, size)
	f.glow = f:CreateTexture(nil, "BACKGROUND")
	f.glow:SetTexture(MEDIA .. "Glow")
	f.glow:SetBlendMode("ADD")
	f.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(f.glow, size * 1.25, size * 1.25)
	f.glow:SetAlpha(0)
	f.tex = f:CreateTexture(nil, "ARTWORK")
	f.tex:SetAllPoints()
	f.rank = 1
	function f:SetRank(r)
		r = math.max(1, math.min(CuratorOctoFull.Length(ns.Level.RANKS), r or 1))
		self.rank = r
		self.tex:SetTexture(ns.Level.Emblem(r))
		local c = ns.Level.RANKS[r].light
		self.glow:SetVertexColor(c[1], c[2], c[3])
		CuratorOctoFull.SetShown(self.glow, r >= 7)
	end
	H.phase = CuratorOctoFull.Mod(((H.phase or 0) + 2.11) , 6)
	f.t = H.phase
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		if self.rank >= 7 then
			self.t = self.t + elapsed
			self.glow:SetAlpha(0.32 + 0.16 * math.sin(self.t * 2.2))
		end
	end)
	f:SetRank(1)
	return f
end

-------------------------------------------------------------------------------
-- What flies from a reward to where it goes
-------------------------------------------------------------------------------
local layer

-- The centre of a region (or of a point { x, y } of the screen), in the points of the screen.
local function Where(r)
	if type(r) == "table" and r.GetCenter then
		local x, y = r:GetCenter()
		if not x then
			return nil
		end
		local k = r:GetEffectiveScale() / UIParent:GetEffectiveScale()
		return x * k, y * k
	end
	return r[1], r[2]
end
H.Where = Where

local function Layer()
	if layer then
		return layer
	end
	layer = CreateFrame("Frame", nil, UIParent)
	layer:SetAllPoints()
	layer:SetFrameStrata("FULLSCREEN_DIALOG")
	layer:SetFrameLevel(450)
	layer.pool = {}
	layer.sparks = ns.Particles:New(layer, 90, "Spark")
	return layer
end

-- An icon (a texture path) flies from a region to another along a curve over size points, in dur
-- seconds, its trail of sparks behind it (colour), and done() when it lands. The icon flies above
-- everything (the album, a booster, the screen of a level). shape: { coords = its part of the
-- texture, ratio = its height for a width of 1 } (a card).
function H.Fly(icon, from, to, size, dur, done, color, delay, shape)
	local lay = Layer()
	local x0, y0 = Where(from)
	local x1, y1 = Where(to)
	if not (x0 and x1) then
		if done then
			done()
		end
		return
	end
	local t = CuratorOctoFull.Remove(lay.pool)
	if not t then
		t = lay:CreateTexture(nil, "OVERLAY")
	end
	t:SetTexture(icon)
	local tc = shape and shape.coords
	if tc then
		t:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
	else
		t:SetTexCoord(0, 1, 0, 1)
	end
	local ratio = shape and shape.ratio or 1
	CuratorOctoFull.SetSize(t, size, size * ratio)
	t:SetAlpha(0)
	t:Show()
	local W, Hh = lay:GetWidth(), lay:GetHeight()
	-- the curve: up and over toward its target
	local cx, cy = (x0 + x1) / 2 + (y1 - y0) * 0.15, math.max(y0, y1) + 90
	color = color or { 1, 0.85, 0.5 }
	local last = 0
	ns.Tween(dur, function(e, raw)
		local x = (1 - e) ^ 2 * x0 + 2 * (1 - e) * e * cx + e * e * x1
		local y = (1 - e) ^ 2 * y0 + 2 * (1 - e) * e * cy + e * e * y1
		t:ClearAllPoints()
		t:SetPoint("CENTER", lay, "BOTTOMLEFT", x, y)
		local k = 1 + 0.35 * math.sin(math.pi * raw) - 0.25 * raw
		CuratorOctoFull.SetSize(t, size * k, size * k * ratio)
		t:SetAlpha(math.min(1, raw * 6))
		if raw - last > 0.06 then
			last = raw
			lay.sparks:Burst(x - W / 2, y - Hh / 2, color, 2, 30, 0.45, size * 0.4)
		end
	end, function()
		t:Hide()
		CuratorOctoFull.Insert(lay.pool, t)
		lay.sparks:Burst(x1 - W / 2, y1 - Hh / 2, color, 10, 90, 0.5, size * 0.45)
		if done then
			done()
		end
	end, Ease.inOutQuad, lay, delay)
end

-- A burst of light at a region (a reward landing, a stamp).
function H.Burst(at, color, n, speed, size)
	local lay = Layer()
	local x, y = Where(at)
	if x then
		lay.sparks:Burst(x - lay:GetWidth() / 2, y - lay:GetHeight() / 2, color or { 1, 0.85, 0.5 }, n or 14, speed or 110, 0.6, size or 16)
	end
end

-------------------------------------------------------------------------------
-- The sections of a page, on its left (the quests, the profile)
-------------------------------------------------------------------------------
-- A button of a section: dark, its icon, its name, a count on its right and the badge of its rewards
-- waiting; lit in gold when chosen. b:Paint(on, label, count, claim, grey).
function H.NavButton(parent, width, height)
	local S = ns.Skin
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, width, height)
	b.width = width
	b.bg = H.Sliced(b, "QuestCard", height, 0, "BACKGROUND")
	b.glow = H.Sliced(b, "QuestGlow", height, H.GlowOut(height), "BORDER", 0, "ADD")
	H.Each(b.glow, "SetVertexColor", 1, 0.8, 0.32)
	H.Each(b.glow, "SetAlpha", 0)
	b.accent = b:CreateTexture(nil, "BORDER", nil, 2)
	b.accent:SetTexture(MEDIA .. "QuestAccent")
	b.accent:SetBlendMode("ADD")
	b.accent:SetVertexColor(1, 0.8, 0.32)
	CuratorOctoFull.SetSize(b.accent, 10, height - 6)
	b.accent:SetPoint("LEFT", 1, 0)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 3, -3)
	b.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.08)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, 22, 22)
	b.icon:SetPoint("LEFT", 10, 0)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", 38, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	b.count = S.Text(b, "GameFontHighlightSmall", "RIGHT")
	b.badge = H.Badge(b, 20)
	b.badge:SetPoint("RIGHT", -7, 0)
	function b:Paint(on, label, count, claim, grey)
		count, claim = count or "", claim or 0
		self.badge:SetCount(claim)
		self.count:SetText(count)
		self.count:ClearAllPoints()
		if claim > 0 then
			self.count:SetPoint("RIGHT", self.badge, "LEFT", -4, 0)
		else
			self.count:SetPoint("RIGHT", -10, 0)
		end
		if grey then
			self.count:SetTextColor(0.55, 0.55, 0.55)
		else
			self.count:SetTextColor(0.85, 0.85, 0.88)
		end
		local room = self.width - 38 - 8 - (count ~= "" and (ns.TextWidth(self.count) + 6) or 0) - (claim > 0 and 26 or 2)
		S.SetFontObject(self.text, "GameFontNormal")
		self.text:SetWidth(room)
		self.text:SetText(label)
		if ns.TextWidth(self.text) > room then
			S.Fit(self.text, label, room, 12, 8)
		end
		H.Each(self.glow, "SetAlpha", on and 0.7 or 0)
		CuratorOctoFull.SetShown(self.accent, on and true or false)
		if on then
			self.text:SetTextColor(1, 1, 1)
		else
			self.text:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
		end
	end
	return b
end

-- The level of the collector in a box (under the sections of a page): the emblem of its rank, the
-- level and the rank beside it, the experience in a bar and what is left of it. box:Paint(xp) (nil: a
-- level not known, an older Curator).
function H.LevelBox(parent, width, height)
	local S = ns.Skin
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, width, height)
	H.Panel(f, height)
	f.title = S.Text(f, "GameFontNormal")
	f.title:SetPoint("TOP", 0, -12)
	f.title:SetText(L["Collector level"])
	f.emblem = H.Emblem(f, 48)
	f.emblem:SetPoint("TOPLEFT", 12, -34)
	f.level = H.Text(f, 18, "OUTLINE")
	f.level:SetPoint("LEFT", f.emblem, "RIGHT", 6, 4)
	f.level:SetTextColor(1, 0.92, 0.7)
	f.rank = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.rank:SetPoint("TOPLEFT", f.level, "BOTTOMLEFT", 0, -3)
	f.xp = H.XPBar(f, width - 28, 14)
	f.xp:SetPoint("BOTTOM", 0, 34)
	f.note = S.Text(f, "GameFontHighlightSmall")
	f.note:SetWidth(width - 20)
	CuratorOctoFull.SetWordWrap(f.note, true)
	f.note:SetTextColor(0.62, 0.62, 0.68)
	function f:Paint(xp)
		local LV = ns.Level
		local known = xp ~= nil
		CuratorOctoFull.SetShown(self.emblem, known)
		CuratorOctoFull.SetShown(self.xp, known)
		self.note:ClearAllPoints()
		if not known then
			self.level:SetText("")
			self.rank:SetText("")
			self.note:SetPoint("CENTER", 0, -8)
			self.note:SetText(L["Level unknown (an older Curator)"])
			return
		end
		self.note:SetPoint("TOP", self.xp, "BOTTOM", 0, -6)
		local level, into, need = LV.Of(xp)
		local r, rank = LV.RankOf(level)
		if self.emblem.rank ~= r or not self.emblem.painted then
			self.emblem.painted = true
			self.emblem:SetRank(r)
		end
		self.level:SetText(string.format(L["Level %d"], level))
		local c = rank.color
		self.rank:SetText(string.format(("|cff%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5)) .. L[rank.name] .. "|r")
		self.xp:SetProgress(need and into / need or 1)
		self.xp:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
		self.note:SetText(need and string.format(L["%s XP to level %d"], ns.Num(need - into), level + 1) or string.format(L["Total: %s XP"], ns.Num(xp)))
	end
	return f
end

-------------------------------------------------------------------------------
-- A booster, standing
-------------------------------------------------------------------------------
-- The booster of an album: its body and its crimped top, the light of its album behind it, its shadow,
-- the glint that sweeps over it now and then; its name on its band when named. pack:SetSeries(s);
-- pack:SetLift(dy) raises it (its shadow stays).
function H.Pack(parent, width, named)
	local h = width * 2
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, width, h)
	f.w, f.h = width, h
	f.glow = f:CreateTexture(nil, "BACKGROUND")
	f.glow:SetTexture(MEDIA .. "Glow")
	f.glow:SetBlendMode("ADD")
	f.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(f.glow, width * 2.8, h * 1.7)
	f.glow:SetAlpha(0.32)
	f.shadow = f:CreateTexture(nil, "BACKGROUND", nil, 1)
	f.shadow:SetTexture(MEDIA .. "Shadow")
	CuratorOctoFull.SetSize(f.shadow, width * 1.5, h * 1.25)
	f.shadow:SetPoint("CENTER", width * 0.06, -h * 0.03)
	f.shadow:SetAlpha(0.75)
	-- (the pack itself, on a frame of its own: it rises over its shadow)
	local p = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(p, width, h)
	p:SetPoint("CENTER")
	f.art = p
	f.body = p:CreateTexture(nil, "ARTWORK")
	f.body:SetAllPoints()
	f.top = p:CreateTexture(nil, "ARTWORK", nil, 1)
	f.top:SetPoint("TOPLEFT")
	f.top:SetPoint("TOPRIGHT")
	f.top:SetHeight(h * 64 / 512)
	-- the glint, cut to the shape of the pack (where the client can cut it)
	if p.CreateMaskTexture and p.SetClipsChildren then
		local clip = CreateFrame("Frame", nil, p)
		clip:SetAllPoints()
		CuratorOctoFull.SetClipsChildren(clip, true)
		clip.mask = CuratorOctoFull.CreateMaskTexture(clip)
		clip.mask:SetAllPoints(p)
		f.sheen = clip:CreateTexture(nil, "OVERLAY")
		f.sheen:SetTexture(MEDIA .. "Sheen")
		f.sheen:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(f.sheen, h * 1.6, h * 1.6)
		f.sheen:SetAlpha(0)
		CuratorOctoFull.AddMaskTexture(f.sheen, clip.mask)
		f.clip = clip
	end
	if named then
		-- (the band of the name spans 336 to 392 of the 512 points of the texture)
		f.name = H.Text(p, math.max(8, math.floor(width * 0.085 + 0.5)), "", "OVERLAY", 2)
		f.name:SetPoint("CENTER", p, "TOP", 0, -h * 364 / 512 + 1)
		f.name:SetTextColor(1, 0.86, 0.52)
		CuratorOctoFull.SetWordWrap(f.name, false)
	end
	function f:SetSeries(s)
		local pack = (s and s.pack) or "PackElwynn"
		self.series = s
		self.body:SetTexture(MEDIA .. pack .. "Bottom")
		self.top:SetTexture(MEDIA .. pack .. "Top")
		if self.clip then
			self.clip.mask:SetTexture(MEDIA .. pack .. "Bottom", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		end
		local g = (s and s.glow) or { 1, 0.8, 0.4 }
		self.glow:SetVertexColor(g[1], g[2], g[3])
		if self.name then
			local k = math.max(8, math.floor(width * 0.085 + 0.5))
			ns.SetFont(self.name, k)
			self.name:SetText(s and ns.Collection:SeriesName(s) or "")
			while k > 6 and ns.TextWidth(self.name) > width * 0.8 do
				k = k - 0.5
				ns.SetFont(self.name, k)
			end
		end
	end
	function f:SetLift(dy)
		self.lift = dy or 0
		p:ClearAllPoints()
		p:SetPoint("CENTER", 0, self.lift)
	end
	-- the glint: a sweep of 1.2 seconds now and then (each pack its own moment)
	H.phase = CuratorOctoFull.Mod(((H.phase or 0) + 1.9) , 5)
	f.t = H.phase
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		if self.sheen then
			local cyc = CuratorOctoFull.Mod(self.t , 5)
			if cyc < 1.2 then
				local u = cyc / 1.2
				self.sheen:ClearAllPoints()
				self.sheen:SetPoint("CENTER", self.art, "CENTER", -self.w * 1.2 + self.w * 2.4 * u, self.h * 0.5 - self.h * u)
				self.sheen:SetAlpha(math.sin(math.pi * u) * 0.55)
			else
				self.sheen:SetAlpha(0)
			end
		end
		if self.bob then
			self:SetLift((self.lift0 or 0) + math.sin(self.t * 1.6) * self.bob)
		end
	end)
	return f
end

-- The round button of the information (an "i" of gold in a ring): b.tip(b) on its tooltip, b:SetScript
-- ("OnClick") as any button.
function H.InfoButton(parent, size)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, size, size)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetTexture(MEDIA .. "CircleMask")
	b.bg:SetVertexColor(0.05, 0.06, 0.12)
	b.bg:SetAlpha(0.92)
	b.bg:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.bg, size * 0.86, size * 0.86)
	b.ring = b:CreateTexture(nil, "ARTWORK")
	b.ring:SetTexture(MEDIA .. "IconRing")
	b.ring:SetAllPoints()
	b.text = H.Text(b, math.max(9, math.floor(size * 0.62 + 0.5)), "", "OVERLAY")
	b.text:SetPoint("CENTER", 0.5, 0)
	b.text:SetText("i")
	b.text:SetTextColor(1, 0.86, 0.45)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetTexture(MEDIA .. "Glow")
	b.hl:SetBlendMode("ADD")
	b.hl:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.hl, size * 1.6, size * 1.6)
	b.hl:SetVertexColor(1, 0.82, 0.4)
	b.hl:SetAlpha(0.7)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		if self.tip then
			self.tip(self)
		end
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end
