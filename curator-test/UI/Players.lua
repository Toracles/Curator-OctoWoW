local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

local P = {}
ns.Players = P

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

-- "Name-Realm" of a unit that is another player that can be asked, "me" for myself, else nil.
function P:UnitName(unit)
	if not (unit and UnitIsPlayer and UnitExists and UnitExists(unit)) then
		return nil
	end
	local ok, isPlayer = pcall(UnitIsPlayer, unit)
	if not ok or Secret(isPlayer) or not isPlayer then
		return nil
	end
	if UnitIsUnit and UnitIsUnit(unit, "player") then
		return "me"
	end
	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(unit)
	else
		name, realm = UnitName(unit)
	end
	if not name or Secret(name) or Secret(realm) then
		return nil
	end
	-- (1.13.1: OctoWoW: the surname where the realm was; the game writes the whole name when it does not
	-- give it apart)
	if ns.Guild:Surnames() and (realm == nil or realm == "") and GetUnitName then
		local ok, whole = pcall(GetUnitName, unit, true)
		if ok and type(whole) == "string" and not Secret(whole) and string.find(whole, " ", 1, true) then
			name, realm = whole, nil
		end
	end
	if UnitFactionGroup then
		local mine, theirs = UnitFactionGroup("player"), UnitFactionGroup(unit)
		if Secret(theirs) or (mine and theirs and mine ~= theirs) then
			return nil
		end
	end
	return ns.Guild:Full(name, realm)
end

-- Opening a collection
-------------------------------------------------------------------------------
-- name: "Name-Realm", "Name" (of my realm), or "me".
function P:Show(name)
	if not name or name == "me" or ns.Guild:IsMe(name) then
		return ns.Album:Open("contents")
	end
	ns.Album:ShowPlayer(ns.Guild:Canon(ns.Guild:Full(name)))
end

-- A name typed in a command, as the game writes names: each word with its first letter in capital (1.13.1: on WoW
-- Forever, the first name and the surname), the realm or the surname after a dash as it was typed.
local function Typed(arg)
	local G = ns.Guild
	local name, realm = CuratorOctoFull.Match(arg, "^([^%-]+)%-?(.*)$")
	name = string.gsub(string.gsub((name or arg), "^%s+", ""), "%s+$", "")
	name = string.gsub(name, "%S+", function(w)
		return G.Capital(G.Fold(w))
	end)
	realm = string.gsub((realm or ""), "%s", "")
	return G:Full(name, realm ~= "" and realm or nil)
end

-- The player a command names: the one known by that name (1.13.1: on OctoWoW, a first name alone finds the one
-- player known by it, or the one friend of Battle.net), else the name as typed. nil: on OctoWoW, a first name alone
-- that says nobody for sure (the chat says to type the surname too).
function P:Named(arg)
	local G = ns.Guild
	local known = G:Canon(G:Full(arg), true)
	if not G:Player(known) then
		known = Typed(arg)
	end
	if known and G:Unsure(known) and not (ns.Trade and ns.Trade:BNTarget(known)) then
		ns.Print(L["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."])
		return nil
	end
	return known
end

-- /curator view [name]: a player by their name, else the target, else my own collection.
function P:ShowCommand(arg)
	arg = string.gsub(string.gsub((arg or ""), "^%s+", ""), "%s+$", "")
	if arg ~= "" then
		local name = self:Named(arg)
		if name then
			self:Show(name)
		end
		return
	end
	local target = self:UnitName("target")
	if target then
		return self:Show(target)
	end
	if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
		ns.Print(L["Only the players of your faction can show their collection."])
		return
	end
	return self:Show("me")
end

-- /curator trade [name]: a trade with a player by their name, else the target, else the trades.
function P:TradeCommand(arg)
	arg = string.gsub(string.gsub((arg or ""), "^%s+", ""), "%s+$", "")
	if arg ~= "" then
		local name = self:Named(arg)
		if name then
			ns.Album:StartTrade(name)
		end
		return
	end
	local target = self:UnitName("target")
	if target and target ~= "me" then
		return ns.Album:StartTrade(target)
	end
	return ns.Album:ShowSocial("trades")
end

-- The character a friend of Battle.net plays in this game (any faction, any realm), from the menu of
-- the friends: its name, and its game account (the messages go through Battle.net).
function P:BNName(contextData)
	if type(contextData) ~= "table" or not (C_BattleNet and C_BattleNet.GetAccountInfoByID) then
		return nil
	end
	local id = contextData.bnetIDAccount
	if type(id) ~= "number" or Secret(id) then
		return nil
	end
	local ok, info = pcall(C_BattleNet.GetAccountInfoByID, id)
	local g = ok and type(info) == "table" and not Secret(info) and info.gameAccountInfo
	if not (g and g.isOnline and g.clientProgram == (BNET_CLIENT_WOW or "WoW") and g.characterName and g.characterName ~= "") then
		return nil
	end
	if WOW_PROJECT_ID and g.wowProjectID and g.wowProjectID ~= WOW_PROJECT_ID then
		return nil
	end
	-- (1.13.1: OctoWoW: "First-Surname", no realm in a name, Comm.lua)
	local name = ns.Guild:BNName(g)
	if not name then
		return nil
	end
	local T = ns.Trade
	if T and g.gameAccountID then
		T.bnByName[name], T.nameByBN[g.gameAccountID] = g.gameAccountID, name
	end
	return name
end

-- The name a right click menu is about (a unit, or a name in the chat or a list).
function P:MenuName(contextData)
	if type(contextData) ~= "table" then
		return nil
	end
	-- a player who is offline cannot answer
	local offline = contextData.isOffline
	if UnitPopupSharedUtil and UnitPopupSharedUtil.IsPlayerOffline then
		local ok, off = pcall(UnitPopupSharedUtil.IsPlayerOffline, contextData)
		offline = offline or (ok and off)
	end
	if offline then
		return nil
	end
	if contextData.unit then
		return self:UnitName(contextData.unit)
	end
	local name = contextData.name
	if type(name) ~= "string" or Secret(name) or name == "" then
		return nil
	end
	-- (1.13.1: OctoWoW: the surname of the character after its first name, never a realm: ns.Guild:Full
	-- leaves mine out)
	local G = ns.Guild
	local server = contextData.server or contextData.surname
	if G:Surnames() then
		server = contextData.surname or contextData.server
	end
	if type(server) ~= "string" or Secret(server) then
		server = nil
	end
	local full = G:Full(name, server)
	-- (a first name alone: its surname from the GUID of the character, when the menu gives it and the game knows it)
	local guid = contextData.guid
	if full and G:Surnames() and not string.find(full, "-", 1, true) and GetPlayerInfoByGUID and type(guid) == "string" and not Secret(guid) then
		local ok, _, _, _, _, _, n, r = pcall(GetPlayerInfoByGUID, guid)
		if ok and type(n) == "string" and not Secret(n) and G.Fold(n) == G.Fold(full) and type(r) == "string" and not Secret(r)
			and r ~= "" and not G:IsRealm(r) then
			full = G:Full(n, r) or full
		end
	end
	return full
end

if Menu and Menu.ModifyMenu then
	local function Add(_, root, contextData)
		local name = P:MenuName(contextData)
		if not name then
			return
		end
		root:CreateDivider()
		root:CreateButton(L["Curator collection"], function()
			P:Show(name)
		end)
		-- (another player: a trade)
		if name ~= "me" and not ns.Guild:IsMe(name) then
			root:CreateButton(L["Trade with Curator"], function()
				ns.Album:StartTrade(name)
			end)
			-- (1.8.0: a player around: a duel with a stake)
			if contextData.unit and ns.DuelUI then
				root:CreateButton(L["Duel with a stake"], function()
					ns.DuelUI:Open(name)
				end)
			end
		end
	end
	for _, which in ipairs({ "SELF", "PLAYER", "PARTY", "RAID_PLAYER", "RAID", "FRIEND", "GUILD",
		"COMMUNITIES_GUILD_MEMBER", "COMMUNITIES_WOW_MEMBER", "CHAT_ROSTER", "RECENT_ALLY" }) do
		pcall(Menu.ModifyMenu, "MENU_UNIT_" .. which, Add)
	end
	-- the friends of Battle.net playing this game: their collection, a trade (any faction, any realm)
	pcall(Menu.ModifyMenu, "MENU_UNIT_BN_FRIEND", function(_, root, contextData)
		local name = P:BNName(contextData)
		if not name then
			return
		end
		root:CreateDivider()
		root:CreateButton(L["Curator collection"], function()
			ns.Album:ShowPlayer(name)
		end)
		root:CreateButton(L["Trade with Curator"], function()
			ns.Album:StartTrade(name)
		end)
	end)
end

do
    local entry = "CURATOR_TRADE"
    local portraitMenus = { PLAYER = true, PARTY = true, RAID = true }

    local function label()
        return ns.locale == "frFR" and "Échange (Curator)" or "Trade (Curator)"
    end

    local function activeMenu()
        local menu = UIDROPDOWNMENU_INIT_MENU or UIDROPDOWNMENU_OPEN_MENU
        if type(menu) == "string" then return _G[menu] end
        return menu
    end

    local function menuTarget(menu)
        if not (menu and portraitMenus[menu.which]) then return end
        local name = P:UnitName(menu.unit)
        if name and name ~= "me" and not ns.Guild:IsMe(name) then return name end
    end

    ns.On("LOGIN", function()
        if Menu and Menu.ModifyMenu then return end
        if not (UnitPopupButtons and UnitPopupMenus and UnitPopupShown and UnitPopup_HideButtons and UnitPopup_OnClick) then
            return
        end
        if UnitPopupButtons[entry] then return end

        local option = { text = label(), dist = 0, color = { r = 0, g = 0.67, b = 1 } }
        UnitPopupButtons[entry] = option
        for which in pairs(portraitMenus) do
            local items = UnitPopupMenus[which]
            if items then
                local position = table.getn(items) + 1
                for index, value in ipairs(items) do
                    if value == "TRADE" then
                        position = index + 1
                        break
                    elseif value == "CANCEL" then
                        position = index
                        break
                    end
                end
                table.insert(items, position, entry)
            end
        end

        local hideButtons = UnitPopup_HideButtons
        UnitPopup_HideButtons = function()
            hideButtons()
            local menu = activeMenu()
            local shown = UnitPopupShown
            local level = shown[UIDROPDOWNMENU_MENU_LEVEL or 1]
            if type(level) == "table" then shown = level end
            if not (menu and portraitMenus[menu.which] and shown) then return end
            local name = menuTarget(menu)
            menu.curatorTradeTarget = name
            option.text = label()
            for index, value in ipairs(UnitPopupMenus[menu.which]) do
                if value == entry then
                    shown[index] = name and 1 or 0
                    break
                end
            end
        end

        local click = UnitPopup_OnClick
        UnitPopup_OnClick = function(...)
            if not (this and this.value == entry) then
                return click(unpack(arg, 1, arg.n))
            end
            local menu = activeMenu()
            local name = menuTarget(menu)
            -- A portrait can change units while its menu is still open.
            if name and name == menu.curatorTradeTarget then
                ns.LiveTradeUI:Invite(name)
            end
        end
    end)
end
