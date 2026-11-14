local _, ns = "Curator", CuratorOctoFull

-- (1.13.0) The words of 1.13.0: the contents of the album by kind (a tab each, the filters of the zones), the album of
-- the Hardcup Saison 3 and the gift codes that give its cards. They go into the tables of Locale.lua (English keys; a
-- missing one falls back to English).
local T = ns.LocaleTables

local function Add(locale, words)
	local dst = T and T[locale]
	if not dst then
		return
	end
	for k, v in pairs(words) do
		dst[k] = v
	end
end

Add("frFR", {
	["Zones"] = "Zones",
	["All zones"] = "Toutes",
	["Albums complete: %d / %d"] = "Albums complets : %d / %d",
	["No album here yet."] = "Aucun album ici pour l'instant.",
	["By level"] = "Par niveau",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "Par niveau. Un booster de donjon : 5 cartes, chacune rare, épique ou légendaire.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "Dans l'ordre du jeu. Un booster de raid : 5 cartes, chacune rare, épique ou légendaire.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "Tes ennemis vaincus, les albums des champs de bataille et leurs exploits : clique sur l'un d'eux pour le voir.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "Des éditions limitées : leurs cartes ne viennent que de leur événement, et ne comptent dans aucun total de la collection.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "Ses cartes viennent de la Hardcup Saison 3, un événement de WoW Classic : le site donne à ses joueurs les leurs dans un code cadeau.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "Tous les albums, par sorte : les zones (par niveau, par continent), les donjons, les raids, le JcJ et les événements, et où tu en es dans chacun. Clique sur l'un d'eux pour l'ouvrir.",
	["No booster for this album: its cards come from a gift code of the website."] = "Aucun booster pour cet album : ses cartes viennent d'un code cadeau du site.",
	["%s: 1 card"] = "%s : 1 carte",
	["%s: %d cards"] = "%s : %d cartes",
	["(%d copies)"] = "(%d exemplaires)",
})

Add("deDE", {
	["Zones"] = "Gebiete",
	["All zones"] = "Alle",
	["Albums complete: %d / %d"] = "Vollständige Alben: %d / %d",
	["No album here yet."] = "Hier gibt es noch kein Album.",
	["By level"] = "Nach Stufe",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "Nach Stufe. Ein Dungeon-Booster: 5 Karten, jede selten, episch oder legendär.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "In der Reihenfolge des Spiels. Ein Schlachtzug-Booster: 5 Karten, jede selten, episch oder legendär.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "Deine besiegten Feinde, die Alben der Schlachtfelder und ihre Waffentaten: Klick auf eines, um es anzusehen.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "Limitierte Ausgaben: Ihre Karten gibt es nur bei ihrem Event, und sie zählen in keiner Gesamtzahl der Sammlung.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "Seine Karten stammen aus der Hardcup Saison 3, einem Event in WoW Classic: Die Website gibt seinen Spielern ihre Karten in einem Geschenkcode.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "Alle Alben, nach Art: die Gebiete (nach Stufe, nach Kontinent), die Dungeons, die Schlachtzüge, das PvP und die Events, und wie weit du in jedem bist. Klick auf eines, um es zu öffnen.",
	["No booster for this album: its cards come from a gift code of the website."] = "Kein Booster für dieses Album: Seine Karten stammen aus einem Geschenkcode der Website.",
	["%s: 1 card"] = "%s: 1 Karte",
	["%s: %d cards"] = "%s: %d Karten",
	["(%d copies)"] = "(%d Exemplare)",
})

Add("esES", {
	["Zones"] = "Zonas",
	["All zones"] = "Todas",
	["Albums complete: %d / %d"] = "Álbumes completos: %d / %d",
	["No album here yet."] = "Aún no hay ningún álbum aquí.",
	["By level"] = "Por nivel",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "Por nivel. Un sobre de mazmorra: 5 cartas, cada una rara, épica o legendaria.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "En el orden del juego. Un sobre de banda: 5 cartas, cada una rara, épica o legendaria.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "Tus enemigos derrotados, los álbumes de los campos de batalla y sus hazañas: haz clic en uno para verlo.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "Ediciones limitadas: sus cartas solo vienen de su evento y no cuentan en ningún total de la colección.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "Sus cartas vienen de la Hardcup Saison 3, un evento de WoW Classic: la web da a sus jugadores las suyas en un código de regalo.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "Todos los álbumes, por tipo: las zonas (por nivel, por continente), las mazmorras, las bandas, el JcJ y los eventos, y cuánto llevas de cada uno. Haz clic en uno para abrirlo.",
	["No booster for this album: its cards come from a gift code of the website."] = "Ningún sobre para este álbum: sus cartas vienen de un código de regalo de la web.",
	["%s: 1 card"] = "%s: 1 carta",
	["%s: %d cards"] = "%s: %d cartas",
	["(%d copies)"] = "(%d copias)",
})

Add("ptBR", {
	["Zones"] = "Zonas",
	["All zones"] = "Todas",
	["Albums complete: %d / %d"] = "Álbuns completos: %d / %d",
	["No album here yet."] = "Ainda não há nenhum álbum aqui.",
	["By level"] = "Por nível",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "Por nível. Um pacote de masmorra: 5 cartas, cada uma rara, épica ou lendária.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "Na ordem do jogo. Um pacote de raide: 5 cartas, cada uma rara, épica ou lendária.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "Seus inimigos derrotados, os álbuns dos campos de batalha e suas proezas: clique em um para vê-lo.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "Edições limitadas: as cartas delas só vêm do seu evento e não contam em nenhum total da coleção.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "As cartas dele vêm da Hardcup Saison 3, um evento de WoW Classic: o site dá aos jogadores as suas em um código de presente.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "Todos os álbuns, por tipo: as zonas (por nível, por continente), as masmorras, as raides, o JxJ e os eventos, e quanto você já tem de cada um. Clique em um para abri-lo.",
	["No booster for this album: its cards come from a gift code of the website."] = "Nenhum pacote para este álbum: as cartas dele vêm de um código de presente do site.",
	["%s: 1 card"] = "%s: 1 carta",
	["%s: %d cards"] = "%s: %d cartas",
	["(%d copies)"] = "(%d cópias)",
})

Add("ruRU", {
	["Zones"] = "Зоны",
	["All zones"] = "Все",
	["Albums complete: %d / %d"] = "Собранные альбомы: %d / %d",
	["No album here yet."] = "Здесь пока нет альбомов.",
	["By level"] = "По уровню",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "По уровню. Бустер подземелья: 5 карт, каждая редкая, эпическая или легендарная.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "В порядке игры. Бустер рейда: 5 карт, каждая редкая, эпическая или легендарная.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "Побеждённые враги, альбомы полей боя и ратные подвиги: нажмите на альбом, чтобы открыть его.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "Ограниченные издания: их карты бывают только во время их события и не входят ни в один итог коллекции.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "Его карты пришли с Hardcup Saison 3, события в WoW Classic: сайт выдаёт игрокам их карты подарочным кодом.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "Все альбомы по видам: зоны (по уровню и континенту), подземелья, рейды, PvP и события, и ваш прогресс в каждом. Нажмите на альбом, чтобы открыть его.",
	["No booster for this album: its cards come from a gift code of the website."] = "Для этого альбома нет бустеров: его карты выдаются подарочным кодом с сайта.",
	["%s: 1 card"] = "%s: 1 карта",
	["%s: %d cards"] = "%s, карт: %d",
	["(%d copies)"] = "(копий: %d)",
})

Add("koKR", {
	["Zones"] = "지역",
	["All zones"] = "전체",
	["Albums complete: %d / %d"] = "완성한 앨범: %d / %d",
	["No album here yet."] = "아직 여기에 앨범이 없습니다.",
	["By level"] = "레벨순",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "레벨순. 던전 부스터: 카드 5장, 각각 희귀, 영웅 또는 전설.",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "게임 순서대로. 공격대 부스터: 카드 5장, 각각 희귀, 영웅 또는 전설.",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "쓰러뜨린 적, 전장 앨범과 전공: 클릭하면 볼 수 있습니다.",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "한정판: 카드는 해당 이벤트에서만 얻을 수 있으며, 수집 합계에 포함되지 않습니다.",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "이 앨범의 카드는 WoW 클래식의 이벤트인 Hardcup Saison 3에서 왔습니다. 웹사이트가 참가자에게 선물 코드로 카드를 줍니다.",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "종류별 모든 앨범: 지역(레벨별, 대륙별), 던전, 공격대, PvP, 이벤트와 각 앨범의 진행도입니다. 앨범을 클릭하면 열립니다.",
	["No booster for this album: its cards come from a gift code of the website."] = "이 앨범에는 부스터가 없습니다. 카드는 웹사이트의 선물 코드로 받습니다.",
	["%s: 1 card"] = "%s: 카드 1장",
	["%s: %d cards"] = "%s: 카드 %d장",
	["(%d copies)"] = "(%d장 보유)",
})

Add("zhCN", {
	["Zones"] = "地区",
	["All zones"] = "全部",
	["Albums complete: %d / %d"] = "集齐的收藏册：%d / %d",
	["No album here yet."] = "这里还没有收藏册。",
	["By level"] = "按等级",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "按等级排列。地下城补充包：5张卡牌，每张为精良、史诗或传说。",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "按游戏中的顺序排列。团队副本补充包：5张卡牌，每张为精良、史诗或传说。",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "你击败的敌人、战场收藏册及其战功：点击一本即可查看。",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "限定版：其卡牌只来自对应的活动，不计入收藏的任何总数。",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "这本收藏册的卡牌来自经典怀旧服的活动 Hardcup Saison 3：网站会以礼品码的形式发给参与的玩家。",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "按类别列出的所有收藏册：地区（按等级、按大陆）、地下城、团队副本、PvP和活动，以及你在每本中的进度。点击一本即可打开。",
	["No booster for this album: its cards come from a gift code of the website."] = "这本收藏册没有补充包：其卡牌来自网站的礼品码。",
	["%s: 1 card"] = "%s：1张卡牌",
	["%s: %d cards"] = "%s：%d张卡牌",
	["(%d copies)"] = "（共%d张）",
})

Add("zhTW", {
	["Zones"] = "地區",
	["All zones"] = "全部",
	["Albums complete: %d / %d"] = "集齊的收藏冊：%d / %d",
	["No album here yet."] = "這裡還沒有收藏冊。",
	["By level"] = "按等級",
	["By level. A booster of a dungeon: 5 cards, each rare, epic or legendary."] = "按等級排列。地城補充包：5張卡牌，每張為精良、史詩或傳說。",
	["In the order of the game. A booster of a raid: 5 cards, each rare, epic or legendary."] = "按遊戲中的順序排列。團隊副本補充包：5張卡牌，每張為精良、史詩或傳說。",
	["Your enemies defeated, the albums of the battlegrounds and their exploits: click one to see it."] = "你擊敗的敵人、戰場收藏冊及其戰功：點擊一本即可查看。",
	["Limited editions: their cards come only from their event, and count in no total of the collection."] = "限定版：其卡牌只來自對應的活動，不計入收藏的任何總數。",
	["Its cards come from the Hardcup Saison 3, an event of WoW Classic: the website gives its players theirs in a gift code."] = "這本收藏冊的卡牌來自經典版的活動 Hardcup Saison 3：網站會以禮物碼的形式發給參與的玩家。",
	["Every album, by kind: the zones (by level, by continent), the dungeons, the raids, the PvP and the events, and how far you are in each. Click one to open it."] = "按類別列出的所有收藏冊：地區（按等級、按大陸）、地城、團隊副本、PvP和活動，以及你在每本中的進度。點擊一本即可開啟。",
	["No booster for this album: its cards come from a gift code of the website."] = "這本收藏冊沒有補充包：其卡牌來自網站的禮物碼。",
	["%s: 1 card"] = "%s：1張卡牌",
	["%s: %d cards"] = "%s：%d張卡牌",
	["(%d copies)"] = "（共%d張）",
})
