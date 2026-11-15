local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local A = ns.Album
local AC = ns.Achievements
local LV = ns.Level
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease

-- The page of the achievements, in the album, as the trophy rooms of the great games. In the head of
-- the window: the points, in big, the title of the collector (in the colour of its rank) and the bar
-- toward the next one. On the left: the categories (how many of each are earned, the badge of the
-- rewards waiting), the level of the collector under them (the experience of the rewards lands there).
-- On the right: the achievements of the category on their cards (the tiers of a series together, a
-- medal each, lit when earned), their points, their reward to claim; the albums: a wall of their
-- emblems, the ring of each, the seal of gold of those complete.
-- (1.9.0: twelve categories, the buttons thinner to keep the level under them)
local NAV_W, NAV_H, NAV_GAP = 192, 28, 3
local X0 = NAV_W + 14
local HEAD_H = 46
local ROW_H, ROW_GAP, ROWS = 90, 6, 4
local LV_H = 132
local WALL_COLS, WALL_W, WALL_H = 8, 66, 46
local MEDAL, MEDAL_GAP = 28, 8
-- the title of the window, to the right of the medal
local TITLE_X, TITLE_ROOM = 98, 388
local GOLDEN = { 1, 0.8, 0.32 }
local DIM = { 0.62, 0.62, 0.68 }
-- the metals of the tiers, from the first to the last
local TIER = {
	{ 0.86, 0.56, 0.32 }, { 0.84, 0.88, 0.98 }, { 1, 0.8, 0.32 }, { 0.56, 0.92, 1 },
	{ 0.86, 0.56, 1 }, { 1, 0.44, 0.44 }, { 1, 0.62, 0.22 },
	-- (1.5.0: the tiers that go further, in the colours of the finishes)
	{ 0.45, 0.78, 1 }, { 0.35, 1, 0.82 }, { 1, 0.92, 0.6 },
}
-- the medals of a card at most (1.5.0: ten, closer together past seven)
local MEDALS = 10
-- (an achievement not earned yet: the icon of a secret one)
local SECRET_ICON = { "Interface\\Icons\\INV_Misc_QuestionMark" }
-- the owner of the animations of the claims (cancelled when the page goes; shared with the quests)
local ANIM = A.CLAIMS

-- (1.14.0, after its test, his word) This character a reroll: it earns no achievement and claims none of their
-- rewards (Reroll.lua: RR:Blocks); a member shown is no matter of it.
local function Locked()
	return ns.Reroll ~= nil and ns.Reroll:Blocks("achievements")
end

-- The icon of each category.
local CAT_ICON = {
	boosters = { "Icon" },
	collection = { "Back", { 0.07, 0.65, 0.21, 0.79 } },
	rarity = { "Gem6" },
	finish = { "Interface\\Icons\\INV_Enchant_ShardPrismaticLarge" },
	albums = { "SetElwynn", nil, { 1, 0.86, 0.5 } },
	contracts = { "Interface\\Icons\\INV_Scroll_03" },
	adventure = { "Interface\\Icons\\INV_Box_01" },
	quests = { "Interface\\Icons\\INV_Misc_Note_01" },
	pvp = { "Interface\\Icons\\INV_BannerPVP_02" },
	social = { "Interface\\Icons\\INV_Misc_Spyglass_03" },
	feats = { "Gem5" },
	bestiary = { "Interface\\Icons\\Ability_Hunter_BeastTaming" },
	-- (1.14.0: the cases, the top of the lid of the case; the secret ones, their question mark)
	cases = { "CratePal1Top", { 0.209, 0.791, 0, 0.582 } },
	secret = { "Interface\\Icons\\INV_Misc_QuestionMark" },
}
-- The general achievements of the albums, as the medals of one line over the wall.
-- (1.9.0: 5, 15 and 40 albums complete, after the first one)
local ALBUM_LINE = { "half", "one", "alb:5", "alb:15", "alb:40", "fek", "fka", "fdun", "fraid", "fall" }

local fmtDate = date or (os and os.date)

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Earned()
	if A.member then
		local i = ns.Guild:Profile(A.member)
		return i and AC:FromBits(i.bits) or {}, i
	end
	return AC:Earned()
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- A category on the left: its icon, its name, how many are earned, the badge of its rewards waiting.
local function NewCat(page, cat, i)
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, NAV_W, NAV_H)
	b:SetPoint("TOPLEFT", 0, -(i - 1) * (NAV_H + NAV_GAP))
	Hud.Panel(b, NAV_H)
	b.accent = b:CreateTexture(nil, "BORDER", nil, 2)
	b.accent:SetTexture(MEDIA .. "QuestAccent")
	b.accent:SetBlendMode("ADD")
	b.accent:SetVertexColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
	CuratorOctoFull.SetSize(b.accent, 10, NAV_H - 6)
	b.accent:SetPoint("LEFT", 1, 0)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 3, -3)
	b.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.08)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, 20, 20)
	b.icon:SetPoint("LEFT", 10, 0)
	Hud.SetIcon(b.icon, CAT_ICON[cat] or { "Icon" })
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", 38, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	b.count = S.Text(b, "GameFontHighlightSmall", "RIGHT")
	b.badge = Hud.Badge(b, 20)
	b.badge:SetPoint("RIGHT", -7, 0)
	b.cat = cat
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:SetAchCategory(cat)
	end)
	return b
end

-- The points and the reward of an achievement, on the right of its card: its medal of points, the orb
-- and the experience, the button to claim it (or "Claimed").
local function Reward(r)
	r.pts = r:CreateTexture(nil, "ARTWORK")
	r.pts:SetTexture(MEDIA .. "TierMedal")
	CuratorOctoFull.SetSize(r.pts, 34, 34)
	r.pts:SetPoint("CENTER", r, "TOPRIGHT", -30, -28)
	r.pts:SetVertexColor(1, 0.8, 0.32)
	r.ptsText = Hud.Text(r, 11, "OUTLINE", "OVERLAY", 2)
	r.ptsText:SetPoint("CENTER", r.pts, "CENTER", 0, -2)
	r.xp = Hud.Text(r, 12, "OUTLINE")
	r.xp:SetTextColor(0.88, 0.76, 1)
	r.xp:SetPoint("RIGHT", r.pts, "LEFT", -8, -1)
	r.orb = r:CreateTexture(nil, "ARTWORK")
	r.orb:SetTexture(Hud.XP)
	CuratorOctoFull.SetSize(r.orb, 20, 20)
	r.orb:SetPoint("RIGHT", r.xp, "LEFT", -1, 0)
	-- (1.11.0) its rubies, under its experience
	r.ruby = ns.RubiesUI.Tag(r, 15, 11)
	r.ruby:SetPoint("RIGHT", r.pts, "LEFT", -8, -16)
	r.claim = Hud.ClaimButton(r, 104, 26, L["Claim"])
	r.claim:SetPoint("BOTTOMRIGHT", -12, 12)
	CuratorOctoFull.SetScript(r.claim, "OnClick", function()
		A:ClaimRows({ r })
	end)
	-- (1.14.0, after its test, his word: off on a reroll, why in its tooltip)
	r.claim.tip = function(self)
		if Locked() then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Claim"], 1, 1, 1)
			GameTooltip:AddLine(ns.Reroll:WhyNot("achievements"), 1, 0.62, 0.45, true)
			GameTooltip:Show()
		end
	end
	if r.claim.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(r.claim, true)
	end
	r.claimed = Hud.Text(r, 12, "OUTLINE")
	r.claimed:SetPoint("BOTTOMRIGHT", -16, 20)
	r.claimed:SetTextColor(0.55, 0.95, 0.45)
	-- the day it was earned, under it
	r.when = S.Text(r, "GameFontDisableSmall", "RIGHT")
	r.when:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -16, 8)
end

-- A card of an achievement (or of the tiers of a series): its icon in a ring of gold, its name, what it
-- asks, how far; the medals of its tiers; its points and its reward.
local function NewRow(page, w)
	local r = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	Hud.Panel(r, ROW_H)
	r.flash = r:CreateTexture(nil, "BORDER", nil, 1)
	r.flash:SetPoint("TOPLEFT", 4, -4)
	r.flash:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(r.flash, 1, 0.86, 0.5, 1)
	r.flash:SetBlendMode("ADD")
	r.flash:SetAlpha(0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetPoint("TOPLEFT", 4, -4)
	r.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.7, 0.05)
	r.icon = Hud.RoundIcon(r, 44)
	r.icon:SetPoint("CENTER", r, "LEFT", 42, 0)
	r.ring = r:CreateTexture(nil, "ARTWORK", nil, 2)
	r.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(r.ring, 58, 58)
	r.ring:SetPoint("CENTER", r, "LEFT", 42, 0)
	r.check = r:CreateTexture(nil, "OVERLAY", nil, 3)
	r.check:SetTexture(MEDIA .. "Check")
	CuratorOctoFull.SetSize(r.check, 34, 34)
	r.check:SetPoint("CENTER", r, "LEFT", 62, -16)
	r.name = S.Text(r, "GameFontHighlight", "LEFT")
	r.name:SetPoint("TOPLEFT", 80, -13)
	r.name:SetWidth(w - 80 - 190)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.desc = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.desc:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
	r.desc:SetWidth(w - 80 - 150)
	CuratorOctoFull.SetWordWrap(r.desc, false)
	CuratorOctoFull.SetMaxLines(r.desc, 3)
	r.bar = Hud.XPBar(r, w - 82 - 170, 12, { 1, 0.72, 0.2 })
	r.bar:SetPoint("TOPLEFT", 82, -56)
	-- the medals of the tiers, under the bar
	r.medals = {}
	for i = 1, MEDALS do
		local i = i; local m = CreateFrame("Button", nil, r)
		CuratorOctoFull.SetSize(m, MEDAL, MEDAL)
		m:SetPoint("TOPLEFT", r, "TOPLEFT", 80 + (i - 1) * (MEDAL + MEDAL_GAP), -54)
		m.glow = m:CreateTexture(nil, "BACKGROUND")
		m.glow:SetTexture(MEDIA .. "Glow")
		m.glow:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(m.glow, MEDAL * 2, MEDAL * 2)
		m.glow:SetPoint("CENTER")
		m.glow:SetAlpha(0)
		m.tex = m:CreateTexture(nil, "ARTWORK")
		m.tex:SetTexture(MEDIA .. "TierMedal")
		m.tex:SetAllPoints()
		m.check = m:CreateTexture(nil, "OVERLAY")
		m.check:SetTexture(MEDIA .. "Check")
		CuratorOctoFull.SetSize(m.check, 18, 18)
		m.check:SetPoint("CENTER", m, "BOTTOMRIGHT", -3, 3)
		m.goal = Hud.Text(m, 9, "OUTLINE", "OVERLAY", 2)
		m.goal:SetPoint("CENTER", m, "CENTER", 0, -1)
		CuratorOctoFull.SetScript(m, "OnEnter", function(self)
			A:MedalTooltip(self)
		end)
		CuratorOctoFull.SetScript(m, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(m, "OnClick", function(self)
			if self.a and AC:Waiting(self.a) and not A.member then
				A:ClaimRows({ r }, { self.a })
			end
		end)
		r.medals[i] = m
	end
	Reward(r)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		if self.waiting and not A.member then
			return A:ClaimRows({ self })
		end
		-- an album's achievement opens the album
		local a = self.a
		if a and a.series and not A.member then
			ns.Play(ns.SND.page)
			A:ShowSeries(a.series)
		end
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:RowTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- its glow breathes while its reward waits (1.14.0: not on a reroll, which cannot claim it)
	r.t = 0
	CuratorOctoFull.SetScript(r, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		if self.waiting and not self.locked then
			Hud.Each(self.glow, "SetAlpha", 0.5 + 0.3 * math.sin(self.t * 3.2))
		end
		local nx = self.nextMedal
		if nx then
			nx.glow:SetAlpha(0.35 + 0.25 * math.sin(self.t * 4))
		end
	end)
	return r
end

-- A place of the wall of the albums: its emblem in the ring of its progress (the seal of gold once
-- complete).
local function NewCell(wall)
	local c = CreateFrame("Button", nil, wall)
	CuratorOctoFull.SetSize(c, WALL_W, WALL_H)
	c.glow = c:CreateTexture(nil, "BACKGROUND")
	c.glow:SetTexture(MEDIA .. "Glow")
	c.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(c.glow, 70, 70)
	c.glow:SetPoint("CENTER", 0, 2)
	c.glow:SetVertexColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
	c.glow:SetAlpha(0)
	c.bg = c:CreateTexture(nil, "BORDER")
	c.bg:SetTexture(MEDIA .. "CircleMask")
	c.bg:SetVertexColor(0.03, 0.03, 0.05)
	c.bg:SetAlpha(0.85)
	CuratorOctoFull.SetSize(c.bg, 34, 34)
	c.bg:SetPoint("CENTER", 0, 2)
	c.set = c:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(c.set, 24, 24)
	c.set:SetPoint("CENTER", 0, 2)
	c.ring = Hud.Ring(c, 42, "ARTWORK", 1)
	c.ring:SetPoint("CENTER", 0, 2)
	c.seal = c:CreateTexture(nil, "OVERLAY")
	c.seal:SetTexture(MEDIA .. "AlbumSeal")
	CuratorOctoFull.SetSize(c.seal, 26, 26)
	c.seal:SetPoint("CENTER", c, "CENTER", 15, -8)
	c.badge = Hud.Badge(c, 16)
	c.badge:SetPoint("CENTER", c, "CENTER", -15, 15)
	c.badge:SetFrameLevel(c:GetFrameLevel() + 3)
	c.hl = c:CreateTexture(nil, "HIGHLIGHT")
	c.hl:SetTexture(MEDIA .. "Glow")
	c.hl:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(c.hl, 56, 56)
	c.hl:SetPoint("CENTER", 0, 2)
	c.hl:SetAlpha(0.3)
	CuratorOctoFull.SetScript(c, "OnClick", function(self)
		if not self.a then
			return
		end
		-- (1.14.0: a reroll claims none: its album opens, why in the tooltip)
		if AC:Waiting(self.a) and not A.member and not Locked() then
			A:ClaimCell(self)
		elseif not A.member then
			ns.Play(ns.SND.page)
			A:ShowSeries(self.a.series)
		end
	end)
	CuratorOctoFull.SetScript(c, "OnEnter", function(self)
		A:CellTooltip(self)
	end)
	CuratorOctoFull.SetScript(c, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return c
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
function A:BuildAch()
	local f = self.frame
	if f.ach then
		return
	end
	local U = self.U
	-- in the head of the window: the medal of the title, the bar toward the next title
	f.aMedal = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.aMedal, 46, 46)
	f.aMedal:SetPoint("CENTER", f, "TOPLEFT", 65, U.PROGRESS_Y - 8)
	f.aMedal:SetFrameLevel(f:GetFrameLevel() + 12)
	f.aMedal.gem = f.aMedal:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.aMedal.gem, 23, 23)
	f.aMedal.gem:SetPoint("CENTER", 0, -1)
	f.aMedal.tex = f.aMedal:CreateTexture(nil, "OVERLAY")
	f.aMedal.tex:SetTexture(MEDIA .. "AchMedal")
	f.aMedal.tex:SetAllPoints()
	f.aMedal:EnableMouse(true)
	CuratorOctoFull.SetScript(f.aMedal, "OnEnter", function(self)
		A:TitleTooltip(self)
	end)
	CuratorOctoFull.SetScript(f.aMedal, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.aBar = Hud.XPBar(f, U.BAR_W, 18, { 1, 0.74, 0.22 })
	f.aBar:SetPoint("RIGHT", f, "TOPRIGHT", -20, U.PROGRESS_Y)
	f.aBar:EnableMouse(true)
	CuratorOctoFull.SetScript(f.aBar, "OnEnter", function(self)
		A:TitleTooltip(self)
	end)
	CuratorOctoFull.SetScript(f.aBar, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.aNote = S.Text(f, "GameFontHighlightSmall", "RIGHT")
	f.aNote:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, U.SUB_Y)
	f.aNote:SetTextColor(DIM[1], DIM[2], DIM[3])
	f.aMedal:Hide()
	f.aBar:Hide()
	f.aNote:Hide()

	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, U.PAGER)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.ach = page
	local rw = U.PAGE_W - 32 - X0
	page.rw = rw
	-- (the points: what the head shows of them, kept for the other pages and the tests)
	page.pts = S.Text(page, "GameFontNormalHuge")
	page.pts:Hide()

	-- the categories
	page.cats = {}
	for i, cat in ipairs(AC.CATEGORIES) do
		page.cats[i] = NewCat(page, cat, i)
	end
	-- the level of the collector, under them: the experience of the rewards lands there
	local lv = Hud.LevelBox(page, NAV_W, LV_H)
	lv:SetPoint("TOPLEFT", 0, -(CuratorOctoFull.Length(AC.CATEGORIES) * (NAV_H + NAV_GAP)) - 10)
	lv:EnableMouse(true)
	CuratorOctoFull.SetScript(lv, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Collector level"], 1, 0.84, 0.48)
		GameTooltip:AddLine(L["The rewards of the achievements are experience: claim them, your level climbs."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(lv, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.lv = lv

	-- the achievements of the category
	local bd = CreateFrame("Frame", nil, page)
	bd:SetPoint("TOPLEFT", X0, 0)
	bd:SetPoint("BOTTOMRIGHT")
	page.board = bd
	bd.title = S.Text(bd, "GameFontNormalLarge", "LEFT")
	bd.title:SetPoint("TOPLEFT", 4, -4)
	bd.stats = S.Text(bd, "GameFontHighlightSmall", "LEFT")
	bd.stats:SetPoint("TOPLEFT", bd.title, "BOTTOMLEFT", 0, -5)
	bd.stats:SetTextColor(DIM[1], DIM[2], DIM[3])
	bd.claimAll = Hud.ClaimButton(bd, 170, 32, L["Claim all"])
	bd.claimAll:SetPoint("TOPRIGHT", -2, -4)
	CuratorOctoFull.SetScript(bd.claimAll, "OnClick", function()
		A:ClaimAllAch()
	end)
	-- (1.14.0, after its test, his word: on a reroll, in its place, the padlock and why: UI/Reroll.lua)
	bd.locker = ns.RerollUI and ns.RerollUI.Pill and ns.RerollUI.Pill(bd) or nil
	if bd.locker then
		bd.locker:SetPoint("TOPRIGHT", -2, -6)
	end
	page.rows = {}
	for i = 1, ROWS do
		local r = NewRow(bd, rw)
		r:SetPoint("TOPLEFT", 0, -HEAD_H - (i - 1) * (ROW_H + ROW_GAP))
		page.rows[i] = r
	end
	-- the albums: their line of medals, then the wall of their emblems
	local wall = CreateFrame("Frame", nil, bd)
	wall:SetPoint("TOPLEFT", 0, -HEAD_H - ROW_H - 10)
	CuratorOctoFull.SetSize(wall, rw, WALL_H * 8)
	wall.cells = {}
	for i = 1, CuratorOctoFull.Length((ns.Series or {})) do
		local c = NewCell(wall)
		c:SetPoint("TOPLEFT", (CuratorOctoFull.Mod((i - 1) , WALL_COLS)) * WALL_W, -math.floor((i - 1) / WALL_COLS) * WALL_H)
		wall.cells[i] = c
	end
	wall:Hide()
	page.wall = wall
	wall.t = 0
	CuratorOctoFull.SetScript(wall, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		local a = 0.4 + 0.3 * math.sin(self.t * 3.4)
		for _, c in ipairs(self.cells) do
			if c.waiting then
				c.glow:SetAlpha(a)
			end
		end
	end)
	CuratorOctoFull.SetScript(page, "OnHide", function()
		ns.CancelOwner(ANIM)
		A:EndClaims()
	end)
end

function A:ShowAchPage(shown)
	local f = self.frame
	if shown then
		self:BuildAch()
	end
	if f.ach then
		CuratorOctoFull.SetShown(f.ach, shown)
		CuratorOctoFull.SetShown(f.aMedal, shown)
		CuratorOctoFull.SetShown(f.aBar, shown)
		CuratorOctoFull.SetShown(f.aNote, shown)
	end
end

function A:SetAchCategory(cat)
	if cat ~= self.achCat then
		self:FinishClaims()
		self.achCat, self.achPage = cat, 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The entries of a category: { a } or { group } (the albums: their line of medals, the wall). On the
-- pages, those with a reward to claim come first, then those earned (the latest first), then the
-- others in their order (1.1.1: a reward waiting was sometimes on another page). A group of tiers is
-- earned once all its tiers are. The order is set when the page of the category opens, and kept while
-- it stays open: a reward claimed does not move its card away (A.achOrder, dropped on another page).
function A:AchList(cat)
	local earned = (Earned())
	local list = AC:Entries(cat, earned)
	if cat == "albums" then
		return list
	end
	local key = cat .. "|" .. tostring(self.member or "")
	local order = self.achOrder
	if not (order and order.key == key) then
		local mine = not self.member
		local rank, when, at = {}, {}, {}
		for i, x in ipairs(list) do
			local waiting, got, latest = false, true, 0
			for _, a in ipairs(x.group and x.group.list or { x.a }) do
				local t = earned[a.id]
				if t then
					if type(t) == "number" and t > latest then
						latest = t
					end
					if mine and AC:Waiting(a) then
						waiting = true
					end
				else
					got = false
				end
			end
			rank[x] = (waiting and 0) or (got and 1) or 2
			when[x], at[x] = latest, i
		end
		local sorted = {}
		for i, x in ipairs(list) do
			sorted[i] = x
		end
		table.sort(sorted, function(p, q)
			if rank[p] ~= rank[q] then
				return rank[p] < rank[q]
			end
			if rank[p] == 1 and when[p] ~= when[q] then
				return when[p] > when[q]
			end
			return at[p] < at[q]
		end)
		order = { key = key, pos = {} }
		for i, x in ipairs(sorted) do
			order.pos[x.group or x.a] = i
		end
		self.achOrder = order
	end
	local at = {}
	for i, x in ipairs(list) do
		at[x] = i
	end
	local far = CuratorOctoFull.Length(list) + 1
	table.sort(list, function(p, q)
		local a, b = order.pos[p.group or p.a] or (far + at[p]), order.pos[q.group or q.a] or (far + at[q])
		return a < b
	end)
	return list
end

function A:AchPage(delta)
	local cat = self.achCat or AC.CATEGORIES[1]
	if cat == "albums" then
		return
	end
	local n = CuratorOctoFull.Length(self:AchList(cat))
	local pages = math.max(1, math.ceil(n / ROWS))
	local p = math.max(1, math.min(pages, (self.achPage or 1) + delta))
	if p ~= self.achPage then
		self:FinishClaims()
		self.achPage = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The achievement page of an achievement (a click on its toast).
function A:ShowAchievement(a)
	self:Build()
	-- (the rewards being claimed land at once)
	self:FinishClaims()
	self:Order()
	-- (my own achievements, in the order of their page as it opens now)
	self.member, self.memberEntries, self.achOrder = nil, nil, nil
	local list = self:AchList(a.cat)
	local at = 1
	for i, x in ipairs(list) do
		if x.a == a or (x.group and x.group == a.group) then
			at = i
		end
	end
	self.achCat, self.achPage = a.cat, math.ceil(at / ROWS)
	self.mode, self.member, self.memberEntries, self.returnMode = "ach", nil, nil, nil
	self:HideDetail()
	self:Reveal()
end

-------------------------------------------------------------------------------
-- Painting the page
-------------------------------------------------------------------------------
function A:RefreshAch()
	local f = self.frame
	local page = f.ach
	AC:Build()
	self:Order()
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:RefreshFooter(false)
	self.questDirty = nil
	self.achCat = self.achCat or AC.CATEGORIES[1]
	local earned, info = Earned()
	local member = self.member
	if member then
		local short = ns.Guild:Short(member)
		local waiting = not info
		CuratorOctoFull.SetShown(f.wait, waiting)
		if waiting then
			local late = self.asked and GetTime() - self.asked > 5
			f.wait.text:SetText(late and string.format(L["%s did not answer (offline?)"], short) or string.format(L["Waiting for %s..."], short))
		end
	end
	local points, count = AC:Points(earned)
	if info then
		points, count = info.points, info.count
	end
	self:PaintAchHead(points, count, info and info.female, AC:Count(earned))
	page.pts:SetText(tostring(points))
	self:PaintAchLevel(self.shownXP or LV:XP())
	self:PaintAchCats(earned)
	if self.achCat == "albums" then
		self:ShowPager(false)
		self:PaintAlbumWall(earned)
	else
		self:ShowPager(true)
		self:PaintAchRows(earned)
	end
	self:PaintBadges()
end

-- The head of the window: the points, the title and the next one, the medal, the bar toward it.
function A:PaintAchHead(points, count, female, total)
	local f = self.frame
	local AT = AC.TITLES
	local title, rank, nextPts, nextTitle = AC:Title(points, female)
	if not self.member then
		title, rank, nextPts, nextTitle = AC:MyTitle()
	end
	local col = AC:RankColour(rank)
	self:SetTitle(string.format(L["%d points"], points), "|cff" .. Hex(col) .. title .. "|r")
	f.title:ClearAllPoints()
	f.title:SetPoint("LEFT", f, "TOPLEFT", TITLE_X, self.U.PROGRESS_Y)
	if ns.TextWidth(f.title) > TITLE_ROOM then
		S.Fit(f.title, f.title:GetText(), TITLE_ROOM, 19, 12)
	end
	f.sub:ClearAllPoints()
	f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_X + 1, self.U.SUB_Y)
	f.subMoved = true
	f.aMedal.gem:SetTexture(AC:RankGem(rank))
	-- the bar from the points of this title to those of the next one
	local from = AT[rank][1]
	if nextPts then
		f.aBar:SetProgress((points - from) / math.max(1, nextPts - from))
		f.aBar:SetText(string.format(L["%d / %d points"], points, nextPts))
		f.aNote:SetText(string.format(L["%d points to %s"], nextPts - points, nextTitle))
	else
		f.aBar:SetProgress(1)
		f.aBar:SetText(string.format(L["%d points"], points))
		f.aNote:SetText(string.format(L["%d / %d achievements"], count, total))
	end
	-- (the bar of the game in the head is the one the pages share: it tells the achievements earned)
	self:SetBar(count, total, string.format(L["%d / %d achievements"], count, total))
end

-- The level of the collector under the categories (an experience: what it shows while rewards land).
function A:PaintAchLevel(xp)
	local lv = self.frame.ach.lv
	lv:Paint(xp)
	CuratorOctoFull.SetShown(lv, not self.member)
end

-- The categories: the one shown in gold, how many are earned, the badge of its rewards waiting.
function A:PaintAchCats(earned)
	local page = self.frame.ach
	for _, b in ipairs(page.cats) do
		local got, all = 0, 0
		for _, a in ipairs(AC.list) do
			if a.cat == b.cat and AC:Shown(a, earned) then
				all = all + 1
				if earned[a.id] then
					got = got + 1
				end
			end
		end
		-- (1.14.0: a reroll claims none, no badge of them)
		local claim = (self.member or Locked()) and 0 or AC:ClaimCount(b.cat)
		b.badge:SetCount(claim)
		b.count:SetText(string.format(("%d/%d"), got, all))
		b.count:ClearAllPoints()
		if claim > 0 then
			b.count:SetPoint("RIGHT", b.badge, "LEFT", -4, 0)
		else
			b.count:SetPoint("RIGHT", -10, 0)
		end
		if got >= all then
			b.count:SetTextColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
		else
			b.count:SetTextColor(0.85, 0.85, 0.88)
		end
		local room = NAV_W - 38 - 8 - (ns.TextWidth(b.count) + 6) - (claim > 0 and 26 or 2)
		S.SetFontObject(b.text, "GameFontNormal")
		b.text:SetWidth(room)
		b.text:SetText(L[AC.LABEL[b.cat]])
		if ns.TextWidth(b.text) > room then
			S.Fit(b.text, L[AC.LABEL[b.cat]], room, 12, 9)
		end
		local on = b.cat == self.achCat
		Hud.Each(b.glow, "SetAlpha", on and 0.7 or 0)
		CuratorOctoFull.SetShown(b.accent, on)
		if on then
			b.text:SetTextColor(1, 1, 1)
		else
			b.text:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
		end
	end
end

-- The head of the board: the category, what is earned of it (and its points), claim all.
function A:PaintBoardHead(earned)
	local bd = self.frame.ach.board
	local got, all, pts, ptsAll = 0, 0, 0, 0
	for _, a in ipairs(AC.list) do
		if a.cat == self.achCat and AC:Shown(a, earned) then
			all, ptsAll = all + 1, ptsAll + a.pts
			if earned[a.id] then
				got, pts = got + 1, pts + a.pts
			end
		end
	end
	bd.title:SetText(L[AC.LABEL[self.achCat]])
	bd.stats:SetText(string.format(L["%d / %d achievements"], got, all) .. "   ·   " .. string.format(L["%d / %d points"], pts, ptsAll))
	local waiting = self.member and 0 or AC:ClaimCount(self.achCat)
	-- (1.14.0, after its test, his word: a reroll claims none, its padlock in the place of the button, UI/Reroll.lua)
	local rr = not self.member and Locked()
	CuratorOctoFull.SetShown(bd.claimAll, waiting >= 2 and not rr)
	CuratorOctoFull.SetEnabled(bd.claimAll, waiting >= 2 and not rr)
	bd.claimAll:SetPulse(true)
	bd.claimAll:SetLabel(L["Claim all"] .. " (" .. waiting .. ")")
	if bd.locker then
		CuratorOctoFull.SetShown(bd.locker, rr)
		if rr then
			bd.locker:Paint("achievements")
		end
	end
end

-- The achievements of the category on their cards, a page of them.
function A:PaintAchRows(earned)
	local page = self.frame.ach
	page.wall:Hide()
	self:PaintBoardHead(earned)
	local list = self:AchList(self.achCat)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / ROWS))
	self.achPage = math.max(1, math.min(self.achPage or 1, pages))
	for i, r in ipairs(page.rows) do
		local entry = list[(self.achPage - 1) * ROWS + i]
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 0, -HEAD_H - (i - 1) * (ROW_H + ROW_GAP))
		CuratorOctoFull.SetShown(r, entry ~= nil)
		if entry then
			if entry.group then
				self:PaintGroup(r, entry.group, earned)
			else
				self:PaintSingle(r, entry.a, earned)
			end
		else
			r.a, r.group, r.waiting, r.nextMedal = nil, nil, false, nil
		end
	end
	self:SetPager(self.achPage, pages)
end

-- The reward of a card: its points, the experience waiting (the button to claim), or claimed.
-- (1.14.0: rubies, those of its achievements as they are given, Rubies.lua: RB:OfAchievement; an album complete has
-- more than its points)
local function PaintReward(r, pts, xp, waiting, claimed, member, rubies)
	r.ptsText:SetText(tostring(pts))
	r.xp:SetText(string.format(L["+%s XP"], ns.Num(xp)))
	r.ruby:SetAlpha(1)
	-- (1.11.0) its rubies: for each of its points
	rubies = (ns.Rubies and xp > 0) and (rubies or (tonumber(pts) or 0) * ns.Rubies.PER_POINT) or 0
	CuratorOctoFull.SetShown(r.ruby, not member and rubies > 0)
	if rubies > 0 then
		r.ruby:SetAmount(rubies, true)
	end
	r.xp:SetAlpha(1)
	r.orb:SetAlpha(1)
	r.waiting = waiting and not member
	-- (1.14.0, after its test, his word: a reroll claims none, its button off)
	local rr = not member and Locked()
	r.locked = rr
	CuratorOctoFull.SetShown(r.claim, r.waiting)
	CuratorOctoFull.SetEnabled(r.claim, r.waiting and not rr)
	r.claim:SetPulse(r.waiting and not rr)
	r.claim:SetAlpha(1)
	CuratorOctoFull.SetShown(r.claimed, claimed and not member and not r.waiting)
	r.claimed:SetText(L["Claimed"])
	CuratorOctoFull.SetShown(r.xp, not member and xp > 0)
	CuratorOctoFull.SetShown(r.orb, not member and xp > 0)
	Hud.Each(r.glow, "SetAlpha", (r.waiting and not rr) and 0.6 or 0)
end

-- One achievement: earned (its colours, its day) or not (grey, how far).
function A:PaintSingle(r, a, earned)
	local got = earned[a.id]
	local member = self.member ~= nil
	r.a, r.group, r.nextMedal = a, nil, nil
	r:SetAlpha(1)
	r.flash:SetAlpha(0)
	local hidden = a.secret and not got
	Hud.SetIcon(r.icon, hidden and SECRET_ICON or a.icon)
	CuratorOctoFull.SetDesaturated(r.icon, not got)
	r.icon:SetAlpha(got and 1 or 0.55)
	CuratorOctoFull.SetDesaturated(r.ring, not got)
	S.SetFontObject(r.name, "GameFontHighlight")
	local name = hidden and L["Secret achievement"] or AC:Name(a)
	r.name:SetText(name)
	if ns.TextWidth(r.name) > r.name:GetWidth() then
		S.Fit(r.name, name, r.name:GetWidth(), 13, 9)
	end
	r.name:SetTextColor(got and 1 or 0.65, got and 0.92 or 0.65, got and 0.75 or 0.65)
	for _, m in ipairs(r.medals) do
		m:Hide()
	end
	-- how far: mine only (another player's progress is not shared)
	local sn = not member and (AC.lastSnapshot or AC:Snapshot()) or nil
	local goal = sn and AC:Goal(a, sn) or 0
	local value = sn and math.min(goal, a.value(sn, ns.db)) or 0
	local showBar = not got and sn and goal > 1
	-- what it asks: on up to three lines when no bar is under it (a secret one: its hint)
	r.desc:Show()
	CuratorOctoFull.SetWordWrap(r.desc, not showBar)
	r.desc:SetText(hidden and L[a.hint] or AC:Desc(a, (not member) and (AC.lastSnapshot or AC:Snapshot()) or AC.lastSnapshot))
	r.bar:ClearAllPoints()
	r.bar:SetPoint("TOPLEFT", 82, -56)
	CuratorOctoFull.SetShown(r.bar, showBar and true or false)
	if showBar then
		r.bar:SetProgress(value / goal)
		r.bar:SetText(string.format(("%d / %d"), value, goal))
	end
	local claimed = got and AC:Claimed(a)
	CuratorOctoFull.SetShown(r.check, claimed and not member)
	CuratorOctoFull.SetSize(r.check, 34, 34)
	r.check:SetAlpha(1)
	PaintReward(r, a.pts, AC:XP(a), got and not claimed, claimed, member, AC:Rubies(a))
	CuratorOctoFull.SetDesaturated(r.pts, not got)
	-- the day it was earned, under the points (when its reward is no longer waiting)
	local day = got and not member and type(got) == "number" and fmtDate and fmtDate("%d/%m/%y", got) or ""
	r.when:SetText(day)
	CuratorOctoFull.SetShown(r.when, day ~= "" and not r.waiting)
end

-- The medals of a card: under its bar, or in its place when there is none (every tier reached).
local function PlaceMedals(r, n)
	local y = r.bar:IsShown() and -54 or -40
	-- (past seven, closer together: they stay left of the reward)
	local step = MEDAL + ((n or 0) > 7 and math.max(1, MEDAL_GAP - 2 * ((n or 0) - 7)) or MEDAL_GAP)
	for i, m in ipairs(r.medals) do
		m:ClearAllPoints()
		m:SetPoint("TOPLEFT", r, "TOPLEFT", 80 + (i - 1) * step, y)
	end
end

-- The tiers of a series: its icon, its title, the medals of its tiers (lit when earned), the bar
-- toward the next tier; its points, the reward of the tiers waiting.
function A:PaintGroup(r, g, earned)
	local member = self.member ~= nil
	r.a, r.group = nil, g
	r:SetAlpha(1)
	r.flash:SetAlpha(0)
	local nxt, got = AC:NextTier(g, earned)
	Hud.SetIcon(r.icon, g.icon)
	CuratorOctoFull.SetDesaturated(r.icon, got == 0)
	r.icon:SetAlpha(got > 0 and 1 or 0.55)
	CuratorOctoFull.SetDesaturated(r.ring, got == 0)
	S.SetFontObject(r.name, "GameFontHighlight")
	r.name:SetText(L[g.title])
	r.name:SetTextColor(got > 0 and 1 or 0.65, got > 0 and 0.92 or 0.65, got > 0 and 0.75 or 0.65)
	r.desc:Hide()
	-- the medals (the goal of each on it: the albums of a family count as many as the family has)
	r.nextMedal = nil
	local sizes = AC.lastSnapshot or AC:Snapshot()
	for i, m in ipairs(r.medals) do
		local a = g.list[i]
		m.a = a
		CuratorOctoFull.SetShown(m, a ~= nil)
		if a then
			local on = earned[a.id] ~= nil
			local c = TIER[math.min(i, CuratorOctoFull.Length(TIER))]
			m.tex:SetVertexColor(c[1], c[2], c[3])
			CuratorOctoFull.SetDesaturated(m.tex, not on)
			m.tex:SetAlpha(on and 1 or 0.35)
			local goal = tostring(AC:Goal(a, sizes))
			-- (1.5.0: five digits a little smaller, inside the medal)
			ns.SetFont(m.goal, CuratorOctoFull.Length(goal) >= 5 and 7.5 or 9, "OUTLINE")
			m.goal:SetText(goal)
			m.goal:SetTextColor(on and 1 or 0.55, on and 0.9 or 0.55, on and 0.7 or 0.55)
			CuratorOctoFull.SetShown(m.check, on and not member and AC:Claimed(a))
			m.check:SetAlpha(1)
			CuratorOctoFull.SetSize(m.check, 18, 18)
			m.glow:SetVertexColor(c[1], c[2], c[3])
			m.glow:SetAlpha(0)
			if a == nxt and not member then
				r.nextMedal = m
			end
		end
	end
	-- the bar toward the next tier (mine)
	local sn = not member and (AC.lastSnapshot or AC:Snapshot()) or nil
	if nxt and sn then
		local goal = AC:Goal(nxt, sn)
		local value = math.min(goal, nxt.value(sn, ns.db))
		r.bar:Show()
		r.bar:SetProgress(value / math.max(1, goal))
		r.bar:SetText(string.format(("%d / %d"), value, goal))
	else
		r.bar:Hide()
	end
	-- the bar under the name, the medals under the bar
	r.bar:ClearAllPoints()
	r.bar:SetPoint("TOPLEFT", 82, -36)
	PlaceMedals(r, CuratorOctoFull.Length(g.list))
	-- the points of the tiers earned, the experience of those waiting
	local pts, xp, waiting, claimedAll = 0, 0, false, got > 0
	local rubies = 0
	for _, a in ipairs(g.list) do
		if earned[a.id] then
			pts = pts + a.pts
			if not member and AC:Waiting(a) then
				xp, waiting = xp + AC:XP(a), true
				rubies = rubies + AC:Rubies(a)
			end
		end
		if earned[a.id] and (member or not AC:Claimed(a)) then
			claimedAll = false
		end
	end
	local nextPts = nxt and nxt.pts or 0
	CuratorOctoFull.SetShown(r.check, false)
	PaintReward(r, waiting and pts or (nxt and nextPts or pts), waiting and xp or (nxt and AC:XP(nxt) or 0), waiting, claimedAll and not nxt, member,
		waiting and rubies or (nxt and AC:Rubies(nxt) or 0))
	CuratorOctoFull.SetDesaturated(r.pts, got == 0)
	r.when:SetText("")
	-- (a tier to come: its points and its reward, dimmed)
	if not waiting and nxt then
		r.xp:SetAlpha(0.5)
		r.orb:SetAlpha(0.5)
		r.ruby:SetAlpha(0.5)
	else
		r.xp:SetAlpha(1)
		r.orb:SetAlpha(1)
		r.ruby:SetAlpha(1)
	end
end

-- The albums: their line of medals (the general achievements), the wall of their emblems.
function A:PaintAlbumWall(earned)
	local page = self.frame.ach
	local member = self.member ~= nil
	self:PaintBoardHead(earned)
	local wall = page.wall
	wall:Show()
	-- the line of medals: the general achievements of the albums
	local r = page.rows[1]
	for i = 2, CuratorOctoFull.Length(page.rows) do
		page.rows[i]:Hide()
	end
	r:Show()
	r:ClearAllPoints()
	r:SetPoint("TOPLEFT", 0, -HEAD_H)
	local g = self.albumLine
	if not g then
		g = { key = "albums", title = "Albums complete", icon = CAT_ICON.albums, list = {} }
		for _, id in ipairs(ALBUM_LINE) do
			g.list[CuratorOctoFull.Length(g.list) + 1] = AC.byId[id]
		end
		self.albumLine = g
	end
	self:PaintGroup(r, g, earned)
	-- (its bar: the albums complete)
	local sn = not member and (AC.lastSnapshot or AC:Snapshot()) or nil
	if sn then
		r.bar:Show()
		r.bar:SetProgress(sn.complete / math.max(1, CuratorOctoFull.Length(ns.Series)))
		r.bar:SetText(string.format(("%d / %d"), sn.complete, CuratorOctoFull.Length(ns.Series)))
	end
	PlaceMedals(r)
	-- the wall, in the order of the contents
	for i, c in ipairs(wall.cells) do
		local s = self:Order()[i]
		local a = s and AC.byId["album:" .. s.key]
		c.a = a
		CuratorOctoFull.SetShown(c, a ~= nil)
		if a then
			local got = earned[a.id] ~= nil
			local o, t = 0, s.official or CuratorOctoFull.Length(s.list)
			if member then
				local sum = ns.Guild:Summary(self.member, s)
				o = sum and math.min(sum.o, t) or (got and t or 0)
			else
				o = C:Progress(s)
			end
			c.set:SetTexture(MEDIA .. (s.set or "SetElwynn"))
			local gl = s.glow or GOLDEN
			c.set:SetVertexColor(0.55 + 0.45 * gl[1], 0.55 + 0.45 * gl[2], 0.55 + 0.45 * gl[3])
			CuratorOctoFull.SetDesaturated(c.set, not got and o == 0)
			c.set:SetAlpha((got or o > 0) and 1 or 0.45)
			c.ring:SetProgress(o / math.max(1, t))
			CuratorOctoFull.SetShown(c.seal, got)
			c.waiting = got and not member and AC:Waiting(a)
			-- (1.14.0: a reroll claims none, no badge)
			c.badge:SetCount((c.waiting and not Locked()) and 1 or 0)
			c.glow:SetAlpha(got and 0.25 or 0)
		end
	end
end

-------------------------------------------------------------------------------
-- The claims: the experience flies to the level, the stamp comes down
-------------------------------------------------------------------------------
-- (1.14.0) The golden boosters to choose of the albums complete among the achievements claimed (Achievements.lua:
-- AC:Claim): they land on the tab of the inventory, where the boosters are, once the experience has (UI/Quests.lua).
local function LandGolden(done, epoch, delay)
	local n = 0
	for _, a in ipairs(done or {}) do
		if AC:AlbumKind(a) then
			n = n + 1
		end
	end
	if n > 0 then
		ns.Delay(delay or 0.7, function()
			A:AddShownPacks("golden", n, epoch)
		end, ANIM)
	end
end

-- The experience of these achievements (of these cards: the achievements of each waiting, or those
-- given) claimed together: an orb flies from each card to the bar of the level, a check of gold comes
-- down on each. The number claimed.
function A:ClaimRows(rows, only)
	if self.member then
		return 0
	end
	-- (1.14.0, after its test, his word: a reroll claims none, the chat says why: Reroll.lua)
	if Locked() then
		ns.Reroll:SayNot("achievements")
		return 0
	end
	local f = self.frame
	local page = f.ach
	local todo, from = {}, {}
	for _, r in ipairs(rows) do
		if r:IsShown() then
			local list = only or (r.group and r.group.list) or { r.a }
			for _, a in ipairs(list) do
				if a and AC:Waiting(a) then
					todo[CuratorOctoFull.Length(todo) + 1] = a
					from[a] = r
				end
			end
		end
	end
	if CuratorOctoFull.Length(todo) == 0 then
		return 0
	end
	local epoch = self:BeginClaims()
	local _, done, rubies = AC:Claim(todo)
	ns.Play(ns.SND.claim)
	LandGolden(done, epoch)
	-- (1.11.0) their rubies fly to the purse of the album, from the first card
	local first = from[done[1] or false]
	if (rubies or 0) > 0 and first and f.wallet and f.wallet:IsVisible() then
		ns.Delay(0.1, function()
			Hud.Fly(ns.Rubies.ICON, first.ruby, f.wallet.gem, 24, 0.55, nil, ns.RubiesUI.GLOW)
		end, ANIM)
	end
	-- one flight a card, its experience together
	local byRow, order = {}, {}
	for _, a in ipairs(done) do
		local r = from[a]
		if not byRow[r] then
			byRow[r] = 0
			order[CuratorOctoFull.Length(order) + 1] = r
		end
		byRow[r] = byRow[r] + AC:XP(a)
	end
	for i, r in ipairs(order) do
		local i, r = i, r; local d = (i - 1) * 0.18
		local xp = byRow[r]
		r.waiting = false
		ns.Tween(0.2, function(e)
			r.claim:SetAlpha(1 - e)
		end, function()
			r.claim:Hide()
			r.claim:SetAlpha(1)
		end, Ease.linear, ANIM, d)
		ns.Tween(0.5, function(_, raw)
			r.flash:SetAlpha(0.35 * (1 - raw))
			Hud.Each(r.glow, "SetAlpha", 0.9 * (1 - raw))
		end, nil, Ease.linear, ANIM, d)
		ns.Delay(d, function()
			Hud.Burst(r.claim, GOLDEN, 14, 110, 16)
		end, ANIM)
		ns.Delay(d + 0.05, function()
			ns.Play(ns.SND.orb)
			Hud.Fly(Hud.XP, r.orb, page.lv.xp, 32, 0.6, function()
				A:AddShownXP(xp, epoch)
			end, { 0.82, 0.62, 1 })
		end, ANIM)
		-- the stamp: on the card, or on the medals of the tiers claimed
		if r.group then
			for _, m in ipairs(r.medals) do
				if m:IsShown() and m.a and from[m.a] == r then
					Hud.Stamp(m.check, 18, d + 0.25, nil, ANIM)
				end
			end
			local done = AC:NextTier(r.group) == nil
			ns.Delay(d + 0.32, function()
				ns.Play(ns.SND.stamp)
				-- (the tiers to come still wait to be reached: their reward shows, dimmed, once these land)
				if done then
					r.claimed:SetText(L["Claimed"])
					r.claimed:Show()
				end
			end, ANIM)
		else
			Hud.Stamp(r.check, 34, d + 0.32, function()
				ns.Play(ns.SND.stamp)
				Hud.Burst(r.check, GOLDEN, 12, 90, 14)
				r.claimed:SetText(L["Claimed"])
				r.claimed:SetAlpha(0)
				r.claimed:Show()
				ns.Tween(0.3, function(e)
					r.claimed:SetAlpha(e)
				end, nil, Ease.outQuad, ANIM)
			end, ANIM)
		end
	end
	self:EndClaimsIn((CuratorOctoFull.Length(order) - 1) * 0.18 + 1.3)
	return CuratorOctoFull.Length(done)
end

-- An album's achievement claimed on the wall: its orb flies to the level.
function A:ClaimCell(c)
	local f = self.frame
	local a = c.a
	if not (a and AC:Waiting(a)) or self.member then
		return
	end
	if Locked() then
		ns.Reroll:SayNot("achievements")
		return
	end
	local epoch = self:BeginClaims()
	local _, done = AC:Claim({ a })
	ns.Play(ns.SND.claim)
	LandGolden(done, epoch)
	c.waiting = false
	c.badge:SetCount(0)
	Hud.Burst(c, GOLDEN, 14, 110, 16)
	Hud.Fly(Hud.XP, c, f.ach.lv.xp, 30, 0.6, function()
		A:AddShownXP(AC:XP(a), epoch)
	end, { 0.82, 0.62, 1 })
	self:EndClaimsIn(1.2)
end

-- Every reward waiting in the category (the albums: their wall too). The number claimed.
function A:ClaimAllAch()
	local page = self.frame.ach
	if Locked() then
		ns.Reroll:SayNot("achievements")
		return 0
	end
	page.board.claimAll:Hide()
	if self.achCat == "albums" then
		local n = self:ClaimRows({ page.rows[1] })
		local cells = {}
		for _, c in ipairs(page.wall.cells) do
			if c:IsShown() and c.waiting then
				cells[CuratorOctoFull.Length(cells) + 1] = c
			end
		end
		if CuratorOctoFull.Length(cells) > 0 then
			local f = self.frame
			local epoch = self:BeginClaims()
			local list = {}
			for _, c in ipairs(cells) do
				list[CuratorOctoFull.Length(list) + 1] = c.a
			end
			local xp, done = AC:Claim(list)
			ns.Play(ns.SND.claim)
			LandGolden(done, epoch)
			-- (eight fly; the last one brings the rest)
			local flights = math.min(CuratorOctoFull.Length(cells), 8)
			local amount, sum = {}, 0
			for k = 1, flights - 1 do
				amount[k] = AC:XP(cells[k].a)
				sum = sum + amount[k]
			end
			amount[flights] = xp - sum
			for i, c in ipairs(cells) do
				local i, c = i, c; c.waiting = false
				c.badge:SetCount(0)
				if i <= flights then
					ns.Delay((i - 1) * 0.08, function()
						Hud.Fly(Hud.XP, c, f.ach.lv.xp, 28, 0.6, function()
							A:AddShownXP(amount[i], epoch)
						end, { 0.82, 0.62, 1 })
					end, ANIM)
				end
			end
			self:EndClaimsIn((flights - 1) * 0.08 + 1.2)
			n = n + CuratorOctoFull.Length(cells)
		end
		return n
	end
	-- (the cards shown first, then those of the other pages of the category at once)
	local n = self:ClaimRows(page.rows)
	local rest = AC:Claimable(self.achCat)
	if CuratorOctoFull.Length(rest) > 0 then
		local epoch = self:BeginClaims()
		local xp, done = AC:Claim(rest)
		LandGolden(done, epoch, 0.8)
		Hud.Fly(Hud.XP, page.board.claimAll, page.lv.xp, 36, 0.7, function()
			A:AddShownXP(xp, epoch)
		end, { 0.82, 0.62, 1 })
		self:EndClaimsIn(1.2)
		n = n + CuratorOctoFull.Length(rest)
	end
	return n
end

-------------------------------------------------------------------------------
-- Tooltips
-------------------------------------------------------------------------------
local function AddAch(a, earned, member)
	local got = earned[a.id]
	local hidden = a.secret and not got
	GameTooltip:AddLine(hidden and L["Secret achievement"] or AC:Name(a), got and 1 or 0.7, got and 0.84 or 0.7, got and 0.4 or 0.7)
	GameTooltip:AddLine(hidden and L[a.hint] or AC:Desc(a, AC.lastSnapshot), 0.85, 0.85, 0.85, true)
	-- (a title of prestige comes with it)
	local special = AC:SpecialOf(a)
	if special then
		local c = AC.PRESTIGE
		GameTooltip:AddLine(string.format(L["Title of prestige: %s"], AC:SpecialName(special.key, AC:Female())), c[1], c[2], c[3], true)
	end
	GameTooltip:AddLine(string.format(L["%d points"], a.pts) .. "   ·   " .. string.format(L["+%s XP"], ns.Num(AC:XP(a)))
		.. (ns.Rubies and ("   ·   " .. ns.Rubies.Text(AC:Rubies(a), 13)) or ""), 1, 0.82, 0.25)
	-- (1.14.0, his word: an album complete, a whole level of experience and a golden booster of an album to choose)
	if AC:AlbumKind(a) then
		GameTooltip:AddLine("+ " .. A:PackReward("golden", 1), 1, 0.82, 0.25)
		if not (got and not member and AC:Claimed(a)) then
			GameTooltip:AddLine(L["Its experience: the whole level you are at when you claim it."], 0.7, 0.7, 0.75, true)
		end
	end
	if got and not member then
		if type(got) == "number" and fmtDate then
			GameTooltip:AddLine(string.format(L["Earned on %s"], fmtDate("%d/%m/%Y", got)), 0.6, 0.9, 0.5)
		end
		if AC:Waiting(a) and Locked() then
			-- (1.14.0, after its test, his word: a reroll claims none, why)
			GameTooltip:AddLine(ns.Reroll:WhyNot("achievements"), 1, 0.62, 0.45, true)
		elseif AC:Waiting(a) then
			GameTooltip:AddLine(L["Click to claim"], 0.4, 1, 0.4)
		else
			GameTooltip:AddLine(L["Claimed"], 0.55, 0.95, 0.45)
		end
	elseif got then
		GameTooltip:AddLine(L["Earned"], 0.6, 0.9, 0.5)
	end
end

function A:RowTooltip(r)
	local earned = Earned()
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if r.group then
		GameTooltip:AddLine(L[r.group.title], 1, 0.84, 0.48)
		for _, a in ipairs(r.group.list) do
			local got = earned[a.id]
			local mark = got and (AC:Claimed(a) and "|cff8cf273" or "|cffffd040") or "|cff888888"
			GameTooltip:AddDoubleLine(mark .. AC:Name(a) .. "|r", string.format(L["%d points"], a.pts), 1, 1, 1, 1, 0.82, 0.25)
		end
		if r.waiting and Locked() then
			GameTooltip:AddLine(ns.Reroll:WhyNot("achievements"), 1, 0.62, 0.45, true)
		elseif r.waiting then
			GameTooltip:AddLine(L["Click to claim"], 0.4, 1, 0.4)
		end
	elseif r.a then
		AddAch(r.a, earned, self.member)
		if r.a.series and not self.member then
			GameTooltip:AddLine(L["Click: open the album"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
		end
	end
	GameTooltip:Show()
end

function A:MedalTooltip(m)
	if not m.a then
		return
	end
	GameTooltip:SetOwner(m, "ANCHOR_TOP")
	AddAch(m.a, Earned(), self.member)
	GameTooltip:Show()
end

function A:CellTooltip(c)
	local a = c.a
	if not a then
		return
	end
	local s = a.series
	GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:SeriesName(s), 1, 0.84, 0.48)
	if not self.member then
		local o, t = C:Progress(s)
		GameTooltip:AddLine(string.format(L["%d / %d cards"], o, t), 1, 1, 1)
	end
	AddAch(a, Earned(), self.member)
	if not self.member and (not AC:Waiting(a) or Locked()) then
		GameTooltip:AddLine(L["Click: open the album"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	end
	GameTooltip:Show()
end

function A:TitleTooltip(owner)
	local earned, info = Earned()
	local points = info and info.points or AC:Points(earned)
	-- (the names of the titles of a female character: theirs from their profile, mine from my character)
	local female = (info and info.female) or (not A.member and AC:Female())
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L["Titles of the collectors"], 1, 0.84, 0.48)
	for i, t in ipairs(AC.TITLES) do
		local col = AC:RankColour(i)
		local name = AC:Title(t[1], female)
		local reached = points >= t[1]
		GameTooltip:AddDoubleLine((reached and "" or "|cff888888") .. name .. (reached and "" or "|r"), string.format(L["%d points"], t[1]),
			col[1], col[2], col[3], reached and 1 or 0.55, reached and 0.82 or 0.55, reached and 0.25 or 0.55)
	end
	GameTooltip:AddLine(L["Achievement points make the title shown to the other players."], 0.8, 0.8, 0.8, true)
	-- (1.5.0) the titles of prestige, each with its achievement
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Titles of prestige"], AC.PRESTIGE[1], AC.PRESTIGE[2], AC.PRESTIGE[3])
	for _, x in ipairs(AC.SPECIAL) do
		local a = AC.byId[x.ach]
		local got = earned[x.ach] ~= nil
		local how = (a and (a.secret and not got) and L["Secret achievement"]) or (a and AC:Name(a)) or ""
		GameTooltip:AddDoubleLine((got and "" or "|cff888888") .. AC:SpecialName(x.key, female) .. (got and "" or "|r"), how,
			AC.PRESTIGE[1], AC.PRESTIGE[2], AC.PRESTIGE[3], got and 0.6 or 0.55, got and 0.9 or 0.55, got and 0.5 or 0.55)
	end
	GameTooltip:AddLine(L["A title of prestige is chosen on your profile: the other players see it instead of the title of your points, and your showcase in a frame of gold."], 0.8, 0.8, 0.8, true)
	GameTooltip:Show()
end
