from pathlib import Path
import re
import subprocess
import sys

root = Path("full-port-work")
addon = root / "Curator"
compiler = Path(".port-runtime/lua50x64/lua50.exe").resolve()
test = Path("tools/verify_full_port.py").read_text(encoding="utf8")
blocks = re.findall(r'lua.execute\(r"""(.*?)"""\)', test, re.S)
files = [line.replace("\\", "/") for line in (addon/"Curator.toc").read_text(encoding="utf8").splitlines()
         if line.endswith(".lua")]
setup = blocks[0].replace("math.mod = math.fmod", "")
load = "\n".join("assert(loadfile(%r))()" % (addon/file).as_posix() for file in files)
events = """
local failure = traceEvent("ADDON_LOADED","Curator")
assert(failure=="",failure)
failure = traceEvent("PLAYER_LOGIN")
assert(failure=="",failure)
"""
script = root / "smoke50.lua"
script.write_text("\n".join([setup, load, events, *blocks[1:], 'print("Lua 5.0 runtime smoke passed")']), encoding="utf8")
result = subprocess.run([compiler, script], capture_output=True, text=True, errors="replace")
print(result.stdout, result.stderr, sep="")
sys.exit(result.returncode)

