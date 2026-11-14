-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "maraudon", kind = "dungeon", instance = 349, area = 2100,
	levels = { 46, 55 }, side = "C",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 12236, 13282, 12258, 12225, 13596, 13601, 12203, 12201 }, final = 12201,
	name = "Maraudon",
	title = { frFR = "Maraudon", deDE = "Maraudon", esES = "Maraudon", esMX = "Maraudon", ptBR = "Maraudon", ruRU = "Марадон", koKR = "마라우돈", zhCN = "玛拉顿" },
	tint = { 0.28, 0.18, 0.37 }, glow = { 0.82, 0.71, 1.00 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioMaraudon", pack = "PackMaraudon", set = "SetMaraudon",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 13321, 1, 8, 0, 1, 1, 6297, 0, false }, -- Frog
		{ 12217, 1, 3, 0, 42, 43, 12345, 770, false }, -- Corruptor
		{ 12216, 1, 3, 0, 42, 43, 2452, 770, false }, -- Poison Sprite
		{ 11792, 1, 3, 0, 42, 43, 2021, 1010, false }, -- Putridus Shadowstalker
		{ 13141, 1, 4, 0, 43, 44, 2079, 1498, false }, -- Deeprot Stomper
		{ 11790, 1, 3, 0, 43, 44, 11345, 1010, false }, -- Putridus Satyr
		{ 11791, 1, 3, 0, 43, 45, 11338, 1010, false }, -- Putridus Trickster
		{ 12219, 1, 10, 0, 44, 45, 12347, 5050, false }, -- Barbed Lasher
		{ 13743, 1, 4, 0, 44, 44, 9593, 1498, false }, -- Corrupt Force of Nature
		{ 13142, 1, 4, 0, 44, 45, 13098, 1498, false }, -- Deeprot Tangler
		{ 11793, 1, 7, 0, 45, 46, 11714, 1134, false }, -- Celebrian Dryad
		{ 12220, 1, 10, 0, 45, 46, 12348, 5050, false }, -- Constrictor Vine
		{ 12222, 1, 10, 0, 45, 46, 14350, 724, false }, -- Creeping Sludge
		{ 12218, 1, 1, 0, 45, 47, 12346, 5043, false }, -- Vile Larva
		{ 11789, 1, 1, 0, 46, 48, 12333, 5043, false }, -- Deep Borer
		{ 13599, 1, 1, 21, 46, 47, 6368, 1464, false }, -- Stolid Snapjaw
		{ 12223, 2, 4, 0, 45, 46, 3386, 462, false }, -- Cavern Lurker
		{ 11794, 2, 7, 0, 45, 47, 12337, 1134, false }, -- Sister of Celebrian
		{ 12224, 2, 4, 0, 46, 47, 9014, 462, false }, -- Cavern Shambler
		{ 12221, 2, 10, 0, 46, 47, 1145, 724, false }, -- Noxious Slime
		{ 12242, 2, 6, 0, 46, 46, 12370, 1044, false }, -- Spirit of Maraudos
		{ 13323, 2, 1, 0, 46, 48, 13209, 6161, false }, -- Subterranean Diemetradon
		{ 12207, 2, 10, 0, 46, 47, 6737, 455, false }, -- Thessala Hydra
		{ 12243, 2, 6, 0, 47, 47, 12373, 1044, false }, -- Spirit of Veng
		{ 11784, 2, 4, 0, 47, 48, 11712, 739, false }, -- Theradrim Guardian
		{ 12206, 2, 5, 0, 48, 49, 12309, 3685, false }, -- Primordial Behemoth
		{ 12237, 3, 4, 0, 48, 48, 9014, 462, false }, -- Meshlok the Harvester
		{ 12236, 4, 3, 0, 47, 47, 12334, 1010, false }, -- Lord Vyletongue
		{ 13282, 4, 4, 0, 48, 48, 11172, 724, false }, -- Noxxion
		{ 12258, 4, 10, 0, 48, 48, 12389, 5050, false }, -- Razorlash
		{ 12225, 4, 7, 0, 49, 49, 12350, 1127, false }, -- Celebras the Cursed
		{ 13596, 4, 1, 0, 50, 50, 13589, 1236, false }, -- Rotgrip
		{ 13601, 4, 7, 0, 50, 50, 7125, 1414, false }, -- Tinkerer Gizlock
		{ 12203, 5, 5, 0, 50, 50, 12293, 3685, false }, -- Landslide
		{ 12201, 6, 4, 0, 51, 51, 12292, 739, false }, -- Princess Theradras
	},
	names = {
		enUS = {[13321] = "Frog", [12217] = "Corruptor", [12216] = "Poison Sprite", [11792] = "Putridus Shadowstalker", [13141] = "Deeprot Stomper", [11790] = "Putridus Satyr", [11791] = "Putridus Trickster", [12219] = "Barbed Lasher", [13743] = "Corrupt Force of Nature", [13142] = "Deeprot Tangler", [11793] = "Celebrian Dryad", [12220] = "Constrictor Vine", [12222] = "Creeping Sludge", [12218] = "Vile Larva", [11789] = "Deep Borer", [13599] = "Stolid Snapjaw", [12223] = "Cavern Lurker", [11794] = "Sister of Celebrian", [12224] = "Cavern Shambler", [12221] = "Noxious Slime", [12242] = "Spirit of Maraudos", [13323] = "Subterranean Diemetradon", [12207] = "Thessala Hydra", [12243] = "Spirit of Veng", [11784] = "Theradrim Guardian", [12206] = "Primordial Behemoth", [12237] = "Meshlok the Harvester", [12236] = "Lord Vyletongue", [13282] = "Noxxion", [12258] = "Razorlash", [12225] = "Celebras the Cursed", [13596] = "Rotgrip", [13601] = "Tinkerer Gizlock", [12203] = "Landslide", [12201] = "Princess Theradras"},
		frFR = {[13321] = "Grenouille", [12217] = "Corrupteur", [12216] = "Fée empoisonnante", [11792] = "Traqueur des ombres Putridus", [13141] = "Marteleur Sève-putride", [11790] = "Satyre Putridus", [11791] = "Entourloupeur Putridus", [12219] = "Flagellant barbelé", [13743] = "Force de la Nature corrompue", [13142] = "Noueur Sève-putride", [11793] = "Dryade de Celebrian", [12220] = "Liane étrangleuse", [12222] = "Vase rampante", [12218] = "Larve maléfique", [11789] = "Fouisseur des profondeurs", [13599] = "Gueule d'acier impassible", [12223] = "Rôdeur des cavernes", [11794] = "Soeur de Celebrian", [12224] = "Traînard des grottes", [12221] = "Gelée nuisible", [12242] = "Esprit de Maraudos", [13323] = "Dimeurtrodon souterrain", [12207] = "Hydre de Thessala", [12243] = "Esprit de Veng", [11784] = "Gardien Theradrim", [12206] = "Béhémoth primordial", [12237] = "Meshlok le Moissonneur", [12236] = "Seigneur Vylelangue", [13282] = "Noxxion", [12258] = "Tranchefouet", [12225] = "Celebras le Maudit", [13596] = "Grippe-charogne", [13601] = "Artisan Gizlock", [12203] = "Glissement de terrain", [12201] = "Princesse Theradras"},
		deDE = {[13321] = "Frosch", [12217] = "Verderber", [12216] = "Giftgrimmling", [11792] = "Schattenpirscher der Putridus", [13141] = "Rottwurzelstampfer", [11790] = "Satyr der Putridus", [11791] = "Schwindler der Putridus", [12219] = "Stachelpeitscher", [13743] = "Verderbte Naturgewalt", [13142] = "Rottwurzelgreifer", [11793] = "Dryade von Celebrian", [12220] = "Würgeranke", [12222] = "Kriechender Schlamm", [12218] = "Elende Larve", [11789] = "Tiefbohrer", [13599] = "Phlegmatischer Schnappkiefer", [12223] = "Höhlenlauerer", [11794] = "Schwester von Celebrian", [12224] = "Höhlenschlurfer", [12221] = "Giftiger Brühschleimer", [12242] = "Geist von Maraudos", [13323] = "Unterirdisches Dimetrodon", [12207] = "Thessalahydra", [12243] = "Geist von Veng", [11784] = "Theradrimwächter", [12206] = "Urzeitliches Ungetüm", [12237] = "Meshlok der Ernter", [12236] = "Lord Schlangenzunge", [13282] = "Noxxion", [12258] = "Schlingwurzler", [12225] = "Celebras der Verfluchte", [13596] = "Faulschnapper", [13601] = "Tüftler Gizlock", [12203] = "Erdrutsch", [12201] = "Prinzessin Theradras"},
		esES = {[13321] = "Rana", [12217] = "Corruptor", [12216] = "Duende venenoso", [11792] = "Acechasombras Putridus", [13141] = "Vapuleador Raizonda", [11790] = "Sátiro Putridus", [11791] = "Tramposo Putridus", [12219] = "Latigador espinoso", [13743] = "Fuerza de la naturaleza corrupta", [13142] = "Enmarañador Raizonda", [11793] = "Dríade celebriana", [12220] = "Parra constrictora", [12222] = "Barroso trepador", [12218] = "Larva vil", [11789] = "Cavapozos de las profundidades", [13599] = "Quijaforte imperturbable", [12223] = "Rondador de la Caverna", [11794] = "Hermana de Celebrian", [12224] = "Arrastrapiés de la Caverna", [12221] = "Babosa nociva", [12242] = "Espíritu de Maraudos", [13323] = "Diemetradón subterráneo", [12207] = "Hidra Thessala", [12243] = "Espíritu de Veng", [11784] = "Guardián Theradrim", [12206] = "Behemoth primario", [12237] = "Meshlok el Cosechador", [12236] = "Lord Lenguavil", [13282] = "Noxxion", [12258] = "Latisable", [12225] = "Celebras el Maldito", [13596] = "Escamapodrida", [13601] = "Manitas Gizlock", [12203] = "Derrumblo", [12201] = "Princesa Theradras"},
		esMX = {[13321] = "Rana", [12217] = "Corruptor", [12216] = "Duende venenoso", [11792] = "Acechasombras Putridus", [13141] = "Vapuleador Raizonda", [11790] = "Sátiro Putridus", [11791] = "Tramposo Putridus", [12219] = "Azotador espinoso", [13743] = "Fuerza de la naturaleza corrupta", [13142] = "Enmarañador Raizonda", [11793] = "Dríade celebriana", [12220] = "Parra constrictora", [12222] = "Lodo trepador", [12218] = "Larva vil", [11789] = "Cavapozos de las profundidades", [13599] = "Quijaforte imperturbable", [12223] = "Rondador de la Caverna", [11794] = "Hermana de Celebrian", [12224] = "Arrastrapiés de la Caverna", [12221] = "Babosa nociva", [12242] = "Espíritu de Maraudos", [13323] = "Diemetradón subterráneo", [12207] = "Hidra Thessala", [12243] = "Espíritu de Veng", [11784] = "Guardián Theradrim", [12206] = "Behemoth primario", [12237] = "Meshlok el Cosechador", [12236] = "Lord Lenguavil", [13282] = "Noxxion", [12258] = "Latisable", [12225] = "Celebras el Maldito", [13596] = "Escamapodrida", [13601] = "Manitas Gizlock", [12203] = "Derrumblo", [12201] = "Princesa Theradras"},
		ptBR = {[13321] = "Rã", [12217] = "Corruptor", [12216] = "Duende Peçonhento", [11792] = "Assombrante de Pútridus", [13141] = "Pisoteador Putrefundo", [11790] = "Sátiro de Pútridus", [11791] = "Trapaceiro de Pútridus", [12219] = "Açoitadeira Farpada", [13743] = "Força da Natureza Corrompida", [13142] = "Emaranhador Putrefundo", [11793] = "Dríade Celebriana", [12220] = "Trepadeira Constritiva", [12222] = "Lodo Rastejante", [12218] = "Larva Torpe", [11789] = "Perfurador Reentrante", [13599] = "Mordelisca Estólida", [12223] = "Tocaieiro das Cavernas", [11794] = "Irmã de Celebras", [12224] = "Cambaleante das Cavernas", [12221] = "Visgo Nocivo", [12242] = "Espírito de Maraudos", [13323] = "Dimetrodonte Subterrâneo", [12207] = "Hidra Thessala", [12243] = "Espírito de Veng", [11784] = "Guardião Theradrim", [12206] = "Beemote Primordial", [12237] = "Meshloc, o Ceifador", [12236] = "Lorde Torpelíngua", [13282] = "Tóxxico", [12258] = "Azorrague", [12225] = "Celebras, o Amaldiçoado", [13596] = "Putrigarra", [13601] = "Engenhoqueiro Bugitranca", [12203] = "Soterrador", [12201] = "Princesa Theradras"},
		ruRU = {[13321] = "Лягушка", [12217] = "Бес-осквернитель", [12216] = "Ядовитый грелль", [11792] = "Тенелов из племени Тлетворных", [13141] = "Прогнивший топотун", [11790] = "Сатир из племени Тлетворных", [11791] = "Плут из племени Тлетворных", [12219] = "Колючий хлыстолап", [13743] = "Оскверненная сила природы", [13142] = "Загнивший плетун", [11793] = "Селебрийская дриада", [12220] = "Удушающая лоза", [12222] = "Ползучий слякоч", [12218] = "Мерзкая личинка", [11789] = "Глубокоп", [13599] = "Вялый хрустогрыз", [12223] = "Пещерный скрытень", [11794] = "Келебрийская сестра", [12224] = "Пещерный шаркун", [12221] = "Пагубная слизь", [12242] = "Дух Мародоса", [13323] = "Подземный деметродон", [12207] = "Тессалийская гидра", [12243] = "Дух Венга", [11784] = "Терадримский страж", [12206] = "Доисторическое чудище", [12237] = "Мешлок Жнец", [12236] = "Лорд Злоязыкий", [13282] = "Ноксион", [12258] = "Бритвохлест", [12225] = "Селебрас Проклятый", [13596] = "Гнилопасть", [13601] = "Ремонтник Гизлок", [12203] = "Сель", [12201] = "Принцесса Терадрас"},
		koKR = {[13321] = "개구리", [12217] = "타락의 마귀", [12216] = "맹독의 마귀", [11792] = "타락의 그림자추적자", [13141] = "우레의 깊은뿌리정령", [11790] = "타락의 사티로스", [11791] = "타락의 요술사", [12219] = "뾰족가시 덩굴손", [13743] = "타락한 자연의 군대", [13142] = "올가미의 깊은뿌리정령", [11793] = "셀레브라스의 드리아드", [12220] = "채찍줄기 덩굴손", [12222] = "끈적거리는 녹괴물", [12218] = "썩은구더기", [11789] = "구덩이 미늘벌레", [13599] = "느림보 무쇠턱거북", [12223] = "동굴껍질괴물", [11794] = "셀레브라스의 딸", [12224] = "파괴의 동굴껍질괴물", [12221] = "맹독 진흙괴물", [12242] = "마라우도스의 영혼", [13323] = "지하 디메트로돈", [12207] = "텟살라 히드라", [12243] = "벵의 영혼", [11784] = "테라드림 수호자", [12206] = "태초의 거수", [12237] = "정원사 메슬로크", [12236] = "군주 바일텅", [13282] = "녹시온", [12258] = "칼날채찍", [12225] = "저주받은 셀레브라스", [13596] = "썩은아귀", [13601] = "땜장이 기즐록", [12203] = "산사태", [12201] = "공주 테라드라스"},
		zhCN = {[13321] = "青蛙", [12217] = "腐化劣魔", [12216] = "毒劣魔", [11792] = "腐烂巡影者", [13141] = "深腐践踏者", [11790] = "腐烂萨特", [11791] = "腐烂欺骗者", [12219] = "尖刺鞭笞者", [13743] = "腐化的自然之力", [13142] = "深腐纠缠者", [11793] = "塞雷布拉斯树妖", [12220] = "蟒藤", [12222] = "爬行污泥怪", [12218] = "邪恶幼虫", [11789] = "深岩虫", [13599] = "迟钝的钳嘴龟", [12223] = "洞窟潜伏者", [11794] = "塞雷布拉斯的姐妹", [12224] = "洞窟游荡者", [12221] = "毒性软泥怪", [12242] = "玛劳杜斯之魂", [13323] = "地下双帆龙", [12207] = "塞萨拉多头怪", [12243] = "温格之魂", [11784] = "瑟莱德丝卫士", [12206] = "原始巨兽", [12237] = "收割者麦什洛克", [12236] = "维利塔恩", [13282] = "诺克赛恩", [12258] = "锐刺鞭笞者", [12225] = "被诅咒的塞雷布拉斯", [13596] = "洛特格里普", [13601] = "工匠吉兹洛克", [12203] = "兰斯利德", [12201] = "瑟莱德丝公主"},
		zhTW = {[13321] = "青蛙", [12217] = "腐化劣魔", [12216] = "毒劣魔", [11792] = "腐爛巡影者", [13141] = "深腐踐踏者", [11790] = "腐爛薩特", [11791] = "腐爛欺詐者", [12219] = "尖刺鞭笞者", [13743] = "墮落的自然之力", [13142] = "深腐糾纏者", [11793] = "瑟雷布萊林精", [12220] = "蟒藤", [12222] = "爬行污泥怪", [12218] = "邪惡幼蟲", [11789] = "深岩蟲", [13599] = "遲鈍的鉗嘴龜", [12223] = "洞窟潛伏者", [11794] = "瑟雷布萊之女", [12224] = "洞窟遊蕩者", [12221] = "毒性軟泥怪", [12242] = "瑪勞杜斯之靈", [13323] = "地下雙帆龍", [12207] = "塞薩拉多頭蛇", [12243] = "溫格之靈", [11784] = "瑟萊德絲衛士", [12206] = "原始巨獸", [12237] = "『收割者』麥什洛克", [12236] = "維利塔恩領主", [13282] = "諾克賽恩", [12258] = "銳刺鞭笞者", [12225] = "被詛咒的塞雷布拉斯", [13596] = "洛特格里普", [13601] = "技工吉茲洛克", [12203] = "蘭斯利德", [12201] = "瑟萊德絲公主"},
	},
	subs = {
		enUS = {[12242] = "The Fourth Kahn", [12243] = "The Fifth Kahn"},
		frFR = {[12242] = "Le quatrième Kahn", [12243] = "Le cinquième Kahn"},
		deDE = {[12242] = "Der vierte Khan", [12243] = "Der fünfte Khan"},
		esES = {[12242] = "El cuarto kahn", [12243] = "El quinto kahn"},
		esMX = {[12242] = "El cuarto kahn", [12243] = "El quinto kahn"},
		ptBR = {[12242] = "O Quarto Khan", [12243] = "O Quinto Khan"},
		ruRU = {[12242] = "Четвертый хан", [12243] = "Пятый хан"},
		koKR = {[12242] = "제4대 칸", [12243] = "제5대 칸"},
		zhCN = {[12242] = "第四可汗", [12243] = "第五可汗"},
		zhTW = {[12242] = "第四可汗", [12243] = "第五可汗"},
	},
}
