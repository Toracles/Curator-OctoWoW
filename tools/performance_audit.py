"""Repeatable CPU/call-count audit using simulated APIs, not client FPS."""
from pathlib import Path
import argparse
import json
import re
import sys
import time

repo = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo / ".test-runtime"))
from lupa.lua51 import LuaRuntime
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--addon", type=Path, default=repo / "curator-test")
args = parser.parse_args()
lua = LuaRuntime()
blocks = re.findall(r'lua.execute\(r"""(.*?)"""\)', (repo / "tools/verify_full_port.py").read_text(encoding="utf-8"), re.S)
lua.execute(blocks[0])
addon = args.addon
toc = (addon / "Curator.toc").read_text(encoding="utf-8").splitlines()
loaded = time.perf_counter()
for line in toc:
    if line.endswith(".lua"):
        lua.execute((addon / line.replace("\\", "/")).read_text(encoding="utf-8"), name="@" + line)
load_ms = (time.perf_counter() - loaded) * 1000
lua.execute('''
math.randomseed(42)
assert(traceEvent("ADDON_LOADED", "Curator") == "")
assert(traceEvent("PLAYER_LOGIN") == "")
local ns = CuratorOctoFull
local count = 0
for _, s in ipairs(ns.Series) do
    if not s.event and not s.limited then
        for _, c in ipairs(s.list) do
            if count < 250 then
                ns.db.cards[c.key] = {n = 8, s = 2, h = 1, t = 1795600000}
                count = count + 1
            end
        end
    end
end
ns.Copies:All() -- complete legacy reconciliation before measuring warm paths
PerfCounts = {}
local function watch(object, key, label)
    local old = object[key]
    object[key] = function(a,b,c,d,e,f)
        PerfCounts[label] = (PerfCounts[label] or 0) + 1
        return old(a,b,c,d,e,f)
    end
end
watch(ns.Copies, "All", "copies_all")
watch(ns.Copies, "Reconcile", "copies_reconcile")
watch(ns.InventoryUI, "Survey", "inventory_survey")
watch(ns.Album, "Refresh", "album_refresh")
watch(ns.Collection, "Progress", "album_progress")
watch(ns, "NewCard", "new_card")
function PerfRun(code)
    PerfCounts = {}
    local instructions = 0
    debug.sethook(function() instructions = instructions + 1000 end, "", 1000)
    local start = os.clock()
    local ok, err = pcall(assert(loadstring(code)))
    local ms = (os.clock() - start) * 1000
    debug.sethook()
    assert(ok, err)
    return ms, instructions, PerfCounts
end
''')
scenarios = {
    "first_minimap": "local a=CuratorOctoFull.Album; a:ToggleFromMinimap(); local n=0; while a.buildJob do a:ResumeBuild(); n=n+1; assert(n<200) end",
    "warm_reopen_5": "local a=CuratorOctoFull.Album; for i=1,5 do a:Hide(); a:ToggleFromMinimap() end",
    "inventory_refresh_5": "local a=CuratorOctoFull.Album; a:Open('inventory'); for i=1,5 do a:Refresh() end",
    "inventory_pages_5": "local a=CuratorOctoFull.Album; for i=1,5 do a:InventoryPage(1) end",
    "album_navigation": "local ns=CuratorOctoFull; for i=1,5 do ns.Album:ShowSeries(ns.Series[i]) end",
    "profile": "CuratorOctoFull.Album:Open('profile')",
    "quests": "CuratorOctoFull.Album:Open('quests')",
    "achievements": "CuratorOctoFull.Album:Open('ach')",
    "cases_preview": "CuratorOctoFull.Album:Hide(); CuratorOctoFull.CrateUI:Test()",
    "minimap_tooltip_5": "local n=CuratorOctoFull; for i=1,5 do this=n.MinimapButton.button; n.MinimapButton.button:GetScript('OnEnter')() end",
    "event_burst": "local n=CuratorOctoFull; n.Album:Open('inventory'); for i=1,5 do n.Fire('CHANGED'); n.Fire('COPIES_CHANGED'); n.Fire('CASES_CHANGED') end; if n.Album.FlushRefresh then n.Album:FlushRefresh() end",
    "closed_events": "local n=CuratorOctoFull; n.Album:Hide(); for i=1,5 do n.Fire('CHANGED'); n.Fire('COPIES_CHANGED'); n.Fire('CASES_CHANGED') end",
}
results = {}
for name, code in scenarios.items():
    ms, instructions, counts = lua.globals().PerfRun(code)
    results[name] = {"mock_cpu_ms": round(ms,3), "lua_instructions_approx": instructions, "calls": dict(counts)}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({"environment":"Lua 5.1 simulated APIs; 250 cards x 8 copies; not game latency", "load_mock_ms":round(load_ms,3), "scenarios":results}, indent=2), encoding="utf-8")
for name, result in results.items():
    print(name, result)
