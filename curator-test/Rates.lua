local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.15.0) The statistics of Curator: every rate as the draws make it, for everyone (without a talent) and for this
-- collector (with the talents it has learned), and the talents that change each one. The page of the statistics
-- shows them (UI/Rates.lua). Every number comes from the functions the draws themselves use (Collection.lua: C:Odds;
-- Talents.lua: TL:BoosterMods, TL:FindChance, TL:FoundFinish, TL:BarPoints, TL:ContractSize; Rewards.lua: its points
-- and its chances; Expertise.lua: E:Odds): never written twice, the page cannot say other than the draws do.
-- A rate: { base, value, mods } (base: for everyone; value: with the talents; mods: the talents that change it, each
-- { id, name, rank, ranks, value, icon, text, add } (add: what it adds, as the talent writes it), in their order).
-------------------------------------------------------------------------------
local RT = {}
ns.Rates = RT

local function TL()
	return ns.Talents
end

-- A talent this collector has learned (of the specialization it plays), or nil.
function RT:Talent(id)
	local T = TL()
	local d = T and T.BY[id]
	if not d then
		return nil
	end
	local rank = T:Rank(id)
	if rank <= 0 then
		return nil
	end
	local value = T:Value(id, rank)
	return { id = id, def = d, name = T:Name(id), rank = rank, ranks = d.ranks, value = value, icon = d.icon, text = T:Text(id, rank),
		add = d.fmt and T:Format(d, value) or nil }
end

-- The talents of a list this collector has learned.
function RT:Learned(ids)
	local out = {}
	for _, id in ipairs(ids or {}) do
		local t = self:Talent(id)
		if t then
			out[CuratorOctoFull.Length(out) + 1] = t
		end
	end
	return out
end

local function Rate(base, value, mods)
	return { base = base or 0, value = value or base or 0, mods = mods or {} }
end
RT.Rate = Rate

-- The specialization played and the points of the talents: { key, name, points, spent } (key nil: none chosen yet).
function RT:Spec()
	local T = TL()
	if not T then
		return {}
	end
	local key = T:Spec()
	return { key = key, name = key and T:SpecName(key, T.Female and T:Female()) or nil, points = T:Points(), spent = T:Spent() }
end

-------------------------------------------------------------------------------
-- The boosters
-------------------------------------------------------------------------------
-- (1.14.0) The talents that change the chance of each rarity, in a booster (Talents.lua, TL:BoosterMods): Hot Hand, the
-- Gambler's, after an epic card or better.
RT.RARITY_TALENTS = {
	[4] = { "hothand" },
}
-- What else the talents of the Gambler do to the boosters: no chance of a rarity, but a card raised, a booster
-- thunderforged, a bet, a booster of legend.
RT.BOOSTER_EFFECTS = { "stake", "streak", "jackpot", "loaded", "double", "relance", "highroller", "careful", "nerves", "landplayer", "lairplayer",
	"grandgame", "displaybox" }

-- The kinds of booster the page shows, and the album of each it shows first (the one of this place, else the
-- last one seen there, else the first of its kind).
-- (1.14.0, after the test of the cases, his word: no more Hallow's End here, nor its corrupted cards)
RT.KINDS = { "zone", "dungeon" }

function RT:KindOf(s)
	return (s.dungeon and "dungeon") or (s.event and "event") or "zone"
end

-- The albums of a kind, in their order (an event: while it lasts).
function RT:Albums(kind)
	local out = {}
	for _, s in ipairs(ns.Series or {}) do
		if self:KindOf(s) == kind and not s.limited and CuratorOctoFull.Length(s.list) > 0 then
			if kind ~= "event" or (ns.Hallow and ns.Hallow.On and ns.Hallow:On() and s.key == ns.Hallow.KEY) then
				out[CuratorOctoFull.Length(out) + 1] = s
			end
		end
	end
	return out
end

-- The experience of a card drawn, by its rarity, and of its finish (Level.lua), without the talents.
local function CardXP(r, forged, finish)
	local LV = ns.Level
	if not LV then
		return 0
	end
	local xp = LV.RARITY[r] or 0
	if finish == "holo" then
		xp = xp + (LV.FINISH[forged and "titan" or "holo"] or 0)
	elseif finish == "shiny" then
		xp = xp + (LV.FINISH[forged and "thunder" or "shiny"] or 0)
	end
	return xp
end

-- What a booster of an album gives, for everyone and with the talents. ctx: { hot } (Hot Hand: after an epic card or
-- better; nil: as now).
function RT:Booster(s, ctx)
	local C, T = ns.Collection, TL()
	ctx = ctx or {}
	local gambler = T ~= nil and T:Spec() == "gambler"
	local hot = ctx.hot
	if hot == nil then
		local st = T and T.State and ns.db and ns.db.talents
		hot = type(st) == "table" and (tonumber(st.hot) or 0) > 0 or false
	end
	-- (the talents of each booster of the day, the first ones: not counted here, they are among its effects)
	local base, now = C:Odds(s, true), C:Odds(s, false, { hot = hot, first = false, firstFive = false, preview = true })
	local out = { series = s, kind = self:KindOf(s), rows = {}, hot = hot }
	local rest = s.dungeon and 3 or 1
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		local b, v = base.rar[r] or 0, now.rar[r] or 0
		if b > 0 or v > 0 then
			local mods = {}
			for _, t in ipairs(gambler and self:Learned(self.RARITY_TALENTS[r]) or {}) do
				if t.id ~= "hothand" or hot then
					mods[CuratorOctoFull.Length(mods) + 1] = t
				end
			end
			local row = Rate(b, v, mods)
			row.r, row.rest = r, r == rest
			out.rows[CuratorOctoFull.Length(out.rows) + 1] = row
		end
	end
	out.cards = Rate(base.cards, base.cards, {})
	out.cards.whole = base.cards
	-- (a zone, an event: a rare card or better in so many boosters; a dungeon, a raid: its last boss)
	if s.dungeon then
		out.mythic = Rate(base.mythic or 0, now.mythic or 0, {})
	else
		local fine = 0
		for r = 3, CuratorOctoFull.Length(ns.RARITY) do
			fine = fine + (now.rar[r] or 0)
		end
		out.rare = Rate(base.rareBooster or 0, 1 - (1 - fine) ^ base.cards, {})
		for _, row in ipairs(out.rows) do
			if row.r >= 3 then
				for _, t in ipairs(row.mods) do
					out.rare.mods[CuratorOctoFull.Length(out.rare.mods) + 1] = t
				end
			end
		end
		out.rare.cards = base.cards
	end
	-- the finishes of each card (an event: corrupted now and then, never forged). Flourish: the epic cards and better
	-- thunderforged more often (Collection.lua, C:RollFinish)
	local epic = 0
	for r = 4, CuratorOctoFull.Length(ns.RARITY) do
		epic = epic + (now.rar[r] or 0)
	end
	if s.event then
		out.corrupt = Rate(base.corrupt or 0, now.corrupt or 0, {})
		out.corrupt.pack = Rate(base.corruptPack or 0, now.corruptPack or 0, {})
	else
		local flourish = gambler and self:Talent("flourish") or nil
		local thunder = Rate(base.shiny, now.shiny + (flourish and flourish.value * epic or 0), flourish and { flourish } or {})
		local titan = Rate(base.holo, now.holo, {})
		thunder.key, titan.key = "thunder", "titan"
		for _, f in ipairs({ thunder, titan }) do
			f.pack = Rate(1 - (1 - f.base) ^ base.cards, 1 - (1 - f.value) ^ base.cards, f.mods)
		end
		out.finishes = { thunder, titan }
	end
	-- the experience of a booster on average (Level.lua: each card by its rarity, more for its finish; the talents
	-- of the Gambler: Adrenaline Rush, every card, twice as much for an epic card or better; Thrills, the forged ones)
	local forged = s.dungeon or s.event
	local rush = gambler and self:Talent("rush") or nil
	local thrills = gambler and self:Talent("thrills") or nil
	local function XP(odds, pS, pH, cards, talents)
		local dS = CardXP(1, forged, "shiny") - CardXP(1, forged, nil)
		local dH = CardXP(1, forged, "holo") - CardXP(1, forged, nil)
		local per = 0
		for r = 1, CuratorOctoFull.Length(ns.RARITY) do
			local p = odds.rar[r] or 0
			if p > 0 then
				local x = CardXP(r, forged, nil)
				local k = 1
				if talents and rush then
					k = k + rush.value * (r >= 4 and 2 or 1)
				end
				local fin = pS * dS + pH * dH
				local thr = (talents and thrills) and thrills.value * (pS * (x + dS) + pH * (x + dH)) or 0
				per = per + p * ((x + fin) * k + thr)
			end
		end
		-- (an event: its corrupted cards)
		if odds.corrupt and ns.Level then
			per = per + odds.corrupt * (ns.Level.FINISH.corrupt or 0)
		end
		return per * cards
	end
	local mods = {}
	for _, t in ipairs({ rush, thrills }) do
		if t then
			mods[CuratorOctoFull.Length(mods) + 1] = t
		end
	end
	local fS, fH = (out.finishes and out.finishes[1].value) or 0, (out.finishes and out.finishes[2].value) or 0
	out.xp = Rate(XP(base, (not s.event) and base.shiny or 0, (not s.event) and base.holo or 0, base.cards, false),
		XP(now, fS, fH, base.cards, true), mods)
	-- (Fresh Ink, the Cartographer's: more for the cards the album of a zone is missing, not counted there)
	out.fresh = (not s.dungeon and not s.event) and self:Talent("freshink") or nil
	-- what else the talents do to the boosters
	out.effects = {}
	for _, t in ipairs(gambler and self:Learned(self.BOOSTER_EFFECTS) or {}) do
		local skip = (t.id == "lairplayer" and not s.dungeon) or (t.id == "landplayer" and s.dungeon)
		if not skip then
			out.effects[CuratorOctoFull.Length(out.effects) + 1] = t
		end
	end
	out.can = { hot = gambler and self:Talent("hothand") ~= nil }
	return out
end

-------------------------------------------------------------------------------
-- The cards found on the creatures
-------------------------------------------------------------------------------
-- The talents that change the chance to find a card (Talents.lua, TL:FindChance), each with what it needs: an elite
-- or a rare (or a boss), a legendary card or better, a boss of a raid, the creature marked, the first elite of the
-- hour, a Survey or an Expedition that runs.
local FIND_TALENTS = {
	{ id = "quarry", when = "elite" },
	{ id = "biggame", when = "legend" },
	{ id = "bigbore", when = "raidboss" },
	{ id = "mark", when = "mark", add = "x3" },
	{ id = "firstblood", when = "firstblood", add = "x2" },
	{ id = "survey", when = "survey", add = "x2" },
	{ id = "expedition", when = "expedition", add = "x3" },
}

-- The chances to find the card of a creature defeated, by the rarity of its card: a creature of the world (or of a
-- dungeon), a boss. ctx: { elite, rare, raid, mark, firstblood, survey, expedition } (nil: as now; Survey: a card the
-- album of the zone is missing).
function RT:Creatures(ctx)
	local R, T = ns.Rewards, TL()
	ctx = ctx or {}
	local spec = T and T:Spec()
	local hunter, carto = spec == "hunter", spec == "carto"
	local function On(key, now)
		if ctx[key] ~= nil then
			return ctx[key] and true or false
		end
		return now and true or false
	end
	local survey = carto and On("survey", T:SurveyLeft() > 0)
	local exped = carto and On("expedition", T:ExpeditionLeft() > 0)
	local mark = hunter and On("mark", false)
	local first = hunter and On("firstblood", T.FirstBlood and T:FirstBlood())
	local function Mods(r, boss, elite, rare, raid)
		local out = {}
		if not (hunter or carto) then
			return out
		end
		for _, x in ipairs(FIND_TALENTS) do
			local ok = (x.when == "elite" and (elite or rare or boss)) or (x.when == "legend" and r >= 5) or (x.when == "raidboss" and boss and raid)
				or (x.when == "mark" and mark) or (x.when == "firstblood" and first and elite and not boss)
				or (x.when == "survey" and survey) or (x.when == "expedition" and exped)
			local t = ok and self:Talent(x.id) or nil
			if t then
				if x.add then
					t.add = x.add
				end
				out[CuratorOctoFull.Length(out) + 1] = t
			end
		end
		return out
	end
	local function Chance(b, r, boss)
		if not (hunter or carto) then
			return b
		end
		return T:FindChance(b, { rarity = r }, { elite = ctx.elite or boss, boss = boss, raid = boss and ctx.raid or nil, rare = ctx.rare,
			mark = mark, firstblood = first, survey = survey, expedition = exped })
	end
	local out = { rows = {}, boss = {}, talents = hunter or carto, hunter = hunter, carto = carto }
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		local b = R.FIND[r] or 0
		local row = Rate(b, Chance(b, r, false), Mods(r, false, ctx.elite, ctx.rare))
		row.r = r
		out.rows[CuratorOctoFull.Length(out.rows) + 1] = row
	end
	for r = 3, CuratorOctoFull.Length(ns.RARITY) do
		local b = R.FIND_BOSS[r] or R.FIND[r] or 0
		local row = Rate(b, Chance(b, r, true), Mods(r, true, true, ctx.rare, ctx.raid))
		row.r = r
		out.boss[CuratorOctoFull.Length(out.boss) + 1] = row
	end
	-- the finishes of a card found (the albums of the dungeons and the raids: forged more often): Mounted Heads, the
	-- elites and the bosses; Necklace of Teeth, the bosses; Raid Relics, the bosses of the raids
	local C = ns.Collection
	local function Finishes(top, second, fctx)
		local t2, s2 = top, second
		if hunter then
			t2, s2 = T:FoundFinish(top, second, fctx)
		end
		local mods = {}
		if hunter then
			if fctx.elite or fctx.boss then
				mods[CuratorOctoFull.Length(mods) + 1] = self:Talent("mounted")
			end
			if fctx.boss then
				mods[CuratorOctoFull.Length(mods) + 1] = self:Talent("teeth")
			end
		end
		local tmods = {}
		for _, t in ipairs(mods) do
			if t and t.id ~= "teeth" then
				tmods[CuratorOctoFull.Length(tmods) + 1] = t
			end
		end
		if hunter and fctx.boss and fctx.raid then
			tmods[CuratorOctoFull.Length(tmods) + 1] = self:Talent("relics")
		end
		local function Clean(list)
			local o = {}
			for _, t in ipairs(list) do
				if t then
					o[CuratorOctoFull.Length(o) + 1] = t
				end
			end
			return o
		end
		return { thunder = Rate(second, s2, Clean(mods)), titan = Rate(top, t2, Clean(tmods)) }
	end
	out.finishes = {
		zone = Finishes(C.ODDS.holo, C.ODDS.shiny, { elite = ctx.elite }),
		dungeon = Finishes(C.DUNGEON.titan, C.DUNGEON.thunder, { elite = true, boss = true, raid = ctx.raid }),
	}
	-- the summits that give a card, the Contract of the Day and its target
	out.gifts = {}
	for _, id in ipairs({ "terra", "dailyhead", "legendhead", "finds", "blanks" }) do
		local t = self:Talent(id)
		if t then
			out.gifts[CuratorOctoFull.Length(out.gifts) + 1] = t
		end
	end
	out.target = hunter and T:Has("dailyhead") and T:Ready("dailyhead") and T:DailyTarget() or nil
	-- the toggles of the page: the situations a talent learned makes a difference in
	out.can = {
		elite = hunter and (self:Talent("quarry") ~= nil or self:Talent("mounted") ~= nil or self:Talent("firstblood") ~= nil),
		rare = hunter and self:Talent("quarry") ~= nil,
		raid = hunter and (self:Talent("bigbore") ~= nil or self:Talent("relics") ~= nil),
		mark = hunter and self:Talent("mark") ~= nil,
		firstblood = hunter and self:Talent("firstblood") ~= nil,
		survey = carto and self:Talent("survey") ~= nil,
		expedition = carto and self:Talent("expedition") ~= nil,
	}
	out.on = { mark = mark, firstblood = first, survey = survey, expedition = exped }
	-- (1.12.0: Hallow's End, while it lasted, the card of its album of a creature; 1.14.0, his word: no more here)
	return out
end

-------------------------------------------------------------------------------
-- The booster bars
-------------------------------------------------------------------------------
-- The points of what the player does, on each bar (ns.PACK_POINTS make a booster), for everyone and with the
-- talents. ctx: { group } (nil: as now). The bar of the world as it fills in the zone of the player (its album).
function RT:Bars(ctx)
	local R, T = ns.Rewards, TL()
	local P = R.POINTS
	ctx = ctx or {}
	local spec = T and T:Spec()
	local carto, hunter = spec == "carto", spec == "hunter"
	local group = ctx.group
	if group == nil then
		group = T and T.InGroup and T.InGroup() or false
	end
	local zone = R.WorldSeries and R:WorldSeries() or nil
	local me = UnitLevel and UnitLevel("player") or nil
	local function Bar(points, reason, kind, extra)
		if not T then
			return points
		end
		local c = { s = zone, group = group, level = me }
		for k, v in pairs(extra or {}) do
			c[k] = v
		end
		return T:BarPoints(points, reason, kind, c)
	end
	-- (the talents of the bar of the world that count everything the player does there, and those of a reason)
	local WORLD = { "trails", "homeland", "nomad", "dew", "starry" }
	local function Mods(kind, ids)
		local out = {}
		if not spec then
			return out
		end
		local list = {}
		for _, id in ipairs(ids or {}) do
			list[CuratorOctoFull.Length(list) + 1] = id
		end
		if kind == "world" and carto then
			for _, id in ipairs(WORLD) do
				list[CuratorOctoFull.Length(list) + 1] = id
			end
		end
		for _, t in ipairs(self:Learned(list)) do
			-- (those that hold here only: the zone of the hearthstone, a zone not played for a while, half of its cards, the first
			-- hour of the day, the night during Survey)
			local keep = true
			if t.id == "trails" then
				keep = zone ~= nil and T.Share and T.Share(zone) < 0.5
			elseif t.id == "homeland" then
				keep = T:Homeland(zone)
			elseif t.id == "nomad" then
				keep = zone ~= nil and T.nomad == zone.key
			elseif t.id == "dew" then
				keep = T:FirstHour()
			elseif t.id == "starry" then
				keep = T:Night() and T:SurveyLeft() > 0
			elseif t.id == "beat" then
				keep = group
			end
			if keep then
				out[CuratorOctoFull.Length(out) + 1] = t
			end
		end
		return out
	end
	local function Row(key, base, value, mods)
		local row = Rate(base, value, mods)
		row.key = key
		return row
	end
	local world = {
		Row("kill", P.kill, Bar(P.kill, "kill", "world", { level = me }), Mods("world", carto and { "seasoned" } or nil)),
	}
	if hunter then
		world[CuratorOctoFull.Length(world) + 1] = Row("elite", P.kill, Bar(P.kill, "kill", "world", { elite = true }), Mods("world", { "beat", "stalker" }))
	end
	world[CuratorOctoFull.Length(world) + 1] = Row("objective", P.objective, Bar(P.objective, "objective", "world"), Mods("world", { "fieldbook" }))
	world[CuratorOctoFull.Length(world) + 1] = Row("quest", P.quest, Bar(P.quest, "quest", "world"), Mods("world", { "fieldbook" }))
	world[CuratorOctoFull.Length(world) + 1] = Row("explore", P.explore, Bar(P.explore, "explore", "world"), Mods("world", { "fieldbook" }))
	world[CuratorOctoFull.Length(world) + 1] = Row("level", P.level, Bar(P.level, "level", "world"), Mods("world"))
	-- (what fills it only with a talent: a gathering, a rare, an honorable kill)
	local forage = carto and self:Talent("forage") or nil
	if forage then
		world[CuratorOctoFull.Length(world) + 1] = Row("gather", 0, Bar(forage.value, "gather", "world"), { forage })
	end
	local pelts = hunter and self:Talent("pelts") or nil
	if pelts then
		world[CuratorOctoFull.Length(world) + 1] = Row("rare", 0, Bar(pelts.value, "kill", "world"), { pelts })
	end
	local dmods = hunter and self:Learned({ "deep" }) or {}
	local bmods = hunter and self:Learned({ "tally", "delver" }) or {}
	for _, t in ipairs(hunter and self:Learned({ "beat" }) or {}) do
		if group then
			dmods[CuratorOctoFull.Length(dmods) + 1] = t
			bmods[CuratorOctoFull.Length(bmods) + 1] = t
		end
	end
	local dungeon = {
		Row("dkill", P.dungeonKill, Bar(P.dungeonKill, "kill", "dungeon"), {}),
		Row("delite", P.elite, Bar(T and T:ElitePoints(P.elite, true) or P.elite, "kill", "dungeon", { elite = true }), dmods),
		Row("boss", P.boss, Bar(T and T:BossPoints(P.boss) or P.boss, "boss", "dungeon", { boss = true }), bmods),
		Row("final", P.final, Bar(T and T:FinalPoints(P.final) or P.final, "dungeon", "dungeon", { boss = true }), bmods),
	}
	local daily = Rate(R.DAILY, T and T:DailyMax(R.DAILY) or R.DAILY, {})
	-- what else the talents do to the bars
	local effects = self:Learned({ "roadbook", "dragonslayer", "raider", "sweep", "handshake", "philanthropist" })
	return { world = world, dungeon = dungeon, daily = daily, per = ns.PACK_POINTS, effects = effects, zone = zone,
		can = { group = hunter and self:Talent("beat") ~= nil },
		reroll = ns.Reroll and ns.Reroll.IsReroll and ns.Reroll:IsReroll() or false }
end

-------------------------------------------------------------------------------
-- The contracts, the expertise and the seals
-------------------------------------------------------------------------------
-- (1.14.0) What the talents of the Smuggler do to the contracts.
RT.CONTRACT_EFFECTS = { "paperwork", "forger", "goldcontract", "fineprint", "lionshare" }

-- The copies a contract takes, by their rarity (normal ones, then forged ones), and how many go at once.
function RT:Contracts()
	local K, T = ns.Contract, TL()
	local smuggler = T ~= nil and T:Spec() == "smuggler"
	local rows = {}
	for r = 1, K.LAST do
		local row = Rate(K.SIZE, K:SizeOf(r, "normal"), {})
		row.r = r
		rows[CuratorOctoFull.Length(rows) + 1] = row
	end
	local forged = Rate(K.SIZE, K:SizeOf(1, "shiny"), {})
	local max = Rate(K.MAX, K:Max(), {})
	local effects = smuggler and self:Learned(self.CONTRACT_EFFECTS) or {}
	return { rows = rows, forged = forged, max = max, effects = effects, top = K.TOP, size = K.SIZE }
end

-- The grades of an expertise (the chance of each: Perfectionist, a 9 becomes a 10 now and then) and the ranks of a
-- seal (Grand Seal: the ranks IX and X likelier).
function RT:Expertise()
	local E, SL = ns.Expertise, ns.Masters
	local out = { grades = {}, seals = {} }
	if E and E.ODDS then
		local base, now = E.ODDS, E:Odds()
		local tb, tn = 0, 0
		for i, o in ipairs(base) do
			tb, tn = tb + o[2], tn + ((now[i] and now[i][2]) or 0)
		end
		local perf = self:Talent("perfectionist")
		local p9 = 0
		for _, o in ipairs(now) do
			if o[1] == 9 then
				p9 = (o[2] or 0) / math.max(tn, 1e-9)
			end
		end
		for i, o in ipairs(base) do
			local v = ((now[i] and now[i][2]) or 0) / math.max(tn, 1e-9)
			local mods = {}
			if perf then
				if o[1] == 9 then
					v = v * (1 - perf.value)
					mods[1] = perf
				elseif o[1] == E.MAX then
					v = v + p9 * perf.value
					mods[1] = perf
				end
			end
			local row = Rate(o[2] / math.max(tb, 1e-9), v, mods)
			row.grade = o[1]
			out.grades[CuratorOctoFull.Length(out.grades) + 1] = row
		end
	end
	if SL and SL.ODDS then
		local now = SL.Odds and SL:Odds() or SL.ODDS
		local t, tn = 0, 0
		for i, o in ipairs(SL.ODDS) do
			t = t + o[2]
			tn = tn + ((now[i] and now[i][2]) or 0)
		end
		local grand = self:Talent("grandseal")
		for i, o in ipairs(SL.ODDS) do
			local row = Rate(o[2] / math.max(t, 1e-9), ((now[i] and now[i][2]) or 0) / math.max(tn, 1e-9), (grand and o[1] >= 9) and { grand } or {})
			row.rank = o[1]
			out.seals[CuratorOctoFull.Length(out.seals) + 1] = row
		end
	end
	out.effects = self:Learned({ "steady", "glance", "glance3", "conservator", "favored", "colleague", "pact", "weekpact", "familyseal", "goldloupe",
		"masterpiece", "restorer", "goldfinger", "patience" })
	return out
end

-------------------------------------------------------------------------------
-- The luck of this collector (Luck.lua: the boosters opened since 1.10.0)
-------------------------------------------------------------------------------
function RT:Luck()
	local LK = ns.Luck
	local d = LK and LK:Db()
	if not d then
		return nil
	end
	local function Line(key, got, expect)
		return { key = key, got = tonumber(got) or 0, expect = (tonumber(expect) or 0) / 1000 }
	end
	return {
		n = tonumber(d.n) or 0,
		rows = { Line(4, d.e, d.xe), Line(5, d.l, d.xl), Line(6, d.m, d.xm) },
		sinceLegendary = tonumber(d.sl) or 0,
		sinceMythic = tonumber(d.sm) or 0,
	}
end

-------------------------------------------------------------------------------
-- (1.14.0) The cases (Cases.lua): where they come from (a reroll: a quarter of the chance, into its chest), what a case
-- gives (the chance of each rank, of each finish, of each condition: the draws' own, CS:Odds), its key. No talent
-- changes them.
-------------------------------------------------------------------------------
function RT:Cases()
	local CS = ns.Cases
	if not (CS and CS.Odds) then
		return nil
	end
	local RR = ns.Reroll
	local reroll = RR ~= nil and RR:IsReroll()
	local function Drop(p)
		return Rate(p, reroll and RR:Points(p) or p, {})
	end
	local tiers, finishes, grades = CS:Odds()
	local out = { kill = Drop(CS.KILL), quest = Drop(CS.QUEST), reroll = reroll, key = CS.KEY_PRICE, ranks = {}, finishes = {},
		conditions = {} }
	for _, t in ipairs(tiers) do
		local row = Rate(t[2], t[2], {})
		row.r = t[1]
		out.ranks[CuratorOctoFull.Length(out.ranks) + 1] = row
	end
	for _, f in ipairs(finishes) do
		local row = Rate(f[2], f[2], {})
		row.key = f[1]
		out.finishes[CuratorOctoFull.Length(out.finishes) + 1] = row
	end
	-- (the grades, into the five conditions of the cards of the cases: UI/Crate.lua, CR.CONDITION)
	local CR = ns.CrateUI
	local total = 0
	for _, g in ipairs(grades) do
		total = total + g[2]
	end
	local by, order = {}, {}
	for _, step in ipairs((CR and CR.CONDITION) or {}) do
		by[step[2]] = 0
		order[CuratorOctoFull.Length(order) + 1] = step[2]
	end
	for _, g in ipairs(grades) do
		local w = CR and CR:Word(g[1])
		if w and by[w] then
			by[w] = by[w] + g[2] / math.max(total, 1e-9)
		end
	end
	-- (31 October, his word: never a condition in words on the cards of the cases: each row its grades, 9-10 to 1-2)
	local hi = 10
	for i, w in ipairs(order) do
		local row = Rate(by[w], by[w], {})
		local lo = (CR.CONDITION[i] and CR.CONDITION[i][1]) or 1
		row.word = w
		row.grades = lo < hi and (lo .. "-" .. hi) or tostring(lo)
		hi = lo - 1
		out.conditions[CuratorOctoFull.Length(out.conditions) + 1] = row
	end
	return out
end
