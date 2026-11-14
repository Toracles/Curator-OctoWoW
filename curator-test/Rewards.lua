local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- Boosters are earned with the booster bars (1.2), filled by what the player does where an album
-- lives. The bar of the world: a creature that gives experience: 2 points; a step of the objective of
-- a quest in progress: 4; a quest turned in (once for each character): 20; a place discovered: 10; a
-- level gained: 40 (1.4.1: twice what they gave before); a quest of the day of the collector: 25
-- (Quests.lua). The dungeons and the raids fill a bar of their own (1.4.1: the same bar before): a
-- creature 0.2, an elite 0.5, a boss 10, its last boss 30 (a place too low for the player gives
-- nothing). ns.PACK_POINTS fill a bar: a booster of the album of the place where it fills (a zone: its
-- album, its capital included; a dungeon or a raid: the album chosen for it, its own by default, else
-- the album of any place the player has been to). Anywhere else (a quest of the collector claimed
-- where no album lives): a booster of a zone to choose. The dungeons and the raids give 5 boosters a
-- day at most (the day of the server: until its daily reset); past it, their points no longer fill
-- their bar. Defeating a creature that has a card can also find that very card. What the player does
-- is told to the quests too (the event ACTIVITY: what, how many, the album of the place). (1.4) The
-- first time a character completes a dungeon or a raid, it also gets a booster of that place,
-- whatever the limit of the day.
local R = {}
ns.Rewards = R

ns.PACK_POINTS = 100
-- the points of the bar (ns.PACK_POINTS make a booster)
local POINTS = {
	kill = 2,          -- a creature that gives experience (1.4.1: twice the points of before, as the four below)
	objective = 4,     -- a step of the objective of a quest in progress
	quest = 20,        -- a quest turned in
	explore = 10,      -- a place discovered
	level = 40,        -- a level gained
	dungeonKill = 0.2, -- a creature of a dungeon or a raid (their bar: the one of the dungeons and the raids)
	elite = 0.5,       -- an elite of a dungeon or a raid
	boss = 10,         -- a boss of a dungeon or a raid
	final = 30,        -- its last boss
}
R.POINTS = POINTS
-- boosters a day from the dungeons and the raids (1.6.0: one more with the talent Dungeon Regular)
R.DAILY = 5
-- the professions: the primary ones (their category of skill lines), cooking, first aid and fishing
local PROFESSIONS = 11
local SECONDARY = { [129] = true, [185] = true, [356] = true }
-- the messages of a place discovered
local EXPLORED = { ERR_ZONE_EXPLORED = true, ERR_ZONE_EXPLORED_XP = true }
-- how long a kill waits for its experience line (and a line for its kill)
local PAIR_XP = 1.5
-- chance to find the card of the creature you defeat, by rarity (bosses: better odds)
local FIND = { 0.012, 0.008, 0.005, 0.003, 0.0015, 0.0005 }
local FIND_BOSS = { [3] = 0.03, [4] = 0.02, [5] = 0.008, [6] = 0.003 }
-- (1.15.0: read by the page of the statistics, Rates.lua)
R.FIND, R.FIND_BOSS = FIND, FIND_BOSS

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

function R:Roll()
	return (self.random or math.random)()
end

-- The series by instance and by map: a zone's map, and the map of the capital that is part of
-- its album (Stormwind in Elwynn Forest...). The dungeons also learn whether most of their
-- creatures are elites. (1.14.0: built at the loading of the save, from the albums just checked: R:Warm, Guard.lua)
local byInstance, byMap
local function Index()
	if not byMap then
		byInstance, byMap = {}, {}
		for _, s in ipairs(ns.Series or {}) do
			if s.instance then
				byInstance[s.instance] = s
			end
			if s.map then
				byMap[s.map] = s
			end
			if s.city then
				byMap[s.city] = s
			end
			if s.dungeon and s.list then
				local elites = 0
				for _, card in ipairs(s.list) do
					if ns.ELITE and ns.ELITE[card.npc] then
						elites = elites + 1
					end
				end
				s.mostlyElite = elites * 2 >= CuratorOctoFull.Length(s.list)
			end
		end
	end
end

-- (1.14.0) The index built now (Guard.lua, at the loading of the save).
function R:Warm()
	Index()
end

-- The dungeon series of the instance you are in.
function R:InstanceSeries()
	if not (IsInInstance and GetInstanceInfo) then
		return nil
	end
	local ok, inside = pcall(IsInInstance)
	if not ok or not inside then
		return nil
	end
	local ok2, _, _, _, _, _, _, _, id = pcall(GetInstanceInfo)
	if not ok2 or type(id) ~= "number" or Secret(id) then
		return nil
	end
	Index()
	return byInstance[id]
end

-- The series of the place you are in: the dungeon, else the zone (from sub-zones and buildings
-- up to the zone map, or the capital's). No series in other instances (battlegrounds, other dungeons).
function R:ZoneSeries()
	local inst = self:InstanceSeries()
	if inst then
		return inst
	end
	if IsInInstance then
		local ok, inside = pcall(IsInInstance)
		if ok and inside then
			return nil
		end
	end
	if not (C_Map and C_Map.GetBestMapForUnit) then
		return nil
	end
	local ok, map = pcall(C_Map.GetBestMapForUnit, "player")
	if not ok then
		return nil
	end
	Index()
	for _ = 1, 6 do
		if not map then
			return nil
		end
		if byMap[map] then
			return byMap[map]
		end
		local info = C_Map.GetMapInfo and C_Map.GetMapInfo(map)
		map = info and info.parentMapID
		if map == 0 then
			return nil
		end
	end
end

-- The zone album you are in, outside the instances: where the world gives boosters.
function R:WorldSeries()
	local s = self:ZoneSeries()
	if s and not s.dungeon then
		return s
	end
end

-------------------------------------------------------------------------------
-- The places visited, and the album a dungeon gives its boosters to
-------------------------------------------------------------------------------
function R:Visited(s)
	return s ~= nil and ns.db ~= nil and ns.db.visited[s.key] == true
end

-- The place you are in is visited (by any of your characters: the collection is the account's).
function R:Visit()
	local s = ns.db and self:ZoneSeries() or nil
	if s and not ns.db.visited[s.key] then
		ns.db.visited[s.key] = true
		ns.Fire("VISITED", s)
	end
	if s ~= self.place then
		self.place = s
		ns.Fire("PLACE_CHANGED", s)
		if s and s.dungeon and self:TooLow(s) then
			ns.Print(string.format(L["%s: too low for your level, no boosters here."], ns.Collection:SeriesName(s)))
		elseif s and s.dungeon and not ns.db.farmHint then
			-- the first dungeon: where to choose the album its boosters go to
			ns.db.farmHint = true
			ns.Print(L["In a dungeon or a raid, you choose the album that gets your boosters: at the bottom of the album."])
		end
	end
	return s
end

-- The album that gets what is earned in a dungeon or a raid: the one chosen for it, when its place
-- was visited, else its own.
function R:FarmSeries(inst)
	inst = inst or self:InstanceSeries()
	if not inst then
		return nil
	end
	local key = ns.db and ns.db.farm[inst.key]
	local s = key and ns.SeriesByKey(key)
	if s and s ~= inst and self:Visited(s) then
		return s
	end
	return inst
end

function R:SetFarm(inst, s)
	if not (inst and s and ns.db) or (s ~= inst and not self:Visited(s)) then
		return false
	end
	ns.db.farm[inst.key] = (s ~= inst) and s.key or nil
	ns.Fire("FARM_CHANGED", inst, s)
	return true
end

-------------------------------------------------------------------------------
-- The bar and the boosters
-------------------------------------------------------------------------------
-- The day of the server: the time of its next daily reset (the same all day long).
function R:Today()
	local now = CuratorOctoFull.ServerTime()
	local D = C_DateAndTime
	if D and D.GetSecondsUntilDailyReset then
		local ok, left = pcall(D.GetSecondsUntilDailyReset)
		if ok and type(left) == "number" and not Secret(left) and left > 0 then
			return math.floor((now + left) / 600 + 0.5)
		end
	end
	return math.floor(now / 86400)
end

-- The boosters the dungeons and the raids give a day.
function R:DailyMax()
	return ns.Talents and ns.Talents:DailyMax(self.DAILY) or self.DAILY
end

-- The boosters the dungeons and raids can still give today, and the count of the day.
function R:DailyLeft()
	local d = ns.db.daily
	local today = self:Today()
	if type(d) ~= "table" or d.day ~= today then
		d = { day = today, n = 0 }
		ns.db.daily = d
	end
	return math.max(0, self:DailyMax() - d.n), d
end

-- The limit of the day reached: said once.
function R:Capped(s)
	local _, d = self:DailyLeft()
	if not d.told then
		d.told = true
		ns.Fire("DAILY_LIMIT", s)
	end
end

-- The points of a bar toward its next booster (0 to ns.PACK_POINTS): the bar of the world, or (kind
-- "dungeon") the one of the dungeons and the raids (1.4.1). (1.14.0: a reroll has bars of its own, Reroll.lua;
-- account: the bars of the account all the same)
function R:Bar(kind, account)
	if not account and ns.Reroll and ns.Reroll:IsReroll() then
		return ns.Reroll:Bar(kind)
	end
	local v = ns.db and (kind == "dungeon" and ns.db.dbar or ns.db.bar)
	return math.max(0, tonumber(v) or 0)
end

-- The bar of the place where the player is: "dungeon" in a dungeon or a raid, else "world".
function R:Here()
	return self:InstanceSeries() and "dungeon" or "world"
end

-- (1.1 and before had a gauge for each album: the bar is the gauge of them all)
function R:Progress()
	return self:Bar()
end

-- Where the booster of the bar goes when it fills here: the album of the place (in a dungeon or a
-- raid: the album chosen for it; inst: that place), nil where no album lives.
function R:Target()
	local inst = self:InstanceSeries()
	if inst then
		return self:FarmSeries(inst), inst
	end
	return self:WorldSeries()
end

-- Points on a bar; a full bar gives a booster to s (nil: a booster of a zone to choose). daily: the
-- points of a dungeon or a raid, on their own bar (past the limit of the day, it stays where it is).
-- (1.14.0) A reroll (Reroll.lua): a quarter of the points, on its own bars, its boosters in its chest; account:
-- points the account claims (the quests of the collector, the talents of the trades), as they are, on the bars of
-- the account. The boosters earned.
function R:Fill(s, points, reason, daily, account, ctx)
	points = tonumber(points) or 0
	if not ns.db or points <= 0 or (ns.Beta and ns.Beta:Over()) then
		return 0
	end
	-- (1.14.0: the album the points go to as it must be, else no point: Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return 0
	end
	local left = CuratorOctoFull.Huge
	if daily then
		left = self:DailyLeft()
		if left <= 0 then
			self:Capped(s)
			return 0
		end
	end
	-- (in tenths of a point: the creatures of the dungeons give fractions of one)
	local kind = daily and "dungeon" or "world"
	-- (1.6.0: the talents that fill the bars more; 1.14.0, ctx: what was defeated, the album of the place)
	if ns.Talents then
		ctx = ctx or {}
		if ctx.s == nil then
			ctx.s = s
		end
		points = ns.Talents:BarPoints(points, reason, kind, ctx)
	end
	local RR = not account and ns.Reroll or nil
	local reroll = RR ~= nil and RR:IsReroll()
	local p
	if reroll then
		-- (its own bars keep hundredths of a point: a quarter of a creature of a dungeon is no tenth)
		points = RR:Points(points)
		p = RR:Bar(kind) + points
	else
		p = math.floor((self:Bar(kind, true) + points) * 10 + 0.5) / 10
	end
	local earned = 0
	while p >= ns.PACK_POINTS and earned < left do
		p = p - ns.PACK_POINTS
		earned = earned + 1
	end
	-- (the limit of the day reached on the way: the bar stays just short of full)
	if reroll then
		RR:SetBar(kind, math.min(p, ns.PACK_POINTS - 0.01))
	else
		ns.db[daily and "dbar" or "bar"] = math.min(math.floor(p * 10 + 0.5) / 10, ns.PACK_POINTS - 0.1)
	end
	if earned > 0 then
		self:Give(s, earned, reason, daily, true, account)
		-- (1.6.0: the boosters of the world of the day, for the talent Beaten Track)
		if not daily and ns.Talents then
			ns.Talents:WorldBoosters(earned, s)
		end
	end
	ns.Fire("PROGRESS", s, points, reason, kind)
	return earned
end

-- Points earned in a place: nothing where no album lives. (1.14.0, ctx: for the talents, R:Fill.)
function R:Add(s, points, reason, daily, ctx)
	if not s then
		return 0
	end
	return self:Fill(s, points, reason, daily, nil, ctx)
end

-- Points earned anywhere (the quests of the collector): the booster of a full bar goes to the album
-- of the zone you are in, else it is a booster of a zone to choose (never a booster of a dungeon: those
-- come from the dungeons and their limit of the day).
-- (1.14.0: points the account claims, as they are on any character: Reroll.lua)
function R:AddAnywhere(points, reason)
	return self:Fill(self:WorldSeries(), points, reason, false, true)
end

-- (1.14.0) The boosters of a reroll (Reroll.lua). Those the account claims, or counted for the account already (the
-- loyalty card, the passport, a treat and the gift of Hallow's End, its quests, the bounties, the wanted poster, the
-- heads with a price): as they are. Those that come of boosters a reroll earned (its bar, the bonus of Hallow's End,
-- Beaten Track): whole, in its chest. Any other (what it earns by playing: the first clear, the pay, the front): a
-- quarter, in its chest.
local ACCOUNT = { inn = true, passport = true, treat = true, welcome = true, hallowQuest = true, bounty = true, wanted = true,
	head = true, chest = true }
local DERIVED = { hallow = true, trail = true }
R.ACCOUNT_REASONS, R.DERIVED_REASONS = ACCOUNT, DERIVED

-- Boosters given: to an album (nil: boosters of a zone to choose). bar: given by a full booster bar
-- (1.9.0: said with the sound of a quest done). account (1.14.0): the account's whatever the character.
function R:Give(s, n, reason, daily, bar, account)
	if not ns.db or n <= 0 or (ns.Beta and ns.Beta:Over()) then
		return
	end
	-- (1.14.0: the album the boosters go to as it must be, else none: Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return
	end
	local RR = ns.Reroll
	local chest = not account and not ACCOUNT[reason] and RR ~= nil and RR:IsReroll()
	if chest and not bar and not DERIVED[reason] then
		n = RR:Quarter("give:" .. tostring(reason), n)
		if n <= 0 then
			return
		end
	end
	local d
	if daily then
		local left
		left, d = self:DailyLeft()
		n = math.min(n, left)
		if n <= 0 then
			return self:Capped(s)
		end
		d.n = d.n + n
	end
	if chest then
		RR:StashPacks(s, n)
	elseif s then
		ns.AddPacks(s, n)
	elseif ns.Level then
		ns.Level:AddChoice("zone", n)
	end
	ns.Fire("PACK_EARNED", s, n, reason, bar == true, chest or nil)
	if d and d.n >= self:DailyMax() then
		self:Capped(s)
	end
end

-- A card found on the creature it shows (holographic or shiny now and then, as in the boosters; in a
-- dungeon or a raid, titanforged or thunderforged). boss: the card of a boss, found on that boss. ctx
-- (1.6.0, for the talents): { elite, boss, rare (the game says so), prey (the Prey of the Day) }. (1.8.0)
-- The card of a rumor of an innkeeper: twice the chance, all day (Tavern.lua); (1.14.0) a lead, three times, and the
-- rest and the dish of the day (Lodging.lua).
function R:Find(card, chance, boss, ctx)
	if ns.Beta and ns.Beta:Over() then
		return
	end
	-- (1.14.0: the card and its album changed by another addon this session: nothing found, no chance of the talents
	-- spent, nothing counted; Guard.lua)
	if ns.Guard and not ns.Guard:Allow(card and card.series, card) then
		return false
	end
	-- (1.8.0: the card of a rumor of the tavern, twice as easy to find all day; 1.14.0: a lead, three times, for days;
	-- the rest and the dish of the day of the inns, Lodging.lua)
	if ns.Tavern then
		chance = ns.Tavern:FindChance(chance, card, ctx, boss)
	end
	local TL = ns.Talents
	if TL then
		chance = TL:FindChance(chance, card, ctx)
	end
	-- (1.14.0: a reroll, a quarter of the chance, the card in its chest; a card a summit gives, given)
	local RR = ns.Reroll
	local reroll = RR ~= nil and RR:IsReroll()
	local gift = ctx and ctx.gift
	if reroll and not gift then
		chance = RR:Points(chance)
	end
	local got = gift ~= nil or self:Roll() < chance
	if TL then
		TL:Found(got, card, ctx)
	end
	if got then
		local C = ns.Collection
		local top, second = C.ODDS.holo, C.ODDS.shiny
		if C:Forged(card) then
			top, second = C.DUNGEON.titan, C.DUNGEON.thunder
		end
		if TL then
			top, second = TL:FoundFinish(top, second, ctx)
		end
		if TL and gift then
			TL:GiftTaken(gift, card)
		end
		-- (1.14.0, Blank Squares: a card already there gives way to another one of its album and rarity, missing)
		if TL and not gift and TL.Blank then
			card = TL:Blank(card)
		end
		local r = self:Roll()
		local finish = (r < top and "holo") or (r < top + second and "shiny") or nil
		-- (1.12.0: a card of an album of an event: corrupted now and then, never forged)
		local corruption
		if card.series and card.series.event then
			finish, corruption = C:RollEventFinish()
		end
		-- (1.14.0, after its test, his word: a card a reroll finds counts for no achievement, Reroll.lua: RR:Counts)
		local st = ns.Stats()
		if RR == nil or RR:Counts() then
			st.found = st.found + 1
			if boss then
				st.bossFound = st.bossFound + 1
			end
			-- (1.5.0, a secret feat: the card of Hogger, found on Hogger)
			if ns.Achievements and card.key == ns.Achievements.HOGGER then
				st.hogger = true
			end
		end
		if reroll then
			local new = not ns.Collection:Owned(card) and not RR:Holds(card)
			RR:StashCard(card, finish, corruption, "f")
			ns.Fire("CARD_FOUND", card, finish, new, nil, true)
			if TL then
				TL:OnFound(card, ctx)
			end
			return true
		end
		local new, count = ns.Collection:Grant(card, finish, nil, corruption)
		-- (1.14.0: refused, the card changed by another addon: Guard.lua)
		if new == nil then
			return false
		end
		ns.Fire("CARD_FOUND", card, finish, new, count)
		if TL then
			TL:OnFound(card, ctx)
		end
		return true
	end
end

-- What this character did (quests, their objectives, professions) and its level: kept apart for each
-- character.
function R:Char()
	local me = (ns.Guild and ns.Guild:Me()) or "?"
	local chars = ns.db.chars
	local c = chars[me]
	if not c then
		c = { quests = {}, obj = {}, skills = {} }
		chars[me] = c
	end
	return c
end

-- The level of this character, kept with what it did (the quests of the account follow its characters).
function R:KeepLevel(level)
	level = level or (UnitLevel and UnitLevel("player"))
	if type(level) == "number" and not Secret(level) and level > 0 then
		self:Char().level = level
	end
end

-------------------------------------------------------------------------------
-- Creatures
-------------------------------------------------------------------------------
local function NpcFromGUID(guid)
	if type(guid) ~= "string" or Secret(guid) then
		return nil
	end
	local ok, kind, id = pcall(function()
		local k, _, _, _, _, npc = strsplit("-", guid)
		return k, tonumber(npc)
	end)
	if ok and (kind == "Creature" or kind == "Vehicle") then
		return id
	end
end

-- The unit that shows a creature (its target, its nameplate...), if any.
local function UnitOf(guid)
	if type(guid) == "string" and not Secret(guid) and UnitTokenFromGUID then
		local ok, unit = pcall(UnitTokenFromGUID, guid)
		if ok and type(unit) == "string" and not Secret(unit) then
			return unit
		end
	end
end

-- Whether the player still gains experience (else the creatures that would give some count).
function R:GainsXP()
	if IsXPUserDisabled then
		local ok, off = pcall(IsXPUserDisabled)
		if ok and off == true then
			return false
		end
	end
	local max = GetMaxPlayerLevel and GetMaxPlayerLevel()
	local level = UnitLevel and UnitLevel("player")
	return not (type(max) == "number" and type(level) == "number" and level >= max)
end

-- The highest level of a creature that gives no experience to a player of a level ("grey").
local function GreyLevel(level)
	if level <= 5 then
		return 0
	elseif level <= 39 then
		return level - 5 - math.floor(level / 10)
	elseif level <= 59 then
		return level - 1 - math.floor(level / 5)
	end
	return level - 9
end
R.GreyLevel = GreyLevel

-- A creature that would give experience to the player: its level (from a unit that shows it, else
-- from its card) above the grey ones.
function R:WouldGiveXP(npc, guid)
	local level
	local unit = UnitOf(guid)
	if unit and UnitLevel then
		local ok, lv = pcall(UnitLevel, unit)
		if ok and type(lv) == "number" and not Secret(lv) then
			level = lv
		end
	end
	if not level then
		local card = npc and ns.Cards["c" .. npc]
		level = card and card.hi
	end
	if not level then
		return false
	end
	if level < 0 then
		return true -- a boss, "??"
	end
	return level > GreyLevel((UnitLevel and UnitLevel("player")) or 1)
end

-- A dungeon or a raid too low for the player (its strongest creatures are grey): it gives nothing.
function R:TooLow(s)
	if not (s and s.dungeon and s.levels) then
		return false
	end
	return s.levels[2] <= GreyLevel((UnitLevel and UnitLevel("player")) or 1)
end

-- What the game says of a creature (a unit that shows it): "normal", "elite", "rare", "rareelite",
-- "worldboss"... (nil: not known).
function R:Classify(guid)
	local unit = UnitOf(guid)
	if unit and UnitClassification then
		local ok, c = pcall(UnitClassification, unit)
		if ok and type(c) == "string" and not Secret(c) then
			return c
		end
	end
end

-- (1.14.0) The level of a creature defeated: a unit that shows it, else its card (nil: not known; -1: a boss).
function R:LevelOf(npc, guid)
	local unit = UnitOf(guid)
	if unit and UnitLevel then
		local ok, lv = pcall(UnitLevel, unit)
		if ok and type(lv) == "number" and not Secret(lv) then
			return lv
		end
	end
	local card = npc and ns.Cards["c" .. npc]
	return card and card.hi or nil
end

-- An elite of a dungeon or a raid: the data of the albums, else what a unit that shows it tells,
-- else what most creatures of the place are.
function R:IsElite(npc, guid, s)
	local card = npc and ns.Cards["c" .. npc]
	if card and card.series.dungeon then
		return ns.ELITE[npc] == true
	end
	local c = self:Classify(guid)
	if c then
		return c == "elite" or c == "rareelite" or c == "worldboss"
	end
	Index()
	return s.mostlyElite == true
end

-- (1.6.0) What the talents need of a creature defeated (1.14.0: { elite, rare, guid, gift: the summit that gives its
-- card }).
function R:FindContext(card, guid, elite)
	local TL = ns.Talents
	if not (TL and TL:Spec()) then
		return nil
	end
	local c = self:Classify(guid)
	local rare
	if c then
		rare = c == "rare" or c == "rareelite"
	end
	if not rare and card and card.npc and ns.RARE and ns.RARE[card.npc] then
		rare = true
	end
	local ctx = { elite = elite, rare = rare, guid = guid }
	ctx.gift = card ~= nil and TL:GiftFor(card, ctx) or nil
	return ctx
end

-- A creature defeated. npc: its NPC id (nil when the client keeps it unnamed); xp: it gave
-- experience (or would have, at the highest level).
function R:OnKill(npc, xp, guid)
	local s = self:ZoneSeries()
	if not s then
		return
	end
	local card = npc and ns.Cards["c" .. npc]
	local own = card ~= nil and card.series == s
	if s.dungeon then
		if own and s.bossSet[npc] then
			return self:OnBoss(s, card)
		end
		if self:TooLow(s) then
			return
		end
		local elite = self:IsElite(npc, guid, s)
		if own then
			self:Find(card, FIND[card.base or card.rarity], nil, self:FindContext(card, guid, elite))
		end
		-- (1.12.0: the card of the album of Hallow's End of this creature, now and then, while it lasts)
		if ns.Hallow then
			ns.Hallow:OnKill(npc)
		end
		local pts = elite and POINTS.elite or POINTS.dungeonKill
		if elite and ns.Talents then
			pts = ns.Talents:ElitePoints(pts, true)
		end
		local got = self:Fill(self:FarmSeries(s), pts, "kill", true, nil, { elite = elite, s = s })
		ns.Fire("ACTIVITY", (s.raid and "raid" or "dungeon") .. (elite and "Elite" or "Kill"), 1, s)
		-- (a creature of a place not too low gives experience: it counts as those of the world)
		ns.Fire("ACTIVITY", "kill", 1, s)
		-- (1.9.0: its kind, for the quests: the creatures of a type)
		ns.Fire("KILLED", card, elite, true)
		return got
	end
	-- in the world, a creature counts when it gives experience
	if not xp then
		return
	end
	-- (1.6.0: the elites of the world, for the talents; 1.14.0: of every tree)
	local TL = ns.Talents
	local elite = (TL and TL:Spec()) and self:IsElite(npc, guid, s) or false
	if own then
		self:Find(card, FIND[card.base or card.rarity], nil, self:FindContext(card, guid, elite))
	end
	-- (1.12.0: the card of the album of Hallow's End of this creature, now and then, while it lasts)
	if ns.Hallow then
		ns.Hallow:OnKill(npc)
	end
	self:Add(s, POINTS.kill, "kill", nil, { level = self:LevelOf(npc, guid), elite = elite })
	ns.Fire("ACTIVITY", "kill", 1, s)
	-- (1.9.0: its kind and whether it was an elite or a rare one, for the quests; 31 October, a rare apart: the quests count
	-- the rares only, no more the elites)
	local c = self:Classify(guid)
	local rare = (npc and ns.RARE and ns.RARE[npc]) or c == "rare" or c == "rareelite"
	ns.Fire("KILLED", card, elite or c == "elite" or c == "rareelite" or c == "rare" or c == "worldboss", false, rare and true or false)
	-- (1.10.0: a rare of the world, for the golden quests: the list of the rares, else what a unit showed)
	if rare then
		ns.Fire("RARE_KILLED", s, npc)
	end
end

-- A kill and its experience line come one after the other, in either order: each waits a moment
-- for the other. A kill without a line gave no experience; a line without a kill (a client
-- without the kill event, the kill of a pet) is a kill that gave some.
R.kills, R.lines = {}, {}

local function Same(a, b)
	return a == nil or b == nil or a == b
end

function R:OnKillEvent(npc, guid)
	self.killEvent = true
	if not self:GainsXP() then
		return self:OnKill(npc, self:WouldGiveXP(npc, guid), guid)
	end
	for i, l in ipairs(self.lines) do
		if Same(npc, l.npc) then
			CuratorOctoFull.Remove(self.lines, i)
			return self:OnKill(npc or l.npc, true, guid)
		end
	end
	local k = { npc = npc, guid = guid }
	CuratorOctoFull.Insert(self.kills, k)
	ns.Delay(PAIR_XP, function()
		for i, x in ipairs(R.kills) do
			if x == k then
				CuratorOctoFull.Remove(R.kills, i)
				return R:OnKill(k.npc, false, k.guid)
			end
		end
	end, R)
end

function R:OnXPLine(name)
	local s = self:ZoneSeries()
	if not s then
		return
	end
	local npc = self:NpcByName(s, name)
	for i, k in ipairs(self.kills) do
		if Same(k.npc, npc) then
			CuratorOctoFull.Remove(self.kills, i)
			return self:OnKill(k.npc or npc, true, k.guid)
		end
	end
	if not self.killEvent then
		return self:OnKill(npc, true)
	end
	local l = { npc = npc }
	CuratorOctoFull.Insert(self.lines, l)
	ns.Delay(PAIR_XP, function()
		for i, x in ipairs(R.lines) do
			if x == l then
				CuratorOctoFull.Remove(R.lines, i)
				return R:OnKill(l.npc, true)
			end
		end
	end, R)
end

-- The boss cards of a dungeon by the name the game gives the encounter.
function R:BossByName(s, name)
	if type(name) ~= "string" or Secret(name) then
		return nil
	end
	local low = string.lower(name)
	for _, card in ipairs(s.list) do
		if s.bossSet[card.npc] then
			local here = ns.Collection:Name(card)
			local en = s.names.enUS[card.npc]
			if (here and string.lower(here) == low) or (en and string.lower(en) == low) then
				return card
			end
		end
	end
end

-- A boss defeated: its points (the last one: more). The end of its encounter and its kill both report
-- it: it counts once. An encounter whose name matches no boss card (a translation, a fight of several creatures)
-- is the boss card killed a few seconds before or after it.
local PAIR = 15
function R:OnBoss(s, card, name, fromEncounter)
	local now = GetTime()
	self.bossDone = self.bossDone or {}
	local id = card and card.key or name or "?"
	if self.bossDone[id] and now - self.bossDone[id] < 120 then
		return
	end
	self.bossDone[id] = now
	local count = true
	if card then
		if self.encounterAlone and now - self.encounterAlone < PAIR then
			-- that encounter was this boss: already counted
			self.encounterAlone = nil
			count = false
		elseif not fromEncounter then
			self.killAlone = now
		end
	else
		if self.killAlone and now - self.killAlone < PAIR then
			-- the boss killed just before: already counted
			self.killAlone = nil
			return
		end
		self.encounterAlone = now
	end
	local final = card ~= nil and card.npc == s.final
	if final then
		-- the dungeon (or the raid) is done (1.14.0, after its test, his word: for the achievements, not by a reroll,
		-- Reroll.lua: RR:Counts; a quarter of the times counted before his word)
		local st = ns.Stats()
		if not ns.Reroll or ns.Reroll:Counts() then
			st.done[s.key] = (st.done[s.key] or 0) + 1
		end
	end
	-- a dungeon too low for the player: no points, no card
	local low = self:TooLow(s)
	if count then
		if not low then
			local pts = final and POINTS.final or POINTS.boss
			-- (1.14.0: the talents of the bosses, Hunting Tally; the raids, Dragonslayer and Beat by their reason)
			if ns.Talents then
				pts = ns.Talents:BossPoints(pts)
			end
			self:Fill(self:FarmSeries(s), pts, final and (s.raid and "raid" or "dungeon") or "boss", true, nil,
				{ boss = true, elite = true, raid = s.raid and true or nil, s = s })
			ns.Fire("ACTIVITY", s.raid and "raidBoss" or "dungeonBoss", 1, s)
			if final then
				ns.Fire("ACTIVITY", s.raid and "raidDone" or "dungeonDone", 1, s)
			end
		end
		ns.Fire("BOSS_DEFEATED", s, card)
	elseif final and not low then
		-- (the encounter of the last boss came first, without a name to know it: it counted as a boss;
		-- the place is done all the same, and the points of a last boss are made up)
		local pts = POINTS.final - POINTS.boss
		self:Fill(self:FarmSeries(s), pts, s.raid and "raid" or "dungeon", true, nil, { boss = true, elite = true, raid = s.raid and true or nil, s = s })
		ns.Fire("ACTIVITY", s.raid and "raidDone" or "dungeonDone", 1, s)
	end
	if card and not low then
		local ctx = (ns.Talents and ns.Talents:Spec()) and { boss = true, elite = true, raid = s.raid and true or nil } or nil
		local chance = FIND_BOSS[card.base or card.rarity] or FIND[card.base or card.rarity]
		local found = self:Find(card, chance, true, ctx)
		-- (1.14.0, Death Halloo: the last boss of a dungeon draws its card a second time)
		if not found and final and not s.raid and ns.Talents and ns.Talents:Has("halali") then
			self:Find(card, chance, true, ctx)
		end
		-- (1.12.0: its card of the album of Hallow's End, now and then, while it lasts)
		if ns.Hallow then
			ns.Hallow:OnKill(card.npc)
		end
	end
	if final and not low then
		self:FirstClear(s)
		-- (1.14.0: the talents of the bosses defeated, Talents.lua)
		if ns.Talents and ns.Talents.BossDone then
			ns.Talents:BossDone(s, card, final)
		end
	elseif card and not low and s.raid and ns.Talents and ns.Talents.BossDone then
		ns.Talents:BossDone(s, card, false)
	end
end

-- (1.4) The first time this character completes a dungeon or a raid (its last boss defeated, the place
-- not too low for it): a booster of that place, besides what the bar gives, whatever the limit of the
-- day. True when it is given.
function R:FirstClear(s)
	if not (ns.db and s and s.dungeon) or (ns.Beta and ns.Beta:Over()) then
		return false
	end
	local c = self:Char()
	c.cleared = c.cleared or {}
	if c.cleared[s.key] then
		return false
	end
	-- (1.14.0: its album changed by another addon this session: the first clear waits for the next one; Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s) then
		return false
	end
	c.cleared[s.key] = CuratorOctoFull.ServerTime()
	-- (1.6.0: two with the talent Trailblazer)
	self:Give(s, ns.Talents and ns.Talents:FirstClearBoosters() or 1, "first", false)
	return true
end

-- Without the kill event (some clients keep it from addons), the experience message names the
-- creature: "%s dies, you gain %d experience."
local xpPattern
local function XPName(text)
	if type(text) ~= "string" or Secret(text) then
		return nil
	end
	if not xpPattern then
		local fmt = _G.COMBATLOG_XPGAIN_FIRSTPERSON or "%s dies, you gain %d experience."
		fmt = string.gsub(fmt, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
		fmt = string.gsub(string.gsub(fmt, "%%%%s", "(.+)"), "%%%%d", "%%d+")
		xpPattern = "^" .. fmt
	end
	return CuratorOctoFull.Match(text, xpPattern)
end

function R:NpcByName(s, name)
	for _, card in ipairs(s.list) do
		if ns.Collection:Name(card) == name then
			return card.npc
		end
	end
end

-------------------------------------------------------------------------------
-- Quests, places, levels (in the world); the professions count for the quests of the collector only
-------------------------------------------------------------------------------
-- A quest turned in: once per quest for each character (a repeatable quest counts the first time).
function R:OnQuestTurnedIn(questID, xp, money)
	local c = self:Char()
	local first = false
	if type(questID) == "number" and not Secret(questID) then
		if c.quests[questID] then
			return
		end
		c.quests[questID] = true
		first = true
		-- the steps of a quest that cannot come back are forgotten (a repeatable one keeps them)
		local Q = C_QuestLog
		local ok, again = pcall(function()
			return Q and Q.IsRepeatableQuest and Q.IsRepeatableQuest(questID)
		end)
		if ok and again == false then
			c.obj[questID] = nil
		end
	end
	local ws = self:WorldSeries()
	self:Add(ws, ns.Talents and ns.Talents:QuestPoints(POINTS.quest, ws) or POINTS.quest, "quest")
	if first then
		ns.Fire("ACTIVITY", "quest", 1)
		-- (1.14.0, his word: its rubies, after the money it gives, once a quest and a character)
		self:TurnInRubies(questID, money)
	end
end

-- (1.14.0, his word) The rubies of a quest of the game turned in (Rubies.lua: RB:OfTurnIn, their guard of the week); a
-- reroll's: a quarter of them, in its chest (Reroll.lua). How many came to the collector.
function R:TurnInRubies(questID, money)
	local RB = ns.Rubies
	if not (RB and RB.OfTurnIn) then
		return 0
	end
	if Secret(money) then
		money = nil
	end
	local n = RB:OfTurnIn(money)
	local RR = ns.Reroll
	if RR and RR:IsReroll() then
		RR:StashRubies(RR:Quarter("rubies:turnin", n))
		return 0
	end
	return RB:Gain(n, "turnin", { quest = questID })
end

-- The objectives of the quests in progress: a step beyond the furthest one reached counts (a quest
-- seen for the first time, or taken again, only sets where it is).
function R:ScanObjectives()
	local Q = C_QuestLog
	if not (ns.db and Q and Q.GetNumQuestLogEntries and Q.GetInfo and Q.GetQuestObjectives) then
		return
	end
	local c = self:Char()
	local steps = 0
	local n = Q.GetNumQuestLogEntries() or 0
	for i = 1, n do
		local info = Q.GetInfo(i)
		local id = info and not info.isHeader and info.questID
		if type(id) == "number" and not Secret(id) then
			local objectives = Q.GetQuestObjectives(id)
			if type(objectives) == "table" then
				local seen = c.obj[id]
				local first = seen == nil
				seen = seen or {}
				for k, o in ipairs(objectives) do
					local got = type(o) == "table" and tonumber(o.numFulfilled) or 0
					local before = seen[k]
					if first or before == nil then
						seen[k] = math.max(got, before or 0)
					elseif got > before then
						seen[k] = got
						steps = steps + 1
					end
				end
				c.obj[id] = seen
			end
		end
	end
	if steps > 0 then
		self:Add(self:WorldSeries(), POINTS.objective * steps, "objective")
		ns.Fire("ACTIVITY", "objective", steps)
	end
	return steps
end

-- The professions: each point beyond the highest rank known counts for the quests of the collector
-- (not for the bar: 1.2). A profession learned again starts where it was; one seen for the first
-- time with points already only sets them.
function R:ScanSkills()
	local S = C_SkillInfo
	if not (ns.db and S and S.GetNumSkillLines and S.GetSkillLineInfo) then
		return
	end
	local lines = S.GetNumSkillLines() or 0
	if lines == 0 then
		return -- not known yet
	end
	local c = self:Char()
	local first = not c.skillsInit
	local gained = 0
	for i = 1, lines do
		local info = S.GetSkillLineInfo(i)
		if type(info) == "table" and not info.isHeader and (info.skillLineCategoryID == PROFESSIONS or SECONDARY[info.skillID]) then
			local id, rank = info.skillID, tonumber(info.rank) or 0
			local before = c.skills[id]
			if before == nil then
				c.skills[id] = rank
				if not first and rank <= 1 then
					gained = gained + rank -- a profession just learned
				end
			elseif rank > before then
				gained = gained + rank - before
				c.skills[id] = rank
			end
		end
	end
	c.skillsInit = true
	if gained > 0 then
		ns.Fire("ACTIVITY", "profession", gained)
	end
	return gained
end

-- A message at the top of the screen: a place discovered.
function R:OnInfoMessage(kind)
	if Secret(kind) then
		return
	end
	local explored = (kind ~= nil) and (kind == _G.LE_GAME_ERR_ZONE_EXPLORED or kind == _G.LE_GAME_ERR_ZONE_EXPLORED_XP)
	if not explored and GetGameMessageInfo then
		local ok, name = pcall(GetGameMessageInfo, kind)
		explored = ok and EXPLORED[name] == true
	end
	if explored then
		self:Add(self:WorldSeries(), POINTS.explore, "explore")
		ns.Fire("ACTIVITY", "explore", 1)
		-- (1.6.0: the talent Explorer)
		if ns.Talents then
			ns.Talents:Explored(self:WorldSeries())
		end
	end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local f = CreateFrame("Frame")
R.frame = f
f:RegisterEvent("PLAYER_LOGIN")

-- some things are read a moment after their event (the map, the quest log, the skills)
local function Soon(key, delay, fn)
	R.soon = R.soon or {}
	if R.soon[key] then
		return
	end
	R.soon[key] = true
	ns.Delay(delay, function()
		R.soon[key] = nil
		fn()
	end, R)
end

CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "PARTY_KILL", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "ENCOUNTER_END", "BOSS_KILL",
			"UI_INFO_MESSAGE", "QUEST_LOG_UPDATE", "SKILL_LINES_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
			"PLAYER_ENTERING_WORLD" }) do
			pcall(f.RegisterEvent, f, e)
		end
		R:Seed()
		R:KeepLevel()
		Soon("visit", 1, function()
			R:Visit()
		end)
		Soon("skills", 2, function()
			R:ScanSkills()
		end)
	elseif event == "PARTY_KILL" then
		local _, target = unpack(arg, 1, arg.n)
		R:OnKillEvent(NpcFromGUID(target), (type(target) == "string" and not Secret(target)) and target or nil)
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local name = XPName(unpack(arg, 1, arg.n))
		if name then
			R:OnXPLine(name)
		end
	elseif event == "ENCOUNTER_END" or event == "BOSS_KILL" then
		local _, name, _, _, success = unpack(arg, 1, arg.n)
		if event == "ENCOUNTER_END" and (Secret(success) or success ~= 1) then
			return
		end
		local s = R:InstanceSeries()
		if s then
			R:OnBoss(s, R:BossByName(s, name), (type(name) == "string" and not Secret(name)) and name or nil, true)
		end
	elseif event == "QUEST_TURNED_IN" then
		-- (1.14.0: the quest, its experience, its money)
		R:OnQuestTurnedIn(unpack(arg, 1, arg.n))
	elseif event == "QUEST_LOG_UPDATE" then
		Soon("objectives", 0.3, function()
			R:ScanObjectives()
		end)
	elseif event == "SKILL_LINES_CHANGED" then
		Soon("skills", 0.3, function()
			R:ScanSkills()
		end)
	elseif event == "UI_INFO_MESSAGE" then
		R:OnInfoMessage((unpack(arg, 1, arg.n)))
	elseif event == "PLAYER_LEVEL_UP" then
		R:KeepLevel((unpack(arg, 1, arg.n)))
		-- (1.14.0: the level known before its points: a reroll that reaches its level of the chest is no reroll)
		if ns.Reroll then
			ns.Reroll:OnLevel((unpack(arg, 1, arg.n)))
		end
		R:Add(R:WorldSeries(), POINTS.level, "level")
		ns.Fire("ACTIVITY", "level", 1)
	else
		-- a new place (zone, sub-zone, instance)
		Soon("visit", 0.5, function()
			R:Visit()
		end)
	end
end)

-- The places visited before they were kept (0.9 and before): the albums whose gauge moved (the gauges
-- of 1.1 and before) and the dungeons completed.
function R:Seed()
	local db = ns.db
	if not db or db.visitedInit then
		return
	end
	db.visitedInit = true
	for key, p in pairs(db.progress or {}) do
		if p > 0 and ns.SeriesByKey(key) then
			db.visited[key] = true
		end
	end
	for key in pairs((db.stats and db.stats.done) or {}) do
		if ns.SeriesByKey(key) then
			db.visited[key] = true
		end
	end
end
