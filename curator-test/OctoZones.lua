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

local creditFields = { "octoLevelCredits", "octoPlaces", "octoExploredAreas", "quests", "octoQuests" }

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
    local questDecided = state.octoQuestCatchUpDecided or character.octoQuestCatchUpDecided
    state.octoQuestCatchUpDecided, character.octoQuestCatchUpDecided = questDecided, questDecided
    return state
end

local function questTitle(id)
    local db = QuestieOcto and QuestieOcto.DatabaseAPI
    local title = db and db.GetQuestTitle and db:GetQuestTitle(id)
    if not title and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        title = C_QuestLog.GetTitleForQuestID(id)
    end
    if type(title) == "string" and title ~= "" and title ~= ("Quest " .. id) then return title end
end

local nativeQuestTurnIn = rewards.OnQuestTurnedIn
function rewards:OnQuestTurnedIn(id, xp, money)
    local state = creditState(self:Char())
    if type(id) == "number" and not state.quests[id] and next(state.octoQuests) then
        local title = questTitle(id)
        if title and state.octoQuests[title] then
            state.quests[id] = true
            return
        end
    end
    return nativeQuestTurnIn(self, id, xp, money)
end

local function bulkQuestAPI()
    return GetQuestsCompleted or (C_QuestLog and C_QuestLog.GetQuestsCompleted)
end

local function completedQuests()
    local completion = QuestieOcto and QuestieOcto.Completion
    if completion and completion.ready and type(completion.history) == "table" then return completion.history end
    if rewards.octoQuestQueryPending or (completion and completion.querying) then return end
    local api = bulkQuestAPI()
    if not api then return end
    local ok, quests = pcall(api)
    if ok and type(quests) == "table" then return quests end
    local output = {}
    ok = pcall(api, output)
    if ok and next(output) then return output end
end

local function scanQuests(state)
    local completed = completedQuests()
    if not completed then return {}, false end
    local ids, seen, complete = {}, {}, true
    local legacy = next(state.octoQuests) ~= nil
    for key, value in pairs(completed) do
        local id = tonumber(key)
        if (value == true or value == 1) and id and id > 0 and id == math.floor(id) and not seen[id] and not state.quests[id] then
            seen[id] = true
            local title = legacy and questTitle(id)
            if legacy and not title then
                complete = false
            elseif not (title and state.octoQuests[title]) then
                table.insert(ids, id)
            else
                state.quests[id] = true
            end
        end
    end
    table.sort(ids)
    return ids, complete
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
    local quests, questsScanned = scanQuests(state)
    local questCount = table.getn(quests)
    local questTasks = ns.Quests and ns.Quests:CatchUpQuestCount(questCount) or 0
    local levelPoints = table.getn(levels) * self.POINTS.level
    local questPoints = questCount * self.POINTS.quest
    local entryBar = self:Bar("world", true)
    local bar = entryBar + levelPoints + questPoints
    local offers = math.floor(bar / ns.PACK_POINTS)
    bar = ns.Mod(bar, ns.PACK_POINTS)
    local packs = math.floor((bar + places * self.POINTS.explore) / ns.PACK_POINTS)
    local signature = { tostring(floor), tostring(entryBar), table.concat(levels, ","),
        table.concat(quests, ","), tostring(questTasks) }
    for _, group in ipairs(groups) do
        for _, place in ipairs(group.places) do table.insert(signature, tostring(place.area)) end
    end
    return { floor = floor, levels = levels, places = places, groups = groups, scanned = scanned, decided = state.octoCatchUpDecided,
        quests = quests, questsScanned = questsScanned, questTasks = questTasks, questsDecided = state.octoQuestCatchUpDecided,
        offers = offers, packs = packs, points = levelPoints + questPoints + places * self.POINTS.explore,
        bar = ns.Mod(bar + places * self.POINTS.explore, ns.PACK_POINTS), signature = table.concat(signature, ":") }
end

function rewards:ApplyCatchUp(plan, accepted)
    if not ns.db or (ns.Beta and ns.Beta:Over()) or (ns.Guard and not ns.Guard:AllowAll(true)) then return false end
    local character = self:Char()
    local state = creditState(character)
    state.octoLevelFloor, character.octoLevelFloor = plan.floor, plan.floor
    state.octoCatchUpDecided, character.octoCatchUpDecided = true, true
    for _, level in ipairs(plan.levels) do state.octoLevelCredits[level] = true end
    local questCount = 0
    for _, id in ipairs(plan.quests) do
        if not state.quests[id] then
            state.quests[id] = true
            questCount = questCount + 1
        end
    end
    if questCount > 0 then state.octoQuestCatchUpDecided, character.octoQuestCatchUpDecided = true, true end
    local choicePoints = table.getn(plan.levels) * self.POINTS.level + questCount * self.POINTS.quest
    if accepted and choicePoints > 0 then
        -- Past level-ups and turn-ins have no reliable location.
        self:Fill(nil, choicePoints, "catchup", false, true)
        if questCount > 0 and ns.Quests then ns.Quests:Add("quest", questCount) end
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
    if quest and not bulkQuestAPI() and not (C_QuestLog and C_QuestLog.GetQuestIDForLogIndex)
        and not (QuestieOcto and QuestieOcto.Completion) then
        local state = creditState(character)
        if state.octoQuests[quest] then return end
        state.octoQuests[quest] = true
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

do
    local labels = {
        title = { "Progress catch-up", "Rattrapage de progression" },
        intro = { "Claim rewards for levels, discoveries and quests turned in before Curator tracked them.",
            "Récupère les récompenses des niveaux, découvertes et quêtes rendues avant leur suivi par Curator." },
        askTake = { "Confirm that you want to claim the rewards below.", "Confirme que tu veux récupérer les récompenses ci-dessous." },
        askSkip = { "Confirm that you want to give up the rewards below. This choice is final for these rewards.",
            "Confirme que tu veux renoncer aux récompenses ci-dessous. Ce choix est définitif pour ces récompenses." },
        levels = { "Levels to credit", "Niveaux à créditer" },
        places = { "Discoveries to credit", "Découvertes à créditer" },
        quests = { "Game quests turned in", "Quêtes du jeu rendues" },
        questTasks = { "Curator turn-in objectives completed", "Objectifs Curator de rendu terminés" },
        points = { "Booster points", "Points de booster" },
        offers = { "Rewards to choose", "Récompenses à choisir" },
        packs = { "Zone boosters", "Boosters de zone" },
        bar = { "Booster bar after claiming", "Barre de boosters après récupération" },
        missing = { "Exploration data is unavailable for this session.", "Les données d’exploration sont indisponibles pour cette session." },
        missingQuests = { "Quest history is unavailable or incomplete.", "L’historique des quêtes est indisponible ou incomplet." },
        zero = { "There are no pending catch-up rewards.", "Il n’y a aucune récompense de rattrapage en attente." },
        take = { "Claim rewards", "Récupérer" },
        skip = { "Decline rewards", "Refuser" },
        yesTake = { "Confirm claim", "Confirmer la récupération" },
        yesSkip = { "Confirm refusal", "Confirmer le refus" },
        back = { "Back", "Retour" },
        close = { "Close", "Fermer" },
        taken = { "Catch-up rewards claimed.", "Récompenses rétroactives récupérées." },
        skipped = { "Catch-up rewards declined.", "Récompenses rétroactives refusées." },
        changed = { "Your rewards changed. Review the updated totals.", "Tes récompenses ont changé. Vérifie les nouveaux totaux." },
        usage = { "Usage: /curator catchup [last level already credited]", "Utilisation : /curator rattrapage [dernier niveau déjà crédité]" },
        reroll = { "Catch-up is available outside the reroll challenge.", "Le rattrapage est disponible hors défi de reroll." },
    }
    local function text(key)
        return labels[key][ns.locale == "frFR" and 2 or 1]
    end

    local rows = { "levels", "places", "quests", "questTasks", "points", "offers", "packs", "bar" }
    local frame
    local function paint(plan, decision, message)
        frame.plan, frame.decision = plan, decision
        local empty = plan.points == 0
        frame:SetTitle(text("title"))
        frame.intro:SetText(text(message or (empty and "zero") or (decision == "take" and "askTake")
            or (decision == "skip" and "askSkip") or "intro"))
        local values = { table.getn(plan.levels), plan.places, table.getn(plan.quests), plan.questTasks,
            plan.points, plan.offers, plan.packs, ns.Num(plan.bar) .. "%" }
        if not plan.scanned then values[2] = "—" end
        if not plan.questsScanned and values[3] == 0 then values[3], values[4] = "—", "—" end
        for i, key in ipairs(rows) do
            local row = frame.rows[i]
            row.label:SetText(text(key))
            row.value:SetText(values[i])
        end
        local notes = {}
        if not plan.scanned then table.insert(notes, text("missing")) end
        if not plan.questsScanned then table.insert(notes, text("missingQuests")) end
        frame.note:SetText(table.concat(notes, "\n"))
        frame.left:SetLabel(text(empty and "close" or decision and "back" or "skip"))
        frame.right:SetLabel(text(decision == "skip" and "yesSkip" or decision == "take" and "yesTake" or "take"))
        ns.SetShown(frame.right, not empty)
    end

    local function build()
        local skin = ns.Skin
        frame = skin.Window("CuratorCatchUpPanel", 530, 412)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(true)
        skin.DragBar(frame, 28)
        table.insert(UISpecialFrames, "CuratorCatchUpPanel")
        frame.intro = skin.Text(frame, "GameFontHighlight", "LEFT")
        frame.intro:SetPoint("TOPLEFT", 28, -48)
        frame.intro:SetWidth(474)
        ns.SetWordWrap(frame.intro, true)
        local summary = CreateFrame("Frame", nil, frame)
        summary:SetPoint("TOPLEFT", 25, -100)
        summary:SetPoint("BOTTOMRIGHT", -25, 101)
        local background = summary:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        ns.ColorTexture(background, .075, .08, .11, 1)
        frame.rows = {}
        for i, key in ipairs(rows) do
            local label = skin.Text(summary, "GameFontHighlight", "LEFT")
            local value = skin.Text(summary, "GameFontNormal", "RIGHT")
            label:SetPoint("TOPLEFT", 16, -15 - (i - 1) * 24)
            value:SetPoint("TOPRIGHT", -16, -15 - (i - 1) * 24)
            frame.rows[i] = { label = label, value = value }
        end
        frame.note = skin.Text(frame, "GameFontHighlightSmall", "LEFT")
        frame.note:SetPoint("BOTTOMLEFT", 28, 65)
        frame.note:SetWidth(474)
        frame.left = skin.Button(frame, "", 190, 30)
        frame.left:SetPoint("BOTTOMLEFT", 26, 24)
        frame.right = skin.Button(frame, "", 225, 30)
        frame.right:SetPoint("BOTTOMRIGHT", -26, 24)
        ns.SetScript(frame.left, "OnClick", function()
            if frame.plan.points == 0 then frame:Hide()
            elseif frame.decision then paint(frame.plan)
            else paint(frame.plan, "skip") end
        end)
        ns.SetScript(frame.right, "OnClick", function()
            if not frame.decision then paint(frame.plan, "take"); return end
            local current, errorKey = rewards:PlanCatchUp(frame.argument)
            if not current then
                if errorKey then ns.Print(text(errorKey)) end
                frame:Hide()
                return
            end
            if frame.plan.signature ~= current.signature then paint(current, nil, "changed"); return end
            local accepted = frame.decision == "take"
            if rewards:ApplyCatchUp(current, accepted) then
                frame:Hide()
                ns.Print(text(accepted and "taken" or "skipped"))
            end
        end)
        ns.SetScript(frame.CloseButton, "OnClick", function() frame:Hide() end)
    end

    function rewards:OpenCatchUp(argument, automatic)
        if automatic and (frame and frame:IsShown() or InCombatLockdown and InCombatLockdown()) then return end
        local plan, errorKey = self:PlanCatchUp(argument)
        if not plan then
            if errorKey and not automatic then ns.Print(text(errorKey)) end
            return
        end
        if automatic then
            local progressPending = not plan.decided and (table.getn(plan.levels) > 0 or plan.places > 0)
            local questsPending = not plan.questsDecided and table.getn(plan.quests) > 0
            if not (progressPending or questsPending) then return end
        end
        if not frame then build() end
        frame.argument = argument
        paint(plan)
        frame:Show()
    end

    local function historyReady()
        ns.Delay(0.2, function()
            if frame and frame:IsShown() then
                local plan = rewards:PlanCatchUp(frame.argument)
                if plan and plan.signature ~= frame.plan.signature then paint(plan, nil, "changed")
                elseif plan then paint(plan, frame.decision) end
            else
                rewards:OpenCatchUp("", true)
            end
        end)
    end

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if not rewards.octoQuestQueryPending then return end
        rewards.octoQuestQueryPending = nil
        historyReady()
    end)
    ns.On("LOGIN", function()
        local questie = QuestieOcto
        if questie and questie.Completion and questie.RegisterMessage then
            local listener = {}
            function listener:CompletionReady()
                if self.completed then return end
                self.completed = true
                historyReady()
            end
            function listener:DatabaseReady()
                if questie.Completion.ready then historyReady() end
            end
            questie:RegisterMessage("COMPLETION_READY", listener, "CompletionReady")
            questie:RegisterMessage("DATABASE_API_READY", listener, "DatabaseReady")
        elseif bulkQuestAPI() and QueryQuestsCompleted then
            rewards.octoQuestQueryPending = true
            local registered = pcall(events.RegisterEvent, events, "QUEST_QUERY_COMPLETE")
            if not registered or not pcall(QueryQuestsCompleted) then rewards.octoQuestQueryPending = nil end
            ns.Delay(8, function()
                if not rewards.octoQuestQueryPending then return end
                rewards.octoQuestQueryPending = nil
                historyReady()
            end)
        end
        ns.Delay(2, function() rewards:OpenCatchUp("", true) end)
    end)
end
