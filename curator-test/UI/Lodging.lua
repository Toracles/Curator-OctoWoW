local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local C = ns.Collection

-------------------------------------------------------------------------------
-- (1.14.0, after its test, his word: the innkeeper redone) The inns on the screen while one plays (Lodging.lua,
-- Tavern.lua): at the end of the booster bar, the rest (its creatures) and the dish of the day under way (its time
-- left); the leads of the tavern, followed on the screen (Shift-drag moves them, /curator leads hides or shows them);
-- the alerts: rested, a dish ended, a lead followed to its card, the round of an innkeeper.
-------------------------------------------------------------------------------
local UI = {}
ns.LodgingUI = UI

local GOLD = { 1, 0.82, 0.36 }
local GREEN = { 0.55, 1, 0.5 }
local REST_ICON = "Interface\\Icons\\Spell_Nature_Sleep"
local LEAD_ICON = "Interface\\Icons\\Ability_Tracking"
local TRACK_W = 270

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- A text in the colour of a rarity.
local function Colored(text, r)
	local x = ns.RARITY[r]
	local c = x and x.text or { 1, 1, 1 }
	return string.format(("|cff%02x%02x%02x%s|r"), math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), text)
end

-- "2 h", "35 min", "2 d": a time left, short.
local function Short(sec)
	sec = math.max(0, tonumber(sec) or 0)
	if sec >= 86400 then
		return string.format(L["%d d"], math.floor(sec / 86400 + 0.5))
	elseif sec >= 3600 then
		return string.format(L["%d h"], math.floor(sec / 3600 + 0.5))
	end
	return string.format(L["%d min"], math.max(1, math.ceil(sec / 60)))
end
UI.Short = Short

-------------------------------------------------------------------------------
-- The end of the booster bar: the rest, the dish of the day
-------------------------------------------------------------------------------
-- An icon of the end of the bar: round, its ring, its line under it.
local function Slot(parent, level)
	local it = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(it, 28, 28)
	it:SetFrameLevel(level)
	it.light = it:CreateTexture(nil, "BACKGROUND")
	it.light:SetTexture(MEDIA .. "Glow")
	it.light:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(it.light, 56, 56)
	it.light:SetPoint("CENTER")
	it.light:SetAlpha(0)
	it.icon = Hud.RoundIcon(it, 21, "ARTWORK")
	it.icon:SetPoint("CENTER")
	it.ring = it:CreateTexture(nil, "OVERLAY")
	it.ring:SetTexture(MEDIA .. "IconRing")
	it.ring:SetPoint("CENTER")
	CuratorOctoFull.SetSize(it.ring, 32, 32)
	it.text = Hud.Text(it, 10, "OUTLINE", "OVERLAY", 3)
	it.text:SetPoint("TOP", it, "BOTTOM", 0, 2)
	CuratorOctoFull.SetScript(it, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(it, "OnClick", function()
		ns.Play(ns.SND.click)
		ns.Album:ShowInns()
	end)
	it:Hide()
	return it
end

function UI:Build()
	local BB = ns.BoosterBar
	local b = BB and BB.frame
	if not b then
		return nil
	end
	if self.rest then
		return b
	end
	local level = b.bar.over:GetFrameLevel() + 2
	self.rest = Slot(b, level)
	self.rest.icon:SetTexture(REST_ICON)
	self.rest.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetScript(self.rest, "OnEnter", function(it)
		UI:RestTooltip(it)
	end)
	self.dish = Slot(b, level)
	CuratorOctoFull.SetScript(self.dish, "OnEnter", function(it)
		UI:DishTooltip(it)
	end)
	-- (it breathes while rested in a place of rest, pulses a moment when its dish is served)
	local t = 0
	CuratorOctoFull.SetScript(self.rest, "OnUpdate", function(it, elapsed)
		t = t + elapsed
		it.light:SetAlpha(it.resting and (0.25 + 0.2 * math.sin(t * 2)) or 0)
		it.tick = (it.tick or 0) + elapsed
		if it.tick >= 10 then
			it.tick = 0
			UI:Paint()
		end
	end)
	CuratorOctoFull.SetScript(self.dish, "OnUpdate", function(it, elapsed)
		it.tick = (it.tick or 0) + elapsed
		if it.tick >= 10 then
			it.tick = 0
			UI:Paint()
		end
	end)
	return b
end

-- Where the dish goes on the bar (the flight of a dish served at the counter: UI/Inns.lua).
function UI:DishSlot()
	self:Build()
	return self.dish
end

-- The rest and the dish, after the talents to use of the tree (UI/BoosterBar.lua), on the right end of the bar.
function UI:Paint()
	local b = self:Build()
	local LG = ns.Lodging
	if not (b and LG and ns.db) then
		return
	end
	local x = 20
	for _, it in ipairs(b.acts or {}) do
		if it:IsShown() then
			x = x + 40
		end
	end
	local n = LG:Rest()
	local resting = LG.Resting()
	local rest = self.rest
	rest.resting = resting
	if n >= 1 or resting then
		rest:ClearAllPoints()
		rest:SetPoint("CENTER", b, "RIGHT", x, 1)
		rest.icon:SetDesaturated(n < 1 or LG.Waiting())
		rest.text:SetText(n >= 1 and ns.Num(n) or "Zz")
		rest.text:SetTextColor(0.6, 0.8, 1)
		rest:Show()
		x = x + 40
	else
		rest:Hide()
	end
	local def, left, _, waiting = LG:Dish()
	local dish = self.dish
	if def then
		dish:ClearAllPoints()
		dish:SetPoint("CENTER", b, "RIGHT", x, 1)
		if dish.key ~= def.key then
			dish.key = def.key
			Hud.SetIcon(dish.icon, { LG:Icon(def) })
		end
		dish.icon:SetDesaturated(waiting)
		dish.text:SetText(waiting and L["Waiting"] or Short(left))
		if waiting then
			dish.text:SetTextColor(1, 0.82, 0.36)
		else
			dish.text:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
		end
		dish:Show()
	else
		dish.key = nil
		dish:Hide()
	end
end

function UI:RestTooltip(it)
	local LG = ns.Lodging
	local n, max = LG:Rest()
	GameTooltip:SetOwner(it, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Rest of the collector"], 0.6, 0.8, 1)
	if n >= 1 then
		GameTooltip:AddLine(string.format(L["Rested: your next %d creatures that have a card are twice as likely to give it."], n), 1, 1, 1, true)
	else
		GameTooltip:AddLine(L["Not rested: no creature of rest left."], 0.8, 0.8, 0.8, true)
	end
	GameTooltip:AddDoubleLine(L["Rest"], string.format(L["%d / %d"], n, max), 0.8, 0.8, 0.8, 1, 1, 1)
	if LG.Waiting() then
		GameTooltip:AddLine(L["It waits: a reroll does not use it."], 1, 0.82, 0.36, true)
	end
	if LG.Resting() then
		GameTooltip:AddLine(L["You are resting here: it grows, online or logged out."], GREEN[1], GREEN[2], GREEN[3], true)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Log out in an inn or a capital: 100 creatures of rest every 8 hours, 300 at most. Never on a boss, a mythic card or an event card."], 0.65, 0.65, 0.65, true)
	GameTooltip:AddLine(L["Click: the inns."], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

function UI:DishTooltip(it)
	local LG = ns.Lodging
	local def, left, from, waiting = LG:Dish()
	if not def then
		return
	end
	GameTooltip:SetOwner(it, "ANCHOR_TOP")
	GameTooltip:AddLine(LG:Name(def), 1, 0.86, 0.55)
	GameTooltip:AddLine(LG:Text(def), 1, 1, 1, true)
	if waiting then
		GameTooltip:AddLine(string.format(L["It waits: you are playing a reroll (%s left)."], LG.Duration(left)), 1, 0.82, 0.36, true)
	else
		GameTooltip:AddLine(string.format(L["%s left, while you play."], LG.Duration(left)), GREEN[1], GREEN[2], GREEN[3], true)
	end
	if from and ns.Inns then
		GameTooltip:AddLine(string.format(L["Served by %s."], ns.Inns:Name(from)), 0.7, 0.7, 0.7, true)
	end
	GameTooltip:AddLine(L["Click: the inns."], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The leads of the tavern, followed on the screen
-------------------------------------------------------------------------------
function UI:Tracker()
	if self.tracker then
		return self.tracker
	end
	local t = CreateFrame("Button", "CuratorLeads", UIParent)
	CuratorOctoFull.SetSize(t, TRACK_W, 60)
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
			ns.db.leadsAt = { point, rel, math.floor(x + 0.5), math.floor(y + 0.5) }
		end
	end)
	CuratorOctoFull.SetScript(t, "OnClick", function()
		ns.Play(ns.SND.click)
		ns.Album:ShowInns()
	end)
	t.bg = t:CreateTexture(nil, "BACKGROUND")
	t.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(t.bg, 0, 0, 0, 0.45)
	t.icon = t:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(t.icon, 18, 18)
	t.icon:SetPoint("TOPLEFT", 6, -6)
	t.icon:SetTexture(LEAD_ICON)
	t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	t.title = S.Text(t, "GameFontNormal", "LEFT")
	t.title:SetPoint("LEFT", t.icon, "RIGHT", 6, 0)
	t.title:SetWidth(TRACK_W - 54)
	CuratorOctoFull.SetWordWrap(t.title, false)
	t.close = S.CloseButton(t)
	CuratorOctoFull.SetSize(t.close, 20, 20)
	t.close:SetPoint("TOPRIGHT", 0, 0)
	CuratorOctoFull.SetScript(t.close, "OnClick", function()
		CuratorOctoFull.SetShown(UI, false)
	end)
	t.lines = {}
	for i = 1, ns.Tavern.LEAD_MAX do
		local i = i; local row = CreateFrame("Button", nil, t)
		CuratorOctoFull.SetSize(row, TRACK_W - 14, 16)
		row:SetPoint("TOPLEFT", 10, -26 - (i - 1) * 17)
		row.name = S.Text(row, "GameFontHighlightSmall", "LEFT")
		row.name:SetPoint("LEFT")
		row.name:SetPoint("RIGHT", -60, 0)
		CuratorOctoFull.SetWordWrap(row.name, false)
		row.left = S.Text(row, "GameFontHighlightSmall", "RIGHT")
		row.left:SetPoint("RIGHT")
		row.left:SetWidth(58)
		CuratorOctoFull.SetScript(row, "OnEnter", function(self)
			UI:LeadTooltip(self)
		end)
		CuratorOctoFull.SetScript(row, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(row, "OnClick", function(self)
			if self.card and ns.Album then
				ns.Play(ns.SND.click)
				ns.Album:ShowCard(self.card)
			end
		end)
		t.lines[i] = row
	end
	t.tick = 0
	CuratorOctoFull.SetScript(t, "OnUpdate", function(self, elapsed)
		self.tick = self.tick + elapsed
		if self.tick >= 20 then
			self.tick = 0
			UI:UpdateTracker()
		end
	end)
	t:Hide()
	self.tracker = t
	self:PlaceTracker()
	return t
end

function UI:PlaceTracker()
	local t = self.tracker
	if not t then
		return
	end
	t:ClearAllPoints()
	local at = ns.db and ns.db.leadsAt
	if type(at) == "table" and at[1] then
		t:SetPoint(at[1], UIParent, at[2] or at[1], tonumber(at[3]) or 0, tonumber(at[4]) or 0)
	else
		t:SetPoint("RIGHT", UIParent, "RIGHT", -40, -90)
	end
end

-- The leads where the player is first (they can be followed here), then the newest.
function UI:Leads()
	local T = ns.Tavern
	if not T then
		return {}
	end
	local list = T:LeadList()
	local here = ns.Rewards and ns.Rewards.ZoneSeries and ns.Rewards:ZoneSeries() or nil
	for i, l in ipairs(list) do
		l.here = here ~= nil and l.card.series == here
		l.i = i
	end
	table.sort(list, function(a, b)
		if a.here ~= b.here then
			return a.here
		end
		return a.i < b.i
	end)
	return list
end

function UI:UpdateTracker()
	if not ns.db then
		return
	end
	local list = self:Leads()
	if CuratorOctoFull.Length(list) == 0 or ns.db.leadsHide then
		if self.tracker then
			self.tracker:Hide()
		end
		return
	end
	local t = self:Tracker()
	t.title:SetText(string.format(L["Leads of the tavern (%d)"], CuratorOctoFull.Length(list)))
	local now = Now()
	for i, row in ipairs(t.lines) do
		local l = list[i]
		row.card, row.lead = l and l.card, l
		if l then
			local name = Colored(C:Name(l.card), l.card.rarity)
			row.name:SetText(name .. "  |cff9a9a9a" .. C:SeriesName(l.card.series) .. "|r")
			row.left:SetText(Short((tonumber(l.u) or 0) - now))
			if l.here then
				row.left:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
			else
				row.left:SetTextColor(0.75, 0.75, 0.75)
			end
			row:Show()
		else
			row:Hide()
		end
	end
	t:SetHeight(26 + math.min(CuratorOctoFull.Length(list), CuratorOctoFull.Length(t.lines)) * 17 + 6)
	t:Show()
end

function UI:LeadTooltip(row)
	local l = row.lead
	if not l then
		return
	end
	local T = ns.Tavern
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	GameTooltip:AddLine(C:Name(l.card), unpack((ns.RARITY[l.card.rarity] or ns.RARITY[1]).text))
	GameTooltip:AddLine(C:SeriesName(l.card.series), 1, 1, 1)
	local k = (l.card.rarity or 0) >= 6 and T.RUMOR_FIND_MYTHIC or T:RumorFind()
	GameTooltip:AddLine(string.format(L["A lead: its card %d times as easy to find on its creature."], k), GREEN[1], GREEN[2], GREEN[3], true)
	GameTooltip:AddLine(string.format(L["%s left."], ns.Duration(math.max(0, (tonumber(l.u) or 0) - Now()))), 0.8, 0.8, 0.8)
	if l.n and ns.Inns then
		GameTooltip:AddLine(string.format((l.w == "bought" and L["Bought from %s."] or L["Told by %s."]), ns.Inns:Name(l.n)), 0.7, 0.7, 0.7, true)
	end
	GameTooltip:AddLine(string.format(L["Found on its creature: the innkeeper owes you a round (%s XP, %s rubies), at the next one you talk to."], ns.Num(T.ROUND.xp), ns.Num(T.ROUND.rubies)), 0.65, 0.65, 0.65, true)
	if ns.Collection:Owned(l.card) then
		GameTooltip:AddLine(L["You have this card already: a copy more, all the same."], 0.6, 0.6, 0.6, true)
	end
	GameTooltip:AddLine(L["Click: its card. Shift-drag: move the leads. /curator leads: hide them."], GOLD[1], GOLD[2], GOLD[3], true)
	GameTooltip:Show()
end

-- The leads on the screen, or not (/curator leads, the cross of the frame, the options).
function UI:SetShown(on)
	if not ns.db then
		return
	end
	ns.db.leadsHide = (not on) or nil
	self:UpdateTracker()
	if on then
		ns.Print(L["The leads of the tavern are shown on the screen while you have some."])
	else
		ns.Print(L["The leads of the tavern are hidden. /curator leads shows them again."])
	end
end

function UI:Toggle()
	CuratorOctoFull.SetShown(self, ns.db ~= nil and ns.db.leadsHide == true)
end

-------------------------------------------------------------------------------
-- The alerts
-------------------------------------------------------------------------------
ns.On("REST_GAINED", function(got, n)
	UI:Paint()
	if (tonumber(got) or 0) < 5 or not ns.Toast then
		return
	end
	ns.Toast:Push({
		title = L["Well rested!"],
		name = string.format(L["%d creatures of rest"], n),
		color = { 0.6, 0.8, 1 },
		line = L["Your next creatures that have a card: twice as likely to give it."],
		tex = { REST_ICON },
		sound = ns.SND.claim,
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

ns.On("DISH_ENDED", function(def)
	UI:Paint()
	if not (def and ns.Toast) then
		return
	end
	ns.Toast:Push({
		title = L["Dish of the day eaten"],
		name = ns.Lodging:Name(def),
		color = { 1, 0.86, 0.55 },
		line = L["Another one comes with tomorrow's stamp, at any innkeeper."],
		tex = { ns.Lodging:Icon(def) },
		sound = ns.SND.close,
	})
end)

ns.On("DISH_TAKEN", function(out)
	UI:Paint()
	-- (at the counter it is served there; a stamp taken another way: told here)
	local counter = ns.InnsUI and ns.InnsUI.panel
	if not (out and out.def and ns.Toast) or (counter and counter:IsShown()) then
		return
	end
	ns.Toast:Push({
		title = string.format(L["Dish of the day: %s"], ns.Lodging:Name(out.def)),
		name = ns.Lodging.Duration(out.time),
		color = { 1, 0.86, 0.55 },
		line = ns.Lodging:Text(out.def),
		tex = { ns.Lodging:Icon(out.def) },
		sound = ns.SND.claim,
	})
end)

ns.On("TAVERN_LEAD_DONE", function(card)
	UI:UpdateTracker()
	if not (card and ns.Toast) then
		return
	end
	ns.Toast:Push({
		title = L["A lead followed to its card!"],
		name = C:Name(card),
		color = { 0.55, 1, 0.5 },
		line = L["Go and see an innkeeper: the round is on him."],
		tex = { LEAD_ICON },
		sound = ns.SND.questDone,
		onClick = function()
			ns.Album:ShowInns()
		end,
	})
end)

ns.On("TAVERN_ROUND", function(res)
	if not res then
		return
	end
	local G = ns.Gossip
	if G and G.open then
		local first = res.cards and res.cards[1]
		local say = (res.n == 1 and first) and string.format(L["So my rumor about %s was true! The round is on me."], C:Name(first))
			or L["My rumors were true! The round is on me."]
		G:Say(say)
	end
end)

for _, e in ipairs({ "TAVERN_LEAD", "TAVERN_RUMOR_BOUGHT", "CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		if UI.updating then
			return
		end
		UI.updating = true
		ns.Delay(0.1, function()
			UI.updating = false
			UI:UpdateTracker()
		end, UI)
	end)
end

for _, e in ipairs({ "REST_CHANGED", "DISH_TAKEN", "XP_GAINED" }) do
	local _, e = _, e; ns.On(e, function()
		UI:Paint()
	end)
end

ns.On("LOGIN", function()
	ns.Delay(1, function()
		UI:Paint()
		UI:UpdateTracker()
	end, UI)
end)

ns.On("PLACE_CHANGED", function()
	UI:UpdateTracker()
end)

-- (the resting of the game changes: an inn, a capital entered or left)
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_UPDATE_RESTING")
CuratorOctoFull.SetScript(ev, "OnEvent", function()
	UI:Paint()
end)
