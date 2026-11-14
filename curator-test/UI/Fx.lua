local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- Easing
-------------------------------------------------------------------------------
local E = {}
ns.Ease = E
function E.linear(t) return t end
function E.inQuad(t) return t * t end
function E.outQuad(t) return 1 - (1 - t) * (1 - t) end
function E.inCubic(t) return t * t * t end
function E.outCubic(t) local u = 1 - t return 1 - u * u * u end
function E.inOutQuad(t)
	if t < 0.5 then
		return 2 * t * t
	end
	local u = -2 * t + 2
	return 1 - u * u / 2
end
function E.inOutCubic(t)
	if t < 0.5 then
		return 4 * t * t * t
	end
	local u = -2 * t + 2
	return 1 - u * u * u / 2
end
function E.outBack(t)
	local c1, c3 = 1.70158, 2.70158
	local u = t - 1
	return 1 + c3 * u * u * u + c1 * u * u
end
function E.outElastic(t)
	if t == 0 or t == 1 then
		return t
	end
	return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
end

-------------------------------------------------------------------------------
-- Tweens: one driver frame, runs only while something animates.
-------------------------------------------------------------------------------
local tweens = {}
local driver = CreateFrame("Frame")
driver:Hide()

-- The time of an owner can run slower (slow motion) or stand still for an instant (the freeze of a
-- big impact): its tweens follow it. 1: normal time.
local scales = {}
function ns.SetTimeScale(owner, k)
	if owner then
		scales[owner] = (k and k ~= 1) and math.max(0, k) or nil
	end
end

function ns.GetTimeScale(owner)
	return owner and scales[owner] or 1
end

-- (1.14.0) What a tween gives back is a handle with nothing in it: the frames keep it, and another addon
-- reaches the frames (EnumerateFrames); the tween itself (its functions, its owner, a module of Curator) stays
-- here.
local handles = setmetatable({}, { __mode = "k" })

-- ns.Tween(duration, fn(eased, raw), done, ease, owner, delay)
function ns.Tween(dur, fn, done, ease, owner, delay)
	local t = { dur = math.max(0.0001, dur), el = -(delay or 0), fn = fn, done = done, ease = ease or E.outCubic, owner = owner }
	tweens[CuratorOctoFull.Length(tweens) + 1] = t
	driver:Show()
	local h = {}
	handles[h] = t
	return h
end

function ns.Delay(sec, fn, owner)
	return ns.Tween(sec, nil, fn, E.linear, owner)
end

function ns.CancelTween(h)
	local t = h and handles[h]
	if t then
		t.cancel = true
	end
end

function ns.CancelOwner(owner)
	for _, t in ipairs(tweens) do
		if t.owner == owner then
			t.cancel = true
		end
	end
end

CuratorOctoFull.SetScript(driver, "OnUpdate", function(_, elapsed)
	elapsed = math.min(elapsed, 0.1)
	local i = 1
	while i <= CuratorOctoFull.Length(tweens) do
		local t = tweens[i]
		if t.cancel then
			CuratorOctoFull.Remove(tweens, i)
		else
			local k = t.owner and scales[t.owner]
			t.el = t.el + (k and elapsed * k or elapsed)
			if t.el >= 0 then
				local p = math.min(1, t.el / t.dur)
				if t.fn then
					local ok, err = pcall(t.fn, t.ease(p), p)
					if not ok then
						t.cancel = true
						geterrorhandler()(err)
					end
				end
				if t.cancel then
					CuratorOctoFull.Remove(tweens, i)
				elseif p >= 1 then
					CuratorOctoFull.Remove(tweens, i)
					if t.done then
						local ok, err = pcall(t.done)
						if not ok then
							geterrorhandler()(err)
						end
					end
				else
					i = i + 1
				end
			else
				i = i + 1
			end
		end
	end
	if CuratorOctoFull.Length(tweens) == 0 then
		driver:Hide()
	end
end)

-------------------------------------------------------------------------------
-- Particles: additive sparks (or four-point stars, which turn; or streaks of light, which point
-- where they fly) flying out of a point.
-------------------------------------------------------------------------------
local Particles = {}
ns.Particles = Particles

-- blend: "ADD" (light, by default) or "BLEND" (dust)
function Particles:New(parent, count, texture, blend, sub)
	local p = { parent = parent, free = {}, active = {}, spin = texture == "Twinkle", orient = texture == "Streak" }
	for i = 1, count do
		local t = parent:CreateTexture(nil, "OVERLAY", nil, sub)
		t:SetTexture(ns.MEDIA .. (texture or "Spark"))
		t:SetBlendMode(blend or "ADD")
		t:Hide()
		p.free[i] = t
	end
	-- (1.14.0: the module behind it hidden from getmetatable, see the tweens)
	return setmetatable(p, { __index = Particles, __metatable = false })
end

-- How many are free.
function Particles:Free()
	return CuratorOctoFull.Length(self.free)
end

-- Sparks drawn into a point (x, y) from a circle around it: the power gathering in a hand.
function Particles:Gather(x, y, color, n, radius, life, size)
	for _ = 1, n do
		local t = CuratorOctoFull.Remove(self.free)
		if not t then
			return
		end
		local ang = math.random() * math.pi * 2
		local r = radius * (0.6 + math.random() * 0.6)
		local sx, sy = x + math.cos(ang) * r, y + math.sin(ang) * r
		local s = size * (0.5 + math.random() * 0.7)
		local l = life * (0.6 + math.random() * 0.6)
		t:SetVertexColor(color[1], color[2], color[3])
		CuratorOctoFull.SetSize(t, s, s)
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.parent, "CENTER", sx, sy)
		t:SetAlpha(0)
		t:Show()
		self.active[t] = true
		ns.Tween(l, function(e, raw)
			t:ClearAllPoints()
			t:SetPoint("CENTER", self.parent, "CENTER", sx + (x - sx) * e, sy + (y - sy) * e)
			t:SetAlpha(math.min(1, raw * 4) * (1 - raw * raw) * (self.alpha or 1))
		end, function()
			self:Release(t)
		end, E.inQuad, self, math.random() * life * 0.5)
	end
end

-- Burst of n sparks from (x, y) relative to the parent's center. grow: their size at the end of their
-- flight (as a share of their size; less than 1 by default: they burn out; more: they come at you).
function Particles:Burst(x, y, color, n, speed, life, size, spreadY, grow)
	for _ = 1, n do
		local t = CuratorOctoFull.Remove(self.free)
		if not t then
			return
		end
		local ang = math.random() * math.pi * 2
		local v = speed * (0.35 + math.random() * 0.65)
		local dx, dy = math.cos(ang) * v, math.sin(ang) * v * (spreadY or 1)
		local s = size * (0.5 + math.random() * 0.7)
		local l = life * (0.6 + math.random() * 0.6)
		t:SetVertexColor(color[1], color[2], color[3])
		CuratorOctoFull.SetSize(t, s, s)
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.parent, "CENTER", x, y)
		t:SetAlpha(self.alpha or 1)
		t:Show()
		self.active[t] = true
		local ox, oy = x + (math.random() - 0.5) * 20, y + (math.random() - 0.5) * 20
		local turn = self.spin and (math.random() - 0.5) * 4 or 0
		if self.orient then
			-- (a streak lies along its flight: the texture is drawn lying, it is turned that way)
			CuratorOctoFull.SetRotation(t, math.atan2(dy, dx))
		end
		local g = (grow or 0.4) - 1
		ns.Tween(l, function(e, raw)
			t:ClearAllPoints()
			-- slight gravity so sparks fall back a little
			t:SetPoint("CENTER", self.parent, "CENTER", ox + dx * e, oy + dy * e - 40 * raw * raw)
			t:SetAlpha((1 - raw * raw) * (self.alpha or 1))
			local k = 1 + raw * g
			CuratorOctoFull.SetSize(t, s * k, s * k)
			if turn ~= 0 then
				CuratorOctoFull.SetRotation(t, turn * raw)
			end
		end, function()
			self:Release(t)
		end, E.outCubic, self)
	end
end

-- Embers rising from a line (x0..x1 at y), drifting and fading: fire, ash.
function Particles:Rise(x0, x1, y, color, n, height, life, size)
	for _ = 1, n do
		local t = CuratorOctoFull.Remove(self.free)
		if not t then
			return
		end
		local x = x0 + math.random() * (x1 - x0)
		local s = size * (0.5 + math.random() * 0.8)
		local l = life * (0.6 + math.random() * 0.7)
		local drift = (math.random() - 0.5) * 40
		local up = height * (0.5 + math.random() * 0.7)
		t:SetVertexColor(color[1], color[2], color[3])
		CuratorOctoFull.SetSize(t, s, s)
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.parent, "CENTER", x, y)
		t:SetAlpha(0)
		t:Show()
		self.active[t] = true
		ns.Tween(l, function(e, raw)
			t:ClearAllPoints()
			t:SetPoint("CENTER", self.parent, "CENTER", x + drift * raw + math.sin(raw * 6 + x) * 6, y + up * e)
			t:SetAlpha((1 - raw) * (0.6 + 0.4 * math.sin(raw * 20 + x)) * math.min(1, raw * 6) * (self.alpha or 1))
		end, function()
			self:Release(t)
		end, E.outQuad, self)
	end
end

-- One mote carried by the air: from (x, y) at (vx, vy) points a second, swaying sideways (wob points),
-- turning (turn: how fast at most), fading in and out over its life: embers, ash, snow, spores,
-- bubbles, sand.
function Particles:Drift(x, y, color, size, life, vx, vy, wob, turn)
	local t = CuratorOctoFull.Remove(self.free)
	if not t then
		return
	end
	t:SetVertexColor(color[1], color[2], color[3])
	CuratorOctoFull.SetSize(t, size, size)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.parent, "CENTER", x, y)
	t:SetAlpha(0)
	t:Show()
	self.active[t] = true
	if self.orient then
		CuratorOctoFull.SetRotation(t, math.atan2(vy, vx))
	end
	local ph = math.random() * 6.28
	local spin = turn and (math.random() - 0.5) * turn or 0
	wob = wob or 0
	ns.Tween(life, function(_, raw)
		local el = raw * life
		t:ClearAllPoints()
		t:SetPoint("CENTER", self.parent, "CENTER", x + vx * el + math.sin(el * 1.3 + ph) * wob, y + vy * el)
		t:SetAlpha(math.min(1, raw * 5, (1 - raw) * 3) * (self.alpha or 1))
		if spin ~= 0 then
			CuratorOctoFull.SetRotation(t, ph + spin * el)
		end
	end, function()
		self:Release(t)
	end, E.linear, self)
end

function Particles:Release(t)
	if self.active[t] then
		self.active[t] = nil
		t:Hide()
		if self.spin or self.orient then
			CuratorOctoFull.SetRotation(t, 0)
		end
		CuratorOctoFull.Insert(self.free, t)
	end
end

function Particles:Clear()
	ns.CancelOwner(self)
	for t in pairs(self.active) do
		self:Release(t)
	end
end

-------------------------------------------------------------------------------
-- Small UI pieces shared by the booster scene and the album (the buttons are the game's own: see
-- UI/Skin.lua).
-------------------------------------------------------------------------------
-- An icon of the achievements on a texture: { media name or icon of the game, texture
-- coordinates, colour }. (1.14.0: or the file number the game gives for the icon of an item, C_Item.GetItemIconByID.)
function ns.SetIcon(tex, icon)
	local file = icon[1]
	if type(file) == "number" then
		tex:SetTexture(file)
	else
		-- (1.14.0: a texture with words on it, in the language of the game: Core.lua, ns.CaseTexture)
		tex:SetTexture(string.find(file, "\\", 1, true) and file or (ns.MEDIA .. ns.CaseTexture(file)))
	end
	local tc = icon[2]
	if tc then
		tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
	else
		tex:SetTexCoord(0, 1, 0, 1)
	end
	local c = icon[3]
	if c then
		tex:SetVertexColor(c[1], c[2], c[3])
	else
		tex:SetVertexColor(1, 1, 1)
	end
end
