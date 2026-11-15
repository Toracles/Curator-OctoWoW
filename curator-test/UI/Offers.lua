local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Ease = ns.Ease

-------------------------------------------------------------------------------
-- (1.14.0, his word) The screen of the rewards to choose (Level.lua: LV:Offers, LV:Choose): the three rewards of the
-- oldest waiting (a level, or what gave a booster to choose before: a quest, a battleground, an inn...), on the whole
-- screen, as they will come: the pack of the booster of its album (golden: in gold), the case turning in the air, the
-- card itself (dealt face down, then turned over), the rubies. One taken: its light bursts, the two others fall away,
-- the next one is dealt. (After its first test, his word: the window of before was too plain.) From the screen of a
-- level reached (UI/LevelUp.lua), the track of the rewards (UI/Profile.lua), the panel of the rewards to choose of the
-- inventory and of the quests (UI/Boosters.lua), or /curator reward.
-------------------------------------------------------------------------------
local OU = {}
ns.OffersUI = OU

-- a reward: its size, the gap between two, the middle of its picture (from its top), where the row stands
local CW, CH, GAP = 250, 420, 34
local ART_Y = -162
local ROW_Y = 162
local GOLD, DIM, RED = { 1, 0.82, 0.25 }, { 0.72, 0.72, 0.78 }, { 1, 0.42, 0.34 }
local GOLDEN = { 1, 0.84, 0.35 }

-- each kind of reward: its word on top, its colour (a booster of a zone: the colour of its album; a card: of its rarity)
local KIND = {
	booster = { tag = "Zone booster", color = { 0.45, 0.95, 0.55 } },
	dungeon = { tag = "Dungeon booster", color = { 0.42, 0.66, 1 } },
	raid = { tag = "Raid booster", color = { 1, 0.52, 0.22 } },
	golden = { tag = "Golden booster", color = GOLDEN },
	case = { tag = "Case", color = { 1, 0.72, 0.3 } },
	rubies = { tag = "Rubies", color = { 1, 0.32, 0.42 } },
	card = { tag = "Card", color = { 0.9, 0.9, 1 } },
}
-- (the words of before, for the chat and the tooltips)
local NAME = {
	booster = "A booster", case = "A case", rubies = "Rubies", card = "A card",
	dungeon = "A booster of a dungeon", raid = "A booster of a raid", golden = "A golden booster",
}
local PACK = { booster = "zone", dungeon = "dungeon", raid = "raid", golden = "golden" }

local function Def(o)
	return ns.Crates and o.e and ns.Crates[o.e] or nil
end

-- What a reward is, in words: its name, its line under it, the colour of its name, its icon (and the part of it).
function OU.Describe(o)
	local LV, C = ns.Level, ns.Collection
	local k = o.k
	if k == "rubies" then
		return L[NAME.rubies], ns.Rubies.Text(o.n, 16), GOLD, ns.Rubies.ICON
	elseif k == "case" then
		local def = Def(o)
		local box = def and def.art and def.art.box
		local line = (def and L[def.title or ""] or "") .. "\n" .. string.format(L["It opens with a key: %s."], ns.Rubies.Text(ns.Cases:KeyPrice(), 12))
		return L[NAME.case], line, { 1, 0.84, 0.26 }, MEDIA .. (box and ns.CaseTexture(box .. "Top") or "CrateTop"), { 0.209, 0.791, 0, 0.582 }
	elseif k == "card" then
		local card = LV.OptionCard(o)
		if not card then
			return L[NAME.card], "", DIM, MEDIA .. "Gem1"
		end
		local rar = ns.RARITY[card.rarity] or ns.RARITY[1]
		local fin = C:FinishName(card, o.f)
		local line = L[rar.label] .. (fin and (" · " .. fin) or "") .. "\n" .. C:SeriesName(card.series)
		return C:Name(card), line, rar.text, MEDIA .. "Gem" .. card.rarity
	end
	local s = LV.OptionAlbum(o)
	return L[NAME[k] or "A booster"], s and C:SeriesName(s) or "", k == "golden" and { 1, 0.86, 0.3 } or { 0.95, 0.92, 0.85 },
		ns.Hud.PackIcon(PACK[k])
end

-- The colour of a reward (its light, its rays, its frame).
local function ColorOf(o)
	if o.k == "card" then
		local card = ns.Level.OptionCard(o)
		local rar = card and ns.RARITY[card.rarity]
		return rar and rar.glow or KIND.card.color
	elseif o.k == "booster" then
		local s = ns.Level.OptionAlbum(o)
		return (s and s.glow) or KIND.booster.color
	end
	return (KIND[o.k] or KIND.card).color
end

-- A reward of the finest: a golden booster, a card legendary or better, a forged one (sparks rise around it).
local function Fine(o)
	if o.k == "golden" then
		return true
	end
	local card = o.k == "card" and ns.Level.OptionCard(o)
	return card and (card.rarity >= 5 or o.f ~= nil) or false
end

-- A reward taken, said in the chat: "Reward of level 12: a booster (Elwynn Forest)."
local function Said(lv, o, got)
	local name, line = OU.Describe(o)
	local what
	if o.k == "rubies" then
		what = ns.Rubies.Text(tonumber(got) or o.n, 12)
	elseif o.k == "card" then
		what = name .. " (" .. string.gsub(line, "\n", ", ") .. ")"
	elseif o.k == "case" then
		what = name
	else
		what = name .. " (" .. line .. ")"
	end
	if lv then
		ns.Print(string.format(L["Reward of level %d: %s."], lv, what))
	else
		ns.Print(string.format(L["Reward chosen: %s."], what))
	end
end

-- A texture drawn smooth: not snapped to the pixels of the screen (snapped, a texture made bigger, turned
-- or moved looks in steps).
local function Smooth(t)
	if t.SetSnapToPixelGrid then
		t:SetSnapToPixelGrid(false)
		t:SetTexelSnappingBias(0)
	end
	return t
end

-- Every texture of a frame and of the frames in it, smooth.
local function SmoothAll(frame)
	if frame.GetRegions then
		for _, r in ipairs({ frame:GetRegions() }) do
			Smooth(r)
		end
	end
	if frame.GetChildren then
		for _, c in ipairs({ frame:GetChildren() }) do
			SmoothAll(c)
		end
	end
end

local function Tex(parent, layer, sub, file, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
	if blend then
		t:SetBlendMode(blend)
	end
	return Smooth(t)
end

-- A frame of a texture of 512 x 128 (QuestCard, QuestGlow) around a frame of any size, in nine pieces: its
-- corners (c points of the texture each) as they are, k points of the screen a point of the texture, its
-- edges stretched along them, its middle stretched evenly (a part of the texture as wide as it must be).
-- out: this far outside the frame. The pieces.
local function Frame9(f, file, c, k, out, w, h, layer, sub, blend)
	local cw = c * k
	local u = { 0, c / 512, 1 - c / 512, 1 }
	local v = { 0, c / 128, 1 - c / 128, 1 }
	-- (the middle: as many points of the texture across as down, so that its grain is not drawn out)
	local midW, midH = w + 2 * out - 2 * cw, h + 2 * out - 2 * cw
	local span = math.min(1 - 2 * c / 512, (128 - 2 * c) / 512 * midW / math.max(1, midH))
	local mu = { c / 512, c / 512 + span }
	local t = {}
	for row = 1, 3 do
		for col = 1, 3 do
			local x = Tex(f, layer, sub, file, blend)
			if row == 2 and col == 2 then
				x:SetTexCoord(mu[1], mu[2], v[2], v[3])
			else
				x:SetTexCoord(u[col], u[col + 1], v[row], v[row + 1])
			end
			t[(row - 1) * 3 + col] = x
		end
	end
	t[1]:SetPoint("TOPLEFT", -out, out)
	t[3]:SetPoint("TOPRIGHT", out, out)
	t[7]:SetPoint("BOTTOMLEFT", -out, -out)
	t[9]:SetPoint("BOTTOMRIGHT", out, -out)
	for _, i in ipairs({ 1, 3, 7, 9 }) do
		CuratorOctoFull.SetSize(t[i], cw, cw)
	end
	t[2]:SetPoint("TOPLEFT", t[1], "TOPRIGHT")
	t[2]:SetPoint("BOTTOMRIGHT", t[3], "BOTTOMLEFT")
	t[8]:SetPoint("TOPLEFT", t[7], "TOPRIGHT")
	t[8]:SetPoint("BOTTOMRIGHT", t[9], "BOTTOMLEFT")
	t[4]:SetPoint("TOPLEFT", t[1], "BOTTOMLEFT")
	t[4]:SetPoint("BOTTOMRIGHT", t[7], "TOPRIGHT")
	t[6]:SetPoint("TOPLEFT", t[3], "BOTTOMLEFT")
	t[6]:SetPoint("BOTTOMRIGHT", t[9], "TOPRIGHT")
	t[5]:SetPoint("TOPLEFT", t[1], "BOTTOMRIGHT")
	t[5]:SetPoint("BOTTOMRIGHT", t[9], "TOPLEFT")
	return t
end

-------------------------------------------------------------------------------
-- A reward: its frame of gold, its word, its light, its picture, its name, its line, its button
-------------------------------------------------------------------------------
local function NewSlot(stage, i)
	local s = CreateFrame("Frame", nil, stage)
	CuratorOctoFull.SetSize(s, CW, CH)
	s.i = i
	s:EnableMouse(true)
	-- the dark card, its thin line of gold (its corners as drawn: 16 points of the texture, 12 of the screen)
	s.bg = Frame9(s, "QuestCard", 16, 0.75, 0, CW, CH, "BACKGROUND")
	-- (the light of its frame, on its line of gold: in the colour of the reward, bright under the mouse;
	-- the ring of the texture lies 14 points inside it, the line of gold 3.75 inside the card)
	s.edge = Frame9(s, "QuestGlow", 40, 1, 14 - 3.75, CW, CH, "BORDER", 0, "ADD")
	ns.Hud.Each(s.edge, "SetVertexColor", 1, 0.8, 0.32)
	ns.Hud.Each(s.edge, "SetAlpha", 0)
	-- (its corners of gold)
	s.corners = {}
	for k, c in ipairs({ { "TOPLEFT", 0, 1, 0, 1, -9, 9 }, { "TOPRIGHT", 1, 0, 0, 1, 9, 9 }, { "BOTTOMLEFT", 0, 1, 1, 0, -9, -9 }, { "BOTTOMRIGHT", 1, 0, 1, 0, 9, -9 } }) do
		local t = Tex(s, "OVERLAY", 1, "GoldCorner")
		t:SetTexCoord(c[2], c[3], c[4], c[5])
		CuratorOctoFull.SetSize(t, 58, 58)
		t:SetPoint(c[1], c[6], c[7])
		s.corners[k] = t
	end
	-- the light of its kind, behind its picture: two crowns of rays turning, a glow
	s.rays = Tex(s, "BORDER", 1, "Rays", "ADD")
	CuratorOctoFull.SetSize(s.rays, 330, 330)
	s.rays:SetPoint("CENTER", s, "TOP", 0, ART_Y)
	s.rays2 = Tex(s, "BORDER", 2, "Rays", "ADD")
	CuratorOctoFull.SetSize(s.rays2, 230, 230)
	s.rays2:SetPoint("CENTER", s, "TOP", 0, ART_Y)
	s.light = Tex(s, "BORDER", 3, "Glow", "ADD")
	CuratorOctoFull.SetSize(s.light, 250, 250)
	s.light:SetPoint("CENTER", s, "TOP", 0, ART_Y)
	s.phase = i * 1.7
	-- its word, a thin line under it
	s.tag = ns.Hud.Text(s, 13, "OUTLINE", "OVERLAY")
	s.tag:SetPoint("TOP", 0, -40)
	s.rule = Tex(s, "OVERLAY")
	CuratorOctoFull.ColorTexture(s.rule, 1, 1, 1, 1)
	CuratorOctoFull.SetSize(s.rule, 120, 1)
	s.rule:SetPoint("TOP", 0, -61)
	-- the picture: one of these, made the first time it is needed (s.art: the one shown)
	s.holder = CreateFrame("Frame", nil, s)
	CuratorOctoFull.SetSize(s.holder, CW, 210)
	s.holder:SetPoint("CENTER", s, "TOP", 0, ART_Y)
	s.holder:SetFrameLevel(s:GetFrameLevel() + 3)
	-- its name, its line
	s.name = ns.Hud.Text(s, 17, "OUTLINE", "OVERLAY")
	s.name:SetPoint("TOP", 0, -266)
	s.name:SetWidth(CW - 24)
	CuratorOctoFull.SetWordWrap(s.name, true)
	s.line = S.Text(s, "GameFontHighlightSmall", "CENTER", "OVERLAY")
	s.line:SetPoint("TOP", s.name, "BOTTOM", 0, -7)
	s.line:SetWidth(CW - 30)
	CuratorOctoFull.SetWordWrap(s.line, true)
	s.line:SetSpacing(3)
	-- what you have of it now: the cards of its album (a bar), your copies of the card, your cases and keys, your rubies
	s.bar = S.ThinBar(s, 184, 15)
	s.bar:SetPoint("BOTTOM", 0, 66)
	s.bar:Hide()
	-- (its words over the bar: on a frame above it)
	local over = CreateFrame("Frame", nil, s)
	over:SetAllPoints(s.bar)
	over:SetFrameLevel(s.bar:GetFrameLevel() + 2)
	s.info = ns.Hud.Text(over, 12, "OUTLINE", "OVERLAY")
	s.info:SetPoint("CENTER", over, "CENTER", 0, 0)
	s.info:SetWidth(CW - 20)
	s.take = ns.Hud.ClaimButton(s, 180, 36, L["Take"])
	s.take:SetPoint("BOTTOM", 0, 18)
	s.take:SetFrameLevel(s:GetFrameLevel() + 6)
	CuratorOctoFull.SetScript(s.take, "OnClick", function()
		OU:Take(i)
	end)
	CuratorOctoFull.SetScript(s, "OnEnter", function(self)
		OU:SlotTooltip(self)
	end)
	CuratorOctoFull.SetScript(s, "OnLeave", function()
		GameTooltip:Hide()
	end)
	s.take:HookScript("OnEnter", function()
		OU:SlotTooltip(s)
	end)
	s.take:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	s.lift, s.dy, s.hot = 0, 0, 0
	return s
end

-- The picture of a kind, made once for this slot.
local function Art(s, kind)
	s.arts = s.arts or {}
	local a = s.arts[kind]
	if a then
		return a
	end
	if kind == "pack" then
		a = ns.Hud.Pack(s.holder, 98, true)
		a:SetPoint("CENTER", 0, 4)
		a.bob, a.lift0 = 4, 0
	elseif kind == "case" then
		a = ns.CrateBox.New(s.holder, 214)
		a:SetPoint("CENTER", 0, -4)
		a:SetFrameLevel(s.holder:GetFrameLevel() + 1)
		a:Paint()
	elseif kind == "card" then
		a = ns.NewCard(s.holder, "mid")
		a:SetPoint("CENTER", 0, 2)
		CuratorOctoFull.SetScript(a, "OnClick", nil)
		CuratorOctoFull.SetScript(a, "OnEnter", function()
			OU:SlotTooltip(s)
		end)
		CuratorOctoFull.SetScript(a, "OnLeave", function()
			GameTooltip:Hide()
		end)
	elseif kind == "rubies" then
		a = CreateFrame("Frame", nil, s.holder)
		CuratorOctoFull.SetSize(a, 170, 170)
		a:SetPoint("CENTER")
		-- (three gems, the biggest in front, and their light)
		a.back1 = a:CreateTexture(nil, "ARTWORK", nil, 0)
		a.back1:SetTexture(MEDIA .. "RubyBig")
		CuratorOctoFull.SetSize(a.back1, 70, 70)
		a.back1:SetPoint("CENTER", -46, -18)
		CuratorOctoFull.SetRotation(a.back1, 0.35)
		a.back2 = a:CreateTexture(nil, "ARTWORK", nil, 0)
		a.back2:SetTexture(MEDIA .. "RubyBig")
		CuratorOctoFull.SetSize(a.back2, 64, 64)
		a.back2:SetPoint("CENTER", 48, -22)
		CuratorOctoFull.SetRotation(a.back2, -0.4)
		a.gem = a:CreateTexture(nil, "ARTWORK", nil, 1)
		a.gem:SetTexture(MEDIA .. "RubyBig")
		CuratorOctoFull.SetSize(a.gem, 118, 118)
		a.gem:SetPoint("CENTER", 0, 8)
		a.shine = a:CreateTexture(nil, "ARTWORK", nil, 2)
		a.shine:SetTexture(MEDIA .. "Twinkle")
		a.shine:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(a.shine, 44, 44)
		a.shine:SetPoint("CENTER", -22, 34)
		a.amount = ns.Hud.Text(a, 26, "THICKOUTLINE", "OVERLAY")
		a.amount:SetPoint("CENTER", 0, -66)
		a.amount:SetTextColor(1, 0.9, 0.9)
	end
	-- (its textures smooth too: made bigger or turned, never in steps)
	SmoothAll(a)
	s.arts[kind] = a
	return a
end

-- The picture of a reward shown in its slot (the others of the slot hidden).
local function ShowArt(s, o, reveal)
	local want = (o.k == "case" and "case") or (o.k == "card" and "card") or (o.k == "rubies" and "rubies") or "pack"
	for kind, a in pairs(s.arts or {}) do
		if kind ~= want then
			a:Hide()
			if kind == "case" and a.SetIdle then
				a:SetIdle(false)
			end
		end
	end
	local a = Art(s, want)
	a:Show()
	a:SetAlpha(1)
	if want == "pack" then
		local sr = ns.Level.OptionAlbum(o)
		a:SetSeries(sr)
		local gold = o.k == "golden"
		for _, t in ipairs({ a.body, a.top }) do
			t:SetDesaturated(gold)
			if gold then
				t:SetVertexColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
			else
				t:SetVertexColor(1, 1, 1)
			end
		end
		local c = ColorOf(o)
		a.glow:SetVertexColor(c[1], c[2], c[3])
		a.glow:SetAlpha(gold and 0.5 or 0.36)
	elseif want == "case" then
		local def = Def(o)
		a:SetArt(def and def.art and def.art.box or nil)
		a:SetIdle(true)
	elseif want == "card" then
		local card = ns.Level.OptionCard(o)
		if card then
			a:SetCard(card, { owned = true, finish = o.f, new = not ns.Collection:Owned(card) })
			-- (dealt face down, turned over as the screen opens)
			a:ShowSide(reveal and "back" or "front")
		end
	elseif want == "rubies" then
		a.amount:SetText(ns.Num(o.n or 0))
	end
	s.art, s.artKind = a, want
	return a
end

-------------------------------------------------------------------------------
-- The screen
-------------------------------------------------------------------------------
function OU:Build()
	if self.frame then
		return self.frame
	end
	local Hud = ns.Hud
	local f = CreateFrame("Frame", "CuratorOffers", UIParent)
	f:SetAllPoints()
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(250)
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorOffers")
	f.dark = Tex(f, "BACKGROUND")
	f.dark:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.dark, 0.01, 0.01, 0.02, 0.86)
	f.vig = Tex(f, "BACKGROUND", 1, "Vignette")
	f.vig:SetAllPoints()

	local st = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(st, 3 * CW + 2 * GAP + 40, 720)
	st:SetPoint("CENTER", 0, 6)
	f.stage = st
	-- the head: its rays, its emblem (the rank of the level) or the icon of a reward, its words
	f.rays = Tex(st, "BACKGROUND", 2, "Rays", "ADD")
	CuratorOctoFull.SetSize(f.rays, 720, 720)
	f.rays:SetPoint("CENTER", st, "TOP", 0, -78)
	f.rays:SetVertexColor(1, 0.78, 0.36)
	f.rays:SetAlpha(0.16)
	f.halo = Tex(st, "BACKGROUND", 3, "Glow", "ADD")
	CuratorOctoFull.SetSize(f.halo, 420, 220)
	f.halo:SetPoint("CENTER", st, "TOP", 0, -84)
	f.halo:SetVertexColor(1, 0.72, 0.3)
	f.halo:SetAlpha(0.3)
	f.emblem = Hud.Emblem(st, 64)
	f.emblem:SetPoint("CENTER", st, "TOP", 0, -36)
	f.icon = Tex(st, "ARTWORK", 1)
	CuratorOctoFull.SetSize(f.icon, 52, 52)
	f.icon:SetPoint("CENTER", st, "TOP", 0, -36)
	f.ring = Tex(st, "ARTWORK", 2, "IconRing")
	CuratorOctoFull.SetSize(f.ring, 76, 76)
	f.ring:SetPoint("CENTER", f.icon, "CENTER")
	f.head = Hud.Text(st, 30, "THICKOUTLINE", "OVERLAY")
	f.head:SetPoint("TOP", st, "TOP", 0, -72)
	f.head:SetTextColor(1, 0.86, 0.42)
	f.sub = Hud.Text(st, 16, "OUTLINE", "OVERLAY")
	f.sub:SetPoint("TOP", f.head, "BOTTOM", 0, -6)
	f.sub:SetTextColor(1, 0.96, 0.88)
	f.hint = S.Text(st, "GameFontHighlightSmall", "CENTER", "OVERLAY")
	f.hint:SetPoint("TOP", f.sub, "BOTTOM", 0, -5)
	f.hint:SetTextColor(DIM[1], DIM[2], DIM[3])

	f.slots = {}
	for i = 1, ns.Level.OFFER_SIZE do
		f.slots[i] = NewSlot(st, i)
	end
	-- the foot: the rewards that wait after these (a pip each), why nothing can be taken, later
	f.queue = Hud.Text(st, 13, "OUTLINE", "OVERLAY")
	f.queue:SetPoint("BOTTOM", st, "BOTTOM", 0, 104)
	f.queue:SetTextColor(1, 0.86, 0.5)
	f.pips = {}
	for i = 1, 10 do
		local p = Tex(st, "OVERLAY", 1, "Glow", "ADD")
		CuratorOctoFull.SetSize(p, 14, 14)
		f.pips[i] = p
	end
	f.note = S.Text(st, "GameFontHighlight", "CENTER", "OVERLAY")
	f.note:SetPoint("BOTTOM", st, "BOTTOM", 0, 56)
	f.note:SetWidth(3 * CW)
	CuratorOctoFull.SetWordWrap(f.note, true)
	f.note:SetTextColor(RED[1], RED[2], RED[3])
	f.later = S.Button(st, L["Later"], 140, 24)
	f.later:SetPoint("BOTTOM", st, "BOTTOM", 0, 20)
	CuratorOctoFull.SetScript(f.later, "OnClick", function()
		OU:Hide()
	end)

	f.sparks = ns.Particles:New(st, 90, "Spark")
	f.stars = ns.Particles:New(st, 50, "Twinkle")

	CuratorOctoFull.SetScript(f, "OnHide", function()
		ns.CancelOwner(OU)
		f.sparks:Clear()
		f.stars:Clear()
		OU.busy, OU.closing = false, false
		f:SetAlpha(1)
		for _, s in ipairs(f.slots) do
			if s.arts and s.arts.case then
				s.arts.case:SetIdle(false)
			end
		end
		GameTooltip:Hide()
	end)
	f.t = 0
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
		OU:Tick(elapsed)
	end)
	SmoothAll(f)
	self.frame = f
	return f
end

-- Every frame: the rays turn, a reward under the mouse rises and glows, the finest ones throw sparks.
function OU:Tick(elapsed)
	local f = self.frame
	f.t = f.t + elapsed
	local t = f.t
	CuratorOctoFull.SetRotation(f.rays, t * 0.05)
	for _, s in ipairs(f.slots) do
		if s:IsShown() then
			CuratorOctoFull.SetRotation(s.rays, s.phase + t * 0.16)
			CuratorOctoFull.SetRotation(s.rays2, -s.phase - t * 0.24)
			local over = not self.busy and s.ok and s:IsMouseOver() and 1 or 0
			s.hot = s.hot + (over - s.hot) * math.min(1, elapsed * 9)
			s.lift = s.hot * 10
			s:ClearAllPoints()
			s:SetPoint("TOP", self.frame.stage, "TOP", s.x0 or 0, -ROW_Y + s.lift + s.dy)
			local k = s.k or 1
			s.light:SetAlpha(math.min(1, (0.34 + 0.22 * s.hot) * k * (0.9 + 0.1 * math.sin(t * 2 + s.phase))))
			s.rays:SetAlpha(math.min(1, (0.2 + 0.18 * s.hot) * k))
			s.rays2:SetAlpha(math.min(1, (0.12 + 0.14 * s.hot) * k))
			ns.Hud.Each(s.edge, "SetAlpha", math.min(1, (0.18 + 0.82 * s.hot) * k))
			-- (the finest: a few sparks rising around them)
			if s.fine and not self.busy then
				s.spark = (s.spark or 0) + elapsed
				if s.spark > 0.22 then
					s.spark = 0
					local c = s.color or GOLD
					f.stars:Rise((s.x0 or 0) - 90, (s.x0 or 0) + 90, f.stage:GetHeight() / 2 - ROW_Y + ART_Y - 70 + s.dy, c, 1, 150, 1.5, 11)
				end
			end
		end
	end
end

-- The oldest reward waiting, shown (deal: dealt as the screen opens, or after one taken); nothing waiting: it goes.
function OU:Paint(deal)
	local f = self.frame
	local LV = ns.Level
	local list = LV:Offers()
	local offer = list[1]
	if not offer then
		self:Hide()
		return
	end
	local opts = type(offer.o) == "table" and offer.o or {}
	-- the head: a level (its rank), or a reward of a quest, an inn... (the icon of what it promised)
	if offer.lv then
		local r = LV.RankOf(tonumber(offer.lv) or 1)
		f.emblem:SetRank(r)
		f.emblem:Show()
		f.icon:Hide()
		f.ring:Hide()
		f.head:SetText(string.format(L["Level %d"], tonumber(offer.lv) or 0))
	else
		f.emblem:Hide()
		f.icon:SetTexture(ns.Hud.PackIcon(offer.p or "offer"))
		f.icon:Show()
		f.ring:Show()
		f.head:SetText(L["A reward to choose"])
	end
	f.sub:SetText(L["Choose your reward"])
	f.hint:SetText(L["Take one of these rewards: the others go."])
	-- the foot: those waiting after it
	local more = CuratorOctoFull.Length(list) - 1
	f.queue:SetText(more > 0 and (more == 1 and L["1 more reward waits."] or string.format(L["%d more rewards wait."], more)) or "")
	local pips = math.min(CuratorOctoFull.Length(list), CuratorOctoFull.Length(f.pips))
	for i, p in ipairs(f.pips) do
		CuratorOctoFull.SetShown(p, CuratorOctoFull.Length(list) > 1 and i <= pips)
		p:ClearAllPoints()
		p:SetPoint("BOTTOM", f.stage, "BOTTOM", (i - (pips + 1) / 2) * 16, 86)
		if i == 1 then
			p:SetVertexColor(1, 0.86, 0.4)
			p:SetAlpha(1)
		else
			p:SetVertexColor(0.7, 0.7, 0.8)
			p:SetAlpha(0.45)
		end
	end
	-- (a reroll chooses none; the cards changed by another addon this session: nothing comes)
	local RR = ns.Reroll
	local why
	if RR and RR:Blocks("choice") then
		why = string.format(L["This character is a reroll: until level %d, it chooses no reward. Choose them with your main character."], RR.LEVEL or 15)
	elseif ns.Guard and not ns.Guard:Allow() then
		why = L["Curator gives nothing until /reload: another addon changed its cards."]
	end
	f.note:SetText(why or "")
	-- the rewards, side by side
	local n = math.min(CuratorOctoFull.Length(opts), CuratorOctoFull.Length(f.slots))
	local x0 = -((n * CW + (n - 1) * GAP) / 2) + CW / 2
	for i, s in ipairs(f.slots) do
		local o = opts[i]
		CuratorOctoFull.SetShown(s, o ~= nil)
		s.o = o
		if o then
			s.x0 = x0 + (i - 1) * (CW + GAP)
			local name, line, color = OU.Describe(o)
			local c = ColorOf(o)
			s.color = c
			s.fine = Fine(o)
			s.tag:SetText(L[(KIND[o.k] or KIND.card).tag])
			s.tag:SetTextColor(c[1], c[2], c[3])
			s.rule:SetVertexColor(c[1], c[2], c[3])
			s.rule:SetAlpha(0.55)
			for _, tx in ipairs({ s.rays, s.rays2, s.light }) do
				tx:SetVertexColor(c[1], c[2], c[3])
			end
			ns.Hud.Each(s.edge, "SetVertexColor", c[1], c[2], c[3])
			s.name:SetText(name)
			s.name:SetTextColor(color[1], color[2], color[3])
			s.bar:Hide()
			s.info:SetText("")
			s.info:SetTextColor(0.86, 0.86, 0.9)
			-- (a booster: its album as its name, where it is, the cards of it you have; a golden one: what it holds; a
			-- case: its edition, its key; the card: whether you have it; the rubies: those you have)
			if PACK[o.k] then
				local sr = ns.Level.OptionAlbum(o)
				local C = ns.Collection
				if sr then
					s.name:SetText(C:SeriesName(sr))
					s.name:SetTextColor(o.k == "golden" and GOLDEN[1] or 1, o.k == "golden" and GOLDEN[2] or 0.94, o.k == "golden" and GOLDEN[3] or 0.82)
					local owned, total = C:Progress(sr)
					s.info:SetText(string.format(L["%d / %d cards"], owned, total))
					s.bar:SetStatusBarColor(c[1], c[2], c[3])
					s.bar:SetProgress(total > 0 and owned / total or 0)
					s.bar:Show()
				end
				local sub = (sr and ns.Album and ns.Album.SubLine) and ns.Album:SubLine(sr) or ""
				if o.k == "golden" then
					sub = L["5 cards, every one epic or better, for an album not complete yet."]
				end
				s.line:SetText(sub)
			elseif o.k == "rubies" then
				s.line:SetText("")
				s.info:SetText(string.format(L["Your rubies: %s"], ns.Rubies.Text(ns.Rubies:Balance(), 12)))
			elseif o.k == "case" then
				local def = Def(o)
				if def then
					s.name:SetText(L[def.title or ""])
				end
				s.line:SetText(string.format(L["It opens with a key: %s."], ns.Rubies.Text(ns.Cases:KeyPrice(), 12)))
				s.info:SetText(string.format(L["Cases to open: %d  ·  Keys: %d"], ns.Cases:Count(o.e), ns.Cases:Keys(o.e)))
			else
				s.line:SetText(line)
				local card = ns.Level.OptionCard(o)
				local e = card and ns.Collection:Entry(card)
				if e and (e.n or 0) > 0 then
					s.info:SetText(string.format(L["Copies: %d"], e.n))
				elseif card then
					s.info:SetText(L["Not in your album yet"])
					s.info:SetTextColor(1, 0.86, 0.4)
				end
			end
			local ok = LV:OptionOk(o)
			s.ok = ok and not why
			CuratorOctoFull.SetEnabled(s.take, ok and not why)
			s.take:SetPulse(ok and not why)
			s.k = ok and 1 or 0.35
			ShowArt(s, o, deal and o.k == "card")
			if not ok then
				s.line:SetText(L["No longer available"])
				s.name:SetTextColor(0.55, 0.55, 0.58)
			end
			s:SetAlpha(1)
			s.dy = 0
		end
	end
	if deal then
		self:Deal(n)
	end
end

-- The rewards dealt: each rises into its place in turn, a card turned over after it, its light bursting.
function OU:Deal(n)
	local f = self.frame
	local cy = f.stage:GetHeight() / 2 - ROW_Y + ART_Y
	for i = 1, n do
		local i = i; local s = f.slots[i]
		s:SetAlpha(0)
		s.dy = -36
		local d = 0.06 + 0.11 * (i - 1)
		ns.Tween(0.42, function(e, raw)
			s:SetAlpha(math.min(1, raw * 1.6))
			s.dy = -36 * (1 - e)
		end, nil, Ease.outBack, OU, d)
		ns.Delay(d + 0.12, function()
			ns.Play(ns.SND.cardLand)
			local c = s.color or GOLD
			f.sparks:Burst(s.x0 or 0, cy, c, s.fine and 26 or 12, s.fine and 220 or 150, 0.7, 14)
		end, OU)
		local o = s.o
		if o and o.k == "card" and s.art and s.artKind == "card" then
			local card = ns.Level.OptionCard(o)
			ns.Delay(d + 0.55, function()
				if not (s.o == o and s.art.Flip) then
					return
				end
				ns.Play(ns.SND.cardFlip)
				s.art:Flip(0.42, nil, function()
					local r = card and card.rarity or 1
					local snd = ns.SND.reveal and ns.SND.reveal[r]
					if snd then
						ns.Play(snd)
					end
					local c = s.color or GOLD
					f.stars:Burst(s.x0 or 0, cy, c, 8 + r * 4, 120 + r * 25, 0.9, 16)
				end, OU)
			end, OU)
		end
	end
end

function OU:SlotTooltip(s)
	local o = s.o
	if not o then
		return
	end
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if o.k == "card" and ns.Level.OptionCard(o) then
		local card = ns.Level.OptionCard(o)
		if ns.Links and ns.Links.AddLines then
			ns.Links:AddLines(GameTooltip, card, o.f)
		else
			GameTooltip:AddLine(ns.Collection:Name(card), 1, 1, 1)
		end
	else
		local name, line, color = OU.Describe(o)
		GameTooltip:AddLine(name, color[1], color[2], color[3])
		if line ~= "" then
			GameTooltip:AddLine(line, 1, 1, 1, true)
		end
	end
	if o.k == "case" then
		GameTooltip:AddLine(L["It goes with your cases (/curator cases)."], DIM[1], DIM[2], DIM[3], true)
	elseif PACK[o.k] then
		GameTooltip:AddLine(L["It goes to your boosters, in this album."], DIM[1], DIM[2], DIM[3], true)
	end
	GameTooltip:AddLine(L["Take it: the others go."], 0.3, 1, 0.3, true)
	GameTooltip:Show()
end

-- A reward taken (the oldest waiting, its i-th): its light bursts, the others fall away, then the next one, or the
-- screen goes.
function OU:Take(i)
	if self.busy then
		return
	end
	local LV = ns.Level
	local f = self.frame
	local offer = LV:Offers()[1]
	-- (busy before it is given: what it gives and the offer after it say so at once by their events, and the
	-- rewards after it must not show in the slots before they are dealt: no glimpse of them)
	self.busy = true
	local ok, o, got = LV:Choose(1, i)
	GameTooltip:Hide()
	if not ok then
		self.busy = false
		ns.Play(ns.SND.page)
		self:Paint()
		return
	end
	local s = f.slots[i]
	local c = s.color or GOLD
	local cy = f.stage:GetHeight() / 2 - ROW_Y + ART_Y + s.lift
	ns.Play(ns.SND.claim)
	if o.k == "rubies" then
		ns.Play(ns.SND.coins)
	elseif Fine(o) then
		ns.Play(ns.SND.holo)
	end
	Said(offer and offer.lv, o, got)
	f.sparks:Burst(s.x0 or 0, cy, c, 40, 280, 0.9, 18)
	f.stars:Burst(s.x0 or 0, cy, { 1, 0.95, 0.8 }, 14, 200, 1.1, 22)
	CuratorOctoFull.SetEnabled(s.take, false)
	s.take:SetPulse(false)
	-- the one taken: its light swells, then it goes up and fades
	ns.Tween(0.7, function(e, raw)
		s.k = 1 + 1.2 * math.sin(math.pi * math.min(1, raw * 1.6))
		s.dy = 26 * e
		s:SetAlpha(raw < 0.55 and 1 or (1 - (raw - 0.55) / 0.45))
	end, nil, Ease.outQuad, OU, 0.05)
	-- the others: down and away
	for j, other in ipairs(f.slots) do
		local j, other = j, other; if j ~= i and other:IsShown() then
			CuratorOctoFull.SetEnabled(other.take, false)
			other.take:SetPulse(false)
			ns.Tween(0.4, function(e)
				other:SetAlpha(1 - e)
				other.dy = -40 * e
			end, nil, Ease.inQuad, OU, 0.05)
		end
	end
	ns.Delay(0.85, function()
		self.busy = false
		if LV:OfferCount() > 0 then
			self:Paint(true)
		else
			self:Hide()
		end
	end, OU)
end

-- Shown (nothing waiting: said in the chat), its rewards dealt.
function OU:Show()
	if ns.Level:OfferCount() == 0 then
		ns.Print(L["No reward waits to be chosen."])
		return
	end
	local f = self:Build()
	-- (asked again while it was going: it stays, dealt again)
	if self.closing then
		ns.CancelOwner(OU)
		self.closing = false
		f:Hide()
	end
	local was = f:IsShown()
	-- (a screen too short for the stage: the stage smaller, whole)
	local h = UIParent:GetHeight() or 0
	f.stage:SetScale(h > 0 and math.min(1, (h - 16) / f.stage:GetHeight()) or 1)
	if not was then
		f:SetAlpha(0)
		f:Show()
		ns.Tween(0.25, function(e)
			f:SetAlpha(e)
		end, nil, Ease.outQuad, OU)
		ns.Play(ns.SND.whoosh)
	end
	f:Raise()
	self.busy = false
	self:Paint(not was)
end

function OU:Hide()
	local f = self.frame
	if not (f and f:IsShown()) or self.closing then
		return
	end
	self.closing = true
	ns.CancelOwner(OU)
	ns.Tween(0.22, function(e)
		f:SetAlpha(1 - e)
	end, function()
		f:Hide()
	end, Ease.outQuad, OU)
end

function OU:Showing()
	return self.frame ~= nil and self.frame:IsShown() and not self.closing
end

for _, e in ipairs({ "OFFERS_CHANGED", "RUBIES_CHANGED", "CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		if OU:Showing() and not OU.busy then
			OU:Paint()
		end
	end)
end
