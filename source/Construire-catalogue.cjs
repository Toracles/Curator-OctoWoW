const fs = require("node:fs");
const path = require("node:path");
const addons = "C:/Games/OctoWoW/Interface/AddOns";
const runtime = path.join(addons, "Questie-Octo/Data/runtime");
const albums = new Map([
    [5087, ["Stormwind Vault", "StormwindVault", "Volkan Cruelblade"]],
    [5103, ["Hateforge Quarry", "HateforgeQuarry", "Har'gesh Doomcaller"]],
    [5179, ["Gilneas"]],
    [5208, ["Gilneas City", "GilneasCity", "Genn Greymane"]],
    [5225, ["Thalassian Highlands"]],
    [5581, ["Northwind"]],
]);
const nameLine = fs.readFileSync(path.join(runtime, "enUS.lua"), "utf8").split(/\r?\n/)
    .find(line => line.startsWith('["units"]='));
const names = new Map(Array.from(nameLine.matchAll(/\[(\d+)\]="((?:[^"\\]|\\.)*)"/g),
    match => [Number(match[1]), match[2].replace(/\\["\\]/g, value => value[1]).replace(/\\t/g, " ").trim()]));
const bosses = new Map();
for (const [area, [, instance]] of albums) {
    if (!instance) continue;
    const file = path.join(addons, "Atlas-CFM/CFMLoot/Data/Instances", instance + ".lua");
    bosses.set(area, new Set(Array.from(fs.readFileSync(file, "utf8").matchAll(/name = LB\["([^"]+)"\]/g), match => match[1])));
}
bosses.get(5087).add("Arc'tiras");
const rows = [];
for (const line of fs.readFileSync(path.join(runtime, "units.lua"), "utf8").split(/\r?\n/)) {
    const entry = line.match(/^\[(\d+)\]=\{\["coords"\]=\{(\{[^\r\n]*?\}|)\}(.*)$/);
    if (!entry) continue;
    const npc = Number(entry[1]);
    const name = names.get(npc);
    if (!name || !/[a-z]/i.test(name) || /\b(?:invisible|trigger|placeholder|waypoint|controller|dummy)\b|^_/i.test(name)) continue;
    const zones = new Set(Array.from(entry[2].matchAll(/\{[^,]+,[^,]+,(\d+),[^}]+\}/g), match => Number(match[1])));
    const level = entry[3].match(/\["lvl"\]="([^"]*)"/)?.[1] ?? "";
    const rank = Number(entry[3].match(/\["rnk"\]="(\d+)"/)?.[1] ?? 0);
    for (const area of zones) {
        if (!albums.has(area)) continue;
        const [album, , finalBoss] = albums.get(area);
        const rarity = name === finalBoss ? 6 : rank === 3 ? 5
            : bosses.get(area)?.has(name) || rank === 2 ? 4
            : rank === 4 ? 3 : rank === 1 ? 2 : 1;
        rows.push({ album, area, npc, name, level, rank, rarity });
    }
}
rows.sort((a,b) => a.area - b.area || a.npc - b.npc);
const output = process.argv[2];
fs.writeFileSync(output, JSON.stringify(rows, null, 2));
for (const [area, [album]] of albums) {
    const zoneRows = rows.filter(row => row.area === area);
    console.log(album, zoneRows.length, zoneRows.filter(row => row.rarity >= 4).map(row => row.name));
}


