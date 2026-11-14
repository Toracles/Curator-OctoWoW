"""Prepare the complete upstream addon for the OctoWoW compatibility pass."""
from hashlib import file_digest
from pathlib import Path
import csv
import re
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT.parent / "Curator-1.14.3.zip"
WORK = ROOT / "full-port-work" / "Curator"
EXPECTED = "e01431a31035665b29fff12d3ec082fa50dda3fb75eb5bd73666a462b73c46de"

with ARCHIVE.open("rb") as source:
    if file_digest(source, "sha256").hexdigest() != EXPECTED:
        sys.exit("Unexpected Curator 1.14.3 archive")

with ZipFile(ARCHIVE) as archive:
    toc = archive.read("Curator/Curator.toc").decode("utf8")
    files = [line.strip().replace("\\", "/") for line in toc.splitlines()
             if line.strip().endswith(".lua")]
    for name in [*files, "LICENSE.txt", "Data/LICENSE.txt", "Data/NOTICE.txt"]:
        target = WORK / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.read("Curator/" + name))
    toc = re.sub(r"^## Interface:.*$", "## Interface: 11200", toc, flags=re.M)
    toc = re.sub(r"^## SavedVariables:.*$",
                 "## SavedVariables: CuratorOctoFullDB, CuratorOctoFullExport", toc, flags=re.M)
    (WORK / "Curator.toc").write_text(toc, encoding="utf8")
    with (WORK.parent / "media.csv").open("w", encoding="utf-8", newline="") as manifest:
        writer = csv.writer(manifest)
        writer.writerow(["Path", "Bytes"])
        for entry in archive.infolist():
            if entry.filename.startswith("Curator/Media/") and not entry.is_dir():
                writer.writerow([entry.filename, entry.file_size])
print(f"{len(files)} upstream Lua modules staged in TOC order")
