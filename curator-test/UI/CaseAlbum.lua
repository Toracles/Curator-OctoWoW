local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Ease = ns.Ease
local A = ns.Album

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) The album of a collection of the cases (the mode "cases" of the album): opened from
-- its tile in the contents (UI/Album.lua: the tab Cases), from the inventory (UI/CaseInventory.lua).
-- (1.14.0, after its second test: « les mêmes menus que les cartes de boosters ») Its pages as the pages of an album of
-- the boosters: its name and its case in the head, its progress in the bar, the gems of its ranks (a click shows only
-- that rank, a second click all of them), the gems of its finishes (the cards won in that finish), the bar clicked (the
-- cards won only); its cards in their slots, eighteen a page, in the order of its case (its ranks, the golden card of
-- the priceless rank, then the weapons of legend won): won, its finest copy, how many, its grade when it was appraised,
-- the copies to exchange on a seal of wax; not won yet, engraved into the page. Under the mouse a card rises in its
-- light; a click shows it big (UI/CaseDetail.lua), as a card of a booster; a right click, its copies to exchange into a
-- contract (UI/Contract.lua: the desk of the notary). The pages turn as the pages of an album. Under the page: back to
-- the contents, its cases and its keys, its copies to exchange, Open a case.
-------------------------------------------------------------------------------
local CR = ns.CrateUI
local GOLD = S.GOLD
-- the pages of an album (UI/Album.lua: the same grid, the same cards)
local COLS, ROWS = 6, 3
local PER_PAGE = COLS * ROWS
local CW, CH = unpack(ns.CARD_SIZES.small)
local GAP_X, GAP_Y, PAD, GRID_TOP = 12, 14, 18, 14
-- the gems of the ranks (UI/CaseDetail.lua: the same), of the finishes
local GEM = { { "Gem3" }, { "Gem4" }, { "Gem4", { 1, 0.6, 0.86 } }, { "Gem6" }, { "Gem5" } }
local FINS = {
	{ key = "thunder", gem = "Gem7", label = "Thunderforged", colour = { 0.55, 0.8, 1 } },
	{ key = "titan", gem = "Gem8", label = "Titanforged", colour = { 1, 0.84, 0.46 } },
}
local FIN_INK = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.86, 0.46 } }
local FIN_RANK = { titan = 2, thunder = 1 }

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-------------------------------------------------------------------------------
-- What is seen of a card won: never the grade hidden in its condition
-------------------------------------------------------------------------------
-- How fine it looks: appraised, its grade (told); else nothing (31 October, his word: its condition shows on it, its
-- wear, never told: nor by the order of its copies).
local function Looks(w)
	if w.ap then
		return 100 + (tonumber(w.g) or 0)
	end
	return 0
end

-- Finer (a before b): what is seen of it, its finish, the most recent.
local function Finer(a, b)
	local la, lb = Looks(a), Looks(b)
	if la ~= lb then
		return la > lb
	end
	local fa, fb = FIN_RANK[a.f or ""] or 0, FIN_RANK[b.f or ""] or 0
	if fa ~= fb then
		return fa > fb
	end
	return (a.i or 0) > (b.i or 0)
end
A.CaseFiner = Finer

-- What is told of it: appraised, its grade; its finish before it (31 October, his word: never its condition in words;
-- nil: nothing to tell).
local function Said(w)
	local E = ns.Expertise
	local text = w.ap and E and E.Label(w.g) or nil
	if w.f and CR.FINISH_NAME[w.f] then
		local fin = "|cff" .. Hex(FIN_INK[w.f]) .. L[CR.FINISH_NAME[w.f]] .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or "") .. "|r"
		text = text and (fin .. "  ·  " .. text) or fin
	end
	return text
end

-------------------------------------------------------------------------------
-- The cards of a collection
-------------------------------------------------------------------------------
-- The cards of the collection of an edition, in the order of its case: { tier, entry | secret | weapon, n, best,
-- list, fins }.
function A:CaseTiles(case)
	local CS, CI = ns.Cases, ns.CrateItems
	local own = CI:Case(case)
	local by, weapons, nw = {}, {}, 0
	for _, w in ipairs(CS:Won(case)) do
		local k = w.e or (w.w and ("w" .. tostring(w.w)))
		if k then
			local list = by[k]
			if not list then
				list = {}
				by[k] = list
				if w.w then
					weapons[CuratorOctoFull.Length(weapons) + 1] = w.w
				end
			end
			list[CuratorOctoFull.Length(list) + 1] = w
			if w.w then
				nw = nw + 1
			end
		end
	end
	local function Of(k, x)
		local list = by[k]
		if list then
			table.sort(list, Finer)
			x.n, x.best, x.list = CuratorOctoFull.Length(list), list[1], list
			x.fins = {}
			for _, w in ipairs(list) do
				if w.f then
					x.fins[w.f] = true
				end
			end
		end
		return x
	end
	local out = {}
	for r = 1, CR.TOP - 1 do
		for _, e in ipairs(own and own[r] or {}) do
			out[CuratorOctoFull.Length(out) + 1] = Of(e.key, { tier = r, entry = e })
		end
	end
	out[CuratorOctoFull.Length(out) + 1] = { tier = CR.TOP, secret = true, n = nw }
	table.sort(weapons)
	for _, id in ipairs(weapons) do
		out[CuratorOctoFull.Length(out) + 1] = Of("w" .. tostring(id), { tier = CR.TOP, weapon = id })
	end
	return out
end

-- The cards shown on its pages: all of them, or those of the rank of the filter, those won only (the bar clicked), those
-- won in the finish of the filter.
function A:CaseCards(case)
	local out = {}
	for _, x in ipairs(self:CaseTiles(case)) do
		local ok = true
		if self.caseRank and x.tier ~= self.caseRank then
			ok = false
		end
		if ok and (self.caseFound or self.caseFin) then
			if x.secret then
				ok = false
			elseif not x.best then
				ok = false
			elseif self.caseFin and not (x.fins and x.fins[self.caseFin]) then
				ok = false
			end
		end
		if ok then
			out[CuratorOctoFull.Length(out) + 1] = x
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- The pieces: its slots, the gems of its head, the bar under its page
-------------------------------------------------------------------------------
-- A slot of the page: its card of a case (UI/CrateCard.lua), engraved into the page when it is not won yet; its count,
-- the seal of its copies to exchange; the light under the mouse.
local function NewSlot(parent, i)
	local c = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(c, CW, CH)
	c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	c.W, c.H = CW, CH
	local col, row = CuratorOctoFull.Mod((i - 1) , COLS), math.floor((i - 1) / COLS)
	c.bx, c.by = PAD + col * (CW + GAP_X), -GRID_TOP - row * (CH + GAP_Y)
	c.col = col
	c.lift, c.dx, c.dy = 1, 0, 0
	c.glow = c:CreateTexture(nil, "BACKGROUND")
	c.glow:SetTexture(MEDIA .. "Glow")
	c.glow:SetBlendMode("ADD")
	c.glow:SetPoint("TOPLEFT", -26, 30)
	c.glow:SetPoint("BOTTOMRIGHT", 26, -30)
	c.glow:SetAlpha(0)
	c.card = ns.CrateCard.New(c, CW)
	c.card:SetPoint("CENTER", c, "CENTER", 0, 0)
	c.card:SetFrameLevel(c:GetFrameLevel() + 1)
	local top = CreateFrame("Frame", nil, c)
	top:SetAllPoints()
	top:SetFrameLevel(c:GetFrameLevel() + 24)
	c.top = top
	-- (not won yet: dark, engraved into the page)
	c.shade = top:CreateTexture(nil, "BACKGROUND")
	c.shade:SetPoint("TOPLEFT", 3, -3)
	c.shade:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(c.shade, 0.02, 0.02, 0.04, 0.62)
	c.shade:Hide()
	c.engrave = top:CreateTexture(nil, "ARTWORK")
	c.engrave:SetTexture(MEDIA .. "Engrave")
	c.engrave:SetPoint("TOPLEFT", -1, 1)
	c.engrave:SetPoint("BOTTOMRIGHT", 1, -1)
	c.engrave:Hide()
	-- its copies (x3), the copies it has to exchange: a seal of wax with their number
	c.count = top:CreateFontString(nil, "OVERLAY")
	ns.SetFont(c.count, 11, "OUTLINE")
	c.count:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 9, 6)
	c.count:SetTextColor(1, 0.92, 0.7)
	c.spare = CreateFrame("Frame", nil, top)
	CuratorOctoFull.SetSize(c.spare, 24, 24)
	c.spare:SetPoint("CENTER", c, "BOTTOMRIGHT", -9, 13)
	c.spare.tex = c.spare:CreateTexture(nil, "ARTWORK")
	c.spare.tex:SetAllPoints()
	c.spare.tex:SetTexture(MEDIA .. "Seal")
	c.spare.text = c.spare:CreateFontString(nil, "OVERLAY")
	ns.SetFont(c.spare.text, 10, "OUTLINE")
	c.spare.text:SetPoint("CENTER", 0.5, 0)
	c.spare.text:SetTextColor(1, 0.96, 0.86)
	c.spare:Hide()
	CuratorOctoFull.SetScript(c, "OnEnter", function(self)
		A:CaseSlotEnter(self)
	end)
	CuratorOctoFull.SetScript(c, "OnLeave", function(self)
		A:CaseSlotLeave(self)
	end)
	CuratorOctoFull.SetScript(c, "OnClick", function(self, button)
		A:CaseSlotClick(self, button)
	end)
	A:PlaceSlot(c)
	c:Hide()
	return c
end

-- A gem of the head: its gem, its count; a glow and a line under it when it is the filter.
local function NewChip(f, gem, tint, colour)
	local b = CreateFrame("Button", nil, f)
	CuratorOctoFull.SetSize(b, 40, 16)
	b.mark = b:CreateTexture(nil, "BACKGROUND")
	b.mark:SetTexture(MEDIA .. "Glow")
	b.mark:SetBlendMode("ADD")
	b.mark:SetPoint("TOPLEFT", -14, 9)
	b.mark:SetPoint("BOTTOMRIGHT", 14, -9)
	b.mark:SetVertexColor(colour[1], colour[2], colour[3])
	b.mark:SetAlpha(0.45)
	b.mark:Hide()
	b.gem = b:CreateTexture(nil, "ARTWORK")
	b.gem:SetTexture(MEDIA .. gem)
	if tint then
		b.gem:SetVertexColor(tint[1], tint[2], tint[3])
	end
	CuratorOctoFull.SetSize(b.gem, 15, 15)
	b.gem:SetPoint("LEFT")
	b.text = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.text:SetPoint("LEFT", b.gem, "RIGHT", 2, 0)
	b.line = b:CreateTexture(nil, "ARTWORK")
	b.line:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 1)
	b.line:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, 1)
	b.line:SetHeight(1)
	CuratorOctoFull.ColorTexture(b.line, colour[1], colour[2], colour[3], 0.9)
	b.line:Hide()
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end

function A:BuildCases()
	local f = self.frame
	if f.casesA then
		return f.casesA
	end
	local page = CreateFrame("Frame", nil, f.body)
	page:SetAllPoints()
	page:SetFrameLevel(f.body:GetFrameLevel() + 1)
	page:Hide()
	f.casesA = page
	page.slots = {}
	for i = 1, PER_PAGE do
		page.slots[i] = NewSlot(page, i)
	end
	-- the gems of its ranks, from the priceless one on the right; the gems of its finishes left of them, past a rule
	page.ranks = {}
	for r = CR.TOP, 1, -1 do
		local r = r; local g = GEM[r]
		local b = NewChip(f, g[1], g[2], CR.RANKS[r].color)
		b.rank = r
		if r == CR.TOP then
			b:SetPoint("RIGHT", f, "TOPRIGHT", -16, -61)
		else
			b:SetPoint("RIGHT", page.ranks[r + 1], "LEFT", -8, 0)
		end
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetCaseRank(r)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:CaseRankTip(self)
		end)
		page.ranks[r] = b
	end
	page.rule = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(page.rule, 1, 14)
	CuratorOctoFull.ColorTexture(page.rule, GOLD[1], GOLD[2], GOLD[3], 0.35)
	page.rule:SetPoint("RIGHT", page.ranks[1], "LEFT", -9, 0)
	page.rule:Hide()
	page.fins = {}
	for i = CuratorOctoFull.Length(FINS), 1, -1 do
		local i = i; local fin = FINS[i]
		local b = NewChip(f, fin.gem, nil, fin.colour)
		b.fin = fin
		b:SetPoint("RIGHT", (i == CuratorOctoFull.Length(FINS)) and page.rule or page.fins[i + 1], "LEFT", (i == CuratorOctoFull.Length(FINS)) and -9 or -8, 0)
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetCaseFin(fin.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			A:CaseFinTip(self)
		end)
		page.fins[i] = b
	end
	-- under the page: its cases and its keys, its copies to exchange, Open a case
	local foot = CreateFrame("Frame", nil, f)
	foot:SetAllPoints()
	foot:SetFrameLevel(f:GetFrameLevel() + 6)
	foot:Hide()
	page.foot = foot
	foot.text = S.Text(foot, "GameFontNormal", "LEFT")
	foot.open = S.Button(foot, L["Open a case"], 170, 22)
	foot.open:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
	CuratorOctoFull.SetScript(foot.open, "OnClick", function()
		ns.Play(ns.SND.click)
		A:Hide()
		ns.CrateUI:Show(A.caseEdition)
	end)
	CuratorOctoFull.SetScript(foot.open, "OnEnter", function(self)
		local CS = ns.Cases
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(string.format(L["Cases to open: %d  ·  Keys: %d"], CS:Count(A.caseEdition), CS:Keys(A.caseEdition)), 1, 1, 1)
		GameTooltip:AddLine(L["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(foot.open, "OnLeave", function()
		GameTooltip:Hide()
	end)
	foot.trade = S.Button(foot, "", 170, 22)
	foot.trade:SetPoint("RIGHT", foot.open, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(foot.trade, "OnClick", function()
		ns.Play(ns.SND.click)
		if A.CaseContractFor then
			A:CaseContractFor(nil, A.caseEdition)
		end
	end)
	CuratorOctoFull.SetScript(foot.trade, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(string.format(L["Copies to exchange: %d"], self.n or 0), 1, 1, 1)
		GameTooltip:AddLine(L["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."], 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine(L["Click: to the contracts"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(foot.trade, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- (the album hidden: its slots as they were, its cards come in again next time)
	f:HookScript("OnHide", function()
		for _, c in ipairs(page.slots) do
			if c.slideTw then
				ns.CancelTween(c.slideTw)
				c.slideTw = nil
			end
			c.lift, c.dx, c.dy = 1, 0, 0
			c:SetAlpha(1)
			A:PlaceSlot(c)
		end
		if A.caseTurnTw then
			ns.CancelTween(A.caseTurnTw)
			A.caseTurnTw, A.caseTurnTo, A.caseTurnDir = nil, nil, nil
		end
		A.caseView = nil
	end)
	return page
end

-------------------------------------------------------------------------------
-- Opened, shown
-------------------------------------------------------------------------------
-- The album of a collection of the cases (case: its edition; nil, the edition of now). (view: kept for its callers of
-- before, its pages only now: its contracts are on the desk of the notary, UI/Contract.lua.)
function A:ShowCases(case, view)
	local CS = ns.Cases
	if not CS then
		return
	end
	self:Build()
	local was = self.caseEdition
	self.caseEdition = (case and CS:Known(case)) and case or self.caseEdition or CS.EDITION
	if was ~= self.caseEdition then
		self.casePage, self.caseRank, self.caseFin, self.caseFound = 1, nil, nil, nil
	end
	if view == "contracts" and self.CaseContractFor then
		return self:CaseContractFor(nil, self.caseEdition)
	end
	-- (back from it: to the tab of the cases of the contents)
	self.mode, self.member, self.memberEntries, self.returnMode, self.tocReturn = "cases", nil, nil, nil, true
	self:HideDetail()
	self:Reveal()
end

function A:ShowCasesPage(shown)
	local f = self.frame
	if shown then
		self:BuildCases()
	end
	local page = f.casesA
	if not page then
		return
	end
	CuratorOctoFull.SetShown(page, shown)
	CuratorOctoFull.SetShown(page.foot, shown)
	if not shown then
		for _, b in ipairs(page.ranks) do
			b:Hide()
		end
		for _, b in ipairs(page.fins) do
			b:Hide()
		end
		page.rule:Hide()
	end
end

-- The arrows of the pages (and the wheel of the mouse).
function A:CasesPage(delta)
	local pages = self.casePages or 1
	local from = self.caseTurnTo or self.casePage or 1
	local p = math.max(1, math.min(pages, from + delta))
	if p ~= from then
		self:HideDetail()
		self:CaseTurnPage(p, delta > 0 and 1 or -1)
	end
end

-- The page turns as the pages of an album do (UI/Album.lua: A:TurnPage): its cards slide away the way it turns, a light
-- passes over it, the cards of the next one slide in from the other side.
function A:CaseTurnPage(p, dir)
	local page = self.frame.casesA
	ns.Play(ns.SND.page)
	self.caseTurnTo, self.caseTurnDir = p, dir
	if self.caseTurnTw then
		ns.CancelTween(self.caseTurnTw)
	end
	local any = false
	for _, c in ipairs(page.slots) do
		local _, c = _, c; if c:IsShown() and c:GetAlpha() > 0.05 then
			any = true
			if c.slideTw then
				ns.CancelTween(c.slideTw)
			end
			local x0, a0 = c.dx or 0, c:GetAlpha()
			local order = dir > 0 and c.col or (COLS - 1 - c.col)
			c.slideTw = ns.Tween(0.13, function(e)
				c.dx = x0 - 34 * dir * e
				c:SetAlpha(a0 * (1 - e))
				A:PlaceSlot(c)
			end, nil, Ease.inQuad, self, order * 0.012)
		end
	end
	self:SweepPage(dir)
	local function go()
		A.caseTurnTw, A.caseTurnTo = nil, nil
		A.casePage = p
		A:Refresh()
	end
	if any then
		self.caseTurnTw = ns.Delay(0.13 + (COLS - 1) * 0.012, go, self)
	else
		go()
	end
end

function A:SetCaseRank(r)
	self.caseRank = (self.caseRank ~= r) and r or nil
	self.casePage = 1
	self:HideDetail()
	ns.Play(ns.SND.page)
	self:Refresh()
	local b = self.frame.casesA.ranks[r]
	if b and b:IsMouseOver() then
		self:CaseRankTip(b)
	end
end

function A:SetCaseFin(key)
	self.caseFin = (self.caseFin ~= key) and key or nil
	self.casePage = 1
	self:HideDetail()
	ns.Play(ns.SND.page)
	self:Refresh()
end

-- (the bar of the head clicked, on the pages of a collection of the cases: the cards won only)
do
	local toggleFound = A.ToggleFound
	function A:ToggleFound(...)
		if self.mode == "cases" then
			self.caseFound = not self.caseFound or nil
			self.casePage = 1
			self:HideDetail()
			ns.Play(ns.SND.page)
			self:Refresh()
			if self.frame.bar.hit:IsMouseOver() then
				self:BarTooltip(self.frame.bar)
			end
			return
		end
		return toggleFound(self, unpack(arg, 1, arg.n))
	end
	local barTooltip = A.BarTooltip
	function A:BarTooltip(bar, ...)
		if self.mode == "cases" then
			GameTooltip:SetOwner(bar, "ANCHOR_BOTTOM")
			GameTooltip:AddLine(bar.text:GetText() or "", 1, 1, 1)
			GameTooltip:AddLine(self.caseFound and L["Click to show all the cards"] or L["Click to show only the cards found"], GOLD[1], GOLD[2], GOLD[3])
			GameTooltip:Show()
			return
		end
		return barTooltip(self, bar, unpack(arg, 1, arg.n))
	end
end

function A:CaseRankTip(b)
	local r = CR.RANKS[b.rank]
	local tc = r.text or r.color
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L[r.label], tc[1], tc[2], tc[3])
	if b.rank == CR.TOP then
		GameTooltip:AddLine(string.format(L["Weapons of legend: %d"], b.found or 0), 1, 1, 1)
	else
		GameTooltip:AddLine(string.format(L["%d / %d cards"], b.found or 0, b.total or 0), 1, 1, 1)
	end
	GameTooltip:AddLine(self.caseRank == b.rank and L["Click to show all the cards"] or L["Click to show only these cards"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

function A:CaseFinTip(b)
	local fin = b.fin
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L[fin.label], fin.colour[1], fin.colour[2], fin.colour[3])
	GameTooltip:AddLine(string.format(L["%d / %d cards"], b.found or 0, b.total or 0), 1, 1, 1)
	GameTooltip:AddLine(self.caseFin == fin.key and L["Click to show all the cards"] or L["Click to show only these cards"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
-- (a card set again only when it changes: setting it loads its creature again)
local function Sig(x)
	local b = x.best
	return table.concat({ x.tier, tostring(x.entry and x.entry.key or x.weapon or "?"), b and tostring(b.i) or "-", b and tostring(b.f) or "",
		b and ns.Cases.WearKey(b) or "", x.n or 0 }, ":")
end

local function PaintSlot(c, x, case)
	local CD = ns.CaseDetail
	c.x = x
	local sig = Sig(x)
	local card = c.card
	if c.sig ~= sig then
		c.sig = sig
		local pick
		if x.best then
			pick = CD.PickOf(CD.DescOf(x.best), x.best)
		elseif x.secret then
			pick = { tier = CR.TOP, secret = true, def = ns.Crates and ns.Crates[case] }
		elseif x.weapon then
			pick = { tier = CR.TOP, weapon = { id = x.weapon } }
		else
			pick = { tier = x.tier, entry = x.entry }
		end
		card:Set(pick, CR.RANKS)
		local def = ns.Crates and ns.Crates[case]
		card:SetBack(def and def.art and def.art.back or nil)
		card:SetLive(true)
	end
	local won = (x.n or 0) > 0
	CuratorOctoFull.SetShown(c.shade, not won)
	CuratorOctoFull.SetShown(c.engrave, not won)
	card:SetAlpha(won and 1 or 0.55)
	c.count:SetText((x.n or 0) > 1 and ("x" .. x.n) or "")
	-- its copies to exchange (UI/Contract.lua), its grade when it was appraised (UI/Expertise.lua)
	local spare = (won and not x.secret and CD) and CD:Spare(CD.DescOf(x.best), x.list) or 0
	CuratorOctoFull.SetShown(c.spare, spare > 0)
	c.spare.text:SetText(spare > 9 and "9+" or tostring(spare))
	if A.PaintGrade then
		A:PaintGrade(c, (x.best and x.best.ap) and (tonumber(x.best.g) or nil) or nil)
	end
	c:Show()
end

function A:RefreshCases()
	local f = self.frame
	local page = self:BuildCases()
	local CS = ns.Cases
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(true)
	self:RefreshFooter(false)
	local case = self.caseEdition
	if not (case and CS:Known(case)) then
		case = CS.EDITION
		self.caseEdition = case
	end
	local def = ns.Crates and ns.Crates[case]
	local all = self:CaseTiles(case)
	local cards = self:CaseCards(case)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(cards) / PER_PAGE))
	self.casePages = pages
	self.casePage = math.max(1, math.min(pages, self.casePage or 1))
	-- the head: its name, its case; its progress; the gems of its ranks and of its finishes
	local owned, total, nw = CS:Progress(case)
	local coll = L[(CS.COLLECTION and CS.COLLECTION[case]) or "Paladin Collection 2026"]
	self:SetTitle(coll, L[(def and def.title) or "Test case"])
	self:SetBar(owned, total, string.format(L["%d / %d cards"], owned, total))
	local found, of = {}, {}
	for r = 1, CR.TOP do
		found[r], of[r] = 0, 0
	end
	local fins = { thunder = 0, titan = 0 }
	for _, x in ipairs(all) do
		if not x.secret then
			if not x.weapon then
				of[x.tier] = of[x.tier] + 1
			end
			if x.best then
				found[x.tier] = found[x.tier] + 1
				for k in pairs(x.fins or {}) do
					fins[k] = (fins[k] or 0) + 1
				end
			end
		end
	end
	for r, b in ipairs(page.ranks) do
		b.found, b.total = found[r], of[r]
		b.text:SetText(r == CR.TOP and tostring(nw) or string.format(("%d/%d"), found[r], of[r]))
		b:SetWidth(17 + math.ceil(ns.TextWidth(b.text, 30)))
		local on = self.caseRank == r
		CuratorOctoFull.SetShown(b.mark, on)
		CuratorOctoFull.SetShown(b.line, on)
		b:SetAlpha((self.caseRank and not on) and 0.5 or 1)
		b:Show()
	end
	page.rule:Show()
	for _, b in ipairs(page.fins) do
		b.found, b.total = fins[b.fin.key] or 0, total
		b.text:SetText(tostring(b.found))
		b:SetWidth(17 + math.ceil(ns.TextWidth(b.text, 12)))
		local on = self.caseFin == b.fin.key
		CuratorOctoFull.SetShown(b.mark, on)
		CuratorOctoFull.SetShown(b.line, on)
		b:SetAlpha((self.caseFin and not on) and 0.5 or 1)
		b:Show()
	end
	-- its cards: those of the page come in one after the other (from the side the page turns from)
	local view = table.concat({ case, self.casePage, self.caseRank or 0, self.caseFin or "", self.caseFound and 1 or 0 }, ":")
	local turned = view ~= self.caseView
	self.caseView = view
	local asked = false
	for i, c in ipairs(page.slots) do
		local x = cards[(self.casePage - 1) * PER_PAGE + i]
		if x then
			PaintSlot(c, x, case)
			if turned then
				self:SlideIn(c, i, self.caseTurnDir)
			end
			-- (a weapon the game does not know yet: its name asked for, the page painted again a moment later)
			if x.weapon and not ns.CrateCard.WeaponName({ id = x.weapon }) then
				ns.CrateCard.Ask(x.weapon)
				asked = true
			end
		else
			c:Hide()
			c.x, c.sig = nil, nil
		end
	end
	self.caseTurnDir = nil
	if asked and (self.casesAsked or 0) < 20 then
		self.casesAsked = (self.casesAsked or 0) + 1
		ns.Delay(0.5, function()
			if self.frame:IsShown() and self.mode == "cases" then
				self:Refresh()
			end
		end, self)
	elseif not asked then
		self.casesAsked = 0
	end
	local label = string.format(L["Page %d / %d"], self.casePage, pages)
	if self.caseRank then
		local r = CR.RANKS[self.caseRank]
		label = "|cff" .. Hex(r.text or r.color) .. L[r.label] .. "|r  ·  " .. label
	end
	if self.caseFound then
		label = L["Found"] .. "  ·  " .. label
	end
	if self.caseFin then
		for _, fin in ipairs(FINS) do
			if fin.key == self.caseFin then
				label = "|cff" .. Hex(fin.colour) .. L[fin.label] .. "|r  ·  " .. label
			end
		end
	end
	self:SetPager(self.casePage, pages, label)
	self:ShowGold(owned >= total and total > 0, owned, total)
	-- (filters that leave the page empty: said on it)
	CuratorOctoFull.SetShown(f.wait, CuratorOctoFull.Length(cards) == 0)
	if CuratorOctoFull.Length(cards) == 0 then
		f.wait.text:SetText(L["No card found with these filters."])
	end
	-- under the page: its cases and its keys, its copies to exchange, Open a case
	local foot = page.foot
	foot.text:ClearAllPoints()
	if f.back:IsShown() then
		foot.text:SetPoint("LEFT", f.back, "RIGHT", 12, 0)
	else
		foot.text:SetPoint("LEFT", f, "BOTTOMLEFT", 14, 15)
	end
	local n, keys = CS:Count(case), CS:Keys(case)
	foot.text:SetText(string.format(L["Cases to open: %d  ·  Keys: %d"], n, keys))
	foot.open:SetLabel(n > 0 and string.format(L["Open a case (%d)"], n) or L["See the case"])
	local spare = 0
	local CD = ns.CaseDetail
	if CD then
		for _, x in ipairs(all) do
			if x.best and not x.secret then
				spare = spare + CD:Spare(CD.DescOf(x.best), x.list)
			end
		end
	end
	foot.trade.n = spare
	CuratorOctoFull.SetShown(foot.trade, spare > 0)
	foot.trade:SetLabel(string.format(L["Duplicates: %d"], spare))
end

-------------------------------------------------------------------------------
-- Its cards under the mouse, clicked
-------------------------------------------------------------------------------
function A:CaseSlotEnter(c)
	local x = c.x
	if not x then
		return
	end
	local CI, CC = ns.CrateItems, ns.CrateCard
	local r = CR.RANKS[x.tier] or CR.RANKS[1]
	local tc = r.text or r.color
	GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
	if x.secret then
		GameTooltip:AddLine(L["Priceless card"], tc[1], tc[2], tc[3])
		GameTooltip:AddLine(L["A weapon of legend. Which one stays a mystery."], 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine(string.format(L["Weapons of legend: %d"], x.n or 0), 1, 1, 1)
		GameTooltip:AddLine(L["Click to view"], GOLD[1], GOLD[2], GOLD[3])
	else
		local name = x.weapon and (CC.WeaponName({ id = x.weapon }) or L["Priceless card"]) or CI:Name(x.entry)
		GameTooltip:AddLine(name, tc[1], tc[2], tc[3])
		GameTooltip:AddLine(L[r.label], 0.7, 0.7, 0.72)
		if x.best then
			GameTooltip:AddLine(string.format(L["Copies: %d"], x.n), 1, 1, 1)
			local said = Said(x.best)
			if said then
				GameTooltip:AddLine(string.format(L["Your finest: %s"], said), 0.9, 0.9, 0.92)
			end
			local CD = ns.CaseDetail
			local spare = CD and CD:Spare(CD.DescOf(x.best), x.list) or 0
			if spare > 0 then
				GameTooltip:AddLine(string.format(L["Copies to exchange: %d"], spare), 1, 0.62, 0.5)
				GameTooltip:AddLine(L["Right click: into an exchange contract"], GOLD[1], GOLD[2], GOLD[3])
			end
			GameTooltip:AddLine(L["Click: show this copy"], 0.4, 1, 0.4)
		else
			GameTooltip:AddLine(L["Not in your collection yet."], 0.62, 0.62, 0.66)
			GameTooltip:AddLine(L["Click to view"], GOLD[1], GOLD[2], GOLD[3])
		end
	end
	GameTooltip:Show()
	local col = r.color
	c.glow:SetVertexColor(col[1], col[2], col[3])
	c.glow:SetAlpha(0.45)
	self:LiftSlot(c, 1.07)
end

function A:CaseSlotLeave(c)
	GameTooltip:Hide()
	c.glow:SetAlpha(0)
	self:LiftSlot(c, 1)
end

function A:CaseSlotClick(c, button)
	local x = c.x
	if not x then
		return
	end
	local CD = ns.CaseDetail
	if x.best then
		local desc = CD.DescOf(x.best)
		-- shift-click: the card in the chat (UI/Links.lua)
		if ns.Links and ns.Links.Modified and ns.Links:Modified() and ns.Links.InsertCase then
			return ns.Links:InsertCase(x.best)
		end
		-- right click: its copies to exchange into a contract
		if button == "RightButton" then
			if self.CaseContractFor and CD:Spare(desc, x.list) > 0 then
				self:CaseContractFor(desc)
			end
			return
		end
		ns.Play(ns.SND.cardFlip)
		self:CaseSlotLeave(c)
		return self:ShowCaseDetail(desc, x.best.i)
	end
	if button == "RightButton" then
		return
	end
	ns.Play(ns.SND.cardFlip)
	self:CaseSlotLeave(c)
	if x.secret then
		CR:ViewEntry(self.caseEdition, nil, nil)
	elseif x.weapon then
		CR:ViewEntry(self.caseEdition, CR.TOP, nil)
	else
		CR:ViewEntry(self.caseEdition, x.tier, x.entry)
	end
end

-- (a case opened, a card appraised, a contract signed: the page as it is now)
ns.On("CASES_CHANGED", function()
	local f = A.frame
	if f and f:IsShown() and (A.mode == "cases" or (A.mode == "contents" and A.tocTab == "cases")) then
		A:Refresh()
	end
end)

