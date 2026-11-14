local C = CuratorOcto
local function normalize(name)
    return string.lower(string.gsub(name or "", "^%s*(.-)%s*$", "%1"))
end
local byName = {}
for _, album in ipairs(C.albums) do byName[normalize(album.name)] = album end
byName["the stormwind vault"] = C.byZone[5087]
byName["hauts-plateaux thalassiens"] = C.byZone[5225]
byName["ville de gilneas"] = C.byZone[5208]

function C.CurrentAlbum()
    local real, zone = byName[normalize(GetRealZoneText())], byName[normalize(GetZoneText())]
    if real and real.boss then return real end
    if zone and zone.boss then return zone end
    if C_Map and C_Map.GetBestMapForUnit then
        local mapped = C.byZone[C_Map.GetBestMapForUnit("player")]
        if mapped then return mapped end
    end
    return real or zone
end

local function character()
    local name = UnitName("player") .. "-" .. (GetRealmName() or "")
    local db = C.db.characters[name]
    if not db then
        db = {quests={}, places={}, clears={}}
        C.db.characters[name] = db
    end
    return db
end

local function resetKey()
    local now = time()
    if GetQuestResetTime then
        local remaining = GetQuestResetTime()
        if remaining and remaining > 0 then return math.floor((now + remaining + 1800) / 86400) end
    end
    return math.floor(now / 86400)
end

local function award(album, amount)
    local key = album.boss and "dungeon" or "world"
    local db = C.db
    local day = resetKey()
    if db.day ~= day then db.day, db.daily = day, 0 end
    local points = (db.points[key] or 0) + amount
    while points >= 100 and (not album.boss or db.daily < 5) do
        points = points - 100
        if album.boss then db.daily = db.daily + 1 end
        C.GivePack(album)
        DEFAULT_CHAT_FRAME:AddMessage("Curator : booster de " .. album.name)
    end
    db.points[key] = math.min(points, 99.9)
    if C.Refresh then C.Refresh() end
end

local function template(fmt, capture)
    if not fmt then return end
    local value = string.gsub(fmt, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    value = string.gsub(value, "%%%%%d+%$s", capture)
    value = string.gsub(value, "%%%%%d+%$d", "%%d+")
    value = string.gsub(value, "%%%%s", capture)
    value = string.gsub(value, "%%%%d", "%%d+")
    return "^" .. value
end

local killPattern = template(COMBATLOG_XPGAIN_FIRSTPERSON or "%s dies, you gain %d experience.", "(.+)")
local questPattern = template(ERR_QUEST_COMPLETE_S or "%s completed.", "(.+)")
local explorePattern = template(ERR_ZONE_EXPLORED, "(.+)")
local exploreXPPattern = template(ERR_ZONE_EXPLORED_XP, "(.+)")
local objectiveCounts = {}
local function scanObjectives(album)
    local old, points = objectiveCounts, 0
    objectiveCounts = {}
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, header = GetQuestLogTitle(i)
        if title and not header then
            local state = {}
            objectiveCounts[title] = state
            for j = 1, (GetNumQuestLeaderBoards(i) or 0) do
                local line, _, done = GetQuestLogLeaderBoard(j, i)
                local _, _, count = string.find(line or "", "(%d+)%s*/%s*%d+")
                state[j] = tonumber(count) or (done and 1 or 0)
                if old[title] and old[title][j] and state[j] > old[title][j] then
                    points = points + (state[j] - old[title][j]) * 4
                end
            end
        end
    end
    if album and not album.boss and points > 0 then award(album, points) end
end

local e = CreateFrame("Frame")
for _, name in ipairs({"PLAYER_LOGIN","PLAYER_LEVEL_UP",
        "QUEST_LOG_UPDATE","CHAT_MSG_COMBAT_XP_GAIN","CHAT_MSG_SYSTEM","UI_INFO_MESSAGE"}) do
    e:RegisterEvent(name)
end
e:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        C.Init()
        scanObjectives()
        return
    end
    if not C.db then return end
    local album = C.CurrentAlbum()
    if event == "QUEST_LOG_UPDATE" then
        scanObjectives(album)
        return
    end
    if not album then return end
    if event == "PLAYER_LEVEL_UP" and not album.boss then
        award(album,40)
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local _, _, name = string.find(arg1 or "", killPattern)
        if not name then return end
        local card = album.byName[normalize(name)]
        local final = card and card.id == album.boss
        local boss = album.boss and card and card.rarity >= 4
        if card and C.Find(card, boss) then DEFAULT_CHAT_FRAME:AddMessage("Curator : " .. card.name) end
        if final then
            local clears = character().clears
            if not clears[album.id] then
                clears[album.id] = true
                C.GivePack(album)
                DEFAULT_CHAT_FRAME:AddMessage("Curator : premier donjon termine, booster de " .. album.name)
            end
        end
        award(album, album.boss and (final and 30 or boss and 10 or card and card.rank == 1 and .5 or .2) or 2)
    elseif (event == "CHAT_MSG_SYSTEM" or event == "UI_INFO_MESSAGE") and not album.boss then
        local message = arg1 or ""
        local _, _, quest
        if questPattern then _, _, quest = string.find(message, questPattern) end
        if quest then
            local seen = character().quests
            if not seen[quest] then seen[quest] = true; award(album,20) end
            return
        end
        local _, _, place
        if exploreXPPattern then _, _, place = string.find(message, exploreXPPattern) end
        if not place and explorePattern then _, _, place = string.find(message, explorePattern) end
        if place then
            local places = character().places
            if not places[place] then places[place] = true; award(album,10) end
        end
    end
end)



