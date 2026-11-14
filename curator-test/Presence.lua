local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- The players with Curator, known by its author (the README says what he sees). A copy joins a channel
-- of the game, hidden (no chat window shows it, nor its notices), says once there that it is there,
-- and answers by whisper whoever calls the roll there; /curator presence turns that off (it is then not
-- on that channel and answers nothing), and on again. A player who said no in the beta (0.23.1, when
-- each was asked) stays off. Messages:
--   L:1:<version>,<level of the character>,<class>    I am here (on the channel, at the login; by
--                       whisper to a roll call, followed by the profile)
--   L:1:off                                           I no longer share: forget me (on the channel)
--   Y:1                                               who is there? (on the channel)
-------------------------------------------------------------------------------
local P = {
	CHANNEL = "CuratorNet",
	JOIN_DELAY = 15,      -- seconds after the login: the channels of the game take their numbers first
	ANSWER_COOLDOWN = 60, -- a roll caller is answered once a minute at most
	CALL_COOLDOWN = 30,   -- a roll called once every half a minute at most
}
ns.Presence = P

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Upper(s)
	return type(s) == "string" and not Secret(s) and string.upper(s) or nil
end

-- The player shares (unless turned off; never the copy of the author, who has no one to tell).
function P:Shares()
	return ns.db ~= nil and ns.db.presence ~= false and not ns.Admin
end

-- On the channel: a player who shares, and the copy of the author (it calls the roll).
function P:Listens()
	return self:Shares() or ns.Admin ~= nil
end

-- The number of the channel (nil: not on it).
function P:Index()
	if not GetChannelName then
		return nil
	end
	local ok, id = pcall(GetChannelName, self.CHANNEL)
	if ok and type(id) == "number" and not Secret(id) and id > 0 then
		return id
	end
	return nil
end

-- A message of a channel: ours, by its number or its name ("5. CuratorNet" or "CuratorNet").
function P:Ours(localID, name)
	local id = self:Index()
	if id and type(localID) == "number" and not Secret(localID) and localID == id then
		return true
	end
	local up = Upper(name)
	return up ~= nil and (CuratorOctoFull.Match(up, "^%d+%.%s*(.+)$") or up) == string.upper(self.CHANNEL)
end

-- No chat window shows the channel: it was not given to one, and is taken out of any that has it.
local function HideFromWindows()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local cf = _G["ChatFrame" .. i]
		if cf and type(cf.channelList) == "table" then
			for _, v in pairs(cf.channelList) do
				if Upper(v) == string.upper(P.CHANNEL) then
					local remove = cf.RemoveChannel or ChatFrame_RemoveChannel
					if remove then
						pcall(remove, cf, P.CHANNEL)
					end
					break
				end
			end
		end
	end
end

-- Nor its notices (joined, left, someone typing in it).
local function Filter(_, _, _, _, _, channelString, _, _, _, _, channelName)
	if Upper(channelName) == string.upper(P.CHANNEL) then
		return true
	end
	local up = Upper(channelString)
	return up ~= nil and CuratorOctoFull.Match(up, "^%d+%.%s*(.+)$") == string.upper(P.CHANNEL)
end

function P:Line()
	local level, class = 0, "-"
	if UnitLevel then
		local ok, l = pcall(UnitLevel, "player")
		level = (ok and type(l) == "number" and not Secret(l)) and l or 0
	end
	if UnitClass then
		local ok, _, file = pcall(UnitClass, "player")
		class = (ok and type(file) == "string" and not Secret(file) and CuratorOctoFull.Match(file, "^%u+$")) or "-"
	end
	return string.format(("L:1:%s,%d,%s"), ns.version or "-", level, class)
end

function P:Join()
	if not self:Listens() then
		return false
	end
	if not self:Index() then
		local join = JoinTemporaryChannel or JoinChannelByName
		if not join then
			return false
		end
		pcall(join, self.CHANNEL)
	end
	-- (on it a moment later: then hidden, and the hello of a player who said yes)
	ns.Delay(3, function()
		P:Joined()
	end, P)
	return true
end

function P:Joined()
	local id = self:Index()
	if not id then
		return
	end
	HideFromWindows()
	if self:Shares() and not self.said then
		self.said = ns.Guild:Send(self:Line(), "CHANNEL", tostring(id)) and true or nil
	end
end

function P:Leave()
	if self:Index() and LeaveChannelByName then
		pcall(LeaveChannelByName, self.CHANNEL)
	end
	self.said = nil
end

-- Shared (on the channel) or not (off it, and the author told to forget them).
function P:Set(on)
	local was = self:Shares()
	ns.db.presence = on and true or false
	if on then
		self:Join()
	else
		local id = self:Index()
		if was and id then
			ns.Guild:Send("L:1:off", "CHANNEL", tostring(id))
		end
		-- (off the channel once that is said)
		ns.Delay(2, function()
			if not P:Listens() then
				P:Leave()
			end
		end, P)
	end
	ns.Print(on and L["Your presence is shared with the author of Curator (/curator presence to stop)."]
		or L["Your presence is not shared with the author of Curator (/curator presence to share it)."])
end

function P:Toggle()
	self:Set(not self:Shares())
end

-- Who is there: every copy of a player who shares answers by whisper (its hello and its profile).
function P:Call()
	local id = self:Index()
	local now = GetTime()
	if not id or (self.called and now - self.called < self.CALL_COOLDOWN) then
		return false
	end
	self.called = now
	return ns.Guild:Send("Y:1", "CHANNEL", tostring(id))
end

-- Read from the messages (Comm.lua): a roll call on the channel, a hello (on the channel or by
-- whisper).
function P:OnMessage(kind, body, channel, sender)
	if kind == "Y" and channel == "CHANNEL" then
		if not self:Shares() then
			return
		end
		self.answered = self.answered or {}
		local now = GetTime()
		local last = self.answered[sender]
		if last and now - last < self.ANSWER_COOLDOWN then
			return
		end
		self.answered[sender] = now
		-- (a little later: not every copy at the same moment)
		ns.Delay(0.5 + math.random() * 4, function()
			if P:Shares() then
				ns.Guild:Send(P:Line(), "WHISPER", sender)
				ns.Guild:Send(ns.Guild:ProfileMessage(), "WHISPER", sender)
			end
		end, P)
	elseif kind == "L" and body == "off" then
		ns.Fire("PRESENCE", sender, { off = true, t = CuratorOctoFull.ServerTime(), via = channel })
	elseif kind == "L" then
		local ver, level, class = CuratorOctoFull.Match((body or ""), "^([^,]*),([^,]*),([^,]*)$")
		if not ver then
			return
		end
		ns.Fire("PRESENCE", sender, {
			ver = (CuratorOctoFull.Length(ver) <= 12 and CuratorOctoFull.Match(ver, "^%d+%.%d+%.?%d*$")) and ver or nil,
			level = ns.Guild.Count(level),
			class = (CuratorOctoFull.Length(class) <= 12 and CuratorOctoFull.Match(class, "^%u+$")) and class or nil,
			t = CuratorOctoFull.ServerTime(),
			via = channel,
		})
	end
end

ns.On("LOGIN", function()
	local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
	if add then
		for _, e in ipairs({ "CHAT_MSG_CHANNEL_NOTICE", "CHAT_MSG_CHANNEL_NOTICE_USER", "CHAT_MSG_CHANNEL_JOIN", "CHAT_MSG_CHANNEL_LEAVE",
			"CHAT_MSG_CHANNEL" }) do
			pcall(add, e, Filter)
		end
	end
	if P:Listens() then
		ns.Delay(P.JOIN_DELAY, function()
			P:Join()
		end, P)
	end
end)
