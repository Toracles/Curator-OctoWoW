local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease
local S = ns.Skin
local C = ns.Collection

-------------------------------------------------------------------------------
-- A card looked at closely, as a card held in the hand (1.3; in 3D, 1.3.1: UI/Card.lua). Drag it to
-- turn it: all the way round, its back showing past a quarter turn, and up and down (dragged up, its
-- top goes away); let go, it keeps turning a moment, slows down and settles on the side it shows, and
-- comes back upright; the mouse over it, it leans a little toward it; a click turns it over; the
-- mouse wheel brings it closer or farther. While it moves, its creature stands still in it, as a
-- figure set in the card. In the booster scene (a card turned over, clicked: B:Inspect, with what
-- there is to know of it beside it), in the detail of a card of the album (UI/Album.lua) and in the
-- window of a card shown in the chat (UI/Links.lua). The legendary and mythic cards can play their
-- entrance again from there (I:Replay).
-------------------------------------------------------------------------------
local I = {}
ns.Inspect = I

local PER_POINT = 0.011  -- radians a point dragged turns it
local PITCH_MAX = 1.05   -- how far it tilts up or down (a client that cannot draw it in 3D: 0.3)
local FRICTION = 2.4     -- how fast a card let go slows down
local KEEP = 0.9         -- under this speed (radians a second) it settles on a side
local SETTLE = 7         -- how fast it settles
local CLICK = 5          -- points moved at most for a click
local HOVER = 0.16       -- how far it leans toward the mouse over it
local STILL = 0.02       -- nearer than this to its rest (radians): still, its creature lives again

-- The nearest side: a multiple of a half turn.
local function Nearest(yaw)
	return math.floor(yaw / math.pi + 0.5) * math.pi
end
I.Nearest = Nearest

-- card: a card of UI/Card.lua (1.14.0: or of a case, UI/CrateCard.lua). holder: the frame it sits in, scaled for the
-- zoom (anchored without an offset, so that it stays where it is). opts: zoom = { least, most, at first }; lean =
-- false: it does not lean toward the mouse (a card of a case: flat at rest, all that moves on it alive).
function I:Attach(card, holder, opts)
	opts = opts or {}
	local z = opts.zoom or { 0.8, 1.6, 1 }
	local t = { yaw = 0, pitch = 0, vy = 0, hy = 0, hp = 0, zoom = z[3] or 1, zoomTo = z[3] or 1, min = z[1], max = z[2], holder = holder,
		lean = opts.lean ~= false }
	card.turn = t
	-- (its creature turns with it: framed whatever its facing)
	card.spin = true
	-- (31 October, his idea: the creatures in 2D) A card of a portrait (UI/Card.lua): its creature in 3D on asking. The card
	-- faces you and stays still, the hand turns its creature in it; asked again, its portrait back (I:Live3D).
	if card.art and card.art.portrait and not card.see3D then
		local b = S.Button(card, L["See in 3D"], 130, 22)
		b:SetPoint("TOP", card, "BOTTOM", 0, -12)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			I:Live3D(card, not card.live3D)
		end)
		b:Hide()
		card.see3D = b
	end
	card:EnableMouse(true)
	if card.RegisterForClicks then
		card:RegisterForClicks()
	end
	CuratorOctoFull.SetScript(card, "OnMouseDown", function(_, button)
		if button ~= "LeftButton" then
			return
		end
		local x, y = GetCursorPosition()
		t.dragging, t.lx, t.ly, t.moved, t.target, t.vy = true, x, y, 0, nil, 0
	end)
	CuratorOctoFull.SetScript(card, "OnMouseUp", function(_, button)
		if button ~= "LeftButton" or not t.dragging then
			return
		end
		t.dragging = false
		if t.moved <= CLICK and not card.live3D then
			-- a click: it turns over
			t.vy = 0
			t.target = Nearest(t.yaw) + math.pi
			ns.Play(ns.SND.cardFlip)
		end
	end)
	return t
end

-- Closer (delta > 0) or farther.
function I:Zoom(card, delta)
	local t = card.turn
	if t then
		t.zoomTo = math.max(t.min, math.min(t.max, t.zoomTo * ((delta > 0) and 1.12 or (1 / 1.12))))
	end
end

-- The card as it is turned, tilted and leaning: in 3D, or squeezed (a client that cannot draw it so).
local function Pose(card, t)
	if ns.Can3D() then
		card:SetPose(t.yaw + t.hy, t.pitch + t.hp)
	else
		card:SetTurn(t.yaw, t.pitch)
	end
end

-- (31 October, his idea) Its creature in 3D (on), or its portrait again: the card comes to face you; its creature loaded
-- for it alone (UI/Card.lua: SetCard keeps it for this card).
function I:Live3D(card, on)
	local t = card.turn
	local m = card.model
	if not (t and m and card.card and card.portraitOn) then
		return
	end
	card.live3D = on and true or nil
	card.liveCard = on and card.card or nil
	if on then
		-- (its face toward you, upright, still)
		t.yaw = math.floor(t.yaw / (2 * math.pi) + 0.5) * 2 * math.pi
		t.pitch, t.vy, t.target, t.hy, t.hp = 0, 0, nil, 0, 0
		card.liveYaw = 0
		card.turnFacing = 0.4
	end
	CuratorOctoFull.SetShown(card.art.portrait, not on)
	m.display = on and card.card.display or nil
	m.facing = 0.4
	card:ReloadModel()
	if card.see3D then
		card.see3D:SetText(L[on and "See the card" or "See in 3D"])
	end
	if card.held then
		card:HeldSync()
	end
	Pose(card, t)
end

-- Faces you at once (yaw: turned that much at first, to come round).
function I:Reset(card, yaw, zoom)
	local t = card.turn
	t.yaw, t.pitch, t.vy, t.target, t.dragging = yaw or 0, 0, 0, nil, false
	t.hy, t.hp = 0, 0
	if zoom then
		t.zoom, t.zoomTo = zoom, zoom
	end
	t.holder:SetScale(t.zoom)
	t.side = nil
	card.turnFacing = 0.4
	Pose(card, t)
end

-- Is it moving (turned by the hand, turning on, settling, coming back upright)?
function I:Moving(card)
	local t = card.turn
	return t and (t.dragging or t.target ~= nil or t.vy ~= 0 or math.abs(t.pitch) > STILL or math.abs(t.yaw - Nearest(t.yaw)) > STILL) or false
end

-- Every frame (from its owner): it follows the hand, or turns on and settles; the zoom eases.
function I:Update(card, elapsed)
	local t = card.turn
	if not t then
		return
	end
	elapsed = math.min(elapsed or 0, 0.1)
	local in3D = ns.Can3D()
	local most = in3D and PITCH_MAX or 0.3
	-- (1.11.0) held still by a scene (the appraisal of a card, UI/Expertise.lua): its pose is the scene's,
	-- the hand has no hold on it meanwhile; the zoom still eases
	local hold = t.hold
	if hold then
		t.dragging, t.target, t.vy, t.hy, t.hp = false, nil, 0, 0, 0
		t.yaw, t.pitch = hold.yaw or 0, math.max(-most, math.min(most, hold.pitch or 0))
		t.side = math.cos(t.yaw) >= 0
		if math.abs(t.zoomTo - t.zoom) > 0.0005 then
			t.zoom = t.zoom + (t.zoomTo - t.zoom) * math.min(1, elapsed * 10)
			t.holder:SetScale(t.zoom)
		end
		card:Freeze(false)
		Pose(card, t)
		return
	end
	if t.dragging then
		local x, y = GetCursorPosition()
		-- (points of the place it is in: closer, it does not turn slower)
		local k = CuratorOctoFull.GetEffectiveScale((t.holder:GetParent() or UIParent))
		if not k or k <= 0 then
			k = 1
		end
		local dx, dy = (x - t.lx) / k, (y - t.ly) / k
		t.lx, t.ly = x, y
		t.moved = t.moved + math.abs(dx) + math.abs(dy)
		if card.live3D then
			-- (its creature in 3D: the hand turns it, the card stays as it is)
			card.liveYaw = (card.liveYaw or 0) + dx * PER_POINT
			card.turnFacing = 0.4 + card.liveYaw
			card.model.facing = card.turnFacing
		else
			t.yaw = t.yaw + dx * PER_POINT
			-- (dragged up: its top goes away, as a card pushed up by the finger)
			t.pitch = math.max(-most, math.min(most, t.pitch - dy * PER_POINT))
			local v = dx * PER_POINT / math.max(elapsed, 1 / 120)
			t.vy = t.vy + (v - t.vy) * math.min(1, elapsed * 14)
		end
	else
		if t.target then
			local d = t.target - t.yaw
			if math.abs(d) < 0.004 then
				t.yaw, t.target = t.target, nil
			else
				t.yaw = t.yaw + d * math.min(1, elapsed * 9)
			end
		elseif math.abs(t.vy) > KEEP then
			t.yaw = t.yaw + t.vy * elapsed
			t.vy = t.vy * math.exp(-FRICTION * elapsed)
		else
			t.vy = 0
			local goal = Nearest(t.yaw)
			local d = goal - t.yaw
			t.yaw = (math.abs(d) < 0.001) and goal or (t.yaw + d * math.min(1, elapsed * SETTLE))
		end
		t.pitch = t.pitch * math.max(0, 1 - elapsed * 6)
	end
	-- (the paper sound as it goes edge on and shows its other side)
	local side = math.cos(t.yaw) >= 0
	if t.side ~= nil and side ~= t.side then
		ns.Play(ns.SND.cardFlip)
	end
	t.side = side
	if math.abs(t.zoomTo - t.zoom) > 0.0005 then
		t.zoom = t.zoom + (t.zoomTo - t.zoom) * math.min(1, elapsed * 10)
		t.holder:SetScale(t.zoom)
	end
	-- the mouse over it (not held): it leans a little toward it, the point under the mouse pressed down
	local hy, hp = 0, 0
	if in3D and t.lean and not t.dragging and not card.live3D and card:IsMouseOver() then
		local x, y = GetCursorPosition()
		local s = CuratorOctoFull.GetEffectiveScale(card)
		local cx, cy = card:GetCenter()
		if s and s > 0 and cx and cy then
			hy = HOVER * math.max(-1, math.min(1, (x / s - cx) / (card.W / 2)))
			hp = -HOVER * math.max(-1, math.min(1, (y / s - cy) / (card.H / 2)))
		end
	end
	local e = math.min(1, elapsed * 8)
	t.hy = t.hy + (hy - t.hy) * e
	t.hp = t.hp + (hp - t.hp) * e
	-- while it moves, its creature stands still in it
	card:Freeze(self:Moving(card))
	Pose(card, t)
end

-- Its entrance played again (a legendary or mythic card; the button waits for its end). full: over the
-- whole screen, even with the boosters open in their small window (from the album, from the chat).
-- False if it cannot play now.
function I:Replay(card, finish, button, full)
	local cin = ns.Cinematic
	if not (cin and card and card.rarity >= 5) or cin:IsPlaying() then
		return false
	end
	local B = ns.Booster
	if B and B.frame and B.frame:IsShown() and B.StopMusic then
		-- (the entrance has its own music)
		B:StopMusic(900)
	end
	if button then
		button:Disable()
	end
	local ok = cin:Play(card, { finish = finish, full = full }, nil, function()
		if button then
			button:Enable()
		end
	end)
	if not ok and button then
		button:Enable()
	end
	return ok and true or false
end

-------------------------------------------------------------------------------
-- In the booster scene: a card turned over, clicked
-------------------------------------------------------------------------------
local B = ns.Booster
local GOLD = { 1, 0.82, 0 }
local INFO_W = 330

-- The creatures of the other cards of the scene: the client draws the models of a strata after its
-- textures, so theirs would come through the card held and its words. Hidden while it is held; back
-- (their creature loaded again) when it is put back. (As during an entrance: UI/Cinematic.lua.)
local function Within(frame, root)
	local p = frame
	while p do
		if p == root then
			return true
		end
		p = p:GetParent()
	end
	return false
end

function B:HideOthers(keep)
	self:ShowOthers()
	local hidden = {}
	for c in pairs(ns.AllCards or {}) do
		local m = c.model
		if c ~= keep and m and m:IsShown() and m:IsVisible() and Within(c, self.frame) then
			m:Hide()
			hidden[CuratorOctoFull.Length(hidden) + 1] = c
		end
	end
	self.heldHidden = hidden
end

-- The buttons in the corner of the scene (the small window, its closing) step aside while a card is held:
-- its own cross takes their place.
function B:CornerAside(on)
	local s = self.frame
	if not s then
		return
	end
	for _, b in ipairs({ s.size, s.shut }) do
		if b then
			b:SetAlpha(on and 0 or 1)
		end
	end
end

-- A card turned over while one is held: its creature waits too.
function B:HideWhileHeld(c)
	if self.inspecting and self.heldHidden and c.model and c.model:IsShown() then
		c.model:Hide()
		CuratorOctoFull.Insert(self.heldHidden, c)
	end
end

function B:ShowOthers()
	local hidden = self.heldHidden
	self.heldHidden = nil
	-- (an entrance playing: they come back with its last flash)
	local cin = ns.Cinematic
	local wait = cin and cin.playing and cin.hiddenCards
	for _, c in ipairs(hidden or {}) do
		if wait then
			CuratorOctoFull.Insert(wait, c)
		else
			c.model:Show()
			if c.front:IsShown() and c.model.display then
				c:ReloadModel()
			end
		end
	end
end

function B:BuildInspect()
	local s = self.frame
	if s.inspect then
		return s.inspect
	end
	-- over the whole scene: the place dark, the card held up in its light, what there is to know of it
	local o = CreateFrame("Button", nil, s)
	o:SetAllPoints()
	o:SetFrameLevel(s:GetFrameLevel() + 100)
	o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	-- (1 November, his word: « si on appuie sur un endroit où y'a pas de bouton, ça ferme le sous menu. J'aimerai un
	-- "Retour" »: a click beside the card does nothing any more; Back under it, o.back)
	o.dim = o:CreateTexture(nil, "BACKGROUND")
	o.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(o.dim, 0.01, 0.01, 0.02, 0.8)
	-- where the card is held, where its words are (frames without an offset in them: scaled in place)
	o.spot = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(o.spot, 1, 1)
	o.spot:SetPoint("CENTER", o, "CENTER", -175, 10)
	o.halo = o:CreateTexture(nil, "BORDER")
	o.halo:SetTexture(MEDIA .. "Glow")
	o.halo:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(o.halo, 620, 700)
	o.halo:SetPoint("CENTER", o.spot, "CENTER")
	o.rays = o:CreateTexture(nil, "BORDER", nil, 1)
	o.rays:SetTexture(MEDIA .. "Rays")
	o.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(o.rays, 760, 760)
	o.rays:SetPoint("CENTER", o.spot, "CENTER")
	o.holder = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(o.holder, 1, 1)
	o.holder:SetPoint("CENTER", o.spot, "CENTER")
	local card = ns.NewCard(o.holder, "huge")
	card:SetPoint("CENTER", o.holder, "CENTER")
	o.card = card
	ns.Inspect:Attach(card, o.holder, { zoom = { 0.8, 1.7, 1.1 } })
	o:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(o, "OnMouseWheel", function(_, delta)
		ns.Inspect:Zoom(card, delta)
	end)
	-- Escape: back to the cards, not out of the scene (when the client lets the key stop there)
	CuratorOctoFull.SetScript(o, "OnKeyDown", function(self, key)
		local mine = key == "ESCAPE"
		if not (InCombatLockdown and InCombatLockdown()) and self.SetPropagateKeyboardInput then
			pcall(self.SetPropagateKeyboardInput, self, not mine)
		end
		if mine then
			B:CloseInspect()
		end
	end)

	-- what there is to know of it
	o.infoSpot = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(o.infoSpot, 1, 1)
	o.infoSpot:SetPoint("CENTER", o, "CENTER", 40, 175)
	local f = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(f, INFO_W, 360)
	f:SetPoint("TOPLEFT", o.infoSpot, "CENTER")
	o.info = f
	f.name = S.Text(f, "GameFontNormalHuge", "LEFT")
	f.name:SetPoint("TOPLEFT", 0, 0)
	f.name:SetWidth(INFO_W)
	CuratorOctoFull.SetWordWrap(f.name, true)
	f.gem = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.gem, 22, 22)
	f.gem:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", -2, -10)
	f.rar = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.rar:SetPoint("LEFT", f.gem, "RIGHT", 5, 0)
	f.line = S.Text(f, "GameFontHighlight", "LEFT")
	f.line:SetPoint("TOPLEFT", f.gem, "BOTTOMLEFT", 2, -10)
	f.rule = S.Divider(f, INFO_W, 0.9)
	f.rule:SetPoint("TOPLEFT", f.line, "BOTTOMLEFT", 0, -12)
	f.set = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.set, 22, 22)
	f.set:SetPoint("TOPLEFT", f.rule, "BOTTOMLEFT", -2, -12)
	f.album = S.Text(f, "GameFontHighlight", "LEFT")
	f.album:SetPoint("LEFT", f.set, "RIGHT", 6, 0)
	f.album:SetWidth(INFO_W - 30)
	CuratorOctoFull.SetWordWrap(f.album, false)
	f.copies = S.Text(f, "GameFontHighlight", "LEFT")
	f.copies:SetPoint("TOPLEFT", f.set, "BOTTOMLEFT", 2, -12)
	f.copies:SetWidth(INFO_W)
	CuratorOctoFull.SetWordWrap(f.copies, true)
	f.new = S.Text(f, "GameFontNormal", "LEFT")
	f.new:SetPoint("TOPLEFT", f.copies, "BOTTOMLEFT", 0, -8)
	f.new:SetTextColor(1, 0.82, 0.25)
	f.new:SetText(L["New!"])
	f.link = S.Button(f, L["Show in the chat"], 160, 24)
	f.link:SetPoint("TOPLEFT", f.new, "BOTTOMLEFT", -2, -16)
	CuratorOctoFull.SetScript(f.link, "OnClick", function()
		local p = o.pick
		if p and ns.Links then
			-- (1.14.3: the copy that came, its very card: UI/Links.lua)
			ns.Links:Insert(p.card, p.finish, p.pt, nil, p.ci and ns.Copies and ns.Copies:Get(p.card.key, p.ci) or nil)
		end
	end)
	f.replay = S.Button(f, L["Replay its entrance"], 190, 24)
	f.replay:SetPoint("LEFT", f.link, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(f.replay, "OnClick", function(self)
		local p = o.pick
		if p then
			ns.Inspect:Replay(p.card, p.finish, self)
		end
	end)
	-- (in the corner of the scene, where its own buttons step aside meanwhile)
	o.close = S.CloseButton(o)
	o.close:SetPoint("TOPRIGHT", -12, -12)
	CuratorOctoFull.SetScript(o.close, "OnClick", function()
		B:CloseInspect()
	end)
	o.hintSpot = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(o.hintSpot, 1, 1)
	o.hintSpot:SetPoint("CENTER", o, "CENTER", 0, -300)
	o.hint = S.Text(o, "GameFontDisable")
	o.hint:SetPoint("CENTER", o.hintSpot, "CENTER")
	o.hint:SetText(L["Drag to turn the card · Mouse wheel to zoom"])
	-- (1 November: back to the cards, the one way; the cross of its corner no more)
	o.back = S.Button(o, L["Back"], 150, 26)
	o.back:SetPoint("TOP", o.hint, "BOTTOM", 0, -10)
	o.back:SetFrameLevel(o:GetFrameLevel() + 30)
	CuratorOctoFull.SetScript(o.back, "OnClick", function()
		B:CloseInspect()
	end)
	o.close:Hide()

	CuratorOctoFull.SetScript(o, "OnUpdate", function(_, elapsed)
		o.t = (o.t or 0) + elapsed
		ns.Inspect:Update(card, elapsed)
		card:Tick(o.t)
		CuratorOctoFull.SetRotation(o.rays, o.t * 0.08)
		-- brought closer: it comes to the middle, its words step aside
		local k = math.max(0, math.min(1, (card.turn.zoom - 1.15) / 0.4))
		if k ~= o.focus then
			B:FocusInspect(k)
		end
	end)
	o:Hide()
	s.inspect = o
	return o
end

-- k: 0 the card on the left and its words beside it, 1 the card brought close, in the middle, alone.
function B:FocusInspect(k)
	local o = self.frame.inspect
	o.focus = k
	o.spot:ClearAllPoints()
	o.spot:SetPoint("CENTER", o, "CENTER", (o.x0 or -175) * (1 - k), 10)
	o.info:SetAlpha(1 - k)
	CuratorOctoFull.SetShown(o.info, k < 0.99)
	o.hint:SetAlpha(1 - k)
end

-- What there is to know of it, at the scale of the words of the scene (larger in the small window).
function B:PaintInspect(pick)
	local o = self.frame.inspect
	local f = o.info
	local card = pick.card
	local r = ns.RARITY[card.rarity]
	local s = card.series
	-- (the small window: its words larger, the card to the left to leave them room)
	local small = self.Small and self:Small()
	local ui = math.min(self.uiK or 1, 1.5)
	o.x0 = small and -250 or -175
	self:FocusInspect(0)
	o.infoSpot:ClearAllPoints()
	o.infoSpot:SetPoint("CENTER", o, "CENTER", small and -80 or 40, small and 205 or 175)
	o.hintSpot:ClearAllPoints()
	o.hintSpot:SetPoint("CENTER", o, "CENTER", 0, small and -330 or -300)
	for _, x in ipairs({ f, o.hint, o.close, o.back }) do
		if x.SetScale then
			x:SetScale(ui)
		end
	end
	local k = (o.close.GetScale and o.close:GetScale()) or 1
	o.close:ClearAllPoints()
	o.close:SetPoint("TOPRIGHT", o, "TOPRIGHT", -12 / k, -12 / k)
	S.SetFontObject(f.name, "GameFontNormalHuge")
	f.name:SetText(C:Name(card))
	if ns.TextWidth(f.name) > INFO_W * 0.98 then
		S.Fit(f.name, C:Name(card), INFO_W * 0.98, 19, 15)
	end
	f.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.gem:SetTexture(MEDIA .. "Gem" .. card.rarity)
	local fin = C:FinishName(card, pick.finish)
	-- (1 November, his word: the pattern of a titanforged card told by the masters of the mages only, Mages.lua; a card
	-- just found is never certified yet)
	f.rar:SetText(L[r.label] .. (fin and ("  ·  " .. fin) or ""))
	f.rar:SetTextColor(r.text[1], r.text[2], r.text[3])
	f.line:SetText(C:Line(card))
	f.set:SetTexture(MEDIA .. (s.set or "SetElwynn"))
	local g = s.glow or GOLD
	f.set:SetVertexColor(0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3])
	f.album:SetText(string.format(("%s · %d/%d"), C:SeriesName(s), card.num, s.official or CuratorOctoFull.Length(s.list)))
	-- (a preview keeps nothing: what the collection has of it)
	local e = C:Entry(card)
	local parts = { string.format(L["Copies: %d"], e and e.n or 0) }
	if e and (e.s or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = C:CopiesLine(card, "shiny", e.s)
	end
	if e and (e.h or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = C:CopiesLine(card, "holo", e.h)
	end
	f.copies:SetText(table.concat(parts, "   ·   "))
	local new = pick.new and not (self.opts and self.opts.test)
	CuratorOctoFull.SetShown(f.new, new and true or false)
	f.link:ClearAllPoints()
	f.link:SetPoint("TOPLEFT", new and f.new or f.copies, "BOTTOMLEFT", -2, -16)
	-- (1.13.0: a card of a picture, the Hardcup Saison 3, has no entrance to play again)
	CuratorOctoFull.SetShown(f.replay, card.rarity >= 5 and not (card.art and card.art.fill))
	CuratorOctoFull.SetEnabled(f.replay, not (ns.Cinematic and ns.Cinematic:IsPlaying()))
	o.halo:SetVertexColor(r.glow[1], r.glow[2], r.glow[3])
	o.rays:SetVertexColor(r.glow[1], r.glow[2], r.glow[3])
end

-- A card turned over, clicked: it comes up close, turning to face you.
function B:Inspect(c)
	local pick = c and c.pick
	if not (pick and c.revealed) or (ns.Cinematic and ns.Cinematic:IsPlaying()) then
		return
	end
	local o = self:BuildInspect()
	ns.CancelOwner(o)
	o.pick = pick
	self.inspecting = c
	self:HideOthers(o.card)
	self:CornerAside(true)
	GameTooltip:Hide()
	local card = o.card
	o:SetAlpha(0)
	o:Show()
	-- (31 October, his word: the very copy that came out, its wear and its corruption on it, as in the scene)
	card:SetCard(pick.card, { owned = true, opening3D = c.openingModel, finish = pick.finish, count = pick.count, new = pick.new and not (self.opts and self.opts.test), facing = 0.4,
		pattern = pick.pt, corrupt = pick.corrupt, wear = pick.wear })
	card:ShowSide("front")
	card.phase = c.phase
	ns.Inspect:Reset(card, -1.3, 0.8)
	card.turn.zoomTo = 1.1
	self:PaintInspect(pick)
	local r = pick.card.rarity
	o.halo:SetAlpha(0.18 + 0.05 * r)
	o.rays:SetAlpha(r >= 3 and (0.1 + 0.06 * (r - 3)) or 0)
	if not (InCombatLockdown and InCombatLockdown()) then
		o:EnableKeyboard(true)
		if o.SetPropagateKeyboardInput then
			pcall(o.SetPropagateKeyboardInput, o, true)
		end
	end
	ns.Play(ns.SND.cardFlip)
	ns.Tween(0.2, function(e)
		o:SetAlpha(e)
	end, nil, Ease.outQuad, o)
	-- (once it has come round to face you: its creature, still while the card turned, plays)
	ns.Delay(0.55, function()
		if o:IsShown() and o.pick == pick then
			card:Animate(o)
			card:PlayVoice()
		end
	end, o)
end

-- Back to the cards (quick: at once, the scene resets or closes).
function B:CloseInspect(quick)
	local o = self.frame and self.frame.inspect
	local function gone()
		if o then
			o:Hide()
			o:SetAlpha(1)
		end
		self.inspecting = nil
		self:ShowOthers()
		self:CornerAside(false)
	end
	if not (o and o:IsShown()) then
		gone()
		return
	end
	o.card.turn.dragging = false
	if not (InCombatLockdown and InCombatLockdown()) then
		o:EnableKeyboard(false)
	end
	ns.CancelOwner(o)
	if quick then
		gone()
		return
	end
	ns.Play(ns.SND.close)
	local from = o:GetAlpha()
	ns.Tween(0.15, function(e)
		o:SetAlpha(from * (1 - e))
	end, gone, Ease.outQuad, o)
end
