local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.8.0) The app of Curator, said in the game: a window at the first login of an account (once:
-- db.siteTold), then whenever /curator site asks for it. What does not work without the app (the
-- mandatory updates, the front of the collectors, the page on the website, the backup), each with a
-- red cross, then where to get it: its address, selected for Ctrl+C (an addon opens no browser).
-- Not when the app is linked to an account on this computer (it says so where it writes the news of
-- the front, Feed.lua: ns.APP), nor on a Mac (the app is for Windows), nor on a collection suspended
-- or obsolete; not in a fight nor while the studio takes its photos (later, when they end).
-- (1.12.0, later) The end of the beta of WoW Forever (W.BETA_END): until then, once a day at a login, the same window
-- tells what becomes of the collection, with the app or without it; with the app linked here, a line in the chat.
-------------------------------------------------------------------------------
local W = {}
ns.SiteWindow = W

W.URL = "curator-wow.com/download"
-- (the end of the beta of WoW Forever: October 21, the end of that day in Paris, by the time of the server)
W.BETA_END = 1792620000
W.DELAY = 8 -- seconds after the login, for the loading and the alerts of the login to pass
W.WIDTH = 520
local LEFT, RIGHT, ICON, GAP = 24, 24, 18, 8

-- What a collection misses without the app, in this order.
local function Lost()
	return {
		L["Every update is mandatory: as soon as a new version comes out, yours stops working until it is updated. The app does it for you."],
		L["The front of the collectors stays silent: no news of the war, no booster for the winning side, no bounty to claim."],
		L["Your page on the website and the rankings are not updated after your games."],
		L["No backup: if your game files are lost, your collection is lost with them."],
	}
end

function W:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorSite", self.WIDTH, 420)
	f:SetPoint("CENTER", 0, 90)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorSite")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle(L["Curator needs its app"])
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			W:Hide()
		end)
	end

	-- the warning, in large red letters, next to the portrait
	f.head = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.head:SetWordWrap(true)
	f.head:SetTextColor(1, 0.32, 0.22)

	-- what does not work without the app: a red cross in front of each
	f.rows = {}
	for i = 1, math.max(CuratorOctoFull.Length(Lost()), 2) do
		local icon = f:CreateTexture(nil, "ARTWORK")
		icon:SetTexture(MEDIA .. "Cross")
		CuratorOctoFull.SetSize(icon, ICON, ICON)
		local text = S.Text(f, "GameFontHighlight", "LEFT")
		text:SetWordWrap(true)
		text:SetSpacing(2)
		f.rows[i] = { icon = icon, text = text }
	end

	-- where to get it: the address, selected (Ctrl+C)
	f.cta = S.Text(f, "GameFontNormal", "LEFT")
	f.cta:SetWordWrap(true)
	f.box = S.Inset(f)
	f.box:SetHeight(34)
	local eb = CreateFrame("EditBox", nil, f.box)
	eb:SetPoint("TOPLEFT", 10, -2)
	eb:SetPoint("BOTTOMRIGHT", -10, 2)
	eb:SetAutoFocus(false)
	if GameFontHighlightLarge or GameFontHighlight then
		eb:SetFontObject(GameFontHighlightLarge or GameFontHighlight)
	end
	eb:SetJustifyH("CENTER")
	CuratorOctoFull.SetScript(eb, "OnEscapePressed", function()
		W:Hide()
	end)
	CuratorOctoFull.SetScript(eb, "OnEditFocusGained", function(self)
		self:HighlightText()
	end)
	CuratorOctoFull.SetScript(eb, "OnTextChanged", function(self, user)
		-- (typed in: the address comes back, selected)
		if user and self:GetText() ~= W.URL then
			self:SetText(W.URL)
			self:HighlightText()
		end
	end)
	CuratorOctoFull.SetScript(eb, "OnMouseUp", function(self)
		self:HighlightText()
	end)
	f.edit = eb
	f.hint = S.Text(f, "GameFontNormalSmall", "CENTER")
	f.hint:SetTextColor(0.75, 0.75, 0.8)

	f.close = S.Button(f, L["Close"], 130, 24)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		W:Hide()
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		eb:ClearFocus()
	end)
	self.frame = f
	return f
end

-- Everything set from the top down, each text as tall as its lines in this language: the window as
-- tall as all of it.
function W:Layout()
	local f = self.frame
	local width = self.WIDTH
	f.head:ClearAllPoints()
	f.head:SetPoint("TOPLEFT", 70, -34)
	f.head:SetWidth(width - 70 - RIGHT)
	local y = math.max(78, 34 + (f.head:GetStringHeight() or 16) + 16)
	for _, row in ipairs(f.rows) do
		if row.text:IsShown() then
		row.icon:ClearAllPoints()
		row.icon:SetPoint("TOPLEFT", LEFT, -(y - 1))
		row.text:ClearAllPoints()
		row.text:SetPoint("TOPLEFT", LEFT + ICON + GAP, -y)
		row.text:SetWidth(width - LEFT - ICON - GAP - RIGHT)
		y = y + math.max(ICON, row.text:GetStringHeight() or 12) + 10
		end
	end
	y = y + 8
	f.cta:ClearAllPoints()
	f.cta:SetPoint("TOPLEFT", LEFT, -y)
	f.cta:SetWidth(width - LEFT - RIGHT)
	y = y + (f.cta:GetStringHeight() or 12) + 8
	f.box:ClearAllPoints()
	f.box:SetPoint("TOPLEFT", LEFT, -y)
	f.box:SetPoint("TOPRIGHT", -RIGHT, -y)
	y = y + 34 + 6
	f.hint:ClearAllPoints()
	f.hint:SetPoint("TOPLEFT", LEFT, -y)
	f.hint:SetWidth(width - LEFT - RIGHT)
	y = y + (f.hint:GetStringHeight() or 10) + 16
	f.close:ClearAllPoints()
	f.close:SetPoint("TOP", 0, -y)
	f:SetHeight(y + 24 + 18)
end

-- Shown (the address selected again when it is already there).
function W:Show()
	local f = self:Build()
	f:SetTitle(L["Curator needs its app"])
	f.head:SetText(L["Without its app, a large part of Curator will not work."])
	local lost = Lost()
	for i, row in ipairs(f.rows) do
		row.icon:SetTexture(MEDIA .. "Cross")
		CuratorOctoFull.SetShown(row.icon, lost[i] ~= nil)
		CuratorOctoFull.SetShown(row.text, lost[i] ~= nil)
		row.text:SetText(lost[i] or "")
	end
	f.cta:SetText(L["Install the app of Curator (Windows) from the website, then sign in with Battle.net."])
	f.hint:SetText(L["Ctrl+C (Cmd+C on a Mac) copies the address: paste it in your browser."])
	f.edit:SetText(self.URL)
	self:Layout()
	if not f:IsShown() then
		ns.Play(ns.SND.open)
	end
	f:Show()
	f:Raise()
	f.edit:SetFocus()
	f.edit:HighlightText()
end

function W:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

-- Said by itself, once for the account: not when the app is linked here, not on a Mac, not to a
-- collection that cannot play, not in a fight nor during the photos of the studio (later, when they
-- end). True when it is shown now.
function W:Offer()
	local db = ns.db
	if not db or db.siteTold or ns.APP then
		return false
	end
	if IsMacClient and IsMacClient() then
		return false
	end
	if ns.Beta and ns.Beta:Over() then
		return false
	end
	if InCombatLockdown and InCombatLockdown() then
		self.afterFight = true
		return false
	end
	if ns.Studio and ns.Studio.running then
		ns.Delay(30, function()
			W:Offer()
		end, W)
		return false
	end
	db.siteTold = (GetServerTime and CuratorOctoFull.ServerTime()) or time()
	self:Show()
	return true
end

-------------------------------------------------------------------------------
-- (1.12.0, later) The end of the beta of WoW Forever
-------------------------------------------------------------------------------
-- Before it (now: the time of the server).
function W:BetaOn(now)
	now = now or ((GetServerTime and CuratorOctoFull.ServerTime()) or time())
	return now < self.BETA_END
end

-- What becomes of the collection: without the app, lost with the beta; with it, kept online.
local function BetaLines()
	return {
		{ MEDIA .. "Cross", L["Your collection lives only in the files of the game, on this computer: when the beta ends, it does not follow you into WoW Forever."] },
		{ MEDIA .. "Check", L["The Curator app saves it online: your page on the website keeps it, with a backup of your save to put back on your computer."] },
	}
end

-- The window of the end of the beta.
function W:ShowBetaEnd()
	local f = self:Build()
	f:SetTitle(L["The beta of WoW Forever ends"])
	f.head:SetText(L["The beta of WoW Forever ends on October 21. Without the Curator app, your collection and all the rest will be lost."])
	local lines = BetaLines()
	for i, row in ipairs(f.rows) do
		local l = lines[i]
		CuratorOctoFull.SetShown(row.icon, l ~= nil)
		CuratorOctoFull.SetShown(row.text, l ~= nil)
		if l then
			row.icon:SetTexture(l[1])
			row.text:SetText(l[2])
		end
	end
	f.cta:SetText(L["Before October 21: install the app of Curator (Windows) from the website, sign in with Battle.net, then log out of the game once."])
	f.hint:SetText(L["Ctrl+C (Cmd+C on a Mac) copies the address: paste it in your browser."])
	f.edit:SetText(self.URL)
	self:Layout()
	if not f:IsShown() then
		ns.Play(ns.SND.open)
	end
	f:Show()
	f:Raise()
	f.edit:SetFocus()
	f.edit:HighlightText()
end

-- Said by itself, once a day until the beta ends: the window without the app here, a line in the chat with it. True
-- when it was said now.
function W:TellBetaEnd()
	local db = ns.db
	if not db or not self:BetaOn() or (ns.Beta and ns.Beta:Over()) then
		return false
	end
	local day = (ns.Inns and ns.Inns.Today) and ns.Inns:Today() or math.floor(((GetServerTime and CuratorOctoFull.ServerTime()) or time()) / 86400)
	if db.betaEndTold == day then
		return false
	end
	if InCombatLockdown and InCombatLockdown() then
		self.afterFight = true
		return false
	end
	db.betaEndTold = day
	if ns.APP or (IsMacClient and IsMacClient()) then
		-- (1.12.1: or the save at hand, UI/Save.lua)
		ns.Print(L["The beta of WoW Forever ends on October 21: the Curator app keeps your collection online. Before the end, save once (the scroll of the album, or /curator save) or log out of the game, so that the last of it goes."])
		return true
	end
	-- (the window of the app said at the same time: this one says it all)
	db.siteTold = db.siteTold or ((GetServerTime and CuratorOctoFull.ServerTime()) or time())
	ns.Print(L["The beta of WoW Forever ends on October 21. Without the Curator app, your collection and all the rest will be lost: curator-wow.com/download"])
	self:ShowBetaEnd()
	return true
end

ns.On("LOGIN", function()
	ns.Delay(W.DELAY, function()
		-- (1.12.0, later: the end of the beta of WoW Forever first; the app is said in it)
		if not W:TellBetaEnd() then
			W:Offer()
		end
	end, W)
end)

-- (in a fight at the moment it was due: when the fight ends)
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
CuratorOctoFull.SetScript(ev, "OnEvent", function()
	if W.afterFight then
		W.afterFight = nil
		ns.Delay(2, function()
			if not W:TellBetaEnd() then
				W:Offer()
			end
		end, W)
	end
end)
