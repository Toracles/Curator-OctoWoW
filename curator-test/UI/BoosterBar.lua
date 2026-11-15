local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease
local C = ns.Collection
local Hud = ns.Hud

-- The booster bar (1.2), over the experience bar of the game: the points toward the next booster
-- (Rewards.lua). On its left the booster of the album the next one goes to; in its middle how full it
-- is and where it goes; each gain rises from it, and it flashes when it is full. Under the mouse: what
-- fills it. A click opens the boosters; Shift-drag moves it (kept); /curator bar hides it or shows it
-- again, /curator bar reset puts it back over the experience bar. (1.4.1) In a dungeon or a raid it is
-- their own bar: steel blue in a frame of dark iron, the medallion of their sealed boosters behind its
-- booster, their points and their limit of the day; the bar of the world waits outside.
local BB = {}
ns.BoosterBar = BB

-- (1.14.0, a player's word) Its size (60 % to 130 %), its picture (the booster on its left end) and its lights (the
-- light that passes over it, its spark, the talents that breathe), set in the options (UI/Options.lua). The lights off,
-- the bar stays still: only a booster that comes lights it up.
BB.SCALE_MIN, BB.SCALE_MAX, BB.SCALE_STEP = 0.4, 1.3, 0.05

function BB:Scale()
	local k = tonumber(ns.db and ns.db.barScale) or 1
	return math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, k))
end

function BB:SetScale(k)
	if not ns.db then
		return
	end
	k = math.floor((tonumber(k) or 1) * 100 + 0.5) / 100
	k = math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, k))
	ns.db.barScale = (math.abs(k - 1) > 0.001) and k or nil
	self:Refresh()
end

function BB:ArtShown()
	return not (ns.db and ns.db.barArtHide)
end

function BB:Calm()
	return (ns.db and ns.db.barCalm) and true or false
end

-- Its size, its picture and its lights as the options say.
function BB:ApplyLook()
	local b = self.frame
	if not b then
		return
	end
	local k = self:Scale()
	if math.abs((b:GetScale() or 1) - k) > 0.001 then
		b:SetScale(k)
	end
	local art = self:ArtShown()
	CuratorOctoFull.SetShown(b.art, art)
	CuratorOctoFull.SetShown(b.glow, art)
	b.bar:SetCalm(self:Calm())
end

-- After an option: built, placed at its size, painted.
function BB:Refresh()
	self:Build()
	self:ApplyLook()
	self:Place()
	self:Paint()
end

local HEIGHT = 13
local MIN_W, MAX_W, FREE_W = 120, 1100, 560
local ICON = 34
local GAP = 3
local TINT = { 1, 0.74, 0.25 }
-- (1.4.1) the bar of the dungeons and the raids: its fill, its frame, its gains
local STEEL = { 0.5, 0.68, 1 }
local IRON = { 0.58, 0.6, 0.68 }
local STEEL_TEXT = { 0.72, 0.86, 1 }
local GREY = { 0.55, 0.55, 0.58 }
local GOLD = { 1, 0.82, 0.36 }
-- the front of a booster, out of its texture (as the toasts show it)
local PACK_CROP = { 30 / 256, 226 / 256, 110 / 512, 306 / 512 }
-- the experience bars of the game, the first one shown (each kind of interface has its own; the classic
-- one: the bar of the reputation watched over it, when shown), else the bar of its buttons
local ANCHORS = { "MainStatusTrackingBarContainer", "StatusTrackingBarManager", "ReputationWatchBar", "MainMenuExpBar", "MainMenuBar", "MainActionBar" }
-- the bars of buttons that may sit right over it: the bar goes over them then, not on their buttons
local OVER = { "MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight" }

-- "12", "0,5": points as the language writes them.
local function Dec(v)
	v = math.floor((tonumber(v) or 0) * 10 + 0.5) / 10
	local s = (v == math.floor(v)) and tostring(math.floor(v)) or string.format(("%.1f"), v)
	return (string.gsub(s, "%.", ns.L["."]))
end
BB.Dec = Dec

local function Visible(f)
	if type(f) ~= "table" or type(f.IsVisible) ~= "function" then
		return false
	end
	local ok, vis = pcall(f.IsVisible, f)
	if not (ok and vis) then
		return false
	end
	local ok2, w = pcall(f.GetWidth, f)
	return ok2 and type(w) == "number" and w > 1
end

-- A frame on the screen: its left, right, top and bottom, in points of the screen (nil: not placed yet).
local function Box(f)
	local ok, l, r, t, b, k = pcall(function()
		return f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom(), f:GetEffectiveScale()
	end)
	if ok and type(l) == "number" and type(r) == "number" and type(t) == "number" and type(b) == "number" and type(k) == "number" then
		return l * k, r * k, t * k, b * k
	end
end

-- f holds g (one of its parents).
local function Holds(f, g)
	for _ = 1, 8 do
		local ok, p = pcall(g.GetParent, g)
		if not ok or not p then
			return false
		end
		if p == f then
			return true
		end
		g = p
	end
	return false
end

-- Where it sits: over the bar of the game a, or over a bar of buttons right over a (as high as they
-- go), so that it covers none of their buttons.
function BB:Base(a, need)
	local base = a
	local al, ar = Box(a)
	if not al then
		return a
	end
	for _ = 1, CuratorOctoFull.Length(OVER) do
		local _, _, top = Box(base)
		local best, bestTop
		for _, name in ipairs(OVER) do
			local f = _G[name]
			if f and f ~= base and f ~= a and Visible(f) and not Holds(f, a) then
				local fl, fr, ft, fb = Box(f)
				if fl and fr > al and fl < ar and ft > top and fb < top + need and (not bestTop or ft > bestTop) then
					best, bestTop = f, ft
				end
			end
		end
		if not best then
			break
		end
		base = best
	end
	return base
end

-- The bar of the game it sits on (nil: none shown).
function BB:Anchor()
	for _, name in ipairs(ANCHORS) do
		local f = _G[name]
		if Visible(f) then
			return f, name
		end
	end
end

function BB:Build()
	if self.frame then
		return self.frame
	end
	local b = CreateFrame("Button", "CuratorBoosterBar", UIParent)
	CuratorOctoFull.SetSize(b, FREE_W, HEIGHT)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(20)
	b:SetClampedToScreen(true)
	b:SetMovable(true)
	if b.SetDontSavePosition then
		b:SetDontSavePosition(true)
	end
	b:RegisterForClicks("LeftButtonUp")
	b:RegisterForDrag("LeftButton")
    b:EnableMouseWheel(true)
    CuratorOctoFull.SetScript(b, "OnMouseWheel", function(_, delta)
        if not delta or delta == 0 then return end
        if IsControlKeyDown and IsControlKeyDown() then
            BB:SetScale(BB:Scale() + (delta > 0 and BB.SCALE_STEP or -BB.SCALE_STEP))
        else
            BB:SetCustomWidth(BB:DisplayWidth() + (delta > 0 and 30 or -30))
        end
    end)
	b:Hide()
	self.frame = b
	b.bar = Hud.XPBar(b, FREE_W, HEIGHT, TINT)
	b.bar:SetAllPoints()
	b.bar.tip:SetVertexColor(1, 0.85, 0.5)
	-- the booster, on the left end
	b.glow = b:CreateTexture(nil, "BACKGROUND")
	b.glow:SetTexture(MEDIA .. "Glow")
	b.glow:SetBlendMode("ADD")
	b.glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	CuratorOctoFull.SetSize(b.glow, ICON * 2.2, ICON * 2.2)
	b.glow:SetAlpha(0)
	b.art = CreateFrame("Frame", nil, b)
	CuratorOctoFull.SetSize(b.art, ICON, ICON)
	b.art:SetPoint("CENTER", b, "LEFT", -ICON * 0.3, 1)
	b.art:SetFrameLevel(b.bar.over:GetFrameLevel() + 2)
	b.glow:SetPoint("CENTER", b.art, "CENTER")
	b.icon = b.art:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	-- (the dungeons and the raids: the iron medallion of their sealed boosters behind it)
	b.iron = b.art:CreateTexture(nil, "BACKGROUND")
	b.iron:SetTexture(MEDIA .. "Lock")
	b.iron:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.iron, ICON * 1.75, ICON * 1.75)
	b.iron:Hide()
	b.ring = b.art:CreateTexture(nil, "OVERLAY")
	b.ring:SetTexture(MEDIA .. "IconRing")
	b.ring:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.ring, ICON * 1.32, ICON * 1.32)
	-- (1.14.0) the talents to use of the tree, on the right end (Talents.lua, TL:BarActives): ready (it breathes),
	-- running (green, the time left), armed or waiting (Double or Nothing on the next booster, the card under the
	-- counter of the Black Market: it pulses), recharging (grey, the time left); a click uses it
	b.acts = {}
	for i = 1, 2 do
		local i = i; local it = CreateFrame("Button", nil, b)
		CuratorOctoFull.SetSize(it, 28, 28)
		it:SetPoint("CENTER", b, "RIGHT", 20 + (i - 1) * 40, 1)
		it:SetFrameLevel(b.bar.over:GetFrameLevel() + 2)
		it.light = it:CreateTexture(nil, "BACKGROUND")
		it.light:SetTexture(MEDIA .. "Glow")
		it.light:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(it.light, 60, 60)
		it.light:SetPoint("CENTER")
		it.light:SetAlpha(0)
		it.icon = Hud.RoundIcon(it, 21, "ARTWORK")
		it.icon:SetPoint("CENTER")
		it.ring = it:CreateTexture(nil, "OVERLAY")
		it.ring:SetTexture(MEDIA .. "IconRing")
		it.ring:SetPoint("CENTER")
		CuratorOctoFull.SetSize(it.ring, 32, 32)
		it.text = Hud.Text(it, 10, "OUTLINE", "OVERLAY", 3)
		it.text:SetPoint("TOP", it, "BOTTOM", 0, 2)
		CuratorOctoFull.SetScript(it, "OnClick", function(self)
			BB:UseActive(self)
		end)
		CuratorOctoFull.SetScript(it, "OnEnter", function(self)
			BB:ActiveTooltip(self)
		end)
		CuratorOctoFull.SetScript(it, "OnLeave", function()
			GameTooltip:Hide()
		end)
		it.t = 0
		CuratorOctoFull.SetScript(it, "OnUpdate", function(self, elapsed)
			self.t = self.t + elapsed
			-- (1.14.0, a player's word: the lights of the bar off, a talent ready or armed lit, still)
			local calm = BB:Calm()
			if self.ready then
				self.light:SetAlpha(calm and 0.35 or (0.3 + 0.25 * math.sin(self.t * 3)))
			elseif self.armed then
				self.light:SetAlpha(calm and 0.55 or (0.45 + 0.35 * math.sin(self.t * 5)))
			end
			self.tick = (self.tick or 0) + elapsed
			if self.tick >= 15 then
				self.tick = 0
				BB:PaintActives()
			end
		end)
		it:Hide()
		b.acts[i] = it
	end
	-- the gains that rise from the end of the fill
	b.floats = {}
	for i = 1, 4 do
		local t = Hud.Text(b.bar.over, 13, "OUTLINE", "OVERLAY", 5)
		t:SetTextColor(1, 0.88, 0.5)
		t:SetAlpha(0)
		b.floats[i] = t
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		if IsShiftKeyDown and IsShiftKeyDown() then
			return
		end
		ns.Play(ns.SND.click)
		ns.Album:ShowBoosters()
	end)
	CuratorOctoFull.SetScript(b, "OnDragStart", function()
		if IsShiftKeyDown and IsShiftKeyDown() then
			BB.moving = true
			b:StartMoving()
		end
	end)
	CuratorOctoFull.SetScript(b, "OnDragStop", function()
		b:StopMovingOrSizing()
		if BB.moving then
			BB.moving = false
			BB:SavePlace()
		end
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		BB.over = true
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		BB:AddLines(GameTooltip)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Click: your boosters. Shift-drag: move the bar. /curator bar: hide it."], GOLD[1], GOLD[2], GOLD[3], true)
		GameTooltip:AddLine(ns.locale == "frFR"
            and "Molette : largeur. Ctrl + molette : échelle."
            or "Mouse wheel: width. Ctrl + wheel: scale.", 1, .84, .48, true)
        GameTooltip:Show()
    end)
    CuratorOctoFull.SetScript(b, "OnLeave", function()
		BB.over = false
		GameTooltip:Hide()
	end)
	return b
end

-- Its width: the button and the bar that fills it, together. (The bar is anchored to all the points of the
-- button: the game draws it as wide as the button, whatever width it is given. Its ticks, its light and
-- its spark go by the width it is given: the button must have the same, or they leave its frame.)
-- The custom width stays independent of the position and of the height scale.
function BB:DisplayWidth()
    local b = self.frame
    local scale = self:Scale()
    return math.floor((b and b.bar.w or FREE_W) * scale + 0.5)
end

function BB:SetCustomWidth(width)
    if not ns.db or type(width) ~= "number" then return end
    ns.db.barWidth = math.floor(math.max(MIN_W, math.min(MAX_W, width)) + 0.5)
    self:Place()
    self:Paint()
end

function BB:SetWidth(w)
	local b = self.frame
	local custom = ns.db and tonumber(ns.db.barWidth)
	if custom then w = custom / self:Scale() end
	w = math.max(20, math.floor((tonumber(w) or FREE_W) + 0.5))
	b:SetWidth(w)
	b.bar:SetBarWidth(w)
end

-- Where it is: over the experience bar of the game, as wide as it (a bar moved: where it was left).
function BB:Place()
	local b = self.frame
	if not b or self.moving then
		return
	end
	local at = ns.db and ns.db.barAt
	-- (1.14.0: at its size first, a player's word: where it was moved kept, in the units of the screen)
	self:ApplyLook()
	b:ClearAllPoints()
	if type(at) == "table" and tonumber(at.x) and tonumber(at.y) then
		local kr = 1
		local ok, r = pcall(function()
			return b:GetEffectiveScale() / UIParent:GetEffectiveScale()
		end)
		if ok and type(r) == "number" and r > 0 then
			kr = r
		end
		b:SetPoint("CENTER", UIParent, "CENTER", at.x / kr, at.y / kr)
		-- (its bounds on the screen whatever its size)
		local k = self:Scale()
		self:SetWidth(math.max(MIN_W / k, math.min(MAX_W / k, tonumber(at.w) or FREE_W)))
		return
	end
	local a = self:Anchor()
	if a then
		local w = a:GetWidth()
		local ok, k = pcall(function()
			return a:GetEffectiveScale() / b:GetEffectiveScale()
		end)
		if ok and type(k) == "number" and k > 0 then
			w = w * k
		end
		-- (as wide as the bar of the game whatever its size: its bounds on the screen)
		local size = self:Scale()
		self:SetWidth(math.max(MIN_W / size, math.min(MAX_W / size, w)))
		local base = self:Base(a, (GAP + HEIGHT + 2) * (b:GetEffectiveScale() or 1))
		b:SetPoint("BOTTOM", base, "TOP", 0, GAP)
		self:Watch(a)
		-- (a bar of buttons shown or hidden later: placed again)
		for _, name in ipairs(OVER) do
			if type(_G[name]) == "table" then
				self:Watch(_G[name])
			end
		end
	else
		self:SetWidth(FREE_W)
		b:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 92)
	end
end

-- (a bar of the game shown, hidden or resized: the bar follows)
function BB:Watch(a)
	self.watched = self.watched or {}
	if self.watched[a] or type(a.HookScript) ~= "function" then
		return
	end
	self.watched[a] = true
	for _, e in ipairs({ "OnShow", "OnHide", "OnSizeChanged" }) do
		local _, e = _, e; pcall(a.HookScript, a, e, function()
			BB:PlaceSoon()
		end)
	end
end

function BB:PlaceSoon()
	if self.placing then
		return
	end
	self.placing = true
	ns.Delay(0.2, function()
		BB.placing = false
		BB:Place()
	end, BB)
end

-- Moved: where its middle was left, from the middle of the screen, and its width.
function BB:SavePlace()
	local b = self.frame
	local x, y = b:GetCenter()
	local cx, cy = UIParent:GetCenter()
	local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()
	if x and y and cx and cy then
		ns.db.barAt = { x = math.floor(x * k - cx + 0.5), y = math.floor(y * k - cy + 0.5), w = b.bar.w }
	end
	self:Place()
end

-- Its look (1.4.1): the bar of the world (gold), or the one of the dungeons and the raids (steel blue
-- in dark iron, the medallion of their sealed boosters).
function BB:Look(kind)
	local b = self.frame
	if b.look == kind then
		return
	end
	b.look = kind
	local dungeon = kind == "dungeon"
	-- (the gold of the frame turned grey, then the blue grey of iron)
	local fr = dungeon and IRON or { 1, 1, 1 }
	for _, t in ipairs({ b.bar.left, b.bar.mid, b.bar.right }) do
		t:SetDesaturated(dungeon)
		t:SetVertexColor(fr[1], fr[2], fr[3])
	end
	CuratorOctoFull.SetShown(b.ring, not dungeon)
	CuratorOctoFull.SetShown(b.iron, dungeon)
	local g = dungeon and STEEL or GOLD
	b.glow:SetVertexColor(g[1], g[2], g[3])
	if dungeon then
		b.bar.tip:SetVertexColor(0.7, 0.85, 1)
	else
		b.bar.tip:SetVertexColor(1, 0.85, 0.5)
	end
	local ft = dungeon and STEEL_TEXT or { 1, 0.88, 0.5 }
	for _, t in ipairs(b.floats) do
		t:SetTextColor(ft[1], ft[2], ft[3])
	end
end

-- How full it is, where its booster goes (dimmed where it does not fill).
function BB:Paint()
	local b = self.frame
	if not b then
		return
	end
	local R = ns.Rewards
	local on = ns.db ~= nil and not ns.db.barHide and not (ns.Beta and ns.Beta:Over())
	CuratorOctoFull.SetShown(b, on and true or false)
	if not on then
		return
	end
	local kind = R:Here()
	self:Look(kind)
	local pts = R:Bar(kind)
	local pct = math.floor(100 * pts / ns.PACK_POINTS)
	b.bar:SetProgress(pts / ns.PACK_POINTS)
	local s, inst = R:Target()
	local note, off
	if inst and R:TooLow(inst) then
		note, off = L["too low for your level"], true
	elseif inst and R:DailyLeft() <= 0 then
		note, off = L["limit of the day reached"], true
	elseif s then
		note = C:SeriesName(s)
	else
		note, off = L["no album here"], true
	end
	local head = (inst and (inst.raid and L["Next raid booster: %d%%"] or L["Next dungeon booster: %d%%"])) or L["Next booster: %d%%"]
	-- (1.14.0: a reroll, its own bar and its chest: Reroll.lua)
	local RR = ns.Reroll
	if RR and RR:IsReroll() then
		note = note .. "  ·  " .. string.format(L["Chest: %d"], RR:Contents().boosters)
	end
	b.bar:SetText(string.format(head, pct) .. "  ·  " .. note)
	b.bar.text:SetTextColor(1, off and 0.82 or 0.95, off and 0.7 or 0.85)
	local c = off and GREY or (inst and STEEL or TINT)
	b.bar.bar:SetStatusBarColor(c[1], c[2], c[3])
	if s and s.pack and not off then
		b.icon:SetTexture(MEDIA .. s.pack .. "Bottom")
		b.icon:SetTexCoord(PACK_CROP[1], PACK_CROP[2], PACK_CROP[3], PACK_CROP[4])
	else
		b.icon:SetTexture(Hud.PackIcon((s and s.dungeon) and (s.raid and "raid" or "dungeon") or "zone"))
		b.icon:SetTexCoord(0, 1, 0, 1)
	end
	b.icon:SetDesaturated(off and true or false)
	self:PaintActives()
	if self.over and GameTooltip:GetOwner() == b then
		b:GetScript("OnEnter")(b)
	end
end

-- (1.14.0) A time on the bar, short: in hours, else in minutes.
local function Short(sec)
	sec = math.max(0, tonumber(sec) or 0)
	if sec >= 3600 then
		return string.format(L["%d h"], math.ceil(sec / 3600))
	end
	return string.format(L["%d min"], math.max(1, math.ceil(sec / 60)))
end

-- (1.14.0) The talents to use of the tree on its end, when they are learned.
function BB:PaintActives()
	local b = self.frame
	local TL = ns.Talents
	if not (b and b.acts) then
		return
	end
	local list = (TL and ns.db and TL:Spec()) and TL:BarActives() or {}
	for i, it in ipairs(b.acts) do
		local id = list[i]
		it.id = id
		CuratorOctoFull.SetShown(it, id ~= nil)
		if id then
			if it.iconId ~= id then
				it.iconId = id
				Hud.SetIcon(it.icon, { TL:Icon(TL.BY[id]) })
			end
			local state, left = TL:ActiveState(id)
			it.ready = state == "ready"
			it.armed = state == "armed" or state == "waiting"
			it.icon:SetDesaturated(state == "cooldown")
			if state == "running" then
				it.light:SetVertexColor(0.45, 1, 0.4)
				it.light:SetAlpha(0.7)
				it.text:SetText(Short(left))
				it.text:SetTextColor(0.55, 1, 0.5)
			elseif state == "armed" then
				it.light:SetVertexColor(0.8, 0.52, 1)
				it.text:SetText(L["Armed"])
				it.text:SetTextColor(0.85, 0.66, 1)
			elseif state == "waiting" then
				it.light:SetVertexColor(1, 0.78, 0.3)
				it.text:SetText(L["To buy"])
				it.text:SetTextColor(1, 0.82, 0.36)
			elseif state == "cooldown" then
				it.light:SetAlpha(0)
				it.text:SetText(Short(left))
				it.text:SetTextColor(0.62, 0.62, 0.66)
			else
				it.light:SetVertexColor(1, 0.82, 0.36)
				it.text:SetText("")
			end
		end
	end
	-- (1.14.0: the rest and the dish of the day of the inns, after them: UI/Lodging.lua)
	if ns.LodgingUI then
		ns.LodgingUI:Paint()
	end
end

-- A click: the talent used (Talents.lua, TL:Activate).
function BB:UseActive(it)
	local TL = ns.Talents
	local id = it and it.id
	if not (TL and id) then
		return
	end
	local ok, why = TL:Activate(id)
	if ok then
		local d = TL.BY[id]
		local col = d and TL.SPEC_BY[d.spec] and TL.SPEC_BY[d.spec].color or { 1, 0.82, 0.36 }
		Hud.Burst(it, col, 12, 80, 12)
	else
		ns.Play(ns.SND.close)
		if why == "ready" then
			ns.Print(L["%s recharges: ready in %s."], TL:Name(id), ns.Duration(TL:Left(id)))
		end
	end
	self:PaintActives()
	if it:IsMouseOver() then
		self:ActiveTooltip(it)
	end
end

-- What the click does, by talent.
local CLICK = {
	survey = "Click: start it now.",
	expedition = "Click: start it now.",
	mark = "Click: mark your target (a creature that has a card).",
	double = "Click: bet your next booster (click again: take the bet back).",
	wheel = "Click: spin the wheel.",
	blackmarket = "Click: see what the reseller has under his counter.",
	glance = "It works at the banker, before you appraise a copy.",
}

function BB:ActiveTooltip(it)
	local TL = ns.Talents
	local id = it and it.id
	local d = TL and id and TL.BY[id]
	if not d then
		return
	end
	GameTooltip:SetOwner(it, "ANCHOR_TOP")
	local col = TL.SPEC_BY[d.spec].color
	GameTooltip:AddLine(TL:Name(id), col[1], col[2], col[3])
	GameTooltip:AddLine(TL:Text(id, TL:Rank(id)), 1, 1, 1, true)
	local state, left = TL:ActiveState(id)
	if state == "running" then
		GameTooltip:AddLine(string.format(L["Active: %s"], ns.Duration(left)), 0.55, 1, 0.5)
	elseif state == "armed" then
		GameTooltip:AddLine(L["Armed: your next booster is the bet."], 0.85, 0.66, 1, true)
		GameTooltip:AddLine(L["Click: take the bet back."], GOLD[1], GOLD[2], GOLD[3])
	elseif state == "waiting" then
		local card, price = TL:BlackMarket()
		if card then
			GameTooltip:AddLine(string.format(L["Under the counter: %s, for %s."], ns.Collection:Name(card), ns.Rubies.Text(price)), 1, 0.82, 0.36, true)
		end
		GameTooltip:AddLine(L["Buy it at a reseller (a vendor of general goods or of trade supplies)."], 0.8, 0.8, 0.8, true)
	elseif state == "cooldown" then
		GameTooltip:AddLine(string.format(L["Ready in %s"], ns.Duration(left)), 0.62, 0.62, 0.66)
	elseif CLICK[id] then
		GameTooltip:AddLine(L[CLICK[id]], GOLD[1], GOLD[2], GOLD[3], true)
	end
	-- (the Contract of the Day: its target, by the Price on its Head)
	if id == "mark" and TL:Ready("dailyhead") then
		local target = TL:DailyTarget()
		if target then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(string.format(L["Contract of the Day: %s (%s)."], ns.Collection:Name(target), ns.Collection:SeriesName(target.series)), 1, 0.45, 0.32, true)
		end
	end
	GameTooltip:Show()
end

-- What a bar tells (its tooltip, and the one of the gauges of the album): how full, where its booster
-- goes, the limit of the day, what fills it, how full the other one is. kind: "world" or "dungeon"
-- (1.4.1; nil: the bar of the place where the player is).
function BB:AddLines(tip, kind)
	local R = ns.Rewards
	kind = kind or R:Here()
	local dungeon = kind == "dungeon"
	local pts = R:Bar(kind)
	tip:AddLine(dungeon and L["Dungeon and raid bar"] or L["Booster bar"], GOLD[1], GOLD[2], GOLD[3])
	tip:AddLine(string.format(L["Next booster: %d%%"], math.floor(100 * pts / ns.PACK_POINTS)) .. "  (" .. Dec(pts) .. " / " .. ns.PACK_POINTS .. ")", 1, 1, 1)
	-- (1.14.0: a reroll, its own bar and its chest: Reroll.lua)
	local RR = ns.Reroll
	if RR and RR:IsReroll() then
		local got = RR:Contents()
		tip:AddLine(string.format(L["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."], RR.LEVEL, RR.LEVEL), 1, 0.62, 0.45, true)
		tip:AddLine(string.format(L["In its chest: %d boosters, %d cards."], got.boosters, got.cards) .. "  (/curator chest)", 0.8, 0.8, 0.8, true)
	end
	local s, inst = R:Target()
	if dungeon then
		if inst and R:TooLow(inst) then
			tip:AddLine(string.format(L["%s: too low for your level, no boosters here."], C:SeriesName(inst)), 1, 0.5, 0.4, true)
		elseif inst then
			tip:AddLine(string.format(L["The next booster goes to: %s"], C:SeriesName(s)), 0.55, 0.85, 1, true)
		else
			tip:AddLine(L["It fills in the dungeons and the raids."], 0.55, 0.85, 1, true)
		end
		local left = R:DailyLeft()
		tip:AddLine(string.format(L["Today: %d / %d boosters from the dungeons and raids"], R:DailyMax() - left, R:DailyMax()), left > 0 and 0.8 or 1, left > 0 and 0.8 or 0.5, left > 0 and 0.8 or 0.4, true)
	elseif inst then
		tip:AddLine(L["It fills outside the dungeons and the raids."], 0.55, 0.85, 1, true)
	elseif s then
		tip:AddLine(string.format(L["The next booster goes to: %s"], C:SeriesName(s)), 0.55, 0.85, 1, true)
	else
		tip:AddLine(L["No album lives here: the bar does not fill (the daily quests of the collector still fill it)."], 1, 0.62, 0.45, true)
	end
	tip:AddLine(" ")
	tip:AddLine(L["What fills it:"], GOLD[1], GOLD[2], GOLD[3])
	local P = R.POINTS
	local Q = ns.Quests and ns.Quests.byKey or {}
	local rows = dungeon and {
		{ "Dungeon or raid: a creature", P.dungeonKill },
		{ "Dungeon or raid: an elite", P.elite },
		{ "Dungeon or raid: a boss", P.boss },
		{ "Dungeon or raid: its last boss", P.final },
	} or {
		{ "A creature that gives experience", P.kill },
		{ "A step of a quest objective", P.objective },
		{ "A quest turned in", P.quest },
		{ "A place discovered", P.explore },
		{ "A level gained", P.level },
		{ "A daily quest of the collector", Q.daily and Q.daily.pts },
		{ "A daily dungeon quest of the collector", Q.dungeonDaily and Q.dungeonDaily.pts },
		{ "A daily PvP quest of the collector", Q.pvpDaily and Q.pvpDaily.pts },
	}
	local vc = dungeon and STEEL_TEXT or { 1, 0.86, 0.45 }
	for _, row in ipairs(rows) do
		if row[2] then
			tip:AddDoubleLine(L[row[1]], "+" .. Dec(row[2]), 0.85, 0.85, 0.88, vc[1], vc[2], vc[3])
		end
	end
	if dungeon then
		tip:AddLine(L["The first time each of your characters completes a dungeon or a raid: a booster of it, besides."], 0.55, 0.85, 1, true)
	end
	-- (1.6.0: what the talents add)
	local TL = ns.Talents
	if TL and TL:Spec() then
		local more = TL:BarPoints(100, "kill", dungeon and "dungeon" or "world") / 100 - 1
		if more > 0.001 then
			tip:AddLine(string.format(L["Your talents fill it %s more."], ns.Pct(more)), 0.55, 1, 0.55, true)
		end
	end
	tip:AddLine(" ")
	local cap = R:DailyMax()
	tip:AddLine(dungeon and (cap == R.DAILY and L["Each time it is full: a booster of the album chosen for the place (its own by default), 5 a day at most."]
		or string.format(L["Each time it is full: a booster of the album chosen for the place (its own by default), %d a day at most."], cap))
		or L["Each time it is full: a booster of the album of the place where you are."], 0.8, 0.8, 0.8, true)
	-- (the other bar keeps its points)
	local other = math.floor(100 * R:Bar(dungeon and "world" or "dungeon") / ns.PACK_POINTS)
	tip:AddLine(string.format((dungeon and L["The bar of the world keeps its points: %d%%"] or L["The dungeons and the raids fill a bar of their own: %d%%"]), other), 0.62, 0.62, 0.66, true)
end

-- A gain rises from the end of the fill ("+10"), when it is for the bar shown.
function BB:Gain(points, kind)
	local b = self.frame
	if not (b and b:IsVisible()) or (tonumber(points) or 0) < 1 or (kind and kind ~= b.look) then
		return
	end
	self.floatI = CuratorOctoFull.Mod((self.floatI or 0) , CuratorOctoFull.Length(b.floats)) + 1
	local t = b.floats[self.floatI]
	t:SetText("+" .. Dec(points))
	local x = b.bar.w * b.bar.p
	if t.tw then
		ns.CancelTween(t.tw)
	end
	t.tw = ns.Tween(1.3, function(e, raw)
		t:ClearAllPoints()
		t:SetPoint("BOTTOM", b, "LEFT", x, HEIGHT / 2 + 2 + 18 * e)
		t:SetAlpha((raw < 0.15 and raw / 0.15) or (raw > 0.6 and (1 - raw) / 0.4) or 1)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.outCubic, BB)
	b.bar:Flash(0.35)
end

-- Full: the bar flashes, its booster swells in its light, sparks burst from it.
function BB:Full()
	local b = self.frame
	if not (b and b:IsVisible()) then
		return
	end
	b.bar:Flash(1)
	Hud.Burst(b.art, b.look == "dungeon" and STEEL or GOLD, 18, 120, 18)
	if b.popTw then
		ns.CancelTween(b.popTw)
	end
	b.popTw = ns.Tween(0.9, function(_, raw)
		local k = 1 + 0.35 * math.sin(math.pi * math.min(1, raw * 2.2)) * (1 - raw)
		b.art:SetScale(k)
		b.glow:SetAlpha(0.9 * (1 - raw))
	end, function()
		b.art:SetScale(1)
		b.glow:SetAlpha(0)
		b.popTw = nil
	end, Ease.linear, BB)
end

-- /curator bar: hidden or shown again; "reset": back over the experience bar.
function BB:Command(arg)
	local db = ns.db
	if not db then
		return
	end
	arg = string.lower((arg or ""))
	local _, _, amount = string.find(arg, "^width%s+(%d+)$")
    if amount then
        self:SetCustomWidth(tonumber(amount))
        ns.Print((ns.locale == "frFR" and "Largeur de la barre : " or "Booster bar width: ") .. db.barWidth)
        return
    elseif arg == "reset" then
        db.barAt, db.barHide, db.barWidth, db.barScale = nil, nil, nil, nil
		ns.Print(L["Booster bar: back over the experience bar."])
	else
		db.barHide = not db.barHide or nil
		ns.Print(db.barHide and L["Booster bar hidden (/curator bar to show it)."] or L["Booster bar shown."])
	end
	self:Build()
	self:Place()
	self:Paint()
end

local function Refresh()
	if BB.frame then
		BB:Paint()
	end
end

ns.On("LOGIN", function()
	BB:Build()
	BB:Place()
	BB:Paint()
	-- (the bars of the game are set up a moment after the login)
	ns.Delay(1.5, function()
		BB:Place()
		BB:Paint()
	end, BB)
end)
ns.On("PROGRESS", function(_, points, _, kind)
	Refresh()
	BB:Gain(points, kind)
end)
ns.On("PACK_EARNED", function()
	Refresh()
	BB:Full()
end)
for _, e in ipairs({ "PLACE_CHANGED", "FARM_CHANGED", "DAILY_LIMIT", "CHANGED", "CHEST_CHANGED", "MAIN_CHANGED" }) do
	ns.On(e, Refresh)
end
-- (1.6.0: the Instinct of the Tracker)
for _, e in ipairs({ "TALENTS_CHANGED", "TALENT_USED", "TALENT_ARMED", "TALENT_RUNNING", "TALENT_PROC", "RESELL_BOUGHT" }) do
	local _, e = _, e; ns.On(e, function()
		BB:PaintActives()
	end)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "UPDATE_FACTION" }) do
	pcall(ev.RegisterEvent, ev, e)
end
CuratorOctoFull.SetScript(ev, "OnEvent", function()
	if BB.frame then
		BB:PlaceSoon()
		Refresh()
	end
end)
