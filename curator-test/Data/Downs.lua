-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "downs", kind = "dungeon", instance = 129, area = 722,
	levels = { 37, 46 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 7357, 8567, 7356, 7355, 7358 }, final = 7358,
	name = "Razorfen Downs",
	title = { frFR = "Souilles de Tranchebauge", deDE = "Die Hügel von Razorfen", esES = "Zahúrda Rajacieno", esMX = "Zahúrda Rajacieno", ptBR = "Urzal dos Mortos", ruRU = "Курганы Иглошкурых", koKR = "가시덩굴 구릉", zhCN = "剃刀高地" },
	tint = { 0.31, 0.21, 0.15 }, glow = { 0.88, 0.75, 0.59 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioDowns", pack = "PackDowns", set = "SetDowns",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 8767, 1, 7, 0, 30, 30, 11573, 402, false }, -- Sah'rhee
		{ 7333, 1, 6, 0, 34, 34, 6121, 379, false }, -- Withered Battle Boar
		{ 7343, 1, 6, 0, 35, 35, 7550, 1016, false }, -- Splinterbone Skeleton
		{ 7329, 1, 6, 0, 35, 36, 11383, 1181, false }, -- Withered Quilguard
		{ 7328, 1, 6, 0, 35, 36, 11384, 1181, false }, -- Withered Reaver
		{ 7337, 1, 7, 0, 36, 37, 11381, 1181, false }, -- Death's Head Necromancer
		{ 7334, 1, 6, 0, 37, 37, 6122, 379, false }, -- Battle Boar Horror
		{ 7341, 1, 6, 0, 37, 38, 9783, 1016, false }, -- Skeletal Frostweaver
		{ 7344, 1, 6, 0, 37, 38, 5231, 1016, false }, -- Splinterbone Warrior
		{ 7346, 1, 6, 0, 38, 39, 7848, 1016, false }, -- Splinterbone Centurion
		{ 8516, 2, 7, 0, 36, 36, 7851, 5971, true }, -- Belnistrasz
		{ 8696, 2, 7, 0, 36, 36, 8029, 5974, true }, -- Henry Stern
		{ 7352, 2, 6, 0, 37, 38, 146, 3417, false }, -- Frozen Soul
		{ 7348, 2, 6, 0, 37, 38, 1065, 409, false }, -- Thorn Eater Ghoul
		{ 7347, 2, 6, 0, 38, 39, 1065, 409, false }, -- Boneflayer Ghoul
		{ 7353, 2, 6, 0, 39, 40, 146, 3417, false }, -- Freezing Spirit
		{ 7342, 2, 6, 0, 39, 40, 1245, 2517, false }, -- Skeletal Summoner
		{ 7345, 2, 6, 0, 39, 40, 7847, 1016, false }, -- Splinterbone Captain
		{ 7354, 3, 7, 0, 40, 40, 11382, 1181, false }, -- Ragglesnout
		{ 7357, 4, 6, 0, 39, 39, 8055, 1016, false }, -- Mordresh Fire Eye
		{ 8567, 4, 6, 0, 40, 40, 7864, 1446, false }, -- Glutton
		{ 7356, 4, 7, 0, 40, 40, 6124, 1181, false }, -- Plaguemaw the Rotting
		{ 7355, 5, 6, 0, 40, 40, 7845, 3346, false }, -- Tuten'kash
		{ 7358, 6, 6, 0, 41, 41, 7971, 5800, false }, -- Amnennar the Coldbringer
	},
	names = {
		enUS = {[8767] = "Sah'rhee", [7333] = "Withered Battle Boar", [7343] = "Splinterbone Skeleton", [7329] = "Withered Quilguard", [7328] = "Withered Reaver", [7337] = "Death's Head Necromancer", [7334] = "Battle Boar Horror", [7341] = "Skeletal Frostweaver", [7344] = "Splinterbone Warrior", [7346] = "Splinterbone Centurion", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Frozen Soul", [7348] = "Thorn Eater Ghoul", [7347] = "Boneflayer Ghoul", [7353] = "Freezing Spirit", [7342] = "Skeletal Summoner", [7345] = "Splinterbone Captain", [7354] = "Ragglesnout", [7357] = "Mordresh Fire Eye", [8567] = "Glutton", [7356] = "Plaguemaw the Rotting", [7355] = "Tuten'kash", [7358] = "Amnennar the Coldbringer"},
		frFR = {[8767] = "Sah'rhee", [7333] = "Sanglier de guerre corrompu", [7343] = "Squelette Os-brisés", [7329] = "Garde-huran flétri", [7328] = "Ravageur flétri", [7337] = "Nécromancienne de la Tête de Mort", [7334] = "Horreur sanglier de guerre", [7341] = "Tisseur de givre squelettique", [7344] = "Guerrier Os-brisés", [7346] = "Centurion Os-brisés", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Ame glacée", [7348] = "Goule des épines", [7347] = "Goule Ecorcheuse-d'os", [7353] = "Esprit glacial", [7342] = "Invocateur squelettique", [7345] = "Capitaine Os-brisés", [7354] = "Groinfendu", [7357] = "Mordresh Oeil-de-feu", [8567] = "Glouton", [7356] = "Pestegueule le Pourrissant", [7355] = "Tuten'kash", [7358] = "Amnennar le Porte-froid"},
		deDE = {[8767] = "Sah'rhee", [7333] = "Siechender Kampfeber", [7343] = "Splitterknochenskelett", [7329] = "Siechende Stachelwache", [7328] = "Siechender Häscher", [7337] = "Nekromant der Totenköpfe", [7334] = "Kampfeberschrecken", [7341] = "Skelettfrostwirker", [7344] = "Splitterknochenkrieger", [7346] = "Splitterknochenzenturio", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Eisseele", [7348] = "Dornenfresserghul", [7347] = "Knochenschinderghul", [7353] = "Eisgeist", [7342] = "Skelettbeschwörer", [7345] = "Splitterknochencaptain", [7354] = "Struppmähne", [7357] = "Mordresh Feuerauge", [8567] = "Nimmersatt", [7356] = "Plaguemaw der Faulende", [7355] = "Tuten'kash", [7358] = "Amnennar der Kältebringer"},
		esES = {[8767] = "Sah'rhee", [7333] = "Jabaguerrero marchito", [7343] = "Esqueleto Astillóseo", [7329] = "Jabaguardia marchito", [7328] = "Atracador marchito", [7337] = "Nigromante Caramuerte", [7334] = "Horror jabaguerrero", [7341] = "Tejescarcha esquelético", [7344] = "Guerrero Astillóseo", [7346] = "Centurión Astillóseo", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Alma gélida", [7348] = "Necrófago Comespinas", [7347] = "Necrófago Deshuesador", [7353] = "Espíritu helado", [7342] = "Invocador esquelético", [7345] = "Capitán Astillóseo", [7354] = "Morrandrajos", [7357] = "Mordresh Ojo de Fuego", [8567] = "Glotón", [7356] = "Fauzpeste el Putrefacto", [7355] = "Tuten'kash", [7358] = "Amnennar el Gélido"},
		esMX = {[8767] = "Sah'rhee", [7333] = "Jabaguerrero marchito", [7343] = "Esqueleto Astillóseo", [7329] = "Jabaguardia marchito", [7328] = "Atracador marchito", [7337] = "Nigromante Caramuerte", [7334] = "Horror jabaguerrero", [7341] = "Tejescarcha esquelético", [7344] = "Guerrero Astillóseo", [7346] = "Centurión Astillóseo", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Alma gélida", [7348] = "Necrófago Comespinas", [7347] = "Necrófago Deshuesador", [7353] = "Espíritu helado", [7342] = "Invocador esquelético", [7345] = "Capitán Astillóseo", [7354] = "Morrandrajos", [7357] = "Mordresh Ojo de Fuego", [8567] = "Glotón", [7356] = "Fauzpeste el Putrefacto", [7355] = "Tuten'kash", [7358] = "Amnennar el Gélido"},
		ptBR = {[8767] = "Foi'maul", [7333] = "Javali de Batalha Dessecado", [7343] = "Esqueleto Racha-osso", [7329] = "Guardatusco Dessecado", [7328] = "Ladratusco Dessecado", [7337] = "Necromante da Cabeça da Morte", [7334] = "Javali de Batalha Horrendo", [7341] = "Tecegelo Descarnado", [7344] = "Guerreiro Racha-osso", [7346] = "Centurião Racha-osso", [8516] = "Belnistrasz", [8696] = "Henry Stern", [7352] = "Alma Congelada", [7348] = "Carniçal Comespinho", [7347] = "Carniçal Quebrossos", [7353] = "Espírito Congelante", [7342] = "Evocador Descarnado", [7345] = "Capitão Racha-osso", [7354] = "Trombarrão", [7357] = "Mordresh Olho-de-Fogo", [8567] = "Glutão", [7356] = "Pragorja, o Podre", [7355] = "Tutan'kash", [7358] = "Amnennar, o Frigífero"},
		ruRU = {[8767] = "Сах-ри", [7333] = "Иссохший боевой кабан", [7343] = "Скелет-костещеп", [7329] = "Иссохший свиностраж", [7328] = "Иссохший разоритель", [7337] = "Некромант из племени Мертвой Головы", [7334] = "Боевой жутесвин", [7341] = "Скелет-ледоплет", [7344] = "Воин-костещеп", [7346] = "Центурион-костещеп", [8516] = "Белнистраз", [8696] = "Генри Штерн", [7352] = "Хладная душа", [7348] = "Вурдалак-шипоед", [7347] = "Вурдалак-живодер", [7353] = "Леденящий дух", [7342] = "Скелет-призыватель", [7345] = "Капитан-костещеп", [7354] = "Круглорыл", [7357] = "Мордреш Огненный Глаз", [8567] = "Обжора", [7356] = "Чумобрюх Гнилой", [7355] = "Тутен'каш", [7358] = "Амненнар Хладовей"},
		koKR = {[8767] = "사르히", [7333] = "썩어버린 전투멧돼지", [7343] = "가시해골 병사", [7329] = "썩어버린 가시경비병", [7328] = "썩어버린 도끼전투병", [7337] = "죽음의 머리교 강령술사", [7334] = "공포의 전투멧돼지", [7341] = "해골 냉기술사", [7344] = "가시해골 전사", [7346] = "가시해골 백인대장", [8516] = "벨리스트라즈", [8696] = "헨리 스턴", [7352] = "얼어붙은 영혼", [7348] = "가시먹이 구울", [7347] = "강철손톱 구울", [7353] = "얼어죽은 유령", [7342] = "해골 소환사", [7345] = "가시해골 대장", [7354] = "너덜주둥이", [7357] = "불꽃눈 모드레쉬", [8567] = "게걸먹보", [7356] = "썩어가는 역병아귀", [7355] = "투텐카쉬", [7358] = "혹한의 암네나르"},
		zhCN = {[8767] = "萨哈斯", [7333] = "枯萎战斗野猪", [7343] = "碎骨骷髅", [7329] = "枯萎野猪人守卫", [7328] = "枯萎掠夺者", [7337] = "亡首通灵师", [7334] = "恐怖战斗野猪", [7341] = "骷髅冰霜法师", [7344] = "碎骨战士", [7346] = "碎骨百夫长", [8516] = "奔尼斯特拉兹", [8696] = "亨利·斯特恩", [7352] = "冰冻之魂", [7348] = "噬棘食尸鬼", [7347] = "嚼骨食尸鬼", [7353] = "寒冰之灵", [7342] = "骷髅召唤者", [7345] = "碎骨统帅", [7354] = "拉戈斯诺特", [7357] = "火眼莫德雷斯", [8567] = "暴食者", [7356] = "腐烂的普雷莫尔", [7355] = "图特卡什", [7358] = "寒冰之王亚门纳尔"},
		zhTW = {[8767] = "薩哈斯", [7333] = "憔悴的戰鬥野豬", [7343] = "碎骨骷髏", [7329] = "憔悴的野豬人守衛", [7328] = "憔悴的搶奪者", [7337] = "亡首死靈法師", [7334] = "恐怖戰鬥野豬", [7341] = "骷髏冰霜法師", [7344] = "碎骨戰士", [7346] = "碎骨百夫長", [8516] = "貝尼斯特拉茲", [8696] = "亨利·斯特恩", [7352] = "冰凍之魂", [7348] = "噬棘食屍鬼", [7347] = "嚼骨食屍鬼", [7353] = "寒冰之靈", [7342] = "骷髏召喚者", [7345] = "碎骨統帥", [7354] = "拉戈斯諾特", [7357] = "火眼莫德雷斯", [8567] = "暴食者", [7356] = "腐爛的普雷莫爾", [7355] = "圖特卡什", [7358] = "『寒冰使者』亞門納爾"},
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
