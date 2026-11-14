local _, ns = "Curator", CuratorOctoFull

-- (1.14.0, after its second test) The words of the cards of the cases in the menus of the cards of the boosters: shown
-- big in the album (UI/CaseDetail.lua), the pages of their collections (UI/CaseAlbum.lua), their contracts on the desk of
-- the notary (UI/CaseContract.lua), the showcase and the chat. They go into the tables of Locale.lua (English keys; a
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
	["A weapon of legend"] = "Arme de légende",
	["All collections"] = "Toutes les collections",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "Dix cartes d'un rang en donnent une du rang suivant, jusqu'à Secret. Les cartes des caisses ne s'échangent qu'entre elles.",
	["Contracts of the cases"] = "Contrats des caisses",
	["Contracts of the boosters"] = "Contrats des boosters",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "Choisis dix cartes de même rang : clique sur une carte pour la mettre dans le contrat.",
	["The appraised copies stay in your album: they never go into a contract."] = "Les exemplaires expertisés restent dans ton album : ils ne vont jamais dans un contrat.",
	["Click: a contract of this rank"] = "Clic : un contrat de ce rang",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "Les cartes de toutes les collections des caisses, ou d'une seule (les flèches du titre aussi).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "Les places vides prennent les cartes qui ont le plus d'exemplaires échangeables (des collections choisies plus haut), leurs exemplaires les plus modestes d'abord ; jamais un exemplaire thunderforged ni titanforged.",
	["Its copies to spare: %s"] = "Ses exemplaires échangeables : %s",
})

Add("deDE", {
	["A weapon of legend"] = "Legendäre Waffe",
	["All collections"] = "Alle Sammlungen",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "Zehn Karten eines Rangs ergeben eine des nächsten, bis Verdeckt. Die Karten der Kisten werden nur untereinander getauscht.",
	["Contracts of the cases"] = "Verträge der Kisten",
	["Contracts of the boosters"] = "Verträge der Booster",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "Wähle zehn Karten des gleichen Rangs: Klicke auf eine Karte, um sie in den Vertrag zu legen.",
	["The appraised copies stay in your album: they never go into a contract."] = "Begutachtete Exemplare bleiben in deinem Album: Sie kommen nie in einen Vertrag.",
	["Click: a contract of this rank"] = "Klick: ein Vertrag dieses Rangs",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "Die Karten aller Sammlungen der Kisten oder nur einer einzigen (auch mit den Pfeilen des Titels).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "Die freien Plätze nehmen die Karten mit den meisten tauschbaren Exemplaren (aus den oben gewählten Sammlungen), ihre schlichtesten Exemplare zuerst; nie ein donnergeschmiedetes oder titanengeschmiedetes.",
	["Its copies to spare: %s"] = "Ihre tauschbaren Exemplare: %s",
})

local es = {
	["A weapon of legend"] = "Arma legendaria",
	["All collections"] = "Todas las colecciones",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "Diez cartas de un rango dan una del siguiente, hasta Encubierto. Las cartas de las cajas solo se intercambian entre ellas.",
	["Contracts of the cases"] = "Contratos de las cajas",
	["Contracts of the boosters"] = "Contratos de los sobres",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "Elige diez cartas del mismo rango: haz clic en una carta para ponerla en el contrato.",
	["The appraised copies stay in your album: they never go into a contract."] = "Las copias tasadas se quedan en tu álbum: nunca entran en un contrato.",
	["Click: a contract of this rank"] = "Clic: un contrato de este rango",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "Las cartas de todas las colecciones de las cajas o de una sola (también con las flechas del título).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "Los huecos libres se llenan con las cartas que tienen más copias para intercambiar (de las colecciones elegidas arriba), primero sus copias más modestas; nunca una forjada por el trueno o por los titanes.",
	["Its copies to spare: %s"] = "Sus copias para intercambiar: %s",
}
Add("esES", es)
Add("esMX", es)

Add("ptBR", {
	["A weapon of legend"] = "Arma lendária",
	["All collections"] = "Todas as coleções",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "Dez cartas de uma categoria dão uma da seguinte, até Secreto. As cartas das caixas só são trocadas entre si.",
	["Contracts of the cases"] = "Contratos das caixas",
	["Contracts of the boosters"] = "Contratos dos pacotes",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "Escolha dez cartas da mesma categoria: clique em uma carta para colocá-la no contrato.",
	["The appraised copies stay in your album: they never go into a contract."] = "As cópias avaliadas ficam no seu álbum: nunca entram em um contrato.",
	["Click: a contract of this rank"] = "Clique: um contrato desta categoria",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "As cartas de todas as coleções das caixas ou de uma só (as setas do título também).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "Os espaços vazios recebem as cartas com mais cópias para trocar (das coleções escolhidas acima), primeiro as cópias mais simples; nunca uma forjada pelo trovão ou pelos titãs.",
	["Its copies to spare: %s"] = "Suas cópias para trocar: %s",
})

Add("ruRU", {
	["A weapon of legend"] = "Легендарное оружие",
	["All collections"] = "Все коллекции",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "Десять карт одного ранга дают одну карту следующего, вплоть до «Тайного». Карты из ящиков обмениваются только между собой.",
	["Contracts of the cases"] = "Договоры ящиков",
	["Contracts of the boosters"] = "Договоры бустеров",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "Выберите десять карт одного ранга: нажмите на карту, чтобы добавить её в договор.",
	["The appraised copies stay in your album: they never go into a contract."] = "Оценённые копии остаются в вашем альбоме: они никогда не идут в договор.",
	["Click: a contract of this rank"] = "Щелчок: договор этого ранга",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "Карты всех коллекций ящиков или только одной (стрелки заголовка тоже).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "Пустые места займут карты, у которых больше всего копий для обмена (из коллекций, выбранных выше), сначала самые простые копии; никогда не выкованные громом или титанами.",
	["Its copies to spare: %s"] = "Её копии для обмена: %s",
})

Add("koKR", {
	["A weapon of legend"] = "전설의 무기",
	["All collections"] = "모든 컬렉션",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "같은 등급 카드 10장으로 다음 등급 카드 1장을 얻습니다(은밀까지). 상자 카드는 서로끼리만 교환할 수 있습니다.",
	["Contracts of the cases"] = "상자 계약서",
	["Contracts of the boosters"] = "부스터 계약서",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "같은 등급의 카드 10장을 고르세요: 카드를 클릭하면 계약서에 들어갑니다.",
	["The appraised copies stay in your album: they never go into a contract."] = "감정된 카드는 앨범에 남습니다: 계약서에는 절대 들어가지 않습니다.",
	["Click: a contract of this rank"] = "클릭: 이 등급의 계약서",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "모든 상자 컬렉션의 카드, 또는 한 컬렉션의 카드만(제목의 화살표로도).",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "빈 자리에 교환 가능한 카드가 가장 많은 카드가 들어갑니다(위에서 고른 컬렉션 중에서). 가장 평범한 사본부터 넣으며, 천둥벼림과 티탄벼림 사본은 넣지 않습니다.",
	["Its copies to spare: %s"] = "교환 가능한 사본: %s",
})

Add("zhCN", {
	["A weapon of legend"] = "传说武器",
	["All collections"] = "所有收藏",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "十张同等级的卡牌换一张下一等级的卡牌，最高到隐秘。箱子卡牌只能彼此交换。",
	["Contracts of the cases"] = "箱子契约",
	["Contracts of the boosters"] = "补充包契约",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "选择十张同等级的卡牌：点击卡牌将其放入契约。",
	["The appraised copies stay in your album: they never go into a contract."] = "已鉴定的卡牌会留在你的收藏册中：它们绝不会放入契约。",
	["Click: a contract of this rank"] = "点击：此等级的契约",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "所有箱子收藏的卡牌，或只看一个（标题的箭头也可以）。",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "空位会放入可交换数量最多的卡牌（来自上方选择的收藏），先放最普通的副本；从不放入雷霆铸造或泰坦造物的副本。",
	["Its copies to spare: %s"] = "可交换的副本：%s",
})

Add("zhTW", {
	["A weapon of legend"] = "傳說武器",
	["All collections"] = "所有收藏",
	["Ten cards of a rank give one of the next, up to Covert. The cards of the cases are exchanged between them only."] = "十張同等級的卡牌換一張下一等級的卡牌，最高到隱密。箱子卡牌只能彼此交換。",
	["Contracts of the cases"] = "箱子契約",
	["Contracts of the boosters"] = "補充包契約",
	["Choose ten cards of the same rank: click a card to put it in the contract."] = "選擇十張同等級的卡牌：點擊卡牌將其放入契約。",
	["The appraised copies stay in your album: they never go into a contract."] = "已鑑定的卡牌會留在你的收藏冊中：它們絕不會放入契約。",
	["Click: a contract of this rank"] = "點擊：此等級的契約",
	["The cards of every collection of the cases, or of one only (the arrows of the title too)."] = "所有箱子收藏的卡牌，或只看一個（標題的箭頭也可以）。",
	["The empty places take the cards with the most copies to spare (of the collections chosen above), their plainest copies first; never a thunderforged or titanforged one."] = "空位會放入可交換數量最多的卡牌（來自上方選擇的收藏），先放最普通的副本；從不放入雷霆鑄造或泰坦鑄造的副本。",
	["Its copies to spare: %s"] = "可交換的副本：%s",
})
