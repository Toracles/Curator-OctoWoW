local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.8.0) The life of the inns, beyond the loyalty card (Inns.lua). With the innkeepers:
-- * the rumors of the tavern: an innkeeper the collector is a regular of (Regular and above) tells a
--   rumor a day: a creature of the album of his inn that the collection is missing, seen around. All
--   day, its card is twice as easy to find on that creature (Rewards.lua: R:Find);
-- * the innkeeper's bet: once a day, a duplicate of the collection (a normal copy to spare, of the
--   rarity chosen) against one of three cards of his album, face down: two of that rarity, one of the
--   rarity above; (1.12.0) five, face down: one of the rarity above, two of that rarity, and two that win
--   nothing (the house keeps the stake); (1.14.0) harder: two copies of a card bet (common to epic), against
--   seven cards face down, one of the rarity above (epic at most: a bet never gives a legendary card), two of
--   that rarity, and four that win nothing;
-- * the home inn: the inn where the hearthstone of the character is bound (the game says so when it
--   is bound there): its innkeeper counts each stamp twice for the loyalty;
-- * the evening at the inn: on Friday evenings (the time of the realm), the stamp of the day is a
--   double stamp on the loyalty card;
-- * a toast: two collectors at the same innkeeper raise their glasses (an invitation and its answer,
--   messages of Curator: Comm.lua), a stamp more on the loyalty card of each, once a day.
-- (1.14.0, after its test, his word: the innkeeper redone) A rumor heard (of the day, a second one, one bought) is a
-- lead: its card three times as easy to find (a mythic card, twice) for T.LEAD_DAYS days (more with Stubborn Rumor),
-- T.LEAD_MAX of them at once, shown on the screen (UI/Counter.lua). Its card found on its creature, the innkeeper owes
-- the collector a round (T.ROUND: experience and rubies), paid at the next innkeeper he talks to (not on a reroll: it
-- waits for a character that earns everything). The rest and the dish of the day count with a lead, LG.CAP times at
-- most (Lodging.lua).
-- What is kept: with the inns (db.inns: the rumors of the day, those heard, the leads (leads = { [card] = { n (the
-- innkeeper), t (when), u (the moment it ends), w (how: "day", "second", "bought") } }), the round owed (round = { n,
-- k = the cards }), the bet of the day and its cards waiting to be picked, the toast of the day), the home of each
-- character (Rewards.lua: R:Char().home) and the counts of the achievements (ns.Stats: bets, the jackpot, toasts,
-- evenings, the leads followed to their card).
-------------------------------------------------------------------------------
local T = { invites = {}, sent = {} }
ns.Tavern = T
local I = ns.Inns

T.RUMOR_RANK = 2 -- the rank of loyalty an innkeeper tells his rumors from (Regular)
-- the rarer creatures are talked about more (the mythic ones less: legends)
T.RUMOR_WEIGHT = { 1, 2, 3, 4, 5, 2 }
T.RUMOR_FIND = 3 -- the chance to find the card of a lead: three times (1.14.0; twice before)
T.RUMOR_FIND_MYTHIC = 2 -- a mythic card: twice, as before
T.LEAD_DAYS = 3 -- a lead holds the day it is heard and two more (1.14.0)
T.LEAD_MAX = 6 -- the leads at once (a new one past them: the oldest one goes)
T.ROUND = { xp = 150, rubies = 100 } -- the round of the innkeeper, for each lead followed to its card
-- the rarities a bet takes, and the best one it gives (1.14.0: up to epic; a legendary or a mythic card is never bet,
-- and a bet never gives a legendary card: 5 before, a legendary card)
T.BET_TOP = 4
-- the cards of a bet: one of the rarity above, two of its rarity, and those that win nothing (1.12.0: five cards, two of
-- them win nothing; 1.14.0: seven, four of them win nothing)
T.BET_CARDS = 7
T.BET_TRAPS = 4
T.TRAP = "x"
-- (1.14.0) the copies of a card a bet takes (one before)
T.BET_STAKE = 2
T.TOAST_WAIT = 180 -- the seconds an invitation to a toast waits for its answer
T.PARTY_DAY, T.PARTY_HOUR = 6, 18 -- the evening at the inn: Friday (in the calendar, 1 is Sunday), from 6 PM
T.HOME_BONUS = 2 -- the stamps of loyalty a stamp gives at the home inn
T.HOME_WAIT = 120 -- seconds between the window of an innkeeper and the hearthstone bound
T.XP = { rumor = 15, bet = 30 }
-- (1.11.0) a rumor bought: the creature chosen among those of his album the collection is missing, for rubies;
-- one a day at each innkeeper (Rubies.lua)
T.RUMOR_PRICE = 800 -- (1.13.0: twice as dear, 50 before; after its second test, the economy redone: 100 before)

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function Clock()
	return GetTime and GetTime() or 0
end

-- Nothing to earn: a beta past its day, a collection suspended, an update missed.
local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-- What the tavern keeps with the inns: the rumors of the day ({ d = day, n = { [npc] = card key } }), the
-- rumors heard in all, the day of the bet and its deal, the day of the toast.
function T:State()
	local s = I:State()
	if not s then
		return nil
	end
	if type(s.rumors) ~= "table" then
		s.rumors = {}
	end
	s.heard = tonumber(s.heard) or 0
	if type(s.leads) ~= "table" then
		s.leads = {}
	end
	return s
end

-------------------------------------------------------------------------------
-- The rumors of the tavern
-------------------------------------------------------------------------------
-- The rumors heard today: [npc] = card key (a new day: none yet).
function T:Rumors()
	local s = self:State()
	if not s then
		return {}
	end
	local today = I:Today()
	if s.rumors.d ~= today or type(s.rumors.n) ~= "table" then
		-- (1.14.0: what a rumor does lasts with its lead, T:Leads; the rumors of the day only say what was told today)
		s.rumors = { d = today, n = {} }
	end
	return s.rumors.n
end

-- (1.14.0, Word of Mouth, a talent of the Cartographer) The second rumors heard today: [npc] = card key.
function T:Rumors2()
	self:Rumors()
	local s = self:State()
	if not s then
		return {}
	end
	if type(s.rumors.m) ~= "table" then
		s.rumors.m = {}
	end
	return s.rumors.m
end

-- The numbers of a day for an innkeeper, the same each time (no math.random: the rumor of the day stays
-- the same, whenever it is asked for).
local function Seeded(day, npc)
	local x = CuratorOctoFull.Mod(((tonumber(day) or 0) * 7919 + (tonumber(npc) or 0) * 104729) , 2147483647)
	if x <= 0 then
		x = 1
	end
	return function()
		x = CuratorOctoFull.Mod((x * 48271) , 2147483647)
		return x / 2147483647
	end
end

-- The card a rumor of this innkeeper tells of (day: today): a creature of the album of his inn that the
-- collection is missing (not a friendly one: those are not defeated), the rarer ones talked about more;
-- with none missing, any creature of that album. Nil: none.
function T:RumorCard(npc, day)
	local album = I:Album(npc)
	if not album then
		return nil
	end
	local C = ns.Collection
	local missing, all = {}, {}
	for _, card in ipairs(album.list or {}) do
		if not card.friendly then
			all[CuratorOctoFull.Length(all) + 1] = card
			if not C:Owned(card) then
				missing[CuratorOctoFull.Length(missing) + 1] = card
			end
		end
	end
	local pool = CuratorOctoFull.Length(missing) > 0 and missing or all
	if CuratorOctoFull.Length(pool) == 0 then
		return nil
	end
	local total = 0
	for _, card in ipairs(pool) do
		total = total + (self.RUMOR_WEIGHT[card.rarity] or 1)
	end
	local x = Seeded(day or I:Today(), npc)() * total
	for _, card in ipairs(pool) do
		x = x - (self.RUMOR_WEIGHT[card.rarity] or 1)
		if x < 0 then
			return card
		end
	end
	return pool[CuratorOctoFull.Length(pool)]
end

-- The rumor of an innkeeper: its card, and true when it was heard today already (nil and why: "rank",
-- the collector is not a regular there yet; "none", nothing to tell).
function T:Rumor(npc)
	local _, r = I:Loyalty(npc)
	if r < self.RUMOR_RANK then
		return nil, "rank"
	end
	local key = self:Rumors()[npc]
	local card = key and ns.Cards and ns.Cards[key]
	if card then
		return card, true
	end
	card = self:RumorCard(npc)
	if not card then
		return nil, "none"
	end
	return card, false
end

-- The rumor of an innkeeper heard: its card, and true when it is heard now for the first time today
-- (nil and why: "closed", "rank", "none").
function T:Hear(npc)
	if Closed() then
		return nil, "closed"
	end
	local card, heard = self:Rumor(npc)
	if not card then
		return nil, heard
	end
	if heard then
		return card, false
	end
	local s = self:State()
	self:Rumors()[npc] = card.key
	s.heard = s.heard + 1
	if ns.Level then
		ns.Level:Gain(self.XP.rumor, "inn")
	end
	-- (1.14.0: a lead, for days)
	self:AddLead(card, npc, "day")
	ns.Fire("TAVERN_RUMOR", card, npc)
	-- (1.14.0, Word of Mouth: a second rumor, another card of the album)
	local TL = ns.Talents
	if TL and TL:Has("wordofmouth") then
		local second = self:SecondCard(npc, card)
		if second then
			self:Rumors2()[npc] = second.key
			self:AddLead(second, npc, "second")
			ns.Fire("TAVERN_RUMOR", second, npc, true)
		end
	end
	ns.Fire("CHANGED")
	return card, true
end

-- (1.14.0) The second rumor of an innkeeper: another card of the album of his inn that the collection misses, drawn
-- the same way all day.
function T:SecondCard(npc, first)
	local album = I:Album(npc)
	if not album then
		return nil
	end
	local pool = {}
	for _, card in ipairs(album.list or {}) do
		if not card.friendly and card ~= first and not ns.Collection:Owned(card) then
			pool[CuratorOctoFull.Length(pool) + 1] = card
		end
	end
	if CuratorOctoFull.Length(pool) == 0 then
		return nil
	end
	local x = Seeded((I:Today() or 0) + 0.5, npc)()
	return pool[math.floor(x * CuratorOctoFull.Length(pool)) + 1] or pool[CuratorOctoFull.Length(pool)]
end

-- The innkeeper who told of a card (nil: no lead of it now; true: a lead of an innkeeper Curator does not know).
-- (1.14.0: the leads, those of the day, the second ones of Word of Mouth and those bought.)
function T:Rumored(card)
	if not (card and ns.db) then
		return nil
	end
	local l = self:Lead(card)
	if l then
		return tonumber(l.n) or true
	end
	return nil
end

-------------------------------------------------------------------------------
-- (1.14.0) The leads: a rumor heard holds for days, its card three times as easy to find, until it is found on its
-- creature. Found, the innkeeper owes a round.
-------------------------------------------------------------------------------
local DAY = 86400

-- The days a lead holds: T.LEAD_DAYS, more with Stubborn Rumor (a talent of the Cartographer, a day a rank).
function T:LeadDays()
	local TL = ns.Talents
	local more = (TL and TL.Has and TL:Has("stubborn")) and TL:Rank("stubborn") or 0
	return self.LEAD_DAYS + more
end

-- The moment a lead heard now ends: the end of the day of the inns, and as many days more as it holds.
function T:LeadEnd()
	local left = I:NextIn()
	return Now() + left + (self:LeadDays() - 1) * DAY
end

-- (the rumors of 1.14.0 before the leads, those of today and those Stubborn Rumor kept: leads)
local function Migrate(T, s)
	if s.leadsFrom then
		return
	end
	s.leadsFrom = 1
	local r = type(s.rumors) == "table" and s.rumors or {}
	local today = r.d == I:Today()
	local function Add(key, npc, why)
		local card = type(key) == "string" and ns.Cards and ns.Cards[key]
		if card and not s.leads[key] then
			s.leads[key] = { n = tonumber(npc), t = Now(), u = T:LeadEnd(), w = why }
		end
	end
	if today then
		for npc, key in pairs(type(r.n) == "table" and r.n or {}) do
			Add(key, npc, "day")
		end
		for npc, key in pairs(type(r.m) == "table" and r.m or {}) do
			Add(key, npc, "second")
		end
	end
	for key in pairs(type(r.o) == "table" and r.o or {}) do
		Add(key, nil, "day")
	end
	local b = type(s.bought) == "table" and s.bought or {}
	if b.d == I:Today() then
		for npc, key in pairs(type(b.n) == "table" and b.n or {}) do
			Add(key, npc, "bought")
		end
	end
	r.o, r.m = nil, (today and r.m) or nil
end

-- The leads now: [card key] = { n, t, u, w } (those past their end gone).
function T:Leads()
	local s = self:State()
	if not s then
		return {}
	end
	Migrate(self, s)
	local now = Now()
	for key, l in pairs(s.leads) do
		if type(l) ~= "table" or (tonumber(l.u) or 0) <= now or not (ns.Cards and ns.Cards[key]) then
			s.leads[key] = nil
		end
	end
	return s.leads
end

-- The lead of a card (nil: none).
function T:Lead(card)
	local key = type(card) == "table" and card.key or card
	if type(key) ~= "string" then
		return nil
	end
	return self:Leads()[key]
end

-- The leads, the newest first: { card, n, t, u, w }.
function T:LeadList()
	local out = {}
	for key, l in pairs(self:Leads()) do
		out[CuratorOctoFull.Length(out) + 1] = { card = ns.Cards[key], n = tonumber(l.n), t = tonumber(l.t) or 0, u = tonumber(l.u) or 0, w = l.w }
	end
	table.sort(out, function(a, b)
		if a.t ~= b.t then
			return a.t > b.t
		end
		return a.card.key < b.card.key
	end)
	return out
end

-- A lead of a card, told by an innkeeper (why: "day", "second", "bought"); a lead of it already: its end pushed back.
-- Past T.LEAD_MAX leads, the oldest one goes.
function T:AddLead(card, npc, why)
	local s = self:State()
	if not (s and card and card.key) or Closed() then
		return nil
	end
	local leads = self:Leads()
	local u = self:LeadEnd()
	local l = leads[card.key]
	if l then
		l.u = math.max(tonumber(l.u) or 0, u)
		l.n, l.w, l.t = tonumber(npc) or l.n, why or l.w, Now()
	else
		l = { n = tonumber(npc), t = Now(), u = u, w = why }
		leads[card.key] = l
		local n, oldest, at = 0, nil, CuratorOctoFull.Huge
		for key, x in pairs(leads) do
			n = n + 1
			if key ~= card.key and (tonumber(x.t) or 0) < at then
				oldest, at = key, tonumber(x.t) or 0
			end
		end
		if n > self.LEAD_MAX and oldest then
			leads[oldest] = nil
		end
	end
	ns.Fire("TAVERN_LEAD", card, npc, why)
	return l
end

-- The round owed: how many leads, their cards (keys).
function T:Round()
	local s = self:State()
	local r = s and s.round
	if type(r) ~= "table" or (tonumber(r.n) or 0) <= 0 then
		return 0, {}
	end
	return tonumber(r.n), type(r.k) == "table" and r.k or {}
end

-- A lead followed to its card (found on its creature): the lead done, a round owed.
function T:LeadDone(card)
	local s = self:State()
	if not (s and card) then
		return
	end
	local l = self:Leads()[card.key]
	if not l then
		return
	end
	s.leads[card.key] = nil
	if type(s.round) ~= "table" then
		s.round = { n = 0, k = {} }
	end
	s.round.n = (tonumber(s.round.n) or 0) + 1
	s.round.k = type(s.round.k) == "table" and s.round.k or {}
	CuratorOctoFull.Insert(s.round.k, card.key)
	while CuratorOctoFull.Length(s.round.k) > 8 do
		CuratorOctoFull.Remove(s.round.k, 1)
	end
	local st = ns.Stats()
	st.leads = (tonumber(st.leads) or 0) + 1
	ns.Fire("TAVERN_LEAD_DONE", card, tonumber(l.n))
	ns.Fire("CHANGED")
end

-- The round paid at this innkeeper: { n (the leads), xp, rubies, cards } (nil: none owed, or it waits: a reroll,
-- nothing can be earned).
function T:PayRound(npc)
	local s = self:State()
	local n, keys = self:Round()
	if not s or n <= 0 or Closed() then
		return nil
	end
	if ns.Lodging and ns.Lodging.Waiting and ns.Lodging.Waiting() then
		return nil
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil
	end
	s.round = nil
	local xp, rubies = n * self.ROUND.xp, n * self.ROUND.rubies
	if ns.Level then
		ns.Level:Gain(xp, "inn")
	end
	local got = ns.Rubies and ns.Rubies:Gain(rubies, "round") or 0
	local cards = {}
	for _, key in ipairs(keys) do
		if ns.Cards[key] then
			cards[CuratorOctoFull.Length(cards) + 1] = ns.Cards[key]
		end
	end
	local res = { n = n, xp = xp, rubies = got, cards = cards, npc = npc }
	ns.Fire("TAVERN_ROUND", res)
	ns.Fire("CHANGED")
	return res
end

-------------------------------------------------------------------------------
-- (1.11.0) The rumors bought: at an innkeeper, the creature chosen among those of the album of his inn that
-- the collection is missing (not a friendly one: those are not defeated); all day, its card is twice as easy
-- to find, as with a rumor of the day. One a day at each innkeeper, for rubies; no need to be a regular.
-------------------------------------------------------------------------------
-- The rumors bought today: [npc] = card key (a new day: none yet).
function T:Bought()
	local s = self:State()
	if not s then
		return {}
	end
	local today = I:Today()
	if type(s.bought) ~= "table" or s.bought.d ~= today or type(s.bought.n) ~= "table" then
		s.bought = { d = today, n = {} }
	end
	return s.bought.n
end

-- The card of the rumor bought at this innkeeper today (nil: none).
function T:BoughtCard(npc)
	local key = self:Bought()[npc]
	return key and ns.Cards and ns.Cards[key] or nil
end

-- The cards a rumor can be bought of at this innkeeper: those of the album of his inn the collection is
-- missing (not the friendly ones), the rarest first.
function T:Wanted(npc)
	local album = I:Album(npc)
	local out = {}
	if not album then
		return out
	end
	local C = ns.Collection
	for _, card in ipairs(album.list or {}) do
		if not card.friendly and not C:Owned(card) then
			out[CuratorOctoFull.Length(out) + 1] = card
		end
	end
	table.sort(out, function(a, b)
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		end
		return (a.num or 0) < (b.num or 0)
	end)
	return out
end

-- Whether a rumor can be bought at this innkeeper now (card: of this card): true, or false and why
-- ("closed", "unknown", "done": one bought here today, "card": not a card missing from his album, "none":
-- no card is missing there, "rubies").
function T:CanBuy(npc, card)
	if Closed() then
		return false, "closed"
	end
	if type(npc) ~= "number" or not I:Album(npc) then
		return false, "unknown"
	end
	if self:BoughtCard(npc) then
		return false, "done"
	end
	if card then
		if card.series ~= I:Album(npc) or card.friendly or ns.Collection:Owned(card) then
			return false, "card"
		end
	elseif CuratorOctoFull.Length(self:Wanted(npc)) == 0 then
		return false, "none"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:RumorPrice())) then
		return false, "rubies"
	end
	return true
end

-- A rumor bought: the card chosen is twice as easy to find all day. The card (nil and why, as CanBuy says).
function T:Buy(npc, card)
	local ok, why = self:CanBuy(npc, card)
	if not ok then
		return nil, why
	end
	if not card then
		return nil, "card"
	end
	local price = self:RumorPrice()
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "rumor")
		if not paid then
			return nil, err
		end
	elseif ns.Talents and ns.Talents.UseFreeRumor then
		ns.Talents:UseFreeRumor()
	end
	self:Bought()[npc] = card.key
	-- (1.14.0: a lead, for days)
	self:AddLead(card, npc, "bought")
	local st = ns.Stats()
	st.rumorsBought = (tonumber(st.rumorsBought) or 0) + 1
	ns.Fire("TAVERN_RUMOR_BOUGHT", card, npc)
	ns.Fire("CHANGED")
	return card
end

-- (Rewards.lua) The chance to find a card on its creature: three times for the card of a lead (1.14.0; a mythic card,
-- twice; twice before 1.14.0), then the rest and the dish of the day (Lodging.lua), LG.CAP times at most together.
-- ctx: what was defeated (an elite, a rare; Rewards.lua: R:FindContext), boss: the card of a boss on its boss.
function T:FindChance(chance, card, ctx, boss)
	if type(chance) ~= "number" or not card then
		return chance
	end
	local k = 1
	local lead = self:Rumored(card) ~= nil
	if lead then
		k = (card.rarity or 0) >= 6 and self.RUMOR_FIND_MYTHIC or self:RumorFind()
	end
	local LG = ns.Lodging
	if LG then
		k = LG:FindMult(card, ctx, boss, k, lead)
	end
	return math.min(1, chance * k)
end

function T:RumorFind()
	local TL = ns.Talents
	return (TL and TL.RumorFind) and TL:RumorFind(self.RUMOR_FIND) or self.RUMOR_FIND
end

-- (1.11.0) The price of a rumor bought: less with the talents (Informant), free once a day (Scout's Gossip).
function T:RumorPrice()
	local TL = ns.Talents
	if TL and TL.FreeRumor and TL:FreeRumor() then
		return 0
	end
	return ns.Rubies and ns.Rubies:Price(self.RUMOR_PRICE, "rumor") or self.RUMOR_PRICE
end

-------------------------------------------------------------------------------
-- The innkeeper's bet
-------------------------------------------------------------------------------
-- The duplicates a bet can take, of a rarity: { card, spare } (the normal copies to spare: one copy of
-- each card always stays), the cards with the most of them first. (1.14.0) Only the cards with enough copies to spare
-- for a bet (n: T.BET_STAKE when nothing is said; a bet made before 1.14.0 took one).
function T:Stakes(rarity, n)
	local K = ns.Contract
	if not (K and type(rarity) == "number") then
		return {}
	end
	n = tonumber(n) or self.BET_STAKE
	local list = {}
	for _, it in ipairs(K:Eligible(rarity, "normal", true)) do
		if it.spare >= n then
			list[CuratorOctoFull.Length(list) + 1] = it
		end
	end
	table.sort(list, function(a, b)
		if a.spare ~= b.spare then
			return a.spare > b.spare
		end
		return a.card.key < b.card.key
	end)
	return list
end

-- The rarity above, for the third card of a bet (epic at most since 1.14.0: legendary before).
function T:Up(rarity)
	return math.min((rarity or 1) + 1, self.BET_TOP)
end

-- The album of an innkeeper has cards of a rarity (a bet of it can be made there).
function T:CanBet(npc, rarity)
	local album = I:Album(npc)
	return album ~= nil and album.byRarity ~= nil and CuratorOctoFull.Length((album.byRarity[rarity] or {})) > 0
end

-- The cards of a bet, from the album of the innkeeper: one of the rarity above (that rarity again when the
-- album has none above, or for an epic card: 1.14.0), two of its rarity (never the card bet, when the album has
-- others), and those that win nothing (T.TRAP: two in 1.12.0, four since 1.14.0). Their keys (nil: the album has none
-- of the rarity).
function T:Draw(npc, rarity, stake)
	local album = I:Album(npc)
	if not (album and album.byRarity) then
		return nil
	end
	local function Pick(r, ...)
		local avoid = { stake, unpack(arg, 1, arg.n) }
		local pool = {}
		for _, card in ipairs(album.byRarity[r] or {}) do
			local ok = true
			for _, x in pairs(avoid) do
				if card == x then
					ok = false
				end
			end
			if ok then
				pool[CuratorOctoFull.Length(pool) + 1] = card
			end
		end
		if CuratorOctoFull.Length(pool) == 0 then
			return nil
		end
		return pool[math.random(CuratorOctoFull.Length(pool))]
	end
	local a = Pick(rarity) or (stake and stake.rarity == rarity and stake) or nil
	if not a then
		return nil
	end
	local b = Pick(rarity, a) or a
	local up = self:Up(rarity)
	local c = (up ~= rarity and Pick(up)) or Pick(rarity, a, b) or b
	local out = { c.key, a.key, b.key }
	-- (1.14.0, the Gambler: High Table, the card of the rarity above twice, in the place of one of its rarity; Small
	-- Stake, a card more that wins nothing)
	local TL = ns.Talents
	local traps = self.BET_TRAPS
	if TL and TL:Has("hightable") then
		local c2 = (up ~= rarity and Pick(up, c)) or c
		out = { c.key, c2.key, a.key }
	elseif TL and TL:Has("lowstake") then
		traps = traps + 1
	end
	for _ = 1, traps do
		out[CuratorOctoFull.Length(out) + 1] = self.TRAP
	end
	return out
end

-- (1.14.0) The copies of a card a bet takes: two (High Table: three; Small Stake: one).
function T:StakeCount()
	local TL = ns.Talents
	if TL and TL:Has("hightable") then
		return 3
	elseif TL and TL:Has("lowstake") then
		return 1
	end
	return self.BET_STAKE
end

-- The bet waiting for its card to be picked (kept until then: a reload does not draw it again): { d (its
-- day), n (the innkeeper), r (the rarity), k (the card bet), c = { the cards: seven, four of them T.TRAP (1.14.0);
-- five, two of them T.TRAP, for a bet made in 1.12.0 and 1.13.0; three before }, ci (1.13.0: the copy bet, Copies.lua;
-- 1.14.0: the copies, a list; nil: the least precious), m (1.14.0: the copies bet; nil: one, a bet made before) }.
function T:Deal()
	local s = self:State()
	local d = s and s.deal
	local n = type(d) == "table" and type(d.c) == "table" and CuratorOctoFull.Length(d.c) or 0
	if not (n == 3 or n == 5 or n == self.BET_CARDS or n == self.BET_CARDS + 1) then
		return nil
	end
	for _, key in ipairs(d.c) do
		if key ~= self.TRAP and not (ns.Cards and ns.Cards[key]) then
			return nil
		end
	end
	return d
end

-- The bet of the day made already (1.14.0, Private Table, a talent of the Gambler: two a day).
function T:BetToday()
	local s = self:State()
	if not s then
		return false
	end
	local TL = ns.Talents
	if TL and TL:Has("private") then
		return s.bet == I:Today() and s.bet2 == I:Today()
	end
	return s.bet == I:Today()
end

-- The copies of a deal chosen by the player (Copies.lua: their numbers; a number alone for a bet made in 1.13.0).
local function DealIds(ci)
	if type(ci) == "table" then
		local out = {}
		for _, id in ipairs(ci) do
			out[CuratorOctoFull.Length(out) + 1] = tonumber(id)
		end
		return out
	end
	return tonumber(ci) and { tonumber(ci) } or {}
end

-- A bet at this innkeeper: copies of a card of a rarity (stake: the card, nil: the one with the most copies to
-- spare; 1.14.0: two copies of it, T.BET_STAKE) against his cards, face down. The deal (the one waiting, if a bet waits
-- for its card; nil and why: "closed", "unknown", "done", "rarity", "stake", "album"). (1.13.0) id: the copy bet (nil:
-- the least precious normal copy); (1.14.0) a list of them too, as many as the copies bet at most (those not chosen:
-- the least precious).
function T:Bet(npc, rarity, stake, id)
	if Closed() then
		return nil, "closed"
	end
	local s = self:State()
	if not s or type(npc) ~= "number" then
		return nil, "unknown"
	end
	local waiting = self:Deal()
	if waiting then
		return waiting
	end
	if type(rarity) ~= "number" or rarity < 1 or rarity > self.BET_TOP then
		return nil, "rarity"
	end
	-- (1.14.0: the cards changed by another addon this session: no bet, no stake taken; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	local second = false
	if s.bet == I:Today() then
		local TL = ns.Talents
		if TL and TL:Has("private") and s.bet2 ~= I:Today() then
			second = true
		else
			return nil, "done"
		end
	end
	local card
	for _, it in ipairs(self:Stakes(rarity, self:StakeCount())) do
		if not stake or it.card == stake or it.card.key == stake then
			card = it.card
			break
		end
	end
	if not card then
		return nil, "stake"
	end
	local m = self:StakeCount()
	local ids = DealIds(id)
	if CuratorOctoFull.Length(ids) > 0 and ns.Copies and not ns.Copies:Chosen(card.key, nil, ids, m) then
		return nil, "stake"
	end
	local cards = self:Draw(npc, rarity, card)
	if not cards then
		return nil, "album"
	end
	if second then
		s.bet2 = I:Today()
	else
		s.bet = I:Today()
	end
	s.deal = { d = I:Today(), n = npc, r = rarity, k = card.key, c = cards, ci = CuratorOctoFull.Length(ids) > 0 and ids or nil, m = m }
	-- (1.14.0, Gambler's Eye: one of the cards face down, its place and its rarity told before the pick)
	local TL = ns.Talents
	if TL and TL:Has("eye") then
		s.deal.eye = { p = math.random(CuratorOctoFull.Length(cards)), i = math.random(CuratorOctoFull.Length(cards)) }
	end
	ns.Fire("TAVERN_DEAL", s.deal)
	ns.Fire("CHANGED")
	return s.deal
end

-- The card picked among those face down (place: 1 to 7). Where each card lies is drawn only now (what is
-- kept of a deal does not tell where the best one is). What it did: { card (won; nil: nothing), trap (true:
-- nothing won, 1.12.0), new, count, stake (the card bet), m (1.14.0: its copies bet), cards (in their places; false
-- where nothing lies), place, rarity, up (the card of the rarity above won), npc } (nil and why: "none", "stake": the
-- duplicates bet are no longer there, nor others of its rarity).
function T:Pick(place)
	local s = self:State()
	local d = self:Deal()
	if not d or Closed() then
		return nil, "none"
	end
	-- (1.14.0: the cards changed by another addon this session: the deal waits, no stake taken; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	local n = CuratorOctoFull.Length(d.c)
	place = math.max(1, math.min(n, math.floor(tonumber(place) or 1)))
	-- (the copies bet: two since 1.14.0, one for a bet made before, the terms of its deal)
	local m = math.max(1, math.floor(tonumber(d.m) or 1))
	-- (the card bet: still enough duplicates to spare, else another one of its rarity; 1 November: asked again, not as the
	-- contract kept it, Contract.lua: K:Forget)
	local K = ns.Contract
	if K and K.Forget then
		K:Forget()
	end
	local stake = ns.Cards[d.k]
	if not (stake and K and K:Spare(stake, "normal", true) >= m) then
		local list = self:Stakes(d.r, m)
		stake = list[1] and list[1].card or nil
	end
	if not stake then
		s.deal = nil
		ns.Fire("CHANGED")
		return nil, "stake"
	end
	local order = {}
	for i = 1, n do
		order[i] = d.c[i]
	end
	-- (Gambler's Eye: the card told stays where it was told, the others are drawn around it)
	local eye = type(d.eye) == "table" and tonumber(d.eye.p) and tonumber(d.eye.i) and d.eye or nil
	local told
	if eye then
		told = CuratorOctoFull.Remove(order, math.max(1, math.min(CuratorOctoFull.Length(order), eye.i)))
	end
	for k = CuratorOctoFull.Length(order), 2, -1 do
		local x = math.random(k)
		order[k], order[x] = order[x], order[k]
	end
	if told then
		CuratorOctoFull.Insert(order, math.max(1, math.min(n, eye.p)), told)
	end
	local cards = {}
	for i = 1, n do
		cards[i] = order[i] ~= self.TRAP and ns.Cards[order[i]] or false
	end
	local won = cards[place] or nil
	-- the duplicates go to the innkeeper (normal copies), his card comes (1.12.0: or nothing; 1.13.0: the copies bet, when
	-- they are still that card's and free, else the least precious)
	local db = ns.db
	local e = db.cards[stake.key]
	local taken
	if ns.Copies then
		local chosen = stake.key == d.k and DealIds(d.ci) or {}
		if CuratorOctoFull.Length(chosen) > 0 and not ns.Copies:Chosen(stake.key, nil, chosen, m) then
			chosen = {}
		end
		local seen = {}
		for _, id in ipairs(chosen) do
			seen[id] = true
		end
		for _, r in ipairs(ns.Copies:Free(stake.key, nil)) do
			if CuratorOctoFull.Length(chosen) >= m then
				break
			end
			if not seen[r.i] then
				chosen[CuratorOctoFull.Length(chosen) + 1] = r.i
				seen[r.i] = true
			end
		end
		taken = ns.Copies:Take(stake.key, nil, m, chosen)
	end
	e.n = e.n - m
	if e.n <= 0 and db.fresh then
		db.fresh[stake.key] = nil
	end
	local new, count
	if won then
		new, count = ns.Collection:Grant(won, nil, "i")
	end
	-- (1.14.0, the Gambler: Sore Loser, the stake given back now and then; Kitty, rubies for a bet won)
	local TL = ns.Talents
	local back = false
	if not won and TL and TL:Has("sore") and math.random() < TL:V("sore") then
		back = true
		if ns.Copies and type(taken) == "table" and CuratorOctoFull.Length(taken) > 0 then
			ns.Copies:Put(stake.key, taken)
		end
		e.n = e.n + m
		if ns.Copies and ns.Copies.Reconcile then
			ns.Copies:Reconcile(stake.key)
		end
	end
	if won and TL and TL:Has("kitty") then
		TL:Rubies(60 * TL:Rank("kitty"), "kitty")
	end
	s.deal = nil
	local st = ns.Stats()
	st.bets = (tonumber(st.bets) or 0) + 1
	local up = won ~= nil and won.rarity > d.r
	if up then
		st.tavernjack = true
	end
	if not won then
		st.betsLost = (tonumber(st.betsLost) or 0) + 1
	end
	if ns.Level then
		ns.Level:Gain(self.XP.bet, "inn")
	end
	local res = { card = won, trap = won == nil, new = new, count = count, stake = stake, m = m, cards = cards, place = place, rarity = d.r,
		up = up, npc = d.n, back = back or nil }
	ns.Fire("TAVERN_BET", res)
	ns.Fire("CHANGED")
	return res
end

-------------------------------------------------------------------------------
-- The evening at the inn
-------------------------------------------------------------------------------
-- Friday evening, from 6 PM in the time of the realm (the calendar of the game).
function T:Party()
	local D = C_DateAndTime
	if not (D and D.GetCurrentCalendarTime) then
		return false
	end
	local ok, t = pcall(D.GetCurrentCalendarTime)
	if not ok or type(t) ~= "table" then
		return false
	end
	local wd, h = t.weekday, t.hour
	if Secret(wd) or Secret(h) or type(wd) ~= "number" or type(h) ~= "number" then
		return false
	end
	return wd == self.PARTY_DAY and h >= self.PARTY_HOUR
end

-------------------------------------------------------------------------------
-- The home inn
-------------------------------------------------------------------------------
-- Where the hearthstone of the character is bound, as the game says it (nil: it does not say).
local function BindLocation()
	if not GetBindLocation then
		return nil
	end
	local ok, place = pcall(GetBindLocation)
	if ok and type(place) == "string" and not Secret(place) and place ~= "" then
		return place
	end
	return nil
end

-- The innkeeper of the home inn of the character (nil: none known, or the hearthstone bound elsewhere
-- since), and what is kept of it ({ n, p = the place, t }).
function T:Home()
	if not (ns.db and ns.Rewards) then
		return nil
	end
	local h = ns.Rewards:Char().home
	if type(h) ~= "table" or type(h.n) ~= "number" then
		return nil
	end
	local place = BindLocation()
	if place and type(h.p) == "string" and place ~= h.p then
		return nil
	end
	return h.n, h
end

function T:IsHome(npc)
	return npc ~= nil and self:Home() == npc
end

-- (Inns.lua) The stamps of loyalty a stamp gives to an innkeeper: two at the home inn.
function I:HomeBonus(npc)
	return T:IsHome(npc) and T.HOME_BONUS or 1
end

-- The hearthstone bound: the innkeeper whose window was open just before (or who asked to confirm it)
-- is the home of the character. place: as the game says it.
function T:Bound(place)
	if not ns.db then
		return
	end
	local now = Clock()
	local b, last = self.binding, self.lastInn
	local npc = (b and now - b.t <= self.HOME_WAIT and b.n) or nil
	if not npc then
		local G = ns.Gossip
		npc = (G and G.open and G.role == "inn" and G.npc) or (last and now - last.t <= self.HOME_WAIT and last.n) or nil
	end
	self.binding = nil
	if type(npc) ~= "number" then
		return
	end
	local c = ns.Rewards:Char()
	local old = type(c.home) == "table" and c.home.n or nil
	-- (the place as the game says it later: the same words to compare)
	c.home = { n = npc, p = BindLocation() or place, t = Now() }
	ns.Delay(1, function()
		local h = ns.Rewards:Char().home
		local p = BindLocation()
		if type(h) == "table" and h.n == npc and p then
			h.p = p
		end
	end, T)
	if old ~= npc then
		ns.Fire("TAVERN_HOME", npc)
	end
	ns.Fire("CHANGED")
end

-- The message of the game when the hearthstone is bound ("%s is now your home."), as a pattern.
local bindPattern
local function BindPattern()
	if bindPattern == nil then
		local fmt = rawget(_G, "ERR_DEATHBIND_SUCCESS_S")
		if type(fmt) == "string" and string.find(fmt, "%s", 1, true) then
			local escaped = string.gsub(fmt, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
			bindPattern = "^" .. (string.gsub(escaped, "%%%%s", "(.+)")) .. "$"
		else
			bindPattern = false
		end
	end
	return bindPattern
end

-------------------------------------------------------------------------------
-- A toast
-------------------------------------------------------------------------------
-- The toast of the day raised already.
function T:ToastedToday()
	local s = self:State()
	return s ~= nil and s.toast == I:Today()
end

-- The collectors to raise a glass with, here: the player targeted, the members of the group the game sees
-- around (of the same faction: the messages reach them). Their full names.
function T:Mates()
	local out, seen = {}, {}
	local G = ns.Guild
	local mine = UnitFactionGroup and UnitFactionGroup("player")
	local function Add(unit)
		local ok, exists = pcall(UnitExists, unit)
		if not ok or Secret(exists) or not exists then
			return
		end
		local okp, player = pcall(UnitIsPlayer, unit)
		if not okp or Secret(player) or not player then
			return
		end
		local oku, me = pcall(UnitIsUnit, unit, "player")
		if not oku or Secret(me) or me then
			return
		end
		local name, realm = UnitName(unit)
		if type(name) ~= "string" or Secret(name) or name == "" or name == rawget(_G, "UNKNOWNOBJECT") then
			return
		end
		if Secret(realm) then
			realm = nil
		end
		local okf, faction = pcall(UnitFactionGroup, unit)
		if okf and faction and mine and not Secret(faction) and not Secret(mine) and faction ~= mine then
			return
		end
		if UnitIsVisible then
			local okv, visible = pcall(UnitIsVisible, unit)
			if okv and not Secret(visible) and not visible then
				return
			end
		end
		local full = G and G:Full(name, realm) or name
		if full and not seen[full] then
			seen[full] = true
			out[CuratorOctoFull.Length(out) + 1] = full
		end
	end
	Add("target")
	local n = GetNumGroupMembers and GetNumGroupMembers() or 0
	if Secret(n) or type(n) ~= "number" then
		n = 0
	end
	if IsInRaid and IsInRaid() then
		for i = 1, n do
			Add("raid" .. i)
		end
	else
		for i = 1, math.max(0, n - 1) do
			Add("party" .. i)
		end
	end
	return out
end

-- A glass raised to a collector at this innkeeper: the invitation goes (its answer, if it comes in time: a
-- stamp more for each). True when it went.
function T:Cheer(name, npc)
	if Closed() or self:ToastedToday() or type(npc) ~= "number" or type(name) ~= "string" or not ns.Guild then
		return false
	end
	local last = self.sent[name]
	if last and last.n == npc and Clock() - last.t < 10 then
		return true
	end
	local ok = ns.Guild:Send(string.format(("K:%s:t,%d,%d"), ns.Guild.VERSION or "1", npc, I:Today()), "WHISPER", name)
	if ok then
		self.sent[name] = { n = npc, t = Clock() }
	end
	return ok and true or false
end

-- A glass raised to me already, waiting at this innkeeper: the invitations, the latest first ({ name, t }).
function T:Invites(npc)
	local out = {}
	local now = Clock()
	for name, inv in pairs(self.invites) do
		if now - inv.t > self.TOAST_WAIT then
			self.invites[name] = nil
		elseif inv.n == npc then
			out[CuratorOctoFull.Length(out) + 1] = { name = name, t = inv.t }
		end
	end
	table.sort(out, function(a, b)
		return a.t > b.t
	end)
	return out
end

-- A toast done with a collector, at an innkeeper: a stamp more on the loyalty card, the toast of the day.
-- What the stamp did (Inns:BonusStamp; nil: nothing).
function T:Cheers(name, npc)
	if self:ToastedToday() or Closed() then
		return nil
	end
	local s = self:State()
	if not s then
		return nil
	end
	-- (1.14.0: the cards changed by another addon this session: the toast of the day waits; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil
	end
	s.toast = I:Today()
	local st = ns.Stats()
	st.cheers = (tonumber(st.cheers) or 0) + 1
	local res = I:BonusStamp(npc, "toast")
	if res then
		res.with = name
	end
	ns.Fire("TAVERN_CHEERS", name, npc, res)
	return res
end

-- My glass raised in answer to a collector's, at this innkeeper: the answer goes back, a stamp more for me
-- (for the other collector when the answer reaches him). What the stamp did (nil: nothing).
function T:Answer(name, npc)
	local inv = self.invites[name]
	if not inv or inv.n ~= npc or Clock() - inv.t > self.TOAST_WAIT or self:ToastedToday() or Closed() then
		return nil
	end
	self.invites[name] = nil
	if ns.Guild then
		ns.Guild:Send(string.format(("K:%s:a,%d,%d"), ns.Guild.VERSION or "1", npc, I:Today()), "WHISPER", name)
	end
	return self:Cheers(name, npc)
end

-- (Comm.lua) A message of a toast, whispered: "t,<npc>,<day>" a glass raised to me at an innkeeper,
-- "a,<npc>,<day>" the answer to mine.
function T:OnMessage(body, channel, sender)
	if channel ~= "WHISPER" or type(body) ~= "string" or type(sender) ~= "string" or not ns.db then
		return
	end
	local what, npc, day = CuratorOctoFull.Match(body, "^(%a),(%d+),(%d+)$")
	npc, day = tonumber(npc), tonumber(day)
	if not (what and npc and day) or day ~= I:Today() then
		return
	end
	if what == "t" then
		if self:ToastedToday() or Closed() then
			return
		end
		self.invites[sender] = { n = npc, t = Clock() }
		ns.Fire("TAVERN_INVITED", sender, npc)
	elseif what == "a" then
		local sent = self.sent[sender]
		if not sent or sent.n ~= npc or Clock() - sent.t > self.TOAST_WAIT + 60 then
			return
		end
		self.sent[sender] = nil
		self:Cheers(sender, npc)
	end
end

if ns.Guild and ns.Guild.Handle then
	ns.Guild:Handle("K", function(body, channel, sender)
		T:OnMessage(body, channel, sender)
	end)
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
ns.On("NPC_TALK", function(role, npc)
	if role == "inn" and type(npc) == "number" then
		T.lastInn = { n = npc, t = Clock() }
		-- (1.14.0: the round owed for the leads followed to their card)
		if ns.db then
			T:PayRound(npc)
		end
	end
end)

-- (the stamp of an evening at the inn: counted for its achievement)
ns.On("INN_STAMP", function(res)
	if res and res.party and ns.db then
		local st = ns.Stats()
		st.parties = (tonumber(st.parties) or 0) + 1
	end
end)

-- (a card of a rumor found: counted; 1.14.0: its lead done, a round owed, once every other handler of the event saw
-- the lead: Treasure Map, Talents.lua)
ns.On("CARD_FOUND", function(card)
	if ns.db and T:Rumored(card) then
		local st = ns.Stats()
		st.rumorTrue = (tonumber(st.rumorTrue) or 0) + 1
		ns.Delay(0, function()
			T:LeadDone(card)
		end, T)
	end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "CONFIRM_BINDER", "HEARTHSTONE_BOUND", "CHAT_MSG_SYSTEM" }) do
			pcall(self.RegisterEvent, self, e)
		end
	elseif event == "CONFIRM_BINDER" then
		local area = unpack(arg, 1, arg.n)
		local G = ns.Gossip
		local now = Clock()
		local npc = (G and G.open and G.role == "inn" and G.npc) or (T.lastInn and now - T.lastInn.t <= T.HOME_WAIT and T.lastInn.n) or nil
		T.binding = npc and { n = npc, t = now, p = (type(area) == "string" and not Secret(area)) and area or nil } or nil
	elseif event == "HEARTHSTONE_BOUND" then
		local b = T.binding
		T:Bound(b and b.p)
		T.boundAt = Clock()
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = unpack(arg, 1, arg.n)
		if type(msg) ~= "string" or Secret(msg) then
			return
		end
		local pat = BindPattern()
		local place = pat and CuratorOctoFull.Match(msg, pat)
		-- (the event of the hearthstone came already: the message says the same)
		if place and not (T.boundAt and Clock() - T.boundAt < 5) then
			T:Bound(place)
		end
	end
end)
