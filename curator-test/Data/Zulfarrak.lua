-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "zulfarrak", kind = "dungeon", instance = 209, area = 1176,
	levels = { 44, 54 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 7795, 7796, 7797, 7272, 7271, 7275, 8127, 7273, 7267 }, final = 7267,
	name = "Zul'Farrak",
	title = { frFR = "Zul'Farrak", deDE = "Zul'Farrak", esES = "Zul'Farrak", esMX = "Zul'Farrak", ptBR = "Zul'Farrak", ruRU = "Зул'Фаррак", koKR = "줄파락", zhCN = "祖尔法拉克" },
	tint = { 0.49, 0.37, 0.18 }, glow = { 1.00, 0.86, 0.59 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioZulfarrak", pack = "PackZulfarrak", set = "SetZulfarrak",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 8130, 1, 10, 0, 30, 35, 1073, 570, false }, -- Sul'lithuz Hatchling
		{ 5648, 1, 7, 0, 43, 44, 6419, 1034, false }, -- Sandfury Shadowcaster
		{ 5649, 1, 7, 0, 44, 45, 6423, 1034, false }, -- Sandfury Blood Drinker
		{ 5650, 1, 7, 0, 44, 45, 6421, 1034, false }, -- Sandfury Witch Doctor
		{ 7269, 1, 1, 0, 44, 46, 7470, 719, false }, -- Scarab
		{ 7246, 1, 7, 0, 45, 46, 6425, 1034, false }, -- Sandfury Shadowhunter
		{ 7247, 1, 7, 0, 45, 46, 6427, 1034, false }, -- Sandfury Soul Eater
		{ 7607, 2, 7, 0, 43, 43, 7222, 5964, true }, -- Weegli Blastfuse
		{ 7608, 2, 7, 0, 44, 44, 6438, 5913, true }, -- Murta Grimgut
		{ 7606, 2, 7, 0, 44, 44, 6432, 6024, true }, -- Oro Eyegouge
		{ 7605, 2, 7, 0, 44, 44, 6435, 5986, true }, -- Raven
		{ 7268, 2, 1, 0, 45, 46, 4305, 4499, false }, -- Sandfury Guardian
		{ 8095, 2, 1, 0, 45, 47, 7345, 570, false }, -- Sul'lithuz Sandcrawler
		{ 7274, 2, 7, 0, 46, 46, 6440, 1034, false }, -- Sandfury Executioner
		{ 8120, 2, 10, 0, 47, 47, 7345, 570, false }, -- Sul'lithuz Abomination
		{ 10081, 3, 7, 0, 45, 45, 9292, 1034, false }, -- Dustwraith
		{ 10080, 3, 7, 0, 45, 45, 9291, 1034, false }, -- Sandarr Dunereaver
		{ 7604, 3, 7, 0, 45, 45, 6433, 5977, true }, -- Sergeant Bly
		{ 10082, 3, 7, 0, 45, 45, 9293, 1034, false }, -- Zerillis
		{ 7795, 4, 7, 0, 46, 46, 6685, 3301, false }, -- Hydromancer Velratha
		{ 7796, 4, 6, 0, 46, 46, 6690, 1034, false }, -- Nekrum Gutchewer
		{ 7797, 4, 7, 0, 46, 46, 6687, 1034, false }, -- Ruuzlu
		{ 7272, 4, 6, 0, 46, 46, 6696, 1034, false }, -- Theka the Martyr
		{ 7271, 4, 7, 0, 46, 46, 6434, 5940, true }, -- Witch Doctor Zum'rah
		{ 7275, 4, 7, 0, 47, 47, 6441, 1034, false }, -- Shadowpriest Sezz'ziz
		{ 8127, 4, 7, 0, 48, 48, 7353, 1034, false }, -- Antu'sul
		{ 7273, 5, 10, 0, 46, 46, 7271, 455, false }, -- Gahz'rilla
		{ 7267, 6, 7, 0, 48, 48, 6439, 1034, false }, -- Chief Ukorz Sandscalp
	},
	names = {
		enUS = {[8130] = "Sul'lithuz Hatchling", [5648] = "Sandfury Shadowcaster", [5649] = "Sandfury Blood Drinker", [5650] = "Sandfury Witch Doctor", [7269] = "Scarab", [7246] = "Sandfury Shadowhunter", [7247] = "Sandfury Soul Eater", [7607] = "Weegli Blastfuse", [7608] = "Murta Grimgut", [7606] = "Oro Eyegouge", [7605] = "Raven", [7268] = "Sandfury Guardian", [8095] = "Sul'lithuz Sandcrawler", [7274] = "Sandfury Executioner", [8120] = "Sul'lithuz Abomination", [10081] = "Dustwraith", [10080] = "Sandarr Dunereaver", [7604] = "Sergeant Bly", [10082] = "Zerillis", [7795] = "Hydromancer Velratha", [7796] = "Nekrum Gutchewer", [7797] = "Ruuzlu", [7272] = "Theka the Martyr", [7271] = "Witch Doctor Zum'rah", [7275] = "Shadowpriest Sezz'ziz", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Chief Ukorz Sandscalp"},
		frFR = {[8130] = "Jeune Sul'lithuz", [5648] = "Exhalombre Sandfury", [5649] = "Buveur de sang Sandfury", [5650] = "Sorcier-docteur Sandfury", [7269] = "Scarabée", [7246] = "Chasseur des ombres Sandfury", [7247] = "Mangeur d'âmes Sandfury", [7607] = "Weegli Blastfuse", [7608] = "Murta Grimgut", [7606] = "Oro Eyegouge", [7605] = "Corbeau", [7268] = "Gardien Sandfury", [8095] = "Rampeur de Sul'lithuz", [7274] = "Bourreau Sandfury", [8120] = "Abomination Sul'lithuz", [10081] = "Ame en peine poudreuse", [10080] = "Sandarr Ravadune", [7604] = "Sergent Bly", [10082] = "Zerillis", [7795] = "Hydromancienne Velratha", [7796] = "Nekrum Mâchetripes", [7797] = "Ruuzlu", [7272] = "Theka le Martyr", [7271] = "Sorcier-docteur Zum'rah", [7275] = "Prêtre des ombres Sezz'ziz", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Chef Ukorz Scalpessable"},
		deDE = {[8130] = "Jungtier von Sul'lithuz", [5648] = "Schattenzauberer der Sandfury", [5649] = "Bluttrinker der Sandfury", [5650] = "Hexendoktor der Sandfury", [7269] = "Skarabäus", [7246] = "Schattenjäger der Sandfury", [7247] = "Seelenfresser der Sandfury", [7607] = "Weegli Lunte", [7608] = "Murta Bauchgrimm", [7606] = "Oro Hohlauge", [7605] = "Die Krähe", [7268] = "Wächter der Sandfury", [8095] = "Sandkriecher von Sul'lithuz", [7274] = "Henker der Sandfury", [8120] = "Monstrosität von Sul'lithuz", [10081] = "Karaburan", [10080] = "Sandarr der Wüstenräuber", [7604] = "Sergeant Bly", [10082] = "Zerillis", [7795] = "Wasserbeschwörerin Velratha", [7796] = "Nekrum der Ausweider", [7797] = "Ruuzlu", [7272] = "Theka der Märtyrer", [7271] = "Hexendoktor Zum'rah", [7275] = "Schattenpriester Sezz'ziz", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Häuptling Ukorz Sandscalp"},
		esES = {[8130] = "Prole de Sul'lithuz", [5648] = "Taumaturgo umbrío Furiarena", [5649] = "Bebesangre Furiarena", [5650] = "Médico brujo Furiarena", [7269] = "Escarabajo", [7246] = "Cazasombras Furiarena", [7247] = "Comealmas Furiarena", [7607] = "Weegli Plomofundido", [7608] = "Murta Tripuriosa", [7606] = "Oro Bocojo", [7605] = "Cuervo", [7268] = "Guardián Furiarena", [8095] = "Reptador de la arena Sul'lithuz", [7274] = "Verdugo Furiarena", [8120] = "Abominación Sul'lithuz", [10081] = "Ánima de polvo", [10080] = "Sandarr Asaltadunas", [7604] = "Sargento Bly", [10082] = "Zerillis", [7795] = "Hidromántica Velratha", [7796] = "Nekrum Cometripas", [7797] = "Ruuzlu", [7272] = "Theka el Mártir", [7271] = "Médico brujo Zum'rah", [7275] = "Sacerdote oscuro Sezz'ziz", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Jefe Ukorz Cabellarena"},
		esMX = {[8130] = "Prole de Sul'lithuz", [5648] = "Taumaturgo umbrío Furiarena", [5649] = "Bebesangre Furiarena", [5650] = "Médico brujo Furiarena", [7269] = "Escarabajo", [7246] = "Cazasombras Furiarena", [7247] = "Comealmas Furiarena", [7607] = "Weegli Plomofundido", [7608] = "Murta Tripuriosa", [7606] = "Oro Bocojo", [7605] = "Cuervo", [7268] = "Guardián Furiarena", [8095] = "Reptador de la arena Sul'lithuz", [7274] = "Verdugo Furiarena", [8120] = "Abominación Sul'lithuz", [10081] = "Ánima de polvo", [10080] = "Sandarr Asaltadunas", [7604] = "Sargento Bly", [10082] = "Zerillis", [7795] = "Hidromántica Velratha", [7796] = "Nekrum Cometripas", [7797] = "Ruuzlu", [7272] = "Theka el Mártir", [7271] = "Médico brujo Zum'rah", [7275] = "Sacerdote oscuro Sezz'ziz", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Jefe Ukorz Cabellarena"},
		ptBR = {[8130] = "Filhote Sul'lithuz", [5648] = "Lança-sombras Zangareia", [5649] = "Bebe-sangue Zangareia", [5650] = "Mandingueiro Zangareia", [7269] = "Escaravelho", [7246] = "Caçador Negro Zangareia", [7247] = "Devorador de Almas Zangareia", [7607] = "Weegli Pavio Quente", [7608] = "Murta Pançabruta", [7606] = "Oro Ranca-olho", [7605] = "Ravena", [7268] = "Guardião Zangareia", [8095] = "Rastejareia Sul'lithuz", [7274] = "Carrasco Zangareia", [8120] = "Abominação Sul'lithuz", [10081] = "Assombração de Poeira", [10080] = "Sandarr Aniquiladunas", [7604] = "Sargento Bly", [10082] = "Zerillis", [7795] = "Hidromante Velratha", [7796] = "Nekrum Cometripas", [7797] = "Ruuzlu", [7272] = "Theka, o Mártir", [7271] = "Mandingueiro Zum'rah", [7275] = "Sacerdote Sombrio Diz'ieh", [8127] = "Antu'sul", [7273] = "Gahz'rilla", [7267] = "Chefe Ukorz Escalpareia"},
		ruRU = {[8130] = "Сул'итуз-детеныш", [5648] = "Темный чародей из племени Песчаной Бури", [5649] = "Кровопийца из племени Песчаной Бури", [5650] = "Знахарь из клана Песчаной Бури", [7269] = "Скарабей", [7246] = "Темный охотник", [7247] = "Пожиратель душ из племени Песчаной Бури", [7607] = "Вигиль Фитиль", [7608] = "Мурта Мрачнобрюх", [7606] = "Оро Вырвиглаз", [7605] = "Ворона", [7268] = "Страж из племени Песчаной Бури", [8095] = "Сул'итуз-пескорыск", [7274] = "Палач из клана Песчаной Бури", [8120] = "Сул'итуз-поганище", [10081] = "Пыльный призрак", [10080] = "Сандарр Разоритель Барханов", [7604] = "Сержант Блай", [10082] = "Зериллис", [7795] = "Гидромант Велрата", [7796] = "Некрум Кишкожуй", [7797] = "Руузлу", [7272] = "Тека Мученик", [7271] = "Знахарь Зум'рах", [7275] = "Темный жрец Шезз'зиз", [8127] = "Анту'сул", [7273] = "Газ'рилла", [7267] = "Вождь Укорз Песчаная Плешь"},
		koKR = {[8130] = "새끼 술리투즈", [5648] = "성난모래부족 흑마술사", [5649] = "성난모래부족 혈투사", [5650] = "성난모래부족 의술사", [7269] = "왕쇠똥구리", [7246] = "성난모래부족 어둠사냥꾼", [7247] = "성난모래부족 영혼사냥꾼", [7607] = "위글리 블라스트퓨즈", [7608] = "무르타 그림구트", [7606] = "오로 아이가우지", [7605] = "레이븐", [7268] = "성난모래부족 수호물", [8095] = "모래집게 술리투즈", [7274] = "성난모래부족 사형집행인", [8120] = "흉포한 술리투즈", [10081] = "더스트레이스", [10080] = "산다르 듄리버", [7604] = "하사관 블라이", [10082] = "제릴리스", [7795] = "유체술사 벨라타", [7796] = "네크룸 거트츄어", [7797] = "루즐루", [7272] = "순교자 데카", [7271] = "의술사 줌라", [7275] = "어둠의사제 세즈지즈", [8127] = "안투술", [7273] = "가즈릴라", [7267] = "족장 우코르즈 샌드스칼프"},
		zhCN = {[8130] = "苏利萨斯幼雏", [5648] = "沙怒暗影法师", [5649] = "沙怒饮血者", [5650] = "沙怒巫医", [7269] = "圣甲虫", [7246] = "沙怒暗影猎手", [7247] = "沙怒噬魂者", [7607] = "维格利", [7608] = "穆尔塔", [7606] = "欧罗·血眼", [7605] = "拉文", [7268] = "沙怒守护者", [8095] = "苏利萨斯沙行者", [7274] = "沙怒刽子手", [8120] = "苏利萨斯憎恶", [10081] = "灰尘怨灵", [10080] = "杉达尔·沙掠者", [7604] = "布莱中士", [10082] = "泽雷利斯", [7795] = "水占师维蕾萨", [7796] = "耐克鲁姆", [7797] = "卢兹鲁", [7272] = "殉教者塞卡", [7271] = "巫医祖穆拉恩", [7275] = "暗影祭司塞瑟斯", [8127] = "安图苏尔", [7273] = "加兹瑞拉", [7267] = "乌克兹·沙顶"},
		zhTW = {[8130] = "蘇利薩斯幼雛", [5648] = "沙怒暗影施法者", [5649] = "沙怒飲血者", [5650] = "沙怒巫醫", [7269] = "聖甲蟲", [7246] = "沙怒暗影獵手", [7247] = "沙怒噬魂者", [7607] = "維格利", [7608] = "莫爾塔", [7606] = "歐魯·鑿眼", [7605] = "拉文", [7268] = "沙怒守護者", [8095] = "蘇利薩斯沙行者", [7274] = "沙怒劊子手", [8120] = "蘇利薩斯憎惡", [10081] = "灰塵怨靈", [10080] = "杉達爾·沙掠者", [7604] = "布萊中士", [10082] = "澤雷利斯", [7795] = "水占師維蕾薩", [7796] = "耐克魯姆", [7797] = "盧茲魯", [7272] = "『殉教者』塞卡", [7271] = "巫醫祖穆拉恩", [7275] = "暗影祭司塞瑟斯", [8127] = "安圖蘇爾", [7273] = "加茲瑞拉", [7267] = "烏克茲·沙頂"},
	},
	subs = {
		enUS = {[8127] = "Overseer of Sul"},
		frFR = {[8127] = "Surveillant de Sul"},
		deDE = {[8127] = "Vorarbeiter von Sul"},
		esES = {[8127] = "Sobrestante de Sul"},
		esMX = {[8127] = "Sobrestante de Sul"},
		ptBR = {[8127] = "Feitor de Sul"},
		ruRU = {[8127] = "Надсмотрщик Сула"},
		koKR = {[8127] = "술의 우두머리"},
		zhCN = {[8127] = "苏尔督军"},
		zhTW = {[8127] = "蘇爾監督者"},
	},
}
