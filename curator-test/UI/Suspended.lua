local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.7.0) The window of a suspended Curator: the save was edited outside the game (its seal no
-- longer matches, Core.lua). Nothing works until the collection starts over: the album does not
-- open, nothing is earned, no booster bar, no trade (Beta.lua, B:Over). It comes at the login and
-- whenever something is asked of Curator. Its button empties the whole collection, as /curator reset
-- confirm does, after a second click. (1.9.1) The same window for a player banned for good (Bans.lua),
-- without that button: nothing brings Curator back. (1.14.0) Or banned for a time (the news of the website): until
-- when, and that Curator works again by itself after.
-------------------------------------------------------------------------------
local W = {}
ns.SuspendedWindow = W

local WIDTH, HEIGHT = 470, 280

-- (1.14.0) The end of a ban for a time, as it is shown (the time of the computer); nil: for good.
local function Ends()
	local e = ns.Bans and ns.Bans.ends
	return (type(e) == "number" and e > 0) and date("%d/%m/%Y %H:%M", e) or nil
end

function W:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorSuspended", WIDTH, HEIGHT)
	f:SetPoint("CENTER", 0, 140)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorSuspended")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle(L["Curator suspended"])
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			W:Hide()
		end)
	end
	-- (Escape closes it: the second click is asked again next time)
	f:HookScript("OnHide", function()
		W:Arm(false)
	end)

	-- why, in large letters, then what it means and how to play again
	f.head = S.Text(f, "GameFontNormalLarge", "CENTER")
	f.head:SetPoint("TOPLEFT", 70, -46)
	f.head:SetPoint("TOPRIGHT", -24, -46)
	f.body = S.Text(f, "GameFontHighlight", "LEFT")
	f.body:SetPoint("TOPLEFT", 70, -78)
	f.body:SetPoint("TOPRIGHT", -24, -78)
	f.body:SetSpacing(3)
	CuratorOctoFull.SetWordWrap(f.body, true)
	-- (the website, just above the buttons, whatever the length of the text above it)
	f.site = S.Text(f, "GameFontNormalSmall", "LEFT")
	f.site:SetPoint("BOTTOMLEFT", 70, 54)
	f.site:SetPoint("BOTTOMRIGHT", -24, 54)
	f.site:SetJustifyV("BOTTOM")
	f.site:SetSpacing(2)
	CuratorOctoFull.SetWordWrap(f.site, true)
	f.site:SetTextColor(0.75, 0.75, 0.8)
	-- the alert of the game's dialogs beside it
	f.alert = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.alert, 40, 40)
	f.alert:SetPoint("TOPLEFT", 20, -72)
	f.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")

	-- start over (a second click to be sure), or later
	f.reset = S.Button(f, L["Reset everything"], 200, 24)
	f.reset:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -6, 18)
	CuratorOctoFull.SetScript(f.reset, "OnClick", function()
		if W.armed then
			W:Reset()
		else
			W:Arm(true)
		end
	end)
	f.later = S.Button(f, CLOSE or "Close", 130, 24)
	f.later:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, 18)
	CuratorOctoFull.SetScript(f.later, "OnClick", function()
		if W.armed then
			W:Arm(false)
		else
			W:Hide()
		end
	end)
	self.frame = f
	return f
end

-- The second click asked (on), or not.
function W:Arm(on)
	self.armed = on and true or nil
	local f = self.frame
	if not f then
		return
	end
	f.reset:SetText(on and L["Confirm: erase everything"] or L["Reset everything"])
	f.later:SetText(on and (CANCEL or "Cancel") or (CLOSE or "Close"))
	local label = f.reset:GetFontString()
	if label then
		if on then
			label:SetTextColor(1, 0.35, 0.3)
		else
			label:SetTextColor(1, 0.82, 0)
		end
	end
end

-- Shown (said again when it is already there).
function W:Show()
	local f = self:Build()
	if not f:IsShown() then
		self:Arm(false)
		ns.Play(ns.SND.warning)
	end
	local banned = ns.Beta ~= nil and ns.Beta:Banned()
	f:SetTitle(banned and L["Curator banned"] or L["Curator suspended"])
	f.later:ClearAllPoints()
	local ends = banned and Ends()
	if ends then
		f.head:SetText(string.format(L["Account banned until %s"], ends))
		f.body:SetText(string.format(L["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."], ends))
		f.site:SetText(L["At the end of the ban, Curator works again by itself."])
		f.reset:Hide()
		f.later:SetPoint("BOTTOM", f, "BOTTOM", 0, 18)
	elseif banned then
		f.head:SetText(L["Account banned for cheating"])
		f.body:SetText(L["Your Battle.net account is banned from Curator for cheating. Curator no longer works on this account: no more boosters, no more cards, no more trades."])
		f.site:SetText(L["This ban is final."])
		f.reset:Hide()
		f.later:SetPoint("BOTTOM", f, "BOTTOM", 0, 18)
	else
		f.head:SetText(L["Save edited outside the game"])
		f.body:SetText(L["Curator is suspended: no more boosters, no more cards, no more trades. To play again, start over: your whole collection is reset (cards, boosters, level, achievements)."])
		f.site:SetText(L["If you use the website of Curator, reset your account there too (My account)."])
		f.reset:Show()
		f.later:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, 18)
	end
	f:Show()
	f:Raise()
end

function W:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

-- Said: in its window, each time something is asked of Curator, and in the chat (once a minute at
-- most).
function W:Tell()
	local now = (GetTime and GetTime()) or 0
	if not self.told or now - self.told >= 60 then
		self.told = now
		if ns.Beta and ns.Beta:Banned() then
			local ends = Ends()
			ns.Print(ends and string.format(L["Curator is blocked: your Battle.net account is banned until %s."], ends)
				or L["Curator is blocked: your Battle.net account is banned for cheating."])
		else
			ns.Print(L["Curator is suspended: your save was edited outside the game. To play again, reset everything (/curator reset confirm)."])
		end
	end
	self:Show()
end

-- The collection emptied: Curator works again (Core.lua, ns.ResetCollection).
function W:Reset()
	self:Arm(false)
	if ns.Beta and ns.Beta:Suspended() then
		ns.ResetCollection()
	end
	self:Hide()
end

ns.On("UNSUSPENDED", function()
	W:Hide()
end)

-- At the login, once the game has settled (and Battle.net with it: a ban is known by the BattleTag).
ns.On("LOGIN", function()
	if ns.Beta then
		ns.Delay(4, function()
			if ns.Beta:Suspended() or ns.Beta:Banned() then
				W:Tell()
			end
		end, W)
	end
end)
