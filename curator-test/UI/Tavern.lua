local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local C = ns.Collection
local I = ns.Inns
local T = ns.Tavern

-------------------------------------------------------------------------------
-- (1.8.0) The life of the inns on the screen (Tavern.lua): the lines of Curator in the window of the
-- innkeepers (a rumor, the bet, the toasts), the note of the rumor of the day beside it, the table of
-- the innkeeper's bet (a duplicate chosen, three cards face down, one turned over), and the alerts (a
-- glass raised to you, a toast done, the home inn). (1.14.0, after its test, his word: the innkeeper redone) The
-- windows beside his counter (UI/Inns.lua); the bet, a scene of its own: the innkeeper behind his table shows his
-- prizes, shuffles them and deals them face down.
-------------------------------------------------------------------------------
local UI = {}
ns.TavernUI = UI

local GOLD = { 1, 0.82, 0 }
local PAPER_INK = { 0.30, 0.19, 0.08 }
local ICON = {
	rumor = "Interface\\GossipFrame\\GossipGossipIcon",
	bet = "Interface\\Icons\\INV_Misc_Coin_02",
	toast = "Interface\\Icons\\INV_Drink_04",
	home = "Interface\\Icons\\INV_Misc_Rune_01",
}
UI.ICON = ICON

-- the languages whose letters the font of the titles has
local FANCY = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }
local function Fancy(fs, size, flags)
	local loc = ns.locale or (GetLocale and GetLocale()) or "enUS"
	if FANCY[loc] then
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

local function RarityName(r)
	local x = ns.RARITY[r]
	return x and L[x.label] or "?"
end

-- A text in the colour of a rarity.
local function Colored(text, r)
	local x = ns.RARITY[r]
	local c = x and x.text or { 1, 1, 1 }
	return string.format(("|cff%02x%02x%02x%s|r"), math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), text)
end

-- A name without the realm of the player (the same realm), as the game shows it.
local function Short(name)
	return ns.Guild and ns.Guild:Short(name) or name
end

-- The windows beside the innkeeper's (or in the middle of the screen); (1.14.0) beside the counter, open with his window
-- (UI/Inns.lua).
local function Place(f)
	f:ClearAllPoints()
	local counter = ns.InnsUI and ns.InnsUI.panel
	local g = rawget(_G, "GossipFrame")
	if counter and counter:IsShown() then
		f:SetPoint("TOPLEFT", counter, "TOPRIGHT", 12, 0)
	elseif g and g.IsShown and g:IsShown() then
		f:SetPoint("TOPLEFT", g, "TOPRIGHT", 14, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 120, 40)
	end
end

-- Only one window beside the counter at a time: the rumor, the rumors to buy, the bet (1.14.0: the counter stays,
-- UI/Inns.lua; before, the loyalty card went too).
function UI:HideAll()
	if self.frame then
		self.frame:Hide()
	end
	if self.note then
		self.note:Hide()
	end
	if self.picker then
		self.picker:Hide()
	end
end

-- (1.14.0: the counter stays beside the innkeeper's window: nothing to hide)
local function HideCard()
end

-------------------------------------------------------------------------------
-- The rumors
-------------------------------------------------------------------------------
-- What an innkeeper says of a creature: the rarer it is, the more he makes of it.
local function RumorLine(r)
	if r >= 5 then
		return L["Rumor has it that %s, no less, wanders around %s... Today might be your day."]
	elseif r == 4 then
		return L["Between us: %s was spotted near %s. Keep your eyes open."]
	elseif r == 3 then
		return L["A hunter told me %s prowls around %s these days."]
	end
	return L["They say %s has been seen around %s lately."]
end

function UI.RumorText(card)
	local say = string.format(RumorLine(card.rarity), C:Name(card), C:SeriesName(card.series))
	-- (1.14.0: a lead, for days)
	local days = T.LeadDays and T:LeadDays() or 1
	return say .. "\n\n" .. string.format(((card.rarity or 0) >= 6 and L["(A lead: its card twice as easy to find, for %d days.)"]
		or L["(A lead: its card three times as easy to find, for %d days.)"]), days)
end

-- The note of the rumor of the day: the card it tells of (as the album shows it), its place.
local NW, NH = 236, 330

function UI:Note()
	if self.note then
		return self.note
	end
	local f = CreateFrame("Frame", "CuratorRumor", UIParent)
	CuratorOctoFull.SetSize(f, NW, NH)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	CuratorOctoFull.SetClampedToScreen(f, true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorRumor")
	f.paper = f:CreateTexture(nil, "BACKGROUND")
	f.paper:SetAllPoints()
	f.paper:SetTexture(MEDIA .. "PassportPage")
	f.title = f:CreateFontString(nil, "OVERLAY")
	Fancy(f.title, 17)
	f.title:SetPoint("TOP", 0, -16)
	f.title:SetTextColor(PAPER_INK[1], PAPER_INK[2], PAPER_INK[3])
	f.title:SetText(L["Rumor of the day"])
	f.card = ns.NewCard(f, "small")
	f.card:SetPoint("TOP", 0, -42)
	f.name = Text(f, 13, PAPER_INK, "CENTER")
	f.name:SetPoint("TOP", f.card, "BOTTOM", 0, -10)
	f.name:SetWidth(NW - 30)
	CuratorOctoFull.SetWordWrap(f.name, false)
	f.place = Text(f, 11, { 0.45, 0.33, 0.2 }, "CENTER")
	f.place:SetPoint("TOP", f.name, "BOTTOM", 0, -4)
	f.place:SetWidth(NW - 30)
	CuratorOctoFull.SetWordWrap(f.place, false)
	f.odds = Text(f, 11, { 0.12, 0.42, 0.2 }, "CENTER")
	f.odds:SetPoint("TOP", f.place, "BOTTOM", 0, -8)
	f.odds:SetWidth(NW - 30)
	CuratorOctoFull.SetWordWrap(f.odds, true)
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		UI.nt = (UI.nt or 0) + elapsed
		if f.card.Tick then
			f.card:Tick(UI.nt)
		end
	end)
	self.note = f
	return f
end

function UI:ShowRumor(card)
	local f = self:Note()
	HideCard()
	if self.frame then
		self.frame:Hide()
	end
	Place(f)
	f.card:SetCard(card, { owned = C:Owned(card) == true })
	f.card:ShowSide("front")
	S.Fit(f.name, Colored(C:Name(card), card.rarity), NW - 30, 13, 9)
	S.Fit(f.place, C:SeriesName(card.series), NW - 30, 11, 8)
	-- (1.14.0: a lead, its time left)
	local l = T.Lead and T:Lead(card)
	local left = l and math.max(0, (tonumber(l.u) or 0) - ((GetServerTime and CuratorOctoFull.ServerTime()) or time())) or 0
	f.odds:SetText(string.format(((card.rarity or 0) >= 6 and L["Twice as easy to find: %s left"] or L["Three times as easy to find: %s left"]), ns.Duration(left)))
	f:Show()
	ns.Play(ns.SND.page)
end

-- The line of the rumor clicked: what the innkeeper says (a rumor, or why none).
function UI:Rumor(npc)
	local card, why = T:Hear(npc)
	local G = ns.Gossip
	if card then
		if G then
			local text = UI.RumorText(card)
			-- (1.14.0, Word of Mouth, a talent of the Cartographer: his second rumor)
			local key2 = T.Rumors2 and T:Rumors2()[npc]
			local second = key2 and ns.Cards[key2]
			if second then
				text = text .. "\n\n" .. string.format(L["And one more, for a regular like you: %s, around %s."], Colored(C:Name(second), second.rarity), C:SeriesName(second.series))
			end
			G:Say(text)
		end
		self:ShowRumor(card)
	elseif G then
		if why == "rank" then
			G:Say(string.format(L["I keep my rumors for my regulars. Come back and see me: at %d stamps here, I will tell you what I hear."], I.RANKS[T.RUMOR_RANK].n))
		elseif why ~= "closed" then
			G:Say(L["Nothing new around here today."])
		end
	end
end

-------------------------------------------------------------------------------
-- The innkeeper's bet
-------------------------------------------------------------------------------
-- (1.14.0: 920 wide for the seven cards of a bet in a row, 680 before; after its test, his word, the scene redone: the
-- innkeeper behind his table, what he says over it; his prizes shown, gathered in a deck, shuffled, dealt face down
-- before the pick. The rules are the same: where each card lies is drawn at the pick, Tavern.lua: T:Pick.)
local BW, BH = 960, 640
local RW = 170 -- the buttons of the rarities, in a column on the left
local DOWN = 120 -- the table under the innkeeper: what lay on it before 1.14.0, this much lower
local LEFT = 52 -- the left of what lies on the table (its felt: from 34 to BW - 34)
local ROW_Y = -262 -- the cards of a bet on the table (their top)
local KEEPER = { 0.95, 0.9, 0.78 }

-- (1.14.0) The stake of a bet in a line: "2 × Chicken" (its copies bet; a bet made before took one: its name alone),
-- in the colour of its rarity (colored).
local function StakeName(card, m, colored)
	local name = colored and Colored(C:Name(card), card.rarity) or C:Name(card)
	m = tonumber(m) or 1
	return m > 1 and (m .. " \195\151 " .. name) or name
end

-- The places of the cards of a deal of n cards on the table (x of their left), their scale: seven in a row on its felt
-- (eight with Small Stake, a little smaller).
function UI.Places(n)
	local k = n > T.BET_CARDS and 0.9 or 1
	local cw = ns.CARD_SIZES.small[1] * k
	local gap = n > T.BET_CARDS and 6 or 10
	local x0 = (BW - (n * cw + (n - 1) * gap)) / 2
	local out = {}
	for i = 1, n do
		out[i] = (x0 + (i - 1) * (cw + gap)) / k
	end
	return out, k, cw
end

-- What the innkeeper says over his table (and in his window, when it is open).
function UI:KeeperSay(text, gossip)
	local f = self.frame
	if not f then
		return
	end
	f.speech:SetText(text or "")
	f.speech:SetAlpha(0)
	ns.Tween(0.25, function(e)
		f.speech:SetAlpha(e)
	end, nil, nil, UI)
	if gossip and ns.Gossip and text then
		ns.Gossip:Say(text)
	end
end

-- The innkeeper behind his table: his own model (the one the player talks to), else the creature of his card.
function UI:Keeper(npc)
	local m = self.frame.keeper
	m:Show()
	if m.ClearModel then
		pcall(m.ClearModel, m)
	end
	local G = ns.Gossip
	local shown = false
	if G and G.open and G.npc == npc and m.SetUnit then
		shown = pcall(m.SetUnit, m, "npc")
	end
	if not shown then
		local card = I:CardOf(npc)
		if card and card.display and card.display > 0 and m.SetDisplayInfo then
			shown = pcall(m.SetDisplayInfo, m, card.display)
		end
	end
	if not shown then
		m:Hide()
		return
	end
	if m.SetPortraitZoom then
		pcall(m.SetPortraitZoom, m, 0.55)
	end
	if m.SetRotation then
		pcall(m.SetRotation, m, 0.35)
	end
	self:KeeperAnim(0)
end

-- An animation of the innkeeper: 0 standing, 60 talking, 68 cheering, 66 bowing (the client: Model:SetAnimation).
function UI:KeeperAnim(id)
	local m = self.frame and self.frame.keeper
	if m and m:IsShown() and m.SetAnimation then
		pcall(m.SetAnimation, m, id)
	end
end

function UI:Frame()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorTavernBet", BW, BH)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	CuratorOctoFull.SetClampedToScreen(f, true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorTavernBet")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	if f.SetTitle then
		f:SetTitle(L["The innkeeper's bet"])
	end
	CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
		f:Hide()
	end)
	f.drag = S.DragBar(f, 22)
	-- the room: the wall behind the innkeeper, his table under the light of a lamp
	f.wall = f:CreateTexture(nil, "BACKGROUND", nil, 1)
	f.wall:SetPoint("TOPLEFT", 10, -24)
	f.wall:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -10, -176)
	CuratorOctoFull.ColorTexture(f.wall, 0.09, 0.06, 0.035, 0.92)
	f.lamp = f:CreateTexture(nil, "BACKGROUND", nil, 2)
	f.lamp:SetTexture(MEDIA .. "Glow")
	f.lamp:SetBlendMode("ADD")
	f.lamp:SetVertexColor(1, 0.72, 0.36)
	f.lamp:SetAlpha(0.35)
	CuratorOctoFull.SetSize(f.lamp, 420, 300)
	f.lamp:SetPoint("CENTER", f, "TOPLEFT", 100, -110)
	f.felt = f:CreateTexture(nil, "BACKGROUND", nil, 3)
	f.felt:SetPoint("TOPLEFT", 10, -172)
	f.felt:SetPoint("BOTTOMRIGHT", -10, 10)
	f.felt:SetTexture(MEDIA .. "TavernTable")
	-- the innkeeper and what he says
	local m = CreateFrame("PlayerModel", nil, f)
	CuratorOctoFull.SetSize(m, 150, 150)
	m:SetPoint("TOPLEFT", 26, -24)
	m:SetFrameLevel(f:GetFrameLevel() + 2)
	f.keeper = m
	f.bubble = CreateFrame("Frame", nil, f)
	f.bubble:SetPoint("TOPLEFT", 190, -42)
	f.bubble:SetPoint("TOPRIGHT", -28, -42)
	f.bubble:SetHeight(108)
	f.bubble.bg = f.bubble:CreateTexture(nil, "BACKGROUND")
	f.bubble.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.bubble.bg, 0, 0, 0, 0.42)
	f.bubble.edge = f.bubble:CreateTexture(nil, "BORDER")
	f.bubble.edge:SetPoint("TOPLEFT", -1, 1)
	f.bubble.edge:SetPoint("BOTTOMLEFT", -1, -1)
	f.bubble.edge:SetWidth(3)
	CuratorOctoFull.ColorTexture(f.bubble.edge, 1, 0.78, 0.36, 0.8)
	f.name = f:CreateFontString(nil, "OVERLAY")
	Fancy(f.name, 16)
	f.name:SetTextColor(1, 0.82, 0.36)
	f.name:SetPoint("BOTTOMLEFT", f.bubble, "TOPLEFT", 4, 4)
	f.speech = Text(f.bubble, 13, KEEPER, "LEFT")
	f.speech:SetPoint("TOPLEFT", 14, -12)
	f.speech:SetPoint("BOTTOMRIGHT", -14, 10)
	CuratorOctoFull.SetWordWrap(f.speech, true)
	if f.speech.SetJustifyV then
		f.speech:SetJustifyV("MIDDLE")
	end
	-- (the rules of the bet, as he says them: kept as the intro of the window)
	f.intro = f.speech
	f.intro:SetText(L["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"])
	-- the choice: the rarity (a column), the card bet (its card), what the innkeeper puts down
	local ch = CreateFrame("Frame", nil, f)
	ch:SetAllPoints()
	f.choose = ch
	ch.rar = {}
	for r = 1, T.BET_TOP do
		local r = r; local b = S.Button(ch, RarityName(r), RW, 26)
		b:SetPoint("TOPLEFT", LEFT, -118 - DOWN - (r - 1) * 32)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			ns.Play(ns.SND.click)
			UI:SetRarity(r)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(RarityName(r), unpack(ns.RARITY[r].text))
			if (self.n or 0) > 0 then
				GameTooltip:AddLine(string.format(L["Duplicates to bet: %d"], self.n), 1, 1, 1)
			else
				GameTooltip:AddLine(L["No duplicate of this rarity."], 0.7, 0.7, 0.7)
			end
			if self.noAlbum then
				GameTooltip:AddLine(L["The album of this inn has no card of this rarity."], 1, 0.4, 0.4, true)
			end
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		ch.rar[r] = b
	end
	local mid = LEFT + RW + 24 + 56
	ch.label = Text(ch, 12, GOLD, "CENTER")
	ch.label:SetPoint("TOP", ch, "TOPLEFT", mid, -114 - DOWN)
	ch.label:SetText(string.format(L["Your stake: %d copies"], T:StakeCount()))
	ch.stake = ns.NewCard(ch, "small")
	ch.stake:SetPoint("TOP", ch, "TOPLEFT", mid, -132 - DOWN)
	ch.other = S.Button(ch, L["Another card"], 126, 22)
	ch.other:SetPoint("TOP", ch.stake, "BOTTOM", 0, -8)
	CuratorOctoFull.SetScript(ch.other, "OnClick", function()
		ns.Play(ns.SND.click)
		UI:NextStake()
	end)
	local rx = mid + 56 + 22
	local rw = BW - LEFT - rx
	ch.head = Text(ch, 13, GOLD, "LEFT")
	ch.head:SetPoint("TOPLEFT", rx, -132 - DOWN)
	ch.head:SetWidth(rw)
	CuratorOctoFull.SetWordWrap(ch.head, false)
	S.Fit(ch.head, L["The innkeeper puts face down:"], rw, 13, 9)
	ch.line1 = Text(ch, 14, { 1, 1, 1 }, "LEFT")
	ch.line1:SetPoint("TOPLEFT", ch.head, "BOTTOMLEFT", 8, -10)
	ch.line1:SetWidth(rw - 8)
	ch.line2 = Text(ch, 14, { 1, 1, 1 }, "LEFT")
	ch.line2:SetPoint("TOPLEFT", ch.line1, "BOTTOMLEFT", 0, -6)
	ch.line2:SetWidth(rw - 8)
	-- (1.12.0) the two that win nothing
	ch.line3 = Text(ch, 14, { 1, 0.45, 0.4 }, "LEFT")
	ch.line3:SetPoint("TOPLEFT", ch.line2, "BOTTOMLEFT", 0, -6)
	ch.line3:SetWidth(rw - 8)
	ch.album = Text(ch, 12, { 0.85, 0.85, 0.85 }, "LEFT")
	ch.album:SetPoint("TOPLEFT", ch.line3, "BOTTOMLEFT", -8, -12)
	ch.album:SetWidth(rw)
	CuratorOctoFull.SetWordWrap(ch.album, true)
	ch.copies = Text(ch, 11, { 0.7, 0.7, 0.7 }, "LEFT")
	ch.copies:SetPoint("TOPLEFT", LEFT, -332 - DOWN)
	ch.copies:SetWidth(BW - 2 * LEFT)
	CuratorOctoFull.SetWordWrap(ch.copies, true)
	ch.go = S.Button(ch, L["Bet two copies"], 200, 30)
	ch.go:SetPoint("BOTTOMRIGHT", -34, 30)
	CuratorOctoFull.SetScript(ch.go, "OnClick", function()
		UI:Go()
	end)
	-- (1.13.0) the copy bet: the least precious, or the one chosen (UI/Copies.lua); 1.14.0: the two copies
	ch.copy = S.Button(ch, L["Choose the copies"], 170, 22)
	ch.copy:SetPoint("RIGHT", ch.go, "LEFT", -12, 0)
	CuratorOctoFull.SetScript(ch.copy, "OnClick", function()
		UI:ChooseStakeCopy()
	end)
	ch.none = Text(ch, 13, { 0.85, 0.85, 0.85 }, "CENTER")
	ch.none:SetPoint("CENTER", 0, -30 - DOWN / 2)
	ch.none:SetWidth(BW - 80)
	CuratorOctoFull.SetWordWrap(ch.none, true)
	-- the cards on the table (1.12.0: five, two of them win nothing; 1.14.0: seven, four of them win nothing)
	local pk = CreateFrame("Frame", nil, f)
	pk:SetAllPoints()
	pk:Hide()
	f.pick = pk
	pk.cards = {}
	local cw, ch2 = ns.CARD_SIZES.small[1], ns.CARD_SIZES.small[2]
	local xs = UI.Places(T.BET_CARDS)
	-- (1.14.0: a card more with Small Stake, a talent of the Gambler)
	for i = 1, T.BET_CARDS + 1 do
		local i = i; local c = ns.NewCard(pk, "small")
		c:SetPoint("TOPLEFT", xs[i] or xs[CuratorOctoFull.Length(xs)], ROW_Y)
		-- (nothing under this one: an empty mug)
		c.trap = CreateFrame("Frame", nil, c)
		c.trap:SetAllPoints()
		c.trap:SetFrameLevel(c:GetFrameLevel() + 20)
		c.trap:Hide()
		c.trap.shade = c.trap:CreateTexture(nil, "ARTWORK")
		c.trap.shade:SetPoint("TOPLEFT", 6, -6)
		c.trap.shade:SetPoint("BOTTOMRIGHT", -6, 6)
		CuratorOctoFull.ColorTexture(c.trap.shade, 0.16, 0.06, 0.02, 0.84)
		c.trap.icon = c.trap:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.SetSize(c.trap.icon, 54, 54)
		c.trap.icon:SetPoint("CENTER", 0, 12)
		c.trap.icon:SetTexture("Interface\\Icons\\INV_Drink_04")
		c.trap.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		c.trap.text = Text(c.trap, 15, { 1, 0.45, 0.4 }, "CENTER")
		c.trap.text:SetPoint("TOP", c.trap.icon, "BOTTOM", 0, -8)
		c.trap.text:SetWidth(cw - 16)
		c.trap.text:SetText(L["Nothing!"])
		c.trap.h = ch2
		CuratorOctoFull.SetScript(c, "OnClick", function()
			if UI.state == "dealing" then
				UI:EndDeal()
			else
				UI:PickCard(i)
			end
		end)
		CuratorOctoFull.SetScript(c, "OnEnter", function(self)
			if UI.state == "pick" then
				self.glow:SetVertexColor(1, 0.82, 0.4)
				self.glow:SetAlpha(0.7)
				UI:Lift(self, true)
			end
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function(self)
			if UI.state == "pick" then
				self.glow:SetAlpha(0)
				UI:Lift(self, false)
			end
		end)
		pk.cards[i] = c
	end
	-- (the deal goes faster with a click on the table)
	pk:EnableMouse(true)
	CuratorOctoFull.SetScript(pk, "OnMouseDown", function()
		if UI.state == "dealing" then
			UI:EndDeal()
		end
	end)
	-- (1.14.0, Gambler's Eye: one of the cards told before the pick, over it)
	pk.eye = Text(pk, 12, { 0.85, 0.66, 1 }, "CENTER")
	pk.eye:SetWidth(cw + 40)
	pk.eye:Hide()
	pk.status = Text(pk, 15, GOLD, "CENTER")
	pk.status:SetPoint("TOP", 0, ROW_Y - ch2 - 22)
	pk.status:SetWidth(BW - 48)
	pk.sub = Text(pk, 11, { 0.85, 0.85, 0.85 }, "CENTER")
	pk.sub:SetPoint("TOP", pk.status, "BOTTOM", 0, -8)
	pk.sub:SetWidth(BW - 48)
	pk.done = S.Button(pk, L["Close"], 140, 26)
	pk.done:SetPoint("BOTTOM", 0, 26)
	CuratorOctoFull.SetScript(pk.done, "OnClick", function()
		f:Hide()
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		UI.t = (UI.t or 0) + elapsed
		if pk:IsShown() then
			for _, c in ipairs(pk.cards) do
				if c.Tick then
					c:Tick(UI.t)
				end
			end
		elseif ch.stake:IsShown() and ch.stake.Tick then
			ch.stake:Tick(UI.t)
		end
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		ns.CancelOwner(UI)
		if UI.state == "flip" or UI.state == "dealing" then
			UI.state = "done"
		end
        local counter = f.returnCounter
        f.returnCounter = nil
        local gossip = ns.Gossip
        if gossip and gossip.open then
            if counter and gossip.npc == counter.npc then counter:Show() end
            gossip:Fallback()
        end
	end)
	self.frame = f
	return f
end

-- The table of the bet, at this innkeeper: the choice of the duplicate, or the cards of a bet waiting. (1.14.0: in the
-- middle of the screen, his counter beside his window.)
function UI:IsBetOpen()
    return self.frame and self.frame:IsShown()
end

function UI:OpenBet(npc)
	local d = T:Deal()
	if not d and T:BetToday() then
		if ns.Gossip then
			ns.Gossip:Say(string.format(L["One bet a day! Come back in %s."], ns.Duration(I:NextIn())))
		end
		return
	end
	local f = self:Frame()
	ns.CancelOwner(UI)
	if self.note then
		self.note:Hide()
	end
	if self.picker then
		self.picker:Hide()
	end
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
	self.npc = npc
	S.Fit(f.name, I:Name(npc), 170, 16, 11)
	self:Keeper(npc)
	-- (1.14.0: the terms of the bet, the talents of the Gambler, High Table and Small Stake, as they change them)
	local TL = ns.Talents
	if TL and TL:Has("hightable") then
		f.intro:SetText(L["High Table: bet three duplicates of the same card. I put seven cards face down, two of the rarity above (epic at most), one of its rarity, and four that win nothing. Pick one!"])
	elseif TL and TL:Has("lowstake") then
		f.intro:SetText(L["Small Stake: bet one duplicate. I put eight cards face down, one of the rarity above (epic at most), two of its rarity, and five that win nothing. Pick one!"])
	else
		f.intro:SetText(L["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"])
	end
	f.speech:SetAlpha(1)
	if d then
		self:ShowPick(d)
	else
		self:ShowChoose(npc)
	end
    local counter = ns.InnsUI and ns.InnsUI.panel
    if counter and counter:IsShown() then
        f.returnCounter = counter
        counter:Hide()
    end
    f:Show()
    if ns.Gossip then ns.Gossip:Fallback() end
    ns.Play(ns.SND.open)
end

function UI:ShowChoose(npc)
	local f = self.frame
	local ch = f.choose
	self.state = "choose"
	ch:Show()
	f.pick:Hide()
	local first
	for r, b in ipairs(ch.rar) do
		local n = 0
		for _, it in ipairs(T:Stakes(r, T:StakeCount())) do
			n = n + it.spare
		end
		-- (1.14.0: the copies to spare of the cards that can be bet, two of them at least; High Table, three; Small
		-- Stake, one)
		b.n = n
		b.noAlbum = not T:CanBet(npc, r)
		b.can = n > 0 and not b.noAlbum
		b:SetText(string.format(("%s (%d)"), RarityName(r), n))
		CuratorOctoFull.SetEnabled(b, b.can)
		if b.can and not first then
			first = r
		end
	end
	-- (the rarity of the last bet, when it can be bet again)
	local r = (self.rarity and ch.rar[self.rarity] and ch.rar[self.rarity].can) and self.rarity or first
	local any = r ~= nil
	-- (1.14.0: Choose the copies too, with nothing to bet)
	for _, k in ipairs({ "label", "stake", "other", "head", "line1", "line2", "line3", "album", "copies", "go", "copy" }) do
		CuratorOctoFull.SetShown(ch[k], any)
	end
	CuratorOctoFull.SetShown(ch.none, not any)
	if any then
		self:SetRarity(r)
	else
		if T:StakeCount() == T.BET_STAKE then
			ch.none:SetText(L["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"])
		else
			ch.none:SetText(string.format(L["A bet takes %d copies to spare of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"], T:StakeCount()))
		end
	end
end

function UI:SetRarity(r)
	local ch = self.frame.choose
	self.rarity = r
	for k, b in ipairs(ch.rar) do
		if k == r then
			b:LockHighlight()
		else
			b:UnlockHighlight()
		end
	end
	self.stakes = T:Stakes(r, T:StakeCount())
	self.si = 1
	self:PaintStake()
end

function UI:NextStake()
	if not self.stakes or CuratorOctoFull.Length(self.stakes) < 2 then
		return
	end
	self.si = (CuratorOctoFull.Mod(self.si , CuratorOctoFull.Length(self.stakes))) + 1
	self:PaintStake()
end

function UI:PaintStake()
	local ch = self.frame.choose
	local r = self.rarity
	local it = self.stakes and self.stakes[self.si]
	if not it then
		ch.stake:Hide()
		CuratorOctoFull.SetEnabled(ch.go, false)
		return
	end
	local e = C:Entry(it.card)
	ch.stake:SetCard(it.card, { owned = true, count = e and e.n or nil })
	ch.stake:ShowSide("front")
	ch.stake:Show()
	CuratorOctoFull.SetEnabled(ch.other, CuratorOctoFull.Length(self.stakes) > 1)
	local up = T:Up(r)
	-- (1.14.0, the Gambler: High Table, the card of the rarity above twice; Small Stake, a card more that wins nothing)
	local TL = ns.Talents
	local high = TL ~= nil and TL:Has("hightable")
	local traps = T.BET_TRAPS + ((TL ~= nil and TL:Has("lowstake")) and 1 or 0)
	if up > r then
		ch.line1:SetText((high and "2" or "1") .. " \195\151 " .. Colored(RarityName(up), up))
		ch.line2:SetText((high and "1" or "2") .. " \195\151 " .. Colored(RarityName(r), r))
	else
		ch.line1:SetText("3 \195\151 " .. Colored(RarityName(r), r))
		ch.line2:SetText("")
	end
	-- (1.12.0) those that win nothing (1.14.0: four, under the line before them: an epic card has one line of cards)
	ch.line3:SetText(traps .. " \195\151 " .. L["nothing: the innkeeper keeps your stake"])
	ch.label:SetText(string.format(L["Your stake: %d copies"], T:StakeCount()))
	ch.line3:ClearAllPoints()
	ch.line3:SetPoint("TOPLEFT", up > r and ch.line2 or ch.line1, "BOTTOMLEFT", 0, -6)
	local album = I:Album(self.npc)
	ch.album:SetText(string.format(L["From the album: %s"], album and C:SeriesName(album) or "?"))
	local text = string.format(L["%s: %d copies to spare (one copy always stays in your album)."], C:Name(it.card), it.spare)
	-- (1.13.0: the copy bet, the one chosen while it is still free, else the least precious; 1.14.0: the two copies bet,
	-- those chosen while they are still free, else the least precious)
	local CP, CU = ns.Copies, ns.CopiesUI
	if CP and CU then
		if self.stakeKey ~= it.card.key or not (self.stakeIds and CP:Chosen(it.card.key, nil, self.stakeIds, T:StakeCount())) then
			self.stakeKey, self.stakeIds = it.card.key, nil
		end
		local parts = {}
		for _, id in ipairs(self:StakeCopies(it.card)) do
			local rec = CP:Get(it.card.key, id)
			if rec then
				parts[CuratorOctoFull.Length(parts) + 1] = CU:Label(it.card, rec) .. " (" .. CU:Short(it.card, rec, true) .. ")"
			end
		end
		if CuratorOctoFull.Length(parts) > 0 then
			text = text .. "\n" .. string.format(L["The copies bet: %s"], table.concat(parts, ", "))
		end
	end
	ch.copies:SetText(text)
	CuratorOctoFull.SetShown(ch.copy, CU ~= nil)
	CuratorOctoFull.SetEnabled(ch.go, true)
end

-- (1.14.0) The copies a bet of this card takes now: those chosen (still free), then the least precious, two of them.
function UI:StakeCopies(card)
	local CP = ns.Copies
	local out, seen = {}, {}
	if not CP then
		return out
	end
	local m = T:StakeCount()
	if self.stakeKey == card.key and self.stakeIds and CP:Chosen(card.key, nil, self.stakeIds, m) then
		for _, id in ipairs(self.stakeIds) do
			out[CuratorOctoFull.Length(out) + 1] = id
			seen[id] = true
		end
	end
	for _, r in ipairs(CP:Free(card.key, nil)) do
		if CuratorOctoFull.Length(out) >= m then
			break
		end
		if not seen[r.i] then
			out[CuratorOctoFull.Length(out) + 1] = r.i
			seen[r.i] = true
		end
	end
	return out
end

-- (1.13.0) The copy bet chosen in the chooser of copies (1.14.0: the two copies).
function UI:ChooseStakeCopy()
	local it = self.stakes and self.stakes[self.si]
	if not (it and ns.CopiesUI) or self.state ~= "choose" then
		return
	end
	ns.CopiesUI:OpenPicker({ card = it.card, finish = nil, n = T:StakeCount(), ids = self.stakeKey == it.card.key and self.stakeIds or nil,
		owner = self.frame, title = string.format(L["Which copies of %s to bet?"], C:Name(it.card)),
		done = function(ids)
			UI.stakeKey, UI.stakeIds = it.card.key, ids
			UI:PaintStake()
		end })
end

-- The duplicates bet: the innkeeper shows his prizes, shuffles them and deals them face down.
function UI:Go()
	local it = self.stakes and self.stakes[self.si]
	if not it or self.state ~= "choose" then
		return
	end
	local d, why = T:Bet(self.npc, self.rarity, it.card, self.stakeKey == it.card.key and self.stakeIds or nil)
	if not d then
		if why == "done" and ns.Gossip then
			ns.Gossip:Say(string.format(L["One bet a day! Come back in %s."], ns.Duration(I:NextIn())))
		end
		self.frame:Hide()
		return
	end
	ns.Play(ns.SND.coins)
	self:ShowPick(d, true)
end

-------------------------------------------------------------------------------
-- (1.14.0) The deal: the prizes face up in a row (the cards of the deal, the empty mugs), gathered in a deck in the
-- middle of the table, shuffled (the deck cut in two, the halves riffled together, three times), dealt face down.
-- Nothing of it is drawn: where each card lies is drawn at the pick (T:Pick). A click on the table: at once.
-------------------------------------------------------------------------------
local Places = UI.Places

-- A card moved on the table: to x, y (points of its scale), in dur seconds (then done).
local function Move(c, x, y, dur, done, delay)
	local x0, y0 = c.px or x, c.py or y
	c.px, c.py = x, y
	if not dur or dur <= 0 then
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", x, y)
		if done then
			done()
		end
		return
	end
	ns.Tween(dur, function(e)
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", x0 + (x - x0) * e, y0 + (y - y0) * e)
	end, function()
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", x, y)
		if done then
			done()
		end
	end, ns.Ease and ns.Ease.outQuad, UI, delay)
end

-- A card under the mouse while one picks: it lifts a little.
function UI:Lift(c, up)
	if not (c.px and c.py) then
		return
	end
	c:ClearAllPoints()
	c:SetPoint("TOPLEFT", c.px, c.py + (up and 8 or 0))
end

function UI:ShowPick(d, fresh)
	local f = self.frame
	local pk = f.pick
	f.choose:Hide()
	pk:Show()
	self.deal = d
	local any
	for _, key in ipairs(d.c) do
		any = any or (key ~= T.TRAP and ns.Cards[key]) or nil
	end
	-- (seven cards; five for a bet made in 1.12.0 and 1.13.0, three before: in the middle; 1.14.0: eight with Small
	-- Stake, a little smaller)
	local n = CuratorOctoFull.Length(d.c)
	local xs, k = Places(n)
	self.places, self.pk = xs, k
	for i, c in ipairs(pk.cards) do
		c.trap:Hide()
		c.glow:SetAlpha(0)
		if i > n then
			c:Hide()
		else
			c:SetScale(k)
			c:SetAlpha(1)
			c:Show()
		end
	end
	pk.eye:Hide()
	pk.done:Hide()
	local stake = ns.Cards[d.k]
	pk.sub:SetText(stake and string.format(L["Your stake: %s"], StakeName(stake, d.m, true)) or "")
	pk.status:SetText("")
	self.state = "dealing"
	if fresh then
		self:ShowPrizes(d, any)
	else
		-- (a bet waiting since another time: dealt again, face down)
		self:Gather(d, any, 0)
	end
end

-- The prizes, face up in a row: the cards of the deal, then the empty mugs.
function UI:ShowPrizes(d, any)
	local pk = self.frame.pick
	local n = CuratorOctoFull.Length(d.c)
	local y = ROW_Y / self.pk
	local count, traps = {}, 0
	for i, key in ipairs(d.c) do
		local i, key = i, key; local c = pk.cards[i]
		Move(c, self.places[i], y)
		if key ~= T.TRAP and ns.Cards[key] then
			local card = ns.Cards[key]
			c:SetCard(card, { owned = C:Owned(card) == true })
			c:ShowSide("front")
			count[card.rarity] = (count[card.rarity] or 0) + 1
		else
			traps = traps + 1
			c:SetCard(any, { owned = true })
			c:SetBack()
			c:ShowSide("back")
			c.trap:SetAlpha(1)
			c.trap:Show()
		end
		c:SetAlpha(0)
		ns.Tween(0.25, function(e)
			c:SetAlpha(e)
		end, nil, nil, UI, (i - 1) * 0.08)
	end
	ns.Play(ns.SND.whoosh)
	self:KeeperAnim(60)
	-- (the prizes by their rarities, the highest first: a card not found yet keeps its secret, as in the album)
	local prizes = {}
	for r = CuratorOctoFull.Length(ns.RARITY), 1, -1 do
		if count[r] then
			prizes[CuratorOctoFull.Length(prizes) + 1] = count[r] .. " \195\151 " .. Colored(RarityName(r), r)
		end
	end
	self:KeeperSay(string.format(L["Here is what is on the table: %s, and %d empty mugs that win nothing. Watch closely..."], table.concat(prizes, ", "), traps))
	ns.Delay(2.4, function()
		if self.state == "dealing" then
			self:Gather(d, any, 0.45)
		end
	end, UI)
end

-- The cards gathered in a deck in the middle, face down, then shuffled, then dealt.
function UI:Gather(d, any, dur)
	local pk = self.frame.pick
	local n = CuratorOctoFull.Length(d.c)
	local cx = (BW / 2) / self.pk - ns.CARD_SIZES.small[1] / 2
	local y = ROW_Y / self.pk
	for i = 1, n do
		local c = pk.cards[i]
		c.trap:Hide()
		if c.facing == "front" and dur > 0 then
			c:SetBack()
			c:Flip(dur * 0.8, nil, nil, UI)
		else
			c:SetCard(any, { owned = true })
			c:SetBack()
			c:ShowSide("back")
		end
		-- (a deck: each card a little over the one before)
		Move(c, cx + (i - n / 2) * 0.8, y + i * 0.8, dur, nil, (dur > 0) and (i - 1) * 0.04 or nil)
	end
	if dur > 0 then
		ns.Play(ns.SND.cardFlip)
		self:KeeperSay(L["I gather them, I shuffle them..."])
	end
	ns.Delay(dur + 0.35, function()
		if self.state == "dealing" then
			self:Shuffle(d, any, dur > 0 and 3 or 1, 1)
		end
	end, UI)
end

-- The deck cut in two, its halves riffled together (rounds times), then the deal.
function UI:Shuffle(d, any, rounds, round)
	local pk = self.frame.pick
	local n = CuratorOctoFull.Length(d.c)
	local cx = (BW / 2) / self.pk - ns.CARD_SIZES.small[1] / 2
	local y = ROW_Y / self.pk
	local CUT = 80
	for i = 1, n do
		local c = pk.cards[i]
		local side = (CuratorOctoFull.Mod(i , 2) == 0) and -1 or 1
		Move(c, cx + side * CUT + i * 0.8, y + i * 0.8, 0.16)
	end
	ns.Delay(0.2, function()
		if self.state ~= "dealing" then
			return
		end
		ns.Play(ns.SND.cardFlip)
		for i = 1, n do
			local c = pk.cards[i]
			Move(c, cx + (i - n / 2) * 0.8, y + i * 0.8, 0.12, nil, (i - 1) * 0.035)
		end
		ns.Delay(0.12 + n * 0.035 + 0.12, function()
			if self.state ~= "dealing" then
				return
			end
			if round < rounds then
				self:Shuffle(d, any, rounds, round + 1)
			else
				self:DealCards(d)
			end
		end, UI)
	end, UI)
end

-- The cards dealt face down, one after the other, to their places.
function UI:DealCards(d)
	local pk = self.frame.pick
	local n = CuratorOctoFull.Length(d.c)
	local y = ROW_Y / self.pk
	for i = 1, n do
		local i = i; local c = pk.cards[i]
		Move(c, self.places[i], y, 0.22, function()
			ns.Play(ns.SND.cardLand)
		end, (i - 1) * 0.12)
	end
	ns.Delay(0.22 + (n - 1) * 0.12 + 0.05, function()
		if self.state == "dealing" then
			self:EndDeal()
		end
	end, UI)
end

-- The deal done (or skipped): the cards face down in their places, the pick.
function UI:EndDeal()
	local d = self.deal
	if not d or self.state ~= "dealing" then
		return
	end
	ns.CancelOwner(UI)
	local pk = self.frame.pick
	local n = CuratorOctoFull.Length(d.c)
	local any
	for _, key in ipairs(d.c) do
		any = any or (key ~= T.TRAP and ns.Cards[key]) or nil
	end
	local y = ROW_Y / self.pk
	for i, c in ipairs(pk.cards) do
		if i <= n then
			c.trap:Hide()
			-- (1.12.0) the cards of the innkeeper, all the same face down: the back of the boosters of the zones, whatever
			-- their album (a back of a dungeon or of Hallow's End would tell what is under it: Card:SetBack)
			c:SetCard(any, { owned = true })
			c:SetBack()
			c:ShowSide("back")
			c:SetFlipSize(c.W, c.H)
			c:SetAlpha(1)
			Move(c, self.places[i], y)
		end
	end
	self.state = "pick"
	self:KeeperAnim(0)
	self.frame.speech:SetAlpha(1)
	self:KeeperSay(L["Your bet is on the table. Pick a card!"], true)
	-- (1.14.0, Gambler's Eye: the card told, its rarity over it)
	local eye = type(d.eye) == "table" and tonumber(d.eye.p) and tonumber(d.eye.i) and d.eye or nil
	local told = eye and pk.cards[math.max(1, math.min(n, eye.p))]
	CuratorOctoFull.SetShown(pk.eye, told ~= nil)
	if told then
		local key = d.c[math.max(1, math.min(n, eye.i))]
		local card = key ~= T.TRAP and ns.Cards[key] or nil
		pk.eye:ClearAllPoints()
		pk.eye:SetPoint("BOTTOM", told, "TOP", 0, 6)
		pk.eye:SetText(string.format(L["Gambler's Eye: %s"], card and Colored(RarityName(card.rarity), card.rarity) or ("|cffff7066" .. L["nothing"] .. "|r")))
	end
	pk.status:SetText(L["Pick a card!"])
end

-- (1.12.0) A card that wins nothing, shown: an empty mug over its back.
local function Nothing(c, alpha, owner)
	c.trap:SetAlpha(0)
	c.trap:Show()
	ns.Tween(0.3, function(e)
		c.trap:SetAlpha(e * (alpha or 1))
	end, nil, nil, owner)
end

-- A card picked: turned over, then the others.
function UI:PickCard(i)
	if self.state ~= "pick" then
		return
	end
	local pk = self.frame.pick
	local res = T:Pick(i)
	if not res then
		self.state = "done"
		pk.status:SetText(L["Your duplicate is no longer there: the bet is off."])
		pk.sub:SetText("")
		pk.done:Show()
		return
	end
	self.state = "flip"
	local c = pk.cards[i]
	c.glow:SetAlpha(0)
	self:Lift(c, false)
	-- the others, once the one picked is seen
	pk.eye:Hide()
	local function Others()
		ns.Delay(0.5, function()
			for k, o in ipairs(pk.cards) do
				local k, o = k, o; if k ~= i and k <= CuratorOctoFull.Length(res.cards) then
					local card = res.cards[k]
					if card then
						o:SetCard(card, { owned = C:Owned(card) == true })
						o:SetBack()
						o:Flip(0.4, nil, function()
							o:SetAlpha(0.55)
						end, UI)
					else
						Nothing(o, 0.7, UI)
					end
				end
			end
			ns.Play(ns.SND.cardFlip)
			self:Result(res)
		end, UI)
	end
	if res.trap then
		-- (nothing under it: the card shakes)
		ns.Play(ns.SND.close)
		local x0, y0 = c.px or CuratorOctoFull.Select(4, c:GetPoint(1)), c.py or ROW_Y
		ns.Tween(0.35, function(e)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", x0 + math.sin(e * math.pi * 6) * 5 * (1 - e), y0)
		end, function()
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", x0, y0)
		end, nil, UI)
		Nothing(c, 1, UI)
		Others()
		return
	end
	c:SetCard(res.card, { owned = true, new = res.new, count = res.count })
	c:SetBack()
	ns.Play(ns.SND.cardFlip)
	c:Flip(0.45, nil, function()
		ns.Play(ns.SND.reveal[math.min(res.card.rarity, 5)] or ns.SND.cardLand)
		if res.up then
			local g = ns.RARITY[res.card.rarity].glow
			c.glow:SetVertexColor(g[1], g[2], g[3])
			ns.Tween(0.8, function(e)
				c.glow:SetAlpha(math.sin(e * math.pi) * 0.9)
			end, nil, nil, UI)
			if Hud and Hud.Burst then
				Hud.Burst(c, { g[1], g[2], g[3] }, 18, 110, 14)
			end
		end
		Others()
	end, UI)
end

function UI:Result(res)
	local pk = self.frame.pick
	self.state = "done"
	if res.trap then
		-- (1.12.0: nothing won; 1.14.0: four cards out of seven, two out of five for a bet made before)
		local traps = 0
		for _, card in ipairs(res.cards) do
			if not card then
				traps = traps + 1
			end
		end
		pk.status:SetText(string.format(L["Nothing! Your stake, %s, goes to the innkeeper."], StakeName(res.stake, res.m, true)))
		-- (1.14.0, Sore Loser: the stake given back)
		if res.back then
			pk.status:SetText(L["Nothing! But the innkeeper gives your stake back (Sore Loser)."])
		end
		pk.sub:SetText(string.format(L["%d cards out of %d win nothing. Better luck tomorrow!"], traps, CuratorOctoFull.Length(res.cards)))
		pk.done:Show()
		self:KeeperAnim(60)
		self:KeeperSay(L["Ha! The house wins. Come back tomorrow!"], true)
		return
	end
	local name = Colored(C:Name(res.card), res.card.rarity)
	if res.up then
		pk.status:SetText(string.format(L["Jackpot! %s is yours."], name))
	else
		pk.status:SetText(string.format(L["%s is yours."], name))
	end
	pk.sub:SetText(string.format(L["Your stake, %s, stays with the innkeeper."], StakeName(res.stake, res.m)))
	pk.done:Show()
	self:KeeperAnim(res.up and 68 or 66)
	self:KeeperSay(res.up and L["Well played! The house pays up."] or L["A bet is a bet! Come back tomorrow for another."], true)
end

-------------------------------------------------------------------------------
-- A toast
-------------------------------------------------------------------------------
function UI:Cheer(name, npc)
	local G = ns.Gossip
	if T:Cheer(name, npc) then
		if G then
			G:Say(string.format(L["You raise your glass to %s. If they raise theirs at this innkeeper within three minutes, a stamp more for each of you!"], Short(name)))
		end
	elseif G then
		G:Say(string.format(L["Your glass stays on the counter: %s cannot be reached."], Short(name)))
	end
end

function UI:Answer(name, npc)
	-- (what it does shows when it is done: TAVERN_CHEERS)
	if not T:Answer(name, npc) and ns.Gossip then
		ns.Gossip:Say(string.format(L["Too late: the glass of %s is empty. Another time!"], Short(name)))
	end
end

-------------------------------------------------------------------------------
-- (1.11.0) A rumor bought (Tavern.lua: T:Buy): the cards of his album the collection is missing, on a
-- parchment beside the innkeeper's window (the rarest first, a page at a time); one chosen, the rumor bought
-- with rubies: its card is twice as easy to find all day.
-------------------------------------------------------------------------------
local PW, PH = 300, 452
local PROWS, PROW_H = 11, 24

function UI:Picker()
	if self.picker then
		return self.picker
	end
	local f = CreateFrame("Frame", "CuratorRumorBuy", UIParent)
	CuratorOctoFull.SetSize(f, PW, PH)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	CuratorOctoFull.SetClampedToScreen(f, true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorRumorBuy")
	f.paper = f:CreateTexture(nil, "BACKGROUND")
	f.paper:SetAllPoints()
	f.paper:SetTexture(MEDIA .. "PassportPage")
	f.title = f:CreateFontString(nil, "OVERLAY")
	Fancy(f.title, 17)
	f.title:SetPoint("TOP", 0, -16)
	f.title:SetTextColor(PAPER_INK[1], PAPER_INK[2], PAPER_INK[3])
	f.title:SetText(L["Which creature?"])
	f.sub = Text(f, 11, PAPER_INK, "CENTER")
	f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -6)
	f.sub:SetWidth(PW - 40)
	CuratorOctoFull.SetWordWrap(f.sub, true)
	f.rows = {}
	for i = 1, PROWS do
		local i = i; local r = CreateFrame("Button", nil, f)
		CuratorOctoFull.SetSize(r, PW - 44, PROW_H - 2)
		r:SetPoint("TOP", f, "TOP", 0, -90 - (i - 1) * PROW_H)
		r.sel = r:CreateTexture(nil, "BACKGROUND")
		r.sel:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.sel, 0.55, 0.32, 0.1, 0.22)
		r.sel:Hide()
		r.hl = r:CreateTexture(nil, "HIGHLIGHT")
		r.hl:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.hl, 0.55, 0.32, 0.1, 0.12)
		r.gem = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.gem, 16, 16)
		r.gem:SetPoint("LEFT", 4, 0)
		r.name = Text(r, 12, PAPER_INK, "LEFT")
		r.name:SetPoint("LEFT", r.gem, "RIGHT", 6, 0)
		r.name:SetPoint("RIGHT", -4, 0)
		CuratorOctoFull.SetWordWrap(r.name, false)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			UI:PickRumor(self.card)
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			if self.card then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				ns.Links:AddLines(GameTooltip, self.card)
				GameTooltip:AddLine(L["Click to choose it"], 0.3, 1, 0.3)
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		f.rows[i] = r
	end
	f.empty = Text(f, 12, PAPER_INK, "CENTER")
	f.empty:SetPoint("TOP", 0, -150)
	f.empty:SetWidth(PW - 60)
	CuratorOctoFull.SetWordWrap(f.empty, true)
	f.pager = S.Pager(f)
	f.pager:SetPoint("BOTTOMRIGHT", -22, 70)
	CuratorOctoFull.SetScript(f.pager.prev, "OnClick", function()
		UI:PickerPage(-1)
	end)
	CuratorOctoFull.SetScript(f.pager.next, "OnClick", function()
		UI:PickerPage(1)
	end)
	f.price = Text(f, 12, PAPER_INK, "LEFT")
	f.price:SetPoint("BOTTOMLEFT", 24, 52)
	f.have = Text(f, 11, { 0.45, 0.33, 0.2 }, "LEFT")
	f.have:SetPoint("TOPLEFT", f.price, "BOTTOMLEFT", 0, -3)
	f.buy = ns.Hud.ClaimButton(f, 150, 30, L["Buy the rumor"])
	f.buy:SetPoint("BOTTOMRIGHT", -20, 18)
	CuratorOctoFull.SetScript(f.buy, "OnClick", function()
		UI:BuyChosen()
	end)
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -2, -2)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	self.picker = f
	return f
end

-- The parchment of the rumors to buy at this innkeeper (or what he says when there is none to buy).
function UI:BuyRumor(npc)
	local G = ns.Gossip
	local ok, why = T:CanBuy(npc)
	if not ok and why ~= "rubies" then
		if G then
			if why == "done" then
				local card = T:BoughtCard(npc)
				if card then
					G:Say(UI.RumorText(card))
					self:ShowRumor(card)
				end
			elseif why == "none" then
				G:Say(L["You already have every creature of these lands. I have nothing more to tell you!"])
			end
		end
		return
	end
	local f = self:Picker()
	HideCard()
	if self.frame then
		self.frame:Hide()
	end
	if self.note then
		self.note:Hide()
	end
	-- (1.14.0: a rumor bought is a lead too, for days)
	f.sub:SetText(string.format(L["Choose a card missing from this album: a lead for %d days, three times as easy to find (twice for a mythic card)."], T.LeadDays and T:LeadDays() or 3))
	self.pickNpc, self.pickCard, self.pickPage = npc, nil, 1
	self.pickList = T:Wanted(npc)
	Place(f)
	f:Show()
	ns.Play(ns.SND.page)
	if G then
		G:Say(L["Looking for a creature? For a few rubies, I can tell you where it was last seen."])
	end
	self:PaintPicker()
end

function UI:PickerPage(delta)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length((self.pickList or {})) / PROWS))
	self.pickPage = math.max(1, math.min(pages, (self.pickPage or 1) + delta))
	ns.Play(ns.SND.page)
	self:PaintPicker()
end

function UI:PickRumor(card)
	if not card then
		return
	end
	self.pickCard = card
	ns.Play(ns.SND.click)
	self:PaintPicker()
end

function UI:PaintPicker()
	local f = self.picker
	if not (f and f:IsShown()) then
		return
	end
	local RB = ns.Rubies
	local list = self.pickList or {}
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / PROWS))
	local page = math.max(1, math.min(pages, self.pickPage or 1))
	self.pickPage = page
	for i, r in ipairs(f.rows) do
		local card = list[(page - 1) * PROWS + i]
		r.card = card
		CuratorOctoFull.SetShown(r, card ~= nil)
		if card then
			r.gem:SetTexture(MEDIA .. "Gem" .. card.rarity)
			local ink = ns.RARITY[card.rarity] and ns.RARITY[card.rarity].ink or PAPER_INK
			r.name:SetText(C:Name(card))
			r.name:SetTextColor(ink[1], ink[2], ink[3])
			CuratorOctoFull.SetShown(r.sel, card == self.pickCard)
		end
	end
	CuratorOctoFull.SetShown(f.empty, CuratorOctoFull.Length(list) == 0)
	f.empty:SetText(L["You already have every creature of these lands. I have nothing more to tell you!"])
	CuratorOctoFull.SetShown(f.pager, pages > 1)
	f.pager:Set(page, pages, string.format(L["Page %d / %d"], page, pages))
	-- (1.11.0: its price with the talents, free once a day with the Scout's Gossip)
	local price = T:RumorPrice()
	f.price:SetText(price > 0 and string.format(L["Price: %s"], RB.Text(price, 14)) or string.format(L["Price: %s"], L["Free"]))
	local have = RB:Balance()
	f.have:SetText(string.format(L["Your rubies: %s"], RB.Text(have, 12)))
	local ok = self.pickCard ~= nil and T:CanBuy(self.pickNpc, self.pickCard)
	CuratorOctoFull.SetEnabled(f.buy, ok and true or false)
	f.buy:SetPulse(ok and true or false)
	if have < price then
		f.have:SetTextColor(0.62, 0.08, 0.05)
	else
		f.have:SetTextColor(0.45, 0.33, 0.2)
	end
end

-- The rumor of the card chosen, bought: the innkeeper tells it, its note shows.
function UI:BuyChosen()
	local npc, card = self.pickNpc, self.pickCard
	if not (npc and card) then
		return
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local got, why = T:Buy(npc, card)
	if not got then
		ns.Play(ns.SND.close)
		if why == "rubies" then
			ns.Print(L["Not enough rubies."])
		end
		self:PaintPicker()
		return
	end
	ns.Play(ns.SND.coins)
	if self.picker then
		self.picker:Hide()
	end
	if ns.Gossip then
		ns.Gossip:Say(UI.RumorText(got))
	end
	self:ShowRumor(got)
end

-------------------------------------------------------------------------------
-- The lines of Curator in the window of an innkeeper (after the loyalty card's)
-------------------------------------------------------------------------------
ns.Gossip:Provide("inn", function(npc)
	if not ns.db or type(npc) ~= "number" then
		return {}
	end
	local lines = {}
	-- (the rumors and the bet: from the album of his inn; an innkeeper Curator does not know has none)
	if I:Album(npc) then
		local _, heard = T:Rumor(npc)
		lines[CuratorOctoFull.Length(lines) + 1] = { text = heard == true and L["The rumor of the day"] or L["Any rumors?"], icon = ICON.rumor, click = function(id)
			UI:Rumor(id or npc)
		end }
		-- (1.11.0) a rumor about the card chosen, for rubies (once a day here: then, the rumor bought again)
		local bought = T:BoughtCard(npc)
		local text = bought and L["The rumor you paid for"]
			or (string.format(L["Ask about a creature you are looking for (%s)"], T:RumorPrice() > 0 and ns.Rubies.Text(T:RumorPrice(), 14) or L["Free"]))
		lines[CuratorOctoFull.Length(lines) + 1] = { text = text, icon = ns.Rubies.ICON, click = function(id)
			UI:BuyRumor(id or npc)
		end }
	end
	if T:Deal() then
		lines[CuratorOctoFull.Length(lines) + 1] = { text = L["The innkeeper's bet (your cards are waiting)"], icon = ICON.bet, click = function(id)
			UI:OpenBet(id or npc)
		end }
	elseif not T:BetToday() and I:Album(npc) then
		lines[CuratorOctoFull.Length(lines) + 1] = { text = L["The innkeeper's bet"], icon = ICON.bet, click = function(id)
			UI:OpenBet(id or npc)
		end }
	end
	if not T:ToastedToday() then
		local shown = {}
		for _, inv in ipairs(T:Invites(npc)) do
			local _, inv = _, inv; shown[inv.name] = true
			lines[CuratorOctoFull.Length(lines) + 1] = { text = string.format(L["Raise your glass to %s"], Short(inv.name)), icon = ICON.toast, click = function(id)
				UI:Answer(inv.name, id or npc)
			end }
		end
		local n = 0
		for _, name in ipairs(T:Mates()) do
			local _, name = _, name; if not shown[name] and n < 4 then
				n = n + 1
				lines[CuratorOctoFull.Length(lines) + 1] = { text = string.format(L["Raise a glass with %s"], Short(name)), icon = ICON.toast, click = function(id)
					UI:Cheer(name, id or npc)
				end }
			end
		end
	end
	return lines
end)

ns.On("NPC_LEFT", function()
	-- (the note and the choice of a bet go with the innkeeper's window; cards on the table stay)
	ns.Delay(0.8, function()
		if ns.Gossip and ns.Gossip.open then
			return
		end
		if UI.note then
			UI.note:Hide()
		end
		if UI.picker then
			UI.picker:Hide()
		end
		if UI.frame and UI.frame:IsShown() and UI.state == "choose" then
			UI.frame:Hide()
		end
	end, UI)
end)

-------------------------------------------------------------------------------
-- The alerts
-------------------------------------------------------------------------------
ns.On("TAVERN_INVITED", function(sender, npc)
	local G = ns.Gossip
	if G and G.open and G.npc == npc then
		G:Refresh()
	end
	if ns.Toast then
		ns.Toast:Push({
			title = string.format(L["%s raises a glass to you!"], Short(sender)),
			name = I:Name(npc),
			color = GOLD,
			line = L["Talk to this innkeeper within three minutes to raise yours."],
			tex = { ICON.toast },
			sound = ns.SND.coins,
		})
	end
end)

ns.On("TAVERN_CHEERS", function(name, npc, res)
	if not res then
		return
	end
	local G = ns.Gossip
	if G and G.open and G.npc == npc and ns.InnsUI and ns.InnsUI.ShowBonus then
		ns.Play(ns.SND.claim)
		ns.InnsUI:ShowBonus(npc, res)
	elseif ns.Toast then
		ns.Toast:Push({
			title = string.format(L["Cheers with %s!"], Short(name)),
			name = I:Name(npc),
			color = GOLD,
			line = L["A stamp more on your loyalty card."],
			tex = { ICON.toast },
			sound = ns.SND.claim,
			onClick = function()
				ns.Album:ShowInns()
			end,
		})
	end
end)

ns.On("TAVERN_HOME", function(npc)
	if not ns.Toast then
		return
	end
	ns.Toast:Push({
		title = L["Your home inn"],
		name = I:Name(npc),
		color = GOLD,
		line = L["Your loyalty counts double here."],
		tex = { ICON.home },
		sound = ns.SND.stamp,
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

-- (1.11.0) the rubies change: the parchment of the rumors to buy says it
ns.On("RUBIES_CHANGED", function()
	UI:PaintPicker()
end)
