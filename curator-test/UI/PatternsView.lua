local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin

-- (1.14.0, for the author: /curator test pattern [number] [rarity]) Twelve titanforged copies of the same card, side by
-- side, each its pattern (Patterns.lua), twelve at a time up to the last one; a click shows one in the hand
-- (UI/Links.lua). Nothing is kept. (His word: the cards of the cases too, /curator test pattern caisse: twelve titanforged
-- cards of a case, UI/CrateCard.lua, of a rank, each its pattern; a click shows one big, UI/CaseView.lua: CR:ViewCopy.)
local V = {}
ns.PatternView = V

local COLS, ROWS = 4, 3
local PAGE = COLS * ROWS
local SIZE = "mid"
local GAP_X, GAP_Y = 14, 16
local LEFT, TOP, FOOT = 18, 66, 96

-- A card for the preview: of that rarity, with a creature, of the album of the place first, else of another album
-- (not an album of an event); the k-th one of them, round.
local function Pick(rarity, k)
	local function Of(s)
		local out = {}
		if s and (s.kind == "zone" or s.kind == "dungeon") and s.byRarity and s.byRarity[rarity] then
			for _, card in ipairs(s.byRarity[rarity]) do
				if card.display and not card.art then
					out[CuratorOctoFull.Length(out) + 1] = card
				end
			end
		end
		return out
	end
	local list = Of(ns.CurrentSeries and ns.CurrentSeries())
	if CuratorOctoFull.Length(list) == 0 then
		for _, s in ipairs(ns.Series or {}) do
			list = Of(s)
			if CuratorOctoFull.Length(list) > 0 then
				break
			end
		end
	end
	if CuratorOctoFull.Length(list) == 0 then
		return nil
	end
	return list[CuratorOctoFull.Mod((k - 1) , CuratorOctoFull.Length(list)) + 1]
end

-- (the cards of the cases) The record of a titanforged card of the case of the month of that rank (5: a weapon of
-- legend), the k-th one of them, round, with that pattern (as Cases.lua keeps them).
local function CaseRecord(rank, k, n)
	local CS, CI, CR = ns.Cases, ns.CrateItems, ns.CrateUI
	local edition = (CS and CS.EDITION) or "paladin1"
	local w = { c = edition, r = rank, f = "titan", pt = n, cw = "Mint", i = 0 }
	if rank >= 5 then
		local list = {}
		for li, line in ipairs((CR and CR.WEAPONS) or {}) do
			for _, x in ipairs(line) do
				list[CuratorOctoFull.Length(list) + 1] = { id = x.id, line = li, class = x.class, faction = x.faction }
			end
		end
		local x = list[CuratorOctoFull.Mod((k - 1) , math.max(1, CuratorOctoFull.Length(list))) + 1]
		if not x then
			return nil
		end
		w.w, w.l, w.cl, w.fa = x.id, x.line, x.class, x.faction
	else
		local own = CI and CI:Case(edition)
		local list = own and own[rank] or {}
		local e = list[CuratorOctoFull.Mod((k - 1) , math.max(1, CuratorOctoFull.Length(list))) + 1]
		if not e then
			return nil
		end
		w.e = e.key
	end
	return w
end

function V:Build()
	if self.frame then
		return
	end
	local cw, ch = ns.CARD_SIZES[SIZE][1], ns.CARD_SIZES[SIZE][2]
	local W = LEFT * 2 + COLS * cw + (COLS - 1) * GAP_X
	local H = TOP + ROWS * ch + (ROWS - 1) * GAP_Y + FOOT
	local f = S.Window("CuratorPatternView", W, H)
	f:SetPoint("CENTER", 0, 20)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	tinsert(UISpecialFrames, "CuratorPatternView")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(ns.MEDIA .. "Icon")
	end
	f:SetTitle(L["Patterns"])
	f.drag = S.DragBar(f, 22)
	f.cards = {}
	for i = 1, PAGE do
		local i = i; local col, row = CuratorOctoFull.Mod((i - 1) , COLS), math.floor((i - 1) / COLS)
		local holder = CreateFrame("Frame", nil, f)
		CuratorOctoFull.SetSize(holder, cw, ch)
		holder:SetPoint("TOPLEFT", LEFT + col * (cw + GAP_X), -TOP - row * (ch + GAP_Y))
		local card = ns.NewCard(holder, SIZE)
		card:SetPoint("CENTER")
		CuratorOctoFull.SetScript(card, "OnClick", function()
			if card.card and card.wearOpts then
				-- (his idea, 31 October: the wear, /curator test usure)
				ns.Play(ns.SND.click)
				ns.Links:View(card.card, nil, nil, nil, card.wearOpts)
			elseif card.card and card.patternN then
				ns.Play(ns.SND.click)
				ns.Links:View(card.card, "holo", nil, card.patternN)
			end
		end)
		f.cards[i] = card
		-- (the wear: its grade over it)
		holder.grade = S.Text(holder, "GameFontNormal")
		holder.grade:SetPoint("BOTTOM", holder, "TOP", 0, 1)
		holder.grade:Hide()
		-- (the cards of the cases: one of them in the same place, made the first time)
		holder.slot = i
		f.holders = f.holders or {}
		f.holders[i] = holder
	end
	f.mode = S.Button(f, "", 200, 22)
	f.mode:SetPoint("TOPRIGHT", -LEFT, -30)
	CuratorOctoFull.SetScript(f.mode, "OnClick", function()
		ns.Play(ns.SND.click)
		V.mode = (V.mode == "cases") and "cards" or "cases"
		V.k = 1
		V:Show(V.from)
	end)
	f.range = S.Text(f, "GameFontNormal")
	f.range:SetPoint("BOTTOM", 0, 60)
	f.hint = S.Text(f, "GameFontDisableSmall")
	f.hint:SetPoint("TOP", f.range, "BOTTOM", 0, -4)
	f.hint:SetText(L["Click a card to see it up close."])
	local bw = math.floor((W - LEFT * 2 - 3 * 8) / 4)
	f.prev = S.Button(f, L["Previous"], bw, 24)
	f.prev:SetPoint("BOTTOMLEFT", LEFT, 16)
	CuratorOctoFull.SetScript(f.prev, "OnClick", function()
		ns.Play(ns.SND.click)
		V:Show(V.from - PAGE)
	end)
	f.rarity = S.Button(f, "", bw, 24)
	f.rarity:SetPoint("LEFT", f.prev, "RIGHT", 8, 0)
	CuratorOctoFull.SetScript(f.rarity, "OnClick", function()
		ns.Play(ns.SND.click)
		if V.mode == "cases" then
			V.rankN = CuratorOctoFull.Mod((V.rankN or 1) , 5) + 1
		else
			V.rarityN = CuratorOctoFull.Mod(V.rarityN , CuratorOctoFull.Length(ns.RARITY)) + 1
		end
		V.k = 1
		V:Show(V.from)
	end)
	f.other = S.Button(f, L["Another card"], bw, 24)
	f.other:SetPoint("LEFT", f.rarity, "RIGHT", 8, 0)
	CuratorOctoFull.SetScript(f.other, "OnClick", function()
		ns.Play(ns.SND.click)
		V.k = V.k + 1
		V:Show(V.from)
	end)
	f.next = S.Button(f, L["Next"], bw, 24)
	f.next:SetPoint("LEFT", f.other, "RIGHT", 8, 0)
	CuratorOctoFull.SetScript(f.next, "OnClick", function()
		ns.Play(ns.SND.click)
		if V.mode == "wear" then
			V.wseed = (V.wseed or 1) + 1
		end
		V:Show(V.from + PAGE)
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		V.t = (V.t or 0) + elapsed
		for _, card in ipairs(f.cards) do
			if card:IsShown() then
				card:Tick(V.t)
			end
		end
	end)
end

-- (his idea, 31 October: the wear, Wear.lua and UI/Wear.lua) Ten copies of the same card, of the grade 10 to 1, then two by
-- chance (its odds), each its wear; Next: other copies; a click shows one in the hand.
function V:ShowWear()
	local f = self.frame
	local card = Pick(self.rarityN, self.k)
	local W = ns.Wear
	f.mode:Hide()
	f:SetTitle(L["Wear"])
	f.range:SetText(L["Wear: 10 to 1, then two by chance"])
	for i, h in ipairs(f.holders) do
		if h.crate then
			h.crate.rec = nil
			h.crate:Hide()
		end
		local c = f.cards[i]
		if card and W then
			local g = i <= 10 and (11 - i) or nil
			local wear = W.Test(g, (self.wseed or 1) * 31 + i)
			c.patternN, c.wearOpts = nil, wear
			c:SetCard(card, { owned = true, facing = 0.4, wear = wear })
			c:ShowSide("front")
			c:Show()
			h.grade:SetText(i <= 10 and tostring(wear.g) or ("? (" .. wear.g .. ")"))
			h.grade:Show()
		else
			c.wearOpts = nil
			c:Hide()
			h.grade:Hide()
		end
	end
	local r = ns.RARITY[self.rarityN]
	f.rarity:SetLabel(string.format(L["Rarity: %s"], L[r.label]))
	CuratorOctoFull.SetEnabled(f.prev, false)
	CuratorOctoFull.SetEnabled(f.next, true)
	if not f:IsShown() then
		f:Show()
		ns.Play(ns.SND.open or ns.SND.cardFlip)
	end
	f:Raise()
end

-- /curator test usure [rarity]: the wear (rare at first).
function V:TestWear(rarity)
	self:Build()
	self.rarityN = rarity or self.rarityN or 3
	self.mode = "wear"
	self.k = 1
	self.wseed = math.random(1, 9999)
	self:Show(1)
end

-- The page that starts at that pattern (from: its first number).
function V:Show(from)
	self:Build()
	local f = self.frame
	if self.mode == "wear" then
		self.from = 1
		return self:ShowWear()
	end
	f.mode:Show()
	for _, h in ipairs(f.holders) do
		h.grade:Hide()
	end
	for _, c in ipairs(f.cards) do
		c.wearOpts = nil
	end
	local max = ns.Patterns.MAX
	from = math.floor(tonumber(from) or 1)
	from = math.max(1, math.min(from, max - CuratorOctoFull.Mod((max - 1) , PAGE)))
	self.from = from
	local last = math.min(max, from + PAGE - 1)
	f.range:SetText(string.format(L["Patterns %d to %d of %d"], from, last, max))
	local cases = self.mode == "cases"
	f.mode:SetLabel(cases and L["Cards of the albums"] or L["Cards of the cases"])
	f:SetTitle(L["Patterns"] .. "  ·  " .. (cases and L["Cards of the cases"] or L["Cards of the albums"]))
	-- (the cards of the cases: a rank, its cards, each its pattern)
	local CR, CD, CC = ns.CrateUI, ns.CaseDetail, ns.CrateCard
	for i, h in ipairs(f.holders) do
		local i, h = i, h; local n = from + i - 1
		local w = cases and n <= max and CaseRecord(self.rankN or 1, self.k, n) or nil
		if w and CR and CD and CC then
			if not h.crate then
				h.crate = CC.New(h, h:GetWidth())
				h.crate:SetPoint("CENTER")
				h.crate:EnableMouse(true)
				CuratorOctoFull.SetScript(h.crate, "OnMouseUp", function(c)
					if c.rec then
						ns.Play(ns.SND.click)
						CR:ViewCopy(c.rec)
					end
				end)
			end
			h.crate.rec = w
			h.crate:Set(CD.PickOf(CD.DescOf(w), w), CR.RANKS)
			local def = ns.Crates and ns.Crates[w.c]
			h.crate:SetBack(def and def.art and def.art.back or nil)
			h.crate:SetLive(true)
			h.crate:Show()
		elseif h.crate then
			h.crate.rec = nil
			h.crate:Hide()
		end
	end
	if cases then
		local rk = CR and CR.RANKS and CR.RANKS[self.rankN or 1]
		f.rarity:SetLabel(string.format(L["Rank: %s"], rk and L[rk.label] or "?"))
	else
		local r = ns.RARITY[self.rarityN]
		f.rarity:SetLabel(string.format(L["Rarity: %s"], L[r.label]))
	end
	local card = (not cases) and Pick(self.rarityN, self.k) or nil
	for i, c in ipairs(f.cards) do
		local n = from + i - 1
		if card and n <= max then
			c.patternN = n
			c:SetCard(card, { owned = true, finish = "holo", facing = 0.4, pattern = n })
			c:ShowSide("front")
			c:Show()
		else
			c.patternN = nil
			c:Hide()
		end
	end
	CuratorOctoFull.SetEnabled(f.prev, from > 1)
	CuratorOctoFull.SetEnabled(f.next, last < max)
	if not f:IsShown() then
		f:Show()
		ns.Play(ns.SND.open or ns.SND.cardFlip)
	end
	f:Raise()
end

-- /curator test pattern [number] [rarity]: the page of that pattern, the cards of that rarity (legendary at first).
-- (cases: the cards of the cases, of that rank: 1 rare to 5 priceless)
function V:Test(n, rarity, cases, rank)
	self.rarityN = rarity or self.rarityN or 5
	self.mode = cases and "cases" or "cards"
	self.rankN = rank or self.rankN or 1
	self.k = 1
	local from = 1
	n = ns.Patterns.Number(n)
	if n then
		from = n - CuratorOctoFull.Mod((n - 1) , PAGE)
	end
	self:Show(from)
end
