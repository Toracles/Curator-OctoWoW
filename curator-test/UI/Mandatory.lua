local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-------------------------------------------------------------------------------
-- The window of a mandatory update (1.4, Mandatory.lua): the version that is out, why this one no
-- longer works, and that the collection waits, nothing lost. It comes at the login and whenever
-- something is asked of the locked copy (the album, a booster), at most once every ten minutes (1.14.2). (1.14.0) The same window says that Curator works on
-- WoW Forever only (Beta.lua, B:Elsewhere). (1.14.3) Below it, the window of the news of an update (ns.NewsWindow).
-------------------------------------------------------------------------------
local W = {}
ns.MandatoryWindow = W

local WIDTH, HEIGHT = 440, 236

-- (1.14.2, his word after a player found it too much: the window and the raid warning at each thing asked of the locked
-- copy) The window comes by itself at most once every W.EVERY seconds, and the raid warning sounds only the first time
-- of the session; the chat still says it, once a minute at most (Mandatory.lua: M:Tell; Beta.lua: B:TellElsewhere).
-- The copy stays locked all the same.
W.EVERY = 600

-- The window may come by itself now (and it is noted that it came).
function W:Due()
	local now = (GetTime and GetTime()) or 0
	if self.shownAt and now - self.shownAt < self.EVERY then
		return false
	end
	self.shownAt = now
	return true
end

-- The window comes: the raid warning, the first time of the session only.
function W:Open(f)
	if not self.rang then
		self.rang = true
		ns.Play(ns.SND.warning)
	end
	f:Show()
	f:Raise()
end

function W:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorMandatory", WIDTH, HEIGHT)
	f:SetPoint("CENTER", 0, 140)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorMandatory")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle(L["Mandatory update"])
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			f:Hide()
		end)
	end

	-- what is out, in large letters, then why this copy stops and what to do
	f.head = S.Text(f, "GameFontNormalLarge", "CENTER")
	f.head:SetPoint("TOPLEFT", 70, -46)
	f.head:SetPoint("TOPRIGHT", -24, -46)
	f.body = S.Text(f, "GameFontHighlight", "LEFT")
	f.body:SetPoint("TOPLEFT", 70, -78)
	f.body:SetPoint("TOPRIGHT", -24, -78)
	f.body:SetSpacing(3)
	CuratorOctoFull.SetWordWrap(f.body, true)
	-- the alert of the game's dialogs beside it
	f.alert = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.alert, 40, 40)
	f.alert:SetPoint("TOPLEFT", 20, -72)
	f.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")

	f.ok = S.Button(f, OKAY or "OK", 130, 24)
	f.ok:SetPoint("BOTTOM", 0, 18)
	CuratorOctoFull.SetScript(f.ok, "OnClick", function()
		f:Hide()
	end)
	self.frame = f
	return f
end

-- Shown (by: the version that made this one obsolete, when known).
function W:Show(by)
	local f = self:Build()
	f:SetTitle(L["Mandatory update"])
	f.head:SetText(by and string.format(L["Curator %s is out"], by) or L["A new version of Curator is out"])
	local beta = ns.Beta and ns.Beta.BETA
	f.body:SetText(string.format((beta and L["This update is mandatory: your version (%s) no longer works. Get the new one in the beta channel: your collection is waiting for you, nothing is lost."]
		or L["This update is mandatory: your version (%s) no longer works. Update Curator, then come back: your collection is waiting for you, nothing is lost."]), ns.version or "?"))
	if f:IsShown() then
		f:Raise()
	elseif self:Due() then
		self:Open(f)
	end
end

-- (1.14.0) Shown: this game is not WoW Forever, where Curator works only.
function W:ShowElsewhere()
	local f = self:Build()
	f:SetTitle(L["Only on WoW Forever"])
	f.head:SetText(L["Curator is made for WoW Forever"])
	f.body:SetText(L["It does not work in this version of the game: nothing is earned here. Your collection waits for you on WoW Forever, nothing is lost."])
	if f:IsShown() then
		f:Raise()
	elseif self:Due() then
		self:Open(f)
	end
end

function W:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

-------------------------------------------------------------------------------
-- (1.14.3, his word of November 6: « Pour chaque maj mettre une fenetre texte disant que l'addon a été mis a jour avec
-- l'essentiel des correctif et nouveauté ») The window of the news of an update: at the first login after an update, once
-- for the collection, what is new and what is fixed in it, in short. Its lines in English here, in the tables of each
-- language in the Locale files (Locale114.lua for 1.14.3). A new collection learns nothing of it (the next update tells
-- its own); one that is suspended, banned, locked by a mandatory update or out of WoW Forever neither. Never in a fight:
-- after it. Seen once shown (db.newsSeen: the version; sealed with the rest, so that a version of before reads the save
-- as it was written). /curator news shows it again.
-------------------------------------------------------------------------------
local N = {}
ns.NewsWindow = N

-- Each version its lines, the newest first. Each release adds its own here, and their words in each language
-- (sortie1143.py checks that the version released has its own).
N.NEWS = {
	{ v = "1.14.3", lines = {
		"Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it.",
		"Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3.",
		"A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it.",
		"The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord.",
		"The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts).",
		"Your main character can be chosen again, once: log in with it and type /curator main.",
		"Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window.",
	} },
}

-- (a moment after the login: after the windows of the login, a mandatory update, a suspension)
N.DELAY = 6
local NEWS_W = 480
local NEWS_LEFT, NEWS_RIGHT = 26, 26
-- (two versions told at once at most, and the newest alone if both would make it taller than this)
N.MAX_H = 640

-- The numbers of a version ("1.14.3": 1, 14, 3).
local function Numbers(v)
	local t = {}
	for n in CuratorOctoFull.Gmatch(tostring(v or ""), "%d+") do
		t[CuratorOctoFull.Length(t) + 1] = tonumber(n)
	end
	return t
end

-- a newer than b (false when one of them is not a version).
local function Newer(a, b)
	local x, y = Numbers(a), Numbers(b)
	if CuratorOctoFull.Length(x) == 0 or CuratorOctoFull.Length(y) == 0 then
		return false
	end
	for i = 1, math.max(CuratorOctoFull.Length(x), CuratorOctoFull.Length(y)) do
		local p, q = x[i] or 0, y[i] or 0
		if p ~= q then
			return p > q
		end
	end
	return false
end
N.Newer = Newer

-- The news to tell after an update, the newest first: those of the versions after the one last seen, up to this one
-- (never seen: this one only); two at most.
function N:Since(seen, now)
	now = now or ns.version
	local out = {}
	for _, e in ipairs(self.NEWS) do
		local upTo = not Newer(e.v, now)
		local after
		if seen then
			after = Newer(e.v, seen)
		else
			after = not Newer(now, e.v)
		end
		if upTo and after then
			out[CuratorOctoFull.Length(out) + 1] = e
			if CuratorOctoFull.Length(out) >= 2 then
				break
			end
		end
	end
	return out
end

-- The news of this version (/curator news); none: the newest there is.
function N:Current()
	for _, e in ipairs(self.NEWS) do
		if not Newer(e.v, ns.version) then
			return e
		end
	end
	return self.NEWS[1]
end

-- Nothing in its way: a collection that plays (not suspended, banned, locked by a mandatory update, out of WoW
-- Forever, a beta past its day).
function N:Free()
	local db = ns.db
	if not db or db.edited then
		return false
	end
	local B = ns.Beta
	if B and B.Over and B:Over() then
		return false
	end
	return true
end

-- At the login: after an update, its news, a moment after.
function N:Login()
	local db = ns.db
	if not db then
		return
	end
	local now = ns.version
	local seen = type(db.newsSeen) == "string" and db.newsSeen or nil
	-- (seen already, or a version of before played after a newer one)
	if seen and not Newer(now, seen) then
		return
	end
	-- (a new collection: nothing to tell, the next update tells its own; an update without news: the next one)
	if not db.welcomed or CuratorOctoFull.Length(self:Since(seen, now)) == 0 then
		db.newsSeen = now
		return
	end
	ns.CancelOwner(self)
	ns.Delay(self.DELAY, function()
		self:Come()
	end, self)
end

-- It comes, when nothing is in its way; in a fight, after it.
function N:Come()
	if not self:Free() then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		self:AfterFight()
		return
	end
	local list = self:Since(type(ns.db.newsSeen) == "string" and ns.db.newsSeen or nil, ns.version)
	if CuratorOctoFull.Length(list) == 0 then
		return
	end
	ns.db.newsSeen = ns.version
	self:Show(list)
end

function N:AfterFight()
	if not self.waiter then
		local w = CreateFrame("Frame")
		CuratorOctoFull.SetScript(w, "OnEvent", function(frame)
			frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
			ns.Delay(1, function()
				N:Come()
			end, N)
		end)
		self.waiter = w
	end
	self.waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function N:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorNews", NEWS_W, 360)
	f:SetPoint("CENTER", 0, 100)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorNews")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle("Curator")
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			N:Hide()
		end)
	end
	f.head = S.Text(f, "GameFontNormalLarge", "LEFT")
	CuratorOctoFull.SetWordWrap(f.head, true)
	f.heads, f.lines = {}, {}
	f.rule = S.Divider(f, NEWS_W - NEWS_LEFT - NEWS_RIGHT, 0.6)
	f.foot = S.Text(f, "GameFontDisableSmall", "LEFT")
	CuratorOctoFull.SetWordWrap(f.foot, true)
	f.ok = S.Button(f, L["Close"], 130, 24)
	CuratorOctoFull.SetScript(f.ok, "OnClick", function()
		N:Hide()
	end)
	self.frame = f
	return f
end

-- Everything from the top down, each text as tall as its lines: the window as tall as all of it (its height).
function N:Lay(list)
	local f = self.frame
	local width = NEWS_W - NEWS_LEFT - NEWS_RIGHT
	f.head:SetText(L["Curator has been updated"])
	f.head:ClearAllPoints()
	f.head:SetPoint("TOPLEFT", 70, -36)
	f.head:SetWidth(NEWS_W - 70 - NEWS_RIGHT)
	local y = math.max(76, 36 + (f.head:GetStringHeight() or 18) + 20)
	local hi, li = 0, 0
	for _, e in ipairs(list) do
		hi = hi + 1
		local h = f.heads[hi]
		if not h then
			h = S.Text(f, "GameFontNormal", "LEFT")
			CuratorOctoFull.SetWordWrap(h, true)
			f.heads[hi] = h
		end
		h:SetText(string.format(L["What is new in Curator %s"], e.v))
		h:ClearAllPoints()
		h:SetPoint("TOPLEFT", NEWS_LEFT, -y)
		h:SetWidth(width)
		h:Show()
		y = y + (h:GetStringHeight() or 14) + 9
		for _, key in ipairs(e.lines) do
			li = li + 1
			local t = f.lines[li]
			if not t then
				t = S.Text(f, "GameFontHighlight", "LEFT")
				CuratorOctoFull.SetWordWrap(t, true)
				t:SetSpacing(2)
				t.gem = f:CreateTexture(nil, "ARTWORK")
				CuratorOctoFull.SetSize(t.gem, 12, 12)
				t.gem:SetTexture(MEDIA .. "Gem5")
				f.lines[li] = t
			end
			t:SetText(L[key])
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", NEWS_LEFT + 20, -y)
			t:SetWidth(width - 20)
			t:Show()
			t.gem:ClearAllPoints()
			t.gem:SetPoint("TOPLEFT", NEWS_LEFT + 1, -(y + 1))
			t.gem:Show()
			y = y + (t:GetStringHeight() or 14) + 8
		end
		y = y + 6
	end
	for i = hi + 1, CuratorOctoFull.Length(f.heads) do
		f.heads[i]:Hide()
	end
	for i = li + 1, CuratorOctoFull.Length(f.lines) do
		f.lines[i]:Hide()
		f.lines[i].gem:Hide()
	end
	f.rule:ClearAllPoints()
	f.rule:SetPoint("TOPLEFT", NEWS_LEFT, -y)
	y = y + 10
	f.foot:SetText(L["/curator news: this window again"])
	f.foot:ClearAllPoints()
	f.foot:SetPoint("TOPLEFT", NEWS_LEFT, -y)
	f.foot:SetWidth(width)
	y = y + (f.foot:GetStringHeight() or 10) + 14
	f.ok:ClearAllPoints()
	f.ok:SetPoint("TOP", f, "TOP", 0, -y)
	return y + 24 + 20
end

-- Shown (list: the news of the versions to tell, the newest first; none: those of this version).
function N:Show(list)
	if type(list) ~= "table" or CuratorOctoFull.Length(list) == 0 then
		list = { self:Current() }
	end
	if not list[1] then
		return
	end
	local f = self:Build()
	local h = self:Lay(list)
	if h > self.MAX_H and CuratorOctoFull.Length(list) > 1 then
		list = { list[1] }
		h = self:Lay(list)
	end
	f:SetHeight(h)
	self.shown = list
	if not f:IsShown() then
		ns.Play(ns.SND.open)
	end
	f:Show()
	f:Raise()
end

function N:Hide()
	local f = self.frame
	if f and f:IsShown() then
		f:Hide()
		ns.Play(ns.SND.close)
	end
end

ns.On("LOGIN", function()
	N:Login()
end)
