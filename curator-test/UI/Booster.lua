local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

local B = {}
ns.Booster = B
-- (the button that leaves the scene, by where the booster was opened from: its page again; 1 November, the inventory)
B.BACK_LABEL = { boosters = "Boosters", inventory = "Inventory" }

local GAP = 26
local SLOT_Y = -4
local LAIR_SLOT_Y = 14
-- (1.4) the five cards of a dungeon: the gap between them (less on a screen too narrow for them, down
-- to a little overlap), and how much lower they are away from the middle one (an arc: a hand of cards)
local LAIR_GAP, LAIR_ARC = 22, 7.5
local PACK_Y = 10
local PACK_W, PACK_H = 220, 440
local TOP_H = PACK_H * 64 / 512
-- the mouth of the pack, where its top tears off
local MOUTH = PACK_Y + PACK_H / 2 - 30
local RAINBOW = { { 1, 0.3, 0.3 }, { 1, 0.85, 0.2 }, { 0.3, 1, 0.4 }, { 0.3, 0.7, 1 }, { 0.85, 0.4, 1 } }
-- the colours of a finish: lightning (thunderforged), the light of a prism (titanforged, 1.11.0: gold and runes
-- before)
local WAVES = {
	thunder = { { 0.55, 0.8, 1 }, { 0.9, 0.97, 1 }, { 0.35, 0.55, 1 }, { 0.7, 0.9, 1 }, { 1, 1, 1 } },
	titan = { { 1, 0.35, 0.4 }, { 1, 0.8, 0.3 }, { 0.42, 1, 0.55 }, { 0.38, 0.85, 1 }, { 0.92, 0.48, 1 } },
}
local WHITE = { 1, 1, 1 }
local WARM = { 1, 0.92, 0.75 }
local DUST = { 0.8, 0.74, 0.64 }
-- (1.12.0, as in Curator Midnight) the colours of N'Zoth's corruption: its smoke, the electric blue and the violet of
-- its motes
local VOID_SMOKE = { 0.14, 0.04, 0.24 }
local VOID_BLUE = { 0.3, 0.36, 1 }
local VOID_VIOLET = { 0.68, 0.3, 1 }
-- the finishes that hold their card at length when it is turned over: the light of the prism on a titanforged one;
-- (1.12.0) N'Zoth waking over a corrupted one
local function Struck(look)
	return look == "titan" or look == "corrupt"
end
-- glint on the pack: one sweep of SWEEP_TIME seconds every SWEEP_EVERY seconds
local SWEEP_TIME, SWEEP_EVERY = 1.3, 4.2
local SWEEP_REACH = (PACK_W + PACK_H) * 0.36 + PACK_H * 0.12

-- The light that leaks out of the pack before it bursts climbs the colours of the rarities, from rare
-- up to the best card inside: blue, then purple, gold and crimson (a booster without a rare card, 1.2:
-- the colour of its best card only, green or a pale light). The first colour comes STEP_FIRST seconds
-- after the click, the next ones every STEP seconds; the pack bursts once the last one has shone for
-- HOLD seconds.
local TELL = { [1] = { 1, 0.92, 0.75 }, [2] = { 0.36, 1, 0.42 }, [3] = { 0.35, 0.62, 1 }, [4] = { 0.74, 0.38, 1 }, [5] = { 1, 0.68, 0.18 }, [6] = { 1, 0.2, 0.3 } }
local STEP_FIRST, STEP = 0.2, 0.42
local HOLD = { [1] = 0.26, [2] = 0.3, [3] = 0.36, [4] = 0.36, [5] = 0.44, [6] = 0.5 }
-- The cards of a booster of a zone (1.2: ten; 1.14.0: eight, Collection.lua): smaller, in two rows (of four), the
-- middle of the first one TEN_TOP points over the middle of the scene.
local TEN_GAP_X, TEN_GAP_Y, TEN_TOP = 22, 16, 126
-- A card gathers its light before it is turned over, then turns (seconds, by rarity). The best ones
-- darken the place and draw the camera closer meanwhile.
local WIND = { 0.06, 0.1, 0.28, 0.75, 1.25, 1.85 }
local FLIP = { 0.26, 0.28, 0.32, 0.4, 0.44, 0.48 }
local DARK = { [4] = 0.3, [5] = 0.52, [6] = 0.76 }
local ZOOM = { [4] = 1.06, [5] = 1.1, [6] = 1.14 }
-- The best cards shine face down: how bright their light is at rest (it breathes up to twice as
-- much), and the seconds between two motes of light rising from them (turned over, half as many).
local AURA_GLOW = { [4] = 0.22, [5] = 0.3, [6] = 0.36 }
local AURA = { [4] = 0.26, [5] = 0.17, [6] = 0.11 }
-- and the rays that turn behind them
local AURA_RAYS = { [4] = 0.16, [5] = 0.32, [6] = 0.4 }
-- A card face down under the mouse lights up in its colour. Blue is darker to the eye than green: the
-- light of a rare card is made stronger, so that it shows more than the one of an uncommon card.
local HOVER_BOOST = { [3] = 1.35 }

-- The small window, to open boosters while you walk: the scene as on a screen of CANVAS_W x CANVAS_H
-- points, drawn smaller. Its width is a part of the width of the screen (SMALL at first, the mouse
-- wheel changes it by SMALL_STEP between SMALL_MIN and SMALL_MAX); its buttons and its words look
-- SMALL_UI times their size in the full screen, to stay easy to read and to click.
local CANVAS_W, CANVAS_H = 1200, 768
local SMALL, SMALL_MIN, SMALL_MAX, SMALL_STEP = 0.38, 0.24, 0.62, 0.03
local SMALL_UI = 0.8
-- where it is at first: on the right of the screen, a little under its middle (points of the screen)
local SMALL_X, SMALL_Y = -28, -36

local function Text(parent, size, flags, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	ns.SetFont(fs, size, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 1)
	return fs
end

local function Tex(parent, layer, sub, file, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
	if blend then
		t:SetBlendMode(blend)
	end
	t:SetAlpha(0)
	return t
end

local function Mix(a, b, k)
	return { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k }
end

function B:Build()
	if self.frame then
		return
	end
	local s = CreateFrame("Frame", "CuratorBoosterScene", UIParent)
	s:SetAllPoints(UIParent)
	s:SetFrameStrata("FULLSCREEN_DIALOG")
	s:EnableMouse(true)
	s:Hide()
	self.frame = s
	tinsert(UISpecialFrames, "CuratorBoosterScene")
	-- the small window moves when its edges are dragged, and the mouse wheel over it changes its size
	-- (the full screen does not move; the client does not keep where the window was put: Curator does)
	s:SetMovable(true)
	if s.SetDontSavePosition then
		s:SetDontSavePosition(true)
	end
	s:RegisterForDrag("LeftButton")
	CuratorOctoFull.SetScript(s, "OnDragStart", function()
		if B:Small() then
			s:StartMoving()
		end
	end)
	CuratorOctoFull.SetScript(s, "OnDragStop", function()
		s:StopMovingOrSizing()
		B:KeepPlace()
	end)
	CuratorOctoFull.SetScript(s, "OnMouseWheel", function(_, delta)
		B:Resize(delta)
	end)
	local base = s:GetFrameLevel()
	-- (owners of timers that run in real time, whatever the time of the scene: the end of a freeze,
	-- the end of a sound that loops)
	self.freeze, self.timers = {}, {}
	self.owners, self.loops = {}, {}

	-- the photo of the album's place, behind a light veil, darker toward the edges of the screen
	s.backdrop = s:CreateTexture(nil, "BACKGROUND", nil, -3)
	s.backdrop:SetAllPoints()
	s.backdrop:SetTexture(MEDIA .. "StudioElwynn")
	s.dim = s:CreateTexture(nil, "BACKGROUND", nil, -2)
	s.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(s.dim, 0.01, 0.015, 0.03, 0.36)
	s.shade = s:CreateTexture(nil, "BACKGROUND", nil, -1)
	s.shade:SetAllPoints()
	s.shade:SetTexture(MEDIA .. "Vignette")
	s.shade:SetAlpha(0.9)
	s.halo = s:CreateTexture(nil, "BACKGROUND", nil, 1)
	s.halo:SetTexture(MEDIA .. "Glow")
	s.halo:SetBlendMode("ADD")
	s.halo:SetPoint("CENTER", 0, 0)
	CuratorOctoFull.SetSize(s.halo, 1300, 900)
	s.halo:SetAlpha(0.22)
	-- the place goes dark while the best cards gather their light (the cards stay above it)
	s.dark = s:CreateTexture(nil, "BACKGROUND", nil, 2)
	s.dark:SetAllPoints()
	CuratorOctoFull.ColorTexture(s.dark, 0, 0, 0, 1)
	s.dark:SetAlpha(0)

	-- the name of the place, as the game writes it when you enter it (and the kind of booster)
	local head = CreateFrame("Frame", nil, s)
	head:SetFrameLevel(base)
	CuratorOctoFull.SetSize(head, 2, 2)
	head:SetPoint("CENTER", 0, 300)
	s.head = head
	s.title = S.Text(head, "QuestFont_Enormous")
	s.title:SetPoint("CENTER", 0, 0)
	s.subtitle = S.Text(head, "GameFontHighlightLarge")
	s.subtitle:SetPoint("TOP", s.title, "BOTTOM", 0, -8)
	s.counter = S.Text(s, "GameFontNormalLarge", "RIGHT")
	s.counter:SetPoint("TOPRIGHT", -40, -40)
	s.hint = S.Text(s, "GameFontHighlightLarge")
	s.hint:SetPoint("CENTER", 0, -206)

	-- The stage: the pack, the cards and the light around them. The camera moves it and zooms it.
	local st = CreateFrame("Frame", nil, s)
	CuratorOctoFull.SetSize(st, 2, 2)
	st:SetPoint("CENTER")
	st:SetFrameLevel(base + 2)
	s.stage = st
	-- behind the cards: wheels of rays, the circle of runes, pillars and needles of light, the motes
	-- of light that rise
	local bk = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(bk, 2, 2)
	bk:SetPoint("CENTER")
	bk:SetFrameLevel(base + 1)
	s.behind = bk
	s.rays = Tex(bk, "BORDER", 0, "Rays", "ADD")
	CuratorOctoFull.SetSize(s.rays, 760, 760)
	-- a second wheel of rays, turning the other way (mythic cards)
	s.rays2 = Tex(bk, "BORDER", 1, "Rays", "ADD")
	CuratorOctoFull.SetSize(s.rays2, 1040, 1040)
	s.burst = Tex(bk, "BORDER", 2, "Rays", "ADD")
	CuratorOctoFull.SetSize(s.burst, 620, 620)
	s.circle = Tex(bk, "ARTWORK", 0, "StrikeRunes", "ADD")
	s.spikes = Tex(bk, "ARTWORK", 1, "Spikes", "ADD")
	s.beams = {}
	for i = 1, 3 do
		s.beams[i] = Tex(bk, "ARTWORK", 2, "Beam", "ADD")
	end
	self.motes = ns.Particles:New(bk, 90)

	-- the pack
	local p = CreateFrame("Button", nil, st)
	p:SetFrameLevel(base + 2)
	CuratorOctoFull.SetSize(p, PACK_W, PACK_H)
	p:SetPoint("CENTER", st, "CENTER", 0, PACK_Y)
	p.glow = p:CreateTexture(nil, "BACKGROUND")
	p.glow:SetTexture(MEDIA .. "Glow")
	p.glow:SetBlendMode("ADD")
	p.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(p.glow, 560, 760)
	-- two pieces cut along a tear line: the top flies off when the pack opens
	p.bottom = p:CreateTexture(nil, "ARTWORK")
	p.bottom:SetAllPoints()
	p.bottom:SetTexture(MEDIA .. "PackElwynnBottom")
	p.top = p:CreateTexture(nil, "ARTWORK", nil, 1)
	p.top:SetTexture(MEDIA .. "PackElwynnTop")
	-- the light on the pack, cut to its shape: the glint that sweeps it now and then, the light that
	-- breaks through it before it bursts, the whole pack white-hot at the last instant
	p.shine = CreateFrame("Frame", nil, p)
	p.shine:SetAllPoints()
	CuratorOctoFull.SetClipsChildren(p.shine, true)
	p.shine.mask = CuratorOctoFull.CreateMaskTexture(p.shine)
	p.shine.mask:SetTexture(MEDIA .. "PackElwynnBottom", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	p.shine.mask:SetAllPoints(p)
	p.shine.sheen = p.shine:CreateTexture(nil, "OVERLAY")
	p.shine.sheen:SetTexture(MEDIA .. "Sheen")
	p.shine.sheen:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(p.shine.sheen, 820, 820)
	p.shine.sheen:SetPoint("CENTER")
	p.shine.sheen:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(p.shine.sheen, p.shine.mask)
	-- a light where the mouse is over the pack
	p.shine.spot = p.shine:CreateTexture(nil, "OVERLAY", nil, 1)
	p.shine.spot:SetTexture(MEDIA .. "Glow")
	p.shine.spot:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(p.shine.spot, 300, 300)
	p.shine.spot:SetPoint("CENTER")
	p.shine.spot:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(p.shine.spot, p.shine.mask)
	p.shine.cracks = {}
	for k = 1, 3 do
		local t = Tex(p.shine, "OVERLAY", 1 + k, "PackCracks" .. k, "ADD")
		t:SetAllPoints(p)
		CuratorOctoFull.AddMaskTexture(t, p.shine.mask)
		p.shine.cracks[k] = t
	end
	p.shine.wash = p.shine:CreateTexture(nil, "OVERLAY", nil, 6)
	p.shine.wash:SetAllPoints(p)
	CuratorOctoFull.ColorTexture(p.shine.wash, 1, 1, 1, 1)
	p.shine.wash:SetBlendMode("ADD")
	p.shine.wash:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(p.shine.wash, p.shine.mask)
	-- the name band of the pack spans 336 to 392 of the 512 px texture
	-- (on the body of the pack: they go with it when it drops away)
	p.name = Text(p, 15, "")
	p.name:SetPoint("CENTER", p.bottom, "TOP", 0, -PACK_H * (364 / 512) + 6)
	p.name:SetWidth(200)
	p.name:SetTextColor(1, 0.86, 0.52)
	p.kind = Text(p, 10, "")
	p.kind:SetPoint("TOP", p.name, "BOTTOM", 0, -2)
	p.kind:SetTextColor(0.8, 0.72, 0.5)
	CuratorOctoFull.SetScript(p, "OnClick", function()
		B:Tear()
	end)
	CuratorOctoFull.SetScript(p, "OnEnter", function()
		if B.state == "pack" then
			p.hover = true
			if (p.sweep or 0) > SWEEP_TIME then
				p.sweep = 0
			end
		end
	end)
	CuratorOctoFull.SetScript(p, "OnLeave", function()
		p.hover = false
	end)
	s.pack = p

	-- the cards
	self.cards = {}
	for i = 1, 5 do
		local i = i; local c = ns.NewCard(st, "big")
		c:Hide()
		c.index = i
		CuratorOctoFull.SetScript(c, "OnClick", function()
			B:CardClick(c, i)
		end)
		CuratorOctoFull.SetScript(c, "OnEnter", function(self)
			B:Hover(self, true)
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function(self)
			B:Hover(self, false)
		end)
		-- (the rays that turn behind it while it waits face down, for the best ones)
		c.rays = Tex(bk, "BORDER", 3, "Rays", "ADD")
		CuratorOctoFull.SetSize(c.rays, c.W * 2.2, c.W * 2.2)
		self.cards[i] = c
	end
	self.bigCards = self.cards
	self.allCards = { unpack(self.cards) }
	-- (the smaller cards of a booster of a zone, eight, are made the first time one opens: B:TenCards)

	-- effects above the cards: dust, sparks, streaks of light, stars, shock waves, the streak of an
	-- impact, red lightning, the banner
	local fx = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(fx, 2, 2)
	fx:SetPoint("CENTER")
	fx:SetFrameLevel(base + 40)
	s.fx = fx
	-- the experience of each card as it is turned over ("+25 XP", falling from it)
	s.xpFloats = {}
	for i = 1, 6 do
		local t = fx:CreateFontString(nil, "OVERLAY")
		ns.SetFont(t, 17, "OUTLINE")
		t:SetAlpha(0)
		s.xpFloats[i] = t
	end
	-- (1.6.0) the talent that changed a card, over it as it is turned over
	s.tags = {}
	for i = 1, 4 do
		local t = fx:CreateFontString(nil, "OVERLAY")
		ns.SetFont(t, 15, "OUTLINE")
		t:SetAlpha(0)
		s.tags[i] = t
	end
	self.puffs = ns.Particles:New(fx, 24, "Puff", "BLEND", -2)
	self.puffs.alpha = 0.42
	self.particles = ns.Particles:New(fx, 160)
	self.streaks = ns.Particles:New(fx, 100, "Streak")
	self.stars = ns.Particles:New(fx, 60, "Twinkle")
	s.rings = {}
	for i = 1, 12 do
		local r = Tex(fx, "OVERLAY", 2, "Ring", "ADD")
		s.rings[i] = r
	end
	s.flare = Tex(fx, "OVERLAY", 4, "Flare", "ADD")
	s.bolts = {}
	for i = 1, 3 do
		s.bolts[i] = Tex(fx, "OVERLAY", 3, "StrikeBolt", "ADD")
	end
	-- the lightning that strikes a thunderforged card (two bolts, the second one mirrored)
	s.lightning = {}
	for i = 1, 2 do
		local b = Tex(fx, "OVERLAY", 5, "Lightning", "ADD")
		if i == 2 then
			b:SetTexCoord(1, 0, 0, 1)
		end
		s.lightning[i] = b
	end

	-- (over the black bands of the forge of the titans, under the light of the screen)
	local bn = CreateFrame("Frame", nil, fx)
	bn:SetFrameLevel(base + 59)
	CuratorOctoFull.SetSize(bn, 420, 105)
	bn.tex = bn:CreateTexture(nil, "ARTWORK")
	bn.tex:SetAllPoints()
	bn.tex:SetTexture(MEDIA .. "BannerLegendary")
	bn.text = Text(bn, 24, "OUTLINE")
	-- the band of the 512 x 128 texture is centred 62 px from the top
	bn.text:SetPoint("CENTER", 0, 105 * (64 - 62) / 128)
	bn:Hide()
	s.banner = bn

	-- over the whole screen: light along its edges in the colour of a big moment, the flash
	local top = CreateFrame("Frame", nil, s)
	top:SetAllPoints()
	top:SetFrameLevel(base + 60)
	s.edge = top:CreateTexture(nil, "OVERLAY", nil, 5)
	s.edge:SetAllPoints(s)
	s.edge:SetTexture(MEDIA .. "Edge")
	s.edge:SetBlendMode("ADD")
	s.edge:SetAlpha(0)
	s.flash = top:CreateTexture(nil, "OVERLAY", nil, 7)
	s.flash:SetAllPoints(s)
	CuratorOctoFull.ColorTexture(s.flash, 1, 1, 1, 1)
	s.flash:SetAlpha(0)

	-- buttons
	s.revealAll = ns.Button(s, L["Reveal all"], 180, 26)
	s.revealAll:SetPoint("CENTER", 0, -248)
	CuratorOctoFull.SetScript(s.revealAll, "OnClick", function()
		ns.Play(ns.SND.click)
		B:RevealAll()
	end)
	-- every booster of the album, one after the other, their cards turned over by themselves (1.2); the
	-- button that stops it, under the count of the boosters
	s.all = ns.Button(s, L["Open all"], 200, 26)
	CuratorOctoFull.SetScript(s.all, "OnClick", function()
		ns.Play(ns.SND.click)
		B:OpenAll()
	end)
	s.all:Hide()
	s.stop = ns.Button(s, L["Stop"], 130, 24)
	CuratorOctoFull.SetScript(s.stop, "OnClick", function()
		ns.Play(ns.SND.click)
		B:StopAll()
	end)
	s.stop:Hide()
	-- (1.6.0) the talents of the Augur and of the Merchant: the omen of a booster (the colour of its best
	-- card, then it is opened or shaken), a card drawn again
	s.omen = ns.Button(s, L["Omen"], 170, 26)
	CuratorOctoFull.SetScript(s.omen, "OnClick", function()
		ns.Play(ns.SND.click)
		B:Tear(true)
	end)
	CuratorOctoFull.SetScript(s.omen, "OnEnter", function(b)
		B:TalentButtonTooltip(b, "presage")
	end)
	CuratorOctoFull.SetScript(s.omen, "OnLeave", function()
		GameTooltip:Hide()
	end)
	s.omen:Hide()
	s.omenOpen = ns.Button(s, L["Open it"], 170, 26)
	CuratorOctoFull.SetScript(s.omenOpen, "OnClick", function()
		ns.Play(ns.SND.click)
		B:OmenOpen()
	end)
	s.omenOpen:Hide()
	s.omenShake = ns.Button(s, L["Shake it"], 170, 26)
	CuratorOctoFull.SetScript(s.omenShake, "OnClick", function()
		B:OmenShake()
	end)
	s.omenShake:Hide()
	s.redraw = ns.Button(s, L["Redraw a card"], 210, 26)
	CuratorOctoFull.SetScript(s.redraw, "OnClick", function()
		ns.Play(ns.SND.click)
		B:StartRedraw()
	end)
	CuratorOctoFull.SetScript(s.redraw, "OnEnter", function(b)
		B:TalentButtonTooltip(b, B.mode == "contract" and "second" or "reroll")
	end)
	CuratorOctoFull.SetScript(s.redraw, "OnLeave", function()
		GameTooltip:Hide()
	end)
	s.redraw:Hide()
	s.again = ns.Button(s, L["Open another"], 200, 26)
	-- (under the bar of the album and the bar of the level)
	s.again:SetPoint("CENTER", 0, -284)
	CuratorOctoFull.SetScript(s.again, "OnClick", function()
		ns.Play(ns.SND.click)
		B:Again()
	end)
	s.album = ns.Button(s, L["Album"], 150, 26)
	s.album:SetPoint("RIGHT", s.again, "LEFT", -14, 0)
	CuratorOctoFull.SetScript(s.album, "OnClick", function()
		ns.Play(ns.SND.click)
		s:Hide()
		-- (1.14.0, after its second test: a contract of the cards of the cases, the card that came in its album,
		-- UI/CaseContract.lua)
		if B.mode == "caseContract" and B.CaseAlbum then
			return B:CaseAlbum()
		end
		-- (opened from the page of the boosters: back to it; else the album of the booster. 1 November: from Everything in
		-- the inventory, back to it, as it was)
		if B.mode ~= "contract" and B.opts and B.opts.from == "boosters" then
			ns.Album:ShowBoosters()
		elseif B.mode ~= "contract" and B.opts and B.opts.from == "inventory" and ns.InventoryUI then
			ns.InventoryUI.ShowPage()
		else
			ns.Album:ShowSeries(B.series)
		end
	end)
	s.close = ns.Button(s, L["Close"], 150, 26)
	s.close:SetPoint("LEFT", s.again, "RIGHT", 14, 0)
	CuratorOctoFull.SetScript(s.close, "OnClick", function()
		ns.Play(ns.SND.close)
		s:Hide()
	end)
	-- The frame of the small window, and in its corner (in the corner of the screen, full screen) the
	-- button that makes the scene a small window or the full screen again, and the one that closes the
	-- small window.
	s.border = CreateFrame("Frame", nil, s, CuratorOctoFull.BackdropTemplate())
	s.border:SetAllPoints()
	s.border:SetFrameLevel(base + 70)
	s.border:Hide()
	s.size = S.RedButton(s, "Condense")
	s.size:SetFrameLevel(base + 72)
	CuratorOctoFull.SetScript(s.size, "OnClick", function()
		ns.Play(ns.SND.click)
		B:ToggleSmall()
	end)
	CuratorOctoFull.SetScript(s.size, "OnEnter", function(b)
		B:SizeTooltip(b)
	end)
	CuratorOctoFull.SetScript(s.size, "OnLeave", function()
		GameTooltip:Hide()
	end)
	s.shut = S.RedButton(s, "Exit")
	s.shut:SetFrameLevel(base + 72)
	CuratorOctoFull.SetScript(s.shut, "OnClick", function()
		ns.Play(ns.SND.close)
		s:Hide()
	end)
	CuratorOctoFull.SetScript(s.shut, "OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
		GameTooltip:AddLine(L["Close"], 1, 1, 1)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(s.shut, "OnLeave", function()
		GameTooltip:Hide()
	end)
	s.shut:Hide()
	s.summary = S.Text(s, "GameFontNormalLarge")
	s.summary:SetPoint("CENTER", 0, -190)
	-- the album filling up with the new cards
	s.bar = S.ThinBar(s, 300, 10, { 0.3, 0.7, 1 })
	s.bar:SetPoint("CENTER", 0, -214)
	s.bar:Hide()
	s.bar.tip = s.bar:CreateTexture(nil, "OVERLAY", nil, 2)
	s.bar.tip:SetTexture(MEDIA .. "Twinkle")
	s.bar.tip:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(s.bar.tip, 34, 34)
	s.bar.tip:SetAlpha(0)
	-- the experience of the collector: what the booster gave, the emblem of the rank, the bar of the
	-- level filling (a level gained: its screen after)
	s.xpBar = ns.Hud.XPBar(s, 300, 14)
	s.xpBar:SetPoint("CENTER", 0, -240)
	s.xpBar:SetFrameLevel(s:GetFrameLevel() + 30)
	s.xpBar:Hide()
	s.xpText = s.xpBar.text
	s.xpEmblem = ns.Hud.Emblem(s, 42)
	s.xpEmblem:SetPoint("RIGHT", s.xpBar, "LEFT", -8, 0)
	s.xpEmblem:SetFrameLevel(s:GetFrameLevel() + 30)
	s.xpEmblem:Hide()
	s.xpGain = S.Text(s, "GameFontNormalLarge", "RIGHT")
	s.xpGain:SetPoint("RIGHT", s.xpEmblem, "LEFT", -8, 0)
	s.xpGain:SetTextColor(0.78, 0.64, 1)
	s.xpLevel = S.Text(s, "GameFontNormal", "LEFT")
	s.xpLevel:SetPoint("LEFT", s.xpBar, "RIGHT", 14, 0)
	s.xpNote = S.Text(s, "GameFontHighlightSmall")
	s.xpNote:SetPoint("TOP", s.xpBar, "BOTTOM", 0, -8)
	s.xpNote:SetTextColor(1, 0.86, 0.5)

	-- the boosters of the dungeons and the raids: their cards, their chains, what watches from the
	-- dark (UI/Lair.lua)
	if self.BuildLair then
		self:BuildLair()
	end
	-- the pieces of the titans, that strike a titanforged card (UI/Forge.lua)
	if self.BuildForge then
		self:BuildForge()
	end

	self.cam = { z = 1, x = 0, y = 0, kick = 0, sx = 0, sy = 0 }
	CuratorOctoFull.SetScript(s, "OnUpdate", function(_, elapsed)
		B:Tick(elapsed)
	end)
	CuratorOctoFull.SetScript(s, "OnHide", function()
		-- (hidden with the whole interface: closed for good, not left half-played)
		if s:IsShown() then
			s:Hide()
		end
		B:TellUntold()
		B:Cleanup()
	end)
end

local function FadeIn(region, dur, owner)
	region:SetAlpha(0)
	region:Show()
	ns.Tween(dur or 0.3, function(e)
		region:SetAlpha(e)
	end, nil, Ease.outQuad, owner)
end

local function GlowTo(tex, alpha, dur, owner)
	if tex.tw then
		ns.CancelTween(tex.tw)
	end
	local from = tex:GetAlpha()
	local tw
	tw = ns.Tween(dur or 0.2, function(e)
		tex:SetAlpha(from + (alpha - from) * e)
	end, function()
		if tex.tw == tw then
			tex.tw = nil
		end
	end, Ease.outQuad, owner)
	tex.tw = tw
end

-------------------------------------------------------------------------------
-- Time, camera, owners
-------------------------------------------------------------------------------
-- An owner of tweens of its own (the charge of the pack, the light a card gathers): cancelled
-- together when that moment is cut short, and with the scene.
function B:Owner()
	local o = {}
	self.owners[o] = true
	return o
end

-- The time of the scene: slower (slow motion), or standing still for an instant (the freeze of a big
-- impact). Its tweens, its sparks and its camera follow it.
function B:SetTime(k)
	for _, o in ipairs({ self, self.particles, self.streaks, self.stars, self.puffs, self.motes }) do
		ns.SetTimeScale(o, k)
	end
	self.timeK = k
end

function B:HitStop(sec)
	ns.CancelOwner(self.freeze)
	self:SetTime(0)
	ns.Delay(sec, function()
		self:SetTime(1)
	end, self.freeze)
end

-- Sounds made to loop (a spell gathering its power): kept by name and stopped when their moment ends
-- (after seconds, or by StopLoop), all of them with the scene.
function B:Loop(key, list, seconds)
	self:StopLoop(key)
	local ok, handle = ns.Play(list)
	if ok and handle then
		self.loops[key] = handle
		if seconds then
			ns.Delay(seconds, function()
				if self.loops[key] == handle then
					self:StopLoop(key)
				end
			end, self.timers)
		end
	end
end

function B:StopLoop(key, fade)
	local h = self.loops[key]
	if h then
		self.loops[key] = nil
		if StopSound then
			StopSound(h, fade or 250)
		end
	end
end

function B:StopLoops()
	for key in pairs(self.loops) do
		self:StopLoop(key)
	end
end

-- The photo behind, cut to the screen: zoom (1: the whole width that fits), and moved by (px, py)
-- points. It moves less than the stage when the camera moves: it is far.
function B:BackdropCrop(zoom, px, py)
	local s, c = self.frame, self.crop
	if not c then
		return
	end
	local w, h = s:GetWidth() or 0, s:GetHeight() or 0
	if w <= 0 or h <= 0 then
		w, h = 1920, 1080
	end
	local hu, hv = (c[2] - c[1]) / 2 / zoom, (c[4] - c[3]) / 2 / zoom
	local cu = (c[1] + c[2]) / 2 + px * (c[2] - c[1]) / w
	local cv = (c[3] + c[4]) / 2 - py * (c[4] - c[3]) / h
	cu = math.max(hu, math.min(1 - hu, cu))
	cv = math.max(hv, math.min(1 - hv, cv))
	s.backdrop:SetTexCoord(cu - hu, cu + hu, cv - hv, cv + hv)
end

function B:SetBackdrop(series)
	local s = self.frame
	-- (cut again if the scene changes its size)
	self.backdropSeries = series
	s.backdrop:SetTexture(MEDIA .. (series.studio or "StudioElwynn"))
	-- the backdrop is twice as wide as tall: keep the middle part that matches the screen
	local w, h = s:GetWidth(), s:GetHeight()
	local screen = (w and h and h > 0) and (w / h) or (16 / 9)
	if screen < 2 then
		local u = screen / 2
		self.crop = { 0.5 - u / 2, 0.5 + u / 2, 0, 1 }
	else
		local v = 2 / screen
		self.crop = { 0, 1, 0.5 - v / 2, 0.5 + v / 2 }
	end
	-- (cut again by the camera at the next frame)
	self.cropZ = nil
	self:BackdropCrop(1, 0, 0)
end

-------------------------------------------------------------------------------
-- The full screen, or the small window
-------------------------------------------------------------------------------
-- The boosters open in the small window (/curator compact, or the button in the corner of the scene).
function B:Small()
	return (ns.db and ns.db.compact) and true or false
end

-- The scene takes the whole screen, or becomes the small window: its size, its scale, its place,
-- its frame, and its buttons and words a little larger than the rest of it.
function B:ApplySize()
	local s = self.frame
	local small = self:Small()
	local k = 1
	s:ClearAllPoints()
	local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
	if not pw or pw <= 0 or not ph or ph <= 0 then
		pw, ph = 1365, 768
	end
	if small then
		local part = tonumber(ns.db.compactW) or SMALL
		part = math.max(SMALL_MIN, math.min(SMALL_MAX, part))
		-- (never taller than most of the screen)
		k = math.min(part * pw / CANVAS_W, ph * 0.86 / CANVAS_H)
		s:SetScale(k)
		CuratorOctoFull.SetSize(s, CANVAS_W, CANVAS_H)
		local at = ns.db.compactAt
		if type(at) == "table" and tonumber(at.x) and tonumber(at.y) then
			-- (whole on the screen, whatever its size)
			local hw, hh = CANVAS_W * k / 2, CANVAS_H * k / 2
			local x = math.max(hw - pw / 2, math.min(pw / 2 - hw, at.x))
			local y = math.max(hh - ph / 2, math.min(ph / 2 - hh, at.y))
			s:SetPoint("CENTER", UIParent, "CENTER", x / k, y / k)
		else
			s:SetPoint("RIGHT", UIParent, "RIGHT", SMALL_X / k, SMALL_Y / k)
		end
	else
		s:SetScale(1)
		CuratorOctoFull.SetSize(s, pw, ph)
		s:SetAllPoints(UIParent)
	end
	self.sizeK = k
	CuratorOctoFull.SetClampedToScreen(s, small)
	s:EnableMouseWheel(small)
	if s.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(s, small)
	end
	-- its frame: the gold border of the game's dialogs, as thick as theirs whatever the scale
	if small then
		s.border:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = math.floor(32 / k + 0.5) })
		s.border:Show()
	else
		s.border:Hide()
	end
	self.uiK = small and math.max(1, math.min(2.4, SMALL_UI / k)) or 1
	self:PlaceUI()
	-- the photo cut again to the new shape, the camera placed again; the mist of a dungeon
	if self.backdropSeries then
		self:SetBackdrop(self.backdropSeries)
	end
	self.camZ, self.camOX, self.camOY, self.cropZ = nil, nil, nil, nil
	if self.cam then
		self:CamApply()
	end
	if self.lair and self.LairFit then
		self:LairFit()
	end
	-- (1.13.0, after its first test: the cards of Open all)
	if self.batch and self.BatchFit then
		self:BatchFit()
	end
end

-- (a region placed at (x, y) points of the scene, whatever its own scale)
local function At(r, point, rel, relPoint, x, y)
	local k = r.GetScale and r:GetScale() or 1
	if not k or k <= 0 then
		k = 1
	end
	r:ClearAllPoints()
	r:SetPoint(point, rel, relPoint, x / k, y / k)
end

-- The buttons and the words of the scene, at their scale and in their places (the small window has
-- the buttons a little lower, under the bars, and its own in its corner).
function B:PlaceUI()
	local s = self.frame
	local small, ui = self:Small(), self.uiK or 1
	for _, r in ipairs({ s.revealAll, s.all, s.stop, s.again, s.album, s.close, s.size, s.shut, s.hint, s.counter, s.summary,
		s.omen, s.omenOpen, s.omenShake, s.redraw }) do
		-- (a client whose texts cannot be scaled: they stay as they are)
		if r.SetScale then
			r:SetScale(ui)
		end
	end
	At(s.revealAll, "CENTER", s, "CENTER", 0, small and -262 or -248)
	At(s.all, "CENTER", s, "CENTER", 0, small and -262 or -248)
	At(s.again, "CENTER", s, "CENTER", 0, small and -322 or -284)
	-- (beside it, at the same scale)
	s.album:ClearAllPoints()
	s.album:SetPoint("RIGHT", s.again, "LEFT", -14, 0)
	s.close:ClearAllPoints()
	s.close:SetPoint("LEFT", s.again, "RIGHT", 14, 0)
	At(s.summary, "CENTER", s, "CENTER", 0, -190)
	self:PlaceHint(self.hintY or -206)
	-- (1.6.0) the omen, under the button that opens them all; its two choices side by side; a card
	-- drawn again, under the buttons of the end
	At(s.omen, "CENTER", s, "CENTER", 0, self.lair and (small and -352 or -342) or (small and -296 or -284))
	local oy = self.lair and (small and -318 or -308) or (small and -262 or -248)
	At(s.omenOpen, "CENTER", s, "CENTER", -95, oy)
	At(s.omenShake, "CENTER", s, "CENTER", 95, oy)
	At(s.redraw, "CENTER", s, "CENTER", 0, small and -358 or -320)
	if small then
		At(s.shut, "TOPRIGHT", s, "TOPRIGHT", -12, -12)
		s.size:ClearAllPoints()
		s.size:SetPoint("RIGHT", s.shut, "LEFT", 2, 0)
		At(s.counter, "TOPLEFT", s, "TOPLEFT", 26, -22)
		s.counter:SetJustifyH("LEFT")
		s.stop:ClearAllPoints()
		s.stop:SetPoint("TOPLEFT", s.counter, "BOTTOMLEFT", 0, -8)
	else
		At(s.size, "TOPRIGHT", s, "TOPRIGHT", -10, -8)
		At(s.counter, "TOPRIGHT", s, "TOPRIGHT", -40, -40)
		s.counter:SetJustifyH("RIGHT")
		s.stop:ClearAllPoints()
		s.stop:SetPoint("TOPRIGHT", s.counter, "BOTTOMRIGHT", 0, -8)
	end
	s.size:SetKind(small and "Expand" or "Condense")
	CuratorOctoFull.SetShown(s.shut, small)
end

-- The line under the pack or the cards, y points under the middle of the scene (lower for the chains
-- of a sealed booster).
function B:PlaceHint(y)
	self.hintY = y
	At(self.frame.hint, "CENTER", self.frame, "CENTER", 0, y)
end

-- Where the small window is: kept, as the points of its middle from the middle of the screen.
function B:SavePlace()
	local s = self.frame
	local x, y = s:GetCenter()
	local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
	local es, ps = CuratorOctoFull.GetEffectiveScale(s), CuratorOctoFull.GetEffectiveScale(UIParent)
	if not (x and y and pw and ph and es and ps and ps > 0) then
		return
	end
	local k = es / ps
	ns.db.compactAt = { x = math.floor(x * k - pw / 2 + 0.5), y = math.floor(y * k - ph / 2 + 0.5) }
end

-- The small window dragged: where it was left is kept, and it is anchored again by its middle (it
-- grows and shrinks around it).
function B:KeepPlace()
	if not self:Small() then
		return
	end
	self:SavePlace()
	self:ApplySize()
end

-- The mouse wheel over the small window: larger (up) or smaller, around its middle.
function B:Resize(delta)
	if not self:Small() then
		return
	end
	self:SavePlace()
	local part = tonumber(ns.db.compactW) or SMALL
	part = math.max(SMALL_MIN, math.min(SMALL_MAX, part + (delta > 0 and SMALL_STEP or -SMALL_STEP)))
	ns.db.compactW = math.floor(part * 100 + 0.5) / 100
	self:ApplySize()
end

-- The small window, or the full screen again (the scene open or not); quiet: no line in the chat.
function B:ToggleSmall(quiet)
	ns.db.compact = not self:Small() or nil
	if self.frame then
		self:ApplySize()
		-- (an entrance playing follows the scene)
		local cin = ns.Cinematic
		if cin and cin:IsPlaying() and cin.Place then
			cin:Place()
			cin:Layout()
		end
		if self.frame:IsShown() and GameTooltip:IsShown() and GameTooltip:GetOwner() == self.frame.size then
			self:SizeTooltip(self.frame.size)
		end
	end
	if not quiet then
		ns.Print(self:Small() and L["Boosters: in a small window. Drag its edges to move it, the mouse wheel over it changes its size."] or L["Boosters: full screen."])
	end
end

function B:SizeTooltip(b)
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
	if self:Small() then
		GameTooltip:AddLine(L["Full screen"], 1, 1, 1)
		GameTooltip:AddLine(L["Back to the boosters in full screen."], 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine(L["Drag the edges of the window to move it, the mouse wheel over it changes its size."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
	else
		GameTooltip:AddLine(L["Small window"], 1, 1, 1)
		GameTooltip:AddLine(L["Open your boosters in a small window you can move, to keep an eye on the world while you walk."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:Show()
end

-- The camera looks at (x, y) of the stage, zoomed z times (and kicked by a punch, shaken).
function B:CamApply()
	local s, cam = self.frame, self.cam
	local st = s.stage
	local z = math.max(0.5, cam.z + cam.kick)
	-- (only what changed: the scale given last, for the client may give back a value rounded a little
	-- differently)
	if self.camZ ~= z then
		self.camZ = z
		st:SetScale(z)
	end
	local ox, oy = -cam.x + cam.sx / z, -cam.y + cam.sy / z
	if self.camOX ~= ox or self.camOY ~= oy then
		self.camOX, self.camOY = ox, oy
		st:ClearAllPoints()
		st:SetPoint("CENTER", s, "CENTER", ox, oy)
	end
	-- (a little larger than the screen, so that it can follow the mouse)
	local bz, bx, by = 1.03 + (z - 1) * 0.3, cam.x * 0.25 + (self.parX or 0), cam.y * 0.25 + (self.parY or 0)
	if self.cropZ ~= bz or self.cropX ~= bx or self.cropY ~= by then
		self.cropZ, self.cropX, self.cropY = bz, bx, by
		self:BackdropCrop(bz, bx, by)
	end
end

-- The camera moves to look at (x, y), zoomed z times.
function B:CamTo(z, x, y, dur, ease, delay)
	local cam = self.cam
	if cam.tw then
		ns.CancelTween(cam.tw)
	end
	local z0, x0, y0
	cam.tw = ns.Tween(dur, function(e)
		if not z0 then
			z0, x0, y0 = cam.z, cam.x, cam.y
		end
		cam.z = z0 + (z - z0) * e
		cam.x = x0 + (x - x0) * e
		cam.y = y0 + (y - y0) * e
	end, function()
		cam.z, cam.x, cam.y = z, x, y
		cam.tw = nil
	end, ease or Ease.outCubic, self, delay)
end

-- A punch: the camera jumps closer for an instant and comes back.
function B:Punch(amount, dur)
	local cam = self.cam
	if cam.kickTw then
		ns.CancelTween(cam.kickTw)
	end
	local from = cam.kick + amount
	cam.kick = from
	cam.kickTw = ns.Tween(dur or 0.4, function(e)
		cam.kick = from * (1 - e)
	end, function()
		cam.kick = 0
		cam.kickTw = nil
	end, Ease.outCubic, self)
end

-- The whole stage shakes, dying away (the stronger shake wins).
function B:Shake(dur, amp)
	local left = (self.shakeT or 0) > 0 and self.shakeA * self.shakeT / self.shakeD or 0
	if amp >= left then
		self.shakeT, self.shakeD, self.shakeA = dur, dur, amp
	end
end

-------------------------------------------------------------------------------
-- Effects
-------------------------------------------------------------------------------
-- A shock wave: a ring that grows from (x, y) to size and fades. file: "Ring" (soft, by default) or
-- "Shock" (a sharp front); flat: its height for a width of 1 (a wave along the ground).
function B:Ring(x, y, color, size, dur, alpha, delay, file, flat)
	local s = self.frame
	local r
	for _, t in ipairs(s.rings) do
		if not t.busy then
			r = t
			break
		end
	end
	if not r then
		return
	end
	r.busy = true
	r:SetTexture(MEDIA .. (file or "Ring"))
	r:ClearAllPoints()
	r:SetPoint("CENTER", s.fx, "CENTER", x, y)
	r:SetVertexColor(color[1], color[2], color[3])
	CuratorOctoFull.SetSize(r, 1, 1)
	r:SetAlpha(0)
	local fl = flat or 1
	ns.Tween(dur or 0.6, function(e, raw)
		local k = (size or 400) * (0.15 + 0.85 * e)
		CuratorOctoFull.SetSize(r, k, k * fl)
		r:SetAlpha((alpha or 0.8) * (1 - raw) * math.min(1, raw * 8))
	end, function()
		r:SetAlpha(0)
		r.busy = false
	end, Ease.outCubic, self, delay)
end

-- The long streak of light of an impact, across (x, y).
function B:Flare(x, y, color, width, dur, alpha, delay)
	local f = self.frame.flare
	if f.tw then
		ns.CancelTween(f.tw)
	end
	f.tw = ns.Tween(dur or 0.5, function(e, raw)
		if raw == 0 or not f.placed then
			f.placed = true
			f:ClearAllPoints()
			f:SetPoint("CENTER", self.frame.fx, "CENTER", x, y)
			f:SetVertexColor(color[1], color[2], color[3])
		end
		CuratorOctoFull.SetSize(f, math.max(1, width * (0.3 + 0.7 * e)), 46 + 34 * (1 - raw))
		f:SetAlpha((alpha or 1) * (1 - raw) ^ 1.3)
	end, function()
		f:SetAlpha(0)
		f.tw, f.placed = nil, false
	end, Ease.outCubic, self, delay)
	f.placed = false
end

-- A pillar of light out of (x, y), up (or down), w wide and h high: it shoots out, then narrows and
-- fades.
function B:Beam(i, x, y, color, w, h, dur, alpha, down)
	local s = self.frame
	local b = s.beams[i]
	b:ClearAllPoints()
	if down then
		b:SetPoint("TOP", s.behind, "CENTER", x, y)
		b:SetTexCoord(0, 1, 1, 0)
	else
		b:SetPoint("BOTTOM", s.behind, "CENTER", x, y)
		b:SetTexCoord(0, 1, 0, 1)
	end
	b:SetVertexColor(color[1], color[2], color[3])
	CuratorOctoFull.SetSize(b, 1, 1)
	if b.tw then
		ns.CancelTween(b.tw)
	end
	b.tw = ns.Tween(dur, function(_, raw)
		local out = Ease.outCubic(math.min(1, raw / 0.16))
		CuratorOctoFull.SetSize(b, math.max(1, w * (1 - 0.55 * raw)), math.max(1, h * out))
		local fade = raw < 0.16 and 1 or (1 - (raw - 0.16) / 0.84) ^ 1.4
		b:SetAlpha((alpha or 1) * fade)
	end, function()
		b:SetAlpha(0)
		b.tw = nil
	end, Ease.linear, self)
end

-- Needles of light bursting out behind (x, y).
function B:Spikes(x, y, color, size, dur, alpha)
	local s = self.frame
	local t = s.spikes
	t:ClearAllPoints()
	t:SetPoint("CENTER", s.behind, "CENTER", x, y)
	t:SetVertexColor(color[1], color[2], color[3])
	if t.tw then
		ns.CancelTween(t.tw)
	end
	local turn = (math.random() - 0.5) * 0.6
	t.tw = ns.Tween(dur or 0.5, function(e, raw)
		local k = size * (0.35 + 0.65 * e)
		CuratorOctoFull.SetSize(t, k, k)
		CuratorOctoFull.SetRotation(t, turn * raw)
		t:SetAlpha((alpha or 1) * (1 - raw) ^ 1.5)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.outCubic, self)
end

-- Red lightning around (x, y) for an instant.
function B:Bolts(x, y, size, color)
	for i, t in ipairs(self.frame.bolts) do
		local i, t = i, t; local a = math.random() * math.pi * 2
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.frame.fx, "CENTER", x + math.cos(a) * size * 0.12, y + math.sin(a) * size * 0.12)
		CuratorOctoFull.SetSize(t, size * (0.8 + 0.3 * math.random()), size * (0.8 + 0.3 * math.random()))
		CuratorOctoFull.SetRotation(t, math.random() * math.pi * 2)
		t:SetVertexColor(color[1], color[2], color[3])
		if t.tw then
			ns.CancelTween(t.tw)
		end
		t.tw = ns.Tween(0.22, function(_, raw)
			t:SetAlpha((raw < 0.3 and 1 or (1 - raw) / 0.7) * (0.55 + 0.45 * math.random()))
		end, function()
			t:SetAlpha(0)
			t.tw = nil
		end, Ease.linear, self, (i - 1) * 0.04)
	end
	ns.Play(ns.SND.crackle)
end

-- The circle of runes behind a card (or the pack) that gathers its light: it opens and turns.
function B:Circle(x, y, color, size, dur, spin)
	local s = self.frame
	local t = s.circle
	t:ClearAllPoints()
	t:SetPoint("CENTER", s.behind, "CENTER", x, y)
	t:SetVertexColor(color[1], color[2], color[3])
	t.spin = spin or 0.7
	t.on = true
	t.gen = (t.gen or 0) + 1
	if t.tw then
		ns.CancelTween(t.tw)
	end
	t.tw = ns.Tween(dur, function(e)
		local k = size * (0.45 + 0.55 * e)
		CuratorOctoFull.SetSize(t, k, k)
		t:SetAlpha(0.8 * e)
	end, function()
		t.tw = nil
	end, Ease.outCubic, self)
end

-- ... and it flies apart when the card is turned.
function B:CircleOut(dur)
	local t = self.frame.circle
	if not t.on then
		return
	end
	if t.tw then
		ns.CancelTween(t.tw)
	end
	local a, w = t:GetAlpha(), t:GetWidth()
	t.tw = ns.Tween(dur or 0.5, function(e)
		CuratorOctoFull.SetSize(t, w * (1 + 0.7 * e), w * (1 + 0.7 * e))
		t:SetAlpha(a * (1 - e))
	end, function()
		t:SetAlpha(0)
		t.on = false
		t.tw = nil
	end, Ease.outCubic, self)
end

-- The flash over the whole screen.
function B:Flash(color, peak, dur)
	local f = self.frame.flash
	f:SetVertexColor(color[1], color[2], color[3])
	f:SetAlpha(peak)
	if f.tw then
		ns.CancelTween(f.tw)
	end
	f.tw = ns.Tween(dur, function(e)
		f:SetAlpha(peak * (1 - e))
	end, function()
		f.tw = nil
	end, Ease.outQuad, self)
end

-- Light along the edges of the screen: it swells at once and dies away.
function B:EdgeGlow(color, peak, dur)
	local e = self.frame.edge
	e:SetVertexColor(color[1], color[2], color[3])
	if e.tw then
		ns.CancelTween(e.tw)
	end
	local from = e:GetAlpha()
	e.tw = ns.Tween(dur, function(_, raw)
		if raw < 0.12 then
			e:SetAlpha(from + (peak - from) * raw / 0.12)
		else
			e:SetAlpha(peak * (1 - (raw - 0.12) / 0.88) ^ 1.3)
		end
	end, function()
		e:SetAlpha(0)
		e.tw = nil
	end, Ease.linear, self)
end

-- The place goes dark (or comes back: 0).
function B:DarkTo(alpha, dur, delay)
	local d = self.frame.dark
	if d.tw then
		ns.CancelTween(d.tw)
	end
	local from
	d.tw = ns.Tween(dur, function(e)
		from = from or d:GetAlpha()
		d:SetAlpha(from + (alpha - from) * e)
	end, function()
		d.tw = nil
	end, Ease.outQuad, self, delay)
end

-- Where the banner of a card comes: over it (the second row of the cards of a zone: under it, not
-- over the first row).
function B:BannerY(c)
	if c.row == 2 then
		return c.slotY - c.H / 2 - 44
	end
	return c.slotY + c.H / 2 + 44
end

-- kind: "Epic", "Legendary", "Mythic", "Thunder", "Titan" or "Prism" (one painted ribbon each; the titanforged
-- cards: "Prism" since 1.11.0, the ribbon of the titans goes on with the titles). It comes down on
-- the screen, holds, and fades. (High on the screen, over the name of the place: the name steps aside
-- meanwhile.)
function B:Banner(text, kind, x, y, hold)
	local bn = self.frame.banner
	bn.tex:SetTexture(MEDIA .. "Banner" .. kind)
	bn.text:SetText(text)
	if kind == "Thunder" or kind == "Titan" or kind == "Prism" or kind == "Corrupt" then
		bn.text:SetTextColor(1, 1, 1)
	else
		bn.text:SetTextColor(1, 0.96, 0.86)
	end
	local maxX = (self.frame:GetWidth() or 1920) / 2 - 210
	x = math.max(-maxX, math.min(maxX, x))
	bn:SetScale(1.7)
	bn:SetAlpha(0)
	bn:Show()
	local function place(k)
		bn:ClearAllPoints()
		bn:SetPoint("CENTER", self.frame.fx, "CENTER", x / k, y / k)
	end
	place(1.7)
	if bn.tw then
		ns.CancelTween(bn.tw)
	end
	-- (under the second row of the cards of a zone: the line and the button under them step aside until it
	-- has gone)
	if y < 0 then
		self:FootAside(true)
	elseif self.footBanner then
		self:FootAside(false)
	end
	local head = self.frame.head
	if y > 220 then
		local a0 = head:GetAlpha()
		if head.tw then
			ns.CancelTween(head.tw)
		end
		head.tw = ns.Tween(0.2, function(e)
			head:SetAlpha(a0 + (0.12 - a0) * e)
		end, function()
			head.tw = ns.Tween(0.5, function(e)
				head:SetAlpha(0.12 + 0.88 * e)
			end, function()
				head.tw = nil
			end, Ease.inQuad, self, (hold or 1.4) + 0.4)
		end, Ease.outQuad, self)
	end
	bn.tw = ns.Tween(0.3, function(e, raw)
		local k = 1.7 - 0.7 * e
		bn:SetScale(k)
		place(k)
		bn:SetAlpha(math.min(1, raw * 3))
	end, function()
		bn:SetScale(1)
		place(1)
		self:Shake(0.12, 3)
		bn.tw = ns.Tween(0.45, function(e)
			bn:SetAlpha(1 - e)
		end, function()
			bn:Hide()
			if self.footBanner then
				self:FootAside(false)
			end
		end, Ease.inQuad, self, hold or 1.4)
	end, Ease.outBack, self)
end

-- The line and the button under the cards step aside (on) while a banner covers them, and come back.
-- (The end of the booster waits for them: B:CheckDone.)
function B:FootAside(on)
	local s = self.frame
	self.footBanner = on and true or false
	for _, r in ipairs({ s.hint, s.revealAll }) do
		GlowTo(r, on and 0.12 or 1, on and 0.2 or 0.5, self)
	end
end

-- The words of the end of a booster wait while a banner covers the place under the cards, or one is
-- still to come there (the finish of a card, after its rarity).
function B:WhenFootFree(fn)
	if self.footBanner or (self.footPending or 0) > 0 then
		ns.Delay(0.2, function()
			self:WhenFootFree(fn)
		end, self)
		return
	end
	fn()
end

-------------------------------------------------------------------------------
-- The scene
-------------------------------------------------------------------------------
-- The effects of the stage gone at once (their tweens cancelled before): rings, streak, pillars,
-- needles, lightning, the circle.
function B:ClearFx()
	local s = self.frame
	for _, r in ipairs(s.rings) do
		r:SetAlpha(0)
		r.busy = false
	end
	for _, t in ipairs({ s.burst, s.circle, s.spikes, s.flare, s.beams[1], s.beams[2], s.beams[3], s.bolts[1], s.bolts[2], s.bolts[3], s.lightning[1], s.lightning[2] }) do
		t:SetAlpha(0)
		t.tw = nil
	end
	s.circle.on = false
	s.flare.placed = false
	if self.ForgeClear then
		self:ForgeClear()
	end
end

function B:ResetScene()
	local s = self.frame
	-- (1.6.0: a booster held for an omen, another scene before the choice: kept as it was drawn)
	if self.picks and self.picks.hold then
		C:KeepHeld(self.picks)
	end
	if self.CloseInspect then
		self:CloseInspect(true)
	end
	ns.CancelOwner(self)
	ns.CancelOwner(self.freeze)
	self:StopLoops()
	ns.CancelOwner(self.timers)
	for o in pairs(self.owners) do
		ns.CancelOwner(o)
	end
	CuratorOctoFull.Wipe(self.owners)
	self:SetTime(1)
	self.particles:Clear()
	self.stars:Clear()
	self.streaks:Clear()
	self.puffs:Clear()
	self.motes:Clear()
	if self.HallowClear then
		self:HallowClear()
	end
	self:ClearFx()
	self.mode = "booster"
	if self.ContractReset then
		self:ContractReset()
	end
	s.flash:SetAlpha(0)
	s.flash.tw = nil
	s.edge:SetAlpha(0)
	s.edge.tw = nil
	s.dark:SetAlpha(0)
	s.dark.tw = nil
	s.halo:SetAlpha(0.22)
	s.banner:Hide()
	s.banner.tw = nil
	self.footBanner, self.footPending = false, 0
	s.hint:SetAlpha(1)
	s.revealAll:SetAlpha(1)
	s.rays:SetAlpha(0)
	s.rays.on, s.rays.card = false, nil
	s.rays.tw = nil
	s.rays2:SetAlpha(0)
	s.rays2.tw = nil
	-- (1.12.0: the Void behind a corrupted card)
	if s.vsky then
		s.vsky:SetAlpha(0)
		s.vsky.tw = nil
	end
	self.voidT = (self.voidT or 0) + 1
	s.revealAll:Hide()
	s.all:Hide()
	s.omen:Hide()
	s.omenOpen:Hide()
	s.omenShake:Hide()
	s.redraw:Hide()
	for _, t in ipairs(s.tags) do
		t:SetAlpha(0)
	end
	self.omen, self.redrawing, self.rerolled = nil, nil, nil
	CuratorOctoFull.SetShown(s.stop, self.autoAll and true or false)
	s.again:Hide()
	s.album:Hide()
	s.close:Hide()
	s.summary:SetText("")
	s.hint:SetText("")
	s.bar:Hide()
	s.bar.tip:SetAlpha(0)
	s.xpBar:Hide()
	s.xpEmblem:Hide()
	for _, t in ipairs({ s.xpGain, s.xpLevel, s.xpNote }) do
		t:SetText("")
	end
	s.xpLevel:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
	for _, t in ipairs(s.xpFloats) do
		t:SetAlpha(0)
	end
	self.xp0 = nil
	-- (a level gained that the scene did not show: its toast now)
	self:LevelToast()
	s.head:SetScale(1)
	s.head:SetAlpha(1)
	s.head.tw = nil
	s.head:ClearAllPoints()
	s.head:SetPoint("CENTER", s, "CENTER", 0, 300)
	self.cam = { z = 1, x = 0, y = 0, kick = 0, sx = 0, sy = 0 }
	self.shakeT, self.shakeD, self.shakeA = 0, 1, 0
	self.camZ, self.camOX, self.camOY, self.cropZ = nil, nil, nil, nil
	self:CamApply()
	self.tell, self.best, self.bestFinish, self.bestLook, self.bestVoid = nil, nil, nil, nil, nil
	self.hovered = nil
	if self.LairReset then
		self:LairReset()
	end
	-- (1.13.0, after its first test: the cards of Open all)
	if self.BatchReset then
		self:BatchReset()
	end
	self.lair = nil
	self.cards = self.bigCards
	for _, c in ipairs(self.allCards) do
		c:Hide()
		c.free, c.revealed, c.busy, c.hovered, c.hoverOn = false, false, false, false, false
		c.lift, c.shake, c.glowBase, c.pop = 0, 0, 0, 0
		c.liftTw, c.popTw, c.windGo, c.moteT, c.sheenA = nil, nil, nil, 0, 0
		c:SetScale(1)
		c:SetAlpha(1)
		c:SetFlipSize(c.W, c.H)
		c.glow:SetAlpha(0)
		c.glow.tw = nil
		c.back.glow:SetAlpha(0)
		c.back.glow.tw = nil
		c.back.core:SetAlpha(0)
		c.back.core.tw = nil
		c.back.cracks:SetAlpha(0)
		c.back.sheen:SetAlpha(0)
		c.hot:SetAlpha(0)
		c.hot.tw = nil
		c.rays:SetAlpha(0)
		c.rayA = 0
		c.badge:Hide()
	end
	local p = s.pack
	p.dy, p.sc, p.sx, p.sy, p.shake, p.pulse, p.hoverK = 0, 1, 1, 1, 0, 0, 0
	p.flying = false
	p:SetScale(1)
	p:SetAlpha(1)
	CuratorOctoFull.SetSize(p, PACK_W, PACK_H)
	p:ClearAllPoints()
	p:SetPoint("CENTER", s.stage, "CENTER", 0, PACK_Y)
	p.top:ClearAllPoints()
	p.top:SetPoint("TOPLEFT")
	p.top:SetPoint("TOPRIGHT")
	p.top:SetHeight(TOP_H)
	p.top:SetAlpha(1)
	p.top:SetVertexColor(1, 1, 1)
	p.bottom:ClearAllPoints()
	p.bottom:SetAllPoints()
	p.bottom:SetAlpha(1)
	p.bottom:SetVertexColor(1, 1, 1)
	p.name:SetAlpha(1)
	p.kind:SetAlpha(1)
	p.shine:Show()
	p.shine.sheen:SetAlpha(0)
	p.shine.spot:SetAlpha(0)
	p.spotA = 0
	for _, t in ipairs(p.shine.cracks) do
		t:SetAlpha(0)
	end
	p.shine.wash:SetAlpha(0)
	-- first glint right after the pack lands
	p.sweep = SWEEP_EVERY - 0.9
	p.hover = false
	p:Show()
	self.t = 0
	self.moteT = 0
end

-- (1.10.0) The colour of the pack of a golden booster (its art in grey, tinted).
B.GOLD = { 1, 0.8, 0.34 }

function B:Open(series, opts)
	self:Build()
	local s = self.frame
	if s:IsShown() and self.state ~= "done" then
		return
	end
	self.series, self.opts = series, opts or {}
	-- (the full screen, or the small window)
	self:ApplySize()
	self:ResetScene()
	local g = series.glow
	self.glow = g
	s.halo:SetVertexColor(g[1], g[2], g[3])
	local p = s.pack
	p.glow:SetVertexColor(g[1], g[2], g[3])
	p.glow:SetAlpha(0.35)
	local pack = series.pack or "PackElwynn"
	p.bottom:SetTexture(MEDIA .. pack .. "Bottom")
	p.top:SetTexture(MEDIA .. pack .. "Top")
	for _, t in ipairs({ p.bottom, p.top }) do
		CuratorOctoFull.SetDesaturated(t, false)
		t:SetVertexColor(1, 1, 1)
	end
	p.shine.mask:SetTexture(MEDIA .. pack .. "Bottom", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	self:SetBackdrop(series)
	local zone = C:SeriesName(series)
	s.title:SetText(zone)
	local kind = ((series.event or series.limited) and L["Limited edition"]) or (series.dungeon and L["Special collection"]) or L["Booster"]
	-- (1.10.0: a golden booster: the pack of its album in gold, its light of gold)
	if self.opts.golden then
		kind = L["Golden booster"]
		local gold = self.GOLD
		for _, t in ipairs({ p.bottom, p.top }) do
			CuratorOctoFull.SetDesaturated(t, true)
			t:SetVertexColor(gold[1], gold[2], gold[3])
		end
		p.glow:SetVertexColor(1, 0.84, 0.35)
		s.halo:SetVertexColor(1, 0.84, 0.35)
		self.glow = { 1, 0.84, 0.35 }
	end
	s.subtitle:SetText(self.opts.test and L["Test booster"] or kind)
	p.name:SetText(zone)
	p.kind:SetText(kind)
	s.hint:SetText(L["Click to open"])
	-- a dungeon or a raid: its darkness, its chains, its cards (UI/Lair.lua; 1.12.0: an album of an event too)
	if (series.dungeon or series.event) and self.LairOpen then
		self:LairOpen(series)
	end
	self:UpdateCounter()
	self.state = "landing"
	if not s:IsShown() then
		s:SetAlpha(0)
		s:Show()
		ns.Tween(0.25, function(e)
			s:SetAlpha(e)
		end, nil, Ease.outQuad, self)
	end
	-- the pack falls into its place and lands with a thud (a sealed one, heavier, from higher)
	local fall = self.lair and 760 or 600
	p.dy = fall
	p.dropTw = ns.Tween(self.lair and 0.46 or 0.4, function(e)
		p.dy = fall * (1 - e)
	end, function()
		p.dropTw = nil
		self:PackLands()
	end, Ease.inQuad, self, self.lair and 0.25 or 0.1)
	-- the name of the place comes down on the screen (higher over the big cards of a dungeon)
	local h = s.head
	local hy = self.lair and 334 or 300
	h:SetAlpha(0)
	ns.Tween(0.5, function(e, raw)
		local k = 1.4 - 0.4 * e
		h:SetScale(k)
		h:ClearAllPoints()
		h:SetPoint("CENTER", s, "CENTER", 0, hy / k)
		h:SetAlpha(math.min(1, raw * 3))
	end, nil, Ease.outBack, self)
	ns.Play(ns.SND.open)
	if self.opts.golden then
		ns.Delay(0.5, function()
			ns.Play(ns.SND.titanFanfare)
		end, self)
	end
end

function B:PackLands()
	local p = self.frame.pack
	if p.dropTw then
		ns.CancelTween(p.dropTw)
		p.dropTw = nil
	end
	p.dy = 0
	if self.state == "landing" then
		self.state = "pack"
		if self.autoAll then
			-- (opening them all: it opens by itself)
			ns.Delay(0.35, function()
				if self.autoAll and self.state == "pack" then
					self:Tear()
				end
			end, self)
		elseif self:CanOpenAll() and self.opts and self.opts.all then
			-- (1.14.0: opened from the page of the boosters with All: all of them at once)
			self.opts.all = nil
			ns.Delay(0.3, function()
				if self.state == "pack" then
					self:OpenAll()
				end
			end, self)
		elseif self:CanOpenAll() then
			local s = self.frame
			s.all:SetLabel(string.format(L["Open all (%d)"], ns.Packs(self.series)))
			-- (a sealed pack: under the words under its chains)
			local small = self:Small()
			At(s.all, "CENTER", s, "CENTER", 0, self.lair and (small and -318 or -308) or (small and -262 or -248))
			FadeIn(s.all, 0.3, self)
		end
		-- (1.6.0: the Omen of the Augur, ready)
		if not self.autoAll and self:CanOmen() then
			local s = self.frame
			local small = self:Small()
			At(s.omen, "CENTER", s, "CENTER", 0, self.lair and (small and -352 or -342) or (small and -296 or -284))
			s.omen:SetLabel(L["Omen"])
			FadeIn(s.omen, 0.3, self)
		end
	end
	ns.Play(ns.SND.packDrop)
	-- it squashes a little, springs back, wobbles
	ns.Tween(0.45, function(_, raw)
		local k = math.cos(raw * math.pi * 2.5) * (1 - raw) ^ 1.6
		p.sx, p.sy = 1 + 0.06 * k, 1 - 0.06 * k
	end, function()
		p.sx, p.sy = 1, 1
	end, Ease.linear, self)
	local foot = PACK_Y - PACK_H / 2 + 10
	self.puffs:Burst(-80, foot, DUST, 3, 90, 0.8, 90, 0.2, 1.9)
	self.puffs:Burst(80, foot, DUST, 3, 90, 0.8, 90, 0.2, 1.9)
	self:Ring(0, foot, WARM, 460, 0.5, 0.3, 0, "Shock", 0.28)
	self:Punch(0.018, 0.3)
	self:Shake(0.16, 3)
	if self.lair then
		self:LairLands()
	end
end

-- The boosters left to open after this one: of the album, or (1.10.0) the golden boosters waiting.
function B:Left()
	if self.opts and self.opts.golden then
		return ns.Golden and ns.Golden:PackCount() or 0
	end
	return ns.Packs(self.series)
end

function B:UpdateCounter()
	if self.opts and self.opts.golden then
		self.frame.counter:SetText(string.format(L["Golden boosters: %d"], self:Left()))
		return
	end
	self.frame.counter:SetText(string.format(L["Boosters: %d"], ns.Packs(self.series)))
end

-- The smaller cards of a booster of a zone (made once, as many as it holds: eight since 1.14.0, ten before; n: more
-- of them, 1.6.0: more with the talents, up to fourteen for the contracts signed at once).
function B:TenCards(n)
	local s = self.frame
	self.tenCards = self.tenCards or {}
	for i = CuratorOctoFull.Length(self.tenCards) + 1, math.max(C.ODDS.cards, n or 0) do
		local i = i; local c = ns.NewCard(s.stage, "mid")
		c:Hide()
		c.index = i
		CuratorOctoFull.SetScript(c, "OnClick", function()
			B:CardClick(c, i)
		end)
		CuratorOctoFull.SetScript(c, "OnEnter", function(card)
			B:Hover(card, true)
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function(card)
			B:Hover(card, false)
		end)
		c.rays = Tex(s.behind, "BORDER", 3, "Rays", "ADD")
		CuratorOctoFull.SetSize(c.rays, c.W * 2.2, c.W * 2.2)
		self.tenCards[i] = c
		self.allCards[CuratorOctoFull.Length(self.allCards) + 1] = c
	end
	return self.tenCards
end

-- (1.6.0) The Omen can be used on this booster.
function B:CanOmen()
	local TL = ns.Talents
	return self.mode == "booster" and not (self.opts and self.opts.test) and TL ~= nil and TL:Ready("presage")
end

-- The colours the light of the pack climbs: from rare (from the best card, without one) to the best.
local function TellFirst(best)
	return math.min(3, best)
end

-------------------------------------------------------------------------------
-- Opening the pack: it shakes, its light climbs to the colour of the best card inside, it bursts
-------------------------------------------------------------------------------
function B:Tear(omen)
	if self.state == "opening" then
		-- (a second click: no more waiting; an omen: its colour at once)
		if self.omen then
			return self:OmenWait()
		end
		return self:Burst()
	end
	if self.state == "landing" then
		-- (clicked while it falls: it lands at once)
		self:PackLands()
	end
	if self.state ~= "pack" then
		return
	end
	-- (1.6.0: the booster given in a trade while it waited: nothing opens)
	if not self.opts.test and self.mode == "booster" and (self.opts.golden and not ns.Golden:Pack(self.opts.golden.t)
		or (not self.opts.golden and ns.Packs(self.series) <= 0)) then
		ns.Play(ns.SND.close)
		self.frame:Hide()
		return
	end
	-- (1.14.0: its album changed by another addon this session: nothing opens, said; Guard.lua)
	if not self.opts.test and self.mode == "booster" and ns.Guard and not ns.Guard:Allow(self.series) then
		ns.Play(ns.SND.close)
		self.frame:Hide()
		return
	end
	-- (1.14.0, after its test: a reroll opens no booster, said; Reroll.lua)
	if not self.opts.test and self.mode == "booster" and ns.Reroll and ns.Reroll:NoOpening() then
		ns.Reroll:SayNoOpening()
		self.frame:Hide()
		return
	end
	if omen and not self:CanOmen() then
		omen = nil
	end
	self.state = "opening"
	local s, p = self.frame, self.frame.pack
	s.all:Hide()
	s.omen:Hide()
	-- (the experience before this booster: its bar fills from there at the end)
	self.xp0 = (not self.opts.test and self.mode ~= "contract" and ns.Level) and ns.Level:XP() or nil
	-- (1.6.0: an omen: the booster drawn and held until it is opened, or shaken)
	self.omen = omen and true or nil
	local opts = self.opts
	if omen then
		opts = {}
		for k, v in pairs(self.opts) do
			opts[k] = v
		end
		opts.hold = true
	end
	self.picks = C:Open(self.series, opts)
	if omen and ns.Talents then
		ns.Talents:Use("presage")
	end
	-- (the eight cards of a booster of a zone: the smaller ones; six to eleven with the talents; a dungeon:
	-- six or seven)
	if not self.lair and CuratorOctoFull.Length(self.picks) > CuratorOctoFull.Length(self.bigCards) then
		self.cards = self:TenCards(CuratorOctoFull.Length(self.picks))
	elseif self.lair and self.LairCards and CuratorOctoFull.Length(self.picks) > CuratorOctoFull.Length(self.lairCards) then
		self.cards = self:LairCards(CuratorOctoFull.Length(self.picks))
	end
	self:UpdateCounter()
	s.hint:SetText("")
	-- (1.14.0, the Gambler: the bet of Double or Nothing, the Great Game, told over the pack as it opens)
	self:GambleNote(self.picks)
	-- the best card inside, and the best finish among them
	local best, finish, look, void = 1, nil, nil, nil
	for _, pick in ipairs(self.picks) do
		best = math.max(best, math.min(6, pick.card.rarity))
		if pick.finish == "holo" or (pick.finish == "shiny" and not finish) then
			finish = pick.finish
			look = C:FinishLook(pick.card, pick.finish)
		end
		-- (1.12.0: a corrupted card among them, the Void seeps out of the pack)
		if pick.finish == "corrupt" then
			void = true
		end
	end
	self.best, self.bestFinish, self.bestLook, self.bestVoid = best, finish, look, void
	-- a legendary, a mythic or a holographic card inside: the guild watches it open, live (an omen: once
	-- opened)
	if not omen then
		self:AnnounceBest()
	end
	self.tellStep = 0
	local own = self:Owner()
	self.charge = own
	local steps = best - TellFirst(best) + 1
	local burst = STEP_FIRST + (steps - 1) * STEP + HOLD[best]
	ns.Play(ns.SND.packShake)
	self:Loop("charge", best >= 5 and ns.SND.charge or ns.SND.hover[4], burst + 0.3)
	-- it trembles more and more, the light swells
	local tremble = (best >= 3) and (2.5 + 2.2 * (best - 3)) or (0.9 + 0.6 * best)
	ns.Tween(burst, function(_, raw)
		p.shake = 1 + tremble * raw * raw
		p.glow:SetAlpha(0.4 + 0.6 * raw)
		p.shine.wash:SetAlpha(0.22 * raw ^ 3)
	end, nil, Ease.linear, own)
	for k = 1, steps do
		local k = k; ns.Delay(STEP_FIRST + (k - 1) * STEP, function()
			self:TellStep(k)
		end, own)
	end
	ns.Delay(burst, function()
		if self.omen then
			self:OmenWait()
		else
			self:Burst()
		end
	end, own)
end

-- (1.14.0, the Gambler) What the talents did to this booster as it opens, under the pack: the bet of Double or Nothing
-- (won: cards more; lost: cards fewer; Nerves of Steel: lost for nothing), the Great Game (a booster of legend).
function B:GambleNote(picks)
	local TL = ns.Talents
	if not (TL and picks) or self.opts.test or self.mode ~= "booster" then
		return
	end
	local text, col
	local bet = picks.bet
	if picks.grand then
		text, col = L["The Great Game: a booster of legend!"], { 1, 0.82, 0.3 }
	elseif bet then
		local n = math.abs(bet.delta or 0)
		if bet.saved then
			text, col = L["Double or Nothing lost, but Nerves of Steel: it costs nothing."], { 0.7, 0.85, 1 }
		elseif bet.win then
			text = n == 1 and L["Double or Nothing: won, one card more!"] or string.format(L["Double or Nothing: won, %d cards more!"], n)
			col = { 0.45, 1, 0.45 }
		elseif n > 0 then
			text = n == 1 and L["Double or Nothing: lost, one card fewer."] or string.format(L["Double or Nothing: lost, %d cards fewer."], n)
			col = { 1, 0.45, 0.4 }
		else
			text, col = L["Double or Nothing: nothing won, nothing lost."], { 0.85, 0.85, 0.85 }
		end
	end
	if not text then
		return
	end
	local s = self.frame
	s.hint:SetText(text)
	s.hint:SetTextColor(col[1], col[2], col[3])
	s.hint:SetAlpha(1)
	if bet and bet.win then
		ns.Play(ns.SND.coins)
	elseif picks.grand then
		ns.Play(ns.SND.levelSting)
	end
	-- (the colour of the hint back, after it)
	ns.Delay(4, function()
		s.hint:SetTextColor(1, 1, 1)
	end, self)
end

-- A legendary, a mythic or a holographic card inside: the guild watches it open, live. (1.14.2, his word: "rare at least,
-- and titanforged and thunderforged too") A rare card or better inside, or a forged one whatever its rarity; the card
-- the guild is shown goes with it (Comm.lua: G.Worth, G.Star).
function B:AnnounceBest()
	if self.opts.test or self.mode == "contract" then
		return
	end
	local G = ns.Guild
	if G.Worth(self.best, self.bestFinish) then
		local star = G.Star(self.picks)
		G:AnnounceOpen(self.series, self.best, self.bestFinish, star and star.card, star and star.finish)
	end
end

-------------------------------------------------------------------------------
-- (1.6.0) The Omen of the Augur: the light of the pack stops on the colour of its best card; opened, or
-- shaken (drawn again, then opened). Closed meanwhile, the scene keeps it as it was drawn.
-------------------------------------------------------------------------------
function B:OmenWait()
	if self.state ~= "opening" or not self.omen then
		return
	end
	local best = self.best or 3
	local steps = best - TellFirst(best) + 1
	if (self.tellStep or 0) < steps then
		self.tellStep = steps - 1
		self:TellStep(steps)
	end
	if self.charge then
		ns.CancelOwner(self.charge)
	end
	self:StopLoop("charge", 150)
	self.state = "omen"
	local s, p = self.frame, self.frame.pack
	p.shake = 1.4
	local r = ns.RARITY[best]
	local hex = string.format(("%02x%02x%02x"), math.floor(r.text[1] * 255 + 0.5), math.floor(r.text[2] * 255 + 0.5), math.floor(r.text[3] * 255 + 0.5))
	s.hint:SetText(string.format(L["Omen: the best card of this booster is %s."], "|cff" .. hex .. L[r.label] .. "|r"))
	local small = self:Small()
	local y = self.lair and (small and -318 or -308) or (small and -262 or -248)
	At(s.omenOpen, "CENTER", s, "CENTER", -95, y)
	At(s.omenShake, "CENTER", s, "CENTER", 95, y)
	FadeIn(s.omenOpen, 0.25, self)
	FadeIn(s.omenShake, 0.25, self)
	-- (the sound of its colour, made to loop: kept, and stopped with its moment; 1.13.0: played as a sound of one
	-- time, the one of an epic or better went on until the game was left)
	self:Loop("omen", ns.SND.hover[math.min(6, math.max(2, best))] or ns.SND.click, 1.6)
end

-- The booster held is the one opened.
function B:OmenOpen()
	if self.state ~= "omen" then
		return
	end
	local s = self.frame
	s.omenOpen:Hide()
	s.omenShake:Hide()
	s.hint:SetText("")
	self:StopLoop("omen", 200)
	self.omen = nil
	if not C:KeepHeld(self.picks) then
		-- (given in a trade meanwhile: nothing opens)
		ns.Play(ns.SND.close)
		s:Hide()
		return
	end
	self:UpdateCounter()
	self:AnnounceBest()
	self.state = "opening"
	self:Burst()
end

-- Shaken: its light goes out, it shakes hard, and it is drawn again (that one is opened).
function B:OmenShake()
	if self.state ~= "omen" then
		return
	end
	local s, p = self.frame, self.frame.pack
	s.omenOpen:Hide()
	s.omenShake:Hide()
	s.hint:SetText("")
	self:StopLoop("omen", 200)
	self.omen = nil
	if self.picks then
		self.picks.hold = nil
	end
	self.picks = nil
	-- (the booster must still be there: a golden one, by its ticket; 1.10.0)
	local gold = self.opts and self.opts.golden
	if (gold and not ns.Golden:Pack(gold.t)) or (not gold and ns.Packs(self.series) <= 0) then
		ns.Play(ns.SND.close)
		s:Hide()
		return
	end
	self.state = "shaking"
	ns.Play(ns.SND.packShake)
	ns.Play(ns.SND.chainHang)
	self:DarkTo(0, 0.3)
	self:CircleOut(0.4)
	GlowTo(s.rays, 0, 0.3, self)
	s.rays.on = false
	local g = self.glow or WARM
	p.glow:SetVertexColor(g[1], g[2], g[3])
	p.glow:SetAlpha(0.35)
	s.halo:SetVertexColor(g[1], g[2], g[3])
	s.halo:SetAlpha(0.22)
	for _, t in ipairs(p.shine.cracks) do
		t:SetAlpha(0)
	end
	p.shine.wash:SetAlpha(0)
	self.tell, self.best, self.bestFinish, self.bestLook, self.bestVoid = nil, nil, nil, nil, nil
	self:CamTo(1, 0, 0, 0.3, Ease.outCubic)
	self:Shake(0.5, 6)
	local foot = PACK_Y - PACK_H / 2 + 10
	self.puffs:Burst(-60, foot, DUST, 3, 90, 0.8, 90, 0.2, 1.9)
	self.puffs:Burst(60, foot, DUST, 3, 90, 0.8, 90, 0.2, 1.9)
	ns.Tween(0.7, function(_, raw)
		p.shake = 1 + 10 * math.sin(raw * math.pi)
	end, function()
		p.shake = 0
		self.state = "pack"
		self:Tear()
	end, Ease.linear, self)
end

-- One more colour: the light that leaks out of the pack is a rarity higher.
function B:TellStep(k)
	local s, p = self.frame, self.frame.pack
	if self.tellStep >= k then
		return
	end
	self.tellStep = k
	local r = TellFirst(self.best or 3) + k - 1
	local col = TELL[r]
	local from = self.tell or self.glow or WARM
	self.tell = col
	local cracks = p.shine.cracks
	ns.Tween(0.2, function(e)
		local c = Mix(from, col, e)
		p.glow:SetVertexColor(c[1], c[2], c[3])
		s.halo:SetVertexColor(c[1], c[2], c[3])
		for i, t in ipairs(cracks) do
			t:SetVertexColor(c[1], c[2], c[3])
			if i == math.min(k, 3) then
				t:SetAlpha(math.max(t:GetAlpha(), e))
			end
		end
	end, nil, Ease.outQuad, self.charge)
	s.halo:SetAlpha(0.22 + 0.08 * k)
	local cy = PACK_Y + 20
	self:Ring(0, cy, col, 300 + 80 * k, 0.5, 0.6, 0, "Shock")
	self.streaks:Burst(0, cy, col, 8 + 5 * k, 260 + 50 * k, 0.5, 30, 0.9)
	self.particles:Burst(0, cy, Mix(col, WHITE, 0.4), 6 + 3 * k, 160, 0.6, 16)
	p.pulse = 0.05
	ns.Tween(0.22, function(e)
		p.pulse = 0.05 * (1 - e)
	end, nil, Ease.outQuad, self.charge)
	if ns.SND.tell[r] then
		ns.Play(ns.SND.tell[r])
	end
	if r >= 4 then
		self:EdgeGlow(col, 0.2 + 0.1 * (r - 4), 0.5)
	end
	self:CamTo(1 + 0.022 * k, 0, PACK_Y * 0.4, 0.3, Ease.outCubic)
	self:Punch(0.012, 0.2)
	if r >= 5 then
		-- gold and crimson: the place goes dark, a circle of runes opens under the pack, the light
		-- turns behind it, the ground rumbles
		self:DarkTo(r == 5 and 0.38 or 0.66, 0.35)
		self:Circle(0, PACK_Y - 20, col, 560 + 60 * (r - 5), 0.4, r == 6 and 1.1 or 0.8)
		s.rays:ClearAllPoints()
		s.rays:SetPoint("CENTER", s.behind, "CENTER", 0, PACK_Y + 40)
		s.rays:SetVertexColor(col[1], col[2], col[3])
		s.rays.on, s.rays.card = true, nil
		GlowTo(s.rays, 0.5 + 0.2 * (r - 5), 0.3, self.charge)
		if r == 5 then
			ns.Play(ns.SND.rumble)
		end
	end
	if r == 6 then
		self:Bolts(0, PACK_Y + 40, 520, { 1, 0.3, 0.35 })
		ns.Delay(0.24, function()
			self:Bolts(0, PACK_Y + 60, 600, { 1, 0.45, 0.4 })
		end, self.charge)
	end
	if r == self.best and self.bestFinish then
		-- a card with a finish among them: sparks of its colours out of the cracks (a rainbow, or
		-- lightning, or gold)
		for i, rc in ipairs(WAVES[self.bestLook] or RAINBOW) do
			local i, rc = i, rc; ns.Delay(0.05 * i, function()
				self.stars:Burst(0, cy, rc, 2, 220, 0.9, 20)
			end, self.charge)
		end
		if self.bestLook == "thunder" then
			self:Bolts(0, cy, 380, { 0.55, 0.8, 1 })
		elseif self.bestLook == "titan" then
			-- (1.11.0) the light of a prism out of the cracks: needles of white light, motes of every colour
			-- rising from the pack, the hum of the halls of the titans
			self:Spikes(0, cy, { 1, 0.97, 0.92 }, 520, 0.6, 0.7)
			for i, rc in ipairs(WAVES.titan) do
				self.motes:Rise(-PACK_W * 0.6, PACK_W * 0.6, cy - PACK_H * 0.4, rc, 2, 300, 1.8, 14)
			end
			self:Loop("titanTell", ns.SND.titanWake, 2.4)
		end
	elseif r == self.best and self.bestVoid then
		-- (1.12.0, as in Curator Midnight) a corrupted card among them: the Void seeps out of the cracks, its smoke,
		-- its motes of electric blue and violet rising; the eye of N'Zoth heard
		self.puffs:Burst(0, cy, VOID_SMOKE, 5, 110, 1.6, 120, 0.6, 2.4)
		self.motes:Rise(-PACK_W * 0.6, PACK_W * 0.6, cy - PACK_H * 0.4, VOID_BLUE, 10, 300, 1.8, 14)
		self.motes:Rise(-PACK_W * 0.5, PACK_W * 0.5, cy - PACK_H * 0.4, VOID_VIOLET, 6, 280, 1.8, 13)
		ns.Play(ns.SND.nzothEye)
	end
	if self.lair then
		self:LairTell(k, col, r)
	end
end

function B:Burst()
	if self.state ~= "opening" then
		return
	end
	self.state = "dealing"
	local s, p = self.frame, self.frame.pack
	local best = self.best or 3
	if self.charge then
		ns.CancelOwner(self.charge)
	end
	-- (cut short: the last colour at once)
	local steps = best - TellFirst(best) + 1
	if (self.tellStep or 0) < steps then
		self.tellStep = steps - 1
		self:TellStep(steps)
		ns.CancelOwner(self.charge)
	end
	self:StopLoop("charge", 150)
	p.pulse = 0
	local col = TELL[best]
	for _, t in ipairs(p.shine.cracks) do
		t:SetVertexColor(col[1], col[2], col[3])
		t:SetAlpha(1)
	end
	s.halo:SetVertexColor(col[1], col[2], col[3])
	p.glow:SetVertexColor(col[1], col[2], col[3])
	p.shake = 0
	-- (a booster without a rare card bursts more quietly)
	local lvl = (best == 1 and -1.4) or (best == 2 and -0.8) or (best - 3)
	local mouth = self.lair and (PACK_Y + 20) or MOUTH
	local hot = Mix(col, WHITE, 0.45)
	ns.Play(ns.SND.packTear)
	ns.Play(ns.SND.packOpen)
	ns.Play(ns.SND.burst[best] or ns.SND.burst[3])
	-- the instant it bursts: white-hot, everything stops for a breath
	p.shine.wash:SetAlpha(0.95)
	self:Flash(hot, 0.32 + 0.1 * lvl, 0.45 + 0.1 * lvl)
	if best >= 4 then
		self:EdgeGlow(col, 0.36 + 0.12 * (best - 4), 1.0 + 0.2 * (best - 4))
	end
	self:HitStop(math.max(0.02, 0.05 + 0.025 * lvl))
	-- the light of the pack dies as it opens
	ns.Tween(0.25, function(e)
		p.shine.wash:SetAlpha(0.95 * (1 - e))
		for _, t in ipairs(p.shine.cracks) do
			t:SetAlpha(1 - e)
		end
	end, function()
		p.shine:Hide()
	end, Ease.outQuad, self)
	-- the top strip tears off and flies away, turning over (a sealed pack: its chains snap, and it is
	-- destroyed the way of its place)
	p.flying = true
	if self.lair then
		self:LairBreak(col, hot)
	else
		local side = (math.random() < 0.5) and -1 or 1
		ns.Tween(0.6, function(e, raw)
			p.top:ClearAllPoints()
			local h = TOP_H * math.max(0.05, math.abs(math.cos(raw * math.pi * 1.5)))
			CuratorOctoFull.SetSize(p.top, PACK_W * (1 - 0.15 * raw), h)
			p.top:SetPoint("CENTER", p, "TOP", side * 90 * e, -TOP_H / 2 + 170 * e - 120 * raw * raw)
			p.top:SetAlpha(1 - raw * raw)
		end, nil, Ease.outCubic, self)
		self.particles:Rise(-PACK_W * 0.4, PACK_W * 0.4, mouth + 6, hot, 10, 70, 0.6, 14)
	end
	-- a pillar of light shoots up out of the pack, a streak of light across it, the shock
	self:Beam(1, 0, mouth - 20, hot, 230 + 40 * lvl, 1000, 0.9 + 0.15 * lvl, 0.95)
	if best >= 5 then
		self:Beam(2, 0, mouth - 20, col, 520, 1100, 1.3, 0.55)
	end
	self:Flare(0, mouth, hot, 1100 + 260 * lvl, 0.55 + 0.1 * lvl, 1)
	self:Ring(0, mouth, col, 560 + 120 * lvl, 0.7, 0.7, 0, "Shock")
	self:Ring(0, mouth, WARM, 380 + 80 * lvl, 0.55, 0.45, 0.06)
	if best >= 4 then
		self:Ring(0, mouth, col, 820 + 140 * lvl, 0.9, 0.4, 0.12, "Shock")
	end
	s.burst:ClearAllPoints()
	s.burst:SetPoint("CENTER", s.behind, "CENTER", 0, mouth)
	s.burst:SetVertexColor(hot[1], hot[2], hot[3])
	ns.Tween(1.1, function(e, raw)
		s.burst:SetAlpha(math.sin(raw * math.pi) * 0.85)
		CuratorOctoFull.SetSize(s.burst, 380 + 460 * e, 380 + 460 * e)
		CuratorOctoFull.SetRotation(s.burst, raw * 0.6)
	end, nil, Ease.outCubic, self)
	self.streaks:Burst(0, mouth, hot, math.floor(26 + 12 * lvl), 520 + 60 * lvl, 0.7, 44, 0.75)
	self.particles:Burst(0, mouth, col, math.floor(24 + 10 * lvl), 300, 0.9, 24, 0.6)
	self.particles:Burst(0, mouth, WARM, 14, 200, 0.8, 18, 0.6)
	self.stars:Burst(0, mouth, Mix(col, WHITE, 0.6), math.max(2, math.floor(8 + 4 * lvl)), 260, 1.0, 22, 0.6)
	if self.bestFinish then
		for k, rc in ipairs(WAVES[self.bestLook] or RAINBOW) do
			local k, rc = k, rc; self:Ring(0, mouth, rc, 300 + 50 * k, 0.8, 0.4, 0.06 * k)
			ns.Delay(0.05 * k, function()
				self.stars:Burst(0, mouth, rc, 3, 260, 1.1, 22, 0.6)
			end, self)
		end
	elseif self.bestVoid then
		-- (1.12.0) the Void out of the pack: its rings, its smoke
		for k, rc in ipairs({ VOID_VIOLET, VOID_BLUE, VOID_VIOLET }) do
			self:Ring(0, mouth, rc, 300 + 60 * k, 0.9, 0.4, 0.07 * k)
		end
		self.puffs:Burst(0, mouth, VOID_SMOKE, 4, 130, 1.4, 120, 0.6, 2.2)
	end
	self:Punch(0.05 + 0.02 * lvl, 0.6)
	self:Shake(0.3 + 0.1 * lvl, 7 + 3 * lvl)
	self:CamTo(1, 0, 0, 0.7, Ease.outCubic)
	if best >= 5 then
		-- the light comes back on the place; the circle flies apart
		self:DarkTo(0, 1.1, 0.2)
		self:CircleOut(0.6)
		GlowTo(s.rays, 0, 1.2, self)
	end
	GlowTo(s.halo, 0.22, 1.2, self)
	if self.lair then
		-- (the pack goes its own way; the cards come out of its ruin)
		ns.Delay(self:LairDealDelay(), function()
			self:Deal(mouth)
		end, self)
		return
	end
	-- the rest of the pack drops away while the cards come out
	ns.Tween(0.5, function(e)
		p.bottom:ClearAllPoints()
		p.bottom:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -150 * e)
		p.bottom:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, -150 * e)
		p.bottom:SetAlpha(1 - e)
		p.name:SetAlpha(1 - e)
		p.kind:SetAlpha(1 - e)
		p.glow:SetAlpha((1 - e) * 0.9)
	end, function()
		p:Hide()
	end, Ease.inQuad, self, 0.1)
	ns.Delay(0.04, function()
		self:Deal(mouth)
	end, self)
end

-- The cards fly out of the pack, turning over in the air, and land in their places one after the
-- other.
function B:Deal(fromY)
	local s = self.frame
	local st = s.stage
	fromY = fromY or PACK_Y
	self.state = "dealing"
	local n = CuratorOctoFull.Length(self.picks)
	self.landed = 0
	ns.Play(ns.SND.whoosh)
	for i, pick in ipairs(self.picks) do
		local i, pick = i, pick; local c = self.cards[i]
		c.pick = pick
		pick.look = C:FinishLook(pick.card, pick.finish)
		c:SetAlpha(0)
		-- face down first: the face (and its creature) is only drawn once the card is turned over
		c:ShowSide("back")
		-- (1.12.0: a corrupted card has none of its corruption until it is turned over: it spreads then, B:VoidWake)
		c:SetCard(pick.card, { owned = true, finish = pick.finish, count = pick.count, new = false, corrupt = pick.corrupt,
			creep = pick.finish == "corrupt" and 0 or nil, pattern = pick.pt, wear = pick.wear })
		-- (1.12.0) a card of Hallow's End: its back of the night, the candle in its jack-o'-lantern (UI/HallowLair.lua)
		if self.HallowBack then
			self:HallowBack(c, pick.card)
		end
		c.phase = math.random()
		local tx, slotY, row = self:SlotXY(i, n)
		c.row = row
		c.slotX, c.slotY = tx, slotY
		c.free = false
		c:ClearAllPoints()
		c:SetPoint("CENTER", st, "CENTER", 0, fromY)
		c:SetScale(0.45)
		c:Show()
		local r = pick.card.rarity
		-- the trail of the card: the best ones leave their colour in the air
		local trail = r >= 4 and ns.RARITY[r].glow or WARM
		local ax, ay = tx * 0.45, fromY + 150 + math.random() * 50
		local nextSpark = 0
		ns.Tween(0.5, function(e, raw)
			local u = 1 - e
			local x = 2 * u * e * ax + e * e * tx
			local y = u * u * fromY + 2 * u * e * ay + e * e * (slotY + 26)
			local k = 0.45 + 0.65 * e
			c:SetScale(k)
			c:SetFlipSize(math.max(1, c.W * math.abs(math.cos(raw * math.pi * 2))), c.H)
			c:ClearAllPoints()
			c:SetPoint("CENTER", st, "CENTER", x / k, y / k)
			c:SetAlpha(math.min(1, raw * 6))
			if raw >= nextSpark then
				nextSpark = raw + 0.08
				self.particles:Burst(x, y, trail, 1, 30, 0.45, r >= 4 and 22 or 14, 1, 0.3)
			end
		end, function()
			-- it comes down hard on its place
			c:SetFlipSize(c.W, c.H)
			ns.Tween(0.09, function(e)
				local k = 1.1 - 0.1 * e
				c:SetScale(k)
				c:ClearAllPoints()
				c:SetPoint("CENTER", st, "CENTER", tx / k, (slotY + 26 * (1 - e)) / k)
			end, function()
				self:Land(c, n)
			end, Ease.inQuad, self)
		end, Ease.outCubic, self, 0.03 + (i - 1) * 0.075)
	end
end

-- Where a card of the scene lands: its place (x, y) and its row. The five cards of a dungeon are bigger,
-- a little higher, in an arc; the eight of a zone smaller, in two rows (1.6.0: six to fourteen too).
function B:SlotXY(i, n)
	local W, H = self.cards[1].W, self.cards[1].H
	if self.cards == self.tenCards then
		local per = math.ceil(n / 2)
		local row = (i <= per) and 1 or 2
		local inRow = (row == 1) and per or (n - per)
		local col = (row == 1) and i or (i - per)
		return (col - (inRow + 1) / 2) * (W + TEN_GAP_X), TEN_TOP - (row - 1) * (H + TEN_GAP_Y), row
	end
	local gap = self.lair and self:LairGap(n, W) or GAP
	local d = i - (n + 1) / 2
	return d * (W + gap), self.lair and (LAIR_SLOT_Y - LAIR_ARC * d * d) or SLOT_Y, nil
end

-- The gap between the cards of a dungeon: as wide as the scene allows them (the screen, or the small
-- window), LAIR_GAP at most.
function B:LairGap(n, W)
	local sw = self.frame:GetWidth()
	if not sw or sw <= 0 then
		sw = 1365
	end
	if n < 2 then
		return LAIR_GAP
	end
	return math.min(LAIR_GAP, (sw * 0.94 - n * W) / (n - 1))
end

function B:Land(c, n)
	local s = self.frame
	c:SetScale(1)
	c.lift, c.pop = 0, 0
	c.free = true
	ns.Play(ns.SND.cardLand)
	local x, y = c.slotX, c.slotY
	local foot = y - c.H / 2 + 8
	self.puffs:Burst(x - 40, foot, DUST, 1, 50, 0.6, 64, 0.2, 1.7)
	self.puffs:Burst(x + 40, foot, DUST, 1, 50, 0.6, 64, 0.2, 1.7)
	self:Ring(x, foot, WARM, 260, 0.35, 0.22, 0, "Shock", 0.3)
	self:Punch(0.006, 0.18)
	local r = c.pick.card.rarity
	if r >= 4 then
		-- the best ones land in their light
		local col = ns.RARITY[r].glow
		c.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.core:SetVertexColor(col[1], col[2], col[3])
		c.back.glow:SetAlpha(1)
		c.glow:SetAlpha(0.8)
		GlowTo(c.back.glow, AURA_GLOW[math.min(6, r)] * 1.6, 0.6, self)
		GlowTo(c.glow, AURA_GLOW[math.min(6, r)], 0.6, self)
		self:Ring(x, y, col, 300 + 30 * r, 0.5, 0.45, 0, "Shock")
		self.particles:Burst(x, y, col, 6 + 3 * (r - 4), 140, 0.6, 18)
		self:Shake(0.12, 2 + (r - 4))
		ns.Play(ns.SND.hover[3])
	end
	if c:IsMouseOver() then
		self:Hover(c, true)
	end
	self.landed = (self.landed or 0) + 1
	if self.landed >= n then
		ns.Delay(0.15, function()
			if self.state == "dealing" then
				self.state = "cards"
				-- (the card of a single contract: nothing else to reveal)
				local one = self.mode == "contract" and CuratorOctoFull.Length(self.picks) == 1
				s.hint:SetText(one and L["Click the card to reveal it"] or L["Click a card to reveal it"])
				if self.autoAll and not one then
					-- (opening them all: every card turns over by itself)
					ns.Delay(0.3, function()
						if self.state == "cards" then
							self:RevealAll()
						end
					end, self)
				elseif not one then
					FadeIn(s.revealAll, 0.3, self)
				end
			end
		end, self)
	end
end

-------------------------------------------------------------------------------
-- Hover and reveal
-------------------------------------------------------------------------------
function B:Hover(c, on)
	if not c.pick then
		return
	end
	local card = c.pick.card
	if not c.revealed then
		if (self.state ~= "cards" and self.state ~= "dealing") or c.busy or not c.free then
			return
		end
		local r = card.rarity
		local col = ns.RARITY[r].glow
		c.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.core:SetVertexColor(col[1], col[2], col[3])
		if c.hallowBack then
			self:HallowCandle(c, on)
		end
		c.hoverOn = on
		self.hovered = on and c or (self.hovered ~= c and self.hovered or nil)
		if c.liftTw then
			ns.CancelTween(c.liftTw)
		end
		local from, pop = c.lift or 0, c.pop or 0
		local to, popTo = on and 18 or 0, on and 0.04 or 0
		c.liftTw = ns.Tween(0.2, function(e)
			c.lift = from + (to - from) * e
			c.pop = pop + (popTo - pop) * e
		end, nil, Ease.outBack, self)
		-- (the best cards keep a light of their own, face down)
		local rest = r >= 4 and AURA_GLOW[math.min(6, r)] or 0
		local k = HOVER_BOOST[r] or 1
		GlowTo(c.glow, on and math.min(1, (r == 1 and 0.25 or (0.3 + 0.14 * r)) * k) or rest, 0.2, self)
		GlowTo(c.back.glow, on and math.min(1, (r == 1 and 0.12 or (0.18 + 0.12 * r)) * k) or rest * 1.6, 0.2, self)
		GlowTo(c.back.core, on and math.min(1, (r == 1 and 0.15 or (0.2 + 0.13 * r)) * k) or rest * 1.5, 0.25, self)
		if on and not c.hovered then
			c.hovered = true
			self:Loop("hover", ns.SND.hover[r], 0.9)
		end
	else
		if on then
			GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
			self:CardTooltip(card, c.pick)
			if ns.Links then
				ns.Links:AddHint(GameTooltip, false)
			end
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
	end
end

-- The scene closed before every card was turned over: the guild still hears about the best ones (the
-- cards are in the collection already).
function B:TellUntold()
	if not self.picks or (self.opts and self.opts.test) or self.mode == "contract" then
		return
	end
	if self.state ~= "opening" and self.state ~= "dealing" and self.state ~= "cards" then
		return
	end
	for _, pick in ipairs(self.picks) do
		if not pick.told and (pick.card.rarity >= 4 or pick.finish) then
			pick.told = true
			ns.Guild:Announce(pick.card, pick.finish)
		end
	end
end

-- entry: copies to show (a guild member's), else mine
function B:CardTooltip(card, pick, entry)
	local r = ns.RARITY[card.rarity]
	GameTooltip:AddLine(C:Name(card), 1, 0.85, 0.5)
	local finish = pick and pick.finish
	local f = C:FinishName(card, finish)
	GameTooltip:AddLine(L[r.label] .. (f and (" · " .. f) or ""), r.text[1], r.text[2], r.text[3])
	-- (1.12.0) a corrupted card: its corruption
	if finish == "corrupt" then
		GameTooltip:AddLine(string.format(L["Corruption: %d %%"], pick.corrupt or 0), 0.8, 0.48, 1)
	end
	GameTooltip:AddLine(C:Line(card), 0.8, 0.8, 0.85)
	local e = entry or C:Entry(card)
	if pick and pick.new then
		GameTooltip:AddLine(L["New!"], 1, 0.82, 0.25)
	elseif e then
		GameTooltip:AddLine(string.format(L["Copies: %d"], e.n), 0.7, 0.7, 0.75)
	end
	-- (1.14.0, Fence's Eye, a talent of the Smuggler: what the reseller gives for a copy, and what he sells it for)
	local TL = ns.Talents
	if TL and TL.FenceLine then
		local fin = (type(pick) == "table" and pick.finish) or (type(pick) == "string" and pick) or nil
		if fin == true then
			fin = "shiny"
		end
		TL:FenceLine(GameTooltip, card, fin)
	end
end

-- A card of the scene clicked: face down, it is turned over; turned over, a click looks at it closely
-- (UI/Inspect.lua), a shift-click puts it in the chat.
function B:CardClick(c, i)
	if self.redrawing and c.revealed and c.pick then
		return self:RedrawCard(i)
	end
	if c.revealed and c.pick then
		if ns.Links and ns.Links:Modified() then
			-- (1.14.3: the copy that came, its very card: UI/Links.lua)
			local p = c.pick
			ns.Links:Insert(p.card, p.finish, p.pt, nil, p.ci and ns.Copies and ns.Copies:Get(p.card.key, p.ci) or nil)
		elseif self.Inspect then
			self:Inspect(c)
		end
		return
	end
	self:Reveal(i)
end

function B:Reveal(i, auto)
	local c = self.cards[i]
	if not c then
		return
	end
	if c.busy and c.windGo then
		-- (a click while it gathers its light: turned over at once)
		return c.windGo()
	end
	-- (a card that has landed can be turned while the others are still landing)
	if (self.state ~= "cards" and self.state ~= "dealing") or not c:IsShown() or c.revealed or c.busy or not c.free then
		return
	end
	c.busy = true
	c.hoverOn = false
	if self.hovered == c then
		self.hovered = nil
	end
	self:StopLoop("hover", 150)
	local r = c.pick.card.rarity
	local col = ns.RARITY[r].glow
	c.glow:SetVertexColor(col[1], col[2], col[3])
	c.back.glow:SetVertexColor(col[1], col[2], col[3])
	c.back.core:SetVertexColor(col[1], col[2], col[3])
	c.back.cracks:SetVertexColor(col[1], col[2], col[3])
	-- (1.3: a titanforged card no longer has a forge of its own: it is turned over as the others, then
	-- comes its light, B:TitanStrike; 1.11.0: the light of a prism)
	self:WindUp(c, r, auto)
end

-- The card gathers its light: it rises toward you, trembles, its light breaks through its back; the
-- best ones darken the place, open a circle of runes behind them, draw the camera closer, beat like
-- a heart. Then it is turned over (or, legendary and mythic, makes its entrance: UI/Cinematic.lua).
function B:WindUp(c, r, auto)
	local col = ns.RARITY[r].glow
	local dur = WIND[r]
	local own = self:Owner()
	local x = c.slotX
	local rise = (r >= 4 and 30) or (r == 3 and 22) or 12
	local grow = (r >= 4 and 0.1) or (r == 3 and 0.06) or 0.03
	if c.liftTw then
		ns.CancelTween(c.liftTw)
		c.liftTw = nil
	end
	local lift0, pop0 = c.lift or 0, c.pop or 0
	ns.Tween(math.max(0.08, math.min(dur, 0.32)), function(e)
		c.lift = lift0 + (rise - lift0) * e
		c.pop = pop0 + (grow - pop0) * e
	end, nil, Ease.outCubic, own)
	local y = c.slotY + rise
	if r >= 3 then
		for _, t in ipairs({ c.glow, c.back.glow, c.back.core }) do
			if t.tw then
				ns.CancelTween(t.tw)
				t.tw = nil
			end
		end
		local g0, b0, k0 = c.glow:GetAlpha(), c.back.glow:GetAlpha(), c.back.core:GetAlpha()
		ns.Tween(dur, function(_, raw)
			c.shake = (r - 2) * 1.5 * raw * raw
			c.glow:SetAlpha(g0 + (1 - g0) * raw)
			c.back.glow:SetAlpha(b0 + (1 - b0) * raw)
			c.back.core:SetAlpha(k0 + (1 - k0) * raw)
			if r >= 4 or c.hallowBack then
				c.back.cracks:SetAlpha(c.hallowBack and math.max(0.5, raw) or raw ^ 1.4)
			end
		end, nil, Ease.linear, own)
		self.particles:Gather(x, y, col, 4 + 5 * (r - 2), 130 + 40 * (r - 2), math.max(0.25, dur * 0.8), 18)
	end
	local wind = "wind" .. (c.index or 0)
	if r == 3 then
		self:Loop(wind, ns.SND.hover[3], dur + 0.2)
	end
	if r >= 4 then
		self:Circle(x, y, col, 400 + 70 * (r - 4), dur, 0.6 + 0.25 * (r - 4))
		self:DarkTo(DARK[r], dur)
		local pull = 0.35 + 0.1 * (r - 4)
		self:CamTo(ZOOM[r], x * pull, y * pull, dur + 0.1, Ease.inOutCubic)
		self:Loop(wind, r >= 5 and ns.SND.charge or ns.SND.hover[4], dur + 0.3)
		if r >= 5 then
			ns.Play(ns.SND.rumble)
		end
		-- the light swells, like a heart beating faster
		local beats = r - 3
		for k = 1, beats do
			local k = k; ns.Delay(dur * (k / (beats + 1)) ^ 0.8, function()
				self:Pulse(c, col, r, k)
			end, own)
		end
		if r == 6 then
			ns.Delay(dur * 0.35, function()
				self:Bolts(x, y, 420, { 1, 0.3, 0.35 })
			end, own)
			ns.Delay(dur * 0.8, function()
				self:Bolts(x, y, 480, { 1, 0.4, 0.4 })
			end, own)
		end
	end
	local done = false
	local go
	go = function()
		if done then
			return
		end
		-- (the entrance of another card plays: this one waits for its end, its creature would show
		-- over it)
		local cin = ns.Cinematic
		if cin and cin:IsPlaying() then
			ns.Delay(0.15, go, own)
			return
		end
		done = true
		c.windGo = nil
		ns.CancelOwner(own)
		self.owners[own] = nil
		self:StopLoop(wind, 200)
		self:AfterWind(c, r, auto, rise, grow)
	end
	c.windGo = go
	ns.Delay(dur, go, own)
end

-- The card has gathered its light: it is turned over. The legendary and mythic cards
-- make their entrance (UI/Cinematic.lua), the card turned over under its last flash; without it
-- (turned off, or already playing): the flip.
function B:AfterWind(c, r, auto, rise, grow)
	-- (the entrance of another card plays: this one waits for its end, its creature would show over it)
	local cin = ns.Cinematic
	if cin and cin:IsPlaying() then
		ns.Delay(0.15, function()
			self:AfterWind(c, r, auto, rise, grow)
		end, self)
		return
	end
	c.shake = 0
	c.lift, c.pop = rise, grow
	if r >= 3 then
		c.glow:SetAlpha(1)
		c.back.glow:SetAlpha(1)
		c.back.core:SetAlpha(1)
	end
	if r >= 4 or c.hallowBack then
		c.back.cracks:SetAlpha(1)
	end
	if r >= 5 then
		-- (1.13.0: a card of a picture, the Hardcup Saison 3, makes no entrance: the music goes on)
		local art = c.pick.card.art
		if cin and cin:Enabled() and self.StopMusic and not (art and art.fill) then
			-- (the entrance has its own music)
			self:StopMusic(900)
		end
		if cin and cin:Enabled() and cin:Play(c.pick.card, { finish = c.pick.finish }, function()
			c.shake = 0
			c:ShowSide("front")
			c.revealed, c.busy = true, false
			self:OnRevealed(c, auto, true)
		end) then
			return
		end
	end
	self:Turn(c, r, auto)
end

-- A beat of the light of a card about to be turned over.
function B:Pulse(c, col, r, k)
	local x, y = c.slotX, c.slotY + (c.lift or 0)
	self:Ring(x, y, col, 320 + 60 * k, 0.45, 0.55, 0, "Shock")
	self.streaks:Burst(x, y, Mix(col, WHITE, 0.3), 6 + 3 * k, 220 + 40 * k, 0.45, 26, 0.8)
	c.hot:SetVertexColor(col[1], col[2], col[3])
	c.hot:SetAlpha(0.45)
	GlowTo(c.hot, 0, 0.3, self)
	ns.Play(ns.SND.tell[math.min(6, 2 + k + (r - 4))])
	self:EdgeGlow(col, 0.15 + 0.07 * k + 0.05 * (r - 4), 0.45)
	self:Punch(0.015, 0.25)
	self:Shake(0.15, 2 + k)
end

-- The card turns over: slower for the best ones until it is edge on, then fast; white for an instant
-- as its face comes.
function B:Turn(c, r, auto)
	local slow = r >= 4
	if slow then
		self:SetTime(0.45)
	end
	c:Flip(FLIP[r], function()
		if slow then
			self:SetTime(1)
		end
		-- (an entrance began while it was turning: its creature waits for the end of it; a card held
		-- up close: the same)
		if ns.Cinematic and ns.Cinematic.HideCard then
			ns.Cinematic:HideCard(c)
		end
		if self.HideWhileHeld then
			self:HideWhileHeld(c)
		end
		ns.Play(ns.SND.cardFlip)
		c.hot:SetVertexColor(1, 1, 1)
		c.hot:SetAlpha(r >= 3 and 0.9 or 0.55)
		GlowTo(c.hot, 0, 0.35, self)
	end, function()
		c.revealed, c.busy = true, false
		self:OnRevealed(c, auto)
	end, self)
end

-- cine: the card comes out of its entrance, which already gave its banner, its sounds and its voice
function B:OnRevealed(c, auto, cine)
	local s = self.frame
	local pick = c.pick
	local r = pick.card.rarity
	local col = ns.RARITY[r].glow
	local x, y = c.slotX, c.slotY + (c.lift or 0)
	if not cine then
		ns.Play(ns.SND.reveal[r])
		if ns.SND.impact[r] then
			ns.Play(ns.SND.impact[r])
		end
	end
	-- the guild hears about the best pulls (not about test boosters)
	if (r >= 4 or pick.finish) and not self.opts.test and self.mode ~= "contract" and not pick.told then
		pick.told = true
		ns.Guild:Announce(pick.card, pick.finish)
	end
	-- (1.12.0) a card of Hallow's End: a swarm of bats out of it, a puff of smoke (UI/HallowLair.lua)
	if c.hallowBack and self.HallowBurst then
		self:HallowBurst(c)
	end
	-- the light that broke through its back goes out; the card jumps at you and settles
	c.back.cracks:SetAlpha(0)
	c.back.core:SetAlpha(0)
	c.back.sheen:SetAlpha(0)
	c.sheenA = 0
	if r >= 2 or cine then
		c.hot:SetVertexColor(1, 1, 1)
		c.hot:SetAlpha(cine and 0.7 or math.min(0.7, 0.3 + 0.1 * r))
		GlowTo(c.hot, 0, 0.45, self)
	end
	local kick = (r >= 5 and 0.16) or (r == 4 and 0.12) or (r == 3 and 0.08) or 0.04
	local pop0 = (c.pop or 0) + kick
	if c.popTw then
		ns.CancelTween(c.popTw)
	end
	c.popTw = ns.Tween(r >= 4 and 0.8 or 0.55, function(e)
		c.pop = pop0 * (1 - e)
	end, function()
		c.pop = 0
		c.popTw = nil
	end, Ease.outElastic, self)
	if (c.lift or 0) > 0 then
		local from = c.lift
		if c.liftTw then
			ns.CancelTween(c.liftTw)
		end
		c.liftTw = ns.Tween(0.5, function(e)
			c.lift = from * (1 - e)
		end, nil, Ease.outBack, self, r >= 4 and 0.15 or 0)
	end
	-- its light, by rarity
	if r >= 2 then
		c.glow:SetAlpha(1)
		c.glowBase = (r >= 4) and 0.55 or (r == 3 and 0.42 or 0.2)
		GlowTo(c.glow, c.glowBase, 0.9, self)
	end
	if r == 1 then
		GlowTo(c.glow, 0, 0.3, self)
		self.puffs:Burst(x, y - c.H / 2 + 10, DUST, 2, 60, 0.6, 70, 0.2, 1.6)
		self.particles:Burst(x, y, WARM, 5, 90, 0.5, 14)
	elseif r == 2 then
		self:Ring(x, y, col, 280, 0.45, 0.35)
		self.particles:Burst(x, y, col, 10, 130, 0.7, 18)
		self.stars:Burst(x, y, Mix(col, WHITE, 0.5), 3, 120, 0.8, 16)
	elseif r == 3 then
		self:Ring(x, y, col, 420, 0.55, 0.6, 0, "Shock")
		self:Ring(x, y, WARM, 300, 0.5, 0.3, 0.05)
		self.streaks:Burst(x, y, Mix(col, WHITE, 0.25), 18, 380, 0.55, 34, 0.8)
		self.particles:Burst(x, y, col, 14, 190, 0.8, 20)
		self.stars:Burst(x, y, Mix(col, WHITE, 0.5), 6, 180, 0.9, 20)
		self:Flare(x, y, Mix(col, WHITE, 0.5), 520, 0.4, 0.8)
		self:Punch(0.012, 0.25)
		self:Shake(0.12, 3)
	else
		self:BigImpact(c, r, col, x, y, cine)
	end
	self:FinishImpact(c, pick, x, y, r, cine)
	-- its experience falls from it
	if pick.xp then
		ns.Delay(r >= 4 and 0.45 or 0.2, function()
			self:XPFloat(c, pick.xp)
		end, self)
	end
	ns.Delay(r >= 4 and 0.3 or 0.12, function()
		c:Animate(self)
		if (not auto or r >= 3) and not cine then
			c:PlayVoice()
		end
	end, self)
	if pick.new then
		local bd = c.badge
		bd:SetScale(0.2)
		bd:Show()
		ns.Tween(0.4, function(e)
			bd:SetScale(0.2 + 0.8 * e)
		end, function()
			self.stars:Burst(x + c.W * 0.32, y + c.H * 0.43, { 1, 0.82, 0.4 }, 3, 70, 0.6, 16)
		end, Ease.outBack, self, 0.2)
	elseif pick.count and pick.count > 1 then
		c.over.count:SetText("x" .. pick.count)
	end
	if c:IsMouseOver() then
		self:Hover(c, true)
	end
	if self.mode == "contract" then
		-- (1.13.0, after its second test: the pick and its card too, for the clause of the collection)
		ns.Fire("CONTRACT_REVEALED", pick.card, pick, c)
	end
	-- (1.6.0: a card the talents changed: which one, over it)
	-- (1.14.0: the talents of the Gambler: Opening Stake and Winning Streak, a card raised; Loaded Dice, a card
	-- thunderforged; Jackpot, the whole booster thunderforged, told on its legendary card)
	local tag = (type(pick.raised) == "string" and pick.raised) or (pick.loaded and "loaded")
		or (pick.jackpot and pick.card.rarity >= 5 and "jackpot") or nil
	if not tag and self.picks and self.picks.jackpot and pick.card.rarity >= 5 then
		tag = "jackpot"
	end
	if tag and ns.Talents then
		ns.Delay(r >= 4 and 0.5 or 0.25, function()
			self:TalentTag(c, tag)
		end, self)
	end
	self:CheckDone()
end

-------------------------------------------------------------------------------
-- (1.6.0) The talents in the scene: a card drawn again (Redraw, Second Chance), the words of a talent over
-- a card it changed
-------------------------------------------------------------------------------

function B:TalentTag(c, id)
	local s = self.frame
	local TL = ns.Talents
	local d = TL and TL.BY[id]
	if not d or not c:IsShown() then
		return
	end
	s.tagI = CuratorOctoFull.Mod((s.tagI or 0) , CuratorOctoFull.Length(s.tags)) + 1
	local t = s.tags[s.tagI]
	t:SetText(TL:Name(id))
	local col = TL.SPEC_BY[d.spec].color
	t:SetTextColor(col[1], col[2], col[3])
	-- (over the card; a card of the second row: on its top, the first row is above it)
	local x, y0 = c.slotX, c.slotY + c.H / 2 + ((c.row == 2) and -26 or (c.row == 1 and 16 or 40))
	if t.tw then
		ns.CancelTween(t.tw)
	end
	self.stars:Burst(x, c.slotY + c.H / 2, col, 5, 90, 0.7, 14)
	t.tw = ns.Tween(2.4, function(e, raw)
		t:ClearAllPoints()
		t:SetPoint("CENTER", s.fx, "CENTER", x, y0 + 16 * e)
		t:SetAlpha((raw < 0.1 and raw / 0.1) or (raw > 0.7 and (1 - raw) / 0.3) or 1)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.outCubic, self)
end

-- The tooltip of the button of a talent of the scene.
function B:TalentButtonTooltip(b, id)
	local TL = ns.Talents
	local d = TL and TL.BY[id]
	if not d then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	local col = TL.SPEC_BY[d.spec].color
	GameTooltip:AddLine(TL:Name(id), col[1], col[2], col[3])
	GameTooltip:AddLine(TL:Text(id, 1), 1, 1, 1, true)
	GameTooltip:Show()
end

function B:CanRedraw()
	local TL = ns.Talents
	if not TL or (self.opts and self.opts.test) or self.autoAll then
		return false
	end
	if self.mode == "contract" then
		return self.result ~= nil and TL:Ready("second")
	end
	return self.mode == "booster" and TL:Ready("reroll")
end

function B:OfferRedraw()
	local s = self.frame
	if self.state == "done" and self:CanRedraw() then
		s.redraw:SetLabel(self.mode == "contract" and L["Second chance"] or L["Redraw a card"])
		FadeIn(s.redraw, 0.3, self)
	else
		s.redraw:Hide()
	end
end

-- The button clicked: a card to choose.
function B:StartRedraw()
	if self.state ~= "done" or not self:CanRedraw() then
		return
	end
	local s = self.frame
	self.redrawing = true
	s.redraw:Hide()
	s.summary:SetText(L["Click the card to draw again."])
	s.summary:SetAlpha(1)
end

-- That card drawn again: it turns face down, another card takes its place, it is turned over.
function B:RedrawCard(i)
	local c = self.cards[i]
	local TL = ns.Talents
	if not (c and c.revealed and c.pick and TL and self.state == "done") then
		return
	end
	self.redrawing = nil
	local np
	if self.mode == "contract" then
		local r = ns.Contract:Redraw(self.result, i)
		if r then
			np = { card = r.card, finish = r.finish, shiny = r.finish == "shiny", holo = r.finish == "holo", new = r.new, count = r.count,
				look = C:FinishLook(r.card, r.finish), redrawn = true }
		end
	elseif TL:Ready("reroll") then
		np = C:Redraw(self.series, self.picks, i)
		if np then
			TL:Use("reroll")
		end
	end
	if not np then
		ns.Play(ns.SND.close)
		self.frame.summary:SetText("")
		return
	end
	self.picks[i] = np
	self.rerolled = true
	-- (while it turns: nothing else to click)
	self.state = "redraw"
	local s = self.frame
	s.summary:SetText("")
	s.redraw:Hide()
	ns.Play(ns.SND.cardFlip)
	c.busy = true
	ns.Tween(0.2, function(e)
		c:SetFlipSize(math.max(1, c.W * (1 - e)), c.H)
	end, function()
		c.pick = np
		c.revealed = false
		c:ShowSide("back")
		c:SetCard(np.card, { owned = true, finish = np.finish, count = np.count, new = false, corrupt = np.corrupt,
			creep = np.finish == "corrupt" and 0 or nil, pattern = np.pt, wear = np.wear })
		-- (1.12.0) its back is the one of the new card (Card:SetBack): its candle too, for a card of Hallow's End
		if self.HallowBack then
			self:HallowBack(c, np.card)
		end
		c.badge:Hide()
		c:SetFlipSize(1, c.H)
		local col = ns.RARITY[np.card.rarity].glow
		self.particles:Burst(c.slotX, c.slotY, col, 10, 140, 0.6, 16)
		ns.Tween(0.2, function(e)
			c:SetFlipSize(math.max(1, c.W * e), c.H)
		end, function()
			c:SetFlipSize(c.W, c.H)
			c.busy, c.free = false, true
			self.state = "cards"
			self:Reveal(i)
		end, Ease.outQuad, self)
	end, Ease.inQuad, self)
end

-- Epic, legendary, mythic: the instant stops, a flash, needles and wheels of light behind the card, a
-- pillar of light through it (legendary and up), shock waves, a streak of light, sparks, the banner;
-- the camera kicks and comes back, the light comes back on the place.
function B:BigImpact(c, r, col, x, y, cine)
	local s = self.frame
	local lvl = r - 4
	local hot = Mix(col, WHITE, 0.5)
	if not cine then
		self:HitStop(0.06 + 0.03 * lvl)
	end
	if r == 4 then
		self:Flash(col, 0.25, 0.45)
	elseif r == 5 then
		self:Flash({ 1, 0.9, 0.7 }, cine and 0.4 or 0.55, 0.75)
	else
		if not cine then
			ns.Play(ns.SND.gong)
		end
		self:Flash({ 1, 0.86, 0.86 }, cine and 0.45 or 0.7, 0.9)
	end
	self:CircleOut(0.55)
	self:DarkTo(0, 0.9, 0.1)
	self:EdgeGlow(col, (r == 4 and 0.45) or (r == 5 and 0.58) or 0.68, 1.1 + 0.2 * lvl)
	self:Spikes(x, y, hot, 620 + 160 * lvl, 0.5 + 0.1 * lvl, 0.95)
	self:Ring(x, y, col, 520 + 90 * lvl, 0.6, 0.75, 0, "Shock")
	self:Ring(x, y, WARM, 380 + 60 * lvl, 0.55, 0.45, 0.06)
	self:Ring(x, y, col, 760 + 140 * lvl, 0.85, 0.4, 0.14, "Shock")
	self:Flare(x, y, hot, 900 + 380 * lvl, 0.55 + 0.1 * lvl, 1)
	self.streaks:Burst(x, y, hot, 30 + 16 * lvl, 460 + 70 * lvl, 0.65, 40, 0.8)
	self.particles:Burst(x, y, col, 30 + 14 * lvl, 280 + 50 * lvl, 1.1 + 0.15 * lvl, 26)
	self.stars:Burst(x, y, Mix(col, WHITE, 0.6), 10 + 6 * lvl, 240, 1.2, 24)
	ns.Delay(0.22, function()
		self.particles:Burst(x, y, { 1, 0.88, 0.6 }, 18 + 10 * lvl, 210, 1.1, 20)
	end, self)
	if r >= 5 then
		self:Beam(1, x, y, hot, 210 + 50 * lvl, 820, 1.1 + 0.2 * lvl, 0.9)
		self:Beam(3, x, y, hot, 210 + 50 * lvl, 620, 1.0 + 0.2 * lvl, 0.7, true)
	end
	-- the wheels of rays behind it stay a while
	s.rays:ClearAllPoints()
	s.rays:SetPoint("CENTER", s.behind, "CENTER", x, y)
	s.rays2:ClearAllPoints()
	s.rays2:SetPoint("CENTER", s.behind, "CENTER", x, y)
	s.rays:SetVertexColor(col[1], col[2], col[3])
	s.rays.on, s.rays.card = true, c
	s.rays:SetAlpha(r == 4 and 0.85 or 1)
	-- (they dim a while later, unless they shine behind another card since)
	if r == 4 then
		ns.Delay(1.6, function()
			if s.rays.card == c then
				GlowTo(s.rays, 0.32, 1.4, self)
			end
		end, self)
	else
		ns.Delay(3, function()
			if s.rays.card == c then
				GlowTo(s.rays, r >= 6 and 0.55 or 0.45, 1.5, self)
			end
		end, self)
	end
	if r < 6 then
		-- (the second wheel is the mythic cards' and the titans': not behind this one)
		GlowTo(s.rays2, 0, 0.4, self)
	end
	if r >= 6 then
		-- the darkness breaks in a crimson flash, two wheels of rays (crimson and gold)
		s.halo:SetVertexColor(col[1], col[2], col[3])
		GlowTo(s.halo, 0.5, 0.8, self)
		s.rays2:SetVertexColor(1, 0.78, 0.36)
		GlowTo(s.rays2, 0.55, 0.6, self)
		ns.Delay(3.5, function()
			if s.rays.card == c then
				GlowTo(s.rays2, 0.3, 1.5, self)
			end
		end, self)
		ns.Delay(0.45, function()
			self.particles:Burst(x, y, col, 30, 200, 1.2, 20)
		end, self)
		if not cine then
			self:Bolts(x, y, 560, { 1, 0.35, 0.4 })
		end
	end
	if not cine then
		local label = (r == 4 and L["EPIC!"]) or (r == 5 and L["LEGENDARY!"]) or L["MYTHIC!"]
		local kind = (r == 4 and "Epic") or (r == 5 and "Legendary") or "Mythic"
		self:Banner(label, kind, x, self:BannerY(c), r == 4 and 1.4 or (r == 5 and 2.2 or 3))
	end
	self:Punch(0.045 + 0.02 * lvl, 0.55)
	self:Shake(0.3 + 0.2 * lvl, 7 + 2 * lvl)
	self:CamTo(1, 0, 0, 0.8, Ease.outCubic, 0.05)
end

-- The banner of a finish: at once, or once the banner of the rarity has gone (epic and up, when
-- the card had no entrance of its own).
function B:FinishBanner(text, kind, c, x, r, cine, hold)
	local wait = 0
	if r >= 4 and not cine then
		wait = (r == 4 and 1.4) or (r == 5 and 2.2) or 3
		wait = wait + 0.85
	end
	if wait > 0 then
		-- (under the second row: the end of the booster waits for it too)
		local under = self:BannerY(c) < 0
		if under then
			self.footPending = (self.footPending or 0) + 1
		end
		ns.Delay(wait, function()
			if under then
				self.footPending = math.max(0, (self.footPending or 0) - 1)
			end
			self:Banner(text, kind, x, self:BannerY(c), hold)
		end, self)
	else
		self:Banner(text, kind, x, self:BannerY(c), hold)
	end
end

-- Thunderforged: lightning strikes the card. Titanforged: the light of a prism (UI/Forge.lua; the titans
-- struck it before 1.11.0). (1.3: every card; the shiny and holographic cards of before are so now.) (1.12.0)
-- Corrupted: N'Zoth wakes (B:VoidWake).
function B:FinishImpact(c, pick, x, y, r, cine)
	local look = C:FinishLook(pick.card, pick.finish)
	if look == "thunder" then
		self:Thunderstrike(c, x, y, r, cine)
		self:FinishBanner(L["THUNDERFORGED!"], "Thunder", c, x, r, cine, 1.9)
	elseif look == "titan" then
		self:TitanStrike(c, x, y, r, cine)
		self:FinishBanner(L["TITANFORGED!"], "Prism", c, x, r, cine, 2.2)
	elseif look == "corrupt" then
		-- (1.12.0, as in Curator Midnight) N'Zoth wakes over it, the toast of a corrupted item of 8.3 heard, its
		-- corruption on its banner
		local level = C.Gauge(pick.corrupt)
		self:VoidWake(c, level, x, y, cine)
		self:FinishBanner(string.format(L["CORRUPTED! %d %%"], level), "Corrupt", c, x, r, cine, level >= 100 and 2.8 or 2.2)
	end
end

-- (1.12.0, as in Curator Midnight) The sky of the Void behind a corrupted card, made the first time one is turned over.
function B:VoidPieces()
	local s = self.frame
	if s.vsky then
		return s
	end
	local bk = s.behind
	s.vsky = Tex(bk, "BORDER", -1)
	s.vsky:SetTexture(MEDIA .. "VoidNebula", "REPEAT", "REPEAT")
	s.vskyMask = CuratorOctoFull.CreateMaskTexture(bk)
	s.vskyMask:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	s.vskyMask:SetAllPoints(s.vsky)
	CuratorOctoFull.AddMaskTexture(s.vsky, s.vskyMask)
	return s
end

-- (1.12.0, as in Curator Midnight) A corrupted card turned over: N'Zoth wakes. The place goes dark, the Void opens
-- behind the card, the corruption spreads over it as far as what it brings (level), the smoke and the motes of the
-- Void rise from it. (How strong all of it is: from the least it can bring to all of it, k.)
function B:VoidWake(c, level, x, y, cine)
	local s = self:VoidPieces()
	local k = 0.25 + 0.75 * level / 100
	self.voidT = (self.voidT or 0) + 1
	local token = self.voidT
	if not cine then
		ns.Play(ns.SND.corruptLoot)
	end
	ns.Delay(0.45, function()
		ns.Play(ns.SND.nzothEye)
	end, self)
	if level >= 80 then
		ns.Play(ns.SND.rumble)
	end
	-- (all of it: the Void drowns it, the place goes darker still, longer)
	if level >= 100 then
		ns.Delay(0.9, function()
			self:EdgeGlow(VOID_VIOLET, 0.65, 2.4)
			self:Shake(0.7, 6)
		end, self)
	end
	-- the place dark, a light of the Void at its edges
	self:DarkTo(0.3 + 0.32 * k, 0.6, 0.1)
	self:EdgeGlow(VOID_VIOLET, 0.35 + 0.25 * k, 1.8 + k)
	self:Shake(0.5 + 0.3 * k, 3 + 4 * k)
	-- the corruption spreads over the card
	c:SpreadCorruption(math.min(level, (c.opts and c.opts.creep) or 0), level, 0.7 + 0.8 * k, self)
	-- its smoke and its motes
	self.puffs:Burst(x, y - c.H * 0.2, VOID_SMOKE, 4 + math.floor(4 * k), 120, 1.6, 110, 0.7, 2.4)
	self.motes:Rise(x - c.W * 0.6, x + c.W * 0.6, y - c.H * 0.5, VOID_BLUE, 10 + math.floor(8 * k), 280, 2.2, 14)
	ns.Delay(0.3, function()
		self.motes:Rise(x - c.W * 0.6, x + c.W * 0.6, y - c.H * 0.5, VOID_VIOLET, 6 + math.floor(6 * k), 260, 2.2, 13)
	end, self)
	-- the Void behind the card: a round of the sky of N'Zoth, its clouds turning slowly
	self:VoidSky(x, y, c.H * (0.95 + 0.35 * k), 0.55 + 0.3 * k, 3.6 + k)
	-- the place comes back (unless another card has darkened it since)
	ns.Delay(2.6 + k, function()
		if self.voidT ~= token then
			return
		end
		for _, other in ipairs(self.cards or {}) do
			if other ~= c and other.busy then
				return
			end
		end
		self:DarkTo(0, 1.2)
	end, self)
end

-- The sky of the Void opens behind a card: a round of it R points across, as bright as top, for dur seconds.
function B:VoidSky(x, y, R, top, dur)
	local s = self:VoidPieces()
	local sky = s.vsky
	sky:ClearAllPoints()
	sky:SetPoint("CENTER", s.behind, "CENTER", x, y)
	if sky.tw then
		ns.CancelTween(sky.tw)
	end
	sky.tw = ns.Tween(dur, function(_, raw)
		local a = (raw < 0.15 and raw / 0.15) or (raw > 0.72 and (1 - raw) / 0.28) or 1
		sky:SetAlpha(top * a)
		local u = raw * 0.05
		sky:SetTexCoord(u, u + 0.7, u * 0.5, u * 0.5 + 0.7)
		local g = R * 2 * (0.75 + 0.25 * math.min(1, raw / 0.2))
		CuratorOctoFull.SetSize(sky, g, g)
	end, function()
		sky:SetAlpha(0)
		sky.tw = nil
	end, Ease.linear, self)
end

-- Thunderforged: a bolt of lightning falls from the sky on the card, three times bright, the screen
-- goes white and blue, lightning crackles around it, the thunder rolls.
function B:Thunderstrike(c, x, y, r, cine)
	local s = self.frame
	local blue, pale = WAVES.thunder[1], WAVES.thunder[2]
	if not cine then
		-- (an entrance already had its thunder)
		ns.Play(ns.SND.thunder)
		ns.Delay(0.12, function()
			ns.Play(ns.SND.thunderRoll)
		end, self)
	end
	for i, b in ipairs(s.lightning) do
		local i, b = i, b; b:ClearAllPoints()
		b:SetPoint("BOTTOM", s.fx, "CENTER", x + (i - 1.5) * 14, y - 30)
		CuratorOctoFull.SetSize(b, i == 1 and 190 or 120, 1150)
		if b.tw then
			ns.CancelTween(b.tw)
		end
		local lag = (i - 1) * 0.05
		b.tw = ns.Tween(0.55, function(_, raw)
			-- three strokes, the last one fading
			local k = (raw < 0.12 and 1) or (raw < 0.2 and 0.25) or (raw < 0.34 and 0.95) or (raw < 0.42 and 0.3) or (1 - raw) / 0.58 * 0.9
			b:SetAlpha(k * (i == 1 and 1 or 0.6))
		end, function()
			b:SetAlpha(0)
			b.tw = nil
		end, Ease.linear, self, lag)
	end
	self:Flash({ 0.82, 0.92, 1 }, 0.5, 0.5)
	self:EdgeGlow(blue, 0.62, 1.1)
	if not cine then
		self:HitStop(0.07)
	end
	self:Bolts(x, y, 520, pale)
	ns.Delay(0.2, function()
		self:Bolts(x, y + 30, 600, blue)
	end, self)
	self:Ring(x, y, blue, 640, 0.6, 0.85, 0, "Shock")
	self:Ring(x, y, WHITE, 420, 0.5, 0.5, 0.05)
	self:Ring(x, y - c.H / 2 + 10, pale, 760, 0.6, 0.6, 0.02, "Shock", 0.3)
	self.streaks:Burst(x, y, pale, 34, 560, 0.6, 40, 0.8)
	self.particles:Burst(x, y, blue, 26, 300, 0.9, 20)
	self.stars:Burst(x, y, WHITE, 10, 220, 1.0, 22)
	self:Punch(0.05, 0.5)
	self:Shake(0.45, 11)
end

function B:RevealAll()
	if self.state ~= "cards" then
		return
	end
	self.frame.revealAll:Hide()
	local queue = {}
	for i, c in ipairs(self.cards) do
		if c:IsShown() and not c.revealed and not c.busy then
			queue[CuratorOctoFull.Length(queue) + 1] = i
		end
	end
	-- best card last (a titanforged card after all of them: the titans strike it; 1.12.0: a corrupted one, N'Zoth
	-- wakes over it)
	local function rank(i)
		local p = self.cards[i].pick
		return p.card.rarity + (Struck(p.look) and 10 or 0)
	end
	table.sort(queue, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then
			return ra < rb
		end
		return a < b
	end)
	local function step(k)
		-- the entrance of a legendary or mythic card plays to its end first; a card held in the hand
		-- (B:Inspect) is put back first
		if (ns.Cinematic and ns.Cinematic:IsPlaying()) or self.inspecting then
			ns.Delay(0.25, function()
				step(k)
			end, self)
			return
		end
		local i = queue[k]
		if not i then
			return
		end
		local c = self.cards[i]
		if c.revealed or c.busy then
			return step(k + 1)
		end
		self:Reveal(i, true)
		local r = c.pick.card.rarity
		local nextI = queue[k + 1]
		local nextR = nextI and self.cards[nextI].pick.card.rarity or 0
		if r <= 2 and nextR <= 3 then
			-- the small ones turn over one after the other, without waiting
			ns.Delay(0.16, function()
				step(k + 1)
			end, self)
			return
		end
		-- a beat after this one is turned (a breath more before the best ones)
		local function wait()
			if c.revealed and not (ns.Cinematic and ns.Cinematic:IsPlaying()) then
				local beat = (r >= 4 and 0.6) or (r == 3 and 0.2) or 0.12
				if nextR >= 4 or (nextI and Struck(self.cards[nextI].pick.look)) then
					beat = beat + 0.3
				end
				ns.Delay(beat, function()
					step(k + 1)
				end, self)
			else
				-- (longer than the longest frame: a delay that ends in the frame it is made would start
				-- again in that same frame)
				ns.Delay(0.12, wait, self)
			end
		end
		wait()
	end
	step(1)
end

function B:CheckDone()
	for _, c in ipairs(self.cards) do
		if c:IsShown() and not c.revealed then
			return
		end
	end
	self.state = "done"
	local s = self.frame
	s.revealAll:Hide()
	s.hint:SetText("")
	local new = 0
	for _, p in ipairs(self.picks) do
		if p.new then
			new = new + 1
		end
	end
	local owned, total = C:Progress(self.series)
	-- (its words come with the buttons, not before)
	s.summary:SetAlpha(0)
	s.summary:SetText(string.format(L["New cards: %d"], new) .. "   ·   " .. string.format(L["%d / %d cards"], owned, total))
	local bar = not self.opts.test and self.mode ~= "contract" and not self.rerolled
	if self.mode == "contract" then
		local p = self.picks[1]
		if CuratorOctoFull.Length(self.picks) > 1 then
			-- several contracts: their new cards; the place of the finest of them takes the screen
			s.summary:SetText(string.format(L["New cards: %d"], new))
			local best = p
			for _, q in ipairs(self.picks) do
				if q.card.rarity > best.card.rarity then
					best = q
				end
			end
			self.series = best.card.series
			ns.Fire("CONTRACT_DONE", best.card)
		else
			s.summary:SetText(p.new and L["New card!"] or string.format(L["Copies: %d"], p.count))
		end
	elseif self.opts.test then
		s.summary:SetText(L["A preview: nothing was added to your collection."])
	end
	-- the cards jump one after the other, then the album fills up with the new ones
	ns.Delay(0.35, function()
		local shown = 0
		for _, c in ipairs(self.cards) do
			local _, c = _, c; if c:IsShown() then
				shown = shown + 1
				local cc, k = c, shown
				ns.Delay(0.07 * (k - 1), function()
					local col = ns.RARITY[cc.pick.card.rarity].glow
					local from = cc.lift or 0
					if cc.liftTw then
						ns.CancelTween(cc.liftTw)
					end
					cc.liftTw = ns.Tween(0.4, function(_, raw)
						cc.lift = from * (1 - raw) + math.sin(raw * math.pi) * 14
					end, nil, Ease.linear, self)
					self.particles:Burst(cc.slotX, cc.slotY + cc.H / 2, col, 4, 80, 0.6, 14)
				end, self)
			end
		end
		if shown > 1 then
			ns.Play(ns.SND.tick)
		end
	end, self)
	-- (after a banner under the second row of cards: B:WhenFootFree)
	ns.Delay(0.5, function() self:WhenFootFree(function()
		FadeIn(s.summary, 0.3, self)
		if bar then
			self:FillBar(owned - new, owned, total, new)
			self:FillXP()
		end
		if self.mode == "contract" then
			CuratorOctoFull.SetEnabled(s.again, true)
			s.again:SetLabel(L["New contract"])
			s.album:SetLabel(L["Album"])
			FadeIn(s.album, 0.3, self)
			FadeIn(s.close, 0.3, self)
			s.again:Show()
			s.again:SetAlpha(1)
			self:OfferRedraw()
			return
		end
		local left = self:Left()
		CuratorOctoFull.SetEnabled(s.again, left > 0)
		s.again:SetLabel(L["Open another"] .. " (" .. left .. ")")
		s.album:SetLabel(L[(self.opts and B.BACK_LABEL[self.opts.from or ""]) or "Album"])
		FadeIn(s.album, 0.3, self)
		FadeIn(s.close, 0.3, self)
		CuratorOctoFull.SetShown(s.again, not self.opts.test)
		s.again:SetAlpha(left > 0 and 1 or 0.45)
		self:OfferRedraw()
		if self.autoAll then
			if left > 0 and not self.opts.test then
				self:AutoNext()
			else
				self:StopAll()
			end
		end
	end) end, self)
end

-------------------------------------------------------------------------------
-- Opening them all (1.2): each booster of the album opens by itself, its cards turn over by
-- themselves, the next one comes once they have been seen (and the screens of a level, an album
-- complete, an entrance, have played); a click on "Stop" ends it after the booster on the screen.
-------------------------------------------------------------------------------
function B:CanOpenAll()
	return self.mode == "booster" and not (self.opts and (self.opts.test or self.opts.golden)) and ns.Packs(self.series) >= 2
		and not (ns.Reroll and ns.Reroll:NoOpening())
end

function B:OpenAll()
	if self.state ~= "pack" or not self:CanOpenAll() then
		return
	end
	-- (1.13.0, after its first test: ten at most, one after the other, then all their cards on the screen)
	if self.Batch then
		return self:Batch()
	end
	self.autoAll = true
	self.frame.all:Hide()
	FadeIn(self.frame.stop, 0.25, self)
	self:Tear()
end

function B:StopAll()
	if self.batch and self.BatchStop then
		return self:BatchStop()
	end
	self.autoAll = nil
	if self.frame then
		self.frame.stop:Hide()
	end
end

-- The next booster, a moment after this one was seen.
function B:AutoNext()
	local doneAt = GetTime()
	local function wait()
		if not self.autoAll or self.state ~= "done" or not self.frame:IsShown() then
			return
		end
		-- (a level gained shows its screen once the bar of the level is full: a few seconds at most)
		local busy = (self.pendingLevel and GetTime() - doneAt < 6) or (ns.LevelUp and ns.LevelUp:Showing()) or (ns.Complete and ns.Complete:Showing())
			or (ns.Cinematic and ns.Cinematic:IsPlaying()) or self.inspecting
		if busy or GetTime() - doneAt < 1.8 then
			ns.Delay(0.3, wait, self)
			return
		end
		self:Again()
	end
	ns.Delay(0.3, wait, self)
end

-- The bar of the album fills up from what it had to what it has now, a chime for each new card.
function B:FillBar(from, to, total, new)
	local s = self.frame
	local bar = s.bar
	local g = self.series.glow
	bar:SetStatusBarColor(g[1], g[2], g[3])
	total = math.max(1, total)
	local p0, p1 = math.max(0, from) / total, math.max(0, to) / total
	bar:SetProgress(p0)
	bar:SetAlpha(0)
	bar:Show()
	FadeIn(bar, 0.25, self)
	local tip = bar.tip
	tip:SetVertexColor(0.6 + 0.4 * g[1], 0.6 + 0.4 * g[2], 0.6 + 0.4 * g[3])
	local w = bar:GetWidth() or 300
	if w <= 0 then
		w = 300
	end
	if new <= 0 then
		return
	end
	local dur = math.min(1.4, 0.35 + 0.15 * new)
	local chimes = 0
	ns.Tween(dur, function(e)
		local p = p0 + (p1 - p0) * e
		bar:SetProgress(p)
		tip:ClearAllPoints()
		tip:SetPoint("CENTER", bar, "LEFT", w * p, 0)
		tip:SetAlpha(0.9)
		CuratorOctoFull.SetRotation(tip, e * 2)
		local due = math.min(new, math.floor(e * new + 0.001))
		while chimes < due and chimes < 6 do
			chimes = chimes + 1
			ns.Play(ns.SND.tick)
		end
	end, function()
		bar:SetProgress(p1)
		GlowTo(tip, 0, 0.5, self)
		-- (1.13.0, after its first test: where the bar is, Open all puts it lower on a tall screen)
		local _, _, _, _, by = bar:GetPoint(1)
		self.stars:Burst(0, by or -214, { 0.6 + 0.4 * g[1], 0.6 + 0.4 * g[2], 0.6 + 0.4 * g[3] }, 4, 60, 0.6, 16)
	end, Ease.outCubic, self, 0.25)
end

-- "+25 XP": the experience of a card turned over, falling from it.
function B:XPFloat(c, xp)
	local s = self.frame
	s.xpFloatI = CuratorOctoFull.Mod((s.xpFloatI or 0) , CuratorOctoFull.Length(s.xpFloats)) + 1
	local t = s.xpFloats[s.xpFloatI]
	t:SetText(string.format(L["+%s XP"], ns.Num(xp)))
	-- (much of it, a titanforged card or a fine one: gold)
	if xp >= 100 then
		t:SetTextColor(1, 0.84, 0.36)
	else
		t:SetTextColor(0.8, 0.68, 1)
	end
	-- (under the card, falling; the first row of the cards of a zone: over it, rising)
	local up = c.row == 1
	local x, y0 = c.slotX, up and (c.slotY + c.H / 2 + 12) or (c.slotY - c.H / 2 - 12)
	local dy = up and 22 or -26
	if t.tw then
		ns.CancelTween(t.tw)
	end
	t.tw = ns.Tween(1.7, function(e, raw)
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.frame.fx, "CENTER", x, y0 + dy * e)
		t:SetAlpha((raw < 0.12 and raw / 0.12) or (raw > 0.65 and (1 - raw) / 0.35) or 1)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.outCubic, self)
end

-- The end of a booster: the experience it gave, the emblem of the rank, the bar of the level filling
-- from where it was (a level crossed on the way: a blow of light, a new rank its emblem; once full, the
-- screen of the level).
function B:FillXP()
	local s = self.frame
	local LV = ns.Level
	local x0 = self.xp0
	self.xp0 = nil
	if not (LV and x0) then
		return
	end
	local x1 = LV:XP()
	if x1 <= x0 then
		return
	end
	local bar = s.xpBar
	local function Show(xp)
		local lv, into, need = LV.Of(xp)
		s.xpLevel:SetText(string.format(L["Level %d"], lv))
		bar:SetProgress(need and into / need or 1)
		bar:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
		local r = LV.RankOf(lv)
		if s.xpEmblem.rank ~= r then
			s.xpEmblem:SetRank(r)
		end
		return lv
	end
	local lv0 = Show(x0)
	local last = lv0
	bar:SetAlpha(0)
	bar:Show()
	FadeIn(bar, 0.25, self)
	s.xpEmblem:SetAlpha(0)
	s.xpEmblem:Show()
	FadeIn(s.xpEmblem, 0.25, self)
	s.xpGain:SetText(string.format(L["+%s XP"], ns.Num(x1 - x0)))
	FadeIn(s.xpGain, 0.25, self)
	FadeIn(s.xpLevel, 0.25, self)
	ns.Tween(math.min(1.6, 0.6 + (x1 - x0) / 400), function(e)
		local lv = Show(x0 + (x1 - x0) * e)
		if lv > last then
			last = lv
			self:LevelUpFx(lv)
		end
	end, function()
		Show(x1)
		-- the levels gained: their screen (the toast when the scene closes before it; in the small
		-- window, its toast: the screen of a level would cover the world)
		local lv1 = LV.Of(x1)
		if lv1 > lv0 and ns.LevelUp then
			ns.Delay(0.55, function()
				self.pendingLevel = nil
				if self:Small() and ns.Toast and ns.Toast.LevelUp then
					ns.Toast:LevelUp(lv1)
				else
					ns.LevelUp:Play(lv0, lv1)
				end
			end, self)
		end
	end, Ease.outCubic, self, 0.35)
end

-- A level crossed on the bar of the level: a blow of light on it, the sound of the experience, a new
-- rank its emblem (the screen of the level comes once the bar is full).
function B:LevelUpFx(level)
	local s = self.frame
	ns.Play(ns.SND.xpTick)
	s.xpBar:Flash(1)
	self:EdgeGlow({ 0.75, 0.55, 1 }, 0.35, 0.8)
	-- (where the bar is: Open all puts it lower on a tall screen)
	local _, _, _, _, xy = s.xpBar:GetPoint(1)
	xy = xy or -240
	self.stars:Burst(0, xy, { 0.85, 0.72, 1 }, 10, 160, 0.9, 20)
	self.particles:Burst(0, xy, { 1, 0.85, 0.5 }, 12, 180, 0.7, 14)
	-- (the level flashes white, then its gold again)
	ns.Tween(0.6, function(e)
		s.xpLevel:SetTextColor(1, 1 - 0.18 * e, 1 - e)
	end, nil, Ease.linear, self)
	-- a new rank: light bursts from its emblem
	local _, rank = ns.Level.RankOf(level)
	if rank.level == level then
		self.stars:Burst(-179, xy, rank.light, 12, 150, 0.8, 18)
	end
end

-- A level gained by a booster whose end was not seen: its toast (when the scene closes, or the next
-- booster begins).
function B:LevelToast()
	local level = self.pendingLevel
	self.pendingLevel = nil
	if level and ns.Toast and ns.Toast.LevelUp then
		ns.Toast:LevelUp(level)
	end
end

function B:Showing()
	return self.frame ~= nil and self.frame:IsShown()
end

function B:Again()
    if self.opts and self.opts.test then return end
	if self.mode == "contract" then
		self.frame:Hide()
		return ns.Album:Open("contract")
	end
	-- (1.14.0, after its second test: back to the desk of the contracts of the cases, UI/CaseContract.lua)
	if self.mode == "caseContract" then
		self.frame:Hide()
		return ns.Album:ShowCaseDesk()
	end
	-- (1.10.0: after a golden booster, the next golden one)
	if self.opts and self.opts.golden then
		if self:Left() <= 0 then
			return
		end
		self.state = "done"
		return ns.Golden:OpenPack()
	end
	if ns.Packs(self.series) <= 0 then
		return
	end
	self.state = "done"
	self:Open(self.series, { from = self.opts and self.opts.from })
end

-------------------------------------------------------------------------------
-- Every frame: the camera, the pack, the cards (idle float, hover, shakes, glows), the motes of
-- light, the rays.
-------------------------------------------------------------------------------
function B:PackTick(dt, t)
	local s, p = self.frame, self.frame.pack
	local idle = self.state == "pack"
	local bob = idle and math.sin(t * 1.8) * 6 or 0
	local ox, oy = 0, 0
	local a = p.shake or 0
	if a > 0 then
		ox, oy = (math.random() - 0.5) * 2 * a, (math.random() - 0.5) * 2 * a
	end
	p.hoverK = (p.hoverK or 0) + ((p.hover and idle and 1 or 0) - (p.hoverK or 0)) * math.min(1, dt * 10)
	local sc = (p.sc or 1) + (p.pulse or 0) + p.hoverK * 0.04
	if math.abs(p:GetScale() - sc) > 0.0005 then
		p:SetScale(sc)
	end
	local sx, sy = p.sx or 1, p.sy or 1
	CuratorOctoFull.SetSize(p, PACK_W * sx, PACK_H * sy)
	if not p.flying then
		p.top:SetHeight(TOP_H * sy)
	end
	p:ClearAllPoints()
	-- (squashed, it stays on the ground)
	p:SetPoint("CENTER", s.stage, "CENTER", ox / sc, (PACK_Y + (p.dy or 0) + bob + oy - (1 - sy) * PACK_H / 2) / sc)
	-- the light of the mouse over the foil
	local spot = p.shine.spot
	p.spotA = (p.spotA or 0) + ((p.hover and idle and 0.3 or 0) - (p.spotA or 0)) * math.min(1, dt * 8)
	if p.spotA > 0.005 then
		local cx, cy = GetCursorPosition()
		local es = CuratorOctoFull.GetEffectiveScale(p)
		local mx, my = p:GetCenter()
		if cx and cy and es and es > 0 and mx and my then
			spot:ClearAllPoints()
			spot:SetPoint("CENTER", p, "CENTER", cx / es - mx, cy / es - my)
		end
		spot:SetAlpha(p.spotA)
	elseif spot:GetAlpha() > 0 then
		spot:SetAlpha(0)
	end
	if idle then
		local target = p.hover and 0.75 or (0.32 + math.sin(t * 2.4) * 0.06)
		p.glow:SetAlpha(p.glow:GetAlpha() + (target - p.glow:GetAlpha()) * math.min(1, dt * 8))
		-- a glint runs over the foil every few seconds, and right away under the mouse
		p.sweep = (p.sweep or 0) + dt
		if p.sweep > SWEEP_EVERY then
			p.sweep = 0
		end
		local u = p.sweep / SWEEP_TIME
		local sheen = p.shine.sheen
		if u <= 1 then
			local d = (-1 + 2 * u) * SWEEP_REACH
			sheen:ClearAllPoints()
			sheen:SetPoint("CENTER", p, "CENTER", d * 0.7071, -d * 0.7071)
			sheen:SetAlpha(math.sin(u * math.pi) * 0.6)
		else
			sheen:SetAlpha(0)
		end
	else
		p.shine.sheen:SetAlpha(0)
	end
end

-- A card face down: the light of the best ones breathes and motes rise from it; the reflection
-- follows the mouse over the card under it.
function B:CardTick(c, i, t, dt)
	local r = c.pick and c.pick.card.rarity or 1
	local b = c.back
	local ray = c.rays
	local want = 0
	if r >= 4 and not c.revealed and not c.busy then
		want = AURA_RAYS[math.min(6, r)] * (0.75 + 0.25 * math.sin(t * 1.9 + i))
	end
	c.rayA = (c.rayA or 0) + (want - (c.rayA or 0)) * math.min(1, dt * 6)
	if c.rayA > 0.005 then
		local col = ns.RARITY[r].glow
		ray:ClearAllPoints()
		ray:SetPoint("CENTER", self.frame.behind, "CENTER", c.slotX, c.slotY + (c.lift or 0))
		ray:SetVertexColor(col[1], col[2], col[3])
		CuratorOctoFull.SetRotation(ray, t * 0.35 * (CuratorOctoFull.Mod(i , 2) == 0 and 1 or -1))
		ray:SetAlpha(c.rayA)
	elseif ray:GetAlpha() > 0 then
		ray:SetAlpha(0)
	end
	local target = (c.hoverOn and not c.busy and not c.revealed) and 0.42 or 0
	c.sheenA = (c.sheenA or 0) + (target - (c.sheenA or 0)) * math.min(1, dt * 10)
	if c.hoverOn and not c.busy then
		local cx, cy = GetCursorPosition()
		local es = CuratorOctoFull.GetEffectiveScale(c)
		local mx, my = c:GetCenter()
		if cx and cy and es and es > 0 and mx and my then
			c.lightX, c.lightY = (cx / es - mx) * 0.8, (cy / es - my) * 0.8
		end
	end
	if c.sheenA > 0.01 then
		c:BackLight(c.lightX or 0, c.lightY or 0, c.sheenA)
	elseif b.sheen:GetAlpha() > 0 then
		b.sheen:SetAlpha(0)
	end
	if c.hallowBack then
		self:HallowFlicker(c, i, t)
	end
	if r >= 4 and not c.busy and not c.revealed and not c.hoverOn then
		local base = AURA_GLOW[math.min(6, r)]
		local breath = 1 + math.sin(t * 2.4 + i * 1.7)
		if not b.glow.tw then
			b.glow:SetAlpha(math.min(1, base * 1.6 * (0.8 + 0.4 * breath)))
		end
		if not b.core.tw then
			b.core:SetAlpha(math.min(1, base * 1.5 * (0.7 + 0.5 * breath)))
		end
		if not c.glow.tw then
			c.glow:SetAlpha(math.min(1, base * (1 + 0.5 * breath)))
		end
	end
	if r >= 5 and not c.busy and not c.revealed then
		-- (the legendary and mythic ones jolt now and then: they want out)
		c.joltT = (c.joltT or 1) - dt
		if c.joltT <= 0 then
			c.joltT = (r >= 6 and 1.2 or 1.7) + math.random() * 0.8
			ns.Tween(0.28, function(e)
				if not c.busy then
					c.shake = 2.6 * (1 - e)
				end
			end, function()
				if not c.busy then
					c.shake = 0
				end
			end, Ease.linear, self)
			if not c.glow.tw then
				c.glow:SetAlpha(math.min(1, c.glow:GetAlpha() + 0.35))
			end
		end
	end
	if r >= 4 and not c.busy then
		c.moteT = (c.moteT or 0) - dt
		if c.moteT <= 0 then
			c.moteT = AURA[math.min(6, r)] * (c.revealed and 2 or 1) * (0.7 + math.random() * 0.6)
			local col = ns.RARITY[r].glow
			local y = c.slotY + (c.lift or 0)
			self.motes:Rise(c.slotX - c.W * 0.45, c.slotX + c.W * 0.45, y - c.H * 0.3, col, 1, 160 + 40 * (r - 4), 1.7, 15 + 2 * (r - 4))
		end
	end
	-- a titanforged card waiting face down (1.11.0): motes of every colour rise from it, its light goes slowly
	-- through the colours of the prism
	local pc = B.PRISM
	if pc and c.pick.look == "titan" and not c.revealed and not c.busy then
		c.prismT = (c.prismT or 0) - dt
		if c.prismT <= 0 then
			c.prismT = 0.28 + math.random() * 0.22
			local y = c.slotY + (c.lift or 0)
			self.motes:Rise(c.slotX - c.W * 0.5, c.slotX + c.W * 0.5, y - c.H * 0.45, pc[math.random(CuratorOctoFull.Length(pc))], 1, 150 + 50 * math.random(), 1.8, 13)
		end
		if r < 4 and not c.glow.tw and not c.hoverOn then
			local h = CuratorOctoFull.Mod((t * 0.12 + i * 0.17) , 1) * CuratorOctoFull.Length(pc)
			local a, b = pc[CuratorOctoFull.Mod(math.floor(h) , CuratorOctoFull.Length(pc)) + 1], pc[CuratorOctoFull.Mod((math.floor(h) + 1) , CuratorOctoFull.Length(pc)) + 1]
			local f = h - math.floor(h)
			c.glow:SetVertexColor(a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f)
			c.glow:SetAlpha(0.22 + 0.12 * math.sin(t * 2.2 + i))
		end
	end
	-- (1.12.0, as in Curator Midnight) a corrupted card waiting face down: the motes of the Void rise from it, its light
	-- goes from the violet to the blue of them
	if c.pick and c.pick.look == "corrupt" and not c.revealed and not c.busy then
		c.voidT = (c.voidT or 0) - dt
		if c.voidT <= 0 then
			c.voidT = 0.3 + math.random() * 0.25
			local y = c.slotY + (c.lift or 0)
			self.motes:Rise(c.slotX - c.W * 0.5, c.slotX + c.W * 0.5, y - c.H * 0.45, (math.random() < 0.5) and VOID_BLUE or VOID_VIOLET, 1, 150 + 50 * math.random(), 1.8, 13)
		end
		if r < 4 and not c.glow.tw and not c.hoverOn then
			local f = 0.5 + 0.5 * math.sin(t * 0.9 + i)
			c.glow:SetVertexColor(VOID_VIOLET[1] + (VOID_BLUE[1] - VOID_VIOLET[1]) * f, VOID_VIOLET[2] + (VOID_BLUE[2] - VOID_VIOLET[2]) * f, 1)
			c.glow:SetAlpha(0.2 + 0.12 * math.sin(t * 2.2 + i))
		end
	end
end

function B:Tick(elapsed)
	local dt = elapsed * (self.timeK or 1)
	self.t = (self.t or 0) + dt
	local t = self.t
	local s = self.frame
	-- the place behind follows the mouse a little, as far things do
	local mx, my = GetCursorPosition()
	local es, w, h = CuratorOctoFull.GetEffectiveScale(s), s:GetWidth(), s:GetHeight()
	if mx and my and es and es > 0 and w and w > 0 and h and h > 0 then
		local k = math.min(1, elapsed * 3)
		-- (from the corner of the scene: the small window is not in the corner of the screen)
		local x0, y0 = s:GetLeft() or 0, s:GetBottom() or 0
		local u = math.max(0, math.min(1, (mx / es - x0) / w))
		local v = math.max(0, math.min(1, (my / es - y0) / h))
		self.parX = (self.parX or 0) + ((u - 0.5) * 22 - (self.parX or 0)) * k
		self.parY = (self.parY or 0) + ((v - 0.5) * 12 - (self.parY or 0)) * k
	end
	-- the camera, and its shake
	local cam = self.cam
	if (self.shakeT or 0) > 0 then
		self.shakeT = self.shakeT - dt
		local a = self.shakeA * math.max(0, self.shakeT / self.shakeD)
		cam.sx, cam.sy = (math.random() - 0.5) * 2 * a, (math.random() - 0.5) * 2 * a
	else
		cam.sx, cam.sy = 0, 0
	end
	self:CamApply()
	if s.pack:IsShown() and self.mode ~= "contract" then
		self:PackTick(dt, t)
	end
	if self.lair then
		self:LairTick(dt, t, elapsed)
	end
	-- motes of light rise slowly in the light of the place (a dungeon has its own air)
	self.moteT = (self.moteT or 0) - dt
	if not self.lair and self.moteT <= 0 and self.motes:Free() > 30 then
		self.moteT = 0.16 + math.random() * 0.12
		local g = self.glow or WARM
		-- (across the screen; in the small window, across it)
		local x = (math.random() * 2 - 1) * (self:Small() and CANVAS_W / 2 or 880)
		self.motes:Rise(x, x, -560, { 0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3] }, 1, 320 + math.random() * 320, 5, 6 + math.random() * 6)
	end
	for i, c in ipairs(self.cards) do
		if c:IsShown() and c.free then
			local bob = c.revealed and 0 or math.sin(t * 1.7 + i * 1.3) * 2.5
			local sx, sy = 0, 0
			local k = c.shake or 0
			if k > 0 then
				sx, sy = (math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k
			end
			local scale = math.max(0.5, 1 + (c.pop or 0))
			if math.abs(c:GetScale() - scale) > 0.0005 then
				c:SetScale(scale)
			end
			c:ClearAllPoints()
			c:SetPoint("CENTER", s.stage, "CENTER", (c.slotX + sx) / scale, (c.slotY + (c.lift or 0) + bob + sy) / scale)
			if c.revealed and (c.glowBase or 0) > 0 and not c.glow.tw then
				c.glow:SetAlpha(c.glowBase + math.sin(t * 2.6 + i) * 0.08)
			end
			if c.pick then
				self:CardTick(c, i, t, dt)
			end
		end
		if c:IsShown() then
			c:Tick(t)
		end
	end
	-- (1.13.0, after its first test) the cards of Open all
	if self.batch and self.BatchTick then
		self:BatchTick(dt, t)
	end
	-- the wheels of rays follow the card they shine behind
	if s.rays.on then
		local c = s.rays.card
		if c then
			local y = c.slotY + (c.lift or 0)
			s.rays:ClearAllPoints()
			s.rays:SetPoint("CENTER", s.behind, "CENTER", c.slotX, y)
			s.rays2:ClearAllPoints()
			s.rays2:SetPoint("CENTER", s.behind, "CENTER", c.slotX, y)
		end
		CuratorOctoFull.SetRotation(s.rays, t * 0.18)
		if s.rays2:GetAlpha() > 0 then
			CuratorOctoFull.SetRotation(s.rays2, -t * 0.11)
		end
	end
	if s.circle.on then
		CuratorOctoFull.SetRotation(s.circle, t * (s.circle.spin or 0.7))
	end
	if self.prism then
		self:ForgeTick(dt)
	end
end

function B:Cleanup()
	-- (1.6.0: a booster held for an omen, the scene closed before the choice: kept as it was drawn)
	if self.picks and self.picks.hold then
		C:KeepHeld(self.picks)
	end
	self.omen, self.redrawing = nil, nil
	if self.CloseInspect then
		self:CloseInspect(true)
	end
	ns.CancelOwner(self)
	self:LevelToast()
	self.autoAll = nil
	self.footBanner, self.footPending = false, 0
	if self.freeze then
		ns.CancelOwner(self.freeze)
		self:StopLoops()
		ns.CancelOwner(self.timers)
	end
	for o in pairs(self.owners or {}) do
		ns.CancelOwner(o)
	end
	if self.owners then
		CuratorOctoFull.Wipe(self.owners)
	end
	if self.particles then
		self:SetTime(1)
	end
	-- (not an entrance played again from the album or the chat: it is not the scene's)
	local cin = ns.Cinematic
	if cin and not (cin.playing and cin.opts and cin.opts.full) then
		cin:Stop()
	end
	if self.LairStop then
		self:LairStop()
	end
	if self.BatchReset then
		self:BatchReset()
	end
	-- (closed while the titans forge a card: their bands, their disc, the words of the scene)
	if self.ForgeClear then
		self:ForgeClear()
	end
	if self.particles then
		self.particles:Clear()
		self.stars:Clear()
		self.streaks:Clear()
		self.puffs:Clear()
		self.motes:Clear()
	end
	GameTooltip:Hide()
	self.state = nil
end

-- what the contract scene (UI/Contract.lua) shares with the booster scene
B.U = {
	Text = Text, Tex = Tex, FadeIn = FadeIn, GlowTo = GlowTo, Mix = Mix, SLOT_Y = SLOT_Y,
	PACK_Y = PACK_Y, PACK_W = PACK_W, PACK_H = PACK_H, TOP_H = TOP_H, WHITE = WHITE, WARM = WARM, DUST = DUST,
	-- (1.13.0, after its first test: and with the scene of Open all, UI/OpenAll.lua)
	At = At, Struck = Struck, TELL = TELL, WAVES = WAVES, RAINBOW = RAINBOW, AURA_GLOW = AURA_GLOW, AURA_RAYS = AURA_RAYS,
	DARK = DARK, VOID_SMOKE = VOID_SMOKE, VOID_BLUE = VOID_BLUE, VOID_VIOLET = VOID_VIOLET,
}
