"""Read the resolved NPC and area data from the installed Questie-Octo."""
import os
from collections import defaultdict
from pathlib import Path
import re

GAME = Path(os.environ.get("OCTOWOW_GAME", "C:/Games/OctoWoW"))
ADDONS = GAME / "Interface/AddOns"
RUNTIME = ADDONS / "Questie-Octo/Data/runtime"
STRING_FIELD = re.compile(r'\[(\d+)\]="((?:[^"\\]|\\.)*)"')
SPAWN = re.compile(r'\{[^,{}]+,[^,{}]+,(\d+),[^,{}]+\}')
ENTRY = re.compile(r'^\[(\d+)\]=\{\["coords"\]=\{(.*?)\},(.*)\},?$')

EXTRA = {
    408: ("gillijim", "Stranglethorn", 48, 53, None, None),
    409: ("lapidis", "Stranglethorn", 48, 53, None, None),
    5121: ("telabim", "Stranglethorn", 54, 60, None, None),
    5536: ("blackstone", "Durotar", 1, 16, None, None),
    5561: ("balor", "Hinterlands", 28, 40, None, None),
    5077: ("crescentgrove", "Blackfathom", 32, 38, "TheCrescentGrove", None),
    5086: ("karazhancrypt", "Scholomance", 58, 60, "KarazhanCrypt", None),
    5097: ("emeraldsanctum", "Ashenvale", 60, 60, "EmeraldSanctum", 2),
    5204: ("blackmorass", "Swamp", 58, 60, "TheBlackMorass", None),
    5601: ("dragonmawretreat", "Depths", 25, 60, "DragonmawRetreat", None),
    5628: ("stormwrought", "Shadowfang", 34, 40, "StormwroughtRuins", None),
    5641: ("windhorn", "Mulgore", 15, 60, "WindhornCanyon", None),
    5723: ("lowerkarazhan", "Scholomance", 60, 60, "LowerKarazhanHalls", 1),
    3457: ("towerkarazhan", "Naxxramas", 60, 60, "TowerofKarazhan", 3),
}
EXCLUDED = ("Zephras", "Thanes", "Dalaran", "Excavation", "Lordaeron", "Hardcup")


def normalized(value):
    return " ".join(value.strip().replace("’", "'").casefold().split())


def read_data():
    locale = (RUNTIME / "enUS.lua").read_text(encoding="utf8").splitlines()
    def names(field):
        line = next(line for line in locale if line.startswith(f'["{field}"]='))
        return {int(key): value.replace(r'\"', '"').replace(r'\t', " ").strip()
                for key, value in STRING_FIELD.findall(line)}
    zones = names("zones")
    units = names("units")
    parents = {}
    for child, parent in re.findall(r'^\[(\d+)\]=\{(\d+),', (RUNTIME / "zones.lua").read_text(encoding="utf8"), re.M):
        parents[int(child)] = int(parent)
    spawns = defaultdict(dict)
    for line in (RUNTIME / "units.lua").read_text(encoding="utf8").splitlines():
        entry = ENTRY.match(line)
        if not entry:
            continue
        npc, coords, fields = entry.groups()
        npc = int(npc)
        name = units.get(npc)
        if not name or not re.search(r"[a-z]", name, re.I) or re.search(
                r"\b(?:invisible|trigger|placeholder|waypoint|controller|dummy)\b|^_", name, re.I):
            continue
        rank = re.search(r'\["rnk"\]="(\d+)"', fields)
        level = re.search(r'\["lvl"\]="([^"]+)"', fields)
        row = {"NPCID": str(npc), "Nom": name, "Niveau": level[1] if level else "",
               "Rang": int(rank[1]) if rank else 0, "DisplayID": ""}
        for area in set(map(int, SPAWN.findall(coords))):
            spawns[area][npc] = row
    return zones, units, parents, spawns


def expand(config, groups):
    zones, units, parents, spawns = read_data()
    selected = {int(row["NPCID"]) for rows in groups.values() for row in rows}
    raids = {}
    bosses_by_area = {}
    for area, (key, studio, low, high, atlas, raid) in EXTRA.items():
        candidates = dict(spawns.get(area, {}))
        boss_names = []
        if atlas:
            source = ADDONS / "Atlas-CFM/CFMLoot/Data/Instances" / (atlas + ".lua")
            boss_names = re.findall(r'name = LB\["([^"]+)"\]', source.read_text(encoding="utf8"))
            # Some custom instances have encounter names but no spawn records in Questie.
            for npc, name in units.items():
                if name in boss_names:
                    candidates.setdefault(npc, {"NPCID": str(npc), "Nom": name, "Rang": 1,
                                                "Niveau": str(high), "DisplayID": ""})
        bosses = {npc for npc, row in candidates.items() if row["Nom"] in boss_names}
        final = next((npc for name in reversed(boss_names) for npc, row in candidates.items()
                      if row["Nom"] == name and npc not in selected), None)
        for npc, row in sorted(candidates.items()):
            if npc in selected:
                continue
            rank = row["Rang"]
            rarity = 6 if npc == final else 4 if npc in bosses or rank in (2, 3) else 3 if rank == 4 else 2 if rank == 1 else 1
            groups[area].append({**row, "RareteID": rarity})
            selected.add(npc)
        if groups[area]:
            config[area] = (key, zones[area], studio, low, high, final)
            if atlas:
                bosses_by_area[area] = bosses
            if raid:
                raids[area] = raid
    return zones, units, parents, raids, bosses_by_area


def filter_classic(path, units):
    text = path.read_text(encoding="utf8")
    hallow = path.stem == "Hallow"
    if not hallow and 'kind = "zone"' not in text and 'kind = "dungeon"' not in text:
        return 0
    # Only inspect the main card table. Auxiliary tables use different schemas.
    start = text.find("\tcards = {")
    end = text.find("\n\t},", start)
    if start < 0 or end < 0:
        return 0
    names = {}
    english = re.search(r'\benUS\s*=\s*\{([^\n]*)', text[end:])
    if english:
        names = dict(re.findall(r'\[(\d+)\]\s*=\s*"((?:[^"\\]|\\.)*)"', english[1]))
    removed = 0
    def keep(match):
        nonlocal removed
        npc = match[1]
        target = units.get(int(npc) - (9000000 if hallow else 0))
        upstream_name = names.get(npc, match[2]).replace(r'\"', '"')
        if hallow:
            upstream_name = re.sub(r" \([a-z]+\)$", "", upstream_name)
        if target and normalized(target) == normalized(upstream_name):
            return match[0]
        removed += 1
        return ""
    cards = re.sub(r'^\t\t\{\s*(\d+),[^\n]+?\},\s*-- ([^\n]+)(?:\n|$)', keep, text[start:end], flags=re.M)
    result = text[:start] + cards + text[end:]
    if path.stem == "Depths":
        result = result.replace("area = 1585", "area = 1584", 1)
    if result != text:
        path.write_bytes(result.encode("utf8"))
    return removed
