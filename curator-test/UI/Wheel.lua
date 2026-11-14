local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud

-------------------------------------------------------------------------------
-- (1.14.0) The Darkmoon Wheel, a summit of the Gambler (Talents.lua: TL:Spin), on the screen: once a day, the wheel of
-- the Faire spun. Its slices as its parts are (Darkmoon Fortune: fewer on nothing, more on the boosters): 36 of them,
-- each part so many, a line where two parts meet; its icons on them, the pointer on its top. What it gives is drawn
-- when the button is clicked (and given at once: closed while it turns, nothing is lost); the wheel then turns and stops
-- on it, slower and slower, a tick at each slice that passes the pointer.
-------------------------------------------------------------------------------
local WU = {}
ns.WheelUI = WU

local W, H = 420, 590
local WHEEL = 280
local SLICES = 36
local TURNS = 5
local SPIN_TIME = 5.6
local GOLD = S.GOLD
local DIM = { 0.72, 0.72, 0.76 }
-- the parts: their colour, their icon, their words
local PART = {
	nothing = { color = { 0.44, 0.4, 0.52 }, icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", label = "Nothing" },
	rubies = { color = { 0.86, 0.2, 0.28 }, label = "%d rubies" },
	zone = { color = { 0.3, 0.68, 0.42 }, pack = "zone", label = "A booster of a zone" },
	zone2 = { color = { 0.3, 0.55, 0.95 }, pack = "zone", two = true, label = "Two boosters of a zone" },
	dungeon = { color = { 0.95, 0.7, 0.22 }, pack = "dungeon", label = "A booster of a dungeon" },
}
WU.PART = PART

local function TL()
	return ns.Talents
end

local function IconOf(key)
	local p = PART[key]
	if p.pack then
		return Hud.PackIcon(p.pack)
	elseif key == "rubies" then
		return ns.Rubies and ns.Rubies.ICON or "Interface\\Icons\\INV_Misc_Gem_Ruby_01"
	end
	return p.icon
end

function WU:Label(key)
	local p = PART[key]
	if not p then
		return ""
	end
	if key == "rubies" then
		return string.format(L[p.label], TL().WHEEL_RUBIES)
	end
	return L[p.label]
end

-- The slices of each part: as many as its share of 36, one at least; the largest part takes what is left over.
function WU:Layout(parts)
	local counts, total, big = {}, 0, 1
	for i, p in ipairs(parts) do
		local c = (p[2] > 0) and math.max(1, math.floor(p[2] * SLICES / 100 + 0.5)) or 0
		counts[i] = c
		total = total + c
		if c > counts[big] then
			big = i
		end
	end
	counts[big] = counts[big] + (SLICES - total)
	-- (the first slice of each part, from the top, clockwise)
	local first, at = {}, 0
	for i, c in ipairs(counts) do
		first[i] = at
		at = at + c
	end
	return counts, first
end

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------
function WU:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorWheel", W, H)
	tinsert(UISpecialFrames, "CuratorWheel")
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	f:Hide()
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01")
	end
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			WU:Hide()
		end)
	end
	f.say = S.Text(f, "GameFontHighlightSmall")
	f.say:SetPoint("TOP", 20, -32)
	f.say:SetWidth(W - 110)
	f.say:SetWordWrap(true)
	f.say:SetTextColor(0.9, 0.84, 0.7)
	-- the wheel: its slices, the lines between its parts, its icons, its rim, its hub, its pointer
	local wh = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(wh, WHEEL, WHEEL)
	wh:SetPoint("TOP", 0, -100)
	f.wheel = wh
	wh.light = wh:CreateTexture(nil, "BACKGROUND")
	wh.light:SetTexture(MEDIA .. "Glow")
	wh.light:SetBlendMode("ADD")
	wh.light:SetPoint("CENTER")
	CuratorOctoFull.SetSize(wh.light, WHEEL * 1.6, WHEEL * 1.6)
	wh.light:SetVertexColor(0.8, 0.52, 1)
	wh.light:SetAlpha(0.35)
	wh.slices = {}
	for i = 1, SLICES do
		local t = wh:CreateTexture(nil, "ARTWORK", nil, 1)
		t:SetTexture(MEDIA .. "WheelWedge")
		t:SetAllPoints()
		wh.slices[i] = t
	end
	wh.lines = {}
	for i = 1, 6 do
		local t = wh:CreateTexture(nil, "ARTWORK", nil, 3)
		t:SetTexture(MEDIA .. "WheelLine")
		t:SetAllPoints()
		t:Hide()
		wh.lines[i] = t
	end
	wh.icons = {}
	for i = 1, 6 do
		local ic = wh:CreateTexture(nil, "OVERLAY", nil, 1)
		CuratorOctoFull.SetSize(ic, 30, 30)
		ic:Hide()
		local x2 = wh:CreateFontString(nil, "OVERLAY")
		ns.SetFont(x2, 13, "OUTLINE")
		x2:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", 6, -4)
		x2:SetText("x2")
		x2:Hide()
		ic.two = x2
		wh.icons[i] = ic
	end
	wh.rim = wh:CreateTexture(nil, "OVERLAY", nil, 4)
	wh.rim:SetTexture(MEDIA .. "WheelRim")
	wh.rim:SetPoint("CENTER")
	CuratorOctoFull.SetSize(wh.rim, WHEEL * 1.12, WHEEL * 1.12)
	wh.hub = wh:CreateTexture(nil, "OVERLAY", nil, 5)
	wh.hub:SetTexture(MEDIA .. "WheelHub")
	wh.hub:SetPoint("CENTER")
	CuratorOctoFull.SetSize(wh.hub, 64, 64)
	wh.pointer = wh:CreateTexture(nil, "OVERLAY", nil, 7)
	wh.pointer:SetTexture(MEDIA .. "WheelPointer")
	CuratorOctoFull.SetSize(wh.pointer, 30, 60)
	wh.pointer:SetPoint("BOTTOM", wh, "TOP", 0, -22)
	-- the light of the part it stopped on, under the pointer
	wh.win = wh:CreateTexture(nil, "OVERLAY", nil, 6)
	wh.win:SetTexture(MEDIA .. "Glow")
	wh.win:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(wh.win, 120, 120)
	wh.win:SetPoint("CENTER", wh, "TOP", 0, -34)
	wh.win:SetAlpha(0)
	-- the parts and their chances, under the wheel
	f.rows = {}
	local order = { "nothing", "rubies", "zone", "zone2", "dungeon" }
	for i, key in ipairs(order) do
		local r = CreateFrame("Frame", nil, f)
		CuratorOctoFull.SetSize(r, W - 80, 18)
		r:SetPoint("TOPLEFT", 40, -(100 + WHEEL + 22) - (i - 1) * 19)
		r.swatch = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.swatch, 12, 12)
		r.swatch:SetPoint("LEFT", 0, 0)
		CuratorOctoFull.ColorTexture(r.swatch, PART[key].color[1], PART[key].color[2], PART[key].color[3], 1)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.icon, 16, 16)
		r.icon:SetPoint("LEFT", r.swatch, "RIGHT", 6, 0)
		r.icon:SetTexture(IconOf(key))
		r.text = S.Text(r, "GameFontHighlight", "LEFT")
		r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
		r.pct = S.Text(r, "GameFontHighlight", "RIGHT")
		r.pct:SetPoint("RIGHT", 0, 0)
		r.key = key
		f.rows[i] = r
	end
	f.result = Hud.Text(f, 16, "OUTLINE")
	f.result:SetPoint("TOP", 0, -(100 + WHEEL + 22) - 5 * 19 - 8)
	f.result:SetWidth(W - 40)
	f.spin = Hud.ClaimButton(f, 220, 34, L["Spin the wheel"])
	f.spin:SetPoint("BOTTOM", 0, 20)
	CuratorOctoFull.SetScript(f.spin, "OnClick", function()
		WU:Spin()
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		WU:Tick(elapsed)
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		-- (closed while it turns: it stops where it was going, what it gave is given)
		if WU.anim then
			WU.angle = CuratorOctoFull.Mod(WU.anim.to , 360)
			WU.anim = nil
		end
	end)
	self.frame = f
	self.angle = self.angle or 0
	return f
end

function WU:Open()
	local T = TL()
	if not (T and T:Has("wheel")) then
		return false
	end
	local f = self:Build()
	f:SetTitle(T:Name("wheel"))
	f:Show()
	f:Raise()
	ns.Play(ns.SND.open)
	self:Paint()
	return true
end

function WU:Hide()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
		ns.Play(ns.SND.close)
	end
end

-------------------------------------------------------------------------------
-- What it shows
-------------------------------------------------------------------------------
-- The slices and the icons at an angle of the wheel (degrees, clockwise).
function WU:PaintWheel(angle)
	local f = self.frame
	local wh = f.wheel
	local T = TL()
	local parts = T:WheelParts()
	local counts, first = self:Layout(parts)
	self.parts, self.counts, self.first = parts, counts, first
	local k = 0
	for i, p in ipairs(parts) do
		local c = PART[p[1]].color
		for j = 1, counts[i] do
			k = k + 1
			local t = wh.slices[k]
			local shade = (CuratorOctoFull.Mod(j , 2) == 0) and 0.86 or 1
			t:SetVertexColor(c[1] * shade, c[2] * shade, c[3] * shade)
			-- (a texture turns the other way round: counter-clockwise)
			CuratorOctoFull.SetRotation(t, -math.rad((k - 1) * (360 / SLICES) + angle))
			t:Show()
		end
	end
	for x = k + 1, SLICES do
		wh.slices[x]:Hide()
	end
	-- the lines where two parts meet, and the icon of each part in its middle
	local r = WHEEL * 0.34
	for i, p in ipairs(parts) do
		local line = wh.lines[i]
		local ic = wh.icons[i]
		if counts[i] > 0 then
			local a0 = first[i] * (360 / SLICES) + angle
			CuratorOctoFull.SetRotation(line, -math.rad(a0))
			line:Show()
			local mid = math.rad(a0 + counts[i] * (360 / SLICES) / 2)
			ic:ClearAllPoints()
			ic:SetPoint("CENTER", wh, "CENTER", r * math.sin(mid), r * math.cos(mid))
			ic:SetTexture(IconOf(p[1]))
			local small = counts[i] <= 2
			CuratorOctoFull.SetSize(ic, small and 22 or 30, small and 22 or 30)
			ic:Show()
			CuratorOctoFull.SetShown(ic.two, PART[p[1]].two and true or false)
		else
			line:Hide()
			ic:Hide()
			ic.two:Hide()
		end
	end
	for i = CuratorOctoFull.Length(parts) + 1, CuratorOctoFull.Length(wh.lines) do
		wh.lines[i]:Hide()
	end
	for i = CuratorOctoFull.Length(parts) + 1, CuratorOctoFull.Length(wh.icons) do
		wh.icons[i]:Hide()
		wh.icons[i].two:Hide()
	end
end

function WU:Paint()
	local f = self.frame
	if not (f and f:IsShown()) then
		return
	end
	local T = TL()
	if not self.anim then
		self:PaintWheel(self.angle or 0)
	end
	local parts = T:WheelParts()
	local by = {}
	for _, p in ipairs(parts) do
		by[p[1]] = p[2]
	end
	for _, r in ipairs(f.rows) do
		r.text:SetText(self:Label(r.key))
		local v = by[r.key] or 0
		local s = (math.abs(v - math.floor(v + 0.5)) < 0.05) and tostring(math.floor(v + 0.5)) or (string.gsub(string.format(("%.1f"), v), "%.", L["."]))
		r.pct:SetText(string.format(L["%s%%"], s))
		r.pct:SetTextColor(r.key == self.got and 1 or 0.85, r.key == self.got and 0.82 or 0.85, r.key == self.got and 0.3 or 0.88)
	end
	local ready = T:Ready("wheel")
	if T:Has("darkmoon") then
		f.say:SetText(L["\"Step right up! Darkmoon Fortune is with you: the wheel stops less often on nothing.\""])
	else
		f.say:SetText(L["\"Step right up, step right up! Once a day, the wheel of the Faire for you.\""])
	end
	if self.anim then
		f.spin:SetEnabled(false)
		f.spin:SetPulse(false)
		return
	end
	f.spin:SetEnabled(ready)
	f.spin:SetPulse(ready)
	if ready then
		f.spin:SetLabel(L["Spin the wheel"])
		if not self.got then
			f.result:SetText("")
		end
	else
		f.spin:SetLabel(string.format(L["Again in %s"], ns.Duration(T:Left("wheel"))))
		local today = T:Day().wheelGot
		if not self.got and today and PART[today] then
			f.result:SetText(string.format(L["Today: %s"], self:Label(today)))
			f.result:SetTextColor(0.85, 0.85, 0.88)
		end
	end
end

-------------------------------------------------------------------------------
-- The spin
-------------------------------------------------------------------------------
function WU:Spin()
	local T = TL()
	if self.anim or not (T and T:Ready("wheel")) then
		ns.Play(ns.SND.close)
		return
	end
	if ns.Beta and ns.Beta.Blocked and ns.Beta:Blocked() then
		return
	end
	-- (the slices as they are before the spin: where it stops is drawn among them)
	self:PaintWheel(self.angle or 0)
	local counts, first, parts = self.counts, self.first, self.parts
	local got = T:Spin()
	if not got then
		ns.Play(ns.SND.close)
		self:Paint()
		return
	end
	self.got = nil
	local at
	for i, p in ipairs(parts) do
		if p[1] == got then
			at = i
		end
	end
	-- a slice of that part, a little off its middle: its angle on the wheel brought under the pointer
	local step = 360 / SLICES
	local n = math.max(1, counts[at or 1] or 1)
	local slice = (first[at or 1] or 0) + math.random(n) - 1
	local inside = (0.2 + 0.6 * math.random()) * step
	local target = slice * step + inside
	local from = self.angle or 0
	-- (the wheel turns clockwise: the angle grows; it stops with that point at the top)
	local stop = CuratorOctoFull.Mod((360 - target) , 360)
	local to = from + TURNS * 360 + (CuratorOctoFull.Mod((stop - CuratorOctoFull.Mod(from , 360)) , 360))
	self.anim = { from = from, to = to, t = 0, got = got, last = math.floor(from / step), tick = 0 }
	local f = self.frame
	f.result:SetText("")
	f.wheel.win:SetAlpha(0)
	ns.Play(ns.SND.packShake)
	self:Paint()
end

local function EaseOut(x)
	return 1 - (1 - x) ^ 4
end

function WU:Tick(elapsed)
	local a = self.anim
	local f = self.frame
	if not a then
		local wh = f and f.wheel
		if wh and self.got then
			self.glowT = (self.glowT or 0) + (elapsed or 0)
			wh.win:SetAlpha(0.45 + 0.3 * math.sin(self.glowT * 4))
		end
		return
	end
	a.t = a.t + (elapsed or 0)
	local x = math.min(1, a.t / SPIN_TIME)
	local angle = a.from + (a.to - a.from) * EaseOut(x)
	self:PaintWheel(angle)
	-- (a tick at each slice that passes the pointer, not too many of them)
	local step = 360 / SLICES
	local now = math.floor(angle / step)
	a.tick = a.tick + (elapsed or 0)
	if now ~= a.last and a.tick >= 0.06 then
		a.last, a.tick = now, 0
		ns.Play(ns.SND.click)
	end
	if x >= 1 then
		self.angle = CuratorOctoFull.Mod(a.to , 360)
		self.anim = nil
		self:Landed(a.got)
	end
end

-- Stopped on what it gave: said, its light, its sound.
function WU:Landed(got)
	local f = self.frame
	self.got = got
	local p = PART[got]
	local col = p and p.color or { 1, 1, 1 }
	f.wheel.win:SetVertexColor(col[1], col[2], col[3])
	self.glowT = 0
	if got == "nothing" then
		f.result:SetText(L["Nothing this time. Come back tomorrow!"])
		f.result:SetTextColor(0.8, 0.78, 0.86)
		ns.Play(ns.SND.cardFlip)
	else
		f.result:SetText(string.format(L["%s!"], self:Label(got)))
		f.result:SetTextColor(1, 0.82, 0.3)
		if got == "rubies" then
			ns.Play(ns.SND.coins)
		elseif got == "dungeon" then
			ns.Play(ns.SND.levelSting)
		else
			ns.Play(ns.SND.claim)
		end
		Hud.Burst(f.wheel, col, got == "dungeon" and 34 or 20, 160, 18)
		if got ~= "rubies" then
			ns.Print(string.format(L["Darkmoon Wheel: %s, to put in the album you want (the inventory, Boosters)."], self:Label(got)))
		end
	end
	self:Paint()
end

ns.On("TALENTS_CHANGED", function()
	if WU.frame and WU.frame:IsShown() and not (ns.Talents and ns.Talents:Has("wheel")) then
		WU.frame:Hide()
	end
end)
