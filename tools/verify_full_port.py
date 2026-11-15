from pathlib import Path
import sys
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
 Low=true, High=true, Text=true, GreetingPanel=true, CreateMaskTexture=true, AddMaskTexture=true}
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
 SetPoint = function(self, point, relative, relativePoint, x, y)
  self.anchor = { point, relative, relativePoint, x, y }
 end,
 ClearAllPoints = function(self) self.anchor = nil end,
 Show = function(self) setShown(self, true, "OnShow") end,
 Hide = function(self) setShown(self, false, "OnHide") end,
 IsShown = function(self) return self.shown ~= false end,
 IsVisible = function(self) return self.shown ~= false end,
}
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
    stepFrames(100)
    assert(booster.state == "cards", booster.state)
    booster:RevealAll()
    stepFrames(480)
    assert(booster.state == "done", booster.state)
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
assert(f.rows[1].value:GetText() == "3" and f.rows[3].value:GetText() == "120")
assert(f.rows[4].value:GetText() == "1" and f.rows[6].value:GetText() == "20%")
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
