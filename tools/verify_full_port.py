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
 Low=true, High=true, Text=true, CreateMaskTexture=true, AddMaskTexture=true}
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
  return texture
 end,
 SetDrawLayer = function(self, layer) self.drawLayer = layer end,
 SetTexture = function(self, file) self.textureFile = file end,
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
 if name then _G[name]=frame end
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
files = [line.replace("\\", "/") for line in (root / "Curator.toc").read_text(encoding="utf8").splitlines()
         if line.endswith(".lua")]
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
