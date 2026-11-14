-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "stockade", kind = "dungeon", instance = 34, area = 717,
	levels = { 24, 32 }, side = "A",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 1663, 1666, 1717, 1696, 1716 }, final = 1716,
	name = "The Stockade",
	title = { frFR = "La Prison", deDE = "Das Verlies", esES = "Las Mazmorras", esMX = "Las Mazmorras", ptBR = "O Cárcere", ruRU = "Тюрьма", koKR = "스톰윈드 지하감옥", zhCN = "监狱" },
	tint = { 0.26, 0.24, 0.22 }, glow = { 1.00, 0.70, 0.40 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioStockade", pack = "PackStockade", set = "SetStockade",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 1707, 1, 7, 0, 23, 23, 2144, 1328, false }, -- Defias Captive
		{ 1706, 1, 7, 0, 23, 24, 2148, 1328, false }, -- Defias Prisoner
		{ 1708, 1, 7, 0, 24, 25, 2146, 1328, false }, -- Defias Inmate
		{ 1711, 2, 7, 0, 24, 25, 2145, 1328, false }, -- Defias Convict
		{ 1715, 2, 7, 0, 25, 26, 2147, 1328, false }, -- Defias Insurgent
		{ 1720, 3, 7, 0, 26, 26, 2142, 1352, false }, -- Bruegal Ironknuckle
		{ 1663, 4, 7, 0, 26, 26, 2149, 1328, false }, -- Dextren Ward
		{ 1666, 4, 7, 0, 27, 27, 825, 1352, false }, -- Kam Deepfury
		{ 1717, 4, 7, 0, 28, 28, 3250, 402, false }, -- Hamhock
		{ 1696, 5, 7, 0, 24, 24, 517, 1346, false }, -- Targorr the Dread
		{ 1716, 6, 7, 0, 29, 29, 1621, 1328, false }, -- Bazil Thredd
	},
	names = {
		enUS = {[1707] = "Defias Captive", [1706] = "Defias Prisoner", [1708] = "Defias Inmate", [1711] = "Defias Convict", [1715] = "Defias Insurgent", [1720] = "Bruegal Ironknuckle", [1663] = "Dextren Ward", [1666] = "Kam Deepfury", [1717] = "Hamhock", [1696] = "Targorr the Dread", [1716] = "Bazil Thredd"},
		frFR = {[1707] = "Captif défias", [1706] = "Prisonnier défias", [1708] = "Interné défias", [1711] = "Détenu défias", [1715] = "Insurgé défias", [1720] = "Bruegal Ironknuckle", [1663] = "Dextren Ward", [1666] = "Kam Deepfury", [1717] = "Hamhock", [1696] = "Targorr le Terrifiant", [1716] = "Bazil Thredd"},
		deDE = {[1707] = "Inhaftierter Defias", [1706] = "Gefangener Defias", [1708] = "Verurteilter Defias", [1711] = "Eingekerkerter Defias", [1715] = "Aufrührer der Defias", [1720] = "Bruegal Eisenfaust", [1663] = "Dextren Ward", [1666] = "Kam Deepfury", [1717] = "Hamhock", [1696] = "Targorr der Schreckliche", [1716] = "Bazil Thredd"},
		esES = {[1707] = "Cautivo Defias", [1706] = "Prisionero Defias", [1708] = "Recluso Defias", [1711] = "Presidiario Defias", [1715] = "Insurgente Defias", [1720] = "Bruegal Nudoferro", [1663] = "Dextren Tutor", [1666] = "Kam Furiahonda", [1717] = "Hamhock", [1696] = "Targor el Pavoroso", [1716] = "Bazil Thredd"},
		esMX = {[1707] = "Cautivo Defias", [1706] = "Prisionero Defias", [1708] = "Recluso Defias", [1711] = "Presidiario Defias", [1715] = "Insurgente Defias", [1720] = "Bruegal Nudoferro", [1663] = "Dextren Tutor", [1666] = "Kam Furiahonda", [1717] = "Hamhock", [1696] = "Targor el Pavoroso", [1716] = "Bazil Thredd"},
		ptBR = {[1707] = "Cativo Défias", [1706] = "Prisioneiro Défias", [1708] = "Recluso Défias", [1711] = "Condenado Défias", [1715] = "Insurgente Défias", [1720] = "Bruegal Ferroque", [1663] = "Flávio Lúcio", [1666] = "Kam Fundafúria", [1717] = "Ramoque", [1696] = "Targorr, o Horror", [1716] = "Basílio Taborda"},
		ruRU = {[1707] = "Пленник из Братства Справедливости", [1706] = "Узник из Братства Справедливости", [1708] = "Заключенный из Братства Справедливости", [1711] = "Каторжник из Братства Справедливости", [1715] = "Мятежник из Братства Справедливости", [1720] = "Бругал Железный Кулак", [1663] = "Декстрен Вард", [1666] = "Кам Гневливый", [1717] = "Хрупконог", [1696] = "Таргорр Ужасный", [1716] = "Базиль Тредд"},
		koKR = {[1707] = "데피아즈단 죄수", [1706] = "데피아즈단 복역수", [1708] = "데피아즈단 전과자", [1711] = "데피아즈단 무기징역수", [1715] = "데피아즈단 반역자", [1720] = "브루갈 아이언너클", [1663] = "덱스트렌 워드", [1666] = "캄 딥퓨리", [1717] = "햄혹", [1696] = "흉악범 타고르", [1716] = "바질 스레드"},
		zhCN = {[1707] = "迪菲亚俘虏", [1706] = "迪菲亚囚徒", [1708] = "迪菲亚狱友", [1711] = "迪菲亚罪犯", [1715] = "迪菲亚叛军", [1720] = "布鲁高·铁拳", [1663] = "迪克斯特·瓦德", [1666] = "卡姆·深怒", [1717] = "哈姆霍克", [1696] = "可怕的塔格尔", [1716] = "巴基尔·斯瑞德"},
		zhTW = {[1707] = "迪菲亞俘虜", [1706] = "迪菲亞囚犯", [1708] = "迪菲亞獄友", [1711] = "迪菲亞罪犯", [1715] = "迪菲亞叛軍", [1720] = "布魯戈·艾爾克納寇", [1663] = "迪克斯特·瓦德", [1666] = "卡姆·深怒", [1717] = "哈姆霍克", [1696] = "可怕的塔高爾", [1716] = "巴基爾·斯瑞德"},
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
