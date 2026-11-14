local C=CuratorOcto
local frame, title, status, open, preview
local index,page=1,1
local views={}
local slots=8

local function album()
    return C.albums[index]
end

function C.Refresh()
    if not frame or not frame:IsShown() then return end
    local current=album()
    local count=0
    for _, card in ipairs(current.cards) do
        if C.Owned(card) then count=count+1 end
    end
    title:SetText(current.name .. "   " .. count .. " / " .. table.getn(current.cards))
    local points=C.db.points[current.boss and "dungeon" or "world"] or 0
    status:SetText(string.format("Page %d / %d     |     %g / 100     |     Boosters : %d",
        page,math.ceil(table.getn(current.cards)/slots),points,C.Packs(current)))
    if C.Packs(current)>0 then open:Enable(); preview:Hide()
    else open:Disable(); preview:Show() end
    for i,view in ipairs(views) do
        local card=current.cards[(page-1)*slots+i]
        view.card=card
        if card then C.PaintCard(view,card,false,C.Owned(card)); view:Show()
        else view:Hide() end
    end
end

local function build()
    frame=C.Panel("CuratorOctoAlbum",786,526)
    title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",frame,"TOP",0,-19)
    status=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    status:SetPoint("BOTTOM",frame,"BOTTOM",0,46)
    for i=1,slots do
        local view=C.CardView(frame)
        view:SetPoint("TOPLEFT",frame,"TOPLEFT",32+math.mod(i-1,4)*186,-44-math.floor((i-1)/4)*210)
        view:SetScript("OnEnter",function()
            local card=this.card
            if not card then return end
            local copies=C.Owned(card)
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
            GameTooltip:SetText(card.name)
            GameTooltip:AddLine(C.rarities[card.rarity])
            GameTooltip:AddLine(copies and ("Copies : " .. copies.count .. " | Foudreforge : " .. copies.shiny ..
                " | Titanforge : " .. copies.holo) or "Carte a decouvrir")
            GameTooltip:Show()
        end)
        view:SetScript("OnLeave",function() GameTooltip:Hide() end)
        views[i]=view
    end
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-6)
    local function change(delta)
        index=math.mod(index+table.getn(C.albums)+delta-1,table.getn(C.albums))+1
        page=1
        C.Refresh()
    end
    C.Button(frame,"< Album",88,18,14,function() change(-1) end)
    C.Button(frame,"Album >",88,111,14,function() change(1) end)
    C.Button(frame,"< Page",76,602,14,function() page=math.max(1,page-1); C.Refresh() end)
    C.Button(frame,"Page >",76,683,14,function()
        page=math.min(page+1, math.ceil(table.getn(album().cards)/slots))
        C.Refresh()
    end)
    open=C.Button(frame,"Ouvrir un booster",143,317,14,function() C.StartOpening(album()) end)
    preview=C.Button(frame,"Essayer l'ouverture",143,317,14,function() C.StartOpening(album(),true) end)
end

SLASH_CURATOROCTO1="/curator"
SlashCmdList.CURATOROCTO=function()
    if not C.db then return end
    if not frame then build() end
    if frame:IsShown() then frame:Hide(); return end
    local current=C.CurrentAlbum()
    for i,value in ipairs(C.albums) do
        if value==current then index,page=i,1; break end
    end
    frame:Show()
    C.Refresh()
end
