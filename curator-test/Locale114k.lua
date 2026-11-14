local _, ns = "Curator", CuratorOctoFull

-- (1.14.0) The words of the cases for real (Cases.lua, UI/Crate.lua): their drops, their keys, their openings, the cards
-- of their collection, the cases in the inventory, the minimap, the ledger, the chest of a reroll. They go into the
-- tables of Locale.lua (English keys; a missing one falls back to English).
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
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator caisses : tes caisses, leurs clés et les cartes qu'elles t'ont données",
	["Back to the case"] = "Retour à la caisse",
	["Cases to open: %d  ·  Keys: %d"] = "Caisses à ouvrir : %d  ·  Clés : %d",
	["%s: %d / %d cards"] = "%s : %d / %d cartes",
	["Weapons of legend: %d"] = "Armes de légende : %d",
	["Paladin Collection 2026"] = "Collection Paladin 2026",
	["Buy a key"] = "Acheter une clé",
	["Yours: %d"] = "Dans ta collection : %d",
	["Thunderforged: %d"] = "Thunderforged : %d",
	["Titanforged: %d"] = "Titanforged : %d",
	["Your finest: %s"] = "Ta plus belle : %s",
	["Not in your collection yet."] = "Pas encore dans ta collection.",
	["A key of the %s, for %s."] = "Une clé de la %s, pour %s.",
	["A key of the %s"] = "Clé de la %s",
	["One key opens one case of its edition."] = "Une clé ouvre une caisse de son édition.",
	["A case and a key of its edition: one card, yours."] = "Une caisse et une clé de son édition : une carte, à toi.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Les caisses tombent des créatures qui donnent de l'expérience (1 sur 100) et des quêtes rendues (4 sur 100).",
	["Out of the case: %s (%s, %s)."] = "Sortie de la caisse : %s (%s, %s).",
	["Cases found: %d"] = "Caisses trouvées : %d",
	["A case!"] = "Une caisse !",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Aucune caisse de cette édition à ouvrir : elles tombent des créatures qui donnent de l'expérience (1 sur 100) et des quêtes rendues (4 sur 100).",
	["To open it, a key of its edition: %s."] = "Pour l'ouvrir, une clé de son édition : %s.",
	["Curator is closed: no case can be opened."] = "Curator est fermé : aucune caisse ne peut être ouverte.",
	["Cases"] = "Caisses",
	["Click: show them."] = "Clic : les voir.",
	["Cases to open: %d (/curator cases)"] = "Caisses à ouvrir : %d (/curator caisses)",
	["A key of a case"] = "Une clé de caisse",
	["Cases: %d"] = "Caisses : %d",
})

Add("deDE", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator kisten: deine Kisten, ihre Schlüssel und die Karten, die sie dir gaben",
	["Back to the case"] = "Zurück zur Kiste",
	["Cases to open: %d  ·  Keys: %d"] = "Ungeöffnete Kisten: %d  ·  Schlüssel: %d",
	["%s: %d / %d cards"] = "%s: %d / %d Karten",
	["Weapons of legend: %d"] = "Legendäre Waffen: %d",
	["Paladin Collection 2026"] = "Paladin-Kollektion 2026",
	["Buy a key"] = "Schlüssel kaufen",
	["Yours: %d"] = "In deiner Sammlung: %d",
	["Thunderforged: %d"] = "Donnergeschmiedet: %d",
	["Titanforged: %d"] = "Titanengeschmiedet: %d",
	["Your finest: %s"] = "Dein bestes Exemplar: %s",
	["Not in your collection yet."] = "Noch nicht in deiner Sammlung.",
	["A key of the %s, for %s."] = "Ein Schlüssel: %s, für %s.",
	["A key of the %s"] = "Schlüssel: %s",
	["One key opens one case of its edition."] = "Ein Schlüssel öffnet eine Kiste seiner Edition.",
	["A case and a key of its edition: one card, yours."] = "Eine Kiste und ein Schlüssel ihrer Edition: eine Karte, für dich.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Kisten fallen von Kreaturen, die Erfahrung geben (1 von 100), und von abgegebenen Quests (4 von 100).",
	["Out of the case: %s (%s, %s)."] = "Aus der Kiste: %s (%s, %s).",
	["Cases found: %d"] = "Kisten gefunden: %d",
	["A case!"] = "Eine Kiste!",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Keine Kiste dieser Edition zu öffnen: Sie fallen von Kreaturen, die Erfahrung geben (1 von 100), und von abgegebenen Quests (4 von 100).",
	["To open it, a key of its edition: %s."] = "Zum Öffnen ein Schlüssel ihrer Edition: %s.",
	["Curator is closed: no case can be opened."] = "Curator ist geschlossen: Keine Kiste kann geöffnet werden.",
	["Cases"] = "Kisten",
	["Click: show them."] = "Klick: anzeigen.",
	["Cases to open: %d (/curator cases)"] = "Ungeöffnete Kisten: %d (/curator kisten)",
	["A key of a case"] = "Ein Kistenschlüssel",
	["Cases: %d"] = "Kisten: %d",
})

local ES = {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator cajas: tus cajas, sus llaves y las cartas que te dieron",
	["Back to the case"] = "Volver a la caja",
	["Cases to open: %d  ·  Keys: %d"] = "Cajas por abrir: %d  ·  Llaves: %d",
	["%s: %d / %d cards"] = "%s: %d / %d cartas",
	["Weapons of legend: %d"] = "Armas legendarias: %d",
	["Paladin Collection 2026"] = "Colección Paladín 2026",
	["Buy a key"] = "Comprar una llave",
	["Yours: %d"] = "En tu colección: %d",
	["Thunderforged: %d"] = "Forjadas por el trueno: %d",
	["Titanforged: %d"] = "Forjadas por los titanes: %d",
	["Your finest: %s"] = "Tu mejor ejemplar: %s",
	["Not in your collection yet."] = "Aún no está en tu colección.",
	["A key of the %s, for %s."] = "Una llave de la %s, por %s.",
	["A key of the %s"] = "Llave de la %s",
	["One key opens one case of its edition."] = "Una llave abre una caja de su edición.",
	["A case and a key of its edition: one card, yours."] = "Una caja y una llave de su edición: una carta, tuya.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Las cajas caen de las criaturas que dan experiencia (1 de cada 100) y de las misiones entregadas (4 de cada 100).",
	["Out of the case: %s (%s, %s)."] = "De la caja: %s (%s, %s).",
	["Cases found: %d"] = "Cajas encontradas: %d",
	["A case!"] = "¡Una caja!",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Ninguna caja de esta edición por abrir: caen de las criaturas que dan experiencia (1 de cada 100) y de las misiones entregadas (4 de cada 100).",
	["To open it, a key of its edition: %s."] = "Para abrirla, una llave de su edición: %s.",
	["Curator is closed: no case can be opened."] = "Curator está cerrado: no se puede abrir ninguna caja.",
	["Cases"] = "Cajas",
	["Click: show them."] = "Clic: verlas.",
	["Cases to open: %d (/curator cases)"] = "Cajas por abrir: %d (/curator cajas)",
	["A key of a case"] = "Una llave de caja",
	["Cases: %d"] = "Cajas: %d",
}
Add("esES", ES)
Add("esMX", ES)

Add("ptBR", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator caixas: suas caixas, suas chaves e as cartas que elas deram",
	["Back to the case"] = "Voltar à caixa",
	["Cases to open: %d  ·  Keys: %d"] = "Caixas para abrir: %d  ·  Chaves: %d",
	["%s: %d / %d cards"] = "%s: %d / %d cartas",
	["Weapons of legend: %d"] = "Armas lendárias: %d",
	["Paladin Collection 2026"] = "Coleção Paladino 2026",
	["Buy a key"] = "Comprar uma chave",
	["Yours: %d"] = "Na sua coleção: %d",
	["Thunderforged: %d"] = "Forjadas pelo trovão: %d",
	["Titanforged: %d"] = "Forjadas pelos titãs: %d",
	["Your finest: %s"] = "Seu melhor exemplar: %s",
	["Not in your collection yet."] = "Ainda não está na sua coleção.",
	["A key of the %s, for %s."] = "Uma chave da %s, por %s.",
	["A key of the %s"] = "Chave da %s",
	["One key opens one case of its edition."] = "Uma chave abre uma caixa da sua edição.",
	["A case and a key of its edition: one card, yours."] = "Uma caixa e uma chave da sua edição: uma carta, sua.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"As caixas caem das criaturas que dão experiência (1 em 100) e das missões entregues (4 em 100).",
	["Out of the case: %s (%s, %s)."] = "Da caixa: %s (%s, %s).",
	["Cases found: %d"] = "Caixas encontradas: %d",
	["A case!"] = "Uma caixa!",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Nenhuma caixa desta edição para abrir: elas caem das criaturas que dão experiência (1 em 100) e das missões entregues (4 em 100).",
	["To open it, a key of its edition: %s."] = "Para abri-la, uma chave da sua edição: %s.",
	["Curator is closed: no case can be opened."] = "O Curator está fechado: nenhuma caixa pode ser aberta.",
	["Cases"] = "Caixas",
	["Click: show them."] = "Clique: vê-las.",
	["Cases to open: %d (/curator cases)"] = "Caixas para abrir: %d (/curator caixas)",
	["A key of a case"] = "Uma chave de caixa",
	["Cases: %d"] = "Caixas: %d",
})

Add("ruRU", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator cases: ваши ящики, их ключи и карты, которые они дали",
	["Back to the case"] = "Назад к ящику",
	["Cases to open: %d  ·  Keys: %d"] = "Ящиков к открытию: %d  ·  Ключей: %d",
	["%s: %d / %d cards"] = "%s: %d / %d карт",
	["Weapons of legend: %d"] = "Легендарное оружие: %d",
	["Paladin Collection 2026"] = "Коллекция паладина 2026",
	["Buy a key"] = "Купить ключ",
	["Yours: %d"] = "В вашей коллекции: %d",
	["Thunderforged: %d"] = "Выкованные громом: %d",
	["Titanforged: %d"] = "Выкованные титанами: %d",
	["Your finest: %s"] = "Лучший экземпляр: %s",
	["Not in your collection yet."] = "Пока нет в вашей коллекции.",
	["A key of the %s, for %s."] = "Ключ: %s, за %s.",
	["A key of the %s"] = "Ключ: %s",
	["One key opens one case of its edition."] = "Один ключ открывает один ящик своего выпуска.",
	["A case and a key of its edition: one card, yours."] = "Ящик и ключ его выпуска: одна карта, ваша.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Ящики выпадают из существ, дающих опыт (1 из 100), и за сданные задания (4 из 100).",
	["Out of the case: %s (%s, %s)."] = "Из ящика: %s (%s, %s).",
	["Cases found: %d"] = "Найдено ящиков: %d",
	["A case!"] = "Ящик!",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"Нет ящиков этого выпуска: они выпадают из существ, дающих опыт (1 из 100), и за сданные задания (4 из 100).",
	["To open it, a key of its edition: %s."] = "Чтобы открыть, нужен ключ его выпуска: %s.",
	["Curator is closed: no case can be opened."] = "Curator закрыт: ящики нельзя открыть.",
	["Cases"] = "Ящики",
	["Click: show them."] = "Щелчок: показать.",
	["Cases to open: %d (/curator cases)"] = "Ящиков к открытию: %d (/curator cases)",
	["A key of a case"] = "Ключ от ящика",
	["Cases: %d"] = "Ящики: %d",
})

Add("koKR", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator cases: 내 상자, 열쇠, 상자에서 나온 카드",
	["Back to the case"] = "상자로 돌아가기",
	["Cases to open: %d  ·  Keys: %d"] = "열 상자: %d  ·  열쇠: %d",
	["%s: %d / %d cards"] = "%s: %d / %d장",
	["Weapons of legend: %d"] = "전설의 무기: %d",
	["Paladin Collection 2026"] = "성기사 컬렉션 2026",
	["Buy a key"] = "열쇠 구매",
	["Yours: %d"] = "보유: %d",
	["Thunderforged: %d"] = "천둥벼림: %d",
	["Titanforged: %d"] = "티탄벼림: %d",
	["Your finest: %s"] = "최고 상태: %s",
	["Not in your collection yet."] = "아직 수집하지 않았습니다.",
	["A key of the %s, for %s."] = "%s 열쇠 구매: %s.",
	["A key of the %s"] = "%s 열쇠",
	["One key opens one case of its edition."] = "열쇠 하나로 같은 에디션의 상자 하나를 엽니다.",
	["A case and a key of its edition: one card, yours."] = "상자 하나와 같은 에디션의 열쇠 하나: 카드 한 장을 얻습니다.",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"상자는 경험치를 주는 생물(100분의 1)과 완료한 퀘스트(100분의 4)에서 나옵니다.",
	["Out of the case: %s (%s, %s)."] = "상자에서 나옴: %s (%s, %s).",
	["Cases found: %d"] = "상자 발견: %d",
	["A case!"] = "상자 발견!",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"열 수 있는 이 에디션의 상자가 없습니다. 상자는 경험치를 주는 생물(100분의 1)과 완료한 퀘스트(100분의 4)에서 나옵니다.",
	["To open it, a key of its edition: %s."] = "열려면 같은 에디션의 열쇠가 필요합니다: %s.",
	["Curator is closed: no case can be opened."] = "Curator가 닫혀 있습니다: 상자를 열 수 없습니다.",
	["Cases"] = "상자",
	["Click: show them."] = "클릭: 보기",
	["Cases to open: %d (/curator cases)"] = "열 상자: %d (/curator cases)",
	["A key of a case"] = "상자 열쇠",
	["Cases: %d"] = "상자: %d",
})

Add("zhCN", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator cases：你的箱子、钥匙以及开出的卡牌",
	["Back to the case"] = "返回箱子",
	["Cases to open: %d  ·  Keys: %d"] = "待开箱子：%d  ·  钥匙：%d",
	["%s: %d / %d cards"] = "%s：%d / %d 张卡牌",
	["Weapons of legend: %d"] = "传说武器：%d",
	["Paladin Collection 2026"] = "圣骑士收藏 2026",
	["Buy a key"] = "购买钥匙",
	["Yours: %d"] = "已拥有：%d",
	["Thunderforged: %d"] = "雷霆铸造：%d",
	["Titanforged: %d"] = "泰坦造物：%d",
	["Your finest: %s"] = "最佳品相：%s",
	["Not in your collection yet."] = "尚未收集。",
	["A key of the %s, for %s."] = "%s的钥匙，花费 %s。",
	["A key of the %s"] = "%s的钥匙",
	["One key opens one case of its edition."] = "一把钥匙可打开同一版本的一个箱子。",
	["A case and a key of its edition: one card, yours."] = "一个箱子加一把同版本的钥匙：一张卡牌，归你所有。",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"箱子来自提供经验的生物（1/100）和交付的任务（4/100）。",
	["Out of the case: %s (%s, %s)."] = "开箱所得：%s（%s，%s）。",
	["Cases found: %d"] = "发现箱子：%d",
	["A case!"] = "一个箱子！",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"没有可打开的该版本箱子：箱子来自提供经验的生物（1/100）和交付的任务（4/100）。",
	["To open it, a key of its edition: %s."] = "打开它需要一把同版本的钥匙：%s。",
	["Curator is closed: no case can be opened."] = "Curator 已关闭：无法打开箱子。",
	["Cases"] = "箱子",
	["Click: show them."] = "点击：查看",
	["Cases to open: %d (/curator cases)"] = "待开箱子：%d（/curator cases）",
	["A key of a case"] = "箱子钥匙",
	["Cases: %d"] = "箱子：%d",
})

Add("zhTW", {
	["/curator cases: your cases, their keys and the cards they gave"] = "/curator cases：你的箱子、鑰匙以及開出的卡牌",
	["Back to the case"] = "返回箱子",
	["Cases to open: %d  ·  Keys: %d"] = "待開箱子：%d  ·  鑰匙：%d",
	["%s: %d / %d cards"] = "%s：%d / %d 張卡牌",
	["Weapons of legend: %d"] = "傳說武器：%d",
	["Paladin Collection 2026"] = "聖騎士收藏 2026",
	["Buy a key"] = "購買鑰匙",
	["Yours: %d"] = "已擁有：%d",
	["Thunderforged: %d"] = "雷霆鑄造：%d",
	["Titanforged: %d"] = "泰坦鑄造：%d",
	["Your finest: %s"] = "最佳品相：%s",
	["Not in your collection yet."] = "尚未收集。",
	["A key of the %s, for %s."] = "%s的鑰匙，花費 %s。",
	["A key of the %s"] = "%s的鑰匙",
	["One key opens one case of its edition."] = "一把鑰匙可打開同一版本的一個箱子。",
	["A case and a key of its edition: one card, yours."] = "一個箱子加一把同版本的鑰匙：一張卡牌，歸你所有。",
	["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"箱子來自提供經驗的生物（1/100）和交付的任務（4/100）。",
	["Out of the case: %s (%s, %s)."] = "開箱所得：%s（%s，%s）。",
	["Cases found: %d"] = "發現箱子：%d",
	["A case!"] = "一個箱子！",
	["No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."] =
		"沒有可打開的該版本箱子：箱子來自提供經驗的生物（1/100）和交付的任務（4/100）。",
	["To open it, a key of its edition: %s."] = "打開它需要一把同版本的鑰匙：%s。",
	["Curator is closed: no case can be opened."] = "Curator 已關閉：無法打開箱子。",
	["Cases"] = "箱子",
	["Click: show them."] = "點擊：查看",
	["Cases to open: %d (/curator cases)"] = "待開箱子：%d（/curator cases）",
	["A key of a case"] = "箱子鑰匙",
	["Cases: %d"] = "箱子：%d",
})
