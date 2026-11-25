-- Data/reward events remain synchronous; only redundant painting is coalesced.
function A:CancelRefresh()
    self.refreshPending = nil
    if self.refreshDriver then self.refreshDriver:Hide() end
end
function A:FlushRefresh()
    if not self.refreshPending then return end
    self:CancelRefresh()
    if self.frame and self.frame:IsShown() then
        if self:ClaimsPage() then self:QuestsChanged() else self:Refresh() end
    end
end
function A:RequestRefresh()
    if self.refreshPending or not (self.frame and self.frame:IsShown()) then return end
    if not self.refreshDriver then
        self.refreshDriver = CreateFrame("Frame")
        self.refreshDriver:Hide()
        CuratorOctoFull.SetScript(self.refreshDriver, "OnUpdate", function() A:FlushRefresh() end)
    end
    self.refreshPending = true
    self.refreshDriver:Show()
end
