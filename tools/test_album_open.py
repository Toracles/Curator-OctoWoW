"""Exercise interruption and compatibility paths of first minimap opening in Lua 5.0."""
from pathlib import Path
import re
import subprocess

repo = Path(__file__).resolve().parents[1]
blocks = re.findall(r'lua.execute\(r"""(.*?)"""\)', (repo / "tools/verify_full_port.py").read_text(encoding="utf-8"), re.S)
setup = blocks[0].replace("math.mod = math.fmod", "")
addon = repo / "curator-test"
files = [s.replace("\\", "/") for s in (addon / "Curator.toc").read_text(encoding="utf-8").splitlines() if s.endswith(".lua")]
load = "\n".join("assert(loadfile(%r))()" % (addon / s).as_posix() for s in files)
start = '''
assert(traceEvent("ADDON_LOADED", "Curator") == "")
assert(traceEvent("PLAYER_LOGIN") == "")
local a = CuratorOctoFull.Album
'''
scenarios = {
    "background_warmup": '''
local combat = UnitAffectingCombat
UnitAffectingCombat = function() return true end
a:WarmUp()
assert(a.buildJob and a.prewarming and not a.buildNotice:IsShown())
this, arg1 = a.buildDriver, 0.016
a.buildDriver:GetScript("OnUpdate")()
assert(not a.frame)
UnitAffectingCombat = function() return false end
while a.buildJob do a:ResumeBuild() end
assert(not a.frame:IsShown() and not a.buildNotice:IsShown())
a:ToggleFromMinimap()
assert(a.frame:IsShown() and not a.buildJob)
UnitAffectingCombat = combat
''',
    "click_during_warmup": '''
a:WarmUp()
a:ResumeBuild()
a:ToggleFromMinimap()
assert(a.openAfterBuild and not a.prewarming and a.buildNotice:IsShown())
while a.buildJob do a:ResumeBuild() end
assert(a.frame:IsShown())
''',

    "cancel": '''
a:ToggleFromMinimap()
a:ResumeBuild()
a.buildNotice:Hide()
while a.buildJob do a:ResumeBuild() end
assert(not a.frame:IsShown())
a:ToggleFromMinimap()
assert(a.frame:IsShown())
''',
    "slash_during_build": '''
a:ToggleFromMinimap()
a:ResumeBuild()
SlashCmdList.CURATOR("quests")
assert(not a.buildJob and a.frame:IsShown() and a.mode == "quests")
assert(not a.buildNotice:IsShown())
''',
    "no_coroutine": '''
local original = coroutine
coroutine = nil
a:ToggleFromMinimap()
assert(not a.buildJob and a.frame:IsShown())
coroutine = original
''',
}
for name, check in scenarios.items():
    script = repo / ("full-port-work/album-open-" + name + ".lua")
    script.write_text("\n".join([setup, load, start, check, 'print("Album opening scenario passed: ' + name + '")']), encoding="utf-8")
    subprocess.run([repo / ".port-runtime/lua50x64/lua50.exe", script], check=True)
