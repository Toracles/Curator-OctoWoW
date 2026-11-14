local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.9.1) The players banned for good from Curator (cheating on purpose, exploiting a bug), as the
-- website keeps them (npm run ban gives these lines): the fingerprints of their Battle.net account (its
-- BattleTag), of their collections and of their characters, each the SHA-256 of
-- "curator-ban:<kind>:<value>" with its ASCII capitals made small. Nothing of them in clear here.
-- Banned, Curator no longer works for them, as a suspended Curator does not (Beta.lua: B:Over), with a
-- window that says so (UI/Suspended.lua), and no starting over.
-- (1.12.1) A character by its name too (kind "char"): "Name-Realm", its realm as the game writes it in the
-- names of the messages (without spaces nor dashes), its capitals made small as the names are folded
-- (Comm.lua: G.Fold). Its own Curator stops as above, and the Curator of every other player ignores what
-- it sends: its offers of trades and of duels, its collection, its level on the chat channel of the
-- collectors, and what it says there (Comm.lua, Channel.lua). The name of who sends a message, the game
-- gives it: no copy can hide it, even one changed by hand. A trade or a duel with it does not start
-- (Trade.lua, Duel.lua). Each line says its kind.
-- (1.14.0) The bans of the website come with its news too (BN:Feed), for a time or for good: the author bans from his
-- atelier, and no version of the addon has to come out for it.
-------------------------------------------------------------------------------
-- (1.12.1: the ban of 1.9.1 lifted, nobody banned now)
local BANNED = {
}

local BN = { senders = {} }
ns.Bans = BN
-- (the table itself: the harness puts its own lines in it)
BN.BANNED = BANNED

-------------------------------------------------------------------------------
-- (1.14.0) The bans of the website in its news (Feed.lua, written by the app of Curator every quarter of an hour; the
-- website: lib/bans.ts): every Battle.net account banned at that moment, by the first BN.HEX hexadecimal digits of each
-- of its fingerprints (as above), each with the end of its ban (in seconds, the time of the server; 0: for good), signed
-- by the website, after the news of each week of the front (the Bourse took the third of the places the app keeps;
-- Front.lua passes over these lines):
--   curator-feed 1
--   w <the week> ... (the front)
--   b <fingerprint> <end>
-- Believed only signed by the website (Front.lua: F:Check), each line only until its end: a ban past its end, or lifted
-- (no longer in the news the app writes), no longer counts. As those of BANNED, while it lasts: the Curator of the player
-- stops (B:Over; UI/Suspended.lua, its window, says until when), the Curator of every other player ignores his characters.
-------------------------------------------------------------------------------
BN.HEX = 32
-- (the longest text of news the app writes, in bytes)
BN.FEED_MAX = 16384

-- (the functions of the game as they are when Curator loads: one changed later by a /run does not count)
local BNGetInfo, UnitGUID = BNGetInfo, UnitGUID

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Known(v)
	return type(v) == "string" and not Secret(v) and v ~= ""
end

-- (1.12.1) A character as its fingerprint is made: "name-realm", its realm without spaces nor dashes, its
-- capitals made small (G.Fold: the accented and the Cyrillic ones too). nil: no name.
function BN.CharKey(name)
	if not Known(name) then
		return nil
	end
	local G = ns.Guild
	local full = (G and G.Full and G:Full(name)) or name
	local n, realm = CuratorOctoFull.Match(full, "^([^%-]+)%-(.*)$")
	if n then
		full = n .. "-" .. (string.gsub(realm, "[%s%-]", ""))
	end
	if G and G.Fold then
		return G.Fold(full)
	end
	return string.lower(full)
end

-- What tells this player: their BattleTag, their collection, their character (each one once known), and
-- (1.12.1) the name of their character.
local function Who()
	local tag, cid, guid, char
	if BNGetInfo then
		local ok, _, t = pcall(BNGetInfo)
		if ok and Known(t) then
			tag = t
		end
	end
	local db = ns.db
	if db and Known(db.cid) then
		cid = db.cid
	end
	if UnitGUID then
		local ok, g = pcall(UnitGUID, "player")
		if ok and Known(g) then
			guid = g
		end
	end
	local G = ns.Guild
	if G and G.Me then
		local ok, me = pcall(G.Me, G)
		if ok and Known(me) and string.find(me, "-", 1, true) then
			char = BN.CharKey(me)
		end
	end
	return tag, cid, guid, char
end

-- The fingerprint of something banned (as scripts/ban.mjs of the website makes it).
function BN.Hash(kind, value)
	return ns.Mandatory.Sha256("curator-ban:" .. kind .. ":" .. (string.gsub(value, "[A-Z]", string.lower)))
end

-- (1.14.0) The time of the server (seconds).
local function Now()
	return (ns.Beta and ns.Beta.Now and ns.Beta:Now()) or (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- (1.14.0) An end of a ban that lasts at that moment: 0 (for good), or later.
local function Lasts(e, now)
	return e ~= nil and (e == 0 or e > now)
end

-- (1.14.0) The longer of two ends (0: for good).
local function Longer(a, b)
	if a == nil then
		return b
	end
	if b == nil then
		return a
	end
	return (a == 0 or b == 0) and 0 or math.max(a, b)
end

-- (1.14.0) The bans of the news: { [fingerprint] = end (0: for good) }, read once for the Feed.lua loaded (it changes only
-- when the game loads it). Nothing that the website did not sign.
function BN:Feed()
	local list = ns.FEED
	if self.feedOf == list and self.feed then
		return self.feed
	end
	local out = {}
	local F, key = ns.Front, ns.FEED_KEY
	for _, e in ipairs(type(list) == "table" and list or {}) do
		local text, sig = type(e) == "table" and e[1], type(e) == "table" and e[2]
		-- (the Bourse, 1.14.0: the bans come after the news of each week of the front, lib/bans.ts; a news of their own
		-- before it, still read)
		local where = type(text) == "string" and (string.find(text, "^curator%-feed 1\nbans 1\n") or string.find(text, "^curator%-feed 1\nw %d+\n"))
		if where and type(sig) == "string" and CuratorOctoFull.Length(text) <= BN.FEED_MAX and CuratorOctoFull.Length(sig) <= 1024
			and string.find(text, "\nb ", 1, true) and F and F.Check and type(key) == "table" and F:Check(text, sig, key) then
			for h, n in CuratorOctoFull.Gmatch(text, "\nb (%x+) (%d+)") do
				if CuratorOctoFull.Length(h) == BN.HEX then
					h = string.lower(h)
					out[h] = Longer(out[h], tonumber(n) or 0)
				end
			end
		end
	end
	self.feedOf, self.feed = list, out
	return out
end

-- Banned (for good, or for a time by the news): once seen, for the rest of the session; BN.ends: the end of the ban (0:
-- for good). (Each fingerprint is made once for what it is made of: B:Over asks often.)
function BN:Banned()
	if self.banned then
		return true
	end
	local feed = self:Feed()
	if (next(BANNED) == nil and next(feed) == nil) or not (ns.Mandatory and ns.Mandatory.Sha256) then
		return false
	end
	local tag, cid, guid, char = Who()
	local seen = (tag or "") .. "\n" .. (cid or "") .. "\n" .. (guid or "") .. "\n" .. (char or "")
	if seen == self.seen then
		return false
	end
	self.seen = seen
	local now, ends = Now(), nil
	for kind, value in pairs({ bnet = tag, cid = cid, guid = guid, char = char }) do
		local h = BN.Hash(kind, value)
		if BANNED[h] then
			self.banned, self.ends = true, 0
			return true
		end
		local e = feed[string.sub(h, 1, BN.HEX)]
		if Lasts(e, now) then
			ends = Longer(ends, e)
		end
	end
	if ends then
		self.banned, self.ends = true, ends
		return true
	end
	return false
end

-- (1.12.1) A character banned by its name (a line of the kind "char", or of before the kinds: true); (1.14.0) or any ban
-- of the news (their kind is not said: each is a fingerprint).
local function AnyChar()
	for _, kind in pairs(BANNED) do
		if kind == "char" or kind == true then
			return true
		end
	end
	return next(BN:Feed()) ~= nil
end

-- (1.12.1) Is this character ("Name-Realm": who sent a message, who a trade or a duel would be with) banned
-- from Curator? Each name once: the answer kept for the session.
function BN:Sender(name)
	if not Known(name) then
		return false
	end
	local known = self.senders[name]
	if known ~= nil then
		return known
	end
	local banned = false
	if AnyChar() and ns.Mandatory and ns.Mandatory.Sha256 then
		local key = BN.CharKey(name)
		if key ~= nil then
			local h = BN.Hash("char", key)
			banned = BANNED[h] ~= nil or Lasts(self:Feed()[string.sub(h, 1, BN.HEX)], Now())
		end
	end
	self.senders[name] = banned
	return banned
end

-- (1.12.1) Said once a minute at most for each name: a trade or a duel with a banned character does not start.
function BN:Tell(name)
	local now = (GetTime and GetTime()) or 0
	self.told = self.told or {}
	if self.told[name] and now - self.told[name] < 60 then
		return
	end
	self.told[name] = now
	local short = (ns.Guild and ns.Guild.Short and ns.Guild:Short(name)) or name
	ns.Print(string.format(L["%s is banned from Curator: no trade with them."], short))
end
