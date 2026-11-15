do
    local live = {}
    ns.LiveTrade = live
    local prefix = "T:" .. VERSION .. ":L/"
    local inviteTime, idleTime = 40, 300
    local sequence = 0

    local function token(id)
        return type(id) == "string" and string.len(id) <= 24 and string.find(id, "^%w+$") ~= nil
    end
    live.ValidToken = token

    local function samePlayer(a, b)
        return a and b and G.Fold(a) == G.Fold(b)
    end

    local function send(s, op, data)
        return ns.Wire:Send(s.with, prefix .. s.id .. "/" .. op .. "/" .. (data or ""), inviteTime)
    end

    local function eligible(name)
        return name and not G:IsMe(name) and T:CanTrade() and not Ignored(name)
            and not (ns.Bans and ns.Bans:Sender(name))
    end

    local function session(id, name, state)
        return { id = id, with = name, state = state, host = state == "waiting",
            untilTime = GetTime() + inviteTime, give = {}, take = {}, sent = "", rev = 0, remoteRev = 0 }
    end

    local function changed(s)
        ns.Fire("LIVE_TRADE_CHANGED", s)
    end

    function live:Close(s, reason, notify)
        if self.current ~= s then return end
        self.current = nil
        ns.CancelOwner(s)
        ns.Wire:Drop(s.with, prefix .. s.id .. "/")
        s.state = reason
        if notify then send(s, "C", reason) end
        changed(s)
    end

    function live:Watch(s)
        ns.Delay(1, function()
            if self.current ~= s then return end
            if GetTime() >= s.untilTime then
                self:Close(s, "expired", true)
            elseif s.attached and not ns.LiveTradeUI:Showing(s) then
                self:Close(s, "closed", true)
            else
                self:Watch(s)
            end
        end, s)
    end

    function live:Invite(name)
        name = G:Canon(Norm(name))
        if not eligible(name) then return false, "unavailable" end
        if self.current then return false, "busy" end
        sequence = sequence + 1
        local id = (ns.db.uid or "") .. Base36(Now()) .. Base36(sequence) .. Base36(math.random(0, 46655))
        local s = session(id, name, "waiting")
        if not token(id) or not send(s, "I") then return false, "unavailable" end
        self.current = s
        self:Watch(s)
        ns.Fire("LIVE_TRADE_OPEN", s)
        return true
    end

    function live:Agree(s)
        if self.current ~= s or s.state ~= "invited" then return end
        if not eligible(s.with) or not send(s, "A") then
            self:Close(s, "closed", true)
            return
        end
        s.state, s.untilTime = "open", GetTime() + idleTime
        changed(s)
        ns.Fire("LIVE_TRADE_OPEN", s)
    end

    function live:Sync(s)
        if self.current ~= s or s.state ~= "open" or s.sync then return end
        if T.Encode(s.give) == s.sent then return end
        s.sync = ns.Delay(.18, function()
            s.sync = nil
            if self.current ~= s or s.state ~= "open" then return end
            local data = T.Encode(s.give)
            if data == s.sent then return end
            local revision = s.rev + 1
            ns.Wire:Drop(s.with, prefix .. s.id .. "/U/")
            if send(s, "U", revision .. "/" .. data) then
                s.sent, s.rev, s.untilTime = data, revision, GetTime() + idleTime
            end
        end, s)
    end

    function live:Submit(s)
        if self.current ~= s or not s.host or s.state ~= "open" then return end
        local draft = T:Draft(s.with, s.give, s.take)
        draft.live = s.id
        local rec = T:Propose(draft)
        if rec then self:Close(s, "sent") end
        return rec
    end

    function live:MatchOffer(rec)
        local s = self.current
        if s and not s.host and s.state == "open" and rec.live == s.id and samePlayer(s.with, rec.with) then
            self:Close(s, "sent")
            return s
        end
    end

    function T:OnLive(f, sender)
        local id, op = f[2], f[3]
        if not token(id) then return end
        local s = live.current
        if op == "I" then
            if not eligible(sender) or (not ns.db.strangers and not T:Known(sender)) then return end
            if s then
                if s.id ~= id or not samePlayer(s.with, sender) then
                    send(session(id, sender, "invited"), "C", "busy")
                end
                return
            end
            s = session(id, sender, "invited")
            live.current = s
            live:Watch(s)
            ns.Fire("LIVE_TRADE_INVITE", s)
            return
        end
        if not (s and s.id == id and samePlayer(s.with, sender)) then return end
        if op == "C" then
            local reason = f[4]
            live:Close(s, (reason == "declined" or reason == "busy" or reason == "expired") and reason or "closed")
        elseif op == "A" and s.state == "waiting" then
            s.state, s.untilTime = "open", GetTime() + idleTime
            changed(s)
        elseif op == "U" and s.state == "open" then
            local revision, data = G.Count(f[4]), f[5]
            if not (revision and revision > s.remoteRev and data and string.len(data) <= 255
                and not string.find(data, "~", 1, true)) then return end
            local items = Decode(data)
            if not items then return end
            s.take, s.remoteRev, s.untilTime = items, revision, GetTime() + idleTime
            changed(s)
        end
    end
end
