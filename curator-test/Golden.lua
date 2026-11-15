local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.10.0) The golden quests: one a week for the whole account, given by the leaders of the capitals
-- (Data/Golden.lua) from the level 10. The quest fits the tranche of levels of the character who takes it
-- (10 to 19, 20 to 29... 60), and only that character moves it on. Three objectives, all at once:
--   the purge: 215 creatures, or 150 creatures and 100 gatherings (mining, herbs, skins), in the zones of
--     the leader for the tranche;
--   the hunt: 3 rares (rare or rare elite) there;
--   the dungeons: 4 dungeons of the tranche done (their last boss; not a raid).
-- Turned in to its leader before the reset of the week (Wednesday, 5:00 in Paris, as the quests of the
-- week), it gives 12,000 XP, 250 points on the booster bar and a golden booster to choose among three
-- (three albums of the lands of the leader for the tranche, the same for everyone that week). Not turned in
-- by then, it is lost with all that was done. A golden booster is bound to the account: no trade.
--
-- What is kept (db.golden): q, the quest taken ({ leader, bracket, guid, char, week, at, kills, gathers,
-- rares, dungeons }); doneWeek, the week it was turned in; n, the golden quests turned in (each one a
-- number: its ticket); packs, the golden boosters waiting ({ s = album, t = ticket, at }). The journal
-- keeps each quest turned in (how "q": the NPC of the leader, its ticket, tranche, album, week, counts and the
-- version of the golden data)
-- and the cards of each golden booster (how "g", its ticket), for the website (Collection.lua, Export.lua).
-------------------------------------------------------------------------------
local GQ = {}
ns.Golden = GQ

GQ.LEVEL = 10
GQ.KILLS, GQ.KILLS_WITH_GATHERS, GQ.GATHERS = 215, 150, 100
GQ.RARES, GQ.DUNGEONS = 3, 4
GQ.XP, GQ.POINTS = 12000, 250
GQ.CHOICES = 3
GQ.SIZE = 5
GQ.WARN_LEFT = 3 * 86400 -- accepted with less than this left before the reset: a warning first
GQ.ALERT_LEFT = 86400    -- this much left before the reset, a quest not done: an alert (once)
GQ.LAST_HOUR = 3600      -- turned in with less than this left: the secret feat
-- The rarities of a golden booster: its first card (legendary, now and then mythic), then each other one.
GQ.FIRST_ODDS = { { 6, 0.05 }, { 5, 0.95 } }
GQ.OTHER_ODDS = { { 6, 0.01 }, { 5, 0.14 }, { 4, 0.85 } }
-- The version of the data the three golden boosters of a week are drawn from (the leaders and their lands,
-- Data/Golden.lua; the albums, their levels) and of what a quest asks (GQ.KILLS... GQ.DUNGEONS above): it goes
-- with each quest turned in, and the website draws them again and judges the quest with the data of that
-- version (lib/golden.ts). A version that changes any of them must change it too.
GQ.DATA = 1
-- (1.13.0) The golden quests paused: they are being reworked. No leader gives one, nothing moves one on and none is
-- lost: a quest under way waits as it was in the save (one done this week can still be turned in). The golden
-- boosters waiting still open.
GQ.PAUSED = true

function GQ:Paused()
	return self.PAUSED == true
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b = pcall(fn, unpack(arg, 1, arg.n))
	if not ok or Secret(a) then
		return nil
	end
	return a, (not Secret(b)) and b or nil
end

-------------------------------------------------------------------------------
-- The leaders and their lands
-------------------------------------------------------------------------------
local byKey, byNpc = {}, {}
local function Index()
	if next(byKey) then
		return
	end
	for i, l in ipairs(ns.GOLDEN_LEADERS or {}) do
		l.index = i
		byKey[l.key] = l
		byNpc[l.npc] = l
	end
end

function GQ:Leader(key)
	Index()
	return byKey[key or ""]
end

function GQ:LeaderByNpc(npc)
	Index()
	return npc and byNpc[npc] or nil
end

-- The leaders of a side ("Horde", "Alliance"), in their order.
function GQ:Leaders(side)
	local out = {}
	for _, l in ipairs(ns.GOLDEN_LEADERS or {}) do
		if not side or l.side == side then
			out[CuratorOctoFull.Length(out) + 1] = l
		end
	end
	return out
end

-- The name of a leader, in the language of the game (the name of his card).
function GQ:LeaderName(l)
	local card = l and ns.Cards and ns.Cards["c" .. l.npc]
	return (card and ns.Collection and ns.Collection:Name(card)) or (l and l.key) or "?"
end

function GQ:Faction()
	local f = Safe(UnitFactionGroup, "player")
	return (f == "Horde" or f == "Alliance") and f or nil
end

function GQ:PlayerLevel()
	local lv = Safe(UnitLevel, "player")
	return type(lv) == "number" and lv or 1
end

-- (1.14.0) The level the tranche of a quest taken now follows: from the release of OctoWoW, the highest character
-- of the account (a reroll kept in a low tranche gives no easier golden quest: Reroll.lua); before, this one.
function GQ:TakerLevel()
	local RR = ns.Reroll
	if RR and RR:Active() then
		return math.max(self:PlayerLevel(), RR:HighestLevel())
	end
	return self:PlayerLevel()
end

function GQ:MaxLevel()
	return (ns.Quests and ns.Quests:MaxLevel()) or 60
end

-- The tranche of a level: 10, 20, 30, 40, 50, or 60 at the highest level (nil under the level 10).
function GQ:Bracket(level)
	level = math.floor(tonumber(level) or 0)
	if level < self.LEVEL then
		return nil
	end
	if level >= self:MaxLevel() then
		return 60
	end
	return math.min(50, math.floor(level / 10) * 10)
end

-- The levels of a tranche.
function GQ:Range(bracket)
	if bracket >= 60 then
		return 60, 60
	end
	return bracket, bracket + 9
end

-- An album of the tranche: 3 of its levels at least in it; at the level 60, an album that goes up to 58.
function GQ:InBracket(s, bracket)
	if not (s and s.levels and bracket) then
		return false
	end
	local lo, hi = s.levels[1], s.levels[2]
	if bracket >= 60 then
		return hi >= 58
	end
	local blo, bhi = self:Range(bracket)
	return math.min(hi, bhi) - math.max(lo, blo) + 1 >= 3
end

-- The zones of a leader for a tranche (albums), in his order.
function GQ:Zones(l, bracket)
	local out = {}
	for _, key in ipairs((l and l.zones) or {}) do
		local s = ns.SeriesByKey(key)
		if s and not s.dungeon and self:InBracket(s, bracket) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end

-- The dungeons of a leader's lands for a tranche (no raid).
function GQ:Dungeons(l, bracket)
	local out = {}
	for _, key in ipairs((l and l.dungeons) or {}) do
		local s = ns.SeriesByKey(key)
		if s and s.dungeon and not s.raid and self:InBracket(s, bracket) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	return out
end

-- Every dungeon of a tranche, wherever it is (no raid), in the order of their keys.
function GQ:AllDungeons(bracket)
	local out = {}
	for _, s in ipairs(ns.Series or {}) do
		if s.dungeon and not s.raid and self:InBracket(s, bracket) then
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	table.sort(out, function(a, b)
		return a.key < b.key
	end)
	return out
end

-- Does an album count for the purge and the hunt of a quest (a zone of its leader for its tranche)?
function GQ:Counts(q, s)
	if not (q and s) or s.dungeon then
		return false
	end
	for _, z in ipairs(self:Zones(self:Leader(q.leader), q.bracket)) do
		if z == s then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- The three golden boosters to choose: three albums of the leader's lands for the tranche, two zones and a
-- dungeon when there are, drawn from the week, the leader and the tranche (the same for everyone; the
-- website draws them the same way, lib/golden.ts). Fewer than three in his lands: the dungeons of the
-- tranche, then its zones, make up the rest.
-------------------------------------------------------------------------------
local MOD = 2147483647

-- A number from a text (31 bits, never 0).
function GQ.Hash(str)
	local a = 5381
	for i = 1, CuratorOctoFull.Length(str) do
		a = CuratorOctoFull.Mod((a * 33 + CuratorOctoFull.Byte(str, i)) , MOD)
	end
	return a == 0 and 1 or a
end

-- The draw of a week: next() gives the numbers of the Park-Miller generator from the hash.
local function Draw(seed)
	local x = seed
	return function()
		x = CuratorOctoFull.Mod((x * 48271) , MOD)
		return x
	end
end

-- A list shuffled by the draw (Fisher-Yates from the end), a copy.
local function Shuffled(list, nextN)
	local t = {}
	for i, v in ipairs(list) do
		t[i] = v
	end
	for i = CuratorOctoFull.Length(t), 2, -1 do
		local j = CuratorOctoFull.Mod(nextN() , i) + 1
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function GQ:Choices(leaderKey, bracket, week)
	local l = self:Leader(leaderKey)
	if not (l and bracket and week) then
		return {}
	end
	local nextN = Draw(self.Hash(string.format(("golden:%d:%s:%d"), week, l.key, bracket)))
	local zones = Shuffled(self:Zones(l, bracket), nextN)
	local dungeons = Shuffled(self:Dungeons(l, bracket), nextN)
	local out, used = {}, {}
	local function Take(s)
		if s and not used[s.key] and CuratorOctoFull.Length(out) < self.CHOICES then
			used[s.key] = true
			out[CuratorOctoFull.Length(out) + 1] = s
		end
	end
	Take(zones[1])
	Take(zones[2])
	Take(dungeons[1])
	for i = 3, CuratorOctoFull.Length(zones) do
		Take(zones[i])
	end
	for i = 2, CuratorOctoFull.Length(dungeons) do
		Take(dungeons[i])
	end
	if CuratorOctoFull.Length(out) < self.CHOICES then
		for _, s in ipairs(Shuffled(self:AllDungeons(bracket), nextN)) do
			Take(s)
		end
	end
	if CuratorOctoFull.Length(out) < self.CHOICES then
		local all = {}
		for _, s in ipairs(ns.Series or {}) do
			-- (1.12.0: never the album of an event; 1.13.0: nor a limited edition)
			if not s.dungeon and not s.event and not s.limited and self:InBracket(s, bracket) then
				all[CuratorOctoFull.Length(all) + 1] = s
			end
		end
		table.sort(all, function(a, b)
			return a.key < b.key
		end)
		for _, s in ipairs(Shuffled(all, nextN)) do
			Take(s)
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- What is kept
-------------------------------------------------------------------------------
function GQ:Db()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.golden) ~= "table" then
		db.golden = {}
	end
	local g = db.golden
	if type(g.packs) ~= "table" then
		g.packs = {}
	end
	g.n = tonumber(g.n) or 0
	return g
end

-- The week of the quests (the end of the week, UTC: its key), and the seconds left in it.
function GQ:Week()
	return ns.Quests and ns.Quests:ResetKey("week") or nil
end

function GQ:Left()
	return ns.Quests and ns.Quests:ResetLeft("week") or 0
end

-- The quest taken, if it is still of this week (else it is lost, and said so).
function GQ:Quest()
	local g = self:Db()
	local q = g and g.q
	if type(q) ~= "table" then
		return nil
	end
	local week = self:Week()
	-- (paused: none is lost, it waits as it was)
	if week and (tonumber(q.week) or 0) < week and not self:Paused() then
		g.q = nil
		local l = self:Leader(q.leader)
		ns.Print(L["Your golden quest is lost: the week ended before you turned it in."])
		ns.Fire("GOLDEN_LOST", l)
		ns.Fire("GOLDEN_CHANGED")
		return nil
	end
	return q
end

-- A golden quest turned in this week (by any character of the account).
function GQ:DoneThisWeek()
	local g = self:Db()
	local week = self:Week()
	return g ~= nil and week ~= nil and tonumber(g.doneWeek) == week
end

-- The character of the quest is the one playing.
function GQ:Mine(q)
	local guid = Safe(UnitGUID, "player")
	return q ~= nil and guid ~= nil and q.guid == guid
end

-------------------------------------------------------------------------------
-- The objectives
-------------------------------------------------------------------------------
function GQ:PurgeDone(q)
	local k, g = tonumber(q.kills) or 0, tonumber(q.gathers) or 0
	return k >= self.KILLS or (k >= self.KILLS_WITH_GATHERS and g >= self.GATHERS)
end

function GQ:IsComplete(q)
	return q ~= nil and self:PurgeDone(q) and (tonumber(q.rares) or 0) >= self.RARES
		and (tonumber(q.dungeons) or 0) >= self.DUNGEONS
end

-- What a quest needs, each line { key, got, need, done } (the purge: its two ways).
function GQ:Objectives(q)
	local k, g = tonumber(q.kills) or 0, tonumber(q.gathers) or 0
	return {
		{ key = "kills", got = k, need = self.KILLS, done = self:PurgeDone(q) },
		{ key = "gathers", got = g, need = self.GATHERS, with = math.min(k, self.KILLS_WITH_GATHERS), withNeed = self.KILLS_WITH_GATHERS,
			done = self:PurgeDone(q) },
		{ key = "rares", got = tonumber(q.rares) or 0, need = self.RARES, done = (tonumber(q.rares) or 0) >= self.RARES },
		{ key = "dungeons", got = tonumber(q.dungeons) or 0, need = self.DUNGEONS, done = (tonumber(q.dungeons) or 0) >= self.DUNGEONS },
	}
end

-- What a leader has for the player now: "low" (under the level 10), "foe" (not of his side), "done" (a
-- golden quest turned in this week), "busy" (a quest of another leader, or of another character),
-- "ready" (his quest done: to turn in), "active" (his quest under way), "offer" (one to take); (1.13.0)
-- "paused" (the golden quests paused: only a quest done this week, his own, is still "ready").
function GQ:State(l)
	if not (l and ns.db) then
		return nil
	end
	if self:Faction() ~= l.side then
		return "foe"
	end
	local q = self:Quest()
	if self:Paused() then
		if q and q.leader == l.key and self:Mine(q) and self:IsComplete(q) and tonumber(q.week) == self:Week() then
			return "ready"
		end
		return "paused"
	end
	if q then
		if q.leader ~= l.key or not self:Mine(q) then
			return "busy"
		end
		return self:IsComplete(q) and "ready" or "active"
	end
	if self:DoneThisWeek() then
		return "done"
	end
	-- (1.14.0: no golden quest for a reroll, Reroll.lua)
	if ns.Reroll and ns.Reroll:IsReroll() then
		return "reroll"
	end
	if not self:Bracket(self:PlayerLevel()) then
		return "low"
	end
	return "offer"
end

-------------------------------------------------------------------------------
-- Taking, giving up, turning in
-------------------------------------------------------------------------------
function GQ:Accept(leaderKey)
	local l = self:Leader(leaderKey)
	local g = self:Db()
	if not (l and g) or (ns.Beta and ns.Beta:Over()) then
		return false
	end
	if self:State(l) ~= "offer" then
		return false
	end
	local week = self:Week()
	if not week then
		return false
	end
	local name, realm = Safe(UnitName, "player")
	realm = realm or Safe(GetRealmName)
	g.q = {
		leader = l.key, bracket = self:Bracket(self:TakerLevel()), guid = Safe(UnitGUID, "player"),
		char = (name or "?") .. ((realm and realm ~= "") and ("-" .. realm) or ""), week = week, at = CuratorOctoFull.ServerTime(),
		kills = 0, gathers = 0, rares = 0, dungeons = 0,
	}
	ns.Fire("GOLDEN_ACCEPTED", l)
	ns.Fire("GOLDEN_CHANGED")
	return true
end

function GQ:Abandon()
	local g = self:Db()
	if not (g and g.q) then
		return false
	end
	g.q = nil
	ns.Fire("GOLDEN_CHANGED")
	return true
end

-- Something done for the quest taken: field ("kills", "gathers", "rares", "dungeons") moves on by n, when
-- the character of the quest did it where it counts.
function GQ:Add(field, n)
	local q = self:Quest()
	if not (q and self:Mine(q)) or self:Paused() then
		return
	end
	local was = self:IsComplete(q)
	q[field] = (tonumber(q[field]) or 0) + (n or 1)
	ns.Fire("GOLDEN_CHANGED")
	if not was and self:IsComplete(q) then
		ns.Fire("GOLDEN_COMPLETE", self:Leader(q.leader))
	end
end

-- Turned in to its leader, its golden booster chosen (an album among the three of the week). True when
-- it was.
function GQ:TurnIn(albumKey)
	local q = self:Quest()
	local g = self:Db()
	if not (q and g and self:Mine(q) and self:IsComplete(q)) or (ns.Beta and ns.Beta:Over()) then
		return false
	end
	-- (its own week only: a clock of the realm that went back past the reset waits for it again)
	if tonumber(q.week) ~= self:Week() then
		return false
	end
	-- (1.14.0: the cards changed by another addon this session: the quest stays to turn in; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return false
	end
	local s
	for _, c in ipairs(self:Choices(q.leader, q.bracket, q.week)) do
		if c.key == albumKey then
			s = c
		end
	end
	if not s then
		return false
	end
	local l = self:Leader(q.leader)
	local left = self:Left()
	g.n = g.n + 1
	local ticket = g.n
	g.doneWeek = q.week
	g.q = nil
	CuratorOctoFull.Insert(g.packs, { s = s.key, t = ticket, at = CuratorOctoFull.ServerTime() })
	-- its line in the journal, for the website: ticket, tranche, album, week, what was done, the version of the
	-- data of the golden boosters
	if ns.Collection and ns.Collection.LogQuest then
		ns.Collection:LogQuest(l.npc, string.format(("%d:%d:%s:%d:%d:%d:%d:%d:%d"), ticket, q.bracket, s.key, q.week,
			tonumber(q.kills) or 0, tonumber(q.gathers) or 0, tonumber(q.rares) or 0, tonumber(q.dungeons) or 0, self.DATA))
	end
	-- the achievements
	local st = ns.Stats()
	st.golden = (tonumber(st.golden) or 0) + 1
	local side = l.side == "Horde" and "goldenH" or "goldenA"
	st[side] = (tonumber(st[side]) or 0) + 1
	st.goldenBy = type(st.goldenBy) == "table" and st.goldenBy or {}
	st.goldenBy[l.key] = true
	st.goldenAt = type(st.goldenAt) == "table" and st.goldenAt or {}
	st.goldenAt[tostring(q.bracket)] = true
	if left > 0 and left <= self.LAST_HOUR then
		st.goldenLast = true
	end
	-- the rewards: the experience, the points on the bar, (1.11.0) the rubies
	if ns.Rubies then
		ns.Rubies:Gain(ns.Rubies.GOLDEN, "golden")
	end
	if ns.Level then
		ns.Level:Gain(self.XP, "golden")
	end
	if ns.Rewards then
		ns.Rewards:AddAnywhere(self.POINTS, "golden")
	end
	if ns.Guild and ns.Guild.AnnounceGolden then
		ns.Guild:AnnounceGolden(l.key)
	end
	ns.Fire("GOLDEN_DONE", l, s, ticket)
	ns.Fire("GOLDEN_CHANGED")
	ns.Fire("CHANGED")
	return true, s, ticket
end

-------------------------------------------------------------------------------
-- The golden boosters waiting
-------------------------------------------------------------------------------
function GQ:Packs()
	local g = self:Db()
	return g and g.packs or {}
end

function GQ:PackCount(s)
	local n = 0
	for _, p in ipairs(self:Packs()) do
		if not s or p.s == s.key then
			n = n + 1
		end
	end
	return n
end

-- (1.14.0, his word) A golden booster given by something else than a golden quest (why: "album", an album complete,
-- Achievements.lua): its own ticket, after those of the quests (the website judges its cards as those of a golden booster
-- whose quest it does not know: epic or better, five at most, lib/golden.ts).
function GQ:AddPack(s, why)
	local g = self:Db()
	if not (g and s) then
		return nil
	end
	g.n = (tonumber(g.n) or 0) + 1
	local ticket = g.n
	CuratorOctoFull.Insert(g.packs, { s = s.key, t = ticket, at = CuratorOctoFull.ServerTime(), w = why })
	ns.Fire("GOLDEN_CHANGED")
	ns.Fire("CHANGED")
	return ticket
end

-- The golden booster of a ticket (nil: gone).
function GQ:Pack(ticket)
	for i, p in ipairs(self:Packs()) do
		if p.t == ticket then
			return p, i
		end
	end
end

-- A golden booster spent (its cards kept, Collection.lua).
function GQ:Spend(ticket)
	local _, i = self:Pack(ticket)
	if i then
		CuratorOctoFull.Remove(self:Packs(), i)
		ns.Fire("GOLDEN_CHANGED")
		return true
	end
	return false
end

-- Opens a golden booster (the first one waiting, or the one of a ticket). from (1.14.2): where it was opened ("boosters",
-- "inventory": back there after it, UI/Booster.lua B.BACK_LABEL); the next one opened from its window keeps it.
function GQ:OpenPack(ticket, from)
	if not ns.db or (ns.Beta and ns.Beta:Blocked()) then
		return false
	end
	-- (1.14.0, after its test: a reroll opens no booster, Reroll.lua)
	if ns.Reroll and ns.Reroll:NoOpening() then
		ns.Reroll:SayNoOpening()
		return false
	end
	local p = ticket and self:Pack(ticket) or self:Packs()[1]
	local s = p and ns.SeriesByKey(p.s)
	if not (s and ns.Booster) then
		return false
	end
	-- (1.14.2: "Open another" after a golden booster, B:Again: from where the one before came)
	local B = ns.Booster
	if from == nil and B.opts and B.opts.golden and B.frame and B.frame:IsShown() then
		from = B.opts.from
	end
	ns.Booster:Open(s, { golden = { t = p.t }, from = from })
	return true
end

-- (1.14.2) The golden boosters waiting, by album: { s = its album, n = how many, t = the ticket of its first }, in the
-- order they came (Everything in the inventory, UI/CaseInventory.lua; the page of the boosters, UI/Boosters.lua).
-- series: of that album only.
function GQ:PacksByAlbum(series)
	local out, at = {}, {}
	for _, p in ipairs(self:Packs()) do
		local s = ns.SeriesByKey(p.s)
		if s and (not series or s == series) then
			local x = at[s]
			if x then
				x.n = x.n + 1
			else
				x = { s = s, n = 1, t = p.t }
				at[s] = x
				out[CuratorOctoFull.Length(out) + 1] = x
			end
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- What counts: the creatures and the dungeons (Rewards.lua), the rares, the gatherings (Quests.lua)
-------------------------------------------------------------------------------
ns.On("ACTIVITY", function(kind, n, s)
	local q = GQ:Quest()
	if not q then
		return
	end
	if kind == "kill" and s and GQ:Counts(q, s) then
		GQ:Add("kills", n or 1)
	elseif kind == "dungeonDone" and s and s.dungeon and not s.raid and GQ:InBracket(s, q.bracket) then
		GQ:Add("dungeons", 1)
	end
end)

ns.On("RARE_KILLED", function(s)
	local q = GQ:Quest()
	if q and GQ:Counts(q, s) then
		GQ:Add("rares", 1)
	end
end)

ns.On("GATHERED", function(kind)
	if kind == "fish" then
		return
	end
	local q = GQ:Quest()
	if q and ns.Rewards and GQ:Counts(q, ns.Rewards:WorldSeries()) then
		GQ:Add("gathers", 1)
	end
end)

-- A golden booster opened: a mythic in it, the secret feat.
ns.On("BOOSTER_OPENED", function(_, picks)
	if not (type(picks) == "table" and picks.golden) then
		return
	end
	for _, p in ipairs(picks) do
		if p.card and p.card.rarity >= 6 then
			ns.Stats().goldenMyth = true
		end
	end
end)

-------------------------------------------------------------------------------
-- The reset of the week and its alert: checked at the login and every few minutes
-------------------------------------------------------------------------------
function GQ:Tick()
	if self:Paused() then
		return
	end
	local q = self:Quest()
	if not (q and self:Mine(q)) or self:IsComplete(q) or q.alerted then
		return
	end
	local left = self:Left()
	if left > 0 and left <= self.ALERT_LEFT then
		q.alerted = true
		local l = self:Leader(q.leader)
		ns.Print(string.format(L["Your golden quest ends in %s: turn it in to %s before the reset, or it is lost."], ns.Duration(left), self:LeaderName(l)))
		ns.Fire("GOLDEN_ALERT", l, left)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function()
	ns.Delay(6, function()
		GQ:Tick()
		-- (paused: a quest under way waits, said once at the login)
		local q = GQ:Paused() and ns.db and GQ:Quest()
		if q and GQ:Mine(q) and GQ:State(GQ:Leader(q.leader)) ~= "ready" then
			ns.Print(L["The golden quest is being reworked: it is not available for now. Yours waits as it was."])
		end
	end, GQ)
	if CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker then
		CuratorOctoFull.Timer.NewTicker(300, function()
			GQ:Tick()
		end)
	end
end)
