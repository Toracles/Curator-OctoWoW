local _, ns = "Curator", CuratorOctoFull

-- (1.13.0) The enchanters who restore the copies of the cards (Restore.lua), from QuestieDB (Forever): the trainers of
-- enchanting (the World Enchanting Trainer, 5038, left out). [npc] = its faction (A, H, AH). An enchanter missing here
-- is known by his title, in the language of the game (the titles of the trainers of enchanting, from the same base,
-- and those of the game itself).
ns.ENCHANTERS = {
	[1317] = "A", -- Lucan Cordell (Expert Enchanter)
	[3011] = "H", -- Teg Dawnstrider (Expert Enchanter)
	[3345] = "H", -- Godan (Expert Enchanter)
	[3606] = "A", -- Alanna Raveneye (Journeyman Enchanter)
	[4213] = "A", -- Taladan (Expert Enchanter)
	[4616] = "H", -- Lavinia Crowe (Expert Enchanter)
	[5157] = "A", -- Gimble Thistlefuzz (Expert Enchanter)
	[5695] = "H", -- Vance Undergloom (Journeyman Enchanter)
	[7949] = "A", -- Xylinnia Starshine (Expert Enchanter)
	[11065] = "A", -- Thonys Pillarstone (Journeyman Enchanter)
	[11066] = "H", -- Jhag (Journeyman Enchanter)
	[11067] = "H", -- Malcomb Wynn (Journeyman Enchanter)
	[11068] = "A", -- Betty Quin (Journeyman Enchanter)
	[11070] = "A", -- Lalina Summermoon (Journeyman Enchanter)
	[11071] = "H", -- Mot Dawnstrider (Journeyman Enchanter)
	[11072] = "A", -- Kitta Firewind (Artisan Enchanter)
	[11073] = "AH", -- Annora (Master Enchanter)
	[11074] = "H", -- Hgarth (Artisan Enchanter)
}

ns.ENCHANTER_TITLES = {
	enUS = { "Apprentice Enchanter", "Journeyman Enchanter", "Expert Enchanter", "Artisan Enchanter", "Master Enchanter", "Enchanting Trainer",
		"Enchanter", "Enchantress" },
	frFR = { "Enchanteur - Apprenti", "Enchanteur - Compagnon", "Enchanteur - compagnon", "Enchanteur - Expert", "Enchanteur - Artisan",
		"Enchanteur - Maître", "Maître des enchanteurs", "Maître enchanteur", "Enchanteur", "Enchanteresse", "Enchanteuse", "Entraîneur d'enchantement" },
	deDE = { "Verzauberkunstlehrling", "Verzauberkunstgeselle", "Verzauberkunstgesellin", "Verzauberkunstexperte", "Verzauberkunstexpertin",
		"Verzauberkunstfachmann", "Verzauberkunstfachfrau", "Verzauberkunstmeister", "Verzauberkunstmeisterin", "Verzauberkunstlehrer",
		"Verzauberkunstlehrerin", "Verzauberer", "Verzauberin" },
	esES = { "Aprendiz encantador", "Oficial encantador", "Oficial encantadora", "Experto encantador", "Experta encantadora", "Artesano encantador",
		"Artesana encantadora", "Maestro encantador", "Maestra encantadora", "Instructor de encantamiento", "Instructora de encantamiento", "Encantador",
		"Encantadora" },
	esMX = { "Aprendiz encantador", "Oficial encantador", "Oficial encantadora", "Experto encantador", "Experta encantadora", "Artesano encantador",
		"Artesana encantadora", "Maestro encantador", "Maestra encantadora", "Instructor de encantamiento", "Instructora de encantamiento", "Encantador",
		"Encantadora" },
	ptBR = { "Encantador Aprendiz", "Encantador Profissional", "Encantadora Profissional", "Encantador Perito", "Encantadora Perita",
		"Encantador Artífice", "Encantadora Artífice", "Mestre Encantador", "Mestre Encantadora", "Instrutor de Encantamento",
		"Instrutora de Encantamento", "Encantador", "Encantadora" },
	ruRU = { "Ученик зачаровывателя", "Подмастерье зачаровывателя", "Зачаровыватель-эксперт", "Зачаровыватель-искусник", "Мастер-зачаровыватель",
		"Наставник зачаровывателей", "Зачаровыватель", "Зачаровывательница" },
	koKR = { "견습 마법부여사", "수습 마법부여사", "숙련 마법부여사", "전문 마법부여사", "마법부여의 대가", "마법부여 전문기술 강사", "마법부여사" },
	zhCN = { "初级附魔师", "中级附魔师", "高级附魔师", "专家级附魔师", "大师级附魔师", "附魔训练师", "附魔师" },
	zhTW = { "見習附魔師", "附魔訓練師", "附魔師", "專家級附魔師", "大師級附魔師" },
}
