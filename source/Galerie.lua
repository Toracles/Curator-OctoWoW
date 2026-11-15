local folder = "Interface\\AddOns\\CuratorOctoGalerie\\"
local album = 1
local page = 1
local columns, slots = 4, 8
local labels = {
    enUS = { "Previous album", "Next album", "Previous page", "Next page", "Page %d / %d" },
    frFR = { "Album précédent", "Album suivant", "Page précédente", "Page suivante", "Page %d / %d" },
}
local function language()
    return labels[CuratorOctoGalleryLanguage] and CuratorOctoGalleryLanguage
        or (GetLocale() == "frFR" and "frFR" or "enUS")
end
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
local buttons = {}
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
    local locale = language()
    local artwork = locale == "frFR" and "Cartes\\" or "Cartes-en\\"
    title:SetText(group.name)
    pageText:SetText(string.format(labels[locale][5], page, pages))
    for i, control in ipairs(buttons) do control:SetText(labels[locale][i]) end
    for i = 1, slots do
        local card = group.cards[(page - 1) * slots + i]
        if card then
            textures[i]:SetTexture(folder .. artwork .. group.path .. "\\" .. card .. ".tga")
            textures[i]:Show()
        else
            textures[i]:Hide()
        end
    end
end

local function button(x, action)
    local control = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    control:SetWidth(125)
    control:SetHeight(24)
    control:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 16)
    control:SetScript("OnClick", action)
    table.insert(buttons, control)
end
button(18, function()
    album = math.mod(album + table.getn(CuratorOctoGallery) - 2, table.getn(CuratorOctoGallery)) + 1
    page = 1
    refresh()
end)
button(149, function()
    album = math.mod(album, table.getn(CuratorOctoGallery)) + 1
    page = 1
    refresh()
end)
button(514, function()
    page = math.max(1, page - 1)
    refresh()
end)
button(645, function()
    page = math.min(page + 1, math.ceil(table.getn(CuratorOctoGallery[album].cards) / slots))
    refresh()
end)
local toggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
toggle:SetWidth(110)
toggle:SetHeight(22)
toggle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -17)
toggle:SetText("English / Français")
toggle:SetScript("OnClick", function()
    CuratorOctoGalleryLanguage = language() == "frFR" and "enUS" or "frFR"
    refresh()
end)
SLASH_CURATOROCTOGALERIE1 = "/curatorgalerie"
SLASH_CURATOROCTOGALERIE2 = "/curatorgallery"
SlashCmdList["CURATOROCTOGALERIE"] = function()
    if frame:IsShown() then frame:Hide() else refresh(); frame:Show() end
end
