local octoConstants = {}
local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
octoConstants.MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local C = ns.Collection
local I = ns.Inns
local A = ns.Album

-------------------------------------------------------------------------------
-- (1.8.0) The inns on the screen (Inns.lua): the lines of Curator in the window of the innkeepers, the
-- loyalty card at the counter (a window beside theirs: its stamps, the one of the day coming down), the
-- signed card of a friend of the house, and the page of the album "Inns": the card, the passport (a
-- stamp for each inn visited, continent by continent), the loyalty of each innkeeper. (1.14.0, after its test, his
-- word: the innkeeper redone) The counter opens with his window: his dish of the day on its slate, the card and its
-- stamp, his rumor (a lead), his bet; the page shows the rest, the dish under way and the leads too (UI/Lodging.lua:
-- on the booster bar and the screen).
-------------------------------------------------------------------------------
local UI = {}
ns.InnsUI = UI

-- the ink of a stamp: blue for the inns of the Alliance, red for the Horde's, green for the others
octoConstants.INK = { A = { 0.17, 0.30, 0.66 }, H = { 0.66, 0.15, 0.12 }, N = { 0.16, 0.44, 0.24 }, ["?"] = { 0.42, 0.24, 0.56 } }
octoConstants.GOLD = { 1, 0.82, 0 }
octoConstants.BROWN = { 0.36, 0.22, 0.09 }
octoConstants.PAPER_INK = { 0.30, 0.19, 0.08 }

local function InkOf(npc)
	local d = ns.INNKEEPERS and ns.INNKEEPERS[npc]
	return octoConstants.INK[(d and d[2]) or "?"]
end

-- the languages whose letters the font of the titles has
octoConstants.FANCY = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }
local function Fancy(fs, size, flags)
	local loc = ns.locale or (GetLocale and GetLocale()) or "enUS"
	if octoConstants.FANCY[loc] then
		fs:SetFont("Fonts\\MORPHEUS.TTF", size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
end

local function Text(parent, size, color, justify, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	ns.SetFont(fs, size)
	if color then
		fs:SetTextColor(color[1], color[2], color[3])
	end
	fs:SetJustifyH(justify or "CENTER")
	return fs
end

-- A text in the colour of a rarity.
local function Colored(text, r)
	local x = ns.RARITY[r]
	local c = x and x.text or { 1, 1, 1 }
	return string.format(("|cff%02x%02x%02x%s|r"), math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), text)
end

-- The day of a stamp, short (the day and the month, as the language writes them).
local function Day(t)
	if not t then
		return ""
	end
	local ok, s = pcall(date, L["%m/%d"], t)
	return ok and s or ""
end

local function DayLong(t)
	if not t then
		return ""
	end
	local ok, s = pcall(date, L["%m/%d/%Y"], t)
	return ok and s or ""
end

-- A stamp is never put quite straight: a small turn of its own (the same each time it is drawn).
local function Turn(npc, t)
	local seed = CuratorOctoFull.Mod(((npc or 1) * 7919 + (t or 0) * 31) , 1000)
	return (seed / 1000 - 0.5) * 0.5
end

-------------------------------------------------------------------------------
-- A stamp: its place on the paper (dashes), and the ink of an inn (its ring, the mark of its album, its
-- day). stamp:Paint(npc, t) (nil: the empty place), stamp:Press(npc, t, delay, land).
-------------------------------------------------------------------------------
function UI.NewStamp(parent, size, withDay)
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, size, size)
	f.slot = f:CreateTexture(nil, "ARTWORK")
	f.slot:SetAllPoints()
	f.slot:SetTexture(octoConstants.MEDIA .. "StampSlot")
	f.slot:SetVertexColor(octoConstants.BROWN[1], octoConstants.BROWN[2], octoConstants.BROWN[3], 0.5)
	-- (the prize of the last place of a card: the booster it brings, faint in its circle)
	f.prize = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.prize:SetPoint("CENTER")
	CuratorOctoFull.SetSize(f.prize, size * 0.42, size * 0.62)
	f.prize:SetAlpha(0.3)
	f.prize:Hide()
	local ink = CreateFrame("Frame", nil, f)
	ink:SetPoint("CENTER")
	CuratorOctoFull.SetSize(ink, size, size)
	f.ink = ink
	ink.ring = ink:CreateTexture(nil, "ARTWORK", nil, 2)
	ink.ring:SetAllPoints()
	ink.ring:SetTexture(octoConstants.MEDIA .. "StampRing")
	ink.mark = ink:CreateTexture(nil, "ARTWORK", nil, 3)
	ink.mark:SetPoint("CENTER", 0, withDay and size * 0.05 or 0)
	CuratorOctoFull.SetSize(ink.mark, size * 0.48, size * 0.48)
	if withDay then
		ink.day = ink:CreateFontString(nil, "OVERLAY")
		ns.SetFont(ink.day, math.max(6.5, size * 0.13), "")
		ink.day:SetPoint("CENTER", 0, -size * 0.27)
	end
	ink:Hide()
	function f:Paint(npc, t)
		self.npc, self.t = npc, t
		if not npc then
			ink:Hide()
			self.slot:Show()
			return
		end
		local c = InkOf(npc)
		local album = I:Album(npc)
		ink.ring:SetVertexColor(c[1], c[2], c[3], 0.9)
		ink.mark:SetTexture(octoConstants.MEDIA .. ((album and album.set) or "SetElwynn"))
		if ink.mark.SetDesaturated then
			CuratorOctoFull.SetDesaturated(ink.mark, true)
		end
		ink.mark:SetVertexColor(c[1] * 1.3, c[2] * 1.3, c[3] * 1.3, 0.85)
		local a = Turn(npc, t)
		if ink.ring.SetRotation then
			CuratorOctoFull.SetRotation(ink.ring, a)
			CuratorOctoFull.SetRotation(ink.mark, a)
		end
		if ink.day then
			ink.day:SetText(Day(t))
			ink.day:SetTextColor(c[1], c[2], c[3], 0.95)
		end
		ink:SetScale(1)
		ink:SetAlpha(1)
		ink:Show()
		self.slot:Hide()
	end
	-- The stamp of the day comes down: big and clear, then on the paper with a thud (land()).
	function f:Press(npc, t, delay, land, owner)
		self:Paint(npc, t)
		self.slot:Show()
		ink:SetAlpha(0)
		ink:SetScale(2.6)
		ns.Tween(0.28, function(e, raw)
			ink:SetScale(2.6 - 1.6 * e)
			ink:SetAlpha(math.min(1, raw * 3))
		end, function()
			ink:SetScale(1)
			ink:SetAlpha(1)
			self.slot:Hide()
			ns.Play(ns.SND.stamp)
			if Hud and Hud.Burst then
				local c = InkOf(npc)
				Hud.Burst(self, { c[1] + 0.3, c[2] + 0.3, c[3] + 0.3 }, 10, 70, 10)
			end
			if land then
				land()
			end
		end, ns.Ease and ns.Ease.inQuad, owner or self, delay)
	end
	f:EnableMouse(true)
	CuratorOctoFull.SetScript(f, "OnEnter", function(self)
		if not self.npc then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(I:Place(self.npc), 1, 0.82, 0)
		GameTooltip:AddLine(I:Name(self.npc), 1, 1, 1)
		if self.t then
			GameTooltip:AddLine(DayLong(self.t), 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return f
end

-------------------------------------------------------------------------------
-- The loyalty card: its paper, its title, its seven places. card:Paint(stamps, prizeSeries).
-------------------------------------------------------------------------------
function UI.NewLoyaltyCard(parent, w)
	local h = w / 2
	local c = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(c, w, h)
	c.bg = c:CreateTexture(nil, "BACKGROUND")
	c.bg:SetAllPoints()
	c.bg:SetTexture(octoConstants.MEDIA .. "InnCard")
	c.title = c:CreateFontString(nil, "OVERLAY")
	Fancy(c.title, math.max(11, w * 0.052))
	c.title:SetPoint("CENTER", c, "TOP", 0, -h * 0.17)
	c.title:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3])
	c.title:SetText(L["Loyalty card"])
	c.sub = c:CreateFontString(nil, "OVERLAY")
	ns.SetFont(c.sub, math.max(8, w * 0.026))
	c.sub:SetPoint("CENTER", c, "TOP", 0, -h * 0.33)
	c.sub:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.85)
	c.sub:SetText(L["Inns of Azeroth"])
	-- the seven places, in a row
	local n = I.CARD
	local inner = w * 0.86
	local step = inner / n
	local size = math.min(step * 0.94, h * 0.36)
	c.slots = {}
	for i = 1, n do
		local st = UI.NewStamp(c, size, w >= 300)
		st:SetPoint("CENTER", c, "TOPLEFT", w * 0.07 + step * (i - 0.5), -h * 0.58)
		c.slots[i] = st
	end
	c.foot = c:CreateFontString(nil, "OVERLAY")
	ns.SetFont(c.foot, math.max(7.5, w * 0.024))
	c.foot:SetPoint("CENTER", c, "BOTTOM", 0, h * 0.16)
	c.foot:SetWidth(w * 0.82)
	c.foot:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.9)
	-- the card full: its light
	c.glow = c:CreateTexture(nil, "OVERLAY", nil, 6)
	c.glow:SetPoint("TOPLEFT", -w * 0.06, h * 0.12)
	c.glow:SetPoint("BOTTOMRIGHT", w * 0.06, -h * 0.12)
	c.glow:SetTexture(octoConstants.MEDIA .. "CardGlow")
	c.glow:SetBlendMode("ADD")
	c.glow:SetVertexColor(1, 0.8, 0.35)
	c.glow:SetAlpha(0)
	function c:Paint(stamps, prize, upto)
		upto = upto or CuratorOctoFull.Length(stamps)
		for i, st in ipairs(self.slots) do
			local x = i <= upto and stamps[i] or nil
			st:Paint(x and x.n, x and x.t)
			st.prize:Hide()
		end
		-- the last place shows the booster it brings
		local last = self.slots[n]
		if not last.npc and prize and prize.pack then
			last.prize:SetTexture(octoConstants.MEDIA .. prize.pack .. "Top")
			last.prize:Show()
		end
		local left = n - upto
		if left > 0 then
			if prize then
				-- (one more: its line has the album alone; in game it said "a booster of 1")
				if left == 1 then
					self.foot:SetText(string.format(L["One more stamp: a booster of %s."], C:SeriesName(prize)))
				else
					self.foot:SetText(string.format(L["%d more stamps: a booster of %s."], left, C:SeriesName(prize)))
				end
			else
				self.foot:SetText(string.format((left == 1 and L["One more stamp: a reward to choose."] or L["%d more stamps: a reward to choose."]), left))
			end
		else
			self.foot:SetText(L["Card full!"])
		end
	end
	return c
end

-------------------------------------------------------------------------------
-- At the counter (1.14.0, after its test, his word: the innkeeper redone): a window beside the innkeeper's, open with
-- it, as one leans on his counter: the innkeeper and his loyalty, his dish of the day on its slate (offered with the
-- stamp of the day; Lodging.lua), the loyalty card and its stamp, his rumor (a lead; Tavern.lua) and his bet. Before
-- 1.14.0: the loyalty card alone, open from the line of the stamp.
-------------------------------------------------------------------------------
local PW, PH = 460, 690
octoConstants.SLATE_W, octoConstants.SLATE_H = 416, 160
octoConstants.CARD_W = 400
octoConstants.CHALK = { 0.96, 0.94, 0.86 }
octoConstants.GREEN = { 0.45, 1, 0.45 }
octoConstants.GREY = { 0.62, 0.62, 0.62 }
octoConstants.ICON = {
	rumor = "Interface\\GossipFrame\\GossipGossipIcon",
	bet = "Interface\\Icons\\INV_Misc_Coin_02",
	round = "Interface\\Icons\\INV_Drink_04",
	lead = "Interface\\Icons\\Ability_Tracking",
	rest = "Interface\\Icons\\Spell_Nature_Sleep",
}
UI.ICON = octoConstants.ICON

-- A row of the counter: its icon, its line, its button.
local function Row(parent, w)
	local r = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(r, w, 36)
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(r.bg, 0, 0, 0, 0.32)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, 24, 24)
	r.icon:SetPoint("LEFT", 8, 0)
	r.text = Text(r, 11.5, { 0.9, 0.9, 0.86 }, "LEFT")
	r.text:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
	CuratorOctoFull.SetWordWrap(r.text, true)
	if r.text.SetMaxLines then
		CuratorOctoFull.SetMaxLines(r.text, 2)
	end
	r.button = S.Button(r, "", 120, 22)
	r.button:SetPoint("RIGHT", -6, 0)
	r.text:SetPoint("RIGHT", r.button, "LEFT", -8, 0)
	return r
end

function UI:Panel()
	if self.panel then
		return self.panel
	end
	local f = S.Window("CuratorInnCard", PW, PH)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	-- (690 high beside the innkeeper's window: on a small screen, or a large scale of the interface, it stays on it)
	CuratorOctoFull.SetClampedToScreen(f, true)
	f:Hide()
	-- (1.12.0: the time of the next stamp, kept up to date while the window is open; 1.14.0: the time of the dish too)
	f.tick = 0
	CuratorOctoFull.HookScript(f, "OnUpdate", function(self, elapsed)
		self.tick = self.tick + elapsed
		if self.tick >= 10 then
			self.tick = 0
			if self.npc and not self.busy then
				UI:PaintDish(self.npc)
				UI:PaintLine2(self.npc)
			end
		end
	end)
	tinsert(UISpecialFrames, "CuratorInnCard")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(octoConstants.MEDIA .. "Icon")
	end
	if f.SetTitle then
		f:SetTitle(L["At the counter"])
	end
	CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
		f:Hide()
	end)
	f.drag = S.DragBar(f, 22)
	-- the innkeeper, his loyalty
	f.who = Text(f, 15, octoConstants.GOLD, "LEFT")
	f.who:SetPoint("TOPLEFT", 24, -64)
	f.who:SetPoint("RIGHT", -170, 0)
	CuratorOctoFull.SetWordWrap(f.who, false)
	f.rank = Text(f, 12, { 1, 1, 1 }, "RIGHT")
	f.rank:SetPoint("TOPRIGHT", -24, -66)
	-- (the home inn: its hearthstone beside the rank)
	f.home = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.home, 18, 18)
	f.home:SetPoint("RIGHT", f.rank, "LEFT", -6, 0)
	f.home.icon = f.home:CreateTexture(nil, "ARTWORK")
	f.home.icon:SetAllPoints()
	f.home.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
	f.home.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.home:EnableMouse(true)
	CuratorOctoFull.SetScript(f.home, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Your home inn"], 1, 0.82, 0)
		GameTooltip:AddLine(L["Your loyalty counts double here."], 1, 1, 1)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.home, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.home:Hide()
	f.bar = S.ThinBar(f, PW - 48, 8, { 0.85, 0.6, 0.15 })
	f.bar:SetPoint("TOPLEFT", 24, -86)
	f.line = Text(f, 11, { 0.85, 0.85, 0.85 }, "LEFT")
	f.line:SetPoint("TOPLEFT", 24, -100)
	f.line:SetPoint("RIGHT", -24, 0)
	CuratorOctoFull.SetWordWrap(f.line, false)
	-- his dish of the day, on its slate
	local sl = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(sl, octoConstants.SLATE_W, octoConstants.SLATE_H)
	sl:SetPoint("TOP", 0, -120)
	sl.bg = sl:CreateTexture(nil, "BACKGROUND")
	sl.bg:SetAllPoints()
	sl.bg:SetTexture(octoConstants.MEDIA .. "InnSlate")
	-- (the slate is the top of its texture, 512 x 197 of 512 x 256)
	sl.bg:SetTexCoord(0, 1, 0, 197 / 256)
	sl.title = sl:CreateFontString(nil, "OVERLAY")
	Fancy(sl.title, 17)
	sl.title:SetPoint("TOP", 0, -21)
	sl.title:SetTextColor(octoConstants.CHALK[1], octoConstants.CHALK[2], octoConstants.CHALK[3])
	sl.glow = sl:CreateTexture(nil, "ARTWORK")
	sl.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	sl.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(sl.glow, 110, 110)
	sl.glow:SetPoint("CENTER", sl, "TOPLEFT", 62, -94)
	sl.glow:SetVertexColor(1, 0.8, 0.45)
	sl.glow:SetAlpha(0.35)
	sl.icon = Hud.RoundIcon(sl, 54, "ARTWORK", 2)
	sl.icon:SetPoint("CENTER", sl, "TOPLEFT", 62, -94)
	sl.ring = sl:CreateTexture(nil, "OVERLAY")
	sl.ring:SetTexture(octoConstants.MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(sl.ring, 66, 66)
	sl.ring:SetPoint("CENTER", sl.icon, "CENTER")
	sl.name = Text(sl, 15, { 1, 0.86, 0.55 }, "LEFT")
	sl.name:SetPoint("TOPLEFT", 106, -45)
	sl.name:SetWidth(octoConstants.SLATE_W - 126)
	CuratorOctoFull.SetWordWrap(sl.name, false)
	sl.text = Text(sl, 11.5, octoConstants.CHALK, "LEFT")
	sl.text:SetPoint("TOPLEFT", sl.name, "BOTTOMLEFT", 0, -3)
	sl.text:SetWidth(octoConstants.SLATE_W - 126)
	CuratorOctoFull.SetWordWrap(sl.text, true)
	if sl.text.SetMaxLines then
		CuratorOctoFull.SetMaxLines(sl.text, 2)
	end
	sl.time = Text(sl, 11, octoConstants.GREEN, "LEFT")
	sl.time:SetPoint("TOPLEFT", sl.text, "BOTTOMLEFT", 0, -4)
	sl.time:SetWidth(octoConstants.SLATE_W - 126)
	CuratorOctoFull.SetWordWrap(sl.time, true)
	-- (three lines: the languages that say it longer)
	if sl.time.SetMaxLines then
		CuratorOctoFull.SetMaxLines(sl.time, 3)
	end
	sl:EnableMouse(true)
	CuratorOctoFull.SetScript(sl, "OnEnter", function(self)
		UI:DishTooltip(self, f.npc)
	end)
	CuratorOctoFull.SetScript(sl, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.slate = sl
	-- the loyalty card, its stamp
	f.card = UI.NewLoyaltyCard(f, octoConstants.CARD_W)
	f.card:SetPoint("TOP", 0, -290)
	f.stamp = S.Button(f, L["Stamp my loyalty card"], 340, 28)
	f.stamp:SetPoint("TOP", f.card, "BOTTOM", 0, -8)
	CuratorOctoFull.SetScript(f.stamp, "OnClick", function()
		if f.npc then
			UI:Open(f.npc, true)
		end
	end)
	f.line2 = Text(f, 11, octoConstants.GREY, "CENTER")
	f.line2:SetPoint("TOP", f.stamp, "BOTTOM", 0, -6)
	f.line2:SetWidth(PW - 48)
	CuratorOctoFull.SetWordWrap(f.line2, false)
	-- his rumor (a lead), his bet
	f.rumor = Row(f, PW - 44)
	f.rumor:SetHeight(54)
	f.rumor:SetPoint("TOP", 0, -560)
	f.rumor.button:ClearAllPoints()
	f.rumor.button:SetPoint("TOPRIGHT", -6, -5)
	f.rumor.text:ClearAllPoints()
	f.rumor.text:SetPoint("LEFT", f.rumor.icon, "RIGHT", 8, 0)
	f.rumor.text:SetPoint("RIGHT", f.rumor, "RIGHT", -134, 0)
	if f.rumor.text.SetMaxLines then
		CuratorOctoFull.SetMaxLines(f.rumor.text, 3)
	end
	f.rumor.icon:SetTexture(octoConstants.ICON.rumor)
	CuratorOctoFull.SetScript(f.rumor.button, "OnClick", function()
		if f.npc and ns.TavernUI then
			ns.Play(ns.SND.click)
			ns.TavernUI:Rumor(f.npc)
			UI:PaintRows(f.npc)
		end
	end)
	f.rumor.buy = S.Button(f.rumor, "", 120, 20)
	f.rumor.buy:SetPoint("TOPRIGHT", f.rumor.button, "BOTTOMRIGHT", 0, -3)
	CuratorOctoFull.SetScript(f.rumor.buy, "OnClick", function()
		if f.npc and ns.TavernUI then
			ns.Play(ns.SND.click)
			ns.TavernUI:BuyRumor(f.npc)
		end
	end)
	f.bet = Row(f, PW - 44)
	f.bet:SetPoint("TOP", f.rumor, "BOTTOM", 0, -8)
	f.bet.icon:SetTexture(octoConstants.ICON.bet)
	f.bet.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetScript(f.bet.button, "OnClick", function()
		if f.npc and ns.TavernUI then
			ns.Play(ns.SND.click)
			ns.TavernUI:OpenBet(f.npc)
		end
	end)
	-- the round of the innkeeper: a banner over the slate, a moment
	f.round = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.round, octoConstants.SLATE_W, 30)
	f.round:SetPoint("BOTTOM", sl, "TOP", 0, -2)
	f.round:SetFrameLevel(sl:GetFrameLevel() + 6)
	f.round.bg = f.round:CreateTexture(nil, "BACKGROUND")
	f.round.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.round.bg, 0.25, 0.14, 0.02, 0.92)
	f.round.icon = f.round:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.round.icon, 22, 22)
	f.round.icon:SetPoint("LEFT", 6, 0)
	f.round.icon:SetTexture(octoConstants.ICON.round)
	f.round.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.round.text = Text(f.round, 12, octoConstants.GOLD, "LEFT")
	f.round.text:SetPoint("LEFT", f.round.icon, "RIGHT", 6, 0)
	f.round.text:SetPoint("RIGHT", -6, 0)
	CuratorOctoFull.SetWordWrap(f.round.text, false)
	f.round:Hide()
	-- the signed card of a friend of the house: beside the window, written as one watches
	local gift = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(gift, 200, 300)
	gift:SetPoint("TOPLEFT", f, "TOPRIGHT", 10, -24)
	gift.title = gift:CreateFontString(nil, "OVERLAY")
	Fancy(gift.title, 18, "OUTLINE")
	gift.title:SetPoint("TOP", 0, 0)
	gift.title:SetTextColor(1, 0.86, 0.5)
	gift.title:SetText(L["Signed card!"])
	gift.card = ns.NewCard(gift, "big")
	gift.card:SetPoint("TOP", 0, -26)
	CuratorOctoFull.SetScript(gift, "OnUpdate", function(_, elapsed)
		UI.t = (UI.t or 0) + elapsed
		if gift.card.Tick then
			gift.card:Tick(UI.t)
		end
	end)
	gift:Hide()
	f.gift = gift
	CuratorOctoFull.SetScript(f, "OnHide", function()
		ns.CancelOwner(UI)
		gift:Hide()
		f.busy = nil
	end)
	self.panel = f
	return f
end

-- The window beside the innkeeper's (or in the middle of the screen).
local function Place(f)
	f:ClearAllPoints()
	local g = rawget(_G, "GossipFrame")
	local fb = ns.Gossip and ns.Gossip.panel
	if g and g.IsShown and g:IsShown() then
		f:SetPoint("TOPLEFT", g, "TOPRIGHT", 14, 0)
	elseif fb and fb.IsShown and fb:IsShown() then
		f:SetPoint("TOPLEFT", fb, "TOPRIGHT", 14, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 120, 40)
	end
end
UI.Place = Place

-- The time of a dish, by the ranks of loyalty (its tooltip).
function UI:DishTooltip(owner, npc)
	local LG = ns.Lodging
	if not (LG and npc) then
		return
	end
	local def = LG:DishOf(npc)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(LG:Name(def), 1, 0.86, 0.55)
	GameTooltip:AddLine(LG:Text(def), 1, 1, 1, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Offered with the stamp of the day, one dish a day. It lasts while you play (not on a reroll), longer as his loyalty grows:"], 0.8, 0.8, 0.8, true)
	local _, r = I:Loyalty(npc)
	for i, x in ipairs(I.RANKS) do
		local on = math.max(1, r) == i
		GameTooltip:AddDoubleLine(I:RankName(i), LG.Duration(LG.DISH_TIME[i]), on and 1 or 0.7, on and 0.82 or 0.7, on and 0 or 0.7, 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Never on a boss, a mythic card or an event card. A new dish takes the place of the one before (the same dish: its time is added)."], 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

-- (1.14.0) What the dishes of the day are (the page of the inns, no dish under way): how they come, how long they last,
-- the five of them.
function UI:DishesTooltip(owner)
	local LG = ns.Lodging
	if not LG then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(L["Dish of the day"], 1, 0.86, 0.55)
	GameTooltip:AddLine(L["Offered with the stamp of the day, one dish a day. It lasts while you play (not on a reroll), longer as his loyalty grows:"], 0.8, 0.8, 0.8, true)
	for i in ipairs(I.RANKS) do
		GameTooltip:AddDoubleLine(I:RankName(i), LG.Duration(LG.DISH_TIME[i]), 0.7, 0.7, 0.7, 1, 1, 1)
	end
	for _, def in ipairs(LG.DISHES) do
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LG:Name(def), 1, 0.86, 0.55)
		GameTooltip:AddLine(LG:Text(def), 1, 1, 1, true)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Never on a boss, a mythic card or an event card. A new dish takes the place of the one before (the same dish: its time is added)."], 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

-- (1.14.0) What the leads of the tavern are (the page of the inns).
function UI:LeadsTooltip(owner)
	local T = ns.Tavern
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(L["Leads of the tavern"], 0.55, 1, 0.5)
	GameTooltip:AddLine(L["The rumors of the innkeepers you are a regular of: their card three times as easy to find, for days."], 1, 1, 1, true)
	if T and T.ROUND then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format(L["Found on its creature: the innkeeper owes you a round (%s XP, %s rubies), at the next one you talk to."], ns.Num(T.ROUND.xp), ns.Num(T.ROUND.rubies)), 0.8, 0.8, 0.8, true)
	end
	GameTooltip:Show()
end

-- His dish of the day, on the slate: the one he serves (offered with the stamp), or the one taken today.
function UI:PaintDish(npc)
	local f = self:Panel()
	local sl = f.slate
	local LG = ns.Lodging
	if not LG then
		sl:Hide()
		return
	end
	sl:Show()
	local def = LG:DishOf(npc)
	local cur, left, from, waiting = LG:Dish()
	if LG:TakenToday() then
		local shown = cur or def
		sl.title:SetText(cur and L["Your dish of the day"] or L["Dish of the day"])
		Hud.SetIcon(sl.icon, { LG:Icon(shown) })
		CuratorOctoFull.SetDesaturated(sl.icon, cur == nil or waiting)
		sl.glow:SetAlpha(cur and not waiting and 0.4 or 0)
		S.Fit(sl.name, LG:Name(shown), octoConstants.SLATE_W - 126, 15, 10)
		sl.text:SetText(LG:Text(shown))
		if cur and waiting then
			sl.time:SetTextColor(1, 0.82, 0.36)
			sl.time:SetText(string.format(L["It waits: you are playing a reroll (%s left)."], LG.Duration(left)))
		elseif cur then
			sl.time:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
			local who = from and from ~= npc and (" " .. string.format(L["(served by %s)"], I:Name(from))) or ""
			sl.time:SetText(string.format(L["%s left, while you play."], LG.Duration(left)) .. who)
		else
			sl.time:SetTextColor(octoConstants.GREY[1], octoConstants.GREY[2], octoConstants.GREY[3])
			sl.time:SetText(string.format(L["Your dish of today is eaten. The next one comes with tomorrow's stamp (in %s)."], ns.Duration(I:NextIn())))
		end
		return
	end
	sl.title:SetText(L["Dish of the day"])
	Hud.SetIcon(sl.icon, { LG:Icon(def) })
	CuratorOctoFull.SetDesaturated(sl.icon, false)
	sl.glow:SetAlpha(0.35)
	S.Fit(sl.name, LG:Name(def), octoConstants.SLATE_W - 126, 15, 10)
	sl.text:SetText(LG:Text(def))
	sl.time:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	local _, r = I:Loyalty(npc)
	local after = math.max(1, r)
	local t = string.format(L["Offered with your stamp: %s (%s)."], LG.Duration(LG:DishTime(npc)), I:RankName(after) or "")
	if cur and cur.key == def.key then
		t = t .. " " .. L["Added to what is left of yours."]
	elseif cur then
		t = t .. " " .. string.format(L["In the place of your %s."], LG:Name(cur))
	end
	sl.time:SetText(t)
end

-- What the window says of an innkeeper: his name, the loyalty, his dish, the day's stamp, his rumor, his bet.
function UI:PaintPanel(npc, stamps, upto)
	local f = self:Panel()
	stamps = stamps or I:CardStamps()
	f.card:Paint(stamps, I:Prize(npc), upto)
	local n, r, nextAt = I:Loyalty(npc)
	S.Fit(f.who, I:Name(npc), PW - 200, 15, 10)
	f.rank:SetText(r > 0 and I:RankName(r) or L["Not a guest yet"])
	CuratorOctoFull.SetShown(f.home, ns.Tavern ~= nil and ns.Tavern:IsHome(npc))
	local lo = r > 0 and I.RANKS[r].n or 0
	f.bar:SetProgress(nextAt and (n - lo) / (nextAt - lo) or 1)
	if nextAt and n == 1 then
		f.line:SetText(string.format(L["Loyalty: one stamp here. %s at %d."], I:RankName(r + 1), nextAt))
	elseif nextAt and n > 0 then
		f.line:SetText(string.format(L["Loyalty: %d stamps here. %s at %d."], n, I:RankName(r + 1), nextAt))
	elseif nextAt then
		f.line:SetText(L["Your first stamp here makes you a passing guest."])
	else
		f.line:SetText(string.format(L["Loyalty: %d stamps here. You are a friend of the house."], n))
	end
	f.npc = npc
	self:PaintDish(npc)
	self:PaintLine2(npc)
	self:PaintRows(npc)
end

-- (1.12.0) The line of the day's stamp and the visa; (1.14.0) the button of the stamp, with his dish.
function UI:PaintLine2(npc)
	local f = self:Panel()
	local s = I:State()
	local v = s and s.visas[npc]
	if I:StampedToday() then
		-- (1.12.0: when the next one comes, at 5:00 in Paris)
		f.stamp:SetLabel(L["Today's stamp: taken"])
		f.stamp:Disable()
		f.line2:SetText(string.format(L["The next one in %s."], ns.Duration(I:NextIn()))
			.. (type(v) == "table" and ("  ·  " .. string.format(L["Visa: %s"], DayLong(v.t))) or ""))
	else
		local party = ns.Tavern and ns.Tavern:Party()
		f.stamp:SetLabel(party and L["Stamp my card (double stamp tonight!)"] or L["Stamp my loyalty card"])
		f.stamp:Enable()
		f.line2:SetText(type(v) == "table" and string.format(L["Visa: %s"], DayLong(v.t)) or L["Your visa of this inn comes with your first visit."])
	end
	f.npc = npc
end

-- His rumor (a lead) and his bet.
function UI:PaintRows(npc)
	local f = self:Panel()
	local T = ns.Tavern
	local album = I:Album(npc)
	local ro, be = f.rumor, f.bet
	if not (T and album) then
		ro.text:SetText(L["Curator knows no album for this inn: no rumor, no bet here. The stamp and the dish, yes."])
		ro.button:Hide()
		ro.buy:Hide()
		be:Hide()
		return
	end
	be:Show()
	local card, why = T:Rumor(npc)
	ro.button:Show()
	if why == "rank" then
		ro.text:SetText(string.format(L["At %d stamps here you are a regular: he tells you his rumor of the day."], I.RANKS[T.RUMOR_RANK].n))
		ro.button:Hide()
	elseif card and why == true then
		local l = T:Lead(card)
		local k = (card.rarity or 0) >= 6 and T.RUMOR_FIND_MYTHIC or T:RumorFind()
		local more = l and string.format(L["A lead: %d times as easy to find, %s left."], k, ns.Duration(math.max(0, (tonumber(l.u) or 0) - ((GetServerTime and CuratorOctoFull.ServerTime()) or time())))) or L["Already found: no lead left."]
		ro.text:SetText(string.format(L["His rumor: %s"], Colored(C:Name(card), card.rarity)) .. "\n" .. more)
		ro.button:SetLabel(L["Hear it again"])
	elseif card then
		ro.text:SetText(L["He leans over the counter: he has heard something today."])
		ro.button:SetLabel(L["Any rumors?"])
	else
		ro.text:SetText(L["Nothing new around here today."])
		ro.button:Hide()
	end
	-- (1.11.0) a rumor bought: the creature chosen
	local bought = T:BoughtCard(npc)
	ro.buy:Show()
	if bought then
		ro.buy:SetLabel(L["Bought today"])
		ro.buy:Disable()
	else
		local price = T:RumorPrice()
		ro.buy:SetLabel(string.format(L["Buy one (%s)"], price > 0 and ns.Rubies.Text(price, 11) or L["Free"]))
		ro.buy:Enable()
	end
	-- his bet
	if T:Deal() then
		be.text:SetText(L["Your stake is on his table: your cards are waiting for you."])
		be.button:SetLabel(L["Back to the table"])
		be.button:Enable()
	elseif T:BetToday() then
		be.text:SetText(string.format(L["Your bet of today is played. The next one in %s."], ns.Duration(I:NextIn())))
		be.button:SetLabel(L["The innkeeper's bet"])
		be.button:Disable()
	else
		-- (the duplicates of a bet, the cards of the innkeeper: High Table and Small Stake, talents of the Gambler, change them)
		local TL = ns.Talents
		local m = T:StakeCount()
		local cards = T.BET_CARDS + ((TL and TL:Has("lowstake")) and 1 or 0)
		be.text:SetText(m == 1 and string.format(L["One duplicate against %d cards, shuffled before your eyes."], cards)
			or string.format(L["%d duplicates against %d cards, shuffled before your eyes."], m, cards))
		be.button:SetLabel(L["Play the bet"])
		be.button:Enable()
	end
end

-- (1.14.0) The round the innkeeper just paid (Tavern.lua: T:PayRound): a banner over his slate.
function UI:ShowRound(res)
	local f = self:Panel()
	if not (res and f:IsShown()) then
		return
	end
	local what = res.n == 1 and L["The round is on him: your lead paid off!"] or string.format(L["The round is on him: %d leads paid off!"], res.n)
	-- (smaller when the language says it longer: its XP and its rubies always seen)
	S.Fit(f.round.text, what .. "  " .. string.format(L["+%s XP"], ns.Num(res.xp)) .. "  " .. ns.Rubies.Text(res.rubies, 12), octoConstants.SLATE_W - 46, 12, 8.5)
	f.round:SetAlpha(0)
	f.round:Show()
	ns.Play(ns.SND.coins)
	ns.Tween(0.4, function(e)
		f.round:SetAlpha(e)
	end, nil, nil, UI)
	ns.Delay(9, function()
		ns.Tween(0.6, function(e)
			f.round:SetAlpha(1 - e)
		end, function()
			f.round:Hide()
		end, nil, UI)
	end, UI)
end

-- The window of the card, for this innkeeper (stamp: the stamp of the day comes down now).
-- The window made ready beside the innkeeper's (the windows of the tavern placed beside it: UI/Tavern.lua).
local function Ready(self)
	local f = self:Panel()
	f.gift:Hide()
	f.card.glow:SetAlpha(0)
	if not f:IsShown() then
		ns.CancelOwner(UI)
		Place(f)
	end
	if f.SetPortraitToUnit then
		pcall(f.SetPortraitToUnit, f, "npc")
	end
	return f
end

-- Stamps just put on the card (res: Inns:Stamp, Inns:BonusStamp): the card as it was, then they come down.
local function Show(self, f, npc, res)
	local old = res.complete and res.complete.stamps or I:CardStamps()
	self:PaintPanel(npc, old, res.at)
	f.busy = true
	if not f:IsShown() then
		f:Show()
		ns.Play(ns.SND.open)
	end
	self:Pressed(f, npc, res, old)
end

-- The counter of this innkeeper (stamp: the stamp of the day now; quiet: open with his window, nothing said).
function UI:Open(npc, stamp, quiet)
	local f = Ready(self)
	local res, why
	if stamp then
		res, why = I:Stamp(npc)
	end
	if res then
		Show(self, f, npc, res)
	else
		self:PaintPanel(npc)
		if not f:IsShown() then
			f:Show()
			ns.Play(quiet and ns.SND.page or ns.SND.open)
		end
		-- (1.14.0: the round he just paid, over his slate)
		if self.pendingRound then
			local round = self.pendingRound
			self.pendingRound = nil
			self:ShowRound(round)
		end
		if not quiet and (why == "done" or (not stamp and I:StampedToday())) and ns.Gossip then
			ns.Gossip:Say(string.format(L["You already have your stamp for today. Come back in %s!"], ns.Duration(I:NextIn())))
		end
	end
	return res
end

-- A stamp more on the card (a toast: Tavern.lua), shown at the counter.
function UI:ShowBonus(npc, res)
	Show(self, Ready(self), npc, res)
end

-- What the innkeeper says of the stamps just taken (a toast: his toast first); (1.14.0) and of his dish.
local function Answer(res)
	local say
	if res.complete then
		local s = res.complete.series
		say = s and string.format(L["Your card is full! Here is a booster of %s, from the house."], C:SeriesName(s))
			or L["Your card is full! Here is a booster, from the house."]
	elseif res.up then
		say = string.format(L["Look at you: %s!"], I:RankName(res.after))
	elseif not res.bonus then
		local left = I.CARD - CuratorOctoFull.Length(I:CardStamps())
		say = left == 1 and L["One more stamp! One more and the house offers you a booster."]
			or string.format(L["One more stamp! %d more and the house offers you a booster."], left)
	end
	if res.signed then
		say = L["For a friend of the house... I sign my card for you."]
	end
	if res.bonus then
		say = L["To your health, both of you! A stamp more on your card."] .. (say and (" " .. say) or "")
	end
	if res.party then
		say = L["Evening at the inn: double stamp!"] .. " " .. say
	end
	local d = res.dish
	local LG = ns.Lodging
	if d and d.def and LG then
		say = (say and (say .. " ") or "") .. string.format(L["And here is my dish of the day: %s. Enjoy!"], LG:Name(d.def))
	end
	return say
end
UI.Answer = Answer

-- The stamps of the day come down, one after the other (two on the evening at the inn), then what they
-- brought: the card full (its light, its booster flying out, a new card), a new rank, the signed card; (1.14.0) his
-- dish, served on its slate.
function UI:Pressed(f, npc, res, old)
	local CARD = I.CARD
	local k = 0
	local delay = 0.35
	local function After()
		f.busy = nil
		if ns.Gossip then
			ns.Gossip:Say(Answer(res))
		end
		self:PaintDish(npc)
		self:PaintLine2(npc)
		self:PaintRows(npc)
		if res.dish then
			self:ServeDish(f)
		end
		if res.signed then
			ns.Delay(0.6, function()
				self:ShowSigned(f, res.signed)
			end, UI)
		end
	end
	local function Full()
		local s = res.complete.series
		ns.Tween(0.5, function(e)
			f.card.glow:SetAlpha(math.sin(e * math.pi) * 0.8)
		end, nil, nil, UI)
		if Hud and Hud.Fly and s and s.pack then
			local bar = ns.BoosterBar and ns.BoosterBar.frame
			local to = (bar and bar:IsShown() and bar) or rawget(_G, "CuratorMinimapButton")
			if to then
				Hud.Fly(octoConstants.MEDIA .. s.pack .. "Top", f.card.slots[CARD], to, 40, 0.9, nil, { 1, 0.85, 0.5 }, 0.3)
			end
		end
	end
	local Next
	Next = function()
		k = k + 1
		if k > res.added then
			return After()
		end
		local pos = res.at + k
		if pos <= CARD then
			local x = old[pos]
			f.card.slots[pos]:Press(npc, x and x.t, delay, function()
				self:PaintPanel(npc, old, pos)
				delay = 0.2
				if pos == CARD and res.complete then
					Full()
					-- (the last stamp: the innkeeper speaks now; a new card comes, for the stamps to come)
					local last = k >= res.added
					if last then
						After()
					end
					ns.Delay(1.6, function()
						self:PaintPanel(npc, I:CardStamps(), 0)
						if not last then
							Next()
						end
					end, UI)
				else
					Next()
				end
			end, UI)
		else
			local cur = I:CardStamps()
			local p2 = pos - CARD
			local x = cur[p2]
			self:PaintPanel(npc, cur, p2 - 1)
			f.card.slots[p2]:Press(npc, x and x.t, delay, function()
				self:PaintPanel(npc, cur, p2)
				Next()
			end, UI)
		end
	end
	Next()
end

-- (1.14.0) The dish served: its slate lights up, its icon flies to the booster bar (where its time is shown).
function UI:ServeDish(f)
	local sl = f.slate
	ns.Play(ns.SND.claim)
	ns.Tween(0.6, function(e)
		sl.glow:SetAlpha(0.4 + math.sin(e * math.pi) * 0.6)
	end, nil, nil, UI)
	Hud.Burst(sl.icon, { 1, 0.85, 0.5 }, 14, 90, 12)
	local bar = ns.BoosterBar and ns.BoosterBar.frame
	local LG = ns.Lodging
	local def = LG and LG:Dish()
	if bar and bar:IsShown() and Hud.Fly and def then
		local to = ns.LodgingUI and ns.LodgingUI.DishSlot and ns.LodgingUI:DishSlot() or bar
		Hud.Fly(LG:Icon(def), sl.icon, to, 30, 0.9, function()
			if ns.LodgingUI and ns.LodgingUI.Paint then
				ns.LodgingUI:Paint()
			end
		end, { 1, 0.85, 0.5 }, 0.4, { coords = { 0.08, 0.92, 0.08, 0.92 } })
	end
end

-- The signed card comes beside the window, its signature written as one watches.
function UI:ShowSigned(f, card)
	local g = f.gift
	g.card:SetCard(card, { owned = true, signed = true })
	g.card:ShowSide("front")
	g:SetAlpha(0)
	g:Show()
	ns.Play(ns.SND.reveal[math.min(card.rarity, 5)] or ns.SND.shiny)
	ns.Tween(0.4, function(e)
		g:SetAlpha(e)
	end, function()
		g.card:WriteSignature(1.6, nil, UI)
		ns.Play(ns.SND.ink)
	end, nil, UI)
end

-------------------------------------------------------------------------------
-- The lines of Curator in the window of an innkeeper
-------------------------------------------------------------------------------
ns.Gossip:Provide("inn", function(npc)
	if not ns.db then
		return {}
	end
	local lines = {}
	if I:StampedToday() then
		lines[CuratorOctoFull.Length(lines) + 1] = { text = string.format(L["My loyalty card (next stamp in %s)"], ns.Duration(I:NextIn())), icon = octoConstants.MEDIA .. "Icon", click = function(id)
			UI:Open(id or npc, false)
		end }
	else
		local party = ns.Tavern and ns.Tavern:Party()
		local LG = ns.Lodging
		local def = LG and type(npc) == "number" and LG:DishOf(npc)
		local text
		if def then
			text = party and string.format(L["Stamp my loyalty card (double stamp tonight!), with the %s"], LG:Name(def))
				or string.format(L["Stamp my loyalty card, with the %s"], LG:Name(def))
		else
			text = party and L["Stamp my loyalty card (double stamp tonight!)"] or L["Stamp my loyalty card"]
		end
		lines[CuratorOctoFull.Length(lines) + 1] = { text = text, icon = octoConstants.MEDIA .. "Icon", click = function(id)
			UI:Open(id or npc, true)
		end }
	end
	return lines
end)

-- (1.14.0) The counter opens with the innkeeper's window (unless turned off in the options).
ns.On("NPC_TALK", function(role, npc)
	if role ~= "inn" or type(npc) ~= "number" or not ns.db or ns.db.innCounter == false then
		return
	end
	ns.Delay(0.05, function()
		local G = ns.Gossip
		if G and G.open and G.npc == npc then
			UI:Open(npc, false, true)
		end
	end, UI)
end)

-- (the round paid as the innkeeper's window opens: shown once his counter is there, UI:Open)
ns.On("TAVERN_ROUND", function(res)
	local f = UI.panel
	if res and f and f:IsShown() then
		UI:ShowRound(res)
	else
		UI.pendingRound = res
	end
end)

ns.On("NPC_LEFT", function()
	-- (the card stays while its stamp comes down, then goes with the innkeeper's window)
	local f = UI.panel
	if f and f:IsShown() and not f.gift:IsShown() then
		ns.Delay(0.8, function()
			if not (ns.Gossip and ns.Gossip.open) and not f.busy then
				f:Hide()
			end
		end, f)
	end
end)

-- (what the counter shows changes: the rubies of a rumor, a rumor heard, a bet played)
for _, e in ipairs({ "RUBIES_CHANGED", "TAVERN_RUMOR", "TAVERN_BET", "TAVERN_DEAL", "DISH_ENDED" }) do
	local _, e = _, e; ns.On(e, function()
		local f = UI.panel
		if f and f:IsShown() and f.npc and not f.busy then
			UI:PaintDish(f.npc)
			UI:PaintRows(f.npc)
		end
	end)
end

-------------------------------------------------------------------------------
-- What the inns gave, in the alerts
-------------------------------------------------------------------------------
ns.On("INN_VISA", function(npc, n)
	if not ns.Toast then
		return
	end
	ns.Toast:Push({
		title = string.format(L["New visa: %d"], n),
		name = I:Place(npc),
		color = { 1, 0.86, 0.6 },
		line = I:Name(npc),
		tex = { "StampRing", nil, InkOf(npc) },
		sound = ns.SND.stamp,
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

ns.On("INN_STEP", function(i, packs)
	if not ns.Toast then
		return
	end
	local goal = I:StepGoal(i)
	ns.Toast:Push({
		title = string.format(L["Travel passport: %d inns!"], goal),
		name = packs == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], packs),
		color = octoConstants.GOLD,
		line = L["Choose it among three: the inventory, Boosters."],
		tex = { "PackZoneChoice" },
		sound = ns.SND.questDone,
		onClick = function()
			ns.Album:ShowBoosters()
		end,
	})
end)

ns.On("INN_RANK", function(npc, after)
	if not ns.Toast then
		return
	end
	ns.Toast:Push({
		title = I:RankName(after),
		name = I:Name(npc),
		color = octoConstants.GOLD,
		line = I:Place(npc),
		tex = { "Interface\\Icons\\INV_Drink_04" },
		sound = ns.SND.rankUp,
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

ns.On("INN_SIGNED", function(card)
	if not ns.Toast then
		return
	end
	ns.Toast:Push({
		title = L["Signed card!"],
		name = C:Name(card),
		color = { 1, 0.86, 0.5 },
		line = L["Signed for a friend of the house."],
		card = card,
		sound = ns.SND.reveal[math.min(card.rarity, 5)],
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

-------------------------------------------------------------------------------
-- The page of the album: the inns. (1.14.0, after its test, his word: the page redone) On the left, the evening at
-- the inn: the loyalty card, the dish of the day on its slate (as at the counter), the rest of the collector and the
-- leads of the tavern on the dark cards of the album, the counts of the inns; on the right, the travel passport open
-- on a continent, all of it inside the frame printed on its page, the way of its steps at its foot.
-------------------------------------------------------------------------------
octoConstants.LEFT_W = 300
octoConstants.LEAD_ROWS = 2 -- (1.14.0) the leads listed on the page, the others on the screen
local TX = 58 -- (where the texts of a dark card start: its medallion before them)
-- (the left is 534 high: the card 146, the slate 120, the rest 76, the leads 62, the counts 96, and between them)
octoConstants.CARD_PW = 292
octoConstants.SLATE_Y, octoConstants.SLATE_PH = -154, 120
octoConstants.REST_Y, octoConstants.REST_H = -282, 76
octoConstants.LEADS_Y, octoConstants.LEADS_H = -364, 62
octoConstants.COUNTS_Y, octoConstants.COUNTS_H = -434, 96
octoConstants.LIGHT = { 0.86, 0.86, 0.82 }
octoConstants.SOFT_GREEN = { 0.6, 0.9, 0.6 }
-- (the room for the title of a dark card, beside what is on its right)
local function TITLE_W(bk)
	local w = bk.right:GetStringWidth() or 0
	return octoConstants.LEFT_W - TX - 12 - (w > 0 and (w + 8) or 0)
end
octoConstants.CONTS = {
	{ key = "EK", label = "Eastern Kingdoms", map = 1415 },
	{ key = "K", label = "Kalimdor", map = 1414 },
	{ key = "Z", label = "Isles", map = nil },
}
-- (the passport: its page 420 x 534, the frame printed on it 20 points in, 25 at the top and the foot; inside it its
-- title, the tabs of the continents, five rows of five inns, the way of its steps)
octoConstants.COLS, octoConstants.ROWS = 5, 5
octoConstants.CELL_W, octoConstants.CELL_H = 72, 74
octoConstants.TABS_Y, octoConstants.GRID_Y, octoConstants.WAY_Y = -57, -92, -463
octoConstants.WAY_H = 40
octoConstants.DASHES = 42

-- A text with its shadow, on the dark of the page.
local function Lit(parent, size, color, justify)
	local fs = Hud.Text(parent, size)
	if color then
		fs:SetTextColor(color[1], color[2], color[3])
	end
	fs:SetJustifyH(justify or "LEFT")
	return fs
end

-- The inns of a continent, by album then name.
local function InnsOf(cont)
	local out = {}
	for npc, d in pairs(ns.INNKEEPERS or {}) do
		if d[1] == cont then
			out[CuratorOctoFull.Length(out) + 1] = npc
		end
	end
	local order = {}
	for i, s in ipairs(A.Order and A:Order() or ns.Series) do
		order[s.key] = i
	end
	table.sort(out, function(a, b)
		local sa, sb = I:Album(a), I:Album(b)
		local oa, ob = sa and order[sa.key] or 999, sb and order[sb.key] or 999
		if oa ~= ob then
			return oa < ob
		end
		return a < b
	end)
	return out
end

-- The innkeepers met that Curator did not know: with the isles.
local function Others()
	local out = {}
	local s = I:State()
	for npc in pairs(s and s.visas or {}) do
		if not I:Known(npc) then
			out[CuratorOctoFull.Length(out) + 1] = npc
		end
	end
	table.sort(out)
	return out
end

-- The inns of a tab of the passport (the isles: with the innkeepers Curator did not know), and those with a visa.
local function TabInns(cont)
	local list = InnsOf(cont)
	if cont == "Z" then
		for _, npc in ipairs(Others()) do
			list[CuratorOctoFull.Length(list) + 1] = npc
		end
	end
	local here = 0
	for _, npc in ipairs(list) do
		if I:HasVisa(npc) then
			here = here + 1
		end
	end
	return list, here
end

-- An inn of the passport: its stamp (or its place, the mark of its album faint in it), its innkeeper, its place, the
-- marks of his loyalty, the quill of his signed card, the hearthstone of the home inn.
local function NewCell(parent)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, octoConstants.CELL_W, octoConstants.CELL_H)
	b.stamp = UI.NewStamp(b, 42, true)
	b.stamp:SetPoint("TOP", 0, -1)
	b.stamp:EnableMouse(false)
	b.ghost = b.stamp:CreateTexture(nil, "ARTWORK", nil, 1)
	b.ghost:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.ghost, 21, 21)
	if b.ghost.SetDesaturated then
		CuratorOctoFull.SetDesaturated(b.ghost, true)
	end
	b.ghost:SetVertexColor(octoConstants.BROWN[1], octoConstants.BROWN[2], octoConstants.BROWN[3], 0.2)
	b.name = Text(b, 9.5, octoConstants.PAPER_INK, "CENTER")
	b.name:SetPoint("TOP", b.stamp, "BOTTOM", 0, 0)
	b.name:SetWidth(octoConstants.CELL_W - 2)
	CuratorOctoFull.SetWordWrap(b.name, false)
	-- (its place on two lines at most: the names of the zones are long)
	b.place = Text(b, 7.5, { 0.45, 0.33, 0.2 }, "CENTER")
	b.place:SetPoint("TOP", b.name, "BOTTOM", 0, 0)
	b.place:SetWidth(octoConstants.CELL_W - 2)
	b.place:SetJustifyV("TOP")
	CuratorOctoFull.SetWordWrap(b.place, true)
	if b.place.SetMaxLines then
		CuratorOctoFull.SetMaxLines(b.place, 2)
	end
	-- the loyalty: four marks; the quill of a signed card
	b.pips = {}
	for i = 1, CuratorOctoFull.Length(I.RANKS) do
		local p = b:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.SetSize(p, 6, 6)
		p:SetTexture(octoConstants.MEDIA .. "Dot")
		p:SetPoint("TOPLEFT", b.stamp, "TOPRIGHT", -3, -4 - (i - 1) * 8)
		b.pips[i] = p
	end
	b.quill = b:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(b.quill, 15, 15)
	b.quill:SetPoint("TOPRIGHT", b.stamp, "TOPLEFT", 7, -1)
	b.quill:SetTexture("Interface\\Icons\\INV_Feather_04")
	b.quill:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	-- (the home inn of the character: its hearthstone)
	b.home = b:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(b.home, 15, 15)
	b.home:SetPoint("BOTTOMRIGHT", b.stamp, "BOTTOMLEFT", 7, 1)
	b.home:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
	b.home:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	-- (under the mouse: a light of ink around it)
	b.hl = b:CreateTexture(nil, "BACKGROUND")
	b.hl:SetPoint("TOPLEFT", 2, 0)
	b.hl:SetPoint("BOTTOMRIGHT", -2, 2)
	CuratorOctoFull.ColorTexture(b.hl, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.08)
	b.hl:Hide()
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		self.hl:Show()
		UI:CellTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function(self)
		self.hl:Hide()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		local card = self.npc and I:CardOf(self.npc)
		if card and ns.Album then
			ns.Album:ShowCard(card)
		end
	end)
	return b
end

function UI:CellTooltip(b)
	local npc = b.npc
	if not npc then
		return
	end
	local s = I:State()
	local v = s and s.visas[npc]
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:SetText(I:Name(npc), 1, 0.82, 0)
	local album = I:Album(npc)
	if type(v) == "table" then
		GameTooltip:AddLine(I:Place(npc), 1, 1, 1)
		GameTooltip:AddLine(string.format(L["Visa: %s"], DayLong(v.t)), 0.7, 0.7, 0.7)
	else
		GameTooltip:AddLine(album and C:SeriesName(album) or "?", 0.7, 0.7, 0.7)
		GameTooltip:AddLine(L["No visa yet: talk to this innkeeper."], 0.6, 0.6, 0.6)
	end
	local n, r, nextAt = I:Loyalty(npc)
	if n > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(I:RankName(r) or "", n == 1 and L["1 stamp"] or string.format(L["%d stamps"], n), 1, 0.82, 0, 1, 1, 1)
		if nextAt then
			GameTooltip:AddLine(string.format(L["%s at %d."], I:RankName(r + 1), nextAt), 0.7, 0.7, 0.7)
		end
	end
	if I:IsSigned("c" .. npc) then
		GameTooltip:AddLine(L["Signed card"], 1, 0.86, 0.5)
	elseif I:CardOf(npc) then
		GameTooltip:AddLine(string.format(L["Friend of the house (%d stamps): his signed card."], I.RANKS[I.SIGN_RANK].n), 0.55, 0.55, 0.55, true)
	end
	local T = ns.Tavern
	if T and T:IsHome(npc) then
		GameTooltip:AddLine(L["Your home inn: your loyalty counts double here."], 0.4, 0.8, 1, true)
	end
	local key = T and T:Rumors()[npc]
	local rumor = key and ns.Cards[key]
	if rumor then
		GameTooltip:AddLine(string.format(L["Rumor of the day: %s"], C:Name(rumor)), 0.6, 0.9, 0.6, true)
	end
	-- (1.14.0) his dish of the day
	local LG = ns.Lodging
	if LG then
		local def = LG:DishOf(npc)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format(L["Dish of the day: %s"], LG:Name(def)), 1, 0.86, 0.55)
		GameTooltip:AddLine(LG:Text(def), 0.85, 0.85, 0.85, true)
	end
	GameTooltip:Show()
end

-- (1.14.0) A step of the passport, under the mouse: its inns, its boosters, where it stands.
function UI:StepTooltip(owner, i)
	local stp = I.STEPS[i]
	if not stp then
		return
	end
	local st = I:State()
	local _, known = I:VisaCount()
	local goal = I:StepGoal(i)
	local got = st and st.steps[i]
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	GameTooltip:SetText(stp.goal == "all" and string.format(L["Every inn of Azeroth (%d)"], goal) or string.format(L["%d inns"], goal), 1, 0.82, 0)
	GameTooltip:AddLine(stp.packs == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], stp.packs), 1, 1, 1)
	if got then
		GameTooltip:AddLine(string.format(L["Earned on %s"], DayLong(got)), 0.45, 1, 0.45)
	else
		GameTooltip:AddLine(string.format(L["%d / %d"], math.min(known, goal), goal), 0.7, 0.7, 0.7)
	end
	GameTooltip:Show()
end

-- A dark card of the left (the cards of the album): its medallion (a round icon in its ring of gold), its title, what is
-- on the right of its title, its line; lit under the mouse (tip: its tooltip).
local function Tile(page, y, h, icon, tip)
	local t = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(t, octoConstants.LEFT_W, h)
	t:SetPoint("TOPLEFT", 0, y)
	Hud.Panel(t, h)
	t.icon = Hud.RoundIcon(t, 34, "ARTWORK")
	t.icon:SetPoint("CENTER", t, "TOPLEFT", 30, -h / 2)
	if icon then
		Hud.SetIcon(t.icon, { icon })
	end
	t.ring = t:CreateTexture(nil, "OVERLAY")
	t.ring:SetTexture(octoConstants.MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(t.ring, 44, 44)
	t.ring:SetPoint("CENTER", t.icon, "CENTER")
	t.title = Lit(t, 12, octoConstants.GOLD)
	t.title:SetPoint("TOPLEFT", TX, -10)
	CuratorOctoFull.SetWordWrap(t.title, false)
	t.right = Lit(t, 10.5, octoConstants.SOFT_GREEN, "RIGHT")
	t.right:SetPoint("TOPRIGHT", -12, -11)
	t.sub = Lit(t, 10, octoConstants.LIGHT)
	t.sub:SetPoint("TOPLEFT", TX, -27)
	t.sub:SetWidth(octoConstants.LEFT_W - TX - 12)
	CuratorOctoFull.SetWordWrap(t.sub, true)
	if t.sub.SetMaxLines then
		CuratorOctoFull.SetMaxLines(t.sub, 2)
	end
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		Hud.Each(self.glow, "SetAlpha", 0.3)
		if tip then
			tip(self)
		end
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function(self)
		Hud.Each(self.glow, "SetAlpha", 0)
		GameTooltip:Hide()
	end)
	return t
end

function A:BuildInns()
	local f = self.frame
	if f.inns then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.inns = page
	local ph = U.PAGE_H - 20

	-- the loyalty card, on top
	page.card = UI.NewLoyaltyCard(page, octoConstants.CARD_PW)
	page.card:SetPoint("TOP", page, "TOPLEFT", octoConstants.LEFT_W / 2, 0)

	-- the dish of the day, on its slate (as at the counter)
	local sl = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(sl, octoConstants.LEFT_W, octoConstants.SLATE_PH)
	sl:SetPoint("TOPLEFT", 0, octoConstants.SLATE_Y)
	sl.bg = sl:CreateTexture(nil, "BACKGROUND")
	sl.bg:SetAllPoints()
	sl.bg:SetTexture(octoConstants.MEDIA .. "InnSlate")
	sl.bg:SetTexCoord(0, 1, 0, 197 / 256)
	-- (its title on the line of chalk of the slate, 27 % of its height down)
	sl.title = sl:CreateFontString(nil, "OVERLAY")
	Fancy(sl.title, 13)
	sl.title:SetPoint("BOTTOM", sl, "TOP", 0, -octoConstants.SLATE_PH * 0.27 + 2)
	sl.title:SetTextColor(octoConstants.CHALK[1], octoConstants.CHALK[2], octoConstants.CHALK[3])
	sl.glow = sl:CreateTexture(nil, "ARTWORK")
	sl.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	sl.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(sl.glow, 80, 80)
	sl.glow:SetPoint("CENTER", sl, "TOPLEFT", 46, -72)
	sl.glow:SetVertexColor(1, 0.8, 0.45)
	sl.glow:SetAlpha(0)
	sl.icon = Hud.RoundIcon(sl, 38, "ARTWORK", 2)
	sl.icon:SetPoint("CENTER", sl, "TOPLEFT", 46, -72)
	sl.ring = sl:CreateTexture(nil, "OVERLAY")
	sl.ring:SetTexture(octoConstants.MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(sl.ring, 48, 48)
	sl.ring:SetPoint("CENTER", sl.icon, "CENTER")
	sl.name = Text(sl, 12.5, { 1, 0.86, 0.55 }, "LEFT")
	sl.name:SetPoint("TOPLEFT", 82, -38)
	CuratorOctoFull.SetWordWrap(sl.name, false)
	sl.text = Text(sl, 9.5, octoConstants.CHALK, "LEFT")
	sl.text:SetWidth(octoConstants.LEFT_W - 82 - 16)
	CuratorOctoFull.SetWordWrap(sl.text, true)
	sl.time = Text(sl, 9.5, octoConstants.GREEN, "LEFT")
	sl.time:SetWidth(octoConstants.LEFT_W - 82 - 16)
	CuratorOctoFull.SetWordWrap(sl.time, false)
	CuratorOctoFull.SetScript(sl, "OnEnter", function(self)
		local LG = ns.Lodging
		if LG and LG:Dish() and ns.LodgingUI then
			ns.LodgingUI:DishTooltip(self)
		else
			UI:DishesTooltip(self)
		end
	end)
	CuratorOctoFull.SetScript(sl, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.dish = sl

	-- the rest of the collector
	page.rest = Tile(page, octoConstants.REST_Y, octoConstants.REST_H, "Interface\\Icons\\Spell_Nature_Sleep", function(self)
		if ns.LodgingUI then
			ns.LodgingUI:RestTooltip(self)
		end
	end)
	page.rest.bar = Hud.XPBar(page.rest, octoConstants.LEFT_W - TX - 16, 10, { 0.45, 0.65, 1 })
	page.rest.bar:SetPoint("TOPLEFT", TX + 2, -30)
	-- (the spark at the end of its fill: blue, as the rest)
	page.rest.bar.tip:SetVertexColor(0.6, 0.8, 1)
	page.rest.sub:ClearAllPoints()
	page.rest.sub:SetPoint("TOPLEFT", TX, -46)

	-- the leads of the tavern
	local le = Tile(page, octoConstants.LEADS_Y, octoConstants.LEADS_H, "Interface\\Icons\\Ability_Tracking", function(self)
		UI:LeadsTooltip(self)
	end)
	page.leads = le
	le.sub:Hide()
	le.right:SetTextColor(0.7, 0.7, 0.7)
	le.rows = {}
	for i = 1, octoConstants.LEAD_ROWS do
		local i = i; local row = CreateFrame("Button", nil, le)
		CuratorOctoFull.SetSize(row, octoConstants.LEFT_W - TX - 12, 15)
		row:SetPoint("TOPLEFT", TX, -27 - (i - 1) * 16)
		row.name = Lit(row, 10.5, { 1, 1, 1 })
		row.name:SetPoint("LEFT")
		row.name:SetPoint("RIGHT", -46, 0)
		CuratorOctoFull.SetWordWrap(row.name, false)
		row.left = Lit(row, 10, { 0.7, 0.7, 0.7 }, "RIGHT")
		row.left:SetPoint("RIGHT")
		row.left:SetWidth(44)
		CuratorOctoFull.SetScript(row, "OnEnter", function(self)
			Hud.Each(le.glow, "SetAlpha", 0.3)
			if ns.LodgingUI and self.lead then
				ns.LodgingUI:LeadTooltip(self)
			end
		end)
		CuratorOctoFull.SetScript(row, "OnLeave", function()
			Hud.Each(le.glow, "SetAlpha", 0)
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(row, "OnClick", function(self)
			if self.card then
				ns.Play(ns.SND.click)
				A:ShowCard(self.card)
			end
		end)
		le.rows[i] = row
	end
	-- (no lead yet: what they are, in their place)
	le.more = Lit(le, 10, { 0.66, 0.66, 0.66 })
	le.more:SetPoint("TOPLEFT", TX, -27)
	le.more:SetWidth(octoConstants.LEFT_W - TX - 12)
	CuratorOctoFull.SetWordWrap(le.more, true)
	if le.more.SetMaxLines then
		CuratorOctoFull.SetMaxLines(le.more, 2)
	end

	-- the counts of the inns
	local co = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(co, octoConstants.LEFT_W, octoConstants.COUNTS_H)
	co:SetPoint("TOPLEFT", 0, octoConstants.COUNTS_Y)
	Hud.Panel(co, octoConstants.COUNTS_H)
	page.counts = co
	page.stats = {}
	local icons = { "Interface\\Icons\\INV_Misc_Note_02", "Interface\\Icons\\INV_Drink_04", "Interface\\Icons\\INV_Feather_04", "Interface\\Icons\\INV_Misc_Map_01" }
	for i = 1, 4 do
		local row = CreateFrame("Frame", nil, co)
		CuratorOctoFull.SetSize(row, octoConstants.LEFT_W - 32, 20)
		row:SetPoint("TOPLEFT", 16, -8 - (i - 1) * 20)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(row.icon, 16, 16)
		row.icon:SetPoint("LEFT")
		row.icon:SetTexture(icons[i])
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.label = Lit(row, 10.5, octoConstants.LIGHT)
		row.label:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
		row.label:SetPoint("RIGHT", -40, 0)
		CuratorOctoFull.SetWordWrap(row.label, false)
		row.value = Lit(row, 12, octoConstants.GOLD, "RIGHT")
		row.value:SetPoint("RIGHT")
		if i > 1 then
			row.rule = row:CreateTexture(nil, "ARTWORK")
			CuratorOctoFull.ColorTexture(row.rule, 1, 0.82, 0.4, 0.13)
			row.rule:SetHeight(1)
			row.rule:SetPoint("TOPLEFT", 0, 1)
			row.rule:SetPoint("TOPRIGHT", 0, 1)
		end
		page.stats[i] = row
	end

	-- the right: the passport, open on a continent
	local rx = octoConstants.LEFT_W + 16
	local pw = U.PAGE_W - 32 - rx
	local book = CreateFrame("Frame", nil, page)
	book:SetPoint("TOPLEFT", rx, 0)
	CuratorOctoFull.SetSize(book, pw, ph)
	book.paper = book:CreateTexture(nil, "BACKGROUND")
	book.paper:SetAllPoints()
	book.paper:SetTexture(octoConstants.MEDIA .. "PassportPage")
	book.title = book:CreateFontString(nil, "OVERLAY")
	Fancy(book.title, 17)
	book.title:SetPoint("TOP", 0, -32)
	book.title:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3])
	-- (a line of ink on each side of it)
	book.flourish = {}
	for i, side in ipairs({ "RIGHT", "LEFT" }) do
		local l = book:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.ColorTexture(l, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.45)
		CuratorOctoFull.SetSize(l, 54, 1)
		l:SetPoint(side, book.title, i == 1 and "LEFT" or "RIGHT", i == 1 and -12 or 12, -1)
		local d = book:CreateTexture(nil, "ARTWORK")
		d:SetTexture(octoConstants.MEDIA .. "Dot")
		d:SetVertexColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.6)
		CuratorOctoFull.SetSize(d, 5, 5)
		d:SetPoint("CENTER", l, side == "RIGHT" and "LEFT" or "RIGHT", 0, 0)
		book.flourish[i] = l
	end
	-- the tabs of the continents: its name, its visas; the one open written darker, underlined
	book.tabs = {}
	local TAB_W = math.floor((pw - 58 - 8) / 3)
	local tx0 = (pw - (3 * TAB_W + 8)) / 2
	for i, ct in ipairs(octoConstants.CONTS) do
		local i, ct = i, ct; local t = CreateFrame("Button", nil, book)
		CuratorOctoFull.SetSize(t, TAB_W, 32)
		t:SetPoint("TOPLEFT", tx0 + (i - 1) * (TAB_W + 4), octoConstants.TABS_Y)
		t.bg = t:CreateTexture(nil, "BACKGROUND")
		t.bg:SetAllPoints()
		CuratorOctoFull.ColorTexture(t.bg, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.08)
		t.label = U.MapName and ct.map and U.MapName(ct.map, L[ct.label]) or L[ct.label]
		t.text = Text(t, 11, octoConstants.PAPER_INK, "CENTER")
		t.text:SetPoint("TOP", 0, -4)
		t.count = Text(t, 9, octoConstants.PAPER_INK, "CENTER")
		t.count:SetPoint("TOP", t.text, "BOTTOM", 0, -1)
		t.line = t:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.ColorTexture(t.line, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.85)
		t.line:SetHeight(2)
		t.line:SetPoint("BOTTOM", 0, 0)
		CuratorOctoFull.SetScript(t, "OnClick", function()
			A.innsCont = ct.key
			ns.Play(ns.SND.page)
			A:Refresh()
		end)
		CuratorOctoFull.SetScript(t, "OnEnter", function(self)
			if not self.on then
				CuratorOctoFull.ColorTexture(self.bg, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.16)
			end
		end)
		CuratorOctoFull.SetScript(t, "OnLeave", function(self)
			if not self.on then
				CuratorOctoFull.ColorTexture(self.bg, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.08)
			end
		end)
		book.tabs[i] = t
	end
	-- the inns
	book.cells = {}
	local gx = (pw - octoConstants.COLS * octoConstants.CELL_W) / 2
	for i = 1, octoConstants.COLS * octoConstants.ROWS do
		local b = NewCell(book)
		local col, row = CuratorOctoFull.Mod((i - 1) , octoConstants.COLS), math.floor((i - 1) / octoConstants.COLS)
		b:SetPoint("TOPLEFT", gx + col * octoConstants.CELL_W, octoConstants.GRID_Y - row * octoConstants.CELL_H)
		book.cells[i] = b
	end
	book.empty = Text(book, 12, octoConstants.PAPER_INK, "CENTER")
	book.empty:SetPoint("CENTER", 0, -20)
	book.empty:SetWidth(pw - 60)
	-- the way of the steps, at the foot of the page: a line of ink from the first visa to the last inn, a stamp at each
	-- step (its boosters in it), darker as far as the visas go
	local way = CreateFrame("Frame", nil, book)
	local ww = octoConstants.COLS * octoConstants.CELL_W
	CuratorOctoFull.SetSize(way, ww, octoConstants.WAY_H)
	way:SetPoint("TOPLEFT", gx, octoConstants.WAY_Y)
	way.x0, way.len = 14, ww - 28
	way.dashes = {}
	for i = 1, octoConstants.DASHES do
		local d = way:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(d, way.len / octoConstants.DASHES * 0.62, 2)
		d:SetPoint("CENTER", way, "TOPLEFT", way.x0 + way.len * (i - 0.5) / octoConstants.DASHES, -13)
		way.dashes[i] = d
	end
	way.start = way:CreateTexture(nil, "ARTWORK", nil, 1)
	way.start:SetTexture(octoConstants.MEDIA .. "Dot")
	CuratorOctoFull.SetSize(way.start, 8, 8)
	way.start:SetPoint("CENTER", way, "TOPLEFT", way.x0, -13)
	way.start:SetVertexColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.85)
	way.nodes = {}
	for i in ipairs(I.STEPS) do
		local i = i; local n = CreateFrame("Button", nil, way)
		CuratorOctoFull.SetSize(n, 26, 26)
		n.slot = n:CreateTexture(nil, "ARTWORK")
		n.slot:SetAllPoints()
		n.slot:SetTexture(octoConstants.MEDIA .. "StampSlot")
		n.slot:SetVertexColor(octoConstants.BROWN[1], octoConstants.BROWN[2], octoConstants.BROWN[3], 0.6)
		n.ring = n:CreateTexture(nil, "ARTWORK", nil, 1)
		n.ring:SetAllPoints()
		n.ring:SetTexture(octoConstants.MEDIA .. "StampRing")
		n.ring:SetVertexColor(0.62, 0.16, 0.12, 0.9)
		n.paper = n:CreateTexture(nil, "BORDER")
		n.paper:SetPoint("TOPLEFT", 3, -3)
		n.paper:SetPoint("BOTTOMRIGHT", -3, 3)
		n.paper:SetTexture(octoConstants.MEDIA .. "Dot")
		n.paper:SetVertexColor(0.93, 0.87, 0.72)
		n.pack = n:CreateTexture(nil, "ARTWORK", nil, 2)
		CuratorOctoFull.SetSize(n.pack, 11, 16)
		n.pack:SetPoint("CENTER")
		n.pack:SetTexture(octoConstants.MEDIA .. "PackZoneChoice")
		-- (its boosters: at its foot, on its right)
		n.packs = Text(n, 8.5, octoConstants.PAPER_INK, "CENTER")
		n.packs:SetPoint("CENTER", n, "BOTTOMRIGHT", -1, 3)
		n.goal = Text(n, 9, octoConstants.PAPER_INK, "CENTER")
		n.goal:SetPoint("TOP", n, "BOTTOM", 0, -1)
		n.check = n:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.SetSize(n.check, 14, 14)
		n.check:SetPoint("CENTER", n, "TOPRIGHT", -3, -3)
		n.check:SetTexture(octoConstants.MEDIA .. "Check")
		CuratorOctoFull.SetScript(n, "OnEnter", function(self)
			UI:StepTooltip(self, i)
		end)
		CuratorOctoFull.SetScript(n, "OnLeave", function()
			GameTooltip:Hide()
		end)
		way.nodes[i] = n
	end
	book.way = way
	page.book = book
	CuratorOctoFull.SetScript(page, "OnUpdate", function(_, elapsed)
		UI.pt = (UI.pt or 0) + elapsed
		-- (1.14.0: the time of the dish and of the leads, kept up to date)
		page.lt = (page.lt or 0) + elapsed
		if page.lt >= 15 then
			page.lt = 0
			A:RefreshLodging(page)
		end
	end)
end

function A:ShowInnsPage(shown)
	local f = self.frame
	if shown then
		self:BuildInns()
	end
	if f.inns then
		CuratorOctoFull.SetShown(f.inns, shown)
	end
end

function A:RefreshInns()
	local f = self.frame
	local page = f.inns
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	local st = I:State()
	local visas, known = I:VisaCount()
	local all = I:AllCount()
	self:SetTitle(L["Inns"], string.format(L["Travel passport: %d / %d inns"], known, all))
	self:SetBar(known, all, string.format(L["%d / %d inns"], known, all))
	-- (1.14.0) the rest, the dish under way, the leads
	self:RefreshLodging(page)
	-- the card
	local stamps = I:CardStamps()
	local last = stamps[CuratorOctoFull.Length(stamps)]
	page.card:Paint(stamps, last and I:Prize(last.n) or nil)
	if I:StampedToday() then
		page.card.sub:SetText(string.format(L["Today's stamp: taken (the next one in %s)"], ns.Duration(I:NextIn())))
	elseif ns.Tavern and ns.Tavern:Party() then
		page.card.sub:SetText(L["Evening at the inn: double stamp tonight!"])
	else
		page.card.sub:SetText(L["Talk to an innkeeper for today's stamp"])
	end
	-- the counts
	local regulars = 0
	for npc, n in pairs(st and st.loyal or {}) do
		if I:Rank(n) >= 2 then
			regulars = regulars + 1
		end
	end
	local rows = {
		{ L["Loyalty cards full"], ns.Num(st and st.cards or 0) },
		{ L["Inns where you are a regular"], ns.Num(regulars) },
		{ L["Signed cards"], ns.Num(I:SignedCount()) },
		{ L["Visas"], ns.Num(visas) },
	}
	for i, row in ipairs(page.stats) do
		row.value:SetText(rows[i][2])
		S.Fit(row.label, rows[i][1], octoConstants.LEFT_W - 32 - 25 - 40, 10.5, 8.5)
	end
	-- the passport, on its continent
	local cont = self.innsCont or "EK"
	local book = page.book
	book.title:SetText(L["Travel passport"])
	local list
	for i, t in ipairs(book.tabs) do
		local ct = octoConstants.CONTS[i]
		local inns, here = TabInns(ct.key)
		local on = ct.key == cont
		if on then
			list = inns
		end
		t.on = on
		S.Fit(t.text, t.label, t:GetWidth() - 6, 11, 8.5)
		t.count:SetText(string.format(L["%d / %d"], here, CuratorOctoFull.Length(inns)))
		t.text:SetAlpha(on and 1 or 0.6)
		t.count:SetAlpha(on and 0.85 or 0.5)
		CuratorOctoFull.ColorTexture(t.bg, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], on and 0.14 or 0.06)
		t.line:SetWidth(t:GetWidth())
		CuratorOctoFull.SetShown(t.line, on)
	end
	list = list or {}
	for i, b in ipairs(book.cells) do
		local npc = list[i]
		b.npc = npc
		if not npc then
			b:Hide()
		else
			local v = st and st.visas[npc]
			local album = I:Album(npc)
			if type(v) == "table" then
				b.stamp:Paint(npc, v.t)
				b.ghost:Hide()
				b.place:SetText(I:Place(npc))
				b.name:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3])
				b.place:SetAlpha(1)
			else
				b.stamp:Paint(nil)
				-- (the mark of its album, faint in the place of its stamp)
				b.ghost:SetTexture(octoConstants.MEDIA .. ((album and album.set) or "SetElwynn"))
				b.ghost:Show()
				b.place:SetText(album and C:SeriesName(album) or "")
				b.name:SetTextColor(octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], 0.6)
				b.place:SetAlpha(0.7)
			end
			-- (1.14.0: a long name made smaller; too long even so, its first word: all of it under the mouse)
			local short = I:ShortName(npc)
			S.Fit(b.name, short, octoConstants.CELL_W - 2, 9.5, 7)
			if S.Width(b.name) > octoConstants.CELL_W - 2 and string.find(short, " ", 1, true) then
				S.Fit(b.name, CuratorOctoFull.Match(short, "^(%S+)"), octoConstants.CELL_W - 2, 9.5, 7)
			end
			local _, r = I:Loyalty(npc)
			for k, p in ipairs(b.pips) do
				CuratorOctoFull.SetShown(p, k <= r)
				p:SetVertexColor(0.85, 0.6, 0.15)
			end
			CuratorOctoFull.SetShown(b.quill, I:IsSigned("c" .. npc))
			CuratorOctoFull.SetShown(b.home, ns.Tavern ~= nil and ns.Tavern:IsHome(npc))
			b:Show()
		end
	end
	CuratorOctoFull.SetShown(book.empty, CuratorOctoFull.Length(list) == 0)
	book.empty:SetText(L["No inn here yet."])
	-- the way of the steps: as far as the visas go
	local way = book.way
	local p = all > 0 and math.min(1, known / all) or 0
	for i, d in ipairs(way.dashes) do
		local reached = (i - 0.5) / octoConstants.DASHES <= p
		CuratorOctoFull.ColorTexture(d, octoConstants.PAPER_INK[1], octoConstants.PAPER_INK[2], octoConstants.PAPER_INK[3], reached and 0.85 or 0.25)
	end
	for i, n in ipairs(way.nodes) do
		local stp = I.STEPS[i]
		local goal = I:StepGoal(i)
		local got = st and st.steps[i]
		n:ClearAllPoints()
		n:SetPoint("CENTER", way, "TOPLEFT", way.x0 + way.len * math.min(1, goal / math.max(1, all)), -13)
		CuratorOctoFull.SetShown(n.ring, got ~= nil)
		CuratorOctoFull.SetShown(n.slot, got == nil)
		CuratorOctoFull.SetShown(n.check, got ~= nil)
		if n.pack.SetDesaturated then
			CuratorOctoFull.SetDesaturated(n.pack, got == nil)
		end
		n.pack:SetAlpha(got and 1 or 0.55)
		n.packs:SetText("×" .. stp.packs)
		n.goal:SetText(ns.Num(goal))
		n.goal:SetAlpha(got and 1 or 0.7)
	end
end

-- (1.14.0) The left of the page: the dish of the day on its slate, the rest of the collector, the leads of the tavern.
function A:RefreshLodging(page)
	local LG, T = ns.Lodging, ns.Tavern
	if not (LG and T) then
		return
	end
	local now = (GetServerTime and CuratorOctoFull.ServerTime()) or time()
	local n, max = LG:Rest()
	local r = page.rest
	S.Fit(r.title, string.format(L["Rest of the collector: %d / %d"], n, max), TITLE_W(r), 12, 9)
	r.bar:SetProgress(n / max)
	if LG.Waiting() and n >= 1 then
		r.sub:SetText(L["It waits: a reroll does not use it."])
	elseif n >= 1 then
		r.sub:SetText(string.format(L["Your next %d creatures that have a card: twice as likely to give it."], n))
	elseif LG.Resting() then
		r.sub:SetText(L["You are resting: 100 every 8 hours here, online or logged out."])
	else
		r.sub:SetText(L["Log out in an inn or a capital: 100 every 8 hours."])
	end
	CuratorOctoFull.SetDesaturated(r.icon, n < 1)
	-- the dish of the day, on its slate
	local d = page.dish
	local def, left, from, waiting = LG:Dish()
	local w = octoConstants.LEFT_W - 82 - 16
	d.text:ClearAllPoints()
	d.time:ClearAllPoints()
	if def then
		d.title:SetText(L["Your dish of the day"])
		Hud.SetIcon(d.icon, { LG:Icon(def) })
		CuratorOctoFull.SetDesaturated(d.icon, waiting)
		d.glow:SetAlpha(waiting and 0 or 0.35)
		S.Fit(d.name, LG:Name(def), w, 12.5, 9)
		d.name:Show()
		d.text:SetPoint("TOPLEFT", 82, -54)
		if d.text.SetMaxLines then
			CuratorOctoFull.SetMaxLines(d.text, 3)
		end
		d.text:SetTextColor(octoConstants.CHALK[1], octoConstants.CHALK[2], octoConstants.CHALK[3])
		d.text:SetText(LG:Text(def))
		d.time:SetPoint("TOPLEFT", d.text, "BOTTOMLEFT", 0, -3)
		if waiting then
			d.time:SetTextColor(1, 0.82, 0.36)
			S.Fit(d.time, string.format(L["It waits: you are playing a reroll (%s left)."], LG.Duration(left)), w, 9.5, 7.5)
		else
			d.time:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
			S.Fit(d.time, string.format(L["%s left, while you play."], LG.Duration(left)), w, 9.5, 7.5)
		end
		d.time:Show()
	else
		d.title:SetText(L["Dish of the day"])
		Hud.SetIcon(d.icon, { "Interface\\Icons\\INV_Misc_Food_15" })
		CuratorOctoFull.SetDesaturated(d.icon, true)
		d.glow:SetAlpha(0)
		d.name:SetText("")
		d.name:Hide()
		d.time:SetText("")
		d.time:Hide()
		d.text:SetPoint("LEFT", d, "TOPLEFT", 82, -72)
		if d.text.SetMaxLines then
			CuratorOctoFull.SetMaxLines(d.text, 3)
		end
		d.text:SetTextColor(0.78, 0.78, 0.74)
		-- (eaten; or the stamp of the day taken without it, before 1.14.0; or to come)
		if LG:TakenToday() then
			d.text:SetText(string.format(L["Your dish of today is eaten. The next one comes with tomorrow's stamp (in %s)."], ns.Duration(I:NextIn())))
		elseif I:StampedToday() then
			d.text:SetText(string.format(L["Your stamp of today is taken: your dish comes with tomorrow's stamp (in %s)."], ns.Duration(I:NextIn())))
		else
			d.text:SetText(L["Not yet: each innkeeper offers his own with your stamp of the day."])
		end
	end
	-- the leads
	local list = ns.LodgingUI and ns.LodgingUI:Leads() or T:LeadList()
	local le = page.leads
	le.right:SetText(CuratorOctoFull.Length(list) > octoConstants.LEAD_ROWS and ("+" .. (CuratorOctoFull.Length(list) - octoConstants.LEAD_ROWS)) or "")
	S.Fit(le.title, CuratorOctoFull.Length(list) > 0 and string.format(L["Leads of the tavern (%d)"], CuratorOctoFull.Length(list)) or L["Leads of the tavern"], TITLE_W(le), 12, 9)
	CuratorOctoFull.SetDesaturated(le.icon, CuratorOctoFull.Length(list) == 0)
	for i, row in ipairs(le.rows) do
		local l = list[i]
		row.card, row.lead = l and l.card, l
		if l then
			local x = ns.RARITY[l.card.rarity]
			local c = x and x.text or { 1, 1, 1 }
			row.name:SetText(C:Name(l.card))
			row.name:SetTextColor(c[1], c[2], c[3])
			row.left:SetText(ns.LodgingUI and ns.LodgingUI.Short((tonumber(l.u) or 0) - now) or "")
			row:Show()
		else
			row:Hide()
		end
	end
	CuratorOctoFull.SetShown(le.more, CuratorOctoFull.Length(list) == 0)
	le.more:SetText(L["No lead yet: ask an innkeeper for his rumors, or buy one."])
	-- (more than two: the others counted on the right of its title, all of them on the screen: above)
end

-- The page of the inns, from anywhere (an alert, a command).
function A:ShowInns()
	self:Build()
	self.mode, self.member, self.memberEntries, self.returnMode = "inns", nil, nil, nil
	self:HideDetail()
	self:Reveal()
end
