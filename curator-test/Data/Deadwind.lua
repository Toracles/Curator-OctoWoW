-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "deadwind", kind = "zone", map = 1430, area = 41, cont = "EK",
	levels = { 55, 60 }, side = "C",
	name = "Deadwind Pass",
	title = { frFR = "Défilé de Deuillevent", deDE = "Gebirgspass der Totenwinde", esES = "Paso de la Muerte", esMX = "Paso de la Muerte", ptBR = "Trilha do Vento Morto", ruRU = "Перевал Мертвого Ветра", koKR = "죽음의 고개", zhCN = "逆风小径" },
	tint = { 0.18, 0.20, 0.24 }, glow = { 0.75, 0.76, 0.84 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioDeadwind", pack = "PackDeadwind", set = "SetDeadwind",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 7369, 1, 7, 0, 55, 56, 11533, 396, false }, -- Deadwind Brute
		{ 7376, 1, 1, 0, 55, 56, 10826, 447, false }, -- Sky Shadow
		{ 12378, 1, 6, 0, 59, 60, 146, 3417, false }, -- Damned Soul
		{ 12380, 1, 6, 0, 59, 60, 12430, 2937, false }, -- Unliving Resident
		{ 7379, 2, 7, 0, 55, 57, 11537, 402, false }, -- Deadwind Ogre Mage
		{ 7370, 3, 6, 0, 58, 60, 4870, 3424, false }, -- Restless Shade
		{ 12377, 3, 6, 0, 58, 60, 11649, 3417, false }, -- Wailing Spectre
		{ 12379, 4, 6, 0, 59, 60, 13951, 2937, false }, -- Unliving Caretaker
		{ 7371, 5, 7, 0, 56, 57, 11536, 396, false }, -- Deadwind Mauler
		{ 7372, 6, 7, 0, 57, 58, 11538, 402, false }, -- Deadwind Warlock
	},
	names = {
		enUS = {[7369] = "Deadwind Brute", [7376] = "Sky Shadow", [12378] = "Damned Soul", [12380] = "Unliving Resident", [7379] = "Deadwind Ogre Mage", [7370] = "Restless Shade", [12377] = "Wailing Spectre", [12379] = "Unliving Caretaker", [7371] = "Deadwind Mauler", [7372] = "Deadwind Warlock"},
		frFR = {[7369] = "Brute de Deuillevent", [7376] = "Ombre céleste", [12378] = "Ame damnée", [12380] = "Résident non vivant", [7379] = "Ogre-mage de Deuillevent", [7370] = "Ame errante", [12377] = "Spectre gémissant", [12379] = "Fossoyeur non-vivant", [7371] = "Marteleur de Deuillevent", [7372] = "Démoniste de Deuillevent"},
		deDE = {[7369] = "Schläger der Totenwindoger", [7376] = "Himmelsschatten", [12378] = "Verdammte Seele", [12380] = "Untoter Einwohner", [7379] = "Magier der Totenwindoger", [7370] = "Ruheloser Schemen", [12377] = "Klagendes Schreckgespenst", [12379] = "Untoter Verwalter", [7371] = "Raufer der Totenwindoger", [7372] = "Hexenmeister der Totenwindoger"},
		esES = {[7369] = "Tosco Vientomuerto", [7376] = "Sombra de los cielos", [12378] = "Alma maldita", [12380] = "Residente sin vida", [7379] = "Mago ogro Vientomuerto", [7370] = "Sombra inquieta", [12377] = "Espectro de los Lamentos", [12379] = "Custodio sin vida", [7371] = "Destructor Vientomuerto", [7372] = "Brujo Vientomuerto"},
		esMX = {[7369] = "Tosco Vientomuerto", [7376] = "Sombra de los cielos", [12378] = "Alma maldita", [12380] = "Residente sin vida", [7379] = "Mago ogro Vientomuerto", [7370] = "Sombra inquieta", [12377] = "Espectro de los Lamentos", [12379] = "Custodio sin vida", [7371] = "Destructor Vientomuerto", [7372] = "Brujo Vientomuerto"},
		ptBR = {[7369] = "Brutamontes do Vento Morto", [7376] = "Sombra Celeste", [12378] = "Alma Penada", [12380] = "Residente Vivo-morto", [7379] = "Ogro-mago do Vento Morto", [7370] = "Vulto Inquieto", [12377] = "Espectro Ululante", [12379] = "Zelador Vivo-Morto", [7371] = "Espancador do Vento Morto", [7372] = "Bruxo do Vento Morto"},
		ruRU = {[7369] = "Громила с перевала Мертвого Ветра", [7376] = "Небесная тень", [12378] = "Проклятая душа", [12380] = "Неживой обитатель", [7379] = "Огр-маг с перевала Мертвого Ветра", [7370] = "Беспокойный дух", [12377] = "Завывающий призрак", [12379] = "Неживой смотритель", [7371] = "Изверг с перевала Мертвого Ветра", [7372] = "Чернокнижник с перевала Мертвого Ветра"},
		koKR = {[7369] = "죽음의고개 투사", [7376] = "하늘그늘독수리", [12378] = "저주받은 유령", [12380] = "죽지 못하는 주민", [7379] = "죽음의고개 오우거마법사", [7370] = "비운의 망령", [12377] = "울부짖는 유령", [12379] = "죽지 못하는 관리인", [7371] = "죽음의고개 싸움꾼", [7372] = "죽음의고개 흑마법사"},
		zhCN = {[7369] = "逆风蛮兵", [7376] = "暗影鹫", [12378] = "被诅咒的灵魂", [12380] = "不死的居民", [7379] = "逆风食人魔法师", [7370] = "不安宁的阴影", [12377] = "哀嚎的鬼怪", [12379] = "不死的看守者", [7371] = "逆风虐待者", [7372] = "逆风术士"},
		zhTW = {[7369] = "逆風蠻卒", [7376] = "暗影鷲", [12378] = "被詛咒的靈魂", [12380] = "不死的居民", [7379] = "逆風巨魔法師", [7370] = "不安寧的陰影", [12377] = "哀嚎的幽靈", [12379] = "不死的看守者", [7371] = "逆風虐待者", [7372] = "逆風術士"},
	},
	subs = {
		enUS = {},
		frFR = {},
		deDE = {},
		esES = {},
		esMX = {},
		ptBR = {},
		ruRU = {},
		koKR = {},
		zhCN = {},
		zhTW = {},
	},
}
