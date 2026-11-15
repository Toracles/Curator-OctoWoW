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

local creditFields = { "octoLevelCredits", "octoPlaces", "octoExploredAreas" }

-- The collection and the separate character save each carry a copy of the receipts.
-- Merge the alpha.15 data and keep receipts if either save is restored or reset.
local function creditState(character)
    if type(CuratorOctoCatchUpDB) ~= "table" then CuratorOctoCatchUpDB = {} end
    local state = CuratorOctoCatchUpDB
    for _, field in ipairs(creditFields) do
        local saved, previous = state[field], character[field]
        if type(saved) ~= "table" then saved = {} end
        if type(previous) == "table" and previous ~= saved then
            for key, credited in pairs(previous) do
                if credited == true then saved[key] = true end
            end
        end
        state[field], character[field] = saved, saved
    end
    local floor = math.max(tonumber(state.octoLevelFloor) or 1, tonumber(character.octoLevelFloor) or 1)
    state.octoLevelFloor, character.octoLevelFloor = floor, floor
    local decided = state.octoCatchUpDecided or character.octoCatchUpDecided
    state.octoCatchUpDecided, character.octoCatchUpDecided = decided, decided
    return state
end

ns.On("LOGIN", function()
    if ns.db then creditState(rewards:Char()) end
end)

-- Track live credit separately from the level saved when logging in.
function rewards:OctoLevelUp(level)
    local series = self:WorldSeries()
    if not series or type(level) ~= "number" or level < 2 then return end
    if ns.Guard and not ns.Guard:Allow(series) then return end
    if ns.Beta and ns.Beta:Over() then return end
    local state = creditState(self:Char())
    local credits = state.octoLevelCredits
    if credits[level] or level <= state.octoLevelFloor then return end
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

local function scanPlaces(state)
    local api = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures
    if not api then return {}, 0, false end
    local known, seen, groups, count, scanned = {}, {}, {}, 0, false
    for name in pairs(state.octoPlaces) do known[zoneKey(name)] = true end
    for _, series in ipairs(ns.Series) do
        if series.kind == "zone" and series.area and (not ns.Guard or ns.Guard:Allow(series)) then
            local ok, overlays = pcall(api, series.area)
            if ok and type(overlays) == "table" then
                scanned = true
                local places = {}
                for _, overlay in ipairs(overlays) do
                    local area = overlay.areaID
                    -- A multi-area overlay can become visible after only one of its areas is explored.
                    if area and (not overlay.areaIDs or table.getn(overlay.areaIDs) == 1) then
                        local name = exploredPlaceName(area)
                        local key = zoneKey(name)
                        local alias = ns.OctoAreaNames and ns.OctoAreaNames[area]
                        if key ~= "" and not known[key] and not known[zoneKey(alias)]
                            and not state.octoExploredAreas[area] and not seen[area] then
                            seen[area] = true
                            known[key] = true
                            if alias then known[zoneKey(alias)] = true end
                            table.insert(places, { area = area, name = name, alias = alias })
                        end
                    end
                end
                if table.getn(places) > 0 then
                    table.insert(groups, { series = series, places = places })
                    count = count + table.getn(places)
                end
            end
        end
    end
    return groups, count, scanned
end

function rewards:PlanCatchUp(argument)
    if not ns.db or (ns.Beta and ns.Beta:Over()) then return end
    argument = argument or ""
    if ns.Reroll and ns.Reroll:IsReroll() then return nil, "reroll" end
    local level = UnitLevel("player")
    if type(level) ~= "number" or level < 1 then return end
    local character = self:Char()
    local state = creditState(character)
    local floor = tonumber(argument)
    if argument == "" then floor = state.octoLevelFloor end
    if not floor or floor < 1 or floor > level or floor ~= math.floor(floor) then
        return nil, "usage"
    end
    floor = math.max(state.octoLevelFloor, floor)
    local levels = {}
    for reached = floor + 1, level do
        if not state.octoLevelCredits[reached] then table.insert(levels, reached) end
    end
    local groups, places, scanned = scanPlaces(state)
    local levelPoints = table.getn(levels) * self.POINTS.level
    local entryBar = self:Bar("world", true)
    local bar = entryBar + levelPoints
    local offers = math.floor(bar / ns.PACK_POINTS)
    bar = ns.Mod(bar, ns.PACK_POINTS)
    local packs = math.floor((bar + places * self.POINTS.explore) / ns.PACK_POINTS)
    local signature = { tostring(floor), tostring(entryBar), table.concat(levels, ",") }
    for _, group in ipairs(groups) do
        for _, place in ipairs(group.places) do table.insert(signature, tostring(place.area)) end
    end
    return { floor = floor, levels = levels, places = places, groups = groups, scanned = scanned, decided = state.octoCatchUpDecided,
        offers = offers, packs = packs, points = levelPoints + places * self.POINTS.explore,
        bar = ns.Mod(bar + places * self.POINTS.explore, ns.PACK_POINTS), signature = table.concat(signature, ":") }
end

function rewards:ApplyCatchUp(plan, accepted)
    if not ns.db or (ns.Beta and ns.Beta:Over()) or (ns.Guard and not ns.Guard:AllowAll(true)) then return false end
    local character = self:Char()
    local state = creditState(character)
    state.octoLevelFloor, character.octoLevelFloor = plan.floor, plan.floor
    state.octoCatchUpDecided, character.octoCatchUpDecided = true, true
    for _, level in ipairs(plan.levels) do state.octoLevelCredits[level] = true end
    if accepted and table.getn(plan.levels) > 0 then
        -- The old level events have no zone. Full bars grant a booster choice.
        self:Fill(nil, table.getn(plan.levels) * self.POINTS.level, "catchup", false, true)
    end
    for _, group in ipairs(plan.groups) do
        for _, place in ipairs(group.places) do
            state.octoExploredAreas[place.area] = true
            state.octoPlaces[place.name] = true
            if place.alias then state.octoPlaces[place.alias] = true end
        end
        local series = group.series
        if accepted then
            if not self:Visited(series) then
                ns.db.visited[series.key] = true
                ns.Fire("VISITED", series)
            end
            self:Add(series, table.getn(group.places) * self.POINTS.explore, "catchup")
        end
    end
    ns.Fire("CHANGED")
    return true
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
    local series = place and rewards:WorldSeries()
    if series and (not ns.Beta or not ns.Beta:Over()) and (not ns.Guard or ns.Guard:Allow(series)) then
        local state = creditState(character)
        local key = zoneKey(place)
        for name in pairs(state.octoPlaces) do
            if zoneKey(name) == key then return end
        end
        state.octoPlaces[place] = true
        rewards:Add(series, rewards.POINTS.explore, "explore")
        ns.Fire("ACTIVITY", "explore", 1)
        if ns.Talents then ns.Talents:Explored(series) end
    end
end)
