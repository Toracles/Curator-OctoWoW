-- Zone text fallback for stock Vanilla and for zones whose map ID differs from Forever.
local ns = CuratorOctoFull
local rewards = ns.Rewards
local originalInstanceSeries = rewards.InstanceSeries

local function zoneKey(name)
    return string.lower(string.gsub(name or "", "^%s*(.-)%s*$", "%1"))
end

local function find(name, dungeon)
    local key = zoneKey(name)
    if key == "" then return end
    if key == "the stormwind vault" then key = "stormwind vault" end
    for _, series in ipairs(ns.Series) do
        local kind = series.kind == "dungeon"
        if kind == dungeon and (zoneKey(series.name) == key or
                zoneKey(series.title and series.title[GetLocale()]) == key) then
            return series
        end
    end
end

local areasByName = {}
for id, name in pairs(ns.OctoAreaNames or {}) do
    local key = zoneKey(name)
    if not areasByName[key] then areasByName[key] = id end
end

local function byArea(id, dungeon)
    local parents = ns.OctoAreaParents or {}
    for _ = 1, 8 do
        if not id then return end
        for _, series in ipairs(ns.Series) do
            if series.area == id and (series.kind == "dungeon") == dungeon then
                return series
            end
        end
        id = parents[id]
    end
end

function rewards:InstanceSeries()
    if GetInstanceInfo then
        local name, kind, _, _, _, _, _, id = GetInstanceInfo()
        if kind == "pvp" or kind == "arena" then return end
        if kind == "party" or kind == "raid" then
            local match = find(name, true) or byArea(id, true)
            if match then return match end
        end
    end
    return find(GetRealZoneText(), true) or find(GetZoneText(), true) or originalInstanceSeries(self)
end

function rewards:ZoneSeries()
    local dungeon = self:InstanceSeries()
    if dungeon then return dungeon end
    if IsInInstance and IsInInstance() then return end
    local real, zone = GetRealZoneText(), GetZoneText()
    local match = find(real, false) or find(zone, false)
        or byArea(areasByName[zoneKey(real)], false) or byArea(areasByName[zoneKey(zone)], false)
    if match then return match end
    if C_Map and C_Map.GetBestMapForUnit then
        return byArea(C_Map.GetBestMapForUnit("player"), false)
    end
end

local function levelCredits(character)
    character.octoLevelCredits = character.octoLevelCredits or {}
    return character.octoLevelCredits
end

-- Track live credit separately from the level saved when logging in.
function rewards:OctoLevelUp(level)
    local series = self:WorldSeries()
    if not series or type(level) ~= "number" or level < 2 then return end
    if ns.Guard and not ns.Guard:Allow(series) then return end
    local character = self:Char()
    local credits = levelCredits(character)
    if credits[level] or level <= (character.octoLevelFloor or 1) then return end
    credits[level] = true
    self:Add(series, self.POINTS.level, "level")
end

local function exploredPlaceName(area)
    local name
    if C_Map and C_Map.GetAreaInfo then
        local ok, value = pcall(C_Map.GetAreaInfo, area)
        if ok then name = value end
        if type(name) == "table" then name = name.name end
    end
    if type(name) ~= "string" or name == "" then
        name = ns.OctoAreaNames and ns.OctoAreaNames[area]
    end
    return name
end

local function importPlaces(reward, character)
    local api = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures
    if not api then return nil end
    character.octoPlaces = character.octoPlaces or {}
    character.octoExploredAreas = character.octoExploredAreas or {}
    local known, count, scanned = {}, 0, false
    for name in pairs(character.octoPlaces) do known[zoneKey(name)] = true end
    for _, series in ipairs(ns.Series) do
        if series.kind == "zone" and series.area then
            local ok, overlays = pcall(api, series.area)
            if ok and type(overlays) == "table" then
                scanned = true
                local worked = 0
                for _, overlay in ipairs(overlays) do
                    local area = overlay.areaID
                    -- A multi-area overlay can become visible after only one of its areas is explored.
                    if area and (not overlay.areaIDs or table.getn(overlay.areaIDs) == 1) then
                        local name = exploredPlaceName(area)
                        local key = zoneKey(name)
                        local alias = ns.OctoAreaNames and ns.OctoAreaNames[area]
                        if key ~= "" and not known[key] and not known[zoneKey(alias)] and not character.octoExploredAreas[area] then
                            character.octoExploredAreas[area] = true
                            character.octoPlaces[name] = true
                            known[key] = true
                            if alias then
                                character.octoPlaces[alias] = true
                                known[zoneKey(alias)] = true
                            end
                            worked = worked + 1
                        end
                    end
                end
                if worked > 0 then
                    if not reward:Visited(series) then
                        ns.db.visited[series.key] = true
                        ns.Fire("VISITED", series)
                    end
                    reward:Add(series, worked * reward.POINTS.explore, "catchup")
                    count = count + worked
                end
            end
        end
    end
    if scanned then return count end
end

function rewards:CatchUp(argument)
    if not ns.db or (ns.Beta and ns.Beta:Over()) or (ns.Guard and not ns.Guard:AllowAll(true)) then return end
    argument = argument or ""
    local fr = ns.locale == "frFR"
    if ns.Reroll and ns.Reroll:IsReroll() then
        ns.Print(fr and "Le rattrapage est disponible sur un personnage hors défi de reroll." or "Catch-up is available outside the reroll challenge.")
        return
    end
    local level = UnitLevel("player")
    if type(level) ~= "number" or level < 1 then return end
    local character = self:Char()
    local floor = tonumber(argument)
    if argument == "" then floor = character.octoLevelFloor or 1 end
    if not floor or floor < 1 or floor > level or floor ~= math.floor(floor) then
        ns.Print(fr and "Utilisation : /curator rattrapage [dernier niveau déjà crédité]" or "Usage: /curator catchup [last level already credited]")
        return
    end
    character.octoLevelFloor = math.max(character.octoLevelFloor or 1, floor)
    local credits, levels = levelCredits(character), 0
    for reached = character.octoLevelFloor + 1, level do
        if not credits[reached] then
            credits[reached] = true
            levels = levels + 1
        end
    end
    if levels > 0 then
        -- The old level events have no zone. Full bars grant a booster choice.
        self:Fill(nil, levels * self.POINTS.level, "catchup", false, true)
    end
    local places = importPlaces(self, character)
    ns.Print(string.format(fr and "Rattrapage : %d niveaux, %d lieux crédités." or "Catch-up: %d levels and %d discoveries credited.", levels, places or 0))
    if not places then
        ns.Print(fr and "La lecture des zones explorées nécessite une version de ClassicAPI qui expose ces données." or "Reading explored areas requires a version of ClassicAPI that exposes them.")
    end
    ns.Fire("CHANGED")
end

local function chatPattern(format)
    if not format then return end
    format = string.gsub(format, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    format = string.gsub(format, "%%%%%d+%%$s", "(.-)")
    format = string.gsub(format, "%%%%%d+%%$d", "%%d+")
    format = string.gsub(format, "%%%%s", "(.-)")
    format = string.gsub(format, "%%%%d", "%%d+")
    return "^" .. format .. "$"
end

local questPattern = chatPattern(ERR_QUEST_COMPLETE_S or "%s completed.")
local explorePattern = chatPattern(ERR_ZONE_EXPLORED)
local exploreWithXP = chatPattern(ERR_ZONE_EXPLORED_XP)
local function capture(message, pattern)
    if not pattern then return end
    local _, _, value = string.find(message, pattern)
    return value
end

-- Native messages carry text on 1.12, while newer clients use IDs.
local messages = CreateFrame("Frame")
messages:RegisterEvent("CHAT_MSG_SYSTEM")
messages:RegisterEvent("UI_INFO_MESSAGE")
messages:SetScript("OnEvent", function()
    if not ns.db or type(arg1) ~= "string" then return end
    local message = arg1
    local character = rewards:Char()
    local quest = capture(message, questPattern)
    if quest and (not C_QuestLog or not C_QuestLog.GetQuestIDForLogIndex) then
        character.octoQuests = character.octoQuests or {}
        if character.octoQuests[quest] then return end
        character.octoQuests[quest] = true
        local series = rewards:WorldSeries()
        local points = rewards.POINTS.quest
        if ns.Talents then points = ns.Talents:QuestPoints(points, series) end
        rewards:Add(series, points, "quest")
        ns.Fire("ACTIVITY", "quest", 1)
        return
    end
    local place = capture(message, exploreWithXP) or capture(message, explorePattern)
    if place and rewards:WorldSeries() then
        character.octoPlaces = character.octoPlaces or {}
        local key = zoneKey(place)
        for name in pairs(character.octoPlaces) do
            if zoneKey(name) == key then return end
        end
        character.octoPlaces[place] = true
        local series = rewards:WorldSeries()
        rewards:Add(series, rewards.POINTS.explore, "explore")
        ns.Fire("ACTIVITY", "explore", 1)
        if ns.Talents then ns.Talents:Explored(series) end
    end
end)
