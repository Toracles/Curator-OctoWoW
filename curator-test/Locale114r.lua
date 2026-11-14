local _, ns = "Curator", CuratorOctoFull

-- (1.14.0) The words of the main character and of the rerolls (Reroll.lua, UI/Reroll.lua), and of the release of WoW
-- Forever. They go into the tables of Locale.lua (English keys; a missing one falls back to English).
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
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever est là ! Curator recommence pour tout le monde : tes cartes de la Sanssaint et de la Hardcup restent, avec les boosters de la Sanssaint que tu n'avais pas encore ouverts, et tes hauts faits Bêta testeur, Pionnier et Survivant de la Hardcup si tu les as. Tout le reste repart de zéro, ton niveau de collectionneur et le classement du site avec lui.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"Ton personnage principal : %s. Il gagne tout dès le niveau 1. Tes autres personnages sont des rerolls : jusqu'au niveau %d, ils gagnent un quart de tout, gardé dans leur coffre (/curator principal pour changer de personnage principal).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"Ce personnage est un reroll : jusqu'au niveau %d, il gagne un quart de tout, gardé dans son coffre (%d boosters, %d cartes pour l'instant). /curator coffre",
	["/curator main: your main character, or make this one your main"] = "/curator principal : ton personnage principal, ou faire de celui-ci ton personnage principal",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator coffre : le coffre de ce personnage (un reroll sous le niveau %d)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "Reviens me voir avec ce personnage au niveau %d : un reroll ne fait pas de quête en or avant.",
	["Your main character"] = "Ton personnage principal",
	["It is a reroll"] = "C'est un reroll",
	["Make it my main"] = "En faire mon personnage principal",
	["Confirm: my main"] = "Confirmer : mon personnage principal",
	["Your main changes once a month at most: again in %s."] = "Ton personnage principal change une fois par mois au plus : à nouveau dans %s.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"Le personnage principal et les rerolls arrivent avec la sortie de WoW Forever. D'ici là, chaque personnage gagne tout.",
	["%s is your main character: it earns everything from level 1."] = "%s est ton personnage principal : il gagne tout dès le niveau 1.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"Tes autres personnages sous le niveau %d sont des rerolls : un quart de tout, gardé dans leur coffre jusqu'au niveau %d.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"Ce personnage est un reroll. Jusqu'au niveau %d, il gagne un quart de tout (boosters, cartes trouvées, rubis, expérience), gardé dans son coffre, qui s'ouvre au niveau %d. Ensuite, il gagne tout, comme ton personnage principal, %s.",
	["In its chest: %d boosters, %d cards."] = "Dans son coffre : %d boosters, %d cartes.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "Ce personnage gagne tout : il est au niveau %d ou plus. Ton personnage principal : %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s est maintenant ton personnage principal : il gagne tout dès le niveau 1.",
	["My boosters"] = "Mes boosters",
	["Boosters of albums: %d"] = "Boosters d'albums : %d",
	["and %d more albums"] = "et %d autres albums",
	["Cards found: %d"] = "Cartes trouvées : %d",
	["Collector experience: %s XP"] = "Expérience de collectionneur : %s XP",
	["The chests of the rerolls come with the release of WoW Forever."] = "Les coffres des rerolls arrivent avec la sortie de WoW Forever.",
	["This character has no chest: it earns everything as it comes."] = "Ce personnage n'a pas de coffre : il gagne tout au fur et à mesure.",
	["The chest of %s"] = "Le coffre de %s",
	["Opens at level %d"] = "S'ouvre au niveau %d",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"D'ici là, ce personnage gagne un quart de tout, gardé ici. Supprimé avant, il emporte son coffre avec lui.",
	["Your chest opens!"] = "Ton coffre s'ouvre !",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"Ses boosters sont dans leurs albums, ses cartes dans ta collection. Désormais, ce personnage gagne tout.",
	["The chest of %s opens: %d boosters, %d cards."] = "Le coffre de %s s'ouvre : %d boosters, %d cartes.",
	["In this character's chest: it opens at level %d."] = "Dans le coffre de ce personnage : il s'ouvre au niveau %d.",
	["Chest: %d"] = "Coffre : %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"Un reroll : un quart des points jusqu'au niveau %d, sur une barre à lui. Ses boosters vont dans son coffre, qui s'ouvre au niveau %d.",
})

Add("deDE", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever ist da! Curator beginnt für alle von vorn: Deine Karten der Schlotternächte und der Hardcup bleiben, mit den Boostern der Schlotternächte, die du noch nicht geöffnet hattest, und deinen Erfolgen Betatester, Pionier und Hardcup-Überlebender, falls du sie hast. Alles andere beginnt wieder bei null, deine Sammlerstufe und die Rangliste der Website mit ihr.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"Dein Hauptcharakter: %s. Er erhält alles ab Stufe 1. Deine anderen Charaktere sind Nebencharaktere: bis Stufe %d erhalten sie ein Viertel von allem, aufbewahrt in ihrer Truhe (/curator main, um den Hauptcharakter zu wechseln).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"Dieser Charakter ist ein Nebencharakter: bis Stufe %d erhält er ein Viertel von allem, aufbewahrt in seiner Truhe (bisher %d Booster, %d Karten). /curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main: dein Hauptcharakter, oder mach diesen zu deinem Hauptcharakter",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest: die Truhe dieses Charakters (ein Nebencharakter unter Stufe %d)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "Komm mit diesem Charakter auf Stufe %d wieder zu mir: Ein Nebencharakter macht vorher keine goldene Quest.",
	["Your main character"] = "Dein Hauptcharakter",
	["It is a reroll"] = "Es ist ein Nebencharakter",
	["Make it my main"] = "Zum Hauptcharakter machen",
	["Confirm: my main"] = "Bestätigen: mein Hauptcharakter",
	["Your main changes once a month at most: again in %s."] = "Dein Hauptcharakter wechselt höchstens einmal im Monat: wieder in %s.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"Hauptcharakter und Nebencharaktere kommen mit dem Start von WoW Forever. Bis dahin erhält jeder Charakter alles.",
	["%s is your main character: it earns everything from level 1."] = "%s ist dein Hauptcharakter: Er erhält alles ab Stufe 1.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"Deine anderen Charaktere unter Stufe %d sind Nebencharaktere: ein Viertel von allem, aufbewahrt in ihrer Truhe bis Stufe %d.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"Dieser Charakter ist ein Nebencharakter. Bis Stufe %d erhält er ein Viertel von allem (Booster, gefundene Karten, Rubine, Erfahrung), aufbewahrt in seiner Truhe, die sich auf Stufe %d öffnet. Danach erhält er alles, wie dein Hauptcharakter, %s.",
	["In its chest: %d boosters, %d cards."] = "In seiner Truhe: %d Booster, %d Karten.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "Dieser Charakter erhält alles: Er ist auf Stufe %d oder höher. Dein Hauptcharakter: %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s ist jetzt dein Hauptcharakter: Er erhält alles ab Stufe 1.",
	["My boosters"] = "Meine Booster",
	["Boosters of albums: %d"] = "Booster von Alben: %d",
	["and %d more albums"] = "und %d weitere Alben",
	["Cards found: %d"] = "Gefundene Karten: %d",
	["Collector experience: %s XP"] = "Sammlererfahrung: %s EP",
	["The chests of the rerolls come with the release of WoW Forever."] = "Die Truhen der Nebencharaktere kommen mit dem Start von WoW Forever.",
	["This character has no chest: it earns everything as it comes."] = "Dieser Charakter hat keine Truhe: Er erhält alles sofort.",
	["The chest of %s"] = "Die Truhe von %s",
	["Opens at level %d"] = "Öffnet sich auf Stufe %d",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"Bis dahin erhält dieser Charakter ein Viertel von allem, hier aufbewahrt. Vorher gelöscht, nimmt er seine Truhe mit.",
	["Your chest opens!"] = "Deine Truhe öffnet sich!",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"Ihre Booster sind in ihren Alben, ihre Karten in deiner Sammlung. Ab jetzt erhält dieser Charakter alles.",
	["The chest of %s opens: %d boosters, %d cards."] = "Die Truhe von %s öffnet sich: %d Booster, %d Karten.",
	["In this character's chest: it opens at level %d."] = "In der Truhe dieses Charakters: Sie öffnet sich auf Stufe %d.",
	["Chest: %d"] = "Truhe: %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"Ein Nebencharakter: ein Viertel der Punkte bis Stufe %d, auf einer eigenen Leiste. Seine Booster kommen in seine Truhe, die sich auf Stufe %d öffnet.",
})

local ES = {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"¡WoW Forever ya está aquí! Curator vuelve a empezar para todos: tus cartas de Halloween y de la Hardcup se quedan, con los sobres de Halloween que aún no habías abierto, y tus logros Probador de la beta, Pionero y Superviviente de la Hardcup si los tienes. Todo lo demás vuelve a empezar de cero, tu nivel de coleccionista y la clasificación de la web con él.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"Tu personaje principal: %s. Lo gana todo desde el nivel 1. Tus otros personajes son secundarios: hasta el nivel %d ganan una cuarta parte de todo, guardada en su cofre (/curator main para cambiar de personaje principal).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"Este personaje es secundario: hasta el nivel %d gana una cuarta parte de todo, guardada en su cofre (%d sobres, %d cartas por ahora). /curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main: tu personaje principal, o hacer de este tu personaje principal",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest: el cofre de este personaje (un secundario por debajo del nivel %d)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "Vuelve a verme con este personaje al nivel %d: un personaje secundario no hace misión dorada antes.",
	["Your main character"] = "Tu personaje principal",
	["It is a reroll"] = "Es un secundario",
	["Make it my main"] = "Hacerlo mi personaje principal",
	["Confirm: my main"] = "Confirmar: mi personaje principal",
	["Your main changes once a month at most: again in %s."] = "Tu personaje principal cambia una vez al mes como máximo: de nuevo en %s.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"El personaje principal y los secundarios llegan con el lanzamiento de WoW Forever. Hasta entonces, cada personaje lo gana todo.",
	["%s is your main character: it earns everything from level 1."] = "%s es tu personaje principal: lo gana todo desde el nivel 1.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"Tus otros personajes por debajo del nivel %d son secundarios: una cuarta parte de todo, guardada en su cofre hasta el nivel %d.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"Este personaje es secundario. Hasta el nivel %d gana una cuarta parte de todo (sobres, cartas encontradas, rubíes, experiencia), guardada en su cofre, que se abre al nivel %d. Después lo gana todo, como tu personaje principal, %s.",
	["In its chest: %d boosters, %d cards."] = "En su cofre: %d sobres, %d cartas.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "Este personaje lo gana todo: es de nivel %d o más. Tu personaje principal: %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s es ahora tu personaje principal: lo gana todo desde el nivel 1.",
	["My boosters"] = "Mis sobres",
	["Boosters of albums: %d"] = "Sobres de álbumes: %d",
	["and %d more albums"] = "y %d álbumes más",
	["Cards found: %d"] = "Cartas encontradas: %d",
	["Collector experience: %s XP"] = "Experiencia de coleccionista: %s PE",
	["The chests of the rerolls come with the release of WoW Forever."] = "Los cofres de los secundarios llegan con el lanzamiento de WoW Forever.",
	["This character has no chest: it earns everything as it comes."] = "Este personaje no tiene cofre: lo gana todo a medida que llega.",
	["The chest of %s"] = "El cofre de %s",
	["Opens at level %d"] = "Se abre al nivel %d",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"Hasta entonces, este personaje gana una cuarta parte de todo, guardada aquí. Si se borra antes, se lleva su cofre.",
	["Your chest opens!"] = "¡Tu cofre se abre!",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"Sus sobres están en sus álbumes, sus cartas en tu colección. A partir de ahora este personaje lo gana todo.",
	["The chest of %s opens: %d boosters, %d cards."] = "El cofre de %s se abre: %d sobres, %d cartas.",
	["In this character's chest: it opens at level %d."] = "En el cofre de este personaje: se abre al nivel %d.",
	["Chest: %d"] = "Cofre: %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"Un secundario: una cuarta parte de los puntos hasta el nivel %d, en una barra propia. Sus sobres van a su cofre, que se abre al nivel %d.",
}
Add("esES", ES)
Add("esMX", ES)

Add("ptBR", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever chegou! O Curator recomeça para todos: suas cartas da Noturnália e da Hardcup ficam, com os pacotes da Noturnália que você ainda não tinha aberto, e suas conquistas Testador da beta, Pioneiro e Sobrevivente da Hardcup, se você as tiver. Todo o resto recomeça do zero, seu nível de colecionador e a classificação do site com ele.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"Seu personagem principal: %s. Ele ganha tudo desde o nível 1. Seus outros personagens são secundários: até o nível %d eles ganham um quarto de tudo, guardado no baú deles (/curator main para trocar de personagem principal).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"Este personagem é secundário: até o nível %d ele ganha um quarto de tudo, guardado no baú dele (%d pacotes, %d cartas até agora). /curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main: seu personagem principal, ou fazer deste o seu personagem principal",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest: o baú deste personagem (um secundário abaixo do nível %d)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "Volte a falar comigo com este personagem no nível %d: um personagem secundário não faz missão dourada antes.",
	["Your main character"] = "Seu personagem principal",
	["It is a reroll"] = "É um secundário",
	["Make it my main"] = "Tornar meu personagem principal",
	["Confirm: my main"] = "Confirmar: meu personagem principal",
	["Your main changes once a month at most: again in %s."] = "Seu personagem principal muda no máximo uma vez por mês: de novo em %s.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"O personagem principal e os secundários chegam com o lançamento de WoW Forever. Até lá, cada personagem ganha tudo.",
	["%s is your main character: it earns everything from level 1."] = "%s é seu personagem principal: ele ganha tudo desde o nível 1.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"Seus outros personagens abaixo do nível %d são secundários: um quarto de tudo, guardado no baú deles até o nível %d.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"Este personagem é secundário. Até o nível %d ele ganha um quarto de tudo (pacotes, cartas encontradas, rubis, experiência), guardado no baú dele, que se abre no nível %d. Depois ele ganha tudo, como seu personagem principal, %s.",
	["In its chest: %d boosters, %d cards."] = "No baú dele: %d pacotes, %d cartas.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "Este personagem ganha tudo: ele está no nível %d ou acima. Seu personagem principal: %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s agora é seu personagem principal: ele ganha tudo desde o nível 1.",
	["My boosters"] = "Meus pacotes",
	["Boosters of albums: %d"] = "Pacotes de álbuns: %d",
	["and %d more albums"] = "e mais %d álbuns",
	["Cards found: %d"] = "Cartas encontradas: %d",
	["Collector experience: %s XP"] = "Experiência de colecionador: %s XP",
	["The chests of the rerolls come with the release of WoW Forever."] = "Os baús dos secundários chegam com o lançamento de WoW Forever.",
	["This character has no chest: it earns everything as it comes."] = "Este personagem não tem baú: ele ganha tudo na hora.",
	["The chest of %s"] = "O baú de %s",
	["Opens at level %d"] = "Abre no nível %d",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"Até lá, este personagem ganha um quarto de tudo, guardado aqui. Apagado antes, ele leva o baú junto.",
	["Your chest opens!"] = "Seu baú se abre!",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"Os pacotes estão nos álbuns, as cartas na sua coleção. A partir de agora este personagem ganha tudo.",
	["The chest of %s opens: %d boosters, %d cards."] = "O baú de %s se abre: %d pacotes, %d cartas.",
	["In this character's chest: it opens at level %d."] = "No baú deste personagem: ele abre no nível %d.",
	["Chest: %d"] = "Baú: %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"Um secundário: um quarto dos pontos até o nível %d, numa barra própria. Os pacotes dele vão para o baú, que abre no nível %d.",
})

Add("ruRU", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever уже здесь! Curator начинается заново для всех: твои карты Тыквовина и Hardcup остаются, вместе с бустерами Тыквовина, которые ты ещё не открыл, и твоими достижениями «Бета-тестер», «Первопроходец» и «Выживший в Hardcup», если они у тебя есть. Всё остальное начинается с нуля, твой уровень коллекционера и таблица лидеров сайта вместе с ним.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"Твой основной персонаж: %s. Он получает все с 1 уровня. Твои другие персонажи твинки: до %d уровня они получают четверть всего, и она хранится в их сундуке (/curator main, чтобы сменить основного персонажа).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"Этот персонаж твинк: до %d уровня он получает четверть всего, и она хранится в его сундуке (пока %d бустеров, %d карт). /curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main: твой основной персонаж, или сделать этого персонажа основным",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest: сундук этого персонажа (твинк ниже %d уровня)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "Возвращайся ко мне с этим персонажем на %d уровне: твинк до этого не выполняет золотое задание.",
	["Your main character"] = "Твой основной персонаж",
	["It is a reroll"] = "Это твинк",
	["Make it my main"] = "Сделать основным",
	["Confirm: my main"] = "Подтвердить: мой основной",
	["Your main changes once a month at most: again in %s."] = "Основной персонаж меняется не чаще раза в месяц: снова через %s.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"Основной персонаж и твинки появятся с выходом WoW Forever. До тех пор каждый персонаж получает все.",
	["%s is your main character: it earns everything from level 1."] = "%s твой основной персонаж: он получает все с 1 уровня.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"Твои другие персонажи ниже %d уровня твинки: четверть всего, которая хранится в их сундуке до %d уровня.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"Этот персонаж твинк. До %d уровня он получает четверть всего (бустеры, найденные карты, рубины, опыт), и она хранится в его сундуке, который откроется на %d уровне. Потом он получает все, как твой основной персонаж, %s.",
	["In its chest: %d boosters, %d cards."] = "В его сундуке: бустеров %d, карт %d.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "Этот персонаж получает все: у него %d уровень или выше. Твой основной персонаж: %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s теперь твой основной персонаж: он получает все с 1 уровня.",
	["My boosters"] = "Мои бустеры",
	["Boosters of albums: %d"] = "Бустеры альбомов: %d",
	["and %d more albums"] = "и еще альбомов: %d",
	["Cards found: %d"] = "Найдено карт: %d",
	["Collector experience: %s XP"] = "Опыт коллекционера: %s",
	["The chests of the rerolls come with the release of WoW Forever."] = "Сундуки твинков появятся с выходом WoW Forever.",
	["This character has no chest: it earns everything as it comes."] = "У этого персонажа нет сундука: он получает все сразу.",
	["The chest of %s"] = "Сундук: %s",
	["Opens at level %d"] = "Откроется на %d уровне",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"До тех пор этот персонаж получает четверть всего, и она хранится здесь. Если удалить его раньше, сундук пропадет вместе с ним.",
	["Your chest opens!"] = "Твой сундук открывается!",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"Его бустеры в своих альбомах, его карты в твоей коллекции. Теперь этот персонаж получает все.",
	["The chest of %s opens: %d boosters, %d cards."] = "Сундук открывается (%s): бустеров %d, карт %d.",
	["In this character's chest: it opens at level %d."] = "В сундуке этого персонажа: он откроется на %d уровне.",
	["Chest: %d"] = "Сундук: %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"Твинк: четверть очков до %d уровня, на собственной полосе. Его бустеры идут в его сундук, который откроется на %d уровне.",
})

Add("koKR", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever가 시작되었습니다! Curator는 모두에게 처음부터 다시 시작됩니다: 할로윈 축제와 하드컵 카드는 남고, 아직 열지 않은 할로윈 축제 부스터와, 가지고 있다면 베타 테스터, 개척자, 하드컵 생존자 업적도 남습니다. 나머지는 모두 0부터 다시 시작되며, 수집가 레벨과 웹사이트 순위표도 함께 초기화됩니다.",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"주 캐릭터: %s. 1레벨부터 모든 것을 얻습니다. 다른 캐릭터는 부캐릭터입니다: %d레벨까지 모든 것의 4분의 1을 얻고, 그것은 상자에 보관됩니다 (/curator main 으로 주 캐릭터 변경).",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"이 캐릭터는 부캐릭터입니다: %d레벨까지 모든 것의 4분의 1을 얻고, 그것은 상자에 보관됩니다 (지금까지 부스터 %d개, 카드 %d장). /curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main: 주 캐릭터 확인, 또는 이 캐릭터를 주 캐릭터로 지정",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest: 이 캐릭터의 상자 (%d레벨 미만의 부캐릭터)",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "이 캐릭터로 %d레벨이 되면 다시 오게: 부캐릭터는 그 전에는 황금 퀘스트를 할 수 없네.",
	["Your main character"] = "주 캐릭터",
	["It is a reroll"] = "부캐릭터입니다",
	["Make it my main"] = "주 캐릭터로 지정",
	["Confirm: my main"] = "확인: 내 주 캐릭터",
	["Your main changes once a month at most: again in %s."] = "주 캐릭터는 한 달에 한 번만 바꿀 수 있습니다: %s 후에 다시 가능.",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"주 캐릭터와 부캐릭터는 WoW Forever 출시와 함께 시작됩니다. 그때까지는 모든 캐릭터가 모든 것을 얻습니다.",
	["%s is your main character: it earns everything from level 1."] = "%s 캐릭터가 주 캐릭터입니다: 1레벨부터 모든 것을 얻습니다.",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"%d레벨 미만의 다른 캐릭터는 부캐릭터입니다: 모든 것의 4분의 1을 얻고, %d레벨까지 상자에 보관됩니다.",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"이 캐릭터는 부캐릭터입니다. %d레벨까지 모든 것(부스터, 발견한 카드, 루비, 경험치)의 4분의 1을 얻으며, 그것은 상자에 보관되고 상자는 %d레벨에 열립니다. 그 후에는 주 캐릭터(%s)처럼 모든 것을 얻습니다.",
	["In its chest: %d boosters, %d cards."] = "상자 안: 부스터 %d개, 카드 %d장.",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "이 캐릭터는 모든 것을 얻습니다: %d레벨 이상입니다. 주 캐릭터: %s.",
	["%s is now your main character: it earns everything from level 1."] = "%s 캐릭터가 이제 주 캐릭터입니다: 1레벨부터 모든 것을 얻습니다.",
	["My boosters"] = "내 부스터",
	["Boosters of albums: %d"] = "앨범 부스터: %d",
	["and %d more albums"] = "외 앨범 %d개",
	["Cards found: %d"] = "발견한 카드: %d",
	["Collector experience: %s XP"] = "수집가 경험치: %s",
	["The chests of the rerolls come with the release of WoW Forever."] = "부캐릭터의 상자는 WoW Forever 출시와 함께 시작됩니다.",
	["This character has no chest: it earns everything as it comes."] = "이 캐릭터는 상자가 없습니다: 얻는 즉시 모든 것을 받습니다.",
	["The chest of %s"] = "%s의 상자",
	["Opens at level %d"] = "%d레벨에 열림",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"그때까지 이 캐릭터는 모든 것의 4분의 1을 얻고, 여기에 보관됩니다. 그 전에 삭제하면 상자도 함께 사라집니다.",
	["Your chest opens!"] = "상자가 열립니다!",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"부스터는 각 앨범에, 카드는 수집품에 들어갔습니다. 이제부터 이 캐릭터는 모든 것을 얻습니다.",
	["The chest of %s opens: %d boosters, %d cards."] = "%s의 상자가 열립니다: 부스터 %d개, 카드 %d장.",
	["In this character's chest: it opens at level %d."] = "이 캐릭터의 상자에 보관됨: %d레벨에 열립니다.",
	["Chest: %d"] = "상자: %d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"부캐릭터: %d레벨까지 점수의 4분의 1을 별도의 바에 받습니다. 부스터는 상자로 가며, 상자는 %d레벨에 열립니다.",
})

Add("zhCN", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever 来了！Curator 为所有人重新开始：你的万圣节和 Hardcup 卡牌保留，还有你尚未打开的万圣节补充包，以及你拥有的内测玩家、先驱者和 Hardcup 幸存者成就。其他一切从零开始，你的收藏家等级和网站的排行榜也随之重置。",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"你的主角色：%s。它从 1 级起获得全部奖励。你的其他角色是小号：在 %d 级之前，它们获得一切的四分之一，保存在各自的宝箱中（/curator main 可更换主角色）。",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"这个角色是小号：在 %d 级之前，它获得一切的四分之一，保存在它的宝箱中（目前 %d 个补充包，%d 张卡牌）。/curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main：查看主角色，或将当前角色设为主角色",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest：这个角色的宝箱（低于 %d 级的小号）",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "等这个角色到了 %d 级再来找我吧：小号在此之前不能接黄金任务。",
	["Your main character"] = "你的主角色",
	["It is a reroll"] = "这是小号",
	["Make it my main"] = "设为主角色",
	["Confirm: my main"] = "确认：设为主角色",
	["Your main changes once a month at most: again in %s."] = "主角色每月最多更换一次：%s 后可再次更换。",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"主角色和小号的规则将随 WoW Forever 上线而开启。在此之前，每个角色都获得全部奖励。",
	["%s is your main character: it earns everything from level 1."] = "%s 是你的主角色：从 1 级起获得全部奖励。",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"低于 %d 级的其他角色是小号：获得一切的四分之一，保存在宝箱中直到 %d 级。",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"这个角色是小号。在 %d 级之前，它获得一切的四分之一（补充包、找到的卡牌、红宝石、经验），保存在它的宝箱中，宝箱在 %d 级时打开。之后它将像你的主角色（%s）一样获得全部奖励。",
	["In its chest: %d boosters, %d cards."] = "宝箱中：%d 个补充包，%d 张卡牌。",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "这个角色获得全部奖励：它已达到 %d 级或以上。你的主角色：%s。",
	["%s is now your main character: it earns everything from level 1."] = "%s 现在是你的主角色：从 1 级起获得全部奖励。",
	["My boosters"] = "我的补充包",
	["Boosters of albums: %d"] = "收藏册补充包：%d",
	["and %d more albums"] = "以及另外 %d 本收藏册",
	["Cards found: %d"] = "找到的卡牌：%d",
	["Collector experience: %s XP"] = "收藏家经验：%s",
	["The chests of the rerolls come with the release of WoW Forever."] = "小号的宝箱将随 WoW Forever 上线而开启。",
	["This character has no chest: it earns everything as it comes."] = "这个角色没有宝箱：获得的一切即时到账。",
	["The chest of %s"] = "%s 的宝箱",
	["Opens at level %d"] = "%d 级时打开",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"在此之前，这个角色获得一切的四分之一，保存在这里。若提前删除角色，宝箱也会一同消失。",
	["Your chest opens!"] = "你的宝箱打开了！",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"补充包已放入各自的收藏册，卡牌已放入你的收藏。从现在起，这个角色获得全部奖励。",
	["The chest of %s opens: %d boosters, %d cards."] = "%s 的宝箱打开了：%d 个补充包，%d 张卡牌。",
	["In this character's chest: it opens at level %d."] = "已放入这个角色的宝箱：%d 级时打开。",
	["Chest: %d"] = "宝箱：%d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"小号：%d 级前只获得四分之一的点数，计入它自己的进度条。它的补充包放入宝箱，宝箱在 %d 级时打开。",
})

Add("zhTW", {
	["WoW Forever is here! Curator starts over for everyone: your Hallow's End and Hardcup cards stay, with the Hallow's End boosters you had not opened yet, and your achievements Beta tester, Pioneer and Hardcup Survivor if you have them. Everything else starts again from zero, your collector level and the leaderboard of the website with it."] =
		"WoW Forever 來了！Curator 為所有人重新開始：你的萬鬼節和 Hardcup 卡牌保留，還有你尚未打開的萬鬼節補充包，以及你擁有的封測玩家、先驅者和 Hardcup 倖存者成就。其他一切從零開始，你的收藏家等級和網站的排行榜也隨之重置。",
	["Your main character: %s. It earns everything from level 1. Your other characters are rerolls: until level %d they earn a quarter of everything, kept in their chest (/curator main to change your main)."] =
		"你的主角色：%s。它從 1 級起獲得全部獎勵。你的其他角色是分身：在 %d 級之前，它們獲得一切的四分之一，保存在各自的寶箱中（/curator main 可更換主角色）。",
	["This character is a reroll: until level %d it earns a quarter of everything, kept in its chest (%d boosters, %d cards so far). /curator chest"] =
		"這個角色是分身：在 %d 級之前，它獲得一切的四分之一，保存在它的寶箱中（目前 %d 個補充包，%d 張卡牌）。/curator chest",
	["/curator main: your main character, or make this one your main"] = "/curator main：查看主角色，或將目前角色設為主角色",
	["/curator chest: the chest of this character (a reroll under level %d)"] = "/curator chest：這個角色的寶箱（低於 %d 級的分身）",
	["Come back to me with this character at level %d: a reroll does no golden quest before."] = "等這個角色到了 %d 級再來找我吧：分身在此之前不能接黃金任務。",
	["Your main character"] = "你的主角色",
	["It is a reroll"] = "這是分身",
	["Make it my main"] = "設為主角色",
	["Confirm: my main"] = "確認：設為主角色",
	["Your main changes once a month at most: again in %s."] = "主角色每月最多更換一次：%s 後可再次更換。",
	["The main character and the rerolls come with the release of WoW Forever. Until then, every character earns everything."] =
		"主角色和分身的規則將隨 WoW Forever 上線而開啟。在此之前，每個角色都獲得全部獎勵。",
	["%s is your main character: it earns everything from level 1."] = "%s 是你的主角色：從 1 級起獲得全部獎勵。",
	["Your other characters under level %d are rerolls: a quarter of everything, kept in their chest until level %d."] =
		"低於 %d 級的其他角色是分身：獲得一切的四分之一，保存在寶箱中直到 %d 級。",
	["This character is a reroll. Until level %d it earns a quarter of everything (boosters, cards found, rubies, experience), kept in its chest, which opens at level %d. Then it earns everything, like your main character, %s."] =
		"這個角色是分身。在 %d 級之前，它獲得一切的四分之一（補充包、找到的卡牌、紅寶石、經驗），保存在它的寶箱中，寶箱在 %d 級時打開。之後它將像你的主角色（%s）一樣獲得全部獎勵。",
	["In its chest: %d boosters, %d cards."] = "寶箱中：%d 個補充包，%d 張卡牌。",
	["This character earns everything: it is level %d or above. Your main character: %s."] = "這個角色獲得全部獎勵：它已達到 %d 級或以上。你的主角色：%s。",
	["%s is now your main character: it earns everything from level 1."] = "%s 現在是你的主角色：從 1 級起獲得全部獎勵。",
	["My boosters"] = "我的補充包",
	["Boosters of albums: %d"] = "收藏冊補充包：%d",
	["and %d more albums"] = "以及另外 %d 本收藏冊",
	["Cards found: %d"] = "找到的卡牌：%d",
	["Collector experience: %s XP"] = "收藏家經驗：%s",
	["The chests of the rerolls come with the release of WoW Forever."] = "分身的寶箱將隨 WoW Forever 上線而開啟。",
	["This character has no chest: it earns everything as it comes."] = "這個角色沒有寶箱：獲得的一切即時到帳。",
	["The chest of %s"] = "%s 的寶箱",
	["Opens at level %d"] = "%d 級時打開",
	["Until then, this character earns a quarter of everything, kept here. Deleted before, it takes its chest with it."] =
		"在此之前，這個角色獲得一切的四分之一，保存在這裡。若提前刪除角色，寶箱也會一同消失。",
	["Your chest opens!"] = "你的寶箱打開了！",
	["Its boosters are in their albums, its cards in your collection. From now on this character earns everything."] =
		"補充包已放入各自的收藏冊，卡牌已放入你的收藏。從現在起，這個角色獲得全部獎勵。",
	["The chest of %s opens: %d boosters, %d cards."] = "%s 的寶箱打開了：%d 個補充包，%d 張卡牌。",
	["In this character's chest: it opens at level %d."] = "已放入這個角色的寶箱：%d 級時打開。",
	["Chest: %d"] = "寶箱：%d",
	["A reroll: a quarter of the points until level %d, on a bar of its own. Its boosters go into its chest, which opens at level %d."] =
		"分身：%d 級前只獲得四分之一的點數，計入它自己的進度條。它的補充包放入寶箱，寶箱在 %d 級時打開。",
})
