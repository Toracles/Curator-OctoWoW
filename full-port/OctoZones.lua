-- Zone text fallback for stock Vanilla and for zones whose map ID differs from Forever.
local ns = CuratorOctoFull
local rewards = ns.Rewards
local originalZoneSeries = rewards.ZoneSeries

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

function rewards:ZoneSeries()
    local instance, kind
    if GetInstanceInfo then instance, kind = GetInstanceInfo() end
    if kind == "pvp" or kind == "arena" then return end
    local dungeon = find(instance, true) or find(GetRealZoneText(), true) or find(GetZoneText(), true)
    if dungeon then return dungeon end
    local existing = originalZoneSeries(self)
    if existing or kind == "party" or kind == "raid" then return existing end
    return find(GetRealZoneText(), false) or find(GetZoneText(), false)
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
        if character.octoPlaces[place] then return end
        character.octoPlaces[place] = true
        local series = rewards:WorldSeries()
        rewards:Add(series, rewards.POINTS.explore, "explore")
        ns.Fire("ACTIVITY", "explore", 1)
        if ns.Talents then ns.Talents:Explored(series) end
    end
end)
