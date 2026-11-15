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
