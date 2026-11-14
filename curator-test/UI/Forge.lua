local _, ns = "Curator", CuratorOctoFull
local Ease = ns.Ease

-------------------------------------------------------------------------------
-- How a titanforged card comes (1.11.0: the light of a prism; before, the titans struck it with their
-- lightning, their disc of runes and the press of their forge). It is turned over as any card, then: time
-- stands still an instant, a white light goes through it and splits behind it into all the colours, a wheel
-- of rays of the rainbow that turns slowly behind it and stays a while; a pillar of white light edged with
-- blue and rose; waves of each colour, one after the other; shards of crystal fly out of it, turning, and
-- stars; its foil goes once round all its colours, bright, and its creature with it (the light of the prism on
-- it, the wheels of rays at its back); motes of every colour rise; a crystal chime, the fanfare of a titanforged
-- item.
-------------------------------------------------------------------------------
local B = ns.Booster
local U = B.U
local Tex, GlowTo = U.Tex, U.GlowTo
local WHITE = U.WHITE

-- the colours of the light split by the prism, in their order
local SPECTRUM = {
	{ 1, 0.35, 0.4 }, { 1, 0.72, 0.3 }, { 1, 0.96, 0.45 }, { 0.42, 1, 0.55 }, { 0.38, 0.85, 1 }, { 0.52, 0.5, 1 }, { 0.92, 0.48, 1 },
}
local PEARL = { 1, 0.97, 0.92 }
local CYAN = { 0.55, 0.92, 1 }
local ROSE = { 1, 0.6, 0.92 }
B.PRISM = SPECTRUM

-------------------------------------------------------------------------------
-- The pieces
-------------------------------------------------------------------------------
function B:BuildForge()
	local s = self.frame
	local bk, fx = s.behind, s.fx
	-- behind the card: the light split by the prism, two wheels of rays turning each its way
	s.prismRays = Tex(bk, "BORDER", 3, "PrismRays", "ADD")
	s.prismRays2 = Tex(bk, "BORDER", 4, "PrismRays", "ADD")
	-- over everything, an instant: the light bursting out of it in all the colours
	s.prismFlash = Tex(fx, "OVERLAY", 2, "PrismRays", "ADD")
	-- shards of crystal, flying out of it and turning
	self.shards = ns.Particles:New(fx, 40, "PrismShard", "ADD", 4)
	self.shards.spin = true
end

-- Everything of the prism gone at once (the scene resets or closes).
function B:ForgeClear()
	local s = self.frame
	if not s or not s.prismRays then
		return
	end
	self.prism = nil
	for _, t in ipairs({ s.prismRays, s.prismRays2, s.prismFlash }) do
		if t.tw then
			ns.CancelTween(t.tw)
		end
		t:SetAlpha(0)
		t.tw = nil
	end
	if self.shards and self.shards.Clear then
		self.shards:Clear()
	end
end

-- The light of the prism turns: every frame, it follows its card.
function B:ForgeTick(dt)
	local pr = self.prism
	if not pr then
		return
	end
	local s = self.frame
	local c = pr.card
	local x, y = c.slotX, c.slotY + (c.lift or 0)
	pr.ang = pr.ang + pr.spin * dt
	pr.k = pr.k + (1 - pr.k) * math.min(1, dt * 3)
	local d = pr.size * pr.k
	s.prismRays:ClearAllPoints()
	s.prismRays:SetPoint("CENTER", s.behind, "CENTER", x, y)
	CuratorOctoFull.SetSize(s.prismRays, d, d)
	CuratorOctoFull.SetRotation(s.prismRays, pr.ang)
	s.prismRays2:ClearAllPoints()
	s.prismRays2:SetPoint("CENTER", s.behind, "CENTER", x, y)
	CuratorOctoFull.SetSize(s.prismRays2, d * 0.68, d * 0.68)
	CuratorOctoFull.SetRotation(s.prismRays2, -pr.ang * 1.6 + 0.4)
	if pr.done and s.prismRays:GetAlpha() <= 0.001 then
		s.prismRays2:SetAlpha(0)
		self.prism = nil
	end
end

-------------------------------------------------------------------------------
-- The coming
-------------------------------------------------------------------------------
-- A titanforged card turned over (cine: out of its entrance, which had its music and its light).
function B:TitanStrike(c, x, y, r, cine)
	local s = self.frame
	-- (1.14.0, his word: the sound of a stone no more, the sounds of the game only) the toast of a warforged item of the
	-- game, at once (before: a blow of holy light, a chime, a gem picked up, the toast after them)
	ns.Delay(cine and 0.05 or 0, function()
		ns.Play(ns.SND.titanFanfare)
	end, self)
	-- time stands still an instant; a white light through it
	if not cine then
		self:HitStop(0.1)
	end
	self:Flash(PEARL, 0.55, 0.7)
	self:EdgeGlow(PEARL, 0.6, 1.5)
	c.hot:SetVertexColor(1, 1, 1)
	c.hot:SetAlpha(1)
	GlowTo(c.hot, 0, 0.6, self)
	-- the light bursting out of it, over everything, an instant
	local fl = s.prismFlash
	if fl.tw then
		ns.CancelTween(fl.tw)
	end
	local turn = (math.random() - 0.5) * 0.5
	fl:ClearAllPoints()
	fl:SetPoint("CENTER", s.fx, "CENTER", x, y)
	fl.tw = ns.Tween(0.95, function(e, raw)
		local d = c.H * (1.2 + 2.4 * e)
		CuratorOctoFull.SetSize(fl, d, d)
		CuratorOctoFull.SetRotation(fl, turn * raw)
		fl:SetAlpha((raw < 0.08) and (raw / 0.08) or (1 - raw) ^ 1.6)
	end, function()
		fl:SetAlpha(0)
		fl.tw = nil
	end, Ease.outCubic, self)
	-- the light split behind it: its wheels of rays of all the colours, which stay a while
	local pr = { card = c, size = c.H * 2.6, k = 0.55, ang = math.random() * 6.28, spin = 0.16 }
	self.prism = pr
	for i, t in ipairs({ s.prismRays, s.prismRays2 }) do
		t:SetVertexColor(1, 1, 1)
		t:SetAlpha(0)
		GlowTo(t, (i == 1) and 1 or 0.75, 0.35, self)
	end
	ns.Delay(3.2, function()
		-- (unless they shine behind another card since)
		if self.prism == pr then
			GlowTo(s.prismRays, 0.5, 1.6, self)
			GlowTo(s.prismRays2, 0.32, 1.6, self)
		end
	end, self)
	-- a pillar of white light, edged with blue and rose
	local foot = y - c.H * 0.45
	self:Beam(1, x, foot, PEARL, 300, 1400, 1.5, 1)
	self:Beam(2, x - 26, foot, CYAN, 220, 1250, 1.6, 0.55)
	self:Beam(3, x + 26, foot, ROSE, 220, 1250, 1.6, 0.55)
	-- waves of each colour, one after the other; a white one, and one along the ground
	for i, col in ipairs(SPECTRUM) do
		self:Ring(x, y, col, 560 + 70 * i, 0.85, 0.7, 0.035 * (i - 1), "Shock")
	end
	self:Ring(x, y, WHITE, 1250, 1.0, 0.45, 0.1, "Shock")
	self:Ring(x, c.slotY - c.H * 0.5, PEARL, 1050, 0.8, 0.55, 0.02, "Shock", 0.3)
	self:Spikes(x, y, PEARL, 980, 0.7, 0.9)
	self:Flare(x, y, PEARL, 1400, 0.7, 0.9)
	-- shards of crystal and stars of every colour
	for i, col in ipairs(SPECTRUM) do
		self.shards:Burst(x, y, col, 3, 560, 1.15, 34, 1, 0.7)
		self.stars:Burst(x, y, col, 2, 300, 1.1, 22)
	end
	self.streaks:Burst(x, y, PEARL, 30, 620, 0.7, 40, 0.8)
	self.stars:Burst(x, y, WHITE, 8, 220, 1.0, 22)
	-- a second glint, smaller
	ns.Delay(0.24, function()
		self:Ring(x, y, PEARL, 520, 0.5, 0.6, 0, "Shock")
		for i = 1, CuratorOctoFull.Length(SPECTRUM), 2 do
			self.shards:Burst(x, y, SPECTRUM[i], 1, 380, 1.0, 26, 1, 0.6)
		end
		self.stars:Burst(x, y, PEARL, 6, 200, 0.9, 20)
	end, self)
	self:Punch(0.05, 0.5)
	self:Shake(0.4, 8)
	-- its foil goes once round all its colours, bright, the light on its creature too (UI/Card.lua: Card:Holo)
	c.flourish = GetTime()
	-- motes of every colour rise around it
	for k = 0, 2 do
		local k = k; ns.Delay(0.15 + 0.35 * k, function()
			for i = 1 + k, CuratorOctoFull.Length(SPECTRUM), 3 do
				self.motes:Rise(x - c.W * 0.7, x + c.W * 0.7, y - c.H * 0.5, SPECTRUM[i], 4, 300, 2.2, 14)
			end
		end, self)
	end
end
