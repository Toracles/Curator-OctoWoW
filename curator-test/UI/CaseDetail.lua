local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Ease = ns.Ease
local A = ns.Album
local E = ns.Expertise
local RB = ns.Rubies
local CR = ns.CrateUI

-------------------------------------------------------------------------------
-- (1.14.0, after its second test: « les cartes de caisses ont les mêmes menus que les cartes de boosters ») A card of a
-- case shown big as the cards of the boosters are, in the detail of the album (UI/Album.lua): on its socle, on the
-- photo of its collection, in the light of its rank, held in the hand (UI/Inspect.lua), in its case when it was
-- appraised (UI/CrateCard.lua: the slab of the expert, in 3D). Beside it, as for a card of a booster: its name, its
-- rank, what it is, its copies (a chip each: the one chosen is the one shown, the one the expert appraises), the
-- condition, the finish and the story of the copy chosen, its expertise, its collection and its number in it, Pin to
-- showcase and Show in the chat. At a banker, the expert appraises the copy chosen as he appraises the cards of the
-- boosters (UI/Expertise.lua: the room darkens, his four looks, the numbers roll, the verdict, the case comes down on
-- it): the grade it came with, hidden in its condition until then, told (Cases.lua: CS:Appraise).
-- The detail shows one card at a time: a card of a booster (d.shown, d.card its card) or a card of a case (d.caseShown,
-- d.card its card of a case, d.crate); A:ShowDetail goes back to the cards of the boosters.
-------------------------------------------------------------------------------
local CD = { sel = {}, descs = {} }
ns.CaseDetail = CD

local GOLD = S.GOLD
local ARM = 3
-- its rank: its gem (and a tint of it), how bright the rays behind it, the rarity of the boosters it shows as (the motes
-- of light rising from the socle: the best ones)
local GEM = { { "Gem3" }, { "Gem4" }, { "Gem4", { 1, 0.6, 0.86 } }, { "Gem6" }, { "Gem5" } }
local RAYS = { 0.2, 0.28, 0.36, 0.44, 0.52 }
local RARITY = { 3, 4, 4, 5, 6 }
local CARD_Y = 26
-- the finishes: their name, their ink, the key of the edge of a chip (UI/Copies.lua: the colour of a finish)
local FIN = {
	thunder = { name = "Thunderforged", ink = { 0.55, 0.8, 1 }, chip = "s" },
	titan = { name = "Titanforged", ink = { 1, 0.84, 0.46 }, chip = "h" },
}
local FIN_ORDER = { titan = 1, thunder = 2 }
-- (the photo of a collection when its case has none)
local STUDIO = "StudioScarlet"

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-------------------------------------------------------------------------------
-- A card of a case
-------------------------------------------------------------------------------
-- A card of a case, the same table each time (a card of its edition: its entry; a weapon of legend: its item):
-- { isCase, case, tier, entry | weapon, key }.
function CD.Desc(case, tier, entry, weapon)
	local key = "k:" .. tostring(case) .. ":" .. (weapon and ("w" .. tostring(weapon)) or tostring(entry and entry.key))
	local d = CD.descs[key]
	if not d then
		d = { isCase = true, case = case, tier = tier, entry = entry, weapon = weapon, key = key }
		CD.descs[key] = d
	end
	return d
end

-- The card of a copy won (a record of Cases.lua, as it leaves it).
function CD.DescOf(w)
	if not w then
		return nil
	end
	if w.w then
		return CD.Desc(w.c, CR.TOP, nil, w.w)
	end
	local e, r = ns.CaseCards.Entry(w.c, w.e)
	return CD.Desc(w.c, r or tonumber(w.r) or 1, e, nil)
end

-- Its name in the language of the game.
function CD.Name(desc)
	if desc.weapon then
		return ns.CrateCard.WeaponName({ id = desc.weapon }) or L["Priceless card"]
	end
	return desc.entry and ns.CrateItems:Name(desc.entry) or L["Priceless card"]
end

-- What it is, under its name (a weapon: the class of its version, its side).
function CD.Line(desc, w)
	if desc.weapon then
		local note = w and ns.CrateCard.WeaponNote({ id = desc.weapon, class = w.cl, faction = w.fa })
		return L["A weapon of legend"] .. (note and ("  ·  " .. note) or "")
	end
	return desc.entry and ns.CrateItems:From(desc.entry) or ""
end

-- The icon of the case of its collection (its emblem in the panel, cut round).
local function IconOf(desc)
	local def = ns.Crates and ns.Crates[desc.case]
	return (def and def.icon) or "Interface\\Icons\\INV_Crate_03"
end
CD.IconOf = IconOf

-- Its collection, its number in it (the cards of its edition in the order of its case; a weapon of legend: its rank).
function CD.Where(desc)
	local CS = ns.Cases
	local coll = L[(CS.COLLECTION and CS.COLLECTION[desc.case]) or "Paladin Collection 2026"]
	if desc.weapon then
		return coll .. " · " .. L[CR.RANKS[CR.TOP].label]
	end
	local own = ns.CrateItems:Case(desc.case)
	local n, at = 0, nil
	for r = 1, CR.TOP - 1 do
		for _, e in ipairs(own and own[r] or {}) do
			n = n + 1
			if desc.entry and e.key == desc.entry.key then
				at = n
			end
		end
	end
	return coll .. " · " .. (at and string.format(("%d/%d"), at, n) or "?")
end

-- Its copies won, as they are shown: those appraised (the finest first), then by finish (titanforged, thunderforged),
-- by condition (the finest first), the oldest first.
function CD:Copies(desc)
	local CS = ns.Cases
	local list = {}
	for _, w in ipairs(CS:Won(desc.case)) do
		if (desc.weapon and w.w == desc.weapon) or (not desc.weapon and not w.w and desc.entry and w.e == desc.entry.key) then
			list[CuratorOctoFull.Length(list) + 1] = w
		end
	end
	table.sort(list, function(a, b)
		local ga, gb = a.ap and (tonumber(a.g) or 0) or -1, b.ap and (tonumber(b.g) or 0) or -1
		if ga ~= gb then
			return ga > gb
		end
		local fa, fb = FIN_ORDER[a.f or ""] or 3, FIN_ORDER[b.f or ""] or 3
		if fa ~= fb then
			return fa < fb
		end
		local ta, tb = tonumber(a.t) or 0, tonumber(b.t) or 0
		if ta ~= tb then
			return ta < tb
		end
		return (a.i or 0) < (b.i or 0)
	end)
	return list
end

-- The copy chosen of a card (its copies too): the one asked for when it is one of them, else the first.
function CD:Selected(desc)
	local list = self:Copies(desc)
	local id = self.sel[desc.key]
	for _, w in ipairs(list) do
		if w.i == id then
			return w, list
		end
	end
	local w = list[1]
	self.sel[desc.key] = w and w.i or nil
	return w, list
end

-- What the label of its case says (as Expertise.lua's E:LabelOf for a card of a booster).
function CD.Label(desc, w)
	local CS = ns.Cases
	local g = math.max(1, math.min(10, math.floor(tonumber(w.g) or 1)))
	local coll = L[(CS.COLLECTION and CS.COLLECTION[desc.case]) or "Paladin Collection 2026"]
	local r = CR.RANKS[desc.tier] or CR.RANKS[1]
	return { grade = g, text = E.Text(g), word = E.Word(g), name = CD.Name(desc), album = coll .. "  ·  " .. L[r.label], num = "",
		marks = E.DecodeMarks(w.m), cert = tonumber(w.ce), color = E.Color(g),
		-- (1 November: titanforged, certified by a master of the mages, Mages.lua: its family and its number)
		titan = ns.Mages and ns.Mages.Label(w, true) or nil }
end

-- The card of a copy as the card of a case shows it (UI/CrateCard.lua: card:Set).
local function PickOf(desc, w)
	-- (31 October, his word: its wear on it, as the cards of the boosters; never its condition in words)
	local pick = { tier = desc.tier, wear = w and ns.Cases.WearOf(w) or nil, finish = w and w.f or nil,
		-- (1.14.0: titanforged, its pattern)
		pt = w and ns.Cases.Pattern(w) or nil }
	if desc.weapon then
		pick.weapon = { id = desc.weapon, class = w and w.cl, faction = w and w.fa, line = w and w.l }
	else
		pick.entry = desc.entry
	end
	return pick
end
CD.PickOf = PickOf

-------------------------------------------------------------------------------
-- The detail, for a card of a case
-------------------------------------------------------------------------------
-- Its card of a case, its chips, its emblem: made once, beside the card of the boosters.
function CD:Build(d)
	if d.crate then
		return
	end
	local bc = d.boosterCard or d.card
	local c = ns.CrateCard.New(d.holder, bc.W)
	c:SetPoint("CENTER", d.holder, "CENTER")
	c:SetFrameLevel(bc:GetFrameLevel())
	-- (held in the hand as the cards of the boosters are; flat at rest, all that moves on it alive)
	ns.Inspect:Attach(c, d.holder, { zoom = { 0.85, 1.25, 1 }, lean = false })
	c:Hide()
	d.crate = c
	-- the emblem of its collection: the icon of its case, cut round
	local set = d:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(set, 22, 22)
	set:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local round = CuratorOctoFull.CreateMaskTexture(d)
	round:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	round:SetAllPoints(set)
	CuratorOctoFull.AddMaskTexture(set, round)
	set:Hide()
	d.caseSet = set
	-- its copies: a chip each (UI/Copies.lua), the copy chosen lit
	local CU = ns.CopiesUI
	local st = CreateFrame("Frame", nil, d)
	CuratorOctoFull.SetSize(st, d.textW or 374, 18)
	st:SetPoint("LEFT", d.copies, "RIGHT", 10, 0)
	st.chips = {}
	for i = 1, 8 do
		local i = i; local b = CU.Chip(st, function(self)
			if self.w and d.caseShown then
				ns.Play(ns.SND.click)
				CD:Select(d, self.w.i)
			end
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			if self.w and d.caseShown then
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				CD:CopyTooltip(GameTooltip, d.caseShown, self.w, self.n)
				GameTooltip:AddLine(L["Click to show it."], 0.4, 1, 0.4)
				GameTooltip:Show()
			end
		end)
		st.chips[i] = b
	end
	st.more = CU.Chip(st, function()
		if d.caseShown and ns.InventoryUI then
			ns.Play(ns.SND.click)
			A:HideDetail()
			ns.InventoryUI:Open("all")
		end
	end)
	st:Hide()
	d.caseStrip = st
	-- (they step aside with what there is to know, during an appraisal)
	if d.infoParts then
		d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = st
		d.infoParts[CuratorOctoFull.Length(d.infoParts) + 1] = set
	end
	-- (the buttons of the panel: for the card shown, of a booster or of a case)
	CuratorOctoFull.SetScript(d.link, "OnClick", function()
		if d.caseShown then
			CD:Link(d)
		elseif d.shown then
			-- (1 November: the pattern of the copy shown and its certificate of the mages with it, UI/Copies.lua; 1.14.3: the
			-- copy itself, its very card, UI/Links.lua)
			ns.Links:Insert(d.shown, d.finish, d.pattern, d.tc, A.mode ~= "member" and ns.CopiesUI and ns.CopiesUI:Selected(d.shown) or nil)
		end
	end)
	CuratorOctoFull.SetScript(d.trade, "OnClick", function()
		if d.caseShown then
			CD:Trade(d)
		elseif d.shown then
			A:ContractFor(d.shown)
		end
	end)
end

-- The detail back to the cards of the boosters (A:ShowDetail).
function CD:Leave(d)
	if not (d and d.caseShown) then
		return
	end
	d.caseShown = nil
	local c = d.crate
	if c then
		ns.CancelOwner(c)
		c:SetSlab(nil)
		c.turn.hold = nil
		c:Hide()
	end
	d.card = d.boosterCard
	d.card:Show()
	d.caseSet:Hide()
	d.caseStrip:Hide()
	d.set:Show()
	d.num:ClearAllPoints()
	d.num:SetPoint("LEFT", d.set, "RIGHT", 6, 0)
	d.spare:ClearAllPoints()
	d.spare:SetPoint("TOPLEFT", d.set, "BOTTOMLEFT", 2, -14)
end

-- A card of a case shown big (desc: CD.Desc; id: the copy chosen, else its finest).
function A:ShowCaseDetail(desc, id)
	local d = self.detail
	if not (d and desc) then
		return
	end
	local XU = ns.ExpertiseUI
	if XU then
		XU:EndCeremony(true)
	end
	-- (1 November: the scene of the enchanter ended, his quote put away: UI/Restore.lua)
	local RU = ns.RestoreUI
	if RU then
		RU:End(true)
		RU:HideQuote()
	end
	if d.rest then
		d.rest.button.armed = nil
	end
	CD:Build(d)
	-- (another card shown: the copy chosen of this one, its zoom as its case wants)
	if id then
		CD.sel[desc.key] = id
	end
	local w = CD:Selected(desc)
	if not w then
		return
	end
	-- the card of a case in the place of the card of the boosters
	d.shown, d.finish = nil, nil
	d.caseShown = desc
	if d.boosterCard then
		d.boosterCard.turn.dragging = false
		d.boosterCard:Hide()
	end
	local c = d.crate
	d.card = c
	c:Show()
	-- what the cards of the boosters show there and a card of a case does not: their blocks, their entrance
	for _, x in ipairs({ d.replay, d.strip or false, d.void or false, d.rest or false, d.set }) do
		if x then
			x:Hide()
		end
	end
	local rank = CR.RANKS[desc.tier] or CR.RANKS[1]
	local col = rank.color
	d.rarity = RARITY[desc.tier] or 3
	d.glow = col
	-- the photo of its collection, cut to the page
	local def = ns.Crates and ns.Crates[desc.case]
	local studio = (def and def.art and def.art.studio) or STUDIO
	d.bg:SetTexture(MEDIA .. studio)
	local fw, fh = d:GetWidth(), d:GetHeight()
	local u = ((fw and fh and fh > 0) and (fw / fh) or 1.38) / 2
	d.bg:SetTexCoord(0.5 - u / 2, 0.5 + u / 2, 0, 1)
	d.halo:SetVertexColor(col[1], col[2], col[3])
	d.rays:SetVertexColor(col[1], col[2], col[3])
	d.rays2:SetVertexColor(1, 0.78, 0.36)
	d.pedGlow:SetVertexColor(0.6 + 0.4 * col[1], 0.6 + 0.4 * col[2], 0.6 + 0.4 * col[3])
	d.pedA = 0.22 + 0.06 * d.rarity
	d.motes:Clear()
	d.sparks:Clear()
	d.moteT = 0.4
	-- the card: the copy chosen, its back the one of its case
	CD:PaintCard(d, "show")
	-- what there is to know of it
	CD:PaintPanel(d)
	d.idle = 0
	-- (shown over the inventory: the inventory again when it closes, as for a card of a booster)
	local f = self.frame
	local IU = ns.InventoryUI
	if IU and f and f.inv and self.mode == "inventory" and (f.inv:IsShown() or (f.invFoot and f.invFoot:IsShown())) then
		IU.under = true
		f.inv:Hide()
		if f.invFoot then
			f.invFoot:Hide()
		end
		if f.invBar then
			f.invBar:Hide()
		end
	end
	-- it comes: the place fades in, the card rises onto its socle in a flash of its light, the rays of its rank open
	d:SetAlpha(0)
	d:Show()
	local rays = RAYS[desc.tier] or 0.2
	d.rays:SetAlpha(0)
	d.rays2:SetAlpha(0)
	d.halo:SetAlpha(0)
	ns.Tween(0.2, function(k)
		d:SetAlpha(k)
	end, nil, Ease.outQuad, self)
	ns.Tween(0.45, function(k, raw)
		c:ClearAllPoints()
		c:SetPoint("CENTER", d.holder, "CENTER", 0, -26 * (1 - k))
		c:SetAlpha(math.min(1, raw * 3))
		d.rays:SetAlpha(rays * k)
		d.rays2:SetAlpha((desc.tier >= CR.TOP and 0.3 or 0) * k)
		d.halo:SetAlpha((0.2 + 0.05 * desc.tier) * k)
	end, nil, Ease.outBack, self)
	ns.Delay(0.2, function()
		if d.caseShown ~= desc then
			return
		end
		local x = 44 + c.W / 2 - (d:GetWidth() or 762) / 2
		local y = CARD_Y - c.H / 2 - 10
		d.sparks:Burst(x, y, col, 10 + 4 * desc.tier, 160, 0.7, 16)
		c.hot:SetVertexColor(1, 1, 1)
		c.hot:SetAlpha(0.35 + 0.06 * desc.tier)
		ns.Tween(0.4, function(k)
			c.hot:SetAlpha((0.35 + 0.06 * desc.tier) * (1 - k))
		end, nil, Ease.outQuad, self)
		if desc.weapon or desc.tier >= 4 then
			ns.Play(ns.SND.shiny)
		end
	end, self)
end

-- A copy won shown big (its number: Cases.lua), in the album of its collection.
function A:ShowCaseCopy(id)
	local CS = ns.Cases
	local w = CS and CS:Card(id)
	if not w then
		return
	end
	self:Build()
	local d = self.detail
	if not (self.frame:IsShown() and (self.mode == "cases" or self.mode == "inventory")) then
		if self.ShowCases then
			self:ShowCases(w.c, "collection")
		end
	end
	self:ShowCaseDetail(CD.DescOf(w), id)
	return d
end

-- The card of the copy chosen: its rank, its creature or its spell or its weapon, its condition, its finish; in its case
-- when it was appraised, at the zoom of its case (how: "show" at once, "after" easing to it, else as it is).
function CD:PaintCard(d, how)
	local desc = d.caseShown
	local c = d.crate
	if not (desc and c) then
		return
	end
	local w = self:Selected(desc)
	local def = ns.Crates and ns.Crates[desc.case]
	local key = desc.key .. ":" .. tostring(w and w.i) .. ":" .. tostring(w and w.f) .. ":" .. (w and ns.Cases.WearKey(w) or "")
	if c.shownKey ~= key then
		c.shownKey = key
		c:Set(PickOf(desc, w), CR.RANKS)
		c:SetBack(def and def.art and def.art.back or nil)
		c:SetLive(true)
		if ns.Inspect and c.turn then
			ns.Inspect:Reset(c, 0, 1)
		end
	end
	local XU = ns.ExpertiseUI
	if XU and XU.cer then
		return
	end
	local info = (w and w.ap) and CD.Label(desc, w) or nil
	c:SlabAlpha(1)
	c:SetSlab(info)
	local t = c.turn
	if t and XU then
		local z = info and XU.SLAB_ZOOMS or XU.CARD_ZOOMS
		t.min, t.max = z[1], z[2]
		local at = info and XU.SLAB_ZOOM or 1
		if how == "show" then
			t.zoom, t.zoomTo = at, at
			t.holder:SetScale(at)
		elseif how == "after" then
			t.zoomTo = at
		else
			t.zoomTo = math.max(t.min, math.min(t.max, t.zoomTo or at))
		end
	end
	d.liftK = 1
	if XU then
		XU:Seat(d, 0)
	end
end

-- What there is to know of it, beside it.
function CD:PaintPanel(d)
	local desc = d.caseShown
	if not desc then
		return
	end
	local CS = ns.Cases
	local w, list = self:Selected(desc)
	local rank = CR.RANKS[desc.tier] or CR.RANKS[1]
	local tc = rank.text or rank.color
	-- its name (a bit smaller for the longest ones), its rank and its gem, what it is
	S.SetFontObject(d.name, "GameFontNormalHuge")
	local name = CD.Name(desc)
	d.name:SetText(name)
	if ns.TextWidth(d.name) > d.name:GetWidth() * 0.98 then
		S.Fit(d.name, name, d.name:GetWidth() * 0.98, 19, 15)
	end
	d.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	local gem = GEM[desc.tier] or GEM[1]
	d.gem:SetTexture(MEDIA .. gem[1])
	local gt = gem[2] or { 1, 1, 1 }
	d.gem:SetVertexColor(gt[1], gt[2], gt[3])
	d.rar:SetText(L[rank.label])
	d.rar:SetTextColor(tc[1], tc[2], tc[3])
	d.replay:Hide()
	d.line:SetText(CD.Line(desc, w))
	-- its copies, their chips; the condition and the finish of the copy chosen, its story
	d.copies:SetText(string.format(L["Copies: %d"], CuratorOctoFull.Length(list)))
	self:PaintStrip(d, list, w)
	-- (31 October, his word: its condition shows on the card, never in words; its finish)
	local parts = {}
	if w then
		local fin = FIN[w.f or ""]
		if fin then
			parts[CuratorOctoFull.Length(parts) + 1] = "|cff" .. Hex(fin.ink) .. L[fin.name] .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or "") .. "|r"
		else
			parts[CuratorOctoFull.Length(parts) + 1] = L["Normal copy"]
		end
	end
	d.shiny:SetText(table.concat(parts, "   ·   "))
	d.shiny:SetTextColor(0.86, 0.86, 0.9)
	d.found:ClearAllPoints()
	d.found:SetPoint("TOPLEFT", d.shiny, "BOTTOMLEFT", 0, -8)
	if w then
		local how = ns.Cases.How(w)
		local day = tonumber(w.t) and tonumber(w.t) > 0 and date("%d/%m/%Y", w.t) or nil
		d.found:SetText(how .. (day and ("  ·  " .. day) or ""))
	else
		d.found:SetText("")
	end
	-- its expertise (the block of the expert, UI/Expertise.lua), its collection under it
	self:PaintAppraise(d)
	d.caseSet:SetTexture(IconOf(desc))
	d.caseSet:Show()
	d.num:ClearAllPoints()
	d.num:SetPoint("LEFT", d.caseSet, "RIGHT", 6, 0)
	d.num:SetText(CD.Where(desc))
	-- (its copies to exchange: the contracts of the cases, on the desk of the notary)
	local spare = self:Spare(desc, list)
	d.spare:ClearAllPoints()
	d.spare:SetPoint("TOPLEFT", d.caseSet, "BOTTOMLEFT", 2, -14)
	CuratorOctoFull.SetShown(d.spare, spare > 0)
	CuratorOctoFull.SetShown(d.trade, spare > 0)
	d.spare:SetText(string.format(L["Copies to exchange: %d"], spare))
	d.pin:ClearAllPoints()
	d.pin:SetPoint("TOPLEFT", spare > 0 and d.spare or d.caseSet, "BOTTOMLEFT", spare > 0 and -2 or 0, -30)
	CuratorOctoFull.SetShown(d.pin, A.mode ~= "member")
	d.link:ClearAllPoints()
	d.link:SetPoint("LEFT", d.pin, "RIGHT", 10, 0)
	self:PaintPin(d)
	-- (1 November: a copy quoted, away from an enchanter: the button of his quote, UI/Restore.lua)
	local RU = ns.RestoreUI
	if RU and RU.PaintQuoteButton then
		RU:PaintQuoteButton()
	end
end

-- Its copies to exchange (a contract of the cases: ten of a rank for one of the next, Cases.lua): those not kept.
function CD:Spare(desc, list)
	if desc.weapon or desc.tier >= (ns.Cases.CONTRACT_TOP or CR.TOP) then
		return 0
	end
	list = list or self:Copies(desc)
	local n = 0
	for _, w in ipairs(list) do
		-- (1 November: a card at an enchanter stays out of them)
		if not w.ap and type(w.aw) ~= "table" then
			n = n + 1
		end
	end
	-- (one copy kept of each card, when the player keeps one: UI/Options.lua)
	local keep = (ns.db and ns.db.keepOne) and 1 or 0
	return math.max(0, math.min(n, CuratorOctoFull.Length(list) - keep))
end

-- The chips of its copies, the copy chosen lit; none when it has only one.
function CD:PaintStrip(d, list, sel)
	local st = d.caseStrip
	local CU = ns.CopiesUI
	if not st then
		return
	end
	local room = (d.textW or 374) - ns.TextWidth(d.copies) - 10
	local x, shown = 0, 0
	for i, b in ipairs(st.chips) do
		local w = list[i]
		b.w, b.n = w, i
		if w then
			local text = "#" .. i
			if w.ap then
				text = text .. " · " .. E.Text(tonumber(w.g) or 1)
			end
			CU.PaintChip(b, text, FIN[w.f or ""] and FIN[w.f].chip or "n", sel == w, false)
			local bw = b:GetWidth()
			local rest = CuratorOctoFull.Length(list) - i
			if x + bw > room - (rest > 0 and 40 or 0) and i > 1 then
				b:Hide()
				b.w = nil
			else
				b:ClearAllPoints()
				b:SetPoint("LEFT", st, "LEFT", x, 0)
				x = x + bw + 4
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
end

-- Its story in a tooltip: its number among its copies, its finish, its condition, how and when it came, its expertise.
function CD:CopyTooltip(tip, desc, w, n)
	local CS = ns.Cases
	local fin = FIN[w.f or ""]
	tip:AddLine(string.format(L["Copy %s"], "#" .. tostring(n or "?")) .. "  ·  " .. (fin and L[fin.name] or L["Normal copy"]) .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or ""), GOLD[1], GOLD[2], GOLD[3])
	-- (1 November: its certificate of the mages, Mages.lua)
	local ml, certified = ns.Mages and ns.Mages.Line(w, true)
	if ml then
		tip:AddLine(ml, certified and 0.86 or 0.6, certified and 0.92 or 0.62, certified and 1 or 0.7)
	end
	local day = tonumber(w.t) and tonumber(w.t) > 0 and date("%d/%m/%Y", w.t) or nil
	tip:AddLine(ns.Cases.How(w) .. (day and ("  ·  " .. day) or ""), 0.86, 0.86, 0.88)
	if w.ap then
		local at = tonumber(w.at) and date("%d/%m/%Y", w.at) or nil
		tip:AddLine(string.format(L["Grade: %s"], E.Label(tonumber(w.g) or 1)) .. (at and ("  ·  " .. at) or ""), 1, 1, 1)
		local m = E.DecodeMarks(w.m)
		if m then
			tip:AddLine(E.MarksText(m), 0.78, 0.8, 0.86, true)
		end
		if tonumber(w.ce) then
			tip:AddLine(string.format(L["Certificate No. %s"], E.CertText(w.ce)), 0.62, 0.62, 0.66)
		end
	end
end

-- Another copy chosen: it is shown, its panel painted again.
function CD:Select(d, id)
	local desc = d.caseShown
	if not desc then
		return
	end
	self.sel[desc.key] = id
	local b = d.appraise
	if b then
		b.armed = nil
	end
	-- (1 November: another copy, its own quote, UI/Restore.lua)
	if d.rest then
		d.rest.button.armed = nil
	end
	local RU = ns.RestoreUI
	if RU then
		RU:HideQuote()
	end
	self:PaintCard(d, "after")
	self:PaintPanel(d)
end

-------------------------------------------------------------------------------
-- Its expertise: the block of the expert (UI/Expertise.lua), for the copy chosen
-------------------------------------------------------------------------------
local WHY = {
	-- (1 November: at an enchanter, UI/Restore.lua)
	away = "At an enchanter already: pick it up first.",
	bank = "At a banker: open your bank, then this card in your album.",
	done = "Appraised already: a copy is appraised once.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: nothing can be bought.",
	-- (1 November, his word: a titanforged card, its certificate of a master of the mages first, Mages.lua)
	cert = "Go see a master of the mages to certify your titanforged!",
}

function CD:PaintAppraise(d)
	local ap = d.appr
	local desc = d.caseShown
	if not (ap and desc) then
		return
	end
	local XU = ns.ExpertiseUI
	local CS = ns.Cases
	local w = self:Selected(desc)
	local mine = A.mode ~= "member"
	CuratorOctoFull.SetShown(ap, mine)
	d.caseSet:ClearAllPoints()
	if not mine then
		if d.rest then
			d.rest:Hide()
		end
		d.caseSet:SetPoint("TOPLEFT", d.found, "BOTTOMLEFT", -2, -22)
		return
	end
	d.caseSet:SetPoint("TOPLEFT", ap, "BOTTOMLEFT", -2, -14)
	if XU and XU.cer then
		return
	end
	-- (1 November, his word: « il faut que les cartes de caisse peuvent être aussi restaurées »: at an enchanter, the
	-- block of the restoration in the place of the expert's, UI/Restore.lua)
	local RU = ns.RestoreUI
	if RU and RU.Shown and RU.Shown() then
		ap:Hide()
		return RU:Paint()
	end
	if d.rest then
		d.rest:Hide()
	end
	local b = ap.button
	ap.line:ClearAllPoints()
	if w and w.ap then
		local g = tonumber(w.g) or 1
		ap.tab:SetGrade(g)
		ap.line:SetPoint("LEFT", ap.tab, "RIGHT", 12, 0)
		ap.line:SetWidth((d.textW or 374) - 104)
		local parts = {}
		if tonumber(w.at) then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["Appraised on %s"], date("%d/%m/%Y", w.at))
		end
		if tonumber(w.ce) then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["No. %s"], E.CertText(w.ce))
		end
		ap.line:SetText(table.concat(parts, "  ·  "))
		ap.line:SetTextColor(0.86, 0.86, 0.86)
		local m = E.DecodeMarks(w.m)
		ap.marks:SetText(m and E.MarksText(m) or "")
		ap.marks:SetTextColor(0.78, 0.8, 0.86)
		b.armed = nil
		b:Hide()
		return
	end
	ap.tab:Hide()
	ap.line:SetPoint("TOPLEFT", 0, -4)
	ap.line:SetWidth((d.textW or 374) - 190)
	ap.line:SetText(L["Not appraised"])
	ap.line:SetTextColor(0.7, 0.7, 0.74)
	ap.marks:SetText(E:AtBank() and L["The expert of the bank appraises this copy: once, for good."] or L["At a banker, an expert appraises this copy: once, for good."])
	ap.marks:SetTextColor(0.62, 0.64, 0.7)
	if not w then
		b:Hide()
		return
	end
	b:Show()
	local ok, why = CS:CanAppraise(w.i)
	b.why = why
	if why == "cert" then
		ap.marks:SetText(L[WHY.cert])
		ap.marks:SetTextColor(0.55, 0.85, 1)
	end
	local price = RB.Text(CS:AppraisePrice(w), 13)
	if b.armed and b.armedId == w.i and GetTime() - b.armed < ARM then
		b:SetLabel(L["Confirm"] .. " · " .. price)
	else
		b:SetLabel(L["Appraise"] .. " · " .. price)
	end
	CuratorOctoFull.SetEnabled(b, ok and true or false)
end

function CD:AppraiseTooltip(d, b)
	local desc = d.caseShown
	local CS = ns.Cases
	local w = desc and self:Selected(desc)
	if not w then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L["The expertise of a card"], 1, 1, 1)
	GameTooltip:AddLine(L["Its exact grade, hidden in its condition, told once and for all: it goes into its case."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(CS:AppraisePrice(w), 13)), 1, 0.82, 0.25)
	local why = b.why == "guard" and ns.Guard and ns.Guard.SHORT or WHY[b.why or ""]
	if why then
		GameTooltip:AddLine(L[why], 1, 0.45, 0.4, true)
	elseif b.armed then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 1, 0.64, 0.68)
	GameTooltip:Show()
end

-- A first click arms the button, a second within its seconds appraises the copy chosen: the scene of the expert.
function CD:AppraiseClick(d)
	local XU = ns.ExpertiseUI
	local CS = ns.Cases
	local b = d.appraise
	local desc = d.caseShown
	local w = desc and self:Selected(desc)
	if not (w and b and XU) or XU.cer then
		return
	end
	if ns.Beta and ns.Beta:Blocked() then
		return
	end
	local ok, why = CS:CanAppraise(w.i)
	if not ok then
		ns.Play(ns.SND.close)
		b.why = why
		self:AppraiseTooltip(d, b)
		return
	end
	if not (b.armed and b.armedId == w.i and GetTime() - b.armed < ARM) then
		b.armed, b.armedId = GetTime(), w.i
		ns.Play(ns.SND.click)
		self:PaintAppraise(d)
		self:AppraiseTooltip(d, b)
		return
	end
	b.armed, b.armedId = nil, nil
	-- (its grade told by the scene only: what is painted waits for its end)
	XU.busy = true
	local res, why2 = CS:Appraise(w.i)
	if not res then
		XU.busy = nil
		ns.Play(ns.SND.close)
		b.why = why2
		self:PaintAppraise(d)
		return
	end
	GameTooltip:Hide()
	local rank = CR.RANKS[desc.tier] or CR.RANKS[1]
	XU:Begin({ card = desc, grade = tonumber(res.g) or 1, marks = E.DecodeMarks(res.m), cert = tonumber(res.ce), id = res.i,
		name = CD.Name(desc), label = CD.Label(desc, res), glow = rank.color })
	XU.busy = nil
end

-------------------------------------------------------------------------------
-- Pin to showcase, Show in the chat, its copies to exchange (UI/CaseShow.lua, UI/Contract.lua)
-------------------------------------------------------------------------------
function CD:PaintPin(d, note)
	local desc = d.caseShown
	if not desc then
		return
	end
	local C = ns.Collection
	local pinned = C.PinnedCase and C:PinnedCase(desc) or nil
	d.pin:SetLabel(pinned and L["Remove from showcase"] or L["Pin to showcase"])
	d.pinNote:SetText(note or (pinned and L["In your showcase"]) or "")
end

function CD:TogglePin(d)
	local desc = d.caseShown
	local C = ns.Collection
	if not (desc and C.PinCase) then
		return
	end
	if C:PinnedCase(desc) then
		C:UnpinCase(desc)
		ns.Play(ns.SND.page)
		return self:PaintPin(d)
	end
	local ok, why = C:PinCase(desc)
	if ok then
		ns.Play(ns.SND.cardLand)
		return self:PaintPin(d)
	end
	ns.Play(ns.SND.close)
	self:PaintPin(d, why == "full" and L["Your showcase is full: remove a card from it first."] or nil)
end

function CD:Link(d)
	local desc = d.caseShown
	local w = desc and self:Selected(desc)
	if w and ns.Links and ns.Links.InsertCase then
		ns.Links:InsertCase(w)
	end
end

function CD:Trade(d)
	local desc = d.caseShown
	if desc and A.CaseContractFor then
		A:HideDetail()
		A:CaseContractFor(desc)
	end
end

-------------------------------------------------------------------------------
-- The detail as it was, for the cards of the boosters; the pieces it shares, for the card shown
-------------------------------------------------------------------------------
do
	-- (installed after every other file that wraps them: the card of a case leaves first, its own pieces after)
	local showDetail = A.ShowDetail
	function A:ShowDetail(...)
		CD:Leave(self.detail)
		return showDetail(self, unpack(arg, 1, arg.n))
	end

	local paintAppraise = A.PaintAppraise
	function A:PaintAppraise(...)
		local d = self.detail
		if d and d.caseShown then
			return CD:PaintAppraise(d)
		end
		return paintAppraise(self, unpack(arg, 1, arg.n))
	end

	local appraiseClick = A.AppraiseClick
	function A:AppraiseClick(...)
		local d = self.detail
		if d and d.caseShown then
			return CD:AppraiseClick(d)
		end
		return appraiseClick(self, unpack(arg, 1, arg.n))
	end

	local appraiseTooltip = A.AppraiseTooltip
	function A:AppraiseTooltip(b, ...)
		local d = self.detail
		if d and d.caseShown then
			return CD:AppraiseTooltip(d, b)
		end
		return appraiseTooltip(self, b, unpack(arg, 1, arg.n))
	end

	local togglePin = A.TogglePin
	function A:TogglePin(...)
		local d = self.detail
		if d and d.caseShown then
			return CD:TogglePin(d)
		end
		return togglePin(self, unpack(arg, 1, arg.n))
	end

	local paintPin = A.PaintPin
	function A:PaintPin(...)
		local d = self.detail
		if d and d.caseShown then
			return CD:PaintPin(d, unpack(arg, 1, arg.n))
		end
		return paintPin(self, unpack(arg, 1, arg.n))
	end
end

-- (the end of an appraisal: the card in its case, what the panel says; a copy won, gone, appraised: the panel again)
function CD:Repaint(how)
	local d = A.detail
	if not (d and d:IsShown() and d.caseShown) then
		return
	end
	local XU = ns.ExpertiseUI
	if XU and (XU.cer or XU.busy) then
		return
	end
	-- (1 November: the scene of the enchanter shows what changed itself, at its end: UI/Restore.lua)
	local RU = ns.RestoreUI
	if RU and (RU.cer or RU.busy or RU.fading) then
		return
	end
	local w = self:Selected(d.caseShown)
	if not w then
		-- (its last copy gone: a contract, a trade)
		return A:HideDetail()
	end
	self:PaintCard(d, how)
	self:PaintPanel(d)
end

ns.On("CASES_CHANGED", function()
	CD:Repaint()
end)
ns.On("SHOWCASE_CHANGED", function()
	local d = A.detail
	if d and d:IsShown() and d.caseShown then
		CD:PaintPin(d)
	end
end)
