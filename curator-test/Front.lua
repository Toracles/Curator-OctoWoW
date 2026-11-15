local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.8.0) The front of the collectors and the heads with a price, through the website of Curator. (1.14.0, after the
-- test of the cases, his word: gone with the PvP until its rework; Pvp.lua.) What stays: what checks the news of the
-- website (RSA, PKCS #1 v1.5 with SHA-256; its public key: Data/FeedKey.lua), the bans, the gift codes, the pass and
-- the Steamwheedle Exchange believe only what it signed (F:Check; Bans.lua, Gifts.lua, Pass.lua, Market.lua), and its
-- SHA-256 (F.Sha256; Pass.lua).
-------------------------------------------------------------------------------
local F = {}
ns.Front = F

F.TEXT_MAX = 16384 -- a text of news longer than this is not read

local B32 = 4294967296
local floor = math.floor

-------------------------------------------------------------------------------
-- SHA-256 (the words of 32 bits as numbers; the bitwise operations by their nibbles, or the bit library
-- of the game when there is one)
-------------------------------------------------------------------------------
local X4, A4 = {}, {}
for a = 0, 15 do
	for b = 0, 15 do
		local x, y, r1, r2, p = a, b, 0, 0, 1
		for _ = 1, 4 do
			local u, v = CuratorOctoFull.Mod(x , 2), CuratorOctoFull.Mod(y , 2)
			if u ~= v then
				r1 = r1 + p
			end
			if u == 1 and v == 1 then
				r2 = r2 + p
			end
			x, y, p = (x - u) / 2, (y - v) / 2, p * 2
		end
		X4[a * 16 + b] = r1
		A4[a * 16 + b] = r2
	end
end
local function Op(t, a, b)
	local r, p = 0, 1
	for _ = 1, 8 do
		local x, y = CuratorOctoFull.Mod(a , 16), CuratorOctoFull.Mod(b , 16)
		r = r + t[x * 16 + y] * p
		a, b, p = (a - x) / 16, (b - y) / 16, p * 16
	end
	return r
end
local bxor = function(a, b)
	return Op(X4, a, b)
end
local band = function(a, b)
	return Op(A4, a, b)
end
-- (the bit library of the game, faster: only if it takes the words of 32 bits as they are)
local lib = rawget(_G, "bit")
if type(lib) == "table" and type(lib.bxor) == "function" and type(lib.band) == "function" then
	local x = function(a, b)
		return CuratorOctoFull.Mod(lib.bxor(a, b) , B32)
	end
	local n = function(a, b)
		return CuratorOctoFull.Mod(lib.band(a, b) , B32)
	end
	local ok, good = pcall(function()
		return x(4294967295, 2147483649) == 2147483646 and n(4294967295, 4042322160) == 4042322160 and x(305419896, 2596069104) == 2290649224
			and n(2147483648, 2147483648) == 2147483648
	end)
	if ok and good then
		bxor, band = x, n
	end
end
local function rrot(x, n)
	local p = 2 ^ n
	local low = CuratorOctoFull.Mod(x , p)
	return (x - low) / p + low * (B32 / p)
end
local function shr(x, n)
	return floor(x / 2 ^ n)
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

-- The SHA-256 of a text: its 32 bytes.
local function Sha256(msg)
	local len = CuratorOctoFull.Length(msg)
	msg = msg .. "\128" .. string.rep("\0", CuratorOctoFull.Mod((55 - len) , 64))
	local bits = len * 8
	local tail = {}
	for i = 8, 1, -1 do
		local b = CuratorOctoFull.Mod(bits , 256)
		tail[i] = string.char(b)
		bits = (bits - b) / 256
	end
	msg = msg .. table.concat(tail)
	local h = { 1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225 }
	local w = {}
	for start = 1, CuratorOctoFull.Length(msg), 64 do
		for i = 0, 15 do
			local b1, b2, b3, b4 = CuratorOctoFull.Byte(msg, start + i * 4, start + i * 4 + 3)
			w[i] = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
		end
		for i = 16, 63 do
			local x, y = w[i - 15], w[i - 2]
			local s0 = bxor(bxor(rrot(x, 7), rrot(x, 18)), shr(x, 3))
			local s1 = bxor(bxor(rrot(y, 17), rrot(y, 19)), shr(y, 10))
			w[i] = CuratorOctoFull.Mod((w[i - 16] + s0 + w[i - 7] + s1) , B32)
		end
		local a, b, c, d, e, f, g, hh = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
		for i = 0, 63 do
			local S1 = bxor(bxor(rrot(e, 6), rrot(e, 11)), rrot(e, 25))
			local ch = bxor(band(e, f), band(B32 - 1 - e, g))
			local t1 = CuratorOctoFull.Mod((hh + S1 + ch + K[i + 1] + w[i]) , B32)
			local S0 = bxor(bxor(rrot(a, 2), rrot(a, 13)), rrot(a, 22))
			local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
			local t2 = CuratorOctoFull.Mod((S0 + maj) , B32)
			hh, g, f, e, d, c, b, a = g, f, e, CuratorOctoFull.Mod((d + t1) , B32), c, b, a, CuratorOctoFull.Mod((t1 + t2) , B32)
		end
		h[1], h[2], h[3], h[4] = CuratorOctoFull.Mod((h[1] + a) , B32), CuratorOctoFull.Mod((h[2] + b) , B32), CuratorOctoFull.Mod((h[3] + c) , B32), CuratorOctoFull.Mod((h[4] + d) , B32)
		h[5], h[6], h[7], h[8] = CuratorOctoFull.Mod((h[5] + e) , B32), CuratorOctoFull.Mod((h[6] + f) , B32), CuratorOctoFull.Mod((h[7] + g) , B32), CuratorOctoFull.Mod((h[8] + hh) , B32)
	end
	local out = {}
	for i = 1, 8 do
		local v = h[i]
		for j = 4, 1, -1 do
			local b = CuratorOctoFull.Mod(v , 256)
			out[(i - 1) * 4 + j] = string.char(b)
			v = (v - b) / 256
		end
	end
	return table.concat(out)
end
F.Sha256 = Sha256

-------------------------------------------------------------------------------
-- The signature of the website: RSA, its exponent 3 (the numbers as limbs of 16 bits, the lowest first;
-- the products by Montgomery's way)
-------------------------------------------------------------------------------
local BASE = 65536

-- A number from its bytes (the highest first), on s limbs.
local function FromBytes(bytes, s)
	local out = {}
	local n = CuratorOctoFull.Length(bytes)
	for i = 1, s do
		local lo = n - (i - 1) * 2
		local b1 = lo >= 1 and CuratorOctoFull.Byte(bytes, lo) or 0
		local b2 = lo - 1 >= 1 and CuratorOctoFull.Byte(bytes, lo - 1) or 0
		out[i] = b2 * 256 + b1
	end
	return out
end

-- The bytes of a text of hexadecimal digits (nil: not one).
local function FromHex(hex)
	if type(hex) ~= "string" or CuratorOctoFull.Mod(CuratorOctoFull.Length(hex) , 2) ~= 0 or string.find(hex, "[^%x]") then
		return nil
	end
	return (string.gsub(hex, "%x%x", function(x)
		return string.char(tonumber(x, 16))
	end))
end
F.FromHex = FromHex

-- a >= b (s limbs)
local function GE(a, b, s)
	for i = s, 1, -1 do
		if a[i] ~= b[i] then
			return a[i] > b[i]
		end
	end
	return true
end

-- a · b · R⁻¹ mod n (R = BASE^s)
local function MonPro(a, b, n, n0, s)
	local t = {}
	for i = 1, s + 2 do
		t[i] = 0
	end
	for i = 1, s do
		local bi = b[i]
		local C = 0
		for j = 1, s do
			local x = t[j] + a[j] * bi + C
			C = floor(x / BASE)
			t[j] = x - C * BASE
		end
		local x = t[s + 1] + C
		C = floor(x / BASE)
		t[s + 1] = x - C * BASE
		t[s + 2] = t[s + 2] + C
		local m = CuratorOctoFull.Mod((t[1] * n0) , BASE)
		x = t[1] + m * n[1]
		C = floor(x / BASE)
		for j = 2, s do
			x = t[j] + m * n[j] + C
			C = floor(x / BASE)
			t[j - 1] = x - C * BASE
		end
		x = t[s + 1] + C
		C = floor(x / BASE)
		t[s] = x - C * BASE
		t[s + 1] = t[s + 2] + C
		t[s + 2] = 0
	end
	local r = {}
	for i = 1, s do
		r[i] = t[i]
	end
	if t[s + 1] > 0 or GE(r, n, s) then
		local borrow = 0
		for i = 1, s do
			local x = r[i] - n[i] - borrow
			if x < 0 then
				x, borrow = x + BASE, 1
			else
				borrow = 0
			end
			r[i] = x
		end
	end
	return r
end

local DIGEST_INFO = FromHex("3031300d060960864801650304020105000420")

-- A text signed with the key { n, r2 } (hexadecimal: the modulus, R² mod n), its signature (hexadecimal).
function F:Check(text, sigHex, key)
	if type(text) ~= "string" or type(key) ~= "table" then
		return false
	end
	local nb, sig = FromHex(key.n), FromHex(sigHex)
	local r2b = FromHex(key.r2)
	if not (nb and sig and r2b) or CuratorOctoFull.Length(nb) < 128 or CuratorOctoFull.Mod(CuratorOctoFull.Length(nb) , 2) ~= 0 or CuratorOctoFull.Length(sig) ~= CuratorOctoFull.Length(nb) or CuratorOctoFull.Length(r2b) > CuratorOctoFull.Length(nb) then
		return false
	end
	local s = CuratorOctoFull.Length(nb) / 2
	local n = FromBytes(nb, s)
	if CuratorOctoFull.Mod(n[1] , 2) == 0 then
		return false
	end
	local x = FromBytes(sig, s)
	if GE(x, n, s) then
		return false
	end
	-- (n0 = -n⁻¹ mod BASE, by Newton)
	local n1 = n[1]
	local inv = n1
	for _ = 1, 5 do
		inv = CuratorOctoFull.Mod((inv * (CuratorOctoFull.Mod((2 - CuratorOctoFull.Mod((n1 * inv) , BASE)) , BASE))) , BASE)
	end
	local n0 = CuratorOctoFull.Mod((BASE - inv) , BASE)
	local one = { 1 }
	for i = 2, s do
		one[i] = 0
	end
	local xm = MonPro(x, FromBytes(r2b, s), n, n0, s)
	local x3 = MonPro(MonPro(xm, xm, n, n0, s), xm, n, n0, s)
	local y = MonPro(x3, one, n, n0, s)
	-- (what it must be: 00 01 FF...FF 00, the digest info of SHA-256, the hash)
	local want = FromBytes("\0\1" .. string.rep("\255", CuratorOctoFull.Length(nb) - 3 - CuratorOctoFull.Length(DIGEST_INFO) - 32) .. "\0" .. DIGEST_INFO .. Sha256(text), s)
	for i = 1, s do
		if y[i] ~= want[i] then
			return false
		end
	end
	return true
end

-------------------------------------------------------------------------------
-- (1.14.2) The week of the news, for the app. The app of Curator asks the website for its news (the pass of the player
-- first, then the news of the Exchange and the bans of the week: Pass.lua, Market.lua, Bans.lua) only for the weeks of
-- the front a save holds (launcher, front.ts: frontOfSave, CuratorDB.pvp.front.w). The PvP gone with 1.14.0 (Pvp.lua)
-- and emptied at the release of OctoWoW, no save held one any more, and no app asked: no pass, so no trade and no
-- sale to the reseller, and no ban nor news of the Exchange in the game. At each logout, before the seal (Core.lua:
-- LOGOUT), the week of now is written there again, and nothing else: { w = the next weekly reset, in tens of minutes },
-- as the app and the website count the weeks (lib/front.ts). Not in a save edited outside the game: the app asks
-- nothing for one.
-------------------------------------------------------------------------------
-- The week of now (the next weekly reset, in tens of minutes), or nil: the game does not say when it is.
function F.Week(now)
	local C = C_DateAndTime
	local ok, left = pcall(function()
		return C and C.GetSecondsUntilWeeklyReset and C.GetSecondsUntilWeeklyReset()
	end)
	if not ok or type(left) ~= "number" or left ~= left or left < 0 or left > 8 * 86400 then
		return nil
	end
	now = now or (GetServerTime and CuratorOctoFull.ServerTime()) or time()
	if type(now) ~= "number" then
		return nil
	end
	return floor((now + left) / 600 + 0.5)
end

ns.On("LOGOUT", function()
	local db = ns.db
	if type(db) ~= "table" or db.edited then
		return
	end
	local w = F.Week()
	if not w then
		return
	end
	if type(db.pvp) ~= "table" then
		db.pvp = {}
	end
	local f = db.pvp.front
	if not (type(f) == "table" and f.w == w) then
		db.pvp.front = { w = w }
	end
end)
