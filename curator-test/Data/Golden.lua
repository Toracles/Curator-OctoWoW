local _, ns = "Curator", CuratorOctoFull

-- (1.10.0) The golden quests: the leaders who give them, each in his capital (the card of his NPC is the
-- mythic card of its album), and his lands: the zones his quest sends to and the dungeons there, by the
-- keys of their albums. Where he stands: QuestieDB (Forever), the map of his city and x, y (0 to 1).
-- A zone counts for a tranche of levels when 3 of its levels at least fall in it (at the level 60: the
-- zones that go up to 58 or more), Golden.lua.
ns.GOLDEN_LEADERS = {
	{
		key = "thrall", npc = 4949, side = "Horde", home = "durotar", map = 1454, x = 0.3173, y = 0.3782,
		zones = { "barrens", "stonetalon", "ashenvale", "desolace", "dustwallow", "azshara", "felwood", "winterspring" },
		dungeons = { "ragefire", "wailing", "blackfathom", "razorfen", "maraudon" },
	},
	{
		key = "cairne", npc = 3057, side = "Horde", home = "mulgore", map = 1456, x = 0.6030, y = 0.5168,
		zones = { "barrens", "stonetalon", "needles", "desolace", "feralas", "tanaris", "ungoro", "silithus" },
		dungeons = { "wailing", "razorfen", "downs", "zulfarrak", "maraudon", "diremaul" },
	},
	{
		key = "sylvanas", npc = 10181, side = "Horde", home = "tirisfal", map = 1458, x = 0.5805, y = 0.9179,
		zones = { "silverpine", "hillsbrad", "alterac", "arathi", "stranglethorn", "swamp", "badlands", "hinterlands",
			"blasted", "burning", "westplague", "eastplague", "deadwind" },
		dungeons = { "lordaeron", "shadowfang", "scarlet", "dalaran", "uldaman", "sunken", "depths", "spire",
			"scholomance", "stratholme" },
	},
	{
		key = "bolvar", npc = 1748, side = "Alliance", home = "elwynn", map = 1453, x = 0.8021, y = 0.3835,
		zones = { "westfall", "redridge", "duskwood", "stranglethorn", "swamp", "blasted", "burning", "deadwind" },
		dungeons = { "deadmines", "stockade", "sunken", "depths", "spire" },
	},
	{
		key = "magni", npc = 2784, side = "Alliance", home = "dunmorogh", map = 1455, x = 0.3909, y = 0.5620,
		zones = { "lochmodan", "wetlands", "hillsbrad", "arathi", "alterac", "badlands", "hinterlands", "westplague",
			"eastplague" },
		dungeons = { "thanes", "excavation", "gnomeregan", "dalaran", "uldaman", "scholomance", "stratholme" },
	},
	{
		key = "tyrande", npc = 7999, side = "Alliance", home = "teldrassil", map = 1457, x = 0.3910, y = 0.8159,
		zones = { "darkshore", "stonetalon", "ashenvale", "needles", "desolace", "dustwallow", "feralas", "tanaris",
			"azshara", "ungoro", "felwood", "winterspring", "silithus" },
		dungeons = { "blackfathom", "maraudon", "zulfarrak", "diremaul" },
	},
}
