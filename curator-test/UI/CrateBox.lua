local _, ns = "Curator", CuratorOctoFull
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.14.0) The case in 3D, as the openings of CS2 show it (UI/Crate.lua).
-- * Drawn as the display of boosters is (UI/Box3D.lua): each face of the case cut in cells whose corners are moved
--   where the eye sees them (SetVertexOffset), in a true perspective; seen from in front and above, turned a little,
--   each face lit by where it faces, those turned away hidden. Its groups drawn in the order the eye needs: its
--   shadow on the ground, its body, its inside, its lid.
-- * Its shell of navy, its gold, the medallion of Curator on its front and on its lid (Media/CrateFront, CrateSide,
--   CrateTop: make_crate_art.py); a case of the month in its own art (case:SetArt: Media/<art>Front, <art>Side, <art>Top,
--   the same parts in them).
-- * At rest it turns slowly to and fro, floats a little over its shadow, a glint passes over its front now and then;
--   held with the mouse, it turns with it, and comes back by itself.
-- * Opened (SetLid): its lid rises a little on its hinge, at the back, the light of its inside pouring out under it.
-- * A client that cannot move the corners of a texture: the case seen from the front, flat.
-- * (1.14.0, after its first test) Falling before the eye (case.dropLift: so high over its shadow, in widths of its
--   frame; case.dropYaw, case.dropPitch: turned so much more meanwhile; UI/Crate.lua), its shadow fainter the higher it
--   is; a case of no copy left, a ghost (case:SetGhost: grey).
-------------------------------------------------------------------------------
local CB = {}
ns.CrateBox = CB

-- The case, in widths of its frame: its width, the height of its body, of its lid, its depth (the sizes of the faces
-- of its textures); its lid open this far at most.
local CW = 0.62
local BH = CW * 352 / 1024
local LH = CW * 128 / 1024
local CD = CW * 596 / 1024
local OPEN = math.rad(36)
-- (its foot, the seam of its lid, its top; the case set on its middle)
local Y0 = -(BH + LH) / 2
local Y1 = Y0 + BH
local Y2 = Y1 + LH
-- the eye, from the middle of the case; the light of the room (from the upper left, in front)
local EYE = 3.0
local LX, LY, LZ = -0.36, 0.66, 0.66
do
	local n = math.sqrt(LX * LX + LY * LY + LZ * LZ)
	LX, LY, LZ = LX / n, LY / n, LZ / n
end
local AMB, DIF, LIFT = 0.44, 0.64, 1.10
-- At rest: seen from in front and above, turned a little to its left; how far it turns to and fro by itself, how far
-- the mouse turns it.
CB.YAW, CB.PITCH = -0.40, 0.34
CB.SWAY, CB.FLOAT = 0.16, 0.006
local DRAG_MAX = 1.15
-- (the light inside: warm)
local INNER = { 1, 0.84, 0.52 }

local TEX = {
	front = MEDIA .. "CrateFront",
	side = MEDIA .. "CrateSide",
	top = MEDIA .. "CrateTop",
	shadow = MEDIA .. "Shadow",
	glow = MEDIA .. "Glow",
	sheen = MEDIA .. "Sheen",
}

-- The parts of the textures (u0, v0, u1, v1), half a texel in: a part never takes the colour of its neighbour.
local function Part(x0, y0, x1, y1, w, h)
	return { (x0 + 0.5) / w, (y0 + 0.5) / h, (x1 - 0.5) / w, (y1 - 0.5) / h }
end
local UV = {
	front = Part(0, 0, 1024, 352, 1024, 512),
	lidFront = Part(0, 360, 1024, 488, 1024, 512),
	side = Part(0, 0, 512, 304, 512, 1024),
	lidSide = Part(0, 312, 512, 422, 512, 1024),
	mouth = Part(0, 432, 512, 730, 512, 1024),
	top = Part(0, 0, 1024, 596, 1024, 1024),
	under = Part(0, 604, 1024, 1024, 1024, 1024),
}
-- the latches on its front (across it), where they meet its lid
CB.LATCHES = { 292 / 1024, 732 / 1024 }

local function Set(v, x, y, z)
	v[1], v[2], v[3] = x, y, z
end

local function Smooth(a, b, x)
	local t = math.max(0, math.min(1, (x - a) / (b - a)))
	return t * t * (3 - 2 * t)
end

-------------------------------------------------------------------------------
-- Faces and their layers
-------------------------------------------------------------------------------
-- A face: a quad of the model, as it is when the case stands closed (its corner o, its width across u, its height down
-- v); where it is now (p, a, b: moved by the lid, by the float); the group it is drawn in, its layers.
local function NewFace(box, group, key, o, u, v, lid)
	local face = {
		key = key, group = group, layers = {}, lid = lid, on = true,
		o0 = o, u0 = u, v0 = v, o = { 0, 0, 0 }, u = { 0, 0, 0 }, v = { 0, 0, 0 },
	}
	box.faces[CuratorOctoFull.Length(box.faces) + 1] = face
	box.face[key] = face
	return face
end

local function LayerUV(L)
	local uv = L.uv
	local du, dv = uv[3] - uv[1], uv[4] - uv[2]
	local n = 0
	for j = 1, L.rows do
		for i = 1, L.cols do
			n = n + 1
			L.cells[n]:SetTexCoord(uv[1] + du * (i - 1) / L.cols, uv[1] + du * i / L.cols, uv[2] + dv * (j - 1) / L.rows,
				uv[2] + dv * j / L.rows)
		end
	end
end

-- A layer of a face: its texture, the part of the face it covers (rect: fx0, fy0, fx1, fy1, from its corner), its part
-- of the texture, how it is coloured (color: "light", "inner", "glow", "shadow"), its cells.
local function NewLayer(box, face, spec)
	local cols, rows = spec.cols or 1, spec.rows or 1
	if box.flat then
		cols, rows = 1, 1
	end
	local L = {
		tex = spec.tex, rect = spec.rect or { 0, 0, 1, 1 }, uv = spec.uv or { 0, 0, 1, 1 }, cols = cols, rows = rows,
		color = spec.color or "light", alpha = spec.alpha or 1, cells = {}, px = {}, py = {}, rest = {}, shown = false,
		off = spec.off, role = spec.role,
	}
	for _ = 1, rows * cols do
		local t = face.group:CreateTexture(nil, spec.layer or "ARTWORK", nil, spec.sub or 0)
		if spec.tex then
			t:SetTexture(spec.tex)
		end
		if spec.blend then
			t:SetBlendMode(spec.blend)
		end
		if t.SetSnapToPixelGrid then
			t:SetSnapToPixelGrid(false)
			t:SetTexelSnappingBias(0)
		end
		t:Hide()
		L.cells[CuratorOctoFull.Length(L.cells) + 1] = t
	end
	LayerUV(L)
	face.layers[CuratorOctoFull.Length(face.layers) + 1] = L
	return L
end

local function ShowLayer(L, on)
	if L.shown == on then
		return
	end
	L.shown = on
	for _, t in ipairs(L.cells) do
		CuratorOctoFull.SetShown(t, on)
	end
end

-------------------------------------------------------------------------------
-- The model: where each face is, for its lid and its float
-------------------------------------------------------------------------------
local function Place(box)
	local a = OPEN * box.lidK
	local sa, ca = math.sin(a), math.cos(a)
	local lift = (box.lift or 0) + (box.dropLift or 0)
	-- (the hinge of the lid, at the back of its seam: a point of the lid turned about it, the front of the lid rising)
	local hy, hz = Y1, -CD / 2
	for _, face in ipairs(box.faces) do
		local o0, u0, v0 = face.o0, face.u0, face.v0
		if face.lid and a > 0 then
			local y, z = o0[2] - hy, o0[3] - hz
			Set(face.o, o0[1], hy + y * ca + z * sa + lift, hz - y * sa + z * ca)
			Set(face.u, u0[1], u0[2] * ca + u0[3] * sa, -u0[2] * sa + u0[3] * ca)
			Set(face.v, v0[1], v0[2] * ca + v0[3] * sa, -v0[2] * sa + v0[3] * ca)
		else
			Set(face.o, o0[1], o0[2] + (face.ground and 0 or lift), o0[3])
			Set(face.u, u0[1], u0[2], u0[3])
			Set(face.v, v0[1], v0[2], v0[3])
		end
	end
	-- the glint over its front: a band passing across it
	local g = box.glint
	local gl = box.glintLayer
	if g then
		local x0, x1 = g - 0.16, g + 0.16
		local c0, c1 = math.max(0, x0), math.min(1, x1)
		gl.rect[1], gl.rect[3] = c0, c1
		gl.off = c1 <= c0
		if not gl.off then
			local u0 = (c0 - x0) / 0.32
			local u1 = (c1 - x0) / 0.32
			gl.cells[1]:SetTexCoord(u0, u1, 0, 1)
			gl.alpha = math.sin(math.pi * math.max(0, math.min(1, (g + 0.16) / 1.32))) * 0.55
		end
	else
		gl.off = true
	end
end

-------------------------------------------------------------------------------
-- The paint: each face turned, seen or not, lit; its cells moved where the eye sees their corners
-------------------------------------------------------------------------------
local function Matrix(box)
	local cy, sy = math.cos(box.yaw), math.sin(box.yaw)
	local cp, sp = math.cos(box.pitch), math.sin(box.pitch)
	local m = box.m
	m[1], m[2], m[3] = cy, 0, sy
	m[4], m[5], m[6] = sp * sy, cp, -sp * cy
	m[7], m[8], m[9] = -cp * sy, sp, cp * cy
	return m
end

local function LayerColor(box, L, lit)
	local c = L.color
	if c == "glow" then
		local k = box.inner * (box.pulse or 1)
		return INNER[1], INNER[2], INNER[3], L.alpha * math.min(1, k)
	elseif c == "shadow" then
		-- (fainter as it floats, much fainter as it falls from high)
		return 1, 1, 1, L.alpha * (1 - math.min(0.6, (box.lift or 0) * 25)) * (1 - math.min(0.92, (box.dropLift or 0) * 1.6))
	elseif c == "inner" then
		-- (the inside of its lid: in the dark while it is shut, lit by the light inside as it opens)
		local q = lit * (0.30 + 0.85 * box.inner * (box.pulse or 1))
		return math.min(1, q * INNER[1] * 1.05), math.min(1, q * INNER[2] * 1.05), math.min(1, q * INNER[3] * 1.15), L.alpha
	end
	return math.min(1, lit), math.min(1, lit), math.min(1, lit), L.alpha
end

local function PaintFace(box, face, m, rest)
	local W, X0, Y0 = box.W, box.X0, box.Y0
	local o, u, v = face.o, face.u, face.v
	local ox, oy, oz = m[1] * o[1] + m[2] * o[2] + m[3] * o[3], m[4] * o[1] + m[5] * o[2] + m[6] * o[3], m[7] * o[1] + m[8] * o[2] + m[9] * o[3]
	local ux, uy, uz = m[1] * u[1] + m[2] * u[2] + m[3] * u[3], m[4] * u[1] + m[5] * u[2] + m[6] * u[3], m[7] * u[1] + m[8] * u[2] + m[9] * u[3]
	local vx, vy, vz = m[1] * v[1] + m[2] * v[2] + m[3] * v[3], m[4] * v[1] + m[5] * v[2] + m[6] * v[3], m[7] * v[1] + m[8] * v[2] + m[9] * v[3]
	-- its normal (v x u: out of its front), whether the eye sees it, its light
	local nx, ny, nz = vy * uz - vz * uy, vz * ux - vx * uz, vx * uy - vy * ux
	local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
	if nl < 1e-9 then
		nl = 1e-9
	end
	nx, ny, nz = nx / nl, ny / nl, nz / nl
	local cx, cy, cz = ox + (ux + vx) / 2, oy + (uy + vy) / 2, oz + (uz + vz) / 2
	local tx, ty, tz = -cx, -cy, EYE - cz
	local facing = (nx * tx + ny * ty + nz * tz) / math.sqrt(tx * tx + ty * ty + tz * tz)
	local seen = face.on and facing > 0.004 and face.group.shown ~= false and not (box.flat and face.flatOff)
	face.facing = facing
	face.seen = seen
	if not (seen or rest) then
		for _, L in ipairs(face.layers) do
			ShowLayer(L, false)
		end
		return
	end
	local lit = (AMB + DIF * math.max(0, nx * LX + ny * LY + nz * LZ)) * LIFT * (face.light or 1)
	face.lit = lit
	for _, L in ipairs(face.layers) do
		if L.off and not rest then
			ShowLayer(L, false)
		else
			local rc = L.rect
			local fx0, fy0, fx1, fy1 = rc[1], rc[2], rc[3], rc[4]
			local cols, rows = L.cols, L.rows
			local px, py = L.px, L.py
			local n = 0
			for j = 0, rows do
				local fy = fy0 + (fy1 - fy0) * j / rows
				local bx, by, bz = ox + vx * fy, oy + vy * fy, oz + vz * fy
				for i = 0, cols do
					local fx = fx0 + (fx1 - fx0) * i / cols
					local z = bz + uz * fx
					local kk = EYE / (EYE - z)
					n = n + 1
					px[n] = (bx + ux * fx) * kk * W + X0
					py[n] = (by + uy * fx) * kk * W + Y0
				end
			end
			local w1 = cols + 1
			local cells, R = L.cells, L.rest
			local r, g, b, a = LayerColor(box, L, lit)
			for j = 1, rows do
				for i = 1, cols do
					local c = (j - 1) * cols + i
					local ul = (j - 1) * w1 + i
					local ll = ul + w1
					local t = cells[c]
					local x1, y1, x2, y2, x3, y3, x4, y4 = px[ul], py[ul], px[ll], py[ll], px[ul + 1], py[ul + 1], px[ll + 1], py[ll + 1]
					if rest or box.flat then
						-- (where it rests: around its corners, never smaller than a point)
						local l = math.min(x1, x2, x3, x4)
						local rr = math.max(x1, x2, x3, x4, l + 1)
						local tp = math.max(y1, y2, y3, y4)
						local bt = math.min(y1, y2, y3, y4, tp - 1)
						local q = R[c]
						if not q then
							q = {}
							R[c] = q
						end
						q[1], q[2], q[3], q[4] = l, tp, rr, bt
						t:ClearAllPoints()
						t:SetPoint("TOPLEFT", box, "CENTER", l, tp)
						CuratorOctoFull.SetSize(t, rr - l, tp - bt)
					end
					if not box.flat then
						local q = R[c]
						t:SetVertexOffset(1, x1 - q[1], y1 - q[2])
						t:SetVertexOffset(2, x2 - q[1], y2 - q[4])
						t:SetVertexOffset(3, x3 - q[3], y3 - q[2])
						t:SetVertexOffset(4, x4 - q[3], y4 - q[4])
					end
					t:SetVertexColor(r, g, b)
					t:SetAlpha(a)
				end
			end
			ShowLayer(L, seen and not L.off)
		end
	end
end

-- Where a point of a face is seen (fx, fy across and down it): x, y from the middle of the frame, in its points.
local function Point(box, face, fx, fy)
	local m = box.m
	local o, u, v = face.o, face.u, face.v
	local x, y, z = o[1] + u[1] * fx + v[1] * fy, o[2] + u[2] * fx + v[2] * fy, o[3] + u[3] * fx + v[3] * fy
	local rx, ry, rz = m[1] * x + m[2] * y + m[3] * z, m[4] * x + m[5] * y + m[6] * z, m[7] * x + m[8] * y + m[9] * z
	local k = EYE / (EYE - rz)
	return rx * k * box.W + box.X0, ry * k * box.W + box.Y0
end

-- (its groups over it, one above the other, in their order: whatever level its frame is given)
local function Relevel(box)
	local base = box:GetFrameLevel()
	if box.base == base then
		return
	end
	box.base = base
	for i, g in ipairs(box.groups) do
		g:SetFrameLevel(base + i)
	end
end

local function Paint(box, rest)
	Relevel(box)
	Matrix(box)
	Place(box)
	local m = box.m
	for _, face in ipairs(box.faces) do
		PaintFace(box, face, m, rest)
	end
end
CB.Paint = Paint

-------------------------------------------------------------------------------
-- A case
-------------------------------------------------------------------------------
-- CB.New(parent, width): a frame of width x 0.6 width, the case in it. case:SetView(yaw, pitch), case:SetLid(k) (0
-- shut, 1 open as far as it goes), case:SetPulse(k) (the light inside, breathing), case:SetIdle(on),
-- case:SetDraggable(on), case:Glint(), case:Kick(k) (a jolt, dying away), case:LatchScreen(i), case:MouthScreen().
function CB.New(parent, width)
	local W = width
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, W, W * 0.6)
	f.W = W
	f.flat = not ns.Can3D()
	-- (its middle a little up: what is seen of it, shut, as much over the middle of its frame as under it)
	f.X0, f.Y0 = 0, W * 0.0145
	f.yaw, f.pitch = CB.YAW, CB.PITCH
	if f.flat then
		f.yaw, f.pitch = 0, 0.30
	end
	f.lidK, f.inner, f.pulse, f.lift, f.kick = 0, 0, 1, 0, 0
	f.m = {}
	f.faces, f.face = {}, {}
	-- the quality: the cells of a face, fewer on a small case
	local q = (W >= 260) and 1 or 0.5
	local function C(n)
		return math.max(1, math.floor(n * q + 0.5))
	end
	-- its groups, drawn in this order
	f.groups = {}
	local function Group()
		local g = CreateFrame("Frame", nil, f)
		g:SetAllPoints()
		f.groups[CuratorOctoFull.Length(f.groups) + 1] = g
		return g
	end
	local under, body, inside, lid = Group(), Group(), Group(), Group()
	f.under, f.body, f.inside, f.lidG = under, body, inside, lid
	inside.shown = false
	inside:Hide()

	-- its shadow on the ground, darker where it stands
	local sh = NewFace(f, under, "shadow", { -0.50, Y0 - 0.003, -0.31 }, { 1.00, 0, 0 }, { 0, 0, 0.64 })
	sh.ground = true
	NewLayer(f, sh, { tex = TEX.shadow, color = "shadow", alpha = 0.92, layer = "BACKGROUND", sub = 0, cols = C(2) })
	local ct = NewFace(f, under, "contact", { -0.36, Y0 - 0.002, -0.21 }, { 0.72, 0, 0 }, { 0, 0, 0.44 })
	ct.ground = true
	NewLayer(f, ct, { tex = TEX.shadow, color = "shadow", alpha = 1, layer = "BACKGROUND", sub = 1, cols = C(2) })

	-- its body: its front, its two sides
	local fr = NewFace(f, body, "front", { -CW / 2, Y1, CD / 2 }, { CW, 0, 0 }, { 0, -BH, 0 })
	NewLayer(f, fr, { tex = TEX.front, role = "front", uv = UV.front, layer = "ARTWORK", sub = 0, cols = C(6), rows = C(2) })
	f.glintLayer = NewLayer(f, fr, { tex = TEX.sheen, layer = "OVERLAY", sub = 0, blend = "ADD", off = true })
	local sl = NewFace(f, body, "left", { -CW / 2, Y1, -CD / 2 }, { 0, 0, CD }, { 0, -BH, 0 })
	sl.flatOff = true
	NewLayer(f, sl, { tex = TEX.side, role = "side", uv = UV.side, layer = "ARTWORK", sub = 0, cols = C(3), rows = C(2) })
	local sr = NewFace(f, body, "right", { CW / 2, Y1, CD / 2 }, { 0, 0, -CD }, { 0, -BH, 0 })
	sr.flatOff = true
	NewLayer(f, sr, { tex = TEX.side, role = "side", uv = UV.side, layer = "ARTWORK", sub = 0, cols = C(3), rows = C(2) })

	-- its inside, seen once its lid rises: the tops of its walls, its lining, the light in it
	local mo = NewFace(f, inside, "mouth", { -CW / 2, Y1, -CD / 2 }, { CW, 0, 0 }, { 0, 0, CD })
	mo.flatOff = true
	NewLayer(f, mo, { tex = TEX.side, role = "side", uv = UV.mouth, color = "inner", layer = "ARTWORK", sub = 0, cols = C(4), rows = C(2) })
	NewLayer(f, mo, { tex = TEX.glow, color = "glow", alpha = 0.9, layer = "OVERLAY", sub = 0, blend = "ADD",
		rect = { -0.1, -0.25, 1.1, 1.25 }, cols = C(2), rows = C(2) })

	-- its lid: its top, its front, its sides, its inside
	local lt = NewFace(f, lid, "lidTop", { -CW / 2, Y2, -CD / 2 }, { CW, 0, 0 }, { 0, 0, CD }, true)
	NewLayer(f, lt, { tex = TEX.top, role = "top", uv = UV.top, layer = "ARTWORK", sub = 0, cols = C(6), rows = C(3) })
	local lf = NewFace(f, lid, "lidFront", { -CW / 2, Y2, CD / 2 }, { CW, 0, 0 }, { 0, -LH, 0 }, true)
	NewLayer(f, lf, { tex = TEX.front, role = "front", uv = UV.lidFront, layer = "ARTWORK", sub = 1, cols = C(6), rows = 1 })
	local ll = NewFace(f, lid, "lidLeft", { -CW / 2, Y2, -CD / 2 }, { 0, 0, CD }, { 0, -LH, 0 }, true)
	ll.flatOff = true
	NewLayer(f, ll, { tex = TEX.side, role = "side", uv = UV.lidSide, layer = "ARTWORK", sub = 1, cols = C(3), rows = 1 })
	local lr = NewFace(f, lid, "lidRight", { CW / 2, Y2, CD / 2 }, { 0, 0, -CD }, { 0, -LH, 0 }, true)
	lr.flatOff = true
	NewLayer(f, lr, { tex = TEX.side, role = "side", uv = UV.lidSide, layer = "ARTWORK", sub = 1, cols = C(3), rows = 1 })
	local lu = NewFace(f, lid, "lidUnder", { -CW / 2, Y1, CD / 2 }, { CW, 0, 0 }, { 0, 0, -CD }, true)
	lu.flatOff = true
	NewLayer(f, lu, { tex = TEX.top, role = "top", uv = UV.under, color = "inner", layer = "ARTWORK", sub = 2, cols = C(6), rows = C(2) })

	for k, fn in pairs(CB.methods) do
		f[k] = fn
	end
	-- where each cell rests: where the case at rest puts it
	Paint(f, true)
	Paint(f)
	return f
end

-------------------------------------------------------------------------------
-- What a case does
-------------------------------------------------------------------------------
local M = {}
CB.methods = M

function M:Paint()
	Paint(self)
end

-- (1.14.0) Its art: the textures of a case of the month (art: the start of their names, Media/<art>Front, <art>Side,
-- <art>Top), or those of the case of the first test (nil).
local ROLE = { front = "Front", side = "Side", top = "Top" }
function M:SetArt(art)
	if self.art == art then
		return
	end
	self.art = art
	for _, face in ipairs(self.faces) do
		for _, L in ipairs(face.layers) do
			if L.role then
				-- (1.14.0: its words in the language of the game, Core.lua: ns.CaseTexture)
				L.tex = art and (MEDIA .. ns.CaseTexture(art .. ROLE[L.role])) or TEX[L.role]
				for _, t in ipairs(L.cells) do
					t:SetTexture(L.tex)
				end
			end
		end
	end
	Paint(self)
end

-- Turned (yaw: its turn, radians; pitch: seen from above that much).
function M:SetView(yaw, pitch)
	if self.flat then
		return
	end
	self.yaw, self.pitch = yaw or CB.YAW, pitch or CB.PITCH
	Paint(self)
end

function M:GetView()
	return self.yaw, self.pitch
end

-- Its lid (k: 0 shut, 1 open as far as it goes; a little past it as it springs open); the light inside follows it.
function M:SetLid(k)
	k = math.max(0, math.min(1.15, k or 0))
	-- (seen flat, from the front: it stays shut)
	if self.flat then
		k = 0
	end
	self.lidK = k
	self.inner = Smooth(0.02, 0.6, k)
	local open = k > 0 and not self.flat
	self.inside.shown = open
	CuratorOctoFull.SetShown(self.inside, open)
	Paint(self)
end

function M:GetLid()
	return self.lidK
end

-- The light inside breathing (1: as the lid gives it).
function M:SetPulse(k)
	self.pulse = k or 1
end

-- A jolt (k: its strength, 1 the strongest), dying away by itself while it is idle.
function M:Kick(k)
	self.kick = math.max(self.kick or 0, k or 1)
end

-- Where the eye sees its latches (i: 1 the left, 2 the right): where they meet the lid, x and y from the middle of
-- the frame; and the middle of its mouth.
function M:LatchScreen(i)
	Matrix(self)
	Place(self)
	return Point(self, self.face.front, CB.LATCHES[i or 1], 0.02)
end

function M:MouthScreen()
	Matrix(self)
	Place(self)
	return Point(self, self.face.front, 0.5, 0)
end

-- A glint passing over its front, now (one sweep).
function M:Glint(dur)
	dur = dur or 1.2
	if self.glintRun or self.flat then
		return
	end
	self.glintRun = true
	ns.Tween(dur, function(_, raw)
		self.glint = -0.16 + 1.32 * raw
		Paint(self)
	end, function()
		self.glintRun = nil
		self.glint = nil
		Paint(self)
	end, ns.Ease.linear, self)
end

-- It turns slowly by itself (on: true), floats over its shadow, a glint over it now and then.
local function Idle(self, elapsed)
	self.t = (self.t or 0) + elapsed
	local t = self.t
	local yaw = (self.baseYaw or CB.YAW) + math.sin(t * 0.42) * CB.SWAY
	local pitch = (self.basePitch or CB.PITCH) + math.sin(t * 0.29) * 0.025
	if self.dragging then
		local x, y = GetCursorPosition()
		local s = self:GetEffectiveScale()
		self.dragOff = math.max(-DRAG_MAX, math.min(DRAG_MAX, self.dragYaw0 + (x / s - self.dragX0) * 0.011))
		if y and self.dragY0 then
			self.tiltOff = math.max(-0.22, math.min(0.30, (self.dragTilt0 or 0) - (y / s - self.dragY0) * 0.005))
		end
	else
		-- (let go: it comes back to its turn by itself)
		for _, key in ipairs({ "dragOff", "tiltOff" }) do
			local v = self[key]
			if v and v ~= 0 then
				v = v * math.max(0, 1 - elapsed * 2.0)
				self[key] = math.abs(v) < 0.002 and 0 or v
			end
		end
	end
	-- (a jolt: it shakes and jumps, less and less)
	local kick = self.kick or 0
	if kick > 0 then
		kick = math.max(0, kick - elapsed * 2.4)
		self.kick = kick
	end
	yaw = yaw + (self.dragOff or 0) + kick * 0.035 * math.sin(t * 57) + (self.dropYaw or 0)
	pitch = pitch + (self.tiltOff or 0) + kick * 0.02 * math.sin(t * 43) + (self.dropPitch or 0)
	self.yaw, self.pitch = yaw, pitch
	self.lift = math.sin(t * 1.15) * CB.FLOAT + kick * 0.018 * math.abs(math.sin(t * 31))
	if t >= (self.nextGlint or 1.2) then
		self.nextGlint = t + 5.5
		self:Glint(1.3)
	end
	-- (thirty paints a second are enough for a case turning slowly; every frame while it is held or jolted)
	self.since = (self.since or 0) + elapsed
	if not self.glintRun and (self.dragging or kick > 0 or self.moving or self.since >= 0.033) then
		self.since = 0
		Paint(self)
	end
end

function M:SetIdle(on)
	if self.flat then
		return
	end
	self.idle = on and true or false
	CuratorOctoFull.SetScript(self, "OnUpdate", on and Idle or nil)
end

-- (1.14.0, after its first test) Grey, a ghost of itself (on), or in its colours again.
function M:SetGhost(on)
	on = on and true or false
	if self.ghost == on then
		return
	end
	self.ghost = on
	for _, face in ipairs(self.faces) do
		for _, L in ipairs(face.layers) do
			if L.role then
				for _, c in ipairs(L.cells) do
					c:SetDesaturated(on)
				end
			end
		end
	end
end

-- Turned with the mouse, held down over it.
function M:SetDraggable(on)
	if self.flat then
		return
	end
	self:EnableMouse(on and true or false)
	if not on then
		self.dragging = false
		CuratorOctoFull.SetScript(self, "OnMouseDown", nil)
		CuratorOctoFull.SetScript(self, "OnMouseUp", nil)
		return
	end
	CuratorOctoFull.SetScript(self, "OnMouseDown", function(b)
		local x, y = GetCursorPosition()
		local s = b:GetEffectiveScale()
		b.dragging = true
		b.dragX0, b.dragY0 = x / s, y and y / s or nil
		b.dragYaw0, b.dragTilt0 = b.dragOff or 0, b.tiltOff or 0
	end)
	CuratorOctoFull.SetScript(self, "OnMouseUp", function(b)
		b.dragging = false
	end)
end
