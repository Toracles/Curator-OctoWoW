from collections import Counter
from html import unescape
import csv
from io import BytesIO
import json
from pathlib import Path
import re
import unicodedata
from zipfile import ZipFile

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Cartes-natives"
OUT.mkdir(exist_ok=True)
FONT = Path("C:/Windows/Fonts")
ALBUMS = {
    "Gilneas": ("Duskwood", "gilneas"),
    "Gilneas City": ("Shadowfang", "gilneas-city"),
    "Northwind": ("Elwynn", "northwind"),
    "Thalassian Highlands": ("Eversong", "thalassian-highlands"),
    "Hateforge Quarry": ("Blackrock", "hateforge-quarry"),
    "Stormwind Vault": ("Stockade", "stormwind-vault"),
}
FALLBACK_STUDIOS = {"Eversong": "Hinterlands", "Blackrock": "Depths"}
COMPARE = Path("C:/Users/Ash/Downloads/comparatif_octowow_wow_forever_2026-11-14.csv")
RUNTIME = Path("C:/Games/OctoWoW/Interface/AddOns/Questie-Octo/Data/runtime/enUS.lua")


def read_csv(p):
    with p.open(encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def normalize(name):
    return " ".join(unicodedata.normalize("NFKC", unescape(name)).replace("’", "'").casefold().split())


def fit_text(draw, value, y, width, size, font_name, color):
    for point in range(size, 13, -1):
        font = ImageFont.truetype(str(FONT / font_name), point)
        if draw.textlength(value, font=font) <= width:
            break
    draw.text((183, y), value, font=font, fill=color, anchor="mm")


def read_texture(archive, name):
    return Image.open(BytesIO(archive.read("Curator/Media/" + name))).convert("RGBA")


def render(row, studio, frame, body, gem, portrait, crop):
    card = body.copy()
    width, height = 318, 294
    background = ImageOps.fit(studio, (width, height), Image.Resampling.LANCZOS, centering=(.5, .48))
    left, right, top, bottom = crop
    coords = (left * portrait.width, top * portrait.height, right * portrait.width, bottom * portrait.height)
    subject = portrait.transform((width, height), Image.Transform.EXTENT, coords, Image.Resampling.BICUBIC)
    background.alpha_composite(subject)
    card.alpha_composite(background, (24,24))
    card.alpha_composite(frame)
    card.alpha_composite(gem.resize((32,32), Image.Resampling.LANCZOS), (34,32))
    draw = ImageDraw.Draw(card)
    fit_text(draw, row["Nom"], 320, 294, 27, "georgiab.ttf", "#f4e7c4")
    fit_text(draw, row["Album"], 382, 284, 22, "georgia.ttf", "#39291d")
    fit_text(draw, row["Rarete"], 423, 276, 21, "georgiab.ttf", "#4b3225")
    if row["Niveau"]:
        fit_text(draw, "Niv. " + row["Niveau"], 453, 270, 17, "georgia.ttf", "#5a4030")
    return card


def export_comparison():
    zone_line = next(line for line in RUNTIME.read_text(encoding="utf8").splitlines()
                     if line.startswith('["zones"]='))
    zones = {}
    for zone_id, name in re.findall(r'\[(\d+)\]="((?:[^"\\]|\\.)*)"', zone_line):
        zones.setdefault(normalize(name.replace(r'\"', '"')), []).append(zone_id)
    entries = read_csv(COMPARE)
    manifest = []
    for row in entries:
        name = row["nom"].split(": ",1)[-1]
        ids = zones.get(normalize(name), [])
        manifest.append({
            "Nom": row["nom"], "Catégorie": row["categorie"], "Source": row["contenu_documente_sur"],
            "ID Forever": row["identifiant_forever"], "ID OctoWoW par nom": " / ".join(ids),
            "Album produit": row["nom"] if row["nom"] in ALBUMS else "",
            "Statut du comparatif": row["statut_comparaison"]
        })
    with (OUT / "Correspondances.csv").open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=manifest[0].keys())
        writer.writeheader()
        writer.writerows(manifest)
    return len(entries)


def main():
    rows = read_csv(ROOT / "Pack/Catalogue.csv")
    models = json.loads((ROOT / "modeles-source.json").read_text(encoding="utf-8-sig"))
    picks = {}
    counts = Counter()
    status = []
    with ZipFile(ROOT.parent / "Curator-1.14.3.zip") as archive:
        original_uv = archive.read("Curator/Data/Portraits.lua").decode()
        crops = {key: tuple(map(float, coords.split(","))) for key, coords in
                 re.findall(r"\[(\d+)\]\s*=\s*\{\s*([-\d., ]+)\s*\}", original_uv)}
        body = read_texture(archive, "Body.tga")
        frames = {i: read_texture(archive, f"Frame{i}.tga") for i in range(1,7)}
        gems = {i: read_texture(archive, f"Gem{i}.tga") for i in range(1,7)}
        studios = {}
        for album, (studio, _) in ALBUMS.items():
            asset = f"Studio{studio}.blp"
            if "Curator/Media/" + asset not in archive.NameToInfo:
                asset = f"Studio{FALLBACK_STUDIOS.get(studio, 'Depths')}.blp"
            studios[album] = (asset, read_texture(archive, asset))
        for row in rows:
            album, display, npc = row["Album"], row["DisplayID"], row["NPCID"]
            model = models.get(npc) or {}
            path = f"Portraits/{display}.blp"
            available = ("Curator/Media/" + path) in archive.NameToInfo and display in crops
            identity = model.get("title") and normalize(model["title"]) == normalize(row["Nom"])
            asset = studios[album][0]
            status.append({"Album": album,"PNJ": row["Nom"],"NPCID": npc,"DisplayID":display,
                           "Portrait Curator":path if available and identity else "", "Décor de prototype":asset})
            if not available or not identity:
                continue
            rarity = int(row["RareteID"])
            portrait = read_texture(archive, path)
            card = render(row, studios[album][1], frames[rarity], body, gems[rarity], portrait, crops[display])
            png = card.crop((0,0,366,512))
            folder = OUT / ALBUMS[album][1]
            folder.mkdir(exist_ok=True)
            png.save(folder / (npc + ".png"), optimize=True)
            card.save(folder / (npc + ".tga"))
            counts[album] += 1
            if album not in picks or rarity > picks[album][0]:
                picks[album] = (rarity, png)
    with (OUT / "Couverture.csv").open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=status[0].keys())
        writer.writeheader()
        writer.writerows(status)
    board = Image.new("RGB", (1190, 1140), "#171510")
    draw = ImageDraw.Draw(board)
    draw.text((26,18),"Curator · OctoWoW",font=ImageFont.truetype(str(FONT/"georgiab.ttf"),34),fill="#ead7aa")
    for index, album in enumerate(ALBUMS):
        if album in picks:
            board.paste(picks[album][1], (26 + (index%3)*386,68+(index//3)*526), picks[album][1])
    board.save(OUT/"Apercu.png")
    print("Comparatif :",export_comparison(),"entrées")
    print("Cartes :",sum(counts.values()),dict(counts))


if __name__ == "__main__":
    main()

