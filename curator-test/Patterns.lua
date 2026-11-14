local _, ns = "Curator", CuratorOctoFull

-- (1.14.0, his idea: "pimenter les Titanforged") The pattern of a titanforged copy, as the patterns of the skins of CS2:
-- a number drawn once, from 1 to 19683 (1 to 300 before), that gives the copy a look of its own and is written on it, small ("Pattern 245").
-- What it changes, on the layers a titanforged card already has (UI/Card.lua): the colours of the foil of its frame and of
-- its window (the foil of prism of all the colours, or the same foil without its colours, lit by those of the pattern),
-- how its light goes round (its speed, its way, how sharp its flashes are), the light along its edge, its dust of stars,
-- the light behind its creature and the light on it, the stars and the motes over it, the sweep and the twinkles; and
-- the metal of its frame (TitanGold: the gold of the frame of the titans, the same on the six, in grey, lit in the colour
-- of its metal: silver, platinum, copper...). The frame keeps the enamel of its rarity.
-- First twelve looks (P.LOOKS), each the base of a family; a number past twelve takes the look of its family (the numbers
-- go round them), a little its own: its speed, where its light starts, the order of its colours.
-- The number of each titanforged copy: drawn when it comes, kept with it, carried in a trade and at the Bourse
-- (Copies.lua: pt; Trade.lua; Market.lua); shown wherever the copy is (UI/Card.lua: opts.pattern).

local P = {}
ns.Patterns = P

-- (31 October, his wish: titanforged copies always different) 19683: each number its own foils, those of its window,
-- of its frame and of its dust (P.HOLO variants of each, 27 x 27 x 27: 30 at first, then the bubbles, the rings, the
-- crosses, the hearts and the drops taken out, his word), and the look of its family.
P.MAX = 19683
P.HOLO = 27

-- tint: the foil without its colours, lit by these, one after the other as its light goes round (none: the foil of
-- prism as it is, all its colours); speed, dir: how fast its light goes round, which way; sharp: how sharp its lights
-- are (2: as the prism; more: brief flashes; less: soft); power: how bright the foil of the frame is, window: the one of
-- the window; dust, dustSpeed: its dust of stars, how bright, how fast it glitters; glory: the light behind the
-- creature, how bright (gs1, gs2: how fast its two wheels turn); glints: the colours of the stars and the motes over
-- the creature (none: those of the prism); spark: the colour of the twinkles and of the sweep; metal: the colour of the
-- metal of its frame (none: its gold).
P.LOOKS = {
	-- 1. Prism: the titanforged card as it was, all the colours of the prism
	{},
	-- 2. Gold
	{
		tint = { { 1, 0.78, 0.3 }, { 1, 0.93, 0.62 }, { 1, 0.64, 0.18 } },
		speed = 0.8, dust = 1.25,
		glints = { { 1, 0.95, 0.75 }, { 1, 0.82, 0.38 }, { 1, 0.7, 0.25 }, { 1, 1, 0.9 } },
		spark = { 1, 0.86, 0.5 },
	},
	-- 3. Ruby
	{
		tint = { { 1, 0.1, 0.2 }, { 1, 0.42, 0.5 }, { 0.82, 0.04, 0.16 } },
		sharp = 3, power = 1.1,
		glints = { { 1, 0.85, 0.88 }, { 1, 0.3, 0.38 }, { 1, 0.5, 0.58 }, { 0.95, 0.15, 0.25 } },
		spark = { 1, 0.6, 0.65 },
		metal = { 1, 0.68, 0.6 },
	},
	-- 4. Emerald
	{
		tint = { { 0.12, 1, 0.42 }, { 0.38, 1, 0.8 }, { 0.04, 0.78, 0.32 } },
		glints = { { 0.85, 1, 0.9 }, { 0.3, 1, 0.55 }, { 0.45, 1, 0.85 }, { 0.15, 0.85, 0.4 } },
		spark = { 0.65, 1, 0.78 },
		metal = { 0.82, 0.96, 0.58 },
	},
	-- 5. Sapphire
	{
		tint = { { 0.18, 0.4, 1 }, { 0.42, 0.82, 1 }, { 0.1, 0.22, 0.95 } },
		glints = { { 0.85, 0.92, 1 }, { 0.35, 0.6, 1 }, { 0.5, 0.88, 1 }, { 0.25, 0.35, 1 } },
		spark = { 0.68, 0.84, 1 },
		metal = { 0.74, 0.84, 1 },
	},
	-- 6. Amethyst
	{
		tint = { { 0.6, 0.28, 1 }, { 0.96, 0.42, 1 }, { 0.4, 0.18, 0.95 } },
		glints = { { 0.95, 0.85, 1 }, { 0.7, 0.4, 1 }, { 1, 0.5, 0.95 }, { 0.5, 0.3, 1 } },
		spark = { 0.86, 0.66, 1 },
		metal = { 0.9, 0.8, 1 },
	},
	-- 7. Mother of pearl: soft lights of every pale colour, a lot of dust
	{
		tint = { { 1, 0.78, 0.9 }, { 0.76, 0.94, 1 }, { 0.88, 0.8, 1 }, { 0.8, 1, 0.88 } },
		speed = 0.6, sharp = 1.5, power = 1.15, dust = 1.6,
		glints = { { 1, 0.95, 0.98 }, { 1, 0.85, 0.92 }, { 0.85, 0.95, 1 }, { 0.92, 1, 0.94 } },
		spark = { 1, 0.96, 0.96 },
		metal = { 1, 0.94, 0.95 },
	},
	-- 8. Aurora: the green, the blue and the violet of the northern lights, slow
	{
		tint = { { 0.18, 1, 0.52 }, { 0.2, 0.84, 1 }, { 0.62, 0.36, 1 } },
		speed = 0.5, sharp = 1.6, gs1 = 0.05, gs2 = -0.08,
		glints = { { 0.4, 1, 0.65 }, { 0.35, 0.9, 1 }, { 0.7, 0.5, 1 }, { 0.9, 1, 0.95 } },
		spark = { 0.6, 1, 0.85 },
		metal = { 0.64, 0.74, 0.8 },
	},
	-- 9. Blaze: the red, the orange and the gold of a fire, quick, in flashes
	{
		tint = { { 1, 0.22, 0.04 }, { 1, 0.58, 0.08 }, { 1, 0.86, 0.28 } },
		speed = 1.8, sharp = 4, power = 1.15, dustSpeed = 1.8, glory = 1.2, gs1 = 0.22, gs2 = -0.34,
		glints = { { 1, 0.9, 0.6 }, { 1, 0.55, 0.15 }, { 1, 0.35, 0.08 }, { 1, 0.75, 0.3 } },
		spark = { 1, 0.7, 0.36 },
		metal = { 1, 0.6, 0.36 },
	},
	-- 10. Glacier: ice and white, slow, a lot of dust
	{
		tint = { { 0.52, 0.88, 1 }, { 1, 1, 1 }, { 0.7, 0.95, 1 } },
		speed = 0.45, dust = 1.8, gs1 = 0.04, gs2 = -0.06,
		glints = { { 1, 1, 1 }, { 0.75, 0.95, 1 }, { 0.6, 0.85, 1 }, { 0.9, 1, 1 } },
		spark = { 0.86, 0.96, 1 },
		metal = { 0.95, 0.99, 1 },
	},
	-- 11. Twilight: the pink, the orange and the gold of a sky at dusk, and its violet
	{
		tint = { { 1, 0.3, 0.68 }, { 1, 0.55, 0.28 }, { 1, 0.82, 0.4 }, { 0.74, 0.3, 0.92 } },
		speed = 0.9,
		glints = { { 1, 0.6, 0.8 }, { 1, 0.7, 0.4 }, { 1, 0.9, 0.55 }, { 0.8, 0.5, 1 } },
		spark = { 1, 0.75, 0.7 },
		metal = { 1, 0.64, 0.82 },
	},
	-- 12. Black pearl: a deep violet, dark, and stars of a bright white
	{
		tint = { { 0.34, 0.18, 0.58 }, { 0.14, 0.18, 0.46 }, { 0.48, 0.24, 0.62 } },
		speed = 0.7, power = 0.8, window = 0.75, dust = 2.1, glory = 0.6,
		glints = { { 1, 1, 1 }, { 0.92, 0.88, 1 }, { 0.8, 0.75, 1 }, { 1, 1, 1 } },
		spark = { 0.92, 0.88, 1 },
		metal = { 0.36, 0.34, 0.42 },
	},
}

-- A number as written on a card: 1 to P.MAX (else none).
function P.Number(n)
	n = tonumber(n)
	if not n then
		return nil
	end
	n = math.floor(n)
	if n < 1 or n > P.MAX then
		return nil
	end
	return n
end

-- (a number from 0 to 1 of a pattern and a salt: the same each time)
local function Frac(n, salt)
	local x = math.sin(n * 12.9898 + salt * 78.233) * 43758.5453
	return x - math.floor(x)
end

local cache = {}

-- The look of a pattern (nil: none, or not a number of a pattern), every field set.
function P:Look(n)
	n = P.Number(n)
	if not n then
		return nil
	end
	local had = cache[n]
	if had then
		return had
	end
	local count = CuratorOctoFull.Length(self.LOOKS)
	local family = CuratorOctoFull.Mod((n - 1) , count) + 1
	local base = self.LOOKS[family]
	local own = n > count
	local look = {
		n = n,
		family = family,
		speed = (base.speed or 1) * (own and (0.8 + 0.4 * Frac(n, 1)) or 1),
		dir = (own and Frac(n, 2) < 0.5) and -1 or 1,
		phase = own and Frac(n, 3) * math.pi * 2 or 0,
		sharp = base.sharp or 2,
		-- (a foil without its colours is less bright: a little more of it, unless the look says otherwise; its edge too)
		power = base.power or (base.tint and 1.35 or 1),
		rim = base.tint and 1.3 or 1,
		window = base.window or 1,
		dust = base.dust or 1,
		dustSpeed = base.dustSpeed or 1,
		glory = base.glory or 1,
		gs1 = base.gs1 or 0.1,
		gs2 = base.gs2 or -0.17,
		glints = base.glints,
		spark = base.spark,
		metal = base.metal,
	}
	-- (its foils: a variant of each, 1 the ones of before; the numbers spread over the 19683 so that two numbers that
	-- follow share none of them: 7919 is prime to 19683, the 1 keeps the foils of before)
	local h = self.HOLO
	local m = CuratorOctoFull.Mod(((n - 1) * 7919) , (h * h * h))
	look.wv = CuratorOctoFull.Mod(m , h) + 1
	look.pv = CuratorOctoFull.Mod(math.floor(m / h) , h) + 1
	look.dv = math.floor(m / (h * h)) + 1
	if base.tint then
		-- (its colours, in an order of its own past the twelve)
		local t, k = {}, CuratorOctoFull.Length(base.tint)
		local shift = own and math.floor(Frac(n, 4) * k) or 0
		for i = 1, k do
			t[i] = base.tint[CuratorOctoFull.Mod((i - 1 + shift) , k) + 1]
		end
		look.tint = t
	end
	cache[n] = look
	return look
end

-- The colour of a look at a point of the round of its light (u from 0 to 1): its colours one after the other, each
-- melting into the next.
function P.Color(look, u)
	local t = look.tint
	local k = CuratorOctoFull.Length(t)
	local x = (CuratorOctoFull.Mod(u , 1)) * k
	local i = math.floor(x)
	local f = x - i
	-- (soft on both ends)
	f = f * f * (3 - 2 * f)
	local a, b = t[i + 1], t[CuratorOctoFull.Mod((i + 1) , k) + 1]
	return a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f
end
