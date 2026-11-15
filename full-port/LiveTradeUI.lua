do
    local ui = {}
    ns.LiveTradeUI = ui
    local live = ns.LiveTrade
    local words = {
        title = { "Live trade", "Échange en direct" },
        invite = { "%s wants to open a live trade with you.", "%s souhaite ouvrir un échange en direct avec toi." },
        accept = { "Open trade", "Ouvrir l’échange" },
        waiting = { "Waiting for %s to open the trade", "En attente de %s" },
        declined = { "%s declined the invitation", "%s a refusé l’invitation" },
        busy = { "%s is already in a live trade", "%s est déjà en échange" },
        expired = { "The live trade timed out", "Le délai de l’échange est écoulé" },
        closed = { "The live trade was closed", "L’échange en direct a été fermé" },
        sent = { "Review the final offer", "Vérifie l’offre finale" },
        open = { "Live preview", "Aperçu en direct" },
        note = { "Add cards or boosters on your side. Both players review the final offer before it goes through.",
            "Ajoute tes cartes ou boosters de ton côté. L’échange se fait après validation de l’offre finale par les deux joueurs." },
        classic = { "Classic offer", "Offre classique" },
        unavailable = { "Live trade is unavailable.", "L’échange en direct est indisponible." },
        localBusy = { "Finish or close your current live trade first.", "Termine ou ferme ton échange en cours." },
    }

    local function word(key)
        return words[key][ns.locale == "frFR" and 2 or 1]
    end

    local invitation
    local function buildInvitation()
        local f = S.Window("CuratorLiveTradeInvitation", 396, 150)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        table.insert(UISpecialFrames, "CuratorLiveTradeInvitation")
        f.message = S.Text(f, "GameFontHighlight")
        f.message:SetPoint("TOP", 0, -48)
        f.message:SetWidth(340)
        ns.SetWordWrap(f.message, true)
        f.accept = S.Button(f, "", 162, 26)
        f.accept:SetPoint("BOTTOMLEFT", 22, 21)
        f.refuse = S.Button(f, "", 162, 26)
        f.refuse:SetPoint("BOTTOMRIGHT", -22, 21)
        ns.SetScript(f.accept, "OnClick", function() live:Agree(f.session) end)
        local refuse = function() live:Close(f.session, "declined", true) end
        ns.SetScript(f.refuse, "OnClick", refuse)
        ns.SetScript(f.CloseButton, "OnClick", refuse)
        ns.SetScript(f, "OnHide", function()
            if f.session and f.session.state == "invited" then refuse() end
        end)
        return f
    end

    function ui:Invite(name)
        local ok, reason = live:Invite(name)
        if not ok then ns.Print(word(reason == "busy" and "localBusy" or "unavailable")) end
    end

    function ui:Showing(s)
        return A.frame and A.frame:IsShown() and A.mode == "guild" and A.ed and A.ed.live == s
    end

    function ui:Paint(e)
        local s, ed = e.live, A.frame.soc.ed
        local active = s.state == "open"
        local draft = e.draft
        draft.give, draft.take = s.give, s.take
        live:Sync(s)
        A:SetTitle(word("title"), "")
        A:SetAllCounts()
        A:PaintTradeHead(draft)
        ed.give.title:SetText(L["You give"])
        ed.take.title:SetText(L["You receive"])
        A:PaintTradeSide(ed.give, s.give, active, true, T:Missing(s.give))
        A:PaintTradeSide(ed.take, s.take, false, false)
        A:PaintBalance(s.give, s.take, s.with)
        ed.state:SetText(string.format(word(s.state), Short(s.with)))
        ed.state:SetTextColor(GOLDEN[1], GOLDEN[2], GOLDEN[3])
        ed.note:SetText(active and word("note") or "")
        ed.swap:SetTexture(MEDIA .. "Swap")
        ed.swap:SetAlpha(1)
        ed.swapGlow:SetAlpha(.25)
        local action = active and s.host and {
            label = L["Propose the trade"], action = "live", enabled = not T:Problem(draft),
        } or nil
        A:TradeButtons(action, { label = L["Cancel"], action = "cancelEdit" },
            s.host and not active and { label = word("classic"), action = "liveClassic" } or nil)
        if active and e.pick then A:RefreshTradePicker() else ed.pick:Hide() end
    end

    function ui:Submit(s)
        local rec = live:Submit(s)
        if rec then
            ns.Play(ns.SND.ink)
            A:ShowTrade(rec.id)
        else
            ns.Play(ns.SND.close)
            A:Refresh()
        end
    end

    function ui:Classic(s)
        live:Close(s, "closed", true)
        A:StartTrade(s.with, s.give, s.take)
    end

    ns.On("LIVE_TRADE_INVITE", function(s)
        invitation = invitation or buildInvitation()
        invitation.session = s
        invitation:SetTitle(word("title"))
        invitation.message:SetText(string.format(word("invite"), Short(s.with)))
        invitation.accept:SetLabel(word("accept"))
        invitation.refuse:SetLabel(L["Refuse"])
        invitation:Show()
    end)

    ns.On("LIVE_TRADE_OPEN", function(s)
        A:StartTrade(s.with)
        if A.ed and A.ed.draft and A.ed.draft.with == s.with then
            A.ed.live, s.attached = s, true
            A:Refresh()
        else
            live:Close(s, "closed", true)
        end
    end)

    ns.On("LIVE_TRADE_CHANGED", function(s)
        if invitation and invitation.session == s and s.state ~= "invited" then invitation:Hide() end
        if ui:Showing(s) then A:Refresh() end
    end)

    ns.On("TRADE_IN", function(rec)
        local s = live:MatchOffer(rec)
        if s and ui:Showing(s) then A:ShowTrade(rec.id) end
    end)
end
