-- Spells: the client data of WoW Forever (1.60.1.70245). Creatures and names: QuestieDB (Forever build); the figures of
-- another time of the game: their names in each language of the game. Pictures: the collection of Clément Hudson.
local _, ns = "Curator", CuratorOctoFull
ns.Crates = ns.Crates or {}

-- (1.14.0) The case of the Paladin Collection, its first edition (UI/Crate.lua, CrateItems.lua). (1.14.0, the Paladin
-- collection redone by its author: 22 cards, each its picture over all of the card, in the frames of the Silver Hand.)
ns.Crates.paladin1 = {
	key = "paladin1", class = "PALADIN",
	-- its name (Locale114c.lua); short, under a case or a key of the inventory (Locale114n.lua)
	title = "Paladin Collection Case No. 1", short = "Paladin No. 1",
	-- the icon of its keys (UI/CaseInventory.lua)
	keyIcon = "Interface\\Icons\\INV_Misc_Key_04",
	-- its art: the textures of its case (Media/CratePal1Front, Side, Top: UI/CrateBox.lua), the back of its cards
	-- (Media/CrateBackPal1: UI/CrateCard.lua), the room of its case (Media/CrateRoomPal1: the banner of the paladins in
	-- the cathedral of Stormwind, 16:9; how dark it is made under what is shown over it), the style of its cards (the
	-- frames of the Silver Hand: UI/CrateCard.lua, CC.STYLES)
	art = { box = "CratePal1", back = "CrateBackPal1", room = "CrateRoomPal1", roomAspect = 16 / 9, roomDim = 0.28, style = "pal" },
	-- (1.14.0, his word: the words of its case in each language) its textures with words on them in each language of the
	-- game, Media/<name><suffix> (French: the texture itself; Core.lua, ns.CaseTexture): the plaque of its front (PALADIN,
	-- English and German alike), the words and the number of its lid, those of the back of its cards (drawn by
	-- make_crate_pal_loc.py)
	words = {
		CratePal1Front = { esES = "Es", esMX = "Es", ptBR = "Pt", ruRU = "Ru", koKR = "Ko", zhCN = "Cn", zhTW = "Tw" },
		CratePal1Top = { enUS = "En", deDE = "De", esES = "Es", esMX = "Es", ptBR = "Pt", ruRU = "Ru", koKR = "Ko", zhCN = "Cn", zhTW = "Tw" },
		CrateBackPal1 = { enUS = "En", deDE = "De", esES = "Es", esMX = "Es", ptBR = "Pt", ruRU = "Ru", koKR = "Ko", zhCN = "Cn", zhTW = "Tw" },
	},
	-- Rare: the spells of the paladin, one card each (its last rank), its picture: { spell, tree (1 Holy, 2 Protection,
	-- 3 Retribution), the sound of its cast, the sound of what it does (0: none), its English name (while the game does
	-- not know it); pic: its picture (Media/<pic>); tile: the part of it the tiles of the case show (its middle from its
	-- top, how much of its width) }
	spells = {
		{ 25292, 1, 2562, 1430, "Holy Light", pic = "PalArtHolyLight" },
		{ 10310, 1, 2562, 1431, "Lay on Hands", pic = "PalArtLayOnHands" },
		{ 20924, 1, 2562, 3077, "Consecration", pic = "PalArtConsecration", tile = { 0.42 } },
		{ 23214, 1, 2562, 5436, "Summon Charger", pic = "PalArtCharger" },
		{ 1020, 2, 2562, 39, "Divine Shield", pic = "PalArtDivineShield", tile = { 0.42 } },
		{ 10308, 2, 2562, 3329, "Hammer of Justice", pic = "PalArtHammer", tile = { 0.42 } },
		{ 20217, 2, 2562, 1455, "Blessing of Kings", pic = "PalArtKings", tile = { 0.45 } },
		{ 20928, 2, 2562, 0, "Holy Shield", pic = "PalArtHolyShield", tile = { 0.45 } },
		{ 20271, 3, 2562, 1270, "Judgement", pic = "PalArtJudgement" },
		{ 20920, 3, 0, 3314, "Seal of Command", pic = "PalArtCommand", tile = { 0.42 } },
		{ 20066, 3, 2562, 1270, "Repentance", pic = "PalArtRepentance", tile = { 0.36 } },
		{ 10301, 3, 1505, 3322, "Retribution Aura", pic = "PalArtRetribution" },
	},
	-- Restricted: the masters of the paladins of the capitals: { npc, displayID, sound kit, the uiMap of its city }
	masters = {
		{ 928, 1499, 5971, 1453, pic = "PalArtGrayson", tile = { 0.22, 0.7 } }, -- Lord Grayson Shadowbreaker
		{ 5491, 3284, 5971, 1453, pic = "PalArtArthur", tile = { 0.42, 0.8 } }, -- Arthur the Faithful
		{ 5492, 3289, 5983, 1453, pic = "PalArtKatherine", tile = { 0.30, 0.7 } }, -- Katherine the Pure
		{ 5147, 3089, 5910, 1455, pic = "PalArtValgar", tile = { 0.50, 0.7 } }, -- Valgar Highforge
	},
	-- Classified: the great figures of the paladins: { npc, displayID, sound kit (its voice), where (map: a uiMap) };
	-- a figure of another time of the game: a number of its own (from 900001), no creature, a voice of the game
	heroes = {
		{ 900001, nil, 5971, pic = "PalArtTuralyon", tile = { 0.50, 0.7 } }, -- High Exarch Turalyon
		{ 1748, 5566, 5971, map = 1453, pic = "PalArtBolvar", tile = { 0.23, 0.7 } }, -- Highlord Bolvar Fordragon
		{ 900002, nil, 5983, pic = "PalArtLiadrin", tile = { 0.31, 0.7 } }, -- Lady Liadrin
	},
	-- Covert: the prince of Lordaeron, in the streets of Stratholme burning; film: his entrance, the film of the author
	-- (UI/CaseFilm.lua: Media/<file>1 to <atlases>, its images 28 to a texture, 7 across and 4 down, each w x h in a
	-- cell of its width; so many images shown (its black at its end left out: its last image the prince in the street,
	-- as his card shows him), so many a second; into: the part of its last image his card shows, from 0 to 1 across it
	-- and down it; its sound, as it is)
	covert = {
		{ 900003, nil, 5971, pic = "PalArtArthas", tile = { 0.32, 0.7 }, film = { file = "PalFilmArthas", atlases = 25,
			frames = 685, fps = 24, cols = 7, rows = 4, cell = 292, w = 288, h = 512, into = { 0, 0.91, 0.254, 0.979 },
			sound = "PalFilmArthas.ogg" } }, -- Arthas Menethil
	},
	-- Priceless: its own weapons of legend, none of another case (UI/Crate.lua: CR.WEAPONS, their lines): { item, pic: its
	-- picture, all of it, still; shine: its reflections as on a holographic card (Media/<shine>1 to 4: the light from the
	-- left, from the right, from above, from below; UI/CrateCard.lua: CC.Shine); film: its entrance, the film of the
	-- author, as the one of Arthas (its last image his picture, Thunderfury with a little more on its sides: the card
	-- shows its sides drawn on past it, its top cut, Thunderfury its foot drawn on too) }
	priceless = {
		{ 17182, pic = "PalArtSulfuras", shine = "PalShineSulfuras", film = { file = "PalFilmSulfuras", atlases = 22,
			frames = 696, fps = 24, cols = 8, rows = 4, cell = 256, w = 256, h = 512, into = { -0.1543, 1.1553, 0.0723, 1 },
			sound = "PalFilmSulfuras.ogg" } },
		{ 19019, pic = "PalArtThunderfury", shine = "PalShineThunderfury", film = { file = "PalFilmThunderfury", atlases = 26,
			frames = 717, fps = 24, cols = 7, rows = 4, cell = 292, w = 288, h = 512, into = { -0.1386, 1.1728, 0.0347, 1.0808 },
			sound = "PalFilmThunderfury.ogg" } },
	},
	names = {
		enUS = { [928] = "Lord Grayson Shadowbreaker", [5491] = "Arthur the Faithful", [5492] = "Katherine the Pure", [5147] = "Valgar Highforge", [1748] = "Highlord Bolvar Fordragon", [900001] = "High Exarch Turalyon", [900002] = "Lady Liadrin", [900003] = "Arthas Menethil" },
		frFR = { [928] = "Seigneur Grayson Shadowbreaker", [5491] = "Arthur le Fidèle", [5492] = "Katherine la Pure", [5147] = "Valgar Highforge", [1748] = "Généralissime Bolvar Fordragon", [900001] = "Haut exarque Turalyon", [900002] = "Dame Liadrin", [900003] = "Arthas Menethil" },
		deDE = { [928] = "Lord Grayson Shadowbreaker", [5491] = "Arthur der Treue", [5492] = "Katharina die Reine", [5147] = "Valgar Highforge", [1748] = "Hochlord Bolvar Fordragon", [900001] = "Hochexarch Turalyon", [900002] = "Lady Liadrin", [900003] = "Arthas Menethil" },
		esES = { [928] = "Lord Grisillo Quiebrasombras", [5491] = "Arthur el Leal", [5492] = "Katherine la Pura", [5147] = "Valgar Forjalta", [1748] = "Alto Señor Bolvar Fordragon", [900001] = "Alto exarca Turalyon", [900002] = "Lady Liadrin", [900003] = "Arthas Menethil" },
		esMX = { [928] = "Lord Grisillo Quiebrasombras", [5491] = "Arthur el Leal", [5492] = "Katherine la Pura", [5147] = "Valgar Forjalta", [1748] = "Alto señor Bolvar Fordragón", [900001] = "Alto exarca Turalyon", [900002] = "Lady Liadrin", [900003] = "Arthas Menethil" },
		ptBR = { [928] = "Lorde Grayson Quebrassombra", [5491] = "Artur, o Fiel", [5492] = "Katherine, a Pura", [5147] = "Valgar Sumaforja", [1748] = "Grão-lorde Bolvar Fordragon", [900001] = "Alto Exarca Turalyon", [900002] = "Lady Liadrin", [900003] = "Arthas Menethil" },
		ruRU = { [928] = "Лорд Грейсон Тенелом", [5491] = "Артур Верный", [5492] = "Катерина Чистая", [5147] = "Вальгар Высшая Кузня", [1748] = "Верховный лорд Болвар Фордрагон", [900001] = "Верховный экзарх Туралион", [900002] = "Леди Лиадрин", [900003] = "Артас Менетил" },
		koKR = { [928] = "그레이슨 섀도브레이커 경", [5491] = "성기사 아서", [5492] = "성기사 캐서린", [5147] = "발가르 하이포지", [1748] = "대영주 볼바르 폴드라곤", [900001] = "투랄리온", [900002] = "여군주 리아드린", [900003] = "아서스 메네실" },
		zhCN = { [928] = "格雷森·沙东布瑞克公爵", [5491] = "虔诚的亚瑟", [5492] = "纯洁的凯瑟琳", [5147] = "瓦尔加·高炉", [1748] = "伯瓦尔·弗塔根公爵", [900001] = "大主教图拉扬", [900002] = "女伯爵莉亚德琳", [900003] = "阿尔萨斯·米奈希尔" },
		zhTW = { [928] = "格雷森·破影者領主", [5491] = "虔誠的亞瑟", [5492] = "純潔的凱薩琳", [5147] = "瓦爾加·高爐", [1748] = "大領主伯瓦爾·弗塔根", [900001] = "圖拉揚", [900002] = "女伯爵莉亞德琳", [900003] = "阿薩斯·米奈希爾" },
	},
	subs = {
		enUS = { [928] = "Paladin Trainer", [5491] = "Paladin Trainer", [5492] = "Paladin Trainer", [5147] = "Paladin Trainer", [900001] = "Army of the Light", [900002] = "Blood Knights", [900003] = "Prince of Lordaeron" },
		frFR = { [928] = "Maître des paladins", [5491] = "Maître des paladins", [5492] = "Maître des paladins", [5147] = "Maître des paladins", [900001] = "Armée de la Lumière", [900002] = "Chevaliers de sang", [900003] = "Prince de Lordaeron" },
		deDE = { [928] = "Paladinlehrer", [5491] = "Paladinlehrer", [5492] = "Paladinlehrerin", [5147] = "Paladinlehrer", [900001] = "Armee des Lichts", [900002] = "Blutritter", [900003] = "Prinz von Lordaeron" },
		esES = { [928] = "Instructor de paladines", [5491] = "Instructor de paladines", [5492] = "Instructor de paladines", [5147] = "Instructor de paladines", [900001] = "Ejército de la Luz", [900002] = "Caballeros de sangre", [900003] = "Príncipe de Lordaeron" },
		esMX = { [928] = "Instructor de paladines", [5491] = "Instructor de paladines", [5492] = "Instructora de paladines", [5147] = "Instructor de paladines", [900001] = "Ejército de la Luz", [900002] = "Caballeros de sangre", [900003] = "Príncipe de Lordaeron" },
		ptBR = { [928] = "Treinamento de Paladinos", [5491] = "Treinamento de Paladinos", [5492] = "Treinamento de Paladinos", [5147] = "Treinamento de Paladinos", [900001] = "Exército da Luz", [900002] = "Cavaleiros Sangrentos", [900003] = "Príncipe de Lordaeron" },
		ruRU = { [928] = "Наставник паладинов", [5491] = "Наставник паладинов", [5492] = "Наставница паладинов", [5147] = "Наставник паладинов", [900001] = "Армия Света", [900002] = "Рыцари крови", [900003] = "Принц Лордерона" },
		koKR = { [928] = "상급 성기사", [5491] = "상급 성기사", [5492] = "상급 성기사", [5147] = "상급 성기사", [900001] = "빛의 군대", [900002] = "피의 기사단", [900003] = "로데론의 왕자" },
		zhCN = { [928] = "圣骑士训练师", [5491] = "圣骑士训练师", [5492] = "圣骑士训练师", [5147] = "圣骑士训练师", [900001] = "圣光军团", [900002] = "血骑士", [900003] = "洛丹伦王子" },
		zhTW = { [928] = "聖騎士訓練師", [5491] = "聖騎士訓練師", [5492] = "聖騎士訓練師", [5147] = "聖騎士訓練師", [900001] = "聖光軍團", [900002] = "血騎士", [900003] = "羅德隆王子" },
	},
}

-- (its words in each language, for every texture of the addon that shows them: Core.lua, ns.CaseTexture)
ns.CaseWords = ns.CaseWords or {}
for name, langs in pairs(ns.Crates.paladin1.words) do
	ns.CaseWords[name] = langs
end
