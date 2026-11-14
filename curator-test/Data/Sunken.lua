-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "sunken", kind = "dungeon", instance = 109, area = 1477,
	levels = { 50, 56 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 8580, 5720, 5719, 5721, 5722, 5711, 5710, 8443, 5709 }, final = 5709,
	name = "The Temple of Atal'Hakkar",
	title = { frFR = "Le temple d'Atal'Hakkar", deDE = "Der Tempel von Atal'Hakkar", esES = "El Templo de Atal'Hakkar", esMX = "El Templo de Atal'Hakkar", ptBR = "Templo de Atal'Hakkar", ruRU = "Храм Атал'Хаккар", koKR = "아탈학카르 신전", zhCN = "阿塔哈卡神庙" },
	tint = { 0.12, 0.31, 0.21 }, glow = { 0.59, 0.94, 0.75 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioSunken", pack = "PackSunken", set = "SetSunken",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 8311, 1, 1, 0, 45, 46, 7571, 5043, false }, -- Slime Maggot
		{ 5269, 1, 7, 0, 46, 47, 4776, 1034, false }, -- Atal'ai Priest
		{ 8318, 1, 3, 0, 46, 47, 7554, 770, false }, -- Atal'ai Slave
		{ 5263, 1, 6, 0, 46, 47, 4769, 1034, false }, -- Mummified Atal'ai
		{ 8384, 1, 4, 0, 47, 49, 631, 462, false }, -- Deep Lurker
		{ 5226, 1, 1, 0, 47, 48, 7549, 5043, false }, -- Murk Worm
		{ 5228, 1, 10, 0, 47, 48, 682, 724, false }, -- Saturated Ooze
		{ 5256, 1, 7, 0, 48, 49, 7709, 1034, false }, -- Atal'ai Warrior
		{ 5259, 1, 7, 0, 48, 50, 6670, 1034, false }, -- Atal'ai Witch Doctor
		{ 5267, 1, 6, 0, 48, 49, 4771, 1034, false }, -- Unliving Atal'ai
		{ 5270, 1, 6, 0, 49, 50, 4778, 1034, false }, -- Atal'ai Corpse Eater
		{ 8319, 1, 2, 0, 49, 50, 621, 428, false }, -- Nightmare Whelp
		{ 5291, 2, 1, 27, 49, 50, 7569, 590, false }, -- Hakkari Frostwing
		{ 5277, 2, 2, 0, 49, 51, 7903, 3525, false }, -- Nightmare Scalebane
		{ 5283, 2, 2, 0, 49, 50, 181, 3525, false }, -- Nightmare Wanderer
		{ 5271, 2, 6, 0, 50, 51, 4773, 1034, false }, -- Atal'ai Deathwalker
		{ 5273, 2, 7, 0, 50, 51, 6675, 1034, false }, -- Atal'ai High Priest
		{ 5280, 2, 2, 0, 50, 51, 7863, 3525, false }, -- Nightmare Wyrmkin
		{ 5708, 2, 1, 27, 51, 51, 4065, 590, false }, -- Spawn of Hakkar
		{ 5713, 3, 6, 0, 51, 51, 6698, 1034, false }, -- Gasher
		{ 5714, 3, 6, 0, 51, 51, 6700, 1034, false }, -- Loro
		{ 5712, 3, 6, 0, 51, 51, 6699, 1034, false }, -- Zolo
		{ 5715, 3, 6, 0, 52, 52, 6702, 1034, false }, -- Hukku
		{ 5717, 3, 6, 0, 52, 52, 6707, 1034, false }, -- Mijan
		{ 5716, 3, 6, 0, 52, 52, 6701, 1034, false }, -- Zul'Lor
		{ 8580, 4, 7, 0, 50, 50, 7873, 1034, false }, -- Atal'alarion
		{ 5720, 4, 2, 0, 51, 51, 6375, 4065, false }, -- Weaver
		{ 5719, 4, 2, 0, 52, 52, 7975, 4065, false }, -- Morphaz
		{ 5721, 4, 2, 0, 53, 53, 7553, 4065, false }, -- Dreamscythe
		{ 5722, 4, 2, 0, 53, 53, 9584, 4065, false }, -- Hazzas
		{ 5711, 4, 6, 0, 53, 53, 6709, 1034, false }, -- Ogom the Wretched
		{ 5710, 4, 7, 0, 54, 54, 6708, 1034, false }, -- Jammal'an the Prophet
		{ 8443, 5, 10, 0, 49, 50, 8053, 5871, false }, -- Avatar of Hakkar
		{ 5709, 6, 2, 0, 55, 55, 7806, 3525, false }, -- Shade of Eranikus
	},
	names = {
		enUS = {[8311] = "Slime Maggot", [5269] = "Atal'ai Priest", [8318] = "Atal'ai Slave", [5263] = "Mummified Atal'ai", [8384] = "Deep Lurker", [5226] = "Murk Worm", [5228] = "Saturated Ooze", [5256] = "Atal'ai Warrior", [5259] = "Atal'ai Witch Doctor", [5267] = "Unliving Atal'ai", [5270] = "Atal'ai Corpse Eater", [8319] = "Nightmare Whelp", [5291] = "Hakkari Frostwing", [5277] = "Nightmare Scalebane", [5283] = "Nightmare Wanderer", [5271] = "Atal'ai Deathwalker", [5273] = "Atal'ai High Priest", [5280] = "Nightmare Wyrmkin", [5708] = "Spawn of Hakkar", [5713] = "Gasher", [5714] = "Loro", [5712] = "Zolo", [5715] = "Hukku", [5717] = "Mijan", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Weaver", [5719] = "Morphaz", [5721] = "Dreamscythe", [5722] = "Hazzas", [5711] = "Ogom the Wretched", [5710] = "Jammal'an the Prophet", [8443] = "Avatar of Hakkar", [5709] = "Shade of Eranikus"},
		frFR = {[8311] = "Gelée urticante", [5269] = "Prêtre atal'ai", [8318] = "Esclave atal'ai", [5263] = "Atal'ai momifié", [8384] = "Rôdeur des Abysses", [5226] = "Ver des boues", [5228] = "Limon saturé", [5256] = "Guerrier atal'ai", [5259] = "Sorcier-docteur atal'ai", [5267] = "Atal'ai non-vivant", [5270] = "Charognard atal'ai", [8319] = "Dragonnet de cauchemar", [5291] = "Aile-de-givre hakkari", [5277] = "Cavale de cauchemar Plaiedécaille", [5283] = "Cavale de cauchemar errante", [5271] = "Marche-mort atal'ai", [5273] = "Grand prêtre atal'ai", [5280] = "Cavale de cauchemar wyrmide", [5708] = "Rejeton d'Hakkar", [5713] = "Balafreur", [5714] = "Loro", [5712] = "Zolo", [5715] = "Hukku", [5717] = "Mijan", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Tisserand", [5719] = "Morphaz", [5721] = "Fauche-rêve", [5722] = "Hazzas", [5711] = "Ogom le Misérable", [5710] = "Jammal'an le prophète", [8443] = "Avatar d'Hakkar", [5709] = "Ombre d'Eranikus"},
		deDE = {[8311] = "Schleimmade", [5269] = "Priester der Atal'ai", [8318] = "Sklave der Atal'ai", [5263] = "Mumifizierter Atal'ai", [8384] = "Tiefenlauerer", [5226] = "Düsterwurm", [5228] = "Gesättigter Brühschlammer", [5256] = "Krieger der Atal'ai", [5259] = "Hexendoktor der Atal'ai", [5267] = "Untoter Atal'ai", [5270] = "Leichenfresser der Atal'ai", [8319] = "Nachtmahrwelpe", [5291] = "Frostflügler der Hakkari", [5277] = "Nachtmahrbannschuppe", [5283] = "Nachtmahrwanderer", [5271] = "Todeswandler der Atal'ai", [5273] = "Hohepriester der Atal'ai", [5280] = "Nachtmahrwyrmkin", [5708] = "Brut von Hakkar", [5713] = "Schlitzer", [5714] = "Loro", [5712] = "Zolo", [5715] = "Hukku", [5717] = "Mijan", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Wirker", [5719] = "Morphaz", [5721] = "Traumsense", [5722] = "Hazzas", [5711] = "Ogom der Elende", [5710] = "Jammal'an der Prophet", [8443] = "Avatar von Hakkar", [5709] = "Eranikus' Schemen"},
		esES = {[8311] = "Cresa de baba", [5269] = "Sacerdote Atal'ai", [8318] = "Esclavo Atal'ai", [5263] = "Atal'ai momificado", [8384] = "Rondador de lo profundo", [5226] = "Gusano de la oscuridad", [5228] = "Moco saturado", [5256] = "Guerrero Atal'ai", [5259] = "Médico brujo Atal'ai", [5267] = "Atal'ai sin vida", [5270] = "Comecadáveres Atal'ai", [8319] = "Cría de la Pesadilla", [5291] = "Alascarcha Hakkari", [5277] = "Horrocrusto pesadilla", [5283] = "Errante pesadilla", [5271] = "Caminamuerte Atal'ai", [5273] = "Sumo sacerdote Atal'ai", [5280] = "Verminte pesadilla", [5708] = "Alevín de Hakkar", [5713] = "Gasher", [5714] = "Loh'ro", [5712] = "Zolo", [5715] = "Hukku", [5717] = "Mijan", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Sastrón", [5719] = "Morphaz", [5721] = "Guadañasueños", [5722] = "Hazzas", [5711] = "Ogom el Desdichado", [5710] = "Jammal'an el Profeta", [8443] = "Avatar de Hakkar", [5709] = "Sombra de Eranikus"},
		esMX = {[8311] = "Cresa de baba", [5269] = "Sacerdote Atal'ai", [8318] = "Esclavo Atal'ai", [5263] = "Atal'ai momificado", [8384] = "Rondador de lo profundo", [5226] = "Gusano de la oscuridad", [5228] = "Moco saturado", [5256] = "Guerrero Atal'ai", [5259] = "Médico brujo Atal'ai", [5267] = "Atal'ai sin vida", [5270] = "Comecadáveres Atal'ai", [8319] = "Cría de la Pesadilla", [5291] = "Alascarcha Hakkari", [5277] = "Horrocrusto pesadilla", [5283] = "Errante pesadilla", [5271] = "Caminamuerte Atal'ai", [5273] = "Sumo sacerdote Atal'ai", [5280] = "Verminte pesadilla", [5708] = "Alevín de Hakkar", [5713] = "Gasher", [5714] = "Loh'ro", [5712] = "Zolo", [5715] = "Hukku", [5717] = "Mijan", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Sastrón", [5719] = "Morphaz", [5721] = "Guadañasueños", [5722] = "Hazzas", [5711] = "Ogom el Desdichado", [5710] = "Jammal'an el Profeta", [8443] = "Avatar de Hakkar", [5709] = "Sombra de Eranikus"},
		ptBR = {[8311] = "Verme de Visgo", [5269] = "Sacerdote Atal'ai", [8318] = "Escravo Atal'ai", [5263] = "Atal'ai Mumificado", [8384] = "Tocaieiro do Abismo", [5226] = "Verme do Lodo", [5228] = "Gosma Saturada", [5256] = "Guerreiro Atal'ai", [5259] = "Mandingueiro Atal'ai", [5267] = "Atal'ai Vivo-Morto", [5270] = "Comedor de Cadáver Atal'ai", [8319] = "Dragonete Apavorante", [5291] = "Asa Gélida Hakkari", [5277] = "Escamorte Apavorante", [5283] = "Vagante Apavorante", [5271] = "Mortívago Atal'ai", [5273] = "Sumo Sacerdote Atal'ai", [5280] = "Draconoide Apavorante", [5708] = "Rebento de Hakkar", [5713] = "Talho", [5714] = "Lorro", [5712] = "Zolo", [5715] = "Hukkah", [5717] = "Mirran", [5716] = "Zul'Lor", [8580] = "Atal'alarion", [5720] = "Tecelão", [5719] = "Morphaz", [5721] = "Darquimeros", [5722] = "Hazzas", [5711] = "Ogom, o Patife", [5710] = "Jammal'an, o Profeta", [8443] = "Avatar de Hakkar", [5709] = "Vulto de Erânicos"},
		ruRU = {[8311] = "Склизкая личинка", [5269] = "Жрец племени Атал'ай", [8318] = "Раб племени Атал'ай", [5263] = "Мумифицированный тролль из племени Атал'ай", [8384] = "Глубинный скрытень", [5226] = "Мракочервь", [5228] = "Влажный слизнюк", [5256] = "Воин из племени Атал'ай", [5259] = "Знахарь из племени Атал'ай", [5267] = "Неживой тролль из племени Атал'ай", [5270] = "Трупоед из племени Атал'ай", [8319] = "Дракончик кошмара", [5291] = "Ледокрыл из племени Хаккари", [5277] = "Кошмарный чешуйчатый губитель", [5283] = "Бродяга кошмара", [5271] = "Мертвоброд из племени Атал'ай", [5273] = "Верховный жрец племени Атал'ай", [5280] = "Ужасная драконида", [5708] = "Порождение Хаккара", [5713] = "Ранокол", [5714] = "Лоро", [5712] = "Золо", [5715] = "Хукку", [5717] = "Миджан", [5716] = "Зул'Лор", [8580] = "Атал'аларион", [5720] = "Ткачик", [5719] = "Морфаз", [5721] = "Жнец Снов", [5722] = "Хаззас", [5711] = "Огом Презренный", [5710] = "Джаммал'ан Пророк", [8443] = "Аватара Хаккара", [5709] = "Тень Эраникуса"},
		koKR = {[8311] = "진흙구더기", [5269] = "아탈라이부족 사제", [8318] = "아탈라이부족 노예", [5263] = "미라가 된 아탈라이트롤", [8384] = "지하껍질괴물", [5226] = "진흙미늘벌레", [5228] = "축축한 수액괴물", [5256] = "아탈라이부족 전사", [5259] = "아탈라이부족 의술사", [5267] = "죽지 못하는 아탈라이트롤", [5270] = "아탈라이부족 식인트롤", [8319] = "악몽의 새끼용", [5291] = "학카르 서리날개천둥매", [5277] = "악몽의 맹독전사", [5283] = "떠도는 악몽의 용혈족", [5271] = "아탈라이부족 좀비", [5273] = "아탈라이부족 대사제", [5280] = "악몽의 고룡족", [5708] = "학카르의 피조물", [5713] = "게이셔", [5714] = "로로", [5712] = "졸로", [5715] = "후쿠", [5717] = "마이잔", [5716] = "줄로", [8580] = "아탈알라리온", [5720] = "위버", [5719] = "몰파즈", [5721] = "드림사이드", [5722] = "하자스", [5711] = "비운의 오그옴", [5710] = "예언자 잠말란", [8443] = "학카르의 화신", [5709] = "에라니쿠스의 사령"},
		zhCN = {[8311] = "巨蛆", [5269] = "阿塔莱祭司", [8318] = "阿塔莱奴隶", [5263] = "阿塔莱木乃伊", [8384] = "神庙深渊潜伏者", [5226] = "黑暗虫", [5228] = "深色软泥怪", [5256] = "阿塔莱战士", [5259] = "阿塔莱巫医", [5267] = "阿塔莱行尸", [5270] = "阿塔莱食尸者", [8319] = "噩梦雏龙", [5291] = "哈卡莱霜翼飞蛇", [5277] = "噩梦刃鳞龙人", [5283] = "噩梦游荡者", [5271] = "阿塔莱死亡行者", [5273] = "阿塔莱高阶祭司", [5280] = "噩梦龙族", [5708] = "哈卡的后代", [5713] = "加什尔", [5714] = "洛若尔", [5712] = "祖罗", [5715] = "胡库", [5717] = "米杉", [5716] = "祖罗尔", [8580] = "阿塔拉利恩", [5720] = "德拉维沃尔", [5719] = "摩弗拉斯", [5721] = "德姆塞卡尔", [5722] = "哈扎斯", [5711] = "可悲的奥戈姆", [5710] = "预言者迦玛兰", [8443] = "哈卡的化身", [5709] = "伊兰尼库斯的阴影"},
		zhTW = {[8311] = "巨蛆", [5269] = "阿塔萊祭司", [8318] = "阿塔萊奴隸", [5263] = "阿塔萊木乃伊", [8384] = "神廟深淵潛伏者", [5226] = "黑暗蟲", [5228] = "深色軟泥怪", [5256] = "阿塔萊戰士", [5259] = "阿塔萊巫醫", [5267] = "阿塔萊行屍", [5270] = "阿塔萊食屍者", [8319] = "夢魘幼龍", [5291] = "哈卡萊霜翼飛蛇", [5277] = "夢魘逆鱗龍人", [5283] = "夢魘漫遊者", [5271] = "阿塔萊死亡行者", [5273] = "阿塔萊高階祭司", [5280] = "夢魘龍人", [5708] = "哈卡的後代", [5713] = "加什爾", [5714] = "洛若爾", [5712] = "祖羅", [5715] = "胡庫", [5717] = "米杉", [5716] = "祖羅爾", [8580] = "阿塔拉利恩", [5720] = "德拉維沃爾", [5719] = "摩弗拉斯", [5721] = "德姆塞卡爾", [5722] = "哈札斯", [5711] = "可悲的奧戈姆", [5710] = "『預言者』迦瑪蘭", [8443] = "哈卡的化身", [5709] = "伊蘭尼庫斯的陰影"},
	},
	subs = {
		enUS = {[8580] = "Guardian of the Idol"},
		frFR = {[8580] = "Gardien de l'idole"},
		deDE = {[8580] = "Wächter des Götzen"},
		esES = {[8580] = "Guardián del ídolo"},
		esMX = {[8580] = "Guardián del ídolo"},
		ptBR = {[8580] = "Guardião do Ídolo"},
		ruRU = {[8580] = "Страж идола"},
		koKR = {[8580] = "신상의 수호신"},
		zhCN = {[8580] = "护卫者"},
		zhTW = {[8580] = "衛像者"},
	},
}
