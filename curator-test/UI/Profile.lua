local octoConstants = {}
local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
octoConstants.MEDIA = ns.MEDIA
local C = ns.Collection
local A = ns.Album
local AC = ns.Achievements
local LV = ns.Level
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease

-- The profile, in the album (mine, or another player's). Over it, in the head of the window, the title of the
-- collector (the points toward the next one in its bar). (1.13.0, after its first test: redone.) Its sections are
-- tabs across the top of the page, as on the contents page: the overview, the track of the rewards of the levels,
-- the finest pulls, and another player's card as a combatant (1.14.0, after its test, his word: the luck no more).
-- The overview: the card of the collector across the page (the emblem of the rank, the level and its experience; the
-- title shown and where to choose it; the next rank, or the rewards of the levels waiting and the button that claims
-- them), then the showcase on its stage,
-- the heart of the page (three cards on their pedestals, each in its light, the rays of the finest turning behind
-- it), and beside it the numbers of the collection and of what was done, in two groups. The track: the levels of a
-- page (a socket for each, a new rank every five levels, the rewards to claim: they fly to the tab of the inventory).
-- The finest pulls: the legendary and mythic cards, the titanforged ones, the thunderforged epic ones, as cards (when
-- and how each came), twelve a page. Another player's profile: the overview, the finest pulls, and (1.8.0) their
-- card as a combatant (UI/Pvp.lua). (The gauges of the next boosters and the button to them, here
-- before: in the boosters of the inventory now, and on the bar over the experience.)
-- (1.14.0: the luck no more, three tabs at most on a row, a third of it each)
octoConstants.TAB_H, octoConstants.TAB_GAP, octoConstants.TABS_ROW = 26, 6, 3
octoConstants.TOP = octoConstants.TAB_H + 8
-- the card of the collector, across the overview: its level, its title, its next rank (or its rewards waiting)
octoConstants.ID_H = 104
octoConstants.ID_LV_W, octoConstants.ID_TITLE_W = 330, 230
-- (in the part of the next rank: its texts beside its emblem)
octoConstants.NR_X = 64
-- under it, the stage of the showcase, and beside it the numbers (a line each, a line more for the cards)
octoConstants.GAP = 10
octoConstants.NUM_W, octoConstants.NUM_ROW, octoConstants.NUM_BIG = 240, 34, 58
-- the stage: the card in the middle, those on its sides (smaller, farther back)
octoConstants.MID_K, octoConstants.SIDE_K, octoConstants.SIDE_DX = 0.94, 0.66, 158
-- (the cards and their pedestals, from the top of a card in its case to the foot of the pedestal, and that top
-- above the foot of the card in the middle: the case of UI/Expertise.lua, its card at 0.82 of its stand)
octoConstants.STAND_SPAN, octoConstants.STAND_TOP = 328, 261
-- the track: ten levels a row, six rows; (1.11.0) two pages: the levels up to the legend, then those past it
octoConstants.COLS, octoConstants.ROWS, octoConstants.ROW_H, octoConstants.ROW_Y = 10, 6, 56, -158
octoConstants.TRACK_PAGES = { { 1, 60 }, { 61, 100 } }
local function TrackPage(level)
	return (level or 1) > octoConstants.TRACK_PAGES[1][2] and 2 or 1
end
-- the finest pulls: six cards a row, two rows
octoConstants.PULL_COLS, octoConstants.PULL_ROWS, octoConstants.PULL_Y = 6, 2, -30
octoConstants.GOLDEN = { 1, 0.8, 0.32 }
octoConstants.DIM = { 0.62, 0.62, 0.68 }
octoConstants.GREEN = { 0.45, 1, 0.4 }
octoConstants.LABEL = { 0.84, 0.84, 0.88 }
-- the owner of the animations of the claims (shared with the quests and the achievements)
octoConstants.ANIM = A.CLAIMS
local fmtDate = date or (os and os.date)

octoConstants.SECTIONS = {
	{ key = "overview", label = "Overview", icon = { "Interface\\Icons\\INV_Misc_Head_Dragon_01" } },
	{ key = "track", label = "Reward track" },
	{ key = "pulls", label = "Finest pulls", icon = { "Gem5" } },
	-- (1.8.0: another player's card as a combatant, made their own way, UI/Pvp.lua; 1.14.0, his word: gone with the PvP
	-- until its rework)
}
octoConstants.HOW = { b = "Booster", f = "Found on a creature", k = "Contract", t = "Trade", i = "From an innkeeper", g = "Golden booster",
	-- (1.12.0: bought for rubies, from the reseller; before, from the antiquarian; 1.14.0: the reward of a level)
	r = "Bought for rubies", l = "The reward of a level" }
-- the numbers: what each counts, its icon, its group (the collection, what was done); the cards first, bigger, with
-- the bar of the whole collection
octoConstants.STATS = {
	{ key = "opened", label = "Boosters opened", icon = { "PackZoneChoice" }, group = 2 },
	{ key = "cards", label = "Cards", icon = { "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" }, group = 1, big = true },
	{ key = "complete", label = "Albums complete", icon = { "AlbumSeal" }, group = 1 },
	{ key = "contracts", label = "Contracts signed", icon = { "Seal" }, group = 2 },
	{ key = "found", label = "Found on creatures", icon = { "Interface\\Icons\\Ability_Tracking" }, group = 2,
		-- (another player's profile does not tell it: their achievements instead)
		other = { key = "achs", label = "Achievements", icon = { "AchMedal" } } },
	{ key = "shiny", label = "Thunderforged cards", icon = { "Twinkle", nil, { 0.62, 0.84, 1 } }, group = 1 },
	{ key = "holo", label = "Titanforged cards", icon = { "Twinkle", nil, { 1, 0.84, 0.5 } }, group = 1 },
	{ key = "points", label = "Achievement points", icon = { "TierMedal", nil, { 1, 0.8, 0.32 } }, group = 2 },
}
-- (the order of the lines in each group: the cards, the albums complete, the finishes; the boosters, the contracts,
-- the cards found, the points)
octoConstants.GROUPS = { { label = "Collection", keys = { "cards", "complete", "shiny", "holo" } },
	{ label = "Activity", keys = { "opened", "contracts", "found", "points" } } }

-- The levels where a rank begins: their rank.
octoConstants.RANK_AT = {}
for r, rank in ipairs(LV.RANKS) do
	octoConstants.RANK_AT[rank.level] = r
end

local function Waiting(n)
	return n == 1 and L["1 reward to claim"] or string.format(L["%d rewards to claim"], n)
end

-- "Légendaire · Holographique"
local function RarityLine(card, finish)
	local f = C:FinishName(card, finish)
	return L[ns.RARITY[card.rarity].label] .. (f and (" · " .. f) or "")
end

-- A colour as the code of a text.
local function Hex(c)
	return string.format(("|cff%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- A text that keeps to a width: in its font, smaller only when it does not fit (its colour set again: the font
-- of an object brings its own).
local function Keep(fs, font, text, width, from, to, colour)
	S.SetFontObject(fs, font)
	fs:SetText(text)
	if ns.TextWidth(fs) > width then
		S.Fit(fs, text, width, from, to)
	end
	if colour then
		fs:SetTextColor(colour[1], colour[2], colour[3])
	end
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- A stamp coming down on a texture: from big and clear to its size, then land().
local function Stamp(tex, size, delay, land)
	return Hud.Stamp(tex, size, delay, land, octoConstants.ANIM)
end

-- A socket of the track: a ring of bronze with the booster of its level, a ring of gold with the
-- emblem of its rank where a rank begins; its number under it.
local function NewNode(tr, level)
	local rank = octoConstants.RANK_AT[level]
	local size = rank and 54 or 42
	local n = CreateFrame("Button", nil, tr)
	CuratorOctoFull.SetSize(n, size, size)
	n.level, n.rank = level, rank
	n.glow = n:CreateTexture(nil, "BACKGROUND")
	n.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	n.glow:SetBlendMode("ADD")
	n.glow:SetVertexColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	CuratorOctoFull.SetSize(n.glow, size * 2.2, size * 2.2)
	n.glow:SetPoint("CENTER")
	n.glow:SetAlpha(0)
	n.bg = n:CreateTexture(nil, "ARTWORK")
	n.bg:SetTexture(octoConstants.MEDIA .. (rank and "TrackNodeBig" or "TrackNode"))
	n.bg:SetAllPoints()
	n.icon = n:CreateTexture(nil, "ARTWORK", nil, 2)
	n.icon:SetPoint("CENTER")
	if rank then
		LV.SetIcon(n.icon, rank)
	else
		-- (1.14.0: a reward to choose among three; a booster of a zone to choose before)
		n.icon:SetTexture(Hud.PackIcon("offer"))
	end
	n.iconSize = rank and 32 or 30
	CuratorOctoFull.SetSize(n.icon, n.iconSize, n.iconSize)
	n.check = n:CreateTexture(nil, "OVERLAY")
	n.check:SetTexture(octoConstants.MEDIA .. "Check")
	CuratorOctoFull.SetSize(n.check, 22, 22)
	n.check:SetPoint("CENTER", n, "BOTTOMRIGHT", -7, 7)
	n.label = Hud.Text(n, 10, "OUTLINE")
	n.label:SetPoint("TOP", n, "BOTTOM", 0, rank and 6 or 2)
	n.label:SetText(tostring(level))
	CuratorOctoFull.SetScript(n, "OnClick", function(self)
		if self.can then
			A:ClaimTrack({ self.level })
		end
	end)
	CuratorOctoFull.SetScript(n, "OnEnter", function(self)
		A:NodeTooltip(self)
	end)
	CuratorOctoFull.SetScript(n, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return n
end

-- A line of the numbers: its icon, what it counts, its number on the right (the cards: bigger, the bar of the whole
-- collection under them). A thin line under it.
local function NewStat(parent, w, stat)
	local big = stat.big
	local t = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(t, w, big and octoConstants.NUM_BIG or octoConstants.NUM_ROW)
	t.big = big
	t.icon = t:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(t.icon, big and 24 or 20, big and 24 or 20)
	if big then
		t.icon:SetPoint("TOPLEFT", 2, -4)
	else
		t.icon:SetPoint("LEFT", 2, 0)
	end
	Hud.SetIcon(t.icon, stat.icon)
	t.label = S.Text(t, big and "GameFontNormal" or "GameFontHighlightSmall", "LEFT")
	CuratorOctoFull.SetWordWrap(t.label, false)
	t.value = Hud.Text(t, big and 18 or 14, "OUTLINE")
	t.value:SetJustifyH("RIGHT")
	t.value:SetTextColor(1, 0.9, 0.62)
	if big then
		t.label:SetPoint("LEFT", t.icon, "RIGHT", 8, 0)
		t.value:SetPoint("RIGHT", t, "TOPRIGHT", -2, -16)
		t.bar = Hud.XPBar(t, w - 4, 12, { 1, 0.78, 0.3 })
		t.bar:SetPoint("BOTTOMLEFT", 2, 8)
	else
		t.label:SetPoint("LEFT", t.icon, "RIGHT", 8, 0)
		t.label:SetTextColor(octoConstants.LABEL[1], octoConstants.LABEL[2], octoConstants.LABEL[3])
		t.value:SetPoint("RIGHT", -2, 0)
	end
	t.line = t:CreateTexture(nil, "BORDER")
	CuratorOctoFull.ColorTexture(t.line, 1, 0.86, 0.6, 0.1)
	t.line:SetHeight(1)
	t.line:SetPoint("BOTTOMLEFT", 0, 0)
	t.line:SetPoint("BOTTOMRIGHT", 0, 0)
	t.stat = stat
	t:EnableMouse(true)
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		A:StatTooltip(self)
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return t
end

-- A card of the showcase, standing on its pedestal in its light (where: from the stage, st.midBottom and
-- st.sideBottom, the feet of the cards under its top).
-- (1.14.0) Where a card stands, of a showcase of n (three; five with the Museum Showcase, a talent of the Archivist:
-- the ones of the sides closer, smaller, two more beyond them): its middle, the foot of the card, its size, its pedestal.
local function StandAt(st, i, n)
	if n and n > 3 then
		if i == 1 then
			return st.mid, st.midBottom, octoConstants.MID_K * 0.9, 196
		elseif i <= 3 then
			return st.mid + (i == 2 and -1 or 1) * 114, st.sideBottom, octoConstants.SIDE_K * 0.88, 132
		end
		return st.mid + (i == 4 and -1 or 1) * 198, st.sideBottom + 14, octoConstants.SIDE_K * 0.7, 104
	end
	if i == 1 then
		return st.mid, st.midBottom, octoConstants.MID_K, 210
	end
	return st.mid + (i == 2 and -octoConstants.SIDE_DX or octoConstants.SIDE_DX), st.sideBottom, octoConstants.SIDE_K, 150
end

local function PlaceStand(st, c, n)
	local BW, BH = unpack(ns.CARD_SIZES.big)
	local x, bottom, k, pw = StandAt(st, c.slot, n)
	local w, h = BW * k, BH * k
	CuratorOctoFull.SetSize(c.spot, pw * 0.95, -bottom + 40)
	c.spot:ClearAllPoints()
	c.spot:SetPoint("TOP", st, "TOPLEFT", x, -4)
	CuratorOctoFull.SetSize(c.ped, pw, pw / 2)
	-- (the middle of its top under the card)
	c.ped:ClearAllPoints()
	c.ped:SetPoint("TOP", st, "TOPLEFT", x, bottom + pw * 0.185)
	CuratorOctoFull.SetSize(c.floor, w * 1.2, 26)
	c.floor:ClearAllPoints()
	c.floor:SetPoint("CENTER", st, "TOPLEFT", x, bottom + 2)
	c:SetScale(k)
	c:ClearAllPoints()
	c:SetPoint("TOPLEFT", st, "TOPLEFT", (x - w / 2) / k, (bottom + h) / k)
	-- (1.11.0: where it stands, for a card in its case: UI/Expertise.lua)
	c.standX, c.standBottom, c.standK = x, bottom, k
end

local function NewStand(st, i)
	local spot = st:CreateTexture(nil, "BORDER", nil, 1)
	spot:SetTexture(octoConstants.MEDIA .. "Spotlight")
	spot:SetBlendMode("ADD")
	spot:SetAlpha(0.26)
	local ped = st:CreateTexture(nil, "ARTWORK")
	ped:SetTexture(octoConstants.MEDIA .. "Pedestal")
	local shadow = st:CreateTexture(nil, "ARTWORK", nil, 1)
	shadow:SetTexture(octoConstants.MEDIA .. "Shadow")
	shadow:SetAlpha(0.8)
	local c = ns.NewCard(st.holder, "big")
	c.shadow:SetAlpha(0.5)
	c.slot = i
	c.spot, c.ped, c.floor = spot, ped, shadow
	PlaceStand(st, c, 3)
	-- (the fourth and the fifth: only in a showcase of five)
	if i > 3 then
		spot:Hide()
		ped:Hide()
		shadow:Hide()
		c:Hide()
	end
	CuratorOctoFull.SetScript(c, "OnEnter", function(self)
		A:ProfileCardEnter(self)
	end)
	CuratorOctoFull.SetScript(c, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(c, "OnClick", function(self)
		A:ProfileCardClick(self.shown, self.finish, self.pattern)
	end)
	return c
end

-- One of the finest pulls: the card, how and when it came under it.
local function NewPull(parent, w, level)
	local CW, CH = unpack(ns.CARD_SIZES.small)
	local r = CreateFrame("Frame", nil, parent)
	r:SetFrameLevel(level)
	CuratorOctoFull.SetSize(r, w, CH + 34)
	local card = ns.NewCard(r, "small")
	card:SetPoint("TOP", r, "TOP", 0, 0)
	card.shadow:SetAlpha(0.6)
	CuratorOctoFull.SetScript(card, "OnEnter", function()
		A:ProfileRowEnter(r)
	end)
	CuratorOctoFull.SetScript(card, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(card, "OnClick", function()
		A:ProfileCardClick(r.shown, r.finish, r.card.pattern)
	end)
	r.card = card
	r.howText = S.Text(r, "GameFontHighlightSmall")
	r.howText:SetPoint("TOP", r, "TOP", 0, -CH - 6)
	r.howText:SetWidth(w)
	CuratorOctoFull.SetWordWrap(r.howText, false)
	r.when = S.Text(r, "GameFontDisableSmall")
	r.when:SetPoint("TOP", r.howText, "BOTTOM", 0, -2)
	r.when:SetWidth(w)
	CuratorOctoFull.SetWordWrap(r.when, false)
	return r
end

-- The level of the collector, on the left of the card of the collector: the emblem of its rank, the level and the
-- rank beside it, the experience in a bar and what is left of it. As the box of the level of the other pages
-- (Hud.LevelBox: box:Paint(xp), nil a level not known; its emblem, its bar, for the rewards landing in it).
local function NewLevel(parent, w, h)
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, w, h)
	f.emblem = Hud.Emblem(f, 70)
	f.emblem:SetPoint("LEFT", 16, 0)
	f.level = Hud.Text(f, 20, "OUTLINE")
	f.level:SetPoint("TOPLEFT", 100, -18)
	f.level:SetTextColor(1, 0.92, 0.7)
	f.rank = S.Text(f, "GameFontHighlight", "LEFT")
	f.rank:SetPoint("BOTTOMLEFT", f.level, "BOTTOMRIGHT", 10, 1)
	CuratorOctoFull.SetWordWrap(f.rank, false)
	f.xp = Hud.XPBar(f, w - 100 - 18, 14)
	f.xp:SetPoint("TOPLEFT", 100, -52)
	f.note = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.note:SetWidth(w - 100 - 18)
	CuratorOctoFull.SetWordWrap(f.note, false)
	f.note:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	function f:Paint(xp)
		local known = xp ~= nil
		CuratorOctoFull.SetShown(self.emblem, known)
		CuratorOctoFull.SetShown(self.xp, known)
		self.note:ClearAllPoints()
		if not known then
			self.level:SetText("")
			self.rank:SetText("")
			self.note:SetPoint("LEFT", 24, 0)
			self.note:SetWidth(w - 40)
			CuratorOctoFull.SetWordWrap(self.note, true)
			self.note:SetText(L["Level unknown (an older Curator)"])
			return
		end
		self.note:SetPoint("TOPLEFT", 100, -74)
		self.note:SetWidth(w - 100 - 18)
		CuratorOctoFull.SetWordWrap(self.note, false)
		local level, into, need = LV.Of(xp)
		local r, rank = LV.RankOf(level)
		if self.emblem.rank ~= r or not self.emblem.painted then
			self.emblem.painted = true
			self.emblem:SetRank(r)
		end
		self.level:SetText(string.format(L["Level %d"], level))
		Keep(self.rank, "GameFontHighlight", Hex(rank.color) .. L[rank.name] .. "|r", w - 100 - 18 - ns.TextWidth(self.level) - 10, 12, 9)
		self.xp:SetProgress(need and into / need or 1)
		self.xp:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
		self.note:SetText(need and string.format(L["%s XP to level %d"], ns.Num(need - into), level + 1) or string.format(L["Total: %s XP"], ns.Num(xp)))
	end
	return f
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
function A:BuildProfile()
	local f = self.frame
	if f.prof then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.prof = page
	local W = U.PAGE_W - 32
	local H = U.PAGE_H - 20 - octoConstants.TOP
	page.rw = W

	-- the sections: tabs across the top of the page (laid out as they are shown: A:PaintProfileNav)
	page.nav = {}
	for i, sec in ipairs(octoConstants.SECTIONS) do
		local i, sec = i, sec; local b = Hud.NavButton(page, (W - (octoConstants.TABS_ROW - 1) * octoConstants.TAB_GAP) / octoConstants.TABS_ROW, octoConstants.TAB_H)
		b.sec = sec
		if sec.icon then
			Hud.SetIcon(b.icon, sec.icon)
		end
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetProfileSection(sec.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:ProfileNavTooltip(self)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		page.nav[i] = b
	end
	-- (the overview, its stage and the finest pulls at the level of the page: their cards no higher than those of
	-- the other pages, under the card shown big)
	local base = page:GetFrameLevel()
	-- under the tabs, the section shown
	local body = CreateFrame("Frame", nil, page)
	body:SetFrameLevel(base)
	body:SetPoint("TOPLEFT", 0, -octoConstants.TOP)
	body:SetPoint("BOTTOMRIGHT")
	page.content = body

	-- the overview: the card of the collector, the showcase on its stage, the numbers beside it
	local ov = CreateFrame("Frame", nil, body)
	ov:SetFrameLevel(base)
	ov:SetAllPoints()
	page.over = ov
	local id = CreateFrame("Frame", nil, ov)
	id:SetFrameLevel(base)
	id:SetPoint("TOPLEFT")
	id:SetPoint("TOPRIGHT")
	id:SetHeight(octoConstants.ID_H)
	id.frame = Hud.Card(id, 0.8)
	page.id = id
	-- (a line of gold between its parts; the second one only with something on its right)
	id.lines = {}
	for i, x in ipairs({ octoConstants.ID_LV_W, octoConstants.ID_LV_W + octoConstants.ID_TITLE_W }) do
		local t = id:CreateTexture(nil, "BORDER")
		CuratorOctoFull.ColorTexture(t, 1, 0.8, 0.4, 0.22)
		CuratorOctoFull.SetSize(t, 1, octoConstants.ID_H - 32)
		t:SetPoint("LEFT", id, "TOPLEFT", x, -octoConstants.ID_H / 2)
		id.lines[i] = t
	end
	-- its level: the emblem of its rank, the level, the experience
	page.lv = NewLevel(id, octoConstants.ID_LV_W, octoConstants.ID_H)
	page.lv:SetPoint("TOPLEFT")
	page.lv:EnableMouse(true)
	CuratorOctoFull.SetScript(page.lv, "OnEnter", function(self)
		A:LevelTooltip(self)
	end)
	CuratorOctoFull.SetScript(page.lv, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.lv.emblem:EnableMouse(true)
	CuratorOctoFull.SetScript(page.lv.emblem, "OnEnter", function(self)
		A:RankTooltip(self, self.rank)
	end)
	CuratorOctoFull.SetScript(page.lv.emblem, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- (1.5.0) the title shown, chosen there (mine): the one of the points, or a title of prestige earned
	local tb = CreateFrame("Frame", nil, id)
	CuratorOctoFull.SetSize(tb, octoConstants.ID_TITLE_W, octoConstants.ID_H)
	tb:SetPoint("TOPLEFT", octoConstants.ID_LV_W, 0)
	tb.label = S.Text(tb, "GameFontNormal", "LEFT")
	tb.label:SetPoint("TOPLEFT", 18, -18)
	tb.label:SetText(L["Title shown"])
	tb.pick = S.Dropdown(tb, octoConstants.ID_TITLE_W - 30)
	tb.pick:SetPoint("TOPLEFT", 14, -38)
	tb.pick:SetupMenu(function(_, root)
		A:TitleMenu(root)
	end)
	tb.pick:SetTooltip(function(tooltip)
		A:TitlePickTooltip(tooltip)
	end)
	tb.more = S.Text(tb, "GameFontHighlightSmall", "LEFT")
	tb.more:SetPoint("TOPLEFT", 18, -74)
	tb.more:SetWidth(octoConstants.ID_TITLE_W - 30)
	CuratorOctoFull.SetWordWrap(tb.more, false)
	tb.more:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	page.titleBox = tb
	-- (another player's: their title, as they show it)
	local mt = CreateFrame("Frame", nil, id)
	CuratorOctoFull.SetSize(mt, octoConstants.ID_TITLE_W, octoConstants.ID_H)
	mt:SetPoint("TOPLEFT", octoConstants.ID_LV_W, 0)
	mt.label = S.Text(mt, "GameFontNormal", "LEFT")
	mt.label:SetPoint("TOPLEFT", 18, -18)
	mt.label:SetText(L["Title shown"])
	mt.name = S.Text(mt, "GameFontNormalLarge", "LEFT")
	mt.name:SetPoint("TOPLEFT", 18, -42)
	mt.name:SetWidth(octoConstants.ID_TITLE_W - 30)
	CuratorOctoFull.SetWordWrap(mt.name, false)
	mt.more = S.Text(mt, "GameFontHighlightSmall", "LEFT")
	mt.more:SetPoint("TOPLEFT", 18, -74)
	mt.more:SetWidth(octoConstants.ID_TITLE_W - 30)
	CuratorOctoFull.SetWordWrap(mt.more, false)
	mt.more:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	mt:Hide()
	page.memberTitle = mt
	-- on the right: the next rank (its emblem, its name, its level), or the rewards of the levels waiting (mine)
	local RW = W - octoConstants.ID_LV_W - octoConstants.ID_TITLE_W
	local nr = CreateFrame("Frame", nil, id)
	CuratorOctoFull.SetSize(nr, RW, octoConstants.ID_H)
	nr:SetPoint("TOPLEFT", octoConstants.ID_LV_W + octoConstants.ID_TITLE_W, 0)
	nr.emblem = Hud.Emblem(nr, 42)
	nr.emblem:SetPoint("LEFT", 14, 0)
	nr.label = S.Text(nr, "GameFontHighlightSmall", "LEFT")
	nr.label:SetPoint("TOPLEFT", octoConstants.NR_X, -30)
	nr.label:SetWidth(RW - octoConstants.NR_X - 6)
	CuratorOctoFull.SetWordWrap(nr.label, false)
	nr.label:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	nr.name = Hud.Text(nr, 14, "OUTLINE")
	nr.name:SetPoint("TOPLEFT", octoConstants.NR_X, -45)
	nr.name:SetJustifyH("LEFT")
	nr.at = S.Text(nr, "GameFontHighlightSmall", "LEFT")
	nr.at:SetPoint("TOPLEFT", octoConstants.NR_X, -64)
	nr.at:SetWidth(RW - octoConstants.NR_X - 6)
	CuratorOctoFull.SetWordWrap(nr.at, false)
	nr:EnableMouse(true)
	CuratorOctoFull.SetScript(nr, "OnEnter", function(self)
		if self.r then
			A:RankTooltip(self, self.r)
		end
	end)
	CuratorOctoFull.SetScript(nr, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.nextRank = nr
	local cl = CreateFrame("Frame", nil, id)
	CuratorOctoFull.SetSize(cl, RW, octoConstants.ID_H)
	cl:SetPoint("TOPLEFT", octoConstants.ID_LV_W + octoConstants.ID_TITLE_W, 0)
	cl.badge = Hud.Badge(cl, 22)
	cl.badge:SetPoint("TOPLEFT", 14, -16)
	cl.text = S.Text(cl, "GameFontNormal", "LEFT")
	cl.text:SetPoint("LEFT", cl.badge, "RIGHT", 6, 0)
	cl.text:SetWidth(RW - 50)
	CuratorOctoFull.SetWordWrap(cl.text, false)
	cl.text:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	cl.go = Hud.ClaimButton(cl, RW - 28, 32, L["Claim all"])
	cl.go:SetPoint("BOTTOM", 0, 18)
	CuratorOctoFull.SetScript(cl.go, "OnClick", function()
		A:ClaimFromOverview()
	end)
	CuratorOctoFull.SetScript(cl.go, "OnEnter", function(self)
		A:ClaimTooltip(self)
	end)
	CuratorOctoFull.SetScript(cl.go, "OnLeave", function()
		GameTooltip:Hide()
	end)
	cl:Hide()
	page.claim = cl

	-- the showcase on its stage, the heart of the page
	local stageW, stageH = W - octoConstants.NUM_W - octoConstants.GAP, H - octoConstants.ID_H - octoConstants.GAP
	local st = CreateFrame("Frame", nil, ov)
	st:SetFrameLevel(base)
	st:SetPoint("TOPLEFT", 0, -(octoConstants.ID_H + octoConstants.GAP))
	CuratorOctoFull.SetSize(st, stageW, stageH)
	-- (its lights stay on it)
	if st.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(st, true)
	end
	st.mid = stageW / 2
	-- (the cards and their pedestals in the middle of its height)
	st.midBottom = -(math.floor((stageH - octoConstants.STAND_SPAN) / 2) + octoConstants.STAND_TOP)
	st.sideBottom = st.midBottom + 22
	st.frame = Hud.Card(st, 0.8)
	local BH = ns.CARD_SIZES.big[2]
	-- (the lights over the stage, the cards over them)
	local light = CreateFrame("Frame", nil, st)
	light:SetFrameLevel(base + 1)
	light:SetAllPoints()
	st.holder = CreateFrame("Frame", nil, st)
	st.holder:SetFrameLevel(base + 1)
	st.holder:SetAllPoints()
	st.halo = light:CreateTexture(nil, "BORDER")
	st.halo:SetTexture(octoConstants.MEDIA .. "Glow")
	st.halo:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(st.halo, 330, 380)
	st.halo:SetPoint("CENTER", st, "TOPLEFT", st.mid, st.midBottom + BH * octoConstants.MID_K / 2)
	st.halo:SetAlpha(0)
	st.rays = light:CreateTexture(nil, "BORDER", nil, 1)
	st.rays:SetTexture(octoConstants.MEDIA .. "Rays")
	st.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(st.rays, 420, 420)
	st.rays:SetPoint("CENTER", st, "TOPLEFT", st.mid, st.midBottom + BH * octoConstants.MID_K / 2)
	st.rays:SetAlpha(0)
	st.title = S.Text(st, "GameFontNormal", "LEFT")
	st.title:SetPoint("TOPLEFT", 14, -11)
	st.title:SetText(L["Showcase"])
	st.info = Hud.InfoButton(st, 18)
	st.info:SetPoint("LEFT", st.title, "RIGHT", 6, 0)
	st.info.tip = function(self)
		A:ShowcaseTooltip(self)
	end
	st.pins = S.Text(st, "GameFontHighlightSmall", "RIGHT")
	st.pins:SetPoint("TOPRIGHT", -14, -12)
	st.pins:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	st.cards = {}
	for i = 1, (C.SHOWCASE_MAX or C.SHOWCASE_SIZE) do
		st.cards[i] = NewStand(st, i)
	end
	st.layout = 3
	st.empty = S.Text(st, "GameFontHighlight")
	st.empty:SetPoint("CENTER", st, "TOPLEFT", st.mid, st.midBottom + BH * octoConstants.MID_K / 2)
	st.empty:SetWidth(stageW - 100)
	CuratorOctoFull.SetWordWrap(st.empty, true)
	-- (1.5.0) a title of prestige: the showcase in a frame of gold
	st.gold = CreateFrame("Frame", nil, st)
	st.gold:SetAllPoints()
	st.gold:SetFrameLevel(base + 3)
	st.gold.edge = st.gold:CreateTexture(nil, "OVERLAY")
	st.gold.edge:SetTexture(octoConstants.MEDIA .. "Edge")
	st.gold.edge:SetBlendMode("ADD")
	st.gold.edge:SetPoint("TOPLEFT", 2, -2)
	st.gold.edge:SetPoint("BOTTOMRIGHT", -2, 2)
	st.gold.edge:SetVertexColor(1, 0.76, 0.3)
	st.gold.edge:SetAlpha(0.45)
	st.gold.corners = {}
	for k, c in ipairs({ { "TOPLEFT", 0, 1, 0, 1, 1, -1 }, { "TOPRIGHT", 1, 0, 0, 1, -1, -1 }, { "BOTTOMLEFT", 0, 1, 1, 0, 1, 1 }, { "BOTTOMRIGHT", 1, 0, 1, 0, -1, 1 } }) do
		local t = st.gold:CreateTexture(nil, "OVERLAY", nil, 1)
		t:SetTexture(octoConstants.MEDIA .. "GoldCorner")
		t:SetTexCoord(c[2], c[3], c[4], c[5])
		CuratorOctoFull.SetSize(t, 58, 58)
		t:SetPoint(c[1], c[6], c[7])
		st.gold.corners[k] = t
	end
	st.gold:Hide()
	page.stage = st
	-- (kept under these names for the other pages: the cards of the showcase)
	page.cards = st.cards

	-- the numbers, beside the stage: the collection, then what was done
	local nb = CreateFrame("Frame", nil, ov)
	nb:SetFrameLevel(base)
	nb:SetPoint("TOPRIGHT", 0, -(octoConstants.ID_H + octoConstants.GAP))
	CuratorOctoFull.SetSize(nb, octoConstants.NUM_W, stageH)
	nb.frame = Hud.Card(nb, 0.8)
	page.numbers = nb
	page.stats = {}
	local byKey = {}
	for i, stat in ipairs(octoConstants.STATS) do
		local t = NewStat(nb, octoConstants.NUM_W - 28, stat)
		page.stats[i] = t
		byKey[stat.key] = t
	end
	nb.heads = {}
	local y = -12
	for g, group in ipairs(octoConstants.GROUPS) do
		local hd = S.Text(nb, "GameFontNormal", "LEFT")
		hd:SetPoint("TOPLEFT", 14, y)
		hd:SetText(L[group.label])
		nb.heads[g] = hd
		y = y - 20
		for _, key in ipairs(group.keys) do
			local t = byKey[key]
			t:SetPoint("TOPLEFT", 14, y)
			y = y - t:GetHeight()
		end
		y = y - 16
	end

	-- the track of the levels
	local tr = CreateFrame("Frame", nil, body)
	tr:SetFrameLevel(base)
	tr:SetAllPoints()
	page.track = tr
	tr.sub = S.Text(tr, "GameFontHighlight", "LEFT")
	tr.sub:SetPoint("TOPLEFT", 4, -10)
	tr.sub:SetWidth(W - 180)
	CuratorOctoFull.SetWordWrap(tr.sub, true)
	tr.claimAll = Hud.ClaimButton(tr, 160, 32, L["Claim all"])
	tr.claimAll:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(tr.claimAll, "OnClick", function()
		-- (1.14.0: the levels claimed; none left, the rewards to choose that wait)
		if CuratorOctoFull.Length(LV:Unclaimed()) > 0 then
			A:ClaimTrack()
		elseif ns.OffersUI then
			ns.OffersUI:Show()
		end
	end)
	-- the rank: this one, how far to the next one, the next one
	tr.cur = Hud.Emblem(tr, 66)
	tr.cur:SetPoint("CENTER", tr, "TOPLEFT", 42, -78)
	tr.cur:EnableMouse(true)
	CuratorOctoFull.SetScript(tr.cur, "OnEnter", function(self)
		A:RankTooltip(self)
	end)
	CuratorOctoFull.SetScript(tr.cur, "OnLeave", function()
		GameTooltip:Hide()
	end)
	tr.curName = Hud.Text(tr, 12, "OUTLINE")
	tr.curName:SetPoint("TOP", tr.cur, "BOTTOM", 0, 2)
	tr.nxt = Hud.Emblem(tr, 66)
	tr.nxt:SetPoint("CENTER", tr, "TOPLEFT", W - 42, -78)
	tr.nxt:EnableMouse(true)
	CuratorOctoFull.SetScript(tr.nxt, "OnEnter", function(self)
		A:RankTooltip(self, self.rank)
	end)
	CuratorOctoFull.SetScript(tr.nxt, "OnLeave", function()
		GameTooltip:Hide()
	end)
	tr.nxtName = Hud.Text(tr, 12, "OUTLINE")
	tr.nxtName:SetPoint("TOP", tr.nxt, "BOTTOM", 0, 2)
	tr.rankBar = Hud.XPBar(tr, W - 2 * 90, 14, { 1, 0.76, 0.3 })
	tr.rankBar:SetPoint("LEFT", tr, "TOPLEFT", 90, -82)
	tr.rankLabel = S.Text(tr, "GameFontNormal")
	tr.rankLabel:SetPoint("BOTTOM", tr.rankBar, "TOP", 0, 9)
	-- the sockets of a page, ten a row, the channel of each row behind them and its light
	local function NodeX(col)
		return 30 + (col - 1) * (W - 60) / (octoConstants.COLS - 1)
	end
	tr.NodeX = NodeX
	tr.lines, tr.fills, tr.nodes = {}, {}, {}
	for row = 1, octoConstants.ROWS do
		local y = octoConstants.ROW_Y - (row - 1) * octoConstants.ROW_H
		local line = tr:CreateTexture(nil, "BORDER")
		line:SetTexture(octoConstants.MEDIA .. "TrackLine")
		line:SetHeight(14)
		line:SetPoint("LEFT", tr, "TOPLEFT", NodeX(1), y)
		line:SetPoint("RIGHT", tr, "TOPLEFT", NodeX(octoConstants.COLS), y)
		local fill = tr:CreateTexture(nil, "BORDER", nil, 2)
		fill:SetTexture(octoConstants.MEDIA .. "TrackFill")
		fill:SetBlendMode("ADD")
		fill:SetHeight(10)
		fill:SetPoint("LEFT", tr, "TOPLEFT", NodeX(1), y)
		tr.lines[row], tr.fills[row] = line, fill
	end
	for level = 1, LV.MAX do
		local n = NewNode(tr, level)
		local pg = TrackPage(level)
		local i = level - octoConstants.TRACK_PAGES[pg][1]
		local col, row = CuratorOctoFull.Mod(i , octoConstants.COLS) + 1, math.floor(i / octoConstants.COLS) + 1
		n:SetPoint("CENTER", tr, "TOPLEFT", NodeX(col), octoConstants.ROW_Y - (row - 1) * octoConstants.ROW_H)
		n.page = pg
		tr.nodes[level] = n
	end
	-- (1.11.0) the two pages of the track: up to the legend, past it (the rewards waiting on each)
	tr.pages = {}
	for pg, span in ipairs(octoConstants.TRACK_PAGES) do
		local pg, span = pg, span; local b = Hud.NavButton(tr, 200, 26)
		b:SetPoint("CENTER", tr, "TOPLEFT", W / 2 + (pg == 1 and -104 or 104), -118)
		LV.SetIcon(b.icon, LV.RankOf(span[2]))
		b.span = span
		CuratorOctoFull.SetScript(b, "OnClick", function()
			if A.trackPage ~= pg then
				ns.Play(ns.SND.page)
				A.trackPage = pg
				A:PaintTrack()
			end
		end)
		tr.pages[pg] = b
	end
	-- the level reached: a ring of light around its socket, a wave leaving it now and then (above
	-- the sockets)
	tr.top = CreateFrame("Frame", nil, tr)
	tr.top:SetAllPoints()
	tr.top:SetFrameLevel(tr:GetFrameLevel() + 10)
	tr.here = tr.top:CreateTexture(nil, "OVERLAY")
	tr.wave = tr.top:CreateTexture(nil, "OVERLAY")
	for _, t in ipairs({ tr.here, tr.wave }) do
		t:SetTexture(octoConstants.MEDIA .. "Ring")
		t:SetBlendMode("ADD")
		t:SetVertexColor(1, 0.86, 0.45)
	end
	tr.waiting = {}
	tr.t = 0
	CuratorOctoFull.SetScript(tr, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		-- (the rewards waiting glow, they beat)
		local a = 0.6 + 0.4 * math.sin(self.t * 3.4)
		local k = 1 + 0.12 * (0.5 + 0.5 * math.sin(self.t * 3.4))
		for n in pairs(self.waiting) do
			n.glow:SetAlpha(a)
			CuratorOctoFull.SetSize(n.icon, n.iconSize * k, n.iconSize * k)
		end
		local at = self.markAt
		if at then
			local size = at:GetWidth()
			local kk = 1.45 + 0.06 * math.sin(self.t * 3)
			CuratorOctoFull.SetSize(self.here, size * kk, size * kk)
			self.here:SetAlpha(0.7 + 0.25 * math.sin(self.t * 3))
			local w = (CuratorOctoFull.Mod(self.t , 2)) / 2
			CuratorOctoFull.SetSize(self.wave, size * (1.4 + 1.1 * w), size * (1.4 + 1.1 * w))
			self.wave:SetAlpha(0.6 * (1 - w))
		end
	end)

	-- the finest pulls, as cards, six a row
	local pl = CreateFrame("Frame", nil, body)
	pl:SetFrameLevel(base)
	pl:SetAllPoints()
	page.pulls = pl
	pl.sub = S.Text(pl, "GameFontHighlight", "LEFT")
	pl.sub:SetPoint("TOPLEFT", 4, -6)
	pl.sub:SetWidth(W - 10)
	-- (on one line, over the cards: smaller when it is long)
	CuratorOctoFull.SetWordWrap(pl.sub, false)
	pl.sub:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	local CW, CH = unpack(ns.CARD_SIZES.small)
	local cw = W / octoConstants.PULL_COLS
	page.rows = {}
	for i = 1, octoConstants.PULL_COLS * octoConstants.PULL_ROWS do
		local r = NewPull(pl, cw - 6, base)
		local col, row = CuratorOctoFull.Mod((i - 1) , octoConstants.PULL_COLS), math.floor((i - 1) / octoConstants.PULL_COLS)
		r:SetPoint("TOP", pl, "TOPLEFT", cw * (col + 0.5), octoConstants.PULL_Y - row * (CH + 50))
		page.rows[i] = r
	end
	pl.empty = S.Text(pl, "GameFontHighlight")
	pl.empty:SetPoint("CENTER", pl, "TOP", 0, -200)
	pl.empty:SetWidth(W - 160)
	CuratorOctoFull.SetWordWrap(pl.empty, true)
	pl.empty:SetTextColor(0.8, 0.8, 0.8)
	page.empty = pl.empty
	page.emptyShelf = st.empty
	-- (1.8.0: another player's card as a combatant; 1.14.0: gone with the PvP, an empty frame in its place)
	page.combat = CreateFrame("Frame", nil, body)
	page.combat:Hide()

	-- hidden, the model frames let go of their creatures: every card is set again next time; the
	-- rewards landing land at once
	CuratorOctoFull.SetScript(page, "OnHide", function()
		for _, c in ipairs(st.cards) do
			c.sig = nil
			-- (a card of a case on its stand: UI/CaseShow.lua)
			if c.crate then
				c.crate.sig = nil
			end
		end
		for _, r in ipairs(page.rows) do
			r.card.sig = nil
		end
		page.combat.sig = nil
		ns.CancelOwner(octoConstants.ANIM)
		A:EndClaims()
	end)
	CuratorOctoFull.SetScript(page, "OnUpdate", function(_, elapsed)
		A.pt = (A.pt or 0) + elapsed
		if ov:IsShown() then
			for _, c in ipairs(st.cards) do
				if c:IsShown() then
					c:Tick(A.pt)
				end
			end
			-- (the rays of the finest card turn slowly)
			if st.rays:GetAlpha() > 0 then
				CuratorOctoFull.SetRotation(st.rays, A.pt * 0.09)
			end
		end
		if pl:IsShown() then
			for _, r in ipairs(page.rows) do
				if r:IsShown() then
					r.card:Tick(A.pt)
				end
			end
		end
	end)
end

function A:ShowProfilePage(shown)
	local f = self.frame
	if shown then
		self:BuildProfile()
	end
	if f.prof then
		CuratorOctoFull.SetShown(f.prof, shown)
	end
end

function A:SetProfileSection(key)
	if key ~= self.profSec then
		self:FinishClaims()
		self.profSec = key
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- What the profile shows: mine, or the other player's whose collection is open (what they sent).
function A:ProfileData()
	AC:Build()
	local member = self.member
	if not member then
		local pts = AC:Points(AC:Earned())
		local census = C:Census()
		local ok, female = pcall(function()
			return UnitSex("player") == 3
		end)
		local complete = 0
		for _, s in ipairs(ns.Series) do
			local o, total = C:Progress(s)
			if total > 0 and o >= total then
				complete = complete + 1
			end
		end
		local special = ns.db.title
		if special and not AC:HasSpecial(special) then
			special = nil
		end
		return {
			mine = true, known = true, points = pts, female = ok and female == true, rar = census.rar, special = special,
			showcase = C:Showcase(), history = C:History(), opened = ns.db.opened or 0,
			contracts = ns.db.contracts or 0, found = ns.Stats().found or 0, xp = LV:XP(),
			owned = census.owned, total = census.total, shiny = census.shiny, holo = census.holo, complete = complete,
			spec = ns.Talents and ns.Talents:Spec() or nil,
		}
	end
	local i = ns.Guild:Profile(member)
	-- (their albums complete: from the summaries of their albums, when they came)
	local complete, any = 0, false
	for _, s in ipairs(ns.Series) do
		local sum = ns.Guild:Summary(member, s)
		if sum then
			any = true
			if sum.o >= (s.official or CuratorOctoFull.Length(s.list)) and CuratorOctoFull.Length(s.list) > 0 then
				complete = complete + 1
			end
		end
	end
	-- (their title of prestige: earned in their achievements)
	local special = i and i.title
	if special and not AC:HasSpecial(special, AC:FromBits(i.bits)) then
		special = nil
	end
	return {
		member = member, known = i ~= nil, points = i and i.points or 0, female = i and i.female, rar = i and i.rar, special = special,
		showcase = ns.Guild:Showcase(member), history = ns.Guild:History(member),
		opened = i and i.opened, contracts = i and i.contracts, xp = i and i.xp, achs = i and i.count,
		owned = i and i.owned, total = CuratorOctoFull.Select(2, C:Overall()), shiny = i and i.shiny, holo = i and i.holo,
		complete = any and complete or nil, spec = i and i.spec, combat = i and i.combat,
		bits = i and i.bits,
	}
end

-- A card of the showcase or of the finest pulls on its place: set again only when it changes (setting
-- it reloads its creature).
-- (1.14.0: a titanforged card, the pattern of its copy, Patterns.lua)
local function PlaceCard(c, card, finish, pattern)
	pattern = finish == "holo" and pattern or nil
	local sig = card.key .. ":" .. (finish or "") .. ":" .. tostring(pattern or 0)
	c.pattern = pattern
	if c.sig ~= sig or not c:IsShown() then
		c.sig = sig
		c:SetCard(card, { owned = true, finish = finish, pattern = pattern })
		c:ShowSide("front")
	end
	c:Show()
end

function A:RefreshProfile()
	local f = self.frame
	local page = f.prof
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	f.wait:Hide()
	self:RefreshFooter(false)
	local data = self:ProfileData()
	self.profData = data
	local member = data.member
	-- the section (another player's profile has no track)
	local sec = self.profSec or "overview"
	if (member and sec == "track") or (sec == "combat" and not (member and data.combat)) or sec == "luck" then
		sec = "overview"
	end
	self.profSec = sec
	-- the title over the page, the points toward the next one in the bar
	local title, rank, nextPts, nextTitle = AC:Title(data.points, data.female)
	if data.known then
		local sub = nextTitle and string.format(L["Next title: %s (%d points)"], nextTitle, nextPts) or L["The highest title"]
		-- (1.6.0: the specialization of the talents)
		if data.spec and ns.Talents and ns.Talents.SpecText then
			sub = ns.Talents.SpecText(data.spec, data.female) .. "  ·  " .. sub
		end
		-- (1.5.0: a title of prestige chosen shows instead of the one of the points)
		local col = AC:RankColour(rank)
		if data.special then
			title, col = AC:SpecialName(data.special, data.female), AC.PRESTIGE
		end
		self:SetTitle(title, sub)
		f.title:SetTextColor(col[1], col[2], col[3])
		data.shownTitle, data.shownColour = title, col
		local from = AC.TITLES[rank][1]
		if nextPts then
			f.bar:SetProgress((data.points - from) / math.max(1, nextPts - from))
			f.bar.text:SetText(string.format(L["%d / %d points"], data.points, nextPts))
		else
			f.bar:SetProgress(1)
			f.bar.text:SetText(string.format(L["%d points"], data.points))
		end
	else
		self:SetTitle("", "")
		self:SetBar(0, 1, "")
	end
	-- every card of every album, by rarity (theirs from their profile)
	local found, all = C.PerRarity(0), C.PerRarity(0)
	for _, s in ipairs(ns.Series) do
		-- (1.12.0: an album of an event counts in no total; 1.13.0: a limited edition neither)
		if not s.event and not s.limited then
			for r = 1, CuratorOctoFull.Length(ns.RARITY) do
				all[r] = all[r] + CuratorOctoFull.Length(s.byRarity[r])
			end
		end
	end
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		found[r] = data.rar and data.rar[r] or 0
	end
	self:SetCounts(found, all)
	if member and not data.known then
		-- their profile has not come yet
		local short = ns.Guild:Short(member)
		local late = self.asked and GetTime() - self.asked > 5
		f.wait.text:SetText(late and string.format(L["%s did not answer (offline?)"], short) or string.format(L["Waiting for %s..."], short))
		f.wait:Show()
	end

	-- the tabs of the sections; the card of the collector (its level painted whatever the section: the rewards of
	-- the quests land in its bar)
	self:PaintProfileNav(data)
	page.lv:Paint((data.mine and self.questBusy and self.shownXP) or data.xp)
	CuratorOctoFull.SetShown(page.lv, data.known)
	CuratorOctoFull.SetShown(page.titleBox, data.mine and true or false)
	if data.mine then
		self:PaintTitleBox()
	end

	-- the section shown (the cards of those hidden let go of their creatures; another player's overview once their
	-- profile came: before, only the note that waits for it)
	CuratorOctoFull.SetShown(page.over, sec == "overview" and (data.known or not member))
	CuratorOctoFull.SetShown(page.track, sec == "track")
	CuratorOctoFull.SetShown(page.pulls, sec == "pulls")
	CuratorOctoFull.SetShown(page.combat, sec == "combat")
	if sec ~= "combat" then
		page.combat.sig = nil
	end
	if sec ~= "overview" then
		for _, c in ipairs(page.stage.cards) do
			c.sig = nil
		end
	end
	if sec ~= "pulls" then
		for _, r in ipairs(page.rows) do
			r.card.sig = nil
		end
	end
	self:ShowPager(sec == "pulls")
	if sec == "overview" then
		self:PaintOverview(data)
	elseif sec == "track" then
		self:PaintTrack()
	else
		self:PaintPulls(data)
	end
end

-- The widths of the tabs of a row: each at least as wide as the others, wider when its name needs it (its icon, its
-- name, its count, its badge), the others sharing what is left; not enough room for all: each in proportion.
local function Share(needs, total)
	local sum = 0
	for _, v in ipairs(needs) do
		sum = sum + v
	end
	local out = {}
	if sum >= total then
		for i, v in ipairs(needs) do
			out[i] = v * total / sum
		end
		return out
	end
	local wide, rest, free = {}, total, CuratorOctoFull.Length(needs)
	local again = true
	while again do
		again = false
		for i, v in ipairs(needs) do
			if not wide[i] and v > rest / free then
				wide[i], rest, free, again = true, rest - v, free - 1, true
			end
		end
	end
	for i, v in ipairs(needs) do
		out[i] = wide[i] and v or rest / free
	end
	return out
end

-- The tabs of the sections across the top, from the left (another player's: the overview, the finest pulls, their
-- card as a combatant, in the room of as many of mine): the track with the rewards waiting on it, the
-- finest pulls with how many.
function A:PaintProfileNav(data)
	local page = self.frame.prof
	local shown, needs = {}, {}
	for _, b in ipairs(page.nav) do
		local key = b.sec.key
		-- (the track: mine only; the card as a combatant: another player's, from 1.8.0)
		local on = not (data.member and key == "track") and (key ~= "combat" or (data.member ~= nil and data.combat ~= nil))
		CuratorOctoFull.SetShown(b, on)
		if on then
			local count, claim = "", 0
			if key == "track" then
				LV.SetIcon(b.icon, (LV:Rank()))
				claim = CuratorOctoFull.Length(LV:Unclaimed())
			elseif key == "pulls" then
				count = tostring(CuratorOctoFull.Length((data.history or {})))
			end
			b.shownCount, b.shownClaim = count, claim
			-- (what its name needs in its font, beside its icon, its count and its badge)
			S.SetFontObject(b.text, "GameFontNormal")
			b.text:SetText(L[b.sec.label])
			b.count:SetText(count)
			shown[CuratorOctoFull.Length(shown) + 1] = b
			needs[CuratorOctoFull.Length(needs) + 1] = 38 + 8 + ns.TextWidth(b.text) + (count ~= "" and (ns.TextWidth(b.count) + 6) or 0) + (claim > 0 and 26 or 2) + 6
		end
	end
	-- (the room of as many tabs of mine, a third of the row each)
	local widths = Share(needs, CuratorOctoFull.Length(shown) * (page.rw - (octoConstants.TABS_ROW - 1) * octoConstants.TAB_GAP) / octoConstants.TABS_ROW)
	local x = 0
	for i, b in ipairs(shown) do
		local w = widths[i]
		b:SetWidth(w)
		b.width = w
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", x, 0)
		x = x + w + octoConstants.TAB_GAP
		b:Paint(b.sec.key == self.profSec, L[b.sec.label], b.shownCount, b.shownClaim)
	end
end

-- (the gauges of the next boosters were on the profile before the first test of 1.13.0: in the boosters of the
-- inventory now; the album still calls this as the booster bar moves)
function A:PaintGauges()
end

-- The card of the collector: the title shown (mine: where to choose it; theirs as they show it), the next rank, or
-- (mine) the rewards of the levels waiting and the button that claims them.
function A:PaintIdCard(data)
	local page = self.frame.prof
	-- the title
	local earned = data.mine and AC:Specials() or (data.bits and AC:Specials(AC:FromBits(data.bits))) or nil
	local prestige = earned and string.format(L["Titles of prestige earned: %d / %d"], CuratorOctoFull.Length(earned), CuratorOctoFull.Length(AC.SPECIAL)) or ""
	if data.mine then
		page.titleBox.more:SetText(prestige)
		page.memberTitle:Hide()
	else
		local mt = page.memberTitle
		CuratorOctoFull.SetShown(mt, data.known and true or false)
		local col = data.shownColour or { 1, 1, 1 }
		Keep(mt.name, "GameFontNormalLarge", data.shownTitle or "", octoConstants.ID_TITLE_W - 30, 16, 10)
		mt.name:SetTextColor(col[1], col[2], col[3])
		mt.more:SetText(prestige)
	end
	-- the rewards of the levels waiting (mine), else the next rank
	local waiting = data.mine and CuratorOctoFull.Length(LV:Unclaimed()) or 0
	CuratorOctoFull.SetShown(page.claim, waiting > 0)
	local nr = page.nextRank
	CuratorOctoFull.SetShown(nr, waiting == 0 and data.known and data.xp ~= nil)
	CuratorOctoFull.SetShown(page.id.lines[2], waiting > 0 or nr:IsShown())
	if waiting > 0 then
		local cl = page.claim
		cl.badge:SetCount(waiting)
		Keep(cl.text, "GameFontNormal", Waiting(waiting), cl.text:GetWidth(), 12, 9, octoConstants.GREEN)
		cl.go:SetLabel(waiting > 1 and L["Claim all"] or L["Claim"])
		cl.go:SetPulse(true)
	elseif nr:IsShown() then
		local lv = LV.Of(data.xp)
		local r = LV.RankOf(lv)
		local nx = LV.RANKS[r + 1]
		nr.r = nx and r + 1 or r
		nr.emblem:SetRank(nr.r)
		nr.emblem.tex:SetDesaturated(nx ~= nil)
		nr.emblem:SetAlpha(nx and 0.75 or 1)
		local c = LV.RANKS[nr.r].color
		-- (the highest one: its name and what it is, in the middle of the height without the level of the next)
		nr.label:ClearAllPoints()
		nr.label:SetPoint("TOPLEFT", octoConstants.NR_X, nx and -30 or -38)
		nr.name:ClearAllPoints()
		nr.name:SetPoint("TOPLEFT", octoConstants.NR_X, nx and -45 or -53)
		Keep(nr.label, "GameFontHighlightSmall", nx and L["Next rank"] or L["The highest rank"], nr.label:GetWidth(), 10, 8, octoConstants.DIM)
		-- (its name in its colour, a little dimmer while it is to come; smaller when it is long)
		local size = 14
		ns.SetFont(nr.name, size, "OUTLINE")
		nr.name:SetText(L[LV.RANKS[nr.r].name])
		while size > 9 and ns.TextWidth(nr.name) > nr.label:GetWidth() do
			size = size - 0.5
			ns.SetFont(nr.name, size, "OUTLINE")
		end
		local k = nx and 0.8 or 1
		nr.name:SetTextColor(c[1] * k + (1 - k) * 0.6, c[2] * k + (1 - k) * 0.6, c[3] * k + (1 - k) * 0.6)
		nr.at:SetText(nx and string.format(L["Level %d"], nx.level) or "")
	end
end

-- The overview: the card of the collector, the showcase on its stage, the numbers beside it.
function A:PaintOverview(data)
	local page = self.frame.prof
	self:PaintIdCard(data)
	local st = page.stage
	local showcase = data.showcase or {}
	local CSH = ns.CaseShow
	-- (1.14.0: a showcase of five, the Museum Showcase: the stands placed for it)
	local n = (CuratorOctoFull.Length(showcase) > C.SHOWCASE_SIZE) and (C.SHOWCASE_MAX or 5) or C.SHOWCASE_SIZE
	if st.layout ~= n then
		st.layout = n
		for _, c in ipairs(st.cards) do
			PlaceStand(st, c, n)
		end
	end
	for i, c in ipairs(st.cards) do
		local v = showcase[i]
		CuratorOctoFull.SetShown(c.spot, i <= n)
		CuratorOctoFull.SetShown(c.ped, i <= n)
		if v and v.case then
			-- (1.14.0, after its second test) a card of a case: its own card on the stand (UI/CaseShow.lua)
			c:Hide()
			c.sig, c.shown, c.finish, c.pinned = nil, nil, nil, v.pinned
			c.floor:Show()
		elseif v then
			-- (1.14.0: mine, the pattern of the copy that shows it)
			PlaceCard(c, v.card, v.finish, data.mine and v.finish == "holo" and ns.Copies and ns.Copies:PatternOf(v.card.key) or nil)
			c.shown, c.finish, c.pinned = v.card, v.finish, v.pinned
			c:SetAlpha(1)
			c.floor:Show()
		else
			c:Hide()
			c.sig, c.shown, c.finish = nil, nil, nil
			c.floor:Hide()
		end
		if CSH then
			CSH:Stand(st, c, (v and v.case) and v or nil, data.mine)
		end
		-- (its light: the colour of its rarity, brighter for the finest; a card of a case: of its rank)
		local col = { 1, 0.92, 0.8 }
		if v and v.case then
			local r = ns.CrateUI.RANKS[v.case.tier] or ns.CrateUI.RANKS[1]
			col = r.text or r.color
		elseif v then
			col = ns.RARITY[v.card.rarity].text
		end
		c.spot:SetVertexColor(0.7 + 0.3 * col[1], 0.7 + 0.3 * col[2], 0.7 + 0.3 * col[3])
		c.spot:SetAlpha(v and 0.3 or 0.12)
	end
	-- (1.5.0) a title of prestige: the frame of gold
	CuratorOctoFull.SetShown(st.gold, data.special ~= nil)
	-- (its title and its pins past the arms of the corners of gold)
	local inset = data.special and 64 or 14
	st.title:ClearAllPoints()
	st.title:SetPoint("TOPLEFT", inset, -11)
	st.pins:ClearAllPoints()
	st.pins:SetPoint("TOPRIGHT", -inset, -12)
	-- the light and the rays of the finest card behind it
	local first = showcase[1]
	-- (1.14.0, after its second test: a card of a case first, as bright as a card of a booster of its rank)
	local rar = first and ((first.card and first.card.rarity) or (first.case and ({ 3, 4, 4, 5, 6 })[first.case.tier])) or 0
	if rar >= 4 then
		local col
		if first.case then
			local r = ns.CrateUI.RANKS[first.case.tier] or ns.CrateUI.RANKS[1]
			col = r.text or r.color
		else
			col = ns.RARITY[first.card.rarity].text
		end
		st.rays:SetVertexColor(col[1], col[2], col[3])
		st.rays:SetAlpha(rar >= 5 and 0.7 or 0.45)
		st.halo:SetVertexColor(col[1], col[2], col[3])
		st.halo:SetAlpha(rar >= 5 and 0.42 or 0.28)
	else
		st.rays:SetAlpha(0)
		st.halo:SetAlpha(0)
	end
	st.empty:SetText(CuratorOctoFull.Length(showcase) == 0 and (data.mine and L["Open boosters: your finest cards will stand here."] or L["Nothing shared yet."]) or "")
	if data.mine then
		st.pins:SetText(string.format(L["Pinned: %d / %d"], CuratorOctoFull.Length(C:Pins()), C:ShowcaseSize()))
	else
		st.pins:SetText("")
	end
	-- the numbers (another player's: what their profile tells)
	for _, t in ipairs(page.stats) do
		local stat = (data.member and t.stat.other) or t.stat
		if t.shown ~= stat then
			t.shown = stat
			Hud.SetIcon(t.icon, stat.icon)
		end
		local key = stat.key
		local v
		if not data.known then
			v = nil
		elseif key == "cards" then
			v = data.owned and (ns.Num(data.owned) .. "/" .. ns.Num(data.total or 0)) or nil
		else
			v = data[key]
			v = v and ns.Num(v) or nil
		end
		-- (a long number: smaller until it fits; what it counts in the room left beside it)
		local w = t:GetWidth()
		local k = t.big and 18 or 14
		ns.SetFont(t.value, k, "OUTLINE")
		t.value:SetText(v or "?")
		local most = t.big and (w - 4) or (w - 90)
		while k > 9 and ns.TextWidth(t.value) > most do
			k = k - 0.5
			ns.SetFont(t.value, k, "OUTLINE")
		end
		local room = t.big and (w - 34 - ns.TextWidth(t.value) - 10) or (w - 30 - ns.TextWidth(t.value) - 10)
		t.label:SetWidth(math.max(40, room))
		Keep(t.label, t.big and "GameFontNormal" or "GameFontHighlightSmall", L[stat.label], math.max(40, room), t.big and 12 or 10, 7.5,
			not t.big and octoConstants.LABEL or nil)
		if t.bar then
			local p = (data.known and data.owned and (data.total or 0) > 0) and data.owned / data.total or 0
			t.bar:SetProgress(p)
			t.bar:SetText((data.known and data.owned) and ns.Pct(p) or "")
		end
	end
end

-- The finest pulls, a page of them, as cards.
function A:PaintPulls(data)
	local page = self.frame.prof
	local pl = page.pulls
	local list = data.history or {}
	local per = octoConstants.PULL_COLS * octoConstants.PULL_ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / per))
	self.profPage = math.max(1, math.min(self.profPage or 1, pages))
	Keep(pl.sub, "GameFontHighlight", data.mine and L["Your legendary and mythic cards, your titanforged cards and your thunderforged epic cards."] or "",
		pl.sub:GetWidth(), 12, 9, octoConstants.DIM)
	for i, r in ipairs(page.rows) do
		local h = list[(self.profPage - 1) * per + i]
		r.shown, r.finish, r.t, r.how = h and h.card, h and h.finish, h and h.t, h and h.how
		CuratorOctoFull.SetShown(r, h ~= nil)
		if h then
			PlaceCard(r.card, h.card, h.finish, h.pt)
			local how = octoConstants.HOW[h.how or ""] and L[octoConstants.HOW[h.how]] or RarityLine(h.card, h.finish)
			-- (a card that came in a trade: with whom)
			if h.how == "t" and h.who then
				how = string.format(L["Trade with %s"], h.who)
			end
			local ht = r.howText
			S.SetFontObject(ht, "GameFontHighlightSmall")
			ht:SetText(how)
			if ns.TextWidth(ht) > ht:GetWidth() then
				S.Fit(ht, how, ht:GetWidth(), 10, 7.5)
			end
			local col = ns.RARITY[h.card.rarity].text
			ht:SetTextColor(col[1] * 0.6 + 0.4, col[2] * 0.6 + 0.4, col[3] * 0.6 + 0.4)
			r.when:SetText((h.t and h.t > 0 and fmtDate) and fmtDate("%d/%m/%y", h.t) or "")
		else
			r.card.sig = nil
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		pl.empty:SetText(data.mine and L["No big pull yet: your legendary and mythic cards, your titanforged cards and your thunderforged epic cards will come here."]
			or L["Nothing shared yet."])
	else
		pl.empty:SetText("")
	end
	self:SetPager(self.profPage, pages)
end

function A:ProfilePage(delta)
	if self.profSec ~= "pulls" then
		return
	end
	local data = self.profData or self:ProfileData()
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length((data.history or {})) / (octoConstants.PULL_COLS * octoConstants.PULL_ROWS)))
	local p = math.max(1, math.min(pages, (self.profPage or 1) + delta))
	if p ~= self.profPage then
		self.profPage = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- (1.13.0, after its first test) The rewards of the levels claimed from the card of the collector: the track shown,
-- they fly from its sockets.
function A:ClaimFromOverview()
	if CuratorOctoFull.Length(LV:Unclaimed()) == 0 then
		return
	end
	GameTooltip:Hide()
	self:SetProfileSection("track")
	if self.profSec == "track" then
		self:ClaimTrack()
	end
end

-------------------------------------------------------------------------------
-- The track of the levels
-------------------------------------------------------------------------------
-- The track: the rank and the next one, the sixty sockets (the rewards waiting glow), the light up
-- to the level reached, its marker.
function A:PaintTrack()
	local tr = self.frame.prof.track
	local xp = LV:XP()
	local lv, into, need = LV.Of(xp)
	local r, rank = LV.RankOf(lv)
	local waiting = CuratorOctoFull.Length(LV:Unclaimed())
	-- (1.14.0: the rewards to choose of the levels claimed, waiting)
	local offers = LV:OfferCount()
	if waiting > 0 then
		tr.sub:SetText(Waiting(waiting))
		tr.sub:SetTextColor(0.45, 1, 0.4)
	elseif offers > 0 then
		tr.sub:SetText(offers == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], offers))
		tr.sub:SetTextColor(0.45, 1, 0.4)
	else
		tr.sub:SetText(lv >= LV.LEGEND and L["Past the legend: a booster of a dungeon too every five levels, of a raid every ten."]
			or L["Each level reached gives a reward to choose among three; a new rank every five levels."])
		tr.sub:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	end
	CuratorOctoFull.SetShown(tr.claimAll, waiting > 0 or offers > 0)
	tr.claimAll:SetEnabled(waiting > 0 or offers > 0)
	tr.claimAll:SetLabel((waiting > 1 and L["Claim all"]) or (waiting == 1 and L["Claim"]) or string.format(L["Choose (%d)"], offers))
	tr.claimAll:SetPulse(true)
	-- this rank, the next one
	tr.cur:SetRank(r)
	tr.curName:SetText(L[rank.name])
	tr.curName:SetTextColor(rank.color[1], rank.color[2], rank.color[3])
	local nx = LV.RANKS[r + 1]
	CuratorOctoFull.SetShown(tr.nxt, nx ~= nil)
	CuratorOctoFull.SetShown(tr.nxtName, nx ~= nil)
	if nx then
		tr.nxt:SetRank(r + 1)
		tr.nxt.glow:Hide()
		tr.nxt.tex:SetDesaturated(true)
		tr.nxt:SetAlpha(0.7)
		tr.nxtName:SetText(L[nx.name])
		tr.nxtName:SetTextColor(0.7, 0.7, 0.74)
		local p = ((lv - rank.level) + (need and into / need or 0)) / (nx.level - rank.level)
		tr.rankBar:SetProgress(p)
		tr.rankBar:SetText(string.format(L["Level %d / %d"], lv, nx.level))
		tr.rankLabel:SetText(string.format(L["Next rank: %s at level %d"], L[nx.name], nx.level))
	else
		tr.rankBar:SetProgress(1)
		tr.rankBar:SetText(L["Highest level"])
		tr.rankLabel:SetText(L["The highest rank"])
	end
	-- (1.11.0) the page: the one chosen, else the one of the level reached
	local page = self.trackPage or TrackPage(lv)
	self.trackPage = page
	local span = octoConstants.TRACK_PAGES[page]
	for pg, b in ipairs(tr.pages) do
		local waitHere = 0
		for _, l in ipairs(LV:Unclaimed()) do
			if TrackPage(l) == pg then
				waitHere = waitHere + 1
			end
		end
		b:Paint(pg == page, string.format(L["Levels %d to %d"], octoConstants.TRACK_PAGES[pg][1], octoConstants.TRACK_PAGES[pg][2]), "", waitHere)
	end
	-- the sockets (those of the page shown)
	CuratorOctoFull.Wipe(tr.waiting)
	local marked
	for level = 1, LV.MAX do
		local n = tr.nodes[level]
		CuratorOctoFull.SetShown(n, n.page == page)
		local reached = level <= lv
		local claimed = level >= 2 and LV:Claimed(level)
		n.can = reached and level >= 2 and not claimed
		CuratorOctoFull.SetShown(n.check, reached and claimed)
		CuratorOctoFull.SetSize(n.check, 22, 22)
		n.check:SetAlpha(1)
		n.glow:SetAlpha(0)
		CuratorOctoFull.SetSize(n.icon, n.iconSize, n.iconSize)
		if n.can and n.page == page then
			tr.waiting[n] = true
		end
		n.bg:SetDesaturated(not reached)
		n.bg:SetAlpha(reached and 1 or 0.55)
		n.icon:SetDesaturated(not reached)
		n.icon:SetAlpha(reached and 1 or 0.42)
		if level == lv then
			n.label:SetTextColor(1, 0.86, 0.4)
			marked = n.page == page and n or nil
		elseif reached then
			n.label:SetTextColor(0.92, 0.9, 0.84)
		else
			n.label:SetTextColor(0.5, 0.5, 0.54)
		end
	end
	-- the light in the channel of each row, up to the level reached (and how far into the next one)
	local NodeX = tr.NodeX
	for row = 1, octoConstants.ROWS do
		local first = span[1] + (row - 1) * octoConstants.COLS
		local last = math.min(span[2], first + octoConstants.COLS - 1)
		local fill = tr.fills[row]
		-- (the rows of the page: those of the last page fewer)
		CuratorOctoFull.SetShown(tr.lines[row], first <= span[2])
		if lv < first or first > span[2] then
			fill:Hide()
		else
			local x
			if lv >= last then
				x = NodeX(octoConstants.COLS)
			else
				local col = lv - first + 1
				x = NodeX(col) + (need and into / need or 0) * (NodeX(col + 1) - NodeX(col))
			end
			fill:SetWidth(math.max(1, x - NodeX(1)))
			fill:Show()
		end
	end
	tr.markAt = marked
	CuratorOctoFull.SetShown(tr.here, marked ~= nil)
	CuratorOctoFull.SetShown(tr.wave, marked ~= nil)
	if marked then
		for _, t in ipairs({ tr.here, tr.wave }) do
			t:ClearAllPoints()
			t:SetPoint("CENTER", marked, "CENTER")
		end
		local size = marked:GetWidth() * 1.45
		CuratorOctoFull.SetSize(tr.here, size, size)
		CuratorOctoFull.SetSize(tr.wave, size, size)
	end
end

-- The rewards of these levels claimed (nil: all of those waiting): their boosters fly from their
-- sockets to the tab of the inventory (its boosters), a check of gold comes down on each. The number claimed.
function A:ClaimTrack(levels)
	local top = LV:Level()
	local wanted = {}
	for _, lv in ipairs(levels or LV:Unclaimed()) do
		if lv >= 2 and lv <= top and not LV:Claimed(lv) then
			wanted[CuratorOctoFull.Length(wanted) + 1] = lv
		end
	end
	if CuratorOctoFull.Length(wanted) == 0 then
		return 0
	end
	local tr = self.frame.prof.track
	local tab = self:BoosterTab()
	local epoch = self:BeginClaims()
	local done, rubies = LV:ClaimLevels(wanted)
	ns.Play(ns.SND.claim)
	-- (1.11.0) their rubies fly to the purse of the album
	local f = self.frame
	if (rubies or 0) > 0 and f.wallet and f.wallet:IsVisible() and tr.nodes[done[1]] then
		ns.Delay(0.1, function()
			Hud.Fly(ns.Rubies.ICON, tr.nodes[done[1]].icon, f.wallet.gem, 24, 0.55, nil, ns.RubiesUI.GLOW)
		end, octoConstants.ANIM)
	end
	if CuratorOctoFull.Length(LV:Unclaimed()) == 0 and LV:OfferCount() == 0 then
		tr.claimAll:Hide()
	end
	local flights = math.min(CuratorOctoFull.Length(done), 8)
	-- (1.11.0: past the legend, boosters of a dungeon and of a raid too: each flight brings the booster of a
	-- zone of its level, the last one what is left of every kind)
	local totals, added = {}, {}
	for _, lv in ipairs(done) do
		LV.RewardPacks(LV.Reward(lv), totals)
	end
	for i, lv in ipairs(done) do
		local i, lv = i, lv; local n = tr.nodes[lv]
		local d = math.min(i - 1, 10) * 0.07
		n.can = false
		tr.waiting[n] = nil
		CuratorOctoFull.SetSize(n.icon, n.iconSize, n.iconSize)
		ns.Tween(0.4, function(_, raw)
			n.glow:SetAlpha(0.9 * (1 - raw))
		end, nil, Ease.linear, octoConstants.ANIM, d)
		local reward = LV.Reward(lv)
		if reward and i <= flights then
			local last = i == flights
			-- (1.14.0: the reward to choose of a level flies to the button that shows them, the boosters to the inventory)
			local offer = reward.kind == "offer"
			ns.Delay(d + 0.05, function()
				Hud.Fly(Hud.PackIcon(reward.kind), n.icon, offer and tr.claimAll or tab, 28, 0.7, function()
					-- (its reward to choose counted as it lands; the boosters to choose past the legend, rewards to
					-- choose too, with the last one)
					if offer then
						A:AddShownPacks("offer", reward.n, epoch)
					end
					if last then
						for _, kind in ipairs(LV.KINDS) do
							local rest = (totals[kind] or 0) - (added[kind] or 0)
							if rest > 0 then
								A:AddShownPacks(kind, rest, epoch)
							end
						end
					elseif not offer then
						added[reward.kind] = (added[reward.kind] or 0) + reward.n
						A:AddShownPacks(reward.kind, reward.n, epoch)
					end
				end, { 1, 0.85, 0.45 })
			end, octoConstants.ANIM)
			for k, m in ipairs(reward.more or {}) do
				local k, m = k, m; ns.Delay(d + 0.12 + 0.08 * k, function()
					Hud.Fly(Hud.PackIcon(m.kind), n.icon, tab, 28, 0.7, nil, { 1, 0.85, 0.45 })
				end, octoConstants.ANIM)
			end
		end
		Stamp(n.check, 22, d + 0.2, function()
			if i == 1 then
				ns.Play(ns.SND.stamp)
			end
			Hud.Burst(n, octoConstants.GOLDEN, 8, 70, 12)
		end)
	end
	self:EndClaimsIn(math.min(CuratorOctoFull.Length(done) - 1, 10) * 0.07 + 1.25)
	-- (1.14.0) then the rewards to choose, the oldest level first
	if LV:OfferCount() > 0 and ns.OffersUI then
		ns.Delay(math.min(CuratorOctoFull.Length(done) - 1, 10) * 0.07 + 1.3, function()
			ns.OffersUI:Show()
		end, octoConstants.ANIM)
	end
	return CuratorOctoFull.Length(done)
end

-------------------------------------------------------------------------------
-- Tooltips
-------------------------------------------------------------------------------
function A:ProfileNavTooltip(b)
	local key = b.sec.key
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L[b.sec.label], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if key == "track" then
		GameTooltip:AddLine(L["Each level reached gives a reward to choose among three; a new rank every five levels."], 1, 1, 1, true)
		local n = CuratorOctoFull.Length(LV:Unclaimed())
		if n > 0 then
			GameTooltip:AddLine(Waiting(n), 0.3, 1, 0.3)
		end
	elseif key == "pulls" then
		GameTooltip:AddLine(L["Your legendary and mythic cards, your titanforged cards and your thunderforged epic cards."], 1, 1, 1, true)
	elseif key == "combat" then
		GameTooltip:AddLine(L["Their card as a combatant, made their own way: their outfit, the place behind them, its finish."], 1, 1, 1, true)
	end
	GameTooltip:Show()
end

-- (1.13.0, after its first test) The button of the card of the collector that claims the rewards of the levels.
function A:ClaimTooltip(owner)
	local n = CuratorOctoFull.Length(LV:Unclaimed())
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L["Reward track"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(Waiting(n), 0.3, 1, 0.3)
	GameTooltip:AddLine(L["On the reward track: for each level, a reward to choose among three."], 1, 1, 1, true)
	GameTooltip:Show()
end

-- The tooltip of the level: where the experience comes from (mine: where to see the quests).
function A:LevelTooltip(owner)
	local data = self.profData
	if not (data and data.xp) then
		return
	end
	local level, into, need = LV.Of(data.xp)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(string.format(L["Collector level %d"], level), S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if need then
		GameTooltip:AddLine(string.format(L["%s XP to level %d"], ns.Num(need - into), level + 1), 1, 1, 1)
	end
	GameTooltip:AddLine(string.format(L["Total: %s XP"], ns.Num(data.xp)), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(L["Experience comes from the boosters opened (each card by its rarity, more for its finish) and from the quests."], 0.8, 0.8, 0.8, true)
	if data.mine then
		GameTooltip:AddLine(L["Your quests: the Quests tab."], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	end
	GameTooltip:Show()
end

-- (1.13.0, after its first test) The bar of the head, on the profile: the points of the achievements toward the next
-- title, not the experience of the level (in the card of the collector). Elsewhere, the bar of the album.
do
	local barTooltip = A.BarTooltip
	function A:BarTooltip(bar)
		local data = self.mode == "profile" and self.profData
		if not (data and data.known) then
			return barTooltip(self, bar)
		end
		local _, _, nextPts, nextTitle = AC:Title(data.points, data.female)
		GameTooltip:SetOwner(bar, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L["Achievement points"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
		GameTooltip:AddLine(bar.text:GetText() or "", 1, 1, 1)
		GameTooltip:AddLine(nextTitle and string.format(L["Next title: %s (%d points)"], nextTitle, nextPts) or L["The highest title"], 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Achievement points raise the title. The level comes from experience."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end
end

function A:StatTooltip(t)
	local stat = t.shown or t.stat
	GameTooltip:SetOwner(t, "ANCHOR_TOP")
	GameTooltip:AddLine(L[stat.label], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(t.value:GetText() or "", 1, 1, 1)
	local key = stat.key
	if key == "shiny" then
		GameTooltip:AddLine(L["Cards that have a thunderforged copy."], 0.8, 0.8, 0.8, true)
	elseif key == "holo" then
		GameTooltip:AddLine(L["Cards that have a titanforged copy."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:Show()
end

-- The showcase: what stands there.
function A:ShowcaseTooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L["Showcase"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if self.member then
		GameTooltip:AddLine(L["The cards this player shows."], 1, 1, 1, true)
	else
		GameTooltip:AddLine(string.format(L["Pinned cards: %d / %d. Pin your favourite cards from their page in your album; your finest cards fill the other places."], CuratorOctoFull.Length(C:Pins()), C:ShowcaseSize()), 1, 1, 1, true)
	end
	GameTooltip:Show()
end

-- A socket of the track: its level, its reward, a new rank; claimed, to claim, or how far.
function A:NodeTooltip(n)
	GameTooltip:SetOwner(n, "ANCHOR_RIGHT")
	GameTooltip:AddLine(string.format(L["Level %d"], n.level), S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if n.rank then
		local rank = LV.RANKS[n.rank]
		GameTooltip:AddLine(string.format(L["New rank: %s"], LV.EmblemText(n.rank, 16) .. " " .. L[rank.name]), rank.color[1], rank.color[2], rank.color[3])
	end
	local reward = LV.Reward(n.level)
	if reward then
		-- (1.14.0: a reward to choose among three, Level.lua: LV.OFFER)
		local what = reward.kind == "offer" and L["a reward to choose among three"] or self:PackReward(reward.kind, reward.n)
		GameTooltip:AddLine(string.format(L["Reward: %s"], what), 1, 1, 1, true)
		-- (1.11.0) past the legend, more of them
		for _, m in ipairs(reward.more or {}) do
			GameTooltip:AddLine("+ " .. self:PackReward(m.kind, m.n), 1, 1, 1, true)
		end
		-- (1.11.0) and its rubies
		if (reward.rubies or 0) > 0 and ns.Rubies then
			GameTooltip:AddLine(ns.Rubies.Text(reward.rubies, 14), 1, 0.64, 0.68)
		end
	end
	if n.level <= LV:Level() then
		if n.can then
			GameTooltip:AddLine(L["Click to claim"], 0.3, 1, 0.3)
		elseif reward then
			GameTooltip:AddLine(L["Claimed"], 0.3, 1, 0.3)
		end
	else
		GameTooltip:AddLine(string.format(L["%s XP to go"], ns.Num(LV.FLOOR[n.level] - LV:XP())), 0.75, 0.75, 0.78)
	end
	GameTooltip:Show()
end

-- The tooltip of a card of the profile: the card, whose it is, what a click does.
function A:ProfileTooltip(owner, card, finish, extra, pattern)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	ns.Links:AddLines(GameTooltip, card, finish, self.member, pattern)
	if extra then
		GameTooltip:AddLine(extra, 1, 0.82, 0.25)
	end
	ns.Links:AddHint(GameTooltip, true)
	GameTooltip:Show()
end

function A:ProfileCardEnter(c)
	if c.shown then
		self:ProfileTooltip(c, c.shown, c.finish, (c.pinned and not self.member) and L["In your showcase"] or nil, c.pattern)
	end
end

function A:ProfileRowEnter(r)
	if r.shown then
		self:ProfileTooltip(r.card, r.shown, r.finish, nil, r.card.pattern)
	end
end

-- A click on one: in the chat (shift), else the card big (mine: its page in my album, with the
-- showcase; another player's: on its own).
function A:ProfileCardClick(card, finish, pattern)
	if not card then
		return
	end
	if ns.Links:Modified() then
		-- (1.14.3: mine, the copy my showcase shows, its very card: UI/Links.lua)
		ns.Links:Insert(card, finish, pattern, nil, not self.member and ns.CopiesUI and ns.CopiesUI:Default(card, finish) or nil)
		return
	end
	local e = not self.member and C:Entry(card)
	if e and e.n > 0 then
		ns.Play(ns.SND.cardFlip)
		GameTooltip:Hide()
		self:ShowDetail(card, e)
		return
	end
	ns.Links:View(card, finish, self.member, pattern)
end

-------------------------------------------------------------------------------
-- From elsewhere
-------------------------------------------------------------------------------
-- My profile, on a section ("track": the track of the levels).
function A:ShowProfile(section)
	self:Build()
	self:FinishClaims()
	if section then
		self.profSec = section
	end
	self.mode, self.member, self.memberEntries, self.returnMode = "profile", nil, nil, nil
	self.page = 1
	self:HideDetail()
	self:Reveal()
end

-------------------------------------------------------------------------------
-- (1.5.0) The title shown: the one of the points, or a title of prestige earned. (1.14.0, his word: those earned only;
-- the others and what earns them, listed under them before, no more.)
-------------------------------------------------------------------------------
function A:TitleMenu(root)
	local female = AC:Female()
	local function chosen(key)
		local t = ns.db and ns.db.title
		if t and not AC:HasSpecial(t) then
			t = nil
		end
		return (t or false) == (key or false)
	end
	local function choose(key)
		if AC:SetSpecial(key) then
			ns.Play(ns.SND.click)
			A:Refresh()
		end
	end
	root:CreateTitle(L["The title of your points"])
	root:CreateRadio((AC:MyTitle()), function()
		return chosen(nil)
	end, function()
		choose(nil)
	end, "-")
	local earned = AC:Specials()
	if CuratorOctoFull.Length(earned) > 0 then
		root:CreateDivider()
		root:CreateTitle(L["Titles of prestige"])
	end
	for _, x in ipairs(earned) do
		local _, x = _, x; root:CreateRadio(AC:SpecialName(x.key, female), function()
			return chosen(x.key)
		end, function()
			choose(x.key)
		end, x.key)
	end
end

-- The box of the title shown: the one chosen, smaller when it is long.
function A:PaintTitleBox()
	local pick = self.frame.prof.titleBox.pick
	pick:GenerateMenu()
	local fs = pick.Text or pick.label
	if fs and fs.GetText then
		-- (in the font of the menu of the game, smaller only when it does not fit)
		local text = fs:GetText() or ""
		pick.textFont = pick.textFont or (fs.GetFontObject and fs:GetFontObject()) or "GameFontHighlightSmall"
		S.SetFontObject(fs, pick.textFont)
		fs:SetText(text)
		local room = pick:GetWidth() - 36
		if ns.TextWidth(fs) > room then
			local _, size = fs:GetFont()
			S.Fit(fs, text, room, math.floor(size or 10), 7.5)
		end
	end
end

function A:TitlePickTooltip(tooltip)
	tooltip:AddLine(L["Title shown"], 1, 0.84, 0.48)
	tooltip:AddLine(L["The title of your points, or a title of prestige earned with an achievement. The other players see it; a title of prestige frames your showcase in gold."], 0.85, 0.85, 0.85, true)
end
