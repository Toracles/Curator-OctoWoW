local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA

-- (1.14.0, after the test of the Paladin collection by its author) The film of a card of a case (its entry: film,
-- Data/Crate*.lua): the entrance of Arthas, the film of Clément Hudson. Its images in textures of the addon (28 to a
-- texture of 2048 x 2048, 7 across and 4 down: pal2/make_pal_film.py), one after the other in their time (the time of its
-- sound: none waits for another), its sound with them, as it is. Over the scene of the case gone dark: the film in its
-- middle, as tall as most of it, its light spilling round it (its image again, large and dim, behind it). At its end its
-- last image goes into the window of the card, which comes around it. A click skips it (its sound fading); the
-- entrances off (/curator cinematic), none. Its textures read while the band runs (one a frame), let go when it is over.
local F = {}
ns.CaseFilm = F

local SIDE = 2048    -- its textures
local DARK = 0.6     -- the scene going dark before its first image
local INTO = 0.9     -- its last image going into the card
local SKIP = 0.35    -- skipped: it fades
local HEIGHT = 0.9   -- its height, a share of the one of the scene
local HINT = 4       -- how long "Click to skip" stays
local AMB = 0.6      -- its light round it

function F:Enabled()
	return not (ns.Cinematic and ns.Cinematic.Enabled and not ns.Cinematic:Enabled())
end

function F:IsPlaying()
	return self.playing and true or false
end

-- (its image i, from 0: its texture, the part of it)
function F.Cell(spec, i)
	local per = spec.cols * spec.rows
	local c = CuratorOctoFull.Mod(i , per)
	local x0 = (CuratorOctoFull.Mod(c , spec.cols)) * spec.cell
	local y0 = math.floor(c / spec.cols) * spec.h
	return math.floor(i / per) + 1, (x0 + 0.5) / SIDE, (x0 + spec.w - 0.5) / SIDE, (y0 + 0.5) / SIDE, (y0 + spec.h - 0.5) / SIDE
end

local function File(spec, a)
	return MEDIA .. spec.file .. a
end

-- Its textures read before it plays (while the band runs): one a frame, drawn on a point of the scene all but clear,
-- so that none waits to be read when its time comes.
function F:Preload(spec, parent)
	if not (spec and parent and self:Enabled()) then
		return
	end
	local h = self.holder
	if not h or h:GetParent() ~= parent then
		h = CreateFrame("Frame", nil, parent)
		CuratorOctoFull.SetSize(h, 1, 1)
		h:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
		h.tex = {}
		self.holder = h
	end
	h.spec, h.next = spec, 1
	h:Show()
	CuratorOctoFull.SetScript(h, "OnUpdate", function(fr)
		local a = fr.next
		if not a or a > spec.atlases then
			CuratorOctoFull.SetScript(fr, "OnUpdate", nil)
			return
		end
		local t = fr.tex[a]
		if not t then
			t = fr:CreateTexture(nil, "BACKGROUND")
			t:SetAllPoints()
			fr.tex[a] = t
		end
		t:SetTexture(File(spec, a))
		t:SetAlpha(0.01)
		t:Show()
		fr.next = a + 1
	end)
end

-- Its textures let go (the film over, the scene closed).
function F:Release()
	local h = self.holder
	if h then
		CuratorOctoFull.SetScript(h, "OnUpdate", nil)
		for _, t in ipairs(h.tex) do
			t:SetTexture(nil)
			t:Hide()
		end
		h.spec, h.next = nil, nil
	end
	local f = self.frame
	if f then
		for _, t in ipairs(f.imgs) do
			t:SetTexture(nil)
			t:Hide()
		end
		f.amb:SetTexture(nil)
	end
end

function F:Build(parent)
	local f = self.frame
	if f and f:GetParent() == parent then
		return f
	end
	f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)
	f:SetFrameLevel(parent:GetFrameLevel() + 90)
	f:EnableMouse(true)
	f:Hide()
	f.black = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	f.black:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.black, 0, 0, 0, 1)
	-- (its light round it: its image again, large and dim, behind it)
	f.amb = f:CreateTexture(nil, "BACKGROUND", nil, -4)
	f.amb:SetAllPoints()
	f.amb:SetVertexColor(0.4, 0.4, 0.4)
	f.screen = CreateFrame("Frame", nil, f)
	f.screen:SetFrameLevel(f:GetFrameLevel() + 1)
	f.imgs = {}
	f.hint = ns.Skin.Text(f.screen, "GameFontDisableSmall", "RIGHT")
	f.hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 18)
	CuratorOctoFull.SetScript(f, "OnMouseDown", function()
		F:Skip()
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function()
		F:Tick()
	end)
	self.frame = f
	return f
end

-- Plays the film spec over the scene (parent); into: where its last image goes (the middle of the window of the card
-- from the middle of the scene, x and y; its width, its height); done: shows the card, as its last image goes into it
-- (or as soon as it is skipped). False: no film (the entrances off).
function F:Play(spec, parent, into, done)
	if not (spec and parent and self:Enabled()) then
		return false
	end
	local f = self:Build(parent)
	for a = 1, math.max(spec.atlases, CuratorOctoFull.Length(f.imgs)) do
		local t = f.imgs[a]
		if a <= spec.atlases then
			if not t then
				t = f.screen:CreateTexture(nil, "ARTWORK")
				t:SetAllPoints()
				f.imgs[a] = t
			end
			t:SetTexture(File(spec, a))
			t:SetAlpha(1)
		else
			t:SetTexture(nil)
		end
		t:Hide()
	end
	local H = parent:GetHeight() * HEIGHT
	self.size = { H * spec.w / spec.h, H }
	self.aspect = parent:GetWidth() / math.max(1, parent:GetHeight())
	f.screen:ClearAllPoints()
	f.screen:SetPoint("CENTER", f, "CENTER", 0, 0)
	CuratorOctoFull.SetSize(f.screen, self.size[1], self.size[2])
	f.screen:SetAlpha(1)
	f.black:SetAlpha(0)
	f.amb:SetAlpha(0)
	f.hint:SetText(L["Click to skip"])
	f.hint:SetAlpha(0)
	f:SetAlpha(1)
	f:Show()
	self.spec, self.into, self.done = spec, into, done
	self.t0, self.shown, self.atlas, self.handle = GetTime(), nil, nil, nil
	self.phase, self.playing = "dark", true
	return true
end

-- (its sound, as its first image comes; the sounds of Curator off: none)
function F:Sound()
	local spec = self.spec
	if not (spec.sound and PlaySoundFile) or (ns.db and ns.db.mute) then
		return
	end
	local ok, willPlay, handle = pcall(PlaySoundFile, MEDIA .. spec.sound, "SFX")
	if ok and willPlay ~= false then
		self.handle = handle
	end
end

-- (its image i: its texture shown, the part of it; its light round it, the band of its middle in the shape of the
-- scene)
function F:Show(i)
	if i == self.shown then
		return
	end
	self.shown = i
	local f, spec = self.frame, self.spec
	local a, u0, u1, v0, v1 = F.Cell(spec, i)
	local t = f.imgs[a]
	if self.atlas ~= a then
		if self.atlas and f.imgs[self.atlas] then
			f.imgs[self.atlas]:Hide()
		end
		t:Show()
		f.amb:SetTexture(File(spec, a))
		self.atlas = a
	end
	t:SetTexCoord(u0, u1, v0, v1)
	local vm, bh = (v0 + v1) / 2, spec.w / (self.aspect or 1.78) / SIDE / 2
	f.amb:SetTexCoord(u0, u1, vm - bh, vm + bh)
	self.uv = { u0, u1, v0, v1 }
end

function F:Tick()
	if not self.playing then
		return
	end
	local f, spec = self.frame, self.spec
	local now = GetTime()
	local t = now - self.t0
	if self.phase == "dark" then
		f.black:SetAlpha(math.min(1, t / DARK))
		if t < DARK then
			return
		end
		self.phase, self.t1 = "film", self.t0 + DARK
		f.amb:SetAlpha(AMB)
		self:Sound()
	end
	if self.phase == "film" then
		local ft = now - self.t1
		local i = math.floor(ft * spec.fps)
		if i >= spec.frames then
			return self:Into()
		end
		self:Show(i)
		local h = ft < HINT and math.min(1, ft * 2) or math.max(0, 1 - (ft - HINT))
		f.hint:SetAlpha(0.75 * h)
		return
	end
	local p = math.min(1, (now - self.t2) / (self.phase == "into" and INTO or SKIP))
	local e = 1 - (1 - p) ^ 3
	if self.phase == "into" then
		-- its last image into the window of the card: where the card shows it, as large, cut as the card cuts it; the
		-- dark and its light going, the card coming around it, then it gives way to the card
		local into, s = self.into, self.size
		-- (what of its image the window shows: spec.into, from 0 to 1 across its image and down it, past them where the
		-- card shows more than it; else its middle, in the shape of the window. What of it is in the window: there, cut
		-- to it)
		local part = spec.into
		if not part then
			local keep = math.min(1, (spec.w / spec.h) / (into.w / into.h))
			part = { 0, 1, (1 - keep) / 2, 1 - (1 - keep) / 2 }
		end
		local c0, c1 = math.max(0, part[1]), math.min(1, part[2])
		local r0, r1 = math.max(0, part[3]), math.min(1, part[4])
		local fx0, fx1 = (c0 - part[1]) / (part[2] - part[1]), (c1 - part[1]) / (part[2] - part[1])
		local fy0, fy1 = (r0 - part[3]) / (part[4] - part[3]), (r1 - part[3]) / (part[4] - part[3])
		local tx, ty = into.x + ((fx0 + fx1) / 2 - 0.5) * into.w, into.y - ((fy0 + fy1) / 2 - 0.5) * into.h
		local tw, th = (fx1 - fx0) * into.w, (fy1 - fy0) * into.h
		f.screen:ClearAllPoints()
		f.screen:SetPoint("CENTER", f, "CENTER", tx * e, ty * e)
		CuratorOctoFull.SetSize(f.screen, s[1] + (tw - s[1]) * e, s[2] + (th - s[2]) * e)
		local u0, u1, v0, v1 = unpack(self.uv)
		local du, dv = u1 - u0, v1 - v0
		f.imgs[self.atlas]:SetTexCoord(u0 + du * c0 * e, u1 - du * (1 - c1) * e, v0 + dv * r0 * e, v1 - dv * (1 - r1) * e)
		f.black:SetAlpha(1 - e)
		f.amb:SetAlpha(AMB * (1 - e))
		f.screen:SetAlpha(p < 0.55 and 1 or math.max(0, 1 - (p - 0.55) / 0.45))
	else
		f:SetAlpha(1 - e)
	end
	f.hint:SetAlpha(0)
	if p >= 1 then
		self:End()
	end
end

-- (its last image: into the card, the card shown under it)
function F:Into()
	self.phase, self.t2 = "into", GetTime()
	self:Show(self.spec.frames - 1)
	self:Done()
end

function F:Done()
	local d = self.done
	self.done = nil
	if d then
		d()
	end
end

-- A click: the film ends now (its sound fading), the card shown.
function F:Skip()
	if not self.playing or self.phase == "into" or self.phase == "skip" then
		return
	end
	if self.handle and StopSound then
		StopSound(self.handle, 600)
	end
	self.handle = nil
	self.phase, self.t2 = "skip", GetTime()
	self:Done()
end

function F:End()
	self.playing, self.phase, self.handle = false, nil, nil
	local f = self.frame
	if f then
		f:Hide()
		f:SetAlpha(1)
	end
	self:Release()
end

-- The scene closed (or another case): the film stopped where it is, its sound with it, its textures let go.
function F:Stop()
	if self.handle and StopSound then
		StopSound(self.handle, 300)
	end
	self.handle, self.done = nil, nil
	self:End()
end
