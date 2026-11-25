-- First minimap opening builds at most one card/tile per rendered frame.
-- Other entry points can finish a pending build synchronously before using it.
function A:BuildStep()
    if self.buildRunning and self.buildJob then coroutine.yield() end
end

function A:ResumeBuild()
    self.buildRunning = true
    local ok, err = coroutine.resume(self.buildJob)
    self.buildRunning = nil
    if not ok then
        self.buildJob, self.openAfterBuild, self.prewarming = nil, nil, nil
        self.buildError = err
        if self.buildDriver then self.buildDriver:Hide() end
        if self.buildNotice then self.buildNotice:Hide() end
        if geterrorhandler then geterrorhandler()(err) end
        return false
    end
    if coroutine.status(self.buildJob) == "dead" then
        local open = self.openAfterBuild
        self.buildJob, self.openAfterBuild, self.prewarming = nil, nil, nil
        self.buildDriver:Hide()
        self.buildNotice:Hide()
        if open then self:Show() end
    end
    return true
end

function A:FinishBuild()
    -- A slash command or another page supersedes a pending minimap opening.
    self.openAfterBuild = nil
    while self.buildJob do
        if not self:ResumeBuild() then return end
    end
end

function A:ToggleFromMinimap()
    if self.buildJob then
        self.prewarming = nil
        self.openAfterBuild = not self.openAfterBuild
        CuratorOctoFull.SetShown(self.buildNotice, self.openAfterBuild)
        return
    end
    if self.buildError then
        ns.Print(ns.locale == "frFR" and "Rechargez l'interface pour réessayer." or "Reload the interface to retry.")
        return
    end
    if self.frame or not (coroutine and coroutine.create and coroutine.resume and coroutine.yield) then
        return self:Toggle()
    end
    self:StartBuild(true)
end

function A:StartBuild(open)
    if not self.buildDriver then
        local driver = CreateFrame("Frame")
        driver:Hide()
        CuratorOctoFull.SetScript(driver, "OnUpdate", function()
            if A.prewarming and UnitAffectingCombat and UnitAffectingCombat("player") then return end
            A:ResumeBuild()
        end)
        self.buildDriver = driver
        local notice = S.Window("CuratorOpening", 300, 80)
        notice:SetPoint("CENTER")
        notice:Hide()
        local text = S.Text(notice, "GameFontNormal")
        text:SetPoint("CENTER", 0, -6)
        text:SetText(ns.locale == "frFR" and "Ouverture de Curator…" or "Opening Curator…")
        self.buildNotice = notice
        CuratorOctoFull.SetScript(notice.CloseButton, "OnClick", function() notice:Hide() end)
        CuratorOctoFull.SetScript(notice, "OnHide", function()
            if A.buildJob then A.openAfterBuild = nil end
        end)
        tinsert(UISpecialFrames, "CuratorOpening")
    end
    self.openAfterBuild = open or nil
    self.buildJob = coroutine.create(function() self:Build() end)
    CuratorOctoFull.SetShown(self.buildNotice, open)
    self.buildDriver:Show()
end

-- Prepare the same hidden frames after login, without delaying login or granting anything.
function A:WarmUp()
    if self.frame or self.buildJob or self.buildError then return end
    if not (coroutine and coroutine.create and coroutine.resume and coroutine.yield) then return end
    self.prewarming = true
    self:StartBuild(false)
end
ns.On("LOGIN", function()
    ns.Delay(3, function() A:WarmUp() end)
end)
