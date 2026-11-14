from pathlib import Path
import sys
from subprocess import run, PIPE
base = Path("full-port-work/Curator")
compiler = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".port-runtime/lua50x64/luac50.exe").resolve()
files = [file for file in (base/"Curator.toc").read_text(encoding="utf8").splitlines() if file.endswith(".lua")]
errors = []
for file in files:
    result = run([compiler,"-p",base/file],stdout=PIPE,stderr=PIPE)
    if result.returncode:
        errors.append(result.stderr.decode(errors="replace").strip() or str(result.returncode))
print(f"{len(files)-len(errors)}/{len(files)} pass Lua 5.0")
print("\n".join(errors))
raise SystemExit(bool(errors))


