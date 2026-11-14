"""Generate OctoWoW albums in the upstream Curator schema."""
from collections import defaultdict
from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / "full-port-work" / "Curator"
CONFIG = {
    5179: ("gilneas", "Gilneas", "Duskwood", 39, 46, None),
    5208: ("gilneascity", "Gilneas City", "Shadowfang", 43, 49, 61418),
    5581: ("northwind", "Northwind", "Elwynn", 30, 40, None),
    5225: ("thalassian", "Thalassian Highlands", "Hinterlands", 15, 20, None),
    5103: ("hateforge", "Hateforge Quarry", "Depths", 52, 60, 60737),
    5087: ("stormwindvault", "Stormwind Vault", "Stockade", 60, 60, 80851),
}


def quote(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


with (ROOT / "data" / "Catalogue.csv").open(encoding="utf-8-sig", newline="") as source:
    groups = defaultdict(list)
    for row in csv.DictReader(source):
        area = int(row["ZoneID"])
        if area in CONFIG:
            groups[area].append(row)

lines = [
    "-- OctoWoW supplemental series, generated from the local Questie-Octo catalogue.",
    "local ns = CuratorOctoFull",
]
for area, (key, name, studio, minimum, maximum, final) in CONFIG.items():
    rows = groups[area]
    assert rows
    bosses = [int(row["NPCID"]) for row in rows if final and int(row["RareteID"]) >= 4]
    if final:
        assert final in bosses
    lines.extend([
        "table.insert(ns.Series, {",
        f'    key = "{key}", kind = "{("dungeon" if final else "zone")}", area = {area},',
        f'    name = {quote(name)}, levels = {{ {minimum}, {maximum} }},',
        '    side = "C", cont = "EK",',
        '    tint = { .22, .18, .10 }, glow = { .95, .72, .42 },',
        f'    studio = "Studio{studio}", pack = "Pack{studio}", set = "Set{studio}",',
    ])
    if final:
        boss_ids = ", ".join(map(str, bosses))
        lines.append(f"    instance = {area}, bosses = {{ {boss_ids} }}, final = {final},")
    else:
        lines.append(f"    map = {area},")
    lines.append("    cards = {")
    for row in rows:
        levels = [int(token) for token in re.findall(r"\d+", row["Niveau"])] or [minimum]
        fields = [int(row["NPCID"]), int(row["RareteID"]), 0, 0,
                  levels[0], levels[-1], int(row["DisplayID"] or 0), 0, "false"]
        lines.append("        { " + ", ".join(map(str, fields)) + " },")
    lines.append("    }, names = { enUS = {")
    for row in rows:
        lines.append(f'        [{int(row["NPCID"])}] = {quote(row["Nom"])},')
    lines.extend(["    } },", "})"])
(WORK / "Data" / "OctoAlbums.lua").write_text("\n".join(lines) + "\n", encoding="utf8")

toc_path = WORK / "Curator.toc"
toc = toc_path.read_text(encoding="utf8")
toc = re.sub(r"^Data\\Zephras\.lua\n", "", toc, flags=re.M)
if "Data\\OctoAlbums.lua" not in toc:
    toc = toc.replace("Guard.lua\n", "Data\\OctoAlbums.lua\nGuard.lua\n", 1)
if "OctoZones.lua" not in toc:
    toc = toc.replace("Rewards.lua\n", "Rewards.lua\nOctoZones.lua\n", 1)
(WORK / "OctoZones.lua").write_bytes((ROOT / "full-port" / "OctoZones.lua").read_bytes())
toc_path.write_text(toc, encoding="utf8")
print(f"Added {sum(map(len, groups.values()))} cards over {len(groups)} OctoWoW albums; excluded Zephras Isle")

