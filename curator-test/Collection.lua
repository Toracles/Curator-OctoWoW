local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

local C = {}
ns.Collection = C
ns.Cards = {}

-- Booster of a zone (1.2): 8 cards (1.14.0, his word: the collection is played over a year, not two weeks; 10
-- before), each drawn on its own; nothing is sure (no rare card in about one booster out of two), and no guarantee
-- after a run of bad luck: the contracts turn the copies into better cards. Each card: mythic 0.05 %, legendary
-- 0.25 %, epic 1.2 %, rare 6.5 %, uncommon 22 %, otherwise common.
local CARD_ODDS = { { 6, 0.0005 }, { 5, 0.0025 }, { 4, 0.012 }, { 3, 0.065 }, { 2, 0.22 } }
local ZONE_CARDS = 8
-- Finish of each card: titanforged (holographic) 1 %, thunderforged (shiny) 1 %, otherwise normal (31 October, his
-- word: both at 1 %; 0.2 % and 0.8 % before).
local HOLO, SHINY = 0.01, 0.01
C.ODDS = { card = CARD_ODDS, cards = ZONE_CARDS, holo = HOLO, shiny = SHINY }

-- The boosters of the dungeons and the raids: 5 cards (1.4: 3 before), each rare, epic or legendary,
-- and now and then the mythic card of the album (its last boss) in the place of the best one. Their finishes are
-- forged: titanforged 1 % (31 October, his word: at least 1 %; 0.35 % before), thunderforged 1.3 % of the cards (they
-- are kept as the holographic and shiny copies of the cards).
local DUNGEON_ODDS = { { 5, 0.01 }, { 4, 0.10 } } -- each card: legendary 1 %, epic 10 %, otherwise rare
local DUNGEON_MYTHIC = 0.005                         -- the last boss: 0.5 % of the boosters
local TITAN, THUNDER = 0.01, 0.013
C.DUNGEON = { size = 5, odds = DUNGEON_ODDS, mythic = DUNGEON_MYTHIC, titan = TITAN, thunder = THUNDER }

-- (1.12.0) The boosters of an album of an event (Hallow's End: Hallow.lua): 5 cards, each drawn on its own. Each
-- card: mythic 0.4 %, legendary 1.5 %, epic 5 %, rare 15 %, uncommon 33 %, otherwise common.
local EVENT_ODDS = { { 6, 0.004 }, { 5, 0.015 }, { 4, 0.05 }, { 3, 0.15 }, { 2, 0.33 } }
local EVENT_CARDS = 5
C.EVENT = { size = EVENT_CARDS, odds = EVENT_ODDS }

-- (1.12.0) Corrupted: the finish of the albums of an event, in the place of the forged ones (no thunderforged nor
-- titanforged card there). One card in ten comes corrupted, the corruption of N'Zoth, drawn as it comes: from 1 to
-- 100 %, the high ones rarer (half of them under 25 %, one in eight over 75 %, 100 % one in two hundred). Each corrupted
-- copy keeps its own, never fused with another: e.cl (the corruption of each copy not sealed, the highest first); e.c
-- (how many corrupted copies, the one sealed with them: Seal.lua) and e.k (the highest of them). A corrupted copy never
-- leaves the album (no trade, no contract, no duel: Contract.lua K.Copies) and is never appraised (Expertise.lua): a
-- Master of Warlocks seals one, a Master of Priests purifies them (Seal.lua).
local CORRUPT = 0.1
local CORRUPT_MIN, CORRUPT_MAX = 1, 100
C.CORRUPT, C.CORRUPT_MIN, C.CORRUPT_MAX, C.CORRUPT_FULL = CORRUPT, CORRUPT_MIN, CORRUPT_MAX, 100

-- The corruption a corrupted copy brings (CORRUPT_MIN to CORRUPT_MAX).
function C:RollCorruption()
	return math.max(CORRUPT_MIN, math.min(CORRUPT_MAX, math.floor(1 + 100 * math.random() ^ 2)))
end

local function Gauge(v)
	return math.max(CORRUPT_MIN, math.min(CORRUPT_MAX, math.floor(tonumber(v) or CORRUPT_MIN)))
end
C.Gauge = Gauge

-- The corrupted copies of a card not sealed (its entry): the corruption of each, the highest first ({}: none). (The
-- saves of the tests of 1.12.0: their one corrupted copy, e.k, a list of one.)
function C:CorruptCopies(e)
	if type(e) ~= "table" then
		return {}
	end
	if type(e.cl) ~= "table" then
		local list = {}
		if (tonumber(e.c) or 0) > 0 and (e.n or 0) > 0 then
			list[1] = Gauge(e.k)
		end
		e.cl = list
	end
	return e.cl
end

-- How many corrupted copies and the highest corruption of them, again (e.c, e.k), after a change: those not sealed,
-- the one sealed (Seal.lua).
function C:SyncCorrupt(card, e)
	if type(e) ~= "table" then
		return
	end
	local list = self:CorruptCopies(e)
	for i, v in ipairs(list) do
		list[i] = Gauge(v)
	end
	table.sort(list, function(a, b)
		return a > b
	end)
	-- (1.13.0: each copy sealed, the copies of a card one by one: Seal.lua)
	local sealed = card and ns.Masters and ns.Masters.KeptAll and ns.Masters:KeptAll(card) or {}
	local n, top = CuratorOctoFull.Length(list), list[1]
	if CuratorOctoFull.Length(sealed) > 0 then
		n = n + CuratorOctoFull.Length(sealed)
		top = math.max(top or 0, sealed[1])
	end
	if n > 0 then
		e.c, e.k = n, top
	else
		e.c, e.k = nil, nil
	end
end

-- The finish of a card of an album of an event: "corrupt" (and its corruption) or nil.
function C:RollEventFinish()
	if math.random() < CORRUPT then
		return "corrupt", self:RollCorruption()
	end
	return nil
end

-- The corruption of a card as the album shows it (0: not corrupted): the copy sealed, else the most corrupted.
function C:Corruption(card)
	local e = card and self:Entry(card)
	if not (e and (e.c or 0) > 0) then
		return 0
	end
	local sealed = ns.Masters and ns.Masters:Kept(card)
	return sealed or Gauge(e.k)
end

-- "90 %, 60 % (sealed), 12 %": the corruption of every corrupted copy of a card ("": none).
function C:CorruptLine(card)
	local e = card and self:Entry(card)
	if not (e and (e.c or 0) > 0) then
		return ""
	end
	local parts = {}
	for _, v in ipairs(self:CorruptCopies(e)) do
		parts[CuratorOctoFull.Length(parts) + 1] = { v, false }
	end
	for _, v in ipairs(ns.Masters and ns.Masters.KeptAll and ns.Masters:KeptAll(card) or {}) do
		parts[CuratorOctoFull.Length(parts) + 1] = { v, true }
	end
	table.sort(parts, function(a, b)
		if a[1] ~= b[1] then
			return a[1] > b[1]
		end
		return a[2] and not b[2]
	end)
	for i, x in ipairs(parts) do
		parts[i] = x[2] and string.format(L["%d %% (sealed)"], x[1]) or string.format(("%d %%"), x[1])
	end
	return table.concat(parts, ", ")
end

local function PerRarity(v)
	local t = {}
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		t[r] = (v == nil) and {} or v
	end
	return t
end
C.PerRarity = PerRarity

function C:Init()
	for _, s in ipairs(ns.Series or {}) do
		if s.cards then
			s.byRarity = PerRarity()
			s.list = {}
			s.dungeon = s.kind == "dungeon"
			-- (1.12.0: an album of an event, its cards those of other albums, each a card of its own: card.real,
			-- the creature's npc)
			local offset = s.event and s.offset or nil
			s.bossSet = {}
			for _, id in ipairs(s.bosses or {}) do
				s.bossSet[id] = true
			end
			for i, row in ipairs(s.cards) do
				-- (the dungeons and the raids have no common card: their creatures are rare at least;
				-- base: the rarity of the creature, which sets how often its card is found on it)
				local rarity = (s.dungeon and row[2] < 3) and 3 or row[2]
				local card = {
					key = "c" .. row[1], npc = row[1], rarity = rarity, base = row[2], type = row[3], family = row[4],
					lo = row[5], hi = row[6], display = row[7], sound = row[8], friendly = row[9],
					num = i, series = s, real = offset and (row[1] - offset) or nil,
				}
				-- (1.13.0, the Hardcup Saison 3: a participant, his picture in the window of his card, no creature; hkey:
				-- his key, as the website knows him)
				if s.pictures and s.pictures[row[1]] then
					card.hkey = s.pictures[row[1]]
					card.art = { file = ns.MEDIA .. "Faces\\" .. card.hkey, fill = true }
				end
				-- (1.14.0) the contraband of the Hardcup Saison 3 (RVN, Curator Hardcup 1.0.2): a mythic card here, in its
				-- look (UI/Card.lua: card.smuggle)
				if s.contraband and s.contraband[row[1]] then
					card.smuggle = true
				end
				s.list[i] = card
				CuratorOctoFull.Insert(s.byRarity[card.rarity], card)
				ns.Cards[card.key] = card
			end
			-- (1.14.0) the cards of the album but its contraband (46/45): those it counts
			s.official = 0
			for _, card in ipairs(s.list) do
				if not card.smuggle then
					s.official = s.official + 1
				end
			end
			-- the rows are now cards; of the names, those in the client's language and in English
			-- (the fallback) are all that is kept
			s.cards = nil
			for _, field in ipairs({ "names", "subs" }) do
				for loc in pairs(s[field] or {}) do
					if loc ~= "enUS" and loc ~= ns.locale then
						s[field][loc] = nil
					end
				end
			end
		end
	end
	-- (1.12.0) no forged copy in an album of an event: those a test build gave are plain copies now
	for key, e in pairs((ns.db and ns.db.cards) or {}) do
		local card = ns.Cards[key]
		if card and card.series and card.series.event and type(e) == "table" and ((tonumber(e.s) or 0) > 0 or (tonumber(e.h) or 0) > 0) then
			e.s, e.h = 0, nil
		end
	end
end

function C:Name(card)
	local s = card.series
	local t = s.names[ns.locale]
	return (t and t[card.npc]) or s.names.enUS[card.npc] or "?"
end

function C:Sub(card)
	local s = card.series
	local t = s.subs[ns.locale]
	return (t and t[card.npc]) or s.subs.enUS[card.npc]
end

local TYPE_FALLBACK = { "Beast", "Dragonkin", "Demon", "Elemental", "Giant", "Undead", "Humanoid", "Critter", "Mechanical" }
function C:TypeName(card)
	if C_CreatureInfo and C_CreatureInfo.GetCreatureTypeInfo then
		local ok, info = pcall(C_CreatureInfo.GetCreatureTypeInfo, card.type)
		if ok and info and info.name and info.name ~= "" then
			return info.name
		end
	end
	return TYPE_FALLBACK[card.type] or ""
end

function C:LevelText(card)
	-- (1.13.0: a participant of the Hardcup Saison 3, a picture: no level)
	if card.art and card.art.fill then
		return ""
	end
	if card.lo == card.hi then
		return string.format(L["Level %d"], card.lo)
	end
	return string.format(L["Level %d-%d"], card.lo, card.hi)
end

-- What the card shows on its parchment: the creature type, or the title of a character.
function C:TypeLine(card)
	return (card.friendly and self:Sub(card)) or self:TypeName(card) or ""
end

-- "Bête · Niveau 5-6", or the title of a character ("Aubergiste · Niveau 30").
function C:Line(card)
	local first = (card.friendly and self:Sub(card)) or self:TypeName(card)
	local level = self:LevelText(card)
	-- (1.13.0: a card of no level, a participant of the Hardcup Saison 3: its title alone)
	if first and first ~= "" and level ~= "" then
		return first .. " · " .. level
	end
	return (first and first ~= "") and first or level
end

-- GetRealZoneText(instance) gives a dungeon's name in the client's language, on clients where it
-- reads its argument (two dungeons must not get the same name).
local realZone
local function DungeonName(id)
	if realZone == nil then
		realZone = false
		if GetRealZoneText then
			local ok1, a = pcall(GetRealZoneText, 36)
			local ok2, b = pcall(GetRealZoneText, 34)
			realZone = ok1 and ok2 and type(a) == "string" and type(b) == "string" and a ~= "" and b ~= "" and a ~= b
		end
	end
	if realZone then
		local ok, name = pcall(GetRealZoneText, id)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
end

function C:SeriesName(s)
	if not s then
		return "?"
	end
	if s.localName then
		return s.localName
	end
	local name
	if s.event or s.limited then
		-- (1.12.0) an album of an event: its own name, in this language (1.13.0: a limited edition too)
		name = (s.title and s.title[ns.locale]) or s.name
	elseif s.dungeon then
		-- the dungeons: their name in this language, else the client's, else English
		name = (s.title and s.title[ns.locale]) or DungeonName(s.instance)
	elseif C_Map and C_Map.GetMapInfo then
		local ok, info = pcall(C_Map.GetMapInfo, s.map)
		if ok and info and type(info.name) == "string" and info.name ~= "" then
			name = info.name
		end
	end
	if name then
		s.localName = name
		return name
	end
	return (s.title and s.title[ns.locale]) or s.name
end

-- "Niveaux 15-25", "Niveau 60"
function C:LevelRange(s)
	if s.levels[1] == s.levels[2] then
		return string.format(L["Level %d"], s.levels[1])
	end
	return string.format(L["Levels %d-%d"], s.levels[1], s.levels[2])
end

-- Cards owned and cards in all the albums.
function C:Overall()
	local owned, total = 0, 0
	for _, s in ipairs(ns.Series or {}) do
		-- (1.12.0: an album of an event counts in no total, Hallow.lua; 1.13.0: a limited edition neither)
		if not s.event and not s.limited then
			local o, t = self:Progress(s)
			owned, total = owned + o, total + t
		end
	end
	return owned, total
end

function C:Entry(card)
	return ns.db and ns.db.cards[card.key]
end

function C:Owned(card)
	local e = self:Entry(card)
	return e and e.n > 0
end

function C:Progress(s)
	local owned, byRarity = 0, PerRarity(0)
	for _, card in ipairs(s.list) do
		if self:Owned(card) then
			-- (1.14.0: the contraband of the Hardcup Saison 3 out of the cards of its album, s.official, as in Curator
			-- Hardcup: 46/45)
			if not card.smuggle then
				owned = owned + 1
			end
			byRarity[card.rarity] = byRarity[card.rarity] + 1
		end
	end
	return owned, s.official or CuratorOctoFull.Length(s.list), byRarity
end

-- The odds of a booster of an album, as its draw makes them (a rarity the album has no card of gives
-- its chance to the one under it): rar[r] (each card), mythic (a dungeon or a raid: its last boss, a
-- booster in so many), rareBooster (a zone: the boosters with a rare card or better), the finishes
-- of each card (shiny and holo: in a dungeon or a raid, thunderforged and titanforged) and the chance
-- a booster has at least one (shinyPack, holoPack), cards (how many a booster holds).
function C:Odds(s, plain, ctx)
	local out = { dungeon = s.dungeon and true or false, rar = {} }
	-- (1.6.0: the talents of the Augur change them; plain: as they are for everyone. 1.15.0, ctx: a situation given,
	-- for the page of the statistics: Talents.lua, TL:BoosterMods)
	local m = not plain and ns.Talents and ns.Talents:BoosterMods(s, ctx or { preview = true }) or nil
	out.talents = m ~= nil
	local function put(r, p)
		while r > 1 and CuratorOctoFull.Length(s.byRarity[r]) == 0 do
			r = r - 1
		end
		out.rar[r] = (out.rar[r] or 0) + p
	end
	local rest = 1
	out.event = s.event ~= nil
	for _, o in ipairs((s.dungeon and DUNGEON_ODDS) or (s.event and EVENT_ODDS) or CARD_ODDS) do
		local p = o[2] * ((m and m.rar[o[1]]) or 1)
		put(o[1], p)
		rest = rest - p
	end
	put(s.dungeon and 3 or 1, rest)
	if s.dungeon then
		out.mythic = CuratorOctoFull.Length(s.byRarity[6]) > 0 and DUNGEON_MYTHIC * ((m and m.rar[6]) or 1) or 0
		out.holo, out.shiny, out.cards = TITAN, THUNDER, C.DUNGEON.size
	else
		out.holo, out.shiny, out.cards = HOLO, SHINY, ZONE_CARDS
		if s.event then
			out.holo, out.shiny, out.cards = 0, 0, EVENT_CARDS
			out.corrupt = CORRUPT
		end
		local fine = 0
		for r = 3, CuratorOctoFull.Length(ns.RARITY) do
			fine = fine + (out.rar[r] or 0)
		end
		out.rareBooster = 1 - (1 - fine) ^ out.cards
	end
	if m then
		out.holo, out.shiny = out.holo * m.holo, out.shiny * m.shiny
	end
	out.holoPack = 1 - (1 - out.holo) ^ out.cards
	out.shinyPack = 1 - (1 - out.shiny) ^ out.cards
	if out.corrupt then
		out.corruptPack = 1 - (1 - out.corrupt) ^ out.cards
	end
	return out
end

-- The finish of a new copy: "holo", "shiny" or nil (normal). forged: a card of a dungeon booster
-- (titanforged and thunderforged, kept as holographic and shiny). m: what the talents change (1.6.0; 1.14.0, the
-- Gambler's Flourish: the epic cards and better thunderforged more often), rarity: the rarity of the card.
function C:RollFinish(forged, m, rarity)
	local r = math.random()
	local top, second = HOLO, SHINY
	if forged then
		top, second = TITAN, THUNDER
	end
	if m then
		top = top * (m.holo or 1)
		second = second * (m.shiny or 1)
		if (rarity or 1) >= 4 then
			second = second + (m.flourish or 0)
		end
	end
	if r < top then
		return "holo"
	elseif r < top + second then
		return "shiny"
	end
end

-- The cards of the dungeons and the raids: their finishes come more often there, and give more
-- experience (Level.lua). (Before 1.3 they had names and looks of their own, thunderforged and
-- titanforged: since, every card has them.)
function C:Forged(card)
	return (card and card.series and (card.series.dungeon or card.series.event)) and true or false
end

-- The name of a finish: Thunderforged, Titanforged (nil: normal). (1.3: the shiny cards became
-- thunderforged, the holographic ones titanforged; "shiny" and "holo" stay the names kept in the saves
-- and the messages.)
function C:FinishName(card, finish)
	if finish == "holo" then
		return L["Titanforged"]
	elseif finish == "shiny" or finish == true then
		return L["Thunderforged"]
	elseif finish == "corrupt" then
		return L["Corrupted"]
	end
end

-- Its look on the card: "thunder" or "titan" (nil: normal).
function C:FinishLook(card, finish)
	if finish == "holo" then
		return "titan"
	elseif finish == "shiny" or finish == true then
		return "thunder"
	elseif finish == "corrupt" then
		return "corrupt"
	end
end

-- "Titanforged copies: 2" and the like, for a card (or a whole album: s).
function C:CopiesLine(card, finish, n, s)
	if finish == "holo" then
		return string.format(L["Titanforged copies: %d"], n)
	elseif finish == "corrupt" then
		return string.format(L["Corrupted copies: %d"], n)
	end
	return string.format(L["Thunderforged copies: %d"], n)
end

-- The finest finish of a card owned (what the album shows): "holo", "shiny" or nil.
function C:BestFinish(e)
	if e and (e.c or 0) > 0 then
		return "corrupt"
	elseif e and (e.h or 0) > 0 then
		return "holo"
	elseif e and (e.s or 0) > 0 then
		return "shiny"
	end
end

-- One more copy of a card, with its finish. Returns new (its first copy), the entry. (1.12.0) A corrupted copy
-- (corruption: its own, never fused with another): among the corrupted copies of the card.
function C:Add(card, finish, corruption)
	local db = ns.db
	-- (1.14.0: a card changed by another addon this session: no copy of it comes; nothing comes once one was, Guard.lua)
	if ns.Guard and not ns.Guard:Allow(nil, card) then
		return false, { n = 0, s = 0 }
	end
	local e = db.cards[card.key]
	if not e then
		e = { n = 0, s = 0, t = CuratorOctoFull.ServerTime() }
		db.cards[card.key] = e
	end
	-- (no forged copy in an album of an event, no corrupted one elsewhere)
	local event = card.series ~= nil and card.series.event ~= nil
	if (event and (finish == "shiny" or finish == "holo" or finish == true)) or (not event and finish == "corrupt") then
		finish = nil
	end
	local new = e.n == 0
	e.n = e.n + 1
	if finish == "shiny" then
		e.s = (e.s or 0) + 1
	elseif finish == "holo" then
		e.h = (e.h or 0) + 1
	elseif finish == "corrupt" then
		local list = self:CorruptCopies(e)
		list[CuratorOctoFull.Length(list) + 1] = Gauge(corruption)
		self:SyncCorrupt(card, e)
	end
	-- (a card found for the first time is new in the album until it has been seen there)
	if new then
		db.fresh = db.fresh or {}
		db.fresh[card.key] = true
	end
	-- (1.14.0: the talents of the albums of the zones, Atlas and Road of Gems: Talents.lua)
	if new and ns.Talents and ns.Talents.NewCard then
		ns.Talents:NewCard(card)
	end
	-- (1.13.0) the copy on its own: its story, its expertise (Copies.lua)
	if ns.Copies then
		ns.Copies:Added(card, finish, corruption)
	end
	return new, e
end

-- The cards new in the album: not yet seen there since they were found.
function C:Fresh(card)
	local f = ns.db and ns.db.fresh
	return f ~= nil and f[card.key] == true
end

-- Seen: not new any more. True when it was.
function C:SeeFresh(card)
	local f = ns.db and ns.db.fresh
	if f and f[card.key] then
		f[card.key] = nil
		return true
	end
	return false
end

-- How many cards are new in an album (in all of them: nil).
function C:FreshCount(s)
	local f = ns.db and ns.db.fresh
	if not f or not next(f) then
		return 0
	end
	local n = 0
	if s then
		for _, card in ipairs(s.list) do
			if f[card.key] then
				n = n + 1
			end
		end
		return n
	end
	for key in pairs(f) do
		if ns.Cards[key] then
			n = n + 1
		end
	end
	return n
end

-- Every new card seen at once (Mark all as seen, on the contents: 1.8.0). How many were new.
function C:SeeAllFresh()
	local n = self:FreshCount()
	local f = ns.db and ns.db.fresh
	if f then
		CuratorOctoFull.Wipe(f)
	end
	return n
end

local function pick(s, rarity, used, m)
	while rarity > 1 and CuratorOctoFull.Length(s.byRarity[rarity]) == 0 do
		rarity = rarity - 1
	end
	local pool = s.byRarity[rarity]
	-- (1.6.0: the cards missing came more often, those of many copies less, with talents of before 1.14.0; never one
	-- already in the booster when another can come)
	if m and ((m.newdeal or 0) > 0 or (m.memory or 0) > 0) then
		local total, cand = 0, {}
		for _, c in ipairs(pool) do
			if not used[c.key] then
				local w = ns.Talents:Weight(m, c)
				total = total + w
				cand[CuratorOctoFull.Length(cand) + 1] = { c, w }
			end
		end
		if total > 0 then
			local x = math.random() * total
			local got = cand[CuratorOctoFull.Length(cand)][1]
			for _, it in ipairs(cand) do
				x = x - it[2]
				if x <= 0 then
					got = it[1]
					break
				end
			end
			used[got.key] = true
			return got
		end
	end
	local card
	for _ = 1, 12 do
		card = pool[math.random(CuratorOctoFull.Length(pool))]
		if not used[card.key] then
			break
		end
	end
	used[card.key] = true
	return card
end

-- (1.5.0) The secret feats of a booster kept (s its album, picks its cards, r the rarity of its best one):
-- every rarity from common to legendary, two legendary cards or better, a booster at night (the time of
-- the player), 25 in a day, 30 in a row without an epic card, a mythic card in the first booster of a
-- dungeon or a raid.
function C:SecretFeats(s, picks, r)
	local st = ns.Stats()
	local has, legs = {}, 0
	for _, p in ipairs(picks) do
		has[p.card.rarity] = true
		if p.card.rarity >= 5 then
			legs = legs + 1
		end
	end
	if has[1] and has[2] and has[3] and has[4] and has[5] then
		st.rainbow = true
	end
	if legs >= 2 then
		st.dleg = true
	end
	local clock = date or (os and os.date)
	local now = clock and clock("*t")
	if now and now.hour >= 3 and now.hour < 5 then
		st.night = true
	end
	local day = now and string.format(("%d-%d-%d"), now.year, now.month, now.day) or "-"
	if st.dayKey ~= day then
		st.dayKey, st.dayN = day, 0
	end
	st.dayN = (st.dayN or 0) + 1
	if st.dayN >= 25 then
		st.marathon = true
	end
	if r >= 4 then
		st.dry = 0
	else
		st.dry = (st.dry or 0) + 1
		if st.dry >= 30 then
			st.unlucky = true
		end
	end
	if s.dungeon and not picks.golden then
		if (st.lairs or 0) == 0 and r >= ns.MYTHIC then
			st.firstmyth = true
		end
		st.lairs = (st.lairs or 0) + 1
	end
end

-- Saves the cards of a booster (not a preview): their copies, the booster spent, the feats. (1.10.0) gold:
-- a golden booster ({ t = its ticket }): its cards come "g" in the journal, with its ticket, and it is spent
-- from the golden boosters waiting (Golden.lua).
-- (1.14.0) A booster held for an omen: what it drew, as it drew it. The scene shows its picks on its cards, and another
-- addon reaches the cards (EnumerateFrames): what is kept (C:KeepHeld) is what was drawn, whatever was done meanwhile to
-- what is shown.
local HELD = setmetatable({}, { __mode = "k" })
-- (and each card of a booster kept, as it was kept: what a talent draws again, C:Redraw, takes back what came, not
-- what the card shown says now)
local KEPT = setmetatable({}, { __mode = "k" })
local function Held(picks, s, best, gold)
	local drawn = {}
	for i, p in ipairs(picks) do
		drawn[i] = { p = p, card = p.card, finish = p.finish, corrupt = p.corrupt, star = p.star, fate = p.fate }
	end
	HELD[picks] = { s = s, best = best, gold = gold and { t = gold.t } or nil, drawn = drawn, star = picks.star, extra = picks.extra,
		fate = picks.fate }
end

local function Keep(self, s, picks, best, gold)
	local db = ns.db
	-- (1.14.0: its album and its cards as they must be, else nothing is kept, the booster stays: Guard.lua)
	local GD = ns.Guard
	if GD then
		if not GD:Allow(s) then
			return false
		end
		for _, p in ipairs(picks) do
			if not GD:Allow(nil, p.card) then
				return false
			end
		end
	end
	local finishes = 0
	-- (1.7.0: the number of this booster, for the journal: the boosters opened before it, plus one)
	self.boosterNo = (tonumber(db.opened) or 0) + 1
	for _, p in ipairs(picks) do
		local new, e = self:Add(p.card, p.finish, p.corrupt)
		p.new, p.count = new, e.n
		-- (1.13.0: its copy, the one a talent would draw again: Redraw; 1.14.0: a titanforged one, its pattern)
		p.ci = ns.Copies and ns.Copies.last and ns.Copies.last.i or nil
		p.pt = ns.Copies and ns.Copies.Pattern(ns.Copies.last) or nil
		-- (his idea, 31 October: its wear, Wear.lua)
		p.wear = ns.Wear and ns.Copies and ns.Wear.Of(ns.Copies.last) or nil
		if p.finish then
			finishes = finishes + 1
		end
		self:Remember(p.card, p.finish, gold and "g" or "b", gold and tostring(gold.t) or nil)
	end
	self.boosterNo = nil
	db.opened = db.opened + 1
	-- (1.12.0: the boosters of an album of an event opened, for its achievements)
	if s.event then
		local st = ns.Stats()
		st.hallowOpen = (tonumber(st.hallowOpen) or 0) + 1
	end
	if gold then
		ns.Golden:Spend(gold.t)
	else
		db.packs[s.key] = math.max(0, (db.packs[s.key] or 0) - 1)
	end
	-- (1.6.0: the boosters of the day of the talents)
	if ns.Talents then
		ns.Talents:Kept(s, picks)
	end
	-- the experience of its cards (each one keeps its own: p.xp), then what follows a booster opened
	if ns.Level then
		ns.Level:Booster(picks)
	end
	for _, p in ipairs(picks) do
		KEPT[p] = { card = p.card, finish = p.finish, corrupt = p.corrupt, ci = p.ci, xp = p.xp }
	end
	ns.Fire("BOOSTER_OPENED", s, picks)
	-- the feats of the achievements
	local st = ns.Stats()
	local r = best.card.rarity
	if r >= 5 and db.opened <= 10 then
		st.lucky = true
	end
	if finishes >= 2 then
		st.double = true
	end
	for _, p in ipairs(picks) do
		if p.card.rarity >= 5 and p.finish then
			st.jackpot = true
		end
	end
	-- (1.5.0) the secret feats of the achievements
	self:SecretFeats(s, picks, r)
	ns.Fire("CHANGED")
end

-- The rarity of one card of a booster of a zone (mult: the odds of each rarity raised by the talents,
-- 1.6.0).
local function RollRarity(mult)
	local r = math.random()
	for _, o in ipairs(CARD_ODDS) do
		local p = mult and o[2] * (mult[o[1]] or 1) or o[2]
		if r < p then
			return o[1]
		end
		r = r - p
	end
	return 1
end

-- (1.12.0) The rarity of one card of a booster of an event.
local function EventRarity(mult)
	local r = math.random()
	for _, o in ipairs(EVENT_ODDS) do
		local p = mult and o[2] * (mult[o[1]] or 1) or o[2]
		if r < p then
			return o[1]
		end
		r = r - p
	end
	return 1
end

-- The rarity of one card of a booster of a dungeon or a raid: rare at least.
local function DungeonRarity(mult)
	local r, top = math.random(), 3
	for _, o in ipairs(DUNGEON_ODDS) do
		local p = mult and o[2] * (mult[o[1]] or 1) or o[2]
		if r < p then
			top = o[1]
			break
		end
		r = r - p
	end
	return top
end

-- (1.6.0, Favor of the Stars) The rarity of the card more of the first booster of the day: epic or better.
local function StarRarity()
	local r = math.random()
	for _, o in ipairs(ns.Talents.STAR_ODDS) do
		if r < o[2] then
			return o[1]
		end
		r = r - o[2]
	end
	return 4
end

-- A card of the rarity given that is not in the booster yet, else of the rarity under it (in the end,
-- a card again).
local function PickFree(s, rarity, used)
	for r = rarity, 1, -1 do
		local free = {}
		for _, card in ipairs(s.byRarity[r]) do
			if not used[card.key] then
				free[CuratorOctoFull.Length(free) + 1] = card
			end
		end
		if CuratorOctoFull.Length(free) > 0 then
			local card = free[math.random(CuratorOctoFull.Length(free))]
			used[card.key] = true
			return card
		end
	end
	return pick(s, rarity, used)
end

-- (1.6.0, New Deal, Card Memory) A card of a dungeon or a raid, no card twice in the booster, by the weight of
-- each card (as PickFree without them).
local function PickWeighted(s, rarity, used, m)
	if not (m and ((m.newdeal or 0) > 0 or (m.memory or 0) > 0)) then
		return PickFree(s, rarity, used)
	end
	for r = rarity, 1, -1 do
		local total, cand = 0, {}
		for _, card in ipairs(s.byRarity[r]) do
			if not used[card.key] then
				local w = ns.Talents:Weight(m, card)
				total = total + w
				cand[CuratorOctoFull.Length(cand) + 1] = { card, w }
			end
		end
		if CuratorOctoFull.Length(cand) > 0 and total > 0 then
			local x = math.random() * total
			local got = cand[CuratorOctoFull.Length(cand)][1]
			for _, it in ipairs(cand) do
				x = x - it[2]
				if x <= 0 then
					got = it[1]
					break
				end
			end
			used[got.key] = true
			return got
		end
	end
	return PickFree(s, rarity, used)
end

-- (1.14.0, the Gambler: Opening Stake, Winning Streak) One of the cards a rarity higher, up to top (epic): one under it
-- whose album has cards of the rarity above. id: the talent that raises it (the scene tells it over the card).
local function Raise(s, picks, used, top, id)
	local cand = {}
	for i, p in ipairs(picks) do
		local up = p.card.rarity + 1
		if up <= (top or 4) and CuratorOctoFull.Length((s.byRarity[up] or {})) > 0 then
			cand[CuratorOctoFull.Length(cand) + 1] = i
		end
	end
	if CuratorOctoFull.Length(cand) == 0 then
		return false
	end
	local p = picks[cand[math.random(CuratorOctoFull.Length(cand))]]
	local up = p.card.rarity + 1
	p.card = s.dungeon and PickFree(s, up, used) or pick(s, up, used)
	p.raised = id or true
	picks.raised = true
	return true
end

-- (1.14.0, the Gambler) After the draw of a booster: its cards raised now and then (m.raise: the chance of each talent).
local function Gamble(s, picks, used, m)
	if not m then
		return
	end
	for _, r in ipairs(m.raise or {}) do
		local id, chance = r[1], r[2]
		if type(r) ~= "table" then
			id, chance = nil, r
		end
		if math.random() < (tonumber(chance) or 0) then
			Raise(s, picks, used, 4, id)
		end
	end
end

-- (1.14.0, the Gambler) After the finishes: Jackpot (a legendary card or better, the whole booster thunderforged now and
-- then), Loaded Dice (two cards of a rarity, rare or better: one of them thunderforged now and then).
local function GambleFinish(s, picks, m)
	if not m or s.event then
		return
	end
	local legend, byR = false, {}
	for _, p in ipairs(picks) do
		local r = p.card.rarity
		if r >= 5 then
			legend = true
		end
		if r >= 3 then
			byR[r] = (byR[r] or 0) + 1
		end
	end
	if legend and (m.jackpot or 0) > 0 and math.random() < m.jackpot then
		for _, p in ipairs(picks) do
			if not p.finish then
				p.finish, p.jackpot = "shiny", true
			end
		end
		picks.jackpot = true
		return
	end
	if (m.loaded or 0) > 0 then
		for r, n in pairs(byR) do
			if n >= 2 and math.random() < m.loaded then
				local cand = {}
				for _, p in ipairs(picks) do
					if p.card.rarity == r and not p.finish then
						cand[CuratorOctoFull.Length(cand) + 1] = p
					end
				end
				if CuratorOctoFull.Length(cand) > 0 then
					local p = cand[math.random(CuratorOctoFull.Length(cand))]
					p.finish, p.loaded = "shiny", true
					picks.loaded = true
				end
				break
			end
		end
	end
end

-- (1.6.0, Double) A card with a finish: another card of the booster gets it too, now and then.
local function Double(picks, m)
	local src
	for _, p in ipairs(picks) do
		if p.finish then
			src = p
			break
		end
	end
	if not src or math.random() >= m.double then
		return
	end
	local cand = {}
	for _, p in ipairs(picks) do
		if not p.finish then
			cand[CuratorOctoFull.Length(cand) + 1] = p
		end
	end
	if CuratorOctoFull.Length(cand) > 0 then
		local p = cand[math.random(CuratorOctoFull.Length(cand))]
		p.finish, p.doubled = src.finish, true
		picks.double = true
	end
end

-- The best card of a booster (the rarest, the first of them; first: the one that must be it).
local function Best(picks, first)
	local best = first or picks[1]
	for _, p in ipairs(picks) do
		if p.card.rarity > best.card.rarity then
			best = p
		end
	end
	best.best = true
	return best
end

-- After the draw: the finishes (target: the card that gets the finish asked for, a preview's), what
-- the talents change.
local function Finish(self, s, picks, opts, m, target)
	for _, p in ipairs(picks) do
		if s.event then
			-- (1.12.0: an album of an event, its corruption)
			p.finish, p.corrupt = self:RollEventFinish()
		else
			p.finish = self:RollFinish(s.dungeon, m, p.card.rarity)
		end
	end
	if m and (m.double or 0) > 0 and not s.event then
		Double(picks, m)
	end
	GambleFinish(s, picks, m)
	if s.event then
		if opts.corrupt then
			target.finish, target.corrupt = "corrupt", (type(opts.corrupt) == "number" and opts.corrupt) or self:RollCorruption()
		end
	elseif opts.holo then
		target.finish = "holo"
	elseif opts.shiny then
		target.finish = "shiny"
	end
	for _, p in ipairs(picks) do
		p.shiny, p.holo = p.finish == "shiny", p.finish == "holo"
	end
end

-- Rolls a booster and saves it right away: closing the opening early never loses cards.
-- opts.force: a card of that rarity in it, the best one (in the place of one of the others), opts.shiny /
-- opts.holo: the finish of that card, opts.test: a preview (the /curator test boosters): free, and
-- nothing of it is kept. The best card of the booster (the rarest, the first of them) is marked: the
-- light of the pack tells its colour. (1.6.0) opts.hold: drawn, not kept yet (an omen: C:KeepHeld keeps
-- it, else it is drawn again); the talents of the Augur change the draw (not a preview's).
function C:Open(s, opts)
	opts = opts or {}
	if opts.golden then
		return self:OpenGolden(s, opts)
	end
	local m = (not opts.test) and ns.Talents and ns.Talents:BoosterMods(s) or nil
	-- (1.14.0, the Great Game: a booster of legend now and then, the first of the week)
	if m and m.grand then
		return self:OpenLegend(s, opts, m)
	end
	if s.dungeon then
		return self:OpenDungeon(s, opts, m)
	end
	local used, rar = {}, {}
	-- (1.12.0: an album of an event, five cards)
	local size = s.event and EVENT_CARDS or ZONE_CARDS
	local n = size
	-- (1.14.0, Double or Nothing: the bet on this booster, its cards more or fewer)
	local bet = (m and not opts.hold) and ns.Talents:Bet(s) or nil
	if bet then
		n = math.max(1, n + bet.delta)
	end
	for i = 1, n do
		rar[i] = s.event and EventRarity(m and m.rar) or RollRarity(m and m.rar)
	end
	local forced
	if opts.force then
		-- (the card asked for is the best one of the booster: the others are no better)
		local f = math.max(1, math.min(6, opts.force))
		forced = math.random(n)
		for i = 1, n do
			rar[i] = math.min(rar[i], f)
		end
		rar[forced] = f
	end
	-- (the rarest first: they keep their rarity, a rarity with no card left gives way to the one under
	-- it, and no card comes twice)
	local order = {}
	for i = 1, n do
		order[i] = i
	end
	table.sort(order, function(a, b)
		if rar[a] ~= rar[b] then
			return rar[a] > rar[b]
		end
		return a < b
	end)
	local picks = {}
	for _, i in ipairs(order) do
		picks[i] = { card = pick(s, rar[i], used) }
	end
	Gamble(s, picks, used, m)
	picks.bet = bet
	picks.extra = (bet and bet.delta > 0) or nil
	picks.grandTried = m and m.grandTried or nil
	local best = Best(picks, picks[forced or order[1]])
	Finish(self, s, picks, opts, m, picks[forced or 1])
	if opts.test then
		-- a preview: what the collection has of these cards, nothing more (1.14.0: a titanforged one, a pattern to see)
		for _, p in ipairs(picks) do
			local e = self:Entry(p.card)
			p.new, p.count = not (e and e.n > 0), e and e.n or 0
			p.pt = p.finish == "holo" and ns.Copies and ns.Copies.DrawPattern() or nil
			p.wear = ns.Wear and ns.Wear.Test(nil, ns.Wear.Hash(tostring(p.card and p.card.key) .. ":" .. tostring(debugprofilestop and debugprofilestop() or 0))) or nil
		end
		return picks
	end
	if opts.hold then
		picks.hold = { s = s, best = best }
		Held(picks, s, best)
		return picks
	end
	Keep(self, s, picks, best)
	return picks
end

-- (1.14.0, the Great Game) A booster of legend: five cards, epic or better, one of them legendary (the others drawn
-- among the epic, legendary and mythic cards as the booster would draw them), its finishes as the booster's.
function C:OpenLegend(s, opts, m)
	local used, picks = {}, {}
	local weights = {}
	for _, o in ipairs(s.dungeon and DUNGEON_ODDS or CARD_ODDS) do
		if o[1] >= 4 then
			weights[CuratorOctoFull.Length(weights) + 1] = { o[1], o[2] }
		end
	end
	if s.dungeon and CuratorOctoFull.Length((s.byRarity[6] or {})) > 0 then
		weights[CuratorOctoFull.Length(weights) + 1] = { 6, DUNGEON_MYTHIC / C.DUNGEON.size }
	end
	local total = 0
	for _, w in ipairs(weights) do
		total = total + w[2]
	end
	local function Draw()
		local x = math.random() * total
		for _, w in ipairs(weights) do
			x = x - w[2]
			if x <= 0 then
				return w[1]
			end
		end
		return 4
	end
	local rar = { 5 }
	for i = 2, 5 do
		rar[i] = Draw()
	end
	table.sort(rar, function(a, b)
		return a > b
	end)
	for i, r in ipairs(rar) do
		-- (an album without a card of that rarity: the rarity under it, epic at least)
		local x = r
		while x > 4 and CuratorOctoFull.Length((s.byRarity[x] or {})) == 0 do
			x = x - 1
		end
		picks[i] = { card = PickFree(s, x, used) }
	end
	picks.grand, picks.grandTried, picks.legend = true, true, true
	local best = Best(picks, picks[1])
	Finish(self, s, picks, opts, m, picks[1])
	for i = CuratorOctoFull.Length(picks), 2, -1 do
		local j = math.random(i)
		picks[i], picks[j] = picks[j], picks[i]
	end
	if opts.hold then
		picks.hold = { s = s, best = best }
		Held(picks, s, best)
		return picks
	end
	Keep(self, s, picks, best)
	return picks
end

-- A booster held for an omen: kept now, as it was drawn (1.14.0: as Curator drew it, see Held).
function C:KeepHeld(picks)
	local h = picks and picks.hold
	local mine = picks and HELD[picks]
	if not (h and mine) then
		return false
	end
	picks.hold = nil
	HELD[picks] = nil
	for i = CuratorOctoFull.Length(picks), 1, -1 do
		picks[i] = nil
	end
	for i, d in ipairs(mine.drawn) do
		local p = d.p
		p.card, p.finish, p.corrupt, p.star, p.fate = d.card, d.finish, d.corrupt, d.star, d.fate
		picks[i] = p
	end
	picks.star, picks.extra, picks.fate = mine.star, mine.extra, mine.fate
	-- (the booster must still be there: given in a trade meanwhile, nothing is kept)
	if mine.gold then
		if not ns.Golden:Pack(mine.gold.t) then
			return false
		end
	elseif ns.Packs(mine.s) <= 0 then
		return false
	end
	return Keep(self, mine.s, picks, mine.best, mine.gold) ~= false
end

-- A booster of a dungeon or a raid: 5 cards, each rare, epic or legendary, sometimes the mythic card
-- in the place of the best one. opts as for C:Open (opts.force: the rarity of the best card); m: what the talents
-- change (C:Open draws it).
function C:OpenDungeon(s, opts, m)
	opts = opts or {}
	if m == nil then
		m = (not opts.test) and ns.Talents and ns.Talents:BoosterMods(s) or nil
	end
	local used, picks = {}, {}
	local rar = {}
	local n = C.DUNGEON.size
	-- (1.14.0, Double or Nothing: the bet on this booster)
	local bet = (m and not opts.hold) and ns.Talents:Bet(s) or nil
	if bet then
		n = math.max(1, n + bet.delta)
	end
	for i = 1, n do
		rar[i] = DungeonRarity(m and m.rar)
	end
	local bestI = 1
	for i = 2, CuratorOctoFull.Length(rar) do
		if rar[i] > rar[bestI] then
			bestI = i
		end
	end
	if opts.force then
		local f = math.max(3, math.min(6, opts.force))
		rar[bestI] = f
		for i = 1, CuratorOctoFull.Length(rar) do
			rar[i] = math.min(rar[i], f)
		end
	elseif math.random() < DUNGEON_MYTHIC * ((m and m.rar[6]) or 1) then
		rar[bestI] = 6
	end
	-- (the best one first: it keeps its rarity; a rarity with no card left in the booster gives way
	-- to the one under it, so that no card comes twice)
	local order = { bestI }
	for i = 1, CuratorOctoFull.Length(rar) do
		if i ~= bestI then
			order[CuratorOctoFull.Length(order) + 1] = i
		end
	end
	for _, i in ipairs(order) do
		picks[i] = { card = PickFree(s, rar[i], used) }
	end
	Gamble(s, picks, used, m)
	picks.bet = bet
	picks.extra = (bet and bet.delta > 0) or nil
	picks.grandTried = m and m.grandTried or nil
	local best = picks[bestI]
	if m then
		best = Best(picks, best)
	else
		best.best = true
	end
	Finish(self, s, picks, opts, m, best)
	for i = CuratorOctoFull.Length(picks), 2, -1 do
		local j = math.random(i)
		picks[i], picks[j] = picks[j], picks[i]
	end
	if opts.test then
		for _, p in ipairs(picks) do
			local e = self:Entry(p.card)
			p.new, p.count = not (e and e.n > 0), e and e.n or 0
			p.pt = p.finish == "holo" and ns.Copies and ns.Copies.DrawPattern() or nil
			p.wear = ns.Wear and ns.Wear.Test(nil, ns.Wear.Hash(tostring(p.card and p.card.key) .. ":" .. tostring(debugprofilestop and debugprofilestop() or 0))) or nil
		end
		return picks
	end
	if opts.hold then
		picks.hold = { s = s, best = best }
		Held(picks, s, best)
		return picks
	end
	Keep(self, s, picks, best)
	return picks
end

-------------------------------------------------------------------------------
-- (1.10.0) A golden booster (Golden.lua): 5 cards, every one epic or better, the first legendary (now and
-- then mythic). The talents of the Augur change it as any booster: the odds of the rarities, a card more now
-- and then, the card of the Favor of the Stars, the Ritual, the finishes (those of the sealed boosters).
-------------------------------------------------------------------------------
-- The rarity of a card of a golden booster (odds: the rarer first, the last one gets the rest).
local function GoldRarity(odds, mult)
	local r = math.random()
	for i, o in ipairs(odds) do
		if i == CuratorOctoFull.Length(odds) then
			return o[1]
		end
		local p = mult and o[2] * (mult[o[1]] or 1) or o[2]
		if r < p then
			return o[1]
		end
		r = r - p
	end
	return odds[CuratorOctoFull.Length(odds)][1]
end

-- A card of a golden booster: one not in it yet, of the rarity drawn, else under it (epic at least); in a
-- small album where all of them are in it already, one of that rarity again (else under it). An album with
-- no card from epic to that rarity: one above it.
local function PickGold(s, rarity, used, m)
	local function Free(r)
		for _, card in ipairs(s.byRarity[r] or {}) do
			if not used[card.key] then
				return true
			end
		end
		return false
	end
	for r = rarity, 4, -1 do
		if Free(r) then
			return PickWeighted(s, r, used, m)
		end
	end
	for r = rarity, 4, -1 do
		local list = s.byRarity[r] or {}
		if CuratorOctoFull.Length(list) > 0 then
			return list[math.random(CuratorOctoFull.Length(list))]
		end
	end
	for r = rarity + 1, CuratorOctoFull.Length(ns.RARITY) do
		if Free(r) then
			return PickWeighted(s, r, used, m)
		end
		local list = s.byRarity[r] or {}
		if CuratorOctoFull.Length(list) > 0 then
			return list[math.random(CuratorOctoFull.Length(list))]
		end
	end
	return PickFree(s, rarity, used)
end

-- (Ritual, in a golden booster) One of the cards a rarity higher: one of that rarity not in the booster yet,
-- else one of that rarity again (never a card under epic, as the Ritual of the other boosters could give).
local function GoldRitual(s, picks, used, m)
	local cand = {}
	for i, p in ipairs(picks) do
		local up = p.card.rarity + 1
		if up <= CuratorOctoFull.Length(ns.RARITY) and CuratorOctoFull.Length((s.byRarity[up] or {})) > 0 then
			cand[CuratorOctoFull.Length(cand) + 1] = i
		end
	end
	if CuratorOctoFull.Length(cand) == 0 then
		return
	end
	local p = picks[cand[math.random(CuratorOctoFull.Length(cand))]]
	local up = p.card.rarity + 1
	local list = s.byRarity[up]
	local free = false
	for _, card in ipairs(list) do
		if not used[card.key] then
			free = true
			break
		end
	end
	p.card = free and PickWeighted(s, up, used, m) or list[math.random(CuratorOctoFull.Length(list))]
	p.raised = true
	picks.ritual = true
end

-- opts.golden: { t = its ticket }; opts.test, opts.hold as for C:Open.
function C:OpenGolden(s, opts)
	local G = ns.Golden
	local m = (not opts.test) and ns.Talents and ns.Talents:BoosterMods(s) or nil
	local mult = m and m.rar or nil
	local rar = { GoldRarity(G.FIRST_ODDS, mult) }
	local n = G.SIZE
	if m and (m.extra or 0) > 0 and math.random() < m.extra then
		n = n + 1
	end
	for i = 2, n do
		rar[i] = GoldRarity(G.OTHER_ODDS, mult)
	end
	local star
	if m and m.star and ns.Talents.STAR_ODDS then
		n = n + 1
		rar[n] = math.max(m.starMin or 4, StarRarity())
		star = n
	end
	-- (the rarest first: each keeps its rarity while a card of it is left)
	local order = {}
	for i = 1, n do
		order[i] = i
	end
	table.sort(order, function(a, b)
		if rar[a] ~= rar[b] then
			return rar[a] > rar[b]
		end
		return a < b
	end)
	local used, picks = {}, {}
	for _, i in ipairs(order) do
		picks[i] = { card = PickGold(s, rar[i], used, m) }
	end
	if m then
		if m.ritual and math.random() < m.ritual then
			GoldRitual(s, picks, used, m)
		end
		picks.star = star and picks[star] or nil
		picks.extra = n > G.SIZE + (star and 1 or 0) or nil
		if picks.star then
			picks.star.star = true
			-- (1.11.0: the Eye of Fate's)
			if m.fate then
				picks.star.fate, picks.fate = true, true
			end
		end
	end
	local best = Best(picks, picks[1])
	for _, p in ipairs(picks) do
		p.finish = self:RollFinish(true, m, p.card.rarity)
	end
	if m and (m.double or 0) > 0 then
		Double(picks, m)
	end
	for _, p in ipairs(picks) do
		p.shiny, p.holo = p.finish == "shiny", p.finish == "holo"
	end
	for i = CuratorOctoFull.Length(picks), 2, -1 do
		local j = math.random(i)
		picks[i], picks[j] = picks[j], picks[i]
	end
	picks.golden = true
	picks.ticket = opts.golden and tostring(opts.golden.t) or nil
	if opts.test then
		for _, p in ipairs(picks) do
			local e = self:Entry(p.card)
			p.new, p.count = not (e and e.n > 0), e and e.n or 0
			p.pt = p.finish == "holo" and ns.Copies and ns.Copies.DrawPattern() or nil
			p.wear = ns.Wear and ns.Wear.Test(nil, ns.Wear.Hash(tostring(p.card and p.card.key) .. ":" .. tostring(debugprofilestop and debugprofilestop() or 0))) or nil
		end
		return picks
	end
	if opts.hold then
		picks.hold = { s = s, best = best, gold = opts.golden }
		Held(picks, s, best, opts.golden)
		return picks
	end
	Keep(self, s, picks, best, opts.golden)
	return picks
end

-- (1.6.0, Redraw) A card of the booster just opened drawn again: its copy goes, another card comes in its
-- place (a card of that booster: the others of the booster left out), with its own finish. Its
-- experience: what it gives more than the card it replaces. The new pick.
function C:Redraw(s, picks, i)
	local shown = picks and picks[i]
	-- (1.14.0: the card as it was kept, see KEPT)
	local p = shown and KEPT[shown]
	if not p or not ns.db then
		return nil
	end
	local db = ns.db
	-- (1.14.0: its album and the card drawn again as they must be: Guard.lua)
	if ns.Guard and not ns.Guard:Allow(s, p.card) then
		return nil
	end
	local e = db.cards[p.card.key]
	-- (its copy, in its finish, must still be there: traded or put in a contract meanwhile, nothing is drawn)
	if ns.Contract.Copies(e, p.finish) <= 0 then
		return nil
	end
	local m = ns.Talents and ns.Talents:BoosterMods(s) or nil
	local used = {}
	for _, q in ipairs(picks) do
		used[q.card.key] = true
	end
	local card
	if picks.golden then
		card = PickGold(s, GoldRarity(ns.Golden.OTHER_ODDS, m and m.rar), used, m)
	elseif s.dungeon then
		card = PickWeighted(s, DungeonRarity(m and m.rar), used, m)
	elseif s.event then
		card = pick(s, EventRarity(m and m.rar), used, m)
	else
		card = pick(s, RollRarity(m and m.rar), used, m)
	end
	local finish, corruption
	if s.event then
		finish, corruption = self:RollEventFinish()
	else
		finish = self:RollFinish(s.dungeon or picks.golden == true, m, card.rarity)
	end
	-- (1.13.0: its copy goes, the one that came with the booster)
	if ns.Copies then
		ns.Copies:Take(p.card.key, p.finish, 1, p.ci and { p.ci } or nil)
	end
	e.n = e.n - 1
	if p.finish == "shiny" then
		e.s = math.max(0, (e.s or 0) - 1)
	elseif p.finish == "holo" then
		e.h = math.max(0, (e.h or 0) - 1)
	elseif p.finish == "corrupt" then
		-- (1.12.0: that corrupted copy taken back, the others stay)
		local list = self:CorruptCopies(e)
		local want = Gauge(p.corrupt)
		for i, v in ipairs(list) do
			if v == want then
				CuratorOctoFull.Remove(list, i)
				break
			end
		end
		self:SyncCorrupt(p.card, e)
	end
	if e.n <= 0 and db.fresh then
		db.fresh[p.card.key] = nil
	end
	-- (1.7.0: the card drawn again takes the place of the old one in the journal)
	local how = picks.golden and "g" or "b"
	self:Unlog(p.card, p.finish, how, tonumber(db.opened) or 0)
	local new, e2 = self:Add(card, finish, corruption)
	local ci = ns.Copies and ns.Copies.last and ns.Copies.last.i or nil
	local pt = ns.Copies and ns.Copies.Pattern(ns.Copies.last) or nil
	self:Remember(card, finish, how, picks.golden and picks.ticket or nil)
	local np = { card = card, finish = finish, shiny = finish == "shiny", holo = finish == "holo", new = new, count = e2.n, redrawn = true,
		ci = ci, pt = pt }
	if finish == "corrupt" then
		np.corrupt = corruption
	end
	np.look = self:FinishLook(card, finish)
	if ns.Level then
		local xp = ns.Level:CardXP(card, finish)
		if ns.Talents then
			xp = ns.Talents:CardXP(xp, new, card, finish, s)
		end
		-- (its experience: what it is worth more than the card it replaces, the experience that falls from it)
		local more = xp - (p.xp or 0)
		if more > 0 then
			ns.Level:Gain(more, "booster")
			np.xp = more
		end
	end
	picks[i] = np
	KEPT[shown] = nil
	KEPT[np] = { card = np.card, finish = np.finish, corrupt = np.corrupt, ci = np.ci, xp = (p.xp or 0) + (np.xp or 0) }
	ns.Fire("CHANGED")
	return np
end

-- What the whole collection holds, for the profile shared with other players.
function C:Census()
	local p = { owned = 0, total = 0, rar = PerRarity(0), shiny = 0, holo = 0, corrupt = 0, corruptFull = 0 }
	for _, s in ipairs(ns.Series or {}) do
		-- (1.12.0: an album of an event counts in no total, its finishes do: Hallow.lua; 1.13.0: a limited edition of
		-- another game, the Hardcup Saison 3, counts in nothing)
		local ev = s.event ~= nil or s.limited ~= nil
		if not ev then
			p.total = p.total + (s.official or CuratorOctoFull.Length(s.list))
		end
		for _, card in ipairs(s.limited and {} or s.list) do
			local e = self:Entry(card)
			if e and e.n > 0 then
				if not ev then
					p.owned = p.owned + 1
					p.rar[card.rarity] = p.rar[card.rarity] + 1
				end
				if (e.s or 0) > 0 then
					p.shiny = p.shiny + 1
				end
				if (e.h or 0) > 0 then
					p.holo = p.holo + 1
				end
				if (e.c or 0) > 0 then
					p.corrupt = p.corrupt + 1
					if (tonumber(e.k) or 0) >= 100 then
						p.corruptFull = p.corruptFull + 1
					end
				end
			end
		end
	end
	return p
end

-- One card straight into the collection (a card found in the world). finish: "holo", "shiny" (or true)
-- or nil; how: what gave it, for the finest pulls ("f": found on a creature). Returns new, copies.
function C:Grant(card, finish, how, corruption)
	-- (1.14.0: the card and its album as they must be, else it does not come, nil: Guard.lua)
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return nil, 0
	end
	finish = finish == true and "shiny" or finish
	local new, e = self:Add(card, finish, corruption)
	self:Remember(card, finish, how or "f")
	ns.Fire("CHANGED")
	return new, e.n
end

-------------------------------------------------------------------------------
-- The finest pulls (the record of the profile) and the showcase
-------------------------------------------------------------------------------
local HISTORY_MAX = 30 -- finest pulls kept
local SHOWCASE_SIZE = 3
C.HISTORY_MAX, C.SHOWCASE_SIZE = HISTORY_MAX, SHOWCASE_SIZE
-- (1.14.0, Museum Showcase, a talent of the Archivist: two places more; the showcases of the others, as many at most)
C.SHOWCASE_MAX = 5
function C:ShowcaseSize()
	local TL = ns.Talents
	return SHOWCASE_SIZE + ((TL and TL.Has and TL:Has("museum")) and 2 or 0)
end

-- A pull worth keeping: a legendary or mythic card, a holographic (titanforged) one, a shiny
-- (thunderforged) epic one.
function C:Notable(card, finish)
	if not card then
		return false
	end
	return card.rarity >= 5 or finish == "holo" or ((finish == "shiny" or finish == true or finish == "corrupt") and card.rarity >= 4)
end

-- How fine a card is: its rarity, one more for a shiny (thunderforged) copy, two for a holographic
-- (titanforged) one.
function C:Score(card, finish)
	return card.rarity + ((finish == "holo" and 2) or ((finish == "shiny" or finish == true or finish == "corrupt") and 1) or 0)
end

-- The finest first; among equals the rarest card, then the most recent.
local function Finer(a, b)
	if a.score ~= b.score then
		return a.score > b.score
	end
	if a.card.rarity ~= b.card.rarity then
		return a.card.rarity > b.card.rarity
	end
	if (a.t or 0) ~= (b.t or 0) then
		return (a.t or 0) > (b.t or 0)
	end
	return a.card.key < b.card.key
end
C.Finer = Finer

-- Pulls as they are kept ({ k, f, t, s, w }), as cards: { card, finish, t, how, who, score }, the
-- finest first.
function C:Pulls(list)
	local out = {}
	for _, h in ipairs(list or {}) do
		local card = ns.Cards[h.k or ""]
		if card then
			local f = (h.f == "holo" or h.f == "shiny") and h.f or nil
			out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = f, t = h.t, how = h.s, who = h.w, score = self:Score(card, f),
				pt = f == "holo" and ns.Copies and ns.Copies.PatternNo(h.pt) or nil }
		end
	end
	table.sort(out, Finer)
	return out
end

-- My finest pulls.
function C:History()
	return self:Pulls(ns.db and ns.db.history)
end

-- A pull is kept when it is one of the finest (how: "b" a booster, "f" found on a creature, "k" a
-- contract, "t" a trade, who: with whom), the first time that card comes with that finish. Past
-- HISTORY_MAX, the least fine goes, the oldest of them first.
function C:Remember(card, finish, how, who)
	-- (1.14.0: no copy came, nothing to remember: Guard.lua)
	if ns.Guard and ns.Guard:Stopped() then
		return false
	end
	-- (1.7.0: every card worth it goes to the journal first, notable or not)
	self:Log(card, finish, how, who)
	if not (ns.db and self:Notable(card, finish)) then
		return false
	end
	if finish == true then
		finish = "shiny"
	end
	local h = ns.db.history or {}
	ns.db.history = h
	for _, e in ipairs(h) do
		if e.k == card.key and e.f == finish then
			return false
		end
	end
	-- (1.14.0: a titanforged card, the pattern of the copy that just came, Copies.lua)
	local CP, pt = ns.Copies, nil
	local last = CP and CP.last
	if finish == "holo" and last and CP:Get(card.key, last.i) == last then
		pt = CP.Pattern(last)
	end
	h[CuratorOctoFull.Length(h) + 1] = { k = card.key, f = finish, t = CuratorOctoFull.ServerTime(), s = how, w = who, pt = pt }
	while CuratorOctoFull.Length(h) > HISTORY_MAX do
		local worst, ws, wt
		for i, e in ipairs(h) do
			local c = ns.Cards[e.k or ""]
			local sc = c and self:Score(c, e.f) or -1
			if not worst or sc < ws or (sc == ws and (e.t or 0) < wt) then
				worst, ws, wt = i, sc, e.t or 0
			end
		end
		CuratorOctoFull.Remove(h, worst)
	end
	ns.Fire("HISTORY_CHANGED")
	return true
end

-- The record starts with what the album already holds (the collections made before it): its finest
-- cards, on the day each one was first found (how: "a", in the album).
function C:SeedHistory()
	local db = ns.db
	if not db or db.historySeeded then
		return
	end
	db.historySeeded = true
	if CuratorOctoFull.Length(db.history) > 0 then
		return
	end
	local list = {}
	for key, e in pairs(db.cards) do
		local card = ns.Cards[key]
		if card and e.n > 0 then
			local f = self:BestFinish(e)
			if self:Notable(card, f) then
				list[CuratorOctoFull.Length(list) + 1] = { card = card, finish = f, t = e.t or 0, score = self:Score(card, f) }
			end
		end
	end
	table.sort(list, Finer)
	for i = 1, math.min(HISTORY_MAX, CuratorOctoFull.Length(list)) do
		local p = list[i]
		db.history[i] = { k = p.card.key, f = p.finish, t = p.t, s = "a" }
	end
end

-------------------------------------------------------------------------------
-- (1.7.0) The journal of the collection: each card worth it that came, when and how, so that the
-- website of Curator can tell where a collection comes from. A card worth it: rare or better, or a
-- thunderforged or titanforged copy of any card. One line each:
--   "time,npc,finish,how,booster,who"
-- time: the server time it came; npc: its creature; finish: "" (normal), "s" (thunderforged), "h"
-- (titanforged); how: "b" a booster, "f" found on a creature, "k" a contract, "t" a trade, "e" a place
-- explored (a talent), "a" in the album before the journal (1.12.0: "x" given by the author to himself, his
-- build: UI/Admin.lua; the website reads it as another way; 1.13.0: "c" a card of a gift code, the cards of the
-- Hardcup Saison 3, who: the id of the code, Gifts.lua; 1.14.0: "p" a copy back from a trade that did not happen,
-- who: with whom it was, C:LogBack); booster: the number of the booster it came
-- from (the boosters opened count them); who: with whom it was traded. A card taken back (drawn again
-- in its place, a trade undone) takes its line back. Past JOURNAL_MAX lines the oldest goes, but a legendary
-- or mythic card stays. The journal is sealed with the rest of the save, and it draws nothing (the
-- tirages stay the same: no math.random here).
-------------------------------------------------------------------------------
local JOURNAL_MAX = 3000
C.JOURNAL_MAX = JOURNAL_MAX

-- A card the journal keeps.
function C:Journaled(card, finish)
	return card ~= nil and type(card.rarity) == "number" and (card.rarity >= 3 or finish == "shiny" or finish == "holo" or finish == "corrupt" or finish == true)
end

-- A line of the journal, as its fields: { t, npc, f ("holo", "shiny" or nil), how, booster, who }.
function C:JournalLine(line)
	if type(line) ~= "string" then
		return nil
	end
	local t, npc, f, how, booster, who = CuratorOctoFull.Match(line, "^(%d+),(%d+),(%a?),(%a?),(%d*),(.*)$")
	if not t then
		return nil
	end
	return {
		t = tonumber(t), npc = tonumber(npc), f = (f == "h" and "holo") or (f == "s" and "shiny") or (f == "c" and "corrupt") or nil,
		how = how ~= "" and how or nil, booster = tonumber(booster), who = who ~= "" and who or nil,
	}
end

local function JournalRarity(line)
	local npc = type(line) == "string" and CuratorOctoFull.Match(line, "^%d+,(%d+),")
	local card = npc and ns.Cards["c" .. npc]
	return card and card.rarity or 0
end

-- Writes a line; past JOURNAL_MAX, the oldest line under legendary goes (else the oldest of all).
local function Append(db, line)
	local j = db.journal
	if type(j) ~= "table" then
		j = {}
		db.journal = j
	end
	j[CuratorOctoFull.Length(j) + 1] = line
	while CuratorOctoFull.Length(j) > JOURNAL_MAX do
		local drop = 1
		for i = 1, CuratorOctoFull.Length(j) do
			if JournalRarity(j[i]) < 5 then
				drop = i
				break
			end
		end
		CuratorOctoFull.Remove(j, drop)
	end
end

-- With whom, as a line keeps it (no comma, no line break, no pipe).
local function CleanWho(who)
	return (string.gsub(tostring(who or ""), "[,\r\n|]", " "))
end

local function JournalText(t, npc, finish, how, booster, who)
	local f = (finish == "holo" and "h") or ((finish == "shiny" or finish == true) and "s") or (finish == "corrupt" and "c") or ""
	how = (type(how) == "string" and CuratorOctoFull.Match(how, "^%a$")) or ""
	return string.format(("%d,%d,%s,%s,%s,%s"), math.floor(tonumber(t) or 0), npc, f, how, booster and tostring(math.floor(booster)) or "", CleanWho(who))
end

-- A card that came (called with every card kept: Remember). True when the journal took it.
function C:Log(card, finish, how, who)
	-- (1.14.0: no copy came, no line: Guard.lua)
	if ns.Guard and (ns.Guard:Stopped() or not ns.Guard:CardOk(card)) then
		return false
	end
	-- (1.13.0: how its copy came, whatever the journal keeps: Copies.lua)
	if ns.Copies then
		ns.Copies:Stamp(card, finish, how, who)
	end
	local db = ns.db
	if not (db and card and card.npc and self:Journaled(card, finish)) then
		return false
	end
	-- (the booster it came from: the one being opened (Keep), else the last one opened (a card drawn
	-- again by a talent comes from the booster just opened))
	local booster
	if how == "b" or how == "g" then
		booster = self.boosterNo or (tonumber(db.opened) or 0)
	end
	Append(db, JournalText(CuratorOctoFull.ServerTime(), card.npc, finish, how, booster, who))
	return true
end

-- (1.14.0) Copies back in the collection, a trade that did not happen (Trade.lua): a line each (how "p", with whom it
-- was), the copies keeping how they came first (no stamp, Copies.lua). The website then knows where they come from:
-- a copy put aside by a trade before the release of OctoWoW, back after it (lib/watch.ts). True when the journal
-- took it.
function C:LogBack(card, finish, who)
	if ns.Guard and not ns.Guard:CardOk(card) then
		return false
	end
	local db = ns.db
	if not (db and card and card.npc and self:Journaled(card, finish)) then
		return false
	end
	Append(db, JournalText(CuratorOctoFull.ServerTime(), card.npc, finish, "p", nil, who))
	return true
end

-- A card that came is taken back (a card drawn again in its place, a trade undone): the latest line
-- of the journal that matches it goes (booster, who: when given, they must match too). True when one
-- went.
function C:Unlog(card, finish, how, booster, who)
	local db = ns.db
	local j = db and db.journal
	if type(j) ~= "table" or not (card and card.npc) then
		return false
	end
	local f = (finish == "holo" and "holo") or ((finish == "shiny" or finish == true) and "shiny") or (finish == "corrupt" and "corrupt") or nil
	local w = who ~= nil and CleanWho(who) or nil
	for i = CuratorOctoFull.Length(j), 1, -1 do
		local l = self:JournalLine(j[i])
		if l and l.npc == card.npc and l.f == f and l.how == how and (booster == nil or l.booster == booster)
			and (w == nil or (l.who or "") == w) then
			CuratorOctoFull.Remove(j, i)
			return true
		end
	end
	return false
end

-- (1.10.0) A golden quest turned in: its line in the journal (how "q": the NPC of its leader; who: its
-- ticket, tranche, album, week, what was done and the version of the golden data, Golden.lua). It draws nothing.
function C:LogQuest(npc, who)
	local db = ns.db
	if not (db and npc) then
		return false
	end
	Append(db, JournalText(CuratorOctoFull.ServerTime(), npc, nil, "q", nil, who))
	return true
end

-- The journal begins with the finest pulls kept before it (once: the collections made before 1.7.0),
-- the oldest first.
function C:SeedJournal()
	local db = ns.db
	if not db or db.journalSeeded then
		return
	end
	db.journalSeeded = true
	db.journal = type(db.journal) == "table" and db.journal or {}
	if CuratorOctoFull.Length(db.journal) > 0 then
		return
	end
	local list = {}
	for _, h in ipairs(db.history or {}) do
		local card = ns.Cards[h.k or ""]
		if card and card.npc then
			list[CuratorOctoFull.Length(list) + 1] = { t = tonumber(h.t) or 0, card = card, f = h.f, s = h.s, w = h.w }
		end
	end
	table.sort(list, function(a, b)
		if a.t ~= b.t then
			return a.t < b.t
		end
		return a.card.npc < b.card.npc
	end)
	for _, h in ipairs(list) do
		Append(db, JournalText(h.t, h.card.npc, h.f, h.s or "a", nil, h.w))
	end
end

-- (1.14.0, after its second test) A card of a case pinned to the showcase: its key ("k:<edition>:<card>", a weapon of
-- legend "k:<edition>:w<item>", as UI/CaseDetail.lua names them), its edition, its card or its weapon.
local function CaseKey(key)
	local case, what = CuratorOctoFull.Match(tostring(key or ""), "^k:([^:]+):(.+)$")
	if not case then
		return nil
	end
	local weapon = CuratorOctoFull.Match(what, "^w(%d+)$")
	return case, (not weapon) and what or nil, weapon and tonumber(weapon) or nil
end
C.CaseKey = CaseKey

-- Its finest copy won (a copy of its record, Cases.lua), else nil: appraised first (its grade), its condition, its
-- finish (CS.Score).
function C:CaseCopy(key)
	local CS = ns.Cases
	local case, entry, weapon = CaseKey(key)
	if not (CS and case) then
		return nil
	end
	local best, bs
	for _, w in ipairs(CS:Won(case)) do
		if (weapon and w.w == weapon) or (entry and not w.w and w.e == entry) then
			local s = CS.Score(w)
			if not best or s > bs or (s == bs and (w.i or 0) > (best.i or 0)) then
				best, bs = w, s
			end
		end
	end
	return best
end

-- The cards pinned to the showcase that are still in the collection (the others leave it): the cards of the albums,
-- and (1.14.0) those of the cases still won.
-- (1.14.0, after its second test: each once, three at most, as pinned; one gone, the others are told, Comm.lua)
function C:Pins()
	local pins = ns.db and ns.db.showcase or {}
	local keep, seen = {}, {}
	for i = 1, CuratorOctoFull.Length(pins) do
		local key = pins[i]
		local ok = false
		if type(key) == "string" and not seen[key] and CuratorOctoFull.Length(keep) < self:ShowcaseSize() then
			local card = ns.Cards[key]
			if card then
				ok = self:Owned(card)
			else
				ok = CaseKey(key) ~= nil and self:CaseCopy(key) ~= nil
			end
		end
		if ok then
			seen[key] = true
			keep[CuratorOctoFull.Length(keep) + 1] = key
		end
	end
	local n = 0
	for _ in pairs(pins) do
		n = n + 1
	end
	if n ~= CuratorOctoFull.Length(keep) then
		for k in pairs(pins) do
			pins[k] = nil
		end
		for i, key in ipairs(keep) do
			pins[i] = key
		end
		if ns.db and pins == ns.db.showcase and ns.Delay and not C.pinsTold then
			C.pinsTold = true
			ns.Delay(0, function()
				C.pinsTold = nil
				ns.Fire("SHOWCASE_CHANGED")
			end, C)
		end
	end
	return pins
end

-- (1.14.0) A card of a case in the showcase (desc: UI/CaseDetail.lua, its key): its place there, else nil.
function C:PinnedCase(desc)
	local key = desc and desc.key
	for i, k in ipairs(self:Pins()) do
		if k == key then
			return i
		end
	end
end

-- Pins a card of a case to the showcase (its finest copy shows there): false and "full" when three are already there.
function C:PinCase(desc)
	local key = desc and desc.key
	if not (ns.db and key and CaseKey(key) and self:CaseCopy(key)) then
		return false
	end
	if self:PinnedCase(desc) then
		return true
	end
	local pins = self:Pins()
	if CuratorOctoFull.Length(pins) >= self:ShowcaseSize() then
		return false, "full"
	end
	pins[CuratorOctoFull.Length(pins) + 1] = key
	ns.Fire("SHOWCASE_CHANGED")
	return true
end

function C:UnpinCase(desc)
	local i = self:PinnedCase(desc)
	if i then
		CuratorOctoFull.Remove(ns.db.showcase, i)
		ns.Fire("SHOWCASE_CHANGED")
	end
end

-- (a card of a case pinned, its copies changed: one appraised, a finer one won, the last gone in a contract; what the
-- showcase shows, and what the others see of it, follow, as for the cards of the boosters: Expertise.lua, Seal.lua)
ns.On("CASES_CHANGED", function()
	local pins = ns.db and ns.db.showcase
	if type(pins) ~= "table" then
		return
	end
	for _, key in pairs(pins) do
		if type(key) == "string" and string.sub(key, 1, 2) == "k:" then
			C:Pins()
			if not C.pinsTold then
				ns.Fire("SHOWCASE_CHANGED")
			end
			return
		end
	end
end)

function C:Pinned(card)
	for i, key in ipairs(self:Pins()) do
		if key == card.key then
			return i
		end
	end
end

-- Pins a card to the showcase: false and "full" when three are already there.
function C:Pin(card)
	if not (ns.db and self:Owned(card)) then
		return false
	end
	if self:Pinned(card) then
		return true
	end
	local pins = self:Pins()
	if CuratorOctoFull.Length(pins) >= self:ShowcaseSize() then
		return false, "full"
	end
	pins[CuratorOctoFull.Length(pins) + 1] = card.key
	ns.Fire("SHOWCASE_CHANGED")
	return true
end

function C:Unpin(card)
	local i = self:Pinned(card)
	if i then
		CuratorOctoFull.Remove(ns.db.showcase, i)
		ns.Fire("SHOWCASE_CHANGED")
	end
end

-- The showcase: the cards pinned (in their order), then the finest cards of the collection in the
-- places left. { { card, finish, pinned } }, each card with its finest finish. (1.14.0, after its second test) A card
-- of a case pinned: { case (its card, UI/CaseDetail.lua: CD.Desc), copy (its finest copy won), pinned }, no card.
function C:Showcase()
	local out, used = {}, {}
	if not ns.db then
		return out
	end
	local CD = ns.CaseDetail
	for _, key in ipairs(self:Pins()) do
		local card = ns.Cards[key]
		if card then
			out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = self:BestFinish(self:Entry(card)), pinned = true }
		else
			local w = self:CaseCopy(key)
			if w and CD then
				out[CuratorOctoFull.Length(out) + 1] = { case = CD.DescOf(w), copy = w, pinned = true }
			end
		end
		used[key] = true
	end
	local size = self:ShowcaseSize()
	if CuratorOctoFull.Length(out) < size then
		local best = {}
		for key, e in pairs(ns.db.cards) do
			local card = ns.Cards[key]
			if card and e.n > 0 and not used[key] then
				local f = self:BestFinish(e)
				best[CuratorOctoFull.Length(best) + 1] = { card = card, finish = f, t = e.t or 0, score = self:Score(card, f) }
			end
		end
		table.sort(best, Finer)
		for i = 1, math.min(CuratorOctoFull.Length(best), size - CuratorOctoFull.Length(out)) do
			out[CuratorOctoFull.Length(out) + 1] = { card = best[i].card, finish = best[i].finish }
		end
	end
	return out
end

ns.On("LOADED", function()
	C:SeedHistory()
	C:SeedJournal()
end)

-- What a player shows of a series: cards owned, legendaries, shiny cards, best card, mythics,
-- holographic cards.
function C:Summary(s, entryOf)
	entryOf = entryOf or function(card) return self:Entry(card) end
	local owned, leg, shiny, best, myth, holo = 0, 0, 0, nil, 0, 0
	for _, card in ipairs(s.list) do
		local e = entryOf(card)
		if e and e.n > 0 then
			-- (1.14.0: the contraband of the Hardcup Saison 3 out of the cards of its album)
			if not card.smuggle then
				owned = owned + 1
			end
			if card.rarity == 5 then
				leg = leg + 1
			elseif card.rarity == 6 then
				myth = myth + 1
			end
			if (e.s or 0) > 0 then
				shiny = shiny + 1
			end
			if (e.h or 0) > 0 then
				holo = holo + 1
			end
			if not best or card.rarity > best.rarity then
				best = card
			end
		end
	end
	return owned, s.official or CuratorOctoFull.Length(s.list), leg, shiny, best, myth, holo
end

-- A whole series in three short strings, to share it: one base 36 digit of copies per card (capped
-- at 35), then the shiny cards and the holographic cards, each as a hexadecimal bit field.
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local function Bits(s, has)
	local bits = {}
	for i, card in ipairs(s.list) do
		local b = math.floor((i - 1) / 4) + 1
		bits[b] = (bits[b] or 0) + ((has(card) and 1 or 0) * 2 ^ (CuratorOctoFull.Mod((i - 1) , 4)))
	end
	for b = 1, math.ceil(CuratorOctoFull.Length(s.list) / 4) do
		bits[b] = string.format(("%x"), bits[b] or 0)
	end
	return table.concat(bits)
end

local function Bit(str, i)
	local k = math.floor((i - 1) / 4) + 1
	local digit = tonumber(string.sub((str or ""), k, k), 16) or 0
	return CuratorOctoFull.Mod(math.floor(digit / 2 ^ (CuratorOctoFull.Mod((i - 1) , 4))) , 2) == 1
end

function C:Encode(s)
	local counts = {}
	for i, card in ipairs(s.list) do
		local e = self:Entry(card)
		local n = e and math.min(35, e.n) or 0
		counts[i] = string.sub(B36, n + 1, n + 1)
	end
	local shinies = Bits(s, function(card)
		local e = self:Entry(card)
		return e and e.n > 0 and (e.s or 0) > 0
	end)
	local holos = Bits(s, function(card)
		local e = self:Entry(card)
		return e and e.n > 0 and (e.h or 0) > 0
	end)
	return table.concat(counts), shinies, holos
end

-- Back to entries: [cardKey] = { n = copies, s = 1 when shiny, h = 1 when holographic }. Bad
-- strings give nil. An album sent before 0.8 has no holographic bits: none.
function C:Decode(s, counts, shinies, holos)
	-- (1.14.0: an album sent before the contraband of the Hardcup Saison 3 has no place for it: none)
	if type(counts) ~= "string" or CuratorOctoFull.Length(counts) > CuratorOctoFull.Length(s.list) or CuratorOctoFull.Length(counts) < (s.official or CuratorOctoFull.Length(s.list)) or type(shinies) ~= "string" then
		return nil
	end
	local out = {}
	for i, card in ipairs(s.list) do
		local n = (i <= CuratorOctoFull.Length(counts)) and string.find(B36, string.sub(counts, i, i), 1, true) or 1
		if not n then
			return nil
		end
		if n > 1 then
			out[card.key] = { n = n - 1, s = Bit(shinies, i) and 1 or 0, h = Bit(holos, i) and 1 or 0 }
		end
	end
	return out
end
