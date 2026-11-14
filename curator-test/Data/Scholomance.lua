-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "scholomance", kind = "dungeon", instance = 289, area = 2057,
	levels = { 58, 60 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 11261, 10505, 10502, 10504, 10901, 10507, 10503, 11622, 10506, 10508, 1853 }, final = 1853,
	name = "Scholomance",
	title = { frFR = "Scholomance", deDE = "Scholomance", esES = "Scholomance", esMX = "Scholomance", ptBR = "Scolomântia", ruRU = "Некроситет", koKR = "스칼로맨스", zhCN = "通灵学院" },
	tint = { 0.18, 0.28, 0.21 }, glow = { 0.71, 0.90, 0.75 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioScholomance", pack = "PackScholomance", set = "SetScholomance",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 10678, 1, 2, 0, 57, 59, 10007, 428, false }, -- Plagued Hatchling
		{ 10485, 1, 6, 0, 57, 58, 9786, 1016, false }, -- Risen Aberration
		{ 10489, 1, 6, 0, 57, 59, 7848, 1016, false }, -- Risen Guard
		{ 10471, 1, 7, 0, 57, 58, 11157, 2937, false }, -- Scholomance Acolyte
		{ 10476, 1, 7, 0, 57, 58, 11161, 2937, false }, -- Scholomance Necrolyte
		{ 10470, 1, 7, 0, 57, 58, 11164, 2937, false }, -- Scholomance Neophyte
		{ 10495, 1, 6, 0, 58, 59, 519, 409, false }, -- Diseased Ghoul
		{ 10481, 1, 6, 0, 58, 59, 10975, 1473, false }, -- Reanimated Corpse
		{ 10491, 1, 6, 0, 58, 59, 11397, 2517, false }, -- Risen Bonewarder
		{ 10469, 1, 7, 0, 58, 59, 11161, 2937, false }, -- Scholomance Adept
		{ 11582, 1, 7, 0, 58, 59, 11163, 2937, false }, -- Scholomance Dark Summoner
		{ 10477, 1, 7, 0, 58, 59, 11163, 2937, false }, -- Scholomance Necromancer
		{ 10472, 1, 7, 0, 58, 59, 11157, 2937, false }, -- Scholomance Occultist
		{ 10480, 1, 6, 0, 58, 59, 10978, 1473, false }, -- Unstable Corpse
		{ 11551, 2, 6, 0, 58, 60, 11178, 3346, false }, -- Necrofiend
		{ 10488, 2, 6, 0, 58, 61, 12074, 472, false }, -- Risen Construct
		{ 10487, 2, 6, 0, 58, 60, 11489, 1016, false }, -- Risen Protector
		{ 10475, 2, 7, 0, 58, 59, 11161, 7014, true }, -- Scholomance Student
		{ 10499, 2, 6, 0, 58, 60, 3942, 3417, false }, -- Spectral Researcher
		{ 10500, 2, 6, 0, 58, 61, 3942, 3417, false }, -- Spectral Teacher
		{ 10498, 2, 6, 0, 58, 60, 3942, 3417, false }, -- Spectral Tutor
		{ 10486, 2, 6, 0, 59, 61, 7847, 1016, false }, -- Risen Warrior
		{ 11257, 2, 7, 0, 59, 60, 11161, 2937, false }, -- Scholomance Handler
		{ 10478, 2, 6, 0, 59, 60, 11401, 1016, false }, -- Splintered Skeleton
		{ 10433, 3, 6, 0, 58, 58, 10248, 6036, true }, -- Marduk Blackpool
		{ 10432, 3, 6, 0, 60, 60, 2606, 2517, false }, -- Vectus
		{ 14861, 3, 3, 0, 61, 61, 10925, 1122, false }, -- Blood Steward of Kirtonos
		{ 14516, 3, 6, 0, 62, 62, 14591, 10677, false }, -- Death Knight Darkreaver
		{ 11261, 4, 7, 0, 60, 60, 10901, 1328, false }, -- Doctor Theolen Krastinov
		{ 10505, 4, 7, 0, 60, 60, 11069, 2937, false }, -- Instructor Malicia
		{ 10502, 4, 6, 0, 60, 60, 11835, 2937, false }, -- Lady Illucia Barov
		{ 10504, 4, 6, 0, 60, 60, 11072, 1328, false }, -- Lord Alexei Barov
		{ 10901, 4, 6, 0, 60, 60, 11492, 1473, false }, -- Lorekeeper Polkelt
		{ 10507, 4, 6, 0, 60, 60, 10433, 7139, false }, -- The Ravenian
		{ 10503, 4, 6, 0, 61, 61, 11073, 2937, false }, -- Jandice Barov
		{ 11622, 4, 6, 0, 61, 61, 12073, 472, false }, -- Rattlegore
		{ 10506, 5, 6, 0, 60, 60, 7534, 0, false }, -- Kirtonos the Herald
		{ 10508, 5, 6, 0, 62, 62, 7919, 5800, false }, -- Ras Frostwhisper
		{ 1853, 6, 7, 0, 61, 61, 11070, 1328, false }, -- Darkmaster Gandling
	},
	names = {
		enUS = {[10678] = "Plagued Hatchling", [10485] = "Risen Aberration", [10489] = "Risen Guard", [10471] = "Scholomance Acolyte", [10476] = "Scholomance Necrolyte", [10470] = "Scholomance Neophyte", [10495] = "Diseased Ghoul", [10481] = "Reanimated Corpse", [10491] = "Risen Bonewarder", [10469] = "Scholomance Adept", [11582] = "Scholomance Dark Summoner", [10477] = "Scholomance Necromancer", [10472] = "Scholomance Occultist", [10480] = "Unstable Corpse", [11551] = "Necrofiend", [10488] = "Risen Construct", [10487] = "Risen Protector", [10475] = "Scholomance Student", [10499] = "Spectral Researcher", [10500] = "Spectral Teacher", [10498] = "Spectral Tutor", [10486] = "Risen Warrior", [11257] = "Scholomance Handler", [10478] = "Splintered Skeleton", [10433] = "Marduk Blackpool", [10432] = "Vectus", [14861] = "Blood Steward of Kirtonos", [14516] = "Death Knight Darkreaver", [11261] = "Doctor Theolen Krastinov", [10505] = "Instructor Malicia", [10502] = "Lady Illucia Barov", [10504] = "Lord Alexei Barov", [10901] = "Lorekeeper Polkelt", [10507] = "The Ravenian", [10503] = "Jandice Barov", [11622] = "Rattlegore", [10506] = "Kirtonos the Herald", [10508] = "Ras Frostwhisper", [1853] = "Darkmaster Gandling"},
		frFR = {[10678] = "Jeune pestiféré", [10485] = "Aberration ressuscitée", [10489] = "Garde ressuscité", [10471] = "Acolyte Scholomance", [10476] = "Nécrolyte Scholomance", [10470] = "Néophyte de la Scholomance", [10495] = "Goule infectée", [10481] = "Cadavre réanimé", [10491] = "Gardien d'os ressuscité", [10469] = "Adepte Scholomance", [11582] = "Invocateur des ténèbres de Scholomance", [10477] = "Nécromancien Scholomance", [10472] = "Occultiste Scholomance", [10480] = "Corps instable", [11551] = "Nécrofiel", [10488] = "Assemblage ressuscité", [10487] = "Protecteur ressuscité", [10475] = "Etudiant de Scholomance", [10499] = "Chercheur spectral", [10500] = "Professeur spectral", [10498] = "Educateur spectral", [10486] = "Guerrier ressuscité", [11257] = "Eleveur de Scholomance", [10478] = "Squelette brisé", [10433] = "Marduk Noirétang", [10432] = "Vectus", [14861] = "Régisseuse sanglante de Kirtonos", [14516] = "Chevalier de la mort Ravassombre", [11261] = "Docteur Theolen Krastinov", [10505] = "Instructeur Malicia", [10502] = "Dame Illucia Barov", [10504] = "Seigneur Alexei Barov", [10901] = "Gardien du savoir Polkelt", [10507] = "Le Voracien", [10503] = "Jandice Barov", [11622] = "Cliquettripes", [10506] = "Kirtonos le Héraut", [10508] = "Ras Murmegivre", [1853] = "Sombre Maître Gandling"},
		deDE = {[10678] = "Verseuchtes Jungtier", [10485] = "Auferstandene Entartung", [10489] = "Auferstandene Wache", [10471] = "Akolyt aus Scholomance", [10476] = "Nekrolyt aus Scholomance", [10470] = "Neophyt aus Scholomance", [10495] = "Kranker Ghul", [10481] = "Reanimierter Kadaver", [10491] = "Auferstandener Knochenwärter", [10469] = "Adept aus Scholomance", [11582] = "Dunkler Beschwörer aus Scholomance", [10477] = "Totenbeschwörer aus Scholomance", [10472] = "Okkultist aus Scholomance", [10480] = "Faulender Leichnam", [11551] = "Nekrobestie", [10488] = "Auferstandenes Konstrukt", [10487] = "Auferstandener Beschützer", [10475] = "Student aus Scholomance", [10499] = "Spektraler Forscher", [10500] = "Spektraler Lehrmeister", [10498] = "Spektraler Tutor", [10486] = "Auferstandener Krieger", [11257] = "Tierführer aus Scholomance", [10478] = "Abgesplittertes Skelett", [10433] = "Marduk Blackpool", [10432] = "Vectus", [14861] = "Blutdiener von Kirtonos", [14516] = "Todesritter Schattensichel", [11261] = "Doktor Theolen Krastinov", [10505] = "Instrukteurin Malicia", [10502] = "Lady Illucia Barov", [10504] = "Lord Alexei Barov", [10901] = "Hüter des Wissens Polkelt", [10507] = "Der Ravenier", [10503] = "Jandice Barov", [11622] = "Blutrippe", [10506] = "Kirtonos der Herold", [10508] = "Ras Frostraunen", [1853] = "Dunkelmeister Gandling"},
		esES = {[10678] = "Trampedor infestado", [10485] = "Aberración resucitada", [10489] = "Guarda resucitado", [10471] = "Acólito de Scholomance", [10476] = "Necrólito de Scholomance", [10470] = "Neófito de Scholomance", [10495] = "Necrófago malsano", [10481] = "Cadáver reanimado", [10491] = "Guardahuesos resucitado", [10469] = "Adepto de Scholomance", [11582] = "Invocador Oscuro de Scholomance", [10477] = "Necromántico de Scholomance", [10472] = "Ocultista de Scholomance", [10480] = "Cuerpo inestable", [11551] = "Necromefisto", [10488] = "Constructo resucitado", [10487] = "Protector resucitado", [10475] = "Estudiante de Scholomance", [10499] = "Investigador espectral", [10500] = "Maestro espectral", [10498] = "Tutor espectral", [10486] = "Guerrero resucitado", [11257] = "Controlador de Scholomance", [10478] = "Esqueleto astillado", [10433] = "Marduz Pozonegro", [10432] = "Vectus", [14861] = "Administradora de sangre de Kirtonos", [14516] = "Caballero de la Muerte Atracoscuro", [11261] = "Doctor Theolen Krastinov", [10505] = "Instructor Malicia", [10502] = "Lady Illucia Barov", [10504] = "Lord Alexei Barov", [10901] = "Tradicionalista Polkelt", [10507] = "El Devorador", [10503] = "Jandice Barov", [11622] = "Traquesangre", [10506] = "Kirtonos el Heraldo", [10508] = "Ras Murmuhielo", [1853] = "Maestro oscuro Gandling"},
		esMX = {[10678] = "Cría de dragón apestada", [10485] = "Aberración resucitada", [10489] = "Guarda resucitado", [10471] = "Acólito de Scholomance", [10476] = "Necrólito de Scholomance", [10470] = "Neófito de Scholomance", [10495] = "Necrófago malsano", [10481] = "Cadáver reanimado", [10491] = "Guardahuesos resucitado", [10469] = "Adepto de Scholomance", [11582] = "Invocador Oscuro de Scholomance", [10477] = "Necromántico de Scholomance", [10472] = "Ocultista de Scholomance", [10480] = "Cuerpo inestable", [11551] = "Necromefisto", [10488] = "Constructo resucitado", [10487] = "Protector resucitado", [10475] = "Estudiante de Scholomance", [10499] = "Investigador espectral", [10500] = "Maestro espectral", [10498] = "Tutor espectral", [10486] = "Guerrero resucitado", [11257] = "Controlador de Scholomance", [10478] = "Esqueleto astillado", [10433] = "Marduz Pozonegro", [10432] = "Vectus", [14861] = "Administradora de sangre de Kirtonos", [14516] = "Caballero de la Muerte Atracoscuro", [11261] = "Doctor Theolen Krastinov", [10505] = "Instructor Malicia", [10502] = "Lady Illucia Barov", [10504] = "Lord Alexei Barov", [10901] = "Tradicionalista Polkelt", [10507] = "El Devorador", [10503] = "Jandice Barov", [11622] = "Traquesangre", [10506] = "Kirtonos el Heraldo", [10508] = "Ras Murmuhielo", [1853] = "Maestro oscuro Gandling"},
		ptBR = {[10678] = "Filhote Pestilento", [10485] = "Aberração Reanimada", [10489] = "Guarda Reanimado", [10471] = "Acólito de Scolomântia", [10476] = "Necrólito de Scolomântia", [10470] = "Neófito de Scolomântia", [10495] = "Carniçal Doente", [10481] = "Cadáver Reanimado", [10491] = "Carcereiro Reanimado", [10469] = "Adepto de Scolomântia", [11582] = "Evocador das Trevas de Scolomântia", [10477] = "Necromante de Scolomântia", [10472] = "Ocultista de Scolomântia", [10480] = "Cadáver Instável", [11551] = "Necroteias", [10488] = "Constructo Animado", [10487] = "Protetor Reanimado", [10475] = "Aluno de Scolomântia", [10499] = "Pesquisador Espectral", [10500] = "Professor Espectral", [10498] = "Docente Espectral", [10486] = "Guerreiro Reanimado", [11257] = "Tratador de Scolomântia", [10478] = "Esqueleto Rachado", [10433] = "Marduque Lagonero", [10432] = "Vectus", [14861] = "Governanta Sangrenta de Kirtonos", [14516] = "Cavaleiro da Morte Noctilatrus", [11261] = "Doutor Theolen Krastinov", [10505] = "Instrutora Malícia", [10502] = "Lady Ilúcia Barov", [10504] = "Lorde Alexei Barov", [10901] = "Erudito Pulquério", [10507] = "O Corvino", [10503] = "Janice Barov", [11622] = "Ossorrange", [10506] = "Kirtonos, o Arauto", [10508] = "Ras Friomúrmuro", [1853] = "Umbromestre Gandling"},
		ruRU = {[10678] = "Зачумленный детеныш дракона", [10485] = "Восставшая аберрация", [10489] = "Восставший стражник", [10471] = "Послушник из Некроситета", [10476] = "Некролит Некроситета", [10470] = "Неофит Некроситета", [10495] = "Болезненный вурдалак", [10481] = "Оживленный труп", [10491] = "Восставший костостраж", [10469] = "Адепт Некроситета", [11582] = "Призыватель Тьмы Некроситета", [10477] = "Некромант Некроситета", [10472] = "Оккультист Некроситета", [10480] = "Нестабильный труп", [11551] = "Злобный некрорахнид", [10488] = "Восставшее создание", [10487] = "Восставший заступник", [10475] = "Ученик Некроситета", [10499] = "Призрачный ученый", [10500] = "Призрачный учитель", [10498] = "Призрачный воспитатель", [10486] = "Восставший воин", [11257] = "Укротитель Некроситета", [10478] = "Раздробленный скелет", [10433] = "Мардук Блэкпул", [10432] = "Вектус", [14861] = "Кровавая прислужница Киртоноса", [14516] = "Рыцарь смерти Темный Терзатель", [11261] = "Доктор Теолен Крастинов", [10505] = "Инструктор Коварница", [10502] = "Леди Иллюсия Баров", [10504] = "Лорд Алексей Баров", [10901] = "Сказитель Полкелт", [10507] = "Равениан", [10503] = "Джандис Баров", [11622] = "Громоклин", [10506] = "Киртонос Глашатай", [10508] = "Рас Снегошепот", [1853] = "Темный магистр Гандлинг"},
		koKR = {[10678] = "역병 걸린 작은 새끼용", [10485] = "되살아난 돌연변이", [10489] = "되살아난 경비병", [10471] = "스칼로맨스 수행사제", [10476] = "스칼로맨스 견습강령술사", [10470] = "스칼로맨스 수련사", [10495] = "역병 걸린 구울", [10481] = "되살아난 시체", [10491] = "되살아난 해골문지기", [10469] = "스칼로맨스 숙련사제", [11582] = "스칼로맨스 암흑소환사", [10477] = "스칼로맨스 강령술사", [10472] = "스칼로맨스 사술사", [10480] = "비틀거리는 시체", [11551] = "소생한 지하마귀", [10488] = "되살아난 피조물", [10487] = "되살아난 민병대원", [10475] = "스칼로맨스 학생", [10499] = "연구원 유령", [10500] = "교사 유령", [10498] = "교수 유령", [10486] = "되살아난 전사", [11257] = "스칼로맨스 조련사", [10478] = "조각난 해골", [10433] = "마르두크 블랙풀", [10432] = "벡투스", [14861] = "키르토노스의 혈지기", [14516] = "죽음의 기사 다크리버", [11261] = "학자 테올렌 크라스티노브", [10505] = "조교 말리시아", [10502] = "여군주 일루시아 바로브", [10504] = "군주 알렉세이 바로브", [10901] = "현자 폴켈트", [10507] = "라베니안", [10503] = "잔다이스 바로브", [11622] = "들창어금니", [10506] = "사자 키르토노스", [10508] = "라스 프로스트위스퍼", [1853] = "암흑스승 간들링"},
		zhCN = {[10678] = "瘟疫龙崽", [10485] = "复活的畸形骷髅", [10489] = "复活的卫兵", [10471] = "通灵学院侍僧", [10476] = "通灵学院通灵师", [10470] = "通灵学院新学徒", [10495] = "生病的食尸鬼", [10481] = "复生的尸体", [10491] = "复活的骷髅守卫", [10469] = "通灵学院专家", [11582] = "通灵学院黑暗召唤师", [10477] = "通灵学院亡灵法师", [10472] = "通灵学院神秘学者", [10480] = "虚弱的尸体", [11551] = "通灵魔", [10488] = "复活的构造体", [10487] = "复活的保卫者", [10475] = "通灵学院学员", [10499] = "鬼灵研究员", [10500] = "鬼灵教师", [10498] = "鬼灵导师", [10486] = "复活的战士", [11257] = "通灵学院管理者", [10478] = "碎裂的骷髅", [10433] = "马杜克·布莱克波尔", [10432] = "维克图斯", [14861] = "基尔图诺斯的卫士", [14516] = "死亡骑士达克雷尔", [11261] = "瑟尔林·卡斯迪诺夫教授", [10505] = "讲师玛丽希亚", [10502] = "伊露希亚·巴罗夫", [10504] = "阿雷克斯·巴罗夫", [10901] = "博学者普克尔特", [10507] = "拉文尼亚", [10503] = "詹迪斯·巴罗夫", [11622] = "血骨傀儡", [10506] = "传令官基尔图诺斯", [10508] = "莱斯·霜语", [1853] = "黑暗院长加丁"},
		zhTW = {[10678] = "瘟疫幼龍", [10485] = "復活的畸形骷髏", [10489] = "復活的衛兵", [10471] = "通靈學院侍僧", [10476] = "通靈學院通靈師", [10470] = "通靈學院新學徒", [10495] = "生病的食屍鬼", [10481] = "複生的屍體", [10491] = "復活的骸骨守衛", [10469] = "通靈學院專家", [11582] = "通靈學院黑暗召喚師", [10477] = "通靈學院死靈法師", [10472] = "通靈學院神秘學者", [10480] = "虛弱的屍體", [11551] = "通靈魔", [10488] = "復活的構造體", [10487] = "復活的保衛者", [10475] = "通靈學院學員", [10499] = "鬼靈研究員", [10500] = "鬼靈教師", [10498] = "鬼靈導師", [10486] = "復活的戰士", [11257] = "通靈學院管理者", [10478] = "碎裂的骷髏", [10433] = "馬杜克·布萊克波爾", [10432] = "維克圖斯", [14861] = "基爾圖諾斯的衛士", [14516] = "死亡騎士達克雷爾", [11261] = "瑟爾林·卡斯迪諾夫教授", [10505] = "講師瑪麗希亞", [10502] = "伊露希亞·巴羅夫女士", [10504] = "阿萊克斯·巴羅夫領主", [10901] = "博學者普克爾特", [10507] = "拉文尼亞", [10503] = "詹迪斯·巴羅夫", [11622] = "血骨傀儡", [10506] = "傳令官基爾圖諾斯", [10508] = "萊斯·霜語", [1853] = "黑暗院長加丁"},
	},
	subs = {
		enUS = {[11261] = "The Butcher"},
		frFR = {[11261] = "Le Boucher"},
		deDE = {[11261] = "Der Schlächter"},
		esES = {[11261] = "El Carnicero"},
		esMX = {[11261] = "El Carnicero"},
		ptBR = {[11261] = "O Carniceiro"},
		ruRU = {[11261] = "Мясник"},
		koKR = {[11261] = "도살자"},
		zhCN = {[11261] = "屠夫"},
		zhTW = {[11261] = "屠夫"},
	},
}
