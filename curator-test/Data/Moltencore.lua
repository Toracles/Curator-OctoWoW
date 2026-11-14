-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "moltencore", kind = "dungeon", raid = 2, instance = 409, area = 2717,
	levels = { 60, 60 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 12056, 12057, 12259, 11988, 12118, 12264, 12098, 11982, 12018, 11502 }, final = 11502,
	name = "Molten Core",
	title = { frFR = "Cœur du Magma", deDE = "Geschmolzener Kern", esES = "Núcleo de Magma", esMX = "Núcleo de Magma", ptBR = "Núcleo Derretido", ruRU = "Огненные Недра", koKR = "화산 심장부", zhCN = "熔火之心", zhTW = "熔火之心" },
	tint = { 0.52, 0.18, 0.03 }, glow = { 1.00, 0.67, 0.24 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioMoltencore", pack = "PackMoltencore", set = "SetMoltencore",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 12099, 1, 4, 0, 60, 60, 5781, 739, false }, -- Firesworn
		{ 11671, 1, 1, 0, 61, 61, 12168, 6819, false }, -- Core Hound
		{ 11666, 1, 4, 0, 61, 62, 1070, 1288, false }, -- Firewalker
		{ 11669, 1, 4, 0, 61, 62, 12190, 0, false }, -- Flame Imp
		{ 11667, 1, 4, 0, 61, 62, 5488, 1288, false }, -- Flameguard
		{ 11665, 1, 4, 0, 61, 62, 12164, 739, false }, -- Lava Annihilator
		{ 12076, 1, 4, 0, 61, 62, 5781, 739, false }, -- Lava Elemental
		{ 12101, 1, 4, 0, 61, 62, 12239, 739, false }, -- Lava Surger
		{ 11661, 1, 7, 0, 62, 62, 12030, 1288, false }, -- Flamewaker
		{ 11672, 2, 1, 0, 62, 62, 11997, 6819, false }, -- Core Rager
		{ 11662, 2, 7, 0, 62, 62, 12030, 1288, false }, -- Flamewaker Priest
		{ 12119, 2, 7, 0, 62, 62, 12030, 1288, false }, -- Flamewaker Protector
		{ 12100, 2, 4, 0, 62, 63, 12163, 739, false }, -- Lava Reaver
		{ 11659, 2, 5, 0, 63, 63, 12162, 3685, false }, -- Molten Destroyer
		{ 11668, 3, 4, 0, 61, 62, 12231, 1288, false }, -- Firelord
		{ 11673, 3, 1, 0, 62, 62, 12189, 6819, false }, -- Ancient Core Hound
		{ 11658, 3, 5, 0, 62, 62, 8269, 3685, false }, -- Molten Giant
		{ 12056, 4, 4, 0, 63, 63, 12129, 1288, false }, -- Baron Geddon
		{ 12057, 4, 4, 0, 63, 63, 12110, 739, false }, -- Garr
		{ 12259, 4, 7, 0, 63, 63, 13030, 1288, false }, -- Gehennas
		{ 11988, 4, 5, 0, 63, 63, 11986, 3685, false }, -- Golemagg the Incinerator
		{ 12118, 4, 7, 0, 63, 63, 13031, 1288, false }, -- Lucifron
		{ 12264, 4, 7, 0, 63, 63, 13032, 1288, false }, -- Shazzrah
		{ 12098, 4, 7, 0, 63, 63, 13030, 1288, false }, -- Sulfuron Harbinger
		{ 11982, 5, 1, 0, 63, 63, 10193, 6819, false }, -- Magmadar
		{ 12018, 5, 7, 0, 63, 63, 12029, 1288, false }, -- Majordomo Executus
		{ 11502, 6, 4, 0, 63, 63, 11121, 7554, false }, -- Ragnaros
	},
	names = {
		enUS = {[12099] = "Firesworn", [11671] = "Core Hound", [11666] = "Firewalker", [11669] = "Flame Imp", [11667] = "Flameguard", [11665] = "Lava Annihilator", [12076] = "Lava Elemental", [12101] = "Lava Surger", [11661] = "Flamewaker", [11672] = "Core Rager", [11662] = "Flamewaker Priest", [12119] = "Flamewaker Protector", [12100] = "Lava Reaver", [11659] = "Molten Destroyer", [11668] = "Firelord", [11673] = "Ancient Core Hound", [11658] = "Molten Giant", [12056] = "Baron Geddon", [12057] = "Garr", [12259] = "Gehennas", [11988] = "Golemagg the Incinerator", [12118] = "Lucifron", [12264] = "Shazzrah", [12098] = "Sulfuron Harbinger", [11982] = "Magmadar", [12018] = "Majordomo Executus", [11502] = "Ragnaros"},
		frFR = {[12099] = "Lige du feu", [11671] = "Chien du Magma", [11666] = "Marchefeu", [11669] = "Diablotin des flammes", [11667] = "Garde des flammes", [11665] = "Annihilateur de lave", [12076] = "Elémentaire de lave", [12101] = "Surgisseur de lave", [11661] = "Attise-flammes", [11672] = "Rageur du Magma", [11662] = "Prêtre Attise-flammes", [12119] = "Protecteur Attise-flammes", [12100] = "Ravageur de lave", [11659] = "Destructeur de lave", [11668] = "Seigneur du feu", [11673] = "Ancien chien du Magma", [11658] = "Géant de lave", [12056] = "Baron Geddon", [12057] = "Garr", [12259] = "Gehennas", [11988] = "Golemagg l'Incinérateur", [12118] = "Lucifron", [12264] = "Shazzrah", [12098] = "Messager de Sulfuron", [11982] = "Magmadar", [12018] = "Chambellan Executus", [11502] = "Ragnaros"},
		deDE = {[12099] = "Feueranbeter", [11671] = "Kernhund", [11666] = "Feuergänger", [11669] = "Flammenwichtel", [11667] = "Flammenwächter", [11665] = "Lavavernichter", [12076] = "Lavaelementar", [12101] = "Lavawoger", [11661] = "Feuerschuppe", [11672] = "Kernwüterich", [11662] = "Feuerschuppenpriester", [12119] = "Feuerschuppenbeschützer", [12100] = "Lavahäscher", [11659] = "Geschmolzener Zerstörer", [11668] = "Feuerlord", [11673] = "Uralter Kernhund", [11658] = "Geschmolzener Riese", [12056] = "Baron Geddon", [12057] = "Garr", [12259] = "Gehennas", [11988] = "Golemagg der Verbrenner", [12118] = "Lucifron", [12264] = "Shazzrah", [12098] = "Sulfuronherold", [11982] = "Magmadar", [12018] = "Majordomus Executus", [11502] = "Ragnaros"},
		esES = {[12099] = "Jurafuego", [11671] = "Can del Núcleo", [11666] = "Caminafuego", [11669] = "Diablillo de llamas", [11667] = "Guardia de llamas", [11665] = "Aniquilador de lava", [12076] = "Elemental de lava", [12101] = "Marea de lava", [11661] = "Caminallamas", [11672] = "Enfurecedor del Núcleo", [11662] = "Sacerdote Caminallamas", [12119] = "Protector Caminallamas", [12100] = "Atracador de lava", [11659] = "Destructor de magma", [11668] = "Señor del Fuego", [11673] = "Can del Núcleo anciano", [11658] = "Gigante fundido", [12056] = "Barón Geddon", [12057] = "Garr", [12259] = "Gehennas", [11988] = "Golemagg el Incinerador", [12118] = "Lucifron", [12264] = "Shazzrah", [12098] = "Sulfuron Presagista", [11982] = "Magmadar", [12018] = "Mayordomo Executus", [11502] = "Ragnaros"},
		esMX = {[12099] = "Jurafuego", [11671] = "Can del Núcleo", [11666] = "Caminafuego", [11669] = "Diablillo de llamas", [11667] = "Guardia de llamas", [11665] = "Aniquilador de lava", [12076] = "Elemental de lava", [12101] = "Marea de lava", [11661] = "Caminallamas", [11672] = "Enfurecedor del Núcleo", [11662] = "Sacerdote Caminallamas", [12119] = "Protector Caminallamas", [12100] = "Atracador de lava", [11659] = "Destructor de magma", [11668] = "Señor del Fuego", [11673] = "Can del Núcleo anciano", [11658] = "Gigante fundido", [12056] = "Barón Geddon", [12057] = "Garr", [12259] = "Gehennas", [11988] = "Golemagg el Incinerador", [12118] = "Lucifron", [12264] = "Shazzrah", [12098] = "Presagista de Sulfuron", [11982] = "Magmadar", [12018] = "Mayordomo Executus", [11502] = "Ragnaros"},
		ptBR = {[12099] = "Devoto do Fogo", [11671] = "Cão-magma", [11666] = "Andarilho Ígneo", [11669] = "Diabrete das Chamas", [11667] = "Guardião das Chamas", [11665] = "Extirpador de Lava", [12076] = "Elemental da Lava", [12101] = "Irrompedor de Lava", [11661] = "Ardilante", [11672] = "Furiante do Núcleo", [11662] = "Sacerdote Ardilante", [12119] = "Protetor Ardilante", [12100] = "Aniquilador de Lava", [11659] = "Destruidor Derretido", [11668] = "Senhor do Fogo", [11673] = "Cão-magma Ancião", [11658] = "Gigante Derretido", [12056] = "Barão Geddon", [12057] = "Garr", [12259] = "Geena", [11988] = "Golemagg, o Incinerador", [12118] = "Lúcifron", [12264] = "Shazzrah", [12098] = "Emissário de Sulfuron", [11982] = "Magmadar", [12018] = "Senescal Executus", [11502] = "Ragnaros"},
		ruRU = {[12099] = "Огнекамень", [11671] = "Пес Недр", [11666] = "Огнеход", [11669] = "Огненный бес", [11667] = "Пламестраж", [11665] = "Лавовый уничтожитель", [12076] = "Элементаль лавы", [12101] = "Лавовый волноплеск", [11661] = "Поджигатель", [11672] = "Яростень Недр", [11662] = "Поджигатель-жрец", [12119] = "Заступник-поджигатель", [12100] = "Лавовый разоритель", [11659] = "Разрушитель из недр", [11668] = "Повелитель огня", [11673] = "Древняя гончая бездны", [11658] = "Оплавленный великан", [12056] = "Барон Геддон", [12057] = "Гарр", [12259] = "Гееннас", [11988] = "Големагг Испепелитель", [12118] = "Люцифрон", [12264] = "Шаззрах", [12098] = "Предвестник Сульфурон", [11982] = "Магмадар", [12018] = "Мажордом Экзекутус", [11502] = "Рагнарос"},
		koKR = {[12099] = "불꽃의 추종자", [11671] = "심장부 사냥개", [11666] = "불꽃 정령", [11669] = "화염 임프", [11667] = "화염의수호자", [11665] = "용암의 파괴자", [12076] = "용암 정령", [12101] = "굽이치는 용암 정령", [11661] = "불꽃꼬리일족 전사", [11672] = "흉포한 심장부 사냥개", [11662] = "불꽃꼬리일족 사제", [12119] = "불꽃꼬리일족 수호병", [12100] = "맹위의 용암 정령", [11659] = "파괴의 용암거인", [11668] = "불의군주", [11673] = "고대의 심장부 사냥개", [11658] = "용암거인", [12056] = "남작 게돈", [12057] = "가르", [12259] = "게헨나스", [11988] = "초열의 골레마그", [12118] = "루시프론", [12264] = "샤즈라", [12098] = "설퍼론 사자", [11982] = "마그마다르", [12018] = "청지기 이그젝큐투스", [11502] = "라그나로스"},
		zhCN = {[12099] = "火誓者", [11671] = "熔火恶犬", [11666] = "火焰行者", [11669] = "烈焰小鬼", [11667] = "烈焰守卫", [11665] = "熔岩歼灭者", [12076] = "熔岩元素", [12101] = "熔岩奔腾者", [11661] = "烈焰行者", [11672] = "熔火怒犬", [11662] = "烈焰行者祭司", [12119] = "烈焰行者护卫", [12100] = "熔岩掠夺者", [11659] = "熔核摧毁者", [11668] = "火焰之王", [11673] = "上古熔火恶犬", [11658] = "熔核巨人", [12056] = "迦顿男爵", [12057] = "加尔", [12259] = "基赫纳斯", [11988] = "焚化者古雷曼格", [12118] = "鲁西弗隆", [12264] = "沙斯拉尔", [12098] = "萨弗隆先驱者", [11982] = "玛格曼达", [12018] = "管理者埃克索图斯", [11502] = "拉格纳罗斯"},
		zhTW = {[12099] = "火誓者", [11671] = "熔核犬", [11666] = "火焰行者", [11669] = "烈焰小鬼", [11667] = "烈焰守衛", [11665] = "熔岩殲滅者", [12076] = "熔岩元素", [12101] = "熔岩奔騰者", [11661] = "烈焰行者", [11672] = "熔核怒犬", [11662] = "烈焰行者祭司", [12119] = "烈焰行者保衛者", [12100] = "熔岩搶奪者", [11659] = "熔核摧毀者", [11668] = "火焰之王", [11673] = "上古熔核犬", [11658] = "熔核巨人", [12056] = "迦頓男爵", [12057] = "加爾", [12259] = "基赫納斯", [11988] = "『焚化者』古雷曼格", [12118] = "魯西弗隆", [12264] = "沙斯拉爾", [12098] = "薩弗隆先驅者", [11982] = "瑪格曼達", [12018] = "管理者埃克索圖斯", [11502] = "拉格納羅斯"},
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
