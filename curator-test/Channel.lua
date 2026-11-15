local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.12.1) The chat channel of the collectors: one for each faction, as the channels of the game are, CuratorHorde
-- and CuratorAlliance, joined at the login (off in the options, or by leaving it as any channel). The chat shows it
-- as "Curator [Horde]", and beside the name of each player who speaks there, the emblem of their rank and their
-- collector level. The level of a collector: said on the channel by each copy once there and when it changes; a
-- player not known yet who speaks there is asked by whisper. /curator chat opens the chat on it. Messages:
--   B:1:<level>       my collector level (on the channel; by whisper, the answer)
--   B:1:?             (whisper) what is your collector level?
-- (A custom channel of the game belongs to the first player in it, who may moderate it: nothing of the
-- collection goes through it, only the level and what the players write there.)
-- (1.14.3, his word of November 6: « il faut que les noms ne comportent pas "alliance" ni "horde", pas d'espace, pas de
-- crochet ... j'ai test avec Curatoralli ça marche »; then: « il faut des nom "curatoralli" et "curatorhord" donc
-- retirer les autres channel si possible ») The realms refuse what is said on a channel whose name holds the name of a
-- faction: the channels are curatoralli and curatorhord now, still shown "Curator [Alliance]" and "Curator [Horde]" by
-- the chat; those of before left by themselves at the login, and taken out of the chat windows (CH:LeaveOld).
-------------------------------------------------------------------------------
local CH = {
	NAMES = { Horde = "curatorhord", Alliance = "curatoralli" },
	-- (the names of before 1.14.3, which the realms refuse)
	OLD = { "CuratorHorde", "CuratorAlliance" },
	JOIN_DELAY = 20,     -- seconds after the login: the channels of the game and the hidden one of the presence first
	SAY_COOLDOWN = 60,   -- my level said on the channel once a minute at most
	ASK_EVERY = 3,       -- one question by whisper every 3 seconds at most
	ASK_AGAIN = 600,     -- a player asked is not asked again within 10 minutes
	ANSWER_COOLDOWN = 60, -- an asker answered once a minute at most
	-- (1.13.1) The characters of the author of Curator, by their GUID (the game gives it with each line of a
	-- channel, and no other player can take it): [ADMIN] before what they say there.
	AUTHOR = {
		["Player-4620-00DFCE57"] = true,
	},
	ADMIN_TAG = "|cffff8000[ADMIN]|r ",
}
ns.Channel = CH

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Upper(s)
	return type(s) == "string" and not Secret(s) and string.upper(s) or nil
end

-- The players by their name, whatever its case and whether its realm is written.
local function Key(name)
	if type(name) ~= "string" or name == "" or Secret(name) then
		return nil
	end
	local G = ns.Guild
	local full = G and G:Full(name) or name
	return G and G.Fold and G.Fold(full) or string.lower(full)
end

-------------------------------------------------------------------------------
-- The channel
-------------------------------------------------------------------------------
-- The faction of the character (nil: none yet), and its name in the language of the game.
function CH:Faction()
	if not UnitFactionGroup then
		return nil
	end
	local ok, faction, shown = pcall(UnitFactionGroup, "player")
	if not ok or Secret(faction) or not self.NAMES[faction or ""] then
		return nil
	end
	return faction, (type(shown) == "string" and not Secret(shown) and shown ~= "") and shown or faction
end

-- The name of the channel of my faction (nil: no faction).
function CH:Name()
	local faction = self:Faction()
	return faction and self.NAMES[faction] or nil
end

-- On it (unless turned off in the options).
function CH:Wanted()
	return ns.db ~= nil and ns.db.chat ~= false and self:Name() ~= nil
end

-- Its number (nil: not on it). (1.14.3: the realm may keep its name in another case, "Curatoralli" when a player made it
-- so: then found in the list of the channels.)
function CH:Index()
	local name = self:Name()
	if not name then
		return nil
	end
	if GetChannelName then
		local ok, id = pcall(GetChannelName, name)
		if ok and type(id) == "number" and not Secret(id) and id > 0 then
			return id
		end
	end
	if GetChannelList then
		local ok, list = pcall(function()
			return { GetChannelList() }
		end)
		if ok and type(list) == "table" then
			local up = string.upper(name)
			for i = 1, CuratorOctoFull.Length(list) - 1 do
				local id, n = list[i], list[i + 1]
				if type(id) == "number" and not Secret(id) and id > 0 and Upper(n) == up then
					return id
				end
			end
		end
	end
	return nil
end

-- A name of a channel, as the chat gives it ("5. curatorhord" or "curatorhord"), in capitals and without its number
-- (nil: none).
local function Bare(name)
	local up = Upper(name)
	if not up or up == "" then
		return nil
	end
	return CuratorOctoFull.Match(up, "^%d+%.%s*(.+)$") or up
end

-- (1.14.3) One of the channels of before (CuratorHorde, CuratorAlliance).
function CH:Old(name)
	local up = Bare(name)
	if not up then
		return false
	end
	for _, n in ipairs(self.OLD) do
		if up == string.upper(n) then
			return true
		end
	end
	return false
end

-- A channel of the collectors (by its name: "5. curatorhord" or "curatorhord", mine or the other one; without a name, by
-- its number). (1.14.3: its name first: the number of a channel of before, left, may be given to the new one at once.)
function CH:Ours(localID, name)
	local up = Bare(name)
	if up then
		for _, n in pairs(self.NAMES) do
			if up == string.upper(n) then
				return true
			end
		end
		return false
	end
	local id = self:Index()
	return (id and type(localID) == "number" and not Secret(localID) and localID == id) and true or false
end

-- "Curator [Horde]", as the chat shows it.
function CH:Shown()
	local _, shown = self:Faction()
	return string.format(("Curator [%s]"), shown or "?")
end

-- Joined (a moment later: said there, given to the chat window, told once).
function CH:Join()
	if not self:Wanted() then
		return false
	end
	if not self:Index() then
		local join = JoinTemporaryChannel or JoinChannelByName
		if not join then
			return false
		end
		-- (in the first chat window, as a channel joined by hand)
		pcall(join, self:Name(), nil, DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.GetID and DEFAULT_CHAT_FRAME:GetID() or 1)
	end
	ns.Delay(3, function()
		CH:Joined()
	end, CH)
	return true
end

-- In the chat window that shows the channels joined (the first one), as a channel joined by hand.
local function Show(name)
	local cf = DEFAULT_CHAT_FRAME or _G.ChatFrame1
	if not (cf and type(cf.channelList) == "table") then
		return
	end
	for _, v in pairs(cf.channelList) do
		if Upper(v) == string.upper(name) then
			return
		end
	end
	local add = cf.AddChannel or ChatFrame_AddChannel
	if add then
		pcall(add, cf, name)
	end
end

function CH:Joined()
	local id = self:Index()
	if not id then
		-- (1.14.3, after his test: not on it yet: asked again twice, a moment apart; then said how to join it by hand)
		self.tries = (self.tries or 0) + 1
		if self.tries <= 2 then
			ns.Delay(8, function()
				CH:Join()
			end, CH)
		elseif self.tries == 3 and self:Wanted() then
			ns.Print(L["The chat channel of the collectors could not be joined: /join %s joins it by hand."], self:Name())
		end
		return
	end
	self.tries = nil
	Show(self:Name())
	self:Say(true)
	local db = ns.db
	-- (1.14.3: told once again, its name and its number new)
	if db and db.chatTold ~= 2 then
		db.chatTold = 2
		ns.Print(L["You are on the chat channel of the collectors of your faction, %s: /%d to talk there, /curator chat too (off in the options)."], self:Shown(), id)
	end
end

function CH:Leave()
	if self:Index() and LeaveChannelByName then
		self.leaving = GetTime()
		pcall(LeaveChannelByName, self:Name())
	end
end

-- (1.14.3) The channels of before (CuratorHorde, CuratorAlliance: nothing could be said there) left, and taken out of the
-- chat windows that showed them. How many were left.
function CH:LeaveOld()
	local n = 0
	for _, name in ipairs(self.OLD) do
		local ok, id = false, nil
		if GetChannelName then
			ok, id = pcall(GetChannelName, name)
		end
		if ok and type(id) == "number" and not Secret(id) and id > 0 and LeaveChannelByName then
			pcall(LeaveChannelByName, name)
			n = n + 1
		end
		for i = 1, (NUM_CHAT_WINDOWS or 10) do
			local cf = _G["ChatFrame" .. i]
			if cf and type(cf.channelList) == "table" then
				for _, v in pairs(cf.channelList) do
					if Upper(v) == string.upper(name) then
						local remove = cf.RemoveChannel or ChatFrame_RemoveChannel
						if remove then
							pcall(remove, cf, name)
						end
						break
					end
				end
			end
		end
	end
	return n
end

-- On it or not (the options).
function CH:Set(on)
	if not ns.db then
		return
	end
	if on then
		ns.db.chat = nil
		self:Join()
	else
		ns.db.chat = false
		self:Leave()
	end
end

-------------------------------------------------------------------------------
-- The levels of the collectors
-------------------------------------------------------------------------------
CH.levels = {}

-- My collector level, said on the channel (now: at once, else within SAY_COOLDOWN of the last time).
function CH:Say(now)
	local id = self:Index()
	if not (id and ns.Level and ns.Guild) then
		return false
	end
	local t = GetTime()
	if not now and self.saidAt and t - self.saidAt < self.SAY_COOLDOWN then
		if not self.sayLater then
			self.sayLater = true
			ns.Delay(self.SAY_COOLDOWN - (t - self.saidAt) + 0.5, function()
				CH.sayLater = nil
				CH:Say(true)
			end, CH)
		end
		return false
	end
	self.saidAt = t
	return ns.Guild:Send(string.format(("B:1:%d"), ns.Level:Level()), "CHANNEL", tostring(id)) and true or false
end

-- The collector level of a player (nil: not known): said, or known from their profile (the guild, the players met).
function CH:Level(name)
	local key = Key(name)
	if not key then
		return nil
	end
	local G = ns.Guild
	if G and (Key(G:Me()) == key) and ns.Level then
		return ns.Level:Level()
	end
	local lv = self.levels[key]
	if lv then
		return lv
	end
	local m = G and (G:Player(G:Full(name)) or G:Player(name))
	local xp = m and m.i and tonumber(m.i.xp)
	if xp and ns.Level and ns.Level.Of then
		return (ns.Level.Of(xp))
	end
	return nil
end

-- Read from the messages (Comm.lua): a level said on the channel or by whisper, a question by whisper.
function CH:OnMessage(body, channel, sender)
	local key = Key(sender)
	if not key then
		return
	end
	if body == "?" then
		if channel ~= "WHISPER" or not self:Index() then
			return
		end
		self.answered = self.answered or {}
		local t = GetTime()
		if self.answered[key] and t - self.answered[key] < self.ANSWER_COOLDOWN then
			return
		end
		self.answered[key] = t
		if ns.Level and ns.Guild then
			ns.Guild:Send(string.format(("B:1:%d"), ns.Level:Level()), "WHISPER", sender)
		end
		return
	end
	local lv = ns.Guild and ns.Guild.Count(body)
	if lv and lv >= 1 and lv <= ((ns.Level and ns.Level.MAX) or 100) then
		self.levels[key] = lv
	end
end

-- A player not known yet who speaks on the channel: asked by whisper, one question every ASK_EVERY seconds.
function CH:Ask(name)
	local key = Key(name)
	if not key or self:Level(name) then
		return
	end
	self.asked = self.asked or {}
	local t = GetTime()
	if self.asked[key] and t - self.asked[key] < self.ASK_AGAIN then
		return
	end
	self.asked[key] = t
	self.toAsk = self.toAsk or {}
	if CuratorOctoFull.Length(self.toAsk) >= 20 then
		return
	end
	self.toAsk[CuratorOctoFull.Length(self.toAsk) + 1] = name
	self:AskNext()
end

function CH:AskNext()
	if self.askBusy then
		return
	end
	local name = self.toAsk and CuratorOctoFull.Remove(self.toAsk, 1)
	if not name then
		return
	end
	self.askBusy = true
	if not self:Level(name) and ns.Guild then
		ns.Guild:Send("B:1:?", "WHISPER", name)
	end
	ns.Delay(self.ASK_EVERY, function()
		CH.askBusy = nil
		CH:AskNext()
	end, CH)
end

-- "<emblem> Coll. 23  ", in the colour of the rank (nil: the level not known).
function CH:Badge(name)
	local lv = self:Level(name)
	local LV = ns.Level
	if not (lv and LV and LV.RankOf) then
		return nil
	end
	local r, rank = LV.RankOf(lv)
	local c = rank and rank.color or { 1, 0.82, 0 }
	local emblem = LV.EmblemText and LV.EmblemText(r, 0) or ""
	return string.format(("%s|cff%02x%02x%02x%s|r  "), emblem ~= "" and (emblem .. " ") or "", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5),
		math.floor(c[3] * 255 + 0.5), string.format(L["Coll. %d"], lv))
end

-------------------------------------------------------------------------------
-- The chat
-------------------------------------------------------------------------------
-- A line of the channel: its name "Curator [Horde]", the emblem and the level of the one who speaks before what
-- they say (asked of a player not known yet). (A character banned from Curator, Bans.lua: its lines hidden.)
-- (1.13.1) A character of the author of Curator, by its GUID.
function CH:Admin(guid)
	return type(guid) == "string" and not Secret(guid) and self.AUTHOR[guid] == true
end

local function Decorate(_, _, msg, author, language, channelString, target, flags, zoneID, localID, channelName, ...)
	if Secret(msg) or Secret(author) or Secret(channelString) or Secret(channelName) or type(msg) ~= "string" then
		return false
	end
	if not CH:Ours(localID, channelName or channelString) then
		return false
	end
	if type(author) == "string" and ns.Bans and ns.Bans:Sender(author) then
		return true
	end
	local num = type(channelString) == "string" and CuratorOctoFull.Match(channelString, "^(%d+)%.") or (type(localID) == "number" and tostring(localID))
	local shown = (num and (num .. ". ") or "") .. CH:Shown()
	local badge = CH:Badge(author)
	if badge then
		msg = badge .. msg
	elseif type(author) == "string" and author ~= "" then
		CH:Ask(author)
	end
	-- (1.13.1: the author of Curator, [ADMIN] first; the GUID of who wrote it, the twelfth argument of the event)
	if CH:Admin((CuratorOctoFull.Select(3, unpack(arg, 1, arg.n)))) then
		msg = CH.ADMIN_TAG .. msg
	end
	return false, msg, author, language, shown, target, flags, zoneID, localID, channelName, unpack(arg, 1, arg.n)
end
CH.Decorate = Decorate

-- The notices of the channel (joined, left, its owner): its name as the chat shows it; those of the players
-- who come and go: hidden.
local function Notice(_, _, msg, author, language, channelString, target, flags, zoneID, localID, channelName, ...)
	if Secret(channelString) or Secret(channelName) then
		return false
	end
	if not CH:Ours(localID, channelName or channelString) then
		return false
	end
	local num = type(channelString) == "string" and CuratorOctoFull.Match(channelString, "^(%d+)%.") or (type(localID) == "number" and tostring(localID))
	return false, msg, author, language, (num and (num .. ". ") or "") .. CH:Shown(), target, flags, zoneID, localID, channelName, unpack(arg, 1, arg.n)
end
CH.Notice = Notice

local function Comings(_, _, _, _, _, channelString, _, _, _, localID, channelName)
	if Secret(channelString) or Secret(channelName) then
		return false
	end
	return CH:Ours(localID, channelName or channelString)
end
CH.Comings = Comings

-- The chat on the channel: "/5 " typed for you, or a message said there at once.
function CH:Open(text)
	local id = self:Index()
	if not id then
		if not self:Wanted() then
			ns.Print(L["The chat channel of the collectors is off: the options of Curator turn it on."])
		else
			ns.Print(L["Not on the chat channel of the collectors yet: a moment."])
			self:Join()
		end
		return false
	end
	if type(text) == "string" and CuratorOctoFull.Match(text, "%S") then
		-- (the newer clients: the number of the channel as a text; the older ones, as a number)
		if CuratorOctoFull.Chat and CuratorOctoFull.Chat.SendChatMessage then
			pcall(CuratorOctoFull.Chat.SendChatMessage, text, "CHANNEL", nil, tostring(id))
		elseif SendChatMessage then
			pcall(SendChatMessage, text, "CHANNEL", nil, id)
		end
		return true
	end
	local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
	if open then
		open("/" .. id .. " ")
	end
	return true
end

ns.On("LOGIN", function()
	local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
	-- (once: a filter given twice would put the level twice on a line)
	if add and not CH.filtered then
		CH.filtered = true
		pcall(add, "CHAT_MSG_CHANNEL", Decorate)
		pcall(add, "CHAT_MSG_CHANNEL_NOTICE", Notice)
		pcall(add, "CHAT_MSG_CHANNEL_NOTICE_USER", Notice)
		pcall(add, "CHAT_MSG_CHANNEL_JOIN", Comings)
		pcall(add, "CHAT_MSG_CHANNEL_LEAVE", Comings)
	end
	-- (1.14.3, his word of November 6 after his test: « les channel ça ne me fait [pas] connecter automatiquement au channel
	-- curatoralli et curatorhord ») Nothing could be said on the channels of before: whoever left one, or turned it off,
	-- is on the new one once all the same (left again, or turned off again: off, the options take him back).
	local db = ns.db
	if db and db.chatAgain ~= 1 then
		db.chatAgain = 1
		if db.chat == false then
			db.chat = nil
		end
	end
	CH.tries = nil
	-- (1.14.3: the channels of before left first, whether this one is wanted or not)
	ns.Delay(CH.JOIN_DELAY, function()
		CH:LeaveOld()
		if CH:Wanted() then
			CH:Join()
		end
	end, CH)
end)

-- (by whisper: the questions and the answers; on the channel, Comm.lua gives them)
if ns.Guild and ns.Guild.Handle then
	ns.Guild:Handle("B", function(body, channel, sender)
		CH:OnMessage(body, channel, sender)
	end)
end

-- My level up: said on the channel.
ns.On("LEVEL_UP", function()
	CH:Say(false)
end)

-- Left by hand (/leave): not joined again (the options take you back).
local ev = CreateFrame("Frame")
ev:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
CuratorOctoFull.SetScript(ev, "OnEvent", function(_, _, kind, _, _, channelString, _, _, _, localID, channelName)
	if Secret(kind) or kind ~= "YOU_LEFT" then
		return
	end
	-- (1.14.3: a channel of before, left by Curator itself at the login: nothing to say, the new one stays wanted)
	if CH:Old(channelName) or CH:Old(channelString) then
		return
	end
	if not CH:Ours(localID, (Bare(channelName) and channelName) or channelString) then
		return
	end
	if CH.leaving and GetTime() - CH.leaving < 10 then
		CH.leaving = nil
		return
	end
	if ns.db and ns.db.chat ~= false then
		ns.db.chat = false
		ns.Print(L["You left the chat channel of the collectors: the options of Curator take you back."])
	end
end)
