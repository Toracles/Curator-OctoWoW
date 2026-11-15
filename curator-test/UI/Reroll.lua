local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.14.0) The main character and the rerolls (Reroll.lua): the window that asks a new character what it is (a
-- reroll, or the new main), the chest of a reroll, and its opening at level 15 (or when the character becomes the
-- main): what came out of it, in its light. The tests of the author (his build: /curator test reroll | coffre |
-- principal | sortie), on a copy of his collection.
-------------------------------------------------------------------------------
local UI = {}
ns.RerollUI = UI

local GOLD = { 1, 0.82, 0.25 }
local CHEST = "Interface\\Icons\\INV_Box_02"
local W = 520

local function RR()
	return ns.Reroll
end

-- The name of this character (its first name).
local function MyName()
	local me = (ns.Guild and ns.Guild:Me()) or ""
	return CuratorOctoFull.Match(me, "^([^%-]+)") or me
end

-------------------------------------------------------------------------------
-- The window of the main
-------------------------------------------------------------------------------
function UI:BuildAsk()
	if self.askFrame then
		return self.askFrame
	end
	local f = S.Window("CuratorMainWindow", W, 250)
	f:SetPoint("CENTER", 0, 90)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	S.DragBar(f)
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(CHEST)
	end
	if f.SetTitle then
		f:SetTitle(L["Your main character"])
	end
	f:Hide()
	tinsert(UISpecialFrames, "CuratorMainWindow")
	local text = S.Text(f, "GameFontHighlight", "LEFT")
	text:SetPoint("TOPLEFT", 74, -42)
	text:SetWidth(W - 100)
	CuratorOctoFull.SetWordWrap(text, true)
	text:SetSpacing(3)
	f.text = text
	local note = S.Text(f, "GameFontNormal", "LEFT")
	note:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
	note:SetWidth(W - 100)
	CuratorOctoFull.SetWordWrap(note, true)
	f.note = note
	local keep = S.Button(f, L["It is a reroll"], 200, 26)
	keep:SetPoint("BOTTOMLEFT", 22, 18)
	CuratorOctoFull.SetScript(keep, "OnClick", function()
		local r = RR()
		if r and r:IsReroll() then
			r:KeepReroll()
		end
		ns.Play(ns.SND.close)
		f:Hide()
	end)
	f.keep = keep
	local make = S.Button(f, L["Make it my main"], 240, 26)
	make:SetPoint("BOTTOMRIGHT", -22, 18)
	CuratorOctoFull.SetScript(make, "OnClick", function()
		UI:MakeMain()
	end)
	if make.SetMotionScriptsWhileDisabled then
		make:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(make, "OnEnter", function(self)
		local r = RR()
		local ok, left = false, 0
		if r then
			ok, left = r:CanChange()
		end
		if not ok and left > 0 then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(L["Make it my main"], 1, 0.82, 0)
			GameTooltip:AddLine(string.format(L["Your main changes once a month at most: again in %s."], ns.Duration(left)), 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	CuratorOctoFull.SetScript(make, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.make = make
	CuratorOctoFull.SetScript(f, "OnHide", function()
		UI.armed = nil
	end)
	self.askFrame = f
	return f
end

-- The window, as this character stands (forced: asked for, /curator main; else the first login of a reroll).
function UI:Ask(forced)
	local r = RR()
	if not (r and ns.db) then
		return
	end
	local f = self:BuildAsk()
	self.armed = nil
	self:PaintAsk()
	f:Show()
	ns.Play(ns.SND.open)
	if not forced and r:IsReroll() then
		-- (asked once: closed without an answer, it stays a reroll)
		local c = r:Char()
		if c then
			c.asked = c.asked or ((GetServerTime and CuratorOctoFull.ServerTime()) or time())
		end
	end
end

function UI:PaintAsk()
	local f = self.askFrame
	local r = RR()
	if not (f and r) then
		return
	end
	local main = r:MainName()
	local ok, left = r:CanChange()
	f.keep:Show()
	f.make:Show()
	f.note:SetText("")
	if not r:Active() then
		f.text:SetText(L["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."])
		f.keep:SetLabel(L["Close"])
		f.make:Hide()
	elseif r:IsMain() then
		f.text:SetText(string.format(L["%s is your main character: it earns everything from level 1."], MyName()))
		f.note:SetText(string.format(L["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."], r.LEVEL, r.LEVEL))
		f.keep:SetLabel(L["Close"])
		f.make:Hide()
	elseif r:IsReroll() then
		local got = r:Contents()
		f.text:SetText(string.format(L["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."], r.LEVEL, r.LEVEL, main))
		-- (1.14.0, after its test, his word: what a reroll does not do at all, Reroll.lua: RR:Rules)
		f.note:SetText(r:Rules(true) .. "\n" .. string.format(L["In its chest: %d boosters, %d cards."], got.boosters, got.cards))
		f.keep:SetLabel(L["It is a reroll"])
	else
		f.text:SetText(string.format(L["This character earns everything: it is level %d or above. Your main character: %s."], r.LEVEL, main))
		f.keep:SetLabel(L["Close"])
	end
	if f.make:IsShown() then
		if self.armed then
			f.make:SetLabel(L["Confirm: my main"])
		else
			f.make:SetLabel(L["Make it my main"])
		end
		f.make:SetEnabled(ok and true or false)
		if not ok and left > 0 then
			local more = string.format(L["Your main changes once a month at most: again in %s."], ns.Duration(left))
			local was = f.note:GetText()
			f.note:SetText((was and was ~= "") and (was .. "\n" .. more) or more)
		end
	end
	local h = 120 + f.text:GetStringHeight() + (f.note:GetText() ~= "" and (f.note:GetStringHeight() + 12) or 0)
	f:SetHeight(math.max(200, math.floor(h + 0.5)))
end

-- The button: a second click to be sure (the main changes once a month at most).
function UI:MakeMain()
	local r = RR()
	if not r or not r:CanChange() then
		ns.Play(ns.SND.close)
		return
	end
	if not self.armed then
		self.armed = true
		self:PaintAsk()
		return
	end
	self.armed = nil
	if r:SetMain(false) then
		ns.Play(ns.SND.stamp)
		ns.Print(string.format(L["%s is now your main character: it earns everything from level 1."], MyName()))
	end
	if self.askFrame then
		self.askFrame:Hide()
	end
end

-------------------------------------------------------------------------------
-- (1.14.0, after its test, his word) A page a reroll cannot use (the quests, the achievements: Reroll.lua, RR:Blocks):
-- a pill in its head, a padlock and the level it waits for, why in its tooltip. pill:Paint(what): its words, its width.
-------------------------------------------------------------------------------
local PILL_MAX = 196
function UI.Pill(parent)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, 170, 28)
	b:SetFrameLevel(parent:GetFrameLevel() + 6)
	b.edge = b:CreateTexture(nil, "BACKGROUND", nil, -1)
	b.edge:SetPoint("TOPLEFT", -1, 1)
	b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(b.edge, 1, 0.56, 0.36, 0.7)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.bg, 0.16, 0.07, 0.03, 0.94)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetTexture(ns.MEDIA .. "Lock")
	CuratorOctoFull.SetSize(b.icon, 18, 18)
	b.icon:SetPoint("LEFT", 6, 0)
	b.label = S.Text(b, "GameFontNormal", "LEFT")
	b.label:SetPoint("LEFT", b.icon, "RIGHT", 5, 0)
	CuratorOctoFull.SetWordWrap(b.label, false)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		local r = RR()
		if not (r and self.what) then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:AddLine(self.label:GetText() or "", 1, 1, 1)
		GameTooltip:AddLine(r:WhyNot(self.what), 1, 0.62, 0.45, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	function b:Paint(what)
		local r = RR()
		self.what = what
		local text = string.format(L["Locked until level %d"], r and r.LEVEL or 15)
		local room = PILL_MAX - 6 - 18 - 5 - 10
		S.SetFontObject(self.label, "GameFontNormal")
		self.label:SetText(text)
		if ns.TextWidth(self.label) > room then
			S.Fit(self.label, text, room, 12, 8)
		end
		self.label:SetTextColor(1, 0.72, 0.5)
		local lw = math.min(ns.TextWidth(self.label) + 4, room)
		self.label:SetWidth(lw)
		self:SetWidth(6 + 18 + 5 + lw + 10)
	end
	b:Hide()
	return b
end

-------------------------------------------------------------------------------
-- The chest
-------------------------------------------------------------------------------
function UI:BuildChest()
	if self.chestFrame then
		return self.chestFrame
	end
	local f = S.Window("CuratorChestWindow", 420, 280)
	f:SetPoint("CENTER", 0, 110)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	S.DragBar(f)
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(CHEST)
	end
	f:Hide()
	tinsert(UISpecialFrames, "CuratorChestWindow")
	-- the chest, in its light
	local art = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(art, 56, 56)
	art:SetPoint("TOP", 0, -40)
	f.art = art
	local glow = art:CreateTexture(nil, "BACKGROUND")
	glow:SetTexture(ns.MEDIA .. "Glow")
	glow:SetBlendMode("ADD")
	glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	CuratorOctoFull.SetSize(glow, 150, 150)
	glow:SetPoint("CENTER")
	glow:SetAlpha(0)
	f.glow = glow
	local icon = art:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture(CHEST)
	f.icon = icon
	local head = S.Text(f, "GameFontNormalLarge", "CENTER")
	head:SetPoint("TOP", art, "BOTTOM", 0, -10)
	head:SetWidth(380)
	f.head = head
	local text = S.Text(f, "GameFontHighlight", "CENTER")
	text:SetPoint("TOP", head, "BOTTOM", 0, -10)
	text:SetWidth(370)
	CuratorOctoFull.SetWordWrap(text, true)
	text:SetSpacing(3)
	f.text = text
	local note = S.Text(f, "GameFontNormalSmall", "CENTER")
	note:SetPoint("TOP", text, "BOTTOM", 0, -10)
	note:SetWidth(370)
	CuratorOctoFull.SetWordWrap(note, true)
	f.note = note
	local go = S.Button(f, L["My boosters"], 170, 24)
	go:SetPoint("BOTTOM", 0, 16)
	CuratorOctoFull.SetScript(go, "OnClick", function()
		f:Hide()
		if ns.Album and ns.Album.ShowBoosters then
			ns.Album:ShowBoosters()
		end
	end)
	f.go = go
	self.chestFrame = f
	return f
end

-- What a chest holds, line by line.
function UI.Lines(got)
	local t = {}
	if got.packs > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Boosters of albums: %d"], got.packs)
		for i = 1, math.min(3, CuratorOctoFull.Length(got.albums)) do
			local a = got.albums[i]
			t[CuratorOctoFull.Length(t) + 1] = "|cff9d9d9d" .. ns.Collection:SeriesName(a.s) .. " ×" .. a.n .. "|r"
		end
		if CuratorOctoFull.Length(got.albums) > 3 then
			t[CuratorOctoFull.Length(t) + 1] = "|cff9d9d9d" .. string.format(L["and %d more albums"], CuratorOctoFull.Length(got.albums) - 3) .. "|r"
		end
	end
	if got.choice > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Rewards to choose: %d"], got.choice)
	end
	if got.cards > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Cards found: %d"], got.cards)
	end
	-- (1.14.0: the cases, Cases.lua)
	if (got.cases or 0) > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Cases: %d"], got.cases)
	end
	if got.xp > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Collector experience: %s XP"], ns.Num(got.xp))
	end
	if got.rubies > 0 then
		t[CuratorOctoFull.Length(t) + 1] = string.format(L["Rubies: %s"], ns.Num(got.rubies))
	end
	if CuratorOctoFull.Length(t) == 0 then
		t[1] = L["Nothing yet."]
	end
	return table.concat(t, "\n")
end

local function Fit(f)
	local h = 40 + 56 + 10 + f.head:GetStringHeight() + 10 + f.text:GetStringHeight() + 10 + f.note:GetStringHeight() + 60
	f:SetHeight(math.max(240, math.floor(h + 0.5)))
end

-- The chest of this character, closed (/curator chest): (1.14.0, after its test) its page in the album, under its tab
-- of the menu (small: the window of before).
function UI:ShowChest(small)
	local r = RR()
	if not (r and ns.db) then
		return
	end
	if not r:IsReroll() then
		if not r:Active() then
			ns.Print(L["The chests of the rerolls come with the release of WoW Forever."])
		else
			ns.Print(L["This character has no chest: it earns everything as it comes."])
		end
		return
	end
	local A = ns.Album
	if not small and A and A.ShowChestTab then
		return A:ShowChestTab()
	end
	local f = self:BuildChest()
	if f.SetTitle then
		f:SetTitle(string.format(L["The chest of %s"], MyName()))
	end
	f.glow:SetAlpha(0.35)
	f.icon:SetDesaturated(true)
	f.head:SetText(string.format(L["Opens at level %d"], r.LEVEL))
	f.text:SetText(UI.Lines(r:Contents()))
	f.note:SetText(L["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."])
	f.go:Hide()
	Fit(f)
	f:Show()
	ns.Play(ns.SND.open)
end

-- The chest opened: what came out of it, in its light (out of a fight: never in the middle of one).
function UI:Opened(got)
	if not got or (got.boosters + got.cards + got.xp + got.rubies) <= 0 then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		ns.Delay(2, function()
			UI:Opened(got)
		end, UI)
		return
	end
	local f = self:BuildChest()
	if f.SetTitle then
		f:SetTitle(string.format(L["The chest of %s"], MyName()))
	end
	f.icon:SetDesaturated(false)
	f.head:SetText(L["Your chest opens!"])
	f.text:SetText(UI.Lines(got))
	f.note:SetText(L["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."])
	CuratorOctoFull.SetShown(f.go, got.boosters > 0)
	Fit(f)
	f:Show()
	ns.Play(ns.SND.claim)
	ns.Play(ns.SND.levelSting)
	if ns.Hud and ns.Hud.Burst then
		ns.Hud.Burst(f.art, GOLD, 26, 150, 18)
	end
	if ns.Tween then
		if f.tw then
			ns.CancelTween(f.tw)
		end
		f.tw = ns.Tween(1.6, function(_, raw)
			f.glow:SetAlpha(0.95 * (1 - raw) + 0.3 * raw)
			f.art:SetScale(1 + 0.25 * math.sin(math.pi * math.min(1, raw * 2)) * (1 - raw))
		end, function()
			f.glow:SetAlpha(0.3)
			f.art:SetScale(1)
			f.tw = nil
		end, ns.Ease and ns.Ease.linear, UI)
	end
	ns.Print(string.format(L["The chest of %s opens: %d boosters, %d cards."], MyName(), got.boosters, got.cards))
end

ns.On("CHEST_OPENED", function(got)
	if UI.quiet then
		return
	end
	UI:Opened(got)
end)

ns.On("MAIN_CHANGED", function()
	if UI.askFrame and UI.askFrame:IsShown() then
		UI:PaintAsk()
	end
end)

ns.On("CHEST_CHANGED", function()
	local f = UI.chestFrame
	local r = RR()
	if f and f:IsShown() and r and r:IsReroll() then
		f.text:SetText(UI.Lines(r:Contents()))
		Fit(f)
	end
end)

-------------------------------------------------------------------------------
-- (1.14.0, after its test, his word) The chest in the menu: a page of the album, under its tab (on a reroll only). On
-- the left, the chest in its light on the photo of the place, the level it opens at and the way there, the main
-- character and the button that makes this one the main; on the right, what it holds (six tiles), its boosters album by
-- album, its cards, its own booster bars, and the rule: a reroll opens nothing.
-------------------------------------------------------------------------------
local CP = {}
UI.Page = CP
local LEFT_W = 300
local TILE_W, TILE_H, TILE_GAP = 204, 62, 10
local LIST_ROWS = 5
-- (its boosters: three rows of a booster each)
local PACK_ROWS, PACK_ROW_H = 3, 33
local TILES = {
	{ key = "packs", label = "Boosters of albums", icon = { "PackZoneChoice" } },
	{ key = "choice", label = "Boosters to choose", icon = { "PackDungeonChoice" } },
	{ key = "cards", label = "Cards found", icon = { "Back", { 0.07, 0.65, 0.21, 0.79 } } },
	{ key = "cases", label = "Cases", icon = { "CaseIcon" } },
	{ key = "xp", label = "Collector experience", icon = { "XPOrb" } },
	{ key = "rubies", label = "Rubies", icon = { "Ruby" } },
}

local function NewTile(parent, def)
	local Hud = ns.Hud
	local t = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(t, TILE_W, TILE_H)
	Hud.Panel(t, TILE_H)
	t.icon = t:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(t.icon, 34, 34)
	t.icon:SetPoint("LEFT", 10, 0)
	Hud.SetIcon(t.icon, def.icon)
	t.value = Hud.Text(t, 19, "OUTLINE")
	t.value:SetPoint("TOPLEFT", 54, -10)
	t.value:SetTextColor(1, 0.9, 0.62)
	t.label = S.Text(t, "GameFontHighlightSmall", "LEFT")
	t.label:SetPoint("TOPLEFT", 54, -36)
	t.label:SetWidth(TILE_W - 62)
	CuratorOctoFull.SetWordWrap(t.label, false)
	t.label:SetTextColor(0.8, 0.8, 0.84)
	t.label:SetText(L[def.label])
	t.def = def
	-- (1 November, his word: « il faut montrer exactement quel booster le gars il a dedans ») the boosters of albums: the
	-- booster of its first album standing in the place of the icon
	if def.key == "packs" then
		t.pack = Hud.Pack(t, 17)
		t.pack:SetPoint("CENTER", t.icon, "CENTER")
		t.pack.glow:SetAlpha(0.22)
		t.pack:Hide()
	end
	return t
end

local function Line(parent, w)
	local fs = S.Text(parent, "GameFontHighlightSmall", "LEFT")
	fs:SetWidth(w)
	CuratorOctoFull.SetWordWrap(fs, false)
	return fs
end

function CP:Build(A)
	local f = A.frame
	if f.chest then
		return f.chest
	end
	local U, Hud, MEDIA = A.U, ns.Hud, ns.MEDIA
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.chest = page
	local W, H = U.PAGE_W - 32, U.PAGE_H - 20
	page.h = H

	-- the chest, on the photo of the place
	local lf = CreateFrame("Frame", nil, page)
	lf:SetPoint("TOPLEFT")
	lf:SetPoint("BOTTOMLEFT")
	lf:SetWidth(LEFT_W)
	if lf.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(lf, true)
	end
	page.left = lf
	lf.photo = lf:CreateTexture(nil, "BACKGROUND")
	lf.photo:SetPoint("TOPLEFT", 2, -2)
	lf.photo:SetPoint("BOTTOMRIGHT", -2, 2)
	lf.shade = lf:CreateTexture(nil, "BACKGROUND", nil, 1)
	lf.shade:SetAllPoints(lf.photo)
	CuratorOctoFull.ColorTexture(lf.shade, 0.02, 0.02, 0.05, 0.62)
	lf.vig = lf:CreateTexture(nil, "BACKGROUND", nil, 2)
	lf.vig:SetAllPoints(lf.photo)
	lf.vig:SetTexture(MEDIA .. "Vignette")
	lf.frame = Hud.Card(lf, 0.75, "BORDER", 0, true)
	lf.title = S.Text(lf, "GameFontNormalLarge")
	lf.title:SetPoint("TOP", 0, -16)
	lf.title:SetWidth(LEFT_W - 24)
	CuratorOctoFull.SetWordWrap(lf.title, false)
	-- (its light: the rays turning slowly, the glow, the ring, the chest, its lock)
	local art = CreateFrame("Frame", nil, lf)
	CuratorOctoFull.SetSize(art, 120, 120)
	art:SetPoint("TOP", 0, -58)
	lf.art = art
	art.rays = art:CreateTexture(nil, "BACKGROUND", nil, 3)
	art.rays:SetTexture(MEDIA .. "Rays")
	art.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(art.rays, 290, 290)
	art.rays:SetPoint("CENTER")
	art.rays:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	art.rays:SetAlpha(0.22)
	art.glow = art:CreateTexture(nil, "BACKGROUND", nil, 4)
	art.glow:SetTexture(MEDIA .. "Glow")
	art.glow:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(art.glow, 210, 210)
	art.glow:SetPoint("CENTER")
	art.glow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
	art.glow:SetAlpha(0.45)
	art.icon = Hud.RoundIcon(art, 96, "ARTWORK")
	art.icon:SetPoint("CENTER")
	art.icon:SetTexture(CHEST)
	art.ring = art:CreateTexture(nil, "ARTWORK", nil, 2)
	art.ring:SetTexture(MEDIA .. "IconRing")
	CuratorOctoFull.SetSize(art.ring, 128, 128)
	art.ring:SetPoint("CENTER")
	art.lock = art:CreateTexture(nil, "OVERLAY")
	art.lock:SetTexture(MEDIA .. "Lock")
	CuratorOctoFull.SetSize(art.lock, 38, 38)
	art.lock:SetPoint("CENTER", art, "BOTTOMRIGHT", -18, 18)
	lf.opens = S.Text(lf, "GameFontNormal")
	lf.opens:SetPoint("TOP", art, "BOTTOM", 0, -16)
	lf.level = Hud.XPBar(lf, 240, 16, { 1, 0.74, 0.25 })
	lf.level:SetPoint("TOP", lf.opens, "BOTTOM", 0, -10)
	lf.togo = S.Text(lf, "GameFontHighlightSmall")
	lf.togo:SetPoint("TOP", lf.level, "BOTTOM", 0, -6)
	lf.togo:SetTextColor(0.8, 0.8, 0.84)
	lf.rule = S.Divider(lf, LEFT_W - 60, 0.6)
	lf.rule:SetPoint("TOP", lf.togo, "BOTTOM", 0, -16)
	lf.mainLabel = S.Text(lf, "GameFontHighlightSmall")
	lf.mainLabel:SetPoint("TOP", lf.rule, "BOTTOM", 0, -14)
	lf.mainLabel:SetTextColor(0.75, 0.75, 0.8)
	lf.mainLabel:SetText(L["Your main character"])
	lf.main = S.Text(lf, "GameFontHighlightLarge")
	lf.main:SetPoint("TOP", lf.mainLabel, "BOTTOM", 0, -4)
	lf.main:SetWidth(LEFT_W - 30)
	CuratorOctoFull.SetWordWrap(lf.main, false)
	lf.make = S.Button(lf, L["Make it my main"], 230, 24)
	lf.make:SetPoint("TOP", lf.main, "BOTTOM", 0, -12)
	CuratorOctoFull.SetScript(lf.make, "OnClick", function()
		CP:MakeMain()
	end)
	if lf.make.SetMotionScriptsWhileDisabled then
		lf.make:SetMotionScriptsWhileDisabled(true)
	end
	CuratorOctoFull.SetScript(lf.make, "OnEnter", function(self)
		local r = RR()
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Make it my main"], 1, 0.82, 0)
		GameTooltip:AddLine(L["It earns everything from level 1, and its chest opens now. Your main changes once a month at most."], 1, 1, 1, true)
		local ok, left = false, 0
		if r then
			ok, left = r:CanChange()
		end
		if not ok and left > 0 then
			GameTooltip:AddLine(string.format(L["Your main changes once a month at most: again in %s."], ns.Duration(left)), 1, 0.45, 0.4, true)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(lf.make, "OnLeave", function()
		GameTooltip:Hide()
	end)
	lf.note = S.Text(lf, "GameFontHighlightSmall")
	lf.note:SetPoint("BOTTOM", 0, 16)
	lf.note:SetWidth(LEFT_W - 36)
	CuratorOctoFull.SetWordWrap(lf.note, true)
	lf.note:SetTextColor(0.68, 0.68, 0.74)

	-- what it holds
	local X = LEFT_W + 16
	local rw = W - X
	local rf = CreateFrame("Frame", nil, page)
	rf:SetPoint("TOPLEFT", X, 0)
	rf:SetPoint("BOTTOMRIGHT")
	page.right = rf
	rf.title = S.Text(rf, "GameFontNormalLarge", "LEFT")
	rf.title:SetPoint("TOPLEFT", 4, -4)
	rf.title:SetText(L["In the chest"])
	rf.sub = S.Text(rf, "GameFontHighlightSmall", "LEFT")
	rf.sub:SetPoint("TOPLEFT", rf.title, "BOTTOMLEFT", 0, -5)
	rf.sub:SetWidth(rw - 8)
	CuratorOctoFull.SetWordWrap(rf.sub, true)
	rf.sub:SetTextColor(0.62, 0.62, 0.68)
	rf.tiles = {}
	for i, def in ipairs(TILES) do
		local t = NewTile(rf, def)
		local col, row = CuratorOctoFull.Mod((i - 1) , 2), math.floor((i - 1) / 2)
		t:SetPoint("TOPLEFT", col * (TILE_W + TILE_GAP), -56 - row * (TILE_H + 8))
		rf.tiles[i] = t
	end
	local listY = -56 - 3 * (TILE_H + 8) - 10
	local function List(x, title)
		local l = CreateFrame("Frame", nil, rf)
		CuratorOctoFull.SetSize(l, TILE_W, 24 + LIST_ROWS * 20)
		l:SetPoint("TOPLEFT", x, listY)
		l.title = S.Text(l, "GameFontNormal", "LEFT")
		l.title:SetPoint("TOPLEFT", 4, 0)
		l.title:SetText(L[title])
		l.rule = S.Divider(l, TILE_W - 8, 0.5)
		l.rule:SetPoint("TOPLEFT", l.title, "BOTTOMLEFT", 0, -4)
		l.lines = {}
		for i = 1, LIST_ROWS do
			local fs = Line(l, TILE_W - 10)
			fs:SetPoint("TOPLEFT", 6, -24 - (i - 1) * 20)
			l.lines[i] = fs
		end
		return l
	end
	-- (1 November, his word: « il faut montrer exactement quel booster le gars il a dedans ») its boosters, album by album:
	-- each its booster standing, its name, how many; under the mouse, what it is
	local function PackList(x, title)
		local l = CreateFrame("Frame", nil, rf)
		CuratorOctoFull.SetSize(l, TILE_W, 24 + PACK_ROWS * PACK_ROW_H)
		l:SetPoint("TOPLEFT", x, listY)
		l.title = S.Text(l, "GameFontNormal", "LEFT")
		l.title:SetPoint("TOPLEFT", 4, 0)
		l.title:SetText(L[title])
		l.rule = S.Divider(l, TILE_W - 8, 0.5)
		l.rule:SetPoint("TOPLEFT", l.title, "BOTTOMLEFT", 0, -4)
		l.rows = {}
		for i = 1, PACK_ROWS do
			local i = i; local r = CreateFrame("Frame", nil, l)
			CuratorOctoFull.SetSize(r, TILE_W - 4, PACK_ROW_H - 1)
			r:SetPoint("TOPLEFT", 2, -21 - (i - 1) * PACK_ROW_H)
			r:EnableMouse(true)
			r.pack = Hud.Pack(r, 15)
			r.pack:SetPoint("LEFT", 8, 0)
			r.pack.glow:SetAlpha(0.2)
			r.name = Line(r, TILE_W - 74)
			r.name:SetPoint("LEFT", r.pack, "RIGHT", 10, 0)
			r.count = S.Text(r, "GameFontNormal", "RIGHT")
			r.count:SetPoint("RIGHT", -6, 0)
			r.count:SetTextColor(1, 0.82, 0.29)
			r.text = Line(r, TILE_W - 14)
			r.text:SetPoint("LEFT", 6, 0)
			CuratorOctoFull.SetScript(r, "OnEnter", function(self)
				CP:PackTip(self)
			end)
			CuratorOctoFull.SetScript(r, "OnLeave", function()
				GameTooltip:Hide()
			end)
			l.rows[i] = r
		end
		return l
	end
	rf.packs = PackList(0, "Its boosters")
	rf.cards = List(TILE_W + TILE_GAP, "Its cards")
	-- its own bars, and the rules (1.14.0, after its test, his word: all of them, under the bars)
	local bh = 136
	local bars = CreateFrame("Frame", nil, rf)
	CuratorOctoFull.SetSize(bars, rw, bh)
	bars:SetPoint("BOTTOMLEFT")
	Hud.Panel(bars, bh)
	rf.bars = bars
	bars.title = S.Text(bars, "GameFontNormal", "LEFT")
	bars.title:SetPoint("TOPLEFT", 14, -10)
	bars.title:SetText(L["Its booster bars"])
	bars.world = Hud.XPBar(bars, rw - 168, 12, { 1, 0.74, 0.25 })
	bars.world:SetPoint("TOPLEFT", 150, -34)
	bars.worldLabel = S.Text(bars, "GameFontHighlightSmall", "LEFT")
	bars.worldLabel:SetPoint("RIGHT", bars.world, "LEFT", -8, 0)
	bars.dungeon = Hud.XPBar(bars, rw - 168, 12, { 0.5, 0.68, 1 })
	bars.dungeon:SetPoint("TOPLEFT", 150, -54)
	bars.dungeonLabel = S.Text(bars, "GameFontHighlightSmall", "LEFT")
	bars.dungeonLabel:SetPoint("RIGHT", bars.dungeon, "LEFT", -8, 0)
	bars.rule = S.Text(bars, "GameFontHighlightSmall", "LEFT")
	bars.rule:SetPoint("TOPLEFT", 14, -72)
	bars.rule:SetWidth(rw - 28)
	CuratorOctoFull.SetWordWrap(bars.rule, true)
	bars.rule:SetTextColor(1, 0.62, 0.45)

	-- the rays turn while the page is shown
	CuratorOctoFull.SetScript(page, "OnUpdate", function(_, dt)
		CP.spin = CuratorOctoFull.Mod(((CP.spin or 0) + (dt or 0) * 0.12) , (2 * math.pi))
		if art.rays.SetRotation then
			CuratorOctoFull.SetRotation(art.rays, CP.spin)
		end
		art.glow:SetAlpha(0.4 + 0.08 * math.sin(CP.spin * 9))
	end)
	CuratorOctoFull.SetScript(page, "OnHide", function()
		CP.armed = nil
	end)
	return page
end

-- The button: a second click to be sure (the main changes once a month at most).
function CP:MakeMain()
	local r = RR()
	if not r or not r:CanChange() then
		ns.Play(ns.SND.close)
		return
	end
	if not self.armed then
		self.armed = true
		ns.Play(ns.SND.click)
		local A = ns.Album
		if A and A.frame and A.frame:IsShown() then
			A:Refresh()
		end
		return
	end
	self.armed = nil
	if r:SetMain(false) then
		ns.Play(ns.SND.stamp)
		ns.Print(string.format(L["%s is now your main character: it earns everything from level 1."], MyName()))
	end
end

-- (1 November) A booster of the chest under the mouse: its album, how many, its cards, when it opens.
function CP:PackTip(row)
	local e = row and row.e
	if not (e and e.s) then
		return
	end
	local C = ns.Collection
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:SeriesName(e.s), 1, 0.82, 0.25)
	local A = ns.Album
	if A and A.SubLine then
		GameTooltip:AddLine(A:SubLine(e.s), 0.8, 0.8, 0.8)
	end
	GameTooltip:AddLine(string.format(L["Boosters: %d"], e.n), 1, 1, 1)
	local owned, total = C:Progress(e.s)
	GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 0.8, 0.8, 0.8)
	local r = RR()
	if r then
		GameTooltip:AddLine(string.format(L["Opens at level %d"], r.LEVEL), 1, 0.62, 0.45)
	end
	GameTooltip:Show()
end

-- The rest of a number of things (more than shown): "and N more".
local function More(n)
	return "|cff9d9d9d" .. string.format(L["and %d more"], n) .. "|r"
end

function CP:Paint(A)
	local page = A.frame.chest
	local r = RR()
	if not (page and r) then
		return
	end
	local lf, rf = page.left, page.right
	local got = r:Contents()
	-- the photo of the place (the album of the zone, else the start of the character)
	local here = (ns.Rewards and ns.Rewards:ZoneSeries()) or ns.HomeSeries()
	lf.photo:SetTexture(ns.MEDIA .. ((here and here.studio) or "StudioElwynn"))
	local k = (LEFT_W / (page.h or 537)) / 2
	lf.photo:SetTexCoord(0.5 - k / 2, 0.5 + k / 2, 0, 1)
	S.SetFontObject(lf.title, "GameFontNormalLarge")
	local title = string.format(L["The chest of %s"], MyName())
	lf.title:SetText(title)
	if ns.TextWidth(lf.title) > LEFT_W - 24 then
		S.Fit(lf.title, title, LEFT_W - 24, 15, 10)
	end
	local lv, need = r:Level(), r.LEVEL
	lf.opens:SetText(string.format(L["Opens at level %d"], need))
	lf.level:SetProgress(math.min(1, lv / need))
	lf.level:SetText(string.format(L["Level %d / %d"], lv, need))
	local left = math.max(0, need - lv)
	lf.togo:SetText(left == 1 and L["1 level to go"] or string.format(L["%d levels to go"], left))
	lf.main:SetText(r:MainName() ~= "" and r:MainName() or "?")
	local ok, wait = r:CanChange()
	lf.make:SetEnabled(ok and true or false)
	lf.make:SetLabel(self.armed and L["Confirm: my main"] or L["Make it my main"])
	if not ok and wait > 0 then
		lf.note:SetText(string.format(L["Your main changes once a month at most: again in %s."], ns.Duration(wait)))
	else
		lf.note:SetText(string.format(L["Deleted before level %d, it takes its chest with it."], need))
	end
	-- what it holds
	rf.sub:SetText(string.format(L["A quarter of everything this character earns, kept until level %d: then it all goes to your collection."], need))
	for _, t in ipairs(rf.tiles) do
		local v = got[t.def.key] or 0
		t.value:SetText(ns.Num(v))
		t.value:SetTextColor(v > 0 and 1 or 0.55, v > 0 and 0.9 or 0.55, v > 0 and 0.62 or 0.58)
		t.icon:SetDesaturated(v <= 0)
		t.icon:SetAlpha(v > 0 and 1 or 0.5)
		-- (the boosters of albums: the booster of the first of them on the tile)
		if t.pack then
			local first = got.albums[1]
			if first then
				if t.pack.series ~= first.s then
					t.pack:SetSeries(first.s)
				end
				t.pack:Show()
				t.icon:Hide()
			else
				t.pack:Hide()
				t.icon:Show()
			end
		end
	end
	-- its boosters, album by album, each its booster (then the rewards to choose; past the rows, how many more)
	local entries = {}
	for _, a in ipairs(got.albums) do
		entries[CuratorOctoFull.Length(entries) + 1] = { s = a.s, n = a.n }
	end
	if got.choice > 0 then
		entries[CuratorOctoFull.Length(entries) + 1] = { text = L["Rewards to choose"] .. "  |cffffd24a×" .. got.choice .. "|r" }
	end
	local rows = rf.packs.rows
	local shown = entries
	if CuratorOctoFull.Length(entries) > CuratorOctoFull.Length(rows) then
		shown = {}
		for i = 1, CuratorOctoFull.Length(rows) - 1 do
			shown[i] = entries[i]
		end
		shown[CuratorOctoFull.Length(rows)] = { text = More(CuratorOctoFull.Length(entries) - CuratorOctoFull.Length(rows) + 1) }
	elseif CuratorOctoFull.Length(entries) == 0 then
		shown = { { text = "|cff9d9d9d" .. L["Nothing yet."] .. "|r" } }
	end
	for i, r in ipairs(rows) do
		local e = shown[i]
		r.e = e
		if e and e.s then
			if r.pack.series ~= e.s then
				r.pack:SetSeries(e.s)
			end
			r.pack:Show()
			local g = e.s.glow or { 1, 0.8, 0.4 }
			r.name:SetTextColor(0.8 + 0.2 * g[1], 0.78 + 0.2 * g[2], 0.6 + 0.2 * g[3])
			S.Fit(r.name, ns.Collection:SeriesName(e.s), TILE_W - 74, 12, 9)
			r.count:SetText("×" .. e.n)
			r.text:SetText("")
			r:Show()
		elseif e then
			r.pack:Hide()
			r.name:SetText("")
			r.count:SetText("")
			r.text:SetText(e.text)
			r:Show()
		else
			r:Hide()
		end
	end
	-- its cards, the rarest first, in the colour of their rarity
	local cards = {}
	for _, x in ipairs(got.list) do
		cards[CuratorOctoFull.Length(cards) + 1] = x
	end
	table.sort(cards, function(a, b)
		if a.card.rarity ~= b.card.rarity then
			return a.card.rarity > b.card.rarity
		end
		return ns.Collection:Name(a.card) < ns.Collection:Name(b.card)
	end)
	for i, fs in ipairs(rf.cards.lines) do
		local x = cards[i]
		if CuratorOctoFull.Length(cards) > LIST_ROWS and i == LIST_ROWS then
			fs:SetText(More(CuratorOctoFull.Length(cards) - LIST_ROWS + 1))
		elseif x then
			local c = ns.RARITY[math.min(CuratorOctoFull.Length(ns.RARITY), x.card.rarity)].text
			fs:SetText(string.format(("|cff%02x%02x%02x%s|r"), c[1] * 255, c[2] * 255, c[3] * 255, ns.Collection:Name(x.card)))
		else
			fs:SetText(i == 1 and ("|cff9d9d9d" .. L["Nothing yet."] .. "|r") or "")
		end
	end
	-- its bars
	local bars = rf.bars
	local world, dungeon = r:Bar("world"), r:Bar("dungeon")
	bars.world:SetProgress(world / ns.PACK_POINTS)
	bars.world:SetText("")
	-- (their words left of the bars, in the room the panel gives them: some languages are long)
	for _, x in ipairs({ { bars.worldLabel, string.format(L["World: %d%%"], math.floor(100 * world / ns.PACK_POINTS)) },
		{ bars.dungeonLabel, string.format(L["Dungeons and raids: %d%%"], math.floor(100 * dungeon / ns.PACK_POINTS)) } }) do
		S.SetFontObject(x[1], "GameFontHighlightSmall")
		x[1]:SetText(x[2])
		if ns.TextWidth(x[1]) > 128 then
			S.Fit(x[1], x[2], 128, 10, 7.5)
		end
	end
	bars.dungeon:SetProgress(dungeon / ns.PACK_POINTS)
	bars.dungeon:SetText("")
	-- (1.14.0, after its test, his word: all that a reroll does not do, Reroll.lua: RR:Rules)
	bars.rule:SetText(r:Rules())
	-- the head of the window: the level toward the chest
	A:SetTitle(L["Chest"], string.format(L["This character is a reroll: a quarter of everything, kept here until level %d."], need))
	A:SetBar(math.min(lv, need), need, string.format(L["Level %d / %d"], lv, need))
end

local A = ns.Album
if A then
	function A:ShowChestPage(shown)
		local f = self.frame
		if shown then
			CP:Build(self)
		end
		if f.chest then
			CuratorOctoFull.SetShown(f.chest, shown)
		end
	end

	function A:RefreshChest()
		local f = self.frame
		-- (no reroll any more: its chest opened; back to the inventory)
		local r = RR()
		if not (r and r:IsReroll()) then
			self.mode = "inventory"
			return self:Refresh()
		end
		for _, c in ipairs(f.slots) do
			c:Hide()
			c.sig = nil
		end
		f.toc:Hide()
		f.list:Hide()
		self:ShowPager(false)
		self:RefreshFooter(false)
		CP:Paint(self)
	end

	-- The page of the chest, from anywhere (/curator chest, a toast).
	function A:ShowChestTab()
		self:Build()
		self.mode, self.member, self.memberEntries, self.returnMode = "chest", nil, nil, nil
		self:HideDetail()
		self:Reveal()
	end
end

-- what goes into the chest, while its page is shown
ns.On("CHEST_CHANGED", function()
	local A2 = ns.Album
	if A2 and A2.mode == "chest" and A2.frame and A2.frame:IsShown() then
		A2:Refresh()
	end
end)

-------------------------------------------------------------------------------
-- The tests of the author (his build): on a copy of his collection, nothing kept
-------------------------------------------------------------------------------
local FR = {
	["(Test: this character as a reroll under level 15, on a copy of your collection: nothing is kept. Kill, loot, quest: a quarter of everything goes into its chest. /curator test coffre opens it; /curator test reroll again: back to your collection.)"] =
		"(Test : ce perso fait comme un reroll de moins de 15, sur une copie de ta collection : rien n'est gardé. Tue, ramasse, fais des quêtes : un quart de tout va dans son coffre. /curator test coffre l'ouvre ; retape /curator test reroll pour revenir à ta collection.)",
	["(Test over: your own collection is back.)"] = "(Test terminé : ta vraie collection est revenue.)",
	["(Test: the collection as the release of WoW Forever makes it, on a copy: only its Hallow's End and Hardcup cards kept. /curator test sortie again: back to your collection.)"] =
		"(Test : la collection telle que la sortie de WoW Forever la fait, sur une copie : seules ses cartes de la Sanssaint et de la Hardcup restent. Retape /curator test sortie pour revenir à ta collection.)",
	["(Test: a chest made up for the show, nothing is kept.)"] = "(Test : un coffre inventé pour l'aperçu, rien n'est gardé.)",
	["(Another test runs already: end it first.)"] = "(Un autre test est déjà en cours : termine-le d'abord.)",
	["(Test: the window of a new reroll, as it shows at its first login.)"] = "(Test : la fenêtre d'un nouveau reroll, telle qu'elle s'affiche à sa première connexion.)",
}
local function T(k)
	return (GetLocale and GetLocale() == "frFR" and FR[k]) or k
end
UI.TEST_TEXT = FR

-- The test that runs: "reroll", "release" (nil: none).
function UI:Testing()
	local AD = ns.Admin
	return (AD and AD.Lent and AD:Lent() and self.testing) or nil
end

local function Lend(copy, what)
	local AD = ns.Admin
	if not (AD and AD.Lend) then
		return false
	end
	if AD:Lend(copy) then
		UI.testing = what
		return true
	end
	return false
end

local function Back()
	local r = RR()
	if r then
		r.forceReroll, r.test = nil, nil
	end
	UI.testing = nil
	local AD = ns.Admin
	if AD and AD.Restore then
		AD:Restore()
	end
	ns.Print(T("(Test over: your own collection is back.)"))
end

function UI:Test(kind)
	local r = RR()
	local AD = ns.Admin
	if not (r and AD and ns.db) then
		return
	end
	local running = self:Testing()
	if kind == "reroll" or kind == "release" then
		if running == kind then
			return Back()
		end
		if running or (AD.Lent and AD:Lent()) then
			ns.Print(T("(Another test runs already: end it first.)"))
			return
		end
		local copy = r.Copy(ns.db)
		if kind == "reroll" then
			if not Lend(copy, "reroll") then
				return
			end
			r.test, r.forceReroll = true, true
			ns.Print(T("(Test: this character as a reroll under level 15, on a copy of your collection: nothing is kept. Kill, loot, quest: a quarter of everything goes into its chest. /curator test coffre opens it; /curator test reroll again: back to your collection.)"))
		else
			copy.forever = nil
			if not Lend(copy, "release") then
				return
			end
			r:Migrate()
			r:Bind()
			r:SetMain(true)
			ns.Print(T("(Test: the collection as the release of WoW Forever makes it, on a copy: only its Hallow's End and Hardcup cards kept. /curator test sortie again: back to your collection.)"))
			ns.Print(L["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."])
		end
		ns.Fire("CHANGED")
		return
	end
	if kind == "chest" then
		if running == "reroll" then
			-- (the chest of the test opened: what this session put in it)
			r.forceReroll = nil
			r.test = true
			local got = r:Open()
			r.forceReroll = true
			if not got or (got.boosters + got.cards + got.xp + got.rubies) <= 0 then
				ns.Print(L["Nothing yet."])
			end
			return
		end
		-- (a chest made up, for the show: nothing kept)
		ns.Print(T("(Test: a chest made up for the show, nothing is kept.)"))
		local got = { packs = 0, choice = 1, boosters = 0, cards = 3, xp = 640, rubies = 12, albums = {}, list = {} }
		for _, key in ipairs({ "elwynn", "westfall", "dunmorogh" }) do
			local s = ns.SeriesByKey(key)
			if s then
				local n = (key == "elwynn") and 5 or 2
				got.albums[CuratorOctoFull.Length(got.albums) + 1] = { s = s, n = n }
				got.packs = got.packs + n
			end
		end
		got.boosters = got.packs + got.choice
		self:Opened(got)
		return
	end
	if kind == "main" then
		ns.Print(T("(Test: the window of a new reroll, as it shows at its first login.)"))
		local was = r.forceReroll
		r.forceReroll = true
		self:Ask(true)
		r.forceReroll = was
		return
	end
end
