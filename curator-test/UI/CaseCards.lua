local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) A card of a case as the grids show it (the inventory: UI/CaseInventory.lua; the album
-- of a collection and its contracts: UI/CaseAlbum.lua): small and still, nothing of the boosters' cards. The frame and
-- the ground of its rank (UI/CrateCard.lua: CrateRank*, CrateGround*), in its window its picture (a figure: its
-- portrait; a spell, an armour: its icon in a medallion, the ring of its rank round it; a weapon of legend: its icon in a
-- ring of gold; the golden card of the secret: its medal and its question mark), its wear (31 October: the pieces of
-- UI/Wear.lua, as on the cards of the boosters), its name and its rank on its plate; forged, the light of its finish along its edge and a gem of it; appraised, the plate of its grade; a count
-- ("x3"); a card the player has not yet: grey, dimmed.
-------------------------------------------------------------------------------
local CM = {}
ns.CaseCards = CM

local TW, TH = 512, 717
local WIN = { 24, 24, 488, 552 }
local PLATE = { 24, 566, 488, 693 }
local function TC(x0, y0, x1, y1, w, h)
	return (x0 + 0.5) / w, (x1 - 0.5) / w, (y0 + 0.5) / h, (y1 - 0.5) / h
end
local FRAME_TC = { TC(0, 0, 512, 717, 1024, 1024) }
-- the light of a finish along its edge, and its gem (the gems of the finishes of the albums)
local FIN = { thunder = { color = { 0.55, 0.8, 1 }, gem = "Gem7" }, titan = { color = { 1, 0.84, 0.46 }, gem = "Gem8" } }

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

local function Text(parent, size, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	ns.SetFont(fs, size, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 1)
	return fs
end

-- A texture over a rectangle of the card (in points of its texture: x0, y0, x1, y1 from its top left).
local function Place(t, f, x0, y0, x1, y1)
	local k = f.k
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", f, "TOPLEFT", x0 * k, -y0 * k)
	CuratorOctoFull.SetSize(t, math.max(0.01, (x1 - x0) * k), math.max(0.01, (y1 - y0) * k))
end

local M = {}
CM.methods = M

-- A small card of a case, w points wide.
function CM.New(parent, w)
	local h = w * TH / TW
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, w, h)
	f.W, f.H, f.k = w, h, w / TW
	local k = f.k
	f.glow = Tex(f, "BACKGROUND", -2, "CardGlow", "ADD")
	f.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(f.glow, w * 1.5, h * 1.3)
	f.glow:SetAlpha(0)
	f.ground = Tex(f, "BACKGROUND", 0)
	Place(f.ground, f, unpack(WIN))
	f.aura = Tex(f, "BACKGROUND", 1, "Glow", "ADD")
	f.aura:SetPoint("CENTER", f, "TOPLEFT", (WIN[1] + WIN[3]) / 2 * k, -(WIN[2] + (WIN[4] - WIN[2]) * 0.46) * k)
	local aw = (WIN[3] - WIN[1]) * k
	CuratorOctoFull.SetSize(f.aura, aw * 1.1, aw * 1.1)
	-- its portrait (all the window), else its icon in its medallion
	f.pic = f:CreateTexture(nil, "ARTWORK", nil, 0)
	Place(f.pic, f, unpack(WIN))
	local isz = aw * 0.5
	f.icon = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.icon:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(f.icon, isz, isz)
	f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	local round = CuratorOctoFull.CreateMaskTexture(f)
	round:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	round:SetAllPoints(f.icon)
	CuratorOctoFull.AddMaskTexture(f.icon, round)
	f.ring = Tex(f, "ARTWORK", 2, "IconRing")
	f.ring:SetPoint("CENTER", f.icon, "CENTER")
	CuratorOctoFull.SetSize(f.ring, isz * 1.24, isz * 1.24)
	f.medal = Tex(f, "ARTWORK", 2, "AchMedal")
	f.medal:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(f.medal, aw * 0.72, aw * 0.72)
	f.q = Text(f, math.max(12, 90 * k), "THICKOUTLINE")
	f.q:SetPoint("CENTER", f.medal, "CENTER", 0, 1)
	f.q:SetText("?")
	f.q:SetTextColor(1, 0.95, 0.72)
	-- over it: the shadow of the window's edges, its frame, its wear, its words
	local o = CreateFrame("Frame", nil, f)
	o:SetAllPoints()
	o:SetFrameLevel(f:GetFrameLevel() + 2)
	f.over = o
	f.vig = Tex(o, "BACKGROUND", 0, "Vignette")
	Place(f.vig, f, unpack(WIN))
	f.vig:SetVertexColor(0, 0, 0, 0.8)
	f.frame = Tex(o, "BORDER", 0)
	f.frame:SetAllPoints()
	f.edge = Tex(o, "ARTWORK", 1, "CardGlow", "ADD")
	f.edge:SetPoint("CENTER")
	CuratorOctoFull.SetSize(f.edge, w * 1.14, h * 1.1)
	f.edge:Hide()
	f.name = Text(o, math.max(7, 34 * k), "OUTLINE")
	f.name:SetPoint("CENTER", f, "TOPLEFT", (PLATE[1] + PLATE[3]) / 2 * k, -(PLATE[2] + 46) * k)
	f.name:SetWidth(430 * k)
	CuratorOctoFull.SetWordWrap(f.name, false)
	f.rank = Text(o, math.max(6.5, 25 * k), "OUTLINE")
	f.rank:SetPoint("CENTER", f, "TOPLEFT", (PLATE[1] + PLATE[3]) / 2 * k, -(PLATE[2] + 94) * k)
	f.rank:SetWidth(430 * k)
	CuratorOctoFull.SetWordWrap(f.rank, false)
	-- (its finish: its gem on its corner; appraised: the plate of its grade; a count)
	f.gem = Tex(o, "OVERLAY", 1)
	CuratorOctoFull.SetSize(f.gem, math.max(10, 64 * k), math.max(10, 64 * k))
	f.gem:SetPoint("CENTER", f, "TOPLEFT", 64 * k, -64 * k)
	f.gem:Hide()
	local gp = CreateFrame("Frame", nil, o)
	CuratorOctoFull.SetSize(gp, math.max(18, 104 * k), math.max(14, 70 * k))
	gp:SetPoint("CENTER", f, "TOPRIGHT", -60 * k, -60 * k)
	gp:SetFrameLevel(o:GetFrameLevel() + 2)
	gp.bg = gp:CreateTexture(nil, "BACKGROUND")
	gp.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(gp.bg, 0.94, 0.92, 0.86, 0.96)
	gp.edge = gp:CreateTexture(nil, "BORDER")
	gp.edge:SetPoint("BOTTOMLEFT")
	gp.edge:SetPoint("BOTTOMRIGHT")
	gp.edge:SetHeight(math.max(2, 10 * k))
	gp.text = gp:CreateFontString(nil, "OVERLAY")
	ns.SetFont(gp.text, math.max(8, 48 * k), "")
	gp.text:SetPoint("CENTER", 0, math.max(1, 3 * k))
	gp.text:SetTextColor(0.13, 0.09, 0.05)
	gp:Hide()
	f.grade = gp
	f.count = Text(o, math.max(9, 52 * k), "OUTLINE")
	f.count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30 * k, -26 * k)
	f.count:SetTextColor(1, 0.86, 0.4)
	f.count:Hide()
	-- (31 October, his word: worn as the cards of the boosters) its wear over its frame and its words, under its plate of
	-- grade and its count (UI/Wear.lua)
	local wf = CreateFrame("Frame", nil, f)
	wf:SetAllPoints()
	wf:SetFrameLevel(o:GetFrameLevel() + 1)
	wf:Hide()
	f.wearF = wf
	f.wearFlip, f.wearTurn = {}, {}
	-- (its count over its wear)
	local top = CreateFrame("Frame", nil, f)
	top:SetAllPoints()
	top:SetFrameLevel(o:GetFrameLevel() + 2)
	f.count:SetParent(top)
	for key, fn in pairs(M) do
		f[key] = fn
	end
	return f
end

-- Its rank (1 to 5): its frame, its ground, the light behind its picture.
function M:SetRank(tier)
	tier = math.max(1, math.min(5, tonumber(tier) or 1))
	self.tier = tier
	local file = MEDIA .. "CrateRank" .. tier
	self.frame:SetTexture(file)
	self.frame:SetTexCoord(unpack(FRAME_TC))
	self.ground:SetTexture(MEDIA .. "CrateGround" .. tier)
	self.ground:SetTexCoord(0, 1, 0, 1)
	local CR = ns.CrateUI
	local r = CR and CR.RANKS and CR.RANKS[tier]
	local col = (r and r.color) or { 1, 1, 1 }
	self.col = col
	self.aura:SetVertexColor(col[1], col[2], col[3], 0.4)
	self.ring:SetVertexColor(math.min(1, col[1] * 1.25 + 0.15), math.min(1, col[2] * 1.25 + 0.15), math.min(1, col[3] * 1.25 + 0.15), 0.95)
	local tc = (r and (r.text or r.color)) or col
	self.rank:SetText(r and L[r.label] or "")
	self.rank:SetTextColor(tc[1], tc[2], tc[3])
end

-- Dressed as a card of a case: x = { tier, entry (CrateItems.lua) or weapon ({ id, class, faction, line }) or secret,
-- wear (Cases.lua: CS.WearOf), finish ("thunder", "titan"), grade (appraised: its grade), count, missing }.
function M:Set(x)
	self.x = x
	self:SetRank(x.tier)
	local CI = ns.CrateItems
	local CC = ns.CrateCard
	local secret = x.secret and not x.weapon
	local entry = (not secret) and x.entry or nil
	local weapon = (not secret) and x.weapon or nil
	CuratorOctoFull.SetShown(self.medal, secret)
	CuratorOctoFull.SetShown(self.q, secret)
	self.pic:Hide()
	self.icon:Hide()
	self.ring:Hide()
	local name
	if secret then
		name = L["Priceless card"]
	elseif weapon then
		name = CC and CC.WeaponName(weapon) or nil
		self.icon:SetTexture((CC and CC.WeaponIcon(weapon)) or "Interface\\Icons\\INV_Misc_QuestionMark")
		self.icon:Show()
		self.ring:SetVertexColor(1, 0.84, 0.4, 1)
		self.ring:Show()
		name = name or L["Priceless card"]
	elseif entry then
		name = CI and CI:Name(entry) or "?"
		local portrait = entry.kind == "npc" and entry.display and SetPortraitTextureFromCreatureDisplayID
			and pcall(SetPortraitTextureFromCreatureDisplayID, self.pic, entry.display)
		if portrait then
			-- (the window taller than wide: the middle of the portrait)
			local ww, wh = WIN[3] - WIN[1], WIN[4] - WIN[2]
			local kk = (1 - ww / wh) / 2
			self.pic:SetTexCoord(kk, 1 - kk, 0, 1)
			self.pic:Show()
		else
			self.icon:SetTexture((CI and CI:Icon(entry)) or (entry.kind == "npc" and "Interface\\Icons\\Spell_Holy_HolyBolt") or "Interface\\Icons\\INV_Misc_QuestionMark")
			self.icon:Show()
			self.ring:Show()
		end
	end
	self.name:SetText(name or "")
	self.name:SetTextColor(1, 1, 1)
	self:FitName()
	if ns.WearUI then
		ns.WearUI.Set(self, (not secret) and x.wear or nil, true)
	end
	local fin = FIN[x.finish or ""]
	CuratorOctoFull.SetShown(self.gem, fin ~= nil)
	CuratorOctoFull.SetShown(self.edge, fin ~= nil)
	if fin then
		self.gem:SetTexture(MEDIA .. fin.gem)
		-- (1.14.0: titanforged, its edge in the colour of its pattern, Patterns.lua)
		local pat = x.finish == "titan" and ns.Patterns and ns.Patterns:Look(x.pt) or nil
		local col = fin.color
		if pat and pat.tint then
			col = { ns.Patterns.Color(pat, 0) }
		end
		self.edge:SetVertexColor(col[1], col[2], col[3], 0.55)
	end
	local g = tonumber(x.grade)
	CuratorOctoFull.SetShown(self.grade, g ~= nil)
	if g then
		local E = ns.Expertise
		local c = (E and E.Color(g)) or { 0.7, 0.7, 0.7 }
		self.grade.text:SetText(tostring(math.floor(g)))
		CuratorOctoFull.ColorTexture(self.grade.edge, c[1], c[2], c[3], 1)
	end
	CuratorOctoFull.SetShown(self.count, (tonumber(x.count) or 0) > 1)
	if (tonumber(x.count) or 0) > 1 then
		self.count:SetText("x" .. ns.Num(x.count))
	end
	self:SetMissing(x.missing)
end

-- Its name on its plate, made smaller until it fits; still too long, on two lines. A small card says its rank by its
-- colours only, its name in the middle of its plate; a larger one under its name.
local SMALL = 0.17
function M:FitName()
	local k = self.k
	local fs = self.name
	local room = 430 * k
	local small = k < SMALL
	local size = math.max(7, 34 * k)
	CuratorOctoFull.SetWordWrap(fs, false)
	ns.SetFont(fs, size, "OUTLINE")
	while size > 6 and ns.TextWidth(fs) > room do
		size = size - 0.5
		ns.SetFont(fs, size, "OUTLINE")
	end
	local two = ns.TextWidth(fs) > room
	CuratorOctoFull.SetWordWrap(fs, two)
	if fs.SetMaxLines then
		CuratorOctoFull.SetMaxLines(fs, two and 2 or 1)
	end
	local mid = (PLATE[1] + PLATE[3]) / 2 * k
	fs:ClearAllPoints()
	if small then
		fs:SetPoint("CENTER", self, "TOPLEFT", mid, -((PLATE[2] + PLATE[4]) / 2) * k)
	else
		fs:SetPoint("CENTER", self, "TOPLEFT", mid, -(PLATE[2] + (two and 52 or 46)) * k)
		self.rank:ClearAllPoints()
		self.rank:SetPoint("CENTER", self, "TOPLEFT", mid, -(PLATE[2] + (two and 106 or 94)) * k)
	end
	CuratorOctoFull.SetShown(self.rank, not small)
end

-- A card the player has not yet: grey and dimmed (on), or in its colours.
function M:SetMissing(on)
	on = on and true or false
	self.missing = on
	for _, t in ipairs({ self.ground, self.pic, self.icon, self.ring, self.frame, self.medal }) do
		t:SetDesaturated(on)
	end
	local a = on and 0.42 or 1
	for _, t in ipairs({ self.ground, self.pic, self.icon, self.frame, self.aura }) do
		t:SetAlpha(a)
	end
	self.name:SetAlpha(on and 0.6 or 1)
	self.rank:SetAlpha(on and 0.6 or 1)
end

-- The look of a card won (its record: Cases.lua): what M:Set takes.
function CM.Look(w, count)
	local CR = ns.CrateUI
	if not (w and CR) then
		return nil
	end
	local x = { tier = tonumber(w.r) or 1, wear = ns.Cases.WearOf(w), finish = w.f, grade = w.ap and tonumber(w.g) or nil, count = count,
		pt = ns.Cases.Pattern(w) }
	if w.w then
		x.tier = CR.TOP
		x.weapon = { id = w.w, line = w.l, class = w.cl, faction = w.fa }
		x.secret = true
	else
		x.entry = CM.Entry(w.c, w.e)
	end
	return x
end

-- The entry of a card of a case (its key: "s" a spell, "n" a figure, "a" an armour), else nil.
function CM.Entry(case, key)
	local CI = ns.CrateItems
	local own = CI and CI:Case(case or (ns.Cases and ns.Cases.EDITION) or "paladin1")
	for r = 1, 4 do
		for _, e in ipairs((own and own[r]) or {}) do
			if e.key == key then
				return e, r
			end
		end
	end
	return nil
end

-- Its name in the language of the game (a card won: its record).
function CM.Name(w)
	if not w then
		return ""
	end
	if w.w then
		local CC = ns.CrateCard
		return (CC and CC.WeaponName({ id = w.w })) or L["Priceless card"]
	end
	local e = CM.Entry(w.c, w.e)
	return (e and ns.CrateItems:Name(e)) or "?"
end
