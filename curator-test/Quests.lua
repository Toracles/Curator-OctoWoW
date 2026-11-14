local _, ns = "Curator", CuratorOctoFull

-- The quests of the collector: ten of the day, five of the week and three of the month, then those of
-- the dungeons (two of the day, one of the week), of the raids (one of the week, one of the month) and
-- of PvP (five of the day, three of the week, two of the month). They are the account's, as the
-- collection: each one counts what any of its characters does (1.14.0, from the release of WoW Forever: but a
-- reroll, which does none and claims none, Reroll.lua: RR:Blocks), and they come for what those characters
-- can do (no dungeon before level 15, no raid before the highest level, no battleground before level 10,
-- no gathering without a gathering profession). (1.9.0) New ones come every day at 5:00 in Paris, the
-- week on Wednesday at 5:00, the month on its first day at 5:00: the same moment for every player. A
-- quest done waits for its rewards to be claimed: its experience, and points on the booster bar (the
-- quests of the day) or boosters to choose (of a zone, a dungeon or a raid). A quest done whose period
-- ends before its rewards are claimed gives them all the same. (1.9.0) Many more kinds of quests: the
-- creatures of a type, the elites, new cards, the inns, the contracts, and a whole war of PvP (the
-- battlegrounds one by one, the classes, the races and the ranks of the enemies, the trophies, the
-- exploits, the revenges, the war board, the front).
local Q = {}
ns.Quests = Q

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

function Q:Roll(n)
	return (self.random or math.random)(n)
end

-- The creature types a quest can ask for (their number in the data), their name, how common they are
-- (a part of the count of every creature) and the level of the account they wait for.
local CTYPES = {
	{ t = 1, name = "Beasts", k = 1 },
	{ t = 7, name = "Humanoids", k = 1 },
	{ t = 6, name = "Undead", k = 0.6, level = 15 },
	{ t = 4, name = "Elementals", k = 0.5, level = 20 },
	{ t = 3, name = "Demons", k = 0.35, level = 30 },
	{ t = 2, name = "Dragonkin", k = 0.3, level = 40 },
}
local CTYPE_BY = {}
for _, c in ipairs(CTYPES) do
	CTYPE_BY[c.t] = c
end
Q.CTYPES = CTYPES

-- The battlegrounds: their name, the level they open at.
local BGS = { { key = "wsg", name = "Warsong Gulch", level = 10 }, { key = "ab", name = "Arathi Basin", level = 20 }, { key = "av", name = "Alterac Valley", level = 51 } }
local BG_BY = {}
for _, b in ipairs(BGS) do
	BG_BY[b.key] = b
end

-- The rank of the enemies a quest asks, by its period.
local RANK = { day = 3, week = 6, month = 9 }

-- What a quest counts: its text (one: when the count is 1), its count for the day, the week, the
-- month, its icon, and whether the account can do it (can). arg: a quest of a kind among several (a type
-- of creature, a class, a race, a battleground, a rank), drawn when it comes. (1.4: the month asks 40
-- boosters opened, 30 before, and 50 earned, 35 before: the quests drawn from then on; those already
-- drawn keep theirs.)
local KINDS = {
	quest = { text = "Turn in %d quests", day = 5, week = 40, month = 150, icon = "Interface\\Icons\\INV_Misc_Note_01" },
	objective = { text = "Complete %d steps of quest objectives", day = 40, week = 350, month = 1300, icon = "Interface\\Icons\\INV_Misc_Map_01" },
	kill = { text = "Defeat %d creatures that give experience", day = 60, week = 700, month = 2500, icon = "Interface\\Icons\\INV_Sword_04" },
	profession = { text = "Gain %d points in your professions", day = 5, week = 25, month = 75, icon = "Interface\\Icons\\Trade_BlackSmithing", can = "CanRaiseSkill" },
	gather = { text = "Gather %d times: herbs, ore, skins or fish", day = 25, week = 220, month = 800, icon = "Interface\\Icons\\Trade_Herbalism", can = "CanGather" },
	open = { text = "Open %d boosters", day = 2, week = 18, month = 70, icon = { "Icon" } },
	earn = { text = "Earn %d boosters by playing", day = 2, week = 18, month = 70, icon = "Interface\\Icons\\INV_Misc_Bag_10" },
	find = { text = "Find %d cards on creatures", week = 4, month = 12, icon = "Interface\\Icons\\INV_Box_01" },
	dungeonBoss = { text = "Defeat %d dungeon bosses", day = 4, week = 30, icon = "Interface\\Icons\\Ability_Warrior_BattleShout" },
	dungeonDone = { text = "Complete %d dungeons", one = "Complete a dungeon", day = 1, week = 8, icon = "Interface\\Icons\\INV_Misc_Key_10" },
	-- (31 October, no more elites in the quests: in no board now; the quests drawn before count on)
	dungeonElite = { text = "Defeat %d elites in dungeons", day = 40, week = 200, icon = "Interface\\Icons\\Ability_Warrior_Cleave" },
	raidBoss = { text = "Defeat %d raid bosses", week = 10, month = 40, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
	raidDone = { text = "Complete %d raids", one = "Complete a raid", week = 2, month = 8, icon = "Interface\\Icons\\INV_Misc_Key_15" },
	hk = { text = "Earn %d honorable kills", day = 15, week = 250, month = 1000, icon = "Interface\\Icons\\Ability_DualWield" },
	bgWin = { text = "Win %d battlegrounds", one = "Win a battleground", day = 1, week = 10, month = 30, icon = "Interface\\Icons\\INV_BannerPVP_02" },
	bgPlay = { text = "Finish %d battlegrounds", day = 2, week = 18, month = 60, icon = "Interface\\Icons\\Ability_Parry" },
	-- (1.9.0) the world: the creatures of a type, the elites, the cards, the inns, the contracts
	-- (1.13.0: their texts say it, the creatures that give experience only, as everywhere in the world)
	ctype = { text = "Defeat %d creatures that give experience: %s", day = 30, week = 300, month = 1000, icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", arg = "CTypeArgs" },
	-- (31 October, his word: no more elites in the quests, the rares kept; the key stays, the quests drawn before count on)
	elite = { text = "Defeat %d rare creatures that give experience, in the world", one = "Defeat a rare creature that gives experience, in the world", week = 3, month = 10, icon = "Interface\\Icons\\Ability_Warrior_Cleave" },
	newcard = { text = "Add %d new cards to your albums", day = 3, week = 25, month = 90, icon = "Interface\\Icons\\INV_Misc_Book_09", can = "CanNewCards" },
	rare = { text = "Get %d cards of rare rarity or better", day = 2, week = 18, month = 60, icon = { "Gem3" } },
	-- (31 October) the week and the month asking more: epic cards and better, contracts that give one
	epic = { text = "Get %d cards of epic rarity or better", one = "Get a card of epic rarity or better", week = 2, month = 8, icon = { "Gem4" } },
	contractEpic = { text = "Sign %d exchange contracts that give a card of epic rarity or better", one = "Sign an exchange contract that gives a card of epic rarity or better", week = 2, month = 6, icon = "Interface\\Icons\\INV_Scroll_05", can = "CanContract" },
	forged = { text = "Get %d thunderforged or titanforged cards", one = "Get a thunderforged or titanforged card", week = 2, month = 6, icon = "Interface\\Icons\\Spell_Nature_Lightning" },
	contract = { text = "Sign %d exchange contracts", one = "Sign an exchange contract", day = 1, week = 6, month = 20, icon = "Interface\\Icons\\INV_Scroll_03", can = "CanContract" },
	stamp = { text = "Get %d stamps on your loyalty card", one = "Get a stamp on your loyalty card", day = 1, week = 5, month = 20, icon = "Interface\\Icons\\INV_Drink_04" },
	visa = { text = "Visit %d inns you have never been to", one = "Visit an inn you have never been to", week = 3, month = 8, icon = "Interface\\Icons\\INV_Misc_Map_01", can = "CanVisa" },
	bet = { text = "Play the innkeeper's bet %d times", one = "Play the innkeeper's bet", day = 1, week = 3, month = 10, icon = "Interface\\Icons\\INV_Misc_Coin_02", can = "CanBet" },
	xp = { text = "Earn %s experience of collector", num = true, day = 2000, week = 25000, month = 90000, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight" },
	explore = { text = "Discover %d new places", day = 3, week = 25, month = 70, icon = "Interface\\Icons\\INV_Misc_Spyglass_02", can = "CanExplore" },
	lairOpen = { text = "Open %d boosters of a dungeon or a raid", week = 6, month = 18, icon = "Interface\\Icons\\INV_Misc_Key_10", level = 15 },
	-- (1.9.0) PvP: the battlegrounds, the enemies, the trophies, the war board, the front
	bgWinIn = { text = "Win %d battles: %s", one = "Win a battle: %s", day = 1, week = 5, month = 15, icon = "Interface\\Icons\\INV_BannerPVP_01", arg = "BgArgs" },
	bgHk = { text = "Earn %d honorable kills in battlegrounds", day = 10, week = 150, month = 600, icon = "Interface\\Icons\\INV_Sword_27" },
	worldHk = { text = "Earn %d honorable kills outside battlegrounds", day = 5, week = 60, month = 250, icon = "Interface\\Icons\\Ability_Rogue_Ambush" },
	pvpClass = { text = "Defeat %d enemies: %s", day = 3, week = 30, month = 100, icon = "Interface\\Icons\\INV_Misc_Head_Human_02", arg = "ClassArgs" },
	pvpRace = { text = "Defeat %d enemies: %s", day = 3, week = 30, month = 100, icon = "Interface\\Icons\\INV_Misc_Head_Orc_01", arg = "RaceArgs" },
	pvpRank = { text = "Defeat %d enemies of rank %d or higher", day = 3, week = 15, month = 40, icon = "Interface\\Icons\\INV_Misc_Note_02", arg = "RankArgs" },
	pvp60 = { text = "Defeat %d enemies of level 60", day = 5, week = 60, month = 200, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Red", level = "max" },
	certify = { text = "Have %d trophies certified by a battlemaster", day = 5, week = 30, month = 120, icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" },
	combatant = { text = "Add %d new combatants to your PvP album", day = 2, week = 10, month = 30, icon = "Interface\\Icons\\INV_Misc_Book_11" },
	exploit = { text = "Achieve %d exploits in battlegrounds", one = "Achieve an exploit in a battleground", day = 1, week = 4, month = 12, icon = "Interface\\Icons\\INV_Misc_Rune_07" },
	revenge = { text = "Take %d revenges", one = "Take a revenge", day = 1, week = 3, month = 8, icon = "Interface\\Icons\\Ability_Warrior_Revenge" },
	bounty = { text = "Claim %d bounties of the war board", one = "Claim a bounty of the war board", week = 2, month = 6, icon = "Interface\\Icons\\INV_Misc_Note_02" },
	pay = { text = "Collect your pay of the week", week = 1, icon = "Interface\\Icons\\INV_Misc_Coin_01" },
	wanted = { text = "Bring down the enemy of the wanted poster", month = 1, icon = "Interface\\Icons\\INV_Misc_Head_Human_01" },
	head = { text = "Bring down %d heads with a price", one = "Bring down a head with a price", week = 1, month = 3, icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", can = "CanHead" },
	-- (1.12.0) Hallow's End, while it lasts (its page: UI/HallowPage.lua): a treat, its creatures, the undead, its
	-- boosters, its cards, those found on their creatures, the corrupted ones
	hallowTreat = { text = "Trick or treat at an innkeeper", day = 1, icon = "Interface\\Icons\\INV_Misc_Bag_28_Halloween" },
	hallowKill = { text = "Defeat %d creatures of the night that give experience (those of the album of Hallow's End)", day = 12, week = 70, icon = "Interface\\Icons\\Spell_Shadow_RaiseDead" },
	hallowUndead = { text = "Defeat %d undead that give experience", day = 25, week = 140, icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", level = 15 },
	hallowOpen = { text = "Open %d boosters of Hallow's End", one = "Open a booster of Hallow's End", day = 1, week = 6, icon = { "Icon" } },
	hallowCards = { text = "Add %d cards of Hallow's End to your collection", day = 5, week = 30, icon = "Interface\\Icons\\INV_Misc_Book_09" },
	hallowFind = { text = "Find %d cards of Hallow's End on their creatures", one = "Find a card of Hallow's End on its creature", week = 1, icon = "Interface\\Icons\\INV_Box_01" },
	hallowCorrupt = { text = "Get %d corrupted cards", one = "Get a corrupted card", week = 2, icon = { "GemCorrupt" } },
	-- (1.14.0, after the test of the cases, his word) The discovery of the Paladin Collection Case No. 1 (Discovery.lua, its
	-- page UI/DiscoveryPage.lua): the spells of the paladins (spells: their group in Discovery.lua, their icon that of its
	-- first spell; a paladin of the account who knows one; names: their names in its text as the client has them, {spell},
	-- and its count, {n}), the deeds of a paladin played (pal: the level of a paladin of the account), and for every class
	-- the undead, the dungeons of the Light, the fallen raised, the cases.
	-- (31 October, his word: every quest of the week asks more: their counts of the week about 1.6 times those of before)
	palLight = { text = "Cast {spell} {n} times", names = true, day = 15, week = 130, can = "CanPal", spells = "light" },
	palFlash = { text = "Cast {spell} {n} times", names = true, day = 20, week = 160, can = "CanPal", spells = "flash" },
	palJudge = { text = "Cast {spell} {n} times", names = true, day = 15, week = 130, can = "CanPal", spells = "judge" },
	palSeal = { text = "Call upon a seal %d times", day = 20, week = 160, can = "CanPal", spells = "seal" },
	palHammer = { text = "Stun {n} enemies with {spell}", names = true, day = 6, week = 50, can = "CanPal", spells = "hammer" },
	palExorcism = { text = "Cast {spell} {n} times", names = true, day = 10, week = 80, can = "CanPal", spells = "exorcism" },
	palTurn = { text = "Cast {spell} {n} times", names = true, day = 3, week = 20, can = "CanPal", spells = "turn" },
	palPurify = { text = "Cast {spell} {n} times", names = true, day = 5, week = 40, can = "CanPal", spells = "purify" },
	palHands = { text = "Use {spell} {n} times", one = "Use {spell}", names = true, day = 1, week = 6, can = "CanPal", spells = "hands" },
	palShield = { text = "Call upon {spell} {n} times", names = true, day = 3, week = 25, can = "CanPal", spells = "shield" },
	palBless = { text = "Cast %d blessings", day = 10, week = 95, can = "CanPal", spells = "bless" },
	palProtect = { text = "Cast {spell} {n} times", names = true, day = 2, week = 15, can = "CanPal", spells = "protect" },
	palWrath = { text = "Cast {spell} {n} times", names = true, day = 5, week = 40, can = "CanPal", spells = "wrath" },
	palHolyWrath = { text = "Cast {spell} {n} times", names = true, day = 4, week = 30, can = "CanPal", spells = "holywrath" },
	palConsecrate = { text = "Cast {spell} {n} times", names = true, day = 10, week = 80, can = "CanPal", spells = "consecrate" },
	palShock = { text = "Cast {spell} {n} times", names = true, day = 8, week = 65, can = "CanPal", spells = "shock" },
	palHolyShield = { text = "Raise {spell} {n} times", names = true, day = 10, week = 80, can = "CanPal", spells = "holyshield" },
	palSteed = { text = "Summon your steed of the Light %d times", day = 2, week = 15, can = "CanPal", spells = "steed" },
	palRedeem = { text = "Bring {n} fallen allies back with {spell}", one = "Bring a fallen ally back with {spell}", names = true, day = 1, week = 8, can = "CanPal", spells = "redeem" },
	palKill = { text = "Defeat %d creatures that give experience with a paladin", day = 60, week = 560, can = "CanPal", pal = 1, icon = "Interface\\Icons\\Spell_Holy_SealOfWrath" },
	palUndead = { text = "Defeat %d undead that give experience with a paladin", day = 25, week = 225, can = "CanPal", pal = 15, icon = "Interface\\Icons\\Spell_Holy_SenseUndead" },
	palDemon = { text = "Defeat %d demons that give experience with a paladin", day = 15, week = 130, can = "CanPal", pal = 30, icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
	palElite = { text = "Defeat %d rare creatures with a paladin, in the world", one = "Defeat a rare creature with a paladin, in the world", week = 3, can = "CanPal", pal = 10, icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
	palQuest = { text = "Turn in %d quests with a paladin", day = 5, week = 40, can = "CanPal", pal = 1, icon = "Interface\\Icons\\INV_Misc_Note_01" },
	palBoss = { text = "Defeat %d dungeon bosses with a paladin", day = 4, week = 30, can = "CanPal", pal = 15, icon = "Interface\\Icons\\Ability_Warrior_BattleShout" },
	palDungeon = { text = "Complete %d dungeons with a paladin", one = "Complete a dungeon with a paladin", day = 1, week = 6, can = "CanPal", pal = 15, icon = "Interface\\Icons\\INV_Misc_Key_10" },
	scourge = { text = "Defeat %d undead that give experience", day = 25, week = 225, level = 15, icon = "Interface\\Icons\\Spell_Shadow_AnimateDead" },
	lightBoss = { text = "Defeat {n} bosses in these dungeons: {places}", places = true, day = 3, week = 25, level = 30, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
	lightDone = { text = "Complete one of these dungeons {n} times: {places}", one = "Complete one of these dungeons: {places}", places = true, day = 1, week = 5, level = 30, icon = "Interface\\Icons\\INV_Misc_Key_15" },
	rez = { text = "Bring %d fallen allies back to life", one = "Bring a fallen ally back to life", day = 2, week = 15, can = "CanRez", spells = "rez" },
	caseFind = { text = "Find %d cases", one = "Find a case", day = 1, week = 6, icon = "Interface\\Icons\\INV_Box_01" },
	caseOpen = { text = "Open %d cases", one = "Open a case", week = 3, icon = "Interface\\Icons\\INV_Misc_Key_03" },
	caseAppraise = { text = "Have %d cards of a case appraised at a banker", one = "Have a card of a case appraised at a banker", week = 2, can = "CanAppraiseCase", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
}
Q.KINDS = KINDS

-- The boards: their section and their period, how many quests, among which, their rewards (XP for
-- each quest, its points on the booster bar, its boosters to choose and their kind), and the level a
-- character of the account needs (raids: the highest level of the game). (The professions no longer
-- give boosters, 1.2: no more quests of professions.) (1.9.0: ten of the day, five of the week, three
-- of the month; PvP: five, three, two, with boosters too.)
-- (31 October, his word: the elites gone from the quests, the rares of the world kept for the week and the month; the week
-- and the month asking far more, their counts about twice those of before, with epic cards and the contracts that give one)
local GENERAL_DAY = { "quest", "objective", "kill", "gather", "open", "earn", "ctype", "newcard", "rare", "contract", "stamp", "bet", "xp", "explore" }
local GENERAL = { "quest", "objective", "kill", "gather", "open", "earn", "find", "ctype", "elite", "newcard", "rare", "epic", "forged",
	"contract", "contractEpic", "stamp", "visa", "bet", "xp", "explore", "lairOpen" }
-- (1.14.0, his word: the PvP gone until its rework, its quests stay: the honorable kills, the battlegrounds, the enemies;
-- those of the trophies, the combatants, the exploits, the revenges, the war board and the front gone with it)
local PVP = { "hk", "bgWin", "bgPlay", "bgWinIn", "bgHk", "worldHk", "pvpClass", "pvpRace", "pvpRank", "pvp60" }
-- (1.12.0) Hallow's End: three quests of the day and one of the week, each with boosters of its album (event: open only
-- while the event lasts)
local HALLOW_DAY = { "hallowTreat", "hallowKill", "hallowUndead", "hallowOpen", "hallowCards", "stamp", "bet" }
local HALLOW_WEEK = { "hallowKill", "hallowUndead", "hallowOpen", "hallowCards", "hallowFind", "hallowCorrupt" }
-- (1.12.0, later) Generous, the beta of WoW Forever ending on October 21 in the middle of it: each quest claimed gives
-- way to another (chain: so many quests in a period at most, those shown first included), drawn from more (what can be
-- done again the same day: not the treat, nor the stamp, nor the bet); two boosters for a quest of the day, five for
-- one of the week.
local HALLOW_MORE = { "hallowKill", "hallowUndead", "hallowOpen", "hallowCards", "quest", "objective", "kill", "gather", "earn", "elite", "ctype", "explore", "xp" }
Q.HALLOW = { day = HALLOW_DAY, week = HALLOW_WEEK, more = HALLOW_MORE }
-- (1.14.0, after the test of the cases, his word) The discovery of the Paladin Collection Case No. 1: four quests of the day
-- and two of the week, half of them of the paladins (PAL: the first of each two), half of them those of every day; a case
-- of the collection each (cases), its experience, its rubies. Each one claimed gives way to another of its half (chain:
-- so many in a period at most).
local PAL = { "palLight", "palFlash", "palJudge", "palSeal", "palHammer", "palExorcism", "palTurn", "palPurify", "palHands",
	"palShield", "palBless", "palProtect", "palWrath", "palHolyWrath", "palConsecrate", "palShock", "palHolyShield", "palSteed",
	"palRedeem", "palKill", "palUndead", "palDemon", "palElite", "palQuest", "palBoss", "palDungeon", "scourge", "lightBoss",
	"lightDone", "rez", "caseFind" }
local PAL_WEEK = {}
for _, k in ipairs(PAL) do
	PAL_WEEK[CuratorOctoFull.Length(PAL_WEEK) + 1] = k
end
PAL_WEEK[CuratorOctoFull.Length(PAL_WEEK) + 1] = "caseOpen"
PAL_WEEK[CuratorOctoFull.Length(PAL_WEEK) + 1] = "caseAppraise"
-- (1.11.0) and its rubies (Rubies.lua). (1.13.0, after its second test: the economy redone around the display of a zone, the
-- purchase of a week for a player of 3 to 5 hours a day: eight times as many for a quest of the day, ten times for the others;
-- 10, 60, 250, 15, 100, 150, 500 before. The quests drawn before keep nothing of the old values: Q.OLD_RUBIES.)
local BOARDS = {
	{ key = "daily", section = "general", period = "day", count = 10, pool = GENERAL_DAY, xp = 200, pts = 25, packs = 0, kind = "zone", rubies = 80 },
	{ key = "weekly", section = "general", period = "week", count = 5, pool = GENERAL, xp = 1200, packs = 1, kind = "zone", rubies = 600 },
	{ key = "monthly", section = "general", period = "month", count = 3, pool = GENERAL, xp = 6000, packs = 3, kind = "zone", rubies = 2500 },
	{ key = "dungeonDaily", section = "dungeon", period = "day", count = 2, pool = { "dungeonBoss", "dungeonDone" }, xp = 500, pts = 50, packs = 0, kind = "dungeon", level = 15, rubies = 120 },
	{ key = "dungeonWeekly", section = "dungeon", period = "week", count = 1, pool = { "dungeonBoss", "dungeonDone" }, xp = 3000, packs = 1, kind = "dungeon", level = 15, rubies = 1000 },
	{ key = "raidWeekly", section = "raid", period = "week", count = 1, pool = { "raidBoss", "raidDone" }, xp = 4000, packs = 1, kind = "raid", level = "max", rubies = 1500 },
	{ key = "raidMonthly", section = "raid", period = "month", count = 1, pool = { "raidBoss", "raidDone" }, xp = 15000, packs = 2, kind = "raid", level = "max", rubies = 5000 },
	{ key = "pvpDaily", section = "pvp", period = "day", count = 5, pool = PVP, xp = 400, pts = 25, packs = 0, kind = "zone", level = 10, rubies = 80 },
	{ key = "pvpWeekly", section = "pvp", period = "week", count = 3, pool = PVP, xp = 2500, packs = 1, kind = "zone", level = 10, rubies = 600 },
	{ key = "pvpMonthly", section = "pvp", period = "month", count = 2, pool = PVP, xp = 8000, packs = 2, kind = "zone", level = 10, rubies = 2500 },
	-- (1.14.0, after the test of the cases, his word: Hallow's End out of the tabs, its quests gone with it; the discovery of
	-- the Paladin Collection Case No. 1 in its place, Discovery.lua)
	{ key = "palDaily", section = "discovery", period = "day", count = 4, half = { PAL, GENERAL_DAY }, xp = 300, rubies = 80, cases = 1, case = "paladin1", event = "paladin", chain = 8 },
	{ key = "palWeekly", section = "discovery", period = "week", count = 2, half = { PAL_WEEK, GENERAL }, xp = 2500, rubies = 600, cases = 1, case = "paladin1", event = "paladin", chain = 4 },
}
-- (a board of halves: every kind of both, for what reads the pool of a board)
for _, b in ipairs(BOARDS) do
	if b.half and not b.pool then
		local all, seen = {}, {}
		for _, h in ipairs(b.half) do
			for _, k in ipairs(h) do
				if not seen[k] then
					seen[k] = true
					all[CuratorOctoFull.Length(all) + 1] = k
				end
			end
		end
		b.pool = all
	end
end
Q.BOARDS = BOARDS
-- (1.13.0, after its second test) the rubies a quest of each board had before: a quest drawn then and not claimed yet gets
-- those of now (Q:MendRubies, once)
Q.OLD_RUBIES = { daily = 10, weekly = 60, monthly = 250, dungeonDaily = 15, dungeonWeekly = 100, raidWeekly = 150, raidMonthly = 500,
	pvpDaily = 10, pvpWeekly = 60, pvpMonthly = 250, hallowDaily = 10, hallowWeekly = 60 }
Q.byKey = {}
for _, b in ipairs(BOARDS) do
	Q.byKey[b.key] = b
end
-- the sections, as the page shows them (and the track of the rewards of the levels)
Q.SECTIONS = {
	{ key = "daily", boards = { "daily" }, label = "Daily" },
	{ key = "weekly", boards = { "weekly" }, label = "Weekly" },
	{ key = "monthly", boards = { "monthly" }, label = "Monthly" },
	{ key = "dungeon", boards = { "dungeonDaily", "dungeonWeekly" }, label = "Dungeons" },
	{ key = "raid", boards = { "raidWeekly", "raidMonthly" }, label = "Raids" },
	{ key = "pvp", boards = { "pvpDaily", "pvpWeekly", "pvpMonthly" }, label = "PvP" },
}

-------------------------------------------------------------------------------
-- The periods of the server: its day and its week (to its resets), the month of its calendar (what the
-- week of PvP, of the front and of the talents follow)
-------------------------------------------------------------------------------
local SPAN = { day = 86400, week = 604800 }
local UNTIL = { day = "GetSecondsUntilDailyReset", week = "GetSecondsUntilWeeklyReset" }

-- The seconds to the reset of the server that ends a day or a week. False: the client cannot tell
-- (the clock tells it then); nil: it cannot tell yet (a value out of reason, as some clients give
-- at their first login).
local function Until(period)
	local D = C_DateAndTime
	local fn = UNTIL[period]
	if not (D and D[fn]) then
		return false
	end
	local ok, left = pcall(D[fn])
	if ok and type(left) == "number" and not Secret(left) and left > 0 and left <= SPAN[period] then
		return left
	end
	return nil
end

-- The date of the server: its calendar (nil while it is not known: some clients give the year 1999
-- at their first login), else the clock of the client.
function Q:Calendar()
	local D = C_DateAndTime
	if D and D.GetCurrentCalendarTime then
		local ok, t = pcall(D.GetCurrentCalendarTime)
		if ok and type(t) == "table" and type(t.year) == "number" and type(t.month) == "number" and not Secret(t.year) and not Secret(t.month)
			and t.year >= 2004 and t.month >= 1 and t.month <= 12 and (tonumber(t.monthDay) or 1) >= 1 then
			return t
		end
		return nil
	end
	local t = date("*t", CuratorOctoFull.ServerTime())
	return { year = t.year, month = t.month, monthDay = t.day, hour = t.hour, minute = t.min }
end

local function DaysIn(year, month)
	if month == 2 then
		return (CuratorOctoFull.Mod(year , 4) == 0 and (CuratorOctoFull.Mod(year , 100) ~= 0 or CuratorOctoFull.Mod(year , 400) == 0)) and 29 or 28
	end
	return (month == 4 or month == 6 or month == 9 or month == 11) and 30 or 31
end

-- The seconds left until the period of the server ends (nil: not known yet).
function Q:Left(period)
	if period == "month" then
		local t = self:Calendar()
		if not t then
			return nil
		end
		local days = DaysIn(t.year, t.month) - (tonumber(t.monthDay) or 1)
		return days * 86400 + (23 - (tonumber(t.hour) or 0)) * 3600 + (60 - (tonumber(t.minute) or 0)) * 60
	end
	local left = Until(period)
	if left == false then
		local now = CuratorOctoFull.ServerTime()
		return (math.floor(now / SPAN[period]) + 1) * SPAN[period] - now
	end
	return left
end

-- The key of the period of the server we are in: when it ends for a day or a week (in seconds), its
-- month for a month (year * 12 + month). Nil: not known yet.
function Q:Key(period)
	if period == "month" then
		local t = self:Calendar()
		return t and (t.year * 12 + t.month) or nil
	end
	local left = self:Left(period)
	return left and (CuratorOctoFull.ServerTime() + left) or nil
end

-------------------------------------------------------------------------------
-- (1.9.0) The resets of the quests: every day at 5:00 in Paris, the week on Wednesday at 5:00, the month
-- on its first day at 5:00. The time of Paris: UTC+1, UTC+2 from the last Sunday of March to the last
-- Sunday of October (at 1:00 UTC). From the clock of the server (GetServerTime: UTC), the same for all.
-------------------------------------------------------------------------------
local RESET = 5 * 3600

-- The days since 1970-01-01 of a date, and back (the calendar of the proleptic Gregorian).
local function DaysFromCivil(y, m, d)
	y = (m <= 2) and (y - 1) or y
	local era = math.floor(y / 400)
	local yoe = y - era * 400
	local mp = CuratorOctoFull.Mod((m + 9) , 12)
	local doy = math.floor((153 * mp + 2) / 5) + d - 1
	local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end
local function CivilFromDays(z)
	z = z + 719468
	local era = math.floor(z / 146097)
	local doe = z - era * 146097
	local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
	local y = yoe + era * 400
	local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local d = doy - math.floor((153 * mp + 2) / 5) + 1
	local m = mp < 10 and (mp + 3) or (mp - 9)
	return (m <= 2) and (y + 1) or y, m, d
end
Q.DaysFromCivil, Q.CivilFromDays = DaysFromCivil, CivilFromDays

-- The offset of the time of Paris from UTC at a moment (in seconds).
function Q.ParisOffset(utc)
	local y = CivilFromDays(math.floor(utc / 86400))
	local function LastSunday(month)
		local last = DaysFromCivil(y, month, DaysIn(y, month))
		return last - CuratorOctoFull.Mod((last + 4) , 7)
	end
	local from = LastSunday(3) * 86400 + 3600
	local to = LastSunday(10) * 86400 + 3600
	return (utc >= from and utc < to) and 7200 or 3600
end

-- The moment (UTC) of a time of Paris (5:00 never falls in the hour the clocks change).
local function FromParis(lp)
	local u = lp - 3600
	if Q.ParisOffset(u) == 3600 then
		return u
	end
	return lp - 7200
end

-- The quests' period we are in at a moment (UTC; now by default): when it ends (UTC), and its key (the end
-- for a day and a week, year * 12 + month for a month).
function Q:ResetPeriod(period, utc)
	utc = utc or CuratorOctoFull.ServerTime()
	local lp = utc + self.ParisOffset(utc) - RESET
	local day = math.floor(lp / 86400)
	if period == "day" then
		local e = FromParis((day + 1) * 86400 + RESET)
		return e, e
	elseif period == "week" then
		-- (1970-01-01 was a Thursday: the weeks begin on Wednesdays, the day 6 and every 7 days)
		local week = math.floor((day + 1) / 7)
		local e = FromParis(((week + 1) * 7 - 1) * 86400 + RESET)
		return e, e
	end
	local y, m = CivilFromDays(day)
	local ny, nm = (m == 12) and (y + 1) or y, (m == 12) and 1 or (m + 1)
	return FromParis(DaysFromCivil(ny, nm, 1) * 86400 + RESET), y * 12 + m
end

-- The seconds left until the quests of a period change.
function Q:ResetLeft(period)
	local now = CuratorOctoFull.ServerTime()
	return math.max(1, (self:ResetPeriod(period, now)) - now)
end

-- The key of the quests' period we are in.
function Q:ResetKey(period)
	return CuratorOctoFull.Select(2, self:ResetPeriod(period))
end

-- A period after the one of the quests kept (a key further on; for a day or a week, by more than half
-- of one: the same end told a few seconds or an hour apart is the same period).
local function Newer(period, key, old)
	if type(old) ~= "number" then
		return true
	end
	if period == "month" then
		return key > old
	end
	return key > old + SPAN[period] / 2
end

-------------------------------------------------------------------------------
-- What the account can do: its characters
-------------------------------------------------------------------------------
-- The highest level among the characters of the account.
function Q:AccountLevel()
	local best = (UnitLevel and UnitLevel("player")) or 1
	if type(best) ~= "number" or Secret(best) then
		best = 1
	end
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		if type(c.level) == "number" and c.level > best then
			best = c.level
		end
	end
	return best
end

function Q:MaxLevel()
	return (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 60
end

-- The level a board (or a kind of quest) asks of a character of the account (nil: none).
function Q:Needs(board)
	if board.level == "max" then
		return self:MaxLevel()
	end
	return board.level
end

-- (1.12.0) Whether an event lasts now: Hallow's End (Hallow.lua); (1.14.0) the discovery of the Paladin Collection
-- Case No. 1 (Discovery.lua).
function Q:EventOn(event)
	if event == "hallow" then
		return ns.Hallow ~= nil and ns.Hallow:On()
	elseif event == "paladin" then
		return ns.Discovery ~= nil and ns.Discovery:On()
	end
	return false
end

function Q:Open(board)
	-- (1.12.0: the quests of an event, while it lasts)
	if board.event and not self:EventOn(board.event) then
		return false
	end
	local need = self:Needs(board)
	return not need or self:AccountLevel() >= need
end

-- (1.14.0) The quests of the discovery of the Paladin Collection Case No. 1 (Discovery.lua): a paladin of the account
-- who knows the spell, or of the level; a character of the account who raises the fallen; a card of a case not appraised.
function Q:CanPal(kind)
	return ns.Discovery ~= nil and ns.Discovery:CanPal(kind)
end

function Q:CanRez()
	return ns.Discovery ~= nil and ns.Discovery:CanRez()
end

function Q:CanAppraiseCase()
	local CS = ns.Cases
	if not (CS and CS.Won) then
		return false
	end
	for _, w in ipairs(CS:Won() or {}) do
		if type(w) == "table" and not w.ap then
			return true
		end
	end
	return false
end

-- A profession can still rise: one known below its highest rank, or a secondary one (cooking, first
-- aid, fishing) a character does not have.
local SECONDARY = { 185, 129, 356 }
function Q:CanRaiseSkill()
	local any = false
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		if c.skillsInit then
			any = true
			for _, rank in pairs(c.skills or {}) do
				if rank < 300 then
					return true
				end
			end
			for _, id in ipairs(SECONDARY) do
				if not (c.skills or {})[id] then
					return true
				end
			end
		end
	end
	-- (no character seen yet: it can)
	return not any
end

-- A character of the account gathers: herbalism, mining, skinning or fishing.
local GATHER_SKILLS = { 182, 186, 393, 356 }
function Q:CanGather()
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		for _, id in ipairs(GATHER_SKILLS) do
			if (c.skills or {})[id] then
				return true
			end
		end
	end
	return false
end

-- (1.9.0) Cards still missing from the albums.
function Q:CanNewCards()
	local C = ns.Collection
	if not (C and C.Overall) then
		return true
	end
	local owned, total = C:Overall()
	return (owned or 0) < (total or 1)
end

-- Copies to spare for a contract (of some rarity, normal ones).
function Q:CanContract()
	local K = ns.Contract
	if not (K and K.SpareByRarity) then
		return true
	end
	local spare = K:SpareByRarity("normal", true)
	for r = 1, CuratorOctoFull.Length(ns.RARITY) - 1 do
		if (spare[r] or 0) >= (K.SIZE or 10) then
			return true
		end
	end
	return false
end

-- Inns never visited (enough for the quest's count, checked as it is drawn).
function Q:CanVisa()
	local I = ns.Inns
	if not (I and I.AllCount and I.VisaCount) then
		return false
	end
	local _, known = I:VisaCount()
	return I:AllCount() - known >= 5
end

-- A duplicate to bet.
function Q:CanBet()
	local T = ns.Tavern
	if not (T and T.Stakes) then
		return false
	end
	for r = 1, T.BET_TOP or 5 do
		if CuratorOctoFull.Length(T:Stakes(r)) > 0 then
			return true
		end
	end
	return false
end

-- Places still to discover: a character of the account below the highest level.
function Q:CanExplore()
	local max = self:MaxLevel()
	local low = (UnitLevel and UnitLevel("player")) or max
	if type(low) == "number" and not Secret(low) and low < max then
		return true
	end
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		if type(c.level) == "number" and c.level < max then
			return true
		end
	end
	return false
end

-- Heads with a price this week (the news of the front: the app of Curator brings them).
function Q:CanHead()
	local F = ns.Front
	if not (F and F.Heads) then
		return false
	end
	local ok, heads = pcall(F.Heads, F)
	return ok and type(heads) == "table" and CuratorOctoFull.Length(heads) > 0
end

-- The factions of the account's characters (the one played now, else the Alliance), and their enemies.
function Q:Factions()
	local set = {}
	for _, c in pairs((ns.db and ns.db.chars) or {}) do
		if c.faction == "Alliance" or c.faction == "Horde" then
			set[c.faction] = true
		end
	end
	local me = UnitFactionGroup and UnitFactionGroup("player")
	if me == "Alliance" or me == "Horde" then
		set[me] = true
	end
	if not next(set) then
		set.Alliance = true
	end
	return set
end

function Q:EnemyFactions()
	local out = {}
	for f in pairs(self:Factions()) do
		out[CuratorOctoFull.Length(out) + 1] = (f == "Alliance") and "Horde" or "Alliance"
	end
	table.sort(out)
	return out
end

-------------------------------------------------------------------------------
-- The quests of a kind among several: their choices ({ a, k: its count a part of the kind's })
-------------------------------------------------------------------------------
function Q:CTypeArgs()
	local level, out = self:AccountLevel(), {}
	for _, c in ipairs(CTYPES) do
		if not c.level or level >= c.level then
			out[CuratorOctoFull.Length(out) + 1] = { a = c.t, k = c.k }
		end
	end
	return out
end

function Q:BgArgs()
	local level, out = self:AccountLevel(), {}
	for _, b in ipairs(BGS) do
		if level >= b.level then
			out[CuratorOctoFull.Length(out) + 1] = { a = b.key }
		end
	end
	return out
end

function Q:ClassArgs()
	local P, seen, out = ns.Pvp, {}, {}
	for _, f in ipairs(self:EnemyFactions()) do
		for _, classes in pairs((P and P.RACE_CLASSES and P.RACE_CLASSES[f]) or {}) do
			for _, cls in ipairs(classes) do
				if not seen[cls] then
					seen[cls] = true
					out[CuratorOctoFull.Length(out) + 1] = { a = cls }
				end
			end
		end
	end
	table.sort(out, function(x, y)
		return x.a < y.a
	end)
	return out
end

function Q:RaceArgs()
	local P, seen, out = ns.Pvp, {}, {}
	for _, f in ipairs(self:EnemyFactions()) do
		for race in pairs((P and P.RACE_CLASSES and P.RACE_CLASSES[f]) or {}) do
			if not seen[race] then
				seen[race] = true
				out[CuratorOctoFull.Length(out) + 1] = { a = race }
			end
		end
	end
	table.sort(out, function(x, y)
		return x.a < y.a
	end)
	return out
end

function Q:RankArgs(period)
	return { { a = RANK[period] or 3 } }
end

-- The name of what a quest of a kind among several asks.
function Q:ArgName(q)
	local L, a = ns.L, q.a
	if q.k == "ctype" then
		local c = CTYPE_BY[a]
		return c and L[c.name] or "?"
	elseif q.k == "bgWinIn" then
		local b = BG_BY[a]
		return b and L[b.name] or "?"
	elseif q.k == "pvpClass" then
		return (ns.Pvp and ns.Pvp:ClassName(a)) or "?"
	elseif q.k == "pvpRace" then
		return (ns.Pvp and ns.Pvp:RaceName(a)) or "?"
	end
	return tostring(a or "?")
end

-------------------------------------------------------------------------------
-- The boards, their quests
-------------------------------------------------------------------------------
-- The count a quest of a kind asks in a period.
function Q:Goal(kind, period)
	local k = KINDS[kind]
	return k and k[period]
end

-- Its text: "Defeat 60 creatures that give experience", "Defeat 30 creatures: Beasts".
function Q:Text(q)
	local L = ns.L
	local k = KINDS[q.k]
	if not k then
		return "?"
	end
	-- (1.14.0: a quest of the spells of the paladins, their names as the client has them; of the dungeons of the Light,
	-- the names of their albums; Discovery.lua)
	if k.names or k.places then
		local D = ns.Discovery
		local t = (q.n == 1 and k.one) and L[k.one] or L[k.text]
		t = string.gsub(t, "{n}", function()
			return ns.Num(q.n)
		end)
		t = string.gsub(t, "{spell}", function()
			return (D and D:SpellText(k.spells)) or "?"
		end)
		t = string.gsub(t, "{places}", function()
			return (D and D:LightText()) or "?"
		end)
		return t
	end
	if q.k == "pvpRank" then
		return string.format(L[k.text], q.n, tonumber(q.a) or 0)
	end
	if k.arg then
		if q.n == 1 and k.one then
			return string.format(L[k.one], self:ArgName(q))
		end
		return string.format(L[k.text], q.n, self:ArgName(q))
	end
	if q.n == 1 and k.one then
		return L[k.one]
	end
	if k.num then
		-- (a big count: its thousands apart)
		return string.format(L[k.text], ns.Num(q.n))
	end
	if not string.find(k.text, "%%d") then
		return L[k.text]
	end
	return string.format(L[k.text], q.n)
end

-- The count of a kind among several: a part of the kind's (by fives past ten).
local function Scaled(n, k)
	if not k or k == 1 then
		return n
	end
	local x = n * k
	if x >= 10 then
		return math.max(5, math.floor(x / 5 + 0.5) * 5)
	end
	return math.max(1, math.floor(x + 0.5))
end

-- The kinds of a board the account can do now, but those already there (have: the kinds of its quests).
function Q:Pool(board, have)
	local pool = {}
	for _, kind in ipairs(board.pool) do
		local k = KINDS[kind]
		if k[board.period] and not (have and have[kind]) and (not k.can or self[k.can](self, kind))
			and (not k.level or self:Open(k)) and (not k.arg or CuratorOctoFull.Length(self[k.arg](self, board.period)) > 0) then
			pool[CuratorOctoFull.Length(pool) + 1] = kind
		end
	end
	return pool
end

-- A quest of a kind for a board. (1.14.0: c, the cases of the discovery it gives.)
function Q:Make(board, kind)
	local k = KINDS[kind]
	local n, a = k[board.period], nil
	if k.arg then
		local args = self[k.arg](self, board.period)
		local x = args[self:Roll(CuratorOctoFull.Length(args))]
		a = x.a
		n = Scaled(n, x.k)
	end
	return { k = kind, a = a, n = n, got = 0, xp = board.xp, p = board.packs, pts = board.pts, r = board.rubies, c = board.cases }
end

-- (1.14.0) The half of a board of halves a kind is of (1: the first; nil: none).
function Q:HalfOf(board, kind)
	for i, h in ipairs(board.half or {}) do
		for _, k in ipairs(h) do
			if k == kind then
				return i
			end
		end
	end
	return nil
end

-- Quests drawn from the pool into a list, up to the count of the board. (1.14.0: a board of halves, a quest of each
-- half in turn, the first half first; a half with nothing more to give leaves its places to the other.)
function Q:Fill(board, list)
	local have = {}
	for _, q in ipairs(list) do
		have[q.k] = true
	end
	if board.half then
		local pools, used, count = {}, {}, {}
		for i, h in ipairs(board.half) do
			pools[i] = self:Pool({ pool = h, period = board.period }, have)
			used[i], count[i] = 0, 0
		end
		for _, q in ipairs(list) do
			local i = self:HalfOf(board, q.k)
			if i then
				count[i] = count[i] + 1
			end
		end
		while CuratorOctoFull.Length(list) < board.count do
			-- (the half with the fewest quests, the first one when even; one with nothing more: the other)
			local pick
			for i = 1, CuratorOctoFull.Length(pools) do
				if used[i] < CuratorOctoFull.Length(pools[i]) and (not pick or count[i] < count[pick]) then
					pick = i
				end
			end
			if not pick then
				break
			end
			local pool = pools[pick]
			local i = used[pick] + 1
			local j = self:Roll(CuratorOctoFull.Length(pool) - i + 1) + i - 1
			pool[i], pool[j] = pool[j], pool[i]
			used[pick] = i
			-- (a kind of both halves: once)
			if not have[pool[i]] then
				have[pool[i]] = true
				count[pick] = count[pick] + 1
				list[CuratorOctoFull.Length(list) + 1] = self:Make(board, pool[i])
			end
		end
		return list
	end
	local pool = self:Pool(board, have)
	local i = 0
	while CuratorOctoFull.Length(list) < board.count and i < CuratorOctoFull.Length(pool) do
		i = i + 1
		local j = self:Roll(CuratorOctoFull.Length(pool) - i + 1) + i - 1
		pool[i], pool[j] = pool[j], pool[i]
		list[CuratorOctoFull.Length(list) + 1] = self:Make(board, pool[i])
	end
	return list
end

-- New quests for a board (the account cannot do it yet: none, the board waits).
function Q:Generate(board, key)
	local entry = { key = key, list = {} }
	if not self:Open(board) then
		entry.locked = true
	else
		self:Fill(board, entry.list)
	end
	ns.db.quests[board.key] = entry
	return entry
end

-- The quests of the periods we are in: new ones when a period ended (and for a board the account
-- could not do, as soon as it can; a period not known yet keeps its quests). True when some came.
-- (Looked at again every few seconds at most, unless forced.)
function Q:Check(force)
	if not ns.db or self.checking then
		return false
	end
	local now = GetTime()
	if not force and self.checked and now - self.checked < 5 then
		return false
	end
	self.checked = now
	-- (what it claims tells the others at once: they may look at the quests while it runs)
	self.checking = true
	local ok, changed = pcall(self.Renew, self)
	self.checking = false
	if not ok then
		geterrorhandler()(changed)
		return false
	end
	return changed
end

-- (1.13.0, after its second test) Once: the quests drawn before the economy was redone, not claimed yet, get the rubies of
-- now (those of a board that had its old value; a quest of another value, a talent's, keeps it). db.qmend: done.
function Q:MendRubies()
	local db = ns.db
	if not db or db.qmend then
		return
	end
	db.qmend = 1
	for _, board in ipairs(BOARDS) do
		local entry = type(db.quests) == "table" and db.quests[board.key]
		local old = self.OLD_RUBIES[board.key]
		for _, q in ipairs(type(entry) == "table" and type(entry.list) == "table" and entry.list or {}) do
			if type(q) == "table" and not q.claimed and old and tonumber(q.r) == old then
				q.r = board.rubies
			end
		end
	end
end

-- New quests for the periods that ended (the rewards of the quests done and not claimed given first);
-- (1.9.0) a board of the period still on, with fewer quests than it now has, given the others.
function Q:Renew()
	self:MendRubies()
	local changed = false
	local auto = { xp = 0, n = 0 }
	for _, board in ipairs(BOARDS) do
		local key = self:ResetKey(board.period)
		local entry = ns.db.quests[board.key]
		-- (1.14.0: the cards changed by another addon this session: a board with quests done and not claimed stays as it
		-- is, renewed after the reload, their rewards claimed then; Guard.lua)
		local waits = false
		if ns.Guard and ns.Guard:Stopped() then
			for _, q in ipairs((entry and entry.list) or {}) do
				if q.done and not q.claimed then
					waits = true
					break
				end
			end
		end
		if waits then
			-- (nothing now)
		elseif key and (not entry or Newer(board.period, key, entry.key) or (entry.locked and self:Open(board))) then
			-- (the rewards of the quests done and not claimed come with the end of their period)
			for _, q in ipairs((entry and entry.list) or {}) do
				if q.done and not q.claimed then
					local xp, p, kind, pts, r = self:Claim(board, q, true)
					auto.xp, auto.n = auto.xp + xp, auto.n + 1
					if kind and p > 0 then
						auto[kind] = (auto[kind] or 0) + p
					end
					auto.pts = (auto.pts or 0) + (pts or 0)
					auto.r = (auto.r or 0) + (r or 0)
				end
			end
			self:Generate(board, key)
			changed = true
		elseif entry and not entry.locked and type(entry.list) == "table" and CuratorOctoFull.Length(entry.list) < board.count and not entry.topped then
			-- (once per period: the pool may have no more kinds to give)
			entry.topped = true
			local before = CuratorOctoFull.Length(entry.list)
			self:Fill(board, entry.list)
			changed = changed or CuratorOctoFull.Length(entry.list) > before
		end
	end
	if auto.n > 0 then
		ns.Fire("QUESTS_AUTOCLAIMED", auto)
	end
	if changed then
		ns.Fire("QUESTS_CHANGED")
		ns.Fire("CLAIMS_CHANGED")
	end
	return changed
end

-- A board's quests (checked first).
function Q:List(boardKey)
	self:Check()
	local entry = ns.db and ns.db.quests[boardKey]
	return entry and entry.list or {}, entry and entry.locked
end

-- Done and all, of a board or of a section.
function Q:Count(boardKeys)
	local done, all = 0, 0
	for _, key in ipairs(boardKeys) do
		local list = self:List(key)
		for _, q in ipairs(list) do
			all = all + 1
			if q.done then
				done = done + 1
			end
		end
	end
	return done, all
end

-- Whether a quest counts what was done: the same kind and, for a kind among several, the same one (a rank:
-- that one or higher).
local function Counts(q, kind, arg)
	if q.k ~= kind or q.done then
		return false
	end
	if q.a == nil then
		return true
	end
	if kind == "pvpRank" then
		return type(arg) == "number" and arg >= q.a
	end
	return arg == q.a
end

-- Something done (kind: what a quest counts) n times (arg: which one, for the kinds among several): the
-- quests that count it move on; those done give their rewards.
-- (1.14.0, after its test, his word: what a reroll does counts for no quest, Reroll.lua: RR:Blocks; a quarter of it
-- counted before his word.)
function Q:Add(kind, n, arg)
	if not ns.db or not KINDS[kind] then
		return
	end
	n = math.floor(tonumber(n) or 0)
	if n <= 0 then
		return
	end
	if ns.Reroll and ns.Reroll:Blocks("quests") then
		return
	end
	self:Check()
	local moved = false
	for _, board in ipairs(BOARDS) do
		local entry = ns.db.quests[board.key]
		for _, q in ipairs((entry and entry.list) or {}) do
			if Counts(q, kind, arg) then
				q.got = math.min(q.n, (q.got or 0) + n)
				moved = true
				if q.got >= q.n then
					self:Complete(board, q)
				end
			end
		end
	end
	if moved then
		ns.Fire("QUESTS_CHANGED")
	end
end

-- A quest done: its rewards wait to be claimed. (1.9.0: counted for the achievements: by period, by
-- section, and a board done whole in its period.)
function Q:Complete(board, q)
	q.done = CuratorOctoFull.ServerTime()
	local st = ns.Stats()
	st.qDone = (tonumber(st.qDone) or 0) + 1
	local key = "q_" .. (board.section == "general" and board.period or board.section)
	st[key] = (tonumber(st[key]) or 0) + 1
	-- (the board done whole: every quest it has, fewer than its count when the account could not do more)
	local entry = ns.db.quests[board.key]
	local all = entry and type(entry.list) == "table" and CuratorOctoFull.Length(entry.list) > 0
	for _, x in ipairs((entry and entry.list) or {}) do
		all = all and x.done ~= nil
	end
	if all then
		local whole = "qAll_" .. board.key
		st[whole] = (tonumber(st[whole]) or 0) + 1
	end
	ns.Fire("QUEST_DONE", board, q)
	ns.Fire("CLAIMS_CHANGED")
end

-- The experience of a quest (1.6.0: more for the quests of hunting, with the talent Hunting Contracts).
function Q:XP(q)
	local xp = tonumber(q and q.xp) or 0
	if ns.Talents then
		xp = ns.Talents:QuestXP(xp, q.k)
	end
	return xp
end

-- (1.11.0) The rubies of a quest: those it came with (a quest drawn before 1.11.0: those of its board).
function Q:Rubies(board, q)
	local r = tonumber(q and q.r)
	if r == nil then
		r = board and tonumber(board.rubies) or 0
	end
	return math.max(0, r or 0)
end

-- The rewards of a quest done claimed: its experience, its points on the booster bar, its boosters to
-- choose, its rubies (auto: at the end of its period). Its experience, its boosters, their kind, its points
-- and its rubies (nothing when it cannot be claimed).
-- (1.14.0) A quest of the save on one of the boards of Curator: no other is claimed (the pages of the quests show
-- them, and another addon reaches what a page shows).
local GENUINE = {}
for _, b in ipairs(BOARDS) do
	GENUINE[b] = true
end
local function OnBoard(board, q)
	if not (GENUINE[board] and ns.db and type(ns.db.quests) == "table") then
		return false
	end
	local entry = ns.db.quests[board.key]
	for _, x in ipairs((type(entry) == "table" and type(entry.list) == "table" and entry.list) or {}) do
		if x == q then
			return true
		end
	end
	return false
end

function Q:Claim(board, q, auto)
	if not (ns.db and q and q.done) or q.claimed or not OnBoard(board, q) then
		return 0, 0, nil, 0, 0
	end
	-- (1.14.0, after its test, his word: a reroll claims none; those of the end of their period come as they are,
	-- Reroll.lua: RR:Blocks)
	if not auto and ns.Reroll and ns.Reroll:Blocks("quests") then
		return 0, 0, nil, 0, 0
	end
	-- (1.14.0: the cards changed by another addon this session: nothing claimed, the quest waits; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return 0, 0, nil, 0, 0
	end
	q.claimed = CuratorOctoFull.ServerTime()
	local p = (board.kind and q.p) or 0
	if p > 0 then
		if board.kind == "hallow" then
			-- (1.12.0: boosters of the album of Hallow's End themselves)
			local hs = ns.Hallow and ns.Hallow:Series()
			if hs and ns.Rewards then
				ns.Rewards:Give(hs, p, "hallowQuest")
			end
		else
			ns.Level:AddChoice(board.kind, p)
		end
	end
	local pts = tonumber(q.pts) or 0
	if pts > 0 and ns.Rewards then
		ns.Rewards:AddAnywhere(pts, "daily")
	end
	-- (1.14.0: a quest of the discovery, a case of its collection; Cases.lua: a reroll, none, the quests claimed by none)
	local cases = math.floor(tonumber(q.c) or 0)
	if cases > 0 and ns.Cases then
		ns.Cases:Give("discovery", cases, board.case)
	end
	-- (1.12.0, later: a quest of a board that chains gives way to another; not at the end of its period)
	if board.chain and not auto then
		self:Chain(board, q)
	end
	local r = self:Rubies(board, q)
	if r > 0 and ns.Rubies then
		r = ns.Rubies:Gain(r, auto and "auto" or "quest", { kind = q.k, period = board.period, section = board.section })
	end
	local xp = self:XP(q)
	ns.Level:Gain(xp, auto and "auto" or "quest")
	if not auto then
		ns.Fire("QUEST_CLAIMED", board, q)
		ns.Fire("CLAIMS_CHANGED")
	end
	return xp, p, board.kind, pts, r
end

-------------------------------------------------------------------------------
-- (1.11.0) The quests of a page changed for others, for rubies (one button on the page of a section): every
-- quest of its boards makes way for another of its board, those done too (the rewards of a quest done and not
-- claimed are given first), drawn among the kinds the account can do (those not on the board first, never
-- twice); what was done for them goes with them. Once in a while for each page (Q.REROLL_CD: the day, the
-- week, the month, the dungeons, the raids, PvP). The price: for each quest changed, twice its own rubies (the
-- rubies of the new ones never pay it back); the talents can lower it (Rubies.lua: RB:Price), the Augur's
-- Prophecy makes the first change of the day free.
-------------------------------------------------------------------------------
Q.REROLL_K = 3 -- (1.13.0: three times its rubies, twice before)
local DAY = 86400
Q.REROLL_CD = { daily = DAY, weekly = 7 * DAY, monthly = 30 * DAY, dungeon = 7 * DAY, raid = 7 * DAY, pvp = 7 * DAY }

-- (1.12.0, later) A quest claimed of a board that chains (Hallow's End): another one in its place, of a kind not
-- among those still to do, while the period has fewer than board.chain quests (entry.made: those it had). True when
-- one came.
function Q:Chain(board, q)
	local entry = ns.db and ns.db.quests[board.key]
	if not (entry and type(entry.list) == "table") or entry.locked then
		return false
	end
	local made = tonumber(entry.made) or CuratorOctoFull.Length(entry.list)
	if made >= board.chain then
		return false
	end
	local at
	for i, x in ipairs(entry.list) do
		if x == q then
			at = i
		end
	end
	if not at then
		return false
	end
	local have = {}
	for i, x in ipairs(entry.list) do
		if i ~= at and not x.claimed then
			have[x.k] = true
		end
	end
	-- (1.14.0: a board of halves, a quest of the half of the one claimed; none left there: of the other)
	local h = board.half and self:HalfOf(board, q.k)
	local pool = self:Pool({ pool = (h and board.half[h]) or board.more or board.pool, period = board.period }, have)
	if CuratorOctoFull.Length(pool) == 0 and h then
		pool = self:Pool({ pool = board.pool, period = board.period }, have)
	end
	if CuratorOctoFull.Length(pool) == 0 then
		return false
	end
	entry.list[at] = self:Make(board, pool[self:Roll(CuratorOctoFull.Length(pool))])
	entry.made = made + 1
	ns.Fire("QUESTS_CHANGED")
	return true
end

-- The quests still to come in the period of a board that chains (after those of now).
function Q:ChainLeft(boardKey)
	local board = self.byKey[boardKey]
	local entry = ns.db and ns.db.quests[boardKey]
	if not (board and board.chain and entry and type(entry.list) == "table") then
		return 0
	end
	return math.max(0, board.chain - (tonumber(entry.made) or CuratorOctoFull.Length(entry.list)))
end

-- The boards of a page (its key in Q.SECTIONS).
function Q:SectionBoards(key)
	for _, sec in ipairs(self.SECTIONS) do
		if sec.key == key then
			local out = {}
			for _, b in ipairs(sec.boards) do
				out[CuratorOctoFull.Length(out) + 1] = self.byKey[b]
			end
			return out
		end
	end
	return {}
end

-- The price of changing a quest of a board, before the talents: twice its rubies.
function Q:RerollEach(board, q)
	return self.REROLL_K * self:Rubies(board, q)
end

-- When the page can change again (0: now), and how long it waits between two changes.
function Q:RerollLeft(key)
	local cd = self.REROLL_CD[key] or DAY
	local last = ns.db and type(ns.db.qrr) == "table" and tonumber(ns.db.qrr[key]) or nil
	if not last then
		return 0, cd
	end
	return math.max(0, last + cd - CuratorOctoFull.ServerTime()), cd
end

-- What a change of the page would do, board by board: { board, entry, slots (the places of its quests: all of
-- them), pool (the kinds that can come), n (how many change), claim (its quests done whose rewards wait) }.
function Q:RerollPlan(key)
	local plan = {}
	if not ns.db then
		return plan
	end
	for _, board in ipairs(self:SectionBoards(key)) do
		local entry = ns.db.quests[board.key]
		if entry and not entry.locked and type(entry.list) == "table" and CuratorOctoFull.Length(entry.list) > 0 then
			local slots, claim = {}, {}
			for i, q in ipairs(entry.list) do
				slots[CuratorOctoFull.Length(slots) + 1] = i
				if q.done and not q.claimed then
					claim[CuratorOctoFull.Length(claim) + 1] = q
				end
			end
			local pool = self:Pool(board, {})
			local n = math.min(CuratorOctoFull.Length(slots), CuratorOctoFull.Length(pool))
			if n > 0 then
				plan[CuratorOctoFull.Length(plan) + 1] = { board = board, entry = entry, slots = slots, pool = pool, n = n, claim = claim }
			end
		end
	end
	return plan
end

-- The price of a change of the page (nil: nothing to change), what it costs before the talents, and how many
-- quests change.
function Q:RerollPrice(key)
	local plan = self:RerollPlan(key)
	if CuratorOctoFull.Length(plan) == 0 then
		return nil
	end
	local base, n = 0, 0
	for _, p in ipairs(plan) do
		local list = p.entry.list
		for k = 1, p.n do
			base = base + self:RerollEach(p.board, list[p.slots[k]])
		end
		n = n + p.n
	end
	base = math.floor(base + 0.5)
	local price = (ns.Rubies and ns.Rubies.Price) and ns.Rubies:Price(base, "reroll") or base
	if ns.Talents and ns.Talents.FreeReroll and ns.Talents:FreeReroll() then
		price = 0
	end
	return price, base, n
end

-- Whether the page can change now: true, or false and why ("none": no quest on it, or no other kind to give;
-- "wait": changed not long ago; "closed"; "rubies": not enough of them; 1.14.0, his word: "reroll", this character
-- is one, Reroll.lua: RR:Blocks).
function Q:CanReroll(key)
	local price = self:RerollPrice(key)
	if not price then
		return false, "none"
	end
	if ns.Beta and ns.Beta:Over() then
		return false, "closed"
	end
	if ns.Reroll and ns.Reroll:Blocks("quests") then
		return false, "reroll"
	end
	if self:RerollLeft(key) > 0 then
		return false, "wait"
	end
	if not (ns.Rubies and ns.Rubies:Has(price)) then
		return false, "rubies"
	end
	return true
end

local function Shuffle(self, t)
	for i = CuratorOctoFull.Length(t), 2, -1 do
		local j = self:Roll(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

-- The page changed: its rubies paid, the rewards of its quests done and not claimed given, a new quest in the
-- place of each one. What changed: { { board, i, old, new } }, the price, and what the rewards claimed gave
-- ({ xp, n, zone, dungeon, raid, pts, r }); nil and why, as CanReroll says it.
function Q:Reroll(key)
	local ok, why = self:CanReroll(key)
	if not ok then
		return nil, why
	end
	-- (1.14.0: the cards changed by another addon this session: nothing paid, nothing changed, the quests wait;
	-- Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil, "guard"
	end
	local price = self:RerollPrice(key)
	local free = price == 0
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "reroll")
		if not paid then
			return nil, err
		end
	elseif free and ns.Talents and ns.Talents.UseFreeReroll then
		ns.Talents:UseFreeReroll()
	end
	local plan = self:RerollPlan(key)
	-- (the rewards waiting first: given as if claimed)
	local got = { xp = 0, n = 0, pts = 0, r = 0 }
	for _, p in ipairs(plan) do
		for _, q in ipairs(p.claim) do
			local xp, packs, kind, pts, r = self:Claim(p.board, q)
			got.xp, got.n = got.xp + (xp or 0), got.n + 1
			if kind and (packs or 0) > 0 then
				got[kind] = (got[kind] or 0) + packs
			end
			got.pts = got.pts + (pts or 0)
			got.r = got.r + (r or 0)
		end
	end
	local changed = {}
	for _, p in ipairs(plan) do
		local list = p.entry.list
		local olds = {}
		for _, i in ipairs(p.slots) do
			olds[list[i].k] = true
		end
		-- the kinds that were not on the board first, then the others (never to the place it had)
		local fresh, stale = {}, {}
		for _, kind in ipairs(p.pool) do
			if olds[kind] then
				stale[CuratorOctoFull.Length(stale) + 1] = kind
			else
				fresh[CuratorOctoFull.Length(fresh) + 1] = kind
			end
		end
		Shuffle(self, fresh)
		Shuffle(self, stale)
		local slots = Shuffle(self, { unpack(p.slots) })
		for _, i in ipairs(slots) do
			local old = list[i]
			local kind = CuratorOctoFull.Remove(fresh)
			if not kind then
				for j = CuratorOctoFull.Length(stale), 1, -1 do
					if stale[j] ~= old.k then
						kind = CuratorOctoFull.Remove(stale, j)
						break
					end
				end
				kind = kind or CuratorOctoFull.Remove(stale)
			end
			-- (a place left without a kind to give: its quest stays as it is)
			if kind then
				local new = self:Make(p.board, kind)
				list[i] = new
				changed[CuratorOctoFull.Length(changed) + 1] = { board = p.board, i = i, old = old, new = new }
			end
		end
		p.entry.rerolls = (tonumber(p.entry.rerolls) or 0) + 1
	end
	ns.db.qrr = type(ns.db.qrr) == "table" and ns.db.qrr or {}
	ns.db.qrr[key] = CuratorOctoFull.ServerTime()
	local st = ns.Stats()
	st.qRerolls = (tonumber(st.qRerolls) or 0) + 1
	st.qRerolled = (tonumber(st.qRerolled) or 0) + CuratorOctoFull.Length(changed)
	if got.n > 0 then
		ns.Fire("QUESTS_REROLL_CLAIMED", got)
	end
	ns.Fire("QUESTS_REROLLED", key, changed, price, free, got)
	ns.Fire("QUESTS_CHANGED")
	ns.Fire("CLAIMS_CHANGED")
	return changed, price, got
end

-- The quests done whose rewards wait: { board, q } (of a section only, by its key).
function Q:Claimable(section)
	local out = {}
	for _, board in ipairs(BOARDS) do
		if not section or board.section == section or board.key == section then
			local entry = ns.db and ns.db.quests[board.key]
			for _, q in ipairs((entry and entry.list) or {}) do
				if q.done and not q.claimed then
					out[CuratorOctoFull.Length(out) + 1] = { board = board, q = q }
				end
			end
		end
	end
	return out
end

-- The rewards waiting, of the quests and of the levels.
function ns.ClaimCount()
	local n = CuratorOctoFull.Length(Q:Claimable())
	if ns.Level then
		n = n + CuratorOctoFull.Length(ns.Level:Unclaimed())
	end
	return n
end

-------------------------------------------------------------------------------
-- What the quests count: what the player does (Rewards.lua, the boosters), and here what it gathers
-- and its PvP
-------------------------------------------------------------------------------
ns.On("ACTIVITY", function(kind, n)
	Q:Add(kind, n or 1)
end)
ns.On("PACK_EARNED", function(_, n)
	Q:Add("earn", n or 1)
end)
-- (1.9.0) the cards a booster, a creature or a contract gave: new ones, rare ones and better, forged ones
local function Got(card, finish, new)
	if type(card) ~= "table" then
		return
	end
	if new then
		Q:Add("newcard", 1)
	end
	if (card.rarity or 0) >= 3 then
		Q:Add("rare", 1)
	end
	if (card.rarity or 0) >= 4 then
		Q:Add("epic", 1)
	end
	if finish == "shiny" or finish == "holo" then
		Q:Add("forged", 1)
	end
	-- (1.12.0) Hallow's End: its cards, the corrupted ones
	if card.series and card.series.event then
		Q:Add("hallowCards", 1)
	end
	if finish == "corrupt" then
		Q:Add("hallowCorrupt", 1)
	end
end
ns.On("BOOSTER_OPENED", function(s, picks)
	Q:Add("open", 1)
	if type(s) == "table" and s.dungeon then
		Q:Add("lairOpen", 1)
	end
	if type(s) == "table" and s.event then
		Q:Add("hallowOpen", 1)
	end
	for _, p in ipairs(type(picks) == "table" and picks or {}) do
		Got(p.card, p.finish, p.new)
	end
end)
ns.On("CARD_FOUND", function(card, finish, new)
	Q:Add("find", 1)
	if type(card) == "table" and card.series and card.series.event then
		Q:Add("hallowFind", 1)
	end
	Got(card, finish, new)
end)
-- (1.12.0) Hallow's End: a treat at an innkeeper, a creature of its album defeated
ns.On("HALLOW_TREAT", function()
	Q:Add("hallowTreat", 1)
end)
ns.On("HALLOW_KILL", function()
	Q:Add("hallowKill", 1)
end)
ns.On("CONTRACT_SIGNED", function(result)
	if type(result) ~= "table" then
		return
	end
	Q:Add("contract", tonumber(result.n) or 1)
	if (tonumber(result.up) or 0) >= 4 then
		Q:Add("contractEpic", tonumber(result.n) or 1)
	end
	for _, c in ipairs(type(result.cards) == "table" and result.cards or {}) do
		Got(c.card, c.finish or result.finish, c.new)
	end
end)
ns.On("KILLED", function(card, elite, inside, rare)
	if type(card) == "table" and card.type then
		Q:Add("ctype", 1, card.type)
		-- (1.12.0: the undead, for the quests of Hallow's End)
		if card.type == 6 then
			Q:Add("hallowUndead", 1)
		end
	end
	-- (31 October, his word: the rares of the world only, no more the elites)
	if rare and not inside then
		Q:Add("elite", 1)
	end
end)
ns.On("XP_GAINED", function(n, why)
	-- (the experience of the quests themselves does not count for them, nor that of a golden quest)
	if why ~= "quest" and why ~= "auto" and why ~= "golden" then
		Q:Add("xp", n)
	end
end)
ns.On("INN_STAMP", function()
	Q:Add("stamp", 1)
end)
ns.On("INN_VISA", function()
	Q:Add("visa", 1)
end)
ns.On("TAVERN_BET", function()
	Q:Add("bet", 1)
end)
-- PvP: the honorable kills where they were made, the enemies (class, race, rank, level), the trophies, the
-- combatants, the exploits, the revenges, the war board, the heads with a price
ns.On("PVP_KILL", function(t)
	if type(t) ~= "table" then
		return
	end
	Q:Add(t.z and "bgHk" or "worldHk", 1)
	if t.cls then
		Q:Add("pvpClass", 1, t.cls)
	end
	if t.race then
		Q:Add("pvpRace", 1, t.race)
	end
	if (tonumber(t.r) or 0) > 0 then
		Q:Add("pvpRank", 1, tonumber(t.r))
	end
	if (tonumber(t.lvl) or 0) >= 60 then
		Q:Add("pvp60", 1)
	end
end)
-- (1.14.0, his word: the trophies certified, the exploits, the revenges, the war board and the front gone with the PvP
-- until its rework: nothing of them counts any more)

-- The gathering spells (by their names, in the language of the client): herbs, ore, skins (1.14.0: each its kind, for
-- the talents of the Cartographer).
local GATHER_SPELLS = { 2366, 2575, 8613 }
local GATHER_KIND = { [2366] = "herb", [2575] = "ore", [8613] = "skin" }
local gatherNames
local function GatherNames()
	if gatherNames then
		return gatherNames
	end
	gatherNames = {}
	for _, id in ipairs(GATHER_SPELLS) do
		local name
		if C_Spell and C_Spell.GetSpellName then
			local ok, n = pcall(C_Spell.GetSpellName, id)
			name = ok and n or nil
		elseif GetSpellInfo then
			local ok, n = pcall(GetSpellInfo, id)
			name = ok and n or nil
		end
		if type(name) == "string" and not Secret(name) and name ~= "" then
			gatherNames[name] = GATHER_KIND[id] or true
		end
	end
	return gatherNames
end

function Q:OnSpell(unit, spellID)
	if unit ~= "player" or type(spellID) ~= "number" or Secret(spellID) then
		return
	end
	local name
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, spellID)
		name = ok and n or nil
	elseif GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, spellID)
		name = ok and n or nil
	end
	local kind = type(name) == "string" and not Secret(name) and GatherNames()[name]
	if kind then
		self:Add("gather", 1)
		-- (1.10.0: what was gathered, for the golden quests: a node or a body, not a fish; 1.14.0: its kind)
		ns.Fire("GATHERED", "node", kind ~= true and kind or nil)
	end
end

-- A fish caught: the loot of a line (once: the loot can tell it is ready twice).
function Q:OnLoot()
	local now = GetTime()
	if not IsFishingLoot or (self.lootAt and now - self.lootAt < 1) then
		return
	end
	local ok, fish = pcall(IsFishingLoot)
	if ok and fish == true then
		self.lootAt = now
		self:Add("gather", 1)
		ns.Fire("GATHERED", "fish", "fish")
	end
end

-- The honorable kills, as the game counts them (from its own reset): each new one counts. A count
-- lower than the one kept is a new count since its reset; none (as some clients say before they
-- know) is not one.
function Q:OnHonor()
	if not GetPVPSessionStats then
		return
	end
	local ok, hk = pcall(GetPVPSessionStats)
	if not ok or type(hk) ~= "number" or Secret(hk) or hk <= 0 then
		return
	end
	local c = ns.Rewards:Char()
	local before = c.hk
	if before == nil then
		-- (a character never counted: this kill)
		before = hk - 1
	elseif hk < before then
		before = 0
	end
	c.hk = hk
	if hk > before then
		self:Add("hk", hk - before)
	end
end

-- The honorable kills a character has already made, the first time it is seen (only the new ones
-- count).
function Q:SeedHonor()
	if not GetPVPSessionStats then
		return
	end
	local c = ns.Rewards:Char()
	if c.hk ~= nil then
		return
	end
	local ok, hk = pcall(GetPVPSessionStats)
	if ok and type(hk) == "number" and not Secret(hk) and hk > 0 then
		c.hk = hk
	end
end

-- The end of a battleground: finished, won (winner: 0 the Horde, 1 the Alliance). Once for each,
-- a reload on its last screen included (kept for the character until it enters a world again).
-- (1.9.0: which battleground, for the quests of each, and counted for the achievements: played and won,
-- each battleground apart.)
function Q:OnBattlegroundEnd(winner)
	if type(winner) ~= "number" or Secret(winner) then
		return
	end
	if IsInInstance then
		local ok, inside, kind = pcall(IsInInstance)
		if not ok or not inside or kind ~= "pvp" then
			return
		end
	end
	local c = ns.Rewards:Char()
	if c.bgDone then
		return
	end
	c.bgDone = true
	local bg = ns.Pvp and ns.Pvp:Battleground() or nil
	local st = ns.Stats()
	-- (1.14.0, after its test, his word: the matches of a reroll count for no achievement, Reroll.lua: RR:Blocks)
	local counts = not (ns.Reroll and ns.Reroll:Blocks("achievements"))
	local function Up(key)
		if counts then
			st[key] = (tonumber(st[key]) or 0) + 1
		end
	end
	Up("bgPlayed")
	self:Add("bgPlay", 1)
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	if (winner == 0 and faction == "Horde") or (winner == 1 and faction == "Alliance") then
		Up("bgWins")
		if bg then
			Up("bgWin_" .. bg)
		end
		self:Add("bgWin", 1)
		if bg then
			self:Add("bgWinIn", 1, bg)
		end
	end
	ns.Fire("BG_DONE", bg)
end

-- (the quests of 0.18 gave their rewards when they were done: they are claimed)
ns.On("LOADED", function()
	local db = ns.db
	if db.questClaims then
		return
	end
	db.questClaims = true
	for _, entry in pairs(db.quests or {}) do
		for _, q in ipairs(type(entry) == "table" and entry.list or {}) do
			if q.done and not q.claimed then
				q.claimed = q.done
			end
		end
	end
end)

-- (1.2: the quests already given take the rewards and the counts of the new boosters; the counts of
-- boosters to open or to earn come down, and a quest that reaches its new count is done)
ns.On("LOADED", function()
	local db = ns.db
	if db.questsBar then
		return
	end
	db.questsBar = true
	for key, entry in pairs(db.quests or {}) do
		local board = Q.byKey[key]
		for _, q in ipairs((board and type(entry) == "table" and entry.list) or {}) do
			if not q.claimed then
				q.p, q.pts = board.packs, board.pts
				local goal = KINDS[q.k] and KINDS[q.k][board.period]
				if not q.done and goal and goal < (q.n or 0) then
					q.n = goal
					if (q.got or 0) >= goal then
						q.got = goal
						q.done = CuratorOctoFull.ServerTime()
					end
				end
			end
		end
	end
end)

-- (1.14.0, his word: the PvP gone until its rework) Once: a quest of PvP of a kind gone (the trophies, the combatants, the
-- exploits, the revenges, the war board, the front), not done, gives way to another of its board (one done keeps its
-- rewards to claim).
ns.On("LOADED", function()
	local db = ns.db
	if not db or db.qpvpGone then
		return
	end
	db.qpvpGone = 1
	for _, board in ipairs(BOARDS) do
		if board.section == "pvp" then
			local entry = type(db.quests) == "table" and db.quests[board.key]
			local list = type(entry) == "table" and type(entry.list) == "table" and entry.list or nil
			if list then
				local keep = {}
				for _, k in ipairs(board.pool) do
					keep[k] = true
				end
				local have = {}
				for _, q in ipairs(list) do
					have[q.k] = true
				end
				for i, q in ipairs(list) do
					if type(q) == "table" and not keep[q.k] and not q.done then
						local pool = Q:Pool(board, have)
						if CuratorOctoFull.Length(pool) > 0 then
							local k = pool[Q:Roll(CuratorOctoFull.Length(pool))]
							have[k] = true
							list[i] = Q:Make(board, k)
						end
					end
				end
			end
		end
	end
end)

-- (31 October, his word: no more elites in the quests, the rares kept; the review of the night) Once: a quest of the
-- elites not done, drawn before, gives way to another of its board when its board no longer draws its kind (of the day,
-- of the dungeons); else, a quest of the rares of the week or the month now, it asks their count (done if it got there).
function Q:ElitesGone()
	local db = ns.db
	if not db or db.qelitesGone then
		return
	end
	db.qelitesGone = 1
	local GONE = { elite = true, palElite = true, dungeonElite = true }
	for _, board in ipairs(BOARDS) do
		local entry = type(db.quests) == "table" and db.quests[board.key]
		local list = type(entry) == "table" and type(entry.list) == "table" and entry.list or nil
		if list then
			local drawn = {}
			for _, pool in ipairs({ board.pool or {}, board.more or {}, (board.half or {})[1] or {}, (board.half or {})[2] or {} }) do
				for _, k in ipairs(pool) do
					drawn[k] = true
				end
			end
			local have = {}
			for _, q in ipairs(list) do
				if type(q) == "table" then
					have[q.k] = true
				end
			end
			for i, q in ipairs(list) do
				if type(q) == "table" and GONE[q.k] and not q.done and not q.claimed then
					local goal = KINDS[q.k] and KINDS[q.k][board.period]
					if goal and drawn[q.k] then
						if (tonumber(q.n) or 0) > goal then
							q.n = goal
							if (tonumber(q.got) or 0) >= goal then
								q.got, q.done = goal, CuratorOctoFull.ServerTime()
							end
						end
					else
						-- (of its half, a board of halves; else of its board)
						local h = board.half and Q:HalfOf(board, q.k)
						local pool = Q:Pool({ pool = (h and board.half[h]) or board.pool or (board.half and board.half[2]) or {}, period = board.period }, have)
						if CuratorOctoFull.Length(pool) == 0 and board.half then
							pool = Q:Pool({ pool = board.half[2] or {}, period = board.period }, have)
						end
						if CuratorOctoFull.Length(pool) > 0 then
							local k = pool[Q:Roll(CuratorOctoFull.Length(pool))]
							have[k] = true
							list[i] = Q:Make(board, k)
						end
					end
				end
			end
		end
	end
end
ns.On("LOADED", function()
	Q:ElitesGone()
end)

-- (1.9.0) The faction of each character of the account (the enemies of the quests of PvP).
local function KeepFaction()
	if not (ns.db and ns.Rewards and UnitFactionGroup) then
		return
	end
	local f = UnitFactionGroup("player")
	if f == "Alliance" or f == "Horde" then
		ns.Rewards:Char().faction = f
	end
end

local f = CreateFrame("Frame")
Q.frame = f
f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "LOOT_READY", "PLAYER_PVP_KILLS_CHANGED", "PVP_MATCH_COMPLETE", "UPDATE_BATTLEFIELD_STATUS",
			"UPDATE_BATTLEFIELD_SCORE", "PLAYER_ENTERING_WORLD" }) do
			pcall(f.RegisterEvent, f, e)
		end
		-- (the spells of the player only: those of the others are many in a raid)
		if f.RegisterUnitEvent then
			pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")
		else
			pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
		end
		KeepFaction()
		Q:Check(true)
		Q:SeedHonor()
		-- (the periods end while playing: checked now and then)
		if CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker then
			CuratorOctoFull.Timer.NewTicker(60, function()
				Q:Check(true)
			end)
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spellID = unpack(arg, 1, arg.n)
		Q:OnSpell(unit, spellID)
	elseif event == "LOOT_READY" then
		Q:OnLoot()
	elseif event == "PLAYER_PVP_KILLS_CHANGED" then
		Q:OnHonor()
	elseif event == "PVP_MATCH_COMPLETE" then
		Q:OnBattlegroundEnd((unpack(arg, 1, arg.n)))
	elseif event == "UPDATE_BATTLEFIELD_STATUS" or event == "UPDATE_BATTLEFIELD_SCORE" then
		-- (the clients that tell the end of a battleground this way)
		if GetBattlefieldWinner then
			local ok, w = pcall(GetBattlefieldWinner)
			if ok and w then
				Q:OnBattlegroundEnd(w)
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- (a world entered, not reloaded: a new battleground can end again)
		local _, reload = unpack(arg, 1, arg.n)
		if not reload and ns.db then
			ns.Rewards:Char().bgDone = nil
		end
		KeepFaction()
	end
end)
