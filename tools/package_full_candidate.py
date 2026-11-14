"""Package the converted upstream build for in-client validation."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parents[1]
staging = root / "full-port-work" / "Curator"
release = root / "release"
release.mkdir(exist_ok=True)
output = release / "Curator-OctoWoW-test-1.12.1.zip"
toc = (staging / "Curator.toc").read_text(encoding="utf8")
scripts = [line.replace("\\", "/") for line in toc.splitlines() if line.endswith(".lua")]
assert "Data/OctoAlbums.lua" in scripts and "OctoCompat.lua" in scripts

with ZipFile(root.parent / "Curator-1.14.3.zip") as upstream:
    with ZipFile(output, "w", ZIP_DEFLATED, compresslevel=3) as package:
        for relative in ["Curator.toc", "LICENSE.txt", "Data/LICENSE.txt", "Data/NOTICE.txt", *scripts]:
            package.write(staging / relative, "Curator/" + relative)
        for entry in upstream.infolist():
            if entry.filename.startswith("Curator/Media/") and not entry.is_dir():
                package.writestr(entry.filename, upstream.read(entry))
        package.write(root / "docs" / "PORTAGE-COMPLET.md", "Curator/ETAT-DU-PORTAGE.md")
with ZipFile(output) as package:
    assert package.testzip() is None
    assert all("Curator/" + script in package.namelist() for script in scripts)
print(output, output.stat().st_size)
