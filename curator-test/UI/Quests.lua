local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local A = ns.Album
local Q = ns.Quests
local LV = ns.Level
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease

-- The page of the quests, in the album, as the quest screens of the great games. Over it, in the head
-- of the window: the emblem of the rank of the collector, its level and its bar of experience. On the
-- left, the sections (the quests of the day, of the week, of the month, of the dungeons, of the raids,
-- of PvP), each with a badge for the rewards waiting in it, and under them the stock of the boosters to
-- choose (put in the albums from the page of the boosters). On the right: the quests of the section on
-- their cards (what to do, how far, the rewards, a button to claim them once done: the experience
-- flies to its bar, the boosters to the stock, a stamp of gold comes down on the card). (1.9.0) A section
-- of more than five quests (ten of the day, ten of PvP) shows them on rows, thinner: what to do and how
-- far on the left, the rewards after the bar, the period or the button to claim on the right; the note
-- of the section behind a button of information.
local NAV_W, NAV_H, NAV_GAP = 192, 34, 4
local X0 = NAV_W + 14
local HEAD_H = 46
local CARD_H, CARD_GAP, CARDS = 80, 8, 5
local ROW_H, ROW_GAP, ROWS = 46, 3, 10
local STOCK_H = 150
-- the title of the window, to the right of the emblem
local TITLE_X, TITLE_ROOM = 130, 388
local GOLDEN = { 1, 0.8, 0.32 }
local DIM = { 0.62, 0.62, 0.68 }
-- the owner of the animations of the claims (cancelled when the page goes; shared with the page of the
-- achievements)
local ANIM = A.CLAIMS

-- The name of a period, for a quest of it, and the time left in it.
local PERIOD = { day = "Daily quest", week = "Weekly quest", month = "Monthly quest" }
local HEAD = { day = "Daily: %s", week = "Weekly: %s", month = "Monthly: %s" }
Q.PERIOD = PERIOD
-- the stripe of a card: the colour of its period (gold while its rewards wait)
local TINT = { day = { 0.36, 0.68, 1 }, week = { 0.74, 0.5, 1 }, month = { 1, 0.58, 0.22 } }
local TITLE = {
	daily = "Daily quests", weekly = "Weekly quests", monthly = "Monthly quests",
	dungeon = "Dungeon quests", raid = "Raid quests", pvp = "PvP quests",
}
local ICON = {
	daily = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	weekly = "Interface\\Icons\\INV_Scroll_05",
	monthly = "Interface\\Icons\\INV_Misc_Book_07",
	dungeon = "Interface\\Icons\\INV_Misc_Key_10",
	raid = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
	pvp = "Interface\\Icons\\INV_BannerPVP_02",
}
-- (1.14.0: golden, the golden booster of an album complete, Achievements.lua)
-- (1.14.0, his word: no booster to choose any more: a reward to choose among three, the booster of its kind one of them,
-- Level.lua: LV:AddChoice; the golden booster of an album complete, into an album drawn at random)
local REWARD_ONE = { zone = "1 reward to choose (a booster of a zone among the three)", dungeon = "1 reward to choose (a booster of a dungeon among the three)", raid = "1 reward to choose (a booster of a raid among the three)",
	hallow = "1 booster of Hallow's End", golden = "1 golden booster of an album drawn at random" }
local REWARD_MANY = { zone = "%d rewards to choose (each with a booster of a zone among the three)", dungeon = "%d rewards to choose (each with a booster of a dungeon among the three)", raid = "%d rewards to choose (each with a booster of a raid among the three)",
	hallow = "%d boosters of Hallow's End", golden = "%d golden boosters of albums drawn at random" }
local NOTES = {
	daily = "Every character of your account counts. The creatures that give no experience do not count.",
	weekly = "Every character of your account counts. The creatures that give no experience do not count.",
	monthly = "Every character of your account counts. The creatures that give no experience do not count.",
	dungeon = "The dungeons too low for your level do not count.",
	raid = "Raids reset every week: one quest a week, one a month.",
	pvp = "Every character of your account counts. An enemy counts for his class, his race or his level once the game has shown him to you: your target, your mouse, his nameplate.",
}
Q.NOTES = NOTES
-- (1.14.0, after its test, his word: from the release of OctoWoW, a reroll does no quest; the main counts, and the
-- other characters from level 15, Reroll.lua)
local FOREVER_COUNT = "Your main character counts, and your other characters from level %d. The creatures that give no experience do not count."
local NOTES_FOREVER = {
	daily = FOREVER_COUNT, weekly = FOREVER_COUNT, monthly = FOREVER_COUNT,
	pvp = "Your main character counts, and your other characters from level %d. An enemy counts for his class, his race or his level once the game has shown him to you: your target, your mouse, his nameplate.",
}
Q.NOTES_FOREVER = NOTES_FOREVER

-- (1.14.0, after its test, his word) This character a reroll: it does no quest, claims none (Reroll.lua: RR:Blocks).
local function Locked()
	return ns.Reroll ~= nil and ns.Reroll:Blocks("quests")
end

-- The sections on the left: the quests of the day, of the week, of the month, of the dungeons, of the
-- raids, of PvP.
local NAV = {}
-- (1.14.0) The quest each card shows, and its board: kept here, not on the card, which another addon reaches
-- (EnumerateFrames): the quests are the save's own tables, and the rewards claimed are theirs.
local SHOWS = setmetatable({}, { __mode = "k" })
local function Shown(r)
	local x = SHOWS[r]
	if x then
		return x.q, x.board
	end
end
for _, sec in ipairs(Q.SECTIONS) do
	NAV[CuratorOctoFull.Length(NAV) + 1] = sec
end

-- "1 booster of a zone to choose", "3 boosters of a raid to choose".
function A:PackReward(kind, n)
	return n == 1 and L[REWARD_ONE[kind]] or string.format(L[REWARD_MANY[kind]], n)
end

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Icon(kind)
	local k = Q.KINDS[kind]
	local icon = k and k.icon
	-- (1.14.0: a quest of the spells of the paladins, the icon of its first spell, Discovery.lua)
	if not icon and k and k.spells then
		icon = (ns.Discovery and ns.Discovery:SpellIcon(k.spells)) or "Interface\\Icons\\Spell_Holy_HolyBolt"
	end
	icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
	return type(icon) == "table" and icon or { icon }
end
Q.Icon = Icon

-- An icon on a texture; those of the game without their border.
local SetIcon = Hud.SetIcon

local function Section(key)
	for _, sec in ipairs(NAV) do
		if sec.key == key then
			return sec
		end
	end
	return NAV[1]
end

local function Waiting(n)
	return n == 1 and L["1 reward to claim"] or string.format(L["%d rewards to claim"], n)
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- The pieces shared with the other pages (UI/Hud.lua).
local Sliced, GlowOut, Each, RoundIcon = Hud.Sliced, Hud.GlowOut, Hud.Each, Hud.RoundIcon

-- A stamp coming down on a texture: from big and clear to its size, then land().
local function Stamp(tex, size, delay, land)
	return Hud.Stamp(tex, size, delay, land, ANIM)
end

-- A button of the sections: dark, its icon, its name, how many of its quests are done, the badge of
-- its rewards waiting; lit in gold when chosen.
local function NewNav(page, sec, i)
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, NAV_W, NAV_H)
	b:SetPoint("TOPLEFT", 0, -(i - 1) * (NAV_H + NAV_GAP))
	b.bg = Sliced(b, "QuestCard", NAV_H, 0, "BACKGROUND")
	b.glow = Sliced(b, "QuestGlow", NAV_H, GlowOut(NAV_H), "BORDER", 0, "ADD")
	Each(b.glow, "SetVertexColor", GOLDEN[1], GOLDEN[2], GOLDEN[3])
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
	CuratorOctoFull.SetSize(b.icon, 22, 22)
	b.icon:SetPoint("LEFT", 10, 0)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", 38, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	b.count = S.Text(b, "GameFontHighlightSmall", "RIGHT")
	b.badge = Hud.Badge(b, 20)
	b.badge:SetPoint("RIGHT", -7, 0)
	b.sec = sec
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:SetQuestSection(sec.key)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:NavTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end

-- A card of a quest: its icon in a ring of gold, what to do, how far in a bar of gold, its period,
-- its rewards (the orb of the experience, the boosters to choose), the button to claim them.
local function NewCard(parent, w)
	local r = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(r, w, CARD_H)
	r.bg = Sliced(r, "QuestCard", CARD_H, 0, "BACKGROUND")
	r.glow = Sliced(r, "QuestGlow", CARD_H, GlowOut(CARD_H), "BORDER", 0, "ADD")
	Each(r.glow, "SetVertexColor", GOLDEN[1], GOLDEN[2], GOLDEN[3])
	Each(r.glow, "SetAlpha", 0)
	r.flash = r:CreateTexture(nil, "BORDER", nil, 1)
	r.flash:SetPoint("TOPLEFT", 4, -4)
	r.flash:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(r.flash, 1, 0.86, 0.5, 1)
	r.flash:SetBlendMode("ADD")
	r.flash:SetAlpha(0)
	r.accent = r:CreateTexture(nil, "BORDER", nil, 2)
	r.accent:SetTexture(MEDIA .. "QuestAccent")
	r.accent:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(r.accent, 12, CARD_H - 16)
	r.accent:SetPoint("LEFT", 2, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetPoint("TOPLEFT", 4, -4)
	r.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.7, 0.05)
	r.icon = RoundIcon(r, 44)
	r.icon:SetPoint("CENTER", r, "LEFT", 46, 0)
	r.iconW = r.icon:GetWidth()
	r.ring = r:CreateTexture(nil, "ARTWORK", nil, 2)
	r.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(r.ring, 58, 58)
	r.ring:SetPoint("CENTER", r, "LEFT", 46, 0)
	r.check = r:CreateTexture(nil, "OVERLAY", nil, 3)
	r.check:SetTexture(MEDIA .. "Check")
	CuratorOctoFull.SetSize(r.check, 38, 38)
	r.check:SetPoint("CENTER", r, "LEFT", 66, -16)
	-- what to do, how far, its period
	r.name = S.Text(r, "GameFontHighlight", "LEFT")
	r.name:SetPoint("TOPLEFT", 84, -13)
	-- (1.11.0: the rubies came among the rewards, on its right)
	r.name:SetWidth(w - 84 - 236)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.bar = Hud.XPBar(r, w - 84 - 196, 14, { 1, 0.72, 0.2 })
	r.bar:SetPoint("TOPLEFT", 86, -36)
	r.when = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.when:SetPoint("TOPLEFT", r.bar, "BOTTOMLEFT", 0, -7)
	r.when:SetWidth(w - 84 - 176)
	CuratorOctoFull.SetWordWrap(r.when, false)
	-- its rewards
	r.packText = Hud.Text(r, 14, "OUTLINE")
	r.packText:SetPoint("RIGHT", r, "TOPRIGHT", -18, -24)
	r.packText:SetTextColor(1, 0.88, 0.6)
	r.pack = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.pack, 32, 32)
	r.pack:SetPoint("RIGHT", r.packText, "LEFT", 0, 0)
	r.xp = Hud.Text(r, 14, "OUTLINE")
	r.xp:SetTextColor(0.88, 0.76, 1)
	r.orb = r:CreateTexture(nil, "ARTWORK")
	r.orb:SetTexture(Hud.XP)
	CuratorOctoFull.SetSize(r.orb, 24, 24)
	r.orb:SetPoint("RIGHT", r.xp, "LEFT", -1, 0)
	-- (1.11.0) its rubies, before its experience
	r.ruby = ns.RubiesUI.Tag(r, 18, 14)
	r.ruby:SetPoint("RIGHT", r.orb, "LEFT", -8, 0)
	-- to claim them; once claimed
	r.claim = Hud.ClaimButton(r, 120, 30, L["Claim"])
	r.claim:SetPoint("RIGHT", r, "BOTTOMRIGHT", -14, 22)
	CuratorOctoFull.SetScript(r.claim, "OnClick", function()
		A:ClaimCards({ r })
	end)
	r.claim.tip = function(self)
		A:QuestTooltip(r, self)
	end
	-- (1.14.0: off on a reroll, why in its tooltip)
	if r.claim.SetMotionScriptsWhileDisabled then
		r.claim:SetMotionScriptsWhileDisabled(true)
	end
	r.claimed = Hud.Text(r, 13, "OUTLINE")
	r.claimed:SetPoint("RIGHT", r, "BOTTOMRIGHT", -20, 22)
	r.claimed:SetTextColor(0.55, 0.95, 0.45)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		if self.waiting then
			A:ClaimCards({ self })
		end
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:QuestTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- its glow breathes while its rewards wait (1.14.0: not on a reroll, which cannot claim them)
	r.t = 0
	CuratorOctoFull.SetScript(r, "OnUpdate", function(self, elapsed)
		if self.waiting and not self.locked then
			self.t = self.t + elapsed
			Each(self.glow, "SetAlpha", 0.5 + 0.3 * math.sin(self.t * 3.2))
		end
	end)
	return r
end

-- (1.9.0) A row of a quest, for a section of more than five: its icon in a smaller ring, what to do on
-- top, under it how far and its rewards, on the right its period, the button to claim or claimed.
local function NewRow(parent, w)
	local r = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r.compact, r.checkSize = true, 24
	r.bg = Sliced(r, "QuestCard", ROW_H, 0, "BACKGROUND")
	r.glow = Sliced(r, "QuestGlow", ROW_H, GlowOut(ROW_H), "BORDER", 0, "ADD")
	Each(r.glow, "SetVertexColor", GOLDEN[1], GOLDEN[2], GOLDEN[3])
	Each(r.glow, "SetAlpha", 0)
	r.flash = r:CreateTexture(nil, "BORDER", nil, 1)
	r.flash:SetPoint("TOPLEFT", 3, -3)
	r.flash:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(r.flash, 1, 0.86, 0.5, 1)
	r.flash:SetBlendMode("ADD")
	r.flash:SetAlpha(0)
	r.accent = r:CreateTexture(nil, "BORDER", nil, 2)
	r.accent:SetTexture(MEDIA .. "QuestAccent")
	r.accent:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(r.accent, 9, ROW_H - 10)
	r.accent:SetPoint("LEFT", 2, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetPoint("TOPLEFT", 3, -3)
	r.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.7, 0.05)
	r.icon = RoundIcon(r, 28)
	r.icon:SetPoint("CENTER", r, "LEFT", 31, 0)
	r.iconW = r.icon:GetWidth()
	r.ring = r:CreateTexture(nil, "ARTWORK", nil, 2)
	r.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(r.ring, 38, 38)
	r.ring:SetPoint("CENTER", r, "LEFT", 31, 0)
	r.check = r:CreateTexture(nil, "OVERLAY", nil, 3)
	r.check:SetTexture(MEDIA .. "Check")
	CuratorOctoFull.SetSize(r.check, 24, 24)
	r.check:SetPoint("CENTER", r, "LEFT", 44, -10)
	-- what to do; under it how far, then its rewards
	r.name = S.Text(r, "GameFontHighlight", "LEFT")
	r.name:SetPoint("TOPLEFT", 58, -7)
	r.name:SetWidth(w - 58 - 136)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.bar = Hud.XPBar(r, 150, 11, { 1, 0.72, 0.2 })
	r.bar:SetPoint("TOPLEFT", 60, -27)
	r.orb = r:CreateTexture(nil, "ARTWORK")
	r.orb:SetTexture(Hud.XP)
	CuratorOctoFull.SetSize(r.orb, 18, 18)
	r.orb:SetPoint("LEFT", r.bar, "RIGHT", 10, 0)
	r.xp = Hud.Text(r, 12, "OUTLINE")
	r.xp:SetTextColor(0.88, 0.76, 1)
	r.xp:SetPoint("LEFT", r.orb, "RIGHT", 1, 0)
	r.pack = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.pack, 22, 22)
	r.pack:SetPoint("LEFT", r.xp, "RIGHT", 9, 0)
	r.packText = Hud.Text(r, 12, "OUTLINE")
	r.packText:SetPoint("LEFT", r.pack, "RIGHT", 1, 0)
	r.packText:SetTextColor(1, 0.88, 0.6)
	-- (1.11.0) its rubies, after the others (placed in PaintCard)
	r.ruby = ns.RubiesUI.Tag(r, 16, 12)
	-- on the right: its period (on the line of what to do: its rewards have the line under it to
	-- themselves); the button to claim; claimed
	r.when = S.Text(r, "GameFontHighlightSmall", "RIGHT")
	r.when:SetPoint("TOPRIGHT", -16, -9)
	r.when:SetWidth(126)
	CuratorOctoFull.SetWordWrap(r.when, false)
	r.claim = Hud.ClaimButton(r, 104, 26, L["Claim"])
	r.claim:SetPoint("RIGHT", -12, 0)
	CuratorOctoFull.SetScript(r.claim, "OnClick", function()
		A:ClaimCards({ r })
	end)
	r.claim.tip = function(self)
		A:QuestTooltip(r, self)
	end
	if r.claim.SetMotionScriptsWhileDisabled then
		r.claim:SetMotionScriptsWhileDisabled(true)
	end
	r.claimed = Hud.Text(r, 12, "OUTLINE")
	r.claimed:SetPoint("RIGHT", -18, 0)
	r.claimed:SetTextColor(0.55, 0.95, 0.45)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		if self.waiting then
			A:ClaimCards({ self })
		end
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:QuestTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	r.t = 0
	CuratorOctoFull.SetScript(r, "OnUpdate", function(self, elapsed)
		if self.waiting and not self.locked then
			self.t = self.t + elapsed
			Each(self.glow, "SetAlpha", 0.5 + 0.3 * math.sin(self.t * 3.2))
		end
	end)
	return r
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
function A:BuildQuests()
	local f = self.frame
	if f.quests then
		return
	end
	local U = self.U
	-- in the head of the window: the emblem of the rank, the bar of the level and what is left of it
	f.qEmblem = Hud.Emblem(f, 56)
	f.qEmblem:SetPoint("CENTER", f, "TOPLEFT", 94, -44)
	f.qEmblem:SetFrameLevel(f:GetFrameLevel() + 12)
	f.qEmblem:EnableMouse(true)
	CuratorOctoFull.SetScript(f.qEmblem, "OnEnter", function(self)
		A:RankTooltip(self)
	end)
	CuratorOctoFull.SetScript(f.qEmblem, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.qXP = Hud.XPBar(f, U.BAR_W, 18)
	f.qXP:SetPoint("RIGHT", f, "TOPRIGHT", -16, -36)
	f.qXP:EnableMouse(true)
	CuratorOctoFull.SetScript(f.qXP, "OnEnter", function(self)
		A:HeadTooltip(self)
	end)
	CuratorOctoFull.SetScript(f.qXP, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.qNote = S.Text(f, "GameFontHighlightSmall", "RIGHT")
	f.qNote:SetPoint("TOPRIGHT", f.qXP, "BOTTOMRIGHT", 0, -7)
	f.qNote:SetTextColor(DIM[1], DIM[2], DIM[3])
	f.qEmblem:Hide()
	f.qXP:Hide()
	f.qNote:Hide()

	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.quests = page
	local rw = U.PAGE_W - 32 - X0
	page.rw = rw

	-- the sections
	page.nav = {}
	for i, sec in ipairs(NAV) do
		page.nav[i] = NewNav(page, sec, i)
	end
	local navBottom = -(CuratorOctoFull.Length(NAV) * (NAV_H + NAV_GAP) - NAV_GAP)

	-- the stock of the rewards to choose (1.14.0, his word: the boosters to choose before), the button that shows them
	local st = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(st, NAV_W, STOCK_H)
	st:SetPoint("TOPLEFT", 0, navBottom - 16)
	st.bg = Sliced(st, "QuestCard", STOCK_H, 0, "BACKGROUND")
	st.title = S.Text(st, "GameFontNormal")
	st.title:SetPoint("TOP", 0, -12)
	st.title:SetText(L["Rewards to choose"])
	st.slots = {}
	for _, kind in ipairs({ "offer" }) do
		local s = CreateFrame("Frame", nil, st)
		CuratorOctoFull.SetSize(s, 56, 66)
		s:SetPoint("TOP", st, "TOP", 0, -32)
		s.glow = s:CreateTexture(nil, "BACKGROUND")
		s.glow:SetTexture(MEDIA .. "Glow")
		s.glow:SetBlendMode("ADD")
		s.glow:SetVertexColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
		CuratorOctoFull.SetSize(s.glow, 80, 80)
		s.glow:SetPoint("CENTER", s, "TOP", 0, -24)
		s.glow:SetAlpha(0)
		s.icon = s:CreateTexture(nil, "ARTWORK")
		s.icon:SetTexture(Hud.PackIcon(kind))
		CuratorOctoFull.SetSize(s.icon, 48, 48)
		s.icon:SetPoint("CENTER", s, "TOP", 0, -24)
		s.count = Hud.Text(s, 14, "OUTLINE")
		s.count:SetPoint("TOP", s, "TOP", 0, -48)
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
	-- (the window of the rewards to choose, UI/Offers.lua)
	st.go = Hud.ClaimButton(st, NAV_W - 24, 30, L["Choose"])
	st.go:SetPoint("BOTTOM", 0, 12)
	CuratorOctoFull.SetScript(st.go, "OnClick", function()
		if ns.OffersUI then
			ns.OffersUI:Show()
		end
	end)
	-- (1.14.0, after its test, his word: off on a reroll, why in its tooltip, UI/Boosters.lua)
	st.go.tip = function(self)
		A:ChoiceTip(self)
	end
	if st.go.SetMotionScriptsWhileDisabled then
		st.go:SetMotionScriptsWhileDisabled(true)
	end
	page.stock = st
	page.stockNote = S.Text(page, "GameFontHighlightSmall", "LEFT")
	page.stockNote:SetPoint("TOPLEFT", st, "BOTTOMLEFT", 4, -8)
	page.stockNote:SetWidth(NAV_W - 4)
	CuratorOctoFull.SetWordWrap(page.stockNote, true)
	page.stockNote:SetTextColor(DIM[1], DIM[2], DIM[3])
	st.note = page.stockNote

	-- the quests of the section, on their cards
	local bd = CreateFrame("Frame", nil, page)
	bd:SetPoint("TOPLEFT", X0, 0)
	bd:SetPoint("BOTTOMRIGHT")
	page.board = bd
	bd.title = S.Text(bd, "GameFontNormalLarge", "LEFT")
	bd.title:SetPoint("TOPLEFT", 4, -4)
	bd.timer = S.Text(bd, "GameFontHighlightSmall", "LEFT")
	bd.timer:SetPoint("TOPLEFT", bd.title, "BOTTOMLEFT", 0, -5)
	bd.timer:SetTextColor(DIM[1], DIM[2], DIM[3])
	bd.claimAll = Hud.ClaimButton(bd, 150, 32, L["Claim all"])
	bd.claimAll:SetPoint("TOPRIGHT", -2, -4)
	CuratorOctoFull.SetScript(bd.claimAll, "OnClick", function()
		A:ClaimSection()
	end)
	-- (1.11.0) the quests of the page changed for others, for rubies
	bd.reroll = A:NewRerollButton(bd)
	-- (1.14.0, after its test, his word: on a reroll, in their place, the padlock and why: UI/Reroll.lua)
	bd.locker = ns.RerollUI and ns.RerollUI.Pill and ns.RerollUI.Pill(bd) or nil
	bd.cards = {}
	for i = 1, CARDS do
		local r = NewCard(bd, rw)
		r:SetPoint("TOPLEFT", 0, -HEAD_H - (i - 1) * (CARD_H + CARD_GAP))
		bd.cards[i] = r
	end
	-- (1.9.0) the rows of a section of more than five quests
	bd.rows = {}
	for i = 1, ROWS do
		local r = NewRow(bd, rw)
		r:SetPoint("TOPLEFT", 0, -HEAD_H - (i - 1) * (ROW_H + ROW_GAP))
		r:Hide()
		bd.rows[i] = r
	end
	bd.shown = bd.cards
	-- (the note of a section on rows: behind this button, next to its title)
	bd.info = Hud.InfoButton(bd, 18)
	bd.info:SetPoint("LEFT", bd.title, "RIGHT", 8, 0)
	bd.info.tip = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(bd.title:GetText() or "", S.GOLD[1], S.GOLD[2], S.GOLD[3])
		GameTooltip:AddLine(bd.info.note or "", 1, 1, 1, true)
		GameTooltip:Show()
	end
	bd.info:Hide()
	bd.note = S.Text(bd, "GameFontHighlightSmall")
	bd.note:SetWidth(rw - 20)
	CuratorOctoFull.SetWordWrap(bd.note, true)
	bd.note:SetTextColor(DIM[1], DIM[2], DIM[3])
	-- (a section the account cannot do yet: its icon locked, the level it waits for)
	bd.lock = bd:CreateTexture(nil, "ARTWORK", nil, 2)
	bd.lock:SetTexture(MEDIA .. "Lock")
	CuratorOctoFull.SetSize(bd.lock, 96, 96)
	bd.lock:SetPoint("CENTER", bd, "TOP", 0, -190)
	bd.lockIcon = RoundIcon(bd, 52)
	bd.lockIcon:SetPoint("CENTER", bd.lock, "CENTER")
	bd.locked = S.Text(bd, "GameFontHighlight")
	bd.locked:SetPoint("TOP", bd.lock, "BOTTOM", 0, -14)
	bd.locked:SetWidth(rw - 80)
	CuratorOctoFull.SetWordWrap(bd.locked, true)

	-- the time left moves on while the page is open
	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		self.tick = (self.tick or 0) + elapsed
		if self.tick >= 20 then
			self.tick = 0
			if not A.questBusy then
				A:Refresh()
			end
		end
	end)
	-- (the page gone, the claims end at once: a level gained shows; the cards turning over, turned)
	CuratorOctoFull.SetScript(page, "OnHide", function()
		ns.CancelOwner(ANIM)
		A:EndClaims()
		A:EndFlips()
	end)
end

function A:ShowQuestsPage(shown)
	local f = self.frame
	if shown then
		self:BuildQuests()
	end
	if f.quests then
		CuratorOctoFull.SetShown(f.quests, shown)
		CuratorOctoFull.SetShown(f.qEmblem, shown)
		CuratorOctoFull.SetShown(f.qXP, shown)
		CuratorOctoFull.SetShown(f.qNote, shown)
	end
	CuratorOctoFull.SetShown(f.bar, not shown)
	if not shown and f.subMoved then
		f.subMoved = nil
		f.sub:ClearAllPoints()
		f.sub:SetPoint("TOPLEFT", 64, -55)
	end
end

function A:SetQuestSection(key)
	if key ~= self.questSec then
		self:FinishClaims()
		self:EndFlips()
		self.questSec = key
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- Something changed (a quest moved, experience, a reward claimed): the page again, unless rewards
-- are landing on it (then at their end).
function A:QuestsChanged()
	if self.questBusy then
		self.questDirty = true
	elseif not self.refreshQueued then
		-- (the changes of one moment, painted once, on the next frame)
		self.refreshQueued = true
		ns.Delay(0, function()
			A.refreshQueued = nil
			if A.frame:IsShown() and A:ClaimsPage() and not A.questBusy then
				A:Refresh()
			end
		end)
	end
end

-- The badge of the tab of the quests: the rewards waiting (with the other badges of the tabs).
function A:PaintQuestBadge()
	self:PaintBadges()
end

-------------------------------------------------------------------------------
-- Painting the page
-------------------------------------------------------------------------------
function A:RefreshQuests()
	local f = self.frame
	local page = f.quests
	self:Order()
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	Q:Check(true)
	self.questDirty = nil
	if not (self.questSec and Section(self.questSec).key == self.questSec) then
		self.questSec = "daily"
	end
	self:PaintLevelHead(self.shownXP or LV:XP())
	self:PaintNav()
	self:PaintStock(self.shownStock)
	page.board:Show()
	self:PaintBoard()
	self:PaintBadges()
end

-- The head of the window: the level (an experience: what the bar shows while rewards land), the rank
-- and the next one, the emblem, the bar.
function A:PaintLevelHead(xp)
	local f = self.frame
	local level, into, need = LV.Of(xp)
	local r, rank = LV.RankOf(level)
	local nx = LV.RANKS[r + 1]
	local sub = "|cff" .. Hex(rank.color) .. L[rank.name] .. "|r   ·   "
	if nx then
		sub = sub .. string.format(L["Next rank: %s at level %d"], LV.EmblemText(r + 1, 14) .. " " .. L[nx.name], nx.level)
	else
		sub = sub .. L["The highest rank"]
	end
	self:SetTitle(string.format(L["Collector level %d"], level), sub)
	f.title:ClearAllPoints()
	f.title:SetPoint("LEFT", f, "TOPLEFT", TITLE_X, -38)
	if ns.TextWidth(f.title) > TITLE_ROOM then
		S.Fit(f.title, f.title:GetText(), TITLE_ROOM, 19, 12)
	end
	f.sub:ClearAllPoints()
	f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_X + 1, -55)
	f.subMoved = true
	if f.qEmblem.rank ~= r or not f.qEmblem.painted then
		f.qEmblem.painted = true
		f.qEmblem:SetRank(r)
	end
	f.qXP:SetProgress(need and into / need or 1)
	f.qXP:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
	f.qNote:SetText(need and string.format(L["%s XP to level %d"], ns.Num(need - into), level + 1) or string.format(L["Total: %s XP"], ns.Num(xp)))
end

-- The sections: chosen in gold, how many quests done, the badge of the rewards waiting.
function A:PaintNav()
	local page = self.frame.quests
	-- (1.14.0, after its test, his word: a reroll claims none, no badge of them)
	local rr = Locked()
	for _, b in ipairs(page.nav) do
		local key = b.sec.key
		local claim, text, grey = 0, "", false
		SetIcon(b.icon, { ICON[key] })
		claim = rr and 0 or CuratorOctoFull.Length(Q:Claimable(key))
		local done, all = Q:Count(b.sec.boards)
		local _, locked = self:QuestRows(b.sec)
		if all == 0 and locked then
			text, grey = string.format(L["Level %d"], Q:Needs(locked)), true
		else
			text = string.format(("%d/%d"), done, all)
		end
		b.badge:SetCount(claim)
		b.count:SetText(text)
		b.count:ClearAllPoints()
		if claim > 0 then
			b.count:SetPoint("RIGHT", b.badge, "LEFT", -4, 0)
		else
			b.count:SetPoint("RIGHT", -10, 0)
		end
		if grey then
			b.count:SetTextColor(0.55, 0.55, 0.55)
		else
			b.count:SetTextColor(0.85, 0.85, 0.88)
		end
		local room = NAV_W - 38 - 8 - (text ~= "" and (ns.TextWidth(b.count) + 6) or 0) - (claim > 0 and 26 or 2)
		S.SetFontObject(b.text, "GameFontNormal")
		b.text:SetWidth(room)
		b.text:SetText(L[b.sec.label])
		if ns.TextWidth(b.text) > room then
			S.Fit(b.text, L[b.sec.label], room, 12, 9)
		end
		local on = key == self.questSec
		Each(b.glow, "SetAlpha", on and 0.7 or 0)
		CuratorOctoFull.SetShown(b.accent, on)
		if on then
			b.text:SetTextColor(1, 1, 1)
		else
			b.text:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
		end
	end
end

-- The quests of a section, each with its board: { board, q }.
function A:QuestRows(sec)
	local rows, locked = {}, nil
	for _, key in ipairs(sec.boards or {}) do
		local board = Q.byKey[key]
		local list, isLocked = Q:List(key)
		if isLocked then
			locked = locked or board
		end
		for _, q in ipairs(list) do
			rows[CuratorOctoFull.Length(rows) + 1] = { board = board, q = q }
		end
	end
	return rows, locked
end

-- The quests of the section on their cards.
function A:PaintBoard()
	local page = self.frame.quests
	local bd = page.board
	local sec = Section(self.questSec)
	bd.title:SetText(L[TITLE[sec.key] or "Daily quests"])
	-- when its quests end (a section of several periods: each, in the colour of its cards; 1.9.0: the
	-- quests change at 5:00 in Paris)
	local seen, parts, single = {}, {}, nil
	for _, key in ipairs(sec.boards) do
		local p = Q.byKey[key].period
		if not seen[p] then
			seen[p] = true
			local left = Q:ResetLeft(p)
			if left then
				parts[CuratorOctoFull.Length(parts) + 1] = "|cff" .. Hex(TINT[p] or DIM) .. string.format(L[HEAD[p]], ns.Duration(left)) .. "|r"
				single = left
			end
		end
	end
	if CuratorOctoFull.Length(parts) == 1 then
		bd.timer:SetText(string.format(L["New quests in %s"], ns.Duration(single)))
	else
		bd.timer:SetText(table.concat(parts, "   ·   "))
	end
	local rows, locked = self:QuestRows(sec)
	-- (more than five: on rows)
	local set = CuratorOctoFull.Length(rows) > CARDS and bd.rows or bd.cards
	local other = set == bd.cards and bd.rows or bd.cards
	bd.shown = set
	for _, r in ipairs(other) do
		r:Hide()
		r.waiting = false
	end
	local waiting, last = 0, nil
	for i, r in ipairs(set) do
		local row = rows[i]
		SHOWS[r] = row and { board = row.board, q = row.q } or nil
		CuratorOctoFull.SetShown(r, row ~= nil)
		if row then
			self:PaintCard(r)
			if r.waiting then
				waiting = waiting + 1
			end
			last = r
		else
			r.waiting = false
		end
	end
	-- (1.14.0, after its test, his word: a reroll claims none, its padlock in the place of the buttons)
	local rr = Locked()
	CuratorOctoFull.SetShown(bd.claimAll, waiting >= 2 and not rr)
	CuratorOctoFull.SetEnabled(bd.claimAll, waiting >= 2 and not rr)
	bd.claimAll:SetPulse(true)
	self:PaintReroll()
	local none = CuratorOctoFull.Length(rows) == 0
	CuratorOctoFull.SetShown(bd.lock, none)
	CuratorOctoFull.SetShown(bd.lockIcon, none)
	CuratorOctoFull.SetShown(bd.locked, none)
	if none then
		SetIcon(bd.lockIcon, { ICON[sec.key] or ICON.daily })
		bd.lockIcon:SetDesaturated(true)
		local need = locked and Q:Needs(locked)
		bd.locked:SetText(need and string.format(L["These quests come when one of your characters reaches level %d."], need) or "")
	end
	bd.note:ClearAllPoints()
	local note = NOTES[sec.key] and L[NOTES[sec.key]] or ""
	-- (1.14.0: from the release of OctoWoW, the main and the characters of level 15 or more count, Reroll.lua)
	local RR = ns.Reroll
	if RR and RR:Active() and NOTES_FOREVER[sec.key] then
		note = string.format(L[NOTES_FOREVER[sec.key]], RR.LEVEL)
	end
	-- (a reroll: why it does none, in the colour of its padlock)
	local why = rr and RR:WhyNot("quests") or nil
	bd.note:SetTextColor(why and 1 or DIM[1], why and 0.62 or DIM[2], why and 0.45 or DIM[3])
	if last and set == bd.rows then
		-- (no room under ten rows: behind the button of information)
		bd.note:SetPoint("TOP", bd, "TOP", 0, -HEAD_H)
		bd.note:SetText("")
		bd.info.note = why and (note ~= "" and (note .. "\n\n" .. why) or why) or note
		CuratorOctoFull.SetShown(bd.info, bd.info.note ~= "")
	elseif last then
		bd.note:SetPoint("TOP", last, "BOTTOM", 0, -10)
		bd.note:SetText(why or note)
		bd.info:Hide()
	else
		bd.note:SetPoint("TOP", bd, "TOP", 0, -HEAD_H)
		bd.note:SetText("")
		bd.info:Hide()
	end
end

-- A card: what to do, how far, its period; its rewards; to claim them, or claimed.
function A:PaintCard(r)
	local q, board = Shown(r)
	local done, claimed = q.done ~= nil, q.claimed ~= nil
	local waiting = done and not claimed
	r.waiting = waiting
	SetIcon(r.icon, Icon(q.k))
	r.icon:SetDesaturated(claimed)
	-- (a card turning over to a new quest keeps turning: UI A:RerollFlip)
	if not r.flipping then
		r.icon:SetWidth(r.iconW or r.icon:GetWidth())
		r.name:SetAlpha(1)
	end
	S.SetFontObject(r.name, "GameFontHighlight")
	r.name:SetText(Q:Text(q))
	if ns.TextWidth(r.name) > r.name:GetWidth() then
		S.Fit(r.name, Q:Text(q), r.name:GetWidth(), 12, 9)
	end
	if claimed then
		r.name:SetTextColor(0.72, 0.72, 0.74)
	else
		r.name:SetTextColor(1, 1, 1)
	end
	r.bar:SetProgress(done and 1 or (q.got or 0) / math.max(1, q.n))
	r.bar:SetText(done and L["Done!"] or string.format(("%s / %s"), ns.Num(q.got or 0), ns.Num(q.n)))
	local left = Q:ResetLeft(board.period)
	local when = L[PERIOD[board.period]]
	if r.compact then
		-- (a row: its period on the right, in its colour; the button to claim or claimed in its place)
		local tint = TINT[board.period] or DIM
		CuratorOctoFull.SetShown(r.when, not (claimed or waiting))
		S.SetFontObject(r.when, "GameFontHighlightSmall")
		r.when:SetText(when)
		if ns.TextWidth(r.when) > r.when:GetWidth() then
			S.Fit(r.when, when, r.when:GetWidth(), 10, 7.5)
		end
		r.when:SetTextColor(tint[1], tint[2], tint[3])
	else
		if claimed then
			when = when .. "  ·  " .. string.format(L["New quests in %s"], ns.Duration(left or 0))
		elseif waiting then
			when = when .. "  ·  |cff66ff55" .. L["Rewards to claim!"] .. "|r"
		elseif left then
			when = when .. "  ·  " .. string.format(L["Ends in %s"], ns.Duration(left))
		end
		S.SetFontObject(r.when, "GameFontHighlightSmall")
		r.when:SetText(when)
		if ns.TextWidth(r.when) > r.when:GetWidth() then
			S.Fit(r.when, when, r.when:GetWidth(), 10, 7.5)
		end
		r.when:SetTextColor(DIM[1], DIM[2], DIM[3])
	end
	local c = waiting and GOLDEN or (claimed and { 0.45, 0.45, 0.5 }) or TINT[board.period] or GOLDEN
	r.accent:SetVertexColor(c[1], c[2], c[3])
	r.accent:SetAlpha(claimed and 0.5 or 1)
	-- the rewards: its experience, its boosters to choose or its points on the booster bar
	r.xp:SetText(string.format(L["+%s XP"], ns.Num(Q:XP(q))))
	local packs = (q.p or 0) > 0 and board.kind
	local pts = not packs and (tonumber(q.pts) or 0) > 0
	CuratorOctoFull.SetShown(r.pack, (packs or pts) and true or false)
	CuratorOctoFull.SetShown(r.packText, (packs or pts) and true or false)
	if packs then
		r.pack:SetTexture(Hud.PackIcon(board.kind))
		r.pack:SetDesaturated(false)
		r.packText:SetText("x" .. q.p)
	elseif pts then
		r.pack:SetTexture(Hud.PackIcon("zone"))
		r.packText:SetText(string.format(L["+%s pts"], ns.Num(q.pts)))
	end
	-- (a card: its rewards in its top right corner, the experience before the boosters or the points; a
	-- row: they follow its bar, placed once)
	if not r.compact then
		r.xp:ClearAllPoints()
		if packs or pts then
			r.xp:SetPoint("RIGHT", r.pack, "LEFT", -8, 0)
		else
			r.xp:SetPoint("RIGHT", r, "TOPRIGHT", -18, -24)
		end
	end
	-- (1.11.0) its rubies: before the experience on a card, after the other rewards on a row
	local rubies = Q:Rubies(board, q)
	CuratorOctoFull.SetShown(r.ruby, rubies > 0)
	if rubies > 0 then
		r.ruby:SetAmount(rubies, true)
		r.ruby:SetAlpha(claimed and 0.6 or 1)
		if r.compact then
			r.ruby:ClearAllPoints()
			if packs or pts then
				r.ruby:SetPoint("LEFT", r.packText, "RIGHT", 9, 0)
			else
				r.ruby:SetPoint("LEFT", r.xp, "RIGHT", 9, 0)
			end
		end
	end
	-- to claim them, or claimed (1.14.0, after its test, his word: a reroll claims none, its button off, why in its
	-- tooltip)
	local rr = Locked()
	r.locked = rr
	CuratorOctoFull.SetShown(r.claim, waiting)
	r.claim:SetAlpha(1)
	CuratorOctoFull.SetEnabled(r.claim, waiting and not rr)
	r.claim:SetPulse(waiting and not rr)
	CuratorOctoFull.SetShown(r.claimed, claimed)
	r.claimed:SetAlpha(1)
	r.claimed:SetText(L["Claimed"])
	CuratorOctoFull.SetShown(r.check, claimed)
	CuratorOctoFull.SetSize(r.check, r.checkSize or 38, r.checkSize or 38)
	r.check:SetAlpha(1)
	r.flash:SetAlpha(0)
	if not waiting or rr then
		Each(r.glow, "SetAlpha", 0)
	end
	r:SetAlpha(claimed and 0.78 or 1)
end

-------------------------------------------------------------------------------
-- The claims: the rewards land, the page waits for them
-------------------------------------------------------------------------------
-- The level and the stock stay as they were, then move as each reward lands; a level gained shows at
-- the end. (Claims made while others land go on with them.)
function A:BeginClaims()
	if not self.questBusy then
		self.questBusy = true
		-- (the page the rewards land on: its bar of the level)
		self.claimPage = (self.mode == "ach" and "ach") or (self.mode == "profile" and "profile") or "quests"
		self.claimEpoch = (self.claimEpoch or 0) + 1
		self.claimWait = 0
		self.shownXP = LV:XP()
		-- (1.14.0: the rewards to choose, as many as wait)
		self.shownStock = { offer = LV:OfferCount() }
	end
	return self.claimEpoch
end

function A:EndClaims()
	if not self.questBusy then
		return
	end
	self.questBusy = false
	self.claimEpoch = self.claimEpoch + 1
	self.claimWait = 0
	self.shownXP, self.shownStock = nil, nil
	local f = self.frame
	local page = (self.claimPage == "ach" and f.ach) or (self.claimPage == "profile" and f.prof) or f.quests
	local seen = page ~= nil and page:IsVisible()
	if seen then
		self:Refresh()
	else
		self:PaintBadges()
	end
	-- the screen of a level gained by the rewards claimed (the album closing with them: its toast)
	local lv = self.pendingLevel
	self.pendingLevel = nil
	if lv then
		if seen and ns.LevelUp then
			ns.LevelUp:Play(lv.from, lv.to)
		elseif ns.Toast and ns.Toast.LevelUp then
			ns.Toast:LevelUp(lv.to)
		end
	end
end

-- The rewards claimed so far land at once (another section, another view).
function A:FinishClaims()
	if self.questBusy then
		ns.CancelOwner(ANIM)
		self:EndClaims()
	end
end

-- The end of these claims, after sec seconds (the last of those landing ends them).
function A:EndClaimsIn(sec)
	local epoch = self.claimEpoch
	self.claimWait = (self.claimWait or 0) + 1
	ns.Delay(sec, function()
		if A.questBusy and A.claimEpoch == epoch then
			A.claimWait = A.claimWait - 1
			if A.claimWait <= 0 then
				A:EndClaims()
			end
		end
	end, ANIM)
end

-- Experience landing in the bar of the level: it fills (a level crossed: a flash).
function A:AddShownXP(n, epoch)
	if not (self.questBusy and self.claimEpoch == epoch) or n <= 0 then
		return
	end
	local f = self.frame
	local from = self.shownXP or LV:XP()
	local to = from + n
	self.shownXP = to
	local lv0 = LV.Of(from)
	-- (the bar of the level of the page: the head of the quests, the box of the achievements, of the
	-- profile)
	local box = (self.claimPage == "ach" and f.ach.lv) or (self.claimPage == "profile" and f.prof.lv) or nil
	local bar = box and box.xp or f.qXP
	local emblem = box and box.emblem or f.qEmblem
	ns.Play(ns.SND.orbHit)
	bar:Flash(0.8)
	ns.Tween(0.55, function(e)
		local x = math.floor(from + (to - from) * e + 0.5)
		local lv = LV.Of(x)
		if lv > lv0 then
			lv0 = lv
			bar:Flash(1)
			Hud.Burst(emblem, { 0.86, 0.7, 1 }, 18, 130, 18)
			ns.Play(ns.SND.xpTick)
		end
		if box then
			box:Paint(x)
		else
			A:PaintLevelHead(x)
		end
	end, nil, Ease.outCubic, ANIM)
end

-- Boosters to choose landing: in the stock of the page of the quests (its count grows, the slot
-- shines), else on the tab of the inventory, where the boosters are (its badge grows).
function A:AddShownPacks(kind, n, epoch)
	if not (self.questBusy and self.claimEpoch == epoch) or n <= 0 then
		return
	end
	-- (1.14.0, his word: a booster to choose is a reward to choose now; a golden one goes into an album at once)
	if kind == "golden" then
		return
	end
	kind = "offer"
	local st = self.shownStock
	st[kind] = (st[kind] or 0) + n
	self:PaintStock(st)
	self:PaintBadges()
	ns.Play(ns.SND.coins)
	local stock = self.claimPage == "quests" and self.frame.quests and self.frame.quests.stock
	local slot = stock and stock:IsVisible() and stock.slots[kind]
	if not slot then
		Hud.Burst(self:BoosterTab(), GOLDEN, 12, 90, 14)
		return
	end
	ns.Tween(0.35, function(e, raw)
		local k = 1 + 0.3 * math.sin(math.pi * e)
		CuratorOctoFull.SetSize(slot.icon, 48 * k, 48 * k)
		slot.glow:SetAlpha(0.9 * (1 - raw))
	end, function()
		CuratorOctoFull.SetSize(slot.icon, 48, 48)
		slot.glow:SetAlpha(0)
	end, Ease.linear, ANIM)
end

-- The tab where the boosters to choose go: the inventory, the first tab, its boosters (1.13.0, after its first test;
-- the tab of the boosters before).
function A:BoosterTab()
	return self.frame.tabs[A.TAB_OF.inventory or A.TAB_OF.boosters]
end

-- The rewards of these cards claimed, one after the other: the button goes, the experience flies to
-- the bar of the level, the boosters to the stock, a stamp of gold comes down. The number claimed.
function A:ClaimCards(cards)
	-- (1.14.0, after its test, his word: a reroll claims none, the chat says why: Reroll.lua)
	if Locked() then
		ns.Reroll:SayNot("quests")
		return 0
	end
	local todo = {}
	for _, r in ipairs(cards) do
		local q = Shown(r)
		if r:IsShown() and r.waiting and q and q.done and not q.claimed then
			todo[CuratorOctoFull.Length(todo) + 1] = r
		end
	end
	if CuratorOctoFull.Length(todo) == 0 then
		return 0
	end
	local f = self.frame
	local stock = f.quests.stock
	local epoch = self:BeginClaims()
	ns.Play(ns.SND.claim)
	for i, r in ipairs(todo) do
		local i, r = i, r; local q, board = Shown(r)
		local xp, p, kind, _, rubies = Q:Claim(board, q)
		local d = (i - 1) * 0.2
		-- (1.11.0) its rubies fly to the purse of the album
		if (rubies or 0) > 0 and f.wallet and f.wallet:IsVisible() then
			ns.Delay(d + 0.1, function()
				Hud.Fly(ns.Rubies.ICON, r.ruby, f.wallet.gem, 24, 0.55, nil, ns.RubiesUI.GLOW)
			end, ANIM)
		end
		-- (claimed now; its button goes when its turn comes)
		r.waiting = false
		ns.Tween(0.2, function(e)
			r.claim:SetAlpha(1 - e)
		end, function()
			r.claim:Hide()
			r.claim:SetAlpha(1)
		end, Ease.linear, ANIM, d)
		ns.Tween(0.5, function(_, raw)
			r.flash:SetAlpha(0.35 * (1 - raw))
			Each(r.glow, "SetAlpha", 0.9 * (1 - raw))
		end, nil, Ease.linear, ANIM, d)
		ns.Delay(d, function()
			Hud.Burst(r.claim, GOLDEN, 14, 110, 16)
		end, ANIM)
		-- the experience flies to the bar of the level
		if xp > 0 then
			ns.Delay(d + 0.05, function()
				ns.Play(ns.SND.orb)
				Hud.Fly(Hud.XP, r.orb, f.qXP, 32, 0.6, function()
					A:AddShownXP(xp, epoch)
				end, { 0.82, 0.62, 1 })
			end, ANIM)
		end
		-- the boosters to the stock (three fly; the last one brings the rest; 1.14.0: rewards to choose now, one slot;
		-- those of Hallow's End go to their album)
		if p > 0 and kind and kind ~= "hallow" then
			local flights = math.min(p, 3)
			for k = 1, flights do
				local k = k; ns.Delay(d + 0.14 + (k - 1) * 0.09, function()
					Hud.Fly(Hud.PackIcon(kind), r.pack, (stock.slots[kind] or stock.slots.offer).icon, 30, 0.62, function()
						A:AddShownPacks(kind, k < flights and 1 or (p - flights + 1), epoch)
					end, { 1, 0.85, 0.45 })
				end, ANIM)
			end
		end
		-- the stamp
		Stamp(r.check, r.checkSize or 38, d + 0.32, function()
			ns.Play(ns.SND.stamp)
			Hud.Burst(r.check, GOLDEN, 12, 90, 14)
			r.icon:SetDesaturated(true)
			r.claimed:SetText(L["Claimed"])
			r.claimed:SetAlpha(0)
			r.claimed:Show()
			ns.Tween(0.3, function(e)
				r.claimed:SetAlpha(e)
				r:SetAlpha(1 - 0.22 * e)
			end, nil, Ease.outQuad, ANIM)
		end)
	end
	self:EndClaimsIn((CuratorOctoFull.Length(todo) - 1) * 0.2 + 1.3)
	return CuratorOctoFull.Length(todo)
end

-- Every reward waiting in the section shown (the button goes with them).
function A:ClaimSection()
	local bd = self.frame.quests.board
	local n = self:ClaimCards(bd.shown or bd.cards)
	if n > 0 then
		bd.claimAll:Hide()
	end
	return n
end

-------------------------------------------------------------------------------
-- (1.11.0) The quests of the page changed for others, for rubies (Quests.lua: Q:Reroll): one button in the
-- head of the page, a die and its price; a first click arms it, a second one within three seconds changes
-- every quest of the page, those done too (their rewards claimed first), each card turning over to its new
-- quest. Once in a while for each page (Q.REROLL_CD): meanwhile the button says when.
-------------------------------------------------------------------------------
local REROLL_ARM = 3
local REROLL_WHY = {
	rubies = "Not enough rubies.",
	none = "No other quest can come on this page now.",
	closed = "Curator is closed: nothing can be bought.",
}
-- (how often a page can change, by its wait)
local REROLL_EVERY = { [86400] = "This page can change once a day.", [7 * 86400] = "This page can change once every 7 days.",
	[30 * 86400] = "This page can change once every 30 days." }

function A:NewRerollButton(bd)
	local b = CreateFrame("Button", nil, bd)
	CuratorOctoFull.SetSize(b, 170, 28)
	b:SetFrameLevel(bd:GetFrameLevel() + 6)
	-- a pill of dark wine, edged in ruby
	b.edge = b:CreateTexture(nil, "BACKGROUND", nil, -1)
	b.edge:SetPoint("TOPLEFT", -1, 1)
	b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(b.edge, 0.85, 0.28, 0.34, 0.75)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.bg, 0.13, 0.03, 0.05, 0.94)
	b.sheen = b:CreateTexture(nil, "BORDER")
	b.sheen:SetPoint("TOPLEFT", 1, -1)
	b.sheen:SetPoint("TOPRIGHT", -1, -1)
	b.sheen:SetHeight(12)
	CuratorOctoFull.ColorTexture(b.sheen, 1, 0.75, 0.78, 0.06)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.45, 0.5, 0.16)
	b.dice = b:CreateTexture(nil, "ARTWORK")
	b.dice:SetTexture("Interface\\Icons\\INV_Misc_Dice_01")
	b.dice:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetSize(b.dice, 20, 20)
	b.dice:SetPoint("LEFT", 5, 0)
	b.label = S.Text(b, "GameFontNormal", "LEFT")
	b.label:SetPoint("LEFT", b.dice, "RIGHT", 6, 0)
	CuratorOctoFull.SetWordWrap(b.label, false)
	b.price = ns.RubiesUI.Tag(b, 15, 12)
	b.price:SetPoint("RIGHT", -8, 0)
	b.free = Hud.Text(b, 12, "OUTLINE")
	b.free:SetPoint("RIGHT", -9, 0)
	b.free:SetTextColor(0.45, 1, 0.45)
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		A:RerollClick(self)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:RerollTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b.t = 0
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		if self.armed then
			CuratorOctoFull.ColorTexture(self.bg, 0.42 + 0.16 * math.sin(self.t * 8), 0.05, 0.09, 0.96)
			if GetTime() - self.armed >= REROLL_ARM then
				self.armed = nil
				A:PaintReroll()
				if self:IsMouseOver() then
					A:RerollTooltip(self)
				end
			end
		end
	end)
	b:Hide()
	return b
end

function A:RerollArmed(b)
	return b.armed ~= nil and GetTime() - b.armed < REROLL_ARM
end

-- The button: shown while a quest of the page can change; its price (free with the Prophecy), its width; to
-- its right the button to claim them all when it is there. The title of the page leaves them room.
function A:PaintReroll()
	local bd = self.frame and self.frame.quests and self.frame.quests.board
	local b = bd and bd.reroll
	if not b then
		return
	end
	local key = self.questSec
	local price, base, n = Q:RerollPrice(key)
	-- (1.14.0, after its test, his word: a reroll changes none; its padlock in the head of the page, UI/Reroll.lua)
	local rr = Locked()
	local show = price ~= nil and ns.Rubies ~= nil and not rr
	CuratorOctoFull.SetShown(b, show)
	b:ClearAllPoints()
	if bd.claimAll:IsShown() then
		b:SetPoint("RIGHT", bd.claimAll, "LEFT", -8, 0)
	else
		b:SetPoint("TOPRIGHT", bd, "TOPRIGHT", -2, -6)
	end
	local right = bd:GetWidth() - (bd.claimAll:IsShown() and 160 or 0)
	local pill = bd.locker
	if pill then
		CuratorOctoFull.SetShown(pill, rr)
		if rr then
			pill:Paint("quests")
			pill:ClearAllPoints()
			pill:SetPoint("TOPRIGHT", bd, "TOPRIGHT", -2, -6)
			right = right - pill:GetWidth() - 10
		end
	end
	if show then
		local ok, why = Q:CanReroll(key)
		b.ok, b.why, b.cost, b.base, b.n, b.key = ok, why, price, base, n, key
		if not self:RerollArmed(b) then
			b.armed = nil
			CuratorOctoFull.ColorTexture(b.bg, 0.13, 0.03, 0.05, 0.94)
		end
		S.SetFontObject(b.label, "GameFontNormal")
		b.label:SetText(b.armed and L["Confirm"] or L["Change the quests"])
		if b.armed then
			b.label:SetTextColor(1, 1, 1)
		else
			b.label:SetTextColor(1, 0.86, 0.5)
		end
		local tagW
		local left = Q:RerollLeft(key)
		b.left = left
		if left > 0 then
			-- (changed not long ago: the time it waits, in the place of its price)
			b.price:Hide()
			b.free:Show()
			b.free:SetText(string.format(L["Again in %s"], ns.Duration(left)))
			b.free:SetTextColor(0.78, 0.78, 0.82)
			tagW = ns.TextWidth(b.free)
		elseif price == 0 then
			b.price:Hide()
			b.free:Show()
			b.free:SetText(L["Free"])
			b.free:SetTextColor(0.45, 1, 0.45)
			tagW = ns.TextWidth(b.free)
		else
			b.free:Hide()
			b.price:Show()
			b.price:SetAmount(price)
			tagW = b.price:GetWidth()
		end
		-- (a little room past its word: the fonts of the clients do not all measure it alike)
		local lw = math.min(ns.TextWidth(b.label) + 4, 154)
		b.label:SetWidth(lw)
		b:SetWidth(5 + 20 + 6 + lw + 10 + tagW + 9)
		b.dice:SetDesaturated(not ok)
		b:SetAlpha(ok and 1 or 0.6)
		right = right - b:GetWidth() - 10
	else
		b.armed = nil
	end
	-- (the title and the time left: up to the buttons)
	local room = math.max(120, right - 4 - (bd.info:IsShown() and 30 or 0))
	local title = bd.title:GetText() or ""
	S.SetFontObject(bd.title, "GameFontNormalLarge")
	bd.title:SetText(title)
	if ns.TextWidth(bd.title) > room then
		S.Fit(bd.title, title, room, 16, 11)
	end
	bd.timer:SetWidth(math.max(120, right - 4))
	CuratorOctoFull.SetWordWrap(bd.timer, false)
	local timer = bd.timer:GetText() or ""
	S.SetFontObject(bd.timer, "GameFontHighlightSmall")
	bd.timer:SetText(timer)
	if ns.TextWidth(bd.timer) > bd.timer:GetWidth() then
		S.Fit(bd.timer, timer, bd.timer:GetWidth(), 10, 7.5)
	end
end

function A:RerollTooltip(b)
	local RB = ns.Rubies
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
	GameTooltip:AddLine(L["Change the quests of this page"], 1, 1, 1)
	GameTooltip:AddLine(L["Every quest of this page makes way for another, drawn among the other kinds, those done too: the rewards of a quest done are claimed first. What you did for the others is lost."], 0.85, 0.85, 0.85, true)
	if (b.n or 0) > 0 then
		GameTooltip:AddLine((b.n == 1 and L["1 quest changes."] or string.format(L["%d quests change."], b.n)), 0.85, 0.85, 0.85)
	end
	if b.cost == 0 then
		GameTooltip:AddLine(L["Free: Prophecy (once a day)."], 0.45, 1, 0.45, true)
	else
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(b.cost or 0, 13)), 1, 0.82, 0.25)
		if b.base and b.cost and b.base > b.cost then
			GameTooltip:AddLine(string.format(L["(%s without your talents)"], RB.Text(b.base, 12)), 0.6, 0.6, 0.62)
		end
	end
	local _, every = Q:RerollLeft(b.key)
	if REROLL_EVERY[every] then
		GameTooltip:AddLine(L[REROLL_EVERY[every]], 0.7, 0.7, 0.72, true)
	end
	if not b.ok and b.why == "wait" then
		GameTooltip:AddLine(string.format(L["Changed not long ago: again in %s."], ns.Duration(Q:RerollLeft(b.key))), 1, 0.45, 0.4, true)
	elseif not b.ok and b.why == "reroll" and ns.Reroll then
		GameTooltip:AddLine(ns.Reroll:WhyNot("quests"), 1, 0.45, 0.4, true)
	elseif not b.ok then
		GameTooltip:AddLine(L[REROLL_WHY[b.why or ""] or "Curator is closed: nothing can be bought."], 1, 0.45, 0.4, true)
	elseif self:RerollArmed(b) then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	GameTooltip:Show()
end

function A:RerollClick(b)
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	if self.questBusy then
		return
	end
	local key = self.questSec
	self:PaintReroll()
	if not b.ok then
		ns.Play(ns.SND.close)
		self:RerollTooltip(b)
		return
	end
	if not self:RerollArmed(b) then
		b.armed = GetTime()
		b.t = 0
		ns.Play(ns.SND.click)
		self:PaintReroll()
		self:RerollTooltip(b)
		return
	end
	b.armed = nil
	local changed, why = Q:Reroll(key)
	if not changed then
		ns.Play(ns.SND.close)
		if why == "wait" then
			ns.Print(L["Changed not long ago: again in %s."], ns.Duration(Q:RerollLeft(key)))
		elseif why == "reroll" and ns.Reroll then
			ns.Reroll:SayNot("quests")
		elseif why and REROLL_WHY[why] then
			ns.Print(L[REROLL_WHY[why]])
		end
		self:PaintReroll()
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.page)
	ns.Play(ns.SND.cardFlip)
	if (why or 0) > 0 then
		ns.Play(ns.SND.coins)
	end
	-- (the page at once with its new quests: each one turns over, one after the other)
	self:Refresh()
	Hud.Burst(b.dice, ns.RubiesUI.GLOW, 16, 110, 14)
	local new = {}
	for _, c in ipairs(changed) do
		new[c.new] = true
	end
	local bd = self.frame.quests.board
	local k = 0
	for _, r in ipairs(bd.shown or {}) do
		local q = Shown(r)
		if r:IsShown() and q and new[q] then
			k = k + 1
			self:RerollFlip(r, (k - 1) * 0.05)
		end
	end
end

-- (the animations of the cards turning over: apart from those of the claims)
local FLIP = {}

-- The cards turning over, turned at once.
function A:EndFlips()
	ns.CancelOwner(FLIP)
	local bd = self.frame and self.frame.quests and self.frame.quests.board
	for _, set in ipairs(bd and { bd.cards, bd.rows } or {}) do
		for _, r in ipairs(set) do
			if r.flipping then
				r.flipping = nil
				r.icon:SetWidth(r.iconW or r.icon:GetWidth())
				r.name:SetAlpha(1)
				r.flash:SetAlpha(0)
			end
		end
	end
end

-- A card turned over to its new quest: its icon opening from its middle, its words coming back, a flash.
function A:RerollFlip(r, delay)
	local size = r.iconW or (r.compact and 28 or 44)
	r.flipping = true
	r.icon:SetWidth(0.01)
	r.name:SetAlpha(0)
	ns.Tween(0.42, function(e, raw)
		r.icon:SetWidth(math.max(0.01, size * math.max(0, e)))
		r.name:SetAlpha(math.min(1, math.max(0, e)))
		r.flash:SetAlpha(0.32 * (1 - raw))
	end, function()
		r.flipping = nil
		r.icon:SetWidth(size)
		r.name:SetAlpha(1)
		r.flash:SetAlpha(0)
	end, Ease.outBack, FLIP, delay)
end

-------------------------------------------------------------------------------
-- Tooltips
-------------------------------------------------------------------------------
-- The rewards of a quest, in words: "+200 XP", "1 booster of a zone to choose", "+25 points on the
-- booster bar".
function A:RewardLine(board, q)
	local parts = { string.format(L["+%s XP"], ns.Num(Q:XP(q))) }
	if (q.p or 0) > 0 and board.kind then
		parts[CuratorOctoFull.Length(parts) + 1] = (q.p == 1) and L[REWARD_ONE[board.kind]] or string.format(L[REWARD_MANY[board.kind]], q.p)
	end
	if (tonumber(q.pts) or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%s points on the booster bar"], ns.Num(q.pts))
	end
	-- (1.14.0: the case of the discovery of the Paladin Collection Case No. 1)
	if (tonumber(q.c) or 0) > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%d case of the Paladin Collection"], q.c)
	end
	-- (1.11.0) its rubies
	local rubies = Q:Rubies(board, q)
	if rubies > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = ns.Rubies.Gem(13) .. " " .. string.format(L["+%s rubies"], ns.Num(rubies))
	end
	return table.concat(parts, "  ·  ")
end
Q.RewardLine = function(_, board, q)
	return A:RewardLine(board, q)
end
-- (short, for the toast of a quest done: its title says the kind of its boosters)
function Q:RewardShort(board, q)
	local text = string.format(L["+%s XP"], ns.Num(Q:XP(q)))
	if (q.p or 0) > 0 and board.kind == "hallow" then
		-- (1.12.0: boosters of Hallow's End)
		text = text .. "  ·  " .. ((q.p == 1) and L["1 booster of Hallow's End"] or string.format(L["%d boosters of Hallow's End"], q.p))
	elseif (q.p or 0) > 0 and board.kind then
		text = text .. "  ·  " .. ((q.p == 1) and L["1 reward to choose"] or string.format(L["%d rewards to choose"], q.p))
	end
	if (tonumber(q.pts) or 0) > 0 then
		text = text .. "  ·  " .. string.format(L["+%s pts"], ns.Num(q.pts))
	end
	-- (1.14.0: the case of the discovery)
	if (tonumber(q.c) or 0) > 0 then
		text = text .. "  ·  " .. string.format(L["+%d case"], q.c)
	end
	-- (1.11.0) its rubies
	local rubies = Q:Rubies(board, q)
	if rubies > 0 then
		text = text .. "  ·  " .. ns.Rubies.Gem(12) .. " " .. string.format(L["+%s rubies"], ns.Num(rubies))
	end
	return text
end

-- A quest: what to do, how far, its rewards, when it ends; to claim it.
function A:QuestTooltip(r, owner)
	local q, board = Shown(r)
	if not q then
		return
	end
	GameTooltip:SetOwner(owner or r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Q:Text(q), 1, 1, 1, true)
	GameTooltip:AddLine(L[PERIOD[board.period]], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if q.claimed then
		GameTooltip:AddLine(L["Claimed"], 0.3, 1, 0.3)
	elseif q.done then
		GameTooltip:AddLine(L["Done!"], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(string.format(("%s / %s"), ns.Num(q.got or 0), ns.Num(q.n)), 0.9, 0.9, 0.9)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Rewards:"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(self:RewardLine(board, q), 1, 1, 1, true)
	local left = Q:ResetLeft(board.period)
	if left then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format((q.done and L["New quests in %s"] or L["Ends in %s"]), ns.Duration(left)), 0.8, 0.8, 0.8)
	end
	-- (1.14.0, after its test, his word: a reroll claims none, nor does any; why)
	if Locked() then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(ns.Reroll:WhyNot("quests"), 1, 0.62, 0.45, true)
	elseif q.done and not q.claimed then
		GameTooltip:AddLine(L["Click to claim"], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function A:NavTooltip(b)
	local key = b.sec.key
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L[TITLE[key]], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	local done, all = Q:Count(b.sec.boards)
	if all > 0 then
		GameTooltip:AddLine(string.format(("%d/%d"), done, all), 1, 1, 1)
	end
	local n = CuratorOctoFull.Length(Q:Claimable(key))
	if n > 0 then
		GameTooltip:AddLine(Waiting(n), 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

-- The bar of the level, in the head of the window.
function A:HeadTooltip(owner)
	local xp = LV:XP()
	local level, into, need = LV.Of(xp)
	local r, rank = LV.RankOf(level)
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(string.format(L["Collector level %d"], level), S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(LV.EmblemText(r, 16) .. " " .. L[rank.name], rank.color[1], rank.color[2], rank.color[3])
	if need then
		GameTooltip:AddLine(string.format(L["%s XP to level %d"], ns.Num(need - into), level + 1), 1, 1, 1)
	end
	GameTooltip:AddLine(string.format(L["Total: %s XP"], ns.Num(xp)), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(L["Experience comes from the boosters opened (each card by its rarity, more for its finish) and from the quests."], 0.8, 0.8, 0.8, true)
	GameTooltip:Show()
end

-- A rank (mine when none is given): its name, its levels, what the ranks are.
function A:RankTooltip(owner, r)
	r = r or (LV:Rank())
	local rank = LV.RANKS[r]
	local nx = LV.RANKS[r + 1]
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(LV.EmblemText(r, 20) .. " " .. L[rank.name], rank.color[1], rank.color[2], rank.color[3])
	if nx then
		GameTooltip:AddLine(string.format(L["Levels %d to %d"], rank.level, nx.level - 1), 1, 1, 1)
	else
		GameTooltip:AddLine(string.format(L["Level %d"], rank.level), 1, 1, 1)
	end
	GameTooltip:AddLine(L["A new rank every five levels, from copper to elementium; the legend at level 60."], 0.8, 0.8, 0.8, true)
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- From elsewhere
-------------------------------------------------------------------------------
-- The page of the quests, on a section ("progress": the track of the levels, in the profile now).
function A:ShowQuests(section)
	if section == "progress" then
		return self:ShowProfile("track")
	end
	self:Build()
	self:FinishClaims()
	if section then
		self.questSec = section
	end
	self.mode, self.member, self.memberEntries, self.returnMode = "quests", nil, nil, nil
	self:HideDetail()
	self:Reveal()
end
