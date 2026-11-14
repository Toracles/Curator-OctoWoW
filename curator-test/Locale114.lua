local _, ns = "Curator", CuratorOctoFull

-- (1.14.0) The words of 1.14.0: the opening of a case (UI/Crate.lua, UI/CrateCard.lua), its ranks of its own. They go
-- into the tables of Locale.lua (English keys; a missing one falls back to English).
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
	["Test case"] = "Caisse d'essai",
	["A preview of the opening: random cards, nothing is kept."] = "Un aperçu de l'ouverture : des cartes au hasard, rien n'est gardé.",
	["Open the case"] = "Ouvrir la caisse",
	["Open another case"] = "Ouvrir une autre caisse",
	["Turn it with the mouse."] = "Tourne-la avec la souris.",
	["Contains one of the following:"] = "Contient l'une des cartes suivantes :",
	["Restricted"] = "Restreint",
	["Classified"] = "Classifié",
	["Covert"] = "Secret",
	["Priceless"] = "Inestimable",
	["Priceless card"] = "Carte inestimable",
	["A weapon of legend. Which one stays a mystery."] = "Une arme de légende. Laquelle, ça reste un mystère.",
	["Click a card to inspect it."] = "Clique sur une carte pour l'inspecter.",
	["Click anywhere to close."] = "Clique n'importe où pour fermer.",
	["A creature of %s, for the test."] = "Une créature de %s, pour l'essai.",
	["Rank 14 weapon"] = "Arme de rang 14",
})

Add("deDE", {
	["Test case"] = "Testkiste",
	["A preview of the opening: random cards, nothing is kept."] = "Eine Vorschau der Öffnung: zufällige Karten, nichts wird behalten.",
	["Open the case"] = "Kiste öffnen",
	["Open another case"] = "Noch eine Kiste öffnen",
	["Turn it with the mouse."] = "Mit der Maus drehen.",
	["Contains one of the following:"] = "Enthält eine der folgenden Karten:",
	["Restricted"] = "Eingeschränkt",
	["Classified"] = "Klassifiziert",
	["Covert"] = "Verdeckt",
	["Priceless"] = "Unbezahlbar",
	["Priceless card"] = "Unbezahlbare Karte",
	["A weapon of legend. Which one stays a mystery."] = "Eine legendäre Waffe. Welche, bleibt ein Rätsel.",
	["Click a card to inspect it."] = "Klicke auf eine Karte, um sie anzusehen.",
	["Click anywhere to close."] = "Klicke irgendwo, um zu schließen.",
	["A creature of %s, for the test."] = "Eine Kreatur aus %s, für den Test.",
	["Rank 14 weapon"] = "Waffe des Rangs 14",
})

Add("esES", {
	["Test case"] = "Caja de prueba",
	["A preview of the opening: random cards, nothing is kept."] = "Una vista previa de la apertura: cartas al azar, no se guarda nada.",
	["Open the case"] = "Abrir la caja",
	["Open another case"] = "Abrir otra caja",
	["Turn it with the mouse."] = "Gírala con el ratón.",
	["Contains one of the following:"] = "Contiene una de las siguientes cartas:",
	["Restricted"] = "Restringido",
	["Classified"] = "Clasificado",
	["Covert"] = "Encubierto",
	["Priceless"] = "Invaluable",
	["Priceless card"] = "Carta invaluable",
	["A weapon of legend. Which one stays a mystery."] = "Un arma de leyenda. Cuál es, sigue siendo un misterio.",
	["Click a card to inspect it."] = "Haz clic en una carta para inspeccionarla.",
	["Click anywhere to close."] = "Haz clic en cualquier lugar para cerrar.",
	["A creature of %s, for the test."] = "Una criatura de %s, para la prueba.",
	["Rank 14 weapon"] = "Arma de rango 14",
})

Add("esMX", {
	["Test case"] = "Caja de prueba",
	["A preview of the opening: random cards, nothing is kept."] = "Una vista previa de la apertura: cartas al azar, no se guarda nada.",
	["Open the case"] = "Abrir la caja",
	["Open another case"] = "Abrir otra caja",
	["Turn it with the mouse."] = "Gírala con el mouse.",
	["Contains one of the following:"] = "Contiene una de las siguientes cartas:",
	["Restricted"] = "Restringido",
	["Classified"] = "Clasificado",
	["Covert"] = "Encubierto",
	["Priceless"] = "Invaluable",
	["Priceless card"] = "Carta invaluable",
	["A weapon of legend. Which one stays a mystery."] = "Un arma de leyenda. Cuál es, sigue siendo un misterio.",
	["Click a card to inspect it."] = "Haz clic en una carta para inspeccionarla.",
	["Click anywhere to close."] = "Haz clic en cualquier lugar para cerrar.",
	["A creature of %s, for the test."] = "Una criatura de %s, para la prueba.",
	["Rank 14 weapon"] = "Arma de rango 14",
})

Add("ptBR", {
	["Test case"] = "Caixa de teste",
	["A preview of the opening: random cards, nothing is kept."] = "Uma prévia da abertura: cartas aleatórias, nada é guardado.",
	["Open the case"] = "Abrir a caixa",
	["Open another case"] = "Abrir outra caixa",
	["Turn it with the mouse."] = "Gire-a com o mouse.",
	["Contains one of the following:"] = "Contém uma das seguintes cartas:",
	["Restricted"] = "Restrito",
	["Classified"] = "Confidencial",
	["Covert"] = "Secreto",
	["Priceless"] = "Inestimável",
	["Priceless card"] = "Carta inestimável",
	["A weapon of legend. Which one stays a mystery."] = "Uma arma lendária. Qual é, continua um mistério.",
	["Click a card to inspect it."] = "Clique em uma carta para inspecioná-la.",
	["Click anywhere to close."] = "Clique em qualquer lugar para fechar.",
	["A creature of %s, for the test."] = "Uma criatura de %s, para o teste.",
	["Rank 14 weapon"] = "Arma de patente 14",
})

Add("ruRU", {
	["Test case"] = "Пробный ящик",
	["A preview of the opening: random cards, nothing is kept."] = "Предпросмотр открытия: случайные карты, ничего не сохраняется.",
	["Open the case"] = "Открыть ящик",
	["Open another case"] = "Открыть ещё один ящик",
	["Turn it with the mouse."] = "Поверните его мышью.",
	["Contains one of the following:"] = "Содержит одну из следующих карт:",
	["Restricted"] = "Запрещённое",
	["Classified"] = "Засекреченное",
	["Covert"] = "Тайное",
	["Priceless"] = "Бесценное",
	["Priceless card"] = "Бесценная карта",
	["A weapon of legend. Which one stays a mystery."] = "Легендарное оружие. Какое именно, остаётся загадкой.",
	["Click a card to inspect it."] = "Нажмите на карту, чтобы рассмотреть её.",
	["Click anywhere to close."] = "Нажмите где угодно, чтобы закрыть.",
	["A creature of %s, for the test."] = "Существо из альбома «%s», для теста.",
	["Rank 14 weapon"] = "Оружие 14-го звания",
})

Add("koKR", {
	["Test case"] = "테스트 상자",
	["A preview of the opening: random cards, nothing is kept."] = "개봉 미리보기: 무작위 카드이며, 아무것도 보관되지 않습니다.",
	["Open the case"] = "상자 열기",
	["Open another case"] = "다른 상자 열기",
	["Turn it with the mouse."] = "마우스로 돌려 보세요.",
	["Contains one of the following:"] = "다음 카드 중 하나가 들어 있습니다:",
	["Restricted"] = "제한됨",
	["Classified"] = "기밀",
	["Covert"] = "은밀",
	["Priceless"] = "무가지보",
	["Priceless card"] = "무가지보 카드",
	["A weapon of legend. Which one stays a mystery."] = "전설의 무기입니다. 어떤 무기인지는 수수께끼입니다.",
	["Click a card to inspect it."] = "카드를 클릭하면 자세히 볼 수 있습니다.",
	["Click anywhere to close."] = "아무 곳이나 클릭하면 닫힙니다.",
	["A creature of %s, for the test."] = "%s의 생물입니다. 테스트용입니다.",
	["Rank 14 weapon"] = "14계급 무기",
})

Add("zhCN", {
	["Test case"] = "测试箱",
	["A preview of the opening: random cards, nothing is kept."] = "开箱预览：随机卡牌，不会保留任何东西。",
	["Open the case"] = "打开箱子",
	["Open another case"] = "再开一个箱子",
	["Turn it with the mouse."] = "用鼠标转动它。",
	["Contains one of the following:"] = "包含以下卡牌之一：",
	["Restricted"] = "受限",
	["Classified"] = "保密",
	["Covert"] = "隐秘",
	["Priceless"] = "无价",
	["Priceless card"] = "无价卡牌",
	["A weapon of legend. Which one stays a mystery."] = "一件传说中的武器。究竟是哪一件，仍是个谜。",
	["Click a card to inspect it."] = "点击卡牌即可查看。",
	["Click anywhere to close."] = "点击任意处关闭。",
	["A creature of %s, for the test."] = "来自%s的生物，仅供测试。",
	["Rank 14 weapon"] = "14级军衔武器",
})

Add("zhTW", {
	["Test case"] = "測試箱",
	["A preview of the opening: random cards, nothing is kept."] = "開箱預覽：隨機卡牌，不會保留任何東西。",
	["Open the case"] = "打開箱子",
	["Open another case"] = "再開一個箱子",
	["Turn it with the mouse."] = "用滑鼠轉動它。",
	["Contains one of the following:"] = "包含以下卡牌之一：",
	["Restricted"] = "受限",
	["Classified"] = "保密",
	["Covert"] = "隱密",
	["Priceless"] = "無價",
	["Priceless card"] = "無價卡牌",
	["A weapon of legend. Which one stays a mystery."] = "一件傳說中的武器。究竟是哪一件，仍是個謎。",
	["Click a card to inspect it."] = "點擊卡牌即可查看。",
	["Click anywhere to close."] = "點擊任意處關閉。",
	["A creature of %s, for the test."] = "來自%s的生物，僅供測試。",
	["Rank 14 weapon"] = "14級軍階武器",
})

-- (1.14.0) The innkeeper's bet made harder (Tavern.lua, UI/Tavern.lua): two copies of a card bet, from common to epic,
-- against seven cards face down, four of them win nothing; a bet never gives a legendary card.
Add("frFR", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "Mise deux doublons d'une même carte : je pose sept cartes face cachée, une de la rareté au-dessus (épique au mieux), deux de sa rareté, et quatre qui ne gagnent rien. Choisis-en une !",
	["Your stake: %d copies"] = "Ta mise : %d exemplaires",
	["Bet two copies"] = "Miser deux exemplaires",
	["Choose the copies"] = "Choisir les exemplaires",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "Un pari prend deux doublons d'une même carte, de commune à épique, d'une rareté que cet album peut égaler. Tu n'en as pas : les doublons viennent avec les boosters, reviens avec quelques-uns !",
	["The copies bet: %s"] = "Les exemplaires misés : %s",
	["Which copies of %s to bet?"] = "Quels exemplaires de %s miser ?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d cartes sur %d ne gagnent rien. Plus de chance demain !",
})

Add("deDE", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "Setz zwei doppelte Exemplare derselben Karte: Ich lege sieben Karten verdeckt hin, eine der Seltenheit darüber (höchstens episch), zwei ihrer Seltenheit und vier, die nichts gewinnen. Zieh eine!",
	["Your stake: %d copies"] = "Dein Einsatz: %d Exemplare",
	["Bet two copies"] = "Zwei Exemplare setzen",
	["Choose the copies"] = "Exemplare wählen",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "Eine Wette braucht zwei doppelte Exemplare derselben Karte, von gewöhnlich bis episch, in einer Seltenheit, die dieses Album aufwiegen kann. Du hast keine: Doppelte Karten kommen mit den Boostern, komm mit ein paar wieder!",
	["The copies bet: %s"] = "Die gesetzten Exemplare: %s",
	["Which copies of %s to bet?"] = "Welche Exemplare von %s setzen?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d von %d Karten gewinnen nichts. Morgen mehr Glück!",
})

local BET_ES = {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "Apuesta dos repetidas de la misma carta: pongo siete cartas boca abajo, una de la rareza superior (épica como mucho), dos de su rareza y cuatro que no ganan nada. ¡Elige una!",
	["Your stake: %d copies"] = "Tu apuesta: %d copias",
	["Bet two copies"] = "Apostar dos copias",
	["Choose the copies"] = "Elegir las copias",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "Una apuesta pide dos repetidas de la misma carta, de común a épica, de una rareza que este álbum pueda igualar. No tienes ninguna: las repetidas llegan con los sobres, ¡vuelve con algunas!",
	["The copies bet: %s"] = "Las copias apostadas: %s",
	["Which copies of %s to bet?"] = "¿Qué copias de %s apostar?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d cartas de %d no ganan nada. ¡Más suerte mañana!",
}
Add("esES", BET_ES)
Add("esMX", BET_ES)

Add("ptBR", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "Aposte duas repetidas da mesma carta: eu ponho sete cartas viradas para baixo, uma da raridade acima (épica no máximo), duas da raridade dela e quatro que não ganham nada. Escolha uma!",
	["Your stake: %d copies"] = "Sua aposta: %d cópias",
	["Bet two copies"] = "Apostar duas cópias",
	["Choose the copies"] = "Escolher as cópias",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "Uma aposta pede duas repetidas da mesma carta, de comum a épica, de uma raridade que este álbum possa cobrir. Você não tem nenhuma: as repetidas vêm com os pacotes, volte com algumas!",
	["The copies bet: %s"] = "As cópias apostadas: %s",
	["Which copies of %s to bet?"] = "Quais cópias de %s apostar?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d cartas de %d não ganham nada. Mais sorte amanhã!",
})

Add("ruRU", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "Поставьте два повтора одной карты: я кладу рубашкой вверх семь карт, одну на ступень выше по редкости (не выше эпической), две той же редкости и четыре, которые ничего не дают. Выберите одну!",
	["Your stake: %d copies"] = "Ваша ставка: %d копии",
	["Bet two copies"] = "Поставить две копии",
	["Choose the copies"] = "Выбрать копии",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "Для ставки нужны два повтора одной карты, от обычной до эпической, той редкости, на которую этот альбом может ответить. У вас таких нет: повторы приходят с бустерами, возвращайтесь с ними!",
	["The copies bet: %s"] = "Ставка: %s",
	["Which copies of %s to bet?"] = "Какие копии поставить: %s?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "Пустых карт: %d из %d. Удачи завтра!",
})

Add("koKR", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "같은 카드의 중복 두 장을 걸어 보세요. 카드 일곱 장을 뒤집어 놓겠습니다. 한 단계 높은 희귀도 한 장(최대 영웅), 같은 희귀도 두 장, 그리고 아무것도 없는 네 장. 한 장을 고르세요!",
	["Your stake: %d copies"] = "걸 카드: %d장",
	["Bet two copies"] = "두 장 걸기",
	["Choose the copies"] = "카드 고르기",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "내기에는 같은 카드의 중복 두 장이 필요합니다. 일반부터 영웅까지, 이 앨범으로 맞받을 수 있는 희귀도여야 합니다. 지금은 없습니다. 중복 카드는 부스터에서 나옵니다. 몇 장 모아서 다시 오세요!",
	["The copies bet: %s"] = "건 카드: %s",
	["Which copies of %s to bet?"] = "%s의 어느 카드들을 걸까요?",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "꽝 %d장 (전체 %d장 중). 내일은 더 운이 좋기를!",
})

Add("zhCN", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "押上同一张卡牌的两张重复卡：我会把七张卡牌背面朝上放好，一张高一级稀有度（最高史诗），两张同稀有度，还有四张什么也没有。选一张吧！",
	["Your stake: %d copies"] = "你的赌注：%d 张",
	["Bet two copies"] = "押上两张",
	["Choose the copies"] = "选择卡牌",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "押注需要同一张卡牌的两张重复卡，从普通到史诗，且是这本收藏册能对上的稀有度。你还没有：重复的卡牌来自补充包，攒一些再来吧！",
	["The copies bet: %s"] = "押上的卡牌：%s",
	["Which copies of %s to bet?"] = "押上 %s 的哪几张？",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d 张卡牌什么也没有（共 %d 张）。明天好运！",
})

Add("zhTW", {
	["Bet two duplicates of the same card: I put seven cards face down, one of the rarity above (epic at most), two of its rarity, and four that win nothing. Pick one!"] = "押上同一張卡牌的兩張重複卡：我會把七張卡牌背面朝上放好，一張高一級稀有度（最高史詩），兩張同稀有度，還有四張什麼也沒有。選一張吧！",
	["Your stake: %d copies"] = "你的賭注：%d 張",
	["Bet two copies"] = "押上兩張",
	["Choose the copies"] = "選擇卡牌",
	["A bet takes two duplicates of the same card, from common to epic, of a rarity this album can match. You have none: duplicates come with the boosters, come back with some!"] = "押注需要同一張卡牌的兩張重複卡，從普通到史詩，且是這本收藏冊能對上的稀有度。你還沒有：重複的卡牌來自補充包，攢一些再來吧！",
	["The copies bet: %s"] = "押上的卡牌：%s",
	["Which copies of %s to bet?"] = "押上 %s 的哪幾張？",
	["%d cards out of %d win nothing. Better luck tomorrow!"] = "%d 張卡牌什麼也沒有（共 %d 張）。明天好運！",
})

-- (1.14.0) The pass of the collection (Pass.lua): the trades, the duels with a stake and the sales to the reseller need
-- the Curator app, linked to the Battle.net account on the website.
Add("frFR", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Ton appli Curator n'a pas encore envoyé cette collection au site : déconnecte-toi du jeu une fois, puis attends quelques minutes.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Ton appli Curator n'a pas encore envoyé ce personnage au site : déconnecte-toi une fois du jeu avec lui, puis attends quelques minutes.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Ton appli Curator n'a pas vérifié ta collection depuis %d jours : ouvre-la, puis recharge ton interface.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "Les échanges, les duels à enjeu et les ventes au revendeur demandent l'appli Curator, reliée à ton compte Battle.net sur le site : %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s n'a pas pu vérifier ton appli Curator : déconnecte-toi une fois du jeu avec ce personnage, puis attends quelques minutes.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s n'a pas l'appli Curator reliée à Battle.net : pas d'échange.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s n'a pas l'appli Curator reliée à Battle.net : pas de duel à enjeu.",
	["Needs the app"] = "Il faut l'appli",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "Vendre au revendeur demande l'appli Curator, reliée à ton compte Battle.net sur le site.",
	["Sales need the Curator app, linked to Battle.net."] = "Les ventes demandent l'appli Curator, reliée à Battle.net.",
})

Add("deDE", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Deine Curator-App hat diese Sammlung noch nicht an die Website geschickt: Melde dich einmal aus dem Spiel ab und warte dann ein paar Minuten.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Deine Curator-App hat diesen Charakter noch nicht an die Website geschickt: Melde dich mit ihm einmal aus dem Spiel ab und warte dann ein paar Minuten.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Deine Curator-App hat deine Sammlung seit %d Tagen nicht geprüft: Öffne sie und lade dann dein Interface neu.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "Tausch, Duelle mit Einsatz und Verkäufe an den Wiederverkäufer brauchen die Curator-App, verknüpft mit deinem Battle.net-Konto auf der Website: %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s konnte deine Curator-App nicht prüfen: Melde dich mit diesem Charakter einmal aus dem Spiel ab und warte dann ein paar Minuten.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s hat die Curator-App nicht mit Battle.net verknüpft: kein Tausch.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s hat die Curator-App nicht mit Battle.net verknüpft: kein Duell mit Einsatz.",
	["Needs the app"] = "App nötig",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "Verkaufen an den Wiederverkäufer braucht die Curator-App, verknüpft mit deinem Battle.net-Konto auf der Website.",
	["Sales need the Curator app, linked to Battle.net."] = "Verkäufe brauchen die Curator-App mit Battle.net.",
})

local PASS_ES = {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Tu aplicación de Curator aún no ha enviado esta colección al sitio: sal del juego una vez y espera unos minutos.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Tu aplicación de Curator aún no ha enviado este personaje al sitio: sal del juego una vez con él y espera unos minutos.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Tu aplicación de Curator no ha revisado tu colección desde hace %d días: ábrela y recarga tu interfaz.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "Los intercambios, los duelos con apuesta y las ventas al revendedor necesitan la aplicación de Curator, vinculada a tu cuenta de Battle.net en el sitio: %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s no pudo comprobar tu aplicación de Curator: sal del juego una vez con este personaje y espera unos minutos.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s no tiene la aplicación de Curator vinculada a Battle.net: no hay intercambio.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s no tiene la aplicación de Curator vinculada a Battle.net: no hay duelo con apuesta.",
	["Needs the app"] = "Falta la aplicación",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "Vender al revendedor necesita la aplicación de Curator, vinculada a tu cuenta de Battle.net en el sitio.",
	["Sales need the Curator app, linked to Battle.net."] = "Las ventas necesitan la aplicación de Curator con Battle.net.",
}
Add("esES", PASS_ES)
Add("esMX", PASS_ES)

Add("ptBR", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Seu aplicativo do Curator ainda não enviou esta coleção ao site: saia do jogo uma vez e espere alguns minutos.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Seu aplicativo do Curator ainda não enviou este personagem ao site: saia do jogo uma vez com ele e espere alguns minutos.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Seu aplicativo do Curator não verifica sua coleção há %d dias: abra-o e recarregue sua interface.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "As trocas, os duelos com aposta e as vendas ao revendedor precisam do aplicativo do Curator, vinculado à sua conta Battle.net no site: %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s não conseguiu verificar seu aplicativo do Curator: saia do jogo uma vez com este personagem e espere alguns minutos.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s não tem o aplicativo do Curator vinculado ao Battle.net: sem troca.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s não tem o aplicativo do Curator vinculado ao Battle.net: sem duelo com aposta.",
	["Needs the app"] = "Falta o aplicativo",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "Vender ao revendedor precisa do aplicativo do Curator, vinculado à sua conta Battle.net no site.",
	["Sales need the Curator app, linked to Battle.net."] = "As vendas precisam do aplicativo do Curator com Battle.net.",
})

Add("ruRU", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Приложение Curator ещё не отправило эту коллекцию на сайт: выйдите из игры один раз и подождите несколько минут.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Приложение Curator ещё не отправило этого персонажа на сайт: выйдите им из игры один раз и подождите несколько минут.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Приложение Curator не проверяло вашу коллекцию уже %d дн.: откройте его и перезагрузите интерфейс.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "Для обменов, дуэлей со ставкой и продаж перекупщику нужно приложение Curator, связанное с вашей учётной записью Battle.net на сайте: %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s не удалось проверить ваше приложение Curator: выйдите из игры один раз этим персонажем и подождите несколько минут.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "У %s нет приложения Curator, связанного с Battle.net: обмена не будет.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "У %s нет приложения Curator, связанного с Battle.net: дуэли со ставкой не будет.",
	["Needs the app"] = "Нужно приложение",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "Для продажи перекупщику нужно приложение Curator, связанное с вашей учётной записью Battle.net на сайте.",
	["Sales need the Curator app, linked to Battle.net."] = "Для продаж нужно приложение Curator с Battle.net.",
})

Add("koKR", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "Curator 앱이 아직 이 수집품을 사이트로 보내지 않았습니다. 게임에서 한 번 접속을 종료한 뒤 몇 분 기다리세요.",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "Curator 앱이 아직 이 캐릭터를 사이트로 보내지 않았습니다. 이 캐릭터로 게임에서 한 번 접속을 종료한 뒤 몇 분 기다리세요.",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "Curator 앱이 %d일 동안 수집품을 확인하지 않았습니다. 앱을 연 뒤 인터페이스를 다시 불러오세요.",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "교환, 내기 결투, 재판매상 판매에는 사이트에서 Battle.net 계정에 연결된 Curator 앱이 필요합니다: %s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s 님이 당신의 Curator 앱을 확인하지 못했습니다. 이 캐릭터로 게임에서 한 번 접속을 종료한 뒤 몇 분 기다리세요.",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s 님은 Battle.net에 연결된 Curator 앱이 없습니다. 교환할 수 없습니다.",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s 님은 Battle.net에 연결된 Curator 앱이 없습니다. 내기 결투를 할 수 없습니다.",
	["Needs the app"] = "앱 필요",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "재판매상에게 팔려면 사이트에서 Battle.net 계정에 연결된 Curator 앱이 필요합니다.",
	["Sales need the Curator app, linked to Battle.net."] = "판매에는 Battle.net에 연결된 Curator 앱이 필요합니다.",
})

Add("zhCN", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "你的 Curator 应用还没有把这个收藏发送到网站：退出游戏一次，然后等几分钟。",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "你的 Curator 应用还没有把这个角色发送到网站：用这个角色退出游戏一次，然后等几分钟。",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "你的 Curator 应用已经 %d 天没有检查你的收藏：打开它，然后重新载入界面。",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "交换、赌注决斗和卖给转卖商都需要 Curator 应用，并在网站上关联你的战网账号：%s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s 无法验证你的 Curator 应用：用这个角色退出游戏一次，然后等几分钟。",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s 没有关联战网的 Curator 应用：无法交换。",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s 没有关联战网的 Curator 应用：无法进行赌注决斗。",
	["Needs the app"] = "需要应用",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "卖给转卖商需要 Curator 应用，并在网站上关联你的战网账号。",
	["Sales need the Curator app, linked to Battle.net."] = "出售需要关联战网的 Curator 应用。",
})

Add("zhTW", {
	["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."] = "你的 Curator 應用程式還沒有把這個收藏傳送到網站：登出遊戲一次，然後等幾分鐘。",
	["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."] = "你的 Curator 應用程式還沒有把這個角色傳送到網站：用這個角色登出遊戲一次，然後等幾分鐘。",
	["Your Curator app has not checked your collection for %d days: open it, then reload your interface."] = "你的 Curator 應用程式已經 %d 天沒有檢查你的收藏：打開它，然後重新載入介面。",
	["Trades, duels for a stake and sales to the reseller need the Curator app, linked to your Battle.net account on the website: %s"] = "交換、賭注決鬥和賣給轉賣商都需要 Curator 應用程式，並在網站上連結你的 Battle.net 帳號：%s",
	["%s could not check your Curator app: log out of the game once with this character, then wait a few minutes."] = "%s 無法驗證你的 Curator 應用程式：用這個角色登出遊戲一次，然後等幾分鐘。",
	["%s does not have the Curator app linked to Battle.net: no trade."] = "%s 沒有連結 Battle.net 的 Curator 應用程式：無法交換。",
	["%s does not have the Curator app linked to Battle.net: no duel with a stake."] = "%s 沒有連結 Battle.net 的 Curator 應用程式：無法進行賭注決鬥。",
	["Needs the app"] = "需要應用程式",
	["Selling to the reseller needs the Curator app, linked to your Battle.net account on the website."] = "賣給轉賣商需要 Curator 應用程式，並在網站上連結你的 Battle.net 帳號。",
	["Sales need the Curator app, linked to Battle.net."] = "出售需要連結 Battle.net 的 Curator 應用程式。",
})

-- (1.14.0) The cards and their albums kept from the other addons (Guard.lua): what is said when one of them changed
-- them, and Curator gives nothing more until the game reloads.

Add("frFR", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Un autre addon a changé les données des cartes de Curator pendant cette session : Curator ne donne plus rien (cartes, boosters, expérience, rubis) jusqu'au prochain rechargement du jeu (/reload). Désactive l'addon qui fait ça.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "Curator ne donne plus rien jusqu'au prochain rechargement du jeu (/reload) : un autre addon a changé les données de ses cartes.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "Curator ne donne plus rien jusqu'au /reload : un autre addon a changé ses cartes.",
})

Add("deDE", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Ein anderes Addon hat in dieser Sitzung die Kartendaten von Curator verändert: Curator gibt nichts mehr (Karten, Booster, Erfahrung, Rubine), bis das Spiel neu geladen wird (/reload). Deaktiviere das Addon, das das tut.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "Curator gibt nichts mehr, bis das Spiel neu geladen wird (/reload): Ein anderes Addon hat seine Kartendaten verändert.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "Curator gibt nichts bis /reload: Ein anderes Addon hat seine Karten verändert.",
})

Add("esES", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Otro addon ha cambiado los datos de las cartas de Curator durante esta sesión: Curator ya no da nada (cartas, sobres, experiencia, rubíes) hasta que se recargue el juego (/reload). Desactiva el addon que lo hace.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "Curator no da nada hasta que se recargue el juego (/reload): otro addon ha cambiado los datos de sus cartas.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "Curator no da nada hasta /reload: otro addon ha cambiado sus cartas.",
})

Add("esMX", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Otro addon ha cambiado los datos de las cartas de Curator durante esta sesión: Curator ya no da nada (cartas, sobres, experiencia, rubíes) hasta que se recargue el juego (/reload). Desactiva el addon que lo hace.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "Curator no da nada hasta que se recargue el juego (/reload): otro addon ha cambiado los datos de sus cartas.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "Curator no da nada hasta /reload: otro addon ha cambiado sus cartas.",
})

Add("ptBR", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Outro addon alterou os dados das cartas do Curator nesta sessão: o Curator não dá mais nada (cartas, pacotes, experiência, rubis) até o jogo ser recarregado (/reload). Desative o addon que faz isso.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "O Curator não dá nada até o jogo ser recarregado (/reload): outro addon alterou os dados das cartas dele.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "O Curator não dá nada até /reload: outro addon alterou as cartas dele.",
})

Add("ruRU", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "Другой аддон изменил данные карт Curator в этом сеансе: Curator больше ничего не даёт (карты, бустеры, опыт, рубины) до перезагрузки игры (/reload). Отключите аддон, который это делает.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "Curator ничего не даёт до перезагрузки игры (/reload): другой аддон изменил данные его карт.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "Curator ничего не даёт до /reload: другой аддон изменил его карты.",
})

Add("koKR", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "이번 세션에서 다른 애드온이 Curator의 카드 데이터를 변경했습니다. 게임을 다시 불러올 때까지(/reload) Curator는 아무것도 주지 않습니다(카드, 부스터, 경험치, 루비). 그 애드온을 비활성화하세요.",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "게임을 다시 불러올 때까지(/reload) Curator는 아무것도 주지 않습니다. 다른 애드온이 카드 데이터를 변경했습니다.",
	["Curator gives nothing until /reload: another addon changed its cards."] = "/reload 전까지 Curator는 아무것도 주지 않습니다. 다른 애드온이 카드를 변경했습니다.",
})

Add("zhCN", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "本次会话中另一个插件修改了 Curator 的卡牌数据：在重新载入游戏（/reload）之前，Curator 不再给予任何东西（卡牌、补充包、经验、红宝石）。请禁用造成此问题的插件。",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "在重新载入游戏（/reload）之前，Curator 不再给予任何东西：另一个插件修改了它的卡牌数据。",
	["Curator gives nothing until /reload: another addon changed its cards."] = "/reload 之前 Curator 不再给予任何东西：另一个插件修改了它的卡牌。",
})

Add("zhTW", {
	["Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."] = "本次工作階段中另一個插件修改了 Curator 的卡牌資料：在重新載入遊戲（/reload）之前，Curator 不再給予任何東西（卡牌、補充包、經驗、紅寶石）。請停用造成此問題的插件。",
	["Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."] = "在重新載入遊戲（/reload）之前，Curator 不再給予任何東西：另一個插件修改了它的卡牌資料。",
	["Curator gives nothing until /reload: another addon changed its cards."] = "/reload 之前 Curator 不再給予任何東西：另一個插件修改了它的卡牌。",
})

-- (1.14.3, his word of November 6) The trades and the reseller without the pass of the app (the Exchange alone asks for it,
-- Pass.lua: PS:Text); the alerts of the guild turned off whole, its epic cards only, moved (UI/Live.lua, UI/Options.lua);
-- the choice of the main given back once (Reroll.lua).
Add("frFR", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "La Bourse demande l'appli Curator, reliée à ton compte Battle.net sur le site : %s",
	["Your guild's alerts"] = "Les alertes de ta guilde",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Ses boosters, ses caisses, ses cartes et ses hauts faits, sur ton écran. Décoché : plus rien de ta guilde ne s'affiche, ni son panneau en direct, ni ses alertes, ni leurs sons.",
	["Epic and better only"] = "Épiques et mieux seulement",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Seulement les cartes épiques, légendaires et mythiques de ta guilde, et ses caisses à partir du rang Restreint.",
	["Move"] = "Déplacer",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Où s'affichent les alertes de Curator et le panneau de ta guilde : fais-les glisser, puis Terminé.",
	["The alerts of Curator"] = "Les alertes de Curator",
	["Your guild, live"] = "Ta guilde, en direct",
	["Drag to move them, then Done."] = "Fais-les glisser, puis Terminé.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3 : tu peux rechoisir ton personnage principal, une fois, quand tu veux : connecte-toi avec lui et tape /curator principal. Ton principal pour l'instant : %s.",
})

Add("deDE", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "Die Börse braucht die Curator-App, verknüpft mit deinem Battle.net-Konto auf der Website: %s",
	["Your guild's alerts"] = "Die Meldungen deiner Gilde",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Ihre Booster, Kisten, Karten und Erfolge auf deinem Bildschirm. Aus: Von deiner Gilde erscheint nichts mehr, weder ihr Live-Fenster noch ihre Meldungen noch deren Töne.",
	["Epic and better only"] = "Nur episch und besser",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Nur die epischen, legendären und mythischen Karten deiner Gilde und ihre Kisten ab dem Rang Eingeschränkt.",
	["Move"] = "Verschieben",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Wo die Meldungen von Curator und das Fenster deiner Gilde erscheinen: Zieh sie, dann Fertig.",
	["The alerts of Curator"] = "Die Meldungen von Curator",
	["Your guild, live"] = "Deine Gilde, live",
	["Drag to move them, then Done."] = "Zieh sie, dann Fertig.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: Du kannst deinen Hauptcharakter einmal neu wählen, wann du willst: Melde dich mit ihm an und gib /curator main ein. Dein Hauptcharakter im Moment: %s.",
})

Add("esES", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "La Bolsa necesita la aplicación de Curator, vinculada a tu cuenta de Battle.net en el sitio: %s",
	["Your guild's alerts"] = "Las alertas de tu hermandad",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Sus sobres, cajas, cartas y logros en tu pantalla. Desactivado: ya no se muestra nada de tu hermandad, ni su panel en directo, ni sus alertas, ni sus sonidos.",
	["Epic and better only"] = "Solo épicas y mejores",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Solo las cartas épicas, legendarias y míticas de tu hermandad, y sus cajas desde el rango Restringido.",
	["Move"] = "Mover",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Dónde se muestran las alertas de Curator y el panel de tu hermandad: arrástralos y luego Listo.",
	["The alerts of Curator"] = "Las alertas de Curator",
	["Your guild, live"] = "Tu hermandad, en directo",
	["Drag to move them, then Done."] = "Arrástralos y luego Listo.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: puedes volver a elegir tu personaje principal, una vez, cuando quieras: conéctate con él y escribe /curator main. Tu principal por ahora: %s.",
})

Add("esMX", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "La Bolsa necesita la aplicación de Curator, vinculada a tu cuenta de Battle.net en el sitio: %s",
	["Your guild's alerts"] = "Las alertas de tu hermandad",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Sus sobres, cajas, cartas y logros en tu pantalla. Desactivado: ya no se muestra nada de tu hermandad, ni su panel en directo, ni sus alertas, ni sus sonidos.",
	["Epic and better only"] = "Solo épicas y mejores",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Solo las cartas épicas, legendarias y míticas de tu hermandad, y sus cajas desde el rango Restringido.",
	["Move"] = "Mover",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Dónde se muestran las alertas de Curator y el panel de tu hermandad: arrástralos y luego Listo.",
	["The alerts of Curator"] = "Las alertas de Curator",
	["Your guild, live"] = "Tu hermandad, en directo",
	["Drag to move them, then Done."] = "Arrástralos y luego Listo.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: puedes volver a elegir tu personaje principal, una vez, cuando quieras: conéctate con él y escribe /curator main. Tu principal por ahora: %s.",
})

Add("ptBR", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "A Bolsa precisa do aplicativo do Curator, vinculado à sua conta Battle.net no site: %s",
	["Your guild's alerts"] = "Os alertas da sua guilda",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Os pacotes, caixas, cartas e conquistas dela na sua tela. Desligado: nada da sua guilda aparece mais, nem o painel ao vivo, nem os alertas, nem os sons.",
	["Epic and better only"] = "Só épicas e melhores",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Só as cartas épicas, lendárias e míticas da sua guilda, e as caixas dela a partir do rank Restrito.",
	["Move"] = "Mover",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Onde aparecem os alertas do Curator e o painel da sua guilda: arraste-os e depois Pronto.",
	["The alerts of Curator"] = "Os alertas do Curator",
	["Your guild, live"] = "Sua guilda, ao vivo",
	["Drag to move them, then Done."] = "Arraste-os e depois Pronto.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: você pode escolher de novo seu personagem principal, uma vez, quando quiser: entre com ele e digite /curator main. Seu principal por enquanto: %s.",
})

Add("ruRU", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "Для Биржи нужно приложение Curator, связанное с вашей учётной записью Battle.net на сайте: %s",
	["Your guild's alerts"] = "Оповещения вашей гильдии",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "Её бустеры, ящики, карты и достижения на вашем экране. Выключено: от гильдии больше ничего не показывается, ни живая панель, ни оповещения, ни их звуки.",
	["Epic and better only"] = "Только эпические и лучше",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "Только эпические, легендарные и мифические карты вашей гильдии и её ящики начиная с ранга «Запрещённое».",
	["Move"] = "Переместить",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Где показываются оповещения Curator и панель вашей гильдии: перетащите их, затем «Готово».",
	["The alerts of Curator"] = "Оповещения Curator",
	["Your guild, live"] = "Ваша гильдия, в прямом эфире",
	["Drag to move them, then Done."] = "Перетащите их, затем «Готово».",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: ты можешь снова выбрать основного персонажа, один раз, когда захочешь: зайди им и введи /curator main. Твой основной сейчас: %s.",
})

Add("koKR", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "거래소에는 사이트에서 Battle.net 계정에 연결된 Curator 앱이 필요합니다: %s",
	["Your guild's alerts"] = "길드 알림",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "길드원의 부스터, 상자, 카드, 업적을 화면에 표시합니다. 끄면: 길드의 실시간 패널, 알림, 소리가 더 이상 표시되지 않습니다.",
	["Epic and better only"] = "영웅 등급 이상만",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "길드의 영웅, 전설, 신화 카드와 제한됨 등급 이상의 상자만 표시합니다.",
	["Move"] = "이동",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Curator 알림과 길드 패널이 표시되는 위치: 끌어서 옮긴 뒤 완료를 누르세요.",
	["The alerts of Curator"] = "Curator 알림",
	["Your guild, live"] = "길드 실시간",
	["Drag to move them, then Done."] = "끌어서 옮긴 뒤 완료를 누르세요.",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3: 주 캐릭터를 원할 때 한 번 다시 고를 수 있습니다: 그 캐릭터로 접속해 /curator main 을 입력하세요. 현재 주 캐릭터: %s.",
})

Add("zhCN", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "交易所需要 Curator 应用，并在网站上关联你的战网账号：%s",
	["Your guild's alerts"] = "公会提醒",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "公会成员的补充包、箱子、卡牌和成就会显示在你的屏幕上。关闭后：公会的任何内容都不再显示，包括实时面板、提醒及其音效。",
	["Epic and better only"] = "仅史诗及以上",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "仅显示公会的史诗、传说和神话卡牌，以及受限等级及以上的箱子。",
	["Move"] = "移动",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Curator 提醒和公会面板的显示位置：拖动它们，然后点击完成。",
	["The alerts of Curator"] = "Curator 提醒",
	["Your guild, live"] = "公会实时",
	["Drag to move them, then Done."] = "拖动它们，然后点击完成。",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3：你可以随时重新选择一次主角色：用它登录并输入 /curator main。当前主角色：%s。",
})

Add("zhTW", {
	["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"] = "交易所需要 Curator 應用程式，並在網站上連結你的 Battle.net 帳號：%s",
	["Your guild's alerts"] = "公會提醒",
	["Their boosters, cases, cards and achievements, on your screen. Off: nothing of your guild shows any more, neither its live panel nor its alerts, nor their sounds."] = "公會成員的補充包、箱子、卡牌和成就會顯示在你的螢幕上。關閉後：公會的任何內容都不再顯示，包括即時面板、提醒及其音效。",
	["Epic and better only"] = "僅史詩及以上",
	["Only the epic, legendary and mythic cards of your guild, and its cases from the Restricted rank."] = "僅顯示公會的史詩、傳說和神話卡牌，以及受限等級及以上的箱子。",
	["Move"] = "移動",
	["Where the alerts of Curator and the panel of your guild show: drag them, then Done."] = "Curator 提醒和公會面板的顯示位置：拖動它們，然後點擊完成。",
	["The alerts of Curator"] = "Curator 提醒",
	["Your guild, live"] = "公會即時",
	["Drag to move them, then Done."] = "拖動它們，然後點擊完成。",
	["Curator 1.14.3: you may choose your main character again, once, whenever you like: log in with it and type /curator main. Your main for now: %s."] = "Curator 1.14.3：你可以隨時重新選擇一次主角色：用它登入並輸入 /curator main。目前主角色：%s。",
})

-- (1.14.3, his word of November 6, later: « voir le full inventaire ») Another player's inventory, where their collection
-- opens (UI/Inventory.lua, Comm.lua).
Add("frFR", {
	["%s's inventory"] = "Inventaire de %s",
	["Click: see it in their album"] = "Clic : la voir dans son album",
	["%s is in combat: their inventory comes in a moment."] = "%s est en combat : son inventaire arrive dans un instant.",
	["%s must update Curator to show their inventory."] = "%s doit mettre Curator à jour pour montrer son inventaire.",
})

Add("deDE", {
	["%s's inventory"] = "Inventar von %s",
	["Click: see it in their album"] = "Klick: im Album ansehen",
	["%s is in combat: their inventory comes in a moment."] = "%s ist im Kampf: Das Inventar kommt gleich.",
	["%s must update Curator to show their inventory."] = "%s muss Curator aktualisieren, um das Inventar zu zeigen.",
})

Add("esES", {
	["%s's inventory"] = "Inventario de %s",
	["Click: see it in their album"] = "Clic: verla en su álbum",
	["%s is in combat: their inventory comes in a moment."] = "%s está en combate: su inventario llegará en un momento.",
	["%s must update Curator to show their inventory."] = "%s debe actualizar Curator para mostrar su inventario.",
})

Add("esMX", {
	["%s's inventory"] = "Inventario de %s",
	["Click: see it in their album"] = "Clic: verla en su álbum",
	["%s is in combat: their inventory comes in a moment."] = "%s está en combate: su inventario llegará en un momento.",
	["%s must update Curator to show their inventory."] = "%s debe actualizar Curator para mostrar su inventario.",
})

Add("ptBR", {
	["%s's inventory"] = "Inventário de %s",
	["Click: see it in their album"] = "Clique: ver no álbum",
	["%s is in combat: their inventory comes in a moment."] = "%s está em combate: o inventário chega em instantes.",
	["%s must update Curator to show their inventory."] = "%s precisa atualizar o Curator para mostrar o inventário.",
})

Add("ruRU", {
	["%s's inventory"] = "Инвентарь: %s",
	["Click: see it in their album"] = "Щелчок: открыть в альбоме игрока",
	["%s is in combat: their inventory comes in a moment."] = "%s в бою: инвентарь появится через мгновение.",
	["%s must update Curator to show their inventory."] = "%s нужно обновить Curator, чтобы показать инвентарь.",
})

Add("koKR", {
	["%s's inventory"] = "%s 님의 보관함",
	["Click: see it in their album"] = "클릭: 앨범에서 보기",
	["%s is in combat: their inventory comes in a moment."] = "%s 님은 전투 중입니다: 잠시 후 보관함이 표시됩니다.",
	["%s must update Curator to show their inventory."] = "%s 님이 보관함을 보여 주려면 Curator를 업데이트해야 합니다.",
})

Add("zhCN", {
	["%s's inventory"] = "%s 的库存",
	["Click: see it in their album"] = "点击：在其收藏册中查看",
	["%s is in combat: their inventory comes in a moment."] = "%s 正在战斗中：库存稍后显示。",
	["%s must update Curator to show their inventory."] = "%s 需要更新 Curator 才能展示库存。",
})

Add("zhTW", {
	["%s's inventory"] = "%s 的庫存",
	["Click: see it in their album"] = "點擊：在其收藏冊中查看",
	["%s is in combat: their inventory comes in a moment."] = "%s 正在戰鬥中：庫存稍後顯示。",
	["%s must update Curator to show their inventory."] = "%s 需要更新 Curator 才能展示庫存。",
})

-- (1.14.3, his word of November 6: « Pour chaque maj mettre une fenetre texte disant que l'addon a été mis a jour avec
-- l'essentiel des correctif et nouveauté ») The window of the news of an update (UI/Mandatory.lua: ns.NewsWindow), its
-- words and the news of 1.14.3 (its lines: N.NEWS there, the same English here).
Add("frFR", {
	["Curator has been updated"] = "Curator a été mis à jour",
	["What is new in Curator %s"] = "Les nouveautés de Curator %s",
	["/curator news: this window again"] = "/curator nouveautes : revoir cette fenêtre",
	["/curator news: what is new in this version"] = "/curator nouveautes : les nouveautés de cette version",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "Les échanges et les ventes au revendeur ne demandent plus l'appli Curator : seule la Bourse la demande encore.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "La collection d'un autre joueur s'ouvre sur son inventaire : chaque exemplaire tel qu'il est vraiment (son usure, son pattern, son boîtier, son sceau, sa signature). Il faut Curator 1.14.3 des deux côtés.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Une carte montrée dans le chat est l'exemplaire même : son usure, sa note, son sceau et sa signature partent avec elle.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "Le canal de discussion des collectionneurs marche enfin : son nom dans le jeu est maintenant curatoralli ou curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Les alertes de ta guilde : coupées pour de bon, épiques et mieux seulement, ou déplacées où tu veux (/curator alertes).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Ton personnage principal peut être rechoisi, une fois : connecte-toi avec lui et tape /curator principal.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI et Immersion : ce que Curator ajoute aux dialogues du jeu s'affiche maintenant à côté de leur fenêtre.",
})

Add("deDE", {
	["Curator has been updated"] = "Curator wurde aktualisiert",
	["What is new in Curator %s"] = "Neu in Curator %s",
	["/curator news: this window again"] = "/curator neuigkeiten: dieses Fenster noch einmal",
	["/curator news: what is new in this version"] = "/curator neuigkeiten: was in dieser Version neu ist",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "Tausch und Verkäufe an den Wiederverkäufer brauchen die Curator-App nicht mehr: Nur die Börse verlangt sie noch.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "Die Sammlung eines anderen Spielers öffnet sich in seinem Inventar: jedes Exemplar so, wie es wirklich ist (Abnutzung, Pattern, Hülle, Siegel, Signatur). Ihr braucht beide Curator 1.14.3.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Eine im Chat gezeigte Karte ist genau dieses Exemplar: Abnutzung, Note, Siegel und Signatur gehen mit.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "Der Chatkanal der Sammler funktioniert jetzt: Sein Name im Spiel ist curatoralli oder curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Die Meldungen deiner Gilde: ganz aus, nur episch und besser, oder dorthin verschoben, wo du willst (/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Dein Hauptcharakter kann einmal neu gewählt werden: Melde dich mit ihm an und gib /curator main ein.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI und Immersion: Was Curator den Dialogen des Spiels hinzufügt, erscheint jetzt neben ihrem Fenster.",
})

Add("esES", {
	["Curator has been updated"] = "Curator se ha actualizado",
	["What is new in Curator %s"] = "Novedades de Curator %s",
	["/curator news: this window again"] = "/curator novedades: volver a ver esta ventana",
	["/curator news: what is new in this version"] = "/curator novedades: las novedades de esta versión",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "Los intercambios y las ventas al revendedor ya no necesitan la aplicación de Curator: solo la Bolsa la sigue pidiendo.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "La colección de otro jugador se abre en su inventario: cada ejemplar tal como es de verdad (su desgaste, su pattern, su funda, su sello, su firma). Los dos necesitáis Curator 1.14.3.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Una carta mostrada en el chat es ese mismo ejemplar: su desgaste, su nota, su sello y su firma van con ella.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "El canal de chat de los coleccionistas ya funciona: su nombre en el juego es ahora curatoralli o curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Las alertas de tu hermandad: apagadas del todo, solo épicas y mejores, o movidas adonde quieras (/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Puedes volver a elegir tu personaje principal, una vez: conéctate con él y escribe /curator main.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI e Immersion: lo que Curator añade a los diálogos del juego ahora aparece junto a su ventana.",
})

Add("esMX", {
	["Curator has been updated"] = "Curator se actualizó",
	["What is new in Curator %s"] = "Novedades de Curator %s",
	["/curator news: this window again"] = "/curator novedades: volver a ver esta ventana",
	["/curator news: what is new in this version"] = "/curator novedades: las novedades de esta versión",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "Los intercambios y las ventas al revendedor ya no necesitan la aplicación de Curator: solo la Bolsa la sigue pidiendo.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "La colección de otro jugador se abre en su inventario: cada ejemplar tal como es de verdad (su desgaste, su pattern, su funda, su sello, su firma). Los dos necesitan Curator 1.14.3.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Una carta mostrada en el chat es ese mismo ejemplar: su desgaste, su nota, su sello y su firma van con ella.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "El canal de chat de los coleccionistas ya funciona: su nombre en el juego es ahora curatoralli o curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Las alertas de tu hermandad: apagadas del todo, solo épicas y mejores, o movidas adonde quieras (/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Puedes volver a elegir tu personaje principal, una vez: conéctate con él y escribe /curator main.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI e Immersion: lo que Curator agrega a los diálogos del juego ahora aparece junto a su ventana.",
})

Add("ptBR", {
	["Curator has been updated"] = "O Curator foi atualizado",
	["What is new in Curator %s"] = "Novidades do Curator %s",
	["/curator news: this window again"] = "/curator novidades: ver esta janela de novo",
	["/curator news: what is new in this version"] = "/curator novidades: as novidades desta versão",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "As trocas e as vendas ao revendedor não precisam mais do aplicativo do Curator: só a Bolsa ainda pede.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "A coleção de outro jogador abre no inventário dele: cada exemplar como realmente é (desgaste, pattern, estojo, selo, assinatura). Os dois precisam do Curator 1.14.3.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Uma carta mostrada no chat é o próprio exemplar: o desgaste, a nota, o selo e a assinatura vão junto.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "O canal de bate-papo dos colecionadores agora funciona: o nome dele no jogo é curatoralli ou curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Os alertas da sua guilda: desligados de vez, só épicas e melhores, ou movidos para onde quiser (/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Seu personagem principal pode ser escolhido de novo, uma vez: entre com ele e digite /curator main.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI e Immersion: o que o Curator acrescenta aos diálogos do jogo agora aparece ao lado da janela deles.",
})

Add("ruRU", {
	["Curator has been updated"] = "Curator обновлён",
	["What is new in Curator %s"] = "Что нового в Curator %s",
	["/curator news: this window again"] = "/curator news: снова открыть это окно",
	["/curator news: what is new in this version"] = "/curator news: что нового в этой версии",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "Для обменов и продаж перекупщику больше не нужно приложение Curator: оно нужно только для Биржи.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "Коллекция другого игрока открывается на его инвентаре: каждый экземпляр таким, какой он есть на самом деле (износ, паттерн, кейс, печать, подпись). Curator 1.14.3 нужен вам обоим.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "Карта, показанная в чате, является тем самым экземпляром: её износ, оценка, печать и подпись идут вместе с ней.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "Чат-канал коллекционеров теперь работает: в игре он называется curatoralli или curatorhord.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "Оповещения твоей гильдии: выключить совсем, только эпические и лучше или переместить куда угодно (/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "Основного персонажа можно выбрать заново, один раз: зайди им и введи /curator main.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI и Immersion: то, что Curator добавляет в диалоги игры, теперь показано рядом с их окном.",
})

Add("koKR", {
	["Curator has been updated"] = "Curator가 업데이트되었습니다",
	["What is new in Curator %s"] = "Curator %s의 새로운 점",
	["/curator news: this window again"] = "/curator news: 이 창 다시 보기",
	["/curator news: what is new in this version"] = "/curator news: 이번 버전의 새로운 점",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "교환과 재판매상 판매에 더 이상 Curator 앱이 필요하지 않습니다. 거래소만 여전히 앱이 필요합니다.",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "다른 플레이어의 수집품이 보관함으로 열립니다. 각 카드를 실제 모습 그대로(마모, 패턴, 케이스, 봉인, 서명) 볼 수 있습니다. 두 사람 모두 Curator 1.14.3이 필요합니다.",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "채팅에 보여 준 카드는 바로 그 카드입니다. 마모, 등급, 봉인, 서명이 함께 전달됩니다.",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "수집가 대화 채널이 이제 작동합니다. 게임 안에서의 이름은 curatoralli 또는 curatorhord입니다.",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "길드 알림: 완전히 끄기, 영웅 등급 이상만 보기, 원하는 곳으로 옮기기(/curator alerts).",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "주 캐릭터를 한 번 다시 고를 수 있습니다. 그 캐릭터로 접속해 /curator main 을 입력하세요.",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI와 Immersion: Curator가 게임 대화에 더하는 내용이 이제 대화 창 옆에 표시됩니다.",
})

Add("zhCN", {
	["Curator has been updated"] = "Curator 已更新",
	["What is new in Curator %s"] = "Curator %s 的新内容",
	["/curator news: this window again"] = "/curator news：再次打开此窗口",
	["/curator news: what is new in this version"] = "/curator news：本版本的新内容",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "交换和卖给转卖商不再需要 Curator 应用：只有交易所仍然需要。",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "其他玩家的收藏会在其库存中打开：每张卡都是它真实的样子（磨损、图案、评级盒、封印、签名）。双方都需要 Curator 1.14.3。",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "在聊天中展示的卡牌就是那一张：它的磨损、评级、封印和签名都会随之一起。",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "收藏家聊天频道现已可用：它在游戏中的名称为 curatoralli 或 curatorhord。",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "公会提醒：可完全关闭、仅显示史诗及以上，或移到你想要的位置（/curator alerts）。",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "可以再选择一次主角色：用它登录并输入 /curator main。",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI 和 Immersion：Curator 在游戏对话中添加的内容现在显示在对话窗口旁边。",
})

Add("zhTW", {
	["Curator has been updated"] = "Curator 已更新",
	["What is new in Curator %s"] = "Curator %s 的新內容",
	["/curator news: this window again"] = "/curator news：再次打開此視窗",
	["/curator news: what is new in this version"] = "/curator news：本版本的新內容",
	["Trades and sales to the reseller no longer need the Curator app: only the Steamwheedle Exchange still asks for it."] = "交換和賣給轉賣商不再需要 Curator 應用程式：只有交易所仍然需要。",
	["Another player's collection opens on their inventory: each copy as it really is (its wear, its pattern, its case, its seal, its signature). Both of you need Curator 1.14.3."] = "其他玩家的收藏會在其庫存中打開：每張卡都是它真實的樣子（磨損、圖案、評級盒、封印、簽名）。雙方都需要 Curator 1.14.3。",
	["A card shown in the chat is the very copy: its wear, its grade, its seal and its signature go with it."] = "在聊天中展示的卡牌就是那一張：它的磨損、評級、封印和簽名都會隨之一起。",
	["The chat channel of the collectors now works: its name in the game is curatoralli or curatorhord."] = "收藏家聊天頻道現已可用：它在遊戲中的名稱為 curatoralli 或 curatorhord。",
	["The alerts of your guild: off for good, epic cards and better only, or moved where you like (/curator alerts)."] = "公會提醒：可完全關閉、僅顯示史詩及以上，或移到你想要的位置（/curator alerts）。",
	["Your main character can be chosen again, once: log in with it and type /curator main."] = "可以再選擇一次主角色：用它登入並輸入 /curator main。",
	["Dialogue UI and Immersion: what Curator adds to the dialogues of the game now shows beside their window."] = "Dialogue UI 和 Immersion：Curator 在遊戲對話中加入的內容現在顯示在對話視窗旁邊。",
})

-- (1.14.3, his test of November 6: the channel of the collectors not joined) Said when it could not be joined after
-- three tries (Channel.lua: CH:Joined).
Add("frFR", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "Impossible de rejoindre le canal de discussion des collectionneurs : /join %s le rejoint à la main.",
})
Add("deDE", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "Dem Chatkanal der Sammler konnte nicht beigetreten werden: /join %s tritt ihm von Hand bei.",
})
Add("esES", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "No se pudo entrar en el canal de chat de los coleccionistas: /join %s entra a mano.",
})
Add("esMX", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "No se pudo entrar al canal de chat de los coleccionistas: /join %s entra a mano.",
})
Add("ptBR", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "Não foi possível entrar no canal de bate-papo dos colecionadores: /join %s entra nele manualmente.",
})
Add("ruRU", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "Не удалось войти в чат-канал коллекционеров: введи /join %s, чтобы войти вручную.",
})
Add("koKR", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "수집가 대화 채널에 들어가지 못했습니다. /join %s 로 직접 들어갈 수 있습니다.",
})
Add("zhCN", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "无法加入收藏家聊天频道：输入 /join %s 手动加入。",
})
Add("zhTW", {
	["The chat channel of the collectors could not be joined: /join %s joins it by hand."] = "無法加入收藏家聊天頻道：輸入 /join %s 手動加入。",
})
