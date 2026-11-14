local _, ns = "Curator", CuratorOctoFull

-- The level of the collector, from 1 to 100 (1.11.0; 60 before). Its experience comes from the boosters opened
-- (each card by its rarity, more for its finish) and from the quests (Quests.lua). (1.14.0, the release of WoW
-- Forever: the levels of the beta came too easily, the curve is five times as long; what is gained stays as it was.)
-- Levels 1 to 11: a gentle ramp (1 000 XP from level 1 to 2, then 500 more each level, then 400 more), so that a
-- first session still gives a level; levels 12 to 40: 10 % more each level, from 2 000; levels 41 to 59: 5 500
-- more each level (no wall before the legend); past the legend, 1 000 more each level. The legend asks 3.5 million
-- (about six months for a very big player), level 100 almost 11.8 million. (Before: 400 XP to level 2, 10 % more
-- each level up to 60, then 800 more each level from 30 000.) The website draws its leaderboard on the same curve
-- (lib/level.ts).
-- Its rank changes every five levels, one metal
-- of the game each (copper to elementium), then the legend at level 60; past it, one gem of the game each
-- (citrine to diamond), then the curator at level 100: each has its emblem.
-- Each level reached gives a reward to choose, claimed on the track of the rewards: three are drawn (1.14.0, his
-- word; a booster of a zone to choose before: the collection came too easily), the player takes one (LV:Choose);
-- past level 60, a reward to choose too every five levels (a booster of a dungeon among the three), and every ten (a
-- booster of a raid among them). (1.14.0, his word: no booster to choose any more) What gave a booster to choose (the
-- quests, the battlegrounds, the wheel, the gift codes, the inns, the chest of a reroll) gives a reward to choose, the
-- booster of its kind one of the three (LV:AddChoice).
local LV = {}
ns.Level = LV

LV.MAX = 100
-- (1.14.0) the ramp of the first levels (what each of the levels 1 to 11 asks), then 10 % more each level from
-- LV.BASE (the level 1 of that rule: level 12 asks 2 000 x 1.1^11) up to LV.GROW_TO, then LV.MID more each level up to
-- the legend, past it LV.STEP more each level (level 60: 187 790, level 99: 226 790)
LV.RAMP = { 1000, 1500, 2000, 2500, 3000, 3400, 3800, 4200, 4600, 5000, 5400 }
LV.BASE, LV.GROWTH, LV.GROW_TO = 2000, 1.10, 40
LV.MID = 5500
LV.LEGEND, LV.STEP = 60, 1000
-- the XP of a card: by its rarity (common to mythic), and for its finish
LV.RARITY = { 10, 15, 25, 45, 60, 100 }
LV.FINISH = { shiny = 20, holo = 100, thunder = 200, titan = 500, corrupt = 150 }
-- the boosters to choose: of a zone, of a dungeon, of a raid
LV.KINDS = { "zone", "dungeon", "raid" }
-- (1.14.0, his word: an album complete gives a golden booster of the album you choose, Achievements.lua: AC:Claim. It
-- waits with the boosters to choose, a kind of its own, UI/Boosters.lua; never sold, never given by anything else)
LV.PICK_KINDS = { "zone", "dungeon", "raid", "golden" }

-- The XP from each level to the next (rounded to tens), and the XP a level starts at.
local NEED, FLOOR = {}, { 0 }
for lv = 1, LV.MAX - 1 do
	if lv <= CuratorOctoFull.Length(LV.RAMP) then
		NEED[lv] = LV.RAMP[lv]
	elseif lv <= LV.GROW_TO then
		NEED[lv] = math.floor(LV.BASE * LV.GROWTH ^ (lv - 1) / 10 + 0.5) * 10
	elseif lv < LV.LEGEND then
		NEED[lv] = NEED[LV.GROW_TO] + LV.MID * (lv - LV.GROW_TO)
	else
		NEED[lv] = NEED[LV.LEGEND - 1] + LV.STEP * (lv - LV.LEGEND + 1)
	end
	FLOOR[lv + 1] = FLOOR[lv] + NEED[lv]
end
LV.NEED, LV.FLOOR = NEED, FLOOR

-- The ranks: from their first level, their name, the colour of their name and of their light.
LV.RANKS = {
	{ level = 1, key = "copper", name = "Copper", color = { 0.95, 0.62, 0.42 }, light = { 1, 0.62, 0.36 } },
	{ level = 5, key = "tin", name = "Tin", color = { 0.8, 0.82, 0.86 }, light = { 0.8, 0.86, 1 } },
	{ level = 10, key = "bronze", name = "Bronze", color = { 0.9, 0.66, 0.38 }, light = { 1, 0.7, 0.4 } },
	{ level = 15, key = "silver", name = "Silver", color = { 0.88, 0.92, 1 }, light = { 0.62, 0.78, 1 } },
	{ level = 20, key = "iron", name = "Iron", color = { 0.76, 0.78, 0.84 }, light = { 1, 0.4, 0.46 } },
	{ level = 25, key = "gold", name = "Gold", color = { 1, 0.84, 0.36 }, light = { 1, 0.84, 0.4 } },
	{ level = 30, key = "mithril", name = "Mithril", color = { 0.64, 0.88, 1 }, light = { 0.5, 0.9, 1 } },
	{ level = 35, key = "truesilver", name = "Truesilver", color = { 0.92, 0.96, 1 }, light = { 0.82, 0.9, 1 } },
	{ level = 40, key = "thorium", name = "Thorium", color = { 0.46, 0.96, 0.8 }, light = { 0.3, 1, 0.78 } },
	{ level = 45, key = "darkiron", name = "Dark Iron", color = { 1, 0.46, 0.24 }, light = { 1, 0.34, 0.1 } },
	{ level = 50, key = "arcanite", name = "Arcanite", color = { 0.92, 0.58, 1 }, light = { 0.92, 0.38, 1 } },
	{ level = 55, key = "elementium", name = "Elementium", color = { 1, 0.62, 0.26 }, light = { 1, 0.55, 0.16 } },
	{ level = 60, key = "legend", name = "Legend", color = { 1, 0.86, 0.46 }, light = { 1, 0.84, 0.47 } },
	-- (1.11.0) past the legend: the gems, then the curator
	{ level = 65, key = "citrine", name = "Citrine", color = { 1, 0.86, 0.34 }, light = { 1, 0.8, 0.26 } },
	{ level = 70, key = "aquamarine", name = "Aquamarine", color = { 0.52, 0.96, 0.9 }, light = { 0.36, 1, 0.9 } },
	{ level = 75, key = "starruby", name = "Star Ruby", color = { 1, 0.44, 0.5 }, light = { 1, 0.26, 0.36 } },
	{ level = 80, key = "sapphire", name = "Sapphire", color = { 0.5, 0.68, 1 }, light = { 0.34, 0.54, 1 } },
	{ level = 85, key = "opal", name = "Opal", color = { 1, 0.86, 0.95 }, light = { 1, 0.72, 0.92 } },
	{ level = 90, key = "emerald", name = "Emerald", color = { 0.42, 1, 0.58 }, light = { 0.26, 1, 0.48 } },
	{ level = 95, key = "diamond", name = "Diamond", color = { 0.9, 0.97, 1 }, light = { 0.8, 0.94, 1 } },
	{ level = 100, key = "curator", name = "Curator", color = { 0.98, 0.74, 1 }, light = { 1, 0.74, 0.36 } },
}

-- The rank of a level: its number and its row.
function LV.RankOf(level)
	local r = 1
	for i, rank in ipairs(LV.RANKS) do
		if (level or 1) >= rank.level then
			r = i
		end
	end
	return r, LV.RANKS[r]
end

-- The emblem of a rank (its texture), and the small one written in a text (size in points).
function LV.Emblem(r)
	return ns.MEDIA .. "Rank" .. (r or 1)
end

-- (the small emblems: 64 x 64 each, four a row, eight rows: 256 x 512, 1.11.0)
function LV.EmblemText(r, size)
	size = size or 16
	r = r or 1
	local col, row = CuratorOctoFull.Mod((r - 1) , 4), math.floor((r - 1) / 4)
	return string.format(("|T%sRankIcons:%d:%d:0:0:256:512:%d:%d:%d:%d|t"), ns.MEDIA, size, size, col * 64, col * 64 + 64, row * 64, row * 64 + 64)
end

-- The part of RankIcons a rank takes: left, right, top, bottom.
function LV.IconCoords(r)
	r = r or 1
	local col, row = CuratorOctoFull.Mod((r - 1) , 4), math.floor((r - 1) / 4)
	return col * 0.25, col * 0.25 + 0.25, row / 8, (row + 1) / 8
end

-- The small emblem of a rank on a texture.
function LV.SetIcon(tex, r)
	tex:SetTexture(ns.MEDIA .. "RankIcons")
	tex:SetTexCoord(LV.IconCoords(r))
end

-- The level of a total of XP, the XP gained in that level and the XP it asks (nil: the highest).
function LV.Of(xp)
	xp = math.max(0, math.floor(tonumber(xp) or 0))
	local lv = 1
	while lv < LV.MAX and xp >= FLOOR[lv + 1] do
		lv = lv + 1
	end
	if lv >= LV.MAX then
		return LV.MAX, xp - FLOOR[LV.MAX], nil
	end
	return lv, xp - FLOOR[lv], NEED[lv]
end

function LV:XP()
	return (ns.db and tonumber(ns.db.xp)) or 0
end

function LV:Level()
	return (LV.Of(self:XP()))
end

function LV:Rank()
	return LV.RankOf(self:Level())
end

-- The XP of a card: its rarity, and its finish (thunderforged or titanforged), more in the dungeons and
-- the raids, as before 1.3 (FINISH: shiny and holo, the finishes of the zones then).
function LV:CardXP(card, finish)
	local xp = self.RARITY[card.rarity] or 0
	local forged = ns.Collection:Forged(card)
	local key
	if finish == "holo" then
		key = forged and "titan" or "holo"
	elseif finish == "shiny" or finish == true then
		key = forged and "thunder" or "shiny"
	elseif finish == "corrupt" then
		-- (1.12.0: a corrupted card of an album of an event)
		key = "corrupt"
	end
	return xp + ((key and self.FINISH[key]) or 0)
end

-- XP gained (why: "booster", "quest", "auto": the rewards of quests not claimed in time). The levels
-- crossed put their rewards on the track, to claim.
function LV:Gain(n, why)
	local db = ns.db
	n = math.floor(tonumber(n) or 0)
	if not db or n <= 0 then
		return 0
	end
	-- (1.14.0: the cards changed by another addon this session: no experience, Guard.lua)
	if ns.Guard and not ns.Guard:Allow() then
		return 0
	end
	-- (1.14.0, Memory of the Roads: outside the dungeons and the raids, more)
	if ns.Talents and ns.Talents.GainXP then
		n = ns.Talents:GainXP(n, why)
	end
	local before = self:Level()
	db.xp = self:XP() + n
	local after = self:Level()
	ns.Fire("XP_GAINED", n, why, before, after)
	if after > before then
		ns.Fire("LEVEL_UP", after, before, why)
		ns.Fire("CLAIMS_CHANGED")
	end
	return after - before
end

-- A booster opened: the XP of each of its cards (kept on each one: p.xp), all of it gained. (1.6.0: more
-- with the talent Collector's Soul; 1.8.0: with First Reading, for the cards the album was missing)
function LV:Booster(picks)
	local total = 0
	local TL = ns.Talents
	for _, p in ipairs(picks) do
		p.xp = self:CardXP(p.card, p.finish)
		if TL then
			p.xp = TL:CardXP(p.xp, p.new, p.card, p.finish, p.card and p.card.series)
		end
		total = total + p.xp
	end
	self:Gain(total, "booster")
	return total
end

-------------------------------------------------------------------------------
-- The rewards of the levels, on the track: claimed one by one, or all at once
-------------------------------------------------------------------------------
-- The reward of a level (from level 2): (1.14.0) a reward to choose among three (kind "offer": LV:NewOffer; a booster of
-- a zone to choose before), and (1.11.0) its rubies (more for a new rank: Rubies.lua); past the legend (1.11.0), more
-- boosters to choose (more: { { kind, n } }): of a dungeon every five levels, of a raid every ten, three of a raid at
-- the last level.
function LV.Reward(level)
	if not level or level < 2 or level > LV.MAX then
		return nil
	end
	local r = { kind = "offer", n = 1, rubies = ns.Rubies and ns.Rubies:OfLevel(level) or 0 }
	if level > LV.LEGEND then
		local more = {}
		if CuratorOctoFull.Mod(level , 5) == 0 then
			more[CuratorOctoFull.Length(more) + 1] = { kind = "dungeon", n = 1 }
		end
		if CuratorOctoFull.Mod(level , 10) == 0 then
			more[CuratorOctoFull.Length(more) + 1] = { kind = "raid", n = level >= LV.MAX and 3 or 1 }
		end
		if CuratorOctoFull.Length(more) > 0 then
			r.more = more
		end
	end
	return r
end

-- The boosters to choose of a reward, kind by kind (into: a table to add them to): { dungeon = 1, raid = 1 } (1.14.0:
-- its reward to choose is none of them).
function LV.RewardPacks(r, into)
	into = into or {}
	if r then
		if r.kind ~= "offer" then
			into[r.kind] = (into[r.kind] or 0) + r.n
		end
		for _, m in ipairs(r.more or {}) do
			into[m.kind] = (into[m.kind] or 0) + m.n
		end
	end
	return into
end

function LV:Claimed(level)
	local c = ns.db and ns.db.levelClaims
	return c ~= nil and c[level] == true
end

-- The levels reached whose rewards wait, in order.
function LV:Unclaimed()
	local out = {}
	for lv = 2, self:Level() do
		if not self:Claimed(lv) then
			out[CuratorOctoFull.Length(out) + 1] = lv
		end
	end
	return out
end

-- Claims the rewards of these levels (nil: all of those waiting). The levels claimed.
function LV:ClaimLevels(levels)
	local db = ns.db
	if not db then
		return {}
	end
	-- (1.14.0: the cards changed by another addon this session: nothing claimed, the rewards stay, Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return {}
	end
	db.levelClaims = db.levelClaims or {}
	local done, top, gain, rubies, offers = {}, self:Level(), {}, 0, 0
	for _, lv in ipairs(levels or self:Unclaimed()) do
		if lv >= 2 and lv <= top and not db.levelClaims[lv] then
			db.levelClaims[lv] = true
			local r = LV.Reward(lv)
			if r then
				LV.RewardPacks(r, gain)
				rubies = rubies + (r.rubies or 0)
				-- (1.14.0: its three rewards drawn now, kept until one is taken)
				if r.kind == "offer" then
					local offer = self:NewOffer(lv)
					if offer then
						local list = self:Offers()
						list[CuratorOctoFull.Length(list) + 1] = offer
						offers = offers + 1
					end
				end
			end
			done[CuratorOctoFull.Length(done) + 1] = lv
		end
	end
	if offers > 0 then
		ns.Fire("OFFERS_CHANGED")
	end
	-- (their boosters to choose added at once, kind by kind; their rubies together)
	for _, kind in ipairs(self.KINDS) do
		if gain[kind] then
			self:AddChoice(kind, gain[kind])
		end
	end
	if rubies > 0 and ns.Rubies then
		rubies = ns.Rubies:Gain(rubies, "level")
	end
	if CuratorOctoFull.Length(done) > 0 then
		ns.Fire("LEVELS_CLAIMED", done, rubies)
		ns.Fire("CLAIMS_CHANGED")
	end
	return done, rubies
end

-------------------------------------------------------------------------------
-- (1.14.0, his word) The reward of a level, to choose: three drawn, each by its weight (never two of a kind; one that
-- cannot come now is not drawn), shown as they will come (the album of a booster, the card and its finish, the
-- rubies): the player takes one, the two others go. Those of several levels wait, one level after the other, in
-- db.offers = { { lv = the level, o = { { k = its kind, s = its album, c = its card, f = its finish, e = the edition
-- of a case, n = rubies }, ... } } }, under the seal of the save (drawn once: nothing draws them again).
--   booster: a booster of the album of a zone where boosters have come (as a booster of a zone to choose)
--   case: a case of the edition of now (Cases.lua; its key bought as any other: none is given)
--   rubies: from LV.OFFER_RUBIES[1] to LV.OFFER_RUBIES[2], by tens
--   card: a card of the album of a zone where boosters have come, its rarity and its finish drawn as a booster of a
--     zone draws them (Collection.lua, C.ODDS; no talent): a mythic as rare as there. Its line in the journal: "l".
--   dungeon, raid: a booster of the album of a dungeon or of a raid where boosters have come, or that was visited
--   golden: a golden booster of an album that could get a booster to choose, not complete yet (as an album complete
--     gives one: Golden.lua, a golden booster of its own)
-------------------------------------------------------------------------------
LV.OFFER = { { "booster", 20 }, { "case", 20 }, { "rubies", 20 }, { "card", 20 }, { "dungeon", 10 }, { "raid", 8 }, { "golden", 2 } }
LV.OFFER_SIZE = 3
LV.OFFER_RUBIES = { 200, 2000 }
local OFFER_RANK = {}
for i, w in ipairs(LV.OFFER) do
	OFFER_RANK[w[1]] = i
end

-- The rewards of the levels waiting to be chosen, the oldest level first.
function LV:Offers()
	local db = ns.db
	if not db then
		return {}
	end
	if type(db.offers) ~= "table" then
		db.offers = {}
	end
	return db.offers
end

function LV:OfferCount()
	local db = ns.db
	return (db and type(db.offers) == "table") and CuratorOctoFull.Length(db.offers) or 0
end

local function Shut()
	return ns.Beta ~= nil and ns.Beta.Over ~= nil and ns.Beta:Over()
end

-- The albums of their own kind that can get a booster of it (golden: those a golden booster can go to).
local function AlbumsOf(kind)
	local out = {}
	for _, s in ipairs(LV:Eligible(kind)) do
		if kind == "golden" or LV.KindOf(s) == kind then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end

-- A card of an album as a booster of a zone draws one: its rarity (none of it in the album: the one under it), its
-- finish.
local function DrawCard(s)
	local C = ns.Collection
	local x, rarity = math.random(), 1
	for _, o in ipairs(C.ODDS.card) do
		if x < o[2] then
			rarity = o[1]
			break
		end
		x = x - o[2]
	end
	local by = s.byRarity or {}
	while rarity > 1 and CuratorOctoFull.Length((by[rarity] or {})) == 0 do
		rarity = rarity - 1
	end
	local pool = by[rarity] or {}
	if CuratorOctoFull.Length(pool) == 0 then
		return nil
	end
	return pool[math.random(CuratorOctoFull.Length(pool))], C:RollFinish(false)
end

-- A reward of a kind, as it would come now (nil: it cannot come).
local function Option(kind)
	if kind == "rubies" then
		if not ns.Rubies or Shut() then
			return nil
		end
		return { k = kind, n = math.random(LV.OFFER_RUBIES[1] / 10, LV.OFFER_RUBIES[2] / 10) * 10 }
	elseif kind == "case" then
		local CS = ns.Cases
		if not (CS and CS:Known(CS.EDITION)) or Shut() then
			return nil
		end
		return { k = kind, e = CS.EDITION }
	end
	local list = AlbumsOf((kind == "booster" or kind == "card") and "zone" or kind)
	if CuratorOctoFull.Length(list) == 0 then
		return nil
	end
	local s = list[math.random(CuratorOctoFull.Length(list))]
	if kind == "card" then
		local card, finish = DrawCard(s)
		return card and { k = kind, c = card.key, f = finish } or nil
	end
	return { k = kind, s = s.key }
end

-- The kind of reward a booster to choose of a kind is (LV:AddChoice): a booster of a zone, of a dungeon, of a raid.
local PROMISE = { zone = "booster", dungeon = "dungeon", raid = "raid" }
LV.PROMISE = PROMISE

-- The three rewards of a level, drawn (nil: none can come). kind: (1.14.0) a booster to choose of that kind given in
-- their place, its booster one of the three (none of it can come now: the three drawn as for a level).
function LV:NewOffer(level, kind)
	local pool, total, out = {}, 0, {}
	local must = PROMISE[kind or ""]
	for _, w in ipairs(self.OFFER) do
		local o = Option(w[1])
		if o then
			if w[1] == must then
				out[1] = o
			else
				pool[CuratorOctoFull.Length(pool) + 1] = { o = o, w = w[2] }
				total = total + w[2]
			end
		end
	end
	while CuratorOctoFull.Length(out) < self.OFFER_SIZE and CuratorOctoFull.Length(pool) > 0 do
		local x, at = math.random() * total, CuratorOctoFull.Length(pool)
		for i, p in ipairs(pool) do
			x = x - p.w
			if x < 0 then
				at = i
				break
			end
		end
		local p = CuratorOctoFull.Remove(pool, at)
		total = total - p.w
		out[CuratorOctoFull.Length(out) + 1] = p.o
	end
	if CuratorOctoFull.Length(out) == 0 then
		return nil
	end
	table.sort(out, function(a, b)
		return OFFER_RANK[a.k] < OFFER_RANK[b.k]
	end)
	local promised
	for _, o in ipairs(out) do
		if o.k == must then
			promised = kind
		end
	end
	return { lv = level, p = promised, o = out }
end

-- The album, the card of a reward (as the data of this version knows them: nil, gone).
function LV.OptionAlbum(o)
	return o and o.s and ns.SeriesByKey(o.s) or nil
end

function LV.OptionCard(o)
	return o and o.c and ns.Cards[o.c] or nil
end

-- A reward that can still come (an album, a card of a version since gone: not).
function LV:OptionOk(o)
	if type(o) ~= "table" then
		return false
	end
	local k = o.k
	if k == "rubies" then
		return ns.Rubies ~= nil and (tonumber(o.n) or 0) > 0 and not Shut()
	elseif k == "case" then
		return ns.Cases ~= nil and ns.Cases:Known(o.e) and not Shut()
	elseif k == "card" then
		-- (1.14.0, his word: of an album unlocked only; one locked again since it was drawn, /curator verrou: no longer)
		local card = LV.OptionCard(o)
		return card ~= nil and self:Unlocked(card.series)
	elseif k == "booster" or k == "dungeon" or k == "raid" or k == "golden" then
		local s = LV.OptionAlbum(o)
		return s ~= nil and LV.KindOf(s) ~= "event" and self:Unlocked(s)
	end
	return false
end

-- What a reward gives (how many: rubies, boosters; a card: true), nil when nothing came (Guard.lua).
local function Give(o)
	local k = o.k
	if k == "rubies" then
		local n = ns.Rubies:Gain(o.n, "level")
		return n > 0 and n or nil
	elseif k == "case" then
		return ns.Cases:Give("level", 1, o.e) and 1 or nil
	elseif k == "card" then
		local card = LV.OptionCard(o)
		local new = ns.Collection:Grant(card, o.f, "l")
		if new == nil then
			return nil
		end
		return true
	end
	local s = LV.OptionAlbum(o)
	if ns.Guard and not ns.Guard:Allow(s) then
		return nil
	end
	if k == "golden" then
		ns.Golden:AddPack(s, "level")
		LV:MarkDropped(s)
	else
		ns.AddPacks(s, 1)
	end
	return 1
end

-- One of the rewards of a level taken (i: the level among those waiting, j: its reward), the two others gone. True
-- and the reward, what it gave; else false and why: "gone" (no such reward, or it cannot come any more), "reroll"
-- (a reroll chooses none, Reroll.lua), "guard" (the cards changed by another addon this session, Guard.lua).
function LV:Choose(i, j)
	local list = self:Offers()
	local offer = list[i]
	local o = offer and type(offer.o) == "table" and offer.o[j]
	if not o or not self:OptionOk(o) then
		return false, "gone"
	end
	if ns.Reroll and ns.Reroll:Blocks("choice") then
		return false, "reroll"
	end
	if ns.Guard and not ns.Guard:Allow() then
		return false, "guard"
	end
	local got = Give(o)
	if got == nil then
		return false, "guard"
	end
	CuratorOctoFull.Remove(list, i)
	ns.Fire("OFFER_CHOSEN", offer.lv, o, got)
	ns.Fire("OFFERS_CHANGED")
	ns.Fire("CLAIMS_CHANGED")
	return true, o, got
end

-- (an offer whose rewards can all no longer come, a version since: drawn again, once)
function LV:MendOffers()
	for i, offer in ipairs(self:Offers()) do
		local any = false
		for _, o in ipairs(type(offer.o) == "table" and offer.o or {}) do
			any = any or self:OptionOk(o)
		end
		if not any then
			local again = self:NewOffer(tonumber(offer.lv), offer.p)
			if again then
				self:Offers()[i] = again
			end
		end
	end
end

-------------------------------------------------------------------------------
-- The boosters to choose, and the albums that can get them
-------------------------------------------------------------------------------
-- The kind of booster an album gives: of a zone, of a dungeon, of a raid.
function LV.KindOf(s)
	-- (1.12.0: an album of an event, "event": no booster to choose goes to it, Hallow.lua; 1.13.0: nor to a limited
	-- edition, the Hardcup Saison 3)
	return ((s.event or s.limited) and "event") or (s.raid and "raid") or (s.dungeon and "dungeon") or "zone"
end

function LV:Choices(kind)
	local c = ns.db and ns.db.choice
	if not kind then
		local n = 0
		for _, k in ipairs(self.PICK_KINDS) do
			n = n + ((c and c[k]) or 0)
		end
		return n
	end
	return (c and c[kind]) or 0
end

-- (1.14.0, his word: no booster to choose any more) Boosters to choose given (kind "zone", "dungeon", "raid": a quest,
-- a full bar where no album lives, a battleground, the wheel, a gift code, an inn, the chest of a reroll, past the
-- legend): a reward to choose among three for each, the booster of its kind one of them. A golden booster to choose
-- (kind "golden", an album complete): into an album drawn at random (LV:GiveGolden). What came (the rewards to
-- choose, the golden boosters).
function LV:AddChoice(kind, n)
	local db = ns.db
	n = math.floor(tonumber(n) or 0)
	if not db or n <= 0 then
		return 0
	end
	-- (1.14.0: the cards changed by another addon this session: nothing, Guard.lua)
	if ns.Guard and not ns.Guard:Allow() then
		return 0
	end
	if kind == "golden" then
		local got = 0
		for _ = 1, n do
			if self:GiveGolden() then
				got = got + 1
			end
		end
		return got
	end
	local list, made = self:Offers(), 0
	for _ = 1, n do
		local offer = self:NewOffer(nil, kind)
		if offer then
			list[CuratorOctoFull.Length(list) + 1] = offer
			made = made + 1
		end
	end
	if made > 0 then
		ns.Fire("OFFERS_CHANGED")
		ns.Fire("CHOICE_CHANGED")
		ns.Fire("CLAIMS_CHANGED")
	end
	return made
end

-- (1.14.0, his word) A golden booster (an album complete): into an album not complete yet that could get a booster
-- to choose, drawn at random (none: the one given, fallback, the album just complete). The album, nil: none.
function LV:GiveGolden(fallback)
	local GQ = ns.Golden
	if not (GQ and ns.db) then
		return nil
	end
	local list = self:Eligible("golden")
	local s = (CuratorOctoFull.Length(list) > 0 and list[math.random(CuratorOctoFull.Length(list))]) or fallback
	if not s or (ns.Guard and not ns.Guard:Allow(s)) then
		return nil
	end
	GQ:AddPack(s, "album")
	self:MarkDropped(s)
	self.lastGolden = s
	ns.Fire("GOLDEN_GIVEN", s)
	return s
end

-- Boosters have come for this album (from playing, a card found there, a booster chosen for it). (1.14.0, his word)
-- The album is unlocked so: only then its boosters and its displays can be bought (the reseller, the Bourse) and
-- come as rewards. Not by a card bought from the reseller (an album drawn at random), nor by what came from a trade
-- or the Bourse, nor by a display opened (Core.lua: ns.AddPacks, its third word).
function LV:Dropped(s)
	local d = ns.db and ns.db.dropped
	return s ~= nil and d ~= nil and d[s.key] == true
end

function LV:Unlocked(s)
	return self:Dropped(s)
end

function LV:MarkDropped(s)
	local db = ns.db
	if s and db then
		db.dropped = db.dropped or {}
		db.dropped[s.key] = true
	end
end

-- (1.6.0) The boosters of a zone to choose can go to the album of a dungeon (not a raid): the talent
-- Foresight.
function LV:Foresees(kind, s)
	return kind == "zone" and s ~= nil and s.dungeon and not s.raid and ns.Talents ~= nil and ns.Talents:Has("foresight")
end

-- The albums that can get a booster to choose of a kind: those unlocked, where boosters have come (1.14.0, his word: a
-- dungeon or a raid only visited, no more), in the order of the contents.
function LV:Eligible(kind)
	local out = {}
	local order = (ns.Album and ns.Album.Order) and ns.Album:Order() or ns.Series
	-- (1.14.0: a golden booster, any album a booster to choose of its kind could go to, but those already complete)
	if kind == "golden" then
		local can = {}
		for _, k in ipairs(self.KINDS) do
			for _, s in ipairs(self:Eligible(k)) do
				if LV.KindOf(s) == k then
					can[s] = true
				end
			end
		end
		local C = ns.Collection
		for _, s in ipairs(order or {}) do
			if can[s] then
				local owned, total = C:Progress(s)
				if owned < total then
					out[CuratorOctoFull.Length(out) + 1] = s
				end
			end
		end
		return out
	end
	for _, s in ipairs(order or {}) do
		local own = LV.KindOf(s)
		if own == kind and self:Dropped(s) then
			out[CuratorOctoFull.Length(out) + 1] = s
		elseif own == "dungeon" and self:Foresees(kind, s) and self:Dropped(s) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end

-- kind: the boosters to choose it would get (its own kind by default).
function LV:CanGet(s, kind)
	if not s then
		return false
	end
	kind = kind or LV.KindOf(s)
	for _, x in ipairs(self:Eligible(kind)) do
		if x == s then
			return true
		end
	end
	return false
end

-- Boosters to choose put in an album (n of them, all of its kind with n = nil; kind: the boosters to
-- choose taken, its own kind by default).
function LV:Assign(s, n, kind)
	if not (ns.db and s) then
		return 0
	end
	-- (1.14.0, after its test, his word: a reroll puts none in an album, Reroll.lua: RR:Blocks)
	if ns.Reroll and ns.Reroll:Blocks("choice") then
		return 0
	end
	kind = kind or LV.KindOf(s)
	if not self:CanGet(s, kind) then
		return 0
	end
	local have = self:Choices(kind)
	n = math.min(n or have, have)
	if n <= 0 then
		return 0
	end
	-- (1.14.0: its album changed by another addon this session: the boosters to choose stay, Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return 0
	end
	ns.db.choice[kind] = have - n
	-- (1.14.0: a golden booster of an album complete, Golden.lua: a golden booster of its own, no talent on it)
	if kind == "golden" then
		for _ = 1, n do
			ns.Golden:AddPack(s, "album")
		end
		self:MarkDropped(s)
		ns.Fire("CHOICE_CHANGED")
		ns.Fire("CHOICE_ASSIGNED", s, n)
		return n
	end
	ns.AddPacks(s, n)
	-- (1.11.0, Double Vision: now and then, a second one with each)
	local TL = ns.Talents
	local more = (TL and TL.Twins) and TL:Twins(n) or 0
	if more > 0 then
		ns.AddPacks(s, more)
		ns.Fire("TALENT_PROC", "doublevision", s, more)
	end
	ns.Fire("CHOICE_CHANGED")
	ns.Fire("CHOICE_ASSIGNED", s, n)
	return n
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
-- The albums where boosters came before 0.18 (when it was not kept): those with boosters waiting,
-- a gauge that moved (the gauges of each album, before 1.2), or cards.
local function Seed()
	local db = ns.db
	-- (the levels of 0.18 gave their boosters at once: their rewards are claimed)
	if db.levelClaims == nil then
		db.levelClaims = {}
		for lv = 2, LV:Level() do
			db.levelClaims[lv] = true
		end
	end
	if db.droppedInit then
		return
	end
	db.droppedInit = true
	local C = ns.Collection
	for _, s in ipairs(ns.Series or {}) do
		local yes = (db.packs[s.key] or 0) > 0 or ((db.progress and db.progress[s.key]) or 0) > 0
		if not yes then
			for _, card in ipairs(s.list or {}) do
				local e = C:Entry(card)
				if e and e.n > 0 then
					yes = true
					break
				end
			end
		end
		if yes then
			db.dropped[s.key] = true
		end
	end
end

ns.On("LOADED", Seed)
ns.On("LOGIN", function()
	local db = ns.db
	if not db then
		return
	end
	if type(db.offers) == "table" and CuratorOctoFull.Length(db.offers) > 0 then
		LV:MendOffers()
	end
	-- (1.14.0, his word: no booster to choose any more) those that waited: a reward to choose each (a golden one, into
	-- an album); what could not come yet waits as it was
	if type(db.choice) == "table" then
		for _, kind in ipairs(LV.PICK_KINDS) do
			local n = math.floor(tonumber(db.choice[kind]) or 0)
			if n > 0 then
				db.choice[kind] = n - LV:AddChoice(kind, n)
			end
		end
	end
end)

-- (1.11.0) The levels past 60: a collector at the legend with experience beyond it reaches them at once (the
-- experience was kept); said once, its screen of a level shown, the rewards waiting on the track.
ns.On("LOGIN", function()
	local db = ns.db
	if not db or db.cap100 then
		return
	end
	db.cap100 = true
	local lv = LV:Level()
	if lv > LV.LEGEND then
		ns.Delay(6, function()
			ns.Print(ns.L["The collector levels now go up to %d: your experience past level %d counts. Level %d!"], LV.MAX, LV.LEGEND, lv)
			ns.Fire("LEVEL_UP", lv, LV.LEGEND, "cap")
			ns.Fire("CLAIMS_CHANGED")
		end, LV)
	end
end)
-- (1.14.0, his word: a card found on a creature does not unlock its album; only its boosters do)
