local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local A = ns.Album
local RT = ns.Rates

-------------------------------------------------------------------------------
-- (1.15.0) The page of the statistics (Rates.lua): every rate of Curator, for everyone and with the talents of this
-- collector. A rate a talent changes: its value for everyone struck through, the new one beside it (green: better;
-- red: lower, as the commons are, the rest of the draws), and in its tooltip the talents that change it, each with
-- its rank and what it adds. The situations a talent learned makes a difference in (in the place of the album, an
-- elite, at night, in a group...) are boxes to tick: the rates change as they would there. Its categories on the
-- left: the boosters (of a zone, of a dungeon or a raid, of an event), the cards found on the creatures, the booster
-- bars, the contracts, the expertise and the seals, the luck of this collector.
-------------------------------------------------------------------------------
local UI = {}
ns.RatesUI = UI

local NAV_W, NAV_H, NAV_GAP = 192, 28, 3
local X0 = NAV_W + 16
local ROW_H = 21
local GOLD, DIM, WHITE = S.GOLD, { 0.62, 0.62, 0.62 }, { 1, 1, 1 }
local UP, DOWN = { 0.42, 1, 0.48 }, { 1, 0.56, 0.46 }
local GOLDEN = { 1, 0.8, 0.32 }
-- (a space that does not break: a chance stays with its sign, 50 %)
local NBSP = "\194\160"

UI.CATS = {
	{ key = "boosters", label = "Boosters", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
	{ key = "creatures", label = "Creatures", icon = "Interface\\Icons\\Ability_Tracking" },
	{ key = "bars", label = "Booster bars", icon = "Interface\\Icons\\INV_Box_01" },
	{ key = "contracts", label = "Contracts", icon = "Interface\\Icons\\INV_Scroll_03" },
	{ key = "expertise", label = "Expertise and seals", icon = "Interface\\Icons\\INV_Misc_Spyglass_02" },
	-- (1.14.0: the cases, Cases.lua)
	{ key = "cases", label = "Cases", icon = "Interface\\Icons\\INV_Crate_03" },
	{ key = "luck", label = "Your luck", icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" },
}
-- (1.14.0, after the test of the cases, his word: no more Hallow's End here, nor its corrupted cards)
UI.KIND_LABEL = { zone = "Zone", dungeon = "Dungeon and raid" }

-- A chance as the page writes it: precise enough for the smallest (0,265 %, 0,0500 %).
local function Pct(p)
	local v = (tonumber(p) or 0) * 100
	local s
	if v == 0 then
		s = "0"
	elseif v >= 10 then
		s = string.format(("%.1f"), v)
	elseif v >= 1 then
		s = string.format(("%.2f"), v)
	elseif v >= 0.1 then
		s = string.format(("%.3f"), v)
	else
		s = string.format(("%.4f"), v)
	end
	if string.find(s, "%.") then
		s = string.gsub(string.gsub(s, "0+$", ""), "%.$", "")
	end
	s = string.gsub(s, "%.", L["."])
	return (string.gsub(string.format(L["%s%%"], s), " ", NBSP))
end
UI.Pct = Pct

-- Two chances side by side (for everyone, with the talents): written with as many decimals, enough to tell them apart
-- (the commons of a zone: 70,00 % > 69,99 %); the zeros at the end only go when both have them.
local function Places(v)
	v = math.abs(v) * 100
	return (v == 0 and 0) or (v >= 10 and 1) or (v >= 1 and 2) or (v >= 0.1 and 3) or 4
end
local function Strip(a, b)
	if string.find(a, "%.") and string.find(b, "%.") then
		while string.sub(a, -1) == "0" and string.sub(b, -1) == "0" do
			a, b = string.sub(a, 1, -2), string.sub(b, 1, -2)
		end
		if string.sub(a, -1) == "." and string.sub(b, -1) == "." then
			a, b = string.sub(a, 1, -2), string.sub(b, 1, -2)
		end
	end
	return a, b
end
local function PctPair(a, b)
	a, b = tonumber(a) or 0, tonumber(b) or 0
	local lo = math.min(a ~= 0 and math.abs(a) or 1, b ~= 0 and math.abs(b) or 1)
	local d = Places(lo)
	local sa, sb = string.format(("%." .. d .. "f"), a * 100), string.format(("%." .. d .. "f"), b * 100)
	while sa == sb and d < 5 do
		d = d + 1
		sa, sb = string.format(("%." .. d .. "f"), a * 100), string.format(("%." .. d .. "f"), b * 100)
	end
	sa, sb = Strip(sa, sb)
	return (string.gsub(string.format(L["%s%%"], (string.gsub(sa, "%.", L["."]))), " ", NBSP)), (string.gsub(string.format(L["%s%%"], (string.gsub(sb, "%.", L["."]))), " ", NBSP)), sa ~= sb
end

-- A number of points, a fraction of them too (0,25; 2,3).
local function Dec(v)
	v = tonumber(v) or 0
	local s = string.gsub(string.gsub(string.format(("%.2f"), v), "0+$", ""), "%.$", "")
	return (string.gsub(s, "%.", L["."]))
end
UI.Dec = Dec

local function Whole(v)
	return ns.Num(v)
end

-- Two numbers side by side, as one writes them both (the experience of a booster: 130 > 134; points: 0,2 > 0,25).
local function DecPair(a, b)
	local sa, sb = Dec(a), Dec(b)
	return sa, sb, sa ~= sb
end
local function WholePair(a, b)
	local sa, sb = Whole(a), Whole(b)
	return sa, sb, sa ~= sb
end
local PAIR = { [Pct] = PctPair, [Dec] = DecPair, [Whole] = WholePair }

-- The tooltip of a talent: its name, its rank, what it does at that rank.
local function TalentTip(owner, t)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(t.name, GOLDEN[1], GOLDEN[2], GOLDEN[3])
	GameTooltip:AddLine(string.format(L["Rank %d / %d"], t.rank, t.ranks), DIM[1], DIM[2], DIM[3])
	GameTooltip:AddLine(t.text, 1, 1, 1, true)
	GameTooltip:Show()
end

-- The line of a talent in a tooltip: its icon, its name, its rank; what it adds on the right.
local function TipTalent(t, extra)
	local icon = string.format(("|T%s:14:14:0:0:64:64:5:59:5:59|t "), t.icon or "")
	local add = t.add and (string.find(t.add, "^x") and t.add or ("+" .. t.add)) or ""
	GameTooltip:AddDoubleLine(icon .. t.name .. "  " .. string.format(L["%d/%d"], t.rank, t.ranks) .. (extra or ""), add, 1, 1, 1, UP[1], UP[2], UP[3])
end

-------------------------------------------------------------------------------
-- The rows
-------------------------------------------------------------------------------
-- A row of a rate: its icon, its name; on the right, its value for everyone struck through when the talents change
-- it, and its value with them; a faint bar of its size under it.
local function NewRow(parent, w)
	local r = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(r, w, ROW_H)
	r:EnableMouse(true)
	r.shade = r:CreateTexture(nil, "BACKGROUND")
	r.shade:SetAllPoints()
	CuratorOctoFull.ColorTexture(r.shade, 1, 1, 1, 0.035)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.6, 0.08)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, 16, 16)
	r.icon:SetPoint("LEFT", 4, 0)
	r.label = S.Text(r, "GameFontHighlight", "LEFT")
	r.label:SetPoint("LEFT", 26, 0)
	CuratorOctoFull.SetWordWrap(r.label, false)
	r.value = S.Text(r, "GameFontHighlight", "RIGHT")
	r.value:SetPoint("RIGHT", -8, 0)
	r.base = S.Text(r, "GameFontHighlight", "RIGHT")
	r.base:SetPoint("RIGHT", r.value, "LEFT", -10, 0)
	r.base:SetTextColor(DIM[1], DIM[2], DIM[3])
	-- (the game has no struck text: a thin line over the value for everyone)
	r.strike = r:CreateTexture(nil, "OVERLAY", nil, 2)
	r.strike:SetHeight(1)
	CuratorOctoFull.ColorTexture(r.strike, 0.82, 0.82, 0.82, 0.95)
	r.strike:SetPoint("LEFT", r.base, "LEFT", -1, 0)
	r.strike:SetPoint("RIGHT", r.base, "RIGHT", 1, 0)
	-- (how big the rate is: a faint fill behind the row, rooted, the smallest seen)
	r.bar = r:CreateTexture(nil, "BORDER")
	r.bar:SetPoint("LEFT", 22, 0)
	r.bar:SetHeight(ROW_H - 6)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		UI:RowTip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

-- A heading of the content: its text, a rule under it.
local function NewHead(parent, w)
	local h = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(h, w, 20)
	h.text = S.Text(h, "GameFontNormal", "LEFT")
	h.text:SetPoint("BOTTOMLEFT", 2, 4)
	h.right = S.Text(h, "GameFontHighlightSmall", "RIGHT")
	h.right:SetPoint("BOTTOMRIGHT", -6, 5)
	h.right:SetTextColor(DIM[1], DIM[2], DIM[3])
	h.rule = S.Divider(h, w, 0.7)
	h.rule:SetPoint("BOTTOMLEFT", 0, 0)
	return h
end

-- A line of text (a note, an explanation).
local function NewNote(parent, w)
	local n = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(n, w, 16)
	n.text = S.Text(n, "GameFontHighlightSmall", "LEFT")
	n.text:SetPoint("TOPLEFT", 4, 0)
	n.text:SetWidth(w - 8)
	CuratorOctoFull.SetWordWrap(n.text, true)
	n.text:SetTextColor(0.85, 0.85, 0.88)
	return n
end

-- A talent of the other effects: its icon, its name and its rank (its tooltip: what it does).
local function NewChip(parent, w)
	local c = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(c, w, 20)
	c:EnableMouse(true)
	c.shade = c:CreateTexture(nil, "BACKGROUND")
	c.shade:SetAllPoints()
	CuratorOctoFull.ColorTexture(c.shade, 0.62, 0.56, 1, 0.07)
	c.icon = c:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(c.icon, 16, 16)
	c.icon:SetPoint("LEFT", 3, 0)
	c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	c.text = S.Text(c, "GameFontHighlightSmall", "LEFT")
	c.text:SetPoint("LEFT", 24, 0)
	c.text:SetPoint("RIGHT", -4, 0)
	CuratorOctoFull.SetWordWrap(c.text, false)
	CuratorOctoFull.SetScript(c, "OnEnter", function(self)
		if self.talent then
			TalentTip(self, self.talent)
		end
	end)
	CuratorOctoFull.SetScript(c, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return c
end

-- A box to tick: a situation a talent makes a difference in.
local function NewToggle(parent)
	local t = S.Check(parent, "")
	CuratorOctoFull.SetScript(t, "OnClick", function(self)
		ns.Play(ns.SND.click)
		UI.ctx[self.key] = self:GetChecked() and true or false
		A:Refresh()
	end)
	return t
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
UI.ctx = {}

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
	b.icon:SetTexture(cat.icon)
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", 38, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	b.text:SetText(L[cat.label])
	b.cat = cat.key
	CuratorOctoFull.SetScript(b, "OnClick", function()
		ns.Play(ns.SND.page)
		A.ratesCat = cat.key
		A:Refresh()
	end)
	return b
end

function A:BuildRates()
	local f = self.frame
	if f.rates then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.rates = page
	local rw = U.PAGE_W - 32 - X0
	page.rw = rw
	page.cats = {}
	for i, cat in ipairs(UI.CATS) do
		page.cats[i] = NewCat(page, cat, i)
	end
	-- under the categories: how to read the page, and the talents of this collector
	local key = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(key, NAV_W, 172)
	key:SetPoint("TOPLEFT", 0, -(CuratorOctoFull.Length(UI.CATS) * (NAV_H + NAV_GAP)) - 12)
	Hud.Panel(key, 172)
	key.title = S.Text(key, "GameFontNormal", "LEFT")
	key.title:SetPoint("TOPLEFT", 12, -12)
	key.title:SetText(L["How to read it"])
	key.old = S.Text(key, "GameFontHighlight", "LEFT")
	key.old:SetPoint("TOPLEFT", 14, -36)
	key.old:SetTextColor(DIM[1], DIM[2], DIM[3])
	key.old:SetText(Pct(0.0005))
	key.strike = key:CreateTexture(nil, "OVERLAY", nil, 2)
	key.strike:SetHeight(1)
	CuratorOctoFull.ColorTexture(key.strike, 0.82, 0.82, 0.82, 0.95)
	key.strike:SetPoint("LEFT", key.old, "LEFT", -1, 0)
	key.strike:SetPoint("RIGHT", key.old, "RIGHT", 1, 0)
	key.new = S.Text(key, "GameFontHighlight", "LEFT")
	key.new:SetPoint("LEFT", key.old, "RIGHT", 10, 0)
	key.new:SetTextColor(UP[1], UP[2], UP[3])
	key.new:SetText(Pct(0.0009))
	key.text = S.Text(key, "GameFontHighlightSmall", "LEFT")
	key.text:SetPoint("TOPLEFT", 12, -58)
	key.text:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(key.text, true)
	key.text:SetTextColor(0.85, 0.85, 0.88)
	key.text:SetText(L["Struck through: for everyone. Beside it: with your talents. Point at a line: the talents that change it."])
	key.spec = S.Text(key, "GameFontHighlightSmall", "LEFT")
	key.spec:SetPoint("BOTTOMLEFT", 12, 12)
	key.spec:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(key.spec, true)
	page.key = key
	-- the content, on the right
	local body = CreateFrame("Frame", nil, page)
	body:SetPoint("TOPLEFT", X0, 0)
	body:SetPoint("BOTTOMRIGHT", 0, 0)
	page.body = body
	page.title = S.Text(body, "GameFontNormalLarge", "LEFT")
	page.title:SetPoint("TOPLEFT", 2, -2)
	page.sub = S.Text(body, "GameFontHighlightSmall", "LEFT")
	page.sub:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -3)
	page.sub:SetWidth(rw - 4)
	CuratorOctoFull.SetWordWrap(page.sub, true)
	page.sub:SetTextColor(DIM[1], DIM[2], DIM[3])
	-- the kinds of booster, the album shown and its arrows
	page.kinds = {}
	for i, kind in ipairs(RT.KINDS) do
		local i, kind = i, kind; local b = S.Button(body, L[UI.KIND_LABEL[kind]], 118, 20)
		b.kind = kind
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			if self.on then
				return
			end
			ns.Play(ns.SND.page)
			A.ratesKind = self.kind
			A.ratesAlbum = nil
			A:Refresh()
		end)
		page.kinds[i] = b
	end
	page.prev = S.Arrow(body, -1, 24)
	page.next = S.Arrow(body, 1, 24)
	page.album = S.Text(body, "GameFontHighlight", "CENTER")
	CuratorOctoFull.SetScript(page.prev, "OnClick", function()
		ns.Play(ns.SND.page)
		A:TurnRatesAlbum(-1)
	end)
	CuratorOctoFull.SetScript(page.next, "OnClick", function()
		ns.Play(ns.SND.page)
		A:TurnRatesAlbum(1)
	end)
	-- the pools of the content
	page.rows, page.heads, page.notes, page.chips, page.toggles = {}, {}, {}, {}, {}
end

function A:ShowRatesPage(shown)
	local f = self.frame
	if shown then
		self:BuildRates()
	end
	if f.rates then
		CuratorOctoFull.SetShown(f.rates, shown)
	end
	if not shown then
		UI.ctx = {}
	end
end

-- The albums of the kind shown, and the one shown (the one of this place first, else the first).
function A:RatesAlbums()
	local kind = self.ratesKind or "zone"
	local list = RT:Albums(kind)
	if CuratorOctoFull.Length(list) == 0 and kind == "event" then
		self.ratesKind = "zone"
		return self:RatesAlbums()
	end
	local s = self.ratesAlbum
	local ok = false
	for _, x in ipairs(list) do
		ok = ok or x == s
	end
	if not ok then
		s = nil
		local here = ns.Rewards and ns.Rewards:ZoneSeries()
		for _, x in ipairs(list) do
			if x == here then
				s = x
			end
		end
		s = s or list[1]
		self.ratesAlbum = s
	end
	return list, s
end

function A:TurnRatesAlbum(dir)
	local list, s = self:RatesAlbums()
	if CuratorOctoFull.Length(list) == 0 then
		return
	end
	local at = 1
	for i, x in ipairs(list) do
		if x == s then
			at = i
		end
	end
	at = CuratorOctoFull.Mod((at - 1 + dir) , CuratorOctoFull.Length(list)) + 1
	self.ratesAlbum = list[at]
	self:Refresh()
end

-------------------------------------------------------------------------------
-- The layout: the content goes down the page, its pieces taken from the pools
-------------------------------------------------------------------------------
local Lay = {}
Lay.__index = Lay

local function Layout(page, y)
	for _, pool in ipairs({ page.rows, page.heads, page.notes, page.chips, page.toggles }) do
		for _, x in ipairs(pool) do
			x:Hide()
		end
	end
	return setmetatable({ page = page, y = y, used = { rows = 0, heads = 0, notes = 0, chips = 0, toggles = 0 }, x = 0, w = page.rw }, Lay)
end

function Lay:Take(pool, make)
	local page = self.page
	self.used[pool] = self.used[pool] + 1
	local x = page[pool][self.used[pool]]
	if not x then
		x = make(page.body, self.w)
		page[pool][self.used[pool]] = x
	end
	x:SetWidth(self.w)
	x:ClearAllPoints()
	x:SetPoint("TOPLEFT", page.body, "TOPLEFT", self.x, -self.y)
	x:Show()
	return x
end

function Lay:Gap(n)
	self.y = self.y + (n or 8)
end

function Lay:Head(text, right)
	local h = self:Take("heads", NewHead)
	h.rule:SetWidth(self.w)
	h.text:SetText(text)
	h.right:SetText(right or "")
	self.y = self.y + 22
	return h
end

-- A rate: label, its rate ({ base, value, mods }), how it reads (fmt), its icon and its colour; lower: less is
-- better (green when it goes down); max: the largest of its table (the size of its bar); note: a line more in its
-- tooltip; tip: more lines.
function Lay:Rate(label, rate, o)
	o = o or {}
	local r = self:Take("rows", NewRow)
	local fmt = o.fmt or Pct
	r.label:SetText(label)
	local c = o.color or WHITE
	r.label:SetTextColor(c[1], c[2], c[3])
	if o.icon then
		r.icon:SetTexture(o.icon)
		r.icon:Show()
	else
		r.icon:Hide()
	end
	local changed = math.abs((rate.value or 0) - (rate.base or 0)) > 1e-12
	local sb, sv = fmt(rate.base), fmt(rate.value)
	if changed and PAIR[fmt] then
		sb, sv, changed = PAIR[fmt](rate.base, rate.value)
	end
	local better = changed and ((o.lower and rate.value < rate.base) or (not o.lower and rate.value > rate.base))
	local vc = (not changed and WHITE) or (better and UP) or DOWN
	if o.text then
		-- (a row of its own words: the luck, what was got against what was expected)
		sv, vc = o.text, o.textColor or WHITE
		sb, changed = o.left or "", false
	end
	r.value:SetText(changed and sv or fmt(rate.value))
	if o.text then
		r.value:SetText(sv)
	end
	r.value:SetTextColor(vc[1], vc[2], vc[3])
	r.base:SetText(sb or "")
	CuratorOctoFull.SetShown(r.base, changed or (o.left ~= nil))
	CuratorOctoFull.SetShown(r.strike, changed)
	-- (a name too long for its row stops before its values: the game cuts it, "...")
	r.label:ClearAllPoints()
	r.label:SetPoint("LEFT", o.icon and 26 or 8, 0)
	r.label:SetPoint("RIGHT", r.base:IsShown() and r.base or r.value, "LEFT", -8, 0)
	if o.max and o.max > 0 then
		local w = math.max(2, (self.w - 30) * math.sqrt(math.min(1, (o.size or rate.value or 0) / o.max)))
		r.bar:SetWidth(w)
		local bc = o.barColor or c
		CuratorOctoFull.ColorTexture(r.bar, bc[1], bc[2], bc[3], 0.16)
		r.bar:Show()
	else
		r.bar:Hide()
	end
	CuratorOctoFull.SetShown(r.shade, CuratorOctoFull.Mod(self.used.rows , 2) == 1)
	r.rate, r.fmt, r.title, r.o = rate, fmt, label, o
	self.y = self.y + ROW_H + 1
	return r
end

function Lay:Note(text, color)
	local n = self:Take("notes", NewNote)
	n.text:SetText(text)
	local c = color or { 0.85, 0.85, 0.88 }
	n.text:SetTextColor(c[1], c[2], c[3])
	local ok, sh = pcall(n.text.GetStringHeight, n.text)
	local h = math.max(14, (ok and tonumber(sh)) or 14)
	n:SetHeight(h)
	self.y = self.y + h + 4
	return n
end

-- The boxes to tick of a section, on one line: { key, label } each.
function Lay:Toggles(list)
	if CuratorOctoFull.Length(list) == 0 then
		return
	end
	local page = self.page
	local x = 0
	for _, t in ipairs(list) do
		self.used.toggles = self.used.toggles + 1
		local b = page.toggles[self.used.toggles]
		if not b then
			b = NewToggle(page.body)
			page.toggles[self.used.toggles] = b
		end
		b.key = t.key
		b.Text:SetText(t.label)
		-- (on: the situation as it is now, when the page has not been told another one)
		if t.on ~= nil then
			b:SetChecked(t.on and true or false)
		else
			b:SetChecked(UI.ctx[t.key] and true or false)
		end
		local w = 30 + (ns.TextWidth and ns.TextWidth(b.Text) or 90) + 14
		if x > 0 and x + w - 14 > self.w then
			x = 0
			self.y = self.y + 26
		end
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", page.body, "TOPLEFT", self.x + x, -self.y)
		b:Show()
		x = x + w
	end
	self.y = self.y + 26
end

-- The other effects of the talents: two of them on a line.
function Lay:Chips(list)
	local half = math.floor((self.w - 6) / 2)
	local x0, w0 = self.x, self.w
	for i, t in ipairs(list) do
		self.w = half
		self.x = x0 + (CuratorOctoFull.Mod((i - 1) , 2)) * (half + 6)
		local c = self:Take("chips", NewChip)
		c.talent = t
		c.icon:SetTexture(t.icon)
		c.text:SetText(t.name .. "  |cff9d9d9d" .. string.format(L["%d/%d"], t.rank, t.ranks) .. "|r" .. (t.add and ("  |cff6bff7a" .. (string.find(t.add, "^x") and "" or "+") .. t.add .. "|r") or ""))
		if CuratorOctoFull.Mod(i , 2) == 0 or i == CuratorOctoFull.Length(list) then
			self.y = self.y + 22
		end
	end
	self.x, self.w = x0, w0
end

-- Two tables side by side: f(lay) for the left, then for the right.
function Lay:Columns(left, right)
	local half = math.floor((self.w - 16) / 2)
	local x0, w0, y0 = self.x, self.w, self.y
	self.w = half
	left(self)
	local y1 = self.y
	self.y, self.x = y0, x0 + half + 16
	right(self)
	self.y = math.max(y1, self.y)
	self.x, self.w = x0, w0
end

-------------------------------------------------------------------------------
-- The tooltip of a rate
-------------------------------------------------------------------------------
function UI:RowTip(r)
	local rate, o = r.rate, r.o or {}
	if not rate then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(r.title, GOLDEN[1], GOLDEN[2], GOLDEN[3])
	local fmt = r.fmt or Pct
	if not o.text then
		local changed = math.abs((rate.value or 0) - (rate.base or 0)) > 1e-12
		local sb, sv = fmt(rate.base), fmt(rate.value)
		if changed and PAIR[fmt] then
			sb, sv, changed = PAIR[fmt](rate.base, rate.value)
		end
		local better = changed and ((o.lower and rate.value < rate.base) or (not o.lower and rate.value > rate.base))
		local vc = (not changed and WHITE) or (better and UP) or DOWN
		GameTooltip:AddDoubleLine(L["For everyone"], sb, 0.8, 0.8, 0.8, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["With your talents"], sv, 0.8, 0.8, 0.8, vc[1], vc[2], vc[3])
	end
	for _, line in ipairs(o.tip or {}) do
		GameTooltip:AddDoubleLine(line[1], line[2], 0.8, 0.8, 0.8, 1, 1, 1)
	end
	if CuratorOctoFull.Length((rate.mods or {})) > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["The talents that change it"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		for _, t in ipairs(rate.mods) do
			local extra
			if t.id == "lucky" and t.dry then
				extra = "  |cff9d9d9d" .. string.format(L["(%d boosters without an epic card)"], t.dry) .. "|r"
			elseif t.id == "onsite" then
				extra = "  |cff9d9d9d" .. L["(in the place of its album)"] .. "|r"
			end
			TipTalent(t, extra)
		end
	elseif o.rest then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["The rest of the draws: what the better rarities take, it gives."], DIM[1], DIM[2], DIM[3], true)
	end
	if o.note then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(o.note, DIM[1], DIM[2], DIM[3], true)
	end
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The sections
-------------------------------------------------------------------------------
local function Rarity(r)
	return ns.RARITY[r]
end
local function GemOf(r)
	return MEDIA .. "Gem" .. r
end

local Sections = {}

-- Where a section starts: under its title and the line that says what it shows.
local function Top(page)
	local function High(fs, d)
		local ok, h = pcall(fs.GetStringHeight, fs)
		h = ok and tonumber(h) or nil
		return (h and h > 0) and h or d
	end
	return 2 + High(page.title, 18) + 3 + High(page.sub, 12) + 10
end

function Sections.boosters(page, lay)
	local list, s = A:RatesAlbums()
	local kind = A.ratesKind or "zone"
	page.title:SetText(L["The boosters"])
	page.sub:SetText(L["What each booster holds: the chance of each card, its finishes, what it gives on average."])
	lay.y = Top(page)
	-- the kinds, the album and its arrows
	local x = 0
	for _, b in ipairs(page.kinds) do
		local shown = CuratorOctoFull.Length(RT:Albums(b.kind)) > 0
		CuratorOctoFull.SetShown(b, shown)
		if shown then
			b:SetWidth(math.max(96, (ns.TextWidth and ns.TextWidth(b:GetFontString()) or 90) + 30))
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", page.body, "TOPLEFT", x, -lay.y)
			x = x + b:GetWidth() + 6
			if b.kind == kind then
				b:LockHighlight()
			else
				b:UnlockHighlight()
			end
			b.on = b.kind == kind
		end
	end
	lay:Gap(26)
	page.prev:ClearAllPoints()
	page.prev:SetPoint("TOPLEFT", page.body, "TOPLEFT", -2, -lay.y + 2)
	page.next:ClearAllPoints()
	page.next:SetPoint("TOPRIGHT", page.body, "TOPLEFT", page.rw + 2, -lay.y + 2)
	page.album:ClearAllPoints()
	page.album:SetPoint("TOP", page.body, "TOPLEFT", page.rw / 2, -lay.y - 4)
	page.prev:Show()
	page.next:Show()
	page.album:Show()
	if not s then
		page.album:SetText("")
		return
	end
	local at = 1
	for i, x2 in ipairs(list) do
		if x2 == s then
			at = i
		end
	end
	page.album:SetText(ns.Collection:SeriesName(s) .. "  |cff9d9d9d" .. string.format(L["(%d / %d)"], at, CuratorOctoFull.Length(list)) .. "|r")
	CuratorOctoFull.SetEnabled(page.prev, CuratorOctoFull.Length(list) > 1)
	CuratorOctoFull.SetEnabled(page.next, CuratorOctoFull.Length(list) > 1)
	lay:Gap(26)
	local b = RT:Booster(s, { hot = UI.ctx.hot })
	-- each card
	local top = 0
	for _, row in ipairs(b.rows) do
		top = math.max(top, row.value, row.base)
	end
	lay:Head(L["Each card"], b.cards.whole and string.format(L["%d cards a booster"], b.cards.whole) or nil)
	for i = CuratorOctoFull.Length(b.rows), 1, -1 do
		local row = b.rows[i]
		local rr = Rarity(row.r)
		lay:Rate(L[rr.label], row, { icon = GemOf(row.r), color = rr.text, max = top, rest = row.rest })
	end
	lay:Gap(6)
	-- each booster
	lay:Head(L["Each booster"])
	if b.rare then
		lay:Rate(L["A rare card or better"], b.rare, { icon = GemOf(3) })
	end
	if b.mythic then
		lay:Rate(L["The mythic card (the last boss)"], b.mythic, { icon = GemOf(6), note = L["In the place of the best card of the booster."] })
	end
	if b.cards.value ~= b.cards.base or b.cards.mods[1] then
		lay:Rate(L["Cards"], b.cards, { fmt = Dec, icon = MEDIA .. "Gem1", note = L["On average: now and then a card more."] })
	end
	lay:Rate(L["Experience on average"], b.xp, { fmt = Whole, icon = "Interface\\Icons\\INV_Misc_Book_09",
		note = b.fresh and L["Fresh Ink: more for the cards your album is missing (not counted here)."] or nil })
	lay:Gap(6)
	-- the finishes
	if b.finishes then
		lay:Head(L["Finishes (each card)"], L["in a booster"])
		for _, fin in ipairs(b.finishes) do
			local c = fin.key == "titan" and { 1, 0.84, 0.5 } or { 0.62, 0.84, 1 }
			lay:Rate(L[fin.key == "titan" and "Titanforged" or "Thunderforged"], fin, { icon = MEDIA .. "Twinkle", color = c,
				tip = { { L["In a booster"], Pct(fin.pack.base) .. "  >  " .. Pct(fin.pack.value) } } })
		end
	end
	-- the situations
	local toggles = {}
	if b.can and b.can.hot then
		toggles[CuratorOctoFull.Length(toggles) + 1] = { key = "hot", label = L["After an epic card (Hot Hand)"], on = b.hot }
	end
	if CuratorOctoFull.Length(toggles) > 0 then
		lay:Gap(4)
		lay:Toggles(toggles)
	end
	-- what else the talents do
	if CuratorOctoFull.Length(b.effects) > 0 then
		lay:Gap(4)
		lay:Head(L["What else your talents do to the boosters"])
		lay:Chips(b.effects)
	end
end

function Sections.creatures(page, lay)
	page.title:SetText(L["The cards of the creatures"])
	page.sub:SetText(L["The chance to find the card of a creature you defeat, by the rarity of its card."])
	lay.y = Top(page)
	local c = RT:Creatures(UI.ctx)
	local toggles = {}
	for _, t in ipairs({ { "elite", L["An elite"] }, { "rare", L["A rare creature"] }, { "raid", L["A raid"] }, { "mark", L["The creature marked"] },
		{ "firstblood", L["The first elite of the hour"] }, { "survey", L["Survey on"] }, { "expedition", L["Expedition on"] } }) do
		if c.can[t[1]] then
			toggles[CuratorOctoFull.Length(toggles) + 1] = { key = t[1], label = t[2], on = c.on[t[1]] }
		end
	end
	lay:Toggles(toggles)
	local top = 0
	for _, row in ipairs(c.boss) do
		top = math.max(top, row.value, row.base)
	end
	for _, row in ipairs(c.rows) do
		top = math.max(top, row.value, row.base)
	end
	lay:Columns(function(l)
		l:Head(L["A creature"])
		for i = CuratorOctoFull.Length(c.rows), 1, -1 do
			local row = c.rows[i]
			local rr = Rarity(row.r)
			l:Rate(L[rr.label], row, { icon = GemOf(row.r), color = rr.text, max = top })
		end
	end, function(l)
		l:Head(L["A boss"])
		for i = CuratorOctoFull.Length(c.boss), 1, -1 do
			local row = c.boss[i]
			local rr = Rarity(row.r)
			l:Rate(L[rr.label], row, { icon = GemOf(row.r), color = rr.text, max = top })
		end
	end)
	lay:Gap(6)
	lay:Head(L["A card found: its finish"])
	lay:Columns(function(l)
		l:Head(L["Zone"])
		l:Rate(L["Thunderforged"], c.finishes.zone.thunder, { icon = MEDIA .. "Twinkle", color = { 0.62, 0.84, 1 } })
		l:Rate(L["Titanforged"], c.finishes.zone.titan, { icon = MEDIA .. "Twinkle", color = { 1, 0.84, 0.5 } })
	end, function(l)
		l:Head(L["Dungeon and raid"])
		l:Rate(L["Thunderforged"], c.finishes.dungeon.thunder, { icon = MEDIA .. "Twinkle", color = { 0.62, 0.84, 1 } })
		l:Rate(L["Titanforged"], c.finishes.dungeon.titan, { icon = MEDIA .. "Twinkle", color = { 1, 0.84, 0.5 } })
	end)
	lay:Gap(6)
	if c.target then
		lay:Note(string.format(L["Contract of the Day: %s (%s). Defeat it and its card is yours."], ns.Collection:Name(c.target), ns.Collection:SeriesName(c.target.series)),
			GOLDEN)
	end
	if CuratorOctoFull.Length(c.gifts) > 0 then
		lay:Head(L["What else your talents do to the cards of the creatures"])
		lay:Chips(c.gifts)
		lay:Gap(4)
	end
	if not c.talents then
		lay:Note(L["The talents of the Cartographer and of the Bounty Hunter change these chances."], DIM)
	end
	if ns.Reroll and ns.Reroll.IsReroll and ns.Reroll:IsReroll() then
		lay:Note(L["This character is a reroll: a quarter of these chances, its cards in its chest."], DOWN)
	end
end

function Sections.bars(page, lay)
	page.title:SetText(L["The booster bars"])
	local b = RT:Bars(UI.ctx)
	page.sub:SetText(string.format(L["What each thing you do gives to your bars: %d points make a booster."], b.per))
	lay.y = Top(page)
	if b.can.group then
		lay:Toggles({ { key = "group", label = L["In a group"] } })
	end
	local LABEL = { kill = "A creature", elite = "An elite", objective = "A step of a quest", quest = "A quest turned in", explore = "A place discovered",
		level = "A level gained", gather = "A gathering", rare = "A rare", hk = "An honorable kill", dkill = "A creature", delite = "An elite", boss = "A boss",
		final = "The last boss" }
	lay:Head(L["The bar of the world"], b.zone and ns.Collection:SeriesName(b.zone) or nil)
	for _, row in ipairs(b.world) do
		lay:Rate(L[LABEL[row.key]], row, { fmt = Dec })
	end
	lay:Gap(6)
	lay:Head(L["The bar of the dungeons and the raids"])
	for _, row in ipairs(b.dungeon) do
		lay:Rate(L[LABEL[row.key]], row, { fmt = Dec })
	end
	lay:Rate(L["Its boosters a day, at most"], b.daily, { fmt = Whole })
	lay:Gap(6)
	if CuratorOctoFull.Length((b.effects or {})) > 0 then
		lay:Head(L["What else your talents do to the bars"])
		lay:Chips(b.effects)
		lay:Gap(4)
	end
	if b.reroll then
		lay:Note(L["This character is a reroll: a quarter of these points, its boosters in its chest."], DOWN)
	end
end

function Sections.contracts(page, lay)
	page.title:SetText(L["The contracts"])
	page.sub:SetText(L["The copies a contract takes for a card of the next rarity."])
	lay.y = Top(page)
	local k = RT:Contracts()
	lay:Head(L["Copies for a card"])
	for _, row in ipairs(k.rows) do
		local rr, nx = Rarity(row.r), Rarity(row.r + 1)
		lay:Rate(string.format(L["%s > %s"], L[rr.label], L[nx.label]), row, { fmt = Whole, icon = GemOf(row.r + 1), color = nx.text, lower = true })
	end
	lay:Rate(L["Forged copies (thunderforged, titanforged)"], k.forged, { fmt = Whole, icon = MEDIA .. "Twinkle", color = { 0.62, 0.84, 1 }, lower = true })
	lay:Rate(L["Contracts signed at once"], k.max, { fmt = Whole })
	lay:Gap(6)
	lay:Note(L["A contract gives a legendary card at most: a mythic card is earned in the boosters."], DIM)
	if CuratorOctoFull.Length(k.effects) > 0 then
		lay:Gap(4)
		lay:Head(L["What else your talents do to the contracts"])
		lay:Chips(k.effects)
	end
end

function Sections.expertise(page, lay)
	page.title:SetText(L["The expertise and the seals"])
	page.sub:SetText(L["The chance of each grade of an expertise, and of each rank of a seal."])
	lay.y = Top(page)
	local e = RT:Expertise()
	local SL, E = ns.Masters, ns.Expertise
	local topE, topS = 0, 0
	for _, row in ipairs(e.grades) do
		topE = math.max(topE, row.value, row.base)
	end
	for _, row in ipairs(e.seals) do
		topS = math.max(topS, row.value)
	end
	lay:Columns(function(l)
		l:Head(L["An expertise"])
		for _, row in ipairs(e.grades) do
			local word = E and E.Word and E.Word(row.grade) or ""
			l:Rate(tostring(row.grade) .. (word ~= "" and ("  |cff9d9d9d" .. word .. "|r") or ""), row, { max = topE, barColor = GOLDEN })
		end
	end, function(l)
		l:Head(L["A seal"])
		for _, row in ipairs(e.seals) do
			local word = SL and SL.Word and SL.Word(row.rank) or ""
			l:Rate((SL and SL.Roman and SL.Roman(row.rank) or tostring(row.rank)) .. (word ~= "" and ("  |cff9d9d9d" .. word .. "|r") or ""), row,
				{ max = topS, barColor = { 0.62, 0.56, 1 } })
		end
	end)
	if CuratorOctoFull.Length((e.effects or {})) > 0 then
		lay:Gap(6)
		lay:Head(L["What else your talents do to the expertise, the seals and the restorations"])
		lay:Chips(e.effects)
	end
end

-- (1.14.0) The cases: where they come from, what a case gives (its rank, its finish, its condition), its key.
function Sections.cases(page, lay)
	page.title:SetText(L["The cases"])
	page.sub:SetText(L["Where the cases come from, and what a case gives: the chance of each rank, of each finish, of each condition."])
	lay.y = Top(page)
	local k = RT:Cases()
	if not k then
		return
	end
	lay:Head(L["Where they come from"], L["a case"])
	lay:Rate(L["A creature that gives experience"], k.kill, { icon = "Interface\\Icons\\Ability_Tracking" })
	lay:Rate(L["A quest turned in (of the game, or of Curator)"], k.quest, { icon = "Interface\\Icons\\INV_Misc_Note_01" })
	lay:Gap(4)
	lay:Note(string.format(L["No limit of a day. One key of its edition opens one: %s rubies."], Whole(k.key)), DIM)
	if k.reroll then
		lay:Note(L["This character is a reroll: a quarter of these chances, its cases in its chest."], DOWN)
	end
	lay:Gap(6)
	local CR = ns.CrateUI
	local top, topC = 0, 0
	for _, row in ipairs(k.ranks) do
		top = math.max(top, row.value)
	end
	for _, row in ipairs(k.conditions) do
		topC = math.max(topC, row.value)
	end
	lay:Columns(function(l)
		l:Head(L["Each case"], L["its card"])
		for _, row in ipairs(k.ranks) do
			local rank = CR and CR.RANKS and CR.RANKS[row.r]
			local c = (rank and (rank.text or rank.color)) or WHITE
			l:Rate(L[(rank and rank.label) or "Rare"], row, { color = c, max = top, barColor = (rank and rank.color) or GOLDEN,
				note = (CR and row.r == CR.TOP) and L["A weapon of legend. Which one stays a mystery."] or nil })
		end
	end, function(l)
		l:Head(L["Its finish"])
		for _, row in ipairs(k.finishes) do
			local c = row.key == "titan" and { 1, 0.84, 0.5 } or { 0.62, 0.84, 1 }
			l:Rate(L[row.key == "titan" and "Titanforged" or "Thunderforged"], row, { icon = MEDIA .. "Twinkle", color = c })
		end
		l:Gap(6)
		l:Head(L["Its condition"])
		for _, row in ipairs(k.conditions) do
			l:Rate(row.grades and string.format(L["Grade %s"], row.grades) or L[row.word], row, { max = topC, barColor = GOLDEN })
		end
	end)
end

function Sections.luck(page, lay)
	page.title:SetText(L["Your luck"])
	page.sub:SetText(L["The cards your boosters gave, against what their chances let expect (without the talents)."])
	lay.y = Top(page)
	local lk = RT:Luck()
	if not lk or lk.n == 0 then
		lay:Note(L["Open boosters: your luck shows here."], DIM)
		return
	end
	lay:Head(string.format(L["Since 1.10.0: %d boosters"], lk.n), L["got / expected, your luck"])
	local most = 0
	for _, row in ipairs(lk.rows) do
		most = math.max(most, row.expect > 0 and row.got / row.expect or 0)
	end
	for _, row in ipairs(lk.rows) do
		local rr = Rarity(row.key)
		local ratio = row.expect > 0 and row.got / row.expect or 0
		local rate = RT.Rate(row.expect, row.got, {})
		local lucky = ratio >= 1
		lay:Rate(L[rr.label], rate, { icon = GemOf(row.key), color = rr.text, max = math.max(1, most), size = ratio,
			left = string.format(L["%s / %s"], Whole(row.got), Dec(math.floor(row.expect * 10 + 0.5) / 10)),
			text = ratio > 0 and string.format(L["x%s"], Dec(math.floor(ratio * 100 + 0.5) / 100)) or "-", textColor = lucky and UP or DOWN,
			tip = { { L["Got"], Whole(row.got) }, { L["Expected"], Dec(math.floor(row.expect * 100 + 0.5) / 100) } },
			note = L["Above x1: luckier than the chances. Under it: less."] })
	end
	lay:Gap(6)
	lay:Head(L["Since your last one"])
	lay:Rate(L["Boosters since your last legendary card"], RT.Rate(lk.sinceLegendary, lk.sinceLegendary, {}), { fmt = Whole, icon = GemOf(5),
		color = Rarity(5).text })
	lay:Rate(L["Boosters since your last mythic card"], RT.Rate(lk.sinceMythic, lk.sinceMythic, {}), { fmt = Whole, icon = GemOf(6),
		color = Rarity(6).text })
end

-------------------------------------------------------------------------------
function A:RefreshRates()
	local f = self.frame
	local page = f.rates
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	local sp = RT:Spec()
	self:SetTitle(L["Statistics"], L["The rates of Curator, and what your talents change"])
	self:SetBar(sp.spent or 0, math.max(1, sp.points or 0), string.format(L["%d / %d points"], sp.spent or 0, sp.points or 0))
	local cat = self.ratesCat or "boosters"
	self.ratesCat = cat
	for _, b in ipairs(page.cats) do
		local on = b.cat == cat
		b.text:SetTextColor(on and 1 or GOLD[1], on and 1 or GOLD[2], on and 1 or GOLD[3])
		CuratorOctoFull.SetShown(b.accent, on)
	end
	page.key.spec:SetText(sp.key and string.format(L["%s: %d points of talent"], sp.name, sp.points or 0) or string.format(L["No specialization yet: the talents come at level %d."], 
		ns.Talents and ns.Talents.CHOOSE or 10))
	-- the pieces of the boosters only show on their section
	for _, b in ipairs(page.kinds) do
		b:Hide()
	end
	page.prev:Hide()
	page.next:Hide()
	page.album:Hide()
	local lay = Layout(page, 0)
	local fn = Sections[cat] or Sections.boosters
	fn(page, lay)
end

-- The page of the statistics, from anywhere (a command).
function A:ShowRates(cat)
	self:Build()
	self.mode, self.member, self.memberEntries, self.returnMode = "rates", nil, nil, nil
	if cat then
		self.ratesCat = cat
	end
	self:HideDetail()
	self:Reveal()
end
