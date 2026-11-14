-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "ruins", kind = "dungeon", raid = 5, instance = 509, area = 3429,
	levels = { 60, 60 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 15369, 15370, 15348, 15340, 15341, 15339 }, final = 15339,
	name = "Ruins of Ahn'Qiraj",
	title = { frFR = "Ruines d'Ahn'Qiraj", deDE = "Ruinen von Ahn'Qiraj", esES = "Ruinas de Ahn'Qiraj", esMX = "Ruinas de Ahn'Qiraj", ptBR = "Ruínas de Ahn'Qiraj", ruRU = "Руины Ан'Киража", koKR = "안퀴라즈 폐허", zhCN = "安其拉废墟", zhTW = "安其拉廢墟" },
	tint = { 0.46, 0.37, 0.18 }, glow = { 1.00, 0.90, 0.59 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioRuins", pack = "PackRuins", set = "SetRuins",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 15514, 1, 10, 0, 55, 55, 15512, 0, false }, -- Buru Egg
		{ 15333, 1, 1, 0, 55, 55, 13509, 5043, false }, -- Silicate Feeder
		{ 15168, 1, 10, 0, 55, 55, 13096, 719, false }, -- Vile Scarab
		{ 15505, 1, 1, 0, 60, 60, 14528, 642, false }, -- Canal Frenzy
		{ 15319, 1, 10, 0, 60, 60, 15483, 719, false }, -- Hive'Zara Collector
		{ 15318, 1, 10, 0, 60, 60, 12153, 719, false }, -- Hive'Zara Drone
		{ 15521, 1, 10, 0, 60, 60, 11095, 719, false }, -- Hive'Zara Hatchling
		{ 15555, 1, 10, 0, 60, 60, 15554, 5043, false }, -- Hive'Zara Larva
		{ 15461, 1, 10, 0, 60, 60, 12151, 719, false }, -- Shrieker Scarab
		{ 15462, 1, 10, 0, 60, 60, 15464, 719, false }, -- Spitting Scarab
		{ 15323, 1, 10, 0, 61, 61, 11084, 719, false }, -- Hive'Zara Sandstalker
		{ 15320, 1, 10, 0, 61, 61, 15439, 719, false }, -- Hive'Zara Soldier
		{ 15327, 1, 10, 0, 61, 61, 9229, 719, false }, -- Hive'Zara Stinger
		{ 15325, 1, 10, 0, 61, 61, 11142, 719, false }, -- Hive'Zara Wasp
		{ 15389, 1, 10, 0, 63, 63, 15738, 8516, false }, -- Captain Drenn
		{ 15388, 1, 10, 0, 63, 63, 15738, 8516, false }, -- Major Pakkon
		{ 15386, 1, 10, 0, 63, 63, 15738, 8516, false }, -- Major Yeggeth
		{ 15336, 2, 10, 0, 61, 61, 15336, 0, false }, -- Hive'Zara Tail Lasher
		{ 15338, 2, 4, 0, 61, 61, 15343, 739, false }, -- Obsidian Destroyer
		{ 15324, 2, 10, 0, 61, 61, 15741, 8516, false }, -- Qiraji Gladiator
		{ 15343, 2, 10, 0, 61, 61, 15465, 8522, false }, -- Qiraji Swarmguard
		{ 15387, 2, 10, 0, 61, 61, 15437, 8516, false }, -- Qiraji Warrior
		{ 15344, 2, 10, 0, 61, 61, 15354, 8522, false }, -- Swarmguard Needler
		{ 15335, 2, 10, 0, 62, 62, 15463, 724, false }, -- Flesh Hunter
		{ 15391, 2, 10, 0, 63, 63, 15738, 8516, false }, -- Captain Qeez
		{ 15392, 2, 10, 0, 63, 63, 15738, 8516, false }, -- Captain Tuubid
		{ 15390, 2, 10, 0, 63, 63, 15738, 8516, false }, -- Captain Xurrem
		{ 15471, 3, 7, 0, 60, 60, 15688, 5974, true }, -- Lieutenant General Andorov
		{ 15355, 3, 10, 0, 62, 62, 15347, 3485, false }, -- Anubisath Guardian
		{ 15385, 3, 10, 0, 63, 63, 15738, 8516, false }, -- Colonel Zerran
		{ 15369, 4, 10, 0, 63, 63, 15431, 719, false }, -- Ayamiss the Hunter
		{ 15370, 4, 10, 0, 63, 63, 15654, 8546, false }, -- Buru the Gorger
		{ 15348, 4, 10, 0, 63, 63, 15742, 8546, false }, -- Kurinnaxx
		{ 15340, 4, 10, 0, 63, 63, 15392, 739, false }, -- Moam
		{ 15341, 5, 10, 0, 63, 63, 15376, 8516, false }, -- General Rajaxx
		{ 15339, 6, 10, 0, 63, 63, 15432, 8505, false }, -- Ossirian the Unscarred
	},
	names = {
		enUS = {[15514] = "Buru Egg", [15333] = "Silicate Feeder", [15168] = "Vile Scarab", [15505] = "Canal Frenzy", [15319] = "Hive'Zara Collector", [15318] = "Hive'Zara Drone", [15521] = "Hive'Zara Hatchling", [15555] = "Hive'Zara Larva", [15461] = "Shrieker Scarab", [15462] = "Spitting Scarab", [15323] = "Hive'Zara Sandstalker", [15320] = "Hive'Zara Soldier", [15327] = "Hive'Zara Stinger", [15325] = "Hive'Zara Wasp", [15389] = "Captain Drenn", [15388] = "Major Pakkon", [15386] = "Major Yeggeth", [15336] = "Hive'Zara Tail Lasher", [15338] = "Obsidian Destroyer", [15324] = "Qiraji Gladiator", [15343] = "Qiraji Swarmguard", [15387] = "Qiraji Warrior", [15344] = "Swarmguard Needler", [15335] = "Flesh Hunter", [15391] = "Captain Qeez", [15392] = "Captain Tuubid", [15390] = "Captain Xurrem", [15471] = "Lieutenant General Andorov", [15355] = "Anubisath Guardian", [15385] = "Colonel Zerran", [15369] = "Ayamiss the Hunter", [15370] = "Buru the Gorger", [15348] = "Kurinnaxx", [15340] = "Moam", [15341] = "General Rajaxx", [15339] = "Ossirian the Unscarred"},
		frFR = {[15514] = "Œuf de Buru", [15333] = "Nourrisseur silicieux", [15168] = "Scarabée vil", [15505] = "Furie des canaux", [15319] = "Collecteur de la Ruche'Zara", [15318] = "Bourdon de la Ruche'Zara", [15521] = "Jeune de la Ruche'Zara", [15555] = "Larve de la Ruche'Zara", [15461] = "Scarabée hurleur", [15462] = "Scarabée cracheur", [15323] = "Traqueur des sables de la Ruche'Zara", [15320] = "Soldat de la Ruche'Zara", [15327] = "Aiguillonneur de la Ruche'Zara", [15325] = "Guêpe de la Ruche'Zara", [15389] = "Capitaine Drenn", [15388] = "Major Parron", [15386] = "Major Yeggeth", [15336] = "Fouette-queue de la Ruche'Zara", [15338] = "Destructeur d'obsidienne", [15324] = "Gladiateur qiraji", [15343] = "Garde-essaim qiraji", [15387] = "Guerrier qiraji", [15344] = "Piqueur garde-essaim", [15335] = "Chasse-chair", [15391] = "Capitaine Qeez", [15392] = "Capitaine Tuubid", [15390] = "Capitaine Xurrem", [15471] = "Général de division Andorov", [15355] = "Gardien Anubisath", [15385] = "Colonel Zerran", [15369] = "Ayamiss le Chasseur", [15370] = "Buru Grandgosier", [15348] = "Kurinnaxx", [15340] = "Moam", [15341] = "Général Rajaxx", [15339] = "Ossirian l'Intouché"},
		deDE = {[15514] = "Ei von Buru", [15333] = "Silikatfresser", [15168] = "Übler Skarabäus", [15505] = "Kanalfrenzy", [15319] = "Sammler des Zaraschwarms", [15318] = "Drohne des Zaraschwarms", [15521] = "Jungtier des Zaraschwarms", [15555] = "Larve des Zaraschwarms", [15461] = "Kreischerskarabäus", [15462] = "Speiender Skarabäus", [15323] = "Sandpirscher des Zaraschwarms", [15320] = "Soldat des Zaraschwarms", [15327] = "Stecher des Zaraschwarms", [15325] = "Wespe des Zaraschwarms", [15389] = "Captain Drenn", [15388] = "Major Pakkon", [15386] = "Major Yeggeth", [15336] = "Schwanzpeitscher des Zaraschwarms", [15338] = "Obsidianzerstörer", [15324] = "Gladiator der Qiraji", [15343] = "Schwarmwache der Qiraji", [15387] = "Krieger der Qiraji", [15344] = "Nadelspeiende Schwarmwache", [15335] = "Fleischjäger", [15391] = "Captain Qeez", [15392] = "Captain Tuubid", [15390] = "Captain Xurrem", [15471] = "Generallieutenant Andorov", [15355] = "Beschützer des Anubisath", [15385] = "Colonel Zerran", [15369] = "Ayamiss der Jäger", [15370] = "Buru der Verschlinger", [15348] = "Kurinnaxx", [15340] = "Moam", [15341] = "General Rajaxx", [15339] = "Ossirian der Narbenlose"},
		esES = {[15514] = "Huevo Buru", [15333] = "Alimentador silítido", [15168] = "Escarabajo vil", [15505] = "Furia de canal", [15319] = "Coleccionista Colmen'Zara", [15318] = "Zángano Colmen'Zara", [15521] = "Prole de Colmen'Zara", [15555] = "Larva Colmen'Zara", [15461] = "Escarabajo chillón", [15462] = "Escarabajo escupidor", [15323] = "Acecharenas Colmen'Zara", [15320] = "Soldado Colmen'Zara", [15327] = "Aguijonero Colmen'Zara", [15325] = "Avispa Colmen'Zara", [15389] = "Capitán Drenn", [15388] = "Mayor Pakkon", [15386] = "Mayor Yeggeth", [15336] = "Colazote Colmen'Zara", [15338] = "Destructor obsidiano", [15324] = "Gladiador qiraji", [15343] = "Guardaenjambre qiraji", [15387] = "Guerrero qiraji", [15344] = "Aguja guardaenjambres", [15335] = "Cazador de carne", [15391] = "Capitán Condurso", [15392] = "Capitán Tuubid", [15390] = "Capitán Xurrem", [15471] = "Teniente general Andorov", [15355] = "Guardián Anubisath", [15385] = "Coronel Zerran", [15369] = "Ayamiss el Cazador", [15370] = "Buru el Manducador", [15348] = "Kurinnaxx", [15340] = "Moam", [15341] = "General Rajaxx", [15339] = "Osirio el Sinmarcas"},
		esMX = {[15514] = "Huevo Buru", [15333] = "Alimentador silítido", [15168] = "Escarabajo vil", [15505] = "Furia de canal", [15319] = "Coleccionista Colmen'Zara", [15318] = "Zángano Colmen'Zara", [15521] = "Prole de Colmen'Zara", [15555] = "Larva Colmen'Zara", [15461] = "Escarabajo chillón", [15462] = "Escarabajo escupidor", [15323] = "Acecharenas Colmen'Zara", [15320] = "Soldado Colmen'Zara", [15327] = "Aguijonero Colmen'Zara", [15325] = "Avispa Colmen'Zara", [15389] = "Capitán Drenn", [15388] = "Mayor Pakkon", [15386] = "Mayor Yeggeth", [15336] = "Colazote Colmen'Zara", [15338] = "Destructor obsidiano", [15324] = "Gladiador qiraji", [15343] = "Guardaenjambre qiraji", [15387] = "Guerrero qiraji", [15344] = "Aguja guardaenjambres", [15335] = "Cazador de carne", [15391] = "Capitán Condurso", [15392] = "Capitán Tuubid", [15390] = "Capitán Xurrem", [15471] = "Teniente general Andorov", [15355] = "Guardián Anubisath", [15385] = "Coronel Zerran", [15369] = "Ayamiss el Cazador", [15370] = "Buru el Manducador", [15348] = "Kurinnaxx", [15340] = "Moam", [15341] = "General Rajaxx", [15339] = "Osirio el Sinmarcas"},
		ptBR = {[15514] = "Ovo de Buru", [15333] = "Comedor de Silicato", [15168] = "Escaravelho Torpe", [15505] = "Farnesim do Canal", [15319] = "Recolhedor Colme'Zara", [15318] = "Zangão Colme'Zara", [15521] = "Pupa Colme'Zara", [15555] = "Larva Colme'Zara", [15461] = "Escaravelho Gritador", [15462] = "Escaravelho Cuspidor", [15323] = "Espreitareia Colme'Zara", [15320] = "Soldado Colme'Zara", [15327] = "Aguilhante Colme'Zara", [15325] = "Vespa Colme'Zara", [15389] = "Capitão Drenn", [15388] = "Major Pakkon", [15386] = "Major Yeggeth", [15336] = "Caudaçoite Colme'Zara", [15338] = "Destruidor Obsidiano", [15324] = "Gladiador Qiraji", [15343] = "Zanguarda Qiraji", [15387] = "Guerreiro Qiraji", [15344] = "Zanguarda Agulheira", [15335] = "Caça-carne", [15391] = "Capitão Qeez", [15392] = "Capitão Tuubid", [15390] = "Capitão Xurrem", [15471] = "Tenente-general Andorov", [15355] = "Guardião Anubisath", [15385] = "Coronel Zerran", [15369] = "Ayamiss, o Caçador", [15370] = "Buru, o Banqueteador", [15348] = "Korinnaxx", [15340] = "Moam", [15341] = "General Rajaxx", [15339] = "Ossirian, o Intocado"},
		ruRU = {[15514] = "Яйцо Буру", [15333] = "Кремнежорка", [15168] = "Коварный скарабей", [15505] = "Канальная бешенка", [15319] = "Сборщик из улья Зара", [15318] = "Трутень из улья Зара", [15521] = "Личинка из улья Зара", [15555] = "Личинка из улья Зара", [15461] = "Скарабей-визгун", [15462] = "Плюющийся скарабей", [15323] = "Пескоброд из улья Зара", [15320] = "Солдат из улья Зара", [15327] = "Острожал из улья Зара", [15325] = "Оса из улья Зара", [15389] = "Капитан Дренн", [15388] = "Майор Паккон", [15386] = "Майор Йеггет", [15336] = "Бичехвост из улья Зара", [15338] = "Обсидиановый разрушитель", [15324] = "Киражский гладиатор", [15343] = "Страж роя-кираж", [15387] = "Киражский воин", [15344] = "Иглокол-страж роя", [15335] = "Плотоед", [15391] = "Капитан Квиз", [15392] = "Капитан Туубид", [15390] = "Капитан Ксуррем", [15471] = "Генерал-лейтенант Андоров", [15355] = "Анубисат-страж", [15385] = "Полковник Зерран", [15369] = "Аямисса Охотница", [15370] = "Буру Ненасытный", [15348] = "Куриннакс", [15340] = "Моам", [15341] = "Генерал Раджакс", [15339] = "Оссириан Неуязвимый"},
		koKR = {[15514] = "부루의 알", [15333] = "소금모래 청소부", [15168] = "청소부 스카라베", [15505] = "운하 프렌지", [15319] = "채집꾼 하이브자라", [15318] = "일꾼 하이브자라", [15521] = "새끼 하이브자라", [15555] = "하이브자라 유충", [15461] = "비명소리 스카라베", [15462] = "독액 스카라베", [15323] = "모래무지 하이브자라", [15320] = "병정 하이브자라", [15327] = "쐐기 하이브자라", [15325] = "독침 하이브자라", [15389] = "부대장 드렌", [15388] = "부사령관 팍콘", [15386] = "부사령관 예게스", [15336] = "채찍꼬리 하이브자라", [15338] = "흑요석 파괴자", [15324] = "퀴라지 투사", [15343] = "퀴라지 감시병", [15387] = "퀴라지 전사", [15344] = "가시쐐기 감시병", [15335] = "청소부 수액괴물", [15391] = "부대장 퀴즈", [15392] = "부대장 투비드", [15390] = "부대장 수렘", [15471] = "사령관 안도로브", [15355] = "아누비사스 감시자", [15385] = "사령관 제란", [15369] = "사냥꾼 아야미스", [15370] = "먹보 부루", [15348] = "쿠린낙스", [15340] = "모암", [15341] = "장군 라작스", [15339] = "무적의 오시리안"},
		zhCN = {[15514] = "布鲁的卵", [15333] = "硅酸盐吞噬者", [15168] = "邪恶甲虫", [15505] = "运河狂鱼", [15319] = "佐拉采集者", [15318] = "佐拉雄蜂", [15521] = "扎拉雏虫", [15555] = "扎拉幼虫", [15461] = "食脑甲虫", [15462] = "喷液甲虫", [15323] = "佐拉沙行者", [15320] = "佐拉士兵", [15327] = "佐拉钉刺者", [15325] = "佐拉黄蜂", [15389] = "德雷恩上尉", [15388] = "帕库少校", [15386] = "耶吉斯少校", [15336] = "佐拉鞭尾蝎", [15338] = "黑曜石毁灭者", [15324] = "其拉角斗士", [15343] = "其拉虫群卫士", [15387] = "其拉战士", [15344] = "虫群守卫钉刺者", [15335] = "血肉猎手", [15391] = "奎兹上尉", [15392] = "图比德上尉", [15390] = "库雷姆上尉", [15471] = "安多洛夫中将", [15355] = "阿努比萨斯守卫者", [15385] = "泽兰上校", [15369] = "狩猎者阿亚米斯", [15370] = "吞咽者布鲁", [15348] = "库林纳克斯", [15340] = "莫阿姆", [15341] = "拉贾克斯将军", [15339] = "无疤者奥斯里安"},
		zhTW = {[15514] = "布魯的卵", [15333] = "矽酸鹽吞噬者", [15168] = "邪惡的甲蟲", [15505] = "運河狂魚", [15319] = "札拉採集者", [15318] = "札拉雄蜂", [15521] = "札拉雛蟲", [15555] = "札拉幼蟲", [15461] = "食腦甲蟲", [15462] = "噴液甲蟲", [15323] = "札拉沙行者", [15320] = "札拉士兵", [15327] = "札拉毒蠍", [15325] = "札拉異種蠍", [15389] = "德蘭上尉", [15388] = "帕康少校", [15386] = "葉吉斯少校", [15336] = "札拉鞭尾蠍", [15338] = "黑曜石毀滅者", [15324] = "其拉角鬥士", [15343] = "其拉蟲群衛士", [15387] = "其拉戰士", [15344] = "蟲群守衛尼德勒", [15335] = "血肉獵手", [15391] = "奎茲上尉", [15392] = "圖畢德上尉", [15390] = "瑟瑞姆上尉", [15471] = "安多洛夫中將", [15355] = "阿努比薩斯守衛者", [15385] = "澤朗上校", [15369] = "『狩獵者』阿亞米斯", [15370] = "『暴食者』布魯", [15348] = "庫林納克斯", [15340] = "莫阿姆", [15341] = "拉賈克斯將軍", [15339] = "『無疤者』奧斯里安"},
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
