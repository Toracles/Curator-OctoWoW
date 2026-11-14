local _, ns = "Curator", CuratorOctoFull

-- (1.14.0) The words of the case of the month (UI/Crate.lua, UI/CrateCard.lua, CrateItems.lua): the case of the Paladin
-- Collection, its first edition, the trees of the paladin (the names of the game), what its cards are, how its cards are
-- turned. They go into the tables of Locale.lua
-- (English keys; a missing one falls back to English).
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
	["Paladin Collection Case No. 1"] = "Caisse Collection Paladin N°1",
	["Drag the card to turn it. Click beside it to close."] = "Fais glisser la carte pour la tourner. Clique à côté pour fermer.",
	["A preview of the opening: nothing is kept."] = "Un aperçu de l'ouverture : rien n'est gardé.",
	["Holy"] = "Sacré",
	["Protection"] = "Protection",
	["Retribution"] = "Vindicte",
	["Paladin spell  ·  %s"] = "Sort de paladin  ·  %s",
	["Master of the paladins in %s"] = "Maître des paladins à %s",
})

Add("deDE", {
	["Paladin Collection Case No. 1"] = "Paladin-Kollektion: Kiste Nr. 1",
	["Drag the card to turn it. Click beside it to close."] = "Ziehe die Karte, um sie zu drehen. Klicke daneben, um zu schließen.",
	["A preview of the opening: nothing is kept."] = "Eine Vorschau der Öffnung: nichts wird behalten.",
	["Holy"] = "Heilig",
	["Protection"] = "Schutz",
	["Retribution"] = "Vergeltung",
	["Paladin spell  ·  %s"] = "Paladinzauber  ·  %s",
	["Master of the paladins in %s"] = "Paladinlehrer in %s",
})

Add("esES", {
	["Paladin Collection Case No. 1"] = "Caja Colección Paladín n.º 1",
	["Drag the card to turn it. Click beside it to close."] = "Arrastra la carta para girarla. Haz clic fuera para cerrar.",
	["A preview of the opening: nothing is kept."] = "Una vista previa de la apertura: no se guarda nada.",
	["Holy"] = "Sagrado",
	["Protection"] = "Protección",
	["Retribution"] = "Reprensión",
	["Paladin spell  ·  %s"] = "Hechizo de paladín  ·  %s",
	["Master of the paladins in %s"] = "Instructor de paladines en %s",
})

Add("esMX", {
	["Paladin Collection Case No. 1"] = "Caja Colección Paladín n.º 1",
	["Drag the card to turn it. Click beside it to close."] = "Arrastra la carta para girarla. Haz clic fuera para cerrar.",
	["A preview of the opening: nothing is kept."] = "Una vista previa de la apertura: no se guarda nada.",
	["Holy"] = "Sagrado",
	["Protection"] = "Protección",
	["Retribution"] = "Reprensión",
	["Paladin spell  ·  %s"] = "Hechizo de paladín  ·  %s",
	["Master of the paladins in %s"] = "Instructor de paladines en %s",
})

Add("ptBR", {
	["Paladin Collection Case No. 1"] = "Caixa Coleção Paladino nº 1",
	["Drag the card to turn it. Click beside it to close."] = "Arraste a carta para girá-la. Clique fora para fechar.",
	["A preview of the opening: nothing is kept."] = "Uma prévia da abertura: nada é guardado.",
	["Holy"] = "Sagrado",
	["Protection"] = "Proteção",
	["Retribution"] = "Retribuição",
	["Paladin spell  ·  %s"] = "Feitiço de paladino  ·  %s",
	["Master of the paladins in %s"] = "Mestre dos paladinos em %s",
})

Add("ruRU", {
	["Paladin Collection Case No. 1"] = "Ящик «Коллекция паладина» № 1",
	["Drag the card to turn it. Click beside it to close."] = "Перетащите карту, чтобы повернуть её. Нажмите рядом, чтобы закрыть.",
	["A preview of the opening: nothing is kept."] = "Предпросмотр открытия: ничего не сохраняется.",
	["Holy"] = "Свет",
	["Protection"] = "Защита",
	["Retribution"] = "Воздаяние",
	["Paladin spell  ·  %s"] = "Заклинание паладина  ·  %s",
	["Master of the paladins in %s"] = "Наставник паладинов: %s",
})

Add("koKR", {
	["Paladin Collection Case No. 1"] = "성기사 컬렉션 상자 1호",
	["Drag the card to turn it. Click beside it to close."] = "카드를 끌어서 돌려 보세요. 바깥을 클릭하면 닫힙니다.",
	["A preview of the opening: nothing is kept."] = "개봉 미리보기: 아무것도 보관되지 않습니다.",
	["Holy"] = "신성",
	["Protection"] = "보호",
	["Retribution"] = "징벌",
	["Paladin spell  ·  %s"] = "성기사 주문  ·  %s",
	["Master of the paladins in %s"] = "%s의 상급 성기사",
})

Add("zhCN", {
	["Paladin Collection Case No. 1"] = "圣骑士收藏箱 1号",
	["Drag the card to turn it. Click beside it to close."] = "拖动卡牌即可旋转。点击旁边即可关闭。",
	["A preview of the opening: nothing is kept."] = "开箱预览：什么都不会保留。",
	["Holy"] = "神圣",
	["Protection"] = "防护",
	["Retribution"] = "惩戒",
	["Paladin spell  ·  %s"] = "圣骑士法术  ·  %s",
	["Master of the paladins in %s"] = "%s的圣骑士训练师",
})

Add("zhTW", {
	["Paladin Collection Case No. 1"] = "聖騎士收藏箱 1號",
	["Drag the card to turn it. Click beside it to close."] = "拖曳卡牌即可旋轉。點擊旁邊即可關閉。",
	["A preview of the opening: nothing is kept."] = "開箱預覽：什麼都不會保留。",
	["Holy"] = "神聖",
	["Protection"] = "防護",
	["Retribution"] = "懲戒",
	["Paladin spell  ·  %s"] = "聖騎士法術  ·  %s",
	["Master of the paladins in %s"] = "%s的聖騎士訓練師",
})
