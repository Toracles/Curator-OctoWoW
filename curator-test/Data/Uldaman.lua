-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "uldaman", kind = "dungeon", instance = 70, area = 1337,
	levels = { 41, 51 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 6910, 6906, 7023, 7206, 7291, 4854, 7228, 2748 }, final = 2748,
	name = "Uldaman",
	title = { frFR = "Uldaman", deDE = "Uldaman", esES = "Uldaman", esMX = "Uldaman", ptBR = "Uldaman", ruRU = "Ульдаман", koKR = "울다만", zhCN = "奥达曼" },
	tint = { 0.37, 0.31, 0.18 }, glow = { 0.94, 0.86, 0.63 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioUldaman", pack = "PackUldaman", set = "SetUldaman",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 7078, 1, 1, 20, 35, 36, 5985, 0, false }, -- Cleft Scorpid
		{ 7175, 1, 7, 0, 35, 35, 763, 659, false }, -- Stonevault Ambusher
		{ 4850, 1, 7, 0, 37, 39, 722, 659, false }, -- Stonevault Cave Lurker
		{ 4852, 1, 7, 0, 37, 38, 160, 659, false }, -- Stonevault Oracle
		{ 4861, 1, 1, 24, 38, 39, 1954, 3369, false }, -- Shrike Bat
		{ 4863, 1, 1, 0, 39, 40, 4486, 570, false }, -- Jadespine Basilisk
		{ 4847, 1, 7, 0, 39, 40, 6054, 1352, false }, -- Shadowforge Relic Hunter
		{ 7022, 1, 1, 20, 39, 40, 2488, 0, false }, -- Venomlash Scorpid
		{ 7405, 1, 1, 20, 42, 43, 5985, 0, false }, -- Deadly Cleft Scorpid
		{ 7011, 1, 7, 0, 42, 43, 6010, 1352, false }, -- Earthen Rocksmasher
		{ 7012, 1, 7, 0, 42, 43, 6009, 1352, false }, -- Earthen Sculptor
		{ 7309, 1, 7, 0, 44, 45, 6025, 1352, false }, -- Earthen Custodian
		{ 7076, 1, 7, 0, 44, 45, 6026, 1352, false }, -- Earthen Guardian
		{ 7077, 1, 7, 0, 44, 45, 6025, 1352, false }, -- Earthen Hallshaper
		{ 7396, 1, 7, 0, 44, 45, 6010, 1352, false }, -- Earthen Stonebreaker
		{ 7397, 1, 7, 0, 44, 45, 6009, 1352, false }, -- Earthen Stonecarver
		{ 6912, 2, 7, 0, 35, 35, 5711, 6036, true }, -- Remains of a Paladin
		{ 7030, 2, 7, 0, 40, 41, 6056, 1352, false }, -- Shadowforge Geologist
		{ 4849, 2, 7, 0, 43, 44, 6067, 1352, false }, -- Shadowforge Archaeologist
		{ 4848, 2, 7, 0, 43, 44, 6055, 1352, false }, -- Shadowforge Darkcaster
		{ 7290, 2, 7, 0, 43, 44, 6057, 1352, false }, -- Shadowforge Sharpshooter
		{ 4860, 2, 4, 0, 43, 44, 2234, 472, false }, -- Stone Steward
		{ 4855, 2, 7, 0, 43, 44, 11166, 659, false }, -- Stonevault Brawler
		{ 4853, 2, 7, 0, 43, 44, 1194, 659, false }, -- Stonevault Geomancer
		{ 7321, 2, 7, 0, 44, 45, 160, 659, false }, -- Stonevault Flameweaver
		{ 7320, 2, 7, 0, 44, 45, 11166, 659, false }, -- Stonevault Mauler
		{ 4857, 2, 4, 0, 46, 46, 10805, 472, false }, -- Stone Keeper
		{ 11073, 2, 7, 0, 54, 54, 10609, 5986, true }, -- Annora
		{ 6907, 3, 7, 0, 40, 40, 5708, 5904, true }, -- Eric "The Swift"
		{ 6908, 3, 7, 0, 40, 40, 5709, 5907, true }, -- Olaf
		{ 10120, 3, 4, 0, 45, 45, 5989, 472, false }, -- Vault Warder
		{ 6910, 4, 7, 0, 40, 40, 5945, 659, false }, -- Revelosh
		{ 6906, 4, 7, 0, 41, 41, 5710, 5910, true }, -- Baelog
		{ 7023, 4, 9, 0, 42, 42, 5285, 472, false }, -- Obsidian Sentinel
		{ 7206, 4, 4, 0, 44, 44, 10798, 472, false }, -- Ancient Stone Keeper
		{ 7291, 4, 7, 0, 45, 45, 6059, 1352, false }, -- Galgann Firehammer
		{ 4854, 4, 7, 0, 45, 45, 11165, 659, false }, -- Grimlok
		{ 7228, 5, 5, 0, 40, 40, 6089, 10119, false }, -- Ironaya
		{ 2748, 6, 5, 0, 47, 47, 5988, 472, false }, -- Archaedas
	},
	names = {
		enUS = {[7078] = "Cleft Scorpid", [7175] = "Stonevault Ambusher", [4850] = "Stonevault Cave Lurker", [4852] = "Stonevault Oracle", [4861] = "Shrike Bat", [4863] = "Jadespine Basilisk", [4847] = "Shadowforge Relic Hunter", [7022] = "Venomlash Scorpid", [7405] = "Deadly Cleft Scorpid", [7011] = "Earthen Rocksmasher", [7012] = "Earthen Sculptor", [7309] = "Earthen Custodian", [7076] = "Earthen Guardian", [7077] = "Earthen Hallshaper", [7396] = "Earthen Stonebreaker", [7397] = "Earthen Stonecarver", [6912] = "Remains of a Paladin", [7030] = "Shadowforge Geologist", [4849] = "Shadowforge Archaeologist", [4848] = "Shadowforge Darkcaster", [7290] = "Shadowforge Sharpshooter", [4860] = "Stone Steward", [4855] = "Stonevault Brawler", [4853] = "Stonevault Geomancer", [7321] = "Stonevault Flameweaver", [7320] = "Stonevault Mauler", [4857] = "Stone Keeper", [11073] = "Annora", [6907] = "Eric \"The Swift\"", [6908] = "Olaf", [10120] = "Vault Warder", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Obsidian Sentinel", [7206] = "Ancient Stone Keeper", [7291] = "Galgann Firehammer", [4854] = "Grimlok", [7228] = "Ironaya", [2748] = "Archaedas"},
		frFR = {[7078] = "Scorpide de la Faille", [7175] = "Embusqué Cavepierre", [4850] = "Rôdeur des cavernes Cavepierre", [4852] = "Oracle Cavepierre", [4861] = "Chauve-souris hurlante", [4863] = "Basilic Jadéchine", [4847] = "Chasseur de reliques Ombreforge", [7022] = "Scorpide empoisonneur", [7405] = "Scorpide de la Faille mortel", [7011] = "Brise-roc terrestre", [7012] = "Sculpteur terrestre", [7309] = "Protecteur terrestre", [7076] = "Gardien terrestre", [7077] = "Réformeur terrestre", [7396] = "Brise-pierre terrestre", [7397] = "Grave-pierre terrestre", [6912] = "Restes d’un paladin", [7030] = "Géologue Ombreforge", [4849] = "Archéologue Ombreforge", [4848] = "Invocateur noir Ombreforge", [7290] = "Tireur d'élite Ombreforge", [4860] = "Régisseur des pierres", [4855] = "Bagarreur Cavepierre", [4853] = "Géomancien Cavepierre", [7321] = "Tisseur de flammes Cavepierre", [7320] = "Marteleur Cavepierre", [4857] = "Gardien des pierres", [11073] = "Annora", [6907] = "Eric \"l'Agile\"", [6908] = "Olaf", [10120] = "Garde de la Banque", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Sentinelle d'obsidienne", [7206] = "Ancien Gardien des pierres", [7291] = "Galgann Firehammer", [4854] = "Grimlok", [7228] = "Ironaya", [2748] = "Archaedas"},
		deDE = {[7078] = "Kluftskorpid", [7175] = "Wegelagerer der Steingrufttroggs", [4850] = "Höhlenlauerer der Steingrufttroggs", [4852] = "Orakel der Steingrufttroggs", [4861] = "Würgerfledermaus", [4863] = "Jaderückenbasilisk", [4847] = "Reliktjäger der Schattenschmiede", [7022] = "Giftpeitscherskorpid", [7405] = "Tödlicher Kluftskorpid", [7011] = "Irdener Felsbrecher", [7012] = "Irdener Bildhauer", [7309] = "Irdener Wärter", [7076] = "Irdener Wächter", [7077] = "Irdener Gewölbeformer", [7396] = "Irdener Steinbrecher", [7397] = "Irdener Steinschneider", [6912] = "Überreste eines Paladins", [7030] = "Geologe der Schattenschmiede", [4849] = "Archäologe der Schattenschmiede", [4848] = "Dunkelzauberer der Schattenschmiede", [7290] = "Scharfschütze der Schattenschmiede", [4860] = "Steinbehüter", [4855] = "Muskelprotz der Steingrufttroggs", [4853] = "Geomant der Steingrufttroggs", [7321] = "Flammenwirker der Steingrufttroggs", [7320] = "Raufer der Steingrufttroggs", [4857] = "Steinbewahrer", [11073] = "Annora", [6907] = "Eric \"Der Flinke\"", [6908] = "Olaf", [10120] = "Gewölbewärter", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Obsidianschildwache", [7206] = "Uralter Steinbewahrer", [7291] = "Galgann Feuerhammer", [4854] = "Grimlok", [7228] = "Ironaya", [2748] = "Archaedas"},
		esES = {[7078] = "Escórpido de La Grieta", [7175] = "Emboscador Grutacanto", [4850] = "Rondador Grutacanto", [4852] = "Oráculo Grutacanto", [4861] = "Alcaudociélago", [4863] = "Basilisco Dorsaljade", [4847] = "Cazareliquias Forjatiniebla", [7022] = "Escórpido lativenenoso", [7405] = "Escórpido del Risco Mortal", [7011] = "Machacapiedras de tierra", [7012] = "Escultor de tierra", [7309] = "Custodio de tierra", [7076] = "Guardián de tierra", [7077] = "Formajol de tierra", [7396] = "Rompepedras de tierra", [7397] = "Tallapiedras de piedra", [6912] = "Restos de un paladín", [7030] = "Geólogo Forjatiniebla", [4849] = "Arqueólogo Forjatiniebla", [4848] = "Forjador oscuro Forjatiniebla", [7290] = "Tirador Forjatiniebla", [4860] = "Asistente de piedra", [4855] = "Camorrista Grutacanto", [4853] = "Geomántico Grutacanto", [7321] = "Tejellama Grutacanto", [7320] = "Destructor Grutacanto", [4857] = "Vigilante de piedra", [11073] = "Annora", [6907] = "Eric \"El Suave\"", [6908] = "Olaf", [10120] = "Guarda de la cámara acorazada", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Centinela Obsidiano", [7206] = "Vigilante pétreo anciano", [7291] = "Galgann Flamartillo", [4854] = "Grimlok", [7228] = "Hierraya", [2748] = "Archaedas"},
		esMX = {[7078] = "Escórpido de La Grieta", [7175] = "Emboscador Grutacanto", [4850] = "Rondador Grutacanto", [4852] = "Oráculo Grutacanto", [4861] = "Alcaudociélago", [4863] = "Basilisco Dorsaljade", [4847] = "Cazareliquias Forjatiniebla", [7022] = "Escórpido lativenenoso", [7405] = "Escórpido del Risco Mortal", [7011] = "Machacapiedras de tierra", [7012] = "Escultor de tierra", [7309] = "Custodio de tierra", [7076] = "Guardián de tierra", [7077] = "Formajol de tierra", [7396] = "Rompepedras de tierra", [7397] = "Tallapiedras de piedra", [6912] = "Restos de un paladín", [7030] = "Geólogo Forjatiniebla", [4849] = "Arqueólogo Forjatiniebla", [4848] = "Forjador oscuro Forjatiniebla", [7290] = "Tirador Forjatiniebla", [4860] = "Asistente de piedra", [4855] = "Camorrista Grutacanto", [4853] = "Geomántico Grutacanto", [7321] = "Tejellama Grutacanto", [7320] = "Destructor Grutacanto", [4857] = "Vigilante de piedra", [11073] = "Annora", [6907] = "Eric \"El Suave\"", [6908] = "Olaf", [10120] = "Guarda de la cámara acorazada", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Centinela Obsidiano", [7206] = "Vigilante pétreo anciano", [7291] = "Galgann Flamartillo", [4854] = "Grimlok", [7228] = "Hierraya", [2748] = "Archaedas"},
		ptBR = {[7078] = "Escorpídeo da Fenda", [7175] = "Emboscador da Abóbada de Pedra", [4850] = "Tocaieiro das Cavernas da Abóbada de Pedra", [4852] = "Oráculo da Abóbada de Pedra", [4861] = "Morcego Corvoide", [4863] = "Basilisco Jadespinho", [4847] = "Caçador de Relíquias de Umbraforja", [7022] = "Escorpídeo Açoitador", [7405] = "Escorpídeo Mortal da Fenda", [7011] = "Esmagarrocha Terrano", [7012] = "Escultor Terrano", [7309] = "Custódio Terrano", [7076] = "Guardião Terrano", [7077] = "Moldador Terrano", [7396] = "Britador Terrano", [7397] = "Entalhador Terrano", [6912] = "Restos Mortais de um Paladino", [7030] = "Geólogo de Umbraforja", [4849] = "Arqueólogo de Umbraforja", [4848] = "Taumaturgo de Umbraforja", [7290] = "Atirador de Elite de Umbraforja", [4860] = "Mordomo de Pedra", [4855] = "Brigão da Abóbada de Pedra", [4853] = "Geomante da Abóbada de Pedra", [7321] = "Tecechamas da Abóbada de Pedra", [7320] = "Esmagador da Abóbada de Pedra", [4857] = "Guardião de Pedra", [11073] = "Annora", [6907] = "Eric, o Veloz", [6908] = "Olaf", [10120] = "Protetor da Abóbada", [6910] = "Revelosh", [6906] = "Baelog", [7023] = "Sentinela de Obsidiana", [7206] = "Antigo Protetor de Pedra", [7291] = "Galnann Martelígneo", [4854] = "Grimlok", [7228] = "Ferronaya", [2748] = "Arkhaedas"},
		ruRU = {[7078] = "Пещерный скорпид", [7175] = "Душитель из племени Каменного Свода", [4850] = "Скрытень из племени Каменного Свода", [4852] = "Оракул из племени Каменного Свода", [4861] = "Крылан-охотник", [4863] = "Нефритовый василиск", [4847] = "Тенегорнский охотник за реликвиями", [7022] = "Ядоносный скорпид", [7405] = "Смертоносный пещерный скорпид", [7011] = "Глиняный камнекрушитель", [7012] = "Глиняный скульптор", [7309] = "Глиняный комендант", [7076] = "Глиняный землестраж", [7077] = "Глиняный строитель", [7396] = "Глиняный камнелом", [7397] = "Глиняный камнерез", [6912] = "Останки паладина", [7030] = "Тенегорнский геолог", [4849] = "Тенегорнский археолог", [4848] = "Тенегорнский черный маг", [7290] = "Тенегорнский меткий стрелок", [4860] = "Каменный распорядитель", [4855] = "Буян из племени Каменного Свода", [4853] = "Геомант из племени Каменного Свода", [7321] = "Ткач Пламени из племени Каменного Свода", [7320] = "Изверг из племени Каменного Свода", [4857] = "Каменный хранитель", [11073] = "Аннора", [6907] = "Эрик \"Быстрый\"", [6908] = "Олаф", [10120] = "Тюремщик подземелья", [6910] = "Ревелош", [6906] = "Бейлог", [7023] = "Обсидиановый часовой", [7206] = "Древний Хранитель Камня", [7291] = "Галганн Огнемолот", [4854] = "Гримлок", [7228] = "Иронайа", [2748] = "Аркедас"},
		koKR = {[7078] = "그늘전갈", [7175] = "바위동굴일족 복병", [4850] = "바위동굴일족 잠복꾼", [4852] = "바위동굴일족 현자", [4861] = "무덤박쥐", [4863] = "비취돌기 바실리스크", [4847] = "어둠괴철로단 보물사냥꾼", [7022] = "맹독꼬리전갈", [7405] = "맹독그늘전갈", [7011] = "토석인 바위망치장이", [7012] = "토석인 조각사", [7309] = "토석인 유물관리자", [7076] = "토석인 수호자", [7077] = "토석인 조각장이", [7396] = "토석인 돌망치장이", [7397] = "토석인 석공", [6912] = "성기사의 유해", [7030] = "어둠괴철로단 지질학자", [4849] = "어둠괴철로단 고고학자", [4848] = "어둠괴철로단 흑마법사", [7290] = "어둠괴철로단 저격수", [4860] = "바위 청지기", [4855] = "바위동굴일족 투사", [4853] = "바위동굴일족 흙점쟁이", [7321] = "바위동굴일족 화염술사", [7320] = "바위동굴일족 싸움꾼", [4857] = "바위 문지기", [11073] = "안노라", [6907] = "날쌘돌이 에릭", [6908] = "올라프", [10120] = "석실 관리인", [6910] = "레벨로쉬", [6906] = "밸로그", [7023] = "흑요석 파수꾼", [7206] = "고대 바위 문지기", [7291] = "갈간 파이어해머", [4854] = "그림로크", [7228] = "아이로나야", [2748] = "아카에다스"},
		zhCN = {[7078] = "裂隙沙漠蝎", [7175] = "石窟伏击者", [4850] = "石窟潜伏者", [4852] = "石窟智者", [4861] = "利齿蝙蝠", [4863] = "玉脊蜥蜴", [4847] = "暗炉发掘者", [7022] = "毒鞭蝎", [7405] = "致命的裂隙沙漠蝎", [7011] = "土灵碎岩者", [7012] = "土灵雕刻者", [7309] = "土灵管理者", [7076] = "土灵守护者", [7077] = "土灵筑厅师", [7396] = "土灵破石者", [7397] = "土灵凿石者", [6912] = "圣骑士的遗体", [7030] = "暗炉地质学家", [4849] = "暗炉考古学家", [4848] = "暗炉暗法师", [7290] = "暗炉狙击手", [4860] = "石头管理者", [4855] = "石窟争斗者", [4853] = "石窟地占师", [7321] = "石窟织炎者", [7320] = "石窟虐待者", [4857] = "石头看守者", [11073] = "安诺拉", [6907] = "埃瑞克", [6908] = "奥拉夫", [10120] = "宝库护卫者", [6910] = "鲁维罗什", [6906] = "巴尔洛戈", [7023] = "黑曜石哨兵", [7206] = "古代的石头看守者", [7291] = "加加恩·火锤", [4854] = "格瑞姆洛克", [7228] = "艾隆纳亚", [2748] = "阿扎达斯"},
		zhTW = {[7078] = "裂隙沙漠蠍", [7175] = "石窟伏擊者", [4850] = "石窟潛伏者", [4852] = "石窟神諭者", [4861] = "利齒蝙蝠", [4863] = "玉脊蜥蜴", [4847] = "暗爐發掘者", [7022] = "毒鞭蠍", [7405] = "致命的裂隙沙漠蠍", [7011] = "土靈碎岩者", [7012] = "土靈雕刻者", [7309] = "土靈管理者", [7076] = "土靈守護者", [7077] = "土靈築廳師", [7396] = "土靈碎石者", [7397] = "土靈鑿石者", [6912] = "聖騎士的遺體", [7030] = "暗爐地質學家", [4849] = "暗爐考古學家", [4848] = "暗爐暗法師", [7290] = "暗爐狙擊手", [4860] = "石頭管理者", [4855] = "石窟打鬥者", [4853] = "石窟地卜師", [7321] = "石窟織炎者", [7320] = "石窟虐待者", [4857] = "石頭看守者", [11073] = "安諾拉", [6907] = "『迅捷』艾利克", [6908] = "奧拉夫", [10120] = "寶庫守衛", [6910] = "魯維羅什", [6906] = "巴爾洛戈", [7023] = "黑曜石哨兵", [7206] = "古代的石頭看守者", [7291] = "加加恩·火錘", [4854] = "格瑞姆洛克", [7228] = "艾隆納亞", [2748] = "阿札達斯"},
	},
	subs = {
		enUS = {[11073] = "Master Enchanter", [4854] = "Stonevault Chieftain", [2748] = "Ancient Stone Watcher"},
		frFR = {[11073] = "Enchanteur - Maître", [4854] = "Chef des Cavepierres", [2748] = "Ancien gardien des pierres"},
		deDE = {[11073] = "Verzauberkunstmeisterin", [4854] = "Häuptling der Steingrufttroggs", [2748] = "Alter Steinbehüter"},
		esES = {[11073] = "Maestra encantadora", [4854] = "Jefe Grutacanto", [2748] = "Guardapiedras antiguo"},
		esMX = {[11073] = "Maestra encantadora", [4854] = "Jefe Grutacanto", [2748] = "Guardapiedras antiguo"},
		ptBR = {[11073] = "Mestre Encantadora", [4854] = "Chefe Abóbada de Pedra", [2748] = "Antigo Vigia de Pedra"},
		ruRU = {[11073] = "Мастер-зачаровыватель", [4854] = "Вождь племени Каменного Свода", [2748] = "Древний Каменный Страж"},
		koKR = {[11073] = "마법부여의 대가", [4854] = "바위동굴일족 족장", [2748] = "고대의 바위감시자"},
		zhCN = {[11073] = "大师级附魔师", [4854] = "石窟酋长", [2748] = "远古石卫士"},
		zhTW = {[11073] = "附魔訓練師", [4854] = "石窟酋長", [2748] = "遠古石衛士"},
	},
}
