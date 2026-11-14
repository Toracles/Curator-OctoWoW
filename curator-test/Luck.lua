local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.10.0) The luck of a collector: from the boosters opened since 1.10.0, the epic, legendary and mythic
-- cards they gave against what the odds of the boosters (without the talents) let expect, and the boosters
-- opened since the last legendary and the last mythic. Kept in db.luck: e, l, m (the cards), xe, xl, xm (what
-- was expected, in thousandths), sl, sm (the boosters since), n (the boosters counted). Shown on the page of the
-- statistics (UI/Rates.lua); (1.14.0, after its test, his word) no more on the profile, nor sent to the players who
-- look at it (its message, J: still read, from a copy of before).
-------------------------------------------------------------------------------
local LK = {}
ns.Luck = LK

-- What a booster lets expect, in thousandths of a card: { epic, legendary, mythic } (a zone: 8 cards, 1.14.0, 10
-- before: { 120, 25, 5 }; a sealed booster: 5 cards and its last boss now and then; a golden booster: 5 cards,
-- Golden.lua).
LK.EXPECT = {
	zone = { 96, 20, 4 },
	sealed = { 500, 50, 5 },
	golden = { 3400, 1510, 90 },
}

function LK:Db()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.luck) ~= "table" then
		db.luck = { e = 0, l = 0, m = 0, xe = 0, xl = 0, xm = 0, sl = 0, sm = 0, n = 0 }
	end
	return db.luck
end

-- A booster opened: what it gave, what it let expect.
function LK:Opened(s, picks)
	local d = self:Db()
	if not (d and s and type(picks) == "table") then
		return
	end
	local kind = picks.golden and "golden" or (s.dungeon and "sealed" or "zone")
	local x = self.EXPECT[kind]
	d.xe, d.xl, d.xm = (d.xe or 0) + x[1], (d.xl or 0) + x[2], (d.xm or 0) + x[3]
	local leg, myth = false, false
	for _, p in ipairs(picks) do
		local r = p.card and p.card.rarity or 0
		if r == 4 then
			d.e = (d.e or 0) + 1
		elseif r == 5 then
			d.l = (d.l or 0) + 1
			leg = true
		elseif r >= 6 then
			d.m = (d.m or 0) + 1
			leg, myth = true, true
		end
	end
	d.n = (d.n or 0) + 1
	d.sl = leg and 0 or ((d.sl or 0) + 1)
	d.sm = myth and 0 or ((d.sm or 0) + 1)
end

ns.On("BOOSTER_OPENED", function(s, picks)
	LK:Opened(s, picks)
end)

-- The luck as a short code (integers, by dots), and back.
function LK:Code(d)
	d = d or self:Db()
	if not d then
		return nil
	end
	local f = {}
	for _, k in ipairs({ "e", "l", "m", "xe", "xl", "xm", "sl", "sm", "n" }) do
		f[CuratorOctoFull.Length(f) + 1] = math.max(0, math.min(99999999, math.floor(tonumber(d[k]) or 0)))
	end
	return table.concat(f, ".")
end

function LK.Parse(code)
	if type(code) ~= "string" or CuratorOctoFull.Length(code) > 120 or not CuratorOctoFull.Match(code, "^[%d%.]+$") then
		return nil
	end
	local f = {}
	for v in CuratorOctoFull.Gmatch(code, "%d+") do
		f[CuratorOctoFull.Length(f) + 1] = tonumber(v)
	end
	if CuratorOctoFull.Length(f) < 9 then
		return nil
	end
	return { e = f[1], l = f[2], m = f[3], xe = f[4], xl = f[5], xm = f[6], sl = f[7], sm = f[8], n = f[9] }
end

-- (Abramowitz and Stegun, 7.1.26: the error function, to 1.5e-7)
local function Erf(x)
	local sign = x < 0 and -1 or 1
	x = math.abs(x)
	local t = 1 / (1 + 0.3275911 * x)
	local y = 1 - ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * math.exp(-x * x)
	return sign * y
end

-- The chance that a count with lambda expected (a law of Poisson) is k at most: exact up to 100 expected, else
-- by the normal law (its half unit included).
function LK.AtMost(k, lambda)
	if k < 0 then
		return 0
	end
	if lambda <= 0 then
		return 1
	end
	if lambda > 100 then
		return 0.5 * (1 + Erf((k + 0.5 - lambda) / math.sqrt(2 * lambda)))
	end
	local term = math.exp(-lambda)
	local sum = term
	for i = 1, k do
		term = term * lambda / i
		sum = sum + term
	end
	return math.min(1, sum)
end

-- The word for a luck (nil: too few boosters, less than a legendary card expected), and how many times what
-- was expected came: the legendary and mythic cards against what the odds let expect, as a chance. So many or
-- more, 1 time in 10 at most: blessed by the gods; 3 in 10: lucky. So few or fewer, 1 in 10: cursed; 3 in 10:
-- unlucky. Else right on the odds (a few boosters can never say much).
function LK.Verdict(d)
	if not d then
		return nil
	end
	local lambda = ((d.xl or 0) + (d.xm or 0)) / 1000
	if lambda < 1 then
		return nil
	end
	local k = math.floor((d.l or 0) + (d.m or 0))
	local ratio = k / lambda
	local more = 1 - LK.AtMost(k - 1, lambda)
	local fewer = LK.AtMost(k, lambda)
	if more <= 0.1 then
		return "Blessed by the gods", ratio
	elseif more <= 0.3 then
		return "Lucky", ratio
	elseif fewer <= 0.1 then
		return "Cursed", ratio
	elseif fewer <= 0.3 then
		return "Unlucky", ratio
	end
	return "Right on the odds", ratio
end

-- Sent after the profile (Comm.lua); read from the others, kept with what they showed.
function LK:Message()
	local code = self:Code()
	return code and string.format(("J:%s:%s"), ns.Guild.VERSION, code) or nil
end

ns.Guild:Handle("J", function(body, channel, sender)
	local d = LK.Parse(body)
	if not d then
		return
	end
	local m = ns.Guild:Store(sender, channel)
	m.luck = d
	ns.Fire("PLAYER_INFO", sender)
end)

-- The luck another player showed (nil: none yet).
function LK:Of(name)
	local m = ns.Guild:Player(name)
	return m and m.luck or nil
end
