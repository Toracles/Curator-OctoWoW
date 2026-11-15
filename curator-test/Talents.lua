local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- (1.14.0, the release of OctoWoW) The talents of the collector, redone: one tree for the account, among five new
-- ones (none of the talents of before stays: the release starts every collection over): the Cartographer (the places,
-- the gathering, the inns and their rumors, the albums of the zones), the Bounty Hunter (the elites, the rares, the
-- bosses, the dungeons, the raids, the enemies), the Gambler (the boosters, the displays, the bets of the innkeepers, the
-- cases), the Smuggler (the reseller, the trades, the contracts) and the Archivist (the expertise, the seals, the
-- restorations, the showcase). The specialization is chosen at collector level TL.CHOOSE (5); its first point comes then,
-- one more with each level up to the legend (56 at level 60), then one every two levels (76 at level 100). Each tree
-- holds 100 ranks: at level 100 a quarter of it stays empty, a choice to make. Ten tiers: a tier opens with TL.TIER_NEED
-- points in the tier above it (all that tier holds when it holds fewer: the seventh, its one talent); the tiers 8 to 10
-- also wait for the level past the legend (61). In each tree a talent of its own, active, at the third tier, that the
-- fourth and the sixth improve, and two summits (the seventh and the tenth tiers): the first time a summit works, an
-- achievement and its title of prestige. Less raw power than before: no big bonus of legendary or mythic cards, no pity
-- (the contracts are there for that), odds that stay under the caps of the watch of the website (lib/watch.ts). Points
-- are placed, then applied: applied, they stay, as the specialization does. To place them again, or to change the
-- specialization: a contract of reconversion paid in rubies (TL.RESPEC_BASE, twice as much each time after, a step less
-- for each TL.RESPEC_DECAY without one); the first one is offered (every tree is new). The state is the account's
-- (db.talents, sealed with the rest of the save).
local TL = {}
ns.Talents = TL

TL.CHOOSE = 5
TL.TIERS = 10
TL.TIER_NEED = 5
TL.LEGEND_TIER = 8 -- (the first tier past the legend)
TL.COLS = 3
TL.RESPEC_BASE = 16000
TL.RESPEC_DECAY = 30 * 86400
TL.RESPEC_STEPS = 5             -- the price doubles five times at most (512 000)
TL.DAY, TL.HOUR, TL.MIN = 86400, 3600, 60
-- (the trades of a day that count: Handshake, Toll)
TL.PARTNERS_A_DAY = 5
TL.TOLLS_A_DAY = 5
-- (Night: from 22 h to 6 h on the clock of the player: Starry Night)
TL.NIGHT_FROM, TL.NIGHT_TO = 22, 6
-- (Atlas: the parts of an album of a zone that pay, and the last one)
TL.ATLAS = { 0.25, 0.5, 0.75, 1 }
-- (Hoard: the rubies held it asks, and what it gives at most for each rank)
TL.HOARD_FROM, TL.HOARD_MAX = 20000, 300
-- (Annuity: the boosters of a week it asks)
TL.ANNUITY_BOOSTERS = 50
-- (Gallery: the visitors of a day that pay)
TL.VISITORS_A_DAY = 20
-- (Raider: a dungeon done within so many seconds)
TL.RAIDER_TIME = 45 * 60
-- (Nomad: a zone not played for so long)
TL.NOMAD_AFTER = 3 * 86400
-- (Morning Dew: the first hour of play of the day)
TL.DEW_TIME = 3600
-- (the Darkmoon Wheel: its parts, in hundredths; Darkmoon Fortune takes from "nothing" and gives to the boosters)
TL.WHEEL = { { "nothing", 40 }, { "rubies", 30 }, { "zone", 22 }, { "zone2", 6 }, { "dungeon", 2 } }
TL.WHEEL_RUBIES = 150

TL.SPECS = {
	{ key = "carto", name = "Cartographer", icon = "Interface\\Icons\\INV_Misc_Map_01", color = { 0.42, 0.88, 0.56 }, art = "DruidRestoration",
		desc = "The surveyor of the Explorers' League: the places, the gathering, the inns and their rumors fill the albums of the zones. Strong from the first levels." },
	{ key = "hunter", name = "Bounty Hunter", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", color = { 1, 0.45, 0.32 }, art = "HunterMarksmanship",
		desc = "Hunts what is worth a lot: the elites, the rares, the bosses, the dungeons and the raids. Every head has its price." },
	{ key = "gambler", name = "Gambler", icon = "Interface\\Icons\\INV_Misc_Ticket_Darkmoon_01", color = { 0.8, 0.52, 1 }, art = "MageArcane",
		desc = "The player of the Darkmoon Faire: the boosters, the displays, the bets of the innkeepers and the cases. More risk, more thrills." },
	{ key = "smuggler", name = "Smuggler", icon = "Interface\\Icons\\INV_Misc_Coin_02", color = { 1, 0.78, 0.3 }, art = "RogueCombat",
		desc = "The king of the black market of Booty Bay: the reseller, the other players and the contracts, always a ruby ahead." },
	{ key = "archivist", name = "Archivist", icon = "Interface\\Icons\\INV_Misc_Book_11", color = { 0.52, 0.8, 1 }, art = "PriestDiscipline",
		desc = "The keeper of the archives of Dalaran: appraises, seals, restores and shows. A perfect card is worth a thousand copies." },
}
TL.SPEC_BY = {}
for i, s in ipairs(TL.SPECS) do
	s.index = i
	TL.SPEC_BY[s.key] = s
end

-------------------------------------------------------------------------------
-- The trees. A talent: its place (tier, column 1 to 3; the two talents of a choice share a column), its ranks, its
-- name, its icon, what it does (desc: its text, %s the value of the rank; val(rank): the values of a text of several),
-- its value (per: by rank; vals: for each rank; fixed: one rank), how the value reads (fmt), a choice it is part of
-- (choice: the key shared by the two), what it needs (req: this talent learned), an active one (cd: its recharge) or
-- one of each day or week (limit), a summit (capstone: its achievement, ach).
-------------------------------------------------------------------------------
TL.LIST = {}
TL.BY = {}
local function Def(spec, tier, col, id, ranks, name, icon, desc, t)
	t = t or {}
	t.spec, t.tier, t.col, t.id, t.ranks, t.name, t.desc = spec, tier, col, id, ranks, name, desc
	t.icon = string.find(icon, "\\", 1, true) and icon or ("Interface\\Icons\\" .. icon)
	t.index = CuratorOctoFull.Length(TL.LIST) + 1
	TL.LIST[t.index] = t
	TL.BY[id] = t
	return t
end
TL.Def = Def

local H = 3600
-- the Cartographer
Def("carto", 1, 1, "fieldbook", 5, "Field Notebook", "INV_Misc_Book_04", "The places discovered, the steps of quests and the quests turned in fill your booster bar of the world %s more.", { per = 0.05, fmt = "pct" })
Def("carto", 1, 2, "forage", 5, "Learned Foraging", "Trade_Herbalism", "Each herb, ore, skin or fish you gather gives %s points to your booster bar of the world (a creature gives 2).", { per = 0.4, fmt = "dec" })
Def("carto", 1, 3, "compass", 1, "Compass", "INV_Misc_Spyglass_02", "Entering a zone, you are told how many cards of its album you are missing, and the rarest of them.")
Def("carto", 2, 1, "finds", 5, "Finds", "INV_Box_01", "Something gathered has a %s chance to give you a common or uncommon card of the place that you are missing.", { per = 0.003, fmt = "pct" })
Def("carto", 2, 2, "passport", 5, "Stamped Passport", "INV_Misc_Note_02", "Each new visa of your travel passport gives you %s rubies and %s experience.", { val = function(r) return 25 * r, 150 * r end })
Def("carto", 2, 3, "wordofmouth", 1, "Word of Mouth", "INV_Drink_04", "The innkeepers you are a regular of tell you two rumors a day instead of one.")
Def("carto", 3, 1, "survey", 1, "Survey", "INV_Misc_Map_01", "Active: for %s, in your zone, the creatures whose card you are missing wear a mark in their tooltip and give their card twice as often. Recharges in %s.", { cd = 20 * H, active = true })
Def("carto", 3, 2, "atlas", 5, "Atlas", "INV_Misc_Book_06", "An album of a zone that reaches 25 %%, 50 %% or 75 %% of its cards gives you %s rubies; %s at 100 %%.", { val = function(r) return 40 * r, 120 * r end })
Def("carto", 3, 3, "trails", 5, "Forgotten Trails", "Ability_Hunter_Pathfinding", "Your booster bar of the world fills %s faster in the zones where you have less than half of the cards.", { per = 0.04, fmt = "pct" })
Def("carto", 4, 1, "survey2", 3, "Thorough Survey", "INV_Misc_Spyglass_01", "Survey lasts %s more.", { per = 600, fmt = "dur", req = { "survey" } })
Def("carto", 4, 2, "explorer", 5, "Explorer's Stride", "Ability_Rogue_Sprint", "The quests of the collector of gathering, of the inns and of new cards give %s more experience.", { per = 0.04, fmt = "pct" })
Def("carto", 4, 3, "homeland", 1, "Homeland", "INV_Misc_Bag_10", "Your booster bar of the world fills %s faster in the zone of your hearthstone.", { fixed = 0.15, fmt = "pct", choice = "c4" })
Def("carto", 4, 3, "nomad", 1, "Nomad", "Ability_Druid_Dash", "Your booster bar of the world fills %s faster in a zone you have not played in for 3 days.", { fixed = 0.15, fmt = "pct", choice = "c4" })
Def("carto", 5, 1, "freshink", 5, "Fresh Ink", "INV_Scroll_02", "In your boosters of a zone, the cards you were missing give %s more experience.", { per = 0.04, fmt = "pct" })
Def("carto", 5, 2, "lodging", 5, "Bed and Board", "INV_Misc_Note_06", "The 7th stamp of your loyalty card of the inns gives one more booster %s of the time.", { per = 0.1, fmt = "pct" })
Def("carto", 5, 3, "treasure", 1, "Treasure Map", "INV_Misc_Map_01", "Once a week, the first rumor of the tavern you follow to its card also gives you a booster of its album.", { limit = "week" })
Def("carto", 6, 1, "survey3", 3, "Great Survey", "Ability_Hunter_EagleEye", "Survey recharges in %s.", { vals = { 16 * H, 12 * H, 8 * H }, fmt = "dur", req = { "survey" } })
Def("carto", 6, 2, "seasoned", 5, "Seasoned Traveler", "Ability_Warrior_Charge", "The creatures of your level or above fill your booster bar of the world %s more.", { per = 0.04, fmt = "pct" })
Def("carto", 6, 3, "herbalist", 1, "Herbalist", "Trade_Herbalism", "Your herbs and your fish count twice for Learned Foraging and Finds.", { choice = "c6" })
Def("carto", 6, 3, "prospector", 1, "Prospector", "Trade_Mining", "Your ore and your skins count twice for Learned Foraging and Finds.", { choice = "c6" })
Def("carto", 7, 2, "terra", 1, "Terra Incognita", "Spell_Nature_SpiritArmor", "Each day, your first victory over a creature whose card you are missing (rare at most), in a zone where you have less than three quarters of the cards, gives you its card. The first time: an achievement and a title of prestige.", { limit = "day", capstone = true, ach = "tTerra" })
Def("carto", 8, 1, "veins", 5, "Rich Veins", "INV_Misc_Gem_Ruby_02", "Each thing gathered has a %s chance to give you 25 rubies.", { per = 0.01, fmt = "pct" })
Def("carto", 8, 2, "stubborn", 5, "Stubborn Rumor", "INV_Misc_Note_01", "A rumor of the tavern stays true %s more, as long as its card is not found.", { per = 86400, fmt = "dur" })
Def("carto", 8, 3, "roadbook", 5, "Road Book", "INV_Scroll_04", "Each day, your first quest turned in in each zone fills its bar with %s more points.", { per = 8, fmt = "num" })
Def("carto", 9, 1, "blanks", 5, "Blank Squares", "INV_Misc_Book_09", "A card you already have, found on a creature, gives way %s of the time to a card of the same album and rarity that you are missing.", { per = 0.03, fmt = "pct" })
Def("carto", 9, 2, "scholar", 5, "Scholar of Places", "INV_Misc_Book_11", "The achievements of the albums and of exploration give %s more experience and rubies.", { per = 0.06, fmt = "pct" })
Def("carto", 9, 3, "starry", 1, "Starry Night", "Spell_Nature_StarFall", "Between 10 PM and 6 AM, Survey also doubles the points of your booster bar of the world.", { choice = "c9" })
Def("carto", 9, 3, "dew", 1, "Morning Dew", "Spell_Nature_Rejuvenation", "Your first hour of play of the day, your booster bar of the world fills %s faster.", { fixed = 0.25, fmt = "pct", choice = "c9" })
Def("carto", 10, 1, "gemroad", 5, "Road of Gems", "INV_Misc_Gem_Variety_01", "Each album of a zone completed gives you %s rubies.", { per = 600, fmt = "num" })
Def("carto", 10, 2, "expedition", 1, "Expedition", "INV_Misc_Spyglass_03", "Active, once a week: for 1 hour, the creatures of your zone give you their card three times as often. The first time an epic card or better falls during an Expedition: an achievement and a title of prestige.", { limit = "week", active = true, capstone = true, ach = "tExped" })
Def("carto", 10, 3, "roadmemory", 5, "Memory of the Roads", "Spell_Holy_SurgeOfLight", "All the experience you earn outside the dungeons and the raids: +%s.", { per = 0.01, fmt = "pct" })

-- the Bounty Hunter
Def("hunter", 1, 1, "quarry", 5, "Choice Quarry", "Ability_Hunter_SniperShot", "Your chance to find the card of an elite or a rare you defeat: +%s.", { per = 0.06, fmt = "pct" })
Def("hunter", 1, 2, "wanted", 5, "Wanted Poster", "INV_Misc_Note_02", "The quests of the collector of creatures, of elites, of dungeons and of PvP give %s more experience.", { per = 0.04, fmt = "pct" })
Def("hunter", 1, 3, "flair", 1, "Keen Nose", "Ability_Tracking", "A sound and a message tell you when a rare whose card you are missing is in sight.")
Def("hunter", 2, 1, "tally", 5, "Hunting Tally", "INV_Misc_Bone_HumanSkull_01", "The bosses of the dungeons and the raids give %s more points to their booster bar.", { per = 2, fmt = "num" })
-- (1.14.0, his word: the PvP gone until its rework; its talents with it, each one in its place another of the hunt)
Def("hunter", 2, 2, "stalker", 5, "Elite Stalker", "Ability_Rogue_Sprint", "The elites you defeat in the world fill your booster bar of the world %s more.", { per = 0.06, fmt = "pct" })
Def("hunter", 2, 3, "teeth", 5, "Necklace of Teeth", "INV_Misc_Head_Tiger_01", "The cards found on bosses come thunderforged %s of the time.", { per = 0.03, fmt = "pct" })
Def("hunter", 3, 1, "mark", 1, "Price on its Head", "INV_Misc_Head_Human_01", "Active: mark your target (a creature that has a card): defeat it within %s and your chance to find its card is tripled. Recharges in %s.", { cd = 8 * H, active = true })
Def("hunter", 3, 2, "deep", 5, "Regular of the Depths", "INV_Misc_Key_14", "The elites of the dungeons and the raids give %s more points to their booster bar (0.5 without it).", { per = 0.1, fmt = "dec" })
Def("hunter", 3, 3, "pelts", 5, "Prized Pelts", "INV_Misc_Pelt_Wolf_01", "Each rare you defeat fills your booster bar of the world with %s points.", { per = 8, fmt = "num" })
Def("hunter", 4, 1, "mark2", 3, "Hot Trail", "Ability_Druid_Dash", "Price on its Head lasts %s more.", { per = 300, fmt = "dur", req = { "mark" } })
Def("hunter", 4, 2, "rarebounty", 3, "Rare Bounty", "INV_Misc_Coin_02", "Each rare you defeat in the world gives you %s rubies.", { per = 10, fmt = "num" })
Def("hunter", 4, 3, "firstblood", 1, "First Blood", "Ability_Warrior_DecisiveStrike", "The first elite you defeat each hour gives you its card twice as often.", { choice = "h4" })
Def("hunter", 4, 3, "halali", 1, "Death Halloo", "Ability_Warrior_BattleShout", "The last boss of a dungeon draws its card a second time when it did not give it.", { choice = "h4" })
Def("hunter", 5, 1, "biggame", 5, "Big Game", "Ability_Mount_JungleTiger", "Your chance to find a legendary or mythic card on a creature: +%s.", { per = 0.04, fmt = "pct" })
Def("hunter", 5, 2, "trophies", 5, "Trophy Room", "INV_Misc_Head_Orc_01", "Each boss of a dungeon or a raid you defeat gives you %s rubies.", { per = 6, fmt = "num" })
Def("hunter", 5, 3, "contractw", 1, "Contract of the Week", "INV_Scroll_03", "Each week, the first last boss of a dungeon or boss of a raid you defeat gives you one more booster of its album.", { limit = "week" })
Def("hunter", 6, 1, "mark3", 3, "Endless Hunt", "Ability_Hunter_RunningShot", "Price on its Head recharges in %s.", { vals = { 6 * H, 4 * H, 3 * H }, fmt = "dur", req = { "mark" } })
Def("hunter", 6, 2, "mounted", 5, "Mounted Heads", "INV_Misc_Head_Dragon_01", "The cards you find on elites and bosses come forged %s more often.", { per = 0.03, fmt = "pct" })
Def("hunter", 6, 3, "delver", 1, "Delver", "INV_Misc_Bag_10", "The bosses of the dungeons fill their booster bar %s more.", { fixed = 0.25, fmt = "pct", choice = "h6" })
Def("hunter", 6, 3, "dragonslayer", 1, "Dragonslayer", "INV_Misc_Head_Dragon_Black", "The bosses of the raids fill their booster bar %s more.", { fixed = 0.25, fmt = "pct", choice = "h6" })
Def("hunter", 7, 2, "dailyhead", 1, "Contract of the Day", "INV_Misc_Bone_HumanSkull_01", "Each day, a target is named to you: an elite or a rare of a zone of your level whose card you are missing. Defeat it and its card is given to you. The first time: an achievement and a title of prestige.", { limit = "day", capstone = true, ach = "tHead" })
Def("hunter", 8, 1, "reward", 5, "Reward", "INV_Misc_Coin_04", "Each elite or rare whose card you find gives you %s rubies.", { per = 20, fmt = "num" })
Def("hunter", 8, 2, "bigbore", 5, "Big Bore", "INV_Weapon_Rifle_01", "The bosses of the raids give you their card %s more often.", { per = 0.06, fmt = "pct" })
Def("hunter", 8, 3, "heads", 5, "Head Collection", "INV_Misc_Book_11", "Each card of a boss you find gives you %s rubies.", { per = 20, fmt = "num" })
Def("hunter", 9, 1, "beat", 5, "Beat", "Spell_Nature_SpiritWolf", "In a group, the elites and the bosses you defeat fill your booster bar %s more.", { per = 0.03, fmt = "pct" })
Def("hunter", 9, 2, "relics", 3, "Raid Relics", "INV_Enchant_ShardPrismaticLarge", "The cards found on the bosses of the raids come titanforged %s of the time.", { per = 0.03, fmt = "pct" })
Def("hunter", 9, 3, "sweep", 1, "Clean Sweep", "Ability_Whirlwind", "Every 10 elites or rares you defeat in the world fill your booster bar of the world with 50 points.", { choice = "h9" })
Def("hunter", 9, 3, "raider", 1, "Raider", "INV_Misc_Key_10", "A dungeon done (its last boss) in less than 45 minutes fills its bar with 50 points.", { choice = "h9" })
Def("hunter", 10, 1, "fortune", 5, "Fortunate Hunter", "INV_Misc_Coin_05", "The quests of the collector of dungeons, of raids and of PvP give you %s more rubies.", { per = 0.05, fmt = "pct" })
Def("hunter", 10, 2, "legendhead", 1, "Legendary Head", "INV_Misc_Head_Dragon_Red", "Once a week, a Price on its Head becomes legendary: the card of your target is given to you for sure when you defeat it (epic at most). The first time: an achievement and a title of prestige.", { limit = "week", capstone = true, ach = "tLegend" })
Def("hunter", 10, 3, "renown", 5, "Hunter's Renown", "INV_BannerPVP_01", "The achievements of the bestiary, of the dungeons and of the raids give %s more experience and rubies.", { per = 0.06, fmt = "pct" })

-- the Gambler (1.14.0, his word after his test: Jackpot, Loaded Dice and Flourish lowered to 1 %, 2 % and 1 % a rank. At
-- their most they gave a Gambler 2.4 times the thunderforged cards of the others, and a legendary card came thunderforged
-- 38 times as often; 1.4 times now, and 7 times for a legendary card with Jackpot: a jackpot stays a moment of its own)
Def("gambler", 1, 1, "rush", 5, "Adrenaline Rush", "Spell_Nature_Lightning", "The cards of your boosters give %s more experience, twice as much for an epic card or better.", { per = 0.02, fmt = "pct" })
Def("gambler", 1, 2, "stake", 5, "Opening Stake", "INV_Misc_Coin_01", "Your first booster of the day: a %s chance that one of its cards goes up a rarity (epic at most).", { per = 0.04, fmt = "pct" })
Def("gambler", 1, 3, "eye", 1, "Gambler's Eye", "INV_Misc_Eye_01", "At the innkeeper's bet, you see the rarity of one of the cards face down before you choose.")
Def("gambler", 2, 1, "displaybox", 5, "Display Chest", "INV_Crate_03", "A display you open holds one more booster %s of the time.", { per = 0.06, fmt = "pct" })
Def("gambler", 2, 2, "keyring", 5, "Key Ring", "INV_Misc_Key_04", "The keys of the cases cost %s fewer rubies.", { per = 0.03, fmt = "pct" })
Def("gambler", 2, 3, "cratenose", 5, "Nose for Cases", "INV_Crate_05", "The cases come %s more often.", { per = 0.06, fmt = "pct" })
Def("gambler", 3, 1, "double", 1, "Double or Nothing", "INV_Misc_Dice_02", "Active: bet your next booster: an even chance that it holds two more cards, or two fewer (one for a booster of a dungeon or a raid). Recharges in %s.", { cd = 12 * H, active = true })
Def("gambler", 3, 2, "jackpot", 5, "Jackpot", "INV_Misc_Gem_Ruby_01", "When a legendary or mythic card comes out of your booster, a %s chance that the whole booster becomes thunderforged.", { per = 0.01, fmt = "pct" })
Def("gambler", 3, 3, "hothand", 5, "Hot Hand", "Spell_Holy_SurgeOfLight", "After an epic card or better, your next two boosters: your chance of an epic card +%s.", { per = 0.02, fmt = "pct" })
Def("gambler", 4, 1, "relance", 3, "Raise", "INV_Misc_Dice_01", "Double or Nothing leans your way: one more card won (rank 1), one card fewer lost (rank 2), a 60 %% chance to win (rank 3).", { req = { "double" } })
Def("gambler", 4, 2, "streak", 5, "Winning Streak", "Spell_Holy_MindVision", "Each day, your first 5 boosters opened: a %s chance that one of their cards goes up a rarity (epic at most).", { per = 0.02, fmt = "pct" })
Def("gambler", 4, 3, "hightable", 1, "High Table", "INV_Misc_Coin_06", "The innkeeper's bet takes 3 copies instead of 2, but the card of the rarity above comes twice as often.", { choice = "g4" })
Def("gambler", 4, 3, "lowstake", 1, "Small Stake", "INV_Misc_Coin_03", "The innkeeper's bet takes one copy only, but one more card wins nothing.", { choice = "g4" })
Def("gambler", 5, 1, "loaded", 5, "Loaded Dice", "INV_Misc_Dice_02", "When your booster holds two cards of the same rarity, rare or better, a %s chance that one of them becomes thunderforged.", { per = 0.02, fmt = "pct" })
Def("gambler", 5, 2, "sore", 5, "Sore Loser", "Spell_Shadow_Curse", "When you lose the innkeeper's bet, a %s chance that he gives your stake back.", { per = 0.06, fmt = "pct" })
Def("gambler", 5, 3, "masterkey", 1, "Master Key", "INV_Misc_Key_15", "Once a week, a case opens without a key.", { limit = "week" })
Def("gambler", 6, 1, "flambe", 3, "Flambé", "Spell_Arcane_Blink", "Double or Nothing recharges in %s.", { vals = { 10 * H, 8 * H, 6 * H }, fmt = "dur", req = { "double" } })
Def("gambler", 6, 2, "flourish", 5, "Flourish", "Spell_Nature_CallStorm", "In your boosters, your epic cards and better: +%s chance to come thunderforged.", { per = 0.01, fmt = "pct" })
Def("gambler", 6, 3, "highroller", 1, "High Roller", "INV_Crate_04", "Double or Nothing can bet a whole display: three more boosters, or three fewer.", { choice = "g6" })
Def("gambler", 6, 3, "careful", 1, "Careful Player", "Spell_Holy_SealOfWisdom", "Double or Nothing makes you lose no card any more, but wins you one only.", { choice = "g6" })
Def("gambler", 7, 2, "wheel", 1, "Darkmoon Wheel", "INV_Misc_Ticket_Tarot_Stack_01", "Each day, spin the wheel: nothing (40 %%), 150 rubies (30 %%), a booster of a zone (22 %%), two boosters of a zone (6 %%) or a booster of a dungeon (2 %%). The first time it stops on the booster of a dungeon: an achievement and a title of prestige.", { limit = "day", active = true, capstone = true, ach = "tWheel" })
Def("gambler", 8, 1, "private", 1, "Private Table", "INV_Misc_Bag_11", "You can play two bets a day at the innkeepers.")
Def("gambler", 8, 2, "kitty", 5, "Kitty", "INV_Misc_Coin_08", "Each bet won at an innkeeper gives you %s rubies, each case opened %s.", { val = function(r) return 60 * r, 30 * r end })
Def("gambler", 8, 3, "cashback", 5, "Till Money", "INV_Misc_Coin_09", "A case that gives a card of its lowest rank gives you back %s of the price of a key.", { per = 0.06, fmt = "pct" })
Def("gambler", 9, 1, "darkmoon", 5, "Darkmoon Fortune", "Spell_Arcane_StarFire", "The Darkmoon Wheel stops less often on nothing: %s points fewer, moved to the boosters.", { per = 5, fmt = "num" })
Def("gambler", 9, 2, "nerves", 5, "Nerves of Steel", "Spell_Nature_UnyeildingStamina", "Double or Nothing: a %s chance that a bet lost costs nothing.", { per = 0.03, fmt = "pct" })
Def("gambler", 9, 3, "landplayer", 1, "Player of the Lands", "INV_Misc_Map_01", "Double or Nothing won on a booster of a zone: 100 rubies more.", { choice = "g9" })
Def("gambler", 9, 3, "lairplayer", 1, "Player of the Lairs", "INV_Misc_Key_10", "Double or Nothing won on a booster of a dungeon or a raid: one more card.", { choice = "g9" })
Def("gambler", 10, 1, "annuity", 5, "Gambler's Annuity", "INV_Misc_Coin_07", "Each week you open 50 boosters or more: %s rubies.", { per = 300, fmt = "num" })
Def("gambler", 10, 2, "grandgame", 1, "The Great Game", "Spell_Arcane_Arcane04", "Each week, your first booster opened has one chance in ten to become a booster of legend: 5 cards epic or better, one of them legendary. The first time: an achievement and a title of prestige.", { limit = "week", capstone = true, ach = "tGrand" })
Def("gambler", 10, 3, "thrills", 5, "Thrills", "INV_Enchant_EssenceMysticalLarge", "The thunderforged and titanforged cards of your boosters give %s more experience.", { per = 0.06, fmt = "pct" })

-- the Smuggler
Def("smuggler", 1, 1, "patter", 5, "Patter", "INV_Misc_Coin_01", "The reseller buys back your copies %s dearer.", { per = 0.04, fmt = "pct" })
Def("smuggler", 1, 2, "paperwork", 5, "Paperwork", "INV_Scroll_06", "A contract has a %s chance to give you back one of the cards you put in it.", { per = 0.02, fmt = "pct" })
Def("smuggler", 1, 3, "fence", 1, "Fence's Eye", "INV_Misc_Spyglass_01", "The tooltip of a card tells you what the reseller gives you for a copy, and what he sells it for.")
Def("smuggler", 2, 1, "handshake", 5, "Handshake", "Spell_Holy_SealOfWisdom", "A trade confirmed where both sides give something fills your booster bar of the world with %s points (once a day for each player, 5 players a day).", { per = 3, fmt = "num" })
Def("smuggler", 2, 2, "falsebottom", 5, "False Bottom", "INV_Misc_Gift_01", "A gift you make, once confirmed, gives you %s rubies (once a day).", { per = 25, fmt = "num" })
Def("smuggler", 2, 3, "tip", 1, "Tip-off", "INV_Letter_09", "Each day, among the cards the reseller sells, one is surely missing from your albums.")
Def("smuggler", 3, 1, "blackmarket", 1, "Black Market", "INV_Misc_Bag_10", "Active: the reseller brings out from under his counter a card you are missing, rare or epic, %s cheaper than its price. Recharges in %s.", { cd = 3 * 86400, active = true })
-- (31 October, the night, his word: the talents redone with what came: the wear, the enchanter, the contracts)
Def("smuggler", 3, 2, "fineprint", 5, "Fine Print", "INV_Hammer_09", "The card of your exchange contracts has a %s chance to come a step better than the average of what you gave.", { per = 0.04, fmt = "pct" })
Def("smuggler", 3, 3, "lionshare", 5, "Lion's Share", "INV_Crown_01", "The quests of the collector of contracts give you %s more rubies.", { per = 0.06, fmt = "pct" })
Def("smuggler", 4, 1, "backroom", 5, "Back Room", "INV_Misc_Bag_07", "Black Market: %s more off.", { per = 0.06, fmt = "pct", req = { "blackmarket" } })
Def("smuggler", 4, 2, "receiver", 5, "Receiver", "INV_Misc_Bag_09", "The reseller buys back your thunderforged and titanforged copies %s dearer.", { per = 0.1, fmt = "pct" })
Def("smuggler", 4, 3, "guildsmuggle", 1, "Guild Smuggling", "INV_Shirt_GuildTabard_01", "The trades with your guild do not count among the 5 players a day of Handshake, and give twice as much.", { choice = "s4" })
Def("smuggler", 4, 3, "farcommerce", 1, "Distant Trade", "INV_Misc_Ribbon_01", "A trade with a player you never traded with gives you 100 rubies (once a week).", { choice = "s4" })
Def("smuggler", 5, 1, "negotiator", 5, "Shrewd Negotiator", "INV_Misc_Gem_Sapphire_02", "The reseller sells you his thunderforged and titanforged cards %s cheaper.", { per = 0.04, fmt = "pct" })
Def("smuggler", 5, 2, "liquidation", 5, "Clearance", "INV_Crate_02", "When you sell 20 copies or more at once to the reseller, he pays you %s more for the whole lot.", { per = 0.03, fmt = "pct" })
Def("smuggler", 5, 3, "delivery", 1, "Special Delivery", "INV_Box_02", "Once a week, the reseller gives you an uncommon card you are missing.", { limit = "week" })
Def("smuggler", 6, 1, "pipeline", 3, "Pipeline", "INV_Misc_Note_06", "Black Market recharges in %s.", { vals = { 60 * H, 48 * H, 36 * H }, fmt = "dur", req = { "blackmarket" } })
Def("smuggler", 6, 2, "forger", 5, "Forger", "INV_Enchant_ShardPrismaticLarge", "Your contracts of thunderforged cards give a titanforged card %s of the time.", { per = 0.015, fmt = "pct" })
Def("smuggler", 6, 3, "philanthropist", 1, "Philanthropist", "Spell_Holy_Restoration", "Your gifts, once confirmed, fill your booster bar of the world with 20 points (once a day).", { choice = "s6" })
Def("smuggler", 6, 3, "toll", 1, "Right of Way", "INV_Misc_Coin_02", "Each trade confirmed gives you 10 rubies (5 trades a day).", { choice = "s6" })
Def("smuggler", 7, 2, "order", 1, "Special Order", "INV_Letter_09", "Each day, you can order from the reseller a card you are missing, epic at most, at its full price. The first time: an achievement and a title of prestige.", { limit = "day", active = true, capstone = true, ach = "tOrder" })
Def("smuggler", 8, 1, "profits", 5, "Profits", "INV_Misc_Coin_04", "Each card bought from the reseller gives you back %s of its price in rubies.", { per = 0.02, fmt = "pct" })
Def("smuggler", 8, 2, "harbor", 5, "Harbor Contacts", "INV_Misc_Book_04", "The reseller has %s more cards for sale each day.", { per = 1, fmt = "num" })
Def("smuggler", 8, 3, "pockets", 3, "Deep Pockets", "INV_Misc_Bag_08", "The guard of the week (past it, the rubies of the reseller and of the talents count for a quarter) is raised by %s.", { per = 0.1, fmt = "pct" })
Def("smuggler", 9, 1, "rebate", 5, "Rebate", "INV_Crate_03", "The displays bought with rubies cost %s less.", { per = 0.02, fmt = "pct" })
Def("smuggler", 9, 2, "goodname", 5, "Good Name", "Spell_Holy_SealOfWisdom", "The achievements of the trades, of the contracts and of the reseller give %s more experience and rubies.", { per = 0.06, fmt = "pct" })
Def("smuggler", 9, 3, "pawn", 1, "Pawnbroker", "INV_Misc_Bag_11", "A copy sold to the reseller can be bought back at the same price for 3 days.", { choice = "s9" })
Def("smuggler", 9, 3, "goldcontract", 1, "Golden Contract", "INV_Scroll_01", "Once a week, a contract of rare cards gives an epic thunderforged card.", { limit = "week", choice = "s9" })
Def("smuggler", 10, 1, "hoard", 5, "Hoard", "INV_Misc_Coin_09", "Each week, when you hold more than 20 000 rubies, you earn %s of them (300 at most for each rank).", { per = 0.003, fmt = "pct" })
Def("smuggler", 10, 2, "baron", 1, "Baron of Booty Bay", "INV_Jewelry_Ring_03", "Once a week, the reseller lets you have a card of his stall (rare at most) at the price he buys it back. The first time: an achievement and a title of prestige.", { limit = "week", capstone = true, ach = "tBaron" })
Def("smuggler", 10, 3, "ledger", 5, "Ledger", "INV_Misc_Book_06", "The rubies of your levels and of your quests of the month: +%s.", { per = 0.03, fmt = "pct" })

-- the Archivist
Def("archivist", 1, 1, "steady", 5, "Steady Hand", "INV_Misc_Spyglass_03", "At each appraisal, a %s chance that the expert raises one of its four grades by a point.", { per = 0.03, fmt = "pct" })
Def("archivist", 1, 2, "colleague", 5, "Colleague's Rate", "INV_Misc_Coin_03", "The appraisal of your cards costs %s fewer rubies.", { per = 0.03, fmt = "pct" })
Def("archivist", 1, 3, "signature", 1, "Archivist's Signature", "INV_Scroll_03", "Your appraised cards bear your name on their label, seen by the other collectors in your showcase.")
Def("archivist", 2, 1, "goldfinger", 5, "Golden Fingers", "Trade_Engraving", "The odds of the enchanters on the flaws of your copies: +%s.", { per = 0.04, fmt = "pct" })
Def("archivist", 2, 2, "pact", 5, "Sealed Pact", "Spell_Shadow_SoulGem", "The seals of the Master Warlocks have a %s chance to go up a rank.", { per = 0.03, fmt = "pct" })
Def("archivist", 2, 3, "sleeves", 3, "Card Sleeves", "INV_Misc_Book_09", "The cards that come to you (boosters, creatures, cases) have a %s chance to come in a grade better.", { per = 0.03, fmt = "pct" })
Def("archivist", 3, 1, "glance", 1, "Glance", "INV_Misc_Eye_01", "Active: before you appraise a copy, you see the grade it would get, and you can give up without paying. Recharges in %s.", { cd = 12 * H, active = true })
Def("archivist", 3, 2, "patience", 5, "Enchanter's Patience", "Spell_Nature_TimeStop", "The enchanters work on your copies %s faster.", { per = 0.08, fmt = "pct" })
Def("archivist", 3, 3, "purifier", 5, "Purifier", "Spell_Holy_Purify", "The purifications of the Master Priests cost %s fewer rubies.", { per = 0.06, fmt = "pct" })
Def("archivist", 4, 1, "glance2", 4, "Trained Eye", "INV_Misc_Spyglass_02", "Glance recharges in %s.", { vals = { 10 * H, 9 * H, 8 * H, 6 * H }, fmt = "dur", req = { "glance" } })
Def("archivist", 4, 2, "perfectionist", 5, "Perfectionist", "INV_Misc_Gem_Diamond_01", "When an appraisal gives a 9, a %s chance that it is a 10.", { per = 0.01, fmt = "pct" })
Def("archivist", 4, 3, "museum", 1, "Museum Showcase", "INV_Misc_Book_11", "Your showcase shows two more cards.", { choice = "a4" })
Def("archivist", 4, 3, "luxury", 1, "Luxury Case", "INV_Jewelry_Ring_03", "Your cards appraised 9 and 10 get a golden case, seen by everyone.", { choice = "a4" })
Def("archivist", 5, 1, "catalog", 5, "Catalogue", "INV_Misc_Book_04", "Each card appraised gives you %s experience, three times as much for a 9 or a 10.", { per = 30, fmt = "num" })
Def("archivist", 5, 2, "casing", 5, "Reinforced Case", "INV_Box_02", "The protective cases cost %s fewer rubies.", { per = 0.1, fmt = "pct" })
Def("archivist", 5, 3, "freerestore", 3, "Restoration Offered", "Trade_Engraving", "Once a week, a restoration for nothing: up to 8 flaws (rank 1), 16 (rank 2), 30 (rank 3).", { limit = "week" })
Def("archivist", 6, 1, "glance3", 2, "Certified Expert", "INV_Misc_Spyglass_03", "Glance also shows the four grades (rank 1), then tells the true grade of a restored copy without paying its appraisal again (rank 2).", { req = { "glance" } })
Def("archivist", 6, 2, "innfriend", 5, "Friend of the Innkeepers", "INV_Drink_04", "A stamp of your loyalty card has a %s chance to count twice for the loyalty of its innkeeper (and his signed card).", { per = 0.1, fmt = "pct" })
Def("archivist", 6, 3, "weekpact", 1, "Pact of the Week", "Spell_Shadow_Twilight", "Once a week, a seal costs half its price.", { limit = "week", choice = "a6" })
Def("archivist", 6, 3, "favored", 1, "Favored Client", "INV_Misc_Coin_05", "Once a day, an appraisal costs half its price.", { limit = "day", choice = "a6" })
Def("archivist", 7, 2, "masterpiece", 1, "Masterpiece", "INV_Enchant_ShardBrilliantLarge", "Once a week, a master's restoration: every flaw he works on is mended, not one missed nor marked. The first time a copy reaches 10 that way: an achievement and a title of prestige.", { limit = "week", capstone = true, ach = "tChef" })
Def("archivist", 8, 1, "renowned", 5, "Renowned Expert", "INV_Misc_Gem_Pearl_01", "Each card appraised 8 or better gives you %s rubies.", { per = 30, fmt = "num" })
Def("archivist", 8, 2, "grandseal", 5, "Grand Seal", "Spell_Shadow_GatherShadows", "Your chance of a seal IX or X: +%s.", { per = 0.06, fmt = "pct" })
Def("archivist", 8, 3, "gallery", 1, "Gallery", "INV_Misc_Note_01", "Each collector who looks at your showcase gives you 5 rubies (20 visitors a day at most).")
Def("archivist", 9, 1, "restorer", 5, "Restorer", "INV_Enchant_EssenceMysticalLarge", "A flaw the enchanter misses: a %s chance he tries it again.", { per = 0.06, fmt = "pct" })
Def("archivist", 9, 2, "archives", 5, "Archives", "INV_Scroll_05", "The achievements of the expertise, of the seals and of the restorations give %s more experience and rubies.", { per = 0.06, fmt = "pct" })
Def("archivist", 9, 3, "goldloupe", 1, "Golden Loupe", "INV_Misc_Gem_Bloodstone_01", "Glance also works on the seals: you see their rank before you pay.", { choice = "a9" })
Def("archivist", 9, 3, "familyseal", 1, "Family Seal", "Spell_Shadow_DetectLesserInvisibility", "Once a week, a seal costs nothing.", { limit = "week", choice = "a9" })
Def("archivist", 10, 1, "patron", 5, "Patron of the Arts", "INV_Misc_Gem_Ruby_03", "Each week, your best appraised copy gives you %s rubies (three times as many for a 10).", { per = 60, fmt = "num" })
Def("archivist", 10, 2, "conservator", 1, "Grand Conservator", "Spell_Holy_MindSooth", "Once a week, an appraisal is made twice and the better grade is kept. The first time it gives a 10: an achievement and a title of prestige.", { limit = "week", capstone = true, ach = "tConserv" })
Def("archivist", 10, 3, "prestige", 5, "Prestige", "INV_Crown_01", "The achievements of the collection (albums complete, rarities) give %s more rubies.", { per = 0.06, fmt = "pct" })

-- the talents of each specialization, in their order; the choices: [key] = { the two talents }
TL.TREE = {}
TL.CHOICES = {}
for _, t in ipairs(TL.LIST) do
	TL.TREE[t.spec] = TL.TREE[t.spec] or {}
	CuratorOctoFull.Insert(TL.TREE[t.spec], t)
	if t.choice then
		local key = t.spec .. "|" .. t.choice
		t.choiceKey = key
		TL.CHOICES[key] = TL.CHOICES[key] or {}
		CuratorOctoFull.Insert(TL.CHOICES[key], t)
	end
end

-- The two talents of a choice (the one given and the other one).
function TL.ChoiceOf(d)
	return d and d.choiceKey and TL.CHOICES[d.choiceKey] or nil
end

-- The most points each tier of a tree can hold (of a choice, its larger talent), and the ranks of each tree.
TL.HOLD = {}
TL.RANKS = {}
do
	local pick = {}
	for _, t in ipairs(TL.LIST) do
		local hold = TL.HOLD[t.spec] or {}
		TL.HOLD[t.spec] = hold
		local before = t.choice and (pick[t.choiceKey] or 0) or 0
		local add = t.choice and math.max(0, t.ranks - before) or t.ranks
		if t.choice then
			pick[t.choiceKey] = math.max(before, t.ranks)
		end
		hold[t.tier] = (hold[t.tier] or 0) + add
		TL.RANKS[t.spec] = (TL.RANKS[t.spec] or 0) + add
	end
end

-- The points a tier asks, spent in the tier above it (none for the first): TL.TIER_NEED, or all that tier holds when
-- it holds fewer (the seventh: its one talent). Without a tree: of them all, the least.
function TL.Gate(tier, spec)
	if tier <= 1 then
		return 0
	end
	local hold = spec and TL.HOLD[spec] and TL.HOLD[spec][tier - 1]
	if not hold then
		for _, h in pairs(TL.HOLD) do
			hold = math.min(hold or CuratorOctoFull.Huge, h[tier - 1] or 0)
		end
	end
	return math.min(TL.TIER_NEED, hold or 0)
end

-------------------------------------------------------------------------------
-- The state of the account
-------------------------------------------------------------------------------
local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end
TL.Now = Now

local function State()
	local db = ns.db
	if not db then
		return nil
	end
	local t = db.talents
	if type(t) ~= "table" then
		t = {}
		db.talents = t
	end
	if type(t.ranks) ~= "table" then
		t.ranks = {}
	end
	if type(t.cd) ~= "table" then
		t.cd = {}
	end
	return t
end
TL.State = State

-- The specialization chosen (its key), nil before.
function TL:Spec()
	local t = ns.db and ns.db.talents
	local key = type(t) == "table" and t.spec or nil
	return self.SPEC_BY[key or ""] and key or nil
end

function TL:SpecDef(key)
	return self.SPEC_BY[key or self:Spec() or ""]
end

-- Its name (female: the name of a female character, in the languages that make one).
function TL:SpecName(key, female)
	local s = self.SPEC_BY[key or ""]
	if not s then
		return nil
	end
	if female then
		local fk = s.name .. "#f"
		local v = L[fk]
		if v ~= fk then
			return v
		end
	end
	return L[s.name]
end

function TL:Female()
	return ns.Achievements and ns.Achievements:Female() or false
end

-- The level of the collector.
function TL:Level()
	return ns.Level and ns.Level:Level() or 1
end

-- The points: the first at the level the specialization is chosen at, then one for each level up to the legend (56
-- at level 60), then one every two levels (76 at level 100).
function TL:Points(level)
	level = level or self:Level()
	if level < self.CHOOSE then
		return 0
	end
	local legend = (ns.Level and ns.Level.LEGEND) or 60
	if level <= legend then
		return level - self.CHOOSE + 1
	end
	return legend - self.CHOOSE + 1 + math.floor((level - legend) / 2)
end

-- The level the specialization is chosen at is reached.
function TL:CanChoose()
	return self:Level() >= self.CHOOSE
end

-- The level past the legend is reached (the tiers past it open with it).
function TL:PastLegend()
	local LV = ns.Level
	return self:Level() > ((LV and LV.LEGEND) or 60)
end

-- The level the tiers past the legend open at.
function TL:LegendLevel()
	local LV = ns.Level
	return ((LV and LV.LEGEND) or 60) + 1
end

-- The ranks applied (a copy can be passed to the functions that take ranks).
function TL:Ranks()
	local t = ns.db and ns.db.talents
	return (type(t) == "table" and type(t.ranks) == "table") and t.ranks or {}
end

-- The points spent (in a table of ranks; the ranks applied by default).
function TL:Spent(ranks)
	local n = 0
	for id, r in pairs(ranks or self:Ranks()) do
		if self.BY[id] then
			n = n + (tonumber(r) or 0)
		end
	end
	return n
end

-- The rank of a talent: applied, and of the specialization chosen (0 else).
function TL:Rank(id)
	local d = self.BY[id]
	if not d or d.spec ~= self:Spec() then
		return 0
	end
	return math.max(0, math.min(d.ranks, math.floor(tonumber(self:Ranks()[id]) or 0)))
end

function TL:Has(id)
	return self:Rank(id) > 0
end

-- The value of a talent at a rank (the rank it has by default; 0 without it).
function TL:Value(id, rank)
	local d = self.BY[id]
	rank = rank or self:Rank(id)
	if not d or rank <= 0 then
		return 0
	end
	if d.vals then
		return d.vals[math.min(rank, CuratorOctoFull.Length(d.vals))]
	elseif d.fixed then
		return d.fixed
	elseif d.per then
		return (d.base or 0) + d.per * rank
	end
	return 1
end

function TL:V(id)
	return self:Value(id)
end

-- (31 October) Card Sleeves: a card that comes (a copy, a card of a case), a grade better now and then, 10 at most.
function TL:Sleeves(g)
	g = tonumber(g)
	if g and g < 10 and self:Has("sleeves") and math.random() < self:V("sleeves") then
		return g + 1
	end
	return g
end

-- (31 October) Fine Print: the card of a contract, a step better than the average of what was given now and then.
function TL:FinePrint()
	return self:Has("fineprint") and math.random() < self:V("fineprint")
end

-- "+15 %", "1,4", "30 min": a value as a talent writes it.
function TL:Format(d, v)
	if d.fmt == "pct" then
		return ns.Pct(v)
	elseif d.fmt == "dec" then
		v = math.floor(v * 10 + 0.5) / 10
		local s = (v == math.floor(v)) and tostring(math.floor(v)) or string.format(("%.1f"), v)
		return (string.gsub(s, "%.", L["."]))
	elseif d.fmt == "dur" then
		return ns.Duration(v)
	end
	return ns.Num(v)
end

-- What a talent does at a rank (0: as it is at its first rank). An active one: its time and its recharge.
function TL:Text(id, rank)
	local d = self.BY[id]
	if not d then
		return ""
	end
	rank = math.max(1, rank or 1)
	if id == "survey" then
		return string.format(L[d.desc], ns.Duration(self:SurveyTime()), ns.Duration(self:Cooldown(id)))
	elseif id == "mark" then
		return string.format(L[d.desc], ns.Duration(self:MarkTime()), ns.Duration(self:Cooldown(id)))
	elseif id == "blackmarket" then
		return string.format(L[d.desc], ns.Pct(self:BlackMarketOff()), ns.Duration(self:Cooldown(id)))
	elseif d.cd then
		return string.format(L[d.desc], ns.Duration(self:Cooldown(id)))
	end
	if d.val then
		local a, b = d.val(rank)
		return string.format(L[d.desc], ns.Num(a), ns.Num(b))
	end
	if d.fmt then
		return string.format(L[d.desc], self:Format(d, self:Value(id, rank)))
	end
	return (string.gsub(L[d.desc], "%%%%", "%%"))
end

function TL:Name(id)
	local d = self.BY[id]
	return d and L[d.name] or "?"
end

-- The icon of a talent (one the game may not have: a question mark).
function TL:Icon(d)
	local icon = d and d.icon
	if icon and GetFileIDFromPath then
		local ok, id = pcall(GetFileIDFromPath, icon)
		if ok and not id then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end
	end
	return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-------------------------------------------------------------------------------
-- The rules of a placement of points
-------------------------------------------------------------------------------
-- The points spent in the tiers under a tier.
local function Below(ranks, spec, tier)
	local n = 0
	for id, r in pairs(ranks) do
		local d = TL.BY[id]
		if d and d.spec == spec and d.tier < tier then
			n = n + (tonumber(r) or 0)
		end
	end
	return n
end
TL.Below = Below

-- The points spent in a tier.
local function InTier(ranks, spec, tier)
	local n = 0
	for id, r in pairs(ranks) do
		local d = TL.BY[id]
		if d and d.spec == spec and d.tier == tier then
			n = n + (tonumber(r) or 0)
		end
	end
	return n
end
TL.InTier = InTier

-- Is a tier of a tree open with these ranks? false and why: "tier" (the points of a tier above it), "legend" (a tier
-- past the legend, the level past it not reached); and the tier that holds it back.
function TL:TierOpen(ranks, spec, tier)
	if tier >= self.LEGEND_TIER and not self:PastLegend() then
		return false, "legend", tier
	end
	for t = 2, tier do
		if InTier(ranks, spec, t - 1) < self.Gate(t, spec) then
			return false, "tier", t
		end
	end
	return true
end

-- Can these ranks be the placement of a specialization with these points? false and why.
function TL:Valid(ranks, spec, points)
	spec = spec or self:Spec()
	points = points or self:Points()
	if not self.SPEC_BY[spec or ""] then
		return false, "spec"
	end
	local total = 0
	for id, r in pairs(ranks) do
		local d = self.BY[id]
		if type(r) ~= "number" or r < 0 or r ~= math.floor(r) then
			return false, "rank"
		end
		if r > 0 then
			if not d or d.spec ~= spec then
				return false, "spec"
			end
			if r > d.ranks then
				return false, "rank"
			end
			total = total + r
			local open, why = self:TierOpen(ranks, spec, d.tier)
			if not open then
				return false, why
			end
			if d.choice then
				for _, o in ipairs(TL.ChoiceOf(d)) do
					if o ~= d and (ranks[o.id] or 0) > 0 then
						return false, "choice"
					end
				end
			end
			if d.req then
				local ok = false
				for _, need in ipairs(d.req) do
					if (ranks[need] or 0) > 0 then
						ok = true
					end
				end
				if not ok then
					return false, "req"
				end
			end
		end
	end
	if total > points then
		return false, "points"
	end
	return true
end

local function Copy(t)
	local out = {}
	for k, v in pairs(t or {}) do
		out[k] = v
	end
	return out
end
TL.Copy = Copy

-- One point more in a talent (in a placement being made): false and why it cannot be.
function TL:CanAdd(ranks, id, spec)
	local d = self.BY[id]
	spec = spec or self:Spec()
	if not d or d.spec ~= spec then
		return false, "spec"
	end
	if (ranks[id] or 0) >= d.ranks then
		return false, "max"
	end
	local try = Copy(ranks)
	try[id] = (try[id] or 0) + 1
	return self:Valid(try, spec)
end

-- One point less (only a point placed and not applied yet comes off).
function TL:CanRemove(ranks, id, base)
	local r = ranks[id] or 0
	if r <= ((base or self:Ranks())[id] or 0) then
		return false, "applied"
	end
	local try = Copy(ranks)
	try[id] = r - 1
	if try[id] == 0 then
		try[id] = nil
	end
	return self:Valid(try)
end

-------------------------------------------------------------------------------
-- The placement being made (the talent page): points added and taken back before they are applied
-------------------------------------------------------------------------------
function TL:Pending()
	if not self.pending or self.pendingSpec ~= self:Spec() then
		self.pending = Copy(self:Ranks())
		self.pendingSpec = self:Spec()
	end
	return self.pending
end

-- Points placed and not applied yet.
function TL:PendingCount()
	if not self.pending then
		return 0
	end
	return self:Spent(self.pending) - self:Spent()
end

function TL:AddPoint(id)
	local p = self:Pending()
	local ok, why = self:CanAdd(p, id)
	if not ok then
		return false, why
	end
	p[id] = (p[id] or 0) + 1
	ns.Fire("TALENTS_PENDING")
	return true
end

function TL:RemovePoint(id)
	local p = self:Pending()
	local ok, why = self:CanRemove(p, id)
	if not ok then
		return false, why
	end
	p[id] = p[id] - 1
	if p[id] == 0 then
		p[id] = nil
	end
	ns.Fire("TALENTS_PENDING")
	return true
end

function TL:Cancel()
	self.pending = nil
	ns.Fire("TALENTS_PENDING")
end

-- The points placed become the talents of the account (for good, until a reconversion).
function TL:Apply()
	local t = State()
	local p = self.pending
	if not (t and p and self:Spec()) or self:PendingCount() <= 0 then
		return false
	end
	if not self:Valid(p) then
		return false
	end
	for id, r in pairs(t.ranks) do
		if (p[id] or 0) < r then
			-- (an applied point never comes off here)
			return false
		end
	end
	t.ranks = Copy(p)
	self.pending = nil
	ns.Fire("TALENTS_CHANGED")
	ns.Fire("CHANGED")
	return true
end

-- The first specialization: chosen for good (free).
function TL:Choose(key)
	local t = State()
	if not t or t.spec or not self.SPEC_BY[key or ""] or not self:CanChoose() then
		return false
	end
	t.spec, t.chosen, t.ranks = key, Now(), {}
	self.pending = nil
	ns.Fire("TALENTS_CHANGED")
	ns.Fire("CHANGED")
	return true
end

-------------------------------------------------------------------------------
-- The contract of reconversion
-------------------------------------------------------------------------------
-- The step of the price: the reconversions made, less one for each month without one.
function TL:RespecStep()
	local t = State()
	if not t then
		return 0
	end
	local n = tonumber(t.respecs) or 0
	local since = Now() - (tonumber(t.respecAt) or 0)
	n = n - math.floor(math.max(0, since) / self.RESPEC_DECAY)
	return math.max(0, math.min(self.RESPEC_STEPS, n))
end

-- Its price (the first one offered: nothing; step given: the price of that step, offered or not).
function TL:RespecCost(step)
	if step == nil and self:FreeRespec() then
		return 0
	end
	local base = self.RESPEC_BASE * 2 ^ (step or self:RespecStep())
	return ns.Rubies and ns.Rubies:Price(base, "respec") or base
end

-- (1.14.0) The first reconversion of a collection with a specialization: offered (every tree is new). It does not raise
-- the price of the next one. (1.12.0 offered one too, to the specializations of before: "1.12.0", the mark of then.)
TL.FREE_RESPEC = "1.14.0"
function TL:FreeRespec()
	local t = ns.db and ns.db.talents
	return type(t) == "table" and self.SPEC_BY[t.spec or ""] ~= nil and t.freeRespec ~= self.FREE_RESPEC
end

-- When the price comes down a step (nil: it is as low as it goes).
function TL:RespecDown()
	local t = State()
	local step = self:RespecStep()
	if not t or step <= 0 then
		return nil
	end
	local since = Now() - (tonumber(t.respecAt) or 0)
	return self.RESPEC_DECAY - CuratorOctoFull.Mod(math.max(0, since) , self.RESPEC_DECAY)
end

-- A reconversion: its rubies paid, the points free again, the specialization chosen (the same one: the points placed
-- again). True and the rubies paid, or false and why ("spec", "rubies", "closed").
function TL:Respec(key)
	local t = State()
	if not (t and t.spec) then
		return false, "spec"
	end
	if not self.SPEC_BY[key or ""] then
		return false, "spec"
	end
	local free = self:FreeRespec()
	local total = self:RespecCost()
	if not ns.Rubies then
		return false, "rubies"
	end
	local paid, why = ns.Rubies:Spend(total, "respec")
	if not paid then
		return false, why
	end
	if free then
		t.freeRespec = self.FREE_RESPEC
	else
		local step = self:RespecStep()
		t.respecs = math.min(self.RESPEC_STEPS, step + 1)
		t.respecAt = Now()
		t.paid = (tonumber(t.paid) or 0) + total
	end
	local old = t.spec
	t.spec, t.ranks = key, {}
	t.armed = nil
	t.survey, t.expedition, t.mark = nil, nil, nil
	self.pending = nil
	ns.Fire("TALENTS_CHANGED")
	ns.Fire("TALENTS_RESPEC", old, key, total)
	ns.Fire("CHANGED")
	return true, total
end

-------------------------------------------------------------------------------
-- What is counted by day and by week (the day and the week of the server), the recharges
-------------------------------------------------------------------------------
-- The seconds until the daily reset, as the server tells them (nil: it does not).
local function ServerDayLeft()
	local D = C_DateAndTime
	if D and D.GetSecondsUntilDailyReset then
		local ok, left = pcall(D.GetSecondsUntilDailyReset)
		if ok and type(left) == "number" and not (issecretvalue and issecretvalue(left)) and left > 0 and left <= 86400 then
			return left
		end
	end
	return nil
end

-- A period of the talents (the day, the week): a table with its end (e). The end the server tells: a period further
-- on by more than half of one is a new one. When it tells none, the end kept holds until it is past, then the next one
-- comes in the same rhythm.
local function Period(t, field, told, span)
	local now = Now()
	local p = t[field]
	if type(p) ~= "table" or type(p.e) ~= "number" then
		p = { e = told or ((math.floor(now / span) + 1) * span) }
		t[field] = p
	elseif told then
		if told > p.e + span / 2 then
			p = { e = told }
			t[field] = p
		end
	elseif now >= p.e then
		p = { e = p.e + span * (math.floor((now - p.e) / span) + 1) }
		t[field] = p
	end
	return p
end

-- The seconds until the day of the talents ends.
function TL:UntilDay()
	local left = ServerDayLeft()
	if left then
		return left
	end
	local d = self:Day()
	return math.max(1, d.e - Now())
end

function TL:Day()
	local left = ServerDayLeft()
	return Period(State(), "day", left and (Now() + left) or nil, 86400)
end

-- The week: its end as the quests know it.
function TL:Week()
	return Period(State(), "week", ns.Quests and ns.Quests:Key("week") or nil, 604800)
end

-- The recharge of an active talent (with the talents that shorten it).
function TL:Cooldown(id)
	local d = self.BY[id]
	if not (d and d.cd) then
		return 0
	end
	local shorter = { survey = "survey3", mark = "mark3", double = "flambe", blackmarket = "pipeline", glance = "glance2" }
	local by = shorter[id]
	if by and self:Has(by) then
		return self:V(by)
	end
	return d.cd
end

-- Seconds before an active talent (or one of the day or of the week) can be used again (0: now).
function TL:Left(id)
	local d = self.BY[id]
	local t = State()
	if not (d and t) then
		return 0
	end
	if d.cd then
		return math.max(0, (tonumber(t.cd[id]) or 0) - Now())
	elseif d.limit == "day" then
		return self:Day()[id] and math.max(1, self:UntilDay()) or 0
	elseif d.limit == "week" then
		return self:Week()[id] and math.max(1, self:Week().e - Now()) or 0
	end
	return 0
end

-- Learned and ready.
function TL:Ready(id)
	return self:Has(id) and self:Left(id) <= 0
end

-- Used: its recharge starts (of the day, of the week: until the next one).
function TL:Use(id)
	local d = self.BY[id]
	local t = State()
	if not (d and t) or not self:Ready(id) then
		return false
	end
	if d.cd then
		t.cd[id] = Now() + self:Cooldown(id)
	elseif d.limit == "day" then
		self:Day()[id] = true
	elseif d.limit == "week" then
		self:Week()[id] = true
	end
	if t.armed then
		t.armed[id] = nil
	end
	ns.Fire("TALENT_USED", id)
	return true
end

-- Armed for the next use (Double or Nothing on the next booster).
function TL:Armed(id)
	local t = ns.db and ns.db.talents
	return type(t) == "table" and type(t.armed) == "table" and t.armed[id] == true and self:Ready(id)
end

function TL:Arm(id, on)
	local t = State()
	if not t or (on and not self:Ready(id)) then
		return false
	end
	t.armed = t.armed or {}
	t.armed[id] = on and true or nil
	ns.Fire("TALENT_ARMED", id, on)
	return true
end

-- A summit worked for the first time: its achievement (its count in the stats, Achievements.lua).
function TL:Summit(id)
	local d = self.BY[id]
	if not (d and d.ach and ns.db) then
		return
	end
	local st = ns.Stats()
	if not st[d.ach] then
		st[d.ach] = true
		if ns.Achievements and ns.Achievements.Queue then
			ns.Achievements:Queue()
		end
	end
end

-- Rubies from a talent (id: its key, told to the ones who listen). A reroll: in its chest (Reroll.lua).
function TL:Rubies(n, id)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 or not ns.Rubies then
		return 0
	end
	local got = ns.Rubies:Gain(n, "talent", { talent = id })
	if got > 0 then
		ns.Fire("TALENT_RUBIES", id, got)
	end
	return got
end

-- Experience from a talent.
function TL:XP(n)
	n = math.floor(tonumber(n) or 0)
	if n > 0 and ns.Level then
		return ns.Level:Gain(n, "talent")
	end
	return 0
end

-- What follows, once nothing that is being shown would be told by it (a booster whose cards are saved before they are
-- shown, an appraisal before its verdict).
function TL:Later(fn)
	local B, XU = ns.Booster, ns.ExpertiseUI
	if (B and B.frame and B.frame:IsShown() and B.state ~= "done") or (XU and (XU.cer or XU.busy)) then
		ns.Delay(1, function()
			TL:Later(fn)
		end, TL)
		return
	end
	fn()
end

function TL:CountKeys(t)
	local n = 0
	for _ in pairs(t or {}) do
		n = n + 1
	end
	return n
end

-- The hours of the night on the clock of the player.
function TL:Night()
	local h = tonumber(date and date("%H") or nil)
	if not h then
		return false
	end
	return h >= self.NIGHT_FROM or h < self.NIGHT_TO
end

local function Roll()
	return (TL.random or math.random)()
end
TL.Roll = Roll

local function InGroup()
	if IsInGroup then
		local ok, yes = pcall(IsInGroup)
		return ok and yes == true
	end
	return false
end
TL.InGroup = InGroup

-- Inside a dungeon, a raid or a battleground.
local function InInstance()
	if IsInInstance then
		local ok, inside = pcall(IsInInstance)
		return ok and inside == true
	end
	return false
end
TL.InInstance = InInstance

-- The share of the cards of an album the collection has.
local function Share(s)
	if not (s and s.list and CuratorOctoFull.Length(s.list) > 0) then
		return 0
	end
	local owned = ns.Collection:Progress(s)
	return owned / (s.official or CuratorOctoFull.Length(s.list))
end
TL.Share = Share

-- A card the collection is missing (and not waiting in the chest of this reroll).
local function Missing(card)
	if not card or ns.Collection:Owned(card) then
		return false
	end
	local RR = ns.Reroll
	return not (RR and RR:IsReroll() and RR:Holds(card))
end
TL.Missing = Missing

-------------------------------------------------------------------------------
-- The bars of the boosters (Rewards.lua)
-------------------------------------------------------------------------------
-- (the points of what the player does: the talents of the bars count them, not those of the quests of the collector or
-- of other talents)
local PLAY = { kill = true, objective = true, quest = true, explore = true, level = true, boss = true, dungeon = true, raid = true, gather = true }
TL.PLAY = PLAY
-- (the points of the world the Field Notebook counts)
local NOTEBOOK = { explore = true, objective = true, quest = true }

-- The points of a bar: the world ("world") or the dungeons and the raids ("dungeon"). ctx: { s (the album of the
-- place), level (the level of the creature defeated, for a kill), elite, boss, raid, group, night, hour (the first
-- hour of the day of play) } (the page of the statistics gives a situation; nil: as it is now).
function TL:BarPoints(points, reason, kind, ctx)
	local spec = self:Spec()
	if not spec or not PLAY[reason or ""] then
		return points
	end
	ctx = ctx or {}
	local k = 1
	if spec == "carto" and kind == "world" then
		if NOTEBOOK[reason] then
			k = k + self:V("fieldbook")
		end
		local s = ctx.s
		if s == nil and ns.Rewards then
			s = ns.Rewards:WorldSeries()
		end
		if s and not s.dungeon then
			if self:Has("trails") and Share(s) < 0.5 then
				k = k + self:V("trails")
			end
			if self:Has("homeland") and self:Homeland(s) then
				k = k + self:V("homeland")
			end
			if self:Has("nomad") and self.nomad == s.key then
				k = k + self:V("nomad")
			end
		end
		if reason == "kill" and self:Has("seasoned") then
			local lv = ctx.level
			local me = UnitLevel and UnitLevel("player")
			if type(lv) == "number" and type(me) == "number" and (lv < 0 or lv >= me) then
				k = k + self:V("seasoned")
			end
		end
		local hour = ctx.hour
		if hour == nil then
			hour = self:FirstHour()
		end
		if self:Has("dew") and hour then
			k = k + self:V("dew")
		end
		-- (Starry Night: during Survey, the night of the player, the points doubled)
		local night = ctx.night
		if night == nil then
			night = self:Night()
		end
		if self:Has("starry") and night and self:SurveyLeft() > 0 then
			k = k * 2
		end
	elseif spec == "hunter" then
		local group = ctx.group
		if group == nil then
			group = InGroup()
		end
		if group and (ctx.elite or ctx.boss) then
			k = k + self:V("beat")
		end
		if ctx.boss and ctx.raid and self:Has("dragonslayer") then
			k = k + self:V("dragonslayer")
		end
		-- (1.14.0: Delver, the bosses of the dungeons; Elite Stalker, the elites of the world)
		if ctx.boss and not ctx.raid and self:Has("delver") then
			k = k + self:V("delver")
		end
		if kind == "world" and reason == "kill" and ctx.elite and not ctx.boss and self:Has("stalker") then
			k = k + self:V("stalker")
		end
	end
	return points * k
end

-- An elite of a dungeon or a raid: its points (Regular of the Depths).
function TL:ElitePoints(points, dungeon)
	if dungeon and self:Has("deep") then
		return points + self:V("deep")
	end
	return points
end

-- A boss of a dungeon or a raid: its points (Hunting Tally).
function TL:BossPoints(points)
	return points + self:V("tally")
end

-- (the last boss: its points, the bosses' rule)
function TL:FinalPoints(points)
	return points
end

-- A quest turned in, in the album of the place: its points (Road Book: the first of the day there).
function TL:QuestPoints(points, s)
	if not (s and self:Has("roadbook")) then
		return points
	end
	local d = self:Day()
	d.road = type(d.road) == "table" and d.road or {}
	if d.road[s.key] then
		return points
	end
	d.road[s.key] = true
	return points + self:V("roadbook")
end

-- The boosters a day of the dungeons and the raids (no talent changes them).
function TL:DailyMax(base)
	return base
end

function TL:FirstClearBoosters()
	return 1
end

function TL:WorldBoosters()
end

-- The hearthstone of this character: in the album of this zone. Its home inn known (Tavern.lua: the innkeeper it was
-- bound at), the album of that inn; else the name the game gives the place it is bound to, seen in the zone.
function TL:Homeland(s)
	if not s then
		return false
	end
	local T, I = ns.Tavern, ns.Inns
	local npc = (T and T.Home) and T:Home() or nil
	if npc and I and I.Album then
		local home = I:Album(npc)
		if home then
			return home == s
		end
	end
	local c = ns.Rewards and ns.Rewards:Char()
	return c ~= nil and c.hearth == s.key
end

-- A zone entered (Rewards.lua: PLACE_CHANGED): the hearthstone seen, the zones not played in for a while (Nomad), what
-- the album misses (Compass), the run of a dungeon (Raider).
function TL:Entered(s)
	local t = State()
	if not t then
		return
	end
	local now = Now()
	-- (the zone left: its time kept)
	if self.here then
		t.seen = type(t.seen) == "table" and t.seen or {}
		t.seen[self.here] = now
	end
	self.here = s and s.key or nil
	self.nomad = nil
	if not s then
		return
	end
	if s.dungeon then
		if not s.raid then
			self.run = { k = s.key, t = (GetTime and GetTime()) or 0 }
		end
		return
	end
	t.seen = type(t.seen) == "table" and t.seen or {}
	local last = tonumber(t.seen[s.key])
	if not last or now - last >= self.NOMAD_AFTER then
		self.nomad = s.key
	end
	t.seen[s.key] = now
	-- (the hearthstone: its place named as the zone or one of its parts)
	local bind = GetBindLocation and GetBindLocation()
	if type(bind) == "string" and bind ~= "" then
		local names = {}
		for _, fn in ipairs({ GetZoneText, GetRealZoneText, GetSubZoneText, GetMinimapZoneText }) do
			if fn then
				local ok, n = pcall(fn)
				if ok and type(n) == "string" and n ~= "" then
					names[n] = true
				end
			end
		end
		if names[bind] and ns.Rewards then
			ns.Rewards:Char().hearth = s.key
		end
	end
	if self:Has("compass") then
		self:Compass(s)
	end
end

-- Compass: how many cards the album of the zone misses, and the rarest of them (once a zone and a session).
function TL:Compass(s)
	self.told = self.told or {}
	if self.told[s.key] or not s.list then
		return
	end
	self.told[s.key] = true
	local n, rarest = 0, nil
	for _, card in ipairs(s.list) do
		if Missing(card) then
			n = n + 1
			if not rarest or card.rarity > rarest.rarity then
				rarest = card
			end
		end
	end
	local C = ns.Collection
	if n == 0 then
		ns.Print(string.format(L["Compass: %s, every card found."], C:SeriesName(s)))
		return
	end
	local r = ns.RARITY[math.min(CuratorOctoFull.Length(ns.RARITY), rarest.rarity)]
	local c = r.text
	ns.Print(string.format(L["Compass: %s, %d cards missing; the rarest: %s."], C:SeriesName(s), n,
		string.format(("|cff%02x%02x%02x%s|r"), c[1] * 255, c[2] * 255, c[3] * 255, C:Name(rarest))))
end

-- Morning Dew: the first hour of play of the day (counted while the game runs).
function TL:FirstHour()
	local t = ns.db and ns.db.talents
	if type(t) ~= "table" then
		return false
	end
	local d = self:Day()
	return (tonumber(d.play) or 0) < self.DEW_TIME
end

-------------------------------------------------------------------------------
-- The cards found on the creatures (Rewards.lua)
-------------------------------------------------------------------------------
-- The chance to find the card of a creature: ctx = { elite, boss, raid, rare (the game says so), guid, gift (a summit
-- gives it), group, night, survey, expedition, mark } (the page of the statistics gives a situation; nil: as now).
function TL:FindChance(chance, card, ctx)
	local spec = self:Spec()
	if not spec or not card then
		return chance
	end
	ctx = ctx or {}
	if ctx.gift then
		return 1
	end
	local k = 1
	if spec == "carto" then
		local zone = ns.Rewards and ns.Rewards:ZoneSeries()
		local survey = ctx.survey
		if survey == nil then
			survey = self:SurveyLeft() > 0 and zone ~= nil and card.series == zone and Missing(card)
		end
		if survey then
			k = k * 2
		end
		local exped = ctx.expedition
		if exped == nil then
			exped = self:ExpeditionLeft() > 0 and zone ~= nil and card.series == zone
		end
		if exped then
			k = k * 3
		end
	elseif spec == "hunter" then
		local add = 0
		if ctx.elite or ctx.rare then
			add = add + self:V("quarry")
		end
		if card.rarity >= 5 then
			add = add + self:V("biggame")
		end
		if ctx.boss and ctx.raid then
			add = add + self:V("bigbore")
		end
		k = 1 + add
		local marked = ctx.mark
		if marked == nil then
			marked = self:Marked(ctx.guid)
		end
		if marked then
			k = k * 3
		end
		if ctx.elite and not ctx.boss and self:Has("firstblood") then
			local fb = ctx.firstblood
			if fb == nil then
				fb = self:FirstBlood()
			end
			if fb then
				k = k * 2
			end
		end
	end
	return math.min(1, chance * k)
end

-- After the roll (the elites of the hour counted: First Blood; the creature marked defeated: its mark ends, told when
-- its card came).
function TL:Found(got, card, ctx)
	if ctx and ctx.elite and not ctx.boss and self:Has("firstblood") then
		local t = State()
		t.fbHour = math.floor(Now() / 3600)
	end
	if ctx and ctx.guid and self:Marked(ctx.guid) then
		local t = State()
		t.mark = nil
		ns.Fire("TALENT_RUNNING", "mark", false)
		if got and not ctx.gift then
			self.cardProc = { id = "mark", card = card }
			ns.Fire("TALENT_PROC", "mark", card)
		end
	end
end

-- First Blood: no elite defeated yet this hour.
function TL:FirstBlood()
	local t = ns.db and ns.db.talents
	return not (type(t) == "table" and t.fbHour == math.floor(Now() / 3600))
end

-- The finishes of a card found (thunderforged: second, titanforged: top): ctx as for TL:FindChance.
function TL:FoundFinish(top, second, ctx)
	if self:Spec() ~= "hunter" or not ctx then
		return top, second
	end
	if ctx.elite or ctx.boss then
		local k = 1 + self:V("mounted")
		top, second = top * k, second * k
	end
	if ctx.boss then
		second = second + self:V("teeth")
		if ctx.raid then
			top = top + self:V("relics")
		end
	end
	return top, second
end

function TL:WildFinish(_, finish)
	return finish
end

-- (1.14.0) A card a summit gives on a creature (Terra Incognita, the Contract of the Day, a Legendary Head): its key,
-- else nil. card: the card of the creature, ctx as for TL:FindChance (guid, elite, rare, boss).
function TL:GiftFor(card, ctx)
	if not (card and ns.db) or not Missing(card) then
		return nil
	end
	ctx = ctx or {}
	local spec = self:Spec()
	if spec == "carto" and self:Ready("terra") and card.rarity <= 3 and not ctx.boss then
		local s = ns.Rewards and ns.Rewards:ZoneSeries()
		if s and not s.dungeon and card.series == s and Share(s) < 0.75 then
			return "terra"
		end
	elseif spec == "hunter" then
		if self:Ready("dailyhead") and self:DailyTarget() == card then
			return "dailyhead"
		end
		local t = State()
		local m = t.mark
		if type(m) == "table" and m.legend and self:Marked(ctx.guid) and card.rarity <= 4 then
			return "legendhead"
		end
	end
	return nil
end

-- The card given: the summit used, its achievement the first time (the toast of the card says the talent).
function TL:GiftTaken(id, card)
	self.cardProc = { id = id, card = card }
	if id == "legendhead" then
		local t = State()
		t.mark = nil
		self:Summit(id)
	elseif id == "terra" or id == "dailyhead" then
		self:Use(id)
		self:Summit(id)
	end
	ns.Fire("TALENT_PROC", id, card)
end

-- Blank Squares: a card already owned found on a creature, now and then another of its album and rarity, missing.
function TL:Blank(card)
	if not (card and card.series and self:Has("blanks")) or Missing(card) or Roll() >= self:V("blanks") then
		return card
	end
	local out = {}
	for _, c in ipairs(card.series.byRarity[card.rarity] or {}) do
		if Missing(c) then
			out[CuratorOctoFull.Length(out) + 1] = c
		end
	end
	if CuratorOctoFull.Length(out) == 0 then
		return card
	end
	local got = out[math.random(CuratorOctoFull.Length(out))]
	self.cardProc = { id = "blanks", card = got }
	ns.Fire("TALENT_PROC", "blanks", got)
	return got
end

-- A card found on a creature (Rewards.lua: CARD_FOUND): Reward, Expedition's summit.
function TL:OnFound(card, ctx)
	if not card then
		return
	end
	ctx = ctx or {}
	if (ctx.elite or ctx.rare) and self:Has("reward") then
		ns.Reroll:Rubies(self:V("reward"), "reward")
	end
	-- (1.14.0: Head Collection, a card of a boss)
	if ctx.boss and self:Has("heads") then
		ns.Reroll:Rubies(self:V("heads"), "heads")
	end
	if card.rarity >= 4 and self:ExpeditionLeft() > 0 then
		self:Summit("expedition")
	end
end

-------------------------------------------------------------------------------
-- The active talents of the trees
-------------------------------------------------------------------------------
-- Survey: how long it lasts, how long it still runs.
function TL:SurveyTime()
	return 30 * 60 + self:V("survey2")
end

function TL:SurveyLeft()
	local t = ns.db and ns.db.talents
	if type(t) ~= "table" or not self:Has("survey") then
		return 0
	end
	return math.max(0, (tonumber(t.survey) or 0) - Now())
end

function TL:StartSurvey()
	if not self:Use("survey") then
		return false
	end
	local t = State()
	t.survey = Now() + self:SurveyTime()
	ns.PlayFor(ns.SND.charge, 1.5)
	ns.Print(string.format(L["Survey: for %s, the creatures of your zone whose card you are missing give it twice as often."], ns.Duration(self:SurveyTime())))
	self:Ends("survey", self:SurveyTime())
	return true
end

-- Expedition: once a week, an hour.
TL.EXPEDITION_TIME = 3600
function TL:ExpeditionLeft()
	local t = ns.db and ns.db.talents
	if type(t) ~= "table" or not self:Has("expedition") then
		return 0
	end
	return math.max(0, (tonumber(t.expedition) or 0) - Now())
end

function TL:StartExpedition()
	if not self:Use("expedition") then
		return false
	end
	local t = State()
	t.expedition = Now() + self.EXPEDITION_TIME
	ns.PlayFor(ns.SND.charge, 1.5)
	ns.Print(L["Expedition: for 1 hour, the creatures of your zone give you their card three times as often."])
	self:Ends("expedition", self.EXPEDITION_TIME)
	return true
end

-- The end of a talent that runs, told (its event: the bar and the page follow).
function TL:Ends(id, left)
	ns.Fire("TALENT_RUNNING", id, true)
	if ns.Delay then
		ns.Delay(left + 0.5, function()
			ns.Fire("TALENT_RUNNING", id, false)
		end, TL)
	end
end

-- Price on its Head: how long the mark holds, the creature marked.
function TL:MarkTime()
	return 15 * 60 + self:V("mark2")
end

function TL:Marked(guid)
	local t = ns.db and ns.db.talents
	local m = type(t) == "table" and t.mark
	if type(m) ~= "table" or not guid or m.g ~= guid then
		return false
	end
	return (tonumber(m.u) or 0) > Now()
end

function TL:MarkLeft()
	local t = ns.db and ns.db.talents
	local m = type(t) == "table" and t.mark
	if type(m) ~= "table" then
		return 0
	end
	return math.max(0, (tonumber(m.u) or 0) - Now())
end

-- The target marked: a creature whose card is known (its unit, "target" by default). True; false and why ("card": no
-- creature with a card targeted, "ready").
function TL:MarkTarget(unit)
	unit = unit or "target"
	if not self:Ready("mark") then
		return false, "ready"
	end
	local ok, guid = pcall(UnitGUID, unit)
	if not ok or type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) then
		return false, "card"
	end
	local kind, _, _, _, _, id = strsplit("-", guid)
	local npc = (kind == "Creature" or kind == "Vehicle") and tonumber(id) or nil
	local card = npc and ns.Cards["c" .. npc]
	if not card then
		return false, "card"
	end
	local dead = UnitIsDead and CuratorOctoFull.Select(2, pcall(UnitIsDead, unit))
	if dead == true then
		return false, "card"
	end
	self:Use("mark")
	local t = State()
	-- (Legendary Head: the first mark of the week)
	local legend = false
	if self:Ready("legendhead") then
		self:Use("legendhead")
		legend = true
	end
	t.mark = { g = guid, k = card.key, u = Now() + self:MarkTime(), legend = legend or nil }
	ns.Play(ns.SND.stamp)
	local name = ns.Collection:Name(card)
	if legend then
		ns.Print(string.format(L["Legendary Head: %s is marked; defeat it within %s and its card is yours (epic at most)."], name, ns.Duration(self:MarkTime())))
	else
		ns.Print(string.format(L["Price on its Head: %s is marked; defeat it within %s and your chance to find its card is tripled."], name, ns.Duration(self:MarkTime())))
	end
	self:Ends("mark", self:MarkTime())
	return true
end

-- Double or Nothing: armed on the next booster (or display, High Roller).
function TL:ArmDouble(on)
	if on == nil then
		on = not self:Armed("double")
	end
	return self:Arm("double", on)
end

-- What a bet on a booster does (s: its album): its cards more (or fewer), won or lost, and whether it was saved by
-- Nerves of Steel. nil when nothing is bet. Used then.
function TL:Bet(s)
	if not self:Armed("double") or (s and s.event) then
		return nil
	end
	local lair = s and s.dungeon
	local r = self:Rank("relance")
	local win = Roll() < ((r >= 3) and 0.6 or 0.5)
	local delta
	if self:Has("careful") then
		delta = win and 1 or 0
	elseif win then
		delta = (lair and 1 or 2) + ((r >= 1) and 1 or 0) + ((lair and self:Has("lairplayer")) and 1 or 0)
	else
		delta = -((lair and 1 or 2) - ((r >= 2) and 1 or 0))
	end
	local saved = false
	if not win and delta < 0 and Roll() < self:V("nerves") then
		delta, saved = 0, true
	end
	self:Use("double")
	local out = { win = win, delta = delta, saved = saved or nil }
	if win and not lair and self:Has("landplayer") then
		out.rubies = 100
	end
	return out
end

-- The bet on a display (High Roller): its boosters more or fewer. nil when nothing is bet.
function TL:BetDisplay()
	if not (self:Has("highroller") and self:Armed("double")) then
		return nil
	end
	local r = self:Rank("relance")
	local win = Roll() < ((r >= 3) and 0.6 or 0.5)
	local delta = win and 3 or -3
	local saved = false
	if not win and Roll() < self:V("nerves") then
		delta, saved = 0, true
	end
	self:Use("double")
	return { win = win, delta = delta, saved = saved or nil }
end

-- Black Market: what it takes off, the card under the counter (drawn when it is used; bought at a reseller).
function TL:BlackMarketOff()
	return math.min(0.6, 0.3 + self:V("backroom"))
end

function TL:BlackMarket()
	local t = ns.db and ns.db.talents
	local bm = type(t) == "table" and t.bm
	if type(bm) ~= "table" or bm.bought then
		return nil
	end
	local card = ns.Cards[bm.k or ""]
	if not card or not Missing(card) then
		return nil
	end
	return card, tonumber(bm.p) or 0
end

-- Used: a card drawn among those the collection misses, rare or epic, of the albums the reseller sells. The card, or
-- nil and why ("ready", "none").
function TL:OpenBlackMarket()
	if not self:Ready("blackmarket") then
		return nil, "ready"
	end
	local RV = ns.Reseller
	local pool = {}
	for _, card in ipairs(RV and RV:Pool() or {}) do
		if (card.rarity == 3 or card.rarity == 4) and Missing(card) then
			pool[CuratorOctoFull.Length(pool) + 1] = card
		end
	end
	if CuratorOctoFull.Length(pool) == 0 then
		return nil, "none"
	end
	local card = pool[math.random(CuratorOctoFull.Length(pool))]
	local price = math.floor(RV.PRICE[card.rarity] * (1 - self:BlackMarketOff()) + 0.5)
	self:Use("blackmarket")
	local t = State()
	t.bm = { k = card.key, p = price, t = Now() }
	ns.Fire("TALENT_PROC", "blackmarket", card)
	return card
end

-- The card under the counter bought (at a reseller). True; false and why ("none", "here", "rubies").
function TL:BuyBlackMarket()
	local card, price = self:BlackMarket()
	if not card then
		return false, "none"
	end
	local RV = ns.Reseller
	if not (RV and RV.here) then
		return false, "here"
	end
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return false, "guard"
	end
	local paid, why = ns.Rubies:Spend(price, "resell")
	if not paid then
		return false, why or "rubies"
	end
	State().bm.bought = true
	ns.Collection:Grant(card, nil, "r")
	ns.Fire("RESELL_BOUGHT", card, price, true)
	return true, card, price
end

-- Special Order: a card the collection misses, epic at most, of the albums the reseller sells, at its full price. True;
-- false and why ("ready", "card", "here", "rubies").
function TL:OrderPrice(card)
	local RV = ns.Reseller
	return card and RV and RV.PRICE[card.rarity] or 0
end

function TL:CanOrder(card)
	if not self:Ready("order") then
		return false, "ready"
	end
	if not (card and card.rarity <= 4 and Missing(card) and card.series and not card.series.event and not card.series.limited) then
		return false, "card"
	end
	local RV = ns.Reseller
	if not (RV and RV.here) then
		return false, "here"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:OrderPrice(card))) then
		return false, "rubies"
	end
	return true
end

function TL:Order(card)
	local ok, why = self:CanOrder(card)
	if not ok then
		return false, why
	end
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return false, "guard"
	end
	local price = self:OrderPrice(card)
	local paid, err = ns.Rubies:Spend(price, "resell")
	if not paid then
		return false, err or "rubies"
	end
	self:Use("order")
	ns.Collection:Grant(card, nil, "r")
	self:Summit("order")
	ns.Fire("RESELL_BOUGHT", card, price, true)
	ns.Fire("TALENT_PROC", "order", card)
	return true, price
end

-- The Darkmoon Wheel: its parts as they are (Darkmoon Fortune: fewer on nothing, more on the boosters).
function TL:WheelParts()
	local out, cut = {}, math.min(40, self:V("darkmoon"))
	local boosters = 0
	for _, p in ipairs(self.WHEEL) do
		if p[1] == "zone" or p[1] == "zone2" or p[1] == "dungeon" then
			boosters = boosters + p[2]
		end
	end
	for _, p in ipairs(self.WHEEL) do
		local v = p[2]
		if p[1] == "nothing" then
			v = v - cut
		elseif p[1] == "zone" or p[1] == "zone2" or p[1] == "dungeon" then
			v = v + cut * p[2] / boosters
		end
		out[CuratorOctoFull.Length(out) + 1] = { p[1], v }
	end
	return out
end

-- The wheel spun (once a day): where it stops, what it gives. The part ("nothing", "rubies", "zone", "zone2",
-- "dungeon"), or nil and why ("ready").
function TL:Spin()
	if not self:Ready("wheel") then
		return nil, "ready"
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil, "guard"
	end
	self:Use("wheel")
	local x = Roll() * 100
	local got = "nothing"
	for _, p in ipairs(self:WheelParts()) do
		if x < p[2] then
			got = p[1]
			break
		end
		x = x - p[2]
	end
	local LV = ns.Level
	if got == "rubies" then
		self:Rubies(self.WHEEL_RUBIES, "wheel")
	elseif got == "zone" and LV then
		LV:AddChoice("zone", 1)
	elseif got == "zone2" and LV then
		LV:AddChoice("zone", 2)
	elseif got == "dungeon" and LV then
		LV:AddChoice("dungeon", 1)
		self:Summit("wheel")
	end
	self:Day().wheelGot = got
	ns.Fire("TALENT_PROC", "wheel", got)
	ns.Fire("CHANGED")
	return got
end

-- Glance (UI/Expertise.lua): used on an appraisal to come.
function TL:CanGlance()
	return self:Ready("glance")
end

-- The active talents on the bar of the boosters (UI/BoosterBar.lua), in their order, of each tree: those learned.
TL.BAR_ACTIVES = {
	carto = { "survey", "expedition" },
	hunter = { "mark" },
	gambler = { "double", "wheel" },
	smuggler = { "blackmarket" },
	archivist = { "glance" },
}
function TL:BarActives()
	local out = {}
	for _, id in ipairs(self.BAR_ACTIVES[self:Spec() or ""] or {}) do
		if self:Has(id) then
			out[CuratorOctoFull.Length(out) + 1] = id
		end
	end
	return out
end

-- The state of a talent to use: "running" and its time left (Survey, Expedition, a mark), "armed" (Double or Nothing
-- on the next booster), "waiting" (the card under the counter of the Black Market, to buy), "cooldown" and the time
-- before it is ready, "ready".
function TL:ActiveState(id)
	if id == "survey" and self:SurveyLeft() > 0 then
		return "running", self:SurveyLeft()
	elseif id == "expedition" and self:ExpeditionLeft() > 0 then
		return "running", self:ExpeditionLeft()
	elseif id == "mark" and self:MarkLeft() > 0 then
		return "running", self:MarkLeft()
	elseif id == "double" and self:Armed("double") then
		return "armed", 0
	elseif id == "blackmarket" and self:BlackMarket() then
		return "waiting", 0
	end
	local left = self:Left(id)
	if left > 0 then
		return "cooldown", left
	end
	return "ready", 0
end

-- A talent to use, used where it can be (the bar of the boosters, the page of the talents, /curator active): true; false
-- and why ("ready": not ready, "card": no creature with a card targeted, "none": nothing under the counter, "where":
-- used elsewhere, its words said). What it does is said in the chat.
function TL:Activate(id)
	if not self:Has(id) then
		return false, "talent"
	end
	if ns.Beta and ns.Beta.Blocked and ns.Beta:Blocked() then
		return false, "closed"
	end
	local state, left = self:ActiveState(id)
	if id == "survey" then
		if state == "running" then
			ns.Print(string.format(L["Survey runs: %s left."], ns.Duration(left)))
			return false, "running"
		end
		if self:StartSurvey() then
			return true
		end
		return false, "ready"
	elseif id == "expedition" then
		if state == "running" then
			ns.Print(string.format(L["Expedition runs: %s left."], ns.Duration(left)))
			return false, "running"
		end
		if self:StartExpedition() then
			return true
		end
		return false, "ready"
	elseif id == "mark" then
		local ok, why = self:MarkTarget("target")
		if not ok and why == "card" then
			ns.Print(L["Price on its Head: target a creature that has a Curator card first."])
		end
		return ok, why
	elseif id == "double" then
		if not self:Armed("double") and not self:Ready("double") then
			return false, "ready"
		end
		local on = not self:Armed("double")
		self:ArmDouble(on)
		if on then
			ns.Print(self:Has("highroller") and L["Double or Nothing: your next booster or display is the bet."] or L["Double or Nothing: your next booster is the bet."])
		else
			ns.Print(L["Double or Nothing: the bet is taken back."])
		end
		return true, on and "armed" or "unarmed"
	elseif id == "wheel" then
		if not self:Ready("wheel") then
			return false, "ready"
		end
		if ns.WheelUI then
			ns.WheelUI:Open()
			return true
		end
		if self:Spin() ~= nil then
			return true
		end
		return false, "ready"
	elseif id == "blackmarket" then
		local card, price = self:BlackMarket()
		if not card then
			if not self:Ready("blackmarket") then
				return false, "ready"
			end
			local why
			card, why = self:OpenBlackMarket()
			if not card then
				if why == "none" then
					ns.Print(L["Black Market: the reseller has nothing you are missing under his counter."])
				end
				return false, why
			end
			card, price = self:BlackMarket()
		end
		local r = ns.RARITY[card.rarity]
		ns.Print(string.format(L["Black Market: %s, for %s, under the counter of the reseller (a vendor of general goods or of trade supplies)."], 
			string.format(("|cff%02x%02x%02x%s|r"), r.text[1] * 255, r.text[2] * 255, r.text[3] * 255, ns.Collection:Name(card)),
			ns.Rubies and ns.Rubies.Text(price) or tostring(price)))
		if ns.Reseller and ns.Reseller.here and ns.ResellerUI then
			ns.ResellerUI:Open("counter")
		end
		return true, "waiting"
	elseif id == "glance" then
		ns.Print(state == "ready" and L["Glance is ready: it works at the banker, before you appraise a copy."]
			or string.format(L["Glance recharges: ready in %s."], ns.Duration(left)))
		return false, "where"
	elseif id == "order" then
		ns.Print(L["Special Order: at a reseller, the tab Under the counter of his window."])
		return false, "where"
	end
	return false, "where"
end

-------------------------------------------------------------------------------
-- The Contract of the Day: a target named each day (an elite or a rare of a zone of the level of this character whose
-- card the collection misses), the same all day long
-------------------------------------------------------------------------------
local M = 2147483647
local function Hash(text)
	local h = 7
	for i = 1, CuratorOctoFull.Length(text) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(text, i)) , M)
	end
	return h > 0 and h or 1
end

function TL:DailyTarget()
	if not self:Has("dailyhead") or not ns.db then
		return nil
	end
	local level = (UnitLevel and UnitLevel("player")) or 1
	local d = self:Day()
	-- (named once a day; a target found or the level of the character changed: named again)
	local card = d.head and ns.Cards[d.head]
	if card and d.headLv == level and Missing(card) then
		return card
	end
	local cand = {}
	for _, s in ipairs(ns.Series or {}) do
		local lv = s.levels
		if not s.dungeon and not s.event and not s.limited and lv and level >= (lv[1] or 1) - 2 and level <= (lv[2] or 60) + 2 then
			for _, c in ipairs(s.list or {}) do
				if c.npc and ((ns.ELITE and ns.ELITE[c.npc]) or (ns.RARE and ns.RARE[c.npc])) and Missing(c) then
					cand[CuratorOctoFull.Length(cand) + 1] = c
				end
			end
		end
	end
	if CuratorOctoFull.Length(cand) == 0 then
		d.head, d.headLv = nil, level
		return nil
	end
	table.sort(cand, function(a, b)
		return a.key < b.key
	end)
	local id = (ns.Export and ns.Export.Id and ns.Export:Id()) or "curator"
	card = cand[(CuratorOctoFull.Mod(Hash(id .. ":" .. tostring(d.e) .. ":" .. level) , CuratorOctoFull.Length(cand))) + 1]
	d.head, d.headLv = card.key, level
	return card
end

-------------------------------------------------------------------------------
-- The quests of the collector, the achievements, the experience, the rubies
-------------------------------------------------------------------------------
-- (the kinds of quests of each talent)
local EXPLORER = { gather = true, stamp = true, visa = true, newcard = true }
local WANTED = { kill = true, ctype = true, elite = true, find = true, dungeonBoss = true, dungeonDone = true, dungeonElite = true, raidBoss = true,
	raidDone = true, hk = true, bgWin = true, bgPlay = true, bgWinIn = true, bgHk = true, worldHk = true, pvpClass = true, pvpRace = true, pvpRank = true,
	pvp60 = true, certify = true, combatant = true, exploit = true, revenge = true, bounty = true, pay = true, wanted = true, head = true }
TL.EXPLORER_KINDS, TL.WANTED_KINDS = EXPLORER, WANTED

-- The experience of a quest of the collector (its kind).
function TL:QuestXP(xp, kind)
	local k = 1
	if EXPLORER[kind or ""] then
		k = k + self:V("explorer")
	end
	if WANTED[kind or ""] then
		k = k + self:V("wanted")
	end
	if k ~= 1 then
		return math.floor(xp * k + 0.5)
	end
	return xp
end

-- The achievements that each talent of the achievements counts (a: the achievement).
local function OfAch(a, kind)
	local cat, g = a.cat, a.group and a.group.key or nil
	local id = tostring(a.id or "")
	if kind == "scholar" then
		return cat == "albums" or (cat == "adventure" and g ~= "d" and g ~= "r" and id ~= "fboss")
	elseif kind == "renown" then
		return cat == "bestiary" or g == "d" or g == "r" or id == "fboss"
	elseif kind == "goodname" then
		return cat == "contracts" or cat == "social"
	elseif kind == "archives" then
		return string.find(id, "^rst") ~= nil or id == "case1" or string.find(id, "^xp") ~= nil or string.find(id, "^seal") ~= nil
	elseif kind == "prestige" then
		return (cat == "collection" and string.find(id, "^rst") == nil and id ~= "case1") or cat == "rarity" or cat == "finish" or cat == "albums"
	end
	return false
end
TL.OfAch = OfAch

-- What the talents add to the experience (what: "xp") or the rubies ("rubies") of an achievement.
function TL:AchBonus(a, what)
	local spec = self:Spec()
	if not (spec and a) then
		return 1
	end
	local k = 1
	local byXp = { carto = "scholar", hunter = "renown", smuggler = "goodname", archivist = "archives" }
	local id = byXp[spec]
	if id and self:Has(id) and OfAch(a, id) then
		k = k + self:V(id)
	end
	if what == "rubies" and spec == "archivist" and self:Has("prestige") and OfAch(a, "prestige") then
		k = k + self:V("prestige")
	end
	return k
end

-- The experience gained (Level.lua: LV:Gain), why it comes: Memory of the Roads, outside the dungeons and the raids.
local NO_XP_TALENT = { chest = true, gift = true, admin = true, back = true }
function TL:GainXP(n, why)
	if NO_XP_TALENT[why or ""] or not self:Has("roadmemory") or InInstance() then
		return n
	end
	return math.floor(n * (1 + self:V("roadmemory")) + 0.5)
end

-- The rubies earned with the talents (why: what they come from, Rubies.lua; ctx: the quest they come from, { kind,
-- period, section }). The rubies of the talents themselves, and the catch-up, as they are.
function TL:RubyGain(n, why, ctx)
	if not self:Spec() or why == "talent" or why == "back" or why == "gift" then
		return n
	end
	local k = 1
	if why == "level" then
		k = k + self:V("ledger")
	end
	if (why == "quest" or why == "auto") and type(ctx) == "table" then
		if ctx.period == "month" then
			k = k + self:V("ledger")
		end
		if ctx.section == "dungeon" or ctx.section == "raid" or ctx.section == "pvp" then
			k = k + self:V("fortune")
		end
		if ctx.kind == "contract" then
			k = k + self:V("lionshare")
		end
	end
	return n * k
end

-- How much less a price in rubies is (what: "key", "expertise", "purify", "case", "pack", "display", "respec"...).
function TL:RubyDiscount(what)
	if not self:Spec() then
		return 0
	end
	if what == "key" then
		return self:V("keyring")
	elseif what == "expertise" then
		return self:V("colleague")
	elseif what == "purify" then
		return self:V("purifier")
	elseif what == "case" then
		return self:V("casing")
	elseif what == "pack" or what == "display" then
		return self:V("rebate")
	end
	return 0
end

-- (the talents of before that changed these: none any more)
function TL:PackWeekBonus()
	return 0
end

function TL:FreePack()
	return false
end

function TL:UseFreePack()
	return false
end

function TL:FreeReroll()
	return false
end

function TL:UseFreeReroll()
	return false
end

function TL:FreeRumor()
	return false
end

function TL:UseFreeRumor()
	return false
end

function TL:RumorFind(base)
	return base
end

function TL:Twins()
	return 0
end

function TL:WishMax(base)
	return base
end

function TL:ContractMax(base)
	return base
end

function TL:ContractSize(base)
	return base
end

function TL:Network()
end

-- Deep Pockets: the guard of the week, raised.
function TL:GuardBonus()
	return self:V("pockets")
end

-------------------------------------------------------------------------------
-- The boosters (Collection.lua): the Gambler
-------------------------------------------------------------------------------
-- What the talents change in a booster of an album (nil: nothing). ctx: a situation given (the page of the
-- statistics: { first, firstFive, hot }; nil: as it is now).
function TL:BoosterMods(s, ctx)
	if self:Spec() ~= "gambler" or not s then
		return nil
	end
	ctx = ctx or {}
	local t = State()
	local d = self:Day()
	local opened = tonumber(d.opened) or 0
	local m = { rar = {}, shiny = 1, holo = 1, raise = {} }
	-- (Hot Hand: after an epic card or better, the next two boosters)
	local hot = ctx.hot
	if hot == nil then
		hot = (tonumber(t.hot) or 0) > 0
	end
	if hot and self:Has("hothand") then
		m.rar[4] = 1 + self:V("hothand")
	end
	-- (Opening Stake: the first booster of the day; Winning Streak: the first five)
	local first = ctx.first
	if first == nil then
		first = opened == 0
	end
	local five = ctx.firstFive
	if five == nil then
		five = opened < 5
	end
	if first and self:Has("stake") then
		m.raise[CuratorOctoFull.Length(m.raise) + 1] = { "stake", self:V("stake") }
	end
	if five and self:Has("streak") then
		m.raise[CuratorOctoFull.Length(m.raise) + 1] = { "streak", self:V("streak") }
	end
	m.jackpot = self:V("jackpot")
	m.loaded = self:V("loaded")
	m.flourish = self:V("flourish")
	-- (The Great Game: the first booster of the week, one chance in ten; not a booster of an event)
	if not s.event and not ctx.preview and self:Ready("grandgame") then
		m.grand = Roll() < 0.1
		m.grandTried = true
	end
	return m
end

-- The weight of a card in the draw (no talent changes it any more).
function TL:Weight()
	return 1
end

-- A booster kept: what is counted by day and by week (the first of the day, the five first, the week of the Annuity,
-- the hot hand), the summits.
function TL:Kept(s, picks)
	if self:Spec() ~= "gambler" or not picks then
		return
	end
	local t = State()
	local d = self:Day()
	d.opened = (tonumber(d.opened) or 0) + 1
	local w = self:Week()
	w.opened = (tonumber(w.opened) or 0) + 1
	local best = 1
	for _, p in ipairs(picks) do
		best = math.max(best, p.card and p.card.rarity or 1)
	end
	if best >= 4 then
		t.hot = 2
	elseif (tonumber(t.hot) or 0) > 0 then
		t.hot = t.hot - 1
	end
	if picks.grandTried then
		self:Use("grandgame")
		if picks.grand then
			self:Summit("grandgame")
			ns.Fire("TALENT_PROC", "grandgame")
		end
	end
	if self:Has("annuity") and w.opened >= self.ANNUITY_BOOSTERS and not w.annuity then
		w.annuity = true
		local n = self:V("annuity")
		self:Later(function()
			TL:Rubies(n, "annuity")
		end)
	end
	if picks.bet and picks.bet.rubies then
		local n = picks.bet.rubies
		self:Later(function()
			TL:Rubies(n, "landplayer")
		end)
	end
end

-- The experience of a card of a booster (new: the album was missing it; card, finish: the card and its finish; s: its
-- album).
function TL:CardXP(xp, new, card, finish, s)
	local spec = self:Spec()
	if not spec then
		return xp
	end
	local k = 1
	if spec == "gambler" then
		local r = self:V("rush")
		if card and card.rarity >= 4 then
			r = r * 2
		end
		k = k + r
		if finish == "shiny" or finish == "holo" then
			k = k + self:V("thrills")
		end
	elseif spec == "carto" and new and s and not s.dungeon and not s.event then
		k = k + self:V("freshink")
	end
	if k ~= 1 then
		return math.floor(xp * k + 0.5)
	end
	return xp
end

-------------------------------------------------------------------------------
-- The trades (Trade.lua: TRADE_CONFIRMED), the contracts (Contract.lua)
-------------------------------------------------------------------------------
-- A player I traded with.
function TL:Partner(name)
	local st = ns.db and ns.db.stats
	return name ~= nil and type(st) == "table" and type(st.partners) == "table" and st.partners[name] == true
end

-- A player of my guild.
function TL:Guildmate(name)
	local T = ns.Trade
	if T and T.roster and T.roster[name] ~= nil then
		return true
	end
	return ns.db and ns.db.guild and ns.db.guild[name] ~= nil or false
end

-- A trade the other side has in its save: Handshake, False Bottom, Distant Trade, Philanthropist, Right of Way.
function TL:TradeConfirmed(rec)
	if self:Spec() ~= "smuggler" or not rec or not rec.with then
		return
	end
	local both = CuratorOctoFull.Length((rec.give or {})) > 0 and CuratorOctoFull.Length((rec.take or {})) > 0
	local gift = CuratorOctoFull.Length((rec.give or {})) > 0 and CuratorOctoFull.Length((rec.take or {})) == 0
	local d = self:Day()
	local who = rec.with
	if both and self:Has("handshake") then
		d.hand = type(d.hand) == "table" and d.hand or {}
		local guild = self:Has("guildsmuggle") and self:Guildmate(who)
		local count = 0
		for _, v in pairs(d.hand) do
			if v ~= "g" then
				count = count + 1
			end
		end
		if not d.hand[who] and (guild or count < self.PARTNERS_A_DAY) then
			d.hand[who] = guild and "g" or true
			local pts = self:V("handshake") * (guild and 2 or 1)
			ns.Rewards:AddAnywhere(pts, "handshake")
			ns.Fire("TALENT_PROC", "handshake", who, pts)
		end
	end
	if gift then
		if self:Has("falsebottom") and not d.falsebottom then
			d.falsebottom = true
			self:Rubies(self:V("falsebottom"), "falsebottom")
		end
		if self:Has("philanthropist") and not d.phil then
			d.phil = true
			ns.Rewards:AddAnywhere(20, "philanthropist")
			ns.Fire("TALENT_PROC", "philanthropist", who)
		end
	end
	if self:Has("toll") and (tonumber(d.toll) or 0) < self.TOLLS_A_DAY then
		d.toll = (tonumber(d.toll) or 0) + 1
		self:Rubies(10, "toll")
	end
	if rec.fresh and self:Ready("farcommerce") then
		self:Use("farcommerce")
		self:Rubies(100, "farcommerce")
	end
end

-- A contract signed (n contracts). (31 October: Labor gone, Fine Print in its place: Contract.lua, Cases.lua.)
function TL:Signed(n)
	if self:Spec() ~= "smuggler" then
		return
	end
end

-------------------------------------------------------------------------------
-- The bosses (Rewards.lua), the places explored, the copies (the trades), the reseller, the expertise
-------------------------------------------------------------------------------
-- A boss of a dungeon or a raid defeated (final: the last boss of the place): Contract of the Week, Raider.
function TL:BossDone(s, card, final)
	if not (s and ns.Rewards) then
		return
	end
	if self:Ready("contractw") and ((final and not s.raid) or s.raid) then
		self:Use("contractw")
		ns.Rewards:Give(s, 1, "contractw", false)
		ns.Fire("TALENT_PROC", "contractw", s)
	end
	if final and not s.raid and self:Has("raider") and self.run and self.run.k == s.key then
		local took = ((GetTime and GetTime()) or 0) - (tonumber(self.run.t) or 0)
		self.run = nil
		if took >= 0 and took < self.RAIDER_TIME then
			ns.Rewards:Fill(ns.Rewards:FarmSeries(s), 50, "raider", true)
			ns.Fire("TALENT_PROC", "raider", s)
		end
	end
end

-- (a place discovered: no talent of the trees any more)
function TL:Explored()
end

-- (the active talent of before: none any more; what the bar and the commands asked of it)
function TL:InstinctLeft()
	return 0
end

function TL:StartInstinct()
	return false
end

-- What a copy of a card is worth (the value of the trades).
function TL:CopyValue(card, finish)
	local T = ns.Trade
	local v = (T and T.VALUE and T.VALUE[card.rarity]) or 1
	local x = T and T.FINISH_X and T.FINISH_X[finish or ""] or nil
	return v * (x or 1)
end

-- The reseller: the cards more of the day (Harbor Contacts).
function TL:ResellBonus()
	return self:Rank("harbor")
end

-- What the reseller pays for a copy (Patter; Receiver for a forged one), and what he asks for a card (Shrewd
-- Negotiator for a forged one): the factor.
function TL:ResellOffer(finish)
	local k = 1 + self:V("patter")
	if finish == "shiny" or finish == "holo" then
		k = k + self:V("receiver")
	end
	return k
end

function TL:ResellPrice(finish)
	if finish == "shiny" or finish == "holo" then
		return 1 - self:V("negotiator")
	end
	return 1
end

-- The expertise (Expertise.lua): a 10 likelier no more (Perfectionist works on the 9), the draws of an appraisal
-- (Grand Conservator: two, once a week).
function TL:GradeLuck()
	return 0
end

function TL:GradeDraws()
	return self:Ready("conservator") and 1 or 0
end

-- A grade drawn: Perfectionist (a 9 becomes a 10 now and then).
function TL:GradeAfter(g)
	if g == 9 and self:Has("perfectionist") and Roll() < self:V("perfectionist") then
		return 10
	end
	return g
end

-- (31 October, the talents redone: Fine Print in the place of Labor, Card Sleeves in the place of Expert's Memory, the
-- same place and as many ranks; the review of the night: their points stay where they were, the rest of the placement
-- with them, never given back for that)
function TL:Renamed(t)
	if type(t) ~= "table" or type(t.ranks) ~= "table" then
		return
	end
	for old, new in pairs({ labor = "fineprint", memory = "sleeves" }) do
		local r = tonumber(t.ranks[old])
		if r and self.BY[new] and not self.BY[old] then
			t.ranks[new] = math.max(tonumber(t.ranks[new]) or 0, math.min(math.floor(r), self.BY[new].ranks))
			t.ranks[old] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
ns.On("LOADED", function()
	local t = ns.db and ns.db.talents
	if type(t) ~= "table" then
		return
	end
	-- (a specialization of before 1.14.0, or a placement that no longer holds: the points come back, the
	-- specialization chosen again when it is gone)
	if t.spec and not TL.SPEC_BY[t.spec] then
		t.spec, t.ranks = nil, {}
	end
	TL:Renamed(t)
	if t.spec and type(t.ranks) == "table" and next(t.ranks) and not TL:Valid(t.ranks, t.spec, TL:Points()) then
		TL.refunded = TL:Spent(t.ranks)
		t.ranks = {}
	end
end)

-- A placement given back at login: said once, the points to place again (free).
ns.On("LOGIN", function()
	local n = TL.refunded
	if not n or n <= 0 or not ns.Delay then
		return
	end
	TL.refunded = nil
	ns.Delay(8, function()
		ns.Print(string.format(L["Your talents were given back: %d points to place again as you like, free of charge (/curator talents)."], TL:Points()))
	end, TL)
end)

ns.On("TRADE_CONFIRMED", function(rec)
	TL:TradeConfirmed(rec)
end)

-- Something gathered (Quests.lua): Learned Foraging, Finds, Rich Veins. what: "node" or "fish"; kind: "herb", "ore",
-- "skin", "fish".
function TL:Gathered(what, kind)
	if self:Spec() ~= "carto" or not ns.Rewards then
		return
	end
	kind = kind or (what == "fish" and "fish") or nil
	local twice = (self:Has("herbalist") and (kind == "herb" or kind == "fish")) or (self:Has("prospector") and (kind == "ore" or kind == "skin"))
	local k = twice and 2 or 1
	local R = ns.Rewards
	local s = R:WorldSeries()
	if self:Has("forage") and s then
		R:Add(s, self:V("forage") * k, "gather")
	end
	-- (a reroll: a quarter of the chance, its card in its chest)
	local RR = ns.Reroll
	local reroll = RR ~= nil and RR:IsReroll()
	if self:Has("finds") and s then
		local chance = self:V("finds") * k
		if reroll then
			chance = RR:Points(chance)
		end
		if Roll() < chance then
			local out = {}
			for _, card in ipairs(s.list or {}) do
				if card.rarity <= 2 and Missing(card) then
					out[CuratorOctoFull.Length(out) + 1] = card
				end
			end
			if CuratorOctoFull.Length(out) > 0 then
				local card = out[math.random(CuratorOctoFull.Length(out))]
				if ns.Guard and not ns.Guard:Allow(s, card) then
					return
				end
				if reroll then
					RR:StashCard(card, nil, nil, "e")
					ns.Fire("TALENT_CARD", "finds", card, true)
				elseif ns.Collection:Grant(card, nil, "e") ~= nil then
					ns.Fire("TALENT_CARD", "finds", card)
				end
			end
		end
	end
	if self:Has("veins") and Roll() < self:V("veins") then
		if RR then
			RR:Rubies(25, "veins")
		else
			self:Rubies(25, "veins")
		end
	end
end

ns.On("GATHERED", function(what, kind)
	TL:Gathered(what, kind)
end)

-- Keen Nose (the Bounty Hunter): a rare whose card the collection misses, in sight (its name plate, the target, the
-- creature under the mouse): a sound and a message, once a creature, a card once an hour at most.
local nosed = {}
function TL:Sniff(unit)
	if type(unit) ~= "string" or not ns.db or not self:Has("flair") then
		return false
	end
	local ok, guid = pcall(UnitGUID, unit)
	if not ok or type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) or nosed[guid] then
		return false
	end
	local kind, _, _, _, _, id = strsplit("-", guid)
	local npc = (kind == "Creature" or kind == "Vehicle") and tonumber(id) or nil
	local card = npc and ns.Cards["c" .. npc]
	if not card or not Missing(card) then
		return false
	end
	local rare = ns.RARE and ns.RARE[npc]
	if not rare and UnitClassification then
		local ok2, c = pcall(UnitClassification, unit)
		rare = ok2 and (c == "rare" or c == "rareelite")
	end
	if not rare then
		return false
	end
	if UnitIsDead then
		local ok3, dead = pcall(UnitIsDead, unit)
		if ok3 and dead == true then
			return false
		end
	end
	nosed[guid] = true
	local now = Now()
	self.noseAt = self.noseAt or {}
	if (self.noseAt[card.key] or 0) > now - 3600 then
		return false
	end
	self.noseAt[card.key] = now
	ns.Play(ns.SND.warning)
	local r = ns.RARITY[card.rarity].text
	ns.Print(string.format(L["Keen Nose: %s is in sight, and its card is missing from your album."], 
		string.format(("|cff%02x%02x%02x%s|r"), r[1] * 255, r[2] * 255, r[3] * 255, ns.Collection:Name(card))))
	ns.Fire("TALENT_PROC", "flair", card)
	return true
end

do
	local nose = CreateFrame and CreateFrame("Frame")
	if nose then
		for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" }) do
			pcall(nose.RegisterEvent, nose, e)
		end
		CuratorOctoFull.SetScript(nose, "OnEvent", function(_, event, unit)
			if event == "PLAYER_TARGET_CHANGED" then
				unit = "target"
			elseif event == "UPDATE_MOUSEOVER_UNIT" then
				unit = "mouseover"
			end
			TL:Sniff(unit)
		end)
	end
end

-- Fence's Eye (the Smuggler): in the tooltip of a card, what the reseller gives for a copy of it, and what he sells it
-- for (finish: of the copy).
function TL:FenceLine(tip, card, finish)
	local RV = ns.Reseller
	if not (tip and card and RV and self:Has("fence")) or (card.series and (card.series.event or card.series.limited)) then
		return false
	end
	if finish ~= "shiny" and finish ~= "holo" then
		finish = nil
	end
	local RB = ns.Rubies
	local give, ask = RV:Offer(card, finish), RV:Price(card, finish)
	tip:AddLine(string.format(L["Fence's Eye: the reseller gives %s for a copy, and sells it %s."], RB.Text(give, 12), RB.Text(ask, 12)), 1, 0.78, 0.3, true)
	return true
end

-- A rare defeated: Prized Pelts (its points on the bar of the world: a reroll, a quarter, on its own bar).
ns.On("RARE_KILLED", function(s)
	if TL:Has("pelts") and ns.Rewards and s and not s.dungeon then
		ns.Rewards:Add(s, TL:V("pelts"), "kill")
	end
	-- (1.14.0: Rare Bounty)
	if TL:Has("rarebounty") and ns.Reroll and s and not s.dungeon then
		ns.Reroll:Rubies(TL:V("rarebounty"), "rarebounty")
	end
end)

-- A zone entered.
ns.On("PLACE_CHANGED", function(s)
	TL:Entered(s)
end)

-- A level: the talents of the levels.
ns.On("LOGIN", function()
	for _, id in ipairs({ "survey", "expedition", "mark" }) do
		local left = (id == "survey" and TL:SurveyLeft()) or (id == "expedition" and TL:ExpeditionLeft()) or TL:MarkLeft()
		if left > 0 then
			TL:Ends(id, left)
		end
	end
end)

-------------------------------------------------------------------------------
-- What the other modules tell (their events): the talents that follow them
-------------------------------------------------------------------------------
-- A new card in an album (Collection.lua: its first copy): Atlas, Road of Gems (the albums of the zones).
function TL:NewCard(card)
	local s = card and card.series
	-- (the parts reached are kept whatever the tree: a part reached before the talent pays nothing)
	if not (s and ns.db) or s.dungeon or s.event or s.limited or not s.list or CuratorOctoFull.Length(s.list) == 0 then
		return
	end
	local share = Share(s)
	local t = State()
	t.atlas = type(t.atlas) == "table" and t.atlas or {}
	local got = tonumber(t.atlas[s.key]) or 0
	for i, part in ipairs(self.ATLAS) do
		if share >= part - 1e-9 and got < i then
			got = i
			local paid = false
			if self:Has("atlas") then
				local r = self:Rank("atlas")
				paid = self:Rubies((part >= 1 and 120 or 40) * r, "atlas") > 0 or paid
			end
			if part >= 1 and self:Has("gemroad") then
				paid = self:Rubies(self:V("gemroad"), "gemroad") > 0 or paid
			end
			if paid then
				ns.Fire("TALENT_PROC", "atlas", s, part)
			end
		end
	end
	t.atlas[s.key] = got
end

-- A visa of the passport (Inns.lua): Stamped Passport.
ns.On("INN_VISA", function()
	if TL:Has("passport") then
		local r = TL:Rank("passport")
		TL:Rubies(25 * r, "passport")
		TL:XP(150 * r)
	end
end)

-- A card found on its creature (Rewards.lua): Treasure Map, the first rumor of the week followed to its card.
ns.On("CARD_FOUND", function(card)
	if card and TL:Ready("treasure") and ns.Tavern and ns.Tavern:Rumored(card) and ns.Rewards then
		TL:Use("treasure")
		ns.Rewards:Give(card.series, 1, "treasure", false)
		ns.Fire("TALENT_PROC", "treasure", card.series)
	end
end)

-- (1.14.0, his word: the PvP gone until its rework, its talents with it) A boss of a dungeon or a raid defeated, where it
-- counts (Rewards.lua: not too low): Trophy Room. The elites and the rares of the world, in their tens: Clean Sweep.
ns.On("BOSS_DEFEATED", function(s)
	local R = ns.Rewards
	if TL:Has("trophies") and ns.Reroll and s and not (R and R.TooLow and R:TooLow(s)) then
		ns.Reroll:Rubies(TL:V("trophies"), "trophies")
	end
end)

ns.On("KILLED", function(_, elite, dungeon)
	if not (elite and not dungeon and TL:Has("sweep") and ns.Rewards) then
		return
	end
	local t = State()
	t.sweep = (tonumber(t.sweep) or 0) + 1
	if t.sweep >= 10 then
		t.sweep = 0
		ns.Rewards:AddAnywhere(50, "sweep")
		ns.Fire("TALENT_PROC", "sweep")
	end
end)

-- An appraisal (Expertise.lua), once its verdict is shown: Expert's Memory, Catalogue, Renowned Expert; Grand
-- Conservator's summit.
ns.On("CARD_APPRAISED", function(res)
	if not (res and TL:Spec() == "archivist") then
		return
	end
	local g = tonumber(res.grade) or 0
	local xp, rubies = 0, 0
	if TL:Has("catalog") then
		xp = xp + TL:V("catalog") * (g >= 9 and 3 or 1)
	end
	if TL:Has("renowned") and g >= 8 then
		rubies = rubies + TL:V("renowned")
	end
	if res.conservator and g >= 10 then
		TL:Summit("conservator")
	end
	if xp > 0 or rubies > 0 then
		TL:Later(function()
			TL:XP(xp)
			TL:Rubies(rubies, "renowned")
		end)
	end
end)

-- A collector who looked at my showcase (Comm.lua: the profile asked for): Gallery.
function TL:Visitor(name)
	if not (name and self:Has("gallery")) then
		return
	end
	local d = self:Day()
	d.visit = type(d.visit) == "table" and d.visit or {}
	if d.visit[name] or self:CountKeys(d.visit) >= self.VISITORS_A_DAY then
		return
	end
	d.visit[name] = true
	self:Rubies(5, "gallery")
end

-- What each week gives, once (at the first moment of the week Curator runs): Hoard (a part of the rubies held), Patron
-- of the Arts (the best appraised copy).
function TL:Weekly()
	if not ns.db or not self:Spec() or (ns.Beta and ns.Beta:Over()) then
		return
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return
	end
	local w = self:Week()
	if self:Has("hoard") and not w.hoard and ns.Rubies then
		w.hoard = true
		local have = ns.Rubies:Balance()
		if have > self.HOARD_FROM then
			local r = self:Rank("hoard")
			local n = math.min(math.floor(have * self:V("hoard")), self.HOARD_MAX * r)
			self:Rubies(n, "hoard")
		end
	end
	if self:Has("patron") and not w.patron and ns.Copies and ns.Expertise then
		w.patron = true
		local best = 0
		for key in pairs(ns.db.cards or {}) do
			for _, rec in ipairs(ns.Copies:List(key) or {}) do
				local g = ns.Expertise.Of(rec)
				if g and rec.sl ~= false and g > best then
					best = g
				end
			end
		end
		if best > 0 then
			local n = self:V("patron") * (best >= 10 and 3 or 1)
			self:Rubies(n, "patron")
		end
	end
end

ns.On("LOGIN", function()
	if ns.Delay then
		ns.Delay(12, function()
			TL:Weekly()
		end, TL)
	end
end)

-- (the first hour of play of the day: counted while the game runs, Morning Dew; the week checked now and then)
local tick = CreateFrame and CreateFrame("Frame")
if tick then
	local acc, week = 0, 0
	CuratorOctoFull.SetScript(tick, "OnUpdate", function(_, elapsed)
		acc = acc + (elapsed or 0)
		if acc < 30 then
			return
		end
		local add = acc
		acc = 0
		week = week + add
		if ns.db and TL:Has("dew") then
			local d = TL:Day()
			d.play = math.min(TL.DEW_TIME + 60, (tonumber(d.play) or 0) + add)
		end
		if week >= 600 then
			week = 0
			TL:Weekly()
		end
	end)
end
