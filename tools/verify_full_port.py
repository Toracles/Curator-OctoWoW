from pathlib import Path
import sys
from gift_code_fixture import gift_code_fixture
sys.path.insert(0, str(Path(".test-runtime").resolve()))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute(r"""
math.mod = math.fmod
time, date = os.time, os.date
tinsert, tremove, strlen, strfind, format = table.insert, table.remove, string.len, string.find, string.format
local noop = function() end
local widget
local scripts = {}
local registrations = {}
local function setShown(frame, shown, eventName)
 if (frame.shown ~= false) == shown then return end
 frame.shown = shown
 local handler = scripts[frame][eventName]
 if handler then
  local previousThis, previousArg = this, arg1
  this, arg1 = frame, nil
  handler()
  this, arg1 = previousThis, previousArg
 end
end
local unavailable = {SetEnabled=true, SetWordWrap=true, SetMaxLines=true, HookScript=true, GetSize=true,
 GetRect=true, GetStringHeight=true, SetMotionScriptsWhileDisabled=true, SetClampedToScreen=true, SetAutoFocus=true,
 SetDesaturated=true, SetVertexOffset=true, SetShown=true, SetSize=true, SetColorTexture=true, SetClipsChildren=true,
 SetPortraitZoom=true, SetCamDistanceScale=true, SetPaused=true, SetParticlesEnabled=true, SetLight=true,
 HasAnimation=true, SetAnimation=true,
 R=true, Low=true, High=true, Text=true, GreetingPanel=true, CreateMaskTexture=true, AddMaskTexture=true}
local methods = {
 RegisterEvent = function(self, event) registrations[self][event] = true end,
 SetScript = function(self, event, callback)
  assert(event ~= "OnModelLoaded" and event ~= "OnTooltipSetUnit", "Unsupported UI script")
  scripts[self][event] = callback
 end,
 GetScript = function(self, event) return scripts[self][event] end,
 GetStatusBarTexture = function() return widget() end,
 GetFontString = function() return widget() end,
 GetStringWidth = function(self) return string.len(self.textValue or "") * 7 end,
 SetText = function(self, value) self.textValue = tostring(value or "") end,
 GetText = function(self) return self.textValue or "" end,
 GetCheckedTexture = function() return widget() end,
 GetNormalTexture = function() return widget() end,
 GetHighlightTexture = function() return widget() end,
 GetParent = function(self) return self.parent end,
 SetParent = function(self, parent) self.parent = parent end,
 CreateTexture = function(self, _, layer)
  local texture = widget(self, true)
  texture.drawLayer = layer or "ARTWORK"
  self.textures = self.textures or {}
  table.insert(self.textures, texture)
  return texture
 end,
 SetDrawLayer = function(self, layer) self.drawLayer = layer end,
 SetTexture = function(self, file, green, blue, alpha)
  self.textureFile, self.textureAlpha = file, alpha
 end,
 SetVertexColor = function(self, red, green, blue, alpha)
  self.vertexAlpha = alpha
 end,
 GetName = function(self) return self.widgetName end,
 CreateFontString = function(self) return widget(self, true) end,
 GetWidth = function() return 1024 end,
 GetHeight = function() return 768 end,
 GetFrameLevel = function() return 1 end,
 GetEffectiveScale = function(self) return self:GetScale() * (self.parent and self.parent:GetEffectiveScale() or 1) end,
 GetScale = function(self) return self.scale or 1 end,
 SetScale = function(self, scale) self.scale = scale end,
 GetAlpha = function() return 1 end,
 GetRotation = function() return 0 end,
 GetLeft = function() return 0 end,
 GetBottom = function() return 0 end,
 GetCenter = function() return 512,384 end,
 GetNumPoints = function(self) return self.anchor and 1 or 0 end,
 GetPoint = function(self) if self.anchor then return unpack(self.anchor) end end,
 SetPoint = function(self, point, relative, relativePoint, x, y)
  self.anchor = { point, relative, relativePoint, x, y }
 end,
 SetAllPoints = function(self, relative) self.allPointsTarget = relative or self.parent end,
 ClearAllPoints = function(self) self.anchor, self.allPointsTarget = nil, nil end,
 Show = function(self) setShown(self, true, "OnShow") end,
 Hide = function(self) setShown(self, false, "OnHide") end,
 IsShown = function(self) return self.shown ~= false end,
 IsVisible = function(self) return self.shown ~= false end,
}
function simulateVertexOffsets(enabled)
 methods.SetVertexOffset = enabled and noop or nil
end
widget = function(parent, layeredRegion)
 local frame = setmetatable({parent=parent}, {__index=function(_, key)
     if layeredRegion and (key == "GetScale" or key == "GetEffectiveScale") then return nil end
     return methods[key] or (not unavailable[key] and string.find(key, "^[A-Z]") and noop or nil)
 end})
 scripts[frame] = {}
 registrations[frame] = {}
 return frame
end
UIParent, Minimap, DEFAULT_CHAT_FRAME, GameTooltip = widget(), widget(), widget(), widget()
unitTooltipCallbacks = {}
TooltipDataProcessor = { AddTooltipPostCall = function(kind, callback)
    assert(kind == 2)
    table.insert(unitTooltipCallbacks, callback)
end }
function assertOpaqueBackground(texture)
 assert(texture.drawLayer == "BACKGROUND")
 assert(texture.textureFile == "Interface\\Buttons\\WHITE8X8" and texture.vertexAlpha == 1)
end
CreateFrame = function(kind,name,parent,template)
 local modern = {SecureActionButtonTemplate=true, BackdropTemplate=true, PortraitFrameTemplate=true, LargeSideTabButtonTemplate=true,
     CollectionsBackgroundTemplate=true, InsetFrameTemplate=true, WowStyle1DropdownTemplate=true, CheckboxWithLabelTemplate=true, ColoredProgressBarTemplate=true}
 assert(not modern[template], "Unsupported inherited template: " .. tostring(template))
 assert(kind ~= "ModelScene", "Unsupported frame type: ModelScene")
 local frame=widget(parent)
 if kind == "PlayerModel" then
  frame.SetDisplayInfo = function(self, display)
   assert(type(display) == "number" and display > 0, "Invalid creature display ID")
   self.testDisplay = display
  end
  frame.ClearModel = function(self) self.testDisplay = nil end
 end
 if name then
  frame.widgetName = name
  _G[name] = frame
  if template == "GossipTitleButtonTemplate" then
   _G[name .. "GossipIcon"] = frame:CreateTexture(nil, "BACKGROUND")
  end
 end
 return frame
end
GetCursorPosition = function() return 640, 480 end
IsShiftKeyDown = function() return false end
function SendAddonMessage(prefix, message, channel, target)
 lastMessage = {prefix, message, channel, target}
end
local clock = 100
GetTime = function() return clock end
function stepFrames(count)
 reportedErrors = {}
 for step = 1,count do
  local snapshot = {}
  for frame, handlers in pairs(scripts) do
   if handlers.OnUpdate and frame:IsShown() then table.insert(snapshot, frame) end
  end
  clock = clock + .05
  for _, frame in ipairs(snapshot) do
   local callback = scripts[frame].OnUpdate
   if callback and frame:IsShown() then
    this, arg1 = frame, .05
    callback()
   end
  end
  assert(not reportedErrors[1], reportedErrors[1])
 end
end
UnitName = function() return "Tester" end
zone = "Northwind"
ERR_ZONE_EXPLORED = "Discovered: %s"
ERR_DEATHBIND_SUCCESS_S = "%s is now your home."
COMBATLOG_HONORGAIN = "%s dies (rank %s). %d honor."
GetZoneText = function() return zone end
GetRealZoneText = GetZoneText
GetRealmName = function() return "OctoWoW" end
UnitLevel = function() return 20 end
UnitFactionGroup = function() return "Alliance" end
IsInGuild = function() return false end
geterrorhandler = function() return function(err) table.insert(reportedErrors,err) end end
reportedErrors = {}
GetLocale = function() return "enUS" end
local clientVersion = "1.18.1"
GetBuildInfo = function() return clientVersion end
GetAddOnMetadata = function(_, field) if field == "Version" then return "1.14.3" end end
SlashCmdList, UISpecialFrames, StaticPopupDialogs = {},{},{}
UnitPopupButtons = {}
UnitPopupMenus = {
 PLAYER = { "WHISPER", "TRADE", "FOLLOW", "CANCEL" },
 PARTY = { "TRADE", "CANCEL" },
 RAID = { "RAID_REMOVE", "CANCEL" },
 SELF = { "CANCEL" },
 PET = { "CANCEL" },
}
UnitPopupShown = { {} }
UIDROPDOWNMENU_MENU_LEVEL = 1
UIDROPDOWNMENU_INIT_MENU = "TestPortraitDropDown"
TestPortraitDropDown = {}
function UnitPopup_HideButtons()
 for index in ipairs(UnitPopupMenus[TestPortraitDropDown.which]) do
  UnitPopupShown[1][index] = 1
 end
end
function UnitPopup_OnClick() return this.value end
function traceEvent(name,value)
 local snapshot={}
 for frame in pairs(scripts) do table.insert(snapshot,frame) end
 local result={}
 reportedErrors={}
 for _, frame in ipairs(snapshot) do
  local handlers=scripts[frame]
  if registrations[frame][name] and handlers.OnEvent then
   this,event,arg1=frame,name,value
   local ok,why=pcall(handlers.OnEvent)
   if not ok then table.insert(result,why) end
  end
 end
 for _, err in ipairs(reportedErrors) do table.insert(result,err) end
 table.sort(result)
 return table.concat(result,"\n")
end
""")
root = Path("full-port-work/Curator")
toc = (root / "Curator.toc").read_text(encoding="utf8").splitlines()
assert "## SavedVariablesPerCharacter: CuratorOctoCatchUpDB" in toc
files = [line.replace("\\", "/") for line in toc if line.endswith(".lua")]
errors = []
for name in files:
    try:
        lua.execute((root / name).read_text(encoding="utf8"), name="@" + name)
    except Exception as exc:
        errors.append(name + ": " + str(exc).splitlines()[0])
print(f"{len(files) - len(errors)} / {len(files)} chunks loaded in Lua 5.1 mock")
print("\n".join(errors))
if errors:
    sys.exit(1)


for event, arg in [("ADDON_LOADED", "Curator"), ("PLAYER_LOGIN", None)]:
    result = lua.globals().traceEvent(event, arg)
    print(f"{event}: {result or 'no mock error'}")
    assert not result, result






lua.execute(r"""
local ns = CuratorOctoFull
assert(ns.db)
assert(ns.SeriesByKey("zephras") == nil)
assert(ns.Rewards:ZoneSeries().key == "northwind")
zone = "Stormwind Vault"
assert(ns.Rewards:ZoneSeries().key == "stormwindvault")
assert(ns.SeriesByKey("gilneas") and ns.SeriesByKey("gilneascity"))
""")
print("OctoWoW album and zone routing checks passed")
lua.execute(r"""
local ns = CuratorOctoFull
local cards = ns.Collection:Open(ns.SeriesByKey("northwind"), { test = true })
assert(table.getn(cards)==8)
local cards = ns.Collection:Open(ns.SeriesByKey("stormwindvault"), { test = true })
assert(table.getn(cards)==5)
""")
print("Upstream draw engine verified on two OctoWoW albums")
lua.execute(r"""
local ns = CuratorOctoFull
local booster, album = ns.Booster, ns.Album
local series = ns.SeriesByKey("northwind")
zone = "Northwind"
album:ShowBoosters()
local function click(button)
    this, arg1 = button, "LeftButton"
    button:GetScript("OnClick")()
end
for _, stock in ipairs({0, 2}) do
    ns.db.packs[series.key] = stock
    local collection = ns.Seal({ cards = ns.db.cards })
    local xp = ns.Level:XP()
    local featured = album.frame.boost.feat
    assert(album.frame:IsShown() and featured.series == series and featured.test:IsShown())
    click(featured.test)
    assert(booster:Showing() and booster.series == series and booster.opts.test)
    assert(not album.frame:IsShown())
    booster:Tear()
    assert(table.getn(booster.picks) == 8)
    booster:Burst()
    stepFrames(580)
    assert(booster.state == "done", booster.state)
    local shownModels = 0
    for i, pick in ipairs(booster.picks) do
        local card = booster.cards[i]
        if pick.card.display and pick.card.display > 0 and not pick.card.art then
            assert(card.openingModel and card.model.testDisplay == pick.card.display)
            assert(card.model.artworkWindow == card.art and card.model.anchor[2] == UIParent and card.model:IsShown())
            shownModels = shownModels + 1
        end
    end
    assert(shownModels > 0)
    if stock == 0 then
        local source
        for _, card in ipairs(booster.cards) do
            if card.revealed and card.openingModel then source = card; break end
        end
        assert(source and source.model:IsShown())
        local display = source.pick.card.display
        local portrait = ns.Portraits[display]
        ns.Portraits[display] = {0, 1, 0, 1}
        booster:Inspect(source)
        stepFrames(45)
        local inspect = booster.frame.inspect
        assert(inspect:IsShown() and inspect.info.name:GetText() ~= "")
        assert(inspect.card.model.testDisplay == display and inspect.card.model:IsShown())
        assert(inspect.card.model.artworkWindow == inspect.card.art and inspect.card.model.anchor[2] == UIParent)
        assert(not inspect.card.held and not inspect.card.see3D:IsShown())
        assert(not source.model:IsShown())
        click(inspect.back)
        assert(inspect:IsShown() and not source.model:IsShown())
        stepFrames(12)
        assert(not inspect:IsShown() and source.model:IsShown() and source.model.testDisplay == display)
        ns.Portraits[display] = portrait
    end
    assert(not booster.frame.again:IsShown())
    booster:Again()
    assert(booster.state == "done" and booster.opts.test)
    assert(ns.Packs(series) == stock and ns.Level:XP() == xp)
    assert(ns.Seal({ cards = ns.db.cards }) == collection)
    click(booster.frame.album)
    assert(not booster:Showing() and album.frame:IsShown() and album.mode == "boosters")
end
ns.db.packs[series.key] = nil
album:Hide()
""")






lua.execute(r"""
local ns = CuratorOctoFull
ns.Wire:Raw("WHISPER", "Collector", "probe")
assert(lastMessage[2] == "probe" and lastMessage[3] == "WHISPER" and lastMessage[4] == "Collector")
""")
print("Test button opens and returns from a preview at zero or positive stock; legacy addon message routed in mock")


lua.execute(r"""
local ns = CuratorOctoFull
zone = "Northwind"
local found = {}
local old = ns.Rewards.Add
ns.Rewards.Add = function(_, series, points, reason)
    assert(series.key == "northwind")
    found[reason] = (found[reason] or 0) + 1
    assert(points > 0)
end
assert(traceEvent("CHAT_MSG_SYSTEM", "A quest completed.") == "")
assert(traceEvent("UI_INFO_MESSAGE", "A quest completed.") == "")
assert(traceEvent("CHAT_MSG_SYSTEM", "Discovered: A Place") == "")
assert(traceEvent("UI_INFO_MESSAGE", "Discovered: A Place") == "")
assert(found.quest == 1 and found.explore == 1)
ns.Rewards.Add = old
""")
print("Legacy quest and discovery messages credited once")




lua.execute(r"""
local ns = CuratorOctoFull
assert(not ns.Beta:Elsewhere())
local build = GetBuildInfo
GetBuildInfo = function() return "1.12.1", "5875" end
assert(not ns.Beta:Elsewhere())
GetBuildInfo = function() return "1.15.0", "70000", "", 11500 end
assert(ns.Beta:Elsewhere())
GetBuildInfo = build
local place
local bound = ns.Tavern.Bound
ns.Tavern.Bound = function(_, value) place = value end
assert(traceEvent("CHAT_MSG_SYSTEM", "Test Inn is now your home.") == "")
assert(place == "Test Inn", tostring(place))
ns.Tavern.Bound = bound
assert(table.getn(ns.Pvp:Patterns()) > 0)
assert(ns.Options:Panel())
assert(ns.Skin.Window("CuratorTestWindow", 400, 320))
SlashCmdList.CURATOR("")
assert(ns.Album.frame and ns.Album.frame:IsShown())
""")
print("Hearthstone message, options panel and /curator verified with legacy APIs")

lua.execute(r"""
local ns = CuratorOctoFull
zone = "Windrock Cliffs"
assert(ns.Rewards:ZoneSeries().key == "balor")
for _, key in ipairs({"zephras", "dalaran", "thanes", "lordaeron", "excavation", "hardcup"}) do
    assert(not ns.SeriesByKey(key), key)
end
for _, id in ipairs({"beta", "pioneer"}) do
    assert(not ns.Achievements:Shown(ns.Achievements.byId[id], {[id]=true}))
end
assert(not ns.SiteWindow.TellBetaEnd and not ns.Album.BetaMark)
local seal = ns.Seal(ns.db)
SlashCmdList.CURATOR("bar width 240")
assert(ns.db.barWidth == 240 and ns.BoosterBar:DisplayWidth() == 240)
local bar = ns.BoosterBar.frame
this, arg1 = bar, -1
bar:GetScript("OnMouseWheel")()
assert(ns.db.barWidth == 210)
assert(ns.Seal(ns.db) == seal)
SlashCmdList.CURATOR("bar reset")
assert(not ns.db.barWidth)
ns.Album:ShowBoosters()
local page = ns.Album.frame.boost
assert(page:IsShown() and page.grid:IsShown() and not page.pick:IsShown())
ns.Album:Hide()
assert(not ns.Album.frame:IsShown())
""")
print("Balor, catalogue exclusions, retired achievements and adjustable bar verified")

lua.execute(r"""
local ns = CuratorOctoFull
local commands = {"inventory", "achievements", "quests", "talents", "inns", "leads",
    "pvp", "boosters", "profile", "level", "rewards", "golden", "search", "gift",
    "main", "chest", "stats", "live", "news", "alerts", "cases", "contract",
    "trade", "duel", "discovery", "social", "options", "rubies", "antiquarian", "counter"}
local failed = {}
for _, command in ipairs(commands) do
    local ok, err = pcall(SlashCmdList.CURATOR, command)
    if not ok then table.insert(failed, command .. ": " .. tostring(err)) end
end
assert(table.getn(failed) == 0, table.concat(failed, "\n"))
local frame = CreateFrame("Frame")
local order = {}
frame:SetScript("OnUpdate", function() table.insert(order, "original") end)
ns.HookScript(frame, "OnUpdate", function(self, elapsed)
    assert(self == frame and elapsed == .05)
    table.insert(order, "hook")
end)
this, arg1 = frame, .05
frame:GetScript("OnUpdate")()
assert(table.concat(order, ",") == "original,hook")
""")
print("Thirty UI commands and legacy event chaining verified")

lua.execute(r"""
local ns = CuratorOctoFull
local album = ns.Album
local function countCards()
    local count = 0
    for _, slot in ipairs(album.frame.slots) do
        if slot:IsShown() and slot.card then count = count + 1 end
    end
    return count
end
local balor = ns.SeriesByKey("balor")
local harelyss
for _, card in ipairs(balor.list) do
    if card.npc == 62317 then harelyss = card end
end
assert(harelyss and harelyss.display == 2737)
album:ShowSeries(balor)
assert(album.page == 1 and countCards() > 0)
local first = countCards()
local total = first
for page = 2, math.ceil(57 / first) do
    album:Page(1)
    stepFrames(60)
    assert(album.page == page and countCards() > 0)
    total = total + countCards()
end
assert(total == 57)
for page = album.page - 1, 1, -1 do
    album:Page(-1)
    stepFrames(60)
    assert(album.page == page)
end
assert(album.page == 1 and countCards() == first)
album:ShowSeries(ns.SeriesByKey("elwynn"))
local slot = album.frame.slots[1]
assert(slot:IsShown() and slot.card)
local testCard = {}
for key, value in pairs(slot.card) do testCard[key] = value end
testCard.display = 1974
ns.Portraits[1974] = nil
slot:SetCard(testCard, { owned = true })
assert(slot.model.testDisplay == 1974 and slot.model.loaded)
ns.ReframeCards()
testCard.display = 0
slot:SetCard(testCard, { owned = true })
assert(not slot.model.testDisplay)
for _, series in ipairs(ns.Series) do
    if series.list and table.getn(series.list) > 0 then
        local ok, err = pcall(album.ShowSeries, album, series)
        assert(ok, series.key .. ": " .. tostring(err))
        assert(countCards() > 0, series.key)
    end
end
""")
print("All 57 Balor cards, every album's first page and optional model controls verified")

lua.execute(r"""
local ns = CuratorOctoFull
local inns, ui, gossip, tavern = ns.Inns, ns.InnsUI, ns.Gossip, ns.TavernUI
local npc = 6740
local parent = CreateFrame("Frame", nil, UIParent)
parent:SetScale(.75)
local icon = parent:CreateTexture()
assert(ns.GetEffectiveScale(icon) == parent:GetEffectiveScale())
local x, y = ns.Hud.Where(icon)
assert(x == 384 and y == 288)
local flight = false
ns.Hud.Fly("test", icon, parent, 30, .25, function() flight = true end)
stepFrames(20)
assert(flight)

GetServerTime = function() return 0 end
assert(ns.IsCalendarTime(ns.ServerTime()))
local state = inns:State()
state.day = 24
state.visas[npc] = { t = 0, p = "Stormwind City" }
ui:PaintLine2(npc)
assert(inns:StampedToday() and state.day == inns:Today())
assert(not string.find(ui.panel.line2:GetText(), "1970", 1, true))
state.day = nil
state.visas[npc] = nil
local oldNpcId = gossip.NpcId
gossip.NpcId = function() return npc end
GossipFrame = CreateFrame("Frame", "GossipFrame", UIParent)
assert(traceEvent("GOSSIP_SHOW") == "")
stepFrames(8)
assert(ui.panel:IsShown() and gossip.panel:IsShown())
local background = gossip.panel.textures[1]
assert(background.drawLayer == "BACKGROUND" and background.textureAlpha == 1)
local function checkCounterAnchor(relative)
    local anchor = ui.panel.anchor
    assert(anchor[1] == "TOPLEFT" and anchor[2] == relative and anchor[3] == "TOPRIGHT" and anchor[4] > 0)
end
checkCounterAnchor(gossip.panel)
gossip.panel:Hide()
ui.Place(ui.panel)
checkCounterAnchor(GossipFrame)
gossip:Refresh()
assert(gossip.panel:IsShown())
checkCounterAnchor(gossip.panel)
assert(ns.IsCalendarTime(state.visas[npc].t))
assert(ui:Open(npc, true))
stepFrames(120)
assert(inns:StampedToday() and ns.IsCalendarTime(state.card[1].t))
tavern:OpenBet(npc)
assert(tavern:IsBetOpen() and not gossip.panel:IsShown() and not ui.panel:IsShown())
gossip:Refresh()
assert(not gossip.panel:IsShown())
tavern.frame:Hide()
assert(ui.panel:IsShown() and gossip.panel:IsShown())
checkCounterAnchor(gossip.panel)
tavern:OpenBet(npc)
gossip:Close()
tavern.frame:Hide()
assert(not ui.panel:IsShown() and not gossip.panel:IsShown())
gossip.NpcId, GetServerTime = oldNpcId, nil
GossipFrame = nil
""")
print("Allison: legacy texture flight, dates, stamp, bet and side-by-side window anchors verified")

lua.execute(r"""
local ns = CuratorOctoFull
local gossip = ns.Gossip
GossipFrame = CreateFrame("Frame", "GossipFrame", UIParent)
GossipGreetingScrollFrame = CreateFrame("ScrollFrame", nil, GossipFrame)
GossipGreetingScrollChildFrame = CreateFrame("Frame", nil, GossipGreetingScrollFrame)
GossipGreetingText = GossipGreetingScrollChildFrame:CreateFontString()
GossipSpacerFrame = CreateFrame("Frame", nil, GossipGreetingScrollChildFrame)
GossipTitleButton1 = CreateFrame("Button", "GossipTitleButton1", GossipGreetingScrollChildFrame, "GossipTitleButtonTemplate")
GossipResize = function(button) button:SetHeight(18) end
local stockClick = function() end
GossipTitleButton1:SetScript("OnClick", stockClick)
GossipTitleButton1:SetID(1)
GossipFrameUpdate = function()
    GossipFrame.buttonIndex = 2
    GossipGreetingText:SetText("Welcome")
    GossipTitleButton1:SetText("Browse goods")
end
assert(gossip:Hook())
local oldNpcId = gossip.NpcId
gossip.NpcId = function() return 6740 end
assert(traceEvent("GOSSIP_SHOW") == "")
assert(gossip.legacyShown and gossip.legacyRows[1]:IsShown())
assert(not gossip.panel:IsShown())
assert(gossip.legacyRows[1]:GetParent() == GossipGreetingScrollChildFrame)
assert(gossip.legacyRows[1].anchor[2] == GossipTitleButton1)
assert(GossipTitleButton1:GetText() == "Browse goods" and GossipTitleButton1:GetScript("OnClick") == stockClick)
local clicked = false
local originalClick = gossip.Click
gossip.Click = function(_, line) clicked = line == gossip.legacyRows[1].curatorLine end
this = gossip.legacyRows[1]
this:GetScript("OnClick")()
assert(clicked)
gossip.Click = originalClick
local count = table.getn(gossip.legacyRows)
gossip:Say("Hello collector")
gossip:Refresh()
assert(GossipGreetingText:GetText() == "Welcome\n\nHello collector")
assert(table.getn(gossip.legacyRows) == count and GossipFrame.buttonIndex == 2)
DUIQuestFrame = CreateFrame("Frame", "DUIQuestFrame", UIParent)
gossip:Refresh()
assert(not gossip.legacyRows[1]:IsShown() and gossip.panel:IsShown())
DUIQuestFrame:Hide()
gossip:Refresh()
assert(gossip.legacyRows[1]:IsShown() and not gossip.panel:IsShown())
assert(traceEvent("GOSSIP_CLOSED") == "")
assert(not gossip.legacyRows[1]:IsShown())
gossip.NpcId = oldNpcId
""")
print("Native inn gossip: stock buttons, Curator clicks, refresh and opaque fallback verified")

lua.execute(r"""
local ns = CuratorOctoFull
local crate = ns.CrateUI
local before = ns.Cases:Count("paladin1")
crate:Show("paladin1")
local spells = { PalArtHolyLight = true, PalArtLayOnHands = true,
    PalArtKings = true, PalArtHolyShield = true }
for row = 0, crate.itemRows - 1 do
    for _, tile in ipairs(crate.frame.items) do
        local entry = tile.pick and tile.pick.entry
        if tile:IsShown() and entry and spells[entry.pic] then
            assert(tile.art:IsShown() and tile.art.textureFile == ns.MEDIA .. entry.pic)
            assert(tile.ground.drawLayer == "BACKGROUND" and tile.art.drawLayer == "BORDER")
            assert(tile.light.drawLayer == "ARTWORK" and tile.edge.drawLayer == "OVERLAY")
            spells[entry.pic] = nil
        end
    end
    crate:ScrollItems(1)
end
assert(next(spells) == nil)
assert(ns.Cases:Count("paladin1") == before)
crate.frame:Hide()
""")
print("Paladin case: all four affected previews load over their backgrounds")

lua.execute(r"""
local ns = CuratorOctoFull
local ledger = ns.Rubies.Ledger
local log = { { n = 10, t = 0 }, { n = 14, t = ns.ServerTime() - 3600 }, { n = 20, t = ns.ServerTime() } }
ns.Rubies.Ledger = function() return log end
ns.RubiesUI:OpenShop(nil, "ledger")
local shop = ns.RubiesUI.shop
assert(shop:IsShown())
assertOpaqueBackground(shop.textures[1])
local rows = shop.ledger.rows
assert(rows[1].when:GetText() == ns.L["now"])
assert(rows[2].when:GetText() == string.format(ns.L["%s ago"], ns.Duration(3600)))
assert(rows[3].when:GetText() == "—" and rows[3].n:GetText() == "+10" and log[1].t == 0)
ns.Rubies.Ledger = ledger
shop:Hide()
""")
print("Ruby ledger: opaque background and valid elapsed times verified")

lua.execute(r"""
local oldBank = BankFrame
BankFrame = CreateFrame("Frame", "BankFrame", UIParent)
BankFrame:Show()
assert(traceEvent("BANKFRAME_OPENED") == "")
assert(CuratorBankPanel.anchor[2] == BankFrame)
assert(CuratorCasePanel.anchor[2] == CuratorBankPanel)
for _, panel in ipairs({ CuratorBankPanel, CuratorCasePanel }) do
    assert(panel:IsShown())
    assertOpaqueBackground(panel.textures[1])
end
assert(traceEvent("BANKFRAME_CLOSED") == "")
assert(not CuratorBankPanel:IsShown() and not CuratorCasePanel:IsShown())
BankFrame = oldBank
""")
print("Bank: opaque appraisal and protective cases panels verified on open and close")

lua.execute(r"""
local ns = CuratorOctoFull
local rewards = ns.Rewards
local character = rewards:Char()
local baseLevel, baseMap, baseExploration = UnitLevel, C_Map, C_MapExplorationInfo
UnitLevel = function() return 37 end
zone = "Balor"
local log = {}
local add, fill = rewards.Add, rewards.Fill
rewards.Fill = function(_, series, points, reason, daily, account)
    table.insert(log, { series, points, reason, daily, account })
end
character.octoPlaces = { ["Windrock Cliffs"] = true }
rewards:OctoLevelUp(37)
assert(table.getn(log) == 1 and log[1][2] == 40)
rewards:OctoLevelUp(37)
assert(table.getn(log) == 1)
C_Map = { GetAreaInfo = function(id)
    return ({ [101] = "windrock cliffs", [102] = "Other Balor location", [103] = "Shared feature" })[id]
end }
C_MapExplorationInfo = { GetExploredMapTextures = function(id)
    if id ~= 5561 then return {} end
    return { { areaID = 101, areaIDs = {101} }, { areaID = 102, areaIDs = {102} },
        { areaID = 102, areaIDs = {102} }, { areaID = 103, areaIDs = {103, 104} } }
end }
assert(rewards:ApplyCatchUp(rewards:PlanCatchUp("30"), true))
assert(table.getn(log) == 3)
assert(log[2][1] == nil and log[2][2] == 240 and log[2][5] == true)
assert(log[3][1].key == "balor" and log[3][2] == 10 and rewards:Visited(log[3][1]))
assert(rewards:ApplyCatchUp(rewards:PlanCatchUp(), true))
assert(traceEvent("CHAT_MSG_SYSTEM", "Discovered: Other Balor location") == "")
assert(table.getn(log) == 3)
rewards.Add, rewards.Fill = add, fill
ns.db.bar = 0
local offers = ns.Level:OfferCount()
UnitLevel = function() return 40 end
assert(rewards:ApplyCatchUp(rewards:PlanCatchUp(), true))
assert(ns.Level:OfferCount() == offers + 1 and ns.db.bar == 20)
assert(rewards:ApplyCatchUp(rewards:PlanCatchUp(), true))
assert(ns.Level:OfferCount() == offers + 1 and ns.db.bar == 20)
UnitLevel, C_Map, C_MapExplorationInfo = baseLevel, baseMap, baseExploration
""")
print("Catch-up: level cutoff, officially explored areas and duplicate prevention verified")

lua.execute(r"""
local ns = CuratorOctoFull
local oldLevel, oldMap, oldExploration = UnitLevel, C_Map, C_MapExplorationInfo
UnitLevel = function() return 37 end
C_Map = { GetAreaInfo = function() return "Previously explored in Balor" end }
C_MapExplorationInfo = { GetExploredMapTextures = function(area)
    if area == 5561 then return { { areaID = 5562, areaIDs = {5562} } } end
    return {}
end }
CuratorOctoCatchUpDB, ns.db.chars, ns.db.bar = nil, {}, 0
local offers = ns.Level:OfferCount()
local function assertCredit()
    assert(ns.Level:OfferCount() == offers + 14 and ns.db.bar == 50)
    local saved = CuratorOctoCatchUpDB
    assert(saved.octoLevelCredits[2] and saved.octoLevelCredits[37] and saved.octoExploredAreas[5562])
end
assert(ns.Rewards:ApplyCatchUp(ns.Rewards:PlanCatchUp(), true))
assertCredit()
local saved = CuratorOctoCatchUpDB
ns.db.chars = {}
assert(ns.Rewards:ApplyCatchUp(ns.Rewards:PlanCatchUp(), true))
assert(CuratorOctoCatchUpDB == saved)
assertCredit()
CuratorOctoCatchUpDB = nil
assert(ns.Rewards:ApplyCatchUp(ns.Rewards:PlanCatchUp(), true))
assertCredit()
UnitLevel, C_Map, C_MapExplorationInfo = oldLevel, oldMap, oldExploration
""")
print("Catch-up: fresh level 37 receives 14 offers and the ledger survives loss of either copy")

lua.execute(r"""
local ns = CuratorOctoFull
local oldLocale, oldLanguage, oldLevel = ns.locale, ns.db.lang, UnitLevel
local oldCache, oldChars = CuratorOctoCatchUpDB, ns.db.chars
local function click(button)
    this = button
    button:GetScript("OnClick")()
end
local function configure()
    CuratorOctoCatchUpDB, ns.db.chars, ns.db.bar = nil, {}, 0
    SlashCmdList.CURATOR("rattrapage")
    return CuratorCatchUpPanel
end
UnitLevel = function() return 4 end
ns.db.lang = "frFR"
ns.ApplyLanguage()
assert(ns.locale == "frFR")
local f = configure()
assert(f:IsShown() and f.TitleText:GetText() == "Rattrapage de progression")
assert(f.rows[1].value:GetText() == "3" and f.rows[5].value:GetText() == "120")
assert(f.rows[6].value:GetText() == "1" and f.rows[8].value:GetText() == "20%")
local offers = ns.Level:OfferCount()
click(f.right)
assert(f.decision == "take" and f.right:GetText() == "Confirmer la récupération")
assert(ns.Level:OfferCount() == offers and ns.db.bar == 0)
click(f.right)
assert(not f:IsShown() and ns.Level:OfferCount() == offers + 1 and ns.db.bar == 20)
ns.db.lang = "enUS"
ns.ApplyLanguage()
assert(ns.locale == "enUS")
f = configure()
assert(f.TitleText:GetText() == "Progress catch-up")
click(f.left)
assert(f.decision == "skip" and f.right:GetText() == "Confirm refusal")
click(f.left)
assert(not f.decision)
click(f.left)
click(f.right)
assert(not f:IsShown() and ns.Level:OfferCount() == offers + 1 and ns.db.bar == 0)
SlashCmdList.CURATOR("rattrapage")
assert(f.rows[1].value:GetText() == "0" and not f.right:IsShown())
f:Hide()
ns.SetLocale(oldLocale)
ns.db.lang, UnitLevel = oldLanguage, oldLevel
CuratorOctoCatchUpDB, ns.db.chars = oldCache, oldChars

local rb, rates = ns.Rubies, ns.Talents.RubyDiscount
ns.Talents.RubyDiscount = function() return 0 end
assert(rb:Price(999, "key") == 250 and ns.Cases:KeyPrice() == 250)
assert(rb:Price(999, "restore") == 500 and rb:Price(0, "pack") == 0)
assert(ns.Displays:Price(ns.SeriesByKey("elwynn")) == 17500)
assert(ns.Talents:OrderPrice({ rarity = 1 }) == 1000)
assert(ns.Reseller:BuyBackPrice({ p = 50 }) == 25)
assert(ns.Reseller:BuyBackPrice({ p = 25, octoPrice = true }) == 25)
ns.Talents.RubyDiscount = function() return 0.15 end
assert(ns.Cases:KeyPrice() == 212)
ns.Talents.RubyDiscount = rates
""")
print("Catch-up panel: both languages, confirmation of claim/refusal and revised ruby prices verified")

lua.execute(r"""
local oldLocale = GetLocale
CuratorOctoGallery = { { name = "Balor", path = "balor", cards = { 62317 } } }
CuratorOctoGalleryLanguage = nil
assert(loadfile("source/Galerie.lua"))()
local gallery = CuratorOctoGalerieFrame
GetLocale = function() return "enUS" end
SlashCmdList.CURATOROCTOGALERIE()
assert(string.find(gallery.textures[1].textureFile, "Cartes-en", 1, true))
SlashCmdList.CURATOROCTOGALERIE()
GetLocale = function() return "frFR" end
SlashCmdList.CURATOROCTOGALERIE()
assert(string.find(gallery.textures[1].textureFile, "Cartes\\", 1, true))
GetLocale = oldLocale
""")
print("Gallery: French and English artworks selected correctly")

lua.execute(r"""
local ns = CuratorOctoFull
local toast = ns.Toast
toast:Hold()
toast.queue = {}
ns.Fire("INN_VISA", 6740, 3)
toast:Step(.2)
assert(toast.state == "hold")
assert(toast.frame.loot.label:GetText() == string.format(ns.L["New visa: %d"], 3))
assertOpaqueBackground(toast.frame.loot.bg)
local oldShowInns = ns.Album.ShowInns
local opened = false
ns.Album.ShowInns = function() opened = true end
this, arg1 = toast.frame, "LeftButton"
toast.frame:GetScript("OnClick")()
assert(opened and not toast.frame:IsShown())
ns.Album.ShowInns = oldShowInns
""")
print("Visa alert: opaque backdrop and passport click verified")

lua.execute(r"""
local ns = CuratorOctoFull
local toast = ns.Toast
local balor = ns.SeriesByKey("balor")
ns.Fire("PACK_EARNED", balor, 1, "explore", true)
toast:Step(.2)
assert(toast.state == "hold" and toast.frame.loot:IsShown())
assert(toast.frame.loot.label:GetText() == ns.L["Booster earned"])
assert(toast.frame.loot.name:GetText() == ns.Collection:SeriesName(balor))
assertOpaqueBackground(toast.frame.loot.bg)
local oldOpen = ns.OpenBooster
local opened
ns.OpenBooster = function(options) opened = options.series end
this, arg1 = toast.frame, "LeftButton"
toast.frame:GetScript("OnClick")()
assert(opened == balor and not toast.frame:IsShown())
ns.OpenBooster = oldOpen

toast:Push({ title = "Test", name = "Achievement", icon = { "StampRing" } })
assert(toast.frame.ach:IsShown() and not toast.frame.loot:IsShown())
assertOpaqueBackground(toast.frame.ach.bg)
toast:Next(true)

ns.Live:Build()
assertOpaqueBackground(ns.Live.frame.bg)
assertOpaqueBackground(ns.Live.mover.toast.textures[1])
assertOpaqueBackground(ns.Live.mover.live.textures[1])
assertOpaqueBackground(ns.Search:Build().textures[1])
assertOpaqueBackground(ns.RestoreUI:Panel().textures[1])
ns.CopiesUI:OpenPicker({ card = balor.list[1] })
assertOpaqueBackground(ns.CopiesUI.picker.textures[1])
ns.CopiesUI:ClosePicker()
""")
print("Booster, achievement and guild alerts plus related legacy panels use opaque client textures")

lua.execute(r"""
local ns = CuratorOctoFull
local album = ns.Album
local f, u = album.frame, album.U
assert(f.CloseButton.anchor[5] == u.HEADER_Y and f.TitleText.anchor[5] == u.HEADER_Y)
assert(f.wallet.anchor[2] == f.CloseButton and f.gear.anchor[2] == f.wallet and f.save.anchor[2] == f.gear)
assert(f.tourButton.anchor[5] == u.HEADER_Y and f.tourButton.caption:GetText() == "Guide")
assert(f.tourButton.i.textureFile == "Interface\\Icons\\INV_Misc_Book_09")
assert(f.bar.anchor[5] == u.PROGRESS_Y and f.goldBar.anchor[5] == u.PROGRESS_Y)
assert(u.HEADER_Y - 12 > u.PROGRESS_Y + 9 and -u.HEAD < u.SUB_Y - 12)

SlashCmdList.CURATOR("achievements")
assert(f.aBar:IsShown() and not f.qXP:IsShown())
assert(f.aBar.anchor[5] == u.PROGRESS_Y and f.aNote.anchor[5] == u.SUB_Y)
SlashCmdList.CURATOR("quests")
assert(f.qXP:IsShown() and not f.aBar:IsShown())
assert(f.qXP.anchor[5] == u.PROGRESS_Y and f.qNote.anchor[5] == u.SUB_Y)
album:ShowSeries(ns.SeriesByKey("balor"))
assert(not f.aBar:IsShown() and not f.qXP:IsShown() and f.bar:IsShown())
assert(f.sub.anchor[3] == u.SUB_Y)

local tour = ns.Tour
if tour.active then tour:Stop() end
this, arg1 = f.tourButton, "LeftButton"
f.tourButton:GetScript("OnClick")()
assert(tour.active)
this, arg1 = f.tourButton, "LeftButton"
f.tourButton:GetScript("OnClick")()
assert(not tour.active)
""")
print("Album header: toolbar, progress rows, album navigation and Guide button verified")

lua.execute(r"""
local ns = CuratorOctoFull
local menu, entry = TestPortraitDropDown, "CURATOR_TRADE"
local oldName, oldFaction, oldExists, oldPlayer, oldSame = UnitName, UnitFactionGroup, UnitExists, UnitIsPlayer, UnitIsUnit
local units = { player = "Tester", target = "Brindille Dupont", party1 = "Hector Dubois",
    raid1 = "Lea Martin", enemy = "Enemy", pet = "Fang" }
UnitName = function(unit) return units[unit] or oldName(unit) end
UnitExists = function(unit) return units[unit] ~= nil end
UnitIsPlayer = function(unit) return unit ~= "pet" end
UnitIsUnit = function(a, b) return a == b end
UnitFactionGroup = function(unit) return unit == "enemy" and "Horde" or "Alliance" end
local function show(which, unit)
    menu.which, menu.unit = which, unit
    UnitPopup_HideButtons()
end
assert(table.concat(UnitPopupMenus.PLAYER, ",") == "WHISPER,TRADE,CURATOR_TRADE,FOLLOW,CANCEL")
assert(table.concat(UnitPopupMenus.PARTY, ",") == "TRADE,CURATOR_TRADE,CANCEL")
assert(table.concat(UnitPopupMenus.RAID, ",") == "RAID_REMOVE,CURATOR_TRADE,CANCEL")
assert(table.getn(UnitPopupMenus.SELF) == 1 and table.getn(UnitPopupMenus.PET) == 1)
local option = UnitPopupButtons[entry]
assert(option.dist == 0 and option.color.b == 1 and option.color.r == 0)
local invite, opened = ns.LiveTradeUI.Invite
ns.LiveTradeUI.Invite = function(self, name) opened = name end
local function click(value)
    this = { value = value }
    return UnitPopup_OnClick()
end
assert(click("TRADE") == "TRADE" and not opened)
local locale = ns.locale
ns.SetLocale("frFR")
show("PLAYER", "target")
assert(option.text == "Échange (Curator)" and UnitPopupShown[1][3] == 1)
click(entry)
assert(opened == "Brindille-Dupont")
opened = nil
units.target = "Other Player"
click(entry)
assert(not opened)
ns.SetLocale("enUS")
show("PARTY", "party1")
assert(option.text == "Trade (Curator)" and UnitPopupShown[1][2] == 1)
click(entry)
assert(opened == "Hector-Dubois")
show("RAID", "raid1")
click(entry)
assert(opened == "Lea-Martin")
for _, unit in ipairs({ "player", "pet", "enemy", "missing" }) do
    show("PLAYER", unit)
    assert(UnitPopupShown[1][3] == 0)
end
ns.SetLocale(locale)
ns.LiveTradeUI.Invite = invite
units.target = "Brindille Dupont"
show("PLAYER", "target")
click(entry)
assert(ns.Album.ed.draft.with == "Brindille-Dupont")
ns.Album:CloseTrade()
UnitName, UnitFactionGroup, UnitExists, UnitIsPlayer, UnitIsUnit = oldName, oldFaction, oldExists, oldPlayer, oldSame
""")
print("Portrait trades: native trade preserved, localized blue entry invites the correct player")

lua.execute(r"""
local ns = CuratorOctoFull
local live, album, wire, trade = ns.LiveTrade, ns.Album, ns.Wire, ns.Trade
local oldSend, oldDrop, oldTrades = wire.Send, wire.Drop, ns.db.trades
local messages = {}
wire.Send = function(_, who, body)
    table.insert(messages, { who = who, body = body })
    return tostring(table.getn(messages))
end
wire.Drop = function() end
ns.db.trades = {}
local function receive(body, sender)
    ns.Guild:OnMessage("T:1:" .. body, "WHISPER", sender)
end
local function click(button)
    this, arg1 = button, "LeftButton"
    button:GetScript("OnClick")()
end
local function last()
    return messages[table.getn(messages)].body
end
local card = ns.SeriesByKey("balor").list[1]
local packs = ns.Packs(card.series)
ns.AddPacks(card.series, 1)
ns.Collection:Add(card)
local owned = ns.Collection:Entry(card).n
assert(live:Invite("Brindille Dupont"))
local host = live.current
assert(string.find(last(), "/" .. "I/", 1, true) and host.state == "waiting")
local ed = album.frame.soc.ed
assert(not ed.give.add:IsShown() and not ed.take.add:IsShown())
receive("L/" .. host.id .. "/A/", "Other Person")
assert(host.state == "waiting")
receive("L/" .. host.id .. "/A/", "Brindille Dupont")
assert(host.state == "open" and ed.give.add:IsShown() and not ed.take.add:IsShown())
album:OpenTradePicker("give")
album:PickClick({ entry = { card = card, n = 1 } })
album:CloseTradePicker()
stepFrames(8)
assert(string.find(last(), "/U/1/" .. card.npc, 1, true))
assert(ns.Collection:Entry(card).n == owned and ns.Packs(card.series) == packs + 1)
receive("L/" .. host.id .. "/U/2/@" .. card.series.key, "Brindille Dupont")
receive("L/" .. host.id .. "/U/1/", "Brindille Dupont")
assert(host.remoteRev == 2 and host.take[1].b == card.series.key and ed.take.slots[1]:IsShown())
assert(not ed.take.slots[1].editing)
receive("L/" .. host.id .. "/U/3/", "Brindille Dupont")
assert(host.remoteRev == 3 and not ed.take.slots[1]:IsShown())
receive("L/" .. host.id .. "/U/4/@" .. card.series.key, "Brindille Dupont")
click(ed.main)
local rec = trade:Get(album.ed.id)
assert(not live.current and rec and rec.live == host.id and rec.st == "out")
local offer = last()
assert(string.find(offer, "/" .. host.id, 1, true))
assert(ns.Collection:Entry(card).n == owned and ns.Packs(card.series) == packs + 1)

ns.db.trades = {}
receive("L/" .. host.id .. "/I/", "Other Person")
local dialog = CuratorLiveTradeInvitation
assert(dialog:IsShown() and live.current.state == "invited" and not album.ed.live)
click(dialog.accept)
local guest = live.current
assert(guest.state == "open" and not guest.host and not dialog:IsShown())
assert(not ed.main:IsShown() and ed.give.add:IsShown())
receive("L/" .. host.id .. "/U/1/" .. card.npc, "Other Person")
assert(guest.take[1].k == card.key and ed.take.slots[1]:IsShown())
receive(string.sub(offer, 5), "Other Person")
local incoming = trade:Get(album.ed.id)
assert(not live.current and incoming and incoming.st == "in" and incoming.live == host.id)
assert(ed.main.action == "accept" and ns.Packs(card.series) == packs + 1)
click(ed.main)
assert(incoming.st == "acc" and ns.Packs(card.series) == packs)

receive("L/declineTest/I/", "Other Person")
click(dialog.refuse)
assert(not live.current and not dialog:IsShown() and string.find(last(), "/C/declined", 1, true))
wire.Send, wire.Drop, ns.db.trades = oldSend, oldDrop, oldTrades
""")
print("Live trade: invitation, bilateral preview, replay protection and explicit final acceptance verified")

lua.execute(r"""
local ns = CuratorOctoFull
ns.Album:Hide()
assert(table.getn(unitTooltipCallbacks) == 1 and unitTooltipCallbacks[1] == ns.Talents.OnCreatureTooltip)
local tip = GameTooltip
local oldUnit, oldLine = tip.GetUnit, tip.AddLine
local oldExists, oldPlayer, oldSame, oldName = UnitExists, UnitIsPlayer, UnitIsUnit, UnitName
local oldAsk, oldProfile = ns.Guild.Ask, ns.Guild.Profile
local lines, asks = {}, 0
local unit = "player"
UnitExists = function() return true end
UnitIsPlayer = function() return true end
UnitIsUnit = function(a, b) return a == b end
UnitName = function(u) return u == "player" and "Tester" or "Other Person" end
tip.GetUnit = function() return UnitName(unit), unit end
tip.AddLine = function(_, line) table.insert(lines, line) end
ns.Guild.Ask = function() asks = asks + 1 end
ns.Guild.Profile = function() return { owned = 113, points = 70, xp = 1000 }, false end
tip:Show()
tip:AddLine("Player")
for _, target in ipairs({ "player", "target" }) do
    unit = target
    for _, callback in ipairs(unitTooltipCallbacks) do callback(tip) end
end
ns.Fire("PLAYER_INFO", "Other-Person")
assert(table.getn(lines) == 1 and lines[1] == "Player" and asks == 0)
tip.GetUnit, tip.AddLine = oldUnit, oldLine
UnitExists, UnitIsPlayer, UnitIsUnit, UnitName = oldExists, oldPlayer, oldSame, oldName
ns.Guild.Ask, ns.Guild.Profile = oldAsk, oldProfile
""")
print("Stock player tooltips stay unchanged, including after player profile messages")

lua.execute(r"""
local ns = CuratorOctoFull
local rewards, board = ns.Rewards, ns.Quests
UnitLevel = function() return 4 end
CuratorOctoCatchUpDB, ns.db.chars, ns.db.bar = nil, {}, 20
local character = rewards:Char()
character.octoLevelFloor, character.octoCatchUpDecided = 4, true
character.quests[4001] = true
character.octoQuests = { ["Previously credited by title"] = true }
local history = { [4001] = true, [4002] = true, [4003] = true, ["4003"] = true,
    [4004] = 1, [4005] = true, [4006] = true, [4007] = false }
QuestieOcto = {
    Completion = { ready = true, history = history },
    DatabaseAPI = { GetQuestTitle = function(_, id)
        if id == 4002 then return "Previously credited by title" end
        return "Test title " .. id
    end },
}
local q = { k = "quest", n = 5, got = 1 }
local kill = { k = "kill", n = 1, got = 0 }
ns.db.quests = { daily = { list = { q, kill } } }
board.checked = GetTime()
local earned = ns.Stats().q_day or 0
local plan = rewards:PlanCatchUp()
assert(plan.decided and not plan.questsDecided and plan.questsScanned)
assert(table.getn(plan.quests) == 4 and plan.quests[1] == 4003 and plan.quests[4] == 4006)
assert(plan.questTasks == 1 and plan.points == 80 and plan.offers == 1 and plan.bar == 0)
local offers = ns.Level:OfferCount()
rewards:OpenCatchUp("", true)
local panel = CuratorCatchUpPanel
assert(panel:IsShown() and panel.rows[3].value:GetText() == "4" and panel.rows[4].value:GetText() == "1")
local function click(button)
    this = button
    button:GetScript("OnClick")()
end
click(panel.right)
assert(not q.done and ns.Level:OfferCount() == offers)
click(panel.right)
assert(q.done and q.got == 5 and kill.got == 0 and ns.Stats().q_day == earned + 1)
assert(ns.Level:OfferCount() == offers + 1 and not panel:IsShown())
assert(CuratorOctoCatchUpDB.quests[4002] and CuratorOctoCatchUpDB.quests[4006])
local ruby = ns.Rubies:Balance()
rewards:OnQuestTurnedIn(4003, 0, 10000)
assert(traceEvent("CHAT_MSG_SYSTEM", "Test title 4003 completed.") == "")
assert(ns.Rubies:Balance() == ruby and ns.Level:OfferCount() == offers + 1)
ns.db.chars = {}
assert(table.getn(rewards:PlanCatchUp().quests) == 0)
CuratorOctoCatchUpDB = nil
assert(table.getn(rewards:PlanCatchUp().quests) == 0)

QuestieOcto = nil
GetQuestsCompleted = function(output)
    if not output then error("This client fills a table") end
    output[4010] = true
end
rewards.octoQuestQueryPending = true
assert(not rewards:PlanCatchUp().questsScanned)
rewards.octoQuestQueryPending = nil
C_QuestLog = { GetTitleForQuestID = function(id) return "Previously unseen " .. id end }
plan = rewards:PlanCatchUp()
assert(plan.questsScanned and plan.quests[1] == 4010)
assert(rewards:ApplyCatchUp(plan, false))
assert(table.getn(rewards:PlanCatchUp().quests) == 0 and ns.Level:OfferCount() == offers + 1)
rewards:OnQuestTurnedIn(4010, 0, 10000)
assert(ns.Rubies:Balance() == ruby)
""")
print("Quest catch-up: confirmed turn-ins, board and achievement counters, legacy receipts and permanent refusal verified")

lua.execute(r"""
local ns = CuratorOctoFull
local save, button = ns.Save, ns.Album.frame.save
local count, lines = 0, {}
local oldLogout, oldPopup, oldReload = Logout, StaticPopup_Show, ReloadUI
local oldCombat, oldPrint, oldTurning = UnitAffectingCombat, ns.Print, save.Turning
local shown
local function click()
    this, arg1 = button, "LeftButton"
    button:GetScript("OnClick")()
end
ns.Print = function(message) table.insert(lines, message) end
StaticPopup_Show = function(key) shown = assert(StaticPopupDialogs[key]) end
ReloadUI = function() error("Collection save must never reload") end
Logout = function()
    assert(not ns.db.saveNote)
    count = count + 1
end
assert(not save:Cover(button, save.SCROLL))
click()
assert(shown and shown.button2 == ns.L["Cancel"] and count == 0 and not ns.db.saveNote)
shown = nil -- dismissing the dialog leaves the collection and session alone
assert(count == 0 and not save.saveOnLogout)
click()
shown.OnAccept()
assert(count == 1 and save.saveOnLogout and not ns.db.saveNote and table.getn(lines) == 0)
ns.Fire("LOGOUT")
assert(not save.saveOnLogout and type(ns.db.saveNote) == "table")
save:Start()
assert(not ns.db.saveNote and lines[1] == ns.L["Your collection is saved."])

shown = nil
UnitAffectingCombat = function(unit) assert(unit == "player"); return 1 end
click()
assert(count == 1 and not shown and not ns.db.saveNote)
UnitAffectingCombat = nil
save.Turning = function() return true end
click()
assert(count == 1 and not shown and not ns.db.saveNote)
save.Turning = oldTurning

Logout = function() error("Logout rejected") end
SlashCmdList.CURATOR("save")
assert(shown and count == 1 and not save.saveOnLogout)
shown.OnAccept()
assert(not ns.db.saveNote and not save.saveOnLogout)
local fallback = ns.L["Use /logout to return to the character selection screen and save your collection."]
assert(lines[table.getn(lines)] == fallback)
local locale = ns.locale
ns.SetLocale("frFR")
assert(ns.L["Save and log out"] == "Sauvegarder et se déconnecter")
ns.SetLocale(locale)
Logout, StaticPopup_Show = oldLogout, oldPopup
ns.Print, ReloadUI, UnitAffectingCombat = oldPrint, oldReload, oldCombat
""")
print("Collection save: confirmation, native logout, session guards and login receipt verified")

lua.execute(gift_code_fixture())

lua.execute(r"""
local ns = CuratorOctoFull
local gifts = ns.Gifts
local oldName, oldRealm, oldNormalized = UnitName, GetRealmName, GetNormalizedRealmName
local oldFull = UnitFullName
UnitName = function() return "Tester" end
GetRealmName = function() return "Other realm" end
GetNormalizedRealmName, UnitFullName = nil, nil
local ok, why = gifts:Check(octoGiftTestCode)
assert(not ok and why == "other", why)
GetRealmName = function() return "N'Zoth" end
ok, why = gifts:Check(octoGiftBadCode)
assert(not ok and why == "damaged", why)
assert(ns.GiftUI.CodeIn("Gift: " .. octoGiftTestCode) == octoGiftTestCode)
ok, why = gifts:Check(octoGiftTestCode)
assert(ok, why)
local rubies, offers = ns.Rubies:Balance(), ns.Level:OfferCount()
ok, why = gifts:Redeem(octoGiftTestCode)
assert(ok, why)
ok, why = gifts:Redeem(octoGiftTestCode)
assert(not ok and why == "used", why)
assert(ns.Rubies:Balance() == rubies + 100 and ns.Level:OfferCount() == offers + 1)
UnitName, GetRealmName, GetNormalizedRealmName, UnitFullName = oldName, oldRealm, oldNormalized, oldFull
""")
print("OctoWoW gift code: real RSA signature, recipient, altered signature and single redemption verified")

lua.execute(r"""
local ns = CuratorOctoFull
local crate, cases = ns.CrateUI, ns.Cases
local edition = "paladin1"
local stock, keys = cases:Count(edition), cases:Keys(edition)
local initialCards = table.getn(cases:Won(edition))
cases:Add(edition, 37)
assert(cases:Count(edition) == stock + 37)
ns.Rubies:Gain(cases:KeyPrice() * 37, "gift")
assert(cases:BuyKey(edition, 37))
local add, earned = cases.Add, 0
cases.Add = function(self, case, count)
    local before = self:Count(edition)
    local result = add(self, case, count)
    earned = earned + self:Count(edition) - before
    return result
end
local observed = 0
local reveal, start = crate.Reveal, GetTime()
crate.Reveal = function(self)
    observed = observed + 1
    return reveal(self)
end
crate:Show(edition)
stepFrames(40)
local function click(button)
    this, arg1 = button, "LeftButton"
    button:GetScript("OnClick")()
end
click(crate.frame.open)
assert(ns.GetTimeScale(crate) == 1)
stepFrames(240)
assert(observed == 1)
local prize, inspector = crate.frame.reveal, crate.frame.inspect
for i = 1, 80 do
    if prize.inspect:IsShown() then break end
    stepFrames(10)
end
assert(prize.inspect:IsShown())
click(prize.inspect)
assert(inspector:IsShown() and inspector.pick == crate.win and not prize.card:IsShown())
click(inspector.back)
assert(not prize.card:IsShown())
stepFrames(12)
assert(prize.card:IsShown() and not inspector:IsShown())
crate:Back()
stepFrames(70)
start = GetTime()
click(crate.frame.batchButtons[20])
assert(crate.batch.total == 20 and crate.batch.opened == 1 and ns.GetTimeScale(crate) == 5)
click(crate.frame.batchButtons[5])
assert(crate.batch.total == 20 and crate.batch.opened == 1)
for i = 1, 150 do
    if crate.batch.opened == 20 and crate.frame.reveal.close:IsShown() then break end
    stepFrames(10)
end
assert(crate.batch.opened == 20 and observed == 21 and crate.frame.reveal.close:IsShown()
    and GetTime() - start < 75, string.format("Batch stopped at %d, with %d reveals in %.2fs",
        crate.batch.opened, observed, GetTime() - start))
assert(cases:Count(edition) == stock + 16 + earned and cases:Keys(edition) == keys + 16,
    string.format("After 21: %d cases, %d keys; started at %d and %d", cases:Count(edition), cases:Keys(edition), stock, keys))
assert(table.getn(cases:Won(edition)) == initialCards + 21)
assert(ns.GetTimeScale(crate) == 1)
crate:Back()
stepFrames(70)
click(crate.frame.batchButtons[10])
assert(crate.batch.total == 10 and crate.batch.opened == 1)
crate.frame:Hide()
stepFrames(250)
assert(not crate.batch and ns.GetTimeScale(crate) == 1)
assert(cases:Count(edition) == stock + 15 + earned and cases:Keys(edition) == keys + 15)
assert(table.getn(cases:Won(edition)) == initialCards + 22)
crate:Show(edition)
stepFrames(40)
click(crate.frame.batchButtons[20])
assert(not crate.batch and cases:Count(edition) == stock + 15 + earned)
click(crate.frame.batchButtons[5])
assert(crate.batch and crate.batch.total == 5)
stepFrames(360)
assert(crate.batch.opened == 5 and observed == 26)
assert(cases:Count(edition) == stock + 10 + earned and cases:Keys(edition) == keys + 10)
crate.frame:Hide()
crate.Reveal = reveal
cases.Add = add
""")
print("Case opening: single and accelerated queues, 20 reveals, safe interruption and stock checks verified")

lua.execute(r"""
local ns = CuratorOctoFull
local b, cases = ns.Booster, ns.Cases
b:Build()
b:BuildContractScene()
local scene, ct = b.frame, b.frame.ct
local paper = ct.paper
paper.tex.SetHeight = function(self, height) self.sheetHeight = height end
paper.title.SetAlpha = function(self, alpha) self.inkAlpha = alpha end
cases:Add("paladin1", 1)
ns.Rubies:Gain(cases:KeyPrice(), "gift")
assert(cases:BuyKey("paladin1", 1))
local rec = assert(cases:Open("paladin1"))
rec.f = nil
b:OpenCaseContract(rec, {})
assert(b.state == "contract" and paper.tex.sheetHeight == 2 and paper.title.inkAlpha == 0)
assert(not ct.wonLabels:IsShown())
stepFrames(18)
assert(paper.tex.sheetHeight == b.CT.P and paper.title.inkAlpha == 1)
local sawBurn = false
for i = 1, 270 do
    if b.state ~= "contract" then break end
    stepFrames(1)
    if paper:IsShown() and paper.edge:IsShown() and paper.tex.sheetHeight < b.CT.P then
        sawBurn = true
    end
end
assert(sawBurn and b.state == "caseDeal" and not paper:IsShown())
assert(not ct.rodTop:IsShown() and not ct.rodBot:IsShown() and not paper.edge:IsShown())
stepFrames(20)
assert(b.state == "caseCard" and not ct.wonLabels:IsShown() and ct.wonHit:IsShown())
b:CaseReveal()
stepFrames(4)
assert(b.state == "caseReveal" and not ct.wonLabels:IsShown())
stepFrames(7)
assert(ct.wonLabels:IsShown() and ct.wonName:GetText() ~= "" and ct.wonRank:GetText() ~= "")
assertOpaqueBackground(ct.wonLabels.textures[1])
assert(not scene.again:IsShown())
stepFrames(26)
assert(b.state == "caseDone" and scene.again:IsShown() and scene.album:IsShown())
assert(scene.summary.anchor[5] < ct.wonLabels.anchor[5] - 108)
scene:Hide()
b:OpenCaseContract(rec, {})
b:ContractSkip()
assert(b.state == "caseCard" and not paper:IsShown() and not ct.wonLabels:IsShown())
scene:Hide()
local series = ns.SeriesByKey("balor")
local card = series.list[1]
b:OpenContract({card = card, given = {card.key}, odds = {{series = series}},
    rarity = 1, up = 2, n = 1, size = 10, count = 1, new = true})
assert(paper.tex.sheetHeight == 2 and paper.title.inkAlpha == 0)
for i = 1, 300 do
    if b.state ~= "contract" then break end
    stepFrames(1)
end
assert(b.state == "dealing" and not paper:IsShown() and not paper.edge:IsShown())
assert(not ct.rodTop:IsShown() and not ct.rodBot:IsShown())
stepFrames(45)
assert(b.state == "cards" and scene.hint:GetText() ~= "")
scene:Hide()
""")
print("Contracts: cropped parchment, burn before deal, synchronized case reward labels and skip verified")

lua.execute(r"""
local ns = CuratorOctoFull
local source = ns.SeriesByKey("balor").list[1]
local data = {}
for key, value in pairs(source) do data[key] = value end
local display = 1974
local oldPortrait = ns.Portraits[display]
ns.Portraits[display] = {0, 1, 0, 1}
data.display, data.art = display, nil
local card = ns.NewCard(UIParent, "big")
card:SetCard(data, {owned = true})
assert(card.art.portrait:IsShown() and not card.model.testDisplay)
card:ShowSide("back")
card:SetCard(data, {owned = true, opening3D = true})
assert(not card.model:IsShown() and not card.model.testDisplay)
card:Flip(0.34)
stepFrames(12)
assert(card.model.testDisplay == display and card.model:IsShown() and not card.art.portrait:IsShown())
assert(card.model.artworkWindow == card.art and card.model.anchor[2] == UIParent)
local viewportX, viewportY, viewportWidth, viewportHeight = 120, 180, 132, 108
card.art.GetLeft = function() return viewportX end
card.art.GetBottom = function() return viewportY end
card.art.GetWidth = function() return viewportWidth end
card.art.GetHeight = function() return viewportHeight end
card:SetScale(0.75)
local cameraRefreshes = 0
card.model.RefreshCamera = function() cameraRefreshes = cameraRefreshes + 1 end
stepFrames(1)
assert(card.model.anchor[4] == 90 and card.model.anchor[5] == 135)
assert(card.model.viewport[3] == 99 and card.model.viewport[4] == 81)
assert(math.abs(card.model:GetEffectiveScale() - 1) < 0.001 and cameraRefreshes == 1)
viewportX, viewportY = 200, 240
stepFrames(1)
assert(card.model.anchor[4] == 150 and card.model.anchor[5] == 180 and cameraRefreshes == 1)
card:SetScale(0.5)
stepFrames(1)
assert(card.model.anchor[4] == 100 and card.model.anchor[5] == 120)
assert(card.model.viewport[3] == 66 and card.model.viewport[4] == 54 and cameraRefreshes == 2)
local can3D = ns.Can3D
simulateVertexOffsets(true)
ns.Can3D = function() return true end
card:SetPose(0.35, 0.12)
assert(card.model.anchor[2] == UIParent)
card:SetPose(math.pi, 0)
assert(not card.model:IsShown())
card:ShowSide("front")
card.model.SetDisplayInfo = function() return false end
card:ReloadModel()
assert(card.art.portrait:IsShown() and not card.model:IsShown())

local crate = ns.CrateUI
crate:Show("paladin1")
stepFrames(40)
local npc, npcTile
for row = 0, crate.itemRows - 1 do
    for _, tile in ipairs(crate.frame.items) do
        local entry = tile.pick and tile.pick.entry
        if tile:IsShown() and entry and entry.kind == "npc" and entry.display then
            assert(tile.creature and tile.creature.testDisplay == entry.display and not tile.art:IsShown())
            assert(tile.creature.artworkWindow:GetParent() == tile and tile.creature.anchor[2] == UIParent)
            npc, npcTile = entry, tile
        end
    end
    if npc then break end
    crate:ScrollItems(1)
end
assert(npc and npcTile)
this, arg1 = npcTile, "LeftButton"
npcTile:GetScript("OnMouseUp")()
local inspect = crate.frame.inspect
assert(inspect:IsShown() and inspect.pick == npcTile.pick and not crate.frame.panel:IsShown())
assert(inspect.name:GetText() ~= "" and inspect.card.scene.testDisplay == npc.display)
assert(inspect.card.scene.artworkWindow == inspect.card.win and inspect.card.scene.anchor[2] == UIParent)
local hold = inspect.card.turn
this, arg1 = inspect, 1
inspect:GetScript("OnMouseWheel")()
stepFrames(12)
assert(hold.zoom > 1)
this, arg1 = inspect.card, "LeftButton"
inspect.card:GetScript("OnMouseDown")()
inspect.card:GetScript("OnMouseUp")()
stepFrames(35)
assert(inspect.card.facing == "back" and not inspect.card.win:IsShown())
this, arg1 = inspect.back, "LeftButton"
inspect.back:GetScript("OnClick")()
assert(inspect:IsShown() and not crate.frame.panel:IsShown())
stepFrames(12)
assert(not inspect:IsShown() and crate.frame.panel:IsShown())
this, arg1 = npcTile, "LeftButton"
npcTile:GetScript("OnMouseUp")()
assert(inspect:IsShown() and inspect.card.scene.testDisplay == npc.display and inspect.card.win:IsShown())
crate:CloseInspect(true)
npcTile:Hide()
assert(not npcTile.creature:IsShown() and not npcTile.creature.testDisplay)
crate.frame:Hide()
local prize = ns.CrateCard.New(UIParent, 200)
prize:Set({tier = 1, entry = npc, opening3D = true}, crate.RANKS)
assert(prize.scene:IsShown() and prize.scene.testDisplay == npc.display)
assert(prize.scene.artworkWindow == prize.win and prize.scene.anchor[2] == UIParent)
prize:SetPose(0.35, 0.12)
assert(prize.scene.anchor[2] == UIParent)
prize:SetPose(math.pi, 0)
assert(not prize.win:IsShown())

local oldItemInfo = GetItemInfo
GetItemInfo = function() return "Model test item" end
local arm = ns.CrateCard.NewArm(UIParent, 5)
arm.model.SetItem = function(self, item) self.testItem = item end
ns.CrateCard.Arm(arm, {id = 17182})
assert(arm.ready and arm.model.testItem == 17182 and arm.model.allPointsTarget == arm)
GetItemInfo, ns.Can3D, ns.Portraits[display] = oldItemInfo, can3D, oldPortrait
simulateVertexOffsets(false)
card:Hide()
prize:Hide()
arm:Hide()
""")
print("Opening models: automatic reveal, stable window anchors, case thumbnails and legacy weapon/portrait fallbacks verified")
