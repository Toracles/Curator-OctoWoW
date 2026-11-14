-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "blackwing", kind = "dungeon", raid = 4, instance = 469, area = 2677,
	levels = { 60, 60 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 12017, 14601, 11983, 11981, 12435, 14020, 13020, 11583 }, final = 11583,
	name = "Blackwing Lair",
	title = { frFR = "Repaire de l'Aile noire", deDE = "Pechschwingenhort", esES = "Guarida Alanegra", esMX = "Guarida Alanegra", ptBR = "Covil Asa Negra", ruRU = "Логово Крыла Тьмы", koKR = "검은날개 둥지", zhCN = "黑翼之巢", zhTW = "黑翼之巢" },
	tint = { 0.15, 0.15, 0.18 }, glow = { 0.86, 0.43, 0.39 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioBlackwing", pack = "PackBlackwing", set = "SetBlackwing",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 13976, 1, 2, 0, 40, 40, 14012, 4065, false }, -- Tortured Drake
		{ 13996, 1, 7, 0, 60, 60, 13991, 1414, false }, -- Blackwing Technician
		{ 14024, 1, 2, 0, 60, 60, 9994, 428, false }, -- Corrupted Blue Whelp
		{ 14025, 1, 2, 0, 60, 60, 14720, 428, false }, -- Corrupted Bronze Whelp
		{ 14023, 1, 2, 0, 60, 60, 694, 428, false }, -- Corrupted Green Whelp
		{ 14022, 1, 2, 0, 60, 60, 956, 428, false }, -- Corrupted Red Whelp
		{ 14456, 1, 7, 0, 61, 61, 12024, 1346, false }, -- Blackwing Guardsman
		{ 12459, 1, 7, 0, 61, 61, 14292, 1346, false }, -- Blackwing Warlock
		{ 12468, 1, 2, 0, 61, 61, 12892, 3525, false }, -- Death Talon Hatcher
		{ 12465, 1, 2, 0, 61, 61, 12894, 3525, false }, -- Death Talon Wyrmkin
		{ 12457, 2, 2, 0, 62, 62, 7923, 2937, false }, -- Blackwing Spellbinder
		{ 12458, 2, 7, 0, 62, 62, 11967, 1346, false }, -- Blackwing Taskmaster
		{ 12463, 2, 2, 0, 62, 62, 8310, 3525, false }, -- Death Talon Flamescale
		{ 12461, 2, 7, 0, 62, 62, 14355, 8162, false }, -- Death Talon Overseer
		{ 12464, 2, 2, 0, 62, 62, 12893, 3525, false }, -- Death Talon Seether
		{ 12460, 2, 2, 0, 63, 63, 14308, 8162, false }, -- Death Talon Wyrmguard
		{ 14401, 3, 7, 0, 60, 60, 14498, 1414, false }, -- Master Elemental Shaper Krixix
		{ 12467, 3, 2, 0, 62, 62, 14544, 3525, false }, -- Death Talon Captain
		{ 12557, 3, 7, 0, 62, 62, 14296, 1346, false }, -- Grethok the Controller
		{ 10162, 3, 2, 0, 63, 63, 9472, 1328, false }, -- Lord Victor Nefarius
		{ 12017, 4, 2, 0, 63, 63, 14308, 8162, false }, -- Broodlord Lashlayer
		{ 14601, 4, 2, 0, 63, 63, 6377, 4065, false }, -- Ebonroc
		{ 11983, 4, 2, 0, 63, 63, 6377, 4065, false }, -- Firemaw
		{ 11981, 4, 2, 0, 63, 63, 6377, 4065, false }, -- Flamegor
		{ 12435, 4, 2, 0, 63, 63, 10115, 3525, false }, -- Razorgore the Untamed
		{ 14020, 5, 2, 0, 63, 63, 14367, 8317, false }, -- Chromaggus
		{ 13020, 5, 2, 0, 63, 63, 13992, 3525, false }, -- Vaelastrasz the Corrupt
		{ 11583, 6, 2, 0, 63, 63, 11380, 8288, false }, -- Nefarian
	},
	names = {
		enUS = {[13976] = "Tortured Drake", [13996] = "Blackwing Technician", [14024] = "Corrupted Blue Whelp", [14025] = "Corrupted Bronze Whelp", [14023] = "Corrupted Green Whelp", [14022] = "Corrupted Red Whelp", [14456] = "Blackwing Guardsman", [12459] = "Blackwing Warlock", [12468] = "Death Talon Hatcher", [12465] = "Death Talon Wyrmkin", [12457] = "Blackwing Spellbinder", [12458] = "Blackwing Taskmaster", [12463] = "Death Talon Flamescale", [12461] = "Death Talon Overseer", [12464] = "Death Talon Seether", [12460] = "Death Talon Wyrmguard", [14401] = "Master Elemental Shaper Krixix", [12467] = "Death Talon Captain", [12557] = "Grethok the Controller", [10162] = "Lord Victor Nefarius", [12017] = "Broodlord Lashlayer", [14601] = "Ebonroc", [11983] = "Firemaw", [11981] = "Flamegor", [12435] = "Razorgore the Untamed", [14020] = "Chromaggus", [13020] = "Vaelastrasz the Corrupt", [11583] = "Nefarian"},
		frFR = {[13976] = "Drake torturé", [13996] = "Technicien de l'Aile noire", [14024] = "Dragonnet bleu corrompu", [14025] = "Dragonnet bronze corrompu", [14023] = "Dragonnet vert corrompu", [14022] = "Dragonnet rouge corrompu", [14456] = "Garde de l'Aile noire", [12459] = "Démoniste de l'Aile noire", [12468] = "Eveilleur Griffemort", [12465] = "Wyrmide Griffemort", [12457] = "Lieur de sort de l'Aile noire", [12458] = "Sous-chef de l'Aile noire", [12463] = "Flammécaille Griffemort", [12461] = "Surveillant Griffemort", [12464] = "Rongé Griffemort", [12460] = "Garde wyrm Griffemort", [14401] = "Maître élémentaire Krixix le Sculpteur", [12467] = "Capitaine Griffemort", [12557] = "Grethok le Contrôleur", [10162] = "Seigneur Victor Nefarius", [12017] = "Seigneur des couvées Lashlayer", [14601] = "Rochébène", [11983] = "Gueule-de-feu", [11981] = "Flamegor", [12435] = "Tranchetripe l'Indompté", [14020] = "Chromaggus", [13020] = "Vaelastrasz le Corrompu", [11583] = "Nefarian"},
		deDE = {[13976] = "Gequälter Drache", [13996] = "Techniker der Pechschwingen", [14024] = "Verderbter blauer Welpe", [14025] = "Verderbter bronzener Welpe", [14023] = "Verderbter grüner Welpe", [14022] = "Verderbter roter Welpe", [14456] = "Gardist der Pechschwingen", [12459] = "Hexenmeister der Pechschwingen", [12468] = "Brutwächter der Todeskrallen", [12465] = "Wyrmkin der Todeskrallen", [12457] = "Zauberbinder der Pechschwingen", [12458] = "Zuchtmeister der Pechschwingen", [12463] = "Flammenschuppe der Todeskrallen", [12461] = "Aufseher der Todeskrallen", [12464] = "Schnauber der Todeskrallen", [12460] = "Wyrmwache der Todeskrallen", [14401] = "Meisterelementarformer Krixix", [12467] = "Captain der Todeskrallen", [12557] = "Grethok der Aufseher", [10162] = "Lord Victor Nefarius", [12017] = "Brutwächter Dreschbringer", [14601] = "Schattenschwinge", [11983] = "Feuerschwinge", [11981] = "Flammenmaul", [12435] = "Razorgore der Ungezähmte", [14020] = "Chromaggus", [13020] = "Vaelastrasz der Verdorbene", [11583] = "Nefarian"},
		esES = {[13976] = "Draco torturado", [13996] = "Técnico Alanegra", [14024] = "Cría azul corrupta", [14025] = "Cría de bronce corrupta", [14023] = "Cría verde corrupta", [14022] = "Cría roja corrupta", [14456] = "Custodio Alanegra", [12459] = "Brujo Alanegra", [12468] = "Criador Garramortal", [12465] = "Vermis Garramortal", [12457] = "Vinculador de hechizos Alanegra", [12458] = "Capataz Alanegra", [12463] = "Flamascama Garramortal", [12461] = "Sobrestante Garramortal", [12464] = "Bullidor Garramortal", [12460] = "Vermiguardia Garramortal", [14401] = "Maestro de los elementos Formacio Krixix", [12467] = "Capitán Garramortal", [12557] = "Grethok el Controlador", [10162] = "Lord Víctor Nefarius", [12017] = "Señor de prole Capazote", [14601] = "Ebanorroca", [11983] = "Faucefogo", [11981] = "Flamagor", [12435] = "Sangrevaja el Indomable", [14020] = "Chromaggus", [13020] = "Vaelastrasz el Corrupto", [11583] = "Nefarian"},
		esMX = {[13976] = "Draco torturado", [13996] = "Técnico Alanegra", [14024] = "Cría azul corrupta", [14025] = "Cría de bronce corrupta", [14023] = "Cría verde corrupta", [14022] = "Cría roja corrupta", [14456] = "Custodio Alanegra", [12459] = "Brujo Alanegra", [12468] = "Criador Garramortal", [12465] = "Vermis Garramortal", [12457] = "Vinculador de hechizos Alanegra", [12458] = "Capataz Alanegra", [12463] = "Flamascama Garramortal", [12461] = "Sobrestante Garramortal", [12464] = "Bullidor Garramortal", [12460] = "Vermiguardia Garramortal", [14401] = "Maestro de los elementos Formacio Krixix", [12467] = "Capitán Garramortal", [12557] = "Grethok el Controlador", [10162] = "Lord Víctor Nefarius", [12017] = "Señor de linaje Capazote", [14601] = "Ebanorroca", [11983] = "Faucefogo", [11981] = "Flamagor", [12435] = "Sangrevaja el Indomable", [14020] = "Chromaggus", [13020] = "Vaelastrasz el Corrupto", [11583] = "Nefarian"},
		ptBR = {[13976] = "Draco Torturado", [13996] = "Técnico Asa Negra", [14024] = "Dragonete Azul Corrompido", [14025] = "Dragonete Bronze Corrompido", [14023] = "Dragonete Verde Corrompido", [14022] = "Dragonete Vermelho Corrompido", [14456] = "Guarda Asa Negra", [12459] = "Bruxo Asa Negra", [12468] = "Fecundador Garra da Morte", [12465] = "Draconoide Garra da Morte", [12457] = "Mesmerizador Asa Negra", [12458] = "Capataz Asa Negra", [12463] = "Flamescama Garra da Morte", [12461] = "Feitor Garra da Morte", [12464] = "Furiário Garra da Morte", [12460] = "Serpeguarda Garra da Morte", [14401] = "Mestre Moldador Elemental Krixix", [12467] = "Capitão Garra da Morte", [12557] = "Grethok, o Controlador", [10162] = "Lorde Victor Nefarius", [12017] = "Prolemestre Flagelador", [14601] = "Petrébano", [11983] = "Fogorja", [11981] = "Flamagor", [12435] = "Violâminus, o Indomado", [14020] = "Cromaggus", [13020] = "Vaelastrasz, o Corrupto", [11583] = "Nefarian"},
		ruRU = {[13976] = "Страдающий дракон", [13996] = "Техник Крыла Тьмы", [14024] = "Оскверненный синий дракончик", [14025] = "Оскверненный бронзовый дракончик", [14023] = "Оскверненный зеленый дракончик", [14022] = "Оскверненный красный дракончик", [14456] = "Стражник Крыла Тьмы", [12459] = "Чернокнижник Крыла Тьмы", [12468] = "Гнездовая Когтя Смерти", [12465] = "Драконида Когтя Смерти", [12457] = "Чароплет Крыла Тьмы", [12458] = "Надсмотрщик из логова Крыла Тьмы", [12463] = "Огнекож Когтя Смерти", [12461] = "Надзиратель Когтя Смерти", [12464] = "Огнечар Когтя Смерти", [12460] = "Змеестраж Когтя Смерти", [14401] = "Ваятель стихий Криксикс", [12467] = "Капитан Когтя Смерти", [12557] = "Греток Регулятор", [10162] = "Лорд Виктор Нефариус", [12017] = "Предводитель драконов Разящий Бич", [14601] = "Черноскал", [11983] = "Огнечрев", [11981] = "Пламегор", [12435] = "Бритвосмерт Неукротимый", [14020] = "Хроммагус", [13020] = "Валестраз Порочный", [11583] = "Нефариан"},
		koKR = {[13976] = "고통받는 비룡", [13996] = "검은날개 기술병", [14024] = "타락한 푸른 새끼용", [14025] = "타락한 청동 새끼용", [14023] = "타락한 녹색 새끼용", [14022] = "타락한 붉은 새끼용", [14456] = "검은날개 수호병", [12459] = "검은날개 흑마법사", [12468] = "죽음의발톱 알지기", [12465] = "죽음의발톱 고룡족", [12457] = "검은날개 역술사", [12458] = "검은날개 작업반장", [12463] = "죽음의발톱 화염전사", [12461] = "죽음의발톱 감독관", [12464] = "죽음의발톱 정예병", [12460] = "죽음의발톱 고룡수호병", [14401] = "수석 원소구현술사 크릭시스", [12467] = "죽음의발톱 부대장", [12557] = "감시자 그레토크", [10162] = "군주 빅터 네파리우스", [12017] = "용기대장 래쉬레이어", [14601] = "에본로크", [11983] = "화염아귀", [11981] = "플레임고르", [12435] = "폭군 서슬송곳니", [14020] = "크로마구스", [13020] = "타락한 밸라스트라즈", [11583] = "네파리안"},
		zhCN = {[13976] = "被折磨的幼龙", [13996] = "黑翼技师", [14024] = "腐化的蓝色雏龙", [14025] = "腐化的青铜雏龙", [14023] = "腐化的绿色雏龙", [14022] = "腐化的红色雏龙", [14456] = "黑翼卫士", [12459] = "黑翼管理者", [12468] = "死爪地卜师", [12465] = "死爪老龙人", [12457] = "黑翼缚法者", [12458] = "黑翼工头", [12463] = "死爪火鳞龙人", [12461] = "黑翼监工", [12464] = "死爪狂乱者", [12460] = "黑翼龙人护卫", [14401] = "大元素师克里希克", [12467] = "死爪龙人队长", [12557] = "黑翼控制者", [10162] = "维克多·奈法里奥斯", [12017] = "勒什雷尔", [14601] = "埃博诺克", [11983] = "费尔默", [11981] = "弗莱格尔", [12435] = "狂野的拉佐格尔", [14020] = "克洛玛古斯", [13020] = "堕落的瓦拉斯塔兹", [11583] = "奈法利安"},
		zhTW = {[13976] = "被折磨的龍", [13996] = "黑翼技師", [14024] = "腐化的藍色幼龍", [14025] = "腐化的青銅幼龍", [14023] = "腐化的綠色幼龍", [14022] = "腐化的紅色幼龍", [14456] = "黑翼衛士", [12459] = "黑翼管理者", [12468] = "死爪地卜師", [12465] = "死爪老龍人", [12457] = "黑翼縛法者", [12458] = "黑翼監工", [12463] = "死爪火鱗龍人", [12461] = "死爪監督者", [12464] = "死爪狂亂者", [12460] = "死爪龍人護衛", [14401] = "大元素師克里希克", [12467] = "死爪龍人隊長", [12557] = "『控制者』葛瑞托克", [10162] = "維克多·奈法利斯領主", [12017] = "龍領主勒西雷爾", [14601] = "埃博諾克", [11983] = "費爾默", [11981] = "弗萊格爾", [12435] = "狂野的拉佐格爾", [14020] = "克洛瑪古斯", [13020] = "墮落的瓦拉斯塔茲", [11583] = "奈法利安"},
	},
	subs = {
		enUS = {[10162] = "Lord of Blackrock"},
		frFR = {[10162] = "Seigneur du Clan Blackrock"},
		deDE = {[10162] = "Lord von Blackrock"},
		esES = {[10162] = "Señor de Roca Negra"},
		esMX = {[10162] = "Señor de Roca Negra"},
		ptBR = {[10162] = "Senhor dos Rocha Negra"},
		ruRU = {[10162] = "Владыка Черной горы"},
		koKR = {[10162] = "검은바위의 지배자"},
		zhCN = {[10162] = "黑石之王"},
		zhTW = {[10162] = "黑石之王"},
	},
}
