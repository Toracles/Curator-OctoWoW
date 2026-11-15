"""Build the bilingual gallery from the published French gallery and source artwork."""
import argparse
import csv
from io import BytesIO, StringIO
from pathlib import Path
import re
from runpy import run_path
from zipfile import ZIP_DEFLATED, ZipFile

source = Path(__file__).resolve().parent
root = source.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("original_gallery", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--curator", type=Path, default=root.parent / "Curator-1.14.3.zip")
args = parser.parse_args()
art = run_path(str(source / "Produire-cartes.py"))
prefix = "CuratorOctoGalerie/"
rarities = {1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic", 5: "Legendary", 6: "Mythic"}
with (root / "data/Catalogue.csv").open(encoding="utf-8-sig", newline="") as stream:
    catalogue = {(row["Album"], row["NPCID"]): row for row in csv.DictReader(stream)}

with ZipFile(args.original_gallery) as original, ZipFile(args.curator) as upstream:
    children = [item for item in original.namelist() if item.startswith(prefix + "Cartes/") and item.endswith(".tga")]
    coverage = csv.DictReader(StringIO(original.read(prefix + "Couverture.csv").decode("utf-8-sig")))
    assets = {(row["Album"], row["NPCID"]): row for row in coverage if row["Portrait Curator"]}
    albums = {folder: name for name, (_, folder) in art["ALBUMS"].items()}
    source_uv = upstream.read("Curator/Data/Portraits.lua").decode()
    crops = {key: tuple(map(float, coords.split(","))) for key, coords in
             re.findall(r"\[(\d+)\]\s*=\s*\{\s*([-\d., ]+)\s*\}", source_uv)}
    loaded = {}

    def texture(name):
        if name not in loaded:
            loaded[name] = art["read_texture"](upstream, name)
        return loaded[name]

    with ZipFile(args.output, "w", ZIP_DEFLATED, compresslevel=3) as gallery:
        gallery.write(source / "Galerie.lua", prefix + "Galerie.lua")
        gallery.write(source / "Galerie.toc", prefix + "CuratorOctoGalerie.toc")
        for filename in ("Catalogue.lua", "Correspondances.csv", "Couverture.csv", "LISEZ-MOI.md", *children):
            path = filename if filename.startswith(prefix) else prefix + filename
            gallery.writestr(path, original.read(path))
        for path in children:
            relative = Path(path).relative_to(prefix + "Cartes")
            key = (albums[relative.parent.name], relative.stem)
            info = assets[key]
            row = dict(catalogue[key])
            rarity = int(row["RareteID"])
            row["Rarete"] = rarities[rarity]
            card = art["render"](row, texture(info["Décor de prototype"]), texture(f"Frame{rarity}.tga"),
                                 texture("Body.tga"), texture(f"Gem{rarity}.tga"),
                                 texture(info["Portrait Curator"]), crops[info["DisplayID"]], "Lv.")
            output = BytesIO()
            card.save(output, format="TGA")
            gallery.writestr(prefix + "Cartes-en/" + relative.as_posix(), output.getvalue())

with ZipFile(args.output) as gallery:
    assert gallery.testzip() is None
    assert all(path.replace("/Cartes/", "/Cartes-en/") in gallery.namelist() for path in children)
print(f"{len(children)} cards in both languages")
