from pathlib import Path
import sys
sys.path.insert(0, str(Path(".test-runtime").resolve()))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute(r"""
math.mod = math.fmod
time = os.time
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
 CreateTexture = function(self) return widget(self) end,
 CreateFontString = function(self) return widget(self) end,
 GetWidth = function() return 1024 end,
 GetHeight = function() return 768 end,
 GetFrameLevel = function() return 1 end,
 GetEffectiveScale = function() return 1 end,
 GetScale = function() return 1 end,
 GetAlpha = function() return 1 end,
 GetRotation = function() return 0 end,
 GetLeft = function() return 0 end,
 GetBottom = function() return 0 end,
 GetCenter = function() return 512,384 end,
 Show = function(self) setShown(self, true, "OnShow") end,
 Hide = function(self) setShown(self, false, "OnHide") end,
 IsShown = function(self) return self.shown ~= false end,
 IsVisible = function(self) return self.shown ~= false end,
}
widget = function(parent)
 local frame = setmetatable({parent=parent}, {__index=function(_, key)
     return methods[key] or (not unavailable[key] and string.find(key, "^[A-Z]") and noop or nil)
 end})
 scripts[frame] = {}
 registrations[frame] = {}
 return frame
end
UIParent, Minimap, DEFAULT_CHAT_FRAME, GameTooltip = widget(), widget(), widget(), widget()
CreateFrame = function(_,name,parent,template)
 local modern = {SecureActionButtonTemplate=true, BackdropTemplate=true, PortraitFrameTemplate=true, LargeSideTabButtonTemplate=true,
     CollectionsBackgroundTemplate=true, InsetFrameTemplate=true, WowStyle1DropdownTemplate=true, CheckboxWithLabelTemplate=true, ColoredProgressBarTemplate=true}
 assert(not modern[template], "Unsupported inherited template: " .. tostring(template))
 local frame=widget(parent)
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
ns.Booster:Open(ns.SeriesByKey("northwind"), {test = true})
assert(ns.Booster.frame and ns.Booster.frame.pack)
ns.Booster:Tear()
assert(table.getn(ns.Booster.picks)==8)
ns.Booster:Burst()
stepFrames(100)
assert(ns.Booster.state == "cards", tostring(ns.Booster.state) .. " landed=" .. tostring(ns.Booster.landed) .. " card=" .. tostring(ns.Booster.cards[1].pick) .. " scale=" .. tostring(ns.Booster.timeK))
ns.Booster:RevealAll()
stepFrames(480)
assert(ns.Booster.state == "done", ns.Booster.state)
""")






lua.execute(r"""
local ns = CuratorOctoFull
ns.Wire:Raw("WHISPER", "Collector", "probe")
assert(lastMessage[2] == "probe" and lastMessage[3] == "WHISPER" and lastMessage[4] == "Collector")
""")
print("Original booster opening reached done; legacy addon message routed in mock")


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
