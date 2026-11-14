-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "ragefire", kind = "dungeon", instance = 389, area = 2437,
	levels = { 13, 18 }, side = "H",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 11519, 11517, 11518, 11520 }, final = 11520,
	name = "Ragefire Chasm",
	title = { frFR = "Gouffre de Ragefeu", deDE = "Ragefireabgrund", esES = "Sima Ígnea", esMX = "Sima Ígnea", ptBR = "Cavernas Ígneas", ruRU = "Огненная пропасть", koKR = "성난불길 협곡", zhCN = "怒焰裂谷" },
	tint = { 0.46, 0.12, 0.06 }, glow = { 1.00, 0.46, 0.18 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioRagefire", pack = "PackRagefire", set = "SetRagefire",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 11320, 1, 1, 0, 13, 14, 11010, 5043, false }, -- Earthborer
		{ 11321, 1, 4, 0, 13, 15, 2075, 739, false }, -- Molten Elemental
		{ 11319, 1, 7, 0, 13, 15, 11610, 659, false }, -- Ragefire Shaman
		{ 11318, 1, 7, 0, 13, 15, 11609, 659, false }, -- Ragefire Trogg
		{ 11322, 1, 7, 0, 13, 15, 11434, 1346, false }, -- Searing Blade Cultist
		{ 11323, 2, 7, 0, 13, 15, 11430, 1346, false }, -- Searing Blade Enforcer
		{ 11324, 2, 7, 0, 13, 15, 11438, 1346, false }, -- Searing Blade Warlock
		{ 11834, 3, 7, 0, 14, 14, 11755, 6008, true }, -- Maur Grimtotem
		{ 11519, 4, 7, 0, 16, 16, 2007, 1010, false }, -- Bazzalan
		{ 11517, 4, 7, 0, 16, 16, 11611, 659, false }, -- Oggleflint
		{ 11518, 5, 7, 0, 16, 16, 11429, 1346, false }, -- Jergosh the Invoker
		{ 11520, 6, 7, 0, 16, 16, 7970, 1102, false }, -- Taragaman the Hungerer
	},
	names = {
		enUS = {[11320] = "Earthborer", [11321] = "Molten Elemental", [11319] = "Ragefire Shaman", [11318] = "Ragefire Trogg", [11322] = "Searing Blade Cultist", [11323] = "Searing Blade Enforcer", [11324] = "Searing Blade Warlock", [11834] = "Maur Grimtotem", [11519] = "Bazzalan", [11517] = "Oggleflint", [11518] = "Jergosh the Invoker", [11520] = "Taragaman the Hungerer"},
		frFR = {[11320] = "Fouisseur", [11321] = "Elémentaire de lave", [11319] = "Chaman Ragefeu", [11318] = "Trogg Ragefeu", [11322] = "Sectateur de la Lame brûlante", [11323] = "Massacreur de la Lame brûlante", [11324] = "Démoniste de la Lame brûlante", [11834] = "Maur Grimtotem", [11519] = "Bazzalan", [11517] = "Lorgnesilex", [11518] = "Jergosh l'Invocateur", [11520] = "Taragaman l'Affameur"},
		deDE = {[11320] = "Erdbohrer", [11321] = "Geschmolzener Elementar", [11319] = "Ragefire-Schamane", [11318] = "Ragefire-Trogg", [11322] = "Searingblade-Kultist", [11323] = "Searingblade-Vollstrecker", [11324] = "Searingblade-Hexenmeister", [11834] = "Maur Grimmtotem", [11519] = "Bazzalan", [11517] = "Flintauge", [11518] = "Jergosh der Herbeirufer", [11520] = "Taragaman der Hungerleider"},
		esES = {[11320] = "Cavatierra", [11321] = "Elemental fundido", [11319] = "Chamán Furia Ardiente", [11318] = "Trogg Furia Ardiente", [11322] = "Fiel abrasador", [11323] = "Déspota abrasador", [11324] = "Brujo abrasador", [11834] = "Maur Tótem Siniestro", [11519] = "Bazzalan", [11517] = "Ogglesílex", [11518] = "Jergosh el Conjurador", [11520] = "Taragaman el Hambriento"},
		esMX = {[11320] = "Cavatierra", [11321] = "Elemental fundido", [11319] = "Chamán Furia Ardiente", [11318] = "Trogg Furia Ardiente", [11322] = "Cultor Hoja Abrasadora", [11323] = "Déspota Hoja Abrasadora", [11324] = "Brujo Hoja Abrasadora", [11834] = "Maur Tótem Siniestro", [11519] = "Bazzalan", [11517] = "Ogglesílex", [11518] = "Jergosh el Convocador", [11520] = "Taragaman el Hambriento"},
		ptBR = {[11320] = "Furaterra", [11321] = "Elemental Derretido", [11319] = "Xamã Iraflama", [11318] = "Trogg Iraflama", [11322] = "Sectário da Lâmina Calcinante", [11323] = "Impositor da Lâmina Calcinante", [11324] = "Bruxo da Lâmina Calcinante", [11834] = "Mauren Temível Totem", [11519] = "Bazzalan", [11517] = "Pederneiro", [11518] = "Jergosh, o Invocador", [11520] = "Taragaman, o Famélico"},
		ruRU = {[11320] = "Землеед", [11321] = "Оплавленный элементаль", [11319] = "Шаман Огненной пропасти", [11318] = "Трогг Огненной пропасти", [11322] = "Сектант из клана Огненного Клинка", [11323] = "Головорез из клана Огненного Клинка", [11324] = "Чернокнижник из клана Огненного Клинка", [11834] = "Маур Зловещий Тотем", [11519] = "Баззалан", [11517] = "Огглфлинт", [11518] = "Жергош Призыватель Духов", [11520] = "Тарагаман Ненасытный"},
		koKR = {[11320] = "땅벌레", [11321] = "녹아내리는 정령", [11319] = "성난불길일족 주술사", [11318] = "성난불길 트로그", [11322] = "이글거리는 칼날단 이교도", [11323] = "이글거리는 칼날단 집행자", [11324] = "이글거리는 칼날단 흑마법사", [11834] = "마우르 그림토템", [11519] = "바잘란", [11517] = "오글플린트", [11518] = "기원사 제로쉬", [11520] = "욕망의 타라가만"},
		zhCN = {[11320] = "钻土虫", [11321] = "熔岩元素", [11319] = "怒焰萨满祭司", [11318] = "怒焰穴居人", [11322] = "燃刃信徒", [11323] = "燃刃执行者", [11324] = "燃刃术士", [11834] = "玛尔·恐怖图腾", [11519] = "巴扎兰", [11517] = "奥格弗林特", [11518] = "祈求者耶戈什", [11520] = "饥饿者塔拉加曼"},
		zhTW = {[11320] = "鑽土蟲", [11321] = "熔岩元素", [11319] = "怒焰薩滿", [11318] = "怒焰穴居人", [11322] = "燃刃信徒", [11323] = "燃刃執行者", [11324] = "燃刃術士", [11834] = "瑪爾·恐怖圖騰", [11519] = "巴札蘭", [11517] = "奧格弗林特", [11518] = "『塑能師』耶戈什", [11520] = "『飢餓者』塔拉加曼"},
	},
	subs = {
		enUS = {[11517] = "Ragefire Chieftain"},
		frFR = {[11517] = "Chef Ragefeu"},
		deDE = {[11517] = "Ragefire-Häuptling"},
		esES = {[11517] = "Jefe Furia Ardiente"},
		esMX = {[11517] = "Jefe Furia Ardiente"},
		ptBR = {[11517] = "Chefe Ígneo"},
		ruRU = {[11517] = "Вождь племени Бушующего Пламени"},
		koKR = {[11517] = "성난불길일족 족장"},
		zhCN = {[11517] = "怒焰酋长"},
		zhTW = {[11517] = "怒焰酋長"},
	},
}
