-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "onyxia", kind = "dungeon", raid = 3, instance = 249, area = 2159,
	levels = { 60, 60 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 10321, 1749, 10184 }, final = 10184,
	name = "Onyxia's Lair",
	title = { frFR = "Repaire d'Onyxia", deDE = "Onyxias Hort", esES = "Guarida de Onyxia", esMX = "Guarida de Onyxia", ptBR = "Covil da Onyxia", ruRU = "Логово Ониксии", koKR = "오닉시아의 둥지", zhCN = "奥妮克希亚的巢穴", zhTW = "奧妮克希亞的巢穴" },
	tint = { 0.24, 0.09, 0.18 }, glow = { 0.90, 0.51, 0.78 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioOnyxia", pack = "PackOnyxia", set = "SetOnyxia",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 4329, 1, 2, 0, 41, 42, 143, 3525, false }, -- Firemane Scout
		{ 4323, 1, 2, 0, 41, 42, 715, 428, false }, -- Searing Hatchling
		{ 4331, 1, 2, 0, 42, 43, 8249, 3525, false }, -- Firemane Ash Tail
		{ 11262, 1, 2, 0, 56, 57, 397, 428, false }, -- Onyxian Whelp
		{ 4334, 2, 2, 0, 43, 44, 8309, 3525, false }, -- Firemane Flamecaller
		{ 4328, 2, 2, 0, 43, 44, 8310, 3525, false }, -- Firemane Scalebane
		{ 12129, 3, 2, 0, 60, 63, 8711, 3525, false }, -- Onyxian Warder
		{ 10321, 4, 2, 0, 61, 61, 6374, 4065, false }, -- Emberstrife
		{ 1749, 5, 2, 0, 62, 62, 8769, 2937, false }, -- Lady Katrana Prestor
		{ 10184, 6, 2, 0, 63, 63, 8570, 3525, false }, -- Onyxia
	},
	names = {
		enUS = {[4329] = "Firemane Scout", [4323] = "Searing Hatchling", [4331] = "Firemane Ash Tail", [11262] = "Onyxian Whelp", [4334] = "Firemane Flamecaller", [4328] = "Firemane Scalebane", [12129] = "Onyxian Warder", [10321] = "Emberstrife", [1749] = "Lady Katrana Prestor", [10184] = "Onyxia"},
		frFR = {[4329] = "Eclaireur Crins-de-feu", [4323] = "Jeune incendiaire", [4331] = "Queue-cendrée Crins-de-feu", [11262] = "Dragonnet onyxien", [4334] = "Implorateur des flammes Crins-de-feu", [4328] = "Plaiedécaille Crins-de-feu", [12129] = "Gardien onyxien", [10321] = "Brandeguerre", [1749] = "Dame Katrana Prestor", [10184] = "Onyxia"},
		deDE = {[4329] = "Späher der Feuermähnen", [4323] = "Sengendes Jungtier", [4331] = "Aschenschweif der Feuermähnen", [11262] = "Onyxiawelpe", [4334] = "Flammenrufer der Feuermähnen", [4328] = "Bannschuppe der Feuermähnen", [12129] = "Onyxias Wärter", [10321] = "Aschenschwinge", [1749] = "Lady Katrana Prestor", [10184] = "Onyxia"},
		esES = {[4329] = "Explorador Pirocabello", [4323] = "Trampedor abrasador", [4331] = "Ceniazote Pirocabello", [11262] = "Cría de Onyxia", [4334] = "Clamallamas Pirocabello", [4328] = "Horrocrusto Pirocabello", [12129] = "Guarda de Onyxia", [10321] = "Brasaliza", [1749] = "Lady Katrana Prestor", [10184] = "Onyxia"},
		esMX = {[4329] = "Explorador Pirocabello", [4323] = "Prole abrasadora", [4331] = "Ceniazote Pirocabello", [11262] = "Cría de Onyxia", [4334] = "Clamallamas Pirocabello", [4328] = "Horrocrusto Pirocabello", [12129] = "Guarda de Onyxia", [10321] = "Brasaliza", [1749] = "Lady Katrana Prestor", [10184] = "Onyxia"},
		ptBR = {[4329] = "Batedor Flamigrenha", [4323] = "Dragonete Calcinante", [4331] = "Cauda Cinza Flamigrenha", [11262] = "Dragonete Onyxiano", [4334] = "Arauto das Chamas Flamigrenha", [4328] = "Escamorte Flamigrenha", [12129] = "Guardador Onyxiano", [10321] = "Ardeluta", [1749] = "Lady Katrana Prestor", [10184] = "Onyxia"},
		ruRU = {[4329] = "Огнегривый разведчик", [4323] = "Опаляющий малыш дракона", [4331] = "Огнегривый пеплохвост", [11262] = "Дракончик Ониксии", [4334] = "Огнегривая заклинательница пламени", [4328] = "Огнегривый чешуйчатый губитель", [12129] = "Хранитель Ониксии", [10321] = "Огнебор", [1749] = "Леди Катрана Престор", [10184] = "Ониксия"},
		koKR = {[4329] = "화염갈기혈족 정찰병", [4323] = "갓 부화한 화염 새끼용", [4331] = "화염갈기혈족 불꽃술사", [11262] = "오닉시아의 새끼용", [4334] = "화염갈기혈족 불꽃소환사", [4328] = "화염갈기혈족 맹독전사", [12129] = "오닉시아의 수호병", [10321] = "엠버스트라이프", [1749] = "여군주 카트라나 프레스톨", [10184] = "오닉시아"},
		zhCN = {[4329] = "火鬃斥候", [4323] = "灼热龙崽", [4331] = "火鬃灰尾龙人", [11262] = "奥妮克希亚雏龙", [4334] = "火鬃招炎者", [4328] = "火鬃守卫", [12129] = "奥妮克希亚守卫", [10321] = "埃博斯塔夫", [1749] = "女伯爵卡特拉娜·普瑞斯托", [10184] = "奥妮克希亚"},
		zhTW = {[4329] = "火鬃斥候", [4323] = "灼熱幼龍", [4331] = "火鬃灰尾龍裔", [11262] = "奧妮克希亞幼龍", [4334] = "火鬃招炎者", [4328] = "火鬃逆鱗守衛", [12129] = "奧妮克希亞守衛", [10321] = "艾博斯塔夫", [1749] = "卡特拉娜·普瑞斯托女士", [10184] = "奧妮克希亞"},
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
