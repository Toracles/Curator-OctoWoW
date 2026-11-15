local _, ns = "Curator", CuratorOctoFull

-- (1.13.1) The words of 1.13.1: on OctoWoW, a first name alone typed in a command that says nobody for sure. They go
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
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "Sur OctoWoW, tape le prénom et le nom de famille du joueur : /curator voir Brindille Dupont.",
})

Add("deDE", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "Gib auf OctoWoW den Vornamen und den Nachnamen des Spielers ein: /curator view Brindille Dupont.",
})

Add("esES", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "En OctoWoW, escribe el nombre y el apellido del jugador: /curator view Brindille Dupont.",
})

Add("esMX", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "En OctoWoW, escribe el nombre y el apellido del jugador: /curator view Brindille Dupont.",
})

Add("ptBR", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "No OctoWoW, digite o nome e o sobrenome do jogador: /curator view Brindille Dupont.",
})

Add("ruRU", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "В OctoWoW введите имя и фамилию игрока: /curator view Brindille Dupont.",
})

Add("koKR", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "OctoWoW에서는 플레이어의 이름과 성을 입력하세요: /curator view Brindille Dupont.",
})

Add("zhCN", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "在 OctoWoW 中，请输入该玩家的名字和姓氏：/curator view Brindille Dupont。",
})

Add("zhTW", {
	["On OctoWoW, type the first name and the surname of the player: /curator view Brindille Dupont."] = "在 OctoWoW 中，請輸入該玩家的名字和姓氏：/curator view Brindille Dupont。",
})
