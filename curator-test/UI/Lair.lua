local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease

-------------------------------------------------------------------------------
-- The boosters of the dungeons and the raids. They come down heavy, sealed: two chains across them,
-- an iron medallion with the emblem of the place. The place is dark, its mist on the ground, its air
-- full of embers or snow or spores; something watches from behind the pack, its eyes open when the
-- pack lands, its master roars and its music plays. Click: the light of the best card climbs
-- through the pack, the chains strain; the chains snap, the medallion bursts, and the pack is
-- destroyed the way of its place (burnt, shattered, rotten, blown up, torn by claws). Five big
-- cards come out (1.4: three before), each rare, epic or legendary, in an arc like a hand of cards
-- (UI/Booster.lua deals them and turns them over).
-------------------------------------------------------------------------------
local B = ns.Booster
local U = B.U
local Tex, GlowTo, Mix = U.Tex, U.GlowTo, U.Mix
local PACK_Y, PACK_W, PACK_H, TOP_H = U.PACK_Y, U.PACK_W, U.PACK_H, U.TOP_H
local WHITE, WARM = U.WHITE, U.WARM

-- the chains, drawn over a box a little larger than the pack, crossing in its middle
local CHAIN_W, CHAIN_H = 300, 520
local LOCK = 104
-- the eyes in the dark, on both sides of the pack (or one, the Old God's, behind it)
local EYE_X, EYE_Y, EYE_W, EYE_H = 268, PACK_Y + 120, 290, 145
local ONE_Y, ONE_W = PACK_Y + 70, 620
local IRON = { 0.42, 0.42, 0.46 }
local SOOT = { 0.16, 0.14, 0.13 }
-- (for the seal of Hallow's End, UI/HallowLair.lua: what it puts back for the others)
B.CHAIN_W, B.CHAIN_H, B.LOCK = CHAIN_W, CHAIN_H, LOCK

-- Each place: col, the colour of what lives there (its mist, the light in its medallion); eye, the
-- colour of its eyes (col by default); one, a single giant eye; mode, how the pack is destroyed
-- (burn, shatter, rot, blast, rend); air, what floats in the air; land and open, the sounds of the
-- place when the pack comes down and when it breaks (its doors, its gong, its bell).
local LAIR = {
	ragefire = { col = { 1, 0.42, 0.12 }, mode = "burn", air = "embers", land = { 6764 }, open = { 5636 } },
	wailing = { col = { 0.45, 1, 0.4 }, mode = "rot", air = "spores", land = { 3541 }, open = { 5335 } },
	deadmines = { col = { 1, 0.55, 0.2 }, eye = { 1, 0.25, 0.15 }, mode = "blast", air = "smoke", land = { 3360 }, open = { 3363 } },
	shadowfang = { col = { 0.55, 0.62, 1 }, eye = { 1, 0.85, 0.25 }, mode = "rend", air = "wisps", land = { 7154 } },
	blackfathom = { col = { 0.3, 0.65, 1 }, eye = { 0.35, 1, 0.85 }, mode = "rot", air = "bubbles", land = { 6455 }, open = { 1097 } },
	stockade = { col = { 1, 0.6, 0.3 }, eye = { 1, 0.3, 0.2 }, mode = "shatter", air = "dust", land = { 7117 }, open = { 6488 } },
	gnomeregan = { col = { 0.5, 1, 0.45 }, mode = "blast", air = "sparks", land = { 7336 }, open = { 7337 } },
	razorfen = { col = { 0.95, 0.62, 0.3 }, eye = { 1, 0.75, 0.2 }, mode = "rend", air = "dust", land = { 3960 } },
	scarlet = { col = { 1, 0.28, 0.24 }, mode = "burn", air = "ash", land = { 7256 }, open = { 5636 } },
	downs = { col = { 0.55, 0.85, 1 }, mode = "shatter", air = "snow", land = { 6761 }, open = { 3076 } },
	uldaman = { col = { 1, 0.82, 0.45 }, mode = "shatter", air = "dust", land = { 6432 }, open = { 3620 } },
	zulfarrak = { col = { 1, 0.75, 0.35 }, mode = "rend", air = "sand", land = { 5155 }, open = { 4654 } },
	maraudon = { col = { 0.78, 0.5, 1 }, mode = "shatter", air = "spores", land = { 7358 }, open = { 3620 } },
	sunken = { col = { 0.4, 0.95, 0.6 }, mode = "rot", air = "bubbles", land = { 4654 }, open = { 7274 } },
	depths = { col = { 1, 0.45, 0.15 }, mode = "burn", air = "embers", land = { 6537 }, open = { 6533 } },
	spire = { col = { 1, 0.35, 0.22 }, mode = "burn", air = "ash", land = { 6485 }, open = { 7274 } },
	diremaul = { col = { 0.5, 0.85, 1 }, eye = { 0.6, 1, 0.55 }, mode = "shatter", air = "motes", land = { 6762 }, open = { 6539 } },
	scholomance = { col = { 0.5, 1, 0.6 }, mode = "rot", air = "wisps", land = { 4678 }, open = { 743 } },
	stratholme = { col = { 0.8, 0.55, 1 }, eye = { 0.6, 0.85, 1 }, mode = "rot", air = "ash", land = { 6760 }, open = { 743 } },
	zulgurub = { col = { 1, 0.16, 0.2 }, mode = "rend", air = "blood", land = { 7334 }, open = { 4654 } },
	moltencore = { col = { 1, 0.45, 0.1 }, mode = "burn", air = "embers", land = { 7315 }, open = { 5636 } },
	onyxia = { col = { 0.85, 0.3, 0.6 }, eye = { 1, 0.55, 0.2 }, mode = "rend", air = "smoke", land = { 7574 }, open = { 7274 } },
	blackwing = { col = { 0.7, 0.3, 1 }, eye = { 1, 0.3, 0.25 }, mode = "burn", air = "ash", land = { 6485 }, open = { 7274 } },
	ruins = { col = { 1, 0.8, 0.4 }, mode = "rend", air = "sand", land = { 7115 }, open = { 7114 } },
	ahnqiraj = { col = { 0.85, 0.45, 1 }, eye = { 1, 0.62, 0.45 }, one = true, mode = "rot", air = "sand", land = { 7116 }, open = { 7114 } },
	-- (1.12.0) Hallow's End (UI/HallowLair.lua): no chains, the candle of the jack-o'-lantern painted on the pack for its
	-- seal; behind the pack, the face of a giant jack-o'-lantern lit in the dark; dead leaves in the air, bats flying
	-- across; the pack bursts into a swarm of bats; the cry of a bat as it lands
	hallow = { col = { 1, 0.5, 0.12 }, eye = { 1, 0.36, 0.05 }, mode = "bats", air = "leaves", seal = "candle", face = "grin", flyby = true, land = { 3369, 6526 }, open = { 6526 } },
	naxxramas = { col = { 0.55, 0.85, 1 }, mode = "shatter", air = "snow", land = { 4678 }, open = { 3076 } },
	-- (1.7.0) the new dungeons of Forever: the tombs of the thanes under Ironforge, the ruins of the old
	-- capital, the dig of the Wetlands, the haunted city of the Kirin Tor
	thanes = { col = { 1, 0.7, 0.32 }, eye = { 1, 0.42, 0.14 }, mode = "shatter", air = "dust", land = { 6432 }, open = { 3620 } },
	lordaeron = { col = { 0.5, 1, 0.68 }, eye = { 0.7, 1, 0.55 }, mode = "rot", air = "wisps", land = { 6760 }, open = { 743 } },
	excavation = { col = { 1, 0.74, 0.38 }, eye = { 1, 0.85, 0.3 }, mode = "rend", air = "dust", land = { 3960 }, open = { 3620 } },
	dalaran = { col = { 0.8, 0.5, 1 }, eye = { 0.95, 0.65, 1 }, mode = "shatter", air = "motes", land = { 6762 }, open = { 6539 } },
}
B.LAIR = LAIR

-- What floats in the air of a place: the texture and how it is drawn, where it comes from (the
-- bottom, the top, the left of the screen, or anywhere), how often one comes, its size, its life,
-- its speed (points a second), how much it sways and turns, how bright it is, its colour (the
-- place's by default).
local AIR = {
	embers = { tex = "Spark", from = "bottom", every = 0.045, size = { 5, 11 }, life = { 3, 5.5 }, vx = { -25, 25 }, vy = { 60, 140 }, wob = 16, col = { 1, 0.5, 0.15 } },
	ash = { tex = "Shard", blend = "BLEND", from = "top", every = 0.06, size = { 5, 11 }, life = { 6, 9 }, vx = { -30, 10 }, vy = { -60, -25 }, wob = 24, turn = 3, col = { 0.3, 0.28, 0.28 }, alpha = 0.85 },
	snow = { tex = "Spark", from = "top", every = 0.035, size = { 4, 10 }, life = { 7, 10 }, vx = { -40, -8 }, vy = { -70, -35 }, wob = 22, col = { 0.85, 0.93, 1 }, alpha = 0.85 },
	spores = { tex = "Spark", from = "any", every = 0.08, size = { 6, 15 }, life = { 6, 9 }, vx = { -14, 14 }, vy = { 8, 30 }, wob = 34, alpha = 0.7 },
	bubbles = { tex = "Ring", from = "bottom", every = 0.07, size = { 8, 24 }, life = { 5, 8 }, vx = { -8, 8 }, vy = { 50, 110 }, wob = 12, alpha = 0.65 },
	sand = { tex = "Streak", from = "left", every = 0.022, size = { 22, 40 }, life = { 2, 3.2 }, vx = { 420, 640 }, vy = { -30, 10 }, wob = 8, col = { 1, 0.84, 0.55 }, alpha = 0.32 },
	dust = { tex = "Spark", from = "any", every = 0.07, size = { 3, 8 }, life = { 6, 10 }, vx = { -10, 10 }, vy = { -8, 12 }, wob = 18, col = { 1, 0.86, 0.6 }, alpha = 0.5 },
	sparks = { tex = "Streak", from = "bottom", every = 0.05, size = { 14, 26 }, life = { 1.2, 2.2 }, vx = { -90, 90 }, vy = { 140, 300 }, wob = 4, col = { 1, 0.85, 0.45 }, alpha = 0.8 },
	blood = { tex = "Spark", from = "bottom", every = 0.06, size = { 4, 10 }, life = { 4, 7 }, vx = { -10, 10 }, vy = { 20, 55 }, wob = 14, col = { 1, 0.12, 0.14 } },
	wisps = { tex = "Puff", from = "any", every = 0.2, size = { 80, 160 }, life = { 5, 8 }, vx = { -30, 30 }, vy = { 6, 26 }, wob = 34, alpha = 0.16 },
	smoke = { tex = "Puff", blend = "BLEND", from = "bottom", every = 0.14, size = { 140, 260 }, life = { 7, 10 }, vx = { -25, 25 }, vy = { 20, 50 }, wob = 24, col = { 0.07, 0.06, 0.06 }, alpha = 0.4 },
	motes = { tex = "Twinkle", from = "any", every = 0.09, size = { 8, 16 }, life = { 4, 7 }, vx = { -12, 12 }, vy = { 6, 24 }, wob = 20, alpha = 0.8 },
	-- (1.12.0) the dead leaves of Hallow's End, of the colours of autumn
	leaves = { tex = "Leaf", blend = "BLEND", from = "top", every = 0.11, size = { 16, 30 }, life = { 7, 10 }, vx = { -55, 15 }, vy = { -62, -30 }, wob = 38, turn = 2.6, alpha = 0.92, n = 50,
		cols = { { 0.86, 0.42, 0.12 }, { 0.72, 0.24, 0.08 }, { 0.92, 0.64, 0.2 }, { 0.55, 0.3, 0.12 }, { 0.8, 0.52, 0.16 } } },
}
B.AIR = AIR

-- How long the pack takes to be destroyed before the cards come out of it, by way.
local DEAL_AFTER = { burn = 0.5, rot = 0.55, shatter = 0.12, blast = 0.08, rend = 0.4, bats = 0.3 }

local function Rand(r)
	return r[1] + math.random() * (r[2] - r[1])
end

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
-- The big cards of the dungeons: n of them at least.
function B:LairCards(n)
	local s = self.frame
	local st = s.stage
	for i = CuratorOctoFull.Length(self.lairCards) + 1, n do
		local i = i; local c = ns.NewCard(st, "lair")
		c:Hide()
		c.index = i
		c.back.tex:SetTexture(MEDIA .. "BackDungeon")
		CuratorOctoFull.SetScript(c, "OnClick", function()
			B:CardClick(c, i)
		end)
		CuratorOctoFull.SetScript(c, "OnEnter", function(card)
			B:Hover(card, true)
		end)
		CuratorOctoFull.SetScript(c, "OnLeave", function(card)
			B:Hover(card, false)
		end)
		c.rays = Tex(s.behind, "BORDER", 3, "Rays", "ADD")
		CuratorOctoFull.SetSize(c.rays, c.W * 2.2, c.W * 2.2)
		self.lairCards[i] = c
		self.allCards[CuratorOctoFull.Length(self.allCards) + 1] = c
	end
	return self.lairCards
end

function B:BuildLair()
	local s = self.frame
	local st = s.stage
	local base = s:GetFrameLevel()
	-- the five big cards, black iron on their back (1.6.0: six or seven with the talents of the Augur, made
	-- the first time a booster holds them: B:LairCards)
	self.lairCards = {}
	self:LairCards(ns.Collection.DUNGEON.size)

	-- the mist on the ground: a dark one, a glowing one (between the photo and the light of the
	-- place), drifting each its own way
	s.fogs = {}
	for i = 1, 2 do
		local f = s:CreateTexture(nil, "BACKGROUND", nil, 0)
		f:SetTexture(MEDIA .. "Fog", "REPEAT", "CLAMP")
		f:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 0, i == 1 and -20 or -60)
		f:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, i == 1 and -20 or -60)
		f:SetBlendMode(i == 1 and "BLEND" or "ADD")
		f:Hide()
		s.fogs[i] = f
	end

	-- the air of the place (it does not move with the camera: it is all around)
	local air = CreateFrame("Frame", nil, s)
	CuratorOctoFull.SetSize(air, 2, 2)
	air:SetPoint("CENTER")
	air:SetFrameLevel(base + 1)
	s.air = air
	self.airPools = {}

	-- the eyes in the dark, behind the pack, and the dim light they cast around them
	local bk = s.behind
	s.eyes, s.eyeHalos = {}, {}
	for i = 1, 2 do
		local h = Tex(bk, "BACKGROUND", 0, "Glow", "ADD")
		CuratorOctoFull.SetSize(h, EYE_W * 1.6, EYE_H * 2.2)
		s.eyeHalos[i] = h
		local t = Tex(bk, "BACKGROUND", 1, "Eye", "ADD")
		if i == 2 then
			t:SetTexCoord(1, 0, 0, 1)
		end
		s.eyes[i] = t
	end
	s.eyeOne = Tex(bk, "BACKGROUND", 1, "EyeOne", "ADD")

	-- on the pack: the chains (each quarter of their texture is one arm), the medallion and its
	-- emblem, what lights them, the claws that tear it
	local p = s.pack
	local sl = CreateFrame("Frame", nil, p)
	sl:SetAllPoints()
	sl:SetFrameLevel(p:GetFrameLevel() + 4)
	sl:Hide()
	p.seal = sl
	sl.chains = {}
	local QUARTERS = {
		{ 0, 0.5, 0, 0.5, "BOTTOMRIGHT", -1, 1 }, { 0.5, 1, 0, 0.5, "BOTTOMLEFT", 1, 1 },
		{ 0, 0.5, 0.5, 1, "TOPRIGHT", -1, -1 }, { 0.5, 1, 0.5, 1, "TOPLEFT", 1, -1 },
	}
	for i, q in ipairs(QUARTERS) do
		local t = sl:CreateTexture(nil, "ARTWORK")
		t:SetTexture(MEDIA .. "ChainCross")
		t:SetTexCoord(q[1], q[2], q[3], q[4])
		CuratorOctoFull.SetSize(t, CHAIN_W / 2, CHAIN_H / 2)
		t.corner, t.dx, t.dy = q[5], q[6], q[7]
		sl.chains[i] = t
	end
	sl.glow = Tex(sl, "ARTWORK", 1, "Glow", "ADD")
	CuratorOctoFull.SetSize(sl.glow, LOCK * 2.6, LOCK * 2.6)
	sl.glow:SetPoint("CENTER")
	sl.lock = sl:CreateTexture(nil, "ARTWORK", nil, 2)
	sl.lock:SetTexture(MEDIA .. "Lock")
	CuratorOctoFull.SetSize(sl.lock, LOCK, LOCK)
	sl.lock:SetPoint("CENTER")
	sl.emblem = sl:CreateTexture(nil, "ARTWORK", nil, 3)
	CuratorOctoFull.SetSize(sl.emblem, LOCK * 0.48, LOCK * 0.48)
	sl.emblem:SetPoint("CENTER")
	sl.shine = Tex(sl, "ARTWORK", 4, nil, "ADD")
	CuratorOctoFull.SetSize(sl.shine, LOCK * 0.48, LOCK * 0.48)
	sl.shine:SetPoint("CENTER")
	sl.claw = Tex(sl, "OVERLAY", 2, "StrikeClaw", "ADD")
	-- the pieces the pack breaks into, the masks that eat it (fire, ooze) and their glowing edge
	p.pieces = {}
	for i = 1, 6 do
		local t = p:CreateTexture(nil, "ARTWORK", nil, 2)
		t:Hide()
		p.pieces[i] = t
	end
	p.burnMask = CuratorOctoFull.CreateMaskTexture(p)
	p.burnMask:SetTexture(MEDIA .. "BurnMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	CuratorOctoFull.SetSize(p.burnMask, PACK_W * 1.3, PACK_H * 3)
	p.rotMask = CuratorOctoFull.CreateMaskTexture(p)
	p.rotMask:SetTexture(MEDIA .. "RotMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	CuratorOctoFull.SetSize(p.rotMask, PACK_W * 1.3, PACK_H * 3)
	p.edge = Tex(p, "OVERLAY", 2, nil, "ADD")

	-- links of chain, splinters of iron and of stone, glints of ice
	self.links = ns.Particles:New(s.fx, 24, "Link", "BLEND")
	self.links.spin = true
	self.shards = ns.Particles:New(s.fx, 48, "Shard", "BLEND")
	self.shards.spin = true
	self.glints = ns.Particles:New(s.fx, 48, "Shard", "ADD")
	self.glints.spin = true
end

-- A pool of the air of a kind (made the first time the kind is needed).
function B:AirPool(kind)
	local pool = self.airPools[kind]
	if not pool then
		local def = AIR[kind]
		pool = ns.Particles:New(self.frame.air, def.n or 70, def.tex, def.blend or "ADD", -1)
		pool.alpha = def.alpha
		pool.spin = def.turn and true or nil
		self.airPools[kind] = pool
	end
	return pool
end

-------------------------------------------------------------------------------
-- The scene
-------------------------------------------------------------------------------
function B:LairReset()
	local s = self.frame
	if not s.fogs then
		return
	end
	local p = s.pack
	CuratorOctoFull.ColorTexture(s.dim, 0.01, 0.015, 0.03, 0.36)
	self:PlaceHint(-206)
	for _, f in ipairs(s.fogs) do
		f:Hide()
	end
	for i = 1, 2 do
		s.eyes[i]:SetAlpha(0)
		s.eyeHalos[i]:SetAlpha(0)
	end
	s.eyeOne:SetAlpha(0)
	self.eyeK, self.eyeA, self.eyeFlare, self.eyeTw = 0, 0, 0, nil
	local sl = p.seal
	sl:Hide()
	sl.glow:SetAlpha(0)
	sl.shine:SetAlpha(0)
	sl.claw:SetAlpha(0)
	sl.lock:SetAlpha(1)
	CuratorOctoFull.SetSize(sl.lock, LOCK, LOCK)
	sl.emblem:SetAlpha(1)
	self:PlaceChains(0)
	for _, t in ipairs(sl.chains) do
		t:SetAlpha(1)
	end
	if p.masked then
		CuratorOctoFull.RemoveMaskTexture(p.bottom, p.masked)
		CuratorOctoFull.RemoveMaskTexture(p.top, p.masked)
		p.masked = nil
	end
	p.edge:SetAlpha(0)
	for _, t in ipairs(p.pieces) do
		t:Hide()
	end
	p.bottom:Show()
	p.top:Show()
	for _, pool in pairs(self.airPools) do
		pool:Clear()
	end
	self.links:Clear()
	self.shards:Clear()
	self.glints:Clear()
	self:StopMusic(400)
	self.airT, self.joltT, self.chainJolt, self.snapped = 0, 2.5, 0, false
	-- (1.12.0: the candle, the face of Hallow's End put away)
	if self.HallowLairReset then
		self:HallowLairReset()
	end
end

-- The chains on the pack, each arm pulled out by `out` points from the middle (0: in place).
function B:PlaceChains(out, jx, jy)
	local sl = self.frame.pack.seal
	for _, t in ipairs(sl.chains) do
		t:ClearAllPoints()
		t:SetPoint(t.corner, sl, "CENTER", t.dx * out + (jx or 0), t.dy * out + (jy or 0))
	end
end

-- The mist on the ground, as high and as wide as the scene (the screen, or the small window).
function B:LairFit()
	local s = self.frame
	local w, h = s:GetWidth() or 0, s:GetHeight() or 0
	if w <= 0 or h <= 0 then
		w, h = 1365, 768
	end
	h = h * 0.42
	for i, f in ipairs(s.fogs or {}) do
		f:SetHeight(h * (i == 1 and 1 or 0.8))
		f.span = (w / 512) * (i == 1 and 0.55 or 0.8)
	end
end

function B:LairOpen(series)
	local s, p = self.frame, self.frame.pack
	local th = LAIR[series.key] or {}
	local col = th.col or series.glow
	local lair = {
		series = series, col = col, eye = th.eye or col, one = th.one, mode = th.mode or "burn",
		air = AIR[th.air] and th.air or "dust", land = th.land, open = th.open,
		candle = th.seal == "candle", grin = th.face == "grin", flyby = th.flyby,
	}
	self.lair = lair
	self.cards = self.lairCards
	-- the place is darker; its mist lies on the ground
	CuratorOctoFull.ColorTexture(s.dim, 0.004, 0.004, 0.008, 0.6)
	s.halo:SetVertexColor(col[1], col[2], col[3])
	s.halo:SetAlpha(0.14)
	p.glow:SetVertexColor(col[1], col[2], col[3])
	p.glow:SetAlpha(0.3)
	self:LairFit()
	for i, f in ipairs(s.fogs) do
		if i == 1 then
			f:SetVertexColor(0.02 + col[1] * 0.04, 0.02 + col[2] * 0.04, 0.025 + col[3] * 0.04)
			f:SetAlpha(0.72)
		else
			f:SetVertexColor(col[1], col[2], col[3])
			f:SetAlpha(0.13)
		end
		f:Show()
	end
	-- the chains, the medallion and the emblem of the place
	local sl = p.seal
	sl:Show()
	sl.emblem:SetTexture(MEDIA .. (series.set or "SetElwynn"))
	sl.emblem:SetVertexColor(0.95, 0.72, 0.4)
	sl.shine:SetTexture(MEDIA .. (series.set or "SetElwynn"))
	sl.shine:SetVertexColor(col[1], col[2], col[3])
	sl.claw:ClearAllPoints()
	sl.claw:SetPoint("CENTER", sl, "CENTER", 0, 10)
	CuratorOctoFull.SetSize(sl.claw, PACK_H * 0.95, PACK_H * 0.95)
	sl.claw:SetVertexColor(col[1], col[2], col[3])
	self:PlaceChains(0)
	-- (1.12.0: the candle of a jack-o'-lantern, or the chains and the medallion; the face of a jack-o'-lantern, or eyes)
	if self.HallowLairSetup then
		self:HallowLairSetup(lair)
	end
	-- (no chains: nothing to break, the pack opens)
	s.hint:SetText(lair.candle and L["Click to open"] or L["Click to break the seal"])
	-- (under the ends of the chains)
	self:PlaceHint(-272)
	self.airT, self.joltT = 0, 2.5
	-- (a first breath of its air, so that the place is not empty while the pack falls)
	for _ = 1, 14 do
		self:AirOne(AIR[lair.air], true)
	end
end

-- The pack comes down hard; what lives there wakes, roars, and its music plays.
function B:LairLands()
	local lair = self.lair
	if not lair.candle then
		ns.Play(ns.SND.chains)
	end
	if lair.land then
		ns.Play(lair.land)
	end
	local foot = PACK_Y - PACK_H / 2 + 10
	self.puffs:Burst(-60, foot, { 0.3, 0.27, 0.24 }, 4, 150, 1.1, 130, 0.25, 2.2)
	self.puffs:Burst(60, foot, { 0.3, 0.27, 0.24 }, 4, 150, 1.1, 130, 0.25, 2.2)
	self:Ring(0, foot, lair.col, 640, 0.6, 0.35, 0.03, "Shock", 0.26)
	self:Punch(0.03, 0.4)
	self:Shake(0.32, 8)
	self.chainJolt = 0.3
	ns.Delay(0.3, function()
		self:OpenEyes()
	end, self)
	ns.Delay(0.55, function()
		-- (broken already, by a quick second click: what roared is gone)
		if not self.snapped then
			self:Roar()
		end
	end, self)
	ns.Delay(0.2, function()
		self:PlayMusic()
	end, self)
end

-- The master of the place (its last boss) roars.
function B:Roar()
	local final = self.lair and self.lair.series.final
	if not final then
		return
	end
	local card = ns.Cards["c" .. final]
	-- (1.12.0: a card of an album of an event, the sounds of its creature)
	local snd = ns.CinematicSounds and ns.CinematicSounds[(card and card.real) or final]
	local roar = (snd and snd[1] and snd[1] > 0 and snd[1]) or (card and card.sound)
	if roar and roar > 0 then
		ns.Play(roar)
	end
end

-- The music of its master (the one of its entrance), until the scene closes or an entrance plays. (1.12.0, later) An
-- album with a theme of its own (Hallow's End: the theme of the author, Hallow.lua): its file instead, played again
-- each time it ends while the scene lasts.
function B:PlayMusic()
	local s = self.lair and self.lair.series
	local theme = s and s.event and ns.Hallow and ns.Hallow.MUSIC
	if theme then
		self:StopMusic(200)
		self:PlayTheme(theme, ns.Hallow.MUSIC_LENGTH or 90)
		return
	end
	local final = s and s.final
	local card = final and ns.Cards["c" .. final]
	if not card or not ns.Cinematic or not ns.Cinematic.MusicOf then
		return
	end
	self:StopMusic(200)
	local ok, handle = ns.Play(ns.Cinematic:MusicOf(card))
	self.music = ok and handle or nil
end

-- (1.12.0, later) A theme of its own: its file (the sounds of Curator on), again at its end while it is the one playing.
function B:PlayTheme(file, length)
	if (ns.db and ns.db.mute) or not PlaySoundFile then
		return
	end
	local ok, willPlay, handle = pcall(PlaySoundFile, file, "SFX")
	if not (ok and willPlay ~= false and handle) then
		return
	end
	self.music = handle
	ns.Delay(length, function()
		if self.music == handle and self.lair and self.frame and self.frame:IsShown() then
			self:PlayTheme(file, length)
		end
	end, self)
end

function B:StopMusic(fade)
	if self.music then
		if StopSound then
			StopSound(self.music, fade or 1000)
		end
		self.music = nil
	end
end

-- (the scene closes)
function B:LairStop()
	self:StopMusic(1500)
	for _, pool in pairs(self.airPools or {}) do
		pool:Clear()
	end
	for _, pool in ipairs({ self.links, self.shards, self.glints }) do
		pool:Clear()
	end
end

-------------------------------------------------------------------------------
-- The eyes
-------------------------------------------------------------------------------
function B:OpenEyes()
	if not self.lair or self.snapped then
		return
	end
	if self.eyeTw then
		ns.CancelTween(self.eyeTw)
	end
	self.blinkT = 2.5 + math.random() * 2
	self.eyeTw = ns.Tween(0.55, function(e, raw)
		self.eyeK = e
		self.eyeA = math.min(1, raw * 2.5) * 0.9
	end, function()
		self.eyeTw = nil
	end, Ease.outBack, self)
	self.eyeFlare = 0.3
end

-- The eyes flare (amount: how much brighter for an instant).
function B:EyeFlare(amount)
	self.eyeFlare = math.max(self.eyeFlare or 0, amount)
end

-- The pack is broken: the eyes widen, blaze, and close for good.
function B:CloseEyes()
	if self.eyeTw then
		ns.CancelTween(self.eyeTw)
	end
	local k0, a0 = self.eyeK or 0, self.eyeA or 0
	self.eyeFlare = 0.6
	-- (the giant eye, at last seen whole, takes its time)
	self.eyeTw = ns.Tween(self.lair and self.lair.one and 1.5 or 0.9, function(_, raw)
		if raw < 0.25 then
			self.eyeK = k0 * (1 + 0.25 * raw / 0.25)
		else
			self.eyeK = k0 * 1.25 * (1 - (raw - 0.25) / 0.75) ^ 2
		end
		self.eyeA = a0 * (1 - raw ^ 2)
	end, function()
		self.eyeK, self.eyeA, self.eyeTw = 0, 0, nil
	end, Ease.linear, self)
end

function B:EyesTick(dt, t)
	local s, lair = self.frame, self.lair
	-- (1.12.0: the face of a jack-o'-lantern, flickering as its candle)
	if lair.grin and self.GrinTick then
		return self:GrinTick(dt, t)
	end
	local k, a = self.eyeK or 0, self.eyeA or 0
	local flare = self.eyeFlare or 0
	if k <= 0.001 or a <= 0.001 then
		if s.eyes[1]:GetAlpha() > 0 or s.eyeOne:GetAlpha() > 0 then
			for i = 1, 2 do
				s.eyes[i]:SetAlpha(0)
				s.eyeHalos[i]:SetAlpha(0)
			end
			s.eyeOne:SetAlpha(0)
		end
		return
	end
	-- they blink now and then (closing and opening in a fifth of a second)
	self.blinkT = (self.blinkT or 3) - dt
	local open = 1
	if self.blinkT < 0 then
		local u = -self.blinkT / 0.2
		if u >= 1 then
			self.blinkT = 2.5 + math.random() * 4
		else
			open = math.abs(1 - 2 * u)
		end
	end
	open = k * math.max(0.06, open)
	local alpha = math.min(1, a * (0.82 + 0.18 * math.sin(t * 2.1)) + flare)
	-- (they follow the mouse a little)
	local ox, oy = (self.parX or 0) * 1.1, (self.parY or 0) * 1.1
	local col = lair.eye
	if lair.one then
		local e = s.eyeOne
		e:SetVertexColor(col[1], col[2], col[3])
		CuratorOctoFull.SetSize(e, ONE_W * (1 + 0.06 * flare), ONE_W * open)
		e:ClearAllPoints()
		e:SetPoint("CENTER", s.behind, "CENTER", ox * 1.5, ONE_Y + oy * 1.5)
		e:SetAlpha(alpha)
	else
		for i = 1, 2 do
			local e, h = s.eyes[i], s.eyeHalos[i]
			local x = (i == 1 and -EYE_X or EYE_X) + ox
			e:SetVertexColor(col[1], col[2], col[3])
			CuratorOctoFull.SetSize(e, EYE_W * (1 + 0.08 * flare), EYE_H * open * (1 + 0.08 * flare))
			e:ClearAllPoints()
			e:SetPoint("CENTER", s.behind, "CENTER", x, EYE_Y + oy)
			e:SetAlpha(alpha)
			h:SetVertexColor(col[1], col[2], col[3])
			h:ClearAllPoints()
			h:SetPoint("CENTER", s.behind, "CENTER", x, EYE_Y + oy)
			h:SetAlpha(alpha * 0.22 * k)
		end
	end
	self.eyeFlare = math.max(0, flare - dt * 1.4)
end

-------------------------------------------------------------------------------
-- Every frame: the mist, the eyes, the air, the pack straining at its chains
-------------------------------------------------------------------------------
function B:AirOne(def, anywhere)
	local s = self.frame
	local pool = self:AirPool(self.lair.air)
	if pool:Free() == 0 then
		return
	end
	local w, h = s:GetWidth() or 1365, s:GetHeight() or 768
	if w <= 0 or h <= 0 then
		w, h = 1365, 768
	end
	local x, y
	local from = anywhere and "any" or def.from
	if from == "bottom" then
		x, y = (math.random() * 2 - 1) * w * 0.55, -h / 2 - 20
	elseif from == "top" then
		x, y = (math.random() * 2 - 1) * w * 0.6, h / 2 + 20
	elseif from == "left" then
		x, y = -w / 2 - 40, (math.random() * 2 - 1) * h * 0.45
	else
		x, y = (math.random() * 2 - 1) * w * 0.5, (math.random() * 2 - 1) * h * 0.45
	end
	local life = Rand(def.life)
	local col = (def.cols and def.cols[math.random(CuratorOctoFull.Length(def.cols))]) or def.col or self.lair.col
	pool:Drift(x, y, col, Rand(def.size), life, Rand(def.vx), Rand(def.vy), def.wob, def.turn)
end

function B:LairTick(dt, t)
	local s, lair = self.frame, self.lair
	for i, f in ipairs(s.fogs) do
		local u = CuratorOctoFull.Mod((t * (i == 1 and 0.011 or -0.019)) , 1)
		f:SetTexCoord(u, u + (f.span or 1), 0, 1)
	end
	self:EyesTick(dt, t)
	local def = AIR[lair.air]
	self.airT = math.max(-0.3, (self.airT or 0) - dt)
	while self.airT <= 0 do
		self.airT = self.airT + def.every * (0.6 + 0.8 * math.random())
		self:AirOne(def)
	end
	-- (1.12.0: bats flying across the night now and then; the spider on its thread)
	if lair.flyby and self.HallowNight then
		self:HallowNight(dt, t)
	end
	-- the sealed pack: now and then what is inside throws itself against the chains
	if self.state == "pack" then
		self.joltT = (self.joltT or 2.5) - dt
		if self.joltT <= 0 then
			self.joltT = 3.2 + math.random() * 3
			self:Jolt()
		end
	end
	if (self.chainJolt or 0) > 0 and self.frame.pack.seal:IsShown() and not self.snapped then
		self.chainJolt = math.max(0, self.chainJolt - dt)
		local a = 9 * self.chainJolt
		-- (the chains pulled tight)
		self:PlaceChains(lair.candle and 0 or -a * 0.2, (math.random() - 0.5) * a, (math.random() - 0.5) * a)
		if self.chainJolt == 0 then
			self:PlaceChains(0)
		end
	end
end

-- Something inside throws itself against the chains: they rattle, the medallion glows.
function B:Jolt()
	local p = self.frame.pack
	local sl = p.seal
	local col = self.lair.col
	if self.lair.candle then
		-- (no chains: the candle of the jack-o'-lantern flares)
		if self.CandleFlare then
			self:CandleFlare()
		end
	else
		ns.Play(ns.SND.chainHang)
	end
	self.chainJolt = 0.35
	ns.Tween(0.35, function(e)
		if self.state == "pack" then
			p.shake = 3.4 * (1 - e)
		end
	end, function()
		if self.state == "pack" then
			p.shake = 0
		end
	end, Ease.linear, self)
	sl.glow:SetVertexColor(col[1], col[2], col[3])
	sl.glow:SetAlpha(0.55)
	GlowTo(sl.glow, 0, 0.9, self)
	sl.shine:SetAlpha(0.7)
	GlowTo(sl.shine, 0, 0.9, self)
	self:EyeFlare(0.2)
end

-------------------------------------------------------------------------------
-- Opening: the light climbs, the chains strain, they snap, the pack is destroyed
-------------------------------------------------------------------------------
-- One more colour: the medallion glows in it, the chains strain, the eyes blaze, a dark echo.
function B:LairTell(k, col, r)
	local sl = self.frame.pack.seal
	if not self.lair.candle then
		ns.Play(ns.SND.chains)
	end
	if ns.SND.tellDark[r] then
		ns.Play(ns.SND.tellDark[r])
	end
	sl.glow:SetVertexColor(col[1], col[2], col[3])
	GlowTo(sl.glow, 0.45 + 0.13 * k, 0.2, self.charge)
	sl.shine:SetVertexColor(col[1], col[2], col[3])
	GlowTo(sl.shine, 0.55 + 0.12 * k, 0.2, self.charge)
	self.chainJolt = 0.3 + 0.08 * k
	self:EyeFlare(0.2 + 0.08 * k)
end

function B:LairDealDelay()
	return DEAL_AFTER[self.lair.mode] or 0.3
end

-- The chains snap and fly apart, the medallion bursts, the eyes close, and the pack is destroyed the
-- way of its place.
function B:LairBreak(col, hot)
	local s, p, lair = self.frame, self.frame.pack, self.lair
	local sl = p.seal
	self.snapped = true
	if not lair.candle then
		ns.Play(ns.SND.chainSnap)
	end
	ns.Play(ns.SND.sealBreak)
	if lair.open then
		ns.Play(lair.open)
	end
	local cy = PACK_Y
	-- (the words under the cards, where they always are)
	self:PlaceHint(-206)
	if lair.candle then
		-- (no chains to fly apart)
	else
		ns.Tween(0.75, function(e, raw)
			for _, t in ipairs(sl.chains) do
				t:ClearAllPoints()
				t:SetPoint(t.corner, sl, "CENTER", t.dx * (40 + 230 * e), t.dy * (30 + 170 * e) - 420 * raw * raw)
				t:SetAlpha(1 - raw ^ 1.6)
			end
		end, nil, Ease.outCubic, self)
	end
	if lair.candle and self.CandleOut then
		-- (1.12.0: the candle of the jack-o'-lantern flares and is blown out)
		self:CandleOut(col, hot)
	else
		self.links:Burst(0, cy, IRON, 14, 340, 0.9, 22, 1, 0.9)
		self.shards:Burst(0, cy, SOOT, 12, 300, 0.8, 18, 1, 0.7)
	end
	self.glints:Burst(0, cy, Mix(col, WHITE, 0.5), 10, 320, 0.7, 16, 1, 0.5)
	-- the medallion: white-hot, it bursts
	sl.shine:SetVertexColor(hot[1], hot[2], hot[3])
	sl.shine:SetAlpha(1)
	ns.Tween(0.3, function(e, raw)
		local k = LOCK * (1 + 0.6 * e)
		CuratorOctoFull.SetSize(sl.lock, k, k)
		sl.lock:SetAlpha(1 - raw)
		sl.emblem:SetAlpha(1 - raw)
		sl.shine:SetAlpha(1 - raw)
		sl.glow:SetAlpha(0.9 * (1 - raw))
	end, nil, Ease.outQuad, self)
	self:CloseEyes()
	-- (the texts on the pack go first)
	ns.Tween(0.2, function(e)
		p.name:SetAlpha(1 - e)
		p.kind:SetAlpha(1 - e)
	end, nil, Ease.outQuad, self)
	local destroy = self["Destroy" .. string.gsub(lair.mode, "^%l", string.upper)]
	if destroy then
		destroy(self, col, hot)
	else
		self:DestroyBurn(col, hot)
	end
end

-- The pack burns away from the bottom up, its edge of fire climbing, embers flying off it.
function B:DestroyBurn(col, hot)
	local p = self.frame.pack
	local m = p.burnMask
	CuratorOctoFull.AddMaskTexture(p.bottom, m)
	CuratorOctoFull.AddMaskTexture(p.top, m)
	p.masked = m
	p.edge:SetTexture(MEDIA .. "BurnEdge")
	CuratorOctoFull.SetSize(p.edge, PACK_W * 1.3, PACK_H * 3 / 8)
	local fire = Mix(col, WARM, 0.35)
	p.edge:SetVertexColor(fire[1], fire[2], fire[3])
	ns.Play(ns.SND.ignite)
	local from, to = -PACK_H / 2 - 30, PACK_H / 2 + 50
	local nextEmber = 0
	ns.Tween(0.85, function(e, raw)
		local y = from + (to - from) * e
		m:ClearAllPoints()
		m:SetPoint("CENTER", p, "CENTER", 0, y)
		p.edge:ClearAllPoints()
		p.edge:SetPoint("CENTER", p, "CENTER", 0, y)
		p.edge:SetAlpha(math.min(1, raw * 6) * math.min(1, (1 - raw) * 5))
		p.glow:SetAlpha(0.9 * (1 - raw))
		if raw >= nextEmber then
			nextEmber = raw + 0.06
			self.particles:Rise(-PACK_W * 0.5, PACK_W * 0.5, PACK_Y + y, fire, 4, 110, 0.9, 13)
		end
	end, function()
		p:Hide()
	end, Ease.inOutCubic, self)
	self.puffs:Burst(0, PACK_Y, { 0.12, 0.1, 0.09 }, 6, 180, 1.4, 170, 0.6, 2.2)
end

-- The pack rots: it darkens in the colour of the place, then melts from the top down, dripping.
function B:DestroyRot(col, hot)
	local p = self.frame.pack
	local m = p.rotMask
	CuratorOctoFull.AddMaskTexture(p.bottom, m)
	CuratorOctoFull.AddMaskTexture(p.top, m)
	p.masked = m
	p.edge:SetTexture(MEDIA .. "RotEdge")
	CuratorOctoFull.SetSize(p.edge, PACK_W * 1.3, PACK_H * 3 / 8)
	p.edge:SetVertexColor(col[1], col[2], col[3])
	ns.Play(ns.SND.melt)
	local dark = Mix(col, { 0, 0, 0 }, 0.55)
	local from, to = PACK_H / 2 + 30, -PACK_H / 2 - 180
	local nextDrip = 0
	ns.Tween(1.0, function(e, raw)
		local k = math.min(1, raw * 3)
		local c = Mix(WHITE, dark, k)
		p.bottom:SetVertexColor(c[1], c[2], c[3])
		p.top:SetVertexColor(c[1], c[2], c[3])
		local y = from + (to - from) * e
		m:ClearAllPoints()
		m:SetPoint("CENTER", p, "CENTER", 0, y)
		p.edge:ClearAllPoints()
		p.edge:SetPoint("CENTER", p, "CENTER", 0, y)
		p.edge:SetAlpha(math.min(1, raw * 5) * math.min(1, (1 - raw) * 4))
		p.glow:SetAlpha(0.9 * (1 - raw))
		if raw >= nextDrip then
			nextDrip = raw + 0.05
			local yy = PACK_Y + math.max(-PACK_H / 2, y)
			for _ = 1, 2 do
				local x = (math.random() - 0.5) * PACK_W
				self.particles:Drift(x, yy, col, 9 + math.random() * 7, 0.7, (math.random() - 0.5) * 20, -220 - math.random() * 160, 0)
			end
			self.motes:Rise(-PACK_W * 0.5, PACK_W * 0.5, yy, col, 2, 120, 1.2, 14)
		end
	end, function()
		p:Hide()
	end, Ease.inOutQuad, self)
end

-- The texture of the body of the pack (its pieces are cut out of it).
function B:PackBody()
	return MEDIA .. (self.lair.series.pack or "PackElwynn") .. "Bottom"
end

-- The pack cracks all over and shatters: its pieces fly out and fall, glints of ice or of stone.
function B:DestroyShatter(col, hot)
	local p = self.frame.pack
	local tex = self:PackBody()
	p.bottom:Hide()
	ns.Play(ns.SND.shatter)
	local pw, ph = PACK_W / 2, PACK_H / 3
	for i, t in ipairs(p.pieces) do
		local i, t = i, t; local cx, ry = CuratorOctoFull.Mod((i - 1) , 2), math.floor((i - 1) / 2)
		t:SetTexture(tex)
		t:SetTexCoord(cx * 0.5, cx * 0.5 + 0.5, ry / 3, ry / 3 + 1 / 3)
		CuratorOctoFull.SetSize(t, pw, ph)
		t:SetVertexColor(1, 1, 1)
		t:SetAlpha(1)
		t:Show()
		local x0, y0 = (cx - 0.5) * pw, (1 - ry) * ph
		local d = math.max(1, math.sqrt(x0 * x0 + y0 * y0))
		local v = 220 + math.random() * 160
		local vx, vy = x0 / d * v + (math.random() - 0.5) * 80, y0 / d * v * 0.7 + 120 + math.random() * 60
		ns.Tween(0.85, function(e, raw)
			t:ClearAllPoints()
			t:SetPoint("CENTER", p, "CENTER", x0 + vx * e, y0 + vy * e - 520 * raw * raw)
			t:SetAlpha(1 - raw ^ 1.8)
			local k = 1 - 0.25 * raw
			CuratorOctoFull.SetSize(t, pw * k, ph * k)
		end, function()
			t:Hide()
		end, Ease.outCubic, self)
	end
	-- the top strip flies up
	CuratorOctoFull.SetSize(p.top, PACK_W, TOP_H)
	ns.Tween(0.6, function(e, raw)
		p.top:ClearAllPoints()
		p.top:SetPoint("CENTER", p, "TOP", 0, -TOP_H / 2 + 260 * e - 200 * raw * raw)
		p.top:SetAlpha(1 - raw)
	end, nil, Ease.outCubic, self)
	self.glints:Burst(0, PACK_Y, Mix(col, WHITE, 0.6), 30, 460, 0.8, 22, 1, 0.6)
	self.shards:Burst(0, PACK_Y, SOOT, 14, 360, 0.9, 16, 1, 0.8)
	self:Flash(Mix(col, WHITE, 0.7), 0.45, 0.4)
	ns.Tween(0.4, function(e)
		p.glow:SetAlpha(0.9 * (1 - e))
	end, function()
		p:Hide()
	end, Ease.outQuad, self, 0.5)
end

-- The pack blows up: a ball of fire, its halves thrown away, debris, smoke.
function B:DestroyBlast(col, hot)
	local p = self.frame.pack
	local tex = self:PackBody()
	p.bottom:Hide()
	ns.Play(ns.SND.blast)
	local fire = { 1, 0.62, 0.22 }
	for i = 1, 2 do
		local i = i; local t = p.pieces[i]
		local side = i == 1 and -1 or 1
		t:SetTexture(tex)
		t:SetTexCoord(i == 1 and 0 or 0.5, i == 1 and 0.5 or 1, 0, 1)
		CuratorOctoFull.SetSize(t, PACK_W / 2, PACK_H)
		t:SetVertexColor(0.7, 0.6, 0.55)
		t:SetAlpha(1)
		t:Show()
		local vx, vy = side * (430 + math.random() * 120), 200 + math.random() * 100
		ns.Tween(0.9, function(e, raw)
			t:ClearAllPoints()
			t:SetPoint("CENTER", p, "CENTER", side * PACK_W / 4 + vx * e, vy * e - 700 * raw * raw)
			t:SetAlpha(1 - raw ^ 1.5)
		end, function()
			t:Hide()
		end, Ease.outCubic, self)
	end
	CuratorOctoFull.SetSize(p.top, PACK_W, TOP_H)
	ns.Tween(0.5, function(e, raw)
		p.top:ClearAllPoints()
		p.top:SetPoint("CENTER", p, "TOP", (math.random() - 0.5) * 6, -TOP_H / 2 + 420 * e)
		p.top:SetAlpha(1 - raw)
	end, nil, Ease.outCubic, self)
	self:Flash(fire, 0.75, 0.6)
	self:Ring(0, PACK_Y, fire, 980, 0.7, 0.9, 0, "Shock")
	self:Ring(0, PACK_Y, WARM, 640, 0.6, 0.7, 0.05)
	self.puffs:Burst(0, PACK_Y, { 0.1, 0.08, 0.07 }, 12, 300, 1.7, 220, 0.8, 2.6)
	self.shards:Burst(0, PACK_Y, SOOT, 26, 520, 1.0, 18, 1, 0.8)
	self.streaks:Burst(0, PACK_Y, fire, 40, 760, 0.6, 30, 0.8)
	self.particles:Burst(0, PACK_Y, fire, 30, 420, 1.0, 22, 0.8)
	self:Shake(0.6, 16)
	self:Punch(0.08, 0.6)
	ns.Tween(0.25, function(e)
		p.glow:SetAlpha(0.9 * (1 - e))
	end, function()
		p:Hide()
	end, Ease.outQuad, self, 0.7)
end

-- Claws tear the pack: three gashes of light across it, and it falls apart in two.
function B:DestroyRend(col, hot)
	local p = self.frame.pack
	local sl = p.seal
	local tex = self:PackBody()
	self:Roar()
	for k = 1, 3 do
		ns.Delay((k - 1) * 0.06, function()
			ns.Play(ns.SND.slash)
		end, self)
	end
	sl.claw:SetAlpha(0)
	ns.Tween(0.55, function(e, raw)
		-- (the claws come down from top right to bottom left, then their gashes fade)
		local k = math.min(1, raw / 0.2)
		sl.claw:ClearAllPoints()
		sl.claw:SetPoint("CENTER", sl, "CENTER", 40 * (1 - k), 10 + 50 * (1 - k))
		sl.claw:SetAlpha(raw < 0.2 and k or (1 - (raw - 0.2) / 0.8))
	end, function()
		sl.claw:SetAlpha(0)
	end, Ease.linear, self)
	self.streaks:Burst(0, PACK_Y, Mix(col, WHITE, 0.3), 26, 520, 0.6, 30, 0.8)
	self.particles:Burst(0, PACK_Y, col, 30, 340, 1.0, 18, 0.8)
	ns.Delay(0.16, function()
		p.bottom:Hide()
		for i = 1, 2 do
			local i = i; local t = p.pieces[i]
			local side = i == 1 and -1 or 1
			t:SetTexture(tex)
			t:SetTexCoord(i == 1 and 0 or 0.5, i == 1 and 0.5 or 1, 0, 1)
			CuratorOctoFull.SetSize(t, PACK_W / 2, PACK_H)
			t:SetVertexColor(1, 1, 1)
			t:SetAlpha(1)
			t:Show()
			ns.Tween(0.8, function(e, raw)
				t:ClearAllPoints()
				t:SetPoint("CENTER", p, "CENTER", side * (PACK_W / 4 + 120 * e), -60 * e - 380 * raw * raw)
				t:SetAlpha(1 - raw ^ 1.4)
			end, function()
				t:Hide()
				if i == 2 then
					p:Hide()
				end
			end, Ease.outQuad, self, (i - 1) * 0.05)
		end
		CuratorOctoFull.SetSize(p.top, PACK_W, TOP_H)
		ns.Tween(0.6, function(e, raw)
			p.top:ClearAllPoints()
			p.top:SetPoint("CENTER", p, "TOP", 30 * e, -TOP_H / 2 - 300 * raw * raw)
			p.top:SetAlpha(1 - raw)
			p.glow:SetAlpha(0.9 * (1 - raw))
		end, nil, Ease.outQuad, self)
	end, self)
end
