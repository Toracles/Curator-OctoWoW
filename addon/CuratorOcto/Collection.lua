local C = {}
CuratorOcto = C
C.media = "Interface\\AddOns\\CuratorOcto\\Media\\"
C.albums = {
    { id = 5179, name = "Gilneas", art = "Duskwood" },
    { id = 5208, name = "Gilneas City", art = "Shadowfang", boss = 61418 },
    { id = 5581, name = "Northwind", art = "Elwynn" },
    { id = 5225, name = "Thalassian Highlands", art = "Hinterlands" },
    { id = 5103, name = "Hateforge Quarry", art = "Depths", boss = 60737 },
    { id = 5087, name = "Stormwind Vault", art = "Stockade", boss = 80851 },
}
C.colors = {
    {1,.92,.75}, {.36,1,.42}, {.35,.62,1}, {.74,.38,1}, {1,.68,.18}, {1,.2,.3},
}
C.rarities = {"Commune", "Peu commune", "Rare", "Epique", "Legendaire", "Mythique"}
C.zoneOdds = {{6,.0005},{5,.0025},{4,.012},{3,.065},{2,.22}}
C.dungeonOdds = {{5,.01},{4,.10}}
C.byZone = {}
for _, album in ipairs(C.albums) do
    C.byZone[album.id] = album
    album.cards = {}
    album.byName = {}
    album.pools = {{},{},{},{},{},{}}
    for id, fields in pairs(CuratorOctoCatalog[album.id]) do
        local card = {id=id, name=fields[1], level=fields[2], rank=fields[3], rarity=fields[4], album=album}
        table.insert(album.cards, card)
        table.insert(album.pools[card.rarity], card)
        album.byName[string.lower(card.name)] = card
    end
    table.sort(album.cards, function(a,b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.name < b.name
    end)
end

function C.Init()
    if type(CuratorOctoDB) ~= "table" then CuratorOctoDB = {} end
    local db = CuratorOctoDB
    db.packs = db.packs or {}
    db.cards = db.cards or {}
    db.points = db.points or {}
    db.characters = db.characters or {}
    C.db = db
end

function C.CardKey(card)
    return card.album.id .. ":" .. card.id
end

function C.Owned(card)
    return C.db.cards[C.CardKey(card)]
end

local function give(card, finish)
    local key = C.CardKey(card)
    local entry = C.db.cards[key] or {count=0, shiny=0, holo=0}
    entry.count = entry.count + 1
    if finish then entry[finish] = entry[finish] + 1 end
    C.db.cards[key] = entry
end

function C.Find(card, boss)
    local ordinary = {.012,.008,.005,.003,.0015,.0005}
    local bosses = {[3]=.03,[4]=.02,[5]=.008,[6]=.003}
    if math.random() < ((boss and bosses[card.rarity]) or ordinary[card.rarity]) then
        give(card)
        return true
    end
end

function C.Packs(album)
    return C.db.packs[album.id] or 0
end

function C.GivePack(album)
    C.db.packs[album.id] = C.Packs(album) + 1
end

local function roll(odds, fallback)
    local chance = math.random()
    for _, pair in ipairs(odds) do
        chance = chance - pair[2]
        if chance < 0 then return pair[1] end
    end
    return fallback
end

local function choose(album, rarity, used)
    for rank = rarity, 1, -1 do
        local candidates = {}
        for _, card in ipairs(album.pools[rank]) do
            if not used[card.id] then table.insert(candidates, card) end
        end
        if table.getn(candidates) > 0 then return candidates[math.random(table.getn(candidates))] end
    end
    for _, card in ipairs(album.cards) do
        if not used[card.id] then return card end
    end
end

function C.OpenPack(album, preview)
    if not preview and C.Packs(album) < 1 then return end
    local order, used, picks = {}, {}, {}
    local count = math.min(album.boss and 5 or 8, table.getn(album.cards))
    for i = 1, count do
        order[i] = {slot=i, rank=roll(album.boss and C.dungeonOdds or C.zoneOdds, album.boss and 3 or 1)}
    end
    table.sort(order, function(a,b)
        if a.rank == b.rank then return a.slot < b.slot end
        return a.rank > b.rank
    end)
    if album.boss and math.random() < .005 then order[1].rank = 6 end
    local best = 1
    for _, draw in ipairs(order) do
        local card = choose(album, draw.rank, used)
        used[card.id] = true
        local finishRoll = math.random()
        local finish
        if finishRoll < .01 then finish = "holo"
        elseif finishRoll < (album.boss and .023 or .02) then finish = "shiny" end
        picks[draw.slot] = {card=card, finish=finish, fresh=not C.Owned(card)}
        best = math.max(best, card.rarity)
    end
    if not preview then
        C.db.packs[album.id] = C.Packs(album) - 1
        for _, pick in ipairs(picks) do give(pick.card, pick.finish) end
    end
    return picks, best
end


