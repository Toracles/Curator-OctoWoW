local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.8.0) Curator in the window of the NPCs the collector talks to (the window of dialogue of the game,
-- GossipFrame): the innkeepers (Inns.lua) and the battlemasters (Pvp.lua) get lines of Curator under
-- their own options, drawn as theirs (the lines of the game's list, ScrollBox and DataProvider: Curator
-- adds its own after each build of the list, and its own clicks on them). A line: { text, icon, click }.
-- What a line does may answer with a line of the NPC (Say): it goes under the greeting of the window.
-- A window of dialogue replaced by another addon: the lines come in a small window of their own,
-- beside it.
-------------------------------------------------------------------------------
local G = { providers = {}, lines = {} }
ns.Gossip = G

-- the icons of the options the game shows: the inn (the hearthstone bound there), the battlemaster
G.ICONS = {
	inn = { [132052] = true, [4955461] = true },
	battle = { [132051] = true },
}
G.ICON = MEDIA .. "Icon"

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

-- What gives the lines of an NPC of a role: fn(npc, name) -> { { text, icon, click }, ... }.
function G:Provide(role, fn)
	self.providers[role] = self.providers[role] or {}
	CuratorOctoFull.Insert(self.providers[role], fn)
end

-- The id of the NPC the player talks to (nil: not one, or the game does not say).
function G:NpcId()
	if UnitCreatureID then
		local ok, id = pcall(UnitCreatureID, "npc")
		if ok and type(id) == "number" and not Secret(id) and id > 0 then
			return id
		end
	end
	if UnitGUID then
		local ok, guid = pcall(UnitGUID, "npc")
		if ok and type(guid) == "string" and not Secret(guid) then
			local kind, _, _, _, _, id = strsplit("-", guid)
			if kind == "Creature" then
				return tonumber(id)
			end
		end
	end
end

-- The options of the window now (C_GossipInfo.GetOptions), {} when the game gives none.
function G:Options()
	if C_GossipInfo and C_GossipInfo.GetOptions then
		local ok, list = pcall(C_GossipInfo.GetOptions)
		if ok and type(list) == "table" then
			return list
		end
	end
	return {}
end

-- What the NPC is for Curator: "inn" (an innkeeper), "battle" (a battlemaster), "leader" (1.10.0: a leader
-- who gives the golden quests), "warlock", "priest" (1.12.0: their masters, Seal.lua), "enchanter" (1.13.0: he
-- restores the copies, Restore.lua), nil.
function G:Role(npc, options)
	if ns.Golden and ns.Golden:LeaderByNpc(npc) then
		return "leader"
	end
	-- (1.12.0: a Master of Warlocks, a Master of Priests: the corrupted cards, Seal.lua)
	local master = ns.Masters and ns.Masters:Role(npc)
	if master then
		return master
	end
	-- (1.13.0: an enchanter, who restores the copies of the cards: Restore.lua)
	if ns.Restore and ns.Restore:IsEnchanter(npc) then
		return "enchanter"
	end
	if ns.Inns and ns.Inns:IsInnkeeper(npc, options) then
		return "inn"
	end
	if ns.BATTLEMASTERS and npc and ns.BATTLEMASTERS[npc] then
		return "battle"
	end
	for _, o in ipairs(options or {}) do
		local icon = type(o) == "table" and (o.overrideIconID or o.icon) or nil
		if icon and not Secret(icon) and self.ICONS.battle[icon] then
			return "battle"
		end
	end
	return nil
end

-- The lines of Curator for the NPC talked to now.
function G:Lines()
	local out = {}
	if ns.Beta and ns.Beta:Over() then
		return out
	end
	for _, fn in ipairs(self.providers[self.role or ""] or {}) do
		local ok, lines = pcall(fn, self.npc, self.name)
		if ok and type(lines) == "table" then
			for _, line in ipairs(lines) do
				out[CuratorOctoFull.Length(out) + 1] = line
			end
		elseif not ok then
			geterrorhandler()(lines)
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- The window of dialogue opens, closes
-------------------------------------------------------------------------------
-- The NPC talked to, known (once a dialogue: at the first build of its list or at its event, whichever
-- comes first).
function G:Begin()
	if self.open then
		return
	end
	local npc = self:NpcId()
	local options = self:Options()
	self.open, self.injected = true, false
	self.npc, self.role, self.say = npc, self:Role(npc, options), nil
	self.name = nil
	if UnitName then
		local ok, name = pcall(UnitName, "npc")
		if ok and type(name) == "string" and not Secret(name) then
			self.name = name
		end
	end
	if self.role then
		ns.Fire("NPC_TALK", self.role, npc, self.name)
	end
end

function G:Open()
	self:Begin()
	-- (the list of the game built before the NPC was known: built again, with Curator's lines)
	if self.role and not self.injected then
		self:Refresh()
	else
		self:Fallback()
	end
end

function G:Close()
	self.open, self.injected = false, false
	self.npc, self.role, self.say, self.name = nil, nil, nil, nil
	if self.panel then
		self.panel:Hide()
	end
	ns.Fire("NPC_LEFT")
end

-- The lines again (what they say changed): the list of the window built again.
function G:Refresh()
	local f = rawget(_G, "GossipFrame")
	if f and f.IsShown and f:IsShown() and self.hooked and f.Update then
		local ok, err = pcall(f.Update, f)
		if not ok then
			geterrorhandler()(err)
		end
	end
	self:Fallback()
end

-- A line of the NPC, under the greeting of its window (an answer to a line of Curator).
function G:Say(text)
	self.say = text
	self:Refresh()
end

-------------------------------------------------------------------------------
-- The lines in the list of the window of the game
-------------------------------------------------------------------------------
-- (the button of the game measured for a line of several rows, as the game measures its own)
local measure

local function Info(line, i)
	return {
		name = line.text, icon = line.icon or G.ICON, flags = 0, status = 0, rewards = {},
		orderIndex = 1000 + i, selectOptionWhenOnlyOption = false,
	}
end

-- The list just built (GossipFrame:Update): Curator's lines after the NPC's options, its answer under the
-- greeting.
function G:Inject(frame)
	local box = frame.GreetingPanel and frame.GreetingPanel.ScrollBox
	local dp = box and box.GetDataProvider and box:GetDataProvider()
	self:Begin()
	if not self.role then
		return
	end
	-- (1.14.0) The NPC known just now: what that set off may have said something at once (the round of an innkeeper), the
	-- list built again with it, Curator's lines in it. That list is the one shown: this one is no longer there.
	if box and box.GetDataProvider and box:GetDataProvider() ~= dp then
		return
	end
	if not (dp and dp.Insert) then
		return
	end
	self.injected = true
	if self.say and dp.Find and dp.ReplaceAtIndex then
		local first = dp:Find(1)
		if type(first) == "table" and first.buttonType == GOSSIP_BUTTON_TYPE_TITLE then
			dp:ReplaceAtIndex(1, {
				buttonType = GOSSIP_BUTTON_TYPE_TITLE, greetingTextFrame = first.greetingTextFrame,
				text = (first.text or "") .. "\n\n" .. self.say,
			})
		end
	end
	local lines = self:Lines()
	if CuratorOctoFull.Length(lines) == 0 then
		return
	end
	if not measure and CreateFrame then
		local ok, b = pcall(CreateFrame, "Button", nil, frame, "GossipTitleOptionButtonTemplate")
		if ok and b then
			b:Hide()
			measure = b
		end
	end
	dp:Insert({ buttonType = GOSSIP_BUTTON_TYPE_DIVIDER })
	for i, line in ipairs(lines) do
		dp:Insert({ buttonType = GOSSIP_BUTTON_TYPE_OPTION, info = Info(line, i), titleOptionButton = measure, curator = line })
	end
end

-- A button of the list shows a line of Curator: its click is Curator's (and the game's again when the
-- button shows one of the NPC's options).
local function Initialized(_, button, data)
	if type(data) == "table" and data.curator then
		if not button.curatorOwn then
			button.curatorOwn = button:GetScript("OnClick") or false
		end
		local line = data.curator
		CuratorOctoFull.SetScript(button, "OnClick", function()
			G:Click(line)
		end)
		button.curatorLine = line
	elseif button.curatorLine then
		CuratorOctoFull.SetScript(button, "OnClick", button.curatorOwn or nil)
		button.curatorLine = nil
	end
end

local function Released(_, button)
	if button.curatorLine then
		CuratorOctoFull.SetScript(button, "OnClick", button.curatorOwn or nil)
		button.curatorLine = nil
	end
end

function G:Click(line)
	if ns.Play then
		ns.Play(ns.SND.click)
	end
	if line and line.click then
		local ok, err = pcall(line.click, self.npc, self.name)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

-- Curator into the window of the game (once, at login).
function G:Hook()
	if self.hooked then
		return true
	end
	local f = rawget(_G, "GossipFrame")
	local box = f and f.GreetingPanel and f.GreetingPanel.ScrollBox
	if not (f and f.Update and box and hooksecurefunc and ScrollUtil and ScrollUtil.AddInitializedFrameCallback
		and GOSSIP_BUTTON_TYPE_OPTION and GOSSIP_BUTTON_TYPE_DIVIDER and GOSSIP_BUTTON_TYPE_TITLE) then
		return false
	end
	hooksecurefunc(f, "Update", function(frame)
		local ok, err = pcall(G.Inject, G, frame)
		if not ok then
			geterrorhandler()(err)
		end
	end)
	ScrollUtil.AddInitializedFrameCallback(box, Initialized, G)
	if ScrollUtil.AddReleasedFrameCallback then
		ScrollUtil.AddReleasedFrameCallback(box, Released, G)
	end
	self.hooked = true
	return true
end

-------------------------------------------------------------------------------
-- A window of dialogue the game does not show (another addon shows its own): the lines in a small
-- window of Curator.
-- (1.14.3, the players' word, many of them: "Dialogue UI compatibility") Dialogue UI (and Immersion) show their own
-- window and hide the whole interface of the game while the NPC talks (SetUIVisibility): this small window is none of
-- it (no parent, the scale of the interface), beside theirs; a click on a line of Curator brings the interface back
-- first, so that what it opens is seen (out of a fight), the NPC still talked to.
-------------------------------------------------------------------------------
local ROW = 22
-- the windows of dialogue of the other addons this one goes beside (the first one shown)
G.OTHERS = { "DUIQuestFrame", "ImmersionFrame" }

-- The window of another addon shown for this NPC (nil: none).
function G:Other()
	for _, name in ipairs(self.OTHERS) do
		local w = rawget(_G, name)
		if type(w) == "table" and w.IsShown and w:IsShown() then
			return w
		end
	end
	return nil
end

-- The interface of the game hidden by another addon while the NPC talks: shown again, out of a fight.
function G:ShowInterface()
	local ui = rawget(_G, "UIParent")
	if not (ui and ui.IsShown) or ui:IsShown() then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if SetUIVisibility then
		pcall(SetUIVisibility, true)
	end
end

function G:Fallback()
	local f = rawget(_G, "GossipFrame")
	local shown = f and f.IsShown and f:IsShown() and self.hooked
	local lines = (not shown) and self.role and self:Lines() or {}
	if CuratorOctoFull.Length(lines) == 0 then
		if self.panel then
			self.panel:Hide()
		end
		return
	end
	local p = self.panel
	if not p then
		-- (1.14.3: no parent, so that it stays when another addon hides the interface; its scale set as it shows)
		p = CreateFrame("Frame", "CuratorGossip", nil, CuratorOctoFull.BackdropTemplate())
		p:SetFrameStrata("DIALOG")
		p:SetWidth(300)
		CuratorOctoFull.SetClampedToScreen(p, true)
		if p.SetBackdrop then
			p:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 32, edgeSize = 24,
				insets = { left = 6, right = 6, top = 6, bottom = 6 },
			})
		end
		p.title = p:CreateFontString(nil, "OVERLAY")
		ns.SetFont(p.title, 13, "")
		p.title:SetPoint("TOPLEFT", 16, -14)
		p.title:SetPoint("RIGHT", -16, 0)
		p.title:SetJustifyH("LEFT")
		p.title:SetTextColor(1, 0.82, 0)
		p.say = p:CreateFontString(nil, "OVERLAY")
		ns.SetFont(p.say, 12, "")
		p.say:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -6)
		p.say:SetPoint("RIGHT", -16, 0)
		p.say:SetJustifyH("LEFT")
		p.say:SetTextColor(0.95, 0.9, 0.78)
		p.rows = {}
		self.panel = p
	end
	p.title:SetText(self.name or "Curator")
	p.say:SetText(self.say or "")
	local top = 14 + 18 + (self.say and (CuratorOctoFull.GetStringHeight(p.say) + 8) or 0)
	for i, line in ipairs(lines) do
		local i, line = i, line; local r = p.rows[i]
		if not r then
			r = CreateFrame("Button", nil, p)
			r:SetHeight(ROW)
			r.icon = r:CreateTexture(nil, "ARTWORK")
			CuratorOctoFull.SetSize(r.icon, 16, 16)
			r.icon:SetPoint("LEFT", 0, 0)
			r.text = r:CreateFontString(nil, "OVERLAY")
			ns.SetFont(r.text, 12, "")
			r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
			r.text:SetPoint("RIGHT")
			r.text:SetJustifyH("LEFT")
			r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			p.rows[i] = r
		end
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 16, -top - (i - 1) * ROW)
		r:SetPoint("RIGHT", -16, 0)
		r.icon:SetTexture(line.icon or self.ICON)
		r.text:SetText(line.text)
		r.text:SetTextColor(1, 1, 1)
		CuratorOctoFull.SetScript(r, "OnClick", function()
			-- (1.14.3: the interface back first, what the line opens seen: G:ShowInterface)
			G:ShowInterface()
			G:Click(line)
		end)
		r:Show()
	end
	for i = CuratorOctoFull.Length(lines) + 1, CuratorOctoFull.Length(p.rows) do
		p.rows[i]:Hide()
	end
	p:SetHeight(top + CuratorOctoFull.Length(lines) * ROW + 16)
	-- (1.14.3) the scale of the interface; beside the window of another addon (Dialogue UI: on its left), else where it was
	local ui = rawget(_G, "UIParent")
	if ui and ui.GetEffectiveScale then
		p:SetScale(ui:GetEffectiveScale())
	end
	p:ClearAllPoints()
	local other = self:Other()
	if other then
		-- (on its side toward the middle of the screen: Dialogue UI puts its own on the right, or on the left)
		local ox = other.GetCenter and other:GetCenter()
		local mid = ui and ui.GetWidth and ui:GetWidth() * ui:GetEffectiveScale() / 2
		if ox and mid and ox * other:GetEffectiveScale() < mid then
			p:SetPoint("TOPLEFT", other, "TOPRIGHT", 12, 0)
		else
			p:SetPoint("TOPRIGHT", other, "TOPLEFT", -12, 0)
		end
	elseif ui then
		p:SetPoint("LEFT", ui, "LEFT", 380, 80)
	else
		p:SetPoint("LEFT", 380, 80)
	end
	p:Show()
	p:Raise()
	-- (the window of the other addon may come just after this one, on the same event: placed beside it then)
	if not other and CuratorOctoFull.Timer and CuratorOctoFull.Timer.After then
		CuratorOctoFull.Timer.After(0.2, function()
			if G.open and G.panel and G.panel:IsShown() and G:Other() then
				G:Fallback()
			end
		end)
	end
end

-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		G:Hook()
		for _, e in ipairs({ "GOSSIP_SHOW", "GOSSIP_CLOSED" }) do
			pcall(self.RegisterEvent, self, e)
		end
	elseif event == "GOSSIP_SHOW" then
		-- (the window of the game builds its list on this event too: Curator's lines come in its build,
		-- or in a build of their own once the NPC is known)
		G:Open()
	elseif event == "GOSSIP_CLOSED" then
		G:Close()
	end
end)
