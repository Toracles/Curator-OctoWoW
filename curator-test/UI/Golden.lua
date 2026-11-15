local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.10.0) The golden quests in the game (Golden.lua): the window of the quest (from the leader: his line in
-- his window of dialogue, or a button while he is the target, close by; else /curator golden: where the
-- quest of the week stands), the follow-up on the screen, the alerts, and the markers: a green ! over a
-- leader who has a quest to give, a green ? when it can be turned in (grey while it is under way), over his
-- head (on his name plate, when the player shows the name plates of the friendly NPCs: 1.13.0, Curator no longer
-- shows them for him nor hides the others), on the map and on the minimap. /curator markers: on or off.
-- (1.13.0) The golden quests paused while they are reworked (Golden.lua: GQ.PAUSED): the leaders say it, the page of
-- the quests says it; a quest done this week can still be turned in.
-------------------------------------------------------------------------------
local UI = {}
ns.GoldenUI = UI

local GQ = ns.Golden
local GREEN = { 0.35, 1, 0.4 }
local GOLD = { 1, 0.82, 0.3 }
local DIM = { 0.62, 0.62, 0.62 }
local PACK_CROP = { 30 / 256, 226 / 256, 110 / 512, 306 / 512 }
UI.ICON_OFFER = "Interface\\GossipFrame\\AvailableQuestIcon"
UI.ICON_TURN = "Interface\\GossipFrame\\ActiveQuestIcon"

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b, c = pcall(fn, unpack(arg, 1, arg.n))
	if not ok or Secret(a) then
		return nil
	end
	return a, b, c
end

-- A marker of a state ("offer": a green !, "ready": a green ?, "active": a grey ?) on a texture.
function UI.PaintMark(tex, state)
	tex:SetTexture(state == "offer" and UI.ICON_OFFER or UI.ICON_TURN)
	tex:SetDesaturated(true)
	if state == "active" then
		tex:SetVertexColor(DIM[1], DIM[2], DIM[3])
	else
		tex:SetVertexColor(GREEN[1], GREEN[2], GREEN[3])
	end
end

-- The state of a leader that shows a marker (nil: none).
function UI:MarkOf(l)
	if not (ns.db and l) or ns.db.goldMarks == false then
		return nil
	end
	local st = GQ:State(l)
	if st == "offer" or st == "ready" or st == "active" then
		return st
	end
	return nil
end

-- The names of a list of albums, in the language of the game.
local function Names(list)
	local out = {}
	for _, s in ipairs(list) do
		out[CuratorOctoFull.Length(out) + 1] = ns.Collection:SeriesName(s)
	end
	return table.concat(out, ", ")
end

-- What is missing of an album in epic or better: "3 epics, 1 legendary, the mythic", or nothing.
function UI:Missing(s)
	local miss = { 0, 0, 0 }
	for r = 4, 6 do
		for _, card in ipairs(s.byRarity[r] or {}) do
			if not ns.Collection:Owned(card) then
				miss[r - 3] = miss[r - 3] + 1
			end
		end
	end
	local parts = {}
	if miss[1] > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format((miss[1] == 1 and L["%d epic"] or L["%d epics"]), miss[1])
	end
	if miss[2] > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = string.format((miss[2] == 1 and L["%d legendary"] or L["%d legendaries"]), miss[2])
	end
	if miss[3] > 0 then
		parts[CuratorOctoFull.Length(parts) + 1] = L["the mythic"]
	end
	if CuratorOctoFull.Length(parts) == 0 then
		return nil
	end
	return table.concat(parts, ", ")
end

-- The words of a leader, then what his lands are for a tranche.
local SPEECH = {
	thrall = "Lok'tar, champion. The Horde is only as strong as its lands are safe. Clear them, hunt the beasts of legend that roam them, and prove yourself in the depths. Come back before the week is out, and gold awaits you.",
	cairne = "Walk with the Earth Mother, young one. The lands of the shu'halo are troubled. Bring them balance, hunt what preys on them, and face the darkness below. Come back before the week ends: your reward will shine like the sun.",
	sylvanas = "The Forsaken do not wait. My lands are infested: purge them, hunt the beasts that defy me, and bring death to the depths. Before the week is over. Fail me, and you will have nothing.",
	bolvar = "Stormwind needs every willing blade. Our lands are threatened: drive the enemy back, hunt their champions, and clear the dungeons that fester in the dark. Report back before the week ends, and the kingdom will reward you in gold.",
	magni = "Well met, friend! The lands of the dwarves need sturdy hands. Thin out the beasts, track down the big ones, and delve deep where the trouble is hiding. Be back before the week is out, and there is gold in it for you!",
	tyrande = "Elune's light guides you, traveler. The forests of Kalimdor are suffering. Cleanse them, hunt the creatures that defile them, and go down into the shadows below. Come back before the week ends, and Elune will bless you with gold.",
}

-------------------------------------------------------------------------------
-- The window of the quest
-------------------------------------------------------------------------------
local W, PAD = 470, 22
-- (the height of a golden booster to choose: its pack, its album, what it would fill)
local CHOICE_H = 124

function UI:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorGolden", W, 600)
	f:SetPoint("CENTER", -120, 40)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorGolden")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			UI:Hide()
		end)
	end
	local inner = W - 2 * PAD

	f.head = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.head:SetPoint("TOPLEFT", 64, -34)
	f.head:SetWidth(W - 64 - PAD)
	f.head:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

	f.speech = S.Text(f, "GameFontHighlight", "LEFT")
	f.speech:SetPoint("TOPLEFT", PAD, -74)
	f.speech:SetWidth(inner)
	CuratorOctoFull.SetWordWrap(f.speech, true)
	f.speech:SetSpacing(2)

	f.lands = S.Text(f, "GameFontNormal", "LEFT")
	f.lands:SetWidth(inner)
	CuratorOctoFull.SetWordWrap(f.lands, true)

	f.objTitle = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.objTitle:SetText(L["Objectives"])
	f.objTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.obj = {}
	for i = 1, 4 do
		local fs = S.Text(f, "GameFontHighlight", "LEFT")
		fs:SetWidth(inner - 12)
		CuratorOctoFull.SetWordWrap(fs, true)
		f.obj[i] = fs
	end
	f.dungeons = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.dungeons:SetWidth(inner - 12)
	CuratorOctoFull.SetWordWrap(f.dungeons, true)
	f.dungeons:SetTextColor(DIM[1] + 0.15, DIM[2] + 0.15, DIM[3] + 0.15)

	f.rewTitle = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.rewTitle:SetText(L["Rewards"])
	f.rewTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	f.rew = S.Text(f, "GameFontHighlight", "LEFT")
	f.rew:SetWidth(inner)
	CuratorOctoFull.SetWordWrap(f.rew, true)

	-- the three golden boosters to choose
	f.choices = {}
	local cw = math.floor((inner - 2 * 10) / 3)
	for i = 1, GQ.CHOICES do
		local i = i; local b = CreateFrame("Button", nil, f)
		CuratorOctoFull.SetSize(b, cw, CHOICE_H)
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		CuratorOctoFull.ColorTexture(b.bg, 0, 0, 0, 0.35)
		-- (the one chosen: a frame of gold around it, a light of gold in it)
		b.sel = CreateFrame("Frame", nil, b)
		b.sel:SetPoint("TOPLEFT", -2, 2)
		b.sel:SetPoint("BOTTOMRIGHT", 2, -2)
		b.sel.fill = b.sel:CreateTexture(nil, "BACKGROUND")
		b.sel.fill:SetAllPoints(b)
		CuratorOctoFull.ColorTexture(b.sel.fill, GOLD[1], GOLD[2], GOLD[3], 0.14)
		for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
			local t = b.sel:CreateTexture(nil, "BORDER")
			CuratorOctoFull.ColorTexture(t, GOLD[1], GOLD[2], GOLD[3], 0.95)
			t:SetPoint(e[1])
			t:SetPoint(e[2])
			if e[3] then
				t:SetHeight(2)
			else
				t:SetWidth(2)
			end
		end
		b.sel:Hide()
		b.icon = b:CreateTexture(nil, "ARTWORK")
		CuratorOctoFull.SetSize(b.icon, 44, 44)
		b.icon:SetPoint("TOP", 0, -6)
		b.icon:SetTexCoord(PACK_CROP[1], PACK_CROP[2], PACK_CROP[3], PACK_CROP[4])
		b.name = S.Text(b, "GameFontNormalSmall", "CENTER")
		b.name:SetPoint("TOP", b.icon, "BOTTOM", 0, -3)
		b.name:SetWidth(cw - 8)
		CuratorOctoFull.SetWordWrap(b.name, true)
		b.miss = S.Text(b, "GameFontHighlightSmall", "CENTER")
		b.miss:SetPoint("TOP", b.name, "BOTTOM", 0, -2)
		b.miss:SetWidth(cw - 8)
		CuratorOctoFull.SetWordWrap(b.miss, true)
		b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			UI:Select(self.s)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			if self.s then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(L["Golden booster"] .. ": " .. ns.Collection:SeriesName(self.s), GOLD[1], GOLD[2], GOLD[3])
				GameTooltip:AddLine(L["5 cards, every one epic or better, the first one legendary (now and then mythic)."], 1, 1, 1, true)
				local miss = UI:Missing(self.s)
				GameTooltip:AddLine(miss and string.format(L["Missing: %s"], miss) or L["Nothing missing in epic or better"], DIM[1], DIM[2], DIM[3], true)
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		f.choices[i] = b
	end

	f.time = S.Text(f, "GameFontNormal", "LEFT")
	f.time:SetWidth(inner)
	f.warn = S.Text(f, "GameFontHighlight", "LEFT")
	f.warn:SetWidth(inner)
	CuratorOctoFull.SetWordWrap(f.warn, true)
	f.warn:SetTextColor(1, 0.35, 0.25)

	f.go = S.Button(f, L["Accept"], 170, 26)
	f.go:SetPoint("BOTTOMRIGHT", -PAD, 18)
	CuratorOctoFull.SetScript(f.go, "OnClick", function()
		UI:Go()
	end)
	f.drop = S.Button(f, L["Abandon"], 150, 26)
	f.drop:SetPoint("BOTTOMLEFT", PAD, 18)
	CuratorOctoFull.SetScript(f.drop, "OnClick", function()
		UI:Drop()
	end)
	self.frame = f
	return f
end

-- Lays the parts out from the top, each under the one before (their heights follow their texts).
local function Below(fs, above, gap)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -(gap or 8))
end

function UI:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

-- Opens the window: l, the leader (nil: the leader of the quest under way, else none); here: talked to
-- him (taking, turning in), else what the quest of the week is.
function UI:Open(l, here)
	if not ns.db or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	local q = GQ:Quest()
	l = l or (q and GQ:Leader(q.leader))
	self.leader, self.here, self.choice, self.armed, self.dropArmed = l, here and true or false, nil, false, false
	self:Build()
	self:Paint()
	self.frame:Show()
	ns.Play(ns.SND.open or ns.SND.click)
end

-- /curator golden: the quest under way, else what the week holds.
function UI:ShowStatus()
	local f = self.frame
	if f and f:IsShown() then
		return self:Hide()
	end
	self:Open(nil, false)
end

function UI:Select(s)
	if not s then
		return
	end
	self.choice = s.key
	ns.Play(ns.SND.click)
	self:Paint()
end

function UI:Paint()
	local f = self.frame
	if not f then
		return
	end
	local l = self.leader
	local q = GQ:Quest()
	local state = l and GQ:State(l) or nil
	local mine = q and l and q.leader == l.key and GQ:Mine(q)
	local bracket = (mine and q.bracket) or GQ:Bracket(GQ:TakerLevel())
	local week = (mine and q.week) or GQ:Week()
	f:SetTitle(l and string.format(L["Golden quest: %s"], GQ:LeaderName(l)) or L["Golden quest"])
	-- no leader (/curator golden, nothing under way): what the week holds, the leaders of the side
	if not l then
		local names = {}
		for _, x in ipairs(GQ:Leaders(GQ:Faction())) do
			names[CuratorOctoFull.Length(names) + 1] = GQ:LeaderName(x)
		end
		f.head:SetText(L["Golden quest"])
		if GQ:Paused() then
			f.speech:SetText(L["The golden quest is being reworked: it is not available for now."])
		elseif GQ:DoneThisWeek() then
			f.speech:SetText(L["You already turned in your golden quest this week. Come back after the reset (Wednesday, 5:00)."])
		else
			f.speech:SetText(string.format(L["No golden quest under way. Each week, the leaders of your side give one, from the level 10: %s."], table.concat(names, ", ")))
		end
		self:Only(f.speech)
		Below(f.time, f.speech, 14)
		f.time:SetText(string.format(L["Next reset: %s"], ns.Duration(GQ:Left())))
		CuratorOctoFull.SetShown(f.time, not GQ:Paused())
		f.go:Hide()
		f.drop:Hide()
		f:SetHeight(math.max(200, 120 + f.speech:GetStringHeight() + 60))
		return
	end
	f.head:SetText(string.format(L["The Trial of %s"], GQ:LeaderName(l)))
	f.speech:SetText(L[SPEECH[l.key] or ""] or "")
	-- what the leader says to a state with nothing to take
	local note
	if state == "paused" then
		note = L["The golden quest is being reworked: it is not available for now."]
	elseif state == "done" then
		note = L["You already turned in your golden quest this week. Come back after the reset (Wednesday, 5:00)."]
	elseif state == "busy" then
		if q and not GQ:Mine(q) then
			-- (the name of the character, its realm only when it is another one)
			local who = tostring(q.char or "?")
			local realm = Safe(GetRealmName)
			if type(realm) == "string" and realm ~= "" and string.sub(who, -(CuratorOctoFull.Length(realm) + 1)) == "-" .. realm then
				who = string.sub(who, 1, -(CuratorOctoFull.Length(realm) + 2))
			end
			note = string.format(L["%s is doing your golden quest of the week."], who)
		else
			note = string.format(L["Your golden quest of the week is with %s."], GQ:LeaderName(GQ:Leader(q and q.leader)))
		end
	elseif state == "low" then
		note = L["Come back to me at the level 10."]
	elseif state == "reroll" then
		-- (1.14.0: no golden quest for a reroll, Reroll.lua)
		note = string.format(L["Come back to me with this character at level %d: a reroll does no golden quest before."], ns.Reroll and ns.Reroll.LEVEL or 15)
	elseif state == "foe" then
		note = L["This leader gives his golden quests to his own side only."]
	end
	if note then
		f.speech:SetText(note)
		self:Only(f.speech)
		f.go:Hide()
		f.drop:Hide()
		f:SetHeight(math.max(200, 120 + f.speech:GetStringHeight() + 40))
		return
	end
	-- the quest: its lands, its objectives (with what was done), its rewards, the time left
	for _, part in ipairs({ f.lands, f.objTitle, f.dungeons, f.rewTitle, f.rew, f.time, f.warn }) do
		part:Show()
	end
	local zones = GQ:Zones(l, bracket)
	f.lands:SetText(string.format(L["My lands for your tranche (levels %s): %s."], self:RangeText(bracket), Names(zones)))
	Below(f.lands, f.speech, 10)
	Below(f.objTitle, f.lands, 14)
	local lines = self:ObjectiveLines(mine and q or nil)
	local above = f.objTitle
	for i, fs in ipairs(f.obj) do
		local line = lines[i]
		fs:SetText(line and line.text or "")
		fs:SetTextColor(line and line.done and GREEN[1] or 1, line and line.done and GREEN[2] or 1, line and line.done and GREEN[3] or 1)
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", above, "BOTTOMLEFT", i == 1 and 10 or 0, -(i == 1 and 8 or 4))
		CuratorOctoFull.SetShown(fs, line ~= nil)
		above = fs
	end
	f.dungeons:SetText(string.format(L["Dungeons of your tranche: %s."], Names(GQ:AllDungeons(bracket))))
	Below(f.dungeons, above, 4)
	-- (under the dungeons, at the left of the objectives: their lines stand 10 to the right)
	f.rewTitle:ClearAllPoints()
	f.rewTitle:SetPoint("TOPLEFT", f.dungeons, "BOTTOMLEFT", -10, -14)
	-- (1.11.0) its rubies too
	if ns.Rubies then
		f.rew:SetText(string.format(L["%s XP, %s points on the booster bar and %s, then a golden booster of your choice:"], ns.Num(GQ.XP), ns.Num(GQ.POINTS), ns.Rubies.Text(ns.Rubies.GOLDEN, 14)))
	else
		f.rew:SetText(string.format(L["%s XP and %s points on the booster bar, then a golden booster of your choice:"], ns.Num(GQ.XP), ns.Num(GQ.POINTS)))
	end
	Below(f.rew, f.rewTitle, 6)
	local choices = GQ:Choices(l.key, bracket, week)
	local cw = f.choices[1]:GetWidth()
	for i, b in ipairs(f.choices) do
		local s = choices[i]
		b.s = s
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", f.rew, "BOTTOMLEFT", (i - 1) * (cw + 10), -10)
		if s then
			b.icon:SetTexture(MEDIA .. (s.pack or "PackElwynn") .. "Bottom")
			b.icon:SetDesaturated(true)
			b.icon:SetVertexColor(1, 0.8, 0.34)
			b.name:SetText(ns.Collection:SeriesName(s))
			local miss = self:Missing(s)
			b.miss:SetText(miss and string.format(L["Missing: %s"], miss) or L["Nothing missing in epic or better"])
			CuratorOctoFull.SetShown(b.sel, self.choice == s.key)
			CuratorOctoFull.SetEnabled(b, state == "ready" and self.here)
			b:Show()
		else
			b:Hide()
		end
	end
	f.time:ClearAllPoints()
	f.time:SetPoint("TOPLEFT", f.rew, "BOTTOMLEFT", 0, -(CHOICE_H + 20))
	local left = GQ:Left()
	f.time:SetText(string.format(L["Time left: %s (the reset: Wednesday, 5:00)"], ns.Duration(left)))
	Below(f.warn, f.time, 6)
	f.warn:SetText("")
	-- the buttons: take it, turn it in, give it up
	f.go:Show()
	CuratorOctoFull.SetEnabled(f.go, true)
	if state == "offer" then
		f.go:SetLabel(self.armed and L["Accept anyway"] or L["Accept"])
		CuratorOctoFull.SetEnabled(f.go, self.here)
		if self.armed then
			f.warn:SetText(string.format(L["Only %s left before the reset: the quest is lost if you do not turn it in in time."], ns.Duration(left)))
		elseif not self.here then
			f.warn:SetText(string.format(L["Talk to %s in his city to take it."], GQ:LeaderName(l)))
			f.warn:SetTextColor(DIM[1], DIM[2], DIM[3])
		end
	elseif state == "ready" then
		f.go:SetLabel(L["Turn in"])
		CuratorOctoFull.SetEnabled(f.go, self.here and self.choice ~= nil)
		if not self.here then
			f.warn:SetText(string.format(L["Go back to %s in his city to turn it in."], GQ:LeaderName(l)))
			f.warn:SetTextColor(DIM[1], DIM[2], DIM[3])
		elseif not self.choice then
			f.warn:SetText(L["Choose your golden booster."])
			f.warn:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
		end
	else
		f.go:Hide()
	end
	if state == "offer" and not self.armed and self.here then
		f.warn:SetTextColor(1, 0.35, 0.25)
	elseif state == "offer" and self.armed then
		f.warn:SetTextColor(1, 0.35, 0.25)
	end
	CuratorOctoFull.SetShown(f.drop, state == "active" or state == "ready")
	f.drop:SetLabel(self.dropArmed and L["Click again to abandon"] or L["Abandon"])
	-- its height: its parts from the top, each as tall as its text (they wrap), then the buttons under them
	local function Tall(fs)
		local t = fs:GetText()
		return (fs:IsShown() and t and t ~= "") and fs:GetStringHeight() or 0
	end
	local h = 74 + Tall(f.speech) + 10 + Tall(f.lands) + 14 + Tall(f.objTitle) + 8
	for i, fs in ipairs(f.obj) do
		h = h + Tall(fs) + (i > 1 and 4 or 0)
	end
	h = h + 4 + Tall(f.dungeons) + 14 + Tall(f.rewTitle) + 6 + Tall(f.rew) + CHOICE_H + 20 + Tall(f.time) + 6 + Tall(f.warn) + 60
	f:SetHeight(math.max(420, math.floor(h + 0.5)))
end

-- Only the head and one text (the other parts hidden).
function UI:Only(text)
	local f = self.frame
	for _, part in ipairs({ f.lands, f.objTitle, f.dungeons, f.rewTitle, f.rew, f.time, f.warn }) do
		part:Hide()
	end
	for _, fs in ipairs(f.obj) do
		fs:Hide()
	end
	for _, b in ipairs(f.choices) do
		b:Hide()
	end
	text:Show()
end

function UI:RangeText(bracket)
	local lo, hi = GQ:Range(bracket or 10)
	return lo == hi and tostring(lo) or (lo .. "-" .. hi)
end

-- The objectives as lines: { text, done } (q: the quest under way, its counts; nil: what it asks).
function UI:ObjectiveLines(q)
	local k = q and (tonumber(q.kills) or 0) or nil
	local g = q and (tonumber(q.gathers) or 0) or nil
	local r = q and (tonumber(q.rares) or 0) or nil
	local d = q and (tonumber(q.dungeons) or 0) or nil
	local purge = q and GQ:PurgeDone(q)
	local function Count(text, got, need)
		if got then
			return text .. string.format(("  (%d/%d)"), math.min(got, need), need)
		end
		return text
	end
	return {
		{ text = Count(string.format(L["Defeat %d creatures in my lands"], GQ.KILLS), k, GQ.KILLS), done = purge },
		{ text = q and (string.format(L["or %d creatures and %d gatherings (mining, herbs, skins)"], GQ.KILLS_WITH_GATHERS, GQ.GATHERS)
			.. string.format(("  (%d/%d, %d/%d)"), math.min(k, GQ.KILLS_WITH_GATHERS), GQ.KILLS_WITH_GATHERS, math.min(g, GQ.GATHERS), GQ.GATHERS))
			or string.format(L["or %d creatures and %d gatherings (mining, herbs, skins)"], GQ.KILLS_WITH_GATHERS, GQ.GATHERS), done = purge },
		{ text = Count(string.format(L["Defeat %d rares in my lands"], GQ.RARES), r, GQ.RARES), done = r and r >= GQ.RARES },
		{ text = Count(string.format(L["Complete %d dungeons of your tranche"], GQ.DUNGEONS), d, GQ.DUNGEONS), done = d and d >= GQ.DUNGEONS },
	}
end

-- The button of the window: take the quest (twice when little time is left), turn it in.
function UI:Go()
	local l = self.leader
	if not (l and self.here) then
		return
	end
	local state = GQ:State(l)
	if state == "offer" then
		if not self.armed and GQ:Left() < GQ.WARN_LEFT then
			self.armed = true
			ns.Play(ns.SND.click)
			return self:Paint()
		end
		if GQ:Accept(l.key) then
			ns.Play(ns.SND.questDone)
			self.armed = false
			self:Paint()
		end
	elseif state == "ready" and self.choice then
		local ok = GQ:TurnIn(self.choice)
		if ok then
			self:Hide()
		end
	end
end

function UI:Drop()
	if not self.dropArmed then
		self.dropArmed = true
		ns.Play(ns.SND.click)
		return self:Paint()
	end
	self.dropArmed = false
	if GQ:Abandon() then
		ns.Print(L["Golden quest abandoned."])
	end
	self:Paint()
end

-------------------------------------------------------------------------------
-- From the leader: his line in his window of dialogue, and a button while he is the target, close by
-------------------------------------------------------------------------------
ns.Gossip:Provide("leader", function(npc)
	local l = GQ:LeaderByNpc(npc)
	local st = l and GQ:State(l)
	if not st or st == "foe" then
		return {}
	end
	-- (1.13.0: paused, being reworked: his line says it, his window too)
	if st == "paused" then
		return { { text = L["The golden quest (being reworked)"], icon = "Interface\\GossipFrame\\GossipGossipIcon", click = function()
			UI:Open(l, true)
		end } }
	end
	local text = (st == "ready" and L["I have done your golden quest."]) or L["I come for the golden quest."]
	return { { text = text, icon = st == "offer" and UI.ICON_OFFER or UI.ICON_TURN, click = function()
		UI:Open(l, true)
	end } }
end)

-- Is the target a leader of my side, close by? (the leader, else nil)
function UI:TargetLeader()
	if not Safe(UnitExists, "target") then
		return nil
	end
	local guid = Safe(UnitGUID, "target")
	local npc = guid and tonumber((CuratorOctoFull.Select(6, strsplit("-", guid))))
	local l = GQ:LeaderByNpc(npc)
	if not l or GQ:State(l) == "foe" then
		return nil
	end
	-- (close by: the distance of a trade; not known, he counts as close)
	if CheckInteractDistance then
		local ok, near = pcall(CheckInteractDistance, "target", 2)
		if ok and not Secret(near) and not near then
			return nil
		end
	end
	return l
end

function UI:BuildPrompt()
	if self.prompt then
		return self.prompt
	end
	local b = CreateFrame("Button", "CuratorGoldenPrompt", UIParent)
	CuratorOctoFull.SetSize(b, 260, 40)
	b:SetPoint("TOP", UIParent, "TOP", 0, -150)
	b:SetFrameStrata("HIGH")
	-- (a line of gold around it: its edge under its background, a pixel larger)
	b.edge = b:CreateTexture(nil, "BACKGROUND", nil, 0)
	b.edge:SetPoint("TOPLEFT", -1, 1)
	b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(b.edge, GOLD[1], GOLD[2], GOLD[3], 0.7)
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.bg, 0.05, 0.04, 0.02, 0.92)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, 26, 26)
	b.icon:SetPoint("LEFT", 8, 0)
	b.text = S.Text(b, "GameFontNormal", "LEFT")
	b.text:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
	b.text:SetPoint("RIGHT", -8, 0)
	b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
	CuratorOctoFull.SetScript(b, "OnClick", function(self)
		if self.l then
			UI:Open(self.l, true)
		end
	end)
	b:Hide()
	self.prompt = b
	return b
end

function UI:UpdatePrompt()
	local l = self:TargetLeader()
	local st = l and GQ:State(l)
	local b = self.prompt
	if not (st == "offer" or st == "ready" or st == "active") then
		if b then
			b:Hide()
		end
		return
	end
	b = self:BuildPrompt()
	b.l = l
	UI.PaintMark(b.icon, st)
	b.text:SetText(st == "ready" and L["Turn in the golden quest"] or string.format(L["Golden quest of %s"], GQ:LeaderName(l)))
	b:Show()
end

-------------------------------------------------------------------------------
-- The follow-up on the screen (the quest under way, of the character playing): its counts, the time left.
-- Shift-drag moves it (it keeps its place); a click opens the window.
-------------------------------------------------------------------------------
local TRACKER_W = 290

function UI:BuildTracker()
	if self.tracker then
		return self.tracker
	end
	local t = CreateFrame("Button", "CuratorGoldenTracker", UIParent)
	CuratorOctoFull.SetSize(t, TRACKER_W, 120)
	t:SetFrameStrata("MEDIUM")
	t:SetMovable(true)
	t:SetClampedToScreen(true)
	t:RegisterForDrag("LeftButton")
	CuratorOctoFull.SetScript(t, "OnDragStart", function(self)
		if IsShiftKeyDown and IsShiftKeyDown() then
			self:StartMoving()
		end
	end)
	CuratorOctoFull.SetScript(t, "OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, rel, x, y = self:GetPoint(1)
		if ns.db then
			ns.db.goldAt = { point, rel, math.floor(x + 0.5), math.floor(y + 0.5) }
		end
	end)
	CuratorOctoFull.SetScript(t, "OnClick", function()
		UI:Open(nil, false)
	end)
	t.bg = t:CreateTexture(nil, "BACKGROUND")
	t.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(t.bg, 0, 0, 0, 0.45)
	t.icon = t:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(t.icon, 18, 18)
	t.icon:SetPoint("TOPLEFT", 6, -6)
	t.title = S.Text(t, "GameFontNormal", "LEFT")
	t.title:SetPoint("LEFT", t.icon, "RIGHT", 6, 0)
	t.title:SetWidth(TRACKER_W - 36)
	CuratorOctoFull.SetWordWrap(t.title, false)
	t.lines = {}
	for i = 1, 5 do
		local fs = S.Text(t, "GameFontHighlightSmall", "LEFT")
		fs:SetPoint("TOPLEFT", 12, -26 - (i - 1) * 16)
		fs:SetWidth(TRACKER_W - 18)
		CuratorOctoFull.SetWordWrap(fs, false)
		t.lines[i] = fs
	end
	-- (1.13.0) whether the place counts, and the leader's lands for the tranche (the creatures of his lands that give
	-- experience count: the grey ones, never)
	t.here = S.Text(t, "GameFontHighlightSmall", "LEFT")
	t.here:SetPoint("TOPLEFT", 12, -26 - 5 * 16 - 2)
	t.here:SetWidth(TRACKER_W - 18)
	CuratorOctoFull.SetWordWrap(t.here, false)
	t.lands = S.Text(t, "GameFontHighlightSmall", "LEFT")
	t.lands:SetPoint("TOPLEFT", t.here, "BOTTOMLEFT", 0, -3)
	t.lands:SetWidth(TRACKER_W - 18)
	CuratorOctoFull.SetWordWrap(t.lands, true)
	if t.lands.SetMaxLines then
		CuratorOctoFull.SetMaxLines(t.lands, 3)
	end
	t.lands:SetTextColor(0.78, 0.78, 0.8)
	self.tracker = t
	self:PlaceTracker()
	return t
end

function UI:PlaceTracker()
	local t = self.tracker
	t:ClearAllPoints()
	local at = ns.db and ns.db.goldAt
	if type(at) == "table" and at[1] then
		t:SetPoint(at[1], UIParent, at[2] or at[1], tonumber(at[3]) or 0, tonumber(at[4]) or 0)
	else
		t:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
	end
end

function UI:UpdateTracker()
	local q = ns.db and GQ:Quest()
	-- (paused: only a quest done this week, to turn in)
	if not (q and GQ:Mine(q)) or (GQ:Paused() and GQ:State(GQ:Leader(q.leader)) ~= "ready") then
		if self.tracker then
			self.tracker:Hide()
		end
		return
	end
	local t = self:BuildTracker()
	local l = GQ:Leader(q.leader)
	local done = GQ:IsComplete(q)
	UI.PaintMark(t.icon, done and "ready" or "active")
	t.title:SetText(string.format(L["Golden quest: %s"], GQ:LeaderName(l)))
	local k, g = tonumber(q.kills) or 0, tonumber(q.gathers) or 0
	local purge = GQ:PurgeDone(q)
	local rows = {
		{ string.format(L["Creatures: %d / %d"], math.min(k, GQ.KILLS), GQ.KILLS), purge },
		{ string.format(L["Gatherings: %d / %d (with %d / %d creatures)"], math.min(g, GQ.GATHERS), GQ.GATHERS, math.min(k, GQ.KILLS_WITH_GATHERS), GQ.KILLS_WITH_GATHERS), purge },
		{ string.format(L["Rares: %d / %d"], math.min(tonumber(q.rares) or 0, GQ.RARES), GQ.RARES), (tonumber(q.rares) or 0) >= GQ.RARES },
		{ string.format(L["Dungeons: %d / %d"], math.min(tonumber(q.dungeons) or 0, GQ.DUNGEONS), GQ.DUNGEONS), (tonumber(q.dungeons) or 0) >= GQ.DUNGEONS },
		{ done and string.format(L["Turn it in to %s."], GQ:LeaderName(l)) or string.format(L["Time left: %s"], ns.Duration(GQ:Left())), done },
	}
	for i, fs in ipairs(t.lines) do
		local r = rows[i]
		fs:SetText(r[1])
		if r[2] then
			fs:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
		else
			fs:SetTextColor(1, 1, 1)
		end
	end
	-- (1.13.0) the place: one of his lands or not; his lands, again
	local here = ns.Rewards and ns.Rewards.ZoneSeries and ns.Rewards:ZoneSeries() or nil
	if here and not here.dungeon then
		if GQ:Counts(q, here) then
			t.here:SetText(L["Here: it counts (the creatures that give you experience)"])
			t.here:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
		else
			t.here:SetText(L["Here: it does not count (not one of my lands)"])
			t.here:SetTextColor(1, 0.62, 0.3)
		end
	else
		t.here:SetText("")
	end
	t.lands:SetText(string.format(L["My lands: %s"], Names(GQ:Zones(l, q.bracket))))
	t:SetHeight(26 + 5 * 16 + 2 + (t.here:GetText() ~= "" and 14 or 0) + 3 + math.max(14, t.lands:GetStringHeight() or 14) + 8)
	t:Show()
end

-------------------------------------------------------------------------------
-- The markers over the leaders: on their name plates, in their cities
-------------------------------------------------------------------------------
-- The leader whose city the player is in (nil: none).
function UI:CityLeader()
	if not (C_Map and C_Map.GetBestMapForUnit) then
		return nil
	end
	local map = Safe(C_Map.GetBestMapForUnit, "player")
	if not map then
		return nil
	end
	for _, l in ipairs(GQ:Leaders(GQ:Faction())) do
		if l.map == map then
			return l
		end
	end
	return nil
end

-- The name plates of the game, as the player set them. (1.13.0: Curator no longer shows the name plates of the
-- friendly NPCs in the city of a leader, nor hides the others: the names of the NPCs went with them. The settings
-- an older Curator changed are put back, out of a fight only: the game forbids it in a fight. The marker of a
-- leader goes on his name plate only when the player shows them himself.)
function UI:UpdatePlates()
	local db = ns.db
	if db and db.goldCVars then
		self:RestorePlates()
	end
	self:RefreshPlates()
end

function UI:RestorePlates()
	local db = ns.db
	local saved = db and db.goldCVars
	if type(saved) ~= "table" then
		if db then
			db.goldCVars = nil
		end
		return
	end
	if not (GetCVar and SetCVar) or (InCombatLockdown and InCombatLockdown()) then
		return
	end
	pcall(SetCVar, "nameplateShowFriendlyNPCs", saved.npcs == "1" and "1" or "0")
	pcall(SetCVar, "nameplateShowFriends", saved.friends == "1" and "1" or "0")
	db.goldCVars = nil
	self:RefreshPlates()
end

-- (1.13.0: no plate of the game is hidden any more)
function UI:Hides()
	return false
end

UI.plates = {}

function UI:OnPlate(unit)
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
		return
	end
	local plate = Safe(C_NamePlate.GetNamePlateForUnit, unit)
	if not plate then
		return
	end
	local guid = Safe(UnitGUID, unit)
	local kind, id
	if type(guid) == "string" then
		local k, _, _, _, _, i = strsplit("-", guid)
		kind, id = k, i
	end
	local npc = kind == "Creature" and tonumber(id) or nil
	local l = npc and GQ:LeaderByNpc(npc)
	local mark = l and self:MarkOf(l)
	local m = self.plates[plate]
	if mark then
		if not m then
			m = CreateFrame("Frame", nil, plate)
			CuratorOctoFull.SetSize(m, 34, 34)
			m:SetPoint("BOTTOM", plate, "TOP", 0, -4)
			m.tex = m:CreateTexture(nil, "OVERLAY")
			m.tex:SetAllPoints()
			self.plates[plate] = m
		end
		UI.PaintMark(m.tex, mark)
		m:Show()
	elseif m then
		m:Hide()
	end
	-- (a plate an older Curator hid, shown again: its name with it)
	local uf = plate.UnitFrame
	if uf and uf.SetAlpha and plate.curatorHid then
		pcall(uf.SetAlpha, uf, 1)
		plate.curatorHid = nil
	end
end

function UI:OffPlate(unit)
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
		return
	end
	local plate = Safe(C_NamePlate.GetNamePlateForUnit, unit)
	if not plate then
		return
	end
	local m = self.plates[plate]
	if m then
		m:Hide()
	end
	if plate.curatorHid and plate.UnitFrame then
		pcall(plate.UnitFrame.SetAlpha, plate.UnitFrame, 1)
		plate.curatorHid = nil
	end
end

function UI:RefreshPlates()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then
		return
	end
	local ok, list = pcall(C_NamePlate.GetNamePlates)
	if not ok or type(list) ~= "table" then
		return
	end
	for _, plate in ipairs(list) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit then
			self:OnPlate(unit)
		end
	end
end

-------------------------------------------------------------------------------
-- The markers on the map (the city of the leader and the maps that hold it) and on the minimap
-------------------------------------------------------------------------------
UI.mapPins = {}

function UI:MapPin(i)
	local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
	if not canvas then
		return nil
	end
	local p = self.mapPins[i]
	if not p then
		p = CreateFrame("Frame", nil, canvas)
		CuratorOctoFull.SetSize(p, 28, 28)
		p:SetFrameStrata("HIGH")
		p.tex = p:CreateTexture(nil, "OVERLAY")
		p.tex:SetAllPoints()
		p:EnableMouse(true)
		CuratorOctoFull.SetScript(p, "OnEnter", function(self)
			if self.l then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(string.format(L["Golden quest of %s"], GQ:LeaderName(self.l)), GOLD[1], GOLD[2], GOLD[3])
				GameTooltip:Show()
			end
		end)
		CuratorOctoFull.SetScript(p, "OnLeave", function()
			GameTooltip:Hide()
		end)
		self.mapPins[i] = p
	end
	return p
end

function UI:UpdateMap()
	if not (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:IsShown()) then
		return
	end
	local map = WorldMapFrame:GetMapID()
	local canvas = WorldMapFrame:GetCanvas()
	local w, h = canvas:GetWidth(), canvas:GetHeight()
	local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
	local n = 0
	for _, l in ipairs(GQ:Leaders(GQ:Faction())) do
		local mark = self:MarkOf(l)
		local x, y
		if mark and map == l.map then
			x, y = l.x, l.y
		elseif mark and C_Map and C_Map.GetMapRectOnMap then
			local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, l.map, map)
			if ok and minX and maxX and not Secret(minX) and maxX > minX then
				x, y = minX + l.x * (maxX - minX), minY + l.y * (maxY - minY)
			end
		end
		if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
			n = n + 1
			local p = self:MapPin(n)
			if p then
				p.l = l
				UI.PaintMark(p.tex, mark)
				p:SetScale(1 / math.max(0.2, scale))
				p:ClearAllPoints()
				p:SetPoint("CENTER", canvas, "TOPLEFT", x * w * scale, -y * h * scale)
				p:Show()
			end
		end
	end
	for i = n + 1, CuratorOctoFull.Length(self.mapPins) do
		self.mapPins[i]:Hide()
	end
end

-- The minimap: its radius in yards by its zoom, outside and inside (as the game draws it).
local MINIMAP_YARDS = {
	outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 6, 200, 133 + 1 / 3 },
	indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}

function UI:MinimapPin()
	if self.mini or not Minimap then
		return self.mini
	end
	local p = CreateFrame("Frame", nil, Minimap)
	CuratorOctoFull.SetSize(p, 20, 20)
	p:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 6)
	p.tex = p:CreateTexture(nil, "OVERLAY")
	p.tex:SetAllPoints()
	p:Hide()
	self.mini = p
	return p
end

function UI:UpdateMinimap()
	local l = self:CityLeader()
	local mark = l and self:MarkOf(l)
	local p = self:MinimapPin()
	if not p then
		return
	end
	if not (mark and C_Map and C_Map.GetPlayerMapPosition and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
		p:Hide()
		return
	end
	local pos = Safe(C_Map.GetPlayerMapPosition, l.map, "player")
	if not pos then
		p:Hide()
		return
	end
	local px, py = pos:GetXY()
	local _, me = Safe(C_Map.GetWorldPosFromMapPos, l.map, CreateVector2D(px, py))
	local _, him = Safe(C_Map.GetWorldPosFromMapPos, l.map, CreateVector2D(l.x, l.y))
	if not (me and him) then
		p:Hide()
		return
	end
	-- (the world: x to the north, y to the west)
	local east, north = -(him.y - me.y), him.x - me.x
	local inside = IsIndoors and IsIndoors() and "indoor" or "outdoor"
	local zoom = Minimap:GetZoom() or 0
	local radius = (MINIMAP_YARDS[inside][zoom] or 300) / 2
	local half = Minimap:GetWidth() / 2
	local k = half / radius
	local dx, dy = east * k, north * k
	if GetCVar and GetCVar("rotateMinimap") == "1" and GetPlayerFacing then
		local f = GetPlayerFacing() or 0
		local c, s = math.cos(f), math.sin(f)
		dx, dy = dx * c + dy * s, -dx * s + dy * c
	end
	local dist = math.sqrt(dx * dx + dy * dy)
	local edge = half - 8
	if dist > edge then
		dx, dy = dx / dist * edge, dy / dist * edge
		p:SetAlpha(0.7)
	else
		p:SetAlpha(1)
	end
	UI.PaintMark(p.tex, mark)
	p:ClearAllPoints()
	p:SetPoint("CENTER", Minimap, "CENTER", dx, dy)
	p:Show()
end

-------------------------------------------------------------------------------
-- The golden boosters waiting: on the page of the boosters, a button of gold in the bar under the page, on the left
-- (the code of a gift on the right); a click opens one. (1.13.0, after its first test: over the boosters of the other
-- albums before, at the top right of their grid, where the button of the displays is now.)
-------------------------------------------------------------------------------
function UI:GoldSlot(st)
	if not st or st.gold then
		return st and st.gold
	end
	local f = ns.Album.frame
	local page = f.boost or st:GetParent()
	local s = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(s, 200, 22)
	s:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 4)
	-- (a line of gold around it: its edge under its background, a pixel larger)
	s.edge = s:CreateTexture(nil, "BACKGROUND", nil, 0)
	s.edge:SetPoint("TOPLEFT", -1, 1)
	s.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(s.edge, GOLD[1], GOLD[2], GOLD[3], 0.6)
	s.bg = s:CreateTexture(nil, "BACKGROUND", nil, 1)
	s.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(s.bg, 0.12, 0.09, 0.02, 0.92)
	s.glow = s:CreateTexture(nil, "BORDER")
	s.glow:SetTexture(MEDIA .. "Glow")
	s.glow:SetBlendMode("ADD")
	s.glow:SetVertexColor(1, 0.8, 0.3)
	CuratorOctoFull.SetSize(s.glow, 34, 34)
	s.glow:SetPoint("CENTER", s, "LEFT", 15, 0)
	s.icon = s:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(s.icon, 20, 20)
	s.icon:SetPoint("CENTER", s, "LEFT", 15, 0)
	s.icon:SetTexCoord(PACK_CROP[1], PACK_CROP[2], PACK_CROP[3], PACK_CROP[4])
	s.icon:SetDesaturated(true)
	s.icon:SetVertexColor(1, 0.8, 0.34)
	s.count = S.Text(s, "GameFontNormal", "LEFT")
	s.count:SetPoint("LEFT", s, "LEFT", 30, 0)
	s.count:SetWidth(200 - 36)
	CuratorOctoFull.SetWordWrap(s.count, false)
	s:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
	CuratorOctoFull.SetScript(s, "OnClick", function()
		if GQ:PackCount() > 0 then
			ns.Play(ns.SND.click)
			GQ:OpenPack()
		end
	end)
	CuratorOctoFull.SetScript(s, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(string.format(L["Golden boosters: %d"], GQ:PackCount()), GOLD[1], GOLD[2], GOLD[3])
		-- (1.14.0: an album complete gives one too, Achievements.lua)
		GameTooltip:AddLine(L["The reward of an album complete or of a golden quest: 5 cards, every one epic or better. A click opens one."], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(s, "OnLeave", function()
		GameTooltip:Hide()
	end)
	st.gold = s
	return s
end

function UI:PaintGoldSlots()
	local f = ns.Album and ns.Album.frame
	if not f then
		return
	end
	local n = GQ:PackCount()
	local s = self:GoldSlot(f.boost and f.boost.stock)
	if s then
		CuratorOctoFull.SetShown(s, n > 0)
		-- (the pack of the album of the first one, in gold)
		local first = GQ:Packs()[1]
		local album = first and ns.SeriesByKey(first.s)
		s.icon:SetTexture(MEDIA .. ((album and album.pack) or "PackElwynn") .. "Bottom")
		s.count:SetText(string.format(L["Golden boosters: %d"], n))
		s.count:SetTextColor(1, 0.88, 0.55)
		s.glow:SetAlpha(n > 0 and 0.7 or 0)
	end
	self:PaintQuestsButton()
end

-- The page of the quests: under the boosters to choose, the golden quest of the week (a click: its window).
function UI:QuestsButton()
	local f = ns.Album and ns.Album.frame
	local page = f and f.quests
	if not (page and page.stock) then
		return nil
	end
	if page.golden then
		return page.golden
	end
	local b = CreateFrame("Button", nil, page)
	-- (under the note of the boosters to choose, as wide as their box)
	local note = page.stockNote
	b:SetPoint("TOPLEFT", note or page.stock, "BOTTOMLEFT", note and -4 or 0, -10)
	b:SetWidth(page.stock:GetWidth() > 0 and page.stock:GetWidth() or 260)
	b:SetHeight(56)
	-- (a line of gold around it: its edge under its background, a pixel larger)
	b.edge = b:CreateTexture(nil, "BACKGROUND", nil, 0)
	b.edge:SetPoint("TOPLEFT", -1, 1)
	b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	CuratorOctoFull.ColorTexture(b.edge, 1, 0.8, 0.3, 0.55)
	b.bg = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.bg, 0.12, 0.09, 0.02, 0.92)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(b.icon, 26, 26)
	b.icon:SetPoint("LEFT", 8, 0)
	b.title = S.Text(b, "GameFontNormal", "LEFT")
	b.title:SetPoint("TOPLEFT", b, "TOPLEFT", 42, -8)
	b.title:SetPoint("TOPRIGHT", b, "TOPRIGHT", -8, -8)
	b.title:SetText(L["Golden quest"])
	b.line = S.Text(b, "GameFontHighlightSmall", "LEFT")
	b.line:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -3)
	b.line:SetPoint("TOPRIGHT", b.title, "BOTTOMRIGHT", 0, -3)
	CuratorOctoFull.SetWordWrap(b.line, true)
	b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		UI:Open(nil, false)
	end)
	page.golden = b
	return b
end

function UI:PaintQuestsButton()
	local b = self:QuestsButton()
	if not b then
		return
	end
	local q = GQ:Quest()
	if GQ:Paused() and not (q and GQ:State(GQ:Leader(q.leader)) == "ready") then
		-- (1.13.0: paused, being reworked)
		UI.PaintMark(b.icon, "active")
		b.line:SetText(L["Being reworked: not available for now."])
	elseif q then
		local done = GQ:IsComplete(q)
		UI.PaintMark(b.icon, done and "ready" or "active")
		local l = GQ:Leader(q.leader)
		if done then
			b.line:SetText(string.format(L["Turn it in to %s."], GQ:LeaderName(l)))
		else
			b.line:SetText(string.format(L["%s, time left: %s"], GQ:LeaderName(l), ns.Duration(GQ:Left())))
		end
	elseif GQ:DoneThisWeek() then
		UI.PaintMark(b.icon, "active")
		b.line:SetText(string.format(L["Turned in this week. Next one: %s."], ns.Duration(GQ:Left())))
	else
		UI.PaintMark(b.icon, "offer")
		b.line:SetText(L["Ask the leaders of your side in their cities."])
	end
end

if ns.Album and ns.Album.PaintStock then
	local paint = ns.Album.PaintStock
	ns.Album.PaintStock = function(self, ...)
		paint(self, unpack(arg, 1, arg.n))
		UI:PaintGoldSlots()
	end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
function UI:Refresh()
	if self.frame and self.frame:IsShown() then
		self:Paint()
	end
	self:UpdateTracker()
	self:UpdatePrompt()
	self:UpdatePlates()
	self:UpdateMap()
	self:UpdateMinimap()
	self:PaintGoldSlots()
end

ns.On("GOLDEN_CHANGED", function()
	UI:Refresh()
end)

ns.On("GOLDEN_ACCEPTED", function(l)
	ns.Toast:Push({
		title = L["Golden quest accepted"],
		name = string.format(L["The Trial of %s"], GQ:LeaderName(l)),
		color = { 1, 0.82, 0 },
		line = string.format(L["Time left: %s"], ns.Duration(GQ:Left())),
		tex = { UI.ICON_OFFER },
		sound = ns.SND.questDone,
		onClick = function()
			UI:Open(l, false)
		end,
	})
end)

ns.On("GOLDEN_COMPLETE", function(l)
	ns.Toast:Push({
		title = L["Golden quest done!"],
		name = string.format(L["The Trial of %s"], GQ:LeaderName(l)),
		color = { 1, 0.82, 0 },
		line = string.format(L["Turn it in to %s."], GQ:LeaderName(l)),
		tex = { UI.ICON_TURN },
		sound = ns.SND.questDone,
		onClick = function()
			UI:Open(l, false)
		end,
	})
end)

ns.On("GOLDEN_ALERT", function(l, left)
	ns.Toast:Push({
		title = L["Your golden quest ends soon"],
		name = string.format(L["Time left: %s"], ns.Duration(left)),
		color = { 1, 0.4, 0.3 },
		line = string.format(L["Turn it in to %s."], GQ:LeaderName(l)),
		tex = { UI.ICON_TURN },
		onClick = function()
			UI:Open(l, false)
		end,
	})
end)

ns.On("GOLDEN_LOST", function(l)
	ns.Toast:Push({
		title = L["Golden quest lost"],
		name = string.format(L["The Trial of %s"], GQ:LeaderName(l)),
		color = { 0.7, 0.7, 0.7 },
		line = L["The week ended before you turned it in."],
		tex = { UI.ICON_TURN },
		dim = true,
	})
end)

-- Turned in: its golden booster opens right away (out of a fight).
ns.On("GOLDEN_DONE", function(_, _, ticket)
	ns.Delay(0.6, function()
		if InCombatLockdown and InCombatLockdown() then
			ns.Print(L["Your golden booster waits in the inventory of the album: Boosters."])
			return
		end
		GQ:OpenPack(ticket)
	end, UI)
end)

ns.On("GUILD_GOLDEN", function(sender, l)
	-- (1.14.3: the guild turned off in the options, nothing of it, its chat line neither: UI/Live.lua, V:Allows)
	if ns.Live and not ns.Live:Allows() then
		return
	end
	local who = ns.Guild and ns.Guild:Short(sender) or sender
	ns.Print(string.format(L["%s turned in a golden quest to %s."], who, GQ:LeaderName(l)))
end)

local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_TARGET_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
	"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_LEVEL_UP" }) do
	pcall(f.RegisterEvent, f, e)
end
CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, unit)
	if not ns.db then
		return
	end
	if event == "NAME_PLATE_UNIT_ADDED" then
		return UI:OnPlate(unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		return UI:OffPlate(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		return UI:UpdatePrompt()
	end
	UI:Refresh()
end)

-- The game closes: the settings of the name plates put back (the game keeps them), and out of the save
-- before its seal (Core.lua, LOGOUT: never in a PLAYER_LOGOUT of our own, which may come after the seal).
ns.On("LOGOUT", function()
	if ns.db then
		UI:RestorePlates()
	end
end)

-- every half second: the prompt (the distance to the leader), the minimap; every 30 seconds: the time left
local acc, slow = 0, 0
CuratorOctoFull.SetScript(f, "OnUpdate", function(_, dt)
	acc, slow = acc + dt, slow + dt
	if acc < 0.5 then
		return
	end
	acc = 0
	if not ns.db then
		return
	end
	if UI.prompt and UI.prompt:IsShown() or Safe(UnitExists, "target") then
		UI:UpdatePrompt()
	end
	UI:UpdateMinimap()
	if slow >= 30 then
		slow = 0
		UI:UpdateTracker()
		if UI.frame and UI.frame:IsShown() then
			UI:Paint()
		end
	end
end)

if WorldMapFrame then
	if WorldMapFrame.HookScript then
		WorldMapFrame:HookScript("OnShow", function()
			UI:UpdateMap()
		end)
	end
	if hooksecurefunc and WorldMapFrame.OnMapChanged then
		hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
			UI:UpdateMap()
		end)
	end
	if hooksecurefunc and WorldMapFrame.OnCanvasScaleChanged then
		hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", function()
			UI:UpdateMap()
		end)
	end
end
