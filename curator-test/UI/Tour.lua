local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-- The guided tour of the album. Step by step: a light around a part of the window (or one of its
-- tabs), and beside the window a bubble that tells what it is and what can be done there, with its
-- buttons (back, next, skip). It starts by itself the first time the album opens; the button (i) in
-- the corner of the album, or /curator tour, plays it again. The bubble stays outside the window where
-- the screen leaves room for it: the client draws the creatures of the cards above every frame, they
-- would hide it. While it plays, the album waits under it (its tabs and its pages follow the tour).
-- The bubble, the arrow and the light are drawn with the art of the game's own help.
local T = {}
ns.Tour = T

local BUBBLE_W, BUBBLE_MIN = 286, 200 -- the width of the bubble; under BUBBLE_MIN, it shrinks
local GAP = 22                        -- between the window and the bubble (its arrow in between)
local PAD = 14                        -- inside the bubble
local EDGE = 8                        -- from the edges of the screen
local GOLD = S.GOLD

-- The pieces of the art of the game's help: the bubble with its glow and its shadow, its arrow, and
-- the light around what is shown. { file, left, right, top, bottom }
local PARTS = "Interface\\TalentFrame\\TalentFrame-Parts"
local HORIZ = "Interface\\TalentFrame\\TalentFrame-Horizontal2"
local VERT = "Interface\\TalentFrame\\TalentFrame-Vertical2"
local GLOW = {
	tl = { PARTS, 0.91796875, 0.96093750, 0.65625000, 0.67773438 },
	tr = { PARTS, 0.12890625, 0.17187500, 0.96679688, 0.98828125 },
	bl = { PARTS, 0.30859375, 0.35156250, 0.96679688, 0.98828125 },
	br = { PARTS, 0.94921875, 0.99218750, 0.32226563, 0.34375000 },
	t = { HORIZ, 0, 1, 0.29687500, 0.33984375 },
	b = { HORIZ, 0, 1, 0.24609375, 0.28906250 },
	l = { VERT, 0.25781250, 0.30078125, 0, 1 },
	r = { VERT, 0.20703125, 0.25000000, 0, 1 },
}
local SHADOW = {
	tl = { PARTS, 0.89062500, 0.98828125, 0.45703125, 0.50585938 },
	tr = { PARTS, 0.66796875, 0.76562500, 0.77343750, 0.82226563 },
	bl = { PARTS, 0.77343750, 0.87109375, 0.77343750, 0.82226563 },
	br = { PARTS, 0.89062500, 0.98828125, 0.36523438, 0.41406250 },
	t = { HORIZ, 0, 1, 0.34765625, 0.44531250 },
	b = { HORIZ, 0, 1, 0.45312500, 0.55078125 },
	l = { VERT, 0.30859375, 0.40625000, 0, 1 },
	r = { VERT, 0.41406250, 0.51171875, 0, 1 },
}
-- (a corner drawn once, turned for the other three; an edge drawn once, turned for the other side)
local function Turned(corner, top, left)
	return {
		tl = { corner, 0, 1, 0, 1 }, tr = { corner, 1, 0, 0, 1 },
		bl = { corner, 0, 1, 1, 0 }, br = { corner, 1, 0, 1, 0 },
		t = { top, 0, 1, 0, 1 }, b = { top, 0, 1, 1, 0 },
		l = { left, 0, 1, 0, 1 }, r = { left, 1, 0, 0, 1 },
	}
end
local LIGHT = Turned("Interface\\Common\\GlowBorder-Corner", "Interface\\Common\\GlowBorder-Top", "Interface\\Common\\GlowBorder-Left")
local LINE = Turned("Interface\\Common\\ThinBorder2-Corner", "Interface\\Common\\ThinBorder2-Top", "Interface\\Common\\ThinBorder2-Left")
-- the arrow, 53 x 21, pointing down, and its glow, 65 x 28
local ARROW = { PARTS, 0.78515625, 0.99218750, 0.54687500, 0.58789063 }
local ARROW_GLOW = { PARTS, 0.40625000, 0.66015625, 0.77343750, 0.82812500 }

-- Eight pieces around a region: corners of size points, out points outside it, the edges between
-- them.
local function Ring(owner, set, size, out, layer, sub, blend)
	local t = {}
	for key, p in pairs(set) do
		local tex = owner:CreateTexture(nil, layer, nil, sub)
		tex:SetTexture(p[1])
		tex:SetTexCoord(p[2], p[3], p[4], p[5])
		if blend then
			tex:SetBlendMode(blend)
		end
		t[key] = tex
	end
	for _, key in ipairs({ "tl", "tr", "bl", "br" }) do
		CuratorOctoFull.SetSize(t[key], size, size)
	end
	t.tl:SetPoint("TOPLEFT", owner, "TOPLEFT", -out, out)
	t.tr:SetPoint("TOPRIGHT", owner, "TOPRIGHT", out, out)
	t.bl:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", -out, -out)
	t.br:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", out, -out)
	t.t:SetPoint("TOPLEFT", t.tl, "TOPRIGHT")
	t.t:SetPoint("BOTTOMRIGHT", t.tr, "BOTTOMLEFT")
	t.b:SetPoint("TOPLEFT", t.bl, "TOPRIGHT")
	t.b:SetPoint("BOTTOMRIGHT", t.br, "BOTTOMLEFT")
	t.l:SetPoint("TOPLEFT", t.tl, "BOTTOMLEFT")
	t.l:SetPoint("BOTTOMRIGHT", t.bl, "TOPRIGHT")
	t.r:SetPoint("TOPLEFT", t.tr, "BOTTOMLEFT")
	t.r:SetPoint("BOTTOMRIGHT", t.br, "TOPRIGHT")
	return t
end

-- The art of an arrow (pointing down) turned to point right (toward the window, the bubble on its
-- left) or left.
local function Point(tex, p, dir)
	local l, r, t, b = p[2], p[3], p[4], p[5]
	tex:SetTexture(p[1])
	if dir == "right" then
		tex:SetTexCoord(r, t, l, t, r, b, l, b)
	else
		tex:SetTexCoord(l, b, r, b, l, t, r, t)
	end
end

-------------------------------------------------------------------------------
-- The button (i) of the album
-------------------------------------------------------------------------------
-- In the corner of the album, as the button of the game's help in its windows: it starts the tour
-- (or ends it).
function T:Attach(f)
	if f.tourButton then
		return
	end
	local b = S.Button(f, "", 88, 24)
	b:SetPoint("LEFT", f, "TOPLEFT", 16, ns.Album.U.HEADER_Y)
	b:SetFrameLevel(f:GetFrameLevel() + 500)
	b.i = b:CreateTexture(nil, "ARTWORK")
	b.i:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	b.i:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetSize(b.i, 16, 16)
	b.i:SetPoint("LEFT", 8, 0)
	b.caption = S.Text(b, "GameFontNormalSmall", "LEFT")
	b.caption:SetPoint("LEFT", b.i, "RIGHT", 6, 0)
	b.caption:SetText("Guide")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		ns.Play(ns.SND.click)
		if T.active then
			T:Stop()
		else
			T:Start()
		end
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function()
		GameTooltip:SetOwner(b, "ANCHOR_RIGHT", -16, -16)
		GameTooltip:AddLine(L["Guided tour"], 1, 1, 1)
		GameTooltip:AddLine(L["A tour of the album and its pages."], GOLD[1], GOLD[2], GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.tourButton = b
	self.button = b
end

-------------------------------------------------------------------------------
-- The overlay, the light, the bubble
-------------------------------------------------------------------------------
-- How wide the tabs on the right edge of the album are.
function T:TabsWidth()
	local tab = ns.Album.frame.tabs[1]
	local w = tab and tab:GetWidth() or 0
	return (w and w > 0) and (w + 4) or 48
end

function T:Build()
	if self.overlay then
		return
	end
	local A = ns.Album
	local f = A.frame
	-- over the album and its tabs: they wait while the tour plays (its own buttons are above it)
	local o = CreateFrame("Frame", nil, f)
	o:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	o:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", self:TabsWidth(), 0)
	o:SetFrameLevel(f:GetFrameLevel() + 300)
	o:EnableMouse(true)
	o:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(o, "OnMouseWheel", function() end)
	o:Hide()
	self.overlay = o

	-- the light around what is shown: a thin line of gold, its glow breathing
	local hl = CreateFrame("Frame", nil, o)
	hl:SetFrameLevel(o:GetFrameLevel() + 2)
	CuratorOctoFull.SetSize(hl, 10, 10)
	hl.glow = Ring(hl, LIGHT, 16, 8, "BORDER", 0, "ADD")
	hl.line = Ring(hl, LINE, 8, 3, "BORDER", 1)
	for _, t in pairs(hl.line) do
		t:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	end
	self.light = hl

	-- the bubble: its shadow, its glow, its dark ground warmed from below, its arrow
	local b = CreateFrame("Frame", nil, o)
	b:SetFrameLevel(o:GetFrameLevel() + 10)
	CuratorOctoFull.SetSize(b, BUBBLE_W, 160)
	b:EnableMouse(true)
	Ring(b, SHADOW, 25, 16, "BACKGROUND", -2)
	Ring(b, GLOW, 11, 6, "BACKGROUND", -1, "ADD")
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 0)
	b.bg:SetPoint("TOPLEFT", 1, -1)
	b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
	CuratorOctoFull.ColorTexture(b.bg, 0, 0, 0, 0.94)
	b.warm = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.warm:SetPoint("TOPLEFT", 1, -1)
	b.warm:SetPoint("BOTTOMRIGHT", -1, 1)
	b.warm:SetTexture(MEDIA .. "Glow")
	-- (the upper half of the round glow: its light along the bottom of the bubble)
	b.warm:SetTexCoord(0, 1, 0, 0.5)
	b.warm:SetBlendMode("ADD")
	b.warm:SetVertexColor(0.5, 0.4, 0.05)
	b.warm:SetAlpha(0.55)
	b.arrowGlow = b:CreateTexture(nil, "BORDER")
	b.arrowGlow:SetBlendMode("ADD")
	b.arrowGlow:SetAlpha(0.5)
	CuratorOctoFull.SetSize(b.arrowGlow, 28, 65)
	b.arrow = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.arrow, 21, 53)
	b.arrowGlow:SetPoint("CENTER", b.arrow, "CENTER")

	b.title = S.Text(b, "GameFontNormalLarge", "LEFT")
	b.title:SetPoint("TOPLEFT", PAD, -PAD)
	b.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	CuratorOctoFull.SetWordWrap(b.title, false)
	b.text = S.Text(b, "GameFontHighlight", "LEFT")
	b.text:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -8)
	CuratorOctoFull.SetWordWrap(b.text, true)
	b.text:SetSpacing(2)
	b.count = S.Text(b, "GameFontDisableSmall", "LEFT")
	b.count:SetPoint("BOTTOMLEFT", PAD, PAD + 5)
	b.close = S.RedButton(b, "Exit")
	CuratorOctoFull.SetSize(b.close, 24, 24)
	b.close:SetPoint("TOPRIGHT", -5, -5)
	CuratorOctoFull.SetScript(b.close, "OnClick", function()
		ns.Play(ns.SND.close)
		T:Stop()
	end)
	CuratorOctoFull.SetScript(b.close, "OnEnter", function()
		GameTooltip:SetOwner(b.close, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Skip"], 1, 1, 1)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b.close, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b.next = S.Button(b, L["Next"], 90, 22)
	b.next:SetPoint("BOTTOMRIGHT", -PAD + 4, PAD - 2)
	CuratorOctoFull.SetScript(b.next, "OnClick", function()
		ns.Play(ns.SND.click)
		T:Go(T.i + 1)
	end)
	b.prev = S.Button(b, L["Previous"], 90, 22)
	b.prev:SetPoint("RIGHT", b.next, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(b.prev, "OnClick", function()
		ns.Play(ns.SND.click)
		if T.i <= 1 then
			T:Stop()
		else
			T:Go(T.i - 1)
		end
	end)
	self.bubble = b

	-- the glow of the light breathes
	CuratorOctoFull.SetScript(o, "OnUpdate", function(_, elapsed)
		T.t = (T.t or 0) + elapsed
		local a = 0.55 + 0.45 * math.sin(T.t * 3.4)
		for _, t in pairs(hl.glow) do
			t:SetAlpha(a)
		end
	end)
	-- the album closed: the tour ends
	CuratorOctoFull.HookScript(f, "OnHide", function()
		if T.active then
			T:Stop()
		end
	end)
end

-------------------------------------------------------------------------------
-- The steps
-------------------------------------------------------------------------------
-- What each tab is for, by its page.
local function TabText(mode)
	if mode == "contents" then
		-- (1.13.0: a tab for each kind of album)
		return L["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."]
	elseif mode == "guild" then
		return L["Your trades with other players, and the wanted cards: those you look for, and those you can give."]
	elseif mode == "contract" then
		-- (1.13.0, after its second test: a legendary card at most, the clause of the collection)
		return L["Ten copies of a rarity make a card of the next one, up to legendary. Ten copies of a single album give a card that album is missing."]
	elseif mode == "ach" then
		return L["Achievements give points and collector titles. Their rewards wait for you here."]
	elseif mode == "profile" then
		return L["Your collector level and the rewards of its track, your showcase and your finest pulls. Other players can see it."]
	elseif mode == "quests" then
		return L["Quests of the day, the week and the month, of the dungeons, the raids and PvP. They give experience and boosters."]
	elseif mode == "talents" then
		return string.format(L["From level %d, choose one of the five specializations for your account: each collector level gives a point to place in its talent tree."], ns.Talents and ns.Talents.CHOOSE or 5)
	elseif mode == "inns" then
		-- (1.8.0)
		return L["Talk to the innkeepers: a stamp a day on your loyalty card, a visa for each inn in your travel passport, and the loyalty of each innkeeper. Seven stamps make a booster."]
	elseif mode == "pvp" then
		return L["Your honorable kills become trophies: a battlemaster certifies them into the cards of the enemies you defeated. At the battlemaster too: your pay of the week, the bounties and the wanted poster."]
			.. " " .. L["Here too: your exploits in the battlegrounds and your own card as a combatant."]
	elseif mode == "rates" then
		-- (1.15.0: the statistics, UI/Rates.lua)
		return L["Every rate of Curator: the chance of each card of each booster, of each card on the creatures, the points of the bars, the contracts. Struck through: for everyone; beside it: with your talents."]
	elseif mode == "inventory" then
		-- (1.13.0; after its first test, the first tab, where the album opens: the boosters, the page of the boosters a part
		-- of it, its tab gone; then the copies)
		return L["Your boosters first: the booster of the place you are in, those of your other albums, your displays, and the rewards to choose that levels and quests give, one among three. The (i) of a booster tells its odds. The filters above show every copy of your cards, each with its story, its grade, its restorations: click one to see it up close."]
	end
	return ""
end

-- The steps: the page of the album, what is lit (a frame of the album, or a region of it from its top
-- left corner: x1, y1, x2, y2), on which side of the window the bubble is, what it says.
function T:Steps()
	local A = ns.Album
	local f = A.frame
	local U = A.U
	local W, Hh, HEAD, FOOT = U.WIDTH, U.HEIGHT, U.HEAD, U.FOOT
	local steps = {
		{ mode = "mine", side = "left", frame = f.body, title = L["Your album"],
			text = L["Each zone, dungeon and raid has its album, with a card for each of its creatures. Click a card you have to see it up close. Click a missing one to look for it: your guild will see it."] },
		-- (the name of the album between its arrows, its bar, the gems of the rarities)
		{ mode = "mine", side = "left", rect = { 56, -20, W - 10, -(HEAD - 2) }, title = L["Turn the albums"],
			text = L["The arrows go to the previous and the next album. The bar shows how far this one is: click it to show only the cards you have. The gems count each rarity: click one to show only its cards."] },
		-- (the bar under the page: the boosters of the album, the booster bar, the button)
		{ mode = "mine", side = "left", rect = { 6, -(Hh - FOOT - 1), W - 6, -(Hh - 3) }, title = L["Earn boosters"],
			text = L["Here are your boosters for this album and the booster bar, also shown over your experience bar. It fills where an album lives: creatures that give experience, quests and their objectives, new places, levels. Full, it gives a booster of the album of the place. The button on the right opens one."] },
	}
	for i, tab in ipairs(f.tabs) do
		local def = A.TABS and A.TABS[i]
		-- (1.12.0: not the tab of an event, there only while it lasts; 1.14.0: nor the chest of a reroll, shown on a reroll
		-- only, its own window tells of it)
		if not (def and (def.event or def.reroll)) then
			-- (the inventory: shown on its boosters, where it opens)
			local mode = tab.mode == "inventory" and "boosters" or tab.mode
			steps[CuratorOctoFull.Length(steps) + 1] = { mode = mode, side = "right", frame = tab, title = def and L[def.label] or "", text = TabText(tab.mode) }
		end
	end
	-- (the button (i); without it, the corner of the window where it would be)
	steps[CuratorOctoFull.Length(steps) + 1] = { mode = "mine", side = "left", frame = self.button, rect = { 16, -7, 104, -31 }, title = L["Your turn!"],
		text = L["This button (or /curator tour) plays the tour again. A tip: the button at the top right of the booster scene opens your boosters in a small window, to keep an eye on the world while you walk."] }
	return steps
end

-------------------------------------------------------------------------------
-- Playing
-------------------------------------------------------------------------------
-- The first time the album opens: the tour, once (not on another player's collection). A collection
-- begun before (OLD boosters opened or more) is only told of it in the chat: the tour plays by itself
-- for a new player alone (1.1.1: it played for everyone who updated).
local OLD = 10

function T:Offer()
	if self.active or self.offering or not ns.db or ns.db.tour then
		return
	end
	local A = ns.Album
	if A.member then
		return
	end
	if (ns.db.opened or 0) >= OLD then
		ns.db.tour = true
		ns.Print(L["/curator tour: a guided tour of the album"])
		return
	end
	self.offering = true
	ns.Delay(0.4, function()
		self.offering = nil
		if ns.db and not ns.db.tour and A.frame:IsShown() and not A.member and not self.active then
			self:Start()
		end
	end, self)
end

-- The tour from its start, on my own album (the album of the place I am in, else the one shown).
function T:Start()
	local A = ns.Album
	if not ns.db or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	if self.active then
		self:Stop()
	end
	A:Build()
	ns.db.tour = true
	local shown = A.frame:IsShown()
	-- (where the album was: back there at the end)
	self.back = shown and not A.member and { mode = A.mode, series = A.series } or nil
	if not shown or A.member or A.mode ~= "mine" then
		local here = ns.Rewards and ns.Rewards:ZoneSeries()
		A:Open("mine", here or A.series or ns.CurrentSeries())
	end
	if not A.frame:IsShown() then
		return
	end
	self:Build()
	self.steps = self:Steps()
	self.active = true
	self.t = 0
	self.overlay:Show()
	self:Go(1)
end

-- Step i (past the last one: the end).
function T:Go(i)
	local step = self.steps and self.steps[i]
	if not step then
		return self:Stop()
	end
	local A = ns.Album
	self.i = i
	A:HideDetail()
	if step.mode and (A.mode ~= step.mode or A.member) then
		A:SetMode(step.mode)
	end
	self:Light(step)
	self:Fill(step)
	self:Place(step)
	if i > 1 then
		ns.Play(ns.SND.page)
	end
end

-- The tour ends (finished, skipped, or the album closed): the album as it was.
function T:Stop()
	if not self.active then
		return
	end
	self.active = false
	ns.CancelOwner(self)
	self.overlay:Hide()
	GameTooltip:Hide()
	local A = ns.Album
	local back = self.back
	self.back = nil
	if back and back.mode and A.frame:IsShown() and (A.mode ~= back.mode or A.series ~= back.series) and back.mode ~= "member" then
		A:Open(back.mode, back.series)
	end
end

-- The light around what the step shows.
function T:Light(step)
	local hl = self.light
	local f = ns.Album.frame
	hl:ClearAllPoints()
	if step.frame then
		-- (4 points around it; inset: that far inside it)
		local d = -(step.inset or -4)
		hl:SetPoint("TOPLEFT", step.frame, "TOPLEFT", -d, d)
		hl:SetPoint("BOTTOMRIGHT", step.frame, "BOTTOMRIGHT", d, -d)
	elseif step.rect then
		local r = step.rect
		hl:SetPoint("TOPLEFT", f, "TOPLEFT", r[1], r[2])
		hl:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", r[3], r[4])
	else
		hl:Hide()
		return
	end
	hl:Show()
end

-- Its words and its buttons, at the width the screen leaves it.
function T:Fill(step, width)
	local b = self.bubble
	local w = width or b:GetWidth() or BUBBLE_W
	b:SetWidth(w)
	b.title:SetWidth(w - 2 * PAD - 22)
	b.title:SetText(step.title or "")
	b.text:SetWidth(w - 2 * PAD)
	b.text:SetText(step.text or "")
	local n = CuratorOctoFull.Length(self.steps)
	b.count:SetText(string.format(("%d / %d"), self.i, n))
	local last = self.i >= n
	b.next:SetText(last and L["Done"] or L["Next"])
	b.prev:SetText(self.i <= 1 and L["Skip"] or L["Previous"])
	for _, btn in ipairs({ b.next, b.prev }) do
		btn:SetWidth(math.max(74, math.ceil(ns.TextWidth(btn:GetFontString()) + 26)))
	end
	-- (no room for the number of the step beside the buttons: it goes)
	local room = w - 2 * PAD - b.next:GetWidth() - b.prev:GetWidth() - 6
	CuratorOctoFull.SetShown(b.count, room >= ns.TextWidth(b.count) + 8)
	-- its height: the words wrapped in its width (the client tells; a guess where it cannot)
	local th = CuratorOctoFull.GetStringHeight(b.text) or 0
	local guess = math.ceil(ns.TextWidth(b.text) / math.max(1, w - 2 * PAD)) * 14
	if th < guess * 0.6 then
		th = guess
	end
	local hh = CuratorOctoFull.GetStringHeight(b.title) or 16
	b:SetHeight(math.floor(PAD + hh + 8 + th + 16 + 22 + PAD - 4 + 0.5))
end

-- Where a step's region is on the screen: left, right, bottom, top (points of the screen).
local function Box(r)
	local l, rr, bt, tp = r:GetLeft(), r:GetRight(), r:GetBottom(), r:GetTop()
	if not (l and rr and bt and tp) then
		return nil
	end
	local k = CuratorOctoFull.GetEffectiveScale(r) / CuratorOctoFull.GetEffectiveScale(UIParent)
	return l * k, rr * k, bt * k, tp * k
end

-- The bubble beside the window, on the side of the step where there is room (else the other side;
-- else smaller), level with what is lit, kept on the screen; its arrow toward it.
function T:Place(step)
	local b = self.bubble
	local f = ns.Album.frame
	local fl, fr, fb, ft = Box(f)
	local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
	if not (fl and pw and ph) then
		return
	end
	-- (1.11.0) the album at its size (UI/Options.lua): its lengths in those of the screen
	local s = CuratorOctoFull.GetEffectiveScale(f) / CuratorOctoFull.GetEffectiveScale(UIParent)
	local tabsW = self:TabsWidth() * s
	local tl, tr, tb, tt
	if step.frame then
		tl, tr, tb, tt = Box(step.frame)
	end
	if not tl then
		local r = step.rect or { 0, 0, (fr - fl) / s, -(ft - fb) / s }
		tl, tr, tt, tb = fl + r[1] * s, fl + r[3] * s, ft + r[2] * s, ft + r[4] * s
	end
	local ty = (tb + tt) / 2
	local side = step.side
	local roomL = fl - EDGE - GAP
	local roomR = pw - (fr + tabsW) - EDGE - GAP
	local room = side == "left" and roomL or roomR
	local other = side == "left" and roomR or roomL
	if room < BUBBLE_MIN and other > room then
		side = side == "left" and "right" or "left"
		room = other
	end
	local w = math.max(BUBBLE_MIN, math.min(BUBBLE_W, room))
	local k = room < BUBBLE_MIN and math.max(0.6, room / BUBBLE_MIN) or 1
	-- (the bubble is in the album: on the screen, at its own size whatever the size of the album)
	b:SetScale(k / s)
	self:Fill(step, w)
	local bh = b:GetHeight() * k
	-- level with what is lit, on the screen
	local cy = math.max(EDGE + bh / 2, math.min(ph - EDGE - bh / 2, ty))
	local dy = (cy - (fb + ft) / 2) / k
	b:ClearAllPoints()
	if side == "left" then
		b:SetPoint("RIGHT", f, "LEFT", -GAP / k, dy)
	else
		b:SetPoint("LEFT", f, "RIGHT", (tabsW + GAP) / k, dy)
	end
	-- the arrow, from the edge of the bubble toward it
	local ay = math.max(-(bh / 2 - 28), math.min(bh / 2 - 28, ty - cy)) / k
	local dir = side == "left" and "right" or "left"
	Point(b.arrow, ARROW, dir)
	Point(b.arrowGlow, ARROW_GLOW, dir)
	b.arrow:ClearAllPoints()
	if side == "left" then
		b.arrow:SetPoint("LEFT", b, "RIGHT", -3, ay)
	else
		b.arrow:SetPoint("RIGHT", b, "LEFT", 3, ay)
	end
	self.side = side
end
