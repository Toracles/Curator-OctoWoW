import csv
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from PIL import Image
root = Path("Cartes-natives")
with (root / "Couverture.csv").open(encoding="utf-8-sig",newline="") as source:
    rows = list(csv.DictReader(source))
albums = dict(zip(
    ["gilneas","gilneas-city","northwind","thalassian-highlands","hateforge-quarry","stormwind-vault"],
    ["Gilneas","Gilneas City","Northwind","Thalassian Highlands","Hateforge Quarry","Stormwind Vault"]
))
base = "CuratorOctoGalerie/"
table = ["CuratorOctoGallery = {"]
count = 0
with ZipFile("Curator-OctoWoW-Galerie.zip", "w", ZIP_DEFLATED, compresslevel=5) as target:
    target.write("Galerie.toc", base + "CuratorOctoGalerie.toc")
    target.write("Galerie.lua", base + "Galerie.lua")
    for doc in ["LISEZ-MOI.md", "Correspondances.csv", "Couverture.csv"]:
        target.write(root / doc, base + doc)
    for folder, album in albums.items():
        accepted = [row["NPCID"] for row in rows if row["Album"] == album and row["Portrait Curator"]]
        assert len(set(accepted)) == len(accepted) and accepted
        table.append('    { name = "%s", path = "%s", cards = { %s } },' %
                     (album,folder,", ".join(accepted)))
        for ident in accepted:
            card = root / folder / (ident + ".tga")
            with Image.open(card) as img:
                assert img.size == (512, 512) and img.mode == "RGBA" and img.getbbox()
            target.write(card, base + "Cartes/" + folder + "/" + card.name)
            count += 1
    target.writestr(base + "Catalogue.lua", "\n".join(table + ["}", ""]))
with ZipFile("Curator-OctoWoW-Galerie.zip") as archive:
    assert archive.testzip() is None and len(archive.namelist()) == count + 6
print(count, "textures", Path("Curator-OctoWoW-Galerie.zip").stat().st_size, "bytes")
