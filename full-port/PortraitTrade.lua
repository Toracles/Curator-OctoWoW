do
    local entry = "CURATOR_TRADE"
    local portraitMenus = { PLAYER = true, PARTY = true, RAID = true }

    local function label()
        return ns.locale == "frFR" and "Échange (Curator)" or "Trade (Curator)"
    end

    local function menuTarget(menu)
        if not (menu and portraitMenus[menu.which]) then return end
        local name = P:UnitName(menu.unit)
        if name and name ~= "me" and not ns.Guild:IsMe(name) then return name end
    end

    ns.On("LOGIN", function()
        if Menu and Menu.ModifyMenu then return end
        if not (UnitPopupButtons and UnitPopupMenus and UnitPopupShown and UnitPopup_HideButtons and UnitPopup_OnClick) then
            return
        end
        if UnitPopupButtons[entry] then return end

        local option = { text = label(), dist = 0, color = { r = 0, g = 0.67, b = 1 } }
        UnitPopupButtons[entry] = option
        for which in pairs(portraitMenus) do
            local items = UnitPopupMenus[which]
            if items then
                local position = table.getn(items) + 1
                for index, value in ipairs(items) do
                    if value == "TRADE" then
                        position = index + 1
                        break
                    elseif value == "CANCEL" then
                        position = index
                        break
                    end
                end
                table.insert(items, position, entry)
            end
        end

        local hideButtons = UnitPopup_HideButtons
        UnitPopup_HideButtons = function()
            hideButtons()
            local menu = _G[UIDROPDOWNMENU_INIT_MENU]
            local shown = UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL]
            if not (menu and portraitMenus[menu.which] and shown) then return end
            local name = menuTarget(menu)
            menu.curatorTradeTarget = name
            option.text = label()
            for index, value in ipairs(UnitPopupMenus[menu.which]) do
                if value == entry then
                    shown[index] = name and 1 or 0
                    break
                end
            end
        end

        local click = UnitPopup_OnClick
        UnitPopup_OnClick = function(...)
            if not (this and this.value == entry) then
                return click(unpack(arg, 1, arg.n))
            end
            local menu = _G[UIDROPDOWNMENU_INIT_MENU]
            local name = menuTarget(menu)
            -- A portrait can change units while its menu is still open.
            if name and name == menu.curatorTradeTarget then
                ns.LiveTradeUI:Invite(name)
            end
        end
    end)
end
