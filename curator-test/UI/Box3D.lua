local _, ns = "Curator", CuratorOctoFull
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.13.0, after its first test) A box in 3D on the screen: the displays of boosters (UI/Displays.lua).
-- * Drawn as the cards held in the hand are (UI/Card.lua): each face of the box is cut in cells whose corners are moved
--   where the eye sees them (SetVertexOffset), in a true perspective; the box turns (its yaw), is seen from above (its
--   pitch), each face lit by where it faces, those turned away hidden. Its faces are drawn in groups, one frame each, in
--   the order the eye needs from in front and above: what is behind it, its inside and its boosters, its sides, its
--   front, its lid, its case.
-- * Its effigy, of its album: the art of its album in the window of its front, its frame of gold, the plaque of its
--   name, the medallion of its emblem, the badge of its 16 boosters, the jewel of its kind (the wings of a raid, the
--   laurels of a dungeon, the sash of a limited edition); its lid, its sides in the colour of its album, sealed.
-- * Opened (SetLid): its seals tear, its lid swings up and back on its hinge, its flap unfolds, the inside of its lid
--   stands behind its boosters as the art of a poster; its boosters stand out of it, the light of its album rises from
--   it. Each booster can rise out of it (SetPackRise), where the eye sees it said (PackScreen) for what flies it on.
-- * In its case of acrylic (SetCased), its glass round it.
-- * A client that cannot move the corners of a texture: the box seen from the front, flat, its faces as they fall.
-------------------------------------------------------------------------------
local B3 = {}
ns.Box3D = B3

-- The box, in widths of its frame: its width, its height, its depth; its cardboard; its lid (its flap tucked behind its
-- front when it is closed), open as far as it leans back.
local BW, BH, BD = 0.80, 0.30, 0.28
local T = 0.010
local LD = BD - T
local LIP = 0.05
local OPEN = math.rad(104)
-- the eye, from the middle of the box; the light of the room (from the upper left, in front)
local EYE = 3.2
local LX, LY, LZ = -0.30, 0.62, 0.72
do
	local n = math.sqrt(LX * LX + LY * LY + LZ * LZ)
	LX, LY, LZ = LX / n, LY / n, LZ / n
end
local AMB, DIF, LIFT = 0.46, 0.62, 1.12
-- its boosters: two rows of eight (1 to 8 at the back, half a step aside; 9 to 16 in front), leaning back a little;
-- how much of them stands out of it when it is open (a part of their height: the back row higher)
local PW = 0.0828
local PH = PW * 2
local GAP = 0.007
local LEAN = math.rad(6)
local ROW_Z = { -0.055, 0.045 }
local ROW_OUT = { 0.62, 0.40 }
-- its two seals, on the edge of its lid
local SEAL_R = 0.032
local SEAL_X = { -0.27, 0.27 }
-- the case round it
local CASE_M, CASE_TOP = 0.026, 0.045

-- At rest: seen from in front and above, turned a little.
B3.YAW, B3.PITCH = -0.30, 0.36
-- (leaned with the mouse, a display inspected: from this far under its pitch to this far over it)
local TILT_LO, TILT_HI = -0.2, 0.3
B3.SIZE = 16

local TEX = {
	front = MEDIA .. "DisplayBoxFront",
	lid = MEDIA .. "DisplayBoxLid",
	header = MEDIA .. "DisplayBoxHeader",
	side = MEDIA .. "DisplayBoxSide",
	glass = MEDIA .. "DisplayBoxGlass",
	beam = MEDIA .. "DisplayBoxBeam",
	shadow = MEDIA .. "Shadow",
	glow = MEDIA .. "Glow",
}

-- The parts of the textures (u0, v0, u1, v1), half a texel in: a part never takes the colour of its neighbour.
local function Part(x0, y0, x1, y1, w, h)
	return { (x0 + 0.5) / w, (y0 + 0.5) / h, (x1 - 0.5) / w, (y1 - 0.5) / h }
end
local UV = {
	frontGold = Part(0, 0, 1024, 384, 1024, 1024),
	frontTint = Part(0, 384, 1024, 768, 1024, 1024),
	sealTop = Part(0, 768, 128, 832, 1024, 1024),
	sealBottom = Part(0, 832, 128, 896, 1024, 1024),
	sash = Part(128, 768, 384, 896, 1024, 1024),
	wings = Part(384, 768, 640, 896, 1024, 1024),
	laurels = Part(640, 768, 896, 896, 1024, 1024),
	glint = Part(896, 768, 1024, 896, 1024, 1024),
	lidGold = Part(0, 0, 1024, 358, 1024, 1024),
	lidTint = Part(0, 360, 1024, 718, 1024, 1024),
	lipGold = Part(0, 720, 1024, 784, 1024, 1024),
	lipTint = Part(0, 788, 1024, 852, 1024, 1024),
	lipInner = Part(0, 856, 1024, 920, 1024, 1024),
	plaque = Part(0, 924, 460, 986, 1024, 1024),
	headerGold = Part(0, 0, 1024, 358, 1024, 512),
	sideGold = Part(0, 0, 256, 256, 512, 512),
	sideTint = Part(256, 0, 512, 256, 512, 512),
	innerSide = Part(0, 256, 256, 512, 512, 512),
	innerBack = Part(256, 256, 512, 352, 512, 512),
	rim = Part(256, 360, 320, 376, 512, 512),
	floor = Part(256, 384, 384, 448, 512, 512),
	-- (the art of an album: its studio, the middle of it, as wide as the window of the front)
	art = { 0, 0.20, 1, 0.806 },
	header = { 0, 0.18, 1, 0.82 },
}
-- the jewel of each kind of display
local GEM = { zone = "Gem3", dungeon = "Gem4", raid = "Gem6", event = "Gem5" }
-- (the gold of an emblem, of the words)
local EMBLEM = { 1, 0.86, 0.52 }

-- The colour of an album on its box: its tint, brightened, a little of its light in it.
local function Tint(s)
	local t = (s and s.tint) or { 0.30, 0.22, 0.12 }
	local g = (s and s.glow) or { 1, 0.8, 0.4 }
	return { math.min(1, t[1] * 1.9 + g[1] * 0.14), math.min(1, t[2] * 1.9 + g[2] * 0.14), math.min(1, t[3] * 1.9 + g[3] * 0.14) }
end
B3.Tint = Tint

local function Smooth(a, b, x)
	local t = math.max(0, math.min(1, (x - a) / (b - a)))
	return t * t * (3 - 2 * t)
end

local function Set(v, x, y, z)
	v[1], v[2], v[3] = x, y, z
end

-------------------------------------------------------------------------------
-- Faces and their layers
-------------------------------------------------------------------------------
-- A face: a quad of the model (its corner o, its width across u, its height down v: three vectors, set before each
-- paint), the group it is drawn in, its layers.
local function NewFace(box, group, key)
	local face = { key = key, group = group, layers = {}, o = { 0, 0, 0 }, u = { 1, 0, 0 }, v = { 0, -1, 0 }, on = true }
	box.faces[CuratorOctoFull.Length(box.faces) + 1] = face
	box.face[key] = face
	return face
end

-- (the parts of the texture of the cells of a layer, after its part)
local function LayerUV(L)
	local uv = L.uv
	local du, dv = uv[3] - uv[1], uv[4] - uv[2]
	local n = 0
	for j = 1, L.rows do
		for i = 1, L.cols do
			n = n + 1
			local u0, u1 = uv[1] + du * (i - 1) / L.cols, uv[1] + du * i / L.cols
			local v0, v1 = uv[2] + dv * (j - 1) / L.rows, uv[2] + dv * j / L.rows
			if L.mirror then
				u0, u1 = uv[1] + du * (1 - (i - 1) / L.cols), uv[1] + du * (1 - i / L.cols)
			end
			L.cells[n]:SetTexCoord(u0, u1, v0, v1)
		end
	end
end

-- A layer of a face: its texture, the part of the face it covers (rect: fx0, fy0, fx1, fy1, from its corner), its part
-- of the texture, how it is coloured (color: "light", "tint", "emblem", "inner", "glow", "shadow", "glass"), its cells.
local function NewLayer(box, face, spec)
	local cols, rows = spec.cols or 1, spec.rows or 1
	if box.flat then
		cols, rows = 1, 1
	end
	local L = {
		tex = spec.tex, rect = spec.rect or { 0, 0, 1, 1 }, uv = spec.uv or { 0, 0, 1, 1 }, cols = cols, rows = rows,
		color = spec.color or "light", alpha = spec.alpha or 1, k = spec.k or 1, mirror = spec.mirror, cells = {},
		px = {}, py = {}, rest = {}, shown = false, off = false,
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
	box.layers[CuratorOctoFull.Length(box.layers) + 1] = L
	return L
end

local function SetLayerTexture(L, tex)
	if L.tex == tex then
		return
	end
	L.tex = tex
	for _, t in ipairs(L.cells) do
		t:SetTexture(tex)
	end
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
-- The model: where each face is, for the turn of the box, its lid, its boosters
-------------------------------------------------------------------------------
-- (the lid open by k: its angle, the unfolding of its flap, its axes: a along it from its hinge, n out of it)
local function LidAxes(k)
	local a = OPEN * k
	local sa, ca = math.sin(a), math.cos(a)
	return a, sa, ca
end

local function Place(box)
	local f = box.face
	local k = box.lidK
	local a, sa, ca = LidAxes(k)
	-- the hinge, at the back of the top; along the lid (0, sa, ca), out of it (0, ca, -sa)
	local hy, hz = BH / 2, -BD / 2
	local e = 0.0015
	local lo = f.lidOut
	Set(lo.o, -BW / 2, hy + ca * e, hz - sa * e)
	Set(lo.u, BW, 0, 0)
	Set(lo.v, 0, sa * LD, ca * LD)
	local li = f.lidIn
	Set(li.o, -BW / 2, hy + sa * LD - ca * e, hz + ca * LD + sa * e)
	Set(li.u, BW, 0, 0)
	Set(li.v, 0, -sa * LD, -ca * LD)
	-- the flap: hanging from the edge of the lid (behind the front), unfolding to lengthen it as it opens
	local u = Smooth(0.15, 0.95, k)
	local b = u * math.pi / 2
	local dy, dz = -ca * math.cos(b) + sa * math.sin(b), sa * math.cos(b) + ca * math.sin(b)
	local fy, fz = hy + sa * LD, hz + ca * LD
	local fo = f.lipOut
	Set(fo.o, -BW / 2, fy, fz)
	Set(fo.u, BW, 0, 0)
	Set(fo.v, 0, dy * LIP, dz * LIP)
	local fi = f.lipIn
	Set(fi.o, -BW / 2, fy + dy * LIP, fz + dz * LIP)
	Set(fi.u, BW, 0, 0)
	Set(fi.v, 0, -dy * LIP, -dz * LIP)
	-- (inside the box, behind its front, while the lid is low)
	local out = a > math.rad(12)
	fo.on, fi.on = out, out
	-- its seals: half on the edge of the lid (going with it), half on the front
	local tear = box.tear
	for i, sx in ipairs(SEAL_X) do
		local st, sb = f["sealTop" .. i], f["sealBottom" .. i]
		local r = SEAL_R
		local d0 = LD - r + T
		Set(st.o, sx - r, hy + sa * d0 + ca * e * 2, hz + ca * d0 - sa * e * 2)
		Set(st.u, 2 * r, 0, 0)
		Set(st.v, 0, sa * r, ca * r)
		local drop = tear * 0.05
		Set(sb.o, sx - r + tear * 0.01 * (i == 1 and -1 or 1), BH / 2 - drop, BD / 2 + e * 2)
		Set(sb.u, 2 * r, 0, -tear * 0.02)
		Set(sb.v, tear * 0.012 * (i == 1 and 1 or -1), -r, 0)
		st.on, sb.on = tear < 1, tear < 1
		st.layers[1].alpha, sb.layers[1].alpha = 1 - tear, 1 - tear
	end
	-- its boosters: seated in it while it is closed, standing out of it once it is open, risen as each rises
	local pop = Smooth(0.6, 1, k)
	local sl, cl = math.sin(LEAN), math.cos(LEAN)
	for i, p in ipairs(box.packs) do
		local face = p.face
		local seated = BH / 2 - PH * cl - 0.006
		local popped = BH / 2 - (1 - p.out) * PH
		local y0 = seated + (popped - seated) * pop + p.rise
		Set(face.o, p.x - PW / 2, y0 + PH * cl, p.z - PH * sl)
		Set(face.u, PW, 0, 0)
		Set(face.v, 0, -PH * cl, PH * sl)
		face.on = p.shown
		box.packY[i] = y0
	end
	-- the glint over its front: a band passing across it
	local g = box.glint
	if g then
		local gl = f.front.glintLayer
		local x0, x1 = g - 0.13, g + 0.13
		local c0, c1 = math.max(0, x0), math.min(1, x1)
		gl.rect[1], gl.rect[3] = c0, c1
		gl.off = c1 <= c0
		if not gl.off then
			local uv = UV.glint
			local du = uv[3] - uv[1]
			local u0 = uv[1] + du * (c0 - x0) / 0.26
			local u1 = uv[1] + du * (c1 - x0) / 0.26
			gl.cells[1]:SetTexCoord(u0, u1, uv[2], uv[4])
			gl.alpha = math.sin(math.pi * math.max(0, math.min(1, (g + 0.15) / 1.3))) * 0.7
		end
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

-- (the colour of a layer, by its kind and the light on its face)
local function LayerColor(box, L, lit, face)
	local c = L.color
	local r, g, b, a = lit, lit, lit, L.alpha
	if c == "tint" then
		local t = box.tint
		r, g, b = t[1] * lit, t[2] * lit, t[3] * lit
	elseif c == "emblem" then
		r, g, b = EMBLEM[1] * lit, EMBLEM[2] * lit, EMBLEM[3] * lit
	elseif c == "inner" then
		local t = box.tint
		local q = (0.34 + 0.66 * box.inner) * lit
		r, g, b = (0.06 + t[1] * 0.62) * q, (0.05 + t[2] * 0.62) * q, (0.05 + t[3] * 0.62) * q
	elseif c == "glow" then
		local gl = box.glow
		r, g, b = gl[1], gl[2], gl[3]
		a = L.alpha * box.inner
	elseif c == "shadow" then
		r, g, b = 1, 1, 1
	elseif c == "glass" then
		r, g, b = 1, 1, 1
	end
	if box.dim and c ~= "glow" and c ~= "glass" then
		r, g, b = r * 0.8, g * 0.8, b * 0.8
	end
	return math.min(1, r), math.min(1, g), math.min(1, b), a
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
			local r, g, b, a = LayerColor(box, L, lit, face)
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

-- Where a point of a face is seen (fx, fy across and down it): x, y from the middle of the frame, in its points; and how
-- much nearer it is.
local function Point(box, face, fx, fy)
	local m = box.m
	local o, u, v = face.o, face.u, face.v
	local x, y, z = o[1] + u[1] * fx + v[1] * fy, o[2] + u[2] * fx + v[2] * fy, o[3] + u[3] * fx + v[3] * fy
	local rx, ry, rz = m[1] * x + m[2] * y + m[3] * z, m[4] * x + m[5] * y + m[6] * z, m[7] * x + m[8] * y + m[9] * z
	local k = EYE / (EYE - rz)
	return rx * k * box.W + box.X0, ry * k * box.W + box.Y0, k
end

-- The words that follow a face: where it puts them, as large as it is seen there, turned with it, faded when it is seen
-- from too far aside.
local function PaintWords(box, w)
	local face = w.face
	local fs = w.fs
	if not (face.seen and w.on ~= false and (w.text or "") ~= "") then
		fs:Hide()
		return
	end
	local x, y = Point(box, face, w.fx, w.fy)
	local xa, ya = Point(box, face, w.fx - 0.05, w.fy)
	local xb, yb = Point(box, face, w.fx + 0.05, w.fy)
	local span = math.sqrt((xb - xa) ^ 2 + (yb - ya) ^ 2)
	local u = face.u
	local nominal = 0.1 * math.sqrt(u[1] * u[1] + u[2] * u[2] + u[3] * u[3]) * box.W
	local s = math.max(0.2, span / math.max(1e-6, nominal))
	fs:ClearAllPoints()
	fs:SetPoint("CENTER", box, "CENTER", x, y)
	if fs.SetTextScale then
		fs:SetTextScale(s)
	elseif math.abs((w.scale or 1) - s) > 0.04 then
		ns.SetFont(fs, math.max(5, w.size * s))
	end
	w.scale = s
	if fs.SetRotation then
		CuratorOctoFull.SetRotation(fs, math.atan2(yb - ya, xb - xa))
	end
	local fade = math.max(0, math.min(1, (face.facing - 0.18) / 0.3))
	fs:SetAlpha(fade * (w.alpha or 1))
	fs:Show()
end

local function Relevel(box)
	local base = box:GetFrameLevel()
	if box.base == base then
		return
	end
	box.base = base
	for i, g in ipairs(box.groups) do
		g:SetFrameLevel(base + i)
	end
	box.lid:SetFrameLevel(base + (box.lidK >= 0.5 and 2 or 6))
end

local function Paint(box, rest)
	box.dirty = nil
	Relevel(box)
	Matrix(box)
	Place(box)
	-- (the lid: over the box while it is low, behind its boosters once it is up)
	local behind = box.lidK >= 0.5
	if behind ~= box.lidBehind then
		box.lidBehind = behind
		box.lid:SetFrameLevel(box.base + (behind and 2 or 6))
	end
	local m = box.m
	for _, face in ipairs(box.faces) do
		PaintFace(box, face, m, rest)
	end
	for _, w in ipairs(box.words) do
		PaintWords(box, w)
	end
end
B3.Paint = Paint

-- (several changes in a frame, one paint: at the next frame)
local dirty = {}
local painter = CreateFrame("Frame")
painter:Hide()
CuratorOctoFull.SetScript(painter, "OnUpdate", function(self)
	for box in pairs(dirty) do
		dirty[box] = nil
		if box.dirty then
			Paint(box)
		end
	end
	self:Hide()
end)
local function Later(box)
	box.dirty = true
	dirty[box] = true
	painter:Show()
end

-------------------------------------------------------------------------------
-- A box
-------------------------------------------------------------------------------
-- B3.New(parent, width): a frame of width x width/2, the box in it. box:SetSeries(s), box:SetView(yaw, pitch),
-- box:SetLid(k) (0 closed, 1 open), box:SetTear(t) (its seals: 0 whole, 1 gone), box:SetCased(on), box:SetDim(on),
-- box:SetPackRise(i, d), box:SetPackShown(i, on), box:ResetPacks(), box:PackScreen(i), box:SealScreen(i),
-- box:Glint(), box:SetIdle(on), box:SetDraggable(on).
function B3.New(parent, width)
	local W = width
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, W, W / 2)
	f.W = W
	f.flat = not ns.Can3D()
	f.X0, f.Y0 = 0, -W * 0.005
	f.yaw, f.pitch = B3.YAW, B3.PITCH
	if f.flat then
		f.yaw, f.pitch = 0, 0.32
	end
	f.lidK, f.tear, f.inner, f.glintAt = 0, 0, 0, nil
	f.m = {}
	f.faces, f.face, f.layers, f.words, f.packs, f.packY = {}, {}, {}, {}, {}, {}
	f.tint, f.glow = Tint(nil), { 1, 0.8, 0.4 }
	-- the quality: the cells of a face, fewer on a small box
	local q = (W >= 200) and 1 or ((W >= 110) and 0.5 or 0.34)
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
	local under, behindG, inside, sides, front, topG, case = Group(), Group(), Group(), Group(), Group(), Group(), Group()
	f.under, f.inside, f.sides, f.frontG, f.caseG = under, inside, sides, front, case
	inside.shown = false
	inside:Hide()
	-- (the lid has a frame of its own: its place among the groups follows its angle)
	local lid = CreateFrame("Frame", nil, f)
	lid:SetAllPoints()
	f.lid = lid
	f.behindG, f.topG = behindG, topG

	-- under it: the light of its album, its shadow on the ground
	f.halo = under:CreateTexture(nil, "BACKGROUND", nil, -8)
	f.halo:SetTexture(TEX.glow)
	f.halo:SetBlendMode("ADD")
	f.halo:SetPoint("CENTER", 0, W * 0.02)
	CuratorOctoFull.SetSize(f.halo, W * 1.25, W * 0.8)
	f.halo:SetAlpha(0.2)
	local sh = NewFace(f, under, "shadow")
	Set(sh.o, -0.64, -BH / 2 - 0.003, -0.33)
	Set(sh.u, 1.28, 0, 0)
	Set(sh.v, 0, 0, 0.68)
	NewLayer(f, sh, { tex = TEX.shadow, color = "shadow", alpha = 0.95, layer = "BACKGROUND", sub = 0, cols = C(2), rows = 1 })
	-- (and where it touches the ground, darker)
	local sh2 = NewFace(f, under, "contact")
	Set(sh2.o, -0.47, -BH / 2 - 0.002, -0.19)
	Set(sh2.u, 0.94, 0, 0)
	Set(sh2.v, 0, 0, 0.40)
	NewLayer(f, sh2, { tex = TEX.shadow, color = "shadow", alpha = 1, layer = "BACKGROUND", sub = 1, cols = C(2), rows = 1 })

	-- the case: its far walls, seen through it (under the box)
	local cw, cd = BW / 2 + CASE_M, BD / 2 + CASE_M
	local cb, ct = -BH / 2 - 0.004, BH / 2 + CASE_TOP
	local function CaseFace(group, key, o, u, v, layer, alpha)
		local cf = NewFace(f, group, key)
		Set(cf.o, o[1], o[2], o[3])
		Set(cf.u, u[1], u[2], u[3])
		Set(cf.v, v[1], v[2], v[3])
		NewLayer(f, cf, { tex = TEX.glass, color = "glass", alpha = alpha, layer = layer, sub = 0, cols = C(2), rows = 1 })
		cf.case = true
		cf.on = false
		return cf
	end
	-- (each wall twice: from outside, over the box; from inside, under it)
	local walls = {
		{ "Front", { -cw, ct, cd }, { 2 * cw, 0, 0 }, { 0, cb - ct, 0 } },
		{ "Back", { cw, ct, -cd }, { -2 * cw, 0, 0 }, { 0, cb - ct, 0 } },
		{ "Left", { -cw, ct, -cd }, { 0, 0, 2 * cd }, { 0, cb - ct, 0 } },
		{ "Right", { cw, ct, cd }, { 0, 0, -2 * cd }, { 0, cb - ct, 0 } },
		{ "Top", { -cw, ct, -cd }, { 2 * cw, 0, 0 }, { 0, 0, 2 * cd } },
	}
	for _, wl in ipairs(walls) do
		local o, u, v = wl[2], wl[3], wl[4]
		CaseFace(case, "case" .. wl[1], o, u, v, "OVERLAY", 0.9)
		-- (from inside: the same wall turned round: its corner at the other end, across the other way)
		local cin = CaseFace(under, "caseIn" .. wl[1], { o[1] + u[1], o[2] + u[2], o[3] + u[3] }, { -u[1], -u[2], -u[3] }, v, "BORDER", 0.55)
		cin.flatOff = wl[1] == "Left" or wl[1] == "Right"
		f.face["case" .. wl[1]].flatOff = wl[1] == "Left" or wl[1] == "Right"
	end

	-- its inside: its walls, its floor, the light in it, the edges of its cardboard
	local ib = NewFace(f, inside, "innerBack")
	Set(ib.o, -BW / 2 + T, BH / 2, -BD / 2 + T)
	Set(ib.u, BW - 2 * T, 0, 0)
	Set(ib.v, 0, -BH, 0)
	NewLayer(f, ib, { tex = TEX.side, uv = UV.innerBack, color = "inner", layer = "BACKGROUND", sub = 0, cols = C(4), rows = C(2) })
	ib.innerLight = NewLayer(f, ib, { tex = TEX.glow, color = "glow", alpha = 0.55, layer = "BORDER", sub = 0, blend = "ADD",
		rect = { 0.1, -0.2, 0.9, 1.0 }, cols = C(2), rows = 1 })
	local il = NewFace(f, inside, "innerLeft")
	il.flatOff = true
	Set(il.o, -BW / 2 + T, BH / 2, BD / 2 - T)
	Set(il.u, 0, 0, -(BD - 2 * T))
	Set(il.v, 0, -BH, 0)
	NewLayer(f, il, { tex = TEX.side, uv = UV.innerSide, color = "inner", layer = "BACKGROUND", sub = 0, cols = C(2), rows = C(2) })
	local ir = NewFace(f, inside, "innerRight")
	ir.flatOff = true
	Set(ir.o, BW / 2 - T, BH / 2, -BD / 2 + T)
	Set(ir.u, 0, 0, BD - 2 * T)
	Set(ir.v, 0, -BH, 0)
	NewLayer(f, ir, { tex = TEX.side, uv = UV.innerSide, color = "inner", layer = "BACKGROUND", sub = 0, cols = C(2), rows = C(2) })
	local fl = NewFace(f, inside, "floor")
	fl.flatOff = true
	Set(fl.o, -BW / 2 + T, -BH / 2 + T, -BD / 2 + T)
	Set(fl.u, BW - 2 * T, 0, 0)
	Set(fl.v, 0, 0, BD - 2 * T)
	fl.light = 0.6
	NewLayer(f, fl, { tex = TEX.side, uv = UV.floor, color = "inner", layer = "BACKGROUND", sub = -1, cols = C(3), rows = C(2) })
	-- (the light rising out of it)
	local bm = NewFace(f, inside, "beam")
	Set(bm.o, -BW / 2 + T, BH / 2 + 0.46, 0)
	Set(bm.u, BW - 2 * T, 0, 0)
	Set(bm.v, 0, -0.52, 0)
	bm.light = 1
	NewLayer(f, bm, { tex = TEX.beam, color = "glow", alpha = 0.75, layer = "BORDER", sub = 1, blend = "ADD", cols = C(3), rows = 1 })
	local function Rim(group, key, o, u, v, layer, sub)
		local rf = NewFace(f, group, key)
		Set(rf.o, o[1], o[2], o[3])
		Set(rf.u, u[1], u[2], u[3])
		Set(rf.v, v[1], v[2], v[3])
		NewLayer(f, rf, { tex = TEX.side, uv = UV.rim, color = "light", layer = layer, sub = sub, cols = (u[1] > 0.3) and C(4) or 1, rows = 1 })
		return rf
	end
	Rim(inside, "rimBack", { -BW / 2, BH / 2, -BD / 2 }, { BW, 0, 0 }, { 0, 0, T }, "BORDER", 2)
	Rim(inside, "rimLeft", { -BW / 2, BH / 2, -BD / 2 + T }, { T, 0, 0 }, { 0, 0, BD - 2 * T }, "BORDER", 2).flatOff = true
	Rim(inside, "rimRight", { BW / 2 - T, BH / 2, -BD / 2 + T }, { T, 0, 0 }, { 0, 0, BD - 2 * T }, "BORDER", 2).flatOff = true

	-- its boosters
	for i = 1, B3.SIZE do
		local back = i <= 8
		local col = back and i or (i - 8)
		local p = {
			x = -BW / 2 + T + 0.012 + PW / 2 + (col - 1) * (PW + GAP) + (back and (PW + GAP) / 2 or 0),
			z = back and ROW_Z[1] or ROW_Z[2], out = back and ROW_OUT[1] or ROW_OUT[2], rise = 0, shown = true, back = back,
		}
		local pf = NewFace(f, inside, "pack" .. i)
		pf.light = back and 0.86 or 1
		local sub = back and 0 or 2
		p.body = NewLayer(f, pf, { color = "light", layer = "ARTWORK", sub = sub })
		p.top = NewLayer(f, pf, { color = "light", layer = "ARTWORK", sub = sub + 1, rect = { 0, 0, 1, 1 / 8 } })
		p.face = pf
		f.packs[i] = p
	end

	-- its sides
	local function Side(key, o, u)
		local sf = NewFace(f, sides, key)
		Set(sf.o, o[1], o[2], o[3])
		Set(sf.u, u[1], u[2], u[3])
		Set(sf.v, 0, -BH, 0)
		NewLayer(f, sf, { tex = TEX.side, uv = UV.sideTint, color = "tint", layer = "BACKGROUND", sub = 0, cols = C(2), rows = C(2) })
		NewLayer(f, sf, { tex = TEX.side, uv = UV.sideGold, color = "light", layer = "ARTWORK", sub = 0, cols = C(2), rows = C(2) })
		sf.emblem = NewLayer(f, sf, { color = "emblem", layer = "OVERLAY", sub = 0,
			rect = { (128 - 40) / 256, (132 - 40) / 256, (128 + 40) / 256, (132 + 40) / 256 } })
		return sf
	end
	f.sideL = Side("sideLeft", { -BW / 2, BH / 2, -BD / 2 }, { 0, 0, BD })
	f.sideR = Side("sideRight", { BW / 2, BH / 2, BD / 2 }, { 0, 0, -BD })

	-- its front: the art of its album, its colour, its gold, its emblem, its jewel, its kind, the glint over it
	local fr = NewFace(f, front, "front")
	Set(fr.o, -BW / 2, BH / 2, BD / 2)
	Set(fr.u, BW, 0, 0)
	Set(fr.v, 0, -BH, 0)
	fr.art = NewLayer(f, fr, { uv = UV.art, color = "light", layer = "BACKGROUND", sub = 0,
		rect = { 12 / 1024, 68 / 384, 1012 / 1024, 372 / 384 }, cols = C(6), rows = C(3) })
	NewLayer(f, fr, { tex = TEX.front, uv = UV.frontTint, color = "tint", layer = "BORDER", sub = 0, cols = C(6), rows = C(3) })
	NewLayer(f, fr, { tex = TEX.front, uv = UV.frontGold, color = "light", layer = "ARTWORK", sub = 0, cols = C(6), rows = C(3) })
	fr.emblem = NewLayer(f, fr, { color = "emblem", layer = "OVERLAY", sub = 0, rect = { 78 / 1024, 248 / 384, 178 / 1024, 348 / 384 } })
	fr.gem = NewLayer(f, fr, { color = "light", layer = "OVERLAY", sub = 1, rect = { 486 / 1024, 36 / 384, 538 / 1024, 88 / 384 } })
	fr.crest = NewLayer(f, fr, { tex = TEX.front, uv = UV.wings, color = "light", layer = "OVERLAY", sub = 0,
		rect = { 384 / 1024, -8 / 384, 640 / 1024, 120 / 384 } })
	fr.sash = NewLayer(f, fr, { tex = TEX.front, uv = UV.sash, color = "tint", layer = "OVERLAY", sub = 2,
		rect = { 768 / 1024, 0, 1, 128 / 384 } })
	fr.glintLayer = NewLayer(f, fr, { tex = TEX.front, uv = UV.glint, color = "light", layer = "OVERLAY", sub = 3, blend = "ADD" })
	fr.glintLayer.off = true
	f.front = fr
	Rim(front, "rimFront", { -BW / 2, BH / 2, BD / 2 - T }, { BW, 0, 0 }, { 0, 0, T }, "BACKGROUND", 1)
	-- (the lower halves of its seals, on its front)
	for i = 1, 2 do
		local sb = NewFace(f, front, "sealBottom" .. i)
		NewLayer(f, sb, { tex = TEX.front, uv = UV.sealBottom, color = "light", layer = "OVERLAY", sub = 4 })
	end

	-- its lid: its top, its inside (the art of its album, the plaque of its name), its flap, the upper halves of its seals
	local lo = NewFace(f, lid, "lidOut")
	lo.light = 0.9
	NewLayer(f, lo, { tex = TEX.lid, uv = UV.lidTint, color = "tint", layer = "BACKGROUND", sub = 0, cols = C(4), rows = C(2) })
	NewLayer(f, lo, { tex = TEX.lid, uv = UV.lidGold, color = "light", layer = "BORDER", sub = 0, cols = C(4), rows = C(2) })
	lo.emblem = NewLayer(f, lo, { color = "emblem", layer = "BORDER", sub = 1, rect = { 437 / 1024, 104 / 358, 587 / 1024, 254 / 358 } })
	local li = NewFace(f, lid, "lidIn")
	li.art = NewLayer(f, li, { uv = UV.header, color = "light", layer = "BACKGROUND", sub = 1,
		rect = { 14 / 1024, 14 / 358, 1010 / 1024, 344 / 358 }, cols = C(4), rows = C(2) })
	NewLayer(f, li, { tex = TEX.lid, uv = UV.plaque, color = "tint", layer = "BORDER", sub = 1,
		rect = { 282 / 1024, 20 / 358, 742 / 1024, 82 / 358 }, cols = C(2), rows = 1 })
	NewLayer(f, li, { tex = TEX.header, uv = UV.headerGold, color = "light", layer = "BORDER", sub = 2, cols = C(4), rows = C(2) })
	local fo = NewFace(f, lid, "lipOut")
	NewLayer(f, fo, { tex = TEX.lid, uv = UV.lipTint, color = "tint", layer = "ARTWORK", sub = 0, cols = C(4), rows = 1 })
	NewLayer(f, fo, { tex = TEX.lid, uv = UV.lipGold, color = "light", layer = "ARTWORK", sub = 1, cols = C(4), rows = 1 })
	local fi = NewFace(f, lid, "lipIn")
	NewLayer(f, fi, { tex = TEX.lid, uv = UV.lipInner, color = "light", layer = "ARTWORK", sub = 2, cols = C(4), rows = 1 })
	for i = 1, 2 do
		local st = NewFace(f, lid, "sealTop" .. i)
		NewLayer(f, st, { tex = TEX.front, uv = UV.sealTop, color = "light", layer = "OVERLAY", sub = 0 })
	end

	-- the words: the name of its album on its plaque, and on the inside of its lid
	f.small = W < 170
	local function Words(face, fx, fy, size, width, group, sub)
		local fs = group:CreateFontString(nil, "OVERLAY")
		fs:SetDrawLayer("OVERLAY", sub or 5)
		local w = { fs = fs, face = face, fx = fx, fy = fy, size = size, size0 = size, width = width }
		ns.SetFont(fs, size, "OUTLINE")
		fs:SetTextColor(1, 0.92, 0.72)
		CuratorOctoFull.SetWordWrap(fs, false)
		fs:Hide()
		f.words[CuratorOctoFull.Length(f.words) + 1] = w
		return w
	end
	f.name = Words(fr, 0.5, 334 / 384, math.max(6, W * 0.028), W * 0.40, front, 5)
	f.name2 = Words(li, 0.5, 51 / 358, math.max(6, W * 0.03), W * 0.36, lid, 6)
	f.name.on = not f.small
	f.name2.on = false

	for k, fn in pairs(B3.methods) do
		f[k] = fn
	end
	-- where each cell rests: where the box at rest puts it
	Paint(f, true)
	f:SetSeries(nil)
	return f
end

-------------------------------------------------------------------------------
-- What a box does
-------------------------------------------------------------------------------
local M = {}
B3.methods = M

function M:SetSeries(s)
	self.series = s
	self.tint = Tint(s)
	local g = (s and s.glow) or { 1, 0.8, 0.4 }
	self.glow = { 0.6 + 0.4 * g[1], 0.6 + 0.4 * g[2], 0.6 + 0.4 * g[3] }
	self.halo:SetVertexColor(g[1], g[2], g[3])
	local studio = MEDIA .. ((s and s.studio) or "StudioElwynn")
	SetLayerTexture(self.front.art, studio)
	SetLayerTexture(self.face.lidIn.art, studio)
	local set = MEDIA .. ((s and s.set) or "SetElwynn")
	for _, L in ipairs({ self.front.emblem, self.face.lidOut.emblem, self.sideL.emblem, self.sideR.emblem }) do
		SetLayerTexture(L, set)
	end
	local D = ns.Displays
	local kind = (D and D.Kind and D.Kind(s)) or "zone"
	self.kind = kind
	SetLayerTexture(self.front.gem, MEDIA .. (GEM[kind] or GEM.zone))
	local fr = self.front
	fr.crest.off = not (kind == "raid" or kind == "dungeon")
	if kind == "dungeon" then
		fr.crest.uv = UV.laurels
	else
		fr.crest.uv = UV.wings
	end
	LayerUV(fr.crest)
	fr.sash.off = kind ~= "event"
	local pack = (s and s.pack) or "PackElwynn"
	for _, p in ipairs(self.packs) do
		SetLayerTexture(p.body, MEDIA .. pack .. "Bottom")
		SetLayerTexture(p.top, MEDIA .. pack .. "Top")
	end
	local name = s and ns.Collection and ns.Collection.SeriesName and ns.Collection:SeriesName(s) or ""
	for _, w in ipairs({ self.name, self.name2 }) do
		w.text = name
		local size = w.size0
		if w.fs.SetTextScale then
			w.fs:SetTextScale(1)
		end
		ns.SetFont(w.fs, size, "OUTLINE")
		w.fs:SetText(name)
		while size > w.size0 * 0.6 and ns.TextWidth(w.fs) > w.width do
			size = size - 0.25
			ns.SetFont(w.fs, size, "OUTLINE")
		end
		w.size = size
		w.scale = nil
	end
	Paint(self)
end

-- Turned (yaw: its turn, radians; pitch: seen from above that much).
function M:SetView(yaw, pitch)
	if self.flat then
		return
	end
	self.yaw, self.pitch = yaw or B3.YAW, pitch or B3.PITCH
	Paint(self)
end

function M:GetView()
	return self.yaw, self.pitch
end

-- Its lid (k: 0 closed, 1 open); the light inside follows it, its seals tear with it unless told otherwise.
function M:SetLid(k, keepSeals)
	k = math.max(0, math.min(1, k or 0))
	self.lidK = k
	self.inner = Smooth(0.05, 0.75, k)
	if not keepSeals then
		self.tear = (k > 0) and math.max(self.tear, 1) or 0
	end
	self.inside.shown = k > 0
	CuratorOctoFull.SetShown(self.inside, k > 0)
	self.name2.on = k > 0.55
	self.name2.alpha = Smooth(0.55, 0.9, k)
	Paint(self)
end

function M:GetLid()
	return self.lidK
end

-- Its seals: 0 whole, 1 torn and gone.
function M:SetTear(t)
	self.tear = math.max(0, math.min(1, t or 0))
	Paint(self)
end

function M:SetCased(on)
	on = on and true or false
	self.cased = on
	for _, face in ipairs(self.faces) do
		if face.case then
			face.on = on
		end
	end
	Paint(self)
end

function M:SetDim(on)
	on = on and true or false
	if self.dim == on then
		return
	end
	self.dim = on
	for _, L in ipairs(self.layers) do
		for _, t in ipairs(L.cells) do
			CuratorOctoFull.SetDesaturated(t, on)
		end
	end
	CuratorOctoFull.SetShown(self.halo, not on)
	Paint(self)
end

-- A booster risen out of the box by d (in widths of the frame); shown or not (painted at the next frame, or at once
-- with box:Paint()).
function M:SetPackRise(i, d)
	local p = self.packs[i]
	if p then
		p.rise = d or 0
		Later(self)
	end
end

function M:SetPackShown(i, on)
	local p = self.packs[i]
	if p then
		p.shown = on and true or false
		Later(self)
	end
end

function M:Paint()
	Paint(self)
end

function M:ResetPacks()
	for _, p in ipairs(self.packs) do
		p.rise, p.shown = 0, true
	end
	Paint(self)
end

-- Where a booster is seen: its middle (x, y from the middle of the frame, in its points), its width there.
function M:PackScreen(i)
	local p = self.packs[i]
	if not p then
		return 0, 0, 0
	end
	Matrix(self)
	Place(self)
	local x, y = Point(self, p.face, 0.5, 0.5)
	local xa, ya = Point(self, p.face, 0, 0.5)
	local xb, yb = Point(self, p.face, 1, 0.5)
	return x, y, math.sqrt((xb - xa) ^ 2 + (yb - ya) ^ 2)
end

-- Where a seal is seen (its middle, on the edge of the lid).
function M:SealScreen(i)
	local face = self.face["sealBottom" .. (i or 1)]
	return Point(self, face, 0.5, 0)
end

-- Where the top of its opening is seen (its middle), and the inside of its lid.
function M:MouthScreen()
	return Point(self, self.face.innerBack, 0.5, 0)
end

-- A glint passing over its front, now (one sweep).
function M:Glint(dur)
	dur = dur or 1.1
	self.glintT0 = GetTime()
	self.glintDur = dur
	if not self.glintRun then
		self.glintRun = true
		ns.Tween(dur, function(_, raw)
			self.glint = -0.15 + 1.3 * raw
			self.front.glintLayer.off = false
			Paint(self)
		end, function()
			self.glintRun = nil
			self.glint = nil
			self.front.glintLayer.off = true
			Paint(self)
		end, ns.Ease.linear, self)
	end
end

-- It turns slowly by itself (on: true), a glint over it now and then.
local function Idle(self, elapsed)
	self.t = (self.t or 0) + elapsed
	local t = self.t
	local yaw = (self.baseYaw or B3.YAW) + math.sin(t * 0.5) * 0.30
	local pitch = (self.basePitch or B3.PITCH) + math.sin(t * 0.33) * 0.035
	if self.dragging then
		local x, y = GetCursorPosition()
		local s = self:GetEffectiveScale()
		self.dragYaw = self.dragYaw0 + (x / s - self.dragX0) * 0.012
		self.dragOff = math.max(-1.0, math.min(1.0, self.dragYaw))
		yaw = yaw + self.dragOff
		-- (tilt: the mouse up and down leans it too, seen from higher or from lower, never from under it)
		if self.tilt and y and self.dragY0 then
			self.tiltOff = math.max(TILT_LO, math.min(TILT_HI, (self.dragTilt0 or 0) - (y / s - self.dragY0) * 0.006))
		end
	elseif self.dragOff and self.dragOff ~= 0 then
		-- (let go: it comes back to its turn by itself)
		self.dragOff = self.dragOff * math.max(0, 1 - elapsed * 2.2)
		if math.abs(self.dragOff) < 0.002 then
			self.dragOff = 0
		end
		yaw = yaw + self.dragOff
	end
	if not self.dragging and self.tiltOff and self.tiltOff ~= 0 then
		self.tiltOff = self.tiltOff * math.max(0, 1 - elapsed * 1.6)
		if math.abs(self.tiltOff) < 0.002 then
			self.tiltOff = 0
		end
	end
	pitch = pitch + (self.tiltOff or 0)
	-- (never round to its back: it has none to show)
	self.yaw, self.pitch = math.max(-1.35, math.min(1.35, yaw)), pitch
	if t >= (self.nextGlint or 1.5) then
		self.nextGlint = t + 5.5
		self:Glint(1.2)
	end
	-- (thirty paints a second are enough for a box turning slowly; every frame while it is dragged)
	self.since = (self.since or 0) + elapsed
	if not self.glintRun and (self.dragging or self.since >= 0.033) then
		self.since = 0
		Paint(self)
	end
end

function M:SetIdle(on)
	if self.flat then
		return
	end
	self.idle = on and true or false
	if on then
		self.baseYaw, self.basePitch = self.baseYaw or B3.YAW, self.basePitch or B3.PITCH
		CuratorOctoFull.SetScript(self, "OnUpdate", Idle)
	else
		CuratorOctoFull.SetScript(self, "OnUpdate", nil)
	end
end

-- Turned with the mouse, held down over it (tilt, after the first test of 1.13.0: leaned up and down too, a display
-- inspected).
function M:SetDraggable(on, tilt)
	if self.flat then
		return
	end
	self.tilt = (on and tilt) and true or nil
	self:EnableMouse(on and true or false)
	if not on then
		CuratorOctoFull.SetScript(self, "OnMouseDown", nil)
		CuratorOctoFull.SetScript(self, "OnMouseUp", nil)
		return
	end
	CuratorOctoFull.SetScript(self, "OnMouseDown", function(b)
		local x, y = GetCursorPosition()
		b.dragging = true
		b.dragX0 = x / b:GetEffectiveScale()
		b.dragYaw0 = b.dragOff or 0
		b.dragY0 = y and y / b:GetEffectiveScale() or nil
		b.dragTilt0 = b.tiltOff or 0
	end)
	CuratorOctoFull.SetScript(self, "OnMouseUp", function(b)
		b.dragging = false
	end)
end

-------------------------------------------------------------------------------
-- A booster on its own, in 3D: what flies out of a display opened (UI/Displays.lua)
-------------------------------------------------------------------------------
-- sp = B3.Pack(parent): sp:SetSeries(s); sp:Pose(x, y, w, yaw, pitch, roll) puts it at (x, y) from the middle of its
-- parent, w wide (twice as high), turned (radians), in perspective; sp:SetLight(k).
function B3.Pack(parent)
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, 10, 20)
	f.flat = not ns.Can3D()
	f.glow = f:CreateTexture(nil, "BACKGROUND")
	f.glow:SetTexture(TEX.glow)
	f.glow:SetBlendMode("ADD")
	f.glow:SetPoint("CENTER")
	f.glow:SetAlpha(0.35)
	f.body = f:CreateTexture(nil, "ARTWORK")
	f.body:SetAllPoints()
	f.top = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.top:SetPoint("TOPLEFT")
	f.top:SetPoint("TOPRIGHT")
	f.top:SetHeight(20 / 8)
	for _, t in ipairs({ f.body, f.top }) do
		if t.SetSnapToPixelGrid then
			t:SetSnapToPixelGrid(false)
			t:SetTexelSnappingBias(0)
		end
	end
	function f:SetSeries(s)
		local pack = (s and s.pack) or "PackElwynn"
		self.body:SetTexture(MEDIA .. pack .. "Bottom")
		self.top:SetTexture(MEDIA .. pack .. "Top")
		local g = (s and s.glow) or { 1, 0.8, 0.4 }
		self.glow:SetVertexColor(g[1], g[2], g[3])
	end
	function f:SetLight(k)
		self.body:SetVertexColor(k, k, k)
		self.top:SetVertexColor(k, k, k)
	end
	function f:Pose(x, y, w, yaw, pitch, roll)
		w = math.max(1, w)
		local h = w * 2
		self:ClearAllPoints()
		self:SetPoint("CENTER", parent, "CENTER", x, y)
		CuratorOctoFull.SetSize(self, w, h)
		self.top:SetHeight(h / 8)
		CuratorOctoFull.SetSize(self.glow, w * 3, h * 1.8)
		if self.flat then
			if self.body.SetRotation then
				CuratorOctoFull.SetRotation(self.body, roll or 0)
				CuratorOctoFull.SetRotation(self.top, roll or 0)
			end
			return
		end
		-- (its corners turned: yaw about its height, pitch about its width, roll in the plane of the screen)
		local cy, sy = math.cos(yaw or 0), math.sin(yaw or 0)
		local cp, sp = math.cos(pitch or 0), math.sin(pitch or 0)
		local cr, sr = math.cos(roll or 0), math.sin(roll or 0)
		local eye = h * 3.5
		local function P(px, py)
			-- yaw
			local x1, z1 = px * cy, -px * sy
			-- pitch
			local y2, z2 = py * cp - z1 * sp, py * sp + z1 * cp
			-- roll
			local x3, y3 = x1 * cr - y2 * sr, x1 * sr + y2 * cr
			local k = eye / (eye - z2)
			return x3 * k, y3 * k
		end
		local hw = w / 2
		local ax, ay = P(-hw, w)
		local bx, by = P(-hw, -w)
		local cx, cy2 = P(hw, w)
		local dx, dy = P(hw, -w)
		self.body:SetVertexOffset(1, ax + hw, ay - w)
		self.body:SetVertexOffset(2, bx + hw, by + w)
		self.body:SetVertexOffset(3, cx - hw, cy2 - w)
		self.body:SetVertexOffset(4, dx - hw, dy + w)
		local ty = w - h / 8
		local ex, ey = P(-hw, ty)
		local gx, gy = P(hw, ty)
		self.top:SetVertexOffset(1, ax + hw, ay - w)
		self.top:SetVertexOffset(2, ex + hw, ey - ty)
		self.top:SetVertexOffset(3, cx - hw, cy2 - w)
		self.top:SetVertexOffset(4, gx - hw, gy - ty)
	end
	f:SetSeries(nil)
	return f
end

-- Where the eye sees a booster of a box turned (its yaw, pitch) for one that flies on from there: the pose to give it.
function B3.PackPose(box)
	return box.yaw or B3.YAW, (box.pitch or B3.PITCH) - LEAN
end
