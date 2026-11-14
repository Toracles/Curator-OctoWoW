-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "wailing", kind = "dungeon", instance = 43, area = 718,
	levels = { 17, 24 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 3671, 3669, 3670, 3673, 5775, 3654 }, final = 3654,
	name = "Wailing Caverns",
	title = { frFR = "Cavernes des lamentations", deDE = "Die Höhlen des Wehklagens", esES = "Cuevas de los Lamentos", esMX = "Cuevas de los Lamentos", ptBR = "Caverna Ululante", ruRU = "Пещеры Стенаний", koKR = "통곡의 동굴", zhCN = "哀嚎洞穴" },
	tint = { 0.14, 0.30, 0.18 }, glow = { 0.46, 1.00, 0.60 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioWailing", pack = "PackWailing", set = "SetWailing",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 3640, 1, 10, 0, 17, 18, 1751, 724, false }, -- Evolving Ectoplasm
		{ 5048, 1, 1, 0, 18, 19, 4317, 4499, false }, -- Deviate Adder
		{ 5053, 1, 1, 6, 18, 19, 2996, 1236, false }, -- Deviate Crocolisk
		{ 3637, 1, 1, 11, 18, 19, 755, 708, false }, -- Deviate Guardian
		{ 8886, 1, 1, 0, 18, 19, 8173, 4499, false }, -- Deviate Python
		{ 3636, 1, 1, 11, 18, 19, 1747, 708, false }, -- Deviate Ravager
		{ 5055, 1, 10, 0, 19, 20, 8172, 5050, false }, -- Deviate Lasher
		{ 3840, 1, 7, 0, 19, 20, 4211, 1357, false }, -- Druid of the Fang
		{ 5761, 2, 4, 0, 19, 20, 1084, 462, false }, -- Deviate Shambler
		{ 5056, 2, 1, 27, 20, 21, 3006, 590, false }, -- Deviate Dreadfang
		{ 5756, 2, 1, 27, 20, 21, 2706, 590, false }, -- Deviate Venomwing
		{ 5755, 2, 1, 0, 20, 20, 4312, 4499, false }, -- Deviate Viper
		{ 5912, 3, 2, 0, 20, 20, 1267, 1649, false }, -- Deviate Faerie Dragon
		{ 3678, 3, 7, 0, 20, 20, 1941, 6011, true }, -- Disciple of Naralex
		{ 3653, 3, 1, 21, 20, 20, 5126, 1464, false }, -- Kresh
		{ 3674, 3, 1, 0, 21, 21, 4203, 1974, false }, -- Skum
		{ 3679, 3, 7, 0, 25, 25, 4216, 5989, true }, -- Naralex
		{ 3671, 4, 7, 0, 20, 20, 4313, 1357, false }, -- Lady Anacondra
		{ 3669, 4, 7, 0, 20, 20, 4213, 1357, false }, -- Lord Cobrahn
		{ 3670, 4, 7, 0, 21, 21, 4214, 1357, false }, -- Lord Pythas
		{ 3673, 4, 7, 0, 21, 21, 4215, 1357, false }, -- Lord Serpentis
		{ 5775, 5, 4, 0, 21, 21, 4256, 462, false }, -- Verdan the Everliving
		{ 3654, 6, 7, 0, 22, 22, 4088, 416, false }, -- Mutanus the Devourer
	},
	names = {
		enUS = {[3640] = "Evolving Ectoplasm", [5048] = "Deviate Adder", [5053] = "Deviate Crocolisk", [3637] = "Deviate Guardian", [8886] = "Deviate Python", [3636] = "Deviate Ravager", [5055] = "Deviate Lasher", [3840] = "Druid of the Fang", [5761] = "Deviate Shambler", [5056] = "Deviate Dreadfang", [5756] = "Deviate Venomwing", [5755] = "Deviate Viper", [5912] = "Deviate Faerie Dragon", [3678] = "Disciple of Naralex", [3653] = "Kresh", [3674] = "Skum", [3679] = "Naralex", [3671] = "Lady Anacondra", [3669] = "Lord Cobrahn", [3670] = "Lord Pythas", [3673] = "Lord Serpentis", [5775] = "Verdan the Everliving", [3654] = "Mutanus the Devourer"},
		frFR = {[3640] = "Ectoplasme grandissant", [5048] = "Serpent déviant", [5053] = "Crocilisque déviant", [3637] = "Gardien déviant", [8886] = "Python déviant", [3636] = "Ravageur déviant", [5055] = "Flagellant déviant", [3840] = "Druide du Croc", [5761] = "Glacial déviant", [5056] = "Croc-d'effroi déviant", [5756] = "Venimeux des airs déviant", [5755] = "Vipère déviante", [5912] = "Dragon féérique déviant", [3678] = "Disciple de Naralex", [3653] = "Kresh", [3674] = "Skum", [3679] = "Naralex", [3671] = "Dame Anacondra", [3669] = "Seigneur Cobrahn", [3670] = "Seigneur Pythas", [3673] = "Seigneur Serpentis", [5775] = "Verdan l'Immortel", [3654] = "Mutanus le Dévoreur"},
		deDE = {[3640] = "Entstehendes Ektoplasma", [5048] = "Deviatotter", [5053] = "Deviatkrokilisk", [3637] = "Deviatwächter", [8886] = "Deviatpython", [3636] = "Deviatverheerer", [5055] = "Deviatpeitscher", [3840] = "Druide des Giftzahns", [5761] = "Deviatschlurfer", [5056] = "Deviatschreckensfang", [5756] = "Deviatgiftschwinge", [5755] = "Deviatviper", [5912] = "Deviatfeendrache", [3678] = "Jünger von Naralex", [3653] = "Kresh", [3674] = "Skum", [3679] = "Naralex", [3671] = "Lady Anacondra", [3669] = "Lord Kobrahn", [3670] = "Lord Pythas", [3673] = "Lord Serpentis", [5775] = "Verdan der Ewiglebende", [3654] = "Mutanus der Verschlinger"},
		esES = {[3640] = "Ectoplasma en desarrollo", [5048] = "Agregador descarriado", [5053] = "Crocolisco descarriado", [3637] = "Guardián descarriado", [8886] = "Pitón descarriado", [3636] = "Devastador descarriado", [5055] = "Latigador descarriado", [3840] = "Druida del Colmillo", [5761] = "Arrastrado descarriado", [5056] = "Colminferno descarriado", [5756] = "Venala descarriada", [5755] = "Víbora descarriada", [5912] = "Dragón feérico descarriado", [3678] = "Discípulo de Naralex", [3653] = "Kresh", [3674] = "Skum", [3679] = "Naralex", [3671] = "Lady Anacondra", [3669] = "Lord Cobrahn", [3670] = "Lord Pythas", [3673] = "Lord Serpentis", [5775] = "Verdan el Eterno", [3654] = "Mutanus el Devorador"},
		esMX = {[3640] = "Ectoplasma en desarrollo", [5048] = "Agregador descarriado", [5053] = "Crocolisco descarriado", [3637] = "Guardián descarriado", [8886] = "Pitón descarriado", [3636] = "Devastador descarriado", [5055] = "Latigador descarriado", [3840] = "Druida del Colmillo", [5761] = "Arrastrapiés descarriado", [5056] = "Colminferno descarriado", [5756] = "Venala descarriada", [5755] = "Víbora descarriada", [5912] = "Dragón feérico descarriado", [3678] = "Discípulo de Naralex", [3653] = "Kresh", [3674] = "Skum", [3679] = "Naralex", [3671] = "Lady Anacondra", [3669] = "Lord Cobrahn", [3670] = "Lord Pythas", [3673] = "Lord Serpentis", [5775] = "Verdan el Eterno", [3654] = "Mutanus el Devorador"},
		ptBR = {[3640] = "Ectoplasma Evolutivo", [5048] = "Áspide Anormal", [5053] = "Crocolisco Anormal", [3637] = "Guardião Anormal", [8886] = "Píton Anormal", [3636] = "Assolador Anormal", [5055] = "Dioneia Anormal", [3840] = "Druida da Presa", [5761] = "Trôpego Anormal", [5056] = "Presátera Anormal", [5756] = "Peçonhasa Anormal", [5755] = "Víbora Anormal", [5912] = "Dragoleta Anormal", [3678] = "Discípulo de Naralex", [3653] = "Cresh", [3674] = "Skória", [3679] = "Naralex", [3671] = "Lady Sucurina", [3669] = "Lorde Cobrahn", [3670] = "Lorde Pítias", [3673] = "Lorde Serpentis", [5775] = "Verdan, o Sempre-vivo", [3654] = "Mutanus, o Devorador"},
		ruRU = {[3640] = "Изменчивая эктоплазма", [5048] = "Загадочный аспид", [5053] = "Загадочный кроколиск", [3637] = "Загадочный страж", [8886] = "Загадочный питон", [3636] = "Загадочный опустошитель", [5055] = "Загадочный плеточник", [3840] = "Друид Клыка", [5761] = "Загадочный шаркун", [5056] = "Загадочный страхозуб", [5756] = "Загадочный крылояд", [5755] = "Загадочная гадюка", [5912] = "Загадочный волшебный дракон", [3678] = "Послушник Наралекса", [3653] = "Криг", [3674] = "Шкам", [3679] = "Наралекс", [3671] = "Повелительница Анакондра", [3669] = "Лорд Кобран", [3670] = "Лорд Питонас", [3673] = "Лорд Серпентис", [5775] = "Вердан Бессмертный", [3654] = "Мутанус Пожиратель"},
		koKR = {[3640] = "진화된 세포괴물", [5048] = "돌연변이 살무사", [5053] = "돌연변이 악어", [3637] = "돌연변이 우두머리랩터", [8886] = "돌연변이 비단뱀", [3636] = "돌연변이 약탈자랩터", [5055] = "돌연변이 덩굴손", [3840] = "송곳니의 드루이드", [5761] = "돌연변이 늪괴물", [5056] = "돌연변이 송곳니천둥매", [5756] = "돌연변이 독날개천둥매", [5755] = "돌연변이 독사", [5912] = "돌연변이 요정용", [3678] = "나랄렉스의 신도", [3653] = "크레쉬", [3674] = "스컴", [3679] = "나랄렉스", [3671] = "여군주 아나콘드라", [3669] = "군주 코브란", [3670] = "군주 피타스", [3673] = "군주 서펜티스", [5775] = "영생의 베르단", [3654] = "걸신들린 무타누스"},
		zhCN = {[3640] = "大型软浆怪", [5048] = "无毒飞蛇", [5053] = "变异鳄鱼", [3637] = "变异守护者", [8886] = "变异巨蟒", [3636] = "变异破坏者", [5055] = "变异鞭笞者", [3840] = "尖牙德鲁伊", [5761] = "变异蹒跚者", [5056] = "变异尖牙风蛇", [5756] = "变异剧毒风蛇", [5755] = "剧毒飞蛇", [5912] = "变异精灵龙", [3678] = "纳拉雷克斯的信徒", [3653] = "克雷什", [3674] = "斯卡姆", [3679] = "纳拉雷克斯", [3671] = "安娜科德拉", [3669] = "考布莱恩", [3670] = "皮萨斯", [3673] = "瑟芬迪斯", [5775] = "永生者沃尔丹", [3654] = "吞噬者穆坦努斯"},
		zhTW = {[3640] = "大型軟漿怪", [5048] = "無毒飛蛇", [5053] = "變異鱷魚", [3637] = "變異守護者", [8886] = "變異巨蟒", [3636] = "變異劫毀者", [5055] = "變異鞭笞者", [3840] = "尖牙德魯伊", [5761] = "變異蹣跚者", [5056] = "變異尖牙風蛇", [5756] = "變異劇毒風蛇", [5755] = "劇毒飛蛇", [5912] = "變異精靈龍", [3678] = "納拉雷克斯的信徒", [3653] = "克雷什", [3674] = "斯卡姆", [3679] = "納拉雷克斯", [3671] = "安娜科德拉", [3669] = "考布萊恩領主", [3670] = "皮薩斯領主", [3673] = "瑟芬迪斯領主", [5775] = "永生的沃爾丹", [3654] = "『吞噬者』穆坦努斯"},
	},
	subs = {
		enUS = {[3671] = "Fanglord", [3669] = "Fanglord", [3670] = "Fanglord", [3673] = "Fanglord"},
		frFR = {[3671] = "Seigneur-Croc", [3669] = "Seigneur-Croc", [3670] = "Seigneur-Croc", [3673] = "Seigneur-Croc"},
		deDE = {[3671] = "Giftzahnlord", [3669] = "Giftzahnlord", [3670] = "Giftzahnlord", [3673] = "Giftzahnlord"},
		esES = {[3671] = "Noble del Colmillo", [3669] = "Noble del Colmillo", [3670] = "Noble del Colmillo", [3673] = "Noble del Colmillo"},
		esMX = {[3671] = "Noble del Colmillo", [3669] = "Noble del Colmillo", [3670] = "Noble del Colmillo", [3673] = "Noble del Colmillo"},
		ptBR = {[3671] = "Mestre da Presa", [3669] = "Lorde da Presa", [3670] = "Lorde da Presa", [3673] = "Lorde da Presa"},
		ruRU = {[3671] = "Владыка змей", [3669] = "Владыка змей", [3670] = "Владыка змей", [3673] = "Владыка змей"},
		koKR = {[3671] = "송곳니 군주", [3669] = "송곳니 군주", [3670] = "송곳니 군주", [3673] = "송곳니 군주"},
		zhCN = {[3671] = "毒牙之王", [3669] = "毒牙之王", [3670] = "毒牙之王", [3673] = "毒牙之王"},
		zhTW = {[3671] = "毒牙之王", [3669] = "毒牙之王", [3670] = "毒牙之王", [3673] = "毒牙之王"},
	},
}
