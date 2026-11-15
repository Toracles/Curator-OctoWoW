local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.8.0) The inns of Azeroth. Each innkeeper (Data/Places.lua: ns.INNKEEPERS; an NPC the game shows
-- as one, with the option to make its inn your home, counts as well) keeps three things for the
-- collector, who talks to them (UI/Gossip.lua: the lines of Curator in their window):
-- * the loyalty card: one stamp a day (the day of the server), at any innkeeper. The seventh stamp gives
--   a booster of the album of the place of its inn (the album of that innkeeper's card), and the card
--   starts over;
-- * the travel passport: the first time the collector talks to an innkeeper, its visa (as many a day as
--   the inns visited). 10, 25 and every inn of Azeroth give boosters to choose;
-- * the loyalty of each innkeeper: the stamps taken at that innkeeper (Passing guest, Regular, Pillar of
--   the bar, Friend of the house). A friend of the house signs his own card for the collector: a copy of
--   it, signed in his hand, that no trade and no contract takes (Trade.lua, Contract.lua: one copy kept).
-- (1.14.0, after its test, his word: the innkeeper redone) The stamp of the day comes with the dish of the day of its
-- innkeeper, longer as his loyalty grows (Lodging.lua, with the rest of the collector).
-- The collection is the account's: the stamps, the visas and the loyalty too (db.inns, sealed with the
-- rest of the save; the places in the language of the game where they were visited).
-------------------------------------------------------------------------------
local I = {}
ns.Inns = I

I.CARD = 7 -- the stamps of a loyalty card
-- the ranks of loyalty: from so many stamps at an innkeeper
I.RANKS = {
	{ n = 1, name = "Passing guest" },
	{ n = 5, name = "Regular" },
	{ n = 10, name = "Pillar of the bar" },
	{ n = 20, name = "Friend of the house" },
}
I.SIGN_RANK = CuratorOctoFull.Length(I.RANKS)
-- the steps of the passport: so many visas (all: every inn known), so many boosters of a zone to choose
I.STEPS = { { goal = 10, packs = 1 }, { goal = 25, packs = 2 }, { goal = "all", packs = 3 } }
-- the experience of the collector: a stamp, a card full, a visa, a rank, a signed card
I.XP = { stamp = 40, card = 200, visa = 25, rank = 100, signed = 300 }
-- the icons of the option of an inn (the hearthstone bound there), as the server gives them
I.BINDER = { [132052] = true, [4955461] = true }

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- What Curator keeps of the inns (db.inns): the day of the last stamp, the stamps of the card now
-- ({ n = innkeeper, t = time }), the cards full, the stamps in all, the visas ([npc] = { t, p = the
-- place, m = the name of an innkeeper Curator did not know }), the loyalty ([npc] = stamps), the signed
-- cards ([npc] = time), the steps of the passport reached ([i] = time).
function I:State()
	local db = ns.db
	if not db then
		return nil
	end
	local s = db.inns
	if type(s) ~= "table" then
		s = {}
		db.inns = s
	end
	if type(s.card) ~= "table" then
		s.card = {}
	end
	if type(s.visas) ~= "table" then
		s.visas = {}
	end
	if type(s.loyal) ~= "table" then
		s.loyal = {}
	end
	if type(s.signed) ~= "table" then
		s.signed = {}
	end
	if type(s.steps) ~= "table" then
		s.steps = {}
	end
	s.cards = tonumber(s.cards) or 0
	s.stamps = tonumber(s.stamps) or 0
	return s
end

-- Nothing to earn: a beta past its day, a collection suspended, an update missed.
local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-------------------------------------------------------------------------------
-- The innkeepers
-------------------------------------------------------------------------------
function I:Known(npc)
	return type(npc) == "number" and ns.INNKEEPERS ~= nil and ns.INNKEEPERS[npc] ~= nil
end

-- The innkeepers Curator knows: their number.
function I:AllCount()
	if not self.all then
		local n = 0
		for _ in pairs(ns.INNKEEPERS or {}) do
			n = n + 1
		end
		self.all = n
	end
	return self.all
end

-- An NPC the collector talks to is an innkeeper: one Curator knows, or one whose options hold the inn's
-- (options: those of its window, C_GossipInfo.GetOptions).
function I:IsInnkeeper(npc, options)
	if self:Known(npc) then
		return true
	end
	for _, o in ipairs(options or {}) do
		local icon = type(o) == "table" and (o.overrideIconID or o.icon) or nil
		if icon and not Secret(icon) and self.BINDER[icon] then
			return true
		end
	end
	return false
end

-- The card of an innkeeper (nil: an innkeeper with no card).
function I:CardOf(npc)
	return ns.Cards and npc and ns.Cards["c" .. tostring(npc)] or nil
end

-- The album of the place of an innkeeper: the album of its card.
function I:Album(npc)
	local card = self:CardOf(npc)
	return card and card.series or nil
end

-- The name of an innkeeper: its card's, else the one kept with its visa.
function I:Name(npc)
	local card = self:CardOf(npc)
	if card then
		return ns.Collection:Name(card)
	end
	local s = self:State()
	local v = s and s.visas[npc]
	return (type(v) == "table" and v.m) or "?"
end

-- (1.14.0, the page of the inns redone) The words of a name (a space that does not break, in the subtitles of some
-- languages, is a space), the letters of a word, two words of the same trade (the same but for their ends: Tabernero,
-- Tabernera; Хозяин, Хозяйка; Gastwirt, Gastwirtin).
local NBSP = "\194\160"
local function Words(s)
	local t = {}
	for w in CuratorOctoFull.Gmatch((string.gsub(s, NBSP, " ")), "%S+") do
		t[CuratorOctoFull.Length(t) + 1] = w
	end
	return t
end
local function Letters(w)
	local t = {}
	for c in CuratorOctoFull.Gmatch(w, "[%z\1-\127\194-\244][\128-\191]*") do
		t[CuratorOctoFull.Length(t) + 1] = c
	end
	return t
end
local function SameTrade(a, b)
	local x, y = Letters(string.lower(a)), Letters(string.lower(b))
	local n = 0
	while n < CuratorOctoFull.Length(x) and n < CuratorOctoFull.Length(y) and x[n + 1] == y[n + 1] do
		n = n + 1
	end
	return n >= 4 and n >= math.min(CuratorOctoFull.Length(x), CuratorOctoFull.Length(y)) - 2
end

-- (1.14.0) The word most names of the innkeepers start with, as this language says them (the word of their trade,
-- when the subtitle of their cards says another one: "Hospedagem", "Estalajadeiro Belm"); nil: none most share.
function I:TradeWord()
	if self.trade == nil then
		self.trade = false
		local count, total = {}, 0
		for npc in pairs(ns.INNKEEPERS or {}) do
			local card = self:CardOf(npc)
			local w = card and Words(ns.Collection:Name(card)) or {}
			total = total + (card and 1 or 0)
			if CuratorOctoFull.Length(w) >= 2 then
				local k = string.lower(w[1])
				count[k] = (count[k] or 0) + 1
			end
		end
		local best, most = nil, 0
		for k, n in pairs(count) do
			if n > most or (n == most and best and k < best) then
				best, most = k, n
			end
		end
		-- (a word most of them share: not the first name of the two innkeepers a language did not translate)
		if best and most >= 5 and most >= total * 0.4 then
			self.trade = best
		end
	end
	return self.trade or nil
end

-- The name of an innkeeper without the word of his trade ("Aubergiste Farley", "Belm l'aubergiste":
-- Farley, Belm), for the small places of the passport. (1.14.0: also when the subtitle of his card says it with a
-- space that does not break, for a man when she is a woman, or with another word)
function I:ShortName(npc)
	local name = self:Name(npc)
	local card = self:CardOf(npc)
	local sub = card and ns.Collection.Sub and ns.Collection:Sub(card) or nil
	local plain = (string.gsub(name, NBSP, " "))
	if type(sub) == "string" and sub ~= "" then
		sub = (string.gsub(sub, NBSP, " "))
		local i, j = string.find(string.lower(plain), string.lower(sub), 1, true)
		if i then
			local short = string.gsub(string.gsub((string.sub(plain, 1, i - 1) .. string.sub(plain, j + 1)), "%s+l'%s*$", ""), "%s+l\226\128\153%s*$", "")
			short = string.gsub(string.gsub(short, "^%s+", ""), "%s+$", "")
			return short ~= "" and short or name
		end
		-- (the same trade said for a woman: its words at the start of the name)
		local sw, nw = Words(sub), Words(plain)
		if CuratorOctoFull.Length(nw) > CuratorOctoFull.Length(sw) then
			local same = true
			for k = 1, CuratorOctoFull.Length(sw) do
				same = same and SameTrade(sw[k], nw[k])
			end
			if same then
				return table.concat(nw, " ", CuratorOctoFull.Length(sw) + 1)
			end
		end
	end
	-- (the word of the trade said otherwise than the subtitle: the one most innkeepers start with)
	local trade = self:TradeWord()
	local nw = Words(plain)
	if trade and CuratorOctoFull.Length(nw) >= 2 and SameTrade(nw[1], trade) then
		return table.concat(nw, " ", 2)
	end
	return name
end

-- The place of an inn, as it was when its visa came (the inn, the town), else the album of its place.
function I:Place(npc)
	local s = self:State()
	local v = s and s.visas[npc]
	if type(v) == "table" and type(v.p) == "string" and v.p ~= "" then
		return v.p
	end
	local album = self:Album(npc)
	return album and ns.Collection:SeriesName(album) or "?"
end

-- The place where the player stands: the inn (the most precise name the game gives), else the zone.
function I:Here()
	for _, fn in ipairs({ GetMinimapZoneText, GetSubZoneText, GetRealZoneText, GetZoneText }) do
		if fn then
			local ok, text = pcall(fn)
			if ok and type(text) == "string" and not Secret(text) and text ~= "" then
				return text
			end
		end
	end
	return nil
end

-------------------------------------------------------------------------------
-- The loyalty of each innkeeper
-------------------------------------------------------------------------------
-- The rank of so many stamps (0: none yet).
function I:Rank(n)
	local r = 0
	for i, x in ipairs(self.RANKS) do
		if (n or 0) >= x.n then
			r = i
		end
	end
	return r
end

-- The name of a rank (the one of a female character, in the languages that make one: "<name>#f").
function I:RankName(r, female)
	local x = self.RANKS[r or 0]
	if not x then
		return nil
	end
	if female == nil and UnitSex then
		local ok, sex = pcall(UnitSex, "player")
		female = ok and sex == 3
	end
	if female then
		local fk = x.name .. "#f"
		local v = L[fk]
		if v ~= fk then
			return v
		end
	end
	return L[x.name]
end

-- The stamps taken at an innkeeper, its rank, the stamps of the next rank (nil: the last one reached).
function I:Loyalty(npc)
	local s = self:State()
	local n = s and tonumber(s.loyal[npc]) or 0
	local r = self:Rank(n)
	local nextRank = self.RANKS[r + 1]
	return n, r, nextRank and nextRank.n or nil
end

-------------------------------------------------------------------------------
-- The loyalty card
-------------------------------------------------------------------------------
-- (1.12.0) The day of the inns: from 5:00 in Paris to the next 5:00, as the quests (the same moment for
-- every player; before, the daily reset of the realm). Its number: the moment it ends, in tens of minutes.
function I:Today()
	local Q = ns.Quests
	if Q and Q.ResetPeriod then
		return math.floor((Q:ResetPeriod("day")) / 600)
	end
	return ns.Rewards and ns.Rewards:Today() or math.floor(Now() / 86400)
end

-- (1.12.0) The seconds until the next day of the inns (the next stamp, rumor, bet).
function I:NextIn()
	local Q = ns.Quests
	if Q and Q.ResetLeft then
		return Q:ResetLeft("day")
	end
	return 86400 - CuratorOctoFull.Mod(Now() , 86400)
end

-- The stamp of the day taken already.
function I:StampedToday(today)
    local s = self:State()
    if not s then return false end
    today = today or self:Today()
    -- Keep the previous stamp locked through the first valid reset after an invalid clock.
    if ns.Quests and ns.Quests.ResetPeriod and type(s.day) == "number" and s.day > 0
        and ns.IsCalendarTime(today * 600) and not ns.IsCalendarTime(s.day * 600) then
        s.day = today
    end
    return s.day == today
end

-- The stamps of the card now: { n = innkeeper, t = time }.
function I:CardStamps()
	local s = self:State()
	return s and s.card or {}
end

-- The album the booster of the card full would come from, stamped at this innkeeper (nil: a booster of
-- a zone to choose).
function I:Prize(npc)
	return self:Album(npc) or (ns.Rewards and ns.Rewards:WorldSeries()) or nil
end

-- The stamps of loyalty a stamp gives to its innkeeper (the inn of the hearthstone counts double:
-- Tavern.lua).
function I:LoyaltyStep(npc)
	return (self.HomeBonus and self:HomeBonus(npc)) or 1
end

-- The stamps the stamp of the day puts on the card (the evening at the inn: two, Tavern.lua).
function I:StampsNow()
	return (ns.Tavern and ns.Tavern:Party()) and 2 or 1
end

-- n stamps on the card, at this innkeeper (res: what they did). A card full gives its booster and starts
-- over: res.complete = { series, stamps (the card full) }. res.at: the stamps of the card before them,
-- res.added: n (their places: res.at + 1 to res.at + n, past the seventh on the new card).
function I:AddStamps(npc, n, res)
	local s = self:State()
	local card = s.card
	res.at, res.added = CuratorOctoFull.Length(card), n
	for _ = 1, n do
		card[CuratorOctoFull.Length(card) + 1] = { n = npc, t = Now() }
		s.stamps = s.stamps + 1
		if CuratorOctoFull.Length(card) >= self.CARD then
			local series = self:Prize(npc)
			local stamps = {}
			for i, x in ipairs(card) do
				stamps[i] = { n = x.n, t = x.t }
			end
			CuratorOctoFull.Wipe(card)
			s.cards = s.cards + 1
			res.complete = { series = series, stamps = stamps }
			res.xp = (res.xp or 0) + self.XP.card
			if ns.Rewards then
				ns.Rewards:Give(series, 1, "inn")
				-- (1.14.0, Bed and Board, a talent of the Cartographer: a booster more now and then)
				local TL = ns.Talents
				if TL and TL:Has("lodging") and math.random() < TL:V("lodging") then
					ns.Rewards:Give(series, 1, "inn")
					res.complete.more = 1
					ns.Fire("TALENT_PROC", "lodging", series)
				end
			end
		end
	end
	return res
end

-- The stamp of the day, at this innkeeper. What it did: { npc, at, added, slot (of the first), loyal,
-- before, after (ranks), up (a new rank worth telling), complete = { series, stamps }, signed = card, party,
-- xp } (nil and why: "closed", "done", "unknown").
function I:Stamp(npc)
	if Closed() then
		return nil, "closed"
	end
	local s = self:State()
	if not s or type(npc) ~= "number" then
		return nil, "unknown"
	end
	local today = self:Today()
	if self:StampedToday(today) then
		return nil, "done"
	end
	-- (1.14.0: the cards changed by another addon this session: no stamp today yet; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil, "guard"
	end
	-- (the visa of the inn, if the visit did not give it already)
	self:Visa(npc)
	s.day = today
	local before = tonumber(s.loyal[npc]) or 0
	local step = self:LoyaltyStep(npc)
	-- (1.14.0, Friend of the Innkeepers, a talent of the Archivist: the stamp counts twice now and then)
	local TL = ns.Talents
	local friend = TL ~= nil and TL:Has("innfriend") and math.random() < TL:V("innfriend")
	if friend then
		step = step * 2
	end
	local after = before + step
	s.loyal[npc] = after
	local res = { npc = npc, loyal = after, before = self:Rank(before), after = self:Rank(after), xp = self.XP.stamp, friend = friend or nil }
	local n = self:StampsNow()
	res.party = n > 1
	self:AddStamps(npc, n, res)
	res.slot = res.at + 1
	-- (1.14.0: his dish of the day, offered with the stamp; Lodging.lua)
	if ns.Lodging then
		res.dish = ns.Lodging:Take(npc)
	end
	-- (a first stamp at an innkeeper makes a passing guest of the collector: no news, the ranks after it are)
	res.up = res.after > res.before and res.after >= 2
	if res.up then
		res.xp = res.xp + self.XP.rank * (res.after - math.max(res.before, 1))
		if res.after >= self.SIGN_RANK then
			res.signed = self:Sign(npc)
			if res.signed then
				res.xp = res.xp + self.XP.signed
			end
		end
	elseif res.after >= self.SIGN_RANK and not s.signed[npc] then
		-- (a friend of the house whose signed card went with a collection emptied: he signs it again)
		res.signed = self:Sign(npc)
	end
	if ns.Level then
		ns.Level:Gain(res.xp, "inn")
	end
	ns.Fire("INN_STAMP", res)
	if res.up then
		ns.Fire("INN_RANK", npc, res.after, res.before)
	end
	ns.Fire("CHANGED")
	return res
end

-- A stamp more on the card (a toast with another collector, Tavern.lua): not the stamp of the day, nor
-- the loyalty of an innkeeper. What it did (as Stamp; nil when nothing can be earned).
function I:BonusStamp(npc, why)
	if Closed() or not self:State() then
		return nil
	end
	-- (1.14.0: the cards changed by another addon this session: no stamp, the card waits as it is; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil
	end
	local res = { npc = npc, bonus = why or true, xp = self.XP.stamp }
	self:AddStamps(npc, 1, res)
	res.slot = res.at + 1
	if ns.Level then
		ns.Level:Gain(res.xp, "inn")
	end
	ns.Fire("INN_BONUS", res)
	ns.Fire("CHANGED")
	return res
end

-------------------------------------------------------------------------------
-- The signed cards
-------------------------------------------------------------------------------
-- An innkeeper, friend of the house, signs his card: a copy of it comes, signed (the card of an
-- innkeeper Curator has no card of: nothing). The card.
function I:Sign(npc)
	local s = self:State()
	local card = self:CardOf(npc)
	if not (s and card) or s.signed[npc] then
		return nil
	end
	-- (1.14.0: the card changed by another addon this session: not signed yet; Guard.lua)
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return nil
	end
	s.signed[npc] = Now()
	-- (the signed copy: a copy of the card, given with it; "i": an innkeeper gave it; 1.13.0: that copy, Copies.lua)
	ns.Collection:Grant(card, nil, "i")
	local CP = ns.Copies
	if CP and CP.last and CP.last.f == nil then
		for _, r in ipairs(CP:List(card.key)) do
			r.sg = nil
		end
		CP.last.sg = true
	end
	ns.Fire("INN_SIGNED", card)
	return card
end

-- The card (or its key) signed for the collector.
function I:IsSigned(card)
	local key = type(card) == "table" and card.key or card
	local npc = type(key) == "string" and tonumber(CuratorOctoFull.Match(key, "^c(%d+)$")) or nil
	local s = npc and self:State()
	return s ~= nil and s.signed[npc] ~= nil
end

-- The copies of a card kept out of the trades and the contracts: its signed copy (a normal one).
function I:Kept(key, finish)
	if (finish == nil or finish == "normal") and self:IsSigned(key) then
		return 1
	end
	return 0
end

function I:SignedCount()
	local n = 0
	local s = self:State()
	for _ in pairs(s and s.signed or {}) do
		n = n + 1
	end
	return n
end

-- The signature of an innkeeper (its texture; nil: none drawn for it).
function I:Signature(npc)
	if self:Known(npc) and self:CardOf(npc) then
		return ns.MEDIA .. "Sign\\" .. npc
	end
end

-------------------------------------------------------------------------------
-- The travel passport
-------------------------------------------------------------------------------
-- The visas: how many, and how many of the inns Curator knows.
function I:VisaCount()
	local s = self:State()
	local n, known = 0, 0
	for npc in pairs(s and s.visas or {}) do
		n = n + 1
		if self:Known(npc) then
			known = known + 1
		end
	end
	return n, known
end

function I:HasVisa(npc)
	local s = self:State()
	return s ~= nil and s.visas[npc] ~= nil
end

-- The goal of a step of the passport.
function I:StepGoal(i)
	local st = self.STEPS[i]
	if not st then
		return nil
	end
	return st.goal == "all" and self:AllCount() or st.goal
end

-- The visa of an inn: the first visit to its innkeeper (place: where it is, else where the player
-- stands; name: the innkeeper's, kept for one Curator does not know). True when it is new.
function I:Visa(npc, place, name)
	if Closed() then
		return false
	end
	local s = self:State()
	if not s or type(npc) ~= "number" or s.visas[npc] then
		return false
	end
	-- (1.14.0: the cards changed by another addon this session: the visa waits for the next visit; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return false
	end
	local v = { t = Now(), p = place or self:Here() }
	if not self:Known(npc) and type(name) == "string" and not Secret(name) then
		v.m = name
	end
	s.visas[npc] = v
	if ns.Level then
		ns.Level:Gain(self.XP.visa, "inn")
	end
	local n, known = self:VisaCount()
	ns.Fire("INN_VISA", npc, n)
	-- (the steps of the passport: every visa counts, "every inn" the inns Curator knows)
	for i, st in ipairs(self.STEPS) do
		local reached = (st.goal == "all" and known >= self:AllCount()) or (st.goal ~= "all" and n >= st.goal)
		if reached and not s.steps[i] then
			s.steps[i] = Now()
			if ns.Rewards then
				ns.Rewards:Give(nil, st.packs, "passport")
			end
			ns.Fire("INN_STEP", i, st.packs)
		end
	end
	ns.Fire("CHANGED")
	return true
end

-------------------------------------------------------------------------------
-- The collector talks to an innkeeper (UI/Gossip.lua): its visa, if it is the first time.
-------------------------------------------------------------------------------
ns.On("NPC_TALK", function(role, npc, name)
	if role == "inn" and type(npc) == "number" and ns.db then
		I:Visa(npc, I:Here(), name)
	end
end)

-- (a collection emptied: the signed cards go with its cards; everything else of the inns goes with
-- what the places gave, when it starts over entirely)
function I:Empty(full)
	local s = ns.db and ns.db.inns
	if type(s) ~= "table" then
		return
	end
	s.signed = {}
	if full then
		ns.db.inns = {}
	end
end
