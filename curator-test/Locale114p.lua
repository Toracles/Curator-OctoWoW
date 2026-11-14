local _, ns = "Curator", CuratorOctoFull

-- (1.14.0, his idea) The words of the patterns of the titanforged copies (Patterns.lua, UI/Card.lua, UI/Links.lua) and of their
-- preview (UI/PatternsView.lua). They go into the tables of Locale.lua (English keys; a missing one falls back to English;
-- esMX shares the table of esES). "Pattern": the word of CS2, as the players say it.
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
	["Rank: %s"] = "Rang : %s",
	["Cards of the cases"] = "Cartes des caisses",
	["Cards of the albums"] = "Cartes des albums",
	["Wear"] = "Usure",
	["Wear: 10 to 1, then two by chance"] = "Usure : de 10 à 1, puis deux au hasard",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "Trop d'exemplaires expertisés, restaurés, corrompus ou titanforged pour un seul échange : choisis-en moins.",
	["With it: a copy, pattern %d"] = "Avec : un exemplaire, pattern %d",
	["Patterns %s"] = "Patterns %s",
	["Pattern %d"] = "Pattern %d",
	["Patterns"] = "Patterns",
	["Patterns %d to %d of %d"] = "Patterns %d à %d sur %d",
	["Previous"] = "Précédents",
	["Next"] = "Suivants",
	["Rarity: %s"] = "Rareté : %s",
	["Another card"] = "Autre carte",
	["Click a card to see it up close."] = "Clique sur une carte pour la voir en grand.",
})

Add("deDE", {
	["Rank: %s"] = "Rang: %s",
	["Cards of the cases"] = "Karten der Kisten",
	["Cards of the albums"] = "Karten der Alben",
	["Wear"] = "Abnutzung",
	["Wear: 10 to 1, then two by chance"] = "Abnutzung: 10 bis 1, dann zwei zufällig",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "Zu viele begutachtete, restaurierte, verderbte oder titanengeschmiedete Exemplare für einen Tausch: Wähle weniger davon.",
	["With it: a copy, pattern %d"] = "Dabei: ein Exemplar, Pattern %d",
	["Patterns %s"] = "Patterns %s",
	["Pattern %d"] = "Pattern %d",
	["Patterns"] = "Patterns",
	["Patterns %d to %d of %d"] = "Patterns %d bis %d von %d",
	["Previous"] = "Zurück",
	["Next"] = "Weiter",
	["Rarity: %s"] = "Seltenheit: %s",
	["Another card"] = "Andere Karte",
	["Click a card to see it up close."] = "Klicke auf eine Karte, um sie groß zu sehen.",
})

Add("esES", {
	["Rank: %s"] = "Rango: %s",
	["Cards of the cases"] = "Cartas de las cajas",
	["Cards of the albums"] = "Cartas de los álbumes",
	["Wear"] = "Desgaste",
	["Wear: 10 to 1, then two by chance"] = "Desgaste: de 10 a 1, luego dos al azar",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "Demasiadas copias tasadas, restauradas, corruptas o forjadas por los titanes para un solo intercambio: elige menos.",
	["With it: a copy, pattern %d"] = "Con ella: una copia, pattern %d",
	["Patterns %s"] = "Patterns %s",
	["Pattern %d"] = "Pattern %d",
	["Patterns"] = "Patterns",
	["Patterns %d to %d of %d"] = "Patterns %d a %d de %d",
	["Previous"] = "Anteriores",
	["Next"] = "Siguientes",
	["Rarity: %s"] = "Rareza: %s",
	["Another card"] = "Otra carta",
	["Click a card to see it up close."] = "Haz clic en una carta para verla en grande.",
})

Add("ptBR", {
	["Rank: %s"] = "Patente: %s",
	["Cards of the cases"] = "Cartas das caixas",
	["Cards of the albums"] = "Cartas dos álbuns",
	["Wear"] = "Desgaste",
	["Wear: 10 to 1, then two by chance"] = "Desgaste: de 10 a 1, depois dois ao acaso",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "Cópias avaliadas, restauradas, corrompidas ou forjadas pelos titãs demais para uma só troca: escolha menos.",
	["With it: a copy, pattern %d"] = "Com ela: uma cópia, pattern %d",
	["Patterns %s"] = "Patterns %s",
	["Pattern %d"] = "Pattern %d",
	["Patterns"] = "Patterns",
	["Patterns %d to %d of %d"] = "Patterns %d a %d de %d",
	["Previous"] = "Anteriores",
	["Next"] = "Próximos",
	["Rarity: %s"] = "Raridade: %s",
	["Another card"] = "Outra carta",
	["Click a card to see it up close."] = "Clique numa carta para vê-la em grande.",
})

Add("ruRU", {
	["Rank: %s"] = "Ранг: %s",
	["Cards of the cases"] = "Карты ящиков",
	["Cards of the albums"] = "Карты альбомов",
	["Wear"] = "Износ",
	["Wear: 10 to 1, then two by chance"] = "Износ: от 10 до 1, затем две случайные",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "Слишком много оцененных, восстановленных, оскверненных или выкованных титанами копий для одного обмена: выберите меньше.",
	["With it: a copy, pattern %d"] = "Вместе с ней: копия, паттерн %d",
	["Patterns %s"] = "Паттерны %s",
	["Pattern %d"] = "Паттерн %d",
	["Patterns"] = "Паттерны",
	["Patterns %d to %d of %d"] = "Паттерны %d-%d из %d",
	["Previous"] = "Назад",
	["Next"] = "Далее",
	["Rarity: %s"] = "Редкость: %s",
	["Another card"] = "Другая карта",
	["Click a card to see it up close."] = "Нажмите на карту, чтобы рассмотреть ее.",
})

Add("koKR", {
	["Rank: %s"] = "등급: %s",
	["Cards of the cases"] = "상자 카드",
	["Cards of the albums"] = "앨범 카드",
	["Wear"] = "마모",
	["Wear: 10 to 1, then two by chance"] = "마모: 10부터 1까지, 그다음 무작위 둘",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "한 번의 교환에 감정되거나 복원되거나 타락하거나 티탄벼림된 카드가 너무 많습니다: 더 적게 고르세요.",
	["With it: a copy, pattern %d"] = "함께: 카드 1장, 패턴 %d",
	["Patterns %s"] = "패턴 %s",
	["Pattern %d"] = "패턴 %d",
	["Patterns"] = "패턴",
	["Patterns %d to %d of %d"] = "패턴 %d~%d / %d",
	["Previous"] = "이전",
	["Next"] = "다음",
	["Rarity: %s"] = "희귀도: %s",
	["Another card"] = "다른 카드",
	["Click a card to see it up close."] = "카드를 클릭하면 크게 볼 수 있습니다.",
})

Add("zhCN", {
	["Rank: %s"] = "等级：%s",
	["Cards of the cases"] = "箱子卡牌",
	["Cards of the albums"] = "图鉴卡牌",
	["Wear"] = "磨损",
	["Wear: 10 to 1, then two by chance"] = "磨损：从 10 到 1，然后随机两张",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "一次交换中经过鉴定、修复、腐化或泰坦造物的卡牌太多：请少选一些。",
	["With it: a copy, pattern %d"] = "附带：一张卡牌，图案 %d",
	["Patterns %s"] = "图案 %s",
	["Pattern %d"] = "图案 %d",
	["Patterns"] = "图案",
	["Patterns %d to %d of %d"] = "图案 %d 至 %d，共 %d",
	["Previous"] = "上一页",
	["Next"] = "下一页",
	["Rarity: %s"] = "稀有度：%s",
	["Another card"] = "换一张卡",
	["Click a card to see it up close."] = "点击卡牌放大查看。",
})

Add("zhTW", {
	["Rank: %s"] = "等級：%s",
	["Cards of the cases"] = "箱子卡牌",
	["Cards of the albums"] = "圖鑑卡牌",
	["Wear"] = "磨損",
	["Wear: 10 to 1, then two by chance"] = "磨損：從 10 到 1，然後隨機兩張",
	["Too many appraised, restored, corrupted or titanforged copies for one trade: choose fewer of them."] = "一次交換中經過鑑定、修復、腐化或泰坦鑄造的卡牌太多：請少選一些。",
	["With it: a copy, pattern %d"] = "附帶：一張卡牌，圖案 %d",
	["Patterns %s"] = "圖案 %s",
	["Pattern %d"] = "圖案 %d",
	["Patterns"] = "圖案",
	["Patterns %d to %d of %d"] = "圖案 %d 至 %d，共 %d",
	["Previous"] = "上一頁",
	["Next"] = "下一頁",
	["Rarity: %s"] = "稀有度：%s",
	["Another card"] = "換一張卡",
	["Click a card to see it up close."] = "點擊卡牌放大檢視。",
})

-- (31 October, his idea: the creatures in 2D) The creature of a card in 3D, on asking (UI/Inspect.lua: I:Live3D).
Add("frFR", { ["See in 3D"] = "Voir en 3D", ["See the card"] = "Voir la carte" })
Add("deDE", { ["See in 3D"] = "In 3D ansehen", ["See the card"] = "Karte ansehen" })
Add("esES", { ["See in 3D"] = "Ver en 3D", ["See the card"] = "Ver la carta" })
Add("ptBR", { ["See in 3D"] = "Ver em 3D", ["See the card"] = "Ver a carta" })
Add("ruRU", { ["See in 3D"] = "Смотреть в 3D", ["See the card"] = "Смотреть карту" })
Add("koKR", { ["See in 3D"] = "3D로 보기", ["See the card"] = "카드 보기" })
Add("zhCN", { ["See in 3D"] = "3D查看", ["See the card"] = "查看卡牌" })
Add("zhTW", { ["See in 3D"] = "3D檢視", ["See the card"] = "檢視卡牌" })
