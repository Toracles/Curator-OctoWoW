local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

local A = {}
ns.Album = A
-- the owner of the animations of the rewards claimed (the pages of the quests and of the achievements)
A.CLAIMS = {}

-- The album is a window of the game: its portrait, its title and its close button, its tabs on its
-- right edge (as the collections). Under the title, the album shown and its progress; then the page,
-- on the ground of the collections, with the cards and the arrows of its pages; under the page, a
-- bar of buttons.
local COLS, ROWS = 6, 3
local PER_PAGE = COLS * ROWS
local CW, CH = unpack(ns.CARD_SIZES.small)
local GAP_X, GAP_Y = 12, 14
local HEAD = 72      -- the title bar, then the album (name, levels) and its progress
local FOOT = 28      -- the bar of buttons under the page
local PAD = 18       -- inside the page, left and right of the cards
local GRID_TOP = 14
local PAGER = 44     -- the arrows of the pages, at the bottom of the page
local PAGE_W = PAD * 2 + COLS * CW + (COLS - 1) * GAP_X
local PAGE_H = GRID_TOP + ROWS * CH + (ROWS - 1) * GAP_Y + PAGER
local WIDTH = PAGE_W + 10
local HEIGHT = HEAD + PAGE_H + FOOT
local BAR_W = 230
-- guild page: one row per member
local ROW_H, ROWS_PER_PAGE = 66, 7
-- (the contents page, a tab for each kind of album: see below)
local GOLD, DIM = S.GOLD, { 0.62, 0.62, 0.62 }
-- the tabs on the right edge, a page each (the pages of an album, "mine", go with the contents:
-- an album opens from there; the social page is "guild")
local TABS = {
	-- (1.13.0: the inventory, every copy, the boosters and the displays: UI/Inventory.lua; after its first test, the
	-- first tab, where the album opens, on its boosters: the page of the boosters is a part of it, its tab gone)
	{ mode = "inventory", label = "Inventory", icon = "Interface\\Icons\\INV_Misc_Bag_10", fallback = "Interface\\Icons\\INV_Misc_Bag_08" },
	{ mode = "contents", label = "All albums", icon = "Interface\\Icons\\INV_Misc_Book_09" },
	-- (1.13.0, after its first test: the tabs of the social page and of the PvP taken away until they are reworked;
	-- their pages still open from where they are needed: a trade, /curator trade, the PvP of the contents, a
	-- battlemaster, /curator pvp)
	{ mode = "contract", label = "Contracts", icon = "Interface\\Icons\\INV_Scroll_03" },
	{ mode = "ach", label = "Achievements", icon = "Interface\\Icons\\Achievement_General" },
	{ mode = "profile", label = "Profile", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
	-- (1.12.0: the goblet of the quests, its yellow mark, where the game has it; before, a note that looks like
	-- a tablet of stone)
	{ mode = "quests", label = "Quests", icon = "Interface\\Icons\\Achievement_Quests_Completed_06", fallback = "Interface\\Icons\\INV_Misc_Note_06" },
	-- (1.6.0: the talents of the collector, UI/Talents.lua)
	{ mode = "talents", label = "Talents", icon = "Interface\\Icons\\Ability_Marksmanship" },
	-- (1.8.0: the inns, their loyalty card and the travel passport, UI/Inns.lua)
	{ mode = "inns", label = "Inns", icon = "Interface\\Icons\\INV_Drink_04" },
	-- (1.12.0: Hallow's End, while it lasts, UI/HallowPage.lua; 1.14.0, after the test of the cases, his word: out of the
	-- tabs, the discovery of the Paladin Collection Case No. 1 in its place, while it lasts: its quests, its cases, its
	-- achievements, UI/DiscoveryPage.lua)
	{ mode = "discovery", label = "Paladin Collection Case No. 1", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", event = "paladin" },
	-- (1.15.0: the statistics, every rate and what the talents change, UI/Rates.lua)
	{ mode = "rates", label = "Statistics", icon = "Interface\\Icons\\INV_Misc_Dice_02", fallback = "Interface\\Icons\\INV_Misc_Note_01" },
	-- (1.14.0, after its test, his word: the chest of a reroll in the menu; its tab only on a reroll, UI/Reroll.lua)
	{ mode = "chest", label = "Chest", icon = "Interface\\Icons\\INV_Box_02", reroll = true },
}
-- (the page of the boosters: under the tab of the inventory, a part of it; the social page and the PvP: no tab, their
-- name as the title of the window, the PvP under the tab of the albums, where its albums are)
local TAB_OF = { inventory = 1, boosters = 1, contents = 2, member = 2, mine = 2, contract = 3, ach = 4, profile = 5, quests = 6, talents = 7, inns = 8,
	discovery = 9, rates = 10, chest = 11 }
A.TAB_OF = TAB_OF
A.TABS = TABS
local PAGE_LABEL = { guild = "Social", pvp = "PvP", cases = "My collection" }
-- (1.14.0, after its first test: the album of a collection of the cases, UI/CaseAlbum.lua, under the tab of the albums)
local LIT_OF = { pvp = TAB_OF.contents, cases = TAB_OF.contents }
-- the pages of another player's collection: their albums, their achievements, their profile. (1.14.3, his word of
-- November 6: « remplacer "tous les albums" par "l'inventaire" ("tout") »: their inventory first, where their collection
-- opens, in the place of the tab of their albums; their albums a button away, under their inventory, UI/Inventory.lua)
local THEIRS = { inventory = true, contents = true, ach = true, profile = true }
local THEIRS_TAB = { inventory = true, ach = true, profile = true }
-- (1.12.0) the finishes of the filter, left of the gems of the rarities: their copies in an entry, their
-- gem (the bolt in a blue stone, the sea-green stone in a ring of gold: the gems of the ranks in their
-- colours), their colour
local FINISHES = {
	{ key = "shiny", field = "s", gem = "Gem7", label = "Thunderforged cards", colour = { 0.45, 0.78, 1 } },
	{ key = "holo", field = "h", gem = "Gem8", label = "Titanforged cards", colour = { 1, 0.8, 0.42 } },
	-- (the albums of an event: their corrupted cards, and no forged one)
	{ key = "corrupt", field = "c", gem = "GemCorrupt", label = "Corrupted cards", colour = { 0.78, 0.45, 1 }, event = true },
}
local FINISH_OF = {}
for _, fin in ipairs(FINISHES) do
	FINISH_OF[fin.key] = fin
end

-- The name the client gives a map (continents, capitals).
local function MapName(id, fallback)
	if C_Map and C_Map.GetMapInfo then
		local ok, info = pcall(C_Map.GetMapInfo, id)
		if ok and info and type(info.name) == "string" and info.name ~= "" then
			return info.name
		end
	end
	return fallback
end

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- A text of a given size in the font of the game, with its shadow.
local function Text(parent, size, flags, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	ns.SetFont(fs, size, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 1)
	return fs
end

-- what the contract and achievement pages (UI/Contract.lua, UI/Achievements.lua) share with the album
A.U = {
	Text = Text, GOLD = GOLD, DIM = DIM, Hex = Hex, MapName = MapName,
	PAGE_W = PAGE_W, PAGE_H = PAGE_H, PAGER = PAGER, WIDTH = WIDTH, HEIGHT = HEIGHT, HEAD = HEAD, FOOT = FOOT,
	BAR_W = BAR_W, CW = CW, CH = CH,
}

function A:Build()
	if self.frame then
		return
	end
	local f = S.Window("CuratorAlbum", WIDTH, HEIGHT)
	f:SetPoint("CENTER", 0, 10)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	tinsert(UISpecialFrames, "CuratorAlbum")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
		A:Hide()
	end)
	-- the title bar moves the window
	f.drag = S.DragBar(f, 22)

	-- the tabs, on the right edge
	f.tabs = {}
	for i, t in ipairs(TABS) do
		-- (an icon the game may not have: the one before it)
		local i, t = i, t; local icon = t.icon
		if t.fallback and GetFileIDFromPath and not GetFileIDFromPath(icon) then
			icon = t.fallback
		end
		local tab = S.SideTab(f, icon, L[t.label], function()
			A:TabClick(t.mode)
		end)
		tab.mode = t.mode
		f.tabs[i] = tab
	end

	-- the album: its name between the arrows that turn to the previous and next album, its levels
	-- under it
	f.sPrev = S.Arrow(f, -1, 26)
	f.sPrev:SetPoint("TOPLEFT", 60, -25)
	CuratorOctoFull.SetScript(f.sPrev, "OnClick", function()
		A:StepSeries(-1)
	end)
	f.title = S.Text(f, "GameFontNormalHuge", "LEFT")
	CuratorOctoFull.SetWordWrap(f.title, false)
	f.sNext = S.Arrow(f, 1, 26)
	f.sNext:SetPoint("LEFT", f.title, "RIGHT", 2, 0)
	CuratorOctoFull.SetScript(f.sNext, "OnClick", function()
		A:StepSeries(1)
	end)
	f.sub = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.sub:SetPoint("TOPLEFT", 64, -55)
	f.sub:SetTextColor(0.8, 0.8, 0.8)

	-- its progress, in a bar of the game; a click on it shows only the cards found (a second
	-- click, all of them)
	local bar = S.Bar(f, BAR_W, "green")
	bar:SetPoint("RIGHT", f, "TOPRIGHT", -16, -37)
	bar.hit = CreateFrame("Button", nil, bar)
	bar.hit:SetAllPoints()
	CuratorOctoFull.SetScript(bar.hit, "OnClick", function()
		A:ToggleFound()
	end)
	CuratorOctoFull.SetScript(bar.hit, "OnEnter", function()
		A:BarTooltip(bar)
	end)
	CuratorOctoFull.SetScript(bar.hit, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.bar = bar

	-- rarity counters: a click on one shows only the cards of that rarity, a second click all of them
	f.counts = {}
	for r = CuratorOctoFull.Length(ns.RARITY), 1, -1 do
		local r = r; local b = CreateFrame("Button", nil, f)
		CuratorOctoFull.SetSize(b, 40, 16)
		b.rarity = r
		local c = ns.RARITY[r].frame
		b.mark = b:CreateTexture(nil, "BACKGROUND")
		b.mark:SetTexture(MEDIA .. "Glow")
		b.mark:SetBlendMode("ADD")
		b.mark:SetPoint("TOPLEFT", -14, 9)
		b.mark:SetPoint("BOTTOMRIGHT", 14, -9)
		b.mark:SetVertexColor(c[1], c[2], c[3])
		b.mark:SetAlpha(0.45)
		b.mark:Hide()
		b.gem = b:CreateTexture(nil, "ARTWORK")
		b.gem:SetTexture(MEDIA .. "Gem" .. r)
		CuratorOctoFull.SetSize(b.gem, 15, 15)
		b.gem:SetPoint("LEFT")
		b.text = S.Text(b, "GameFontHighlightSmall", "LEFT")
		b.text:SetPoint("LEFT", b.gem, "RIGHT", 2, 0)
		b.line = b:CreateTexture(nil, "ARTWORK")
		b.line:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 1)
		b.line:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, 1)
		b.line:SetHeight(1)
		CuratorOctoFull.ColorTexture(b.line, c[1], c[2], c[3], 0.9)
		b.line:Hide()
		if r == CuratorOctoFull.Length(ns.RARITY) then
			b:SetPoint("RIGHT", f, "TOPRIGHT", -16, -61)
		else
			b:SetPoint("RIGHT", f.counts[r + 1], "LEFT", -8, 0)
		end
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetFilter(r)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:CountTooltip(self)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		f.counts[r] = b
	end

	-- (1.12.0) the finishes, left of the gems past a thin rule: a click on one shows only the cards
	-- found in that finish (and in that look), a second click all of them
	f.fins = {}
	for i, fin in ipairs(FINISHES) do
		local i, fin = i, fin; local b = CreateFrame("Button", nil, f)
		CuratorOctoFull.SetSize(b, 34, 16)
		b.finish = fin.key
		local c = fin.colour
		b.mark = b:CreateTexture(nil, "BACKGROUND")
		b.mark:SetTexture(MEDIA .. "Glow")
		b.mark:SetBlendMode("ADD")
		b.mark:SetPoint("TOPLEFT", -14, 9)
		b.mark:SetPoint("BOTTOMRIGHT", 14, -9)
		b.mark:SetVertexColor(c[1], c[2], c[3])
		b.mark:SetAlpha(0.45)
		b.mark:Hide()
		b.gem = b:CreateTexture(nil, "ARTWORK")
		b.gem:SetTexture(MEDIA .. fin.gem)
		CuratorOctoFull.SetSize(b.gem, 15, 15)
		b.gem:SetPoint("LEFT")
		b.text = S.Text(b, "GameFontHighlightSmall", "LEFT")
		b.text:SetPoint("LEFT", b.gem, "RIGHT", 2, 0)
		b.line = b:CreateTexture(nil, "ARTWORK")
		b.line:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 1)
		b.line:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, 1)
		b.line:SetHeight(1)
		CuratorOctoFull.ColorTexture(b.line, c[1], c[2], c[3], 0.9)
		b.line:Hide()
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetFinish(fin.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:FinishTooltip(self)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		b:Hide()
		f.fins[i] = b
	end
	f.finRule = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.finRule, 1, 14)
	CuratorOctoFull.ColorTexture(f.finRule, GOLD[1], GOLD[2], GOLD[3], 0.35)
	f.finRule:Hide()

	-- the page: the ground of the collections
	local body = S.Background(f)
	body:SetPoint("TOPLEFT", 4, -HEAD)
	body:SetPoint("BOTTOMRIGHT", -6, FOOT)
	f.body = body

	-- grid
	f.slots = {}
	for i = 1, PER_PAGE do
		local i = i; local c = ns.NewCard(body, "small")
		local col, row = CuratorOctoFull.Mod((i - 1) , COLS), math.floor((i - 1) / COLS)
		c.bx, c.by = PAD + col * (CW + GAP_X), -GRID_TOP - row * (CH + GAP_Y)
		c.col = col
		c.lift, c.dx, c.dy = 1, 0, 0
		A:PlaceSlot(c)
		c.shadow:SetAlpha(0.6)
		-- a card not found yet is engraved into the page
		local eg = CreateFrame("Frame", nil, c)
		eg:SetAllPoints()
		eg:SetFrameLevel(c:GetFrameLevel() + 9)
		eg.tex = eg:CreateTexture(nil, "OVERLAY")
		eg.tex:SetTexture(MEDIA .. "Engrave")
		eg.tex:SetPoint("TOPLEFT", -1, 1)
		eg.tex:SetPoint("BOTTOMRIGHT", 1, -1)
		eg:Hide()
		c.engrave = eg
		-- the copies it has to exchange: a seal of wax with their number
		local sp = CreateFrame("Frame", nil, c)
		CuratorOctoFull.SetSize(sp, 24, 24)
		sp:SetPoint("CENTER", c, "BOTTOMRIGHT", -9, 13)
		sp:SetFrameLevel(c:GetFrameLevel() + 9)
		sp.tex = sp:CreateTexture(nil, "ARTWORK")
		sp.tex:SetAllPoints()
		sp.tex:SetTexture(MEDIA .. "Seal")
		sp.text = sp:CreateFontString(nil, "OVERLAY")
		ns.SetFont(sp.text, 10, "OUTLINE")
		sp.text:SetPoint("CENTER", 0.5, 0)
		sp.text:SetTextColor(1, 0.96, 0.86)
		sp:Hide()
		c.spare = sp
		-- (1.5.0) copies that came in a trade and wait (the days of the quarantine): an hourglass
		local wt = CreateFrame("Frame", nil, c)
		CuratorOctoFull.SetSize(wt, 22, 22)
		wt:SetPoint("CENTER", c, "BOTTOMLEFT", 12, 14)
		wt:SetFrameLevel(c:GetFrameLevel() + 9)
		wt.tex = wt:CreateTexture(nil, "ARTWORK")
		wt.tex:SetAllPoints()
		wt.tex:SetTexture(MEDIA .. "Hourglass")
		wt:Hide()
		c.wait = wt
		-- a card looked for: mine (missing), or one of mine to spare that someone looks for
		local sk = CreateFrame("Frame", nil, c)
		CuratorOctoFull.SetSize(sk, 24, 24)
		sk:SetPoint("CENTER", c, "TOPRIGHT", -14, -42)
		sk:SetFrameLevel(c:GetFrameLevel() + 10)
		sk.tex = sk:CreateTexture(nil, "OVERLAY")
		sk.tex:SetAllPoints()
		sk.tex:SetTexture(MEDIA .. "Seek")
		sk:Hide()
		c.seek = sk
		CuratorOctoFull.SetScript(c, "OnEnter", function(self)
			A:SlotEnter(self)
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function(self)
			A:SlotLeave(self)
		end)
		CuratorOctoFull.SetScript(c, "OnClick", function(self, button)
			A:SlotClick(self, button)
		end)
		f.slots[i] = c
	end
	-- a light that passes over the page when it turns, under the cards, kept inside the page (1.1.1: it
	-- went over the edges of the window)
	local clip = CreateFrame("Frame", nil, body)
	clip:SetAllPoints()
	if clip.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(clip, true)
	end
	clip:SetFrameLevel(body:GetFrameLevel())
	local lit = CreateFrame("Frame", nil, clip)
	lit:SetAllPoints()
	lit:SetFrameLevel(body:GetFrameLevel())
	f.sweep = lit:CreateTexture(nil, "OVERLAY", nil, 6)
	f.sweep:SetTexture(MEDIA .. "Sheen")
	f.sweep:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.sweep, 420, 840)
	f.sweep:SetVertexColor(1, 0.92, 0.75)
	f.sweep:SetAlpha(0)
	-- an album complete: its frame of gold, its seal, its bar of gold
	f.gold = CreateFrame("Frame", nil, body)
	f.gold:SetAllPoints()
	f.gold:SetFrameLevel(body:GetFrameLevel() + 24)
	f.gold.edge = f.gold:CreateTexture(nil, "OVERLAY")
	f.gold.edge:SetTexture(MEDIA .. "Edge")
	f.gold.edge:SetBlendMode("ADD")
	f.gold.edge:SetPoint("TOPLEFT", 2, -2)
	f.gold.edge:SetPoint("BOTTOMRIGHT", -2, 2)
	f.gold.edge:SetVertexColor(1, 0.76, 0.3)
	f.gold.edge:SetAlpha(0.32)
	f.gold.corners = {}
	for k, c in ipairs({ { "TOPLEFT", 0, 1, 0, 1, 1, -1 }, { "TOPRIGHT", 1, 0, 0, 1, -1, -1 }, { "BOTTOMLEFT", 0, 1, 1, 0, 1, 1 }, { "BOTTOMRIGHT", 1, 0, 1, 0, -1, 1 } }) do
		local t = f.gold:CreateTexture(nil, "OVERLAY", nil, 1)
		t:SetTexture(MEDIA .. "GoldCorner")
		t:SetTexCoord(c[2], c[3], c[4], c[5])
		CuratorOctoFull.SetSize(t, 70, 70)
		t:SetPoint(c[1], c[6] * 1, c[7] * 1)
		f.gold.corners[k] = t
	end
	f.gold:Hide()
	f.goldBar = ns.Hud.XPBar(f, BAR_W - 30, 16, { 1, 0.74, 0.22 })
	f.goldBar:SetPoint("RIGHT", f, "TOPRIGHT", -16, -37)
	f.goldBar:Hide()
	f.goldSeal = f:CreateTexture(nil, "OVERLAY", nil, 2)
	f.goldSeal:SetTexture(MEDIA .. "AlbumSeal")
	CuratorOctoFull.SetSize(f.goldSeal, 46, 46)
	f.goldSeal:SetPoint("CENTER", f.goldBar, "LEFT", -18, 2)
	f.goldSeal:Hide()

	-- the pages, at the bottom of the page (as under the toys)
	f.pager = S.Pager(body)
	f.pager:SetPoint("BOTTOM", body, "BOTTOM", 36, 8)
	f.pager:SetFrameLevel(body:GetFrameLevel() + 25)
	CuratorOctoFull.SetScript(f.pager.prev, "OnClick", function()
		A:Page(-1)
	end)
	CuratorOctoFull.SetScript(f.pager.next, "OnClick", function()
		A:Page(1)
	end)

	-- the bar of buttons, under the page
	local FOOT_Y = FOOT / 2 + 1
	f.boosters = S.Text(f, "GameFontNormal", "LEFT")
	f.boosters:SetPoint("LEFT", f, "BOTTOMLEFT", 14, FOOT_Y)
	-- the booster bar (the one over the experience bar of the game: UI/BoosterBar.lua)
	local gauge = S.ThinBar(f, 90, 9)
	gauge:SetPoint("LEFT", f.boosters, "RIGHT", 12, 0)
	gauge:EnableMouse(true)
	CuratorOctoFull.SetScript(gauge, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		if ns.BoosterBar then
			ns.BoosterBar:AddLines(GameTooltip)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(gauge, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.gauge = gauge
	-- in a dungeon or a raid: the album that gets the boosters earned there (a menu of the game
	-- chooses another)
	f.farm = S.Dropdown(f, 180)
	f.farm:SetPoint("LEFT", f, "BOTTOMLEFT", 14, FOOT_Y)
	f.farm:SetupMenu(function(_, root)
		A:FarmMenu(root)
	end)
	f.farm:SetTooltip(function(tooltip)
		A:FarmTooltip(tooltip)
	end)
	f.farm:Hide()
	f.open = S.Button(f, L["Open a booster"], 170, 22)
	f.open:SetPoint("BOTTOMRIGHT", -8, 4)
	CuratorOctoFull.SetScript(f.open, "OnClick", function()
		-- (1.14.0, after its test: a reroll opens none; the album stays open, the chat says why: Reroll.lua)
		if ns.Reroll and ns.Reroll:NoOpening() then
			ns.Reroll:SayNoOpening()
			return
		end
		ns.Play(ns.SND.click)
		local s = A.mode ~= "contents" and A:Series() or nil
		A:Hide()
		ns.OpenBooster({ series = s })
	end)
	-- without a booster it says so, and its tooltip tells where they are earned (1.1.1: it was only greyed)
	if f.open.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(f.open, true)
	end
	CuratorOctoFull.SetScript(f.open, "OnEnter", function(self)
		if self:IsEnabled() then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		-- (1.14.0, after its test, his word: a reroll opens none, why)
		if ns.Reroll and ns.Reroll:NoOpening() then
			GameTooltip:AddLine(ns.Reroll:Why(), 1, 0.62, 0.45, true)
			GameTooltip:Show()
			return
		end
		GameTooltip:AddLine(L["No booster to open"], 1, 1, 1)
		GameTooltip:AddLine(L["Fill the booster bar (above your experience bar) where an album lives: defeat creatures that give experience, complete quests and their objectives, discover places, gain levels; in a dungeon or a raid, defeat its creatures and its bosses. Each time it is full: a booster of the album of the place."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.open, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- the copies of the album to exchange: to the contracts
	f.trade = S.Button(f, "", 170, 22)
	f.trade:SetPoint("RIGHT", f.open, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(f.trade, "OnClick", function()
		ns.Play(ns.SND.click)
		A:ContractFor(nil, A:Series())
	end)
	CuratorOctoFull.SetScript(f.trade, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(string.format(L["Copies to exchange: %d"], self.n or 0), 1, 1, 1)
		-- (1.13.0, after its second test: a legendary card at most, the clause of the collection)
		GameTooltip:AddLine(L["Ten copies of a rarity make a card of the next one, up to legendary. Ten copies of a single album give a card that album is missing."], 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine(L["Click: to the contracts"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.trade, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.trade:Hide()
	-- every new card seen at once, on the contents (1.8.0, asked by the players: after many boosters,
	-- the pennants of the new cards had to be seen one card at a time). As wide as its text needs,
	-- in every language; the space is there, between the boosters and the button to open one.
	f.seeAll = S.Button(f, L["Mark all as seen"], 170, 22)
	f.seeAll:SetPoint("RIGHT", f.open, "LEFT", -6, 0)
	f.seeAll:SetWidth(math.max(170, math.min(220, math.ceil(S.Width(f.seeAll.label, 0)) + 28)))
	CuratorOctoFull.SetScript(f.seeAll, "OnClick", function()
		ns.Play(ns.SND.page)
		C:SeeAllFresh()
		GameTooltip:Hide()
		A:Refresh()
	end)
	CuratorOctoFull.SetScript(f.seeAll, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Mark all as seen"], 1, 1, 1)
		GameTooltip:AddLine(string.format(L["New cards: %d"], C:FreshCount()), 1, 0.45, 0.35)
		GameTooltip:AddLine(L["Takes the red pennant off every new card, in all your albums."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.seeAll, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.seeAll:Hide()
	-- back, one step: from an album to the contents, from another player's collection to mine
	-- (A:GoBack; the back button of a mouse does the same)
	f.back = S.Button(f, L["Back"], 110, 22)
	f.back:SetPoint("BOTTOMLEFT", 8, 4)
	CuratorOctoFull.SetScript(f.back, "OnClick", function()
		A:GoBack()
	end)
	f.back:Hide()
	f:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(f, "OnMouseWheel", function(_, delta)
		-- (1.11.0) Ctrl: the size of the album (UI/Options.lua)
		if IsControlKeyDown and IsControlKeyDown() and ns.Options then
			ns.Options:StepScale(delta)
			return
		end
		A:Page(delta > 0 and -1 or 1)
	end)

	self:BuildGuild()
	self:BuildContents()
	self:BuildDetail()

	CuratorOctoFull.SetScript(f, "OnShow", function()
		A:Refresh()
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		A.detail:Hide()
		GameTooltip:Hide()
		-- (the new cards of the page shown were seen; a page turning ends)
		A:SeePage()
		if A.turnTw then
			ns.CancelTween(A.turnTw)
			A.turnTw, A.turnTarget, A.turnDir = nil, nil, nil
		end
		-- next time, the album opens on my own collection, all of it
		A.mode, A.member, A.memberEntries, A.achOrder, A.achPage = "mine", nil, nil, nil, 1
		A.filter, A.found, A.finish = nil, nil, nil
		-- (1.13.0: the contents open again on the tab of the place you are in; the filter of the zones stays)
		A.tocTab, A.tocPages, A.tocReturn = nil, nil, nil
		-- hidden model frames let go of their creatures: set every card again next time
		A.view = nil
		for _, c in ipairs(f.slots) do
			c.sig = nil
			c.lift, c.dx, c.dy = 1, 0, 0
			c:SetAlpha(1)
			A:PlaceSlot(c)
		end
		for _, r in ipairs(f.list.rows) do
			r.card.card = nil
		end
		A:ContractHidden()
		A.returnMode = nil
		A.profPage, A.profSec = nil, nil
		A.boosterPick, A.boostPage = nil, nil
		A.ed, A.who, A.socSec = nil, nil, nil
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		A.t = (A.t or 0) + elapsed
		for _, c in ipairs(f.slots) do
			if c:IsShown() then
				c:Tick(A.t)
			end
		end
	end)
	for _, e in ipairs({ "CHANGED", "GUILD_CHANGED", "GUILD_ALBUM", "PLAYER_INFO", "ACH_CHANGED", "FARM_CHANGED", "PLACE_CHANGED", "DAILY_LIMIT",
		"SHOWCASE_CHANGED", "HISTORY_CHANGED" }) do
		local _, e = _, e; ns.On(e, function()
			if f:IsShown() then
				if A:ClaimsPage() then
					A:QuestsChanged()
				else
					A:Refresh()
				end
			end
		end)
	end
	-- the quests move with each creature defeated: only their page (not while rewards land on it);
	-- the level, their page and the profile; the rewards waiting, the badge of their tab
	ns.On("QUESTS_CHANGED", function()
		if f:IsShown() and A.mode == "quests" then
			A:QuestsChanged()
		end
	end)
	for _, e in ipairs({ "XP_GAINED", "CHOICE_CHANGED", "CLAIMS_CHANGED" }) do
		local _, e = _, e; ns.On(e, function()
			if not f:IsShown() then
				return
			end
			if A:ClaimsPage() then
				A:QuestsChanged()
			elseif A.mode == "boosters" then
				A:Refresh()
			else
				A:PaintBadges()
			end
		end)
	end
	-- each creature defeated moves the gauge: only the footer changes
	ns.On("PROGRESS", function()
		if not f:IsShown() then
			return
		end
		if A.mode == "mine" then
			A:RefreshFooter(true)
		elseif A.mode == "contents" and not A.member and f.farm:IsShown() then
			A:PaintGauge(ns.Rewards:FarmSeries())
		elseif A.mode == "boosters" and f.boost then
			A:PaintFeaturedGauge()
		elseif A.mode == "profile" and not A.member and f.prof then
			A:PaintGauges()
		end
	end)
	self.page, self.listPage, self.mode = 1, 1, "mine"
	-- the button (i) of the guided tour, in the corner (UI/Tour.lua)
	if ns.Tour then
		ns.Tour:Attach(f)
	end
	-- the back button of a mouse (its fourth one), wherever it is over the album
	self:HookBack(f)
end

-- The back button of a mouse over a frame of the album and over all those in it that take the clicks:
-- back, one step. Only those: a script of the mouse given to a frame makes it take the clicks, and the
-- frames over the cards (their creatures, their frames, their finishes) and over the pages would then
-- stop them from reaching what is under them (1.1.1: nothing could be clicked in the album any more).
local function MouseBack(_, button)
	if button == "Button4" then
		A:GoBack()
	end
end

-- (a frame that takes the clicks of the mouse)
local function TakesClicks(frame)
	for _, getter in ipairs({ "IsMouseClickEnabled", "IsMouseEnabled" }) do
		if frame[getter] then
			local ok, on = pcall(frame[getter], frame)
			if ok and type(on) == "boolean" then
				return on
			end
		end
	end
	return false
end

function A:HookBack(frame)
	if frame.curatorBack then
		return
	end
	frame.curatorBack = true
	if TakesClicks(frame) then
		pcall(CuratorOctoFull.HookScript, frame, "OnMouseUp", MouseBack)
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		self:HookBack(child)
	end
end

-- Back, at the foot of the window: on another player's pages, and on the pages of my albums (1.1.1); the boosters and
-- their gauge (in a dungeon, its menu) come after it (1.13.0: and on the PvP page opened from the contents). (1 November,
-- his word: « J'aimerai un "Retour" pour voir la page précédente pour tout »: and whenever a card is shown big, on any
-- page; a click beside it no longer closes it)
function A:PaintBack()
	local f = self.frame
	if not (f and f.back) then
		return
	end
	local back = self.member ~= nil or self.mode == "mine" or ((self.mode == "pvp" or self.mode == "cases") and self.tocReturn == true)
		or (self.detail ~= nil and self.detail:IsShown())
	CuratorOctoFull.SetShown(f.back, back and true or false)
	f.boosters:ClearAllPoints()
	f.farm:ClearAllPoints()
	if back then
		f.boosters:SetPoint("LEFT", f.back, "RIGHT", 12, 0)
		f.farm:SetPoint("LEFT", f.back, "RIGHT", 8, 0)
	else
		f.boosters:SetPoint("LEFT", f, "BOTTOMLEFT", 14, FOOT / 2 + 1)
		f.farm:SetPoint("LEFT", f, "BOTTOMLEFT", 14, FOOT / 2 + 1)
	end
end

-- Back, one step (the button of the page, the back button of a mouse): the card shown big closes; an
-- album goes back to the contents (1.13.0: on the tab and the page of that album; the PvP page opened from
-- the contents, back to its tab); another player's album back to their albums, their other pages back to
-- mine. Elsewhere it does nothing (a trade being written stays as it is). true if it went back.
function A:GoBack()
	local f = self.frame
	if not (f and f:IsShown()) then
		return false
	end
	local d = self.detail
	if d and d:IsShown() then
		self:HideDetail()
		ns.Play(ns.SND.page)
		return true
	end
	if self.member then
		ns.Play(ns.SND.page)
		-- (1.14.3: their album back to where it opened from, their inventory or their albums; their albums back to their
		-- inventory)
		if self.mode == "member" then
			self:SetMemberMode(self.memberBack or "inventory")
		elseif self.mode == "contents" then
			self:SetMemberMode("inventory")
		else
			self:SetMode(self.returnMode or "contents")
		end
		return true
	end
	if self.mode == "mine" then
		ns.Play(ns.SND.page)
		local s = self:Series()
		if s then
			self:TocAt(s)
		end
		self:SetMode("contents")
		return true
	end
	if self.mode == "pvp" and self.tocReturn then
		ns.Play(ns.SND.page)
		self.tocTab = "pvp"
		self:SetMode("contents")
		return true
	end
	-- (1.14.0, after its first test: the album of a collection of the cases opened from the contents, back to its tab)
	if self.mode == "cases" and self.tocReturn then
		ns.Play(ns.SND.page)
		self.tocTab = "cases"
		self:SetMode("contents")
		return true
	end
	return false
end

function A:Series()
	self.series = self.series or ns.CurrentSeries()
	return self.series
end

-- Albums in the order of the contents page: the zones of the Eastern Kingdoms, then of
-- Kalimdor (by level), then the islands of no continent (Zephras), then the dungeons, then the raids
-- (in their order in the game).
local order
function A:Order()
	if not order then
		order = {}
		for _, s in ipairs(ns.Series) do
			order[CuratorOctoFull.Length(order) + 1] = s
		end
		local rank = function(s)
			-- (1.12.0: the albums of the events last; 1.13.0: the limited editions with them)
			return ((s.event or s.limited) and 6) or (s.raid and 5) or (s.dungeon and 4) or (s.cont == "K" and 2) or (s.cont == "EK" and 1) or 3
		end
		table.sort(order, function(a, b)
			if rank(a) ~= rank(b) then
				return rank(a) < rank(b)
			end
			if (a.raid or 0) ~= (b.raid or 0) then
				return (a.raid or 0) < (b.raid or 0)
			end
			if a.levels[1] ~= b.levels[1] then
				return a.levels[1] < b.levels[1]
			end
			if a.levels[2] ~= b.levels[2] then
				return a.levels[2] < b.levels[2]
			end
			return a.key < b.key
		end)
		for i, s in ipairs(order) do
			s.order = i
		end
	end
	return order
end

-- The previous or next album (with the guild page or a member's album, theirs too).
function A:StepSeries(delta)
	if self.mode == "contract" then
		return self:StepContractAlbum(delta)
	end
	local list = self:Order()
	local cur = self:Series()
	local i = CuratorOctoFull.Mod(((cur.order or 1) - 1 + delta) , CuratorOctoFull.Length(list)) + 1
	ns.Play(ns.SND.page)
	self:HideDetail()
	if self.mode == "member" then
		return self:ShowMember(self.member, list[i])
	end
	self.series, self.page, self.listPage = list[i], 1, 1
	self:Refresh()
end

-- The entries shown: mine, or those of the guild member whose album is open.
function A:EntryOf(card)
	if self.mode == "member" then
		local e = self.memberEntries and self.memberEntries[card.key]
		return e
	end
	return C:Entry(card)
end

-- A click on a tab: one of my pages, or with another player's collection, theirs.
function A:TabClick(mode)
	if self.member then
		if THEIRS[mode] then
			self:SetMemberMode(mode)
		end
		return
	end
	self:SetMode(mode)
end

-- (1.12.0) Where the tabs on the right edge start, and their scale: 60 under the top of the window as before;
-- higher, under its title bar, when they would not all fit; and a little smaller when even so they would go
-- past its bottom (TABS_MARGIN above it). The height of a tab and the space between two, in its own scale.
local TABS_TOP, TABS_HIGH, TABS_MARGIN = 60, 28, 8
function A.TabsLayout(frameH, count, tabH, space)
	if count <= 0 or tabH <= 0 then
		return TABS_TOP, 1
	end
	local need = count * tabH + (count - 1) * space
	if TABS_TOP + need <= frameH - TABS_MARGIN then
		return TABS_TOP, 1
	end
	return TABS_HIGH, math.min(1, (frameH - TABS_MARGIN - TABS_HIGH) / need)
end

-- (1.14.0, after its test) The tab of the chest shows: this character a reroll (UI/Reroll.lua).
function A.RerollTab()
	local RR = ns.Reroll
	return RR ~= nil and RR:IsReroll() or false
end

-- The tabs (another player's collection has only three: their albums, their achievements, their
-- profile), the title of the window and the arrows of the albums.
function A:PaintTabs()
	local f = self.frame
	local other = self.member ~= nil
	local short = other and ns.Guild:Short(self.member)
	local prev
	-- (1.12.0: eleven tabs with the one of an event: from higher, and made a little smaller when they would go
	-- past the bottom of the window; the gap of a tab is its offset under the one above, negative: down)
	local count, tabH, space = 0, 0, 2
	for i, tab in ipairs(f.tabs) do
		if (not other or THEIRS_TAB[tab.mode]) and not (TABS[i].event and not ns.Quests:EventOn(TABS[i].event))
			and not (TABS[i].reroll and not A.RerollTab()) then
			count = count + 1
			tabH = math.max(tabH, tab:GetHeight() or 0)
			space = math.max(0, -(tab.gap or -2))
		end
	end
	local top, scale = A.TabsLayout(f:GetHeight() or HEIGHT, count, tabH, space)
	-- (1.14.3: another player's albums and an album of theirs, under the tab of their inventory)
	local lit = TAB_OF[self.mode] or LIT_OF[self.mode]
	if other and (self.mode == "member" or self.mode == "contents") then
		lit = TAB_OF.inventory
	end
	for i, tab in ipairs(f.tabs) do
		local shown = not other or THEIRS_TAB[tab.mode] or false
		-- (1.12.0: the tab of an event, while it lasts)
		if TABS[i].event and not ns.Quests:EventOn(TABS[i].event) then
			shown = false
		end
		-- (1.14.0, after its test: the chest of a reroll, on a reroll only, mine)
		if TABS[i].reroll and (other or not A.RerollTab()) then
			shown = false
		end
		CuratorOctoFull.SetShown(tab, shown)
		-- with another player's collection, their inventory (1.14.3), their achievements, their profile
		if other and tab.mode == "contents" then
			tab.tooltipText = string.format(L["%s's albums"], short)
		elseif other and tab.mode == "inventory" then
			tab.tooltipText = string.format(L["%s's inventory"], short)
		elseif other and tab.mode == "ach" then
			tab.tooltipText = string.format(L["%s's achievements"], short)
		elseif other and tab.mode == "profile" then
			tab.tooltipText = string.format(L["%s's profile"], short)
		else
			tab.tooltipText = L[TABS[i].label]
		end
		tab:SetChecked(lit == i)
		if shown then
			tab:ClearAllPoints()
			tab:SetScale(scale)
			if prev then
				tab:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -space)
			else
				-- (the offset of a frame is counted in its own scale)
				tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, -top / scale)
			end
			prev = tab
		end
	end
	self:PaintBack()
	local title
	if other then
		title = (self.mode == "ach" and string.format(L["%s's achievements"], short))
			or (self.mode == "profile" and string.format(L["%s's profile"], short))
			or string.format(L["%s's collection"], short)
	elseif self.mode == "mine" then
		title = L["My collection"]
	else
		local i = TAB_OF[self.mode]
		title = L[(i and TABS[i].label) or PAGE_LABEL[self.mode] or TABS[TAB_OF.contents].label]
	end
	f:SetTitle(title)
	-- the arrows turn the albums, on every page but the contents, the boosters, the achievements, the
	-- profile, the quests and the social page
	local album = self.mode ~= "contents" and self.mode ~= "ach" and self.mode ~= "profile" and self.mode ~= "quests" and self.mode ~= "boosters"
		and self.mode ~= "guild" and self.mode ~= "talents" and self.mode ~= "inns" and self.mode ~= "pvp" and self.mode ~= "discovery"
		and self.mode ~= "inventory" and self.mode ~= "rates" and self.mode ~= "cases" and self.mode ~= "chest"
	CuratorOctoFull.SetShown(f.sPrev, album)
	CuratorOctoFull.SetShown(f.sNext, album)
	f.title:ClearAllPoints()
	if album then
		f.title:SetPoint("LEFT", f.sPrev, "RIGHT", 2, 0)
	else
		f.title:SetPoint("LEFT", f.sPrev, "LEFT", 2, 0)
	end
	-- the new cards, the rewards waiting, on their tabs
	self:PaintBadges()
end

-- Title of a page: its name (smaller to leave room for the progress bar), then its line under it.
function A:SetTitle(text, sub)
	local f = self.frame
	-- from after the left arrow to the progress bar, less the right arrow
	local room = (WIDTH - 16 - BAR_W) - 12 - (60 + 26 + 2) - (2 + 26)
	S.SetFontObject(f.title, "GameFontNormalHuge")
	f.title:SetText(text)
	if ns.TextWidth(f.title) > room then
		S.Fit(f.title, text, room, 19, 12)
	end
	f.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.sub:SetText(sub or "")
end

-- The progress bar of the header: done of total, and its text.
function A:SetBar(done, total, text)
	local bar = self.frame.bar
	bar:SetProgress(done / math.max(1, total))
	bar.text:SetText(text)
end

-- The pages of the page shown.
function A:SetPager(page, pages, label)
	self.frame.pager:Set(page, pages, label or string.format(L["Page %d / %d"], page, pages))
end

function A:SetMode(mode)
	self.mode = mode
	self.tocReturn = nil
	-- (the achievements: their order set again, on their first page: the rewards waiting are there)
	self.member, self.memberEntries, self.achOrder, self.achPage = nil, nil, nil, 1
	self.page = 1
	self:HideDetail()
	if mode == "guild" then
		ns.Guild:Query()
	end
	self:Refresh()
end

-- A page of the other player whose collection is open: their albums, their achievements, their
-- profile (asked for again: their showcase and their finest pulls come with it).
function A:SetMemberMode(mode)
	self.mode = mode
	self.memberEntries, self.achOrder = nil, nil
	self.page, self.achPage, self.profPage = 1, 1, 1
	if mode == "profile" and self.member then
		self.asked = GetTime()
		ns.Guild:Ask(self.member, true)
		ns.Delay(6, function()
			if A.mode == "profile" and A.member and A.frame:IsShown() then
				A:Refresh()
			end
		end, self)
	end
	self:HideDetail()
	self:Refresh()
end

-- The collection of another player (a guild member, or a player met): the contents of their
-- albums, from what they send when asked. (1.14.3, his word: on their inventory, Everything, its first page.)
function A:ShowPlayer(name)
	-- (1.13.1: the name as Curator keeps it, whatever way it came: on OctoWoW, "First-Surname")
	name = ns.Guild:Canon(ns.Guild:Full(name) or name)
	if not name then
		return
	end
	self:Build()
	if not (self.frame:IsShown() and self.member) then
		self.returnMode = self.frame:IsShown() and self.mode or "contents"
	end
	-- (1.14.3: their inventory as it opens, Everything, its first page: UI/Inventory.lua)
	if ns.InventoryUI and ns.InventoryUI.TheirHome then
		ns.InventoryUI:TheirHome(name)
	end
	self.mode, self.member, self.memberEntries, self.achOrder = "inventory", name, nil, nil
	self.tocTab, self.tocPages, self.page, self.profSec, self.memberBack = nil, nil, 1, nil, nil
	self.asked = GetTime()
	ns.Guild:Ask(name, true)
	self:Seen(name)
	self:HideDetail()
	self:Reveal()
	ns.Delay(6, function()
		if A.member == name and A.frame:IsShown() then
			A:Refresh()
		end
	end, self)
end

-- A collection of another player looked at (for the achievements), once it is there.
function A:Seen(name)
	if ns.Guild:Player(name) and not ns.Guild:IsMe(name) then
		local st = ns.Stats()
		if not st.seen[name] then
			st.seen[name] = true
			ns.Fire("SEEN", name)
		end
	end
end

-- Opens a guild member's album: what they sent last time, refreshed by a request to them. (1.14.3) card: a card of
-- their inventory clicked, its page; back to where it opened from (their inventory, their albums).
function A:ShowMember(name, s, card)
	name = ns.Guild:Canon(ns.Guild:Full(name) or name)
	if not name then
		return
	end
	self:Build()
	if not (self.frame:IsShown() and self.member) then
		self.returnMode = self.frame:IsShown() and self.mode or "guild"
	end
	if self.frame:IsShown() and self.member == name and (self.mode == "inventory" or self.mode == "contents") then
		self.memberBack = self.mode
	elseif self.member ~= name then
		self.memberBack = nil
	end
	self:Seen(name)
	self.series = s or self:Series()
	self.mode, self.member, self.page, self.profSec = "member", name, 1, nil
	if card and card.series == self.series then
		self.filter, self.found, self.finish = nil, nil, nil
		for i, c in ipairs(self.series.list) do
			if c == card then
				self.page = math.ceil(i / PER_PAGE)
			end
		end
	end
	self.memberEntries = ns.Guild:Album(name, self.series)
	self.asked = GetTime()
	ns.Guild:RequestAlbum(name, self.series)
	self:HideDetail()
	self:Reveal()
	ns.Delay(6, function()
		if A.mode == "member" and A.member == name then
			A:Refresh()
		end
	end, self)
end

-- "Dungeon · Levels 17-26", "Raid · Level 60", "Levels 10-20", "Levels 1-10 · Stormwind City"
function A:SubLine(s)
	-- (1.12.0) an album of an event: a limited edition, until when (Hallow.lua)
	if s.event then
		local H = ns.Hallow
		if H and H:On() then
			return L["Limited edition"] .. " · " .. string.format(L["ends in %s"], ns.Duration(H:Left()))
		elseif H and H:Over() then
			return L["Limited edition"] .. " · " .. L["the event is over"]
		end
		return L["Limited edition"]
	end
	-- (1.13.0) a limited edition of no event of the game: the Hardcup Saison 3, an event of WoW Classic
	if s.limited then
		return L["Limited edition"] .. " · " .. L["WoW Classic"]
	end
	if s.raid then
		return L["Raid"] .. " · " .. C:LevelRange(s)
	elseif s.dungeon then
		return L["Dungeon"] .. " · " .. C:LevelRange(s)
	end
	local city = s.city and MapName(s.city)
	if city then
		return C:LevelRange(s) .. " · " .. city
	end
	return C:LevelRange(s)
end

-------------------------------------------------------------------------------
-- Rarity counters and the filter
-------------------------------------------------------------------------------
-- The filter works on the pages of cards (mine, a guild member's).
function A:CanFilter()
	return self.mode == "mine" or self.mode == "member"
end

function A:SetFilter(r)
	if not self:CanFilter() then
		return
	end
	self.filter = (self.filter ~= r) and r or nil
	self.page = 1
	self:HideDetail()
	ns.Play(ns.SND.page)
	self:Refresh()
	local b = self.frame.counts[r]
	if b:IsMouseOver() then
		self:CountTooltip(b)
	end
end

-- The cards shown on the pages of an album: all of them, or those of the rarity of the filter,
-- and only those found when the bar was clicked (1.12.0: or found in the finish of the filter).
function A:Cards(s)
	local list = self.filter and s.byRarity[self.filter] or s.list
	local fin = self.finish and FINISH_OF[self.finish]
	if not self.found and not fin then
		return list
	end
	local out = {}
	for _, card in ipairs(list) do
		local e = self:EntryOf(card)
		if e and e.n > 0 and (not fin or (e[fin.field] or 0) > 0) then
			out[CuratorOctoFull.Length(out) + 1] = card
		end
	end
	return out
end

-- (1.12.0) The finish filter: the cards found in that finish only (a second click: all of them).
function A:SetFinish(key)
	if not self:CanFilter() then
		return
	end
	self.finish = (self.finish ~= key) and key or nil
	self.page = 1
	self:HideDetail()
	ns.Play(ns.SND.page)
	self:Refresh()
	for _, b in ipairs(self.frame.fins) do
		if b.finish == key and b:IsMouseOver() then
			self:FinishTooltip(b)
		end
	end
end

-- The look of a card found: the finish of the filter when it has it (a card in both finishes shows
-- the one asked for), its best one otherwise.
function A:ShownFinish(e)
	local fin = self.finish and FINISH_OF[self.finish]
	if fin and e and (e[fin.field] or 0) > 0 then
		return fin.key
	end
	return C:BestFinish(e)
end

-- The cards of an album found in each finish, on the buttons of the finishes (only on the pages of
-- an album: elsewhere they hide). Left of the leftmost gem shown, past the rule.
function A:SetFinishCounts(s)
	local f = self.frame
	local can = self:CanFilter() and s ~= nil
	CuratorOctoFull.SetShown(f.finRule, can)
	-- (1.12.0: an album of an event, its corrupted cards; the others, their forged ones)
	local event = s ~= nil and s.event ~= nil
	for _, b in ipairs(f.fins) do
		CuratorOctoFull.SetShown(b, can and ((FINISH_OF[b.finish].event == true) == event))
	end
	if not can then
		return
	end
	local n = {}
	for _, fin in ipairs(FINISHES) do
		n[fin.key] = 0
	end
	for _, card in ipairs(s.list) do
		local e = self:EntryOf(card)
		if e and e.n > 0 then
			for _, fin in ipairs(FINISHES) do
				if (e[fin.field] or 0) > 0 then
					n[fin.key] = n[fin.key] + 1
				end
			end
		end
	end
	for _, b in ipairs(f.fins) do
		b.found, b.total = n[b.finish], s.official or CuratorOctoFull.Length(s.list)
		b.text:SetText(tostring(b.found))
		b:SetWidth(17 + math.ceil(ns.TextWidth(b.text, 12)))
		local on = self.finish == b.finish
		CuratorOctoFull.SetShown(b.mark, on)
		CuratorOctoFull.SetShown(b.line, on)
		b:SetAlpha((self.finish and not on) and 0.5 or 1)
	end
	local left
	for r = 1, CuratorOctoFull.Length(f.counts) do
		if f.counts[r]:IsShown() then
			left = f.counts[r]
			break
		end
	end
	f.finRule:ClearAllPoints()
	if left then
		f.finRule:SetPoint("RIGHT", left, "LEFT", -9, 0)
	else
		f.finRule:SetPoint("RIGHT", f, "TOPRIGHT", -16, -61)
	end
	local nxt = f.finRule
	for i = CuratorOctoFull.Length(f.fins), 1, -1 do
		local b = f.fins[i]
		if b:IsShown() then
			b:ClearAllPoints()
			b:SetPoint("RIGHT", nxt, "LEFT", nxt == f.finRule and -9 or -8, 0)
			nxt = b
		end
	end
end

function A:FinishTooltip(b)
	local fin = FINISH_OF[b.finish]
	local c = fin.colour
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L[fin.label], c[1], c[2], c[3])
	GameTooltip:AddLine(string.format(L["%d / %d cards"], b.found or 0, b.total or 0), 1, 1, 1)
	if self:CanFilter() then
		GameTooltip:AddLine(self.finish == b.finish and L["Click to show all the cards"] or L["Click to show only the cards found in this finish"], GOLD[1], GOLD[2], GOLD[3], true)
	end
	GameTooltip:Show()
end

function A:ToggleFound()
	if not self:CanFilter() then
		return
	end
	self.found = not self.found or nil
	self.page = 1
	self:HideDetail()
	ns.Play(ns.SND.page)
	self:Refresh()
	if self.frame.bar.hit:IsMouseOver() then
		self:BarTooltip(self.frame.bar)
	end
end

function A:BarTooltip(bar)
	GameTooltip:SetOwner(bar, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(bar.text:GetText() or "", 1, 1, 1)
	if self:CanFilter() then
		GameTooltip:AddLine(self.found and L["Click to show all the cards"] or L["Click to show only the cards found"], GOLD[1], GOLD[2], GOLD[3])
	end
	GameTooltip:Show()
end

-- found, total: one counter per rarity
function A:SetCounts(found, total)
	local f = self.frame
	local can = self:CanFilter()
	for r, b in ipairs(f.counts) do
		b.found, b.total = found[r], total[r]
		b.text:SetText(string.format(("%d/%d"), found[r], total[r]))
		b:SetWidth(17 + math.ceil(ns.TextWidth(b.text, 30)))
		local on = can and self.filter == r
		CuratorOctoFull.SetShown(b.mark, on)
		CuratorOctoFull.SetShown(b.line, on)
		b:SetAlpha((can and self.filter and not on) and 0.5 or 1)
		-- (no card of this rarity here: the commons and uncommons of a dungeon or a raid)
		if (total[r] or 0) == 0 then
			b:Hide()
		end
	end
end

function A:CountTooltip(b)
	local r = ns.RARITY[b.rarity]
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L[r.label], r.text[1], r.text[2], r.text[3])
	GameTooltip:AddLine(string.format(L["%d / %d cards"], b.found or 0, b.total or 0), 1, 1, 1)
	if self:CanFilter() then
		GameTooltip:AddLine(self.filter == b.rarity and L["Click to show all the cards"] or L["Click to show only these cards"], GOLD[1], GOLD[2], GOLD[3])
	end
	GameTooltip:Show()
end

-- The arrows of the pages (album, guild, contents, contracts, achievements).
function A:ShowPager(shown)
	CuratorOctoFull.SetShown(self.frame.pager, shown)
end

function A:Refresh()
	local f = self.frame
	local s = self:Series()
	self:ShowGold(false)
	f.trade:Hide()
	f.seeAll:Hide()
	self:PaintTabs()
	self:ShowContractPage(self.mode == "contract")
	self:ShowAchPage(self.mode == "ach")
	self:ShowProfilePage(self.mode == "profile")
	self:ShowQuestsPage(self.mode == "quests")
	self:ShowBoostersPage(self.mode == "boosters")
	self:ShowSocialPage(self.mode == "guild" and not self.member)
	self:ShowTalentsPage(self.mode == "talents")
	self:ShowInnsPage(self.mode == "inns")
	-- (1.14.0, his word: the page of the PvP gone with it until its rework, UI/Pvp.lua)
	if self.ShowPvpPage then
		self:ShowPvpPage(self.mode == "pvp")
	end
	self:ShowDiscoveryPage(self.mode == "discovery")
	-- (1.15.0: the statistics)
	if self.ShowRatesPage then
		self:ShowRatesPage(self.mode == "rates")
	end
	-- (1.13.0: the inventory)
	if self.ShowInventoryPage then
		self:ShowInventoryPage(self.mode == "inventory")
	end
	-- (1.14.0, after its first test: the album of a collection of the cases)
	if self.ShowCasesPage then
		self:ShowCasesPage(self.mode == "cases")
	end
	-- (1.14.0, after its test: the chest of a reroll, UI/Reroll.lua)
	if self.ShowChestPage then
		self:ShowChestPage(self.mode == "chest")
	end
	-- (the quests and the achievements have their own bars in the head)
	CuratorOctoFull.SetShown(f.bar, self.mode ~= "quests" and self.mode ~= "ach")
	-- the contract page has its own row of rarities (the five exchanges), the achievements and the
	-- quests their categories (the talents: none)
	for _, b in ipairs(f.counts) do
		CuratorOctoFull.SetShown(b, self.mode ~= "contract" and self.mode ~= "ach" and self.mode ~= "quests" and self.mode ~= "talents" and self.mode ~= "inns" and self.mode ~= "pvp"
			and self.mode ~= "discovery" and self.mode ~= "inventory" and self.mode ~= "rates" and self.mode ~= "cases" and self.mode ~= "chest")
	end
	-- (1.12.0: the finishes, on the pages of an album only: see below)
	self:SetFinishCounts(nil)
	f.wait:Hide()
	f.farm:Hide()
	if self.mode == "contract" then
		return self:RefreshContract()
	end
	if self.mode == "ach" then
		return self:RefreshAch()
	end
	if self.mode == "profile" then
		return self:RefreshProfile()
	end
	if self.mode == "quests" then
		return self:RefreshQuests()
	end
	if self.mode == "boosters" then
		return self:RefreshBoosters()
	end
	if self.mode == "talents" then
		return self:RefreshTalents()
	end
	if self.mode == "inns" then
		return self:RefreshInns()
	end
	if self.mode == "pvp" and self.RefreshPvp then
		return self:RefreshPvp()
	end
	if self.mode == "discovery" then
		return self:RefreshDiscovery()
	end
	if self.mode == "rates" and self.RefreshRates then
		return self:RefreshRates()
	end
	if self.mode == "inventory" and self.RefreshInventory then
		return self:RefreshInventory()
	end
	if self.mode == "cases" and self.RefreshCases then
		return self:RefreshCases()
	end
	if self.mode == "chest" and self.RefreshChest then
		return self:RefreshChest()
	end
	if self.mode == "contents" then
		return self:RefreshContents()
	end
	f.toc:Hide()
	self:ShowPager(true)
	if self.mode == "guild" then
		return self:RefreshSocial()
	end
	f.list:Hide()
	-- (a filter on a rarity this album has none of, the commons of a dungeon: off)
	if self.filter and CuratorOctoFull.Length(s.byRarity[self.filter]) == 0 then
		self.filter = nil
	end
	local cards = self:Cards(s)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(cards) / PER_PAGE))
	self.page = math.max(1, math.min(self.page or 1, pages))
	local member = self.mode == "member"
	if member then
		self.memberEntries = ns.Guild:Album(self.member, s) or self.memberEntries
	end
	self:SetTitle(C:SeriesName(s), self:SubLine(s))
	-- (1.14.0: the contraband of the Hardcup Saison 3 out of the cards of its album, in the count of its rarity)
	local owned, total, byRarity = 0, s.official or CuratorOctoFull.Length(s.list), C.PerRarity(0)
	for _, card in ipairs(s.list) do
		local e = self:EntryOf(card)
		if e and e.n > 0 then
			if not card.smuggle then
				owned = owned + 1
			end
			byRarity[card.rarity] = byRarity[card.rarity] + 1
		end
	end
	self:SetBar(owned, total, string.format(L["%d / %d cards"], owned, total))
	local all = C.PerRarity(0)
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		all[r] = CuratorOctoFull.Length(s.byRarity[r])
	end
	self:SetCounts(byRarity, all)
	self:SetFinishCounts(s)
	-- a new page (another album, page, filter): the new cards of the one left were seen; the cards come
	-- in one after the other (from the side the page turns from)
	local view = table.concat({ s.key, self.page, self.filter or 0, self.found and 1 or 0, self.member or "", self.finish or "" }, ":")
	local turned = view ~= self.view
	if turned then
		self:SeePage()
	end
	self.view = view
	local mine = not member
	local keep = ns.db.keepOne
	local fresh = {}
	for i, c in ipairs(f.slots) do
		local card = cards[(self.page - 1) * PER_PAGE + i]
		if card then
			local e = self:EntryOf(card)
			local has = (e and e.n > 0) and true or false
			local finish = has and self:ShownFinish(e) or nil
			local new = mine and has and C:Fresh(card)
			-- (1.8.0: the card of an innkeeper, signed for me)
			local signed = mine and has and ns.Inns ~= nil and ns.Inns:IsSigned(card)
			-- (1.14.0: titanforged, the pattern of my copy that shows it, Copies.lua)
			local pattern = mine and finish == "holo" and ns.Copies and ns.Copies:PatternOf(card.key) or nil
			-- (his idea, 31 October: the wear of its copy, Wear.lua)
			local wear = mine and has and ns.Wear and ns.Wear:Shown(card, finish) or nil
			-- a card is set again only when it changes: setting it reloads its creature
			local sig = self:SlotSig(card, e, finish, new) .. (signed and "#" or "") .. (pattern and ("p" .. pattern) or "")
				.. (wear and ("w" .. tostring(wear.seed) .. table.concat(wear.m, "") .. tostring(wear.x or "") .. tostring(wear.a or "")) or "")
			if c.sig ~= sig or not c:IsShown() then
				c.sig = sig
				-- (the pennant of the card it showed, shrinking away: it goes with it)
				local bd = c.badge
				if bd.tw then
					ns.CancelTween(bd.tw)
					bd.tw = nil
					bd:SetScale(1)
					bd:SetAlpha(1)
				end
				c:SetCard(card, { owned = has, finish = finish, count = has and e.n or nil, new = new, signed = signed, pattern = pattern,
					wear = wear })
				c:ShowSide("front")
			end
			if new then
				fresh[CuratorOctoFull.Length(fresh) + 1] = card
			end
			CuratorOctoFull.SetShown(c.engrave, not has)
			-- the copies it has to exchange
			local spare = (mine and has) and ns.Contract:SpareAll(card, keep) or 0
			CuratorOctoFull.SetShown(c.spare, spare > 0)
			c.spare.text:SetText(spare > 9 and "9+" or tostring(spare))
			CuratorOctoFull.SetShown(c.wait, (mine and has and ns.Trade and ns.Trade:HeldAll(card.key) > 0) and true or false)
			self:PaintSeek(c, mine, has, spare)
			-- (1.11.0) its grade, when it was appraised (UI/Expertise.lua)
			if self.PaintGrade then
				self:PaintGrade(c, (mine and has and ns.Expertise) and ns.Expertise:Grade(card) or nil)
			end
			c.phase = i * 0.37
			c:Show()
			if turned then
				self:SlideIn(c, i, self.turnDir)
			end
		else
			c:Hide()
			c.card, c.sig = nil, nil
		end
	end
	self.turnDir = nil
	self.pageFresh = CuratorOctoFull.Length(fresh) > 0 and fresh or nil
	-- an album complete: its frame of gold, its seal, its bar of gold
	local complete = owned >= total and total > 0
	self:ShowGold(complete, owned, total)
	local label = string.format(L["Page %d / %d"], self.page, pages)
	if self.filter then
		local r = ns.RARITY[self.filter]
		label = "|cff" .. Hex(r.text) .. L[r.label] .. "|r  ·  " .. label
	end
	if self.found then
		label = L["Found"] .. "  ·  " .. label
	end
	if self.finish then
		local fin = FINISH_OF[self.finish]
		label = "|cff" .. Hex(fin.colour) .. L[fin.label] .. "|r  ·  " .. label
	end
	self:SetPager(self.page, pages, label)
	-- a member's album that has not arrived yet
	local waiting = member and not self.memberEntries
	-- (1.12.0) filters that leave the page empty: said on it
	local empty = not waiting and CuratorOctoFull.Length(cards) == 0 and (self.found or self.finish) and true or false
	CuratorOctoFull.SetShown(f.wait, waiting or empty)
	if waiting then
		local late = self.asked and GetTime() - self.asked > 5
		f.wait.text:SetText(late and string.format(L["%s did not answer (offline?)"], ns.Guild:Short(self.member))
			or string.format(L["Waiting for %s..."], ns.Guild:Short(self.member)))
	elseif empty then
		f.wait.text:SetText(L["No card found with these filters."])
	end
	self:RefreshFooter(not member)
end

-- An album complete: its frame of gold, the seal and the bar of gold in the head (instead of the
-- bar of the game); anything else: the bar of the game.
function A:ShowGold(on, owned, total)
	local f = self.frame
	CuratorOctoFull.SetShown(f.gold, on and true or false)
	CuratorOctoFull.SetShown(f.goldBar, on and true or false)
	CuratorOctoFull.SetShown(f.goldSeal, on and true or false)
	if on then
		f.bar:Hide()
		f.goldBar:SetProgress(1)
		f.goldBar:SetText(string.format(L["%d / %d cards"], owned, total))
	end
end

function A:RefreshFooter(mine)
	local f = self.frame
	local s = self:Series()
	local inst = mine and ns.Rewards:InstanceSeries() or nil
	CuratorOctoFull.SetShown(f.farm, inst ~= nil)
	CuratorOctoFull.SetShown(f.boosters, mine and not inst)
	CuratorOctoFull.SetShown(f.gauge, mine)
	CuratorOctoFull.SetShown(f.open, mine)
	-- the copies of the album to exchange (on its pages)
	local spare = (mine and self.mode == "mine") and ns.Contract:SpareIn(s, ns.db.keepOne) or 0
	f.trade.n = spare
	CuratorOctoFull.SetShown(f.trade, spare > 0)
	f.trade:SetLabel(string.format(L["Duplicates: %d"], spare))
	if not mine then
		return
	end
	local packs = ns.Packs(s)
	f.boosters:SetText(string.format(L["Boosters: %d"], packs))
	-- (1.14.0, after its test, his word: a reroll opens none, the button off, why in its tooltip)
	CuratorOctoFull.SetEnabled(f.open, packs > 0 and not (ns.Reroll and ns.Reroll:NoOpening()))
	f.open:SetLabel(packs > 0 and L["Open a booster"] or L["No booster to open"])
	if inst then
		return self:PaintFarm(inst)
	end
	f.gauge:ClearAllPoints()
	f.gauge:SetPoint("LEFT", f.boosters, "RIGHT", 12, 0)
	f.gauge:SetWidth(90)
	f.gauge:SetAlpha(1)
	self:PaintGauge(s)
end

-- The booster bar (one for every album, 1.2; in a dungeon or a raid, theirs, steel blue: 1.4.1).
function A:PaintGauge()
	local f = self.frame
	local R = ns.Rewards
	local kind = R:Here()
	local pct = math.floor(100 * R:Bar(kind) / ns.PACK_POINTS)
	f.gauge.pct = pct
	f.gauge:SetProgress(pct / 100)
	if kind == "dungeon" then
		f.gauge:SetStatusBarColor(0.5, 0.68, 1)
	else
		f.gauge:SetStatusBarColor(0, 0.6, 0)
	end
end

-------------------------------------------------------------------------------
-- In a dungeon or a raid: the album that gets the boosters earned there
-------------------------------------------------------------------------------
function A:PaintFarm(inst)
	local f = self.frame
	local s = ns.Rewards:FarmSeries(inst)
	local farm = f.farm
	-- the menu shows the album chosen
	farm:GenerateMenu()
	-- a dungeon too low, or the boosters of the day all given: the gauge is dimmed
	local off = ns.Rewards:TooLow(inst) or ns.Rewards:DailyLeft() <= 0
	f.gauge:SetAlpha(off and 0.45 or 1)
	farm:Show()
	f.gauge:ClearAllPoints()
	f.gauge:SetPoint("LEFT", farm, "RIGHT", 14, 0)
	f.gauge:SetWidth(80)
	f.gauge:Show()
	self:PaintGauge(s)
end

-- The tooltip of the menu: where the boosters of this place go, the limit of the day.
function A:FarmTooltip(tooltip)
	local R = ns.Rewards
	local inst = R:InstanceSeries()
	if not inst then
		return
	end
	local s = R:FarmSeries(inst)
	tooltip:AddLine(string.format(L["Boosters earned in %s go to:"], C:SeriesName(inst)), GOLD[1], GOLD[2], GOLD[3])
	tooltip:AddLine(C:SeriesName(s), 1, 1, 1)
	tooltip:AddLine(string.format(L["Next booster: %d%%"], math.floor(100 * R:Bar("dungeon") / ns.PACK_POINTS)), 0.8, 0.8, 0.8)
	tooltip:AddLine(string.format(L["Boosters: %d"], ns.Packs(s)), 1, 1, 1)
	-- the limit of the day, and a dungeon too low
	local left = R:DailyLeft()
	tooltip:AddLine(string.format(L["Today: %d / %d boosters from the dungeons and raids"], R:DailyMax() - left, R:DailyMax()), left > 0 and 0.8 or 1, left > 0 and 0.8 or 0.5, left > 0 and 0.8 or 0.4)
	if R:TooLow(inst) then
		tooltip:AddLine(string.format(L["%s: too low for your level, no boosters here."], C:SeriesName(inst)), 1, 0.5, 0.4, true)
	end
	tooltip:AddLine(L["Click to choose another album"], GOLD[1], GOLD[2], GOLD[3])
end

-- The menu of the albums that can get them: this place's own, then those of the places visited.
function A:FarmMenu(root)
	local R = ns.Rewards
	local inst = R:InstanceSeries()
	if not inst then
		return
	end
	local others = {}
	for _, s in ipairs(self:Order()) do
		if s ~= inst and R:Visited(s) then
			others[CuratorOctoFull.Length(others) + 1] = s
		end
	end
	root:CreateTitle(string.format(L["Boosters earned in %s go to:"], C:SeriesName(inst)))
	local function Add(s)
		root:CreateRadio(C:SeriesName(s), function()
			return R:FarmSeries(inst) == s
		end, function()
			R:SetFarm(inst, s)
		end, s)
	end
	Add(inst)
	if CuratorOctoFull.Length(others) > 0 then
		root:CreateDivider()
	end
	for _, s in ipairs(others) do
		Add(s)
	end
	root:CreateDivider()
	root:CreateTitle(L["Only the albums of the places you have been to can be chosen."])
	if CuratorOctoFull.Length(others) > 14 and root.SetScrollMode then
		root:SetScrollMode(440)
	end
end

function A:Page(delta)
	if self.mode == "contract" then
		return self:ContractPage(delta)
	end
	if self.mode == "ach" then
		return self:AchPage(delta)
	end
	if self.mode == "profile" then
		return self:ProfilePage(delta)
	end
	if self.mode == "quests" then
		return
	end
	if self.mode == "boosters" then
		return self:BoostersPage(delta)
	end
	if self.mode == "contents" then
		return self:TocPage(delta)
	end
	if self.mode == "guild" then
		return self:SocialPage(delta)
	end
	-- (1.13.0: the inventory, UI/Inventory.lua)
	if self.mode == "inventory" then
		return self:InventoryPage(delta)
	end
	-- (1.14.0, after its first test: the album of a collection of the cases, UI/CaseAlbum.lua)
	if self.mode == "cases" then
		return self.CasesPage and self:CasesPage(delta)
	end
	local s = self:Series()
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(self:Cards(s)) / PER_PAGE))
	local from = self.turnTarget or self.page or 1
	local p = math.max(1, math.min(pages, from + delta))
	if p ~= from then
		self:HideDetail()
		self:TurnPage(p, delta > 0 and 1 or -1)
	end
end

-- The page turns: its cards slide away the way it turns, a light passes over it, the cards of the
-- next one slide in from the other side (one turn after the other: the next one at once).
function A:TurnPage(p, dir)
	local f = self.frame
	ns.Play(ns.SND.page)
	self.turnTarget, self.turnDir = p, dir
	if self.turnTw then
		ns.CancelTween(self.turnTw)
	end
	local any = false
	for _, c in ipairs(f.slots) do
		local _, c = _, c; if c:IsShown() and c:GetAlpha() > 0.05 then
			any = true
			if c.slideTw then
				ns.CancelTween(c.slideTw)
			end
			local x0, a0 = c.dx or 0, c:GetAlpha()
			local order = dir > 0 and c.col or (COLS - 1 - c.col)
			c.slideTw = ns.Tween(0.13, function(e)
				c.dx = x0 - 34 * dir * e
				c:SetAlpha(a0 * (1 - e))
				A:PlaceSlot(c)
			end, nil, Ease.inQuad, self, order * 0.012)
		end
	end
	self:SweepPage(dir)
	local function go()
		A.turnTw, A.turnTarget = nil, nil
		A.page = p
		A:Refresh()
	end
	if any then
		self.turnTw = ns.Delay(0.13 + (COLS - 1) * 0.012, go, self)
	else
		go()
	end
end

-- A light passing over the page, the way it turns.
function A:SweepPage(dir)
	local t = self.frame.sweep
	if t.tw then
		ns.CancelTween(t.tw)
	end
	t.tw = ns.Tween(0.45, function(e, raw)
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.frame.body, "CENTER", dir * (420 - 840 * e), 0)
		t:SetAlpha(math.sin(math.pi * raw) * 0.32)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.inOutQuad, self)
end

function A:SlotEnter(c)
	if not c.card then
		return
	end
	GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
	local e = self:EntryOf(c.card)
	if e and e.n > 0 then
		ns.Booster:CardTooltip(c.card, nil, e)
		if (e.s or 0) > 0 then
			GameTooltip:AddLine(C:CopiesLine(c.card, "shiny", e.s), 0.75, 0.75, 1)
		end
		if (e.h or 0) > 0 then
			GameTooltip:AddLine(C:CopiesLine(c.card, "holo", e.h), 1, 0.8, 0.42)
		end
		-- (1.12.0) its corrupted copies, its seal
		if (e.c or 0) > 0 then
			GameTooltip:AddLine(string.format(L["Corrupted copies: %s"], C:CorruptLine(c.card)), 0.8, 0.48, 1, true)
			local rank = ns.Masters and ns.Masters:Rank(c.card)
			if rank then
				GameTooltip:AddLine(string.format(L["Sealed: %s"], ns.Masters.Label(rank)), 1, 1, 1)
			end
		end
		if self.mode ~= "member" and C:Pinned(c.card) then
			GameTooltip:AddLine(L["In your showcase"], 1, 0.82, 0.25)
		end
		-- the copies it has to exchange, and the way to the contracts
		local spare = self.mode == "mine" and ns.Contract:SpareAll(c.card, ns.db.keepOne) or 0
		if spare > 0 then
			GameTooltip:AddLine(string.format(L["Copies to exchange: %d"], spare), 1, 0.62, 0.5)
			GameTooltip:AddLine(L["Right click: into an exchange contract"], GOLD[1], GOLD[2], GOLD[3])
		end
		-- who looks for it; the copies that came in a trade not confirmed yet
		local T = ns.Trade
		if self.mode == "mine" and T then
			local seekers = T:SoughtBy(c.card)
			if CuratorOctoFull.Length(seekers) > 0 then
				GameTooltip:AddLine(string.format(L["Wanted by %s"], table.concat(self:ShortNames(seekers, 4), ", ")), 0.55, 0.85, 1, true)
			end
			local held = T:HeldAll(c.card.key)
			if held > 0 then
				-- (1.5.0: the days of the quarantine)
				local upto = T:HeldUntil(c.card.key)
				GameTooltip:AddLine(string.format(L["From a trade: %d, free in %s"], held, ns.Duration(math.max(60, (upto or 0) - CuratorOctoFull.ServerTime()))), 1, 0.8, 0.45, true)
				GameTooltip:AddLine(L["Until then it counts for no achievement, goes into no contract and into no other trade."], 0.75, 0.75, 0.75, true)
			end
		end
		ns.Links:AddHint(GameTooltip, true)
		-- a new card is seen: its pennant goes (not while the page turns: the cards are on their way)
		if self.mode == "mine" and not self.turnTarget and c:GetAlpha() > 0.9 and C:SeeFresh(c.card) then
			self:FreshSeen(c)
		end
	else
		local r = ns.RARITY[c.card.rarity]
		GameTooltip:AddLine("???", 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L[r.label], r.text[1], r.text[2], r.text[3])
		GameTooltip:AddLine(L["Not found yet"], 0.5, 0.5, 0.5)
		-- (my album: look for it, or not any more; who has it to spare)
		local T = ns.Trade
		if self.mode == "mine" and T then
			local holders = T:HoldersOf(c.card)
			if CuratorOctoFull.Length(holders) > 0 then
				GameTooltip:AddLine(string.format(L["To spare: %s"], table.concat(self:ShortNames(holders, 4), ", ")), 0.45, 1, 0.45, true)
			end
			if T:Wished(c.card) then
				GameTooltip:AddLine(L["You look for it"], 0.55, 0.85, 1)
				GameTooltip:AddLine(L["Click: stop looking for it"], GOLD[1], GOLD[2], GOLD[3])
			else
				GameTooltip:AddLine(L["Click: look for it (your guild sees it)"], GOLD[1], GOLD[2], GOLD[3])
			end
		end
	end
	GameTooltip:Show()
	c.glow:SetVertexColor(1, 0.9, 0.6)
	c.glow:SetAlpha(0.35)
	self:LiftSlot(c, 1.07)
end

function A:SlotLeave(c)
	GameTooltip:Hide()
	c.glow:SetAlpha(0)
	self:LiftSlot(c, 1)
end

-- The members of the guild, a page further.
function A:GuildPage(delta)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(ns.Guild:Members(self:Series())) / ROWS_PER_PAGE))
	local p = math.max(1, math.min(pages, (self.listPage or 1) + delta))
	if p ~= self.listPage then
		self.listPage = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- A slot at its place, grown from its centre (lift), moved aside (dx) and lowered (dy) for the
-- animations.
function A:PlaceSlot(c)
	local k = c.lift or 1
	c:SetScale(k)
	c:ClearAllPoints()
	c:SetPoint("TOPLEFT", c:GetParent(), "TOPLEFT", (c.bx + (c.dx or 0) + CW * (1 - k) / 2) / k, (c.by - CH * (1 - k) / 2 + (c.dy or 0)) / k)
end

function A:LiftSlot(c, to)
	if c.liftTw then
		ns.CancelTween(c.liftTw)
	end
	local from = c.lift or 1
	c.liftTw = ns.Tween(0.14, function(e)
		c.lift = from + (to - from) * e
		A:PlaceSlot(c)
	end, nil, ns.Ease.outQuad, self)
end

-- The cards of a page come in one after the other: from below, or from the side the page turns from
-- (dir), column after column.
function A:SlideIn(c, i, dir)
	if c.slideTw then
		ns.CancelTween(c.slideTw)
	end
	local x0, y0 = dir and 34 * dir or 0, dir and 0 or -10
	local delay = dir and ((dir > 0 and c.col or (COLS - 1 - c.col)) * 0.035 + math.floor((i - 1) / COLS) * 0.012) or (i - 1) * 0.018
	c.dx, c.dy = x0, y0
	c:SetAlpha(0)
	self:PlaceSlot(c)
	c.slideTw = ns.Tween(dir and 0.26 or 0.22, function(e)
		c.dx = x0 * (1 - e)
		c.dy = y0 * (1 - e)
		c:SetAlpha(e)
		A:PlaceSlot(c)
	end, function()
		c.dx, c.dy = 0, 0
		c:SetAlpha(1)
		A:PlaceSlot(c)
	end, ns.Ease.outCubic, self, delay)
end

function A:SlotClick(c, button)
	local e = c.card and self:EntryOf(c.card)
	-- a card of mine not found yet: looked for, or not any more
	if c.card and not (e and e.n > 0) and self.mode == "mine" and ns.Trade and not ns.Links:Modified() then
		local ok, why = ns.Trade:ToggleWish(c.card)
		if ok then
			ns.Play(ns.Trade:Wished(c.card) and ns.SND.ink or ns.SND.page)
			self:PaintSeek(c)
			if c:IsMouseOver() then
				self:SlotEnter(c)
			end
		else
			ns.Play(ns.SND.close)
			if why == "full" then
				ns.Print(L["You already look for %d cards: stop looking for one first."], ns.Trade:WishMax())
			end
		end
		return
	end
	if e and e.n > 0 then
		-- shift-click: the card in the chat
		if ns.Links:Modified() then
			-- (1.14.3: mine, the copy the page shows with it, its very card: UI/Links.lua)
			local fin = self:ShownFinish(e)
			local rec = self.mode ~= "member" and ns.CopiesUI and ns.CopiesUI:Default(c.card, fin) or nil
			ns.Links:Insert(c.card, fin, c.pat and c.pat.n or nil, nil, rec)
			return
		end
		-- right click: its copies to exchange into a contract
		if button == "RightButton" then
			if self.mode == "mine" and ns.Contract:SpareAll(c.card, ns.db.keepOne) > 0 then
				self:ContractFor(c.card)
			end
			return
		end
		ns.Play(ns.SND.cardFlip)
		self:ShowDetail(c.card, e)
	end
end

-- The mark of a card looked for: mine (a card missing, looked for), or one of mine to spare that someone
-- looks for (in blue).
function A:PaintSeek(c, mine, has, spare)
	local T = ns.Trade
	local card = c.card
	if mine == nil then
		mine = self.mode == "mine"
		local e = card and C:Entry(card)
		has = e and e.n > 0
		spare = (mine and has) and ns.Contract:SpareAll(card, ns.db.keepOne) or 0
	end
	local wished = mine and T and card and not has and T:Wished(card)
	local sought = mine and T and card and has and (spare or 0) > 0 and CuratorOctoFull.Length(T:SoughtBy(card)) > 0
	CuratorOctoFull.SetShown(c.seek, (wished or sought) and true or false)
	if wished then
		c.seek.tex:SetVertexColor(1, 1, 1)
	elseif sought then
		c.seek.tex:SetVertexColor(0.55, 0.85, 1)
	end
end

-- A new card seen under the mouse: its pennant shrinks away.
function A:FreshSeen(c)
	local bd = c.badge
	local card = c.card
	if bd:IsShown() then
		if bd.tw then
			ns.CancelTween(bd.tw)
		end
		bd.tw = ns.Tween(0.25, function(e)
			bd:SetScale(math.max(0.05, 1 - e))
			bd:SetAlpha(1 - e)
		end, function()
			bd.tw = nil
			bd:SetScale(1)
			bd:SetAlpha(1)
			-- (the slot shows another card now)
			if c.card ~= card then
				return
			end
			bd:Hide()
			-- (its count of copies, under the pennant)
			local e = card and C:Entry(card)
			if e and e.n > 1 then
				c.over.count:SetText("x" .. e.n)
			end
		end, Ease.inQuad, self)
	end
	-- (not set again for it: it would load its creature again)
	if c.card then
		local e = C:Entry(c.card)
		c.sig = self:SlotSig(c.card, e, self:ShownFinish(e), false)
	end
	self:PaintBadges()
end

-- What a slot shows (a card is set again only when it changes: setting it reloads its creature).
function A:SlotSig(card, e, finish, fresh)
	local has = e and e.n > 0
	-- (1.12.0: a corrupted card, the corruption it shows: sealed, purified, it changes)
	local k = (finish == "corrupt") and ("~" .. C:Corruption(card)) or ""
	return card.key .. (has and ("+" .. e.n) or "-") .. (finish or "") .. k .. (fresh and "*" or "")
end

-- The new cards of the page left were seen.
function A:SeePage()
	local list = self.pageFresh
	self.pageFresh = nil
	if not list then
		return
	end
	local any = false
	for _, card in ipairs(list) do
		if C:SeeFresh(card) then
			any = true
		end
	end
	if any and self.frame:IsShown() then
		self:PaintBadges()
	end
end

-- The badges of the tabs: the new cards (my collection), the boosters to choose, the rewards of the
-- achievements, of the levels (the profile) and of the quests waiting.
function A:PaintBadges()
	local f = self.frame
	if not (f and f.tabs) then
		return
	end
	local function badge(i, key)
		local tab = f.tabs[i]
		if not f[key] then
			f[key] = ns.Hud.Badge(tab, 20)
			f[key]:SetPoint("CENTER", tab, "TOPRIGHT", -9, -9)
			f[key]:SetFrameLevel(tab:GetFrameLevel() + 6)
		end
		return f[key]
	end
	badge(TAB_OF.contents, "newBadge"):SetCount(self.member and 0 or C:FreshCount())
	-- (1.14.0, after its test, his word: what a reroll cannot claim nor use has no badge, Reroll.lua: RR:Blocks)
	local RR = ns.Reroll
	local noQuests = RR ~= nil and RR:Blocks("quests")
	local noAch = RR ~= nil and RR:Blocks("achievements")
	local noChoice = RR ~= nil and RR:Blocks("choice")
	-- (the trades waiting: no tab of the social page since the first test of 1.13.0; their toast, the minimap button)
	badge(TAB_OF.ach, "achBadge"):SetCount((self.member or noAch) and 0 or ns.Achievements:ClaimCount())
	-- (1.12.0: the quests of Hallow's End on its own tab; 1.14.0: those of the discovery of the Paladin Collection Case
	-- No. 1 on its own, those of Hallow's End gone)
	local eventWaiting = (self.DiscoveryWaiting and not self.member and not noQuests) and self:DiscoveryWaiting() or 0
	badge(TAB_OF.quests, "qBadge"):SetCount((self.member or noQuests) and 0 or math.max(0, CuratorOctoFull.Length(ns.Quests:Claimable()) - eventWaiting))
	badge(TAB_OF.discovery, "discoveryBadge"):SetCount(eventWaiting)
	badge(TAB_OF.profile, "profBadge"):SetCount(self.member and 0 or CuratorOctoFull.Length(ns.Level:Unclaimed()))
	-- (1.6.0: the points of talent to place)
	badge(TAB_OF.talents, "talBadge"):SetCount((self.member or not (ns.Talents and ns.Talents.Waiting)) and 0 or ns.Talents:Waiting())
	-- (1.14.0: the rewards to choose; while rewards land, those landed so far)
	local choose = ns.Level:OfferCount()
	if self.questBusy and self.shownStock then
		choose = 0
		for _, n in pairs(self.shownStock) do
			choose = choose + n
		end
	end
	-- (1.13.0, after its first test: on the tab of the inventory, its boosters a part of it)
	badge(TAB_OF.boosters, "boostBadge"):SetCount((self.member or noChoice) and 0 or choose)
end

-- The copies of a card to exchange into a contract (all those it has, as many contracts as they make),
-- or the contracts of an album (the lowest rarity it has enough copies of for one).
function A:ContractFor(card, s)
	local K = ns.Contract
	local keep = ns.db.keepOne
	if card then
		local n, finish = K:SpareAll(card, keep)
		if n <= 0 then
			return
		end
		local ct = K:New(card.rarity, finish, math.ceil(K:Spare(card, finish, keep) / K:SizeOf(card.rarity, finish)))
		K:PutAll(ct, card, keep)
		self.ct, self.ctAlbum, self.ctPop = ct, nil, nil
		ns.Play(ns.SND.ink)
	else
		-- the lowest rarity it has enough copies of for a contract (normal copies first, then shiny,
		-- then holographic), else the one it has the most copies of
		local best, most, mostN = nil, nil, 0
		for _, finish in ipairs(K.FINISHES) do
			-- (1.13.0, after its second test: common to epic, a contract gives a legendary card at most)
			for r = 1, K.LAST do
				local n = 0
				for _, it in ipairs(K:Eligible(r, finish, keep, s)) do
					n = n + it.spare
				end
				if n >= K:SizeOf(r, finish) and not best then
					best = { r, finish }
				end
				if n > mostN then
					most, mostN = { r, finish }, n
				end
			end
		end
		local pick = best or most or { 1, "normal" }
		self.ct, self.ctAlbum = K:New(pick[1], pick[2]), s
	end
	self.ctPage = 1
	self:SetMode("contract")
end

-------------------------------------------------------------------------------
-- Detail view: the card in a showcase, on the photo of its place: a spotlight from above, the rays of
-- its rarity turning behind it, a socle under it (motes of light rising from it for the best ones);
-- drag to turn the card all the way round (its creature turns with it), the mouse wheel to bring it
-- closer (UI/Inspect.lua). Beside it, what there is to know about it; the legendary and mythic cards
-- can play their entrance again.
-------------------------------------------------------------------------------
-- the light of the rarities behind the card (rays: how bright)
local SHOW_RAYS = { 0, 0.12, 0.2, 0.3, 0.42, 0.5 }
local CARD_Y = 26

function A:BuildDetail()
	local f = self.frame
	local Hud = ns.Hud
	-- over the page: the window, its header and its bar of buttons stay around it
	local d = CreateFrame("Button", nil, f.body)
	d:SetPoint("TOPLEFT", 3, -3)
	d:SetPoint("BOTTOMRIGHT", -3, 3)
	d:SetFrameLevel(f.body:GetFrameLevel() + 30)
	d:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	if d.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(d, true)
	end
	-- the photo of its place, darkened, its edges in the shade
	d.bg = d:CreateTexture(nil, "BACKGROUND")
	d.bg:SetAllPoints()
	d.bg:SetTexture(MEDIA .. "StudioElwynn")
	d.dim = d:CreateTexture(nil, "BACKGROUND", nil, 1)
	d.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(d.dim, 0.01, 0.01, 0.02, 0.62)
	d.vig = d:CreateTexture(nil, "BACKGROUND", nil, 2)
	d.vig:SetAllPoints()
	d.vig:SetTexture(MEDIA .. "Vignette")
	-- (1 November, his word: « si on appuie sur un endroit où y'a pas de bouton, ça ferme le sous menu. J'aimerai un
	-- "Retour" »: a click beside the card does nothing; Back at the foot of the window, a tab, or the back button of a
	-- mouse, A:GoBack)
	d:Hide()
	self.detail = d

	local x0 = 44
	local cw, ch = ns.CARD_SIZES.huge[1], ns.CARD_SIZES.huge[2]
	local cx = x0 + cw / 2
	-- behind the card: the rays of its rarity, its light, the spotlight
	d.rays = d:CreateTexture(nil, "BORDER")
	d.rays:SetTexture(MEDIA .. "Rays")
	d.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(d.rays, 660, 660)
	d.rays:SetPoint("CENTER", d, "LEFT", cx, CARD_Y)
	d.rays2 = d:CreateTexture(nil, "BORDER", nil, 1)
	d.rays2:SetTexture(MEDIA .. "Rays")
	d.rays2:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(d.rays2, 880, 880)
	d.rays2:SetPoint("CENTER", d, "LEFT", cx, CARD_Y)
	d.rays2:SetVertexColor(1, 0.78, 0.36)
	d.halo = d:CreateTexture(nil, "BORDER", nil, 2)
	d.halo:SetTexture(MEDIA .. "Glow")
	d.halo:SetBlendMode("ADD")
	d.halo:SetPoint("CENTER", d, "LEFT", cx, CARD_Y)
	CuratorOctoFull.SetSize(d.halo, 560, 640)
	d.spot = d:CreateTexture(nil, "BORDER", nil, 3)
	d.spot:SetTexture(MEDIA .. "Spotlight")
	d.spot:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(d.spot, 330, 520)
	d.spot:SetPoint("TOP", d, "TOPLEFT", cx, 30)
	d.spot:SetVertexColor(1, 0.95, 0.85)
	d.spot:SetAlpha(0.32)
	-- the socle, its light
	d.ped = d:CreateTexture(nil, "ARTWORK")
	d.ped:SetTexture(MEDIA .. "Pedestal")
	CuratorOctoFull.SetSize(d.ped, 340, 128)
	d.ped:SetPoint("CENTER", d, "LEFT", cx, CARD_Y - ch / 2 - 36)
	d.pedGlow = d:CreateTexture(nil, "ARTWORK", nil, 1)
	d.pedGlow:SetTexture(MEDIA .. "Glow")
	d.pedGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(d.pedGlow, 330, 80)
	d.pedGlow:SetPoint("CENTER", d.ped, "CENTER", 0, 16)

	-- (held in a frame placed without an offset: brought closer, it stays in place)
	d.seat = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(d.seat, 1, 1)
	d.seat:SetPoint("CENTER", d, "LEFT", cx, CARD_Y)
	d.holder = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(d.holder, 1, 1)
	d.holder:SetPoint("CENTER", d.seat, "CENTER")
	local card = ns.NewCard(d.holder, "huge")
	card:SetPoint("CENTER", d.holder, "CENTER")
	ns.Inspect:Attach(card, d.holder, { zoom = { 0.85, 1.25, 1 } })
	d:EnableMouseWheel(true)
	-- (1.14.0, after its second test: the card shown, of a booster or of a case, UI/CaseDetail.lua)
	CuratorOctoFull.SetScript(d, "OnMouseWheel", function(_, delta)
		ns.Inspect:Zoom(d.card, delta)
	end)
	d.card, d.boosterCard = card, card
	d.hint = S.Text(d, "GameFontDisableSmall")
	d.hint:SetPoint("TOP", d.ped, "BOTTOM", 0, 18)
	d.hint:SetText(L["Drag to turn the card · Mouse wheel to zoom"])
	-- the motes of light of the best cards, rising from the socle
	local fx = CreateFrame("Frame", nil, d)
	fx:SetAllPoints()
	fx:SetFrameLevel(card:GetFrameLevel() + 14)
	d.fx = fx
	d.motes = ns.Particles:New(fx, 40)
	d.sparks = ns.Particles:New(fx, 40)

	-- what there is to know: a dark panel, lines of gold above and under it
	local x1 = x0 + cw + 40
	local textW = PAGE_W - 6 - x1 - 40
	d.panel = d:CreateTexture(nil, "BORDER", nil, 4)
	d.panel:SetPoint("TOPRIGHT", -18, -34)
	CuratorOctoFull.ColorTexture(d.panel, 0.01, 0.01, 0.03, 0.5)
	d.ruleTop = S.Divider(d, textW + 36, 1)
	d.ruleTop:SetPoint("BOTTOM", d.panel, "TOP", 0, 0)
	d.ruleBot = S.Divider(d, textW + 36, 1)
	d.ruleBot:SetPoint("TOP", d.panel, "BOTTOM", 0, 0)
	d.name = S.Text(d, "GameFontNormalHuge", "LEFT")
	d.name:SetPoint("TOPLEFT", x1, -60)
	d.name:SetWidth(textW)
	CuratorOctoFull.SetWordWrap(d.name, true)
	d.gem = d:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(d.gem, 22, 22)
	d.gem:SetPoint("TOPLEFT", d.name, "BOTTOMLEFT", -2, -9)
	d.rar = S.Text(d, "GameFontNormalLarge", "LEFT")
	d.rar:SetPoint("LEFT", d.gem, "RIGHT", 5, 0)
	-- (a legendary or mythic card: its entrance again, on the row of its rarity)
	d.replay = S.Button(d, L["Replay its entrance"], 180, 24)
	d.replay:SetPoint("LEFT", d.gem, "LEFT", textW + 2 - 180, 0)
	CuratorOctoFull.SetScript(d.replay, "OnClick", function(self)
		if d.shown then
			ns.Inspect:Replay(d.shown, d.finish, self, true)
		end
	end)
	d.line = S.Text(d, "GameFontHighlight", "LEFT")
	d.line:SetPoint("TOPLEFT", d.gem, "BOTTOMLEFT", 2, -10)
	d.rule = S.Divider(d, textW, 0.9)
	d.rule:SetPoint("TOPLEFT", d.line, "BOTTOMLEFT", 0, -12)
	d.copies = S.Text(d, "GameFontHighlight", "LEFT")
	d.copies:SetPoint("TOPLEFT", d.rule, "BOTTOMLEFT", 0, -12)
	d.shiny = S.Text(d, "GameFontHighlight", "LEFT")
	d.shiny:SetPoint("TOPLEFT", d.copies, "BOTTOMLEFT", 0, -8)
	d.shiny:SetTextColor(0.75, 0.75, 1)
	-- (1 November: the families of its titanforged copies, certified, A.PatternsText: on two lines rather than out of the page)
	d.shiny:SetWidth(textW)
	CuratorOctoFull.SetWordWrap(d.shiny, true)
	CuratorOctoFull.SetMaxLines(d.shiny, 2)
	d.found = S.Text(d, "GameFontHighlight", "LEFT")
	d.found:SetPoint("TOPLEFT", d.shiny, "BOTTOMLEFT", 0, -8)
	d.found:SetTextColor(0.8, 0.8, 0.8)
	-- its album: its emblem, its name, its number in it
	d.set = d:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(d.set, 22, 22)
	d.set:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", -2, -22)
	d.num = S.Text(d, "GameFontDisable", "LEFT")
	d.num:SetPoint("LEFT", d.set, "RIGHT", 6, 0)
	-- the copies to exchange, and the way to the contracts
	d.spare = S.Text(d, "GameFontHighlight", "LEFT")
	d.spare:SetPoint("TOPLEFT", d.set, "BOTTOMLEFT", 2, -14)
	d.spare:SetTextColor(1, 0.62, 0.5)
	d.trade = S.Button(d, L["Exchange them"], 130, 22)
	d.trade:SetPoint("LEFT", d.spare, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(d.trade, "OnClick", function()
		if d.shown then
			A:ContractFor(d.shown)
		end
	end)
	-- the card in the showcase of my profile, the card in the chat
	local bw = math.floor((textW - 10) / 2)
	d.pin = Hud.ClaimButton(d, bw, 30, L["Pin to showcase"])
	-- (the panel ends under the buttons)
	d.panel:SetPoint("BOTTOMLEFT", d.pin, "BOTTOMLEFT", -18, -46)
	CuratorOctoFull.SetScript(d.pin, "OnClick", function()
		A:TogglePin()
	end)
	d.link = S.Button(d, L["Show in the chat"], bw, 24)
	d.link:SetPoint("LEFT", d.pin, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(d.link, "OnClick", function()
		if d.shown then
			-- (1 November: the certificate of the copy shown with it, Mages.lua: UI/Copies.lua; 1.14.3: the copy itself)
			ns.Links:Insert(d.shown, d.finish, d.pattern, d.tc, A.mode ~= "member" and ns.CopiesUI and ns.CopiesUI:Selected(d.shown) or nil)
		end
	end)
	d.pinNote = S.Text(d, "GameFontHighlightSmall", "LEFT")
	d.pinNote:SetPoint("TOPLEFT", d.pin, "BOTTOMLEFT", 2, -8)
	d.pinNote:SetWidth(textW)
	CuratorOctoFull.SetWordWrap(d.pinNote, true)
	d.pinNote:SetTextColor(0.8, 0.8, 0.8)

	CuratorOctoFull.SetScript(d, "OnUpdate", function(_, elapsed)
		A.dt = (A.dt or 0) + elapsed
		-- the card in the hand; left alone a while, its creature turns slowly in it (1.14.0, after its second test: the
		-- card shown, of a booster or of a case; a card of a case moves of itself, UI/CrateCard.lua)
		local card = d.card
		local tn = card.turn
		if tn.dragging or tn.target or tn.vy ~= 0 then
			d.idle = 0
		else
			d.idle = (d.idle or 0) + elapsed
			if d.idle > 2.5 then
				card.turnFacing = (card.turnFacing or 0.4) + elapsed * 0.35
			end
		end
		ns.Inspect:Update(card, elapsed)
		if card.Tick then
			card:Tick(A.dt)
		end
		CuratorOctoFull.SetRotation(d.rays, A.dt * 0.1)
		CuratorOctoFull.SetRotation(d.rays2, -A.dt * 0.07)
		-- the light of the socle breathes; the best cards: motes of light rising
		d.pedGlow:SetAlpha((d.pedA or 0.3) * (0.8 + 0.2 * math.sin(A.dt * 2)))
		if (d.rarity or 1) >= 4 then
			d.moteT = (d.moteT or 0) - elapsed
			if d.moteT <= 0 then
				d.moteT = 0.32 - 0.05 * (d.rarity - 4)
				local mx = cx - (d:GetWidth() or 762) / 2
				d.motes:Rise(mx - 110, mx + 110, CARD_Y - ch / 2 - 12, d.glow or GOLD, 1, 300, 2.4, 14)
			end
		end
	end)
end

function A:ShowDetail(card, e)
	local d = self.detail
	e = e or C:Entry(card)
	local r = ns.RARITY[card.rarity]
	local s = card.series
	d.rarity = card.rarity
	d.glow = r.glow
	-- the photo of its place, cut to the page (the photos are twice as wide as tall)
	d.bg:SetTexture(MEDIA .. (s.studio or "StudioElwynn"))
	local w, h = d:GetWidth(), d:GetHeight()
	local u = ((w and h and h > 0) and (w / h) or 1.38) / 2
	d.bg:SetTexCoord(0.5 - u / 2, 0.5 + u / 2, 0, 1)
	-- (1.14.0: titanforged, the pattern of my copy that shows it, Copies.lua)
	local shownFinish = self:ShownFinish(e)
	d.pattern = self.mode ~= "member" and shownFinish == "holo" and ns.Copies and ns.Copies:PatternOf(card.key) or nil
	d.card:SetCard(card, { owned = true, finish = shownFinish, facing = 0.4,
		signed = self.mode ~= "member" and ns.Inns ~= nil and ns.Inns:IsSigned(card), pattern = d.pattern,
		wear = self.mode ~= "member" and ns.Wear and ns.Wear:Shown(card, shownFinish) or nil })
	d.card:ShowSide("front")
	ns.Inspect:Reset(d.card, 0, 1)
	d.halo:SetVertexColor(r.glow[1], r.glow[2], r.glow[3])
	d.rays:SetVertexColor(r.glow[1], r.glow[2], r.glow[3])
	d.pedGlow:SetVertexColor(0.6 + 0.4 * r.glow[1], 0.6 + 0.4 * r.glow[2], 0.6 + 0.4 * r.glow[3])
	d.pedA = 0.22 + 0.06 * card.rarity
	d.motes:Clear()
	d.sparks:Clear()
	d.moteT = 0.4
	d.gem:SetTexture(MEDIA .. "Gem" .. card.rarity)
	-- big title, a bit smaller for the longest names (still too long: it wraps)
	S.SetFontObject(d.name, "GameFontNormalHuge")
	d.name:SetText(C:Name(card))
	if ns.TextWidth(d.name) > d.name:GetWidth() * 0.98 then
		S.Fit(d.name, C:Name(card), d.name:GetWidth() * 0.98, 19, 15)
	end
	d.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	d.rar:SetText(L[r.label])
	d.rar:SetTextColor(r.text[1], r.text[2], r.text[3])
	-- (1.13.0: a card of a picture, the Hardcup Saison 3, has no entrance to play again)
	CuratorOctoFull.SetShown(d.replay, card.rarity >= 5 and not (card.art and card.art.fill))
	CuratorOctoFull.SetEnabled(d.replay, not (ns.Cinematic and ns.Cinematic:IsPlaying()))
	d.line:SetText(C:Line(card))
	d.set:SetTexture(MEDIA .. (s.set or "SetElwynn"))
	local g = s.glow or GOLD
	d.set:SetVertexColor(0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3])
	d.num:SetText(string.format(("%s · %d/%d"), C:SeriesName(s), card.num, s.official or CuratorOctoFull.Length(s.list)))
	d.shown, d.finish = card, self:ShownFinish(e)
	local mine = self.mode ~= "member"
	self:PaintCopies(card, e)
	-- (another player's card: in the chat, not in my showcase)
	CuratorOctoFull.SetShown(d.pin, mine)
	d.link:ClearAllPoints()
	if mine then
		d.link:SetPoint("LEFT", d.pin, "RIGHT", 10, 0)
	else
		d.link:SetPoint("BOTTOMLEFT", d.pin, "BOTTOMLEFT", 0, 3)
	end
	self:PaintPin()
	d.idle = 0
	-- it comes: the place fades in, the card rises onto its socle in a flash of its light, the rays
	-- of its rarity open behind it
	d:SetAlpha(0)
	d:Show()
	self:PaintBack()
	local rays = SHOW_RAYS[card.rarity] or 0
	d.rays:SetAlpha(0)
	d.rays2:SetAlpha(0)
	d.halo:SetAlpha(0)
	ns.Tween(0.2, function(k)
		d:SetAlpha(k)
	end, nil, Ease.outQuad, self)
	local c = d.card
	ns.Tween(0.45, function(k, raw)
		c:ClearAllPoints()
		c:SetPoint("CENTER", d.holder, "CENTER", 0, -26 * (1 - k))
		c:SetAlpha(math.min(1, raw * 3))
		d.rays:SetAlpha(rays * k)
		d.rays2:SetAlpha((card.rarity >= 6 and 0.3 or 0) * k)
		d.halo:SetAlpha((0.18 + 0.05 * card.rarity) * k)
	end, nil, Ease.outBack, self)
	ns.Delay(0.2, function()
		local x = 44 + c.W / 2 - (d:GetWidth() or 762) / 2
		local y = CARD_Y - c.H / 2 - 10
		d.sparks:Burst(x, y, r.glow, 8 + 3 * card.rarity, 160, 0.7, 16)
		if card.rarity >= 3 then
			c.hot:SetVertexColor(1, 1, 1)
			c.hot:SetAlpha(0.35 + 0.06 * card.rarity)
			ns.Tween(0.4, function(k)
				c.hot:SetAlpha((0.35 + 0.06 * card.rarity) * (1 - k))
			end, nil, Ease.outQuad, self)
		end
	end, self)
	ns.Delay(0.25, function()
		d.card:Animate(self)
		d.card:PlayVoice()
	end, self)
end

-- What the panel says of its copies (how many, their finishes, when it was found, those to exchange) and where the
-- buttons under it go: when it is shown, and again when they change under it (1.12.0: a corrupted copy sealed or
-- purified: UI/Seal.lua).
-- (1.14.0) The patterns of my titanforged copies of a card, the oldest first. (1 November, his word: their number told by
-- the masters of the mages only, Mages.lua: those certified, their family and their number, " (Saphir 245, Prisme 12)";
-- those not certified, how many: "": none certified.)
function A.PatternsText(key)
	local CP, MG = ns.Copies, ns.Mages
	if not (CP and MG) then
		return ""
	end
	local recs = {}
	for _, r in ipairs(CP:List(key)) do
		if CP.Pattern(r) then
			recs[CuratorOctoFull.Length(recs) + 1] = r
		end
	end
	table.sort(recs, function(x, y)
		return (x.i or 0) < (y.i or 0)
	end)
	local tags, waiting = {}, 0
	for _, r in ipairs(recs) do
		local tag = MG.Tag(r)
		if not tag then
			waiting = waiting + 1
		elseif CuratorOctoFull.Length(tags) < 4 then
			tags[CuratorOctoFull.Length(tags) + 1] = tag
		elseif CuratorOctoFull.Length(tags) == 4 then
			tags[CuratorOctoFull.Length(tags) + 1] = "..."
		end
	end
	if CuratorOctoFull.Length(tags) == 0 then
		return ""
	end
	if waiting > 0 then
		tags[CuratorOctoFull.Length(tags) + 1] = waiting == 1 and L["one not certified"] or string.format(L["%d not certified"], waiting)
	end
	return " (" .. table.concat(tags, ", ") .. ")"
end

function A:PaintCopies(card, e)
	local d = self.detail
	if not (d and card) then
		return
	end
	local mine = self.mode ~= "member"
	e = e or (mine and C:Entry(card)) or nil
	local parts = {}
	if e and (e.s or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = C:CopiesLine(card, "shiny", e.s)
	end
	if e and (e.h or 0) > 0 then
		-- (1.14.0: mine, the pattern of each, Copies.lua)
		parts[CuratorOctoFull.Length(parts) + 1] = C:CopiesLine(card, "holo", e.h) .. (mine and A.PatternsText(card.key) or "")
	end
	-- (1.12.0) its corrupted copies: the corruption of each (mine), how many (another player's)
	local corrupted = e and (tonumber(e.c) or 0) > 0
	if corrupted then
		local line = mine and C:CorruptLine(card) or ""
		parts[CuratorOctoFull.Length(parts) + 1] = line ~= "" and string.format(L["Corrupted copies: %s"], line) or C:CopiesLine(card, "corrupt", e.c)
	end
	local shiny = CuratorOctoFull.Length(parts) > 0
	d.copies:SetText(string.format(L["Copies: %d"], e and e.n or 0))
	d.shiny:SetText(table.concat(parts, "   ·   "))
	-- (the gold of the titans, or the blue of the lightning; 1.12.0: the violet of the Void)
	if e and (e.h or 0) > 0 then
		d.shiny:SetTextColor(1, 0.8, 0.42)
	elseif corrupted then
		d.shiny:SetTextColor(0.8, 0.48, 1)
	else
		d.shiny:SetTextColor(0.75, 0.75, 1)
	end
	-- no empty line when there is no shiny copy
	d.found:ClearAllPoints()
	d.found:SetPoint("TOPLEFT", shiny and d.shiny or d.copies, "BOTTOMLEFT", 0, -8)
	d.found:SetText((e and e.t) and string.format(L["Found on %s"], date("%d/%m/%Y", e.t)) or "")
	-- the copies to exchange (mine)
	local spare = mine and ns.Contract:SpareAll(card, ns.db.keepOne) or 0
	CuratorOctoFull.SetShown(d.spare, spare > 0)
	CuratorOctoFull.SetShown(d.trade, spare > 0)
	d.spare:SetText(string.format(L["Copies to exchange: %d"], spare))
	-- the buttons under what there is to know
	d.pin:ClearAllPoints()
	d.pin:SetPoint("TOPLEFT", spare > 0 and d.spare or d.set, "BOTTOMLEFT", spare > 0 and -2 or 0, -30)
end

function A:HideDetail()
	local d = self.detail
	if d and d:IsShown() then
		d.card.turn.dragging = false
		d:Hide()
		self:PaintBack()
		-- (the profile shows what was pinned or taken out)
		if self.mode == "profile" and self.frame:IsShown() then
			self:Refresh()
		end
	end
end

-- The button of the showcase: to pin the card, or to take it out.
function A:PaintPin(note)
	local d = self.detail
	local card = d.shown
	if not card then
		return
	end
	local pinned = C:Pinned(card)
	d.pin:SetLabel(pinned and L["Remove from showcase"] or L["Pin to showcase"])
	d.pinNote:SetText(note or (pinned and self.mode ~= "member" and L["In your showcase"]) or "")
end

function A:TogglePin()
	local d = self.detail
	local card = d.shown
	if not card then
		return
	end
	if C:Pinned(card) then
		C:Unpin(card)
		ns.Play(ns.SND.page)
		return self:PaintPin()
	end
	local ok, why = C:Pin(card)
	if ok then
		ns.Play(ns.SND.cardLand)
		return self:PaintPin()
	end
	ns.Play(ns.SND.close)
	self:PaintPin(why == "full" and L["Your showcase is full: remove a card from it first."] or nil)
end

-- Opens my album on a card: its page, and its detail when it is mine.
function A:ShowCard(card)
	self:Build()
	self.filter, self.found, self.finish = nil, nil, nil
	self:Open("mine", card.series)
	local i = 1
	for k, c in ipairs(self:Cards(card.series)) do
		if c == card then
			i = k
		end
	end
	self.page = math.ceil(i / PER_PAGE)
	self:Refresh()
	local e = C:Entry(card)
	if e and e.n > 0 then
		self:ShowDetail(card, e)
	end
end

-- (31 October, his word) A copy of a card shown big, that very copy (id: its number, Copies.lua): the card that just came,
-- as it came, its wear on it.
function A:ShowCopy(card, id)
	local CU = ns.CopiesUI
	if CU and id and ns.Copies and ns.Copies:Get(card.key, id) then
		-- (the copy asked for, as the inventory asks: the detail chooses its copy again when it opens, UI/Copies.lua)
		CU.sel[card.key] = id
		CU.pending = { key = card.key, id = id }
	end
	return self:ShowCard(card)
end

-------------------------------------------------------------------------------
-- Guild page: who shares their albums, best collections first.
-------------------------------------------------------------------------------
function A:BuildGuild()
	local f = self.frame
	local list = CreateFrame("Frame", nil, f.body)
	list:SetPoint("TOPLEFT", 16, -14)
	list:SetPoint("BOTTOMRIGHT", -16, PAGER)
	list:SetFrameLevel(f.body:GetFrameLevel() + 20)
	list:Hide()
	f.list = list
	list.rows = {}
	for i = 1, ROWS_PER_PAGE do
		local i = i; local r = S.ListButton(list)
		r:SetHeight(ROW_H - 8)
		r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
		r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
		-- their best card, tiny
		local card = ns.NewCard(r, "small")
		card:SetScale(0.34)
		card:SetPoint("LEFT", r, "LEFT", 26 / 0.34, 0)
		card:EnableMouse(false)
		card.shadow:SetAlpha(0.4)
		card.tiny = true
		r.card = card
		r.name = S.Text(r, "GameFontNormalLarge", "LEFT")
		r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 80, -11)
		r.points = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.points:SetPoint("LEFT", r.name, "RIGHT", 10, 0)
		r.best = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.best:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -6)
		-- progress: bar, count, legendaries, shiny cards
		local bar = S.ThinBar(r, 200, 9)
		bar:SetPoint("RIGHT", r, "RIGHT", -214, -6)
		r.bar = bar
		r.count = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.count:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 6)
		r.leg = r:CreateTexture(nil, "ARTWORK")
		r.leg:SetTexture(MEDIA .. "Gem5")
		CuratorOctoFull.SetSize(r.leg, 18, 18)
		r.leg:SetPoint("LEFT", bar, "RIGHT", 18, 0)
		r.legText = S.Text(r, "GameFontHighlight", "LEFT")
		r.legText:SetPoint("LEFT", r.leg, "RIGHT", 3, 0)
		r.myth = r:CreateTexture(nil, "ARTWORK")
		r.myth:SetTexture(MEDIA .. "Gem6")
		CuratorOctoFull.SetSize(r.myth, 18, 18)
		r.myth:SetPoint("LEFT", r.legText, "RIGHT", 10, 0)
		r.mythText = S.Text(r, "GameFontHighlight", "LEFT")
		r.mythText:SetPoint("LEFT", r.myth, "RIGHT", 3, 0)
		-- the shiny and holographic copies under the bar, where the longest languages fit
		r.shiny = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.shiny:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -5)
		r.shiny:SetPoint("RIGHT", r, "RIGHT", -10, 0)
		r.shiny:SetTextColor(0.75, 0.75, 1)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.member then
				ns.Play(ns.SND.cardFlip)
				A:ShowMember(self.member, A:Series())
			end
		end)
		list.rows[i] = r
	end
	list.empty = S.Text(list, "GameFontHighlight")
	list.empty:SetPoint("CENTER", 0, 20)
	list.empty:SetWidth(520)
	CuratorOctoFull.SetWordWrap(list.empty, true)
	CuratorOctoFull.SetScript(list, "OnUpdate", function(_, elapsed)
		A.lt = (A.lt or 0) + elapsed
		for _, r in ipairs(list.rows) do
			if r:IsShown() and r.card:IsShown() then
				r.card:Tick(A.lt)
			end
		end
	end)

	-- note over the page while a member's album is on its way (a box of the game's tooltips)
	local w = CreateFrame("Frame", nil, f.body, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(w, 420, 46)
	w:SetPoint("CENTER", f.body, "CENTER", 0, 10)
	w:SetFrameLevel(f.body:GetFrameLevel() + 40)
	w:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	w:SetBackdropColor(0, 0, 0, 0.9)
	w.text = S.Text(w, "GameFontHighlight")
	w.text:SetPoint("CENTER", 0, 0)
	w:Hide()
	f.wait = w
end

function A:RefreshGuild()
	local f = self.frame
	local s = self:Series()
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.wait:Hide()
	f.list:Show()
	self:SetTitle(C:SeriesName(s), self:SubLine(s))
	-- my own progress stays at the top right, to compare
	local owned, total, byRarity = C:Progress(s)
	self:SetBar(owned, total, string.format(L["%d / %d cards"], owned, total))
	local all = C.PerRarity(0)
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		all[r] = CuratorOctoFull.Length(s.byRarity[r])
	end
	self:SetCounts(byRarity, all)
	local members = ns.Guild:Members(s)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(members) / ROWS_PER_PAGE))
	self.listPage = math.max(1, math.min(self.listPage or 1, pages))
	for i, row in ipairs(f.list.rows) do
		local m = members[(self.listPage - 1) * ROWS_PER_PAGE + i]
		row.member = m and m.name
		CuratorOctoFull.SetShown(row, m ~= nil)
		if m then
			local sum = m.sum or { o = 0, n = s.official or CuratorOctoFull.Length(s.list), l = 0, sh = 0, my = 0 }
			row.name:SetText(m.short)
			if m.i then
				local title, tcol = ns.Achievements:TitleOf(m.i)
				-- (their level of collector, the emblem of its rank before it)
				local level = ""
				if m.i.xp then
					local lv = ns.Level.Of(m.i.xp)
					level = "  ·  " .. ns.Level.EmblemText((ns.Level.RankOf(lv)), 14) .. " " .. string.format(L["Level %d"], lv)
				end
				local line = "|cff" .. Hex(tcol) .. title .. "|r  ·  " .. string.format(L["%d points"], m.i.points) .. level
				S.SetFontObject(row.points, "GameFontHighlightSmall")
				row.points:SetText(line)
				-- (a long title, in the longest languages: a little smaller)
				local w = row.points:GetWidth()
				if w and w > 0 and ns.TextWidth(row.points) > w then
					S.Fit(row.points, line, w, 10, 8)
				end
			else
				row.points:SetText("")
			end
			local best = sum.best and ns.Cards[sum.best]
			if best then
				if row.card.card ~= best or not row.card:IsShown() then
					row.card:Show()
					row.card:SetCard(best, { owned = true })
					row.card:ShowSide("front")
				end
				row.card.phase = i * 0.5
				local rc = ns.RARITY[best.rarity].text
				row.best:SetText(C:Name(best))
				row.best:SetTextColor(rc[1], rc[2], rc[3])
			else
				row.card:Hide()
				row.best:SetText("")
			end
			row.count:SetText(string.format(L["%d / %d cards"], sum.o, sum.n))
			row.bar:SetProgress(sum.o / math.max(1, sum.n))
			row.legText:SetText(tostring(sum.l))
			row.mythText:SetText(tostring(sum.my or 0))
			local fin = {}
			if sum.sh > 0 then
				fin[CuratorOctoFull.Length(fin) + 1] = C:CopiesLine(nil, "shiny", sum.sh, s)
			end
			if (sum.ho or 0) > 0 then
				fin[CuratorOctoFull.Length(fin) + 1] = C:CopiesLine(nil, "holo", sum.ho, s)
			end
			row.shiny:SetText(table.concat(fin, "  ·  "))
		end
	end
	if CuratorOctoFull.Length(members) == 0 then
		f.list.empty:SetText(IsInGuild() and L["No guild member shares an album yet. They need Curator too!"] or L["You are not in a guild."])
	else
		f.list.empty:SetText("")
	end
	self:SetPager(self.listPage, pages)
	self:RefreshFooter(false)
end

-------------------------------------------------------------------------------
-- Contents page (1.13.0): the albums by kind, a tab each: the zones (by level, a filter by continent), the
-- dungeons, the raids, the PvP (the combatants, the albums of the battlegrounds, the exploits: UI/Pvp.lua) and the
-- events (the limited editions: Hallow's End, the Hardcup Saison 3). Each tab a grid of its tiles (an album each:
-- its photo, its emblem, the ring of its progress, the seal of gold of an album complete, its boosters waiting, its
-- new cards), six a row, four rows a page. (Before 1.13.0: a page per band of levels, three columns.)
-------------------------------------------------------------------------------
local TOC_TABS = {
	{ key = "zones", label = "Zones", icon = "Interface\\Icons\\INV_Misc_Map_01" },
	{ key = "dungeons", label = "Dungeons", icon = "Interface\\Icons\\INV_Misc_Key_10" },
	{ key = "raids", label = "Raids", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
	-- (mine only: what another player sends of their collection holds nothing of their PvP)
	{ key = "pvp", label = "PvP", icon = "Interface\\Icons\\INV_BannerPVP_02", mine = true },
	{ key = "events", label = "Events", icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" },
	-- (1.14.0, after its first test: the collections of the cases, a tile each, UI/CaseAlbum.lua; mine only)
	{ key = "cases", label = "Cases", icon = "Interface\\Icons\\INV_Crate_03", mine = true },
}
A.TOC_TABS = TOC_TABS
local TOC_TAB = {}
for i, t in ipairs(TOC_TABS) do
	TOC_TAB[t.key] = i
end
-- the filters of the zones: every continent, the Eastern Kingdoms, Kalimdor, the islands of no continent (Zephras)
local CONTS = { "all", "EK", "K", "isles" }
local CONT_RANK = { EK = 1, K = 2, isles = 3 }
local TOC_COLS, TOC_ROWS = 6, 4
local TOC_PER = TOC_COLS * TOC_ROWS
A.TOC_PER = TOC_PER
local TOC_W = PAGE_W - 2 * PAD
local TILE_W, TILE_H = 112, 96
local TILE_GX, TILE_GY = (TOC_W - TOC_COLS * TILE_W) / (TOC_COLS - 1), 15
local TILE_ROW = TILE_H + TILE_GY
-- (the photos of the albums are twice as wide as tall: the whole of it, in all the width of the tile)
local PHOTO_H = (TILE_W - 10) / 2
local TAB_H, TAB_GAP = 26, 6
local CHIP_H, CHIP_GAP = 20, 6
-- the line under the tabs (the filters of the zones, else a word of the tab), then the grid
local LINE_Y = -(TAB_H + 8)
local GRID_Y = LINE_Y - CHIP_H - 8
local HERE = { 0.55, 0.85, 1 }
-- (the PvP: its albums, a tile each; the photo of the combatants and of the exploits, those of the battlegrounds
-- from the album of the zone they are in, UI/Pvp.lua)
local PVP_TILES = {
	{ view = "combat", studio = "StudioBurning" },
	{ view = "bgs", bg = "wsg" },
	{ view = "bgs", bg = "ab" },
	{ view = "bgs", bg = "av" },
	{ view = "feats", studio = "StudioStranglethorn", lv = 10 },
}

-- The tab of an album, and its continent (a zone's: the islands are of none).
local function TabOf(s)
	return ((s.event or s.limited) and "events") or (s.raid and "raids") or (s.dungeon and "dungeons") or "zones"
end
local function ContOf(s)
	return (s.cont == "EK" and "EK") or (s.cont == "K" and "K") or "isles"
end
A.TocTabOf, A.TocContOf = TabOf, ContOf

-- The name of a filter of the zones.
local function ContName(cont)
	if cont == "EK" then
		return MapName(1415, L["Eastern Kingdoms"])
	elseif cont == "K" then
		return MapName(1414, L["Kalimdor"])
	elseif cont == "isles" then
		return L["Islands"]
	end
	return L["All zones"]
end

-- (the page of a tab is kept for each tab, and for each filter of the zones)
local function PageKey(tab, cont)
	return tab == "zones" and ("zones:" .. (cont or "all")) or tab
end

-- The tile of an album.
local function NewTile(toc)
	local Hud = ns.Hud
	local t = CreateFrame("Button", nil, toc)
	CuratorOctoFull.SetSize(t, TILE_W, TILE_H)
	Hud.Panel(t, TILE_H)
	-- the light of the place you are in, around it
	t.here = Hud.Sliced(t, "QuestGlow", TILE_H, Hud.GlowOut(TILE_H), "BORDER", 1, "ADD")
	Hud.Each(t.here, "SetVertexColor", HERE[1], HERE[2], HERE[3])
	Hud.Each(t.here, "SetAlpha", 0)
	-- the photo of the album
	t.photo = t:CreateTexture(nil, "ARTWORK")
	t.photo:SetPoint("TOPLEFT", 5, -5)
	t.photo:SetPoint("TOPRIGHT", -5, -5)
	t.photo:SetHeight(PHOTO_H)
	t.vig = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.vig:SetAllPoints(t.photo)
	t.vig:SetTexture(MEDIA .. "Vignette")
	t.vig:SetAlpha(0.8)
	t.hl = t:CreateTexture(nil, "HIGHLIGHT")
	t.hl:SetAllPoints(t.photo)
	CuratorOctoFull.ColorTexture(t.hl, 1, 0.95, 0.8, 0.12)
	t.hl:SetBlendMode("ADD")
	-- its emblem, on a dark round
	t.setBg = t:CreateTexture(nil, "ARTWORK", nil, 2)
	t.setBg:SetTexture(MEDIA .. "CircleMask")
	t.setBg:SetVertexColor(0, 0, 0)
	t.setBg:SetAlpha(0.6)
	CuratorOctoFull.SetSize(t.setBg, 24, 24)
	t.setBg:SetPoint("TOPLEFT", t.photo, "TOPLEFT", 2, -2)
	t.set = t:CreateTexture(nil, "ARTWORK", nil, 3)
	CuratorOctoFull.SetSize(t.set, 18, 18)
	t.set:SetPoint("CENTER", t.setBg, "CENTER")
	-- the ring of its progress on the corner of the photo; the seal of gold once it is complete
	local top = CreateFrame("Frame", nil, t)
	top:SetAllPoints()
	top:SetFrameLevel(t:GetFrameLevel() + 3)
	t.top = top
	t.ringBg = top:CreateTexture(nil, "ARTWORK")
	t.ringBg:SetTexture(MEDIA .. "CircleMask")
	t.ringBg:SetVertexColor(0.02, 0.02, 0.04)
	t.ringBg:SetAlpha(0.85)
	CuratorOctoFull.SetSize(t.ringBg, 30, 30)
	t.ringBg:SetPoint("CENTER", t.photo, "BOTTOMRIGHT", -17, 15)
	t.ring = Hud.Ring(top, 34, "ARTWORK", 1)
	t.ring:SetPoint("CENTER", t.ringBg, "CENTER")
	t.pct = Hud.Text(top, 8, "OUTLINE", "OVERLAY", 2)
	t.pct:SetPoint("CENTER", t.ringBg, "CENTER", 0.5, 0)
	t.seal = top:CreateTexture(nil, "OVERLAY", nil, 3)
	t.seal:SetTexture(MEDIA .. "AlbumSeal")
	CuratorOctoFull.SetSize(t.seal, 46, 46)
	t.seal:SetPoint("CENTER", t.ringBg, "CENTER", 0, 4)
	-- its new cards: the red pennant of the cards, how many
	t.new = CreateFrame("Frame", nil, top)
	CuratorOctoFull.SetSize(t.new, 44, 44 * 96 / 256)
	t.new:SetPoint("TOPRIGHT", t.photo, "TOPRIGHT", 3, 2)
	t.new.tex = t.new:CreateTexture(nil, "ARTWORK")
	t.new.tex:SetAllPoints()
	t.new.tex:SetTexture(MEDIA .. "TagNew")
	t.new.text = Hud.Text(t.new, 9, "", "OVERLAY")
	t.new.text:SetPoint("CENTER", 44 * (145 / 256 - 0.5), 0.5)
	t.new.text:SetTextColor(1, 0.95, 0.82)
	-- its name and its progress, under the photo
	t.name = S.Text(t, "GameFontNormal", "LEFT")
	t.name:SetPoint("TOPLEFT", 7, -5 - PHOTO_H - 5)
	t.name:SetWidth(TILE_W - 14)
	CuratorOctoFull.SetWordWrap(t.name, false)
	t.count = S.Text(t, "GameFontHighlightSmall", "LEFT")
	t.count:SetPoint("TOPLEFT", 7, -5 - PHOTO_H - 21)
	t.lv = S.Text(t, "GameFontDisableSmall", "LEFT")
	t.lv:SetPoint("LEFT", t.count, "RIGHT", 6, 0)
	-- boosters waiting: the pack of the album, how many
	t.packB = t:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(t.packB, 8, 16)
	t.packB:SetPoint("BOTTOMRIGHT", -20, 6)
	t.packT = t:CreateTexture(nil, "ARTWORK", nil, 1)
	CuratorOctoFull.SetSize(t.packT, 8, 16 * 64 / 512)
	t.packT:SetPoint("TOP", t.packB, "TOP")
	t.packs = S.Text(t, "NumberFontNormalSmall", "LEFT")
	t.packs:SetPoint("LEFT", t.packB, "RIGHT", 2, -2)
	CuratorOctoFull.SetScript(t, "OnClick", function(self)
		if self.series then
			ns.Play(ns.SND.page)
			if A.member then
				A:ShowMember(A.member, self.series)
			else
				A:ShowSeries(self.series)
			end
		elseif self.pvp then
			-- (the PvP page, on that album; Back comes back here)
			ns.Play(ns.SND.page)
			A:ShowPvp(self.pvp.view, self.pvp.bg)
			A.tocReturn = true
			A:PaintTabs()
		elseif self.caseKey and A.ShowCases then
			-- (1.14.0, after its first test: the album of a collection of the cases; Back comes back here)
			ns.Play(ns.SND.page)
			A:ShowCases(self.caseKey, "collection")
			A.tocReturn = true
			A:PaintTabs()
		end
	end)
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		A:ContentsTooltip(self)
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return t
end

-- A filter of the zones: a small button, gold when chosen.
local function NewChip(toc)
	local b = CreateFrame("Button", nil, toc)
	b:SetHeight(CHIP_H)
	b.edge = b:CreateTexture(nil, "BACKGROUND")
	b.edge:SetAllPoints()
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.bg:SetPoint("TOPLEFT", 1, -1)
	b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints(b.bg)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.1)
	b.text = S.Text(b, "GameFontHighlightSmall")
	b.text:SetPoint("CENTER", 0, 0)
	function b:Paint(text, on)
		self.text:SetText(text)
		self:SetWidth(math.max(48, math.ceil(ns.TextWidth(self.text)) + 22))
		self.on = on
		if on then
			CuratorOctoFull.ColorTexture(self.edge, 1, 0.8, 0.32, 0.95)
			CuratorOctoFull.ColorTexture(self.bg, 0.26, 0.18, 0.05, 0.95)
			self.text:SetTextColor(1, 1, 1)
		else
			CuratorOctoFull.ColorTexture(self.edge, 0.55, 0.45, 0.25, 0.55)
			CuratorOctoFull.ColorTexture(self.bg, 0.06, 0.05, 0.04, 0.9)
			self.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
		end
	end
	return b
end

function A:BuildContents()
	local f = self.frame
	local Hud = ns.Hud
	local toc = CreateFrame("Frame", nil, f.body)
	toc:SetPoint("TOPLEFT", PAD, -10)
	toc:SetPoint("BOTTOMRIGHT", -PAD, PAGER)
	toc:SetFrameLevel(f.body:GetFrameLevel() + 20)
	toc:Hide()
	f.toc = toc
	-- the tabs, across the top of the page
	toc.tabs = {}
	for i, def in ipairs(TOC_TABS) do
		local i, def = i, def; local b = Hud.NavButton(toc, (TOC_W - (CuratorOctoFull.Length(TOC_TABS) - 1) * TAB_GAP) / CuratorOctoFull.Length(TOC_TABS), TAB_H)
		b.key = def.key
		Hud.SetIcon(b.icon, { def.icon })
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			A:SetTocTab(self.key)
		end)
		toc.tabs[i] = b
	end
	-- under them: the filters of the zones, or a word of the tab
	toc.chips = {}
	for i, cont in ipairs(CONTS) do
		local i, cont = i, cont; local b = NewChip(toc)
		b.cont = cont
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			A:SetTocCont(self.cont)
		end)
		toc.chips[i] = b
	end
	toc.word = S.Text(toc, "GameFontDisableSmall", "LEFT")
	CuratorOctoFull.SetWordWrap(toc.word, false)
	-- the grid of the tiles
	toc.rows = {}
	for i = 1, TOC_PER do
		local t = NewTile(toc)
		t:SetPoint("TOPLEFT", toc, "TOPLEFT", (CuratorOctoFull.Mod((i - 1) , TOC_COLS)) * (TILE_W + TILE_GX), GRID_Y - math.floor((i - 1) / TOC_COLS) * TILE_ROW)
		t:Hide()
		toc.rows[i] = t
	end
	toc.empty = S.Text(toc, "GameFontDisable")
	toc.empty:SetPoint("TOP", toc, "TOP", 0, GRID_Y - 120)
	-- the light of the place you are in breathes
	toc.t = 0
	CuratorOctoFull.SetScript(toc, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		local a = 0.45 + 0.3 * math.sin(self.t * 3)
		for _, t in ipairs(self.rows) do
			if t.isHere and t:IsShown() then
				ns.Hud.Each(t.here, "SetAlpha", a)
			end
		end
	end)
end

-- The tabs shown: every one, but the PvP with another player's collection (and without the PvP of the addon).
function A:TocTabs()
	local out = {}
	for _, def in ipairs(TOC_TABS) do
		if not (def.mine and self.member) and not (def.key == "pvp" and not (ns.Pvp and ns.PvpUI))
			and not (def.key == "cases" and not (ns.Cases and self.RefreshCases)) then
			out[CuratorOctoFull.Length(out) + 1] = def.key
		end
	end
	return out
end

-- The albums of a tab (the zones: of a filter), in the order of its pages: the zones by level (then the Eastern
-- Kingdoms, Kalimdor, the islands), the dungeons by level, the raids in the order of the game, the events as they
-- came; the PvP, its albums ({ view, bg }).
function A:TocList(tab, cont)
	if tab == "pvp" then
		return PVP_TILES
	end
	-- (the cases: their collections, { case }, the one of now first)
	if tab == "cases" then
		local out = {}
		for _, k in ipairs(ns.Cases and ns.Cases:Editions() or {}) do
			out[CuratorOctoFull.Length(out) + 1] = { case = k }
		end
		return out
	end
	local out = {}
	for _, s in ipairs(self:Order()) do
		if TabOf(s) == tab and (tab ~= "zones" or cont == nil or cont == "all" or ContOf(s) == cont) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	if tab == "zones" then
		table.sort(out, function(a, b)
			if a.levels[1] ~= b.levels[1] then
				return a.levels[1] < b.levels[1]
			end
			if a.levels[2] ~= b.levels[2] then
				return a.levels[2] < b.levels[2]
			end
			if CONT_RANK[ContOf(a)] ~= CONT_RANK[ContOf(b)] then
				return CONT_RANK[ContOf(a)] < CONT_RANK[ContOf(b)]
			end
			return a.key < b.key
		end)
	end
	return out
end

-- The contents on the tab and the page of an album (the filter of the zones kept when the album is in it, else
-- every continent).
function A:TocAt(s)
	local tab = TabOf(s)
	self.tocTab = tab
	local cont
	if tab == "zones" then
		cont = self.tocCont or "all"
		if cont ~= "all" and ContOf(s) ~= cont then
			cont = "all"
		end
		self.tocCont = cont
	end
	self.tocPages = self.tocPages or {}
	for i, x in ipairs(self:TocList(tab, cont)) do
		if x == s then
			self.tocPages[PageKey(tab, cont)] = math.ceil(i / TOC_PER)
			return
		end
	end
end

-- Where the contents open: the tab and the page of the album of the place you are in (in a dungeon or a raid,
-- theirs); elsewhere, the zones, on the page of the first one that still has levels for you.
function A:TocHome()
	local here = ns.Rewards and ns.Rewards:ZoneSeries()
	if here then
		return self:TocAt(here)
	end
	self.tocTab = "zones"
	local cont = self.tocCont or "all"
	self.tocCont = cont
	local level = (UnitLevel and tonumber(UnitLevel("player"))) or 1
	local list, at = self:TocList("zones", cont), 1
	for i, s in ipairs(list) do
		at = i
		if s.levels[2] >= level then
			break
		end
	end
	self.tocPages = self.tocPages or {}
	self.tocPages[PageKey("zones", cont)] = math.ceil(at / TOC_PER)
end

-- Another tab; another filter of the zones (each on the page it was left on).
function A:SetTocTab(tab)
	if self.tocTab == tab or not TOC_TAB[tab] then
		return
	end
	self.tocTab = tab
	ns.Play(ns.SND.page)
	self:Refresh()
end

function A:SetTocCont(cont)
	if self.tocTab == "zones" and (self.tocCont or "all") == cont then
		return
	end
	self.tocTab, self.tocCont = "zones", cont
	ns.Play(ns.SND.page)
	self:Refresh()
end

-- The tab shown, its filter, its albums, its pages and the page shown.
function A:TocView()
	local tab = self.tocTab
	local cont = tab == "zones" and (self.tocCont or "all") or nil
	local list = self:TocList(tab, cont)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / TOC_PER))
	self.tocPages = self.tocPages or {}
	local key = PageKey(tab, cont)
	local page = math.max(1, math.min(pages, self.tocPages[key] or 1))
	self.tocPages[key] = page
	return tab, cont, list, page, pages
end

-- The arrows of the pages (and the wheel of the mouse), on the contents.
function A:TocPage(delta)
	if not self.tocTab then
		return
	end
	local tab, cont, _, page, pages = self:TocView()
	local p = math.max(1, math.min(pages, page + delta))
	if p ~= page then
		self.tocPages[PageKey(tab, cont)] = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The new cards of the albums of a tab (mine).
function A:TocFresh(tab)
	if tab == "pvp" or tab == "cases" then
		return 0
	end
	local n = 0
	for _, s in ipairs(self:TocList(tab)) do
		n = n + C:FreshCount(s)
	end
	return n
end

function A:ContentsTooltip(row)
	-- (1.14.0, after its first test: a collection of the cases)
	if row.caseKey then
		local CS = ns.Cases
		local case = row.caseKey
		local owned, total, weapons = CS:Progress(case)
		GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
		GameTooltip:AddLine(row.name:GetText() or "", GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 1, 1, 1)
		if weapons > 0 then
			GameTooltip:AddLine(string.format(L["Weapons of legend: %d"], weapons), 1, 0.84, 0.26)
		end
		GameTooltip:AddLine(string.format(L["Cases to open: %d  ·  Keys: %d"], CS:Count(case), CS:Keys(case)), 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Its cards come out of its cases only, and are exchanged between them only."], 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine(L["Click to open"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
		return
	end
	local x = row.pvp
	if x then
		-- (an album of the PvP)
		local P, UI = ns.Pvp, ns.PvpUI
		GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
		GameTooltip:AddLine(row.name:GetText() or "", GOLD[1], GOLD[2], GOLD[3])
		if x.view == "combat" then
			GameTooltip:AddLine(string.format(L["Combatants in your album: %d"], P:CardCount()), 1, 1, 1)
			GameTooltip:AddLine(L["Your honorable kills become trophies. A battlemaster certifies them, pays you each week and keeps the war board."], 0.8, 0.8, 0.8, true)
		elseif x.view == "bgs" then
			local n, total = P:BgProgress(x.bg)
			GameTooltip:AddLine(string.format(L["%d / %d cards"], n, total), 1, 1, 1)
			GameTooltip:AddLine((P:Enemy() or "Horde") == "Horde" and L["A combatant of each race and class of the Horde, defeated in this battleground."]
				or L["A combatant of each race and class of the Alliance, defeated in this battleground."], 0.8, 0.8, 0.8, true)
		else
			GameTooltip:AddLine(string.format(L["Exploits: %d / %d"], P:FeatCount(), CuratorOctoFull.Length(P.FEATS)), 1, 1, 1)
			GameTooltip:AddLine(L["A battleground a row: its victory, its objective, its defense. The score at the end of each match counts them."], 0.8, 0.8, 0.8, true)
		end
		GameTooltip:AddLine(L["Click to open"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
		return
	end
	local s = row.series
	if not s then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:SeriesName(s), GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:AddLine(self:SubLine(s), 0.8, 0.8, 0.8)
	if self.member then
		-- the other player's album: what their summary tells
		local sum = ns.Guild:Summary(self.member, s)
		GameTooltip:AddLine(string.format(L["%d / %d cards"], sum and sum.o or 0, s.official or CuratorOctoFull.Length(s.list)), 1, 1, 1)
		if sum and (sum.my or 0) > 0 then
			local rr = ns.RARITY[6]
			GameTooltip:AddLine(string.format(("%s %d/%d"), L[rr.label], sum.my, CuratorOctoFull.Length(s.byRarity[6])), rr.text[1], rr.text[2], rr.text[3])
		end
		if sum and sum.l > 0 then
			local rr = ns.RARITY[5]
			GameTooltip:AddLine(string.format(("%s %d/%d"), L[rr.label], sum.l, CuratorOctoFull.Length(s.byRarity[5])), rr.text[1], rr.text[2], rr.text[3])
		end
		GameTooltip:AddLine(L["Click to view"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
		return
	end
	local owned, total, byRarity = C:Progress(s)
	GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 1, 1, 1)
	if owned >= total and total > 0 then
		GameTooltip:AddLine(L["Album complete!"], 1, 0.84, 0.3)
	end
	local fresh = C:FreshCount(s)
	if fresh > 0 then
		GameTooltip:AddLine(string.format(L["New cards: %d"], fresh), 1, 0.45, 0.35)
	end
	-- the finest cards found there
	for r = CuratorOctoFull.Length(ns.RARITY), 5, -1 do
		if byRarity[r] > 0 then
			local rr = ns.RARITY[r]
			GameTooltip:AddLine(string.format(("%s %d/%d"), L[rr.label], byRarity[r], CuratorOctoFull.Length(s.byRarity[r])), rr.text[1], rr.text[2], rr.text[3])
		end
	end
	local packs = ns.Packs(s)
	if packs > 0 then
		GameTooltip:AddLine(string.format(L["Boosters: %d"], packs), 1, 1, 1)
	end
	local spare = ns.Contract:SpareIn(s, ns.db.keepOne)
	if spare > 0 then
		GameTooltip:AddLine(string.format(L["Copies to exchange: %d"], spare), 1, 0.62, 0.5)
	end
	-- (1.13.0: a limited edition of no booster, the Hardcup Saison 3: where its cards come from)
	if s.limited and s.from then
		GameTooltip:AddLine(L[s.from], 0.8, 0.8, 0.8, true)
	end
	if ns.Rewards:Target() == s then
		GameTooltip:AddLine(string.format(L["Next booster: %d%%"], math.floor(100 * ns.Rewards:Bar(ns.Rewards:Here()) / ns.PACK_POINTS)), 0.8, 0.8, 0.8)
	end
	local inst = ns.Rewards:InstanceSeries()
	if inst and ns.Rewards:FarmSeries(inst) == s then
		GameTooltip:AddLine(string.format(L["Boosters earned in %s go to this album."], C:SeriesName(inst)), 1, 1, 1, true)
	end
	if row.isHere then
		GameTooltip:AddLine(L["You are here"], 0.1, 1, 0.1)
	end
	GameTooltip:AddLine(L["Click to open"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

-- The ring of a tile: its progress (none: total nil), or the seal of gold once complete.
local function PaintRing(t, o, total)
	local complete = total ~= nil and total > 0 and o >= total
	local p = o / math.max(1, total or 1)
	t.ring:SetProgress(p)
	CuratorOctoFull.SetShown(t.ring, total ~= nil and not complete)
	CuratorOctoFull.SetShown(t.ringBg, total ~= nil and not complete)
	CuratorOctoFull.SetShown(t.pct, total ~= nil and not complete and o > 0)
	t.pct:SetText(string.format(("%d%%"), math.floor(p * 100)))
	CuratorOctoFull.SetShown(t.seal, complete)
	ns.Hud.Each(t.glow, "SetAlpha", complete and 0.75 or 0)
	return complete
end

-- The name of a tile, made smaller to fit.
local function TileName(t, text)
	S.SetFontObject(t.name, "GameFontNormal")
	t.name:SetText(text)
	if ns.TextWidth(t.name) > TILE_W - 14 then
		S.Fit(t.name, text, TILE_W - 14, 11.5, 8)
	end
end

function A:FillContentsRow(t, s, here)
	local Hud = ns.Hud
	local o, total
	if self.member then
		local sum = ns.Guild:Summary(self.member, s)
		o, total = sum and math.min(sum.o, s.official or CuratorOctoFull.Length(s.list)) or 0, s.official or CuratorOctoFull.Length(s.list)
	else
		o, total = C:Progress(s)
	end
	t.series, t.pvp, t.caseKey = s, nil, nil
	t.isHere = s == here
	t.set:Show()
	if t.crate then
		t.crate:Hide()
	end
	-- (1.13.0: a picture of its own for its tile, the Hardcup Saison 3; else its studio)
	t.photo:SetTexture(MEDIA .. (s.tile or s.studio or "StudioElwynn"))
	t.photo:SetTexCoord(0, 1, 0, 1)
	t.set:SetTexture(MEDIA .. (s.set or "SetElwynn"))
	local g = s.glow or GOLD
	t.set:SetVertexColor(0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3])
	TileName(t, C:SeriesName(s))
	local complete = PaintRing(t, o, total)
	t.complete = complete
	if t.isHere then
		t.name:SetTextColor(1, 1, 1)
	elseif complete then
		t.name:SetTextColor(1, 0.88, 0.45)
	else
		t.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	end
	t.count:SetText(string.format(("%d/%d"), o, total))
	if complete then
		t.count:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	else
		t.count:SetTextColor(1, 1, 1)
	end
	-- (1.12.0: an album of an event, its time left in the place of its levels; 1.13.0: a limited edition of no
	-- event of the game, the Hardcup Saison 3, so)
	if s.event then
		local H = ns.Hallow
		t.lv:SetText((H and H:On()) and ns.Duration(H:Left()) or L["Limited edition"])
	elseif s.limited then
		t.lv:SetText(L["Limited edition"])
	else
		t.lv:SetText(s.levels[1] == s.levels[2] and tostring(s.levels[1]) or string.format(("%d-%d"), s.levels[1], s.levels[2]))
	end
	Hud.Each(t.here, "SetAlpha", t.isHere and 0.6 or 0)
	-- boosters waiting, new cards (mine only)
	local packs = self.member and 0 or ns.Packs(s)
	local pack = s.pack or "PackElwynn"
	t.packB:SetTexture(MEDIA .. pack .. "Bottom")
	t.packT:SetTexture(MEDIA .. pack .. "Top")
	CuratorOctoFull.SetShown(t.packB, packs > 0)
	CuratorOctoFull.SetShown(t.packT, packs > 0)
	t.packs:SetText(packs > 0 and tostring(packs) or "")
	local fresh = self.member and 0 or C:FreshCount(s)
	CuratorOctoFull.SetShown(t.new, fresh > 0)
	t.new.text:SetText("+" .. fresh)
	t:Show()
end

-- (1.13.0) The tile of an album of the PvP: the combatants (no end to them: how many), an album of a battleground,
-- the exploits.
function A:FillPvpTile(t, x)
	local P, UI = ns.Pvp, ns.PvpUI
	local o, total, name, studio, lv
	if x.view == "combat" then
		o, name = P:CardCount(), L["Combatants"]
	elseif x.view == "bgs" then
		o, total = P:BgProgress(x.bg)
		name = UI.BattlegroundName(x.bg)
		local home = ns.SeriesByKey(UI.FEAT_STUDIO[x.bg] or "")
		studio = home and home.studio
		lv = UI.FEAT_LEVEL[x.bg]
	else
		o, total, name = P:FeatCount(), CuratorOctoFull.Length(P.FEATS), L["Exploits"]
	end
	t.series, t.pvp, t.isHere, t.caseKey = nil, x, false, nil
	t.set:Show()
	if t.crate then
		t.crate:Hide()
	end
	t.photo:SetTexture(MEDIA .. (studio or x.studio or "StudioElwynn"))
	t.photo:SetTexCoord(0, 1, 0, 1)
	t.set:SetTexture(MEDIA .. "SetPvp")
	t.set:SetVertexColor(1, 0.92, 0.7)
	TileName(t, name)
	local complete = PaintRing(t, o, total)
	t.complete = complete
	t.name:SetTextColor(complete and 1 or GOLD[1], complete and 0.88 or GOLD[2], complete and 0.45 or GOLD[3])
	t.count:SetText(total and string.format(("%d/%d"), o, total) or tostring(o))
	if complete then
		t.count:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	else
		t.count:SetTextColor(1, 1, 1)
	end
	lv = lv or x.lv
	t.lv:SetText(lv and string.format(("%d-60"), lv) or "")
	ns.Hud.Each(t.here, "SetAlpha", 0)
	t.packB:Hide()
	t.packT:Hide()
	t.packs:SetText("")
	t.new:Hide()
	t:Show()
end

-- (1.14.0, after its first test) The tile of a collection of the cases (UI/CaseAlbum.lua): its case seen from above, the
-- crate on its corner, the cards of its collection won (each once) on its ring, its cases to open.
function A:FillCaseTile(t, x)
	local CS = ns.Cases
	local case = x.case
	local def = ns.Crates and ns.Crates[case]
	local art = def and def.art and def.art.box
	local owned, total = CS:Progress(case)
	t.series, t.pvp, t.isHere, t.caseKey = nil, nil, false, case
	-- (its top: 1024 by 596 of its texture, the middle of it twice as wide as tall)
	t.photo:SetTexture(MEDIA .. (art and ns.CaseTexture(art .. "Top") or "CrateTop"))
	t.photo:SetTexCoord(0, 1, 42 / 1024, 554 / 1024)
	t.set:Hide()
	if not t.crate then
		t.crate = t:CreateTexture(nil, "ARTWORK", nil, 3)
		CuratorOctoFull.SetSize(t.crate, 18, 18)
		t.crate:SetPoint("CENTER", t.setBg, "CENTER")
		t.crate:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		local round = CuratorOctoFull.CreateMaskTexture(t)
		round:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		round:SetAllPoints(t.crate)
		CuratorOctoFull.AddMaskTexture(t.crate, round)
	end
	t.crate:SetTexture("Interface\\Icons\\INV_Crate_03")
	t.crate:Show()
	TileName(t, L[(CS.COLLECTION and CS.COLLECTION[case]) or "Paladin Collection 2026"])
	local complete = PaintRing(t, owned, total)
	t.complete = complete
	t.name:SetTextColor(complete and 1 or GOLD[1], complete and 0.88 or GOLD[2], complete and 0.45 or GOLD[3])
	t.count:SetText(string.format(("%d/%d"), owned, total))
	if complete then
		t.count:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	else
		t.count:SetTextColor(1, 1, 1)
	end
	local n = CS:Count(case)
	t.lv:SetText(n > 0 and string.format(L["To open: %d"], n) or "")
	ns.Hud.Each(t.here, "SetAlpha", 0)
	t.packB:Hide()
	t.packT:Hide()
	t.packs:SetText("")
	t.new:Hide()
	t:Show()
end

-- The cards of the albums of a tab: owned and total, by rarity, and the albums complete (another player's: from
-- what they send, their legendary and mythic cards only by rarity; the PvP: its places and its exploits).
function A:TocCounts(tab, list, member)
	local owned, total, done = 0, 0, 0
	local byRarity, all = C.PerRarity(0), C.PerRarity(0)
	-- (1.14.0, after its first test: the collections of the cases, their cards each once)
	if tab == "cases" then
		for _, x in ipairs(list) do
			local o, t = ns.Cases:Progress(x.case)
			owned, total = owned + o, total + t
			if t > 0 and o >= t then
				done = done + 1
			end
		end
		return owned, total, byRarity, all, done
	end
	if tab == "pvp" then
		local P = ns.Pvp
		for _, bg in ipairs(P.BG_ORDER) do
			local n, t = P:BgProgress(bg)
			owned, total = owned + n, total + t
			if t > 0 and n >= t then
				done = done + 1
			end
		end
		owned, total = owned + P:FeatCount(), total + CuratorOctoFull.Length(P.FEATS)
		return owned, total, byRarity, all, done
	end
	for _, s in ipairs(list) do
		local o, br
		if member then
			local sum = ns.Guild:Summary(member, s)
			o = sum and math.min(sum.o, s.official or CuratorOctoFull.Length(s.list)) or 0
			br = C.PerRarity(0)
			br[5], br[6] = sum and sum.l or 0, sum and sum.my or 0
			all[5], all[6] = all[5] + CuratorOctoFull.Length(s.byRarity[5]), all[6] + CuratorOctoFull.Length(s.byRarity[6])
		else
			local _
			o, _, br = C:Progress(s)
			for r = 1, CuratorOctoFull.Length(ns.RARITY) do
				all[r] = all[r] + CuratorOctoFull.Length(s.byRarity[r])
			end
		end
		for r = 1, CuratorOctoFull.Length(ns.RARITY) do
			byRarity[r] = byRarity[r] + br[r]
		end
		owned, total = owned + o, total + (s.official or CuratorOctoFull.Length(s.list))
		if (s.official or CuratorOctoFull.Length(s.list)) > 0 and o >= (s.official or CuratorOctoFull.Length(s.list)) then
			done = done + 1
		end
	end
	return owned, total, byRarity, all, done
end

-- The tabs across the top (another player's collection: no PvP), each lit when chosen, the new cards of its albums
-- on it (mine).
function A:PaintTocTabs()
	local toc = self.frame.toc
	local keys = self:TocTabs()
	local shown = {}
	for _, key in ipairs(keys) do
		shown[key] = true
	end
	local tw = (TOC_W - (CuratorOctoFull.Length(keys) - 1) * TAB_GAP) / CuratorOctoFull.Length(keys)
	local i = 0
	for _, b in ipairs(toc.tabs) do
		CuratorOctoFull.SetShown(b, shown[b.key] == true)
		if shown[b.key] then
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", toc, "TOPLEFT", i * (tw + TAB_GAP), 0)
			CuratorOctoFull.SetSize(b, tw, TAB_H)
			b.width = tw
			i = i + 1
			b:Paint(b.key == self.tocTab, L[TOC_TABS[TOC_TAB[b.key]].label], "", self.member and 0 or self:TocFresh(b.key))
		end
	end
end

-- The line under the tabs: the filters of the zones (and their order), else what the tab holds.
local TOC_WORDS = {
	zones = "By level",
	dungeons = "By level. A booster of a dungeon: 5 cards, each rare, epic or legendary.",
	raids = "In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary.",
	pvp = "Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it.",
	events = "Limited editions: their cards come only from their event, and count in no total of the collection.",
	cases = "The collections of the cases: their cards come out of the cases only, and are exchanged between them only.",
}
function A:PaintTocLine(tab, cont)
	local toc = self.frame.toc
	local x = 0
	for _, b in ipairs(toc.chips) do
		CuratorOctoFull.SetShown(b, tab == "zones")
		if tab == "zones" then
			b:Paint(ContName(b.cont), b.cont == cont)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", toc, "TOPLEFT", x, LINE_Y)
			x = x + b:GetWidth() + CHIP_GAP
		end
	end
	toc.word:ClearAllPoints()
	toc.word:SetText(L[TOC_WORDS[tab] or ""] or "")
	if tab == "zones" then
		toc.word:SetJustifyH("RIGHT")
		toc.word:SetPoint("RIGHT", toc, "TOPRIGHT", 0, LINE_Y - CHIP_H / 2)
		toc.word:SetWidth(math.max(40, TOC_W - x - 10))
	else
		toc.word:SetJustifyH("LEFT")
		toc.word:SetPoint("LEFT", toc, "TOPLEFT", 2, LINE_Y - CHIP_H / 2)
		toc.word:SetWidth(TOC_W - 4)
	end
end

function A:RefreshContents()
	local f = self.frame
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.list:Hide()
	f.wait:Hide()
	f.toc:Show()
	local member = self.member
	-- (the tab of the place you are in the first time; another player's collection: their zones, from the first)
	local tabs = {}
	for _, key in ipairs(self:TocTabs()) do
		tabs[key] = true
	end
	if not (self.tocTab and tabs[self.tocTab]) then
		if member then
			self.tocTab, self.tocPages = "zones", {}
		else
			self:TocHome()
		end
	end
	local tab, cont, list, page, pages = self:TocView()
	self.tocPage = page
	self:PaintTocTabs()
	self:PaintTocLine(tab, cont)
	-- the tiles of the page
	local here = not member and ns.Rewards and ns.Rewards:ZoneSeries() or nil
	local toc = f.toc
	for i, t in ipairs(toc.rows) do
		local x = list[(page - 1) * TOC_PER + i]
		if x and tab == "pvp" then
			self:FillPvpTile(t, x)
		elseif x and tab == "cases" then
			self:FillCaseTile(t, x)
		elseif x then
			self:FillContentsRow(t, x, here)
		else
			t.series, t.pvp, t.isHere, t.caseKey = nil, nil, false, nil
			t:Hide()
		end
	end
	toc.empty:SetText(CuratorOctoFull.Length(list) == 0 and L["No album here yet."] or "")
	-- the head: the tab (and its filter), its albums complete, the cards of its albums, by rarity
	local title = L[TOC_TABS[TOC_TAB[tab]].label]
	if cont and cont ~= "all" then
		title = title .. " · " .. ContName(cont)
	end
	local owned, total, byRarity, all, done = self:TocCounts(tab, list, member)
	if member then
		-- another player's collection: their achievement points, while it comes
		local i = ns.Guild:Profile(member)
		local short = ns.Guild:Short(member)
		self:SetTitle(title, i and string.format(L["%d achievement points"], i.points) or "")
		local waiting = not i and not next((ns.Guild:Player(member) or { s = {} }).s)
		CuratorOctoFull.SetShown(f.wait, waiting)
		if waiting then
			local late = self.asked and GetTime() - self.asked > 5
			f.wait.text:SetText(late and string.format(L["%s did not answer (offline?)"], short) or string.format(L["Waiting for %s..."], short))
		end
	elseif tab == "pvp" then
		self:SetTitle(title, string.format(L["Combatants in your album: %d"], ns.Pvp:CardCount()))
	else
		self:SetTitle(title, string.format(L["Albums complete: %d / %d"], done, CuratorOctoFull.Length(list)))
	end
	self:SetBar(owned, total, string.format(L["%d / %d cards"], owned, total))
	self:SetCounts(byRarity, all)
	-- (the collections of the cases: no rarity of the albums)
	if tab == "cases" then
		for _, b in ipairs(f.counts) do
			b:Hide()
		end
	end
	-- footer: the pages of the tab, every booster waiting (opened from the album of the place you are in first)
	self:ShowPager(true)
	self:SetPager(page, pages)
	local packs = ns.TotalPacks()
	CuratorOctoFull.SetShown(f.boosters, not member)
	f.boosters:SetText(string.format(L["Boosters: %d"], packs))
	f.gauge:Hide()
	CuratorOctoFull.SetShown(f.open, not member)
	CuratorOctoFull.SetEnabled(f.open, packs > 0 and not (ns.Reroll and ns.Reroll:NoOpening()))
	f.open:SetLabel(packs > 0 and L["Open a booster"] or L["No booster to open"])
	-- every new card seen at once, while there are some (mine)
	CuratorOctoFull.SetShown(f.seeAll, not member and C:FreshCount() > 0)
	local inst = not member and ns.Rewards:InstanceSeries() or nil
	if inst then
		f.boosters:Hide()
		self:PaintFarm(inst)
	end
end

-- Every card of every album, by rarity: owned (mine, or another player's from their summaries), total,
-- owned by rarity, total by rarity.
function A:AllCounts(member)
	local owned, total = 0, 0
	local byRarity, all = C.PerRarity(0), C.PerRarity(0)
	for _, s in ipairs(ns.Series) do
		-- (1.12.0: an album of an event counts in no total, Hallow.lua; 1.13.0: a limited edition neither)
		if not s.event and not s.limited then
			total = total + (s.official or CuratorOctoFull.Length(s.list))
			for r = 1, CuratorOctoFull.Length(ns.RARITY) do
				all[r] = all[r] + CuratorOctoFull.Length(s.byRarity[r])
			end
			if member then
				local sum = ns.Guild:Summary(member, s)
				owned = owned + (sum and math.min(sum.o, s.official or CuratorOctoFull.Length(s.list)) or 0)
			else
				local o, _, br = C:Progress(s)
				owned = owned + o
				for r = 1, CuratorOctoFull.Length(ns.RARITY) do
					byRarity[r] = byRarity[r] + br[r]
				end
			end
		end
	end
	return owned, total, byRarity, all
end

-- The head of the window: every card of every album of mine (its bar, the counters of the rarities).
function A:SetAllCounts()
	local owned, total, byRarity, all = self:AllCounts()
	self:SetBar(owned, total, string.format(L["%d / %d cards"], owned, total))
	self:SetCounts(byRarity, all)
end

-- The pages where rewards are claimed and land (the quests, the achievements, the track of the levels
-- in the profile): what changes there waits for them.
function A:ClaimsPage()
	return self.mode == "quests" or self.mode == "ach" or (self.mode == "profile" and not self.member)
end

-- Shows the album as it is set (mode, series), or refreshes it when it is already open.
function A:Reveal()
	-- (a beta build past its day: no album)
	if ns.Beta and ns.Beta:Blocked() then
		self:Hide()
		return
	end
	if self.frame:IsShown() then
		self:Refresh()
	else
		self.frame:Show()
		ns.Play(ns.SND.open)
	end
	-- the first time: the guided tour (UI/Tour.lua)
	if ns.Tour then
		ns.Tour:Offer()
	end
end

-- Opens the album on a page: "contents", or an album ("mine", "guild").
function A:Open(mode, s)
	self:Build()
	self.mode = mode or "mine"
	self.series = s or self.series or ns.CurrentSeries()
	self.member, self.memberEntries, self.returnMode, self.achOrder, self.achPage = nil, nil, nil, nil, 1
	self.page, self.listPage, self.tocReturn = 1, 1, nil
	-- (1.12.0) the talents open on their tree (not on the contract of reconversion left open, nor a preview)
	self.talView = nil
	self:HideDetail()
	if self.mode == "guild" then
		ns.Guild:Query()
	end
	self:Reveal()
end

function A:ShowSeries(s, mode)
	self:Open(mode or "mine", s)
end

-- The album of the place you are in, else the contents (/curator album).
function A:ShowHere()
	self:Build()
	if self.frame:IsShown() then
		return
	end
	local here = ns.Rewards and ns.Rewards:ZoneSeries()
	if here then
		self:Open("mine", here)
	else
		self:Open("contents")
	end
end

-- The album as it opens by itself (the minimap button, /curator): since the first test of 1.13.0, the inventory on its
-- boosters (UI/Inventory.lua); the album of the place you are in before.
function A:Show()
	return self:ShowHere()
end

function A:Hide()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
		ns.Play(ns.SND.close)
	end
end

function A:Toggle()
	self:Build()
	if self.frame:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end

-- (/curator album) The album of the place you are in, or closed.
function A:ToggleHere()
	self:Build()
	if self.frame:IsShown() then
		self:Hide()
	else
		self:ShowHere()
	end
end

-- A player asked by a name typed in lower case answers with their own: the album follows it.
for _, e in ipairs({ "PLAYER_INFO", "GUILD_CHANGED" }) do
	local _, e = _, e; ns.On(e, function(name)
		if A.member and name and A.member ~= name and ns.Guild.Fold(A.member) == ns.Guild.Fold(name) then
			A.member = name
		end
		if A.member and A.member == name then
			A:Seen(name)
		end
	end)
end
