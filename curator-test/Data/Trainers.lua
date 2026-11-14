local _, ns = "Curator", CuratorOctoFull

-- (1.12.0) The masters of the classes who keep the corrupted cards (Seal.lua), from QuestieDB (Forever): the
-- warlock trainers (a Master of Warlocks seals a corrupted card) and the priest trainers (a Master of Priests
-- purifies one). [npc] = its faction (A, H).
ns.WARLOCK_MASTERS = {
	[459] = "A", -- Drusilla La Salle
	[460] = "A", -- Alamar Grimm
	[461] = "A", -- Demisette Cloyce
	[906] = "A", -- Maximillian Crowe
	[988] = "H", -- Kartosh
	[2126] = "H", -- Maximillion
	[2127] = "H", -- Rupert Boch
	[3156] = "H", -- Nartok
	[3172] = "H", -- Dhugru Gorelust
	[3324] = "H", -- Grol'dar
	[3325] = "H", -- Mirket
	[3326] = "H", -- Zevrost
	[4563] = "H", -- Kaal Soulreaper
	[4564] = "H", -- Luther Pickman
	[4565] = "H", -- Richard Kerwin
	[5171] = "A", -- Thistleheart
	[5172] = "A", -- Briarthorn
	[5173] = "A", -- Alexander Calder
	[5495] = "A", -- Ursula Deline
	[5496] = "A", -- Sandahl
	[5612] = "A", -- Gimrizz Shadowcog
}
ns.PRIEST_MASTERS = {
	[375] = "A", -- Priestess Anetta
	[376] = "A", -- High Priestess Laurena
	[377] = "A", -- Priestess Josetta
	[837] = "A", -- Branstock Khalder
	[1226] = "A", -- Maxan Anvol
	[2123] = "H", -- Dark Cleric Duesten
	[2129] = "H", -- Dark Cleric Beryl
	[3044] = "H", -- Miles Welsh
	[3045] = "H", -- Malakai Cross
	[3046] = "H", -- Father Cobb
	[3595] = "A", -- Shanda
	[3600] = "A", -- Laurna Morninglight
	[3706] = "H", -- Tai'jin
	[3707] = "H", -- Ken'jai
	[4090] = "A", -- Astarii Starseeker
	[4091] = "A", -- Jandria
	[4092] = "A", -- Lariia
	[4606] = "H", -- Aelthalyste
	[4607] = "H", -- Father Lankester
	[4608] = "H", -- Father Lazarus
	[5141] = "A", -- Theodrus Frostbeard
	[5142] = "A", -- Braenna Flintcrag
	[5143] = "A", -- Toldren Deepiron
	[5484] = "A", -- Brother Benjamin
	[5489] = "A", -- Brother Joshua
	[6014] = "H", -- X'yera
	[6018] = "H", -- Ur'kyo
	[11397] = "A", -- Nara Meideros
	[11401] = "A", -- Priestess Alathea
	[11406] = "A", -- High Priest Rohan
}

-- (1.14.0, 1 November, his idea: « les maîtres des mages analysent les titanforged ») The masters of the mages who
-- certify a titanforged copy (Mages.lua), from QuestieDB (Forever): the mage trainers (the World Mage Trainers and
-- Haka'wani, nowhere in the world, left out). [npc] = its faction (A, H).
ns.MAGE_MASTERS = {
	[198] = "A", -- Khelden Bremen
	[328] = "A", -- Zaldimar Wefhellt
	[944] = "A", -- Marryk Nurribit
	[1228] = "A", -- Magis Sparkmantle
	[2124] = "H", -- Isabella
	[2128] = "H", -- Cain Firesong
	[3047] = "H", -- Archmage Shymm
	[3048] = "H", -- Ursyn Ghull
	[3049] = "H", -- Thurston Xane
	[4566] = "H", -- Kaelystia Hatebringer
	[4567] = "H", -- Pierce Shackleton
	[4568] = "H", -- Anastasia Hartwell
	[5144] = "A", -- Bink
	[5145] = "A", -- Juli Stormkettle
	[5146] = "A", -- Nittlebur Sparkfizzle
	[5497] = "A", -- Jennea Cannon
	[5498] = "A", -- Elsharin
	[5880] = "H", -- Un'Thuwa
	[5882] = "H", -- Pephredo
	[5883] = "H", -- Enyo
	[5884] = "H", -- Mai'ah
	[5885] = "H", -- Deino
	[7311] = "H", -- Uthel'nay
	[7312] = "A", -- Dink
}
-- Their names in each language of the game (the same base): the English first, then each language that says it
-- otherwise. A certificate keeps the number of its master: his name read in the language of whoever reads it.
ns.MAGE_MASTER_NAMES = {
	[198] = { "Khelden Bremen", ptBR = "Gaspar Melchior", ruRU = "Кельден Бремен", koKR = "켈덴 브레멘", zhCN = "凯尔登·布雷门", zhTW = "凱爾登·布雷門" },
	[328] = { "Zaldimar Wefhellt", ruRU = "Залдимар Вефхеллт", koKR = "잘디마르 웨펠트", zhCN = "扎尔迪玛·维夫希尔特", zhTW = "札爾迪瑪·維夫希爾特" },
	[944] = { "Marryk Nurribit", ruRU = "Маррик Нуррибит", koKR = "마릭 너리빗", zhCN = "玛瑞克·斯托纳尔", zhTW = "瑪瑞克·斯托納爾" },
	[1228] = { "Magis Sparkmantle", esES = "Magis Chispamanto", esMX = "Magis Chispamanto", ptBR = "Magis Fagulhamanto", ruRU = "Магис Искроплащ", koKR = "마지스 스파크맨틀", zhCN = "玛济斯·石衣", zhTW = "瑪濟斯·石衣" },
	[2124] = { "Isabella", ruRU = "Изабелла", koKR = "이자벨라", zhCN = "伊莎贝拉", zhTW = "伊莎貝拉" },
	[2128] = { "Cain Firesong", esES = "Cain Pirosón", esMX = "Cain Pirosón", ptBR = "Caio Cantígnea", ruRU = "Кейн Песнь Пламени", koKR = "케인 파이어송", zhCN = "凯恩·火歌", zhTW = "凱恩·火歌" },
	[3047] = { "Archmage Shymm", frFR = "Archimage Shymm", deDE = "Erzmagier Shymm", esES = "Archimago Shymm", esMX = "Archimago Shymm", ptBR = "Arquimago Shymm", ruRU = "Верховный маг Шимм", koKR = "대마법사 심", zhCN = "大法师山姆", zhTW = "大法師山姆" },
	[3048] = { "Ursyn Ghull", ptBR = "Ursyn Karnissa", ruRU = "Урсин Гуль", koKR = "울신 굴", zhCN = "奥松·格鲁尔", zhTW = "奧松·格盧爾" },
	[3049] = { "Thurston Xane", ruRU = "Тюрстон Ксейн", koKR = "더스턴 제인", zhCN = "瑟斯顿·科萨恩", zhTW = "瑟斯頓·科薩恩" },
	[4566] = { "Kaelystia Hatebringer", esES = "Kaelystia Aversión", esMX = "Kaelystia Aversión", ptBR = "Kaelystia Odiosa", ruRU = "Келестия Ненавистница", koKR = "캘리스티아 헤이트브링어", zhCN = "凯利斯蒂亚", zhTW = "凱利斯蒂亞" },
	[4567] = { "Pierce Shackleton", esES = "Pierce Esqueletonio", esMX = "Pierce Esqueletonio", ptBR = "Frederico Grilhões", ruRU = "Пирс Шеклтон", koKR = "피어스 섀클턴", zhCN = "皮尔斯·沙克尔顿", zhTW = "皮爾斯·沙克爾頓" },
	[4568] = { "Anastasia Hartwell", ptBR = "Anastácia Cordato", ruRU = "Анастасия Хартвелл", koKR = "아나스타샤 하트웰", zhCN = "安娜斯塔西娅·哈特威尔", zhTW = "安娜斯塔西婭·哈特威爾" },
	[5144] = { "Bink", ruRU = "Бинк", koKR = "빙크", zhCN = "彬克", zhTW = "彬克" },
	[5145] = { "Juli Stormkettle", esES = "Juli Tormentacaldera", esMX = "Juli Tormentacaldera", ptBR = "Juli Tachofundo", ruRU = "Джули Скороварга", koKR = "율리 스톰케틀", zhCN = "朱莉·雷线", zhTW = "朱莉·雷線" },
	[5146] = { "Nittlebur Sparkfizzle", esES = "Nittlebur Chispancio", esMX = "Nittlebur Chispancio", ptBR = "Nitlebur Faiscrispa", ruRU = "Ниттльбур Шумогам", koKR = "니틀부르 스파크피즐", zhCN = "尼特布尔·火花", zhTW = "尼特布林·火花" },
	[5497] = { "Jennea Cannon", ptBR = "Jana Catão", ruRU = "Джинния Пушка", koKR = "제니아 캐논", zhCN = "詹妮亚·坎农", zhTW = "詹妮亞·坎農" },
	[5498] = { "Elsharin", ruRU = "Эльшарина", koKR = "엘샤린", zhCN = "艾尔莎林", zhTW = "艾爾莎林" },
	[5880] = { "Un'Thuwa", ruRU = "Ун'Тува", koKR = "운투와", zhCN = "安苏瓦", zhTW = "安蘇瓦" },
	[5882] = { "Pephredo", ptBR = "Pefreda", ruRU = "Пефредо", koKR = "페프레도", zhCN = "皮菲瑞多", zhTW = "皮菲瑞多" },
	[5883] = { "Enyo", ptBR = "Ênia", ruRU = "Энио", koKR = "엔요", zhCN = "恩尤", zhTW = "恩尤" },
	[5884] = { "Mai'ah", ruRU = "Май'ах", koKR = "마이아", zhCN = "迈安", zhTW = "邁安" },
	[5885] = { "Deino", ptBR = "Denya", ruRU = "Дейно", koKR = "다이노", zhCN = "迪诺", zhTW = "迪諾" },
	[7311] = { "Uthel'nay", ruRU = "Утель'най", koKR = "우텔나이", zhCN = "尤塞尔奈", zhTW = "尤塞爾奈" },
	[7312] = { "Dink", ruRU = "Динк", koKR = "딩크", zhCN = "丁克", zhTW = "丁克" },
}
