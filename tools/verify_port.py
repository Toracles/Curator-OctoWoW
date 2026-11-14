from pathlib import Path
import sys

sys.path.insert(0, str(Path(".test-runtime").resolve()))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute("""
math.mod=math.fmod
local noop=function() end
frames, UISpecialFrames, SlashCmdList={},{},{}
local methods={SetScript=function(self,k,fn) self[k]=fn end,
 Show=function(self) self.visible=true end, Hide=function(self) self.visible=false end,
 IsShown=function(self) return self.visible end,
 GetWidth=function() return 1024 end,GetHeight=function() return 768 end}
local function widget()
 return setmetatable({}, {__index=function(_,k) return methods[k] or (string.find(k,"^%u") and noop or nil) end})
end
UIParent=widget()
methods.CreateTexture,methods.CreateFontString=widget,widget
function CreateFrame(kind,name)
 local w=widget()
 if name then frames[name]=w elseif not events then events=w end
 return w
end
DEFAULT_CHAT_FRAME=widget()
PlaySound=noop
time=function() return 86400 end
zone="Gilneas"
GetRealZoneText=function() return zone end
GetZoneText=GetRealZoneText
GetRealmName=function() return "Octo" end
UnitName=function() return "Test" end
GetNumQuestLogEntries=function() return 0 end
ERR_ZONE_EXPLORED="Discovered: %s"
function fire(name,message) event,arg1=name,message; events.OnEvent() end
""")
root = Path("addon/CuratorOcto")
for name in (root / "CuratorOcto.toc").read_text().splitlines():
    if name.endswith(".lua"):
        lua.execute((root / name).read_text())
lua.execute("""
fire("PLAYER_LOGIN")
local C=CuratorOcto
local a,d=C.byZone[5179],C.byZone[5087]
fire("CHAT_MSG_SYSTEM","Discovered: Village")
fire("UI_INFO_MESSAGE","Discovered: Village")
assert(C.db.points.world==10)
fire("CHAT_MSG_SYSTEM","A quest completed.")
fire("UI_INFO_MESSAGE","A quest completed.")
assert(C.db.points.world==30)
for i=1,35 do fire("CHAT_MSG_COMBAT_XP_GAIN","Creature dies, you gain 100 experience.") end
assert(C.Packs(a)==1 and C.db.points.world==0)
assert(table.getn(C.OpenPack(a,true))==8 and C.Packs(a)==1 and not next(C.db.cards))
SlashCmdList.CURATOROCTO()
C.StartOpening(a)
local w=frames.CuratorOctoOpening
assert(w.state=="ready")
w.pack.OnClick()
assert(w.state=="charge" and C.Packs(a)==0)
assert(C.OpenPack(a)==nil)
for i=1,120 do arg1=.04; w.OnUpdate() end
assert(w.state=="reveal")
w.skip.OnClick()
for i=1,80 do arg1=.04; w.OnUpdate() end
local seen={}
C.Init()
for _,view in ipairs(w.cards) do
 assert(view.revealed)
 local card=view.pick.card
 assert(C.Owned(card).count==1 and not seen[card.id])
 seen[card.id]=true
end
zone="Stormwind Vault"
fire("CHAT_MSG_COMBAT_XP_GAIN","Volkan Cruelblade dies, you gain 100 experience.")
assert(C.Packs(d)==1 and C.db.points.dungeon==30)
assert(table.getn(C.OpenPack(d))==5)
""")
print("Collection, acquisition, opening phases and persistence OK under mocked Lua 5.1")
