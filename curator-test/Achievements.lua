local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local C = ns.Collection

-- Achievements: goals of the collection, worth points. Each one has a value (where the player is)
-- and a goal; it is earned when the value reaches the goal, once and for good. The general ones
-- come first, then one per album, in the order of the data: the place of an achievement in the
-- list is its bit in what other players receive, so new ones are only ever added at the end.
local AC = { list = {}, byId = {} }
ns.Achievements = AC

-- (1.9.0: the quests and the PvP, each a category of its own; the achievements of PvP of 1.8.0 go there)
-- (1.14.0, after the test of the cases, his word: the PvP gone until its rework, its achievements with it, those of its
-- quests among the quests; the cases, a category of their own; the secret ones, "?" and their riddle, a category of
-- their own, out of the feats)
AC.CATEGORIES = { "boosters", "collection", "rarity", "finish", "albums", "bestiary", "contracts", "adventure", "quests", "cases", "social", "feats", "secret" }
AC.LABEL = {
	boosters = "Boosters", collection = "Collection", rarity = "Rarities", finish = "Finishes", albums = "Albums",
	bestiary = "Bestiary", contracts = "Contracts", adventure = "Adventure", quests = "Quests", pvp = "PvP", social = "Social", feats = "Feats",
	cases = "Cases", secret = "Secret",
}

-- The icons: an icon of the game, or a texture of the addon's media (its crop, its colour).
local ICON = {
	booster = { "Icon" },
	card = { "Back", { 0.07, 0.65, 0.21, 0.79 } },
	seal = { "Interface\\Icons\\INV_Scroll_03" },
	-- (1.3: the finishes are thunderforged and titanforged: lightning, the shard of the titans)
	shiny = { "Interface\\Icons\\Spell_Nature_Lightning" },
	holo = { "Interface\\Icons\\INV_Enchant_ShardPrismaticLarge" },
	eye = { "Interface\\Icons\\INV_Misc_Spyglass_03" },
	find = { "Interface\\Icons\\INV_Box_01" },
}

local function Def(t)
	t.index = CuratorOctoFull.Length(AC.list) + 1
	AC.list[t.index] = t
	AC.byId[t.id] = t
	return t
end
-- (1.13.0) the same for the files loaded after this one (with AC.After1130: Restore.lua, Displays.lua)
AC.Define = Def

-- The general achievements added after the albums came (0.22 and later): they go after those of the
-- albums, so that the bits of the older ones stay where they were for every player.
local late = {}
local function Later(fn)
	late[CuratorOctoFull.Length(late) + 1] = fn
end

-- A series of tiers: "Boosters opened: 100" and so on. They make a group (one line of medals on the
-- page), its title: title.
AC.GROUPS = {}
local function Group(key, title, icon)
	local g = AC.GROUPS[key]
	if not g then
		g = { key = key, title = title, icon = icon, list = {} }
		AC.GROUPS[key] = g
	end
	return g
end

local function Tiers(cat, prefix, icon, tiers, value, desc, title)
	local g = Group(prefix, title, icon)
	for i, t in ipairs(tiers) do
		local a = Def({ id = prefix .. t[1], cat = cat, goal = t[1], pts = t[2], name = t[3], icon = icon, value = value, desc = desc, group = g, tier = i })
		g.list[i] = a
	end
end

local function Count(set)
	local n = 0
	for _ in pairs(set or {}) do
		n = n + 1
	end
	return n
end

-------------------------------------------------------------------------------
-- The general achievements (their order is part of what players share: add new ones at the end)
-------------------------------------------------------------------------------
Tiers("boosters", "b", ICON.booster, {
	{ 1, 5, "First booster" }, { 10, 5, "Taste for it" }, { 50, 10, "Regular" }, { 100, 10, "Collector" },
	{ 250, 25, "Enthusiast" }, { 500, 25, "Booster addict" }, { 1000, 50, "A thousand and one boosters" },
}, function(_, db)
	return db.opened or 0
end, function(a)
	return string.format(L["Boosters opened: %d"], a.goal)
end, "Boosters opened")

Tiers("collection", "c", ICON.card, {
	{ 25, 5, "First pages" }, { 100, 5, "Well filled" }, { 500, 10, "Librarian" }, { 1000, 10, "Archivist" },
	{ 2500, 25, "Curator" }, { 5000, 50, "Great collector" },
}, function(sn)
	return sn.owned
end, function(a)
	return string.format(L["Different cards: %d"], a.goal)
end, "Different cards")
Def({ id = "call", cat = "collection", pts = 100, name = "All of Azeroth", icon = ICON.card,
	value = function(sn) return sn.owned end, goalOf = function(sn) return sn.total end,
	desc = function() return L["Every card of every album."] end })

local RARITY_GROUP = { [4] = "Epic cards", [5] = "Legendary cards", [6] = "Mythic cards" }
local function Rarity(id, r, goal, pts, name)
	local g = Group("r" .. r, RARITY_GROUP[r], { "Gem" .. r })
	local a = Def({ id = id, cat = "rarity", pts = pts, name = name, icon = { "Gem" .. r }, goal = goal,
		value = function(sn) return sn.byRarity[r] end,
		desc = function(x)
			local rr = ns.RARITY[r]
			return string.format(L["Different cards of rarity %s: %d"], L[rr.label], x.goal)
		end, group = g, tier = CuratorOctoFull.Length(g.list) + 1 })
	g.list[CuratorOctoFull.Length(g.list) + 1] = a
end
Rarity("e1", 4, 1, 5, "Epic!")
Rarity("e25", 4, 25, 10, "Epic collection")
Rarity("l1", 5, 1, 10, "Legendary!")
Rarity("l25", 5, 25, 25, "Living legend")
Rarity("m1", 6, 1, 25, "Mythic!")
Rarity("m10", 6, 10, 50, "Pantheon")
Def({ id = "mall", cat = "rarity", pts = 100, name = "Every myth", icon = { "Gem6" },
	value = function(sn) return sn.byRarity[6] end, goalOf = function(sn) return sn.mythics end,
	desc = function() return L["Every mythic card."] end })

-- (1.3: the shiny cards became thunderforged, the holographic ones titanforged; their achievements
-- keep their places, their names follow)
Tiers("finish", "s", ICON.shiny, {
	{ 1, 5, "Struck by lightning" }, { 10, 10, "Storm chaser" }, { 50, 25, "Lord of thunder" },
}, function(sn)
	return sn.shiny
end, function(a)
	return string.format(L["Different thunderforged cards: %d"], a.goal)
end, "Thunderforged cards")
Tiers("finish", "h", ICON.holo, {
	{ 1, 10, "Touched by the titans" }, { 10, 25, "Forged by the titans" },
}, function(sn)
	return sn.holo
end, function(a)
	return string.format(L["Different titanforged cards: %d"], a.goal)
end, "Titanforged cards")
Def({ id = "hm", cat = "finish", pts = 100, name = "Myth of the titans", icon = ICON.holo, goal = 1,
	value = function(sn) return sn.holoMythic and 1 or 0 end,
	desc = function() return L["A titanforged mythic card."] end })

-- albums: half of one, one, the four families, all of them (one each for every album comes later)
Def({ id = "half", cat = "albums", pts = 5, name = "Halfway", icon = ICON.card, goal = 1,
	value = function(sn) return sn.half and 1 or 0 end,
	desc = function() return L["Half of an album."] end })
Def({ id = "one", cat = "albums", pts = 10, name = "Album complete", icon = ICON.card, goal = 1,
	value = function(sn) return sn.complete > 0 and 1 or 0 end,
	desc = function() return L["A complete album."] end })
local FAMILY = {
	ek = function(s) return not s.dungeon and s.cont == "EK" end,
	ka = function(s) return not s.dungeon and s.cont == "K" end,
	dun = function(s) return s.dungeon and not s.raid end,
	raid = function(s) return s.raid ~= nil end,
	all = function() return true end,
}
for _, f in ipairs({ { "ek", 50, "Eastern Kingdoms" }, { "ka", 50, "Kalimdor" }, { "dun", 50, "Dungeon master" },
	{ "raid", 50, "Conqueror" }, { "all", 200, "Fully Curated" } }) do
	local _, f = _, f; local fam = FAMILY[f[1]]
	Def({ id = "f" .. f[1], cat = "albums", pts = f[2], name = f[3], icon = ICON.card,
		value = function(sn) return sn.families[f[1]] or 0 end,
		goalOf = function(sn) return sn.familySize[f[1]] or 0 end,
		desc = function(a, sn) return string.format(L["Complete albums: %d"], sn and a.goalOf(sn) or 0) end,
		family = fam })
end

Tiers("contracts", "k", ICON.seal, {
	{ 1, 5, "Signed and sealed" }, { 10, 10, "Notary" }, { 50, 25, "Jurist" },
}, function(_, db)
	return db.contracts or 0
end, function(a)
	return string.format(L["Contracts signed: %d"], a.goal)
end, "Contracts signed")
-- (1.13.0, after its second test: a contract gives a legendary card at most; the pact of before, a mythic card from a
-- contract, kept by those who made one, its key as it was)
Def({ id = "kmyth", cat = "contracts", pts = 25, name = "Legendary pact", icon = { "Gem5" }, goal = 1,
	value = function(_, db) return (db.stats.kLeg or db.stats.kMyth) and 1 or 0 end,
	desc = function() return L["A legendary card from a contract."] end })
Def({ id = "kholo", cat = "contracts", pts = 25, name = "Titanforged contract", icon = ICON.holo, goal = 1,
	value = function(_, db) return db.stats.kHolo and 1 or 0 end,
	desc = function() return L["A contract of titanforged cards."] end })

Tiers("adventure", "f", ICON.find, {
	{ 1, 5, "Lucky find" }, { 25, 10, "Rummager" },
}, function(_, db)
	return db.stats.found or 0
end, function(a)
	return string.format(L["Cards found on creatures: %d"], a.goal)
end, "Cards found on creatures")
Def({ id = "fboss", cat = "adventure", pts = 10, name = "Boss trophy", icon = ICON.find, goal = 1,
	value = function(_, db) return (db.stats.bossFound or 0) > 0 and 1 or 0 end,
	desc = function() return L["The card of a boss, found on that boss."] end })
local function Done(db, raid)
	local n = 0
	for key in pairs(db.stats.done or {}) do
		local s = ns.SeriesByKey(key)
		if s and ((raid and s.raid) or (not raid and not s.raid)) then
			n = n + 1
		end
	end
	return n
end
Tiers("adventure", "d", { "SetDeadmines" }, {
	{ 1, 5, "Dungeon cleared" }, { 10, 25, "Delver" },
}, function(_, db)
	return Done(db, false)
end, function(a)
	return string.format(L["Different dungeons completed: %d"], a.goal)
end, "Dungeons completed")
Tiers("adventure", "r", { "SetMoltencore" }, {
	{ 1, 10, "Raid cleared" }, { 7, 50, "Raid veteran" },
}, function(_, db)
	return Done(db, true)
end, function(a)
	return string.format(L["Different raids completed: %d"], a.goal)
end, "Raids completed")

Tiers("social", "v", ICON.eye, {
	{ 1, 5, "Curious" }, { 10, 10, "Connoisseur" }, { 50, 25, "Art critic" },
}, function(_, db)
	return Count(db.stats.seen)
end, function(a)
	return string.format(L["Collections of other players viewed: %d"], a.goal)
end, "Collections viewed")

local function Feat(id, pts, name, icon, desc)
	Def({ id = id, cat = "feats", pts = pts, name = name, icon = icon, goal = 1,
		value = function(_, db) return db.stats[id] and 1 or 0 end,
		desc = function() return L[desc] end })
end
Feat("lucky", 10, "Beginner's luck", { "Gem5" }, "A legendary card or better in your first 10 boosters.")
Feat("double", 25, "Double", ICON.shiny, "Two cards with a finish (thunderforged, titanforged) in the same booster.")
Feat("pity", 5, "At last!", { "Gem4" }, "The epic card of the guarantee, after 11 boosters without one.")
-- (1.2: no more epic card sure to come; shown only to those who earned it)
AC.byId.pity.onlyEarned = true
Feat("jackpot", 50, "Jackpot", ICON.holo, "A legendary card or better with a finish (thunderforged, titanforged), in a booster.")

-- The trades (0.22): the players traded with, a gift, a card looked for that came, a mythic card traded.
Later(function()
	Tiers("social", "x", { "Swap" }, {
		{ 1, 5, "First trade" }, { 5, 10, "Well connected" }, { 15, 25, "Merchant prince" },
	}, function(_, db)
		return Count(db.stats.partners)
	end, function(a)
		return string.format(L["Different players traded with: %d"], a.goal)
	end, "Trading partners")
	Feat("gift", 5, "Generous", { "Gift" }, "A gift to another player: a trade where nothing comes back.")
	Feat("wish", 10, "Wish granted", { "Seek" }, "A card you were looking for, from a trade.")
	Feat("tMyth", 25, "Mythic deal", { "Gem6" }, "A mythic card traded, given or received.")
end)

-- The testers of the closed beta (0.23, then 1.1 to 1.7): earned by playing it (the mark of the save, Beta.lua),
-- kept when the collection starts over.
Later(function()
	Def({ id = "beta", gone = true })
end)

-------------------------------------------------------------------------------
-- (1.5.0) After the albums of Zephras, in this order (the bits of the older achievements stay where
-- they are; what comes later goes after these): the bestiary (the types of the creatures, the
-- families of the beasts), tiers that go further, the secret feats.
-------------------------------------------------------------------------------
local last = {}
local function Last(fn)
	last[CuratorOctoFull.Length(last) + 1] = fn
end

-- More tiers for a group: its category, its icon, its value and its description are those of its
-- first tier. { goal, points, name } or, for every card of something, { "all", points, name, goalOf,
-- desc }.
local function More(prefix, tiers)
	local g = AC.GROUPS[prefix]
	local first = g.list[1]
	for _, t in ipairs(tiers) do
		local i = CuratorOctoFull.Length(g.list) + 1
		local all = t[1] == "all"
		local a = Def({ id = prefix .. tostring(t[1]), cat = first.cat, pts = t[2], name = t[3], icon = first.icon, value = first.value,
			goal = (not all) and t[1] or nil, goalOf = all and t[4] or nil, desc = all and t[5] or first.desc, group = g, tier = i })
		g.list[i] = a
	end
end

-- The types of creatures of the cards (their number in the data), their name, their tiers ("all":
-- every card of that type), their icon. (The humanoids are most of the cards: "Different cards" counts
-- them.)
AC.KINDS = {
	{ t = 1, name = "Beasts", icon = { "Interface\\Icons\\Ability_Hunter_BeastTaming" },
		tiers = { { 50, 10, "Into the Wild" }, { 250, 25, "Wild at Heart" }, { "all", 50, "Lord of the Wilds" } } },
	{ t = 6, name = "Undead", icon = { "Interface\\Icons\\Spell_Shadow_RaiseDead" },
		tiers = { { 25, 10, "Grave Robber" }, { 100, 25, "Necrologist" }, { "all", 50, "The Scourge" } } },
	{ t = 4, name = "Elementals", icon = { "Interface\\Icons\\Spell_Nature_EarthElemental_Totem" },
		tiers = { { 25, 10, "Elemental Touch" }, { 100, 25, "Elementalist" }, { "all", 50, "Heart of the Elements" } } },
	{ t = 3, name = "Demons", icon = { "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
		tiers = { { 10, 10, "Fel Touched" }, { 50, 25, "Summoner" }, { "all", 50, "The Burning Legion" } } },
	{ t = 2, name = "Dragonkin", icon = { "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
		tiers = { { 10, 10, "Scales and Flames" }, { 50, 25, "Dragonwatcher" }, { "all", 50, "Dragonflight" } } },
	{ t = 5, name = "Giants", icon = { "Interface\\Icons\\Ability_Warrior_Rampage" }, tiers = { { "all", 25, "Giant Steps" } } },
	{ t = 9, name = "Mechanical", icon = { "Interface\\Icons\\INV_Gizmo_02" }, tiers = { { "all", 25, "Gears and Cogs" } } },
	{ t = 8, name = "Critters", icon = { "Interface\\Icons\\Spell_Nature_Polymorph" }, tiers = { { "all", 10, "Friend of Critters" } } },
}

-- The families of the beasts (their number in the data), their name, the name of their achievement,
-- the icon of their pets.
AC.BEASTS = {
	{ f = 1, name = "Wolves", ach = "The Pack", icon = "Wolf" },
	{ f = 2, name = "Cats", ach = "Nine Lives", icon = "Cat" },
	{ f = 3, name = "Spiders", ach = "Arachnophobia", icon = "Spider" },
	{ f = 4, name = "Bears", ach = "Hibernation", icon = "Bear" },
	{ f = 5, name = "Boars", ach = "Tusks and Bristles", icon = "Boar" },
	{ f = 6, name = "Crocolisks", ach = "Snap!", icon = "Crocolisk" },
	{ f = 7, name = "Carrion Birds", ach = "Circling Overhead", icon = "Vulture" },
	{ f = 8, name = "Crabs", ach = "Sideways", icon = "Crab" },
	{ f = 9, name = "Gorillas", ach = "King of the Jungle", icon = "Gorilla" },
	{ f = 11, name = "Raptors", ach = "Jurassic", icon = "Raptor" },
	{ f = 12, name = "Tallstriders", ach = "Long Strides", icon = "TallStrider" },
	{ f = 20, name = "Scorpids", ach = "Sting", icon = "Scorpid" },
	{ f = 21, name = "Turtles", ach = "Slow and Steady", icon = "Turtle" },
	{ f = 24, name = "Bats", ach = "Night Wings", icon = "Bat" },
	{ f = 25, name = "Hyenas", ach = "Laughing Pack", icon = "Hyena" },
	{ f = 26, name = "Owls", ach = "Wide Eyes", icon = "Owl" },
	{ f = 27, name = "Wind Serpents", ach = "Wind Riders", icon = "WindSerpent" },
}

-- The bestiary: the tiers of each type (a single one: on its own card), each family, every family.
Last(function()
	for _, k in ipairs(AC.KINDS) do
		local _, k = _, k; local t = k.t
		local g = CuratorOctoFull.Length(k.tiers) > 1 and Group("t" .. t, k.name, k.icon) or nil
		for i, x in ipairs(k.tiers) do
			local i, x = i, x; local all = x[1] == "all"
			local a = Def({ id = string.format(("t%d:%s"), t, tostring(x[1])), cat = "bestiary", pts = x[2], name = x[3], icon = k.icon,
				goal = (not all) and x[1] or nil,
				goalOf = all and function(sn) return sn.kindSize[t] or 0 end or nil,
				value = function(sn) return sn.kinds[t] or 0 end,
				desc = all and function() return string.format(L["%s: every card."], L[k.name]) end
					or function(a) return string.format(L["%s: %d different cards"], L[k.name], a.goal) end,
				group = g, tier = g and i or nil, kind = t })
			if g then
				g.list[i] = a
			end
		end
	end
	for _, b in ipairs(AC.BEASTS) do
		local _, b = _, b; local f = b.f
		Def({ id = "fam:" .. f, cat = "bestiary", pts = 10, name = b.ach, icon = { "Interface\\Icons\\Ability_Hunter_Pet_" .. b.icon },
			goalOf = function(sn) return sn.beastSize[f] or 0 end, value = function(sn) return sn.beasts[f] or 0 end,
			desc = function() return string.format(L["%s: every card."], L[b.name]) end, beast = f })
	end
	Def({ id = "bmaster", cat = "bestiary", pts = 50, name = "Beastmaster", icon = { "Interface\\Icons\\Ability_Hunter_BeastMastery" },
		goalOf = function(sn) return sn.beastFamilies end, value = function(sn) return sn.beastDone end,
		desc = function() return L["Every card of every family of beasts."] end })
end)

-- Tiers that go further: the boosters opened, the epic, legendary and mythic cards, the finishes, the
-- contracts, the cards found on the creatures, the partners of the trades; the copies in all.
Last(function()
	More("b", { { 2500, 50, "Booster fiend" }, { 5000, 50, "Unstoppable" }, { 10000, 100, "Ten thousand boosters" } })
	More("r4", { { 100, 10, "Epic tale" }, { 250, 25, "Epic saga" },
		{ "all", 50, "Every epic", function(sn) return sn.rarSize[4] end, function() return L["Every epic card."] end } })
	More("r5", { { 50, 25, "Legend hunter" },
		{ "all", 100, "Every legend", function(sn) return sn.rarSize[5] end, function() return L["Every legendary card."] end } })
	More("r6", { { 25, 50, "Mythographer" }, { 50, 50, "Olympus" } })
	More("s", { { 100, 25, "Thunderstruck" }, { 250, 50, "Eye of the storm" } })
	More("h", { { 25, 25, "Chosen of the titans" }, { 50, 50, "Heir of the titans" } })
	More("k", { { 100, 25, "Magistrate" }, { 250, 50, "High chancellor" } })
	More("f", { { 100, 25, "Treasure seeker" }, { 250, 50, "Nothing escapes me" } })
	More("x", { { 30, 25, "Trade baron" }, { 50, 50, "Trade magnate" } })
	Tiers("collection", "n", ICON.card, {
		{ 1000, 10, "Duplicates galore" }, { 5000, 25, "Mountain of cards" }, { 10000, 50, "Dragon on its hoard" },
	}, function(sn)
		return sn.copies
	end, function(a)
		return string.format(L["Copies in all: %d"], a.goal)
	end, "Copies")
end)

-- The secret feats: "???" and a hint until earned. Their counters are in the stats (Collection.lua:
-- the boosters; Rewards.lua: Hogger).
AC.HOGGER = "c448"
Last(function()
	local function Secret(id, pts, name, icon, desc, hint, value)
		return Def({ id = id, cat = "feats", pts = pts, name = name, icon = icon, goal = 1, secret = true, hint = hint,
			value = value or function(_, db) return db.stats[id] and 1 or 0 end,
			desc = function() return L[desc] end })
	end
	Secret("rainbow", 25, "Rainbow", { "Interface\\Icons\\INV_Misc_Gem_Variety_01" },
		"Every rarity from common to legendary in the same booster.", "A booster of every colour.")
	Secret("dleg", 25, "Double legend", { "Gem5" }, "Two legendary cards or better in the same booster.", "Lightning sometimes strikes twice.")
	-- (Hogger: his name in the language of the cards)
	local hog = Secret("hogger", 10, "", { "Interface\\Icons\\INV_Misc_Head_Gnoll_01" }, "", "A famous gnoll keeps something on him.")
	local function Hogger()
		local card = ns.Cards and ns.Cards[AC.HOGGER]
		return card and C:Name(card) or "Hogger"
	end
	hog.nameOf = function()
		return string.format(L["%s, on %s"], Hogger(), Hogger())
	end
	hog.desc = function()
		return string.format(L["The card of %s, found on %s."], Hogger(), Hogger())
	end
	Secret("night", 10, "Insomniac", { "Interface\\Icons\\Spell_Nature_Sleep" },
		"A booster opened between 3 and 5 in the morning.", "Some open their boosters while everyone sleeps.")
	Secret("marathon", 10, "Marathon", { "Interface\\Icons\\Ability_Rogue_Sprint" }, "25 boosters opened in the same day.", "A very, very long day of openings.")
	Secret("unlucky", 10, "Out of luck", { "Interface\\Icons\\Spell_Shadow_Curse" },
		"30 boosters in a row without an epic card.", "Luck always turns... in the end.")
	Secret("dupe", 10, "One too many", ICON.card, "20 copies of the same card.", "Her again?", function(sn)
		return sn.maxCopies >= 20 and 1 or 0
	end)
	Secret("firstmyth", 25, "Myth at first sight", { "Gem6" },
		"A mythic card in your first booster of a dungeon or a raid.", "Some newcomers start at the very top.")
end)

-- (1.6.0) The last talent of each specialization: the first time it works, its achievement, and its title
-- of prestige. After all the achievements of before. (1.14.0: the trees of before are gone with the release of WoW
-- Forever: their achievements stay where they are, for the bits of the others, seen only by a collection that has
-- them; the summits of the new trees have theirs, AC.TALENTS, at the end of the list.)
AC.OLD_TALENTS = { "tPrey", "tMaster", "tOracle", "tWild", "tTycoon", "tFate" }
Last(function()
	local function Talent(id, name, icon, desc)
		return Def({ id = id, cat = "feats", pts = 25, name = name, icon = icon, goal = 1, onlyEarned = true,
			value = function(_, db) return db.stats[id] and 1 or 0 end,
			desc = function() return L[desc] end })
	end
	Talent("tPrey", "Master of the Hunt", { "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
		"A card from the Prey of the Day, the last talent of the Tracker.")
	Talent("tMaster", "Master of Contracts", { "Interface\\Icons\\INV_Crown_01" },
		"A contract gone up two rarities with the Masterstroke, the last talent of the Merchant.")
	Talent("tOracle", "Oracle", { "Interface\\Icons\\Spell_Arcane_StarFire" },
		"A card from the Favor of the Stars, the last talent of the Augur.")
end)

-------------------------------------------------------------------------------
-- (1.8.0) After the albums of 1.7.0, in this order: the inns (Inns.lua); then the albums of 1.8.0 and
-- later. (The modules of 1.8.0 that bring achievements of their own add them here, in their order.)
-------------------------------------------------------------------------------
local after180 = {}
local function After180(fn)
	after180[CuratorOctoFull.Length(after180) + 1] = fn
end
AC.After180 = After180

local function InnsOf(db)
	return type(db.inns) == "table" and db.inns or {}
end

-- The visas: all of them, those of the inns Curator knows.
local function Visas(db)
	local n, known = 0, 0
	local inn = ns.INNKEEPERS or {}
	for npc in pairs(type(InnsOf(db).visas) == "table" and InnsOf(db).visas or {}) do
		n = n + 1
		if inn[npc] then
			known = known + 1
		end
	end
	return n, known
end

After180(function()
	local INN = { "Interface\\Icons\\INV_Drink_04" }
	local VISA = { "Interface\\Icons\\INV_Misc_Map_01" }
	local SIGN = { "Interface\\Icons\\INV_Feather_04" }
	Tiers("adventure", "inncard", INN, {
		{ 1, 10, "First Round" }, { 5, 10, "Loyal Customer" }, { 20, 25, "Tavern Legend" },
	}, function(_, db)
		return tonumber(InnsOf(db).cards) or 0
	end, function(a)
		return string.format(L["Loyalty cards full: %d"], a.goal)
	end, "Loyalty cards")
	Tiers("adventure", "visa", VISA, {
		{ 10, 10, "Traveler" }, { 25, 25, "Seasoned Traveler" },
	}, function(_, db)
		return (Visas(db))
	end, function(a)
		return string.format(L["Inns visited: %d"], a.goal)
	end, "Travel passport")
	local g = AC.GROUPS.visa
	local all = Def({ id = "visaall", cat = "adventure", pts = 50, name = "Tour of Azeroth", icon = VISA,
		value = function(_, db) return CuratorOctoFull.Select(2, Visas(db)) end,
		goalOf = function() return ns.Inns and ns.Inns:AllCount() or 47 end,
		desc = function() return L["Every inn of Azeroth."] end, group = g, tier = CuratorOctoFull.Length(g.list) + 1 })
	g.list[CuratorOctoFull.Length(g.list) + 1] = all
	Def({ id = "innpillar", cat = "adventure", pts = 10, name = "Pillar of the Bar", icon = INN, goal = 10,
		value = function(_, db)
			local best = 0
			for _, n in pairs(type(InnsOf(db).loyal) == "table" and InnsOf(db).loyal or {}) do
				best = math.max(best, tonumber(n) or 0)
			end
			return best
		end,
		desc = function() return L["10 stamps at the same innkeeper."] end })
	Tiers("adventure", "signed", SIGN, {
		{ 1, 25, "Friend of the House" }, { 5, 50, "Autograph Hunter" },
	}, function(_, db)
		local n = 0
		for _ in pairs(type(InnsOf(db).signed) == "table" and InnsOf(db).signed or {}) do
			n = n + 1
		end
		return n
	end, function(a)
		return string.format(L["Signed cards: %d"], a.goal)
	end, "Signed cards")
end)

-- The life of the inns (Tavern.lua): the rumors, an evening at the inn, the bet, the toasts.
After180(function()
	local GOSSIP = { "Interface\\Icons\\INV_Letter_15" }
	local NIGHT = { "Interface\\Icons\\INV_Drink_05" }
	local CHEERS = { "Interface\\Icons\\INV_Drink_04" }
	Def({ id = "rumors", cat = "adventure", pts = 10, name = "Tavern Gossip", icon = GOSSIP, goal = 10,
		value = function(_, db) return tonumber(InnsOf(db).heard) or 0 end,
		desc = function() return L["10 rumors heard from the innkeepers."] end })
	Def({ id = "party", cat = "adventure", pts = 10, name = "Friday Night", icon = NIGHT, goal = 1,
		value = function(_, db) return ((tonumber(db.stats.parties) or 0) > 0) and 1 or 0 end,
		desc = function() return L["Your stamp of the day on an evening at the inn (Friday evening): a double stamp."] end })
	Feat("tavernjack", 10, "Jackpot at the Tavern", { "Interface\\Icons\\INV_Misc_Coin_02" }, "The card of the rarity above, at the innkeeper's bet.")
	Tiers("social", "cheers", CHEERS, {
		{ 1, 10, "Cheers!" }, { 10, 25, "Round for Everyone" },
	}, function(_, db)
		return tonumber(db.stats.cheers) or 0
	end, function(a)
		return string.format(L["Toasts with other collectors: %d"], a.goal)
	end, "Toasts")
end)

-- The PvP (Pvp.lua): the combatants of the album, a general or a warlord, the bounties, the wanted, the pay.
-- (1.9.0: in the category of the PvP, the duels with them)
After180(function()
	local SWORD = { "Interface\\Icons\\INV_Sword_27" }
	local function PvpOf(db)
		return type(db.pvp) == "table" and db.pvp or {}
	end
	Tiers("pvp", "pvpc", SWORD, {
		{ 1, 10, "First Blood" }, { 25, 10, "Brawler" }, { 100, 25, "Veteran of the Front" }, { 250, 50, "Warmonger" },
	}, function(_, db)
		return Count(type(PvpOf(db).cards) == "table" and PvpOf(db).cards or {})
	end, function(a)
		return string.format(L["Enemies in your PvP album: %d"], a.goal)
	end, "Combatants")
	Def({ id = "pvpleg", cat = "pvp", pts = 25, name = "Head of the Army", icon = { "Interface\\Icons\\INV_Misc_Head_Orc_01" }, goal = 1,
		value = function(_, db)
			for _, c in pairs(type(PvpOf(db).cards) == "table" and PvpOf(db).cards or {}) do
				if type(c) == "table" and (tonumber(c.rk) or 0) >= 12 then
					return 1
				end
			end
			return 0
		end,
		desc = function() return L["The card of an enemy of rank 12 or higher: a general, a marshal."] end })
	Tiers("pvp", "bounty", { "Interface\\Icons\\INV_Misc_Note_02" }, {
		{ 1, 10, "Bounty Hunter" }, { 25, 25, "Professional Hunter" },
	}, function(_, db)
		return tonumber(db.stats.bounties) or 0
	end, function(a)
		return string.format(L["Bounties of the war board claimed: %d"], a.goal)
	end, "Bounties")
	Def({ id = "wanted", cat = "pvp", pts = 25, name = "Dead or Alive", icon = { "Interface\\Icons\\INV_Misc_Head_Human_01" }, goal = 1,
		value = function(_, db) return ((tonumber(db.stats.wanted) or 0) > 0) and 1 or 0 end,
		desc = function() return L["The enemy of a wanted poster brought down, his bounty claimed."] end })
	Def({ id = "pay", cat = "pvp", pts = 10, name = "On the Payroll", icon = { "Interface\\Icons\\INV_Misc_Coin_01" }, goal = 4,
		value = function(_, db) return tonumber(PvpOf(db).pays) or 0 end,
		desc = function() return L["Your pay of the week collected 4 times."] end })
	-- (the flex of PvP) the revenges, the nemesis, the exploits of the battlegrounds, a rival
	Tiers("pvp", "revenge", { "Interface\\Icons\\Ability_Warrior_Revenge" }, {
		{ 1, 10, "Sweet Revenge" }, { 10, 25, "Served Cold" },
	}, function(_, db)
		return tonumber(db.stats.revenge) or 0
	end, function(a)
		return string.format(L["Revenges: %d. Bring down whoever just brought you down, within 15 minutes."], a.goal)
	end, "Revenges")
	Def({ id = "nemesis", cat = "pvp", pts = 25, name = "Nemesis No More", icon = { "Interface\\Icons\\Spell_Shadow_DeathCoil" }, goal = 1,
		value = function(_, db) return ((tonumber(db.stats.nemesis) or 0) > 0) and 1 or 0 end,
		desc = function() return L["Your nemesis brought down: the enemy who brought you down the most."] end })
	Tiers("pvp", "exploit", { "Interface\\Icons\\INV_Misc_Rune_07" }, {
		{ 1, 10, "First Exploit" }, { 9, 50, "Battle-Hardened" },
	}, function(_, db)
		local n = 0
		for id in pairs(type(PvpOf(db).feats) == "table" and PvpOf(db).feats or {}) do
			if ns.Pvp and ns.Pvp.FEAT_BY[id] then
				n = n + 1
			end
		end
		return n
	end, function(a)
		return string.format(L["Exploits of the battlegrounds: %d"], a.goal)
	end, "Exploits")
	Def({ id = "rival", cat = "pvp", pts = 25, name = "Arch-Rival", icon = { "Interface\\Icons\\Ability_DualWield" }, goal = 1,
		value = function(_, db)
			for _, c in pairs(type(PvpOf(db).cards) == "table" and PvpOf(db).cards or {}) do
				if type(c) == "table" and (tonumber(c.k) or 0) >= 25 then
					return 1
				end
			end
			return 0
		end,
		desc = function() return L["The same combatant defeated 25 times: his card titanforged."] end })
	-- the albums of the battlegrounds (Pvp.lua): each one complete, then all three
	local function BgDone(db, bg)
		local done = type(PvpOf(db).bgDone) == "table" and PvpOf(db).bgDone or {}
		return (done[bg .. ":Horde"] or done[bg .. ":Alliance"]) and true or false
	end
	Def({ id = "bgwsg", cat = "pvp", pts = 25, name = "The Whole Gulch", icon = { "Interface\\Icons\\INV_Misc_Rune_07" }, goal = 1,
		value = function(_, db) return BgDone(db, "wsg") and 1 or 0 end,
		desc = function() return L["The album of Warsong Gulch complete: a combatant of each race and class of the enemy, defeated there."] end })
	Def({ id = "bgab", cat = "pvp", pts = 25, name = "The Whole Basin", icon = { "Interface\\Icons\\INV_Jewelry_Amulet_07" }, goal = 1,
		value = function(_, db) return BgDone(db, "ab") and 1 or 0 end,
		desc = function() return L["The album of Arathi Basin complete: a combatant of each race and class of the enemy, defeated there."] end })
	Def({ id = "bgav", cat = "pvp", pts = 25, name = "The Whole Valley", icon = { "Interface\\Icons\\INV_Jewelry_Necklace_21" }, goal = 1,
		value = function(_, db) return BgDone(db, "av") and 1 or 0 end,
		desc = function() return L["The album of Alterac Valley complete: a combatant of each race and class of the enemy, defeated there."] end })
	Def({ id = "bgall", cat = "pvp", pts = 50, name = "Every Battlefield", icon = { "Interface\\Icons\\INV_Misc_Map_01" }, goal = 3,
		value = function(_, db)
			return (BgDone(db, "wsg") and 1 or 0) + (BgDone(db, "ab") and 1 or 0) + (BgDone(db, "av") and 1 or 0)
		end,
		desc = function() return L["The albums of the three battlegrounds complete."] end })
	-- the duels with a stake (Duel.lua): won
	Tiers("pvp", "duel", { "Interface\\Icons\\Ability_Parry" }, {
		{ 1, 10, "High Stakes" }, { 10, 25, "Professional Duelist" },
	}, function(_, db)
		return tonumber(db.stats.duelsWon) or 0
	end, function(a)
		return string.format(L["Duels with a stake won: %d"], a.goal)
	end, "Duels with a stake")
	-- the front of the collectors (Front.lua): the heads with a price claimed, the booster of the front won
	Tiers("pvp", "head", { "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" }, {
		{ 1, 10, "Head Hunter" }, { 10, 25, "Price on Their Heads" },
	}, function(_, db)
		return tonumber(db.stats.heads) or 0
	end, function(a)
		return string.format(L["Heads with a price brought down and claimed: %d"], a.goal)
	end, "Heads with a price")
	Def({ id = "front", cat = "pvp", pts = 10, name = "On the Winning Side", icon = { "Interface\\Icons\\INV_BannerPVP_02" }, goal = 1,
		value = function(_, db) return ((tonumber(db.stats.frontWins) or 0) > 0) and 1 or 0 end,
		desc = function() return L["The booster of the front claimed: your side won it the week before."] end })
end)

-------------------------------------------------------------------------------
-- (1.9.0) After the albums of 1.8.0, in this order: the quests of the collector and its level, the
-- PvP, then a few more (the boosters of the dungeons, the albums complete, the toasts, two secret feats
-- of PvP); then the albums of 1.9.0 and later. Their counters: Quests.lua (the quests done, the boards
-- done whole, the battlegrounds), Pvp.lua (the kills by class, race, rank and level, where they were
-- made, the deaths, the exploits).
-------------------------------------------------------------------------------
local after190 = {}
local function After190(fn)
	after190[CuratorOctoFull.Length(after190) + 1] = fn
end
AC.After190 = After190

-- A series of tiers whose ids are "<prefix>:<goal>" (the ids of 1.9.0 on).
local function Steps(cat, prefix, icon, tiers, value, desc, title)
	local g = Group(prefix, title, icon)
	for _, t in ipairs(tiers) do
		local i = CuratorOctoFull.Length(g.list) + 1
		-- (t[5]: its id as it was, when its goal changed: the achievements earned stay theirs)
		local a = Def({ id = t[5] or (prefix .. ":" .. t[1]), cat = cat, goal = t[1], pts = t[2], name = t[3], icon = t[4] or icon, value = value,
			desc = desc, group = g, tier = i })
		g.list[i] = a
	end
	return g
end

-- More tiers for an achievement of before that was alone (its id: prefix): a group comes, it its first
-- tier, the new ones after it (their medals in one line).
local function Join(prefix, a)
	local g = AC.GROUPS[prefix]
	if not g then
		local first = AC.byId[prefix]
		g = Group(prefix, a.groupTitle, (first and first.icon) or a.icon)
		if first and not first.group then
			first.group, first.tier = g, 1
			g.list[1] = first
		end
	end
	a.group, a.tier = g, CuratorOctoFull.Length(g.list) + 1
	g.list[a.tier] = a
	return a
end

local function Stat(db, key)
	return tonumber(type(db.stats) == "table" and db.stats[key]) or 0
end

-- The emblem of the rank of a level of collector, as the icon of an achievement.
function AC.RankEmblem(level)
	local LV = ns.Level
	local r = (LV and LV.RankOf) and LV.RankOf(level) or (math.floor(level / 5) + 1)
	if LV and LV.IconCoords then
		return { "RankIcons", { LV.IconCoords(r) } }
	end
	local col, row = CuratorOctoFull.Mod((r - 1) , 4), math.floor((r - 1) / 4)
	return { "RankIcons", { col * 0.25, col * 0.25 + 0.25, row / 8, (row + 1) / 8 } }
end

local function Text(key)
	return function(a)
		return string.format(L[key], a.goal)
	end
end

local function Fixed(key)
	return function()
		return L[key]
	end
end

-- The quests of the collector, its level.
After190(function()
	local function St(key)
		return function(_, db)
			return Stat(db, key)
		end
	end
	Steps("quests", "qd", { "Interface\\Icons\\INV_Misc_Note_01" }, {
		{ 1, 5, "Odd Job" }, { 10, 5, "Helping Hand" }, { 50, 10, "Reliable" }, { 100, 10, "Hard Worker" },
		{ 250, 25, "Tireless" }, { 500, 25, "Taskmaster" }, { 1000, 50, "Legend of the Notice Board" }, { 2500, 100, "Nothing Left Undone" },
	}, St("qDone"), Text("Quests of the collector done: %d"), "Quests done")
	Steps("quests", "qday", { "Interface\\Icons\\INV_Misc_PocketWatch_01" }, {
		{ 30, 10, "Daily Routine" }, { 150, 25, "Creature of Habit" }, { 500, 50, "Every Single Day" },
	}, St("q_day"), Text("Daily quests done: %d"), "Daily quests")
	Steps("quests", "qweek", { "Interface\\Icons\\INV_Scroll_05" }, {
		{ 10, 10, "Week In, Week Out" }, { 50, 25, "Weekly Ritual" }, { 150, 50, "Calendar Keeper" },
	}, St("q_week"), Text("Weekly quests done: %d"), "Weekly quests")
	Steps("quests", "qmonth", { "Interface\\Icons\\INV_Misc_Book_07" }, {
		{ 3, 10, "A Month's Work" }, { 12, 25, "A Year of Toil" }, { 36, 50, "The Long Haul" },
	}, St("q_month"), Text("Monthly quests done: %d"), "Monthly quests")
	Steps("quests", "qdun", { "Interface\\Icons\\INV_Misc_Key_10" }, {
		{ 10, 10, "Into the Depths" }, { 50, 25, "Dungeon Contractor" }, { 150, 50, "Keeper of the Keys" },
	}, St("q_dungeon"), Text("Dungeon quests done: %d"), "Dungeon quests")
	Steps("quests", "qraid", { "Interface\\Icons\\INV_Misc_Head_Dragon_Black" }, {
		{ 5, 10, "Raid Orders" }, { 25, 25, "Raid Quartermaster" }, { 75, 50, "Strategist" },
	}, St("q_raid"), Text("Raid quests done: %d"), "Raid quests")
	Steps("quests", "qallday", { "Interface\\Icons\\INV_Scroll_04" }, {
		{ 1, 10, "Clean Slate" }, { 10, 25, "Spotless" }, { 50, 50, "Immaculate" },
	}, St("qAll_daily"), Text("Days when every quest of the day was done: %d"), "Every quest of the day")
	Def({ id = "qallweek", cat = "quests", pts = 25, name = "Week Well Spent", icon = { "Interface\\Icons\\INV_Scroll_06" }, goal = 1,
		value = function(_, db) return Stat(db, "qAll_weekly") > 0 and 1 or 0 end,
		desc = Fixed("Every quest of a week done before its end.") })
	Def({ id = "qallmonth", cat = "quests", pts = 25, name = "Month of Glory", icon = { "Interface\\Icons\\INV_Crown_02" }, goal = 1,
		value = function(_, db) return Stat(db, "qAll_monthly") > 0 and 1 or 0 end,
		desc = Fixed("Every quest of a month done before its end.") })
	-- the level of the collector: each tier the emblem of the rank of its level
	local Emblem = AC.RankEmblem
	local tiers = {}
	for i, t in ipairs({ { 10, 10, "Bronze Collector" }, { 20, 10, "Iron Collector" }, { 30, 25, "Mithril Collector" },
		{ 40, 25, "Thorium Collector" }, { 50, 50, "Arcanite Collector" }, { 60, 100, "Legendary Collector" } }) do
		tiers[i] = { t[1], t[2], t[3], Emblem(t[1]) }
	end
	Steps("quests", "lvl", Emblem(60), tiers, function()
		return (ns.Level and ns.Level:Level()) or 1
	end, Text("Collector level %d reached."), "Collector level")
end)

-- The PvP: the honorable kills, the trophies, the battlegrounds, the enemies (their classes, their races,
-- their ranks, their level), the deaths, the exploits; more tiers for those of 1.8.0; the quests of PvP.
After190(function()
	local function St(key)
		return function(_, db)
			return Stat(db, key)
		end
	end
	local function PvpOf(db)
		return type(db.pvp) == "table" and db.pvp or {}
	end
	Steps("pvp", "hk", { "Interface\\Icons\\Ability_Warrior_OffensiveStance" }, {
		{ 1, 5, "Honorable Debut" }, { 100, 10, "Skirmisher" }, { 500, 10, "Soldier of the Line" }, { 1000, 25, "Battle-Scarred" },
		{ 2500, 25, "Reaper" }, { 5000, 50, "Scourge of the Enemy" }, { 10000, 100, "Ten Thousand Fallen" },
	}, function(_, db)
		return tonumber(PvpOf(db).hk) or 0
	end, Text("Honorable kills: %d"), "Honorable kills")
	Steps("pvp", "trophy", { "Interface\\Icons\\INV_Misc_Bone_OrcSkull_01" }, {
		{ 10, 5, "Proof of Valor" }, { 100, 10, "Trophy Wall" }, { 500, 25, "Hall of Trophies" }, { 2000, 50, "Museum of War" },
	}, St("certified"), Text("Trophies certified by a battlemaster: %d"), "Trophies certified")
	Steps("pvp", "bgp", { "Interface\\Icons\\INV_BannerPVP_01" }, {
		{ 1, 5, "Called to Battle" }, { 25, 10, "Front-Line Regular" }, { 100, 25, "Battle-Tested" }, { 300, 50, "Lifer" },
	}, St("bgPlayed"), Text("Battlegrounds finished: %d"), "Battlegrounds")
	Steps("pvp", "bgw", { "Interface\\Icons\\INV_BannerPVP_02" }, {
		{ 1, 10, "Victory!" }, { 25, 10, "Seasoned Victor" }, { 100, 25, "Champion of the Field" }, { 250, 50, "Conqueror of Battlefields" },
	}, St("bgWins"), Text("Battlegrounds won: %d"), "Victories")
	Steps("pvp", "bgwwsg", { "Interface\\Icons\\INV_Misc_Rune_07" }, {
		{ 10, 10, "Flag Runner" }, { 50, 25, "Hero of the Gulch" },
	}, St("bgWin_wsg"), Text("Victories at Warsong Gulch: %d"), "Warsong Gulch")
	Steps("pvp", "bgwab", { "Interface\\Icons\\INV_Jewelry_Amulet_07" }, {
		{ 10, 10, "Five Bases" }, { 50, 25, "Lord of the Basin" },
	}, St("bgWin_ab"), Text("Victories in Arathi Basin: %d"), "Arathi Basin")
	Steps("pvp", "bgwav", { "Interface\\Icons\\INV_Jewelry_Necklace_21" }, {
		{ 10, 10, "Snowbound" }, { 50, 25, "Hero of Alterac" },
	}, St("bgWin_av"), Text("Victories in Alterac Valley: %d"), "Alterac Valley")
	Steps("pvp", "bghk", { "Interface\\Icons\\Ability_Warrior_InnerRage" }, {
		{ 100, 10, "Battlefield Brawler" }, { 1000, 25, "Battlefield Butcher" },
	}, St("bgHk"), Text("Honorable kills in battlegrounds: %d"), "Battlefield kills")
	Steps("pvp", "whk", { "Interface\\Icons\\Ability_Rogue_Ambush" }, {
		{ 25, 10, "Ambusher" }, { 250, 25, "Roaming Menace" }, { 1000, 50, "Terror of the Roads" },
	}, St("worldHk"), Text("Honorable kills outside battlegrounds: %d"), "World PvP")
	-- every class, every race of the enemy: so many times each (the fewest of them)
	local function Fewest(db, key, ids)
		local t = type(db.stats) == "table" and type(db.stats[key]) == "table" and db.stats[key] or {}
		local low
		for _, id in ipairs(ids) do
			local n = tonumber(t[id]) or 0
			low = (low == nil or n < low) and n or low
		end
		return low or 0
	end
	local function EnemyClasses()
		local P, seen, out = ns.Pvp, {}, {}
		for _, f in ipairs((ns.Quests and ns.Quests:EnemyFactions()) or { "Horde" }) do
			for _, c in ipairs((P and P.CLASSES and P.CLASSES[f]) or {}) do
				if not seen[c] then
					seen[c] = true
					out[CuratorOctoFull.Length(out) + 1] = c
				end
			end
		end
		return out
	end
	local function EnemyRaces()
		local P, seen, out = ns.Pvp, {}, {}
		for _, f in ipairs((ns.Quests and ns.Quests:EnemyFactions()) or { "Horde" }) do
			for _, r in ipairs((P and P.RACES and P.RACES[f]) or {}) do
				if not seen[r] then
					seen[r] = true
					out[CuratorOctoFull.Length(out) + 1] = r
				end
			end
		end
		return out
	end
	Steps("pvp", "cls", { "Interface\\Icons\\INV_Misc_Head_Human_02" }, {
		{ 1, 10, "Know Your Enemy" }, { 10, 25, "Well Rounded" }, { 50, 50, "Bane of Every Class" },
	}, function(_, db)
		return Fewest(db, "byCls", EnemyClasses())
	end, Text("Every class of the enemy defeated, %d times each"), "Classes")
	Steps("pvp", "race", { "Interface\\Icons\\INV_Misc_Head_Troll_01" }, {
		{ 1, 10, "Diverse Foes" }, { 10, 25, "No One Is Spared" }, { 50, 50, "Bane of Every Race" },
	}, function(_, db)
		return Fewest(db, "byRace", EnemyRaces())
	end, Text("Every race of the enemy defeated, %d times each"), "Races")
	Steps("pvp", "rk6", { "Interface\\Icons\\INV_Shield_06" }, {
		{ 10, 10, "Officer Down" }, { 100, 25, "Breaking the Ranks" },
	}, St("rk6"), Text("Enemies of rank 6 or higher defeated: %d"), "Officers")
	Steps("pvp", "rk10", { "Interface\\Icons\\INV_Helmet_01" }, {
		{ 10, 25, "Commander Slayer" }, { 50, 50, "Decapitation Strike" },
	}, St("rk10"), Text("Enemies of rank 10 or higher defeated: %d"), "Commanders")
	Def({ id = "rk14", cat = "pvp", pts = 25, name = "Topple the Highest", icon = { "Interface\\Icons\\INV_Crown_01" }, goal = 1,
		value = function(_, db) return Stat(db, "rk14") > 0 and 1 or 0 end,
		desc = Fixed("An enemy of rank 14 defeated: a grand marshal or a high warlord.") })
	Steps("pvp", "max", { "Interface\\Icons\\INV_Misc_Head_Dragon_Red" }, {
		{ 50, 10, "Among Equals" }, { 500, 25, "Top of the Food Chain" },
	}, St("max60"), Text("Enemies of level 60 defeated: %d"), "Level 60 enemies")
	Steps("pvp", "death", { "Interface\\Icons\\Spell_Holy_Resurrection" }, {
		{ 1, 5, "Baptism of Fire" }, { 100, 10, "Cannon Fodder" }, { 500, 25, "Spirit Healer's Regular" },
	}, St("pvpDeaths"), Text("Brought down by enemy players: %d"), "Fallen")
	More("revenge", { { 50, 50, "Vendetta" } })
	Join("nemesis", Def({ id = "nemesis10", cat = "pvp", pts = 25, name = "Obsession", icon = { "Interface\\Icons\\Spell_Shadow_DeathCoil" }, goal = 10,
		value = St("nemesis"), desc = Fixed("Your nemesis brought down 10 times."), groupTitle = "Nemesis" }))
	Steps("pvp", "expl", { "Interface\\Icons\\INV_Misc_Rune_07" }, {
		{ 25, 10, "Daredevil" }, { 100, 25, "Hero of the Battlegrounds" }, { 250, 50, "Living Legend of War" },
	}, St("exploits"), Text("Exploits achieved in battlegrounds: %d"), "Exploits achieved")
	More("pvpc", { { 500, 50, "Rogues' Gallery" }, { 1000, 100, "The Whole Army" } })
	More("bounty", { { 100, 50, "Bounty King" } })
	local pays = function(_, db)
		return tonumber(PvpOf(db).pays) or 0
	end
	Join("pay", Def({ id = "pay12", cat = "pvp", pts = 25, name = "Career Soldier", icon = { "Interface\\Icons\\INV_Misc_Coin_01" }, goal = 12,
		value = pays, desc = Fixed("Your pay of the week collected 12 times."), groupTitle = "Pay of the week" }))
	Join("pay", Def({ id = "pay52", cat = "pvp", pts = 50, name = "Old Soldier", icon = { "Interface\\Icons\\INV_Misc_Coin_01" }, goal = 52,
		value = pays, desc = Fixed("Your pay of the week collected 52 times.") }))
	Join("wanted", Def({ id = "wanted10", cat = "pvp", pts = 25, name = "Most Wanted", icon = { "Interface\\Icons\\INV_Misc_Head_Human_01" }, goal = 10,
		value = St("wanted"), desc = Fixed("10 enemies of the wanted poster brought down, their bounty claimed."), groupTitle = "Wanted" }))
	More("head", { { 50, 50, "Headsman" } })
	Join("front", Def({ id = "front10", cat = "pvp", pts = 25, name = "Holding the Line", icon = { "Interface\\Icons\\INV_BannerPVP_02" }, goal = 10,
		value = St("frontWins"), desc = Fixed("The booster of the front claimed 10 times."), groupTitle = "The front" }))
	More("duel", { { 50, 50, "Duel Master" } })
	Steps("pvp", "qpvp", { "Interface\\Icons\\Ability_Warrior_BattleShout" }, {
		{ 10, 10, "Orders from the Front" }, { 50, 25, "Soldier of Fortune" }, { 250, 50, "War Hero" },
	}, St("q_pvp"), Text("PvP quests done: %d"), "PvP quests")
	Def({ id = "qallpd", cat = "pvp", pts = 10, name = "Day of Battle", icon = { "Interface\\Icons\\Ability_Warrior_Charge" }, goal = 1,
		value = function(_, db) return Stat(db, "qAll_pvpDaily") > 0 and 1 or 0 end,
		desc = Fixed("Every PvP quest of the day done in its day.") })
	Def({ id = "qallpw", cat = "pvp", pts = 25, name = "Week of War", icon = { "Interface\\Icons\\INV_Misc_Horn_01" }, goal = 1,
		value = function(_, db) return Stat(db, "qAll_pvpWeekly") > 0 and 1 or 0 end,
		desc = Fixed("Every PvP quest of a week done before its end.") })
	Def({ id = "qallpm", cat = "pvp", pts = 25, name = "Month of War", icon = { "Interface\\Icons\\INV_Misc_Horn_02" }, goal = 1,
		value = function(_, db) return Stat(db, "qAll_pvpMonthly") > 0 and 1 or 0 end,
		desc = Fixed("Every PvP quest of a month done before its end.") })
end)

-- A few more: the boosters of the dungeons and the raids, the albums complete, the toasts, two secret
-- feats of PvP.
After190(function()
	Steps("boosters", "lair", { "PackDungeonChoice" }, {
		{ 10, 10, "Treasures of the Deep" }, { 100, 25, "Vault Raider" }, { 500, 50, "Hoard of the Depths" },
	}, function(_, db)
		return Stat(db, "lairs")
	end, Text("Boosters of dungeons and raids opened: %d"), "Boosters of dungeons and raids")
	Steps("albums", "alb", ICON.card, {
		{ 5, 25, "Bookworm" }, { 15, 50, "Bibliophile" }, { 40, 100, "Grand Librarian" },
	}, function(sn)
		return sn.complete
	end, Text("Complete albums: %d"), "Complete albums")
	More("cheers", { { 50, 50, "Life of the Party" } })
	local function Secret(id, pts, name, icon, desc, hint)
		return Def({ id = id, cat = "feats", pts = pts, name = name, icon = icon, goal = 1, secret = true, hint = hint,
			value = function(_, db) return (type(db.stats) == "table" and db.stats[id]) and 1 or 0 end,
			desc = Fixed(desc) })
	end
	Secret("underdog", 25, "David and Goliath", { "Interface\\Icons\\Ability_Hunter_SniperShot" },
		"An enemy player 10 levels or more above you, defeated.", "Size is not everything.")
	Secret("mirror", 10, "Mirror Match", { "Interface\\Icons\\INV_Misc_Gem_Pearl_04" },
		"An enemy player of your own class, defeated.", "Fighting yourself is never easy.")
end)

-------------------------------------------------------------------------------
-- (1.10.0) The golden quests (Golden.lua), after every achievement of 1.9.0 and the albums of 1.9.0: the
-- quests turned in, a title of prestige for each side, the three leaders of a side, every tranche, and two
-- secret feats. Their counters: Golden.lua (golden, goldenH, goldenA, goldenBy, goldenAt, goldenMyth,
-- goldenLast).
-------------------------------------------------------------------------------
local after1100 = {}
local function After1100(fn)
	after1100[CuratorOctoFull.Length(after1100) + 1] = fn
end
AC.After1100 = After1100

After1100(function()
	local function St(key)
		return function(_, db)
			return Stat(db, key)
		end
	end
	Steps("quests", "gq", { "Interface\\Icons\\INV_Misc_Coin_01" }, {
		{ 1, 10, "Touched by Gold" }, { 5, 25, "Golden Hands" }, { 10, 25, "Heart of Gold" }, { 25, 50, "Golden Age" },
	}, St("golden"), Text("Golden quests turned in: %d"), "Golden quests")
	Def({ id = "gqhorde", cat = "quests", pts = 100, name = "Champion of the Horde", icon = { "Interface\\Icons\\INV_BannerPVP_01" },
		goal = 50, value = St("goldenH"), desc = Fixed("50 golden quests turned in to the leaders of the Horde.") })
	Def({ id = "gqalliance", cat = "quests", pts = 100, name = "Champion of the Alliance", icon = { "Interface\\Icons\\INV_BannerPVP_02" },
		goal = 50, value = St("goldenA"), desc = Fixed("50 golden quests turned in to the leaders of the Alliance.") })
	Def({ id = "gqlords", cat = "quests", pts = 25, name = "In the Service of the Leaders", icon = { "Interface\\Icons\\INV_Crown_02" },
		goal = 3, value = function(_, db)
			local by = type(db.stats) == "table" and type(db.stats.goldenBy) == "table" and db.stats.goldenBy or {}
			local n = { Horde = 0, Alliance = 0 }
			for _, l in ipairs(ns.GOLDEN_LEADERS or {}) do
				if by[l.key] then
					n[l.side] = n[l.side] + 1
				end
			end
			return math.max(n.Horde, n.Alliance)
		end, desc = Fixed("A golden quest turned in to each of the three leaders of a side.") })
	Def({ id = "gqall", cat = "quests", pts = 50, name = "From End to End", icon = { "Interface\\Icons\\INV_Misc_Map_01" },
		goal = 6, value = function(_, db)
			local at = type(db.stats) == "table" and type(db.stats.goldenAt) == "table" and db.stats.goldenAt or {}
			local n = 0
			for _, b in ipairs({ "10", "20", "30", "40", "50", "60" }) do
				if at[b] then
					n = n + 1
				end
			end
			return n
		end, desc = Fixed("A golden quest turned in in each tranche of levels, from 10 to 60.") })
	local function Secret(id, pts, name, icon, desc, hint)
		return Def({ id = id, cat = "feats", pts = pts, name = name, icon = icon, goal = 1, secret = true, hint = hint,
			value = function(_, db) return (type(db.stats) == "table" and db.stats[id]) and 1 or 0 end,
			desc = Fixed(desc) })
	end
	Secret("goldenMyth", 25, "Gold and Myth", { "Interface\\Icons\\INV_Misc_Gem_Pearl_04" },
		"A mythic card in a golden booster.", "Gold sometimes hides a legend.")
	Secret("goldenLast", 10, "By a Thread", { "Interface\\Icons\\INV_Misc_PocketWatch_01" },
		"A golden quest turned in less than an hour before the reset.", "Just in time.")
end)

-------------------------------------------------------------------------------
-- (1.11.0) The rubies (Rubies.lua), after every achievement of 1.10.0 and the albums of 1.10.0: the rubies
-- earned and spent, the quests changed, the rumors and the boosters bought, then the expertise of the
-- cards (Expertise.lua). Their counters: ns.Stats (rubyEarned, rubySpent, qRerolls, rumorsBought, rubyPacks,
-- appraised, grade10).
-------------------------------------------------------------------------------
local after1110 = {}
local function After1110(fn)
	after1110[CuratorOctoFull.Length(after1110) + 1] = fn
end
AC.After1110 = After1110

-------------------------------------------------------------------------------
-- (1.12.0) Hallow's End: its quests, its treats, its boosters, its corrupted cards. After every achievement before
-- them, the album of Hallow's End included (the bits of the older ones stay where they were). Achievements of the
-- event (event): once it is over, only for those who earned them.
-------------------------------------------------------------------------------
local after1120 = {}
local function After1120(fn)
	after1120[CuratorOctoFull.Length(after1120) + 1] = fn
end
AC.After1120 = After1120
local PUMPKIN = { "Interface\\Icons\\INV_Misc_Bag_28_Halloween" }
local VOID = { "GemCorrupt" }
After1120(function()
	local function Treats(_, db)
		return (type(db.hallow) == "table" and tonumber(db.hallow.treats)) or 0
	end
	local function Quests()
		return tonumber(ns.Stats().q_hallow) or 0
	end
	Def({ id = "hq10", cat = "quests", pts = 10, name = "Trick or quest", icon = PUMPKIN, goal = 10, event = "hallow", value = Quests,
		desc = function() return string.format(L["Complete %d quests of Hallow's End."], 10) end })
	Def({ id = "hq40", cat = "quests", pts = 25, name = "Keeper of Hallow's End", icon = PUMPKIN, goal = 40, event = "hallow", value = Quests,
		desc = function() return string.format(L["Complete %d quests of Hallow's End."], 40) end })
	Def({ id = "htreat10", cat = "adventure", pts = 10, name = "Sweet tooth", icon = PUMPKIN, goal = 10, event = "hallow", value = Treats,
		desc = function() return string.format(L["Trick or treat at the innkeepers %d times."], 10) end })
	Def({ id = "hopen25", cat = "boosters", pts = 10, name = "A bag full of treats", icon = { "Icon" }, goal = 25, event = "hallow",
		value = function() return tonumber(ns.Stats().hallowOpen) or 0 end,
		desc = function() return string.format(L["Open %d boosters of Hallow's End."], 25) end })
	Def({ id = "hcor1", cat = "finish", pts = 10, name = "A touch of the Void", icon = VOID, goal = 1, event = "hallow",
		value = function(sn) return sn.corrupt or 0 end,
		desc = function() return L["Get a corrupted card."] end })
	Def({ id = "hcor10", cat = "finish", pts = 25, name = "Whispers of N'Zoth", icon = VOID, goal = 10, event = "hallow",
		value = function(sn) return sn.corrupt or 0 end,
		desc = function() return string.format(L["Have %d corrupted cards."], 10) end })
	Def({ id = "hcor100", cat = "finish", pts = 50, name = "Utterly corrupted", icon = VOID, goal = 1, event = "hallow",
		value = function(sn) return sn.corruptFull or 0 end,
		desc = function() return L["Get a card corrupted at 100 %."] end })
end)

After1110(function()
	local function St(key)
		return function(_, db)
			return Stat(db, key)
		end
	end
	local RUBY = { "Ruby" }
	-- (1.13.0, after its second test: ten times as many, the economy redone; 1 000, 10 000 and 50 000 before, their ids
	-- as they were, so that those earned stay)
	Steps("adventure", "rbe", RUBY, {
		{ 10000, 10, "A Handful of Rubies", nil, "rbe:1000" }, { 100000, 25, "Ruby Hoard", nil, "rbe:10000" },
		{ 500000, 50, "A Dragon's Hoard", nil, "rbe:50000" },
	}, St("rubyEarned"), Text("Rubies earned: %d"), "Rubies earned")
	Steps("adventure", "rbs", RUBY, {
		{ 10000, 10, "Big Spender", nil, "rbs:1000" }, { 100000, 25, "Patron of the Collectors", nil, "rbs:10000" },
	}, St("rubySpent"), Text("Rubies spent: %d"), "Rubies spent")
	Def({ id = "qswap", cat = "quests", pts = 10, name = "Not That One", icon = { "Interface\\Icons\\INV_Scroll_05" },
		goal = 10, value = St("qRerolls"), desc = Fixed("The quests of a page changed for rubies 10 times.") })
	Def({ id = "rumorbuy", cat = "adventure", pts = 10, name = "Paid Informant", icon = { "Interface\\GossipFrame\\GossipGossipIcon" },
		goal = 10, value = St("rumorsBought"), desc = Fixed("10 rumors bought from the innkeepers.") })
	Def({ id = "rubypack", cat = "boosters", pts = 10, name = "Regular Customer", icon = { "PackZoneChoice" },
		goal = 10, value = St("rubyPacks"), desc = Fixed("10 boosters bought with rubies.") })
	Steps("collection", "xpt", { "Interface\\Icons\\INV_Misc_Spyglass_02" }, {
		{ 1, 10, "Under the Loupe" }, { 25, 10, "Second Opinion" }, { 100, 25, "Connoisseur" },
	}, St("appraised"), Text("Cards appraised: %d"), "Cards appraised")
	Steps("collection", "x10", { "Interface\\Icons\\INV_Misc_Gem_Diamond_02" }, {
		{ 1, 25, "Gem Mint" }, { 10, 50, "Flawless Collection" },
	}, St("grade10"), Text("Cards appraised 10: %d"), "Cards appraised 10")
	-- the levels past the legend: more tiers of the level of the collector (the last one: a title of prestige)
	local g = AC.GROUPS["lvl"]
	local first = g and g.list[1]
	if first then
		for _, t in ipairs({ { 70, 25, "Aquamarine Collector" }, { 80, 50, "Sapphire Collector" }, { 90, 50, "Emerald Collector" },
			{ 100, 100, "Grand Curator" } }) do
			local i = CuratorOctoFull.Length(g.list) + 1
			g.list[i] = Def({ id = "lvl:" .. t[1], cat = first.cat, goal = t[1], pts = t[2], name = t[3], icon = AC.RankEmblem(t[1]),
				value = first.value, desc = first.desc, group = g, tier = i })
		end
	end
	-- the last talent of each specialization past the legend: the first time it works, its achievement and its
	-- title of prestige (1.14.0: gone with their trees, seen only by a collection that has them)
	local function Talent(id, name, icon, desc)
		return Def({ id = id, cat = "feats", pts = 25, name = name, icon = icon, goal = 1, onlyEarned = true,
			value = function(_, db) return db.stats[id] and 1 or 0 end,
			desc = function() return L[desc] end })
	end
	Talent("tWild", "Warden of the Wilds", { "Interface\\Icons\\Spell_Nature_SpiritArmor" },
		"A card from the Legend of the Wilds, the last talent of the Tracker past the legend.")
	Talent("tTycoon", "Tycoon", { "Interface\\Icons\\INV_Jewelry_Ring_03" },
		"A day opened by the Market Maker, the last talent of the Merchant past the legend.")
	Talent("tFate", "Fatebinder", { "Interface\\Icons\\Spell_Arcane_Arcane04" },
		"A card from the Eye of Fate, the last talent of the Augur past the legend.")
end)

-------------------------------------------------------------------------------
-- (1.13.0) The achievements of 1.13.0, after every achievement before them and the albums of 1.13.0 (the bits of the
-- older ones stay where they were): the Hardcup Saison 3 here; the files loaded after this one add theirs with
-- AC.After1130, in the order they load (Restore.lua, Displays.lua).
-------------------------------------------------------------------------------
local after1130 = {}
local function After1130(fn)
	after1130[CuratorOctoFull.Length(after1130) + 1] = fn
end
AC.After1130 = After1130
-- (1.13.0, after its second test) Last of all, after those of the files loaded after this one: the clause of the
-- collection, the cards an album was missing from contracts of its copies alone (Contract.lua: K:Sign).
local after1131 = {}
local function After1131(fn)
	after1131[CuratorOctoFull.Length(after1131) + 1] = fn
end
-- (1.14.0) The summits of the five trees of the talents (Talents.lua): the first time each works, its achievement and
-- its title of prestige. Last of all.
local after1140 = {}
AC.TALENTS = { "tTerra", "tExped", "tHead", "tLegend", "tWheel", "tGrand", "tOrder", "tBaron", "tChef", "tConserv" }
after1140[1] = function()
	local function Talent(id, name, icon, desc)
		return Def({ id = id, cat = "feats", pts = 25, name = name, icon = icon, goal = 1,
			value = function(_, db) return db.stats[id] and 1 or 0 end,
			desc = function() return L[desc] end })
	end
	Talent("tTerra", "Pathfinder", { "Interface\\Icons\\Spell_Nature_SpiritArmor" },
		"A card from Terra Incognita, a summit of the Cartographer.")
	Talent("tExped", "Expedition Leader", { "Interface\\Icons\\INV_Misc_Spyglass_03" },
		"An epic card or better found during an Expedition, a summit of the Cartographer.")
	Talent("tHead", "Headhunter", { "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" },
		"A card from the Contract of the Day, a summit of the Bounty Hunter.")
	Talent("tLegend", "Legend Slayer", { "Interface\\Icons\\INV_Misc_Head_Dragon_Red" },
		"A card from a Legendary Head, a summit of the Bounty Hunter.")
	Talent("tWheel", "Darling of the Faire", { "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01" },
		"The Darkmoon Wheel stopped on the booster of a dungeon, a summit of the Gambler.")
	Talent("tGrand", "High Roller", { "Interface\\Icons\\Spell_Arcane_Arcane04" },
		"A booster of legend from the Great Game, a summit of the Gambler.")
	Talent("tOrder", "Fixer", { "Interface\\Icons\\INV_Letter_09" },
		"A card from a Special Order, a summit of the Smuggler.")
	Talent("tBaron", "Baron of Booty Bay", { "Interface\\Icons\\INV_Jewelry_Ring_03" },
		"A card of the stall of the reseller at the price he buys it back, a summit of the Smuggler.")
	Talent("tChef", "Master Restorer", { "Interface\\Icons\\INV_Enchant_ShardBrilliantLarge" },
		"A copy restored to 10 by a Masterpiece, a summit of the Archivist.")
	Talent("tConserv", "Grand Conservator", { "Interface\\Icons\\Spell_Holy_MindSooth" },
		"A 10 from an appraisal of the Grand Conservator, a summit of the Archivist.")
end
-- (1.14.0, after its test, his word: the innkeeper redone) The leads followed to their card, the dishes of the day
-- tasted, the rest of the collector (Tavern.lua, Lodging.lua): after the summits, last of all (the bits of the others
-- where they were).
after1140[2] = function()
	local LEAD = { "Interface\\Icons\\Ability_Tracking" }
	local DISH = { "Interface\\Icons\\INV_Misc_Food_15" }
	local REST = { "Interface\\Icons\\Spell_Nature_Sleep" }
	Tiers("adventure", "lead", LEAD, {
		{ 1, 10, "On the Trail" }, { 10, 25, "Bloodhound" }, { 50, 50, "Master Tracker" },
	}, function(_, db)
		return tonumber(db.stats.leads) or 0
	end, function(a)
		return string.format(L["Leads of the tavern followed to their card: %d"], a.goal)
	end, "Leads of the tavern")
	Def({ id = "gourmet", cat = "adventure", pts = 10, name = "Gourmet", icon = DISH,
		value = function(_, db)
			local n = 0
			local LG = ns.Lodging
			for key in pairs(type(InnsOf(db).tasted) == "table" and InnsOf(db).tasted or {}) do
				if not LG or LG.BY[key] then
					n = n + 1
				end
			end
			return n
		end,
		goalOf = function() return ns.Lodging and CuratorOctoFull.Length(ns.Lodging.DISHES) or 5 end,
		desc = function() return L["Every dish of the day of the innkeepers tasted."] end })
	Def({ id = "wellrested", cat = "adventure", pts = 10, name = "Well Rested", icon = REST,
		value = function(_, db)
			local r = InnsOf(db).rest
			return type(r) == "table" and (tonumber(r.b) or 0) or 0
		end,
		goalOf = function() return ns.Lodging and ns.Lodging.REST_MAX or 300 end,
		desc = function() return string.format(L["As much rest as there can be: %d creatures of rest at once."], ns.Lodging and ns.Lodging.REST_MAX or 300) end })
end

-- (1.14.0) The Steamwheedle Exchange (Market.lua: its own counters, db.market.st): the sales, the first purchase, a
-- legendary card sold, a sale of a million rubies, a barter with a player of the other side, the cards an album was
-- missing bought there. After the dishes and the rest of the innkeeper, last of all (the bits of the others where they
-- were).
after1140[3] = function()
	local HAMMER = { "Interface\\Icons\\INV_Hammer_09" }
	local COIN = { "Interface\\Icons\\INV_Misc_Coin_17" }
	local function St(db, key)
		local m = type(db.market) == "table" and db.market or nil
		local st = m and type(m.st) == "table" and m.st or nil
		return st and tonumber(st[key]) or 0
	end
	Tiers("social", "msold", HAMMER, {
		{ 1, 10, "First Strike of the Hammer" }, { 25, 25, "Smooth Talker" }, { 100, 50, "Auctioneer" },
	}, function(_, db)
		return St(db, "sold")
	end, function(a)
		return a.goal == 1 and L["Your first sale at the Steamwheedle Exchange."] or string.format(L["Sales at the Steamwheedle Exchange: %d"], a.goal)
	end, "Sales at the Exchange")
	Def({ id = "mbought", cat = "social", pts = 10, name = "First Purchase", icon = COIN, goal = 1,
		value = function(_, db) return math.min(1, St(db, "bought")) end,
		desc = function() return L["Your first purchase at the Steamwheedle Exchange."] end })
	Def({ id = "mlegend", cat = "social", pts = 25, name = "Merchant of Legends", icon = { "Interface\\Icons\\INV_Misc_Coin_04" }, goal = 1,
		value = function(_, db) return math.min(1, St(db, "legend")) end,
		desc = function() return L["A legendary card or better sold at the Steamwheedle Exchange."] end })
	Def({ id = "mbig", cat = "social", pts = 50, name = "The Deal of the Century", icon = { "Interface\\Icons\\INV_Misc_Coin_02" }, goal = 1,
		value = function(_, db) return math.min(1, St(db, "big")) end,
		desc = function() return L["A sale of 1,000,000 rubies or more at the Steamwheedle Exchange."] end })
	Def({ id = "mcross", cat = "social", pts = 10, name = "Without Borders", icon = { "Interface\\Icons\\INV_Misc_Map_01" }, goal = 1,
		value = function(_, db) return math.min(1, St(db, "cross")) end,
		desc = function() return L["A barter with a player of the other faction."] end })
	Def({ id = "mfilon", cat = "social", pts = 25, name = "A Rich Vein", icon = { "Interface\\Icons\\INV_Pick_02" }, goal = 10,
		value = function(_, db) return St(db, "filon") end,
		desc = function() return L["10 cards you were missing, bought at the Steamwheedle Exchange."] end })
end

-- (1.14.0, after the test of the cases, his word: many more achievements, and secret ones) The cases (Cases.lua: their
-- counters, the cards won), the discovery of the Paladin Collection Case No. 1 (Discovery.lua: its quests), the paladins
-- and the Light (their counters, Discovery.lua), and the secret ones of it: "?" and their riddle until earned. After the
-- Exchange, last of all (the bits of the others where they were).
after1140[4] = function()
	local CASE = { "CratePal1Top", { 0.209, 0.791, 0, 0.582 } }
	local KEY = { "Interface\\Icons\\INV_Misc_Key_03" }
	local LIGHT = { "Interface\\Icons\\Spell_Holy_HolyBolt" }
	local function St(db, key)
		return type(db.stats) == "table" and tonumber(db.stats[key]) or 0
	end
	-- (the counters of the spells of the paladins, by their group: Discovery.lua)
	local function Pal(db, ...)
		local t = type(db.stats) == "table" and type(db.stats.pal) == "table" and db.stats.pal or {}
		local n = 0
		for _, g in ipairs({ unpack(arg, 1, arg.n) }) do
			n = n + (tonumber(t[g]) or 0)
		end
		return n
	end
	local function Names(...)
		local D = ns.Discovery
		local out = {}
		for _, g in ipairs({ unpack(arg, 1, arg.n) }) do
			out[CuratorOctoFull.Length(out) + 1] = D and D:SpellText(g) or g
		end
		if CuratorOctoFull.Length(out) == 1 then
			return out[1]
		end
		local last = CuratorOctoFull.Remove(out)
		return string.format(L["%s or %s"], table.concat(out, ", "), last)
	end
	-- (the cards of the cases won, once a check: their ranks, their finishes, the 10s of an appraisal)
	local function Won(sn)
		if sn and sn.caseWon then
			return sn.caseWon
		end
		local w = { rank = {}, thunder = 0, titan = 0, ten = 0 }
		local CS = ns.Cases
		for _, x in ipairs((CS and CS.Won and CS:Won()) or {}) do
			local r = tonumber(x.r) or 0
			for k = 1, r do
				w.rank[k] = (w.rank[k] or 0) + 1
			end
			if x.f == "thunder" then
				w.thunder = w.thunder + 1
			elseif x.f == "titan" then
				w.titan = w.titan + 1
			end
			if x.ap and tonumber(x.g) == 10 then
				w.ten = w.ten + 1
			end
		end
		if sn then
			sn.caseWon = w
		end
		return w
	end
	local function Collection()
		local CS = ns.Cases
		if not (CS and CS.Progress) then
			return 0, 20
		end
		local got, all = CS:Progress(ns.Discovery and ns.Discovery.CASE or nil)
		return tonumber(got) or 0, math.max(1, tonumber(all) or 20)
	end
	-- the cases
	Steps("cases", "cget", CASE, {
		{ 1, 5, "A Mysterious Case" }, { 10, 10, "Case Hunter" }, { 50, 25, "Case Collector" }, { 250, 50, "Warehouse Keeper" },
	}, function(_, db)
		return St(db, "casesGot")
	end, function(a)
		return string.format(L["Cases obtained: %d"], a.goal)
	end, "Cases obtained")
	Steps("cases", "copen", KEY, {
		{ 1, 5, "The First Turn of the Key" }, { 10, 10, "Key Master" }, { 50, 25, "Locksmith" }, { 100, 25, "Treasure Keeper" },
		{ 250, 50, "Lord of the Vault" },
	}, function(_, db)
		return St(db, "casesOpened")
	end, function(a)
		return string.format(L["Cases opened: %d"], a.goal)
	end, "Cases opened")
	local RANKS = {
		{ "crank2", 2, 10, "Restricted Access", { "Gem4" }, "A card of the Restricted rank or better, out of a case." },
		{ "crank3", 3, 10, "Classified Information", { "Gem4", nil, { 1, 0.55, 1 } }, "A card of the Classified rank or better, out of a case." },
		{ "crank4", 4, 25, "Top Secret", { "Gem6" }, "A card of the Covert rank or better, out of a case." },
		{ "crank5", 5, 50, "Priceless", { "Gem8" }, "A priceless card, a weapon of legend, out of a case." },
	}
	for _, r in ipairs(RANKS) do
		local _, r = _, r; Def({ id = r[1], cat = "cases", pts = r[3], name = r[4], icon = r[5], goal = 1,
			value = function(sn) return math.min(1, Won(sn).rank[r[2]] or 0) end,
			desc = function() return L[r[6]] end })
	end
	Def({ id = "ccoll:5", cat = "cases", pts = 10, name = "Initiate of the Silver Hand", icon = CASE, goal = 5,
		value = function() return (Collection()) end,
		desc = function() return string.format(L["%d different cards of the Paladin Collection."], 5) end })
	Def({ id = "ccoll:10", cat = "cases", pts = 25, name = "Squire of the Silver Hand", icon = CASE, goal = 10,
		value = function() return (Collection()) end,
		desc = function() return string.format(L["%d different cards of the Paladin Collection."], 10) end })
	Def({ id = "ccollall", cat = "cases", pts = 50, name = "The Whole Silver Hand", icon = CASE,
		value = function() return (Collection()) end,
		goalOf = function() return CuratorOctoFull.Select(2, Collection()) end,
		desc = function() return L["Every card of the Paladin Collection, the weapons of legend aside."] end })
	Def({ id = "cthunder", cat = "cases", pts = 10, name = "Case Struck by Lightning", icon = { "Interface\\Icons\\Spell_Nature_Lightning" }, goal = 1,
		value = function(sn) return math.min(1, Won(sn).thunder) end,
		desc = function() return L["A thunderforged card out of a case."] end })
	Def({ id = "ctitan", cat = "cases", pts = 25, name = "Forged in the Case", icon = { "Interface\\Icons\\INV_Enchant_ShardPrismaticLarge" }, goal = 1,
		value = function(sn) return math.min(1, Won(sn).titan) end,
		desc = function() return L["A titanforged card out of a case."] end })
	Def({ id = "cgrade10", cat = "cases", pts = 25, name = "Perfect Ten", icon = { "Interface\\Icons\\INV_Misc_Spyglass_03" }, goal = 1,
		value = function(sn) return math.min(1, Won(sn).ten) end,
		desc = function() return L["A card of a case appraised 10 at a banker."] end })
	Steps("cases", "ccontract", { "Interface\\Icons\\INV_Scroll_03" }, {
		{ 1, 10, "Ten for One" }, { 10, 25, "Trader of the Light" },
	}, function(_, db)
		return St(db, "caseContracts")
	end, function(a)
		return a.goal == 1 and L["An exchange contract of cards of a case signed."] or string.format(L["Exchange contracts of cards of a case signed: %d"], a.goal)
	end, "Contracts of the cases")
	Def({ id = "ckey:25", cat = "cases", pts = 10, name = "A Ring of Keys", icon = KEY, goal = 25,
		value = function(_, db) return St(db, "caseKeys") end,
		desc = function() return string.format(L["Keys bought: %d"], 25) end })
	-- the discovery of the Paladin Collection Case No. 1: its quests (an event: once it is over, only for those who
	-- earned them)
	local g = Steps("quests", "qdisc", LIGHT, {
		{ 1, 10, "Called by the Light" }, { 10, 10, "Squire of the Light" }, { 25, 25, "Knight of the Light" },
		{ 50, 25, "Champion of the Light" }, { 100, 50, "Highlord of the Discovery" },
	}, function(_, db)
		return St(db, "q_discovery")
	end, function(a)
		return string.format(L["Quests of the discovery of the Paladin Collection Case No. 1 completed: %d"], a.goal)
	end, "Quests of the discovery")
	for _, a in ipairs(g.list) do
		a.event = "paladin"
	end
	-- the Light and its paladins
	Steps("adventure", "scourge", { "Interface\\Icons\\Spell_Shadow_AnimateDead" }, {
		{ 100, 10, "Undertaker" }, { 1000, 25, "Scourge Slayer" }, { 5000, 50, "Bane of the Lich King" },
	}, function(_, db)
		return St(db, "scourge")
	end, function(a)
		return string.format(L["Undead that give experience defeated: %d"], a.goal)
	end, "Undead defeated")
	Steps("adventure", "lightrun", { "Interface\\Icons\\INV_Misc_Key_15" }, {
		{ 5, 10, "Crusader of the Light" }, { 25, 25, "Purifier" }, { 100, 50, "Lightbringer" },
	}, function(_, db)
		return St(db, "lightDone")
	end, function(a)
		return string.format(L["Dungeons of the Light completed (%s): %d"], ns.Discovery and ns.Discovery:LightText() or "", a.goal)
	end, "Dungeons of the Light")
	Steps("adventure", "rez", { "Interface\\Icons\\Spell_Holy_Resurrection" }, {
		{ 10, 10, "Second Chance" }, { 50, 25, "Angel of Mercy" }, { 250, 50, "Miracle Worker" },
	}, function(_, db)
		return St(db, "rez")
	end, function(a)
		return string.format(L["Fallen allies brought back to life: %d"], a.goal)
	end, "Fallen allies raised")
	Steps("adventure", "palheal", LIGHT, {
		{ 100, 10, "Light of the Faithful" }, { 1000, 25, "Beacon of Hope" }, { 5000, 50, "The Light Provides" },
	}, function(_, db)
		return Pal(db, "light", "flash")
	end, function(a)
		return string.format(L["%s cast: %d"], Names("light", "flash"), a.goal)
	end, "Healing of the Light")
	Steps("adventure", "paljudge", { "Interface\\Icons\\Spell_Holy_RighteousFury" }, {
		{ 100, 10, "Judge" }, { 1000, 25, "High Inquisitor" },
	}, function(_, db)
		return Pal(db, "judge")
	end, function(a)
		return string.format(L["%s cast: %d"], Names("judge"), a.goal)
	end, "Judgements")
	Steps("adventure", "palbless", { "Interface\\Icons\\Spell_Holy_FistOfJustice" }, {
		{ 100, 10, "Benevolent" }, { 1000, 25, "Blessed Be" },
	}, function(_, db)
		return Pal(db, "bless", "protect")
	end, function(a)
		return string.format(L["Blessings cast: %d"], a.goal)
	end, "Blessings")
	Steps("adventure", "palhands", { "Interface\\Icons\\Spell_Holy_LayOnHands" }, {
		{ 10, 10, "Healing Hands" }, { 50, 25, "Saint" },
	}, function(_, db)
		return Pal(db, "hands")
	end, function(a)
		return string.format(L["%s used: %d"], Names("hands"), a.goal)
	end, "Hands of the Light")
	Steps("adventure", "palhoj", { "Interface\\Icons\\Spell_Holy_SealOfMight" }, {
		{ 50, 10, "Order of the Hammer" }, { 500, 25, "Justice Served" },
	}, function(_, db)
		return Pal(db, "hammer")
	end, function(a)
		return string.format(L["%s cast: %d"], Names("hammer"), a.goal)
	end, "Stuns of the Light")
	Steps("adventure", "palbubble", { "Interface\\Icons\\Spell_Holy_DivineIntervention" }, {
		{ 25, 10, "Unbreakable" }, { 250, 25, "Lord of the Bubble" },
	}, function(_, db)
		return Pal(db, "shield")
	end, function(a)
		return string.format(L["%s cast: %d"], Names("shield"), a.goal)
	end, "Shields of the Light")
	-- the secret ones: "?" and their riddle until earned (their flags in the stats: Discovery.lua)
	local function Secret(id, pts, name, icon, desc, hint, value)
		return Def({ id = id, cat = "secret", pts = pts, name = name, icon = icon, goal = 1, secret = true, hint = hint,
			value = value or function(_, db) return (type(db.stats) == "table" and db.stats[id]) and 1 or 0 end,
			desc = type(desc) == "function" and desc or function() return L[desc] end })
	end
	Secret("sBubble", 25, "Bubble Hearth", { "Interface\\Icons\\Spell_Holy_DivineIntervention" },
		function() return string.format(L["%s, then your hearthstone, within 10 seconds."], ns.Discovery and ns.Discovery.SpellName(642) or "Divine Shield") end,
		"Some knights of the Light leave a fight inside a shining bubble, straight home.")
	Secret("sSacrifice", 10, "The Last Gift", { "Interface\\Icons\\Spell_Nature_TimeStop" },
		function() return string.format(L["%s cast: your life for another's."], ns.Discovery and ns.Discovery.SpellName(19752) or "Divine Intervention") end,
		"The greatest gift of the Light costs the giver their life.")
	Secret("sUndead", 25, "Forsaken Faith", { "Interface\\Icons\\Spell_Shadow_RaiseDead" },
		function() return string.format(L["%s cast by an undead paladin."], ns.Discovery and ns.Discovery:SpellText("light") or "Holy Light") end,
		"The Light answers even those it should burn.")
	Secret("sChapel", 10, "Light's Hope", CASE, function()
		local s = ns.SeriesByKey and ns.SeriesByKey("eastplague")
		return string.format(L["A case opened in %s."], s and C:SeriesName(s) or "Eastern Plaguelands")
	end, "Open what you found where the last hope of the Light still stands.")
	Secret("sCulling", 25, "The Culling", CASE, function()
		local s = ns.SeriesByKey and ns.SeriesByKey("stratholme")
		return string.format(L["A case opened in %s."], s and C:SeriesName(s) or "Stratholme")
	end, "Some cases should be opened where a prince made his choice.")
	Secret("sHoard", 10, "Saving It for Later", CASE, "25 cases waiting to be opened, at once.",
		"Why open them? Keeping them is so much nicer.", function()
			local CS = ns.Cases
			return (CS and CS.Total and CS:Total() >= 25) and 1 or 0
		end)
	Secret("sKeyring", 10, "Keys Without Locks", KEY, "10 keys at once, and not a single case to open.",
		"A ring heavy with keys, and nothing to open.", function()
			local CS = ns.Cases
			if not (CS and CS.Total and CS.Editions) then
				return 0
			end
			local keys = 0
			for _, k in ipairs(CS:Editions()) do
				keys = keys + CS:Keys(k)
			end
			return (keys >= 10 and CS:Total() == 0) and 1 or 0
		end)
	Secret("sVigil", 10, "Midnight Vigil", LIGHT, "A quest of the discovery claimed between midnight and one in the morning.",
		"A vigil kept until midnight is rewarded.")
	Secret("sPatience", 10, "Trial of Patience", KEY, "10 cases opened in a row without a card above the Rare rank.",
		"The Light tests the patient, ten times over.")
	Secret("sLightDay", 25, "Four Halls of the Dead", { "Interface\\Icons\\INV_Misc_Key_15" }, function()
		return string.format(L["%s: all four completed between two daily resets."], ns.Discovery and ns.Discovery:LightText(true) or "")
	end, "Four halls of the dead, cleansed between two dawns.")
	Secret("sMassRez", 10, "Rise, All of You", { "Interface\\Icons\\Spell_Holy_Resurrection" }, "3 fallen allies brought back to life within a minute.",
		"One after the other, they all rose again.")
end

-- (31 October, the night, his word: achievements of the wear, never a grade told but by the expert) The grades the expert
-- told (Expertise.lua, Cases.lua: an appraisal; counted below), the flaws the enchanters mended, their mishaps, the
-- copies left without a flaw (Restore.lua). After the cases, last of all (the bits of the others where they were).
after1140[5] = function()
	local LOUPE = { "Interface\\Icons\\INV_Misc_Spyglass_02" }
	local ENGRAVE = { "Interface\\Icons\\Trade_Engraving" }
	local function St(db, key)
		return type(db.stats) == "table" and tonumber(db.stats[key]) or 0
	end
	-- (the grades told: their count by whole grade, 1 to 10)
	local function Told(db, lo, hi)
		local t = type(db.stats) == "table" and type(db.stats.gtold) == "table" and db.stats.gtold or {}
		local n = 0
		for g = lo, hi do
			n = n + (tonumber(t[g]) or 0)
		end
		return n
	end
	Def({ id = "wgr1", cat = "collection", pts = 10, name = "Worn to the Card", icon = { "Interface\\Icons\\INV_Misc_Note_02" }, goal = 1,
		value = function(_, db) return math.min(1, Told(db, 1, 1)) end,
		desc = function() return L["A card the expert appraised 1."] end })
	Tiers("collection", "wlow", LOUPE, {
		{ 3, 10, "Seen Better Days" }, { 15, 25, "Battle-Scarred Collection" },
	}, function(_, db)
		return Told(db, 1, 3)
	end, function(a)
		return string.format(L["Cards the expert appraised 3 or lower: %d"], a.goal)
	end, "Cards appraised 3 or lower")
	Def({ id = "wrange", cat = "collection", pts = 50, name = "Every Shade of Wear", icon = { "Interface\\Icons\\INV_Misc_Gem_Variety_01" }, goal = 10,
		value = function(_, db)
			local t = type(db.stats) == "table" and type(db.stats.gtold) == "table" and db.stats.gtold or {}
			local n = 0
			for g = 1, 10 do
				if (tonumber(t[g]) or 0) > 0 then
					n = n + 1
				end
			end
			return n
		end,
		desc = function() return L["Cards the expert appraised to every grade, from 1 to 10."] end })
	Tiers("collection", "wfix", ENGRAVE, {
		{ 1, 10, "A Gentle Touch" }, { 50, 25, "Hands of the Enchanter" }, { 250, 50, "Good as New" },
	}, function(_, db)
		return St(db, "flawsMended")
	end, function(a)
		return a.goal == 1 and L["A flaw mended by an enchanter."] or string.format(L["Flaws mended by the enchanters: %d"], a.goal)
	end, "Flaws mended")
	Def({ id = "wclean", cat = "collection", pts = 25, name = "Not a Scratch Left", icon = { "Interface\\Icons\\INV_Enchant_ShardBrilliantLarge" }, goal = 1,
		value = function(_, db) return math.min(1, St(db, "flawless")) end,
		desc = function() return L["A copy left without a single flaw by the enchanters."] end })
	Def({ id = "wmishap", cat = "secret", pts = 10, name = "The Varnish Clouded", icon = { "Interface\\Icons\\INV_Potion_25" }, goal = 1, secret = true,
		hint = "Even the steadiest hand slips now and then.",
		value = function(_, db) return math.min(1, St(db, "mishaps")) end,
		desc = function() return L["A mark left on a card by the work of an enchanter."] end })
end

After1131(function()
	Def({ id = "kclause", cat = "contracts", pts = 10, name = "Collector's clause", icon = { "Interface\\Icons\\INV_Scroll_03" }, goal = 1,
		value = function(_, db) return math.min(1, tonumber(db.stats.kClause) or 0) end,
		desc = function() return L["A card your album was missing, from a contract of its copies alone."] end })
	Def({ id = "kclause25", cat = "contracts", pts = 25, name = "Notary of the albums", icon = { "Interface\\Icons\\INV_Scroll_04" }, goal = 25,
		value = function(_, db) return tonumber(db.stats.kClause) or 0 end,
		desc = function() return L["25 cards your albums were missing, from contracts of their copies alone."] end })
end)
After1130(function()
	-- (its players: the cards of the event brought from WoW Classic with the gift code of the website, Gifts.lua)
	Def({ id = "hardcup", gone = true })
end)

-- The titles of prestige: each one comes with an achievement. Chosen (db.title), it shows instead of the
-- title of the points (on the profile, its showcase framed in gold, in the tooltips, in the guild); its
-- key goes with the profile.
AC.SPECIAL = {
	{ key = "beasts", ach = "bmaster", name = "Beastmaster" },
	{ key = "dragons", ach = "t2:all", name = "Dragonslayer" },
	{ key = "demons", ach = "t3:all", name = "Demonologist" },
	{ key = "undead", ach = "t6:all", name = "Gravedigger" },
	{ key = "elements", ach = "t4:all", name = "Elemental Lord" },
	{ key = "myths", ach = "mall", name = "Mythkeeper" },
	{ key = "complete", ach = "fall", name = "Completionist" },
	{ key = "night", ach = "night", name = "Insomniac" },
	-- (1.6.0: the last talents)
	{ key = "hunt", ach = "tPrey", name = "Master of the Hunt" },
	{ key = "contracts", ach = "tMaster", name = "Master of Contracts" },
	{ key = "oracle", ach = "tOracle", name = "Oracle" },
	-- (1.8.0: every inn of Azeroth)
	{ key = "globetrotter", ach = "visaall", name = "Globetrotter" },
	-- (1.9.0: a thousand quests, 250 battlegrounds won, ten thousand honorable kills)
	{ key = "questmaster", ach = "qd:1000", name = "Questmaster" },
	{ key = "warbringer", ach = "bgw:250", name = "Warbringer" },
	{ key = "executioner", ach = "hk:10000", name = "Executioner" },
	-- (1.10.0: fifty golden quests for the leaders of a side)
	{ key = "championH", ach = "gqhorde", name = "Champion of the Horde" },
	{ key = "championA", ach = "gqalliance", name = "Champion of the Alliance" },
	-- (1.11.0: the hundredth level; the last talents past the legend)
	{ key = "curator", ach = "lvl:100", name = "Grand Curator" },
	{ key = "wild", ach = "tWild", name = "Warden of the Wilds" },
	{ key = "tycoon", ach = "tTycoon", name = "Tycoon" },
	{ key = "fate", ach = "tFate", name = "Fatebinder" },
	-- (1.13.0: the players of the Hardcup Saison 3)
	
	-- (1.14.0: the summits of the five trees of the talents)
	{ key = "pathfinder", ach = "tTerra", name = "Pathfinder" },
	{ key = "expedition", ach = "tExped", name = "Expedition Leader" },
	{ key = "headhunter", ach = "tHead", name = "Headhunter" },
	{ key = "legendslayer", ach = "tLegend", name = "Legend Slayer" },
	{ key = "darling", ach = "tWheel", name = "Darling of the Faire" },
	{ key = "highroller", ach = "tGrand", name = "High Roller" },
	{ key = "fixer", ach = "tOrder", name = "Fixer" },
	{ key = "baron", ach = "tBaron", name = "Baron of Booty Bay" },
	{ key = "restorer", ach = "tChef", name = "Master Restorer" },
	{ key = "conservator", ach = "tConserv", name = "Grand Conservator" },
	-- (1.14.0: a hundred sales at the Steamwheedle Exchange)
	{ key = "auctioneer", ach = "msold100", name = "Auctioneer" },
}
AC.SPECIAL_BY = {}
for _, x in ipairs(AC.SPECIAL) do
	AC.SPECIAL_BY[x.key] = x
end
-- the colour of the titles of prestige
AC.PRESTIGE = { 1, 0.78, 0.3 }

-------------------------------------------------------------------------------
-- One achievement per album (once the albums are loaded), after the general ones
-------------------------------------------------------------------------------
local function AlbumAch(s)
	local g = s.glow or { 1, 0.84, 0.48 }
	-- (1.13.0: a limited edition, the Hardcup Saison 3, as an event)
	Def({ id = "album:" .. s.key, cat = "albums", series = s, pts = (s.raid or s.event or s.limited) and 25 or 10, goal = s.official or CuratorOctoFull.Length(s.list),
		icon = { s.set or "SetElwynn", nil, { 0.55 + 0.45 * g[1], 0.55 + 0.45 * g[2], 0.55 + 0.45 * g[3] } },
		value = function(sn) return sn.albums[s.key] or 0 end,
		desc = function() return L["Every card of this album."] end })
end

-- One for every album: those of the first albums, then the general ones added later, then those of the
-- albums added later (s.since: Zephras), each at the end of the list when it came; (1.7.0) the albums
-- that came after the achievements of 1.5.0 (the new dungeons of Forever) go after those, in their turn.
local function Version(v)
	local a, b, c = CuratorOctoFull.Match(tostring(v or ""), "^(%d+)%.(%d+)%.?(%d*)")
	return (tonumber(a) or 0) * 10000 + (tonumber(b) or 0) * 100 + (tonumber(c) or 0)
end
local AFTER_150 = Version("1.5.0")
local AFTER_180 = Version("1.8.0")
local AFTER_190 = Version("1.9.0")
local AFTER_1100 = Version("1.10.0")
local AFTER_1110 = Version("1.11.0")
-- (1.13.0: the albums of 1.13.0 and later after every achievement before them, Hallow's End's too: the profiles shared
-- tell the achievements by their place in the list)
local AFTER_1130 = Version("1.13.0")

function AC:Build()
	if self.built or not (ns.Series and ns.Series[1] and ns.Series[1].list) then
		return self.built
	end
	self.built = true
	for _, s in ipairs(ns.Series) do
		if not s.since then
			AlbumAch(s)
		end
	end
	for _, fn in ipairs(late) do
		fn()
	end
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) < AFTER_150 then
			AlbumAch(s)
		end
	end
	for _, fn in ipairs(last) do
		fn()
	end
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_150 and Version(s.since) < AFTER_180 then
			AlbumAch(s)
		end
	end
	for _, fn in ipairs(after180) do
		fn()
	end
	-- (1.8.0) the pioneers, after every achievement of 1.8.0: the collectors who played Curator before WoW
	-- Forever came out (the mark of the save, Beta.lua), kept when the collection starts over
	Def({ id = "pioneer", gone = true })
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_180 and Version(s.since) < AFTER_190 then
			AlbumAch(s)
		end
	end
	-- (1.9.0) the quests, the PvP and the others of 1.9.0, then the albums of 1.9.0 and later
	for _, fn in ipairs(after190) do
		fn()
	end
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_190 and Version(s.since) < AFTER_1100 then
			AlbumAch(s)
		end
	end
	-- (1.10.0) the golden quests, then the albums of 1.10.0
	for _, fn in ipairs(after1100) do
		fn()
	end
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_1100 and Version(s.since) < AFTER_1110 then
			AlbumAch(s)
		end
	end
	-- (1.11.0) the rubies and the expertise, then the albums of 1.11.0 and later
	for _, fn in ipairs(after1110) do
		fn()
	end
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_1110 and Version(s.since) < AFTER_1130 then
			AlbumAch(s)
		end
	end
	-- (1.12.0) Hallow's End: its quests, its treats, its boosters, its corrupted cards
	for _, fn in ipairs(after1120) do
		fn()
	end
	-- (1.13.0) the albums of 1.13.0 and later (the Hardcup Saison 3), last
	for _, s in ipairs(ns.Series) do
		if s.since and Version(s.since) >= AFTER_1130 then
			AlbumAch(s)
		end
	end
	-- (1.13.0) then the achievements of 1.13.0, in the order they were given (this file's first: the Hardcup Saison 3;
	-- then those of the files loaded after it, AC.After1130: the restorations, the displays)
	for _, fn in ipairs(after1130) do
		fn()
	end
	-- (1.13.0, after its second test) the clause of the collection
	for _, fn in ipairs(after1131) do
		fn()
	end
	-- (1.14.0) the summits of the five trees of the talents, last
	for _, fn in ipairs(after1140) do
		fn()
	end
	-- (1.14.0, after the test of the cases, his word) every secret achievement in the category of the secret ones (out of
	-- the feats); the PvP gone until its rework: its achievements stay in the list for the bits of the others, shown to
	-- none, earned by none, counted for none (AC.Gone), those of its quests among the quests
	for _, a in ipairs(self.list) do
		if a.secret then
			a.cat = "secret"
		end
		if self.PVP_QUESTS[a.id] then
			a.cat = "quests"
		elseif a.cat == "pvp" or self.PVP_GONE[a.id] then
			a.gone = true
		end
	end
	return true
end

-- (1.14.0) The achievements of the quests of PvP (they stay, with their quests), those of PvP elsewhere (gone with it).
AC.PVP_QUESTS = { ["qpvp:10"] = true, ["qpvp:50"] = true, ["qpvp:250"] = true, qallpd = true, qallpw = true, qallpm = true }
AC.PVP_GONE = { underdog = true, mirror = true }

function AC:Name(a)
	if a.series then
		return string.format(L["Album complete: %s"], C:SeriesName(a.series))
	end
	if a.nameOf then
		return a.nameOf()
	end
	return L[a.name]
end

function AC:Desc(a, sn)
	return a.desc(a, sn)
end

function AC:Goal(a, sn)
	if a.goalOf then
		return sn and a.goalOf(sn) or 1
	end
	return a.goal
end

-------------------------------------------------------------------------------
-- Where the collection is: counted once for every check
-------------------------------------------------------------------------------
function AC:Snapshot()
	local db = ns.db
	local sn = { owned = 0, total = 0, byRarity = C.PerRarity(0), shiny = 0, holo = 0, holoMythic = false, mythics = 0,
		albums = {}, half = false, complete = 0, families = {}, familySize = {},
		-- (1.5.0) the cards of each type of creature, of each family of beasts, of each rarity; the copies
		kinds = {}, kindSize = {}, beasts = {}, beastSize = {}, beastFamilies = 0, beastDone = 0, rarSize = C.PerRarity(0),
		copies = 0, maxCopies = 0, corrupt = 0, corruptFull = 0 }
	-- (the copies that came in a trade not confirmed yet do not count yet)
	local T = ns.Trade
	for _, s in ipairs(ns.Series) do
		local o = 0
		-- (1.12.0) an album of an event (Hallow.lua) counts in no total of the collection, its own achievement
		-- aside: once over, a total with its cards would be out of reach. Its copies and its finishes count.
		-- (1.13.0) A limited edition of another game (the Hardcup Saison 3, its cards from a gift code): nothing of it
		-- counts, its own achievement aside, not even its copies and its finishes.
		local ev = s.event ~= nil or s.limited ~= nil
		local away = s.limited ~= nil
		for _, card in ipairs(s.list) do
			local e = db.cards[card.key]
			if e and T and e.n > 0 and T:HeldAll(card.key) > 0 then
				e = { n = e.n - T:HeldAll(card.key), s = (e.s or 0) - T:Held(card.key, "shiny"), h = (e.h or 0) - T:Held(card.key, "holo") }
			end
			local t, fam = card.type, card.type == 1 and card.family or 0
			if not ev then
				sn.rarSize[card.rarity] = sn.rarSize[card.rarity] + 1
				if t then
					sn.kindSize[t] = (sn.kindSize[t] or 0) + 1
				end
				if fam > 0 then
					sn.beastSize[fam] = (sn.beastSize[fam] or 0) + 1
				end
			end
			if e and e.n > 0 and away then
				-- (1.14.0: the contraband of the Hardcup Saison 3 out of its album)
				if not card.smuggle then
					o = o + 1
				end
			elseif e and e.n > 0 then
				o = o + 1
				sn.copies = sn.copies + e.n
				if e.n > sn.maxCopies then
					sn.maxCopies = e.n
				end
				-- (1.12.0) its corruption; (1.14.0, his word: a corrupted copy goes in a trade too) the corrupted copies that
				-- came in a trade or from the Bourse, not free yet, wait as the others (Copies.lua: CP.Locked)
				local raw = db.cards[card.key]
				if raw and (raw.c or 0) > 0 then
					local free, top = raw.c, tonumber(raw.k) or 0
					local CP = ns.Copies
					if T and CP and T:Held(card.key, "corrupt") > 0 then
						free, top = 0, 0
						for _, r in ipairs(CP:List(card.key)) do
							if r.f == "c" and not CP.Locked(r) then
								free = free + 1
								top = math.max(top, tonumber(r.cor) or 0)
							end
						end
					end
					if free > 0 then
						sn.corrupt = sn.corrupt + 1
						if top >= 100 then
							sn.corruptFull = sn.corruptFull + 1
						end
					end
				end
				if not ev then
					if t then
						sn.kinds[t] = (sn.kinds[t] or 0) + 1
					end
					if fam > 0 then
						sn.beasts[fam] = (sn.beasts[fam] or 0) + 1
					end
					sn.byRarity[card.rarity] = sn.byRarity[card.rarity] + 1
				end
				if (e.s or 0) > 0 then
					sn.shiny = sn.shiny + 1
				end
				if (e.h or 0) > 0 then
					sn.holo = sn.holo + 1
					if card.rarity == ns.MYTHIC then
						sn.holoMythic = true
					end
				end
			end
		end
		sn.albums[s.key] = o
		if not ev then
			sn.mythics = sn.mythics + CuratorOctoFull.Length(s.byRarity[ns.MYTHIC])
			sn.total = sn.total + CuratorOctoFull.Length(s.list)
			sn.owned = sn.owned + o
			local done = o >= CuratorOctoFull.Length(s.list)
			if o * 2 >= CuratorOctoFull.Length(s.list) then
				sn.half = true
			end
			if done then
				sn.complete = sn.complete + 1
			end
			for key, fam in pairs(FAMILY) do
				if fam(s) then
					sn.familySize[key] = (sn.familySize[key] or 0) + 1
					if done then
						sn.families[key] = (sn.families[key] or 0) + 1
					end
				end
			end
		end
	end
	-- (the families of beasts that have cards, and those complete)
	for _, b in ipairs(AC.BEASTS) do
		local size = sn.beastSize[b.f] or 0
		if size > 0 then
			sn.beastFamilies = sn.beastFamilies + 1
			if (sn.beasts[b.f] or 0) >= size then
				sn.beastDone = sn.beastDone + 1
			end
		end
	end
	return sn
end

function AC:Points(earned)
	local n, count = 0, 0
	for _, a in ipairs(self.list) do
		if earned[a.id] and not a.gone then
			n, count = n + a.pts, count + 1
		end
	end
	return n, count
end

-- Earned set of a list of ids.
function AC:Earned()
	return (ns.db and ns.db.ach) or {}
end

-------------------------------------------------------------------------------
-- The titles of the collectors, by their achievement points; each rank shows in the colour of a
-- rarity (from the commons to the mythics)
-------------------------------------------------------------------------------
AC.TITLES = {
	{ 0, "Novice" }, { 50, "Treasure Hunter" }, { 200, "Hoarder" }, { 500, "Master Collector" },
	{ 900, "Card Sovereign" }, { 1400, "Keeper of the Treasure" },
	-- (1.5.0: two more, in the colours of the finishes)
	{ 2000, "Card Emperor" }, { 3000, "Eternal Collector" },
}
-- the ranks beyond the six of the rarities: their colour, their gem (a bolt in a blue stone, a sea-green
-- stone in a ring of gold: the colours of the finishes)
local RANK_LOOK = {
	[7] = { col = { 0.45, 0.78, 1 }, gem = "Gem7" },
	[8] = { col = { 0.35, 1, 0.82 }, gem = "Gem8" },
}

function AC:RankColour(rank)
	local x = RANK_LOOK[rank]
	return x and x.col or ns.RARITY[math.max(1, math.min(rank or 1, CuratorOctoFull.Length(ns.RARITY)))].text
end

function AC:RankGem(rank)
	local x = RANK_LOOK[rank]
	return ns.MEDIA .. (x and x.gem or ("Gem" .. math.max(1, math.min(rank or 1, CuratorOctoFull.Length(ns.RARITY)))))
end

-- A title in the language of the client; female: the one of a female character, in the languages
-- that make one ("<title>#f").
local function TitleName(key, female)
	if female then
		local fk = key .. "#f"
		local v = L[fk]
		if v ~= fk then
			return v
		end
	end
	return L[key]
end

-- The title of a collector with these points: its name, its rank (1 to 6), the points of the next
-- rank and its name (nil at the last one).
function AC:Title(points, female)
	local rank = 1
	for i, t in ipairs(self.TITLES) do
		if (points or 0) >= t[1] then
			rank = i
		end
	end
	local nxt = self.TITLES[rank + 1]
	return TitleName(self.TITLES[rank][2], female), rank, nxt and nxt[1], nxt and TitleName(nxt[2], female)
end

-- My title (my points, the character I play).
function AC:MyTitle()
	return self:Title((self:Points(self:Earned())), self:Female())
end

function AC:Female()
	local ok, female = pcall(function()
		return UnitSex("player") == 3
	end)
	return ok and female == true
end

-------------------------------------------------------------------------------
-- (1.5.0) The titles of prestige
-------------------------------------------------------------------------------
function AC:SpecialName(key, female)
	local x = key and self.SPECIAL_BY[key]
	return x and TitleName(x.name, female) or nil
end

-- The title of prestige of an achievement (nil: none).
function AC:SpecialOf(a)
	for _, x in ipairs(self.SPECIAL) do
		if x.ach == a.id then
			return x
		end
	end
end

-- A title of prestige earned (earned: a set of ids, mine by default).
function AC:HasSpecial(key, earned)
	local x = key and self.SPECIAL_BY[key]
	return x ~= nil and (earned or self:Earned())[x.ach] ~= nil
end

-- The title shown: of prestige when chosen and earned, else the one of the points. Its colour, and
-- whether it is of prestige.
function AC:TitleShown(points, female, special, earned)
	if special and self:HasSpecial(special, earned) then
		return self:SpecialName(special, female), self.PRESTIGE, true
	end
	local title, rank = self:Title(points, female)
	return title, self:RankColour(rank), false
end

-- Mine.
function AC:MyTitleShown()
	return self:TitleShown((self:Points(self:Earned())), self:Female(), ns.db and ns.db.title)
end

-- Another player's, from their profile (their title of prestige: earned in their bits).
function AC:TitleOf(i)
	if not i then
		return nil
	end
	return self:TitleShown(i.points or 0, i.female, i.title, i.title and self:FromBits(i.bits) or nil)
end

-- My title of prestige chosen (nil: the one of the points). Only one earned.
function AC:SetSpecial(key)
	if key ~= nil and not self:HasSpecial(key) then
		return false
	end
	if ns.db then
		ns.db.title = key
	end
	ns.Fire("TITLE_CHANGED", key)
	return true
end

-- The titles of prestige earned (mine), in their order.
function AC:Specials(earned)
	local out = {}
	for _, x in ipairs(self.SPECIAL) do
		if self:HasSpecial(x.key, earned) then
			out[CuratorOctoFull.Length(out) + 1] = x
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- Checking
-------------------------------------------------------------------------------
-- Earns what is reached. silent: no toast (the first check, for what was done before 0.9).
function AC:Check(silent)
	-- (1.7.0: a suspended collection earns nothing, Beta.lua; 1.9.1: nor a banned player)
	if not ns.db or (ns.Beta and (ns.Beta:Suspended() or ns.Beta:Banned())) then
		return {}
	end
	-- (1.14.0, after its test, his word: a reroll earns none; those the account reaches meanwhile come with the next look
	-- on the main, or on this character from level 15: Reroll.lua, RR:Blocks)
	if ns.Reroll and ns.Reroll:Blocks("achievements") then
		return {}
	end
	self:Build()
	local db = ns.db
	db.ach = db.ach or {}
	ns.Stats()
	local sn = self:Snapshot()
	self.lastSnapshot = sn
	local now = CuratorOctoFull.ServerTime()
	local new = {}
	local before = (self:Points(db.ach))
	for _, a in ipairs(self.list) do
		if not db.ach[a.id] and not a.gone then
			local goal = self:Goal(a, sn)
			if goal > 0 and a.value(sn, db) >= goal then
				db.ach[a.id] = now
				new[CuratorOctoFull.Length(new) + 1] = a
			end
		end
	end
	if CuratorOctoFull.Length(new) > 0 then
		ns.Fire("ACH_CHANGED")
		ns.Fire("CLAIMS_CHANGED")
		if not silent then
			-- (each with the points before it and after it: the toasts count them up one after the other)
			local p = before
			for _, a in ipairs(new) do
				ns.Fire("ACH_EARNED", a, p, p + a.pts)
				p = p + a.pts
			end
		end
	end
	return new
end

-------------------------------------------------------------------------------
-- The rewards: the experience of each achievement earned, to claim (twenty for each of its points)
-------------------------------------------------------------------------------
AC.XP_PER_POINT = 20

-- (1.14.0, his word, after a player's: completing an album must feel rewarding) The achievement of an album complete of
-- a zone, a dungeon or a raid: its kind (nil: another achievement, or the album of an event or of a limited edition,
-- which keeps its points). Its reward: a whole level of experience (what the level you are at asks, when it is claimed;
-- kept then, db.achXP), rubies by its kind (Rubies.lua: RB.ALBUM) and a golden booster of an album to choose
-- (Level.lua: the kind "golden" of the boosters to choose).
function AC:AlbumKind(a)
	local s = a and a.series
	if not s then
		return nil
	end
	local kind = ns.Level and ns.Level.KindOf(s)
	return (kind == "zone" or kind == "dungeon" or kind == "raid") and kind or nil
end

function AC:XP(a)
	-- (1.14.0: the talents of the achievements of a kind, Talents.lua: TL:AchBonus)
	local k = ns.Talents and ns.Talents.AchBonus and ns.Talents:AchBonus(a, "xp") or 1
	-- (1.14.0: an album complete, a level: what was given once claimed, else what the level you are at asks)
	if self:AlbumKind(a) then
		local kept = ns.db and type(ns.db.achXP) == "table" and tonumber(ns.db.achXP[a.id])
		if kept and self:Claimed(a) then
			return kept
		end
		local LV = ns.Level
		local level = LV:Level()
		local need = LV.NEED[level] or LV.NEED[LV.MAX - 1] or 0
		return math.floor(need * k + 0.5)
	end
	return math.floor(a.pts * self.XP_PER_POINT * k + 0.5)
end

function AC:Claimed(a)
	local c = ns.db and ns.db.achClaimed
	return c ~= nil and c[a.id] ~= nil
end

-- Earned, its reward not claimed yet.
function AC:Waiting(a)
	local db = ns.db
	return db ~= nil and db.ach ~= nil and db.ach[a.id] ~= nil and not self:Claimed(a)
end

-- The achievements whose rewards wait (of a category, a group, or all of them), in their order.
function AC:Claimable(cat, group)
	self:Build()
	local out = {}
	for _, a in ipairs(self.list) do
		if (not cat or a.cat == cat) and (not group or a.group == group) and not a.gone and self:Waiting(a) then
			out[CuratorOctoFull.Length(out) + 1] = a
		end
	end
	return out
end

function AC:ClaimCount(cat)
	return CuratorOctoFull.Length(self:Claimable(cat))
end

-- (1.11.0) The rubies of an achievement (for each of its points: Rubies.lua).
function AC:Rubies(a)
	return ns.Rubies and ns.Rubies:OfAchievement(a) or 0
end

-- Claims the rewards of these achievements (nil: all of those waiting): their experience together, and
-- (1.11.0) their rubies. Returns the experience, the achievements claimed and the rubies.
function AC:Claim(list)
	local db = ns.db
	if not db then
		return 0, {}, 0
	end
	-- (1.14.0: the cards changed by another addon this session: nothing claimed, the rewards stay; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return 0, {}, 0
	end
	-- (1.14.0, after its test, his word: a reroll claims none, the rewards wait for the main: Reroll.lua, RR:Blocks)
	if ns.Reroll and ns.Reroll:Blocks("achievements") then
		return 0, {}, 0
	end
	db.achClaimed = db.achClaimed or {}
	local now = CuratorOctoFull.ServerTime()
	local xp, done, rubies = 0, {}, 0
	local golden = {}
	for _, a in ipairs(list or self:Claimable()) do
		if self:Waiting(a) then
			local x = self:XP(a)
			-- (1.14.0: an album complete, its level of experience kept as given, and its golden booster)
			if self:AlbumKind(a) then
				db.achXP = type(db.achXP) == "table" and db.achXP or {}
				db.achXP[a.id] = x
				golden[CuratorOctoFull.Length(golden) + 1] = a.series
			end
			db.achClaimed[a.id] = now
			xp = xp + x
			rubies = rubies + self:Rubies(a)
			done[CuratorOctoFull.Length(done) + 1] = a
		end
	end
	-- (1.14.0, his word: its golden booster into an album drawn at random, among those not complete; none: this one)
	if ns.Level then
		for _, s in ipairs(golden) do
			ns.Level:GiveGolden(s)
		end
	end
	if CuratorOctoFull.Length(done) > 0 then
		ns.Fire("ACH_CLAIMED", done, xp, rubies)
		if rubies > 0 and ns.Rubies then
			rubies = ns.Rubies:Gain(rubies, "ach")
		end
		ns.Level:Gain(xp, "ach")
		ns.Fire("CLAIMS_CHANGED")
	end
	return xp, done, rubies
end

-- An achievement only for those who earned it (Beta tester): to the others it is not shown, and it is
-- not among what they have left to earn.
function AC:Shown(a, earned)
	-- (1.14.0: gone, the PvP until its rework: to none)
	if a.gone then
		return false
	end
	-- (1.12.0: the album of an event, once it is over: only for those who completed it; 1.14.0: the event of each)
	local ev = a.event or (a.series ~= nil and a.series.event ~= nil and "hallow") or nil
	local only = a.onlyEarned or (ev ~= nil and self:EventOver(ev))
	return not only or (earned or self:Earned())[a.id] ~= nil
end

-- (1.14.0) Whether an event is over: Hallow's End (Hallow.lua), the discovery of the Paladin Collection Case No. 1
-- (Discovery.lua).
function AC:EventOver(ev)
	if ev == "paladin" then
		return ns.Discovery ~= nil and ns.Discovery:Over()
	end
	return ns.Hallow ~= nil and ns.Hallow:Over()
end

-- How many achievements there are for a player (those shown to them).
function AC:Count(earned)
	self:Build()
	local n = 0
	for _, a in ipairs(self.list) do
		if self:Shown(a, earned) then
			n = n + 1
		end
	end
	return n
end

-- The entries of a category on its page: the achievements alone, and the tiers of a group together
-- (at the place of the first of them): { a } or { group }. earned: the achievements of the player
-- shown (mine by default).
function AC:Entries(cat, earned)
	self:Build()
	earned = earned or self:Earned()
	local out, seen = {}, {}
	for _, a in ipairs(self.list) do
		if a.cat == cat and self:Shown(a, earned) then
			local g = a.group
			if g then
				if not seen[g] then
					seen[g] = true
					out[CuratorOctoFull.Length(out) + 1] = { group = g }
				end
			else
				out[CuratorOctoFull.Length(out) + 1] = { a = a }
			end
		end
	end
	return out
end

-- The tier of a group to reach next (nil: all of them earned), and how many are earned.
function AC:NextTier(g, earned)
	earned = earned or self:Earned()
	local got = 0
	local nxt
	for _, a in ipairs(g.list) do
		if earned[a.id] then
			got = got + 1
		elseif not nxt then
			nxt = a
		end
	end
	return nxt, got
end

-- Checks a moment after changes; a booster or a contract being revealed waits for its end (its
-- cards are saved before they are shown: an achievement must not tell what is coming).
function AC:Queue(delay)
	if self.queued then
		return
	end
	self.queued = true
	ns.Delay(delay or 0.4, function()
		AC.queued = false
		local B = ns.Booster
		if B and B.frame and B.frame:IsShown() and B.state ~= "done" then
			return AC:Queue(1)
		end
		-- (1.11.0: an appraisal being shown, its grade saved before its verdict: UI/Expertise.lua)
		local XU = ns.ExpertiseUI
		if XU and (XU.cer or XU.busy) then
			return AC:Queue(1)
		end
		AC:Check()
	end, AC)
end

-------------------------------------------------------------------------------
-- Sharing: the earned achievements as a bit field (4 per hexadecimal digit, in the order of the list)
-------------------------------------------------------------------------------
function AC:Bits(earned)
	self:Build()
	local out = {}
	for i = 1, math.ceil(CuratorOctoFull.Length(self.list) / 4) do
		local v = 0
		for b = 0, 3 do
			local a = self.list[(i - 1) * 4 + b + 1]
			if a and earned[a.id] then
				v = v + 2 ^ b
			end
		end
		out[i] = string.format(("%x"), v)
	end
	return table.concat(out)
end

-- (1.9.0) The same bits six at a time (A-Z, a-z, 0-9, - and _: one letter for six achievements), for the
-- profile to stay within the length of a message with many more achievements.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local B64_OF = {}
for i = 1, 64 do
	B64_OF[string.sub(B64, i, i)] = i - 1
end

function AC:Bits64(earned)
	self:Build()
	local out = {}
	for i = 1, math.ceil(CuratorOctoFull.Length(self.list) / 6) do
		local v = 0
		for b = 0, 5 do
			local a = self.list[(i - 1) * 6 + b + 1]
			if a and earned[a.id] then
				v = v + 2 ^ b
			end
		end
		out[i] = string.sub(B64, v + 1, v + 1)
	end
	return table.concat(out)
end

-- The bits of a profile of 1.9.0 and later as those of before (4 a digit; nil: not such bits).
function AC.HexOf64(str)
	if type(str) ~= "string" or str == "" or CuratorOctoFull.Length(str) > 400 or not CuratorOctoFull.Match(str, "^[%w%-_]+$") then
		return nil
	end
	local bits = {}
	for k = 1, CuratorOctoFull.Length(str) do
		local v = B64_OF[string.sub(str, k, k)]
		for b = 0, 5 do
			bits[CuratorOctoFull.Length(bits) + 1] = CuratorOctoFull.Mod(math.floor(v / 2 ^ b) , 2)
		end
	end
	local out = {}
	for i = 1, math.ceil(CuratorOctoFull.Length(bits) / 4) do
		local v = 0
		for b = 0, 3 do
			v = v + (bits[(i - 1) * 4 + b + 1] or 0) * 2 ^ b
		end
		out[i] = string.format(("%x"), v)
	end
	return table.concat(out)
end

-- The set of ids earned of a bit field (the bits of achievements this version does not know are left).
function AC:FromBits(str)
	self:Build()
	local set = {}
	if type(str) ~= "string" then
		return set
	end
	for i, a in ipairs(self.list) do
		local k = math.floor((i - 1) / 4) + 1
		local digit = tonumber(string.sub(str, k, k), 16) or 0
		if CuratorOctoFull.Mod(math.floor(digit / 2 ^ (CuratorOctoFull.Mod((i - 1) , 4))) , 2) == 1 then
			set[a.id] = true
		end
	end
	return set
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
-- (1.9.0: a quest done, experience gained, a battleground over)
-- (1.14.0: the cases found, opened, appraised, their keys)
for _, e in ipairs({ "CHANGED", "CONTRACT_SIGNED", "CARD_FOUND", "PACK_EARNED", "SEEN", "QUEST_DONE", "XP_GAINED", "BG_DONE", "CASES_CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		if AC.ready then
			AC:Queue()
		end
	end)
end
ns.On("LOGIN", function()
	if not ns.db then
		return
	end
	AC.ready = true
	-- (1.5.0) the boosters of dungeons and raids opened, for the secret feat of the first one: not counted
	-- before; a card of a dungeon or a raid says one was opened
	local st = ns.Stats()
	if st.lairs == nil then
		st.lairs = 0
		for _, s in ipairs(ns.Series or {}) do
			if s.dungeon and (C:Progress(s)) > 0 then
				st.lairs = 1
				break
			end
		end
	end
	-- the first time: what was done before is earned without a word, then counted in one line
	if not ns.db.achInit then
		local new = AC:Check(true)
		ns.db.achInit, ns.db.ach150, ns.db.ach190 = true, true, true
		if CuratorOctoFull.Length(new) > 0 then
			local pts = 0
			for _, a in ipairs(new) do
				pts = pts + a.pts
			end
			ns.Print(L["%d achievements already earned (%d points). Type /curator achievements to see them."], CuratorOctoFull.Length(new), pts)
		end
	elseif not ns.db.ach150 then
		-- (1.5.0: the new achievements already reached are earned without a toast each, said in one line)
		local new = AC:Check(true)
		ns.db.ach150 = true
		if CuratorOctoFull.Length(new) > 0 then
			local pts = 0
			for _, a in ipairs(new) do
				pts = pts + a.pts
			end
			ns.Print(L["%d new achievements already earned (%d points). Type /curator achievements to see them."], CuratorOctoFull.Length(new), pts)
		end
	elseif not ns.db.ach190 then
		-- (1.9.0: the same for those of 1.9.0 already reached: the level, the boosters of the dungeons, the
		-- albums, the honorable kills and the trophies counted since 1.8.0)
		local new = AC:Check(true)
		ns.db.ach190 = true
		if CuratorOctoFull.Length(new) > 0 then
			local pts = 0
			for _, a in ipairs(new) do
				pts = pts + a.pts
			end
			ns.Print(L["%d new achievements already earned (%d points). Type /curator achievements to see them."], CuratorOctoFull.Length(new), pts)
		end
	else
		AC:Queue(2)
	end
end)

-- (31 October) The grades the expert told, by whole grade (a copy of a booster, a card of a case): the achievements of
-- the wear count only what an appraisal said.
local function GradeTold(g)
	g = math.floor(tonumber(g) or 0)
	if g < 1 or g > 10 or not ns.Stats then
		return
	end
	local st = ns.Stats()
	st.gtold = type(st.gtold) == "table" and st.gtold or {}
	st.gtold[g] = (tonumber(st.gtold[g]) or 0) + 1
end
ns.GradeTold = GradeTold
ns.On("CARD_APPRAISED", function(res)
	if type(res) == "table" then
		GradeTold(res.grade)
	end
end)
ns.On("CASE_APPRAISED", function(out)
	if type(out) == "table" then
		GradeTold(out.g)
	end
end)
