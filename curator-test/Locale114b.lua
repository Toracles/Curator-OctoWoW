local _, ns = "Curator", CuratorOctoFull

-- (1.14.0) The words of a ban for a time (Bans.lua: the bans of the news of the website; UI/Suspended.lua: its window):
-- until when Curator is blocked, and that it works again by itself after. They go into the tables of Locale.lua
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
	["Account banned until %s"] = "Compte banni jusqu'au %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Ton compte Battle.net est banni de Curator jusqu'au %s. D'ici là, Curator ne marche plus sur ce compte : plus de boosters, plus de cartes, plus d'échanges. Ta collection est gardée.",
	["At the end of the ban, Curator works again by itself."] = "À la fin du ban, Curator remarche tout seul.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator est bloqué : ton compte Battle.net est banni jusqu'au %s.",
})

Add("deDE", {
	["Account banned until %s"] = "Konto gebannt bis %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Dein Battle.net-Konto ist bis %s von Curator gebannt. Bis dahin funktioniert Curator auf diesem Konto nicht: keine Booster, keine Karten, kein Tausch. Deine Sammlung bleibt erhalten.",
	["At the end of the ban, Curator works again by itself."] = "Nach Ablauf des Banns funktioniert Curator von selbst wieder.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator ist blockiert: Dein Battle.net-Konto ist bis %s gebannt.",
})

Add("esES", {
	["Account banned until %s"] = "Cuenta baneada hasta el %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Tu cuenta de Battle.net está baneada de Curator hasta el %s. Hasta entonces, Curator no funciona en esta cuenta: ni sobres, ni cartas, ni intercambios. Tu colección se conserva.",
	["At the end of the ban, Curator works again by itself."] = "Cuando termine el baneo, Curator volverá a funcionar solo.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator está bloqueado: tu cuenta de Battle.net está baneada hasta el %s.",
})

Add("esMX", {
	["Account banned until %s"] = "Cuenta baneada hasta el %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Tu cuenta de Battle.net está baneada de Curator hasta el %s. Hasta entonces, Curator no funciona en esta cuenta: ni sobres, ni cartas, ni intercambios. Tu colección se conserva.",
	["At the end of the ban, Curator works again by itself."] = "Cuando termine el baneo, Curator volverá a funcionar solo.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator está bloqueado: tu cuenta de Battle.net está baneada hasta el %s.",
})

Add("ptBR", {
	["Account banned until %s"] = "Conta banida até %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Sua conta Battle.net está banida do Curator até %s. Até lá, o Curator não funciona nesta conta: sem pacotes, sem cartas, sem trocas. Sua coleção é mantida.",
	["At the end of the ban, Curator works again by itself."] = "Ao fim do banimento, o Curator volta a funcionar sozinho.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "O Curator está bloqueado: sua conta Battle.net está banida até %s.",
})

Add("ruRU", {
	["Account banned until %s"] = "Аккаунт забанен до %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Ваш аккаунт Battle.net забанен в Curator до %s. До тех пор Curator на этом аккаунте не работает: ни бустеров, ни карт, ни обменов. Ваша коллекция сохраняется.",
	["At the end of the ban, Curator works again by itself."] = "Когда бан закончится, Curator снова заработает сам.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator заблокирован: ваш аккаунт Battle.net забанен до %s.",
})

Add("koKR", {
	["Account banned until %s"] = "%s까지 계정 차단",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "Battle.net 계정이 %s까지 Curator에서 차단되었습니다. 그때까지 이 계정에서는 Curator가 작동하지 않습니다. 부스터도, 카드도, 교환도 없습니다. 수집품은 그대로 보존됩니다.",
	["At the end of the ban, Curator works again by itself."] = "차단이 끝나면 Curator가 저절로 다시 작동합니다.",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator가 차단되었습니다: Battle.net 계정이 %s까지 차단되었습니다.",
})

Add("zhCN", {
	["Account banned until %s"] = "账号封禁至 %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "你的战网账号已被 Curator 封禁至 %s。在此之前，Curator 在此账号上无法使用：没有补充包、没有卡牌、也无法交换。你的收藏会被保留。",
	["At the end of the ban, Curator works again by itself."] = "封禁结束后，Curator 会自动恢复。",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator 已被锁定：你的战网账号被封禁至 %s。",
})

Add("zhTW", {
	["Account banned until %s"] = "帳號封鎖至 %s",
	["Your Battle.net account is banned from Curator until %s. Until then, Curator does not work on this account: no boosters, no cards, no trades. Your collection is kept."] = "你的 Battle.net 帳號已被 Curator 封鎖至 %s。在此之前，Curator 在此帳號上無法使用：沒有補充包、沒有卡牌、也無法交換。你的收藏會被保留。",
	["At the end of the ban, Curator works again by itself."] = "封鎖結束後，Curator 會自動恢復。",
	["Curator is blocked: your Battle.net account is banned until %s."] = "Curator 已被鎖定：你的 Battle.net 帳號被封鎖至 %s。",
})
