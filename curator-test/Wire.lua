local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.12.0) The wire: the messages between two collections that must arrive (the trades, the duels).
-- A message is numbered and kept in the save until its receiver says it has it. Until then it goes again,
-- now and then while the receiver may be there, at once when they come back (a message of theirs, the
-- guild or Battle.net says they are online), by every way that reaches them in turn (Battle.net between
-- friends, the guild, a whisper). The receiver reads it once, in the order its writer wrote it (one
-- message at a time to each player), and says so. A long one goes in parts. When the game holds the
-- messages back (the chat in lockdown, too many messages at once, a receiver offline), they wait: nothing
-- is lost, even across a reload. Its own prefix: the game counts its messages apart from the other ones of
-- Curator (the summaries of the guild, the profiles).
-- Messages (prefix CuratorW, fields separated by ":"):
--   M:<number>:<i>/<n>:<to>:<part>   a part of a message (to: its receiver, through the guild; empty
--                                   otherwise)
--   K:<number>:<to>                  the message came (to: its writer, through the guild)
--   P:<to>:<text>                    a message that needs no answer (the checks of the trades): sent once
-- What is kept (db.wire): n (the count behind the numbers), out ([receiver] = the messages still to
-- deliver, in order: s the number, b the text, t when it was written, x when it gives up, k the tries),
-- seen ([writer] = [number] = when it came), log (the last lines of the journal: /curator log).
-------------------------------------------------------------------------------
local W = { handlers = {}, acked = {}, lost = {}, due = {}, parts = {}, offline = {}, tokens = 8, filled = 0 }
ns.Wire = W

W.PREFIX = "CuratorW"
W.PART = 170               -- the characters of a message in one part
W.MAX_PARTS = 64           -- (1 November: 8 before; every copy of a trade goes with its wear, Trade.lua)
W.TTL = 7 * 86400          -- a message nobody got goes after a week
W.SEEN_DAYS = 8            -- the numbers read are kept a little longer than a message can live
W.RETRY = { 4, 8, 15, 30, 60, 120, 240 } -- seconds before each new try, while the receiver may be there
W.OFFLINE_WAIT = 300       -- a receiver the game says is offline: tried again after five minutes
W.LOCKED_WAIT = 5          -- the game holds the chat back: again after five seconds
W.SLEEP_AFTER, W.SLEEP_WAIT = 20, 1800 -- twenty tries without a word back: every half hour (at once when they come)
W.BUCKET, W.FILL = 8, 1.2  -- messages at once, seconds for one more (the game allows ten, then one a second)
W.LOG_MAX = 250
W.TICK = 0.5

-- What the game says of a message sent (Enum.SendAddonMessageResult).
local OK, THROTTLE, CHANNEL_THROTTLE, LOCKDOWN, OFFLINE, ERROR = 0, 3, 8, 11, 12, 9

local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Now()
	return CuratorOctoFull.ServerTime()
end

local function Clock()
	return GetTime and GetTime() or 0
end

local function Base36(n)
	n = math.floor(n)
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = math.floor(n / 36)
	until n == 0
	return s
end

-- "Name-Realm" for any name (the realm of mine when none is given).
local function Norm(name)
	if type(name) ~= "string" or name == "" or Secret(name) then
		return nil
	end
	return ns.Guild and ns.Guild:Full(name) or name
end
W.Norm = Norm

local function Short(name)
	return type(name) == "string" and (string.gsub(name, "%-.*$", "")) or "?"
end

local function IsMe(name)
	return ns.Guild ~= nil and ns.Guild:IsMe(name)
end

-------------------------------------------------------------------------------
-- What is kept
-------------------------------------------------------------------------------
function W:DB()
	local db = ns.db
	if type(db) ~= "table" then
		return nil
	end
	local w = db.wire
	if type(w) ~= "table" then
		w = {}
		db.wire = w
	end
	w.n = tonumber(w.n) or 0
	if type(w.out) ~= "table" then
		w.out = {}
	end
	if type(w.seen) ~= "table" then
		w.seen = {}
	end
	if type(w.log) ~= "table" then
		w.log = {}
	end
	return w
end

-- A line of the journal (the time of the realm, what went and came): /curator log shows the last ones.
function W:Log(fmt, ...)
	local w = self:DB()
	if not w then
		return
	end
	local ok, line = pcall(string.format, fmt, unpack(arg, 1, arg.n))
	if not ok then
		line = tostring(fmt)
	end
	local clock = (date and date("%m-%d %H:%M:%S", Now())) or tostring(Now())
	line = clock .. " " .. (string.gsub(line, "[\r\n|]", " "))
	local log = w.log
	log[CuratorOctoFull.Length(log) + 1] = line
	while CuratorOctoFull.Length(log) > self.LOG_MAX do
		CuratorOctoFull.Remove(log, 1)
	end
end

-- The last lines of the journal (n of them, the oldest first).
function W:Journal(n)
	local w = self:DB()
	local log = w and w.log or {}
	local out = {}
	for i = math.max(1, CuratorOctoFull.Length(log) - (n or 40) + 1), CuratorOctoFull.Length(log) do
		out[CuratorOctoFull.Length(out) + 1] = log[i]
	end
	return out
end

-- A number no message of mine had: the time it is written, then a count.
function W:Next()
	local w = self:DB()
	w.n = CuratorOctoFull.Mod((w.n + 1) , 46656)
	return Base36(Now()) .. "." .. Base36(w.n)
end

-------------------------------------------------------------------------------
-- What the modules hear
-------------------------------------------------------------------------------
-- (the letter a text starts with: "T" the trades, "Z" the duels) fn(to, text, number) when its receiver
-- has it; lost(to, text) when it is given up.
function W:OnAck(kind, fn)
	self.acked[kind] = fn
end

function W:OnLost(kind, fn)
	self.lost[kind] = fn
end

-------------------------------------------------------------------------------
-- Sending
-------------------------------------------------------------------------------
-- A message that must arrive: kept until its receiver has it (ttl: the seconds it may wait, a week by
-- default). Its number, or nil.
function W:Send(to, text, ttl)
	to = Norm(to)
	local w = self:DB()
	if not (w and to and type(text) == "string" and text ~= "") or IsMe(to) or CuratorOctoFull.Length(text) > self.PART * self.MAX_PARTS
		or string.find(text, "|", 1, true) then
		return nil
	end
	local q = w.out[to]
	if type(q) ~= "table" then
		q = {}
		w.out[to] = q
	end
	local s = self:Next()
	q[CuratorOctoFull.Length(q) + 1] = { s = s, b = text, t = Now(), x = Now() + math.floor(ttl or self.TTL), k = 0 }
	self:Log("> %s %s %s", Short(to), s, string.sub(text, 1, 28))
	-- (the first one in line goes at once; the others when the one before has come)
	self:Arm()
	if CuratorOctoFull.Length(q) == 1 then
		self.due[to] = 0
		self:Try(to, q[1])
	end
	return s
end

-- A message that needs no answer (the checks of the trades), by the best way to its receiver, once.
function W:Post(to, text)
	to = Norm(to)
	if not (to and type(text) == "string") or IsMe(to) or string.find(text, "|", 1, true) then
		return false
	end
	local route = self:Routes(to)[1]
	if not route then
		return false
	end
	local msg = string.format(("P:%s:%s"), route == "GUILD" and to or "", text)
	if CuratorOctoFull.Length(msg) > 255 then
		return false
	end
	if self:Locked() then
		return false
	end
	self:Fill()
	if self.tokens < 1 then
		return false
	end
	self.tokens = self.tokens - 1
	return self:Raw(route, to, msg) == OK
end

-- The messages still to deliver to a player, in order ({ s, b, t, x, k }).
function W:Pending(to)
	local w = self:DB()
	local q = w and w.out[Norm(to) or ""]
	return type(q) == "table" and q or {}
end

-- A message still to deliver to that player whose text starts so.
function W:Waiting(to, start)
	for _, m in ipairs(self:Pending(to)) do
		if type(m) == "table" and type(m.b) == "string" and string.sub(m.b, 1, CuratorOctoFull.Length(start)) == start then
			return m
		end
	end
	return nil
end

-- The messages to a player whose text starts so no longer go (a newer one says it better).
function W:Drop(to, start)
	to = Norm(to)
	local w = self:DB()
	local q = w and to and w.out[to]
	if type(q) ~= "table" then
		return 0
	end
	local n = 0
	for i = CuratorOctoFull.Length(q), 1, -1 do
		local m = q[i]
		if type(m) ~= "table" or (type(m.b) == "string" and string.sub(m.b, 1, CuratorOctoFull.Length(start)) == start) then
			CuratorOctoFull.Remove(q, i)
			n = n + 1
		end
	end
	if n > 0 then
		self.due[to] = 0
		self:Log("- %s %d dropped (%s)", Short(to), n, string.sub(start, 1, 20))
	end
	if CuratorOctoFull.Length(q) == 0 then
		w.out[to] = nil
	end
	return n
end

-- The game told that this player is offline (when, by the clock), or nil.
function W:Offline(to)
	return self.offline[Norm(to) or ""]
end

-- The ways to a player, in the order to try them: Battle.net (a friend), the guild (a member online),
-- a whisper.
function W:Routes(to)
	local out = {}
	local T = ns.Trade
	if T and T.BNTarget and T:BNTarget(to) then
		out[CuratorOctoFull.Length(out) + 1] = "BN"
	end
	-- (1.13.1: WoW Forever: a first name alone, or a name of 1.13.0 with my realm: Battle.net only, when it says whose
	-- it is; no whisper reaches it for sure, it waits until then)
	if ns.Guild and ns.Guild.Unsure and ns.Guild:Unsure(to) then
		return out
	end
	if T and T.roster and T.roster[to] == true and IsInGuild and IsInGuild() then
		out[CuratorOctoFull.Length(out) + 1] = "GUILD"
	end
	out[CuratorOctoFull.Length(out) + 1] = "WHISPER"
	return out
end

-- The chat held back by the game (its lockdown).
function W:Locked()
	local api = CuratorOctoFull.Chat
	if api and api.InChatMessagingLockdown then
		local ok, locked = pcall(api.InChatMessagingLockdown)
		return ok and not Secret(locked) and locked == true
	end
	return false
end

-- The messages the game lets go now (ten at once, then one a second: a little less, to be sure).
function W:Fill()
	local clock = Clock()
	if self.tokens >= self.BUCKET then
		self.filled = clock
		return
	end
	local add = math.floor((clock - self.filled) / self.FILL)
	if add > 0 then
		self.tokens = math.min(self.BUCKET, self.tokens + add)
		self.filled = self.filled + add * self.FILL
	end
end

-- A message out, by a way: what the game says (OK, THROTTLE, LOCKDOWN, OFFLINE, ERROR...).
function W:Raw(route, to, msg)
	local ok, res
	if route == "BN" then
		local T = ns.Trade
		local id = T and T:BNTarget(to)
		local B = C_BattleNet
		local send = (B and B.SendGameData) or BNSendGameData
		if not (id and send) then
			return ERROR
		end
		ok, res = pcall(send, id, self.PREFIX, msg)
	else
		local api = CuratorOctoFull.Chat
		if not (api and api.SendAddonMessage) then
			return ERROR
		end
		if route == "GUILD" then
			ok, res = pcall(api.SendAddonMessage, self.PREFIX, msg, "GUILD")
		else
			ok, res = pcall(api.SendAddonMessage, self.PREFIX, msg, "WHISPER", to)
		end
	end
	if not ok then
		return ERROR
	end
	if res == nil or res == true or res == 0 then
		return OK
	end
	if res == false or Secret(res) then
		return ERROR
	end
	return tonumber(res) or ERROR
end

-- A message cut in parts that fit (never inside a letter of several bytes).
function W:Split(text)
	local parts, i = {}, 1
	while i <= CuratorOctoFull.Length(text) do
		local j = math.min(CuratorOctoFull.Length(text), i + self.PART - 1)
		-- (the next byte continues a letter: the cut goes back to its first byte)
		while j < CuratorOctoFull.Length(text) and j > i do
			local b = CuratorOctoFull.Byte(text, j + 1)
			if b < 128 or b >= 192 then
				break
			end
			j = j - 1
		end
		parts[CuratorOctoFull.Length(parts) + 1] = string.sub(text, i, j)
		i = j + 1
	end
	if CuratorOctoFull.Length(parts) == 0 then
		parts[1] = ""
	end
	return parts
end

-- The first message in line for a player, once more.
function W:Try(to, m)
	if self:Locked() then
		self.due[to] = Clock() + self.LOCKED_WAIT
		return
	end
	local parts = self:Split(m.b)
	self:Fill()
	if self.tokens < CuratorOctoFull.Length(parts) then
		self.due[to] = Clock() + self.FILL
		return
	end
	local routes = self:Routes(to)
	-- (1.13.1: no way to them now: later, as for a player offline)
	if CuratorOctoFull.Length(routes) == 0 then
		self.due[to] = Clock() + self.OFFLINE_WAIT
		return
	end
	m.k = (tonumber(m.k) or 0) + 1
	local route = routes[(CuratorOctoFull.Mod((m.k - 1) , CuratorOctoFull.Length(routes))) + 1]
	local res = OK
	for i, part in ipairs(parts) do
		res = self:Raw(route, to, string.format(("M:%s:%d/%d:%s:%s"), m.s, i, CuratorOctoFull.Length(parts), route == "GUILD" and to or "", part))
		self.tokens = self.tokens - 1
		if res ~= OK then
			break
		end
	end
	local clock = Clock()
	if res == LOCKDOWN then
		m.k = m.k - 1
		self.due[to] = clock + self.LOCKED_WAIT
	elseif res == THROTTLE or res == CHANNEL_THROTTLE then
		m.k = m.k - 1
		self.tokens = 0
		self.filled = clock
		self.due[to] = clock + 2
	elseif res == OFFLINE then
		self.offline[to] = clock
		self.due[to] = clock + self.OFFLINE_WAIT
		self:Log("~ %s %s offline", Short(to), m.s)
	else
		local wait = self.RETRY[math.min(m.k, CuratorOctoFull.Length(self.RETRY))]
		-- (no word back after many tries: now and then, or at once when they are heard of)
		if m.k >= self.SLEEP_AFTER then
			wait = math.max(wait, self.SLEEP_WAIT)
		end
		-- (known to be offline, by the guild or Battle.net: not before they come back, or now and then)
		local T = ns.Trade
		if self.offline[to] or (T and T.Online and T:Online(to) == false) then
			wait = math.max(wait, self.OFFLINE_WAIT)
		end
		self.due[to] = clock + wait
		self:Log("~ %s %s try %d %s%s", Short(to), m.s, m.k, route, res == OK and "" or (" error " .. tostring(res)))
	end
end

-- Every message in line, when its time comes; those too old are given up.
function W:Pump()
	local w = self:DB()
	if not w then
		return
	end
	local now, clock = Now(), Clock()
	local left = false
	for to, q in pairs(w.out) do
		if type(q) ~= "table" then
			w.out[to] = nil
		else
			local head = q[1]
			while head and (type(head) ~= "table" or type(head.b) ~= "string" or (tonumber(head.x) or 0) <= now) do
				CuratorOctoFull.Remove(q, 1)
				if type(head) == "table" and type(head.b) == "string" then
					self:Log("x %s %s given up", Short(to), tostring(head.s))
					local fn = self.lost[string.sub(head.b, 1, 1)]
					if fn then
						fn(to, head.b)
					end
				end
				self.due[to] = 0
				head = q[1]
			end
			if not head then
				w.out[to] = nil
			else
				left = true
				if clock >= (self.due[to] or 0) then
					self:Try(to, head)
				end
			end
		end
	end
	-- (the parts of a message that never came whole)
	for key, p in pairs(self.parts) do
		if clock - p.t > 120 then
			self.parts[key] = nil
		end
	end
	return left
end

-- They are there (a message of theirs, the guild, Battle.net): what waits for them goes at once.
function W:Wake(name)
	name = Norm(name)
	if not name then
		return
	end
	self.offline[name] = nil
	local w = self:DB()
	local q = w and w.out[name]
	if type(q) == "table" and q[1] and (self.due[name] or 0) > Clock() then
		self.due[name] = Clock()
		self:Arm()
	end
end

-- Everyone at once (the login, the guild back online).
function W:WakeAll()
	local w = self:DB()
	for name in pairs(w and w.out or {}) do
		self.due[name] = 0
	end
	self:Arm()
end

-------------------------------------------------------------------------------
-- Receiving
-------------------------------------------------------------------------------
-- A message came whole: once only (its number seen before: only the word back), then read as any
-- message of Curator.
function W:Deliver(text, sender)
	if ns.Guild and ns.Guild.OnMessage then
		ns.Guild:OnMessage(text, "WHISPER", sender)
	end
end

-- Says a message came, by the way it came.
function W:Ack(channel, sender, s)
	local route = (channel == "BN" and "BN") or (channel == "GUILD" and "GUILD") or "WHISPER"
	if route == "GUILD" and not (IsInGuild and IsInGuild()) then
		route = "WHISPER"
	end
	self:Raw(route, sender, string.format(("K:%s:%s"), s, route == "GUILD" and sender or ""))
end

-- The word back for a message of mine: the next one goes.
local function Holds(q, s)
	if type(q) ~= "table" then
		return false
	end
	for _, m in ipairs(q) do
		if type(m) == "table" and m.s == s then
			return true
		end
	end
	return false
end

function W:Acked(sender, s)
	local w = self:DB()
	local q = w and w.out[sender]
	-- (1.13.1: WoW Forever: what waited for them under a name of 1.13.0 (their first name alone, or with my realm),
	-- theirs now that they say it came: under their name, the first in line)
	if w and not Holds(q, s) and ns.Guild and ns.Guild.Aliases then
		for _, alias in ipairs(ns.Guild:Aliases(sender)) do
			local aq = w.out[alias]
			if Holds(aq, s) then
				for _, m in ipairs(type(q) == "table" and q or {}) do
					aq[CuratorOctoFull.Length(aq) + 1] = m
				end
				w.out[sender], w.out[alias] = aq, nil
				self.due[alias] = nil
				q = aq
				self:Log("= %s: what waited for %s", Short(sender), Short(alias))
				break
			end
		end
	end
	if type(q) ~= "table" then
		return
	end
	for i, m in ipairs(q) do
		if type(m) == "table" and m.s == s then
			CuratorOctoFull.Remove(q, i)
			self:Log("= %s %s came (%d tries)", Short(sender), s, tonumber(m.k) or 0)
			if CuratorOctoFull.Length(q) == 0 then
				w.out[sender] = nil
			end
			self.due[sender] = 0
			local fn = type(m.b) == "string" and self.acked[string.sub(m.b, 1, 1)]
			if fn then
				fn(sender, m.b, s)
			end
			-- (the next one in line goes at once)
			if type(w.out[sender]) == "table" and w.out[sender][1] then
				self:Try(sender, w.out[sender][1])
			end
			return
		end
	end
end

-- A message of the wire (channel: "GUILD", "WHISPER" or "BN").
function W:OnMessage(text, channel, sender)
	if type(text) ~= "string" or Secret(text) or Secret(sender) then
		return
	end
	sender = Norm(sender)
	if not sender or IsMe(sender) then
		return
	end
	local kind, rest = CuratorOctoFull.Match(text, "^(%u):(.*)$")
	if kind == "M" then
		local s, i, n, to, part = CuratorOctoFull.Match(rest, "^([%w%.]+):(%d+)/(%d+):([^:]*):(.*)$")
		i, n = tonumber(i), tonumber(n)
		if not (s and i and n and n >= 1 and n <= self.MAX_PARTS and i >= 1 and i <= n and CuratorOctoFull.Length(s) <= 16) then
			return
		end
		if (to ~= "" and not IsMe(to)) or (to == "" and channel == "GUILD") then
			return
		end
		self:Wake(sender)
		local key = sender .. "\1" .. s
		local p = self.parts[key]
		if not p or p.n ~= n then
			p = { n = n, got = {}, c = 0, t = Clock() }
			self.parts[key] = p
		end
		if not p.got[i] then
			p.got[i] = part
			p.c = p.c + 1
		end
		if p.c < n then
			return
		end
		self.parts[key] = nil
		local body = table.concat(p.got, "", 1, n)
		self:Ack(channel, sender, s)
		local w = self:DB()
		if not w then
			return
		end
		local seen = w.seen[sender]
		if type(seen) ~= "table" then
			seen = {}
			w.seen[sender] = seen
		end
		if seen[s] then
			return
		end
		seen[s] = Now()
		self:Log("< %s %s %s", Short(sender), s, string.sub(body, 1, 28))
		self:Deliver(body, sender)
	elseif kind == "K" then
		local s, to = CuratorOctoFull.Match(rest, "^([%w%.]+):([^:]*)$")
		if not s or (to ~= "" and not IsMe(to)) or (to == "" and channel == "GUILD") then
			return
		end
		self:Wake(sender)
		self:Acked(sender, s)
	elseif kind == "P" then
		local to, body = CuratorOctoFull.Match(rest, "^([^:]*):(.*)$")
		if not to or (to ~= "" and not IsMe(to)) or (to == "" and channel == "GUILD") then
			return
		end
		self:Wake(sender)
		self:Deliver(body, sender)
	end
end

-- The numbers read too long ago go.
function W:Prune()
	local w = self:DB()
	if not w then
		return
	end
	local old = Now() - self.SEEN_DAYS * 86400
	for name, seen in pairs(w.seen) do
		if type(seen) == "table" then
			for s, t in pairs(seen) do
				if (tonumber(t) or 0) < old then
					seen[s] = nil
				end
			end
			if next(seen) == nil then
				w.seen[name] = nil
			end
		else
			w.seen[name] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
local f = CreateFrame("Frame")
W.frame = f
f.t = 0

-- (the clock of the wire runs while something waits)
function W:Arm()
	if not f:GetScript("OnUpdate") then
		f.t = 0
		CuratorOctoFull.SetScript(f, "OnUpdate", function(self, elapsed)
			self.t = self.t + elapsed
			if self.t < W.TICK then
				return
			end
			self.t = 0
			if not W:Pump() then
				CuratorOctoFull.SetScript(self, "OnUpdate", nil)
			end
		end)
	end
end

ns.On("LOADED", function()
	W:DB()
	W:Prune()
end)

ns.On("LOGIN", function()
	-- (what waited since the last time goes, a moment after the login)
	ns.Delay(5, function()
		W:WakeAll()
	end, W)
end)

f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		local api = CuratorOctoFull.Chat
		if api and api.RegisterAddonMessagePrefix then
			pcall(api.RegisterAddonMessagePrefix, W.PREFIX)
		end
		pcall(self.RegisterEvent, self, "CHAT_MSG_ADDON")
		pcall(self.RegisterEvent, self, "BN_CHAT_MSG_ADDON")
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, text, channel, sender = unpack(arg, 1, arg.n)
		if not Secret(prefix) and prefix == W.PREFIX and (channel == "WHISPER" or channel == "GUILD") then
			W:OnMessage(text, channel, sender)
		end
	elseif event == "BN_CHAT_MSG_ADDON" then
		local prefix, text, _, senderID = unpack(arg, 1, arg.n)
		if not Secret(prefix) and prefix == W.PREFIX and not Secret(senderID) and ns.Trade and ns.Trade.BNName then
			local name = ns.Trade:BNName(senderID)
			if name then
				W:OnMessage(text, "BN", name)
			end
		end
	end
end)
