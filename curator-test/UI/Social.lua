local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local A = ns.Album
local T = ns.Trade
local G = ns.Guild
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local Each = Hud.Each

-- The social page, in the album. On the left, its sections (the trades, the cards looked for; the
-- guild had one until 1.2) and the box of the trades (how many were done, with how many players, the
-- offers of players I do not know, a new trade). The trades: those open (an offer to answer first),
-- then the history. The cards looked for: mine (who has them to
-- spare), and those my guild looks for that I have to spare. A trade opens on the whole page: what I
-- give on the left, what I receive on the right, the gauge of the balance between them, the buttons of
-- the moment (propose, accept, change, refuse, withdraw); a side gets its cards and its boosters from a
-- chooser over the page (mine, or what the other player's album shows).
local NAV_W, NAV_H, NAV_GAP = 192, 34, 4
local X0 = NAV_W + 14
local BOX_H = 212
-- the trades: the open ones and the history on two tabs, seven rows a page
local ROW_H, ROW_GAP, ROWS = 58, 6, 7
local SUB_W, SUB_H = 160, 26
-- the cards looked for: two strips of six cards
local WISH_COLS, WISH_K, WISH_CELL_W, WISH_CELL_H = 6, 0.5, 86, 136
-- a trade: its two sides, their places (four a row, two rows), the gauge, the buttons
local PANEL_W, PANEL_H, PANEL_Y = 316, 304, -50
local SLOT_COLS, SLOT_ROWS, SLOT_K, SLOT_W, SLOT_H = 4, 2, 0.5, 72, 116
local GAUGE_W = 420
-- the chooser of a side: seven cards a row, two rows
local PICK_COLS, PICK_ROWS, PICK_K = 7, 2, 0.6
local PICK_CELL_W, PICK_CELL_H = 96, 124
-- the chooser of a player: eight a page
local WHO_ROWS, WHO_H = 8, 44

local GOLDEN = { 1, 0.8, 0.32 }
local DIM = { 0.62, 0.62, 0.68 }
local GREEN = { 0.45, 1, 0.45 }
local RED = { 1, 0.45, 0.4 }
local BLUE = { 0.55, 0.85, 1 }
local SOFT = { 0.82, 0.82, 0.86 }

-- (1.2: the section of the guild, its members and their albums, is gone; the guild still shares what
-- the trades and the wanted cards need)
-- (1.14.2, his word: "add a Guild tab with the finds of the people of the guild, showing the cards shown etc, those who
-- ask for cards etc; you have carte blanche") The guild again, on three tabs of its own: its finds (the cards its members
-- pulled, the boosters and the cases they opened live, their achievements and golden quests), its members (their level,
-- their cards, their showcase), and the cards they look for that I have to spare, a trade with each a click away.
local SECTIONS = {
	{ key = "trades", label = "Trades", icon = { "Swap" } },
	{ key = "guild", label = "Guild", icon = { "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" } },
	{ key = "wish", label = "Wanted cards", icon = { "Seek" } },
	-- (1.14.0) the Steamwheedle Exchange (UI/Market.lua): what is in deposit, on the way, what happened
	{ key = "market", label = "Steamwheedle Exchange", icon = { "Interface\\Icons\\INV_Misc_Coin_17" } },
}
local function Section(key)
	return (key == "trades" or key == "wish" or key == "market" or key == "guild") and key or "trades"
end
-- (1.14.2) the Guild: its three tabs; its finds in a wall of cards (five a row, three rows), each card this small; its
-- members and the cards they look for in rows (seven a page), their cards this small
local GUILD_TABS = {
	{ key = "finds", icon = { "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" } },
	{ key = "members", icon = { "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" } },
	{ key = "wanted", icon = { "Seek" } },
}
local FIND_COLS, FIND_ROWS, FIND_H, FIND_K = 5, 3, 152, 0.52
local SHOW_K, SHOW_W, WANT_K = 0.3, 40, 0.33

local fmtDate = date or (os and os.date)

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Colour(text, c)
	return "|cff" .. Hex(c) .. text .. "|r"
end

local function Short(name)
	return T:Short(name)
end

-- "Hogger · Brillante ×2", in the colour of its rarity; "2 boosters · Forêt d'Elwynn".
local function ItemText(it, plain)
	if it.b then
		local s = ns.SeriesByKey(it.b)
		local text = (it.n == 1 and L["1 booster"] or string.format(L["%d boosters"], it.n)) .. " · " .. (s and C:SeriesName(s) or "?")
		return plain and text or Colour(text, { 1, 0.86, 0.5 })
	end
	local card = ns.Cards[it.k]
	if not card then
		return "?"
	end
	local f = C:FinishName(card, it.f)
	local text = C:Name(card) .. (f and (" · " .. f) or "") .. (it.n > 1 and (" ×" .. it.n) or "")
	return plain and text or Colour(text, ns.RARITY[card.rarity].text)
end

-- A side in a few words: its first things, then how many more.
local function SideText(items, room)
	if CuratorOctoFull.Length(items) == 0 then
		return Colour(L["nothing"], DIM)
	end
	local parts = {}
	for i = 1, math.min(CuratorOctoFull.Length(items), room or 2) do
		parts[i] = ItemText(items[i])
	end
	local text = table.concat(parts, ", ")
	if CuratorOctoFull.Length(items) > (room or 2) then
		text = text .. Colour(" " .. string.format(L["+%d more"], CuratorOctoFull.Length(items) - (room or 2)), DIM)
	end
	return text
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- A choice among a few: dark, lit in gold when chosen.
local function NewToggle(parent, w, h)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, w, h)
	b.bg = Hud.Sliced(b, "QuestCard", h, 0, "BACKGROUND")
	b.glow = Hud.Sliced(b, "QuestGlow", h, Hud.GlowOut(h), "BORDER", 0, "ADD")
	Each(b.glow, "SetVertexColor", GOLDEN[1], GOLDEN[2], GOLDEN[3])
	Each(b.glow, "SetAlpha", 0)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 3, -3)
	b.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.08)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, h - 4, h - 4)
	b.icon:SetPoint("LEFT", 6, 0)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", h + 6, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	function b:SetLabel(text)
		local room = w - h - 12
		S.SetFontObject(self.text, "GameFontNormal")
		self.text:SetWidth(room)
		self.text:SetText(text)
		if ns.TextWidth(self.text) > room then
			S.Fit(self.text, text, room, 12, 8)
		end
	end
	function b:SetSelected(on)
		Each(self.glow, "SetAlpha", on and 0.85 or 0)
		self.on = on
		local c = on and { 1, 1, 1 } or S.GOLD
		self.text:SetTextColor(c[1], c[2], c[3])
	end
	return b
end

-- A small round button with an icon (a trade with a member, the pages of a strip).
local function RoundButton(parent, size, icon)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, size, size)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetTexture(MEDIA .. "CircleMask")
	b.bg:SetVertexColor(0.05, 0.06, 0.12)
	b.bg:SetAlpha(0.92)
	b.bg:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.bg, size * 0.86, size * 0.86)
	b.ring = b:CreateTexture(nil, "ARTWORK")
	b.ring:SetTexture(MEDIA .. "IconRing")
	b.ring:SetAllPoints()
	b.icon = b:CreateTexture(nil, "ARTWORK", nil, 1)
	CuratorOctoFull.SetSize(b.icon, size * 0.6, size * 0.6)
	b.icon:SetPoint("CENTER")
	Hud.SetIcon(b.icon, icon)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetTexture(MEDIA .. "Glow")
	b.hl:SetBlendMode("ADD")
	b.hl:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.hl, size * 1.6, size * 1.6)
	b.hl:SetVertexColor(1, 0.82, 0.4)
	b.hl:SetAlpha(0.7)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		if self.tip then
			self.tip(self)
		end
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end

-- The dot of a player online (green), offline (grey), not known (none).
local function Dot(parent, size)
	local t = parent:CreateTexture(nil, "OVERLAY")
	t:SetTexture(MEDIA .. "Dot")
	CuratorOctoFull.SetSize(t, size or 10, size or 10)
	function t:SetOnline(on)
		if on == nil then
			self:Hide()
			return
		end
		self:Show()
		if on then
			self:SetVertexColor(0.3, 1, 0.35)
		else
			self:SetVertexColor(0.45, 0.45, 0.48)
		end
	end
	return t
end

-- (1.14.0) What each place of a side shows (an item of the trade, the save's own table): kept here, not on the place,
-- which another addon reaches (EnumerateFrames).
local SLOTS = setmetatable({}, { __mode = "k" })

-- What a place of a side shows (nil: nothing).
function A:TradeSlotItem(s)
	return SLOTS[s]
end

-- A place of a side of the trade: a card (or the boosters of an album), how many.
local function NewSlot(panel, i)
	local col, row = CuratorOctoFull.Mod((i - 1) , SLOT_COLS), math.floor((i - 1) / SLOT_COLS)
	local x0 = (PANEL_W - SLOT_COLS * SLOT_W) / 2
	local s = CreateFrame("Button", nil, panel)
	CuratorOctoFull.SetSize(s, SLOT_W, SLOT_H)
	s:SetPoint("TOPLEFT", x0 + col * SLOT_W, -40 - row * SLOT_H)
	s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local card = ns.NewCard(s, "small")
	card:SetScale(SLOT_K)
	card:SetPoint("TOP", s, "TOP", 0, -2 / SLOT_K)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.55)
	card.tiny = true
	s.card = card
	s.pack = Hud.Pack(s, 38)
	s.pack:SetPoint("TOP", 0, -4)
	s.count = Hud.Text(s, 12, "OUTLINE", "OVERLAY")
	s.count:SetPoint("TOP", s, "TOP", 0, -88)
	s.count:SetTextColor(1, 0.9, 0.6)
	s.warn = s:CreateTexture(nil, "OVERLAY")
	s.warn:SetTexture(MEDIA .. "Badge")
	CuratorOctoFull.SetSize(s.warn, 16, 16)
	s.warn:SetPoint("TOPRIGHT", -4, -2)
	s.warn:Hide()
	-- (1.13.0: the finest grade of the copies that go with it, Copies.lua)
	s.grade = ns.ExpertiseUI and ns.ExpertiseUI.Tab(s, 46, 12) or nil
	if s.grade then
		s.grade:SetPoint("TOP", s, "TOP", 0, 2)
		s.grade:SetFrameLevel(s:GetFrameLevel() + 6)
	end
	s.hl = s:CreateTexture(nil, "HIGHLIGHT")
	s.hl:SetTexture(MEDIA .. "Glow")
	s.hl:SetBlendMode("ADD")
	s.hl:SetPoint("CENTER", s, "TOP", 0, -42)
	CuratorOctoFull.SetSize(s.hl, 110, 130)
	s.hl:SetVertexColor(1, 0.85, 0.5)
	s.hl:SetAlpha(0.35)
	CuratorOctoFull.SetScript(s, "OnEnter", function(self)
		A:TradeSlotTooltip(self)
	end)
	CuratorOctoFull.SetScript(s, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(s, "OnClick", function(self, button)
		A:TradeSlotClick(self, button)
	end)
	return s
end

-- A side of the trade: its title, its value, its places, its button to add.
local function NewPanel(ed, side)
	local p = CreateFrame("Frame", nil, ed)
	CuratorOctoFull.SetSize(p, PANEL_W, PANEL_H)
	p.bg = Hud.Card(p, 0.75, "BACKGROUND")
	p.side = side
	p.title = S.Text(p, "GameFontNormal", "LEFT")
	p.title:SetPoint("TOPLEFT", 14, -13)
	p.value = S.Text(p, "GameFontHighlightSmall", "RIGHT")
	p.value:SetPoint("TOPRIGHT", -14, -14)
	p.value:SetTextColor(0.75, 0.75, 0.8)
	p.rule = S.Divider(p, PANEL_W - 24, 0.6)
	p.rule:SetPoint("TOP", 0, -32)
	p.slots = {}
	for i = 1, SLOT_COLS * SLOT_ROWS do
		p.slots[i] = NewSlot(p, i)
	end
	p.empty = S.Text(p, "GameFontHighlight")
	p.empty:SetPoint("CENTER", 0, 4)
	p.empty:SetWidth(PANEL_W - 40)
	CuratorOctoFull.SetWordWrap(p.empty, true)
	p.empty:SetTextColor(0.6, 0.6, 0.64)
	p.add = S.Button(p, L["Add"], 150, 22)
	p.add:SetPoint("BOTTOM", 0, 12)
	CuratorOctoFull.SetScript(p.add, "OnClick", function()
		ns.Play(ns.SND.click)
		A:OpenTradePicker(side)
	end)
	return p
end

-- A card or a booster of the chooser: how many, a click puts one in.
local function NewPick(pk, i)
	local col, row = CuratorOctoFull.Mod((i - 1) , PICK_COLS), math.floor((i - 1) / PICK_COLS)
	local x0 = (pk.w - PICK_COLS * PICK_CELL_W) / 2
	local b = CreateFrame("Button", nil, pk)
	CuratorOctoFull.SetSize(b, PICK_CELL_W, PICK_CELL_H)
	b:SetPoint("TOPLEFT", x0 + col * PICK_CELL_W, -96 - row * PICK_CELL_H)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local card = ns.NewCard(b, "small")
	card:SetScale(PICK_K)
	card:SetPoint("TOP", b, "TOP", 0, -2 / PICK_K)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.55)
	card.tiny = true
	b.card = card
	b.pack = Hud.Pack(b, 44)
	b.pack:SetPoint("TOP", 0, -2)
	b.count = Hud.Text(b, 13, "OUTLINE", "OVERLAY")
	b.count:SetPoint("LEFT", b.pack.art, "BOTTOMRIGHT", 2, 10)
	b.count:SetTextColor(1, 0.9, 0.6)
	b.name = S.Text(b, "GameFontHighlightSmall")
	b.name:SetPoint("TOP", b, "TOP", 0, -98)
	b.name:SetWidth(PICK_CELL_W - 6)
	CuratorOctoFull.SetWordWrap(b.name, false)
	b.fin = S.Text(b, "GameFontHighlightSmall")
	b.fin:SetPoint("TOP", b.name, "BOTTOM", 0, -1)
	b.fin:SetWidth(PICK_CELL_W - 6)
	CuratorOctoFull.SetWordWrap(b.fin, false)
	b.fin:SetTextColor(0.75, 0.85, 1)
	b.mark = b:CreateTexture(nil, "OVERLAY")
	b.mark:SetTexture(MEDIA .. "Seek")
	CuratorOctoFull.SetSize(b.mark, 18, 18)
	b.mark:SetPoint("TOPLEFT", 8, -2)
	b.mark:Hide()
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetTexture(MEDIA .. "Glow")
	b.hl:SetBlendMode("ADD")
	b.hl:SetPoint("CENTER", b, "TOP", 0, -48)
	CuratorOctoFull.SetSize(b.hl, 120, 140)
	b.hl:SetVertexColor(1, 0.85, 0.5)
	b.hl:SetAlpha(0.35)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:PickTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnClick", function(self, button)
		A:PickClick(self, button)
	end)
	return b
end

-- A trade in the list: its kind, the other player, where it is, what goes each way, when.
local function NewTradeRow(list, i, w)
	local r = S.ListButton(list)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
	r.glow = r:CreateTexture(nil, "BACKGROUND", nil, 2)
	r.glow:SetAllPoints()
	CuratorOctoFull.ColorTexture(r.glow, 1, 0.8, 0.3, 0.12)
	r.glow:SetBlendMode("ADD")
	r.glow:Hide()
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, 30, 30)
	r.icon:SetPoint("LEFT", 12, 0)
	r.name = S.Text(r, "GameFontNormal", "LEFT")
	r.name:SetPoint("TOPLEFT", 52, -10)
	r.name:SetWidth(170)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.dot = Dot(r, 9)
	r.state = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.state:SetPoint("TOPLEFT", 52, -32)
	r.state:SetWidth(178)
	CuratorOctoFull.SetWordWrap(r.state, false)
	r.give = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.give:SetPoint("TOPLEFT", 238, -11)
	r.give:SetWidth(w - 238 - 70)
	CuratorOctoFull.SetWordWrap(r.give, false)
	r.take = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.take:SetPoint("TOPLEFT", 238, -33)
	r.take:SetWidth(w - 238 - 70)
	CuratorOctoFull.SetWordWrap(r.take, false)
	r.when = S.Text(r, "GameFontDisableSmall", "RIGHT")
	r.when:SetPoint("TOPRIGHT", -10, -11)
	r.mark = r:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(r.mark, 18, 18)
	r.mark:SetPoint("BOTTOMRIGHT", -10, 8)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		if self.rec then
			ns.Play(ns.SND.cardFlip)
			A:ShowTrade(self.rec.id)
		end
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:TradeRowTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

-- (1.14.0) A line of the Exchange: the thing, what it is now (or what happened), its rubies, its day.
local function NewMarketRow(list, i, w)
	local r = S.ListButton(list)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, 30, 30)
	r.icon:SetPoint("LEFT", 12, 0)
	r.name = S.Text(r, "GameFontNormal", "LEFT")
	r.name:SetPoint("TOPLEFT", 52, -10)
	r.name:SetWidth(w - 52 - 150)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.state = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.state:SetPoint("TOPLEFT", 52, -32)
	r.state:SetWidth(w - 52 - 150)
	CuratorOctoFull.SetWordWrap(r.state, false)
	r.money = S.Text(r, "GameFontHighlight", "RIGHT")
	r.money:SetPoint("TOPRIGHT", -12, -11)
	r.money:SetWidth(136)
	r.when = S.Text(r, "GameFontDisableSmall", "RIGHT")
	r.when:SetPoint("TOPRIGHT", -12, -33)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		local MUI = ns.MarketUI
		if MUI and self.it then
			MUI:Tooltip(self, self.it, self.tip)
		end
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

-- A card of a strip of the cards looked for: the card, two lines under it.
local function NewWish(strip, i)
	local b = CreateFrame("Button", nil, strip)
	CuratorOctoFull.SetSize(b, WISH_CELL_W, WISH_CELL_H)
	b:SetPoint("TOPLEFT", (i - 1) * (WISH_CELL_W + 2), -30)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local card = ns.NewCard(b, "small")
	card:SetScale(WISH_K)
	card:SetPoint("TOP", b, "TOP", 0, -2 / WISH_K)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.55)
	card.tiny = true
	b.card = card
	b.line1 = S.Text(b, "GameFontHighlightSmall")
	b.line1:SetPoint("TOP", b, "TOP", 0, -86)
	b.line1:SetWidth(WISH_CELL_W - 2)
	CuratorOctoFull.SetWordWrap(b.line1, false)
	b.line2 = S.Text(b, "GameFontHighlightSmall")
	b.line2:SetPoint("TOP", b.line1, "BOTTOM", 0, -3)
	b.line2:SetWidth(WISH_CELL_W - 2)
	CuratorOctoFull.SetWordWrap(b.line2, true)
	CuratorOctoFull.SetMaxLines(b.line2, 2)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetTexture(MEDIA .. "Glow")
	b.hl:SetBlendMode("ADD")
	b.hl:SetPoint("CENTER", b, "TOP", 0, -42)
	CuratorOctoFull.SetSize(b.hl, 110, 130)
	b.hl:SetVertexColor(1, 0.85, 0.5)
	b.hl:SetAlpha(0.35)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:WishTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnClick", function(self, button)
		A:WishClick(self, button)
	end)
	return b
end

-- A strip of cards looked for: its title, its count, its arrows.
local function NewStrip(page, w, kind)
	local st = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(st, w, 30 + WISH_CELL_H)
	st.kind = kind
	st.title = S.Text(st, "GameFontNormal", "LEFT")
	st.title:SetPoint("TOPLEFT", 2, -4)
	st.prev = S.Arrow(st, -1, 24)
	st.prev:SetPoint("TOPRIGHT", -30, 2)
	st.next = S.Arrow(st, 1, 24)
	st.next:SetPoint("TOPRIGHT", -2, 2)
	CuratorOctoFull.SetScript(st.prev, "OnClick", function()
		A:WishPage(kind, -1)
	end)
	CuratorOctoFull.SetScript(st.next, "OnClick", function()
		A:WishPage(kind, 1)
	end)
	S.PageArrows(st.prev, st.next)
	st.pages = S.Text(st, "GameFontDisableSmall", "RIGHT")
	st.pages:SetPoint("RIGHT", st.prev, "LEFT", -4, 0)
	st.cards = {}
	for i = 1, WISH_COLS do
		st.cards[i] = NewWish(st, i)
	end
	st.empty = S.Text(st, "GameFontHighlight")
	st.empty:SetPoint("TOP", 0, -70)
	st.empty:SetWidth(w - 60)
	CuratorOctoFull.SetWordWrap(st.empty, true)
	st.empty:SetTextColor(0.62, 0.62, 0.66)
	return st
end

-- (1.14.2) A find of the guild in its wall: its card (a booster without it: its pack; a case: the card that came out of
-- it; an achievement: its icon in a ring), the light of its rarity behind it, under it its name, who found it, when.
local function NewFind(wall, i, cw)
	local col, row = CuratorOctoFull.Mod((i - 1) , FIND_COLS), math.floor((i - 1) / FIND_COLS)
	local b = CreateFrame("Button", nil, wall)
	CuratorOctoFull.SetSize(b, cw, FIND_H)
	b:SetPoint("TOPLEFT", col * cw, -row * FIND_H)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b.glow = b:CreateTexture(nil, "BACKGROUND")
	b.glow:SetTexture(MEDIA .. "Glow")
	b.glow:SetBlendMode("ADD")
	b.glow:SetPoint("CENTER", b, "TOP", 0, -46)
	CuratorOctoFull.SetSize(b.glow, cw * 1.2, 118)
	b.glow:SetAlpha(0)
	local card = ns.NewCard(b, "small")
	card:SetScale(FIND_K)
	card:SetPoint("TOP", b, "TOP", 0, -4 / FIND_K)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.55)
	card.tiny = true
	b.card = card
	b.pack = Hud.Pack(b, 38)
	b.pack:SetPoint("TOP", 0, -6)
	b.pack:Hide()
	b.icon = Hud.RoundIcon(b, 50)
	b.icon:SetPoint("CENTER", b, "TOP", 0, -45)
	b.ring = b:CreateTexture(nil, "ARTWORK", nil, 2)
	b.ring:SetTexture(MEDIA .. "IconRing")
	b.ring:SetVertexColor(1, 0.84, 0.4)
	CuratorOctoFull.SetSize(b.ring, 62, 62)
	b.ring:SetPoint("CENTER", b.icon, "CENTER")
	b.icon:Hide()
	b.ring:Hide()
	b.line1 = S.Text(b, "GameFontHighlightSmall")
	b.line1:SetPoint("TOP", b, "TOP", 0, -91)
	b.line1:SetWidth(cw - 6)
	CuratorOctoFull.SetWordWrap(b.line1, false)
	CuratorOctoFull.SetMaxLines(b.line1, 2)
	b.line2 = S.Text(b, "GameFontNormalSmall")
	b.line2:SetPoint("TOP", b.line1, "BOTTOM", 0, -3)
	b.line2:SetWidth(cw - 6)
	CuratorOctoFull.SetWordWrap(b.line2, false)
	b.line3 = S.Text(b, "GameFontDisableSmall")
	b.line3:SetPoint("TOP", b.line2, "BOTTOM", 0, -3)
	b.line3:SetWidth(cw - 6)
	CuratorOctoFull.SetWordWrap(b.line3, false)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetTexture(MEDIA .. "Glow")
	b.hl:SetBlendMode("ADD")
	b.hl:SetPoint("CENTER", b, "TOP", 0, -46)
	CuratorOctoFull.SetSize(b.hl, cw * 1.1, 120)
	b.hl:SetVertexColor(1, 0.85, 0.5)
	b.hl:SetAlpha(0.3)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:FindTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		A:FindClick(self)
	end)
	return b
end

-- (1.14.2) A member of the guild: whether they are there, their name, their title, level and cards, their showcase (three
-- cards, small), a trade with them.
local function NewMember(list, i, w)
	local r = S.ListButton(list)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
	r.name = S.Text(r, "GameFontNormal", "LEFT")
	r.name:SetPoint("TOPLEFT", 14, -10)
	r.name:SetWidth(220)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.dot = Dot(r, 9)
	r.info = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.info:SetPoint("TOPLEFT", 14, -32)
	r.info:SetWidth(w - 14 - 3 * SHOW_W - 66)
	CuratorOctoFull.SetWordWrap(r.info, false)
	r.trade = RoundButton(r, 30, { "Swap" })
	r.trade:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.trade:SetFrameLevel(r:GetFrameLevel() + 4)
	r.trade.tip = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Propose a trade"], 1, 1, 1)
		if self:GetParent().member then
			GameTooltip:AddLine(Short(self:GetParent().member), 0.85, 0.85, 0.85)
		end
		GameTooltip:Show()
	end
	CuratorOctoFull.SetScript(r.trade, "OnClick", function(self)
		local m = self:GetParent().member
		if m then
			ns.Play(ns.SND.click)
			A:StartTrade(m, nil, nil, "guild")
		end
	end)
	-- (their showcase: a card of the albums, or a card of a case, made the first time one shows)
	r.show = {}
	for k = 1, 3 do
		local slot = CreateFrame("Frame", nil, r)
		CuratorOctoFull.SetSize(slot, SHOW_W - 4, ROW_H - 6)
		slot:SetPoint("RIGHT", r, "RIGHT", -(12 + 30 + 14 + (3 - k) * SHOW_W), 0)
		local c = ns.NewCard(slot, "small")
		c:SetScale(SHOW_K)
		c:SetPoint("CENTER", slot, "CENTER", 0, 0)
		c:EnableMouse(false)
		c.shadow:SetAlpha(0.5)
		c.tiny = true
		slot.card = c
		r.show[k] = slot
	end
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		if self.member then
			ns.Play(ns.SND.cardFlip)
			ns.Album:ShowPlayer(self.member)
		end
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:MemberTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

-- (1.14.2) A card a member of the guild looks for that I have to spare: the card, who looks for it, how many I have to
-- spare, the button that proposes them a trade, that card on my side.
local function NewWanted(list, i, w)
	local r = S.ListButton(list)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
	local card = ns.NewCard(r, "small")
	card:SetScale(WANT_K)
	card:SetPoint("LEFT", r, "LEFT", 10 / WANT_K, 0)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.5)
	card.tiny = true
	r.card = card
	r.name = S.Text(r, "GameFontNormal", "LEFT")
	r.name:SetPoint("TOPLEFT", 60, -10)
	r.name:SetWidth(w - 60 - 176)
	CuratorOctoFull.SetWordWrap(r.name, false)
	-- (whether the member who looks for it is there, before who it is)
	r.dot = Dot(r, 9)
	r.dot:SetPoint("TOPLEFT", 60, -34)
	r.info = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.info:SetPoint("TOPLEFT", 74, -32)
	r.info:SetWidth(w - 74 - 176)
	CuratorOctoFull.SetWordWrap(r.info, false)
	r.go = S.Button(r, L["Propose a trade"], 156, 22)
	r.go:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.go:SetFrameLevel(r:GetFrameLevel() + 4)
	CuratorOctoFull.SetScript(r.go, "OnClick", function(self)
		A:ProposeWanted(self:GetParent())
	end)
	-- (a click on the row, as on a card of the strip of the cards looked for: offered)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		A:ProposeWanted(self)
	end)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:WantedTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
function A:BuildSocial()
	local f = self.frame
	if f.soc then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.soc = page
	local W = U.PAGE_W - 32
	local rw = W - X0
	page.W, page.rw = W, rw

	-- the sections
	page.nav = {}
	for i, sec in ipairs(SECTIONS) do
		local i, sec = i, sec; local b = Hud.NavButton(page, NAV_W, NAV_H)
		b.sec = sec
		Hud.SetIcon(b.icon, sec.icon)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetSocialSection(sec.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:SocialNavTooltip(self)
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		page.nav[i] = b
	end

	-- the box of the trades: how many were done, with how many players, what waits, the offers of
	-- the players I do not know, a new trade
	local box = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(box, NAV_W, BOX_H)
	Hud.Panel(box, BOX_H)
	box.title = S.Text(box, "GameFontNormal")
	box.title:SetPoint("TOP", 0, -12)
	box.title:SetText(L["Your trades"])
	box.icon = box:CreateTexture(nil, "ARTWORK")
	box.icon:SetTexture(MEDIA .. "Swap")
	CuratorOctoFull.SetSize(box.icon, 34, 34)
	box.icon:SetPoint("TOPLEFT", 12, -34)
	box.done = Hud.Text(box, 18, "OUTLINE")
	box.done:SetPoint("TOPLEFT", 54, -34)
	box.done:SetTextColor(1, 0.92, 0.7)
	box.doneLabel = S.Text(box, "GameFontHighlightSmall", "LEFT")
	box.doneLabel:SetPoint("TOPLEFT", box.done, "BOTTOMLEFT", 0, -2)
	box.doneLabel:SetWidth(NAV_W - 64)
	CuratorOctoFull.SetWordWrap(box.doneLabel, false)
	box.partners = S.Text(box, "GameFontHighlightSmall", "LEFT")
	box.partners:SetPoint("TOPLEFT", 14, -80)
	box.partners:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(box.partners, false)
	box.partners:SetTextColor(0.8, 0.8, 0.84)
	box.held = S.Text(box, "GameFontHighlightSmall", "LEFT")
	box.held:SetPoint("TOPLEFT", box.partners, "BOTTOMLEFT", 0, -4)
	box.held:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(box.held, true)
	CuratorOctoFull.SetMaxLines(box.held, 2)
	box.held:SetTextColor(1, 0.8, 0.45)
	box.strangers = S.Check(box, L["Offers from strangers"])
	box.strangers:SetPoint("BOTTOMLEFT", 10, 50)
	box.strangers.Text:SetWidth(NAV_W - 50)
	box.strangers.Text:SetJustifyH("LEFT")
	CuratorOctoFull.SetWordWrap(box.strangers.Text, true)
	CuratorOctoFull.SetScript(box.strangers, "OnClick", function(self)
		ns.db.strangers = self:GetChecked() and true or false
		ns.Play(ns.SND.click)
	end)
	CuratorOctoFull.SetScript(box.strangers, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Offers from strangers"], 1, 1, 1)
		GameTooltip:AddLine(L["Ticked: any player can send you an offer. Unticked: only your guild, your friends and the players you traded with."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(box.strangers, "OnLeave", function()
		GameTooltip:Hide()
	end)
	box.new = Hud.ClaimButton(box, NAV_W - 24, 30, L["New trade"])
	box.new:SetPoint("BOTTOM", 0, 12)
	CuratorOctoFull.SetScript(box.new, "OnClick", function()
		ns.Play(ns.SND.click)
		A:OpenChooser()
	end)
	page.box = box

	-- the trades: the open ones, the history
	local tr = CreateFrame("Frame", nil, page)
	tr:SetPoint("TOPLEFT", X0, 0)
	CuratorOctoFull.SetSize(tr, rw, U.PAGE_H - 20)
	page.trades = tr
	tr.tabs = {}
	for i, key in ipairs({ "open", "past" }) do
		local i, key = i, key; local b = NewToggle(tr, SUB_W, SUB_H)
		b:SetPoint("TOPLEFT", (i - 1) * (SUB_W + 8), 0)
		b.key = key
		Hud.SetIcon(b.icon, key == "open" and { "Swap" } or { "Hourglass" })
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetTradeTab(key)
		end)
		tr.tabs[i] = b
	end
	tr.rows = {}
	local list = CreateFrame("Frame", nil, tr)
	list:SetPoint("TOPLEFT", 0, -SUB_H - 12)
	CuratorOctoFull.SetSize(list, rw, ROWS * (ROW_H + ROW_GAP))
	tr.list = list
	for i = 1, ROWS do
		tr.rows[i] = NewTradeRow(list, i, rw)
	end
	tr.empty = S.Text(tr, "GameFontHighlight")
	tr.empty:SetPoint("TOP", 0, -140)
	tr.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(tr.empty, true)
	tr.empty:SetTextColor(0.62, 0.62, 0.66)

	-- the cards looked for: mine, and those my guild looks for
	local ws = CreateFrame("Frame", nil, page)
	ws:SetPoint("TOPLEFT", X0, 0)
	CuratorOctoFull.SetSize(ws, rw, U.PAGE_H - 20)
	page.wish = ws
	ws.mine = NewStrip(ws, rw, "mine")
	ws.mine:SetPoint("TOPLEFT", 0, 0)
	ws.rule = S.Divider(ws, rw, 0.7)
	ws.rule:SetPoint("TOPLEFT", 0, -(30 + WISH_CELL_H + 18))
	ws.theirs = NewStrip(ws, rw, "theirs")
	ws.theirs:SetPoint("TOPLEFT", 0, -(30 + WISH_CELL_H + 36))
	ws.hint = S.Text(ws, "GameFontHighlightSmall", "LEFT")
	ws.hint:SetPoint("BOTTOMLEFT", 2, 42)
	ws.hint:SetWidth(rw - 4)
	CuratorOctoFull.SetWordWrap(ws.hint, true)
	ws.hint:SetTextColor(0.7, 0.7, 0.74)
	ws.hint:SetText(L["Click a card you are missing in your album to look for it: your guild sees it, and their cards to spare show it."])

	-- (1.14.0) the Steamwheedle Exchange: what is in deposit and on the way, then what happened; bought and sold at an
	-- auctioneer (the tab Curator of the auction house)
	local mk = CreateFrame("Frame", nil, page)
	mk:SetPoint("TOPLEFT", X0, 0)
	CuratorOctoFull.SetSize(mk, rw, U.PAGE_H - 20)
	page.market = mk
	mk.tabs = {}
	for i, key in ipairs({ "now", "past" }) do
		local i, key = i, key; local b = NewToggle(mk, SUB_W, SUB_H)
		b:SetPoint("TOPLEFT", (i - 1) * (SUB_W + 8), 0)
		b.key = key
		Hud.SetIcon(b.icon, key == "now" and { "Interface\\Icons\\INV_Misc_Coin_17" } or { "Hourglass" })
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetMarketTab(key)
		end)
		mk.tabs[i] = b
	end
	local ml = CreateFrame("Frame", nil, mk)
	ml:SetPoint("TOPLEFT", 0, -SUB_H - 12)
	CuratorOctoFull.SetSize(ml, rw, ROWS * (ROW_H + ROW_GAP))
	mk.rows = {}
	for i = 1, ROWS do
		mk.rows[i] = NewMarketRow(ml, i, rw)
	end
	mk.empty = S.Text(mk, "GameFontHighlight")
	mk.empty:SetPoint("TOP", 0, -140)
	mk.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(mk.empty, true)
	mk.empty:SetTextColor(0.62, 0.62, 0.66)
	mk.hint = S.Text(mk, "GameFontHighlightSmall", "RIGHT")
	mk.hint:SetPoint("TOPRIGHT", 0, -6)
	mk.hint:SetWidth(rw - 2 * (SUB_W + 8) - 8)
	CuratorOctoFull.SetWordWrap(mk.hint, true)
	CuratorOctoFull.SetMaxLines(mk.hint, 2)
	mk.hint:SetTextColor(0.7, 0.7, 0.74)

	-- (1.14.2) the guild: its finds, its members, the cards they look for (their cards made the first time each shows)
	local gd = CreateFrame("Frame", nil, page)
	gd:SetPoint("TOPLEFT", X0, 0)
	CuratorOctoFull.SetSize(gd, rw, U.PAGE_H - 20)
	page.guild = gd
	gd.tabs = {}
	for i, t in ipairs(GUILD_TABS) do
		local i, t = i, t; local b = NewToggle(gd, SUB_W, SUB_H)
		b:SetPoint("TOPLEFT", (i - 1) * (SUB_W + 8), 0)
		b.key = t.key
		Hud.SetIcon(b.icon, t.icon)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetGuildTab(t.key)
		end)
		gd.tabs[i] = b
	end
	for _, key in ipairs({ "wall", "members", "wanted" }) do
		local box = CreateFrame("Frame", nil, gd)
		box:SetPoint("TOPLEFT", 0, -SUB_H - 12)
		CuratorOctoFull.SetSize(box, rw, U.PAGE_H - 20 - SUB_H - 12)
		box:Hide()
		gd[key] = box
	end
	gd.empty = S.Text(gd, "GameFontHighlight")
	gd.empty:SetPoint("TOP", 0, -140)
	gd.empty:SetWidth(rw - 60)
	CuratorOctoFull.SetWordWrap(gd.empty, true)
	gd.empty:SetTextColor(0.62, 0.62, 0.66)
	-- (under the cards they look for, what a click does: when the page leaves it room)
	gd.hint = S.Text(gd.wanted, "GameFontHighlightSmall", "LEFT")
	gd.hint:SetWidth(rw - 4)
	CuratorOctoFull.SetWordWrap(gd.hint, true)
	gd.hint:SetTextColor(0.7, 0.7, 0.74)

	-- the guild list: in the part on the right
	f.list:SetParent(page)
	f.list:ClearAllPoints()
	f.list:SetPoint("TOPLEFT", page, "TOPLEFT", X0, 0)
	f.list:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, U.PAGER - 10)
	f.list:SetFrameLevel(page:GetFrameLevel() + 1)
	-- (its rows in the narrower part: the name and its lines on the left, the progress on the right,
	-- whether they are there, a trade with them)
	for _, r in ipairs(f.list.rows) do
		local _, r = _, r; r.name:ClearAllPoints()
		r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 74, -6)
		r.name:SetWidth(190)
		CuratorOctoFull.SetWordWrap(r.name, false)
		-- (the title, the points and the level: up to the bar, for the long titles)
		r.points:ClearAllPoints()
		r.points:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
		r.points:SetWidth(math.max(210, rw - 74 - 194 - 12))
		CuratorOctoFull.SetWordWrap(r.points, false)
		r.best:ClearAllPoints()
		r.best:SetPoint("TOPLEFT", r.points, "BOTTOMLEFT", 0, -2)
		r.best:SetWidth(math.max(210, rw - 74 - 194 - 12))
		CuratorOctoFull.SetWordWrap(r.best, false)
		r.bar:SetWidth(140)
		r.bar:ClearAllPoints()
		r.bar:SetPoint("RIGHT", r, "RIGHT", -54, 2)
		CuratorOctoFull.SetSize(r.leg, 14, 14)
		r.leg:ClearAllPoints()
		r.leg:SetPoint("TOPLEFT", r.bar, "BOTTOMLEFT", -2, -5)
		CuratorOctoFull.SetSize(r.myth, 14, 14)
		r.shiny:Hide()
		r.dot = Dot(r, 9)
		r.trade = RoundButton(r, 30, { "Swap" })
		r.trade:SetPoint("RIGHT", r, "RIGHT", -12, 0)
		r.trade:SetFrameLevel(r:GetFrameLevel() + 4)
		r.trade.tip = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Propose a trade"], 1, 1, 1)
			if self:GetParent().member then
				GameTooltip:AddLine(Short(self:GetParent().member), 0.85, 0.85, 0.85)
			end
			GameTooltip:Show()
		end
		CuratorOctoFull.SetScript(r.trade, "OnClick", function(self)
			local m = self:GetParent().member
			if m then
				ns.Play(ns.SND.click)
				A:StartTrade(m)
			end
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			A:GuildRowTooltip(self)
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	self:BuildTradeEditor(page)
	self:BuildChooser(page)

	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		A.st = (A.st or 0) + elapsed
		local t = A.st
		for _, r in ipairs(self.trades.rows) do
			if r.pulse and r:IsShown() then
				r.glow:SetAlpha(0.45 + 0.4 * math.sin(t * 4))
			end
		end
		if self.wish:IsShown() then
			for _, st in ipairs({ self.wish.mine, self.wish.theirs }) do
				for _, b in ipairs(st.cards) do
					if b:IsShown() then
						b.card:Tick(t)
					end
				end
			end
		end
		-- (1.14.2) the cards of the guild
		local gd = self.guild
		if gd:IsShown() then
			for _, b in ipairs(gd.cells or {}) do
				if b:IsShown() and b.card:IsShown() then
					b.card:Tick(t)
				end
			end
			for _, r in ipairs(gd.wantRows or {}) do
				if r:IsShown() then
					r.card:Tick(t)
				end
			end
			for _, r in ipairs(gd.memberRows or {}) do
				if r:IsShown() then
					for _, slot in ipairs(r.show) do
						if slot:IsShown() and slot.card:IsShown() then
							slot.card:Tick(t)
						end
					end
				end
			end
		end
		local ed = self.ed
		if ed:IsShown() then
			for _, p in ipairs({ ed.give, ed.take }) do
				for _, s in ipairs(p.slots) do
					if s.card:IsShown() then
						s.card:Tick(t)
					end
				end
			end
			if ed.pick:IsShown() then
				for _, b in ipairs(ed.pick.cells) do
					if b.card:IsShown() then
						b.card:Tick(t)
					end
				end
			end
		end
	end)
end

function A:ShowSocialPage(shown)
	local f = self.frame
	if shown then
		self:BuildSocial()
	end
	if f.soc then
		CuratorOctoFull.SetShown(f.soc, shown)
	end
end

function A:SetSocialSection(key)
	self.ed, self.who = nil, nil
	key = Section(key)
	if key ~= self.socSec then
		self.socSec = key
		self.listPage, self.tradePage = 1, 1
		ns.Play(ns.SND.page)
		if key == "guild" then
			G:Query()
		end
	end
	self:Refresh()
end

function A:SetTradeTab(key)
	if key ~= self.tradeTab then
		self.tradeTab, self.tradePage = key, 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The social page: a trade open (all the page), the chooser of a player, or a section.
function A:RefreshSocial()
	local f = self.frame
	local page = f.soc
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.wait:Hide()
	local sec = Section(self.socSec)
	self.socSec = sec
	local ed, who = self.ed ~= nil, self.who ~= nil
	-- (a trade or the chooser takes the whole page)
	for _, b in ipairs(page.nav) do
		CuratorOctoFull.SetShown(b, not (ed or who))
	end
	CuratorOctoFull.SetShown(page.box, not (ed or who))
	CuratorOctoFull.SetShown(page.trades, not (ed or who) and sec == "trades")
	CuratorOctoFull.SetShown(page.wish, not (ed or who) and sec == "wish")
	CuratorOctoFull.SetShown(page.market, not (ed or who) and sec == "market")
	-- (1.14.2: the guild on a page of its own; the list of the members of an album of before 1.2 stays hidden)
	CuratorOctoFull.SetShown(page.guild, not (ed or who) and sec == "guild")
	CuratorOctoFull.SetShown(page.ed, ed)
	CuratorOctoFull.SetShown(page.who, who and not ed)
	f.list:Hide()
	if not (ed or who) then
		self:PaintSocialNav()
		self:PaintTradeBox()
	end
	if sec ~= "wish" or ed or who then
		for _, st in ipairs({ page.wish.mine, page.wish.theirs }) do
			for _, b in ipairs(st.cards) do
				b.card.sig = nil
			end
		end
	end
	-- (1.14.2: the cards of the guild set again when it shows again: hidden, their creatures were let go)
	if sec ~= "guild" or ed or who then
		self:ForgetGuildCards()
	end
	if ed then
		self:ShowPager(false)
		self:RefreshFooter(false)
		return self:RefreshTradeEditor()
	end
	if who then
		self:RefreshFooter(false)
		return self:RefreshChooser()
	end
	self:SetAllCounts()
	self:RefreshFooter(false)
	if sec == "guild" then
		return self:RefreshGuildPage()
	end
	if sec == "trades" then
		return self:RefreshTrades()
	end
	if sec == "market" then
		return self:RefreshMarket()
	end
	return self:RefreshWishes()
end

function A:SetMarketTab(key)
	if key ~= self.marketTab then
		self.marketTab, self.marketPage = key, 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- (1.14.0) The lines of the Exchange: in deposit, the buy orders, on the way ("now"); what happened ("past").
function A:MarketLines(tab)
	local MUI = ns.MarketUI
	local out = {}
	if not MUI then
		return out
	end
	if tab == "past" then
		for _, h in ipairs(MUI:History({ listed = true, sold = true, back = true, refused = true, bought = true, refund = true, ordered = true, unfilled = true })) do
			out[CuratorOctoFull.Length(out) + 1] = { h = h }
		end
		return out
	end
	for _, x in ipairs(MUI:OnTheWay()) do
		out[CuratorOctoFull.Length(out) + 1] = { way = x }
	end
	for _, x in ipairs(MUI:Deposit()) do
		out[CuratorOctoFull.Length(out) + 1] = { dep = x }
	end
	for _, x in ipairs(MUI:Orders()) do
		out[CuratorOctoFull.Length(out) + 1] = { ord = x }
	end
	return out
end

function A:RefreshMarket()
	local MUI = ns.MarketUI
	local mk = self.frame.soc.market
	local tab = self.marketTab or "now"
	self.marketTab = tab
	local now, past = self:MarketLines("now"), self:MarketLines("past")
	local MK = ns.Market
	local m = MK and MK:Db()
	local st = m and m.st or {}
	self:SetTitle(L["Steamwheedle Exchange"], string.format(L["Sold: %d  ·  Bought: %d"], tonumber(st.sold) or 0, tonumber(st.bought) or 0))
	for _, b in ipairs(mk.tabs) do
		b:SetLabel(string.format((b.key == "now" and L["Now (%d)"] or L["History (%d)"]), b.key == "now" and CuratorOctoFull.Length(now) or CuratorOctoFull.Length(past)))
		b:SetSelected(b.key == tab)
	end
	mk.hint:SetText(string.format(L["Bought and sold at an auctioneer: the tab Curator of the auction house. Every listing: %s"], "curator-wow.com/bourse"))
	local list = tab == "now" and now or past
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / ROWS))
	self.marketPage = math.max(1, math.min(self.marketPage or 1, pages))
	local Rubies = function(n)
		return ns.Rubies.Text(n or 0, 12)
	end
	for i, r in ipairs(mk.rows) do
		local x = list[(self.marketPage - 1) * ROWS + i]
		CuratorOctoFull.SetShown(r, x ~= nil and MUI ~= nil)
		r.it, r.tip = nil, nil
		if x and MUI then
			local it, ask, state, col, money, when
			if x.h then
				local h = x.h
				if h.k == "ordered" or h.k == "unfilled" then
					ask = MK.ReadAsk(h.it or "")
				else
					it = MK.Unpack(h.it or "")
				end
				state, money, col = MUI.Event(h)
				when = fmtDate("%d/%m", tonumber(h.t) or 0)
			elseif x.way then
				it = x.way.it
				state, col = x.way.fill and L["Sold to an order: on its way"] or L["On its way"], DIM
				money = Rubies(x.way.paid)
				when = fmtDate("%d/%m", tonumber((x.way.b or x.way.fill).t) or 0)
			elseif x.dep then
				it = x.dep.it
				local stt = MUI.STATE[x.dep.state] or MUI.STATE.waiting
				state, col = L[stt[1]] .. ((x.dep.state ~= "waiting" and x.dep.ends) and ("  ·  " .. MUI.Left(x.dep.ends)) or ""), stt[2]
				money = x.dep.price and Rubies(x.dep.price) or L["Barter"]
				when = ""
			else
				ask = x.ord.ask
				local stt = MUI.STATE[x.ord.state] or MUI.STATE.waiting
				state, col = L["Buy order"] .. "  ·  " .. L[stt[1]], stt[2]
				money = Rubies(x.ord.price)
				when = ""
			end
			local icon = MUI.Icon(it or (ask and { k = ask.k, npc = ask.npc, series = ask.series, edition = ask.edition }))
			r.icon:SetTexture(icon)
			S.SetFontObject(r.name, "GameFontNormal")
			local name = (it and MUI.Title(it, 2)) or (ask and MUI.AskText(ask)) or "?"
			r.name:SetText(name)
			if ns.TextWidth(r.name) > r.name:GetWidth() then
				S.Fit(r.name, name, r.name:GetWidth(), 12, 9)
			end
			local c = (it and MUI.Color(it)) or S.GOLD
			r.name:SetTextColor(c[1], c[2], c[3])
			r.state:SetText(state or "")
			r.state:SetTextColor((col or DIM)[1], (col or DIM)[2], (col or DIM)[3])
			r.money:SetText(money or "")
			r.when:SetText(when or "")
			r.it = it
			r:SetSelected(false)
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		mk.empty:SetText(tab == "now" and L["Nothing at the Exchange now. At an auctioneer, the tab Curator puts your things on sale and buys those of the others."]
			or L["Nothing yet."])
	else
		mk.empty:SetText("")
	end
	self:ShowPager(true)
	self:SetPager(self.marketPage, pages)
end

-- The sections on the left, the box of the trades under them.
function A:PaintSocialNav()
	local page = self.frame.soc
	local prev
	for _, b in ipairs(page.nav) do
		b:ClearAllPoints()
		if prev then
			b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -NAV_GAP)
		else
			b:SetPoint("TOPLEFT")
		end
		prev = b
		local key = b.sec.key
		local count, claim = "", 0
		if key == "trades" then
			claim = T:Waiting()
			local open = T:List()
			count = CuratorOctoFull.Length(open) > 0 and tostring(CuratorOctoFull.Length(open)) or ""
		elseif key == "wish" then
			local n = CuratorOctoFull.Length(T:Wishes())
			count = n > 0 and tostring(n) or ""
		elseif key == "market" then
			local n = CuratorOctoFull.Length(self:MarketLines("now"))
			count = n > 0 and tostring(n) or ""
		elseif key == "guild" then
			-- (1.14.2: the members known)
			local n = CuratorOctoFull.Length(self:GuildMembers())
			count = n > 0 and tostring(n) or ""
		end
		b:Paint(key == self.socSec, L[b.sec.label], count, claim)
	end
	page.box:ClearAllPoints()
	page.box:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
end

function A:PaintTradeBox()
	local box = self.frame.soc.box
	local done, partners = T:Done()
	box.done:SetText(ns.Num(done))
	box.doneLabel:SetText(done == 1 and L["trade done"] or L["trades done"])
	box.partners:SetText(string.format(L["Players traded with: %d"], partners))
	local held = T:HeldTotal()
	local locked = 0
	for _, rec in pairs(ns.db.trades) do
		if T.Unconfirmed(rec) then
			locked = locked + 1
		end
	end
	if locked > 0 then
		box.held:SetText(held > 0 and string.format(L["Waiting for confirmation: trades (%d), boosters (%d)"], locked, held)
			or string.format(L["Waiting for confirmation: trades (%d)"], locked))
	elseif T:HeldCards() > 0 then
		-- (1.5.0) the cards that came in trades, in their days of quarantine
		box.held:SetText(string.format(L["Cards from trades that wait: %d (the next free in %s)"], T:HeldCards(),
			ns.Duration(math.max(60, (T.lockEnds or CuratorOctoFull.ServerTime()) - CuratorOctoFull.ServerTime()))))
	else
		box.held:SetText("")
	end
	box.strangers:SetChecked(ns.db.strangers and true or false)
	-- (1.14.0: without the pass of the collection, the trade window opens all the same, and says why: Pass.lua)
	local ok, why = T:CanTrade()
	CuratorOctoFull.SetEnabled(box.new, (ok or why == "pass") and true or false)
end

-- The members: whether they are there, a trade with them (their Curator trades: 0.22 and later).
function A:PaintGuildRows()
	for _, r in ipairs(self.frame.list.rows) do
		if r:IsShown() and r.member then
			r.dot:ClearAllPoints()
			r.dot:SetPoint("LEFT", r.name, "LEFT", math.min(190, ns.TextWidth(r.name)) + 6, 0)
			r.dot:SetOnline(T:Online(r.member))
			local okT, whyT = T:CanTrade()
			local can = T:CanReach(r.member) ~= false and (okT or whyT == "pass")
			CuratorOctoFull.SetShown(r.trade, not G:IsMe(r.member))
			CuratorOctoFull.SetEnabled(r.trade, can and true or false)
			r.trade:SetAlpha(can and 1 or 0.4)
		end
	end
end

function A:GuildRowTooltip(r)
	local name = r.member
	if not name then
		return
	end
	local s = self:Series()
	local sum = G:Summary(name, s)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Short(name), 1, 1, 1)
	local i = G:Profile(name)
	if i then
		local title, c = ns.Achievements:TitleOf(i)
		GameTooltip:AddLine(title, c[1], c[2], c[3])
	end
	if sum then
		GameTooltip:AddLine(C:SeriesName(s) .. " · " .. string.format(L["%d / %d cards"], sum.o, sum.n), 0.85, 0.85, 0.85)
		if (sum.sh or 0) > 0 then
			GameTooltip:AddLine(C:CopiesLine(nil, "shiny", sum.sh, s), 0.75, 0.75, 1)
		end
		if (sum.ho or 0) > 0 then
			GameTooltip:AddLine(C:CopiesLine(nil, "holo", sum.ho, s), 1, 0.8, 0.42)
		end
	end
	local online = T:Online(name)
	if online ~= nil then
		GameTooltip:AddLine(online and L["online"] or L["offline"], online and 0.3 or 0.6, online and 1 or 0.6, online and 0.35 or 0.6)
	end
	GameTooltip:AddLine(L["Click: see their album"], 0.3, 1, 0.3)
	GameTooltip:Show()
end

function A:SocialNavTooltip(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	local key = b.sec.key
	GameTooltip:AddLine(L[b.sec.label], 1, 1, 1)
	if key == "guild" then
		GameTooltip:AddLine(L["The finds of your guild, its members with Curator and their showcases, and the cards they look for that you have to spare."], 0.85, 0.85, 0.85, true)
	elseif key == "trades" then
		GameTooltip:AddLine(L["Your trades with other players: those open, then the history."], 0.85, 0.85, 0.85, true)
		local n = T:Waiting()
		if n > 0 then
			GameTooltip:AddLine(string.format(L["Offers to answer: %d"], n), GOLDEN[1], GOLDEN[2], GOLDEN[3])
		end
	else
		GameTooltip:AddLine(L["The cards you look for, and those your guild looks for that you have to spare."], 0.85, 0.85, 0.85, true)
	end
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The trades
-------------------------------------------------------------------------------
-- Where a trade is, in a few words, and its colour.
function A:TradeState(rec)
	local who = Short(rec.with)
	local st = rec.st
	if st == "draft" then
		return L["A new trade"], GOLDEN
	elseif st == "in" then
		return string.format((rec.rev > 1 and L["%s changed the offer"] or L["%s makes you an offer"]), who), GOLDEN
	elseif st == "out" then
		-- (1.12.0: the offer on the wire, not there yet; its player offline)
		if not rec.got then
			local Wr = ns.Wire
			if rec.lost or (Wr and Wr:Offline(rec.with)) or T:Online(rec.with) == false then
				return string.format(L["%s is offline: the offer waits"], who), DIM
			end
			return string.format(L["On its way to %s..."], who), BLUE
		end
		return string.format(L["Waiting for %s"], who), BLUE
	elseif st == "acc" then
		if not rec.agot then
			return string.format(L["Accepted: your answer is on its way to %s"], who), BLUE
		end
		return L["Accepted: the trade is being made"], BLUE
	elseif st == "done" then
		if T.Unconfirmed(rec) then
			return string.format(L["Done: waiting for %s to save it"], who), { 1, 0.8, 0.45 }
		end
		return L["Trade made"], GREEN
	end
	local why = rec.why
	local mine = rec.by == "me"
	if why == "declined" then
		return mine and string.format(L["%s refused"], who) or L["You refused"], RED
	elseif why == "cancelled" then
		return mine and L["You withdrew your offer"] or string.format(L["%s withdrew the offer"], who), DIM
	elseif why == "expired" then
		return L["Expired"], DIM
	elseif why == "reversed" then
		return string.format(L["Undone: not saved by %s"], who), RED
	elseif why == "refused" then
		return string.format(L["%s does not take offers from strangers"], who), RED
	elseif why == "edited" then
		return L["Impossible: a test or edited collection"], RED
	elseif why == "version" then
		return string.format(L["%s must update Curator"], who), RED
	elseif why == "busy" then
		return string.format(L["%s has too many offers waiting"], who), RED
	elseif why == "gone" then
		return L["Impossible: something was missing"], RED
	elseif why == "pass" or why == "nopass" then
		-- (1.14.0, Pass.lua: "pass", they could not check mine; "nopass", theirs is not there or did not hold. 1.14.3: the
		-- trades need the pass no more, only a Curator of before asks for it: theirs, to update)
		return string.format(L["%s must update Curator"], who), RED
	end
	return L["Cancelled"], DIM
end

function A:RefreshTrades()
	local page = self.frame.soc
	local tr = page.trades
	local tab = self.tradeTab or "open"
	self.tradeTab = tab
	local open, past = T:List()
	self:SetTitle(L["Trades"], string.format(L["Open: %d  ·  Done: %d"], CuratorOctoFull.Length(open), (T:Done())))
	for _, b in ipairs(tr.tabs) do
		local n = b.key == "open" and CuratorOctoFull.Length(open) or CuratorOctoFull.Length(past)
		b:SetLabel(string.format((b.key == "open" and L["Open (%d)"] or L["History (%d)"]), n))
		b:SetSelected(b.key == tab)
	end
	local list = tab == "open" and open or past
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / ROWS))
	self.tradePage = math.max(1, math.min(self.tradePage or 1, pages))
	for i, r in ipairs(tr.rows) do
		local rec = list[(self.tradePage - 1) * ROWS + i]
		r.rec = rec
		CuratorOctoFull.SetShown(r, rec ~= nil)
		if rec then
			local gift = CuratorOctoFull.Length(rec.take) == 0 and CuratorOctoFull.Length(rec.give) > 0
			local gifted = CuratorOctoFull.Length(rec.give) == 0 and CuratorOctoFull.Length(rec.take) > 0
			Hud.SetIcon(r.icon, (gift or gifted) and { "Gift" } or { "Swap" })
			r.name:SetText(Short(rec.with))
			r.dot:ClearAllPoints()
			r.dot:SetPoint("LEFT", r.name, "LEFT", math.min(170, ns.TextWidth(r.name)) + 6, 0)
			local online
			if T.OPEN[rec.st] then
				online = T:Online(rec.with)
			end
			r.dot:SetOnline(online)
			local text, col = self:TradeState(rec)
			S.SetFontObject(r.state, "GameFontHighlightSmall")
			r.state:SetText(text)
			if ns.TextWidth(r.state) > 178 then
				S.Fit(r.state, text, 178, 10, 7.5)
			end
			r.state:SetTextColor(col[1], col[2], col[3])
			for _, x in ipairs({ { r.give, L["You give:"], rec.give }, { r.take, L["You receive:"], rec.take } }) do
				local fs = x[1]
				local room = fs:GetWidth()
				S.SetFontObject(fs, "GameFontHighlightSmall")
				local t = Colour(x[2], DIM) .. " " .. SideText(x[3])
				fs:SetText(t)
				if ns.TextWidth(fs) > room then
					-- (smaller, then only the first thing and how many more)
					S.Fit(fs, t, room, 10, 8.5)
					if ns.TextWidth(fs) > room then
						fs:SetText(Colour(x[2], DIM) .. " " .. SideText(x[3], 1))
					end
				end
			end
			local t = rec.td or rec.u or rec.t
			r.when:SetText(t and fmtDate("%d/%m", t) or "")
			r.pulse = rec.st == "in"
			CuratorOctoFull.SetShown(r.glow, r.pulse)
			r:SetSelected(false)
			if rec.st == "done" and T.Unconfirmed(rec) then
				r.mark:SetTexture(MEDIA .. "Hourglass")
				r.mark:Show()
			elseif rec.st == "done" then
				r.mark:SetTexture(MEDIA .. "Check")
				r.mark:Show()
			else
				r.mark:Hide()
			end
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		tr.empty:SetText(tab == "open" and L["No trade open. Propose one with New trade, or from a card shown in the chat."]
			or L["No trade yet."])
	else
		tr.empty:SetText("")
	end
	self:ShowPager(true)
	self:SetPager(self.tradePage, pages)
end

function A:TradeRowTooltip(r)
	local rec = r.rec
	if not rec then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(string.format(L["Trade with %s"], Short(rec.with)), 1, 1, 1)
	local text, col = self:TradeState(rec)
	GameTooltip:AddLine(text, col[1], col[2], col[3], true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["You give:"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
	for _, it in ipairs(rec.give) do
		GameTooltip:AddLine("  " .. ItemText(it))
	end
	if CuratorOctoFull.Length(rec.give) == 0 then
		GameTooltip:AddLine("  " .. L["nothing"], 0.6, 0.6, 0.6)
	end
	GameTooltip:AddLine(L["You receive:"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
	for _, it in ipairs(rec.take) do
		GameTooltip:AddLine("  " .. ItemText(it))
	end
	if CuratorOctoFull.Length(rec.take) == 0 then
		GameTooltip:AddLine("  " .. L["nothing"], 0.6, 0.6, 0.6)
	end
	if T.Unconfirmed(rec) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format(L["What came from %s waits until their game has saved the trade (a reload or a new login): it cannot go into a contract or another trade yet, and its boosters wait to be opened."], Short(rec.with)), 1, 0.8, 0.45, true)
	end
	GameTooltip:AddLine(L["Click to see it"], 0.3, 1, 0.3)
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The cards looked for
-------------------------------------------------------------------------------
-- Mine (who has them to spare), and those my guild looks for that I have to spare (who looks for them).
function A:WishLists()
	local mine = T:Wishes()
	local theirs = {}
	for _, card in ipairs(T:SoughtSpare()) do
		theirs[CuratorOctoFull.Length(theirs) + 1] = card
	end
	-- (also from the players met: what they look for that I have to spare)
	local seen = {}
	for _, card in ipairs(theirs) do
		seen[card.key] = true
	end
	for _, m in pairs(ns.db.met) do
		for key in pairs(m.wish or {}) do
			local card = ns.Cards[key]
			if card and not seen[key] then
				local spare = 0
				for _, fin in ipairs(ns.Contract.FINISHES) do
					spare = spare + T:Spare(card, fin, true)
				end
				if spare > 0 then
					seen[key] = true
					theirs[CuratorOctoFull.Length(theirs) + 1] = card
				end
			end
		end
	end
	table.sort(theirs, function(a, b)
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		end
		return a.npc < b.npc
	end)
	return mine, theirs
end

-- (1.14.0) corrupt: the corruption shown on a corrupted card (a copy of a trade: its own; false: not known yet, "?").
-- (1.14.0) pattern: the pattern shown on a titanforged card (a copy of a trade: its own, the first of its line).
local function PlaceCard(c, card, owned, finish, count, corrupt, pattern)
	pattern = finish == "holo" and pattern or nil
	local sig = card.key .. (owned and "+" or "-") .. (finish or "") .. ":" .. (count or 0) .. ":" .. tostring(corrupt) .. ":" .. tostring(pattern or 0)
	if c.sig ~= sig or not c:IsShown() then
		c.sig = sig
		c:SetCard(card, { owned = owned, finish = finish, count = count, corrupt = corrupt or nil, corruptUnknown = corrupt == false or nil,
			pattern = pattern })
		c:ShowSide("front")
	end
	c:Show()
end

-- The finish of a card to spare that goes first: the normal copies, then the shiny, then the holographic (1.14.0, then
-- the corrupted).
local function SpareFinish(card)
	for _, fin in ipairs({ "normal", "shiny", "holo", "corrupt" }) do
		if T:Spare(card, fin, true) > 0 then
			return fin ~= "normal" and fin or nil
		end
	end
end

function A:RefreshWishes()
	local ws = self.frame.soc.wish
	local mine, theirs = self:WishLists()
	self.wishMine, self.wishTheirs = mine, theirs
	self:SetTitle(L["Wanted cards"], string.format(L["You look for: %d  ·  Your guild looks for: %d"], CuratorOctoFull.Length(mine), CuratorOctoFull.Length(theirs)))
	for _, st in ipairs({ ws.mine, ws.theirs }) do
		local list = st.kind == "mine" and mine or theirs
		local key = st.kind == "mine" and "wishPage" or "wantPage"
		local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / WISH_COLS))
		self[key] = math.max(1, math.min(self[key] or 1, pages))
		local p = self[key]
		st.title:SetText(st.kind == "mine" and string.format(L["You look for (%d)"], CuratorOctoFull.Length(list)) or string.format(L["Your guild looks for (%d)"], CuratorOctoFull.Length(list)))
		CuratorOctoFull.SetShown(st.prev, pages > 1)
		CuratorOctoFull.SetShown(st.next, pages > 1)
		CuratorOctoFull.SetEnabled(st.prev, p > 1)
		CuratorOctoFull.SetEnabled(st.next, p < pages)
		st.pages:SetText(pages > 1 and string.format(L["Page %d / %d"], p, pages) or "")
		for i, b in ipairs(st.cards) do
			local card = list[(p - 1) * WISH_COLS + i]
			b.cardRef = card
			CuratorOctoFull.SetShown(b, card ~= nil)
			if card then
				if st.kind == "mine" then
					PlaceCard(b.card, card, false)
					local where = string.format(("%s #%d"), C:SeriesName(card.series), card.num)
					S.SetFontObject(b.line1, "GameFontHighlightSmall")
					b.line1:SetText(where)
					if ns.TextWidth(b.line1) > WISH_CELL_W - 4 then
						S.Fit(b.line1, where, WISH_CELL_W - 4, 10, 7.5)
					end
					b.line1:SetTextColor(0.85, 0.85, 0.88)
					local holders = T:HoldersOf(card)
					b.holders = holders
					if CuratorOctoFull.Length(holders) > 0 then
						b.line2:SetText(string.format(L["Spare: %s"], table.concat(self:ShortNames(holders, 2), ", ")))
						b.line2:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
					else
						b.line2:SetText(L["Nobody yet"])
						b.line2:SetTextColor(0.55, 0.55, 0.58)
					end
				else
					local fin = SpareFinish(card)
					b.finish = fin
					PlaceCard(b.card, card, true, fin)
					S.SetFontObject(b.line1, "GameFontHighlightSmall")
					b.line1:SetText(C:Name(card))
					if ns.TextWidth(b.line1) > WISH_CELL_W - 4 then
						S.Fit(b.line1, C:Name(card), WISH_CELL_W - 4, 10, 7.5)
					end
					local rc = ns.RARITY[card.rarity].text
					b.line1:SetTextColor(rc[1], rc[2], rc[3])
					local seekers = T:SoughtBy(card)
					b.seekers = seekers
					b.line2:SetText(string.format(L["Wanted by %s"], table.concat(self:ShortNames(seekers, 2), ", ")))
					b.line2:SetTextColor(BLUE[1], BLUE[2], BLUE[3])
				end
			else
				b.card.sig = nil
			end
		end
		if CuratorOctoFull.Length(list) == 0 then
			st.empty:SetText(st.kind == "mine" and L["You look for no card yet."]
				or L["Nobody of your guild looks for a card you have to spare."])
		else
			st.empty:SetText("")
		end
	end
	self:ShowPager(false)
end

-- Short names, the first ones and how many more.
function A:ShortNames(names, room)
	local out = {}
	for i = 1, math.min(CuratorOctoFull.Length(names), room) do
		out[i] = Short(names[i])
	end
	if CuratorOctoFull.Length(names) > room then
		out[CuratorOctoFull.Length(out) + 1] = "+" .. (CuratorOctoFull.Length(names) - room)
	end
	return out
end

function A:WishPage(kind, delta)
	local key = kind == "mine" and "wishPage" or "wantPage"
	self[key] = (self[key] or 1) + delta
	ns.Play(ns.SND.page)
	self:Refresh()
end

function A:WishTooltip(b)
	local card = b.cardRef
	if not card then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	local strip = b:GetParent()
	if strip.kind == "mine" then
		local r = ns.RARITY[card.rarity]
		GameTooltip:AddLine("???", 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L[r.label], r.text[1], r.text[2], r.text[3])
		GameTooltip:AddLine(string.format(("%s · %d/%d"), C:SeriesName(card.series), card.num, card.series.official or CuratorOctoFull.Length(card.series.list)), 0.62, 0.62, 0.62)
		local holders = b.holders or {}
		if CuratorOctoFull.Length(holders) > 0 then
			GameTooltip:AddLine(string.format(L["To spare: %s"], table.concat(self:ShortNames(holders, 6), ", ")), GREEN[1], GREEN[2], GREEN[3], true)
			GameTooltip:AddLine(string.format(L["Click: ask %s for it"], Short(holders[1])), 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Nobody you know has it to spare yet."], 0.6, 0.6, 0.6, true)
		end
		GameTooltip:AddLine(L["Right click: stop looking for it"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
	else
		ns.Booster:CardTooltip(card, b.finish, C:Entry(card))
		local seekers = b.seekers or {}
		GameTooltip:AddLine(string.format(L["Wanted by %s"], table.concat(self:ShortNames(seekers, 6), ", ")), BLUE[1], BLUE[2], BLUE[3], true)
		if CuratorOctoFull.Length(seekers) > 0 then
			GameTooltip:AddLine(string.format(L["Click: offer it to %s"], Short(seekers[1])), 0.3, 1, 0.3)
		end
	end
	GameTooltip:Show()
end

function A:WishClick(b, button)
	local card = b.cardRef
	if not card then
		return
	end
	local strip = b:GetParent()
	if strip.kind == "mine" then
		if button == "RightButton" then
			T:ToggleWish(card)
			ns.Play(ns.SND.page)
			return self:Refresh()
		end
		local holders = b.holders or {}
		if CuratorOctoFull.Length(holders) > 0 then
			ns.Play(ns.SND.cardFlip)
			self:StartTrade(holders[1], nil, { { k = card.key, n = 1 } })
		end
		return
	end
	local seekers = b.seekers or {}
	if CuratorOctoFull.Length(seekers) > 0 then
		self:OfferSpare(seekers[1], card, b.finish)
	end
end

-- A card of mine to spare offered to a player who looks for it: a trade with them, a copy of it on my side (finish: the
-- one that goes first, SpareFinish). (1.14.2) back: the section the trade closes back to (the guild).
function A:OfferSpare(who, card, finish, back)
	ns.Play(ns.SND.cardFlip)
	self:StartTrade(who, { { k = card.key, f = finish, n = 1 } }, nil, back)
end

-------------------------------------------------------------------------------
-- (1.14.2) The guild: its finds (Comm.lua: G:FindList), its members, the cards they look for that I have to spare
-------------------------------------------------------------------------------
-- How long ago, in a few letters: "now", "3 min ago", "5 h ago", "2 d ago".
local function Ago(t)
	local s = math.max(0, CuratorOctoFull.ServerTime() - (tonumber(t) or 0))
	if s < 60 then
		return L["now"]
	elseif s < 3600 then
		return string.format(L["%s ago"], string.format(L["%d min"], math.floor(s / 60)))
	elseif s < 86400 then
		return string.format(L["%s ago"], string.format(L["%d h"], math.floor(s / 3600)))
	end
	return string.format(L["%s ago"], string.format(L["%d d"], math.floor(s / 86400)))
end

-- The name of my guild (nil: none, or not told yet).
local function GuildName()
	if not (IsInGuild and IsInGuild() and GetGuildInfo) then
		return nil
	end
	local ok, name = pcall(GetGuildInfo, "player")
	if ok and type(name) == "string" and name ~= "" and not (issecretvalue and issecretvalue(name)) then
		return name
	end
	return nil
end

-- A rank of the cases (UI/Crate.lua: CR.RANKS), its colour and the colour of its words.
local function CaseRank(r)
	local CR = ns.CrateUI
	local rank = CR and CR.RANKS and (CR.RANKS[tonumber(r) or 1] or CR.RANKS[1])
	if not rank then
		return { label = "Rare", color = { 0.29, 0.41, 1 } }, { 0.29, 0.41, 1 }
	end
	return rank, rank.text or rank.color
end

-- What a find shows (x: a find, Comm.lua): { kind, card, finish } a card of the albums (a golden quest: its leader, with
-- leader); { kind, s, r, finish } a booster whose card was not told (a version of before); { kind, case } the card that
-- came out of a case; { kind, ach } an achievement. nil: something this version does not know.
local function FindLook(x)
	local k = x.k
	if k == "p" or k == "o" then
		local card = type(x.c) == "string" and ns.Cards[x.c] or nil
		if card then
			local fin = (k == "p") and x.f or x.cf
			return { kind = k, card = card, finish = (fin == "holo" or fin == "shiny") and fin or nil }
		end
		local s = k == "o" and ns.SeriesByKey(x.s or "") or nil
		if s then
			return { kind = k, s = s, r = math.max(1, math.min(CuratorOctoFull.Length(ns.RARITY), tonumber(x.r) or 1)), finish = x.f }
		end
	elseif k == "k" then
		local v = G.CaseCard(x.e, x.r, x.x, x.f)
		if v then
			return { kind = k, case = v }
		end
	elseif k == "a" then
		local AC = ns.Achievements
		local a = AC and AC:Build() and AC.byId[x.a or ""]
		if a then
			return { kind = k, ach = a }
		end
	elseif k == "g" then
		local GQ = ns.Golden
		local l = GQ and GQ:Leader(x.l)
		local card = l and ns.Cards["c" .. tostring(l.npc)]
		if card then
			return { kind = k, leader = l, card = card }
		end
	end
	return nil
end

-- The members of my guild Curator knows (what they shared: Comm.lua), those online first, then the finest collections.
-- (1.14.2) Still in my guild: once the game told who is in it (Trade.lua: T:ScanRoster), one who left it is not listed
-- any more; before that, every one known.
local function InGuild(name)
	local roster = T.roster
	if type(roster) ~= "table" or next(roster) == nil then
		return true
	end
	return roster[name] ~= nil
end

function A:GuildMembers()
	local out = {}
	local B = ns.Bans
	for name, m in pairs((ns.db and ns.db.guild) or {}) do
		if type(m) == "table" and not G:IsMe(name) and not (B and B:Sender(name)) and InGuild(name) then
			out[CuratorOctoFull.Length(out) + 1] = { name = name, short = Short(name), i = G:Profile(name), online = T:Online(name) }
		end
	end
	table.sort(out, function(a, b)
		local oa, ob = a.online and 2 or (a.online == nil and 1 or 0), b.online and 2 or (b.online == nil and 1 or 0)
		if oa ~= ob then
			return oa > ob
		end
		local ca, cb = a.i and a.i.owned or -1, b.i and b.i.owned or -1
		if ca ~= cb then
			return ca > cb
		end
		return a.short < b.short
	end)
	return out
end

-- The cards the members of my guild look for that I have to spare (the strip "Your guild looks for" of the cards looked
-- for, member by member: T:SoughtSpare, T:SoughtBy): { card, who, finish (the copy that goes first), spare (how many) },
-- the rarest first.
function A:GuildWanted()
	local out = {}
	local B = ns.Bans
	for _, card in ipairs(T:SoughtSpare()) do
		local spare = 0
		for _, fin in ipairs(T.FINISHES) do
			spare = spare + T:Spare(card, fin, true)
		end
		local fin = SpareFinish(card)
		for _, who in ipairs(T:SoughtBy(card)) do
			if ns.db.guild[who] and not (B and B:Sender(who)) and InGuild(who) then
				out[CuratorOctoFull.Length(out) + 1] = { card = card, who = who, finish = fin, spare = spare }
			end
		end
	end
	table.sort(out, function(a, b)
		if a.card.rarity ~= b.card.rarity then
			return a.card.rarity > b.card.rarity
		end
		if a.card.npc ~= b.card.npc then
			return a.card.npc < b.card.npc
		end
		return a.who < b.who
	end)
	return out
end

-- The list of a tab of the guild, and how many of it a page holds.
function A:GuildList(tab)
	if tab == "members" then
		return self:GuildMembers(), ROWS
	elseif tab == "wanted" then
		return self:GuildWanted(), ROWS
	end
	local out = {}
	for _, f in ipairs(G:FindList()) do
		local look = FindLook(f.x)
		if look then
			look.who, look.t = f.who, f.t
			out[CuratorOctoFull.Length(out) + 1] = look
		end
	end
	return out, FIND_COLS * FIND_ROWS
end

function A:SetGuildTab(key)
	if key ~= self.guildTab then
		self.guildTab, self.guildPage = key, 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- (its cards set again when it shows again: hidden, they let go of their creatures)
function A:ForgetGuildCards()
	local soc = self.frame and self.frame.soc
	local gd = soc and soc.guild
	if not gd then
		return
	end
	for _, b in ipairs(gd.cells or {}) do
		b.card.sig = nil
	end
	for _, r in ipairs(gd.wantRows or {}) do
		r.card.sig = nil
	end
	for _, r in ipairs(gd.memberRows or {}) do
		for _, slot in ipairs(r.show) do
			slot.card.sig = nil
		end
	end
end

-- The guild: its name over the page, its three tabs and their counts, the one shown, its pages.
function A:RefreshGuildPage()
	local gd = self.frame.soc.guild
	local tab = self.guildTab or "finds"
	self.guildTab = tab
	local finds = self:GuildList("finds")
	local members = self:GuildMembers()
	local wanted = self:GuildWanted()
	self:SetTitle(GuildName() or L["Guild"], string.format(L["Members with Curator: %d  ·  Finds: %d"], CuratorOctoFull.Length(members), CuratorOctoFull.Length(finds)))
	local counts = { finds = CuratorOctoFull.Length(finds), members = CuratorOctoFull.Length(members), wanted = CuratorOctoFull.Length(wanted) }
	local labels = { finds = L["Finds (%d)"], members = L["Members (%d)"], wanted = L["They look for (%d)"] }
	for _, b in ipairs(gd.tabs) do
		b:SetLabel(string.format(labels[b.key], counts[b.key]))
		b:SetSelected(b.key == tab)
	end
	local list = (tab == "members" and members) or (tab == "wanted" and wanted) or finds
	local per = (tab == "finds") and FIND_COLS * FIND_ROWS or ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / per))
	self.guildPage = math.max(1, math.min(self.guildPage or 1, pages))
	local first = (self.guildPage - 1) * per
	CuratorOctoFull.SetShown(gd.wall, tab == "finds")
	CuratorOctoFull.SetShown(gd.members, tab == "members")
	CuratorOctoFull.SetShown(gd.wanted, tab == "wanted")
	if tab == "finds" then
		self:PaintFinds(gd, finds, first)
	elseif tab == "members" then
		self:PaintMembers(gd, members, first)
	else
		self:PaintWanted(gd, wanted, first)
	end
	local empty = ""
	if CuratorOctoFull.Length(list) == 0 then
		if not (IsInGuild and IsInGuild()) then
			empty = L["You are not in a guild."]
		elseif tab == "finds" then
			empty = L["No find yet: the cards your guild pulls, rare or better, and the boosters and the cases it opens show here as they come."]
		elseif tab == "members" then
			empty = L["Nobody known yet: the members of your guild show here once they are online with Curator."]
		else
			empty = L["Nobody of your guild looks for a card you have to spare."]
		end
	end
	gd.empty:SetText(empty)
	self:ShowPager(true)
	self:SetPager(self.guildPage, pages)
end

-- A text in its place, made smaller (then cut by the client) when it is too long.
local function PutText(fs, object, text, room, size, minSize)
	S.SetFontObject(fs, object)
	fs:SetText(text)
	if ns.TextWidth(fs) > room then
		S.Fit(fs, text, room, size, minSize)
	end
end

-- The finds, a wall of their cards.
local GOLD_GLOW = { 1, 0.8, 0.32 }
local TITAN_GLOW = { 1, 0.86, 0.46 }
function A:PaintFinds(gd, finds, first)
	local wall = gd.wall
	if not gd.cells then
		gd.cells = {}
		local cw = math.floor(wall:GetWidth() / FIND_COLS)
		for i = 1, FIND_COLS * FIND_ROWS do
			gd.cells[i] = NewFind(wall, i, cw)
		end
	end
	for i, b in ipairs(gd.cells) do
		local look = finds[first + i]
		b.look = look
		CuratorOctoFull.SetShown(b, look ~= nil)
		if look then
			self:PaintFind(b, look, i)
		else
			b.card.sig = nil
		end
	end
end

function A:PaintFind(b, look, i)
	local card = look.card
	local CM = ns.CaseCards
	CuratorOctoFull.SetShown(b.card, card ~= nil)
	CuratorOctoFull.SetShown(b.pack, card == nil and look.s ~= nil)
	CuratorOctoFull.SetShown(b.icon, look.ach ~= nil)
	CuratorOctoFull.SetShown(b.ring, look.ach ~= nil)
	if b.ccard then
		CuratorOctoFull.SetShown(b.ccard, look.case ~= nil)
	end
	local glow, ga, name, ink = GOLD_GLOW, 0, "", S.WHITE
	if card then
		PlaceCard(b.card, card, true, look.finish)
		b.card.phase = i * 0.37
		local r = card.rarity
		if look.kind == "g" then
			-- (a golden quest: its leader, in the gold of the golden boosters)
			glow, ga = GOLD_GLOW, 0.55
			name, ink = ns.Golden:LeaderName(look.leader), GOLDEN
		else
			glow, ga = ns.RARITY[r].glow, (r >= 5 and 0.62) or (r == 4 and 0.46) or (r == 3 and 0.3) or 0.14
			if look.finish == "holo" then
				glow, ga = TITAN_GLOW, math.max(ga, 0.5)
			end
			name, ink = C:Name(card), ns.RARITY[r].text
		end
	else
		b.card.sig = nil
		if look.s then
			-- (a booster whose card was not told: its pack, the light of its best card)
			b.pack:SetSeries(look.s)
			glow, ga = ns.RARITY[look.r].glow, 0.42
			name, ink = C:SeriesName(look.s), ns.RARITY[look.r].text
		elseif look.case and CM then
			if not b.ccard then
				b.ccard = CM.New(b, 60)
				b.ccard:SetPoint("TOP", b, "TOP", 0, -3)
				-- (its name under it, not on its plate: too small there)
				b.ccard.name:Hide()
			end
			local x = CM.Look(look.case) or { tier = look.case.r }
			x.wear, x.grade, x.count = nil, nil, nil
			b.ccard:Set(x)
			b.ccard:Show()
			local rank, rink = CaseRank(look.case.r)
			glow, ga = rank.color, 0.22 + 0.08 * (tonumber(look.case.r) or 1)
			name, ink = CM.Name(look.case), rink
		elseif look.ach then
			Hud.SetIcon(b.icon, look.ach.icon)
			glow, ga = GOLD_GLOW, 0.4
			name, ink = ns.Achievements:Name(look.ach), GOLDEN
		end
	end
	b.glow:SetVertexColor(glow[1], glow[2], glow[3])
	b.glow:SetAlpha(ga)
	local room = b:GetWidth() - 8
	-- (a long name: smaller first, then on two lines)
	CuratorOctoFull.SetWordWrap(b.line1, false)
	PutText(b.line1, "GameFontHighlightSmall", name, room, 10, 8.5)
	if ns.TextWidth(b.line1) > room then
		CuratorOctoFull.SetWordWrap(b.line1, true)
	end
	b.line1:SetTextColor(ink[1], ink[2], ink[3])
	PutText(b.line2, "GameFontNormalSmall", Short(look.who), room, 10, 7.5)
	PutText(b.line3, "GameFontDisableSmall", Ago(look.t), room, 10, 7.5)
end

function A:FindTooltip(b)
	local look = b.look
	if not look then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	local who = Short(look.who)
	local album = true
	if look.kind == "g" then
		GameTooltip:AddLine(L["Golden quest"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		GameTooltip:AddLine(string.format(L["%s turned in a golden quest to %s."], who, ns.Golden:LeaderName(look.leader)), 0.85, 0.85, 0.85, true)
		album = false
	elseif look.card then
		ns.Booster:CardTooltip(look.card, { finish = look.finish })
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format((look.kind == "o" and L["%s opened it in a booster, live."] or L["%s pulled it."]), who), BLUE[1], BLUE[2], BLUE[3], true)
	elseif look.s then
		local r = ns.RARITY[look.r]
		GameTooltip:AddLine(C:SeriesName(look.s), 1, 1, 1)
		GameTooltip:AddLine(string.format(L["Its finest card: %s"], L[r.label]), r.text[1], r.text[2], r.text[3])
		GameTooltip:AddLine(string.format(L["%s opened a booster of this album, live."], who), BLUE[1], BLUE[2], BLUE[3], true)
	elseif look.case then
		local v = look.case
		local rank, rink = CaseRank(v.r)
		local CR = ns.CrateUI
		local fin = v.f and CR and CR.FINISH_NAME and CR.FINISH_NAME[v.f]
		local def = ns.Crates and ns.Crates[v.c]
		GameTooltip:AddLine(ns.CaseCards.Name(v), rink[1], rink[2], rink[3])
		GameTooltip:AddLine(L[rank.label] .. (fin and (" · " .. L[fin]) or ""), rank.color[1], rank.color[2], rank.color[3])
		if def and def.title then
			GameTooltip:AddLine(L[def.title], 0.75, 0.75, 0.8)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(string.format(L["%s opened it in a case, live."], who), BLUE[1], BLUE[2], BLUE[3], true)
		album = false
	elseif look.ach then
		GameTooltip:AddLine(ns.Achievements:Name(look.ach), GOLDEN[1], GOLDEN[2], GOLDEN[3])
		GameTooltip:AddLine(string.format(L["%d points"], look.ach.pts or 0), 0.85, 0.85, 0.85)
		GameTooltip:AddLine(string.format(L["%s earned"], who), BLUE[1], BLUE[2], BLUE[3])
		album = false
	end
	GameTooltip:AddLine(Ago(look.t), DIM[1], DIM[2], DIM[3])
	GameTooltip:AddLine(album and L["Click: see their album"] or L["Click: see their collection"], 0.3, 1, 0.3)
	GameTooltip:Show()
end

-- A find clicked: the album of that card at its member's (a booster: its album), else their collection.
function A:FindClick(b)
	local look = b.look
	if not look then
		return
	end
	ns.Play(ns.SND.cardFlip)
	local s = (look.kind ~= "g" and look.card and look.card.series) or look.s
	if s then
		return self:ShowMember(look.who, s)
	end
	return self:ShowPlayer(look.who)
end

-- The members, a row each: their showcase small on its right (the cards of the albums, those of the cases).
function A:PaintMembers(gd, members, first)
	local box = gd.members
	if not gd.memberRows then
		gd.memberRows = {}
		for i = 1, ROWS do
			gd.memberRows[i] = NewMember(box, i, box:GetWidth())
		end
	end
	local CM = ns.CaseCards
	local okT, whyT = T:CanTrade()
	for i, r in ipairs(gd.memberRows) do
		local m = members[first + i]
		r.member = m and m.name
		CuratorOctoFull.SetShown(r, m ~= nil)
		if m then
			PutText(r.name, "GameFontNormal", m.short, 220, 12, 8)
			r.dot:ClearAllPoints()
			r.dot:SetPoint("LEFT", r.name, "LEFT", math.min(220, ns.TextWidth(r.name)) + 6, 0)
			r.dot:SetOnline(m.online)
			local parts = {}
			local p = m.i
			if p then
				local title, tcol = ns.Achievements:TitleOf(p)
				parts[CuratorOctoFull.Length(parts) + 1] = Colour(title, tcol)
				if p.xp then
					local lv = ns.Level.Of(p.xp)
					parts[CuratorOctoFull.Length(parts) + 1] = ns.Level.EmblemText((ns.Level.RankOf(lv)), 13) .. " " .. string.format(L["Level %d"], lv)
				end
				parts[CuratorOctoFull.Length(parts) + 1] = (p.owned == 1) and L["1 card"] or string.format(L["%d cards"], p.owned or 0)
			else
				parts[CuratorOctoFull.Length(parts) + 1] = Colour(L["Their profile comes once they are online with Curator."], DIM)
			end
			PutText(r.info, "GameFontHighlightSmall", table.concat(parts, "  ·  "), r.info:GetWidth(), 10, 7.5)
			local show = G:Showcase(m.name) or {}
			for k, slot in ipairs(r.show) do
				local v = show[k]
				if v and v.card then
					if slot.cc then
						slot.cc:Hide()
					end
					PlaceCard(slot.card, v.card, true, v.finish)
					slot.card.phase = i + k * 0.4
					slot:Show()
				elseif v and v.copy and CM then
					slot.card:Hide()
					slot.card.sig = nil
					if not slot.cc then
						slot.cc = CM.New(slot, SHOW_W - 6)
						slot.cc:SetPoint("CENTER")
						-- (its name in the tooltip of the row: too small on its plate)
						slot.cc.name:Hide()
					end
					local x = CM.Look(v.copy) or { tier = 1 }
					x.count = nil
					slot.cc:Set(x)
					slot.cc:Show()
					slot:Show()
				else
					slot.card.sig = nil
					slot:Hide()
				end
			end
			local can = T:CanReach(m.name) ~= false and (okT or whyT == "pass")
			CuratorOctoFull.SetEnabled(r.trade, can and true or false)
			r.trade:SetAlpha(can and 1 or 0.4)
			r:SetSelected(false)
		end
	end
end

function A:MemberTooltip(r)
	local name = r.member
	if not name then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Short(name), 1, 1, 1)
	local p = G:Profile(name)
	if p then
		local title, c = ns.Achievements:TitleOf(p)
		GameTooltip:AddLine(title, c[1], c[2], c[3])
		if p.xp then
			GameTooltip:AddLine(string.format(L["Collector level %d"], ns.Level.Of(p.xp)), 0.75, 0.62, 1)
		end
		GameTooltip:AddLine(string.format(L["%d / %d cards"], p.owned or 0, p.total or 0), 0.85, 0.85, 0.85)
		GameTooltip:AddLine(string.format(L["%d points"], p.points or 0), 0.85, 0.85, 0.85)
	end
	local show = G:Showcase(name)
	if show and CuratorOctoFull.Length(show) > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Showcase"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		for _, v in ipairs(show) do
			if v.card then
				local fin = C:FinishName(v.card, v.finish)
				local rc = ns.RARITY[v.card.rarity].text
				GameTooltip:AddLine("  " .. C:Name(v.card) .. (fin and (" · " .. fin) or ""), rc[1], rc[2], rc[3])
			elseif v.copy and ns.CaseCards then
				local _, rink = CaseRank(v.copy.r)
				GameTooltip:AddLine("  " .. ns.CaseCards.Name(v.copy), rink[1], rink[2], rink[3])
			end
		end
	end
	-- (their finest pulls, the first three: F)
	local pulls = G:History(name)
	if pulls and CuratorOctoFull.Length(pulls) > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Finest pulls"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		for k = 1, math.min(3, CuratorOctoFull.Length(pulls)) do
			local h = pulls[k]
			local fin = C:FinishName(h.card, h.finish)
			local rc = ns.RARITY[h.card.rarity].text
			GameTooltip:AddLine("  " .. C:Name(h.card) .. (fin and (" · " .. fin) or ""), rc[1], rc[2], rc[3])
		end
	end
	local online = T:Online(name)
	if online ~= nil then
		GameTooltip:AddLine(online and L["online"] or L["offline"], online and 0.3 or 0.6, online and 1 or 0.6, online and 0.35 or 0.6)
	end
	GameTooltip:AddLine(L["Click: see their collection"], 0.3, 1, 0.3)
	GameTooltip:Show()
end

-- The cards they look for that I have to spare, a row each: the button proposes a trade to that member, a copy of that
-- card on my side.
function A:PaintWanted(gd, wanted, first)
	local box = gd.wanted
	if not gd.wantRows then
		gd.wantRows = {}
		for i = 1, ROWS do
			gd.wantRows[i] = NewWanted(box, i, box:GetWidth())
		end
	end
	local okT, whyT = T:CanTrade()
	local last
	for i, r in ipairs(gd.wantRows) do
		local w = wanted[first + i]
		r.want = w
		CuratorOctoFull.SetShown(r, w ~= nil)
		if w then
			last = r
		end
		if w then
			PlaceCard(r.card, w.card, true, w.finish)
			r.card.phase = i * 0.45
			local fin = C:FinishName(w.card, w.finish)
			PutText(r.name, "GameFontNormal", C:Name(w.card) .. (fin and (" · " .. fin) or ""), r.name:GetWidth(), 12, 8)
			local rc = ns.RARITY[w.card.rarity].text
			r.name:SetTextColor(rc[1], rc[2], rc[3])
			PutText(r.info, "GameFontHighlightSmall", Colour(string.format(L["Wanted by %s"], Short(w.who)), BLUE) .. "  ·  "
				.. Colour(string.format(L["To spare: %d"], w.spare), GREEN), r.info:GetWidth(), 10, 7.5)
			r.dot:SetOnline(T:Online(w.who))
			local can = T:CanReach(w.who) ~= false and (okT or whyT == "pass")
			CuratorOctoFull.SetEnabled(r.go, can and true or false)
			local label = L["Propose a trade"]
			r.go:SetText(label)
			if ns.TextWidth(r.go.label) > r.go:GetWidth() - 12 then
				S.Fit(r.go.label, label, r.go:GetWidth() - 12, 12, 8)
			end
			r:SetSelected(false)
		end
	end
	gd.hint:ClearAllPoints()
	gd.hint:SetText(L["Click a card or Propose a trade: a trade with that member opens, the card already on your side."])
	if last and last ~= gd.wantRows[ROWS] then
		gd.hint:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 2, -12)
		gd.hint:Show()
	else
		gd.hint:Hide()
	end
end

function A:WantedTooltip(r)
	local w = r.want
	if not w then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	ns.Booster:CardTooltip(w.card, { finish = w.finish })
	GameTooltip:AddLine(string.format(L["Wanted by %s"], Short(w.who)), BLUE[1], BLUE[2], BLUE[3], true)
	GameTooltip:AddLine(string.format(L["To spare: %d"], w.spare), GREEN[1], GREEN[2], GREEN[3])
	GameTooltip:AddLine(string.format(L["Click: offer it to %s"], Short(w.who)), 0.3, 1, 0.3)
	GameTooltip:Show()
end

-- A card they look for offered: a trade with that member, a copy of it on my side; back to the guild after it.
function A:ProposeWanted(r)
	local w = r.want
	if w then
		self:OfferSpare(w.who, w.card, w.finish, "guild")
	end
end

-------------------------------------------------------------------------------
-- A trade, on the whole page
-------------------------------------------------------------------------------
function A:BuildTradeEditor(page)
	local W = page.W
	local ed = CreateFrame("Frame", nil, page)
	ed:SetAllPoints()
	ed:SetFrameLevel(page:GetFrameLevel() + 4)
	ed:Hide()
	page.ed = ed
	ed.back = S.Button(ed, L["Back"], 96, 22)
	ed.back:SetPoint("TOPLEFT", 0, 0)
	CuratorOctoFull.SetScript(ed.back, "OnClick", function()
		ns.Play(ns.SND.page)
		A:CloseTrade()
	end)
	ed.title = S.Text(ed, "GameFontNormalLarge", "LEFT")
	ed.title:SetPoint("TOPLEFT", 110, -1)
	CuratorOctoFull.SetWordWrap(ed.title, false)
	ed.dot = Dot(ed, 10)
	ed.info = S.Text(ed, "GameFontHighlightSmall", "LEFT")
	ed.info:SetPoint("TOPLEFT", ed.title, "BOTTOMLEFT", 0, -4)
	ed.info:SetWidth(360)
	CuratorOctoFull.SetWordWrap(ed.info, false)
	ed.state = S.Text(ed, "GameFontNormal", "RIGHT")
	ed.state:SetPoint("TOPRIGHT", -34, -2)
	ed.state:SetWidth(330)
	CuratorOctoFull.SetWordWrap(ed.state, true)
	CuratorOctoFull.SetMaxLines(ed.state, 2)

	ed.give = NewPanel(ed, "give")
	ed.give:SetPoint("TOPLEFT", 0, PANEL_Y)
	ed.take = NewPanel(ed, "take")
	ed.take:SetPoint("TOPRIGHT", 0, PANEL_Y)
	-- the arrows between them
	ed.swap = ed:CreateTexture(nil, "ARTWORK")
	ed.swap:SetTexture(MEDIA .. "Swap")
	CuratorOctoFull.SetSize(ed.swap, 56, 56)
	ed.swap:SetPoint("CENTER", ed, "TOP", 0, PANEL_Y - PANEL_H / 2 + 6)
	ed.swapGlow = ed:CreateTexture(nil, "BORDER")
	ed.swapGlow:SetTexture(MEDIA .. "Glow")
	ed.swapGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(ed.swapGlow, 120, 120)
	ed.swapGlow:SetPoint("CENTER", ed.swap, "CENTER")
	ed.swapGlow:SetVertexColor(1, 0.8, 0.4)
	ed.swapGlow:SetAlpha(0.25)

	-- the gauge of the balance: the bar of the experience as its ground, its light from the middle to
	-- where it leans, the star of where it leans
	local gy = PANEL_Y - PANEL_H - 22
	local g = Hud.XPBar(ed, GAUGE_W, 14)
	g:SetPoint("TOP", ed, "TOP", 0, gy)
	g:SetProgress(0)
	g.text:SetText("")
	g.fill = g.bar:CreateTexture(nil, "ARTWORK", nil, 2)
	g.fill:SetTexture(MEDIA .. "XPFill")
	g.fill:SetDesaturated(true)
	g.fill:SetHeight(14)
	g.mid = g.over:CreateTexture(nil, "OVERLAY", nil, 3)
	CuratorOctoFull.ColorTexture(g.mid, 1, 0.86, 0.45, 0.9)
	CuratorOctoFull.SetSize(g.mid, 2, 20)
	g.mid:SetPoint("CENTER", g, "CENTER")
	g.star = g.over:CreateTexture(nil, "OVERLAY", nil, 4)
	g.star:SetTexture(MEDIA .. "Twinkle")
	g.star:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(g.star, 34, 34)
	-- (its ends named on each side of it, clear of the words under it)
	g.left = S.Text(ed, "GameFontDisableSmall", "RIGHT")
	g.left:SetPoint("RIGHT", g, "LEFT", -22, 0)
	g.left:SetText(L["You give more"])
	g.right = S.Text(ed, "GameFontDisableSmall", "LEFT")
	g.right:SetPoint("LEFT", g, "RIGHT", 22, 0)
	g.right:SetText(L["You receive more"])
	g.label = S.Text(ed, "GameFontNormal")
	g.label:SetPoint("TOP", g, "BOTTOM", 0, -5)
	g.why = Hud.InfoButton(ed, 20)
	g.why:SetPoint("LEFT", g.label, "RIGHT", 6, 0)
	g.why.tip = function(self)
		A:BalanceTooltip(self)
	end
	ed.gauge = g

	-- what is wrong, what to know
	ed.note = S.Text(ed, "GameFontHighlightSmall")
	ed.note:SetPoint("TOP", g, "BOTTOM", 0, -30)
	ed.note:SetWidth(W - 60)
	CuratorOctoFull.SetWordWrap(ed.note, true)
	-- (1.5.0: five lines, the days of the quarantine under the wait of the save)
	CuratorOctoFull.SetMaxLines(ed.note, 5)

	-- the buttons of the moment
	ed.main = Hud.ClaimButton(ed, 230, 34, "")
	ed.main:SetPoint("BOTTOM", ed, "BOTTOM", 0, 6)
	CuratorOctoFull.SetScript(ed.main, "OnClick", function()
		A:TradeMain()
	end)
	ed.alt1 = S.Button(ed, "", 160, 24)
	CuratorOctoFull.SetScript(ed.alt1, "OnClick", function(self)
		A:TradeAlt(self.action)
	end)
	ed.alt2 = S.Button(ed, "", 160, 24)
	CuratorOctoFull.SetScript(ed.alt2, "OnClick", function(self)
		A:TradeAlt(self.action)
	end)
	-- the stamp of a trade made
	ed.stamp = ed:CreateTexture(nil, "OVERLAY", nil, 6)
	ed.stamp:SetTexture(MEDIA .. "Check")
	ed.stamp:SetPoint("CENTER", ed.swap, "CENTER")
	ed.stamp:Hide()

	self:BuildTradePicker(ed)
end

-- What the trade on the screen shows: the draft being written, else the trade kept.
function A:TradeShown()
	local e = self.ed
	if not e then
		return nil
	end
	local rec = e.id and T:Get(e.id)
	if e.draft then
		return e.draft, rec
	end
	return rec, rec
end

-- Opens a trade kept.
function A:ShowTrade(id)
	self:Build()
	local rec = T:Get(id)
	if not rec then
		return
	end
	self.ed, self.who = { id = id }, nil
	self.socSec, self.tradeBack = "trades", nil
	if not (self.frame:IsShown() and self.mode == "guild" and not self.member) then
		self:Open("guild")
	else
		self:Refresh()
	end
end

-- A new trade with a player (what I give, what I ask for, when known). (1.14.2) back: the section of the social page the
-- trade closes back to (the guild: a trade proposed from it), else the trades.
function A:StartTrade(name, give, take, back)
	self:Build()
	name = T.Norm(name)
	if not name or G:IsMe(name) then
		return
	end
	-- (1.12.1) a character banned from Curator: no trade (Bans.lua)
	if ns.Bans and ns.Bans:Sender(name) then
		ns.Bans:Tell(name)
		ns.Play(ns.SND.close)
		return
	end
	self.ed, self.who = { draft = T:Draft(name, give, take) }, nil
	self.socSec = "trades"
	self.tradeBack = back
	self.tradeAsked = GetTime()
	-- (their profile tells whether their Curator trades)
	if not G:Profile(name) then
		G:Ask(name, false)
	end
	if not (self.frame:IsShown() and self.mode == "guild" and not self.member) then
		self:Open("guild")
	else
		self:Refresh()
	end
	-- (the answer to the question: the page says it)
	ns.Delay(6, function()
		if A.ed and A.frame:IsShown() and A.mode == "guild" then
			A:Refresh()
		end
	end, self)
end

function A:CloseTrade()
	local e = self.ed
	-- (a trade being changed: back to the trade as it is; else back to the list)
	if e and e.draft and e.id and T:Get(e.id) then
		e.draft = nil
	else
		self.ed = nil
		-- (1.14.2: a trade proposed from the guild: back to it)
		if self.tradeBack then
			self.socSec, self.tradeBack = Section(self.tradeBack), nil
		end
	end
	self:Refresh()
end

-- The partner of the trade on the screen: their title, their level, whether they are there.
function A:PaintTradeHead(t)
	local ed = self.frame.soc.ed
	local name = t.with
	ed.title:SetText(string.format(L["Trade with %s"], Short(name)))
	ed.dot:ClearAllPoints()
	ed.dot:SetPoint("LEFT", ed.title, "LEFT", ns.TextWidth(ed.title) + 8, 0)
	ed.dot:SetOnline(T:Online(name))
	local i = G:Profile(name)
	local parts = {}
	if i then
		local title = ns.Achievements:TitleOf(i)
		parts[CuratorOctoFull.Length(parts) + 1] = title
		if i.xp then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Level %d"], ns.Level.Of(i.xp))
		end
		if i.trades then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Trades: %d"], i.trades)
		end
	end
	local online = T:Online(name)
	if online == true then
		parts[CuratorOctoFull.Length(parts) + 1] = Colour(L["online"], GREEN)
	elseif online == false then
		parts[CuratorOctoFull.Length(parts) + 1] = Colour(L["offline"], DIM)
	end
	ed.info:SetText(table.concat(parts, "  ·  "))
end

-- The places of a side: its cards and boosters, how many, what is missing.
function A:PaintTradeSide(p, items, editing, mine, lacks)
	local missing = {}
	for _, m in ipairs(lacks or {}) do
		missing[m.item] = m.n
	end
	for i, s in ipairs(p.slots) do
		local it = items[i]
		SLOTS[s], s.editing, s.mine = it, editing, mine
		CuratorOctoFull.SetShown(s, it ~= nil)
		if it then
			if it.b then
				s.card:Hide()
				s.card.sig = nil
				s.pack:Show()
				s.pack:SetSeries(ns.SeriesByKey(it.b))
			else
				s.pack:Hide()
				local card = ns.Cards[it.k]
				-- (1.14.0: a corrupted card, the corruption of its copies in the trade, the highest)
				PlaceCard(s.card, card, true, it.f, nil, it.f == "corrupt" and self:TradeCorruption(it, mine) or nil,
					it.f == "holo" and self:TradePattern(it, mine) or nil)
			end
			s.count:SetText(it.n > 1 and ("×" .. it.n) or "")
			CuratorOctoFull.SetShown(s.warn, missing[it] ~= nil)
			if s.grade then
				local g = it.k and self:TradeBestGrade(it, mine) or nil
				if g then
					s.grade:SetGrade(g)
				else
					s.grade:Hide()
				end
			end
		else
			s.card.sig = nil
			if s.grade then
				s.grade:Hide()
			end
		end
	end
	CuratorOctoFull.SetShown(p.add, editing and CuratorOctoFull.Length(items) < T.MAX_ITEMS)
	local v = T:Value(items)
	p.value:SetText(CuratorOctoFull.Length(items) > 0 and string.format(L["Value: %s"], ns.Num(math.floor(v + 0.5))) or "")
	if CuratorOctoFull.Length(items) == 0 then
		p.empty:SetText(editing and (mine and L["Nothing yet: add cards or boosters you give."] or L["Nothing yet: add what you ask for."])
			or L["Nothing"])
	else
		p.empty:SetText("")
	end
end

-- The gauge: where the trade leans, its word.
function A:PaintBalance(give, take, partner)
	local g = self.frame.soc.ed.gauge
	local p, word = T:Balance(give, take)
	local half = GAUGE_W / 2
	local x = p * half
	g.fill:ClearAllPoints()
	if math.abs(x) >= 1 then
		g.fill:Show()
		if x < 0 then
			g.fill:SetPoint("RIGHT", g, "CENTER", 0, 0)
		else
			g.fill:SetPoint("LEFT", g, "CENTER", 0, 0)
		end
		g.fill:SetWidth(math.abs(x))
	else
		g.fill:Hide()
	end
	local c = (word == "empty" and DIM) or (word == "even" and GOLDEN) or ((word == "more" or word == "gift") and { 1, 0.55, 0.3 }) or { 0.4, 0.9, 0.55 }
	g.fill:SetVertexColor(c[1], c[2], c[3])
	g.star:ClearAllPoints()
	g.star:SetPoint("CENTER", g, "CENTER", x, 0)
	CuratorOctoFull.SetShown(g.star, word ~= "empty")
	g.star:SetVertexColor(c[1], c[2], c[3])
	local who = Short(partner)
	-- (how many times more one side is worth: a little, or so many times)
	local a, b = T:Value(give), T:Value(take)
	local ratio = (a > 0 and b > 0) and math.max(a, b) / math.min(a, b) or 1
	local times = math.floor(ratio + 0.5)
	local text = (word == "empty" and L["Nothing to trade yet"]) or (word == "gift" and string.format(L["A gift for %s"], who))
		or (word == "gifted" and string.format(L["A gift from %s"], who)) or (word == "even" and L["Even"])
		or (word == "more" and (ratio < 1.5 and L["You give a little more"] or string.format(L["You give %d times more"], times)))
		or (ratio < 1.5 and L["You receive a little more"] or string.format(L["You receive %d times more"], times))
	g.label:SetText(text)
	g.label:SetTextColor(c[1], c[2], c[3])
	g.word = word
end

-- The buttons: the big one, two others; nil hides them.
function A:TradeButtons(main, alt1, alt2)
	local ed = self.frame.soc.ed
	CuratorOctoFull.SetShown(ed.main, main ~= nil)
	if main then
		ed.main:SetLabel(main.label)
		ed.main.action = main.action
		CuratorOctoFull.SetEnabled(ed.main, main.enabled ~= false)
		ed.main:SetPulse(main.pulse and main.enabled ~= false)
		ed.main.tip = main.tip
	end
	local alts = { alt1, alt2 }
	local shown = {}
	for i, b in ipairs({ ed.alt1, ed.alt2 }) do
		local a = alts[i]
		CuratorOctoFull.SetShown(b, a ~= nil)
		if a then
			b:SetLabel(a.label)
			-- (wider for a long label, in some languages)
			b:SetWidth(math.max(160, math.min(230, ns.TextWidth(b.label) + 30)))
			b.action = a.action
			CuratorOctoFull.SetEnabled(b, a.enabled ~= false)
			shown[CuratorOctoFull.Length(shown) + 1] = b
		end
	end
	-- (the others on each side of the big one, or in the middle without it)
	for _, b in ipairs(shown) do
		b:ClearAllPoints()
	end
	if main then
		if shown[1] then
			shown[1]:SetPoint("RIGHT", ed.main, "LEFT", -14, 0)
		end
		if shown[2] then
			shown[2]:SetPoint("LEFT", ed.main, "RIGHT", 14, 0)
		end
	elseif CuratorOctoFull.Length(shown) == 2 then
		shown[1]:SetPoint("BOTTOMRIGHT", ed, "BOTTOM", -7, 11)
		shown[2]:SetPoint("BOTTOMLEFT", ed, "BOTTOM", 7, 11)
	elseif CuratorOctoFull.Length(shown) == 1 then
		shown[1]:SetPoint("BOTTOM", ed, "BOTTOM", 0, 11)
	end
end

-- The lines of what a side lacks.
local function LacksText(lacks)
	local parts = {}
	for _, m in ipairs(lacks) do
		local it = { k = m.item.k, f = m.item.f, b = m.item.b, n = m.n }
		parts[CuratorOctoFull.Length(parts) + 1] = ItemText(it, true)
	end
	return table.concat(parts, ", ")
end

function A:RefreshTradeEditor()
	local f = self.frame
	local ed = f.soc.ed
	local t, rec = self:TradeShown()
	if not t then
		self.ed = nil
		return self:RefreshSocial()
	end
	local e = self.ed
	local editing = e.draft ~= nil
	self:SetTitle(L["Trades"], editing and L["Choose what you give and what you ask for"] or "")
	self:SetAllCounts()
	self:PaintTradeHead(t)
	ed.give.title:SetText(L["You give"])
	ed.take.title:SetText(L["You receive"])
	local lacks = (editing or t.st == "in") and T:Missing(t.give) or {}
	self:PaintTradeSide(ed.give, t.give, editing, true, lacks)
	self:PaintTradeSide(ed.take, t.take, editing, false)
	self:PaintBalance(t.give, t.take, t.with)
	local who = Short(t.with)
	-- where it is
	local stateText, stateCol
	if editing then
		stateText = e.id and string.format(L["You change the offer: it goes back to %s."], who) or L["A new trade"]
		stateCol = GOLDEN
	else
		stateText, stateCol = self:TradeState(t)
	end
	ed.state:SetText(stateText)
	ed.state:SetTextColor(stateCol[1], stateCol[2], stateCol[3])
	local done = not editing and t.st == "done"
	local closed = not editing and t.st == "no"
	ed.swap:SetTexture(MEDIA .. (done and "Check" or "Swap"))
	ed.swap:SetDesaturated(closed)
	ed.swap:SetAlpha(closed and 0.45 or 1)
	ed.swapGlow:SetVertexColor(done and 0.55 or 1, done and 1 or 0.8, done and 0.5 or 0.4)
	ed.swapGlow:SetAlpha(closed and 0 or 0.25)
	-- what is wrong, what to know
	local notes = {}
	local can, whyNot, passWhy = T:CanTrade()
	if not can then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour((whyNot == "beta" and L["Beta over"]) or (whyNot == "edited" and L["Your save was edited outside the game: no trade."])
			or (whyNot == "pass" and ns.Pass and ns.Pass:Text(passWhy))
			or (whyNot == "guard" and L["Curator gives nothing until /reload: another addon changed its cards."])
			or L["Your collection is a test collection: no trade."], RED)
	end
	if CuratorOctoFull.Length(lacks) > 0 then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["You lack: %s"], LacksText(lacks)), RED)
	end
	if editing and ns.Bans and ns.Bans:Sender(t.with) then
		-- (1.12.1: a character banned from Curator, Bans.lua)
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["%s is banned from Curator: no trade nor duel with them."], who), RED)
	elseif editing then
		local reach = T:CanReach(t.with)
		if reach == false then
			notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["%s has an older Curator: it does not trade yet (0.22 and later)."], who), RED)
		elseif reach == nil and self.tradeAsked and GetTime() - self.tradeAsked > 5 then
			notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["No answer from %s: offline, or without Curator? The offer will wait for them."], who), DIM)
		end
		if not T:Fits(t.give, t.take) then
			-- (1.13.0: eight lines a side, else what goes with the copies that have something to tell; 1.14.0: the
			-- corrupted ones too, the titanforged ones and their patterns)
			local lines = CuratorOctoFull.Length(t.give) <= T.MAX_ITEMS and CuratorOctoFull.Length(t.take) <= T.MAX_ITEMS
			notes[CuratorOctoFull.Length(notes) + 1] = Colour(lines and L["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."]
				or L["Too much for one trade: eight lines a side at most."], RED)
		end
	elseif t.st == "in" and not T:AnswerFits(t, e.picks) then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(L["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."], RED)
	elseif t.st == "done" and T.Unconfirmed(t) then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["What came from %s waits until their game has saved the trade (a reload or a new login): it cannot go into a contract or another trade yet, and its boosters wait to be opened."], who), { 1, 0.8, 0.45 })
	end
	-- (1.5.0) the cards received wait the days of the quarantine
	local cards = false
	for _, it in ipairs(t.take or {}) do
		if it.k then
			cards = true
		end
	end
	if cards and (editing or t.st == "in") then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["The cards you receive are yours at once, but wait %d days before they count for your achievements and can go into a contract or another trade."], T.QUARANTINE_DAYS), DIM)
	elseif cards and T.Quarantined(t) then
		local left = (t.td or 0) + T.QUARANTINE_DAYS * 86400 - CuratorOctoFull.ServerTime()
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(string.format(L["The cards from %s wait %s more before they count for your achievements and can go into a contract or another trade."], who, ns.Duration(math.max(60, left))), { 1, 0.8, 0.45 })
	end
	-- (1.13.0: the copies I give, mine to choose)
	local mineCards = false
	for _, it in ipairs(t.give or {}) do
		if it.k then
			mineCards = true
		end
	end
	if mineCards and (editing or t.st == "in") then
		notes[CuratorOctoFull.Length(notes) + 1] = Colour(L["The least precious copies of your cards go: right-click a card you give to choose them."], DIM)
	end
	ed.note:SetText(table.concat(notes, "\n"))
	-- the buttons
	local problem = editing and T:Problem(t)
	if editing then
		self:TradeButtons({ label = e.id and L["Send the new offer"] or L["Propose the trade"], action = "propose", enabled = problem == nil },
			{ label = L["Cancel"], action = "cancelEdit" })
	elseif t.st == "in" then
		self:TradeButtons({ label = L["Accept"], action = "accept", enabled = CuratorOctoFull.Length(lacks) == 0 and can and T:AnswerFits(t, e.picks), pulse = true },
			{ label = L["Change"], action = "edit", enabled = can }, { label = L["Refuse"], action = "decline" })
	elseif t.st == "out" then
		self:TradeButtons(nil, { label = L["Change"], action = "edit", enabled = can }, { label = L["Withdraw"], action = "withdraw" })
	elseif t.st == "acc" then
		self:TradeButtons(nil, { label = L["Back"], action = "back" })
	elseif t.st == "done" then
		local alt2 = (T.Unconfirmed(t) and not t.dur) and { label = L["Save on my side"], action = "reload" } or nil
		self:TradeButtons(nil, { label = L["Another trade"], action = "again" }, alt2)
	else
		self:TradeButtons(nil, { label = L["Propose again"], action = "again" }, { label = L["Back"], action = "back" })
	end
	ed.main.tip = nil
	CuratorOctoFull.SetScript(ed.alt2, "OnEnter", function(self)
		if self.action == "reload" then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Save on my side"], 1, 1, 1)
			GameTooltip:AddLine(string.format(L["Reloads your interface: your game saves the trade, and what %s received from you is free on their side at once."], who), 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
			-- (1.13.0, after its third test: its click through a macro of the game, which alone still reloads the interface)
			if ns.Save and ns.Save.Cover then
				ns.Save:Cover(self, ns.Save.TRADE)
			end
		end
	end)
	CuratorOctoFull.SetScript(ed.alt2, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- the chooser over the sides
	if e.pick then
		self:RefreshTradePicker()
	else
		ed.pick:Hide()
	end
end

-- The big button.
function A:TradeMain()
	local ed = self.frame.soc.ed
	local action = ed.main.action
	local e = self.ed
	local t, rec = self:TradeShown()
	if action == "propose" then
		local r, why = T:Propose(t)
		if r then
			ns.Play(ns.SND.ink)
			self.ed = { id = r.id }
		else
			ns.Play(ns.SND.close)
		end
		return self:Refresh()
	elseif action == "accept" then
		-- (1.13.0: the copies I chose for each line I give, else the least precious)
		if T:Accept(rec, e and e.picks or nil) then
			ns.Play(ns.SND.seal)
		else
			ns.Play(ns.SND.close)
		end
		return self:Refresh()
	end
end

-- The other buttons.
function A:TradeAlt(action)
	local t, rec = self:TradeShown()
	local e = self.ed
	if action == "cancelEdit" or action == "back" then
		ns.Play(ns.SND.page)
		return self:CloseTrade()
	elseif action == "edit" and rec then
		ns.Play(ns.SND.click)
		e.draft = { id = rec.id, with = rec.with, give = T.Copy(rec.give), take = T.Copy(rec.take), st = "draft", rev = rec.rev }
		return self:Refresh()
	elseif action == "decline" and rec then
		T:Decline(rec)
		ns.Play(ns.SND.close)
		return self:Refresh()
	elseif action == "withdraw" and rec then
		T:Withdraw(rec)
		ns.Play(ns.SND.close)
		return self:Refresh()
	elseif action == "again" and t then
		ns.Play(ns.SND.click)
		local again = t.st ~= "done"
		self.ed = { draft = T:Draft(t.with, again and T.Copy(t.give) or nil, again and T.Copy(t.take) or nil) }
		-- (1.13.0: the copies chosen then, chosen again now: those of before may be gone)
		for _, side in ipairs({ self.ed.draft.give, self.ed.draft.take }) do
			for _, it in ipairs(side) do
				it.ids, it.c = nil, nil
			end
		end
		return self:Refresh()
	elseif action == "reload" then
		-- (1.12.1: as the scroll of the album, the save then told; not in a fight, UI/Save.lua. 1.13.0, after its third test:
		-- the button clicked itself, not the macro laid over it, a fight or no macro of the game: /reload to type)
		if ns.Save then
			ns.Save:Now("trade")
		end
	end
end

-- A place of a side: its tooltip; a click takes one out (with shift, all of them) while the trade is
-- written.
function A:TradeSlotTooltip(s)
	local it = SLOTS[s]
	if not it then
		return
	end
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if it.b then
		local sr = ns.SeriesByKey(it.b)
		GameTooltip:AddLine(it.n == 1 and L["1 booster"] or string.format(L["%d boosters"], it.n), 1, 0.86, 0.5)
		if sr then
			GameTooltip:AddLine(C:SeriesName(sr), 1, 1, 1)
			GameTooltip:AddLine(A:SubLine(sr), 0.7, 0.7, 0.7)
			if s.mine then
				GameTooltip:AddLine(string.format(L["Boosters: %d"], ns.Packs(sr)), 0.8, 0.8, 0.8)
			end
		end
	else
		local card = ns.Cards[it.k]
		ns.Booster:CardTooltip(card, it.f, C:Entry(card))
		local f = C:FinishName(card, it.f)
		GameTooltip:AddLine((f or L["Normal copy"]) .. (it.n > 1 and ("  ×" .. it.n) or ""), 0.85, 0.85, 1)
		local e = C:Entry(card)
		if e and e.n > 0 then
			GameTooltip:AddLine(string.format(L["In your album: %d"], e.n), 0.4, 1, 0.4)
		else
			GameTooltip:AddLine(L["Not in your album yet"], 0.62, 0.62, 0.62)
		end
	end
	GameTooltip:AddLine(string.format(L["Value: %s"], ns.Num(math.floor(T:ItemValue(it) + 0.5))), 0.7, 0.7, 0.74)
	-- (1.13.0) the copies that go: those chosen, else the least precious; what comes with those I receive
	if it.k then
		self:TradeCopiesTooltip(s, it)
	end
	if s.warn:IsShown() then
		GameTooltip:AddLine(L["You do not have enough of it."], RED[1], RED[2], RED[3])
	end
	if s.editing then
		GameTooltip:AddLine(L["Click: one less  ·  Shift-click: take it out"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
	end
	if it.k and s.mine and self:TradePickable() then
		GameTooltip:AddLine(L["Right-click: choose the copies you give"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
	end
	GameTooltip:Show()
end

-- (1.13.0) The copies of my side can be chosen: an offer I write, or one I answer.
function A:TradePickable()
	local e = self.ed
	local t = self:TradeShown()
	return e ~= nil and t ~= nil and (e.draft ~= nil or t.st == "in")
end

-- The copies of a line I give, as they would go now (those chosen, the least precious after them), and where the
-- choice is kept: the offer written (it.ids), else the answer (e.picks[i]).
function A:TradeLeaving(it)
	local e = self.ed
	local t = self:TradeShown()
	local ids = it.ids
	if e and t and not e.draft and t.st == "in" then
		for i, x in ipairs(t.give or {}) do
			if x == it then
				ids = e.picks and e.picks[i] or nil
			end
		end
	end
	return T.Leaving({ k = it.k, f = it.f, ids = ids }, it.n or 1), ids
end

-- The finest grade (a number) of the copies of a line: mine that go, or those that come with theirs.
function A:TradeBestGrade(it, mine)
	local CP = ns.Copies
	local best
	if mine and type(it.cp) == "table" then
		-- (gone already, with the trade: the copies that went)
		for _, r in ipairs(it.cp) do
			local g = CP.Grade(r)
			if g and r.sl ~= false and (not best or g > best) then
				best = g
			end
		end
	elseif mine and ns.db and C:Owned(ns.Cards[it.k]) and self.ed then
		for _, id in ipairs((self:TradeLeaving(it))) do
			local g = CP.Grade(CP:Get(it.k, id))
			if g and (not best or g > best) then
				best = g
			end
		end
	elseif type(it.c) == "table" then
		for _, p in ipairs(it.c) do
			local r = CP.Unpack(p)
			local g = r and CP.Grade(r)
			if g and (not best or g > best) then
				best = g
			end
		end
	end
	return best and best / 100 or nil
end

-- (1.14.0, his idea) The pattern of the first titanforged copy of a line (Patterns.lua): mine that go (gone already,
-- else as they would go now), theirs as they told it; nil: none known (theirs asked for, their copies chosen when they
-- answer). (1 November: and that copy, its certificate of the mages with it, Mages.lua: a link of the chat carries it)
function A:TradePattern(it, mine)
	local CP = ns.Copies
	if not CP then
		return nil
	end
	if mine and type(it.cp) == "table" then
		for _, r in ipairs(it.cp) do
			if CP.Pattern(r) then
				return CP.Pattern(r), r
			end
		end
	elseif mine and ns.db and C:Owned(ns.Cards[it.k]) and self.ed then
		for _, id in ipairs((self:TradeLeaving(it))) do
			local r = CP:Get(it.k, id)
			local pt = CP.Pattern(r)
			if pt then
				return pt, r
			end
		end
	elseif type(it.c) == "table" then
		for _, p in ipairs(it.c) do
			local r = CP.Unpack(p)
			if r and r.pt then
				return r.pt, r
			end
		end
	end
	return nil
end

-- (1.14.0) The highest corruption of the copies of a corrupted line: mine that go (gone already, else as they would go
-- now), theirs as they told it; false: not known yet (theirs asked for, their copies chosen when they answer).
function A:TradeCorruption(it, mine)
	local CP = ns.Copies
	local best
	local function See(r)
		local k = r and tonumber(r.cor)
		if k and (not best or k > best) then
			best = k
		end
	end
	if not CP then
		return false
	end
	if mine and type(it.cp) == "table" then
		for _, r in ipairs(it.cp) do
			if r.f == "c" then
				See(r)
			end
		end
	elseif mine and ns.db and C:Owned(ns.Cards[it.k]) and self.ed then
		for _, id in ipairs((self:TradeLeaving(it))) do
			local r = CP:Get(it.k, id)
			if r and r.f == "c" then
				See(r)
			end
		end
	elseif type(it.c) == "table" then
		for _, p in ipairs(it.c) do
			See(CP.Unpack(p))
		end
	end
	return best or false
end

-- The copies in the tooltip of a line: mine that go (chosen or the least precious), theirs that come with something
-- to tell (their grade, their restorations; 1.14.0: their corruption, their seal).
function A:TradeCopiesTooltip(s, it)
	local CP, CU = ns.Copies, ns.CopiesUI
	local card = ns.Cards[it.k]
	if not (card and CP and CU) then
		return
	end
	if s.mine and self:TradePickable() then
		local ids, chosen = self:TradeLeaving(it)
		local names = CU:Names(card, ids)
		if names ~= "" then
			GameTooltip:AddLine(string.format(((chosen and CuratorOctoFull.Length(chosen) > 0) and L["The copies you chose: %s"] or L["The least precious go: %s"]), names), 0.8, 0.86, 1, true)
		end
		for _, id in ipairs(ids) do
			local r = CP:Get(it.k, id)
			-- (1.14.0: a corrupted copy, its name says its corruption; a reliquary, its corruption after its rank)
			if r and CP.Telling(r) and (r.f ~= "c" or r.ws) then
				local g = CP.Grade(r)
				local more = ((g and r.sl ~= false) and ("  " .. ns.Expertise.Label(g / 100))) or (r.f == "c" and ("  ·  " .. string.format(("%d %%"), tonumber(r.cor) or 0))) or ""
				-- (1.14.0: a titanforged copy, its pattern; 1 November: told once certified by a master of the mages)
				local tag = ns.Mages and ns.Mages.Tag(r, false, true)
				if tag then
					more = more .. "  ·  " .. tag
				end
				GameTooltip:AddLine("  " .. CU:Label(card, r) .. more, 0.86, 0.86, 0.9)
			end
		end
	elseif type(it.c) == "table" and CuratorOctoFull.Length(it.c) > 0 then
		local SL = ns.Masters
		for _, p in ipairs(it.c) do
			local r = CP.Unpack(p)
			if r and r.cor then
				-- (1.14.0: a corrupted copy, its corruption; a reliquary, its seal)
				local rank = r.seal and SL and SL.Valid(r.seal.g)
				local text = rank and string.format(L["With it: a reliquary sealed %s, corrupted at %d %%"], SL.Label(rank), r.cor)
					or string.format(L["With it: a copy corrupted at %d %%"], r.cor)
				GameTooltip:AddLine(text, 0.82, 0.6, 1, true)
			elseif r then
				local g = CP.Grade(r)
				local rs = type(r.r) == "table" and CuratorOctoFull.Length(r.r) or 0
				local text
				if g and r.sl ~= false then
					text = string.format(L["With it: a copy appraised %s"], ns.Expertise.Label(g / 100))
				elseif g or r.hg or rs > 0 then
					text = L["With it: a copy restored, its case opened"]
				end
				if text and rs > 0 and g and r.sl ~= false then
					text = text .. "  ·  " .. (rs == 1 and L["Restored once"] or string.format(L["Restored %d times"], rs))
				end
				-- (1.14.0: a titanforged copy, its pattern; 1 November: told once certified by a master of the mages,
				-- its certificate with it, Mages.lua)
				local tag = r.pt and ns.Mages and ns.Mages.TagOf(r.pt, r.tc, false, true)
				if tag then
					text = text and (text .. "  ·  " .. tag) or string.format(L["With it: a certified copy, %s"], tag)
				end
				if text then
					GameTooltip:AddLine(text, 0.86, 0.86, 1, true)
				end
			end
		end
	end
end

function A:TradeSlotClick(s, button)
	local it = SLOTS[s]
	local e = self.ed
	-- (1.13.0) a card I give, right-clicked: the chooser of its copies (an offer I write, or one I answer)
	if button == "RightButton" and it and it.k and s.mine and self:TradePickable() then
		local t = self:TradeShown()
		local card = ns.Cards[it.k]
		local leaving, chosen = self:TradeLeaving(it)
		GameTooltip:Hide()
		ns.CopiesUI:OpenPicker({ card = card, finish = it.f, n = it.n or 1, ids = (chosen and CuratorOctoFull.Length(chosen) > 0) and chosen or leaving, owner = s,
			done = function(ids)
				if e.draft then
					it.ids = ids
				else
					e.picks = e.picks or {}
					for i, x in ipairs(t.give or {}) do
						if x == it then
							e.picks[i] = ids
						end
					end
				end
				A:Refresh()
			end })
		return
	end
	if not (it and s.editing and e and e.draft) then
		if it and it.k and ns.Links:Modified() then
			-- (1 November: its certificate of the mages with its pattern, when certified)
			local pt, rec
			if it.f == "holo" then
				pt, rec = self:TradePattern(it, s.mine)
			end
			local MG = ns.Mages
			ns.Links:Insert(ns.Cards[it.k], it.f, pt, MG and rec and MG.Pack(MG.Of(rec)) or nil, rec)
		end
		return
	end
	local side = s.mine and e.draft.give or e.draft.take
	for i, x in ipairs(side) do
		if x == it then
			if IsShiftKeyDown() or x.n <= 1 then
				CuratorOctoFull.Remove(side, i)
			else
				x.n = x.n - 1
				-- (1.13.0: the copies chosen, as many as go)
				if type(x.ids) == "table" then
					while CuratorOctoFull.Length(x.ids) > x.n do
						CuratorOctoFull.Remove(x.ids)
					end
				end
			end
			break
		end
	end
	ns.Play(ns.SND.page)
	GameTooltip:Hide()
	self:Refresh()
end

-- The cote: how the gauge counts.
function A:BalanceTooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L["The balance of the trade"], 1, 1, 1)
	GameTooltip:AddLine(L["A guide only: every trade is free. A card counts as rare as a booster makes it: a common 1, an uncommon 3, a rare 10, an epic 60, a legendary 300, a mythic 1,500; a thunderforged copy 25 times more, a titanforged one 100 times more; a booster what it holds on average."], 0.85, 0.85, 0.85, true)
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The chooser of a side: my cards and boosters, or theirs (what their album shows)
-------------------------------------------------------------------------------
function A:BuildTradePicker(ed)
	local W = ed:GetParent().W
	local pk = CreateFrame("Frame", nil, ed)
	pk:SetPoint("TOPLEFT", 0, PANEL_Y + 6)
	CuratorOctoFull.SetSize(pk, W, PANEL_H + 112)
	pk.w = W
	pk:SetFrameLevel(ed:GetFrameLevel() + 10)
	pk:EnableMouse(true)
	pk.bg = Hud.Card(pk, 0.75, "BACKGROUND")
	pk.shade = pk:CreateTexture(nil, "BACKGROUND", nil, -1)
	pk.shade:SetPoint("TOPLEFT", 3, -3)
	pk.shade:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(pk.shade, 0.02, 0.02, 0.04, 0.96)
	pk:Hide()
	ed.pick = pk
	pk.title = S.Text(pk, "GameFontNormalLarge", "LEFT")
	pk.title:SetPoint("TOPLEFT", 16, -14)
	pk.sub = S.Text(pk, "GameFontHighlightSmall", "LEFT")
	pk.sub:SetPoint("TOPLEFT", pk.title, "BOTTOMLEFT", 0, -4)
	pk.sub:SetWidth(W - 260)
	CuratorOctoFull.SetWordWrap(pk.sub, false)
	pk.sub:SetTextColor(0.75, 0.75, 0.8)
	-- cards or boosters
	pk.kinds = {}
	for i, kind in ipairs({ "cards", "packs" }) do
		local i, kind = i, kind; local b = NewToggle(pk, 120, 24)
		b:SetPoint("TOPRIGHT", -16 - (2 - i) * 128, -12)
		b.kind = kind
		Hud.SetIcon(b.icon, kind == "cards" and { "Back", { 0.07, 0.65, 0.21, 0.79 } } or { "PackZoneChoice" })
		b:SetLabel(kind == "cards" and L["Cards"] or L["Boosters"])
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetGiftPickKind(kind)
		end)
		pk.kinds[i] = b
	end
	-- the album, the filter
	pk.album = S.Dropdown(pk, 210)
	pk.album:SetPoint("TOPLEFT", 16, -56)
	pk.album:SetupMenu(function(_, root)
		A:PickAlbumMenu(root)
	end)
	pk.only = S.Check(pk, "")
	pk.only:SetPoint("LEFT", pk.album, "RIGHT", 14, 0)
	CuratorOctoFull.SetScript(pk.only, "OnClick", function(self)
		local p = A.ed and A.ed.pick
		if p then
			p.only = self:GetChecked() and true or false
			p.page = 1
			ns.Play(ns.SND.click)
			A:Refresh()
		end
	end)
	pk.cells = {}
	for i = 1, PICK_COLS * PICK_ROWS do
		pk.cells[i] = NewPick(pk, i)
	end
	pk.empty = S.Text(pk, "GameFontHighlight")
	pk.empty:SetPoint("CENTER", 0, 0)
	pk.empty:SetWidth(W - 120)
	CuratorOctoFull.SetWordWrap(pk.empty, true)
	pk.empty:SetTextColor(0.65, 0.65, 0.7)
	pk.pager = S.Pager(pk)
	pk.pager:SetPoint("BOTTOMRIGHT", -14, 10)
	CuratorOctoFull.SetScript(pk.pager.prev, "OnClick", function()
		A:PickPage(-1)
	end)
	CuratorOctoFull.SetScript(pk.pager.next, "OnClick", function()
		A:PickPage(1)
	end)
	pk.done = Hud.ClaimButton(pk, 170, 30, L["Done"])
	pk.done:SetPoint("BOTTOM", 0, 12)
	pk.side = S.Text(pk, "GameFontHighlightSmall", "LEFT")
	pk.side:SetPoint("BOTTOMLEFT", 18, 20)
	pk.side:SetWidth((W - 170) / 2 - 30)
	CuratorOctoFull.SetWordWrap(pk.side, true)
	CuratorOctoFull.SetMaxLines(pk.side, 2)
	CuratorOctoFull.SetScript(pk.done, "OnClick", function()
		ns.Play(ns.SND.page)
		A:CloseTradePicker()
	end)
	pk:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(pk, "OnMouseWheel", function(_, delta)
		A:PickPage(delta > 0 and -1 or 1)
	end)
end

function A:OpenTradePicker(side)
	local e = self.ed
	if not (e and e.draft) then
		return
	end
	local mine = side == "give"
	local s = (not mine) and (self:Series()) or nil
	e.pick = { side = side, kind = "cards", series = s, only = true, page = 1 }
	if not mine then
		e.pick.series = self:Series()
		self:AskTheirAlbum()
	end
	self:Refresh()
end

function A:CloseTradePicker()
	if self.ed then
		self.ed.pick = nil
	end
	self:Refresh()
end

-- Their album shown in the chooser: asked again (what they sent last time shows meanwhile).
function A:AskTheirAlbum()
	local e = self.ed
	local p = e and e.pick
	if not (p and p.side == "take" and p.series and e.draft) then
		return
	end
	p.asked = GetTime()
	G:RequestAlbum(e.draft.with, p.series)
	ns.Delay(6, function()
		if A.ed and A.ed.pick == p and A.frame:IsShown() then
			A:Refresh()
		end
	end, self)
end

-- (1.14.0: its own name; it took the place of the kinds of the boosters to choose, UI/Boosters.lua, whose buttons
-- then did nothing)
function A:SetGiftPickKind(kind)
	local p = self.ed and self.ed.pick
	if p and p.kind ~= kind then
		p.kind, p.page = kind, 1
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

function A:PickPage(delta)
	local p = self.ed and self.ed.pick
	if not p then
		return
	end
	local pages = self.pickPages or 1
	local to = math.max(1, math.min(pages, (p.page or 1) + delta))
	if to ~= p.page then
		p.page = to
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The albums of the chooser: all of them (mine), or one at a time (theirs: their album is asked for).
function A:PickAlbumMenu(root)
	local p = self.ed and self.ed.pick
	if not p then
		return
	end
	local function choose(s)
		p.series, p.page = s, 1
		if p.side == "take" then
			A:AskTheirAlbum()
		end
		A:Refresh()
	end
	if p.side == "give" or p.kind == "packs" then
		root:CreateRadio(L["All albums"], function()
			return p.series == nil
		end, function()
			choose(nil)
		end)
	end
	if root.SetScrollMode then
		root:SetScrollMode(400)
	end
	for _, s in ipairs(self:Order()) do
		local _, s = _, s; root:CreateRadio(C:SeriesName(s), function(x)
			return p.series == x
		end, function(x)
			choose(x)
		end, s)
	end
end

-- What the chooser holds: { card, finish, n } or { series, n }.
function A:PickEntries()
	local e = self.ed
	local p = e.pick
	local d = e.draft
	local out = {}
	local function inDraft(side, it)
		for _, x in ipairs(side) do
			if T.Same(x, it) then
				return x.n
			end
		end
		return 0
	end
	if p.kind == "packs" then
		for _, s in ipairs(self:Order()) do
			if not p.series or p.series == s then
				if p.side == "give" then
					local n = ns.Packs(s) - inDraft(d.give, { b = s.key })
					if n > 0 then
						out[CuratorOctoFull.Length(out) + 1] = { series = s, n = n }
					end
				else
					out[CuratorOctoFull.Length(out) + 1] = { series = s }
				end
			end
		end
		return out
	end
	local albums = p.series and { p.series } or self:Order()
	if p.side == "give" then
		for _, s in ipairs(albums) do
			for _, card in ipairs(s.list) do
				-- (1.14.0, his word: the corrupted copies too)
				for _, fin in ipairs({ "holo", "shiny", "corrupt", "normal" }) do
					local f = fin ~= "normal" and fin or nil
					local n = T:Spare(card, fin, p.only) - inDraft(d.give, { k = card.key, f = f })
					if n > 0 then
						out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = f, n = n }
					end
				end
			end
		end
		table.sort(out, function(a, b)
			if a.card.rarity ~= b.card.rarity then
				return a.card.rarity > b.card.rarity
			end
			if (a.finish ~= nil) ~= (b.finish ~= nil) then
				return a.finish ~= nil
			end
			if a.card.series ~= b.card.series then
				return (a.card.series.order or 0) < (b.card.series.order or 0)
			end
			return a.card.num < b.card.num
		end)
		return out
	end
	-- theirs: what their album shows (only what I do not have, with the filter)
	local s = p.series
	local entries = s and G:Album(d.with, s)
	if not entries then
		return out, true
	end
	for _, card in ipairs(s.list) do
		local x = entries[card.key]
		if x and x.n > 0 and not (p.only and C:Owned(card)) then
			local shiny, holo = (x.s or 0) > 0, (x.h or 0) > 0
			local normal = x.n - (shiny and 1 or 0) - (holo and 1 or 0)
			if holo then
				out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = "holo", n = nil, theirs = x.n }
			end
			if shiny then
				out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = "shiny", n = nil, theirs = x.n }
			end
			if normal > 0 then
				out[CuratorOctoFull.Length(out) + 1] = { card = card, n = normal, theirs = x.n }
			end
		end
	end
	return out
end

function A:RefreshTradePicker()
	local ed = self.frame.soc.ed
	local pk = ed.pick
	local e = self.ed
	local p = e.pick
	local d = e.draft
	if not (p and d) then
		pk:Hide()
		return
	end
	pk:Show()
	local mine = p.side == "give"
	local who = Short(d.with)
	pk.title:SetText(mine and L["What you give"] or string.format(L["What you ask %s for"], who))
	for _, b in ipairs(pk.kinds) do
		b:SetSelected(b.kind == p.kind)
	end
	pk.album:GenerateMenu()
	CuratorOctoFull.SetShown(pk.only, p.kind == "cards")
	pk.only.Text:SetText(mine and L["Duplicates only"] or L["Only those you are missing"])
	pk.only:SetChecked(p.only and true or false)
	local list, waiting = self:PickEntries()
	local cells = CuratorOctoFull.Length(pk.cells)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / cells))
	self.pickPages = pages
	p.page = math.max(1, math.min(p.page or 1, pages))
	for i, b in ipairs(pk.cells) do
		local x = list[(p.page - 1) * cells + i]
		b.entry = x
		CuratorOctoFull.SetShown(b, x ~= nil)
		if x then
			if x.series then
				b.card:Hide()
				b.card.sig = nil
				b.pack:Show()
				b.pack:SetSeries(x.series)
				b.name:SetText(C:SeriesName(x.series))
				b.name:SetTextColor(1, 0.86, 0.5)
				b.count:SetText(x.n and ("x" .. x.n) or "")
				b.fin:SetText("")
				b.mark:Hide()
			else
				b.pack:Hide()
				-- (the copies to give, or that they have: on the card, as in the album)
				PlaceCard(b.card, x.card, true, x.finish, x.n)
				local rc = ns.RARITY[x.card.rarity].text
				b.name:SetText(C:Name(x.card))
				b.name:SetTextColor(rc[1], rc[2], rc[3])
				b.fin:SetText(C:FinishName(x.card, x.finish) or "")
				b.count:SetText("")
				-- (a card looked for: by them when I give it, by me when I ask for it)
				local sought = mine and CuratorOctoFull.Length(T:SoughtBy(x.card)) > 0 or (not mine and T:Wished(x.card))
				CuratorOctoFull.SetShown(b.mark, sought and true or false)
			end
		else
			b.card.sig = nil
		end
	end
	if waiting then
		local late = p.asked and GetTime() - p.asked > 5
		pk.empty:SetText(late and string.format(L["%s did not answer (offline?)"], who) or string.format(L["Waiting for %s..."], who))
	elseif CuratorOctoFull.Length(list) == 0 then
		pk.empty:SetText(p.kind == "packs" and L["No booster to give."] or (mine and L["No card to spare here."] or L["Nothing to ask for here."]))
	else
		pk.empty:SetText("")
	end
	pk.sub:SetText(p.kind == "packs" and not mine and string.format(L["%s will say whether they have them."], who)
		or (mine and L["Click: one more  ·  Shift-click: all of them"] or L["Click: ask for one"]))
	pk.pager:Set(p.page, pages, string.format(L["Page %d / %d"], p.page, pages))
	local items = mine and d.give or d.take
	pk.side:SetText(Colour(mine and L["You give:"] or L["You receive:"], GOLDEN) .. " " .. SideText(items, 3))
end

function A:PickTooltip(b)
	local x = b.entry
	if not x then
		return
	end
	local p = self.ed and self.ed.pick
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	if x.series then
		GameTooltip:AddLine(C:SeriesName(x.series), 1, 0.86, 0.5)
		GameTooltip:AddLine(A:SubLine(x.series), 0.7, 0.7, 0.7)
		if x.n then
			GameTooltip:AddLine(string.format(L["Boosters: %d"], x.n), 1, 1, 1)
		end
	else
		ns.Booster:CardTooltip(x.card, x.finish, C:Entry(x.card))
		local f = C:FinishName(x.card, x.finish)
		if f then
			GameTooltip:AddLine(f, 0.85, 0.85, 1)
		end
		if p and p.side == "give" then
			GameTooltip:AddLine(string.format(L["To spare: %d"], x.n or 0), 1, 0.62, 0.5)
			local seekers = T:SoughtBy(x.card)
			if CuratorOctoFull.Length(seekers) > 0 then
				GameTooltip:AddLine(string.format(L["Wanted by %s"], table.concat(self:ShortNames(seekers, 6), ", ")), BLUE[1], BLUE[2], BLUE[3], true)
			end
		else
			GameTooltip:AddLine(string.format(L["Their copies: %d"], x.theirs or 0), 0.8, 0.8, 0.8)
			local e = C:Entry(x.card)
			if e and e.n > 0 then
				GameTooltip:AddLine(string.format(L["In your album: %d"], e.n), 0.4, 1, 0.4)
			else
				GameTooltip:AddLine(L["Not in your album yet"], 0.62, 0.62, 0.62)
			end
		end
	end
	GameTooltip:Show()
end

-- A click puts one in (with shift, all of them: mine).
function A:PickClick(b, button)
	local x = b.entry
	local e = self.ed
	if not (x and e and e.draft and e.pick) then
		return
	end
	local p = e.pick
	local side = p.side == "give" and e.draft.give or e.draft.take
	local it = x.series and { b = x.series.key } or { k = x.card.key, f = x.finish }
	local n = 1
	if IsShiftKeyDown() and x.n and p.side == "give" then
		n = x.n
	end
	local found
	for _, o in ipairs(side) do
		if T.Same(o, it) then
			found = o
			break
		end
	end
	if found then
		found.n = math.min(T.MAX_COUNT, found.n + n)
	else
		if CuratorOctoFull.Length(side) >= T.MAX_ITEMS then
			ns.Play(ns.SND.close)
			return
		end
		it.n = n
		side[CuratorOctoFull.Length(side) + 1] = it
	end
	ns.Play(ns.SND.ink)
	self:Refresh()
end

-------------------------------------------------------------------------------
-- The chooser of a player: the guild online, the friends of Battle.net, those traded with, those met
-------------------------------------------------------------------------------
function A:BuildChooser(page)
	local W = page.W
	local wh = CreateFrame("Frame", nil, page)
	wh:SetAllPoints()
	wh:SetFrameLevel(page:GetFrameLevel() + 4)
	wh:Hide()
	page.who = wh
	wh.back = S.Button(wh, L["Back"], 96, 22)
	wh.back:SetPoint("TOPLEFT", 0, 0)
	CuratorOctoFull.SetScript(wh.back, "OnClick", function()
		ns.Play(ns.SND.page)
		A.who = nil
		A:Refresh()
	end)
	wh.title = S.Text(wh, "GameFontNormalLarge", "LEFT")
	wh.title:SetPoint("TOPLEFT", 110, -1)
	wh.title:SetText(L["A new trade: with whom?"])
	wh.rows = {}
	for i = 1, WHO_ROWS do
		local i = i; local r = S.ListButton(wh)
		CuratorOctoFull.SetSize(r, W, WHO_H)
		r:SetPoint("TOPLEFT", 0, -40 - (i - 1) * (WHO_H + 4))
		r.dot = Dot(r, 10)
		r.dot:SetPoint("LEFT", 14, 0)
		r.name = S.Text(r, "GameFontNormal", "LEFT")
		r.name:SetPoint("LEFT", 32, 0)
		r.name:SetWidth(220)
		CuratorOctoFull.SetWordWrap(r.name, false)
		r.from = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.from:SetPoint("LEFT", 260, 0)
		r.from:SetWidth(W - 260 - 150)
		CuratorOctoFull.SetWordWrap(r.from, false)
		r.from:SetTextColor(0.75, 0.75, 0.8)
		r.go = S.Text(r, "GameFontNormalSmall", "RIGHT")
		r.go:SetPoint("RIGHT", -14, 0)
		r.go:SetText(L["Propose a trade"])
		if ns.TextWidth(r.go) > 136 then
			S.Fit(r.go, L["Propose a trade"], 136, 10, 7.5)
		end
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.player then
				ns.Play(ns.SND.click)
				A:StartTrade(self.player)
			end
		end)
		wh.rows[i] = r
	end
	wh.empty = S.Text(wh, "GameFontHighlight")
	wh.empty:SetPoint("TOP", 0, -160)
	wh.empty:SetWidth(W - 120)
	CuratorOctoFull.SetWordWrap(wh.empty, true)
	wh.empty:SetTextColor(0.65, 0.65, 0.7)
	wh.hint = S.Text(wh, "GameFontHighlightSmall", "LEFT")
	wh.hint:SetPoint("BOTTOMLEFT", 2, 50)
	wh.hint:SetWidth(W - 220)
	CuratorOctoFull.SetWordWrap(wh.hint, true)
	wh.hint:SetTextColor(0.7, 0.7, 0.74)
	wh.hint:SetText(L["Anyone else: right click on the player (their portrait, their name in the chat) and Trade with Curator, or type /curator trade Name."])
end

function A:OpenChooser()
	self.who, self.ed, self.tradeBack = { page = 1 }, nil, nil
	self:Refresh()
end

-- The players to trade with: those of the guild who shared (online first), the friends of Battle.net
-- playing, those traded with, those met lately.
function A:Candidates()
	local out, seen = {}, {}
	local function add(name, from, online)
		name = T.Norm(name)
		if name and not seen[name] and not G:IsMe(name) then
			seen[name] = true
			out[CuratorOctoFull.Length(out) + 1] = { name = name, from = from, online = online }
		end
	end
	for name in pairs(ns.db.guild) do
		add(name, L["Guild"], T:Online(name))
	end
	for _, name in ipairs(T:BNFriends()) do
		add(name, L["Battle.net friend"], true)
	end
	for _, rec in pairs(ns.db.trades) do
		add(rec.with, L["Traded with"], T:Online(rec.with))
	end
	for name in pairs(ns.db.met) do
		add(name, L["Met"], T:Online(name))
	end
	table.sort(out, function(a, b)
		local oa, ob = a.online and 2 or (a.online == nil and 1 or 0), b.online and 2 or (b.online == nil and 1 or 0)
		if oa ~= ob then
			return oa > ob
		end
		return a.name < b.name
	end)
	return out
end

function A:RefreshChooser()
	local wh = self.frame.soc.who
	local list = self:Candidates()
	self:SetTitle(L["Trades"], L["Choose a player"])
	self:SetAllCounts()
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / WHO_ROWS))
	local w = self.who
	w.page = math.max(1, math.min(w.page or 1, pages))
	for i, r in ipairs(wh.rows) do
		local c = list[(w.page - 1) * WHO_ROWS + i]
		r.player = c and c.name
		CuratorOctoFull.SetShown(r, c ~= nil)
		if c then
			r.name:SetText(Short(c.name))
			r.dot:SetOnline(c.online)
			local i2 = G:Profile(c.name)
			local from = c.from
			local old = i2 ~= nil and i2.uid == nil
			if old then
				from = from .. "  ·  " .. Colour(L["older Curator"], DIM)
			elseif i2 then
				local title = ns.Achievements:Title(i2.points, i2.female)
				from = from .. "  ·  " .. title .. (i2.xp and ("  ·  " .. string.format(L["Level %d"], ns.Level.Of(i2.xp))) or "")
			end
			r.from:SetText(from)
			CuratorOctoFull.SetEnabled(r, not old)
			r.name:SetTextColor(old and 0.5 or 1, old and 0.5 or 0.82, old and 0.5 or 0)
			CuratorOctoFull.SetShown(r.go, not old)
		end
	end
	wh.empty:SetText(CuratorOctoFull.Length(list) == 0 and L["Nobody yet: your guild, your Battle.net friends and the players you meet with Curator show here."] or "")
	self:ShowPager(true)
	self:SetPager(w.page, pages)
end

-------------------------------------------------------------------------------
-- The pages, the events
-------------------------------------------------------------------------------
function A:SocialPage(delta)
	if self.ed then
		if self.ed.pick then
			return self:PickPage(delta)
		end
		return
	end
	if self.who then
		local n = CuratorOctoFull.Length(self:Candidates())
		local pages = math.max(1, math.ceil(n / WHO_ROWS))
		local p = math.max(1, math.min(pages, (self.who.page or 1) + delta))
		if p ~= self.who.page then
			self.who.page = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
		return
	end
	local sec = Section(self.socSec)
	if sec == "trades" then
		local open, past = T:List()
		local n = (self.tradeTab == "past") and CuratorOctoFull.Length(past) or CuratorOctoFull.Length(open)
		local pages = math.max(1, math.ceil(n / ROWS))
		local p = math.max(1, math.min(pages, (self.tradePage or 1) + delta))
		if p ~= self.tradePage then
			self.tradePage = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
	elseif sec == "market" then
		local n = CuratorOctoFull.Length(self:MarketLines(self.marketTab or "now"))
		local pages = math.max(1, math.ceil(n / ROWS))
		local p = math.max(1, math.min(pages, (self.marketPage or 1) + delta))
		if p ~= self.marketPage then
			self.marketPage = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
	elseif sec == "guild" then
		-- (1.14.2) the pages of the tab of the guild shown
		local list, per = self:GuildList(self.guildTab or "finds")
		local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / per))
		local p = math.max(1, math.min(pages, (self.guildPage or 1) + delta))
		if p ~= self.guildPage then
			self.guildPage = p
			ns.Play(ns.SND.page)
			self:Refresh()
		end
	end
end

-- The social page from elsewhere: a section (the trades with an offer to answer first).
function A:ShowSocial(section)
	self:Build()
	self.ed, self.who, self.tradeBack = nil, nil, nil
	self.socSec = Section(section or (T:Waiting() > 0 and "trades") or self.socSec)
	if self.socSec == "trades" and T:Waiting() > 0 then
		self.tradeTab = "open"
	end
	self:Open("guild")
end

-- A trade made while it is on the screen: what goes flies to the other side, what comes to mine, a
-- stamp.
function A:PlayTradeDone(rec)
	local ed = self.frame.soc.ed
	local CW, CH = unpack(ns.CARD_SIZES.small)
	local shape = { coords = { 0, 366 / 512, 0, 1 }, ratio = CH / CW }
	local delay = 0
	for _, pair in ipairs({ { ed.give, ed.take }, { ed.take, ed.give } }) do
		for _, s in ipairs(pair[1].slots) do
			if s:IsShown() and SLOTS[s] then
				local icon = SLOTS[s].b and (MEDIA .. ((ns.SeriesByKey(SLOTS[s].b) or {}).pack or "PackElwynn") .. "Bottom") or (MEDIA .. "Back")
				Hud.Fly(icon, s, pair[2], 34, 0.7, nil, { 1, 0.85, 0.5 }, delay, SLOTS[s].b and { coords = { 0, 1, 0, 1 }, ratio = 2 } or shape)
				delay = delay + 0.05
			end
		end
	end
	ns.Play(ns.SND.whoosh)
	ns.Delay(0.75 + delay, function()
		if not ed:IsShown() then
			return
		end
		ns.Play(ns.SND.coins)
		Hud.Stamp(ed.stamp, 64, 0, function()
			Hud.Burst(ed.stamp, { 1, 0.86, 0.45 }, 18, 120, 18)
			ns.Delay(0.9, function()
				ed.stamp:Hide()
			end, A.CLAIMS)
		end, A.CLAIMS)
	end, A.CLAIMS)
end

ns.On("TRADES_CHANGED", function(rec)
	local f = A.frame
	if not (f and f:IsShown()) then
		return
	end
	if A.mode == "guild" and not A.member then
		-- (a trade being written: what changed under it shows, the draft stays)
		A:Refresh()
	else
		A:PaintBadges()
	end
end)

ns.On("TRADE_DONE", function(rec)
	local f = A.frame
	if f and f:IsShown() and A.mode == "guild" and A.ed and A.ed.id == rec.id and not A.ed.draft and f.soc and f.soc.ed:IsShown() then
		A:PlayTradeDone(rec)
	end
end)

-- (1.14.2: a find of the guild)
for _, e in ipairs({ "WISH_CHANGED", "FRIENDS_CHANGED", "GUILD_ALBUM", "GUILD_FINDS" }) do
	local _, e = _, e; ns.On(e, function()
		local f = A.frame
		if f and f:IsShown() and A.mode == "guild" and not A.member then
			A:Refresh()
		end
	end)
end

-- (1.14.2) The roster of the game changed (one joined or left the guild, came or went): the Guild section with it, a
-- second after (Trade.lua scans it on the same event; a big guild sends it often: once a second at most).
do
	local rf = CreateFrame("Frame")
	pcall(rf.RegisterEvent, rf, "GUILD_ROSTER_UPDATE")
	local pending
	CuratorOctoFull.SetScript(rf, "OnEvent", function()
		if pending then
			return
		end
		pending = true
		ns.Delay(1, function()
			pending = nil
			local f = A.frame
			if f and f:IsShown() and A.mode == "guild" and A.socSec == "guild" and not A.member then
				A:Refresh()
			end
		end, rf)
	end)
end
