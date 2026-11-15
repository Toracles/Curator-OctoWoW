local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin
local Hud = ns.Hud
local RV = ns.Reseller
local RB = ns.Rubies
local C = ns.Collection

-------------------------------------------------------------------------------
-- (1.12.0) The reseller on the screen (Reseller.lua): at a vendor of general goods or of trade supplies, a tab on the
-- right of the window of the merchant; a click on it opens his window beside it. Two pages: his cards of the day (the
-- cards themselves, forged now and then, their finish and their price under each; two clicks to buy one, it is dear),
-- and the copies he buys back: (1.13.0, after its first test) the inventory as he sees it (UI/Inventory.lua: a box to
-- tick on each copy he takes, as many as the player wants, then Sell), opened by his tab; his page says what it is and
-- opens it again. His window closes with the window of the merchant. Nowhere else: no command opens it.
-------------------------------------------------------------------------------
local RUI = {}
ns.ResellerUI = RUI

local W, H = 640, 382
local CARD_SCALE = 0.8
local CARD_W, CARD_H = ns.CARD_SIZES.small[1] * CARD_SCALE, ns.CARD_SIZES.small[2] * CARD_SCALE
local CARD_GAP = 10
local ARM = 3 -- (seconds) a first click arms the button, a second one within confirms
-- the line at the bottom of his window: its size of letters, smaller (down to FOOT_MIN) when it is too long for it
local FOOT_SIZE, FOOT_MIN = 10, 8
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local GOLD = S.GOLD
local DIM = { 0.72, 0.72, 0.76 }
local WHY = {
	sold = "Bought already: he has others tomorrow.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
	card = "He no longer has this card.",
}
local TABS = {
	{ key = "sale", label = "His cards" },
	{ key = "buy", label = "He buys back" },
	-- (1.14.0: the talents of the Smuggler, Black Market, Special Order, Pawnbroker: for them only)
	{ key = "counter", label = "Under the counter", smuggler = true },
}
local TAB_ICON = { sale = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01", buy = "Interface\\Icons\\INV_Misc_Coin_02",
	counter = "Interface\\Icons\\INV_Misc_Bag_10" }
-- (1.14.0) The tab of the talents of the Smuggler shows when one of them is learned.
local function Counter()
	local TL = ns.Talents
	return TL ~= nil and (TL:Has("blackmarket") or TL:Has("order") or TL:Has("pawn"))
end
RUI.Counter = Counter

-- (the colours of the finishes, as their frames show them)
local FINISH_COLOR = { shiny = { 0.55, 0.8, 1 }, holo = { 1, 0.62, 1 } }

local function FinishName(card, finish)
	if finish == "shiny" or finish == "holo" then
		return C:FinishName(card, finish)
	end
	return nil
end

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------
function RUI:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorReseller", W, H)
	tinsert(UISpecialFrames, "CuratorReseller")
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(ICON)
	end
	f:SetTitle(L["The reseller"])
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			RUI:Hide()
		end)
	end
	-- his words, under the title
	f.say = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.say:SetPoint("TOPLEFT", 64, -30)
	f.say:SetWidth(W - 64 - 150)
	CuratorOctoFull.SetWordWrap(f.say, true)
	f.say:SetTextColor(0.9, 0.84, 0.7)
	f.have = S.Text(f, "GameFontHighlight", "RIGHT")
	f.have:SetPoint("TOPRIGHT", -14, -34)
	-- the tabs
	f.tabs = {}
	for i, t in ipairs(TABS) do
		local i, t = i, t; local b = Hud.NavButton(f, 170, 26)
		b:SetPoint("TOPLEFT", 64 + (i - 1) * 176, -58)
		Hud.SetIcon(b.icon, { TAB_ICON[t.key] })
		b.key = t.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			if RUI.tab ~= t.key then
				ns.Play(ns.SND.page)
				RUI:Tab(t.key)
			end
			-- (1.13.0, after its first test: what he buys back, the inventory as he sees it, at once)
			if t.key == "buy" then
				RUI:OpenSelling()
			end
		end)
		f.tabs[i] = b
	end
	f.ground = S.Background(f)
	f.ground:SetPoint("TOPLEFT", 8, -90)
	f.ground:SetPoint("BOTTOMRIGHT", -6, 30)
	f.foot = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.foot:SetPoint("BOTTOMLEFT", 16, 10)
	f.foot:SetWidth(W - 32)
	CuratorOctoFull.SetWordWrap(f.foot, false)
	f.foot:SetTextColor(DIM[1], DIM[2], DIM[3])

	-- his cards of the day
	local sale = CreateFrame("Frame", nil, f)
	sale:SetPoint("TOPLEFT", f.ground, "TOPLEFT")
	sale:SetPoint("BOTTOMRIGHT", f.ground, "BOTTOMRIGHT")
	f.sale = sale
	sale.slots = {}
	for i = 1, RV.STOCK + 1 do
		local i = i; local slot = CreateFrame("Frame", nil, sale)
		CuratorOctoFull.SetSize(slot, CARD_W, CARD_H + 58)
		local c = ns.NewCard(slot, "small")
		c:SetScale(CARD_SCALE)
		c:SetPoint("TOP", slot, "TOP", 0, 0)
		CuratorOctoFull.SetScript(c, "OnEnter", function(self)
			RUI:CardTooltip(slot, self)
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function()
			GameTooltip:Hide()
		end)
		slot.card = c
		-- (a card forged: its finish, over the line of what it is to the album)
		slot.fin = S.Text(slot, "GameFontNormalSmall")
		slot.fin:SetPoint("TOP", slot, "TOP", 0, -CARD_H - 5)
		slot.fin:SetWidth(CARD_W + 10)
		CuratorOctoFull.SetWordWrap(slot.fin, false)
		slot.state = S.Text(slot, "GameFontHighlightSmall")
		slot.state:SetPoint("TOP", slot, "TOP", 0, -CARD_H - 5)
		slot.state:SetWidth(CARD_W + 6)
		CuratorOctoFull.SetWordWrap(slot.state, false)
		slot.buy = S.Button(slot, "", CARD_W + 4, 22)
		slot.buy:SetPoint("TOP", slot.state, "BOTTOM", 0, -4)
		if slot.buy.SetMotionScriptsWhileDisabled then
			CuratorOctoFull.SetMotionScriptsWhileDisabled(slot.buy, true)
		end
		CuratorOctoFull.SetScript(slot.buy, "OnClick", function()
			RUI:Buy(slot)
		end)
		CuratorOctoFull.SetScript(slot.buy, "OnEnter", function(self)
			RUI:CardTooltip(slot, self)
		end)
		CuratorOctoFull.SetScript(slot.buy, "OnLeave", function()
			GameTooltip:Hide()
		end)
		-- (1.14.0, Baron of Booty Bay: once a week, a card of his stall, rare at most, at his buying price)
		slot.baron = S.Button(slot, "", CARD_W + 4, 20)
		slot.baron:SetPoint("TOP", slot.buy, "BOTTOM", 0, -3)
		if slot.baron.SetMotionScriptsWhileDisabled then
			CuratorOctoFull.SetMotionScriptsWhileDisabled(slot.baron, true)
		end
		CuratorOctoFull.SetScript(slot.baron, "OnClick", function()
			RUI:Baron(slot)
		end)
		CuratorOctoFull.SetScript(slot.baron, "OnEnter", function(self)
			RUI:BaronTooltip(slot, self)
		end)
		CuratorOctoFull.SetScript(slot.baron, "OnLeave", function()
			GameTooltip:Hide()
		end)
		slot.baron:Hide()
		-- bought: a seal over it
		slot.sold = S.Text(slot, "GameFontNormalLarge")
		slot.sold:SetPoint("CENTER", slot, "TOP", 0, -CARD_H / 2)
		slot.sold:SetText(L["Bought"])
		slot.sold:SetTextColor(0.45, 1, 0.45)
		slot.i = i
		sale.slots[i] = slot
	end
	-- (1.14.0, Harbor Contacts, a talent of the Smuggler: more cards than his stall shows at once, a page of them)
	sale.prev = S.Arrow(sale, -1, 24)
	sale.prev:SetPoint("LEFT", sale, "LEFT", 6, 30)
	CuratorOctoFull.SetScript(sale.prev, "OnClick", function()
		RUI:SalePage(-1)
	end)
	sale.next = S.Arrow(sale, 1, 24)
	sale.next:SetPoint("RIGHT", sale, "RIGHT", -6, 30)
	CuratorOctoFull.SetScript(sale.next, "OnClick", function()
		RUI:SalePage(1)
	end)
	S.PageArrows(sale.prev, sale.next)
	sale.page = S.Text(sale, "GameFontHighlightSmall")
	sale.page:SetPoint("BOTTOM", sale, "BOTTOM", 0, 6)
	sale.page:SetTextColor(DIM[1], DIM[2], DIM[3])

	-- the copies he buys back (1.13.0, after its first test): the inventory as he sees it (UI/Inventory.lua); here,
	-- what it is and the way to it
	local buy = CreateFrame("Frame", nil, f)
	buy:SetPoint("TOPLEFT", f.ground, "TOPLEFT", 10, -8)
	buy:SetPoint("BOTTOMRIGHT", f.ground, "BOTTOMRIGHT", -10, 6)
	f.buy = buy
	-- three copies fanned out in his hand, the one in front ticked, the light of the rubies behind them
	local art = CreateFrame("Frame", nil, buy)
	CuratorOctoFull.SetSize(art, 200, 230)
	art:SetPoint("LEFT", buy, "LEFT", 6, 0)
	buy.art = art
	art.glow = art:CreateTexture(nil, "BACKGROUND")
	art.glow:SetTexture(ns.MEDIA .. "Glow")
	art.glow:SetBlendMode("ADD")
	art.glow:SetPoint("CENTER", 0, 4)
	CuratorOctoFull.SetSize(art.glow, 270, 250)
	art.glow:SetVertexColor(1, 0.25, 0.32)
	art.glow:SetAlpha(0.2)
	art.cards = {}
	for i, a in ipairs({ { -40, -8, 0.24 }, { 40, -8, -0.24 }, { 0, 4, 0 } }) do
		local t = art:CreateTexture(nil, "ARTWORK", nil, i)
		t:SetTexture(ns.MEDIA .. "Back_S")
		t:SetTexCoord(0, 366 / 512, 0, 1)
		CuratorOctoFull.SetSize(t, 92, 128)
		t:SetPoint("CENTER", a[1], a[2])
		CuratorOctoFull.SetRotation(t, a[3])
		if i < 3 then
			t:SetVertexColor(0.72, 0.72, 0.76)
		end
		art.cards[i] = t
	end
	art.check = art:CreateTexture(nil, "OVERLAY")
	art.check:SetTexture(ns.MEDIA .. "Check")
	CuratorOctoFull.SetSize(art.check, 40, 40)
	art.check:SetPoint("CENTER", art, "CENTER", 34, 56)
	art.ruby = art:CreateTexture(nil, "OVERLAY", nil, 1)
	art.ruby:SetTexture(RB.ICON)
	CuratorOctoFull.SetSize(art.ruby, 34, 34)
	art.ruby:SetPoint("CENTER", art, "CENTER", 0, -78)
	art.rubyGlow = art:CreateTexture(nil, "OVERLAY")
	art.rubyGlow:SetTexture(ns.MEDIA .. "Glow")
	art.rubyGlow:SetBlendMode("ADD")
	art.rubyGlow:SetVertexColor(1, 0.3, 0.36)
	CuratorOctoFull.SetSize(art.rubyGlow, 80, 80)
	art.rubyGlow:SetPoint("CENTER", art.ruby, "CENTER")
	art.rubyGlow:SetAlpha(0.55)
	-- what it is, what he takes now, the way to it
	local tx = 226
	buy.title = S.Text(buy, "GameFontNormalLarge", "LEFT")
	buy.title:SetPoint("TOPLEFT", buy, "TOPLEFT", tx, -22)
	buy.title:SetWidth(W - 36 - tx)
	CuratorOctoFull.SetWordWrap(buy.title, false)
	buy.title:SetText(L["He buys back your copies"])
	buy.text = S.Text(buy, "GameFontHighlight", "LEFT")
	buy.text:SetPoint("TOPLEFT", buy.title, "BOTTOMLEFT", 0, -10)
	buy.text:SetWidth(W - 36 - tx)
	CuratorOctoFull.SetWordWrap(buy.text, true)
	buy.text:SetSpacing(2)
	buy.text:SetText(L["Tick in your inventory the copies you want to sell him: he takes them for next to nothing, as many as you want."])
	buy.now = S.Text(buy, "GameFontHighlightSmall", "LEFT")
	buy.now:SetPoint("TOPLEFT", buy.text, "BOTTOMLEFT", 0, -12)
	buy.now:SetWidth(W - 36 - tx)
	CuratorOctoFull.SetWordWrap(buy.now, true)
	-- (1.13.0, after its second test: the guard of the week, what he still pays in full: Rubies.lua, RB.GUARD)
	buy.guard = S.Text(buy, "GameFontHighlightSmall", "LEFT")
	buy.guard:SetPoint("TOPLEFT", buy.now, "BOTTOMLEFT", 0, -8)
	buy.guard:SetWidth(W - 36 - tx)
	CuratorOctoFull.SetWordWrap(buy.guard, true)
	buy.open = S.Button(buy, L["Open my inventory"], 250, 30)
	buy.open:SetPoint("BOTTOMLEFT", buy, "BOTTOMLEFT", tx, 22)
	if buy.open.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(buy.open, true)
	end
	CuratorOctoFull.SetScript(buy.open, "OnClick", function()
		ns.Play(ns.SND.click)
		RUI:OpenSelling()
	end)
	CuratorOctoFull.SetScript(buy.open, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Open my inventory"], 1, 1, 1)
		GameTooltip:AddLine(L["The copies he takes first, a box to tick on each: then Sell."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(buy.open, "OnLeave", function()
		GameTooltip:Hide()
	end)

	-- (1.14.0) under the counter: the talents of the Smuggler (UI below: RUI:BuildCounter)
	self:BuildCounter(f)

	f.t = 0
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		if RUI.tab == "sale" then
			for _, slot in ipairs(self.sale.slots) do
				if slot:IsShown() then
					slot.card:Tick(self.t)
				end
			end
		end
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		if RUI.tabButton then
			RUI.tabButton:SetChecked(false)
		end
	end)
	self.frame = f
	return f
end

-- Where it stands: beside the window of the merchant (past the tab), or in the middle.
function RUI:Place()
	local f = self.frame
	f:ClearAllPoints()
	local m = _G.MerchantFrame
	if m and m.IsShown and m:IsShown() then
		f:SetPoint("TOPLEFT", m, "TOPRIGHT", 46, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 120, 60)
	end
end

function RUI:Open(tab)
	if not RV.here then
		ns.Print(L["The reseller stands at the vendors of general goods and of trade supplies: talk to one of them to see his cards."])
		return false
	end
	local f = self:Build()
	self:Place()
	f:Show()
	f:Raise()
	ns.Play(ns.SND.open)
	if self.tabButton then
		self.tabButton:SetChecked(true)
	end
	self:Tab(tab or self.tab or "sale")
	return true
end

function RUI:Hide()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
		ns.Play(ns.SND.close)
	end
end

function RUI:Toggle()
	if self.frame and self.frame:IsShown() then
		self:Hide()
	else
		self:Open()
	end
end

function RUI:Tab(key)
	local f = self:Build()
	self.tab = key or self.tab or "sale"
	if self.tab == "counter" and not Counter() then
		self.tab = "sale"
	end
	self.page = 1
	CuratorOctoFull.SetShown(f.sale, self.tab == "sale")
	CuratorOctoFull.SetShown(f.buy, self.tab == "buy")
	CuratorOctoFull.SetShown(f.counter, self.tab == "counter")
	self.picking = nil
	self:Paint()
end

-------------------------------------------------------------------------------
-- What it shows
-------------------------------------------------------------------------------
function RUI:Paint()
	local f = self.frame
	if not (f and f:IsShown()) then
		return
	end
	f.have:SetText(RB.Text(RB:Balance(), 15))
	-- (the copies he takes now, and what they would bring: on his tab, on his page)
	local IU = ns.InventoryUI
	self.takes, self.worth = 0, 0
	if IU and IU.Taken then
		self.takes, self.worth = IU:Taken()
	end
	-- (1.14.0: four tabs with the counter of the Smuggler, narrower; the one of the displays, UI/Displays.lua, among them)
	local four = Counter()
	for i, b in ipairs(f.tabs) do
		CuratorOctoFull.SetShown(b, not TABS[i].smuggler or four)
	end
	local tw = four and 136 or 170
	local x = 64
	for _, b in ipairs({ f.tabs[1], f.tabs[2], f.dispTab or false, f.tabs[3] }) do
		if b and b:IsShown() then
			b.width = tw
			b:SetWidth(tw)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", x, -58)
			x = x + tw + 6
		end
	end
	for i, b in ipairs(f.tabs) do
		local count = ""
		if b.key == "sale" then
			local st, left = RV:State(), 0
			for j = 1, CuratorOctoFull.Length(RV:Stock()) do
				if not (st and st.got[j]) then
					left = left + 1
				end
			end
			count = tostring(left)
		elseif b.key == "buy" then
			count = ns.Num(self.takes)
		elseif b.key == "counter" then
			local TL = ns.Talents
			count = (TL and TL:BlackMarket()) and "!" or ""
		end
		b:Paint(b.key == self.tab, L[TABS[i].label], count, 0)
	end
	local nextIn = (ns.Inns and ns.Inns.NextIn) and ns.Inns:NextIn() or nil
	if self.tab == "counter" then
		f.say:SetText(L["\"Between us, then. What is under my counter never was here.\""])
		self:Foot(L["The talents of the Smuggler: Black Market, Special Order, Pawnbroker."])
		self:PaintCounter()
	elseif self.tab == "buy" then
		f.say:SetText(L["\"Your copies to spare? I take them, for what they are worth to me. Not much.\""])
		self:Foot(L["He takes everything: every copy, the last ones too, your cases and your keys. Only what a trade or an enchanter holds stays."])
		self:PaintBuy()
	else
		f.say:SetText(L["\"Cards of every album, picked up here and there. Dear, I know: you will find them nowhere else.\""])
		self:Foot(nextIn and string.format(L["Other cards in %s · never those of a limited edition"], ns.Duration(nextIn))
			or L["Other cards tomorrow · never those of a limited edition"])
		self:PaintSale()
	end
end

-- The line at the bottom: in smaller letters when it is too long for the window (in some languages).
function RUI:Foot(text)
	local fs = self.frame.foot
	local file, _, flags = fs:GetFont()
	file, flags = file or "Fonts\\FRIZQT__.TTF", flags or ""
	local k = FOOT_SIZE
	fs:SetFont(file, k, flags)
	fs:SetText(text)
	while k > FOOT_MIN and (ns.TextWidth(fs) or 0) > W - 32 do
		k = k - 0.5
		fs:SetFont(file, k, flags)
	end
end

-- (1.14.0) Another page of his cards (Harbor Contacts: more than his stall shows at once).
function RUI:SalePage(dir)
	ns.Play(ns.SND.page)
	self.salePage = (self.salePage or 1) + dir
	for _, slot in ipairs(self.frame.sale.slots) do
		slot.armed, slot.baronArmed = nil, nil
	end
	self:Paint()
end

function RUI:PaintSale()
	local f = self.frame
	local stock = RV:Stock()
	local st = RV:State()
	local n = CuratorOctoFull.Length(stock)
	-- (a page of them: as many as his stall shows)
	local per = CuratorOctoFull.Length(f.sale.slots)
	local pages = math.max(1, math.ceil(n / per))
	self.salePage = math.max(1, math.min(pages, self.salePage or 1))
	local first = (self.salePage - 1) * per
	local shownN = math.max(0, math.min(per, n - first))
	CuratorOctoFull.SetShown(f.sale.prev, pages > 1)
	CuratorOctoFull.SetShown(f.sale.next, pages > 1)
	CuratorOctoFull.SetEnabled(f.sale.prev, self.salePage > 1)
	CuratorOctoFull.SetEnabled(f.sale.next, self.salePage < pages)
	CuratorOctoFull.SetShown(f.sale.page, pages > 1)
	f.sale.page:SetText(string.format(L["Page %d / %d"], self.salePage, pages))
	local total = shownN * CARD_W + (shownN - 1) * CARD_GAP
	local x0 = (W - 14 - total) / 2
	for j, slot in ipairs(f.sale.slots) do
		local i = first + j
		if slot.i ~= i then
			slot.armed, slot.baronArmed = nil, nil
		end
		slot.i = i
		local card = j <= shownN and stock[i] or nil
		CuratorOctoFull.SetShown(slot, card ~= nil)
		if card then
			slot:ClearAllPoints()
			slot:SetPoint("TOPLEFT", f.sale, "TOPLEFT", x0 + (j - 1) * (CARD_W + CARD_GAP), -14)
			local bought = st and st.got[i]
			local finish = RV:StockFinish(i)
			if slot.shown ~= card or slot.shownFinish ~= finish then
				slot.shown, slot.shownFinish = card, finish
				slot.card:SetCard(card, { owned = true, finish = finish })
				slot.card:ShowSide("front")
			end
			-- (its finish, in its colour, the line of the album under it)
			local fin = FinishName(card, finish)
			CuratorOctoFull.SetShown(slot.fin, fin ~= nil)
			if fin then
				-- (a long name of a finish, in some languages: smaller until it fits under the card)
				S.SetFontObject(slot.fin, "GameFontNormalSmall")
				slot.fin:SetText(fin)
				if ns.TextWidth(slot.fin) > CARD_W + 10 then
					S.Fit(slot.fin, fin, CARD_W + 10, 10, 8)
				end
				local c = FINISH_COLOR[finish] or GOLD
				slot.fin:SetTextColor(c[1], c[2], c[3])
			end
			slot.state:ClearAllPoints()
			slot.state:SetPoint("TOP", slot, "TOP", 0, -CARD_H - (fin and 19 or 5))
			slot.card:SetAlpha(bought and 0.35 or 1)
			CuratorOctoFull.SetShown(slot.sold, bought and true or false)
			local e = C:Entry(card)
			local have = e and e.n or 0
			if bought then
				slot.state:SetText("")
			elseif have > 0 then
				slot.state:SetText(string.format(L["You have %d"], have))
				slot.state:SetTextColor(DIM[1], DIM[2], DIM[3])
			else
				slot.state:SetText(L["New!"])
				slot.state:SetTextColor(0.45, 1, 0.45)
			end
			local ok, why = RV:CanBuy(i)
			slot.why = why
			if not (slot.armed and GetTime() - slot.armed < ARM) then
				slot.armed = nil
				slot.buy:SetLabel(bought and L["Bought"] or RB.Text(RV:Price(card, finish), 12))
			end
			CuratorOctoFull.SetEnabled(slot.buy, ok)
			-- (1.14.0, Baron of Booty Bay: a card rare at most, while the talent is ready)
			local TL = ns.Talents
			local baron = TL ~= nil and TL:Has("baron") and card.rarity <= 3 and not bought
			CuratorOctoFull.SetShown(slot.baron, baron and true or false)
			if baron then
				if not (slot.baronArmed and GetTime() - slot.baronArmed < ARM) then
					slot.baronArmed = nil
					slot.baron:SetLabel(string.format(L["Baron: %s"], RB.Text(RV:BaronPrice(i) or 0, 11)))
				end
				CuratorOctoFull.SetEnabled(slot.baron, RV:CanBaron(i) and true or false)
			end
		end
	end
end

function RUI:CardTooltip(slot, owner)
	local card = RV:Stock()[slot.i]
	if not card then
		return
	end
	local finish = RV:StockFinish(slot.i)
	GameTooltip:SetOwner(owner or slot, "ANCHOR_RIGHT")
	if ns.Links and ns.Links.AddLines then
		ns.Links:AddLines(GameTooltip, card)
	else
		GameTooltip:AddLine(C:Name(card), 1, 1, 1)
	end
	local fin = FinishName(card, finish)
	if fin then
		local c = FINISH_COLOR[finish] or GOLD
		GameTooltip:AddLine(fin, c[1], c[2], c[3])
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(RV:Price(card, finish), 13)), 1, 0.82, 0.25)
	local why = slot.why
	if why and WHY[why] then
		GameTooltip:AddLine(L[WHY[why]], 1, 0.45, 0.4, true)
	elseif slot.armed and GetTime() - slot.armed < ARM then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function RUI:Buy(slot)
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local ok, why = RV:CanBuy(slot.i)
	if not ok then
		ns.Play(ns.SND.close)
		slot.why = why
		self:CardTooltip(slot, slot.buy)
		return
	end
	-- (two clicks: it is dear)
	if not (slot.armed and GetTime() - slot.armed < ARM) then
		slot.armed = GetTime()
		slot.buy:SetLabel(L["Confirm"])
		ns.Play(ns.SND.click)
		self:CardTooltip(slot, slot.buy)
		return
	end
	slot.armed = nil
	local done, card, price, finish = RV:Buy(slot.i)
	if not done then
		ns.Play(ns.SND.close)
		self:Paint()
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.coins)
	ns.Play((finish and ns.SND.shiny) or ns.SND.reveal[card.rarity] or ns.SND.shiny)
	Hud.Burst(slot.card, ns.RARITY[card.rarity].glow, finish and 34 or 22, 140, 18)
	local fin = FinishName(card, finish)
	ns.Print(L["From the reseller: %s, for %s."], fin and (C:Name(card) .. " (" .. fin .. ")") or C:Name(card), RB.Text(price or 0))
	self:Paint()
end

-- His page of the copies he buys back: how many he takes now, what they would bring; the way to the inventory as he
-- sees it.
function RUI:PaintBuy()
	local b = self.frame.buy
	local IU = ns.InventoryUI
	local n, rubies = self.takes or 0, self.worth or 0
	-- (1.14.0, a player's word: he takes everything; what is said here, the duplicates)
	if n > 0 then
		b.now:SetText(string.format(L["Your duplicates: %d copies, %s for all of them. He takes every other copy too."], n, RB.Text(rubies, 13)))
		b.now:SetTextColor(1, 0.86, 0.45)
	else
		b.now:SetText(L["No duplicate now. He takes every copy, the last ones too: the inventory warns you."])
		b.now:SetTextColor(DIM[1], DIM[2], DIM[3])
	end
	if b.guard then
		local RUBI = ns.RubiesUI
		b.guard:SetText(RUBI and RUBI.GuardLine and RUBI:GuardLine() or "")
		b.guard:SetTextColor(0.8, 0.8, 0.84)
	end
	CuratorOctoFull.SetEnabled(b.open, IU ~= nil and IU.OpenSeller ~= nil and not (ns.Beta and ns.Beta:Over()))
end

-- (1.13.0, after its first test) The inventory as he sees it (UI/Inventory.lua): over his window.
function RUI:OpenSelling()
	local IU = ns.InventoryUI
	if not (IU and IU.OpenSeller) or (ns.Beta and ns.Beta:Blocked()) then
		return false
	end
	GameTooltip:Hide()
	return IU:OpenSeller()
end

-------------------------------------------------------------------------------
-- His tab, on the window of the merchant
-------------------------------------------------------------------------------
function RUI:TabButton()
	if self.tabButton then
		return self.tabButton
	end
	local parent = _G.MerchantFrame or UIParent
	local t = S.SideTab(parent, ICON, L["The reseller (Curator)"], function()
		RUI:Toggle()
	end)
	t:Hide()
	self.tabButton = t
	return t
end

function RUI:ShowTab(on)
	local t = self:TabButton()
	t:ClearAllPoints()
	local m = _G.MerchantFrame
	if m and t:GetParent() == m then
		t:SetPoint("TOPLEFT", m, "TOPRIGHT", 0, -46)
	else
		t:SetPoint("LEFT", UIParent, "LEFT", 10, 120)
	end
	CuratorOctoFull.SetShown(t, on and true or false)
	t:SetChecked(on and self.frame and self.frame:IsShown() or false)
end

-- the reseller there, or no longer
ns.On("RESELLER", function(here)
	if here then
		RUI:ShowTab(true)
		local st = RV:State()
		if st and st.told ~= st.d then
			st.told = st.d
			ns.Print(L["The reseller is at this vendor today: his tab, on the right of the merchant's window."])
		end
	else
		RUI:ShowTab(false)
		RUI:Hide()
	end
end)

for _, event in ipairs({ "RUBIES_CHANGED", "CHANGED" }) do
	ns.On(event, function()
		if RUI.frame and RUI.frame:IsShown() then
			RUI:Paint()
		end
	end)
end

-------------------------------------------------------------------------------
-- (1.14.0) Baron of Booty Bay, on a card of his stall: two clicks
-------------------------------------------------------------------------------
local BARON_WHY = {
	ready = "Once a week: the Baron of Booty Bay is used this week.",
	card = "A card rare at most.",
	sold = "Bought already: he has others tomorrow.",
	rubies = "Not enough rubies.",
	here = "At the reseller only.",
}

function RUI:BaronTooltip(slot, owner)
	local TL = ns.Talents
	local card = RV:Stock()[slot.i]
	if not (TL and card) then
		return
	end
	GameTooltip:SetOwner(owner or slot, "ANCHOR_RIGHT")
	GameTooltip:AddLine(TL:Name("baron"), 1, 0.78, 0.3)
	GameTooltip:AddLine(TL:Text("baron", 1), 1, 1, 1, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(string.format(L["%s for %s instead of %s."], C:Name(card), RB.Text(RV:BaronPrice(slot.i) or 0, 13), RB.Text(RV:Price(card, RV:StockFinish(slot.i)), 13)), 1, 0.82, 0.25, true)
	local ok, why = RV:CanBaron(slot.i)
	if not ok and BARON_WHY[why or ""] then
		GameTooltip:AddLine(L[BARON_WHY[why]], 1, 0.45, 0.4, true)
	elseif slot.baronArmed and GetTime() - slot.baronArmed < ARM then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

function RUI:Baron(slot)
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local ok = RV:CanBaron(slot.i)
	if not ok then
		ns.Play(ns.SND.close)
		self:BaronTooltip(slot, slot.baron)
		return
	end
	if not (slot.baronArmed and GetTime() - slot.baronArmed < ARM) then
		slot.baronArmed = GetTime()
		slot.baron:SetLabel(L["Confirm"])
		ns.Play(ns.SND.click)
		self:BaronTooltip(slot, slot.baron)
		return
	end
	slot.baronArmed = nil
	local done, card, price = RV:Baron(slot.i)
	if not done then
		ns.Play(ns.SND.close)
		self:Paint()
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.reveal[card.rarity] or ns.SND.shiny)
	Hud.Burst(slot.card, { 1, 0.78, 0.3 }, 30, 140, 18)
	ns.Print(L["Baron of Booty Bay: %s, for %s."], C:Name(card), RB.Text(price or 0))
	self:Paint()
end

-------------------------------------------------------------------------------
-- (1.14.0) Under the counter: Black Market (the card he brings out, rare or epic, cheaper), Special Order (a card the
-- collection misses, epic at most, at its full price: chosen in a list of his albums), Pawnbroker (the copies sold in
-- the last three days, bought back at what he paid)
-------------------------------------------------------------------------------
local COL_W = math.floor((W - 14 - 2 * 8) / 3)
local PICK_ROWS, PICK_COLS = 7, 2

local function Column(parent, i, title, icon)
	local c = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(c, COL_W, 248)
	c:SetPoint("TOPLEFT", (i - 1) * (COL_W + 8), -6)
	Hud.Panel(c, 248)
	c.icon = Hud.RoundIcon(c, 24, "ARTWORK", 2)
	c.icon:SetPoint("TOPLEFT", 10, -10)
	Hud.SetIcon(c.icon, { icon })
	c.title = S.Text(c, "GameFontNormal", "LEFT")
	c.title:SetPoint("LEFT", c.icon, "RIGHT", 8, 0)
	c.title:SetWidth(COL_W - 50)
	CuratorOctoFull.SetWordWrap(c.title, false)
	c.title:SetText(title)
	c.text = S.Text(c, "GameFontHighlightSmall", "LEFT")
	c.text:SetPoint("TOPLEFT", 12, -42)
	c.text:SetWidth(COL_W - 24)
	CuratorOctoFull.SetWordWrap(c.text, true)
	c.text:SetTextColor(0.85, 0.85, 0.88)
	c.btn = S.Button(c, "", COL_W - 24, 24)
	c.btn:SetPoint("BOTTOM", 0, 12)
	if c.btn.SetMotionScriptsWhileDisabled then
		CuratorOctoFull.SetMotionScriptsWhileDisabled(c.btn, true)
	end
	c.none = S.Text(c, "GameFontHighlightSmall")
	c.none:SetPoint("CENTER", 0, 0)
	c.none:SetWidth(COL_W - 24)
	CuratorOctoFull.SetWordWrap(c.none, true)
	c.none:SetTextColor(DIM[1], DIM[2], DIM[3])
	return c
end

function RUI:BuildCounter(f)
	local TL = ns.Talents
	local co = CreateFrame("Frame", nil, f)
	co:SetPoint("TOPLEFT", f.ground, "TOPLEFT", 7, 0)
	co:SetPoint("BOTTOMRIGHT", f.ground, "BOTTOMRIGHT", -7, 0)
	co:Hide()
	f.counter = co
	local function Name(id)
		return TL and TL.BY[id] and TL:Name(id) or id
	end
	-- the Black Market
	local bm = Column(co, 1, Name("blackmarket"), "Interface\\Icons\\INV_Misc_Bag_10")
	bm.card = ns.NewCard(bm, "small")
	bm.card:SetScale(0.62)
	bm.card:SetPoint("TOP", bm, "TOP", 0, -84 / 0.62)
	bm.card:Hide()
	CuratorOctoFull.SetScript(bm.card, "OnEnter", function(self)
		local card = TL and TL:BlackMarket()
		if card then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			ns.Booster:CardTooltip(card, nil)
			GameTooltip:Show()
		end
	end)
	CuratorOctoFull.SetScript(bm.card, "OnLeave", function()
		GameTooltip:Hide()
	end)
	bm.crate = bm:CreateTexture(nil, "ARTWORK")
	bm.crate:SetTexture("Interface\\Icons\\INV_Crate_04")
	CuratorOctoFull.SetSize(bm.crate, 64, 64)
	bm.crate:SetPoint("CENTER", 0, -10)
	bm.price = S.Text(bm, "GameFontNormal")
	bm.price:SetPoint("BOTTOM", bm.btn, "TOP", 0, 6)
	CuratorOctoFull.SetScript(bm.btn, "OnClick", function()
		RUI:BlackMarketClick()
	end)
	co.bm = bm
	-- the Special Order
	local od = Column(co, 2, Name("order"), "Interface\\Icons\\INV_Letter_09")
	od.seal = od:CreateTexture(nil, "ARTWORK")
	od.seal:SetTexture(ns.MEDIA .. "Seal")
	CuratorOctoFull.SetSize(od.seal, 70, 70)
	od.seal:SetPoint("CENTER", 0, -14)
	CuratorOctoFull.SetScript(od.btn, "OnClick", function()
		RUI:StartPicking()
	end)
	co.od = od
	-- the Pawnbroker
	local pw = Column(co, 3, Name("pawn"), "Interface\\Icons\\INV_Misc_Bag_11")
	pw.rows = {}
	for i = 1, 6 do
		local i = i; local r = CreateFrame("Button", nil, pw)
		CuratorOctoFull.SetSize(r, COL_W - 16, 25)
		r:SetPoint("TOPLEFT", 8, -84 - (i - 1) * 26)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT")
		r.hl:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.6, 0.08)
		r.name = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.name:SetPoint("TOPLEFT", 2, -1)
		r.name:SetWidth(COL_W - 24)
		CuratorOctoFull.SetWordWrap(r.name, false)
		r.sub = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.sub:SetPoint("BOTTOMLEFT", 2, 1)
		r.sub:SetWidth(COL_W - 24)
		CuratorOctoFull.SetWordWrap(r.sub, false)
		r.sub:SetTextColor(DIM[1], DIM[2], DIM[3])
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			RUI:BuyBackClick(self)
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			RUI:PawnTooltip(self)
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		pw.rows[i] = r
	end
	pw.btn:Hide()
	co.pw = pw
	-- the list of a Special Order: the albums he sells, the cards of each the collection misses (epic at most)
	local pk = CreateFrame("Frame", nil, co)
	pk:SetAllPoints()
	pk:SetFrameLevel(co:GetFrameLevel() + 10)
	Hud.Panel(pk, 260)
	pk.prev = S.Arrow(pk, -1, 24)
	pk.prev:SetPoint("TOPLEFT", 10, -8)
	CuratorOctoFull.SetScript(pk.prev, "OnClick", function()
		RUI:TurnPick(-1)
	end)
	pk.next = S.Arrow(pk, 1, 24)
	pk.next:SetPoint("TOPRIGHT", -10, -8)
	CuratorOctoFull.SetScript(pk.next, "OnClick", function()
		RUI:TurnPick(1)
	end)
	pk.album = S.Text(pk, "GameFontNormal")
	pk.album:SetPoint("TOP", 0, -12)
	pk.album:SetWidth(W - 120)
	pk.rows = {}
	local rw = math.floor((W - 14 - 30) / PICK_COLS)
	for i = 1, PICK_ROWS * PICK_COLS do
		local i = i; local r = CreateFrame("Button", nil, pk)
		CuratorOctoFull.SetSize(r, rw - 6, 24)
		local col, row = CuratorOctoFull.Mod((i - 1) , PICK_COLS), math.floor((i - 1) / PICK_COLS)
		r:SetPoint("TOPLEFT", 12 + col * rw, -40 - row * 26)
		r.shade = r:CreateTexture(nil, "BACKGROUND")
		r.shade:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.shade, 1, 1, 1, 0.04)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT")
		r.hl:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.6, 0.1)
		r.gem = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.gem, 14, 14)
		r.gem:SetPoint("LEFT", 4, 0)
		r.name = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.name:SetPoint("LEFT", r.gem, "RIGHT", 6, 0)
		r.name:SetWidth(rw - 120)
		CuratorOctoFull.SetWordWrap(r.name, false)
		r.price = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.price:SetPoint("RIGHT", -6, 0)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			RUI:OrderClick(self)
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			if self.card then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				ns.Booster:CardTooltip(self.card, nil)
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(self.armed and GetTime() - self.armed < ARM and L["Click again to confirm."] or L["Click, then click again to confirm."], 0.3, 1, 0.3)
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		pk.rows[i] = r
	end
	pk.page = S.Text(pk, "GameFontHighlightSmall")
	pk.page:SetPoint("BOTTOM", 0, 14)
	pk.pprev = S.Arrow(pk, -1, 20)
	pk.pprev:SetPoint("RIGHT", pk.page, "LEFT", -8, 0)
	CuratorOctoFull.SetScript(pk.pprev, "OnClick", function()
		RUI.pickPage = math.max(1, (RUI.pickPage or 1) - 1)
		ns.Play(ns.SND.page)
		RUI:PaintCounter()
	end)
	pk.pnext = S.Arrow(pk, 1, 20)
	pk.pnext:SetPoint("LEFT", pk.page, "RIGHT", 8, 0)
	CuratorOctoFull.SetScript(pk.pnext, "OnClick", function()
		RUI.pickPage = (RUI.pickPage or 1) + 1
		ns.Play(ns.SND.page)
		RUI:PaintCounter()
	end)
	S.PageArrows(pk.pprev, pk.pnext)
	pk.back = S.Button(pk, L["Back"], 110, 22)
	pk.back:SetPoint("BOTTOMLEFT", 12, 10)
	CuratorOctoFull.SetScript(pk.back, "OnClick", function()
		ns.Play(ns.SND.page)
		RUI.picking = nil
		RUI:PaintCounter()
	end)
	pk.empty = S.Text(pk, "GameFontHighlight")
	pk.empty:SetPoint("CENTER", 0, 0)
	pk.empty:SetWidth(W - 80)
	pk.empty:SetTextColor(DIM[1], DIM[2], DIM[3])
	pk:Hide()
	co.pick = pk
end

-- The albums he sells whose cards (epic at most) the collection misses, and those cards of one, in their order.
function RUI:OrderAlbums()
	local TL = ns.Talents
	local by, list = {}, {}
	for _, card in ipairs(RV:Pool() or {}) do
		local s = card.series
		if s and not s.event and not s.limited and card.rarity <= 4 and TL.Missing(card) then
			if not by[s] then
				by[s] = {}
				list[CuratorOctoFull.Length(list) + 1] = s
			end
			CuratorOctoFull.Insert(by[s], card)
		end
	end
	local order = {}
	for i, s in ipairs(ns.Series or {}) do
		order[s] = i
	end
	table.sort(list, function(a, b)
		return (order[a] or 0) < (order[b] or 0)
	end)
	for _, s in ipairs(list) do
		table.sort(by[s], function(a, b)
			if a.rarity ~= b.rarity then
				return a.rarity > b.rarity
			end
			return C:Name(a) < C:Name(b)
		end)
	end
	return list, by
end

function RUI:StartPicking()
	local TL = ns.Talents
	if not (TL and TL:Ready("order")) then
		ns.Play(ns.SND.close)
		return
	end
	ns.Play(ns.SND.page)
	self.picking = true
	self.pickPage = 1
	local list = self:OrderAlbums()
	-- (the album of this place first, when he sells it)
	local here = ns.Rewards and ns.Rewards:ZoneSeries()
	self.pickAlbum = nil
	for _, s in ipairs(list) do
		if s == here then
			self.pickAlbum = s
		end
	end
	self.pickAlbum = self.pickAlbum or list[1]
	self:PaintCounter()
end

function RUI:TurnPick(dir)
	local list = self:OrderAlbums()
	if CuratorOctoFull.Length(list) == 0 then
		return
	end
	local at = 1
	for i, s in ipairs(list) do
		if s == self.pickAlbum then
			at = i
		end
	end
	at = CuratorOctoFull.Mod((at - 1 + dir) , CuratorOctoFull.Length(list)) + 1
	self.pickAlbum = list[at]
	self.pickPage = 1
	ns.Play(ns.SND.page)
	self:PaintCounter()
end

function RUI:PaintCounter()
	local f = self.frame
	local co = f and f.counter
	local TL = ns.Talents
	if not (co and co:IsShown() and TL) then
		return
	end
	local pk = co.pick
	CuratorOctoFull.SetShown(pk, self.picking and true or false)
	CuratorOctoFull.SetShown(co.bm, not self.picking)
	CuratorOctoFull.SetShown(co.od, not self.picking)
	CuratorOctoFull.SetShown(co.pw, not self.picking)
	if self.picking then
		return self:PaintPicking()
	end
	-- the Black Market
	local bm = co.bm
	local has = TL:Has("blackmarket")
	local card, price = TL:BlackMarket()
	CuratorOctoFull.SetShown(bm.card, has and card ~= nil)
	CuratorOctoFull.SetShown(bm.crate, has and card == nil)
	CuratorOctoFull.SetShown(bm.price, has and card ~= nil)
	CuratorOctoFull.SetShown(bm.btn, has)
	CuratorOctoFull.SetShown(bm.none, not has)
	bm.none:SetText(not has and L["A talent of the Smuggler, at the third tier of his tree."] or "")
	if has then
		if card then
			if bm.shown ~= card then
				bm.shown = card
				bm.card:SetCard(card, { owned = true })
				bm.card:ShowSide("front")
			end
			bm.text:SetText(string.format(L["He brings it out from under his counter: %s cheaper than its price."], ns.Pct(TL:BlackMarketOff())))
			bm.price:SetText(RB.Text(price, 13))
			local armed = self.bmArmed and GetTime() - self.bmArmed < ARM
			bm.btn:SetLabel(armed and L["Confirm"] or L["Buy it"])
			CuratorOctoFull.SetEnabled(bm.btn, RB:Has(price))
		elseif TL:Ready("blackmarket") then
			bm.text:SetText(L["\"I may have something you are missing, rare or epic. For you, a price.\""])
			CuratorOctoFull.SetDesaturated(bm.crate, false)
			bm.btn:SetLabel(L["Ask him"])
			CuratorOctoFull.SetEnabled(bm.btn, true)
		else
			bm.text:SetText(L["Nothing under his counter for now."])
			CuratorOctoFull.SetDesaturated(bm.crate, true)
			bm.btn:SetLabel(string.format(L["Again in %s"], ns.Duration(TL:Left("blackmarket"))))
			CuratorOctoFull.SetEnabled(bm.btn, false)
		end
	end
	-- the Special Order
	local od = co.od
	local hasO = TL:Has("order")
	CuratorOctoFull.SetShown(od.btn, hasO)
	CuratorOctoFull.SetShown(od.seal, hasO)
	CuratorOctoFull.SetShown(od.none, not hasO)
	od.none:SetText(not hasO and L["A summit of the tree of the Smuggler, at its seventh tier."] or "")
	if hasO then
		local ready = TL:Ready("order")
		od.text:SetText(L["Once a day, a card you are missing, epic at most, of the albums he sells: at its full price."])
		CuratorOctoFull.SetDesaturated(od.seal, not ready)
		od.btn:SetLabel(ready and L["Choose a card"] or string.format(L["Again in %s"], ns.Duration(TL:Left("order"))))
		CuratorOctoFull.SetEnabled(od.btn, ready)
	else
		od.text:SetText("")
	end
	-- the Pawnbroker
	local pw = co.pw
	local hasP = TL:Has("pawn")
	local pawns = hasP and RV:Pawns() or {}
	CuratorOctoFull.SetShown(pw.none, not hasP or CuratorOctoFull.Length(pawns) == 0)
	pw.none:SetText(not hasP and L["A talent of the Smuggler, at the ninth tier of his tree."] or L["No copy sold in the last 3 days."])
	pw.text:SetText(hasP and L["Your copies sold in the last 3 days: bought back at what he paid."] or "")
	local now = (GetServerTime and CuratorOctoFull.ServerTime()) or time()
	for i, r in ipairs(pw.rows) do
		-- (the last ones first)
		local at = CuratorOctoFull.Length(pawns) - i + 1
		local x = pawns[at]
		r.at = at
		CuratorOctoFull.SetShown(r, x ~= nil)
		if x then
			local c = ns.Cards[x.k]
			local rr = ns.RARITY[c.rarity].text
			local fin = (x.f == "shiny" or x.f == "holo") and (" · " .. C:FinishName(c, x.f)) or ""
			r.name:SetText(C:Name(c) .. fin)
			r.name:SetTextColor(rr[1], rr[2], rr[3])
			local armed = r.armed and GetTime() - r.armed < ARM
			r.sub:SetText(armed and L["Click again to confirm."] or string.format(L["%s · %s left"], RB.Text(x.p, 11), ns.Duration(RV.PAWN_TIME - (now - (tonumber(x.t) or 0)))))
		end
	end
end

function RUI:PaintPicking()
	local pk = self.frame.counter.pick
	local list, by = self:OrderAlbums()
	local s = self.pickAlbum
	local ok = false
	for _, x in ipairs(list) do
		ok = ok or x == s
	end
	if not ok then
		s = list[1]
		self.pickAlbum = s
	end
	CuratorOctoFull.SetEnabled(pk.prev, CuratorOctoFull.Length(list) > 1)
	CuratorOctoFull.SetEnabled(pk.next, CuratorOctoFull.Length(list) > 1)
	CuratorOctoFull.SetShown(pk.empty, s == nil)
	pk.empty:SetText(L["No card you are missing in the albums he sells."])
	local cards = s and by[s] or {}
	local per = PICK_ROWS * PICK_COLS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(cards) / per))
	self.pickPage = math.max(1, math.min(pages, self.pickPage or 1))
	pk.album:SetText(s and (C:SeriesName(s) .. "  |cff9d9d9d" .. string.format(L["(%d cards you are missing)"], CuratorOctoFull.Length(cards)) .. "|r") or "")
	pk.page:SetText(string.format(L["Page %d / %d"], self.pickPage, pages))
	CuratorOctoFull.SetShown(pk.page, pages > 1)
	CuratorOctoFull.SetShown(pk.pprev, pages > 1)
	CuratorOctoFull.SetShown(pk.pnext, pages > 1)
	CuratorOctoFull.SetEnabled(pk.pprev, self.pickPage > 1)
	CuratorOctoFull.SetEnabled(pk.pnext, self.pickPage < pages)
	local TL = ns.Talents
	for i, r in ipairs(pk.rows) do
		local card = cards[(self.pickPage - 1) * per + i]
		if r.card ~= card then
			r.armed = nil
		end
		r.card = card
		CuratorOctoFull.SetShown(r, card ~= nil)
		if card then
			r.gem:SetTexture(ns.MEDIA .. "Gem" .. card.rarity)
			local rr = ns.RARITY[card.rarity].text
			r.name:SetText(C:Name(card))
			r.name:SetTextColor(rr[1], rr[2], rr[3])
			local armed = r.armed and GetTime() - r.armed < ARM
			local price = TL:OrderPrice(card)
			r.price:SetText(armed and ("|cff4dff4d" .. L["Confirm"] .. "|r") or RB.Text(price, 11))
			CuratorOctoFull.SetShown(r.shade, CuratorOctoFull.Mod(i , 2) == 1)
		end
	end
end

function RUI:OrderClick(r)
	local TL = ns.Talents
	local card = r and r.card
	if not (TL and card) or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	local ok, why = TL:CanOrder(card)
	if not ok then
		ns.Play(ns.SND.close)
		if why == "rubies" then
			ns.Print(L["Special Order: not enough rubies for %s (%s)."], C:Name(card), RB.Text(TL:OrderPrice(card)))
		end
		return
	end
	if not (r.armed and GetTime() - r.armed < ARM) then
		for _, o in ipairs(self.frame.counter.pick.rows) do
			o.armed = nil
		end
		r.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintPicking()
		return
	end
	r.armed = nil
	local done, price = TL:Order(card)
	if not done then
		ns.Play(ns.SND.close)
		self:PaintCounter()
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.reveal[card.rarity] or ns.SND.shiny)
	ns.Print(L["Special Order: %s, for %s."], C:Name(card), RB.Text(price or 0))
	self.picking = nil
	self:Paint()
	Hud.Burst(self.frame.counter.od, ns.RARITY[card.rarity].glow, 26, 140, 18)
end

function RUI:BlackMarketClick()
	local TL = ns.Talents
	if not TL or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	local co = self.frame.counter
	local card = TL:BlackMarket()
	if not card then
		-- (he brings it out)
		local got, why = TL:OpenBlackMarket()
		if not got then
			ns.Play(ns.SND.close)
			if why == "none" then
				ns.Print(L["Black Market: the reseller has nothing you are missing under his counter."])
			end
			self:PaintCounter()
			return
		end
		ns.Play(ns.SND.packOpen)
		Hud.Burst(co.bm, ns.RARITY[got.rarity].glow, 22, 120, 16)
		self:PaintCounter()
		return
	end
	if not (self.bmArmed and GetTime() - self.bmArmed < ARM) then
		self.bmArmed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintCounter()
		return
	end
	self.bmArmed = nil
	local done, bought, price = TL:BuyBlackMarket()
	if not done then
		ns.Play(ns.SND.close)
		self:PaintCounter()
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.reveal[bought.rarity] or ns.SND.shiny)
	Hud.Burst(co.bm, ns.RARITY[bought.rarity].glow, 30, 140, 18)
	ns.Print(L["Black Market: %s, for %s."], C:Name(bought), RB.Text(price or 0))
	self:Paint()
end

function RUI:PawnTooltip(r)
	local x = RV:Pawns()[r.at or 0]
	local card = x and ns.Cards[x.k]
	if not card then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	ns.Booster:CardTooltip(card, x.f)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(string.format(L["Buy it back: %s"], RB.Text(x.p, 13)), 1, 0.82, 0.25)
	GameTooltip:AddLine(r.armed and GetTime() - r.armed < ARM and L["Click again to confirm."] or L["Click, then click again to confirm."], 0.3, 1, 0.3)
	GameTooltip:Show()
end

function RUI:BuyBackClick(r)
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local x = RV:Pawns()[r.at or 0]
	if not x then
		return
	end
	if not RB:Has(x.p) then
		ns.Play(ns.SND.close)
		return
	end
	if not (r.armed and GetTime() - r.armed < ARM) then
		r.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintCounter()
		self:PawnTooltip(r)
		return
	end
	r.armed = nil
	local done, card = RV:BuyBack(r.at)
	if not done then
		ns.Play(ns.SND.close)
		self:PaintCounter()
		return
	end
	GameTooltip:Hide()
	ns.Play(ns.SND.coins)
	ns.Print(L["Pawnbroker: %s, bought back."], C:Name(card))
	self:Paint()
end
