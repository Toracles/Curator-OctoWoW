local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local A = ns.Album

-------------------------------------------------------------------------------
-- (1.14.0, after the test of the cases, his word) The page of the discovery of the Paladin Collection Case No. 1 (a tab
-- of the album, while it lasts: Discovery.lua), in the place of the one of Hallow's End: the banner of the paladins
-- (the room of its case), the light that drifts in it; the time it still lasts; its quests of the day and of the week
-- (Quests.lua: palDaily, palWeekly), a case of the collection each; its cases, its keys, its collection; its
-- achievements.
-------------------------------------------------------------------------------
local GOLD = { 1, 0.84, 0.42 }
local PALE = { 1, 0.95, 0.84 }
local GREY = { 0.74, 0.74, 0.78 }
local HOLY = "Interface\\Icons\\Spell_Holy_HolyBolt"
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local LEFT_W, RIGHT_W = 452, 252
local ROW_H, ROW_GAP = 48, 4
local SIDE_COL = 118 -- (the rewards of a quest, on the right of its row, and its button)
local DAY_ROWS, WEEK_ROWS = 4, 2
local MOTES = 16
local ARM = 3
-- (the room of the case: the banner of the paladins, 16:9 on its texture; the medallion of the case on its front)
local ROOM_ASPECT = 16 / 9
local MEDAL = { 0.4014, 0.5986, 0.0996, 0.4941 }
-- (the case of the quests, on a line of text: the top of its lid, as the alert of a case shows it)
local CASE_TEX = "|T%s:%d:%d:0:0:1024:1024:214:810:0:596|t"
-- its achievements, along the foot of the page (Achievements.lua): its quests, the first case opened, the priceless
-- card, the whole collection, the culling (a secret one: its question mark until it is earned)
A.DISCOVERY_ACH = { "qdisc:1", "qdisc:10", "qdisc:25", "qdisc:50", "qdisc:100", "copen:1", "crank5", "ccollall", "sCulling" }

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

local function Text(parent, size, color, justify, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	ns.SetFont(fs, size, flags)
	if not flags or flags == "" then
		fs:SetShadowOffset(1, -1)
		fs:SetShadowColor(0, 0, 0, 1)
	end
	if color then
		fs:SetTextColor(color[1], color[2], color[3])
	end
	fs:SetJustifyH(justify or "LEFT")
	return fs
end

-- A panel of the cathedral: dark blue, a line of gold around it.
local function Panel(parent, w, h)
	local p = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(p, w, h)
	p.bg = p:CreateTexture(nil, "BACKGROUND")
	p.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(p.bg, 0.02, 0.03, 0.07, 0.78)
	p.edge = {}
	for _, pt in ipairs({ { "TOPLEFT", "TOPRIGHT", "h" }, { "BOTTOMLEFT", "BOTTOMRIGHT", "h" }, { "TOPLEFT", "BOTTOMLEFT", "v" }, { "TOPRIGHT", "BOTTOMRIGHT", "v" } }) do
		local t = p:CreateTexture(nil, "BORDER")
		t:SetPoint(pt[1])
		t:SetPoint(pt[2])
		if pt[3] == "h" then
			t:SetHeight(1)
		else
			t:SetWidth(1)
		end
		CuratorOctoFull.ColorTexture(t, GOLD[1], GOLD[2], GOLD[3], 0.4)
		p.edge[CuratorOctoFull.Length(p.edge) + 1] = t
	end
	return p
end

-- A round icon of the game (its border cut off).
local function RoundIcon(parent, size, file, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	CuratorOctoFull.SetSize(t, size, size)
	t:SetTexture(file)
	t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	local m = CuratorOctoFull.CreateMaskTexture(parent)
	m:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(t)
	CuratorOctoFull.AddMaskTexture(t, m)
	return t
end

-- The medallion of the case (a coin of gold and blue).
local function Medal(parent, size, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	CuratorOctoFull.SetSize(t, size, size)
	t:SetTexture(MEDIA .. ns.CaseTexture("CratePal1Front"))
	t:SetTexCoord(MEDAL[1], MEDAL[2], MEDAL[3], MEDAL[4])
	local m = CuratorOctoFull.CreateMaskTexture(parent)
	m:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(t)
	CuratorOctoFull.AddMaskTexture(t, m)
	return t
end

local function CaseText(size)
	-- (1.14.0: the lid in the language of the game, Core.lua: ns.CaseTexture)
	return string.format(CASE_TEX, MEDIA .. ns.CaseTexture("CratePal1Top"), size, size)
end
A.DiscoveryCaseText = CaseText

local function Armed(b)
	return b.armed ~= nil and GetTime() - b.armed < ARM
end

-------------------------------------------------------------------------------
-- Building
-------------------------------------------------------------------------------
local function NewQuestRow(parent, w)
	local r = Panel(parent, w, ROW_H)
	r.icon = RoundIcon(r, 34, HOLY)
	r.icon:SetPoint("LEFT", 8, 0)
	r.ring = r:CreateTexture(nil, "OVERLAY")
	r.ring:SetTexture(MEDIA .. "Glow")
	r.ring:SetBlendMode("ADD")
	r.ring:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	CuratorOctoFull.SetSize(r.ring, 54, 54)
	r.ring:SetPoint("CENTER", r.icon, "CENTER")
	r.ring:SetAlpha(0.3)
	-- (what to do, two lines at most; under it, how far, on its bar)
	local mid = w - 52 - SIDE_COL
	r.text = Text(r, 11, PALE)
	r.text:SetPoint("TOPLEFT", 50, -4)
	r.text:SetWidth(mid)
	r.text:SetHeight(26)
	r.text:SetJustifyV("TOP")
	CuratorOctoFull.SetWordWrap(r.text, true)
	r.bar = S.ThinBar(r, mid - 4, 9, GOLD)
	r.bar:SetPoint("BOTTOMLEFT", 52, 5)
	r.count = Text(r.bar, 9, { 1, 1, 1 }, "CENTER", "OUTLINE")
	r.count:SetDrawLayer("OVERLAY", 7)
	r.count:SetPoint("CENTER", r.bar, "CENTER", 0, 0)
	-- (its rewards, on the right: the experience; its case and its rubies, or its button once it is done)
	r.xp = Text(r, 11, { 1, 0.82, 0.25 }, "RIGHT")
	r.xp:SetPoint("TOPRIGHT", -10, -6)
	r.gift = Text(r, 11, { 1, 0.92, 0.75 }, "RIGHT")
	r.gift:SetPoint("BOTTOMRIGHT", -10, 7)
	r.claim = S.Button(r, L["Claim"], SIDE_COL - 20, 20)
	r.claim:SetPoint("BOTTOMRIGHT", -9, 5)
	r.done = r:CreateTexture(nil, "OVERLAY")
	r.done:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	CuratorOctoFull.SetSize(r.done, 18, 18)
	r.done:SetPoint("BOTTOMRIGHT", -10, 6)
	r.doneText = Text(r, 11, { 0.45, 0.9, 0.45 }, "RIGHT")
	r.doneText:SetPoint("RIGHT", r.done, "LEFT", -4, 0)
	r.doneText:SetText(L["Claimed"])
	CuratorOctoFull.SetScript(r.claim, "OnClick", function()
		A:DiscoveryClaim(r)
	end)
	r:EnableMouse(true)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:DiscoveryQuestTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return r
end

local function Head(page, text, x, y)
	local h = page:CreateFontString(nil, "OVERLAY")
	Fancy(h, 18, "OUTLINE")
	h:SetPoint("TOPLEFT", x, y)
	h:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	h:SetText(text)
	return h
end

function A:BuildDiscovery()
	local f = self.frame
	if f.discovery then
		return
	end
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 6, -4)
	page:SetPoint("BOTTOMRIGHT", -6, 4)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	CuratorOctoFull.SetClipsChildren(page, true)
	page:Hide()
	f.discovery = page
	-- the banner of the paladins, the room of the case, as wide as the page (its sides cut), dimmed
	page.bg = page:CreateTexture(nil, "BACKGROUND", nil, -2)
	page.bg:SetAllPoints()
	page.bg:SetTexture(MEDIA .. "CrateRoomPal1")
	page.bg:SetVertexColor(0.5, 0.5, 0.56)
	page.shade = page:CreateTexture(nil, "BACKGROUND", nil, -1)
	page.shade:SetAllPoints()
	page.shade:SetTexture(MEDIA .. "Vignette")
	page.shade:SetVertexColor(0, 0, 0, 1)
	-- the motes of light that drift up in the room
	page.motes = {}
	for i = 1, MOTES do
		local m = page:CreateTexture(nil, "BORDER", nil, 1)
		m:SetTexture(MEDIA .. "Glow")
		m:SetBlendMode("ADD")
		m:SetVertexColor(1, 0.9, 0.62)
		m:SetAlpha(0)
		page.motes[i] = m
	end
	-- the banner of the page: its name in the letters of the titles, the medallion of the case on each side, its time
	page.title = page:CreateFontString(nil, "OVERLAY")
	Fancy(page.title, 24, "OUTLINE")
	page.title:SetPoint("TOP", 0, -14)
	page.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	page.title:SetShadowOffset(2, -2)
	page.title:SetShadowColor(0, 0, 0, 1)
	CuratorOctoFull.SetWordWrap(page.title, false)
	page.titleGlow = page:CreateTexture(nil, "ARTWORK")
	page.titleGlow:SetTexture(MEDIA .. "Glow")
	page.titleGlow:SetBlendMode("ADD")
	page.titleGlow:SetVertexColor(1, 0.82, 0.4)
	CuratorOctoFull.SetSize(page.titleGlow, 520, 100)
	page.titleGlow:SetPoint("CENTER", page.title, "CENTER", 0, -2)
	page.titleGlow:SetAlpha(0.3)
	page.medals = {}
	for i, side in ipairs({ -1, 1 }) do
		local glow = page:CreateTexture(nil, "ARTWORK")
		glow:SetTexture(MEDIA .. "Glow")
		glow:SetBlendMode("ADD")
		glow:SetVertexColor(1, 0.84, 0.45)
		CuratorOctoFull.SetSize(glow, 96, 96)
		local m = Medal(page, 40, "OVERLAY")
		m.side = side
		glow:SetPoint("CENTER", m, "CENTER")
		m.glow = glow
		page.medals[i] = m
	end
	page.sub = Text(page, 12, { 1, 1, 1 }, "CENTER")
	page.sub:SetPoint("TOP", page.title, "BOTTOM", 0, -6)
	-- the quests: four of the day, two of the week
	local top = -70
	page.dayHead = Head(page, L["Quests of the day"], 16, top)
	page.dayLeft = Text(page, 11, GREY, "RIGHT")
	page.dayLeft:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", 16 + LEFT_W, top - 20)
	page.rows = {}
	for i = 1, DAY_ROWS do
		local r = NewQuestRow(page, LEFT_W)
		r:SetPoint("TOPLEFT", 16, top - 26 - (i - 1) * (ROW_H + ROW_GAP))
		r.board = "palDaily"
		r.i = i
		page.rows[CuratorOctoFull.Length(page.rows) + 1] = r
	end
	local wtop = top - 26 - DAY_ROWS * (ROW_H + ROW_GAP) - 6
	page.weekHead = Head(page, L["Quests of the week"], 16, wtop)
	page.weekLeft = Text(page, 11, GREY, "RIGHT")
	page.weekLeft:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", 16 + LEFT_W, wtop - 20)
	for i = 1, WEEK_ROWS do
		local r = NewQuestRow(page, LEFT_W)
		r:SetPoint("TOPLEFT", 16, wtop - 26 - (i - 1) * (ROW_H + ROW_GAP))
		r.board = "palWeekly"
		r.i = i
		page.rows[CuratorOctoFull.Length(page.rows) + 1] = r
	end
	local bottom = wtop - 26 - WEEK_ROWS * (ROW_H + ROW_GAP) + ROW_GAP
	-- the cases: the case turning, how many to open, the keys, the collection
	local side = Panel(page, RIGHT_W, top - bottom)
	side:SetPoint("TOPRIGHT", -16, top)
	page.side = side
	side.head = side:CreateFontString(nil, "OVERLAY")
	Fancy(side.head, 17, "OUTLINE")
	side.head:SetPoint("TOP", 0, -10)
	side.head:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	side.head:SetText(L["Your cases"])
	side.boxAt = CreateFrame("Frame", nil, side)
	CuratorOctoFull.SetSize(side.boxAt, RIGHT_W - 40, 124)
	side.boxAt:SetPoint("TOP", 0, -32)
	side.spot = side:CreateTexture(nil, "BORDER")
	side.spot:SetTexture(MEDIA .. "Spotlight")
	side.spot:SetBlendMode("ADD")
	side.spot:SetPoint("TOP", 0, -26)
	CuratorOctoFull.SetSize(side.spot, RIGHT_W - 20, 150)
	side.spot:SetVertexColor(1, 0.88, 0.6, 0.2)
	side.count = Text(side, 15, GOLD, "CENTER")
	side.count:SetPoint("TOP", side.boxAt, "BOTTOM", 0, -4)
	side.keys = Text(side, 12, { 1, 1, 1 }, "CENTER")
	side.keys:SetPoint("TOP", side.count, "BOTTOM", 0, -4)
	side.cards = Text(side, 11, GREY, "CENTER")
	side.cards:SetPoint("TOP", side.keys, "BOTTOM", 0, -4)
	side.cards:SetWidth(RIGHT_W - 20)
	side.note = Text(side, 11, { 0.86, 0.82, 0.7 }, "CENTER")
	side.note:SetPoint("TOP", side.cards, "BOTTOM", 0, -10)
	side.note:SetWidth(RIGHT_W - 30)
	CuratorOctoFull.SetWordWrap(side.note, true)
	side.album = S.Button(side, L["See the collection"], RIGHT_W - 40, 22)
	side.album:SetPoint("BOTTOM", 0, 12)
	CuratorOctoFull.SetScript(side.album, "OnClick", function()
		ns.Play(ns.SND.page)
		local D = ns.Discovery
		if A.ShowCases and D then
			A:ShowCases(D.CASE, "collection")
		end
	end)
	side.buy = S.Button(side, "", RIGHT_W - 40, 22)
	side.buy:SetPoint("BOTTOM", side.album, "TOP", 0, 6)
	CuratorOctoFull.SetScript(side.buy, "OnClick", function(b)
		A:DiscoveryBuyKey(b)
	end)
	CuratorOctoFull.SetScript(side.buy, "OnEnter", function(b)
		A:DiscoveryKeyTooltip(b)
	end)
	CuratorOctoFull.SetScript(side.buy, "OnLeave", function()
		GameTooltip:Hide()
	end)
	side.open = S.Button(side, "", RIGHT_W - 40, 26)
	side.open:SetPoint("BOTTOM", side.buy, "TOP", 0, 6)
	CuratorOctoFull.SetScript(side.open, "OnClick", function()
		local D = ns.Discovery
		if D and ns.CrateUI then
			ns.Play(ns.SND.click)
			ns.CrateUI:Show(D.CASE)
		end
	end)
	-- its achievements, along the foot of the page
	page.achHead = page:CreateFontString(nil, "OVERLAY")
	Fancy(page.achHead, 16, "OUTLINE")
	page.achHead:SetPoint("BOTTOMLEFT", 16, 52)
	page.achHead:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	page.achHead:SetText(L["Achievements of the discovery"])
	page.ach = {}
	CuratorOctoFull.SetScript(page, "OnUpdate", function(_, elapsed)
		A:DiscoveryTick(elapsed)
	end)
	CuratorOctoFull.SetScript(page, "OnHide", function(p)
		if p.side.box then
			p.side.box:SetIdle(false)
		end
	end)
end

-- The buttons of its achievements (made once they are known: Achievements.lua).
function A:DiscoveryAchButtons(page)
	local ids = A.DISCOVERY_ACH
	for i, id in ipairs(ids) do
		local i, id = i, id; local b = page.ach[i]
		if not b then
			b = CreateFrame("Button", nil, page)
			CuratorOctoFull.SetSize(b, 38, 38)
			b:SetPoint("BOTTOMLEFT", 16 + (i - 1) * 46, 10)
			b.icon = RoundIcon(b, 34, HOLY)
			b.icon:SetPoint("CENTER")
			b.ring = b:CreateTexture(nil, "OVERLAY")
			b.ring:SetTexture(MEDIA .. "Glow")
			b.ring:SetBlendMode("ADD")
			CuratorOctoFull.SetSize(b.ring, 54, 54)
			b.ring:SetPoint("CENTER")
			b.ring:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
			b.check = b:CreateTexture(nil, "OVERLAY", nil, 2)
			b.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			CuratorOctoFull.SetSize(b.check, 15, 15)
			b.check:SetPoint("BOTTOMRIGHT", 2, -2)
			CuratorOctoFull.SetScript(b, "OnEnter", function(self)
				A:DiscoveryAchTooltip(self)
			end)
			CuratorOctoFull.SetScript(b, "OnLeave", function()
				GameTooltip:Hide()
			end)
			CuratorOctoFull.SetScript(b, "OnClick", function(self)
				local a = ns.Achievements and ns.Achievements.byId[self.id]
				if a and A.ShowAchievement then
					A:ShowAchievement(a)
				end
			end)
			page.ach[i] = b
		end
		b.id = id
	end
	for i = CuratorOctoFull.Length(ids) + 1, CuratorOctoFull.Length(page.ach) do
		page.ach[i]:Hide()
	end
end

function A:ShowDiscoveryPage(shown)
	local f = self.frame
	if shown then
		self:BuildDiscovery()
	end
	if f.discovery then
		CuratorOctoFull.SetShown(f.discovery, shown)
	end
end

-- The album opened on the page of the discovery.
function A:ShowDiscovery()
	if not self.frame then
		self:Build()
	end
	if not self.frame:IsShown() then
		self:Show()
	end
	self:SetMode("discovery")
end

-------------------------------------------------------------------------------
-- Painting
-------------------------------------------------------------------------------
-- (the quest each row shows, and its board: kept here, not on the row, which another addon reaches)
local SHOWS = setmetatable({}, { __mode = "k" })

local function SetIcon(tex, kind)
	local icon = ns.Quests.Icon and ns.Quests.Icon(kind) or { HOLY }
	ns.SetIcon(tex, icon)
	tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

function A:PaintDiscoveryRow(r, board, q)
	local Q = ns.Quests
	SHOWS[r] = q and { q = q, board = board } or nil
	if not q then
		r:Hide()
		return
	end
	r:Show()
	SetIcon(r.icon, q.k)
	r.text:SetText(Q:Text(q))
	local got, n = math.min(q.got or 0, q.n or 1), q.n or 1
	r.bar:SetValue(got / math.max(1, n))
	r.count:SetText(string.format(("%s / %s"), ns.Num(got), ns.Num(n)))
	r.xp:SetText(string.format(L["+%s XP"], ns.Num(Q:XP(q))))
	local gift = {}
	if (tonumber(q.c) or 0) > 0 then
		gift[CuratorOctoFull.Length(gift) + 1] = CaseText(16) .. " x" .. q.c
	end
	local rubies = Q:Rubies(board, q)
	if rubies > 0 and ns.Rubies and ns.Rubies.Gem then
		gift[CuratorOctoFull.Length(gift) + 1] = ns.Rubies.Gem(12) .. " " .. ns.Num(rubies)
	end
	r.gift:SetText(table.concat(gift, "   "))
	local ready = q.done and not q.claimed
	-- (a reroll claims none, Reroll.lua: RR:Blocks)
	local rr = ns.Reroll ~= nil and ns.Reroll:Blocks("quests")
	CuratorOctoFull.SetShown(r.claim, ready and true or false)
	CuratorOctoFull.SetEnabled(r.claim, (ready and not rr) and true or false)
	CuratorOctoFull.SetShown(r.gift, not ready and not q.claimed)
	CuratorOctoFull.SetShown(r.done, q.claimed ~= nil)
	CuratorOctoFull.SetShown(r.doneText, q.claimed ~= nil)
	r.ring:SetAlpha(ready and 0.75 or (q.claimed and 0.12 or 0.3))
	for _, e in ipairs(r.edge) do
		e:SetAlpha(ready and 1 or 0.4)
	end
	local c = q.claimed and 0.6 or nil
	r.text:SetTextColor(c or PALE[1], c or PALE[2], c or PALE[3])
end

function A:RefreshDiscovery()
	local f = self.frame
	local page = f.discovery
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	local D, Q, CS = ns.Discovery, ns.Quests, ns.Cases
	if not (D and Q and page) then
		return
	end
	local case = D.CASE
	local def = ns.Crates and ns.Crates[case]
	local title = L[(def and def.title) or "Paladin Collection Case No. 1"]
	local on = D:On()
	local left = on and string.format(L["The discovery lasts %s more"], ns.Duration(D:Left())) or L["The discovery is over."]
	local cases = CS and CS:Count(case) or 0
	local keys = CS and CS:Keys(case) or 0
	self:SetTitle(title, string.format(L["Cases to open: %d  ·  Keys: %d"], cases, keys))
	-- (the bar of the head: the cards of its collection)
	if CS and CS.Progress then
		local got, all = CS:Progress(case)
		got, all = tonumber(got) or 0, tonumber(all) or 0
		self:SetBar(got, math.max(1, all), string.format(L["%d / %d cards"], got, all))
	end
	-- (the room cut to the shape of the page)
	local w, h = page:GetWidth() or 756, page:GetHeight() or 549
	local keep = math.min(1, (w / math.max(1, h)) / ROOM_ASPECT)
	page.bg:SetTexCoord((1 - keep) / 2, 1 - (1 - keep) / 2, 0, 1)
	-- (its name as large as the page lets it be; the medallions on each side of it)
	page.title:SetText(string.format(L["Discovery of the %s"], title))
	local room = w - 150
	for _, size in ipairs({ 24, 21, 18, 16 }) do
		Fancy(page.title, size, "OUTLINE")
		if (page.title:GetStringWidth() or 0) <= room then
			break
		end
	end
	local tw = math.min(room, page.title:GetStringWidth() or room)
	for _, m in ipairs(page.medals) do
		m:ClearAllPoints()
		m:SetPoint("CENTER", page.title, "CENTER", m.side * (tw / 2 + 32), 0)
	end
	page.sub:SetText(left)
	-- the quests
	Q:Check()
	local day = Q:List("palDaily")
	local week = Q:List("palWeekly")
	for i = 1, DAY_ROWS do
		self:PaintDiscoveryRow(page.rows[i], Q.byKey.palDaily, day[i])
	end
	for i = 1, WEEK_ROWS do
		self:PaintDiscoveryRow(page.rows[DAY_ROWS + i], Q.byKey.palWeekly, week[i])
	end
	local moreDay = Q:ChainLeft("palDaily")
	local moreWeek = Q:ChainLeft("palWeekly")
	page.dayLeft:SetText(moreDay > 0 and string.format(L["+%d to come · new ones in %s"], moreDay, ns.Duration(Q:ResetLeft("day")))
		or string.format(L["New ones in %s"], ns.Duration(Q:ResetLeft("day"))))
	page.weekLeft:SetText(moreWeek > 0 and string.format(L["+%d to come · new ones in %s"], moreWeek, ns.Duration(Q:ResetLeft("week")))
		or string.format(L["New ones in %s"], ns.Duration(Q:ResetLeft("week"))))
	-- the cases
	local side = page.side
	if not side.box and ns.CrateBox then
		side.box = ns.CrateBox.New(side.boxAt, 170)
		side.box:SetPoint("CENTER", side.boxAt, "CENTER", 0, -4)
		side.box:SetFrameLevel(side:GetFrameLevel() + 2)
		side.box:Paint()
	end
	if side.box then
		side.box:SetArt(def and def.art and def.art.box or nil)
		side.box:SetGhost(cases <= 0)
		side.box:SetAlpha(cases > 0 and 1 or 0.5)
		side.box:Show()
		side.box:SetIdle(true)
	end
	side.count:SetText(string.format(L["Cases to open: %d"], cases))
	side.count:SetTextColor(cases > 0 and GOLD[1] or 0.6, cases > 0 and GOLD[2] or 0.6, cases > 0 and GOLD[3] or 0.62)
	side.keys:SetText(string.format(L["Keys: %d"], keys))
	if CS and CS.Progress then
		local got, all = CS:Progress(case)
		side.cards:SetText(string.format(L["Cards of the collection: %d / %d"], tonumber(got) or 0, tonumber(all) or 0))
	end
	side.note:SetText(string.format(L["Each quest of the discovery gives a case of its collection; a key of %s opens one."], 
		(ns.Rubies and CS) and ns.Rubies.Text(CS:KeyPrice(), 11) or "999"))
	side.open:SetText(cases > 0 and L["Open the case"] or L["See the case"])
	local RB = ns.Rubies
	if Armed(side.buy) then
		side.buy:SetText(L["Confirm"])
	else
		side.buy:SetText(L["Buy a key"] .. "  " .. ((RB and CS) and RB.Text(CS:KeyPrice(), 12) or ""))
	end
	-- its achievements
	self:DiscoveryAchButtons(page)
	local AC = ns.Achievements
	local earned = AC and AC:Earned() or {}
	local anyAch = false
	for i, b in ipairs(page.ach) do
		local a = AC and AC.byId[b.id]
		local shown = a ~= nil and i <= CuratorOctoFull.Length(A.DISCOVERY_ACH)
		CuratorOctoFull.SetShown(b, shown)
		if shown then
			anyAch = true
			local icon = a.icon
			if type(icon) == "table" then
				ns.SetIcon(b.icon, icon)
			else
				b.icon:SetTexture(icon or HOLY)
			end
			b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			-- (a secret one, not earned: its question mark, Achievements.lua)
			if a.secret and not earned[a.id] then
				b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
			local got = earned[a.id] ~= nil
			CuratorOctoFull.SetDesaturated(b.icon, not got)
			b.icon:SetVertexColor(got and 1 or 0.55, got and 1 or 0.55, got and 1 or 0.55)
			CuratorOctoFull.SetShown(b.check, got)
			b.ring:SetAlpha(got and 0.6 or 0.15)
		end
	end
	CuratorOctoFull.SetShown(page.achHead, anyAch)
end

-- Every frame: the motes of light drift up, the title and the medallions glow; once a second, the time it lasts.
function A:DiscoveryTick(elapsed)
	local page = self.frame and self.frame.discovery
	if not page then
		return
	end
	page.t = (page.t or 0) + elapsed
	local t = page.t
	page.titleGlow:SetAlpha(0.24 + 0.08 * math.sin(t * 1.5) + (page.burst or 0) * 0.5)
	for i, m in ipairs(page.medals) do
		m.glow:SetAlpha(0.3 + 0.18 * math.sin(t * 1.9 + i * 2.2) + (page.burst or 0) * 0.6)
	end
	if page.burst then
		page.burst = page.burst - elapsed * 1.2
		if page.burst <= 0 then
			page.burst = nil
		end
	end
	local w, h = page:GetWidth() or 756, page:GetHeight() or 549
	for i, m in ipairs(page.motes) do
		if not m.life or t >= m.t0 + m.life then
			-- (a new one, low in the room, now and then; all of them at once in a burst)
			local r = math.random()
			m.t0 = t + ((m.life and not page.burstNow) and r * 2.5 or 0)
			m.life = 5 + r * 5
			m.x0 = 0.05 + 0.9 * math.random()
			m.y0 = 0.55 + 0.45 * math.random()
			m.size = 8 + 14 * math.random()
			m.sway = 0.01 + 0.02 * math.random()
			CuratorOctoFull.SetSize(m, m.size, m.size)
		end
		local u = (t - m.t0) / m.life
		if u < 0 then
			m:SetAlpha(0)
		else
			local x = m.x0 + m.sway * math.sin(u * 6.28 + i)
			local y = m.y0 - 0.5 * u
			m:ClearAllPoints()
			m:SetPoint("CENTER", page, "TOPLEFT", w * x, -h * y)
			m:SetAlpha(0.55 * math.sin(math.min(1, u) * math.pi) * (page.burst and 1.6 or 1))
		end
	end
	page.burstNow = nil
	page.tickT = (page.tickT or 0) + elapsed
	if page.tickT >= 1 then
		page.tickT = 0
		local D = ns.Discovery
		if D and D:On() then
			page.sub:SetText(string.format(L["The discovery lasts %s more"], ns.Duration(D:Left())))
		end
		-- (the key armed for a few seconds: asked again once it is no more)
		local b = page.side and page.side.buy
		if b and b.armed and not Armed(b) then
			b.armed = nil
			A:RefreshDiscovery()
		end
	end
end

-- A burst of light: a quest claimed.
function A:DiscoveryBurst()
	local page = self.frame and self.frame.discovery
	if not page then
		return
	end
	page.burst = 1
	page.burstNow = true
	for _, m in ipairs(page.motes) do
		m.life = nil
	end
end

-------------------------------------------------------------------------------
-- Claims, keys, tooltips
-------------------------------------------------------------------------------
function A:DiscoveryClaim(r)
	local Q = ns.Quests
	local x = SHOWS[r]
	local board, q = x and x.board, x and x.q
	if not (board and q and q.done and not q.claimed) then
		return
	end
	if ns.Reroll and ns.Reroll:Blocks("quests") then
		ns.Reroll:SayNot("quests")
		return
	end
	Q:Claim(board, q)
	ns.Play(ns.SND.claim)
	self:DiscoveryBurst()
	self:RefreshDiscovery()
	self:PaintBadges()
end

-- A key bought from the page: a first click arms the button, a second within its seconds pays.
function A:DiscoveryBuyKey(b)
	local CS, D = ns.Cases, ns.Discovery
	if not (CS and D) then
		return
	end
	if not Armed(b) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:RefreshDiscovery()
		self:DiscoveryKeyTooltip(b)
		return
	end
	b.armed = nil
	GameTooltip:Hide()
	local ok, why = CS:BuyKey(D.CASE, 1)
	if not ok then
		ns.Play(ns.SND.close)
		local text = (why == "rubies" and L["Not enough rubies."]) or (why == "guard" and ns.Guard and L[ns.Guard.SHORT])
			or L["Curator is closed: no case can be opened."]
		ns.Print("|cffff6060" .. text .. "|r")
		self:RefreshDiscovery()
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.claim)
	local def = ns.Crates and ns.Crates[D.CASE]
	ns.Print(L["A key of the %s, for %s."], L[(def and def.title) or "Paladin Collection Case No. 1"], ns.Rubies.Text(CS:KeyPrice()))
	self:RefreshDiscovery()
end

function A:DiscoveryKeyTooltip(b)
	local CS, D, RB = ns.Cases, ns.Discovery, ns.Rubies
	if not (CS and D and RB) then
		return
	end
	local def = ns.Crates and ns.Crates[D.CASE]
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(string.format(L["A key of the %s"], L[(def and def.title) or "Paladin Collection Case No. 1"]), 1, 0.84, 0.26)
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(CS:KeyPrice(), 13)), 1, 0.82, 0.25)
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 0.85, 0.85, 0.88)
	GameTooltip:AddLine(Armed(b) and L["Click again to confirm."] or L["Click, then click again to confirm."], 0.3, 1, 0.3)
	GameTooltip:Show()
end

function A:DiscoveryQuestTooltip(r)
	local x = SHOWS[r]
	local q, board = x and x.q, x and x.board
	if not q then
		return
	end
	local Q = ns.Quests
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Q:Text(q), PALE[1], PALE[2], PALE[3], true)
	GameTooltip:AddLine(A:RewardLine(board, q), 1, 0.82, 0.25, true)
	local rr = ns.Reroll ~= nil and ns.Reroll:Blocks("quests")
	if q.claimed then
		GameTooltip:AddLine(L["Claimed"], 0.4, 1, 0.4)
	elseif q.done and not rr then
		GameTooltip:AddLine(L["Done: claim its rewards"], 0.4, 1, 0.4)
	end
	local k = Q.KINDS[q.k]
	if k and (k.spells or k.pal) and q.k ~= "rez" then
		GameTooltip:AddLine(k.spells and L["A spell of the paladins: any paladin of your account counts."]
			or L["Played with a paladin of your account."], 0.7, 0.7, 0.7, true)
	else
		GameTooltip:AddLine(L["Every character of your account counts, while the discovery lasts."], 0.7, 0.7, 0.7, true)
	end
	if rr then
		GameTooltip:AddLine(ns.Reroll:WhyNot("quests"), 1, 0.62, 0.45, true)
	end
	GameTooltip:Show()
end

function A:DiscoveryAchTooltip(b)
	local AC = ns.Achievements
	local a = AC and AC.byId[b.id]
	if not a then
		return
	end
	local sn = AC:Snapshot()
	local goal = AC:Goal(a, sn)
	local v = math.min(goal, a.value(sn, ns.db))
	local got = AC:Earned()[a.id] ~= nil
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(AC:Name(a), got and 1 or 0.85, got and 0.82 or 0.85, got and 0 or 0.85)
	GameTooltip:AddLine(AC:Desc(a, sn), 1, 1, 1, true)
	GameTooltip:AddDoubleLine(string.format(L["%d points"], a.pts), got and L["Earned"] or string.format(("%s / %s"), ns.Num(v), ns.Num(goal)), 1, 0.82, 0, 1, 1, 1)
	GameTooltip:Show()
end

-- The badge on its tab: its rewards waiting (as the save has them: the quests are looked at again elsewhere).
function A:DiscoveryWaiting()
	local n = 0
	local quests = ns.db and ns.db.quests or {}
	for _, key in ipairs({ "palDaily", "palWeekly" }) do
		local entry = quests[key]
		for _, q in ipairs((type(entry) == "table" and type(entry.list) == "table" and entry.list) or {}) do
			if type(q) == "table" and q.done and not q.claimed then
				n = n + 1
			end
		end
	end
	return n
end

for _, e in ipairs({ "QUESTS_CHANGED", "CASES_CHANGED", "RUBIES_CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		local f = A.frame
		if f and f.discovery and f.discovery:IsShown() and A.mode == "discovery" then
			A:RefreshDiscovery()
		end
	end)
end
