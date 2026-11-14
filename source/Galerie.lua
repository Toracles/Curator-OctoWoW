local folder = "Interface\\AddOns\\CuratorOctoGalerie\\"
local album = 1
local page = 1
local columns, slots = 4, 8
local frame = CreateFrame("Frame", "CuratorOctoGalerieFrame", UIParent)
frame:SetWidth(785)
frame:SetHeight(640)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = {left = 9, right = 9, top = 9, bottom = 9},
})
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
frame:Hide()
table.insert(UISpecialFrames, frame:GetName())

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -20)
local pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 24)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -7)
local textures = {}
for i = 1, slots do
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(183)
    icon:SetHeight(256)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + math.mod(i - 1, columns) * 190, -54 - math.floor((i - 1) / columns) * 261)
    icon:SetTexCoord(0, 366 / 512, 0, 1)
    textures[i] = icon
end

local function refresh()
    local group = CuratorOctoGallery[album]
    local pages = math.ceil(table.getn(group.cards) / slots)
    title:SetText(group.name)
    pageText:SetText(page .. " / " .. pages)
    for i = 1, slots do
        local card = group.cards[(page - 1) * slots + i]
        if card then
            textures[i]:SetTexture(folder .. "Cartes\\" .. group.path .. "\\" .. card .. ".tga")
            textures[i]:Show()
        else
            textures[i]:Hide()
        end
    end
end

local function button(label, x, action)
    local control = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    control:SetWidth(125)
    control:SetHeight(24)
    control:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 16)
    control:SetText(label)
    control:SetScript("OnClick", action)
end
button("Album precedent", 18, function()
    album = math.mod(album + table.getn(CuratorOctoGallery) - 2, table.getn(CuratorOctoGallery)) + 1
    page = 1
    refresh()
end)
button("Album suivant", 149, function()
    album = math.mod(album, table.getn(CuratorOctoGallery)) + 1
    page = 1
    refresh()
end)
button("Page precedente", 514, function()
    page = math.max(1, page - 1)
    refresh()
end)
button("Page suivante", 645, function()
    page = math.min(page + 1, math.ceil(table.getn(CuratorOctoGallery[album].cards) / slots))
    refresh()
end)
SLASH_CURATOROCTOGALERIE1 = "/curatorgalerie"
SlashCmdList["CURATOROCTOGALERIE"] = function()
    if frame:IsShown() then frame:Hide() else refresh(); frame:Show() end
end
