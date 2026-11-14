-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "shadowfang", kind = "dungeon", instance = 33, area = 209,
	levels = { 22, 30 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 3914, 3886, 3887, 4279, 4274, 3927, 4278, 4275 }, final = 4275,
	name = "Shadowfang Keep",
	title = { frFR = "Donjon d'Ombrecroc", deDE = "Burg Shadowfang", esES = "Castillo de Colmillo Oscuro", esMX = "Castillo de Colmillo Oscuro", ptBR = "Bastilha da Presa Negra", ruRU = "Крепость Темного Клыка", koKR = "그림자송곳니 성채", zhCN = "影牙城堡" },
	tint = { 0.18, 0.18, 0.32 }, glow = { 0.62, 0.66, 1.00 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioShadowfang", pack = "PackShadowfang", set = "SetShadowfang",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 3861, 1, 1, 1, 18, 19, 801, 390, false }, -- Bleak Worg
		{ 3851, 1, 7, 0, 18, 19, 729, 437, false }, -- Shadowfang Whitescalp
		{ 3862, 1, 1, 1, 18, 18, 11421, 390, false }, -- Slavering Worg
		{ 3864, 1, 1, 0, 19, 20, 1951, 729, false }, -- Fel Steed
		{ 3875, 1, 6, 0, 20, 21, 3229, 1328, false }, -- Haunted Servitor
		{ 3865, 1, 1, 0, 20, 21, 1952, 729, false }, -- Shadow Charger
		{ 3853, 1, 7, 0, 20, 20, 729, 437, false }, -- Shadowfang Moonwalker
		{ 3854, 1, 7, 0, 20, 20, 203, 437, false }, -- Shadowfang Wolfguard
		{ 5058, 1, 1, 1, 20, 21, 246, 390, false }, -- Wolfguard Worg
		{ 3855, 1, 7, 0, 21, 21, 657, 437, false }, -- Shadowfang Darksoul
		{ 3857, 1, 7, 0, 21, 21, 202, 437, false }, -- Shadowfang Glutton
		{ 3877, 1, 6, 0, 21, 22, 3226, 1328, false }, -- Wailing Guardsman
		{ 10000, 1, 7, 0, 26, 26, 2353, 1328, false }, -- Arugal
		{ 4444, 2, 7, 0, 21, 21, 2689, 6036, true }, -- Deathstalker Vincent
		{ 3866, 2, 1, 24, 22, 23, 8808, 3369, false }, -- Vile Bat
		{ 3868, 2, 1, 24, 23, 24, 1955, 3369, false }, -- Blood Seeker
		{ 3873, 2, 6, 0, 23, 24, 3225, 1328, false }, -- Tormented Officer
		{ 3863, 2, 6, 0, 24, 24, 2446, 6699, false }, -- Lupine Horror
		{ 3859, 2, 7, 0, 24, 24, 736, 437, false }, -- Shadowfang Ragetooth
		{ 3849, 3, 7, 0, 18, 18, 2006, 6039, true }, -- Deathstalker Adamant
		{ 3850, 3, 7, 0, 18, 18, 2005, 5971, true }, -- Sorcerer Ashcrombe
		{ 3872, 3, 6, 0, 25, 25, 3224, 1328, false }, -- Deathsworn Captain
		{ 14682, 3, 6, 0, 25, 25, 1061, 1446, false }, -- Sever
		{ 3914, 4, 7, 0, 20, 20, 524, 437, false }, -- Rethilgore
		{ 3886, 4, 7, 0, 22, 22, 524, 437, false }, -- Razorclaw the Butcher
		{ 3887, 4, 6, 0, 24, 24, 3222, 1328, false }, -- Baron Silverlaine
		{ 4279, 4, 7, 0, 24, 24, 522, 437, false }, -- Odo the Blindwatcher
		{ 4274, 4, 1, 0, 25, 25, 2352, 390, false }, -- Fenrus the Devourer
		{ 3927, 4, 7, 0, 25, 25, 11179, 437, false }, -- Wolf Master Nandos
		{ 4278, 5, 6, 0, 24, 24, 3223, 1328, false }, -- Commander Springvale
		{ 4275, 6, 7, 0, 26, 26, 2353, 1328, false }, -- Archmage Arugal
	},
	names = {
		enUS = {[3861] = "Bleak Worg", [3851] = "Shadowfang Whitescalp", [3862] = "Slavering Worg", [3864] = "Fel Steed", [3875] = "Haunted Servitor", [3865] = "Shadow Charger", [3853] = "Shadowfang Moonwalker", [3854] = "Shadowfang Wolfguard", [5058] = "Wolfguard Worg", [3855] = "Shadowfang Darksoul", [3857] = "Shadowfang Glutton", [3877] = "Wailing Guardsman", [10000] = "Arugal", [4444] = "Deathstalker Vincent", [3866] = "Vile Bat", [3868] = "Blood Seeker", [3873] = "Tormented Officer", [3863] = "Lupine Horror", [3859] = "Shadowfang Ragetooth", [3849] = "Deathstalker Adamant", [3850] = "Sorcerer Ashcrombe", [3872] = "Deathsworn Captain", [14682] = "Sever", [3914] = "Rethilgore", [3886] = "Razorclaw the Butcher", [3887] = "Baron Silverlaine", [4279] = "Odo the Blindwatcher", [4274] = "Fenrus the Devourer", [3927] = "Wolf Master Nandos", [4278] = "Commander Springvale", [4275] = "Archmage Arugal"},
		frFR = {[3861] = "Worg pâle", [3851] = "Poil-blanc Ombrecroc", [3862] = "Worg écumant", [3864] = "Palefroi corrompu", [3875] = "Serviteur hanté", [3865] = "Destrier des ténèbres", [3853] = "Marche-lune d'Ombrecroc", [3854] = "Garde-loup d'Ombrecroc", [5058] = "Garde-loup worg", [3855] = "Ténébreux d'Ombrecroc", [3857] = "Glouton d'Ombrecroc", [3877] = "Gardien gémissant", [10000] = "Arugal", [4444] = "Traqueur noir Vincent", [3866] = "Chauve-souris vile", [3868] = "Sanguinaire", [3873] = "Officier tourmenté", [3863] = "Horreur Lupine", [3859] = "Enragé d'Ombrecroc", [3849] = "Traqueur noir Adamant", [3850] = "Ensorceleur Ashcrombe", [3872] = "Capitaine Ligemort", [14682] = "Sectionneur", [3914] = "Rethilgore", [3886] = "Tranchegriffe le Boucher", [3887] = "Baron d'Argelaine", [4279] = "Odo l'Aveugle", [4274] = "Fenrus le Dévoreur", [3927] = "Maître-loup Nandos", [4278] = "Commandant Springvale", [4275] = "Archimage Arugal"},
		deDE = {[3861] = "Kahler Worg", [3851] = "Shadowfang-Weißskalp", [3862] = "Sabbernder Worg", [3864] = "Teufelsross", [3875] = "Verhexter Bediensteter", [3865] = "Schattenstürmer", [3853] = "Shadowfang-Mondwandler", [3854] = "Shadowfang-Wolfswache", [5058] = "Wolfswachenworg", [3855] = "Shadowfang-Dunkelseele", [3857] = "Shadowfang-Nimmersatt", [3877] = "Klagender Gardist", [10000] = "Arugal", [4444] = "Todespirscher Vincent", [3866] = "Üble Fledermaus", [3868] = "Blutsucher", [3873] = "Gepeinigter Offizier", [3863] = "Werwolfschrecken", [3859] = "Shadowfang-Wutzahn", [3849] = "Todespirscher Adamant", [3850] = "Zauberhexer Ashcrombe", [3872] = "Todeshöriger Captain", [14682] = "Häcksler", [3914] = "Rethilgore", [3886] = "Klingenklaue der Metzger", [3887] = "Baron Silverlaine", [4279] = "Odo der Blindseher", [4274] = "Fenrus der Verschlinger", [3927] = "Wolfmeister Nandos", [4278] = "Kommandant Springvale", [4275] = "Erzmagier Arugal"},
		esES = {[3861] = "Lupo lóbrego", [3851] = "Canoso Colmillo Oscuro", [3862] = "Lupo esclavizante", [3864] = "Corcel nefasto", [3875] = "Servidor encantado", [3865] = "Cargador de las Sombras", [3853] = "Caminalunas Colmillo Oscuro", [3854] = "Guardialobo Colmillo Oscuro", [5058] = "Lupo Guardialobo", [3855] = "Almanegra Colmillo Oscuro", [3857] = "Glotón Colmillo Oscuro", [3877] = "Custodio de los Lamentos", [10000] = "Arugal", [4444] = "Mortacechador Vincent", [3866] = "Murciovil", [3868] = "Rastreasangre", [3873] = "Oficial atormentado", [3863] = "Horror Lupino", [3859] = "Furiadiente Colmillo Oscuro", [3849] = "Mortacechador Adamant", [3850] = "Hechicero Ashcrombe", [3872] = "Capitán Juramorte", [14682] = "Cercenador", [3914] = "Rethilgore", [3886] = "Zarpador el Carnicero", [3887] = "Barón Filargenta", [4279] = "Odo el Cegato", [4274] = "Fenrus el Devorador", [3927] = "Maestro de lobos Nandos", [4278] = "Comandante Vallefont", [4275] = "Archimago Arugal"},
		esMX = {[3861] = "Lupo lóbrego", [3851] = "Canoso Colmillo Oscuro", [3862] = "Lupo esclavizante", [3864] = "Corcel nefasto", [3875] = "Servidor encantado", [3865] = "Cargador de las Sombras", [3853] = "Caminalunas Colmillo Oscuro", [3854] = "Guardialobo Colmillo Oscuro", [5058] = "Lupo Guardialobo", [3855] = "Almanegra Colmillo Oscuro", [3857] = "Glotón Colmillo Oscuro", [3877] = "Custodio de los Lamentos", [10000] = "Arugal", [4444] = "Mortacechador Vincent", [3866] = "Murciovil", [3868] = "Rastreasangre", [3873] = "Oficial atormentado", [3863] = "Horror Lupino", [3859] = "Furiadiente Colmillo Oscuro", [3849] = "Mortacechador Adamant", [3850] = "Hechicero Ashcrombe", [3872] = "Capitán Juramorte", [14682] = "Cercenador", [3914] = "Rethilgore", [3886] = "Zarpador el Carnicero", [3887] = "Barón Filargenta", [4279] = "Odo el Cegato", [4274] = "Fenrus el Devorador", [3927] = "Maestro de lobos Nandos", [4278] = "Comandante Vallefont", [4275] = "Archimago Arugal"},
		ptBR = {[3861] = "Worg Sinistro", [3851] = "Grenhalva Presa Negra", [3862] = "Worg Salivante", [3864] = "Corcel Vil", [3875] = "Servo Assombrado", [3865] = "Corcel das Sombras", [3853] = "Lunâmbulo Presa Negra", [3854] = "Lupeguarda Presa Negra", [5058] = "Worg Lupeguarda", [3855] = "Almanegra Presa Negra", [3857] = "Glutão Presa Negra", [3877] = "Guarda Lamuriento", [10000] = "Arugal", [4444] = "Sicário Vicente", [3866] = "Morcego Torpe", [3868] = "Busca-sangue", [3873] = "Oficial Atormentado", [3863] = "Horror Lupino", [3859] = "Iradentes Presa Negra", [3849] = "Sicário Admeto", [3850] = "Feiticeiro Ashcrombe", [3872] = "Capitão Devoto da Morte", [14682] = "'Ranka", [3914] = "Rethilgore", [3886] = "Garraguda, o Açougueiro", [3887] = "Barão Silverlaine", [4279] = "Odo, o Vigia Cego", [4274] = "Fenrus, o Devorador", [3927] = "Nandos, o Mestre de Lobos", [4278] = "Comandante Floraval", [4275] = "Arquimago Arugal"},
		ruRU = {[3861] = "Бесцветный ворг", [3851] = "Белоголов Серого Клыка", [3862] = "Слюнявый ворг", [3864] = "Конь скверны", [3875] = "Призрачный служитель", [3865] = "Скакун тени", [3853] = "Лунолюб Серого Клыка", [3854] = "Волкостраж Темного Клыка", [5058] = "Ворг-волкостраж", [3855] = "Темный дух из крепости Темного Клыка", [3857] = "Прожорень Серого Клыка", [3877] = "Стенающий охранник", [10000] = "Аругал", [4444] = "Страж смерти Эрланд Винсент", [3866] = "Злобный нетопырь", [3868] = "Кровожад", [3873] = "Замученный офицер", [3863] = "Волчий ужас", [3859] = "Ярозуб Серого Клыка", [3849] = "Страж смерти Адамант", [3850] = "Колдун Ашкромб", [3872] = "Капитан служителей Смерти", [14682] = "Калечер", [3914] = "Ретилгор", [3886] = "Остроклык Мясник", [3887] = "Барон Сребролен", [4279] = "Одо Слепой Страж", [4274] = "Фенрус Пожиратель", [3927] = "Командир воргенов Нандос", [4278] = "Командир Ручьедол", [4275] = "Верховный маг Аругал"},
		koKR = {[3861] = "사나운 검은늑대", [3851] = "그림자송곳니일족 백발전사", [3862] = "굶주린 검은늑대", [3864] = "지옥마", [3875] = "이승을 떠도는 하인 유령", [3865] = "암흑마", [3853] = "그림자송곳니일족 달전사", [3854] = "그림자송곳니일족 늑대투사", [5058] = "늑대투사의 검은늑대", [3855] = "그림자송곳니일족 검은영혼", [3857] = "그림자송곳니일족 광신도", [3877] = "울부짖는 경비병 유령", [10000] = "아루갈", [4444] = "죽음의추적자 빈센트", [3866] = "그림자박쥐", [3868] = "흡혈박쥐", [3873] = "고통받는 장교 유령", [3863] = "늑대 망령", [3859] = "그림자송곳니일족 송곳니투사", [3849] = "죽음의추적자 아다만트", [3850] = "마법사 애쉬크롬비", [3872] = "죽음의 경비대장", [14682] = "살육의 괴물", [3914] = "레실고어", [3886] = "도살자 칼날발톱", [3887] = "남작 실버레인", [4279] = "눈먼감시자 오도", [4274] = "파멸의 펜루스", [3927] = "늑대왕 난도스", [4278] = "사령관 스프링베일", [4275] = "대마법사 아루갈"},
		zhCN = {[3861] = "灰色座狼", [3851] = "影牙白头狼人", [3862] = "被奴役的座狼", [3864] = "地狱战马", [3875] = "鬼怪仆从", [3865] = "暗影军马", [3853] = "影牙夜行者", [3854] = "影牙狼人卫兵", [5058] = "警戒座狼", [3855] = "影牙魔魂狼人", [3857] = "影牙暴食者", [3877] = "哀嚎的卫兵", [10000] = "阿鲁高", [4444] = "亡灵哨兵文森特", [3866] = "邪蝠", [3868] = "觅血者", [3873] = "痛苦的文官", [3863] = "暗牙恐狼", [3859] = "影牙暴怒者", [3849] = "亡灵哨兵阿达曼特", [3850] = "巫师阿克鲁比", [3872] = "死亡之誓", [14682] = "塞沃尔", [3914] = "雷希戈尔", [3886] = "屠夫拉佐克劳", [3887] = "席瓦莱恩男爵", [4279] = "盲眼守卫奥杜", [4274] = "吞噬者芬鲁斯", [3927] = "狼王南杜斯", [4278] = "指挥官斯普林瓦尔", [4275] = "大法师阿鲁高"},
		zhTW = {[3861] = "荒狼", [3851] = "影牙白頭狼人", [3862] = "被奴役的座狼", [3864] = "魔化戰馬", [3875] = "鬼怪僕從", [3865] = "暗影戰馬", [3853] = "影牙夜行者", [3854] = "影牙狼人衛兵", [5058] = "警戒座狼", [3855] = "影牙黑暗之魂狼人", [3857] = "影牙暴食者", [3877] = "哀嚎的衛兵", [10000] = "阿魯高", [4444] = "亡靈哨兵文森特", [3866] = "邪蝠", [3868] = "覓血者", [3873] = "痛苦的文官", [3863] = "暗牙恐狼", [3859] = "影牙暴怒者", [3849] = "亡靈哨兵阿達曼特", [3850] = "巫士阿克魯比", [3872] = "死亡誓言者隊長", [14682] = "塞沃爾", [3914] = "雷希戈爾", [3886] = "屠夫拉佐克勞", [3887] = "席瓦萊恩男爵", [4279] = "『盲眼守衛』奧杜", [4274] = "『吞噬者』芬魯斯", [3927] = "狼王南杜斯", [4278] = "指揮官斯普林瓦爾", [4275] = "大法師阿魯高"},
	},
	subs = {
		enUS = {[3914] = "The Cell Keeper"},
		frFR = {[3914] = "Le gardien de la cellule"},
		deDE = {[3914] = "Der Zellenbewahrer"},
		esES = {[3914] = "El guardián de la celda"},
		esMX = {[3914] = "El guardián de la celda"},
		ptBR = {[3914] = "O Carcereiro"},
		ruRU = {[3914] = "Страж подвала"},
		koKR = {[3914] = "문지기"},
		zhCN = {[3914] = "牢房看守"},
		zhTW = {[3914] = "牢房看守"},
	},
}
