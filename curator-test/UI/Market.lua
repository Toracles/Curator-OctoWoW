local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin
local MK = ns.Market
local C = ns.Collection
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.14.0) The Bourse Gentepression on the screen (Market.lua): a fourth tab, "Curator", at the bottom of the window of
-- the auction house of the game, in the look of the game (its frame, its fonts, its buttons; the cards drawn as in
-- Curator). Four pages: Buy (the selection of the news of the market: what you lack and your favorites first, the
-- filters, the sorts, a thing alike grouped; its card under the mouse, its sheet on a click: its story, the curve of its
-- price), Sell (everything that can go, a box each, its price held to its bounds, its days and their fee, a barter, an
-- accroche, several at once; the buy orders open for what you have), My sales (in deposit, online, sold, back:
-- withdraw, lower the price, put on sale again), My purchases (on the way, received, refunded; the buy orders). Only at
-- an auctioneer: MK.at, the window of the auction house open. While the website keeps the market closed: "Opening
-- soon". The window of the auction house of a client of another kind: the same page beside it, in a window of its own.
-------------------------------------------------------------------------------
local MUI = { page = "buy", f = {}, sort = "rarity", shown = {} }
ns.MarketUI = MUI

local W, H = 778, 344
local ROWS = 10
local ROW_H = 23
local GOLD, WHITE, DIM = S.GOLD, S.WHITE, { 0.62, 0.62, 0.66 }
local GREEN, RED = { 0.3, 1, 0.3 }, { 1, 0.4, 0.35 }
local ARM = 3 -- (seconds) a first click arms a button that spends, a second one within does it
local SITE = "curator-wow.com/bourse"

-- (a whole number of a record, as the addon keeps them)
local function Int(v)
	return math.max(0, math.floor(tonumber(v) or 0))
end
local PAGES = {
	{ key = "buy", label = "Buy", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
	{ key = "sell", label = "Sell", icon = "Interface\\Icons\\INV_Misc_Note_02" },
	{ key = "mine", label = "My sales", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
	{ key = "bought", label = "My purchases", icon = "Interface\\Icons\\INV_Letter_15" },
}
-- the lines a seller may add under a thing (MK.ACCROCHES of them)
MUI.ACCROCHES = {
	"Collector's piece", "Friendly price", "Quick sale", "To complete your album", "The jewel of my collection",
	"Making room", "Rare on the market", "A bargain", "For a true fan",
}
-- (why a thing cannot be listed or bought, in the words of the player)
local WHY = {
	test = "A test collection never goes to the Exchange.",
	edited = "A save edited outside the game never goes to the Exchange.",
	beta = "Curator is stopped: nothing goes to the Exchange.",
	author = "Your build of the author gives cards: the Exchange is for the players (your test mode: /curator test bourse).",
	guard = "Another addon changed the cards of Curator this session: /reload first.",
	pass = "The Exchange asks for the pass of your collection, as the trades do.",
	app = "No news of the Exchange yet: the Curator app brings them (every quarter of an hour, then /reload).",
	old = "The news of the Exchange are too old: open the Curator app, then reload your interface.",
	closed = "The Exchange is not open yet.",
	away = "You list and buy only at an auctioneer.",
	thing = "This thing cannot go now.",
	price = "A price out of its bounds.",
	asks = "What the barter asks is out of the bounds of the thing.",
	days = "A duration the Exchange does not know.",
	rubies = "Not enough rubies.",
	limit = "Too many listings at once.",
	day = "Enough purchases for today.",
	cap = "Enough displays bought this week.",
	give = "What you give does not answer what the barter asks.",
	gone = "This listing is no longer in the selection.",
	mine = "Your own listing.",
	none = "Nothing to do.",
	locked = "It came in a trade or from the Exchange not long ago: it waits for the end of its quarantine.",
	-- (1.14.0, his word: the boosters and the displays of an album unlocked only, Market.lua: MK:Locked)
	unlock = "Album locked: win one of its boosters by playing first.",
	market = "Bought at the Exchange not long ago: it waits for the end of its quarantine.",
	away2 = "At an enchanter now.",
	signed = "The copy signed by its innkeeper stays.",
	staked = "Put on a duel.",
}
MUI.WHY = WHY

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Text(fs, s)
	fs:SetText(s or "")
end

local function Color(fs, c)
	fs:SetTextColor(c[1], c[2], c[3])
end

local function Rubies(n, size)
	return ns.Rubies.Text(n or 0, size or 12)
end
MUI.Rubies = Rubies

-------------------------------------------------------------------------------
-- What a thing is, in words and in pictures
-------------------------------------------------------------------------------
local FIN = { s = "shiny", h = "holo", c = "corrupt" }
local CRATE_FIN = { t = "thunder", T = "titan" }

-- The entry of a card of a case (its edition, its key: CrateItems.lua).
local function Entry(edition, key)
	local CI = ns.CrateItems
	local c = CI and CI:Case(edition)
	for r = 1, 4 do
		for _, e in ipairs(c and c[r] or {}) do
			if e.key == key then
				return e
			end
		end
	end
	return nil
end
MUI.Entry = Entry

-- The name of a case of an edition.
local function CaseName(edition)
	local def = ns.Crates and ns.Crates[edition]
	return (def and def.title and L[def.title]) or L["A case"]
end

-- The card of the albums of a thing (nil: not a copy of a card).
function MUI.Card(it)
	return it and it.k == "c" and ns.Cards["c" .. it.npc] or nil
end

-- Its name, as the player reads it.
function MUI.Name(it)
	if not it then
		return "?"
	end
	if it.k == "c" then
		local card = MUI.Card(it)
		return card and C:Name(card) or ("#" .. it.npc)
	elseif it.k == "b" then
		local s = ns.SeriesByKey(it.series)
		return string.format(L["Booster: %s"], s and C:SeriesName(s) or it.series)
	elseif it.k == "d" then
		local s = ns.SeriesByKey(it.series)
		return string.format(L["Display: %s"], s and C:SeriesName(s) or it.series)
	elseif it.k == "x" then
		return CaseName(it.edition)
	elseif it.k == "w" then
		if it.weapon then
			local CC = ns.CrateCard
			return (CC and CC.WeaponName and CC.WeaponName({ id = it.weapon.item })) or L["A weapon of legend"]
		end
		local e = Entry(it.edition, it.entry)
		return e and ns.CrateItems:Name(e) or "?"
	end
	return "?"
end

-- The colour of its name: the rarity of a card, the rank of a card of a case; the rest in gold.
function MUI.Color(it)
	if it and it.k == "c" then
		local card = MUI.Card(it)
		local r = card and ns.RARITY[card.rarity]
		return r and r.text or WHITE
	elseif it and it.k == "w" then
		local CR = ns.CrateUI
		local rank = CR and CR.RANKS and CR.RANKS[it.rank]
		return (rank and (rank.text or rank.color)) or WHITE
	end
	return GOLD
end

-- Its icon (a texture).
function MUI.Icon(it)
	if not it then
		return "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	if it.k == "c" then
		local card = MUI.Card(it)
		return MEDIA .. "Gem" .. ((card and card.rarity) or 1)
	elseif it.k == "b" then
		-- (1.14.2: a booster is drawn in two halves, its lower one as its icon, as on the booster bar; s.pack alone
		-- is no file)
		local s = ns.SeriesByKey(it.series)
		return MEDIA .. ((s and s.pack) or "PackElwynn") .. "Bottom"
	elseif it.k == "d" then
		return MEDIA .. "DisplayIcon"
	elseif it.k == "x" then
		return MEDIA .. "CaseIcon"
	elseif it.k == "w" then
		if it.entry then
			local e = Entry(it.edition, it.entry)
			local icon = e and ns.CrateItems:Icon(e)
			if icon then
				return icon
			end
		end
		return MEDIA .. "CrateRank" .. it.rank
	end
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- (1 November) The family and the number of a titanforged copy certified by a master of the mages, in its colour (nil:
-- not certified; case: a card of a case), Mages.lua.
function MUI.Family(it, case)
	local MG = ns.Mages
	if not (MG and it.pt and it.tc) then
		return nil
	end
	return MG.TagOf(it.pt, MG.Unpack(it.tc), case)
end

-- The finish of a thing, in words (nil: none to say).
function MUI.FinishText(it)
	if it.k == "c" and it.f ~= "n" then
		local card = MUI.Card(it)
		return card and C:FinishName(card, FIN[it.f]) or nil
	elseif it.k == "w" and it.f ~= "n" then
		return it.f == "T" and L["Titanforged"] or L["Thunderforged"]
	end
	return nil
end

-- The badges of a thing, true to its story: what the addon tells of it (never written by the seller).
function MUI.Badges(it)
	local out = {}
	if it.k == "c" then
		local card = MUI.Card(it)
		-- (its grade only while its case is closed on it: a restoration opens it, its grade known at its next appraisal)
		if it.g > 0 and it.sl == true then
			out[CuratorOctoFull.Length(out) + 1] = string.format(L["Grade %s"], ns.Expertise.Text(it.g / 100))
		elseif it.g > 0 then
			out[CuratorOctoFull.Length(out) + 1] = L["Case opened"]
		end
		local f = it.f ~= "c" and MUI.FinishText(it)
		if f then
			out[CuratorOctoFull.Length(out) + 1] = f
		end
		-- (1.14.0: a titanforged copy, its pattern, Patterns.lua; 1 November, his word: told by the masters of the mages
		-- only, its family and its number once certified, Mages.lua)
		if it.pt then
			out[CuratorOctoFull.Length(out) + 1] = MUI.Family(it) or L["Not certified"]
		end
		if CuratorOctoFull.Length(it.r) > 0 then
			out[CuratorOctoFull.Length(out) + 1] = L["Restored"]
		end
		if it.f == "c" and not it.seal then
			out[CuratorOctoFull.Length(out) + 1] = string.format(L["Corrupted %d %%"], it.cor)
		end
		if it.seal then
			out[CuratorOctoFull.Length(out) + 1] = string.format(L["Reliquary %s"], ns.Masters.Roman(it.seal.rank))
		end
		local s = card and card.series
		if s and s.key == "hallow" then
			out[CuratorOctoFull.Length(out) + 1] = L["Hallow's End 2026"]
		elseif s and s.limited == "hardcup" then
			out[CuratorOctoFull.Length(out) + 1] = L["Hardcup Saison 3"]
		end
		if it.ow == "f" then
			out[CuratorOctoFull.Length(out) + 1] = L["Found on the creature"]
		end
		if MUI.LaunchWeek(it.ot) then
			out[CuratorOctoFull.Length(out) + 1] = L["Launch week"]
		end
	elseif it.k == "d" and it.cased then
		out[CuratorOctoFull.Length(out) + 1] = L["In its case"]
	elseif it.k == "w" then
		local f = MUI.FinishText(it)
		if f then
			out[CuratorOctoFull.Length(out) + 1] = f
		end
		-- (1.14.0: titanforged, its pattern; 1 November: its family and its number once certified, Mages.lua)
		if it.pt then
			out[CuratorOctoFull.Length(out) + 1] = MUI.Family(it, true) or L["Not certified"]
		end
		-- (31 October, his word: never its condition in words; it shows on the card, its wear)
		if it.ap then
			out[CuratorOctoFull.Length(out) + 1] = it.grade == 10 and L["Grade 10"] or string.format(L["Grade %d"], it.grade)
		end
	end
	return out
end

-- (the week of the release of WoW Forever: from Wednesday 4 November 2026, 5:00 in Paris, seven days)
MUI.LAUNCH = 1793764800
function MUI.LaunchWeek(t)
	t = tonumber(t) or 0
	return t >= MUI.LAUNCH and t < MUI.LAUNCH + 7 * 86400
end

-- Its name with its badges, on one line (most: so many badges at most).
function MUI.Title(it, most)
	local b = MUI.Badges(it)
	if CuratorOctoFull.Length(b) == 0 then
		return MUI.Name(it)
	end
	if most and CuratorOctoFull.Length(b) > most then
		local keep = {}
		for i = 1, most do
			keep[i] = b[i]
		end
		b = keep
	end
	return MUI.Name(it) .. "  ·  " .. table.concat(b, " · ")
end

-- What a barter asks, in words.
function MUI.AskText(a)
	if not a then
		return "?"
	end
	if a.k == "c" then
		local card = ns.Cards["c" .. a.npc]
		local name = card and C:Name(card) or ("#" .. a.npc)
		local f = a.f ~= "n" and card and C:FinishName(card, FIN[a.f]) or nil
		local g = (a.min or 0) > 0 and string.format(L["grade %d or more"], a.min) or nil
		return name .. (f and (" (" .. f .. ")") or "") .. (g and (", " .. g) or "")
	elseif a.k == "b" or a.k == "d" then
		return MUI.Name({ k = a.k, series = a.series, cased = a.cased }) .. ((a.k == "d" and a.cased) and (" (" .. L["In its case"] .. ")") or "")
	end
	return CaseName(a.edition)
end

-- The time left before an end ("2 d 4 h"; "-": none).
function MUI.Left(ends)
	ends = tonumber(ends)
	if not ends or ends <= 0 then
		return "-"
	end
	local left = ends - Now()
	if left <= 0 then
		return L["Ended"]
	end
	return ns.Duration(left)
end

-------------------------------------------------------------------------------
-- Little pieces of the game
-------------------------------------------------------------------------------
-- A box to type in (numeric: digits only), in a dark inset; hint: a grey word while it is empty; onChange(box, byUser)
-- at each change of its text.
local function EditBox(parent, w, numeric, max, hint, onChange)
	local box = S.Inset(parent)
	CuratorOctoFull.SetSize(box, w, 22)
	local eb = CreateFrame("EditBox", nil, box)
	eb:SetPoint("TOPLEFT", 6, -2)
	eb:SetPoint("BOTTOMRIGHT", -6, 2)
	eb:SetAutoFocus(false)
	eb:SetFontObject(GameFontHighlightSmall)
	eb:SetMaxLetters(max or (numeric and 9 or 40))
	if numeric and eb.SetNumeric then
		eb:SetNumeric(true)
	end
	box.eb = eb
	box.hint = S.Text(box, "GameFontDisableSmall", "LEFT")
	box.hint:SetPoint("LEFT", 8, 0)
	box.hint:SetPoint("RIGHT", -6, 0)
	box.hint:SetWordWrap(false)
	box.hint:SetText(hint or "")
	local function Paint()
		CuratorOctoFull.SetShown(box.hint, (eb:GetText() or "") == "" and not eb:HasFocus())
	end
	CuratorOctoFull.SetScript(eb, "OnTextChanged", function(_, user)
		Paint()
		if onChange then
			onChange(box, user)
		end
	end)
	CuratorOctoFull.SetScript(eb, "OnEditFocusGained", Paint)
	CuratorOctoFull.SetScript(eb, "OnEditFocusLost", Paint)
	CuratorOctoFull.SetScript(eb, "OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	CuratorOctoFull.SetScript(eb, "OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	function box:Get()
		return tonumber(self.eb:GetText() or "")
	end
	function box:Set(v)
		self.eb:SetText(v ~= nil and tostring(v) or "")
		Paint()
	end
	function box:Text()
		return self.eb:GetText() or ""
	end
	Paint()
	return box
end
MUI.EditBox = EditBox

local function Clock()
	return (GetTime and GetTime()) or 0
end

-- A button that spends: a first click arms it ("Confirm?"), a second one within ARM seconds does it.
local function ArmButton(parent, text, w, onDo)
	local b = S.Button(parent, text, w, 22)
	b.text0 = text
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		if self.armed and Clock() - self.armed <= ARM then
			self.armed = nil
			self:SetText(self.text0)
			onDo(self)
			return
		end
		self.armed = Clock()
		self:SetText(L["Confirm?"])
		ns.Play(ns.SND.tick)
		if CuratorOctoFull.Timer and CuratorOctoFull.Timer.After then
			CuratorOctoFull.Timer.After(ARM + 0.05, function()
				if self.armed and Clock() - self.armed >= ARM then
					self.armed = nil
					self:SetText(self.text0)
				end
			end)
		end
	end)
	function b:SetLabel(t)
		self.text0 = t
		if not self.armed then
			self:SetText(t)
		end
	end
	function b:Disarm()
		self.armed = nil
		self:SetText(self.text0)
	end
	return b
end
MUI.ArmButton = ArmButton

-- A text on its line, smaller when it is long (the client cuts what is still too long).
local function Fit(fs, text, size)
	S.Fit(fs, text or "", fs:GetWidth() - 2, size or 10, 8)
end

-- A row of a list: its icon, its name, its columns (cols: { width, justify } after the name).
local function Row(parent, nameW, cols)
	local r = S.ListButton(parent)
	r:SetHeight(ROW_H - 1)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, ROW_H - 5, ROW_H - 5)
	r.icon:SetPoint("LEFT", 3, 0)
	r.name = S.Text(r, "GameFontNormalSmall", "LEFT")
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
	r.name:SetWidth(nameW)
	r.name:SetWordWrap(false)
	r.cols = {}
	local x = 3 + (ROW_H - 5) + 6 + nameW + 6
	for i, c in ipairs(cols) do
		local fs = S.Text(r, "GameFontHighlightSmall", c[2] or "RIGHT")
		fs:SetPoint("LEFT", x, 0)
		fs:SetWidth(c[1])
		fs:SetWordWrap(false)
		r.cols[i] = fs
		x = x + c[1] + 6
	end
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	return r
end

-- A tab of the pages of the Bourse, at the top of its panel.
-- A button whose words are its own (smaller when long), out of reach of the fonts of its states: b:Words(text, colour).
local function OwnWords(b, left, right, justify)
	b:SetText("")
	b.words = S.Text(b, "GameFontNormal", justify or "CENTER")
	b.words:SetPoint("LEFT", left or 6, 0)
	b.words:SetPoint("RIGHT", right or -6, 0)
	b.words:SetWordWrap(false)
	function b:Words(text, c)
		self.text0 = text
		S.Fit(self.words, text or "", self.words:GetWidth() - 4, 12, 8)
		c = c or (self:IsEnabled() and GOLD or { 0.5, 0.5, 0.5 })
		self.words:SetTextColor(c[1], c[2], c[3])
	end
	return b
end

local function PageTab(parent, label, icon)
	local b = S.Button(parent, "", 128, 24)
	b.icon = b:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(b.icon, 16, 16)
	b.icon:SetPoint("LEFT", 8, 0)
	b.icon:SetTexture(icon)
	OwnWords(b, 8 + 16 + 5, -6, "LEFT")
	b:Words(label)
	function b:Paint(on, text)
		if on then
			self:LockHighlight()
		else
			self:UnlockHighlight()
		end
		self:Words(text, on and WHITE or GOLD)
	end
	return b
end

-------------------------------------------------------------------------------
-- The panel
-------------------------------------------------------------------------------
function MUI:Build(parent)
	if self.frame then
		if parent and self.frame:GetParent() ~= parent then
			self.frame:SetParent(parent)
		end
		return self.frame
	end
	local f = CreateFrame("Frame", "CuratorMarket", parent or UIParent)
	CuratorOctoFull.SetSize(f, W, H)
	f:Hide()
	f:EnableMouse(true)
	f.bg = S.Inset(f)
	f.bg:SetPoint("TOPLEFT", 0, -30)
	f.bg:SetPoint("BOTTOMRIGHT", 0, 0)
	f.tabs = {}
	for i, p in ipairs(PAGES) do
		local i, p = i, p; local b = PageTab(f, L[p.label], p.icon)
		b:SetPoint("TOPLEFT", (i - 1) * 132, 0)
		b.key = p.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			ns.Play(ns.SND.page)
			MUI:Page(p.key)
		end)
		f.tabs[i] = b
	end
	-- (the rubies, the age of the list and the address of every listing, the button that sends and receives: a
	-- /reload)
	f.rubies = S.Text(f, "GameFontHighlight", "RIGHT")
	f.rubies:SetPoint("TOPRIGHT", -4, -1)
	f.fresh = CreateFrame("Button", nil, f)
	CuratorOctoFull.SetSize(f.fresh, 106, 12)
	f.fresh:SetPoint("TOPRIGHT", -4, -16)
	f.fresh.text = S.Text(f.fresh, "GameFontDisableSmall", "RIGHT")
	f.fresh.text:SetPoint("RIGHT")
	f.fresh.text:SetWordWrap(false)
	CuratorOctoFull.SetScript(f.fresh, "OnClick", function(self)
		MUI:CopyBox(self, "https://" .. SITE)
	end)
	CuratorOctoFull.SetScript(f.fresh, "OnEnter", function(self)
		self.text:SetTextColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:AddLine(L["Every listing is on the website"], 1, 1, 1)
		GameTooltip:AddLine(L["In the game, a selection: what you lack and your favorites first. Click: the address of the website, to copy."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.fresh, "OnLeave", function(self)
		self.text:SetTextColor(0.5, 0.5, 0.5)
		GameTooltip:Hide()
	end)
	f.reload = OwnWords(S.Button(f, "", 120, 22))
	f.reload:Words(L["Send and receive"])
	f.reload:SetPoint("TOPRIGHT", -114, -1)
	CuratorOctoFull.SetScript(f.reload, "OnClick", function()
		MUI:Reload()
	end)
	CuratorOctoFull.SetScript(f.reload, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Send and receive"], 1, 1, 1)
		GameTooltip:AddLine(L["The interface reloads: the game saves, the Curator app sends your save to the Exchange at once (the first to arrive wins), and what the news brought comes. The news come back every quarter of an hour."], 0.85, 0.85, 0.85, true)
		local news = MK:News()
		if news and news.t then
			GameTooltip:AddLine(string.format(L["The news of the Exchange here: %s ago"], ns.Duration(math.max(0, Now() - news.t))), 0.62, 0.62, 0.66, true)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.reload, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.pages = {}
	f.pages.buy = self:BuildBuy(f)
	f.pages.sell = self:BuildSell(f)
	f.pages.mine = self:BuildMine(f)
	f.pages.bought = self:BuildBought(f)
	-- (closed: the opening to come)
	local cl = CreateFrame("Frame", nil, f)
	cl:SetAllPoints(f.bg)
	cl:SetFrameLevel(f:GetFrameLevel() + 20)
	cl:EnableMouse(true)
	cl.bg = cl:CreateTexture(nil, "BACKGROUND")
	cl.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(cl.bg, 0.03, 0.03, 0.04, 0.94)
	cl.crest = cl:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(cl.crest, 72, 72)
	cl.crest:SetPoint("TOP", 0, -46)
	cl.crest:SetTexture("Interface\\Icons\\INV_Misc_Coin_17")
	cl.title = S.Text(cl, "GameFontNormalHuge", "CENTER")
	cl.title:SetPoint("TOP", cl.crest, "BOTTOM", 0, -14)
	cl.title:SetText(L["Opening soon"])
	cl.text = S.Text(cl, "GameFontHighlight", "CENTER")
	cl.text:SetPoint("TOP", cl.title, "BOTTOM", 0, -12)
	cl.text:SetWidth(W - 160)
	cl.text:SetWordWrap(true)
	cl.say = S.Text(cl, "GameFontNormal", "CENTER")
	cl.say:SetPoint("TOP", cl.text, "BOTTOM", 0, -18)
	cl.say:SetWidth(W - 160)
	cl.say:SetWordWrap(true)
	cl.say:SetTextColor(0.85, 0.75, 0.5)
	cl:Hide()
	f.closed = cl
	CuratorOctoFull.SetScript(f, "OnShow", function()
		MUI:Paint()
	end)
	self.frame = f
	ns.On("MARKET_CHANGED", function()
		if f:IsShown() then
			MUI:Paint()
		end
	end)
	ns.On("RUBIES_CHANGED", function()
		if f:IsShown() then
			MUI:PaintHead()
		end
	end)
	return f
end

-- The page shown.
function MUI:Page(key)
	self.page = key or self.page or "buy"
	local f = self.frame
	if not f then
		return
	end
	for k, p in pairs(f.pages) do
		CuratorOctoFull.SetShown(p, k == self.page)
	end
	self:Paint()
end

-- The interface reloaded: the game saves (the app sends the save), the news written since are read. (The test of the
-- author: the website played here at once.)
function MUI:Reload()
	ns.Play(ns.SND.click or ns.SND.tick)
	if self.testing then
		self:TestJudge(true)
		return
	end
	if ReloadUI then
		ReloadUI()
	end
end

-- What the head of the panel says: the rubies, the age of the list, what waits to be sent.
function MUI:PaintHead()
	local f = self.frame
	if not f then
		return
	end
	f.rubies:SetText(Rubies(ns.Rubies:Balance(), 14))
	local m = MK:Db()
	for _, b in ipairs(f.tabs) do
		local n = 0
		if b.key == "mine" then
			for _ in pairs(m and m.ls or {}) do
				n = n + 1
			end
		elseif b.key == "bought" then
			for _, t in ipairs({ m and m.bu or {}, m and m.od or {}, m and m.fl or {} }) do
				for _ in pairs(t) do
					n = n + 1
				end
			end
		end
		local count = n > 0 and (" (" .. n .. ")") or ""
		local label
		for _, p in ipairs(PAGES) do
			if p.key == b.key then
				label = L[p.label]
			end
		end
		b:Paint(b.key == self.page, label .. count)
	end
	local news = MK:News()
	f.fresh.text:SetText(news and news.t and string.format(L["List of %s ago"], ns.Duration(math.max(0, Now() - news.t))) or "")
	f.fresh.text:SetTextColor(0.5, 0.5, 0.5)
	-- (something waits for the website: the button says Send now (Put online now, on the page Sell); else Receive)
	local waiting = self:Waiting()
	f.reload:Words((waiting and self.page == "sell" and L["Put online now"]) or (waiting and L["Send now"]) or L["Receive"])
end

-- A box with an address to copy (Ctrl+C), under a frame; it goes with Escape, Enter, or its cross (1 November, his word:
-- « SANS cliquer sur "Retour" impossible de retour »: a click elsewhere no more).
function MUI:CopyBox(owner, text)
	local cb = self.copy
	if not cb then
		cb = CreateFrame("Frame", nil, self.frame)
		CuratorOctoFull.SetSize(cb, 300, 52)
		cb:SetFrameLevel(self.frame:GetFrameLevel() + 40)
		cb.bg = S.Inset(cb)
		cb.bg:SetAllPoints()
		local c = CreateFrame("Frame", nil, cb)
		c:SetAllPoints()
		c:SetFrameLevel(cb.bg:GetFrameLevel() + 1)
		cb.hint = S.Text(c, "GameFontHighlightSmall", "LEFT")
		cb.hint:SetPoint("TOPLEFT", 10, -8)
		cb.hint:SetWidth(256)
		cb.hint:SetWordWrap(false)
		cb.hint:SetText(L["Ctrl+C (Cmd+C on a Mac) copies the address: paste it in your browser."])
		cb.box = EditBox(c, 280, false, 80)
		cb.box:SetPoint("TOPLEFT", 10, -22)
		local eb = cb.box.eb
		CuratorOctoFull.SetScript(eb, "OnEscapePressed", function()
			cb:Hide()
		end)
		CuratorOctoFull.SetScript(eb, "OnEnterPressed", function()
			cb:Hide()
		end)
		cb.close = S.CloseButton(c)
		cb.close:SetPoint("TOPRIGHT", 2, 2)
		CuratorOctoFull.SetScript(cb.close, "OnClick", function()
			cb:Hide()
		end)
		CuratorOctoFull.SetScript(eb, "OnTextChanged", function(self, user)
			-- (the address stays as it is: a key typed by mistake changes nothing)
			if user and self:GetText() ~= cb.text then
				self:SetText(cb.text)
				self:HighlightText()
			end
		end)
		self.copy = cb
	end
	cb.text = text
	cb:ClearAllPoints()
	cb:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)
	cb.box.eb:SetText(text)
	cb:Show()
	cb.box.eb:SetFocus()
	cb.box.eb:HighlightText()
	ns.Play(ns.SND.click)
end

-- Something of the save the website has not seen yet (a listing, a purchase, a withdrawal...).
function MUI:Waiting()
	local m = MK:Db()
	if not m then
		return false
	end
	if next(m.bu) or next(m.fl) or next(m.wd) or next(m.pc) then
		return true
	end
	for n in pairs(m.ls) do
		if MK:StateOf(n) == "waiting" then
			return true
		end
	end
	for n in pairs(m.od) do
		if MK:StateOf(n, true) == "waiting" then
			return true
		end
	end
	return false
end

function MUI:Paint()
	local f = self.frame
	if not (f and f:IsShown()) then
		return
	end
	self:PaintHead()
	local ok, why, when = MK:CanUse(true)
	local closed = not ok and why == "closed"
	CuratorOctoFull.SetShown(f.closed, closed)
	if closed then
		local d = tonumber(when)
		f.closed.text:SetText(d and d > 0 and string.format(L["The Steamwheedle Exchange opens on %s."], date("%d/%m/%Y %H:%M", d))
			or L["The Steamwheedle Exchange opens soon: one market for the Horde and the Alliance of every realm."])
		f.closed.say:SetText(L["\"Horde or Alliance, gold stays gold. Come back when the Cartel opens its doors.\""])
	end
	local p = self.page or "buy"
	if p == "buy" then
		self:PaintBuy()
	elseif p == "sell" then
		self:PaintSell()
	elseif p == "mine" then
		self:PaintMine()
	else
		self:PaintBought()
	end
end

-- A line at the bottom of a page: why nothing can be done (nil: all is well).
function MUI:Why(fs, why, extra)
	if not why then
		fs:SetText("")
		return
	end
	local text = L[WHY[why] or WHY.thing]
	if why == "pass" and ns.Pass and ns.Pass.Text then
		text = ns.Pass:Text(extra)
	end
	fs:SetText(text)
	fs:SetTextColor(RED[1], RED[2], RED[3])
end

-------------------------------------------------------------------------------
-- The auction house of the game: its fourth tab
-------------------------------------------------------------------------------
-- (the window of the auction house of Vanilla: AuctionFrame, its tabs at its bottom; a client of another kind: the
-- panel in a window of its own, beside its window)
function MUI:Hook()
	local af = _G.AuctionFrame
	if self.hooked or not af then
		return self.hooked
	end
	self.hooked = true
	local n = (af.numTabs or 3) + 1
	local tab = S.Make("Button", "AuctionFrameTab" .. n, af, "AuctionTabTemplate")
		or S.Make("Button", "AuctionFrameTab" .. n, af, "CharacterFrameTabButtonTemplate")
	if not tab then
		-- (no tab of the game: a button of the game under the window, where the tabs are)
		tab = S.Make("Button", "AuctionFrameTab" .. n, af, "UIPanelButtonTemplate") or S.Button(af, "", 100, 24)
		CuratorOctoFull.SetSize(tab, 100, 24)
	end
	tab:SetID(n)
	tab:SetText("Curator")
	local prev = _G["AuctionFrameTab" .. (n - 1)]
	if prev then
		tab:SetPoint("LEFT", prev, "RIGHT", -15, 0)
	else
		tab:SetPoint("BOTTOMLEFT", af, "BOTTOMLEFT", 15 + (n - 1) * 80, -30)
	end
	if PanelTemplates_TabResize then
		pcall(PanelTemplates_TabResize, tab, 0)
	end
	if PanelTemplates_SetNumTabs then
		pcall(PanelTemplates_SetNumTabs, af, n)
		pcall(PanelTemplates_EnableTab, af, n)
	end
	self.tab, self.tabId = tab, n
	local panel = self:Build(af)
	local function Show(index)
		if index == n then
			for _, name in ipairs({ "AuctionFrameBrowse", "AuctionFrameBid", "AuctionFrameAuctions" }) do
				local p = _G[name]
				if p and p.Hide then
					p:Hide()
				end
			end
			if PanelTemplates_SetTab then
				pcall(PanelTemplates_SetTab, af, n)
			end
			-- (the ground of the page of the bids: a list over the whole window)
			local parts = { "TopLeft", "Top", "TopRight", "BotLeft", "Bot", "BotRight" }
			for _, part in ipairs(parts) do
				local t = _G["AuctionFrame" .. part]
				if t and t.SetTexture then
					t:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-" .. part)
				end
			end
			if MUI.win then
				MUI.win:Hide()
			end
			panel = MUI:Place(af, 22, -72)
			MUI:Page(MUI.page)
		elseif panel:GetParent() == af then
			panel:Hide()
		end
	end
	CuratorOctoFull.SetScript(tab, "OnClick", function(self)
		if AuctionFrameTab_OnClick then
			pcall(AuctionFrameTab_OnClick, self)
		end
		Show(n)
		ns.Play(ns.SND.page)
	end)
	if hooksecurefunc and AuctionFrameTab_OnClick then
		hooksecurefunc("AuctionFrameTab_OnClick", function(btn)
			local id = btn and btn.GetID and btn:GetID()
			if id and id ~= n and panel:GetParent() == af then
				panel:Hide()
			end
		end)
	end
	return true
end

-- The panel in a frame (the window of the auction house of the game, or its own window): there, shown.
function MUI:Place(parent, x, y)
	local panel = self:Build(parent)
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	panel:SetFrameLevel(parent:GetFrameLevel() + 10)
	panel:Show()
	return panel
end

-- A window of its own (beside the window of an auction house of another kind; the test of the author): shown, the
-- panel in it.
function MUI:ShowWindow()
	local w = self:Window()
	w:Show()
	self:Place(w, 12, -62)
	return w
end

-- A window of its own, beside the window of an auction house of another kind.
function MUI:Window()
	if self.win then
		return self.win
	end
	local w = S.Window("CuratorMarketWindow", W + 24, H + 74)
	w:SetFrameStrata("HIGH")
	w:SetToplevel(true)
	w:Hide()
	if w.SetPortraitToAsset then
		w:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Coin_17")
	end
	w:SetTitle(L["Steamwheedle Exchange"])
	S.DragBar(w, 22)
	tinsert(UISpecialFrames, "CuratorMarketWindow")
	self.win = w
	return w
end

-- The auction house opened, closed.
function MUI:Opened()
	MK.at = true
	MK:Forget()
	if self:Hook() then
		return
	end
	-- (another window of the auction house: a button on it opens the panel in a window of its own)
	local ah = _G.AuctionHouseFrame
	local w = self:Window()
	w:ClearAllPoints()
	if ah and ah.IsShown and ah:IsShown() then
		w:SetPoint("TOPLEFT", ah, "TOPRIGHT", 8, 0)
	else
		w:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
	if not self.side and ah then
		local b = S.SideTab(ah, "Interface\\Icons\\INV_Misc_Coin_17", L["Steamwheedle Exchange"], function()
			if w:IsShown() then
				w:Hide()
			else
				MUI:ShowWindow()
				MUI:Page(MUI.page)
			end
		end)
		b:SetPoint("TOPLEFT", ah, "TOPRIGHT", b.gap or 0, -40)
		self.side = b
	end
end

function MUI:Closed()
	if self.testing then
		-- (the test of the author: the Exchange anywhere, in its own window)
		return
	end
	MK.at = false
	if self.frame then
		self.frame:Hide()
	end
	if self.win then
		self.win:Hide()
	end
	if self.sheet then
		self.sheet:Hide()
	end
	if self.picker then
		self.picker:Hide()
	end
end

do
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("AUCTION_HOUSE_SHOW")
	ev:RegisterEvent("AUCTION_HOUSE_CLOSED")
	ev:RegisterEvent("ADDON_LOADED")
	CuratorOctoFull.SetScript(ev, "OnEvent", function(_, event, arg1)
		if event == "AUCTION_HOUSE_SHOW" then
			MUI:Opened()
		elseif event == "AUCTION_HOUSE_CLOSED" then
			MUI:Closed()
		elseif event == "ADDON_LOADED" and (arg1 == "Blizzard_AuctionUI" or arg1 == "Blizzard_AuctionHouseUI") then
			MUI:Hook()
		end
	end)
end

-------------------------------------------------------------------------------
-- Pieces of the pages
-------------------------------------------------------------------------------
local TYPES = {
	{ key = "all", label = "Everything" }, { key = "c", label = "Cards" }, { key = "w", label = "Cards of the cases" },
	{ key = "b", label = "Boosters" }, { key = "d", label = "Displays" }, { key = "x", label = "Cases" },
}
local FINISHES = {
	{ key = "all", label = "Every finish" }, { key = "n", label = "Normal" }, { key = "s", label = "Thunderforged" },
	{ key = "h", label = "Titanforged" }, { key = "c", label = "Corrupted" },
}
-- (1 November, 13 h 26, his word: « y'a pas les options pour les cartes de caisses, pour les types de titanforges etc etc ..
-- vraiment il faut que ça soit précis ») A finish of the cards of the albums, as a card of a case has it (thunderforged t,
-- titanforged T); its titanforged (its certificate, its family); appraised; restored.
local FINISH_CASE = { n = "n", s = "t", h = "T" }
local RANK_KEY = 100 -- (the ranks of the cards of the cases in the menu of the rarities: 101 to 105)

local function Titan(it)
	return (it.k == "c" and it.f == "h") or (it.k == "w" and it.f == "T")
end

-- Its grade as the expert found it, appraised (a copy in its case; a card of a case appraised); nil: not appraised.
local function GradeOf(it)
	if it.k == "c" then
		return (it.sl == true and (tonumber(it.g) or 0) >= 100) and it.g / 100 or nil
	elseif it.k == "w" then
		return it.ap and tonumber(it.grade) or nil
	end
	return nil
end

local function Restored(it)
	return (it.k == "c" and type(it.r) == "table" and CuratorOctoFull.Length(it.r) > 0) or (it.k == "w" and it.wear ~= nil)
end

-- Whether a thing answers a filter of its titanforged ("yes": certified by a master of the mages, "no": not, "f<n>":
-- certified, of that family).
local function TitanOk(it, v)
	if not Titan(it) then
		return false
	elseif v == "yes" then
		return it.tc ~= nil
	elseif v == "no" then
		return it.tc == nil
	end
	local fam = tonumber(CuratorOctoFull.Match(tostring(v), "^f(%d+)$"))
	local MG = ns.Mages
	local info = fam and it.tc and it.pt and MG and MG.Info(it.pt, it.k == "w")
	return info ~= nil and info.family == fam
end

-- Whether a thing answers a filter of its grade (-1: not appraised; -2: appraised; n: n or more).
local function GradeOk(it, g)
	if not (it.k == "c" or it.k == "w") then
		return false
	end
	local v = GradeOf(it)
	if g == -1 then
		return v == nil
	elseif g == -2 then
		return v ~= nil
	end
	return v ~= nil and v >= g
end
MUI.TitanOk, MUI.GradeOk, MUI.Restored = TitanOk, GradeOk, Restored

local SORTS = {
	{ key = "rarity", label = "Sort: rarity" }, { key = "price", label = "Sort: price" },
	{ key = "new", label = "Sort: newest" }, { key = "ending", label = "Sort: ending soon" },
}
local KIND_ORDER = { c = 1, w = 2, d = 3, b = 4, x = 5 }

-- A menu of the game (dd) of options { key, label (or text, already in the words of the player) }: get() the one
-- chosen, set(key) on a choice.
local function Menu(dd, list, get, set)
	dd:SetupMenu(function(_, root)
		local options = type(list) == "function" and list() or list
		if root.SetScrollMode and CuratorOctoFull.Length(options) > 14 then
			root:SetScrollMode(400)
		end
		for _, o in ipairs(options) do
			local _, o = _, o; root:CreateRadio(o.text or L[o.label], function()
				return get() == o.key
			end, function()
				set(o.key)
			end, o.key)
		end
	end)
end

-- A menu of the game, small (a button that opens it, its option chosen on it): dd:SetupMenu(generator), dd:GenerateMenu().
-- (Without the menus of the game: a click takes the next option.)
local function SmallDrop(parent, w)
	local d = S.Button(parent, "", w, 22)
	d.label:ClearAllPoints()
	d.label:SetPoint("LEFT", 8, 0)
	d.label:SetPoint("RIGHT", -22, 0)
	d.label:SetJustifyH("LEFT")
	d.label:SetWordWrap(false)
	d.arrow = d:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(d.arrow, 16, 16)
	d.arrow:SetPoint("RIGHT", -5, 0)
	d.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
	local radios = {}
	function d:SetupMenu(gen)
		self.generator = gen
		self:GenerateMenu()
	end
	function d:GenerateMenu()
		if not self.generator then
			return
		end
		local chosen
		local root = {}
		radios = {}
		function root:CreateRadio(text, isSelected, setSelected, data)
			radios[CuratorOctoFull.Length(radios) + 1] = { isSelected = isSelected, setSelected = setSelected, data = data }
			if isSelected(data) then
				chosen = text
			end
			return {}
		end
		function root.CreateTitle()
			return {}
		end
		function root.CreateDivider() end
		function root.SetScrollMode() end
		self.generator(self, root)
		self:SetText(chosen or "")
	end
	CuratorOctoFull.SetScript(d, "OnClick", function(self)
		if not self.generator then
			return
		end
		ns.Play(ns.SND.click)
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(self, function(owner, root)
				self.generator(owner, root)
			end)
			return
		end
		local at = 0
		for i, r in ipairs(radios) do
			if r.isSelected(r.data) then
				at = i
			end
		end
		local nextOne = radios[CuratorOctoFull.Mod(at , math.max(1, CuratorOctoFull.Length(radios))) + 1]
		if nextOne then
			nextOne.setSelected(nextOne.data)
		end
		self:GenerateMenu()
	end)
	return d
end
MUI.SmallDrop = SmallDrop

-- (a menu says the option chosen again when it changed elsewhere)
local function Sync(dd, v)
	if dd.shownValue ~= v then
		dd.shownValue = v
		if dd.GenerateMenu then
			dd:GenerateMenu()
		end
	end
end

-- The albums, in the order of the contents of the album, for a menu (first: the option of every album).
local function AlbumList(first)
	local out = { { key = "all", text = L[first or "All albums"] } }
	local A = ns.Album
	for _, s in ipairs((A and A.Order and A:Order()) or ns.Series or {}) do
		out[CuratorOctoFull.Length(out) + 1] = { key = s.key, text = C:SeriesName(s) }
	end
	return out
end

-- The durations of a listing, for a menu (base: the price, or the value of reference of a barter: its fee told).
local function DayList(base)
	local out = {}
	for _, d in ipairs(MK:Rules().days) do
		local text = d[1] == 1 and L["1 day"] or string.format(L["%d days"], d[1])
		if base then
			text = text .. "  ·  " .. string.format(L["fee %s"], Rubies(MK:Fee(base, d[1]) or 0, 10))
		end
		out[CuratorOctoFull.Length(out) + 1] = { key = d[1], text = text }
	end
	return out
end

-- The duration chosen at first: three days (else the first the rules know).
local function DefaultDays()
	local days = MK:Rules().days
	for _, d in ipairs(days) do
		if d[1] == 3 then
			return 3
		end
	end
	return days[1] and days[1][1] or 1
end

-- A label on the left of a field (smaller when long: 82 wide at most).
local function Label(parent, text, object)
	local fs = S.Text(parent, object or "GameFontNormalSmall", "LEFT")
	fs:SetText(text)
	if not object and S.Width(fs) > 82 then
		S.Fit(fs, text, 82, 10, 7.5)
	end
	return fs
end

-- A little tab of a page (its parts: My things, Buy orders...): b:Paint(on, text).
local function SubTab(parent, w)
	local b = OwnWords(S.Button(parent, "", w, 20))
	function b:Paint(on, text)
		if on then
			self:LockHighlight()
		else
			self:UnlockHighlight()
		end
		self:Words(text, on and WHITE or GOLD)
	end
	return b
end

-- The story of a thing, line by line ({ text, colour }): what the addon tells of it, never what the seller wrote.
function MUI.Story(it)
	local out = {}
	local function Add(text, c, wrap)
		out[CuratorOctoFull.Length(out) + 1] = { text, c or { 1, 1, 1 }, wrap }
	end
	if it.k == "c" then
		local card = MUI.Card(it)
		if card then
			Add(C:SeriesName(card.series) .. "  ·  " .. L[ns.RARITY[card.rarity].label], { 0.7, 0.7, 0.72 })
		end
		local f = MUI.FinishText(it)
		if f then
			Add(f)
		end
		local E = ns.Expertise
		if it.g > 0 and it.sl ~= true then
			Add(L["Its case opened: its grade is known at its next appraisal."], { 0.72, 0.86, 1 }, true)
		elseif it.g > 0 then
			Add(string.format(L["Grade: %s"], E.Label(it.g / 100)))
			local m = E.DecodeMarks(it.m)
			if m then
				Add(E.MarksText(m), { 0.78, 0.8, 0.86 }, true)
			end
			if it.ce > 0 then
				Add(string.format(L["Certificate No. %s"], E.CertText(it.ce)), DIM)
			end
		end
		if CuratorOctoFull.Length(it.r) > 0 then
			local days = {}
			for _, x in ipairs(it.r) do
				if (x[1] or 0) > 0 then
					days[CuratorOctoFull.Length(days) + 1] = date("%d/%m/%Y", x[1])
				end
			end
			Add((CuratorOctoFull.Length(it.r) == 1 and L["Restored once"] or string.format(L["Restored %d times"], CuratorOctoFull.Length(it.r))) .. (CuratorOctoFull.Length(days) > 0 and ("  ·  " .. table.concat(days, ", ")) or ""), { 0.66, 0.9, 1 }, true)
		end
		if it.f == "c" then
			Add(string.format(L["A corrupted copy: %d %%"], it.cor), { 0.82, 0.6, 1 })
		end
		if it.seal then
			local SL = ns.Masters
			Add(string.format(L["Sealed: %s"], SL.Label(it.seal.rank)))
			Add(string.format(L["Pact No. %s"], tostring(it.seal.pact)) .. (it.seal.master ~= "" and ("  ·  " .. it.seal.master) or ""), DIM)
		end
		if it.ot > 0 or it.och ~= "" or it.ow ~= "" then
			local CU = ns.CopiesUI
			local parts = { (CU and CU.How and it.ow ~= "") and CU.How({ w = it.ow }) or L["First"] }
			if it.ot > 0 then
				parts[CuratorOctoFull.Length(parts) + 1] = date("%d/%m/%Y", it.ot)
			end
			if it.och ~= "" then
				parts[CuratorOctoFull.Length(parts) + 1] = it.och
			end
			Add(table.concat(parts, "  ·  "), { 0.7, 0.72, 0.78 }, true)
		end
	elseif it.k == "w" then
		local CR = ns.CrateUI
		local rank = CR and CR.RANKS and CR.RANKS[it.rank]
		Add(CaseName(it.edition) .. (rank and ("  ·  " .. L[rank.label]) or ""), { 0.7, 0.7, 0.72 })
		for _, b in ipairs(MUI.Badges(it)) do
			Add(b)
		end
		if it.weapon then
			local note = ns.CrateCard and ns.CrateCard.WeaponNote and ns.CrateCard.WeaponNote({ id = it.weapon.item,
				class = it.weapon.cls ~= "" and it.weapon.cls or nil, faction = it.weapon.side ~= "" and it.weapon.side or nil })
			Add(L["A weapon of legend"] .. (note and ("  ·  " .. note) or ""), { 1, 0.5, 0.2 })
		end
		if it.ap then
			Add(string.format(L["Certificate No. %s"], ns.Expertise.CertText(it.ap.ce)), DIM)
		end
		if it.ot > 0 then
			Add((it.oh == "k" and L["From a contract"] or L["From a case"]) .. "  ·  " .. date("%d/%m/%Y", it.ot), { 0.7, 0.72, 0.78 })
		end
	elseif it.k == "d" then
		Add(L["16 boosters, sealed in their box"])
		if it.cased then
			Add(L["In its protective case"], { 0.72, 0.86, 1 })
		end
	elseif it.k == "b" then
		Add(L["A booster to open"])
	elseif it.k == "x" then
		Add(L["A case to open with a key of its edition"])
	end
	return out
end

-- The tooltip of a thing (owner: the frame under the mouse; extra: lines after it).
function MUI:Tooltip(owner, it, extra)
	if not it then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	local c = MUI.Color(it)
	GameTooltip:AddLine(MUI.Name(it), c[1], c[2], c[3])
	for _, l in ipairs(MUI.Story(it)) do
		GameTooltip:AddLine(l[1], l[2][1], l[2][2], l[2][3], l[3] and true or false)
	end
	for _, l in ipairs(extra or {}) do
		local col = l[2] or { 1, 0.82, 0.25 }
		GameTooltip:AddLine(l[1], col[1], col[2], col[3], true)
	end
	GameTooltip:Show()
end

-- A favorite of mine (a star in the game, or on the website: the news say so).
function MUI:Favorite(spec)
	if MK:IsFavorite(spec) then
		return true
	end
	local n = MK:News()
	return n ~= nil and n.favs ~= nil and n.favs[spec] == true
end

-- The things of the collection that answer what a barter (or an order) asks, one each, the plainest first: their
-- sources, and the things; nil when one is missing.
function MUI:Givable(asks, sellable)
	sellable = sellable or MK:Sellable()
	local used, out, items = {}, {}, {}
	for _, a in ipairs(asks or {}) do
		local best, bi
		for i, x in ipairs(sellable) do
			if not used[i] and MK.Answers(x.it, a) then
				-- (a copy appraised, restored, of an origin of its own: last)
				local it = x.it
				local v = (it.g or 0) + CuratorOctoFull.Length((it.r or {})) * 1000 + ((it.ot or 0) > 0 and 1 or 0)
				if not best or v < best then
					best, bi = v, i
				end
			end
		end
		if not bi then
			return nil
		end
		used[bi] = true
		out[CuratorOctoFull.Length(out) + 1] = sellable[bi].src
		items[CuratorOctoFull.Length(items) + 1] = sellable[bi].it
	end
	return out, items
end

-- A rubies text, or "-".
local function Price(p, size)
	return p and Rubies(p, size or 11) or "-"
end

-- What a barter asks, on one line (its rubies more after it).
local function BarterText(asks, cp)
	local parts = {}
	for _, a in ipairs(asks or {}) do
		parts[CuratorOctoFull.Length(parts) + 1] = MUI.AskText(a)
	end
	local s = table.concat(parts, " + ")
	if (cp or 0) > 0 then
		s = s .. " + " .. Rubies(cp, 11)
	end
	return s
end
MUI.BarterText = BarterText

-------------------------------------------------------------------------------
-- Buy: the selection of the news, filtered, sorted
-------------------------------------------------------------------------------
local BUY_ROWS = 9
local LX = 184 -- (the left of the list, past the filters)

function MUI:BuildBuy(f)
	local p = CreateFrame("Frame", nil, f)
	p:SetFrameLevel(f.bg:GetFrameLevel() + 2)
	p:SetPoint("TOPLEFT", f.bg, "TOPLEFT", 8, -8)
	p:SetPoint("BOTTOMRIGHT", f.bg, "BOTTOMRIGHT", -8, 8)
	local F = self.f
	F.type, F.album, F.rarity, F.finish, F.grade, F.edition = "all", "all", 0, "all", 0, "all"
	F.rank, F.titan, F.restored = 0, "all", "all"
	local function Again()
		MUI.buyPage = 1
		MUI:PaintBuy()
	end
	-- the filters, on the left
	local y = 0
	-- (1 November: three filters more, their rows a little closer: 20 high, 1 between them)
	local STEP = 21
	p.search = EditBox(p, 170, false, 40, L["Search"], Again)
	p.search:SetHeight(20)
	p.search:SetPoint("TOPLEFT", 0, y)
	p.search.eb:SetPoint("BOTTOMRIGHT", -22, 2)
	y = y - STEP
	local function Drop()
		local d = SmallDrop(p, 170)
		d:SetHeight(20)
		d:SetPoint("TOPLEFT", 0, y)
		y = y - STEP
		return d
	end
	p.type = Drop()
	Menu(p.type, TYPES, function() return F.type end, function(v)
		F.type = v
		-- (a rarity of the albums for the cards of the albums, a rank for the cards of the cases)
		if v ~= "all" and v ~= "c" then
			F.rarity = 0
		end
		if v ~= "all" and v ~= "w" then
			F.rank = 0
		end
		Again()
	end)
	p.album = Drop()
	Menu(p.album, function() return AlbumList() end, function() return F.album end, function(v) F.album = v Again() end)
	-- (the rarities of the albums; 1 November: the ranks of the cards of the cases with them, of the cases only when the
	-- type is theirs)
	p.rarity = Drop()
	Menu(p.rarity, function()
		local out = { { key = 0, text = L["Every rarity"] } }
		if F.type == "all" or F.type == "c" then
			for i, r in ipairs(ns.RARITY) do
				out[CuratorOctoFull.Length(out) + 1] = { key = i, text = L[r.label] }
			end
		end
		local CR = ns.CrateUI
		if (F.type == "all" or F.type == "w") and CR and CR.RANKS then
			for i, r in ipairs(CR.RANKS) do
				out[CuratorOctoFull.Length(out) + 1] = { key = RANK_KEY + i, text = F.type == "w" and L[r.label] or string.format(L["Case: %s"], L[r.label]) }
			end
		end
		return out
	end, function()
		return (F.rank or 0) > 0 and RANK_KEY + F.rank or F.rarity
	end, function(v)
		if v > RANK_KEY then
			F.rank, F.rarity = v - RANK_KEY, 0
		else
			F.rank, F.rarity = 0, v
		end
		Again()
	end)
	p.finish = Drop()
	Menu(p.finish, FINISHES, function() return F.finish end, function(v) F.finish = v Again() end)
	-- (1 November: the titanforged certified by a master of the mages, or not; of a family, Mages.lua)
	p.titan = Drop()
	Menu(p.titan, function()
		local out = { { key = "all", text = L["Every family"] }, { key = "yes", text = L["Titanforged, certified"] }, { key = "no", text = L["Titanforged, not certified"] } }
		local MG = ns.Mages
		for i, name in ipairs(MG and MG.FAMILIES or {}) do
			out[CuratorOctoFull.Length(out) + 1] = { key = "f" .. i, text = L[name] }
		end
		return out
	end, function() return F.titan end, function(v) F.titan = v Again() end)
	p.grade = Drop()
	Menu(p.grade, function()
		-- (1 November: as the website has them, the best first: a 10, then 9 or more down to 2 or more)
		local out = { { key = 0, text = L["Any grade"] }, { key = -1, text = L["Not appraised"] }, { key = -2, text = L["Appraised, any grade"] },
			{ key = 10, text = string.format(L["Grade %d"], 10) } }
		for g = 9, 2, -1 do
			out[CuratorOctoFull.Length(out) + 1] = { key = g, text = string.format(L["Grade %d or more"], g) }
		end
		return out
	end, function() return F.grade end, function(v) F.grade = v Again() end)
	-- (1 November: restored at an enchanter, or never)
	p.restored = Drop()
	Menu(p.restored, { { key = "all", label = "Restored or not" }, { key = "yes", label = "Restored at an enchanter" }, { key = "no", label = "Never restored at an enchanter" } },
		function() return F.restored end, function(v) F.restored = v Again() end)
	p.edition = Drop()
	Menu(p.edition, function()
		return MUI:Editions()
	end, function() return F.edition end, function(v) F.edition = v Again() end)
	p.min = EditBox(p, 80, true, 9, L["Price from"], Again)
	p.min:SetHeight(20)
	p.min:SetPoint("TOPLEFT", 0, y)
	p.max = EditBox(p, 80, true, 9, L["to"], Again)
	p.max:SetHeight(20)
	p.max:SetPoint("LEFT", p.min, "RIGHT", 10, 0)
	y = y - STEP
	p.sort = Drop()
	Menu(p.sort, SORTS, function() return MUI.sort end, function(v) MUI.sort = v Again() end)
	p.checks = {}
	for _, c in ipairs({ { "missing", "What I lack" }, { "barter", "Barters I can make" }, { "fav", "My favorites" } }) do
		local _, c = _, c; local box = S.Check(p, L[c[2]])
		box:SetPoint("TOPLEFT", -2, y)
		CuratorOctoFull.SetScript(box, "OnClick", function(self)
			F[c[1]] = self:GetChecked() and true or false
			ns.Play(ns.SND.click)
			Again()
		end)
		p.checks[c[1]] = box
		y = y - 19
	end
	-- (every filter off: a little cross in the box of the search)
	p.clear = CreateFrame("Button", nil, p.search)
	CuratorOctoFull.SetSize(p.clear, 16, 16)
	p.clear:SetPoint("RIGHT", -4, 0)
	p.clear:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	p.clear:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight", "ADD")
	CuratorOctoFull.SetScript(p.clear, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Every filter off"], 1, 1, 1)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(p.clear, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(p.clear, "OnClick", function()
		F.type, F.album, F.rarity, F.finish, F.grade, F.edition = "all", "all", 0, "all", 0, "all"
		F.rank, F.titan, F.restored = 0, "all", "all"
		F.missing, F.barter, F.fav = false, false, false
		for _, b in pairs(p.checks) do
			b:SetChecked(false)
		end
		p.search:Set("")
		p.min:Set("")
		p.max:Set("")
		ns.Play(ns.SND.click)
		Again()
	end)
	-- the list, on the right: its heads (a click: its sort)
	p.heads = {}
	local heads = { { "rarity", L["Thing"], 283 }, { "price", L["Price"], 116 }, { nil, L["Seller"], 90 }, { "ending", L["Time left"], 76 } }
	local hx = LX
	for _, h in ipairs(heads) do
		local _, h = _, h; local b = CreateFrame("Button", nil, p)
		CuratorOctoFull.SetSize(b, h[3] - 2, 18)
		b:SetPoint("TOPLEFT", hx, 0)
		b.text = S.Text(b, "GameFontHighlightSmall", "LEFT")
		b.text:SetPoint("LEFT", 4, 0)
		b.text:SetText(h[2])
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		CuratorOctoFull.ColorTexture(b.bg, 1, 1, 1, 0.06)
		b.key = h[1]
		if h[1] then
			b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
			CuratorOctoFull.SetScript(b, "OnClick", function()
				MUI.sort = h[1]
				ns.Play(ns.SND.click)
				Again()
			end)
		end
		p.heads[CuratorOctoFull.Length(p.heads) + 1] = b
		hx = hx + h[3]
	end
	p.rows = {}
	for i = 1, BUY_ROWS do
		local i = i; local r = Row(p, 250, { { 110, "RIGHT" }, { 84, "LEFT" }, { 66, "RIGHT" } })
		r:SetPoint("TOPLEFT", LX, -20 - (i - 1) * ROW_H)
		r:SetWidth(W - 16 - LX)
		r.star = r:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.SetSize(r.star, 12, 12)
		r.star:SetPoint("TOPLEFT", r.icon, "TOPLEFT", -4, 4)
		r.star:SetTexture("Interface\\Common\\ReputationStar")
		r.star:SetTexCoord(0, 0.5, 0, 0.5)
		r.star:Hide()
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			if self.lst then
				MUI:Tooltip(self, self.lst.it, MUI:SelLines(self.lst))
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(r, "OnClick", function(self, button)
			if not self.lst then
				return
			end
			MUI.chosen = self.lst
			ns.Play(ns.SND.click)
			if button == "RightButton" then
				MUI:Sheet(self.lst.it, self.lst)
			end
			MUI:PaintBuy()
		end)
		CuratorOctoFull.SetScript(r, "OnDoubleClick", function(self)
			if self.lst then
				MUI:Sheet(self.lst.it, self.lst)
			end
		end)
		p.rows[i] = r
	end
	p.empty = S.Text(p, "GameFontDisable", "CENTER")
	p.empty:SetPoint("TOPLEFT", LX + 20, -90)
	p.empty:SetPoint("TOPRIGHT", -20, -90)
	p.pager = S.Pager(p)
	p.pager:SetPoint("BOTTOMRIGHT", 0, 28)
	CuratorOctoFull.SetScript(p.pager.prev, "OnClick", function()
		MUI.buyPage = math.max(1, (MUI.buyPage or 1) - (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1))
		ns.Play(ns.SND.page)
		MUI:PaintBuy()
	end)
	CuratorOctoFull.SetScript(p.pager.next, "OnClick", function()
		MUI.buyPage = (MUI.buyPage or 1) + (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1)
		ns.Play(ns.SND.page)
		MUI:PaintBuy()
	end)
	p.count = S.Text(p, "GameFontDisableSmall", "LEFT")
	p.count:SetPoint("BOTTOMLEFT", LX, 46)
	-- the thing chosen, its purchase
	p.info = S.Text(p, "GameFontNormal", "LEFT")
	p.info:SetPoint("BOTTOMLEFT", LX, 6)
	p.info:SetWidth(290)
	p.info:SetWordWrap(false)
	p.why = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.why:SetPoint("BOTTOMLEFT", LX, 26)
	p.why:SetWidth(380)
	p.why:SetWordWrap(false)
	p.buy = ArmButton(p, L["Buy"], 150, function()
		MUI:BuyChosen()
	end)
	p.buy:SetPoint("BOTTOMRIGHT", 0, 0)
	p.sheetBtn = S.Button(p, L["Its sheet"], 90, 22)
	p.sheetBtn:SetPoint("RIGHT", p.buy, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(p.sheetBtn, "OnClick", function()
		if MUI.chosen then
			MUI:Sheet(MUI.chosen.it, MUI.chosen)
		end
	end)
	p.star = CreateFrame("Button", nil, p)
	CuratorOctoFull.SetSize(p.star, 22, 22)
	p.star:SetPoint("RIGHT", p.sheetBtn, "LEFT", -6, 0)
	p.star.tex = p.star:CreateTexture(nil, "ARTWORK")
	p.star.tex:SetAllPoints()
	p.star.tex:SetTexture("Interface\\Common\\ReputationStar")
	p.star.tex:SetTexCoord(0, 0.5, 0, 0.5)
	CuratorOctoFull.SetScript(p.star, "OnClick", function()
		local sel = MUI.chosen
		if sel then
			MUI:ToggleFavorite(sel.it)
		end
	end)
	CuratorOctoFull.SetScript(p.star, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Favorite"], 1, 1, 1)
		GameTooltip:AddLine(L["A star: this thing first in your selection, in the game and on the website."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(p.star, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return p
end

-- The editions of the things (a filter of the page Buy): the limited ones of the albums, the week of the release, the
-- cases.
function MUI:Editions()
	local out = { { key = "all", text = L["Every edition"] }, { key = "hallow", text = L["Hallow's End 2026"] },
		{ key = "hardcup", text = L["Hardcup Saison 3"] }, { key = "launch", text = L["Launch week"] } }
	local CS = ns.Cases
	local keys = {}
	for key in pairs(ns.Crates or {}) do
		if CS and CS:Known(key) then
			keys[CuratorOctoFull.Length(keys) + 1] = key
		end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		out[CuratorOctoFull.Length(out) + 1] = { key = "x:" .. key, text = CaseName(key) }
	end
	return out
end

-- A thing of an edition (the filter of the page Buy).
function MUI.OfEdition(it, edition)
	if edition == "all" then
		return true
	end
	local card = MUI.Card(it)
	local s = (card and card.series) or (it.series and ns.SeriesByKey(it.series)) or nil
	if edition == "hallow" then
		return s ~= nil and s.key == "hallow"
	elseif edition == "hardcup" then
		return s ~= nil and s.limited == "hardcup"
	elseif edition == "launch" then
		return MUI.LaunchWeek(it.ot)
	end
	local case = CuratorOctoFull.Match(edition, "^x:(.+)$")
	return case ~= nil and (it.k == "w" or it.k == "x") and it.edition == case
end

-- A star on a thing, or off (a star of the website goes off on the website).
function MUI:ToggleFavorite(it)
	local spec = MK.Spec(it)
	if MK:IsFavorite(spec) then
		MK:Favorite(spec, false)
	elseif self:Favorite(spec) then
		ns.Print(L["A star put on the website: it goes off on the website, on the page of the thing."])
		return
	else
		MK:Favorite(spec, true)
	end
	ns.Play(ns.SND.click)
	if self.sheet and self.sheet:IsShown() then
		self:PaintSheet()
	end
	self:Paint()
end

-- The lines of a listing for its tooltip: its price, its seller, its time left, how many alike.
function MUI:SelLines(sel)
	local out = { { " " } }
	if sel.price then
		out[CuratorOctoFull.Length(out) + 1] = { string.format(L["Price: %s"], Rubies(sel.price, 12)), WHITE }
	end
	if CuratorOctoFull.Length((sel.asks or {})) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = { string.format(L["Barter: %s"], BarterText(sel.asks, sel.cp)), { 0.6, 0.9, 1 } }
	end
	out[CuratorOctoFull.Length(out) + 1] = { string.format(L["Seller: %s"], MK.Name(sel.seller)) .. "  ·  " .. MUI.Left(sel.ends), DIM }
	if sel.count > 1 then
		out[CuratorOctoFull.Length(out) + 1] = { string.format(L["%d alike on sale, from %s"], sel.count, Rubies(sel.from or sel.price or 0, 12)), DIM }
	end
	if sel.ac and MUI.ACCROCHES[sel.ac + 1] then
		out[CuratorOctoFull.Length(out) + 1] = { "\"" .. L[MUI.ACCROCHES[sel.ac + 1]] .. "\"", { 1, 0.86, 0.5 } }
	end
	local n = MK:News()
	local q = n and n.prices[MK.Spec(sel.it)]
	if q and q.median then
		out[CuratorOctoFull.Length(out) + 1] = { string.format(L["Median of 30 days: %s (%d sales)"], Rubies(q.median, 12), q.n), DIM }
	end
	out[CuratorOctoFull.Length(out) + 1] = { L["Right click: its sheet"], { 0.62, 0.62, 0.66 } }
	return out
end

-- The rank of a thing in the sort by rarity (the best first).
local function Rank(it)
	local card = MUI.Card(it)
	if card then
		return card.rarity * 10 + ((it.f == "h" and 3) or (it.f == "s" and 2) or 0)
	elseif it.k == "w" then
		return it.rank * 12 + ((it.f == "T" and 3) or (it.f == "t" and 2) or 0)
	elseif it.k == "d" then
		return 40
	elseif it.k == "b" then
		return 20
	end
	return 10
end
MUI.Rank = Rank

-- The selection, as the filters and the sort say.
function MUI:Selection()
	local n = MK:News()
	local F = self.f
	local p = self.frame and self.frame.pages.buy
	local text = p and string.lower(p.search:Text()) or ""
	local lo, hi = p and p.min:Get(), p and p.max:Get()
	local sellable = F.barter and MK:Sellable() or nil
	local out = {}
	for _, sel in ipairs(n and n.sel or {}) do
		local it = sel.it
		local card = MUI.Card(it)
		local keep = true
		if F.type ~= "all" and it.k ~= F.type then
			keep = false
		elseif F.album ~= "all" and not ((card and card.series and card.series.key == F.album) or it.series == F.album) then
			keep = false
		elseif F.rarity > 0 and not (card and card.rarity == F.rarity) then
			keep = false
		elseif (F.rank or 0) > 0 and not (it.k == "w" and it.rank == F.rank) then
			keep = false
		elseif F.finish ~= "all" and not ((it.k == "c" and it.f == F.finish) or (it.k == "w" and it.f == FINISH_CASE[F.finish])) then
			keep = false
		elseif (F.titan or "all") ~= "all" and not TitanOk(it, F.titan) then
			keep = false
		elseif F.grade ~= 0 and not GradeOk(it, F.grade) then
			keep = false
		elseif (F.restored or "all") ~= "all" and not ((it.k == "c" or it.k == "w") and Restored(it) == (F.restored == "yes")) then
			keep = false
		elseif not MUI.OfEdition(it, F.edition or "all") then
			keep = false
		elseif lo and (sel.price or 0) < lo then
			keep = false
		elseif hi and (sel.price or CuratorOctoFull.Huge) > hi then
			keep = false
		elseif F.missing and not (card and not C:Owned(card)) then
			keep = false
		elseif F.fav and not self:Favorite(MK.Spec(it)) then
			keep = false
		elseif F.barter and not (CuratorOctoFull.Length(sel.asks) > 0 and self:Givable(sel.asks, sellable)) then
			keep = false
		elseif text ~= "" and not string.find(string.lower(MUI.Title(it)), text, 1, true) then
			keep = false
		end
		if keep then
			out[CuratorOctoFull.Length(out) + 1] = sel
		end
	end
	local sort = self.sort or "rarity"
	table.sort(out, function(a, b)
		if sort == "price" then
			local pa, pb = a.price or CuratorOctoFull.Huge, b.price or CuratorOctoFull.Huge
			if pa ~= pb then
				return pa < pb
			end
		elseif sort == "new" then
			if a.id ~= b.id then
				return a.id > b.id
			end
		elseif sort == "ending" then
			if a.ends ~= b.ends then
				return a.ends < b.ends
			end
		else
			local ra, rb = Rank(a.it), Rank(b.it)
			if ra ~= rb then
				return ra > rb
			end
		end
		return a.id > b.id
	end)
	return out
end

-- Why the thing chosen cannot be bought now (nil: it can), and what is given for a barter.
function MUI:CanBuy(sel)
	local ok, why, extra = MK:CanUse()
	if not ok then
		return why, extra
	end
	if MK:Locked(sel.it) then
		return "unlock"
	end
	local barter = sel.price == nil
	local give = barter and self:Givable(sel.asks) or nil
	if barter and not give then
		return "give"
	end
	if not ns.Rubies:Has(barter and (sel.cp or 0) or sel.price) then
		return "rubies"
	end
	return nil, give
end

function MUI:PaintBuy()
	local f = self.frame
	local p = f and f.pages.buy
	if not (p and p:IsShown()) then
		return
	end
	local F = self.f
	Sync(p.type, F.type)
	Sync(p.album, F.album)
	Sync(p.rarity, F.type .. ":" .. F.rarity .. ":" .. (F.rank or 0))
	Sync(p.finish, F.finish)
	Sync(p.titan, F.titan)
	Sync(p.grade, F.grade)
	Sync(p.restored, F.restored)
	Sync(p.edition, F.edition)
	Sync(p.sort, self.sort)
	for _, h in ipairs(p.heads) do
		local c = (h.key and h.key == self.sort) and GOLD or WHITE
		h.text:SetTextColor(c[1], c[2], c[3])
	end
	local list = self:Selection()
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / BUY_ROWS))
	self.buyPage = math.min(math.max(1, self.buyPage or 1), pages)
	p.pager:Set(self.buyPage, pages, string.format(L["Page %d/%d"], self.buyPage, pages))
	CuratorOctoFull.SetShown(p.pager, pages > 1)
	local first = (self.buyPage - 1) * BUY_ROWS
	for i, r in ipairs(p.rows) do
		local sel = list[first + i]
		r.lst = sel
		if sel then
			r:Show()
			r.icon:SetTexture(MUI.Icon(sel.it))
			Fit(r.name, MUI.Title(sel.it, 2))
			Color(r.name, MUI.Color(sel.it))
			local price
			if sel.price then
				price = Rubies(sel.price, 11)
				if sel.count > 1 then
					price = string.format(L["x%d from %s"], sel.count, Rubies(sel.from or sel.price, 11))
				end
			else
				price = L["Barter"]
			end
			Fit(r.cols[1], price)
			Fit(r.cols[2], MK.Name(sel.seller))
			Fit(r.cols[3], MUI.Left(sel.ends))
			CuratorOctoFull.SetShown(r.star, self:Favorite(MK.Spec(sel.it)))
			r:SetSelected(self.chosen ~= nil and self.chosen.id == sel.id)
		else
			r:Hide()
		end
	end
	local n = MK:News()
	local all = n and CuratorOctoFull.Length((n.sel or {})) or 0
	if CuratorOctoFull.Length(list) == 0 then
		p.empty:SetText(all > 0 and L["Nothing on sale answers these filters."]
			or string.format(L["Nothing on sale in your selection yet. Every listing is on the website: %s"], SITE))
		p.empty:Show()
	else
		p.empty:Hide()
	end
	p.count:SetText(all > 0 and string.format(L["%d of %d in your selection (every listing: %s)"], CuratorOctoFull.Length(list), all, SITE) or "")
	-- (the one chosen: still in the selection, as the news say it now)
	local sel = self.chosen
	if sel then
		local now
		for _, x in ipairs(n and n.sel or {}) do
			if x.id == sel.id then
				now = x
			end
		end
		self.chosen, sel = now, now
	end
	CuratorOctoFull.SetShown(p.star, sel ~= nil)
	p.sheetBtn:SetEnabled(sel ~= nil)
	if not sel then
		S.Fit(p.info, L["Choose a thing in the list (right click: its sheet)."], 290, 12, 9)
		Color(p.info, DIM)
		p.buy:SetEnabled(false)
		p.buy:SetLabel(L["Buy"])
		local ok, why, extra = MK:CanUse()
		self:Why(p.why, (not ok and why ~= "closed") and why or nil, extra)
		return
	end
	p.star.tex:SetDesaturated(not self:Favorite(MK.Spec(sel.it)))
	S.Fit(p.info, MUI.Name(sel.it), 290, 12, 9)
	Color(p.info, MUI.Color(sel.it))
	local why, extra = self:CanBuy(sel)
	p.buy:SetEnabled(why == nil)
	p.buy:SetLabel(sel.price and string.format(L["Buy: %s"], Rubies(sel.price, 11)) or L["Barter"])
	if why then
		self:Why(p.why, why, extra)
	elseif sel.price == nil then
		local _, items = self:Givable(sel.asks)
		local names = {}
		for _, it in ipairs(items or {}) do
			names[CuratorOctoFull.Length(names) + 1] = MUI.Name(it)
		end
		p.why:SetText(string.format(L["You give: %s"], table.concat(names, " + ") .. ((sel.cp or 0) > 0 and (" + " .. Rubies(sel.cp, 10)) or "")))
		p.why:SetTextColor(0.6, 0.9, 1)
	else
		p.why:SetText("")
	end
end

-- The purchase of a listing (its price, or its barter: the plainest things that answer it).
function MUI:BuyChosen(sel)
	sel = sel or self.chosen
	if not sel then
		return
	end
	local why0, give = self:CanBuy(sel)
	if why0 then
		ns.Print(L[WHY[why0] or WHY.thing])
		return
	end
	local n, why = MK:Buy(sel, give)
	if n then
		ns.Play(ns.SND.coins)
		ns.Print(string.format(L["Bought: %s. It comes with the next mail of the Cartel (a quarter of an hour at most). Send now: the first to arrive wins."], MUI.Name(sel.it)))
		self.chosen = nil
		if self.sheet and self.sheet.sel == sel then
			self.sheet:Hide()
		end
	else
		ns.Print(L[WHY[why] or WHY.thing])
	end
	self:Paint()
end

-------------------------------------------------------------------------------
-- The sheet of a thing: its card, its story, the curve of its price, its purchase
-------------------------------------------------------------------------------
local SHEET_W, SHEET_H = 620, 470
local CURVE_W, CURVE_H = 330, 74

local function Hex(c)
	return string.format(("|cff%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- A card of a case as its record would be (UI/CaseDetail.lua draws it so): its grade hidden but its condition, unless
-- it was appraised.
function MUI.CrateRecord(it)
	local w = { c = it.edition, r = it.rank, f = CRATE_FIN[it.f], ot = it.ot, oh = it.oh, pt = it.pt }
	if it.weapon then
		w.w, w.l = it.weapon.item, it.weapon.line
		w.cl = it.weapon.cls ~= "" and it.weapon.cls or nil
		w.fa = it.weapon.side ~= "" and it.weapon.side or nil
	else
		w.e = it.entry
	end
	if it.ap then
		w.ap, w.g, w.m, w.ce, w.at = true, it.grade, it.ap.m, it.ap.ce, it.ap.at
	else
		local CS = ns.Cases
		local cond = CS and CS.CONDITION and CS.CONDITION[MK.Step(it.grade)]
		w.cw = cond and cond[2] or "Good"
		-- (31 October: its wear, the very one the seller sees: its grade, its seed from what never changes of it)
		w.grade = it.grade
	end
	return w
end

-- The label of the case of a copy of a card (its grade, its seal), as another player's card shows it.
function MUI.Slab(it)
	local card = MUI.Card(it)
	if not card then
		return nil
	end
	local E = ns.Expertise
	if it.seal then
		local SL = ns.Masters
		return {
			seal = true, grade = it.seal.rank, roman = SL.Roman(it.seal.rank), word = SL.Word(it.seal.rank), name = C:Name(card),
			album = C:SeriesName(card.series), num = string.format(("#%d/%d"), card.num or 0, CuratorOctoFull.Length((card.series and card.series.list or {}))),
			rarity = card.rarity, marks = E.DecodeMarks(it.seal.marks), cert = it.seal.pact, corrupt = it.cor,
			by = it.seal.master ~= "" and it.seal.master or nil, color = SL.Color(it.seal.rank),
		}
	end
	if it.g > 0 and it.sl ~= false then
		local info = E:LabelOf(card, it.g / 100, E.DecodeMarks(it.m), it.ce > 0 and it.ce or nil)
		if info and CuratorOctoFull.Length(it.r) > 0 then
			info.restored = {}
			for i, x in ipairs(it.r) do
				info.restored[i] = x[1] or 0
			end
		end
		return info
	end
	return nil
end

function MUI:BuildSheet()
	if self.sheet then
		return self.sheet
	end
	local w = S.Window("CuratorMarketSheet", SHEET_W, SHEET_H)
	w:SetFrameStrata("HIGH")
	w:SetToplevel(true)
	w:Hide()
	if w.SetPortraitToAsset then
		w:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Coin_17")
	end
	w:SetTitle(L["Steamwheedle Exchange"])
	S.DragBar(w, 22)
	tinsert(UISpecialFrames, "CuratorMarketSheet")
	local RX = 236
	w.name = S.Text(w, "GameFontNormalLarge", "LEFT")
	w.name:SetPoint("TOPLEFT", RX, -36)
	w.name:SetWidth(SHEET_W - RX - 24)
	w.name:SetWordWrap(false)
	w.sub = S.Text(w, "GameFontHighlightSmall", "LEFT")
	w.sub:SetPoint("TOPLEFT", w.name, "BOTTOMLEFT", 0, -4)
	w.sub:SetWidth(SHEET_W - RX - 24)
	w.sub:SetWordWrap(true)
	w.sub:SetMaxLines(2)
	-- (its card, on the left)
	w.holder = CreateFrame("Frame", nil, w)
	CuratorOctoFull.SetSize(w.holder, 200, 330)
	w.holder:SetPoint("TOPLEFT", 16, -60)
	w.card = ns.NewCard(w.holder, "big")
	w.card:SetPoint("BOTTOM", 0, 6)
	w.card:Hide()
	w.icon = w.holder:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(w.icon, 128, 128)
	w.icon:SetPoint("CENTER", 0, -20)
	w.icon:Hide()
	CuratorOctoFull.SetScript(w.card, "OnClick", nil)
	-- (its story, on the right)
	w.story = S.Text(w, "GameFontHighlightSmall", "LEFT")
	w.story:SetPoint("TOPLEFT", w.sub, "BOTTOMLEFT", 0, -10)
	w.story:SetWidth(SHEET_W - RX - 24)
	w.story:SetWordWrap(true)
	w.story:SetJustifyV("TOP")
	w.story:SetSpacing(3)
	w.line = S.Divider(w, SHEET_W - RX - 24, 0.6)
	w.line:SetPoint("TOPLEFT", w.story, "BOTTOMLEFT", 0, -10)
	w.offer = S.Text(w, "GameFontNormal", "LEFT")
	w.offer:SetPoint("TOPLEFT", w.line, "BOTTOMLEFT", 0, -10)
	w.offer:SetWidth(SHEET_W - RX - 24)
	w.offer:SetWordWrap(true)
	w.offer:SetJustifyV("TOP")
	w.offer:SetSpacing(3)
	-- (the curve of its price: the month of the sales alike)
	local cv = CreateFrame("Frame", nil, w)
	CuratorOctoFull.SetSize(cv, CURVE_W, CURVE_H)
	cv:SetPoint("BOTTOMLEFT", RX + 10, 58)
	cv.bg = cv:CreateTexture(nil, "BACKGROUND")
	cv.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(cv.bg, 0, 0, 0, 0.35)
	cv.median = cv:CreateTexture(nil, "ARTWORK")
	cv.median:SetHeight(1)
	CuratorOctoFull.ColorTexture(cv.median, GOLD[1], GOLD[2], GOLD[3], 0.55)
	cv.dots = {}
	cv.top = S.Text(cv, "GameFontDisableSmall", "LEFT")
	cv.top:SetPoint("BOTTOMLEFT", cv, "TOPLEFT", 0, 3)
	cv.left = S.Text(cv, "GameFontDisableSmall", "LEFT")
	cv.left:SetPoint("TOPLEFT", cv, "BOTTOMLEFT", 0, -3)
	cv.left:SetText(L["30 days ago"])
	cv.right = S.Text(cv, "GameFontDisableSmall", "RIGHT")
	cv.right:SetPoint("TOPRIGHT", cv, "BOTTOMRIGHT", 0, -3)
	cv.right:SetText(L["Today"])
	cv.none = S.Text(cv, "GameFontDisableSmall", "CENTER")
	cv.none:SetPoint("CENTER")
	cv.none:SetWidth(CURVE_W - 20)
	cv.none:SetWordWrap(true)
	w.curve = cv
	w.caption = S.Text(w, "GameFontHighlightSmall", "LEFT")
	w.caption:SetPoint("BOTTOMLEFT", cv, "TOPLEFT", 0, 16)
	w.caption:SetWidth(CURVE_W + 40)
	w.caption:SetWordWrap(false)
	-- (the purchase)
	w.buy = ArmButton(w, L["Buy"], 170, function()
		MUI:BuyChosen(w.sel)
	end)
	w.buy:SetPoint("BOTTOMRIGHT", -16, 16)
	w.why = S.Text(w, "GameFontHighlightSmall", "RIGHT")
	w.why:SetPoint("RIGHT", w.buy, "LEFT", -12, 0)
	w.why:SetWidth(300)
	w.why:SetWordWrap(false)
	w.star = CreateFrame("Button", nil, w)
	CuratorOctoFull.SetSize(w.star, 24, 24)
	w.star:SetPoint("BOTTOMLEFT", 20, 16)
	w.star.tex = w.star:CreateTexture(nil, "ARTWORK")
	w.star.tex:SetAllPoints()
	w.star.tex:SetTexture("Interface\\Common\\ReputationStar")
	w.star.tex:SetTexCoord(0, 0.5, 0, 0.5)
	w.star.label = S.Text(w.star, "GameFontNormalSmall", "LEFT")
	w.star.label:SetPoint("LEFT", w.star, "RIGHT", 4, 0)
	CuratorOctoFull.SetScript(w.star, "OnClick", function()
		if w.it then
			MUI:ToggleFavorite(w.it)
		end
	end)
	w.t = 0
	CuratorOctoFull.SetScript(w, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		if self.card:IsShown() and self.card.Tick then
			self.card:Tick(self.t)
		end
	end)
	CuratorOctoFull.SetScript(w, "OnHide", function(self)
		self.sel = nil
	end)
	self.sheet = w
	return w
end

-- The sheet of a thing (sel: its listing in the selection; nil: a thing of mine, its story and its prices only).
function MUI:Sheet(it, sel)
	if not it then
		return
	end
	local w = self:BuildSheet()
	w.it, w.sel = it, sel
	w:ClearAllPoints()
	local anchor = (self.frame and self.frame:IsVisible()) and (_G.AuctionFrame and _G.AuctionFrame:IsShown() and _G.AuctionFrame or self.win) or nil
	if anchor then
		w:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 0)
	else
		w:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
	w:Show()
	ns.Play(ns.SND.open)
	self:PaintSheet()
end

function MUI:PaintSheet()
	local w = self.sheet
	if not (w and w:IsShown() and w.it) then
		return
	end
	local it, sel = w.it, w.sel
	-- (a listing gone from the news: the sheet says so)
	if sel then
		local n = MK:News()
		local now
		for _, x in ipairs(n and n.sel or {}) do
			if x.id == sel.id then
				now = x
			end
		end
		w.sel, sel = now, now
		w.gone = now == nil
	else
		w.gone = false
	end
	local c = MUI.Color(it)
	w.name:SetText(MUI.Name(it))
	w.name:SetTextColor(c[1], c[2], c[3])
	local badges = MUI.Badges(it)
	w.sub:SetText(table.concat(badges, "  ·  "))
	-- its picture
	w.card:Hide()
	w.icon:Hide()
	if w.crate then
		w.crate:Hide()
	end
	if it.k == "c" and MUI.Card(it) then
		local card = MUI.Card(it)
		local opts = { owned = true, finish = FIN[it.f], corrupt = it.f == "c" and it.cor or nil, pattern = it.pt }
		local sig = MK.Pack(it)
		if w.card.sig ~= sig then
			w.card.sig = sig
			w.card:SetCard(card, opts)
			w.card:ShowSide("front")
			if w.card.SlabAlpha then
				w.card:SlabAlpha(1)
			end
			w.card:SetSlab(MUI.Slab(it))
			if w.card.Animate then
				w.card:Animate(w)
			end
		end
		w.card:Show()
	elseif it.k == "w" and ns.CrateCard and ns.CaseDetail then
		local CD = ns.CaseDetail
		if not w.crate then
			w.crate = ns.CrateCard.New(w.holder, ns.CARD_SIZES.big[1])
			w.crate:SetPoint("BOTTOM", 0, 6)
		end
		local rec = MUI.CrateRecord(it)
		local desc = CD.DescOf(rec)
		local sig = MK.Pack(it)
		if desc and w.crate.sig ~= sig then
			w.crate.sig = sig
			w.crate:Set(CD.PickOf(desc, rec), ns.CrateUI.RANKS)
			local def = ns.Crates and ns.Crates[rec.c]
			w.crate:SetBack(def and def.art and def.art.back or nil)
			w.crate:SetLive(true)
			w.crate:SlabAlpha(1)
			w.crate:SetSlab(rec.ap and CD.Label(desc, rec) or nil)
		end
		CuratorOctoFull.SetShown(w.crate, desc ~= nil)
	else
		w.icon:SetTexture(MUI.Icon(it))
		w.icon:Show()
	end
	-- its story
	local lines = {}
	for _, l in ipairs(MUI.Story(it)) do
		lines[CuratorOctoFull.Length(lines) + 1] = Hex(l[2]) .. l[1] .. "|r"
	end
	w.story:SetText(table.concat(lines, "\n"))
	-- the listing
	local offer = {}
	if sel then
		if sel.price then
			offer[CuratorOctoFull.Length(offer) + 1] = string.format(L["Price: %s"], Rubies(sel.price, 14))
		end
		if CuratorOctoFull.Length((sel.asks or {})) > 0 then
			offer[CuratorOctoFull.Length(offer) + 1] = Hex({ 0.6, 0.9, 1 }) .. string.format(L["Barter: %s"], BarterText(sel.asks, sel.cp)) .. "|r"
		end
		offer[CuratorOctoFull.Length(offer) + 1] = Hex(DIM) .. string.format(L["Seller: %s"], MK.Name(sel.seller)) .. "  ·  " .. string.format(L["Time left: %s"], MUI.Left(sel.ends)) .. "|r"
		if sel.ac and MUI.ACCROCHES[sel.ac + 1] then
			offer[CuratorOctoFull.Length(offer) + 1] = Hex({ 1, 0.86, 0.5 }) .. "\"" .. L[MUI.ACCROCHES[sel.ac + 1]] .. "\"|r"
		end
		if sel.count > 1 then
			offer[CuratorOctoFull.Length(offer) + 1] = Hex(DIM) .. string.format(L["%d alike on sale, from %s"], sel.count, Rubies(sel.from or sel.price or 0, 11)) .. "|r"
		end
	elseif w.gone then
		offer[CuratorOctoFull.Length(offer) + 1] = Hex(RED) .. L["This listing is no longer in the selection."] .. "|r"
	end
	w.offer:SetText(table.concat(offer, "\n"))
	CuratorOctoFull.SetShown(w.line, CuratorOctoFull.Length(offer) > 0)
	-- the curve of the month
	self:PaintCurve(it)
	-- the star, the purchase
	local fav = self:Favorite(MK.Spec(it))
	w.star.tex:SetDesaturated(not fav)
	w.star.label:SetText(fav and L["In your favorites"] or L["Add to your favorites"])
	CuratorOctoFull.SetShown(w.buy, sel ~= nil)
	if sel then
		local why, extra = self:CanBuy(sel)
		w.buy:SetEnabled(why == nil)
		w.buy:SetLabel(sel.price and string.format(L["Buy: %s"], Rubies(sel.price, 11)) or L["Barter"])
		if why then
			self:Why(w.why, why, extra)
		else
			w.why:SetText("")
		end
	else
		w.why:SetText("")
	end
end

-- The prices of the month of a thing alike (the news: q), as points over the days.
function MUI:PaintCurve(it)
	local w = self.sheet
	local cv = w.curve
	local n = MK:News()
	local q = n and n.prices[MK.Spec(it)]
	local unique = MK.Ident(it) == nil
	for _, d in ipairs(cv.dots) do
		d:Hide()
	end
	cv.median:Hide()
	cv.top:SetText("")
	if not (q and q.n > 0 and CuratorOctoFull.Length(q.pts) > 0) then
		cv.none:SetText(L["No sale alike these 30 days."])
		cv.none:Show()
		w.caption:SetText(string.format(L["Its value of reference: %s"], Rubies(MK:Ref(it), 11)))
		return
	end
	cv.none:Hide()
	local top = q.median or 0
	for _, pt in ipairs(q.pts) do
		top = math.max(top, pt[2])
	end
	top = math.max(1, top * 1.15)
	for i, pt in ipairs(q.pts) do
		local d = cv.dots[i]
		if not d then
			d = cv:CreateTexture(nil, "OVERLAY")
			CuratorOctoFull.SetSize(d, 6, 6)
			d:SetTexture("Interface\\Buttons\\WHITE8X8")
			cv.dots[i] = d
		end
		local x = (30 - math.min(30, math.max(0, pt[1]))) / 30 * (CURVE_W - 8) + 1
		local y = pt[2] / top * (CURVE_H - 8) + 1
		d:ClearAllPoints()
		d:SetPoint("BOTTOMLEFT", cv, "BOTTOMLEFT", x, y)
		d:SetVertexColor(1, 0.86, 0.4)
		d:Show()
	end
	if q.median then
		cv.median:ClearAllPoints()
		cv.median:SetPoint("BOTTOMLEFT", cv, "BOTTOMLEFT", 0, q.median / top * (CURVE_H - 8) + 4)
		cv.median:SetWidth(CURVE_W)
		cv.median:Show()
	end
	local highest = 0
	for _, pt in ipairs(q.pts) do
		highest = math.max(highest, pt[2])
	end
	cv.top:SetText(string.format(L["Highest: %s"], Rubies(highest, 10)))
	local text = string.format(L["Median of 30 days: %s (%d sales)"], Rubies(q.median or 0, 11), q.n)
	if unique then
		text = string.format(L["Copies alike without a story of their own: %s (%d sales)"], Rubies(q.median or 0, 11), q.n)
	end
	w.caption:SetText(text)
end

-------------------------------------------------------------------------------
-- Sell: everything that can go, the form of its listing; the buy orders open for what I have
-------------------------------------------------------------------------------
local SELL_ROWS = 8
local FX = 316 -- (the left of the form)
local FW = W - 16 - FX -- (its width)
local LW = 86 -- (its labels, on the left of its fields)
local CHIP_W = 114 -- (a thing a barter asks)

-- The things of the collection that can go, alike together: { it, srcs, n, key } (copies alike: one line, their count;
-- a booster, a display, a case: their count; a thing of a story of its own: a line each).
function MUI:Things()
	local out, by = {}, {}
	for _, x in ipairs(MK:Sellable()) do
		local id = MK.Ident(x.it)
		if (x.it.k == "c" or x.it.k == "w") and id then
			local g = by[id]
			if g then
				g.srcs[CuratorOctoFull.Length(g.srcs) + 1] = x.src
				g.n = g.n + 1
			else
				g = { it = x.it, srcs = { x.src }, n = 1, key = id }
				by[id] = g
				out[CuratorOctoFull.Length(out) + 1] = g
			end
		else
			out[CuratorOctoFull.Length(out) + 1] = { it = x.it, srcs = { x.src }, n = x.n or 1, key = x.pack }
		end
	end
	table.sort(out, function(a, b)
		local ka, kb = KIND_ORDER[a.it.k] or 9, KIND_ORDER[b.it.k] or 9
		if ka ~= kb then
			return ka < kb
		end
		local ra, rb = Rank(a.it), Rank(b.it)
		if ra ~= rb then
			return ra > rb
		end
		local na, nb = MUI.Name(a.it), MUI.Name(b.it)
		if na ~= nb then
			return na < nb
		end
		return a.key < b.key
	end)
	return out
end

-- The price a thing is offered at first: the median of the month (in its bounds), else its value of reference.
function MUI:FirstPrice(it)
	local ref = MK:Ref(it)
	local lo, hi = MK:Bounds(ref)
	local n = MK:News()
	local q = MK.Ident(it) and n and n.prices[MK.Spec(it)]
	local p = (q and q.median) or ref
	return math.max(lo, math.min(hi, p))
end

function MUI:BuildSell(f)
	local p = CreateFrame("Frame", nil, f)
	p:SetFrameLevel(f.bg:GetFrameLevel() + 2)
	p:SetPoint("TOPLEFT", f.bg, "TOPLEFT", 8, -8)
	p:SetPoint("BOTTOMRIGHT", f.bg, "BOTTOMRIGHT", -8, 8)
	p:Hide()
	self.sellMode = "things"
	self.sellType = "all"
	self.form = {}
	-- (the two lists: my things, the buy orders)
	p.tabThings = SubTab(p, 146)
	p.tabThings:SetPoint("TOPLEFT", 0, 0)
	CuratorOctoFull.SetScript(p.tabThings, "OnClick", function()
		MUI.sellMode, MUI.sellPage = "things", 1
		ns.Play(ns.SND.click)
		MUI:PaintSell()
	end)
	p.tabOrders = SubTab(p, 146)
	p.tabOrders:SetPoint("LEFT", p.tabThings, "RIGHT", 4, 0)
	CuratorOctoFull.SetScript(p.tabOrders, "OnClick", function()
		MUI.sellMode, MUI.sellPage = "orders", 1
		ns.Play(ns.SND.click)
		MUI:PaintSell()
	end)
	local function Again()
		MUI.sellPage = 1
		MUI:PaintSell()
	end
	p.search = EditBox(p, 146, false, 40, L["Search"], Again)
	p.search:SetPoint("TOPLEFT", 0, -26)
	p.type = SmallDrop(p, 146)
	p.type:SetPoint("LEFT", p.search, "RIGHT", 4, 0)
	Menu(p.type, TYPES, function() return MUI.sellType end, function(v) MUI.sellType = v Again() end)
	p.rows = {}
	for i = 1, SELL_ROWS do
		local i = i; local r = Row(p, 228, { { 30, "RIGHT" } })
		r:SetPoint("TOPLEFT", 0, -52 - (i - 1) * ROW_H)
		r:SetWidth(296)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			if self.thing then
				MUI:Tooltip(self, self.thing.it, self.thing.n > 1 and { { " " }, { string.format(L["%d of them can go"], self.thing.n), DIM } } or nil)
			elseif self.order then
				local o = self.order
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(L["Buy order"], 1, 1, 1)
				GameTooltip:AddLine(MUI.AskText(o.ask), GOLD[1], GOLD[2], GOLD[3], true)
				GameTooltip:AddLine(string.format(L["Pays: %s"], Rubies(o.price, 12)), 1, 1, 1)
				GameTooltip:AddLine(string.format(L["Buyer: %s"], MK.Name(o.buyer)) .. "  ·  " .. MUI.Left(o.ends), DIM[1], DIM[2], DIM[3])
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(r, "OnClick", function(self, button)
			if self.thing then
				MUI:ChooseThing(self.thing)
				if button == "RightButton" then
					MUI:Sheet(self.thing.it)
				end
			elseif self.order then
				MUI.sellOrder = self.order
				ns.Play(ns.SND.click)
				MUI:PaintSell()
			end
		end)
		p.rows[i] = r
	end
	p.empty = S.Text(p, "GameFontDisable", "CENTER")
	p.empty:SetPoint("TOPLEFT", 10, -100)
	p.empty:SetWidth(276)
	p.empty:SetWordWrap(true)
	p.pager = S.Pager(p)
	p.pager:SetPoint("BOTTOMLEFT", 229, 22)
	CuratorOctoFull.SetScript(p.pager.prev, "OnClick", function()
		MUI.sellPage = math.max(1, (MUI.sellPage or 1) - (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1))
		ns.Play(ns.SND.page)
		MUI:PaintSell()
	end)
	CuratorOctoFull.SetScript(p.pager.next, "OnClick", function()
		MUI.sellPage = (MUI.sellPage or 1) + (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1)
		ns.Play(ns.SND.page)
		MUI:PaintSell()
	end)
	p.count = S.Text(p, "GameFontDisableSmall", "LEFT")
	p.count:SetPoint("BOTTOMLEFT", 0, 4)
	p.count:SetWidth(296)
	p.count:SetWordWrap(true)
	p.split = p:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.ColorTexture(p.split, 1, 0.82, 0, 0.25)
	CuratorOctoFull.SetSize(p.split, 1, 286)
	p.split:SetPoint("TOPLEFT", FX - 10, -4)
	self:BuildForm(p)
	self:BuildFill(p)
	return p
end

-- The form of a listing (the thing chosen on the left).
function MUI:BuildForm(p)
	local fm = CreateFrame("Frame", nil, p)
	fm:SetPoint("TOPLEFT", FX, 0)
	fm:SetPoint("BOTTOMRIGHT", 0, 0)
	p.form = fm
	local F = self.form
	local function Again()
		MUI:PaintSell()
	end
	fm.name = S.Text(fm, "GameFontNormalLarge", "LEFT")
	fm.name:SetPoint("TOPLEFT", 0, 0)
	fm.name:SetWidth(FW - 30)
	fm.name:SetWordWrap(false)
	fm.badges = S.Text(fm, "GameFontHighlightSmall", "LEFT")
	fm.badges:SetPoint("TOPLEFT", 0, -20)
	fm.badges:SetWidth(FW - 30)
	fm.badges:SetWordWrap(false)
	fm.sheet = CreateFrame("Button", nil, fm)
	CuratorOctoFull.SetSize(fm.sheet, 22, 22)
	fm.sheet:SetPoint("TOPRIGHT", 0, 2)
	fm.sheet.tex = fm.sheet:CreateTexture(nil, "ARTWORK")
	fm.sheet.tex:SetAllPoints()
	fm.sheet.tex:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
	CuratorOctoFull.SetScript(fm.sheet, "OnClick", function()
		local g = MUI:ChosenThing()
		if g then
			MUI:Sheet(g.it)
		end
	end)
	CuratorOctoFull.SetScript(fm.sheet, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Its sheet"], 1, 1, 1)
		GameTooltip:AddLine(L["Its story and the prices of the month of the things alike."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(fm.sheet, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- its price
	fm.priceL = Label(fm, L["Price"])
	fm.priceL:SetPoint("TOPLEFT", 0, -50)
	fm.price = EditBox(fm, 110, true, 9, L["rubies"], function(_, user)
		if user then
			F.p = fm.price:Get()
			MUI:PaintForm()
		end
	end)
	fm.price:SetPoint("TOPLEFT", LW, -44)
	fm.only = S.Check(fm, L["Barter only"])
	fm.only:SetPoint("LEFT", fm.price, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(fm.only, "OnClick", function(self)
		F.only = self:GetChecked() and true or false
		ns.Play(ns.SND.click)
		MUI:PaintForm()
	end)
	fm.ref = S.Text(fm, "GameFontDisableSmall", "LEFT")
	fm.ref:SetPoint("TOPLEFT", 0, -72)
	fm.ref:SetWidth(FW)
	fm.ref:SetWordWrap(false)
	-- its days, its fee
	fm.daysL = Label(fm, L["Duration"])
	fm.daysL:SetPoint("TOPLEFT", 0, -98)
	fm.days = SmallDrop(fm, 190)
	fm.days:SetPoint("TOPLEFT", LW, -92)
	Menu(fm.days, function()
		local g = MUI:ChosenThing()
		local base = g and ((not F.only and F.p) or MK:Ref(g.it)) or nil
		return DayList(base)
	end, function() return F.d end, function(v) F.d = v MUI:PaintForm() end)
	fm.fee = S.Text(fm, "GameFontHighlightSmall", "LEFT")
	fm.fee:SetPoint("LEFT", fm.days, "RIGHT", 10, 0)
	fm.fee:SetWidth(FW - LW - 200)
	fm.fee:SetWordWrap(true)
	-- a barter: what it asks (three things at most), the rubies more
	fm.barterL = Label(fm, L["Barter"])
	fm.barterL:SetPoint("TOPLEFT", 0, -126)
	fm.chips = {}
	for i = 1, MK.ASKS do
		local i = i; local b = S.Button(fm, "", CHIP_W, 20)
		b:SetPoint("TOPLEFT", LW + (i - 1) * (CHIP_W + 4), -122)
		b.label:SetWordWrap(false)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			CuratorOctoFull.Remove(F.asks, i)
			ns.Play(ns.SND.click)
			MUI:PaintForm()
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			local a = F.asks[i]
			if a then
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:AddLine(MUI.AskText(a), 1, 1, 1, true)
				GameTooltip:AddLine(L["Click: no longer ask for it."], 0.85, 0.85, 0.85, true)
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		fm.chips[i] = b
	end
	fm.ask = S.Button(fm, L["Ask for..."], CHIP_W, 20)
	CuratorOctoFull.SetScript(fm.ask, "OnClick", function()
		MUI:Pick(L["What do you ask for it?"], function(spec)
			local a = MK.ReadAsk(spec)
			if a and CuratorOctoFull.Length(F.asks) < MK.ASKS then
				F.asks[CuratorOctoFull.Length(F.asks) + 1] = a
			end
			MUI:PaintForm()
		end)
	end)
	fm.cpL = Label(fm, L["and"], "GameFontHighlightSmall")
	fm.cpL:SetPoint("TOPLEFT", LW, -152)
	fm.cp = EditBox(fm, 100, true, 9, L["rubies more"], function(_, user)
		if user then
			F.cp = fm.cp:Get()
			MUI:PaintForm()
		end
	end)
	fm.cp:SetPoint("TOPLEFT", LW + 32, -146)
	-- its line, several at once
	fm.acL = Label(fm, L["Its line"])
	fm.acL:SetPoint("TOPLEFT", 0, -180)
	fm.ac = SmallDrop(fm, 230)
	fm.ac:SetPoint("TOPLEFT", LW, -174)
	Menu(fm.ac, function()
		local out = { { key = -1, text = L["No line"] } }
		for i, t in ipairs(MUI.ACCROCHES) do
			out[CuratorOctoFull.Length(out) + 1] = { key = i - 1, text = "\"" .. L[t] .. "\"" }
		end
		return out
	end, function() return F.ac or -1 end, function(v) F.ac = v >= 0 and v or nil MUI:PaintForm() end)
	fm.countL = Label(fm, L["How many"])
	fm.countL:SetPoint("TOPLEFT", 0, -208)
	fm.count = EditBox(fm, 50, true, 3, "1", function(_, user)
		if user then
			F.count = fm.count:Get()
			MUI:PaintForm()
		end
	end)
	fm.count:SetPoint("TOPLEFT", LW, -202)
	fm.of = S.Text(fm, "GameFontHighlightSmall", "LEFT")
	fm.of:SetPoint("LEFT", fm.count, "RIGHT", 8, 0)
	-- what it gives, why not, the button
	fm.get = S.Text(fm, "GameFontHighlightSmall", "LEFT")
	fm.get:SetPoint("BOTTOMLEFT", 0, 54)
	fm.get:SetWidth(FW)
	fm.get:SetWordWrap(false)
	fm.why = S.Text(fm, "GameFontHighlightSmall", "LEFT")
	fm.why:SetPoint("BOTTOMLEFT", 0, 26)
	fm.why:SetWidth(FW)
	fm.why:SetWordWrap(true)
	fm.why:SetMaxLines(2)
	fm.list = ArmButton(fm, L["Put on sale"], 200, function()
		MUI:ListChosen()
	end)
	fm.list:SetPoint("BOTTOMRIGHT", 0, 0)
	fm.none = S.Text(fm, "GameFontDisable", "CENTER")
	fm.none:SetPoint("TOPLEFT", 20, -100)
	fm.none:SetWidth(FW - 40)
	fm.none:SetWordWrap(true)
	fm.none:SetText(L["Choose on the left what you put on sale. Its price stays in its bounds; the fee of its days is paid now, given back if it sells."])
	return fm
end

-- The form to sell to a buy order (the order chosen on the left).
function MUI:BuildFill(p)
	local fo = CreateFrame("Frame", nil, p)
	fo:SetPoint("TOPLEFT", FX, 0)
	fo:SetPoint("BOTTOMRIGHT", 0, 0)
	fo:Hide()
	p.fill = fo
	fo.title = S.Text(fo, "GameFontNormalLarge", "LEFT")
	fo.title:SetPoint("TOPLEFT", 0, 0)
	fo.title:SetWidth(FW)
	fo.title:SetWordWrap(false)
	fo.text = S.Text(fo, "GameFontHighlight", "LEFT")
	fo.text:SetPoint("TOPLEFT", 0, -28)
	fo.text:SetWidth(FW)
	fo.text:SetWordWrap(true)
	fo.text:SetJustifyV("TOP")
	fo.text:SetSpacing(4)
	fo.why = S.Text(fo, "GameFontHighlightSmall", "LEFT")
	fo.why:SetPoint("BOTTOMLEFT", 0, 28)
	fo.why:SetWidth(FW)
	fo.why:SetWordWrap(false)
	fo.go = ArmButton(fo, L["Sell to this order"], 200, function()
		MUI:FillChosen()
	end)
	fo.go:SetPoint("BOTTOMRIGHT", 0, 0)
	fo.none = S.Text(fo, "GameFontDisable", "CENTER")
	fo.none:SetPoint("TOPLEFT", 20, -100)
	fo.none:SetWidth(FW - 40)
	fo.none:SetWordWrap(true)
	fo.none:SetText(L["The buy orders of the other players for what you have: choose one on the left, the plainest of your copies that answers it goes."])
	return fo
end

-- The thing chosen on the left (nil: none, or gone since).
function MUI:ChosenThing()
	local key = self.sellKey
	if not key then
		return nil
	end
	for _, g in ipairs(self.things or {}) do
		if g.key == key then
			return g
		end
	end
	return nil
end

-- A thing chosen to sell: its form as it should start (pre: a listing of before, its price and its days).
function MUI:ChooseThing(g, pre)
	self.sellKey = g.key
	local F = self.form
	F.p = (pre and pre.p) or self:FirstPrice(g.it)
	F.only = pre ~= nil and pre.p == nil and CuratorOctoFull.Length((pre.tr or {})) > 0
	F.d = (pre and pre.d) or DefaultDays()
	F.asks = {}
	for _, a in ipairs(pre and pre.tr or {}) do
		local x = type(a) == "string" and MK.ReadAsk(a) or a
		if x then
			F.asks[CuratorOctoFull.Length(F.asks) + 1] = x
		end
	end
	F.cp = pre and pre.cp or nil
	F.ac = pre and pre.ac or nil
	F.count = 1
	ns.Play(ns.SND.click)
	local fm = self.frame and self.frame.pages.sell.form
	if fm then
		fm.price:Set(F.p)
		fm.cp:Set(F.cp)
		fm.count:Set(1)
		fm.only:SetChecked(F.only)
		fm.list:Disarm()
	end
	self:PaintSell()
end

-- What the form asks, as MK:List takes it; and why it cannot go (nil: it can), with what to say.
function MUI:FormOpts(g)
	local F = self.form
	local it = g.it
	local ref = MK:Ref(it)
	local lo, hi = MK:Bounds(ref)
	local opts = { p = (not F.only) and F.p or nil, d = F.d, ac = F.ac }
	if CuratorOctoFull.Length(F.asks) > 0 then
		opts.tr = {}
		for i, a in ipairs(F.asks) do
			opts.tr[i] = MK.AskText(a)
		end
		opts.cp = F.cp
	end
	local ok, why, extra = MK:CanUse()
	if not ok then
		return opts, why, extra
	end
	if ref <= 0 then
		return opts, "thing"
	end
	if F.only and CuratorOctoFull.Length(F.asks) == 0 then
		return opts, "barter0"
	end
	if not F.only and not F.p then
		return opts, "price0"
	end
	if opts.p and (opts.p < lo or opts.p > hi) then
		return opts, "bounds", string.format(L["From %s to %s."], Rubies(lo, 10), Rubies(hi, 10))
	end
	if CuratorOctoFull.Length(F.asks) > 0 then
		local asked = F.cp or 0
		for _, a in ipairs(F.asks) do
			asked = asked + MK:RefAsk(a)
		end
		if asked < lo or asked > hi then
			return opts, "asks2", string.format(L["What it asks is worth %s: from %s to %s."], Rubies(asked, 10), Rubies(lo, 10), Rubies(hi, 10))
		end
	end
	local count = math.max(1, math.min(g.n, F.count or 1))
	local fee = MK:Fee(opts.p or ref, F.d) or 0
	if MK:Active() + count > MK:Rules().listingsMax then
		return opts, "limit"
	end
	if not ns.Rubies:Has(fee * count) then
		return opts, "rubies"
	end
	return opts, nil, nil, fee, count
end

local FORM_WHY = {
	barter0 = "A barter asks for something: Ask for...",
	price0 = "Its price: in rubies.",
	bounds = "A price out of its bounds.",
	asks2 = "What the barter asks is out of the bounds of the thing.",
}

function MUI:PaintSell()
	local f = self.frame
	local p = f and f.pages.sell
	if not (p and p:IsShown()) then
		return
	end
	local n = MK:News()
	local orders = n and n.orders or {}
	p.tabThings:Paint(self.sellMode == "things", L["My things"])
	p.tabOrders:Paint(self.sellMode == "orders", CuratorOctoFull.Length(orders) > 0 and string.format(L["Buy orders (%d)"], CuratorOctoFull.Length(orders)) or L["Buy orders"])
	Sync(p.type, self.sellType)
	local text = string.lower(p.search:Text())
	local list = {}
	if self.sellMode == "orders" then
		local sellable = MK:Sellable()
		for _, o in ipairs(orders) do
			if text == "" or string.find(string.lower(MUI.AskText(o.ask)), text, 1, true) then
				list[CuratorOctoFull.Length(list) + 1] = { order = o, can = self:Givable({ o.ask }, sellable) ~= nil }
			end
		end
	else
		self.things = self:Things()
		for _, g in ipairs(self.things) do
			if (self.sellType == "all" or g.it.k == self.sellType) and (text == "" or string.find(string.lower(MUI.Title(g.it)), text, 1, true)) then
				list[CuratorOctoFull.Length(list) + 1] = g
			end
		end
	end
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / SELL_ROWS))
	self.sellPage = math.min(math.max(1, self.sellPage or 1), pages)
	p.pager:Set(self.sellPage, pages, string.format(L["Page %d/%d"], self.sellPage, pages))
	CuratorOctoFull.SetShown(p.pager, pages > 1)
	local first = (self.sellPage - 1) * SELL_ROWS
	for i, r in ipairs(p.rows) do
		local x = list[first + i]
		r.thing, r.order = nil, nil
		if not x then
			r:Hide()
		elseif x.order then
			local o = x.order
			r.order = o
			r:Show()
			r.name:SetWidth(178)
			r.cols[1]:ClearAllPoints()
			r.cols[1]:SetPoint("RIGHT", -4, 0)
			r.cols[1]:SetWidth(80)
			r.icon:SetTexture(MUI.Icon({ k = o.ask.k, npc = o.ask.npc, series = o.ask.series, edition = o.ask.edition }))
			r.icon:SetDesaturated(not x.can)
			Fit(r.name, MUI.AskText(o.ask))
			Color(r.name, x.can and GOLD or DIM)
			Fit(r.cols[1], Rubies(o.price, 10))
			r:SetSelected(self.sellOrder ~= nil and self.sellOrder.id == o.id)
		else
			r.thing = x
			r:Show()
			r.name:SetWidth(228)
			r.cols[1]:ClearAllPoints()
			r.cols[1]:SetPoint("RIGHT", -4, 0)
			r.cols[1]:SetWidth(30)
			r.icon:SetTexture(MUI.Icon(x.it))
			r.icon:SetDesaturated(false)
			Fit(r.name, MUI.Title(x.it, 2))
			Color(r.name, MUI.Color(x.it))
			Fit(r.cols[1], x.n > 1 and ("x" .. x.n) or "")
			r:SetSelected(self.sellKey == x.key)
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		p.empty:SetText(self.sellMode == "orders" and L["No buy order open for what you have."] or L["Nothing of your collection can go now."])
		p.empty:Show()
	else
		p.empty:Hide()
	end
	if self.sellMode == "orders" then
		p.count:SetText("")
		p.form:Hide()
		p.fill:Show()
		self:PaintFill()
	else
		local total = 0
		for _, g in ipairs(self.things or {}) do
			total = total + g.n
		end
		p.count:SetText(string.format(L["%d things can go  ·  %d of %d listings at once"], total, MK:Active(), MK:Rules().listingsMax))
		p.fill:Hide()
		p.form:Show()
		self:PaintForm()
	end
end

function MUI:PaintForm()
	local fm = self.frame and self.frame.pages.sell.form
	if not (fm and fm:IsShown()) then
		return
	end
	local g = self:ChosenThing()
	local F = self.form
	local parts = { fm.name, fm.badges, fm.sheet, fm.priceL, fm.price, fm.only, fm.ref, fm.daysL, fm.days, fm.fee, fm.barterL,
		fm.ask, fm.cpL, fm.cp, fm.acL, fm.ac, fm.countL, fm.count, fm.of, fm.get, fm.why, fm.list }
	for _, x in ipairs(parts) do
		CuratorOctoFull.SetShown(x, g ~= nil)
	end
	for _, b in ipairs(fm.chips) do
		CuratorOctoFull.SetShown(b, false)
	end
	CuratorOctoFull.SetShown(fm.none, g == nil)
	if not g then
		return
	end
	local it = g.it
	fm.name:SetText(MUI.Name(it))
	Color(fm.name, MUI.Color(it))
	fm.badges:SetText(table.concat(MUI.Badges(it), "  ·  "))
	local ref = MK:Ref(it)
	local lo, hi = MK:Bounds(ref)
	local n = MK:News()
	local q = n and n.prices[MK.Spec(it)]
	local refText = string.format(L["Reference %s  ·  from %s to %s"], Rubies(ref, 10), Rubies(lo, 10), Rubies(hi, 10))
	if q and q.median then
		refText = refText .. "  ·  " .. string.format(L["median %s (%d sales)"], Rubies(q.median, 10), q.n)
	end
	-- (what the reseller would give for it)
	local RV = ns.Reseller
	local card = MUI.Card(it)
	if card and it.f ~= "c" and RV and RV.Offer then
		refText = refText .. "  ·  " .. string.format(L["reseller %s"], Rubies(RV:Offer(card, FIN[it.f] or "normal"), 10))
	end
	S.Fit(fm.ref, refText, FW, 10, 7.5)
	fm.price:SetAlpha(F.only and 0.4 or 1)
	fm.price.eb:SetEnabled(not F.only)
	local base = (not F.only and F.p) or ref
	-- (the fee of each duration told in its menu: said again when the price changes)
	Sync(fm.days, tostring(F.d) .. ":" .. tostring(base))
	local fee = MK:Fee(base, F.d) or 0
	fm.fee:SetText(string.format(L["Fee %s, given back if it sells"], Rubies(fee, 10)))
	-- the barter
	for i, b in ipairs(fm.chips) do
		local a = F.asks[i]
		CuratorOctoFull.SetShown(b, a ~= nil)
		if a then
			b:SetText(MUI.AskText(a))
		end
	end
	fm.ask:ClearAllPoints()
	fm.ask:SetPoint("TOPLEFT", LW + CuratorOctoFull.Length(F.asks) * (CHIP_W + 4), -122)
	CuratorOctoFull.SetShown(fm.ask, CuratorOctoFull.Length(F.asks) < MK.ASKS)
	CuratorOctoFull.SetShown(fm.cp, CuratorOctoFull.Length(F.asks) > 0)
	CuratorOctoFull.SetShown(fm.cpL, CuratorOctoFull.Length(F.asks) > 0)
	Sync(fm.ac, F.ac or -1)
	-- several at once
	CuratorOctoFull.SetShown(fm.count, g.n > 1)
	CuratorOctoFull.SetShown(fm.countL, g.n > 1)
	CuratorOctoFull.SetShown(fm.of, g.n > 1)
	fm.of:SetText(string.format(L["of %d"], g.n))
	local count = math.max(1, math.min(g.n, F.count or 1))
	-- what a sale gives
	local get = {}
	if not F.only and F.p then
		get[CuratorOctoFull.Length(get) + 1] = string.format(L["Sold: you get %s (the share of the Cartel: %d %%)"], Rubies(MK:Net(F.p), 10), MK:Rules().commission)
	end
	if CuratorOctoFull.Length(F.asks) > 0 then
		get[CuratorOctoFull.Length(get) + 1] = L["Bartered: what it asks"] .. ((F.cp or 0) > 0 and (" + " .. Rubies(MK:Net(F.cp), 10)) or "")
	end
	fm.get:SetText(table.concat(get, "  ·  "))
	local _, why, extra, fee2 = self:FormOpts(g)
	fm.list:SetEnabled(why == nil)
	local label = count > 1 and string.format(L["Put %d on sale"], count) or L["Put on sale"]
	fm.list:SetLabel(label .. "  (" .. Rubies((fee2 or fee) * count, 10) .. ")")
	if why and FORM_WHY[why] then
		fm.why:SetText(L[FORM_WHY[why]] .. (extra and ("  " .. extra) or ""))
		fm.why:SetTextColor(RED[1], RED[2], RED[3])
	else
		self:Why(fm.why, why, extra)
	end
end

-- The thing chosen put on sale (so many at once): each its own listing, each its fee.
function MUI:ListChosen()
	local g = self:ChosenThing()
	if not g then
		return
	end
	local opts, why = self:FormOpts(g)
	if why then
		ns.Print(L[FORM_WHY[why] or WHY[why] or WHY.thing])
		return
	end
	local count = math.max(1, math.min(g.n, self.form.count or 1))
	local done, err = 0, nil
	for i = 1, count do
		local src = (g.it.k == "c" or g.it.k == "w") and g.srcs[i] or g.srcs[1]
		local n, w = MK:List(src, opts)
		if not n then
			err = w
			break
		end
		done = done + 1
	end
	if done > 0 then
		ns.Play(ns.SND.coins)
		ns.Print((done > 1 and string.format(L["%d put on sale: %s."], done, MUI.Name(g.it)) or string.format(L["Put on sale: %s."], MUI.Name(g.it)))
			.. " " .. L["It goes to the Exchange with your next save: Send now."])
		self.sellKey = nil
	end
	if err then
		ns.Print(L[WHY[err] or WHY.thing])
	end
	self:Paint()
end

function MUI:PaintFill()
	local fo = self.frame and self.frame.pages.sell.fill
	if not fo then
		return
	end
	local o = self.sellOrder
	if o then
		local now
		local n = MK:News()
		for _, x in ipairs(n and n.orders or {}) do
			if x.id == o.id then
				now = x
			end
		end
		self.sellOrder, o = now, now
	end
	CuratorOctoFull.SetShown(fo.none, o == nil)
	CuratorOctoFull.SetShown(fo.title, o ~= nil)
	CuratorOctoFull.SetShown(fo.text, o ~= nil)
	CuratorOctoFull.SetShown(fo.go, o ~= nil)
	CuratorOctoFull.SetShown(fo.why, o ~= nil)
	if not o then
		return
	end
	fo.title:SetText(string.format(L["Buy order of %s"], MK.Name(o.buyer)))
	local give, items = self:Givable({ o.ask })
	local lines = {
		string.format(L["Wants: %s"], MUI.AskText(o.ask)),
		string.format(L["Pays: %s"], Rubies(o.price, 12)) .. "  ·  " .. string.format(L["Time left: %s"], MUI.Left(o.ends)),
		string.format(L["You get: %s (the share of the Cartel: %d %%)"], Rubies(MK:Net(o.price), 12), MK:Rules().commission),
	}
	if items and items[1] then
		lines[CuratorOctoFull.Length(lines) + 1] = Hex({ 0.6, 0.9, 1 }) .. string.format(L["You give: %s"], MUI.Title(items[1])) .. "|r"
	end
	fo.text:SetText(table.concat(lines, "\n"))
	local ok, why, extra = MK:CanUse()
	if ok and not give then
		ok, why = false, "give"
	end
	fo.go:SetEnabled(ok)
	self:Why(fo.why, not ok and why or nil, extra)
end

function MUI:FillChosen()
	local o = self.sellOrder
	if not o then
		return
	end
	local give = self:Givable({ o.ask })
	if not give then
		ns.Print(L[WHY.give])
		return
	end
	local n, why = MK:Fill(o, give[1])
	if n then
		ns.Play(ns.SND.coins)
		ns.Print(string.format(L["Sold to the order of %s: it goes with your next save (Send now). The first to arrive wins."], MK.Name(o.buyer)))
		self.sellOrder = nil
	else
		ns.Print(L[WHY[why] or WHY.thing])
	end
	self:Paint()
end

-------------------------------------------------------------------------------
-- My sales, my purchases: what is in deposit, on the way, and what happened
-------------------------------------------------------------------------------
local LIST_ROWS = 9
local STATE = {
	online = { "Online", GREEN }, hidden = { "Hidden for now", { 1, 0.6, 0.2 } }, waiting = { "Not sent yet", DIM },
	withdraw = { "Withdrawal asked", GOLD }, price = { "New price asked", GOLD },
}
local STATE_TIP = {
	online = "In the selection of the players.",
	hidden = "The website keeps it out of the selection for now (a save to check, a collection under watch): it comes back as soon as all is well.",
	waiting = "The website has not seen it yet: it goes with your next save (Send now).",
	withdraw = "It goes with your next save: the website gives it back if nobody bought it before.",
	price = "It goes with your next save: the website lowers its price if nobody bought it before.",
}
-- (why the website gave a thing back, refused it, refunded a purchase)
local SITE_WHY = {
	closed = "the Exchange was closed", kind = "a thing the Exchange does not take", price = "a price out of its bounds",
	fee = "its fee was not right", limit = "too many listings at once", rules = "the rules had changed",
	pair = "five sales a week between two players at most", self = "between two of your collections", gone = "sold before",
	day = "enough purchases for the day", cap = "enough displays for the week", e = "its time was over", w = "withdrawn",
	x = "taken back by the Exchange", f = "a ban",
}
local EVENT = {
	listed = "Listed", sold = "Sold to %s", back = "Came back", refused = "Refused", bought = "Bought from %s",
	refund = "Refunded", ordered = "Buy order placed", unfilled = "Buy order over",
}
MUI.STATE = STATE
local SELLER_EVENTS = { listed = true, sold = true, back = true, refused = true }
local BUYER_EVENTS = { bought = true, refund = true, ordered = true, unfilled = true }

-- A list of rows on a page (top: where it starts; cols: after the name).
local function Rows(p, top, nameW, cols, onClick, onEnter)
	local rows = {}
	for i = 1, LIST_ROWS do
		local i = i; local r = Row(p, nameW, cols)
		r:SetPoint("TOPLEFT", 0, top - (i - 1) * ROW_H)
		r:SetWidth(W - 16)
		CuratorOctoFull.SetScript(r, "OnClick", function(self, button)
			if self.x then
				onClick(self.x, button)
			end
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			if self.x and onEnter then
				onEnter(self, self.x)
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		rows[i] = r
	end
	return rows
end

-- A pager under a list (get/set: its page).
local function ListPager(p, paint, get, set)
	local pg = S.Pager(p)
	pg:SetPoint("BOTTOMRIGHT", 0, 28)
	CuratorOctoFull.SetScript(pg.prev, "OnClick", function()
		set(math.max(1, get() - (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1)))
		ns.Play(ns.SND.page)
		paint()
	end)
	CuratorOctoFull.SetScript(pg.next, "OnClick", function()
		set(get() + (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1))
		ns.Play(ns.SND.page)
		paint()
	end)
	return pg
end

-- The listings of mine in deposit: { n, l, it, price, state, ends }.
function MUI:Deposit()
	local m = MK:Db()
	local out = {}
	for n, l in pairs(m and m.ls or {}) do
		local st, s = MK:StateOf(n)
		local state = (m.wd[n] and "withdraw") or (m.pc[n] and "price") or st
		out[CuratorOctoFull.Length(out) + 1] = { n = n, l = l, it = MK.Unpack(l.it), price = MK:PriceOf(n), state = state, ends = s and s.ends }
	end
	table.sort(out, function(a, b)
		return a.n > b.n
	end)
	return out
end

-- The buy orders of mine: { n, o, ask, price, state, ends }.
function MUI:Orders()
	local m = MK:Db()
	local out = {}
	for n, o in pairs(m and m.od or {}) do
		local st, s = MK:StateOf(n, true)
		out[CuratorOctoFull.Length(out) + 1] = { n = n, o = o, ask = MK.ReadAsk(o.k), price = o.p, state = m.wd[n] and "withdraw" or st, ends = s and s.ends }
	end
	table.sort(out, function(a, b)
		return a.n > b.n
	end)
	return out
end

-- The purchases on their way: { n, b, it, paid }.
function MUI:OnTheWay()
	local m = MK:Db()
	local out = {}
	for n, b in pairs(m and m.bu or {}) do
		out[CuratorOctoFull.Length(out) + 1] = { n = n, b = b, it = MK.Unpack(b.it or ""), paid = b.p }
	end
	for n, x in pairs(m and m.fl or {}) do
		out[CuratorOctoFull.Length(out) + 1] = { n = n, fill = x, it = MK.Unpack(x.it or ""), paid = x.p }
	end
	table.sort(out, function(a, b)
		return a.n > b.n
	end)
	return out
end

-- What happened (kinds: SELLER_EVENTS or BUYER_EVENTS), the newest first.
function MUI:History(kinds)
	local m = MK:Db()
	local out = {}
	for i = CuratorOctoFull.Length((m and m.h or {})), 1, -1 do
		local h = m.h[i]
		if type(h) == "table" and kinds[h.k] then
			out[CuratorOctoFull.Length(out) + 1] = h
		end
	end
	return out
end

-- An event in words: its line, the rubies it moved (+ in, - out), its colour.
function MUI.Event(h)
	local what = L[EVENT[h.k] or h.k]
	if h.k == "sold" or h.k == "bought" then
		what = string.format(what, h.w or "?")
	elseif (h.k == "back" or h.k == "refused" or h.k == "refund" or h.k == "unfilled") and h.w and SITE_WHY[h.w] then
		what = what .. ": " .. L[SITE_WHY[h.w]]
	end
	local p = tonumber(h.p)
	local money, col = "", WHITE
	if h.k == "sold" or h.k == "refund" or h.k == "unfilled" then
		money, col = p and p > 0 and ("+" .. Rubies(p, 10)) or "", GREEN
	elseif h.k == "bought" or h.k == "ordered" then
		money, col = p and p > 0 and ("-" .. Rubies(p, 10)) or "", WHITE
	elseif h.k == "listed" then
		money = p and Rubies(p, 10) or L["Barter"]
	elseif h.k == "back" or h.k == "refused" then
		col = { 1, 0.6, 0.2 }
	end
	return what, money, col
end

-- The thing of an event (a thing, or what an order asked).
local function EventThing(h)
	if h.k == "ordered" or h.k == "unfilled" then
		local a = MK.ReadAsk(h.it or "")
		return nil, a
	end
	return MK.Unpack(h.it or ""), nil
end

-- The thing of an event come back, among the things that can go now (nil: no longer there).
function MUI:BackThing(h)
	local it = MK.Unpack(h.it or "")
	if not it then
		return nil
	end
	local key = MK.Ident(it)
	key = ((it.k == "c" or it.k == "w") and key) or (key == nil and h.it) or MK.Pack(it)
	for _, g in ipairs(self:Things()) do
		if g.key == key then
			return g
		end
	end
	return nil
end

-- The price it was put on sale at last (its history).
function MUI:LastListed(pack)
	for _, h in ipairs(self:History({ listed = true })) do
		if h.it == pack then
			return h.p
		end
	end
	return nil
end

-- A thing come back on the page Sell, chosen, its price of before.
function MUI:Relist(h)
	local g = self:BackThing(h)
	if not g then
		return
	end
	self:Page("sell")
	self.sellMode = "things"
	self:ChooseThing(g, { p = self:LastListed(h.it) })
end

function MUI:BuildMine(f)
	local p = CreateFrame("Frame", nil, f)
	p:SetFrameLevel(f.bg:GetFrameLevel() + 2)
	p:SetPoint("TOPLEFT", f.bg, "TOPLEFT", 8, -8)
	p:SetPoint("BOTTOMRIGHT", f.bg, "BOTTOMRIGHT", -8, 8)
	p:Hide()
	self.mineTab = "deposit"
	p.tabDeposit = SubTab(p, 160)
	p.tabDeposit:SetPoint("TOPLEFT", 0, 0)
	CuratorOctoFull.SetScript(p.tabDeposit, "OnClick", function()
		MUI.mineTab, MUI.minePage, MUI.mineChosen = "deposit", 1, nil
		ns.Play(ns.SND.click)
		MUI:PaintMine()
	end)
	p.tabHistory = SubTab(p, 160)
	p.tabHistory:SetPoint("LEFT", p.tabDeposit, "RIGHT", 4, 0)
	CuratorOctoFull.SetScript(p.tabHistory, "OnClick", function()
		MUI.mineTab, MUI.minePage, MUI.mineChosen = "history", 1, nil
		ns.Play(ns.SND.click)
		MUI:PaintMine()
	end)
	p.rows = Rows(p, -26, 280, { { 170, "LEFT" }, { 110, "RIGHT" }, { 80, "RIGHT" } }, function(x, button)
		MUI.mineChosen = x
		ns.Play(ns.SND.click)
		if button == "RightButton" then
			local it = x.it or (x.h and EventThing(x.h))
			if it then
				MUI:Sheet(it)
			end
		end
		MUI:PaintMine()
	end, function(r, x)
		if x.h then
			local it = EventThing(x.h)
			if it then
				MUI:Tooltip(r, it, { { " " }, { date("%d/%m/%Y %H:%M", tonumber(x.h.t) or 0), DIM } })
			end
		elseif x.it then
			local extra = { { " " }, { L[STATE[x.state] and STATE[x.state][1] or "?"], STATE[x.state] and STATE[x.state][2] or WHITE },
				{ L[STATE_TIP[x.state] or ""], DIM } }
			if x.l.tr then
				local asks = {}
				for _, a in ipairs(x.l.tr) do
					asks[CuratorOctoFull.Length(asks) + 1] = MK.ReadAsk(a)
				end
				extra[CuratorOctoFull.Length(extra) + 1] = { string.format(L["Barter: %s"], BarterText(asks, x.l.cp)), { 0.6, 0.9, 1 } }
			end
			MUI:Tooltip(r, x.it, extra)
		end
	end)
	p.empty = S.Text(p, "GameFontDisable", "CENTER")
	p.empty:SetPoint("TOPLEFT", 60, -110)
	p.empty:SetPoint("TOPRIGHT", -60, -110)
	p.pager = ListPager(p, function() MUI:PaintMine() end, function() return MUI.minePage or 1 end, function(v) MUI.minePage = v end)
	p.why = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.why:SetPoint("BOTTOMLEFT", 0, 2)
	p.why:SetWidth(370)
	p.why:SetWordWrap(true)
	p.why:SetMaxLines(2)
	p.withdraw = ArmButton(p, L["Withdraw"], 130, function()
		local x = MUI.mineChosen
		if x and x.n then
			local ok, why = MK:Withdraw(x.n)
			ns.Print(ok and L["Withdrawal asked: it goes with your next save (Send now). It comes back if nobody bought it before."] or L[WHY[why] or WHY.thing])
			MUI:Paint()
		end
	end)
	p.withdraw:SetPoint("BOTTOMRIGHT", 0, 0)
	p.lower = S.Button(p, L["Lower the price"], 130, 22)
	p.lower:SetPoint("RIGHT", p.withdraw, "LEFT", -8, 0)
	CuratorOctoFull.SetScript(p.lower, "OnClick", function()
		local x = MUI.mineChosen
		local v = p.newPrice:Get()
		if x and x.n and v then
			local ok, why, lo = MK:Reprice(x.n, v)
			if ok then
				ns.Play(ns.SND.coins)
				ns.Print(string.format(L["New price asked: %s. It goes with your next save (Send now)."], Rubies(v, 12)))
				p.newPrice:Set("")
			elseif why == "price" then
				ns.Print(string.format(L["A lower price, from %s."], Rubies(lo or 1, 12)))
			else
				ns.Print(L[WHY[why] or WHY.thing])
			end
			MUI:Paint()
		end
	end)
	p.newPrice = EditBox(p, 100, true, 9, L["new price"], function()
		MUI:PaintMine()
	end)
	p.newPrice:SetPoint("RIGHT", p.lower, "LEFT", -6, 0)
	p.again = S.Button(p, L["Put on sale again"], 170, 22)
	p.again:SetPoint("BOTTOMRIGHT", 0, 0)
	CuratorOctoFull.SetScript(p.again, "OnClick", function()
		local x = MUI.mineChosen
		if x and x.h then
			MUI:Relist(x.h)
		end
	end)
	return p
end

function MUI:PaintMine()
	local f = self.frame
	local p = f and f.pages.mine
	if not (p and p:IsShown()) then
		return
	end
	local deposit = self:Deposit()
	p.tabDeposit:Paint(self.mineTab == "deposit", string.format(L["In deposit (%d)"], CuratorOctoFull.Length(deposit)))
	p.tabHistory:Paint(self.mineTab == "history", L["History"])
	local list = {}
	if self.mineTab == "history" then
		for _, h in ipairs(self:History(SELLER_EVENTS)) do
			list[CuratorOctoFull.Length(list) + 1] = { h = h, key = "h" .. tostring(h.t) .. (h.it or "") .. h.k }
		end
	else
		for _, x in ipairs(deposit) do
			x.key = "n" .. x.n
			list[CuratorOctoFull.Length(list) + 1] = x
		end
	end
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / LIST_ROWS))
	self.minePage = math.min(math.max(1, self.minePage or 1), pages)
	p.pager:Set(self.minePage, pages, string.format(L["Page %d/%d"], self.minePage, pages))
	CuratorOctoFull.SetShown(p.pager, pages > 1)
	local first = (self.minePage - 1) * LIST_ROWS
	local chosen = self.mineChosen
	local still
	for _, x in ipairs(list) do
		if chosen and x.key == chosen.key then
			still = x
		end
	end
	self.mineChosen, chosen = still, still
	for i, r in ipairs(p.rows) do
		local x = list[first + i]
		r.x = x
		if not x then
			r:Hide()
		elseif x.h then
			r:Show()
			local it = EventThing(x.h)
			r.icon:SetTexture(MUI.Icon(it))
			Fit(r.name, it and MUI.Title(it, 2) or "?")
			Color(r.name, it and MUI.Color(it) or WHITE)
			local what, money, col = MUI.Event(x.h)
			Fit(r.cols[1], what)
			Color(r.cols[1], col)
			Fit(r.cols[2], money)
			Fit(r.cols[3], date("%d/%m", tonumber(x.h.t) or 0))
			r:SetSelected(chosen == x)
		else
			r:Show()
			r.icon:SetTexture(MUI.Icon(x.it))
			Fit(r.name, x.it and MUI.Title(x.it, 2) or "?")
			Color(r.name, x.it and MUI.Color(x.it) or WHITE)
			local st = STATE[x.state] or STATE.waiting
			Fit(r.cols[1], L[st[1]])
			Color(r.cols[1], st[2])
			Fit(r.cols[2], x.price and Rubies(x.price, 10) or L["Barter"])
			Fit(r.cols[3], x.state == "waiting" and "-" or MUI.Left(x.ends))
			r:SetSelected(chosen == x)
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		p.empty:SetText(self.mineTab == "history" and L["Nothing yet."] or L["Nothing on sale. The page Sell puts your things in deposit at the Exchange."])
		p.empty:Show()
	else
		p.empty:Hide()
	end
	-- (what can be done with the one chosen)
	local deposit = self.mineTab == "deposit"
	CuratorOctoFull.SetShown(p.withdraw, deposit)
	CuratorOctoFull.SetShown(p.lower, deposit)
	CuratorOctoFull.SetShown(p.newPrice, deposit)
	CuratorOctoFull.SetShown(p.again, not deposit)
	local ok, why, extra = MK:CanUse()
	if deposit then
		local x = chosen
		local can = x ~= nil and x.state ~= "withdraw" and MK.at
		p.withdraw:SetEnabled(can and true or false)
		local v = p.newPrice:Get()
		p.lower:SetEnabled((can and x.price and x.state ~= "price" and v and v < x.price) and true or false)
		CuratorOctoFull.SetShown(p.newPrice, x ~= nil and x.price ~= nil)
		CuratorOctoFull.SetShown(p.lower, x ~= nil and x.price ~= nil)
		if not MK.at then
			self:Why(p.why, "away")
		elseif x then
			p.why:SetText(L[STATE_TIP[x.state] or ""])
			p.why:SetTextColor(DIM[1], DIM[2], DIM[3])
		else
			p.why:SetText("")
		end
	else
		local g = chosen and chosen.h and (chosen.h.k == "back" or chosen.h.k == "refused") and self:BackThing(chosen.h) or nil
		p.again:SetEnabled(g ~= nil and ok)
		self:Why(p.why, (not ok and why ~= "closed") and why or nil, extra)
	end
end

function MUI:BuildBought(f)
	local p = CreateFrame("Frame", nil, f)
	p:SetFrameLevel(f.bg:GetFrameLevel() + 2)
	p:SetPoint("TOPLEFT", f.bg, "TOPLEFT", 8, -8)
	p:SetPoint("BOTTOMRIGHT", f.bg, "BOTTOMRIGHT", -8, 8)
	p:Hide()
	self.boughtTab = "way"
	p.tabs = {}
	for i, t in ipairs({ "way", "orders", "history" }) do
		local i, t = i, t; local b = SubTab(p, 160)
		b:SetPoint("TOPLEFT", (i - 1) * 164, 0)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			MUI.boughtTab, MUI.boughtPage, MUI.boughtChosen = t, 1, nil
			ns.Play(ns.SND.click)
			MUI:PaintBought()
		end)
		b.key = t
		p.tabs[i] = b
	end
	p.rows = Rows(p, -26, 280, { { 170, "LEFT" }, { 110, "RIGHT" }, { 80, "RIGHT" } }, function(x, button)
		MUI.boughtChosen = x
		ns.Play(ns.SND.click)
		if button == "RightButton" and x.it then
			MUI:Sheet(x.it)
		end
		MUI:PaintBought()
	end, function(r, x)
		local it = x.it or (x.h and EventThing(x.h))
		if it then
			MUI:Tooltip(r, it, x.h and { { " " }, { date("%d/%m/%Y %H:%M", tonumber(x.h.t) or 0), DIM } } or nil)
		elseif x.ask then
			GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L["Buy order"], 1, 1, 1)
			GameTooltip:AddLine(MUI.AskText(x.ask), GOLD[1], GOLD[2], GOLD[3], true)
			GameTooltip:AddLine(L["Its rubies wait in deposit: they come back if nobody answers it."], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end
	end)
	p.empty = S.Text(p, "GameFontDisable", "CENTER")
	p.empty:SetPoint("TOPLEFT", 60, -110)
	p.empty:SetPoint("TOPRIGHT", -60, -110)
	p.pager = ListPager(p, function() MUI:PaintBought() end, function() return MUI.boughtPage or 1 end, function(v) MUI.boughtPage = v end)
	p.why = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.why:SetPoint("BOTTOMLEFT", 0, 2)
	p.why:SetWidth(W - 16 - 140)
	p.why:SetWordWrap(true)
	p.why:SetMaxLines(2)
	p.withdraw = ArmButton(p, L["Withdraw"], 120, function()
		local x = MUI.boughtChosen
		if x and x.n and x.ask then
			local ok, why = MK:Withdraw(x.n)
			ns.Print(ok and L["Withdrawal asked: it goes with your next save (Send now). Its rubies come back if nobody answered it before."] or L[WHY[why] or WHY.thing])
			MUI:Paint()
		end
	end)
	p.withdraw:SetPoint("BOTTOMRIGHT", 0, 0)
	-- (a buy order: what, its price, its days)
	self.order = { d = DefaultDays() }
	p.what = S.Button(p, L["Ask for..."], 200, 22)
	p.what:SetPoint("BOTTOMLEFT", 0, 28)
	p.what.label:SetWordWrap(false)
	CuratorOctoFull.SetScript(p.what, "OnClick", function()
		MUI:Pick(L["What do you want to buy?"], function(spec)
			MUI.order.ask = MK.ReadAsk(spec)
			if MUI.order.ask then
				local lo, hi = MK:Bounds(MK:RefAsk(MUI.order.ask))
				MUI.order.p = math.max(lo, math.min(hi, MK:RefAsk(MUI.order.ask)))
				p.price:Set(MUI.order.p)
			end
			MUI:PaintBought()
		end)
	end)
	p.price = EditBox(p, 100, true, 9, L["rubies"], function(_, user)
		if user then
			MUI.order.p = p.price:Get()
			MUI:PaintBought()
		end
	end)
	p.price:SetPoint("LEFT", p.what, "RIGHT", 8, 0)
	p.days = SmallDrop(p, 120)
	p.days:SetPoint("LEFT", p.price, "RIGHT", 8, 0)
	Menu(p.days, function() return DayList() end, function() return MUI.order.d end, function(v) MUI.order.d = v MUI:PaintBought() end)
	p.place = ArmButton(p, L["Place the order"], 170, function()
		local o = MUI.order
		if not (o.ask and o.p) then
			return
		end
		local n, why, lo, hi = MK:Order(MK.AskText(o.ask), o.p, o.d)
		if n then
			ns.Play(ns.SND.coins)
			ns.Print(string.format(L["Buy order placed: %s for %s. Its rubies wait in deposit; it goes with your next save (Send now)."], MUI.AskText(o.ask), Rubies(o.p, 12)))
			o.ask, o.p = nil, nil
			p.price:Set("")
		elseif why == "price" then
			ns.Print(string.format(L["Its price: from %s to %s."], Rubies(lo or 1, 12), Rubies(hi or 1, 12)))
		else
			ns.Print(L[WHY[why] or WHY.thing])
		end
		MUI:Paint()
	end)
	p.place:SetPoint("LEFT", p.days, "RIGHT", 8, 0)
	p.orderRef = S.Text(p, "GameFontDisableSmall", "LEFT")
	p.orderRef:SetPoint("BOTTOMLEFT", p.what, "TOPLEFT", 0, 4)
	p.orderRef:SetWidth(W - 40)
	p.orderRef:SetWordWrap(false)
	return p
end

function MUI:PaintBought()
	local f = self.frame
	local p = f and f.pages.bought
	if not (p and p:IsShown()) then
		return
	end
	local way, orders = self:OnTheWay(), self:Orders()
	for _, b in ipairs(p.tabs) do
		local text = (b.key == "way" and string.format(L["On the way (%d)"], CuratorOctoFull.Length(way))) or (b.key == "orders" and string.format(L["Buy orders (%d)"], CuratorOctoFull.Length(orders))) or L["History"]
		b:Paint(self.boughtTab == b.key, text)
	end
	local list = {}
	local tab = self.boughtTab
	if tab == "history" then
		for _, h in ipairs(self:History(BUYER_EVENTS)) do
			list[CuratorOctoFull.Length(list) + 1] = { h = h, key = "h" .. tostring(h.t) .. (h.it or "") .. h.k }
		end
	elseif tab == "orders" then
		for _, x in ipairs(orders) do
			x.key = "o" .. x.n
			list[CuratorOctoFull.Length(list) + 1] = x
		end
	else
		for _, x in ipairs(way) do
			x.key = "b" .. x.n
			list[CuratorOctoFull.Length(list) + 1] = x
		end
	end
	-- (the list is shorter above the form of a buy order)
	local rows = tab == "orders" and LIST_ROWS - 2 or LIST_ROWS
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / rows))
	self.boughtPage = math.min(math.max(1, self.boughtPage or 1), pages)
	p.pager:Set(self.boughtPage, pages, string.format(L["Page %d/%d"], self.boughtPage, pages))
	CuratorOctoFull.SetShown(p.pager, pages > 1)
	p.pager:ClearAllPoints()
	p.pager:SetPoint("BOTTOMRIGHT", 0, tab == "orders" and 74 or 28)
	local chosen
	for _, x in ipairs(list) do
		if self.boughtChosen and x.key == self.boughtChosen.key then
			chosen = x
		end
	end
	self.boughtChosen = chosen
	local first = (self.boughtPage - 1) * rows
	for i, r in ipairs(p.rows) do
		local x = i <= rows and list[first + i] or nil
		r.x = x
		if not x then
			r:Hide()
		elseif x.h then
			r:Show()
			local it, ask = EventThing(x.h)
			r.icon:SetTexture(MUI.Icon(it or (ask and { k = ask.k, npc = ask.npc, series = ask.series, edition = ask.edition })))
			Fit(r.name, it and MUI.Title(it, 2) or (ask and MUI.AskText(ask)) or "?")
			Color(r.name, it and MUI.Color(it) or GOLD)
			local what, money, col = MUI.Event(x.h)
			Fit(r.cols[1], what)
			Color(r.cols[1], col)
			Fit(r.cols[2], money)
			Fit(r.cols[3], date("%d/%m", tonumber(x.h.t) or 0))
			r:SetSelected(chosen == x)
		elseif x.ask then
			r:Show()
			r.icon:SetTexture(MUI.Icon({ k = x.ask.k, npc = x.ask.npc, series = x.ask.series, edition = x.ask.edition }))
			Fit(r.name, MUI.AskText(x.ask))
			Color(r.name, GOLD)
			local st = STATE[x.state] or STATE.waiting
			Fit(r.cols[1], L[st[1]])
			Color(r.cols[1], st[2])
			Fit(r.cols[2], Rubies(x.price, 10))
			Fit(r.cols[3], x.state == "waiting" and "-" or MUI.Left(x.ends))
			r:SetSelected(chosen == x)
		else
			r:Show()
			r.icon:SetTexture(MUI.Icon(x.it))
			Fit(r.name, x.it and MUI.Title(x.it, 2) or "?")
			Color(r.name, x.it and MUI.Color(x.it) or WHITE)
			Fit(r.cols[1], x.fill and L["Sold to an order: on its way"] or L["On its way"])
			Color(r.cols[1], DIM)
			Fit(r.cols[2], x.b and x.b.gv and CuratorOctoFull.Length(x.b.gv) > 0 and (L["Barter"] .. ((x.paid or 0) > 0 and (" + " .. Rubies(x.paid, 10)) or "")) or Rubies(x.paid or 0, 10))
			Fit(r.cols[3], ns.Duration(math.max(0, Now() - (tonumber((x.b or x.fill).t) or Now()))))
			r:SetSelected(chosen == x)
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		p.empty:SetText((tab == "history" and L["Nothing yet."]) or (tab == "orders" and L["No buy order. Below: what you want, its price, its days; its rubies wait in deposit."])
			or L["Nothing on its way. What you buy comes with the next mail of the Cartel."])
		p.empty:Show()
	else
		p.empty:Hide()
	end
	local orderTab = tab == "orders"
	for _, x in ipairs({ p.what, p.price, p.days, p.place, p.orderRef }) do
		CuratorOctoFull.SetShown(x, orderTab)
	end
	CuratorOctoFull.SetShown(p.withdraw, orderTab and chosen ~= nil)
	p.withdraw:SetEnabled(chosen ~= nil and chosen.state ~= "withdraw" and MK.at and true or false)
	local ok, why, extra = MK:CanUse()
	if orderTab then
		local o = self.order
		Sync(p.days, o.d)
		p.what:SetText(o.ask and MUI.AskText(o.ask) or L["Ask for..."])
		if o.ask then
			local ref = MK:RefAsk(o.ask)
			local lo, hi = MK:Bounds(ref)
			p.orderRef:SetText(string.format(L["Reference %s  ·  from %s to %s"], Rubies(ref, 10), Rubies(lo, 10), Rubies(hi, 10)))
			if ok and not (o.p and o.p >= lo and o.p <= hi) then
				ok, why = false, "price"
			end
			if ok and not ns.Rubies:Has(o.p) then
				ok, why = false, "rubies"
			end
			if ok and MK:Active() >= MK:Rules().listingsMax then
				ok, why = false, "limit"
			end
		else
			p.orderRef:SetText(L["A buy order: rubies in deposit for a precise thing; the first who sells it to you takes them."])
			ok = false
			why = nil
		end
		p.place:SetEnabled(ok)
		p.place:ClearAllPoints()
		p.place:SetPoint("LEFT", p.days, "RIGHT", 8, 0)
		self:Why(p.why, (not ok and why ~= "closed") and why or nil, extra)
	else
		if tab == "way" and CuratorOctoFull.Length(list) > 0 then
			p.why:SetText(L["The next mail of the Cartel brings the answer: the thing, or what you gave, back."])
			p.why:SetTextColor(DIM[1], DIM[2], DIM[3])
		else
			self:Why(p.why, (not ok and why ~= "closed") and why or nil, extra)
		end
	end
end

-------------------------------------------------------------------------------
-- What a barter or a buy order asks for: a card (its finish, a grade from which), a booster, a display, a case
-------------------------------------------------------------------------------
local PICK_ROWS = 8
local PICK_KINDS = { { key = "c", label = "Cards" }, { key = "b", label = "Boosters" }, { key = "d", label = "Displays" }, { key = "x", label = "Cases" } }
local PICK_FIN = { { key = "n", label = "Normal" }, { key = "s", label = "Thunderforged" }, { key = "h", label = "Titanforged" }, { key = "c", label = "Corrupted" } }

-- The things that can be asked for, of a kind (text: in their names; album: of one album only, cards).
function MUI:Askable(kind, text, album)
	local out = {}
	local A = ns.Album
	local order = (A and A.Order and A:Order()) or ns.Series or {}
	if kind == "c" then
		for _, s in ipairs(order) do
			if album == "all" or s.key == album then
				for _, card in ipairs(s.list or {}) do
					local name = C:Name(card)
					if text == "" or string.find(string.lower(name), text, 1, true) then
						out[CuratorOctoFull.Length(out) + 1] = { k = "c", npc = card.npc, card = card, name = name, sub = C:SeriesName(s), color = ns.RARITY[card.rarity].text }
					end
				end
			end
		end
	elseif kind == "b" or kind == "d" then
		local D = ns.Displays
		for _, s in ipairs(order) do
			local ok = (kind == "b" and MK.AlbumKind(s) ~= nil) or (kind == "d" and D and D.Eligible(s))
			-- (1.14.0, his word: an album unlocked only)
			ok = ok and not MK:Locked({ k = kind, series = s.key })
			local name = C:SeriesName(s)
			if ok and (text == "" or string.find(string.lower(name), text, 1, true)) then
				out[CuratorOctoFull.Length(out) + 1] = { k = kind, series = s.key, name = MUI.Name({ k = kind, series = s.key }), sub = "", color = GOLD }
			end
		end
	elseif kind == "x" then
		local CS = ns.Cases
		for key in pairs(ns.Crates or {}) do
			if CS and CS:Known(key) then
				local name = CaseName(key)
				if text == "" or string.find(string.lower(name), text, 1, true) then
					out[CuratorOctoFull.Length(out) + 1] = { k = "x", edition = key, name = name, sub = "", color = GOLD }
				end
			end
		end
		table.sort(out, function(a, b)
			return a.edition < b.edition
		end)
	end
	return out
end

function MUI:BuildPicker()
	if self.picker then
		return self.picker
	end
	local f = self.frame
	local pk = CreateFrame("Frame", nil, f)
	pk:SetAllPoints(f.bg)
	pk:SetFrameLevel(f:GetFrameLevel() + 30)
	pk:EnableMouse(true)
	pk:Hide()
	pk.bg = pk:CreateTexture(nil, "BACKGROUND")
	pk.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(pk.bg, 0.04, 0.035, 0.03, 0.97)
	pk.edge = S.Inset(pk)
	pk.edge:SetAllPoints()
	-- (what it holds, over its inset)
	local c = CreateFrame("Frame", nil, pk)
	c:SetAllPoints()
	c:SetFrameLevel(pk.edge:GetFrameLevel() + 1)
	pk.c = c
	pk.kind, pk.album, pk.fin, pk.min, pk.cased, pk.page = "c", "all", "n", 0, false, 1
	local function Again()
		pk.page, pk.chosen = 1, nil
		MUI:PaintPicker()
	end
	pk.title = S.Text(c, "GameFontNormalLarge", "LEFT")
	pk.title:SetPoint("TOPLEFT", 14, -12)
	pk.tabs = {}
	for i, k in ipairs(PICK_KINDS) do
		local i, k = i, k; local b = SubTab(c, 110)
		b:SetPoint("TOPLEFT", 14 + (i - 1) * 114, -38)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			pk.kind = k.key
			ns.Play(ns.SND.click)
			Again()
		end)
		b.key, b.text0 = k.key, L[k.label]
		pk.tabs[i] = b
	end
	pk.search = EditBox(c, 200, false, 40, L["Search"], Again)
	pk.search:SetPoint("TOPLEFT", 14, -64)
	pk.albumDd = SmallDrop(c, 230)
	pk.albumDd:SetPoint("LEFT", pk.search, "RIGHT", 8, 0)
	Menu(pk.albumDd, function() return AlbumList() end, function() return pk.album end, function(v) pk.album = v Again() end)
	pk.rows = {}
	for i = 1, PICK_ROWS do
		local i = i; local r = Row(c, 250, { { 180, "LEFT" } })
		r:SetPoint("TOPLEFT", 14, -92 - (i - 1) * ROW_H)
		r:SetWidth(480)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.x then
				pk.chosen = self.x
				ns.Play(ns.SND.click)
				MUI:PaintPicker()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnDoubleClick", function(self)
			if self.x then
				pk.chosen = self.x
				MUI:PickChosen()
			end
		end)
		pk.rows[i] = r
	end
	pk.pager = S.Pager(c)
	pk.pager:SetPoint("TOPRIGHT", pk, "TOPLEFT", 494, -92 - PICK_ROWS * ROW_H - 2)
	CuratorOctoFull.SetScript(pk.pager.prev, "OnClick", function()
		pk.page = math.max(1, pk.page - (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1))
		MUI:PaintPicker()
	end)
	CuratorOctoFull.SetScript(pk.pager.next, "OnClick", function()
		pk.page = pk.page + (IsShiftKeyDown and IsShiftKeyDown() and S.JUMP or 1)
		MUI:PaintPicker()
	end)
	pk.empty = S.Text(c, "GameFontDisable", "CENTER")
	pk.empty:SetPoint("TOPLEFT", 14, -140)
	pk.empty:SetWidth(480)
	pk.empty:SetWordWrap(true)
	-- (on the right: its finish, a grade from which, in its case)
	local RX = 514
	pk.choice = S.Text(c, "GameFontNormal", "LEFT")
	pk.choice:SetPoint("TOPLEFT", RX, -92)
	pk.choice:SetWidth(W - RX - 20)
	pk.choice:SetWordWrap(true)
	pk.finL = Label(c, L["Finish"])
	pk.finL:SetPoint("TOPLEFT", RX, -128)
	pk.finDd = SmallDrop(c, 200)
	pk.finDd:SetPoint("TOPLEFT", RX, -142)
	Menu(pk.finDd, PICK_FIN, function() return pk.fin end, function(v)
		pk.fin = v
		if v == "c" then
			pk.min = 0
		end
		MUI:PaintPicker()
	end)
	pk.minL = Label(c, L["Its grade"])
	pk.minL:SetPoint("TOPLEFT", RX, -174)
	pk.minDd = SmallDrop(c, 200)
	pk.minDd:SetPoint("TOPLEFT", RX, -188)
	Menu(pk.minDd, function()
		local out = { { key = 0, text = L["Any copy"] } }
		for g = 1, 10 do
			out[CuratorOctoFull.Length(out) + 1] = { key = g, text = string.format(L["Appraised %d or more"], g) }
		end
		return out
	end, function() return pk.min end, function(v) pk.min = v MUI:PaintPicker() end)
	pk.casedBox = S.Check(c, L["In its protective case"])
	pk.casedBox:SetPoint("TOPLEFT", RX - 2, -128)
	CuratorOctoFull.SetScript(pk.casedBox, "OnClick", function(self)
		pk.cased = self:GetChecked() and true or false
		MUI:PaintPicker()
	end)
	pk.ref = S.Text(c, "GameFontDisableSmall", "LEFT")
	pk.ref:SetPoint("TOPLEFT", RX, -222)
	pk.ref:SetWidth(W - RX - 20)
	pk.ref:SetWordWrap(true)
	pk.ok = S.Button(c, L["Choose"], 110, 22)
	pk.ok:SetPoint("BOTTOMRIGHT", -14, 12)
	CuratorOctoFull.SetScript(pk.ok, "OnClick", function()
		MUI:PickChosen()
	end)
	pk.cancel = S.Button(c, L["Cancel"], 100, 22)
	pk.cancel:SetPoint("RIGHT", pk.ok, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(pk.cancel, "OnClick", function()
		pk:Hide()
	end)
	self.picker = pk
	return pk
end

-- The spec of what the picker shows chosen (nil: nothing chosen).
function MUI:PickSpec()
	local pk = self.picker
	local x = pk and pk.chosen
	if not x then
		return nil
	end
	if x.k == "c" then
		return "c." .. x.npc .. "." .. pk.fin .. ((pk.fin ~= "c" and pk.min > 0) and ("." .. pk.min) or "")
	elseif x.k == "b" then
		return "b." .. x.series
	elseif x.k == "d" then
		return "d." .. x.series .. "." .. (pk.cased and "1" or "0")
	end
	return "x." .. x.edition
end

-- What a barter or an order asks for, chosen: onPick(spec).
function MUI:Pick(title, onPick)
	local pk = self:BuildPicker()
	pk.title:SetText(title)
	pk.onPick, pk.chosen = onPick, nil
	pk:Show()
	ns.Play(ns.SND.open)
	self:PaintPicker()
end

function MUI:PickChosen()
	local pk = self.picker
	local spec = self:PickSpec()
	if not (pk and spec and MK.ReadAsk(spec)) then
		return
	end
	pk:Hide()
	ns.Play(ns.SND.click)
	if pk.onPick then
		pk.onPick(spec)
	end
end

function MUI:PaintPicker()
	local pk = self.picker
	if not (pk and pk:IsShown()) then
		return
	end
	for _, b in ipairs(pk.tabs) do
		b:Paint(pk.kind == b.key, b.text0)
	end
	Sync(pk.albumDd, pk.album)
	CuratorOctoFull.SetShown(pk.albumDd, pk.kind == "c")
	local list = self:Askable(pk.kind, string.lower(pk.search:Text()), pk.album)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / PICK_ROWS))
	pk.page = math.min(math.max(1, pk.page), pages)
	pk.pager:Set(pk.page, pages, string.format(L["Page %d/%d"], pk.page, pages))
	CuratorOctoFull.SetShown(pk.pager, pages > 1)
	local first = (pk.page - 1) * PICK_ROWS
	for i, r in ipairs(pk.rows) do
		local x = list[first + i]
		r.x = x
		if x then
			r:Show()
			r.icon:SetTexture(MUI.Icon(x))
			Fit(r.name, x.name)
			Color(r.name, x.color or WHITE)
			Fit(r.cols[1], x.sub or "")
			r:SetSelected(pk.chosen ~= nil and pk.chosen.k == x.k and pk.chosen.npc == x.npc and pk.chosen.series == x.series and pk.chosen.edition == x.edition)
		else
			r:Hide()
		end
	end
	CuratorOctoFull.SetShown(pk.empty, CuratorOctoFull.Length(list) == 0)
	pk.empty:SetText(L["Nothing of that name."])
	local x = pk.chosen
	local card = x and x.k == "c"
	CuratorOctoFull.SetShown(pk.finL, card)
	CuratorOctoFull.SetShown(pk.finDd, card)
	CuratorOctoFull.SetShown(pk.minL, card and pk.fin ~= "c")
	CuratorOctoFull.SetShown(pk.minDd, card and pk.fin ~= "c")
	CuratorOctoFull.SetShown(pk.casedBox, x ~= nil and x.k == "d")
	pk.casedBox:SetChecked(pk.cased)
	Sync(pk.finDd, pk.fin)
	Sync(pk.minDd, pk.min)
	local spec = self:PickSpec()
	local a = spec and MK.ReadAsk(spec)
	pk.choice:SetText(a and MUI.AskText(a) or L["Choose in the list."])
	pk.ref:SetText(a and string.format(L["Its value of reference: %s"], Rubies(MK:RefAsk(a), 10)) or "")
	pk.ok:SetEnabled(a ~= nil)
end

-------------------------------------------------------------------------------
-- The test of the author (his build): the Exchange on a copy of his collection, nothing kept; its news made up (a
-- selection of the albums, buy orders, the prices of the month), the website played here: what goes is judged at once,
-- the buyers and the sellers come by themselves. /curator test bourse again: back to his collection.
-------------------------------------------------------------------------------
local TEST_FR = {
	["(Test: the Exchange on a copy of your collection, nothing is kept. Its news are made up; the website is played here: Send now answers at once, buyers and sellers come by themselves. /curator test bourse again: back to your collection.)"] =
		"(Test : la Bourse sur une copie de ta collection, rien n'est gardé. Ses nouvelles sont inventées ; le site est joué ici : Envoyer maintenant répond tout de suite, des acheteurs et des vendeurs viennent tout seuls. Retape /curator test bourse pour revenir à ta collection.)",
	["(Test over: your own collection is back.)"] = "(Test terminé : ta vraie collection est revenue.)",
	["(Another test runs already: end it first.)"] = "(Un autre test est déjà en cours : termine-le d'abord.)",
	["(Test: the website answered.)"] = "(Test : le site a répondu.)",
}
local function TT(k)
	return (GetLocale and GetLocale() == "frFR" and TEST_FR[k]) or k
end
local TEST_NAMES = { "Thrall", "Jaina", "Sylvanas", "Varian", "Baine", "Tyrande", "Vol~27jin", "D~C3~A9londra", "Gelbin", "Rexxar" }
local TEST_MARKS = { "9999", "9A99", "A9A9", "AAAA", "8999", "9989", "7898", "A99A" }

local function Pick(list)
	return list[math.random(1, CuratorOctoFull.Length(list))]
end

-- A price of a thing made up: about its value of reference, in its bounds.
local function TestPrice(it)
	local ref = MK:Ref(it)
	local lo, hi = MK:Bounds(ref)
	return math.max(lo, math.min(hi, math.floor(ref * (0.6 + math.random() * 0.8))))
end

-- The news made up for the test: the market open, a selection of every album, buy orders for cards of the collection,
-- the prices of the month of the things alike.
function MUI:TestNews()
	local now = Now()
	local news = { t = now, v = now + 3 * 86400, open = true, opens = 0, msgs = {}, mine = {}, sel = {}, orders = {}, prices = {},
		favs = {}, rules = {} }
	for k, v in pairs(MK.DEFAULT) do
		news.rules[k] = v
	end
	local id = 5000
	local function Add(it, price, opts)
		opts = opts or {}
		local pack = MK.Pack(it)
		local x = MK.Unpack(pack)
		if not x then
			return
		end
		id = id + 1
		news.sel[CuratorOctoFull.Length(news.sel) + 1] = { id = id, ends = now + (opts.days or Pick({ 1, 3, 5, 7 })) * 86400 - math.random(0, 80000),
			price = price, count = opts.count or 1, from = price, seller = Pick(TEST_NAMES),
			ac = (math.random(1, 3) == 1) and math.random(0, MK.ACCROCHES - 1) or nil, asks = opts.asks or {}, cp = opts.cp or 0,
			pack = pack, it = x }
		local spec = MK.Ident(x)
		if spec and price and not news.prices[spec] then
			local pts = {}
			for i = 1, math.random(2, 8) do
				pts[i] = { math.random(0, 29), math.max(1, math.floor(price * (0.75 + math.random() * 0.5))) }
			end
			table.sort(pts, function(a, b)
				return a[1] > b[1]
			end)
			news.prices[spec] = { median = math.floor(price * (0.9 + math.random() * 0.2)), n = CuratorOctoFull.Length(pts), pts = pts }
		end
	end
	local FIN_PICK = { "n", "n", "n", "n", "s", "s", "h" }
	for _, s in ipairs(ns.Series or {}) do
		local list = s.list or {}
		for _ = 1, math.min(CuratorOctoFull.Length(list), 3) do
			local card = list[math.random(1, CuratorOctoFull.Length(list))]
			local it = { k = "c", npc = card.npc, f = Pick(FIN_PICK), g = 0, m = "", ce = 0, hg = 0, r = {}, ot = 0, ow = "", och = "", cor = 0 }
			if math.random(1, 5) == 1 then
				local g = math.random(70, 100) * 10
				it.g, it.hg, it.m, it.ce, it.sl = g, g, Pick(TEST_MARKS), math.random(100000, 999999), true
				if math.random(1, 3) == 1 then
					it.r = { { now - math.random(1, 40) * 86400, math.random(1, 4), math.random(10, 100) } }
				end
				it.ot = MUI.LAUNCH + math.random(0, 9 * 86400)
				it.ow = Pick({ "b", "f", "b", "k" })
				it.och = MK.Unesc(Pick(TEST_NAMES)) or ""
			end
			-- (1.14.0: a titanforged copy, its pattern; 1 November, the filters of the Bourse to try: one in two certified by a
			-- master of the mages)
			if it.f == "h" and ns.Copies then
				it.pt = ns.Copies.DrawPattern()
				local MG = ns.Mages
				if MG and math.random(1, 2) == 1 then
					it.tc = MG.Pack({ t = now - math.random(1, 20) * 86400, m = MG.TEST_MASTER })
				end
			end
			Add(it, TestPrice(it), { count = MK.PlainCopy(it) and math.random(1, 4) or 1 })
		end
		if MK.AlbumKind(s) then
			local b = { k = "b", series = s.key }
			if math.random(1, 3) == 1 then
				Add(b, TestPrice(b), { count = math.random(1, 6) })
			end
			if ns.Displays and ns.Displays.Eligible(s) and math.random(1, 6) == 1 then
				local d = { k = "d", series = s.key, cased = math.random(1, 2) == 1 }
				Add(d, TestPrice(d))
			end
		end
	end
	-- (a reliquary, a barter or two, a case and its cards)
	local CI = ns.CrateItems
	local case = ns.Cases and ns.Cases.EDITION
	if case and CI and CI:Case(case) then
		Add({ k = "x", edition = case }, 250, { count = 3 })
		local c = CI:Case(case)
		for r = 1, 4 do
			local e = Pick(c[r])
			local ap = math.random(1, 2) == 1
			local w = { k = "w", edition = case, rank = r, entry = e.key, f = Pick({ "n", "n", "t", "T" }), grade = math.random(3, 10),
				ot = MUI.LAUNCH + math.random(0, 9 * 86400), oh = "" }
			if ap then
				w.ap = { m = Pick(TEST_MARKS), ce = math.random(10000, 99999), at = now - 3600 }
			end
			-- (1 November, the filters of the Bourse to try: a titanforged one with its pattern, certified one time in two; one
			-- in three restored at an enchanter)
			local MG, W = ns.Mages, ns.Wear
			if w.f == "T" and ns.Copies then
				w.pt = ns.Copies.DrawPattern()
				if MG and math.random(1, 2) == 1 then
					w.tc = MG.Pack({ t = now - math.random(1, 20) * 86400, m = MG.TEST_MASTER })
				end
			end
			if W and W.Pack and math.random(1, 3) == 1 then
				w.wear = W.Pack({ w0 = Pick(TEST_MARKS) }, true)
			end
			Add(w, TestPrice(w))
		end
	end
	local mine = {}
	for _, x in ipairs(ns.Copies and ns.Copies:All() or {}) do
		mine[CuratorOctoFull.Length(mine) + 1] = x.card
	end
	for i = 1, math.min(2, CuratorOctoFull.Length(mine)) do
		local card = Pick(mine)
		local s = card.series
		if MK.AlbumKind(s) then
			local b = { k = "b", series = s.key }
			Add(b, nil, { asks = { { k = "c", npc = card.npc, f = "n", min = 0 } }, cp = i == 1 and 0 or 200 })
		end
	end
	-- (buy orders for cards of the collection)
	for i = 1, math.min(5, CuratorOctoFull.Length(mine)) do
		local card = Pick(mine)
		local a = { k = "c", npc = card.npc, f = "n", min = 0 }
		local ref = MK:RefAsk(a)
		local lo, hi = MK:Bounds(ref)
		news.orders[CuratorOctoFull.Length(news.orders) + 1] = { id = 7000 + i, ends = now + math.random(1, 7) * 86400, price = math.max(lo, math.min(hi, math.floor(ref * 1.1))),
			buyer = Pick(TEST_NAMES), spec = MK.AskText(a), ask = a }
	end
	return news
end

-- The website played here: what the save asks is judged at once (listings online, purchases come, withdrawals, new
-- prices, sales to the orders); now and then a buyer takes a listing, a seller answers an order. now: Send now.
function MUI:TestJudge(now)
	local news = MK.test and MK.test.news
	local db = ns.db
	local m = MK:Db()
	if not (self.testing and news and db and m) then
		return
	end
	local cid, t = db.cid, Now()
	local out = {}
	local function Say(body)
		out[CuratorOctoFull.Length(out) + 1] = body
	end
	local function Mine(n, order)
		for i, x in ipairs(news.mine) do
			if x.n == n and x.order == order then
				return x, i
			end
		end
		return nil
	end
	local function Gone(n, order)
		local _, i = Mine(n, order)
		if i then
			CuratorOctoFull.Remove(news.mine, i)
		end
	end
	for n in pairs(m.wd) do
		if m.ls[n] then
			Say(string.format(("back %d w"), n))
			Gone(n, false)
		elseif m.od[n] then
			Say(string.format(("oend %d w"), n))
			Gone(n, true)
		end
	end
	for n, p in pairs(m.pc) do
		local x = Mine(n, false)
		if x then
			x.price = p
		end
	end
	for n, b in pairs(m.bu) do
		local hit, at
		for i, x in ipairs(news.sel) do
			if x.id == b.l then
				hit, at = x, i
			end
		end
		if hit then
			-- (as the website says it: the purchase it closes, its aim, its rubies, what it gave)
			local given = (b.gv and CuratorOctoFull.Length(b.gv) > 0) and (" " .. table.concat(b.gv, " ")) or ""
			Say(string.format(("got %d 0 %s - %d %d %s%s"), n, hit.seller, Int(b.l), Int(b.p), hit.pack, given))
			hit.count = hit.count - 1
			if hit.count <= 0 then
				CuratorOctoFull.Remove(news.sel, at)
			end
		else
			Say(string.format(("ref %d gone"), n))
		end
	end
	for n, f in pairs(m.fl) do
		local hit, at
		for i, o in ipairs(news.orders) do
			if o.id == f.o then
				hit, at = o, i
			end
		end
		if hit then
			Say(string.format(("fsold %d %d %d %s %d %s"), n, MK:Net(hit.price), hit.price, hit.buyer, Int(f.o), f.it))
			CuratorOctoFull.Remove(news.orders, at)
		else
			Say(string.format(("fno %d gone"), n))
		end
	end
	-- (the buyers, the sellers: a listing online for a while, an order)
	for _, x in ipairs(news.mine) do
		local l = (not x.order) and m.ls[x.n]
		local o = x.order and m.od[x.n]
		if l and not m.wd[x.n] and t - (tonumber(l.t) or t) >= 20 and math.random() < 0.4 then
			local packs = {}
			for _, a in ipairs(l.tr or {}) do
				local ask = MK.ReadAsk(a)
				if ask and ask.k == "c" then
					packs[CuratorOctoFull.Length(packs) + 1] = MK.Pack({ k = "c", npc = ask.npc, f = ask.f, g = (ask.min or 0) * 100, m = (ask.min or 0) > 0 and "9999" or "",
						ce = (ask.min or 0) > 0 and math.random(100000, 999999) or 0, sl = true, hg = (ask.min or 0) * 100, r = {}, ot = 0, ow = "",
						och = "", cor = ask.f == "c" and 50 or 0 })
				elseif ask then
					packs[CuratorOctoFull.Length(packs) + 1] = MK.Pack({ k = ask.k, series = ask.series, cased = ask.cased, edition = ask.edition })
				end
			end
			local paid = l.p or l.cp or 0
			local p = m.pc[x.n] or l.p
			if p and CuratorOctoFull.Length(packs) == 0 then
				paid = p
			end
			x.sold = true
			-- (as the website says it: the listing it closes, its days, its fee, its thing, then what the buyer gave)
			local body = string.format(("sold %d %d %d %s %s %d %d %s"), x.n, MK:Net(paid) + Int(l.fee), paid, Pick(TEST_NAMES),
				math.random(1, 3) == 1 and "x" or "-", Int(l.d), Int(l.fee), l.it)
			Say(CuratorOctoFull.Length(packs) > 0 and (body .. " " .. table.concat(packs, " ")) or body)
		elseif o and not m.wd[x.n] and t - (tonumber(o.t) or t) >= 30 and math.random() < 0.4 then
			local ask = MK.ReadAsk(o.k)
			if ask and (ask.k ~= "c" or (ask.min or 0) == 0) then
				local it = ask.k == "c" and { k = "c", npc = ask.npc, f = ask.f, g = 0, m = "", ce = 0, hg = 0, r = {}, ot = 0, ow = "", och = "",
					cor = ask.f == "c" and 50 or 0 } or { k = ask.k, series = ask.series, cased = ask.cased, edition = ask.edition }
				x.sold = true
				Say(string.format(("ogot %d %s %d %s"), x.n, Pick(TEST_NAMES), Int(o.p), MK.Pack(it)))
			end
		end
	end
	for i = CuratorOctoFull.Length(news.mine), 1, -1 do
		if news.mine[i].sold then
			CuratorOctoFull.Remove(news.mine, i)
		end
	end
	-- (what is new: online)
	for n, l in pairs(m.ls) do
		if not Mine(n, false) and not m.wd[n] then
			news.mine[CuratorOctoFull.Length(news.mine) + 1] = { cid = cid, n = n, shown = true, price = m.pc[n] or l.p, ends = t + (tonumber(l.d) or 3) * 86400, id = 90000 + n, order = false }
		end
	end
	for n, o in pairs(m.od) do
		if not Mine(n, true) and not m.wd[n] then
			news.mine[CuratorOctoFull.Length(news.mine) + 1] = { cid = cid, n = n, shown = true, price = o.p, ends = t + (tonumber(o.d) or 3) * 86400, id = 90000 + n, order = true }
		end
	end
	local msgs = {}
	for i, body in ipairs(out) do
		local kind, rest = CuratorOctoFull.Match(body, "^(%S+)%s*(.*)$")
		local args = {}
		for a in CuratorOctoFull.Gmatch(rest, "%S+") do
			args[CuratorOctoFull.Length(args) + 1] = a
		end
		msgs[i] = { seq = m.seq + i, kind = kind, args = args }
	end
	news.msgs[cid] = msgs
	news.t = math.max(news.t, t)
	MK:Apply()
	news.msgs[cid] = {}
	if now then
		ns.Print(TT("(Test: the website answered.)"))
	end
	self:Paint()
	if self.sheet and self.sheet:IsShown() then
		self:PaintSheet()
	end
end

-- The test begun, or ended (again).
function MUI:Test()
	local AD = ns.Admin
	if not (AD and AD.Lend and ns.db and ns.Reroll and ns.Reroll.Copy) then
		return
	end
	if self.testing then
		self.testing = nil
		if self.ticker then
			self.ticker:Cancel()
			self.ticker = nil
		end
		MK.test = nil
		MK.at = (_G.AuctionFrame and _G.AuctionFrame:IsShown()) or false
		MK:Forget()
		AD:Restore()
		if self.win then
			self.win:Hide()
		end
		if self.sheet then
			self.sheet:Hide()
		end
		ns.Print(TT("(Test over: your own collection is back.)"))
		return
	end
	if AD.Lent and AD:Lent() then
		ns.Print(TT("(Another test runs already: end it first.)"))
		return
	end
	local copy = ns.Reroll.Copy(ns.db)
	copy.test = true
	if not AD:Lend(copy) then
		return
	end
	self.testing = true
	MK.test = { news = self:TestNews() }
	MK.at = true
	MK:Forget()
	if CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker then
		self.ticker = CuratorOctoFull.Timer.NewTicker(10, function()
			MUI:TestJudge()
		end)
	end
	ns.Print(TT("(Test: the Exchange on a copy of your collection, nothing is kept. Its news are made up; the website is played here: Send now answers at once, buyers and sellers come by themselves. /curator test bourse again: back to your collection.)"))
	if not (self:Hook() and _G.AuctionFrame and _G.AuctionFrame:IsShown()) then
		local w = self:Window()
		w:ClearAllPoints()
		w:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
		self:ShowWindow()
	end
	self:Page("buy")
end

-------------------------------------------------------------------------------
-- What the news of the Bourse brought, at the login: an alert, a line in the chat each
-------------------------------------------------------------------------------
function MUI:Said(said)
	if type(said) ~= "table" or CuratorOctoFull.Length(said) == 0 then
		return
	end
	local Push = function(item)
		if ns.Toast and ns.Toast.Push then
			ns.Toast:Push(item)
		end
	end
	local sold, soldCards, rubies, back = 0, 0, 0, 0
	for _, h in ipairs(said) do
		local _, h = _, h; local it, ask = EventThing(h)
		local name = (it and MUI.Name(it)) or (ask and MUI.AskText(ask)) or "?"
		local what, money = MUI.Event(h)
		ns.Print(string.format(L["Steamwheedle Exchange: %s, %s"], name, what) .. (money ~= "" and ("  " .. money) or ""))
		if h.k == "sold" then
			sold = sold + 1
			soldCards = soldCards + ((it and it.k == "c") and 1 or 0)
			rubies = rubies + (tonumber(h.p) or 0)
		elseif h.k == "bought" and it then
			-- (what comes: as a card found)
			local card = MUI.Card(it)
			local finish = card and FIN[it.f] or nil
			local line = (card and ns.Toast and ns.Toast.Line) and ns.Toast.Line(card, finish, it.pt) or table.concat(MUI.Badges(it), "  ·  ")
			Push({ title = L["Delivered by the mail of the Cartel"], name = MUI.Name(it), color = MUI.Color(it), line = line,
				card = card, finish = finish, pt = it.pt, tex = (not card) and { MUI.Icon(it) } or nil,
				sound = (card and ns.SND.reveal[card.rarity]) or ns.SND.cardFlip,
				onClick = function()
					MUI.page = "bought"
				end })
		elseif h.k == "back" or h.k == "refused" or h.k == "refund" or h.k == "unfilled" then
			back = back + 1
		end
	end
	if sold > 0 then
		local name
		if soldCards == sold then
			name = sold == 1 and string.format(L["You sold a card: +%s"], Rubies(rubies, 12)) or string.format(L["You sold %d cards: +%s"], sold, Rubies(rubies, 12))
		else
			name = sold == 1 and string.format(L["You sold a thing: +%s"], Rubies(rubies, 12)) or string.format(L["You sold %d things: +%s"], sold, Rubies(rubies, 12))
		end
		Push({ title = L["Steamwheedle Exchange"], name = name, color = GOLD, line = L["The share of the Cartel taken, your fees given back."],
			tex = { "Interface\\Icons\\INV_Misc_Coin_17" }, sound = ns.SND.coins })
	end
	if back > 0 then
		Push({ title = L["Steamwheedle Exchange"], name = back == 1 and L["A thing came back"] or string.format(L["%d things came back"], back),
			color = WHITE, line = L["My sales, My purchases: what happened."], tex = { "Interface\\Icons\\INV_Letter_15" }, sound = ns.SND.close })
	end
end

ns.On("MARKET_NEWS", function(said)
	MUI:Said(said)
end)

-- (the section of the Exchange of the social page of the album, shown: it follows)
ns.On("MARKET_CHANGED", function()
	local A = ns.Album
	if A and A.frame and A.frame:IsShown() and A.mode == "guild" and A.socSec == "market" and not A.member then
		A:Refresh()
	end
end)
