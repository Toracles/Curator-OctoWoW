local BATCH_SPEED = 5

function CR:StartBatch(count)
    if not self.real or self.batch or not self.frame or not self.frame:IsShown()
        or self.state ~= "case" or not ns.Cases then
        return
    end
    if count > ns.Cases:Openable(self.real) then
        self:PaintReal()
        return
    end
    self.batch = { total = count, opened = 0 }
    ns.SetTimeScale(self, BATCH_SPEED)
    self:Open()
end

function CR:PaintBatch()
    local batch = self.batch
    local status = self.frame.batchStatus
    CuratorOctoFull.SetShown(status, batch ~= nil)
    if batch then
        status:SetText(string.format(L["Cases opened: %d / %d"], batch.opened, batch.total))
    end
end

function CR:ClearBatch()
    if not self.batch then
        return
    end
    self.batch = nil
    ns.SetTimeScale(self, 1)
    self:PaintBatch()
end

function CR:AdvanceBatch()
    local batch = self.batch
    if not batch or batch.opened >= batch.total then
        if batch then ns.SetTimeScale(self, 1) end
        return false
    end
    -- Leave each reward on screen briefly before the next case begins.
    ns.Delay(1.6, function()
        batch.advance = true
        self:Back()
    end, self)
    return true
end

function CR:ContinueBatch()
    local batch = self.batch
    if batch and batch.advance then
        batch.advance = nil
        -- Let the case settle and the panel reappear before opening it.
        ns.Delay(0.45, function()
            if self.batch == batch then self:Open() end
        end, self)
    end
end
