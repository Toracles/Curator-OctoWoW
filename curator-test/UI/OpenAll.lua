local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease
local C = ns.Collection

-------------------------------------------------------------------------------
-- (1.13.0, after its first test) Open all: the boosters of an album opened one after the other, ten at most at
-- once, then every card of them on the screen (UI/Booster.lua). The packs come down in a row under the place of
-- the cards; each one in turn shakes, its light in the colour of its best card, and bursts: its cards fly out of
-- it to their places, face down. Once they are all there, they turn over in a wave across the screen; the best
-- ones last, each with its light and its sound (a legendary or a mythic card makes its entrance: UI/Cinematic.lua).
-- Then the album fills, the experience of the collector (its screen when a level is gained), the screen of an
-- album complete; and a button opens the ten next ones.
-- Each booster is C:Open's, as one opened alone: its pack spent, its cards kept at once (closing the scene early
-- loses none), its journal, the achievements, the quests, the experience, the guild, the talents. Never a golden
-- booster, a preview, or the Omen. Stop: no other pack opens (they stay in the album), the cards drawn turn over
-- at once.
-- A hundred cards at once: the small cards, their words too small to be read left out (their name alone, larger),
-- the creatures of the best ones only, still (in the window of the others, the portrait of their creature, a
-- picture the client draws once); the card under the mouse comes larger, its creature with it; a click looks at it
-- closely (UI/Inspect.lua).
-------------------------------------------------------------------------------
local B = ns.Booster
local U = B.U
local Tex, FadeIn, GlowTo, Mix, At = U.Tex, U.FadeIn, U.GlowTo, U.Mix, U.At
local PACK_W, PACK_H, TOP_H = U.PACK_W, U.PACK_H, U.TOP_H
local WHITE, WARM = U.WHITE, U.WARM
local TELL, WAVES, RAINBOW, Struck = U.TELL, U.WAVES, U.RAINBOW, U.Struck
local AURA_GLOW, AURA_RAYS, DARK = U.AURA_GLOW, U.AURA_RAYS, U.DARK

-- ten boosters at most at once
local MAX = 10
-- Where things are, in points of the scene: the name of the album HEAD_PAD under its top, smaller (HEAD_K); the
-- grid of the cards from TOP_PAD under its top down to BOTTOM_PAD over its bottom, SIDE from its edges; under the
-- grid, the row of the packs (its middle ROW_Y over the bottom), then the words of the end, the bars and the
-- buttons (END_Y over the bottom: where a booster has them on a screen of 768 points, lower on a taller one).
local TOP_PAD, BOTTOM_PAD, SIDE = 84, 208, 34
local ROW_Y = 118
local HEAD_PAD, HEAD_K = 44, 0.78
local END_Y = { summary = 194, bar = 170, xp = 144, buttons = 100, smallButtons = 62 }
-- The gaps of the grid: between two cards (of their width, of their height), and between two boosters on a row
-- (of the width of a card); its cards never larger than MAX_K times the small card. The packs of the row: PACK_K
-- times the pack of the scene at most, ROW_GAP of their width apart.
local GX, GY, GROUP = 0.08, 0.075, 0.2
local MAX_K = 1.2
local PACK_K, ROW_GAP = 0.42, 0.32
-- Under TINY_K times the small card, the words of a card are too small: its name alone, NAME_PT points on the
-- screen, NAME_MIN for a long one (B:BatchName).
local TINY_K, NAME_PT, NAME_MIN = 1, 9, 7
-- The rhythm, by the best card of a pack (seconds): its light before it bursts, then the next pack; the packs
-- coming down; the cards flying to their places; the wave that turns them over (the whole grid, the best ones
-- left for the end).
local CHARGE = { 0.12, 0.13, 0.17, 0.3, 0.5, 0.66 }
local AFTER = { 0.13, 0.13, 0.16, 0.32, 0.55, 0.72 }
local DROP, DROP_EVERY = 0.36, 0.045
local FLY, FLY_EVERY = 0.46, 0.022
local WAVE = 1.5
-- The card under the mouse: this many times its size in the grid (as large as a card of a booster of a zone at
-- least: its words can be read).
local ZOOM = 1.9
-- A sound of a card turned over at most every FLIP_EVERY seconds (a hundred of them at once would be noise), of a
-- rare one every RARE_EVERY.
local FLIP_EVERY, RARE_EVERY = 0.06, 0.12

-- The best cards of the batch, those that turn over after the wave: epic and up, or with a finish.
local function Special(pick)
	return pick.card.rarity >= 4 or pick.finish ~= nil
end

-- Their order: the lesser ones first; the finishes after the cards of their rarity (a titanforged or corrupted
-- one after all of them, as in a booster).
local function Rank(pick)
	return pick.card.rarity * 10 + (pick.finish and 4 or 0) + (Struck(C:FinishLook(pick.card, pick.finish)) and 60 or 0)
end

-- A card shown without its creature (the creature costs; the creatures of the best ones only): the card itself
-- for the rest of what it shows.
local LITE = {}
local function Lite(card)
	local t = LITE[card]
	if not t then
		t = setmetatable({ display = false }, { __index = card })
		LITE[card] = t
	end
	return t
end

-------------------------------------------------------------------------------
-- The place of the grid, and where each card goes in it
-------------------------------------------------------------------------------
-- The place of the grid in points of the stage (left, right, bottom, top), and the size of the scene.
function B:BatchArea()
	local s = self.frame
	local w, h = s:GetWidth(), s:GetHeight()
	if not (w and w > 0 and h and h > 0) then
		w, h = 1365, 768
	end
	return -w / 2 + SIDE, w / 2 - SIDE, -h / 2 + BOTTOM_PAD, h / 2 - TOP_PAD, w, h
end

-- The grid of n cards (per: the cards of a booster) in a place of W x H points: its columns and its rows, the
-- scale of its cards (as large as they can be; rows that hold whole boosters, a little better: each booster in a
-- row, or a gap between them on a row).
local function Fit(n, per, W, H, cw, ch)
	local best
	n = math.max(1, n)
	for cols = 1, n do
		local rows = math.ceil(n / cols)
		local whole = per and per > 1 and n > per and CuratorOctoFull.Mod(cols , per) == 0
		local groups = (whole and cols > per) and (cols / per) or 1
		local wk = W / (cw * (cols + (cols - 1) * GX + (groups - 1) * GROUP))
		local hk = H / (ch * (rows + (rows - 1) * GY))
		local k = math.min(MAX_K, wk, hk)
		local score = k * (whole and 1.06 or 1)
		if not best or score > best.score + 1e-6 then
			best = { cols = cols, rows = rows, k = k, score = score, per = groups > 1 and per or nil }
		end
	end
	return best
end

-- Where the i-th card of n goes in the grid g (points of the stage), and its row (1: the top one). The last row
-- in the middle; a gap between two boosters on a row that holds whole ones.
local function Slot(g, i, n)
	local cols, per = g.cols, g.per
	local row = math.floor((i - 1) / cols)
	local col = CuratorOctoFull.Mod((i - 1) , cols)
	local inRow = math.min(cols, n - row * cols)
	local cw, ch = g.cw, g.ch
	local gx, gy, gg = cw * GX, ch * GY, cw * GROUP
	local width = inRow * cw + (inRow - 1) * gx + (per and math.floor((inRow - 1) / per) * gg or 0)
	local x = -width / 2 + cw / 2 + col * (cw + gx) + (per and math.floor(col / per) * gg or 0)
	local height = g.rows * ch + (g.rows - 1) * gy
	local y = g.cy + height / 2 - ch / 2 - row * (ch + gy)
	return g.cx + x, y, row + 1
end

-- The grid of the batch for the cards it will have (those drawn, and those of the packs not opened yet), and
-- each card in its place (animate: they move there; else at once).
function B:BatchLayout(animate)
	local b = self.batch
	if not b then
		return
	end
	local x0, x1, y0, y1 = self:BatchArea()
	local cw, ch = unpack(ns.CARD_SIZES.small)
	local n = math.max(CuratorOctoFull.Length(b.cards), b.total)
	local g = Fit(n, b.per, x1 - x0, y1 - y0, cw, ch)
	g.cx, g.cy = (x0 + x1) / 2, (y0 + y1) / 2
	g.cw, g.ch = cw * g.k, ch * g.k
	g.n = n
	local k0 = b.g and b.g.k
	b.g = g
	-- (its words too small to be read: its name alone, larger, B:BatchName)
	local tiny = g.k < TINY_K
	for i, c in ipairs(b.cards) do
		local x, y, row = Slot(g, i, n)
		-- (only those whose place changed move)
		local moved = c.slotX == nil or math.abs(c.slotX - x) > 0.5 or math.abs(c.slotY - y) > 0.5 or k0 ~= g.k
		c.slotX, c.slotY, c.row = x, y, row
		if c.tiny ~= tiny then
			c.tiny = tiny
			if c.revealed then
				c:SetFaceDetailsShown(true)
			end
		end
		if c.free and (moved or not animate) then
			self:BatchPlace(c, animate)
		end
		if c.revealed then
			self:BatchName(c)
		end
	end
end

-- A name on two lines (in the font of fs): cut at a space, or after a hyphen, where its longer line is the
-- shortest; that line's width. (nil: nowhere to cut it.)
local function Lines(fs, text)
	local best, bestW
	for i in CuratorOctoFull.Gmatch(text, "()[ %-]") do
		local a = string.sub(text, i, i) == "-" and string.sub(text, 1, i) or string.sub(text, 1, i - 1)
		local z = string.sub(text, i + 1)
		if a ~= "" and z ~= "" then
			fs:SetText(a)
			local wa = ns.TextWidth(fs)
			fs:SetText(z)
			local w = math.max(wa, ns.TextWidth(fs))
			if not bestW or w < bestW then
				best, bestW = a .. "\n" .. z, w
			end
		end
	end
	return best, bestW
end

-- The name of a card too small for its words, alone in the middle of its parchment: as large as the small words of
-- the scene, on two lines at most (shown once it is turned over).
function B:BatchName(c)
	local b = self.batch
	local t = c.oaName
	if not (b and c.tiny and c.revealed and c.pick and not c.flipping) then
		if t then
			t:Hide()
		end
		return
	end
	if not t then
		t = c.over:CreateFontString(nil, "OVERLAY")
		t:SetJustifyH("CENTER")
		t:SetJustifyV("MIDDLE")
		CuratorOctoFull.SetWordWrap(t, true)
		if t.SetMaxLines then
			pcall(t.SetMaxLines, t, 2)
		end
		c.oaName = t
	end
	local k = math.max(0.2, b.g.k)
	local maxW = c.W * 0.8
	t:ClearAllPoints()
	t:SetPoint("CENTER", c, "BOTTOM", 0, c.H * 0.205)
	t:SetWidth(maxW + 4 / k)
	t:SetTextColor(0.27, 0.17, 0.08)
	t:Show()
	local name = C:Name(c.pick.card)
	-- (on one line, else on two, smaller down to NAME_MIN points; still too long, the client cuts it: the
	-- tooltip has it whole)
	for pt = NAME_PT, NAME_MIN, -0.5 do
		ns.SetFont(t, pt / k)
		t:SetText(name)
		if ns.TextWidth(t) <= maxW then
			return
		end
		local two, w = Lines(t, name)
		if two and w <= maxW then
			t:SetText(two)
			return
		end
	end
	t:SetText((Lines(t, name)) or name)
end

-- A card that has landed, to its place in the grid (and its scale).
function B:BatchPlace(c, animate)
	local b = self.batch
	local grid = self.frame.grid
	local k1, x1, y1 = b.g.k, c.slotX, c.slotY
	if c.moveTw then
		ns.CancelTween(c.moveTw)
		c.moveTw = nil
	end
	if not animate then
		c:SetScale(k1)
		c:ClearAllPoints()
		c:SetPoint("CENTER", grid, "CENTER", x1 / k1, y1 / k1)
		c.atX, c.atY = x1, y1
		return
	end
	local k0, x0, y0 = c:GetScale(), c.atX or x1, c.atY or y1
	c.moveTw = ns.Tween(0.32, function(e)
		local k = k0 + (k1 - k0) * e
		local x, y = x0 + (x1 - x0) * e, y0 + (y1 - y0) * e
		c:SetScale(k)
		c:ClearAllPoints()
		c:SetPoint("CENTER", grid, "CENTER", x / k, y / k)
		c.atX, c.atY = x, y
	end, function()
		c.moveTw = nil
	end, Ease.outCubic, self)
end

-- The scene changed its size (the small window, the full screen): the grid, the packs, the name fit it again.
function B:BatchFit()
	local b = self.batch
	if not b then
		return
	end
	self:BatchLayout(false)
	self:BatchRow(false)
	self:BatchHead(0, true)
	self:BatchEndPlace()
	self:BatchButtons()
	-- (Stop beside the count of the boosters, full screen: under it, it would be over the grid)
	local s = self.frame
	if not self:Small() then
		s.stop:ClearAllPoints()
		s.stop:SetPoint("RIGHT", s.counter, "LEFT", -16, 0)
	end
end

-------------------------------------------------------------------------------
-- The frames of the batch (made once): the grid and its cards, the row of the packs, the card under the mouse
-------------------------------------------------------------------------------
function B:BatchBuild()
	local s = self.frame
	if s.grid then
		return
	end
	local st = s.stage
	local lvl = st:GetFrameLevel()
	-- (the cards of the grid over what shines behind them; the packs over the cards that fly out of them; the card
	-- under the mouse over them all, under the sparks)
	-- (the best cards a little over the others: their light spills over them)
	local grid = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(grid, 2, 2)
	grid:SetPoint("CENTER")
	grid:SetFrameLevel(lvl + 1)
	s.grid = grid
	local row = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(row, 2, 2)
	row:SetPoint("CENTER")
	row:SetFrameLevel(lvl + 22)
	s.packRow = row
	local top = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(top, 2, 2)
	top:SetPoint("CENTER")
	top:SetFrameLevel(lvl + 28)
	s.zoomLayer = top
	self.gridCards, self.batchPacks = {}, {}
	-- (the place a little darker behind so many cards: they stand out from it)
	local dim = s:CreateTexture(nil, "BACKGROUND", nil, 0)
	dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(dim, 0, 0, 0, 1)
	dim:SetAlpha(0)
	s.batchDim = dim
	-- the button of the ten next ones (where the button of the next booster is)
	local nx = ns.Button(s, "", 260, 26)
	CuratorOctoFull.SetScript(nx, "OnClick", function()
		ns.Play(ns.SND.click)
		B:BatchAgain()
	end)
	nx:Hide()
	s.batchNext = nx
end

-- The i-th card of the grid (made the first time).
function B:BatchCard(i)
	local c = self.gridCards[i]
	if c then
		return c
	end
	c = ns.NewCard(self.frame.grid, "small")
	c:Hide()
	c.gridI = i
	c.shadow:SetAlpha(0.5)
	CuratorOctoFull.SetScript(c, "OnClick", function(card)
		B:GridClick(card)
	end)
	CuratorOctoFull.SetScript(c, "OnEnter", function(card)
		B:GridHover(card, true)
	end)
	CuratorOctoFull.SetScript(c, "OnLeave", function(card)
		B:GridHover(card, false)
	end)
	self.gridCards[i] = c
	return c
end

-- A pack of the row: as the pack of the scene, its light cut to its shape (made the first time).
function B:BatchPack(i)
	local p = self.batchPacks[i]
	if p then
		return p
	end
	p = CreateFrame("Frame", nil, self.frame.packRow)
	CuratorOctoFull.SetSize(p, PACK_W, PACK_H)
	p.glow = Tex(p, "BACKGROUND", 0, "Glow", "ADD")
	p.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(p.glow, PACK_W * 2.5, PACK_H * 1.7)
	p.bottom = p:CreateTexture(nil, "ARTWORK")
	p.top = p:CreateTexture(nil, "ARTWORK", nil, 1)
	local sh = CreateFrame("Frame", nil, p)
	sh:SetAllPoints()
	sh.mask = CuratorOctoFull.CreateMaskTexture(sh)
	sh.mask:SetAllPoints(p)
	sh.cracks = {}
	for k = 1, 3 do
		local t = Tex(sh, "OVERLAY", 1 + k, "PackCracks" .. k, "ADD")
		t:SetAllPoints(p)
		CuratorOctoFull.AddMaskTexture(t, sh.mask)
		sh.cracks[k] = t
	end
	sh.wash = sh:CreateTexture(nil, "OVERLAY", nil, 6)
	sh.wash:SetAllPoints(p)
	CuratorOctoFull.ColorTexture(sh.wash, 1, 1, 1, 1)
	sh.wash:SetBlendMode("ADD")
	sh.wash:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(sh.wash, sh.mask)
	p.shine = sh
	p:Hide()
	self.batchPacks[i] = p
	return p
end

-- A pack of the row as it was made: whole, dark, of the album.
local function PaintPack(p, series)
	local pack = series.pack or "PackElwynn"
	p.bottom:SetTexture(MEDIA .. pack .. "Bottom")
	p.top:SetTexture(MEDIA .. pack .. "Top")
	p.shine.mask:SetTexture(MEDIA .. pack .. "Bottom", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	p.bottom:ClearAllPoints()
	p.bottom:SetAllPoints()
	p.bottom:SetAlpha(1)
	p.top:ClearAllPoints()
	p.top:SetPoint("TOPLEFT")
	p.top:SetPoint("TOPRIGHT")
	p.top:SetHeight(TOP_H)
	p.top:SetAlpha(1)
	local g = series.glow or WARM
	p.glow:SetVertexColor(g[1], g[2], g[3])
	p.glow:SetAlpha(0.3)
	p.glow.tw = nil
	for _, t in ipairs(p.shine.cracks) do
		t:SetAlpha(0)
	end
	p.shine.wash:SetAlpha(0)
	p:SetAlpha(1)
end

-- The row of the packs: k of them under the grid, as large as the scene lets them (animate: they come down).
function B:BatchRow(animate)
	local b = self.batch
	local x0, x1, _, _, _, hgt = self:BatchArea()
	local rowY = -hgt / 2 + ROW_Y
	local n = CuratorOctoFull.Length(b.packs)
	local k = math.min(PACK_K, (x1 - x0) / (n * PACK_W * (1 + ROW_GAP)))
	local w = PACK_W * k
	local total = n * w + (n - 1) * w * ROW_GAP
	b.rowK = k
	for i, pk in ipairs(b.packs) do
		pk.x, pk.y, pk.k = -total / 2 + w / 2 + (i - 1) * w * (1 + ROW_GAP), rowY, k
		pk.mouth = rowY + (PACK_H / 2 - 30) * k
		local p = pk.frame
		p:SetScale(k)
		if not animate then
			p:ClearAllPoints()
			p:SetPoint("CENTER", self.frame.stage, "CENTER", pk.x / k, pk.y / k)
		end
	end
end

-- The name of the album, higher and smaller over the grid (after delay: the scene may still be bringing it down;
-- now: at once).
function B:BatchHead(delay, now)
	local s = self.frame
	local h = s.head
	local hgt = s:GetHeight()
	if not hgt or hgt <= 0 then
		hgt = 768
	end
	local y1 = hgt / 2 - HEAD_PAD
	if h.tw then
		ns.CancelTween(h.tw)
		h.tw = nil
	end
	if now then
		h:SetScale(HEAD_K)
		h:ClearAllPoints()
		h:SetPoint("CENTER", s, "CENTER", 0, y1 / HEAD_K)
		h:SetAlpha(1)
		return
	end
	local k0, y0
	ns.Tween(0.4, function(e)
		if not k0 then
			k0 = h:GetScale() or 1
			local _, _, _, _, oy = h:GetPoint(1)
			y0 = (oy or 300 / k0) * k0
		end
		local k = k0 + (HEAD_K - k0) * e
		h:SetScale(k)
		h:ClearAllPoints()
		h:SetPoint("CENTER", s, "CENTER", 0, (y0 + (y1 - y0) * e) / k)
	end, nil, Ease.outCubic, self, delay)
end

-------------------------------------------------------------------------------
-- Opening them
-------------------------------------------------------------------------------
-- Open all: the boosters of the album, ten at most (headDelay: the scene is still bringing its name down).
function B:Batch(headDelay)
	if not self:CanOpenAll() then
		return
	end
	if self.state == "landing" then
		self:PackLands()
	end
	if self.state ~= "pack" then
		return
	end
	self:BatchBuild()
	local s, p = self.frame, self.frame.pack
	local series = self.series
	local n = math.min(MAX, ns.Packs(series))
	self.autoAll = nil
	-- (the states of the cards being drawn and turned over: the toasts, the achievements, the save wait for the end)
	self.state = "dealing"
	s.all:Hide()
	s.omen:Hide()
	s.revealAll:Hide()
	s.hint:SetText("")
	-- (the experience before them: its bar fills from there at the end; a level gained meanwhile shows then)
	self.xp0 = ns.Level and ns.Level:XP() or nil
	-- (a dungeon: what watches from the dark does not come back once the packs break, B:BatchBurst)
	if self.lair then
		self.snapped = true
	end
	local b = {
		series = series, n = n, opened = 0, picks = {}, packs = {}, cards = {}, landed = 0, phase = "packs",
		per = (series.dungeon and C.DUNGEON.size) or (series.event and C.EVENT.size) or C.ODDS.cards,
		-- (the creatures of the best ones only: a dungeon has nothing under rare)
		floor = series.dungeon and 4 or 3, glowing = {}, hidden = {}, flipSnd = 0, rareSnd = 0,
	}
	b.total = n * b.per
	self.batch = b
	-- (the cards drawn, all of them: the guild hears about the best ones if the scene closes before they are seen)
	self.picks = b.picks
	for i = 1, n do
		local f = self:BatchPack(i)
		PaintPack(f, series)
		b.packs[i] = { frame = f }
	end
	self:BatchLayout(false)
	self:BatchRow(false)
	self:BatchHead(headDelay or 0)
	self:BatchEndPlace()
	s.subtitle:SetText(string.format(L["Boosters opened: %d"], 0))
	-- Stop: beside the count of the boosters (under it, it would be over the grid)
	if not self:Small() then
		s.stop:ClearAllPoints()
		s.stop:SetPoint("RIGHT", s.counter, "LEFT", -16, 0)
	end
	FadeIn(s.stop, 0.25, self)
	GlowTo(s.batchDim, 0.3, 0.6, self)
	-- the pack of the scene goes into the row as the packs come down in it
	p.flying = true
	local dy0, sc0 = p.dy or 0, p.sc or 1
	ns.Tween(0.3, function(e)
		p.sc = sc0 + (b.rowK - sc0) * e
		p.dy = dy0 + (b.packs[1].y - U.PACK_Y - dy0) * e
		p:SetAlpha(1 - e)
	end, function()
		p:Hide()
		p.flying = false
	end, Ease.inQuad, self)
	ns.Play(ns.SND.whoosh)
	for i, pk in ipairs(b.packs) do
		local i, pk = i, pk; local f = pk.frame
		local k = pk.k
		f:SetAlpha(0)
		f:Show()
		local from = pk.y + 420
		ns.Tween(DROP, function(e, raw)
			f:ClearAllPoints()
			f:SetPoint("CENTER", s.stage, "CENTER", pk.x / k, (from + (pk.y - from) * e) / k)
			f:SetAlpha(math.min(1, raw * 4))
		end, function()
			-- it lands: a little squash, a puff of dust; it waits its turn, floating a little (B:BatchTick)
			pk.landed = true
			self.puffs:Burst(pk.x, pk.y - PACK_H * k / 2 + 6, U.DUST, 1, 50, 0.6, 50, 0.2, 1.6)
			if i == 1 or i == n then
				ns.Play(ns.SND.packDrop)
			end
			ns.Tween(0.3, function(_, raw)
				local q = math.cos(raw * math.pi * 2.5) * (1 - raw) ^ 1.6
				CuratorOctoFull.SetSize(f, PACK_W * (1 + 0.06 * q), PACK_H * (1 - 0.06 * q))
			end, function()
				CuratorOctoFull.SetSize(f, PACK_W, PACK_H)
			end, Ease.linear, self)
		end, Ease.inQuad, self, 0.12 + (i - 1) * DROP_EVERY)
	end
	self:Shake(0.18, 3)
	ns.Delay(0.12 + (n - 1) * DROP_EVERY + DROP + 0.12, function()
		if self.batch == b then
			self:BatchCharge(1)
		end
	end, self)
end

-- The i-th pack: its booster opened (its cards kept now), its light climbs to the colour of its best card, it
-- bursts; then the next one.
function B:BatchCharge(i)
	local b = self.batch
	local pk = b and b.packs[i]
	if not pk then
		return
	end
	-- (stopped; or the boosters given in a trade meanwhile: no more; 1.14.0: or its album changed by another addon this
	-- session, Guard.lua)
	if b.stopped or ns.Packs(b.series) <= 0 or (ns.Guard and not ns.Guard:Allow(b.series))
		or (ns.Reroll and ns.Reroll:NoOpening()) then
		return self:BatchPacksDone(i)
	end
	local s = self.frame
	local picks = C:Open(b.series, self.opts)
	b.opened = b.opened + 1
	pk.picks = picks
	pk.opened = true
	local best, finish, look, void = 1, nil, nil, nil
	for _, pick in ipairs(picks) do
		best = math.max(best, math.min(6, pick.card.rarity))
		if pick.finish == "holo" or (pick.finish == "shiny" and not finish) then
			finish = pick.finish
			look = C:FinishLook(pick.card, pick.finish)
		end
		if pick.finish == "corrupt" then
			void = true
		end
	end
	pk.best, pk.finish, pk.look, pk.void = best, finish, look, void
	-- a legendary, a mythic or a titanforged card inside: the guild watches it open (as one opened alone). (1.14.2, his
	-- word: "rare at least, and titanforged and thunderforged too") A rare card or better, or a forged one; in a wave, one
	-- of those below the rule of before only when its card is finer than all those this wave showed: the guild is never
	-- flooded (Comm.lua: G.Worth, G.Star)
	local G = ns.Guild
	if G.Worth(best, finish) then
		local star = G.Star(picks)
		local score = star and G.OpenScore(star.card.rarity, star.finish) or 0
		if G.OldRule(best, finish) or score > (b.toldScore or 0) then
			b.toldScore = math.max(b.toldScore or 0, score)
			G:AnnounceOpen(b.series, best, finish, star and star.card, star and star.finish)
		end
	end
	-- its cards, in their places to come (the grid grows when a talent gave it one more)
	local first = CuratorOctoFull.Length(b.cards)
	for j, pick in ipairs(picks) do
		b.picks[CuratorOctoFull.Length(b.picks) + 1] = pick
		local c = self:BatchCard(first + j)
		b.cards[first + j] = c
		self:BatchDress(c, pick)
	end
	pk.cards = { unpack(b.cards, first + 1, first + CuratorOctoFull.Length(picks)) }
	b.total = CuratorOctoFull.Length(b.cards) + (b.n - i) * b.per
	self:BatchLayout(true)
	self:UpdateCounter()
	s.subtitle:SetText(string.format(L["Boosters opened: %d"], b.opened))
	-- its light climbs, it trembles
	local f = pk.frame
	local col = TELL[best]
	local dur = CHARGE[best]
	-- (a sound of its light from rare up: ten packs in a few seconds, the small ones quiet)
	if best >= 3 and ns.SND.tell[best] then
		ns.Play(ns.SND.tell[best])
	end
	f.glow:SetVertexColor(col[1], col[2], col[3])
	for _, t in ipairs(f.shine.cracks) do
		t:SetVertexColor(col[1], col[2], col[3])
	end
	local steps = math.min(3, math.max(1, best - 1))
	local tremble = (best >= 4 and 4 + 2 * (best - 4)) or (1.4 + 0.5 * best)
	local k = pk.k
	ns.Tween(dur, function(_, raw)
		local a = tremble * raw * raw
		f:ClearAllPoints()
		f:SetPoint("CENTER", s.stage, "CENTER", (pk.x + (math.random() - 0.5) * 2 * a) / k, (pk.y + (math.random() - 0.5) * 2 * a) / k)
		f.glow:SetAlpha(0.35 + 0.65 * raw)
		for m, t in ipairs(f.shine.cracks) do
			if m <= steps then
				t:SetAlpha(math.min(1, raw * (1 + steps - m)))
			end
		end
		f.shine.wash:SetAlpha(0.25 * raw ^ 3)
	end, nil, Ease.linear, self)
	self:Ring(pk.x, pk.y, col, 260 * k * 2, 0.4, 0.5, 0, "Shock")
	if best >= 4 then
		self:EdgeGlow(col, 0.16 + 0.08 * (best - 4), dur + 0.2)
	end
	if best >= 5 then
		-- gold and crimson: the place goes dark, the ground rumbles
		self:DarkTo(best == 5 and 0.36 or 0.6, dur)
		s.halo:SetVertexColor(col[1], col[2], col[3])
		GlowTo(s.halo, 0.36, dur, self)
		ns.Play(ns.SND.rumble)
	end
	ns.Delay(dur, function()
		if self.batch == b then
			self:BatchBurst(i)
		end
	end, self)
	ns.Delay(dur + AFTER[best], function()
		if self.batch == b then
			if i < b.n then
				self:BatchCharge(i + 1)
			else
				self:BatchPacksDone(i + 1)
			end
		end
	end, self)
end

-- A card of the grid for a card drawn: face down, its back of its album, the light of the best ones; their
-- creature (the others: none, they are many).
function B:BatchDress(c, pick)
	local b = self.batch
	pick.look = C:FinishLook(pick.card, pick.finish)
	c.pick = pick
	c.free, c.revealed, c.busy = false, false, false
	c.glowBase = 0
	c:SetAlpha(0)
	c:SetScale(1)
	c:ShowSide("back")
	local model = pick.card.rarity >= b.floor
	c.oaModel = model
	-- (still: a hundred creatures moving would cost)
	c:Freeze(model and pick.card.rarity < 5)
	c:SetCard(model and pick.card or Lite(pick.card), { owned = true, finish = pick.finish, count = pick.count, new = false,
		corrupt = pick.corrupt, pattern = pick.pt, wear = pick.wear })
	self:BatchFace(c, not model and pick.card.display or nil)
	c:SetFrameLevel(self.frame.grid:GetFrameLevel() + (Special(pick) and 10 or 1))
	c.phase = math.random()
	c.glow:SetAlpha(0)
	c.glow.tw = nil
	c.hot:SetAlpha(0)
	c.back.glow:SetAlpha(0)
	c.back.core:SetAlpha(0)
	c.back.cracks:SetAlpha(0)
	c.badge:Hide()
	c.badge:SetScale(1)
	if c.oaRays then
		c.oaRays:SetAlpha(0)
	end
	if c.oaName then
		c.oaName:Hide()
	end
	local r = pick.card.rarity
	if r >= 4 then
		local col = ns.RARITY[r].glow
		for _, t in ipairs({ c.glow, c.back.glow, c.back.core, c.back.cracks }) do
			t:SetVertexColor(col[1], col[2], col[3])
		end
	end
	c:Hide()
end

-- The portrait of its creature in the window of a card without its creature (display: nil, none): a picture
-- the game draws once, where a creature would be drawn each frame. (A client without it: the photo of the place.)
function B:BatchFace(c, display)
	local f = c.oaFace
	if not display or not SetPortraitTextureFromCreatureDisplayID then
		if f then
			f:Hide()
		end
		return
	end
	if not f then
		local art = c.art
		f = art.pic:GetParent():CreateTexture(nil, "ARTWORK", nil, 1)
		-- (the head of the creature in the middle of the window, as wide as it)
		local side = c.W * (1 - 48 / 366)
		CuratorOctoFull.SetSize(f, side, side)
		f:SetPoint("CENTER", art, "CENTER", 0, 0)
		c.oaFace = f
	end
	if pcall(SetPortraitTextureFromCreatureDisplayID, f, display) then
		f:Show()
	else
		f:Hide()
	end
end

-- The pack bursts in the light of its best card; its cards fly out of it to their places.
function B:BatchBurst(i)
	local b = self.batch
	local pk = b.packs[i]
	local s, f = self.frame, pk.frame
	local best = pk.best or 1
	local col = TELL[best]
	local hot = Mix(col, WHITE, 0.45)
	local k = pk.k
	local x, mouth = pk.x, pk.mouth
	local lvl = (best == 1 and -1.4) or (best == 2 and -0.8) or (best - 3)
	ns.Play(ns.SND.packTear)
	ns.Play(ns.SND.burst[best] or ns.SND.burst[3])
	if i == 1 and self.lair and self.CloseEyes then
		self:CloseEyes()
	end
	-- white-hot for an instant; its light dies as it opens
	f:ClearAllPoints()
	f:SetPoint("CENTER", s.stage, "CENTER", pk.x / k, pk.y / k)
	f.shine.wash:SetAlpha(0.95)
	ns.Tween(0.25, function(e)
		f.shine.wash:SetAlpha(0.95 * (1 - e))
		for _, t in ipairs(f.shine.cracks) do
			t:SetAlpha(math.min(t:GetAlpha(), 1 - e))
		end
	end, nil, Ease.outQuad, self)
	-- its top tears off and flies away, turning over; the rest of it drops away
	local side = (CuratorOctoFull.Mod(i , 2) == 0) and 1 or -1
	ns.Tween(0.5, function(e, raw)
		f.top:ClearAllPoints()
		local h = TOP_H * math.max(0.05, math.abs(math.cos(raw * math.pi * 1.5)))
		CuratorOctoFull.SetSize(f.top, PACK_W * (1 - 0.15 * raw), h)
		f.top:SetPoint("CENTER", f, "TOP", side * 90 * e, -TOP_H / 2 + 170 * e - 120 * raw * raw)
		f.top:SetAlpha(1 - raw * raw)
	end, nil, Ease.outCubic, self)
	ns.Tween(0.42, function(e)
		f.bottom:ClearAllPoints()
		f.bottom:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -150 * e)
		f.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -150 * e)
		f.bottom:SetAlpha(1 - e)
		f.glow:SetAlpha(0.9 * (1 - e))
	end, function()
		f:Hide()
	end, Ease.inQuad, self, 0.08)
	-- a pillar of light out of it, the shock, the sparks
	b.beam = CuratorOctoFull.Mod((b.beam or 0) , 3) + 1
	self:Beam(b.beam, x, mouth - 10, hot, math.max(60, (150 + 34 * lvl) * k * 2.2), 900, 0.75 + 0.1 * lvl, 0.85)
	self:Ring(x, mouth, col, math.max(160, (440 + 110 * lvl) * k * 1.7), 0.55, 0.65, 0, "Shock")
	self:Ring(x, mouth, WARM, math.max(120, (300 + 70 * lvl) * k * 1.7), 0.45, 0.4, 0.05)
	self.streaks:Burst(x, mouth, hot, math.max(6, math.floor(14 + 6 * lvl)), 300 + 40 * lvl, 0.55, 30, 0.75)
	self.particles:Burst(x, mouth, col, math.max(6, math.floor(14 + 6 * lvl)), 220, 0.75, 18, 0.6)
	if best >= 3 then
		self.stars:Burst(x, mouth, Mix(col, WHITE, 0.6), 2 + 2 * (best - 3), 200, 0.9, 20, 0.6)
	end
	if best >= 4 then
		self:Flash(hot, 0.12 + 0.08 * (best - 4), 0.4 + 0.1 * (best - 4))
		self:EdgeGlow(col, 0.3 + 0.1 * (best - 4), 0.8 + 0.2 * (best - 4))
		self:Ring(x, mouth, col, 900 + 160 * (best - 4), 0.85, 0.4, 0.1, "Shock")
		self:Shake(0.22 + 0.08 * (best - 4), 4 + 2 * (best - 4))
		self:Punch(0.02 + 0.01 * (best - 4), 0.35)
	end
	if best >= 5 then
		b.beam = CuratorOctoFull.Mod(b.beam , 3) + 1
		self:Beam(b.beam, x, mouth - 10, col, 300, 1100, 1.1, 0.55)
		self:DarkTo(0, 0.9, 0.2)
		GlowTo(s.halo, 0.22, 1.1, self)
		self.stars:Burst(x, mouth, hot, 8, 280, 1.1, 22, 0.6)
	end
	if pk.finish then
		for m, rc in ipairs(WAVES[pk.look] or RAINBOW) do
			local m, rc = m, rc; self:Ring(x, mouth, rc, 220 + 40 * m, 0.7, 0.4, 0.05 * m)
			ns.Delay(0.05 * m, function()
				self.stars:Burst(x, mouth, rc, 2, 220, 1, 20, 0.6)
			end, self)
		end
	elseif pk.void then
		for m, rc in ipairs({ U.VOID_VIOLET, U.VOID_BLUE, U.VOID_VIOLET }) do
			self:Ring(x, mouth, rc, 240 + 50 * m, 0.8, 0.4, 0.07 * m)
		end
		self.puffs:Burst(x, mouth, U.VOID_SMOKE, 3, 110, 1.3, 90, 0.6, 2)
	end
	self:BatchDeal(pk)
end

-- Its cards fly out of it, turning over in the air, to their places in the grid (which can still change: they
-- go where their place is when they come).
function B:BatchDeal(pk)
	local b = self.batch
	local grid = self.frame.grid
	-- (the sound of the cards flying out: every other pack, they follow each other closely)
	b.whoosh = not b.whoosh
	if b.whoosh then
		ns.Play(ns.SND.whoosh)
	end
	local x0, y0 = pk.x, pk.mouth
	local left = CuratorOctoFull.Length(pk.cards)
	for j, c in ipairs(pk.cards) do
		local j, c = j, c; local tx, ty = c.slotX, c.slotY
		local ax = x0 + (tx - x0) * 0.25 + (math.random() - 0.5) * 40
		local ay = math.max(y0, ty) + 40 + math.random() * 50
		c:ClearAllPoints()
		c:SetPoint("CENTER", grid, "CENTER", x0 / 0.2, y0 / 0.2)
		c:SetScale(0.2)
		c:SetAlpha(0)
		c:Show()
		local nextSpark = 0
		local r = c.pick.card.rarity
		local trail = r >= 4 and ns.RARITY[r].glow or WARM
		c.flyTw = ns.Tween(FLY, function(e, raw)
			local kk = b.g.k
			local u = 1 - e
			local x = u * u * x0 + 2 * u * e * ax + e * e * c.slotX
			local y = u * u * y0 + 2 * u * e * ay + e * e * c.slotY
			local k = kk * (0.3 + 0.7 * e)
			c:SetScale(k)
			c:SetFlipSize(math.max(1, c.W * math.abs(math.cos(raw * math.pi * 2))), c.H)
			c:ClearAllPoints()
			c:SetPoint("CENTER", grid, "CENTER", x / k, y / k)
			c.atX, c.atY = x, y
			c:SetAlpha(math.min(1, raw * 5))
			if r >= 4 and raw >= nextSpark then
				nextSpark = raw + 0.1
				self.particles:Burst(x, y, trail, 1, 30, 0.45, 18, 1, 0.3)
			end
		end, function()
			c.flyTw = nil
			left = left - 1
			self:BatchLand(c, left == 0)
		end, Ease.outCubic, self, 0.04 + (j - 1) * FLY_EVERY)
	end
end

-- A card lands in its place (the last of its pack: the sound of them); the best ones in their light.
function B:BatchLand(c, last)
	local b = self.batch
	c:SetFlipSize(c.W, c.H)
	c.free = true
	self:BatchPlace(c, false)
	local k = b.g.k
	local x, y = c.slotX, c.slotY
	-- (it comes down hard: a little larger for an instant; moved meanwhile, the grid changing, it goes)
	local grid = self.frame.grid
	c.moveTw = ns.Tween(0.14, function(e)
		local q = b.g.k * (1.1 - 0.1 * e)
		c:SetScale(q)
		c:ClearAllPoints()
		c:SetPoint("CENTER", grid, "CENTER", c.slotX / q, c.slotY / q)
	end, function()
		c.moveTw = nil
		self:BatchPlace(c, false)
	end, Ease.outQuad, self)
	if last then
		ns.Play(ns.SND.cardLand)
	end
	local r = c.pick.card.rarity
	if r >= 4 then
		local col = ns.RARITY[r].glow
		c.back.glow:SetAlpha(1)
		c.glow:SetAlpha(0.8)
		GlowTo(c.back.glow, AURA_GLOW[math.min(6, r)] * 1.6, 0.6, self)
		GlowTo(c.glow, AURA_GLOW[math.min(6, r)], 0.6, self)
		self:Ring(x, y, col, math.max(120, 300 * k * 1.4), 0.5, 0.45, 0, "Shock")
		self.particles:Burst(x, y, col, 4 + 2 * (r - 4), 110, 0.6, 16)
		b.glowing[CuratorOctoFull.Length(b.glowing) + 1] = c
		-- the rays that turn behind it while it waits face down (its own: over the cards around it, as its light)
		if not c.oaRays then
			c.oaRays = Tex(c, "BACKGROUND", -3, "Rays", "ADD")
			c.oaRays:SetPoint("CENTER")
			CuratorOctoFull.SetSize(c.oaRays, c.W * 2.6, c.W * 2.6)
		end
		c.oaRays:SetVertexColor(col[1], col[2], col[3])
	end
	if c:IsMouseOver() then
		self:GridHover(c, true)
	end
	b.landed = b.landed + 1
	if b.packsDone and b.landed >= CuratorOctoFull.Length(b.cards) then
		self:BatchCardsDown()
	end
end

-- No more packs to open (the last one burst, or Stop, or none left): the packs not opened go back to the album,
-- the grid fits the cards drawn.
function B:BatchPacksDone(i)
	local b = self.batch
	if not b or b.packsDone then
		return
	end
	b.packsDone = true
	for m = i, CuratorOctoFull.Length(b.packs) do
		local m = m; local pk = b.packs[m]
		if not pk.opened then
			local f = pk.frame
			local y0 = pk.y
			ns.Tween(0.4, function(e)
				f:ClearAllPoints()
				f:SetPoint("CENTER", self.frame.stage, "CENTER", pk.x / pk.k, (y0 + 260 * e) / pk.k)
				f:SetAlpha(1 - e)
			end, function()
				f:Hide()
			end, Ease.inQuad, self, 0.04 * (m - i))
		end
	end
	if b.total ~= CuratorOctoFull.Length(b.cards) then
		b.total = CuratorOctoFull.Length(b.cards)
		self:BatchLayout(true)
	end
	self:UpdateCounter()
	if b.landed >= CuratorOctoFull.Length(b.cards) then
		self:BatchCardsDown()
	end
end

-- Every card in its place: a breath, then they turn over (at once, when stopped).
function B:BatchCardsDown()
	local b = self.batch
	if b.down then
		return
	end
	b.down = true
	ns.Delay(b.stopped and 0.1 or 0.35, function()
		if self.batch ~= b then
			return
		end
		if b.stopped then
			return self:BatchQuick()
		end
		self:BatchWave()
	end, self)
end

-------------------------------------------------------------------------------
-- Turning them over
-------------------------------------------------------------------------------
-- The wave: the cards turn over across the grid from its top left corner (the best ones wait for it to pass).
function B:BatchWave()
	local b = self.batch
	b.phase = "wave"
	self.state = "cards"
	local g = b.g
	local span = math.max(1, (g.cols - 1) + (g.rows - 1) * 1.4)
	local queue, special = {}, {}
	for i, c in ipairs(b.cards) do
		if Special(c.pick) then
			special[CuratorOctoFull.Length(special) + 1] = c
		else
			local col = CuratorOctoFull.Mod((i - 1) , g.cols)
			queue[CuratorOctoFull.Length(queue) + 1] = { c = c, due = (col + (c.row - 1) * 1.4) / span * WAVE }
		end
	end
	table.sort(queue, function(a, b2)
		if a.due ~= b2.due then
			return a.due < b2.due
		end
		return a.c.gridI < b2.c.gridI
	end)
	table.sort(special, function(a, b2)
		local ra, rb = Rank(a.pick), Rank(b2.pick)
		if ra ~= rb then
			return ra < rb
		end
		return a.gridI < b2.gridI
	end)
	b.queue, b.special, b.waveI, b.waveT = queue, special, 1, 0
	b.waveEnd = (CuratorOctoFull.Length(queue) > 0 and WAVE or 0) + 0.45
	ns.Play(ns.SND.whoosh)
end

-- (every frame) The wave goes on; it waits while a card is looked at closely.
function B:BatchWaveTick(dt)
	local b = self.batch
	if self.inspecting then
		return
	end
	b.waveT = b.waveT + dt
	local q = b.queue
	while b.waveI <= CuratorOctoFull.Length(q) and q[b.waveI].due <= b.waveT do
		self:BatchFlip(q[b.waveI].c)
		b.waveI = b.waveI + 1
	end
	if b.waveI > CuratorOctoFull.Length(q) and b.waveT >= b.waveEnd then
		b.phase = "best"
		self:BatchSpecial(1)
	end
end

-- A card turned over in the wave (quick: all at once, without its sound).
function B:BatchFlip(c, quick)
	if c.revealed or c.busy or not c.pick then
		return
	end
	local b = self.batch
	c.busy, c.flipping = true, true
	if c.oaName then
		c.oaName:Hide()
	end
	local r = c.pick.card.rarity
	c:Flip(quick and 0.2 or 0.26, function()
		c.hot:SetVertexColor(1, 1, 1)
		c.hot:SetAlpha(r >= 3 and 0.8 or 0.5)
		GlowTo(c.hot, 0, 0.3, self)
		local now = GetTime()
		if not quick and now - b.flipSnd >= FLIP_EVERY then
			b.flipSnd = now
			ns.Play(ns.SND.cardFlip)
		end
	end, function()
		c.revealed, c.busy, c.flipping = true, false, false
		self:BatchRevealed(c, quick)
	end, self)
end

-- A card turned over: the guild hears about the best ones, its light by its rarity, the mark of a new one.
-- quiet: no light of its own (turned over all at once); cine: out of its entrance.
function B:BatchRevealed(c, quiet, cine)
	local b = self.batch
	local pick = c.pick
	local r = pick.card.rarity
	local col = ns.RARITY[r].glow
	local x, y = c.slotX, c.slotY
	local k = b.g.k
	if (r >= 4 or pick.finish) and not pick.told then
		pick.told = true
		ns.Guild:Announce(pick.card, pick.finish)
	end
	c.back.glow:SetAlpha(0)
	c.back.core:SetAlpha(0)
	c.back.cracks:SetAlpha(0)
	if c.oaRays then
		GlowTo(c.oaRays, 0, 0.4, self)
	end
	if r >= 2 then
		c.glow:SetVertexColor(col[1], col[2], col[3])
		c.glow:SetAlpha(0.9)
		c.glowBase = (r >= 5 and 0.5) or (r == 4 and 0.42) or (r == 3 and 0.3) or 0.14
		GlowTo(c.glow, c.glowBase, 0.8, self)
	else
		c.glowBase = 0
		GlowTo(c.glow, 0, 0.3, self)
	end
	if not quiet and not cine then
		if r == 2 then
			self.particles:Burst(x, y, col, 3, 70, 0.5, 12)
		elseif r == 3 then
			self:Ring(x, y, col, math.max(110, 280 * k * 1.4), 0.45, 0.5, 0, "Shock")
			self.particles:Burst(x, y, col, 7, 120, 0.7, 16)
			self.stars:Burst(x, y, Mix(col, WHITE, 0.5), 2, 90, 0.8, 14)
			local now = GetTime()
			if now - b.rareSnd >= RARE_EVERY then
				b.rareSnd = now
				ns.Play(ns.SND.reveal[3])
			end
		end
	end
	if pick.new then
		local bd = c.badge
		bd:SetScale(0.2)
		bd:Show()
		ns.Tween(0.4, function(e)
			bd:SetScale(0.2 + 0.8 * e)
		end, function()
			if not quiet then
				self.stars:Burst(x + c.W * k * 0.32, y + c.H * k * 0.43, { 1, 0.82, 0.4 }, 2, 50, 0.6, 12)
			end
		end, Ease.outBack, self, quiet and 0 or 0.15)
	end
	self:BatchName(c)
	if c:IsMouseOver() then
		self:GridHover(c, true)
	end
end

-- Where the banner of a card of the grid goes (as for a card of a booster: B:BannerY), and the rays and the
-- circle behind it: its place, its size on the screen.
local function Spot(c, b)
	local k = b.g.k
	-- (a card in the upper half: its banner under it)
	return { slotX = c.slotX, slotY = c.slotY, W = c.W * k, H = c.H * k, row = (c.slotY > (b.g.cy or 0)) and 2 or 1, lift = 0 }
end

-- The best ones, one after the other: they gather their light and turn over, with their sound; a legendary or
-- a mythic card makes its entrance (its card turned over under its last flash).
function B:BatchSpecial(k)
	local b = self.batch
	if not b or b.stopped then
		return
	end
	if self.inspecting or (ns.Cinematic and ns.Cinematic:IsPlaying()) then
		ns.Delay(0.25, function()
			if self.batch == b then
				self:BatchSpecial(k)
			end
		end, self)
		return
	end
	local c = b.special[k]
	if not c then
		return self:BatchFinish()
	end
	if c.revealed or c.busy then
		return self:BatchSpecial(k + 1)
	end
	local pick = c.pick
	local r = pick.card.rarity
	local col = ns.RARITY[r].glow
	local x, y = c.slotX, c.slotY
	local kk = b.g.k
	local spot = Spot(c, b)
	local own = self:Owner()
	b.own = own
	c.busy = true
	local function after(beat)
		ns.Delay(beat, function()
			if self.batch == b then
				self:BatchSpecial(k + 1)
			end
		end, self)
	end
	-- it gathers its light: it rises toward you, trembles, its light breaks through its back
	local wind = (r >= 6 and 1.2) or (r == 5 and 0.9) or (r == 4 and 0.32) or 0.2
	local k0 = kk
	ns.Tween(math.min(wind, 0.3), function(e)
		local q = k0 * (1 + 0.14 * e)
		c:SetScale(q)
		c:ClearAllPoints()
		c:SetPoint("CENTER", self.frame.grid, "CENTER", x / q, (y + 8 * e) / q)
	end, nil, Ease.outCubic, own)
	ns.Tween(wind, function(_, raw)
		c.glow:SetAlpha(math.max(c.glow:GetAlpha(), raw))
		c.back.glow:SetAlpha(math.max(c.back.glow:GetAlpha(), raw))
		c.back.core:SetAlpha(raw)
		c.back.cracks:SetAlpha(raw ^ 1.4)
	end, nil, Ease.linear, own)
	if r >= 4 then
		self.particles:Gather(x, y, col, 4 + 5 * (r - 3), 90 + 40 * (r - 3), math.max(0.25, wind * 0.8), 16)
	end
	if r >= 5 then
		self:DarkTo(DARK[r], wind)
		self:Circle(x, y, col, math.max(220, (420 + 80 * (r - 5)) * kk * 1.6), wind, 0.8 + 0.3 * (r - 5))
		self:CamTo(1.05 + 0.02 * (r - 5), x * 0.3, y * 0.3, wind + 0.1, Ease.inOutCubic)
		self:Loop("oaWind", ns.SND.charge, wind + 0.3)
		ns.Play(ns.SND.rumble)
		for m = 1, r - 3 do
			local m = m; ns.Delay(wind * (m / (r - 2)) ^ 0.8, function()
				self:Ring(x, y, col, math.max(160, (320 + 60 * m) * kk * 1.4), 0.45, 0.55, 0, "Shock")
				self.streaks:Burst(x, y, Mix(col, WHITE, 0.3), 5 + 2 * m, 200 + 40 * m, 0.45, 24, 0.8)
				ns.Play(ns.SND.tell[math.min(6, 2 + m + (r - 4))])
				self:EdgeGlow(col, 0.15 + 0.07 * m, 0.45)
				self:Shake(0.15, 2 + m)
			end, own)
		end
		if r == 6 then
			ns.Delay(wind * 0.5, function()
				self:Bolts(x, y, 300, { 1, 0.3, 0.35 })
			end, own)
		end
	elseif r == 4 then
		ns.Play(ns.SND.tell[4])
	end
	ns.Delay(wind, function()
		if self.batch ~= b or b.stopped then
			return
		end
		self:StopLoop("oaWind", 200)
		local cin = ns.Cinematic
		local art = pick.card.art
		if r >= 5 and cin and cin:Enabled() and not (art and art.fill) then
			-- (the entrance has its own music)
			if self.StopMusic then
				self:StopMusic(900)
			end
			if cin:Play(pick.card, { finish = pick.finish }, function()
				c:ShowSide("front")
				c:Freeze(false)
				self:BatchPlace(c, false)
				c.revealed, c.busy = true, false
				self:BatchRevealed(c, false, true)
				self:BigImpact(spot, r, col, x, y, true)
				self:BatchFinishFx(c, spot, true)
			end, function()
				after(0.6)
			end) then
				return
			end
		end
		local slow = r >= 5
		if slow then
			self:SetTime(0.5)
		end
		c.flipping = true
		if c.oaName then
			c.oaName:Hide()
		end
		c:Flip(r >= 5 and 0.44 or 0.32, function()
			if slow then
				self:SetTime(1)
			end
			if ns.Cinematic and ns.Cinematic.HideCard then
				ns.Cinematic:HideCard(c)
			end
			if self.HideWhileHeld then
				self:HideWhileHeld(c)
			end
			ns.Play(ns.SND.cardFlip)
			c.hot:SetVertexColor(1, 1, 1)
			c.hot:SetAlpha(0.9)
			GlowTo(c.hot, 0, 0.35, self)
		end, function()
			c.revealed, c.busy, c.flipping = true, false, false
			if r >= 5 then
				c:Freeze(false)
			end
			-- it settles back in its place
			local q0 = c:GetScale()
			ns.Tween(0.35, function(e)
				local q = q0 + (kk - q0) * e
				c:SetScale(q)
				c:ClearAllPoints()
				c:SetPoint("CENTER", self.frame.grid, "CENTER", x / q, (y + 8 * (1 - e)) / q)
			end, function()
				self:BatchPlace(c, false)
			end, Ease.outBack, self)
			self:BatchRevealed(c, true)
			ns.Play(ns.SND.reveal[r] or ns.SND.reveal[4])
			if ns.SND.impact[r] then
				ns.Play(ns.SND.impact[r])
			end
			if r >= 4 then
				self:BigImpact(spot, r, col, x, y, false)
			else
				self:Ring(x, y, col, math.max(120, 300 * kk * 1.4), 0.5, 0.55, 0, "Shock")
				self.particles:Burst(x, y, col, 10, 140, 0.8, 18)
			end
			local fin = self:BatchFinishFx(c, spot, false)
			after(((r >= 6 and 2.6) or (r == 5 and 2) or (r == 4 and 0.75) or 0.35) + (fin and 0.6 or 0))
		end, self)
	end, own)
end

-- A card with a finish turned over: its light (lightning, the light of a prism, the Void), its banner. True when
-- it has one.
function B:BatchFinishFx(c, spot, cine)
	local pick = c.pick
	local look = pick.look
	if not look then
		return false
	end
	local b = self.batch
	local x, y, r = c.slotX, c.slotY, pick.card.rarity
	local size = math.max(200, 420 * b.g.k * 1.5)
	if look == "thunder" then
		self:Bolts(x, y, size, { 0.55, 0.8, 1 })
		ns.Play(ns.SND.thunder)
		for m, rc in ipairs(WAVES.thunder) do
			self:Ring(x, y, rc, size * (0.6 + 0.12 * m), 0.6, 0.4, 0.05 * m)
		end
		self:FinishBanner(L["THUNDERFORGED!"], "Thunder", spot, x, r, cine, 1.6)
	elseif look == "titan" then
		ns.Play(ns.SND.titan)
		self:Spikes(x, y, { 1, 0.97, 0.92 }, size * 1.3, 0.6, 0.8)
		for m, rc in ipairs(WAVES.titan) do
			self:Ring(x, y, rc, size * (0.6 + 0.14 * m), 0.7, 0.45, 0.06 * m)
			self.motes:Rise(x - spot.W * 0.6, x + spot.W * 0.6, y - spot.H * 0.4, rc, 2, 220, 1.6, 12)
		end
		self:FinishBanner(L["TITANFORGED!"], "Prism", spot, x, r, cine, 1.9)
	elseif look == "corrupt" then
		ns.Play(ns.SND.corruptLoot)
		for m, rc in ipairs({ U.VOID_VIOLET, U.VOID_BLUE, U.VOID_VIOLET }) do
			self:Ring(x, y, rc, size * (0.6 + 0.15 * m), 0.8, 0.45, 0.07 * m)
		end
		self.puffs:Burst(x, y, U.VOID_SMOKE, 3, 90, 1.3, 80, 0.6, 2)
		self.motes:Rise(x - spot.W * 0.5, x + spot.W * 0.5, y - spot.H * 0.4, U.VOID_BLUE, 5, 200, 1.6, 12)
		self:FinishBanner(string.format(L["CORRUPTED! %d %%"], C.Gauge(pick.corrupt)), "Corrupt", spot, x, r, cine, 1.9)
	else
		return false
	end
	return true
end

-- Stop, or the end of the packs after it: every card left face down turns over at once.
function B:BatchQuick()
	local b = self.batch
	b.phase = "best"
	self.state = "cards"
	if b.own then
		ns.CancelOwner(b.own)
	end
	self:StopLoop("oaWind", 150)
	self:DarkTo(0, 0.3)
	self:CircleOut(0.3)
	self:CamTo(1, 0, 0, 0.4)
	ns.Play(ns.SND.whoosh)
	local any = false
	for i, c in ipairs(b.cards) do
		-- (one turning over already ends on its own)
		local i, c = i, c; if not c.revealed and not c.flipping then
			any = true
			-- (one gathering its light when stopped: turned over as the others)
			c.busy = false
			ns.Delay(0.004 * i, function()
				if self.batch == b then
					self:BatchFlip(c, true)
					if c.pick.card.rarity >= 5 then
						c:Freeze(false)
					end
				end
			end, self)
		end
	end
	ns.Delay(any and (0.004 * CuratorOctoFull.Length(b.cards) + 0.45) or 0.1, function()
		if self.batch == b then
			-- (back to its size in the grid: one may have risen as it gathered its light)
			for _, c in ipairs(b.cards) do
				if c.free then
					self:BatchPlace(c, false)
				end
			end
			self:BatchEnd()
		end
	end, self)
end

-- Every card turned over: a light runs across the grid, then the end.
function B:BatchFinish()
	local b = self.batch
	b.phase = "end"
	local g = b.g
	local span = math.max(1, (g.cols - 1) + (g.rows - 1))
	for i, c in ipairs(b.cards) do
		local i, c = i, c; local col = CuratorOctoFull.Mod((i - 1) , g.cols)
		ns.Delay(((col + c.row - 1) / span) * 0.5, function()
			if self.batch == b and c:IsShown() then
				c.hot:SetVertexColor(1, 0.95, 0.85)
				c.hot:SetAlpha(0.3)
				GlowTo(c.hot, 0, 0.4, self)
			end
		end, self)
	end
	ns.Play(ns.SND.tick)
	ns.Delay(0.6, function()
		if self.batch == b then
			self:BatchEnd()
		end
	end, self)
end

-- The end of the batch: what it gave (the album fills, the experience: its screen when a level was gained),
-- the buttons. The toasts, the achievements (an album complete: its screen) come now.
function B:BatchEnd()
	local b = self.batch
	if not b or b.ended then
		return
	end
	b.ended = true
	b.phase = "end"
	self.state = "done"
	local s = self.frame
	s.stop:Hide()
	s.hint:SetText("")
	local new = 0
	for _, p in ipairs(b.picks) do
		if p.new then
			new = new + 1
		end
	end
	local owned, total = C:Progress(b.series)
	s.subtitle:SetText(string.format(L["Boosters opened: %d"], b.opened))
	s.summary:SetText(string.format(L["New cards: %d"], new) .. "   ·   " .. string.format(L["%d / %d cards"], owned, total))
	FadeIn(s.summary, 0.3, self)
	self:UpdateCounter()
	if b.opened > 0 then
		self:FillBar(owned - new, owned, total, new)
		self:FillXP()
	else
		-- (nothing opened: no experience to show, a level gained elsewhere is not this scene's)
		self.xp0 = nil
	end
	self:BatchButtons(true)
end

-- The buttons of the end: the album, the ten next boosters (or the last ones; the last one alone, as any
-- booster), close.
function B:BatchButtons(fade)
	local b = self.batch
	if not (b and b.ended) then
		return
	end
	local s = self.frame
	local left = ns.Packs(b.series)
	local small = self:Small()
	local y = self:BatchEndY() - (END_Y.summary - (small and END_Y.smallButtons or END_Y.buttons))
	self:BatchEndPlace()
	local nx = s.batchNext
	local main
	if left >= 2 then
		local n = math.min(MAX, left)
		nx:SetLabel(left > MAX and string.format(L["Open the next %d (%d left)"], n, left) or string.format(L["Open the last %d"], n))
		local w = (nx.label and ns.TextWidth and ns.TextWidth(nx.label)) or 0
		nx:SetWidth(math.max(220, math.ceil(w) + 44))
		if nx.SetScale then
			nx:SetScale(self.uiK or 1)
		end
		At(nx, "CENTER", s, "CENTER", 0, y)
		CuratorOctoFull.SetEnabled(nx, true)
		s.again:Hide()
		main = nx
	else
		-- (one left: opened as any booster; none: the button greyed)
		nx:Hide()
		CuratorOctoFull.SetEnabled(s.again, left > 0)
		s.again:SetLabel(L["Open another"] .. " (" .. left .. ")")
		At(s.again, "CENTER", s, "CENTER", 0, y)
		main = s.again
	end
	s.album:SetLabel(L[(self.opts and self.BACK_LABEL and self.BACK_LABEL[self.opts.from or ""]) or "Album"])
	s.album:ClearAllPoints()
	s.album:SetPoint("RIGHT", main, "LEFT", -14, 0)
	s.close:ClearAllPoints()
	s.close:SetPoint("LEFT", main, "RIGHT", 14, 0)
	if fade then
		FadeIn(s.album, 0.3, self)
		FadeIn(s.close, 0.3, self)
	else
		s.album:Show()
		s.close:Show()
	end
	main:Show()
	main:SetAlpha(left > 0 and 1 or 0.45)
end

-- The words of the end and the bars under the grid: where a booster has them on a screen of 768 points, right
-- under the cards on a taller one. Their y (and the buttons'), from the line of the words.
function B:BatchEndY()
	local b = self.batch
	local _, _, _, _, _, hgt = self:BatchArea()
	local y = -hgt / 2 + END_Y.summary
	local g = b and b.g
	if g then
		local height = g.rows * g.ch + (g.rows - 1) * g.ch * GY
		y = math.max(y, g.cy - height / 2 - 22)
	end
	return y
end

function B:BatchEndPlace()
	local s = self.frame
	local y = self:BatchEndY()
	At(s.summary, "CENTER", s, "CENTER", 0, y)
	s.bar:ClearAllPoints()
	s.bar:SetPoint("CENTER", s, "CENTER", 0, y - (END_Y.summary - END_Y.bar))
	s.xpBar:ClearAllPoints()
	s.xpBar:SetPoint("CENTER", s, "CENTER", 0, y - (END_Y.summary - END_Y.xp))
end

-- The ten next ones: their pack comes down, and they open.
function B:BatchAgain()
	local b = self.batch
	local series = b and b.series or self.series
	if ns.Packs(series) < 2 then
		return self:Again()
	end
	self.state = "done"
	self:Open(series, { from = self.opts and self.opts.from })
	if self.state ~= "landing" then
		return
	end
	self:PackLands()
	-- (the scene still brings its name down: higher once it is there)
	self:Batch(0.5)
end

-- Stop: no other pack opens; the cards drawn turn over at once.
function B:BatchStop()
	local b = self.batch
	if not b or b.ended or b.stopped then
		return
	end
	b.stopped = true
	self.frame.stop:Hide()
	if b.phase == "wave" or b.phase == "best" then
		return self:BatchQuick()
	end
	-- (the packs: the one being opened bursts as it was going to, its cards are drawn; no other opens, and the
	-- cards turn over at once once they are down: B:BatchCharge, B:BatchCardsDown)
end

-------------------------------------------------------------------------------
-- The cards of the grid under the mouse
-------------------------------------------------------------------------------
-- A card turned over: larger over the others, with its creature and its words; what there is to know of it. A
-- card face down: its light.
function B:GridHover(c, on)
	local b = self.batch
	if not (b and c.pick) then
		return
	end
	if not c.revealed then
		if c.free and not c.busy then
			local r = c.pick.card.rarity
			local rest = (r >= 4 and AURA_GLOW[math.min(6, r)]) or 0
			if r < 4 then
				local col = ns.RARITY[r].glow
				c.glow:SetVertexColor(col[1], col[2], col[3])
			end
			GlowTo(c.glow, on and math.min(1, 0.25 + 0.12 * r) or rest, 0.2, self)
		end
		return
	end
	if on then
		self:BatchZoom(c)
	elseif self.frame.zoom and self.frame.zoom.of == c then
		self:BatchZoom(nil)
	end
end

-- The card under the mouse, larger (nil: none). Its creature is drawn over the frames around it: the creatures
-- of the cards it covers step aside meanwhile.
function B:BatchZoom(c)
	local s = self.frame
	local b = self.batch
	local z = s.zoom
	-- (the creatures it covered come back)
	for i = CuratorOctoFull.Length(b.hidden), 1, -1 do
		local h = b.hidden[i]
		b.hidden[i] = nil
		if h:IsShown() and h.revealed and not (ns.Cinematic and ns.Cinematic:IsPlaying()) and not self.inspecting then
			h.model:Show()
		end
	end
	if not c then
		if z then
			z.of = nil
			if z.tw then
				ns.CancelTween(z.tw)
				z.tw = nil
			end
			z:Hide()
		end
		GameTooltip:Hide()
		return
	end
	if not z then
		z = ns.NewCard(s.zoomLayer, "mid")
		z:EnableMouse(false)
		z:Hide()
		s.zoom = z
	end
	local pick = c.pick
	z.of = c
	z:SetCard(pick.card, { owned = true, finish = pick.finish, count = pick.count, new = pick.new, corrupt = pick.corrupt, pattern = pick.pt,
		wear = pick.wear })
	z:ShowSide("front")
	z.phase = c.phase
	local r = pick.card.rarity
	local col = r >= 2 and ns.RARITY[r].glow or WARM
	z.glow:SetVertexColor(col[1], col[2], col[3])
	z.glow:SetAlpha((r >= 4 and 0.5) or (r == 3 and 0.4) or 0.28)
	-- (as large as ZOOM times the card, never smaller than the card of a booster of a zone; whole on the scene)
	local k = b.g.k
	local k1 = math.max(1, ZOOM * k * c.W / z.W)
	local zw, zh = z.W * k1, z.H * k1
	local _, _, _, _, w, h = self:BatchArea()
	local x = math.max(-w / 2 + zw / 2 + 8, math.min(w / 2 - zw / 2 - 8, c.slotX))
	local y = math.max(-h / 2 + zh / 2 + 8, math.min(h / 2 - zh / 2 - 8, c.slotY))
	-- (the creatures it covers, and its own card's, step aside)
	for _, o in ipairs(b.cards) do
		if o.oaModel and o.revealed and o.model:IsShown() and math.abs(o.slotX - x) < (zw + o.W * k) / 2 and math.abs(o.slotY - y) < (zh + o.H * k) / 2 then
			o.model:Hide()
			b.hidden[CuratorOctoFull.Length(b.hidden) + 1] = o
		end
	end
	local k0 = k * c.W / z.W
	if z.tw then
		ns.CancelTween(z.tw)
	end
	z:SetAlpha(0)
	z:Show()
	z.tw = ns.Tween(0.16, function(e)
		local q = k0 + (k1 - k0) * e
		z:SetScale(q)
		z:ClearAllPoints()
		z:SetPoint("CENTER", s.zoomLayer, "CENTER", (c.slotX + (x - c.slotX) * e) / q, (c.slotY + (y - c.slotY) * e) / q)
		z:SetAlpha(math.min(1, e * 2.5))
	end, function()
		z.tw = nil
	end, Ease.outBack, self)
	-- what there is to know of it, beside it (on the side with room)
	GameTooltip:SetOwner(z, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	if x > 0 then
		GameTooltip:SetPoint("RIGHT", z, "LEFT", -8, 0)
	else
		GameTooltip:SetPoint("LEFT", z, "RIGHT", 8, 0)
	end
	self:CardTooltip(pick.card, pick)
	if ns.Links then
		ns.Links:AddHint(GameTooltip, false)
	end
	GameTooltip:Show()
end

-- A click on a card turned over: it comes up close (B:Inspect); with the key of the links, its link in the chat.
function B:GridClick(c)
	if not (self.batch and c.pick and c.revealed) then
		return
	end
	if ns.Links and ns.Links:Modified() then
		-- (1.14.3: the copy that came, its very card: UI/Links.lua)
		local p = c.pick
		ns.Links:Insert(p.card, p.finish, p.pt, nil, p.ci and ns.Copies and ns.Copies:Get(p.card.key, p.ci) or nil)
		return
	end
	self:BatchZoom(nil)
	if self.Inspect then
		self:Inspect(c)
	end
end

-------------------------------------------------------------------------------
-- Every frame, and the scene put back
-------------------------------------------------------------------------------
-- The packs waiting their turn; the wave; the best cards face down (their light breathes, their rays turn); what
-- moves on the cards turned over; the card under the mouse.
function B:BatchTick(dt, t)
	local b = self.batch
	if b.phase == "wave" then
		self:BatchWaveTick(dt)
	end
	local s = self.frame
	if b.phase == "packs" then
		for i, pk in ipairs(b.packs) do
			if pk.landed and not pk.opened and not b.packsDone then
				local f = pk.frame
				f:ClearAllPoints()
				f:SetPoint("CENTER", s.stage, "CENTER", pk.x / pk.k, (pk.y + math.sin(t * 1.8 + i * 0.7) * 4) / pk.k)
			end
		end
	end
	for i, c in ipairs(b.glowing) do
		local ray = c.oaRays
		if not c.revealed and not c.busy and c.free then
			-- (stronger than on the cards of a booster: these are small, among many)
			local r = math.min(6, c.pick.card.rarity)
			local base = (AURA_GLOW[r] or 0.22) * 1.5
			local breath = 1 + math.sin(t * 2.4 + i * 1.7)
			if not c.back.glow.tw then
				c.back.glow:SetAlpha(math.min(1, base * 1.4 * (0.8 + 0.4 * breath)))
			end
			if not c.back.core.tw then
				c.back.core:SetAlpha(math.min(1, base * 1.3 * (0.7 + 0.5 * breath)))
			end
			if not c.glow.tw then
				c.glow:SetAlpha(math.min(1, base * (1 + 0.5 * breath)))
			end
			if ray then
				CuratorOctoFull.SetRotation(ray, t * 0.35 * (CuratorOctoFull.Mod(i , 2) == 0 and 1 or -1))
				if not ray.tw then
					ray:SetAlpha(math.min(1, (AURA_RAYS[r] or 0.16) * 1.6 * (0.75 + 0.25 * math.sin(t * 1.9 + i))))
				end
			end
		end
	end
	-- (what moves on the cards turned over: the finishes, the light of the best ones, the cards of an event)
	for _, c in ipairs(b.cards) do
		if c.revealed and (c.shine:IsShown() or c.art.rays:IsShown()) and c:IsShown() then
			c:Tick(t)
		end
	end
	local z = s.zoom
	if z and z:IsShown() then
		z:Tick(t)
	end
end

-- The scene put back (another booster, or closed): the grid, the packs, the card under the mouse gone; its
-- words and its buttons where they were.
function B:BatchReset()
	local s = self.frame
	local b = self.batch
	self.batch = nil
	if not s or not s.grid then
		return
	end
	if b then
		for _, h in ipairs(b.hidden) do
			h.model:Show()
		end
	end
	for _, c in ipairs(self.gridCards) do
		c:Hide()
		c.pick, c.free, c.revealed, c.busy, c.flipping, c.flyTw, c.moveTw = nil, false, false, false, false, nil, nil
		c.glow:SetAlpha(0)
		c.glow.tw = nil
		c.hot:SetAlpha(0)
		c.hot.tw = nil
		c.badge:Hide()
		if c.oaRays then
			c.oaRays:SetAlpha(0)
			c.oaRays.tw = nil
		end
		if c.oaName then
			c.oaName:Hide()
		end
	end
	for _, p in ipairs(self.batchPacks) do
		p:Hide()
	end
	if s.zoom then
		s.zoom.of = nil
		s.zoom.tw = nil
		s.zoom:Hide()
	end
	s.batchNext:Hide()
	s.batchDim:SetAlpha(0)
	s.batchDim.tw = nil
	s.again:SetAlpha(1)
	-- (the buttons, the words and the bars of the scene where they were)
	if b then
		self:PlaceUI()
		s.bar:ClearAllPoints()
		s.bar:SetPoint("CENTER", 0, -214)
		s.xpBar:ClearAllPoints()
		s.xpBar:SetPoint("CENTER", 0, -240)
	end
end
