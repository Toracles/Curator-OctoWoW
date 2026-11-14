local _, ns = "Curator", CuratorOctoFull

-- Sharing between players, without any server: every player with the addon tells the guild what
-- they own (a profile and a summary per album), announces their best pulls and achievements, and
-- sends their whole album on request. Any other player met in the world can ask for the same by
-- whisper. Messages (fields separated by ":" and ","):
--   S:1:*;<series>,<owned>,<total>,<legendaries>,<shiny>,<best card>,<mythics>,<holographic>;...
--                       summary of the albums started ("*": a new summary, forget the last one);
--                       several messages if long
--   I:1:<owned>,<total>,<owned of each rarity (6)>,<shiny>,<holographic>,<boosters>,<contracts>,
--       <points>,<achievements>,<flags>,<achievement bits>,<experience>    the profile (flags: 1 a test
--                       collection, 2 a save edited outside the game, 4 a female character, for
--                       the titles; the experience of the collector, its level: 0.18 and later; then
--                       the number of the collection, its trades, the version, the title of prestige
--                       (1.5.0) and the specialization of the talents (1.6.0))
--   V:1:<card>,<finish>[,<grade>,<marks>,<cert>];...                    the showcase (three cards;
--                       1.11.0: an appraised card, its grade 1 to 10, its four marks "9A9A", its
--                       certificate: Expertise.lua)
--   F:1:*;<card>,<finish>,<how>,<day>;...                               the finest pulls ("*": a new
--                       list; how: b a booster, f found on a creature, k a contract, a in the album
--                       before; day: server time / 86400); several messages if long
--   P:1:<series>,<card>,<finish 0/1/2>                                 a pull worth showing (finish:
--                       0 normal, 1 shiny, 2 holographic)
--   O:1:<series>,<best rarity>,<best finish>[,<card>,<its finish>]     a booster with a legendary,
--                       a mythic or a holographic card is being opened (the guild watches it live);
--                       1.14.2: the card it shows after them (its finest), its finish (the versions of
--                       before read the first three and leave the rest)
--   O:1:b:<series>,<best rarity>,<best finish>,<card>,<its finish>     (1.14.2) the same, a booster
--                       with a rare card or better, or a thunderforged one, below the rule of before:
--                       "b:" before its album, which the versions of before do not know (they leave it)
--   O:1:k:<edition>,<rank>,<finish>,<card>                              (1.14.2) a case opened, live: its
--                       edition, the rank of its card (1 Rare to 5 Priceless), its forged finish (0, 1
--                       thunderforged, 2 titanforged), its card (the key of its entry; a weapon of
--                       legend: w<item>); "k:<edition>" is no album either for a version of before
--   H:1:<achievement>                                                   an achievement worth showing
--   Q:1                                                                 send me your summaries
--   W:1:<1 or 2>                                                        (whisper) send me your profile,
--                       1: the profile alone, 2: and the summaries
--   R:1:<series>                                                        send me your album (whisper)
--   A:1:<series>,<part>,<parts>,<data>                                  an album in parts (whisper):
--                       the copies of each card, the shiny bits then the holographic bits, cut in
--                       pieces that fit
--   C:1:<series>,<copies>,<shiny bits>                                  an album in one message (0.6)
-- The trades (T), the cards looked for (N), the cards to spare looked for (U) and the fine cards that
-- came in a trade (E): see Trade.lua. The secret of an obsolete version (X): see Mandatory.lua (1.4). The hello (L) and the roll call (Y) of the players who agreed
-- to be known by the author of Curator, on their hidden channel: see Presence.lua. (1.8.0) A toast at an innkeeper (K), whispered: see Tavern.lua. The profile ends with the number of the collection (its trades
-- know it by it) and its trades done (0.22 and later). The friends of Battle.net playing this game get
-- the whispers through Battle.net: other factions and realms too. (1.12.1) The collector level on the chat channel of
-- the collectors (B): see Channel.lua. (1.14.3) Another player's inventory, page by page (Z, D): at the end of this file.
local G = { handlers = {} }
ns.Guild = G

local PREFIX = "Curator"
local VERSION = "1"
local SUMMARY_DELAY = 20 -- seconds between two summaries after changes
local QUERY_COOLDOWN = 60
local MAX_LEN = 250 -- longest addon message
local PART_LEN = 200 -- album data in one message
local MET_MAX = 100 -- players met kept (the oldest go first)
G.MAX_LEN = MAX_LEN
G.VERSION = VERSION
local PROFILE_FRESH = 600 -- seconds a profile shown in the tooltips stays fresh

local C = ns.Collection

local function Chat()
	return CuratorOctoFull.Chat
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

-- A finish in the messages: 0 normal, 1 shiny (thunderforged), 2 holographic (titanforged).
local function FinishCode(finish)
	return (finish == "holo" and 2) or ((finish == "shiny" or finish == true) and 1) or 0
end
local function FinishOf(code)
	return (code == "2" and "holo") or (code == "1" and "shiny") or nil
end
G.FinishCode, G.FinishOf = FinishCode, FinishOf
local HOW = { b = true, f = true, k = true, a = true, t = true, i = true }

-- A count in a message: digits only, seven at most (no sign, exponent, "inf" or "nan"); nil else.
local function Count(v)
	if type(v) ~= "string" or not CuratorOctoFull.Match(v, "^%d+$") or CuratorOctoFull.Length(v) > 7 then
		return nil
	end
	return tonumber(v)
end
G.Count = Count

function G:Me()
	if self.me then
		return self.me
	end
	local name, realm
	if UnitFullName then
		name, realm = UnitFullName("player")
	end
	-- (1.13.1: kept once the game told both, the name and the realm (on WoW Forever, the surname): it does not change)
	local whole = type(name) == "string" and name ~= "" and type(realm) == "string" and realm ~= ""
	name = name or UnitName("player")
	if (not realm or realm == "") and GetNormalizedRealmName then
		realm = GetNormalizedRealmName()
	end
	if realm and realm ~= "" then
		local me = name .. "-" .. realm
		if whole and not Secret(me) then
			self.me = me
		end
		return me
	end
	return name
end

-- (1.13.1) WoW Forever: a character has a first name and a surname, and no realm in its name. The game writes
-- "First Surname" in the names of its messages, of its chat and of its lists, gives the two apart (UnitFullName,
-- UnitName: the surname where the realm was), and reaches a character as "First-Surname" as well as "First
-- Surname". Curator names every player "First-Surname", whatever way the game wrote them: the same player under
-- one name, a message to them that reaches them. True on WoW Forever (the surname of mine is no realm), known
-- once the game tells my name.
function G:Surnames()
	if self.surnames == nil and UnitFullName and (GetNormalizedRealmName or GetRealmName) then
		local ok, first, second = pcall(UnitFullName, "player")
		local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName())
		if ok and type(first) == "string" and type(second) == "string" and not Secret(first) and not Secret(second) and second ~= ""
			and type(realm) == "string" and realm ~= "" and not Secret(realm) then
			-- (my realm, whatever way the game writes it: its spaces, its dashes, its capitals)
			self.surnames = not self:IsRealm(second)
		end
	end
	return self.surnames == true
end

-- (1.13.1) The character of a game account of Battle.net (C_BattleNet), as Curator names players: "Name-Realm";
-- on WoW Forever, "First-Surname" (its surname from its GUID, when the game knows it), else its first name alone.
function G:BNName(g)
	if type(g) ~= "table" or Secret(g) or type(g.characterName) ~= "string" or g.characterName == "" or Secret(g.characterName) then
		return nil
	end
	local realm = g.realmName or g.realmDisplayName
	if Secret(realm) then
		realm = nil
	end
	if self:Surnames() then
		realm = nil
		local guid = g.playerGuid
		if not string.find(g.characterName, "[%s%-]") and GetPlayerInfoByGUID and type(guid) == "string" and not Secret(guid) then
			local ok, _, _, _, _, _, n, r = pcall(GetPlayerInfoByGUID, guid)
			if ok and n == g.characterName and type(r) == "string" and not Secret(r) and r ~= "" and not self:IsRealm(r) then
				realm = r
			end
		end
	end
	return self:Full(g.characterName, (type(realm) == "string" and realm ~= "") and realm or nil)
end

-- (1.13.1) The realm of mine, whatever way it is written (its spaces and dashes, its capitals).
local function RealmKey(r)
	return G.Fold((string.gsub(r, "[%s%-]", "")))
end

function G:IsRealm(s)
	if type(s) ~= "string" or s == "" or Secret(s) then
		return false
	end
	local keys = self.realms
	if not keys then
		keys = {}
		local all = true
		for _, f in ipairs({ GetNormalizedRealmName or false, GetRealmName or false }) do
			if f then
				local ok, r = pcall(f)
				if ok and type(r) == "string" and not Secret(r) and r ~= "" then
					keys[RealmKey(r)] = true
				else
					all = false
				end
			end
		end
		-- (kept once the game told them all: the realm does not change in a session)
		if all and next(keys) then
			self.realms = keys
		end
	end
	return keys[RealmKey(s)] == true
end

-- (1.13.1) WoW Forever: the first name of a name Curator 1.13.0 made with my realm after it ("Brindille-ClassicBetaPvE2":
-- a friend of Battle.net, a first name typed, a menu), which reaches nobody by whisper; else nil.
function G:RealmForm(name)
	if type(name) ~= "string" or not self:Surnames() then
		return nil
	end
	local f, suffix = CuratorOctoFull.Match(name, "^([^%s%-]+)%-(.+)$")
	return (f and self:IsRealm(suffix)) and f or nil
end

-- (1.13.1) WoW Forever: a name with no surname nor realm (a first name alone), or as 1.13.0 made it: no whisper reaches
-- it for sure; only Battle.net, when it says whose it is.
function G:Unsure(name)
	if type(name) ~= "string" or not self:Surnames() then
		return false
	end
	return not string.find(name, "-", 1, true) or self:RealmForm(name) ~= nil
end

-- (1.13.1) WoW Forever: the other names a player of now ("First-Surname") had in what Curator 1.13.0 kept: their first
-- name alone, and their first name with my realm.
function G:Aliases(name)
	local first = type(name) == "string" and self:Surnames() and CuratorOctoFull.Match(name, "^([^%s%-]+)%-") or nil
	if not first or self:RealmForm(name) then
		return {}
	end
	local out = { first }
	local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName())
	if type(realm) == "string" and realm ~= "" and not Secret(realm) then
		out[CuratorOctoFull.Length(out) + 1] = first .. "-" .. string.gsub(realm, "[%s%-]", "")
	end
	return out
end

-- "Name-Realm" for the same realm shows as "Name"; (1.13.1) on WoW Forever, "First-Surname" as the game writes
-- it, "First Surname".
function G:Short(sender)
	if type(sender) ~= "string" or Secret(sender) then
		return sender
	end
	if self:Surnames() then
		local full = self:Full(sender) or sender
		return (string.gsub(full, "%-", " ", 1))
	end
	if Ambiguate then
		local ok, s = pcall(Ambiguate, sender, "guild")
		if ok and s then
			return s
		end
	end
	return (string.gsub(sender, "%-.*$", ""))
end

-- "Name-Realm", as the messages of other players come (the realm of mine when none is given). (1.13.1) On WoW
-- Forever, "First-Surname": from "First Surname" as the game writes it (a realm the old way after it, as Curator
-- 1.13.0 made it, left out), or from the first name and the surname apart; a first name alone stays alone (its
-- surname is not known here, and a realm would make it another character).
function G:Full(name, realm)
	if type(name) ~= "string" or name == "" or Secret(name) then
		return nil
	end
	local first, surname = CuratorOctoFull.Match(name, "^%s*([^%s%-]+)%s+([^%s%-]+)")
	if first then
		return first .. "-" .. surname
	end
	name = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
	if name == "" then
		return nil
	end
	if string.find(name, "-", 1, true) then
		-- (WoW Forever: a name of 1.13.0 with my realm after a first name alone stays as it is until it is made over,
		-- G:FixRealms: it says whom it was for; nothing goes to it by whisper, G:Send, Wire.lua)
		return name
	end
	-- (on WoW Forever, a surname after the first name; my realm there never: it is no part of a name)
	if type(realm) == "string" and realm ~= "" and not Secret(realm) and not (self:Surnames() and self:IsRealm(realm)) then
		return name .. "-" .. string.gsub(realm, "[%s%-]", "")
	end
	if self:Surnames() then
		return name
	end
	realm = GetNormalizedRealmName and GetNormalizedRealmName() or (GetRealmName and GetRealmName() or "")
	realm = string.gsub((realm or ""), "[%s%-]", "")
	if realm == "" then
		return name
	end
	return name .. "-" .. realm
end

-- Lower case, accented (É) and Cyrillic (Ж) letters included: names compare whatever their case.
function G.Fold(s)
	s = string.lower(s)
	-- À to Þ (C3 80-9E, × excepted) become à to þ (C3 A0-BE)
	s = string.gsub(s, "\195([\128-\150\152-\158])", function(c)
		return "\195" .. string.char(CuratorOctoFull.Byte(c) + 32)
	end)
	-- Ё (D0 81) becomes ё (D1 91), А to П (D0 90-9F) а to п (D0 B0-BF), Р to Я (D0 A0-AF) р to я (D1 80-8F)
	s = string.gsub(s, "\208([\129\144-\175])", function(c)
		local b = CuratorOctoFull.Byte(c)
		if b == 129 then
			return "\209\145"
		elseif b < 160 then
			return "\208" .. string.char(b + 32)
		end
		return "\209" .. string.char(b - 32)
	end)
	return s
end

-- The first letter in capital (an accented or Cyrillic one too), as the game writes names.
function G.Capital(s)
	local a, b = CuratorOctoFull.Byte(s, 1, 2)
	if a == 195 and b and b >= 160 and b <= 190 and b ~= 183 then
		return "\195" .. string.char(b - 32) .. string.sub(s, 3)
	elseif a == 208 and b and b >= 176 and b <= 191 then
		return "\208" .. string.char(b - 32) .. string.sub(s, 3)
	elseif a == 209 and b and b >= 128 and b <= 143 then
		return "\208" .. string.char(b + 32) .. string.sub(s, 3)
	elseif a == 209 and b == 145 then
		return "\208\129" .. string.sub(s, 3)
	end
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

function G:IsMe(name)
	if type(name) ~= "string" or Secret(name) then
		return false
	end
	-- (1.13.1: WoW Forever, "First Surname" as the game writes it: "First-Surname", as I am)
	name = self:Full(name) or name
	local me = self:Me()
	if not me then
		return false
	end
	if self:Surnames() then
		if name == me then
			return true
		end
		if self.meFold == nil or self.meFoldOf ~= me then
			self.meFold, self.meFoldOf = G.Fold(me), me
		end
		return G.Fold(name) == self.meFold
	end
	local short = self:Short(name)
	local mine = self:Surnames() and self:Short(me) or (UnitName("player") or "")
	return name == me or G.Fold(name) == G.Fold(me) or short == mine or G.Fold(short) == G.Fold(mine)
end

-- Messages that the client could not send right now (throttled) are sent again a moment later.
local queue = {}
local function Raw(msg, channel, target)
	local api = Chat()
	local ok, res = pcall(api.SendAddonMessage, PREFIX, msg, channel, target)
	if not ok then
		return false
	end
	if res == 3 or res == 8 then
		return nil -- throttled: later
	end
	return res == nil or res == true or res == 0
end

local function Flush()
	while queue[1] do
		local m = queue[1]
		local ok = Raw(m[1], m[2], m[3])
		if ok == nil and m[4] < 5 then
			m[4] = m[4] + 1
			ns.Delay(1, Flush, G)
			return
		end
		CuratorOctoFull.Remove(queue, 1)
	end
end

function G:Send(msg, channel, target)
	local api = Chat()
	if not (api and api.SendAddonMessage) or CuratorOctoFull.Length(msg) > MAX_LEN or Secret(target) then
		return false
	end
	-- (1.13.1: WoW Forever: a whisper to the name as Curator makes it, First-Surname)
	if channel == "WHISPER" and type(target) == "string" and self:Surnames() then
		target = self:Full(target) or target
	end
	-- (a friend of Battle.net: through Battle.net)
	if channel == "WHISPER" and ns.Trade then
		local id = ns.Trade:BNTarget(ns.Trade.Norm(target))
		if id then
			return ns.Trade:SendBN(id, PREFIX, msg)
		end
	end
	-- (1.13.1: WoW Forever: a name of 1.13.0 with my realm after it reaches nobody by whisper)
	if channel == "WHISPER" and self:RealmForm(target) then
		return false
	end
	if channel == "GUILD" and not IsInGuild() then
		return false
	end
	if api.InChatMessagingLockdown then
		local ok, locked = pcall(api.InChatMessagingLockdown)
		if ok and locked then
			return false
		end
	end
	if queue[1] then
		queue[CuratorOctoFull.Length(queue) + 1] = { msg, channel, target, 0 }
		return true
	end
	local ok = Raw(msg, channel, target)
	if ok == nil then
		queue[CuratorOctoFull.Length(queue) + 1] = { msg, channel, target, 0 }
		ns.Delay(1, Flush, G)
		return true
	end
	return ok
end

-------------------------------------------------------------------------------
-- Sending
-------------------------------------------------------------------------------
-- The summary of every album started, cut in as few messages as fit.
function G:SummaryMessages()
	local head = "S:" .. VERSION .. ":"
	-- the first message starts with "*": the receivers forget what they had (a reset reaches them)
	local msgs, cur = {}, head .. "*"
	for _, s in ipairs(ns.Series or {}) do
		local owned, total, leg, shiny, best, myth, holo = C:Summary(s)
		if owned > 0 then
			local part = table.concat({ s.key, owned, total, leg, shiny, best and best.key or "-", myth, holo }, ",")
			if CuratorOctoFull.Length(cur) + 1 + CuratorOctoFull.Length(part) > MAX_LEN then
				msgs[CuratorOctoFull.Length(msgs) + 1] = cur
				cur = head .. part
			else
				cur = cur .. ";" .. part
			end
		end
	end
	msgs[CuratorOctoFull.Length(msgs) + 1] = cur
	return msgs
end

-- My profile: the whole collection in a few numbers, my achievements as bits.
function G:ProfileMessage()
	local c = C:Census()
	local AC = ns.Achievements
	local earned = (ns.db and ns.db.ach) or {}
	local pts, count = AC:Points(earned)
	local female = false
	if UnitSex then
		local ok, sex = pcall(UnitSex, "player")
		female = ok and not Secret(sex) and sex == 3
	end
	local flags = ((ns.db and ns.db.test) and 1 or 0) + ((ns.db and ns.db.edited) and 2 or 0) + (female and 4 or 0)
	local f = { c.owned, c.total }
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		f[CuratorOctoFull.Length(f) + 1] = c.rar[r]
	end
	for _, v in ipairs({ c.shiny, c.holo, (ns.db and ns.db.opened) or 0, (ns.db and ns.db.contracts) or 0, pts, count, flags }) do
		f[CuratorOctoFull.Length(f) + 1] = v
	end
	-- (1.9.0: the bits six at a time, at the end; here none, for the length of the message)
	f[CuratorOctoFull.Length(f) + 1] = ""
	-- (after the bits: the clients before 0.18 read up to them and leave the rest)
	f[CuratorOctoFull.Length(f) + 1] = math.min(9999999, math.floor((ns.Level and ns.Level:XP()) or 0))
	-- (0.22: the number of the collection, its trades done)
	f[CuratorOctoFull.Length(f) + 1] = (ns.db and ns.db.uid) or "-"
	f[CuratorOctoFull.Length(f) + 1] = math.min(9999999, (ns.db and ns.db.stats and ns.db.stats.trades) or 0)
	-- (0.23: the version of Curator played, for the players to know a newer one exists)
	f[CuratorOctoFull.Length(f) + 1] = ns.version or "-"
	-- (1.5.0: the title of prestige chosen, when earned)
	local title = ns.db and ns.db.title
	f[CuratorOctoFull.Length(f) + 1] = (title and AC:HasSpecial(title, earned)) and title or "-"
	-- (1.6.0: the specialization of the talents)
	f[CuratorOctoFull.Length(f) + 1] = (ns.Talents and ns.Talents:Spec()) or "-"
	-- (1.8.0: the card of the collector as a combatant, his own way)
	local okc, code = pcall(function()
		return ns.Pvp and ns.Pvp:MyCode()
	end)
	f[CuratorOctoFull.Length(f) + 1] = (okc and code) or "-"
	-- (1.9.0: the achievements earned, six a letter)
	f[CuratorOctoFull.Length(f) + 1] = AC:Bits64(earned)
	return "I:" .. VERSION .. ":" .. table.concat(f, ",")
end

-- (1.14.0, after its second test) A card of a case in the showcase: its key ("k:<edition>:<card>", a weapon of legend
-- "k:<edition>:w<item>"), its finish (1 thunderforged, 2 titanforged), its grade, its marks and its certificate once
-- appraised, the step of its condition (1 Mint ... 5 Poor: never a grade hidden), the class and the side of the version
-- of its weapon. (A version of before knows no such card: it leaves it.)
local CASE_FIN = { thunder = "1", titan = "2" }
local CASE_FIN_OF = { ["1"] = "thunder", ["2"] = "titan" }
local function CaseEntry(v, bare)
	local CS = ns.Cases
	local w = v.copy
	local g = w.ap and tonumber(w.g) or nil
	-- (31 October: its wear after, its four marks and its seed: the others see the card as it is; bare: without it, the
	-- message too long)
	-- (veiled by its seed: never its grade in plain text, Cases.lua CS.Veil)
	local x, X = CS.WearOf(w), ns.Expertise
	local wm = (not bare) and x and X and X.EncodeMarks and CS.Veil(X.EncodeMarks(x.m), x.seed) or ""
	local parts = { v.case.key, CASE_FIN[w.f or ""] or "0", g and tostring(g) or "", g and tostring(w.m or "") or "",
		g and tostring(w.ce or "") or "", tostring(CS.Step(CS.Word(w))), tostring(w.cl or ""), tostring(w.fa or ""),
		wm, wm ~= "" and tostring(x.seed) or "" }
	-- (1 November, his word: the very same card: restored at an enchanter, what he did to it, Wear.lua)
	local rw = wm ~= "" and ns.Wear and ns.Wear.Pack and ns.Wear.Pack(w, true) or nil
	if rw then
		parts[11] = rw
	end
	return table.concat(parts, ",")
end

-- My showcase: its three cards and their finishes.
function G:ShowcaseMessage(bare)
	local parts = {}
	for _, v in ipairs(C:Showcase()) do
		if v.case then
			parts[CuratorOctoFull.Length(parts) + 1] = CaseEntry(v, bare)
		else
			-- (1.11.0) its grade, its marks and its certificate, when it was appraised
			local X = ns.Expertise
			local g = X and X:Grade(v.card)
			local extra = ""
			if g then
				-- (1.14.0: the talents of the Archivist that the others see, Signature (S) and Luxury Case (L): its marks)
				local TL, flags = ns.Talents, ""
				if TL and TL:Has("signature") then
					flags = flags .. "S"
				end
				if TL and TL:Has("luxury") and g >= 9 then
					flags = flags .. "L"
				end
				-- (the flags only when there are some: without them, the message as before 1.14.0)
				extra = "," .. g .. "," .. (X.EncodeMarks(X:Marks(v.card)) or "") .. "," .. (X:Cert(v.card) or "") .. (flags ~= "" and ("," .. flags) or "")
			end
			parts[CuratorOctoFull.Length(parts) + 1] = v.card.key .. "," .. FinishCode(v.finish) .. extra
		end
	end
	local msg = "V:" .. VERSION .. ":" .. table.concat(parts, ";")
	-- (31 October: too long for one message, the wear of its cards of cases left out, then its last cards: never nothing)
	if CuratorOctoFull.Length(msg) > MAX_LEN and not bare then
		return self:ShowcaseMessage(true)
	end
	while CuratorOctoFull.Length(msg) > MAX_LEN and CuratorOctoFull.Length(parts) > 1 do
		parts[CuratorOctoFull.Length(parts)] = nil
		msg = "V:" .. VERSION .. ":" .. table.concat(parts, ";")
	end
	return msg
end

-- (the four marks of a grade as the expert gives them, Expertise.lua: E:MarksFor; others are left)
local function MarksFit(m, g, top)
	if g >= top then
		return m[1] == top and m[2] == top and m[3] == top and m[4] == top
	end
	local sum = 0
	for i = 1, 4 do
		if m[i] < g - 1 or m[i] > g + 1 then
			return false
		end
		sum = sum + m[i]
	end
	return math.floor(sum / 4 + 0.5) == g
end

-- A card of a case another player shows (a part of their showcase): { ck, f, g, m, c, s, cl, fa }, else nil (an edition
-- or a card this version does not know). A weapon of legend is one of the list (UI/Crate.lua: CR.WeaponOf), its class
-- and its side as the list has them, never as they were sent.
local function ParseCase(f)
	local CS, CM, CR = ns.Cases, ns.CaseCards, ns.CrateUI
	local key = f[1] or ""
	if CuratorOctoFull.Length(key) > 48 then
		return nil
	end
	local case, what = CuratorOctoFull.Match(key, "^k:(%w+):(%w+)$")
	if not (case and CS and CS:Known(case)) then
		return nil
	end
	local wdef
	local weapon = CuratorOctoFull.Match(what, "^w(%d+)$")
	if weapon then
		wdef = CR and CR.WeaponOf and CR.WeaponOf(weapon)
		if not wdef then
			return nil
		end
	elseif not (CM and CM.Entry(case, what)) then
		return nil
	end
	local X = ns.Expertise
	local g = X and X.ValidGrade(f[3]) or nil
	if g and g ~= math.floor(g) then
		g = nil
	end
	local marks = g and X.DecodeMarks(f[4]) or nil
	if marks and not MarksFit(marks, g, X.MAX or 10) then
		marks = nil
	end
	local cert = g and tonumber(f[5]) or nil
	local step = Count(f[6])
	local word = CS.CONDITION[(step and step >= 1 and step <= CuratorOctoFull.Length(CS.CONDITION)) and step or CuratorOctoFull.Length(CS.CONDITION)][2]
	-- (31 October: its wear, its marks and its seed, when they came)
	local wm = X and X.DecodeMarks(f[9]) and f[9] or nil
	local wv = wm and Count(f[10]) or nil
	if not (wv and wv >= 1 and wv <= 999998) then
		wm, wv = nil, nil
	end
	-- (1 November: restored at an enchanter, what he did to it, Wear.lua)
	local rw = wv and f[11] and f[11] ~= "" and ns.Wear and ns.Wear.Unpack and ns.Wear.Unpack(f[11], true) or nil
	return { ck = wdef and ("k:" .. case .. ":w" .. wdef.id) or key, f = CASE_FIN_OF[f[2] or ""], g = g,
		m = marks and f[4] or nil, c = (cert and cert >= 0 and cert < 100000000 and cert == math.floor(cert)) and cert or nil,
		w = word, cl = wdef and wdef.class or nil, fa = wdef and wdef.faction or nil, wm = wm, wv = wv,
		w0 = rw and rw.w0 or nil, wx = rw and rw.wx or nil, wa = rw and rw.wa or nil }
end

-- My finest pulls, the finest first, cut in as few messages as fit.
function G:HistoryMessages()
	local head = "F:" .. VERSION .. ":"
	local msgs, cur = {}, head .. "*"
	for _, h in ipairs(C:History()) do
		local part = table.concat({ h.card.key, FinishCode(h.finish), HOW[h.how or ""] and h.how or "a", math.floor((h.t or 0) / 86400) }, ",")
		if CuratorOctoFull.Length(cur) + 1 + CuratorOctoFull.Length(part) > MAX_LEN then
			msgs[CuratorOctoFull.Length(msgs) + 1] = cur
			cur = head .. part
		else
			cur = cur .. ";" .. part
		end
	end
	msgs[CuratorOctoFull.Length(msgs) + 1] = cur
	return msgs
end

-- The finest pulls go when they changed since they were last sent (the first summary of a session
-- sends them); whoever wants them sooner asks with W:2.
function G:SendSummary()
	self.summaryPending = false
	self.lastSummary = GetTime()
	local all = self:Send(self:ProfileMessage(), "GUILD")
	all = self:Send(self:ShowcaseMessage(), "GUILD") and all
	for _, msg in ipairs(self:SummaryMessages()) do
		all = self:Send(msg, "GUILD") and all
	end
	local hist = self:HistoryMessages()
	local sig = table.concat(hist, "\n")
	if sig ~= self.historySent then
		local sent = true
		for _, msg in ipairs(hist) do
			sent = self:Send(msg, "GUILD") and sent
		end
		-- (not sent, the guild not reachable yet: they go with the next summary)
		if sent then
			self.historySent = sig
		end
		all = sent and all
	end
	-- the cards I look for, my cards to spare that someone looks for: when they changed
	local T = ns.Trade
	if T then
		for _, list in ipairs({ { "wishSent", T:WishMessages() }, { "spareSent", T:SpareMessages() } }) do
			local lsig = table.concat(list[2], "\n")
			if lsig ~= self[list[1]] then
				local sent = true
				for _, msg in ipairs(list[2]) do
					sent = self:Send(msg, "GUILD") and sent
				end
				if sent then
					self[list[1]] = lsig
				end
				all = sent and all
			end
		end
	end
	return all
end

-- Changes are grouped: one summary at most every SUMMARY_DELAY seconds.
function G:QueueSummary(delay)
	if self.summaryPending then
		return
	end
	self.summaryPending = true
	ns.Delay(delay or SUMMARY_DELAY, function()
		G:SendSummary()
	end, G)
end

-- finish: "shiny", "holo" (true: shiny) or nil
function G:Announce(card, finish)
	if not (ns.db and ns.db.announce) then
		return
	end
	local f = (finish == "holo" and 2) or ((finish == "shiny" or finish == true) and 1) or 0
	self:Send(string.format(("P:%s:%s,%s,%d"), VERSION, card.series.key, card.key, f), "GUILD")
end

-- (1.14.2, his word: "as soon as it is a rare or better we all see it with a small animation; I want it to come out more
-- often: rare at least, and titanforged and thunderforged too") A booster the guild watches open, live: a rare card or
-- better inside, or a forged one (thunderforged, titanforged) whatever its rarity (best: its best rarity; finish: its
-- finest finish, "holo" or "shiny").
function G.Worth(best, finish)
	return (tonumber(best) or 0) >= 3 or finish == "shiny" or finish == "holo"
end

-- (the rule of before 1.14.2: a legendary or a mythic card inside, or a titanforged one; the versions of before read it)
function G.OldRule(best, finish)
	return (tonumber(best) or 0) >= 5 or finish == "holo"
end

-- How fine an opening is, to compare two of them (a rarity, a finish): the rarity first, then its forge.
function G.OpenScore(rarity, finish)
	return (tonumber(rarity) or 0) * 10 + ((finish == "holo" and 6) or (finish == "shiny" and 3) or 0)
end

-- The card a booster shows to the guild (picks: its cards { card, finish }): a legendary or a mythic one, the finest; else
-- a titanforged one, the rarest; else the finest of them (a forged one ahead of another of its rarity). nil: none.
function G.Star(picks)
	local best, bestScore
	local top = 0
	for _, p in ipairs(picks or {}) do
		if p.card then
			top = math.max(top, p.card.rarity)
		end
	end
	for _, p in ipairs(picks or {}) do
		local card = p.card
		if card then
			local fin = (p.finish == "holo" or p.finish == "shiny") and p.finish or nil
			local score = G.OpenScore(card.rarity, fin)
			-- (as the rule of before shows them: the legendary and the mythic cards ahead, then the titanforged ones)
			if top >= 5 and card.rarity >= 5 then
				score = score + 1000
			elseif top < 5 and fin == "holo" then
				score = score + 500
			end
			if not bestScore or score > bestScore then
				best, bestScore = p, score
			end
		end
	end
	return best
end

-- The guild watches a booster being opened, live (UI/Live.lua): its album, its best rarity and its best finish; (1.14.2)
-- then the card it shows and its finish (star). Under the rule of before, as before (the versions of before read it);
-- below it, its album after "b:" (they leave it).
function G:AnnounceOpen(s, rarity, finish, star, starFinish)
	if not (ns.db and ns.db.announce) then
		return false
	end
	local msg = string.format(("O:%s:%s%s,%d,%d"), VERSION, G.OldRule(rarity, finish) and "" or "b:", s.key, rarity, FinishCode(finish))
	if type(star) == "table" and star.key then
		msg = msg .. "," .. star.key .. "," .. FinishCode(starFinish)
	end
	return self:Send(msg, "GUILD")
end

-- (1.14.2, his word: "a booster or a case") A case opened (Cases.lua: its card drawn and kept as it opens; rec: what
-- came): the guild watches it, live. Its edition, the rank of its card, its finish, its card (never its grade).
local CASE_FIN_CODE = { thunder = 1, titan = 2 }
function G:AnnounceCase(case, rec)
	if not (ns.db and ns.db.announce) or type(rec) ~= "table" then
		return false
	end
	local CS = ns.Cases
	if not (CS and CS:Known(case)) then
		return false
	end
	local what = (tonumber(rec.w) and ("w" .. math.floor(rec.w))) or (type(rec.e) == "string" and rec.e) or nil
	if not what then
		return false
	end
	return self:Send(string.format(("O:%s:k:%s,%d,%d,%s"), VERSION, case, math.floor(tonumber(rec.r) or 1), CASE_FIN_CODE[rec.f or ""] or 0, what), "GUILD")
end

-- An achievement the guild hears about: the albums completed, and those worth 25 points or more.
function G:AnnounceAchievement(a)
	if not (ns.db and ns.db.announce) or not (a.series or a.pts >= 25) then
		return
	end
	self:Send(string.format(("H:%s:%s"), VERSION, a.id), "GUILD")
end

-- (1.10.0) A golden quest turned in: the guild hears of it (the key of its leader).
function G:AnnounceGolden(leaderKey)
	if not (ns.db and ns.db.announce) or type(leaderKey) ~= "string" then
		return
	end
	self:Send(string.format(("G:%s:%s"), VERSION, leaderKey), "GUILD")
end

-- Asks the guild for their summaries (when the guild page opens).
function G:Query()
	-- (1.14.2: the roster of the game asked again too, the client gives it at most every ten seconds: who joined the
	-- guild, who left it, for its section of the social page, UI/Social.lua)
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		pcall(C_GuildInfo.GuildRoster)
	end
	local now = GetTime()
	if self.lastQuery and now - self.lastQuery < QUERY_COOLDOWN then
		return false
	end
	self.lastQuery = now
	return self:Send("Q:" .. VERSION, "GUILD")
end

-- Asks a player for their profile (full: and their summaries, to look through their albums). A
-- tooltip asks at most one player a second, and each player once in a while.
function G:Ask(name, full)
	if not name or self:IsMe(name) or Secret(name) then
		return false
	end
	self.asked = self.asked or {}
	local now = GetTime()
	local key = name .. (full and ":2" or ":1")
	local last = self.asked[key]
	if last and now - last < (full and 8 or 120) then
		return false
	end
	if not full and self.lastAsk and now - self.lastAsk < 1 then
		return false
	end
	self.asked[key] = now
	if not full then
		self.lastAsk = now
	end
	return self:Send(string.format(("W:%s:%d"), VERSION, full and 2 or 1), "WHISPER", name)
end

-- My profile and my showcase (and my summaries and my finest pulls) to a player who asked.
function G:SendProfile(target, full)
	-- (1.14.0, Gallery, a talent of the Archivist: a collector who looks at my showcase)
	if full and ns.Talents and ns.Talents.Visitor then
		ns.Talents:Visitor(target)
	end
	local all = self:Send(self:ProfileMessage(), "WHISPER", target)
	all = self:Send(self:ShowcaseMessage(), "WHISPER", target) and all
	if full then
		-- (1.10.0: the luck of the boosters went here, a message of its own; 1.14.0, after its test: the profile shows it
		-- no more, nor sends it)
		for _, msg in ipairs(self:SummaryMessages()) do
			all = self:Send(msg, "WHISPER", target) and all
		end
		for _, msg in ipairs(self:HistoryMessages()) do
			all = self:Send(msg, "WHISPER", target) and all
		end
		if ns.Trade then
			for _, msg in ipairs(ns.Trade:WishMessages()) do
				all = self:Send(msg, "WHISPER", target) and all
			end
			-- (1.6.0, the talent Network: to a player I traded with, my cards to spare they look for)
			if ns.Talents and ns.Talents:Has("network") and ns.Talents:Partner(ns.Trade.Norm(target)) then
				for _, msg in ipairs(ns.Trade:SpareFor(target)) do
					all = self:Send(msg, "WHISPER", target) and all
				end
			end
		end
	end
	return all
end

-- My album, in as many whispers as it takes.
function G:SendAlbum(s, target)
	local counts, shinies, holos = C:Encode(s)
	local data = counts .. shinies .. holos
	local parts = math.max(1, math.ceil(CuratorOctoFull.Length(data) / PART_LEN))
	local all = true
	for i = 1, parts do
		local chunk = string.sub(data, (i - 1) * PART_LEN + 1, i * PART_LEN)
		all = self:Send(string.format(("A:%s:%s,%d,%d,%s"), VERSION, s.key, i, parts, chunk), "WHISPER", target) and all
	end
	return all
end

function G:RequestAlbum(name, s)
	self.waiting = self.waiting or {}
	self.waiting[name .. ":" .. s.key] = GetTime()
	return self:Send(string.format(("R:%s:%s"), VERSION, s.key), "WHISPER", name)
end

-------------------------------------------------------------------------------
-- What other players shared: the guild members, and the players met
-------------------------------------------------------------------------------
local function Split(str, sep)
	local out = {}
	for part in CuratorOctoFull.Gmatch((str .. sep), "(.-)" .. sep) do
		out[CuratorOctoFull.Length(out) + 1] = part
	end
	return out
end

function G:Member(name)
	local db = ns.db.guild
	db[name] = db[name] or { s = {}, c = {} }
	return db[name]
end

-- The players met: the most recent ones are kept.
function G:Prune()
	local met, list = ns.db.met, {}
	for name, m in pairs(met) do
		list[CuratorOctoFull.Length(list) + 1] = { name = name, t = m.t or 0 }
	end
	if CuratorOctoFull.Length(list) <= MET_MAX then
		return
	end
	table.sort(list, function(a, b)
		return a.t > b.t
	end)
	for i = MET_MAX + 1, CuratorOctoFull.Length(list) do
		met[list[i].name] = nil
	end
end

-- Where what a player sends goes: with the guild members (what comes from the guild channel, or
-- from a player already known there), else with the players met.
function G:Store(name, channel)
	if channel == "GUILD" or ns.db.guild[name] then
		return self:Member(name)
	end
	local met = ns.db.met
	local m = met[name]
	if not m then
		m = { s = {}, c = {}, t = CuratorOctoFull.ServerTime() }
		met[name] = m
		self:Prune()
	end
	return m
end

-- What a player shared (a guild member or a player met), by name.
function G:Player(name)
	if not (name and ns.db) then
		return nil
	end
	local m = ns.db.guild[name] or ns.db.met[name]
	-- (1.13.1: WoW Forever: "First Surname" as the game writes it, kept as "First-Surname")
	if m == nil and type(name) == "string" and string.find(name, " ", 1, true) then
		local full = self:Full(name)
		if full and full ~= name then
			m = ns.db.guild[full] or ns.db.met[full]
		end
	end
	return m
end

-- The name a player is known by, whatever the case of the letters typed. (1.13.1) loose: a name typed in a command,
-- on WoW Forever a first name alone that one player known has (never for a menu nor a trade: it could be another one).
function G:Canon(name, loose)
	if not (name and ns.db) then
		return name
	end
	if type(name) == "string" and string.find(name, " ", 1, true) then
		name = self:Full(name) or name
	end
	if ns.db.guild[name] or ns.db.met[name] then
		return name
	end
	local low = G.Fold(name)
	for _, db in ipairs({ ns.db.guild, ns.db.met }) do
		for known in pairs(db) do
			if G.Fold(known) == low then
				return known
			end
		end
	end
	-- (1.13.1: WoW Forever: a first name alone, as a player types it: the one player known by it)
	if loose and self:Surnames() and not string.find(name, "-", 1, true) then
		local found
		for _, db in ipairs({ ns.db.guild, ns.db.met }) do
			for known in pairs(db) do
				local first = CuratorOctoFull.Match(known, "^([^%-]+)%-")
				if first and G.Fold(first) == low then
					if found and found ~= known then
						return name
					end
					found = known
				end
			end
		end
		if found then
			return found
		end
	end
	return name
end

-- The profile of a player, when it came (and if it is fresh: fresh = true).
function G:Profile(name)
	local m = self:Player(name)
	local i = m and m.i
	if not i then
		return nil
	end
	return i, (CuratorOctoFull.ServerTime() - (i.t or 0)) < PROFILE_FRESH
end

-- A player's summary of an album.
function G:Summary(name, s)
	local m = self:Player(name)
	return m and m.s[s.key]
end

-- A player's showcase ({ { card, finish, grade } }), when they sent it.
function G:Showcase(name)
	local m = self:Player(name)
	if not (m and m.v) then
		return nil
	end
	local out = {}
	local CR, CD, CM = ns.CrateUI, ns.CaseDetail, ns.CaseCards
	for _, v in ipairs(m.v) do
		local card = ns.Cards[v.k or ""]
		if card then
			local X = ns.Expertise
			local g = X and X.ValidGrade(v.g) or nil
			out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = v.f, grade = g, marks = g and X.DecodeMarks(v.m) or nil, cert = g and tonumber(v.c) or nil,
				sig = g and v.sig or nil, lux = g and v.lux or nil }
		elseif v.ck and CD and CM then
			-- (1.14.0, after its second test) a card of a case: its copy as they showed it, { case, copy } as in mine
			local case, what = CuratorOctoFull.Match(v.ck, "^k:(%w+):(%w+)$")
			local weapon = what and tonumber(CuratorOctoFull.Match(what, "^w(%d+)$") or "")
			local _, r = CM.Entry(case, what)
			local w = { c = case, e = (not weapon) and what or nil, w = weapon, r = weapon and CR.TOP or r, f = v.f, cw = v.w,
				ap = v.g ~= nil or nil, g = v.g, m = v.m, ce = v.c, cl = v.cl, fa = v.fa, wm = v.wm, wv = v.wv, w0 = v.w0, wx = v.wx, wa = v.wa }
			if w.r then
				out[CuratorOctoFull.Length(out) + 1] = { case = CD.DescOf(w), copy = w, theirs = true }
			end
		end
	end
	return out
end

-- A player's finest pulls (as C:Pulls gives them), when they sent them.
function G:History(name)
	local m = self:Player(name)
	return m and m.hist and C:Pulls(m.hist) or nil
end

-- (1.14.2) A case a member of the guild opened (O:1:k:<edition>,<rank>,<finish>,<card>): what came as a card won is kept
-- ({ c = its edition, r = its rank, e = its card, or w = its weapon of legend with its class cl and its side fa as the
-- list has them, f = its finish }), else nil (an edition, a card or a rank this version does not know).
local CASE_FIN_OF_CODE = { ["1"] = "thunder", ["2"] = "titan" }
local function OpenedCase(case, f)
	local CS, CR, CM = ns.Cases, ns.CrateUI, ns.CaseCards
	if not (CS and CS:Known(case) and CR and CM) then
		return nil
	end
	local r = Count(f[2])
	local what = f[4] or ""
	if not r or CuratorOctoFull.Length(what) > 16 then
		return nil
	end
	local fin = CASE_FIN_OF_CODE[f[3] or ""]
	local weapon = CuratorOctoFull.Match(what, "^w(%d+)$")
	if weapon then
		local w = CR.WeaponOf(weapon)
		if not w or r ~= CR.TOP then
			return nil
		end
		return { c = case, r = CR.TOP, w = w.id, cl = w.class, fa = w.faction, f = fin }
	end
	local e, er = CM.Entry(case, what)
	if not e or r ~= er then
		return nil
	end
	return { c = case, r = er, e = what, f = fin }
end

-- (the same, from a find kept: its edition, its rank, its card, its finish)
function G.CaseCard(case, r, what, finish)
	if type(case) ~= "string" or type(what) ~= "string" then
		return nil
	end
	return OpenedCase(case, { "k:" .. case, tostring(tonumber(r) or ""), (finish == "titan" and "2") or (finish == "thunder" and "1") or "0", what })
end

-------------------------------------------------------------------------------
-- (1.14.2, his word: "a Guild tab with the finds of the people of the guild") The finds of the guild: the pulls worth
-- showing (P), the boosters (O) and the cases (O, "k:") opened live, the achievements (H) and the golden quests (G) its
-- members told, each kept with what that member shared (db.guild[name].fd: out of the seal, emptied at the release and
-- by a reset, Core.lua), the FINDS_MAX latest of them all, from one session to the next. A find: { t = when, k = its
-- kind: "p" a pull (c its card, f its finish); "o" a booster (s its album, r its best rarity, f its finest finish, c and
-- cf the card it showed, v true once that card was turned over); "k" a case (e its edition, r the rank of its card, x its
-- card, f its finish); "a" an achievement (a); "g" a golden quest (l its leader) }.
-------------------------------------------------------------------------------
G.FINDS_MAX = 40
-- (the pull of the card a booster of that member showed a moment before: that booster, not another find)
local FIND_JOIN = 300

-- The finds kept: the oldest past FINDS_MAX let go.
function G:PruneFinds()
	local all = {}
	for _, m in pairs(ns.db.guild) do
		if type(m) == "table" and type(m.fd) == "table" then
			for _, x in ipairs(m.fd) do
				all[CuratorOctoFull.Length(all) + 1] = { x = x, t = tonumber(type(x) == "table" and x.t) or 0 }
			end
		end
	end
	if CuratorOctoFull.Length(all) <= self.FINDS_MAX then
		return
	end
	table.sort(all, function(a, b)
		return a.t > b.t
	end)
	local gone = {}
	for i = self.FINDS_MAX + 1, CuratorOctoFull.Length(all) do
		gone[all[i].x] = true
	end
	for _, m in pairs(ns.db.guild) do
		if type(m) == "table" and type(m.fd) == "table" then
			local keep = {}
			for _, x in ipairs(m.fd) do
				if not gone[x] then
					keep[CuratorOctoFull.Length(keep) + 1] = x
				end
			end
			m.fd = CuratorOctoFull.Length(keep) > 0 and keep or nil
		end
	end
end

-- A find of a member of the guild (x: as above; its time given here). The find kept, else nil.
function G:AddFind(sender, x)
	if not (ns.db and ns.db.guild and type(sender) == "string" and type(x) == "table") or self:IsMe(sender) then
		return nil
	end
	local m = self:Store(sender, "GUILD")
	local now = math.floor(CuratorOctoFull.ServerTime())
	m.t = now
	x.t = now
	if type(m.fd) ~= "table" then
		m.fd = {}
	end
	m.fd[CuratorOctoFull.Length(m.fd) + 1] = x
	self:PruneFinds()
	ns.Fire("GUILD_FINDS", sender, x)
	return x
end

-- A pull worth showing (P): the card a booster of that member opened a moment before showed (or, from a version of
-- before, the card it waited for: a legendary or a mythic one of its best rarity, else a titanforged one): that find,
-- its card seen; else a find of its own.
function G:PullFind(sender, card, finish)
	local m = self:Player(sender)
	local fd = m and type(m.fd) == "table" and m.fd or nil
	local now = math.floor(CuratorOctoFull.ServerTime())
	for i = CuratorOctoFull.Length((fd or {})), 1, -1 do
		local x = fd[i]
		if type(x) == "table" and x.k == "o" and not x.v and now - (tonumber(x.t) or 0) <= FIND_JOIN and x.s == card.series.key then
			local r = tonumber(x.r) or 0
			if x.c == card.key or (x.c == nil and ((r >= 5 and card.rarity >= r) or (r < 5 and finish == "holo"))) then
				x.v = true
				if x.c == nil then
					x.c, x.cf = card.key, finish
				end
				ns.Fire("GUILD_FINDS", sender, x)
				return x
			end
		end
	end
	return self:AddFind(sender, { k = "p", c = card.key, f = finish })
end

-- The finds of the guild, the latest first: { { who = name, x = find, t = when } } (never mine, nor of a character
-- banned from Curator).
function G:FindList()
	local out = {}
	local B = ns.Bans
	for name, m in pairs((ns.db and ns.db.guild) or {}) do
		if type(m) == "table" and type(m.fd) == "table" and not self:IsMe(name) and not (B and B:Sender(name)) then
			for _, x in ipairs(m.fd) do
				if type(x) == "table" then
					out[CuratorOctoFull.Length(out) + 1] = { who = name, x = x, t = tonumber(x.t) or 0 }
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a.t ~= b.t then
			return a.t > b.t
		end
		return a.who < b.who
	end)
	return out
end

local function ParseProfile(body)
	local f = Split(body, ",")
	if CuratorOctoFull.Length(f) < 16 then
		return nil
	end
	local n = {}
	for k = 1, 15 do
		n[k] = Count(f[k])
		if not n[k] then
			return nil
		end
	end
	local i = { owned = n[1], total = n[2], rar = {}, shiny = n[9], holo = n[10], opened = n[11], contracts = n[12],
		points = n[13], count = n[14], flags = n[15], bits = CuratorOctoFull.Match(f[16], "^%x*$") and f[16] or "", t = CuratorOctoFull.ServerTime() }
	for r = 1, 6 do
		i.rar[r] = n[2 + r]
	end
	i.test = CuratorOctoFull.Mod(i.flags , 2) == 1
	i.edited = CuratorOctoFull.Mod(math.floor(i.flags / 2) , 2) == 1
	i.female = CuratorOctoFull.Mod(math.floor(i.flags / 4) , 2) == 1
	-- the experience of the collector (none from a player before 0.18)
	i.xp = Count(f[17])
	-- the number of the collection and its trades done (none before 0.22: that Curator does not trade)
	local uid = f[18]
	if type(uid) == "string" and CuratorOctoFull.Match(uid, "^%w+$") and CuratorOctoFull.Length(uid) <= 8 then
		i.uid = uid
		i.trades = Count(f[19])
	end
	-- the version of Curator they play (none before 0.23)
	local ver = f[20]
	if type(ver) == "string" and CuratorOctoFull.Length(ver) <= 12 and CuratorOctoFull.Match(ver, "^%d+%.%d+%.?%d*$") then
		i.ver = ver
	end
	-- their title of prestige (none before 1.5.0); shown when their achievements have it
	local title = f[21]
	if type(title) == "string" and ns.Achievements and ns.Achievements.SPECIAL_BY[title] then
		i.title = title
	end
	-- their specialization of the talents (none before 1.6.0)
	local spec = f[22]
	if type(spec) == "string" and ns.Talents and ns.Talents.SPEC_BY[spec] then
		i.spec = spec
	end
	-- their card as a combatant (none before 1.8.0)
	i.combat = ns.Pvp and ns.Pvp.ParseCode(f[23]) or nil
	-- their achievements six a letter (1.9.0 on: their bits of before are empty)
	local hex = ns.Achievements and ns.Achievements.HexOf64(f[24])
	if hex then
		i.bits = hex
	end
	return i
end

function G:OnMessage(text, channel, sender, localID, channelName)
	if Secret(text) or Secret(sender) or Secret(channel) then
		return
	end
	if type(text) ~= "string" or type(sender) ~= "string" then
		return
	end
	-- (1.13.1: WoW Forever: who sent it as Curator names them, "First-Surname"; the game writes "First Surname")
	sender = self:Full(sender) or sender
	if self:IsMe(sender) then
		return
	end
	local kind, ver, body = CuratorOctoFull.Match(text, "^(%a):(%d+):?(.*)$")
	if not kind or ver ~= VERSION then
		return
	end
	-- (1.12.1) A character banned from Curator (Bans.lua): nothing of theirs is read. But the hello, the roll
	-- call and the secret of an obsolete version on the hidden channel (the messages most often there: no
	-- fingerprint made for each), and, for the page of the author, their hello and their profile: he sees
	-- them there, said banned.
	local B = ns.Bans
	if B and not (channel == "CHANNEL" and (kind == "L" or kind == "Y" or kind == "X")) and not (ns.Admin and (kind == "L" or kind == "I"))
		and B:Sender(sender) then
		return
	end
	-- (a channel: only the hidden one of the players who agreed, and only its hello and its roll call)
	local P = ns.Presence
	if channel == "CHANNEL" then
		if P and (kind == "L" or kind == "Y") and P:Ours(localID, channelName) then
			P:OnMessage(kind, body, channel, sender)
		elseif kind == "X" and P and ns.Mandatory and P:Ours(localID, channelName) then
			ns.Mandatory:OnMessage(body, channel, sender)
		elseif kind == "B" and ns.Channel and ns.Channel:Ours(localID, channelName) then
			-- (1.12.1: the collector level said on the chat channel of the collectors, Channel.lua)
			ns.Channel:OnMessage(body, channel, sender)
		end
		return
	elseif kind == "L" then
		if P and channel == "WHISPER" then
			P:OnMessage(kind, body, channel, sender)
		end
		return
	elseif kind == "X" then
		-- (1.4: the secret of an obsolete version, Mandatory.lua)
		if ns.Mandatory then
			ns.Mandatory:OnMessage(body, channel, sender)
		end
		return
	end
	-- (they are there: the trades to settle with them are checked)
	local T = ns.Trade
	if T then
		T:Contact(sender)
		if kind == "T" or kind == "N" or kind == "U" or kind == "E" then
			return T:OnMessage(kind, body, channel, sender)
		end
	end
	-- (1.8.0: the kinds of messages the modules read themselves)
	local handler = self.handlers[kind]
	if handler then
		return handler(body, channel, sender)
	end
	if kind == "S" then
		local m = self:Store(sender, channel)
		m.t = CuratorOctoFull.ServerTime()
		local parts = Split(body, ";")
		if parts[1] == "*" then
			CuratorOctoFull.Wipe(m.s)
		end
		for _, part in ipairs(parts) do
			local f = Split(part, ",")
			local s = ns.SeriesByKey(f[1])
			if s and CuratorOctoFull.Length(f) >= 6 then
				m.s[s.key] = {
					o = Count(f[2]) or 0, n = Count(f[3]) or CuratorOctoFull.Length(s.list),
					l = Count(f[4]) or 0, sh = Count(f[5]) or 0,
					best = ns.Cards[f[6]] and f[6] or nil, my = Count(f[7]) or 0, ho = Count(f[8]) or 0,
				}
			end
		end
		ns.Fire("GUILD_CHANGED", sender)
	elseif kind == "I" then
		local i = ParseProfile(body)
		if i then
			local m = self:Store(sender, channel)
			m.t = CuratorOctoFull.ServerTime()
			m.i = i
			ns.Fire("PLAYER_INFO", sender)
		end
	elseif kind == "V" then
		local m = self:Store(sender, channel)
		m.t = CuratorOctoFull.ServerTime()
		m.v = {}
		for _, part in ipairs(Split(body, ";")) do
			local f = Split(part, ",")
			local card = ns.Cards[f[1] or ""]
			if card and CuratorOctoFull.Length(m.v) < (C.SHOWCASE_MAX or C.SHOWCASE_SIZE) then
				local X = ns.Expertise
				-- (1.13.0: a copy restored, its grade with its decimals)
				local g = X and X.ValidGrade(f[3]) or nil
				local c = g and tonumber(f[5]) or nil
				-- (1.14.0: Signature and Luxury Case, talents of the Archivist)
				local flags = g and type(f[6]) == "string" and string.sub(f[6], 1, 4) or ""
				m.v[CuratorOctoFull.Length(m.v) + 1] = { k = card.key, f = FinishOf(f[2]), g = g, m = g and X.DecodeMarks(f[4]) and f[4] or nil,
					c = (c and c >= 0 and c < 100000000 and c == math.floor(c)) and c or nil,
					sig = string.find(flags, "S", 1, true) ~= nil or nil, lux = (g and g >= 9 and string.find(flags, "L", 1, true) ~= nil) or nil }
			elseif not card and CuratorOctoFull.Length(m.v) < (C.SHOWCASE_MAX or C.SHOWCASE_SIZE) then
				-- (1.14.0, after its second test: a card of a case)
				local v = ParseCase(f)
				if v then
					m.v[CuratorOctoFull.Length(m.v) + 1] = v
				end
			end
		end
		ns.Fire("PLAYER_INFO", sender)
	elseif kind == "F" then
		local m = self:Store(sender, channel)
		m.t = CuratorOctoFull.ServerTime()
		local parts = Split(body, ";")
		if parts[1] == "*" or not m.hist then
			m.hist = {}
		end
		for _, part in ipairs(parts) do
			local f = Split(part, ",")
			local card = ns.Cards[f[1] or ""]
			local day = Count(f[4])
			if card and day and CuratorOctoFull.Length(m.hist) < C.HISTORY_MAX then
				-- (the day at noon: its date reads the same on both sides of the world)
				m.hist[CuratorOctoFull.Length(m.hist) + 1] = { k = card.key, f = FinishOf(f[2]), s = HOW[f[3] or ""] and f[3] or "a", t = day * 86400 + 43200 }
			end
		end
		ns.Fire("PLAYER_INFO", sender)
	elseif kind == "P" then
		local f = Split(body, ",")
		local card = ns.Cards[f[2] or ""]
		if card and card.series.key == f[1] then
			-- (1.14.2: a find of the guild, kept; the card of a booster it watched open: that opening)
			if channel == "GUILD" then
				self:PullFind(sender, card, FinishOf(f[3]))
			end
			ns.Fire("GUILD_PULL", sender, card, FinishOf(f[3]))
		end
	elseif kind == "O" then
		if channel ~= "GUILD" then
			return
		end
		local f = Split(body, ",")
		local key = f[1] or ""
		-- (1.14.2) a case opened
		local case = CuratorOctoFull.Match(key, "^k:(%w+)$")
		if case then
			local v = OpenedCase(case, f)
			if v then
				self:AddFind(sender, { k = "k", e = case, r = v.r, x = v.e or ("w" .. v.w), f = v.f })
				ns.Fire("GUILD_CASE", sender, case, v)
			end
			return
		end
		-- (1.14.2: a booster below the rule of before, its album after "b:")
		local s = ns.SeriesByKey(CuratorOctoFull.Match(key, "^b:(.+)$") or key)
		local r = Count(f[2])
		if s and r then
			local best, finish = math.max(1, math.min(CuratorOctoFull.Length(ns.RARITY), r)), FinishOf(f[3])
			-- (1.14.2: the card it shows, of that album; none from a version of before)
			local star = ns.Cards[f[4] or ""]
			if star and star.series ~= s then
				star = nil
			end
			local starFinish = star and FinishOf(f[5]) or nil
			self:AddFind(sender, { k = "o", s = s.key, r = best, f = finish, c = star and star.key or nil, cf = starFinish })
			ns.Fire("GUILD_OPEN", sender, s, best, finish, star, starFinish)
		end
	elseif kind == "H" then
		local a = ns.Achievements and ns.Achievements:Build() and ns.Achievements.byId[body]
		if a and channel == "GUILD" then
			self:AddFind(sender, { k = "a", a = a.id })
			ns.Fire("GUILD_ACH", sender, a)
		end
	elseif kind == "G" then
		-- (1.10.0: a golden quest turned in by a member of the guild)
		local l = ns.Golden and ns.Golden:Leader(body)
		if l and channel == "GUILD" then
			self:AddFind(sender, { k = "g", l = l.key })
			ns.Fire("GUILD_GOLDEN", sender, l)
		end
	elseif kind == "Q" then
		-- answer a little later, so a whole guild does not answer at the same moment
		if not self.answering then
			self.answering = true
			ns.Delay(1 + (math.random() * 4), function()
				G.answering = false
				G:SendSummary()
			end, G)
		end
	elseif kind == "W" and channel == "WHISPER" then
		self.replied = self.replied or {}
		local key = sender .. ":W" .. body
		local now = GetTime()
		if not self.replied[key] or now - self.replied[key] > 5 then
			self.replied[key] = now
			self:SendProfile(sender, body == "2")
		end
	elseif kind == "R" and channel == "WHISPER" then
		local s = ns.SeriesByKey(body)
		self.replied = self.replied or {}
		local key = sender .. ":" .. body
		local now = GetTime()
		if s and (not self.replied[key] or now - self.replied[key] > 10) then
			self.replied[key] = now
			self:SendAlbum(s, sender)
		end
	elseif kind == "A" then
		-- a part of an album: kept until all the parts are there
		local f = Split(body, ",")
		local s = ns.SeriesByKey(f[1])
		local i, n = tonumber(f[2]), tonumber(f[3])
		if s and i and n and i >= 1 and i <= n and n <= 20 and f[4] then
			self.parts = self.parts or {}
			local key = sender .. ":" .. s.key
			local p = self.parts[key]
			local now = GetTime()
			if not p or p.n ~= n or now - p.t > 30 then
				p = { n = n, got = {}, t = now }
				self.parts[key] = p
			end
			p.got[i] = f[4]
			local data = {}
			for k = 1, n do
				if not p.got[k] then
					return
				end
				data[k] = p.got[k]
			end
			self.parts[key] = nil
			data = table.concat(data)
			-- the copies, then the shiny bits and the holographic bits (none from a member on 0.7)
			local n, b = CuratorOctoFull.Length(s.list), math.ceil(CuratorOctoFull.Length(s.list) / 4)
			self:ReceiveAlbum(sender, s, string.sub(data, 1, n), string.sub(data, n + 1, n + b), string.sub(data, n + b + 1, n + 2 * b), channel)
		end
	elseif kind == "C" then
		local f = Split(body, ",")
		local s = ns.SeriesByKey(f[1])
		if s then
			self:ReceiveAlbum(sender, s, f[2], f[3], nil, channel)
		end
	end
end

-- (1.8.0) A kind of message a module reads itself (a letter no other kind takes): fn(body, channel, sender).
function G:Handle(kind, fn)
	self.handlers[kind] = fn
end

-- An album sent by a player, kept when it reads well (the same cards as mine: the same version).
function G:ReceiveAlbum(sender, s, counts, shinies, holos, channel)
	if C:Decode(s, counts, shinies, holos) then
		local m = self:Store(sender, channel)
		m.t = CuratorOctoFull.ServerTime()
		m.c[s.key] = { counts = counts, shinies = shinies, holos = holos, t = CuratorOctoFull.ServerTime() }
		ns.Fire("GUILD_ALBUM", sender, s)
	end
end

-- The members who shared something, best collections first.
function G:Members(s)
	local list = {}
	for name, m in pairs(ns.db.guild) do
		local sum = m.s[s.key]
		if sum or m.c[s.key] then
			list[CuratorOctoFull.Length(list) + 1] = { name = name, short = self:Short(name), sum = sum, t = m.t or 0, i = m.i }
		end
	end
	table.sort(list, function(a, b)
		local oa, ob = a.sum and a.sum.o or 0, b.sum and b.sum.o or 0
		if oa ~= ob then
			return oa > ob
		end
		return a.short < b.short
	end)
	return list
end

-- A player's album as entries ([cardKey] = { n, s, h }), when they sent it.
function G:Album(name, s)
	local m = self:Player(name)
	local c = m and m.c[s.key]
	return c and C:Decode(s, c.counts, c.shinies, c.holos)
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
local f = CreateFrame("Frame")
G.frame = f
f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		local api = Chat()
		if api and api.RegisterAddonMessagePrefix then
			pcall(api.RegisterAddonMessagePrefix, PREFIX)
		end
		f:RegisterEvent("CHAT_MSG_ADDON")
		ns.Delay(8, function()
			G:SendSummary()
		end, G)
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, text, channel, sender, _, _, localID, channelName = unpack(arg, 1, arg.n)
		if not Secret(prefix) and prefix == PREFIX then
			G:OnMessage(text, channel, sender, localID, channelName)
		end
	end
end)

for _, e in ipairs({ "CHANGED", "SHOWCASE_CHANGED", "XP_GAINED" }) do
	local _, e = _, e; ns.On(e, function()
		if G.ready then
			G:QueueSummary()
		end
	end)
end
ns.On("ACH_EARNED", function(a)
	G:AnnounceAchievement(a)
	G:QueueSummary()
end)
-- (1.14.2) A case opened for real (Cases.lua, CS:Open: as its band starts to run): the guild watches it.
ns.On("CASE_OPENED", function(case, rec)
	G:AnnounceCase(case, rec)
end)
-- (1.13.1) WoW Forever: the players Curator 1.13.0 and before kept as the game wrote them ("First Surname"), or
-- as they made them for a message ("First Surname-Realm", which reached nobody), kept under the name Curator gives
-- them now ("First-Surname"); two names of the same player made one (what each holds kept, the latest first). In
-- the players known, the trades and the duels, the wire, the collections looked at and the partners counted.
local function Merge(into, from)
	if type(into) ~= "table" or type(from) ~= "table" then
		return into or from
	end
	if (tonumber(from.t) or 0) > (tonumber(into.t) or 0) then
		into, from = from, into
	end
	for k, v in pairs(from) do
		if into[k] == nil then
			into[k] = v
		elseif type(into[k]) == "table" and type(v) == "table" and k ~= "i" then
			for kk, vv in pairs(v) do
				if into[k][kk] == nil then
					into[k][kk] = vv
				end
			end
		end
	end
	return into
end

-- (the messages waiting for a player, two queues made one; the players who said hello, on the page of the author:
-- the first time and the last one kept)
local function Concat(a, b)
	if type(a) == "table" and type(b) == "table" then
		for _, x in ipairs(b) do
			a[CuratorOctoFull.Length(a) + 1] = x
		end
	end
	return a
end

local function MergeSeen(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a or b
	end
	local newer, older = a, b
	if (tonumber(b.last) or 0) > (tonumber(a.last) or 0) then
		newer, older = b, a
	end
	for k, v in pairs(older) do
		if newer[k] == nil then
			newer[k] = v
		end
	end
	if tonumber(older.first) and (not tonumber(newer.first) or older.first < newer.first) then
		newer.first = older.first
	end
	return newer
end

local function Renamed(name)
	if type(name) ~= "string" or not string.find(name, " ", 1, true) then
		return nil
	end
	local full = G:Full(name)
	return full ~= name and full or nil
end
G.Renamed = Renamed

-- The keys of a table renamed (rename(key, value): its new name, or nil), two of the same player made one by merge
-- (nil: the one already there kept).
local function RenameKeys(t, merge, rename)
	if type(t) ~= "table" then
		return 0
	end
	rename = rename or Renamed
	local moved = {}
	for k, v in pairs(t) do
		local to = rename(k, v)
		if to and to ~= k then
			moved[CuratorOctoFull.Length(moved) + 1] = { k, to }
		end
	end
	for _, m in ipairs(moved) do
		local v = t[m[1]]
		t[m[1]] = nil
		if t[m[2]] == nil then
			t[m[2]] = v
		elseif merge then
			t[m[2]] = merge(t[m[2]], v)
		end
	end
	return CuratorOctoFull.Length(moved)
end

function G:FixNames(db)
	if type(db) ~= "table" then
		return 0
	end
	local n = RenameKeys(db.guild, Merge) + RenameKeys(db.met, Merge)
	local st = db.stats
	if type(st) == "table" then
		n = n + RenameKeys(st.seen) + RenameKeys(st.partners)
	end
	for _, list in ipairs({ db.trades, db.duels }) do
		if type(list) == "table" then
			for _, rec in pairs(list) do
				if type(rec) == "table" then
					local to = Renamed(rec.with)
					if to then
						rec.with, n = to, n + 1
					end
				end
			end
		end
	end
	local w = db.wire
	if type(w) == "table" then
		n = n + RenameKeys(w.out, Concat) + RenameKeys(w.seen, Merge)
	end
	-- (the players who said hello, on the page of the author)
	n = n + RenameKeys(db.seen, MergeSeen)
	return n
end

-- (1.13.1) WoW Forever: the names Curator 1.13.0 made with my realm after a first name alone (a friend of Battle.net, a
-- first name typed, a menu: "Brindille-ClassicBetaPvE2"), which reach nobody by whisper, made over once the game told
-- my surname: the name of the same player now, from Battle.net (bn: the name 1.13.0 gave each friend playing now, and
-- the one of now, Trade.lua) or from the number of their collection (a character of that first name: the others of the
-- same collection are other characters). Those not known yet stay as they are, for a friend of Battle.net who comes
-- later (Trade.lua, T:ScanBN): never another player of that first name, it could be someone else. Returns how many.
function G:FixRealms(db, bn)
	if type(db) ~= "table" or not self:Surnames() then
		return 0
	end
	bn = type(bn) == "table" and bn or {}
	-- (the players known under a name of now, by the number of their collection and their first name)
	local byUid = {}
	for _, t in ipairs({ db.guild, db.met }) do
		if type(t) == "table" then
			for name, m in pairs(t) do
				local uid = type(m) == "table" and type(m.i) == "table" and m.i.uid
				local first = type(name) == "string" and not self:RealmForm(name) and CuratorOctoFull.Match(name, "^([^%s%-]+)%-")
				if uid and first then
					local key = uid .. "\1" .. G.Fold(first)
					if byUid[key] == nil then
						byUid[key] = name
					elseif byUid[key] ~= name then
						byUid[key] = false
					end
				end
			end
		end
	end
	local left = false
	local function Now(name, uid)
		local first = self:RealmForm(name)
		if not first then
			return nil
		end
		local to = bn[name] or (uid ~= nil and byUid[uid .. "\1" .. G.Fold(first)]) or nil
		if not to then
			left = true
		end
		return to or nil
	end
	local function Plain(name)
		return Now(name)
	end
	local function Known(name, m)
		return Now(name, type(m) == "table" and type(m.i) == "table" and m.i.uid or nil)
	end
	local n = RenameKeys(db.guild, Merge, Known) + RenameKeys(db.met, Merge, Known)
	local st = db.stats
	if type(st) == "table" then
		n = n + RenameKeys(st.seen, nil, Plain) + RenameKeys(st.partners, nil, Plain)
	end
	for _, list in ipairs({ db.trades, db.duels }) do
		if type(list) == "table" then
			for _, rec in pairs(list) do
				if type(rec) == "table" then
					local to = Now(rec.with, rec.wuid)
					if to then
						rec.with, n = to, n + 1
					end
				end
			end
		end
	end
	local w = db.wire
	if type(w) == "table" then
		n = n + RenameKeys(w.out, Concat, Plain) + RenameKeys(w.seen, Merge, Plain)
	end
	n = n + RenameKeys(db.seen, MergeSeen, Plain)
	-- (some still to make over, when their friend of Battle.net comes)
	self.realmsLeft = left
	return n
end

-- (1.13.1) Once the game told my surname (at the login, or a little later): on WoW Forever, the friends of Battle.net
-- named again, the names of 1.13.0 with my realm made over, my own characters forgotten among the players known.
function G:Settle()
	if self.settled or not self.ready then
		return false
	end
	self:Surnames()
	if self.surnames == nil then
		-- (not known yet)
		return false
	end
	self.settled = true
	if self:Surnames() then
		local T = ns.Trade
		if T and T.ScanBN then
			T:ScanBN()
		end
		self:FixRealms(ns.db, T and T.OldBNNames and T:OldBNNames() or nil)
	end
	self:ForgetMe()
	return true
end

ns.On("LOADED", function()
	G:FixNames(ns.db)
	-- (a save loaded: what the login makes over, made over again for it)
	G.settled = nil
end)

-- (1.13.1) WoW Forever: myself, as Curator 1.13.0 kept me from my own messages (it did not know them for mine),
-- forgotten among the players known.
function G:ForgetMe()
	local me = self:Me()
	if type(me) ~= "string" or not ns.db then
		return 0
	end
	-- (and my other characters: the same collection, its number theirs, as 1.13.0 kept them from their messages)
	local low, uid, n = G.Fold(me), ns.db.uid, 0
	for _, db in ipairs({ ns.db.guild, ns.db.met }) do
		for name, m in pairs(db) do
			local theirs = type(m) == "table" and type(m.i) == "table" and m.i.uid
			if G.Fold(name) == low or (uid ~= nil and theirs == uid) then
				db[name], n = nil, n + 1
			end
		end
	end
	return n
end

ns.On("LOGIN", function()
	G.ready = true
	-- (the game may tell my surname a little later than my name: asked again every two seconds, a minute at most)
	if not G:Settle() then
		local tries = 0
		local function Again()
			tries = tries + 1
			if not G:Settle() and tries < 30 then
				ns.Delay(2, Again, G)
			end
		end
		ns.Delay(2, Again, G)
	end
	-- the players met long ago are forgotten
	local met, now = ns.db.met, CuratorOctoFull.ServerTime()
	for name, m in pairs(met) do
		if now - (m.t or 0) > 30 * 86400 then
			met[name] = nil
		end
	end
end)

-------------------------------------------------------------------------------
-- (1.14.3, his word of November 6: « Quand je regarde la collection de quelqu'un ca serait bien de voir le full
-- inventaire aussi et aussi voir les réel carte ... les usures/les caisses/les motifs des titanforged, voir aussi les
-- cartes expertiser etc etc et tout quoi! ») Another player's inventory, page by page, as their own Curator shows it to
-- them (UI/Inventory.lua): the page of a filter, an order, a rarity, an album, their duplicates only, asked by whisper.
-- Their Curator picks the lines of that page as their inventory would (IU:Remote) and sends each one as it is: a copy
-- with its wear, its pattern, its expertise, its restorations, its seal, its corruption, its signature; a card of a case
-- the same; their boosters, displays, cases and keys; how many in each filter and in each rarity. Never where a copy was
-- found, by which character, nor with whom it was traded. A page at a time: a collection of thousands of copies would
-- take minutes, a page a second or two.
--   Z:1:<mark>,<filter>,<order>,<rarity>,<album>,<duplicates>,<page>   (whisper) send me that page of your inventory
--   D:1:<mark>,<part>,<parts>,<data>                                   (whisper) the page, in parts; "<mark>,0,0,b": not
--                       now (in combat), ask again in a moment; "<mark>,0,0,n": nothing to send
-- The page, its parts put together: records separated by ";", their fields by "," (the moments in base 36):
--   h,<lines>,<page>,<S signature, L luxury case>,<filter-count. ...>,<count of each rarity, by ".">,<copies>,<appraised>,
--       <boosters>,<displays>
--   c,<card>,<its number among its copies>,<finish>,<when>,<how>,<booster No.>,<S signed, W sealed>,<appraised when>,
--       <purified when>,<at an enchanter until>,<which one>,<what goes with it in a trade: Copies.lua, CP.Pack>,
--       <came in a trade: when it came first>,<and how>
--   w,<its number>,<edition>,<rank>,<card>,<weapon>,<its line>,<finish>,<pattern>,<appraised: 1>,<grade>,<marks>,<cert>,
--       <appraised when>,<when>,<how>,<seed>,<marks veiled>,<condition 1 to 5>,<restored: Wear.lua>,<certificate of the
--       mages>,<at an enchanter until>,<which one>,<restorations>
--   i,<g golden booster, p booster, d display, x case, k key>,<album or edition>,<how many>,<displays to open>,<in their case>
-------------------------------------------------------------------------------
G.INV_WAIT = 15      -- seconds an answer is waited for (from its last part)
G.INV_WAIT_OLD = 5   -- the same, their profile saying a Curator older than 1.14.3 (it does not know the question)
G.INV_FRESH = 60     -- seconds a page that came stays as it is (asked again after)
G.INV_RETRY = 30     -- no answer: asked again after this
G.INV_BUSY = 8       -- in combat: asked again after this
G.INV_GAP = 1        -- an answer to the same player at most every second (the last page asked)
G.INV_PARTS = 24     -- the parts of a page at most
G.INV_DEBOUNCE = 0.25 -- the pages turned fast: only the one stopped on is asked
G.INV_VIEWS = 40     -- pages kept of a player
local INV_PART = 220

local INV_FILTER = { all = true, graded = true, restored = true, away = true, forged = true, certified = true, corrupt = true }
local INV_SORT = { new = true, old = true, rarity = true, grade = true, album = true }
local ITEM_CODE = { golden = "g", pack = "p", display = "d", case = "x", key = "k" }
local ITEM_OF = { g = "golden", p = "pack", d = "display", x = "case", k = "key" }
local MARKS4 = "^[1-9A][1-9A][1-9A][1-9A]$"

-- A version at least as recent as another ("1.14.3").
function G.AtLeast(ver, want)
	local a, b = {}, {}
	for n in CuratorOctoFull.Gmatch(tostring(ver or ""), "%d+") do
		a[CuratorOctoFull.Length(a) + 1] = tonumber(n)
	end
	for n in CuratorOctoFull.Gmatch(tostring(want or ""), "%d+") do
		b[CuratorOctoFull.Length(b) + 1] = tonumber(n)
	end
	for i = 1, math.max(CuratorOctoFull.Length(a), CuratorOctoFull.Length(b)) do
		local x, y = a[i] or 0, b[i] or 0
		if x ~= y then
			return x > y
		end
	end
	return true
end

-- A moment, a number, in base 36 ("": none); and back (nil: none).
local function T36(n)
	n = tonumber(n)
	return (n and n > 0) and ns.Copies.To36(n) or ""
end
local function F36(s)
	return (type(s) == "string" and s ~= "") and ns.Copies.From36(s) or nil
end

-- A whole number of the record as it goes ("": none).
local function Whole(v)
	v = tonumber(v)
	return (v and v >= 0 and v == math.floor(v) and v < 100000000) and tostring(v) or ""
end

-- A word of letters and digits as it goes ("": none or anything else).
local function Word(v)
	return type(v) == "string" and CuratorOctoFull.Length(v) <= 24 and CuratorOctoFull.Match(v, "^%w+$") or ""
end

-- A name as a page carries it: none of the marks of the messages, 24 bytes at most, no letter cut in two at its end.
local function InvName(s)
	s = (string.gsub(tostring(s or ""), "[%c|.,/;:~*@+%-%%=]", ""))
	if CuratorOctoFull.Length(s) <= 24 then
		return s
	end
	s = string.sub(s, 1, 24)
	local i = CuratorOctoFull.Length(s)
	while i > 1 and CuratorOctoFull.Byte(s, i) >= 128 and CuratorOctoFull.Byte(s, i) < 192 do
		i = i - 1
	end
	local b = CuratorOctoFull.Byte(s, i)
	local need = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
	if CuratorOctoFull.Length(s) - i + 1 < need then
		s = string.sub(s, 1, i - 1)
	end
	return s
end

-- (the enchanter a copy is at: until when, and his name)
local function AwayParts(aw)
	if type(aw) ~= "table" then
		return "", ""
	end
	local u = T36(aw.u)
	return u ~= "" and u or "0", InvName(aw.by)
end

-- A copy of the albums on a page (n: its number among the copies of its card, as its owner sees them).
local function CopyLine(x, n)
	local card, rec = x.card, x.rec
	local CP = ns.Copies
	-- (what a trade carries of it, Copies.lua: CP.Pack; never the character it came to first)
	local r = {}
	for k, v in pairs(rec) do
		r[k] = v
	end
	r.ch = nil
	r.o = type(rec.o) == "table" and { t = rec.o.t, w = rec.o.w } or nil
	local ok, pack = pcall(CP.Pack, r, card.key)
	pack = (ok and type(pack) == "string" and not string.find(pack, "[,;|]")) and pack or ""
	local f = (rec.f == "s" or rec.f == "h" or rec.f == "c") and rec.f or ""
	local how = type(rec.w) == "string" and CuratorOctoFull.Match(rec.w, "^%a$") or ""
	local marks = (rec.sg and "S" or "") .. ((rec.ws and rec.f == "c") and "W" or "")
	local until36, by = AwayParts(rec.aw)
	-- (came in a trade: where it came from first, when and how; never who had it)
	local o = type(rec.o) == "table" and rec.o or nil
	local firstHow = o and type(o.w) == "string" and CuratorOctoFull.Match(o.w, "^%a$") or ""
	return table.concat({ "c", card.key, Whole(n), f, T36(rec.t), how, T36(rec.bn), marks, T36(rec.at), T36(rec.pu), until36, by, pack,
		o and T36(o.t) or "", firstHow }, ",")
end

-- A card of a case on a page (its record as Cases.lua lets it out: CS.Public).
local function CaseLine(x, n)
	local w = x.case
	local CS, MG, W = ns.Cases, ns.Mages, ns.Wear
	local ap = w.ap and true or false
	local rw = W and W.Pack and W.Pack(w, true) or ""
	if type(rw) ~= "string" or not CuratorOctoFull.Match(rw, "^[0-9a-zA-Z%-]*$") then
		rw = ""
	end
	local tc = MG and MG.Pack(MG.Of(w)) or ""
	local until36, by = AwayParts(w.aw)
	local fin = (w.f == "thunder" or w.f == "titan") and w.f or ""
	return table.concat({ "w", Whole(n), Word(w.c), Whole(w.r), Word(w.e), Whole(w.w), Whole(w.l), fin, Whole(CS.Pattern(w)),
		ap and "1" or "", ap and Whole(w.g) or "", ap and (type(w.m) == "string" and CuratorOctoFull.Match(w.m, MARKS4) or "") or "", ap and Whole(w.ce) or "",
		ap and T36(w.at) or "", T36(w.t), (w.h == "k" or w.h == "m") and w.h or "", Whole(w.wv),
		type(w.wm) == "string" and CuratorOctoFull.Match(w.wm, MARKS4) or "", ap and "" or tostring(CS.Step(CS.Word(w))), rw, tc or "", until36, by,
		type(w.rr) == "table" and tostring(CuratorOctoFull.Length(w.rr)) or "" }, ",")
end

-- A booster, a display, a case or a key on a page (a slot of Everything: how many of it).
local function ItemLine(x)
	local where = (x.s and x.s.key) or x.ed
	if type(where) ~= "string" or not CuratorOctoFull.Match(where, "^[%w_]+$") then
		return nil
	end
	return table.concat({ "i", ITEM_CODE[x.item], where, Whole(x.of), x.item == "display" and Whole(x.open) or "",
		x.item == "display" and Whole(x.cased) or "" }, ",")
end

-- The page of my inventory asked (p: { filter, sort, rarity, series, dupes, page }), as it goes (nil: none to send).
function G:InventoryText(p)
	local IU = ns.InventoryUI
	if not (IU and IU.Remote) then
		return nil
	end
	local ok, r = pcall(IU.Remote, IU, p)
	if not (ok and type(r) == "table") then
		return nil
	end
	local TL = ns.Talents
	local flags = ((TL and TL:Has("signature")) and "S" or "") .. ((TL and TL:Has("luxury")) and "L" or "")
	local chips = {}
	for _, d in ipairs(IU.FILTERS or {}) do
		chips[CuratorOctoFull.Length(chips) + 1] = d.key .. "-" .. Whole(math.floor(tonumber(r.chips and r.chips[d.key]) or 0))
	end
	local gems = {}
	for i = 1, CuratorOctoFull.Length(ns.RARITY) do
		gems[i] = Whole(math.floor(tonumber(r.gems and r.gems[i]) or 0))
	end
	local recs = { table.concat({ "h", Whole(r.total), Whole(r.page), flags, table.concat(chips, "."), table.concat(gems, "."), Whole(r.copies),
		Whole(r.graded), Whole(r.packs), Whole(r.displays) }, ",") }
	for _, l in ipairs(r.lines or {}) do
		local x, line = l.x, nil
		if x.card and x.rec then
			line = CopyLine(x, l.n)
		elseif x.case then
			line = CaseLine(x, l.n)
		elseif x.item and ITEM_CODE[x.item] then
			line = ItemLine(x)
		end
		if line and not string.find(line, "[;|]") then
			recs[CuratorOctoFull.Length(recs) + 1] = line
		end
	end
	-- (no more than its parts allow: its last lines left out)
	local text = table.concat(recs, ";")
	while CuratorOctoFull.Length(text) > (G.INV_PARTS - 1) * INV_PART and CuratorOctoFull.Length(recs) > 1 do
		recs[CuratorOctoFull.Length(recs)] = nil
		text = table.concat(recs, ";")
	end
	return text
end

-- A text in parts of that many bytes at most, never a letter cut in two between two parts (a name in another alphabet).
local function Chunks(text, size)
	local out, i = {}, 1
	while i <= CuratorOctoFull.Length(text) do
		local j = math.min(CuratorOctoFull.Length(text), i + size - 1)
		while j < CuratorOctoFull.Length(text) and j > i and CuratorOctoFull.Byte(text, j + 1) >= 128 and CuratorOctoFull.Byte(text, j + 1) < 192 do
			j = j - 1
		end
		out[CuratorOctoFull.Length(out) + 1] = string.sub(text, i, j)
		i = j + 1
	end
	return out
end
G.Chunks = Chunks

-- A page of my inventory to a player who asked: in its parts; in combat, not now.
function G:SendInventory(target, mark, p)
	if InCombatLockdown and InCombatLockdown() then
		return self:Send(string.format(("D:%s:%s,0,0,b"), VERSION, mark), "WHISPER", target)
	end
	local text = self:InventoryText(p)
	if not text then
		return self:Send(string.format(("D:%s:%s,0,0,n"), VERSION, mark), "WHISPER", target)
	end
	local chunks = Chunks(text, INV_PART)
	local all = true
	for i, chunk in ipairs(chunks) do
		all = self:Send(string.format(("D:%s:%s,%d,%d,%s"), VERSION, mark, i, CuratorOctoFull.Length(chunks), chunk), "WHISPER", target) and all
	end
	return all
end

-- A page asked: answered at once, or a moment later when the last one to that player went less than a second ago (the
-- last page they asked then, the others left: they turned past them).
function G:ServeInventory(target, mark, p)
	self.invServe = self.invServe or {}
	local key = G.Fold(target)
	local s = self.invServe[key]
	if not s then
		s = {}
		self.invServe[key] = s
	end
	s.want = { target = target, mark = mark, p = p }
	if s.timer then
		return
	end
	local function Go()
		s.timer = nil
		local want = s.want
		s.want = nil
		if want then
			s.t = GetTime()
			G:SendInventory(want.target, want.mark, want.p)
		end
	end
	local wait = (s.t or -1000) + G.INV_GAP - GetTime()
	if wait <= 0 then
		Go()
	else
		s.timer = ns.Delay(wait, Go, G)
	end
end

G:Handle("Z", function(body, channel, sender)
	if channel ~= "WHISPER" then
		return
	end
	local f = Split(body, ",")
	local mark = f[1]
	if not (type(mark) == "string" and CuratorOctoFull.Match(mark, "^[0-9a-z]+$") and CuratorOctoFull.Length(mark) <= 8) then
		return
	end
	local rarity = Count(f[4])
	G:ServeInventory(sender, mark, {
		filter = INV_FILTER[f[2] or ""] and f[2] or "all", sort = INV_SORT[f[3] or ""] and f[3] or "new",
		rarity = (rarity and ns.RARITY[rarity]) and rarity or nil, series = (f[5] and f[5] ~= "") and ns.SeriesByKey(f[5]) or nil,
		dupes = f[6] == "1", page = math.max(1, Count(f[7]) or 1),
	})
end)

-------------------------------------------------------------------------------
-- The pages of another player, as they come
-------------------------------------------------------------------------------
-- (the numbers given to the copies of the pages: theirs, never one of mine)
local invSeq = 900000000

-- A copy of the albums of their page (nil: a card or a finish this version does not know). Its record as mine are,
-- read from what a trade carries (CP.Unpack); theirs: its number among their copies, the label of its case or of its
-- reliquary (UI/Inventory.lua, UI/Copies.lua).
local function TheirCopy(f, flags, who)
	local CP, E, MG, SL = ns.Copies, ns.Expertise, ns.Mages, ns.Masters
	local card = ns.Cards[f[2] or ""]
	local fin = f[4] or ""
	if not card or not (fin == "" or fin == "s" or fin == "h" or fin == "c") then
		return nil
	end
	local pack = f[13] or ""
	local rec = (pack ~= "" and CP.Unpack(pack)) or {}
	invSeq = invSeq + 1
	rec.i = invSeq
	rec.f = fin ~= "" and fin or nil
	rec.t = F36(f[5])
	rec.w = CuratorOctoFull.Match((f[6] or ""), "^%a$")
	rec.bn = F36(f[7])
	local marks = f[8] or ""
	rec.sg = string.find(marks, "S", 1, true) and true or nil
	rec.at = F36(f[9])
	rec.pu = F36(f[10])
	local u = f[11] ~= "" and (f[11] == "0" and 0 or F36(f[11])) or nil
	rec.aw = u and { u = u, by = (f[12] and f[12] ~= "") and f[12] or nil } or nil
	-- (where it came from first: a copy that came in a trade, or from the Exchange; never who had it)
	if rec.w == "t" or rec.w == "m" then
		local ot, ow = F36(f[14]), CuratorOctoFull.Match((f[15] or ""), "^%a$")
		if ot or ow then
			rec.o = { t = ot or 0, w = ow }
		elseif type(rec.o) == "table" then
			rec.o.ch = nil
		end
	else
		rec.o = nil
	end
	-- (a pattern on a copy not titanforged, a corruption on one not corrupted: none)
	if rec.f ~= "h" then
		rec.pt, rec.tc = nil, nil
	end
	if rec.f ~= "c" then
		rec.cor = nil
	end
	local seal = rec.f == "c" and string.find(marks, "W", 1, true) and type(rec.seal) == "table" and rec.seal or nil
	rec.seal = nil
	rec.ws = seal and true or nil
	local n = tonumber(f[3])
	local th = { n = (n and n > 0) and n or nil, who = who }
	if seal then
		th.seal = { g = seal.g, s = seal.s, c = seal.c, t = seal.t, by = seal.by, k = rec.cor }
		th.info = SL and SL.LabelOf and SL:LabelOf(card, nil, th.seal) or nil
	elseif CP.Grade(rec) and rec.sl ~= false then
		local g = CP.Grade(rec)
		local info = E and E.LabelOf and E:LabelOf(card, g / 100, E.DecodeMarks(rec.m), rec.ce, nil,
			{ by = flags.S and G:Short(who) or nil, lux = flags.L and g >= 900, titan = MG and MG.Label(rec) or nil }) or nil
		if info and type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0 then
			info.restored = {}
			for i, v in ipairs(rec.r) do
				info.restored[i] = type(v) == "table" and tonumber(v[1]) or 0
			end
		end
		th.info = info
	end
	rec.theirs = th
	return { card = card, rec = rec, theirs = true }
end

-- A card of a case of their page (nil: an edition, a card or a weapon this version does not know): its record as
-- Cases.lua lets mine out (CS.Public), the weapons of legend as the list has them.
local function TheirCase(f)
	local CS, CR, CM = ns.Cases, ns.CrateUI, ns.CaseCards
	local case = f[3]
	if not (CS and CR and CM and CS:Known(case)) then
		return nil
	end
	invSeq = invSeq + 1
	local w = { i = invSeq, c = case }
	local weapon = (f[6] and f[6] ~= "") and CR.WeaponOf and CR.WeaponOf(f[6]) or nil
	if weapon then
		w.w, w.r, w.cl, w.fa, w.l = weapon.id, CR.TOP, weapon.class, weapon.faction, tonumber(f[7])
	else
		local e, r = CM.Entry(case, f[5])
		if not e then
			return nil
		end
		w.e, w.r = e.key, r
	end
	w.f = (f[8] == "thunder" or f[8] == "titan") and f[8] or nil
	w.pt = w.f == "titan" and tonumber(f[9]) or nil
	local g = tonumber(f[11])
	if f[10] == "1" and g and g >= 1 and g <= 10 and g == math.floor(g) then
		w.ap, w.g = true, g
		w.m = CuratorOctoFull.Match((f[12] or ""), MARKS4)
		w.ce = tonumber(f[13])
		w.at = F36(f[14])
	end
	w.t = F36(f[15])
	w.h = (f[16] == "k" or f[16] == "m") and f[16] or nil
	local wv = tonumber(f[17])
	if wv and wv >= 1 and wv <= 999998 then
		w.wv = wv
		w.wm = CuratorOctoFull.Match((f[18] or ""), MARKS4)
	end
	if not w.ap then
		local step = tonumber(f[19])
		w.cw = CS.CONDITION[(step and step >= 1 and step <= CuratorOctoFull.Length(CS.CONDITION)) and step or CuratorOctoFull.Length(CS.CONDITION)][2]
	end
	local rw = (f[20] and f[20] ~= "") and ns.Wear and ns.Wear.Unpack(f[20], true) or nil
	if rw then
		w.w0, w.wx, w.wa = rw.w0, rw.wx, rw.wa
	end
	local tc = (f[21] and f[21] ~= "") and ns.Mages and ns.Mages.Unpack(f[21]) or nil
	if tc and w.f == "titan" then
		w.tc = tc
	end
	local u = (f[22] and f[22] ~= "") and (f[22] == "0" and 0 or F36(f[22])) or nil
	if u then
		w.aw = { u = u, by = (f[23] and f[23] ~= "") and f[23] or nil }
	end
	local rr = tonumber(f[24])
	if rr and rr > 0 then
		w.rr = {}
		for k = 1, math.min(rr, 50) do
			w.rr[k] = { 0, 1, 0 }
		end
	end
	local n = tonumber(f[2])
	return { case = w, theirs = true, n = (n and n > 0) and n or nil, t = w.t, i = w.i }
end

-- A booster, a display, a case or a key of their page (nil: an album or an edition this version does not know).
local function TheirItem(f)
	local kind = ITEM_OF[f[2] or ""]
	local of = tonumber(f[4])
	if not (kind and of and of >= 1 and of < 10000000) then
		return nil
	end
	local x = { item = kind, n = 1, of = of, stack = true, theirs = true }
	if kind == "case" or kind == "key" then
		if not (ns.Cases and ns.Cases:Known(f[3])) then
			return nil
		end
		x.ed = f[3]
	else
		x.s = ns.SeriesByKey(f[3] or "")
		if not x.s then
			return nil
		end
		if kind == "display" then
			x.open, x.cased = tonumber(f[5]) or 0, tonumber(f[6]) or 0
		end
	end
	return x
end

-- Their page, its parts put together (nil: it does not read): { lines, total, page, chips, gems, copies, graded,
-- packs, displays }.
local function TheirPage(text, who)
	local recs = Split(text, ";")
	local h = Split(recs[1] or "", ",")
	if h[1] ~= "h" then
		return nil
	end
	local fl = h[4] or ""
	local flags = { S = string.find(fl, "S", 1, true) ~= nil, L = string.find(fl, "L", 1, true) ~= nil }
	local v = { lines = {}, total = Count(h[2]) or 0, page = math.max(1, Count(h[3]) or 1), chips = {}, gems = {}, copies = Count(h[7]) or 0,
		graded = Count(h[8]) or 0, packs = Count(h[9]) or 0, displays = Count(h[10]) or 0 }
	for k, n in CuratorOctoFull.Gmatch((h[5] or ""), "(%a+)%-(%d+)") do
		v.chips[k] = Count(n)
	end
	local r = 0
	for n in CuratorOctoFull.Gmatch((h[6] or ""), "%d+") do
		r = r + 1
		v.gems[r] = Count(n) or 0
	end
	for i = 2, CuratorOctoFull.Length(recs) do
		local f = Split(recs[i], ",")
		local ok, x = false, nil
		if f[1] == "c" then
			ok, x = pcall(TheirCopy, f, flags, who)
		elseif f[1] == "w" then
			ok, x = pcall(TheirCase, f)
		elseif f[1] == "i" then
			ok, x = pcall(TheirItem, f)
		end
		if ok and x then
			v.lines[CuratorOctoFull.Length(v.lines) + 1] = x
		end
	end
	return v
end

-- Their page came whole (text: its parts put together; nil: it did not read): kept for its choices, shown.
local function Came(sender, inv, ask, text)
	inv.ask = nil
	local ok, v = false, nil
	if text then
		ok, v = pcall(TheirPage, text, sender)
	end
	if ok and v then
		v.t = GetTime()
		inv.count = inv.count + 1
		if inv.count > G.INV_VIEWS then
			inv.views, inv.count = {}, 1
		end
		inv.views[ask.key] = v
		inv.last = v
		inv.state, inv.failT, inv.busyT = nil, nil, nil
	else
		inv.failT, inv.state = GetTime(), "silent"
	end
	ns.Fire("INVENTORY", sender)
end

-- What is known of a player's inventory: { views = { [choices] = their page }, last, ask, state, failT, busyT }.
function G:Inv(name)
	self.inv = self.inv or {}
	local k = G.Fold(name)
	local inv = self.inv[k]
	if not inv then
		inv = { views = {}, count = 0 }
		self.inv[k] = inv
	end
	return inv
end

local function ViewKey(p)
	return table.concat({ p.filter or "all", p.sort or "new", p.rarity or "", p.series and p.series.key or "", p.dupes and "1" or "",
		p.page or 1 }, "/")
end

-- A page of a player's inventory asked of them (the pages turned fast: only the last one, a moment after).
function G:AskInventory(name, p, key)
	local inv = self:Inv(name)
	local ask = { key = key, t = GetTime() }
	inv.ask = ask
	local function Check()
		if inv.ask ~= ask then
			return
		end
		-- (a Curator older than 1.14.3, as their profile says: it does not know the question, a few seconds are enough)
		local i = G:Profile(name)
		local old = type(i) == "table" and i.ver ~= nil and not G.AtLeast(i.ver, "1.14.3")
		local left = (old and G.INV_WAIT_OLD or G.INV_WAIT) - (GetTime() - ask.t)
		if left > 0.01 then
			ns.Delay(left, Check, G)
			return
		end
		inv.ask, inv.failT = nil, GetTime()
		inv.state = old and "old" or "silent"
		ns.Fire("INVENTORY", name)
	end
	ns.Delay(G.INV_DEBOUNCE, function()
		if inv.ask ~= ask then
			return
		end
		G.invMark = (G.invMark or 0) + 1
		ask.mark = ns.Copies.To36(G.invMark) .. ns.Copies.To36(math.random(0, 1295))
		ask.t = GetTime()
		-- (the author's test, /curator test inventaire: my own inventory as another player sees it, each page made as it
		-- goes to them and read back as it comes to them; nothing sent)
		if G:IsMe(name) then
			return Came(name, inv, ask, G:InventoryText(p))
		end
		local msg = string.format(("Z:%s:%s,%s,%s,%s,%s,%s,%d"), VERSION, ask.mark, p.filter or "all", p.sort or "new", p.rarity or "",
			p.series and p.series.key or "", p.dupes and "1" or "", p.page or 1)
		G:Send(msg, "WHISPER", name)
		ns.Delay(G.INV_WAIT_OLD, Check, G)
	end, G)
end

-- (UI/Inventory.lua) A page of another player's inventory, for these choices: { state, view, last }. The state: "ok"
-- (the page is there: view), "wait" (asked), "busy" (in combat: asked again in a moment), "silent" (no answer), "old"
-- (their Curator is older than 1.14.3); last: the page that came last (its counts while the next one comes). A page
-- missing, or there for a minute, is asked (again).
function G:InventoryView(name, p)
	local inv = self:Inv(name)
	local key = ViewKey(p)
	local v = inv.views[key]
	local now = GetTime()
	local asking = inv.ask ~= nil and inv.ask.key == key
	local busy = inv.busyT ~= nil and now - inv.busyT < G.INV_BUSY
	local failed = inv.failT ~= nil and now - inv.failT < G.INV_RETRY
	if not asking and not busy and not failed and (not v or now - v.t >= G.INV_FRESH) then
		self:AskInventory(name, p, key)
		asking = true
	end
	local state = (v and "ok") or (asking and "wait") or (busy and "busy") or inv.state or "silent"
	return { state = state, view = v, last = inv.last }
end

G:Handle("D", function(body, channel, sender)
	if channel ~= "WHISPER" then
		return
	end
	local mark, i, n, data = CuratorOctoFull.Match(body, "^([0-9a-z]+),(%d+),(%d+),(.*)$")
	i, n = tonumber(i), tonumber(n)
	local inv = mark and G.inv and G.inv[G.Fold(sender)]
	local ask = inv and inv.ask
	if not (ask and ask.mark == mark and i and n) then
		return
	end
	if n == 0 then
		-- (not now: in combat, asked again in a moment; nothing to send)
		inv.ask = nil
		if data == "b" then
			inv.busyT = GetTime()
		else
			inv.failT, inv.state = GetTime(), "silent"
		end
		ns.Fire("INVENTORY", sender)
		return
	end
	if i < 1 or i > n or n > G.INV_PARTS then
		return
	end
	if ask.n ~= n then
		ask.n, ask.got = n, {}
	end
	ask.got[i] = data
	ask.t = GetTime()
	for k = 1, n do
		if not ask.got[k] then
			return
		end
	end
	Came(sender, inv, ask, table.concat(ask.got))
end)
