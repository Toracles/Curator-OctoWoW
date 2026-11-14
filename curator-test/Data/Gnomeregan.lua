-- AUTO GENERATED. Creatures and names: QuestieDB (Forever build). Models and sounds: CMaNGOS classic-db, client data.
local _, ns = "Curator", CuratorOctoFull
ns.Series = ns.Series or {}
ns.Series[CuratorOctoFull.Length(ns.Series) + 1] = {
	key = "gnomeregan", kind = "dungeon", instance = 90, area = 721,
	levels = { 29, 38 }, side = "A",
	-- bosses (a kill fills the gauge), the last one completes the dungeon
	bosses = { 7079, 6235, 7361, 6229, 7800 }, final = 7800,
	name = "Gnomeregan",
	title = { frFR = "Gnomeregan", deDE = "Gnomeregan", esES = "Gnomeregan", esMX = "Gnomeregan", ptBR = "Gnomeregan", ruRU = "Гномреган", koKR = "놈리건", zhCN = "诺莫瑞根" },
	tint = { 0.14, 0.30, 0.26 }, glow = { 0.50, 1.00, 0.70 },
	-- studio backdrop (card window and booster scene), pack, set mark
	studio = "StudioGnomeregan", pack = "PackGnomeregan", set = "SetGnomeregan",
	-- { npcID, rarity 1-6, creature type, family, min level, max level, displayID, sound kit, character }
	cards = {
		{ 7897, 1, 9, 0, 20, 20, 6888, 5762, false }, -- Alarm-a-bomb 2600
		{ 6207, 1, 7, 0, 25, 27, 764, 659, false }, -- Caverndeep Ambusher
		{ 6206, 1, 7, 0, 25, 27, 830, 659, false }, -- Caverndeep Burrower
		{ 6329, 1, 7, 0, 25, 26, 976, 659, false }, -- Irradiated Pillager
		{ 7849, 1, 9, 0, 25, 25, 6888, 5762, false }, -- Mobile Alert System
		{ 6211, 1, 7, 0, 27, 28, 10285, 659, false }, -- Caverndeep Reaver
		{ 6218, 1, 10, 0, 27, 28, 358, 724, false }, -- Irradiated Slime
		{ 6220, 1, 4, 0, 28, 29, 4907, 724, false }, -- Irradiated Horror
		{ 7603, 1, 7, 0, 28, 29, 6967, 1039, false }, -- Leprous Assistant
		{ 6223, 1, 7, 0, 28, 29, 6982, 3269, false }, -- Leprous Defender
		{ 6233, 1, 9, 0, 28, 29, 6978, 4419, false }, -- Mechanized Sentry
		{ 6224, 1, 7, 0, 29, 30, 6936, 1039, false }, -- Leprous Machinesmith
		{ 6222, 1, 7, 0, 29, 30, 6932, 1039, false }, -- Leprous Technician
		{ 6225, 1, 9, 0, 29, 30, 5926, 4319, false }, -- Mechano-Tank
		{ 9676, 2, 7, 0, 24, 24, 9027, 5922, true }, -- Tink Sprocketwhistle
		{ 6219, 2, 10, 0, 28, 29, 11137, 724, false }, -- Corrosive Lurker
		{ 6392, 2, 7, 0, 29, 30, 6608, 5928, true }, -- Holdout Medic
		{ 6226, 2, 9, 0, 30, 31, 6890, 4319, false }, -- Mechano-Flamewalker
		{ 6230, 2, 9, 0, 30, 30, 8369, 4319, false }, -- Peacekeeper Security Suit
		{ 6234, 2, 9, 0, 31, 32, 6979, 4419, false }, -- Mechanized Guardian
		{ 6227, 2, 9, 0, 31, 32, 6891, 4319, false }, -- Mechano-Frostwalker
		{ 6232, 2, 9, 0, 32, 33, 6889, 4319, false }, -- Arcane Nullifier X-21
		{ 6212, 2, 7, 0, 32, 33, 3456, 1352, false }, -- Dark Iron Agent
		{ 7998, 3, 7, 0, 27, 27, 7138, 5931, true }, -- Blastmaster Emi Shortfuse
		{ 7850, 3, 7, 0, 28, 28, 7132, 5964, true }, -- Kernobee
		{ 6407, 3, 7, 0, 29, 30, 6628, 5925, true }, -- Holdout Technician
		{ 6228, 3, 7, 0, 33, 33, 6669, 1352, false }, -- Dark Iron Ambassador
		{ 7079, 4, 4, 0, 30, 30, 5497, 724, false }, -- Viscous Fallout
		{ 6235, 4, 9, 0, 32, 32, 6915, 4319, false }, -- Electrocutioner 6000
		{ 7361, 4, 7, 0, 32, 32, 6533, 659, false }, -- Grubbis
		{ 6229, 5, 9, 0, 32, 32, 6774, 4319, false }, -- Crowd Pummeler 9-60
		{ 7800, 6, 9, 0, 34, 34, 6980, 4319, false }, -- Mekgineer Thermaplugg
	},
	names = {
		enUS = {[7897] = "Alarm-a-bomb 2600", [6207] = "Caverndeep Ambusher", [6206] = "Caverndeep Burrower", [6329] = "Irradiated Pillager", [7849] = "Mobile Alert System", [6211] = "Caverndeep Reaver", [6218] = "Irradiated Slime", [6220] = "Irradiated Horror", [7603] = "Leprous Assistant", [6223] = "Leprous Defender", [6233] = "Mechanized Sentry", [6224] = "Leprous Machinesmith", [6222] = "Leprous Technician", [6225] = "Mechano-Tank", [9676] = "Tink Sprocketwhistle", [6219] = "Corrosive Lurker", [6392] = "Holdout Medic", [6226] = "Mechano-Flamewalker", [6230] = "Peacekeeper Security Suit", [6234] = "Mechanized Guardian", [6227] = "Mechano-Frostwalker", [6232] = "Arcane Nullifier X-21", [6212] = "Dark Iron Agent", [7998] = "Blastmaster Emi Shortfuse", [7850] = "Kernobee", [6407] = "Holdout Technician", [6228] = "Dark Iron Ambassador", [7079] = "Viscous Fallout", [6235] = "Electrocutioner 6000", [7361] = "Grubbis", [6229] = "Crowd Pummeler 9-60", [7800] = "Mekgineer Thermaplugg"},
		frFR = {[7897] = "Alarme-bombe 2600", [6207] = "Embusqué des Basses-cavernes", [6206] = "Creuseur des Basses-cavernes", [6329] = "Pilleur irradié", [7849] = "Système d'alarme mobile", [6211] = "Ravageur des Basses-cavernes", [6218] = "Gelée irradiée", [6220] = "Horreur irradiée", [7603] = "Assistant lépreux", [6223] = "Défenseur lépreux", [6233] = "Sentinelle mécanique", [6224] = "Forgeur de machines lépreux", [6222] = "Technicien lépreux", [6225] = "Mécano-Tank", [9676] = "Bricolo Sprocketwhistle", [6219] = "Rôdeur corrosif", [6392] = "Infirmier du Hangar", [6226] = "Mécano-Brûleur", [6230] = "Tenue de maintien de l'ordre", [6234] = "Gardien mécanique", [6227] = "Mécano-Glaceur", [6232] = "Annulateur d’Arcane X-21", [6212] = "Agent Sombrefer", [7998] = "Maître-dynamiteur Emi Shortfuse", [7850] = "Kernobee", [6407] = "Technicien du Hangar", [6228] = "Ambassadeur Sombrefer", [7079] = "Retombée visqueuse", [6235] = "Electrocuteur 6000", [7361] = "Grubbis", [6229] = "Faucheur de foule 9-60", [7800] = "Mekgénieur Thermaplugg"},
		deDE = {[7897] = "Bombenalarm 2600", [6207] = "Wegelagerer der Tiefentroggs", [6206] = "Einbuddler der Tiefentroggs", [6329] = "Bestrahlter Plünderer", [7849] = "Mobiles Alarmsystem", [6211] = "Häscher der Tiefentroggs", [6218] = "Bestrahlter Brühschleimer", [6220] = "Bestrahlter Schrecken", [7603] = "Aussätziger Gehilfe", [6223] = "Aussätziger Verteidiger", [6233] = "Mechanischer Wachposten", [6224] = "Aussätziger Maschinenschmied", [6222] = "Aussätziger Techniker", [6225] = "Mechanopanzer", [9676] = "Tink Sprocketwhistle", [6219] = "Ätzender Lauerer", [6392] = "Bastionssanitäter", [6226] = "Mechanoflammenwandler", [6230] = "Friedensbewahrer-Sicherheitsanzug", [6234] = "Mechanischer Wächter", [6227] = "Mechanofrostwandler", [6232] = "Arkaner Nullifizierer X-21", [6212] = "Agent der Dunkeleisenzwerge", [7998] = "Sprengmeisterin Emi Shortfuse", [7850] = "Kernobee", [6407] = "Bastionstechniker", [6228] = "Botschafter der Dunkeleisenzwerge", [7079] = "Verflüssigte Ablagerung", [6235] = "Elektrokutionator 6000", [7361] = "Grubbis", [6229] = "Meute-Verprügler 9-60", [7800] = "Robogenieur Thermaplugg"},
		esES = {[7897] = "Alarmabomba 2600", [6207] = "Emboscador Cueva Honda", [6206] = "Hurgador Cueva Honda", [6329] = "Saqueador irradiado", [7849] = "Sistema móvil de alarma", [6211] = "Atracador Cueva Honda", [6218] = "Babosa irradiada", [6220] = "Horror irradiado", [7603] = "Asistente leproso", [6223] = "Defensor leproso", [6233] = "Argos mecanizado", [6224] = "Maquinista leproso", [6222] = "Técnico leproso", [6225] = "Mecanotanque", [9676] = "Tink Silbadentado", [6219] = "Rondador corrosivo", [6392] = "Médico Negador", [6226] = "Caminallamas mecanizado", [6230] = "Traje de seguridad de Pacificador", [6234] = "Guardián mecanizado", [6227] = "Caminaescarcha mecanizado", [6232] = "Nulificador X21 Arcano", [6212] = "Agente Hierro Negro", [7998] = "Maestro Destructor Emi Plomocorto", [7850] = "Kernobee", [6407] = "Técnico Negador", [6228] = "Embajador Hierro Negro", [7079] = "Radiactivo viscoso", [6235] = "Electrocutor 6000", [7361] = "Grubbis", [6229] = "Golpeamasa 9-60", [7800] = "Mekigeniero Termochufe"},
		esMX = {[7897] = "Alarmabomba 2600", [6207] = "Emboscador Cueva Honda", [6206] = "Hurgador Cueva Honda", [6329] = "Saqueador irradiado", [7849] = "Sistema móvil de alarma", [6211] = "Atracador Cueva Honda", [6218] = "Babosa irradiada", [6220] = "Horror irradiado", [7603] = "Asistente leproso", [6223] = "Defensor leproso", [6233] = "Argos mecanizado", [6224] = "Maquinista leproso", [6222] = "Técnico leproso", [6225] = "Mecanotanque", [9676] = "Tink Silbadentado", [6219] = "Rondador corrosivo", [6392] = "Médico Negador", [6226] = "Caminallamas mecanizado", [6230] = "Traje de seguridad de Pacificador", [6234] = "Guardián mecanizado", [6227] = "Caminaescarcha mecanizado", [6232] = "Nulificador X21 Arcano", [6212] = "Agente Hierro Negro", [7998] = "Maestro Destructor Emi Plomocorto", [7850] = "Kernobee", [6407] = "Técnico Negador", [6228] = "Embajador Hierro Negro", [7079] = "Radiactivo viscoso", [6235] = "Electrocutor 6000", [7361] = "Grubbis", [6229] = "Golpeamasa 9-60", [7800] = "Mekigeniero Termochufe"},
		ptBR = {[7897] = "Bombalarme 2600", [6207] = "Emboscador de Furnafunda", [6206] = "Entocador de Furnafunda", [6329] = "Pilhador Irradiado", [7849] = "Sistema de Alerta Móvel", [6211] = "Aniquilador de Furnafunda", [6218] = "Visgo Irradiado", [6220] = "Horror Irradiado", [7603] = "Assistente Leproso", [6223] = "Defensor Leproso", [6233] = "Sentinela Mecanoide", [6224] = "Mecanista Leproso", [6222] = "Técnico Leproso", [6225] = "Mecanotanque", [9676] = "Plim Bobinapito", [6219] = "Tocaieiro Corrosivo", [6392] = "Médico do Hangar", [6226] = "Mecano-Fogâmbulo", [6230] = "Armadura de Segurança do Pacificador", [6234] = "Guardião Mecanoide", [6227] = "Mecano-Gelâmbulo", [6232] = "Nulificador Arcano X-21", [6212] = "Agente Ferro Negro", [7998] = "Estalomestre Emi Paviocurto", [7850] = "Kernobill", [6407] = "Técnico do Hangar", [6228] = "Embaixador Ferro Negro", [7079] = "Precipitação Radioativa Viscosa", [6235] = "Eletrocutor 6000", [7361] = "Grúdio", [6229] = "Espanca-gente 9-60", [7800] = "Mecangenheiro Termaplugue"},
		ruRU = {[7897] = "Тревого-бомба 2600", [6207] = "Душитель из пещерных глубин", [6206] = "Землеглот из пещерных глубин", [6329] = "Облученный погромщик", [7849] = "Мобильная охранная система", [6211] = "Разоритель из пещерных глубин", [6218] = "Облученная слизь", [6220] = "Облученный ужас", [7603] = "Прокаженный ассистент", [6223] = "Прокаженный защитник", [6233] = "Механический караульный", [6224] = "Прокаженный машиностроитель", [6222] = "Прокаженный техник", [6225] = "Механотанк", [9676] = "Звяк Пружиносвист", [6219] = "Едкий скрытень", [6392] = "Медик зоны", [6226] = "Механический пламеход", [6230] = "Защитный скафандр миротворца", [6234] = "Механический страж", [6227] = "Механический ледоступ", [6232] = "Волшебный обнулятор X-21", [6212] = "Посланник из клана Черного Железа", [7998] = "Взрывник Ими Фитилюшка", [7850] = "Керноби", [6407] = "Техник зоны", [6228] = "Посол из клана Черного Железа", [7079] = "Липкая муть", [6235] = "Электрошокер 6000", [7361] = "Грязнюк", [6229] = "Толпогон 9-60", [7800] = "Мекжинер Термоштепсель"},
		koKR = {[7897] = "경보폭탄 2600", [6207] = "깊은굴일족 복병", [6206] = "깊은굴일족 땅꾼", [6329] = "오염된 약탈자", [7849] = "이동 경보 장치", [6211] = "깊은굴일족 약탈꾼", [6218] = "방사능 진흙괴물", [6220] = "오염된 폐기물", [7603] = "오염된 노움 조수", [6223] = "오염된 노움 수호병", [6233] = "기계화 보초병", [6224] = "오염된 노움 기계공", [6222] = "오염된 노움 기술병", [6225] = "기계화 보행전차", [9676] = "팅크 스프로켓휘슬", [6219] = "부식성 녹괴물", [6392] = "저항군 의무병", [6226] = "기계화 화염보행전차", [6230] = "평화감시단 방사능처리반", [6234] = "기계화 수호병", [6227] = "기계화 냉기보행전차", [6232] = "자동화 마력제거기 X-21", [6212] = "검은무쇠단 첩보원", [7998] = "폭발물전문가 에미 쇼트퓨즈", [7850] = "케르노비", [6407] = "저항군 기술병", [6228] = "검은무쇠단 사절", [7079] = "방사성 폐기물", [6235] = "기계화 문지기 6000", [7361] = "그루비스", [6229] = "고철 압축기 9-60", [7800] = "멕기니어 텔마플러그"},
		zhCN = {[7897] = "警报炸弹2600型", [6207] = "洞窟伏击者", [6206] = "洞窟穴居者", [6329] = "辐射抢劫者", [7849] = "移动警报系统", [6211] = "洞窟劫掠者", [6218] = "辐射泥浆怪", [6220] = "辐射水元素", [7603] = "麻疯助手", [6223] = "麻疯防御者", [6233] = "机械哨兵", [6224] = "麻疯机械师", [6222] = "麻疯技师", [6225] = "步行坦克", [9676] = "丁克·铁哨", [6219] = "酸性潜伏者", [6392] = "躲起来的医师", [6226] = "机械烈焰行者", [6230] = "动力保安装甲", [6234] = "机械守护者", [6227] = "机械冰霜行者", [6232] = "施法者克星X-21", [6212] = "黑铁密探", [7998] = "爆破专家艾米·短线", [7850] = "克努比", [6407] = "躲起来的技师", [6228] = "黑铁大师", [7079] = "粘性辐射尘", [6235] = "电刑器6000型", [7361] = "格鲁比斯", [6229] = "群体打击者9-60", [7800] = "麦克尼尔·瑟玛普拉格"},
		zhTW = {[7897] = "警報炸彈2600型", [6207] = "洞窟伏擊者", [6206] = "洞窟穴居者", [6329] = "輻射掠取者", [7849] = "移動警報系統", [6211] = "洞窟搶奪者", [6218] = "輻射泥漿怪", [6220] = "輻射水元素", [7603] = "麻瘋助手", [6223] = "麻瘋防衛者", [6233] = "機械哨兵", [6224] = "麻瘋機械師", [6222] = "麻瘋技師", [6225] = "步行坦克", [9676] = "丁克·鐵哨", [6219] = "酸性潛伏者", [6392] = "躲起來的醫師", [6226] = "機械烈焰行者", [6230] = "動力保安裝甲", [6234] = "機械守護者", [6227] = "機械冰霜行者", [6232] = "秘法剋星X-21", [6212] = "黑鐵密探", [7998] = "爆破專家艾米·短路", [7850] = "克努比", [6407] = "躲起來的技師", [6228] = "黑鐵大使", [7079] = "粘性輻射塵", [6235] = "電刑器6000型", [7361] = "格魯比斯", [6229] = "群體打擊者9-60", [7800] = "麥克尼爾·瑟瑪普拉格"},
	},
	subs = {
		enUS = {[9676] = "Engineering Supplies"},
		frFR = {[9676] = "Fournitures d'ingénieur"},
		deDE = {[9676] = "Ingenieursbedarf"},
		esES = {[9676] = "Suministros de ingeniería"},
		esMX = {[9676] = "Suministros de ingeniería"},
		ptBR = {[9676] = "Suprimentos de Engenharia"},
		ruRU = {[9676] = "Инженерные материалы"},
		koKR = {[9676] = "기술용품 상인"},
		zhCN = {[9676] = "工程学供应商"},
		zhTW = {[9676] = "工程學供應商"},
	},
}
