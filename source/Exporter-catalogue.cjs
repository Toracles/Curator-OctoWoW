const fs = require("node:fs");
const csv = value => '"' + String(value ?? "").replaceAll('"', '""') + '"';
const rows = JSON.parse(fs.readFileSync("catalogue-source.json"));
const models = JSON.parse(fs.readFileSync("modeles-source.json"));
const rarityNames = ["", "Commune", "Peu commune", "Rare", "Épique", "Légendaire", "Mythique"];
const output = rows.map(row => {
    const model = models[row.npc];
    const display = model?.display || 0;
    const art = display && fs.existsSync("Pack/Portraits/" + display + ".tga") ? "Portraits/" + display + ".tga" : "";
    return {...row, display, art, url: "https://octowow.st/db/?npc=" + row.npc };
});
fs.writeFileSync("Pack/Catalogue.csv", "\uFEFF" + [
    "Album,ZoneID,NPCID,Nom,Niveau,Rang,RareteID,Rarete,DisplayID,Illustration,Fiche",
    ...output.map(row => [row.album,row.area,row.npc,row.name,row.level,row.rank,row.rarity,
        rarityNames[row.rarity],row.display || "",row.art,row.url].map(csv).join(",")),
].join("\r\n") + "\r\n");
const quote = value => '"' + value.replaceAll("\\","\\\\").replaceAll('"','\\"') + '"';
fs.writeFileSync("Pack/Catalogue.lua", [
    "-- Data for the Curator OctoWoW port (Lua 5.0 compatible).",
    "-- ZoneID -> NPCID -> { name, level, game rank, card rarity, display ID, TGA path }.",
    "CuratorOctoCatalog = {",
    ...[...new Set(output.map(row => row.area))].flatMap(area => [
        "  [" + area + "] = { -- " + output.find(row => row.area === area).album,
        ...output.filter(row => row.area === area).map(row => "    [" + row.npc + "] = { "
            + [quote(row.name), quote(row.level), row.rank,row.rarity,row.display,quote(row.art)].join(", ") + " },"),
        "  },",
    ]),
    "}", "",
].join("\n"));
if (new Set(output.map(row => row.area + ":" + row.npc)).size !== output.length) throw new Error("Duplicate row");
console.log(JSON.stringify({cards:output.length, modeled:output.filter(row => row.display).length,
    illustrated:output.filter(row=>row.art).length, uniqueTga:new Set(output.map(row=>row.art).filter(Boolean)).size,
    rarity: rarityNames.slice(1).map((name,index)=>[name,output.filter(row=>row.rarity===index+1).length])}));
