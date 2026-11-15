local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local A = ns.Album
local C = ns.Collection
local CP = ns.Copies
local E = ns.Expertise
local SL = ns.Masters

-------------------------------------------------------------------------------
-- (1.13.0) Each copy on the screen (Copies.lua). A card of mine shown big lists its copies (a chip each: its
-- number among them, its grade, its seal, its corruption; the edge of its finish): the one chosen is the one shown
-- (in its case, its reliquary, its corruption), the one the expert appraises, the masters seal or purify, the
-- enchanters restore (UI/Restore.lua); its story under them (when, how, where it came). The chooser of copies: the
-- copies of a card that leave (a trade, a contract, the reseller, a duel, the tavern), the least precious chosen
-- first, the player's choice whenever he wants another.
-------------------------------------------------------------------------------
local CU = { sel = {} }
ns.CopiesUI = CU

local GOLD = S.GOLD
local CHIPS = 8 -- the chips of the copies shown big, at most (then "+n": the inventory)
-- the edge of a chip: the colour of the finish of its copy
local EDGE = {
	n = { 0.62, 0.62, 0.66 }, s = { 0.5, 0.72, 1 }, h = { 1, 0.8, 0.42 }, c = { 0.72, 0.36, 1 },
}
local LIT = { 1, 0.86, 0.45 }

-------------------------------------------------------------------------------
-- What is said of a copy
-------------------------------------------------------------------------------
local HOW = {
	b = "From a booster", g = "From a golden booster", f = "From a creature", k = "From a contract", t = "From a trade",
	r = "Bought from the reseller", i = "From an innkeeper", c = "From a gift code", e = "Found while exploring",
	x = "Given by the author", a = "In the album before 1.13.0", m = "Bought at the Exchange",
	-- (1.14.0: the reward of a level, chosen: Level.lua)
	l = "The reward of a level",
}

-- How a copy came, in a few words.
function CU.How(rec)
	local w = rec and rec.w
	if w == "b" and tonumber(rec.bn) then
		return string.format(L["From booster No. %d"], rec.bn)
	elseif w == "t" and type(rec.p) == "string" and rec.p ~= "" then
		return string.format(L["Traded with %s"], rec.p)
	elseif w == "m" and type(rec.p) == "string" and rec.p ~= "" then
		return string.format(L["Bought at the Exchange from %s"], rec.p)
	end
	return L[HOW[w or ""] or "Origin unknown"]
end

local function Day(t)
	t = tonumber(t)
	return (t and t > 0) and date("%d/%m/%Y", t) or nil
end
CU.Day = Day

-- The copies of a card in the order they are shown: those appraised (in their case, the finest first), those sealed,
-- then by finish (titanforged, thunderforged, normal, corrupted), the oldest first.
local FIN_ORDER = { h = 1, s = 2, n = 3, c = 4 }
function CU:Ordered(card)
	local list = {}
	for _, r in ipairs(card and CP:List(card.key) or {}) do
		list[CuratorOctoFull.Length(list) + 1] = r
	end
	local function Rank(r)
		local g = CP.Grade(r)
		if g and r.sl ~= false then
			return 0, -g
		elseif r.ws then
			local _, n = SL:Record(card, r.i)
			return 1, -(n or 0)
		end
		return 2, FIN_ORDER[r.f or "n"] or 3
	end
	table.sort(list, function(a, b)
		local a1, a2 = Rank(a)
		local b1, b2 = Rank(b)
		if a1 ~= b1 then
			return a1 < b1
		end
		if a2 ~= b2 then
			return a2 < b2
		end
		local ta, tb = tonumber(a.t) or 0, tonumber(b.t) or 0
		if ta ~= tb then
			return ta < tb
		end
		return (a.i or 0) < (b.i or 0)
	end)
	return list
end

-- The number of a copy among those of its card, as they are shown (1 to n; nil: not one of them).
function CU:Index(card, id)
	for i, r in ipairs(self:Ordered(card)) do
		if r.i == id then
			return i
		end
	end
	return nil
end

-- (1.14.3) A copy of another player's inventory (Comm.lua): its number among their copies, its seal, as they came
-- (nil: a copy of mine).
local function Theirs(rec)
	return type(rec) == "table" and type(rec.theirs) == "table" and rec.theirs or nil
end
CU.Theirs = Theirs

-- "#2", "#2 · 8,45", "#1 · VII", "#3 · 62 %": the name of a copy on a chip.
function CU:Label(card, rec, i)
	local th = Theirs(rec)
	local head = "#" .. tostring(i or (th and th.n) or (not th and self:Index(card, rec.i)) or "?")
	local g = CP.Grade(rec)
	if g and rec.sl ~= false then
		return head .. " · " .. E.Text(g / 100)
	elseif rec.ws then
		local n
		if th then
			n = th.seal and SL.Valid(th.seal.g) or nil
		else
			n = CuratorOctoFull.Select(2, SL:Record(card, rec.i))
		end
		return head .. " · " .. SL.Roman(n)
	elseif rec.f == "c" then
		return head .. " · " .. string.format(("%d %%"), tonumber(rec.cor) or 0)
	end
	return head
end

-- What its story says in a line: how it came, when, where (brief: not where).
function CU:Short(card, rec, brief)
	if not rec then
		return ""
	end
	local parts = { CU.How(rec) }
	local day = Day(rec.t)
	if day then
		parts[CuratorOctoFull.Length(parts) + 1] = day
	end
	if not brief and type(rec.z) == "string" and rec.z ~= "" then
		parts[CuratorOctoFull.Length(parts) + 1] = rec.z
	end
	return table.concat(parts, "  ·  ")
end

-- (1.14.0, a player's word: a signed copy, a corrupted one, can leave: Copies.lua, CP:Stuck)
local WHY = {
	away = "At an enchanter: it cannot leave your album until it is back.",
	locked = "Came in a trade not free yet: it waits.",
	staked = "Put on a duel: it waits for it.",
}
CU.WHY = WHY

-- Its story in a tooltip: how and when it came, where, who; its expertise, its restorations, its seal, its corruption,
-- why it cannot leave.
function CU:Tooltip(tip, card, rec, full)
	if not (rec and card) then
		return
	end
	-- (1.14.0: a titanforged copy, its pattern)
	local pt = CP.Pattern(rec)
	-- (1.14.3: a copy of another player's inventory: its number among theirs, its seal as it came; nothing of mine holds it)
	local th = Theirs(rec)
	-- (1 November, his word: its pattern told by the masters of the mages only, the line under it, Mages.lua)
	tip:AddLine(string.format(L["Copy %s"], "#" .. tostring((th and th.n) or (not th and self:Index(card, rec.i)) or "?")) .. "  ·  "
		.. (C:FinishName(card, CP.Finish(rec)) or L["Normal copy"]), GOLD[1], GOLD[2], GOLD[3])
	-- (1 November: its certificate of the mages, Mages.lua)
	local ml, certified = ns.Mages and ns.Mages.Line(rec)
	if ml then
		tip:AddLine(ml, certified and 0.86 or 0.6, certified and 0.92 or 0.62, certified and 1 or 0.7)
	end
	local day = Day(rec.t)
	tip:AddLine(CU.How(rec) .. (day and ("  ·  " .. day) or ""), 1, 1, 1)
	local where = {}
	if type(rec.z) == "string" and rec.z ~= "" then
		where[CuratorOctoFull.Length(where) + 1] = rec.z
	end
	if type(rec.ch) == "string" and rec.ch ~= "" then
		where[CuratorOctoFull.Length(where) + 1] = string.format(L["by %s"], rec.ch)
	end
	if CuratorOctoFull.Length(where) > 0 then
		tip:AddLine(table.concat(where, "  ·  "), 0.78, 0.78, 0.8)
	end
	-- (came in a trade: where it came from first)
	local o = type(rec.o) == "table" and rec.o or nil
	if o and (o.w or tonumber(o.t) and o.t > 0) then
		local first = L[HOW[o.w or ""] or "Origin unknown"]
		local od = Day(o.t)
		tip:AddLine(string.format(L["First: %s"], first .. (od and ("  ·  " .. od) or "") .. ((type(o.ch) == "string" and o.ch ~= "") and ("  ·  " .. o.ch) or "")),
			0.7, 0.72, 0.78, true)
	end
	local g = CP.Grade(rec)
	if g and rec.sl ~= false then
		local at = Day(rec.at)
		tip:AddLine(string.format(L["Grade: %s"], E.Label(g / 100)) .. (at and ("  ·  " .. at) or ""), 1, 1, 1)
		local m = E.DecodeMarks(rec.m)
		if full and m then
			tip:AddLine(E.MarksText(m), 0.78, 0.8, 0.86, true)
		end
		if full and tonumber(rec.ce) then
			tip:AddLine(string.format(L["Certificate No. %s"], E.CertText(rec.ce)), 0.62, 0.62, 0.66)
		end
	elseif g then
		tip:AddLine(L["Its case opened: its grade is known at its next appraisal."], 0.72, 0.86, 1, true)
	end
	local rs = type(rec.r) == "table" and rec.r or {}
	if CuratorOctoFull.Length(rs) > 0 then
		-- (1 November, 12 h 56: ten restorations the same day: each day once; more than two days, the last one)
		local days, seen = {}, {}
		for _, x in ipairs(rs) do
			local d = Day(type(x) == "table" and x[1]) or "?"
			if not seen[d] then
				seen[d] = true
				days[CuratorOctoFull.Length(days) + 1] = d
			end
		end
		local line
		if CuratorOctoFull.Length(rs) == 1 then
			line = string.format(L["Restored once: %s"], days[1])
		elseif CuratorOctoFull.Length(days) <= 2 then
			line = string.format(L["Restored %d times: %s"], CuratorOctoFull.Length(rs), table.concat(days, ", "))
		else
			line = string.format(L["Restored %d times, the last on %s"], CuratorOctoFull.Length(rs), days[CuratorOctoFull.Length(days)])
		end
		tip:AddLine(line, 0.66, 0.9, 1, true)
	end
	if CP.Away(rec) and ns.Restore and ns.Restore.AwayText then
		tip:AddLine(ns.Restore:AwayText(rec), 0.6, 0.85, 1, true)
	end
	if rec.ws then
		local x, n
		if th then
			x = th.seal
			n = x and SL.Valid(x.g) or nil
		else
			x, n = SL:Record(card, rec.i)
		end
		if n then
			tip:AddLine(string.format(L["Sealed: %s"], SL.Label(n)) .. ((x and Day(x.t)) and ("  ·  " .. Day(x.t)) or ""), 1, 1, 1)
		end
	end
	if rec.f == "c" then
		tip:AddLine(string.format(L["A corrupted copy: %d %%"], tonumber(rec.cor) or 0), 0.82, 0.6, 1)
	end
	if tonumber(rec.pu) then
		tip:AddLine(string.format(L["Purified on %s"], Day(rec.pu)), 1, 0.92, 0.7)
	end
	if rec.sg then
		tip:AddLine(L["Signed by its innkeeper"], 1, 0.86, 0.5)
	end
	local why = (not th) and CP:Stuck(card.key, rec) or nil
	if why and why ~= "corrupt" and why ~= "signed" and why ~= "away" then
		tip:AddLine(L[WHY[why]], 1, 0.62, 0.4, true)
	end
end

-------------------------------------------------------------------------------
-- The copy chosen of a card shown big
-------------------------------------------------------------------------------
-- The copy shown first: of the finish shown when there is one (the filter of the album), its finest appraised, its
-- finest seal, else its finest finish, the oldest.
function CU:Default(card, finish)
	local list = self:Ordered(card)
	local fk = finish and CP.Key(finish) or nil
	if finish and finish ~= "normal" then
		for _, r in ipairs(list) do
			if r.f == fk then
				return r
			end
		end
	end
	return list[1]
end

-- The copy chosen of a card (mine; nil: none).
function CU:Selected(card)
	if not (card and ns.db and C:Owned(card)) then
		return nil
	end
	local id = self.sel[card.key]
	local rec = id and CP:Get(card.key, id)
	if not rec then
		rec = self:Default(card, A.detail and A.detail.shown == card and A.detail.finish or nil)
		self.sel[card.key] = rec and rec.i or nil
	end
	return rec
end

function CU:Select(card, id)
	if not card then
		return
	end
	self.sel[card.key] = id
	local d = A.detail
	if d and d:IsShown() and d.shown == card then
		self:Apply(d)
		A:PaintCopies(card)
		if ns.ExpertiseUI then
			ns.ExpertiseUI:PaintDetail("after")
		end
	end
	ns.Fire("COPY_SELECTED", card, id)
end

-- The card shown big as its copy chosen: its finish, its corruption, its signature.
function CU:Apply(d)
	local card = d and d.shown
	local rec = card and A.mode ~= "member" and self:Selected(card)
	local c = d and d.card
	if not (rec and c and c.opts) then
		return
	end
	local o = c.opts
	local finish = CP.Finish(rec)
	local signed = rec.sg == true
	-- (1.14.0: a titanforged copy, its pattern, Patterns.lua)
	local pt = CP.Pattern(rec)
	d.finish, d.pattern = finish, pt
	-- (1 November: its certificate of the mages, as a link of the chat carries it, UI/Links.lua)
	d.tc = pt and ns.Mages and ns.Mages.Pack(ns.Mages.Of(rec)) or nil
	-- (his idea, 31 October: the wear of this copy, Wear.lua)
	local wear = ns.Wear and ns.Wear.Of(rec) or nil
	-- (31 October: the flaws an enchanter mended, his mishaps, with it)
	local wk = wear and (tostring(wear.seed) .. table.concat(wear.m, "") .. ":" .. tostring(wear.x or "") .. ":" .. tostring(wear.a or "")) or ""
	local wk0 = o.wear and (tostring(o.wear.seed) .. table.concat(o.wear.m, "") .. ":" .. tostring(o.wear.x or "") .. ":" .. tostring(o.wear.a or "")) or ""
	if (o.signed and true or false) ~= signed then
		o.signed = signed
		o.finish, o.corrupt, o.creep, o.pattern, o.wear = finish, rec.cor, nil, pt, wear
		c:SetCard(card, o)
	elseif o.finish ~= finish or o.corrupt ~= rec.cor or o.creep ~= nil or o.pattern ~= pt or wk ~= wk0 then
		o.finish, o.corrupt, o.creep, o.pattern, o.wear = finish, rec.cor, nil, pt, wear
		-- (1.14.0: held in 3D, its pieces dressed again with it: Card:Refinish)
		c:Refinish()
	end
end

-------------------------------------------------------------------------------
-- The chips of the copies
-------------------------------------------------------------------------------
-- (1.14.0) The copy each chip shows, and what each row of the chooser shows: kept here, not on the chip or the row,
-- which another addon reaches (EnumerateFrames): the copies are the save's own tables.
local RECS = setmetatable({}, { __mode = "k" })

-- What a chip or a row of the chooser shows (the copy of a chip; for a row: { rec, stuck }).
function CU:Shows(b)
	return RECS[b]
end

local function Chip(parent, onClick)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, 40, 18)
	b.edge = b:CreateTexture(nil, "BACKGROUND")
	b.edge:SetAllPoints()
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.bg:SetPoint("TOPLEFT", 1, -1)
	b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
	b.text = S.Text(b, "GameFontHighlightSmall")
	b.text:SetPoint("CENTER")
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.hl, 1, 1, 1, 0.08)
	CuratorOctoFull.SetScript(b, "OnClick", onClick)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end
CU.Chip = Chip

-- (lit: the copy chosen; dim: away, it cannot be chosen for what is asked)
function CU.PaintChip(b, text, fk, lit, dim)
	b.text:SetText(text)
	b:SetWidth(math.max(34, math.ceil(ns.TextWidth(b.text)) + 14))
	local c = lit and LIT or EDGE[fk or "n"] or EDGE.n
	CuratorOctoFull.ColorTexture(b.edge, c[1], c[2], c[3], lit and 0.95 or (dim and 0.3 or 0.6))
	if lit then
		CuratorOctoFull.ColorTexture(b.bg, 0.16, 0.12, 0.04, 0.95)
		b.text:SetTextColor(1, 1, 1)
	else
		CuratorOctoFull.ColorTexture(b.bg, 0.05, 0.05, 0.07, 0.95)
		if dim then
			b.text:SetTextColor(0.5, 0.5, 0.52)
		else
			b.text:SetTextColor(0.86, 0.86, 0.9)
		end
	end
	b:Show()
end

function CU:BuildDetail(d)
	if d.strip or not d.copies then
		return
	end
	local st = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(st, d.textW or 374, 18)
	st:SetPoint("LEFT", d.copies, "RIGHT", 10, 0)
	st.chips = {}
	for i = 1, CHIPS do
		local i = i; local b = Chip(st, function(self)
			local rec = RECS[self]
			if d.shown and rec then
				ns.Play(ns.SND.click)
				CU:Select(d.shown, rec.i)
			end
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			local rec = RECS[self]
			if d.shown and rec then
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				CU:Tooltip(GameTooltip, d.shown, rec, true)
				GameTooltip:AddLine(L["Click to show it."], 0.4, 1, 0.4)
				GameTooltip:Show()
			end
		end)
		st.chips[i] = b
	end
	st.more = Chip(st, function()
		if d.shown and ns.InventoryUI then
			ns.Play(ns.SND.click)
			ns.InventoryUI:OpenOn(d.shown)
		end
	end)
	CuratorOctoFull.SetScript(st.more, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Every copy of it: the inventory"], 1, 1, 1)
		GameTooltip:Show()
	end)
	st:Hide()
	d.strip = st
	-- (the strip steps aside with what there is to know, during an appraisal and a rite)
	if d.infoParts then
		d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = st
	end
end

-- The chips of the card shown big (mine), the copy chosen lit; its story in the line under them.
function CU:PaintStrip(d)
	local st = d and d.strip
	local card = d and d.shown
	if not st then
		return
	end
	local mine = card and A.mode ~= "member" and C:Owned(card)
	if not mine then
		st:Hide()
		return
	end
	local list = self:Ordered(card)
	local sel = self:Selected(card)
	local room = (d.textW or 374) - ns.TextWidth(d.copies) - 10
	local x, shown = 0, 0
	for i, b in ipairs(st.chips) do
		local rec = list[i]
		RECS[b] = rec
		if rec then
			CU.PaintChip(b, self:Label(card, rec, i), rec.f, sel == rec, CP.Away(rec))
			local w = b:GetWidth()
			local rest = CuratorOctoFull.Length(list) - i
			-- (the room of a "+n" kept when more follow)
			if x + w > room - (rest > 0 and 40 or 0) and i > 1 then
				b:Hide()
				RECS[b] = nil
			else
				b:ClearAllPoints()
				b:SetPoint("LEFT", st, "LEFT", x, 0)
				x = x + w + 4
				shown = i
			end
		else
			b:Hide()
		end
	end
	local more = CuratorOctoFull.Length(list) - shown
	if more > 0 then
		CU.PaintChip(st.more, "+" .. more, nil, false)
		st.more:ClearAllPoints()
		st.more:SetPoint("LEFT", st, "LEFT", x, 0)
	else
		st.more:Hide()
	end
	CuratorOctoFull.SetShown(st, CuratorOctoFull.Length(list) > 1)
	-- the line of its story
	if sel and d.found then
		d.found:SetText(self:Short(card, sel))
		-- (too long for its line, or nearly: without its zone)
		local w = d.found:GetWidth()
		if w and w > 0 and ns.TextWidth(d.found) > w * 0.94 then
			d.found:SetText(self:Short(card, sel, true))
		end
	end
end

do
	local buildDetail = A.BuildDetail
	function A:BuildDetail(...)
		local r = buildDetail(self, unpack(arg, 1, arg.n))
		if self.detail then
			CU:BuildDetail(self.detail)
		end
		return r
	end

	local showDetail = A.ShowDetail
	function A:ShowDetail(card, e, ...)
		-- (the copy shown first: of the finish shown, else the finest; chosen again each time it is shown)
		if card then
			CU.sel[card.key] = nil
		end
		local r = showDetail(self, card, e, unpack(arg, 1, arg.n))
		local d = self.detail
		if d and card and self.mode ~= "member" and C:Owned(card) then
			CU.sel[card.key] = nil
			-- (a copy asked for: the inventory, UI/Inventory.lua)
			local want = CU.pending
			CU.pending = nil
			local rec = want and want.key == card.key and CP:Get(card.key, want.id) or CU:Default(card, d.finish)
			CU.sel[card.key] = rec and rec.i or nil
			CU:Apply(d)
			CU:PaintStrip(d)
			if ns.ExpertiseUI then
				ns.ExpertiseUI:PaintDetail("show")
			end
		end
		return r
	end

	local paintCopies = A.PaintCopies
	function A:PaintCopies(card, e, ...)
		local r = paintCopies(self, card, e, unpack(arg, 1, arg.n))
		CU:PaintStrip(self.detail)
		return r
	end
end

-- (a copy gone, come, appraised, sealed: the chips again)
local function Repaint()
	local d = A.detail
	if d and d:IsShown() and d.shown and not (ns.ExpertiseUI and ns.ExpertiseUI.cer) and not (ns.SealUI and ns.SealUI.cer) then
		CU:PaintStrip(d)
	end
	if CU.picker and CU.picker:IsShown() then
		CU:PaintPicker()
	end
end
ns.On("CHANGED", Repaint)
ns.On("COPIES_CHANGED", Repaint)

-------------------------------------------------------------------------------
-- The chooser: the copies of a card that leave
-------------------------------------------------------------------------------
local ROWS = 8
local ROW_H = 30
local PICK_W = 470

-- The copies a chooser offers: those that can leave, the least precious first (those that cannot, after them, shown
-- grey when asked: why).
function CU:Choices(card, finish, showStuck)
	local out = {}
	local fk = CP.Key(finish)
	for _, r in ipairs(CP:Free(card.key, finish)) do
		out[CuratorOctoFull.Length(out) + 1] = { rec = r }
	end
	if showStuck then
		for _, r in ipairs(CP:List(card.key)) do
			if r.f == fk and CP:Stuck(card.key, r) then
				out[CuratorOctoFull.Length(out) + 1] = { rec = r, stuck = CP:Stuck(card.key, r) }
			end
		end
	end
	return out
end

local function BuildPicker()
	local f = CreateFrame("Frame", "CuratorCopyPicker", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, PICK_W, 126 + ROWS * ROW_H)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	CuratorOctoFull.SetClampedToScreen(f, true)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
	end
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("TOPLEFT", 18, -16)
	f.title:SetWidth(PICK_W - 60)
	CuratorOctoFull.SetWordWrap(f.title, false)
	f.sub = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
	f.sub:SetWidth(PICK_W - 40)
	CuratorOctoFull.SetWordWrap(f.sub, true)
	f.sub:SetTextColor(0.78, 0.78, 0.82)
	f.close = S.CloseButton(f)
	f.close:SetPoint("TOPRIGHT", -4, -4)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		CU:ClosePicker()
	end)
	f.rows = {}
	for i = 1, ROWS do
		local i = i; local r = S.ListButton(f)
		CuratorOctoFull.SetSize(r, PICK_W - 36, ROW_H - 2)
		r:SetPoint("TOPLEFT", 18, -72 - (i - 1) * ROW_H)
		r.check = r:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(r.check, 18, 18)
		r.check:SetPoint("LEFT", 6, 0)
		r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
		r.tick = r:CreateTexture(nil, "OVERLAY")
		CuratorOctoFull.SetSize(r.tick, 18, 18)
		r.tick:SetPoint("CENTER", r.check, "CENTER")
		r.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		r.chip = Chip(r)
		r.chip:EnableMouse(false)
		r.chip:SetPoint("LEFT", r.check, "RIGHT", 6, 0)
		r.line = S.Text(r, "GameFontHighlightSmall", "LEFT")
		r.line:SetPoint("LEFT", r.chip, "RIGHT", 10, 0)
		r.line:SetPoint("RIGHT", r, "RIGHT", -6, 0)
		CuratorOctoFull.SetWordWrap(r.line, false)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			CU:PickRow(self)
		end)
		CuratorOctoFull.SetScript(r, "OnEnter", function(self)
			local p, it = CU.pick, RECS[self]
			if p and it then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				CU:Tooltip(GameTooltip, p.card, it.rec, true)
				if it.stuck then
					GameTooltip:AddLine(L[WHY[it.stuck] or "It cannot leave now."], 1, 0.45, 0.4, true)
				end
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(r, "OnLeave", function()
			GameTooltip:Hide()
		end)
		r:EnableMouseWheel(true)
		CuratorOctoFull.SetScript(r, "OnMouseWheel", function(_, delta)
			CU:PickScroll(-delta)
		end)
		f.rows[i] = r
	end
	f:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(f, "OnMouseWheel", function(_, delta)
		CU:PickScroll(-delta)
	end)
	f.pos = S.Text(f, "GameFontDisableSmall", "RIGHT")
	f.pos:SetPoint("BOTTOMRIGHT", -20, 46)
	f.count = S.Text(f, "GameFontNormal", "LEFT")
	f.count:SetPoint("BOTTOMLEFT", 20, 48)
	f.ok = Hud.ClaimButton(f, 170, 28, L["Confirm"])
	f.ok:SetPoint("BOTTOMRIGHT", -20, 12)
	CuratorOctoFull.SetScript(f.ok, "OnClick", function()
		CU:PickDone()
	end)
	f.least = S.Button(f, L["The least precious"], 170, 22)
	f.least:SetPoint("BOTTOMLEFT", 20, 15)
	CuratorOctoFull.SetScript(f.least, "OnClick", function()
		CU:PickLeast()
	end)
	f:Hide()
	return f
end

-- The chooser opens: opts = { card, finish, n (how many leave), ids (those chosen already), title, sub, done (with
-- the numbers chosen), owner (beside it) }.
function CU:OpenPicker(opts)
	if not (opts and opts.card) then
		return
	end
	self.picker = self.picker or BuildPicker()
	local f = self.picker
	local items = self:Choices(opts.card, opts.finish, true)
	local n = math.max(1, math.floor(tonumber(opts.n) or 1))
	local chosen, count = {}, 0
	for _, id in ipairs(type(opts.ids) == "table" and opts.ids or {}) do
		if count < n then
			chosen[id] = true
			count = count + 1
		end
	end
	self.pick = { card = opts.card, finish = opts.finish, n = n, items = items, chosen = chosen, top = 0, done = opts.done }
	if count < n then
		self:PickLeast(true)
	end
	f.title:SetText(opts.title or string.format((n == 1 and L["Which copy of %s?"] or L["Which copies of %s?"]), C:Name(opts.card)))
	f.sub:SetText(opts.sub or (n == 1 and L["The one that leaves your album. The least precious is chosen for you: choose another if you like."]
		or L["Those that leave your album. The least precious are chosen for you: choose others if you like."]))
	f:ClearAllPoints()
	if opts.owner then
		f:SetPoint("LEFT", opts.owner, "RIGHT", 12, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
	f:Show()
	f:Raise()
	self:PaintPicker()
end

function CU:ClosePicker()
	if self.picker then
		self.picker:Hide()
	end
	self.pick = nil
end

-- (the least precious chosen: those of before forgotten; keep: those chosen stay, the others filled)
function CU:PickLeast(keep)
	local p = self.pick
	if not p then
		return
	end
	if not keep then
		p.chosen = {}
	end
	local count = 0
	for _ in pairs(p.chosen) do
		count = count + 1
	end
	for _, it in ipairs(p.items) do
		if count >= p.n then
			break
		end
		if not it.stuck and not p.chosen[it.rec.i] then
			p.chosen[it.rec.i] = true
			count = count + 1
		end
	end
	if not keep then
		ns.Play(ns.SND.click)
		self:PaintPicker()
	end
end

function CU:PickScroll(delta)
	local p = self.pick
	if not p then
		return
	end
	p.top = math.max(0, math.min(CuratorOctoFull.Length(p.items) - ROWS, p.top + delta))
	self:PaintPicker()
end

function CU:PickRow(r)
	local p = self.pick
	local it = RECS[r]
	if not (p and it) then
		return
	end
	if it.stuck then
		ns.Play(ns.SND.close)
		return
	end
	local id = it.rec.i
	if p.chosen[id] then
		p.chosen[id] = nil
	else
		local count = 0
		for _ in pairs(p.chosen) do
			count = count + 1
		end
		if count >= p.n then
			-- (one alone: the other one goes out for it; several: one at a time)
			if p.n == 1 then
				p.chosen = {}
			else
				ns.Play(ns.SND.close)
				return
			end
		end
		p.chosen[id] = true
	end
	ns.Play(ns.SND.click)
	self:PaintPicker()
end

function CU:PaintPicker()
	local f, p = self.picker, self.pick
	if not (f and p) then
		return
	end
	-- (a copy gone meanwhile: out of the chooser)
	local items = self:Choices(p.card, p.finish, true)
	local free = {}
	for _, it in ipairs(items) do
		if not it.stuck then
			free[it.rec.i] = true
		end
	end
	for id in pairs(p.chosen) do
		if not free[id] then
			p.chosen[id] = nil
		end
	end
	p.items = items
	p.top = math.max(0, math.min(math.max(0, CuratorOctoFull.Length(items) - ROWS), p.top))
	local count = 0
	for _ in pairs(p.chosen) do
		count = count + 1
	end
	for i, r in ipairs(f.rows) do
		local it = items[p.top + i]
		RECS[r] = it
		if it then
			local rec = it.rec
			CuratorOctoFull.SetShown(r.tick, p.chosen[rec.i] == true)
			CU.PaintChip(r.chip, self:Label(p.card, rec), rec.f, false, it.stuck ~= nil)
			local line = self:Short(p.card, rec)
			-- (1.14.0: a titanforged copy, its pattern first: the one to keep, the one to give)
			-- (1 November: its family and its number once certified, Mages.lua)
			local tag = ns.Mages and ns.Mages.Tag(rec, false, true)
			if tag then
				line = tag .. "  ·  " .. line
			end
			if it.stuck then
				line = line .. "  ·  " .. L[WHY[it.stuck] or "It cannot leave now."]
			end
			r.line:SetText(line)
			r.line:SetTextColor(it.stuck and 0.5 or 0.86, it.stuck and 0.5 or 0.86, it.stuck and 0.52 or 0.88)
			r:SetSelected(p.chosen[rec.i] == true)
			r:Show()
		else
			r:Hide()
		end
	end
	f.pos:SetText(CuratorOctoFull.Length(items) > ROWS and string.format(("%d-%d / %d"), p.top + 1, math.min(CuratorOctoFull.Length(items), p.top + ROWS), CuratorOctoFull.Length(items)) or "")
	f.count:SetText(string.format(L["Chosen: %d / %d"], count, p.n))
	f.count:SetTextColor(count == p.n and 0.4 or 1, count == p.n and 1 or 0.82, count == p.n and 0.4 or 0.3)
	CuratorOctoFull.SetEnabled(f.ok, count == p.n)
end

function CU:PickDone()
	local p = self.pick
	if not p then
		return
	end
	local ids = {}
	for _, it in ipairs(p.items) do
		if p.chosen[it.rec.i] then
			ids[CuratorOctoFull.Length(ids) + 1] = it.rec.i
		end
	end
	if CuratorOctoFull.Length(ids) ~= p.n then
		ns.Play(ns.SND.close)
		return
	end
	local done = p.done
	self:ClosePicker()
	ns.Play(ns.SND.click)
	if done then
		done(ids)
	end
end

-- "#2 (8,45), #5": the copies chosen of a card, as a line says them.
function CU:Names(card, ids)
	local parts = {}
	for _, id in ipairs(ids or {}) do
		local rec = CP:Get(card.key, id)
		if rec then
			parts[CuratorOctoFull.Length(parts) + 1] = self:Label(card, rec)
		end
	end
	return table.concat(parts, ", ")
end
