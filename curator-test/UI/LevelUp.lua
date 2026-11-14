local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local Ease = ns.Ease

-- The level of the collector gained, on the whole screen: the dark falls, the rays of its rank turn
-- behind its emblem, which comes down with a blow of light (a new rank: the old emblem breaks first,
-- the new one is forged in its place, its ribbon unrolls); the number of the level climbs to the new
-- one; the bar of the level; the reward that waits on the track, to claim at once (then to put in an
-- album) or later. A click anywhere (or Escape) goes on.
local LU = {}
ns.LevelUp = LU

local EMBLEM_Y = 112

local function Tex(parent, layer, sub, file, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
	if blend then
		t:SetBlendMode(blend)
	end
	return t
end

function LU:Build()
	if self.frame then
		return
	end
	local Hud = ns.Hud
	local f = CreateFrame("Frame", "CuratorLevelUp", UIParent)
	f:SetAllPoints()
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(300)
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	tinsert(UISpecialFrames, "CuratorLevelUp")
	f.dark = Tex(f, "BACKGROUND")
	f.dark:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.dark, 0, 0, 0, 1)
	f.vig = Tex(f, "BACKGROUND", 1, "Vignette")
	f.vig:SetAllPoints()

	local st = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(st, 900, 700)
	st:SetPoint("CENTER", 0, 26)
	f.st = st
	local function at(t, w, h, x, y)
		CuratorOctoFull.SetSize(t, w, h or w)
		t:SetPoint("CENTER", st, "CENTER", x or 0, y or EMBLEM_Y)
		return t
	end
	f.rays = at(Tex(st, "BACKGROUND", 2, "Rays", "ADD"), 860)
	f.rays2 = at(Tex(st, "BACKGROUND", 3, "Rays", "ADD"), 560)
	f.glow = at(Tex(st, "BORDER", 0, "Glow", "ADD"), 560)
	f.ring = at(Tex(st, "BORDER", 1, "Ring", "ADD"), 200)
	f.old = at(Tex(st, "ARTWORK", 1), 250)
	f.emblem = at(Tex(st, "ARTWORK", 2), 250)
	-- a light passing over the emblem, cut to it
	f.sheen = at(Tex(st, "ARTWORK", 3, "Sheen", "ADD"), 250)
	if st.CreateMaskTexture then
		f.mask = CuratorOctoFull.CreateMaskTexture(st)
		f.mask:SetAllPoints(f.emblem)
		CuratorOctoFull.AddMaskTexture(f.sheen, f.mask)
	end
	f.sheen:SetAlpha(0)
	f.flash = Tex(f, "OVERLAY", 7)
	f.flash:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.flash, 1, 1, 1, 1)
	f.flash:SetBlendMode("ADD")
	f.flash:SetAlpha(0)

	f.label = Hud.Text(st, 16, "OUTLINE")
	f.label:SetPoint("CENTER", st, "CENTER", 0, -32)
	f.label:SetTextColor(1, 0.84, 0.4)
	f.level = Hud.Text(st, 64, "THICKOUTLINE")
	f.level:SetPoint("CENTER", st, "CENTER", 0, -76)
	f.level:SetTextColor(1, 0.96, 0.84)
	f.banner = at(Tex(st, "ARTWORK", 4, "BannerRank"), 400, 100, 0, -150)
	f.newRank = Hud.Text(st, 12, "OUTLINE")
	f.newRank:SetPoint("CENTER", st, "CENTER", 0, -124)
	f.newRank:SetTextColor(1, 0.9, 0.6)
	f.rank = Hud.Text(st, 22, "OUTLINE")
	f.rank:SetPoint("CENTER", st, "CENTER", 0, -149)
	f.xp = Hud.XPBar(st, 320, 14)
	f.xp:SetPoint("CENTER", st, "CENTER", 0, -192)

	-- the reward
	f.reward = CreateFrame("Frame", nil, st)
	CuratorOctoFull.SetSize(f.reward, 420, 60)
	f.reward:SetPoint("CENTER", st, "CENTER", 0, -246)
	f.rewardLabel = Hud.Text(f.reward, 12, "OUTLINE")
	f.rewardLabel:SetPoint("TOP", 0, 6)
	f.rewardLabel:SetTextColor(1, 0.84, 0.4)
	f.icon = Tex(f.reward, "ARTWORK", 1)
	CuratorOctoFull.SetSize(f.icon, 54, 54)
	f.iconGlow = Tex(f.reward, "BORDER", 0, "Glow", "ADD")
	CuratorOctoFull.SetSize(f.iconGlow, 110, 110)
	f.iconGlow:SetPoint("CENTER", f.icon, "CENTER")
	f.iconGlow:SetVertexColor(1, 0.8, 0.4)
	f.rewardText = Hud.Text(f.reward, 15, "")
	f.rewardText:SetTextColor(1, 1, 1)
	f.claim = Hud.ClaimButton(st, 220, 40, L["Claim"])
	f.claim:SetPoint("CENTER", st, "CENTER", 0, -306)
	CuratorOctoFull.SetScript(f.claim, "OnClick", function()
		LU:OnClaim()
	end)
	f.hint = Hud.Text(st, 11, "")
	f.hint:SetPoint("CENTER", st, "CENTER", 0, -346)
	f.hint:SetTextColor(0.75, 0.75, 0.78)
	-- (1 November, his word: « SANS cliquer sur "Retour" impossible de retour »: a button goes on, a click beside no more)
	f.go = ns.Button(st, L["Continue"], 160, 24)
	f.go:SetPoint("CENTER", st, "CENTER", 0, -352)
	CuratorOctoFull.SetScript(f.go, "OnClick", function()
		if LU.ready then
			LU:Close()
		end
	end)
	f.go:Hide()

	f.sparks = ns.Particles:New(st, 70, "Spark")
	f.stars = ns.Particles:New(st, 40, "Twinkle")
	f.shards = ns.Particles:New(st, 26, "Shard", "BLEND")

	CuratorOctoFull.SetScript(f, "OnMouseDown", function() end)
	CuratorOctoFull.SetScript(f, "OnHide", function(self)
		-- (hidden with the whole interface: it does not come back stopped)
		if self:IsShown() then
			self:Hide()
		end
		LU:Cleanup()
	end)
	f.t = 0
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		CuratorOctoFull.SetRotation(self.rays, self.t * 0.12)
		CuratorOctoFull.SetRotation(self.rays2, -self.t * 0.2)
		if LU.live then
			self.glow:SetAlpha(LU.glowA * (0.8 + 0.2 * math.sin(self.t * 2.4)))
			-- the emblem floats a little
			local y = EMBLEM_Y + math.sin(self.t * 1.6) * 3
			self.emblem:ClearAllPoints()
			self.emblem:SetPoint("CENTER", self.st, "CENTER", 0, y)
		end
	end)
end

-- Fades a region to an alpha.
local function FadeTo(r, a, dur, delay)
	local a0 = r:GetAlpha()
	return ns.Tween(dur, function(e)
		r:SetAlpha(a0 + (a - a0) * e)
	end, nil, Ease.outQuad, LU, delay)
end

-- (the screen of an album complete first: a level waits for its end)
local AFTER = {}

-- The screen of a level, from a level to another (several crossed at once: the last one).
-- opts.done: called when it closes.
function LU:Play(from, to, opts)
	if ns.Complete and ns.Complete:Showing() then
		local w = self.after
		self.after = { from = w and math.min(w.from, from) or from, to = w and math.max(w.to, to) or to, opts = opts or (w and w.opts) }
		if not self.afterPoll then
			self.afterPoll = true
			local function step()
				if ns.Complete:Showing() then
					ns.Delay(0.3, step, AFTER)
					return
				end
				LU.afterPoll = false
				local a = LU.after
				LU.after = nil
				if a then
					LU:Play(a.from, a.to, a.opts)
				end
			end
			ns.Delay(0.3, step, AFTER)
		end
		return
	end
	self:Build()
	local f = self.frame
	local LV = ns.Level
	ns.CancelOwner(self)
	-- (the alerts wait for its end)
	if ns.Toast and ns.Toast.Hold then
		ns.Toast:Hold()
	end
	f.sparks:Clear()
	f.stars:Clear()
	f.shards:Clear()
	self.opts = opts or {}
	self.from, self.to = from, to
	self.ready, self.live, self.claimed, self.closing = false, false, false, false
	f:SetAlpha(1)
	local r0 = LV.RankOf(from)
	local r1, rank = LV.RankOf(to)
	local rankUp = r1 > r0
	self.rankUp = rankUp
	local c = rank.light
	GameTooltip:Hide()
	f:Show()
	f:Raise()
	f.t = 0
	f.dark:SetAlpha(0)
	f.vig:SetAlpha(0)
	FadeTo(f.dark, 0.74, 0.35)
	FadeTo(f.vig, 1, 0.35)
	for _, t in ipairs({ f.rays, f.rays2, f.glow, f.ring, f.old, f.emblem, f.sheen, f.label, f.level, f.banner, f.newRank, f.rank, f.xp, f.reward, f.claim, f.hint }) do
		t:SetAlpha(0)
	end
	f.rays:SetVertexColor(c[1], c[2], c[3])
	f.rays2:SetVertexColor(c[1], c[2], c[3])
	f.glow:SetVertexColor(c[1], c[2], c[3])
	f.ring:SetVertexColor(c[1], c[2], c[3])
	self.glowA = 0
	f.emblem:SetTexture(LV.Emblem(r1))
	if f.mask then
		f.mask:SetTexture(LV.Emblem(r1), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	end
	f.emblem:ClearAllPoints()
	f.emblem:SetPoint("CENTER", f.st, "CENTER", 0, EMBLEM_Y)
	-- (the texts under the emblem: lower when the ribbon of a new rank comes)
	local function place(r, y)
		r:ClearAllPoints()
		r:SetPoint("CENTER", f.st, "CENTER", 0, y)
	end
	local y = rankUp and -172 or -128
	place(f.banner, y - 1)
	place(f.rank, y)
	place(f.xp, y - (rankUp and 54 or 40))
	self.rewardY = y - (rankUp and 108 or 94)
	place(f.reward, self.rewardY)
	place(f.claim, y - (rankUp and 168 or 154))
	place(f.hint, y - (rankUp and 208 or 194))

	-- the emblem comes down: the old one breaks first when the rank is new
	local land = 0.2
	if rankUp then
		land = 1.25
		f.old:SetTexture(LV.Emblem(r0))
		CuratorOctoFull.SetSize(f.old, 250, 250)
		f.old:ClearAllPoints()
		f.old:SetPoint("CENTER", f.st, "CENTER", 0, EMBLEM_Y)
		ns.Tween(0.45, function(e, raw)
			local k = 1.6 - 0.6 * e
			CuratorOctoFull.SetSize(f.old, 250 * k, 250 * k)
			f.old:SetAlpha(math.min(1, raw * 3))
		end, nil, Ease.outBack, self, 0.15)
		ns.Play(ns.SND.levelSting)
		-- the light of the new rank gathers into it: its glow grows, sparks are drawn in, the rays wake
		ns.Tween(0.6, function(e)
			f.glow:SetAlpha(0.45 * e)
		end, nil, Ease.inQuad, self, 0.55)
		ns.Delay(0.55, function()
			f.sparks:Gather(0, EMBLEM_Y, c, 26, 210, 0.6, 16)
		end, self)
		FadeTo(f.rays2, 0.16, 0.5, 0.6)
		-- it shakes, cracks of light, then it breaks
		ns.Tween(0.5, function(_, raw)
			local j = 6 * raw
			f.old:ClearAllPoints()
			f.old:SetPoint("CENTER", f.st, "CENTER", (math.random() - 0.5) * j, EMBLEM_Y + (math.random() - 0.5) * j)
			f.old:SetVertexColor(1, 1 - 0.2 * raw, 1 - 0.4 * raw)
		end, nil, Ease.linear, self, 0.7)
		ns.Delay(1.2, function()
			ns.Play(ns.SND.shatter)
			f.shards:Burst(0, EMBLEM_Y, { 0.85, 0.82, 0.78 }, 22, 380, 0.9, 30, 1, 0.6)
			f.sparks:Burst(0, EMBLEM_Y, c, 26, 320, 0.8, 22)
			f.old:SetAlpha(0)
			f.old:SetVertexColor(1, 1, 1)
		end, self)
	end
	ns.Delay(land, function()
		if not rankUp then
			ns.Play(ns.SND.levelSting)
		else
			ns.Play(ns.SND.rankUp)
		end
		-- the blow: the flash, the ring of light, the rays
		f.flash:SetAlpha(rankUp and 0.65 or 0.4)
		FadeTo(f.flash, 0, 0.5)
		ns.Tween(0.55, function(e, raw)
			local k = (rankUp and 1.9 or 1.7) - (rankUp and 0.9 or 0.7) * e
			CuratorOctoFull.SetSize(f.emblem, 250 * k, 250 * k)
			f.emblem:SetAlpha(math.min(1, raw * 4))
		end, function()
			CuratorOctoFull.SetSize(f.emblem, 250, 250)
			LU.live = true
		end, Ease.outBack, self)
		ns.Tween(0.7, function(e, raw)
			local s = 160 + 700 * e
			CuratorOctoFull.SetSize(f.ring, s, s)
			f.ring:SetAlpha((1 - raw) * 0.9)
		end, nil, Ease.outCubic, self, 0.12)
		FadeTo(f.rays, 0.5, 0.6, 0.05)
		FadeTo(f.rays2, 0.32, 0.6, 0.1)
		local g0 = f.glow:GetAlpha()
		ns.Tween(0.6, function(e)
			LU.glowA = g0 + (0.55 - g0) * e
			f.glow:SetAlpha(LU.glowA)
		end, nil, Ease.outQuad, self, 0.05)
		f.stars:Burst(0, EMBLEM_Y, c, 18, 260, 1.0, 26)
		f.sparks:Burst(0, EMBLEM_Y, { 1, 0.9, 0.6 }, 20, 240, 0.8, 18)
		-- a light passing over it
		ns.Tween(0.9, function(_, raw)
			f.sheen:ClearAllPoints()
			f.sheen:SetPoint("CENTER", f.st, "CENTER", -180 + 360 * raw, EMBLEM_Y)
			f.sheen:SetAlpha(math.sin(math.pi * raw) * 0.8)
		end, nil, Ease.linear, self, 0.6)
	end, self)

	-- the number climbs to the new level
	local t0 = land + 0.35
	f.label:SetText(L["LEVEL"])
	FadeTo(f.label, 1, 0.3, t0)
	f.level:SetText(tostring(from))
	FadeTo(f.level, 1, 0.3, t0)
	local steps = math.max(1, to - from)
	local beat = math.min(0.22, 0.9 / steps)
	for i = 1, steps do
		local i = i; local lv = from + i
		ns.Delay(t0 + 0.25 + beat * i, function()
			f.level:SetText(tostring(lv))
			ns.Play(ns.SND.xpTick)
			ns.Tween(0.2, function(e)
				ns.SetFont(f.level, 64 + 18 * math.sin(math.pi * e), "THICKOUTLINE")
			end, function()
				ns.SetFont(f.level, 64, "THICKOUTLINE")
			end, Ease.linear, self)
			if lv == to then
				f.sparks:Burst(0, -76, { 1, 0.86, 0.5 }, 16, 200, 0.6, 16)
			end
		end, self)
	end
	local t1 = t0 + 0.35 + beat * steps

	-- the rank: its name (a new one on its ribbon)
	local rc = rank.color
	f.rank:SetText(L[rank.name])
	f.rank:SetTextColor(rc[1], rc[2], rc[3])
	if rankUp then
		f.newRank:SetText(L["NEW RANK!"])
		f.rank:SetTextColor(1, 0.96, 0.86)
		ns.Tween(0.45, function(e, raw)
			CuratorOctoFull.SetSize(f.banner, 400 * (0.6 + 0.4 * e), 100)
			f.banner:SetAlpha(math.min(1, raw * 3))
		end, nil, Ease.outBack, self, t1)
		FadeTo(f.newRank, 1, 0.3, t1 + 0.2)
	end
	FadeTo(f.rank, 1, 0.35, t1 + 0.1)

	-- the bar of the new level
	local lv, into, need = LV.Of(LV:XP())
	f.xp:SetProgress(need and into / need or 1)
	f.xp:SetText(need and string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need)) or L["Highest level"])
	FadeTo(f.xp, 1, 0.35, t1 + 0.35)

	-- the reward waiting
	self:PaintReward()
	FadeTo(f.reward, 1, 0.35, t1 + 0.6)
	ns.Delay(t1 + 0.6, function()
		if CuratorOctoFull.Length(LV:Unclaimed()) > 0 then
			ns.Play(ns.SND.coins)
		end
	end, self)
	FadeTo(f.claim, 1, 0.3, t1 + 0.8)
	f.hint:SetText("")
	f.go:SetAlpha(0)
	ns.Delay(t1 + 1.4, function()
		f.go:Show()
	end, self)
	FadeTo(f.go, 1, 0.4, t1 + 1.4)
	ns.Delay(0.9, function()
		LU.ready = true
	end, self)
	-- embers rising all along
	for k = 0, 8 do
		local k = k; ns.Delay(land + k * 0.45, function()
			f.sparks:Rise(-260, 260, -330, c, 5, 420, 2.2, 14)
		end, self)
	end
end

-- The reward waiting on the track: (1.14.0) the rewards to choose of the levels reached and not claimed (three each,
-- one taken: UI/Offers.lua; a booster of a zone to choose each before).
function LU:PaintReward()
	local f = self.frame
	local LV = ns.Level
	local n = CuratorOctoFull.Length(LV:Unclaimed())
	f.rewardLabel:SetText(L["REWARD"])
	f.icon:SetTexture(ns.Hud.PackIcon("offer"))
	if self.claimed then
		f.rewardText:SetText(L["Choose your reward among three."])
		f.claim:SetLabel(L["Choose"])
		f.claim:SetEnabled(LV:OfferCount() > 0)
		f.claim:SetPulse(true)
	elseif n > 0 then
		f.rewardText:SetText(n == 1 and L["1 reward to choose"] or string.format(L["%d rewards to choose"], n))
		-- (1.11.0) and their rubies; past the legend, their boosters of a dungeon and of a raid (their icons)
		local rubies, packs = 0, {}
		for _, lv in ipairs(LV:Unclaimed()) do
			local r = LV.Reward(lv)
			rubies = rubies + (r and r.rubies or 0)
			LV.RewardPacks(r, packs)
		end
		if rubies > 0 and ns.Rubies then
			f.rewardText:SetText(f.rewardText:GetText() .. "   " .. ns.Rubies.Gem(16) .. " +" .. ns.Num(rubies))
		end
		local more = {}
		for _, kind in ipairs({ "dungeon", "raid" }) do
			if (packs[kind] or 0) > 0 then
				more[CuratorOctoFull.Length(more) + 1] = string.format(("|T%s:20:20|t %s"), ns.Hud.PackIcon(kind), "x" .. packs[kind])
			end
		end
		if CuratorOctoFull.Length(more) > 0 then
			f.rewardText:SetText(f.rewardText:GetText() .. "\n+ " .. table.concat(more, "   "))
		end
		f.claim:SetLabel(L["Claim"])
		f.claim:SetEnabled(true)
		f.claim:SetPulse(true)
	else
		f.rewardText:SetText(L["Claimed"])
		f.claim:SetLabel(L["Choose"])
		f.claim:SetEnabled(LV:OfferCount() > 0)
		f.claim:SetPulse(false)
	end
	-- the icon and its text, side by side, in the middle
	local w = 54 + 10 + ns.TextWidth(f.rewardText)
	f.icon:ClearAllPoints()
	f.icon:SetPoint("LEFT", f.reward, "CENTER", -w / 2, -10)
	f.rewardText:ClearAllPoints()
	f.rewardText:SetPoint("LEFT", f.icon, "RIGHT", 10, 0)
end

-- The button: the rewards claimed (they fly up and burst into the emblem), then (1.14.0) it opens the window of the
-- rewards to choose (UI/Offers.lua; the album to put the boosters to choose before).
function LU:OnClaim()
	local f = self.frame
	local LV = ns.Level
	if self.claimed or CuratorOctoFull.Length(LV:Unclaimed()) == 0 then
		self:Close()
		-- (the screen of a booster under it goes: the window would be behind it)
		local B = ns.Booster
		if B and B.Showing and B:Showing() then
			B.frame:Hide()
		end
		if ns.OffersUI and LV:OfferCount() > 0 then
			ns.OffersUI:Show()
		end
		return
	end
	local done = LV:ClaimLevels()
	self.claimed = true
	ns.Play(ns.SND.claim)
	-- they fly into the emblem
	local sx, sy = ns.Hud.Where(f.st)
	if sx then
		for i = 1, math.min(CuratorOctoFull.Length(done), 6) do
			local i = i; ns.Hud.Fly(ns.Hud.PackIcon("offer"), f.icon, { sx, sy + EMBLEM_Y }, 44, 0.55, function()
				if i == 1 then
					ns.Play(ns.SND.coins)
					f.stars:Burst(0, EMBLEM_Y, { 1, 0.86, 0.45 }, 10, 180, 0.7, 22)
				end
			end, { 1, 0.85, 0.45 }, (i - 1) * 0.08)
		end
	end
	f.sparks:Burst(0, self.rewardY or -222, { 1, 0.86, 0.45 }, 20, 220, 0.7, 18)
	self:PaintReward()
end

function LU:Close()
	local f = self.frame
	if not (f and f:IsShown()) or self.closing then
		return
	end
	self.closing = true
	self.ready = false
	ns.Tween(0.3, function(e)
		f:SetAlpha(1 - e)
	end, function()
		f:Hide()
		f:SetAlpha(1)
	end, Ease.outQuad, self)
end

function LU:Cleanup()
	local f = self.frame
	ns.CancelOwner(self)
	f.sparks:Clear()
	f.stars:Clear()
	f.shards:Clear()
	f.flash:SetAlpha(0)
	self.live, self.ready, self.closing = false, false, false
	f:SetAlpha(1)
	local done = self.opts and self.opts.done
	self.opts = nil
	if done then
		done()
	end
	-- the alerts that waited
	if ns.Toast and ns.Toast.Resume then
		ns.Toast:Resume()
	end
end

function LU:Showing()
	return self.frame ~= nil and self.frame:IsShown()
end
