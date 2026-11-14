local _, ns = "Curator", CuratorOctoFull
local MEDIA = ns.MEDIA
local Ease = ns.Ease

-------------------------------------------------------------------------------
-- (1.12.0) The boosters of Hallow's End in their lair (UI/Lair.lua, UI/Booster.lua): the back of their cards (the night
-- over the graveyard, painted: the moon, the bats, a great jack-o'-lantern aglow; what glows in it, BackHallowFace, in
-- the colour of the card, flickering as its candle), and what comes out of a card turned over: a swarm of bats and a
-- puff of smoke, the light of its rarity, more of them for the best ones, the thunder for the legendary and mythic ones.
-------------------------------------------------------------------------------
local B = ns.Booster
local U = B.U
local GlowTo = U.GlowTo

local CANDLE = { 1, 0.6, 0.2 }
-- by rarity: how many bats, how far they fly (points), the smoke, the sounds
local BURST = {
	[1] = { bats = 2, reach = 260, puffs = 3, sparks = 6 },
	[2] = { bats = 4, reach = 300, puffs = 4, sparks = 10 },
	[3] = { bats = 6, reach = 360, puffs = 5, sparks = 16, snd = "hallowBats" },
	[4] = { bats = 9, reach = 420, puffs = 6, sparks = 24, snd = "hallowBats" },
	[5] = { bats = 13, reach = 500, puffs = 8, sparks = 34, snd = "hallowBats", thunder = true },
	[6] = { bats = 18, reach = 600, puffs = 10, sparks = 46, snd = "hallowBats", thunder = true, wail = true },
}
local BAT_POOL = 64
local BAT_LIFE = 1.6

-- A card of Hallow's End: its back of the night (else the back of its kind of booster).
function B:HallowBack(c, card)
	local hallow = card ~= nil and card.series ~= nil and card.series.look == "hallow"
	local b = c.back
	if hallow then
		-- (its back, the same everywhere: Card:SetBack, UI/Card.lua; what glows on it, the face of its jack-o'-lantern
		-- first: warm, in the colour of the card for the best ones)
		c:SetBack(card)
	elseif c.hallowBack then
		b.tex:SetTexture(MEDIA .. (self.lair and "BackDungeon" or ("Back" .. c.sfx)))
		b.cracks:SetTexture(MEDIA .. "CardCracks")
		b.cracks:SetAlpha(0)
	end
	c.hallowBack = hallow or nil
end

-- The colour of the candle of a card of Hallow's End face down, hovered (its rarity) or not.
function B:HallowCandle(c, hover)
	if not c.hallowBack or not c.pick then
		return
	end
	local r = c.pick.card.rarity
	local col = (hover or r >= 4) and ns.RARITY[r].glow or CANDLE
	c.back.cracks:SetVertexColor(col[1], col[2], col[3])
end

-- Every frame, a card face down: its candle flickers, brighter as its light swells.
function B:HallowFlicker(c, i, t)
	if not c.hallowBack or c.revealed or c.busy then
		return
	end
	local b = c.back
	local flick = 0.78 + 0.14 * math.sin(t * 9.3 + i * 2.1) + 0.08 * math.sin(t * 23 + i * 5)
	local lvl = math.max(c.hoverOn and 0.55 or 0.22, b.core:GetAlpha() * 0.9)
	b.cracks:SetAlpha(math.min(1, lvl * flick))
end

-------------------------------------------------------------------------------
-- What comes out of a card turned over
-------------------------------------------------------------------------------
function B:HallowBats()
	if self.hbats then
		return self.hbats
	end
	local fx = self.frame.fx or self.frame
	local pool = {}
	for i = 1, BAT_POOL do
		local t = fx:CreateTexture(nil, "OVERLAY", nil, 6)
		t:SetTexture(MEDIA .. "Bat")
		t:SetTexCoord(0, 0.5, 0, 1)
		t:Hide()
		pool[i] = t
	end
	self.hbats = pool
	return pool
end

-- A swarm of n bats out of (x, y) (in the middle of the scene), flying away every way, up more than down. big: how
-- much bigger they are (1: as the bats of a card).
function B:HallowSwarm(x, y, n, reach, rim, big)
	local pool = self:HallowBats()
	local parent = self.frame.fx or self.frame
	local used = 0
	for _, t in ipairs(pool) do
		local _, t = _, t; if used >= n then
			break
		end
		if not t:IsShown() then
			used = used + 1
			local a = math.random() * math.pi * 2
			-- (up more than down)
			local dx, dy = math.cos(a), math.sin(a) * 0.75 + 0.35
			local d = reach * (0.6 + math.random() * 0.6)
			local size = (34 + math.random() * 34) * (big or 1)
			local ph = math.random() * 3
			local life = BAT_LIFE * (0.75 + math.random() * 0.5)
			local left = dx < 0
			CuratorOctoFull.SetSize(t, size * 0.4, size * 0.2)
			t:SetVertexColor(rim and (0.45 + rim[1] * 0.25) or 0.6, rim and (0.4 + rim[2] * 0.2) or 0.5, rim and (0.45 + rim[3] * 0.2) or 0.55)
			t:SetAlpha(0)
			t:ClearAllPoints()
			t:SetPoint("CENTER", parent, "CENTER", x, y)
			t:Show()
			local beat = 0
			ns.Tween(life, function(e, raw)
				local k = 0.4 + 0.9 * e
				CuratorOctoFull.SetSize(t, size * k, size * 0.5 * k)
				t:ClearAllPoints()
				t:SetPoint("CENTER", parent, "CENTER", x + dx * d * e + math.sin(raw * 9 + ph) * 10, y + dy * d * e + math.sin(raw * 13 + ph) * 8)
				-- (its wings, up and down, nine beats a second)
				beat = beat + 1
				local up = CuratorOctoFull.Mod(math.floor(GetTime() * 9 + ph * 3) , 2) == 0
				local l, r = up and 0 or 0.5, up and 0.5 or 1
				if left then
					l, r = r, l
				end
				t:SetTexCoord(l, r, 0, 1)
				t:SetAlpha(math.min(1, raw * 8) * (1 - math.max(0, (raw - 0.7) / 0.3)))
			end, function()
				t:Hide()
			end, Ease.outQuad, self, math.random() * 0.12)
		end
	end
	return used
end

-- The card of Hallow's End is turned over: its bats, its smoke, its light, its sounds.
function B:HallowBurst(c)
	if not (c and c.pick and c.hallowBack) then
		return
	end
	local r = math.min(6, c.pick.card.rarity)
	local def = BURST[r] or BURST[1]
	local col = ns.RARITY[r].glow
	local x, y = c.slotX or 0, (c.slotY or 0) + (c.lift or 0)
	self:HallowSwarm(x, y + c.H * 0.1, def.bats, def.reach, col)
	-- (the smoke of the jack-o'-lantern blown out, then the light of the card)
	if self.puffs then
		self.puffs:Burst(x, y, { 0.16, 0.08, 0.2 }, def.puffs, 140 + 20 * r, 1.1, 120 + 10 * r, 0.6, 1.8)
	end
	if self.particles then
		self.particles:Burst(x, y, col, def.sparks, 200 + 40 * r, 0.9, 16)
		self.particles:Burst(x, y, CANDLE, math.floor(def.sparks / 2), 160 + 30 * r, 0.8, 12)
	end
	if self.Ring then
		self:Ring(x, y, col, 260 + 50 * r, 0.5, 0.35 + 0.08 * r, 0, "Shock")
	end
	if def.snd then
		ns.Play(ns.SND[def.snd])
	end
	if def.thunder then
		ns.Play(ns.SND.thunderRoll)
		if self.EdgeGlow then
			self:EdgeGlow(col, 0.35, 0.6)
		end
	end
	if def.wail then
		ns.Delay(0.35, function()
			ns.Play(ns.SND.hallowWail)
		end, self)
	end
end

-- The scene closes: the bats still flying go.
function B:HallowClear()
	for _, t in ipairs(self.hbats or {}) do
		t:Hide()
	end
end

-------------------------------------------------------------------------------
-- The lair of Hallow's End (UI/Lair.lua: LAIR.hallow). No chains on the pack: the candle of the jack-o'-lantern
-- painted on it is its seal, flickering (what glows on the pack, laid over it), flaring when what is inside throws
-- itself against it. Behind the pack, the face of a giant jack-o'-lantern lit in the dark: its eyes on both sides, its
-- grin under them (their fire, their hot core over it), flickering as a candle, now and then guttering. Bats far away
-- cross the night. Opened: the candle flares white-hot and is blown out; the face is blown out, a puff of smoke out
-- of its eyes; the pack bursts into bats.
-------------------------------------------------------------------------------
local Tex, Mix = U.Tex, U.Mix
local PACK_Y, PACK_W, PACK_H = U.PACK_Y, U.PACK_W, U.PACK_H
local WHITE = U.WHITE
-- the light of the candle in the jack-o'-lantern painted on the pack, its seal (what glows on the pack, laid over it:
-- PackHallow26Glow); the light that flares behind it when the pack is clicked: its size
local PACK_GLOW = "PackHallow26Glow"
local CANDLE_W, CANDLE_H = 118, 86
-- the face: its eyes on both sides of the pack, its grin under them, around the foot of the pack
local FACE_X, FACE_Y, FACE_W, FACE_H = 300, PACK_Y + 140, 300, 150
local GRIN_Y, GRIN_W, GRIN_H = PACK_Y - 130, 900, 380
local FIRE = { 1, 0.36, 0.05 }
local CORE = { 1, 0.8, 0.35 }
local FAR_BATS = 8

-- The pieces of the lair of Hallow's End (made the first time).
function B:HallowParts()
	local s = self.frame
	if s.hallowParts then
		return s.hallowParts
	end
	local hp = {}
	local bk = s.behind
	-- the face: the hot core of its eyes over them (UI/Lair.lua: s.eyes, its two eyes), its grin, a light around it all
	hp.halo = Tex(bk, "BACKGROUND", 0, "Glow", "ADD")
	CuratorOctoFull.SetSize(hp.halo, 1500, 980)
	hp.halo:SetPoint("CENTER", bk, "CENTER", 0, PACK_Y + 10)
	hp.eyeCores = {}
	for i = 1, 2 do
		local c = Tex(bk, "BACKGROUND", 2, "HallowEyeCore", "ADD")
		if i == 2 then
			c:SetTexCoord(1, 0, 0, 1)
		end
		c:SetAlpha(0)
		hp.eyeCores[i] = c
	end
	hp.grin = Tex(bk, "BACKGROUND", 1, "HallowGrin", "ADD")
	hp.grinCore = Tex(bk, "BACKGROUND", 2, "HallowGrinCore", "ADD")
	for _, t in ipairs({ hp.halo, hp.grin, hp.grinCore }) do
		t:SetAlpha(0)
	end
	-- the jack-o'-lantern painted on the pack, its seal: the light of its candle, flickering
	local sl = s.pack.seal
	hp.pumpkin = Tex(sl, "ARTWORK", 3, PACK_GLOW, "ADD")
	hp.pumpkin:SetAllPoints(sl)
	hp.pumpkin:SetVertexColor(FIRE[1], FIRE[2] + 0.2, FIRE[3] + 0.1)
	hp.pumpkin:Hide()
	-- the bats far away, across the night
	hp.far = {}
	for i = 1, FAR_BATS do
		local t = bk:CreateTexture(nil, "BACKGROUND", nil, 3)
		t:SetTexture(MEDIA .. "Bat")
		t:SetTexCoord(0, 0.5, 0, 1)
		t:SetVertexColor(0.1, 0.08, 0.12)
		t:Hide()
		hp.far[i] = t
	end
	s.hallowParts = hp
	return hp
end

-- Every lair: the candle or the chains (the candle of the jack-o'-lantern of the pack, or the medallion), the face
-- or the eyes.
function B:HallowLairSetup(lair)
	local s = self.frame
	local sl = s.pack.seal
	local candle = lair.candle
	if not (candle or lair.grin or s.hallowParts) then
		return
	end
	local hp = self:HallowParts()
	for _, t in ipairs(sl.chains) do
		-- (no chains on the pack of Hallow's End)
		t:SetTexture(MEDIA .. "ChainCross")
		CuratorOctoFull.SetSize(t, B.CHAIN_W / 2, B.CHAIN_H / 2)
		t:SetVertexColor(1, 1, 1)
		t:SetAlpha(candle and 0 or 1)
		CuratorOctoFull.SetShown(t, not candle)
	end
	CuratorOctoFull.SetShown(sl.lock, not candle)
	CuratorOctoFull.SetShown(sl.emblem, not candle)
	CuratorOctoFull.SetShown(hp.pumpkin, candle)
	hp.pumpkin:SetAlpha(0.4)
	hp.pumpkin:SetVertexColor(FIRE[1], FIRE[2] + 0.2, FIRE[3] + 0.1)
	hp.burst, hp.flare = nil, 0
	if candle then
		-- (what lights the seal: the jack-o'-lantern of the pack, its candle flaring)
		sl.shine:SetTexture(MEDIA .. "Glow")
		CuratorOctoFull.SetSize(sl.shine, CANDLE_W * 1.3, CANDLE_H * 1.3)
	else
		CuratorOctoFull.SetSize(sl.shine, B.LOCK * 0.48, B.LOCK * 0.48)
	end
	for i = 1, 2 do
		s.eyes[i]:SetTexture(MEDIA .. (lair.grin and "HallowEye" or "Eye"))
	end
	self.flyT, self.gutterT = 2.5, 4
end

-- The scene closes, or another lair opens: what is of Hallow's End goes.
function B:HallowLairReset()
	local hp = self.frame.hallowParts
	if not hp then
		return
	end
	for _, t in ipairs({ hp.halo, hp.grin, hp.grinCore, hp.eyeCores[1], hp.eyeCores[2] }) do
		t:SetAlpha(0)
	end
	hp.lit = false
	for _, t in ipairs(hp.far) do
		t:Hide()
	end
	local sl = self.frame.pack.seal
	-- (the chains, the medallion and its emblem of the other lairs, as they were)
	for _, t in ipairs(sl.chains) do
		t:Show()
		t:SetAlpha(1)
	end
	sl.lock:Show()
	sl.emblem:Show()
	hp.pumpkin:Hide()
	-- (the backs of the cards: plain again until the next ones are dealt)
	for _, c in ipairs(self.lairCards or {}) do
		self:HallowBack(c, nil)
	end
end

-- What is inside throws itself against the seal: the candle of the jack-o'-lantern flares.
function B:CandleFlare()
	local hp = self.frame.hallowParts
	if hp and not hp.burst then
		hp.flare = 0.45
	end
end

-- Every frame of the lair: the bats far away, now and then; the candle of the jack-o'-lantern of the pack.
function B:HallowNight(dt, t)
	local s = self.frame
	local hp = s.hallowParts
	if not hp then
		return
	end
	self.flyT = (self.flyT or 2.5) - dt
	if self.flyT <= 0 then
		self.flyT = 3.5 + math.random() * 5
		self:HallowFlyBy(math.random(1, 3))
	end
	-- (the candle in the jack-o'-lantern of the pack; it flares, and settles again)
	if hp.pumpkin:IsShown() and not hp.burst then
		hp.flare = math.max(0, (hp.flare or 0) - dt * 0.9)
		hp.pumpkin:SetAlpha(math.min(1, 0.42 + 0.12 * math.sin(t * 9.3) + 0.07 * math.sin(t * 23.1 + 1) + 0.05 * math.sin(t * 3.7) + hp.flare))
	end
end

-- A few bats far away cross the night, high over the pack, their wings beating.
function B:HallowFlyBy(n)
	local s = self.frame
	local hp = s.hallowParts
	local bk = s.behind
	local w = math.max(1000, (s:GetWidth() or 1365) / math.max(0.5, (s.stage and s.stage:GetScale()) or 1))
	local dir = math.random() < 0.5 and 1 or -1
	local y0 = PACK_Y + 170 + math.random() * 170
	local k = 0
	for _, t in ipairs(hp.far) do
		local _, t = _, t; if k >= n then
			break
		end
		if not t:IsShown() then
			k = k + 1
			local size = 20 + math.random() * 18
			local dy = (math.random() - 0.5) * 70
			local ph = math.random() * 3
			local life = 3.6 + math.random() * 2
			CuratorOctoFull.SetSize(t, size, size * 0.5)
			t:SetAlpha(0.9)
			t:Show()
			ns.Tween(life, function(e, raw)
				local x = -dir * (w / 2 + 60) + dir * (w + 120) * raw
				t:ClearAllPoints()
				t:SetPoint("CENTER", bk, "CENTER", x, y0 + dy + math.sin(raw * 7 + ph) * 18)
				local up = CuratorOctoFull.Mod(math.floor(GetTime() * 8 + ph * 3) , 2) == 0
				local l, r = up and 0 or 0.5, up and 0.5 or 1
				if dir < 0 then
					l, r = r, l
				end
				t:SetTexCoord(l, r, 0, 1)
			end, function()
				t:Hide()
			end, Ease.linear, self, (k - 1) * (0.25 + math.random() * 0.3))
		end
	end
end

-- Every frame: the face of the jack-o'-lantern, flickering as its candle (UI/Lair.lua: B:EyesTick). eyeA: how lit it
-- is (B:OpenEyes, B:CloseEyes); eyeFlare: how much brighter for an instant.
function B:GrinTick(dt, t)
	local s = self.frame
	local hp = s.hallowParts
	if not hp then
		return
	end
	local a = self.eyeA or 0
	local flare = self.eyeFlare or 0
	if a <= 0.001 then
		if hp.lit then
			for i = 1, 2 do
				s.eyes[i]:SetAlpha(0)
				s.eyeHalos[i]:SetAlpha(0)
				hp.eyeCores[i]:SetAlpha(0)
			end
			hp.grin:SetAlpha(0)
			hp.grinCore:SetAlpha(0)
			hp.halo:SetAlpha(0)
			hp.lit = false
		end
		return
	end
	hp.lit = true
	-- (a candle: two slow waves and a fast tremble; now and then it gutters, and comes back)
	local f = 0.8 + 0.09 * math.sin(t * 3.1) + 0.07 * math.sin(t * 7.3 + 1) + 0.04 * math.sin(t * 17.9)
	self.gutterT = (self.gutterT or 4) - dt
	if self.gutterT < 0 then
		local u = -self.gutterT / 0.4
		if u >= 1 then
			self.gutterT = 3 + math.random() * 5
		else
			f = f * (0.5 + 0.5 * math.abs(1 - 2 * u))
		end
	end
	local alpha = math.min(1, a * f + flare)
	local hot = math.min(1, a * f * f + flare * 1.3)
	local ox, oy = (self.parX or 0) * 1.1, (self.parY or 0) * 1.1
	local grow = 1 + 0.05 * flare
	for i = 1, 2 do
		local x = (i == 1 and -FACE_X or FACE_X) + ox
		local e, c, h = s.eyes[i], hp.eyeCores[i], s.eyeHalos[i]
		e:SetVertexColor(FIRE[1], FIRE[2], FIRE[3])
		c:SetVertexColor(CORE[1], CORE[2], CORE[3])
		h:SetVertexColor(FIRE[1], FIRE[2], FIRE[3])
		for _, tex in ipairs({ e, c }) do
			CuratorOctoFull.SetSize(tex, FACE_W * grow, FACE_H * grow)
			tex:ClearAllPoints()
			tex:SetPoint("CENTER", s.behind, "CENTER", x, FACE_Y + oy)
		end
		h:ClearAllPoints()
		h:SetPoint("CENTER", s.behind, "CENTER", x, FACE_Y + oy)
		e:SetAlpha(alpha * 0.9)
		c:SetAlpha(hot * 0.85)
		h:SetAlpha(alpha * 0.16)
	end
	hp.grin:SetVertexColor(FIRE[1], FIRE[2], FIRE[3])
	hp.grinCore:SetVertexColor(CORE[1], CORE[2], CORE[3])
	for _, tex in ipairs({ hp.grin, hp.grinCore }) do
		CuratorOctoFull.SetSize(tex, GRIN_W * grow, GRIN_H * grow)
		tex:ClearAllPoints()
		tex:SetPoint("CENTER", s.behind, "CENTER", ox * 0.8, GRIN_Y + oy * 0.8)
	end
	hp.grin:SetAlpha(alpha * 0.9)
	hp.grinCore:SetAlpha(hot * 0.85)
	hp.halo:SetVertexColor(FIRE[1], FIRE[2], FIRE[3])
	hp.halo:SetAlpha(alpha * 0.1)
	self.eyeFlare = math.max(0, flare - dt * 1.4)
end

-- Opened: the candle of the jack-o'-lantern flares, white-hot, and is blown out; the face is blown out, a puff of
-- smoke out of its eyes.
function B:CandleOut(col, hot)
	local s = self.frame
	local hp = s.hallowParts
	if not hp then
		return
	end
	-- (the candle of the jack-o'-lantern: it flares, white-hot, and is blown out)
	hp.burst = true
	ns.Tween(0.35, function(e, raw)
		hp.pumpkin:SetVertexColor(FIRE[1], FIRE[2] + 0.2 + 0.4 * e, FIRE[3] + 0.1 + 0.6 * e)
		hp.pumpkin:SetAlpha(math.min(1, 2.2 * raw) * (1 - raw) * 2.2)
	end, function()
		hp.pumpkin:Hide()
	end, Ease.outQuad, self)
	-- (sparks of its flame)
	self.glints:Burst(0, PACK_Y - 6, FIRE, 18, 300, 0.7, 12, 1, 0.5)
	-- (the face blown out: smoke out of its eyes)
	ns.Delay(0.5, function()
		if self.puffs then
			for _, side in ipairs({ -1, 1 }) do
				self.puffs:Burst(side * FACE_X, FACE_Y, { 0.16, 0.12, 0.12 }, 3, 90, 1.3, 120, 0.35, 1.6)
			end
		end
	end, self)
end

-- The pack bursts into a swarm of bats: a flash of its light, the pack darkens and is gone into them.
function B:DestroyBats(col, hot)
	local p = self.frame.pack
	ns.Play(ns.SND.hallowBats)
	self:Flash(Mix(col, WHITE, 0.4), 0.5, 0.35)
	self:Ring(0, PACK_Y, col, 900, 0.6, 0.7, 0, "Shock")
	ns.Tween(0.32, function(_, raw)
		local k = 1 - 0.75 * raw
		p.bottom:SetVertexColor(k, k * 0.95, k)
		p.top:SetVertexColor(k, k * 0.95, k)
		p.bottom:SetAlpha(1 - raw ^ 1.5)
		p.top:SetAlpha(1 - raw ^ 1.5)
		p.glow:SetAlpha(0.9 * (1 - raw))
	end, function()
		p:Hide()
		p.bottom:SetAlpha(1)
		p.top:SetAlpha(1)
		p.bottom:SetVertexColor(1, 1, 1)
		p.top:SetVertexColor(1, 1, 1)
	end, Ease.outQuad, self)
	-- (its bats, out of all of it)
	for i = 1, 4 do
		local y = PACK_Y + (i - 2.5) * PACK_H * 0.22
		self:HallowSwarm((math.random() - 0.5) * PACK_W * 0.6, y, 7, 640, col, 1.45)
	end
	if self.puffs then
		self.puffs:Burst(0, PACK_Y, { 0.14, 0.07, 0.18 }, 10, 260, 1.5, 200, 0.7, 2.4)
	end
	if self.particles then
		self.particles:Burst(0, PACK_Y, Mix(col, FIRE, 0.5), 30, 420, 1.0, 18, 0.8)
	end
	self:Shake(0.35, 9)
end
