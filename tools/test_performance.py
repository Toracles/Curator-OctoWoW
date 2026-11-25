"""Regression checks for cached views and coalesced paints, using native Lua 5.0."""
from pathlib import Path
import re
import subprocess

repo = Path(__file__).resolve().parents[1]
blocks = re.findall(r'lua.execute\(r"""(.*?)"""\)', (repo / "tools/verify_full_port.py").read_text(encoding="utf-8"), re.S)
setup = blocks[0].replace("math.mod = math.fmod", "")
addon = repo / "curator-test"
files = [s.replace("\\", "/") for s in (addon / "Curator.toc").read_text(encoding="utf-8").splitlines() if s.endswith(".lua")]
load = "\n".join("assert(loadfile(%r))()" % (addon / s).as_posix() for s in files)
checks = r'''
assert(traceEvent("ADDON_LOADED", "Curator") == "")
assert(traceEvent("PLAYER_LOGIN") == "")
local ns = CuratorOctoFull
local a, iu, cp = ns.Album, ns.InventoryUI, ns.Copies
local card = ns.SeriesByKey("elwynn").list[1]
ns.Collection:Add(card)
a:Open("inventory")
local all, calls = cp.All, 0
cp.All = function(self) calls=calls+1; return all(self) end
iu:InvalidateSurvey()
local view = iu:Survey()
assert(calls==1)
view.chips.all = 999999
assert(iu:Survey().chips.all ~= 999999 and calls==1)
a:RefreshInventory()
assert(calls==1)
-- Direct collection API use, without CHANGED yet, must not return stale data.
local count = table.getn(iu:Survey().copies)
ns.Collection:Add(card)
assert(table.getn(iu:Survey().copies)==count+1 and calls==2)
for _, event in ipairs({"CHANGED","COPIES_CHANGED","CASES_CHANGED","DISPLAYS_CHANGED","TRADES_CHANGED","COPY_CERTIFIED"}) do
    local before=calls
    ns.Fire(event)
    iu:Survey()
    assert(calls==before+1, event)
end
-- Every query parameter belongs to the key; changing page does not.
for _, pair in ipairs({{"sort","old"},{"filter","graded"},{"rarity",3},{"series",card.series},{"dupes",true},{"card",card}}) do
    local before=calls
    iu[pair[1]]=pair[2]
    iu:Survey()
    assert(calls==before+1)
end
local before=calls
iu.page=2; iu:Survey(); assert(calls==before)
iu.filter,iu.sort,iu.rarity,iu.series,iu.dupes,iu.card="all","new",nil,nil,nil,nil
-- Sales always recalculate, and cannot leave a pre-sale cached snapshot behind.
local takes, items = iu.Takes, iu.ItemsTaken
iu.Takes=function() return false end
iu.ItemsTaken=function() return 0 end
iu.sell={picked={}}
before=calls
iu:Survey(); iu:Survey()
assert(calls==before+2 and not iu.surveyCache)
iu.sell=nil; iu.Takes,iu.ItemsTaken=takes,items
cp.All=all
-- Data events still reach other subscribers synchronously; only painting waits.
a:CancelRefresh()
local refresh, paints, received = a.Refresh,0,0
a.Refresh=function(self) paints=paints+1; return refresh(self) end
ns.On("CHANGED",function() received=received+1 end)
for i=1,5 do ns.Fire("CHANGED"); ns.Fire("COPIES_CHANGED"); ns.Fire("CASES_CHANGED") end
assert(received==5 and paints==0 and a.refreshPending)
a:FlushRefresh()
assert(paints==1 and not a.refreshPending)
a:FlushRefresh(); assert(paints==1)
ns.Fire("CHANGED"); a:Hide(); a:FlushRefresh(); assert(paints==1)
for i=1,5 do ns.Fire("CHANGED") end
assert(not a.refreshPending and paints==1)
a.Refresh=refresh
assert(traceEvent("PLAYER_LOGOUT")=="")
assert(CuratorOctoFullDB.cards[card.key].n==2)
print("Performance regressions: invalidation, direct grants, query keys, immutable counts, sales, event bursts and logout passed")
'''
script=repo / "full-port-work/performance-regressions.lua"
script.write_text("\n".join([setup,load,checks]),encoding="utf-8")
subprocess.run([repo / ".port-runtime/lua50x64/lua50.exe",script],check=True)
