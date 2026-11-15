local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin
local A = ns.Album

-------------------------------------------------------------------------------
-- (1.11.0) The options of Curator, in the options of the game (Options, AddOns, Curator; /curator options; the
-- gear of the album): the size of the album (Ctrl and the mouse wheel over it do the same), and the switches
-- that were only commands: the booster bar, the minimap button, the boosters in a small window, the entrances
-- of the legendary and mythic cards, the markers of the golden quests, the live openings of the guild, the
-- pulls shared with the guild, the offers from strangers, the presence shared with the author. A client
-- without the options of the addons: the same panel in a window of its own.
-------------------------------------------------------------------------------
local O = {}
ns.Options = O

O.SCALE_MIN, O.SCALE_MAX, O.SCALE_STEP = 0.6, 1.3, 0.05

-- (1.12.0) The languages Curator can be shown in, each in its own words.
local ENDONYM = { enUS = "English", frFR = "Fran\195\167ais", deDE = "Deutsch", esES = "Espa\195\177ol", ptBR = "Portugu\195\170s",
	ruRU = "\208\160\209\131\209\129\209\129\208\186\208\184\208\185", koKR = "\237\149\156\234\181\173\236\150\180",
	zhCN = "\231\174\128\228\189\147\228\184\173\230\150\135", zhTW = "\231\185\129\233\171\148\228\184\173\230\150\135" }
O.ENDONYM = ENDONYM

-- The game's language, as Curator names it.
local function ClientLang()
	local l = GetLocale and GetLocale() or "enUS"
	return (l == "enGB" and "enUS") or (l == "esMX" and "esES") or l
end

-- The choices: the game's language (nil), then the others.
function O:Languages()
	local out = { false }
	local client = ClientLang()
	for _, l in ipairs(ns.LangChoices()) do
		if l ~= client then
			out[CuratorOctoFull.Length(out) + 1] = l
		end
	end
	return out
end

-- The language chosen (nil: the game's), and its name.
function O:Language()
	local l = ns.db and ns.db.lang or nil
	if l then
		return l, ENDONYM[l] or l
	end
	local client = ClientLang()
	return nil, string.format(L["The language of the game (%s)"], ENDONYM[client] or client)
end

-- The next language (step: 1 or -1); it takes after a reload.
function O:StepLanguage(step)
	if not ns.db then
		return
	end
	local list = self:Languages()
	local cur = ns.db.lang or false
	local i = 1
	for k, l in ipairs(list) do
		if l == cur then
			i = k
		end
	end
	i = (CuratorOctoFull.Mod((i - 1 + step) , CuratorOctoFull.Length(list))) + 1
	ns.db.lang = list[i] or nil
	self:Paint()
end

-- The size of the album (1: as it was made).
function O:AlbumScale()
	local k = tonumber(ns.db and ns.db.albumScale) or 1
	return math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, k))
end

function O:SetAlbumScale(k)
	if not ns.db then
		return
	end
	k = math.floor((tonumber(k) or 1) * 100 + 0.5) / 100
	k = math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, k))
	ns.db.albumScale = (k ~= 1) and k or nil
	A:ApplyScale()
	self:Paint()
end

-- One step bigger (delta > 0) or smaller.
function O:StepScale(delta)
	self:SetAlbumScale(self:AlbumScale() + (delta > 0 and self.SCALE_STEP or -self.SCALE_STEP))
end

-- The album at its size (its middle where it was).
function A:ApplyScale()
	local f = self.frame
	if not f then
		return
	end
	local k = O:AlbumScale()
	if math.abs((f:GetScale() or 1) - k) < 0.001 then
		return
	end
	local x, y = f:GetCenter()
	local old = f:GetScale() or 1
	f:SetScale(k)
	if x and y then
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * old / k, y * old / k)
	end
end

do
	local build = A.Build
	function A:Build(...)
		local r = build(self, unpack(arg, 1, arg.n))
		local f = self.frame
		if f and not f.gear then
			-- the gear of the options, left of the purse (UI/Rubies.lua) in the title bar
			local g = CreateFrame("Button", nil, f)
			CuratorOctoFull.SetSize(g, 18, 18)
			-- (over the title bar: the pieces of the template of the window stand at 500 and more in the game)
			g:SetFrameLevel(math.max(f:GetFrameLevel() + 520, f.CloseButton and (f.CloseButton:GetFrameLevel() + 2) or 0))
			if f.wallet then
				g:SetPoint("RIGHT", f.wallet, "LEFT", -10, 0)
			elseif f.CloseButton then
				g:SetPoint("RIGHT", f.CloseButton, "LEFT", -6, 0)
			else
				g:SetPoint("TOPRIGHT", -34, -3)
			end
			g.icon = g:CreateTexture(nil, "ARTWORK")
			g.icon:SetAllPoints()
			g.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
			g.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			g.hl = g:CreateTexture(nil, "HIGHLIGHT")
			g.hl:SetAllPoints()
			CuratorOctoFull.ColorTexture(g.hl, 1, 1, 1, 0.2)
			CuratorOctoFull.SetScript(g, "OnClick", function()
				ns.Play(ns.SND.click)
				O:Open()
			end)
			CuratorOctoFull.SetScript(g, "OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				GameTooltip:AddLine(L["Options"], 1, 1, 1)
				GameTooltip:AddLine(L["The size of the album, what is shown, what is shared."], 0.85, 0.85, 0.85, true)
				GameTooltip:AddLine(L["Ctrl + mouse wheel over the album: its size."], S.GOLD[1], S.GOLD[2], S.GOLD[3], true)
				GameTooltip:Show()
			end)
			CuratorOctoFull.SetScript(g, "OnLeave", function()
				GameTooltip:Hide()
			end)
			f.gear = g
		end
		self:ApplyScale()
		return r
	end
	local paintTabs = A.PaintTabs
	function A:PaintTabs(...)
		local r = paintTabs(self, unpack(arg, 1, arg.n))
		if self.frame and self.frame.gear then
			CuratorOctoFull.SetShown(self.frame.gear, not self.member)
		end
		return r
	end
end

-------------------------------------------------------------------------------
-- The switches: each reads and sets what its command did
-------------------------------------------------------------------------------
local SWITCHES = {
	{ section = "On the screen" },
	-- (1.14.0, a player's word: its size, its picture and its lights on the same row, O:BarRow)
	{ key = "bar", label = "The booster bar", row = "bar",
		get = function() return not ns.db.barHide end,
		set = function(on)
			ns.db.barHide = (not on) or nil
			local BB = ns.BoosterBar
			if BB then
				BB:Refresh()
			end
		end },
	{ key = "minimap", label = "The button of the minimap",
		get = function() return not (ns.db.minimap and ns.db.minimap.hide) end,
		set = function(on)
			ns.db.minimap = ns.db.minimap or {}
			ns.db.minimap.hide = (not on) or nil
			if ns.MinimapButton then
				ns.MinimapButton:Update()
			end
		end },
	{ key = "compact", label = "The boosters in a small window you can move",
		get = function() return ns.Booster and ns.Booster:Small() or false end,
		set = function(on)
			if ns.Booster and (ns.Booster:Small() and true or false) ~= on then
				ns.Booster:ToggleSmall(true)
			end
		end },
	{ key = "cinematic", label = "The entrances of the legendary and mythic cards",
		get = function() return ns.db.cinematic ~= false end,
		set = function(on)
			ns.db.cinematic = on and true or false
		end },
	-- (1.14.0, his word) the creatures of the cards as a still picture, cut out on the backdrop (UI/Card.lua, Still)
	{ key = "still", label = "The creatures of the cards as a still picture",
		get = function() return ns.db.still == true end,
		set = function(on)
			ns.db.still = on or nil
			if ns.ApplyStillCards then
				ns.ApplyStillCards()
			end
		end },
	-- (1.14.0) the counter beside the innkeepers, the leads of the tavern on the screen (UI/Inns.lua, UI/Lodging.lua)
	{ key = "innCounter", label = "The counter beside the innkeepers (his dish of the day, your card, his rumor, his bet)",
		get = function() return ns.db.innCounter ~= false end,
		set = function(on)
			ns.db.innCounter = on and true or false
		end },
	{ key = "leads", label = "The leads of the tavern on the screen",
		get = function() return not ns.db.leadsHide end,
		set = function(on)
			ns.db.leadsHide = (not on) or nil
			if ns.LodgingUI then
				ns.LodgingUI:UpdateTracker()
			end
		end },
	{ key = "markers", label = "The markers of the golden quests (map, minimap, leaders)",
		get = function() return ns.db.goldMarks ~= false end,
		set = function(on)
			ns.db.goldMarks = on and true or false
			ns.Fire("GOLDEN_CHANGED")
		end },
	-- (1.14.2: the cases too, UI/Live.lua; 1.14.3, the players' word: all that comes from the guild on the screen, its
	-- epic cards and better only, and the alerts moved, on the same row: O:LiveRow)
	{ key = "live", label = "Your guild's alerts", row = "live",
		get = function() return ns.db.live ~= false end,
		set = function(on)
			ns.db.live = on and true or false
		end },
	-- (1.11.0) the rubies said in the chat, the sounds
	{ key = "rubychat", label = "The rubies you earn, said in the chat while the album is closed",
		get = function() return ns.db.rubyChat ~= false end,
		set = function(on)
			ns.db.rubyChat = on and true or false
		end },
	{ key = "sound", label = "The sounds of Curator",
		get = function() return not ns.db.mute end,
		set = function(on)
			ns.db.mute = (not on) or nil
		end },
	-- (1.12.1) the reminders to save the collection (UI/Save.lua)
	{ key = "saveRemind", label = "A reminder to save, after a long while of play or a great card",
		get = function() return ns.db.saveRemind ~= false end,
		set = function(on)
			if on then
				ns.db.saveRemind = nil
			else
				ns.db.saveRemind = false
			end
			if ns.Save then
				ns.Save:Paint()
			end
		end },
	{ section = "Sharing" },
	{ key = "announce", label = "Share your best pulls with your guild",
		get = function() return ns.db.announce ~= false end,
		set = function(on)
			ns.db.announce = on and true or false
		end },
	{ key = "strangers", label = "Offers of trades from players you do not know",
		get = function() return ns.db.strangers ~= false end,
		set = function(on)
			ns.db.strangers = on and true or false
		end },
	-- (on unless turned off; the copy of the author shows it as the players have it, it has no one to tell)
	{ key = "presence", label = "Your presence, shared with the author of Curator",
		get = function() return ns.db.presence ~= false end,
		set = function(on)
			if ns.Admin or not ns.Presence then
				ns.db.presence = on and true or false
			elseif (ns.Presence:Shares() and true or false) ~= on then
				ns.Presence:Set(on)
			end
		end },
	-- (1.12.1) the chat channel of the collectors of the faction (Channel.lua)
	{ key = "chat", label = "The chat channel of the collectors of your faction (Curator [Horde] or [Alliance])",
		get = function() return ns.db.chat ~= false end,
		set = function(on)
			if ns.Channel then
				ns.Channel:Set(on)
			elseif on then
				ns.db.chat = nil
			else
				ns.db.chat = false
			end
		end },
}
O.SWITCHES = SWITCHES

-- (1.11.0) The windows of Curator back in their first places: the album (at its size), the booster bar, the
-- small window of the boosters (and its size), the golden quest followed.
function O:ResetWindows()
	local db = ns.db
	if not db then
		return
	end
	db.barAt, db.compactAt, db.compactW, db.goldAt, db.leadsAt = nil, nil, nil, nil, nil
	-- (1.14.3: the alerts and the panel of the guild, UI/Live.lua)
	if ns.Live and ns.Live.ResetPlace then
		ns.Live:ResetPlace()
	else
		db.alertsAt = nil
	end
	local f = A.frame
	if f then
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
	end
	if ns.BoosterBar and ns.BoosterBar.frame then
		ns.BoosterBar:Place()
	end
	if ns.Booster and ns.Booster.frame and ns.Booster.ApplySize then
		ns.Booster:ApplySize()
	end
	local G = ns.GoldenUI
	if G and G.tracker and G.PlaceTracker then
		G:PlaceTracker()
	end
	-- (1.14.0: the leads of the tavern)
	if ns.LodgingUI and ns.LodgingUI.tracker then
		ns.LodgingUI:PlaceTracker()
	end
	local shop = ns.RubiesUI and ns.RubiesUI.shop
	if shop then
		shop:Hide()
	end
	ns.Print(L["The windows of Curator are back in their first places."])
end

-------------------------------------------------------------------------------
-- The panel
-------------------------------------------------------------------------------
local function Slider(parent, width)
	local sl = S.Make("Slider", nil, parent, "OptionsSliderTemplate")
	if not sl then
		sl = CreateFrame("Slider", nil, parent)
		sl:SetOrientation("HORIZONTAL")
		sl:SetHeight(17)
		sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		local bg = sl:CreateTexture(nil, "BACKGROUND")
		bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
		bg:SetPoint("TOPLEFT", 0, -3)
		bg:SetPoint("BOTTOMRIGHT", 0, 3)
	end
	-- (the words of the template: ours instead)
	for _, k in ipairs({ "Low", "High", "Text" }) do
		local x = sl[k]
		if x and x.SetText then
			x:SetText("")
		end
	end
	sl:SetWidth(width)
	sl:SetMinMaxValues(O.SCALE_MIN * 100, O.SCALE_MAX * 100)
	sl:SetValueStep(O.SCALE_STEP * 100)
	if sl.SetObeyStepOnDrag then
		sl:SetObeyStepOnDrag(true)
	end
	sl:EnableMouseWheel(true)
	return sl
end

-- (1.14.0, a player's word) The row of the booster bar: shown or not (its check box, c), its size, its picture, its
-- lights (UI/BoosterBar.lua), on the same row: the page keeps its height.
function O:BarRow(p, c)
	c.Text:SetWidth(165)
	local function Tip(owner, title, text)
		CuratorOctoFull.SetScript(owner, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L[title], 1, 1, 1)
			GameTooltip:AddLine(L[text], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(owner, "OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	Tip(c, "The booster bar", "Over the experience bar of the game: the points toward your next booster. Shift-drag it to move it.")
	local sl = Slider(p, 90)
	local BB = ns.BoosterBar
	if BB then
		sl:SetMinMaxValues(BB.SCALE_MIN * 100, BB.SCALE_MAX * 100)
		sl:SetValueStep(BB.SCALE_STEP * 100)
	end
	sl:SetPoint("LEFT", c, "LEFT", 204, 0)
	CuratorOctoFull.SetScript(sl, "OnValueChanged", function(_, v)
		if O.painting or not ns.BoosterBar then
			return
		end
		ns.BoosterBar:SetScale((tonumber(v) or 100) / 100)
		O:Paint()
	end)
	CuratorOctoFull.SetScript(sl, "OnMouseWheel", function(_, delta)
		local BB = ns.BoosterBar
		if BB then
			BB:SetScale(BB:Scale() + (delta > 0 and BB.SCALE_STEP or -BB.SCALE_STEP))
			O:Paint()
		end
	end)
	Tip(sl, "Size of the booster bar", "From 60 % to 130 %. The mouse wheel over it does the same.")
	p.barScale = sl
	p.barScaleValue = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.barScaleValue:SetPoint("LEFT", sl, "RIGHT", 8, 0)
	local art = S.Check(p, L["Picture"])
	art:SetPoint("LEFT", c, "LEFT", 349, 0)
	CuratorOctoFull.SetScript(art, "OnClick", function(self)
		if not ns.db then
			return
		end
		ns.Play(ns.SND.click)
		ns.db.barArtHide = (not self:GetChecked()) or nil
		if ns.BoosterBar then
			ns.BoosterBar:Refresh()
		end
		O:Paint()
	end)
	Tip(art, "Picture", "The booster on the left end of the bar.")
	p.barArt = art
	local lights = S.Check(p, L["Lights"])
	lights:SetPoint("LEFT", c, "LEFT", 454, 0)
	CuratorOctoFull.SetScript(lights, "OnClick", function(self)
		if not ns.db then
			return
		end
		ns.Play(ns.SND.click)
		ns.db.barCalm = (not self:GetChecked()) or nil
		if ns.BoosterBar then
			ns.BoosterBar:Refresh()
		end
		O:Paint()
	end)
	Tip(lights, "Lights", "The light that passes over the bar, the spark at its end, the talents that breathe. Off: the bar stays still, and lights up only when a booster comes.")
	p.barLights = lights
end

-- (1.14.3, the players' word) The row of the alerts of the guild: on or off (its check box, c), its epic cards and
-- better only, and where the alerts show (UI/Live.lua: V:Mover), on the same row.
function O:LiveRow(p, c)
	c.Text:SetWidth(200)
	local function Tip(owner, title, text)
		CuratorOctoFull.SetScript(owner, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L[title], 1, 1, 1)
			GameTooltip:AddLine(L[text], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(owner, "OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	Tip(c, "Your guild's alerts", "Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds.")
	local epic = S.Check(p, L["Epic and better only"])
	epic:SetPoint("LEFT", c, "LEFT", 230, 0)
	epic.Text:SetWidth(160)
	CuratorOctoFull.SetScript(epic, "OnClick", function(self)
		if not ns.db then
			return
		end
		ns.Play(ns.SND.click)
		ns.db.liveEpic = self:GetChecked() and true or nil
		O:Paint()
	end)
	Tip(epic, "Epic and better only", "Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank.")
	p.liveEpic = epic
	local move = S.Button(p, L["Move"], 90, 22)
	move:SetPoint("LEFT", c, "LEFT", 424, 0)
	CuratorOctoFull.SetScript(move, "OnClick", function()
		ns.Play(ns.SND.click)
		if ns.Live and ns.Live.Mover then
			ns.Live:Mover()
		end
	end)
	Tip(move, "Move", "Where the alerts of Curator and the panel of your guild show: drag them, then Done.")
	p.liveMove = move
end

function O:Panel()
	if self.panel then
		return self.panel
	end
	local p = CreateFrame("Frame", "CuratorOptions", UIParent)
	-- (1.12.1: two switches more, the reminders to save and the chat channel, a little closer together)
	CuratorOctoFull.SetSize(p, 620, 606)
	p:Hide()
	p.name = "Curator"
	p.title = S.Text(p, "GameFontNormalLarge", "LEFT")
	p.title:SetPoint("TOPLEFT", 16, -16)
	p.title:SetText("Curator")
	p.version = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.version:SetPoint("LEFT", p.title, "RIGHT", 10, -1)
	p.version:SetTextColor(0.7, 0.7, 0.74)
	p.sub = S.Text(p, "GameFontHighlightSmall", "LEFT")
	p.sub:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -8)
	p.sub:SetWidth(560)
	CuratorOctoFull.SetWordWrap(p.sub, true)
	p.sub:SetText(L["The options of your collection of cards. They are the account's: every character has the same."])

	-- the size of the album
	local y = -70
	p.albumHead = S.Text(p, "GameFontNormal", "LEFT")
	p.albumHead:SetPoint("TOPLEFT", 16, y)
	p.albumHead:SetText(L["The album"])
	p.scaleLabel = S.Text(p, "GameFontHighlight", "LEFT")
	p.scaleLabel:SetPoint("TOPLEFT", 30, y - 26)
	p.scaleLabel:SetText(L["Size of the album"])
	p.scale = Slider(p, 220)
	p.scale:SetPoint("LEFT", p.scaleLabel, "RIGHT", 18, 0)
	p.scaleValue = S.Text(p, "GameFontHighlight", "LEFT")
	p.scaleValue:SetPoint("LEFT", p.scale, "RIGHT", 12, 0)
	CuratorOctoFull.SetScript(p.scale, "OnValueChanged", function(_, v)
		if O.painting then
			return
		end
		O:SetAlbumScale((tonumber(v) or 100) / 100)
	end)
	CuratorOctoFull.SetScript(p.scale, "OnMouseWheel", function(_, delta)
		O:StepScale(delta)
	end)
	p.scaleReset = S.Button(p, L["Reset"], 90, 22)
	p.scaleReset:SetPoint("LEFT", p.scaleValue, "RIGHT", 18, 0)
	CuratorOctoFull.SetScript(p.scaleReset, "OnClick", function()
		ns.Play(ns.SND.click)
		O:SetAlbumScale(1)
	end)
	-- (1.12.0: the note of the size in the tooltip of its slider; the language of Curator in its place)
	CuratorOctoFull.SetScript(p.scale, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Size of the album"], 1, 1, 1)
		GameTooltip:AddLine(L["Ctrl + mouse wheel over the album does the same. Drag its title bar to move it."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(p.scale, "OnLeave", function()
		GameTooltip:Hide()
	end)
	p.langLabel = S.Text(p, "GameFontHighlight", "LEFT")
	p.langLabel:SetPoint("TOPLEFT", p.scaleLabel, "BOTTOMLEFT", 0, -16)
	p.langLabel:SetText(L["Language of Curator"])
	p.langPrev = S.Button(p, "<", 26, 22)
	p.langPrev:SetPoint("LEFT", p.langLabel, "RIGHT", 18, 0)
	p.langValue = S.Text(p, "GameFontHighlight", "CENTER")
	p.langValue:SetWidth(210)
	p.langValue:SetPoint("LEFT", p.langPrev, "RIGHT", 6, 0)
	p.langNext = S.Button(p, ">", 26, 22)
	p.langNext:SetPoint("LEFT", p.langValue, "RIGHT", 6, 0)
	for _, b in ipairs({ p.langPrev, p.langNext }) do
		local _, b = _, b; CuratorOctoFull.SetScript(b, "OnClick", function(self)
			ns.Play(ns.SND.click)
			O:StepLanguage(self == p.langPrev and -1 or 1)
		end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(L["Language of Curator"], 1, 1, 1)
			GameTooltip:AddLine(L["Its words and the names of its cards. It changes after a reload of the interface."], 0.85, 0.85, 0.85, true)
			GameTooltip:Show()
		end)
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	p.langReload = S.Button(p, L["Reload now"], 130, 22)
	p.langReload:SetPoint("LEFT", p.langNext, "RIGHT", 14, 0)
	-- (1.13.0, after its third test: the game no longer lets an addon reload the interface; a macro of the game laid over
	-- the button does it, UI/Save.lua. In a fight, or without it: /reload to type.)
	CuratorOctoFull.SetScript(p.langReload, "OnClick", function()
		ns.Print(L["Type /reload: the game no longer lets an addon reload the interface."])
	end)
	CuratorOctoFull.HookScript(p.langReload, "OnEnter", function(self)
		if ns.Save and ns.Save.Cover then
			ns.Save:Cover(self, ns.Save.LANGUAGE)
		end
	end)

	-- the switches (1.14.0: three more, the counter, the leads and the creatures in 2D; a little closer together, the
	-- panel keeps its height: the canvas of the options of the game is about 600 high)
	y = y - 80
	p.checks = {}
	for _, sw in ipairs(SWITCHES) do
		local _, sw = _, sw; if sw.section then
			local h = S.Text(p, "GameFontNormal", "LEFT")
			h:SetPoint("TOPLEFT", 16, y - 8)
			h:SetText(L[sw.section])
			y = y - 28
		else
			local c = S.Check(p, L[sw.label])
			c:SetPoint("TOPLEFT", 26, y)
			c.Text:SetWidth(520)
			c.Text:SetJustifyH("LEFT")
			c.sw = sw
			CuratorOctoFull.SetScript(c, "OnClick", function(self)
				if not ns.db then
					return
				end
				ns.Play(ns.SND.click)
				self.sw.set(self:GetChecked() and true or false)
				O:Paint()
			end)
			p.checks[CuratorOctoFull.Length(p.checks) + 1] = c
			if sw.row == "bar" then
				O:BarRow(p, c)
			elseif sw.row == "live" then
				O:LiveRow(p, c)
			end
			y = y - 22
		end
	end

	-- the album, the guided tour
	p.open = S.Button(p, L["Open the album"], 160, 24)
	p.open:SetPoint("TOPLEFT", 26, y - 10)
	CuratorOctoFull.SetScript(p.open, "OnClick", function()
		ns.Play(ns.SND.click)
		if ns.Album and not (ns.Album.frame and ns.Album.frame:IsShown()) then
			ns.Album:Toggle()
		end
	end)
	p.tour = S.Button(p, L["Guided tour"], 160, 24)
	p.tour:SetPoint("LEFT", p.open, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(p.tour, "OnClick", function()
		ns.Play(ns.SND.click)
		if ns.Tour then
			ns.Tour:Start()
		end
	end)
	-- (1.11.0) the windows moved back where they were at first
	p.reset = S.Button(p, L["Reset the windows"], 180, 24)
	p.reset:SetPoint("LEFT", p.tour, "RIGHT", 10, 0)
	CuratorOctoFull.SetScript(p.reset, "OnClick", function()
		ns.Play(ns.SND.click)
		O:ResetWindows()
	end)
	CuratorOctoFull.SetScript(p.reset, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Reset the windows"], 1, 1, 1)
		GameTooltip:AddLine(L["The album, the booster bar, the small window of the boosters and the golden quest back in their first places."], 0.85, 0.85, 0.85, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(p.reset, "OnLeave", function()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(p, "OnShow", function()
		O:Paint()
	end)
	self.panel = p
	return p
end

function O:Paint()
	local p = self.panel
	if not (p and p:IsVisible() and ns.db) then
		return
	end
	self.painting = true
	p.version:SetText(ns.Beta and ns.Beta:VersionText() or ns.version)
	local k = self:AlbumScale()
	p.scale:SetValue(math.floor(k * 100 + 0.5))
	p.scaleValue:SetText(string.format(("%d%%"), math.floor(k * 100 + 0.5)))
	CuratorOctoFull.SetEnabled(p.scaleReset, math.abs(k - 1) > 0.001)
	for _, c in ipairs(p.checks) do
		c:SetChecked(c.sw.get() and true or false)
	end
	-- (1.14.0) the row of the booster bar: its size, its picture, its lights
	local BB = ns.BoosterBar
	if p.barScale and BB then
		local b = BB:Scale()
		p.barScale:SetValue(math.floor(b * 100 + 0.5))
		p.barScaleValue:SetText(string.format(("%d%%"), math.floor(b * 100 + 0.5)))
		p.barArt:SetChecked(BB:ArtShown())
		p.barLights:SetChecked(not BB:Calm())
		-- (the bar hidden: its options dimmed)
		local on = not ns.db.barHide
		for _, w in ipairs({ p.barScale, p.barArt, p.barLights }) do
			if w.SetEnabled then
				CuratorOctoFull.SetEnabled(w, on)
			end
		end
		local g = on and 1 or 0.5
		p.barScaleValue:SetTextColor(g, g, g)
		for _, c in ipairs({ p.barArt, p.barLights }) do
			if c.Text then
				c.Text:SetTextColor(on and 1 or 0.5, on and 0.82 or 0.5, on and 0 or 0.5)
			end
		end
	end
	-- (1.14.3) the row of the alerts of the guild: its epic cards only, dimmed when the guild is off
	if p.liveEpic then
		local on = ns.db.live ~= false
		p.liveEpic:SetChecked(ns.db.liveEpic and true or false)
		if p.liveEpic.SetEnabled then
			CuratorOctoFull.SetEnabled(p.liveEpic, on)
		end
		if p.liveEpic.Text then
			p.liveEpic.Text:SetTextColor(on and 1 or 0.5, on and 0.82 or 0.5, on and 0 or 0.5)
		end
	end
	-- (1.12.0) the language: a reload to take it, when it is not the one shown
	local lang, name = self:Language()
	p.langValue:SetText(name)
	local shown = ns.locale or "enUS"
	shown = (shown == "enGB" and "enUS") or (shown == "esMX" and "esES") or shown
	CuratorOctoFull.SetShown(p.langReload, (lang or ClientLang()) ~= shown)
	self.painting = false
end

-- In the options of the game (once, at login).
function O:Register()
	if self.registered then
		return self.category ~= nil or self.legacy
	end
	self.registered = true
	local p = self:Panel()
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, p, "Curator")
		if ok and cat then
			pcall(Settings.RegisterAddOnCategory, cat)
			self.category = cat
			return true
		end
	end
	if InterfaceOptions_AddCategory then
		local ok = pcall(InterfaceOptions_AddCategory, p)
		self.legacy = ok and true or nil
		return self.legacy
	end
	return false
end

-- The options shown: in the options of the game, else in a window of their own.
function O:Open()
	local inGame = self:Register()
	if inGame and self.category and Settings and Settings.OpenToCategory then
		local id = (self.category.GetID and self.category:GetID()) or self.category.ID
		local ok = pcall(Settings.OpenToCategory, id)
		if ok then
			return
		end
	elseif inGame and self.legacy and InterfaceOptionsFrame_OpenToCategory then
		-- (twice: the game opens the right page the second time)
		pcall(InterfaceOptionsFrame_OpenToCategory, self.panel)
		pcall(InterfaceOptionsFrame_OpenToCategory, self.panel)
		return
	end
	self:Window()
end

-- A window of its own (a client without the options of the addons).
function O:Window()
	local w = self.window
	if not w then
		w = S.Window("CuratorOptionsWindow", 640, 670)
		w:SetPoint("CENTER")
		w:SetFrameStrata("DIALOG")
		w:SetToplevel(true)
		w:EnableMouse(true)
		tinsert(UISpecialFrames, "CuratorOptionsWindow")
		if w.SetTitle then
			w:SetTitle("Curator")
		end
		if w.SetPortraitToAsset then
			w:SetPortraitToAsset(ns.MEDIA .. "Icon")
		end
		CuratorOctoFull.SetScript(w.CloseButton, "OnClick", function()
			w:Hide()
		end)
		w.drag = S.DragBar(w, 22)
		self.window = w
	end
	-- (the panel comes in it; the options of the game, opened later, take it back in theirs)
	local p = self:Panel()
	p:SetParent(w)
	p:ClearAllPoints()
	p:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -50)
	p:Show()
	w:Show()
	self:Paint()
end

ns.On("LOGIN", function()
	O:Register()
end)

-- (what changed elsewhere: a command, the button of the booster scene)
for _, e in ipairs({ "CHANGED", "GOLDEN_CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		O:Paint()
	end)
end
