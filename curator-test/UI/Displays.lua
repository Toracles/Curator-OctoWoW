local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local C = ns.Collection
local D = ns.Displays

-------------------------------------------------------------------------------
-- (1.13.0) The displays of boosters and the protective cases on the screen (Displays.lua).
-- * A display: its box in 3D (UI/Box3D.lua, 1.13.0 after its first test), the effigy of its album on it (its art, its
--   emblem, its name, the jewel of its kind), its sixteen boosters inside; in its case of acrylic when it is in one
--   (DU.Box).
-- * Inspected first (DU:Inspect, the boosters of the inventory, after the first test of 1.13.0): the room darkens,
--   the box comes down turning to face you and stays, turning slowly; a drag turns it, the mouse wheel brings it closer;
--   Open the display, or Back.
-- * Opened (DU:OpenDisplay, or Open the display when it is inspected): its seals tear, its lid swings open on the light
--   of its album, its boosters stand up in it, rise out of it one by one and fly down to the boosters of its album under
--   it, counted as they land; a click skips it (the boosters were in the album at once: nothing is lost).
-- * The boosters of the inventory: a button to its displays, album by album, with those in their case.
-- * The reseller: a tab of his displays, those of his shop (Displays.lua: D:ForSale, other ones every D.SHOP_DAYS days):
--   the box of the album chosen, big, turning (a drag turns it), the kind of each album, its price, when his shop
--   changes.
-- * A banker: a small window of Curator under the expert's, the protective cases of the displays, in and out (a booster
--   in its case no more since the first test of 1.13.0).
-------------------------------------------------------------------------------
local DU = {}
ns.DisplaysUI = DU

local B3 = ns.Box3D
local GOLD = S.GOLD
local DIM = { 0.66, 0.66, 0.7 }
local CASE_COLOR = { 0.66, 0.86, 1 }
local LIMITED = { 1, 0.64, 0.32 }
local ARM = 3 -- (seconds) a first click arms a button that spends rubies, a second one within confirms
local SCENE = {} -- the owner of the animations of an opening (all of them stopped when it ends)

-- (why something cannot be done, said)
local WHY = {
	none = "None of this album here.",
	cased = "In its case: take it out at a banker first.",
	closed = "Curator is closed: nothing can be done.",
	busy = "A display is being opened.",
	bank = "At a banker only.",
	rubies = "Not enough rubies.",
	album = "No display of this album.",
	event = "Only while its event lasts.",
	shop = "Not in his shop these days.",
	here = "At the reseller only.",
	-- (1.14.0, his word: an album unlocked only, Level.lua: LV:Unlocked)
	locked = "Album locked: win one of its boosters by playing first.",
}
DU.WHY = WHY
-- (1.14.0, after its test: a reroll opens nothing; its words name the main, Reroll.lua: already in the language of
-- the player, they come back as they are from the table of the words)
setmetatable(WHY, { __index = function(_, k)
	if k == "reroll" and ns.Reroll then
		return ns.Reroll:Why()
	end
end })

-- The kinds of displays: their words, their colours (Displays.lua: D.Kind).
local KIND = {
	zone = { label = "Zone", color = { 0.56, 0.86, 0.44 } },
	dungeon = { label = "Dungeon", color = { 0.66, 0.70, 1 } },
	raid = { label = "Raid", color = { 1, 0.46, 0.40 } },
	event = { label = "Limited edition", color = LIMITED },
}
DU.KIND = KIND

local function Name(s)
	return s and C:SeriesName(s) or "?"
end

local function Tint(s)
	return (s and s.glow) or { 1, 0.8, 0.4 }
end

local function Armed(b)
	return b.armed ~= nil and GetTime() - b.armed < ARM
end

-- The kind of a display, said in its colour.
local function KindText(s)
	local k = KIND[D.Kind(s) or "zone"] or KIND.zone
	local c = k.color
	return string.format(("|cff%02x%02x%02x%s|r"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5), L[k.label])
end
DU.KindText = KindText

-------------------------------------------------------------------------------
-- A display: its box of sixteen boosters, in 3D
-------------------------------------------------------------------------------
-- box:SetSeries(s), box:SetLid(k) (0: closed, 1: open), box:SetCased(on), box:SetCount(n), box:SetDim(on), its view, its
-- boosters (UI/Box3D.lua).
function DU.Box(parent, width)
	local f = B3.New(parent, width)
	-- how many (over its corner: at the bottom, or at the top when something stands at its foot)
	f.count = Hud.Text(f.caseG, math.max(11, math.floor(width * 0.075 + 0.5)), "OUTLINE", "OVERLAY", 7)
	f.count:SetDrawLayer("OVERLAY", 7)
	f.count:SetTextColor(1, 0.86, 0.45)
	function f:SetCount(n)
		self.count:SetText((n and n > 1) and ("x" .. n) or "")
	end
	function f:SetCountAt(where)
		self.count:ClearAllPoints()
		if where == "top" then
			self.count:SetPoint("CENTER", self, "TOPRIGHT", -width * 0.07, -width * 0.06)
		else
			self.count:SetPoint("CENTER", self, "BOTTOMRIGHT", -width * 0.07, width * 0.07)
		end
	end
	f:SetCountAt("bottom")
	return f
end

-- A box under the mouse: a glint over it, its lid lifted a little to show its light (unless it is in its case).
function DU:Peek(box)
	if not box or box.peeking then
		return
	end
	box:Glint(0.9)
	if box.cased or ns.Can3D() == false then
		return
	end
	box.peeking = true
	ns.Tween(0.9, function(_, raw)
		box:SetLid(0.1 * math.sin(math.pi * raw), true)
	end, function()
		box:SetLid(0, true)
		box.peeking = nil
	end, Ease.linear, box)
end

-------------------------------------------------------------------------------
-- A display opened: its ceremony
-------------------------------------------------------------------------------
local BOX_W, BOX_Y = 460, 40   -- the box, from the middle of the screen
local PILE_Y, PILE_W = -205, 56 -- the boosters of its album, under it
-- the moments (seconds): it comes down, it settles, its seals tear, its lid opens; its boosters rise (one every STEP),
-- fly down to the boosters of its album; the last one landed, the end
local INTRO, SETTLE, TEAR, LID, STEP, LIFT, FLY, OUTRO = 0.8, 0.45, 0.3, 0.75, 0.11, 0.26, 0.62, 1.4
local DROP = 170   -- (how high above its place it comes from)
local YAW1 = -0.24 -- (how it faces you once it has come down)
-- (inspected, after the first test of 1.13.0: the mouse wheel brings it closer, from ZOOM_MIN to ZOOM_MAX; opened then,
-- it turns back to face you in BACK seconds; its two buttons side by side, INSPECT_W wide)
local ZOOM_MIN, ZOOM_MAX, ZOOM_STEP = 0.85, 1.3, 0.09
local BACK = 0.45
local INSPECT_W = 380
local RISE_UP = 0.2 -- (how far a booster rises out of it before it flies: in widths of the box)
-- (the boosters out of the box: the front row first, from the middle out, a back one after each)
local RISE = { 12, 4, 13, 5, 11, 3, 14, 6, 10, 2, 15, 7, 9, 1, 16, 8 }

local function HideSprites(f)
	for _, sp in ipairs(f.sprites) do
		sp:Hide()
	end
end

-- The box where it is, from the middle of the screen (brought closer when it is inspected: its place the same).
local function PlaceBox(cer, y)
	cer.boxY = y
	local box = cer.f.box
	box:ClearAllPoints()
	box:SetPoint("CENTER", cer.f, "CENTER", 0, y / (box:GetScale() or 1))
end

function DU:Scene()
	if self.scene then
		return self.scene
	end
	local f = CreateFrame("Button", "CuratorDisplayScene", UIParent)
	f:SetAllPoints()
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(200)
	f:EnableMouse(true)
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(f, "OnClick", function()
		-- (1 November, his word: « SANS cliquer sur "Retour" impossible de retour »: inspected, a click does nothing, a
		-- right click no more; Back, ctl.back. Opened, a click skips its ceremony)
		local cer = DU.cer
		if cer and cer.inspect then
			return
		end
		DU:Skip()
	end)
	-- (the mouse wheel brings it closer while it is inspected)
	CuratorOctoFull.SetScript(f, "OnMouseWheel", function(_, delta)
		DU:Zoom(delta)
	end)
	-- (hidden another way, Escape: its end, as a click at its end; nothing is lost)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		if DU.cer then
			DU:Close(true)
		end
	end)
	if UISpecialFrames then
		CuratorOctoFull.Insert(UISpecialFrames, "CuratorDisplayScene")
	end
	f:Hide()
	f.dim = f:CreateTexture(nil, "BACKGROUND")
	f.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.dim, 0.01, 0.01, 0.02, 0.86)
	f.vig = f:CreateTexture(nil, "BACKGROUND", nil, 1)
	f.vig:SetAllPoints()
	f.vig:SetTexture(MEDIA .. "Vignette")
	f.rays = f:CreateTexture(nil, "BORDER")
	f.rays:SetTexture(MEDIA .. "Rays")
	f.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.rays, 860, 860)
	f.rays:SetPoint("CENTER", 0, BOX_Y + 70)
	f.rays:SetAlpha(0)
	-- (its light from above: from past the top of the screen, whatever its height, down to under the box)
	f.spot = f:CreateTexture(nil, "BORDER", nil, 1)
	f.spot:SetTexture(MEDIA .. "Spotlight")
	f.spot:SetBlendMode("ADD")
	f.spot:SetWidth(660)
	f.spot:SetPoint("TOP", f, "TOP", 0, 80)
	f.spot:SetPoint("BOTTOM", f, "CENTER", 0, BOX_Y - 150)
	f.spot:SetAlpha(0.3)
	f.title = S.Text(f, "GameFontNormalHuge")
	f.title:SetPoint("CENTER", 0, BOX_Y + 300)
	f.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.sub = S.Text(f, "GameFontHighlight")
	f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -8)
	f.sub:SetTextColor(0.88, 0.86, 0.8)
	f.box = DU.Box(f, BOX_W)
	f.box:SetPoint("CENTER", 0, BOX_Y)
	-- where its boosters fly to: the boosters of its album, a fan of three, counted
	local pile = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(pile, PILE_W * 3, PILE_W * 2.4)
	pile:SetPoint("CENTER", 0, PILE_Y)
	f.pile = pile
	f.pileL = B3.Pack(pile)
	f.pileR = B3.Pack(pile)
	f.pileL:SetFrameLevel(pile:GetFrameLevel() + 1)
	f.pileR:SetFrameLevel(pile:GetFrameLevel() + 1)
	f.pileL:Pose(-PILE_W * 0.46, 2, PILE_W * 0.9, 0, 0, 0.2)
	f.pileR:Pose(PILE_W * 0.46, 2, PILE_W * 0.9, 0, 0, -0.2)
	CuratorOctoFull.SetLight(f.pileL, 0.7)
	CuratorOctoFull.SetLight(f.pileR, 0.7)
	f.dest = Hud.Pack(pile, PILE_W, true)
	f.dest:SetPoint("CENTER")
	f.dest:SetFrameLevel(pile:GetFrameLevel() + 3)
	f.destCount = Hud.Text(f.dest.art, 26, "OUTLINE", "OVERLAY", 3)
	f.destCount:SetPoint("LEFT", f.dest.art, "RIGHT", PILE_W * 0.55, 0)
	f.destCount:SetTextColor(1, 0.86, 0.45)
	f.destLabel = S.Text(f, "GameFontHighlightSmall")
	f.destLabel:SetPoint("TOP", pile, "BOTTOM", 0, -4)
	f.destLabel:SetTextColor(DIM[1], DIM[2], DIM[3])
	f.hint = S.Text(f, "GameFontDisableSmall")
	f.hint:SetPoint("BOTTOM", 0, 50)
	f.hint:SetText(L["Click to skip"])
	-- (1.13.0, after its first test) inspected before it is opened: how many there are, Open the display, Back
	f.have = S.Text(f, "GameFontHighlight")
	f.have:SetPoint("TOP", f.sub, "BOTTOM", 0, -6)
	f.have:SetTextColor(1, 0.92, 0.75)
	f.have:Hide()
	local ctl = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(ctl, INSPECT_W, 40)
	ctl:SetPoint("CENTER", f, "CENTER", 0, PILE_Y - 44)
	ctl:SetFrameLevel(f:GetFrameLevel() + 30)
	ctl:Hide()
	f.ctl = ctl
	ctl.open = Hud.ClaimButton(ctl, 230, 34, L["Open the display"])
	ctl.open:SetPoint("LEFT", ctl, "LEFT", 0, 0)
	CuratorOctoFull.SetScript(ctl.open, "OnClick", function()
		DU:InspectOpen()
	end)
	ctl.open.tip = function(self)
		local cer = DU.cer
		if not cer then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Open the display"], 1, 1, 1)
		GameTooltip:AddLine(string.format(L["Its 16 boosters go to %s."], Name(cer.s)), GOLD[1], GOLD[2], GOLD[3], true)
		local _, why = D:CanOpen(cer.s)
		if why and WHY[why] then
			GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
		end
		GameTooltip:Show()
	end
	ctl.back = S.Button(ctl, L["Back"], 130, 26)
	ctl.back:SetPoint("RIGHT", ctl, "RIGHT", 0, 0)
	CuratorOctoFull.SetScript(ctl.back, "OnClick", function()
		ns.Play(ns.SND.close)
		DU:Close()
	end)
	-- (its sparks, its flash, the boosters on their way: above it all)
	local fx = CreateFrame("Frame", nil, f)
	fx:SetAllPoints()
	fx:SetFrameLevel(f:GetFrameLevel() + 40)
	f.fx = fx
	f.sparks = ns.Particles:New(fx, 160)
	f.twinkles = ns.Particles:New(fx, 36, "Twinkle")
	f.flash = fx:CreateTexture(nil, "OVERLAY")
	f.flash:SetTexture(MEDIA .. "Glow")
	f.flash:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.flash, BOX_W * 1.4, BOX_W * 0.75)
	f.flash:SetPoint("CENTER", 0, BOX_Y + BOX_W * 0.12)
	f.flash:SetAlpha(0)
	f.sprites = {}
	for i = 1, D.SIZE do
		local sp = B3.Pack(fx)
		sp:Hide()
		f.sprites[i] = sp
	end
	f.t = 0
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		CuratorOctoFull.SetRotation(self.rays, self.t * 0.12)
	end)
	self.scene = f
	return f
end

-- The boosters of the album under the box: one more as each lands.
local function PaintDest(f, n)
	f.destCount:SetText("x" .. n)
end

-- One booster landed among the others of its album.
function DU:Land(cer)
	if self.cer ~= cer then
		return
	end
	local f = cer.f
	cer.landed = cer.landed + 1
	-- (1.14.0: the boosters it gave, the talents of the Gambler counted: D.lastOpened)
	local n = cer.n or D.SIZE
	PaintDest(f, math.min(cer.after or CuratorOctoFull.Huge, cer.before + math.floor(cer.landed * n / D.SIZE + 0.5)))
	if CuratorOctoFull.Mod(cer.landed , 2) == 1 then
		ns.Play(ns.SND.tick)
	end
	f.dest:SetLift(7)
	ns.Tween(0.22, function(e)
		f.dest:SetLift(7 * (1 - e))
	end, nil, Ease.outQuad, SCENE)
	f.sparks:Burst(0, PILE_Y + 10, Tint(cer.s), 7, 90, 0.45, 12)
	if cer.landed >= D.SIZE then
		self:Last(cer)
	end
end

-- A booster out of the box: it flies on, turning, out over the box and down to the boosters of its album, growing as
-- it comes (its trail of sparks).
local function Fly(cer, i)
	local f = cer.f
	local s = cer.s
	local box = f.box
	local sp = f.sprites[i]
	local x0, y0, w0 = box:PackScreen(i)
	y0 = y0 + cer.boxY
	local yaw0, pitch0 = B3.PackPose(box)
	box:SetPackShown(i, false)
	sp:SetSeries(s)
	CuratorOctoFull.SetLight(sp, 1)
	sp:Pose(x0, y0, w0, yaw0, pitch0, 0)
	sp:SetAlpha(1)
	sp:Show()
	local x1, y1, w1 = 0, PILE_Y, PILE_W
	local side = (x0 >= 0) and 1 or -1
	local cx, cy = x0 * 1.5 + side * 90, math.max(y0, y1) + 120
	local g = Tint(s)
	local last = 0
	ns.Tween(FLY, function(e, raw)
		local x = (1 - e) ^ 2 * x0 + 2 * (1 - e) * e * cx + e * e * x1
		local y = (1 - e) ^ 2 * y0 + 2 * (1 - e) * e * cy + e * e * y1
		local w = (w0 + (w1 - w0) * e) * (1 + 0.18 * math.sin(math.pi * raw))
		local yaw = yaw0 * (1 - e) + side * 1.15 * math.sin(math.pi * raw)
		local roll = -side * 0.4 * math.sin(math.pi * raw) * (1 - raw)
		sp:Pose(x, y, w, yaw, pitch0 * (1 - e), roll)
		if raw - last > 0.07 then
			last = raw
			f.sparks:Burst(x, y, g, 2, 30, 0.4, w * 0.4)
		end
	end, function()
		sp:Hide()
		DU:Land(cer)
	end, Ease.inOutQuad, SCENE)
end

-- A booster rises out of the box (from behind its front), then flies.
local function Rise(cer, i)
	local box = cer.f.box
	if CuratorOctoFull.Mod(i , 4) == 0 then
		ns.Play(ns.SND.whoosh)
	end
	ns.Tween(LIFT, function(e)
		box:SetPackRise(i, RISE_UP * e)
	end, function()
		if DU.cer == cer then
			Fly(cer, i)
		end
	end, Ease.outQuad, SCENE)
end

-- The box, the album, the room: the scene made ready, the box coming down turning to face you and settling. inspect
-- (after the first test of 1.13.0): it stays there, turning slowly, to be looked at (DU:Inspect), until it is opened
-- (DU:InspectOpen) or put back; else it opens at once (DU:Play). Its moments go on in DU:Unseal.
function DU:Present(s, inspect)
	local f = self:Scene()
	ns.CancelOwner(SCENE)
	HideSprites(f)
	f.sparks:Clear()
	f.twinkles:Clear()
	local cer = { s = s, f = f, landed = 0, boxY = BOX_Y, inspect = inspect and true or false }
	self.cer = cer
	-- (the alerts wait for its end, as for the other scenes)
	if ns.Toast and ns.Toast.Hold then
		ns.Toast:Hold()
	end
	GameTooltip:Hide()
	local g = Tint(s)
	f.title:SetText(Name(s))
	f.sub:SetText(L["A display of 16 boosters"] .. "  ·  " .. KindText(s))
	f.rays:SetVertexColor(g[1], g[2], g[3])
	f.spot:SetVertexColor(0.8 + 0.2 * g[1], 0.8 + 0.2 * g[2], 0.8 + 0.2 * g[3])
	f.flash:SetVertexColor(g[1], g[2], g[3])
	local box = f.box
	box:SetIdle(false)
	box:SetDraggable(false)
	box.dragging, box.dragOff, box.tiltOff = false, 0, 0
	box:SetScale(1)
	box:SetAlpha(0)
	box:SetSeries(s)
	box:SetCased(false)
	box:SetCount(nil)
	box:SetDim(false)
	box:ResetPacks()
	box:SetTear(0)
	box:SetLid(0, true)
	local yaw1, pitch1 = YAW1, B3.PITCH
	box:SetView(-1.15, 0.12)
	PlaceBox(cer, BOX_Y + DROP)
	f.dest:SetSeries(s)
	f.dest:SetLift(0)
	f.pileL:SetSeries(s)
	f.pileR:SetSeries(s)
	f.pile:SetAlpha(0)
	f.destLabel:SetText(L["Boosters to open"])
	f.destLabel:SetAlpha(cer.inspect and 0 or 1)
	-- (opened at once: its boosters in its album already, the pile counts up to all of them; inspected: counted again
	-- when it is opened)
	local after = ns.Packs(s)
	local lo = D.lastOpened
	cer.n = (not cer.inspect and lo and lo.s == s and lo.n) or D.SIZE
	cer.after, cer.before = after, math.max(0, after - cer.n)
	PaintDest(f, cer.before)
	-- (inspected: how many of this album wait, Open the display and Back, what a drag and the wheel do)
	local n = D:Count(s)
	f.have:SetText(n == 1 and L["1 display to open"] or string.format(L["%d displays to open"], n))
	f.have:SetAlpha(1)
	CuratorOctoFull.SetShown(f.have, cer.inspect)
	f.ctl:SetAlpha(0)
	CuratorOctoFull.SetShown(f.ctl, cer.inspect)
	f.hint:SetText(cer.inspect and L["Drag it to turn it · Mouse wheel to bring it closer"] or L["Click to skip"])
	f:EnableMouseWheel(cer.inspect)
	f.rays:SetAlpha(0)
	f.flash:SetAlpha(0)
	f:SetAlpha(0)
	f:Show()
	f:Raise()
	ns.Play(ns.SND.open)
	ns.Tween(0.3, function(e)
		f:SetAlpha(e)
	end, nil, Ease.outQuad, SCENE)
	-- it comes down, turning to face you
	ns.Tween(INTRO, function(e, raw)
		PlaceBox(cer, BOX_Y + DROP * (1 - Ease.outBack(raw)))
		box:SetAlpha(math.min(1, raw * 2.5))
		box:SetView(-1.15 + (yaw1 + 1.15) * e, 0.12 + (pitch1 - 0.12) * e)
		if not cer.inspect then
			f.pile:SetAlpha(raw)
		end
		f.rays:SetAlpha(0.22 * raw)
	end, function()
		PlaceBox(cer, BOX_Y)
		ns.Play(ns.SND.packDrop)
		-- (the dust where it lands)
		f.sparks:Burst(0, BOX_Y - BOX_W * 0.2, { 0.9, 0.82, 0.66 }, 18, 120, 0.5, 10)
	end, Ease.outCubic, SCENE)
	-- it settles, a glint over it; inspected, it turns slowly by itself then, a drag turns it, its buttons come
	ns.Delay(INTRO, function()
		box:Glint(0.7)
		ns.Tween(SETTLE, function(e)
			box:SetView(yaw1 + 0.06 * e, pitch1)
			f.spot:SetAlpha(0.3 + 0.2 * e)
		end, function()
			if DU.cer == cer and cer.inspect then
				box.baseYaw, box.basePitch, box.t, box.nextGlint = yaw1 + 0.06, pitch1, 0, nil
				box:SetIdle(true)
				box:SetDraggable(true, true)
				ns.Tween(0.3, function(e)
					f.ctl:SetAlpha(e)
				end, nil, Ease.outQuad, SCENE)
			end
		end, Ease.inOutQuad, SCENE)
	end, SCENE)
	return cer
end

-- Its seals tear, its lid opens on the light of its album, its boosters rise out of it one by one and fly to the boosters
-- of its album (in its album already).
function DU:Unseal(cer)
	local f = cer.f
	local box = f.box
	local g = Tint(cer.s)
	cer.opened = true
	local t = 0
	-- its seals tear
	ns.Delay(t, function()
		ns.Play(ns.SND.packTear)
		for i = 1, 2 do
			local x, y = box:SealScreen(i)
			f.sparks:Burst(x, y + cer.boxY, { 1, 0.86, 0.5 }, 16, 140, 0.55, 12)
		end
		ns.Tween(TEAR, function(_, raw)
			box:SetTear(raw)
		end, nil, Ease.linear, SCENE)
	end, SCENE)
	t = t + TEAR
	-- its lid opens on the light inside
	ns.Delay(t, function()
		ns.Play(ns.SND.packOpen)
		local burst = false
		ns.Tween(LID, function(e)
			box:SetLid(e, true)
			f.rays:SetAlpha(0.22 + 0.3 * e)
			if not burst and e > 0.45 then
				burst = true
				local x, y = box:MouthScreen()
				f.flash:ClearAllPoints()
				f.flash:SetPoint("CENTER", f, "CENTER", x, y + cer.boxY)
				f.flash:SetAlpha(0.8)
				ns.Tween(0.6, function(_, r)
					f.flash:SetAlpha(0.8 * (1 - r))
				end, nil, Ease.outQuad, SCENE)
				f.sparks:Burst(x, y + cer.boxY + 10, g, 40, 240, 0.85, 18)
			end
		end, function()
			box:SetLid(1, true)
		end, Ease.outCubic, SCENE)
	end, SCENE)
	t = t + LID + 0.12
	-- its boosters rise out of it and fly to its album, one by one
	for k, i in ipairs(RISE) do
		local k, i = k, i; ns.Delay(t + (k - 1) * STEP, function()
			if DU.cer == cer then
				Rise(cer, i)
			end
		end, SCENE)
	end
end

-- The ceremony of a display opened at once (its boosters in its album already).
function DU:Play(s)
	local cer = self:Present(s, false)
	ns.Delay(INTRO + SETTLE, function()
		if DU.cer == cer then
			DU:Unseal(cer)
		end
	end, SCENE)
	return cer
end

-- Brought closer, or further (the mouse wheel), while it is inspected.
function DU:Zoom(delta)
	local cer = self.cer
	if not (cer and cer.inspect) then
		return
	end
	local box = cer.f.box
	local z0 = box:GetScale() or 1
	local z1 = math.max(ZOOM_MIN, math.min(ZOOM_MAX, (cer.zoomTo or z0) + ((delta or 0) > 0 and ZOOM_STEP or -ZOOM_STEP)))
	cer.zoomTo = z1
	if cer.zoomTw then
		ns.CancelTween(cer.zoomTw)
	end
	cer.zoomTw = ns.Tween(0.18, function(e)
		box:SetScale(z0 + (z1 - z0) * e)
		PlaceBox(cer, BOX_Y)
	end, function()
		cer.zoomTw = nil
	end, Ease.outQuad, SCENE)
end

-- Open the display, while it is inspected: its boosters go to its album (D:Open), the box turns back to face you, its
-- pile comes under it, then its seals tear. True, or false and why.
function DU:InspectOpen()
	local cer = self.cer
	if not (cer and cer.inspect) then
		return false
	end
	local f = cer.f
	local ok, why = D:Open(cer.s)
	if not ok then
		ns.Play(ns.SND.close)
		if why and WHY[why] then
			ns.Print(L[WHY[why]])
		end
		return false, why
	end
	cer.inspect, cer.opened = false, true
	cer.after = ns.Packs(cer.s)
	local lo = D.lastOpened
	cer.n = (lo and lo.s == cer.s and lo.n) or D.SIZE
	cer.before = math.max(0, cer.after - cer.n)
	PaintDest(f, cer.before)
	local box = f.box
	box:SetIdle(false)
	box:SetDraggable(false)
	box.dragging = false
	if cer.zoomTw then
		ns.CancelTween(cer.zoomTw)
		cer.zoomTw = nil
	end
	f:EnableMouseWheel(false)
	f.hint:SetText(L["Click to skip"])
	GameTooltip:Hide()
	ns.Play(ns.SND.click)
	local yaw0, pitch0 = box:GetView()
	local z0 = box:GetScale() or 1
	local yaw1, pitch1 = YAW1 + 0.06, B3.PITCH
	local a0 = f.ctl:GetAlpha()
	ns.Tween(BACK, function(e)
		box:SetView(yaw0 + (yaw1 - yaw0) * e, pitch0 + (pitch1 - pitch0) * e)
		box:SetScale(z0 + (1 - z0) * e)
		PlaceBox(cer, BOX_Y)
		f.ctl:SetAlpha(a0 * (1 - e))
		f.have:SetAlpha(1 - e)
		f.pile:SetAlpha(e)
		f.destLabel:SetAlpha(e)
	end, function()
		box:SetScale(1)
		PlaceBox(cer, BOX_Y)
		f.ctl:Hide()
		f.have:Hide()
		f.have:SetAlpha(1)
		if DU.cer == cer then
			DU:Unseal(cer)
		end
	end, Ease.inOutQuad, SCENE)
	return true
end

-- The last one landed: their light, the words of the end; the empty box closes and goes.
function DU:Last(cer)
	local f = cer.f
	local g = Tint(cer.s)
	ns.Play(ns.SND.levelSting)
	f.twinkles:Burst(0, PILE_Y + 10, g, 20, 170, 1, 26)
	f.sparks:Burst(0, PILE_Y + 10, { 1, 0.9, 0.6 }, 28, 210, 0.8, 16)
	PaintDest(f, cer.after or 0)
	-- (1.14.0: the talents of the Gambler, what they made of it)
	local lo = D.lastOpened
	local n = cer.n or D.SIZE
	local text = n == D.SIZE and L["Its 16 boosters are in its album, to open."] or string.format(L["Its %d boosters are in its album, to open."], n)
	if lo and lo.s == cer.s and lo.bet then
		text = text .. "\n" .. ((lo.bet.saved and L["Double or Nothing: lost, but Nerves of Steel kept the boosters."])
			or (lo.bet.win and L["Double or Nothing: won, three boosters more!"]) or L["Double or Nothing: lost, three boosters fewer."])
	elseif lo and lo.s == cer.s and lo.more then
		text = text .. "\n" .. L["Display Chest: a booster more!"]
	end
	f.sub:SetText(text)
	local box = f.box
	ns.Tween(0.55, function(e)
		box:SetLid(1 - e, true)
	end, nil, Ease.inOutQuad, SCENE)
	ns.Tween(0.6, function(e)
		box:SetAlpha(1 - e)
	end, nil, Ease.inQuad, SCENE, 0.5)
	ns.Delay(OUTRO, function()
		DU:Close()
	end, SCENE)
end

-- A click: at once to its end (the boosters were in the album already).
function DU:Skip()
	local cer = self.cer
	-- (inspected: nothing to skip, it waits to be opened or put back)
	if not cer or cer.inspect then
		return
	end
	ns.CancelOwner(SCENE)
	local f = cer.f
	HideSprites(f)
	cer.landed = D.SIZE
	PaintDest(f, cer.after)
	ns.Play(ns.SND.stamp)
	self:Close(true)
end

-- Its end (quick: at once).
function DU:Close(quick)
	local cer = self.cer
	local f = self.scene
	self.cer = nil
	if not f then
		return
	end
	ns.CancelOwner(SCENE)
	-- (an inspected one put back, never opened: nothing done)
	if cer and cer.opened then
		ns.Fire("DISPLAY_SCENE_DONE", cer.s)
	end
	local box = f.box
	box:SetIdle(false)
	box:SetDraggable(false)
	box.dragging = false
	f:EnableMouseWheel(false)
	local function Gone()
		f:Hide()
		HideSprites(f)
		box:ResetPacks()
		box:SetLid(0, true)
		box:SetTear(0)
		box:SetAlpha(1)
		box:SetScale(1)
		f.ctl:Hide()
		f.have:Hide()
		f.destLabel:SetAlpha(1)
		f.hint:SetText(L["Click to skip"])
		f.sparks:Clear()
		f.twinkles:Clear()
		if ns.Toast and ns.Toast.Resume then
			ns.Toast:Resume()
		end
	end
	if quick then
		Gone()
		return
	end
	ns.Tween(0.35, function(e)
		f:SetAlpha(1 - e)
	end, Gone, Ease.outQuad, SCENE)
end

-- A display being opened, its ceremony on the screen.
function DU:Playing()
	return self.cer ~= nil
end

-- A display of an album opened, with its ceremony: true; false and why when it cannot be (Displays.lua: D:CanOpen;
-- "busy": another one being opened).
function DU:OpenDisplay(s)
	if self.cer then
		return false, "busy"
	end
	if ns.Beta and ns.Beta:Blocked() then
		return false, "closed"
	end
	local ok, why = D:Open(s)
	if not ok then
		ns.Play(ns.SND.close)
		return false, why
	end
	local cer = self:Play(s)
	cer.opened = true
	return true
end

-- (1.13.0, after its first test) A display of an album inspected before it is opened (the boosters of the inventory):
-- its box big, turning slowly, a drag turns it, the wheel brings it closer; Open the display (DU:InspectOpen), or Back.
-- True; false and why when it cannot be (Displays.lua: D:CanOpen; "busy": another one on the screen).
function DU:Inspect(s)
	if self.cer then
		return false, "busy"
	end
	if ns.Beta and ns.Beta:Blocked() then
		return false, "closed"
	end
	local ok, why = D:CanOpen(s)
	if not ok then
		ns.Play(ns.SND.close)
		return false, why
	end
	self:Present(s, true)
	return true
end

-------------------------------------------------------------------------------
-- The boosters of the inventory (the page of the boosters, a part of it since the first test of 1.13.0): its displays
-------------------------------------------------------------------------------
-- (1.13.0, after its first test: under the bar of the filters of the inventory, the rows a little lower)
local ROWS, ROW_H, ROW_GAP, ROWS_TOP = 4, 96, 6, -64
local BOX_ROW = 150

local function RowTooltip(r)
	local x = r.item
	if not x then
		return
	end
	local s = x.series
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Name(s), 1, 1, 1)
	GameTooltip:AddLine(L["A display of 16 boosters"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:AddLine(KindText(s))
	GameTooltip:AddLine(L["Opened: its 16 boosters go to its album, to open as any other."], 0.85, 0.85, 0.85, true)
	if x.casedDisplays > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["In its case: sealed, neither opened nor traded until it comes out of it, at a banker, free."], CASE_COLOR[1], CASE_COLOR[2],
			CASE_COLOR[3], true)
	end
	GameTooltip:Show()
end

local function NewRow(parent, w)
	local r = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r.bg = Hud.Sliced(r, "QuestCard", ROW_H, 0, "BACKGROUND")
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetPoint("TOPLEFT", 4, -4)
	r.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.6, 0.05)
	r.box = DU.Box(r, BOX_ROW)
	r.box:SetPoint("LEFT", 4, -4)
	local x = 4 + BOX_ROW + 12
	r.name = S.Text(r, "GameFontNormal", "LEFT")
	r.name:SetPoint("TOPLEFT", x, -12)
	r.name:SetWidth(w - x - 12)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.kind = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.kind:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
	r.kind:SetWidth(w - x - 12)
	CuratorOctoFull.SetWordWrap(r.kind, false)
	r.line = S.Text(r, "GameFontHighlight", "LEFT")
	r.line:SetPoint("TOPLEFT", r.kind, "BOTTOMLEFT", 0, -5)
	r.line:SetWidth(w - x - 12)
	CuratorOctoFull.SetWordWrap(r.line, false)
	r.case = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.case:SetPoint("TOPLEFT", r.line, "BOTTOMLEFT", 0, -4)
	r.case:SetWidth(w - x - 134)
	CuratorOctoFull.SetWordWrap(r.case, true)
	CuratorOctoFull.SetMaxLines(r.case, 2)
	r.case:SetTextColor(CASE_COLOR[1], CASE_COLOR[2], CASE_COLOR[3])
	-- (1.13.0, after its first test: inspected before it is opened, its box big, to look at it as long as you like)
	r.open = Hud.ClaimButton(r, 112, 28, L["Inspect"])
	r.open:SetPoint("BOTTOMRIGHT", -12, 10)
	r.open:SetFrameLevel(r:GetFrameLevel() + 14)
	CuratorOctoFull.SetScript(r.open, "OnClick", function()
		local s = r.item and r.item.series
		if not s then
			return
		end
		ns.Play(ns.SND.click)
		GameTooltip:Hide()
		DU:Inspect(s)
	end)
	r.open.tip = function(self)
		local s = r.item and r.item.series
		if not s then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Inspect the display"], 1, 1, 1)
		GameTooltip:AddLine(string.format(L["Its box, big: turn it, look at it, then open it. Its 16 boosters go to %s."], Name(s)), GOLD[1], GOLD[2], GOLD[3], true)
		local _, why = D:CanOpen(s)
		if why and WHY[why] then
			GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
		end
		GameTooltip:Show()
	end
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		RowTooltip(self)
		if self.item and self.box:IsShown() then
			DU:Peek(self.box)
		end
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

local function PaintRow(r, x)
	r.item = x
	CuratorOctoFull.SetShown(r, x ~= nil)
	if not x then
		return
	end
	local s = x.series
	local hasBox = x.displays > 0 or x.casedDisplays > 0
	CuratorOctoFull.SetShown(r.box, hasBox)
	if hasBox then
		if r.box.series ~= s then
			r.box:SetSeries(s)
		end
		r.box:SetCased(x.displays == 0)
		r.box:SetCount(x.displays > 0 and x.displays or x.casedDisplays)
		r.box:SetCountAt("bottom")
	end
	S.SetFontObject(r.name, "GameFontNormal")
	r.name:SetText(Name(s))
	if ns.TextWidth(r.name) > r.name:GetWidth() then
		S.Fit(r.name, Name(s), r.name:GetWidth(), 12, 9)
	end
	r.kind:SetText(KindText(s))
	if x.displays > 0 then
		r.line:SetText(x.displays == 1 and L["1 display to open"] or string.format(L["%d displays to open"], x.displays))
		r.line:SetTextColor(1, 0.92, 0.75)
	else
		r.line:SetText(L["No display to open"])
		r.line:SetTextColor(DIM[1], DIM[2], DIM[3])
	end
	r.case:SetText(x.casedDisplays == 0 and "" or (x.casedDisplays == 1 and L["1 display in its case"] or string.format(L["%d displays in their case"], x.casedDisplays)))
	CuratorOctoFull.SetEnabled(r.open, x.displays > 0)
	r.open:SetPulse(x.displays > 0)
end

function DU:BuildBoostersView(page)
	if page.disp then
		return page.disp
	end
	local A = ns.Album
	local rw = page.rw or 420
	local v = CreateFrame("Frame", nil, page)
	v:SetAllPoints(page.grid)
	v:Hide()
	page.disp = v
	v.title = S.Text(v, "GameFontNormalLarge", "LEFT")
	v.title:SetPoint("TOPLEFT", 4, -4)
	v.title:SetText(L["Displays and cases"])
	v.sub = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.sub:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -5)
	v.sub:SetWidth(rw - 116)
	CuratorOctoFull.SetWordWrap(v.sub, true)
	CuratorOctoFull.SetMaxLines(v.sub, 3)
	v.sub:SetTextColor(DIM[1], DIM[2], DIM[3])
	v.sub:SetText(L["16 boosters of an album in each display. At a banker, a protective case keeps a display sealed."])
	v.back = S.Button(v, L["Back"], 100, 22)
	v.back:SetPoint("TOPRIGHT", -2, -4)
	CuratorOctoFull.SetScript(v.back, "OnClick", function()
		ns.Play(ns.SND.page)
		A.dispView = nil
		A:Refresh()
	end)
	v.rows = {}
	for i = 1, ROWS do
		local r = NewRow(v, rw - 4)
		r:SetPoint("TOPLEFT", 2, ROWS_TOP - (i - 1) * (ROW_H + ROW_GAP))
		v.rows[i] = r
	end
	v.empty = S.Text(v, "GameFontHighlight")
	v.empty:SetPoint("CENTER", v, "TOP", 0, -230)
	v.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(v.empty, true)
	v.empty:SetTextColor(0.8, 0.8, 0.8)
	v.empty:SetText(L["No display yet. They come from the reseller, from gift codes, and now and then with a quest of the month or a golden quest."])
	v.pager = S.Pager(v)
	v.pager:SetPoint("BOTTOMRIGHT", -4, 2)
	CuratorOctoFull.SetScript(v.pager.prev, "OnClick", function()
		DU.page = math.max(1, (DU.page or 1) - 1)
		ns.Play(ns.SND.page)
		DU:PaintBoostersView()
	end)
	CuratorOctoFull.SetScript(v.pager.next, "OnClick", function()
		DU.page = (DU.page or 1) + 1
		ns.Play(ns.SND.page)
		DU:PaintBoostersView()
	end)
	return v
end

function DU:PaintBoostersView()
	local A = ns.Album
	local page = A.frame and A.frame.boost
	local v = page and page.disp
	if not (v and v:IsShown()) then
		return
	end
	local list = D:All()
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / ROWS))
	self.page = math.max(1, math.min(self.page or 1, pages))
	local first = (self.page - 1) * ROWS
	for i, r in ipairs(v.rows) do
		PaintRow(r, list[first + i])
	end
	CuratorOctoFull.SetShown(v.empty, CuratorOctoFull.Length(list) == 0)
	CuratorOctoFull.SetShown(v.pager, pages > 1)
	v.pager:Set(self.page, pages, string.format(L["Page %d / %d"], self.page, pages))
end

-- The button of the displays, over the boosters of the other albums: how many to open.
local function PaintDispButton(page)
	local b = page and page.dispButton
	if b then
		b:SetText(string.format(L["Displays: %d"], D:Total()))
	end
end

local function InstallBoosters()
	local A = ns.Album
	if not (A and A.BuildBoosters and A.RefreshBoosters) or DU.boostersHooked then
		return
	end
	DU.boostersHooked = true
	local build = A.BuildBoosters
	function A:BuildBoosters(...)
		local r = build(self, unpack(arg, 1, arg.n))
		local page = self.frame and self.frame.boost
		if page and page.grid and not page.dispButton then
			local b = S.Button(page.grid, "", 156, 22)
			b:SetPoint("TOPRIGHT", -2, -2)
			CuratorOctoFull.SetScript(b, "OnClick", function()
				ns.Play(ns.SND.page)
				A.dispView = true
				A.boosterPick = nil
				A:Refresh()
			end)
			CuratorOctoFull.SetScript(b, "OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:AddLine(L["Displays and cases"], 1, 1, 1)
				GameTooltip:AddLine(L["Your displays of 16 boosters, album by album, and what waits in its case."], GOLD[1], GOLD[2], GOLD[3], true)
				GameTooltip:Show()
			end)
			CuratorOctoFull.SetScript(b, "OnLeave", function()
				GameTooltip:Hide()
			end)
			page.dispButton = b
			DU:BuildBoostersView(page)
			-- (the album closed: its boosters again next time, not their displays)
			if CuratorOctoFull.HookScript then
				CuratorOctoFull.HookScript(self.frame, "OnHide", function()
					A.dispView, DU.page = nil, nil
				end)
			end
		end
		return r
	end
	local refresh = A.RefreshBoosters
	function A:RefreshBoosters(...)
		local r = refresh(self, unpack(arg, 1, arg.n))
		local page = self.frame and self.frame.boost
		if page and page.disp then
			local on = (self.dispView and not self.boosterPick) and true or false
			CuratorOctoFull.SetShown(page.disp, on)
			if on then
				page.grid:Hide()
				page.pick:Hide()
				DU:PaintBoostersView()
			end
			PaintDispButton(page)
		end
		return r
	end
	-- (another tab: the boosters of the albums again when it comes back)
	local setMode = A.SetMode
	if setMode then
		function A:SetMode(mode, ...)
			if mode ~= "boosters" then
				self.dispView = nil
			end
			return setMode(self, mode, unpack(arg, 1, arg.n))
		end
	end
	local showBoosters = A.ShowBoosters
	if showBoosters then
		function A:ShowBoosters(...)
			self.dispView = DU.toView or nil
			DU.toView = nil
			return showBoosters(self, unpack(arg, 1, arg.n))
		end
	end
end

-- The displays shown, in the boosters of the inventory (a click on the toast of a display earned).
function DU:ShowInAlbum()
	local A = ns.Album
	if not (A and A.ShowBoosters) then
		return
	end
	self.toView = true
	A:ShowBoosters()
end

-------------------------------------------------------------------------------
-- At a banker: the protective cases
-------------------------------------------------------------------------------
local CASE_W, CASE_ROWS, CASE_ROW_H = 300, 5, 22
local LIST_TOP = -112
local CASE_BOX = 124

-- The albums the cases can take something of: displays to open, or in their case.
local function CaseAlbums()
	local out = {}
	for _, s in ipairs((ns.Album and ns.Album.Order and ns.Album:Order()) or ns.Series or {}) do
		if not s.limited and (D:Count(s) > 0 or D:CasedDisplays(s) > 0) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end
DU.CaseAlbums = CaseAlbums

-- A button of the cases: kind ("display"), way ("in": into its case, for rubies, two clicks; "out": free).
local function CaseButton(parent, kind, way)
	local b = S.Button(parent, "", 118, 22)
	b.kind, b.way = kind, way
	if b.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(b, true)
	end
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		DU:CaseClick(self)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		DU:CaseTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self)
		if self.armed and not Armed(self) then
			self.armed = nil
			DU:PaintCaseButton(self)
		end
	end)
	return b
end

function DU:CasePanel()
	if self.cases then
		return self.cases
	end
	local W = CASE_W
	local f = CreateFrame("Frame", "CuratorCasePanel", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, W, 374)
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
	f.icon:SetTexture(MEDIA .. "CaseIcon")
	CuratorOctoFull.SetSize(f.icon, 36, 36)
	f.icon:SetPoint("TOPLEFT", 12, -10)
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 6, -3)
	CuratorOctoFull.SetWordWrap(f.title, false)
	f.sub = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.text = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.text:SetPoint("TOPLEFT", f.icon, "BOTTOMLEFT", 2, -7)
	f.text:SetWidth(W - 28)
	CuratorOctoFull.SetWordWrap(f.text, true)
	f.text:SetTextColor(0.85, 0.85, 0.85)
	f.text:SetText(L["A display in its case stays sealed: neither opened nor traded until it comes out of it, here, free."])
	-- the albums
	f.rows = {}
	for i = 1, CASE_ROWS do
		local i = i; local r = S.ListButton(f)
		CuratorOctoFull.SetSize(r, W - 24, CASE_ROW_H - 2)
		r:SetPoint("TOPLEFT", 12, LIST_TOP - (i - 1) * CASE_ROW_H)
		r.name = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.name:SetPoint("LEFT", 6, 0)
		r.name:SetWidth(W - 24 - 86)
		CuratorOctoFull.SetWordWrap(r.name, false)
		-- (how many: displays to open, in their case)
		r.dispIcon = r:CreateTexture(nil, "ARTWORK")
		r.dispIcon:SetTexture(MEDIA .. "DisplayIcon")
		CuratorOctoFull.SetSize(r.dispIcon, 16, 16)
		r.dispIcon:SetPoint("RIGHT", -62, 0)
		r.dispN = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.dispN:SetPoint("LEFT", r.dispIcon, "RIGHT", 2, 0)
		r.caseIcon = r:CreateTexture(nil, "ARTWORK")
		r.caseIcon:SetTexture(MEDIA .. "CaseIcon")
		CuratorOctoFull.SetSize(r.caseIcon, 16, 16)
		r.caseIcon:SetPoint("RIGHT", -22, 0)
		r.caseN = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.caseN:SetPoint("LEFT", r.caseIcon, "RIGHT", 1, 0)
		r.caseN:SetTextColor(CASE_COLOR[1], CASE_COLOR[2], CASE_COLOR[3])
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.series and DU.caseSel ~= self.series then
				ns.Play(ns.SND.click)
				DU.caseSel = self.series
				DU:PaintCases()
			end
		end)
		f.rows[i] = r
	end
	f.empty = S.Text(f, "GameFontHighlightSmall")
	f.empty:SetPoint("TOP", 0, LIST_TOP - 30)
	f.empty:SetWidth(W - 40)
	CuratorOctoFull.SetWordWrap(f.empty, true)
	f.empty:SetTextColor(DIM[1], DIM[2], DIM[3])
	f.empty:SetText(L["No display to put in a case for now."])
	f.pager = S.Pager(f)
	f.pager:SetScale(0.8)
	f.pager:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14 / 0.8, (LIST_TOP - CASE_ROWS * CASE_ROW_H) / 0.8)
	CuratorOctoFull.SetScript(f.pager.prev, "OnClick", function()
		DU.casePage = math.max(1, (DU.casePage or 1) - 1)
		ns.Play(ns.SND.page)
		DU:PaintCases()
	end)
	CuratorOctoFull.SetScript(f.pager.next, "OnClick", function()
		DU.casePage = (DU.casePage or 1) + 1
		ns.Play(ns.SND.page)
		DU:PaintCases()
	end)
	-- the album chosen: its displays, in their case or not
	local y = LIST_TOP - CASE_ROWS * CASE_ROW_H - 30
	f.line = S.Divider(f, W - 30, 0.8)
	f.line:SetPoint("TOP", 0, y + 4)
	f.chosen = S.Text(f, "GameFontNormal", "LEFT")
	f.chosen:SetPoint("TOPLEFT", 14, y - 4)
	f.chosen:SetWidth(W - 28)
	CuratorOctoFull.SetWordWrap(f.chosen, false)
	-- (its display, in its case of acrylic when it is in one; what there is under it)
	f.dispArt = DU.Box(f, CASE_BOX)
	f.dispArt:SetPoint("TOPLEFT", 8, y - 30)
	f.dispText = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.dispText:SetPoint("TOPLEFT", 16, y - 30 - CASE_BOX / 2 - 2)
	f.dispText:SetWidth(W - 32)
	CuratorOctoFull.SetWordWrap(f.dispText, false)
	f.dispIn = CaseButton(f, "display", "in")
	f.dispIn:SetPoint("TOPRIGHT", -14, y - 36)
	f.dispOut = CaseButton(f, "display", "out")
	f.dispOut:SetPoint("TOPRIGHT", -14, y - 60)
	f.buttons = { f.dispIn, f.dispOut }
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	self.cases = f
	return f
end

-- The label of a button of the cases: its price (in), free (out), to confirm (armed).
function DU:PaintCaseButton(b)
	if b.way == "out" then
		b:SetText(L["Take out"])
	elseif Armed(b) then
		b:SetText(L["Confirm"])
	else
		b:SetText(L["Protect"] .. " " .. ns.Rubies.Text(D:CasePrice(b.kind), 12))
	end
end

function DU:PaintCases()
	local f = self.cases
	if not (f and f:IsShown()) then
		return
	end
	local RB = ns.Rubies
	S.Fit(f.title, L["Curator: the protective cases"], CASE_W - 96, 12, 9)
	f.sub:SetText(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 12)))
	local list = CaseAlbums()
	-- (the album chosen: the one chosen before while it is there, else the first)
	local sel
	for _, s in ipairs(list) do
		if s == self.caseSel then
			sel = s
		end
	end
	sel = sel or list[1]
	self.caseSel = sel
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / CASE_ROWS))
	if self.casePage == nil and sel then
		for i, s in ipairs(list) do
			if s == sel then
				self.casePage = math.ceil(i / CASE_ROWS)
			end
		end
	end
	self.casePage = math.max(1, math.min(self.casePage or 1, pages))
	local first = (self.casePage - 1) * CASE_ROWS
	for i, r in ipairs(f.rows) do
		local s = list[first + i]
		r.series = s
		CuratorOctoFull.SetShown(r, s ~= nil)
		if s then
			r:SetSelected(s == sel)
			r.name:SetText(Name(s))
			if s == sel then
				r.name:SetTextColor(1, 1, 1)
			else
				r.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
			end
			r.dispN:SetText(tostring(D:Count(s)))
			local cased = D:CasedDisplays(s)
			r.caseIcon:SetAlpha(cased > 0 and 1 or 0.3)
			r.caseN:SetText(tostring(cased))
		end
	end
	CuratorOctoFull.SetShown(f.empty, CuratorOctoFull.Length(list) == 0)
	CuratorOctoFull.SetShown(f.pager, pages > 1)
	f.pager:Set(self.casePage, pages, string.format(("%d / %d"), self.casePage, pages))
	-- the album chosen
	local any = sel ~= nil
	for _, x in ipairs({ f.line, f.chosen, f.dispArt, f.dispText }) do
		CuratorOctoFull.SetShown(x, any)
	end
	for _, b in ipairs(f.buttons) do
		CuratorOctoFull.SetShown(b, any)
	end
	if not any then
		return
	end
	f.chosen:SetText(Name(sel))
	local nd, cd = D:Count(sel), D:CasedDisplays(sel)
	if f.dispArt.series ~= sel then
		f.dispArt:SetSeries(sel)
	end
	f.dispArt:SetCased(cd > 0)
	f.dispArt:SetDim(nd == 0 and cd == 0)
	f.dispArt:SetCount(nil)
	f.dispText:SetText(string.format(L["Displays to open: %d"], nd) .. "  ·  |cffa8dbff" .. string.format(L["In their case: %d"], cd) .. "|r")
	for _, b in ipairs(f.buttons) do
		local ok
		if b.way == "in" then
			ok = D:CanCase(sel, b.kind)
		else
			ok = D:CanUncase(sel, b.kind)
		end
		CuratorOctoFull.SetEnabled(b, ok and true or false)
		if not ok then
			b.armed = nil
		end
		self:PaintCaseButton(b)
	end
end

function DU:CaseTooltip(b)
	local s = self.caseSel
	if not s then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Name(s), 1, 1, 1)
	local RB = ns.Rubies
	if b.way == "in" then
		GameTooltip:AddLine(L["A display into its case"], CASE_COLOR[1], CASE_COLOR[2], CASE_COLOR[3])
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(D:CasePrice(b.kind), 13)), 1, 0.82, 0.25)
		GameTooltip:AddLine(L["Sealed in it: neither opened nor traded until it comes out of it, at a banker, free."], 0.85, 0.85, 0.85, true)
		local ok, why = D:CanCase(s, b.kind)
		if not ok and WHY[why] then
			GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
		elseif Armed(b) then
			GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
		end
	else
		GameTooltip:AddLine(L["A display out of its case"], CASE_COLOR[1], CASE_COLOR[2], CASE_COLOR[3])
		GameTooltip:AddLine(L["Free"], 0.4, 1, 0.4)
		local ok, why = D:CanUncase(s, b.kind)
		if not ok and WHY[why] then
			GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
		end
	end
	GameTooltip:Show()
end

function DU:CaseClick(b)
	local s = self.caseSel
	if not s or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	if b.way == "out" then
		local ok = D:Uncase(s, b.kind)
		ns.Play(ok and ns.SND.place or ns.SND.close)
		if ok then
			ns.Print(L["Out of its case: a display of %s, to open."], Name(s))
		end
		self:PaintCases()
		return
	end
	local ok = D:CanCase(s, b.kind)
	if not ok then
		ns.Play(ns.SND.close)
		self:CaseTooltip(b)
		return
	end
	if not Armed(b) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintCaseButton(b)
		self:CaseTooltip(b)
		return
	end
	b.armed = nil
	local done, price = D:Case(s, b.kind)
	if done then
		ns.Play(ns.SND.seal)
		Hud.Burst(self.cases.dispArt, CASE_COLOR, 14, 90, 12)
		ns.Print(L["In its case: a display of %s, for %s."], Name(s), ns.Rubies.Text(price or 0))
	else
		ns.Play(ns.SND.close)
	end
	GameTooltip:Hide()
	self:PaintCases()
end

function DU:ShowCases(show)
	if not show then
		if self.cases then
			self.cases:Hide()
		end
		return
	end
	if not ns.db or (ns.Beta and ns.Beta:Over()) then
		return
	end
	local f = self:CasePanel()
	f:ClearAllPoints()
	-- (under the window of the expert, beside the bank; it follows that window)
	local XU = ns.ExpertiseUI
	local expert = XU and XU.Panel and XU:Panel()
	if expert then
		f:SetPoint("TOPLEFT", expert, "BOTTOMLEFT", 0, -6)
	else
		f:SetPoint("TOPLEFT", UIParent, "LEFT", 420, -1)
	end
	self.casePage = nil
	f:Show()
	self:PaintCases()
end

-------------------------------------------------------------------------------
-- At the reseller: his displays
-------------------------------------------------------------------------------
local SALE_ROWS, SALE_ROW_H = 8, 26
local SALE_LEFT = 300 -- (the box of the album chosen, on the left; the albums on the right)
local SALE_BOX = 290

-- His displays: those of his shop (the zones, the dungeon, the raid, the two drawn: D:ForSale), the album of the place
-- you are in first, then those of the events that last.
function DU:SaleList()
	local list = D:ForSale()
	local here = ns.Rewards and ns.Rewards.ZoneSeries and ns.Rewards:ZoneSeries()
	local out, seen = {}, {}
	local function Put(s)
		if s and not seen[s] then
			seen[s] = true
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	for _, s in ipairs(list) do
		if s == here then
			Put(s)
		end
	end
	for _, s in ipairs(list) do
		if s.event then
			Put(s)
		end
	end
	for _, s in ipairs(list) do
		Put(s)
	end
	return out
end

-- When his shop changes, said (the line over his displays).
local function PaintShopLeft(v)
	v.left:SetText(string.format(L["Other displays in %s"], ns.Duration(D:ShopLeft())))
end

function DU:BuildSale(f)
	if f.disp then
		return f.disp
	end
	local RUI = ns.ResellerUI
	local v = CreateFrame("Frame", nil, f)
	v:SetPoint("TOPLEFT", f.ground, "TOPLEFT", 10, -8)
	v:SetPoint("BOTTOMRIGHT", f.ground, "BOTTOMRIGHT", -10, 6)
	v:Hide()
	f.disp = v
	-- the album chosen: its box, big, turning (a drag turns it); its name, its kind; the button to buy
	v.box = DU.Box(v, SALE_BOX)
	v.box:SetPoint("TOP", v, "TOPLEFT", SALE_LEFT / 2, 6)
	v.box:SetDraggable(true)
	CuratorOctoFull.SetScript(v.box, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Drag it to turn it"], 0.85, 0.85, 0.85)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(v.box, "OnLeave", function()
		GameTooltip:Hide()
	end)
	v.name = S.Text(v, "GameFontNormalLarge")
	v.name:SetPoint("TOP", v, "TOPLEFT", SALE_LEFT / 2, -146)
	v.name:SetWidth(SALE_LEFT - 10)
	CuratorOctoFull.SetWordWrap(v.name, false)
	v.kind = S.Text(v, "GameFontHighlightSmall")
	v.kind:SetPoint("TOP", v.name, "BOTTOM", 0, -4)
	v.kind:SetWidth(SALE_LEFT - 10)
	CuratorOctoFull.SetWordWrap(v.kind, false)
	v.have = S.Text(v, "GameFontHighlightSmall")
	v.have:SetPoint("TOP", v.kind, "BOTTOM", 0, -3)
	v.have:SetWidth(SALE_LEFT - 10)
	v.have:SetTextColor(DIM[1], DIM[2], DIM[3])
	v.buy = S.Button(v, "", 230, 24)
	v.buy:SetPoint("BOTTOM", v, "BOTTOMLEFT", SALE_LEFT / 2, 2)
	if v.buy.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(v.buy, true)
	end
	CuratorOctoFull.SetScript(v.buy, "OnClick", function()
		DU:SaleClick()
	end)
	CuratorOctoFull.SetScript(v.buy, "OnEnter", function(self)
		DU:SaleTooltip(self)
	end)
	CuratorOctoFull.SetScript(v.buy, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(v.buy, "OnUpdate", function(self)
		if self.armed and not Armed(self) then
			self.armed = nil
			DU:PaintSale()
		end
	end)
	-- when his shop changes; the albums he has them of: their kind, their price
	local rw = (f:GetWidth() or 640) - 36 - SALE_LEFT - 12
	v.left = S.Text(v, "GameFontHighlightSmall", "LEFT")
	v.left:SetPoint("TOPLEFT", SALE_LEFT + 14, -2)
	v.left:SetWidth(rw - 4)
	CuratorOctoFull.SetWordWrap(v.left, false)
	v.left:SetTextColor(0.9, 0.84, 0.7)
	v.rows = {}
	for i = 1, SALE_ROWS do
		local i = i; local r = S.ListButton(v)
		CuratorOctoFull.SetSize(r, rw, SALE_ROW_H - 2)
		r:SetPoint("TOPLEFT", SALE_LEFT + 12, -18 - (i - 1) * SALE_ROW_H)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.icon, 9, 18)
		r.icon:SetPoint("LEFT", 6, 0)
		r.name = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.name:SetPoint("LEFT", 20, 5)
		r.name:SetWidth(rw - 20 - 92)
		CuratorOctoFull.SetWordWrap(r.name, false)
		r.kind = S.Text(r, "GameFontDisableSmall", "LEFT")
		r.kind:SetPoint("LEFT", 20, -6)
		r.kind:SetWidth(rw - 20 - 92)
		CuratorOctoFull.SetWordWrap(r.kind, false)
		r.price = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.price:SetPoint("RIGHT", -8, 0)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.series and DU.saleSel ~= self.series then
				ns.Play(ns.SND.click)
				DU.saleSel = self.series
				v.buy.armed = nil
				DU:PaintSale()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			DU:SaleTooltip(self, self.series)
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		v.rows[i] = r
	end
	v.pager = S.Pager(v)
	v.pager:SetPoint("BOTTOMRIGHT", -2, -2)
	CuratorOctoFull.SetScript(v.pager.prev, "OnClick", function()
		DU.salePage = math.max(1, (DU.salePage or 1) - 1)
		ns.Play(ns.SND.page)
		DU:PaintSale()
	end)
	CuratorOctoFull.SetScript(v.pager.next, "OnClick", function()
		DU.salePage = (DU.salePage or 1) + 1
		ns.Play(ns.SND.page)
		DU:PaintSale()
	end)
	-- (its box turns while it is shown; the time left, each second; another shop when it changes)
	CuratorOctoFull.SetScript(v, "OnShow", function(self)
		self.box:SetIdle(true)
	end)
	CuratorOctoFull.SetScript(v, "OnHide", function(self)
		self.box:SetIdle(false)
	end)
	v.tick = 0
	CuratorOctoFull.SetScript(v, "OnUpdate", function(self, elapsed)
		self.tick = self.tick + elapsed
		if self.tick < 1 then
			return
		end
		self.tick = 0
		if self.period ~= D:ShopPeriod() then
			DU:PaintSale()
		else
			PaintShopLeft(self)
		end
	end)
	-- its tab, after his two
	local b = Hud.NavButton(f, 170, 26)
	b:SetPoint("TOPLEFT", 64 + 2 * 176, -58)
	Hud.SetIcon(b.icon, { "DisplayIcon" })
	CuratorOctoFull.SetScript(b, "OnClick", function()
		if RUI.tab ~= "display" then
			ns.Play(ns.SND.page)
			RUI:Tab("display")
		end
	end)
	f.dispTab = b
	return v
end

function DU:PaintSale()
	local RUI = ns.ResellerUI
	local f = RUI and RUI.frame
	local v = f and f.disp
	if not v then
		return
	end
	local RB = ns.Rubies
	v.period = D:ShopPeriod()
	PaintShopLeft(v)
	local list = self:SaleList()
	-- (the album chosen: the one chosen before while he has it, else the first)
	local sel
	for _, s in ipairs(list) do
		if s == self.saleSel then
			sel = s
		end
	end
	sel = sel or list[1]
	self.saleSel = sel
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / SALE_ROWS))
	if self.salePage == nil and sel then
		for i, s in ipairs(list) do
			if s == sel then
				self.salePage = math.ceil(i / SALE_ROWS)
			end
		end
	end
	self.salePage = math.max(1, math.min(self.salePage or 1, pages))
	local first = (self.salePage - 1) * SALE_ROWS
	for i, r in ipairs(v.rows) do
		local s = list[first + i]
		r.series = s
		CuratorOctoFull.SetShown(r, s ~= nil)
		if s then
			r:SetSelected(s == sel)
			r.icon:SetTexture(MEDIA .. (s.pack or "PackElwynn") .. "Bottom")
			r.name:SetText(Name(s))
			if s == sel then
				r.name:SetTextColor(1, 1, 1)
			else
				r.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
			end
			r.kind:SetText(KindText(s))
			r.price:SetText(RB.Text(D:Price(s), 11))
		end
	end
	CuratorOctoFull.SetShown(v.pager, pages > 1)
	v.pager:Set(self.salePage, pages, string.format(L["Page %d / %d"], self.salePage, pages))
	local any = sel ~= nil
	for _, x in ipairs({ v.box, v.name, v.kind, v.have, v.buy }) do
		CuratorOctoFull.SetShown(x, any)
	end
	if not any then
		return
	end
	if v.box.series ~= sel then
		v.box:SetSeries(sel)
	end
	local have = D:Count(sel)
	v.box:SetCount(nil)
	S.SetFontObject(v.name, "GameFontNormalLarge")
	v.name:SetText(Name(sel))
	if ns.TextWidth(v.name) > SALE_LEFT - 10 then
		S.Fit(v.name, Name(sel), SALE_LEFT - 10, 16, 10)
	end
	if sel.event then
		v.kind:SetText(KindText(sel) .. "  ·  " .. L["Limited edition: while its event lasts"])
	else
		v.kind:SetText(KindText(sel) .. "  ·  |cffd1d1db" .. C:LevelRange(sel) .. "|r")
	end
	v.have:SetText(have > 0 and string.format(L["Yours already, to open: %d"], have) or "")
	local ok = D:CanBuy(sel)
	CuratorOctoFull.SetEnabled(v.buy, ok and true or false)
	if not ok then
		v.buy.armed = nil
	end
	if Armed(v.buy) then
		v.buy:SetText(L["Confirm"])
	else
		v.buy:SetText(L["Buy"] .. "  " .. RB.Text(D:Price(sel), 14))
	end
end

-- The tooltip of a display he sells (s: of a line; else the album chosen, under its button).
function DU:SaleTooltip(owner, s)
	local onButton = s == nil
	s = s or self.saleSel
	if not s then
		return
	end
	local RB = ns.Rubies
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Name(s), 1, 1, 1)
	GameTooltip:AddLine(L["A display of 16 boosters"], GOLD[1], GOLD[2], GOLD[3])
	if s.event then
		GameTooltip:AddLine(L["Limited edition: while its event lasts"], LIMITED[1], LIMITED[2], LIMITED[3])
	else
		GameTooltip:AddLine(KindText(s))
	end
	GameTooltip:AddLine(L["Sealed in its box: open it in the inventory, its 16 boosters go to its album."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(D:Price(s), 13)), 1, 0.82, 0.25)
	local ok, why = D:CanBuy(s)
	if not ok and WHY[why] then
		GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
	elseif onButton and Armed(owner) then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	elseif onButton then
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function DU:SaleClick()
	local RUI = ns.ResellerUI
	local v = RUI and RUI.frame and RUI.frame.disp
	local s = self.saleSel
	if not (v and s) or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	local b = v.buy
	local ok = D:CanBuy(s)
	if not ok then
		ns.Play(ns.SND.close)
		self:SaleTooltip(b)
		return
	end
	if not Armed(b) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintSale()
		self:SaleTooltip(b)
		return
	end
	b.armed = nil
	local done, price = D:Buy(s)
	GameTooltip:Hide()
	if not done then
		ns.Play(ns.SND.close)
		RUI:Paint()
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.claim)
	Hud.Burst(v.box, Tint(s), 26, 140, 16)
	v.box:Glint(0.8)
	ns.Print(L["From the reseller: a display of %s, for %s. Open it in the inventory."], Name(s), ns.Rubies.Text(price or 0))
	RUI:Paint()
end

local function InstallReseller()
	local RUI = ns.ResellerUI
	if not (RUI and RUI.Build and RUI.Tab and RUI.Paint) or DU.resellerHooked then
		return
	end
	DU.resellerHooked = true
	local build = RUI.Build
	function RUI:Build(...)
		local f = build(self, unpack(arg, 1, arg.n))
		if f and not f.disp then
			DU:BuildSale(f)
		end
		return f
	end
	local tab = RUI.Tab
	function RUI:Tab(key, ...)
		if key == "display" then
			DU.salePage = nil
		end
		local r = tab(self, key, unpack(arg, 1, arg.n))
		local f = self.frame
		if f and f.disp then
			CuratorOctoFull.SetShown(f.disp, self.tab == "display")
		end
		return r
	end
	local paint = RUI.Paint
	function RUI:Paint(...)
		local r = paint(self, unpack(arg, 1, arg.n))
		local f = self.frame
		if f and f:IsShown() and f.disp then
			if f.dispTab then
				f.dispTab:Paint(self.tab == "display", L["Displays"], tostring(CuratorOctoFull.Length(D:ForSale())), 0)
			end
			if self.tab == "display" then
				f.say:SetText(L["\"Displays, sealed: sixteen boosters of an album in each. A collector's pleasure, and a dear one.\""])
				self:Foot(L["New displays every 3 days, of the albums you unlocked only: three zones, a dungeon, a raid, two drawn at random"])
				DU:PaintSale()
			end
		end
		return r
	end
end

-------------------------------------------------------------------------------
-- The alerts wait while a display opens (as for the other scenes: UI/Toast.lua)
-------------------------------------------------------------------------------
local function InstallToast()
	local T = ns.Toast
	if not (T and T.Waits) or DU.toastHooked then
		return
	end
	DU.toastHooked = true
	local waits = T.Waits
	function T:Waits(...)
		return waits(self, unpack(arg, 1, arg.n)) or DU:Playing()
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
InstallBoosters()
InstallToast()
-- (every file loaded: the pages of the files loaded after this one wrapped too)
ns.On("LOADED", function()
	InstallBoosters()
	InstallReseller()
	InstallToast()
end)

-- (a display come now and then: its alert; from the reseller or a gift code: their own words)
ns.On("DISPLAY_EARNED", function(s, n, why)
	if why ~= "quest" and why ~= "golden" and why ~= "hallow" then
		return
	end
	ns.Print(L["A display of %s! Its 16 boosters wait in the inventory: Displays."], Name(s))
	if ns.Toast and ns.Toast.Push then
		ns.Toast:Push({
			title = L["A display earned!"],
			name = Name(s),
			color = { 1, 0.86, 0.5 },
			line = L["16 boosters to open: the inventory, Displays."],
			tex = { "DisplayIcon" },
			sound = ns.SND.claim,
			onClick = function()
				DU:ShowInAlbum()
			end,
		})
	end
end)

ns.On("BANK_CHANGED", function(open)
	DU:ShowCases(open)
end)

for _, event in ipairs({ "DISPLAYS_CHANGED", "RUBIES_CHANGED", "CHANGED" }) do
	ns.On(event, function()
		if DU.cases and DU.cases:IsShown() then
			DU:PaintCases()
		end
		local A = ns.Album
		local page = A and A.frame and A.frame.boost
		if page and page.disp and page.disp:IsShown() and A.frame:IsShown() then
			DU:PaintBoostersView()
			PaintDispButton(page)
		end
	end)
end
