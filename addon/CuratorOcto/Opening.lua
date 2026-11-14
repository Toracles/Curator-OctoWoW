local C = CuratorOcto
local media = C.media
local opening
local W, H = 143, 200
local WIND = {.06,.1,.28,.75,1.25,1.85}
local FLIP = {.26,.28,.32,.4,.44,.48}
local HOLD = {.26,.3,.36,.36,.44,.5}

function C.Panel(name, width, height)
    local panel = CreateFrame("Frame", name, UIParent)
    panel:SetWidth(width)
    panel:SetHeight(height)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,
        insets={left=6,right=6,top=6,bottom=6}})
    panel:SetScale(math.min(1, (UIParent:GetWidth()-24)/width, (UIParent:GetHeight()-24)/height))
    table.insert(UISpecialFrames, name)
    panel:Hide()
    return panel
end

function C.Button(parent, label, width, x, y, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(24)
    button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    button:SetText(label)
    button:SetScript("OnClick", action)
    return button
end

local function texture(parent, layer, asset)
    local t = parent:CreateTexture(nil, layer)
    if asset then t:SetTexture(media .. asset) end
    return t
end

local function size(region, w, h)
    region:SetWidth(w)
    region:SetHeight(h)
end

function C.CardView(parent)
    local view = CreateFrame("Button", nil, parent)
    size(view,W,H)
    view.back = texture(view,"OVERLAY","Back.tga")
    view.back:SetAllPoints(view)
    view.back:SetTexCoord(0,366/512,0,1)
    view.art = texture(view,"BACKGROUND")
    view.art:SetAllPoints(view)
    view.art:SetTexCoord(0,366/512,0,1)
    view.portrait = texture(view,"BORDER")
    view.portrait:SetPoint("TOPLEFT",view,"TOPLEFT",10,-12)
    view.portrait:SetPoint("BOTTOMRIGHT",view,"BOTTOMRIGHT",-10,81)
    view.frame = texture(view,"ARTWORK")
    view.frame:SetAllPoints(view)
    view.frame:SetTexCoord(0,366/512,0,1)
    view.name = view:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    view.name:SetPoint("LEFT",view,"LEFT",9,-25)
    view.name:SetPoint("RIGHT",view,"RIGHT",-9,-25)
    view.label = view:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    view.label:SetPoint("BOTTOM",view,"BOTTOM",0,26)
    view.label:SetTextColor(.27,.16,.08)
    view.shine = texture(view,"OVERLAY","Glow.tga")
    view.shine:SetAllPoints(view)
    view.shine:SetBlendMode("ADD")
    view.shine:SetAlpha(0)
    return view
end

function C.PaintCard(view, card, back, owned, finish)
    local artwork = CuratorOctoFaces[card.album.id][card.id]
    view.back:Hide()
    view.portrait:Hide()
    view.frame:Hide()
    view.name:Hide()
    view.label:Hide()
    view.art:Hide()
    if back then view.back:Show(); return end
    view.art:SetTexture(media .. (artwork or "Body.tga"))
    local tone = owned and 1 or .48
    view.art:SetVertexColor(tone,tone,tone)
    view.art:Show()
    if not artwork then
        local display = CuratorOctoCatalog[card.album.id][card.id][5]
        if CuratorOctoPortraits[display] then
            view.portrait:SetTexture(media .. "Portraits\\" .. display .. ".tga")
        else
            view.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        view.portrait:SetVertexColor(tone,tone,tone)
        view.portrait:Show()
        view.frame:SetTexture(media .. "Frame" .. card.rarity .. ".tga")
        view.frame:Show()
        view.name:SetText(card.name)
        view.name:Show()
        view.label:SetText(C.rarities[card.rarity])
        view.label:Show()
    end
    if finish then
        view.label:SetText(finish=="holo" and "Titanforge" or "Foudreforge")
        view.label:SetTextColor(.95,.78,.2)
        view.label:Show()
    else
        view.label:SetTextColor(.27,.16,.08)
    end
end

local function ease(t)
    return 1-(1-t)^3
end

local function place(region,parent,x,y)
    region:ClearAllPoints()
    region:SetPoint("CENTER", parent, "CENTER", x, y)
end

local function build()
    local scene = C.Panel("CuratorOctoOpening", 790, 570)
    scene:SetFrameStrata("FULLSCREEN_DIALOG")
    scene.background = texture(scene,"BACKGROUND")
    scene.background:SetPoint("TOPLEFT",scene,"TOPLEFT",9,-9)
    scene.background:SetPoint("BOTTOMRIGHT",scene,"BOTTOMRIGHT",-9,9)
    scene.background:SetVertexColor(.6,.6,.6)
    scene.glow = texture(scene,"ARTWORK","Glow.tga")
    scene.glow:SetBlendMode("ADD")
    scene.ring = texture(scene,"ARTWORK","Shock.tga")
    scene.ring:SetBlendMode("ADD")
    scene.pack = CreateFrame("Button",nil,scene)
    size(scene.pack,165,330)
    scene.bottom = texture(scene.pack,"ARTWORK")
    size(scene.bottom,165,330)
    scene.top = texture(scene.pack,"ARTWORK")
    size(scene.top,165,41)
    scene.title = scene:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    scene.title:SetPoint("TOP",scene,"TOP",0,-26)
    scene.hint = scene:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    scene.hint:SetPoint("BOTTOM",scene,"BOTTOM",0,22)
    scene.cards = {}
    for i=1,8 do scene.cards[i]=C.CardView(scene) end
    scene.close = C.Button(scene,"Fermer",100,18,13,function() scene:Hide() end)
    scene.skip = C.Button(scene,"Tout retourner",142,630,13,function()
        if scene.state == "reveal" then
            for _, card in ipairs(scene.cards) do
                if card.pick then scene.reveal(card) end
            end
        end
    end)
    scene.skip:Hide()
    function scene.reveal(view)
        if view.clock or view.revealed then return end
        view.clock=0
    end
    for _, view in ipairs(scene.cards) do
        view:SetScript("OnClick",function()
            if scene.state=="reveal" then scene.reveal(this) end
        end)
    end
    scene.pack:SetScript("OnClick",function()
        if scene.state == "ready" then
            local picks, best = C.OpenPack(scene.album,scene.preview)
            if not picks then scene:Hide(); return end
            scene.picks, scene.best, scene.state, scene.elapsed=picks,best,"charge",0
            scene.hint:SetText("")
            if C.Refresh then C.Refresh() end
        elseif scene.state == "charge" then
            scene.elapsed=scene.chargeTime or 3
        end
    end)
    scene:SetScript("OnUpdate", function()
        local dt=arg1 or 0
        scene.elapsed=scene.elapsed+dt
        local t=scene.elapsed
        if scene.state=="ready" then
            local y=-16+10*math.sin(t*2)
            place(scene.pack,scene,0,y)
            place(scene.glow,scene,0,y)
            scene.glow:SetVertexColor(1,.8,.52)
            scene.glow:SetAlpha(.23+.09*math.sin(t*3))
            size(scene.glow,260,310)
        elseif scene.state=="charge" then
            local best=scene.best
            local rarity=best<3 and best or math.min(best,3+math.floor(math.max(0,t-.2)/.42))
            local color=C.colors[rarity]
            scene.chargeTime=.2+math.max(0,best-3)*.42+HOLD[best]
            scene.glow:SetVertexColor(color[1],color[2],color[3])
            scene.glow:SetAlpha(math.min(.9,.26+t*.55))
            size(scene.glow,250+t*200,320+t*140)
            place(scene.pack,scene,math.sin(t*78)*(2+t*5),-16+math.sin(t*86)*3)
            if t>=scene.chargeTime then
                scene.state,scene.elapsed="deal",0
                PlaySound("igQuestListComplete")
            end
        elseif scene.state=="deal" then
            local burst=math.min(1,t/.52)
            local color=C.colors[scene.best]
            scene.ring:SetVertexColor(color[1],color[2],color[3])
            scene.ring:SetAlpha(.9*(1-burst))
            size(scene.ring,110+610*burst,110+420*burst)
            place(scene.ring,scene,0,95)
            place(scene.top,scene.pack,80*burst,138+160*burst)
            place(scene.bottom,scene.pack,0,-160*burst)
            scene.pack:SetAlpha(1-burst)
            scene.glow:SetAlpha(.85*(1-burst))
            local n=table.getn(scene.picks)
            local settled=true
            for i,pick in ipairs(scene.picks) do
                local view=scene.cards[i]
                local raw=math.min(1,math.max(0,(t-.045*(i-1))/.55))
                if raw<1 then settled=false end
                if raw>0 then
                    local e=ease(raw)
                    if not view.pick then
                        view.pick=pick
                        C.PaintCard(view,pick.card,true,true)
                        view:Show()
                    end
                    local columns=n>5 and 4 or n
                    local col=math.mod(i-1,columns)
                    local x=(col-(columns-1)/2)*151
                    local y=n>5 and (i<=4 and 110 or -105) or (22-math.abs(col-2)*8)
                    place(view,scene,x*e,100*(1-e)+y*e+math.sin(e*math.pi)*85)
                    size(view,math.max(1,W*(.45+.55*e)*math.abs(math.cos(raw*math.pi*2))),H*(.45+.55*e))
                    view:SetAlpha(math.min(1,raw*6))
                end
            end
            if settled then
                scene.pack:Hide()
                scene.state="reveal"
                scene.hint:SetText("Clique sur les cartes pour les retourner")
                scene.skip:Show()
            end
        else
            local pending=0
            for _,view in ipairs(scene.cards) do
                if view.pick and not view.revealed then pending=pending+1 end
                if view.clock then
                    local card=view.pick.card
                    local rank=card.rarity
                    local color=C.colors[rank]
                    view.clock=view.clock+dt
                    local turn=(view.clock-WIND[rank])/FLIP[rank]
                    view.shine:SetVertexColor(color[1],color[2],color[3])
                    view.shine:SetAlpha(turn<0 and math.min(.85,view.clock/WIND[rank]) or math.max(0,1-turn))
                    if turn>=0 then
                        size(view,math.max(1,W*math.abs(math.cos(math.min(1,turn)*math.pi))),H)
                        if turn>=.5 and not view.face then
                            view.face=true
                            C.PaintCard(view,card,false,true,view.pick.finish)
                            PlaySound("igMainMenuOptionCheckBoxOn")
                        end
                        if turn>=1 then
                            view.revealed,view.clock=true,nil
                            view.shine:SetAlpha(0)
                        end
                    end
                end
            end
            if pending==0 then scene.hint:SetText("Booster ouvert"); scene.skip:Hide() end
        end
    end)
    return scene
end

function C.StartOpening(album, preview)
    if not preview and C.Packs(album)==0 then return end
    opening=opening or build()
    local scene=opening
    scene.album,scene.preview,scene.state,scene.elapsed=album,preview,"ready",0
    scene.background:SetTexture(media .. "Studio" .. album.art .. ".blp")
    scene.top:SetTexture(media .. "Pack" .. album.art .. "Top.blp")
    scene.bottom:SetTexture(media .. "Pack" .. album.art .. "Bottom.blp")
    place(scene.top,scene.pack,0,144)
    place(scene.bottom,scene.pack,0,0)
    scene.pack:SetAlpha(1)
    scene.pack:Show()
    scene.title:SetText(album.name)
    scene.hint:SetText(preview and "Apercu : clique sur le booster" or "Clique sur le booster pour l'ouvrir")
    scene.ring:SetAlpha(0)
    scene.skip:Hide()
    for _, view in ipairs(scene.cards) do
        view.pick,view.clock,view.face,view.revealed=nil,nil,nil,nil
        view.shine:SetAlpha(0)
        view:Hide()
    end
    scene:Show()
end

