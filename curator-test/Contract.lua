local _, ns = "Curator", CuratorOctoFull

-- Exchange contracts: ten copies of one rarity and one finish, taken from any albums, for one card
-- of the next rarity with the same finish. The album of the new card is drawn in proportion to the
-- copies given from each album (5 from Elwynn and 5 from Loch Modan: one chance in two each), then
-- the card among that album's cards of the next rarity. Shiny and holographic copies only go with
-- copies of their own finish. Up to five contracts are signed at once (fifty copies, five new cards:
-- each drawn the same way, from all the copies given).
-- (1.13.0, after its second test) Redone: a legendary card at most (K.TOP: a mythic card is earned, in the boosters,
-- never exchanged); the clause of the collection (every copy given from one album: the new card is one that album is
-- missing, K:Clause); the register of the last contracts signed (db.kLog, K:Log).
local K = { SIZE = 10, MAX = 5 }
ns.Contract = K
-- (1.14.0) Each card a contract gave, as it gave it (K:Redraw)
local SIGNED = setmetatable({}, { __mode = "k" })
local C = ns.Collection

K.FINISHES = { "normal", "shiny", "holo" }
-- the rarity the contracts give at most (legendary), and the rarity of the copies of the last of them (epic)
K.TOP = ns.MYTHIC - 1
K.LAST = K.TOP - 1
-- the contracts the register keeps
K.LOG_MAX = 20

-- A rarity of copies a contract takes (common to epic).
function K:Takes(rarity)
	rarity = tonumber(rarity) or 0
	return rarity >= 1 and rarity <= self.LAST
end

-- (1.6.0) The cards a contract takes and how many contracts go at once: the talents of the Merchant
-- change them (fewer cards for some rarities and the finishes, five with the Favor Contract armed; up
-- to ten at once).
function K:SizeOf(rarity, finish, favor)
	if ns.Talents then
		return ns.Talents:ContractSize(self.SIZE, rarity, finish, favor)
	end
	return self.SIZE
end

-- The Favor Contract armed on a contract, and still ready.
local function Favor(ct)
	return ct.favor and ns.Talents ~= nil and ns.Talents:Ready("favor") or false
end
K.Favor = Favor

function K:Size(ct)
	return self:SizeOf(ct.rarity, ct.finish, Favor(ct))
end

function K:Max()
	return ns.Talents and ns.Talents:ContractMax(self.MAX) or self.MAX
end

-- A talent of the next contract (1.6.0: the Favor Contract, the Masterstroke, the Tailor-Made Contract with its album,
-- the Alchemist, talents of the Merchant): such a contract is signed alone. (1.14.0: the trees of before gone, none.)
K.ACTIVES = {}
function K:Single(ct)
	return (ct.favor or ct.master or ct.tailor or ct.alchemist) and true or false
end

function K:SetActive(ct, key, value)
	local id = self.ACTIVES[key]
	if not id then
		return false
	end
	if value and not (ns.Talents and ns.Talents:Ready(id)) then
		return false
	end
	ct[key] = value or nil
	if value then
		self:SetCount(ct, 1)
	end
	-- (the copies past what it now takes go back)
	while ct.count > self:Capacity(ct) do
		self:TakeAt(ct, ct.count)
	end
	return true
end

-- Copies of a card in a finish: the normal ones are the copies that are neither shiny nor holographic (1.12.0:
-- nor corrupted: the corrupted copies of a card never leave the album, they are in no list of finishes to give).
function K.Copies(e, finish)
	if not e or e.n <= 0 then
		return 0
	end
	local s, h, c = e.s or 0, e.h or 0, math.min(e.n, math.max(0, math.floor(tonumber(e.c) or 0)))
	if finish == "shiny" then
		return s
	elseif finish == "holo" then
		return h
	elseif finish == "corrupt" then
		return c
	end
	return math.max(0, e.n - s - h - c)
end

-- (1 November, his error « script ran too long » at the exchange contract: what a card has to spare asked again and
-- again in a paint of the page, every card of every album, the cards not had too: a card without a copy of that finish
-- answers at once; one that has some, asked once a frame (its counts in the question: a copy that comes or goes asks
-- again at once), anything that changes the copies asks again at once (the events below), a contract signed too)
local MEMO, memoT = {}, nil
local function Memo()
	local now = GetTime and GetTime() or 0
	if memoT ~= now then
		memoT = now
		MEMO = {}
	end
	return MEMO
end
function K:Forget()
	memoT = nil
end

-- (the copies at an enchanter, every card, counted once a frame: "<card>:<finish of the record>")
local function AwayIndex(memo)
	local idx = memo.__away
	if idx then
		return idx
	end
	idx = {}
	local all = ns.db and type(ns.db.copies) == "table" and ns.db.copies
	for key, list in pairs(all or {}) do
		if type(list) == "table" then
			for _, r in ipairs(list) do
				if type(r) == "table" and type(r.aw) == "table" then
					local k = key .. ":" .. tostring(r.f)
					idx[k] = (idx[k] or 0) + 1
				end
			end
		end
	end
	memo.__away = idx
	return idx
end
for _, ev in ipairs({ "CHANGED", "COPIES_CHANGED", "TRADES_CHANGED", "TRADE_IN", "TRADE_REVERSED", "TRADE_NO", "COPY_RESTORED",
	"REST_CHANGED", "CASES_CHANGED", "SHOWCASE_CHANGED", "MAIN_CHANGED" }) do
	ns.On(ev, function()
		memoT = nil
	end)
end

-- The copies of a card that can go into a contract. keep: one copy of each card stays in the album
-- (its finest one). The copies that came in a trade not confirmed yet wait (Trade.lua).
function K:Spare(card, finish, keep)
	if finish == "corrupt" or not card or (card.series and card.series.limited) then
		return 0
	end
	local e = C:Entry(card)
	local n = self.Copies(e, finish)
	if n <= 0 then
		return 0
	end
	local memo = Memo()
	local mk = card.key .. (finish or "normal") .. (keep and "1" or "0") .. n .. ":" .. tostring(e.n) .. ":" .. tostring(e.s) .. ":" .. tostring(e.h)
	local v = memo[mk]
	if v == nil then
		v = self:SpareNow(card, finish, keep)
		memo[mk] = v
	end
	return v
end

function K:SpareNow(card, finish, keep)
	-- (1.12.0: a corrupted copy never leaves the album, whoever asks for it)
	if finish == "corrupt" then
		return 0
	end
	-- (1.13.0: nor a copy of a limited edition of another game, the Hardcup Saison 3: its cards come from a gift code
	-- only, no contract makes one, no reseller buys one, no bet of the tavern takes one)
	if card and card.series and card.series.limited then
		return 0
	end
	local e = C:Entry(card)
	local n = self.Copies(e, finish)
	-- (1 November, his error « script ran too long » at the exchange contract, a big collection: no copy of that finish,
	-- nothing to spare, nothing else asked)
	if n <= 0 then
		return 0
	end
	-- (no trade waiting, nothing held: not asked)
	local T = ns.Trade
	if T then
		if T.held == nil and T.CountLocks then
			T:CountLocks()
		end
		if T.held == nil or next(T.held) ~= nil then
			n = n - T:Held(card.key, finish)
		end
	end
	-- (1.8.0: the copies put on a duel wait for it)
	if ns.Duel then
		n = n - ns.Duel:Staked(card.key, finish)
	end
	-- (1.8.0: the copy signed by its innkeeper stays: the one kept, when it is the finest)
	local signed = ns.Inns and ns.Inns:Kept(card.key, finish) or 0
	n = n - signed
	-- (1.13.0: the copies at an enchanter wait for him: Restore.lua; 1 November: counted once a frame, AwayIndex)
	if ns.Copies then
		local CP = ns.Copies
		n = n - (AwayIndex(Memo())[card.key .. ":" .. tostring(CP.FK and CP.FK[finish or ""])] or 0)
	end
	if n > 0 and keep and signed == 0 and finish == (C:BestFinish(e) or "normal") then
		n = n - 1
	end
	return math.max(0, n)
end

local function Albums()
	return (ns.Album and ns.Album.Order) and ns.Album:Order() or ns.Series
end

-- The cards with copies to spare in a rarity and a finish: { card, spare }, album by album (in the
-- order of the contents), or of one album only.
function K:Eligible(rarity, finish, keep, series)
	local out = {}
	for _, s in ipairs(Albums()) do
		if not series or s == series then
			for _, card in ipairs(s.byRarity[rarity] or {}) do
				local n = self:Spare(card, finish, keep)
				if n > 0 then
					out[CuratorOctoFull.Length(out) + 1] = { card = card, spare = n }
				end
			end
		end
	end
	return out
end

-- Copies to spare of every rarity, in a finish (for the counters of the contract page).
function K:SpareByRarity(finish, keep)
	local out = C.PerRarity(0)
	for _, s in ipairs(ns.Series or {}) do
		for _, card in ipairs(s.list) do
			out[card.rarity] = out[card.rarity] + self:Spare(card, finish, keep)
		end
	end
	return out
end

-- The copies of a card that can go into contracts, every finish together (nothing for the legendary and mythic cards
-- since 1.13.0, after its second test: a contract gives a legendary card at most); and the finish with the most of them.
function K:SpareAll(card, keep)
	if not self:Takes(card.rarity) then
		return 0
	end
	local n, best, most = 0, "normal", 0
	for _, finish in ipairs(self.FINISHES) do
		local k = self:Spare(card, finish, keep)
		n = n + k
		if k > most then
			best, most = finish, k
		end
	end
	return n, best
end

-- The copies to spare of an album (all of them: nil), every rarity that can be exchanged.
function K:SpareIn(s, keep)
	local n = 0
	for _, x in ipairs(s and { s } or ns.Series or {}) do
		for _, card in ipairs(x.list) do
			n = n + self:SpareAll(card, keep)
		end
	end
	return n
end

-------------------------------------------------------------------------------
-- A contract being written (or several of them at once: n)
-------------------------------------------------------------------------------
function K:New(rarity, finish, n)
	return { rarity = rarity or 1, finish = finish or "normal", n = math.max(1, math.min(self:Max(), n or 1)), picks = {}, list = {}, count = 0,
		ids = {} }
end

-- (1.13.0) The copies of a card in a contract (Copies.lua: their numbers), those the player chose or the least
-- precious free ones, one for each of its places.
function K:Ids(ct, key)
	ct.ids = ct.ids or {}
	ct.ids[key] = ct.ids[key] or {}
	return ct.ids[key]
end

-- The copy that goes into the contract next: the one given (id), else the least precious free one not in it yet.
local function NextCopy(ct, card, id)
	local CP = ns.Copies
	if not CP then
		return nil
	end
	local used = {}
	for _, x in ipairs(K:Ids(ct, card.key)) do
		used[x] = true
	end
	for _, r in ipairs(CP:Free(card.key, ct.finish)) do
		if not used[r.i] and (id == nil or r.i == id) then
			return r.i
		end
	end
	return nil
end

-- The copies it takes: ten for each contract (1.6.0: fewer with some talents).
function K:Capacity(ct)
	return self:Size(ct) * (ct.n or 1)
end

-- How many contracts the copies to spare of its rarity and finish make (one at least, five at most;
-- 1.6.0: up to ten with the talent Batches).
function K:MaxCount(ct, keep, series)
	if self:Single(ct) then
		return 1
	end
	local n = 0
	for _, it in ipairs(self:Eligible(ct.rarity, ct.finish, keep, series)) do
		n = n + it.spare
	end
	return math.max(1, math.min(self:Max(), math.floor(n / self:Size(ct))))
end

-- Another number of contracts: the copies past what they take go back, the last ones first.
function K:SetCount(ct, n)
	ct.n = math.max(1, math.min(self:Single(ct) and 1 or self:Max(), n or 1))
	while ct.count > self:Capacity(ct) do
		self:TakeAt(ct, ct.count)
	end
end

-- One more copy of a card into the contract. False when it is full or the card has none to spare. (1.13.0) id: the
-- copy chosen (nil: the least precious free one).
function K:Put(ct, card, keep, id)
	if ct.count >= self:Capacity(ct) or card.rarity ~= ct.rarity then
		return false
	end
	local used = ct.picks[card.key] or 0
	if used >= self:Spare(card, ct.finish, keep) then
		return false
	end
	local ci = NextCopy(ct, card, id)
	if id ~= nil and not ci then
		return false
	end
	ct.picks[card.key] = used + 1
	ct.list[CuratorOctoFull.Length(ct.list) + 1] = card.key
	ct.count = ct.count + 1
	if ci then
		local ids = self:Ids(ct, card.key)
		ids[CuratorOctoFull.Length(ids) + 1] = ci
	end
	return true
end

-- Takes back the copy at a place of the contract (or the last copy of a card given). (1.13.0) id: that copy of it
-- (nil: the last one put in).
function K:TakeAt(ct, i, id)
	local key = ct.list[i]
	if not key then
		return false
	end
	CuratorOctoFull.Remove(ct.list, i)
	ct.picks[key] = (ct.picks[key] or 1) - 1
	if ct.picks[key] <= 0 then
		ct.picks[key] = nil
	end
	ct.count = ct.count - 1
	local ids = ct.ids and ct.ids[key]
	if type(ids) == "table" then
		local at = CuratorOctoFull.Length(ids)
		for j, x in ipairs(ids) do
			if x == id then
				at = j
			end
		end
		CuratorOctoFull.Remove(ids, at)
		if CuratorOctoFull.Length(ids) == 0 or not ct.picks[key] then
			ct.ids[key] = nil
		end
	end
	return true
end

-- (1.13.0) One copy of a card in the contract for another of its copies (id: the one going out, to: the one coming
-- in). True when it was.
function K:Swap(ct, card, id, to)
	local ids = card and ct.ids and ct.ids[card.key]
	if type(ids) ~= "table" then
		return false
	end
	local at
	for j, x in ipairs(ids) do
		if x == id then
			at = j
		end
		if x == to then
			return false
		end
	end
	if not at or not NextCopy(ct, card, to) then
		return false
	end
	ids[at] = to
	return true
end

function K:Take(ct, card)
	for i = CuratorOctoFull.Length(ct.list), 1, -1 do
		if ct.list[i] == card.key then
			return self:TakeAt(ct, i)
		end
	end
	return false
end

-- Copies past what is left to spare go back (after a contract was signed, or the keep option changed). (1.13.0: a copy
-- chosen no longer free, traded or sold meanwhile: the least precious free ones in its place.)
function K:Check(ct, keep)
	for i = CuratorOctoFull.Length(ct.list), 1, -1 do
		local key = ct.list[i]
		if (ct.picks[key] or 0) > self:Spare(ns.Cards[key], ct.finish, keep) then
			self:TakeAt(ct, i)
		end
	end
	local CP = ns.Copies
	for key, n in pairs(CP and ct.picks or {}) do
		local ids = ct.ids and ct.ids[key]
		if type(ids) == "table" and (CuratorOctoFull.Length(ids) ~= n or not CP:Chosen(key, ct.finish, ids, n)) then
			ct.ids[key] = nil
			local card = ns.Cards[key]
			for _ = 1, n do
				local ci = card and NextCopy(ct, card)
				if ci then
					local list = self:Ids(ct, key)
					list[CuratorOctoFull.Length(list) + 1] = ci
				end
			end
		end
	end
end

-- Fills the empty places with the cards that have the most copies to spare (of one album, or of all).
function K:Fill(ct, keep, series)
	local list = self:Eligible(ct.rarity, ct.finish, keep, series)
	for i, it in ipairs(list) do
		it.i = i
	end
	table.sort(list, function(a, b)
		if a.spare ~= b.spare then
			return a.spare > b.spare
		end
		return a.i < b.i
	end)
	local cap = self:Capacity(ct)
	for _, it in ipairs(list) do
		while ct.count < cap and self:Put(ct, it.card, keep) do
		end
		if ct.count >= cap then
			break
		end
	end
end

-- Every copy to spare of a card into the contract, as many as it still takes. How many went in.
function K:PutAll(ct, card, keep)
	local n = 0
	while self:Put(ct, card, keep) do
		n = n + 1
	end
	return n
end

-- The cards in the contract, each once, with how many of their copies: { card, n }, in the order
-- they were put in.
function K:Groups(ct)
	local out, at = {}, {}
	for _, key in ipairs(ct.list) do
		local g = at[key]
		if not g then
			g = { card = ns.Cards[key], n = 0 }
			at[key] = g
			out[CuratorOctoFull.Length(out) + 1] = g
		end
		g.n = g.n + 1
	end
	return out
end

-- Where the new card can come from: { { series, share } }, the likeliest first.
function K:Odds(ct)
	local by, out = {}, {}
	for key, n in pairs(ct.picks) do
		local s = ns.Cards[key].series
		by[s] = (by[s] or 0) + n
	end
	for s, n in pairs(by) do
		out[CuratorOctoFull.Length(out) + 1] = { series = s, share = n / math.max(1, ct.count) }
	end
	table.sort(out, function(a, b)
		if a.share ~= b.share then
			return a.share > b.share
		end
		return (a.series.order or 0) < (b.series.order or 0)
	end)
	return out
end

-------------------------------------------------------------------------------
-- (1.13.0, after its second test) The clause of the collection: every copy given from one album, the new card is one
-- that album is missing in the rarity it gives (several contracts at once: as many different ones as it misses).
-------------------------------------------------------------------------------
-- The album of every copy of a contract (nil: several, or none yet).
function K:Album(ct)
	local s
	for key in pairs(ct.picks or {}) do
		local card = ns.Cards[key]
		local x = card and card.series
		if s and x ~= s then
			return nil
		end
		s = x
	end
	return s
end

-- The cards of an album the collection does not have, of a rarity.
function K:MissingOf(s, rarity)
	local out = {}
	for _, c in ipairs(s and s.byRarity and s.byRarity[rarity] or {}) do
		if not C:Owned(c) then
			out[CuratorOctoFull.Length(out) + 1] = c
		end
	end
	return out
end

-- The rarity a contract gives (two more with the Masterstroke armed, a contract of commons, uncommons or rares).
function K:Up(ct)
	return math.min(self.TOP, ct.rarity + ((ct.master and ct.rarity <= 3) and 2 or 1))
end

-- The clause of a contract: its one album and the cards of the rarity it gives that album is missing (nil: copies of
-- several albums, or none yet; the list empty: the album has them all).
function K:Clause(ct)
	if (ct.count or 0) <= 0 then
		return nil
	end
	local s = self:Album(ct)
	if not s then
		return nil
	end
	return s, self:MissingOf(s, self:Up(ct))
end

-- The album the clause would best be made with (all of them, not one chosen): the one with the most copies to spare in
-- this rarity and finish among those missing cards of the rarity above, enough for a contract. s, its copies to spare,
-- the cards it misses (nil: none).
function K:ClauseAlbum(rarity, finish, keep)
	local best, bestN, bestMiss
	local size = self:SizeOf(rarity, finish)
	for _, s in ipairs(ns.Series or {}) do
		if not s.limited then
			local n = 0
			for _, card in ipairs(s.byRarity[rarity] or {}) do
				n = n + self:Spare(card, finish, keep)
			end
			if n >= size then
				local miss = CuratorOctoFull.Length(self:MissingOf(s, math.min(self.TOP, rarity + 1)))
				if miss > 0 and (not best or n > bestN) then
					best, bestN, bestMiss = s, n, miss
				end
			end
		end
	end
	return best, bestN, bestMiss
end

-------------------------------------------------------------------------------
-- (1.13.0, after its second test) The register: the last contracts signed, the latest last ({ t = when, r = the rarity
-- of the copies given, u = the rarity of the cards they gave, s = the copies of each contract, n = the contracts,
-- f = the finish, c = { { k = the card, nw = new, cl = by the clause }, ... } })
-------------------------------------------------------------------------------
function K:Log(result)
	local db = ns.db
	if not (db and result) then
		return
	end
	if type(db.kLog) ~= "table" then
		db.kLog = {}
	end
	local cards = {}
	for i, x in ipairs(result.cards or {}) do
		if i <= 12 and x.card then
			cards[CuratorOctoFull.Length(cards) + 1] = { k = x.card.key, nw = x.new and true or nil, cl = x.clause and true or nil }
		end
	end
	db.kLog[CuratorOctoFull.Length(db.kLog) + 1] = { t = CuratorOctoFull.ServerTime(), r = result.rarity, u = result.up, s = result.size, n = result.n, f = result.finish,
		c = cards }
	while CuratorOctoFull.Length(db.kLog) > self.LOG_MAX do
		CuratorOctoFull.Remove(db.kLog, 1)
	end
end

function K:Register()
	local db = ns.db
	return db and type(db.kLog) == "table" and db.kLog or {}
end

-- (1.6.0, Expert's Eye) A card of that rarity the album is missing: of the album of the card drawn, else
-- of another album of the contract (nil: none is missing).
local function Missing(odds, up, card)
	local list = { card and card.series }
	for _, o in ipairs(odds) do
		list[CuratorOctoFull.Length(list) + 1] = o.series
	end
	for _, s in ipairs(list) do
		local out = {}
		for _, c in ipairs(s.byRarity[up] or {}) do
			if not C:Owned(c) then
				out[CuratorOctoFull.Length(out) + 1] = c
			end
		end
		if CuratorOctoFull.Length(out) > 0 then
			return out[math.random(CuratorOctoFull.Length(out))]
		end
	end
end

-- The album a new card comes from: drawn by the odds (an album without cards of that rarity gives
-- way to another one of the contract), then the card among its cards of that rarity.
local function Draw(odds, up)
	local r, s = math.random(), nil
	for _, o in ipairs(odds) do
		if r < o.share then
			s = o.series
			break
		end
		r = r - o.share
	end
	s = s or odds[CuratorOctoFull.Length(odds)].series
	if CuratorOctoFull.Length(s.byRarity[up]) == 0 then
		-- (every album has cards of each rarity) another album of the contract
		for _, o in ipairs(odds) do
			if CuratorOctoFull.Length(o.series.byRarity[up]) > 0 then
				s = o.series
				break
			end
		end
	end
	local pool = s.byRarity[up]
	if CuratorOctoFull.Length(pool) == 0 then
		return nil
	end
	return pool[math.random(CuratorOctoFull.Length(pool))]
end

-- Signs a full contract (or all of them): the copies are given, the new cards drawn and added to the
-- collection. Returns { cards = { { card, finish, new, count }, ... }, card, finish, new, count (those
-- of the first), n, odds, given = { cardKey, ... }, rarity }, or nil and why.
function K:Sign(ct, keep)
	if ct.count ~= self:Capacity(ct) then
		return nil, "incomplete"
	end
	-- (1.14.0, after its test, his word: a reroll signs none, Reroll.lua: RR:Blocks)
	if ns.Reroll and ns.Reroll:Blocks("contracts") then
		return nil, "reroll"
	end
	-- (1.14.0: the cards changed by another addon this session: nothing signed, nothing taken; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil, "guard"
	end
	-- (1.13.0, after its second test: a legendary card at most, a mythic card is earned)
	if not self:Takes(ct.rarity) then
		return nil, "rarity"
	end
	for key, n in pairs(ct.picks) do
		-- (1.14.0: a card of the rarity of the contract, as K:Put takes them, whatever changed the contract since)
		local card = ns.Cards[key]
		if not card or card.rarity ~= ct.rarity or n > self:Spare(card, ct.finish, keep) then
			return nil, "missing"
		end
		-- (1.13.0: the copies chosen, each one still there and free to leave)
		local ids = ct.ids and ct.ids[key]
		if ns.Copies and type(ids) == "table" and CuratorOctoFull.Length(ids) > 0 and not ns.Copies:Chosen(key, ct.finish, ids, n) then
			return nil, "missing"
		end
	end
	-- (1.6.0) the talents of the Merchant: those of the next contract (each one still ready), those that
	-- come now and then (1.14.0: the trees of before gone, the Smuggler's: Paperwork, Forger, Golden Contract)
	local TL = ns.Talents
	local merchant = false
	local smuggler = TL ~= nil and TL:Spec() == "smuggler"
	local favor = Favor(ct)
	local size = self:Size(ct)
	local master = merchant and ct.master and ct.rarity <= 3 and TL:Ready("masterstroke") or false
	local tailor = merchant and ct.tailor and TL:Ready("tailor") and ns.SeriesByKey(ct.tailor) or nil
	local alchemist = merchant and ct.alchemist and ct.finish == "shiny" and TL:Ready("alchemist") or false
	local up = math.min(self.TOP, ct.rarity + (master and 2 or 1))
	local odds = self:Odds(ct)
	-- (the Tailor-Made Contract: the album chosen, one of those of the contract)
	local from = odds
	-- (1.12.0: never the album of an event, a limited edition: its cards would come from the others; 1.13.0: nor the
	-- Hardcup Saison 3)
	if tailor and (tailor.event or tailor.limited) then
		tailor = nil
	end
	if tailor then
		for _, o in ipairs(odds) do
			if o.series == tailor and CuratorOctoFull.Length(tailor.byRarity[up]) > 0 then
				from = { { series = tailor, share = 1 } }
			end
		end
		if from == odds then
			tailor = nil
		end
	end
	local n = ct.n or 1
	-- (1.13.0, after its second test: the clause of the collection, every copy from one album: cards it is missing,
	-- each one once, then drawn as the others)
	local one = self:Album(ct)
	if one and tailor and tailor ~= one then
		one = nil
	end
	local missing = one and self:MissingOf(one, up) or nil
	local drawn, byClause = {}, {}
	for i = 1, n do
		if missing and CuratorOctoFull.Length(missing) > 0 then
			drawn[i] = CuratorOctoFull.Remove(missing, math.random(CuratorOctoFull.Length(missing)))
			byClause[i] = true
		else
			drawn[i] = Draw(from, up)
		end
		if not drawn[i] then
			return nil, "empty"
		end
	end
	if merchant then
		-- (Expert's Eye: a card the album is missing; those of the clause are already)
		if TL:Has("expert") then
			for i = 1, n do
				if not byClause[i] and math.random() < TL:V("expert") then
					drawn[i] = Missing(from, up, drawn[i]) or drawn[i]
				end
			end
		end
		-- (High Volume: five contracts or more at once, a card more now and then)
		if n >= 5 and TL:Has("volume") then
			local extras = 0
			for _ = 1, n do
				if extras < TL.VOLUME_MAX and math.random() < TL:V("volume") then
					extras = extras + 1
					drawn[CuratorOctoFull.Length(drawn) + 1] = Draw(from, up)
				end
			end
		end
	end
	-- (1.14.0, Paperwork: one of the cards of a contract comes back now and then)
	local back = {}
	if smuggler and TL:Has("paperwork") then
		for j = 1, n do
			if math.random() < TL:V("paperwork") then
				local k = (j - 1) * size + math.random(size)
				if ct.list[k] then
					back[CuratorOctoFull.Length(back) + 1] = ct.list[k]
				end
			end
		end
	end
	-- (Haggling, of before 1.14.0: half of the cards of a contract came back now and then)
	if merchant and TL:Has("haggle") then
		for j = 1, n do
			if math.random() < TL:V("haggle") then
				local slice = {}
				for k = (j - 1) * size + 1, j * size do
					slice[CuratorOctoFull.Length(slice) + 1] = ct.list[k]
				end
				for k = CuratorOctoFull.Length(slice), 2, -1 do
					local x = math.random(k)
					slice[k], slice[x] = slice[x], slice[k]
				end
				for k = 1, math.floor(CuratorOctoFull.Length(slice) / 2) do
					back[CuratorOctoFull.Length(back) + 1] = slice[k]
				end
			end
		end
	end
	local db = ns.db
	-- (1.13.0: the copies given, those chosen; those the Haggling gives back, the same ones, the finest first)
	local CP = ns.Copies
	local gave = {}
	for key, k in pairs(ct.picks) do
		local e = db.cards[key]
		if CP then
			gave[key] = CP:Take(key, ct.finish, k, ct.ids and ct.ids[key])
			table.sort(gave[key], function(a, b)
				return CP.LeastFirst(b, a)
			end)
		end
		e.n = e.n - k
		if ct.finish == "shiny" then
			e.s = (e.s or 0) - k
		elseif ct.finish == "holo" then
			e.h = (e.h or 0) - k
		end
		-- (a card given away entirely is no longer a new one)
		if e.n <= 0 and db.fresh then
			db.fresh[key] = nil
		end
	end
	for _, key in ipairs(back) do
		local e = db.cards[key]
		local r = CP and gave[key] and CuratorOctoFull.Remove(gave[key], 1)
		if r then
			CP:Put(key, { r })
		end
		e.n = e.n + 1
		if ct.finish == "shiny" then
			e.s = (e.s or 0) + 1
		elseif ct.finish == "holo" then
			e.h = (e.h or 0) + 1
		end
		if CP then
			CP:Reconcile(key)
		end
	end
	-- (31 October, his word: the contracts redone) What comes is in the condition of what was given: their wear
	-- averaged (Wear.lua), each mark of theirs; every copy given appraised (in its case or not), it comes appraised too,
	-- its grade and its marks told, a certificate of its own (a contract of experts: no appraisal to pay).
	-- (the review of the night: a copy restored since its appraisal tells no more what it is, its true grade hidden until
	-- it is appraised again: no clause of the experts with it; with the clause, what comes is the average of what their
	-- appraisals told, never of a grade still hidden)
	local given, told = {}, {}
	local certified = true
	local E = ns.Expertise
	for _, list in pairs(gave) do
		for _, r in ipairs(list) do
			given[CuratorOctoFull.Length(given) + 1] = r
			local g = CP and CP.Grade(r)
			local hg = tonumber(r.hg)
			local m = g and E and E.DecodeMarks and E.DecodeMarks(r.m)
			if not (g and m) or (hg and (hg ~= g or (r.hm and r.hm ~= r.m))) then
				certified = false
			else
				told[CuratorOctoFull.Length(told) + 1] = { g = g, m = r.m }
			end
		end
	end
	local W = ns.Wear
	local avgG, avgM
	if W and W.Average then
		avgG, avgM = W.Average((certified and CuratorOctoFull.Length(told) == CuratorOctoFull.Length(given)) and told or given)
	end
	certified = certified and CuratorOctoFull.Length(given) > 0 and avgG ~= nil
	-- (31 October, Fine Print, a talent of the Smuggler: its worst mark a step better now and then, its grade with it)
	local fine = false
	if avgM and TL and TL.FinePrint and TL:FinePrint() then
		local lo = 1
		for k = 2, 4 do
			if avgM[k] < avgM[lo] then
				lo = k
			end
		end
		if avgM[lo] < 10 then
			avgM[lo] = avgM[lo] + 1
			fine = true
			avgG = math.max(1, math.min(10, math.floor((avgM[1] + avgM[2] + avgM[3] + avgM[4]) / 4 + 0.5)))
			if avgG >= 10 and not (avgM[1] == 10 and avgM[2] == 10 and avgM[3] == 10 and avgM[4] == 10) then
				avgG = 9
			end
		end
	end
	local finish = ct.finish ~= "normal" and ct.finish or nil
	local cards = {}
	-- (1.14.0, Golden Contract: once a week, a contract of rare cards gives an epic thunderforged card)
	local golden = smuggler and not finish and ct.rarity == 3 and TL:Ready("goldcontract") or false
	for i, card in ipairs(drawn) do
		local f = finish
		if smuggler then
			if golden and i == 1 and not f then
				f = "shiny"
			elseif f == "shiny" and TL:Has("forger") and math.random() < TL:V("forger") then
				f = "holo"
			end
		end
		if merchant then
			if not f and up >= 3 then
				-- (Storm Seal; Consolation Prize: a card already there)
				if TL:Has("stormseal") and math.random() < TL:V("stormseal") then
					f = "shiny"
				elseif TL:Has("consolation") and C:Owned(card) and math.random() < TL:V("consolation") then
					f = "shiny"
				end
			elseif f == "shiny" then
				-- (the Alchemist: the first card; Seal Master)
				if alchemist and i == 1 then
					f = "holo"
				elseif TL:Has("sealmaster") and math.random() < TL:V("sealmaster") then
					f = "holo"
				end
			end
		end
		local new, e = C:Add(card, f)
		local ci = CP and CP.last and CP.last.i or nil
		-- (1.14.0: a titanforged card, the pattern of its copy)
		local pt = CP and CP.Pattern(CP.last) or nil
		-- (31 October: in the condition of what was given; appraised when all of it was)
		local wear
		local last = CP and CP.last
		if last and avgG and W then
			if not tonumber(last.wv) then
				W.Fresh(last)
			end
			W.Store(last, avgG, avgM)
			if certified then
				local E = ns.Expertise
				-- (1 November, the twenty levels: its grade the mean of its marks, to its tenth)
				local gx = (W.Exact and W.Exact(avgM)) or avgG
				last.g, last.hg, last.m, last.at, last.sl = math.floor(gx * 100 + 0.5), nil, E.EncodeMarks(avgM), GetServerTime and CuratorOctoFull.ServerTime() or time(), true
				last.ce = E.CertFor and E.CertFor(card) or nil
				-- (1 November: a titanforged card is appraised only with its certificate of the mages, Mages.lua: a
				-- contract of experts writes it too, as it writes its appraisal)
				if CP.Pattern(last) and not (ns.Mages and ns.Mages.Of(last)) then
					last.tc = { t = last.at, m = 0 }
				end
				if ns.GradeTold then
					ns.GradeTold(avgG)
				end
			end
			wear = W.Of(last)
		end
		C:Remember(card, f, "k")
		cards[i] = { card = card, finish = f, new = new, count = e.n, extra = i > n or nil, ci = ci, pt = pt, clause = byClause[i], wear = wear,
			certified = (certified and last ~= nil) or nil }
		SIGNED[cards[i]] = { card = card, finish = f, ci = ci, clause = byClause[i] }
	end
	db.contracts = (db.contracts or 0) + n
	local st = ns.Stats()
	if up == ns.MYTHIC then
		st.kMyth = true
	end
	-- (1.13.0, after its second test: a legendary card from a contract, the cards of the clause)
	if up == self.TOP then
		st.kLeg = true
	end
	local hits = 0
	for _ in pairs(byClause) do
		hits = hits + 1
	end
	if hits > 0 then
		st.kClause = (tonumber(st.kClause) or 0) + hits
	end
	if ct.finish == "holo" then
		st.kHolo = true
	end
	if golden then
		TL:Use("goldcontract")
	end
	if favor then
		TL:Use("favor")
	end
	if tailor then
		TL:Use("tailor")
	end
	if alchemist then
		TL:Use("alchemist")
	end
	if master then
		TL:Use("masterstroke")
		st.tMaster = true
	end
	ct.favor, ct.master, ct.tailor, ct.alchemist = nil, nil, nil, nil
	local given = {}
	for i, key in ipairs(ct.list) do
		given[i] = key
	end
	local first = cards[1]
	local result = { cards = cards, card = first.card, finish = finish, new = first.new, count = first.count, n = n, odds = odds,
		given = given, rarity = ct.rarity, up = up, size = size, back = CuratorOctoFull.Length(back) > 0 and back or nil, master = master or nil, tailor = tailor,
		alchemist = alchemist or nil, favor = favor or nil, clause = hits > 0 and one or nil, clauseN = hits, golden = golden or nil,
		avgG = avgG, avgM = avgM, certified = certified or nil, fine = fine or nil }
	self:Log(result)
	if TL then
		TL:Signed(n)
	end
	ns.Fire("CHANGED")
	ns.Fire("CONTRACT_SIGNED", result)
	if master then
		ns.Fire("TALENT_PROC", "masterstroke")
	end
	return result
end

-- (1.6.0, Second Chance) A card of a contract just signed drawn again: its copy goes, another card of
-- its rarity comes, from the albums of the contract, with its finish. The new card (nil: it cannot).
-- (1.14.0: the card as the contract gave it, SIGNED: the ceremony shows it on its cards, which another addon reaches)
function K:Redraw(result, i)
	local TL = ns.Talents
	local shown = result and result.cards and result.cards[i]
	local r = shown and SIGNED[shown]
	if not (r and TL and TL:Ready("second")) then
		return nil
	end
	-- (1.14.0: the cards changed by another addon this session: nothing drawn again; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll(true) then
		return nil
	end
	local db = ns.db
	local e = db.cards[r.card.key]
	-- (its copy, in its finish, must still be there: traded or put in a contract meanwhile, nothing is drawn)
	if K.Copies(e, r.finish) <= 0 then
		return nil
	end
	-- (a contract made to measure: from the album chosen)
	local odds = result.tailor and { { series = result.tailor, share = 1 } } or result.odds
	local card
	-- (1.13.0, after its second test: a card of the clause, another card its album is missing, when there is one)
	if r.clause and result.clause then
		local miss = {}
		for _, c in ipairs(self:MissingOf(result.clause, r.card.rarity)) do
			if c ~= r.card then
				miss[CuratorOctoFull.Length(miss) + 1] = c
			end
		end
		card = CuratorOctoFull.Length(miss) > 0 and miss[math.random(CuratorOctoFull.Length(miss))] or nil
	end
	card = card or Draw(odds, r.card.rarity)
	if not card then
		return nil
	end
	-- (1.13.0: its copy goes, the one that came with the contract)
	local CP = ns.Copies
	if CP then
		CP:Take(r.card.key, r.finish, 1, r.ci and { r.ci } or nil)
	end
	e.n = e.n - 1
	if r.finish == "shiny" then
		e.s = math.max(0, (e.s or 0) - 1)
	elseif r.finish == "holo" then
		e.h = math.max(0, (e.h or 0) - 1)
	end
	if e.n <= 0 and db.fresh then
		db.fresh[r.card.key] = nil
	end
	-- (1.7.0: the card drawn again takes the place of the old one in the journal)
	C:Unlog(r.card, r.finish, "k")
	local new, e2 = C:Add(card, r.finish)
	local ci = CP and CP.last and CP.last.i or nil
	local pt = CP and CP.Pattern(CP.last) or nil
	-- (31 October: the card drawn again in the condition of what was given, as the one it replaces)
	local W, wear = ns.Wear, nil
	local lastC = CP and CP.last
	if lastC and W and result.avgG then
		W.Store(lastC, result.avgG, result.avgM)
		if result.certified then
			local E = ns.Expertise
			lastC.g, lastC.m, lastC.at, lastC.sl = result.avgG * 100, E.EncodeMarks(result.avgM), GetServerTime and CuratorOctoFull.ServerTime() or time(), true
			lastC.ce = E.CertFor and E.CertFor(card) or nil
		end
		wear = W.Of(lastC)
	end
	C:Remember(card, r.finish, "k")
	TL:Use("second")
	local nr = { card = card, finish = r.finish, new = new, count = e2.n, redrawn = true, ci = ci, pt = pt, clause = r.clause, wear = wear,
		certified = result.certified }
	result.cards[i] = nr
	SIGNED[shown] = nil
	SIGNED[nr] = { card = card, finish = r.finish, ci = ci, clause = r.clause }
	-- (the register: the card drawn again in the place of the old one)
	local log = self:Register()
	local last = log[CuratorOctoFull.Length(log)]
	if last and type(last.c) == "table" and last.c[i] and last.c[i].k == r.card.key then
		last.c[i] = { k = card.key, nw = new and true or nil, cl = r.clause and true or nil }
	end
	if i == 1 then
		result.card, result.new, result.count = card, new, e2.n
	end
	ns.Fire("CHANGED")
	return nr
end
