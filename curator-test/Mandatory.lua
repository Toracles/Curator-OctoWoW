local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- Mandatory updates (1.4). Each build carries the fingerprint of its version (MINE): the hash of a
-- secret of that version that only the author can make (from a key kept on his own computer, never
-- in the addon). A build that makes older versions obsolete carries their secrets (REVEALS) and
-- gives them to the players it sees on them: by whisper, when their profile or their hello on the
-- channel of the presence says their version. A copy that gets the secret of its own version checks
-- it against its fingerprint; if it matches, it is obsolete: it says so in a window and locks itself
-- as a beta past its day does (the album no longer opens, nothing is earned, no trade), until it is
-- updated, and passes the secret on to its guild. Nobody else can lock a copy: without the secret,
-- nothing matches. Message:
--   X:1:<version made obsolete>,<its secret>,<the version that makes it obsolete>
-------------------------------------------------------------------------------
local M = {}
ns.Mandatory = M

-- The fingerprint of this version (written when the build is made: the tool of the author computes it
-- on his computer from his key), and the secrets of the versions this one makes obsolete.
M.MINE = { v = "1.14.3", c = "f9a3cc3894486971f2b0e310b6bcde934c1d02cb06309faf5397638781def355" }
-- (1.5.0 was mandatory: it made 1.4.1 obsolete, the first version with a fingerprint; 1.6.0 and 1.7.0
-- were not. From 1.8.0 on, every version is mandatory: it carries the secrets of all the versions before
-- it that have a fingerprint, and makes them obsolete. 1.13.0 too: the secret of 1.12.0 joins those of
-- before, written when it is armed. 1.12.1 never came out: all it brought went into 1.13.0. 1.13.1, a small version,
-- is not mandatory: it carries its own fingerprint, and the secrets of before as 1.13.0 did; 1.13.0 keeps working.)
-- (1.13.2 closed Curator at the end of the beta of WoW Forever and made 1.13.0 and 1.13.1 obsolete. 1.14.0, when it
-- is armed: the secrets of 1.13.0, 1.13.1 and 1.13.2 join those of before, so that every copy of the beta is told to update.)
M.REVEALS = {
	["1.4.1"] = "a5c14083a597fbfa1c4425251323c2615be9d16953e16c3c5e43c3f7732747d4",
	["1.5.0"] = "53dada2d1236cec4e5800fa29c47e5703ed75605db1cb625e26b7f80f73b74c9",
	["1.6.0"] = "9aeaad986cb854302a80c32b4d21a88f31c4a1f0d6e641d972dbeed3c16a8fa8",
	["1.7.0"] = "60c0f8d1f3c63046daa4f2cef7c2b2ce9c3212e4c1510bd2136b57dc94fe2e4b",
	["1.8.0"] = "2f92a5d904feb24c01203539b608700135c588b0c21442bd0d7616e7c293b10a",
	["1.9.0"] = "f9b2f93186f86ca4222ac95ff4cd615f2087edc6c3e270482f3eac74efb1119c",
	["1.9.1"] = "fa38979d2af923387986477f6ee64f2c1ee4d4c380f7719513286f26b872c10c",
	["1.10.0"] = "2135ff04482ab69354e8fd5dc03ff7131dec618f782c8b6851944f387f43a53b",
	["1.11.0"] = "757f0a81a397104dfbf15f0c544891ce1990856d0ecf6bb839844a586b045ed9",
	["1.12.0"] = "6eb7829ea83e82c6c9ae8bab33bb8bd64b322ec4da4fb20016c881e3d4645321",
	["1.13.0"] = "3be906fb1e6ad757cd581acca5d5c910eba721060b9f70ce7c50e4bd252e7e65",
	["1.13.1"] = "99649d4a9e3f68661a36a4e070e184b8db2fd466c9a42ab662ad6c56a3df8256",
	["1.13.2"] = "f320b51f15dfa206a30d10f9ce37db1280e8855f502098f3161f0591d4c8a2fb",
	["1.14.0"] = "fd1373d88b70701ebfe297a7ec2b7bf3e256e8a12c744aacb97cb2ceb2070288",
	["1.14.1"] = "75a151f1872f142345f878d088736cf14fdf1b62d1b62e8cb35f084f78c5ad11",
	["1.14.2"] = "16159b8eeb0c3ca1daf417e8b701492c8ade8f66c440b39e5bbb2e0f548741c3",
}

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

-------------------------------------------------------------------------------
-- SHA-256 (FIPS 180-4) in plain Lua, without any library of bits: 32-bit words held as numbers, their
-- xor and their and four bits at a time.
-------------------------------------------------------------------------------
local XOR4, AND4 = {}, {}
for a = 0, 15 do
	for b = 0, 15 do
		local x, y, z = 0, 0, 1
		local p, q = a, b
		for _ = 1, 4 do
			local i, j = CuratorOctoFull.Mod(p , 2), CuratorOctoFull.Mod(q , 2)
			if i ~= j then
				x = x + z
			end
			if i == 1 and j == 1 then
				y = y + z
			end
			p, q, z = (p - i) / 2, (q - j) / 2, z * 2
		end
		XOR4[a * 16 + b], AND4[a * 16 + b] = x, y
	end
end

local W32 = 4294967296

local function Op(t, a, b)
	local r, m = 0, 1
	for _ = 1, 8 do
		local x, y = CuratorOctoFull.Mod(a , 16), CuratorOctoFull.Mod(b , 16)
		r = r + t[x * 16 + y] * m
		a, b, m = (a - x) / 16, (b - y) / 16, m * 16
	end
	return r
end

local function Xor(a, b)
	return Op(XOR4, a, b)
end

local function And(a, b)
	return Op(AND4, a, b)
end

local function Not(a)
	return W32 - 1 - a
end

-- Rotation to the right by n bits, shift to the right by n bits.
local function Ror(x, n)
	local k = 2 ^ n
	local lo = CuratorOctoFull.Mod(x , k)
	return (x - lo) / k + lo * (W32 / k)
end

local function Shr(x, n)
	local k = 2 ^ n
	return (x - CuratorOctoFull.Mod(x , k)) / k
end

local K = {
	1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221,
	3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580,
	3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986,
	2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895,
	666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037,
	2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344,
	430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779,
	1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298,
}

-- The hash of a string, in 64 hexadecimal digits (lower case).
function M.Sha256(msg)
	local h = { 1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225 }
	local len = CuratorOctoFull.Length(msg)
	-- the padding: a bit 1, zeros, then the length in bits on 64 bits
	local bits = len * 8
	local tail = { "\128", string.rep("\0", CuratorOctoFull.Mod((55 - len) , 64)) }
	local lenBytes = {}
	for i = 8, 1, -1 do
		local b = CuratorOctoFull.Mod(bits , 256)
		lenBytes[i] = string.char(b)
		bits = (bits - b) / 256
	end
	msg = msg .. table.concat(tail) .. table.concat(lenBytes)
	local w = {}
	for chunk = 1, CuratorOctoFull.Length(msg), 64 do
		for i = 0, 15 do
			local a, b, c, d = CuratorOctoFull.Byte(msg, chunk + i * 4, chunk + i * 4 + 3)
			w[i] = ((a * 256 + b) * 256 + c) * 256 + d
		end
		for i = 16, 63 do
			local x, y = w[i - 15], w[i - 2]
			local s0 = Xor(Xor(Ror(x, 7), Ror(x, 18)), Shr(x, 3))
			local s1 = Xor(Xor(Ror(y, 17), Ror(y, 19)), Shr(y, 10))
			w[i] = CuratorOctoFull.Mod((w[i - 16] + s0 + w[i - 7] + s1) , W32)
		end
		local a, b, c, d, e, f, g, hh = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
		for i = 0, 63 do
			local S1 = Xor(Xor(Ror(e, 6), Ror(e, 11)), Ror(e, 25))
			local ch = Xor(And(e, f), And(Not(e), g))
			local t1 = CuratorOctoFull.Mod((hh + S1 + ch + K[i + 1] + w[i]) , W32)
			local S0 = Xor(Xor(Ror(a, 2), Ror(a, 13)), Ror(a, 22))
			local maj = Xor(Xor(And(a, b), And(a, c)), And(b, c))
			local t2 = CuratorOctoFull.Mod((S0 + maj) , W32)
			hh, g, f, e, d, c, b, a = g, f, e, CuratorOctoFull.Mod((d + t1) , W32), c, b, a, CuratorOctoFull.Mod((t1 + t2) , W32)
		end
		h[1], h[2], h[3], h[4] = CuratorOctoFull.Mod((h[1] + a) , W32), CuratorOctoFull.Mod((h[2] + b) , W32), CuratorOctoFull.Mod((h[3] + c) , W32), CuratorOctoFull.Mod((h[4] + d) , W32)
		h[5], h[6], h[7], h[8] = CuratorOctoFull.Mod((h[5] + e) , W32), CuratorOctoFull.Mod((h[6] + f) , W32), CuratorOctoFull.Mod((h[7] + g) , W32), CuratorOctoFull.Mod((h[8] + hh) , W32)
	end
	local out = {}
	for i = 1, 8 do
		out[i] = string.format(("%08x"), h[i])
	end
	return table.concat(out)
end

-------------------------------------------------------------------------------
-- Obsolete or not
-------------------------------------------------------------------------------
local function IsVersion(v)
	return type(v) == "string" and CuratorOctoFull.Length(v) <= 12 and CuratorOctoFull.Match(v, "^%d+%.%d+%.?%d*$") ~= nil
end

local function IsSecret(s)
	return type(s) == "string" and CuratorOctoFull.Length(s) == 64 and CuratorOctoFull.Match(s, "^%x+$") ~= nil
end

-- This build can be made obsolete: its fingerprint is there, for the version it is.
function M:Armed()
	return IsSecret(self.MINE.c) and self.MINE.v == ns.version
end

-- The secret of this version (it is obsolete): true.
function M:Check(ver, secret)
	if not self:Armed() or ver ~= self.MINE.v or not IsSecret(secret) then
		return false
	end
	return M.Sha256(string.lower(secret)) == string.lower(self.MINE.c)
end

function M:Locked()
	return self.lock ~= nil
end

-- The version that made this one obsolete (nil: not known, or not obsolete).
function M:By()
	return self.lock and self.lock.by
end

-- Obsolete: kept in the save (the next sessions stay locked until the update), said, and passed on.
function M:Lock(secret, by)
	local first = not self.lock
	self.lock = { v = self.MINE.v, s = string.lower(secret), by = IsVersion(by) and by or nil, t = CuratorOctoFull.ServerTime() }
	if ns.db then
		ns.db.mandatory = self.lock
	end
	if first then
		ns.Fire("MANDATORY", self.lock)
		self:Tell()
		self:Relay()
	end
end

-- Said: in its window, each time something is asked of this copy, and in the chat (once a minute at
-- most).
function M:Tell()
	local now = (GetTime and GetTime()) or 0
	local by = self:By()
	if not self.told or now - self.told >= 60 then
		self.told = now
		ns.Print(by and string.format(L["Mandatory update: Curator %s is out and your version (%s) no longer works."], by, ns.version)
			or string.format(L["Mandatory update: your version of Curator (%s) no longer works."], ns.version))
	end
	if ns.MandatoryWindow then
		ns.MandatoryWindow:Show(by)
	end
end

-- The guild gets the secret too (those on this version lock themselves; the others pay no heed).
function M:Relay()
	if self.relayed or not self.lock or not ns.Guild then
		return
	end
	if IsInGuild and IsInGuild() then
		self.relayed = ns.Guild:Send(string.format(("X:1:%s,%s,%s"), self.lock.v, self.lock.s, self.lock.by or "-"), "GUILD") and true or nil
	end
end

-- A secret given by another player.
function M:OnMessage(body, channel, sender)
	if type(body) ~= "string" or Secret(body) then
		return
	end
	local ver, secret, by = CuratorOctoFull.Match(body, "^([^,]+),([^,]+),([^,]+)$")
	if not ver or self.lock then
		return
	end
	if self:Check(ver, secret) then
		self:Lock(secret, by)
	end
end

-------------------------------------------------------------------------------
-- The players seen on an obsolete version get its secret (once each, by whisper)
-------------------------------------------------------------------------------
function M:Give(name, ver)
	local secret = ver and self.REVEALS[ver]
	if not (name and IsSecret(secret)) or self.lock or not ns.Guild or ns.Guild:IsMe(name) then
		return false
	end
	self.given = self.given or {}
	local key = name .. "@" .. ver
	if self.given[key] then
		return false
	end
	self.given[key] = true
	return ns.Guild:Send(string.format(("X:1:%s,%s,%s"), ver, secret, ns.version or "-"), "WHISPER", name)
end

ns.On("PLAYER_INFO", function(name)
	local i = ns.Guild and name and ns.Guild:Profile(name)
	if i and i.ver then
		M:Give(name, i.ver)
	end
end)

ns.On("PRESENCE", function(name, p)
	if p and p.ver then
		M:Give(name, p.ver)
	end
end)

-- The lock of the sessions before, as long as this version is the one it locked.
ns.On("LOADED", function()
	local m = ns.db and ns.db.mandatory
	if type(m) ~= "table" then
		ns.db.mandatory = nil
		return
	end
	if m.v == M.MINE.v and M:Check(m.v, m.s) then
		M.lock = { v = m.v, s = m.s, by = IsVersion(m.by) and m.by or nil, t = m.t }
	else
		-- (updated since: the lock no longer applies)
		ns.db.mandatory = nil
	end
end)

ns.On("LOGIN", function()
	if M.lock then
		ns.Delay(4, function()
			M:Tell()
			M:Relay()
		end, M)
	end
end)
