local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- The other players: what their collection is shows in their tooltip (their cards, their title of
-- collector, their showcase), and their right click menu (or /curator view) opens it in the album.
-- Players of the other faction cannot be asked (no whispers between the factions).
local P = {}
ns.Players = P

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local MYTHIC_ICON = "|T" .. ns.MEDIA .. "Gem6:12:12:0:0|t"

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

-- The line of the tooltip: their cards, their mythic cards, their points.
function P:Line(i)
	local text = string.format(L["Curator: %d cards · %d points"], i.owned, i.points)
	if (i.rar and i.rar[6] or 0) > 0 then
		text = text .. "  ·  " .. MYTHIC_ICON .. " " .. i.rar[6]
	end
	return text
end

-- My own profile, the same way.
function P:Mine()
	local c = ns.Collection:Census()
	local AC = ns.Achievements
	local earned = AC:Earned()
	local pts = AC:Points(earned)
	local ok, female = pcall(function()
		return UnitSex("player") == 3
	end)
	-- (1.5.0: my title of prestige, when I chose one; 1.6.0: my specialization)
	local title = ns.db.title
	return { owned = c.owned, points = pts, rar = c.rar, test = ns.db.test, edited = ns.db.edited, female = ok and female == true, xp = ns.Level:XP(),
		beta = ns.db.ach and ns.db.ach.beta ~= nil, pioneer = ns.db.ach and ns.db.ach.pioneer ~= nil, title = title, bits = title and AC:Bits(earned) or nil,
		spec = ns.Talents and ns.Talents:Spec() or nil }
end

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- Their title of collector, in the colour of its rank, and their level of collector with the emblem
-- of its rank (when they have one: 0.18 and later; named in full, under the level of the character).
function P:TitleLine(i)
	-- (1.5.0: their title of prestige, when they chose one)
	local title, col = ns.Achievements:TitleOf(i)
	if i.xp then
		local level = ns.Level.Of(i.xp)
		local r, lr = ns.Level.RankOf(level)
		title = title .. "  ·  " .. ns.Level.EmblemText(r, 16) .. " |cff" .. Hex(lr.color) .. L[lr.name] .. "|r  ·  " .. string.format(L["Collector level %d"], level)
	end
	return title, col
end

-- "Showcase: <the three cards>", each in the colour of its rarity.
function P:ShowcaseLine(showcase)
	local names = {}
	for _, v in ipairs(showcase or {}) do
		if v.card then
			names[CuratorOctoFull.Length(names) + 1] = "|cff" .. Hex(ns.RARITY[v.card.rarity].text) .. ns.Collection:Name(v.card) .. "|r"
		elseif v.case and ns.CaseDetail then
			-- (1.14.0, after its second test: a card of a case, in the colour of its rank)
			local r = ns.CrateUI.RANKS[v.case.tier] or ns.CrateUI.RANKS[1]
			names[CuratorOctoFull.Length(names) + 1] = "|cff" .. Hex(r.text or r.color) .. ns.CaseDetail.Name(v.case) .. "|r"
		end
	end
	if CuratorOctoFull.Length(names) == 0 then
		return nil
	end
	return string.format(L["Showcase: %s"], table.concat(names, ", "))
end

-- showcase: the cards of their showcase, when they sent them.
function P:AddLines(tooltip, i, showcase)
	tooltip:AddLine(self:Line(i), 1, 0.84, 0.48)
	local title, c = self:TitleLine(i)
	tooltip:AddLine(title, c[1], c[2], c[3])
	-- (1.6.0: their specialization of the talents)
	local TL = ns.Talents
	if i.spec and TL and TL.SPEC_BY[i.spec] then
		local sp = TL.SPEC_BY[i.spec]
		tooltip:AddLine("|T" .. sp.icon .. ":14:14:0:0:64:64:5:59:5:59|t " .. string.format(L["Specialization: %s"], TL:SpecName(i.spec, i.female)), sp.color[1], sp.color[2], sp.color[3])
	end
	local line = self:ShowcaseLine(showcase)
	if line then
		tooltip:AddLine(line, 0.8, 0.8, 0.8, true)
	end
	self.addedShowcase = line ~= nil
	-- (a tester of the beta: its achievement, among the bits they sent)
	local beta = i.beta
	if beta == nil and i.bits and i.bits ~= "" then
		beta = ns.Achievements:FromBits(i.bits).beta == true
	end
	if beta then
		tooltip:AddLine("|T" .. ns.MEDIA .. "Beta:14:14|t " .. L["Beta tester"], 1, 0.55, 0.25)
	end
	-- (1.8.0: a pioneer, there before OctoWoW came out: its achievement, among the bits they sent)
	local pioneer = i.pioneer
	if pioneer == nil and i.bits and i.bits ~= "" then
		pioneer = ns.Achievements:FromBits(i.bits).pioneer == true
	end
	if pioneer then
		tooltip:AddLine("|T" .. ns.MEDIA .. "Pioneer:14:14|t " .. L["Pioneer"], 0.45, 0.66, 1)
	end
	if i.test then
		tooltip:AddLine(L["Test collection"], 0.95, 0.55, 0.4)
	end
	if i.edited then
		tooltip:AddLine(L["Save edited outside the game"], 0.95, 0.4, 0.35)
	end
end

local function OnUnitTooltip(tooltip)
	if tooltip ~= GameTooltip or not ns.db then
		return
	end
	local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
	if not ok or not unit or Secret(unit) then
		return
	end
	local name = P:UnitName(unit)
	P.shown, P.added = name, false
	if not name then
		return
	end
	if name == "me" then
		P:AddLines(tooltip, P:Mine(), ns.Collection:Showcase())
		P.added = true
		return
	end
	local i, fresh = ns.Guild:Profile(name)
	if i then
		P:AddLines(tooltip, i, ns.Guild:Showcase(name))
		P.added = true
	end
	if not fresh then
		ns.Guild:Ask(name)
	end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
	local unitType = (Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit) or 2
	TooltipDataProcessor.AddTooltipPostCall(unitType, OnUnitTooltip)
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetUnit", OnUnitTooltip)
end

-- The answer comes while their tooltip is still there: its line is added.
local function Showing(name)
	if not GameTooltip:IsShown() then
		return false
	end
	local ok, _, unit = pcall(GameTooltip.GetUnit, GameTooltip)
	return ok and unit and not Secret(unit) and P:UnitName(unit) == name
end

ns.On("PLAYER_INFO", function(name)
	if P.shown ~= name or not Showing(name) then
		return
	end
	if not P.added then
		local i = ns.Guild:Profile(name)
		if i then
			P:AddLines(GameTooltip, i, ns.Guild:Showcase(name))
			P.added = true
			GameTooltip:Show()
		end
	elseif not P.addedShowcase then
		-- (their showcase comes after their profile)
		local line = P:ShowcaseLine(ns.Guild:Showcase(name))
		if line then
			GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true)
			P.addedShowcase = true
			GameTooltip:Show()
		end
	end
end)

-------------------------------------------------------------------------------
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
