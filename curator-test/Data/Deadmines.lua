-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "deadmines", kind = "dungeon", instance = 36, area = 1581,
	levels = { 17, 26 }, side = "A",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 644, 647, 645, 1763, 642, 646, 639 }, final = 639,
	name = "The Deadmines",
	title = { frFR = "Les Mortemines", deDE = "Die Todesminen", esES = "Las Minas de la Muerte", esMX = "Las Minas de la Muerte", ptBR = "Minas Mortas", ruRU = "Мертвые Копи", koKR = "죽음의 폐광", zhCN = "死亡矿井" },
	tint = { 0.36, 0.22, 0.10 }, glow = { 1.00, 0.72, 0.36 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioDeadmines", pack = "PackDeadmines", set = "SetDeadmines",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 1729, 1, 7, 0, 17, 18, 2318, 1328, false }, -- Defias Evoker
		{ 634, 1, 7, 0, 17, 18, 2316, 1328, false }, -- Defias Overseer
		{ 598, 1, 7, 0, 18, 18, 308, 1294, false }, -- Defias Miner
		{ 4416, 1, 7, 0, 18, 19, 2438, 1294, false }, -- Defias Strip Miner
		{ 4417, 1, 7, 0, 18, 19, 2440, 1328, false }, -- Defias Taskmaster
		{ 1731, 1, 7, 0, 18, 19, 7110, 1414, false }, -- Goblin Craftsman
		{ 622, 1, 7, 0, 18, 19, 7109, 1414, false }, -- Goblin Engineer
		{ 641, 1, 7, 0, 18, 19, 7111, 1414, false }, -- Goblin Woodcarver
		{ 4418, 2, 7, 0, 18, 19, 2447, 1328, false }, -- Defias Wizard
		{ 636, 2, 7, 0, 19, 20, 2314, 1328, false }, -- Defias Blackguard
		{ 657, 2, 7, 0, 19, 20, 2347, 1328, false }, -- Defias Pirate
		{ 1732, 2, 7, 0, 19, 20, 2349, 2937, false }, -- Defias Squallshaper
		{ 3947, 2, 7, 0, 19, 20, 7112, 1414, false }, -- Goblin Shipbuilder
		{ 3586, 3, 7, 0, 19, 19, 556, 1294, false }, -- Miner Johnson
		{ 643, 3, 7, 0, 20, 20, 7125, 1414, false }, -- Sneed
		{ 644, 4, 7, 0, 19, 19, 14403, 396, false }, -- Rhahk'Zor
		{ 647, 4, 7, 0, 20, 20, 7113, 1414, false }, -- Captain Greenskin
		{ 645, 4, 7, 0, 20, 20, 1305, 416, false }, -- Cookie
		{ 1763, 4, 7, 0, 20, 20, 7124, 1414, false }, -- Gilnid
		{ 642, 4, 9, 0, 20, 20, 1269, 1982, false }, -- Sneed's Shredder
		{ 646, 5, 7, 0, 20, 20, 2026, 1353, false }, -- Mr. Smite
		{ 639, 6, 7, 0, 21, 21, 2029, 1328, false }, -- Edwin VanCleef
	},
	names = {
		enUS = {[1729] = "Defias Evoker", [634] = "Defias Overseer", [598] = "Defias Miner", [4416] = "Defias Strip Miner", [4417] = "Defias Taskmaster", [1731] = "Goblin Craftsman", [622] = "Goblin Engineer", [641] = "Goblin Woodcarver", [4418] = "Defias Wizard", [636] = "Defias Blackguard", [657] = "Defias Pirate", [1732] = "Defias Squallshaper", [3947] = "Goblin Shipbuilder", [3586] = "Miner Johnson", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Captain Greenskin", [645] = "Cookie", [1763] = "Gilnid", [642] = "Sneed's Shredder", [646] = "Mr. Smite", [639] = "Edwin VanCleef"},
		frFR = {[1729] = "Evocateur défias", [634] = "Surveillant défias", [598] = "Mineur défias", [4416] = "Carrier défias", [4417] = "Sous-chef défias", [1731] = "Artisan gobelin", [622] = "Ingénieur gobelin", [641] = "Sculpteur gobelin", [4418] = "Sorcier défias", [636] = "Canaille défias", [657] = "Pirate défias", [1732] = "Forme-grain défias", [3947] = "Constructeur naval gobelin", [3586] = "Mineur Johnson", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Capitaine Vertepeau", [645] = "Macaron", [1763] = "Gilnid", [642] = "Déchiqueteur de Sneed", [646] = "M. Smite", [639] = "Edwin VanCleef"},
		deDE = {[1729] = "Rufer der Defias", [634] = "Vorarbeiter der Defias", [598] = "Minenarbeiter der Defias", [4416] = "Akkordminenarbeiter der Defias", [4417] = "Zuchtmeister der Defias", [1731] = "Goblin-Handwerker", [622] = "Goblin-Ingenieur", [641] = "Goblin-Holzschnitzer", [4418] = "Hexer der Defias", [636] = "Lump der Defias", [657] = "Pirat der Defias", [1732] = "Wellenformer der Defias", [3947] = "Goblin-Schiffbauer", [3586] = "Minenarbeiter Johnson", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Captain Greenskin", [645] = "Cookie", [1763] = "Gilnid", [642] = "Sneeds Schredder", [646] = "Mr. Smite", [639] = "Edwin van Cleef"},
		esES = {[1729] = "Evocador Defias", [634] = "Sobrestante Defias", [598] = "Minero Defias", [4416] = "Cantero Defias", [4417] = "Capataz Defias", [1731] = "Artesano goblin", [622] = "Ingeniero goblin", [641] = "Tallador de madera goblin", [4418] = "Zahorí Defias", [636] = "Guardanegro Defias", [657] = "Pirata Defias", [1732] = "Formarrasca Defias", [3947] = "Armador goblin", [3586] = "Minero Johnson", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Capitán Verdetez", [645] = "Cocinitas", [1763] = "Gilnid", [642] = "Trituradora de Sneed", [646] = "Don Mamporro", [639] = "Edwin VanCleef"},
		esMX = {[1729] = "Evocador Defias", [634] = "Sobrestante Defias", [598] = "Minero Defias", [4416] = "Cantero Defias", [4417] = "Capataz Defias", [1731] = "Artesano goblin", [622] = "Ingeniero goblin", [641] = "Tallador de madera goblin", [4418] = "Zahorí Defias", [636] = "Guardanegro Defias", [657] = "Pirata Defias", [1732] = "Formarrasca Defias", [3947] = "Armador goblin", [3586] = "Minero Johnson", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Capitán Verdetez", [645] = "Cocinitas", [1763] = "Gilnid", [642] = "Trituradora de Sneed", [646] = "Don Mamporro", [639] = "Edwin VanCleef"},
		ptBR = {[1729] = "Evocador Défias", [634] = "Feitor Défias", [598] = "Minerador Défias", [4416] = "Cavouqueiro Défias", [4417] = "Capataz Défias", [1731] = "Goblin Artesão", [622] = "Engenheiro Goblínico", [641] = "Goblin Entalhador", [4418] = "Teurgo Défias", [636] = "Guardião das Sombras Défias", [657] = "Pirata Défias", [1732] = "Artífice de Borrasca Défias", [3947] = "Goblin Construtor de Navios", [3586] = "Minerador João", [643] = "Sneed", [644] = "Rhahk'Zor", [647] = "Capitão Peleverde", [645] = "Cuca", [1763] = "Gilnid", [642] = "Retalhador do Sneed", [646] = "Sr. Castiga", [639] = "Edwin VanCleef"},
		ruRU = {[1729] = "Вызыватель из Братства Справедливости", [634] = "Надзиратель из Братства Справедливости", [598] = "Шахтер из Братства Справедливости", [4416] = "Горнорабочий из Братства Справедливости", [4417] = "Надсмотрщик из Братства Справедливости", [1731] = "Гоблин-ремесленник", [622] = "Гоблин-инженер", [641] = "Гоблин-древоруб", [4418] = "Волшебник из Братства Справедливости", [636] = "Черный страж из Братства Справедливости", [657] = "Пират из Братства Справедливости", [1732] = "Ветроплет из Братства Справедливости", [3947] = "Гоблин-корабел", [3586] = "Шахтер Джонсон", [643] = "Снид", [644] = "Рак'Зор", [647] = "Капитан Зеленямс", [645] = "Пирожок", [1763] = "Гилнид", [642] = "Крошшер Снида", [646] = "Мистер Каюк", [639] = "Эдвин ван Клиф"},
		koKR = {[1729] = "데피아즈단 기원사", [634] = "데피아즈단 감독관", [598] = "데피아즈단 광부", [4416] = "데피아즈단 갱부", [4417] = "데피아즈단 작업반장", [1731] = "고블린 땜장이", [622] = "고블린 기술자", [641] = "고블린 목공", [4418] = "데피아즈단 마술사", [636] = "데피아즈단 검은자객", [657] = "데피아즈단 해적", [1732] = "데피아즈단 얼음마법사", [3947] = "고블린 조선공", [3586] = "광부 존슨", [643] = "스니드", [644] = "라크조르", [647] = "선장 그린스킨", [645] = "쿠키", [1763] = "길니드", [642] = "스니드의 벌목기", [646] = "미스터 스마이트", [639] = "에드윈 밴클리프"},
		zhCN = {[1729] = "迪菲亚招魂师", [634] = "迪菲亚监工", [598] = "迪菲亚矿工", [4416] = "迪菲亚赤膊矿工", [4417] = "迪菲亚工头", [1731] = "地精工匠", [622] = "地精工程师", [641] = "地精木匠", [4418] = "迪菲亚巫师", [636] = "迪菲亚黑衣卫兵", [657] = "迪菲亚海盗", [1732] = "迪菲亚塑风师", [3947] = "地精造船师", [3586] = "矿工约翰森", [643] = "斯尼德", [644] = "拉克佐", [647] = "绿皮队长", [645] = "曲奇", [1763] = "基尔尼格", [642] = "斯尼德的伐木机", [646] = "重拳先生", [639] = "艾德温·范克里夫"},
		zhTW = {[1729] = "迪菲亞塑能師", [634] = "迪菲亞監督者", [598] = "迪菲亞礦工", [4416] = "迪菲亞赤膊礦工", [4417] = "迪菲亞監工", [1731] = "哥布林工匠", [622] = "哥布林工程師", [641] = "哥布林木匠", [4418] = "迪菲亞巫師", [636] = "迪菲亞黑衣衛兵", [657] = "迪菲亞海賊", [1732] = "迪菲亞塑風師", [3947] = "哥布林造船師", [3586] = "礦工約翰森", [643] = "斯尼德", [644] = "拉克佐", [647] = "綠皮隊長", [645] = "廚師", [1763] = "基爾尼格", [642] = "斯尼德的伐木機", [646] = "重拳先生", [639] = "艾德溫·范克里夫"},
	},
	subs = {
		enUS = {[643] = "Lumbermaster", [644] = "The Foreman", [645] = "The Ship's Cook", [1763] = "The Smelter", [642] = "Lumbermaster", [646] = "The Ship's First Mate", [639] = "Defias Kingpin"},
		frFR = {[643] = "Bûcheron", [644] = "Le contremaître", [645] = "Le cuistot du navire", [1763] = "Le fondeur", [642] = "Bûcheron", [646] = "Le premier officier du navire", [639] = "Caïd défias"},
		deDE = {[643] = "Holzfällermeister", [644] = "Der Großknecht", [645] = "Der Smutje", [1763] = "Der Schmelzer", [642] = "Holzfällermeister", [646] = "Der Erste Maat", [639] = "Herrscher der Defias"},
		esES = {[643] = "Maestro leñador", [644] = "El Supervisor", [645] = "El cocinero del barco", [1763] = "El Fundidor", [642] = "Maestro leñador", [646] = "El contramaestre del barco", [639] = "Cerebro de los Defias"},
		esMX = {[643] = "Maestro leñador", [644] = "El Supervisor", [645] = "El cocinero del barco", [1763] = "El Fundidor", [642] = "Maestro leñador", [646] = "El contramaestre del barco", [639] = "Cerebro de los Defias"},
		ptBR = {[643] = "Madeireiro", [644] = "O Capataz", [645] = "Cozinheiro do Navio", [1763] = "O Fundidor", [642] = "Madeireiro", [646] = "Imediato do Navio", [639] = "Chefão Défias"},
		ruRU = {[643] = "Начальник лесозаготовки", [644] = "Штейгер", [645] = "Корабельный кок", [1763] = "Литейщик", [642] = "Начальник лесозаготовки", [646] = "Первый помощник капитана", [639] = "Главарь Братства Справедливости"},
		koKR = {[643] = "작업 감독관", [644] = "감독관", [645] = "요리사", [1763] = "제련공", [642] = "작업 감독관", [646] = "일등항해사", [639] = "데피아즈단 두목"},
		zhCN = {[643] = "伐木工头", [644] = "工头", [645] = "船上的厨师", [1763] = "熔炼师", [642] = "伐木工头", [646] = "船上的大副", [639] = "迪菲亚兄弟会首脑"},
		zhTW = {[643] = "伐木工頭", [644] = "工頭", [645] = "船上的廚師", [1763] = "熔煉師", [642] = "伐木工頭", [646] = "船上的大副", [639] = "迪菲亞兄弟會首腦"},
	},
}
