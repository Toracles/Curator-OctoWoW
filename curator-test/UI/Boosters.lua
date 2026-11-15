local octoConstants = {}
local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
octoConstants.MEDIA = ns.MEDIA
local C = ns.Collection
local A = ns.Album
local LV = ns.Level
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease

-- The page of the boosters, in the album. On the left, the booster of the place you are in, big, on the
-- photo of its place, standing on its pedestal in a light from above: how many wait, the gauge of the
-- next one, the button that opens one (in a dungeon or a raid: the album its boosters go to). On the
-- right, the boosters of the other albums (a click opens one), then the boosters to choose (the levels
-- and the quests give them) and the albums to put them in. The (i) of a booster tells its odds: each
-- rarity, the finishes (in the dungeons and the raids, thunderforged and titanforged).
octoConstants.FEAT_W = 300                   -- the booster of the place
local X1 = octoConstants.FEAT_W + 16               -- the right part
-- (1.13.0, after its first test: the page a part of the inventory, under the bar of its filters; all a little smaller)
-- (1.14.0: the page redone, after the test: both bars and the cards of the album under the booster, the boosters of
-- the other albums with how much of their album is found, how the boosters come while there are none)
octoConstants.PACK_W, octoConstants.PACK_TOP = 104, -34    -- the big booster
octoConstants.PED_W = 190                    -- its pedestal
octoConstants.TILE_W, octoConstants.TILE_H, octoConstants.TILE_GAP, octoConstants.TILE_COLS, octoConstants.TILE_ROWS = 132, 166, 6, 3, 2
octoConstants.GRID_Y = -50
octoConstants.STOCK_H = 110
-- the albums to choose: three a row, three rows
octoConstants.PICK_COLS, octoConstants.PICK_ROWS, octoConstants.PICK_W, octoConstants.PICK_H, octoConstants.PICK_GAP = 3, 3, 124, 96, 8
octoConstants.PICK_Y = -94
octoConstants.GOLDEN = { 1, 0.8, 0.32 }
-- (1.14.2) the light of a tile of golden boosters, standing (A:PaintGrid)
octoConstants.GILT_LIGHT = 0.45
octoConstants.DIM = { 0.62, 0.62, 0.68 }
octoConstants.HERE = { 0.55, 0.85, 1 }
octoConstants.KIND_LABEL = { zone = "Zones: %d", dungeon = "Dungeons: %d", raid = "Raids: %d", golden = "Golden: %d" }
octoConstants.SLOT_LABEL = { zone = "Zone", dungeon = "Dungeon", raid = "Raid", golden = "Golden" }
octoConstants.FINISH_NAME = { thunder = "Thunderforged", titan = "Titanforged" }
-- the odds: the rows of the rarities, of the finishes
octoConstants.ODD_ROWS = 6

local Each = Hud.Each

-- (1.14.0, after its test, his word) This character a reroll: it uses no booster to choose, neither puts one in an
-- album nor buys one (Reroll.lua: RR:Blocks).
local function ChoiceBlocked()
	return ns.Reroll ~= nil and ns.Reroll:Blocks("choice")
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- The (i) of a booster: its tooltip, a click shows its odds.
local function Info(parent, size, s)
	local b = Hud.InfoButton(parent, size)
	b.s = s
	b.tip = function(self)
		local x = self.s or (parent.series)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Odds of this booster"], octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
		if x then
			GameTooltip:AddLine(C:SeriesName(x), 1, 1, 1)
		end
		GameTooltip:AddLine(L["Click to see them"], 0.3, 1, 0.3)
		GameTooltip:Show()
	end
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		local x = self.s or parent.series
		if x then
			A:ShowOdds(x)
		end
	end)
	return b
end

-- A booster of another album: the photo of its place, its booster standing in front, how many wait,
-- its name and its levels, its (i). A click opens one.
local function NewTile(page)
	local t = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(t, octoConstants.TILE_W, octoConstants.TILE_H)
	Hud.Panel(t, octoConstants.TILE_H)
	t.photo = t:CreateTexture(nil, "ARTWORK")
	t.photo:SetPoint("TOPLEFT", 6, -6)
	t.photo:SetPoint("TOPRIGHT", -6, -6)
	t.photo:SetHeight(60)
	-- (the photos are twice as wide as tall: a little of their sides cut)
	local cut = math.max(0, (1 - ((octoConstants.TILE_W - 12) / 60) / 2) / 2)
	t.photo:SetTexCoord(cut, 1 - cut, 0, 1)
	t.vig = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.vig:SetAllPoints(t.photo)
	t.vig:SetTexture(octoConstants.MEDIA .. "Vignette")
	t.vig:SetAlpha(0.9)
	t.setBg = t:CreateTexture(nil, "ARTWORK", nil, 2)
	t.setBg:SetTexture(octoConstants.MEDIA .. "CircleMask")
	t.setBg:SetVertexColor(0, 0, 0)
	t.setBg:SetAlpha(0.6)
	CuratorOctoFull.SetSize(t.setBg, 24, 24)
	t.setBg:SetPoint("TOPLEFT", t.photo, "TOPLEFT", 2, -2)
	t.set = t:CreateTexture(nil, "ARTWORK", nil, 3)
	CuratorOctoFull.SetSize(t.set, 18, 18)
	t.set:SetPoint("CENTER", t.setBg, "CENTER")
	t.pack = Hud.Pack(t, 42)
	t.pack:SetPoint("CENTER", t, "TOP", 0, -66)
	t.count = Hud.Text(t.pack.art, 15, "OUTLINE", "OVERLAY", 3)
	t.count:SetPoint("LEFT", t.pack.art, "BOTTOMRIGHT", 3, 12)
	t.count:SetTextColor(1, 0.86, 0.45)
	t.name = S.Text(t, "GameFontNormal")
	t.name:SetPoint("TOP", 0, -113)
	t.name:SetWidth(octoConstants.TILE_W - 12)
	CuratorOctoFull.SetWordWrap(t.name, false)
	t.lv = S.Text(t, "GameFontDisableSmall")
	t.lv:SetPoint("TOP", t.name, "BOTTOM", 0, -3)
	t.lv:SetWidth(octoConstants.TILE_W - 12)
	CuratorOctoFull.SetWordWrap(t.lv, false)
	-- (1.14.0) how much of its album is found: a thin bar, its share beside it
	t.prog = CreateFrame("Frame", nil, t)
	CuratorOctoFull.SetSize(t.prog, octoConstants.TILE_W - 56, 6)
	t.prog:SetPoint("BOTTOMLEFT", 12, 12)
	t.prog.bg = t.prog:CreateTexture(nil, "BACKGROUND")
	t.prog.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(t.prog.bg, 0, 0, 0, 0.6)
	t.prog.fill = t.prog:CreateTexture(nil, "ARTWORK")
	t.prog.fill:SetPoint("TOPLEFT")
	t.prog.fill:SetPoint("BOTTOMLEFT")
	CuratorOctoFull.ColorTexture(t.prog.fill, 1, 0.8, 0.32, 0.9)
	t.prog.edge = t.prog:CreateTexture(nil, "BORDER")
	t.prog.edge:SetPoint("TOPLEFT", -1, 1)
	t.prog.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(t.prog.edge, 0.45, 0.34, 0.16, 0.9)
	t.pct = S.Text(t, "GameFontHighlightSmall", "RIGHT")
	t.pct:SetPoint("RIGHT", t, "BOTTOMRIGHT", -10, 15)
	t.pct:SetWidth(36)
	t.hl = t:CreateTexture(nil, "HIGHLIGHT")
	t.hl:SetPoint("TOPLEFT", 4, -4)
	t.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(t.hl, 1, 0.9, 0.6, 0.07)
	t.info = Info(t, 22)
	t.info:SetPoint("TOPRIGHT", -4, -4)
	t.info:SetFrameLevel(t:GetFrameLevel() + 6)
	t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(t, "OnClick", function(self, button)
		-- (1.14.2: a golden booster, the first of its album that came)
		if self.gold then
			return A:OpenGolden(self.gold.s, "boosters")
		end
		-- (1.14.0: a right click, all of them)
		A:OpenFrom(self.series, button == "RightButton")
	end)
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		Each(self.glow, "SetAlpha", 0.55)
		A:LiftPack(self.pack, 5)
		if self.gold then
			return A:GoldenTooltip(self, self.gold.s, self.gold.n)
		end
		A:BoosterTooltip(self, self.series)
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function(self)
		-- (a golden booster: its light of gold stays a little)
		Each(self.glow, "SetAlpha", self.gold and octoConstants.GILT_LIGHT or 0)
		A:LiftPack(self.pack, 0)
		GameTooltip:Hide()
	end)
	return t
end

-- A choice among a few (the kinds of boosters to choose): dark, lit in gold when chosen.
local function NewToggle(parent, w, h)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, w, h)
	b.bg = Hud.Sliced(b, "QuestCard", h, 0, "BACKGROUND")
	b.glow = Hud.Sliced(b, "QuestGlow", h, Hud.GlowOut(h), "BORDER", 0, "ADD")
	Each(b.glow, "SetVertexColor", octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 3, -3)
	b.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.08)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, h + 2, h + 2)
	b.icon:SetPoint("LEFT", 6, 0)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", h + 10, 0)
	function b:SetSelected(on)
		Each(self.glow, "SetAlpha", on and 0.85 or 0)
		self.on = on
		self:Paint()
	end
	function b:Paint()
		if not self:IsEnabled() then
			self.text:SetTextColor(0.5, 0.5, 0.5)
			CuratorOctoFull.SetDesaturated(self.icon, true)
		else
			local c = self.on and { 1, 1, 1 } or S.GOLD
			self.text:SetTextColor(c[1], c[2], c[3])
			CuratorOctoFull.SetDesaturated(self.icon, false)
		end
	end
	return b
end

-- A tile of an album to choose: its picture, the mark of its set, its name; lit in gold when chosen.
local function NewPickTile(parent)
	local t = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(t, octoConstants.PICK_W, octoConstants.PICK_H)
	t.bg = Hud.Sliced(t, "QuestCard", octoConstants.PICK_H, 0, "BACKGROUND")
	t.photo = t:CreateTexture(nil, "ARTWORK")
	t.photo:SetPoint("TOPLEFT", 7, -7)
	t.photo:SetPoint("BOTTOMRIGHT", -7, 26)
	t.set = t:CreateTexture(nil, "ARTWORK", nil, 2)
	CuratorOctoFull.SetSize(t.set, 22, 22)
	t.set:SetPoint("BOTTOMRIGHT", t.photo, "BOTTOMRIGHT", -2, 2)
	t.glow = Hud.Sliced(t, "QuestGlow", octoConstants.PICK_H, Hud.GlowOut(octoConstants.PICK_H), "OVERLAY", 0, "ADD")
	Each(t.glow, "SetVertexColor", octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	t.flash = t:CreateTexture(nil, "OVERLAY", nil, 1)
	t.flash:SetAllPoints(t.photo)
	CuratorOctoFull.ColorTexture(t.flash, 1, 0.86, 0.5, 1)
	t.flash:SetBlendMode("ADD")
	t.flash:SetAlpha(0)
	t.hl = t:CreateTexture(nil, "HIGHLIGHT")
	t.hl:SetAllPoints(t.photo)
	CuratorOctoFull.ColorTexture(t.hl, 1, 1, 1, 0.1)
	t.name = S.Text(t, "GameFontHighlightSmall")
	t.name:SetPoint("BOTTOM", 0, 9)
	t.name:SetWidth(octoConstants.PICK_W - 12)
	CuratorOctoFull.SetWordWrap(t.name, false)
	CuratorOctoFull.SetScript(t, "OnClick", function(self)
		A:PickTile(self)
	end)
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		A:TileTooltip(self)
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return t
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
function A:BuildBoosters()
	local f = self.frame
	if f.boost then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	-- (1.13.0, after its first test: a part of the inventory, under the bar of its filters: UI/Inventory.lua)
	local bar = ns.InventoryUI and ns.InventoryUI.BAR_H or 0
	page:SetPoint("TOPLEFT", 16, -10 - bar)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.boost = page
	page.h = U.PAGE_H - 20 - bar
	local W = U.PAGE_W - 32
	local rw = W - X1
	page.rw = rw

	-- the booster of the place, on the photo of its place
	local ft = CreateFrame("Frame", nil, page)
	ft:SetPoint("TOPLEFT")
	ft:SetPoint("BOTTOMLEFT")
	ft:SetWidth(octoConstants.FEAT_W)
	-- (its lights stay in it)
	if ft.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(ft, true)
	end
	page.feat = ft
	ft.photo = ft:CreateTexture(nil, "BACKGROUND")
	ft.photo:SetPoint("TOPLEFT", 2, -2)
	ft.photo:SetPoint("BOTTOMRIGHT", -2, 2)
	ft.shade = ft:CreateTexture(nil, "BACKGROUND", nil, 1)
	ft.shade:SetAllPoints(ft.photo)
	CuratorOctoFull.ColorTexture(ft.shade, 0.03, 0.03, 0.07, 0.5)
	ft.vig = ft:CreateTexture(nil, "BACKGROUND", nil, 2)
	ft.vig:SetAllPoints(ft.photo)
	ft.vig:SetTexture(octoConstants.MEDIA .. "Vignette")
	-- (darker under the texts)
	ft.foot = ft:CreateTexture(nil, "BACKGROUND", nil, 3)
	ft.foot:SetPoint("BOTTOMLEFT", ft.photo, "BOTTOMLEFT")
	ft.foot:SetPoint("BOTTOMRIGHT", ft.photo, "BOTTOMRIGHT")
	ft.foot:SetHeight(220)
	CuratorOctoFull.ColorTexture(ft.foot, 0, 0, 0, 0.42)
	ft.frame = Hud.Card(ft, 0.75, "BORDER", 0, true)
	ft.edge = ft:CreateTexture(nil, "BORDER", nil, 2)
	ft.edge:SetTexture(octoConstants.MEDIA .. "Edge")
	ft.edge:SetBlendMode("ADD")
	ft.edge:SetAllPoints(ft.photo)
	ft.edge:SetVertexColor(1, 0.76, 0.3)
	ft.edge:SetAlpha(0.22)
	-- where it is
	ft.where = S.Text(ft, "GameFontNormal")
	ft.where:SetPoint("TOP", 0, -13)
	ft.where:SetWidth(octoConstants.FEAT_W - 30)
	CuratorOctoFull.SetWordWrap(ft.where, false)
	-- its light from above, its pedestal, the booster standing on it
	ft.spot = ft:CreateTexture(nil, "BORDER", nil, 3)
	ft.spot:SetTexture(octoConstants.MEDIA .. "Spotlight")
	ft.spot:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(ft.spot, 230, 320)
	ft.spot:SetPoint("TOP", 0, -20)
	ft.spot:SetAlpha(0.3)
	local packBottom = octoConstants.PACK_TOP - octoConstants.PACK_W * 2
	ft.pedestal = ft:CreateTexture(nil, "ARTWORK")
	ft.pedestal:SetTexture(octoConstants.MEDIA .. "Pedestal")
	CuratorOctoFull.SetSize(ft.pedestal, octoConstants.PED_W, octoConstants.PED_W / 2)
	-- (the middle of its top at the foot of the booster)
	ft.pedestal:SetPoint("TOP", 0, packBottom + 8 + octoConstants.PED_W * 0.185)
	ft.pack = Hud.Pack(ft, octoConstants.PACK_W, true)
	ft.pack:SetPoint("TOP", 0, octoConstants.PACK_TOP)
	ft.pack.bob = 3
	ft.count = Hud.Text(ft.pack.art, 22, "OUTLINE", "OVERLAY", 3)
	ft.count:SetPoint("LEFT", ft.pack.art, "BOTTOMRIGHT", 4, 22)
	ft.count:SetTextColor(1, 0.86, 0.45)
	ft.info = Info(ft, 26)
	ft.info:SetPoint("CENTER", ft.pack, "TOPRIGHT", 22, -8)
	ft.info:SetFrameLevel(ft:GetFrameLevel() + 8)
	-- (the pack opens one too)
	ft.hit = CreateFrame("Button", nil, ft)
	ft.hit:SetAllPoints(ft.pack)
	ft.hit:SetFrameLevel(ft:GetFrameLevel() + 6)
	CuratorOctoFull.SetScript(ft.hit, "OnClick", function()
		A:OpenFrom(ft.series)
	end)
	CuratorOctoFull.SetScript(ft.hit, "OnEnter", function(self)
		A:BoosterTooltip(self, ft.series)
	end)
	CuratorOctoFull.SetScript(ft.hit, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- its name, its levels, how many wait
	ft.name = S.Text(ft, "GameFontNormalLarge")
	ft.name:SetPoint("TOP", 0, packBottom - 44)
	ft.name:SetWidth(octoConstants.FEAT_W - 24)
	CuratorOctoFull.SetWordWrap(ft.name, false)
	ft.sub = S.Text(ft, "GameFontHighlightSmall")
	ft.sub:SetPoint("TOP", ft.name, "BOTTOM", 0, -4)
	ft.sub:SetTextColor(0.8, 0.8, 0.84)
	ft.packs = S.Text(ft, "GameFontHighlight")
	ft.packs:SetPoint("TOP", ft.sub, "BOTTOM", 0, -6)
	-- (1.14.0) the cards of its album found: a bar, their count in it
	ft.prog = Hud.XPBar(ft, 216, 12, { 0.42, 0.88, 0.56 })
	ft.prog:SetPoint("TOP", ft.packs, "BOTTOM", 0, -10)
	ft.prog:EnableMouse(true)
	CuratorOctoFull.SetScript(ft.prog, "OnEnter", function(self)
		if ft.series then
			local owned, total = C:Progress(ft.series)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(C:SeriesName(ft.series), octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
			GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 1, 1, 1)
			GameTooltip:AddLine(L["Click: the album"], 0.3, 1, 0.3)
			GameTooltip:Show()
		end
	end)
	CuratorOctoFull.SetScript(ft.prog, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(ft.prog, "OnMouseUp", function()
		if ft.series then
			ns.Play(ns.SND.page)
			A:ShowSeries(ft.series)
		end
	end)
	-- the buttons that open one, or all of them (1.14.0: ten at most at once, UI/OpenAll.lua)
	ft.open = Hud.ClaimButton(ft, 168, 36, L["Open a booster"])
	ft.open:SetPoint("BOTTOMLEFT", 16, 12)
	CuratorOctoFull.SetScript(ft.open, "OnClick", function()
		A:OpenFrom(ft.series)
	end)
	-- (1.14.0, after its test, his word: a reroll opens none; the buttons off, why in their tooltip: Reroll.lua)
	local function RerollTip(self)
		if ft.blocked and ns.Reroll then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(ns.Reroll:Why(), 1, 0.62, 0.45, true)
			GameTooltip:Show()
		end
	end
	ft.open.tip = RerollTip
	for _, b in ipairs({ ft.open }) do
		if b.SetMotionScriptsWhileDisabled then
			CuratorOctoFull.SetMotionScriptsWhileDisabled(b, true)
		end
	end
	ft.all = Hud.ClaimButton(ft, 96, 36, L["All"])
	ft.all:SetPoint("BOTTOMRIGHT", -16, 12)
	CuratorOctoFull.SetScript(ft.all, "OnClick", function()
		A:OpenFrom(ft.series, true)
	end)
	if ft.all.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(ft.all, true)
	end
	CuratorOctoFull.SetScript(ft.all, "OnEnter", function(self)
		if self:IsEnabled() then
			self.hot:SetAlpha(1)
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Open all"], 1, 1, 1)
		GameTooltip:AddLine(L["The boosters of this album one after the other, ten at most, then all their cards on the screen."], 0.85, 0.85, 0.85, true)
		if ft.blocked and ns.Reroll then
			GameTooltip:AddLine(ns.Reroll:Why(), 1, 0.62, 0.45, true)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(ft.all, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- (1.14.0) the two booster bars: the world's, the one of the dungeons and the raids, each with its words over it
	local function Gauge(kind, y, tint)
		local g = Hud.XPBar(ft, 268, 12, tint)
		g:SetPoint("BOTTOM", 0, y)
		g:EnableMouse(true)
		CuratorOctoFull.SetScript(g, "OnEnter", function(self)
			A:GaugeTooltip(self, kind)
		end)
		CuratorOctoFull.SetScript(g, "OnLeave", function()
			GameTooltip:Hide()
		end)
		g.left = S.Text(ft, "GameFontHighlightSmall", "LEFT")
		g.left:SetPoint("BOTTOMLEFT", g, "TOPLEFT", 0, 4)
		g.right = S.Text(ft, "GameFontHighlightSmall", "RIGHT")
		g.right:SetPoint("BOTTOMRIGHT", g, "TOPRIGHT", 0, 4)
		g.right:SetWidth(150)
		CuratorOctoFull.SetWordWrap(g.right, false)
		g.kind = kind
		return g
	end
	ft.gauge = Gauge("world", 104, { 1, 0.74, 0.25 })
	ft.gauge2 = Gauge("dungeon", 62, { 0.5, 0.68, 1 })
	-- (the names the other pieces know them by)
	ft.next, ft.today = ft.gauge.left, ft.gauge2.right
	-- in a dungeon or a raid: the album its boosters go to (in the place of how many wait)
	ft.farmLabel = S.Text(ft, "GameFontHighlightSmall")
	ft.farmLabel:SetPoint("TOP", ft.sub, "BOTTOM", 0, -9)
	ft.farmLabel:SetWidth(octoConstants.FEAT_W - 30)
	CuratorOctoFull.SetWordWrap(ft.farmLabel, false)
	ft.farm = S.Dropdown(ft, 220)
	ft.farm:SetPoint("TOP", ft.farmLabel, "BOTTOM", 0, -5)
	ft.farm:SetupMenu(function(_, root)
		A:FarmMenu(root)
	end)
	ft.farm:SetTooltip(function(tooltip)
		A:FarmTooltip(tooltip)
	end)
	ft.farm:Hide()

	-- the boosters of the other albums
	local gr = CreateFrame("Frame", nil, page)
	gr:SetPoint("TOPLEFT", X1, 0)
	gr:SetPoint("BOTTOMRIGHT")
	page.grid = gr
	gr.title = S.Text(gr, "GameFontNormalLarge", "LEFT")
	gr.title:SetPoint("TOPLEFT", 4, -4)
	gr.title:SetText(L["Your other boosters"])
	gr.sub = S.Text(gr, "GameFontHighlightSmall", "LEFT")
	gr.sub:SetPoint("TOPLEFT", gr.title, "BOTTOMLEFT", 0, -5)
	gr.sub:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	gr.tiles = {}
	for i = 1, octoConstants.TILE_COLS * octoConstants.TILE_ROWS do
		local t = NewTile(gr)
		local col, row = CuratorOctoFull.Mod((i - 1) , octoConstants.TILE_COLS), math.floor((i - 1) / octoConstants.TILE_COLS)
		t:SetPoint("TOPLEFT", col * (octoConstants.TILE_W + octoConstants.TILE_GAP), octoConstants.GRID_Y - row * (octoConstants.TILE_H + octoConstants.TILE_GAP))
		gr.tiles[i] = t
	end
	gr.empty = S.Text(gr, "GameFontHighlight")
	gr.empty:SetPoint("TOP", gr, "TOP", 0, octoConstants.GRID_Y - 8)
	gr.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(gr.empty, true)
	gr.empty:SetTextColor(0.8, 0.8, 0.8)
	-- (1.14.0) no other booster: how they come, a line each
	local how = CreateFrame("Frame", nil, gr)
	how:SetPoint("TOPLEFT", 0, octoConstants.GRID_Y - 30)
	CuratorOctoFull.SetSize(how, rw, 2 * octoConstants.TILE_H - 18)
	Hud.Panel(how, 2 * octoConstants.TILE_H - 18)
	how.title = S.Text(how, "GameFontNormal", "LEFT")
	how.title:SetPoint("TOPLEFT", 18, -20)
	how.title:SetText(L["How boosters come"])
	how.rows = {}
	for i = 1, 5 do
		local r = CreateFrame("Frame", nil, how)
		CuratorOctoFull.SetSize(r, rw - 32, 46)
		r:SetPoint("TOPLEFT", 18, -46 - (i - 1) * 48)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.icon, 30, 30)
		r.icon:SetPoint("LEFT", 0, 0)
		r.text = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.text:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
		r.text:SetWidth(rw - 32 - 44)
		CuratorOctoFull.SetWordWrap(r.text, true)
		r.text:SetTextColor(0.88, 0.88, 0.9)
		how.rows[i] = r
	end
	how:Hide()
	gr.how = how
	gr.pager = S.Pager(gr)
	-- (1.14.0: on the line of the title, beside the button of the displays: UI/Displays.lua)
	gr.pager:SetPoint("TOPRIGHT", -2, -27)
	CuratorOctoFull.SetScript(gr.pager.prev, "OnClick", function()
		A:BoostersPage(-1)
	end)
	CuratorOctoFull.SetScript(gr.pager.next, "OnClick", function()
		A:BoostersPage(1)
	end)

	-- (1.14.0, his word: no booster to choose any more) the rewards to choose, the button that shows them (UI/Offers.lua)
	local st = CreateFrame("Frame", nil, gr)
	CuratorOctoFull.SetSize(st, rw, octoConstants.STOCK_H)
	st:SetPoint("BOTTOMLEFT")
	Hud.Panel(st, octoConstants.STOCK_H)
	st.title = S.Text(st, "GameFontNormal", "LEFT")
	st.title:SetPoint("TOPLEFT", 14, -10)
	st.title:SetText(L["Rewards to choose"])
	st.slots = {}
	for _, kind in ipairs({ "offer" }) do
		local s = CreateFrame("Frame", nil, st)
		CuratorOctoFull.SetSize(s, 56, 56)
		s:SetPoint("TOP", st, "TOPLEFT", 40, -26)
		s.glow = s:CreateTexture(nil, "BACKGROUND")
		s.glow:SetTexture(octoConstants.MEDIA .. "Glow")
		s.glow:SetBlendMode("ADD")
		s.glow:SetVertexColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
		CuratorOctoFull.SetSize(s.glow, 76, 76)
		s.glow:SetPoint("CENTER", s, "TOP", 0, -20)
		s.glow:SetAlpha(0)
		s.icon = s:CreateTexture(nil, "ARTWORK")
		s.icon:SetTexture(Hud.PackIcon(kind))
		CuratorOctoFull.SetSize(s.icon, 40, 40)
		s.icon:SetPoint("CENTER", s, "TOP", 0, -20)
		s.count = Hud.Text(s, 13, "OUTLINE")
		s.count:SetPoint("TOP", s, "TOP", 0, -41)
		-- (1.14.0: its kind under it)
		s.label = S.Text(s, "GameFontDisableSmall")
		s.label:SetPoint("TOP", s.count, "BOTTOM", 0, -1)
		s.label:SetText(octoConstants.SLOT_LABEL[kind] and L[octoConstants.SLOT_LABEL[kind]] or "")
		s.kind = kind
		s:EnableMouse(true)
		CuratorOctoFull.SetScript(s, "OnEnter", function(self)
			A:StockTooltip(self)
		end)
		CuratorOctoFull.SetScript(s, "OnLeave", function()
			GameTooltip:Hide()
		end)
		st.slots[kind] = s
	end
	st.go = Hud.ClaimButton(st, 170, 32, L["Choose"])
	st.go:SetPoint("TOPRIGHT", -14, -30)
	CuratorOctoFull.SetScript(st.go, "OnClick", function()
		if ns.OffersUI then
			ns.OffersUI:Show()
		end
	end)
	-- (1.14.0, after its test, his word: off on a reroll, why in its tooltip)
	st.go.tip = function(self)
		A:ChoiceTip(self)
	end
	if st.go.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(st.go, true)
	end
	-- (1.14.0, his word: the boosters to choose are sold no more, its button of the shop gone)
	st.note = S.Text(st, "GameFontHighlightSmall", "LEFT")
	st.note:SetPoint("BOTTOMLEFT", 14, 8)
	st.note:SetWidth(rw - 28 - 184)
	CuratorOctoFull.SetWordWrap(st.note, true)
	st.note:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	page.stock = st

	-- the albums to put the boosters to choose in
	local pk = CreateFrame("Frame", nil, page)
	pk:SetPoint("TOPLEFT", X1, 0)
	pk:SetPoint("BOTTOMRIGHT")
	page.pick = pk
	pk.title = S.Text(pk, "GameFontNormalLarge", "LEFT")
	pk.title:SetPoint("TOPLEFT", 4, -4)
	pk.title:SetText(L["Choose the album"])
	pk.sub = S.Text(pk, "GameFontHighlightSmall", "LEFT")
	pk.sub:SetPoint("TOPLEFT", pk.title, "BOTTOMLEFT", 0, -5)
	pk.sub:SetWidth(rw - 10)
	CuratorOctoFull.SetWordWrap(pk.sub, true)
	pk.sub:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	pk.sub:SetText(L["Only the albums where boosters have already come can get them."])
	pk.back = S.Button(pk, L["Back"], 100, 22)
	pk.back:SetPoint("TOPRIGHT", -2, -4)
	CuratorOctoFull.SetScript(pk.back, "OnClick", function()
		A:ClosePicker()
	end)
	pk.kinds = {}
	-- (1.14.0: the golden boosters of the albums complete, a fourth, only while there are some: A:PlaceKinds)
	local kw = math.floor((rw - 2 * 8) / CuratorOctoFull.Length(LV.KINDS))
	for i, kind in ipairs(LV.PICK_KINDS) do
		local i, kind = i, kind; local b = NewToggle(pk, kw, 28)
		b:SetPoint("TOPLEFT", (i - 1) * (kw + 8), -56)
		b.icon:SetTexture(Hud.PackIcon(kind))
		b.kind = kind
		CuratorOctoFull.SetShown(b, kind ~= "golden")
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetPickKind(kind)
		end)
		pk.kinds[i] = b
	end
	pk.tiles = {}
	local gx = (rw - octoConstants.PICK_COLS * octoConstants.PICK_W - (octoConstants.PICK_COLS - 1) * octoConstants.PICK_GAP) / 2
	for i = 1, octoConstants.PICK_COLS * octoConstants.PICK_ROWS do
		local t = NewPickTile(pk)
		local col, row = CuratorOctoFull.Mod((i - 1) , octoConstants.PICK_COLS), math.floor((i - 1) / octoConstants.PICK_COLS)
		t:SetPoint("TOPLEFT", gx + col * (octoConstants.PICK_W + octoConstants.PICK_GAP), octoConstants.PICK_Y - row * (octoConstants.PICK_H + octoConstants.PICK_GAP))
		pk.tiles[i] = t
	end
	pk.pager = S.Pager(pk)
	pk.pager:SetPoint("TOPRIGHT", -4, octoConstants.PICK_Y - octoConstants.PICK_ROWS * (octoConstants.PICK_H + octoConstants.PICK_GAP) - 2)
	CuratorOctoFull.SetScript(pk.pager.prev, "OnClick", function()
		A:BoostersPage(-1)
	end)
	CuratorOctoFull.SetScript(pk.pager.next, "OnClick", function()
		A:BoostersPage(1)
	end)
	pk.addOne = Hud.ClaimButton(pk, 190, 34, L["Add one"])
	pk.addOne:SetPoint("BOTTOMLEFT", 10, 6)
	CuratorOctoFull.SetScript(pk.addOne, "OnClick", function()
		A:AssignChoice(1)
	end)
	pk.addAll = Hud.ClaimButton(pk, 190, 34, L["Add all"])
	pk.addAll:SetPoint("BOTTOMRIGHT", -10, 6)
	CuratorOctoFull.SetScript(pk.addAll, "OnClick", function()
		A:AssignChoice(nil)
	end)
	pk.empty = S.Text(pk, "GameFontHighlight")
	pk.empty:SetPoint("CENTER", pk, "TOP", 0, octoConstants.PICK_Y - (octoConstants.PICK_ROWS * (octoConstants.PICK_H + octoConstants.PICK_GAP)) / 2)
	pk.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(pk.empty, true)

	-- the odds of a booster, over the page
	self:BuildOdds(page)

	-- the gauge and the count of the day move while the page is open (each creature defeated)
	CuratorOctoFull.SetScript(page, "OnHide", function()
		page.odds:Hide()
	end)

	-- (1.12.0) a gift code of the author: its window (UI/Gift.lua), in the bar under the page
	f.giftCode = S.Button(f, L["Gift code"], 150, 22)
	f.giftCode:SetPoint("BOTTOMRIGHT", -8, 4)
	CuratorOctoFull.SetScript(f.giftCode, "OnClick", function()
		ns.Play(ns.SND.click)
		GameTooltip:Hide()
		if ns.GiftUI then
			ns.GiftUI:Show()
		end
	end)
	CuratorOctoFull.SetScript(f.giftCode, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Gift code"], 1, 1, 1)
		GameTooltip:AddLine(L["Redeem a code the author of Curator gave you: rewards to choose, rubies."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.giftCode, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.giftCode:Hide()
end

function A:ShowBoostersPage(shown)
	local f = self.frame
	if shown then
		self:BuildBoosters()
	end
	if f.boost then
		CuratorOctoFull.SetShown(f.boost, shown)
	end
	if f.giftCode then
		CuratorOctoFull.SetShown(f.giftCode, shown)
	end
end

-------------------------------------------------------------------------------
-- What is shown
-------------------------------------------------------------------------------
-- The booster shown big: the album of the place you are in (in a dungeon or a raid: the album its
-- boosters go to), else the album with the most boosters, else the album of your start. And the place.
function A:FeaturedSeries()
	local R = ns.Rewards
	local inst = R:InstanceSeries()
	if inst then
		return R:FarmSeries(inst), inst
	end
	local here = R:ZoneSeries()
	if here then
		return here, here
	end
	local best, most = nil, 0
	for _, s in ipairs(self:Order()) do
		local n = ns.Packs(s)
		if n > most then
			best, most = s, n
		end
	end
	return best or ns.HomeSeries(), nil
end

-- The albums with boosters waiting, but the one shown big: the most first.
function A:OtherBoosters(featured)
	local list = {}
	for _, s in ipairs(self:Order()) do
		if s ~= featured and ns.Packs(s) > 0 then
			list[CuratorOctoFull.Length(list) + 1] = s
		end
	end
	table.sort(list, function(a, b)
		local na, nb = ns.Packs(a), ns.Packs(b)
		if na ~= nb then
			return na > nb
		end
		return (a.order or 0) < (b.order or 0)
	end)
	return list
end

-- (1.14.2, his word: « Les boosters "Booster en or" il faut qu'ils soit aussi dans l'inventaire ») What the grid of the
-- other boosters shows: the golden boosters first, a tile for those of each album in the order they came (Golden.lua),
-- then the boosters of the other albums (A:OtherBoosters). A golden one: { golden = true, s = its album, n = how many,
-- t = the ticket of its first }.
function A:GridList(featured)
	local list = {}
	local GQ = ns.Golden
	for _, g in ipairs(GQ and GQ.PacksByAlbum and GQ:PacksByAlbum() or {}) do
		list[CuratorOctoFull.Length(list) + 1] = { golden = true, s = g.s, n = g.n, t = g.t }
	end
	for _, s in ipairs(self:OtherBoosters(featured)) do
		list[CuratorOctoFull.Length(list) + 1] = s
	end
	return list
end

-- (1.14.2) A booster standing (UI/Hud.lua, Hud.Pack) in gold: a golden booster, the pack of its album in gold and its
-- light of gold, as when it opens (UI/Booster.lua, B.GOLD); or as it is (on: false). How bright its light is stays for
-- the page that shows it to say.
A.GILT_GLOW = { 1, 0.84, 0.35 }
function A:GildPack(p, on)
	on = on and true or false
	local gold = (ns.Booster and ns.Booster.GOLD) or { 1, 0.8, 0.34 }
	for _, t in ipairs({ p.body, p.top }) do
		CuratorOctoFull.SetDesaturated(t, on)
		if on then
			t:SetVertexColor(gold[1], gold[2], gold[3])
		else
			t:SetVertexColor(1, 1, 1)
		end
	end
	local g = on and self.GILT_GLOW or (p.series and p.series.glow) or { 1, 0.8, 0.4 }
	p.glow:SetVertexColor(g[1], g[2], g[3])
	p.gilt = on
end

-- (1.14.2) A golden booster under the mouse (the page of the boosters, Everything in the inventory): what it is, its
-- album, what it holds, how many of that album wait; a reroll opens none, why.
function A:GoldenTooltip(owner, s, n, anchor)
	local g = self.GILT_GLOW
	GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
	GameTooltip:AddLine(L["Golden booster"], g[1], g[2], g[3])
	GameTooltip:AddLine(C:SeriesName(s), 1, 1, 1)
	GameTooltip:AddLine(L["The reward of an album complete or of a golden quest: 5 cards, every one epic or better. A click opens one."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(string.format(L["Golden boosters: %d"], n or 1), 1, 0.86, 0.45)
	if ns.Reroll and ns.Reroll:NoOpening() then
		GameTooltip:AddLine(ns.Reroll:Why(), 1, 0.62, 0.45, true)
	end
	GameTooltip:Show()
end

-- (1.14.2) The first golden booster of an album that came, opened (Golden.lua): the album put away, the window of the
-- booster says where it came from (from: "boosters" or "inventory", UI/Booster.lua) and goes back to it. A reroll opens
-- none: why, in the chat.
function A:OpenGolden(s, from)
	local GQ = ns.Golden
	local g = GQ and GQ.PacksByAlbum and GQ:PacksByAlbum(s)[1]
	if not g or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	if ns.Reroll and ns.Reroll:NoOpening() then
		ns.Reroll:SayNoOpening()
		return
	end
	ns.Play(ns.SND.click)
	GameTooltip:Hide()
	self:Hide()
	GQ:OpenPack(g.t, from)
end

-- The head of the window: every booster waiting, (1.14.0) the rewards to choose; every card of every album.
function A:PaintBoostersHead()
	local total, choose = ns.TotalPacks(), LV:OfferCount()
	local parts = {}
	if choose > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Rewards to choose: %d"], choose)
	end
	-- (the boosters that came in a trade wait until it is confirmed)
	local held = ns.Trade and ns.Trade:HeldTotal() or 0
	if held > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["From trades, waiting: %d"], held)
	end
	-- (1.14.2: the golden boosters waiting, Golden.lua)
	local golden = ns.Golden and ns.Golden:PackCount() or 0
	if golden > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Golden boosters: %d"], golden)
	end
	self:SetTitle(string.format(L["Boosters: %d"], total), table.concat(parts, "  ·  "))
	self:SetAllCounts()
end

function A:RefreshBoosters()
	local f = self.frame
	local page = f.boost
	self:Order()
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	self:PaintBoostersHead()
	local featured, place = self:FeaturedSeries()
	self:PaintFeatured(featured, place)
	-- (1.14.0: a reroll chooses no album for them: no picker)
	if self.boosterPick and ChoiceBlocked() then
		self.boosterPick = nil
	end
	local picking = self.boosterPick and true or false
	CuratorOctoFull.SetShown(page.grid, not picking)
	CuratorOctoFull.SetShown(page.pick, picking)
	if picking then
		self:PaintPicker()
	else
		self:PaintGrid(featured)
	end
	self:PaintStock(self.shownStock)
	self:PaintBadges()
end

-- The booster of the place: its photo, its booster on its pedestal, how many wait, the gauge, the
-- button.
function A:PaintFeatured(s, place)
	local ft = self.frame.boost.feat
	local R = ns.Rewards
	ft.series = s
	if not s then
		return
	end
	local studio = s.studio or "StudioElwynn"
	ft.photo:SetTexture(octoConstants.MEDIA .. studio)
	-- (the middle of the photo, as wide as the column allows)
	local k = (octoConstants.FEAT_W / (self.frame.boost.h or (self.U.PAGE_H - 20))) / 2
	ft.photo:SetTexCoord(0.5 - k / 2, 0.5 + k / 2, 0, 1)
	local g = s.glow or octoConstants.GOLDEN
	ft.spot:SetVertexColor(0.75 + 0.25 * g[1], 0.75 + 0.25 * g[2], 0.75 + 0.25 * g[3])
	ft.pack:SetSeries(s)
	local inst = R:InstanceSeries()
	S.SetFontObject(ft.where, "GameFontNormal")
	if place and place == s then
		ft.where:SetText(L["You are here"])
		ft.where:SetTextColor(octoConstants.HERE[1], octoConstants.HERE[2], octoConstants.HERE[3])
	elseif inst then
		ft.where:SetText(string.format(L["The boosters earned in %s go here"], C:SeriesName(inst)))
		ft.where:SetTextColor(octoConstants.HERE[1], octoConstants.HERE[2], octoConstants.HERE[3])
	else
		-- (no place: the album with the most boosters; none anywhere: the album you started in)
		ft.where:SetText(ns.Packs(s) > 0 and L["The most boosters"] or "")
		ft.where:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	end
	if ns.TextWidth(ft.where) > octoConstants.FEAT_W - 30 then
		S.Fit(ft.where, ft.where:GetText(), octoConstants.FEAT_W - 30, 12, 9)
	end
	local name = C:SeriesName(s)
	S.SetFontObject(ft.name, "GameFontNormalLarge")
	ft.name:SetText(name)
	if ns.TextWidth(ft.name) > octoConstants.FEAT_W - 24 then
		S.Fit(ft.name, name, octoConstants.FEAT_W - 24, 16, 10)
	end
	ft.sub:SetText(self:SubLine(s))
	local packs = ns.Packs(s)
	ft.count:SetText(packs > 0 and ("x" .. packs) or "")
	S.SetFontObject(ft.packs, "GameFontHighlight")
	if packs == 0 then
		ft.packs:SetText(L["No booster to open"])
		ft.packs:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	else
		ft.packs:SetText(packs == 1 and L["1 booster to open"] or string.format(L["%d boosters to open"], packs))
		ft.packs:SetTextColor(1, 0.92, 0.75)
	end
	-- (boosters of this album from a trade not confirmed yet: they wait)
	local held = ns.Trade and ns.Trade:HeldPacks(s) or 0
	if held > 0 then
		ft.packs:SetText(ft.packs:GetText() .. "\n|cffffcc73" .. string.format(L["%d from a trade, waiting"], held) .. "|r")
	end
	ft.pack.art:SetAlpha(packs > 0 and 1 or 0.55)
	CuratorOctoFull.SetDesaturated(ft.pack.body, packs == 0)
	CuratorOctoFull.SetDesaturated(ft.pack.top, packs == 0)
	-- (1.14.0, after its test, his word: a reroll opens none)
	local blocked = ns.Reroll ~= nil and ns.Reroll:NoOpening()
	ft.blocked = blocked
	CuratorOctoFull.SetEnabled(ft.open, packs > 0 and not blocked)
	ft.open:SetPulse(packs > 0 and not blocked)
	-- (1.14.0) all of them, two at least; the cards of its album found
	CuratorOctoFull.SetEnabled(ft.all, packs >= 2 and not blocked)
	ft.all:SetLabel(packs >= 2 and string.format(L["All (%d)"], math.min(10, packs)) or L["All"])
	local owned, total = C:Progress(s)
	ft.prog:SetProgress(total > 0 and owned / total or 0)
	ft.prog:SetText(string.format(L["%d / %d cards"], owned, total))
	CuratorOctoFull.SetShown(ft.farm, inst ~= nil)
	CuratorOctoFull.SetShown(ft.farmLabel, inst ~= nil)
	CuratorOctoFull.SetShown(ft.packs, inst == nil)
	if inst then
		ft.farm:GenerateMenu()
		S.SetFontObject(ft.farmLabel, "GameFontHighlightSmall")
		ft.farmLabel:SetText(string.format(L["Boosters earned in %s go to:"], C:SeriesName(inst)))
		if ns.TextWidth(ft.farmLabel) > octoConstants.FEAT_W - 30 then
			S.Fit(ft.farmLabel, ft.farmLabel:GetText(), octoConstants.FEAT_W - 30, 10, 8)
		end
	end
	self:PaintFeaturedGauge()
end

-- The booster bar under the booster shown big (in a dungeon or a raid: the count of the day too);
-- each creature defeated moves it. (Its booster goes to the album of the place: "Next booster" when
-- that is the one shown.)
function A:PaintFeaturedGauge()
	local ft = self.frame.boost.feat
	local s = ft.series
	if not s then
		return
	end
	local R = ns.Rewards
	local inst = R:InstanceSeries()
	-- (1.4.1: in a dungeon or a raid, their bar; 1.14.0: both of them, the one of the place lit)
	ft.kind = inst and "dungeon" or "world"
	local world = math.floor(100 * R:Bar("world") / ns.PACK_POINTS)
	local g = ft.gauge
	g:SetProgress(world / 100)
	g:SetText("")
	g.left:SetText(string.format(L["World: %d%%"], world))
	local ws = R.WorldSeries and R:WorldSeries() or nil
	g.right:SetText(ws and ("> " .. C:SeriesName(ws)) or L["No album here"])
	g.right:SetTextColor(ws and 0.85 or 0.6, ws and 0.85 or 0.6, ws and 0.88 or 0.62)
	g:SetAlpha(inst and 0.6 or 1)
	local dungeon = math.floor(100 * R:Bar("dungeon") / ns.PACK_POINTS)
	local g2 = ft.gauge2
	g2:SetProgress(dungeon / 100)
	g2:SetText("")
	g2.left:SetText(string.format(L["Dungeons and raids: %d%%"], dungeon))
	local left = R:DailyLeft()
	g2.right:SetText(string.format(L["Today: %d / %d"], R:DailyMax() - left, R:DailyMax()))
	g2.right:SetTextColor(left > 0 and 0.85 or 1, left > 0 and 0.85 or 0.5, left > 0 and 0.88 or 0.4)
	local off = (inst and R:TooLow(inst)) or left <= 0
	g2:SetAlpha((off and 0.45) or (inst and 1) or 0.75)
	-- (the bar of the place in full light, its words in gold)
	for _, x in ipairs({ g, g2 }) do
		local lit = x.kind == ft.kind
		x.left:SetTextColor(lit and octoConstants.GOLDEN[1] or 0.8, lit and octoConstants.GOLDEN[2] or 0.8, lit and octoConstants.GOLDEN[3] or 0.84)
	end
end

-- The boosters of the other albums, a page of them.
function A:PaintGrid(featured)
	local gr = self.frame.boost.grid
	-- (1.14.2: the golden boosters first, A:GridList)
	local list = self:GridList(featured)
	local per = octoConstants.TILE_COLS * octoConstants.TILE_ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / per))
	self.boostPage = math.max(1, math.min(self.boostPage or 1, pages))
	local n, golden = 0, 0
	for _, x in ipairs(list) do
		if x.golden then
			golden = golden + x.n
		else
			n = n + ns.Packs(x)
		end
	end
	local heads = {}
	if n > 0 then
		heads[CuratorOctoFull.Length(heads) + 1] = string.format(L["Boosters: %d"], n)
	end
	if golden > 0 then
		heads[CuratorOctoFull.Length(heads) + 1] = string.format(L["Golden boosters: %d"], golden)
	end
	gr.sub:SetText(table.concat(heads, "  ·  "))
	-- (1.14.0: none, how they come)
	self:PaintHowTo(CuratorOctoFull.Length(list) == 0)
	for i, t in ipairs(gr.tiles) do
		local x = list[(self.boostPage - 1) * per + i]
		local gold = x and x.golden and x or nil
		local s = gold and gold.s or x
		t.series = s
		t.gold = gold
		t.info.s = s
		CuratorOctoFull.SetShown(t, s ~= nil)
		if s then
			t.photo:SetTexture(octoConstants.MEDIA .. (s.studio or "StudioElwynn"))
			-- (1.14.2: a golden booster: its photo in gold too)
			CuratorOctoFull.SetDesaturated(t.photo, gold ~= nil)
			if gold then
				t.photo:SetVertexColor(1, 0.86, 0.55)
			else
				t.photo:SetVertexColor(1, 1, 1)
			end
			t.set:SetTexture(octoConstants.MEDIA .. (s.set or "SetElwynn"))
			local g = s.glow or octoConstants.GOLDEN
			t.set:SetVertexColor(0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3])
			t.pack:SetSeries(s)
			self:GildPack(t.pack, gold ~= nil)
			t.count:SetText("x" .. (gold and gold.n or ns.Packs(s)))
			local name = C:SeriesName(s)
			S.SetFontObject(t.name, "GameFontNormal")
			t.name:SetText(name)
			if ns.TextWidth(t.name) > octoConstants.TILE_W - 12 then
				S.Fit(t.name, name, octoConstants.TILE_W - 12, 11.5, 7.5)
			end
			-- (1.14.2: a golden booster: so said under its album, in gold, its light of gold standing; its odds are not
			-- those of the album)
			CuratorOctoFull.SetShown(t.info, gold == nil)
			Each(t.glow, "SetAlpha", t:IsMouseOver() and 0.55 or (gold and octoConstants.GILT_LIGHT or 0))
			if gold then
				t.lv:SetText(L["Golden booster"])
				t.lv:SetTextColor(self.GILT_GLOW[1], self.GILT_GLOW[2], self.GILT_GLOW[3])
			else
				t.lv:SetText(((s.event or s.limited) and L["Limited edition"]) or (s.raid and L["Raid"]) or (s.dungeon and L["Dungeon"]) or C:LevelRange(s))
				t.lv:SetTextColor(0.5, 0.5, 0.5)
			end
			-- (1.14.0: how much of its album is found)
			local owned, total = C:Progress(s)
			local k = total > 0 and owned / total or 0
			t.prog.fill:SetWidth(math.max(0.01, (octoConstants.TILE_W - 56) * k))
			if k >= 1 then
				CuratorOctoFull.ColorTexture(t.prog.fill, 0.45, 1, 0.45, 0.9)
			else
				CuratorOctoFull.ColorTexture(t.prog.fill, 1, 0.8, 0.32, 0.9)
			end
			CuratorOctoFull.SetShown(t.prog.fill, k > 0)
			t.pct:SetText(string.format(L["%d%%"], math.floor(k * 100)))
			t.pct:SetTextColor(k >= 1 and 0.45 or 0.85, k >= 1 and 1 or 0.85, k >= 1 and 0.45 or 0.88)
		end
	end
	gr.empty:SetText(CuratorOctoFull.Length(list) == 0 and L["No other booster for now."] or "")
	CuratorOctoFull.SetShown(gr.pager, pages > 1)
	gr.pager:Set(self.boostPage, pages, string.format(L["Page %d / %d"], self.boostPage, pages))
end

-- (1.14.0) No other booster: how they come, with what each thing gives now.
function A:PaintHowTo(shown)
	local how = self.frame.boost.grid.how
	CuratorOctoFull.SetShown(how, shown and true or false)
	if not shown then
		return
	end
	local R = ns.Rewards
	local lines = {
		{ Hud.PackIcon("zone"), string.format(L["Your bar of the world fills with all you do where an album lives: each time it is full, a booster of that album (%d%% now)."], math.floor(100 * R:Bar("world") / ns.PACK_POINTS)) },
		{ Hud.PackIcon("dungeon"), string.format(L["In the dungeons and the raids, a bar of their own: %d boosters a day at most, their album yours to choose."], R:DailyMax()) },
		{ Hud.XP, L["Each collector level: a reward to choose among three."] },
		{ "Interface\\Icons\\INV_Misc_Note_01", L["The quests of the collector: rewards to choose, experience and rubies."] },
		{ octoConstants.MEDIA .. "DisplayIcon", L["The reseller of the vendors of general goods sells displays: 16 boosters of an album."] },
	}
	for i, r in ipairs(how.rows) do
		local x = lines[i]
		CuratorOctoFull.SetShown(r, x ~= nil)
		if x then
			r.icon:SetTexture(x[1])
			r.text:SetText(x[2])
		end
	end
end

-- (1.14.0, his word: no booster to choose any more) The stock of the rewards to choose (counts: what to show while
-- rewards land, counts.offer), on the page of the boosters and on the page of the quests: how many wait, the button
-- that shows them (UI/Offers.lua); a reroll chooses none (Reroll.lua), why under them.
function A:PaintStock(counts)
	local f = self.frame
	local n = (counts and counts.offer) or LV:OfferCount()
	local stocks = {}
	if f.boost then
		stocks[CuratorOctoFull.Length(stocks) + 1] = f.boost.stock
	end
	if f.quests then
		stocks[CuratorOctoFull.Length(stocks) + 1] = f.quests.stock
	end
	local blocked = ChoiceBlocked()
	for _, st in ipairs(stocks) do
		local s = st.slots.offer
		if s then
			s.n = n
			s.count:SetText("x" .. n)
			CuratorOctoFull.SetShown(s.count, n > 0)
			CuratorOctoFull.SetDesaturated(s.icon, n == 0)
			s.icon:SetAlpha(n > 0 and 1 or 0.4)
			if n > 0 then
				s.count:SetTextColor(1, 0.88, 0.55)
			else
				s.count:SetTextColor(0.5, 0.5, 0.52)
			end
		end
		CuratorOctoFull.SetEnabled(st.go, n > 0 and not blocked)
		st.go:SetPulse(n > 0 and not blocked)
		st.go:SetLabel((blocked and string.format(L["Locked until level %d"], ns.Reroll.LEVEL)) or (n > 0 and string.format(L["Choose (%d)"], n)) or L["Choose"])
		local note
		if blocked then
			note = string.format(L["This character is a reroll: until level %d, it chooses no reward. Choose them with your main character."], ns.Reroll.LEVEL or 15)
		elseif n == 0 then
			note = L["Each level reached and many quests give a reward to choose among three."]
		else
			note = ""
		end
		st.note:SetText(note)
		if blocked then
			st.note:SetTextColor(1, 0.62, 0.45)
		else
			st.note:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
		end
		-- (on the page of the boosters, none waiting: their words in the place of the slot, under the title)
		if f.boost and st == f.boost.stock then
			if s then
				CuratorOctoFull.SetShown(s, n > 0)
				if s.label then
					s.label:SetTextColor(0.85, 0.85, 0.88)
				end
			end
			st.note:ClearAllPoints()
			if n > 0 then
				st.note:SetPoint("BOTTOMLEFT", 14, 8)
			else
				st.note:SetPoint("TOPLEFT", st.title, "BOTTOMLEFT", 0, -10)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- The albums to choose
-------------------------------------------------------------------------------
-- A tile: its album (the one chosen in gold).
local function PaintPickTile(t, s, chosen)
	local pw, ph = octoConstants.PICK_W - 14, octoConstants.PICK_H - 33
	if s.studio then
		-- (the picture of its place: its middle, as wide as the tile allows)
		local cut = math.min(1, (pw / ph) / 2)
		t.photo:SetTexture(octoConstants.MEDIA .. s.studio)
		t.photo:SetTexCoord(0.5 - cut / 2, 0.5 + cut / 2, 0, 1)
	else
		t.photo:SetTexture(octoConstants.MEDIA .. (s.pack or "PackElwynn") .. "Top")
		t.photo:SetTexCoord(0.1, 0.9, 0.3, 0.7)
	end
	CuratorOctoFull.SetShown(t.set, s.set ~= nil)
	if s.set then
		t.set:SetTexture(octoConstants.MEDIA .. s.set)
	end
	local name = C:SeriesName(s)
	S.SetFontObject(t.name, "GameFontHighlightSmall")
	t.name:SetText(name)
	if ns.TextWidth(t.name) > octoConstants.PICK_W - 12 then
		S.Fit(t.name, name, octoConstants.PICK_W - 12, 10, 7.5)
	end
	if chosen then
		t.name:SetTextColor(1, 0.86, 0.4)
	else
		t.name:SetTextColor(0.9, 0.9, 0.92)
	end
	Each(t.glow, "SetAlpha", chosen and 0.95 or 0)
	t.photo:SetVertexColor(chosen and 1 or 0.82, chosen and 1 or 0.82, chosen and 1 or 0.82)
end

-- The albums that can get the boosters to choose of a kind: the one chosen, the buttons to put one or
-- all of them in it.
function A:PaintPicker()
	local pk = self.frame.boost.pick
	-- the kind: kept while it has boosters to choose, else the first that has some (with albums for
	-- them first)
	local kind = self.pickKind
	if not (kind and LV:Choices(kind) > 0) then
		kind = nil
		for _, k in ipairs(LV.PICK_KINDS) do
			if LV:Choices(k) > 0 and CuratorOctoFull.Length(LV:Eligible(k)) > 0 then
				kind = k
				break
			end
		end
		if not kind then
			for _, k in ipairs(LV.PICK_KINDS) do
				if LV:Choices(k) > 0 then
					kind = k
					break
				end
			end
		end
		self.pickKind = kind
	end
	self:PlaceKinds(LV:Choices("golden") > 0)
	for _, b in ipairs(pk.kinds) do
		local n = LV:Choices(b.kind)
		local text = string.format(L[octoConstants.KIND_LABEL[b.kind]], n)
		-- (four of them: their words fitted to them)
		S.SetFontObject(b.text, "GameFontNormal")
		b.text:SetText(text)
		local room = b:GetWidth() - (b.textX or 38) - 6
		if ns.TextWidth(b.text) > room then
			S.Fit(b.text, text, room, 12, 7.5)
		end
		CuratorOctoFull.SetEnabled(b, n > 0)
		b:SetSelected(b.kind == kind)
	end
	-- (1.14.0: what a golden booster holds, which albums can get one)
	pk.sub:SetText(kind == "golden" and L["5 cards, every one epic or better, for an album not complete yet."]
		or L["Only the albums where boosters have already come can get them."])
	local list = kind and LV:Eligible(kind) or {}
	-- the album chosen: kept while it can get them, else the first
	local s = self.choiceSeries
	-- (1.6.0: the boosters of a zone can go to a dungeon with the talent Foresight; 1.14.0: a golden booster, any album
	-- that can get one)
	if not (s and kind and (kind == "golden" or LV.KindOf(s) == kind or LV:Foresees(kind, s)) and LV:CanGet(s, kind)) then
		s = list[1]
		self.choiceSeries = s
	end
	local per = octoConstants.PICK_COLS * octoConstants.PICK_ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / per))
	self.pickPage = math.max(1, math.min(self.pickPage or 1, pages))
	for i, t in ipairs(pk.tiles) do
		local x = list[(self.pickPage - 1) * per + i]
		t.s = x
		CuratorOctoFull.SetShown(t, x ~= nil)
		if x then
			PaintPickTile(t, x, x == s)
		end
	end
	CuratorOctoFull.SetShown(pk.pager, pages > 1)
	pk.pager:Set(self.pickPage, pages, string.format(L["Page %d / %d"], self.pickPage, pages))
	local n = kind and LV:Choices(kind) or 0
	-- (1.14.0, after its test, his word: a reroll puts none in an album)
	local ok = s ~= nil and not ChoiceBlocked()
	CuratorOctoFull.SetEnabled(pk.addOne, ok and n > 0)
	pk.addOne:SetPulse(ok and n > 0)
	CuratorOctoFull.SetEnabled(pk.addAll, ok and n > 1)
	pk.addAll:SetLabel(n > 1 and (L["Add all"] .. " (" .. n .. ")") or L["Add all"])
	if LV:Choices() == 0 then
		pk.empty:SetText(L["No booster to choose"])
	elseif CuratorOctoFull.Length(list) == 0 then
		pk.empty:SetText(L["No album can get them yet: they wait for the first boosters of their kind."])
	else
		pk.empty:SetText("")
	end
end

-- (1.14.0) The kinds over the albums to choose: three, or four with the golden boosters of the albums complete
-- (narrower then, their icons smaller; the golden one the narrowest, its word short).
function A:PlaceKinds(golden)
	local page = self.frame.boost
	local pk = page.pick
	if pk.golden == golden then
		return
	end
	pk.golden = golden
	local rw, gap = page.rw, 8
	local gw = golden and 84 or 0
	local count = CuratorOctoFull.Length(LV.KINDS)
	local kw = math.floor((rw - gw - (golden and count or count - 1) * gap) / count)
	local x = 0
	for _, b in ipairs(pk.kinds) do
		local on = b.kind ~= "golden" or golden
		CuratorOctoFull.SetShown(b, on)
		if on then
			local w = b.kind == "golden" and gw or kw
			b:SetWidth(w)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", x, -56)
			x = x + w + gap
			local icon = golden and 24 or 30
			CuratorOctoFull.SetSize(b.icon, icon, icon)
			b.textX = icon + 8
			b.text:ClearAllPoints()
			b.text:SetPoint("LEFT", b.textX, 0)
		end
	end
end

function A:OpenPicker()
	-- (1.14.0, after its test, his word: a reroll chooses no album for them, the chat says why)
	if ChoiceBlocked() then
		ns.Reroll:SayNot("choice")
		return
	end
	ns.Play(ns.SND.page)
	self.boosterPick = true
	self.pickPage = nil
	self:Refresh()
end

function A:ClosePicker()
	ns.Play(ns.SND.page)
	self.boosterPick = nil
	self:Refresh()
end

function A:SetPickKind(kind)
	if kind ~= self.pickKind and LV:Choices(kind) > 0 then
		ns.Play(ns.SND.click)
		self.pickKind = kind
		self.pickPage = 1
		self:Refresh()
	end
end

function A:PickTile(t)
	if t.s and t.s ~= self.choiceSeries then
		ns.Play(ns.SND.click)
		self.choiceSeries = t.s
		self:Refresh()
	end
end

-- The pages of the boosters of the other albums, or of the albums to choose (the wheel of the mouse
-- turns them too).
function A:BoostersPage(delta)
	if self.boosterPick then
		local list = self.pickKind and LV:Eligible(self.pickKind) or {}
		local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / (octoConstants.PICK_COLS * octoConstants.PICK_ROWS)))
		local p = math.max(1, math.min(pages, (self.pickPage or 1) + delta))
		if p ~= self.pickPage then
			self.pickPage = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
		return
	end
	local list = self:GridList((self:FeaturedSeries()))
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / (octoConstants.TILE_COLS * octoConstants.TILE_ROWS)))
	local p = math.max(1, math.min(pages, (self.boostPage or 1) + delta))
	if p ~= self.boostPage then
		self.boostPage = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- Put one booster to choose (or all those of its kind: n = nil) in the album chosen: they fly from
-- the stock into its tile.
function A:AssignChoice(n)
	local s = self.choiceSeries
	if not s then
		return
	end
	if ChoiceBlocked() then
		ns.Reroll:SayNot("choice")
		return
	end
	local kind = self.pickKind or LV.KindOf(s)
	local page = self.frame.boost
	local tile
	for _, t in ipairs(page.pick.tiles) do
		if t:IsShown() and t.s == s then
			tile = t
		end
	end
	local from
	for _, b in ipairs(page.pick.kinds) do
		if b.kind == kind then
			from = b.icon
		end
	end
	local given = LV:Assign(s, n, kind)
	if given > 0 then
		ns.Play(ns.SND.place)
		for k = 1, math.min(given, 4) do
			local k = k; Hud.Fly(Hud.PackIcon(kind), from or page.pick, tile or page.pick, 34, 0.5, function()
				if k == 1 and tile then
					ns.Play(ns.SND.open)
					Hud.Burst(tile, octoConstants.GOLDEN, 16, 110, 16)
					ns.Tween(0.45, function(_, raw)
						tile.flash:SetAlpha(0.5 * (1 - raw))
					end, nil, Ease.linear, tile)
				end
			end, { 1, 0.85, 0.45 }, (k - 1) * 0.08)
		end
		local name = C:SeriesName(s)
		if kind == "golden" then
			-- (1.14.0: a golden booster waits in the button of gold under the page, UI/Golden.lua)
			ns.Print(given == 1 and string.format(L["A golden booster of %s: it waits in the button of gold under the page."], name)
				or string.format(L["%d golden boosters of %s: they wait in the button of gold under the page."], given, name))
		else
			ns.Print(given == 1 and string.format(L["A booster added to %s."], name) or string.format(L["%d boosters added to %s."], given, name))
		end
	end
	self:Refresh()
end

-------------------------------------------------------------------------------
-- Opening
-------------------------------------------------------------------------------
-- A booster of an album opened from the page (the album goes, the booster comes; 1.14.0, all: all of them, ten at
-- most, UI/OpenAll.lua).
function A:OpenFrom(s, all, from)
	if not s or ns.Packs(s) <= 0 then
		return
	end
	-- (1.14.0, after its test: a reroll opens none; the album stays open, the chat says why: Reroll.lua)
	if ns.Reroll and ns.Reroll:NoOpening() then
		ns.Reroll:SayNoOpening()
		return
	end
	ns.Play(ns.SND.click)
	GameTooltip:Hide()
	self:Hide()
	-- (1 November: from Everything in the inventory, back to it after, UI/CaseInventory.lua)
	ns.OpenBooster({ series = s, from = from or "boosters", all = (all and ns.Packs(s) >= 2) or nil })
end

-- A booster raised a little (under the mouse), or back down.
function A:LiftPack(pack, dy)
	if pack.liftTw then
		ns.CancelTween(pack.liftTw)
	end
	local from = pack.lift or 0
	pack.liftTw = ns.Tween(0.16, function(e)
		pack:SetLift(from + (dy - from) * e)
	end, function()
		pack.liftTw = nil
	end, Ease.outQuad, pack)
end

-------------------------------------------------------------------------------
-- The odds of a booster
-------------------------------------------------------------------------------
-- Over the page: the shade, a panel with the name of the album, what a booster holds, the chance of
-- each rarity, the finishes. (1 November, his word: « J'aimerai un "Retour" »: Back under it; a click beside it does
-- nothing any more.)
function A:BuildOdds(page)
	local o = CreateFrame("Button", nil, page)
	o:SetAllPoints()
	o:SetFrameLevel(page:GetFrameLevel() + 40)
	o.shade = o:CreateTexture(nil, "BACKGROUND")
	o.shade:SetAllPoints()
	CuratorOctoFull.ColorTexture(o.shade, 0, 0, 0, 0.62)
	-- (the wheel of the mouse does not turn the pages under it)
	o:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(o, "OnMouseWheel", function() end)
	o:Hide()
	page.odds = o
	local W, H = 400, 392
	local p = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(p, W, H)
	p:SetPoint("CENTER", 0, 4)
	p:EnableMouse(true)
	o.panel = p
	p.frame = Hud.Card(p, 0.9)
	p.pack = Hud.Pack(p, 34)
	p.pack:SetPoint("TOPLEFT", 22, -16)
	p.pack.glow:SetAlpha(0.2)
	p.name = S.Text(p, "GameFontNormalLarge", "LEFT")
	p.name:SetPoint("TOPLEFT", 72, -22)
	p.name:SetWidth(W - 120)
	CuratorOctoFull.SetWordWrap(p.name, false)
	p.sub = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.sub:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -4)
	p.sub:SetText(L["Odds of each booster"])
	p.sub:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	p.what = S.Text(p, "GameFontHighlight", "LEFT")
	p.what:SetPoint("TOPLEFT", 72, -62)
	p.what:SetWidth(W - 94)
	CuratorOctoFull.SetWordWrap(p.what, true)
	p.close = S.CloseButton(p)
	p.close:SetPoint("TOPRIGHT", -6, -6)
	CuratorOctoFull.SetScript(p.close, "OnClick", function()
		A:HideOdds()
	end)
	p.close:Hide()
	o.back = S.Button(o, L["Back"], 140, 24)
	o.back:SetPoint("TOP", p, "BOTTOM", 0, -10)
	CuratorOctoFull.SetScript(o.back, "OnClick", function()
		A:HideOdds()
	end)
	local function Head(y)
		local h = S.Text(p, "GameFontNormal", "LEFT")
		h:SetPoint("TOPLEFT", 26, y)
		h.rule = S.Divider(p, W - 52, 0.7)
		h.rule:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
		return h
	end
	local function Row(y)
		local r = CreateFrame("Frame", nil, p)
		CuratorOctoFull.SetSize(r, W - 52, 20)
		r:SetPoint("TOPLEFT", 26, y)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.icon, 16, 16)
		r.icon:SetPoint("LEFT", 2, 0)
		r.label = S.Text(r, "GameFontHighlight", "LEFT")
		r.label:SetPoint("LEFT", 24, 0)
		r.value = S.Text(r, "GameFontHighlight", "RIGHT")
		r.value:SetPoint("RIGHT", -4, 0)
		r.extra = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.extra:SetPoint("RIGHT", -64, 0)
		r.extra:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
		-- (a bar of its chance under it, faint)
		r.bar = r:CreateTexture(nil, "BACKGROUND")
		r.bar:SetPoint("BOTTOMLEFT", 24, -1)
		r.bar:SetHeight(2)
		CuratorOctoFull.ColorTexture(r.bar, 1, 1, 1, 0.5)
		return r
	end
	p.rarHead = Head(-112)
	p.rows = {}
	for i = 1, octoConstants.ODD_ROWS do
		p.rows[i] = Row(-136 - (i - 1) * 26)
	end
	p.note = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.note:SetWidth(W - 52)
	CuratorOctoFull.SetWordWrap(p.note, true)
	p.note:SetTextColor(0.85, 0.85, 0.88)
	p.finHead = Head(0)
	p.fins = {}
	for i = 1, 2 do
		local r = Row(0)
		r:ClearAllPoints()
		if i == 1 then
			r:SetPoint("TOPLEFT", p.finHead, "BOTTOMLEFT", 0, -12)
		else
			r:SetPoint("TOPLEFT", p.fins[i - 1], "BOTTOMLEFT", 0, -6)
		end
		p.fins[i] = r
	end
end

-- The odds of a booster of this album, over the page.
function A:ShowOdds(s)
	local page = self.frame.boost
	if not (page and s) then
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.page)
	local o = page.odds
	local p = o.panel
	local odds = C:Odds(s)
	o.series = s
	p.pack:SetSeries(s)
	S.SetFontObject(p.name, "GameFontNormalLarge")
	p.name:SetText(C:SeriesName(s))
	if ns.TextWidth(p.name) > p.name:GetWidth() then
		S.Fit(p.name, C:SeriesName(s), p.name:GetWidth(), 16, 10)
	end
	-- (a zone: 8 cards since 1.14.0, C.ODDS.cards)
	p.what:SetText((odds.dungeon and L["5 cards, each rare, epic or legendary"]) or (odds.event and L["5 cards, each drawn on its own"])
		or string.format(L["%d cards, each drawn on its own"], odds.cards or C.ODDS.cards))
	p.rarHead:SetText(L["Each card"])
	-- the rarities (a zone: all of them; a dungeon: from rare), the finest last
	local rows = {}
	for r = odds.dungeon and 3 or 1, CuratorOctoFull.Length(ns.RARITY) do
		if (odds.rar[r] or 0) > 0 then
			rows[CuratorOctoFull.Length(rows) + 1] = r
		end
	end
	local top = 0
	for _, r in ipairs(rows) do
		top = math.max(top, odds.rar[r])
	end
	for i, row in ipairs(p.rows) do
		local r = rows[i]
		CuratorOctoFull.SetShown(row, r ~= nil)
		if r then
			local rr = ns.RARITY[r]
			row.icon:SetTexture(octoConstants.MEDIA .. "Gem" .. r)
			row.label:SetText(L[rr.label])
			row.label:SetTextColor(rr.text[1], rr.text[2], rr.text[3])
			row.value:SetText(ns.Pct(odds.rar[r]))
			row.extra:SetText("")
			CuratorOctoFull.ColorTexture(row.bar, rr.text[1], rr.text[2], rr.text[3], 0.55)
			-- (how big each chance is, rooted: the smallest stay seen)
			row.bar:SetWidth(math.max(2, (row:GetWidth() - 30) * math.sqrt(odds.rar[r] / top)))
		end
	end
	-- the boosters with a rare card or better (a zone: nothing is sure), the last boss (a dungeon, a raid)
	local note
	if odds.dungeon then
		note = (odds.mythic or 0) > 0 and string.format(L["Mythic (the last boss): %s of the boosters, in the place of the best card."], ns.Pct(odds.mythic)) or ""
	else
		note = string.format(L["A rare card or better in %s of the boosters."], ns.Pct(odds.rareBooster or 0)) .. " "
			.. (odds.event and L["A limited edition: its boosters only come while Hallow's End lasts."]
				or L["Nothing is sure: your copies to spare make better cards with the contracts."])
	end
	p.note:SetText(note)
	-- (the note under the last rarity shown, the finishes under it; the panel as tall as they need)
	p.note:ClearAllPoints()
	p.note:SetPoint("TOPLEFT", p.rows[math.max(1, CuratorOctoFull.Length(rows))], "BOTTOMLEFT", 0, -10)
	p.finHead:ClearAllPoints()
	p.finHead:SetPoint("TOPLEFT", p.note, "BOTTOMLEFT", 0, -24)
	p:SetHeight(396 + (CuratorOctoFull.Length(rows) - 4) * 26)
	p.finHead:SetText(L["Finishes (each card)"])
	-- (1.3: the same two finishes everywhere, more often in the dungeons and the raids)
	local fins = { { "thunder", odds.shiny, odds.shinyPack }, { "titan", odds.holo, odds.holoPack } }
	for i, row in ipairs(p.fins) do
		local x = fins[i]
		row.icon:SetTexture(octoConstants.MEDIA .. "Twinkle")
		-- (their colours: the lightning, the gold of the titans)
		local c = (x[1] == "titan") and { 1, 0.84, 0.5 } or { 0.62, 0.84, 1 }
		row.icon:SetVertexColor(c[1], c[2], c[3])
		row.label:SetText(L[octoConstants.FINISH_NAME[x[1]]])
		row.label:SetTextColor(c[1], c[2], c[3])
		row.value:SetText(ns.Pct(x[2]))
		row.extra:SetText(string.format(L["%s of the boosters"], ns.Pct(x[3])))
		CuratorOctoFull.ColorTexture(row.bar, c[1], c[2], c[3], 0.5)
		row.bar:SetWidth(math.max(2, (row:GetWidth() - 30) * math.sqrt(x[2] / math.max(x[2], fins[1][2]))))
	end
	o:SetAlpha(0)
	o:Show()
	p:SetScale(0.94)
	ns.Tween(0.18, function(e)
		o:SetAlpha(e)
		p:SetScale(0.94 + 0.06 * e)
	end, nil, Ease.outQuad, o)
end

function A:HideOdds()
	local page = self.frame.boost
	if page and page.odds:IsShown() then
		ns.Play(ns.SND.close)
		page.odds:Hide()
	end
end

-------------------------------------------------------------------------------
-- Tooltips
-------------------------------------------------------------------------------
-- A booster of the page: its album, how many wait, the gauge of the next one; a click opens one.
function A:BoosterTooltip(owner, s)
	if not s then
		return
	end
	local R = ns.Rewards
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:SeriesName(s), octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	GameTooltip:AddLine(self:SubLine(s), 0.8, 0.8, 0.8)
	local packs = ns.Packs(s)
	GameTooltip:AddLine(string.format(L["Boosters: %d"], packs), 1, 1, 1)
	if R:Target() == s then
		GameTooltip:AddLine(string.format(L["Next booster: %d%%"], math.floor(100 * R:Bar(R:Here()) / ns.PACK_POINTS)), 0.8, 0.8, 0.8)
	end
	local owned, total = C:Progress(s)
	GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 0.8, 0.8, 0.8)
	-- (1.14.0, after its test, his word: a reroll opens none, why instead of the clicks)
	if packs > 0 and ns.Reroll and ns.Reroll:NoOpening() then
		GameTooltip:AddLine(ns.Reroll:Why(), 1, 0.62, 0.45, true)
		GameTooltip:Show()
		return
	end
	if packs > 0 then
		GameTooltip:AddLine(L["Click to open a booster"], 0.3, 1, 0.3)
	end
	-- (1.14.0: all of them, from a tile)
	if packs >= 2 and owner and owner.series == s and owner.pct then
		GameTooltip:AddLine(L["Right click: all of them (ten at most)"], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

-- A booster bar: how full, where its booster goes, what fills it (the bar over the experience bar
-- tells the same: UI/BoosterBar.lua). kind: "world" or "dungeon" (nil: the one of the place).
function A:GaugeTooltip(owner, kind)
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	if ns.BoosterBar then
		ns.BoosterBar:AddLines(GameTooltip, kind)
	end
	GameTooltip:Show()
end

-- (1.11.0) The button of the shop: what the boosters to choose cost in rubies, how many are left this week.
function A:BuyTooltip(b)
	local RB = ns.Rubies
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Buy a booster to choose"], 1, 1, 1)
	GameTooltip:AddLine(string.format(L["A booster of a zone: %s"], RB.Text(RB:PackPrice("zone") or 0, 13)), 0.9, 0.9, 0.9)
	GameTooltip:AddLine(string.format(L["A booster of a dungeon: %s"], RB.Text(RB:PackPrice("dungeon") or 0, 13)), 0.9, 0.9, 0.9)
	GameTooltip:AddLine(string.format(L["A booster of a raid: %s"], RB.Text(RB:PackPrice("raid") or 0, 13)), 0.9, 0.9, 0.9)
	GameTooltip:AddLine(string.format(L["%d a week, every kind together: %d left this week."], RB:PackWeek(), RB:PacksLeft()), S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	if ChoiceBlocked() then
		GameTooltip:AddLine(ns.Reroll:WhyNot("choice"), 1, 0.62, 0.45, true)
	end
	GameTooltip:Show()
end

-- (1.14.0, his word) The slot of the rewards to choose.
function A:StockTooltip(slot)
	local n = LV:OfferCount()
	GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L["Rewards to choose"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(n == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], n), 1, 1, 1)
	GameTooltip:AddLine(L["Each level reached and many quests give a reward to choose among three."], 0.8, 0.8, 0.8, true)
	if ChoiceBlocked() then
		GameTooltip:AddLine(string.format(L["This character is a reroll: until level %d, it chooses no reward. Choose them with your main character."], ns.Reroll.LEVEL or 15), 1, 0.62, 0.45, true)
	end
	GameTooltip:Show()
end

-- (1.14.0, after its test, his word) The button to choose their album: off on a reroll, why (Reroll.lua: RR:Blocks).
function A:ChoiceTip(owner)
	if not ChoiceBlocked() then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Choose the album"], 1, 1, 1)
	GameTooltip:AddLine(ns.Reroll:WhyNot("choice"), 1, 0.62, 0.45, true)
	GameTooltip:Show()
end

function A:TileTooltip(t)
	local s = t.s
	if not s then
		return
	end
	GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:SeriesName(s), S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(self:SubLine(s), 0.85, 0.85, 0.85)
	GameTooltip:AddLine(string.format(L["Boosters: %d"], ns.Packs(s)), 1, 0.86, 0.5)
	-- (1.14.0: choosing the album of a golden booster, those it has already)
	if self.boosterPick and self.pickKind == "golden" and ns.Golden then
		GameTooltip:AddLine(string.format(L["Golden boosters: %d"], ns.Golden:PackCount(s)), octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	end
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- From elsewhere
-------------------------------------------------------------------------------
-- The page of the boosters (picker: the albums to put the boosters to choose in).
function A:ShowBoosters(picker)
	self:Build()
	self:FinishClaims()
	-- (1.14.0, after its test, his word: a reroll chooses no album for them, Reroll.lua)
	self.boosterPick = picker and LV:Choices() > 0 and not ChoiceBlocked() or nil
	self.mode, self.member, self.memberEntries, self.returnMode = "boosters", nil, nil, nil
	self:HideDetail()
	self:Reveal()
end

-- (1.14.2) A golden booster given or opened (Golden.lua): its tile on the page of the boosters, there or gone at once.
ns.On("GOLDEN_CHANGED", function()
	local f = A.frame
	if f and f:IsShown() and A.mode == "boosters" and f.boost then
		A:Refresh()
	end
end)
