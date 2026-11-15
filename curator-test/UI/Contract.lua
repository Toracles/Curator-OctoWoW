local octoConstants = {}
local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
octoConstants.MEDIA = ns.MEDIA
local C = ns.Collection
local K = ns.Contract
local A = ns.Album
local B = ns.Booster
local Ease = ns.Ease
local S = ns.Skin
local Hud = ns.Hud

-- The exchange contract: a page of the album to write it, then a scene of its own in the booster's frame: the
-- parchment unrolls, the cards melt into it, the seal strikes, a fire of gold eats it, the new cards rise out of it,
-- face down. The rarer the card promised, the darker and the more charged.
-- (1.13.0, after its second test: the page redone from the ground up, the desk of a notary. On the left, the ladder of
-- the exchanges, from the commons at its foot to the epic cards, the mythic card at its top out of reach (it is earned:
-- Contract.lua, K.TOP); under it the finishes, the copy kept of each card, the register of the last contracts. In the
-- middle, on the blotter, the deed: its places in a ring around the card it promises, face down, sealed when the deed
-- is full; under the ring, where the new card comes from, the clause of the collection (every copy from one album: a
-- card that album is missing), how many contracts at once, Sign and its quill. On the right, the drawer of the copies to
-- spare, a line a card: its name, its album, its copies; the albums they are taken from, their order, Fill and Clear.)

-- the page: the whole body of the album (the arrows of its pages hidden: the drawer has its own)
octoConstants.PAGE_W = 736
-- the ladder of the exchanges, on the left: its rungs, the medallion of each
octoConstants.LAD_W, octoConstants.RUNG_H, octoConstants.RUNG_GAP, octoConstants.MED = 158, 62, 6, 38
octoConstants.RUNGS = K.LAST + 1           -- the exchanges, and the mythic card above them, out of reach
octoConstants.FIN_Y, octoConstants.FIN_H = -346, 22      -- the finishes under it
octoConstants.KEEP_Y = -428
octoConstants.REG_Y = -478
-- the deed, in the middle, on the blotter of the desk (its parchment: 80/512 to 432/512 of ContractDeed)
octoConstants.DEED_X, octoConstants.DEED_Y, octoConstants.DEED_W, octoConstants.DEED_H = 172, -4, 362, 532
octoConstants.DEED_U0, octoConstants.DEED_U1 = 80 / 512, 432 / 512
-- the ring of its places: its centre on the deed, its radius, a place
octoConstants.RING_X, octoConstants.RING_Y, octoConstants.RING_R = octoConstants.DEED_W / 2, -230, 109
octoConstants.SLOT_W, octoConstants.SLOT_H = 37, 52
octoConstants.SLOTS = 10
octoConstants.BACK_W, octoConstants.BACK_H = 50, 70
-- under the ring: where the new card comes from, the clause, the talents and its button, how many at once and Sign
octoConstants.FROM_Y, octoConstants.CLAUSE_Y, octoConstants.ACTS_Y, octoConstants.SIGN_Y = -369, -405, -452, -476
-- the lights of the copies given, in a ring around the card it promises
octoConstants.DOT_R, octoConstants.DOTS = 54, 10
octoConstants.TEXT_X, octoConstants.TEXT_W = 30, octoConstants.DEED_W - 60
-- the drawer of the copies to spare, on the right: its rows
octoConstants.DRAW_X, octoConstants.DRAW_W = 548, 188
octoConstants.ROW_H, octoConstants.ROWS, octoConstants.ROWS_Y = 37, 10, -84
-- the register of the contracts, over the drawer
-- (each line: its date, its deal, two lines of the cards it gave)
octoConstants.REG_ROWS, octoConstants.REG_ROW_H = 8, 66
octoConstants.INK = { 0.30, 0.18, 0.08 }
octoConstants.INK_SOFT = { 0.45, 0.30, 0.15 }
octoConstants.GOLDEN = { 1, 0.8, 0.32 }
octoConstants.DIM = { 0.55, 0.55, 0.58 }
octoConstants.GREEN = { 0.16, 0.42, 0.12 }
octoConstants.TEX_R = 366 / 512
octoConstants.CARD_FLY = { coords = { 0, octoConstants.TEX_R, 0, 1 }, ratio = 157 / 112 }
octoConstants.FINISH_LABEL = { normal = "Normal cards", shiny = "Thunderforged cards", holo = "Titanforged cards" }
octoConstants.FINISH_NAME = { shiny = "Thunderforged", holo = "Titanforged" }
octoConstants.FINISH_TINT = { shiny = { 0.62, 0.84, 1 }, holo = { 1, 0.84, 0.5 } }
octoConstants.FINISH_ICON = {
	normal = { "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" },
	shiny = { "Interface\\Icons\\Spell_Nature_Lightning" },
	holo = { "Interface\\Icons\\INV_Enchant_ShardPrismaticLarge" },
}
-- the orders of the drawer
octoConstants.SORTS = {
	{ key = "count", label = "Copies", tip = "The cards with the most copies to spare first." },
	{ key = "album", label = "Albums", tip = "Album by album, in the order of the list of the albums." },
	{ key = "name", label = "Names", tip = "In the order of their names." },
}
-- (a line of the drawer in the contract: its bar of gold, under the mouse a little brighter)
octoConstants.PICKED, octoConstants.HOVER = 0.75, 0.95

local function Finish(ct)
	return ct.finish ~= "normal" and ct.finish or nil
end

-- "10 × Commune  »  1 × Peu commune", in the colours of the rarities (the fonts of the game have
-- no arrow); n contracts: their copies and their cards. ink: written on the parchment (the inks of
-- the rarities). (1.6.0) size: the cards a contract takes, up: the rarity it gives (the talents of
-- the Merchant change them).
local function Deal(rarity, n, ink, size, up)
	n = n or 1
	local a, b = ns.RARITY[rarity], ns.RARITY[math.min(CuratorOctoFull.Length(ns.RARITY), up or (rarity + 1))]
	local hex = A.U.Hex
	local ca, cb = ink and a.ink or a.text, ink and b.ink or b.text
	return string.format(("%d × |cff%s%s|r  »  %d × |cff%s%s|r"), (size or K.SIZE) * n, hex(ca), L[a.label], n, hex(cb), L[b.label])
end

-- The rarity a contract gives (two more with the Masterstroke armed; a legendary card at most).
local function Up(ct)
	return K:Up(ct)
end

-- A text made smaller (down to 8) until it fits its width.
local function Fit(fs, text, size, width)
	ns.SetFont(fs, size)
	fs:SetText(text)
	while size > 8 and ns.TextWidth(fs) > width do
		size = size - 1
		ns.SetFont(fs, size)
	end
end

-- How many contracts copies to spare make ("3 contracts"), or how many one takes when they make none ("10 needed").
local function Makes(spare, size)
	local n = math.floor((spare or 0) / math.max(1, size))
	if n <= 0 then
		return string.format(L["%d needed"], size), false
	end
	return n == 1 and L["1 contract"] or string.format(L["%d contracts"], n), true
end

-- A place of the ring, from the top, clockwise (places: how many the deed has).
local function RingXY(i, places)
	local a = math.pi / 2 - (i - 1) * 2 * math.pi / math.max(1, places)
	return octoConstants.RING_X + octoConstants.RING_R * math.cos(a), octoConstants.RING_Y + octoConstants.RING_R * math.sin(a)
end

-- (1.14.0, after its second test) What the desk of the contracts of the cards of the cases shares with it (UI/
-- CaseContract.lua: the same desk, its own ladder, its own cards).
A.CT = {
	PAGE_W = octoConstants.PAGE_W, LAD_W = octoConstants.LAD_W, RUNG_H = octoConstants.RUNG_H, RUNG_GAP = octoConstants.RUNG_GAP, MED = octoConstants.MED, KEEP_Y = octoConstants.KEEP_Y, FIN_Y = octoConstants.FIN_Y,
	DEED_W = octoConstants.DEED_W, RING_X = octoConstants.RING_X, RING_Y = octoConstants.RING_Y, SLOT_W = octoConstants.SLOT_W, SLOT_H = octoConstants.SLOT_H, SLOTS = octoConstants.SLOTS,
	BACK_W = octoConstants.BACK_W, BACK_H = octoConstants.BACK_H, DOT_R = octoConstants.DOT_R, DOTS = octoConstants.DOTS, TEXT_X = octoConstants.TEXT_X, TEXT_W = octoConstants.TEXT_W,
	FROM_Y = octoConstants.FROM_Y, CLAUSE_Y = octoConstants.CLAUSE_Y, ACTS_Y = octoConstants.ACTS_Y, SIGN_Y = octoConstants.SIGN_Y,
	DRAW_W = octoConstants.DRAW_W, ROW_H = octoConstants.ROW_H, ROWS = octoConstants.ROWS, ROWS_Y = octoConstants.ROWS_Y, TEX_R = octoConstants.TEX_R, CARD_FLY = octoConstants.CARD_FLY,
	INK = octoConstants.INK, INK_SOFT = octoConstants.INK_SOFT, GOLDEN = octoConstants.GOLDEN, DIM = octoConstants.DIM, GREEN = octoConstants.GREEN, PICKED = octoConstants.PICKED, HOVER = octoConstants.HOVER,
	Fit = Fit, Makes = Makes, RingXY = RingXY,
}

-------------------------------------------------------------------------------
-- The page of the album
-------------------------------------------------------------------------------
function A:Contract()
	if not self.ct then
		-- the lowest rarity with enough copies to spare for a contract, else the commons
		local spare = K:SpareByRarity("normal", ns.db.keepOne)
		local r = 1
		for i = 1, K.LAST do
			if spare[i] >= K:SizeOf(i, "normal") then
				r = i
				break
			end
		end
		self.ct = K:New(r, "normal")
	end
	return self.ct
end

-- A rung of the ladder: its medallion (the gem of the card it gives, the gem of the copies it takes, the copies to
-- spare on a chip), what it takes, what it gives, the contracts its copies make and how far the next one is. The last
-- one, at the top: the mythic card, out of reach, its padlock. Lit when chosen.
local function NewRung(page, r)
	local locked = r > K.LAST
	local from, to = ns.RARITY[r], ns.RARITY[math.min(CuratorOctoFull.Length(ns.RARITY), r + 1)]
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, octoConstants.LAD_W, octoConstants.RUNG_H)
	b:SetPoint("TOPLEFT", 0, -2 - (octoConstants.RUNGS - r) * (octoConstants.RUNG_H + octoConstants.RUNG_GAP))
	Hud.Panel(b, octoConstants.RUNG_H)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 4, -4)
	b.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.07)
	local mx = 8 + octoConstants.MED / 2
	-- (the light of the rarity it gives, behind the medallion: it breathes when chosen)
	b.light = b:CreateTexture(nil, "BORDER", nil, 2)
	b.light:SetTexture(octoConstants.MEDIA .. "Glow")
	b.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.light, octoConstants.MED * 2, octoConstants.MED * 2)
	b.light:SetPoint("CENTER", b, "LEFT", mx, 0)
	b.light:SetVertexColor(to.glow[1], to.glow[2], to.glow[3])
	b.light:SetAlpha(0)
	b.node = b:CreateTexture(nil, "ARTWORK")
	b.node:SetTexture(octoConstants.MEDIA .. "TrackNodeBig")
	CuratorOctoFull.SetSize(b.node, octoConstants.MED, octoConstants.MED)
	b.node:SetPoint("CENTER", b, "LEFT", mx, 0)
	b.gemTo = b:CreateTexture(nil, "ARTWORK", nil, 2)
	b.gemTo:SetTexture(octoConstants.MEDIA .. "Gem" .. math.min(CuratorOctoFull.Length(ns.RARITY), r + 1))
	CuratorOctoFull.SetSize(b.gemTo, 18, 18)
	b.gemTo:SetPoint("CENTER", b.node, "CENTER")
	b.gemFrom = b:CreateTexture(nil, "ARTWORK", nil, 3)
	b.gemFrom:SetTexture(octoConstants.MEDIA .. "Gem" .. r)
	CuratorOctoFull.SetSize(b.gemFrom, 12, 12)
	b.gemFrom:SetPoint("CENTER", b.node, "BOTTOMLEFT", 6, 6)
	local tx = 8 + octoConstants.MED + 9
	local tw = octoConstants.LAD_W - tx - 6
	b.from = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.from:SetPoint("TOPLEFT", tx, -7)
	b.from:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.from, false)
	b.from:SetTextColor(from.text[1], from.text[2], from.text[3])
	Fit(b.from, L[from.label], 10, tw)
	b.to = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.to:SetPoint("TOPLEFT", b.from, "BOTTOMLEFT", 0, -1)
	b.to:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.to, false)
	b.to:SetTextColor(to.text[1], to.text[2], to.text[3])
	Fit(b.to, "» " .. L[to.label], 10, tw)
	b.makes = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.makes:SetPoint("TOPLEFT", b.to, "BOTTOMLEFT", 0, -2)
	b.makes:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.makes, false)
	b.rarity, b.tw, b.locked = r, tw, locked
	if locked then
		-- the mythic card: earned in the boosters, never exchanged
		b.node:SetDesaturated(true)
		b.node:SetVertexColor(0.6, 0.6, 0.62)
		b.gemTo:SetDesaturated(true)
		b.gemTo:SetAlpha(0.55)
		b.gemFrom:SetDesaturated(true)
		b.gemFrom:SetAlpha(0.55)
		b.lock = b:CreateTexture(nil, "OVERLAY", nil, 2)
		b.lock:SetTexture(octoConstants.MEDIA .. "Lock")
		CuratorOctoFull.SetSize(b.lock, 20, 20)
		b.lock:SetPoint("CENTER", b.node, "TOPRIGHT", -2, -4)
		b.from:SetAlpha(0.65)
		b.to:SetAlpha(0.65)
		Fit(b.makes, L["Must be earned"], 10, tw)
		b.makes:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
	else
		-- the copies to spare, on a dark chip at the top right of the medallion
		b.chip = b:CreateTexture(nil, "OVERLAY")
		b.chip:SetTexture(octoConstants.MEDIA .. "CircleMask")
		b.chip:SetVertexColor(0.03, 0.03, 0.05)
		b.chip:SetAlpha(0.92)
		CuratorOctoFull.SetSize(b.chip, 24, 17)
		b.chip:SetPoint("CENTER", b.node, "TOPRIGHT", 1, -4)
		b.count = Hud.Text(b, 10, "OUTLINE", "OVERLAY", 2)
		b.count:SetPoint("CENTER", b.chip, "CENTER", 0, 0)
		-- how far the next contract is (its copies to spare past those of the contracts they already make)
		b.bar = Hud.XPBar(b, tw, 6, { 1, 0.74, 0.22 })
		b.bar:SetPoint("TOPLEFT", b.makes, "BOTTOMLEFT", 0, -3)
		b.bar.text:SetText("")
	end
	function b:SetSelected(on)
		self.on = on
		if not self.locked then
			self.node:SetVertexColor(on and 1 or 0.72, on and 1 or 0.72, on and 1 or 0.72)
			self.gemTo:SetAlpha(on and 1 or 0.8)
		end
		Hud.Each(self.glow, "SetAlpha", on and 0.85 or 0)
		if not on then
			self.light:SetAlpha(0)
		end
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:SetContractRarity(r)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:RungTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end

-- A finish: a dark button, its icon, its name and its copies to spare; lit in gold when chosen.
local function NewToggle(page, finish)
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, octoConstants.LAD_W, octoConstants.FIN_H)
	Hud.Panel(b, octoConstants.FIN_H)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 3, -3)
	b.hl:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.08)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, octoConstants.FIN_H - 6, octoConstants.FIN_H - 6)
	b.icon:SetPoint("LEFT", 5, 0)
	Hud.SetIcon(b.icon, octoConstants.FINISH_ICON[finish])
	b.text = S.Text(b, "GameFontNormalSmall", "LEFT")
	b.text:SetPoint("LEFT", octoConstants.FIN_H + 2, 0)
	b.text:SetPoint("RIGHT", -4, 0)
	CuratorOctoFull.SetWordWrap(b.text, false)
	function b:SetChecked(on)
		self.on = on
		Hud.Each(self.glow, "SetAlpha", on and 0.8 or 0)
		local c = on and { 1, 1, 1 } or S.GOLD
		self.text:SetTextColor(c[1], c[2], c[3])
	end
	function b:GetChecked()
		return self.on
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:SetContractFinish(finish)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L[octoConstants.FINISH_LABEL[finish]], 1, 1, 1)
		GameTooltip:AddLine(L["Thunderforged and titanforged cards only go with cards of their own finish, and give a card of that finish."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end

-- A place of the ring: a card in it (a copy, or several of the same card), else its frame of gold and a cross.
local function NewSlot(deed, i)
	local U = A.U
	local sl = CreateFrame("Button", nil, deed)
	CuratorOctoFull.SetSize(sl, octoConstants.SLOT_W, octoConstants.SLOT_H)
	sl:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	sl.bg = sl:CreateTexture(nil, "BACKGROUND")
	sl.bg:SetTexture(octoConstants.MEDIA .. "ContractSlot")
	sl.bg:SetPoint("TOPLEFT", -3, 3)
	sl.bg:SetPoint("BOTTOMRIGHT", 3, -3)
	sl.plus = U.Text(sl, 17, "")
	sl.plus:SetPoint("CENTER", 0, 1)
	sl.plus:SetText("+")
	sl.plus:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3], 0.6)
	sl.plus:SetShadowOffset(0, 0)
	local c = ns.NewCard(sl, "small")
	c:SetScale(octoConstants.SLOT_W / U.CW)
	c:SetPoint("CENTER", sl, "CENTER", 0, 0)
	c:EnableMouse(false)
	c.shadow:SetAlpha(0.5)
	c:Hide()
	sl.card = c
	-- the copies of the same card, or the cards beyond the tenth place
	local top = CreateFrame("Frame", nil, sl)
	top:SetAllPoints()
	top:SetFrameLevel(c:GetFrameLevel() + 12)
	sl.n = Hud.Text(top, 11, "OUTLINE", "OVERLAY")
	sl.n:SetPoint("BOTTOMRIGHT", 3, -3)
	sl.n:SetTextColor(1, 0.92, 0.7)
	sl.more = Hud.Text(top, 13, "OUTLINE", "OVERLAY")
	sl.more:SetPoint("CENTER", 0, 0)
	sl.more:SetTextColor(1, 0.92, 0.7)
	CuratorOctoFull.SetScript(sl, "OnClick", function(self, button)
		-- (1.13.0: a right click, the copies of that card that go into it: Copies.lua)
		if button == "RightButton" and self.group and self.group.card and not self.rest then
			A:ChooseContractCopies(self)
			return
		end
		A:TakeContract(i)
	end)
	CuratorOctoFull.SetScript(sl, "OnEnter", function(self)
		A:SlotContractTooltip(self, i)
	end)
	CuratorOctoFull.SetScript(sl, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return sl
end

-- (1.6.0) A talent of the Merchant for the next contract (it changes what comes): lit when armed.
local function NewActive(parent, key)
	local id = K.ACTIVES[key]
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, 26, 26)
	b.light = b:CreateTexture(nil, "BACKGROUND")
	b.light:SetTexture(octoConstants.MEDIA .. "Glow")
	b.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.light, 56, 56)
	b.light:SetPoint("CENTER")
	b.light:SetVertexColor(1, 0.78, 0.3)
	b.light:SetAlpha(0)
	b.icon = Hud.RoundIcon(b, 19, "ARTWORK")
	b.icon:SetPoint("CENTER")
	Hud.SetIcon(b.icon, { ns.Talents and ns.Talents.BY[id].icon or "Interface\\Icons\\INV_Misc_QuestionMark" })
	b.ring = b:CreateTexture(nil, "OVERLAY")
	b.ring:SetTexture(octoConstants.MEDIA .. "IconRing")
	b.ring:SetAllPoints()
	b.key, b.id = key, id
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		A:ContractActive(self)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:ContractActiveTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	return b
end

-- A line of the drawer: a card with copies to spare, small, its name and its album, the copies left to give; a bar of
-- gold on its left while some of its copies are in the contract.
local function NewRow(dr, i)
	local U = A.U
	local row = CreateFrame("Button", nil, dr)
	CuratorOctoFull.SetSize(row, octoConstants.DRAW_W - 12, octoConstants.ROW_H - 3)
	row:SetPoint("TOPLEFT", 6, octoConstants.ROWS_Y - (i - 1) * octoConstants.ROW_H)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(row.bg, 1, 1, 1, (CuratorOctoFull.Mod(i , 2) == 0) and 0.035 or 0.015)
	row.hl = row:CreateTexture(nil, "HIGHLIGHT")
	row.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(row.hl, 1, 0.86, 0.5, 0.1)
	row.mark = row:CreateTexture(nil, "ARTWORK", nil, 2)
	row.mark:SetPoint("TOPLEFT", 0, 0)
	row.mark:SetPoint("BOTTOMLEFT", 0, 0)
	row.mark:SetWidth(3)
	CuratorOctoFull.ColorTexture(row.mark, 1, 0.8, 0.3, 1)
	row.mark:SetAlpha(0)
	row.glow = row:CreateTexture(nil, "BORDER")
	row.glow:SetAllPoints()
	CuratorOctoFull.ColorTexture(row.glow, 1, 0.8, 0.3, 0.1)
	row.glow:SetAlpha(0)
	local h = octoConstants.ROW_H - 6
	local c = ns.NewCard(row, "small")
	c:SetScale(h / U.CH)
	c:SetPoint("LEFT", row, "LEFT", 6 * U.CH / h, 0)
	c:EnableMouse(false)
	c.shadow:SetAlpha(0.4)
	c:Hide()
	row.card = c
	local tx = 8 + h * U.CW / U.CH + 6
	row.name = S.Text(row, "GameFontHighlightSmall", "LEFT")
	row.name:SetPoint("TOPLEFT", tx, -4)
	row.name:SetWidth(octoConstants.DRAW_W - 12 - tx - 40)
	CuratorOctoFull.SetWordWrap(row.name, false)
	row.album = S.Text(row, "GameFontDisableSmall", "LEFT")
	row.album:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
	row.album:SetWidth(octoConstants.DRAW_W - 12 - tx - 40)
	CuratorOctoFull.SetWordWrap(row.album, false)
	row.left = Hud.Text(row, 13, "OUTLINE")
	row.left:SetPoint("RIGHT", row, "RIGHT", -5, 3)
	row.left:SetTextColor(1, 0.92, 0.75)
	row.used = Hud.Text(row, 9, "OUTLINE")
	row.used:SetPoint("TOPRIGHT", row.left, "BOTTOMRIGHT", 0, -1)
	row.used:SetTextColor(1, 0.8, 0.3)
	CuratorOctoFull.SetScript(row, "OnClick", function(self, button)
		A:ContractRowClick(self, button)
	end)
	CuratorOctoFull.SetScript(row, "OnEnter", function(self)
		A:ContractRowTooltip(self)
	end)
	CuratorOctoFull.SetScript(row, "OnLeave", function(self)
		GameTooltip:Hide()
		A:PaintRow(self)
	end)
	row:Hide()
	return row
end

-- A line of the register: when, what was given, what came of it.
local function NewRegLine(reg, i)
	local l = CreateFrame("Frame", nil, reg)
	CuratorOctoFull.SetSize(l, octoConstants.DRAW_W - 16, octoConstants.REG_ROW_H - 4)
	l:SetPoint("TOPLEFT", 8, -34 - (i - 1) * octoConstants.REG_ROW_H)
	l.bg = l:CreateTexture(nil, "BACKGROUND")
	l.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(l.bg, 1, 1, 1, (CuratorOctoFull.Mod(i , 2) == 0) and 0.035 or 0.015)
	l.head = S.Text(l, "GameFontDisableSmall", "LEFT")
	l.head:SetPoint("TOPLEFT", 4, -3)
	l.head:SetWidth(octoConstants.DRAW_W - 24)
	CuratorOctoFull.SetWordWrap(l.head, false)
	l.what = S.Text(l, "GameFontHighlightSmall", "LEFT")
	l.what:SetPoint("TOPLEFT", l.head, "BOTTOMLEFT", 0, -2)
	l.what:SetWidth(octoConstants.DRAW_W - 24)
	CuratorOctoFull.SetWordWrap(l.what, false)
	l.cards = S.Text(l, "GameFontHighlightSmall", "LEFT")
	l.cards:SetPoint("TOPLEFT", l.what, "BOTTOMLEFT", 0, -2)
	l.cards:SetWidth(octoConstants.DRAW_W - 24)
	CuratorOctoFull.SetWordWrap(l.cards, true)
	if l.cards.SetMaxLines then
		CuratorOctoFull.SetMaxLines(l.cards, 2)
	end
	l:Hide()
	return l
end

function A:BuildContract()
	local f = self.frame
	if f.ct then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 6)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.ct = page

	-- the desk of the notary: its wood, its blotter of leather under the deed
	page.desk = page:CreateTexture(nil, "BACKGROUND", nil, -6)
	page.desk:SetTexture(octoConstants.MEDIA .. "ContractDesk")
	page.desk:SetPoint("TOPLEFT", -4, 2)
	page.desk:SetPoint("BOTTOMRIGHT", 4, -2)

	-- the ladder: a rail of gold through the medallions, the rungs, from the commons at its foot to the mythic card
	page.rail = page:CreateTexture(nil, "BACKGROUND", nil, 1)
	CuratorOctoFull.ColorTexture(page.rail, 1, 0.78, 0.32, 0.4)
	page.rail:SetWidth(2)
	page.rail:SetPoint("TOP", page, "TOPLEFT", 8 + octoConstants.MED / 2, -2 - octoConstants.RUNG_H / 2)
	page.rail:SetPoint("BOTTOM", page, "TOPLEFT", 8 + octoConstants.MED / 2, -2 - (octoConstants.RUNGS - 1) * (octoConstants.RUNG_H + octoConstants.RUNG_GAP) - octoConstants.RUNG_H / 2)
	page.rungs = {}
	for r = 1, octoConstants.RUNGS do
		page.rungs[r] = NewRung(page, r)
	end
	-- (the tiles of before: the same buttons, for those who look for them by that name)
	page.rec = page.rungs

	-- the finishes, under it: copies only go with copies of their own finish
	page.fin = {}
	for k, finish in ipairs(K.FINISHES) do
		local b = NewToggle(page, finish)
		b:SetPoint("TOPLEFT", 0, octoConstants.FIN_Y - (k - 1) * (octoConstants.FIN_H + 4))
		page.fin[finish] = b
	end
	-- keep one copy of each card in the album (a check box of the game)
	local keep = S.Check(page, L["Keep one copy of each card"])
	keep:SetPoint("TOPLEFT", 0, octoConstants.KEEP_Y)
	keep.Text:SetWidth(octoConstants.LAD_W - 30)
	CuratorOctoFull.SetWordWrap(keep.Text, true)
	CuratorOctoFull.SetScript(keep, "OnClick", function()
		ns.db.keepOne = not ns.db.keepOne
		K:Check(A:Contract(), ns.db.keepOne)
		ns.Play(ns.SND.click)
		A:Refresh()
	end)
	CuratorOctoFull.SetScript(keep, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Keep one copy of each card"], 1, 1, 1)
		GameTooltip:AddLine(L["The album keeps the finest copy of each card (titanforged, then thunderforged); only the others go into contracts."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(keep, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.keep = keep
	-- the register of the last contracts signed
	page.regButton = S.Button(page, L["The register"], octoConstants.LAD_W, 24)
	page.regButton:SetPoint("TOPLEFT", 0, octoConstants.REG_Y)
	CuratorOctoFull.SetScript(page.regButton, "OnClick", function()
		A:ToggleRegister()
	end)
	CuratorOctoFull.SetScript(page.regButton, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["The register"], 1, 1, 1)
		GameTooltip:AddLine(L["The last contracts you signed, and what came of them."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(page.regButton, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.regIcon = page.regButton:CreateTexture(nil, "OVERLAY")
	CuratorOctoFull.SetSize(page.regIcon, 16, 16)
	page.regIcon:SetPoint("LEFT", 8, 0)
	Hud.SetIcon(page.regIcon, { "Interface\\Icons\\INV_Misc_Book_09" })

	-- the deed, on the blotter: its shadow, its parchment, its head
	local deed = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(deed, octoConstants.DEED_W, octoConstants.DEED_H)
	deed:SetPoint("TOPLEFT", octoConstants.DEED_X, octoConstants.DEED_Y)
	deed.shadow = deed:CreateTexture(nil, "BACKGROUND", nil, -2)
	CuratorOctoFull.ColorTexture(deed.shadow, 0, 0, 0, 0.42)
	deed.shadow:SetPoint("TOPLEFT", 5, -7)
	deed.shadow:SetPoint("BOTTOMRIGHT", 7, -9)
	deed.glow = deed:CreateTexture(nil, "BACKGROUND", nil, -1)
	deed.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.glow:SetBlendMode("ADD")
	deed.glow:SetPoint("TOPLEFT", -60, 50)
	deed.glow:SetPoint("BOTTOMRIGHT", 60, -50)
	deed.glow:SetVertexColor(1, 0.8, 0.4)
	deed.glow:SetAlpha(0)
	deed.paper = deed:CreateTexture(nil, "BORDER")
	deed.paper:SetTexture(octoConstants.MEDIA .. "ContractDeed")
	deed.paper:SetTexCoord(octoConstants.DEED_U0, octoConstants.DEED_U1, 0, 1)
	deed.paper:SetAllPoints()
	deed.title = U.Text(deed, 16, "")
	deed.title:SetPoint("TOP", 0, -26)
	deed.title:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.title:SetShadowOffset(0, 0)
	deed.deal = U.Text(deed, 12, "")
	deed.deal:SetPoint("TOP", deed.title, "BOTTOM", 0, -4)
	deed.deal:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.deal:SetShadowOffset(0, 0)
	-- in the middle of the ring: the card it promises, face down, its light, the ring of the copies given, how many
	deed.backGlow = deed:CreateTexture(nil, "ARTWORK", nil, -2)
	deed.backGlow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.backGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(deed.backGlow, 150, 150)
	deed.backGlow:SetPoint("CENTER", deed, "TOPLEFT", octoConstants.RING_X, octoConstants.RING_Y)
	deed.backGlow:SetAlpha(0.35)
	-- (the ring of gold, once the deed is full; before, a light for each copy given)
	deed.ring = Hud.Ring(deed, 128, "ARTWORK", -1)
	deed.ring:SetPoint("CENTER", deed, "TOPLEFT", octoConstants.RING_X, octoConstants.RING_Y + 4)
	deed.ring:SetProgress(1)
	deed.ring:SetAlpha(0)
	deed.dots = {}
	for i = 1, octoConstants.DOTS do
		local a = math.pi / 2 - (i - 1) * 2 * math.pi / octoConstants.DOTS
		local x, y = octoConstants.RING_X + octoConstants.DOT_R * math.cos(a), octoConstants.RING_Y + 4 + octoConstants.DOT_R * math.sin(a)
		local glow = deed:CreateTexture(nil, "ARTWORK", nil, -1)
		glow:SetTexture(octoConstants.MEDIA .. "Glow")
		glow:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(glow, 26, 26)
		glow:SetPoint("CENTER", deed, "TOPLEFT", x, y)
		glow:SetVertexColor(1, 0.75, 0.3)
		glow:SetAlpha(0)
		local d = deed:CreateTexture(nil, "ARTWORK", nil, 0)
		d:SetTexture(octoConstants.MEDIA .. "Dot")
		CuratorOctoFull.SetSize(d, 10, 10)
		d:SetPoint("CENTER", deed, "TOPLEFT", x, y)
		d.glow = glow
		deed.dots[i] = d
	end
	deed.back = deed:CreateTexture(nil, "ARTWORK", nil, 1)
	deed.back:SetTexture(octoConstants.MEDIA .. "Back_S")
	deed.back:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	CuratorOctoFull.SetSize(deed.back, octoConstants.BACK_W, octoConstants.BACK_H)
	deed.back:SetPoint("CENTER", deed, "TOPLEFT", octoConstants.RING_X, octoConstants.RING_Y + 4)
	deed.gem = deed:CreateTexture(nil, "ARTWORK", nil, 2)
	CuratorOctoFull.SetSize(deed.gem, 20, 20)
	deed.gem:SetPoint("CENTER", deed.back, "CENTER", 0, 0)
	deed.count = A.U.Text(deed, 11, "")
	deed.count:SetPoint("CENTER", deed, "TOPLEFT", octoConstants.RING_X, octoConstants.RING_Y - octoConstants.DOT_R - 12)
	deed.count:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.count:SetShadowOffset(0, 0)
	-- the seal that comes down on the card when the deed is full
	deed.stamp = deed:CreateTexture(nil, "OVERLAY", nil, 3)
	deed.stamp:SetTexture(octoConstants.MEDIA .. "Seal")
	CuratorOctoFull.SetSize(deed.stamp, 46, 46)
	deed.stamp:SetPoint("CENTER", deed.back, "CENTER", 0, -2)
	deed.stamp:Hide()
	deed.stampGlow = deed:CreateTexture(nil, "OVERLAY", nil, 2)
	deed.stampGlow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.stampGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(deed.stampGlow, 110, 110)
	deed.stampGlow:SetPoint("CENTER", deed.stamp, "CENTER")
	deed.stampGlow:SetVertexColor(1, 0.5, 0.4)
	deed.stampGlow:SetAlpha(0)
	-- the places, in a ring
	deed.slots = {}
	for i = 1, octoConstants.SLOTS do
		deed.slots[i] = NewSlot(deed, i)
	end
	-- where the new card comes from
	deed.from = S.Text(deed, "GameFontHighlightSmall", "CENTER")
	deed.from:SetPoint("TOP", deed, "TOP", 0, octoConstants.FROM_Y)
	deed.from:SetWidth(octoConstants.TEXT_W)
	CuratorOctoFull.SetWordWrap(deed.from, true)
	deed.from:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.from:SetShadowOffset(0, 0)
	-- the clause of the collection: its seal, what it says, the button that fills the contract for it
	deed.clauseIcon = deed:CreateTexture(nil, "ARTWORK")
	deed.clauseIcon:SetTexture(octoConstants.MEDIA .. "Seal")
	CuratorOctoFull.SetSize(deed.clauseIcon, 18, 18)
	deed.clauseIcon:SetPoint("TOPLEFT", octoConstants.TEXT_X, octoConstants.CLAUSE_Y + 2)
	deed.clause = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.clause:SetPoint("TOPLEFT", octoConstants.TEXT_X + 22, octoConstants.CLAUSE_Y)
	deed.clause:SetWidth(octoConstants.TEXT_W - 22)
	CuratorOctoFull.SetWordWrap(deed.clause, true)
	deed.clause:SetShadowOffset(0, 0)
	-- (31 October, the contracts redone: the clause of the condition: what comes is in the condition of what is given)
	deed.cond = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.cond:SetPoint("TOPLEFT", deed.clause, "BOTTOMLEFT", 0, -3)
	deed.cond:SetWidth(octoConstants.TEXT_W - 22)
	CuratorOctoFull.SetWordWrap(deed.cond, true)
	deed.cond:SetShadowOffset(0, 0)
	deed.clauseBtn = S.Button(deed, L["Fill for the clause"], 150, 20)
	deed.clauseBtn:SetPoint("TOPRIGHT", deed, "TOPRIGHT", -octoConstants.TEXT_X, octoConstants.ACTS_Y)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnClick", function()
		A:FillForClause()
	end)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnEnter", function(self)
		A:ClauseTooltip(self)
	end)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- (1.6.0) the talents of the Merchant for the next contract, on the left over the signature
	deed.acts = CreateFrame("Frame", nil, deed)
	CuratorOctoFull.SetSize(deed.acts, 4 * 30, 26)
	deed.acts:SetPoint("TOPLEFT", octoConstants.TEXT_X, octoConstants.ACTS_Y + 3)
	deed.actButtons = {}
	-- (1.14.0: the trees of before gone, no talent of the next contract: Contract.lua, K.ACTIVES)
	for _, key in ipairs({ "favor", "master", "tailor", "alchemist" }) do
		local id = K.ACTIVES[key]
		if id and ns.Talents and ns.Talents.BY[id] then
			deed.actButtons[CuratorOctoFull.Length(deed.actButtons) + 1] = NewActive(deed.acts, key)
		end
	end
	-- the signature: how many contracts at once (one to five, the most the copies make), Sign and its quill
	local mult = CreateFrame("Frame", nil, deed)
	CuratorOctoFull.SetSize(mult, 150, 26)
	mult:SetPoint("TOPLEFT", octoConstants.TEXT_X - 6, octoConstants.SIGN_Y - 4)
	mult.prev = S.Arrow(mult, -1, 22)
	mult.prev:SetPoint("LEFT", 0, 0)
	CuratorOctoFull.SetScript(mult.prev, "OnClick", function()
		A:SetContractCount(A:Contract().n - 1)
	end)
	mult.text = U.Text(mult, 15, "")
	mult.text:SetPoint("LEFT", mult.prev, "RIGHT", 4, 0)
	mult.text:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	mult.text:SetShadowOffset(0, 0)
	mult.next = S.Arrow(mult, 1, 22)
	mult.next:SetPoint("LEFT", mult.text, "RIGHT", 4, 0)
	CuratorOctoFull.SetScript(mult.next, "OnClick", function()
		A:SetContractCount(A:Contract().n + 1)
	end)
	mult.max = S.Button(mult, L["Max"], 50, 20)
	mult.max:SetPoint("LEFT", mult.next, "RIGHT", 4, 0)
	CuratorOctoFull.SetScript(mult.max, "OnClick", function()
		A:ContractMax()
	end)
	CuratorOctoFull.SetScript(mult.max, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Max"], 1, 1, 1)
		GameTooltip:AddLine(K:Max() == K.MAX and L["As many contracts as your copies to spare make (five at most), filled at once."]
			or string.format(L["As many contracts as your copies to spare make (%d at most), filled at once."], K:Max()), 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(mult.max, "OnLeave", function()
		GameTooltip:Hide()
	end)
	deed.mult = mult
	page.sign = Hud.ClaimButton(deed, 162, 32, L["Sign the contract"])
	page.sign:SetPoint("TOPRIGHT", deed, "TOPRIGHT", -octoConstants.TEXT_X + 6, octoConstants.SIGN_Y - 1)
	page.sign.label = page.sign.text
	CuratorOctoFull.SetScript(page.sign, "OnClick", function()
		A:SignContract()
	end)
	-- (1.14.0, after its test, his word: off on a reroll, why in its tooltip; Reroll.lua: RR:Blocks)
	page.sign.tip = function(self)
		if ns.Reroll and ns.Reroll:Blocks("contracts") then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Sign the contract"], 1, 1, 1)
			GameTooltip:AddLine(ns.Reroll:WhyNot("contracts"), 1, 0.62, 0.45, true)
			GameTooltip:Show()
		end
	end
	if page.sign.SetMotionScriptsWhileDisabled then
		page.sign:SetMotionScriptsWhileDisabled(true)
	end
	page.sign.quill = page.sign:CreateTexture(nil, "OVERLAY", nil, 2)
	page.sign.quill:SetTexture(octoConstants.MEDIA .. "Quill")
	CuratorOctoFull.SetSize(page.sign.quill, 30, 30)
	page.sign.quill:SetPoint("CENTER", page.sign, "LEFT", 4, 6)
	page.band = deed
	-- (the pieces of before, under their names: the parchment, its seal; what it gives, where it comes from)
	deed.seal = deed.stamp
	page.get = deed
	page.odds = deed.from

	-- the drawer of the copies to spare
	local dr = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(dr, octoConstants.DRAW_W, 1)
	dr:SetPoint("TOPLEFT", octoConstants.DRAW_X, -2)
	dr:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", octoConstants.DRAW_X, 2)
	dr.bg = Hud.Card(dr, 0.75)
	dr.title = S.Text(dr, "GameFontNormal", "LEFT")
	dr.title:SetPoint("TOPLEFT", 10, -10)
	dr.title:SetText(L["Your copies"])
	dr.total = Hud.Text(dr, 13, "OUTLINE")
	dr.total:SetPoint("TOPRIGHT", dr, "TOPRIGHT", -10, -9)
	dr.total:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	dr.albums = S.Dropdown(dr, octoConstants.DRAW_W - 12)
	dr.albums:SetPoint("TOPLEFT", 6, -28)
	dr.albums:SetupMenu(function(_, root)
		A:ContractAlbumsMenu(root)
	end)
	dr.albums:SetTooltip(function(tooltip)
		tooltip:AddLine(L["All albums"], 1, 1, 1)
		tooltip:AddLine(L["The cards of every album, or of one only (the arrows of the title too)."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
	end)
	dr.sorts = {}
	local sw = (octoConstants.DRAW_W - 12 - 4) / CuratorOctoFull.Length(octoConstants.SORTS)
	for k, so in ipairs(octoConstants.SORTS) do
		local k, so = k, so; local b = CreateFrame("Button", nil, dr)
		CuratorOctoFull.SetSize(b, sw - 2, 20)
		b:SetPoint("TOPLEFT", 6 + (k - 1) * sw, -56)
		Hud.Panel(b, 20)
		b.text = S.Text(b, "GameFontNormalSmall", "CENTER")
		b.text:SetPoint("LEFT", 2, 0)
		b.text:SetPoint("RIGHT", -2, 0)
		CuratorOctoFull.SetWordWrap(b.text, false)
		Fit(b.text, L[so.label], 10, sw - 8)
		b.key = so.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetContractSort(so.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L[so.label], 1, 1, 1)
			GameTooltip:AddLine(L[so.tip], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		dr.sorts[k] = b
	end
	dr.rows = {}
	for i = 1, octoConstants.ROWS do
		dr.rows[i] = NewRow(dr, i)
	end
	dr.empty = S.Text(dr, "GameFontHighlightSmall", "CENTER")
	dr.empty:SetPoint("TOP", dr, "TOP", 0, octoConstants.ROWS_Y - 60)
	dr.empty:SetWidth(octoConstants.DRAW_W - 30)
	CuratorOctoFull.SetWordWrap(dr.empty, true)
	dr.empty:SetTextColor(0.82, 0.82, 0.86)
	-- its pages, the mouse wheel too
	dr.prev = S.Arrow(dr, -1, 22)
	dr.prev:SetPoint("TOPLEFT", 10, octoConstants.ROWS_Y - octoConstants.ROWS * octoConstants.ROW_H - 2)
	CuratorOctoFull.SetScript(dr.prev, "OnClick", function()
		A:ContractPage(-1)
	end)
	dr.next = S.Arrow(dr, 1, 22)
	dr.next:SetPoint("TOPRIGHT", -10, octoConstants.ROWS_Y - octoConstants.ROWS * octoConstants.ROW_H - 2)
	CuratorOctoFull.SetScript(dr.next, "OnClick", function()
		A:ContractPage(1)
	end)
	dr.pages = S.Text(dr, "GameFontHighlightSmall", "CENTER")
	dr.pages:SetPoint("TOP", dr, "TOP", 0, octoConstants.ROWS_Y - octoConstants.ROWS * octoConstants.ROW_H - 6)
	dr:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(dr, "OnMouseWheel", function(_, delta)
		A:ContractPage(delta > 0 and -1 or 1)
	end)
	-- Fill and Clear, at its foot
	local tools = CreateFrame("Frame", nil, dr)
	CuratorOctoFull.SetSize(tools, octoConstants.DRAW_W - 12, 24)
	tools:SetPoint("BOTTOMLEFT", dr, "BOTTOMLEFT", 6, 10)
	tools.fill = S.Button(tools, L["Fill"], (octoConstants.DRAW_W - 16) / 2, 24)
	tools.fill:SetPoint("LEFT", 0, 0)
	CuratorOctoFull.SetScript(tools.fill, "OnClick", function()
		A:FillContract()
	end)
	CuratorOctoFull.SetScript(tools.fill, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Fill"], 1, 1, 1)
		GameTooltip:AddLine(L["The empty places take the cards with the most copies to spare (of the albums chosen above)."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(tools.fill, "OnLeave", function()
		GameTooltip:Hide()
	end)
	tools.clear = S.Button(tools, L["Clear"], (octoConstants.DRAW_W - 16) / 2, 24)
	tools.clear:SetPoint("RIGHT", 0, 0)
	CuratorOctoFull.SetScript(tools.clear, "OnClick", function()
		A:ClearContract()
	end)
	dr.tools = tools
	page.drawer = dr
	-- (Fill and Clear: the "bar of buttons" of the contract, f.ctFoot, as it was named when they stood under the page)
	f.ctFoot = tools
	-- (the pieces of before, under their names: the menu of the albums, the line over the cards, the cards)
	page.albums = dr.albums
	page.listTitle = dr.total
	page.empty = dr.empty
	page.grid = dr.rows

	-- the register, over the drawer
	local reg = CreateFrame("Frame", nil, page)
	reg:SetAllPoints(dr)
	reg:SetFrameLevel(dr:GetFrameLevel() + 30)
	reg:EnableMouse(true)
	reg:EnableMouseWheel(true)
	reg.bg = Hud.Card(reg, 0.75)
	reg.fill = reg:CreateTexture(nil, "BACKGROUND", nil, -1)
	reg.fill:SetPoint("TOPLEFT", 3, -3)
	reg.fill:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(reg.fill, 0.04, 0.03, 0.03, 0.96)
	reg.title = S.Text(reg, "GameFontNormal", "LEFT")
	reg.title:SetPoint("TOPLEFT", 10, -10)
	reg.title:SetText(L["The register"])
	reg.close = S.Button(reg, "x", 22, 20)
	reg.close:SetPoint("TOPRIGHT", -6, -6)
	CuratorOctoFull.SetScript(reg.close, "OnClick", function()
		A:ToggleRegister(false)
	end)
	reg.lines = {}
	for i = 1, octoConstants.REG_ROWS do
		reg.lines[i] = NewRegLine(reg, i)
	end
	reg.empty = S.Text(reg, "GameFontHighlightSmall", "CENTER")
	reg.empty:SetPoint("TOP", reg, "TOP", 0, -90)
	reg.empty:SetWidth(octoConstants.DRAW_W - 30)
	CuratorOctoFull.SetWordWrap(reg.empty, true)
	reg.empty:SetTextColor(0.82, 0.82, 0.86)
	reg.note = S.Text(reg, "GameFontDisableSmall", "CENTER")
	reg.note:SetPoint("BOTTOM", reg, "BOTTOM", 0, 40)
	reg.note:SetWidth(octoConstants.DRAW_W - 20)
	reg.prev = S.Arrow(reg, -1, 22)
	reg.prev:SetPoint("BOTTOMLEFT", 10, 10)
	CuratorOctoFull.SetScript(reg.prev, "OnClick", function()
		A:RegisterPage(-1)
	end)
	reg.next = S.Arrow(reg, 1, 22)
	reg.next:SetPoint("BOTTOMRIGHT", -10, 10)
	CuratorOctoFull.SetScript(reg.next, "OnClick", function()
		A:RegisterPage(1)
	end)
	reg.pages = S.Text(reg, "GameFontHighlightSmall", "CENTER")
	reg.pages:SetPoint("BOTTOM", reg, "BOTTOM", 0, 15)
	CuratorOctoFull.SetScript(reg, "OnMouseWheel", function(_, delta)
		A:RegisterPage(delta > 0 and -1 or 1)
	end)
	reg:Hide()
	page.register = reg

	-- the rung chosen breathes, the seal of a full deed glows, the cards move
	page.t = 0
	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		A.ctT = (A.ctT or 0) + elapsed
		for _, b in ipairs(self.rungs) do
			if b.on then
				b.light:SetAlpha(0.45 + 0.2 * math.sin(self.t * 3))
			end
		end
		local d = self.band
		if d.full then
			d.stampGlow:SetAlpha(0.45 + 0.3 * math.sin(self.t * 4))
			d.backGlow:SetAlpha(0.55 + 0.2 * math.sin(self.t * 4))
		end
		for _, row in ipairs(self.drawer.rows) do
			if row:IsShown() and row.card:IsShown() then
				row.card:Tick(A.ctT)
			end
		end
		for _, sl in ipairs(d.slots) do
			if sl.card:IsShown() then
				sl.card:Tick(A.ctT)
			end
		end
	end)
end

function A:ShowContractPage(shown)
	local f = self.frame
	-- (1 November: the desk redone, f.ctb, A:BuildDesk, for the boosters and, his word at 11 h 47 (« tu as oublié le
	-- contrat des caisses »), for the cards of the cases too: UI/CaseContract.lua shows its own pieces on it. The page of
	-- before, f.ct, A:BuildContract, is not built any more.)
	if shown then
		self:BuildDesk()
	end
	if f.ct then
		f.ct:Hide()
	end
	if f.ctb then
		CuratorOctoFull.SetShown(f.ctb, shown and true or false)
		if not shown and self.ctPanel then
			self:DeskPanel(nil)
		end
	end
end

function A:ContractHidden()
	self.ctConfirm = nil
end

function A:SetContractRarity(r)
	local ct = self:Contract()
	if not K:Takes(r) then
		-- (the top of the ladder: the mythic card is earned, never exchanged)
		ns.Play(ns.SND.close)
		return
	end
	if r ~= ct.rarity then
		self.ct = K:New(r, ct.finish)
		self.ctPage = 1
		self.ctConfirm = nil
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

function A:SetContractFinish(finish)
	local ct = self:Contract()
	if finish ~= ct.finish then
		self.ct = K:New(ct.rarity, finish)
		self.ctPage = 1
		self.ctConfirm = nil
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- How many contracts at once (the copies past what they take go back).
function A:SetContractCount(n)
	local ct = self:Contract()
	n = math.max(1, math.min(K:Single(ct) and 1 or K:Max(), n))
	if n ~= ct.n then
		K:SetCount(ct, n)
		self.ctConfirm = nil
		ns.Play(ns.SND.click)
		self:Refresh()
	end
end

-- As many contracts as the copies to spare make, filled.
function A:ContractMax()
	local ct = self:Contract()
	local keep = ns.db.keepOne
	K:SetCount(ct, K:MaxCount(ct, keep, self.ctAlbum))
	self.ctConfirm = nil
	self:FillContract()
end

-- The places all empty again (as many contracts as before).
function A:ClearContract()
	ns.Play(ns.SND.click)
	local ct = self:Contract()
	self.ct = K:New(ct.rarity, ct.finish, ct.n)
	-- (1 November: emptied by hand, it stays so: not filled again by itself)
	self.ct.manual = true
	self.ctConfirm = nil
	self:Refresh()
end

-- The empty places filled with the cards that have the most copies to spare: a few fly from the drawer into the ring.
function A:FillContract()
	local ct = self:Contract()
	local before = ct.count
	K:Fill(ct, ns.db.keepOne, self.ctAlbum)
	local n = ct.count - before
	if n > 0 then
		ns.Play(ns.SND.ink)
		self.ctConfirm = nil
	end
	self:Refresh()
	-- (1 November: the desk; from the list beside it, when shown)
	local page = self.frame.ctb
	local col = ns.RARITY[ct.rarity].glow
	for k = 1, math.min(n, 6) do
		local src = page and page.drawer:IsShown() and page.drawer.rows[k]
		local dst = page and page.band.slots[math.min(octoConstants.SLOTS, before + k)]
		if src and dst and src:IsShown() and dst:IsShown() then
			Hud.Fly(octoConstants.MEDIA .. "Back_S", src.card, dst, 24, 0.36, nil, col, (k - 1) * 0.05, octoConstants.CARD_FLY)
		end
	end
end

-- (1.13.0, after its second test) The clause of the collection at once: the album with the most copies to spare among
-- those missing cards of the rarity above (Contract.lua: K:ClauseAlbum), the contract emptied and filled with its copies.
function A:FillForClause()
	local ct = self:Contract()
	local s = self.ctAlbum
	if not s or CuratorOctoFull.Length(K:MissingOf(s, Up(ct))) == 0 then
		s = K:ClauseAlbum(ct.rarity, ct.finish, ns.db.keepOne)
	end
	if not s then
		ns.Play(ns.SND.close)
		return
	end
	self.ct = K:New(ct.rarity, ct.finish, 1)
	self.ctAlbum = s
	self.ctPage = 1
	self.ctConfirm = nil
	self:FillContract()
end

function A:ClauseTooltip(b)
	local ct = self:Contract()
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Fill for the clause"], 1, 1, 1)
	local s, n, miss = K:ClauseAlbum(ct.rarity, ct.finish, ns.db.keepOne)
	if self.ctAlbum and CuratorOctoFull.Length(K:MissingOf(self.ctAlbum, Up(ct))) > 0 then
		s, miss = self.ctAlbum, CuratorOctoFull.Length(K:MissingOf(self.ctAlbum, Up(ct)))
	end
	if s then
		GameTooltip:AddLine(string.format(L["The contract takes the copies of %s alone."], C:SeriesName(s)), S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:AddLine(string.format(L["Its %s cards missing from your album: %d"], L[ns.RARITY[Up(ct)].label], miss), 1, 1, 1, true)
	else
		GameTooltip:AddLine(L["No album has enough copies to spare in this rarity for a contract while missing cards of the next one."], 0.85, 0.85, 0.85, true)
	end
	GameTooltip:Show()
end

-- The albums the cards are taken from: all of them, or one of those that have copies to spare in this rarity and finish
-- (the arrows of the title, the menu of the drawer).
local function ContractAlbums()
	local ct = A:Contract()
	local list = { false }
	for _, s in ipairs(A:Order()) do
		if CuratorOctoFull.Length(K:Eligible(ct.rarity, ct.finish, ns.db.keepOne, s)) > 0 then
			list[CuratorOctoFull.Length(list) + 1] = s
		end
	end
	return list
end

function A:SetContractAlbum(s)
	if (s or nil) == self.ctAlbum then
		return
	end
	self.ctAlbum = s or nil
	-- (1 November: the contract written again from that album, filled by itself)
	local ct = self:Contract()
	self.ct = K:New(ct.rarity, ct.finish, ct.n)
	self.ctConfirm = nil
	self.ctPage = 1
	ns.Play(ns.SND.page)
	self:Refresh()
end

function A:StepContractAlbum(delta)
	local list = ContractAlbums()
	local cur = 1
	for i, s in ipairs(list) do
		if s == (self.ctAlbum or false) then
			cur = i
		end
	end
	local nxt = list[CuratorOctoFull.Mod((cur - 1 + delta) , CuratorOctoFull.Length(list)) + 1]
	self.ctAlbum = nxt or nil
	local ct = self:Contract()
	self.ct = K:New(ct.rarity, ct.finish, ct.n)
	self.ctConfirm = nil
	self.ctPage = 1
	ns.Play(ns.SND.page)
	self:Refresh()
end

-- The menu of the albums, over the drawer: every album, then those with copies to spare in this rarity and finish.
function A:ContractAlbumsMenu(root)
	for _, s in ipairs(ContractAlbums()) do
		local _, s = _, s; root:CreateRadio(s and C:SeriesName(s) or L["All albums"], function(x)
			return (A.ctAlbum or false) == x
		end, function(x)
			A:SetContractAlbum(x or nil)
		end, s)
	end
	if root.SetScrollMode and CuratorOctoFull.Length(ContractAlbums()) > 16 then
		root:SetScrollMode(440)
	end
end

-- The order of the drawer: the most copies first (the default), album by album, by name.
function A:SetContractSort(key)
	if (self.ctSort or "count") == key then
		return
	end
	self.ctSort = key
	self.ctPage = 1
	ns.Play(ns.SND.page)
	self:Refresh()
end

-- The cards of the drawer, in its order.
function A:ContractList(ct, keep)
	local list = K:Eligible(ct.rarity, ct.finish, keep, self.ctAlbum)
	for i, it in ipairs(list) do
		it.i = i
	end
	local sort = self.ctSort or "count"
	if sort == "count" then
		table.sort(list, function(a, b)
			if a.spare ~= b.spare then
				return a.spare > b.spare
			end
			return a.i < b.i
		end)
	elseif sort == "name" then
		local names = {}
		for _, it in ipairs(list) do
			names[it] = C:Name(it.card) or ""
		end
		table.sort(list, function(a, b)
			if names[a] ~= names[b] then
				return names[a] < names[b]
			end
			return a.i < b.i
		end)
	end
	return list
end

function A:ContractPage(delta)
	local ct = self:Contract()
	local n = CuratorOctoFull.Length(K:Eligible(ct.rarity, ct.finish, ns.db.keepOne, self.ctAlbum))
	local pages = math.max(1, math.ceil(n / A.CTB.ROWS))
	local p = math.max(1, math.min(pages, (self.ctPage or 1) + delta))
	if p ~= self.ctPage then
		self.ctPage = p
		ns.Play(ns.SND.page)
		self:Refresh()
	end
end

-- The place of the ring a card is in (its group; a copy a place: the last of them), after the page is painted.
local function SlotOf(page, card)
	local at
	for _, sl in ipairs(page.band.slots) do
		if sl:IsShown() and sl.group and sl.group.card == card then
			at = sl
		end
	end
	return at or page.band.slots[octoConstants.SLOTS]
end

-- A click puts a copy of the card in (a shift-click: every copy of it the contract still takes), a right click takes
-- one back.
function A:ContractRowClick(row, button)
	local it = row.item
	if not it then
		return
	end
	local ct = self:Contract()
	-- (1 November: chosen by hand, not filled by itself any more)
	ct.manual = true
	local pop
	if button == "RightButton" then
		if K:Take(ct, it.card) then
			ns.Play(ns.SND.cardFlip)
		end
	elseif IsShiftKeyDown and IsShiftKeyDown() then
		if K:PutAll(ct, it.card, ns.db.keepOne) > 0 then
			ns.Play(ns.SND.ink)
			pop = it.card
		else
			ns.Play(ns.SND.close)
		end
	elseif K:Put(ct, it.card, ns.db.keepOne) then
		ns.Play(ns.SND.ink)
		pop = it.card
	else
		ns.Play(ns.SND.close)
	end
	self.ctConfirm = nil
	self:Refresh()
	-- the card flies into its place of the ring, which takes it with a pop
	if pop then
		local page = self.frame.ctb
		local sl = SlotOf(page, pop)
		local col = ns.RARITY[pop.rarity].glow
		local card = sl.card
		Hud.Fly(octoConstants.MEDIA .. "Back_S", row.card, sl, 28, 0.32, function()
			Hud.Burst(sl, col, 10, 90, 12)
			local base = octoConstants.SLOT_W / A.U.CW
			ns.Tween(0.25, function(e)
				card:SetScale(base * (1.3 - 0.3 * e))
			end, function()
				card:SetScale(base)
			end, Ease.outBack, A)
		end, col, 0, octoConstants.CARD_FLY)
	end
	if row:IsMouseOver() then
		self:ContractRowTooltip(row)
	end
end

-- (the names of before, for those who call them so)
A.ContractCardClick = A.ContractRowClick

-- A click on a place of the ring takes a copy of its card back (that copy, when a place holds one).
function A:TakeContract(i)
	local ct = self:Contract()
	local sl = self.frame.ctb.band.slots[i]
	local g = sl and sl.group
	local took = g and (g.at and K:TakeAt(ct, g.at) or (not g.at and K:Take(ct, g.card)))
	if took then
		-- (1 November: taken back by hand, not filled again by itself)
		ct.manual = true
		ns.Play(ns.SND.cardFlip)
		self.ctConfirm = nil
		self:Refresh()
	end
end

-- A line of the drawer: its bar and its light of gold while some of its copies are in the contract.
function A:PaintRow(row, hover)
	local it = row.item
	local ct = self.ct
	local used = it and ct and ct.picks[it.card.key] or 0
	row.mark:SetAlpha(used > 0 and 1 or 0)
	row.glow:SetAlpha(used > 0 and (hover and octoConstants.HOVER or octoConstants.PICKED) or 0)
	if used > 0 then
		row.left:SetTextColor(1, 0.82, 0.32)
	else
		row.left:SetTextColor(1, 0.92, 0.75)
	end
end
A.PaintPick = A.PaintRow

function A:ContractRowTooltip(row)
	local it = row.item
	if not it then
		return
	end
	local ct = self:Contract()
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	ns.Booster:CardTooltip(it.card, { finish = Finish(ct) })
	GameTooltip:AddLine(C:SeriesName(it.card.series), 0.8, 0.8, 0.8)
	local used = ct.picks[it.card.key] or 0
	GameTooltip:AddLine(string.format(L["To spare: %d"], it.spare - used), 1, 1, 1)
	if used > 0 then
		GameTooltip:AddLine(string.format(L["In the contract: %d"], used), 1, 0.86, 0.45)
	end
	GameTooltip:AddLine(L["Click: into the contract · Right click: take it back"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:AddLine(L["Shift-click: all its copies"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:Show()
	self:PaintRow(row, true)
end
A.ContractCardTooltip = A.ContractRowTooltip

function A:SlotContractTooltip(sl, i)
	local g = sl.group
	if not g then
		return
	end
	local ct = self:Contract()
	GameTooltip:SetOwner(sl, "ANCHOR_RIGHT")
	if sl.rest then
		GameTooltip:AddLine(string.format(L["And %d more cards"], sl.rest), 1, 1, 1)
	end
	ns.Booster:CardTooltip(g.card, { finish = Finish(ct) })
	GameTooltip:AddLine(C:SeriesName(g.card.series), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(string.format(L["In the contract: %d"], g.n), 1, 1, 1)
	-- (1.13.0) its copies in it: those chosen, the least precious else; one appraised or restored said
	local CP, CU = ns.Copies, ns.CopiesUI
	local ids = ct.ids and ct.ids[g.card.key]
	if CP and CU and type(ids) == "table" and CuratorOctoFull.Length(ids) > 0 and not sl.rest then
		GameTooltip:AddLine(string.format(L["Its copies in it: %s"], CU:Names(g.card, ids)), 0.8, 0.86, 1, true)
		for _, id in ipairs(ids) do
			local r = CP:Get(g.card.key, id)
			if r and CP.Telling(r) then
				local gr = CP.Grade(r)
				GameTooltip:AddLine("  " .. CU:Label(g.card, r) .. ((gr and r.sl ~= false) and ("  " .. ns.Expertise.Label(gr / 100)) or ""), 1, 0.72, 0.45)
			end
		end
	end
	GameTooltip:AddLine(L["Click: take it back"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	if not sl.rest then
		GameTooltip:AddLine(L["Right click: choose its copies"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	end
	GameTooltip:Show()
end

-- (1.13.0) The copies of a card that go into the contract: chosen in the chooser of copies (UI/Copies.lua), as many as
-- the contract takes of it.
function A:ChooseContractCopies(sl)
	local ct = self:Contract()
	local g = sl and sl.group
	if not (g and g.card and ns.CopiesUI) then
		return
	end
	local key = g.card.key
	local n = ct.picks[key] or 0
	if n <= 0 then
		return
	end
	GameTooltip:Hide()
	local fin = ct.finish ~= "normal" and ct.finish or nil
	ns.CopiesUI:OpenPicker({ card = g.card, finish = fin, n = n, ids = ct.ids and ct.ids[key], owner = sl,
		done = function(ids)
			if ns.Copies:Chosen(key, fin, ids, n) then
				ct.ids = ct.ids or {}
				ct.ids[key] = ids
			end
			A:Refresh()
		end })
end

function A:RungTooltip(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	if b.locked then
		GameTooltip:AddLine(Deal(K.TOP, 1, nil, K.SIZE, ns.MYTHIC), 1, 1, 1)
		GameTooltip:AddLine(L["The mythic cards are earned: no contract gives one. They come from the boosters (and now and then from the reseller)."], 1, 0.6, 0.6, true)
		GameTooltip:Show()
		return
	end
	local fin = self:Contract().finish
	local size = K:SizeOf(b.rarity, fin)
	GameTooltip:AddLine(Deal(b.rarity, 1, nil, size), 1, 1, 1)
	GameTooltip:AddLine(string.format(L["Copies to spare: %d"], b.found or 0), 1, 1, 1)
	if (b.found or 0) >= size * 2 then
		GameTooltip:AddLine(string.format(L["Enough for %d contracts at once."], math.min(K:Max(), math.floor((b.found or 0) / size))), 1, 0.86, 0.45)
	end
	if b.rarity == K.LAST then
		GameTooltip:AddLine(L["The highest a contract gives: a legendary card. The mythic ones are earned."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:AddLine(L["Click: a contract of this rarity"], S.GOLD[1], S.GOLD[2], S.GOLD[3])
	GameTooltip:Show()
end
A.RecipeTooltip = A.RungTooltip

-------------------------------------------------------------------------------
-- (1.6.0) The talents of the Merchant for the next contract: the Favor Contract (five cards), the
-- Masterstroke (two rarities up, to legendary), the Tailor-Made Contract (the album of the new card,
-- among those of the contract), the Alchemist (thunderforged cards give a titanforged one). Armed, the
-- contract is signed alone.
-------------------------------------------------------------------------------
local function ActiveOk(b, ct)
	local TL = ns.Talents
	if not (TL and TL:Has(b.id)) then
		return false
	end
	if b.key == "master" and ct.rarity > 3 then
		return false
	end
	if b.key == "alchemist" and ct.finish ~= "shiny" then
		return false
	end
	return true
end

-- The talents had, in a row over the signature (from the left); how many.
function A:PaintContractActives()
	local deed = self.frame.ctb.band
	local ct = self:Contract()
	local TL = ns.Talents
	local shown = {}
	for _, b in ipairs(deed.actButtons) do
		local has = TL ~= nil and TL:Has(b.id)
		CuratorOctoFull.SetShown(b, has)
		if has then
			shown[CuratorOctoFull.Length(shown) + 1] = b
			local ready = TL:Ready(b.id) and ActiveOk(b, ct)
			local on = ct[b.key] and true or false
			b.icon:SetDesaturated(not ready)
			b.icon:SetAlpha(ready and 1 or 0.5)
			b.ring:SetDesaturated(not ready)
			b.light:SetAlpha(on and 0.85 or 0)
		end
	end
	for i, b in ipairs(shown) do
		b:ClearAllPoints()
		b:SetPoint("LEFT", b:GetParent(), "LEFT", (i - 1) * 30, 0)
	end
	return CuratorOctoFull.Length(shown)
end

function A:ContractActive(b)
	local ct = self:Contract()
	local TL = ns.Talents
	if not (TL and TL:Ready(b.id) and ActiveOk(b, ct)) then
		ns.Play(ns.SND.close)
		return
	end
	if b.key == "tailor" and not ct.tailor then
		-- (the album: one of the contract, chosen in a menu; 1.12.0: never the album of an event)
		local odds = {}
		for _, o in ipairs(K:Odds(ct)) do
			if not o.series.event and not o.series.limited then
				odds[CuratorOctoFull.Length(odds) + 1] = o
			end
		end
		if CuratorOctoFull.Length(odds) == 0 then
			ns.Play(ns.SND.close)
			return
		end
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(b, function(_, root)
				root:CreateTitle(L["The album of the new card"])
				for _, o in ipairs(odds) do
					local _, o = _, o; root:CreateRadio(C:SeriesName(o.series), function(key)
						return ct.tailor == key
					end, function(key)
						K:SetActive(ct, "tailor", key)
						ns.Play(ns.SND.ink)
						A:Refresh()
					end, o.series.key)
				end
			end)
		else
			K:SetActive(ct, "tailor", odds[1].series.key)
			ns.Play(ns.SND.ink)
			self:Refresh()
		end
		return
	end
	K:SetActive(ct, b.key, not ct[b.key] or nil)
	ns.Play(ct[b.key] and ns.SND.ink or ns.SND.cardFlip)
	self.ctConfirm = nil
	self:Refresh()
end

function A:ContractActiveTooltip(b)
	local TL = ns.Talents
	if not TL then
		return
	end
	local ct = self:Contract()
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(TL:Name(b.id), 1, 0.78, 0.3)
	GameTooltip:AddLine(TL:Text(b.id, 1), 1, 1, 1, true)
	local left = TL:Left(b.id)
	if left > 0 then
		GameTooltip:AddLine(string.format((TL.BY[b.id].limit and L["Again in %s"] or L["Ready in %s"]), ns.Duration(left)), 0.62, 0.62, 0.68)
	elseif not ActiveOk(b, ct) then
		GameTooltip:AddLine(b.key == "master" and L["Up to legendary: a contract of common, uncommon or rare cards."]
			or L["A contract of thunderforged cards."], 1, 0.4, 0.35, true)
	elseif ct[b.key] then
		if b.key == "tailor" then
			local tailor = ns.SeriesByKey(ct.tailor)
			GameTooltip:AddLine(string.format(L["The new card comes from: %s"], tailor and C:SeriesName(tailor) or "?"), 0.55, 1, 0.55, true)
		end
		GameTooltip:AddLine(L["Armed for this contract (signed alone). Click: not any more."], 0.55, 1, 0.55, true)
	else
		GameTooltip:AddLine(L["Click: for this contract (signed alone)."], 1, 0.8, 0.32, true)
	end
	GameTooltip:Show()
end

-- Two clicks to sign: the first asks to confirm, for a few seconds.
function A:SignContract()
	local ct = self:Contract()
	-- (1 November: what each card has to spare asked again, not as it was kept, Contract.lua: K:Forget)
	K:Forget()
	if ct.count < K:Capacity(ct) then
		return
	end
	-- (1.14.0, after its test, his word: a reroll signs none, the chat says why: Reroll.lua)
	if ns.Reroll and ns.Reroll:Blocks("contracts") then
		ns.Reroll:SayNot("contracts")
		return
	end
	if not (self.ctConfirm and GetTime() - self.ctConfirm < 4) then
		self.ctConfirm = GetTime()
		ns.Play(ns.SND.click)
		self:Refresh()
		ns.Delay(4.05, function()
			if A.ctConfirm and GetTime() - A.ctConfirm >= 4 then
				A.ctConfirm = nil
				if A.frame:IsShown() and A.mode == "contract" then
					A:Refresh()
				end
			end
		end, self)
		return
	end
	self.ctConfirm = nil
	local result = K:Sign(ct, ns.db.keepOne)
	if not result then
		K:Check(ct, ns.db.keepOne)
		self:Refresh()
		return
	end
	-- the next one ready: as many contracts, filled with what is left (one click to sign it again)
	local nxt = K:New(ct.rarity, ct.finish, ct.n)
	K:SetCount(nxt, math.min(ct.n, K:MaxCount(nxt, ns.db.keepOne, self.ctAlbum)))
	K:Fill(nxt, ns.db.keepOne, self.ctAlbum)
	self.ct = nxt
	self:Hide()
	B:OpenContract(result)
end

-------------------------------------------------------------------------------
-- (1.13.0, after its second test) The register: the last contracts signed (Contract.lua: K:Register), a page of them.
-------------------------------------------------------------------------------
function A:ToggleRegister(on)
	-- (1 November: beside the deed of the desk, which steps aside for it)
	local page = self.frame and self.frame.ctb
	if not page then
		return
	end
	if on == nil then
		on = self.ctPanel ~= "register"
	end
	ns.Play(on and ns.SND.open or ns.SND.close)
	self.regPage = 1
	self:DeskPanel(on and "register" or nil)
	self:PaintRegister(page)
	if not on then
		self:Refresh()
	end
end

function A:RegisterPage(delta)
	local page = self.frame.ctb
	local per = CuratorOctoFull.Length(page.register.lines)
	local n = CuratorOctoFull.Length(K:Register())
	local pages = math.max(1, math.ceil(n / per))
	local p = math.max(1, math.min(pages, (self.regPage or 1) + delta))
	if p ~= self.regPage then
		self.regPage = p
		ns.Play(ns.SND.page)
		self:PaintRegister(page)
	end
end

function A:PaintRegister(page)
	local reg = page.register
	local log = K:Register()
	page.regButton:SetText(CuratorOctoFull.Length(log) > 0 and string.format(("%s (%d)"), L["The register"], CuratorOctoFull.Length(log)) or L["The register"])
	if not reg:IsShown() then
		return
	end
	local hex = A.U.Hex
	local per = CuratorOctoFull.Length(reg.lines)
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(log) / per))
	self.regPage = math.max(1, math.min(self.regPage or 1, pages))
	for i, l in ipairs(reg.lines) do
		-- (the latest first)
		local e = log[CuratorOctoFull.Length(log) - ((self.regPage - 1) * per + i) + 1]
		if e then
			l:Show()
			local when = date and date("%d/%m %H:%M", e.t) or ""
			l.head:SetText(when)
			local r = tonumber(e.r) or 1
			S.Fit(l.what, Deal(r, e.n or 1, nil, tonumber(e.s), tonumber(e.u) or math.min(K.TOP, r + 1)), octoConstants.DRAW_W - 24, 11, 8)
			local parts, extra = {}, 0
			for k, x in ipairs(type(e.c) == "table" and e.c or {}) do
				local card = ns.Cards[x.k]
				if card and k <= 2 then
					local rc = ns.RARITY[card.rarity].text
					parts[CuratorOctoFull.Length(parts) + 1] = string.format(("|cff%s%s|r%s%s"), hex(rc), C:Name(card) or "?", x.nw and (" |cff66ff66" .. L["new"] .. "|r") or "",
						x.cl and " |cffffcc55*|r" or "")
				elseif card then
					extra = extra + 1
				end
			end
			if extra > 0 then
				parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%d more"], extra)
			end
			l.cards:SetText(table.concat(parts, ", "))
		else
			l:Hide()
		end
	end
	reg.empty:SetText(CuratorOctoFull.Length(log) == 0 and L["No contract signed yet. The register keeps your last twenty."] or "")
	S.Fit(reg.note, CuratorOctoFull.Length(log) > 0 and L["* a card of the clause of the collection"] or "", octoConstants.DRAW_W - 20, 10, 8)
	reg.pages:SetText(string.format(("%d / %d"), self.regPage, pages))
	reg.prev:SetEnabled(self.regPage > 1)
	reg.next:SetEnabled(self.regPage < pages)
end

-------------------------------------------------------------------------------
-- What the page shows
-------------------------------------------------------------------------------
-- The ladder: each rung with the copies to spare of its rarity in this finish, the contracts they make, how far the
-- next one is; the one chosen lit.
function A:PaintLadder(page, ct, keep)
	local spare = K:SpareByRarity(ct.finish, keep)
	for r, b in ipairs(page.rungs) do
		if not b.locked then
			b.found = spare[r]
			b.count:SetText(spare[r] > 999 and "999+" or tostring(spare[r]))
			b.chip:SetWidth(math.max(22, ns.TextWidth(b.count) + 12))
			local need = K:SizeOf(r, ct.finish)
			local text, enough = Makes(spare[r], need)
			Fit(b.makes, text, 10, b.tw)
			if enough then
				b.count:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
				b.makes:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
			else
				b.count:SetTextColor(0.6, 0.6, 0.6)
				b.makes:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
			end
			b.bar:SetProgress((CuratorOctoFull.Mod(spare[r] , need)) / need)
			b:SetSelected(r == ct.rarity)
		else
			b:SetSelected(false)
		end
	end
end

-- The finishes, with the copies to spare of the rarity (the forged ones by the name of their finish).
function A:PaintFinishes(page, ct, keep)
	for _, fin in ipairs(K.FINISHES) do
		local b = page.fin[fin]
		local n = K:SpareByRarity(fin, keep)[ct.rarity]
		Fit(b.text, string.format(("%s (%d)"), L[fin == "normal" and octoConstants.FINISH_LABEL[fin] or octoConstants.FINISH_NAME[fin]], n), 10, octoConstants.LAD_W - octoConstants.FIN_H - 8)
		b:SetChecked(fin == ct.finish)
	end
end

-- The deed: its head, its places in the ring (a card a place, the same card's copies together; past ten, the last place
-- tells how many more), the card it promises (sealed when it is full), where it comes from, the clause, Sign.
-- (31 October, the contracts redone) The wear of a copy of a card given (the first of its copies in the contract), of
-- the copy of it that would go next (nil: none known).
function A:GivenWear(ct, card)
	local CP, W = ns.Copies, ns.Wear
	if not (CP and W and card) then
		return nil
	end
	local ids = ct.ids and ct.ids[card.key]
	local rec = type(ids) == "table" and ids[1] and CP:Get(card.key, ids[1]) or nil
	return rec and W.Of(rec) or nil
end

function A:NextWear(ct, card)
	local CP, W = ns.Copies, ns.Wear
	if not (CP and W and card) then
		return nil
	end
	local used = {}
	for _, x in ipairs(ct.ids and ct.ids[card.key] or {}) do
		used[x] = true
	end
	for _, r in ipairs(CP:Free(card.key, ct.finish)) do
		if not used[r.i] then
			return W.Of(r)
		end
	end
	return nil
end

function A:PaintDeed(page, ct, cap, size, up, finish)
	local deed = page.band
	deed.title:SetText(ct.n > 1 and string.format(L["%d exchange contracts"], ct.n) or L["Exchange contract"])
	Fit(deed.deal, Deal(ct.rarity, ct.n, true, size, up), 12, octoConstants.DEED_W - 70)
	local groups
	if ct.n > 1 then
		groups = K:Groups(ct)
	else
		groups = {}
		for i, key in ipairs(ct.list) do
			groups[i] = { card = ns.Cards[key], n = 1, at = i }
		end
	end
	local full = ct.count == cap
	-- (1.6.0: one contract of fewer cards: as many places, the ring as round)
	local places = ct.n > 1 and octoConstants.SLOTS or math.min(octoConstants.SLOTS, cap)
	for i, sl in ipairs(deed.slots) do
		CuratorOctoFull.SetShown(sl, i <= places)
		local x, y = RingXY(i, places)
		sl:ClearAllPoints()
		sl:SetPoint("CENTER", deed, "TOPLEFT", x, y)
	end
	for i, sl in ipairs(deed.slots) do
		local g = groups[i]
		local c = sl.card
		sl.rest = nil
		if i == octoConstants.SLOTS and CuratorOctoFull.Length(groups) > octoConstants.SLOTS then
			-- the cards beyond the tenth place
			local rest = 0
			for k = octoConstants.SLOTS, CuratorOctoFull.Length(groups) do
				rest = rest + groups[k].n
			end
			sl.rest = CuratorOctoFull.Length(groups) - octoConstants.SLOTS + 1
			g = groups[CuratorOctoFull.Length(groups)]
			sl.more:SetText("+" .. rest)
		else
			sl.more:SetText("")
		end
		sl.group = g
		if g then
			local card = g.card
			-- (31 October, his word: the contracts redone: the copy given, its wear on it; what comes is in their
			-- condition, their wear averaged)
			local wear = self:GivenWear(ct, card)
			local wk = wear and (tostring(wear.seed) .. table.concat(wear.m, "") .. tostring(wear.x or "") .. tostring(wear.a or "")) or ""
			if c.card ~= card or c.ctFinish ~= ct.finish or c.ctWear ~= wk or not c:IsShown() then
				c:Show()
				c:SetCard(card, { owned = true, finish = finish, wear = wear })
				c:ShowSide("front")
				c.ctFinish, c.ctWear = ct.finish, wk
			end
			c:SetAlpha(sl.rest and 0.35 or 1)
			c.phase = i * 0.41
			sl.plus:Hide()
			sl.bg:SetAlpha(1)
			sl.n:SetText((not sl.rest and g.n > 1) and ("x" .. g.n) or "")
		else
			c:Hide()
			c.card = nil
			CuratorOctoFull.SetShown(sl.plus, not full)
			sl.bg:SetAlpha(full and 0.45 or 1)
			sl.n:SetText("")
		end
	end
	-- the card it promises: its gem, its light, the ring of the copies given (it grows), sealed once full
	local r2 = ns.RARITY[up]
	deed.gem:SetTexture(octoConstants.MEDIA .. "Gem" .. up)
	deed.backGlow:SetVertexColor(r2.glow[1], r2.glow[2], r2.glow[3])
	if not full then
		deed.backGlow:SetAlpha(0.2 + 0.25 * ct.count / math.max(1, cap))
	end
	-- (the lights: one for each copy given, ten for several contracts, each a tenth of them)
	local dots = ct.n > 1 and octoConstants.DOTS or math.min(octoConstants.DOTS, cap)
	local lit = ct.n > 1 and math.floor(octoConstants.DOTS * ct.count / math.max(1, cap)) or ct.count
	for i, d in ipairs(deed.dots) do
		local a = math.pi / 2 - (i - 1) * 2 * math.pi / math.max(1, dots)
		d:ClearAllPoints()
		d:SetPoint("CENTER", deed, "TOPLEFT", octoConstants.RING_X + octoConstants.DOT_R * math.cos(a), octoConstants.RING_Y + 4 + octoConstants.DOT_R * math.sin(a))
		d.glow:ClearAllPoints()
		d.glow:SetPoint("CENTER", d, "CENTER")
		CuratorOctoFull.SetShown(d, i <= dots)
		local on = i <= lit
		if on then
			d:SetVertexColor(1, 0.84, 0.4)
			d:SetAlpha(1)
		else
			d:SetVertexColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
			d:SetAlpha(0.5)
		end
		d.glow:SetAlpha((on and i <= dots) and 0.55 or 0)
	end
	deed.ring:SetVertexColor(1, 0.86, 0.42)
	if deed.ringTw then
		ns.CancelTween(deed.ringTw)
		deed.ringTw = nil
	end
	if full and not deed.full and deed:IsVisible() then
		deed.ring:SetAlpha(0)
		deed.ringTw = ns.Tween(0.45, function(e)
			deed.ring:SetAlpha(e)
		end, function()
			deed.ringTw = nil
		end, Ease.outQuad, A)
	elseif full then
		deed.ring:SetAlpha(1)
	else
		deed.ring:SetAlpha(0)
	end
	-- (made smaller when long, so that it never runs under the places of the ring)
	Fit(deed.count, full and L["Ready to sign"] or string.format(L["%d / %d cards"], ct.count, cap), 11, 92)
	if full and not deed.full then
		-- (the seal comes down on the card)
		if deed:IsVisible() then
			Hud.Stamp(deed.stamp, 46, 0.05, function()
				ns.Play(ns.SND.seal)
				Hud.Burst(deed.stamp, { 1, 0.5, 0.4 }, 12, 100, 14)
			end, A)
		else
			CuratorOctoFull.SetSize(deed.stamp, 46, 46)
			deed.stamp:SetAlpha(1)
			deed.stamp:Show()
		end
	elseif not full then
		deed.stamp:Hide()
		deed.stampGlow:SetAlpha(0)
	end
	deed.full = full
	deed.glow:SetAlpha(full and 0.3 or 0.1)
	deed.glow:SetVertexColor(r2.glow[1], r2.glow[2], r2.glow[3])
	-- where the new card comes from (the Tailor-Made Contract: the album chosen, when it is one of the contract)
	local odds = K:Odds(ct)
	local tailor = ct.tailor and ns.SeriesByKey(ct.tailor)
	if tailor then
		for _, o in ipairs(odds) do
			if o.series == tailor and CuratorOctoFull.Length(tailor.byRarity[up]) > 0 then
				odds = { { series = tailor, share = 1 } }
				break
			end
		end
	end
	local parts = {}
	for i, o in ipairs(odds) do
		if i <= 3 then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(("%s %d %%"), C:SeriesName(o.series), math.floor(o.share * 100 + 0.5))
		end
	end
	if CuratorOctoFull.Length(odds) > 3 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%d more albums"], CuratorOctoFull.Length(odds) - 3)
	end
	if ct.count == 0 then
		deed.from:SetText(size == 10 and L["Choose ten cards of the same rarity and finish: click a card to put it in the contract."]
			or string.format(L["Choose %d cards of the same rarity and finish: click a card to put it in the contract."], size))
		deed.from.summary = nil
	else
		deed.from:SetText(string.format((ct.n > 1 and L["The new cards come from: %s"] or L["The new card comes from: %s"]), table.concat(parts, " · ")))
		local all = {}
		for _, o in ipairs(odds) do
			all[CuratorOctoFull.Length(all) + 1] = string.format(("%s %d%%"), C:SeriesName(o.series), math.floor(o.share * 100 + 0.5))
		end
		deed.from.summary = string.format(L["The new card comes from: %s"], table.concat(all, ", "))
	end
	-- the clause of the collection
	local s, missing = K:Clause(ct)
	local upName = L[r2.label]
	local m = missing and CuratorOctoFull.Length(missing) or 0
	local ok = s and m > 0
	if ok then
		-- (each card it is missing once: one missing, or fewer than the contracts, the others drawn as usual)
		local n, name, text = ct.n or 1, C:SeriesName(s)
		if m == 1 then
			text = string.format((n > 1 and L["Collection clause: one of the new cards will be the %s card of %s still missing from your album."]
				or L["Collection clause: the new card will be the %s card of %s still missing from your album."]), upName, name)
		elseif n > m then
			text = string.format(L["Collection clause: %d of the new cards will be the %s cards of %s missing from your album."], m, upName, name)
		elseif n > 1 then
			text = string.format(L["Collection clause: the new cards will be among the %d %s cards of %s missing from your album."], m, upName, name)
		else
			text = string.format(L["Collection clause: the new card will be one of the %d %s cards of %s missing from your album."], m, upName, name)
		end
		deed.clause:SetText(text)
		deed.clause:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	elseif s then
		deed.clause:SetText(string.format(L["Collection clause: your album already has every %s card of %s."], upName, C:SeriesName(s)))
		deed.clause:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	else
		deed.clause:SetText(L["Collection clause: copies of a single album give a card that album is missing."])
		deed.clause:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	end
	deed.clauseIcon:SetDesaturated(not ok)
	deed.clauseIcon:SetAlpha(ok and 1 or 0.55)
	deed.clause.ok = ok and true or false
	-- (31 October: the clause of the condition; every copy given appraised: the clause of the experts)
	local CP = ns.Copies
	local all, n = ct.count > 0, 0
	for key, ids in pairs(ct.ids or {}) do
		for _, id in ipairs(ids) do
			n = n + 1
			local rec = CP and CP:Get(key, id)
			if not (rec and CP.Grade(rec)) then
				all = false
			end
		end
	end
	if all and n == ct.count then
		deed.cond:SetText(L["Clause of the experts: all appraised, it comes appraised."])
		deed.cond:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	else
		-- (the clause of the collection long, on three lines: the short words, nothing over the buttons)
		local long = (deed.clause:GetStringHeight() or 0) > 30
		deed.cond:SetText(long and L["Clause of the condition: their average wear."] or L["Clause of the condition: the average wear of the copies given."])
		deed.cond:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	end
	-- (its button: when the contract does not have it yet and an album can make it)
	local can = not ok and K:ClauseAlbum(ct.rarity, ct.finish, ns.db.keepOne) ~= nil and not K:Single(ct)
	-- (1.14.0, after its test, his word: a reroll signs none; why in the place of the clause, Reroll.lua: RR:Blocks)
	local rr = ns.Reroll ~= nil and ns.Reroll:Blocks("contracts")
	if rr then
		deed.clause:SetText(ns.Reroll:WhyNot("contracts"))
		deed.clause:SetTextColor(0.62, 0.14, 0.1)
		deed.clauseIcon:SetDesaturated(true)
		deed.clauseIcon:SetAlpha(0.55)
		deed.clause.ok = false
		can = false
	end
	CuratorOctoFull.SetShown(deed.clauseBtn, can and true or false)
	-- how many at once
	local keep = ns.db.keepOne
	local most = K:MaxCount(ct, keep, self.ctAlbum)
	local mult = deed.mult
	mult.text:SetText("x" .. ct.n)
	mult.prev:SetEnabled(ct.n > 1)
	mult.next:SetEnabled(ct.n < (K:Single(ct) and 1 or K:Max()))
	local any = CuratorOctoFull.Length(K:Eligible(ct.rarity, ct.finish, keep, self.ctAlbum)) > 0
	mult.max:SetEnabled(any and (most > 1 or ct.count < cap))
	-- the talents of the Merchant, Sign
	self:PaintContractActives()
	local confirming = full and not rr and self.ctConfirm and GetTime() - self.ctConfirm < 4
	page.sign:SetLabel(confirming and L["Confirm?"] or (ct.n > 1 and string.format(L["Sign the %d contracts"], ct.n) or L["Sign the contract"]))
	local signs = full and not rr
	page.sign:SetEnabled(signs)
	page.sign:SetPulse(signs)
	page.sign.quill:SetDesaturated(not signs)
	page.sign.quill:SetAlpha(signs and 1 or 0.6)
end

-- The drawer: the cards with copies to spare (of the album chosen), in its order, a page of them; Fill and Clear.
function A:PaintDrawer(page, ct, keep, finish)
	local dr = page.drawer
	local list = self:ContractList(ct, keep)
	local total = 0
	for _, it in ipairs(list) do
		total = total + it.spare
	end
	dr.total:SetText(ns.Num(total))
	dr.total.label = string.format(L["Copies to spare: %d"], total)
	dr.albums:GenerateMenu()
	for _, b in ipairs(dr.sorts) do
		local on = (self.ctSort or "count") == b.key
		Hud.Each(b.glow, "SetAlpha", on and 0.8 or 0)
		local col = on and { 1, 1, 1 } or S.GOLD
		b.text:SetTextColor(col[1], col[2], col[3])
	end
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / octoConstants.ROWS))
	self.ctPage = math.max(1, math.min(self.ctPage or 1, pages))
	for i, row in ipairs(dr.rows) do
		local it = list[(self.ctPage - 1) * octoConstants.ROWS + i]
		if it then
			row:Show()
			local c = row.card
			-- (31 October: the copy that would go next, its wear on it)
			local wear = self:NextWear(ct, it.card)
			local wk = wear and (tostring(wear.seed) .. table.concat(wear.m, "") .. tostring(wear.x or "") .. tostring(wear.a or "")) or ""
			if c.card ~= it.card or c.ctFinish ~= ct.finish or c.ctWear ~= wk or not c:IsShown() then
				c:Show()
				c:SetCard(it.card, { owned = true, finish = finish, wear = wear })
				c:ShowSide("front")
				c.ctFinish, c.ctWear = ct.finish, wk
			end
			c.phase = i * 0.29
			local rc = ns.RARITY[it.card.rarity].text
			S.Fit(row.name, C:Name(it.card) or "?", octoConstants.DRAW_W - 12 - (8 + (octoConstants.ROW_H - 6) * A.U.CW / A.U.CH + 6) - 40, 11, 8)
			row.name:SetTextColor(rc[1], rc[2], rc[3])
			-- (a long name of an album made smaller, as the name of the card)
			S.Fit(row.album, C:SeriesName(it.card.series), octoConstants.DRAW_W - 12 - (8 + (octoConstants.ROW_H - 6) * A.U.CW / A.U.CH + 6) - 40, 10, 8)
			local used = ct.picks[it.card.key] or 0
			local left = it.spare - used
			row.left:SetText("x" .. left)
			row.used:SetText(used > 0 and ("+" .. used) or "")
			row:SetAlpha(left > 0 and 1 or 0.5)
			row.item = it
			self:PaintRow(row, row:IsMouseOver())
		else
			row:Hide()
			row.card:Hide()
			row.card.card, row.item = nil, nil
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		dr.empty:SetText(L["No copy to spare in this rarity and finish yet. Duplicates come with the boosters!"])
	else
		dr.empty:SetText("")
	end
	dr.pages:SetText(string.format(("%d / %d"), self.ctPage, pages))
	dr.prev:SetEnabled(self.ctPage > 1)
	dr.next:SetEnabled(self.ctPage < pages)
	local cap = K:Capacity(ct)
	dr.tools.fill:SetEnabled(ct.count < cap and CuratorOctoFull.Length(list) > 0)
	dr.tools.clear:SetEnabled(ct.count > 0)
end

function A:RefreshContract()
	local f = self.frame
	self:BuildDesk()
	local page = f.ctb
	local keep = ns.db.keepOne
	local ct = self:Contract()
	K:Check(ct, keep)
	-- (1 November, his word: the contract filled by itself, with the least precious duplicates; not once chosen by hand)
	if not ct.manual and ct.count < K:Capacity(ct) then
		K:Fill(ct, keep, self.ctAlbum)
	end
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	f.wait:Hide()
	f.boosters:Hide()
	f.gauge:Hide()
	f.open:Hide()
	-- (the drawer has its own pages)
	self:ShowPager(false)
	local finish = Finish(ct)
	local cap = K:Capacity(ct)
	local size = K:Size(ct)
	local up = Up(ct)
	-- title: the album the cards are taken from, or all of them
	self:SetTitle(self.ctAlbum and C:SeriesName(self.ctAlbum) or L["Exchange contract"], Deal(ct.rarity, ct.n, nil, size, up))
	-- the bar of the head: the contract filling up
	self:SetBar(ct.count, cap, string.format(L["%d / %d cards"], ct.count, cap))
	self:PaintTiles(page, ct, keep)
	self:PaintDeskChips(page, ct, keep)
	page.keep:SetChecked(keep and true or false)
	self:PaintDesk(page, ct, cap, size, up, finish)
	self:PaintDeskDrawer(page, ct, keep, finish)
	self:PaintRegister(page)
end

-------------------------------------------------------------------------------
-- (1 November, 10 h 27, his word: « le contrat d'échange c'est un peu le fouillis quand même xD. Ça serait bien qu'il
-- soit ergonomique et plus simple. Rework le totalement stp »; his choices: the ring in the middle, the contract filled
-- by itself) The desk of the boosters, redone (f.ctb): at the top, the four exchanges, the finishes and the register;
-- in the middle, the deed, its ring, and on its right what comes and its clauses; under the ring, the cards to change
-- by hand and the album; at the foot, the copy kept of each card, how many contracts at once, Sign. The cards to choose,
-- and the register, beside the deed on asking (it steps aside for them). The contract fills itself with the least
-- precious duplicates as soon as an exchange is chosen; a card taken back or put in by hand, Clear: not any more. The
-- desk of the cases keeps the page of before (f.ct, UI/CaseContract.lua).
-------------------------------------------------------------------------------
local DK = {
	TILE_H = 44, TILE_GAP = 8, CHIPS_Y = -54, CHIP_H = 22,
	DEED_Y = -84, DEED_W = 540, DEED_H = 412,
	RING_X = 186, RING_Y = -218,
	SIDE_X = 336, SIDE_W = 172,
	PANEL_W = 188,
	ROWS = 7, ROWS_Y = -58, REG_ROW_H = 60, REG_ROWS = 5,
	-- (the parchment of ContractDeed cut in nine: its corners and its edges as they are, its middle a plain part of it)
	CUT = 30,
}
DK.HOME_X = (octoConstants.PAGE_W - DK.DEED_W) / 2
DK.PANEL_X = octoConstants.PAGE_W - DK.PANEL_W
A.CTB = DK

-- A place of the ring of the desk, from the top, clockwise.
local function DeskRingXY(i, places)
	local a = math.pi / 2 - (i - 1) * 2 * math.pi / math.max(1, places)
	return DK.RING_X + octoConstants.RING_R * math.cos(a), DK.RING_Y + octoConstants.RING_R * math.sin(a)
end
DK.RingXY = DeskRingXY

-- The parchment of the deed on a frame of any size, in nine pieces (its double line of ink all round, its corners).
local function Parchment(f)
	local px = 1 / 512
	local u = { 80 * px, (80 + DK.CUT) * px, (432 - DK.CUT) * px, 432 * px }
	local v = { 0, DK.CUT * px, (512 - DK.CUT) * px, 1 }
	-- (the middle: a plain part, under the flourish of its head)
	local mid = { 120 * px, 470 * px }
	local t = {}
	for row = 1, 3 do
		for col = 1, 3 do
			local x = f:CreateTexture(nil, "BORDER")
			x:SetTexture(octoConstants.MEDIA .. "ContractDeed")
			local v0, v1 = v[row], v[row + 1]
			if row == 2 and col == 2 then
				v0, v1 = mid[1], mid[2]
			end
			x:SetTexCoord(u[col], u[col + 1], v0, v1)
			t[(row - 1) * 3 + col] = x
		end
	end
	local c = DK.CUT * 1.03
	for k = 1, 9 do
		CuratorOctoFull.SetSize(t[k], c, c)
	end
	t[1]:SetPoint("TOPLEFT")
	t[3]:SetPoint("TOPRIGHT")
	t[7]:SetPoint("BOTTOMLEFT")
	t[9]:SetPoint("BOTTOMRIGHT")
	t[2]:SetPoint("TOPLEFT", t[1], "TOPRIGHT")
	t[2]:SetPoint("BOTTOMRIGHT", t[3], "BOTTOMLEFT")
	t[8]:SetPoint("TOPLEFT", t[7], "TOPRIGHT")
	t[8]:SetPoint("BOTTOMRIGHT", t[9], "BOTTOMLEFT")
	t[4]:SetPoint("TOPLEFT", t[1], "BOTTOMLEFT")
	t[4]:SetPoint("BOTTOMRIGHT", t[7], "TOPRIGHT")
	t[6]:SetPoint("TOPLEFT", t[3], "BOTTOMLEFT")
	t[6]:SetPoint("BOTTOMRIGHT", t[9], "TOPRIGHT")
	t[5]:SetPoint("TOPLEFT", t[1], "BOTTOMRIGHT")
	t[5]:SetPoint("BOTTOMRIGHT", t[9], "TOPLEFT")
	return t
end

-- An exchange at the top of the desk: its medallion (the gem it gives, the gem it takes), what it takes and what it
-- gives, the contracts its copies make. Lit when chosen.
local function NewTile(page, r, w)
	local from, to = ns.RARITY[r], ns.RARITY[math.min(CuratorOctoFull.Length(ns.RARITY), r + 1)]
	local b = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(b, w, DK.TILE_H)
	Hud.Panel(b, DK.TILE_H)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetPoint("TOPLEFT", 4, -4)
	b.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(b.hl, 1, 0.9, 0.6, 0.07)
	local med = 30
	b.light = b:CreateTexture(nil, "BORDER", nil, 2)
	b.light:SetTexture(octoConstants.MEDIA .. "Glow")
	b.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.light, med * 2, med * 2)
	b.light:SetPoint("CENTER", b, "LEFT", 7 + med / 2, 0)
	b.light:SetVertexColor(to.glow[1], to.glow[2], to.glow[3])
	b.light:SetAlpha(0)
	b.node = b:CreateTexture(nil, "ARTWORK")
	b.node:SetTexture(octoConstants.MEDIA .. "TrackNodeBig")
	CuratorOctoFull.SetSize(b.node, med, med)
	b.node:SetPoint("CENTER", b, "LEFT", 7 + med / 2, 0)
	b.gemTo = b:CreateTexture(nil, "ARTWORK", nil, 2)
	b.gemTo:SetTexture(octoConstants.MEDIA .. "Gem" .. math.min(CuratorOctoFull.Length(ns.RARITY), r + 1))
	CuratorOctoFull.SetSize(b.gemTo, 16, 16)
	b.gemTo:SetPoint("CENTER", b.node, "CENTER")
	b.gemFrom = b:CreateTexture(nil, "ARTWORK", nil, 3)
	b.gemFrom:SetTexture(octoConstants.MEDIA .. "Gem" .. r)
	CuratorOctoFull.SetSize(b.gemFrom, 11, 11)
	b.gemFrom:SetPoint("CENTER", b.node, "BOTTOMLEFT", 5, 5)
	local tx = 7 + med + 6
	local tw = w - tx - 8
	b.deal = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.deal:SetPoint("TOPLEFT", tx, -8)
	b.deal:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.deal, false)
	local hex = A.U.Hex
	Fit(b.deal, string.format(("|cff%s%s|r |cff9a9aa4»|r |cff%s%s|r"), hex(from.text), L[from.label], hex(to.text), L[to.label]), 10, tw)
	b.makes = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.makes:SetPoint("TOPLEFT", b.deal, "BOTTOMLEFT", 0, -3)
	b.makes:SetWidth(tw)
	CuratorOctoFull.SetWordWrap(b.makes, false)
	b.rarity, b.tw = r, tw
	function b:SetSelected(on)
		self.on = on
		self.node:SetVertexColor(on and 1 or 0.72, on and 1 or 0.72, on and 1 or 0.72)
		self.gemTo:SetAlpha(on and 1 or 0.8)
		Hud.Each(self.glow, "SetAlpha", on and 0.85 or 0)
		if not on then
			self.light:SetAlpha(0)
		end
	end
	CuratorOctoFull.SetScript(b, "OnClick", function()
		A:SetContractRarity(r)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:RungTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return b
end

-- The deed of the desk: its parchment, its head, its ring around the card it promises, the cards to change by hand and
-- the album under the ring; on its right, what comes, where from, the clauses.
local function NewDeed(page)
	local U = A.U
	local deed = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(deed, DK.DEED_W, DK.DEED_H)
	deed:SetPoint("TOPLEFT", DK.HOME_X, DK.DEED_Y)
	deed.x = DK.HOME_X
	deed.shadow = deed:CreateTexture(nil, "BACKGROUND", nil, -2)
	CuratorOctoFull.ColorTexture(deed.shadow, 0, 0, 0, 0.42)
	deed.shadow:SetPoint("TOPLEFT", 5, -7)
	deed.shadow:SetPoint("BOTTOMRIGHT", 7, -9)
	deed.glow = deed:CreateTexture(nil, "BACKGROUND", nil, -1)
	deed.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.glow:SetBlendMode("ADD")
	deed.glow:SetPoint("TOPLEFT", -60, 50)
	deed.glow:SetPoint("BOTTOMRIGHT", 60, -50)
	deed.glow:SetVertexColor(1, 0.8, 0.4)
	deed.glow:SetAlpha(0)
	deed.paper = Parchment(deed)
	-- its head, and the flourish of the parchment under it
	deed.title = U.Text(deed, 16, "")
	deed.title:SetPoint("TOP", 0, -24)
	deed.title:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.title:SetShadowOffset(0, 0)
	deed.deal = U.Text(deed, 12, "")
	deed.deal:SetPoint("TOP", deed.title, "BOTTOM", 0, -4)
	deed.deal:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.deal:SetShadowOffset(0, 0)
	deed.flourish = deed:CreateTexture(nil, "ARTWORK")
	deed.flourish:SetTexture(octoConstants.MEDIA .. "ContractDeed")
	deed.flourish:SetTexCoord(128 / 512, 384 / 512, 70 / 512, 90 / 512)
	CuratorOctoFull.SetSize(deed.flourish, 256, 20)
	deed.flourish:SetPoint("TOP", deed, "TOP", 0, -60)
	-- in the middle of the ring: the card it promises, face down, its light, the lights of the copies given, how many
	local rx, ry = DK.RING_X, DK.RING_Y
	deed.backGlow = deed:CreateTexture(nil, "ARTWORK", nil, -2)
	deed.backGlow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.backGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(deed.backGlow, 150, 150)
	deed.backGlow:SetPoint("CENTER", deed, "TOPLEFT", rx, ry)
	deed.backGlow:SetAlpha(0.35)
	deed.ring = Hud.Ring(deed, 128, "ARTWORK", -1)
	deed.ring:SetPoint("CENTER", deed, "TOPLEFT", rx, ry + 4)
	deed.ring:SetProgress(1)
	deed.ring:SetAlpha(0)
	deed.dots = {}
	for i = 1, octoConstants.DOTS do
		local glow = deed:CreateTexture(nil, "ARTWORK", nil, -1)
		glow:SetTexture(octoConstants.MEDIA .. "Glow")
		glow:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(glow, 26, 26)
		glow:SetVertexColor(1, 0.75, 0.3)
		glow:SetAlpha(0)
		local d = deed:CreateTexture(nil, "ARTWORK", nil, 0)
		d:SetTexture(octoConstants.MEDIA .. "Dot")
		CuratorOctoFull.SetSize(d, 10, 10)
		d.glow = glow
		deed.dots[i] = d
	end
	deed.back = deed:CreateTexture(nil, "ARTWORK", nil, 1)
	deed.back:SetTexture(octoConstants.MEDIA .. "Back_S")
	deed.back:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	CuratorOctoFull.SetSize(deed.back, octoConstants.BACK_W, octoConstants.BACK_H)
	deed.back:SetPoint("CENTER", deed, "TOPLEFT", rx, ry + 4)
	deed.gem = deed:CreateTexture(nil, "ARTWORK", nil, 2)
	CuratorOctoFull.SetSize(deed.gem, 20, 20)
	deed.gem:SetPoint("CENTER", deed.back, "CENTER", 0, 0)
	deed.count = U.Text(deed, 11, "")
	deed.count:SetPoint("CENTER", deed, "TOPLEFT", rx, ry - octoConstants.DOT_R - 12)
	deed.count:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.count:SetShadowOffset(0, 0)
	deed.stamp = deed:CreateTexture(nil, "OVERLAY", nil, 3)
	deed.stamp:SetTexture(octoConstants.MEDIA .. "Seal")
	CuratorOctoFull.SetSize(deed.stamp, 46, 46)
	deed.stamp:SetPoint("CENTER", deed.back, "CENTER", 0, -2)
	deed.stamp:Hide()
	deed.stampGlow = deed:CreateTexture(nil, "OVERLAY", nil, 2)
	deed.stampGlow:SetTexture(octoConstants.MEDIA .. "Glow")
	deed.stampGlow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(deed.stampGlow, 110, 110)
	deed.stampGlow:SetPoint("CENTER", deed.stamp, "CENTER")
	deed.stampGlow:SetVertexColor(1, 0.5, 0.4)
	deed.stampGlow:SetAlpha(0)
	deed.slots = {}
	for i = 1, octoConstants.SLOTS do
		deed.slots[i] = NewSlot(deed, i)
	end
	-- under the ring: the cards to change by hand (the list beside the deed), the album they are taken from
	local under = ry - octoConstants.RING_R - octoConstants.SLOT_H / 2 - 8
	deed.change = S.Button(deed, L["Change the cards"], 128, 22)
	deed.change:SetPoint("TOPRIGHT", deed, "TOPLEFT", rx - 4, under)
	CuratorOctoFull.SetScript(deed.change, "OnClick", function()
		A:ToggleContractDrawer()
	end)
	CuratorOctoFull.SetScript(deed.change, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Change the cards"], 1, 1, 1)
		GameTooltip:AddLine(L["Click: into the contract · Right click: take it back"], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(deed.change, "OnLeave", function()
		GameTooltip:Hide()
	end)
	deed.albums = S.Dropdown(deed, 172)
	deed.albums:SetPoint("TOPLEFT", deed, "TOPLEFT", rx + 4, under)
	deed.albums:SetupMenu(function(_, root)
		A:ContractAlbumsMenu(root)
	end)
	if deed.albums.SetTooltip then
		deed.albums:SetTooltip(function(tooltip)
			tooltip:AddLine(L["All albums"], 1, 1, 1)
			tooltip:AddLine(L["The cards of every album, or of one only (the arrows of the title too)."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		end)
	end
	-- on its right: what comes, where from, the clauses
	local sx, sw = DK.SIDE_X, DK.SIDE_W
	deed.how = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.how:SetPoint("TOPLEFT", sx, -90)
	deed.how:SetWidth(sw)
	CuratorOctoFull.SetWordWrap(deed.how, true)
	deed.how:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	deed.how:SetShadowOffset(0, 0)
	deed.getLabel = U.Text(deed, 11, "")
	deed.getLabel:SetJustifyH("LEFT")
	deed.getLabel:SetPoint("TOPLEFT", deed.how, "BOTTOMLEFT", 0, -12)
	deed.getLabel:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	deed.getLabel:SetShadowOffset(0, 0)
	deed.getLabel:SetText(L["You get"])
	deed.getGem = deed:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(deed.getGem, 22, 22)
	deed.getGem:SetPoint("TOPLEFT", deed.getLabel, "BOTTOMLEFT", -2, -5)
	deed.get = U.Text(deed, 15, "")
	deed.get:SetPoint("LEFT", deed.getGem, "RIGHT", 5, 0)
	deed.get:SetShadowOffset(0, 0)
	deed.from = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.from:SetPoint("TOPLEFT", deed.getGem, "BOTTOMLEFT", 2, -7)
	deed.from:SetWidth(sw)
	CuratorOctoFull.SetWordWrap(deed.from, true)
	deed.from:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	deed.from:SetShadowOffset(0, 0)
	deed.clauseIcon = deed:CreateTexture(nil, "ARTWORK")
	deed.clauseIcon:SetTexture(octoConstants.MEDIA .. "Seal")
	CuratorOctoFull.SetSize(deed.clauseIcon, 18, 18)
	deed.clauseIcon:SetPoint("TOPLEFT", deed.from, "BOTTOMLEFT", -2, -12)
	deed.clause = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.clause:SetPoint("TOPLEFT", deed.clauseIcon, "TOPRIGHT", 4, -2)
	deed.clause:SetWidth(sw - 22)
	CuratorOctoFull.SetWordWrap(deed.clause, true)
	deed.clause:SetShadowOffset(0, 0)
	deed.cond = S.Text(deed, "GameFontHighlightSmall", "LEFT")
	deed.cond:SetPoint("TOPLEFT", deed.clause, "BOTTOMLEFT", 0, -5)
	deed.cond:SetWidth(sw - 22)
	CuratorOctoFull.SetWordWrap(deed.cond, true)
	deed.cond:SetShadowOffset(0, 0)
	deed.clauseBtn = S.Button(deed, L["Fill for the clause"], sw, 20)
	deed.clauseBtn:SetPoint("TOPLEFT", deed.cond, "BOTTOMLEFT", -22, -10)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnClick", function()
		A:FillForClause()
	end)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnEnter", function(self)
		A:ClauseTooltip(self)
	end)
	CuratorOctoFull.SetScript(deed.clauseBtn, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- (the pieces of before, under their names)
	deed.seal = deed.stamp
	return deed
end

-- The list of the cards to spare beside the deed (on asking): a line a card, their order, its pages, Fill and Clear.
local function NewDrawer(page)
	local w = DK.PANEL_W
	local dr = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(dr, w, DK.DEED_H)
	dr:SetPoint("TOPLEFT", DK.PANEL_X, DK.DEED_Y)
	dr:SetFrameLevel(page:GetFrameLevel() + 30)
	dr:EnableMouse(true)
	dr.bg = Hud.Card(dr, 0.75)
	dr.title = S.Text(dr, "GameFontNormal", "LEFT")
	dr.title:SetPoint("TOPLEFT", 10, -10)
	dr.title:SetText(L["Your copies"])
	dr.close = S.Button(dr, "x", 22, 20)
	dr.close:SetPoint("TOPRIGHT", -6, -6)
	CuratorOctoFull.SetScript(dr.close, "OnClick", function()
		A:ToggleContractDrawer(false)
	end)
	dr.total = Hud.Text(dr, 13, "OUTLINE")
	dr.total:SetPoint("RIGHT", dr.close, "LEFT", -6, 0)
	dr.total:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
	dr.sorts = {}
	local sw = (w - 12 - 4) / CuratorOctoFull.Length(octoConstants.SORTS)
	for k, so in ipairs(octoConstants.SORTS) do
		local k, so = k, so; local b = CreateFrame("Button", nil, dr)
		CuratorOctoFull.SetSize(b, sw - 2, 20)
		b:SetPoint("TOPLEFT", 6 + (k - 1) * sw, -32)
		Hud.Panel(b, 20)
		b.text = S.Text(b, "GameFontNormalSmall", "CENTER")
		b.text:SetPoint("LEFT", 2, 0)
		b.text:SetPoint("RIGHT", -2, 0)
		CuratorOctoFull.SetWordWrap(b.text, false)
		Fit(b.text, L[so.label], 10, sw - 8)
		b.key = so.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			A:SetContractSort(so.key)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L[so.label], 1, 1, 1)
			GameTooltip:AddLine(L[so.tip], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		dr.sorts[k] = b
	end
	dr.rows = {}
	for i = 1, DK.ROWS do
		local row = NewRow(dr, i)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 6, DK.ROWS_Y - (i - 1) * octoConstants.ROW_H)
		dr.rows[i] = row
	end
	dr.empty = S.Text(dr, "GameFontHighlightSmall", "CENTER")
	dr.empty:SetPoint("TOP", dr, "TOP", 0, DK.ROWS_Y - 60)
	dr.empty:SetWidth(w - 30)
	CuratorOctoFull.SetWordWrap(dr.empty, true)
	dr.empty:SetTextColor(0.82, 0.82, 0.86)
	local below = DK.ROWS_Y - DK.ROWS * octoConstants.ROW_H - 2
	dr.prev = S.Arrow(dr, -1, 22)
	dr.prev:SetPoint("TOPLEFT", 10, below)
	CuratorOctoFull.SetScript(dr.prev, "OnClick", function()
		A:ContractPage(-1)
	end)
	dr.next = S.Arrow(dr, 1, 22)
	dr.next:SetPoint("TOPRIGHT", -10, below)
	CuratorOctoFull.SetScript(dr.next, "OnClick", function()
		A:ContractPage(1)
	end)
	dr.pages = S.Text(dr, "GameFontHighlightSmall", "CENTER")
	dr.pages:SetPoint("TOP", dr, "TOP", 0, below - 4)
	dr:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(dr, "OnMouseWheel", function(_, delta)
		A:ContractPage(delta > 0 and -1 or 1)
	end)
	local tools = CreateFrame("Frame", nil, dr)
	CuratorOctoFull.SetSize(tools, w - 12, 24)
	tools:SetPoint("BOTTOMLEFT", dr, "BOTTOMLEFT", 6, 10)
	tools.fill = S.Button(tools, L["Fill"], (w - 16) / 2, 24)
	tools.fill:SetPoint("LEFT", 0, 0)
	CuratorOctoFull.SetScript(tools.fill, "OnClick", function()
		A:FillContract()
	end)
	CuratorOctoFull.SetScript(tools.fill, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Fill"], 1, 1, 1)
		GameTooltip:AddLine(L["The empty places take the cards with the most copies to spare (of the albums chosen above)."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(tools.fill, "OnLeave", function()
		GameTooltip:Hide()
	end)
	tools.clear = S.Button(tools, L["Clear"], (w - 16) / 2, 24)
	tools.clear:SetPoint("RIGHT", 0, 0)
	CuratorOctoFull.SetScript(tools.clear, "OnClick", function()
		A:ClearContract()
	end)
	dr.tools = tools
	dr:Hide()
	return dr
end

-- The register beside the deed (on asking): the last contracts signed, a page of them.
local function NewRegister(page)
	local w = DK.PANEL_W
	local reg = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(reg, w, DK.DEED_H)
	reg:SetPoint("TOPLEFT", DK.PANEL_X, DK.DEED_Y)
	reg:SetFrameLevel(page:GetFrameLevel() + 32)
	reg:EnableMouse(true)
	reg:EnableMouseWheel(true)
	reg.bg = Hud.Card(reg, 0.75)
	reg.fill = reg:CreateTexture(nil, "BACKGROUND", nil, -1)
	reg.fill:SetPoint("TOPLEFT", 3, -3)
	reg.fill:SetPoint("BOTTOMRIGHT", -3, 3)
	CuratorOctoFull.ColorTexture(reg.fill, 0.04, 0.03, 0.03, 0.96)
	reg.title = S.Text(reg, "GameFontNormal", "LEFT")
	reg.title:SetPoint("TOPLEFT", 10, -10)
	reg.title:SetText(L["The register"])
	reg.close = S.Button(reg, "x", 22, 20)
	reg.close:SetPoint("TOPRIGHT", -6, -6)
	CuratorOctoFull.SetScript(reg.close, "OnClick", function()
		A:ToggleRegister(false)
	end)
	reg.lines = {}
	for i = 1, DK.REG_ROWS do
		local l = NewRegLine(reg, i)
		l:ClearAllPoints()
		l:SetPoint("TOPLEFT", 8, -34 - (i - 1) * DK.REG_ROW_H)
		l:SetHeight(DK.REG_ROW_H - 4)
		reg.lines[i] = l
	end
	reg.empty = S.Text(reg, "GameFontHighlightSmall", "CENTER")
	reg.empty:SetPoint("TOP", reg, "TOP", 0, -90)
	reg.empty:SetWidth(w - 30)
	CuratorOctoFull.SetWordWrap(reg.empty, true)
	reg.empty:SetTextColor(0.82, 0.82, 0.86)
	reg.note = S.Text(reg, "GameFontDisableSmall", "CENTER")
	reg.note:SetPoint("BOTTOM", reg, "BOTTOM", 0, 40)
	reg.note:SetWidth(w - 20)
	reg.prev = S.Arrow(reg, -1, 22)
	reg.prev:SetPoint("BOTTOMLEFT", 10, 10)
	CuratorOctoFull.SetScript(reg.prev, "OnClick", function()
		A:RegisterPage(-1)
	end)
	reg.next = S.Arrow(reg, 1, 22)
	reg.next:SetPoint("BOTTOMRIGHT", -10, 10)
	CuratorOctoFull.SetScript(reg.next, "OnClick", function()
		A:RegisterPage(1)
	end)
	reg.pages = S.Text(reg, "GameFontHighlightSmall", "CENTER")
	reg.pages:SetPoint("BOTTOM", reg, "BOTTOM", 0, 15)
	CuratorOctoFull.SetScript(reg, "OnMouseWheel", function(_, delta)
		A:RegisterPage(delta > 0 and -1 or 1)
	end)
	reg:Hide()
	return reg
end

function A:BuildDesk()
	local f = self.frame
	if f.ctb then
		return
	end
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 6)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.ctb = page
	-- the desk: its wood under the exchanges, its blotter of leather under the deed (ContractDesk: the blotter from 236
	-- to 748 of its 1024 points)
	local function Wood(u0, u1, v0, v1)
		local t = page:CreateTexture(nil, "BACKGROUND", nil, -6)
		t:SetTexture(octoConstants.MEDIA .. "ContractDesk")
		t:SetTexCoord(u0, u1, v0, v1)
		return t
	end
	local bx0, bx1 = DK.HOME_X - 10, DK.HOME_X + DK.DEED_W + 10
	local top, foot = DK.DEED_Y + 8, DK.DEED_Y - DK.DEED_H - 6
	page.desk = Wood(0, 236 / 1024, 0, 0.14)
	page.desk:SetPoint("TOPLEFT", -4, 2)
	page.desk:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", 4, top)
	page.deskL = Wood(0, 236 / 1024, 0.14, 0.9)
	page.deskL:SetPoint("TOPLEFT", page, "TOPLEFT", -4, top)
	page.deskL:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", bx0, foot)
	page.blotter = Wood(236 / 1024, 748 / 1024, 0, 1)
	page.blotter:SetPoint("TOPLEFT", page, "TOPLEFT", bx0, top)
	page.blotter:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", bx1, foot)
	page.deskR = Wood(748 / 1024, 1, 0.14, 0.9)
	page.deskR:SetPoint("TOPLEFT", page, "TOPLEFT", bx1, top)
	page.deskR:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", 4, foot)
	-- (the foot: the wood again, under the copy kept, how many at once and Sign)
	page.deskFoot = Wood(0, 236 / 1024, 0.9, 1)
	page.deskFoot:SetPoint("TOPLEFT", page, "TOPLEFT", -4, foot)
	page.deskFoot:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 4, -2)
	-- at the top: the four exchanges, then the finishes and the register
	local tw = (octoConstants.PAGE_W - (K.LAST - 1) * DK.TILE_GAP) / K.LAST
	page.tiles = {}
	for r = 1, K.LAST do
		local b = NewTile(page, r, tw)
		b:SetPoint("TOPLEFT", (r - 1) * (tw + DK.TILE_GAP), -2)
		page.tiles[r] = b
	end
	-- (the names of before: the rungs of the ladder, its rail)
	page.rungs = page.tiles
	page.rail = page:CreateTexture(nil, "BACKGROUND")
	page.rail:Hide()
	page.fin = {}
	for _, finish in ipairs(K.FINISHES) do
		local _, finish = _, finish; local b = ns.CopiesUI.Chip(page, function()
			A:SetContractFinish(finish)
		end)
		b:SetHeight(DK.CHIP_H)
		b.finish = finish
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:AddLine(L[octoConstants.FINISH_LABEL[finish]], 1, 1, 1)
			GameTooltip:AddLine(L["Thunderforged and titanforged cards only go with cards of their own finish, and give a card of that finish."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		page.fin[finish] = b
	end
	page.regButton = S.Button(page, L["The register"], 150, DK.CHIP_H)
	page.regButton:SetPoint("TOPRIGHT", 0, DK.CHIPS_Y)
	CuratorOctoFull.SetScript(page.regButton, "OnClick", function()
		A:ToggleRegister()
	end)
	CuratorOctoFull.SetScript(page.regButton, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L["The register"], 1, 1, 1)
		GameTooltip:AddLine(L["The last contracts you signed, and what came of them."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(page.regButton, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- in the middle: the deed
	local deed = NewDeed(page)
	page.band = deed
	page.get, page.odds = deed, deed.from
	-- at the foot: the copy kept of each card, the talents of the Merchant, how many at once, Sign and its quill
	local keep = S.Check(page, L["Keep one copy of each card"])
	keep:SetPoint("BOTTOMLEFT", 0, 4)
	keep.Text:SetWidth(230)
	CuratorOctoFull.SetWordWrap(keep.Text, true)
	CuratorOctoFull.SetScript(keep, "OnClick", function()
		ns.db.keepOne = not ns.db.keepOne
		K:Check(A:Contract(), ns.db.keepOne)
		ns.Play(ns.SND.click)
		A:Refresh()
	end)
	CuratorOctoFull.SetScript(keep, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Keep one copy of each card"], 1, 1, 1)
		GameTooltip:AddLine(L["The album keeps the finest copy of each card (titanforged, then thunderforged); only the others go into contracts."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(keep, "OnLeave", function()
		GameTooltip:Hide()
	end)
	page.keep = keep
	deed.acts = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(deed.acts, 4 * 30, 26)
	deed.acts:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 270, 6)
	deed.actButtons = {}
	for _, key in ipairs({ "favor", "master", "tailor", "alchemist" }) do
		local id = K.ACTIVES[key]
		if id and ns.Talents and ns.Talents.BY[id] then
			deed.actButtons[CuratorOctoFull.Length(deed.actButtons) + 1] = NewActive(deed.acts, key)
		end
	end
	page.sign = Hud.ClaimButton(page, 176, 32, L["Sign the contract"])
	page.sign:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 2)
	page.sign.label = page.sign.text
	CuratorOctoFull.SetScript(page.sign, "OnClick", function()
		A:SignContract()
	end)
	page.sign.tip = function(self)
		if ns.Reroll and ns.Reroll:Blocks("contracts") then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Sign the contract"], 1, 1, 1)
			GameTooltip:AddLine(ns.Reroll:WhyNot("contracts"), 1, 0.62, 0.45, true)
			GameTooltip:Show()
		end
	end
	if page.sign.SetMotionScriptsWhileDisabled then
		page.sign:SetMotionScriptsWhileDisabled(true)
	end
	page.sign.quill = page.sign:CreateTexture(nil, "OVERLAY", nil, 2)
	page.sign.quill:SetTexture(octoConstants.MEDIA .. "Quill")
	CuratorOctoFull.SetSize(page.sign.quill, 30, 30)
	page.sign.quill:SetPoint("CENTER", page.sign, "LEFT", 4, 6)
	local mult = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(mult, 150, 26)
	mult:SetPoint("RIGHT", page.sign, "LEFT", -16, 0)
	mult.max = S.Button(mult, L["Max"], 50, 22)
	mult.max:SetPoint("RIGHT", 0, 0)
	CuratorOctoFull.SetScript(mult.max, "OnClick", function()
		A:ContractMax()
	end)
	CuratorOctoFull.SetScript(mult.max, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Max"], 1, 1, 1)
		GameTooltip:AddLine(K:Max() == K.MAX and L["As many contracts as your copies to spare make (five at most), filled at once."]
			or string.format(L["As many contracts as your copies to spare make (%d at most), filled at once."], K:Max()), 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(mult.max, "OnLeave", function()
		GameTooltip:Hide()
	end)
	mult.next = S.Arrow(mult, 1, 22)
	mult.next:SetPoint("RIGHT", mult.max, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(mult.next, "OnClick", function()
		A:SetContractCount(A:Contract().n + 1)
	end)
	mult.text = Hud.Text(mult, 15, "OUTLINE")
	mult.text:SetPoint("RIGHT", mult.next, "LEFT", -6, 0)
	mult.text:SetTextColor(1, 0.92, 0.75)
	mult.prev = S.Arrow(mult, -1, 22)
	mult.prev:SetPoint("RIGHT", mult.text, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(mult.prev, "OnClick", function()
		A:SetContractCount(A:Contract().n - 1)
	end)
	deed.mult = mult
	-- beside the deed, on asking: the cards to choose, the register
	page.drawer = NewDrawer(page)
	page.register = NewRegister(page)
	page.grid = page.drawer.rows
	-- the exchange chosen breathes, the seal of a full deed glows, the cards move
	page.t = 0
	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		A.ctT = (A.ctT or 0) + elapsed
		for _, b in ipairs(self.tiles) do
			if b.on then
				b.light:SetAlpha(0.45 + 0.2 * math.sin(self.t * 3))
			end
		end
		local d = self.band
		if d.full then
			d.stampGlow:SetAlpha(0.45 + 0.3 * math.sin(self.t * 4))
			d.backGlow:SetAlpha(0.55 + 0.2 * math.sin(self.t * 4))
		end
		if self.drawer:IsShown() then
			for _, row in ipairs(self.drawer.rows) do
				if row:IsShown() and row.card:IsShown() then
					row.card:Tick(A.ctT)
				end
			end
		end
		for _, sl in ipairs(d.slots) do
			if sl.card:IsShown() then
				sl.card:Tick(A.ctT)
			end
		end
	end)
	-- (put away: the list and the register with it, the deed back in the middle)
	CuratorOctoFull.SetScript(page, "OnHide", function()
		if A.ctPanel then
			A:DeskPanel(nil)
		end
	end)
end

-- The deed steps aside for the list of the cards or the register (on: which; nil: back in the middle).
function A:DeskPanel(which)
	local page = self.frame and self.frame.ctb
	if not page then
		return
	end
	self.ctPanel = which
	CuratorOctoFull.SetShown(page.drawer, which == "drawer")
	CuratorOctoFull.SetShown(page.register, which == "register")
	local deed = page.band
	local to = which and 0 or DK.HOME_X
	if deed.slide then
		ns.CancelTween(deed.slide)
		deed.slide = nil
	end
	local from = deed.x or DK.HOME_X
	if from == to or not deed:IsVisible() then
		deed.x = to
		deed:SetPoint("TOPLEFT", page, "TOPLEFT", to, DK.DEED_Y)
		return
	end
	deed.slide = ns.Tween(0.25, function(e)
		deed.x = from + (to - from) * e
		deed:SetPoint("TOPLEFT", page, "TOPLEFT", deed.x, DK.DEED_Y)
	end, function()
		deed.slide = nil
		deed.x = to
		deed:SetPoint("TOPLEFT", page, "TOPLEFT", to, DK.DEED_Y)
	end, Ease.outQuad, A)
end

-- The list of the cards beside the deed: shown, or put away (on: nil, the other way round).
function A:ToggleContractDrawer(on)
	if on == nil then
		on = self.ctPanel ~= "drawer"
	end
	ns.Play(on and ns.SND.open or ns.SND.close)
	self:DeskPanel(on and "drawer" or nil)
	self:Refresh()
end

-- The exchanges at the top: the copies to spare of each rarity in this finish, the contracts they make; the one chosen
-- lit.
function A:PaintTiles(page, ct, keep)
	local spare = K:SpareByRarity(ct.finish, keep)
	for r, b in ipairs(page.tiles) do
		b.found = spare[r]
		local need = K:SizeOf(r, ct.finish)
		local text, enough = Makes(spare[r], need)
		Fit(b.makes, text, 10, b.tw)
		if enough then
			b.makes:SetTextColor(octoConstants.GOLDEN[1], octoConstants.GOLDEN[2], octoConstants.GOLDEN[3])
		else
			b.makes:SetTextColor(octoConstants.DIM[1], octoConstants.DIM[2], octoConstants.DIM[3])
		end
		b:SetSelected(r == ct.rarity)
	end
end

-- The finishes, with the copies to spare of the rarity chosen; the register, how many it keeps.
function A:PaintDeskChips(page, ct, keep)
	local x = 0
	for _, fin in ipairs(K.FINISHES) do
		local b = page.fin[fin]
		local n = K:SpareByRarity(fin, keep)[ct.rarity]
		local on = fin == ct.finish
		ns.CopiesUI.PaintChip(b, L[fin == "normal" and octoConstants.FINISH_LABEL[fin] or octoConstants.FINISH_NAME[fin]] .. "  |cffbfa873" .. ns.Num(n) .. "|r", nil, on,
			n == 0 and not on)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", page, "TOPLEFT", x, DK.CHIPS_Y)
		x = x + b:GetWidth() + 6
	end
	local log = K:Register()
	page.regButton:SetText(CuratorOctoFull.Length(log) > 0 and string.format(("%s (%d)"), L["The register"], CuratorOctoFull.Length(log)) or L["The register"])
end

-- The deed of the desk: its head, its places in the ring, the card it promises (sealed when full), what comes and
-- where from, the clauses; how many at once and Sign at the foot.
function A:PaintDesk(page, ct, cap, size, up, finish)
	local deed = page.band
	deed.title:SetText(ct.n > 1 and string.format(L["%d exchange contracts"], ct.n) or L["Exchange contract"])
	Fit(deed.deal, Deal(ct.rarity, ct.n, true, size, up), 12, DK.DEED_W - 90)
	local groups
	if ct.n > 1 then
		groups = K:Groups(ct)
	else
		groups = {}
		for i, key in ipairs(ct.list) do
			groups[i] = { card = ns.Cards[key], n = 1, at = i }
		end
	end
	local full = ct.count == cap
	local places = ct.n > 1 and octoConstants.SLOTS or math.min(octoConstants.SLOTS, cap)
	for i, sl in ipairs(deed.slots) do
		CuratorOctoFull.SetShown(sl, i <= places)
		local x, y = DeskRingXY(i, places)
		sl:ClearAllPoints()
		sl:SetPoint("CENTER", deed, "TOPLEFT", x, y)
	end
	for i, sl in ipairs(deed.slots) do
		local g = groups[i]
		local c = sl.card
		sl.rest = nil
		if i == octoConstants.SLOTS and CuratorOctoFull.Length(groups) > octoConstants.SLOTS then
			local rest = 0
			for k = octoConstants.SLOTS, CuratorOctoFull.Length(groups) do
				rest = rest + groups[k].n
			end
			sl.rest = CuratorOctoFull.Length(groups) - octoConstants.SLOTS + 1
			g = groups[CuratorOctoFull.Length(groups)]
			sl.more:SetText("+" .. rest)
		else
			sl.more:SetText("")
		end
		sl.group = g
		if g then
			local card = g.card
			local wear = self:GivenWear(ct, card)
			local wk = wear and (tostring(wear.seed) .. table.concat(wear.m, "") .. tostring(wear.x or "") .. tostring(wear.a or "")) or ""
			if c.card ~= card or c.ctFinish ~= ct.finish or c.ctWear ~= wk or not c:IsShown() then
				c:Show()
				c:SetCard(card, { owned = true, finish = finish, wear = wear })
				c:ShowSide("front")
				c.ctFinish, c.ctWear = ct.finish, wk
			end
			c:SetAlpha(sl.rest and 0.35 or 1)
			c.phase = i * 0.41
			sl.plus:Hide()
			sl.bg:SetAlpha(1)
			sl.n:SetText((not sl.rest and g.n > 1) and ("x" .. g.n) or "")
		else
			c:Hide()
			c.card = nil
			CuratorOctoFull.SetShown(sl.plus, not full)
			sl.bg:SetAlpha(full and 0.45 or 1)
			sl.n:SetText("")
		end
	end
	-- the card it promises: its gem, its light, the lights of the copies given, sealed once full
	local r2 = ns.RARITY[up]
	deed.gem:SetTexture(octoConstants.MEDIA .. "Gem" .. up)
	deed.backGlow:SetVertexColor(r2.glow[1], r2.glow[2], r2.glow[3])
	if not full then
		deed.backGlow:SetAlpha(0.2 + 0.25 * ct.count / math.max(1, cap))
	end
	local dots = ct.n > 1 and octoConstants.DOTS or math.min(octoConstants.DOTS, cap)
	local lit = ct.n > 1 and math.floor(octoConstants.DOTS * ct.count / math.max(1, cap)) or ct.count
	for i, d in ipairs(deed.dots) do
		local a = math.pi / 2 - (i - 1) * 2 * math.pi / math.max(1, dots)
		d:ClearAllPoints()
		d:SetPoint("CENTER", deed, "TOPLEFT", DK.RING_X + octoConstants.DOT_R * math.cos(a), DK.RING_Y + 4 + octoConstants.DOT_R * math.sin(a))
		d.glow:ClearAllPoints()
		d.glow:SetPoint("CENTER", d, "CENTER")
		CuratorOctoFull.SetShown(d, i <= dots)
		local on = i <= lit
		if on then
			d:SetVertexColor(1, 0.84, 0.4)
			d:SetAlpha(1)
		else
			d:SetVertexColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
			d:SetAlpha(0.5)
		end
		d.glow:SetAlpha((on and i <= dots) and 0.55 or 0)
	end
	deed.ring:SetVertexColor(1, 0.86, 0.42)
	if deed.ringTw then
		ns.CancelTween(deed.ringTw)
		deed.ringTw = nil
	end
	if full and not deed.full and deed:IsVisible() then
		deed.ring:SetAlpha(0)
		deed.ringTw = ns.Tween(0.45, function(e)
			deed.ring:SetAlpha(e)
		end, function()
			deed.ringTw = nil
		end, Ease.outQuad, A)
	elseif full then
		deed.ring:SetAlpha(1)
	else
		deed.ring:SetAlpha(0)
	end
	Fit(deed.count, full and L["Ready to sign"] or string.format(L["%d / %d cards"], ct.count, cap), 11, 92)
	if full and not deed.full then
		if deed:IsVisible() then
			Hud.Stamp(deed.stamp, 46, 0.05, function()
				ns.Play(ns.SND.seal)
				Hud.Burst(deed.stamp, { 1, 0.5, 0.4 }, 12, 100, 14)
			end, A)
		else
			CuratorOctoFull.SetSize(deed.stamp, 46, 46)
			deed.stamp:SetAlpha(1)
			deed.stamp:Show()
		end
	elseif not full then
		deed.stamp:Hide()
		deed.stampGlow:SetAlpha(0)
	end
	deed.full = full
	deed.glow:SetAlpha(full and 0.3 or 0.1)
	deed.glow:SetVertexColor(r2.glow[1], r2.glow[2], r2.glow[3])
	-- the album the cards are taken from, the cards changed by hand
	deed.albums:GenerateMenu()
	deed.change:SetText(self.ctPanel == "drawer" and L["Close"] or L["Change the cards"])
	-- on its right: the cards given, chosen by itself or by hand; what comes, where from
	if ct.count == 0 and CuratorOctoFull.Length(K:Eligible(ct.rarity, ct.finish, ns.db.keepOne, self.ctAlbum)) == 0 then
		-- (none to spare in this rarity and finish: said, nothing to change)
		deed.how:SetText(L["No copy to spare in this rarity and finish yet. Duplicates come with the boosters!"])
	elseif ct.count == 0 then
		deed.how:SetText(size == 10 and L["Choose ten cards of the same rarity and finish: click a card to put it in the contract."]
			or string.format(L["Choose %d cards of the same rarity and finish: click a card to put it in the contract."], size))
	else
		deed.how:SetText(ct.manual and L["The cards you chose"] or L["Your least precious duplicates, chosen for you"])
	end
	deed.getGem:SetTexture(octoConstants.MEDIA .. "Gem" .. up)
	deed.get:SetText(ct.n > 1 and string.format(("%d × %s"), ct.n, L[r2.label]) or L[r2.label])
	deed.get:SetTextColor(r2.ink[1], r2.ink[2], r2.ink[3])
	local odds = K:Odds(ct)
	local tailor = ct.tailor and ns.SeriesByKey(ct.tailor)
	if tailor then
		for _, o in ipairs(odds) do
			if o.series == tailor and CuratorOctoFull.Length(tailor.byRarity[up]) > 0 then
				odds = { { series = tailor, share = 1 } }
				break
			end
		end
	end
	local parts = {}
	for i, o in ipairs(odds) do
		if i <= 3 then
			parts[CuratorOctoFull.Length(parts) + 1] = string.format(("%s %d %%"), C:SeriesName(o.series), math.floor(o.share * 100 + 0.5))
		end
	end
	if CuratorOctoFull.Length(odds) > 3 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format(L["+%d more albums"], CuratorOctoFull.Length(odds) - 3)
	end
	if ct.count == 0 then
		deed.from:SetText("")
		deed.from.summary = nil
	else
		deed.from:SetText(string.format((ct.n > 1 and L["The new cards come from: %s"] or L["The new card comes from: %s"]), table.concat(parts, " · ")))
		local all = {}
		for _, o in ipairs(odds) do
			all[CuratorOctoFull.Length(all) + 1] = string.format(("%s %d%%"), C:SeriesName(o.series), math.floor(o.share * 100 + 0.5))
		end
		deed.from.summary = string.format(L["The new card comes from: %s"], table.concat(all, ", "))
	end
	-- the clause of the collection
	local s, missing = K:Clause(ct)
	local upName = L[r2.label]
	local m = missing and CuratorOctoFull.Length(missing) or 0
	local ok = s and m > 0
	if ok then
		local n, name, text = ct.n or 1, C:SeriesName(s)
		if m == 1 then
			text = string.format((n > 1 and L["Collection clause: one of the new cards will be the %s card of %s still missing from your album."]
				or L["Collection clause: the new card will be the %s card of %s still missing from your album."]), upName, name)
		elseif n > m then
			text = string.format(L["Collection clause: %d of the new cards will be the %s cards of %s missing from your album."], m, upName, name)
		elseif n > 1 then
			text = string.format(L["Collection clause: the new cards will be among the %d %s cards of %s missing from your album."], m, upName, name)
		else
			text = string.format(L["Collection clause: the new card will be one of the %d %s cards of %s missing from your album."], m, upName, name)
		end
		deed.clause:SetText(text)
		deed.clause:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	elseif s then
		deed.clause:SetText(string.format(L["Collection clause: your album already has every %s card of %s."], upName, C:SeriesName(s)))
		deed.clause:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	else
		deed.clause:SetText(L["Collection clause: copies of a single album give a card that album is missing."])
		deed.clause:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	end
	deed.clauseIcon:SetDesaturated(not ok)
	deed.clauseIcon:SetAlpha(ok and 1 or 0.55)
	deed.clause.ok = ok and true or false
	local CP = ns.Copies
	local all, n = ct.count > 0, 0
	for key, ids in pairs(ct.ids or {}) do
		for _, id in ipairs(ids) do
			n = n + 1
			local rec = CP and CP:Get(key, id)
			if not (rec and CP.Grade(rec)) then
				all = false
			end
		end
	end
	if all and n == ct.count then
		deed.cond:SetText(L["Clause of the experts: all appraised, it comes appraised."])
		deed.cond:SetTextColor(octoConstants.GREEN[1], octoConstants.GREEN[2], octoConstants.GREEN[3])
	else
		deed.cond:SetText(L["Clause of the condition: the average wear of the copies given."])
		deed.cond:SetTextColor(octoConstants.INK_SOFT[1], octoConstants.INK_SOFT[2], octoConstants.INK_SOFT[3])
	end
	local can = not ok and K:ClauseAlbum(ct.rarity, ct.finish, ns.db.keepOne) ~= nil and not K:Single(ct)
	local rr = ns.Reroll ~= nil and ns.Reroll:Blocks("contracts")
	if rr then
		deed.clause:SetText(ns.Reroll:WhyNot("contracts"))
		deed.clause:SetTextColor(0.62, 0.14, 0.1)
		deed.clauseIcon:SetDesaturated(true)
		deed.clauseIcon:SetAlpha(0.55)
		deed.clause.ok = false
		can = false
	end
	CuratorOctoFull.SetShown(deed.clauseBtn, can and true or false)
	-- how many at once, the talents of the Merchant, Sign
	local keep = ns.db.keepOne
	local most = K:MaxCount(ct, keep, self.ctAlbum)
	local mult = deed.mult
	mult.text:SetText("x" .. ct.n)
	mult.prev:SetEnabled(ct.n > 1)
	mult.next:SetEnabled(ct.n < (K:Single(ct) and 1 or K:Max()))
	local any = CuratorOctoFull.Length(K:Eligible(ct.rarity, ct.finish, keep, self.ctAlbum)) > 0
	mult.max:SetEnabled(any and (most > 1 or ct.count < cap))
	self:PaintContractActives()
	local confirming = full and not rr and self.ctConfirm and GetTime() - self.ctConfirm < 4
	page.sign:SetLabel(confirming and L["Confirm?"] or (ct.n > 1 and string.format(L["Sign the %d contracts"], ct.n) or L["Sign the contract"]))
	local signs = full and not rr
	page.sign:SetEnabled(signs)
	page.sign:SetPulse(signs)
	page.sign.quill:SetDesaturated(not signs)
	page.sign.quill:SetAlpha(signs and 1 or 0.6)
end

-- The list of the cards beside the deed (when shown): the cards with copies to spare (of the album chosen), in its
-- order, a page of them; Fill and Clear.
function A:PaintDeskDrawer(page, ct, keep, finish)
	local dr = page.drawer
	if not dr:IsShown() then
		return
	end
	local list = self:ContractList(ct, keep)
	local total = 0
	for _, it in ipairs(list) do
		total = total + it.spare
	end
	dr.total:SetText(ns.Num(total))
	dr.total.label = string.format(L["Copies to spare: %d"], total)
	for _, b in ipairs(dr.sorts) do
		local on = (self.ctSort or "count") == b.key
		Hud.Each(b.glow, "SetAlpha", on and 0.8 or 0)
		local col = on and { 1, 1, 1 } or S.GOLD
		b.text:SetTextColor(col[1], col[2], col[3])
	end
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(list) / DK.ROWS))
	self.ctPage = math.max(1, math.min(self.ctPage or 1, pages))
	for i, row in ipairs(dr.rows) do
		local it = list[(self.ctPage - 1) * DK.ROWS + i]
		if it then
			row:Show()
			local c = row.card
			local wear = self:NextWear(ct, it.card)
			local wk = wear and (tostring(wear.seed) .. table.concat(wear.m, "") .. tostring(wear.x or "") .. tostring(wear.a or "")) or ""
			if c.card ~= it.card or c.ctFinish ~= ct.finish or c.ctWear ~= wk or not c:IsShown() then
				c:Show()
				c:SetCard(it.card, { owned = true, finish = finish, wear = wear })
				c:ShowSide("front")
				c.ctFinish, c.ctWear = ct.finish, wk
			end
			c.phase = i * 0.29
			local rc = ns.RARITY[it.card.rarity].text
			S.Fit(row.name, C:Name(it.card) or "?", DK.PANEL_W - 12 - (8 + (octoConstants.ROW_H - 6) * A.U.CW / A.U.CH + 6) - 40, 11, 8)
			row.name:SetTextColor(rc[1], rc[2], rc[3])
			S.Fit(row.album, C:SeriesName(it.card.series), DK.PANEL_W - 12 - (8 + (octoConstants.ROW_H - 6) * A.U.CW / A.U.CH + 6) - 40, 10, 8)
			local used = ct.picks[it.card.key] or 0
			local left = it.spare - used
			row.left:SetText("x" .. left)
			row.used:SetText(used > 0 and ("+" .. used) or "")
			row:SetAlpha(left > 0 and 1 or 0.5)
			row.item = it
			self:PaintRow(row, row:IsMouseOver())
		else
			row:Hide()
			row.card:Hide()
			row.card.card, row.item = nil, nil
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		dr.empty:SetText(L["No copy to spare in this rarity and finish yet. Duplicates come with the boosters!"])
	else
		dr.empty:SetText("")
	end
	dr.pages:SetText(string.format(("%d / %d"), self.ctPage, pages))
	dr.prev:SetEnabled(self.ctPage > 1)
	dr.next:SetEnabled(self.ctPage < pages)
	local cap = K:Capacity(ct)
	dr.tools.fill:SetEnabled(ct.count < cap and CuratorOctoFull.Length(list) > 0)
	dr.tools.clear:SetEnabled(ct.count > 0)
end

-------------------------------------------------------------------------------
-- The scene of the contract
-------------------------------------------------------------------------------
local P = 380        -- the parchment
octoConstants.CT_Y = -6      -- its height on the screen (from the centre)
octoConstants.IN_SCALE = 0.72
-- the part of the parchment between its own rods (the rods of the scene roll it)
octoConstants.PAPER_V0, octoConstants.PAPER_V1 = 0.07, 0.93
-- how charged the scene is, by the rarity of the cards promised (2 uncommon ... 6 mythic): the dark,
-- the light of the parchment, the beats of the heart before the seal, lightning, rays
octoConstants.TENSION = {
	[2] = { dark = 0.15, glow = 0.25, beats = 0 },
	[3] = { dark = 0.3, glow = 0.35, beats = 1 },
	[4] = { dark = 0.5, glow = 0.45, beats = 2, circle = true, rays = 0.25 },
	-- (1.13.0, after its second test: a legendary card at most, the summit of the contracts: the gong rings for it)
	[5] = { dark = 0.72, glow = 0.6, beats = 4, circle = true, rays = 0.5, bolts = true, gong = true },
	[6] = { dark = 0.78, glow = 0.65, beats = 4, circle = true, rays = 0.5, bolts = true, gong = true },
}
-- the fire that eats the parchment: gold, crimson and gold for the legendary cards (the summit of the contracts)
octoConstants.FIRE = { { 1, 0.72, 0.25 }, [5] = { 1, 0.42, 0.3 }, [6] = { 1, 0.42, 0.3 } }
-- (1.14.0, after its second test) a contract of the cards of the cases (B.mode "caseContract", UI/CaseContract.lua): as
-- charged as a contract of the boosters, by the rank it gives (a restricted card as a rare one, a classified card as an
-- epic one, a covert card, the summit of their contracts, as a legendary one)
octoConstants.CASE_LEVEL = { [2] = 3, [3] = 4, [4] = 5 }

-- How charged the scene of the contract shown is (the rarity of the boosters it is as charged as).
local function Level(self)
	local r = self.result
	if self.mode == "caseContract" then
		return octoConstants.CASE_LEVEL[r and r.up or 2] or 3
	end
	return math.min(CuratorOctoFull.Length(ns.RARITY), (r and (r.up or (r.rarity + 1))) or 2)
end

function B:BuildContractScene()
	local s = self.frame
	if s.ct then
		return
	end
	local ct = CreateFrame("Frame", nil, s)
	ct:SetAllPoints()
	ct:SetFrameLevel(s:GetFrameLevel() + 20)
	ct:Hide()
	s.ct = ct
	-- the parchment opens between its rods: a window that grows from its middle
	local roll = CreateFrame("Frame", nil, ct)
	CuratorOctoFull.SetSize(roll, P, P)
	roll:SetPoint("CENTER", s, "CENTER", 0, octoConstants.CT_Y)
	if roll.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(roll, true)
	end
	ct.roll = roll
	-- the parchment, its texts and what burns it away (the mask is in the same frame)
	local paper = CreateFrame("Frame", nil, roll)
	CuratorOctoFull.SetSize(paper, P, P)
	paper:SetPoint("CENTER", s, "CENTER", 0, octoConstants.CT_Y)
	paper.glow = ct:CreateTexture(nil, "BACKGROUND")
	paper.glow:SetTexture(octoConstants.MEDIA .. "Glow")
	paper.glow:SetBlendMode("ADD")
	paper.glow:SetPoint("CENTER", s, "CENTER", 0, octoConstants.CT_Y)
	CuratorOctoFull.SetSize(paper.glow, P * 1.6, P * 1.6)
	paper.glow:SetVertexColor(1, 0.8, 0.5)
	paper.glow:SetAlpha(0)
	paper.tex = paper:CreateTexture(nil, "ARTWORK")
	paper.tex:SetAllPoints()
	paper.tex:SetTexture(octoConstants.MEDIA .. "Contract")
	paper.tex:SetTexCoord(0, 1, octoConstants.PAPER_V0, octoConstants.PAPER_V1)
	paper.mask = CuratorOctoFull.CreateMaskTexture(paper)
	paper.mask:SetTexture(octoConstants.MEDIA .. "BurnMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	-- the burning line is in the middle of the mask: three parchments high, it covers the whole
	-- sheet while the line is still under it, and the glowing edge (an eighth of the mask) follows it
	CuratorOctoFull.SetSize(paper.mask, P * 0.8, P * 3)
	CuratorOctoFull.AddMaskTexture(paper.tex, paper.mask)
	paper.edge = paper:CreateTexture(nil, "OVERLAY", nil, 3)
	paper.edge:SetTexture(octoConstants.MEDIA .. "BurnEdge")
	paper.edge:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(paper.edge, P * 0.8, P * 3 / 8)
	paper.edge:Hide()
	-- the light of the cards melted into it
	paper.inner = paper:CreateTexture(nil, "ARTWORK", nil, 1)
	paper.inner:SetTexture(octoConstants.MEDIA .. "Glow")
	paper.inner:SetBlendMode("ADD")
	paper.inner:SetPoint("CENTER", 0, 10)
	CuratorOctoFull.SetSize(paper.inner, P * 0.8, P * 0.8)
	paper.inner:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(paper.inner, paper.mask)
	paper.title = paper:CreateFontString(nil, "OVERLAY")
	ns.SetFont(paper.title, 19)
	paper.title:SetPoint("CENTER", paper, "TOP", 0, -P * 0.13)
	paper.title:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	paper.line = paper:CreateFontString(nil, "OVERLAY")
	ns.SetFont(paper.line, 14)
	paper.line:SetPoint("CENTER", paper, "TOP", 0, -P * 0.25)
	paper.line:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	-- how many contracts at once, written big in ink
	paper.mult = paper:CreateFontString(nil, "OVERLAY")
	ns.SetFont(paper.mult, 42)
	paper.mult:SetPoint("CENTER", paper, "CENTER", 0, -12)
	paper.mult:SetTextColor(octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3], 0.85)
	paper.seal = paper:CreateTexture(nil, "OVERLAY", nil, 2)
	paper.seal:SetTexture(octoConstants.MEDIA .. "Seal")
	paper.seal:Hide()
	ct.paper = paper
	-- its rods, at the edges of the window
	ct.rodTop = ct:CreateTexture(nil, "OVERLAY", nil, 4)
	ct.rodTop:SetTexture(octoConstants.MEDIA .. "ScrollRod")
	CuratorOctoFull.SetSize(ct.rodTop, P + 52, 34)
	ct.rodBot = ct:CreateTexture(nil, "OVERLAY", nil, 4)
	ct.rodBot:SetTexture(octoConstants.MEDIA .. "ScrollRod")
	CuratorOctoFull.SetSize(ct.rodBot, P + 52, 34)
	-- the cards given
	ct.cards = {}
	for i = 1, K.SIZE do
		local c = ns.NewCard(ct, "small")
		c:EnableMouse(false)
		c:Hide()
		ct.cards[i] = c
	end
	CuratorOctoFull.SetScript(ct, "OnUpdate", function()
		for _, c in ipairs(ct.cards) do
			if c:IsShown() then
				c:Tick(B.t or 0)
			end
		end
	end)
	-- a click during the ceremony goes straight to the new cards (hooked: the forge of the titans
	-- listens too)
	s:HookScript("OnMouseDown", function()
		if B.state == "contract" then
			B:ContractSkip()
		end
	end)
end

-- a click on a new card during the ceremony too
local Reveal = B.Reveal
function B:Reveal(i, auto)
	if self.state == "contract" then
		return self:ContractSkip()
	end
	return Reveal(self, i, auto)
end

-- Where the given cards wait: five on each side of the parchment, in two staggered columns.
octoConstants.SPOTS = { { 245, 125 }, { 345, 62 }, { 245, 0 }, { 345, -62 }, { 245, -125 } }
local function Around(i)
	local side = i <= 5 and -1 or 1
	local p = octoConstants.SPOTS[CuratorOctoFull.Mod((i - 1) , 5) + 1]
	return side * p[1], octoConstants.CT_Y + p[2]
end
-- they go into the parchment one side then the other
octoConstants.INTO = { 1, 6, 2, 7, 3, 8, 4, 9, 5, 10 }

-- The ten cards given that come around it: all of them for one contract; for several, as many
-- different ones as there are first.
local function AroundKeys(given)
	if CuratorOctoFull.Length(given) <= K.SIZE then
		return given
	end
	local out, left, at = {}, {}, {}
	for _, key in ipairs(given) do
		left[key] = (left[key] or 0) + 1
	end
	for _, key in ipairs(given) do
		if CuratorOctoFull.Length(out) < K.SIZE and not at[key] then
			at[key] = true
			out[CuratorOctoFull.Length(out) + 1] = key
			left[key] = left[key] - 1
		end
	end
	for _, key in ipairs(given) do
		if CuratorOctoFull.Length(out) < K.SIZE and left[key] > 0 then
			out[CuratorOctoFull.Length(out) + 1] = key
			left[key] = left[key] - 1
		end
	end
	return out
end

local function PlaceAt(c, x, y, scale)
	c:SetScale(scale)
	c:ClearAllPoints()
	c:SetPoint("CENTER", B.frame, "CENTER", x / scale, y / scale)
end

-- The parchment open over k (0 closed, 1 open): its window, its rods.
local function Unroll(ct, k)
	local h = math.max(2, P * k)
	ct.roll:SetHeight(h)
	ct.rodTop:ClearAllPoints()
	ct.rodTop:SetPoint("CENTER", B.frame, "CENTER", 0, octoConstants.CT_Y + h / 2)
	ct.rodBot:ClearAllPoints()
	ct.rodBot:SetPoint("CENTER", B.frame, "CENTER", 0, octoConstants.CT_Y - h / 2)
end

function B:ContractReset()
	local s = self.frame
	if not s.ct then
		return
	end
	s.ct:Hide()
	local paper = s.ct.paper
	paper:SetAlpha(1)
	paper:SetScale(1)
	paper:Show()
	paper.edge:Hide()
	paper.seal:Hide()
	paper.glow:SetAlpha(0)
	paper.inner:SetAlpha(0)
	s.ct.rodTop:Show()
	s.ct.rodBot:Show()
	s.ct.rodTop:SetAlpha(1)
	s.ct.rodBot:SetAlpha(1)
	Unroll(s.ct, 1)
	for _, c in ipairs(s.ct.cards) do
		c:Hide()
		c:SetAlpha(1)
	end
	-- (1.14.0, after its second test: the cards of the cases given, the card that came, its words: UI/CaseContract.lua)
	for _, c in ipairs(s.ct.crates or {}) do
		c:Hide()
		c:SetAlpha(1)
	end
	if self.CaseContractReset then
		self:CaseContractReset()
	end
	s.pack:Show()
end

function B:OpenContract(result)
	self:Build()
	local s = self.frame
	self:BuildContractScene()
	self.opts = {}
	-- (the full screen, or the small window)
	self:ApplySize()
	self:ResetScene()
	self.mode = "contract"
	self.result = result
	local card = result.card
	self.series = card.series
	-- the place most of the cards came from, until the new cards show where they come from
	self:SetBackdrop(result.odds[1].series)
	s.halo:SetVertexColor(1, 0.85, 0.6)
	s.pack:Hide()
	s.title:SetText((result.n or 1) > 1 and string.format(L["%d exchange contracts"], result.n) or L["Exchange contract"])
	s.subtitle:SetText(Deal(result.rarity, result.n, nil, result.size, result.up))
	s.counter:SetText("")
	s.hint:SetText("")
	self.state = "contract"
	if not s:IsShown() then
		s:SetAlpha(0)
		s:Show()
		ns.Tween(0.25, function(e)
			s:SetAlpha(e)
		end, nil, Ease.outQuad, self)
	end
	-- the new cards, dealt face down once the parchment has burned away
	self.picks = {}
	for i, r in ipairs(result.cards or { result }) do
		-- (1 November, his word: « les titanforged sous contrat sortent par défaut en prisme, mais quand tu regardes dans
		-- ton inventaire tu vois ton vrai titanforged »: the pattern of the copy that came, its wear, its number with it)
		self.picks[i] = { card = r.card, finish = r.finish, shiny = r.finish == "shiny", holo = r.finish == "holo",
			new = r.new, count = r.count, look = C:FinishLook(r.card, r.finish), extra = r.extra, clause = r.clause,
			pt = r.pt, wear = r.wear, ci = r.ci }
	end
	-- (1.6.0: more than five new cards, the batches of the Merchant: the smaller cards, in two rows)
	if CuratorOctoFull.Length(self.picks) > CuratorOctoFull.Length(self.bigCards) then
		self.cards = self:TenCards(CuratorOctoFull.Length(self.picks))
	end
	for _, c in ipairs(self.cards) do
		c:Hide()
	end
	self:ContractTimeline()
end

function B:ContractTimeline()
	local s = self.frame
	local ct = s.ct
	local paper = ct.paper
	local result = self.result
	local finish = result.finish
	-- (1.14.0, after its second test) a contract of the cards of the cases (UI/CaseContract.lua): its cards, its ranks;
	-- up: the rarity it gives (for the cases, the rank), lvl: how charged the scene is
	local case = self.mode == "caseContract"
	local CR = ns.CrateUI
	local up = case and result.up or math.min(CuratorOctoFull.Length(ns.RARITY), result.up or (result.rarity + 1))
	local lvl = Level(self)
	local tn = octoConstants.TENSION[lvl] or octoConstants.TENSION[2]
	local col = case and CR.RANKS[up].color or ns.RARITY[up].glow
	local n = result.n or 1
	ct:Show()
	paper:Show()
	paper:SetAlpha(1)
	paper:SetScale(1)
	paper.title:SetText(n > 1 and string.format(L["%d exchange contracts"], n) or L["Exchange contract"])
	Fit(paper.line, case and result.line or Deal(result.rarity, n, true, result.size, result.up), 14, P * 0.8)
	paper.mult:SetText(n > 1 and ("x" .. n) or "")
	paper.title:SetAlpha(1)
	paper.line:SetAlpha(1)
	paper.mult:SetAlpha(1)
	paper.mask:ClearAllPoints()
	paper.mask:SetPoint("CENTER", paper, "CENTER", 0, -P * 0.66)
	paper.edge:Hide()
	paper.seal:Hide()
	paper.glow:SetVertexColor(col[1], col[2], col[3])
	paper.inner:SetVertexColor(col[1], col[2], col[3])
	paper.inner:SetAlpha(0)
	ct.rodTop:Show()
	ct.rodBot:Show()
	ct.rodTop:SetAlpha(0)
	ct.rodBot:SetAlpha(0)
	Unroll(ct, 0)
	ns.Play(ns.SND.contract)
	-- the dark falls as much as the card promised is rare
	self:DarkTo(tn.dark, 0.6)
	-- the parchment unrolls from its middle
	ns.Tween(0.6, function(e, raw)
		Unroll(ct, e)
		ct.rodTop:SetAlpha(math.min(1, raw * 5))
		ct.rodBot:SetAlpha(math.min(1, raw * 5))
	end, nil, Ease.outCubic, self, 0.1)
	ns.Tween(0.6, function(e)
		paper.glow:SetAlpha(tn.glow * 0.5 * e)
	end, nil, Ease.outQuad, self, 0.2)
	-- the cards given come in on both sides (the cards of the cases: their copies given, each its card)
	local keys = case and result.given or AroundKeys(result.given)
	local shown = case and math.min(CuratorOctoFull.Length(keys), CuratorOctoFull.Length(ct.cards)) or CuratorOctoFull.Length(keys)
	for i = 1, shown do
		local i = i; local key = keys[i]
		local c
		if case then
			c = self:CaseGiven(i, key)
		else
			c = ct.cards[i]
			c:SetCard(ns.Cards[key], { owned = true, finish = finish })
			c:ShowSide("front")
		end
		c.phase = i * 0.37
		local x, y = Around(i)
		c:SetAlpha(0)
		PlaceAt(c, x * 1.3, y, octoConstants.IN_SCALE)
		c:Show()
		ns.Tween(0.45, function(e, raw)
			c:SetAlpha(math.min(1, raw * 2.5))
			PlaceAt(c, x * (1.3 - 0.3 * e), y, octoConstants.IN_SCALE)
		end, nil, Ease.outBack, self, 0.45 + 0.06 * i)
	end
	-- then into the parchment, one after the other: each melts into it, a light of its colour, and the
	-- light of the parchment grows
	local t0 = 1.7
	local order = {}
	for _, i in ipairs(octoConstants.INTO) do
		if i <= shown then
			order[CuratorOctoFull.Length(order) + 1] = i
		end
	end
	for k, i in ipairs(order) do
		local k, i = k, i; local c = case and ct.crates[i] or ct.cards[i]
		local x, y = Around(i)
		local rc = case and CR.RANKS[c.tier or 1].color or ns.RARITY[c.card.rarity].glow
		ns.Tween(0.42, function(e, raw)
			local cx, cy = x * (1 - e), y + (octoConstants.CT_Y + 20 - y) * e + math.sin(raw * math.pi) * 60
			PlaceAt(c, cx, cy, octoConstants.IN_SCALE * (1 - 0.72 * e))
			c:SetAlpha(1 - raw * raw)
			-- (white hot as it melts in)
			c.hot:SetVertexColor(1, 0.95, 0.8)
			c.hot:SetAlpha(raw * 0.9)
		end, function()
			c:Hide()
			c.hot:SetAlpha(0)
			self.particles:Burst(0, octoConstants.CT_Y + 20, rc, 8, 130, 0.7, 16)
			self.puffs:Burst(0, octoConstants.CT_Y + 10, { 0.25, 0.16, 0.08 }, 1, 40, 0.6, 50, 0.4, 1.4)
			local g = tn.glow * (0.4 + 0.6 * k / CuratorOctoFull.Length(order))
			paper.glow:SetAlpha(g)
			B.U.GlowTo(paper.glow, g * 0.7, 0.3, self)
			paper.inner:SetAlpha(math.min(0.55, 0.12 + 0.43 * k / CuratorOctoFull.Length(order)))
			if CuratorOctoFull.Mod(k , 2) == 1 then
				ns.Play(ns.SND.ink)
			end
		end, Ease.inCubic, self, t0 + 0.15 * (k - 1))
	end
	-- the light gathers: the beats of a heart, the circle of runes, lightning (the rarer, the more)
	local tGather = t0 + 0.15 * (CuratorOctoFull.Length(order) - 1) + 0.45
	if tn.circle then
		ns.Delay(tGather - 0.3, function()
			self:Circle(0, octoConstants.CT_Y, col, 520 + 60 * (lvl - 4), 0.8, 0.6 + 0.2 * (lvl - 4))
		end, self)
	end
	if tn.rays then
		ns.Delay(tGather - 0.3, function()
			local r1, r2 = s.rays, s.rays2
			r1:ClearAllPoints()
			r1:SetPoint("CENTER", s.behind, "CENTER", 0, octoConstants.CT_Y)
			r1:SetVertexColor(col[1], col[2], col[3])
			r1.on, r1.card = true, nil
			B.U.GlowTo(r1, tn.rays, 0.8, self)
			if lvl >= 6 then
				r2:ClearAllPoints()
				r2:SetPoint("CENTER", s.behind, "CENTER", 0, octoConstants.CT_Y)
				r2:SetVertexColor(1, 0.78, 0.36)
				B.U.GlowTo(r2, 0.3, 0.8, self)
			end
		end, self)
	end
	for k = 1, tn.beats do
		local k = k; ns.Delay(tGather + (k - 1) * (0.5 - 0.06 * k), function()
			self:Ring(0, octoConstants.CT_Y, col, 360 + 50 * k, 0.45, 0.5, 0, "Shock")
			self:EdgeGlow(col, 0.12 + 0.06 * k, 0.45)
			self:Punch(0.012, 0.25)
			self:Shake(0.15, 1.5 + k)
			ns.Play(ns.SND.tell[math.min(6, 2 + k)])
			paper.inner:SetAlpha(math.min(0.85, paper.inner:GetAlpha() + 0.1))
		end, self)
	end
	local tBeats = tGather + tn.beats * 0.42
	if tn.bolts then
		ns.Play(ns.SND.rumble)
		ns.Delay(tBeats - 0.3, function()
			self:Bolts(-150, octoConstants.CT_Y + 60, 380, col)
		end, self)
		ns.Delay(tBeats - 0.1, function()
			self:Bolts(150, octoConstants.CT_Y - 40, 420, lvl >= 6 and { 1, 0.3, 0.35 } or col)
		end, self)
	end
	-- the seal strikes, left of the signature
	local tSeal = tBeats + 0.2
	local sx, sy = -P * 0.1, -P * 0.25
	ns.Delay(tSeal, function()
		paper.seal:Show()
		paper.seal:SetAlpha(0)
		ns.Tween(0.22, function(e, raw)
			local k = 92 * (3 - 2 * e)
			CuratorOctoFull.SetSize(paper.seal, k, k)
			paper.seal:ClearAllPoints()
			paper.seal:SetPoint("CENTER", paper, "CENTER", sx, sy)
			paper.seal:SetAlpha(math.min(1, raw * 3))
		end, function()
			ns.Play(ns.SND.seal)
			if ns.SND.impact[lvl] then
				ns.Play(ns.SND.impact[lvl])
			end
			if tn.gong then
				ns.Play(ns.SND.gong)
			end
			self:HitStop(0.05 + 0.02 * (lvl - 2))
			self:Ring(sx, octoConstants.CT_Y + sy, { 0.9, 0.35, 0.3 }, 300, 0.6, 0.55)
			self:Ring(sx, octoConstants.CT_Y + sy, col, 520 + 80 * (lvl - 2), 0.7, 0.6, 0.04, "Shock")
			self.particles:Burst(sx, octoConstants.CT_Y + sy, { 0.75, 0.62, 0.5 }, 18, 150, 0.8, 14)
			self.streaks:Burst(sx, octoConstants.CT_Y + sy, col, 10 + 4 * (lvl - 2), 300, 0.5, 26, 0.8)
			self.puffs:Burst(sx - 30, octoConstants.CT_Y + sy - 20, { 0.7, 0.62, 0.52 }, 2, 60, 0.7, 70, 0.3, 1.6)
			self:Flash({ 1, 0.92, 0.8 }, 0.2 + 0.06 * (lvl - 2), 0.35)
			self:Shake(0.25, 3 + 2 * (lvl - 2))
			self:Punch(0.02 + 0.006 * (lvl - 2), 0.3)
			paper.glow:SetAlpha(tn.glow + 0.2)
			B.U.GlowTo(paper.glow, tn.glow, 0.6, self)
		end, Ease.inQuad, self)
	end, self)
	-- the parchment burns away in a fire of gold, from the bottom up; the new cards rise out of it
	local tBurn = tSeal + 0.8
	local fire = octoConstants.FIRE[lvl] or octoConstants.FIRE[1]
	ns.Delay(tBurn, function()
		ns.Play(ns.SND.burn)
		ns.Tween(0.4, function(e)
			paper.title:SetAlpha(1 - e)
			paper.line:SetAlpha(1 - e)
			paper.mult:SetAlpha(1 - e)
		end, nil, Ease.outQuad, self)
		paper.edge:SetVertexColor(fire[1], fire[2], fire[3])
		paper.edge:Show()
		local sealGone = false
		local nextEmber = 0
		ns.Tween(1.7, function(e, raw)
			local m = -P * 0.66 + P * 1.32 * e
			paper.mask:ClearAllPoints()
			paper.mask:SetPoint("CENTER", paper, "CENTER", 0, m)
			paper.edge:ClearAllPoints()
			paper.edge:SetPoint("CENTER", paper, "CENTER", 0, m)
			paper.edge:SetAlpha(math.min(1, raw * 6) * math.min(1, (1 - raw) * 6))
			if raw >= nextEmber and m > -P * 0.48 and m < P * 0.48 then
				nextEmber = raw + 0.03
				self.particles:Rise(-P * 0.36, P * 0.36, octoConstants.CT_Y + m, fire, 2 + math.floor((lvl - 2) / 2), 110, 1.2, 13)
				if lvl >= 4 then
					self.stars:Rise(-P * 0.3, P * 0.3, octoConstants.CT_Y + m, { 1, 0.86, 0.5 }, 1, 160, 1.3, 16)
				end
			end
			if not sealGone and m > sy - 10 then
				sealGone = true
				ns.Tween(0.3, function(k)
					paper.seal:SetAlpha(1 - k)
				end, nil, Ease.outQuad, self)
			end
			-- the rods go with it
			ct.rodTop:SetAlpha(1 - raw)
			ct.rodBot:SetAlpha(1 - raw)
		end, function()
			paper:Hide()
			paper.edge:Hide()
			ct.rodTop:Hide()
			ct.rodBot:Hide()
		end, Ease.linear, self)
		-- (a flash of gold as the last of it goes)
		ns.Delay(1.45, function()
			self:Flash({ fire[1], fire[2], fire[3] }, 0.22, 0.4)
			self:Ring(0, octoConstants.CT_Y, fire, 640, 0.6, 0.5, 0, "Shock")
		end, self)
	end, self)
	ns.Delay(tBurn + 1.35, function()
		if case then
			self:CaseContractDeal()
		else
			self:ContractDeal()
		end
	end, self)
end

-- The new cards rise out of the fire and fly to their places, face down.
function B:ContractDeal()
	if self.state ~= "contract" then
		return
	end
	self.frame.ct.paper:Hide()
	self:Deal(octoConstants.CT_Y)
end

-- The ceremony is cut short: the new cards at their places at once, face down.
function B:ContractReady()
	local s = self.frame
	if self.state ~= "contract" then
		return
	end
	local n = CuratorOctoFull.Length(self.picks)
	for i, pick in ipairs(self.picks) do
		local c = self.cards[i]
		c.pick = pick
		c:ShowSide("back")
		c:SetCard(pick.card, { owned = true, finish = pick.finish, count = pick.count, new = false, pattern = pick.pt, wear = pick.wear })
		-- (1.12.0) its back, the one of its booster (Card:SetBack); a card of Hallow's End: its candle (UI/HallowLair.lua)
		if self.HallowBack then
			self:HallowBack(c, pick.card)
		end
		c.phase = i * 0.3
		local x, y, row = self:SlotXY(i, n)
		c.slotX, c.slotY, c.row = x, y, row
		c.lift, c.pop = 0, 0
		c:SetScale(1)
		c:SetAlpha(1)
		c.free = true
		c:Show()
		local r = pick.card.rarity
		local col = ns.RARITY[r].glow
		c.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.glow:SetVertexColor(col[1], col[2], col[3])
		c.back.core:SetVertexColor(col[1], col[2], col[3])
		if r >= 4 then
			c.glow:SetAlpha(0.3)
			c.back.glow:SetAlpha(0.45)
		end
	end
	self.state = "cards"
	s.hint:SetText(n == 1 and L["Click the card to reveal it"] or L["Click a card to reveal it"])
	if n > 1 then
		B.U.FadeIn(s.revealAll, 0.3, self)
	else
		s.revealAll:Hide()
	end
end

function B:ContractSkip()
	local s = self.frame
	ns.CancelOwner(self)
	-- (the shock wave of the seal, cut in its flight, would stay on the screen)
	self:ClearFx()
	self.particles:Clear()
	self.stars:Clear()
	self.streaks:Clear()
	self.puffs:Clear()
	self:SetTime(1)
	s:SetAlpha(1)
	s.flash:SetAlpha(0)
	s.edge:SetAlpha(0)
	s.dark:SetAlpha((octoConstants.TENSION[Level(self)] or octoConstants.TENSION[2]).dark)
	s.rays:SetAlpha(0)
	s.rays.on = false
	s.rays2:SetAlpha(0)
	local ct = s.ct
	ct.paper:Hide()
	ct.paper.edge:Hide()
	ct.rodTop:Hide()
	ct.rodBot:Hide()
	for _, c in ipairs(ct.cards) do
		c:Hide()
	end
	for _, c in ipairs(ct.crates or {}) do
		c:Hide()
	end
	-- (1.14.0, after its second test: the card of a case that comes, UI/CaseContract.lua)
	if self.mode == "caseContract" then
		return self:CaseContractReady()
	end
	self:ContractReady()
end

-- (what the scene of a contract of the cards of the cases shares with it: UI/CaseContract.lua)
B.CT = { P = P, CT_Y = octoConstants.CT_Y, IN_SCALE = octoConstants.IN_SCALE, TENSION = octoConstants.TENSION, Level = Level, Around = Around, PlaceAt = PlaceAt }

-- After the reveal of the new card of a single contract: the place it comes from takes the screen,
-- through a dark moment. (Through B:DarkTo: what darkened the place before gives way to it, the light
-- of the titans included.) Several contracts: the place of the finest of them, once all are revealed.
local function ShowPlace(card)
	local s = B.frame
	ns.Delay(card.rarity >= 6 and 1.0 or 0.35, function()
		B:DarkTo(0.9, 0.25)
		ns.Delay(0.25, function()
			B:SetBackdrop(card.series)
			s.title:SetText(C:SeriesName(card.series))
			B:DarkTo(0, 0.7)
		end, B)
	end, B)
end

-- (1.13.0, after its second test) A card of the clause of the collection revealed: said over it, in gold.
function B:ClauseTag(c)
	local s = self.frame
	if not (c and c:IsShown() and s.tags) then
		return
	end
	s.tagI = CuratorOctoFull.Mod((s.tagI or 0) , CuratorOctoFull.Length(s.tags)) + 1
	local t = s.tags[s.tagI]
	t:SetText(L["Collection clause"])
	t:SetTextColor(1, 0.82, 0.36)
	local x, y0 = c.slotX, c.slotY + c.H / 2 + ((c.row == 2) and -26 or (c.row == 1 and 16 or 40))
	if t.tw then
		ns.CancelTween(t.tw)
	end
	self.stars:Burst(x, c.slotY + c.H / 2, { 1, 0.82, 0.36 }, 6, 90, 0.7, 14)
	t.tw = ns.Tween(2.4, function(e, raw)
		t:ClearAllPoints()
		t:SetPoint("CENTER", s.fx, "CENTER", x, y0 + 16 * e)
		t:SetAlpha((raw < 0.1 and raw / 0.1) or (raw > 0.7 and (1 - raw) / 0.3) or 1)
	end, function()
		t:SetAlpha(0)
		t.tw = nil
	end, Ease.outCubic, self)
end

ns.On("CONTRACT_REVEALED", function(card, pick, c)
	if CuratorOctoFull.Length((B.picks or {})) <= 1 then
		ShowPlace(card)
	end
	if pick and pick.clause and c then
		ns.Delay((card.rarity or 1) >= 4 and 0.55 or 0.3, function()
			B:ClauseTag(c)
		end, B)
	end
end)

ns.On("CONTRACT_DONE", function(best)
	if best then
		ShowPlace(best)
	end
end)
