from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

project = Path(__file__).resolve().parents[1]
workspace = project.parent
source = project / "addon" / "CuratorOcto"
audit = workspace / "Curator-OctoWoW-audit"
studios = {
    "gilneas": "Duskwood",
    "gilneas-city": "Shadowfang",
    "northwind": "Elwynn",
    "thalassian-highlands": "Hinterlands",
    "hateforge-quarry": "Depths",
    "stormwind-vault": "Stockade",
}
preserved = ["Back.tga", "Glow.tga", "Beam.tga", "Shock.tga", "Body.tga"]
preserved += [f"Frame{i}.tga" for i in range(1, 7)]

with ZipFile(workspace / "Curator-1.14.3.zip") as original:
    for studio in studios.values():
        preserved += [f"Studio{studio}.blp", f"Pack{studio}Top.blp", f"Pack{studio}Bottom.blp"]
    textures = {name: original.read(f"Curator/Media/{name}") for name in preserved}

portraits = {path.stem: path for path in (audit / "Pack" / "Portraits").glob("*.tga")}
slugs = dict(zip(studios, (5179, 5208, 5581, 5225, 5103, 5087)))
art = ["CuratorOctoFaces = {"]
faces = {}
for slug, zone in slugs.items():
    art.append(f"    [{zone}] = {{")
    for path in sorted((audit / "Cartes-natives" / slug).glob("*.tga")):
        name = f"Cards/{slug}/{path.name}"
        art.append(f'        [{int(path.stem)}] = "{name}",')
        faces[name] = path
    art.append("    },")
art.append("}")
art.append("CuratorOctoPortraits = {")
for display in sorted(portraits, key=int):
    art.append(f"    [{int(display)}] = true,")
art.append("}")
(source / "Art.lua").write_text("\n".join(art) + "\n", encoding="ascii")

output = project / "release" / "Curator-OctoWoW-0.2.0-alpha.1.zip"
output.parent.mkdir(exist_ok=True)
base = "CuratorOcto/"
with ZipFile(output, "w", ZIP_DEFLATED, compresslevel=4) as archive:
    for path in source.iterdir():
        archive.write(path, base + path.name)
    for name, content in textures.items():
        archive.writestr(base + "Media/" + name, content)
    for name, path in faces.items():
        archive.write(path, base + "Media/" + name)
    for display, path in portraits.items():
        archive.write(path, base + "Media/Portraits/" + display + ".tga")
    for name in ("LICENSE", "NOTICE.md"):
        archive.write(project / "data" / "OctoQuestDatabase" / name, base + "Credits/" + name)
with ZipFile(output) as archive:
    assert archive.testzip() is None
    toc = archive.read(base + "CuratorOcto.toc").decode()
    assert all(base + name in archive.namelist() for name in toc.splitlines() if name.endswith(".lua"))
print(output, len(faces), "faces", len(portraits), "portraits")
