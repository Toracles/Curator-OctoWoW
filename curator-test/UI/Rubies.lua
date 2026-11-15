local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local RB = ns.Rubies
local LV = ns.Level

-------------------------------------------------------------------------------
-- (1.11.0) The rubies on the screen (Rubies.lua): the purse of the album (in its title bar, on every page
-- of my collection: how many, counted up or down as they come and go, a "+60" rising from it), what it
-- says under the mouse, the tags of the rewards (the gem and a number), the shop of the boosters to choose
-- (the page of the boosters) and /curator rubies in the chat.
-------------------------------------------------------------------------------
local RUI = {}
ns.RubiesUI = RUI

RUI.TEXT = { 1, 0.64, 0.68 }  -- the colour of their numbers
RUI.GLOW = { 1, 0.25, 0.32 }  -- the colour of their light
local GOLD = S.GOLD
local DIM = { 0.75, 0.75, 0.78 }

-- A tag of rubies: the gem, a number after it ("+60"). tag:SetAmount(n, sign) sets it and its width.
function RUI.Tag(parent, size, fontSize, layer)
	local t = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(t, size, size)
	t.size = size
	t.gem = t:CreateTexture(nil, layer or "ARTWORK")
	t.gem:SetTexture(RB.ICON)
	CuratorOctoFull.SetSize(t.gem, size, size)
	t.gem:SetPoint("LEFT")
	t.text = Hud.Text(t, fontSize or 12, "OUTLINE")
	t.text:SetPoint("LEFT", t.gem, "RIGHT", 1, 0)
	t.text:SetTextColor(RUI.TEXT[1], RUI.TEXT[2], RUI.TEXT[3])
	function t:SetAmount(n, sign)
		self.text:SetText((sign and "+" or "") .. ns.Num(n))
		self:SetWidth(self.size + 1 + ns.TextWidth(self.text))
	end
	return t
end

-------------------------------------------------------------------------------
-- The purse of the album
-------------------------------------------------------------------------------
function A:BuildWallet(f)
	if not f or f.wallet then
		return
	end
	local w = CreateFrame("Button", nil, f)
	CuratorOctoFull.SetSize(w, 80, 20)
	-- (over the title bar of the window: the pieces of its template stand at 500 and more in the game, its
	-- close button among them)
	local close = f.CloseButton
	w:SetFrameLevel(math.max(f:GetFrameLevel() + 520, close and (close:GetFrameLevel() + 2) or 0))
	if close then
		w:SetPoint("RIGHT", close, "LEFT", -4, 0)
	else
		w:SetPoint("TOPRIGHT", f, "TOPRIGHT", -34, -3)
	end
	-- a pill of dark wine, edged in ruby, so that it reads at a glance
	w.edge = w:CreateTexture(nil, "BACKGROUND", nil, -2)
	w.edge:SetPoint("TOPLEFT", -1, 1)
	w.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(w.edge, 0.85, 0.28, 0.34, 0.7)
	w.bg = w:CreateTexture(nil, "BACKGROUND", nil, -1)
	w.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(w.bg, 0.1, 0.02, 0.04, 0.94)
	w.hl = w:CreateTexture(nil, "HIGHLIGHT")
	w.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(w.hl, 1, 0.45, 0.5, 0.16)
	w.glow = w:CreateTexture(nil, "BACKGROUND", nil, 1)
	w.glow:SetTexture(ns.MEDIA .. "Glow")
	w.glow:SetBlendMode("ADD")
	w.glow:SetVertexColor(RUI.GLOW[1], RUI.GLOW[2], RUI.GLOW[3])
	CuratorOctoFull.SetSize(w.glow, 46, 46)
	w.glow:SetAlpha(0)
	w.text = Hud.Text(w, 14, "OUTLINE")
	w.text:SetPoint("RIGHT", w, "RIGHT", -7, 0)
	w.text:SetTextColor(1, 0.92, 0.92)
	w.gem = w:CreateTexture(nil, "ARTWORK")
	w.gem:SetTexture(RB.ICON)
	CuratorOctoFull.SetSize(w.gem, 18, 18)
	w.gem:SetPoint("RIGHT", w.text, "LEFT", -4, 0)
	w.glow:SetPoint("CENTER", w.gem, "CENTER")
	-- (what came or went, rising from it)
	w.float = Hud.Text(w, 13, "OUTLINE")
	w.float:SetPoint("TOP", w.gem, "BOTTOM", 0, -2)
	w.float:SetAlpha(0)
	CuratorOctoFull.SetScript(w, "OnEnter", function(self)
		RUI:WalletTooltip(self)
	end)
	CuratorOctoFull.SetScript(w, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(w, "OnClick", function()
		ns.Play(ns.SND.click)
		GameTooltip:Hide()
		A:ShowBoosters()
		RUI:OpenShop()
	end)
	f.wallet = w
	RUI.wallet = w
	RUI.shown = RB:Balance()
	RUI:PaintWallet()
end

-- The purse: its number (while it counts, the one it is at), its width; hidden on another player's collection.
function RUI:PaintWallet(value)
	local w = self.wallet
	if not w then
		return
	end
	CuratorOctoFull.SetShown(w, ns.db ~= nil and not A.member)
	if value == nil then
		if self.countTw then
			value = self.counting or RB:Balance()
		else
			value = RB:Balance()
			self.shown = value
		end
	end
	w.text:SetText(ns.Num(value))
	w:SetWidth(6 + 18 + 4 + ns.TextWidth(w.text) + 7)
end

-- Rubies came (n > 0) or went (n < 0): the purse counts to its new number, its gem lights up, "+60" rises.
function RUI:Changed(n, why)
	local w = self.wallet
	local target = RB:Balance()
	if not (w and w:IsVisible()) then
		self.shown = target
		self:PaintWallet()
		return
	end
	-- (rewards flying to it: it counts once they land)
	local delay = (A.questBusy and n > 0 and why ~= "pack") and 0.62 or 0
	local from = (self.countTw and self.counting) or self.shown or (target - n)
	self.shown = target
	if self.countTw then
		ns.CancelTween(self.countTw)
	end
	self.counting = from
	self.countTw = ns.Tween(0.6, function(e)
		RUI.counting = math.floor(from + (target - from) * e + 0.5)
		RUI:PaintWallet(RUI.counting)
	end, function()
		RUI.countTw, RUI.counting = nil, nil
		RUI:PaintWallet()
	end, Ease.outCubic, RUI, delay)
	ns.Delay(delay, function()
		if n > 0 and not A.questBusy then
			ns.Play(ns.SND.coins)
		end
		w.float:SetText((n > 0 and "+" or "-") .. ns.Num(math.abs(n)))
		if n > 0 then
			w.float:SetTextColor(0.55, 1, 0.55)
		else
			w.float:SetTextColor(1, 0.45, 0.45)
		end
		ns.Tween(1.3, function(e, raw)
			w.float:ClearAllPoints()
			w.float:SetPoint("TOP", w.gem, "BOTTOM", 0, -2 - 16 * e)
			w.float:SetAlpha(raw < 0.15 and raw / 0.15 or (1 - (raw - 0.15) / 0.85))
			w.glow:SetAlpha(0.9 * (1 - raw))
			local k = 1 + 0.35 * math.sin(math.pi * math.min(1, raw * 2.5))
			CuratorOctoFull.SetSize(w.gem, 18 * k, 18 * k)
		end, function()
			w.float:SetAlpha(0)
			w.glow:SetAlpha(0)
			CuratorOctoFull.SetSize(w.gem, 18, 18)
		end, Ease.outQuad, RUI)
	end, RUI)
end

-- What the purse says under the mouse: how many, where they come from, what they buy.
function RUI:WalletTooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
	GameTooltip:AddDoubleLine(L["Rubies"], RB.Text(RB:Balance(), 16), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
	GameTooltip:AddLine(L["Earned with your quests, your achievements, your collector levels, the copies you sell to the reseller and your talents."], 0.85, 0.85, 0.85, true)
	-- (1.14.0, his word: the quests of the game turned in)
	GameTooltip:AddLine(self:TurnInLine(), 0.85, 0.85, 0.85, true)
	-- (1.13.0, after its second test: the guard of the week; 1.14.0: and the one of the quests of the game)
	GameTooltip:AddLine(self:GuardLine(), 1, 0.82, 0.45, true)
	GameTooltip:AddLine(self:GuardLine("turnin"), 1, 0.82, 0.45, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["What they buy:"], GOLD[1], GOLD[2], GOLD[3])
	for _, line in ipairs(self:Uses()) do
		GameTooltip:AddLine(line, 1, 1, 1, true)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Click: the ruby counter (the ledger)"], 0.3, 1, 0.3)
	GameTooltip:Show()
end

-- (1.13.0, after its second test) The guard of the week, in a line: what the reseller and the talents still pay in full,
-- or that they pay a quarter until the weekly reset (Rubies.lua: RB.GUARD). (1.14.0) pool "turnin": the guard of the
-- quests of the game turned in.
function RUI:GuardLine(pool)
	local left = RB.GuardLeft and RB:GuardLeft(pool) or 0
	if pool == "turnin" then
		if left > 0 then
			return string.format(L["This week, the quests of the game still pay %s in full, then a quarter."], RB.Text(left, 12))
		end
		return string.format(L["This week, the quests of the game pay a quarter: the %s paid in full are reached (until Wednesday, 5:00 in Paris)."], RB.Text(RB:GuardMax(pool), 12))
	end
	if left > 0 then
		return string.format(L["This week, the reseller and your talents still pay %s in full, then a quarter."], RB.Text(left, 12))
	end
	return string.format(L["This week, the reseller and your talents pay a quarter: the %s paid in full are reached (until Wednesday, 5:00 in Paris)."], RB.Text(RB:GuardMax(), 12))
end

-- (1.14.0, his word) What a quest of the game turned in gives, in a line (Rubies.lua: RB:OfTurnIn).
function RUI:TurnInLine()
	return string.format(L["Each quest of the game you turn in: %d to %d rubies, after the money it gives (once a quest and a character)."], RB.TURNIN_MIN or 1, RB.TURNIN_MAX or 50)
end

-- What the rubies buy, one line each.
function RUI:Uses()
	local TL, Q, T = ns.Talents, ns.Quests, ns.Tavern
	local out = {}
	-- (1.14.0, his word: the boosters to choose sold no more)
	if Q and Q.REROLL_K then
		-- (the least a quest costs: one of the day, twice its rubies)
		local least
		for _, board in ipairs(Q.BOARDS or {}) do
			local r = tonumber(board.rubies) or 0
			if r > 0 and (not least or r < least) then
				least = r
			end
		end
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["The quests of a page changed for others (the Quests tab): from %s a quest"], RB.Text(Q.REROLL_K * (least or 10), 12))
	end
	if T and T.RUMOR_PRICE then
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["A rumor about the card you choose, at an innkeeper: %s"], RB.Text(T.RumorPrice and T:RumorPrice() or T.RUMOR_PRICE, 12))
	end
	if ns.Expertise then
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["The expertise of a card, at a banker: from %s"], RB.Text(ns.Expertise:From(), 12))
	end
	-- (1.12.0: the corrupted cards, at the masters of the classes)
	if ns.Masters then
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["The seal of a corrupted card, at a Master of Warlocks: from %s"], RB.Text(ns.Masters:SealPrice({ rarity = 1 }), 12))
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["The purification of a corrupted card, at a Master of Priests: from %s"], RB.Text(ns.Masters:PurifyPrice({ rarity = 1 }, 1), 12))
	end
	-- (1.13.0: a copy restored, at an enchanter)
	if ns.Restore then
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["The restoration of a copy, at an enchanter: from %s"], RB.Text(ns.Restore:From(), 12))
	end
	-- (1.12.0: the reseller, at the vendors of general goods, in the place of the antiquarian)
	if ns.Reseller then
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["Cards of every album, at the reseller (a vendor of general goods or of trade supplies): from %s"], RB.Text(ns.Reseller:Price({ rarity = 1 }), 12))
	end
	-- (1.13.0: the displays of 16 boosters, at the reseller; the protective cases, at a banker: Displays.lua)
	if ns.Displays then
		local DS = ns.Displays
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["A display of 16 boosters, at the reseller: %s (a limited edition: %s)"], RB.Text(DS:Price({}), 12),
			RB.Text(DS:Price({ event = true }), 12))
		out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["A protective case, at a banker: %s for a booster, %s for a display"], RB.Text(DS:CasePrice("pack"), 12),
			RB.Text(DS:CasePrice("display"), 12))
	end
	if TL and TL.RespecCost then
		-- (1.12.0: the one offered, once)
		if TL.FreeRespec and TL:FreeRespec() then
			out[CuratorOctoFull.Length(out) + 1] = "· " .. L["A reconversion contract (the Talents tab): offered once with 1.12.0"]
		else
			out[CuratorOctoFull.Length(out) + 1] = "· " .. string.format(L["A reconversion contract (the Talents tab): %s"], RB.Text(TL:RespecCost(), 12))
		end
	end
	return out
end

-- /curator rubies: in the chat.
function RUI:Tell()
	ns.Print(L["Rubies: %s."], RB.Text(RB:Balance()))
	-- (1.13.0, after its second test: the rubies of the quests as their boards have them, the guard of the week)
	local Q = ns.Quests
	local function Of(key)
		local b = Q and Q.byKey and Q.byKey[key]
		return b and b.rubies or 0
	end
	ns.Print(L["They come from your quests (%s for a quest of the day, %s of the week, %s of the month), your achievements (%s for each point), your collector levels (%s, %s more for a new rank) and the golden quests (%s)."],
		ns.Num(Of("daily")), ns.Num(Of("weekly")), ns.Num(Of("monthly")), ns.Num(RB.PER_POINT), ns.Num(RB.PER_LEVEL), ns.Num(RB.PER_RANK), ns.Num(RB.GOLDEN))
	-- (1.14.0, his word: the quests of the game turned in, their guard)
	ns.Print(self:TurnInLine())
	ns.Print(self:GuardLine())
	ns.Print(self:GuardLine("turnin"))
	for _, line in ipairs(self:Uses()) do
		ns.Print(line)
	end
end

-------------------------------------------------------------------------------
-- The counter of the rubies (the purse, the page of the boosters): its shop of boosters to choose (a booster
-- of a zone, of a dungeon or of a raid, RB:PackWeek() of them a week) and the ledger (the last comings and
-- goings). (1.12.0: the antiquarian of 1.11.0 gone, the reseller at the vendors of general goods: UI/Reseller.lua)
-------------------------------------------------------------------------------
local SHOP_W, SHOP_H, ROW_H = 400, 392, 44
local LIST_TOP = -134
local KIND_NAME = { zone = "A booster of a zone", dungeon = "A booster of a dungeon", raid = "A booster of a raid" }
local WHY = {
	week = "Your boosters of the week are bought: more after the weekly reset (Wednesday, 5:00 in Paris).",
	album = "No album can get one yet: it waits for the first boosters of its kind (a dungeon or a raid: once you have been there).",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
}
-- the tabs of the counter
-- (1.14.0, his word: the boosters to choose sold no more, the counter keeps its ledger)
local TABS = {
	{ key = "ledger", label = "Ledger", icon = { "Interface\\Icons\\INV_Misc_Note_01" } },
}
local LEDGER_ROWS = 11
-- what the rubies of a line of the ledger came from, or bought
local LEDGER = {
	quest = "A quest", auto = "Quests ended", ach = "An achievement", level = "A collector level", golden = "A golden quest",
	back = "What you did before the rubies", talent = "A talent", respec = "A reconversion contract", reroll = "Quests changed",
	swap = "Quests changed", rumor = "A rumor", pack = "A booster to choose", expertise = "An appraisal", antique = "The antiquarian",
	-- (1.12.0: a card of the reseller, a copy sold to him: Reseller.lua)
	resell = "The reseller", resold = "Sold to the reseller",
	-- (1.12.0: a gift code of the author, Gifts.lua; a corrupted card sealed, or purified: Seal.lua)
	gift = "A gift code", seal = "A seal of a warlock", purify = "A purification",
	-- (1.13.0: a copy restored at an enchanter, Restore.lua)
	restore = "A restoration",
	-- (1.14.0: the round of an innkeeper, a lead followed to its card: Tavern.lua; his word: a quest of the game turned in,
	-- Rewards.lua)
	round = "The round of an innkeeper", turnin = "A quest turned in",
	-- (1.13.0: a display of the reseller, a protective case at a banker: Displays.lua)
	display = "A display of the reseller", case = "A protective case",
	-- (1.14.0: a key of a case, Cases.lua)
	casekey = "A key of a case",
	-- (1 November: a certificate of a master of the mages, Mages.lua)
	certify = "A certificate of the mages",
	-- (the author's gifts to himself, his build: UI/Admin.lua)
	admin = "The author's tools",
}

local function Panel(f)
	local p = CreateFrame("Frame", nil, f)
	p:SetPoint("TOPLEFT", 16, LIST_TOP + 32)
	p:SetPoint("BOTTOMRIGHT", -16, 12)
	p:Hide()
	return p
end

function RUI:Shop()
	if self.shop then
		return self.shop
	end
	local f = CreateFrame("Frame", "CuratorRubyShop", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, SHOP_W, SHOP_H)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	CuratorOctoFull.SetScript(f, "OnDragStart", f.StartMoving)
	CuratorOctoFull.SetScript(f, "OnDragStop", f.StopMovingOrSizing)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorRubyShop")
	if f.SetBackdrop then
		f:SetBackdrop({
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
	end
	local background = f:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    background:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
    CuratorOctoFull.ColorTexture(background, 0.025, 0.027, 0.035, 1)
	f.gem = f:CreateTexture(nil, "ARTWORK")
	f.gem:SetTexture(RB.ICON)
	CuratorOctoFull.SetSize(f.gem, 24, 24)
	f.gem:SetPoint("TOPLEFT", 16, -13)
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("LEFT", f.gem, "RIGHT", 6, 0)
	f.title:SetText(L["The ruby counter"])
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -4, -4)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		f:Hide()
	end)
	f.have = S.Text(f, "GameFontHighlight", "RIGHT")
	f.have:SetPoint("TOPRIGHT", -36, -18)
	-- the tabs
	f.tabs = {}
	local tw = (SHOP_W - 32 - 2 * 6) / CuratorOctoFull.Length(TABS)
	for i, t in ipairs(TABS) do
		local i, t = i, t; local b = Hud.NavButton(f, tw, 26)
		b:SetPoint("TOPLEFT", 16 + (i - 1) * (tw + 6), -42)
		Hud.SetIcon(b.icon, t.icon)
		b.key = t.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			if RUI.tab ~= t.key then
				ns.Play(ns.SND.page)
				RUI:ShopTab(t.key)
			end
		end)
		f.tabs[i] = b
	end
	f.week = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.week:SetPoint("TOPLEFT", 18, -76)
	f.week:SetWidth(SHOP_W - 36)
	CuratorOctoFull.SetWordWrap(f.week, true)

	-- the boosters to choose
	local pk = Panel(f)
	f.packs = pk
	f.rows = {}
	for i, kind in ipairs(LV.KINDS) do
		local i, kind = i, kind; local r = CreateFrame("Frame", nil, pk)
		CuratorOctoFull.SetSize(r, SHOP_W - 32, ROW_H - 4)
		r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
		r.bg = r:CreateTexture(nil, "BACKGROUND")
		r.bg:SetAllPoints()
		CuratorOctoFull.ColorTexture(r.bg, 1, 1, 1, 0.04)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		r.icon:SetTexture(Hud.PackIcon(kind))
		CuratorOctoFull.SetSize(r.icon, 34, 34)
		r.icon:SetPoint("LEFT", 4, 0)
		r.name = S.Text(r, "GameFontHighlight", "LEFT")
		r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -2)
		r.name:SetWidth(SHOP_W - 32 - 46 - 96)
		CuratorOctoFull.SetWordWrap(r.name, false)
		r.price = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.price:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
		r.buy = S.Button(r, L["Buy"], 84, 22)
		r.buy:SetPoint("RIGHT", -4, 0)
		r.buy.kind = kind
		CuratorOctoFull.SetScript(r.buy, "OnClick", function(self)
			RUI:Buy(self.kind)
		end)
		if r.buy.SetMotionScriptsWhileDisabled then
			CuratorOctoFull.SetMotionScriptsWhileDisabled(r.buy, true)
		end
		CuratorOctoFull.SetScript(r.buy, "OnEnter", function(self)
			RUI:ShopTooltip(self)
		end)
		CuratorOctoFull.SetScript(r.buy, "OnLeave", function()
			GameTooltip:Hide()
		end)
		r.kind = kind
		f.rows[i] = r
	end
	f.note = S.Text(pk, "GameFontHighlightSmall", "LEFT")
	f.note:SetPoint("BOTTOMLEFT", 2, 4)
	f.note:SetWidth(SHOP_W - 36)
	CuratorOctoFull.SetWordWrap(f.note, true)
	f.note:SetTextColor(DIM[1], DIM[2], DIM[3])
	f.note:SetText(L["They wait with your boosters to choose: put them in the album you want."])

	-- the ledger
	local lg = Panel(f)
	f.ledger = lg
	lg.rows = {}
	for i = 1, LEDGER_ROWS do
		local r = CreateFrame("Frame", nil, lg)
		CuratorOctoFull.SetSize(r, SHOP_W - 32, 20)
		r:SetPoint("TOPLEFT", 0, -(i - 1) * 21)
		if CuratorOctoFull.Mod(i , 2) == 1 then
			r.bg = r:CreateTexture(nil, "BACKGROUND")
			r.bg:SetAllPoints()
			CuratorOctoFull.ColorTexture(r.bg, 1, 1, 1, 0.035)
		end
		r.n = S.Text(r, "GameFontHighlight", "RIGHT")
		r.n:SetPoint("LEFT", 4, 0)
		r.n:SetWidth(66)
		r.what = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.what:SetPoint("LEFT", 82, 0)
		r.what:SetWidth(SHOP_W - 32 - 82 - 96)
		CuratorOctoFull.SetWordWrap(r.what, false)
		r.when = S.Text(r, "GameFontDisableSmall", "RIGHT")
		r.when:SetPoint("RIGHT", -4, 0)
		lg.rows[i] = r
	end
	lg.empty = S.Text(lg, "GameFontHighlight")
	lg.empty:SetPoint("TOP", 0, -40)
	lg.empty:SetTextColor(DIM[1], DIM[2], DIM[3])
	lg.empty:SetText(L["Nothing yet."])
	self.shop = f
	return f
end

-- A tab of the counter shown.
function RUI:ShopTab(key)
	local f = self:Shop()
	-- (1.14.0: the ledger only, Rubies.lua: RB.PACKS_SOLD)
	self.tab = RB.PACKS_SOLD and (key or self.tab or "packs") or "ledger"
	if self.tab ~= "packs" and self.tab ~= "ledger" then
		self.tab = "ledger"
	end
	CuratorOctoFull.SetShown(f.packs, self.tab == "packs")
	CuratorOctoFull.SetShown(f.ledger, self.tab == "ledger")
	self:PaintShop()
end

function RUI:PaintShop()
	local f = self.shop
	if not (f and f:IsShown()) then
		return
	end
	local tab = self.tab or "ledger"
	f.have:SetText(RB.Text(RB:Balance(), 15))
	for i, b in ipairs(f.tabs) do
		b:Paint(b.key == tab, L[TABS[i].label], "", 0)
	end
	if tab == "packs" then
		-- (1.14.0, after its test, his word: a reroll buys none, why under them)
		local rr = ns.Reroll ~= nil and ns.Reroll:Blocks("choice")
		f.note:SetText(rr and ns.Reroll:WhyNot("choice") or L["They wait with your boosters to choose: put them in the album you want."])
		if rr then
			f.note:SetTextColor(1, 0.62, 0.45)
		else
			f.note:SetTextColor(DIM[1], DIM[2], DIM[3])
		end
		f.week:SetText(string.format(L["This week: %d of %d"], RB:PacksThisWeek(), RB:PackWeek()))
		f.week:SetTextColor(RB:PacksLeft() > 0 and 0.85 or 1, RB:PacksLeft() > 0 and 0.85 or 0.5, RB:PacksLeft() > 0 and 0.85 or 0.4)
		for _, r in ipairs(f.rows) do
			local ok, why = RB:CanBuyPack(r.kind)
			local price = RB:PackPrice(r.kind) or 0
			r.name:SetText(L[KIND_NAME[r.kind]])
			r.price:SetText(price > 0 and RB.Text(price, 13) or ("|cff60ff60" .. L["Free"] .. "|r"))
			CuratorOctoFull.SetEnabled(r.buy, ok)
			r.buy.why = why
			CuratorOctoFull.SetDesaturated(r.icon, not ok)
			r.name:SetTextColor(ok and 1 or 0.6, ok and 1 or 0.6, ok and 1 or 0.6)
		end
	else
		self:PaintLedger()
	end
end

-- The ledger: the last comings and goings, the latest first.
function RUI:PaintLedger()
	local f = self.shop
	local lg = f.ledger
	local log = RB:Ledger()
	local st = ns.Stats()
	f.week:SetText(string.format(L["Earned in all: %s · Spent: %s"], RB.Text(tonumber(st.rubyEarned) or 0, 12), RB.Text(tonumber(st.rubySpent) or 0, 12)))
	f.week:SetTextColor(0.85, 0.85, 0.85)
	local now = CuratorOctoFull.ServerTime()
	for i, r in ipairs(lg.rows) do
		local e = log[CuratorOctoFull.Length(log) - i + 1]
		CuratorOctoFull.SetShown(r, e ~= nil)
		if e then
			local n = tonumber(e.n) or 0
			r.n:SetText((n >= 0 and "+" or "-") .. ns.Num(math.abs(n)))
			if n >= 0 then
				r.n:SetTextColor(0.5, 1, 0.5)
			else
				r.n:SetTextColor(1, 0.5, 0.48)
			end
			-- (the rubies of a talent: its name)
			local tid = type(e.w) == "string" and CuratorOctoFull.Match(e.w, "^t:(.+)$")
			if tid and ns.Talents and ns.Talents.BY[tid] then
				r.what:SetText(ns.Talents:Name(tid))
			else
				r.what:SetText(L[LEDGER[e.w or ""] or "Rubies"])
			end
			local timestamp = tonumber(e.t)
            local ago = CuratorOctoFull.IsCalendarTime(timestamp) and math.max(0, now - timestamp)
            r.when:SetText(ago and (ago < 60 and L["now"] or string.format(L["%s ago"], ns.Duration(ago))) or "—")
		end
	end
	CuratorOctoFull.SetShown(lg.empty, CuratorOctoFull.Length(log) == 0)
end

-- The counter, beside the button that opens it (or the purse): opened at a tab (the boosters by default), or
-- closed when it was.
function RUI:OpenShop(anchor, tab)
	local f = self:Shop()
	if f:IsShown() and anchor and f.anchor == anchor and (not tab or tab == self.tab) then
		f:Hide()
		return
	end
	f.anchor = anchor
	f:ClearAllPoints()
	if anchor then
		f:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 6, 6)
	elseif A.frame and A.frame:IsShown() then
		f:SetPoint("TOPRIGHT", A.frame, "TOPRIGHT", -24, -30)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
	end
	f:Show()
	ns.Play(ns.SND.open)
	self:ShopTab(tab or "ledger")
end

function RUI:ShopTooltip(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L[KIND_NAME[b.kind]], 1, 1, 1)
	local price = RB:PackPrice(b.kind) or 0
	GameTooltip:AddLine(price > 0 and RB.Text(price, 14) or L["Free"], 1, 1, 1)
	-- (1.14.0, after its test, his word: a reroll buys none, why: Reroll.lua)
	if b.why == "reroll" and ns.Reroll then
		GameTooltip:AddLine(ns.Reroll:WhyNot("choice"), 1, 0.45, 0.4, true)
	elseif b.why and WHY[b.why] then
		GameTooltip:AddLine(L[WHY[b.why]], 1, 0.45, 0.4, true)
	else
		GameTooltip:AddLine(L["It waits with your boosters to choose: put it in the album you want."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:Show()
end

function RUI:Buy(kind)
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local ok, why = RB:BuyPack(kind)
	local price = why
	if not ok then
		if why == "reroll" and ns.Reroll then
			ns.Reroll:SayNot("choice")
		else
			ns.Play(ns.SND.close)
			if why and WHY[why] then
				ns.Print(L[WHY[why]])
			end
		end
		self:PaintShop()
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.place)
	ns.Print(L["Bought: %s, for %s. It waits with your boosters to choose."], A:PackReward(kind, 1), RB.Text(price or 0))
	local f = self.shop
	for _, r in ipairs(f.rows) do
		if r.kind == kind then
			Hud.Burst(r.icon, RUI.GLOW, 12, 90, 14)
		end
	end
	self:PaintShop()
end

-------------------------------------------------------------------------------
-- Into the album: the purse built with it, painted with its tabs
-------------------------------------------------------------------------------
do
	local build = A.Build
	function A:Build(...)
		local r = build(self, unpack(arg, 1, arg.n))
		if self.frame then
			self:BuildWallet(self.frame)
		end
		return r
	end
	local paintTabs = A.PaintTabs
	function A:PaintTabs(...)
		local r = paintTabs(self, unpack(arg, 1, arg.n))
		RUI:PaintWallet()
		return r
	end
end

ns.On("RUBIES_CHANGED", function(n, why)
	RUI:Changed(n or 0, why)
	RUI:PaintShop()
	-- (rubies earned while the album is closed: a line in the chat; the catch-up says its own. 1.14.2: never while a case
	-- is being opened, UI/Crate.lua: the rubies of a talent would tell what came out of it before its band stops)
	local CR = ns.CrateUI
	if (n or 0) > 0 and why ~= "back" and why ~= "auto" and not (A.frame and A.frame:IsShown()) and not (ns.db and ns.db.rubyChat == false)
		and not (CR and CR.Hiding and CR:Hiding()) then
		ns.Print(L["Rubies: +%s (%s in all)."], ns.Num(n), RB.Text(RB:Balance()))
	end
end)

for _, e in ipairs({ "CHOICE_CHANGED", "CLAIMS_CHANGED", "LEVELS_CLAIMED", "CHANGED", "TALENTS_CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		RUI:PaintShop()
	end)
end

-- (the catch-up of 1.11.0: its toast)
ns.On("RUBIES_BACKPAY", function(total)
	if ns.Toast then
		ns.Toast:Push({
			title = L["The rubies are here!"],
			name = RB.Text(total, 16),
			color = { 1, 0.42, 0.48 },
			line = L["For what you already did: your quests, your achievements, your levels."],
			tex = { "Ruby" },
			sound = ns.SND.coins,
			onClick = function()
				ns.Album:ShowBoosters()
				RUI:OpenShop()
			end,
		})
	end
end)
