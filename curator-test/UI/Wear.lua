local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (his idea, 31 October) The wear of a copy on its card (Wear.lua: its grade, its four marks, its seed): pieces drawn
-- before (Media\Wear) put together by its seed, never twice the same. Its corners whitened, rounded, split, a dog-ear;
-- its edges rubbed, chipped, torn; scratches (that catch the light: the more as the light runs across them, held in the
-- hand), gouges, creases, a bend, a crumpled patch, dents, fingernail crescents, a pin hole, the mark of a rubber band;
-- the ring of a mug, water, foxing, grime, the print torn off, tape, a sticker pulled off, the card yellowed, a side
-- faded; specks of ink, a hair. (20 h 11, his word: a 10 has nothing at all; a 1 is worn through, it shows at once.)
-- Its grade only a tendency: the best ones look alike.
-- Each piece: B laid over the card (BLEND), G added (ADD, the light). On the card itself, over all that is printed on
-- it (its frame, its picture, its words, its pennant), under its case only; squeezed with it when it turns over, and in
-- 3D cut into small cells that lie on the card as its face does (his word, 14 h 14: on the card, never a sheet over it).
-------------------------------------------------------------------------------
local WU = {}
ns.WearUI = WU

local MEDIA = ns.MEDIA .. "Wear\\"
local floor, sin, cos, abs, sqrt, pi = math.floor, math.sin, math.cos, math.abs, math.sqrt, math.pi

local CORNER_K = { 0.04, 0.08, 0.14, 0.22, 0.34, 0.52, 0.8, 1.25 }
local EDGE_S = { 0.08, 0.18, 0.32, 0.5, 0.72, 1.0 }
-- (the sides of the pieces laid at its corners and edges, in widths of the card: Media\Wear, as they were drawn)
local CORNER_SIDE, DOG_SIDE, EDGE_LEN, EDGE_DEPTH, TEAR_SIDE = 0.24, 0.34, 0.40, 0.05, 0.14
local ROUND = 22 / 366 -- (the round of its corners, in widths of the card: Card.lua)
-- (how many of each were drawn)
local NV = {
	Corner = 8, DogEar = 8, Edge = 6, Tear = 12, Scratch = 24, Swipe = 4, Deep = 12, Fold = 6, Bend = 6, Crumple = 6,
	Dent = 10, Nail = 6, Pin = 4, Band = 4, Stain = 12, Water = 6, Fox = 6, Grime = 6, Loss = 8, Tape = 4, Sticker = 4,
	Tan = 4, Fade = 3, Lint = 5,
}

-- How much of each, by its mark (1 to 10; 10: nothing at all). A number: so many on average (0.3: one, three times in
-- ten). His word, 20 h 11: a 1 must show it at once, a 2 and a 3 far more than they did; 9 and 8 as good as new.
local HOW = {
	-- its corners: the chance that each is touched, how worn (the least, the most: CORNER_K); a dog-ear
	cornerP = { 1, 1, 1, 1, 1, 0.8, 0.55, 0.3, 0.06, 0 },
	cornerLo = { 0.85, 0.55, 0.36, 0.22, 0.13, 0.08, 0.05, 0.035, 0.03, 0 },
	cornerHi = { 1.25, 1.1, 0.8, 0.5, 0.34, 0.22, 0.13, 0.07, 0.045, 0 },
	dogear = { 1.3, 0.6, 0.3, 0.08, 0, 0, 0, 0, 0, 0 },
	-- its edges: pieces along each side, how worn (EDGE_S); tears, chips, knocks
	edgeN = { 5, 4, 3, 2, 1.4, 0.8, 0.35, 0.1, 0, 0 },
	edgeLo = { 0.8, 0.6, 0.4, 0.28, 0.18, 0.1, 0.08, 0.08, 0, 0 },
	edgeHi = { 1.0, 1.0, 0.8, 0.55, 0.4, 0.28, 0.18, 0.1, 0, 0 },
	tear = { 1.8, 0.8, 0.3, 0.06, 0, 0, 0, 0, 0, 0 },
	-- its surface
	scratch = { 18, 12, 8, 4.5, 3, 1.8, 0.8, 0.3, 0.1, 0 },
	swipe = { 1.2, 0.7, 0.35, 0.15, 0.05, 0, 0, 0, 0, 0 },
	deep = { 4, 2.5, 1.2, 0.4, 0.15, 0.05, 0, 0, 0, 0 },
	fold = { 3.2, 2.0, 1.1, 0.5, 0.3, 0, 0, 0, 0, 0 },
	bend = { 0.6, 0.5, 0.45, 0.35, 0.2, 0.08, 0, 0, 0, 0 },
	crumple = { 1.0, 0.4, 0.1, 0, 0, 0, 0, 0, 0, 0 },
	dent = { 3.5, 2.2, 1.4, 0.7, 0.4, 0.15, 0.06, 0, 0, 0 },
	nail = { 1.8, 1.2, 0.8, 0.45, 0.3, 0.1, 0, 0, 0, 0 },
	stain = { 1.6, 1.0, 0.6, 0.25, 0.06, 0, 0, 0, 0, 0 },
	water = { 0.65, 0.35, 0.12, 0, 0, 0, 0, 0, 0, 0 },
	speck = { 9, 6, 4, 3, 2.2, 1.6, 1.0, 0.6, 0.25, 0 },
	fox = { 1.6, 0.8, 0.3, 0.1, 0, 0, 0, 0, 0, 0 },
	grime = { 2.5, 1.2, 0.4, 0.1, 0, 0, 0, 0, 0, 0 },
	loss = { 1.4, 0.5, 0.15, 0, 0, 0, 0, 0, 0, 0 },
	tape = { 0.25, 0.12, 0.04, 0, 0, 0, 0, 0, 0, 0 },
	sticker = { 0.25, 0.12, 0.04, 0, 0, 0, 0, 0, 0, 0 },
	pin = { 0.2, 0.08, 0, 0, 0, 0, 0, 0, 0, 0 },
	band = { 0.25, 0.2, 0.12, 0.06, 0, 0, 0, 0, 0, 0 },
	lint = { 0.6, 0.45, 0.35, 0.25, 0.18, 0.12, 0.08, 0, 0, 0 },
	-- the whole card: yellowed (its chance, how much), a side faded by the sun
	tanP = { 1, 0.9, 0.55, 0.25, 0.12, 0.05, 0, 0, 0, 0 },
	tanA = { 0.95, 0.75, 0.55, 0.42, 0.32, 0.25, 0, 0, 0, 0 },
	fadeP = { 0.45, 0.4, 0.3, 0.22, 0.15, 0.08, 0, 0, 0, 0 },
}

-- (how worn a mark makes it: slowly, then fast; 10 nothing)
local function Sev(m)
	return (math.max(0, (10 - m) / 9)) ^ 1.8
end

-- (so many: x on average, a little more or less)
local function Count(rnd, x)
	if not x or x <= 0 then
		return 0
	end
	if x >= 2 then
		x = x * (0.75 + 0.5 * rnd())
	end
	local n = floor(x)
	if rnd() < x - n then
		n = n + 1
	end
	return n
end

-- (one of n)
local function Pick(rnd, n)
	return 1 + CuratorOctoFull.Mod(floor(rnd() * n) , n)
end

local function Nearest(list, v)
	local best, bd = 1, CuratorOctoFull.Huge
	for i, x in ipairs(list) do
		local d = abs(x - v)
		if d < bd then
			best, bd = i, d
		end
	end
	return best
end

-- (31 October, the enchanter redone) Each flaw of a copy, made of one piece or two: what it marks of the four (2 its
-- corners, 3 its edges, 4 its surface: its centering, the first, the enchanters never touch) and how much it weighs
-- in it. A flaw mended by an enchanter is gone from the card for good (the copy keeps which ones: wear.x); what went
-- wrong at his bench is a flaw of its own (wear.a).
local FLAW = {
	corner = { 2, 1 }, dogear = { 2, 2.2 }, edge = { 3, 0.6 }, tear = { 3, 2 },
	scratch = { 4, 0.3 }, swipe = { 4, 0.5 }, deep = { 4, 1 }, fold = { 4, 1.6 }, bend = { 4, 0.8 }, crumple = { 4, 1.8 },
	dent = { 4, 0.45 }, nail = { 4, 0.35 }, pin = { 4, 0.5 }, band = { 4, 0.7 }, stain = { 4, 0.8 }, water = { 4, 1.1 },
	fox = { 4, 0.4 }, grime = { 4, 0.5 }, loss = { 4, 1.1 }, tape = { 4, 0.9 }, sticker = { 4, 0.8 }, tan = { 4, 1.6 },
	fade = { 4, 1.2 }, speck = { 4, 0.08 }, lint = { 4, 0.05 },
}
WU.FLAW = FLAW
-- (the mishaps of the bench: their kind, their pieces)
local MISHAP = { stain = "Stain", water = "Water", fox = "Fox" }
WU.MISHAP = MISHAP
local CUR -- (the flaw being laid: its pieces go to it)
-- (31 October, the review of the night: its wear laid on a card of reference, then brought to the size of this one)
local SX, SY = 1, 1

-- (the layers of the pieces, under to over)
local SUB = { tan = -8, fade = -8, water = -7, stain = -6, fox = -6, grime = -6, tape = -5, sticker = -5, bend = -4,
	scratchB = -3, scratchG = -2, fold = -1, dent = 0, loss = 1, edge = 2, dogear = 2, corner = 3, speck = 4, lint = 5 }

-- A piece of the card (turn: a piece that turns; its own pool, the card in 3D turning it the same, Card.lua: quads).
local function Piece(c, turn, i)
	local pool = turn and c.wearTurn or c.wearFlip
	local p = pool[i]
	if not p then
		p = c.wearF:CreateTexture(nil, "OVERLAY")
		if p.SetSnapToPixelGrid then
			p:SetSnapToPixelGrid(false)
			p:SetTexelSnappingBias(0)
		end
		p.turn = turn
		pool[i] = p
	end
	return p
end

-- The corners of a piece in its texture (UL, LL, UR, LR, as SetTexCoord takes them): turned by rot (its width lying
-- that way on the card, downward), or flipped (tc: left, right, top, bottom). asp: a texture asp times as wide as it is
-- high (a crease, a rubber band), laid in a square as wide as it, its height across the middle of it.
local function Corners(rot, tc, asp)
	if rot then
		local cr, sr = cos(rot), sin(rot)
		local k = asp or 1
		local function At(dx, dy)
			return 0.5 + cr * dx + sr * dy, 0.5 + k * (-sr * dx + cr * dy)
		end
		local ulx, uly = At(-0.5, -0.5)
		local llx, lly = At(-0.5, 0.5)
		local urx, ury = At(0.5, -0.5)
		local lrx, lry = At(0.5, 0.5)
		return { ulx, uly, llx, lly, urx, ury, lrx, lry }
	end
	local l, r, t, b = 0, 1, 0, 1
	if tc then
		l, r, t, b = tc[1], tc[2], tc[3], tc[4]
	end
	return { l, t, l, b, r, t, r, b }
end

-- Puts a piece: its texture, how it is laid, where (its middle, from the top left of the card), how big, which way.
local function Put(c, p, file, blend, sub, x, y, w, h, rot, tc, alpha, asp)
	x, y, w, h = x * SX, y * SY, w * SX, h * SY
	p.file = MEDIA .. file
	p.kind = CuratorOctoFull.Match(file, "^%a+")
	p:SetTexture(p.file, "CLAMP", "CLAMP")
	p.blend = blend
	p:SetBlendMode(blend)
	p:SetVertexColor(1, 1, 1)
	p:SetDrawLayer("OVERLAY", sub)
	p.sub = sub
	p.tc8 = Corners(rot, tc, asp)
	p:SetTexCoord(unpack(p.tc8))
	-- (where it lies, in shares of the card: squeezed with it, WU.Fit)
	p.fx, p.fy, p.fw, p.fh = x / c.W, y / c.H, w / c.W, h / c.H
	p:ClearAllPoints()
	p:SetPoint("CENTER", c, "TOPLEFT", x, -y)
	CuratorOctoFull.SetSize(p, w, h)
	p.base = alpha or 1
	p:SetAlpha(p.base)
	-- (where it is on the card at rest, from its middle, upward: the card in 3D, Card.lua)
	local cx, cy = x - c.W / 2, c.H / 2 - y
	p.rest = { cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2 }
	p.glint, p.ang, p.soft = nil, nil, nil
	p:Show()
	p.flaw = CUR
	if CUR then
		CUR.pieces[CuratorOctoFull.Length(CUR.pieces) + 1] = p
		-- (a flaw an enchanter mended: gone from the card)
		if CUR.gone then
			p:Hide()
		end
	end
	return p
end

-- The card turning over (Card.lua: SetFlipSize, the card w by h): its pieces squeezed with it, as its face is.
function WU.Fit(c, w, h)
	if not c.wearOn then
		return
	end
	for _, pool in ipairs({ c.wearFlip, c.wearTurn }) do
		for _, p in ipairs(pool) do
			if p:IsShown() and p.fx then
				p:ClearAllPoints()
				p:SetPoint("CENTER", c, "TOPLEFT", p.fx * w, -p.fy * h)
				CuratorOctoFull.SetSize(p, math.max(0.01, p.fw * w), math.max(0.01, p.fh * h))
			end
		end
	end
end

-------------------------------------------------------------------------------
-- In 3D (Card.lua: BuildHeld, HeldSync, HeldPaint). One quad for a whole piece, its corners where the card puts them,
-- drew what is inside it flat between them: up to 19 points off the card when it turns (a fold, as big as the card).
-- Each piece is cut into small cells instead, each corner of each cell where the card puts that point (as its face is,
-- Card.lua: Project): it lies on the card in every pose, less than a fifth of a point off.
-------------------------------------------------------------------------------
-- (where each piece has something, from the middle of its texture: half its width, half its height; Media\Wear,
-- sprites2.py: pieces.json)
local BOX = {
	BandB = { 0.5, 0.14 }, BandG = { 0.5, 0.16 }, BendB = { 0.46, 0.45 }, BendG = { 0.46, 0.43 },
	CrumpleB = { 0.48, 0.46 }, CrumpleG = { 0.45, 0.46 }, DeepB = { 0.45, 0.05 }, DeepG = { 0.45, 0.05 },
	DentB = { 0.47, 0.48 }, DentG = { 0.47, 0.47 }, FoldB = { 0.46, 0.48 }, FoldG = { 0.46, 0.39 },
	Fox = { 0.46, 0.46 }, Grime = { 0.47, 0.47 }, Lint = { 0.42, 0.34 }, Loss = { 0.48, 0.44 }, NailB = { 0.25, 0.45 },
	NailG = { 0.39, 0.45 }, PinB = { 0.42, 0.42 }, PinG = { 0.41, 0.42 }, ScratchB = { 0.45, 0.07 },
	ScratchG = { 0.45, 0.07 }, Speck = { 0.42, 0.48 }, Stain = { 0.49, 0.5 }, Sticker = { 0.4, 0.26 },
	SwipeB = { 0.44, 0.1 }, SwipeG = { 0.44, 0.1 }, TapeB = { 0.44, 0.17 }, TapeG = { 0.42, 0.17 },
	TearH = { 0.38, 0.5 }, TearHG = { 0.39, 0.5 }, TearV = { 0.5, 0.38 }, TearVG = { 0.5, 0.39 },
	Water = { 0.49, 0.42 },
}
local FULL = { 0.5, 0.5 }
-- (the side of a cell, in widths of the card; the whole card yellowed, a side faded by the sun, soft all over and as
-- large as the card: the cells of its face, 6 by 8, Card.lua: BuildHeld)
local CELL = 1 / 9
local FACE = { Fade = { 6, 8 }, Tan = { 6, 8 } }

-- The point (s across, t down, 0 to 1) of a piece, in its texture.
local function TC(q, s, t)
	local a, b, cc, d = (1 - s) * (1 - t), s * (1 - t), (1 - s) * t, s * t
	return a * q[1] + cc * q[3] + b * q[5] + d * q[7], a * q[2] + cc * q[4] + b * q[6] + d * q[8]
end

-- Does a cell (its corners in the texture) show something of its piece?
local function Meets(box, a1, a2, b1, b2, c1, c2, d1, d2)
	local u1, u2 = math.min(a1, b1, c1, d1), math.max(a1, b1, c1, d1)
	local v1, v2 = math.min(a2, b2, c2, d2), math.max(a2, b2, c2, d2)
	return u2 > 0.5 - box[1] and u1 < 0.5 + box[1] and v2 > 0.5 - box[2] and v1 < 0.5 + box[2]
end

function WU.Held(c, h)
	-- (its cells over the words of the card held, under nothing but its case: Card.lua, Hold)
	h.wear = { n = 0 }
end

local function Cell(c, hw, h, k)
	local t = hw[k]
	if not t then
		t = h.texts:CreateTexture(nil, "OVERLAY")
		if t.SetSnapToPixelGrid then
			t:SetSnapToPixelGrid(false)
			t:SetTexelSnappingBias(0)
		end
		t:Hide()
		hw[k] = t
	end
	return t
end

-- Its pieces cut into cells, laid on the card held (Card:HeldSync; its wear given again while held, WU.Set).
function WU.Mesh(c)
	local h = c.held3
	local hw = h and h.wear
	if not hw then
		return
	end
	local W, H = c.W, c.H
	local k = 0
	if c.wearOn then
		for _, pool in ipairs({ c.wearFlip, c.wearTurn }) do
			for _, p in ipairs(pool) do
				if p:IsShown() and p.rest and p.tc8 then
					local x1, y1, x2, y2 = p.rest[1], p.rest[2], p.rest[3], p.rest[4]
					local pw, ph = x2 - x1, y2 - y1
					local nx = math.max(1, math.min(12, math.ceil(pw / (W * CELL) - 0.01)))
					local ny = math.max(1, math.min(12, math.ceil(ph / (W * CELL) - 0.01)))
					if FACE[p.kind] then
						nx, ny = FACE[p.kind][1], FACE[p.kind][2]
					end
					local box, q = BOX[p.kind] or FULL, p.tc8
					for j = 0, ny - 1 do
						local t0, t1 = j / ny, (j + 1) / ny
						local cy2, cy1 = y2 - t0 * ph, y2 - t1 * ph
						for i = 0, nx - 1 do
							local s0, s1 = i / nx, (i + 1) / nx
							local cx1, cx2 = x1 + s0 * pw, x1 + s1 * pw
							-- (on the card only, and only where the piece has something)
							if cx2 > -W / 2 and cx1 < W / 2 and cy2 > -H / 2 and cy1 < H / 2 then
								local a1, a2 = TC(q, s0, t0)
								local b1, b2 = TC(q, s0, t1)
								local c1, c2 = TC(q, s1, t0)
								local d1, d2 = TC(q, s1, t1)
								if Meets(box, a1, a2, b1, b2, c1, c2, d1, d2) then
									k = k + 1
									local t = Cell(c, hw, h, k)
									t:SetTexture(p.file, "CLAMP", "CLAMP")
									t:SetBlendMode(p.blend or "BLEND")
									t:SetDrawLayer("OVERLAY", p.sub or 0)
									t:SetTexCoord(a1, a2, b1, b2, c1, c2, d1, d2)
									t:ClearAllPoints()
									t:SetPoint("TOPLEFT", c, "CENTER", cx1, cy2)
									CuratorOctoFull.SetSize(t, cx2 - cx1, cy2 - cy1)
									local r = t.r or {}
									r[1], r[2], r[3], r[4] = cx1, cy1, cx2, cy2
									t.r, t.src, t.pose, t.a, t.on, t.vk = r, p, nil, nil, nil, nil
									t:SetVertexColor(1, 1, 1)
									t:Hide()
								end
							end
						end
					end
				end
			end
		end
	end
	for i = k + 1, CuratorOctoFull.Length(hw) do
		local t = hw[i]
		t.src, t.on = nil, nil
		t:Hide()
	end
	hw.n = k
end

-- Every frame, held (Card:HeldPaint): each cell where the card puts its corners now, as bright as its piece (the glint
-- of a scratch, UI/Wear.lua: Tick).
function WU.HeldPaint(c, pose)
	local h = c.held3
	local hw = h and h.wear
	if not (hw and hw.n and hw.n > 0) then
		return
	end
	local WarpQuad = ns.Card3D.WarpQuad
	for i = 1, hw.n do
		local t = hw[i]
		local p = t.src
		local a = p and p:GetAlpha() or 0
		local on = p ~= nil and c.wearOn and p:IsShown() and a > 0.002
		if on then
			if t.pose ~= pose then
				local r = t.r
				WarpQuad(c, t, r[1], r[2], r[3], r[4])
				t.pose = pose
			end
			if a ~= t.a then
				t.a = a
				t:SetAlpha(a)
			end
			-- (1 November: a flaw lit on the card, the enchanter's quote: its cells lit with it)
			if p.GetVertexColor then
				local vr, vg, vb = p:GetVertexColor()
				local vk = (vr or 1) * 1000000 + (vg or 1) * 1000 + (vb or 1)
				if vk ~= t.vk then
					t.vk = vk
					t:SetVertexColor(vr or 1, vg or 1, vb or 1)
				end
			end
		end
		if on ~= t.on then
			t.on = on
			CuratorOctoFull.SetShown(t, on)
		end
	end
end

local function HideFrom(pool, n)
	for i = n, CuratorOctoFull.Length(pool) do
		pool[i]:Hide()
		pool[i].rest = nil
	end
end

-- The wear of a copy on a card (wear: Wear.lua, W.Of; nil: none), its face shown (front) or not.
function WU.Set(c, wear, front)
	if not c.wearF then
		return
	end
	if not (wear and front) then
		if c.wearOn then
			HideFrom(c.wearFlip, 1)
			HideFrom(c.wearTurn, 1)
			c.wearF:Hide()
			c.wearOn = false
		end
		c.wearKey = nil
		if c.wearFlaws then
			CuratorOctoFull.Wipe(c.wearFlaws)
		end
		return
	end
	local key = tostring(wear.seed) .. ":" .. table.concat(wear.m, "") .. ":" .. c.W .. ":" .. tostring(wear.x or "") .. ":" .. tostring(wear.a or "")
	if c.wearOn and c.wearKey == key then
		return
	end
	c.wearKey = key
	c.wearOn = true
	c.wearF:Show()
	c.wearGlints = c.wearGlints or {}
	CuratorOctoFull.Wipe(c.wearGlints)
	-- (31 October, the review of the night: laid on a card of reference, 330 wide, of the shape of this one to the
	-- hundredth, then brought to its size, Put: the same flaws in the same order whatever its size, those the enchanter
	-- mended, Restore.lua, the very ones gone from it)
	local W = 330
	local H = W * floor((c.H / c.W) * 100 + 0.5) / 100
	SX, SY = c.W / W, c.H / H
	local u = W / 330
	local rnd = ns.Wear.Rng(wear.seed)
	-- (a point on the card, m inside its edge, its corners round: nothing of its wear past them)
	local rho = W * ROUND
	local function In(px, py, m)
		local k = math.max(rho, m)
		local qx = px < k and k - px or (px > W - k and px - (W - k) or 0)
		local qy = py < k and k - py or (py > H - k and py - (H - k) or 0)
		return qx * qx + qy * qy <= (k - m) * (k - m)
	end
	-- (its flaws, one by one: the ones an enchanter mended, gone)
	c.wearFlaws = c.wearFlaws or {}
	CuratorOctoFull.Wipe(c.wearFlaws)
	local gone = {}
	for id in CuratorOctoFull.Gmatch(tostring(wear.x or ""), "%d+") do
		gone[tonumber(id)] = true
	end
	local fk = 0
	local function Flaw(kind, x, y, sev)
		fk = fk + 1
		local d = FLAW[kind]
		CUR = { id = fk, kind = kind, cat = d[1], sev = sev or d[2], x = x / W, y = y / H, pieces = {}, gone = gone[fk] or nil }
		c.wearFlaws[CuratorOctoFull.Length(c.wearFlaws) + 1] = CUR
		return CUR
	end
	local nf, nt = 0, 0
	local function F()
		nf = nf + 1
		return Piece(c, false, nf)
	end
	local function T()
		nt = nt + 1
		return Piece(c, true, nt)
	end
	local function Glint(p, ang, soft)
		p.glint, p.ang, p.soft = true, ang, soft
		c.wearGlints[CuratorOctoFull.Length(c.wearGlints) + 1] = p
	end
	local cen, cor, edg, sur = wear.m[1], wear.m[2], wear.m[3], wear.m[4]
	local _ = cen -- (its centering: the expert sees it, the card shows it not)
	local function How(what, m)
		return HOW[what][math.max(1, math.min(10, floor(tonumber(m) or 10)))] or 0
	end
	-- (each corner the top left one turned: left, right, top, bottom)
	local CORNERS = { { 0, 1, 0, 1 }, { 1, 0, 0, 1 }, { 0, 1, 1, 0 }, { 1, 0, 1, 0 } }

	-- its corners
	local side = W * CORNER_SIDE
	for i = 1, 4 do
		if rnd() < How("cornerP", cor) then
			local lo, hi = How("cornerLo", cor), How("cornerHi", cor)
			local x = (i == 1 or i == 3) and side / 2 or W - side / 2
			local y = i <= 2 and side / 2 or H - side / 2
			local lvl = Nearest(CORNER_K, lo + (hi - lo) * rnd())
			Flaw("corner", x, y, 0.3 + 0.9 * lvl / CuratorOctoFull.Length(CORNER_K))
			Put(c, F(), string.format(("Corner%d_%d"), lvl, Pick(rnd, NV.Corner)), "BLEND",
				SUB.corner, x, y, side, side, nil, CORNERS[i])
		end
	end
	-- (a dog-ear or two: a corner once folded over)
	local dogs = {}
	for _ = 1, math.min(2, Count(rnd, How("dogear", cor))) do
		local i = Pick(rnd, 4)
		if not dogs[i] then
			dogs[i] = true
			local ds = W * DOG_SIDE
			local x = (i == 1 or i == 3) and ds / 2 or W - ds / 2
			local y = i <= 2 and ds / 2 or H - ds / 2
			local v = Pick(rnd, NV.DogEar)
			Flaw("dogear", x, y)
			Put(c, F(), "DogEarB" .. v, "BLEND", SUB.dogear, x, y, ds, ds, nil, CORNERS[i])
			Glint(Put(c, F(), "DogEarG" .. v, "ADD", SUB.dogear, x, y, ds, ds, nil, CORNERS[i], 0.7), 0, true)
		end
	end
	-- its edges, rubbed here and there along each side (the worst ones all along)
	local nE = How("edgeN", edg)
	if nE > 0 then
		local len, dep = W * EDGE_LEN, W * EDGE_DEPTH
		local lo, hi = How("edgeLo", edg), How("edgeHi", edg)
		for sd = 1, 4 do
			local long = sd > 2
			local L = long and H or W
			local n = math.min(6, Count(rnd, nE * (long and 1.3 or 1)))
			for j = 1, n do
				local lvl = Nearest(EDGE_S, lo + (hi - lo) * rnd())
				local file = string.format(("Edge%s%d_%d"), long and "V" or "H", lvl, Pick(rnd, NV.Edge))
				local ln = len * (1 + (edg <= 2 and 0.5 or 0.2) * rnd())
				local t = math.max(0, math.min(1, (j - 0.5 + (rnd() - 0.5) * 0.9) / n))
				local at = ln / 2 + 0.05 * W + t * (L - ln - 0.1 * W)
				local mir = rnd() < 0.5
				local esev = 0.2 + 0.6 * lvl / CuratorOctoFull.Length(EDGE_S)
				if sd == 1 then
					Flaw("edge", at, dep / 2, esev)
					Put(c, F(), file, "BLEND", SUB.edge, at, dep / 2, ln, dep, nil, mir and { 1, 0, 0, 1 } or { 0, 1, 0, 1 })
				elseif sd == 2 then
					Flaw("edge", at, H - dep / 2, esev)
					Put(c, F(), file, "BLEND", SUB.edge, at, H - dep / 2, ln, dep, nil, mir and { 1, 0, 1, 0 } or { 0, 1, 1, 0 })
				elseif sd == 3 then
					Flaw("edge", dep / 2, at, esev)
					Put(c, F(), file, "BLEND", SUB.edge, dep / 2, at, dep, ln, nil, mir and { 0, 1, 1, 0 } or { 0, 1, 0, 1 })
				else
					Flaw("edge", W - dep / 2, at, esev)
					Put(c, F(), file, "BLEND", SUB.edge, W - dep / 2, at, dep, ln, nil, mir and { 1, 0, 1, 0 } or { 1, 0, 0, 1 })
				end
			end
		end
	end
	-- (tears, chips, knocks on its edges)
	for _ = 1, math.min(4, Count(rnd, How("tear", edg))) do
		local ts = W * TEAR_SIDE
		local sd = Pick(rnd, 4)
		local L = sd > 2 and H or W
		local at = ts / 2 + 0.08 * W + rnd() * (L - ts - 0.16 * W)
		local v = Pick(rnd, NV.Tear)
		local mir = rnd() < 0.5
		local x, y, tc, f
		if sd == 1 then
			x, y, tc, f = at, ts / 2, mir and { 1, 0, 0, 1 } or { 0, 1, 0, 1 }, "TearH"
		elseif sd == 2 then
			x, y, tc, f = at, H - ts / 2, mir and { 1, 0, 1, 0 } or { 0, 1, 1, 0 }, "TearH"
		elseif sd == 3 then
			x, y, tc, f = ts / 2, at, mir and { 0, 1, 1, 0 } or { 0, 1, 0, 1 }, "TearV"
		else
			x, y, tc, f = W - ts / 2, at, mir and { 1, 0, 1, 0 } or { 1, 0, 0, 1 }, "TearV"
		end
		Flaw("tear", x, y)
		Put(c, F(), f .. v, "BLEND", SUB.edge, x, y, ts, ts, nil, tc)
		Glint(Put(c, F(), f .. "G" .. v, "ADD", SUB.edge, x, y, ts, ts, nil, tc, 0.7), 0, true)
	end

	-- its surface
	local ss = Sev(sur)
	local function Inside(r)
		r = math.min(r, W * 0.45, H * 0.45)
		local x, y
		for _ = 1, 12 do
			x, y = r + rnd() * (W - 2 * r), r + rnd() * (H - 2 * r)
			if In(x, y, r) then
				return x, y
			end
		end
		return W / 2, y
	end
	-- (does a piece lie on the card: where its texture has something (BOX), laid there, that big, turned so)
	local function OnCard(x, y, cr, sr, a, b)
		return In(x + a * cr - b * sr, y + a * sr + b * cr, 1.5 * u)
	end
	-- (shape "box": all its box, a crease, a strip of tape; else the ellipse in its box)
	local function Fits(x, y, size, rot, box, asp, shape)
		local cr, sr = cos(rot), sin(rot)
		local bu, bv = box[1] * size, box[2] * size / (asp or 1)
		for k = 0, 15 do
			local th = k * pi / 8
			if not OnCard(x, y, cr, sr, bu * cos(th), bv * sin(th)) then
				return false
			end
		end
		if shape == "box" then
			for _, q in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
				if not OnCard(x, y, cr, sr, bu * q[1], bv * q[2]) then
					return false
				end
			end
		end
		return true
	end
	-- (scratches: their groove, their glint; gouges through to the stock)
	local function Line(fb, fg, nv, L, ag, box)
		local rot = rnd() * pi
		local size = L / 0.86
		local v = Pick(rnd, nv)
		for _ = 1, 8 do
			local x, y = rnd() * W, rnd() * H
			if Fits(x, y, size, rot, box) then
				Flaw(fb == "SwipeB" and "swipe" or (fb == "DeepB" and "deep" or "scratch"), x, y)
				Put(c, T(), fb .. v, "BLEND", SUB.scratchB, x, y, size, size, rot)
				Glint(Put(c, T(), fg .. v, "ADD", SUB.scratchG, x, y, size, size, rot, nil, ag), rot)
				return
			end
		end
	end
	for _ = 1, math.min(26, Count(rnd, How("scratch", sur))) do
		Line("ScratchB", "ScratchG", NV.Scratch, (15 + 170 * rnd() ^ 2) * u, 0.5 + 0.4 * ss, BOX.ScratchB)
	end
	for _ = 1, math.min(3, Count(rnd, How("swipe", sur))) do
		Line("SwipeB", "SwipeG", NV.Swipe, (50 + 110 * rnd()) * u, 0.4 + 0.3 * ss, BOX.SwipeB)
	end
	for _ = 1, math.min(7, Count(rnd, How("deep", sur))) do
		Line("DeepB", "DeepG", NV.Deep, (20 + 150 * rnd() ^ 1.5) * u, 0.6, BOX.DeepB)
	end
	-- (creases: the card bent double once, the first of a card worn through across the most of it; a bend let go)
	local function Reach(px, py, ux, uy, m)
		local t = CuratorOctoFull.Huge
		if ux > 1e-6 then
			t = math.min(t, (W - m - px) / ux)
		elseif ux < -1e-6 then
			t = math.min(t, (px - m) / -ux)
		end
		if uy > 1e-6 then
			t = math.min(t, (H - m - py) / uy)
		elseif uy < -1e-6 then
			t = math.min(t, (py - m) / -uy)
		end
		return t
	end
	local function Crease(fb, fg, v, first, alpha, box)
		local a = rnd() * pi
		local x, y = W * (0.25 + 0.5 * rnd()), H * (0.25 + 0.5 * rnd())
		local dx, dy = cos(a), sin(a)
		local reach = math.min(Reach(x, y, dx, dy, 2 * u), Reach(x, y, -dx, -dy, 2 * u))
		local size = reach * (first and (0.9 + 0.1 * rnd()) or (0.4 + 0.6 * rnd())) * 2 / 0.9
		for _ = 1, 20 do
			if Fits(x, y, size, a, box, 4, "box") then
				-- (a crease: its weight as deep as it is, the first across a card worn through the most)
				if fb == "BendB" then
					Flaw("bend", x, y)
				else
					Flaw("fold", x, y, (v > 6 and 2.2 or 1.1) * (first and 1.3 or 1))
				end
				Put(c, T(), fb .. v, "BLEND", SUB.fold, x, y, size, size, a, nil, alpha, 4)
				Glint(Put(c, T(), fg .. v, "ADD", SUB.fold, x, y, size, size, a, nil, 0.8, 4), a, true)
				return
			end
			size = size * 0.92
		end
	end
	for i = 1, math.min(5, Count(rnd, How("fold", sur))) do
		local heavy = sur <= 2 or (sur == 3 and rnd() < 0.5)
		local v = (heavy and 6 or 0) + Pick(rnd, NV.Fold)
		Crease("FoldB", "FoldG", v, i == 1 and sur <= 2, math.min(1, 0.55 + 0.5 * ss), BOX.FoldB)
	end
	for _ = 1, math.min(2, Count(rnd, How("bend", sur))) do
		Crease("BendB", "BendG", Pick(rnd, NV.Bend), false, 0.6 + 0.4 * ss, BOX.BendB)
	end
	-- (a patch crumpled in a hand)
	for _ = 1, math.min(2, Count(rnd, How("crumple", sur))) do
		local sz = W * (0.35 + 0.3 * rnd())
		local x, y = Inside(sz * 0.47)
		local rot = rnd() * 2 * pi
		local v = Pick(rnd, NV.Crumple)
		Flaw("crumple", x, y)
		Put(c, T(), "CrumpleB" .. v, "BLEND", SUB.fold, x, y, sz, sz, rot, nil, 0.9)
		Glint(Put(c, T(), "CrumpleG" .. v, "ADD", SUB.fold, x, y, sz, sz, rot, nil, 0.7), rot, true)
	end
	-- (dents, fingernail crescents, a pin hole, the line of a rubber band)
	for _ = 1, math.min(6, Count(rnd, How("dent", sur))) do
		local sz = (4 + 8 * rnd()) * u * 2.2
		local x, y = Inside(sz * 0.5)
		local v = Pick(rnd, NV.Dent)
		Flaw("dent", x, y)
		Put(c, T(), "DentB" .. v, "BLEND", SUB.dent, x, y, sz, sz, 0)
		Glint(Put(c, T(), "DentG" .. v, "ADD", SUB.dent, x, y, sz, sz, 0, nil, 0.8), 0, true)
	end
	for _ = 1, math.min(4, Count(rnd, How("nail", sur))) do
		local sz = (10 + 10 * rnd()) * u * 1.6
		local x, y = Inside(sz * 0.5)
		local rot = rnd() * 2 * pi
		local v = Pick(rnd, NV.Nail)
		Flaw("nail", x, y)
		Put(c, T(), "NailB" .. v, "BLEND", SUB.dent, x, y, sz, sz, rot)
		Glint(Put(c, T(), "NailG" .. v, "ADD", SUB.dent, x, y, sz, sz, rot, nil, 0.8), rot, true)
	end
	for _ = 1, math.min(2, Count(rnd, How("pin", sur))) do
		local sz = (16 + 8 * rnd()) * u
		-- (pinned to a wall: near its top, in the middle or near a corner)
		local x = rnd() < 0.6 and W * (0.4 + 0.2 * rnd()) or (rnd() < 0.5 and W * 0.12 or W * 0.88)
		local y = H * (0.06 + 0.06 * rnd())
		if rnd() < 0.2 then
			y = H - y
		end
		local v = Pick(rnd, NV.Pin)
		if In(x, y, sz * 0.5) then
			Flaw("pin", x, y)
			Put(c, T(), "PinB" .. v, "BLEND", SUB.dent, x, y, sz, sz, 0)
			Glint(Put(c, T(), "PinG" .. v, "ADD", SUB.dent, x, y, sz, sz, 0, nil, 0.8), 0, true)
		end
	end
	for _ = 1, math.min(2, Count(rnd, How("band", sur))) do
		local v = Pick(rnd, NV.Band)
		local x, y, sz, rot = W / 2, H * (0.2 + 0.6 * rnd()), W, 0
		if rnd() < 0.45 then
			x, y, sz, rot = W * (0.2 + 0.6 * rnd()), H / 2, H, pi / 2
		end
		Flaw("band", x, y)
		Put(c, T(), "BandB" .. v, "BLEND", SUB.dent, x, y, sz, sz, rot, nil, 0.85, 8)
		Glint(Put(c, T(), "BandG" .. v, "ADD", SUB.dent, x, y, sz, sz, rot, nil, 0.7, 8), rot, true)
	end
	-- (the ring of a mug: a card that has seen a tavern; water; foxing; the dirt of hands at its edges)
	for _ = 1, math.min(3, Count(rnd, How("stain", sur))) do
		local r = (35 + 30 * rnd()) * u * 1.15
		local x, y = Inside(r)
		Flaw("stain", x, y)
		Put(c, T(), "Stain" .. Pick(rnd, NV.Stain), "BLEND", SUB.stain, x, y, r * 2, r * 2, rnd() * 2 * pi)
	end
	for _ = 1, math.min(2, Count(rnd, How("water", sur))) do
		local r = (55 + 55 * rnd()) * u
		local x, y = Inside(r * 0.95)
		Flaw("water", x, y)
		Put(c, T(), "Water" .. Pick(rnd, NV.Water), "BLEND", SUB.water, x, y, r * 2, r * 2, rnd() * 2 * pi)
	end
	for _ = 1, math.min(4, Count(rnd, How("fox", sur))) do
		local r = (8 + 12 * rnd()) * u
		local x, y = Inside(r)
		Flaw("fox", x, y)
		Put(c, T(), "Fox" .. Pick(rnd, NV.Fox), "BLEND", SUB.fox, x, y, r * 2, r * 2, rnd() * 2 * pi)
	end
	for _ = 1, math.min(4, Count(rnd, How("grime", sur))) do
		local r = (30 + 35 * rnd()) * u
		local sd = Pick(rnd, 4)
		local x, y
		if sd <= 2 then
			x, y = r + rnd() * (W - 2 * r), sd == 1 and r or H - r
		else
			x, y = sd == 3 and r or W - r, r + rnd() * (H - 2 * r)
		end
		if not In(x, y, r * 0.95) then
			x, y = Inside(r)
		end
		Flaw("grime", x, y)
		Put(c, T(), "Grime" .. Pick(rnd, NV.Grime), "BLEND", SUB.grime, x, y, r * 2, r * 2, rnd() * 2 * pi)
	end
	-- (the print torn off where something stuck to it; tape, yellowed or pulled off; a price sticker pulled off)
	for _ = 1, math.min(3, Count(rnd, How("loss", sur))) do
		local sz = (18 + 40 * rnd()) * u
		local x, y = Inside(sz * 0.5)
		Flaw("loss", x, y)
		Put(c, T(), "Loss" .. Pick(rnd, NV.Loss), "BLEND", SUB.loss, x, y, sz, sz, rnd() * 2 * pi)
	end
	for _ = 1, Count(rnd, How("tape", sur)) do
		local sz = W * (0.32 + 0.14 * rnd())
		local rot = rnd() < 0.6 and ((Pick(rnd, 2) - 1) * pi / 2 + (rnd() - 0.5) * 0.3) or rnd() * pi
		local v = Pick(rnd, NV.Tape)
		for _ = 1, 8 do
			local x, y = rnd() * W, rnd() * H
			if Fits(x, y, sz, rot, BOX.TapeB, 1, "box") then
				Flaw("tape", x, y)
				Put(c, T(), "TapeB" .. v, "BLEND", SUB.tape, x, y, sz, sz, rot)
				Glint(Put(c, T(), "TapeG" .. v, "ADD", SUB.tape, x, y, sz, sz, rot, nil, 0.8), rot, true)
				break
			end
		end
	end
	for _ = 1, Count(rnd, How("sticker", sur)) do
		local sz = W * (0.2 + 0.08 * rnd())
		local x, y = Inside(sz * 0.42)
		Flaw("sticker", x, y)
		Put(c, T(), "Sticker" .. Pick(rnd, NV.Sticker), "BLEND", SUB.sticker, x, y, sz, sz, (rnd() - 0.5) * 0.6)
	end
	-- (the whole card yellowed; a side faded by the sun)
	if rnd() < How("tanP", sur) then
		Flaw("tan", W / 2, H / 2, 0.6 + 1.4 * How("tanA", sur))
		Put(c, F(), "Tan" .. Pick(rnd, NV.Tan), "BLEND", SUB.tan, W / 2, H / 2, W, H, nil, CORNERS[Pick(rnd, 4)],
			How("tanA", sur) * (0.8 + 0.2 * rnd()))
	end
	if rnd() < How("fadeP", sur) then
		Flaw("fade", W / 2, H / 2)
		Put(c, F(), "Fade" .. Pick(rnd, NV.Fade), "BLEND", SUB.fade, W / 2, H / 2, W, H, nil, CORNERS[Pick(rnd, 4)],
			math.min(0.85, 0.35 + 0.6 * ss))
	end
	-- what says little: specks of ink, a hair on it (the best ones: a dot of the print, now and then)
	for _ = 1, math.min(14, Count(rnd, How("speck", sur))) do
		local v = sur >= 7 and ({ 1, 2, 3, 9, 10 })[Pick(rnd, 5)] or Pick(rnd, 12)
		local big = (v >= 4 and v <= 8) or v >= 11
		local sz = (big and (5 + 9 * rnd()) or (1.6 + 3.2 * rnd())) * u
		local x, y = Inside(sz)
		Flaw("speck", x, y)
		Put(c, T(), "Speck" .. v, "BLEND", SUB.speck, x, y, sz, sz, rnd() * 2 * pi)
	end
	for _ = 1, math.min(2, Count(rnd, How("lint", sur))) do
		local ln = (6 + 22 * rnd()) * u
		local sz = ln / 0.8
		local x, y = Inside(sz * 0.5 + 2 * u)
		Flaw("lint", x, y)
		Put(c, T(), "Lint" .. Pick(rnd, NV.Lint), "BLEND", SUB.lint, x, y, sz, sz, rnd() * 2 * pi)
	end
	-- (what went wrong at the bench of an enchanter: a ring of his solvent, a patch his varnish clouded, a burn of his
	-- runes; each one a flaw of its own, mended in its turn: "kind:x:y:size:turn:variant", x, y, size in thousandths of
	-- the card, its turn in hundredths of a radian)
	local k = 0
	for part in CuratorOctoFull.Gmatch(tostring(wear.a or ""), "[^;]+") do
		local kind, ax, ay, as, ar, av = CuratorOctoFull.Match(part, "^(%a+):(%d+):(%d+):(%d+):(%d+):(%d+)$")
		local file = MISHAP[kind or ""]
		if file and NV[file] then
			k = k + 1
			local x, y = tonumber(ax) / 1000 * W, tonumber(ay) / 1000 * H
			local sz = math.max(4, tonumber(as) / 1000 * W)
			local f = Flaw(kind, x, y)
			f.id, f.mishap = 1000 + k, k
			Put(c, T(), file .. (1 + CuratorOctoFull.Mod((tonumber(av) - 1) , NV[file])), "BLEND", SUB[kind] or SUB.stain, x, y, sz, sz, tonumber(ar) / 100)
		end
	end
	CUR = nil
	HideFrom(c.wearFlip, nf + 1)
	HideFrom(c.wearTurn, nt + 1)
	-- (the card squeezed as it turns over: its pieces with it)
	local cw, ch = c:GetSize()
	if cw and ch and (math.abs(cw - W) > 0.01 or math.abs(ch - H) > 0.01) then
		WU.Fit(c, cw, ch)
	end
	WU.Tick(c, c.tickT or 0)
	if c.held then
		WU.Mesh(c)
	end
end

-- (31 October, the enchanter redone: Restore.lua) The flaws of a wear as they lie on a card of a booster (laid on a card
-- of its own, out of sight, as big as an album shows one: the same flaws at any size): { { id, kind, cat, sev, x, y,
-- gone, mishap }, ... }, in the order they were laid.
local probe
function WU.Flaws(wear)
	if not (wear and type(wear.m) == "table" and ns.CARD_SIZES and ns.CARD_SIZES.big) then
		return {}
	end
	if not probe then
		local W0, H0 = ns.CARD_SIZES.big[1], ns.CARD_SIZES.big[2]
		probe = CreateFrame("Frame", nil, UIParent)
		CuratorOctoFull.SetSize(probe, W0, H0)
		probe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -4000, 4000)
		probe:SetAlpha(0)
		probe.W, probe.H = W0, H0
		probe.wearF = CreateFrame("Frame", nil, probe)
		probe.wearF:SetAllPoints()
		probe.wearFlip, probe.wearTurn = {}, {}
		probe:Hide()
	end
	probe.wearKey = nil
	WU.Set(probe, wear, true)
	local out = {}
	for _, f in ipairs(probe.wearFlaws or {}) do
		out[CuratorOctoFull.Length(out) + 1] = { id = f.id, kind = f.kind, cat = f.cat, sev = f.sev, x = f.x, y = f.y, gone = f.gone, mishap = f.mishap }
	end
	return out
end

-- Each frame: its scratches a little brighter as the light runs across them (held in the hand: as it turns; put down:
-- a light above it on its left, moving a little). Its wear itself never moves, nor comes and goes: only a shimmer.
function WU.Tick(c, t)
	local list = c.wearGlints
	if not (c.wearOn and list) then
		return
	end
	local R = c.held and c.R
	local tx, ty, power
	if R then
		tx, ty = R[3] or 0, -(R[6] or 0)
		local lean = math.min(1, sqrt(tx * tx + ty * ty) * 2.5)
		power = 0.8 + 0.2 * lean
		if lean < 0.05 then
			tx, ty = -0.6, 0.7
		end
	else
		local a = -2.3 + 0.35 * sin(t * 0.37 + (c.phase or 0) * 3)
		tx, ty = cos(a), -sin(a)
		power = 0.85
	end
	local phiL = math.atan2(-ty, tx)
	for _, p in ipairs(list) do
		if p.soft then
			p:SetAlpha(p.base * power)
		else
			local k = abs(sin(p.ang - phiL))
			p:SetAlpha(p.base * (0.55 + 0.45 * k * k * k) * power)
		end
	end
end
