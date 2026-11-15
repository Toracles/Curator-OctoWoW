-- 1.12.1 builds its gossip list with GossipTitleButtonTemplate and a scroll child.
-- Give Curator its own buttons so the game keeps the IDs and scripts of its options.
function G:HideLegacyRows()
    self.legacyShown = nil
    for _, row in ipairs(self.legacyRows or {}) do
        row:Hide()
    end
end

function G:PaintLegacy()
    self:HideLegacyRows()
    local frame = GossipFrame
    if not (self.open and self.role == "inn" and frame:IsVisible()) or self:Other() then return end
    if type(frame.buttonIndex) ~= "number" then return end
    local index = frame.buttonIndex - 1
    local previous = (index > 0 and _G["GossipTitleButton" .. index]) or GossipGreetingText
    local lines = self:Lines()
    local rows = self.legacyRows
    for i, line in ipairs(lines) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Button", "CuratorGossipRow" .. i,
                GossipGreetingScrollChildFrame, "GossipTitleButtonTemplate")
            rows[i] = row
            CuratorOctoFull.SetScript(row, "OnClick", function(self)
                G:Click(self.curatorLine)
            end)
        end
        row.curatorLine = line
        row:SetText(line.text)
        _G[row:GetName() .. "GossipIcon"]:SetTexture(line.icon or self.ICON)
        GossipResize(row)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, i == 1 and -10 or 0)
        row:Show()
        previous = row
    end
    if self.say then
        GossipGreetingText:SetText((GossipGreetingText:GetText() or "") .. "\n\n" .. self.say)
    end
    if table.getn(lines) > 0 then
        GossipSpacerFrame:SetPoint("TOP", previous, "BOTTOM", 0, 0)
        GossipSpacerFrame:Show()
    end
    GossipGreetingScrollFrame:UpdateScrollChildRect()
    self.legacyShown = true
end

function G:HookLegacy()
    if self.legacyHooked then return true end
    local update = GossipFrameUpdate
    if not (type(update) == "function" and type(GossipResize) == "function" and GossipFrame
        and GossipGreetingText and GossipGreetingScrollChildFrame and GossipGreetingScrollFrame and GossipSpacerFrame) then
        return false
    end
    self.legacyRows = {}
    GossipFrameUpdate = function()
        update()
        local ok = pcall(G.PaintLegacy, G)
        if not ok then G:HideLegacyRows() end
        if G.open then G:Fallback() end
    end
    self.legacyHooked = true
    return true
end
