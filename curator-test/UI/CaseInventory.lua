local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Ease = ns.Ease
local A = ns.Album

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) The cases in the inventory (UI/Inventory.lua):
-- * the cards of the cases among the copies (every copy, the appraised ones, the forged ones; never with a rarity of the
--   albums nor one card of an album chosen; 1.14.0, a player's word: sold to the reseller too, Reseller.lua): each its
--   own small card (UI/CaseCards.lua),
--   its condition (appraised: its grade) on its plate, its finish; under the mouse it rises, its story in its tooltip; a
--   click shows it alone, held in the hand (UI/CaseView.lua: at a banker, its expertise);
-- * Cases, Keys: each case, each key on its own in the grid, as in a true inventory (below).
-------------------------------------------------------------------------------
local IU = ns.InventoryUI
local CR = ns.CrateUI
local CM = ns.CaseCards
local GOLD = S.GOLD
local ARM = 3
-- (the rarity of the albums a card of a case sorts with, by its rank: a rare card of a case with the rare cards of the
-- albums, a priceless one above the mythic ones)
local SORT_RARITY = { 3, 4, 5, 6, 7 }
-- the ink of its plate: its finish; appraised
local INK = { thunder = { 0.55, 0.78, 1 }, titan = { 1, 0.8, 0.42 } }
local INK_GRADED = { 1, 0.93, 0.72 }
local FIN_GEM = { thunder = "Gem7", titan = "Gem8" }
local KEY_ICON = "Interface\\Icons\\INV_Misc_Key_04"

local function Armed(b)
	return b.armed ~= nil and GetTime() - b.armed < ARM
end

-- Whether a card of a case goes in this filter of the copies.
local function Wants(filter, w)
	if filter == "all" then
		return true
	elseif filter == "graded" then
		return w.ap == true
	elseif filter == "forged" then
		return w.f == "thunder" or w.f == "titan"
	elseif filter == "certified" then
		-- (1 November: titanforged, certified by a master of the mages, Mages.lua)
		return w.f == "titan" and ns.Mages ~= nil and ns.Mages.Of(w) ~= nil
	end
	return false
end

-- The editions in their order (the case of now first), and the place of each.
local function Editions()
	local CS = ns.Cases
	local list = CS and CS:Editions() or {}
	local at = {}
	for i, k in ipairs(list) do
		at[k] = i
	end
	return list, at
end

-------------------------------------------------------------------------------
-- The cards of the cases among the copies
-------------------------------------------------------------------------------
-- (IU:Survey) The cards of the cases of the filter added to the lines, and to the counts of the filters. (1.14.0, a
-- player's word) Each one a duplicate or not (the finest copy of each card stays: CS.Score, the oldest), the last copy
-- of its card or not; dupes: the duplicates only. In the sell mode, whether the reseller takes it (x.takes): how many
-- he takes.
function IU:AddCases(lines, chips, filter, rarity, only, sell, dupes)
	local CS = ns.Cases
	local CD = ns.CaseDetail
	local RV = ns.Reseller
	chips.__cases = true
	if not CS or only or rarity then
		return 0
	end
	local _, at = Editions()
	local won = CS:Won()
	local keeper, count = {}, {}
	if CD then
		for _, w in ipairs(won) do
			local key = CD.DescOf(w).key
			count[key] = (count[key] or 0) + 1
			local b = keeper[key]
			local sw, sb = CS.Score(w), b and CS.Score(b)
			if not b or sw > sb or (sw == sb and (w.i or 0) < (b.i or 0)) then
				keeper[key] = w
			end
		end
	end
	local open = sell and RV and RV:Open()
	local taken = 0
	for _, w in ipairs(won) do
		local key = CD and CD.DescOf(w).key
		local dupe = key ~= nil and keeper[key] ~= nil and keeper[key].i ~= w.i
		if not dupes or dupe then
			for _, k in ipairs({ "all", "graded", "forged", "certified" }) do
				if Wants(k, w) then
					chips[k] = (chips[k] or 0) + 1
				end
			end
			local takes = open and not RV:CaseHeld(w) and RV:CaseOffer(w) > 0 or false
			if takes then
				taken = taken + 1
			end
			if Wants(filter, w) then
				local _, r = CM.Entry(w.c, w.e)
				lines[CuratorOctoFull.Length(lines) + 1] = {
					case = w, rarity = SORT_RARITY[tonumber(w.r) or 1] or 3, grade = w.ap and (tonumber(w.g) or 0) * 100 or nil,
					order = 1000 + (at[w.c] or 99), num = (tonumber(w.r) or 1) * 100 + (r and 0 or 50), t = w.t, i = w.i,
					dupe = dupe, unique = key ~= nil and (count[key] or 0) <= 1, takes = sell and takes or nil,
				}
			end
		end
	end
	return taken
end

-- (IU:Counts) The cases to open, their keys; the cards of the cases among the copies of the bar over the boosters.
function IU:CaseCounts(chips)
	local CS = ns.Cases
	chips.cases = CS and CS:Total() or 0
	local keys = 0
	for _, k in ipairs(CS and CS:Editions() or {}) do
		keys = keys + CS:Keys(k)
	end
	chips.keys = keys
	if CS and not chips.__cases then
		for _, w in ipairs(CS:Won()) do
			for _, key in ipairs({ "all", "graded", "forged", "certified" }) do
				if Wants(key, w) then
					chips[key] = (chips[key] or 0) + 1
				end
			end
		end
	end
end

-- The cards of the cases: how many, how many appraised.
function IU:CaseTotals()
	local CS = ns.Cases
	local n, g = 0, 0
	for _, w in ipairs(CS and CS:Won() or {}) do
		n = n + 1
		if w.ap then
			g = g + 1
		end
	end
	return n, g
end

-- (the grid of the copies, UI/Inventory.lua: the same cards at the same size, in their case smaller, the case in the room
-- of a card; the copy under the mouse larger, leaning toward it)
local SW, SH = ns.CARD_SIZES.small[1], ns.CARD_SIZES.small[2]
local K = 0.85
local CARD_H = SH * K
local BOX = ns.SlabRects(SW, SH)
local KC = math.min(SW * K / (BOX[3] - BOX[1]), CARD_H / (BOX[4] - BOX[2]))
local CASE_DY = (BOX[2] + BOX[4]) / 2
local LIFT = 1.14
local LEAN_YAW, LEAN_PITCH = 0.5, 0.36

-- The number of a copy among those of its card, as they are shown (UI/CaseDetail.lua: CD:Copies), kept until the cards
-- change.
local index
function IU:CaseIndex(w)
	local CD = ns.CaseDetail
	if not CD then
		return nil
	end
	index = index or {}
	local desc = CD.DescOf(w)
	local list = index[desc.key]
	if not list then
		list = {}
		for i, x in ipairs(CD:Copies(desc)) do
			if x.i ~= nil then
				list[x.i] = i
			end
		end
		index[desc.key] = list
	end
	return w.i ~= nil and list[w.i] or nil
end
ns.On("CASES_CHANGED", function()
	index = nil
end)

-- Its card of a case where the card of a copy is: at K of its size, in its case smaller (its case in the room of a card).
local function Seat(cell, c, cased)
	local k = cased and KC or K
	c:SetScale(k)
	c:ClearAllPoints()
	c:SetPoint("CENTER", cell, "TOP", 0, (-CARD_H / 2 - (cased and CASE_DY * KC or 0)) / k)
	cell.crateK = k
end

-- Its card in the cell, as the cards of the boosters are (UI/CrateCard.lua: alive, in its case when it was appraised); its
-- plate under it: its number among its copies, its condition (appraised: its grade), the gem of its finish.
function IU:PaintCaseCell(cell, x)
	local w = x.case
	local CD = ns.CaseDetail
	cell.card:Hide()
	cell.card.sig = nil
	cell.band:Hide()
	cell.hasBand = false
	cell.tick:Hide()
	local cw = cell:GetWidth()
	local c = cell.crate
	if not c then
		c = ns.CrateCard.New(cell, SW)
		c:SetFrameLevel(cell.card:GetFrameLevel())
		cell.crate = c
	end
	local desc = CD.DescOf(w)
	-- (31 October: its wear in its signature, never its condition in words)
	local sig = tostring(w.i) .. ":" .. tostring(w.f) .. ":" .. tostring(w.ap and w.g) .. ":" .. ns.Cases.WearKey(w)
	if cell.crateSig ~= sig then
		cell.crateSig = sig
		c:Set(CD.PickOf(desc, w), CR.RANKS)
		local def = ns.Crates and ns.Crates[w.c]
		c:SetBack(def and def.art and def.art.back or nil)
		c:SetLive(true)
		c:SlabAlpha(1)
		c:SetSlab(w.ap and CD.Label(desc, w) or nil)
	end
	cell.caseId = w.i
	Seat(cell, c, w.ap)
	c:Show()
	local sell = self.sell ~= nil
	local takes = sell and x.takes or false
	-- (the copy risen under the mouse stays risen: the lens over it; at the reseller, one he leaves dimmed)
	-- (1 November: a card at an enchanter, dimmed: away)
	local away = type(w.aw) == "table"
	cell.alpha, cell.takes, cell.why = ((sell and not takes) or away) and 0.34 or 1, takes or nil, (sell and not takes) and (away and "away2" or "market") or nil
	c:SetAlpha((IU.caseLensCell == cell) and 0 or cell.alpha)
	local plate = cell.plate
	local E = ns.Expertise
	-- (1.14.3: a card of another player's inventory: its number among theirs, as it came, Comm.lua)
	local n = x.n or (not x.theirs and self:CaseIndex(w)) or nil
	local head = "#" .. tostring(n or "?")
	-- (31 October, his word: its condition shows on it, its wear, never told in words; appraised, its grade)
	local text = w.ap and (head .. " · " .. E.Text(tonumber(w.g) or 1)) or head
	local ink = (w.ap and INK_GRADED) or INK[w.f or ""] or { 0.86, 0.86, 0.9 }
	-- (1.14.0, a player's word: at the reseller, the last copy of a card said; its price on the right)
	if takes and x.unique then
		text, ink = L["Last one"], IU.LAST
	end
	plate.why:Hide()
	plate.label:Show()
	plate.label:SetText(text)
	plate.label:SetTextColor(ink[1], ink[2], ink[3])
	local tag = plate.tag
	if tag then
		CuratorOctoFull.SetShown(tag, takes and true or false)
		if takes then
			tag:SetAmount(ns.Reseller:PaysNow(ns.Reseller:CaseOffer(w)), true)
		end
	end
	local gem = FIN_GEM[w.f or ""]
	CuratorOctoFull.SetShown(plate.gem, gem ~= nil)
	if gem then
		plate.gem:SetTexture(MEDIA .. gem)
	end
	local lead = gem and 13 or 0
	plate.gem:ClearAllPoints()
	plate.label:ClearAllPoints()
	if takes then
		S.Fit(plate.label, plate.label:GetText(), cw - 12 - lead - (tag and tag:GetWidth() or 0), 10, 7.5)
		plate.gem:SetPoint("LEFT", plate, "LEFT", 4, 0)
		plate.label:SetPoint("LEFT", plate, "LEFT", 5 + lead, 0)
	else
		S.Fit(plate.label, plate.label:GetText(), cw - 8 - lead, 10, 7.5)
		local tw = math.min(cw - 8, ns.TextWidth(plate.label)) + lead
		plate.gem:SetPoint("LEFT", plate, "CENTER", -tw / 2, 0)
		plate.label:SetPoint("LEFT", plate, "CENTER", -tw / 2 + lead, 0)
	end
	local col = (CR.RANKS[desc.tier] or CR.RANKS[1]).color
	cell.edgeCol = { col[1] * 0.6, col[2] * 0.6, col[3] * 0.6, 0.9 }
	CuratorOctoFull.ColorTexture(plate.edge, col[1] * 0.6, col[2] * 0.6, col[3] * 0.6, 0.9)
	plate:SetAlpha((sell and not takes) and 0.75 or 1)
	self:PaintTick(cell)
end

-- The lens of the cards of the cases: one card for all of them, over the one under the mouse (larger, leaning toward it
-- in 3D, its case in 3D with it), as the lens of the copies of the boosters (UI/Inventory.lua).
local function Lens(page)
	local lens = page.caseLens
	if lens then
		return lens
	end
	local hold = page.lensHold or page
	lens = ns.CrateCard.New(hold, SW)
	lens:SetFrameLevel(hold:GetFrameLevel() + 2)
	lens:Hide()
	lens.yaw, lens.pitch, lens.lift = 0, 0, 1
	page.caseLens = lens
	CuratorOctoFull.HookScript(page, "OnUpdate", function(_, elapsed)
		if lens:IsShown() and lens.cell then
			IU:CaseLean(lens, elapsed)
		end
	end)
	CuratorOctoFull.HookScript(page, "OnHide", function()
		if IU.caseLensCell then
			IU:LeaveCase(IU.caseLensCell)
		end
	end)
	return lens
end

local function PlaceLens(lens)
	local cell = lens.cell
	if not cell then
		return
	end
	local u = lens.lift or 1
	local k = (cell.crateK or K) * u
	lens:SetScale(k)
	lens:ClearAllPoints()
	lens:SetPoint("CENTER", cell.crate, "CENTER", 0, 4 * (u - 1) / (LIFT - 1) * (cell.crateK or K) / k)
end

function IU:EnterCase(cell, x)
	local c = cell.crate
	local page = A.frame and A.frame.inv
	if not (c and page) then
		return
	end
	if self.lensCell and self.lensCell ~= cell then
		self:Leave(self.lensCell)
	end
	if self.caseLensCell and self.caseLensCell ~= cell then
		self:LeaveCase(self.caseLensCell)
	end
	local CD = ns.CaseDetail
	local w = x.case
	local desc = CD.DescOf(w)
	local lens = Lens(page)
	self.caseLensCell, self.caseHover = cell, cell
	lens.cell = cell
	local sig = cell.crateSig
	if lens.sig ~= sig then
		lens.sig = sig
		lens:Set(CD.PickOf(desc, w), CR.RANKS)
		local def = ns.Crates and ns.Crates[w.c]
		lens:SetBack(def and def.art and def.art.back or nil)
		lens:SetLive(true)
		lens:SlabAlpha(1)
		lens:SetSlab(w.ap and CD.Label(desc, w) or nil)
	end
	lens.yaw, lens.pitch, lens.lift = 0, 0, 1
	PlaceLens(lens)
	lens:Show()
	c:SetAlpha(0)
	if lens.liftTw then
		ns.CancelTween(lens.liftTw)
	end
	lens.liftTw = ns.Tween(0.14, function(e)
		lens.lift = 1 + (LIFT - 1) * e
		PlaceLens(lens)
	end, nil, Ease.outQuad, A)
	self:CaseTooltip(cell, x)
end

function IU:LeaveCase(cell)
	if self.caseHover == cell then
		self.caseHover = nil
	end
	if self.caseLensCell ~= cell then
		return
	end
	self.caseLensCell = nil
	local page = A.frame and A.frame.inv
	local lens = page and page.caseLens
	if lens then
		if lens.liftTw then
			ns.CancelTween(lens.liftTw)
			lens.liftTw = nil
		end
		lens.cell = nil
		lens:SetPose(0, 0)
		lens:Hide()
	end
	if cell.crate then
		cell.crate:SetAlpha(cell.alpha or 1)
	end
end

-- Every frame: the card risen leans toward the mouse, eased (in 3D: UI/CrateCard.lua, card:SetPose).
function IU:CaseLean(lens, elapsed)
	local cell = lens.cell
	local c = cell and cell.crate
	if not c then
		return
	end
	local x, y = GetCursorPosition()
	local cx, cy = c:GetCenter()
	local sc = c:GetEffectiveScale()
	local dx, dy = 0, 0
	if x and cx and sc and sc > 0 then
		local hw, hh = math.max(1, (c:GetWidth() or 1) / 2), math.max(1, (c:GetHeight() or 1) / 2)
		dx, dy = (x / sc - cx) / hw, (y / sc - cy) / hh
	end
	dx, dy = math.max(-1, math.min(1, dx)), math.max(-1, math.min(1, dy))
	local a = math.min(1, (elapsed or 0) * 12)
	lens.yaw = lens.yaw + (LEAN_YAW * dx - lens.yaw) * a
	lens.pitch = lens.pitch + (-LEAN_PITCH * dy - lens.pitch) * a
	lens:SetPose(lens.yaw, lens.pitch)
end

-- Its story under the mouse: its name, its rank and its collection, its condition (appraised: its grade, its marks),
-- its finish, where it came from, when.
function IU:CaseTooltip(cell, x)
	local w = x.case
	local CS, E = ns.Cases, ns.Expertise
	local tier = (w.w and CR.TOP) or tonumber(w.r) or 1
	local r = CR.RANKS[tier] or CR.RANKS[1]
	local tc = r.text or r.color
	GameTooltip:SetOwner(cell, (cell.col or 0) >= 4 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	GameTooltip:AddLine(CM.Name(w), tc[1], tc[2], tc[3])
	local coll = (CS.COLLECTION and CS.COLLECTION[w.c]) or "Paladin Collection 2026"
	GameTooltip:AddLine(L[coll] .. "  ·  " .. L[r.label], 0.7, 0.7, 0.72)
	if w.ap then
		GameTooltip:AddLine(string.format(L["Appraised: %s"], E.Label(w.g)), 1, 1, 1)
		local m = E.DecodeMarks(w.m)
		if m then
			GameTooltip:AddLine(E.MarksText(m), 0.75, 0.75, 0.78)
		end
	else
		-- (31 October, his word: never its condition in words, its wear shows on it)
		GameTooltip:AddLine(L["Not appraised"], 0.75, 0.75, 0.78)
	end
	-- (1 November: at an enchanter, until when; restored, how many times)
	local RS = ns.Restore
	if RS and type(w.aw) == "table" then
		GameTooltip:AddLine(RS:AwayText(w) or "", 0.82, 0.78, 1, true)
	elseif type(w.rr) == "table" and CuratorOctoFull.Length(w.rr) > 0 then
		GameTooltip:AddLine(CuratorOctoFull.Length(w.rr) == 1 and L["Restored once"] or string.format(L["Restored %d times"], CuratorOctoFull.Length(w.rr)), 0.82, 0.78, 1)
	end
	if w.f and CR.FINISH_NAME[w.f] then
		local ink = INK[w.f]
		GameTooltip:AddLine(L[CR.FINISH_NAME[w.f]] .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or ""), ink[1], ink[2], ink[3])
		-- (1 November: its certificate of the mages, Mages.lua)
		local ml, certified = ns.Mages and ns.Mages.Line(w, true)
		if ml then
			GameTooltip:AddLine(ml, certified and 0.86 or 0.6, certified and 0.92 or 0.62, certified and 1 or 0.7)
		end
	end
	GameTooltip:AddLine(CS.How(w), 0.62, 0.62, 0.66)
	if w.t then
		GameTooltip:AddLine(date("%d/%m/%Y %H:%M", w.t), 0.5, 0.5, 0.55)
	end
	-- (1.14.0, a player's word: at the reseller, what it brings, its last copy said)
	if self.sell then
		GameTooltip:AddLine(" ")
		if x.takes then
			GameTooltip:AddLine(string.format(L["He pays %s a copy."], ns.Rubies.Text(ns.Reseller:PaysNow(ns.Reseller:CaseOffer(w)), 13)), 1, 0.82, 0.25)
			if x.unique then
				GameTooltip:AddLine(L["Its last copy: sold, the card leaves your album."], IU.LAST[1], IU.LAST[2], IU.LAST[3], true)
			end
			GameTooltip:AddLine(self:LineTicked(x) and L["Click: untick it"] or L["Click: tick it"], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Bought at the Exchange not long ago: it waits for the end of its quarantine."], 1, 0.45, 0.4, true)
		end
		GameTooltip:AddLine(L["Right click: show this copy"], 0.62, 0.62, 0.66)
	elseif not x.theirs then
		GameTooltip:AddLine(L["Click: show this copy"], 0.4, 1, 0.4)
	end
	GameTooltip:Show()
end

function IU:ClickCase(cell, x)
	-- (shift-click: the copy in the chat, UI/CaseShow.lua)
	local K = ns.Links
	if K and K.InsertCase and K:Modified() then
		return K:InsertCase(x.case)
	end
	-- (1.14.3: a card of another player's inventory: shown on their page only)
	if x.theirs then
		return
	end
	ns.Play(ns.SND.cardFlip)
	self:LeaveCase(cell)
	GameTooltip:Hide()
	-- (1.14.0, after its second test: shown big as the cards of the boosters are, over the inventory: UI/CaseDetail.lua)
	A:ShowCaseDetail(ns.CaseDetail.DescOf(x.case), x.case.i)
end

-------------------------------------------------------------------------------
-- (1.14.0, a player's word) The cases, the keys: one by one in the grid of the inventory, as in a true inventory (six
-- cases: six cases side by side; the keys the same), each in its slot (Media/InvSlot), its edition under it: a case in 3D
-- in the art of its edition (UI/CrateBox.lua), a key its icon and the medallion of its edition. Under the mouse a case
-- turns and shines, a key rises; a click shows its case (UI/Crate.lua: open it, buy a key there), a right click on a
-- case its collection (UI/CaseAlbum.lua). Over them: where they come from, a key to buy (a first click arms it, a
-- second pays).
-------------------------------------------------------------------------------
local SLOT_W = SW * K
local SLOT_TEX, SLOT_U = MEDIA .. "InvSlot", 183 / 256
-- (the frame of a case in 3D, the case itself 0.62 of it; its middle a little over the middle of its slot)
local BOX_W, BOX_DY = 132, 6
local KEY_SIZE, KEY_LIFT = 58, 1.14
-- (the medallion of an edition: the middle of the lid of its case, Media/<art>Top)
local MEDAL_UV = { 0.369, 0.631, 0.125, 0.387 }
local INK_CASE, INK_KEY = { 1, 0.84, 0.42 }, { 0.93, 0.88, 0.74 }

-- The items of the page: each case of each edition (kind "cases"), or each key ("keys"), the edition of now first. (At
-- the reseller: whether he takes each, x.takes; a case bought at the Bourse waits its quarantine, the last ones.)
function IU:ItemLines(kind)
	local CS = ns.Cases
	local RV = ns.Reseller
	local out = {}
	if not CS then
		return out
	end
	local key = kind == "keys"
	local open = self.sell ~= nil and RV ~= nil and RV:Open()
	for _, ed in ipairs(CS:Editions()) do
		local n = key and CS:Keys(ed) or CS:Count(ed)
		local free = open and (key and RV:FreeKeys(ed) or RV:FreeCases(ed)) or 0
		for i = 1, n do
			out[CuratorOctoFull.Length(out) + 1] = { item = key and "key" or "case", ed = ed, n = i, of = n, takes = open and i <= free or nil }
		end
	end
	return out
end

-- (IU:Survey, the sell mode) The cases and the keys the reseller takes: how many.
function IU:ItemsTaken()
	local CS, RV = ns.Cases, ns.Reseller
	if not (CS and RV and RV:Open()) then
		return 0
	end
	local n = 0
	for _, ed in ipairs(CS:Editions()) do
		n = n + RV:FreeCases(ed) + RV:FreeKeys(ed)
	end
	return n
end

-- (1 November, his word: « dans "tout" ... y'a aussi les caisses et les clés ... vraiment je veux tout ») What waits to
-- be opened, at the head of Everything (IU:Survey): the golden boosters (1.14.2), the boosters of each album (the one of
-- the place first, then the most, as on their page), the displays of each album, the cases of each edition, their keys;
-- each in one slot, how many on it (x.stack). series: of that album only (its golden boosters, its boosters, its
-- displays). At the reseller (sell): the cases and the keys one by one, as on their pages, to tick each; no booster nor
-- display (he buys none back).
function IU:AllItems(series, sell)
	local out = {}
	local CS = ns.Cases
	if sell then
		if CS and not series then
			for _, kind in ipairs({ "cases", "keys" }) do
				for _, x in ipairs(self:ItemLines(kind)) do
					out[CuratorOctoFull.Length(out) + 1] = x
				end
			end
		end
		return out
	end
	-- (1.14.2, his word: « Les boosters "Booster en or" il faut qu'ils soit aussi dans l'inventaire »: the golden boosters
	-- first, one slot for those of each album, in the order they came; a click opens one, Golden.lua)
	local GQ = ns.Golden
	for _, g in ipairs(GQ and GQ.PacksByAlbum and GQ:PacksByAlbum(series) or {}) do
		out[CuratorOctoFull.Length(out) + 1] = { item = "golden", s = g.s, n = 1, of = g.n, stack = true }
	end
	local packs = {}
	if series then
		packs[1] = ns.Packs(series) > 0 and series or nil
	elseif A.FeaturedSeries and A.OtherBoosters then
		local featured = A:FeaturedSeries()
		if featured and ns.Packs(featured) > 0 then
			packs[1] = featured
		end
		for _, s in ipairs(A:OtherBoosters(featured)) do
			packs[CuratorOctoFull.Length(packs) + 1] = s
		end
	end
	for _, s in ipairs(packs) do
		out[CuratorOctoFull.Length(out) + 1] = { item = "pack", s = s, n = 1, of = ns.Packs(s), stack = true }
	end
	local D = ns.Displays
	for _, d in ipairs(D and D.All and D:All() or {}) do
		if not series or d.series == series then
			out[CuratorOctoFull.Length(out) + 1] = { item = "display", s = d.series, n = 1, of = d.displays + d.casedDisplays, open = d.displays,
				cased = d.casedDisplays, stack = true }
		end
	end
	if CS and not series then
		for _, ed in ipairs(CS:Editions()) do
			local n = CS:Count(ed)
			if n > 0 then
				out[CuratorOctoFull.Length(out) + 1] = { item = "case", ed = ed, n = 1, of = n, stack = true }
			end
		end
		for _, ed in ipairs(CS:Editions()) do
			local n = CS:Keys(ed)
			if n > 0 then
				out[CuratorOctoFull.Length(out) + 1] = { item = "key", ed = ed, n = 1, of = n, stack = true }
			end
		end
	end
	return out
end

-- How many things the items hold (a slot of five boosters: five).
function IU:ItemCount(items)
	local n = 0
	for _, x in ipairs(items or {}) do
		n = n + (x.stack and (x.of or 0) or 1)
	end
	return n
end

-- The name of an edition, short (under an item), whole (in its tooltip).
local function EdName(ed, short)
	local def = ns.Crates and ns.Crates[ed]
	if short and def and def.short then
		return L[def.short]
	end
	return L[(def and def.title) or "Test case"]
end

local function Round(s, tex)
	local m = CuratorOctoFull.CreateMaskTexture(s)
	m:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(tex)
	CuratorOctoFull.AddMaskTexture(tex, m)
end

-- Its slot (made the first time), where its card is.
local function Slot(cell)
	local s = cell.slot
	if s then
		return s
	end
	s = CreateFrame("Frame", nil, cell)
	cell.slot = s
	s:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
	CuratorOctoFull.SetSize(s, SLOT_W, CARD_H)
	s:SetFrameLevel(cell.card:GetFrameLevel())
	s.bg = s:CreateTexture(nil, "BACKGROUND")
	s.bg:SetAllPoints()
	s.bg:SetTexture(SLOT_TEX)
	s.bg:SetTexCoord(0, SLOT_U, 0, 1)
	-- (lit under the mouse)
	s.lit = s:CreateTexture(nil, "BORDER")
	s.lit:SetTexture(MEDIA .. "Glow")
	s.lit:SetBlendMode("ADD")
	s.lit:SetPoint("CENTER", s, "CENTER", 0, BOX_DY)
	CuratorOctoFull.SetSize(s.lit, SLOT_W * 1.25, SLOT_W * 1.25)
	s.lit:SetVertexColor(1, 0.78, 0.38)
	s.lit:SetAlpha(0)
	-- a key: its icon round in its ring, the medallion of its edition at its foot
	s.key = s:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(s.key, KEY_SIZE, KEY_SIZE)
	s.key:SetPoint("CENTER", s, "CENTER", 0, BOX_DY)
	s.key:SetTexture(KEY_ICON)
	s.key:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	Round(s, s.key)
	s.ring = s:CreateTexture(nil, "ARTWORK", nil, 1)
	s.ring:SetTexture(MEDIA .. "IconRing")
	s.ring:SetVertexColor(1, 0.84, 0.4)
	s.ring:SetPoint("TOPLEFT", s.key, "TOPLEFT", -KEY_SIZE * 0.12, KEY_SIZE * 0.12)
	s.ring:SetPoint("BOTTOMRIGHT", s.key, "BOTTOMRIGHT", KEY_SIZE * 0.12, -KEY_SIZE * 0.12)
	s.medal = s:CreateTexture(nil, "ARTWORK", nil, 3)
	CuratorOctoFull.SetSize(s.medal, 26, 26)
	s.medal:SetPoint("CENTER", s.key, "BOTTOMRIGHT", -3, 3)
	Round(s, s.medal)
	s.medalRing = s:CreateTexture(nil, "ARTWORK", nil, 4)
	s.medalRing:SetTexture(MEDIA .. "IconRing")
	s.medalRing:SetVertexColor(1, 0.84, 0.4)
	s.medalRing:SetPoint("CENTER", s.medal, "CENTER")
	CuratorOctoFull.SetSize(s.medalRing, 32, 32)
	-- (1 November: in Everything, a slot holds every one of its kind: how many, over whatever stands in it)
	s.top = CreateFrame("Frame", nil, s)
	s.top:SetAllPoints()
	s.top:SetFrameLevel(s:GetFrameLevel() + 24)
	s.count = ns.Hud.Text(s.top, 15, "OUTLINE", "OVERLAY", 7)
	s.count:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -7, 9)
	s.count:SetTextColor(1, 0.86, 0.45)
	return s
end

-- (1 November) A booster of an album in a slot of Everything, standing (UI/Hud.lua), made the first time.
local PACK_W, DISP_W = 44, 100
local function SlotPack(s)
	local p = s.pack
	if not p then
		p = ns.Hud.Pack(s, PACK_W)
		p:SetPoint("CENTER", s, "CENTER", 0, BOX_DY + 2)
		p:SetFrameLevel(s:GetFrameLevel() + 2)
		p.glow:SetAlpha(0.2)
		s.pack = p
	end
	return p
end

-- (1.14.2) Behind a golden booster in a slot of Everything: rays of gold turning slowly, as behind a card shown big in
-- the album (UI/Album.lua), so that it is told from a booster at a glance; made the first time.
local function SlotAura(s)
	local a = s.aura
	if not a then
		a = CreateFrame("Frame", nil, s)
		a:SetAllPoints()
		a:SetFrameLevel(s:GetFrameLevel() + 1)
		a.rays = a:CreateTexture(nil, "BORDER")
		a.rays:SetTexture(MEDIA .. "Rays")
		a.rays:SetBlendMode("ADD")
		a.rays:SetVertexColor(1, 0.78, 0.36)
		CuratorOctoFull.SetSize(a.rays, SLOT_W * 0.98, SLOT_W * 0.98)
		a.rays:SetPoint("CENTER", s, "CENTER", 0, BOX_DY + 2)
		a.rays:SetAlpha(0.7)
		a.t = 0
		CuratorOctoFull.SetScript(a, "OnUpdate", function(self, elapsed)
			self.t = self.t + elapsed
			CuratorOctoFull.SetRotation(self.rays, self.t * 0.22)
		end)
		s.aura = a
	end
	return a
end

-- A display of an album in a slot of Everything, its box in 3D (UI/Displays.lua), made the first time.
local function SlotDisplay(s)
	local b = s.disp
	if not b then
		b = ns.DisplaysUI.Box(s, DISP_W)
		b:SetPoint("CENTER", s, "CENTER", 0, BOX_DY)
		b:SetFrameLevel(s:GetFrameLevel() + 2)
		s.disp = b
	end
	return b
end

-- Its slot put away (a copy there now, or nothing).
function IU:HideSlot(cell)
	if self.itemHover == cell then
		self:LeaveItem(cell)
	end
	local s = cell.slot
	if s then
		if s.box then
			s.box:SetIdle(false)
		end
		s:Hide()
	end
	cell.itemSig = nil
end

-- A case or a key in its cell (x: { item = "case" or "key", ed: its edition, n: its place among them, of: how many }).
function IU:PaintItemCell(cell, x)
	cell.card:Hide()
	cell.card.sig = nil
	if cell.crate then
		cell.crate:Hide()
	end
	cell.crateSig = nil
	cell.band:Hide()
	cell.hasBand = false
	cell.tick:Hide()
	cell.ticked = false
	cell.alpha, cell.takes, cell.why = 1, nil, nil
	local s = Slot(cell)
	local sig = x.item .. ":" .. tostring(x.ed or (x.s and x.s.key)) .. ":" .. x.n .. ":" .. tostring(x.stack and x.of or "")
	local moved = cell.itemSig ~= sig
	if moved and self.itemHover == cell then
		self:LeaveItem(cell)
	end
	cell.itemSig = sig
	s:Show()
	-- (1 November: in Everything, how many of it the slot holds)
	s.count:SetText((x.stack and (x.of or 0) > 1) and ("x" .. x.of) or "")
	-- (1 November: a booster, a display of an album, in Everything: below; 1.14.2: a golden booster too)
	local album = x.item == "pack" or x.item == "display" or x.item == "golden"
	if s.pack then
		CuratorOctoFull.SetShown(s.pack, x.item == "pack" or x.item == "golden")
	end
	if s.disp then
		CuratorOctoFull.SetShown(s.disp, x.item == "display")
		if x.item ~= "display" then
			s.disp:SetIdle(false)
		end
	end
	if s.aura then
		CuratorOctoFull.SetShown(s.aura, x.item == "golden")
	end
	if album then
		return self:PaintAlbumItem(cell, s, x, moved)
	end
	local def = ns.Crates and ns.Crates[x.ed]
	local art = def and def.art and def.art.box
	local isCase = x.item == "case"
	CuratorOctoFull.SetShown(s.key, not isCase)
	CuratorOctoFull.SetShown(s.ring, not isCase)
	CuratorOctoFull.SetShown(s.medal, not isCase)
	CuratorOctoFull.SetShown(s.medalRing, not isCase)
	if isCase then
		local b = s.box
		if not b then
			b = ns.CrateBox.New(s, BOX_W)
			b:SetPoint("CENTER", s, "CENTER", 0, BOX_DY)
			b:SetFrameLevel(s:GetFrameLevel() + 2)
			s.box = b
		end
		b:SetArt(art)
		b:Show()
	else
		if s.box then
			s.box:SetIdle(false)
			s.box:Hide()
		end
		s.key:SetTexture((def and def.keyIcon) or KEY_ICON)
		s.medal:SetTexture(MEDIA .. ns.CaseTexture((art or "Crate") .. "Top"))
		s.medal:SetTexCoord(MEDAL_UV[1], MEDAL_UV[2], MEDAL_UV[3], MEDAL_UV[4])
	end
	-- its plate: its edition
	local plate = cell.plate
	plate.why:Hide()
	if plate.tag then
		plate.tag:Hide()
	end
	plate.gem:Hide()
	plate.label:Show()
	local ink = isCase and INK_CASE or INK_KEY
	local sell = self.sell ~= nil
	local takes = sell and x.takes or false
	cell.takes = takes or nil
	cell.edgeCol = nil
	plate.label:SetTextColor(ink[1], ink[2], ink[3])
	plate.label:ClearAllPoints()
	local tag = plate.tag
	if tag then
		CuratorOctoFull.SetShown(tag, takes and true or false)
		if takes then
			tag:SetAmount(ns.Reseller:PaysNow(isCase and ns.Reseller.CASE_ITEM or ns.Reseller.KEY_ITEM), true)
		end
	end
	if takes then
		S.Fit(plate.label, EdName(x.ed, true), SLOT_W - 12 - (tag and tag:GetWidth() or 0), 10, 7.5)
		plate.label:SetPoint("LEFT", plate, "LEFT", 5, 0)
	else
		S.Fit(plate.label, EdName(x.ed, true), SLOT_W - 8, 10, 7.5)
		plate.label:SetPoint("CENTER", plate, "CENTER", 0, 0)
	end
	CuratorOctoFull.ColorTexture(plate.edge, 0.62, 0.48, 0.2, 0.9)
	plate:SetAlpha((sell and not takes) and 0.75 or 1)
	s:SetAlpha((sell and not takes) and 0.4 or 1)
	self:PaintTick(cell)
	-- (another item under the mouse where the one before was: it is lit in its turn)
	if moved and cell:IsShown() and cell:IsMouseOver() then
		self:EnterItem(cell, x)
	end
end

-- (1.14.2) A golden booster: the pack of its album in gold, its light of gold (UI/Boosters.lua, A:GildPack), its plate
-- edged in gold; a booster of an album: as it is.
local GILT_EDGE = { 1, 0.8, 0.3, 1 }
local function Gild(p, on)
	A:GildPack(p, on)
	p.glow:SetAlpha(on and 0.45 or 0.2)
end

-- (1 November) A booster or a display of an album in its slot of Everything: standing in it, the name of its album on
-- its plate, how many over it (IU:PaintItemCell). (1.14.2: a golden booster, in gold.)
function IU:PaintAlbumItem(cell, s, x, moved)
	s.key:Hide()
	s.ring:Hide()
	s.medal:Hide()
	s.medalRing:Hide()
	if s.box then
		s.box:SetIdle(false)
		s.box:Hide()
	end
	local gilt = x.item == "golden"
	if x.item == "pack" or gilt then
		local p = SlotPack(s)
		if p.series ~= x.s then
			p:SetSeries(x.s)
		end
		Gild(p, gilt)
		p:Show()
		if gilt then
			SlotAura(s):Show()
		end
	else
		local b = SlotDisplay(s)
		if b.series ~= x.s then
			b:SetSeries(x.s)
		end
		-- (all of them in their case: its glass round it)
		b:SetCased((x.open or 0) == 0)
		b:SetCount(nil)
		b:Show()
	end
	local plate = cell.plate
	plate.why:Hide()
	if plate.tag then
		plate.tag:Hide()
	end
	plate.gem:Hide()
	plate.label:Show()
	-- (a golden booster: its plate edged in gold, IU:PaintTick)
	cell.takes, cell.edgeCol = nil, gilt and GILT_EDGE or nil
	local g = (x.s and x.s.glow) or { 1, 0.8, 0.4 }
	if gilt then
		plate.label:SetTextColor(1, 0.84, 0.3)
	else
		plate.label:SetTextColor(0.8 + 0.2 * g[1], 0.78 + 0.2 * g[2], 0.6 + 0.2 * g[3])
	end
	plate.label:ClearAllPoints()
	S.Fit(plate.label, ns.Collection:SeriesName(x.s), SLOT_W - 8, 10, 7.5)
	plate.label:SetPoint("CENTER", plate, "CENTER", 0, 0)
	CuratorOctoFull.ColorTexture(plate.edge, 0.62, 0.48, 0.2, 0.9)
	plate:SetAlpha(1)
	s:SetAlpha(1)
	self:PaintTick(cell)
	if moved and cell:IsShown() and cell:IsMouseOver() then
		self:EnterItem(cell, x)
	end
end

function IU:EnterItem(cell, x)
	local s = cell.slot
	if not s then
		return
	end
	if self.lensCell and self.lensCell ~= cell then
		self:Leave(self.lensCell)
	end
	if self.caseLensCell then
		self:LeaveCase(self.caseLensCell)
	end
	if self.itemHover and self.itemHover ~= cell then
		self:LeaveItem(self.itemHover)
	end
	self.itemHover = cell
	if s.litTw then
		ns.CancelTween(s.litTw)
	end
	local isCase = x.item == "case"
	local isKey = x.item == "key"
	s.litTw = ns.Tween(0.16, function(e)
		s.lit:SetAlpha(0.42 * e)
		if isKey then
			local k = KEY_SIZE * (1 + (KEY_LIFT - 1) * e)
			CuratorOctoFull.SetSize(s.key, k, k)
		end
	end, function()
		s.litTw = nil
	end, Ease.outQuad, A)
	-- (1 November: a booster rises, a display shines and lifts its lid a little, as on the page of the boosters; 1.14.2:
	-- a golden booster rises too)
	if (x.item == "pack" or x.item == "golden") and s.pack and A.LiftPack then
		A:LiftPack(s.pack, 5)
	elseif x.item == "display" and s.disp and ns.DisplaysUI.Peek then
		ns.DisplaysUI:Peek(s.disp)
	end
	if isCase and s.box then
		-- (it turns by itself, a glint over it at once)
		s.box.t, s.box.nextGlint = 0, 5.5
		s.box:SetIdle(true)
		s.box:Glint(1.1)
	end
	self:ItemTooltip(cell, x)
end

function IU:LeaveItem(cell)
	if self.itemHover == cell then
		self.itemHover = nil
	end
	local s = cell.slot
	if not s then
		return
	end
	if s.litTw then
		ns.CancelTween(s.litTw)
		s.litTw = nil
	end
	s.lit:SetAlpha(s.tickLit and 0.3 or 0)
	CuratorOctoFull.SetSize(s.key, KEY_SIZE, KEY_SIZE)
	if s.pack and ((s.pack.lift or 0) ~= 0 or s.pack.liftTw) and A.LiftPack then
		A:LiftPack(s.pack, 0)
	end
	local b = s.box
	if b and b.idle then
		b:SetIdle(false)
		b.lift, b.kick, b.dragOff, b.tiltOff = 0, 0, 0, 0
		b:SetView(ns.CrateBox.YAW, ns.CrateBox.PITCH)
	end
end

-- (1.14.3) A slot of another player's Everything: what it is, how many they have.
function IU:TheirItemTooltip(cell, x)
	GameTooltip:SetOwner(cell, (cell.col or 0) >= 4 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	local n = x.of or 0
	if x.item == "case" or x.item == "key" then
		local CS = ns.Cases
		local coll = CS and CS.COLLECTION and CS.COLLECTION[x.ed]
		GameTooltip:AddLine(x.item == "key" and string.format(L["A key of the %s"], EdName(x.ed)) or EdName(x.ed), 1, 0.84, 0.26)
		if coll then
			GameTooltip:AddLine(L[coll], 0.7, 0.7, 0.72)
		end
		GameTooltip:AddLine(string.format((x.item == "key" and L["Keys: %d"] or L["Cases to open: %d"]), n), 1, 1, 1)
	else
		GameTooltip:AddLine(ns.Collection:SeriesName(x.s), 1, 1, 1)
		if x.item == "display" then
			GameTooltip:AddLine(L["A display of 16 boosters"], GOLD[1], GOLD[2], GOLD[3])
			local open, cased = x.open or 0, x.cased or 0
			if open > 0 then
				GameTooltip:AddLine(open == 1 and L["1 display to open"] or string.format(L["%d displays to open"], open), 1, 0.92, 0.75)
			end
			if cased > 0 then
				GameTooltip:AddLine(cased == 1 and L["1 display in its case"] or string.format(L["%d displays in their case"], cased), 0.66, 0.86, 1)
			end
		elseif x.item == "golden" then
			GameTooltip:AddLine(string.format(L["Golden boosters: %d"], n), 1, 0.84, 0.35)
		else
			GameTooltip:AddLine(string.format(L["Boosters: %d"], n), 1, 0.92, 0.75)
		end
	end
	GameTooltip:Show()
end

-- What it is under the mouse: its edition, its collection, its cases or keys; what a click does.
function IU:ItemTooltip(cell, x)
	-- (1.14.3: another player's)
	if x.theirs then
		return self:TheirItemTooltip(cell, x)
	end
	local CS = ns.Cases
	-- (1 November: a booster of an album, in Everything: as on the page of the boosters)
	if x.item == "pack" then
		A:BoosterTooltip(cell, x.s)
		if ns.Packs(x.s) >= 2 and not (ns.Reroll and ns.Reroll:NoOpening()) then
			GameTooltip:AddLine(L["Right click: all of them (ten at most)"], 0.3, 1, 0.3)
			GameTooltip:Show()
		end
		return
	end
	if x.item == "display" then
		return self:DisplayTooltip(cell, x)
	end
	if x.item == "golden" then
		return self:GoldenTooltip(cell, x)
	end
	GameTooltip:SetOwner(cell, (cell.col or 0) >= 4 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	local coll = CS.COLLECTION and CS.COLLECTION[x.ed]
	if x.item == "case" then
		local keys = CS:Keys(x.ed)
		GameTooltip:AddLine(EdName(x.ed), 1, 0.84, 0.26)
		if coll then
			GameTooltip:AddLine(L[coll], 0.7, 0.7, 0.72)
		end
		GameTooltip:AddLine(string.format(L["Cases to open: %d"], CS:Count(x.ed)), 1, 1, 1)
		GameTooltip:AddLine(string.format(L["Keys: %d"], keys), keys > 0 and 1 or 0.6, keys > 0 and 0.86 or 0.6, keys > 0 and 0.4 or 0.62)
		if not self.sell then
			GameTooltip:AddLine(keys > 0 and L["Click: open it"] or L["Click: see it (a key opens it)"], 0.4, 1, 0.4)
		end
		if A.ShowCases then
			GameTooltip:AddLine(L["Right click: its collection"], 0.62, 0.62, 0.66)
		end
	else
		GameTooltip:AddLine(string.format(L["A key of the %s"], EdName(x.ed)), 1, 0.84, 0.26)
		GameTooltip:AddLine(L["One key opens one case of its edition."], 1, 1, 1, true)
		-- (1 November: in Everything, all of them in one slot: how many)
		if x.stack then
			GameTooltip:AddLine(string.format(L["Keys: %d"], CS:Keys(x.ed)), 1, 0.86, 0.4)
		end
		GameTooltip:AddLine(string.format(L["Cases to open: %d"], CS:Count(x.ed)), 0.85, 0.85, 0.88)
		if not self.sell then
			GameTooltip:AddLine(L["Click: to its case"], 0.4, 1, 0.4)
		end
	end
	-- (1.14.0, a player's word: at the reseller, what it brings)
	if self.sell then
		local RV = ns.Reseller
		GameTooltip:AddLine(" ")
		if x.takes then
			GameTooltip:AddLine(string.format(L["He pays %s for it."], ns.Rubies.Text(RV:PaysNow(x.item == "case" and RV.CASE_ITEM or RV.KEY_ITEM), 13)), 1, 0.82, 0.25)
			GameTooltip:AddLine(self:LineTicked(x) and L["Click: untick it"] or L["Click: tick it"], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Bought at the Exchange not long ago: it waits for the end of its quarantine."], 1, 0.45, 0.4, true)
		end
	end
	GameTooltip:Show()
end

-- (1.14.2) A golden booster in Everything: what it is, its album, what it holds, how many of that album wait, as on the
-- page of the boosters (UI/Boosters.lua, A:GoldenTooltip).
function IU:GoldenTooltip(cell, x)
	A:GoldenTooltip(cell, x.s, x.of, (cell.col or 0) >= 4 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
end

-- (1 November) A display of an album in Everything: its album, its kind, how many to open, how many in their case; a
-- click inspects one (UI/Displays.lua), or why it cannot.
function IU:DisplayTooltip(cell, x)
	local DU, D = ns.DisplaysUI, ns.Displays
	local s = x.s
	GameTooltip:SetOwner(cell, (cell.col or 0) >= 4 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	GameTooltip:AddLine(ns.Collection:SeriesName(s), 1, 1, 1)
	GameTooltip:AddLine(L["A display of 16 boosters"], GOLD[1], GOLD[2], GOLD[3])
	if DU.KindText then
		GameTooltip:AddLine(DU.KindText(s))
	end
	local open, cased = x.open or 0, x.cased or 0
	if open > 0 then
		GameTooltip:AddLine(open == 1 and L["1 display to open"] or string.format(L["%d displays to open"], open), 1, 0.92, 0.75)
	end
	if cased > 0 then
		GameTooltip:AddLine(cased == 1 and L["1 display in its case"] or string.format(L["%d displays in their case"], cased), 0.66, 0.86, 1)
	end
	GameTooltip:AddLine(L["Opened: its 16 boosters go to its album, to open as any other."], 0.85, 0.85, 0.85, true)
	local ok, why = D:CanOpen(s)
	if ok then
		GameTooltip:AddLine(L["Click: inspect it"], 0.4, 1, 0.4)
	elseif why and DU.WHY and DU.WHY[why] then
		GameTooltip:AddLine(L[DU.WHY[why]], 1, 0.45, 0.4, true)
	end
	GameTooltip:Show()
end

function IU:ClickItem(cell, x, button)
	-- (1.14.3: another player's: theirs to open, never mine)
	if x.theirs then
		return
	end
	self:LeaveItem(cell)
	GameTooltip:Hide()
	-- (1 November, in Everything: a booster opened as on its page, a right click all of them, then back to the inventory;
	-- a display inspected, UI/Displays.lua)
	if x.item == "pack" then
		return A:OpenFrom(x.s, button == "RightButton", "inventory")
	end
	-- (1.14.2: a golden booster of that album, the first that came; its button "Inventory" after it, as a booster:
	-- UI/Boosters.lua, A:OpenGolden)
	if x.item == "golden" then
		return A:OpenGolden(x.s, "inventory")
	end
	if x.item == "display" then
		local ok = ns.DisplaysUI:Inspect(x.s)
		if not ok then
			self:DisplayTooltip(cell, x)
		end
		return
	end
	if button == "RightButton" and x.item == "case" and A.ShowCases then
		ns.Play(ns.SND.page)
		return A:ShowCases(x.ed, "collection")
	end
	ns.Play(ns.SND.click)
	CR:Show(x.ed)
end

-- Under the items, as under the copies: on the left (where the album of the copies is chosen) the collection (the
-- cases); on the right a key to buy (a first click arms it, a second pays). The pages between them.
local function Head(page)
	local h = page.itemHead
	if h then
		return h
	end
	h = CreateFrame("Frame", nil, page)
	h:SetAllPoints()
	h:SetFrameLevel(page:GetFrameLevel() + 30)
	h.buy = S.Button(h, "", 176, 22)
	h.buy:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 6)
	h.coll = S.Button(h, "", 150, 22)
	h.coll:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 0, 6)
	page.itemHead = h
	return h
end

local function Fit(b, least)
	b:SetWidth(math.max(least, math.ceil(ns.TextWidth(b:GetFontString() or b.label) + 26)))
end

-- The page of the cases (kind "cases") or of the keys ("keys"): the items one by one in the grid of the copies.
function IU:PaintCasesPage(page, kind)
	local CS = ns.Cases
	local RB = ns.Rubies
	if self.lensCell then
		self:Leave(self.lensCell)
	end
	if self.caseLensCell then
		self:LeaveCase(self.caseLensCell)
	end
	page.sort:Hide()
	page.only:Hide()
	local h = Head(page)
	h:Show()
	local ed = CS and CS.EDITION
	local title = ed and EdName(ed) or ""
	local b = h.buy
	if b.armedCase ~= ed then
		b.armed = nil
	end
	if Armed(b) then
		b:SetText(L["Confirm"])
	else
		b:SetText(L["Buy a key"] .. "  " .. (RB and RB.Text(CS:KeyPrice(), 13) or tostring(CS:KeyPrice())))
	end
	Fit(b, 150)
	CuratorOctoFull.SetScript(b, "OnClick", function()
		IU:BuyKey(b, ed)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function()
		GameTooltip:SetOwner(b, "ANCHOR_TOP")
		GameTooltip:AddLine(string.format(L["A key of the %s"], title), 1, 0.84, 0.26)
		GameTooltip:AddLine(L["One key opens one case of its edition."], 1, 1, 1, true)
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(CS:KeyPrice(), 13)), 1, 0.82, 0.25)
		GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 0.85, 0.85, 0.88)
		GameTooltip:AddLine(Armed(b) and L["Click again to confirm."] or L["Click, then click again to confirm."], 0.3, 1, 0.3)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetShown(b, ed ~= nil and not self.sell)
	h.coll:SetText(L["See the collection"])
	Fit(h.coll, 150)
	CuratorOctoFull.SetShown(h.coll, kind == "cases" and A.ShowCases ~= nil and ed ~= nil and not self.sell)
	CuratorOctoFull.SetScript(h.coll, "OnClick", function()
		ns.Play(ns.SND.page)
		A:ShowCases(ed, "collection")
	end)
	-- (the lines of the page: those Tick all and Tick the page tick at the reseller)
	local lines = self:ItemLines(kind)
	self.lines = lines
	self:PaintGrid(page, lines)
	if self.sell then
		self:PaintSell()
	end
	-- (none: where they come from, what a key does)
	if kind == "cases" then
		page.empty:SetText(L["No case yet."] .. "\n\n" .. L["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."])
	else
		page.empty:SetText(L["No key yet."] .. "\n\n" .. string.format(L["A key of its edition opens a case: %s each, none given."], RB and RB.Text(CS:KeyPrice(), 12) or ""))
	end
	if not self.sell then
		if kind == "cases" then
			A:SetTitle(L["Inventory"], string.format(L["Cases to open: %d"], CS:Total()))
		else
			local keys = 0
			for _, k in ipairs(CS:Editions()) do
				keys = keys + CS:Keys(k)
			end
			A:SetTitle(L["Inventory"], string.format(L["Keys: %d"], keys))
		end
	end
end

function IU:HideCasesPage(page)
	if page.itemHead then
		page.itemHead:Hide()
	end
end

-- A key bought over the cases or the keys: a first click arms the button, a second within its seconds pays.
function IU:BuyKey(b, case)
	local CS = ns.Cases
	if not Armed(b) or b.armedCase ~= case then
		b.armed, b.armedCase = GetTime(), case
		ns.Play(ns.SND.click)
		A:Refresh()
		ns.Delay(ARM + 0.05, function()
			if not Armed(b) and A.frame and A.frame:IsShown() and A.mode == "inventory" and (IU.filter == "keys" or IU.filter == "cases") then
				b.armed = nil
				A:Refresh()
			end
		end, A)
		return
	end
	b.armed = nil
	GameTooltip:Hide()
	local ok, why = CS:BuyKey(case, 1)
	if not ok then
		ns.Play(ns.SND.close)
		local text = (why == "rubies" and L["Not enough rubies."]) or (why == "guard" and ns.Guard and L[ns.Guard.SHORT])
			or L["Curator is closed: no case can be opened."]
		ns.Print("|cffff6060" .. text .. "|r")
		A:Refresh()
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.claim)
	local def = ns.Crates and ns.Crates[case]
	ns.Print(L["A key of the %s, for %s."], L[(def and def.title) or "Test case"], ns.Rubies.Text(CS:KeyPrice()))
	A:Refresh()
end
