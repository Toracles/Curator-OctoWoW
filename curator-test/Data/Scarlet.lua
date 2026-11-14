-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "scarlet", kind = "dungeon", instance = 189, area = 796,
	levels = { 26, 45 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 3983, 4543, 3974, 6487, 4542, 3975, 3976, 3977 }, final = 3977,
	name = "Scarlet Monastery",
	title = { frFR = "Monastère écarlate", deDE = "Das Scharlachrote Kloster", esES = "Monasterio Escarlata", esMX = "Monasterio Escarlata", ptBR = "Monastério Escarlate", ruRU = "Монастырь Алого Ордена", koKR = "붉은십자군 수도원", zhCN = "血色修道院" },
	tint = { 0.40, 0.08, 0.10 }, glow = { 1.00, 0.40, 0.36 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioScarlet", pack = "PackScarlet", set = "SetScarlet",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 4293, 1, 7, 0, 30, 31, 2518, 2937, false }, -- Scarlet Scryer
		{ 4306, 1, 7, 0, 30, 31, 2607, 1328, false }, -- Scarlet Torturer
		{ 6426, 1, 6, 0, 31, 33, 10255, 1473, false }, -- Anguished Dead
		{ 4308, 1, 6, 0, 31, 32, 5430, 3417, false }, -- Unfettered Spirit
		{ 6427, 1, 6, 0, 32, 33, 4629, 3424, false }, -- Haunting Phantasm
		{ 4296, 1, 7, 0, 33, 34, 5726, 1328, false }, -- Scarlet Adept
		{ 4287, 1, 7, 0, 33, 34, 2463, 1328, false }, -- Scarlet Gallant
		{ 4304, 1, 1, 25, 33, 33, 2709, 2511, false }, -- Scarlet Tracking Hound
		{ 4288, 1, 7, 0, 34, 35, 2497, 2937, false }, -- Scarlet Beastmaster
		{ 4299, 1, 7, 0, 34, 35, 2501, 2937, false }, -- Scarlet Chaplain
		{ 4291, 1, 7, 0, 34, 35, 2507, 1328, false }, -- Scarlet Diviner
		{ 4297, 1, 7, 0, 35, 36, 2503, 2937, false }, -- Scarlet Conjuror
		{ 4540, 1, 7, 0, 35, 36, 2603, 1328, false }, -- Scarlet Monk
		{ 4286, 1, 7, 0, 35, 36, 2522, 1328, false }, -- Scarlet Soldier
		{ 4289, 1, 7, 0, 36, 37, 2509, 2937, false }, -- Scarlet Evoker
		{ 4290, 2, 7, 0, 36, 37, 2511, 1328, false }, -- Scarlet Guardsman
		{ 4292, 2, 7, 0, 36, 37, 2476, 2937, false }, -- Scarlet Protector
		{ 4298, 2, 7, 0, 37, 38, 2462, 1328, false }, -- Scarlet Defender
		{ 4295, 2, 7, 0, 37, 38, 2514, 1328, false }, -- Scarlet Myrmidon
		{ 4294, 2, 7, 0, 37, 38, 2524, 1328, false }, -- Scarlet Sorcerer
		{ 4301, 2, 7, 0, 38, 39, 2499, 1328, false }, -- Scarlet Centurion
		{ 4300, 2, 7, 0, 38, 39, 2525, 2937, false }, -- Scarlet Wizard
		{ 4303, 2, 7, 0, 39, 40, 2492, 1328, false }, -- Scarlet Abbot
		{ 4302, 2, 7, 0, 39, 40, 2460, 2937, false }, -- Scarlet Champion
		{ 3981, 3, 7, 0, 8, 8, 2046, 6036, true }, -- Vorrel Sengutz
		{ 6490, 3, 6, 0, 33, 33, 5534, 1328, false }, -- Azshir the Sleepless
		{ 6488, 3, 6, 0, 33, 33, 5230, 1371, false }, -- Fallen Champion
		{ 6489, 3, 6, 0, 33, 33, 5231, 1016, false }, -- Ironspine
		{ 3983, 4, 7, 0, 32, 32, 2044, 1328, false }, -- Interrogator Vishas
		{ 4543, 4, 6, 0, 34, 34, 11396, 2517, false }, -- Bloodmage Thalnos
		{ 3974, 4, 7, 0, 34, 34, 2040, 1328, false }, -- Houndmaster Loksey
		{ 6487, 4, 7, 0, 37, 37, 5266, 1328, false }, -- Arcanist Doan
		{ 4542, 4, 6, 0, 40, 40, 2605, 1371, false }, -- High Inquisitor Fairbanks
		{ 3975, 5, 7, 0, 40, 40, 2041, 1328, false }, -- Herod
		{ 3976, 5, 7, 0, 42, 42, 2042, 1328, false }, -- Scarlet Commander Mograine
		{ 3977, 6, 7, 0, 42, 42, 2043, 2937, false }, -- High Inquisitor Whitemane
	},
	names = {
		enUS = {[4293] = "Scarlet Scryer", [4306] = "Scarlet Torturer", [6426] = "Anguished Dead", [4308] = "Unfettered Spirit", [6427] = "Haunting Phantasm", [4296] = "Scarlet Adept", [4287] = "Scarlet Gallant", [4304] = "Scarlet Tracking Hound", [4288] = "Scarlet Beastmaster", [4299] = "Scarlet Chaplain", [4291] = "Scarlet Diviner", [4297] = "Scarlet Conjuror", [4540] = "Scarlet Monk", [4286] = "Scarlet Soldier", [4289] = "Scarlet Evoker", [4290] = "Scarlet Guardsman", [4292] = "Scarlet Protector", [4298] = "Scarlet Defender", [4295] = "Scarlet Myrmidon", [4294] = "Scarlet Sorcerer", [4301] = "Scarlet Centurion", [4300] = "Scarlet Wizard", [4303] = "Scarlet Abbot", [4302] = "Scarlet Champion", [3981] = "Vorrel Sengutz", [6490] = "Azshir the Sleepless", [6488] = "Fallen Champion", [6489] = "Ironspine", [3983] = "Interrogator Vishas", [4543] = "Bloodmage Thalnos", [3974] = "Houndmaster Loksey", [6487] = "Arcanist Doan", [4542] = "High Inquisitor Fairbanks", [3975] = "Herod", [3976] = "Scarlet Commander Mograine", [3977] = "High Inquisitor Whitemane"},
		frFR = {[4293] = "Clairvoyant écarlate", [4306] = "Tortionnaire écarlate", [6426] = "Mort angoissé", [4308] = "Esprit libéré", [6427] = "Illusion spectrale", [4296] = "Adepte écarlate", [4287] = "Vaillant écarlate", [4304] = "Chien de chasse écarlate", [4288] = "Belluaire écarlate", [4299] = "Chapelain écarlate", [4291] = "Devin écarlate", [4297] = "Conjurateur écarlate", [4540] = "Moine écarlate", [4286] = "Soldat écarlate", [4289] = "Evocateur écarlate", [4290] = "Gardien écarlate", [4292] = "Protecteur écarlate", [4298] = "Défenseur écarlate", [4295] = "Myrmidon écarlate", [4294] = "Ensorceleur écarlate", [4301] = "Centurion écarlate", [4300] = "Sorcier écarlate", [4303] = "Abbé écarlate", [4302] = "Champion écarlate", [3981] = "Vorrel Sengutz", [6490] = "Azshir le Sans-sommeil", [6488] = "Champion mort", [6489] = "Echine-de-fer", [3983] = "Interrogateur Vishas", [4543] = "Mage de sang Thalnos", [3974] = "Maître-chien Loksey", [6487] = "Arcaniste Doan", [4542] = "Grand Inquisiteur Fairbanks", [3975] = "Herod", [3976] = "Commandant écarlate Mograine", [3977] = "Grand Inquisiteur Whitemane"},
		deDE = {[4293] = "Scharlachroter Wahrsager", [4306] = "Scharlachroter Folterknecht", [6426] = "Gequälter Toter", [4308] = "Ungefesselter Geist", [6427] = "Spuktrugbild", [4296] = "Scharlachroter Adept", [4287] = "Scharlachroter Kavalier", [4304] = "Scharlachroter Fährtenleserhund", [4288] = "Scharlachroter Bestienmeister", [4299] = "Scharlachroter Kaplan", [4291] = "Scharlachroter Rutengänger", [4297] = "Scharlachroter Herbeizauberer", [4540] = "Scharlachroter Mönch", [4286] = "Scharlachroter Soldat", [4289] = "Scharlachroter Rufer", [4290] = "Scharlachroter Gardist", [4292] = "Scharlachroter Beschützer", [4298] = "Scharlachroter Verteidiger", [4295] = "Scharlachroter Myrmidone", [4294] = "Scharlachroter Zauberhexer", [4301] = "Scharlachroter Zenturio", [4300] = "Scharlachroter Hexer", [4303] = "Scharlachroter Abt", [4302] = "Scharlachroter Held", [3981] = "Vorrel Sengutz", [6490] = "Azshir der Schlaflose", [6488] = "Gestürzter Held", [6489] = "Eisenrücken", [3983] = "Befrager Vishas", [4543] = "Blutmagier Thalnos", [3974] = "Hundemeister Loksey", [6487] = "Arkanist Doan", [4542] = "Hochinquisitor Fairbanks", [3975] = "Herod", [3976] = "Scharlachroter Kommandant Mograine", [3977] = "Hochinquisitor Whitemane"},
		esES = {[4293] = "Arúspice Escarlata", [4306] = "Torturador Escarlata", [6426] = "Muerto angustiado", [4308] = "Espíritu sin grilletes", [6427] = "Fantasma encantado", [4296] = "Adepto Escarlata", [4287] = "Gallardo Escarlata", [4304] = "Sabueso Escarlata", [4288] = "Maestro de bestias Escarlata", [4299] = "Capellán Escarlata", [4291] = "Adivinador Escarlata", [4297] = "Conjurador Escarlata", [4540] = "Monje Escarlata", [4286] = "Soldado Escarlata", [4289] = "Evocador Escarlata", [4290] = "Custodio Escarlata", [4292] = "Protector Escarlata", [4298] = "Defensor Escarlata", [4295] = "Mirmidón Escarlata", [4294] = "Hechicero Escarlata", [4301] = "Centurión Escarlata", [4300] = "Zahorí Escarlata", [4303] = "Abad Escarlata", [4302] = "Campeón Escarlata", [3981] = "Vorrel Sengutz", [6490] = "Azshir el Insomne", [6488] = "Campeón caído", [6489] = "Dorsacerado", [3983] = "Interrogador Vishas", [4543] = "Mago sangriento Thalnos", [3974] = "Maestro de canes Loksey", [6487] = "Arcanista Doan", [4542] = "Alto inquisidor Ribalimpia", [3975] = "Herod", [3976] = "Comandante Escarlata Mograine", [3977] = "Alta inquisidora Melenablanca"},
		esMX = {[4293] = "Arúspice Escarlata", [4306] = "Torturador Escarlata", [6426] = "Muerto angustiado", [4308] = "Espíritu sin grilletes", [6427] = "Fantasma encantado", [4296] = "Adepto Escarlata", [4287] = "Gallardo Escarlata", [4304] = "Sabueso Escarlata", [4288] = "Maestro de bestias Escarlata", [4299] = "Capellán Escarlata", [4291] = "Adivinador Escarlata", [4297] = "Conjurador Escarlata", [4540] = "Monje Escarlata", [4286] = "Soldado Escarlata", [4289] = "Evocador Escarlata", [4290] = "Custodio Escarlata", [4292] = "Protector Escarlata", [4298] = "Defensor Escarlata", [4295] = "Mirmidón Escarlata", [4294] = "Hechicero Escarlata", [4301] = "Centurión Escarlata", [4300] = "Zahorí Escarlata", [4303] = "Abad Escarlata", [4302] = "Campeón Escarlata", [3981] = "Vorrel Sengutz", [6490] = "Azshir el Insomne", [6488] = "Campeón caído", [6489] = "Dorsacerado", [3983] = "Interrogador Vishas", [4543] = "Mago sangriento Thalnos", [3974] = "Maestro de canes Loksey", [6487] = "Arcanista Doan", [4542] = "Alto inquisidor Ribalimpia", [3975] = "Herod", [3976] = "Comandante Escarlata Mograine", [3977] = "Alta inquisidora Melenablanca"},
		ptBR = {[4293] = "Áugure Escarlate", [4306] = "Torturador Escarlate", [6426] = "Morto Agonizante", [4308] = "Espírito Desopresso", [6427] = "Fantasma Vingador", [4296] = "Adepto Escarlate", [4287] = "Nobre Escarlate", [4304] = "Cão Farejador Escarlate", [4288] = "Senhor das Feras Escarlate", [4299] = "Capelão Escarlate", [4291] = "Vaticinador Escarlate", [4297] = "Conjurador Escarlate", [4540] = "Monge Escarlate", [4286] = "Soldado Escarlate", [4289] = "Evocador Escarlate", [4290] = "Guarda Escarlate", [4292] = "Protetor Escarlate", [4298] = "Defensor Escarlate", [4295] = "Mirmidão Escarlate", [4294] = "Feiticeiro Escarlate", [4301] = "Centurião Escarlate", [4300] = "Teurgo Escarlate", [4303] = "Abade Escarlate", [4302] = "Campeão Escarlate", [3981] = "Vorrel Sentripaz", [6490] = "Ashir, o Insone", [6488] = "Campeão Caído", [6489] = "Espinha de Ferro", [3983] = "Interrogador Vishas", [4543] = "Mago Sangrento Thalnos", [3974] = "Mestre de Matilha Lobato", [6487] = "Arcanista Doan", [4542] = "Alto-inquisidor Fairbanks", [3975] = "Herodes", [3976] = "Comandante Escarlate Mograine", [3977] = "Alta-inquisidora Cristalba"},
		ruRU = {[4293] = "Провидец из Алого ордена", [4306] = "Истязатель из Алого ордена", [6426] = "Тоскующий мертвец", [4308] = "Освобожденный дух", [6427] = "Блуждающий фантазм", [4296] = "Адепт из Алого ордена", [4287] = "Орденоносец из Алого ордена", [4304] = "Ищейка из Алого ордена", [4288] = "Зверолов из Алого ордена", [4299] = "Капеллан из Алого ордена", [4291] = "Гадатель из Алого ордена", [4297] = "Окудник из Алого ордена", [4540] = "Монах из Алого ордена", [4286] = "Солдат из Алого ордена", [4289] = "Вызыватель из Алого ордена", [4290] = "Охранник из Алого ордена", [4292] = "Заступник из Алого ордена", [4298] = "Защитник из Алого ордена", [4295] = "Мирмидон из Алого ордена", [4294] = "Колдун из Алого ордена", [4301] = "Центурион из Алого ордена", [4300] = "Волшебник из Алого ордена", [4303] = "Аббат из Алого ордена", [4302] = "Воитель из Алого ордена", [3981] = "Воррел Сенгутц", [6490] = "Азшир Неспящий", [6488] = "Павший воитель", [6489] = "Железноспин", [3983] = "Дознаватель Вишас", [4543] = "Волшебник Крови Талнос", [3974] = "Псарь Локси", [6487] = "Чародей Доан", [4542] = "Верховный инквизитор Фэйрбанкс", [3975] = "Герод", [3976] = "Командир Могрейн из Алого ордена", [3977] = "Верховный инквизитор Вайтмейн"},
		koKR = {[4293] = "붉은십자군 점술사", [4306] = "붉은십자군 고문관", [6426] = "고통받는 망자", [4308] = "해방된 영혼", [6427] = "절규하는 환영", [4296] = "붉은십자군 상급사제", [4287] = "붉은십자군 수행원", [4304] = "붉은십자군 추적용 하이에나", [4288] = "붉은십자군 조련사", [4299] = "붉은십자군 전도사", [4291] = "붉은십자군 풍수사", [4297] = "붉은십자군 요술사", [4540] = "붉은십자군 수도사", [4286] = "붉은십자군 병사", [4289] = "붉은십자군 강령사", [4290] = "붉은십자군 보초", [4292] = "붉은십자군 수호병", [4298] = "붉은십자군 호위병", [4295] = "붉은십자군 정예병", [4294] = "붉은십자군 빙술사", [4301] = "붉은십자군 백인대장", [4300] = "붉은십자군 마술사", [4303] = "붉은십자군 대수도원장", [4302] = "붉은십자군 용사", [3981] = "보렐 센구츠", [6490] = "잠들지 않는 아즈쉬르", [6488] = "타락한 용사", [6489] = "무쇠해골", [3983] = "심문관 비샤스", [4543] = "혈법사 탈노스", [3974] = "사냥개조련사 록시", [6487] = "신비술사 도안", [4542] = "종교재판관 페어뱅크스", [3975] = "헤로드", [3976] = "붉은십자군 사령관 모그레인", [3977] = "종교재판관 화이트메인"},
		zhCN = {[4293] = "血色占卜师", [4306] = "血色拷问者", [6426] = "痛苦的死者", [4308] = "自由的幽魂", [6427] = "鬼魅幻影", [4296] = "血色老兵", [4287] = "血色豪侠", [4304] = "血色捕猎犬", [4288] = "血色驯兽员", [4299] = "血色牧师", [4291] = "血色教士", [4297] = "血色咒术师", [4540] = "血色僧侣", [4286] = "血色士兵", [4289] = "血色招魂师", [4290] = "血色卫兵", [4292] = "血色保卫者", [4298] = "血色防御者", [4295] = "血色仆从", [4294] = "血色魔术师", [4301] = "血色百夫长", [4300] = "血色巫师", [4303] = "血色修士", [4302] = "血色勇士", [3981] = "沃瑞尔·森加斯", [6490] = "永醒的艾希尔", [6488] = "死灵勇士", [6489] = "铁脊死灵", [3983] = "审讯员韦沙斯", [4543] = "血法师萨尔诺斯", [3974] = "驯犬者洛克希", [6487] = "奥法师杜安", [4542] = "大检察官法尔班克斯", [3975] = "赫洛德", [3976] = "血色十字军指挥官莫格莱尼", [3977] = "大检察官怀特迈恩"},
		zhTW = {[4293] = "血色占卜者", [4306] = "血色拷問者", [6426] = "痛苦的死者", [4308] = "自由的幽魂", [6427] = "冤魂魅靈", [4296] = "血色老兵", [4287] = "血色豪俠", [4304] = "血色捕獵犬", [4288] = "血色馴獸員", [4299] = "血色牧師", [4291] = "血色預言師", [4297] = "血色咒術師", [4540] = "血色僧侶", [4286] = "血色士兵", [4289] = "血色塑能師", [4290] = "血色衛兵", [4292] = "血色保衛者", [4298] = "血色防衛者", [4295] = "血色僕從", [4294] = "血色巫士", [4301] = "血色百夫長", [4300] = "血色巫師", [4303] = "血色修士", [4302] = "血色勇士", [3981] = "沃瑞爾·森古斯", [6490] = "不眠的艾希爾", [6488] = "亡靈勇士", [6489] = "鐵脊死靈", [3983] = "審訊員韋沙斯", [4543] = "血法師薩爾諾斯", [3974] = "馴犬者洛克希", [6487] = "秘法師杜安", [4542] = "高等審判官法爾班克斯", [3975] = "赫洛德", [3976] = "血色十字軍指揮官莫格萊尼", [3977] = "高等審判官懷特邁恩"},
	},
	subs = {
		enUS = {[3975] = "The Scarlet Champion"},
		frFR = {[3975] = "Le champion écarlate"},
		deDE = {[3975] = "Der Scharlachrote Held"},
		esES = {[3975] = "El Campeón Escarlata"},
		esMX = {[3975] = "El Campeón Escarlata"},
		ptBR = {[3975] = "O Campeão Escarlate"},
		ruRU = {[3975] = "Герой Алого ордена"},
		koKR = {[3975] = "붉은십자군 용사"},
		zhCN = {[3975] = "血色十字军勇士"},
		zhTW = {[3975] = "血色勇士"},
	},
}
