local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local A = ns.Album
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local TL = ns.Talents

-- (1.6.0) The page of the talents, in the album. (1.14.0: the five trees of the release.) Before the specialization is
-- chosen: the five of them in a row, the one looked at below (its emblem, what it does, some of its talents over its
-- art), to look at their trees and, from level 5, to choose one (two clicks: it is for good). Then: on the left the
-- specialization, the points to place, the talents to use and when they are ready again, the contract of reconversion;
-- on the right its tree, ten tiers of talents in three columns, the points each tier asks on their left. A click places
-- a point, a right click takes it back (before they are applied), and Apply (two clicks) makes them the talents of the
-- account. Its tooltips tell what each talent does, at its rank and at the next one.
local NAV_W = 192
local X0 = NAV_W + 14
-- (1.9.0: the tree as in the game: a row of talents every 64 points, a column every 100, the two
-- talents of a choice side by side)
local ROW, COL, PAIR_DX = 88, 135, 25
-- (1.11.0) above the first tier and under the last one, on the body of the tree that scrolls; the line above a
-- tier, so far above its talents (its words over it, under the branches that run between the rows)
local TREE_MARGIN = 46
local TIER_LINE = 7
local FOOT_H = 34
local GOLDEN = { 1, 0.8, 0.32 }
local DIM = { 0.62, 0.62, 0.68 }
local GREEN = { 0.35, 1, 0.35 }
local CONFIRM = 4
-- the talents that are used, or that work once a day or a week, by specialization (six at most learned at once)
local ACTIVES = {
	carto = { "survey", "expedition", "terra", "treasure" },
	hunter = { "mark", "dailyhead", "legendhead", "contractw" },
	gambler = { "double", "wheel", "grandgame", "masterkey" },
	smuggler = { "blackmarket", "order", "baron", "delivery", "goldcontract", "farcommerce" },
	archivist = { "glance", "masterpiece", "conservator", "freerestore", "weekpact", "favored", "familyseal" },
}
-- some talents of each specialization, on the screen of the choice
local HIGHLIGHTS = {
	carto = { "survey", "forage", "finds", "atlas", "terra", "expedition" },
	hunter = { "mark", "quarry", "flair", "teeth", "dailyhead", "legendhead" },
	gambler = { "double", "rush", "stake", "jackpot", "wheel", "grandgame" },
	smuggler = { "blackmarket", "patter", "fence", "handshake", "order", "baron" },
	archivist = { "glance", "steady", "signature", "restorer", "masterpiece", "conservator" },
}

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

-- The name of a specialization in its colour.
local function SpecText(key, female)
	local sp = TL.SPEC_BY[key or ""]
	if not sp then
		return ""
	end
	return "|cff" .. Hex(sp.color) .. (TL:SpecName(key, female) or "") .. "|r"
end
TL.SpecText = SpecText

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- (1.9.0) A talent as in the talent frame of the game: its icon in the slot of the game, coloured by its
-- state (green: a point can go there, gold: every rank, grey: not yet), its rank in the small box at its
-- corner, the light of the points placed and not applied behind it.
local BTN = 37
local function NewTalent(parent)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, BTN, BTN)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b.size = BTN
	b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -2)
	b.glow:SetTexture(MEDIA .. "TalentGlow")
	b.glow:SetBlendMode("ADD")
	b.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.glow, BTN * 2.1, BTN * 2.1)
	b.glow:SetAlpha(0)
	b.slot = b:CreateTexture(nil, "BACKGROUND")
	b.slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
	CuratorOctoFull.SetSize(b.slot, 64, 64)
	b.slot:SetPoint("CENTER", 0, -1)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.rankBorder = b:CreateTexture(nil, "OVERLAY")
	b.rankBorder:SetTexture("Interface\\TalentFrame\\TalentFrame-RankBorder")
	CuratorOctoFull.SetSize(b.rankBorder, 32, 32)
	b.rankBorder:SetPoint("CENTER", b, "BOTTOMRIGHT", 0, 0)
	b.rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	b.rank:SetPoint("CENTER", b.rankBorder, "CENTER", 1, 0)
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		A:TalentTooltip(self)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(b, "OnClick", function(self, button)
		A:TalentClick(self, button)
	end)
	return b
end

-- The branches of the game between a talent and those that need it (UI-TalentBranches: gold when what
-- it needs is there, grey else) and the arrow at their end. Their pieces: a bar, a corner (├ ┘ └ ┐ ┌).
local BRANCHES = "Interface\\TalentFrame\\UI-TalentBranches"
local ARROWS = "Interface\\TalentFrame\\UI-TalentArrows"
local BRANCH = {
	v = { 0, 0.125, 0, 0.484375, 0.515625, 1 },
	h = { 0.2578125, 0.3828125, 0, 0.5, 0.5, 1 },
	upLeft = { 0.38671875, 0.51171875, 0, 0.5, 0.5, 1 },
	upRight = { 0.51171875, 0.38671875, 0, 0.5, 0.5, 1 },
	leftDown = { 0.515625, 0.640625, 0, 0.5, 0.5, 1 },
	rightDown = { 0.640625, 0.515625, 0, 0.5, 0.5, 1 },
}
local ARROW_DOWN = { 0, 0.5, 0, 0.5, 0.5, 1 }

-- A piece of a branch from the pool of the tree (x, y from its top left, y downwards).
local function Piece(tree, file, coords, on, x, y, w, h)
	tree.used = tree.used + 1
	local t = tree.pieces[tree.used]
	if not t then
		t = tree.lines:CreateTexture(nil, "ARTWORK")
		tree.pieces[tree.used] = t
	end
	t:SetTexture(file)
	t:SetTexCoord(coords[1], coords[2], on and coords[3] or coords[5], on and coords[4] or coords[6])
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", tree.body or tree, "TOPLEFT", x, -y)
	CuratorOctoFull.SetSize(t, w, h)
	t:SetDrawLayer("ARTWORK", on and 1 or 0)
	t:Show()
	return t
end

-- The art of the game behind a tree, as the talent frame shows it: its four pieces (the picture is 300 by
-- 331 on a canvas of 320 by 384), cut to fill the place of the tree without being stretched.
-- (1.14.0: the art of each tree, Talents.lua: its spec.art)
local ART_W, ART_H = 300, 331
local ART_PIECES = {
	{ "TopLeft", 0, 0, 256, 256 }, { "TopRight", 256, 0, 64, 256 },
	{ "BottomLeft", 0, 256, 256, 128 }, { "BottomRight", 256, 256, 64, 128 },
}
local function PaintArt(tree, key)
	local def = TL.SPEC_BY[key or ""] or TL.SPECS[1]
	local name = def.art or "DruidRestoration"
	if tree.art.name == name then
		return
	end
	tree.art.name = name
	local w, h = tree:GetWidth(), tree:GetHeight()
	local k = math.max(w / ART_W, h / ART_H)
	local cw, ch = w / k, h / k
	local x0, y0 = (ART_W - cw) / 2, (ART_H - ch) / 2
	for i, pc in ipairs(ART_PIECES) do
		local t = tree.art[i]
		local ix0, iy0 = math.max(x0, pc[2]), math.max(y0, pc[3])
		local ix1, iy1 = math.min(x0 + cw, pc[2] + pc[4]), math.min(y0 + ch, pc[3] + pc[5])
		if ix1 > ix0 and iy1 > iy0 then
			t:SetTexture("Interface\\TalentFrame\\" .. name .. "-" .. pc[1])
			t:SetTexCoord((ix0 - pc[2]) / pc[4], (ix1 - pc[2]) / pc[4], (iy0 - pc[3]) / pc[5], (iy1 - pc[3]) / pc[5])
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", tree, "TOPLEFT", (ix0 - x0) * k, -(iy0 - y0) * k)
			CuratorOctoFull.SetSize(t, (ix1 - ix0) * k, (iy1 - iy0) * k)
			t:Show()
		else
			t:Hide()
		end
	end
end


-- A line of the talents to use: its icon, its name, when it is ready.
local function NewActive(parent, w)
	local r = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(r, w, 22)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(r.icon, 18, 18)
	r.icon:SetPoint("LEFT", 0, 0)
	r.name = S.Text(r, "GameFontHighlightSmall", "LEFT")
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
	CuratorOctoFull.SetWordWrap(r.name, false)
	r.state = S.Text(r, "GameFontHighlightSmall", "RIGHT")
	r.state:SetPoint("RIGHT", 0, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(r.hl, 1, 0.9, 0.6, 0.08)
	CuratorOctoFull.SetScript(r, "OnEnter", function(self)
		A:ActiveTooltip(self)
	end)
	CuratorOctoFull.SetScript(r, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(r, "OnClick", function(self)
		A:ActiveClick(self)
	end)
	return r
end

-- (1.14.0) A specialization on the screen of the choice, in the row of the five: its emblem and its name; the one looked
-- at lit.
local function NewMedal(parent, w, h, i)
	local c = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(c, w, h)
	c.bg = Hud.Card(c, 0.75, "BACKGROUND")
	c.glow = Hud.CardGlow(c, 0.75)
	c.light = c:CreateTexture(nil, "BORDER")
	c.light:SetTexture(MEDIA .. "Glow")
	c.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(c.light, 120, 120)
	c.light:SetPoint("CENTER", c, "TOP", 0, -38)
	c.light:SetAlpha(0.35)
	c.ring = c:CreateTexture(nil, "ARTWORK", nil, 3)
	c.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(c.ring, 58, 58)
	c.ring:SetPoint("CENTER", c, "TOP", 0, -38)
	c.icon = Hud.RoundIcon(c, 44, "ARTWORK", 2)
	c.icon:SetPoint("CENTER", c.ring, "CENTER")
	c.name = S.Text(c, "GameFontNormal")
	c.name:SetPoint("TOP", c.ring, "BOTTOM", 0, -3)
	c.name:SetWidth(w - 10)
	CuratorOctoFull.SetWordWrap(c.name, true)
	if c.name.SetMaxLines then
		CuratorOctoFull.SetMaxLines(c.name, 2)
	end
	c.hl = c:CreateTexture(nil, "HIGHLIGHT")
	c.hl:SetPoint("TOPLEFT", 4, -4)
	c.hl:SetPoint("BOTTOMRIGHT", -4, 4)
	CuratorOctoFull.ColorTexture(c.hl, 1, 0.9, 0.6, 0.06)
	c.i = i
	return c
end

-- (1.14.0) A talent of the specialization looked at, on the screen of the choice: its icon in its node, its name, its
-- tier (and what kind of talent it is), what it does (two lines; all of it in its tooltip).
local function NewHighlight(parent, w)
	local ln = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(ln, w, 50)
	ln:EnableMouse(true)
	ln.icon = ln:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(ln.icon, 30, 30)
	ln.icon:SetPoint("TOPLEFT", 4, -4)
	ln.frame = ln:CreateTexture(nil, "OVERLAY")
	ln.frame:SetTexture(MEDIA .. "TalentNode")
	CuratorOctoFull.SetSize(ln.frame, 42, 42)
	ln.frame:SetPoint("CENTER", ln.icon, "CENTER")
	ln.name = S.Text(ln, "GameFontNormal", "LEFT")
	ln.name:SetPoint("TOPLEFT", ln.icon, "TOPRIGHT", 12, 1)
	CuratorOctoFull.SetWordWrap(ln.name, false)
	ln.tag = S.Text(ln, "GameFontHighlightSmall", "RIGHT")
	ln.tag:SetPoint("TOPRIGHT", -6, -1)
	ln.tag:SetTextColor(DIM[1], DIM[2], DIM[3])
	ln.desc = S.Text(ln, "GameFontHighlightSmall", "LEFT")
	ln.desc:SetPoint("TOPLEFT", ln.name, "BOTTOMLEFT", 0, -3)
	ln.desc:SetWidth(w - 56)
	ln.desc:SetHeight(26)
	ln.desc:SetJustifyV("TOP")
	CuratorOctoFull.SetWordWrap(ln.desc, true)
	if ln.desc.SetMaxLines then
		CuratorOctoFull.SetMaxLines(ln.desc, 2)
	end
	ln.desc:SetTextColor(0.85, 0.85, 0.88)
	ln.hl = ln:CreateTexture(nil, "HIGHLIGHT")
	ln.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(ln.hl, 1, 0.9, 0.6, 0.06)
	CuratorOctoFull.SetScript(ln, "OnEnter", function(self)
		if self.id then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			A:TalentLines(TL.BY[self.id], 0, 0, true)
			GameTooltip:Show()
		end
	end)
	CuratorOctoFull.SetScript(ln, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return ln
end

-- Where a talent stands in its tree (from its top left, y downwards): its tier, its column (1.14.0: three of them, the
-- second in the middle), the two talents of a choice on either side.
local function TalentAt(tree, d)
	local x = tree:GetWidth() / 2 + ((d.col or 2) - 2) * COL
	local pair = d.choice and TL.ChoiceOf(d)
	if pair then
		x = x + (pair[1] == d and -PAIR_DX or PAIR_DX)
	end
	return x, tree.top + (d.tier - 1) * tree.row
end
A.TalentAt = TalentAt

-- (1.11.0) The body of the tree moved (to: how far down it is seen, from 0 to the last tiers), its track and its
-- arrows painted.
function A:ScrollTree(to)
	local tree = self.frame and self.frame.tal and self.frame.tal.tree
	if not (tree and tree.body) then
		return
	end
	local most = math.max(0, tree.bodyH - tree.th)
	to = math.max(0, math.min(most, math.floor((tonumber(to) or 0) + 0.5)))
	tree.scroll = to
	tree.body:ClearAllPoints()
	tree.body:SetPoint("TOPLEFT", tree, "TOPLEFT", 0, to)
	local bar = tree.bar
	local h = bar:GetHeight()
	if not h or h <= 0 then
		h = tree.th - 52
	end
	local k = tree.th / tree.bodyH
	bar.thumb:SetHeight(math.max(12, h * k))
	bar.thumb:ClearAllPoints()
	bar.thumb:SetPoint("TOP", bar, "TOP", 0, -(most > 0 and (h - h * k) * to / most or 0))
	CuratorOctoFull.SetShown(bar, most > 0)
	CuratorOctoFull.SetShown(tree.up, most > 0)
	CuratorOctoFull.SetShown(tree.down, most > 0)
	CuratorOctoFull.SetEnabled(tree.up, to > 0)
	CuratorOctoFull.SetEnabled(tree.down, to < most)
end

-- A bar of a way, from p to q: upright (v) or not, the line it runs along (c), from a to b along it.
local function Bar(p, q)
	if math.abs(p[1] - q[1]) < 0.5 then
		return { v = true, c = p[1], a = math.min(p[2], q[2]), b = math.max(p[2], q[2]) }
	end
	return { v = false, c = p[2], a = math.min(p[1], q[1]), b = math.max(p[1], q[1]) }
end

-- Whether a way passes over a talent of its tree (the two it links aside), or out of the tree.
local function OverTalents(tree, way, from, to)
	local m = BTN / 2 + 8
	local w = tree:GetWidth()
	for i = 1, CuratorOctoFull.Length(way) - 1 do
		local s = Bar(way[i], way[i + 1])
		if s.v and (s.c < 10 or s.c > w - 10) then
			return true
		end
		for _, d in ipairs(TL.LIST) do
			if d.spec == from.spec and d ~= from and d ~= to then
				local x, y = TalentAt(tree, d)
				if s.v then
					if math.abs(x - s.c) < m and y + BTN / 2 > s.a and y - BTN / 2 < s.b then
						return true
					end
				elseif math.abs(y - s.c) < BTN / 2 + 4 and x + m > s.a and x - m < s.b then
					return true
				end
			end
		end
	end
	return false
end

-- How much a way gets mixed up with the ways already drawn between two other talents: along the same
-- line, or meeting it (where two ways come from the same talent, or go to the same one, they may join).
local function Clash(way, from, to, placed)
	local cost = 0
	for _, o in ipairs(placed) do
		if o.from ~= from and o.to ~= to then
			for i = 1, CuratorOctoFull.Length(way) - 1 do
				local s = Bar(way[i], way[i + 1])
				for j = 1, CuratorOctoFull.Length(o.way) - 1 do
					local t = Bar(o.way[j], o.way[j + 1])
					if s.v == t.v then
						if math.abs(s.c - t.c) < 8 and math.min(s.b, t.b) - math.max(s.a, t.a) > -2 then
							cost = cost + 10
						end
					else
						local h, v = s.v and t or s, s.v and s or t
						if v.c >= h.a - 3 and v.c <= h.b + 3 and h.c >= v.a - 3 and h.c <= v.b + 3 then
							cost = cost + 4
						end
					end
				end
			end
		end
	end
	return cost
end

-- The way of a branch from a talent to one that needs it, as in the talent frame of the game: straight
-- down, or sideways under it then down, or down then sideways over the other one; when talents stand
-- in between, along the gaps between the rows and between the columns (never over another talent),
-- and apart from the other branches. Its points (x, y), the first one the centre of the talent it
-- comes from, the last one over the talent it goes to.
local function Way(tree, from, to, placed)
	local ax, ay = TalentAt(tree, from)
	local bx, by = TalentAt(tree, to)
	local half = tree.row / 2
	local gapA, gapB = ay + half, by - half
	local top = by - BTN / 2 - 2
	local A, T = { ax, ay }, { bx, top }
	local list, fallback = {}, 1
	local function Round(gx)
		list[CuratorOctoFull.Length(list) + 1] = { A, { ax, gapA }, { gx, gapA }, { gx, gapB }, { bx, gapB }, T }
	end
	if math.abs(ax - bx) < 1 then
		list[1] = { A, T }
		-- (else round the talents between them, on the left or on the right)
		Round(ax - COL * 0.58)
		Round(ax + COL * 0.58)
		fallback = 2
	elseif to.tier == from.tier + 1 then
		list[1] = { A, { ax, gapA }, { bx, gapA }, T }
	else
		list[1] = { A, { ax, gapA }, { bx, gapA }, T }
		list[2] = { A, { ax, gapB }, { bx, gapB }, T }
		-- (down a gap between the columns: next to the one it goes to, next to the one it comes from, or
		-- outside them)
		local dir = bx > ax and 1 or -1
		Round(bx - dir * COL / 2)
		Round(ax + dir * COL / 2)
		Round(ax - dir * COL * 0.58)
		Round(bx + dir * COL * 0.58)
		fallback = 3
	end
	local best, bestCost
	for _, way in ipairs(list) do
		if CuratorOctoFull.Length(list) == 1 or not OverTalents(tree, way, from, to) then
			local cost = Clash(way, from, to, placed or {})
			if cost == 0 then
				return way
			end
			if not bestCost or cost < bestCost then
				best, bestCost = way, cost
			end
		end
	end
	return best or list[fallback]
end
A.TalentWay = Way

-- A branch drawn along its way: its bars, its corners, its arrow (on: gold).
local function DrawWay(tree, way, on)
	local W = 32
	for i = 1, CuratorOctoFull.Length(way) - 1 do
		local p, q = way[i], way[i + 1]
		if math.abs(p[1] - q[1]) < 0.5 then
			local y1, y2 = math.min(p[2], q[2]), math.max(p[2], q[2])
			Piece(tree, BRANCHES, BRANCH.v, on, p[1] - W / 2, y1, W, y2 - y1)
		else
			local x1, x2 = math.min(p[1], q[1]), math.max(p[1], q[1])
			Piece(tree, BRANCHES, BRANCH.h, on, x1, p[2] - W / 2, x2 - x1, W)
		end
	end
	-- the corners: where the way turns
	for i = 2, CuratorOctoFull.Length(way) - 1 do
		local p, c, q = way[i - 1], way[i], way[i + 1]
		local kind
		if math.abs(p[1] - c[1]) < 0.5 then
			-- (down, then sideways: the bar from above meets the one to the side)
			kind = q[1] < c[1] and "upLeft" or "upRight"
		else
			-- (sideways, then down)
			kind = p[1] < c[1] and "leftDown" or "rightDown"
		end
		Piece(tree, BRANCHES, BRANCH[kind], on, c[1] - W / 2, c[2] - W / 2, W, W)
	end
	local e = way[CuratorOctoFull.Length(way)]
	Piece(tree, ARROWS, ARROW_DOWN, on, e[1] - W / 2, e[2] - 18, W, W)
end

-------------------------------------------------------------------------------
-- Building the page
-------------------------------------------------------------------------------
function A:BuildTalents()
	local f = self.frame
	if f.tal then
		return
	end
	local U = self.U
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.tal = page
	local pw = U.PAGE_W - 32
	local ph = U.PAGE_H - 20
	local rw = pw - X0
	page.rw, page.pw, page.ph = rw, pw, ph

	-- on the left: the specialization
	local sp = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(sp, NAV_W, 192)
	sp:SetPoint("TOPLEFT")
	sp.bg = Hud.Card(sp, 0.75, "BACKGROUND")
	sp.glow = Hud.CardGlow(sp, 0.75)
	sp.light = sp:CreateTexture(nil, "BORDER")
	sp.light:SetTexture(MEDIA .. "Glow")
	sp.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(sp.light, 150, 150)
	sp.light:SetPoint("CENTER", sp, "TOP", 0, -54)
	sp.light:SetAlpha(0.45)
	sp.ring = sp:CreateTexture(nil, "ARTWORK", nil, 3)
	sp.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(sp.ring, 76, 76)
	sp.ring:SetPoint("CENTER", sp, "TOP", 0, -54)
	sp.icon = Hud.RoundIcon(sp, 58, "ARTWORK", 2)
	sp.icon:SetPoint("CENTER", sp.ring, "CENTER")
	sp.name = Hud.Text(sp, 18, "")
	sp.name:SetPoint("TOP", sp.ring, "BOTTOM", 0, -6)
	sp.desc = S.Text(sp, "GameFontHighlightSmall")
	sp.desc:SetPoint("TOP", sp.name, "BOTTOM", 0, -6)
	sp.desc:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(sp.desc, true)
	sp.desc:SetTextColor(0.82, 0.82, 0.86)
	page.spec = sp

	-- the points
	local pt = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(pt, NAV_W, 86)
	pt:SetPoint("TOPLEFT", sp, "BOTTOMLEFT", 0, -10)
	pt.bg = Hud.Card(pt, 0.75, "BACKGROUND")
	pt.title = S.Text(pt, "GameFontNormal")
	pt.title:SetPoint("TOP", 0, -10)
	pt.title:SetText(L["Talent points"])
	pt.n = Hud.Text(pt, 24, "OUTLINE")
	pt.n:SetPoint("TOPRIGHT", pt, "TOP", -4, -28)
	pt.n:SetTextColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
	pt.left = S.Text(pt, "GameFontHighlightSmall", "LEFT")
	pt.left:SetPoint("LEFT", pt.n, "RIGHT", 6, -1)
	pt.note = S.Text(pt, "GameFontHighlightSmall")
	pt.note:SetPoint("BOTTOM", 0, 9)
	pt.note:SetWidth(NAV_W - 20)
	CuratorOctoFull.SetWordWrap(pt.note, true)
	pt.note:SetTextColor(DIM[1], DIM[2], DIM[3])
	page.points = pt

	-- the talents to use
	local ac = CreateFrame("Frame", nil, page)
	CuratorOctoFull.SetSize(ac, NAV_W, 120)
	ac:SetPoint("TOPLEFT", pt, "BOTTOMLEFT", 0, -10)
	ac.bg = Hud.Card(ac, 0.75, "BACKGROUND")
	ac.title = S.Text(ac, "GameFontNormal")
	ac.title:SetPoint("TOP", 0, -10)
	ac.title:SetText(L["Active talents"])
	ac.rows = {}
	for i = 1, 8 do
		local r = NewActive(ac, NAV_W - 24)
		r:SetPoint("TOPLEFT", 12, -30 - (i - 1) * 22)
		ac.rows[i] = r
	end
	ac.empty = S.Text(ac, "GameFontHighlightSmall")
	ac.empty:SetPoint("TOP", 0, -34)
	ac.empty:SetWidth(NAV_W - 24)
	CuratorOctoFull.SetWordWrap(ac.empty, true)
	ac.empty:SetTextColor(DIM[1], DIM[2], DIM[3])
	page.actives = ac

	-- the contract of reconversion
	page.respecBtn = S.Button(page, L["Reconversion contract"], NAV_W, 24)
	page.respecBtn:SetPoint("BOTTOMLEFT", 0, 0)
	CuratorOctoFull.SetScript(page.respecBtn, "OnClick", function()
		A:TalentView(A.talView == "respec" and "tree" or "respec")
	end)
	CuratorOctoFull.SetScript(page.respecBtn, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Reconversion contract"], 1, 1, 1)
		GameTooltip:AddLine(L["Change your specialization, or place your points again: paid in rubies."], 0.85, 0.85, 0.85, true)
		-- (1.11.0) its price, the rubies of the collection
		if ns.Rubies then
			-- (1.14.0: the first one offered, every tree being new)
			if TL:FreeRespec() then
				GameTooltip:AddLine(L["Price: offered, your first reconversion"], 0.45, 1, 0.45, true)
			else
				GameTooltip:AddLine(string.format(L["Price: %s"], ns.Rubies.Text(TL:RespecCost())), 1, 0.82, 0.25)
			end
			GameTooltip:AddLine(string.format(L["Your rubies: %s"], ns.Rubies.Text(ns.Rubies:Balance())), 0.85, 0.85, 0.85)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(page.respecBtn, "OnLeave", function()
		GameTooltip:Hide()
	end)

	-- on the right: the tree, as the talent frame of the game (1.9.0): the art of the specialization
	-- behind, the talents in their slots, the branches between them
	local tree = CreateFrame("Frame", nil, page)
	tree:SetPoint("TOPLEFT", X0, 0)
	CuratorOctoFull.SetSize(tree, rw, ph - FOOT_H - 4)
	page.tree = tree
	tree.art = {}
	for i = 1, CuratorOctoFull.Length(ART_PIECES) do
		tree.art[i] = tree:CreateTexture(nil, "BACKGROUND")
	end
	-- (its edge: a dark line, a shadow inside)
	tree.edge = {}
	for i, pt in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
		local e = tree:CreateTexture(nil, "BORDER")
		CuratorOctoFull.ColorTexture(e, 0, 0, 0, 0.85)
		e:SetPoint(pt[1])
		e:SetPoint(pt[2])
		if i <= 2 then
			e:SetHeight(2)
		else
			e:SetWidth(2)
		end
		tree.edge[i] = e
	end
	-- (1.11.0: ten tiers, taller than the window: the talents and their branches on a body that scrolls,
	-- cut to the window; the mouse wheel moves it, Ctrl + the wheel still sizes the album)
	local th = ph - FOOT_H - 4
	tree.row = ROW
	tree.top = TREE_MARGIN
	tree.th = th
	tree.bodyH = math.max(th, TREE_MARGIN * 2 + (TL.TIERS - 1) * ROW)
	tree.view = CreateFrame("Frame", nil, tree)
	tree.view:SetPoint("TOPLEFT", 2, -2)
	tree.view:SetPoint("BOTTOMRIGHT", -2, 2)
	if tree.view.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(tree.view, true)
	end
	tree.body = CreateFrame("Frame", nil, tree.view)
	CuratorOctoFull.SetSize(tree.body, rw, tree.bodyH)
	tree.body:SetPoint("TOPLEFT", tree, "TOPLEFT", 0, 0)
	tree.scroll = 0
	-- (a line above each tier, its words on its left: the tier, and while it is closed the points it asks;
	-- above the tiers past the legend, their words in the middle too)
	tree.tiers = {}
	for t = 1, TL.TIERS do
		local y = tree.top + (t - 1) * ROW - BTN / 2 - TIER_LINE
		local line = S.Divider(tree.body, rw - 24, 0.9)
		line:SetPoint("CENTER", tree.body, "TOPLEFT", rw / 2, -y)
		local text = S.Text(tree.body, "GameFontNormalSmall", "LEFT")
		text:SetPoint("BOTTOMLEFT", tree.body, "TOPLEFT", 12, -y + 2)
		tree.tiers[t] = { line = line, text = text, y = y }
	end
	local past = (TL.LEGEND_TIER or 8)
	tree.past = tree.tiers[past] and tree.tiers[past].line
	tree.pastText = S.Text(tree.body, "GameFontNormalSmall")
	tree.pastText:SetPoint("BOTTOM", tree.past, "TOP", 0, 2)
	tree.pastText:SetText(L["Past the legend: from level 61"])
	-- (the branches: in a frame of their own, under the talents)
	tree.lines = CreateFrame("Frame", nil, tree.body)
	tree.lines:SetAllPoints()
	tree.pieces, tree.used = {}, 0
	tree.nodes = {}
	for _, d in ipairs(TL.LIST) do
		local b = NewTalent(tree.body)
		b:SetFrameLevel(tree.lines:GetFrameLevel() + 2)
		local x, y = A.TalentAt(tree, d)
		b:SetPoint("CENTER", tree.body, "TOPLEFT", x, -y)
		b.d = d
		Hud.SetIcon(b.icon, { d.icon })
		-- (the icon whole, as the game shows it in its slot)
		b.icon:SetTexCoord(0, 1, 0, 1)
		tree.nodes[d.id] = b
	end
	-- (the scroll: the mouse wheel; at the right edge, its track and where the window is on it, an arrow
	-- up and one down)
	tree:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(tree, "OnMouseWheel", function(_, delta)
		if IsControlKeyDown and IsControlKeyDown() and ns.Options then
			ns.Options:StepScale(delta)
			return
		end
		A:ScrollTree(tree.scroll - delta * ROW)
	end)
	local bar = CreateFrame("Frame", nil, tree)
	bar:SetFrameLevel(tree.lines:GetFrameLevel() + 6)
	bar:SetPoint("TOPRIGHT", -5, -26)
	bar:SetPoint("BOTTOMRIGHT", -5, 26)
	bar:SetWidth(6)
	bar.track = bar:CreateTexture(nil, "BACKGROUND")
	bar.track:SetAllPoints()
	CuratorOctoFull.ColorTexture(bar.track, 0, 0, 0, 0.45)
	bar.thumb = bar:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.ColorTexture(bar.thumb, GOLDEN[1], GOLDEN[2], GOLDEN[3], 0.7)
	bar.thumb:SetWidth(4)
	tree.bar = bar
	local function Arrow(up)
		local a = CreateFrame("Button", nil, tree)
		CuratorOctoFull.SetSize(a, 22, 22)
		a:SetFrameLevel(tree.lines:GetFrameLevel() + 6)
		local name = up and "Up" or "Down"
		a:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. name .. "Button-Up")
		a:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. name .. "Button-Down")
		a:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. name .. "Button-Disabled")
		a:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-Scroll" .. name .. "Button-Highlight", "ADD")
		CuratorOctoFull.SetScript(a, "OnClick", function()
			ns.Play(ns.SND.click)
			A:ScrollTree(tree.scroll + (up and -3 or 3) * ROW)
		end)
		return a
	end
	tree.up = Arrow(true)
	tree.up:SetPoint("TOPRIGHT", -1, -3)
	tree.down = Arrow(false)
	tree.down:SetPoint("BOTTOMRIGHT", -1, 3)

	-- under the tree: what was placed, Cancel, Apply changes; the way back from a tree looked at
	local foot = CreateFrame("Frame", nil, page)
	foot:SetPoint("BOTTOMLEFT", X0, 0)
	foot:SetPoint("BOTTOMRIGHT", 0, 0)
	foot:SetHeight(FOOT_H)
	foot.note = S.Text(foot, "GameFontHighlightSmall", "LEFT")
	foot.note:SetPoint("LEFT", 4, 0)
	foot.note:SetWidth(rw - 340)
	CuratorOctoFull.SetWordWrap(foot.note, true)
	foot.note:SetTextColor(DIM[1], DIM[2], DIM[3])
	foot.apply = S.Button(foot, L["Apply changes"], 210, 24)
	foot.apply:SetPoint("RIGHT", 0, 0)
	CuratorOctoFull.SetScript(foot.apply, "OnClick", function()
		A:ApplyTalents()
	end)
	foot.cancel = S.Button(foot, L["Cancel"], 110, 24)
	foot.cancel:SetPoint("RIGHT", foot.apply, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(foot.cancel, "OnClick", function()
		ns.Play(ns.SND.click)
		A.talApply = nil
		TL:Cancel()
	end)
	foot.back = S.Button(foot, L["Back"], 120, 24)
	foot.back:SetPoint("RIGHT", 0, 0)
	CuratorOctoFull.SetScript(foot.back, "OnClick", function()
		ns.Play(ns.SND.page)
		A:TalentView(A.talReturn or (TL:Spec() and "tree" or "choose"))
	end)
	page.foot = foot

	-- the screen of the choice (1.14.0): the five specializations in a row, the one looked at below them, over its art
	local ch = CreateFrame("Frame", nil, page)
	ch:SetAllPoints()
	ch:SetFrameLevel(page:GetFrameLevel() + 10)
	ch.head = S.Text(ch, "GameFontHighlight")
	ch.head:SetPoint("TOP", 0, -2)
	ch.head:SetWidth(pw - 40)
	CuratorOctoFull.SetWordWrap(ch.head, true)
	local n = CuratorOctoFull.Length(TL.SPECS)
	local mw = math.floor((pw - (n - 1) * 8) / n)
	local MEDAL_Y, MEDAL_H = -40, 96
	ch.medals = {}
	for i, spec in ipairs(TL.SPECS) do
		local i, spec = i, spec; local c = NewMedal(ch, mw, MEDAL_H, i)
		c:SetPoint("TOPLEFT", (i - 1) * (mw + 8), MEDAL_Y)
		c.key = spec.key
		CuratorOctoFull.SetScript(c, "OnClick", function()
			if A.talLook ~= spec.key then
				ns.Play(ns.SND.page)
				A.talLook = spec.key
				A.talChoose = nil
				A:Refresh()
			end
		end)
		CuratorOctoFull.SetScript(c, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(TL:SpecName(spec.key, TL:Female()), spec.color[1], spec.color[2], spec.color[3])
			GameTooltip:AddLine(L[spec.desc], 1, 1, 1, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function()
			GameTooltip:Hide()
		end)
		ch.medals[i] = c
	end
	-- the one looked at: its art behind (darker on the left, where its words are), its emblem, its name, what it does,
	-- the buttons to look at its tree and to choose it; on the right, some of its talents
	local dh = ph - (-MEDAL_Y + MEDAL_H + 10) - 26
	local dt = CreateFrame("Frame", nil, ch)
	CuratorOctoFull.SetSize(dt, pw, dh)
	dt:SetPoint("TOPLEFT", 0, MEDAL_Y - MEDAL_H - 10)
	dt.bg = Hud.Card(dt, 0.75, "BACKGROUND")
	dt.glow = Hud.CardGlow(dt, 0.75)
	dt.art = {}
	for i = 1, CuratorOctoFull.Length(ART_PIECES) do
		dt.art[i] = dt:CreateTexture(nil, "BORDER")
	end
	dt.shade = dt:CreateTexture(nil, "BORDER", nil, 2)
	CuratorOctoFull.ColorTexture(dt.shade, 0, 0, 0, 0.5)
	dt.shade:SetPoint("TOPLEFT", 3, -3)
	dt.shade:SetPoint("BOTTOMLEFT", 3, 3)
	dt.shade:SetWidth(290)
	dt.shade2 = dt:CreateTexture(nil, "BORDER", nil, 2)
	CuratorOctoFull.ColorTexture(dt.shade2, 0, 0, 0, 0.32)
	dt.shade2:SetPoint("TOPLEFT", dt.shade, "TOPRIGHT")
	dt.shade2:SetPoint("BOTTOMRIGHT", -3, 3)
	dt.light = dt:CreateTexture(nil, "ARTWORK")
	dt.light:SetTexture(MEDIA .. "Glow")
	dt.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(dt.light, 190, 190)
	dt.light:SetPoint("CENTER", dt, "TOPLEFT", 66, -64)
	dt.light:SetAlpha(0.5)
	dt.ring = dt:CreateTexture(nil, "ARTWORK", nil, 3)
	dt.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(dt.ring, 92, 92)
	dt.ring:SetPoint("CENTER", dt, "TOPLEFT", 66, -64)
	dt.icon = Hud.RoundIcon(dt, 72, "ARTWORK", 2)
	dt.icon:SetPoint("CENTER", dt.ring, "CENTER")
	dt.name = Hud.Text(dt, 22, "")
	dt.name:SetPoint("LEFT", dt.ring, "RIGHT", 8, 6)
	dt.name:SetWidth(170)
	dt.name:SetJustifyH("LEFT")
	CuratorOctoFull.SetWordWrap(dt.name, true)
	dt.role = S.Text(dt, "GameFontHighlightSmall", "LEFT")
	dt.role:SetPoint("TOPLEFT", dt.name, "BOTTOMLEFT", 0, -4)
	dt.role:SetWidth(170)
	CuratorOctoFull.SetWordWrap(dt.role, true)
	dt.role:SetTextColor(DIM[1], DIM[2], DIM[3])
	dt.desc = S.Text(dt, "GameFontHighlight", "LEFT")
	dt.desc:SetPoint("TOPLEFT", 18, -124)
	dt.desc:SetWidth(262)
	CuratorOctoFull.SetWordWrap(dt.desc, true)
	dt.desc:SetSpacing(2)
	dt.desc:SetTextColor(0.9, 0.88, 0.84)
	dt.choose = Hud.ClaimButton(dt, 248, 32, L["Choose"])
	dt.choose:SetPoint("BOTTOMLEFT", 22, 14)
	CuratorOctoFull.SetScript(dt.choose, "OnClick", function()
		A:ChooseSpec(A.talLook)
	end)
	dt.see = S.Button(dt, L["See the tree"], 248, 22)
	dt.see:SetPoint("BOTTOMLEFT", 22, 54)
	CuratorOctoFull.SetScript(dt.see, "OnClick", function()
		ns.Play(ns.SND.page)
		A.talPreview = A.talLook
		A.talReturn = "choose"
		A:TalentView("preview")
	end)
	dt.title = S.Text(dt, "GameFontNormal", "LEFT")
	dt.title:SetPoint("TOPLEFT", 304, -14)
	dt.title:SetText(L["Some of its talents"])
	dt.lines = {}
	local lw = pw - 304 - 14
	for k = 1, 6 do
		local ln = NewHighlight(dt, lw)
		ln:SetPoint("TOPLEFT", 300, -34 - (k - 1) * 52)
		dt.lines[k] = ln
	end
	ch.detail = dt
	ch.foot = S.Text(ch, "GameFontHighlightSmall")
	ch.foot:SetPoint("BOTTOM", 0, 6)
	ch.foot:SetWidth(pw - 40)
	CuratorOctoFull.SetWordWrap(ch.foot, true)
	ch.foot:SetTextColor(DIM[1], DIM[2], DIM[3])
	ch:Hide()
	page.choose = ch

	-- the contract of reconversion
	local rs = CreateFrame("Frame", nil, page)
	rs:SetPoint("TOPLEFT", X0, 0)
	rs:SetPoint("BOTTOMRIGHT")
	rs:SetFrameLevel(page:GetFrameLevel() + 10)
	rs.paper = rs:CreateTexture(nil, "BACKGROUND")
	rs.paper:SetTexture(MEDIA .. "ContractBand")
	rs.paper:SetPoint("TOPLEFT", 0, -8)
	rs.paper:SetPoint("BOTTOMRIGHT", 0, 50)
	rs.paper:SetAlpha(0.95)
	rs.rodTop = rs:CreateTexture(nil, "ARTWORK", nil, 3)
	rs.rodTop:SetTexture(MEDIA .. "ScrollRod")
	rs.rodTop:SetHeight(26)
	rs.rodTop:SetPoint("LEFT", rs.paper, "TOPLEFT", -14, 2)
	rs.rodTop:SetPoint("RIGHT", rs.paper, "TOPRIGHT", 14, 2)
	rs.rodBot = rs:CreateTexture(nil, "ARTWORK", nil, 3)
	rs.rodBot:SetTexture(MEDIA .. "ScrollRod")
	rs.rodBot:SetHeight(26)
	rs.rodBot:SetPoint("LEFT", rs.paper, "BOTTOMLEFT", -14, -2)
	rs.rodBot:SetPoint("RIGHT", rs.paper, "BOTTOMRIGHT", 14, -2)
	local INK = { 0.30, 0.18, 0.08 }
	local function Ink(size, justify)
		local t = U.Text(rs, size, "")
		t:SetTextColor(INK[1], INK[2], INK[3])
		t:SetShadowOffset(0, 0)
		if justify then
			t:SetJustifyH(justify)
		end
		return t
	end
	rs.title = Ink(18)
	rs.title:SetPoint("TOP", 0, -30)
	rs.title:SetText(L["Reconversion contract"])
	-- (five lines at most: the price under them, where it is in every language)
	rs.text = Ink(12)
	rs.text:SetPoint("TOP", 0, -60)
	rs.text:SetWidth(rw - 80)
	CuratorOctoFull.SetWordWrap(rs.text, true)
	rs.price = Ink(14)
	rs.price:SetPoint("TOP", 0, -144)
	rs.down = Ink(11)
	rs.down:SetPoint("TOP", 0, -164)
	-- the specialization after it (1.14.0: the five of them, in a row)
	rs.specs = {}
	local ns5 = CuratorOctoFull.Length(TL.SPECS)
	local bw = math.floor((rw - 80 - (ns5 - 1) * 8) / ns5)
	for i, spec in ipairs(TL.SPECS) do
		local i, spec = i, spec; local b = CreateFrame("Button", nil, rs)
		CuratorOctoFull.SetSize(b, bw, 74)
		b:SetPoint("TOPLEFT", rs, "TOPLEFT", 40 + (i - 1) * (bw + 8), -186)
		b.bg = Hud.Card(b, 0.75, "BACKGROUND")
		b.glow = Hud.CardGlow(b, 0.75)
		b.icon = Hud.RoundIcon(b, 30, "ARTWORK", 2)
		b.icon:SetPoint("TOP", 0, -9)
		Hud.SetIcon(b.icon, { spec.icon })
		b.ring = b:CreateTexture(nil, "OVERLAY")
		b.ring:SetTexture(MEDIA .. "IconRing")
		CuratorOctoFull.SetSize(b.ring, 40, 40)
		b.ring:SetPoint("CENTER", b.icon, "CENTER")
		b.name = S.Text(b, "GameFontNormalSmall")
		b.name:SetPoint("TOP", b.icon, "BOTTOM", 0, -6)
		b.name:SetWidth(bw - 6)
		CuratorOctoFull.SetWordWrap(b.name, true)
		if b.name.SetMaxLines then
			CuratorOctoFull.SetMaxLines(b.name, 2)
		end
		b.key = spec.key
		CuratorOctoFull.SetScript(b, "OnClick", function()
			if A.talRespec ~= spec.key then
				ns.Play(ns.SND.click)
				A.talRespec = spec.key
				A.talRespecOk = nil
				A:Refresh()
			end
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(TL:SpecName(spec.key, TL:Female()), spec.color[1], spec.color[2], spec.color[3])
			GameTooltip:AddLine(L[spec.desc], 1, 1, 1, true)
			GameTooltip:AddLine(spec.key == TL:Spec() and L["Place my points again"] or L["Switch to it"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		rs.specs[i] = b
	end
	-- the specialization chosen, under them
	rs.after = Ink(12)
	rs.after:SetPoint("TOP", rs, "TOP", 0, -270)
	rs.after:SetWidth(rw - 80)
	CuratorOctoFull.SetWordWrap(rs.after, true)
	rs.worth = Ink(12)
	rs.worth:SetPoint("TOP", rs, "TOP", 0, -296)
	rs.worth:SetWidth(rw - 80)
	CuratorOctoFull.SetWordWrap(rs.worth, true)
	rs.seal = rs:CreateTexture(nil, "OVERLAY")
	rs.seal:SetTexture(MEDIA .. "Seal")
	CuratorOctoFull.SetSize(rs.seal, 54, 54)
	rs.seal:SetPoint("BOTTOMRIGHT", rs.paper, "BOTTOMRIGHT", -26, 18)
	rs.sign = Hud.ClaimButton(rs, 190, 34, L["Sign the contract"])
	rs.sign:SetPoint("BOTTOM", rs, "BOTTOM", 0, 8)
	CuratorOctoFull.SetScript(rs.sign, "OnClick", function()
		A:SignRespec()
	end)
	rs.back = S.Button(rs, L["Back"], 110, 22)
	rs.back:SetPoint("RIGHT", rs.sign, "LEFT", -12, 0)
	CuratorOctoFull.SetScript(rs.back, "OnClick", function()
		ns.Play(ns.SND.page)
		A:TalentView("tree")
	end)
	rs.see = S.Button(rs, L["See the tree"], 130, 22)
	rs.see:SetPoint("LEFT", rs.sign, "RIGHT", 12, 0)
	CuratorOctoFull.SetScript(rs.see, "OnClick", function()
		ns.Play(ns.SND.page)
		A.talPreview = A.talRespec
		A.talReturn = "respec"
		A:TalentView("preview")
	end)
	rs:Hide()
	page.respec = rs

	-- the time of the talents to use moves on while the page is open
	page.tick = 0
	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		self.tick = self.tick + elapsed
		if self.tick >= 1 then
			self.tick = 0
			A:PaintActives()
		end
		self.t = (self.t or 0) + elapsed
		-- (the points placed and not applied breathe)
		for _, b in pairs(self.tree.nodes) do
			if b.pending then
				b.glow:SetAlpha(0.35 + 0.25 * math.sin(self.t * 4))
			end
		end
	end)
end

function A:ShowTalentsPage(shown)
	local f = self.frame
	if shown then
		self:BuildTalents()
	end
	if f.tal then
		CuratorOctoFull.SetShown(f.tal, shown)
	end
	if not shown then
		self.talApply, self.talChoose, self.talRespecOk = nil, nil, nil
	end
end

-- Another screen of the page: "tree", "choose", "preview", "respec".
function A:TalentView(view)
	self.talView = view
	self.talApply, self.talChoose, self.talRespecOk = nil, nil, nil
	if view == "respec" then
		self.talRespec = self.talRespec or TL:Spec()
	end
	if view ~= "preview" then
		self.talReturn = nil
	end
	self:Refresh()
end

-------------------------------------------------------------------------------
-- Painting the page
-------------------------------------------------------------------------------
function A:RefreshTalents()
	local f = self.frame
	local page = f.tal
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:ShowPager(false)
	self:RefreshFooter(false)
	local spec = TL:Spec()
	local view = self.talView
	if not spec then
		if view ~= "preview" then
			view = "choose"
		end
	elseif view ~= "respec" and view ~= "preview" then
		view = "tree"
	end
	if view == "preview" and not TL.SPEC_BY[self.talPreview or ""] then
		view = spec and "tree" or "choose"
	end
	self.talView = view
	local points, spent = TL:Points(), TL:Spent(spec and TL:Pending() or {})
	-- the head: the specialization, the points (1.14.0: the first at level 5, then one for each level)
	local level = TL:Level()
	if spec then
		self:SetTitle(TL:SpecName(spec, TL:Female()), L["Talents"] .. "  ·  " .. string.format(L["Collector level %d: %d points"], level, points))
		self:SetBar(spent, points, string.format(L["%d / %d points"], spent, points))
	else
		self:SetTitle(L["Talents"], string.format(L["Collector level %d: %d points"], level, points))
		self:SetBar(math.min(level, TL.CHOOSE), TL.CHOOSE, level >= TL.CHOOSE and L["Choose your specialization"] or string.format(L["Level %d / %d"], level, TL.CHOOSE))
	end
	CuratorOctoFull.SetShown(page.choose, view == "choose")
	local side = view ~= "choose"
	CuratorOctoFull.SetShown(page.spec, side)
	CuratorOctoFull.SetShown(page.points, side)
	CuratorOctoFull.SetShown(page.actives, side)
	CuratorOctoFull.SetShown(page.respecBtn, spec ~= nil and side)
	CuratorOctoFull.SetShown(page.respec, view == "respec")
	CuratorOctoFull.SetShown(page.tree, view == "tree" or view == "preview")
	CuratorOctoFull.SetShown(page.foot, view == "tree" or view == "preview")
	if view == "choose" then
		return self:PaintChoice()
	end
	self:PaintSpecPanel(view == "preview" and self.talPreview or spec)
	self:PaintPoints()
	self:PaintActives()
	if view == "respec" then
		return self:PaintRespec()
	end
	self:PaintTree(view == "preview" and self.talPreview or spec, view == "preview")
end

-- The specialization on the left.
function A:PaintSpecPanel(key)
	local sp = self.frame.tal.spec
	local def = TL.SPEC_BY[key or ""]
	if not def then
		return
	end
	Hud.SetIcon(sp.icon, { def.icon })
	sp.light:SetVertexColor(def.color[1], def.color[2], def.color[3])
	sp.name:SetText(TL:SpecName(key, TL:Female()))
	sp.name:SetTextColor(def.color[1], def.color[2], def.color[3])
	sp.desc:SetText(L[def.desc])
	-- (1.14.0: as tall as its words)
	local ok, h = pcall(sp.desc.GetStringHeight, sp.desc)
	h = ok and tonumber(h) or 60
	sp:SetHeight(math.max(160, 126 + h + 12))
	Hud.Each(sp.glow, "SetVertexColor", def.color[1], def.color[2], def.color[3])
	Hud.Each(sp.glow, "SetAlpha", (key == TL:Spec()) and 0.4 or 0)
end

function A:PaintPoints()
	local pt = self.frame.tal.points
	local spec = TL:Spec()
	local points = TL:Points()
	if not spec then
		pt.n:SetText(ns.Num(points))
		pt.left:SetText(L["points"])
		pt.note:SetText(points >= TL.CHOOSE and L["Choose a specialization to place them."] or string.format(L["The specialization is chosen at level %d."], TL.CHOOSE))
		return
	end
	local p = TL:Pending()
	local left = points - TL:Spent(p)
	pt.n:SetText(ns.Num(left))
	pt.left:SetText(left == 1 and L["point to place"] or L["points to place"])
	local pend = TL:PendingCount()
	if pend > 0 then
		pt.note:SetText("|cff" .. Hex(GREEN) .. string.format(L["%d placed, not applied"], pend) .. "|r")
	else
		pt.note:SetText(string.format(L["%d spent of %d"], TL:Spent(), points))
	end
end

-- The state of a talent to use: its words, their colour (Talents.lua, TL:ActiveState).
local PURPLE = { 0.85, 0.66, 1 }
function A:ActiveState(id)
	local d = TL.BY[id]
	local state, left = TL:ActiveState(id)
	if state == "running" then
		return string.format(L["Active: %s"], ns.Duration(left)), GREEN
	elseif state == "armed" then
		return L["Armed"], PURPLE
	elseif state == "waiting" then
		return L["To buy"], GOLDEN
	elseif state == "cooldown" then
		if d and d.limit then
			return string.format(L["Again in %s"], ns.Duration(left)), DIM
		end
		return string.format(L["Ready in %s"], ns.Duration(left)), DIM
	end
	return L["Ready"], GOLDEN
end

function A:PaintActives()
	local page = self.frame.tal
	if not (page and page:IsShown()) or not page.actives:IsShown() then
		return
	end
	local ac = page.actives
	local spec = TL:Spec()
	local list = {}
	if spec and self.talView ~= "preview" then
		for _, id in ipairs(ACTIVES[spec] or {}) do
			if TL:Has(id) then
				list[CuratorOctoFull.Length(list) + 1] = id
			end
		end
	end
	for i, r in ipairs(ac.rows) do
		local id = list[i]
		r.id = id
		CuratorOctoFull.SetShown(r, id ~= nil)
		if id then
			Hud.SetIcon(r.icon, { TL:Icon(TL.BY[id]) })
			local text, col = self:ActiveState(id)
			r.state:SetText(text)
			r.state:SetTextColor(col[1], col[2], col[3])
			local room = NAV_W - 24 - 23 - ns.TextWidth(r.state) - 6
			r.name:SetWidth(math.max(20, room))
			-- (a long name, in some languages: smaller until it fits beside its state)
			S.SetFontObject(r.name, "GameFontHighlightSmall")
			r.name:SetText(TL:Name(id))
			if ns.TextWidth(r.name) > math.max(20, room) then
				S.Fit(r.name, TL:Name(id), math.max(20, room), 10, 8)
			end
		end
	end
	ac:SetHeight(42 + math.max(1, CuratorOctoFull.Length(list)) * 22)
	CuratorOctoFull.SetShown(ac.empty, CuratorOctoFull.Length(list) == 0)
	ac.empty:SetText(spec and L["No talent to use yet: the third tier of your tree holds one."] or L["Your active talents show here."])
end

-- The talents to use: what a click does, or where they work.
local WHERE = {
	survey = "Click: start it now.",
	expedition = "Click: start it now.",
	mark = "Click: mark your target (a creature that has a card).",
	double = "Click: bet your next booster (click again: take the bet back).",
	wheel = "Click: spin the wheel.",
	blackmarket = "Click: see what the reseller has under his counter.",
	order = "At a reseller (a vendor of general goods or of trade supplies): the tab Under the counter of his window.",
	baron = "At a reseller: the button under a card of his stall.",
	glance = "It works at the banker, before you appraise a copy.",
	masterpiece = "It works on your next restoration at an enchanter.",
	freerestore = "It works on your next restoration at an enchanter, up to its flaws.",
	conservator = "It works on your next appraisal, by itself.",
	favored = "It works on your next appraisal, by itself.",
	weekpact = "It works on your next seal at a Master Warlock, by itself.",
	familyseal = "It works on your next seal at a Master Warlock, by itself.",
	dailyhead = "Its target: here, in the tooltip of the creature, and on the button of Price on its Head.",
	legendhead = "It works on your next Price on its Head.",
}
-- (the talents a click uses, here as on the bar of the boosters)
local CLICKS = { survey = true, expedition = true, mark = true, double = true, wheel = true, blackmarket = true, glance = true, order = true }

function A:ActiveTooltip(r)
	local id = r.id
	local d = id and TL.BY[id]
	if not d then
		return
	end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	self:TalentLines(d, TL:Rank(id), TL:Rank(id), false)
	local text, col = self:ActiveState(id)
	GameTooltip:AddLine(text, col[1], col[2], col[3])
	if id == "dailyhead" and TL:Ready("dailyhead") then
		local target = TL:DailyTarget()
		if target then
			GameTooltip:AddLine(string.format(L["Contract of the Day: %s (%s)."], ns.Collection:Name(target), ns.Collection:SeriesName(target.series)), 1, 0.45, 0.32, true)
		end
	elseif id == "blackmarket" then
		local card, price = TL:BlackMarket()
		if card then
			GameTooltip:AddLine(string.format(L["Under the counter: %s, for %s."], ns.Collection:Name(card), ns.Rubies.Text(price)), 1, 0.82, 0.36, true)
		end
	end
	GameTooltip:AddLine(L[WHERE[id] or "It works by itself."], GOLDEN[1], GOLDEN[2], GOLDEN[3], true)
	GameTooltip:Show()
end

function A:ActiveClick(r)
	local id = r.id
	if not (id and CLICKS[id]) then
		return
	end
	local ok, why = TL:Activate(id)
	if ok then
		local d = TL.BY[id]
		Hud.Burst(r, TL.SPEC_BY[d.spec].color, 12, 90, 14)
	else
		ns.Play(ns.SND.close)
		if why == "ready" then
			ns.Print(L["%s recharges: ready in %s."], TL:Name(id), ns.Duration(TL:Left(id)))
		end
	end
	self:PaintActives()
	if r:IsMouseOver() then
		self:ActiveTooltip(r)
	end
end

-- The colours of the game: the slot and the rank of a talent where a point can go (green), of one with
-- every rank (gold), of one that cannot be taken yet (grey).
local GREEN_SLOT, GOLD_SLOT, GREY_SLOT = { 0.1, 1, 0.1 }, { 1, 0.82, 0 }, { 0.5, 0.5, 0.5 }

-- The tree of a specialization (preview: looked at, not mine), as the game paints its talents: a talent
-- whose tier is open, whose need is met, with a point to place or points in it, in colour (green, gold
-- with every rank); the others grey, their rank hidden while they have none.
-- (1.11.0) The lines of the tiers: an open tier in gold, a closed one dim with the points it asks (1.12.0:
-- spent in the tier above it; past the legend, the level it waits for); their words on the left, moved
-- aside of the branches that cross them.
function A:PaintTiers(tree, key, ranks, mine)
	if not tree.tiers then
		return
	end
	local w = tree:GetWidth()
	for t, tr in ipairs(tree.tiers) do
		local gate = TL.Gate(t, key)
		local above = t > 1 and TL.InTier(ranks, key, t - 1) or 0
		local open, why, at = false, nil, nil
		if mine then
			open, why, at = TL:TierOpen(ranks, key, t)
		end
		local text
		if t == 1 or open then
			text = string.format(L["Tier %d"], t)
		elseif mine and why == "legend" then
			text = string.format(L["Tier %d · level %d"], t, TL:LegendLevel())
		elseif mine and at == t then
			text = string.format((gate == 1 and L["Tier %d · %d / 1 point"] or L["Tier %d · %d / %d points"]), t, math.min(above, gate), gate)
		elseif mine then
			-- (a tier above it still closed: what this one will ask)
			text = string.format((gate == 1 and L["Tier %d · 1 point"] or L["Tier %d · %d points"]), t, gate)
		else
			text = string.format((gate == 1 and L["Tier %d · 1 point"] or L["Tier %d · %d points"]), t, gate)
		end
		tr.text:SetText(text)
		local c = (open or (t == 1 and mine)) and GOLDEN or DIM
		tr.text:SetTextColor(c[1], c[2], c[3])
		tr.line:SetAlpha((open or (t == 1 and mine)) and 0.9 or 0.35)
		-- (its words: from the left, past the branches that go down through them)
		local tw = ns.TextWidth(tr.text) or 80
		local y2 = tr.y - 2
		local y1 = y2 - 13
		local busy = {}
		for _, way in ipairs(tree.ways or {}) do
			local pts = way.way
			for i = 1, CuratorOctoFull.Length(pts) - 1 do
				local p, q = pts[i], pts[i + 1]
				if math.abs(p[1] - q[1]) < 0.5 then
					local a, b = math.min(p[2], q[2]), math.max(p[2], q[2])
					if b > y1 and a < y2 then
						busy[CuratorOctoFull.Length(busy) + 1] = { p[1] - 8, p[1] + 8 }
					end
				end
			end
		end
		local x = 12
		local moved = true
		while moved do
			moved = false
			for _, r in ipairs(busy) do
				if x < r[2] and x + tw > r[1] then
					x = r[2] + 4
					moved = true
				end
			end
		end
		x = math.min(x, math.max(12, w - tw - 12))
		tr.text:ClearAllPoints()
		tr.text:SetPoint("BOTTOMLEFT", tree.body, "TOPLEFT", x, -y2)
	end
	if tree.pastText then
		local open = mine and TL:TierOpen(ranks, key, TL.LEGEND_TIER or 8)
		local c = open and GOLDEN or { 0.9, 0.78, 0.45 }
		tree.pastText:SetTextColor(c[1], c[2], c[3])
	end
end

function A:PaintTree(key, preview)
	local page = self.frame.tal
	local tree = page.tree
	local mine = not preview and key == TL:Spec()
	local ranks = mine and TL:Pending() or {}
	local base = mine and TL:Ranks() or {}
	local col = TL.SPEC_BY[key].color
	PaintArt(tree, key)
	local left = mine and (TL:Points() - TL:Spent(ranks)) or 0
	for id, b in pairs(tree.nodes) do
		local d = b.d
		local here = d.spec == key
		CuratorOctoFull.SetShown(b, here)
		if here then
			local r = ranks[id] or 0
			local applied = base[id] or 0
			local open = TL:TierOpen(ranks, key, d.tier)
			local need = true
			if d.req then
				need = false
				for _, n in ipairs(d.req) do
					if (ranks[n] or 0) > 0 then
						need = true
					end
				end
			end
			local out = false
			for _, o in ipairs(TL.ChoiceOf(d) or {}) do
				if o ~= d and (ranks[o.id] or 0) > 0 then
					out = true
				end
			end
			local state
			if preview then
				state = "look"
			elseif open and need and not out and (left > 0 or r > 0) then
				state = r >= d.ranks and "max" or (r > 0 and "learned" or "open")
			else
				state = "closed"
			end
			b.state, b.mine, b.r, b.applied = state, mine, r, applied
			b.pending = mine and r > applied
			local slot = (state == "max" and GOLD_SLOT) or ((state == "open" or state == "learned") and GREEN_SLOT) or GREY_SLOT
			if state == "look" then
				slot = { 0.82, 0.82, 0.82 }
			end
			b.slot:SetVertexColor(slot[1], slot[2], slot[3])
			local grey = state == "closed"
			b.icon:SetDesaturated(grey)
			if grey then
				b.icon:SetVertexColor(0.65, 0.65, 0.65)
			else
				b.icon:SetVertexColor(1, 1, 1)
			end
			-- its rank in the box at its corner (hidden while it has none and cannot have one)
			local showRank = state ~= "look" and not (grey and r == 0)
			CuratorOctoFull.SetShown(b.rankBorder, showRank)
			CuratorOctoFull.SetShown(b.rank, showRank)
			b.rank:SetText(r)
			local c = grey and GREY_SLOT or (state == "max" and GOLD_SLOT) or GREEN_SLOT
			b.rank:SetTextColor(c[1], c[2], c[3])
			b.rankBorder:SetVertexColor(grey and 0.5 or 1, grey and 0.5 or 1, grey and 0.5 or 1)
			b.glow:SetVertexColor(col[1], col[2], col[3])
			if not b.pending then
				b.glow:SetAlpha(0)
			end
		end
	end
	-- the branches: from a talent to those that need it (gold once it has a point)
	for i = 1, tree.used do
		tree.pieces[i]:Hide()
	end
	tree.used = 0
	local ways = {}
	for _, d in ipairs(TL.LIST) do
		if d.spec == key and d.req then
			for _, n in ipairs(d.req) do
				local from = TL.BY[n]
				if from then
					ways[CuratorOctoFull.Length(ways) + 1] = { way = Way(tree, from, d, ways), from = from, to = d, on = not preview and (ranks[n] or 0) > 0 }
				end
			end
		end
	end
	-- (the grey ones first: where two meet, the gold one shows)
	table.sort(ways, function(p, q)
		return (p.on and 1 or 0) < (q.on and 1 or 0)
	end)
	for _, w in ipairs(ways) do
		DrawWay(tree, w.way, w.on)
	end
	tree.ways = ways
	self:PaintTiers(tree, key, ranks, mine)
	-- (1.11.0) where the tree is seen: the first time, the tiers past the legend for a collector past it
	if not tree.placed then
		tree.placed = true
		self:ScrollTree((mine and TL:PastLegend()) and tree.bodyH or 0)
	else
		self:ScrollTree(tree.scroll)
	end
	-- under it
	local foot = page.foot
	local pend = mine and TL:PendingCount() or 0
	CuratorOctoFull.SetShown(foot.apply, mine)
	CuratorOctoFull.SetShown(foot.cancel, mine)
	CuratorOctoFull.SetEnabled(foot.cancel, pend > 0)
	CuratorOctoFull.SetShown(foot.back, preview)
	if preview then
		foot.note:SetText(string.format(L["A look at a tree (%s): nothing is placed."], TL:SpecName(key, TL:Female())))
	elseif pend > 0 then
		local confirm = self.talApply and GetTime() - self.talApply < CONFIRM
		foot.note:SetText(confirm and ("|cffffd060" .. L["Applied points stay: only a reconversion contract frees them."] .. "|r")
			or string.format(L["%d points placed: apply them to make them count."], pend))
		foot.apply:SetLabel(confirm and L["Confirm"] or L["Apply changes"])
		CuratorOctoFull.SetEnabled(foot.apply, true)
	else
		local free = TL:Points() - TL:Spent()
		foot.note:SetText(free > 0 and L["Click: a point · Right click: take it back (before you apply them)"] or L["Every point is placed. Each collector level gives one more."])
		foot.apply:SetLabel(L["Apply changes"])
		CuratorOctoFull.SetEnabled(foot.apply, false)
	end
end

-- The lines of a talent in a tooltip: its name, its rank, what it does (at its rank, then at the next
-- one), what it needs. r: its rank there, applied: its rank applied; look: a talent looked at.
function A:TalentLines(d, r, applied, look)
	local col = TL.SPEC_BY[d.spec].color
	GameTooltip:AddLine(L[d.name], col[1], col[2], col[3])
	if not look then
		GameTooltip:AddLine(string.format(L["Rank %d/%d"], r, d.ranks), 1, 0.82, 0.3)
	end
	if d.active then
		GameTooltip:AddLine(L["Active talent"], 0.55, 0.85, 1)
	elseif d.limit == "day" then
		GameTooltip:AddLine(L["Once a day"], 0.55, 0.85, 1)
	elseif d.limit == "week" then
		GameTooltip:AddLine(L["Once a week"], 0.55, 0.85, 1)
	end
	GameTooltip:AddLine(TL:Text(d.id, math.max(1, r)), 1, 1, 1, true)
	if r > 0 and r < d.ranks then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Next rank:"], 1, 0.82, 0.3)
		GameTooltip:AddLine(TL:Text(d.id, r + 1), 1, 1, 1, true)
	end
	if d.choice then
		local other
		for _, o in ipairs(TL.ChoiceOf(d) or {}) do
			if o ~= d then
				other = o
			end
		end
		if other then
			GameTooltip:AddLine(string.format(L["A choice: this talent or %s, not both."], L[other.name]), 0.85, 0.7, 1, true)
		end
	end
	-- (1.14.0: a summit, its achievement and its title)
	if d.capstone then
		GameTooltip:AddLine(L["A summit of the tree: the first time it works, an achievement and a title of prestige."], 1, 0.82, 0.3, true)
	end
end

function A:TalentTooltip(b)
	local d = b.d
	if not d then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	local preview = not b.mine
	self:TalentLines(d, b.r or 0, b.applied or 0, preview)
	if not preview then
		local ranks = TL:Pending()
		local open, why, at = TL:TierOpen(ranks, d.spec, d.tier)
		if not open and why == "legend" then
			GameTooltip:AddLine(string.format(L["Requires collector level %d (past the legend)."], TL:LegendLevel()), 1, 0.3, 0.3, true)
		elseif not open then
			-- (1.12.0: the tier above the first one still closed)
			local gate = TL.Gate(at, d.spec)
			local text = gate == 1 and string.format(L["Requires 1 point in tier %d."], at - 1) or string.format(L["Requires %d points in tier %d."], gate, at - 1)
			GameTooltip:AddLine(text, 1, 0.3, 0.3, true)
		end
		if d.req then
			local ok = false
			local names = {}
			for _, need in ipairs(d.req) do
				names[CuratorOctoFull.Length(names) + 1] = TL:Name(need)
				if (ranks[need] or 0) > 0 then
					ok = true
				end
			end
			if not ok then
				GameTooltip:AddLine(string.format(L["Requires: %s"], table.concat(names, L[" or "])), 1, 0.3, 0.3, true)
			end
		end
		if d.active and (b.applied or 0) > 0 then
			local text, col = self:ActiveState(d.id)
			GameTooltip:AddLine(text, col[1], col[2], col[3])
		end
		local ok, why = TL:CanAdd(ranks, d.id)
		if ok then
			GameTooltip:AddLine(L["Click: one point"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		elseif why == "points" and (b.r or 0) < d.ranks then
			GameTooltip:AddLine(L["No point left to place: each collector level gives one."], 0.8, 0.8, 0.8, true)
		end
		if (b.r or 0) > (b.applied or 0) then
			GameTooltip:AddLine(L["Right click: take the point back"], GOLDEN[1], GOLDEN[2], GOLDEN[3])
		end
	end
	GameTooltip:Show()
end

function A:TalentClick(b, button)
	if not b.mine then
		return
	end
	local d = b.d
	local ok
	if button == "RightButton" then
		ok = TL:RemovePoint(d.id)
		if ok then
			ns.Play(ns.SND.cardFlip)
		end
	else
		ok = TL:AddPoint(d.id)
		if ok then
			ns.Play(ns.SND.ink)
			Hud.Burst(b, TL.SPEC_BY[d.spec].color, 8, 70, 12)
		end
	end
	if not ok then
		ns.Play(ns.SND.close)
	end
	self.talApply = nil
	if b:IsMouseOver() then
		self:Refresh()
		self:TalentTooltip(b)
	end
end

-- Apply (two clicks: the points placed stay).
function A:ApplyTalents()
	if TL:PendingCount() <= 0 then
		return
	end
	if not (self.talApply and GetTime() - self.talApply < CONFIRM) then
		self.talApply = GetTime()
		ns.Play(ns.SND.click)
		self:Refresh()
		ns.Delay(CONFIRM + 0.05, function()
			if A.talApply and GetTime() - A.talApply >= CONFIRM then
				A.talApply = nil
				if A.frame:IsShown() and A.mode == "talents" then
					A:Refresh()
				end
			end
		end, self)
		return
	end
	self.talApply = nil
	local before = TL.Copy(TL:Ranks())
	if not TL:Apply() then
		ns.Play(ns.SND.close)
		return
	end
	ns.Play(ns.SND.rankUp)
	local tree = self.frame.tal.tree
	local col = TL:SpecDef().color
	for id, r in pairs(TL:Ranks()) do
		if r > (before[id] or 0) and tree.nodes[id] then
			Hud.Burst(tree.nodes[id], col, 14, 120, 16)
		end
	end
end

-------------------------------------------------------------------------------
-- The screen of the choice
-------------------------------------------------------------------------------
-- (what a talent is, in the list of the choice: its tier and its kind)
local function Tag(d)
	local kind = (d.capstone and L["Summit"]) or (d.active and L["Active"]) or (d.limit == "day" and L["Once a day"])
		or (d.limit == "week" and L["Once a week"]) or nil
	local tier = string.format(L["Tier %d"], d.tier)
	return kind and (tier .. "  ·  " .. kind) or tier
end

function A:PaintChoice()
	local ch = self.frame.tal.choose
	local can = TL:CanChoose()
	if can then
		ch.head:SetText(L["Choose your specialization: it is the one of your whole account. Your first talent point comes with it, then one more with each collector level."])
	else
		ch.head:SetText(string.format(L["Your specialization is chosen at collector level %d (you are level %d): your first talent point comes with it, then one more with each level. Look at the trees meanwhile."], TL.CHOOSE, TL:Level()))
	end
	ch.foot:SetText(L["The choice is for good: changing your specialization later asks for a reconversion contract, paid in rubies (the first one is offered)."])
	local female = TL:Female()
	local look = TL.SPEC_BY[self.talLook or ""] and self.talLook or TL.SPECS[1].key
	self.talLook = look
	for _, c in ipairs(ch.medals) do
		local def = TL.SPEC_BY[c.key]
		local on = c.key == look
		Hud.SetIcon(c.icon, { def.icon })
		c.icon:SetDesaturated(not on)
		c.light:SetVertexColor(def.color[1], def.color[2], def.color[3])
		c.light:SetAlpha(on and 0.6 or 0.15)
		c.name:SetText(TL:SpecName(c.key, female))
		if on then
			c.name:SetTextColor(def.color[1], def.color[2], def.color[3])
		else
			c.name:SetTextColor(0.75, 0.75, 0.78)
		end
		Hud.Each(c.glow, "SetVertexColor", def.color[1], def.color[2], def.color[3])
		Hud.Each(c.glow, "SetAlpha", on and 0.7 or 0)
	end
	local dt = ch.detail
	local def = TL.SPEC_BY[look]
	PaintArt(dt, look)
	for _, t in ipairs(dt.art) do
		t:SetAlpha(0.32)
	end
	Hud.SetIcon(dt.icon, { def.icon })
	dt.light:SetVertexColor(def.color[1], def.color[2], def.color[3])
	dt.name:SetText(TL:SpecName(look, female))
	dt.name:SetTextColor(def.color[1], def.color[2], def.color[3])
	dt.role:SetText(string.format(L["A tree of %d ranks, ten tiers"], TL.RANKS[look] or 0))
	dt.desc:SetText(L[def.desc])
	Hud.Each(dt.glow, "SetVertexColor", def.color[1], def.color[2], def.color[3])
	for k, ln in ipairs(dt.lines) do
		local id = HIGHLIGHTS[look][k]
		local d = id and TL.BY[id]
		ln.id = id
		CuratorOctoFull.SetShown(ln, d ~= nil)
		if d then
			Hud.SetIcon(ln.icon, { TL:Icon(d) })
			ln.name:SetText(TL:Name(id))
			ln.name:SetTextColor(def.color[1], def.color[2], def.color[3])
			ln.tag:SetText(Tag(d))
			ln.name:SetWidth(math.max(60, ln:GetWidth() - 56 - (ns.TextWidth(ln.tag) or 80) - 12))
			ln.desc:SetText(TL:Text(id, 1))
		end
	end
	local confirm = self.talChoose and self.talChoose.key == look and GetTime() - self.talChoose.t < CONFIRM
	CuratorOctoFull.SetShown(dt.choose, can)
	dt.choose:SetLabel(confirm and string.format(L["Confirm: %s"], TL:SpecName(look, female)) or string.format(L["Choose: %s"], TL:SpecName(look, female)))
	dt.choose:SetPulse(confirm and true or false)
	Hud.Each(dt.glow, "SetAlpha", confirm and 0.8 or 0.25)
end

function A:ChooseSpec(key)
	if not TL:CanChoose() or TL:Spec() then
		return
	end
	if not (self.talChoose and self.talChoose.key == key and GetTime() - self.talChoose.t < CONFIRM) then
		self.talChoose = { key = key, t = GetTime() }
		ns.Play(ns.SND.click)
		self:Refresh()
		ns.Delay(CONFIRM + 0.05, function()
			if A.talChoose and GetTime() - A.talChoose.t >= CONFIRM then
				A.talChoose = nil
				if A.frame:IsShown() and A.mode == "talents" then
					A:Refresh()
				end
			end
		end, self)
		return
	end
	self.talChoose = nil
	if TL:Choose(key) then
		ns.Play(ns.SND.rankUp)
		self.talView = "tree"
		self:Refresh()
		local sp = self.frame.tal.spec
		Hud.Burst(sp, TL.SPEC_BY[key].color, 24, 160, 18)
		ns.Print(L["Specialization chosen: %s. Place your talent points in its tree."], TL:SpecName(key, TL:Female()))
	end
end

-------------------------------------------------------------------------------
-- The contract of reconversion
-------------------------------------------------------------------------------
function A:PaintRespec()
	local rs = self.frame.tal.respec
	local cur = TL:Spec()
	local target = TL.SPEC_BY[self.talRespec or ""] and self.talRespec or cur
	self.talRespec = target
	local cost = TL:RespecCost()
	-- (1.11.0) paid in rubies: no copy of the collection goes any more
	local RB = ns.Rubies
	rs.text:SetText(L["Change your specialization, or place your points again in yours. It is paid in rubies, earned with your quests, your achievements and your levels. Its price doubles with each reconversion and comes down a step for each month without one."])
	-- (1.14.0: the first one offered, every tree being new)
	if TL:FreeRespec() then
		rs.price:SetText(L["Price: offered, your first reconversion"])
	else
		rs.price:SetText(string.format(L["Price: %s"], RB.Text(cost, 16)))
	end
	local down = TL:RespecDown()
	rs.down:SetText(down and string.format(L["Goes down a step in %s"], ns.Duration(down)) or L["At its lowest price"])
	local female = TL:Female()
	for _, b in ipairs(rs.specs) do
		local def = TL.SPEC_BY[b.key]
		local on = b.key == target
		b.name:SetText(TL:SpecName(b.key, female))
		b.name:SetTextColor(def.color[1], def.color[2], def.color[3])
		Hud.Each(b.glow, "SetVertexColor", def.color[1], def.color[2], def.color[3])
		Hud.Each(b.glow, "SetAlpha", on and 0.8 or 0)
		b.icon:SetDesaturated(not on)
	end
	local tdef = TL.SPEC_BY[target]
	local tname = "|cff" .. Hex(tdef.color) .. TL:SpecName(target, female) .. "|r"
	rs.after:SetText(target == cur and string.format(L["After it: %s, your points to place again."], tname) or string.format(L["After it: %s, its tree and your points to place."], tname))
	local have = RB:Balance()
	local enough = have >= cost and not (ns.Beta and ns.Beta:Over())
	if cost <= 0 then
		rs.worth:SetText(string.format(L["Your rubies: %s. It costs you nothing."], RB.Text(have, 14)))
		rs.worth:SetTextColor(0.30, 0.18, 0.08)
	elseif enough then
		rs.worth:SetText(string.format(L["Your rubies: %s. Left after it: %s."], RB.Text(have, 14), RB.Text(have - cost, 14)))
		rs.worth:SetTextColor(0.30, 0.18, 0.08)
	else
		rs.worth:SetText(string.format(L["Your rubies: %s. Not enough for it: they come with your quests, your achievements and your levels."], RB.Text(have, 14)))
		rs.worth:SetTextColor(0.62, 0.08, 0.05)
	end
	local confirm = self.talRespecOk and GetTime() - self.talRespecOk < CONFIRM
	CuratorOctoFull.SetEnabled(rs.sign, enough)
	rs.sign:SetLabel(confirm and L["Confirm"] or L["Sign the contract"])
	rs.sign:SetPulse(confirm and true or false)
	rs.seal:SetDesaturated(not enough)
	rs.seal:SetAlpha(enough and 1 or 0.4)
end

function A:SignRespec()
	local target = self.talRespec
	if not (target and TL:Spec()) then
		return
	end
	if not (self.talRespecOk and GetTime() - self.talRespecOk < CONFIRM) then
		self.talRespecOk = GetTime()
		ns.Play(ns.SND.click)
		self:Refresh()
		ns.Delay(CONFIRM + 0.05, function()
			if A.talRespecOk and GetTime() - A.talRespecOk >= CONFIRM then
				A.talRespecOk = nil
				if A.frame:IsShown() and A.mode == "talents" then
					A:Refresh()
				end
			end
		end, self)
		return
	end
	self.talRespecOk = nil
	local ok, paid = TL:Respec(target)
	if not ok then
		ns.Play(ns.SND.close)
		self:Refresh()
		return
	end
	ns.Play(ns.SND.seal)
	ns.Play(ns.SND.burn)
	ns.Print(L["Reconversion contract signed (%s): %s. Your points are free again."], ns.Rubies.Text(paid), TL:SpecName(target, TL:Female()))
	self.talRespec = nil
	self:TalentView("tree")
end

-------------------------------------------------------------------------------
-- Elsewhere: the creatures (Tracking), the toasts of the talents, the badge of the tab
-------------------------------------------------------------------------------
-- (1.14.0) The creatures, in their tooltip: during a Survey (the Cartographer), those whose card the album of the zone is
-- missing; the creature marked by a Price on its Head, the target of the Contract of the Day (the Bounty Hunter).
local function NpcOf(guid)
	if type(guid) ~= "string" or Secret(guid) then
		return nil
	end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind == "Creature" or kind == "Vehicle" then
		return tonumber(id)
	end
end

local function OnCreatureTooltip(tooltip)
	if tooltip ~= GameTooltip or not ns.db then
		return
	end
	local spec = TL:Spec()
	if spec ~= "carto" and spec ~= "hunter" then
		return
	end
	local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
	if not ok or not unit or Secret(unit) then
		return
	end
	local ok2, player = pcall(UnitIsPlayer, unit)
	if not ok2 or Secret(player) or player then
		return
	end
	local ok3, guid = pcall(UnitGUID, unit)
	if not ok3 then
		return
	end
	local npc = NpcOf(guid)
	local card = npc and ns.Cards["c" .. npc]
	if not card then
		return
	end
	local added = false
	if spec == "carto" then
		local zone = ns.Rewards and ns.Rewards:ZoneSeries()
		if TL:SurveyLeft() > 0 and zone and card.series == zone and TL.Missing(card) then
			local r = ns.RARITY[card.rarity]
			local gem = "|T" .. MEDIA .. "Gem" .. card.rarity .. ":12:12:0:0|t "
			tooltip:AddLine(gem .. string.format(L["Survey: its card is missing from your album (%s)."], "|cff" .. Hex(r.text) .. L[r.label] .. "|r"), 0.45, 1, 0.55, true)
			added = true
		end
	else
		if TL:Marked(guid) then
			tooltip:AddLine(string.format(L["Price on its Head: %s left."], ns.Duration(TL:MarkLeft())), 1, 0.45, 0.32)
			added = true
		end
		if TL:Ready("dailyhead") and TL:DailyTarget() == card then
			tooltip:AddLine(L["Contract of the Day: defeat it, its card is yours."], 1, 0.82, 0.3, true)
			added = true
		end
	end
	if added then
		tooltip:Show()
	end
end
TL.OnCreatureTooltip = OnCreatureTooltip

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
	local unitType = (Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit) or 2
	TooltipDataProcessor.AddTooltipPostCall(unitType, OnCreatureTooltip)
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetUnit", OnCreatureTooltip)
end

-- The page follows the talents and the level.
for _, e in ipairs({ "TALENTS_CHANGED", "TALENTS_PENDING", "TALENT_USED", "TALENT_ARMED", "TALENT_RUNNING", "LEVEL_UP" }) do
	local _, e = _, e; ns.On(e, function()
		local f = A.frame
		if not (f and f:IsShown()) then
			return
		end
		if A.mode == "talents" then
			A:Refresh()
		else
			A:PaintBadges()
		end
	end)
end

-- The points to place: the badge of the tab (and a choice to make, from level 5).
function TL:Waiting()
	if not ns.db then
		return 0
	end
	if not self:Spec() then
		return self:CanChoose() and 1 or 0
	end
	return math.max(0, self:Points() - self:Spent())
end

-- A level that gives a point: said in the chat (at level 5, the choice).
ns.On("LEVEL_UP", function(level, before)
	if not ns.db or level <= (before or 0) then
		return
	end
	if not TL:Spec() then
		if level >= TL.CHOOSE and (before or 0) < TL.CHOOSE then
			ns.Print(L["Level %d: choose your talent specialization (/curator talents)."], TL.CHOOSE)
		end
		return
	end
	-- (1.14.0: past the legend, a point every two levels)
	if TL:Points(level) > TL:Points(before or (level - 1)) then
		ns.Print(L["A new talent point to place (/curator talents)."])
	end
end)

-- The toasts of the talents: a card given (Explorer), boosters more (Beaten Track, Broker, Steady
-- Income).
local function Toast(item)
	if ns.Toast then
		ns.Toast:Push(item)
	end
end

ns.On("TALENT_CARD", function(id, card, chest)
	local C = ns.Collection
	-- (1.14.0: the card of a reroll, in its chest: Reroll.lua)
	local line = ns.Toast and ns.Toast.Line and ns.Toast.Line(card) or C:SeriesName(card.series)
	if chest then
		line = string.format(L["In this character's chest: it opens at level %d."], ns.Reroll and ns.Reroll.LEVEL or 15)
	end
	Toast({
		title = string.format(L["%s: a card!"], TL:Name(id)),
		name = C:Name(card),
		color = ns.RARITY[card.rarity].text,
		line = line,
		card = card,
		sound = ns.SND.reveal[card.rarity] or ns.SND.shiny,
		onClick = function()
			A:ShowSeries(card.series)
		end,
	})
end)

-- (1.14.0) The toasts of the talents of an album that reaches a part of its cards (Atlas, Road of Gems). (Bounty Board
-- and Gladiator, their booster to choose: gone with the PvP.)
ns.On("TALENT_PROC", function(id, s, part)
	if id == "atlas" and type(s) == "table" and type(part) == "number" then
		Toast({
			title = string.format(L["%s: %d%% of the album!"], TL:Name("atlas"), math.floor(part * 100 + 0.5)),
			name = ns.Collection:SeriesName(s),
			color = { 0.42, 0.88, 0.56 },
			line = L["Rubies for your Atlas: the album of a zone, a part of its cards."],
			tex = { s.set or "SetElwynn" },
			sound = ns.SND.coins,
			onClick = function()
				A:ShowSeries(s)
			end,
		})
	end
end)
