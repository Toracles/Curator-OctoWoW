-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "blackfathom", kind = "dungeon", instance = 48, area = 719,
	levels = { 24, 32 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 4887, 4831, 6243, 12902, 4830, 4832, 4829 }, final = 4829,
	name = "Blackfathom Deeps",
	title = { frFR = "Profondeurs de Brassenoire", deDE = "Blackfathom-Tiefe", esES = "Cavernas de Brazanegra", esMX = "Cavernas de Brazanegra", ptBR = "Profundezas Negras", ruRU = "Непроглядная Пучина", koKR = "검은심연의 나락", zhCN = "黑暗深渊" },
	tint = { 0.08, 0.20, 0.36 }, glow = { 0.36, 0.72, 1.00 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioBlackfathom", pack = "PackBlackfathom", set = "SetBlackfathom",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 4807, 1, 7, 0, 22, 23, 4762, 3438, false }, -- Blackfathom Myrmidon
		{ 4818, 1, 7, 0, 22, 23, 4920, 416, false }, -- Blindlight Murloc
		{ 4815, 1, 7, 0, 22, 23, 2835, 1452, false }, -- Murkshallow Snapclaw
		{ 4821, 1, 1, 8, 22, 23, 981, 1230, false }, -- Skittering Crustacean
		{ 4824, 1, 1, 21, 23, 24, 1244, 1464, false }, -- Aku'mai Fisher
		{ 4805, 1, 7, 0, 23, 24, 4982, 4025, false }, -- Blackfathom Sea Witch
		{ 4798, 1, 3, 0, 23, 24, 2014, 1010, false }, -- Fallenroot Shadowstalker
		{ 4822, 1, 1, 8, 23, 24, 1001, 1230, false }, -- Snapping Crustacean
		{ 4827, 1, 1, 0, 24, 25, 2836, 1236, false }, -- Deep Pool Threshfin
		{ 4799, 1, 3, 0, 24, 25, 2021, 1010, false }, -- Fallenroot Hellcaller
		{ 4809, 1, 7, 0, 24, 25, 2882, 1352, false }, -- Twilight Acolyte
		{ 4812, 1, 7, 0, 24, 25, 2894, 1352, false }, -- Twilight Loreseeker
		{ 4823, 2, 1, 8, 25, 26, 9565, 1230, false }, -- Barbed Crustacean
		{ 4819, 2, 7, 0, 25, 25, 11293, 416, false }, -- Blindlight Muckdweller
		{ 4820, 2, 7, 0, 25, 25, 3617, 416, false }, -- Blindlight Oracle
		{ 4811, 2, 7, 0, 25, 26, 2886, 2960, false }, -- Twilight Aquamancer
		{ 4810, 2, 7, 0, 25, 26, 2898, 1034, false }, -- Twilight Reaver
		{ 4825, 2, 1, 21, 26, 27, 5026, 1464, false }, -- Aku'mai Snapjaw
		{ 4814, 2, 7, 0, 26, 27, 2890, 1346, false }, -- Twilight Elementalist
		{ 4813, 2, 7, 0, 26, 27, 2876, 1361, false }, -- Twilight Shadowmage
		{ 4787, 3, 7, 0, 18, 18, 4946, 5992, true }, -- Argent Guard Thaelrid
		{ 4887, 4, 1, 21, 25, 25, 5027, 1464, false }, -- Ghamoo-ra
		{ 4831, 4, 7, 0, 25, 25, 4979, 4025, false }, -- Lady Sarevess
		{ 6243, 4, 7, 0, 26, 26, 1773, 416, false }, -- Gelihast
		{ 12902, 4, 7, 0, 26, 26, 12822, 1328, false }, -- Lorgus Jett
		{ 4830, 4, 1, 0, 26, 26, 1816, 1236, false }, -- Old Serra'kis
		{ 4832, 5, 7, 0, 27, 27, 4939, 1346, false }, -- Twilight Lord Kelris
		{ 4829, 6, 10, 0, 28, 28, 2837, 455, false }, -- Aku'mai
	},
	names = {
		enUS = {[4807] = "Blackfathom Myrmidon", [4818] = "Blindlight Murloc", [4815] = "Murkshallow Snapclaw", [4821] = "Skittering Crustacean", [4824] = "Aku'mai Fisher", [4805] = "Blackfathom Sea Witch", [4798] = "Fallenroot Shadowstalker", [4822] = "Snapping Crustacean", [4827] = "Deep Pool Threshfin", [4799] = "Fallenroot Hellcaller", [4809] = "Twilight Acolyte", [4812] = "Twilight Loreseeker", [4823] = "Barbed Crustacean", [4819] = "Blindlight Muckdweller", [4820] = "Blindlight Oracle", [4811] = "Twilight Aquamancer", [4810] = "Twilight Reaver", [4825] = "Aku'mai Snapjaw", [4814] = "Twilight Elementalist", [4813] = "Twilight Shadowmage", [4787] = "Argent Guard Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Lady Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Old Serra'kis", [4832] = "Twilight Lord Kelris", [4829] = "Aku'mai"},
		frFR = {[4807] = "Myrmidon de Brassenoire", [4818] = "Murloc Noctant", [4815] = "Claque-pinces Troublefond", [4821] = "Crustacé luisant", [4824] = "Pêcheur Aku'mai", [4805] = "Sorcière des mers de Brassenoire", [4798] = "Traqueur des ombres Sans-racines", [4822] = "Crustacé carnassier", [4827] = "Battraileron du bassin profond", [4799] = "Invocateur infernal Sans-racines", [4809] = "Acolyte du crépuscule", [4812] = "Erudit du crépuscule", [4823] = "Crustacé épineux", [4819] = "Marche-boue Noctant", [4820] = "Oracle Noctant", [4811] = "Aquamancien du crépuscule", [4810] = "Ravageur du crépuscule", [4825] = "Gueule d'acier d'Aku'mai", [4814] = "Elémentaliste du crépuscule", [4813] = "Ombremage du crépuscule", [4787] = "Garde d’argent Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Dame Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Vieux Serra'kis", [4832] = "Seigneur du crépuscule Kelris", [4829] = "Aku'mai"},
		deDE = {[4807] = "Blackfathom-Myrmidone", [4818] = "Murloc der Nachtaugen", [4815] = "Untiefenschnappklaue", [4821] = "Huschendes Krustentier", [4824] = "Aku'mai-Angler", [4805] = "Blackfathom-Meerhexe", [4798] = "Schattenpirscher der Leidbringer", [4822] = "Schnappendes Krustentier", [4827] = "Tiefteichdreschflosse", [4799] = "Höllenrufer der Leidbringer", [4809] = "Twilight-Akolyt", [4812] = "Twilight-Bewahrer der Lehren", [4823] = "Stacheliges Krustentier", [4819] = "Matschkrabbler der Nachtaugen", [4820] = "Orakel der Nachtaugen", [4811] = "Twilight-Aquamant", [4810] = "Twilight-Häscher", [4825] = "Aku'mai-Schnappkiefer", [4814] = "Twilight-Elementarist", [4813] = "Twilight-Schattenmagier", [4787] = "Argentumwache Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Lady Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Old Serra'kis", [4832] = "Twilight-Lord Kelris", [4829] = "Aku'mai"},
		esES = {[4807] = "Mirmidón Brazanegra", [4818] = "Múrloc Cegaluz", [4815] = "Quebrador Sombroscura", [4821] = "Crustarácnido", [4824] = "Pescador Aku'mai", [4805] = "Bruja de mar Brazanegra", [4798] = "Acechasombras Malarraíz", [4822] = "Crustáceo mordedor", [4827] = "Trillasín de la fosa profunda", [4799] = "Clamainferno Malarraíz", [4809] = "Acólito Crepuscular", [4812] = "Cazatumbres Crepuscular", [4823] = "Crustáceo espinoso", [4819] = "Habitabosta Cegaluz", [4820] = "Oráculo Cegaluz", [4811] = "Aquamántivo Crepuscular", [4810] = "Atracador Crepuscular", [4825] = "Quijaforte Aku'mai", [4814] = "Elementalista Crepuscular", [4813] = "Mago oscuro Crepuscular", [4787] = "Guardia Argenta Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Lady Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Viejo Serra'kis", [4832] = "Señor Crepuscular Kelris", [4829] = "Aku'mai"},
		esMX = {[4807] = "Mirmidón Brazanegra", [4818] = "Múrloc Cegaluz", [4815] = "Quebrador Sombroscura", [4821] = "Crustarácnido", [4824] = "Pescador Aku'mai", [4805] = "Bruja de mar Brazanegra", [4798] = "Acechasombras Malarraíz", [4822] = "Crustáceo mordedor", [4827] = "Trillasín de la fosa profunda", [4799] = "Clamainferno Malarraíz", [4809] = "Acólito Crepuscular", [4812] = "Cazatumbres Crepuscular", [4823] = "Crustáceo espinoso", [4819] = "Habitabosta Cegaluz", [4820] = "Oráculo Cegaluz", [4811] = "Aquamántivo Crepuscular", [4810] = "Atracador Crepuscular", [4825] = "Quijaforte Aku'mai", [4814] = "Elementalista Crepuscular", [4813] = "Mago oscuro Crepuscular", [4787] = "Guardia Argenta Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Lady Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Viejo Serra'kis", [4832] = "Señor Crepuscular Kelris", [4829] = "Aku'mai"},
		ptBR = {[4807] = "Mirmidão das Profundezas Negras", [4818] = "Murloc Cegalume", [4815] = "Batenaz Covarrasa", [4821] = "Crustáceo Deslizante", [4824] = "Aku'mai Pescadora", [4805] = "Bruxa do Mar das Profundezas Negras", [4798] = "Assombrante Satíricon", [4822] = "Crustáceo Mordedor", [4827] = "Manguadonte da Poça Funda", [4799] = "Infernarauto Satíricon", [4809] = "Acólito do Crepúsculo", [4812] = "Pesquisador do Crepúsculo", [4823] = "Crustáceo Farpado", [4819] = "Moralodo Cegalume", [4820] = "Oráculo Cegalume", [4811] = "Aquamante do Crepúsculo", [4810] = "Aniquilador do Crepúsculo", [4825] = "Mordelisca Aku'mai", [4814] = "Elementalista do Crepúsculo", [4813] = "Umbramante do Crepúsculo", [4787] = "Guarda Argênteo Thaelrid", [4887] = "Ghamoo-ra", [4831] = "Lady Sarevess", [6243] = "Gelihast", [12902] = "Lorgus Jett", [4830] = "Velho Serra'kis", [4832] = "Senhor do Crepúsculo Kelris", [4829] = "Aku'mai"},
		ruRU = {[4807] = "Мирмидон Непроглядной Пучины", [4818] = "Мурлок из племени Мутной Воды", [4815] = "Мелководный клешнехват", [4821] = "Стремительное ракообразное", [4824] = "Рыбоед Аку'май", [4805] = "Морская ведьма Непроглядной Пучины", [4798] = "Тенелов из племени Змеящегося Корня", [4822] = "Ракообразный клешнехват", [4827] = "Глубинный крепкозуб", [4799] = "Призыватель огня из племени Змеящегося Корня", [4809] = "Служитель из культа Сумеречного Молота", [4812] = "Летописец из культа Сумеречного Молота", [4823] = "Колючий членистоног", [4819] = "Грязекоп из племени Мутной Воды", [4820] = "Оракул из племени Мутной Воды", [4811] = "Аквамант из культа Сумеречного Молота", [4810] = "Разоритель из культа Сумеречного Молота", [4825] = "Хрустогрыз Аку'май", [4814] = "Повелитель стихий из культа Сумеречного Молота", [4813] = "Темный маг из культа Сумеречного Молота", [4787] = "Страж Талрид из ордена Серебряного Рассвета", [4887] = "Гхаму-ра", [4831] = "Леди Саревесс", [6243] = "Гелихаст", [12902] = "Лоргус Джетт", [4830] = "Старина Серракис", [4832] = "Повелитель сумрака Келрис", [4829] = "Аку'май"},
		koKR = {[4807] = "검은심연의 미르미돈", [4818] = "유리비늘멀록 멀록", [4815] = "집게발 검은모래톱마크루라", [4821] = "뾰족껍질게", [4824] = "아쿠마이거북", [4805] = "검은심연의 바다마녀", [4798] = "썩은뿌리의 그림자추적자", [4822] = "집게껍질게", [4827] = "깊은웅덩이 트레샤돈", [4799] = "썩은뿌리의 지옥소환사", [4809] = "황혼의망치단 수행사제", [4812] = "황혼의망치단 진리탐구자", [4823] = "가시껍질게", [4819] = "유리비늘멀록 땅꾼", [4820] = "유리비늘멀록 점쟁이", [4811] = "황혼의망치단 정령사", [4810] = "황혼의망치단 약탈자", [4825] = "무쇠턱 아쿠마이거북", [4814] = "황혼의망치단 원소마법사", [4813] = "황혼의망치단 흑마법사", [4787] = "은빛경비병 타엘리드", [4887] = "가무라", [4831] = "여왕 사레베스", [6243] = "겔리하스트", [12902] = "로구스 제트", [4830] = "늙은 세라키스", [4832] = "황혼의 군주 켈리스", [4829] = "아쿠마이"},
		zhCN = {[4807] = "黑暗深渊仆从", [4818] = "盲光鱼人", [4815] = "巨钳黑泥龙虾人", [4821] = "滑腻的甲壳蟹", [4824] = "阿库麦尔食鱼龟", [4805] = "黑暗深渊海巫", [4798] = "腐根巡影者", [4822] = "巨钳甲壳蟹", [4827] = "深池蛇颈龙", [4799] = "腐根唤魔者", [4809] = "暮光侍僧", [4812] = "暮光寻知者", [4823] = "刺毛甲壳蟹", [4819] = "盲光泥居者", [4820] = "盲光先知", [4811] = "暮光水占师", [4810] = "暮光劫掠者", [4825] = "阿库麦尔钳嘴龟", [4814] = "暮光元素法师", [4813] = "暮光暗法师", [4787] = "银月守卫塞尔瑞德", [4887] = "加摩拉", [4831] = "萨利维丝", [6243] = "格里哈斯特", [12902] = "洛古斯·杰特", [4830] = "瑟拉吉斯", [4832] = "梦游者克尔里斯", [4829] = "阿库麦尔"},
		zhTW = {[4807] = "黑暗深淵僕從", [4818] = "盲光魚人", [4815] = "巨鉗黑泥龍蝦人", [4821] = "滑膩的甲殼蟹", [4824] = "阿庫麥爾食魚龜", [4805] = "黑暗深淵海巫", [4798] = "腐根巡影者", [4822] = "巨鉗甲殼蟹", [4827] = "深池蛇頸龍", [4799] = "腐根喚魔者", [4809] = "暮光侍僧", [4812] = "暮光尋知者", [4823] = "刺毛甲殼蟹", [4819] = "盲光泥居者", [4820] = "盲光神諭者", [4811] = "暮光水占師", [4810] = "暮光搶奪者", [4825] = "阿庫麥爾鉗嘴龜", [4814] = "暮光元素法師", [4813] = "暮光暗影法師", [4787] = "銀色黎明守衛塞爾瑞德", [4887] = "加摩拉", [4831] = "薩利維絲女士", [6243] = "格里哈斯特", [12902] = "洛古斯·傑特", [4830] = "瑟拉吉斯", [4832] = "暮光領主克爾里斯", [4829] = "阿庫麥爾"},
	},
	subs = {
		enUS = {[4787] = "The Argent Dawn"},
		frFR = {[4787] = "L'Aube d'argent"},
		deDE = {[4787] = "Die Argentumdämmerung"},
		esES = {[4787] = "El Alba Argenta"},
		esMX = {[4787] = "El Alba Argenta"},
		ptBR = {[4787] = "A Aurora Argêntea"},
		ruRU = {[4787] = "Серебряный Рассвет"},
		koKR = {[4787] = "은빛 여명회"},
		zhCN = {[4787] = "银色黎明"},
		zhTW = {[4787] = "銀色黎明"},
	},
}
