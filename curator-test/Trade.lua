local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- Trades between players, without any server. Anything goes for anything (cards with their finish,
-- boosters of an album), a gift too. One player proposes, the other accepts, refuses or changes the
-- offer (it comes back to the first one); the trade is made when the one who did not write the last
-- offer accepts it: what they give leaves their collection at once and waits with the trade (no other
-- trade, no contract can take it), the one who wrote it checks they still have what they give, makes
-- the trade on their side and says so, and the other side follows.
--
-- Each collection is the only judge of itself: nothing proves the other side has what it gives. The
-- seal of the save shows a collection edited outside the game: it cannot trade, nor a test collection.
-- The game writes the save only when it logs out or reloads: a game closed at the wrong moment comes
-- back as it was before the trade. So each trade is numbered and kept on both sides, and the two
-- collections compare it whenever they meet again (a message from that player, or a check now and
-- then): a trade the other side has lost is undone on this side too. Until the other side has it in
-- its save (it says so once it has reloaded or logged in again), what came from it waits: the cards
-- count in the album but cannot go into a contract or another trade, nor count for the achievements;
-- the boosters wait to be opened. After LOCK_DAYS days, they are free anyway. (1.5.0) The cards that
-- came in a trade wait QUARANTINE_DAYS days in any case, confirmed or not: a card lent to complete an
-- album, then given back, no longer pays.
--
-- Messages (whispers, or the Battle.net game data between friends: other factions and realms too):
--   T:1:P/<id>/<rev>/<uid>/<flags>/<gives>/<takes>   an offer (what its writer gives, what it takes)
--   T:1:A/<id>/<rev>/<uid>                           accepted (what the acceptor gives is put aside)
--   T:1:D/<id>/<rev>                                 done on the side of the writer of the offer
--   T:1:X/<id>/<rev>/<why>                           refused, withdrawn, or impossible
--   T:1:K/<uid>/<id>,<id>...                         where are these trades on your side?
--   T:1:Y/<uid>/<id>=<state>,...                     D done and saved, N done (not saved yet), W
--                                                    accepted (waiting), O open, M not there
--   T:1:V/<pass>/<signature>                         (1.14.0) my pass, before each offer, answer or duel of mine
--                                                    (Pass.lua: its lines separated by ~; 1.14.3: asked for no more)
--   N:1:*;<creature>,...                             the cards I look for ("*": a new list)
--   U:1:*;<creature>,...                             my cards to spare that someone of my guild looks for
--   E:1:<creature><finish>/<partner>/<gift>          a fine card came to me in a trade (the guild sees it)
-- Items: a card "<creature>[s|h|c]" (shiny or thunderforged, holographic or titanforged, 1.14.0: corrupted), boosters
-- "@<album>"; "*<n>" for several. flags: 1 a test collection, 2 a save edited outside the game, (1.8.0)
-- 4 the stake of a duel (Duel.lua: a gift of the one who lost, taken at once by the one who won).
-- (1.14.0, his word: the corrupted copies go in a trade too) Each corrupted copy given goes with its corruption, and its
-- seal when a Master of Warlocks sealed it (a reliquary): its "~<copy>" always (Copies.Pack), never fused with another.
-- (1.14.0, his idea) Each titanforged copy given goes with its pattern (Patterns.lua): its "~<copy>" always too.
-- (1.13.0) Each copy on its own (Copies.lua): the copies that leave are those their owner chose (ids, kept with the
-- trade), and those that have something to tell go with it, after their card: "~<copy>" for each (its expertise, its
-- restorations, where it came from first: Copies.Pack), on the side of the one who gives them (the offer for the copies
-- of its writer, the answer A for those of the one who accepts). What left is kept with the trade (cp), what came too
-- (got): a trade undone gives back the same copies, takes back those that came.
local T = { contactAt = {}, checkAt = {}, bnByName = {}, nameByBN = {}, offline = {}, whispered = {} }
ns.Trade = T

local C = ns.Collection
local K = ns.Contract
local G = ns.Guild

T.MAX_ITEMS = 8           -- different things on each side
T.MAX_COUNT = 99          -- copies of one card (or boosters of one album) on a line
T.MAX_LEN = 10000         -- the longest message (1.12.0: the wire cuts it in parts, Wire.lua; 1.13.0: 600 before, the copies
                          -- that have something to tell go with their card; 1 November: 1300 before, every copy its
                          -- wear with it, Wear.lua: W.Pack)
T.LOCK_DAYS = 3           -- what came in a trade is free after this many days anyway
T.QUARANTINE_DAYS = 7     -- (1.5.0) the cards that came in a trade wait this many days in any case
T.EXPIRE = 7 * 86400      -- an offer nobody answered goes away
T.KEEP = 100              -- trades kept in the history (besides those still to settle)
T.OPEN_MAX = 20           -- offers received at once
T.WISH_MAX = 60           -- cards looked for (1.6.0: more with the talent Address Book, T:WishMax)
T.WISH_CAP = 360          -- the cards another player looks for, kept at most
T.CHECK_EVERY = 120       -- seconds between two checks of a player's trades to settle (1.12.0: 300 before)
T.TICK = 60

-- The value of a card for the gauge of a trade: how rare the boosters make its rarity (1.2: an
-- uncommon three times rarer than a common, a rare ten times, an epic sixty), times 25 for a shiny or
-- thunderforged copy and 100 for a holographic or titanforged one (1.14.0: 10 for a corrupted one, one card of an
-- event in ten); a booster, what it holds on average.
T.VALUE = { 1, 3, 10, 60, 300, 1500 }
T.FINISH_X = { shiny = 25, holo = 100, corrupt = 10 }
-- (1.14.0) the finishes of the copies that go in a trade
T.FINISHES = { "normal", "shiny", "holo", "corrupt" }
T.EVEN = 0.15             -- this close to the middle, a trade is even

local VERSION = "1"
local FLAG_TEST, FLAG_EDITED, FLAG_DUEL = 1, 2, 4
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Now()
	return CuratorOctoFull.ServerTime()
end

local function Base36(n)
	n = math.floor(n)
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = math.floor(n / 36)
	until n == 0
	return s
end

-- "Name-Realm" for any name (the realm of mine when none is given).
local function Norm(name)
	if type(name) ~= "string" or name == "" or Secret(name) then
		return nil
	end
	return G:Full(name)
end
T.Norm = Norm

function T:Short(name)
	return name and G:Short(name) or "?"
end

-------------------------------------------------------------------------------
-- Items: a card ({ k = card key, f = "shiny" / "holo" / "corrupt" / nil, n = copies }) or boosters ({ b = album
-- key, n = how many })
-------------------------------------------------------------------------------
local function Same(a, b)
	return a.k == b.k and a.f == b.f and a.b == b.b
end
T.Same = Same

-- (1.13.0) A list of copies (their numbers, the payloads that go with them), as many as there are of both.
local function Join(a, b)
	if type(a) ~= "table" and type(b) ~= "table" then
		return nil
	end
	local out = {}
	for _, list in ipairs({ a or {}, b or {} }) do
		for _, v in ipairs(list) do
			out[CuratorOctoFull.Length(out) + 1] = v
		end
	end
	return CuratorOctoFull.Length(out) > 0 and out or nil
end

-- The same thing twice on a side makes one line (1.13.0: the copies chosen of both, what goes with them).
local function Merge(items)
	local out = {}
	for _, it in ipairs(items) do
		local found
		for _, o in ipairs(out) do
			if Same(o, it) then
				found = o
				break
			end
		end
		if found then
			found.n = found.n + (it.n or 1)
			found.ids, found.c = Join(found.ids, it.ids), Join(found.c, it.c)
		else
			out[CuratorOctoFull.Length(out) + 1] = { k = it.k, f = it.f, b = it.b, n = it.n or 1, ids = Join(it.ids), c = Join(it.c) }
		end
	end
	return out
end
T.Merge = Merge

local function Copy(items)
	local out = {}
	for i, it in ipairs(items or {}) do
		out[i] = { k = it.k, f = it.f, b = it.b, n = it.n, ids = Join(it.ids), c = Join(it.c) }
	end
	return out
end
T.Copy = Copy

-- full (1.13.0): with what goes with the copies that have something to tell (it.c).
local function Encode(items, full)
	local out = {}
	for _, it in ipairs(items) do
		local tok
		if it.b then
			tok = "@" .. it.b
		else
			local card = ns.Cards[it.k]
			tok = tostring(card and card.npc or 0) .. ((it.f == "shiny" and "s") or (it.f == "holo" and "h") or (it.f == "corrupt" and "c") or "")
		end
		if (it.n or 1) > 1 then
			tok = tok .. "*" .. it.n
		end
		if full and it.k and type(it.c) == "table" then
			for i, p in ipairs(it.c) do
				if i <= (it.n or 1) and type(p) == "string" and p ~= "" then
					tok = tok .. "~" .. p
				end
			end
		end
		out[CuratorOctoFull.Length(out) + 1] = tok
	end
	return table.concat(out, ",")
end
T.Encode = Encode

-- Back to items; nil for anything this version does not know (a card, an album, a count).
local function Decode(str)
	local items = {}
	if type(str) ~= "string" then
		return nil
	end
	if str == "" then
		return items
	end
	for tok in CuratorOctoFull.Gmatch((str .. ","), "([^,]*),") do
		local n = 1
		-- (1.13.0: what goes with the copies that have something to tell, after the card)
		local pays, read
		local head, rest = CuratorOctoFull.Match(tok, "^([^~]*)(~.*)$")
		if head then
			tok, pays, read = head, {}, {}
			for p in CuratorOctoFull.Gmatch(rest, "~([^~]*)") do
				local r = ns.Copies and ns.Copies.Unpack(p)
				if not r or CuratorOctoFull.Length(pays) >= T.MAX_COUNT then
					return nil
				end
				pays[CuratorOctoFull.Length(pays) + 1], read[CuratorOctoFull.Length(read) + 1] = p, r
			end
		end
		local body, cnt = CuratorOctoFull.Match(tok, "^(.-)%*(%d+)$")
		if body then
			tok, n = body, G.Count(cnt)
		end
		if not n or n < 1 or n > T.MAX_COUNT then
			return nil
		end
		local key = CuratorOctoFull.Match(tok, "^@(%w+)$")
		if key then
			local s = ns.SeriesByKey(key)
			-- (1.13.0: no booster of a limited edition of no booster, the Hardcup Saison 3)
			if not s or s.limited or pays then
				return nil
			end
			items[CuratorOctoFull.Length(items) + 1] = { b = s.key, n = n }
		else
			local npc, f = CuratorOctoFull.Match(tok, "^(%d+)([shc]?)$")
			local card = npc and ns.Cards["c" .. npc]
			if not card or (pays and CuratorOctoFull.Length(pays) > n) then
				return nil
			end
			-- (1.14.0: a corrupted copy, of an album of an event only; each one with its corruption when they come, the
			-- others never with one)
			if f == "c" and not (card.series and card.series.event) then
				return nil
			end
			-- (1.14.0: a pattern, only with a titanforged copy, Copies.lua)
			for _, r in ipairs(read or {}) do
				if (f == "c") ~= (r.cor ~= nil) or (r.pt ~= nil and f ~= "h") then
					return nil
				end
			end
			if f == "c" and pays and CuratorOctoFull.Length(pays) ~= n then
				return nil
			end
			items[CuratorOctoFull.Length(items) + 1] = { k = card.key, f = (f == "s" and "shiny") or (f == "h" and "holo") or (f == "c" and "corrupt") or nil, n = n, c = pays }
		end
	end
	items = Merge(items)
	if CuratorOctoFull.Length(items) > T.MAX_ITEMS then
		return nil
	end
	return items
end
T.Decode = Decode

-- (1.14.0) Every corrupted copy a side gives comes with its corruption (what the giver says of it: its "~<copy>").
local function Told(items)
	for _, it in ipairs(items or {}) do
		if it.f == "corrupt" and not (type(it.c) == "table" and CuratorOctoFull.Length(it.c) == (it.n or 1)) then
			return false
		end
	end
	return true
end
T.Told = Told

-- How many things a side holds (copies and boosters).
function T:Count(items)
	local n = 0
	for _, it in ipairs(items or {}) do
		n = n + (it.n or 1)
	end
	return n
end

-------------------------------------------------------------------------------
-- The value of a side, and the balance of a trade
-------------------------------------------------------------------------------
local packValue = {}

-- What a booster of an album holds on average, in the values of the cards.
function T:PackValue(s)
	local v = packValue[s.key]
	if v then
		return v
	end
	local V = self.VALUE
	-- (the odds as they are for everyone: the talents of one player do not change what a booster is worth)
	local o = C:Odds(s, true)
	local best = 0
	for r, p in pairs(o.rar) do
		best = best + p * V[r]
	end
	-- (each card drawn on its own, 1.2; a dungeon or a raid: its last boss now and then)
	local base = o.cards * best + (o.mythic or 0) * V[6]
	v = base * (1 + o.shiny * (self.FINISH_X.shiny - 1) + o.holo * (self.FINISH_X.holo - 1))
	packValue[s.key] = v
	return v
end

function T:ItemValue(it)
	if it.b then
		local s = ns.SeriesByKey(it.b)
		return s and self:PackValue(s) * it.n or 0
	end
	local card = ns.Cards[it.k]
	if not card then
		return 0
	end
	return self.VALUE[card.rarity] * (self.FINISH_X[it.f or ""] or 1) * it.n
end

function T:Value(items)
	local v = 0
	for _, it in ipairs(items or {}) do
		v = v + self:ItemValue(it)
	end
	return v
end

-- Where a trade leans: -1 (all given) to 1 (all received), and its word: "empty", "gift" (I give,
-- nothing comes back), "gifted" (I receive a gift), "even", "more" (I give more), "less" (I receive
-- more).
function T:Balance(give, take)
	local a, b = self:Value(give), self:Value(take)
	if a <= 0 and b <= 0 then
		return 0, "empty"
	elseif b <= 0 then
		return -1, "gift"
	elseif a <= 0 then
		return 1, "gifted"
	end
	local p = (b - a) / (a + b)
	if math.abs(p) <= self.EVEN then
		return p, "even"
	end
	return p, p < 0 and "more" or "less"
end

-------------------------------------------------------------------------------
-- The trades kept
-------------------------------------------------------------------------------
local function DB()
	return ns.db
end

function T:Get(id)
	local db = DB()
	return db and db.trades and db.trades[id]
end

local OPEN = { out = true, ["in"] = true, acc = true }
T.OPEN = OPEN

-- Done but not confirmed yet by the other side (within the days of the lock).
local function Unconfirmed(rec)
	return rec.st == "done" and not rec.ok and not rec.free
end
T.Unconfirmed = Unconfirmed

-- (1.5.0) Done within the days of the quarantine (the trades made by 1.5.0 and later).
local function Quarantined(rec, now)
	return rec.st == "done" and rec.q ~= nil and (now or Now()) < (rec.td or 0) + T.QUARANTINE_DAYS * 86400
end
T.Quarantined = Quarantined

-- The trades still to settle with the other side: done and not confirmed, accepted and waiting; (1.12.0) an
-- offer they got a while ago (a game closed before saving may have lost it: then it goes again).
local function ToSettle(rec)
	return Unconfirmed(rec) or rec.st == "acc" or (rec.st == "out" and rec.got ~= nil and Now() - rec.got > 60)
end

-- Every trade: those open first (the newest first), then the history (the newest first).
function T:List()
	local db = DB()
	local open, past = {}, {}
	for _, rec in pairs(db and db.trades or {}) do
		if OPEN[rec.st] then
			open[CuratorOctoFull.Length(open) + 1] = rec
		else
			past[CuratorOctoFull.Length(past) + 1] = rec
		end
	end
	table.sort(open, function(a, b)
		-- (an offer to answer comes first)
		local wa, wb = a.st == "in" and 1 or 0, b.st == "in" and 1 or 0
		if wa ~= wb then
			return wa > wb
		end
		return (a.u or 0) > (b.u or 0)
	end)
	table.sort(past, function(a, b)
		return (a.td or a.u or 0) > (b.td or b.u or 0)
	end)
	return open, past
end

-- The offers waiting for my answer.
function T:Waiting()
	local n = 0
	for _, rec in pairs(DB() and DB().trades or {}) do
		if rec.st == "in" then
			n = n + 1
		end
	end
	return n
end

-- The trades done, the players traded with.
function T:Done()
	local st = ns.db and ns.db.stats
	local partners = 0
	for _ in pairs(st and st.partners or {}) do
		partners = partners + 1
	end
	return (st and st.trades) or 0, partners
end

-- Something changed: the locks are counted again, the pages follow.
function T:Changed(rec)
	if rec then
		rec.u = Now()
		-- (what is on the screen now is no longer what is in the save)
		rec.dur = nil
	end
	self:CountLocks()
	ns.Fire("TRADES_CHANGED", rec)
end

-- The history keeps its last T.KEEP trades (those still to settle stay).
function T:Prune()
	local db = DB()
	local past = {}
	for id, rec in pairs(db.trades) do
		if not OPEN[rec.st] and not ToSettle(rec) then
			past[CuratorOctoFull.Length(past) + 1] = { id = id, t = rec.td or rec.u or 0 }
		end
	end
	if CuratorOctoFull.Length(past) <= self.KEEP then
		return
	end
	table.sort(past, function(a, b)
		return a.t > b.t
	end)
	for i = self.KEEP + 1, CuratorOctoFull.Length(past) do
		db.trades[past[i].id] = nil
	end
end

-------------------------------------------------------------------------------
-- What can be given: the copies of a card, less those waiting (from a trade not confirmed)
-------------------------------------------------------------------------------
-- The copies that came in trades not confirmed yet: [cardKey .. ":" .. finish] = n.
function T:CountLocks()
	local held, upto, soon = {}, {}, nil
	local now = Now()
	for _, rec in pairs(DB() and DB().trades or {}) do
		local unconfirmed, quarantined = Unconfirmed(rec), Quarantined(rec, now)
		if unconfirmed or quarantined then
			local ends = math.max(unconfirmed and (rec.td or now) + self.LOCK_DAYS * 86400 or 0,
				quarantined and (rec.td or now) + self.QUARANTINE_DAYS * 86400 or 0)
			if not soon or ends < soon then
				soon = ends
			end
			for _, it in ipairs(rec.take or {}) do
				if it.k then
					local key = it.k .. ":" .. (it.f or "normal")
					held[key] = (held[key] or 0) + it.n
					upto[it.k] = math.max(upto[it.k] or 0, ends)
				end
			end
		end
	end
	-- (1.14.0) the copies bought at the Bourse, in their quarantine (Market.lua), wait as those of a trade
	for _, q in ipairs(ns.Market and ns.Market.QuarantinedCopies and ns.Market:QuarantinedCopies() or {}) do
		local key = q.k .. ":" .. q.f
		held[key] = (held[key] or 0) + 1
		upto[q.k] = math.max(upto[q.k] or 0, q.u)
		if not soon or q.u < soon then
			soon = q.u
		end
	end
	self.held, self.heldUntil, self.lockEnds = held, upto, soon
end

-- (1.5.0) When every copy of a card that came in a trade is free (nil: none waits).
function T:HeldUntil(key)
	if not self.heldUntil then
		self:CountLocks()
	end
	return self.heldUntil[key]
end

-- The copies of cards that wait (every card, every finish).
function T:HeldCards()
	if not self.held then
		self:CountLocks()
	end
	local n = 0
	for _, v in pairs(self.held) do
		n = n + v
	end
	return n
end

-- Copies of a card (in a finish: "normal", "shiny", "holo", "corrupt") that came in trades not confirmed.
function T:Held(key, finish)
	if not self.held then
		self:CountLocks()
	end
	return self.held[key .. ":" .. (finish or "normal")] or 0
end

-- All of them, every finish.
function T:HeldAll(key)
	return self:Held(key, "normal") + self:Held(key, "shiny") + self:Held(key, "holo") + self:Held(key, "corrupt")
end

-- The copies of a card in a finish that can go in a trade (keep: one copy of each card stays, its
-- finest).
function T:Spare(card, finish, keep)
	local e = C:Entry(card)
	local fin = finish or "normal"
	local n = K.Copies(e, fin) - self:Held(card.key, fin)
	-- (1.8.0: the copies put on a duel wait for it)
	if ns.Duel then
		n = n - ns.Duel:Staked(card.key, fin)
	end
	-- (1.13.0: the copies at an enchanter wait for him: Restore.lua; 1.14.0, a player's word: the copy signed by its
	-- innkeeper goes too, the signature stays with the card)
	if ns.Copies then
		n = n - ns.Copies:AwayCount(card.key, fin ~= "normal" and fin or nil)
	end
	if keep and n > 0 and fin == (C:BestFinish(e) or "normal") then
		n = n - 1
	end
	return math.max(0, n)
end

-- Boosters of an album that came in trades not confirmed (they wait to be opened).
function T:HeldPacks(s)
	local h = ns.db and ns.db.held
	return (h and s and h[s.key]) or 0
end

function T:HeldTotal()
	local n = 0
	for _, v in pairs(ns.db and ns.db.held or {}) do
		n = n + v
	end
	return n
end

-- Can I give this item (n of it)? The copies or the boosters it lacks.
function T:Lacks(it)
	if it.b then
		local s = ns.SeriesByKey(it.b)
		return math.max(0, it.n - (s and ns.Packs(s) or 0))
	end
	local card = ns.Cards[it.k]
	if not card then
		return it.n
	end
	-- (1.13.0: the copies chosen, each one still there and free to leave)
	if ns.Copies and type(it.ids) == "table" and CuratorOctoFull.Length(it.ids) > 0 and not ns.Copies:Chosen(it.k, it.f, it.ids, it.n) then
		return it.n
	end
	return math.max(0, it.n - self:Spare(card, it.f))
end

-- What a side lacks: { { item, missing } }.
function T:Missing(items)
	local out = {}
	for _, it in ipairs(items or {}) do
		local m = self:Lacks(it)
		if m > 0 then
			out[CuratorOctoFull.Length(out) + 1] = { item = it, n = m }
		end
	end
	return out
end

-------------------------------------------------------------------------------
-- Taking items out, putting them in
-------------------------------------------------------------------------------
local function Entry(key)
	local db = ns.db
	local e = db.cards[key]
	if not e then
		e = { n = 0, s = 0, t = Now() }
		db.cards[key] = e
	end
	return e
end

-- (1.13.0) The copies of an item that leave: those chosen (ids) first, then the least precious free ones; n of them.
local function Leaving(it, n)
	local CP = ns.Copies
	local out, seen = {}, {}
	for _, id in ipairs(type(it.ids) == "table" and it.ids or {}) do
		id = tonumber(id)
		if id and not seen[id] and CuratorOctoFull.Length(out) < n then
			seen[id] = true
			out[CuratorOctoFull.Length(out) + 1] = id
		end
	end
	if CP and CuratorOctoFull.Length(out) < n then
		for _, r in ipairs(CP:Free(it.k, it.f)) do
			if CuratorOctoFull.Length(out) >= n then
				break
			end
			if not seen[r.i] then
				seen[r.i] = true
				out[CuratorOctoFull.Length(out) + 1] = r.i
			end
		end
	end
	return out
end
T.Leaving = Leaving

local function Flat(t)
	local o = {}
	for k, v in pairs(t) do
		o[k] = v
	end
	return o
end

-- (1.14.0, his word: the corrupted copies go in a trade too) The corruption of the copies that left (their records,
-- gone; k of them) out of their card's, the seal of a reliquary with its copy (kept on its record, rec.seal, to come
-- back with it or to go with it: Copies.Pack): as a copy put on sale at the Bourse leaves (Market.lua, TakeOut).
local function CorruptOut(key, e, gone, k)
	local card = ns.Cards[key]
	local SL = ns.Masters
	local list = C:CorruptCopies(e)
	local seals = SL and SL:Seals(key) or {}
	local sealsGone, done = false, 0
	for _, r in ipairs(gone) do
		if type(r) == "table" and r.f == "c" and done < k then
			done = done + 1
			local x
			if r.ws then
				for i, s in ipairs(seals) do
					if s.i == r.i then
						x = CuratorOctoFull.Remove(seals, i)
						sealsGone = true
						break
					end
				end
			end
			if x then
				r.seal = Flat(x)
			else
				r.seal = nil
				-- (its corruption, else the nearest one)
				local v, at, d = C.Gauge(r.cor), nil, nil
				for i, c in ipairs(list) do
					local dd = math.abs(c - v)
					if not at or dd < d then
						at, d = i, dd
					end
				end
				if at then
					CuratorOctoFull.Remove(list, at)
				end
			end
		end
	end
	-- (copies without a record: the least corrupted)
	for _ = done + 1, k do
		if CuratorOctoFull.Length(list) > 0 then
			table.sort(list, function(a, b)
				return a > b
			end)
			CuratorOctoFull.Remove(list)
		end
	end
	if sealsGone then
		SL:Db()[key] = CuratorOctoFull.Length(seals) > 0 and seals or nil
	end
	C:SyncCorrupt(card, e)
end

-- (1.14.0) The corrupted copies back in (a trade undone, an answer that did not happen): their corruption, their seal
-- with them, as they left (CorruptOut). n of them.
local function CorruptIn(key, e, recs, n)
	local card = ns.Cards[key]
	local SL = ns.Masters
	local list = C:CorruptCopies(e)
	local seals = SL and SL:Seals(key) or {}
	local sealsBack, done = false, 0
	for _, r in ipairs(type(recs) == "table" and recs or {}) do
		if type(r) == "table" and r.f == "c" and done < n then
			done = done + 1
			if type(r.seal) == "table" and SL then
				local x = Flat(r.seal)
				x.i = r.i
				seals[CuratorOctoFull.Length(seals) + 1] = x
				sealsBack = true
			else
				list[CuratorOctoFull.Length(list) + 1] = C.Gauge(r.cor)
			end
			r.seal = nil
		end
	end
	for _ = done + 1, n do
		list[CuratorOctoFull.Length(list) + 1] = C.CORRUPT_MIN
	end
	if sealsBack then
		SL:Db()[key] = seals
	end
	C:SyncCorrupt(card, e)
end

-- Copies out of the collection (as many as there are, n at most): how many went, and (1.13.0) their records (the
-- copies of ids first: those that came, a trade undone; else those chosen, then the least precious).
local function TakeCopies(it, n, ids)
	local e = ns.db.cards[it.k]
	if not e then
		return 0, {}
	end
	local fin = it.f or "normal"
	local k = math.min(n, K.Copies(e, fin))
	if k <= 0 then
		return 0, {}
	end
	local gone = {}
	if ns.Copies then
		gone = ns.Copies:Take(it.k, it.f, k, ids or Leaving(it, k))
	end
	e.n = e.n - k
	if fin == "shiny" then
		e.s = (e.s or 0) - k
	elseif fin == "holo" then
		e.h = (e.h or 0) - k
	elseif fin == "corrupt" then
		CorruptOut(it.k, e, gone, k)
		if ns.Copies then
			ns.Copies:Reconcile(it.k)
		end
	end
	if e.n <= 0 and ns.db.fresh then
		ns.db.fresh[it.k] = nil
	end
	return k, gone
end

-- Copies back into the collection (no new card: they were there; 1.13.0: the same copies, recs).
local function PutBack(it, n, recs)
	if ns.Copies then
		ns.Copies:Put(it.k, recs)
	end
	local e = Entry(it.k)
	e.n = e.n + n
	if it.f == "shiny" then
		e.s = (e.s or 0) + n
	elseif it.f == "holo" then
		e.h = (e.h or 0) + n
	elseif it.f == "corrupt" then
		CorruptIn(it.k, e, recs, n)
	end
	if ns.Copies then
		ns.Copies:Reconcile(it.k)
	end
end

-- What I give leaves: the copies, the boosters (those of the trade: they must be there). (1.13.0: the copies that
-- went, kept with the trade, cp; what goes with them, c.)
local function Remove(it)
	if it.b then
		local db = ns.db
		db.packs[it.b] = math.max(0, (db.packs[it.b] or 0) - it.n)
	else
		local _, gone = TakeCopies(it, it.n)
		it.cp = CuratorOctoFull.Length(gone) > 0 and gone or nil
		local c = {}
		for _, r in ipairs(gone) do
			local p = ns.Copies.Pack(r)
			if p then
				c[CuratorOctoFull.Length(c) + 1] = p
			end
		end
		it.c = CuratorOctoFull.Length(c) > 0 and c or nil
	end
end

-- What I gave comes back (1.13.0: the same copies; 1.14.0: a line of the journal each, C:LogBack: rec, the trade).
local function Restore(it, rec)
	if it.b then
		local db = ns.db
		db.packs[it.b] = (db.packs[it.b] or 0) + it.n
	else
		PutBack(it, it.n, it.cp)
		it.cp = nil
		local card = ns.Cards[it.k]
		if card then
			for _ = 1, it.n do
				C:LogBack(card, it.f, rec and T:Short(rec.with) or nil)
			end
		end
	end
end

-- What comes in a trade: the cards in the album (new ones are new), the fine ones among the finest
-- pulls (how: a trade, with whom); the boosters wait until the trade is confirmed. (1.13.0: the copies that have
-- something to tell, with it (it.c); each copy that came, kept with the trade: got.)
local function Receive(it, rec)
	if it.b then
		local db = ns.db
		db.held = db.held or {}
		db.held[it.b] = (db.held[it.b] or 0) + it.n
		return
	end
	local card = ns.Cards[it.k]
	local CP = ns.Copies
	local got = {}
	-- (1.14.0: a corrupted copy, its corruption and its seal, those its giver told)
	local cors, seals = {}, {}
	if CP then
		local fk = CP.Key(it.f)
		for i, p in ipairs(type(it.c) == "table" and it.c or {}) do
			local r = i <= it.n and CP.Unpack(p)
			if r then
				r.f = fk
				if fk == "c" then
					cors[i], seals[i] = r.cor, r.seal
				end
				r.cor, r.seal = nil, nil
				CP:Expect(it.k, r)
			end
		end
		CP:SetContext({ w = "t", p = T:Short(rec.with), tr = rec.id })
	end
	for i = 1, it.n do
		if CP then
			CP.last = nil
		end
		C:Add(card, it.f, it.f == "corrupt" and (cors[i] or C.CORRUPT_MIN) or nil)
		local r = CP and CP.last
		if r then
			got[CuratorOctoFull.Length(got) + 1] = r.i
			-- (a reliquary: its seal with its copy, its corruption out of those not sealed: as at the Bourse, Market.lua)
			local x = seals[i]
			local SL = ns.Masters
			if x and SL and r.f == "c" then
				local e = C:Entry(card)
				local list = C:CorruptCopies(e)
				local v = C.Gauge(cors[i])
				for j, c in ipairs(list) do
					if c == v then
						CuratorOctoFull.Remove(list, j)
						break
					end
				end
				local all = SL:Seals(card.key)
				all[CuratorOctoFull.Length(all) + 1] = { g = x.g, s = x.s, c = x.c, k = v, t = x.t, by = x.by, i = r.i }
				SL:Db()[card.key] = all
				C:SyncCorrupt(card, e)
				CP:Reconcile(card.key)
			end
		end
	end
	if CP then
		CP:SetContext(nil)
		CP.expect[it.k] = nil
		it.got = CuratorOctoFull.Length(got) > 0 and got or nil
	end
	-- (1.7.0: the journal takes each copy that came, the finest pulls the card once)
	for _ = 2, it.n do
		C:Log(card, it.f, "t", T:Short(rec.with))
	end
	C:Remember(card, it.f, "t", T:Short(rec.with))
end

-- What came goes again (a trade undone): its copies, its boosters (still waiting, else opened ones are
-- gone); (1.7.0) their lines of the journal go too.
local function Unreceive(it, rec)
	if it.b then
		local db = ns.db
		db.held = db.held or {}
		local h = math.min(db.held[it.b] or 0, it.n)
		db.held[it.b] = (db.held[it.b] or 0) - h
		if db.held[it.b] <= 0 then
			db.held[it.b] = nil
		end
		local rest = it.n - h
		if rest > 0 then
			db.packs[it.b] = math.max(0, (db.packs[it.b] or 0) - rest)
		end
		return
	end
	-- (1.13.0: the copies that came, those of the trade)
	TakeCopies(it, it.n, it.got)
	it.got = nil
	local card = ns.Cards[it.k]
	if card and rec then
		for _ = 1, it.n do
			C:Unlog(card, it.f, "t", nil, T:Short(rec.with))
		end
	end
end

-- The boosters of a trade confirmed: they can be opened. (1.14.0: their album as it must be, Guard.lua, else they
-- stay held, it.wait, and come at a next check, T:Tick; again: only those that waited.)
local function Release(rec, again)
	local db = ns.db
	local GD = ns.Guard
	local released = false
	for _, it in ipairs(rec.take or {}) do
		if it.b and (not again or it.wait) then
			db.held = db.held or {}
			local h = math.min(db.held[it.b] or 0, it.n)
			local s = ns.SeriesByKey(it.b)
			if h > 0 and s and GD and not GD:Trading(GD.Allow, GD, s) then
				it.wait = true
			else
				it.wait = nil
				if h > 0 then
					released = true
					db.held[it.b] = db.held[it.b] - h
					if db.held[it.b] <= 0 then
						db.held[it.b] = nil
					end
					-- (1.14.0, his word: boosters of a trade never unlock their album, Level.lua: LV:Unlocked)
					if s and GD then
						GD:Trading(ns.AddPacks, s, h, true)
					elseif s then
						ns.AddPacks(s, h, true)
					end
				end
			end
		end
	end
	return released
end
T.Release = Release

-------------------------------------------------------------------------------
-- Who can trade
-------------------------------------------------------------------------------
function T:Flags()
	local db = ns.db
	return ((db and db.test) and FLAG_TEST or 0) + ((db and db.edited) and FLAG_EDITED or 0)
end

-- Can I trade at all? false and why: "test", "edited", "beta" (a beta build past its day), "guard". (1.14.3, his word:
-- the trades need the pass of the app no more, on either side: Pass.lua, the Exchange alone asks for it.)
function T:CanTrade()
	local db = ns.db
	if not db then
		return false, "test"
	end
	-- (an edited save, said as such before the lock it puts on Curator)
	if db.edited then
		return false, "edited"
	end
	if ns.Beta and ns.Beta:Over() then
		return false, "beta"
	end
	if db.test then
		return false, "test"
	end
	-- (1.14.0: the cards changed by another addon this session: no trade, no duel; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard"
	end
	return true
end

-- A player I know: of my guild, my friends (of the game, of Battle.net), or one I traded with.
function T:Known(name)
	if not name then
		return false
	end
	if ns.db.guild[name] or self.bnByName[name] then
		return true
	end
	if self.roster and self.roster[name] ~= nil then
		return true
	end
	if C_FriendList and C_FriendList.GetFriendInfo then
		local ok, info = pcall(C_FriendList.GetFriendInfo, G:Short(name))
		if ok and info and not Secret(info) then
			return true
		end
	end
	for _, rec in pairs(ns.db.trades) do
		if rec.with == name and rec.st == "done" then
			return true
		end
	end
	return false
end

local function Ignored(name)
	if C_FriendList and C_FriendList.IsOnIgnoredList then
		local ok, yes = pcall(C_FriendList.IsOnIgnoredList, G:Short(name))
		return ok and yes == true
	end
	return false
end

-- Online: true, false, or nil (not known: a player of no list of mine).
function T:Online(name)
	if not name then
		return nil
	end
	if self.bnByName[name] then
		return true
	end
	if self.roster and self.roster[name] ~= nil then
		return self.roster[name]
	end
	if C_FriendList and C_FriendList.GetFriendInfo then
		local ok, info = pcall(C_FriendList.GetFriendInfo, G:Short(name))
		if ok and type(info) == "table" and not Secret(info) and info.connected ~= nil then
			return info.connected and true or false
		end
	end
	if self.offline[name] and GetTime() - self.offline[name] < 120 then
		return false
	end
	return nil
end

-- Does this player's Curator trade (0.22 and later: their profile tells their number)? nil: not known.
function T:CanReach(name)
	local i = G:Profile(name)
	if not i then
		return nil
	end
	return i.uid ~= nil
end

-------------------------------------------------------------------------------
-- Sending
-------------------------------------------------------------------------------
-- (1.12.0) The offers, the answers, the trades made and refused go by the wire (Wire.lua): kept until the
-- other side has them, sent again until then, read once. The checks (K, Y) need no answer: they go once,
-- and come again with the next check.
local RELIABLE = { P = true, A = true, D = true, X = true, V = true }

function T:Send(name, body)
	self.whispered[name] = GetTime()
	local text = "T:" .. VERSION .. ":" .. body
	local Wr = ns.Wire
	if Wr then
		if RELIABLE[string.sub(body, 1, 1)] then
			-- (the same message waiting already: once is enough)
			if Wr:Waiting(name, text) then
				return true
			end
			return Wr:Send(name, text) ~= nil
		end
		return Wr:Post(name, text)
	end
	return G:Send(text, "WHISPER", name)
end

-- (1.14.0) My pass goes to a player before my offer, my answer or my duel (the wire keeps the order of my messages to
-- them): Pass.lua. Nothing when I have none. (1.14.3: no longer asked for, still sent when I have one: a player still
-- in 1.14.2 asks for it.)
function T:SendPass(name)
	local P = ns.Pass
	if not (P and name) then
		return false
	end
	local text, sig = P:Wire()
	if not text then
		return false
	end
	return self:Send(name, table.concat({ "V", text, sig }, "/"))
end

-- (1.12.0) The mark of a version of an offer: when it was written and by whom (two versions with the same
-- number, after a game closed before saving or two changes crossing: the newest is the offer).
function T:Tag()
	local t = Base36(Now())
	return string.rep(("0"), math.max(0, 6 - CuratorOctoFull.Length(t))) .. t .. (ns.db.uid or "")
end

-- (1.12.0) A mark newer than another (none: older than any).
local function Newer(a, b)
	return type(a) == "string" and a ~= "" and (type(b) ~= "string" or b == "" or a > b)
end

-- (1.12.0) The same version (a mark not known on one side: the number is enough).
local function SameTag(a, b)
	return type(a) ~= "string" or a == "" or type(b) ~= "string" or b == "" or a == b
end

local function OfferBody(rec)
	-- (the offer as its writer sees it: what I give, what I take; 1.8.0: the stake of a duel; 1.12.0: the mark
	-- of its version; 1.13.0: what goes with the copies I give)
	local body = table.concat({ "P", rec.id, rec.rev, ns.db.uid, T:Flags() + (rec.duel and FLAG_DUEL or 0), Encode(rec.give, true), Encode(rec.take),
		rec.tag or "", rec.duel or "" }, "/")
	return rec.live and (body .. "/" .. rec.live) or body
end

-- My offer goes (again): when the game says its player is not there, it waits for them (1.12.0: on the
-- wire, which sends it again until it is there; an older version of it, not there yet, no longer goes).
function T:SendOffer(rec)
	rec.sentAt, rec.lost, rec.got = Now(), nil, nil
	if ns.Wire then
		ns.Wire:Drop(rec.with, "T:" .. VERSION .. ":P/" .. rec.id .. "/")
	end
	-- (1.14.0: my pass first)
	self:SendPass(rec.with)
	if not self:Send(rec.with, OfferBody(rec)) then
		rec.lost = true
	end
end

-- An offer fits a message (eight lines a side, and its length).
function T:Fits(give, take)
	if CuratorOctoFull.Length(give) > self.MAX_ITEMS or CuratorOctoFull.Length(take) > self.MAX_ITEMS then
		return false
	end
	local body = table.concat({ "P", "xxxxxx-xxxxxxxx", 999, "xxxxxx", 3, Encode(self:Resolve(Copy(give)), true), Encode(take), "xxxxxxxxxxxx",
		"xxxxxxxxxxxxxxxx" }, "/")
	return CuratorOctoFull.Length(("T:" .. VERSION .. ":" .. body)) <= self.MAX_LEN
end

-- (1.13.0) The copies I give, each item of a side: those chosen (ids), the least precious free ones after them; what
-- goes with those that have something to tell (c). Nothing for the boosters.
function T:Resolve(items)
	local CP = ns.Copies
	for _, it in ipairs(items or {}) do
		if it.k and CP then
			local ids = Leaving(it, it.n or 1)
			local c = {}
			for _, id in ipairs(ids) do
				-- (1.14.0: a corrupted copy, its seal too: its card)
				local p = CP.Pack(CP:Get(it.k, id), it.k)
				if p then
					c[CuratorOctoFull.Length(c) + 1] = p
				end
			end
			it.ids = CuratorOctoFull.Length(ids) > 0 and ids or nil
			it.c = CuratorOctoFull.Length(c) > 0 and c or nil
		end
	end
	return items
end

-- (1.13.0) My answer to an offer fits a message: what goes with the copies I would give (those chosen, picks: a list of
-- ids for each line I give; else the least precious) goes with it.
function T:AnswerFits(rec, picks)
	local give = Copy(rec and rec.give)
	for i, it in ipairs(give) do
		it.ids = it.k and type(picks) == "table" and type(picks[i]) == "table" and CuratorOctoFull.Length(picks[i]) > 0 and Join(picks[i]) or nil
	end
	local body = table.concat({ "A", rec and rec.id or "", rec and rec.rev or 0, ns.db.uid or "", rec and rec.tag or "",
		Encode(self:Resolve(give), true) }, "/")
	return CuratorOctoFull.Length(("T:" .. VERSION .. ":" .. body)) <= self.MAX_LEN
end

-- A new offer to a player (nothing in it yet): not kept until it is sent.
function T:Draft(name, give, take)
	-- (1.13.1: the name a known player goes by, whatever the case of its letters as typed)
	local with = Norm(name)
	return { with = with and G:Canon(with), give = Merge(give or {}), take = Merge(take or {}), st = "draft", rev = 0 }
end

-- Why an offer cannot be sent (nil: it can): "test", "edited", "empty", "self", "big", "lacks", and
-- (1.12.1) "banned": the other player is banned from Curator (Bans.lua).
function T:Problem(draft)
	local ok, why = self:CanTrade()
	if not ok then
		return why
	end
	if not draft.with or G:IsMe(draft.with) then
		return "self"
	end
	if ns.Bans and ns.Bans:Sender(draft.with) then
		return "banned"
	end
	if CuratorOctoFull.Length(draft.give) == 0 and CuratorOctoFull.Length(draft.take) == 0 then
		return "empty"
	end
	if not self:Fits(draft.give, draft.take) then
		return "big"
	end
	if CuratorOctoFull.Length(self:Missing(draft.give)) > 0 then
		return "lacks"
	end
	return nil
end

-- Sends an offer: a new one (a draft), or a new version of an open trade (an offer changed, mine or
-- theirs). Returns the trade, or nil and why.
function T:Propose(draft)
	local why = self:Problem(draft)
	if why then
		return nil, why
	end
	local db = ns.db
	local rec = draft.id and db.trades[draft.id]
	if rec then
		if not OPEN[rec.st] or rec.st == "acc" then
			return nil, "closed"
		end
		rec.rev = rec.rev + 1
	else
		-- (its number: the collection, the moment, a count; a game closed before saving counts again, the
		-- moment does not)
		db.tradeSeq = (db.tradeSeq or 0) + 1
		rec = { id = db.uid .. "-" .. Base36(Now()) .. Base36(CuratorOctoFull.Mod(db.tradeSeq , 1296)), with = G:Canon(draft.with), rev = 1, t = Now(), duel = draft.duel }
		db.trades[rec.id] = rec
	end
	-- (1.13.0: the copies I give, those chosen and the least precious after them, what goes with them)
	rec.give, rec.take = self:Resolve(Merge(draft.give)), Merge(draft.take)
	for _, it in ipairs(rec.take) do
		it.ids, it.c = nil, nil
	end
	rec.by, rec.st, rec.why, rec.lost = "me", "out", nil, nil
	rec.tag = self:Tag()
	rec.live = ns.LiveTrade.ValidToken(draft.live) and draft.live or nil
	rec.wuid = rec.wuid or (G:Profile(rec.with) or {}).uid
	self:Changed(rec)
	self:SendOffer(rec)
	return rec
end

-- Accepts the offer received: what I give is put aside (it waits with the trade), the writer is told. (1.13.0) picks:
-- the copies I chose for each line I give (picks[i]: their numbers; nil: the least precious), what goes with them told.
function T:Accept(rec, picks)
	if not (rec and rec.st == "in" and rec.by == "them") then
		return false, "closed"
	end
	local ok, why = self:CanTrade()
	if not ok then
		return false, why
	end
	for i, it in ipairs(rec.give) do
		it.ids = it.k and type(picks) == "table" and type(picks[i]) == "table" and CuratorOctoFull.Length(picks[i]) > 0 and Join(picks[i]) or nil
	end
	if CuratorOctoFull.Length(self:Missing(rec.give)) > 0 then
		for _, it in ipairs(rec.give) do
			it.ids = nil
		end
		return false, "lacks"
	end
	-- (1.13.0: what goes with the copies I give must fit my answer)
	if not self:AnswerFits(rec, picks) then
		for _, it in ipairs(rec.give) do
			it.ids = nil
		end
		return false, "big"
	end
	for _, it in ipairs(rec.give) do
		Remove(it)
	end
	rec.st, rec.escrow = "acc", true
	self:Changed(rec)
	-- (1.14.0: my pass first)
	self:SendPass(rec.with)
	self:Send(rec.with, table.concat({ "A", rec.id, rec.rev, ns.db.uid, rec.tag or "", Encode(rec.give, true) }, "/"))
	ns.Fire("CHANGED")
	return true
end

-- Refuses the offer received.
function T:Decline(rec)
	if not (rec and rec.st == "in") then
		return false
	end
	rec.st, rec.why = "no", "declined"
	self:Changed(rec)
	self:Send(rec.with, table.concat({ "X", rec.id, rec.rev, "declined" }, "/"))
	return true
end

-- Takes back my offer.
function T:Withdraw(rec)
	if not (rec and rec.st == "out") then
		return false
	end
	rec.st, rec.why = "no", "cancelled"
	self:Changed(rec)
	self:Send(rec.with, table.concat({ "X", rec.id, rec.rev, "cancelled" }, "/"))
	return true
end

-------------------------------------------------------------------------------
-- The trade made, confirmed, undone
-------------------------------------------------------------------------------
local function Notable(card, finish)
	return card and (C:Notable(card, finish) or card.rarity >= 5)
end

-- The trade is made on my side: what I give leaves (unless it was put aside), what comes comes.
function T:Apply(rec)
	local db = ns.db
	if not rec.escrow then
		for _, it in ipairs(rec.give) do
			Remove(it)
		end
	end
	rec.escrow = nil
	for _, it in ipairs(rec.take) do
		-- (1.14.0: what the other player gave comes, whatever another addon changed this session; each card and its
		-- album as they must be: Guard.lua)
		if ns.Guard then
			ns.Guard:Trading(Receive, it, rec)
		else
			Receive(it, rec)
		end
	end
	-- (1.5.0: its cards wait the days of the quarantine)
	rec.st, rec.td, rec.q = "done", Now(), true
	-- the achievements: the players traded with, a gift, a card looked for, a mythic card
	local st = ns.Stats()
	st.trades = (st.trades or 0) + 1
	st.partners = st.partners or {}
	-- (1.6.0: a player never traded with before, for the talent Broker)
	rec.fresh = not st.partners[rec.with] or nil
	st.partners[rec.with] = true
	if CuratorOctoFull.Length(rec.take) == 0 and CuratorOctoFull.Length(rec.give) > 0 then
		st.gift = true
	end
	local best
	for _, side in ipairs({ rec.give, rec.take }) do
		for _, it in ipairs(side) do
			local card = it.k and ns.Cards[it.k]
			if card and card.rarity >= ns.MYTHIC then
				st.tMyth = true
			end
		end
	end
	for _, it in ipairs(rec.take) do
		local card = it.k and ns.Cards[it.k]
		if card then
			if db.wish and db.wish[card.key] then
				db.wish[card.key] = nil
				st.wish = true
				self.wishSig = nil
			end
			if Notable(card, it.f) and (not best or C:Score(card, it.f) > C:Score(best.card, best.f)) then
				best = { card = card, f = it.f }
			end
		end
	end
	self:Changed(rec)
	ns.Fire("CHANGED")
	ns.Fire("WISH_CHANGED")
	ns.Fire("TRADE_DONE", rec)
	-- (1.8.0: the stake of a duel, paid)
	if rec.duel and ns.Duel then
		ns.Duel:Paid(rec)
	end
	-- the finest card that came, for the guild
	if best and db.announce then
		G:Send(string.format(("E:%s:%s%s/%s/%d"), VERSION, best.card.npc, (best.f == "shiny" and "s") or (best.f == "holo" and "h") or "",
			rec.with, CuratorOctoFull.Length(rec.give) == 0 and 1 or 0), "GUILD")
	end
end

-- The other side has the trade in its save: what came is free.
function T:Confirm(rec)
	if not Unconfirmed(rec) then
		return
	end
	rec.ok = true
	Release(rec)
	self:Changed(rec)
	ns.Fire("CHANGED")
	ns.Fire("TRADE_CONFIRMED", rec)
end

-- The other side lost the trade (its game closed before saving it): it is undone here too, what came
-- goes, what I gave comes back.
function T:Reverse(rec)
	for _, it in ipairs(rec.take) do
		Unreceive(it, rec)
	end
	for _, it in ipairs(rec.give) do
		Restore(it, rec)
	end
	rec.st, rec.why, rec.escrow = "no", "reversed", nil
	self:Changed(rec)
	ns.Fire("CHANGED")
	ns.Fire("TRADE_REVERSED", rec)
	-- (1.12.0: the stake of a duel, undone: the duel waits for it again)
	if rec.duel and ns.Duel and ns.Duel.Reversed then
		ns.Duel:Reversed(rec)
	end
end

-- An offer I had accepted did not happen: what I put aside comes back.
local function Unescrow(rec)
	if rec.escrow then
		for _, it in ipairs(rec.give) do
			Restore(it, rec)
		end
		rec.escrow = nil
		ns.Fire("CHANGED")
	end
end

-- (1.14.0, later) The release of OctoWoW (Reroll.lua, RR:Migrate): what I gave in the trades I accepted, held until
-- their other side confirms, back to me (the same copies), before the collection starts over: quietly (nothing told, no
-- line of the journal: it starts empty). The trades themselves go with the rest; what came to me, waiting, too.
function T:GiveBackAll()
	local db = ns.db
	for _, rec in pairs(type(db) == "table" and type(db.trades) == "table" and db.trades or {}) do
		if type(rec) == "table" and rec.escrow and type(rec.give) == "table" then
			for _, it in ipairs(rec.give) do
				local n = type(it) == "table" and math.max(0, math.floor(tonumber(it.n) or 0)) or 0
				if n == 0 then
					-- (nothing to give back)
				elseif it.b then
					if type(db.packs) == "table" then
						db.packs[it.b] = (tonumber(db.packs[it.b]) or 0) + n
					end
				elseif it.k and ns.Cards[it.k] then
					PutBack(it, n, it.cp)
					it.cp = nil
				end
			end
			rec.escrow = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Receiving
-------------------------------------------------------------------------------
local WHY = { declined = true, cancelled = true, gone = true, stale = true, refused = true, edited = true, version = true,
	busy = true, closed = true, unknown = true, pass = true, nopass = true }

-- The trade a message is about, when it comes from its other side (the same player, or another
-- character of the same account).
local function Mine(id, sender, uid)
	local rec = T:Get(id)
	if not rec then
		return nil
	end
	if rec.with == sender or (uid and rec.wuid and rec.wuid == uid) then
		return rec
	end
	if type(rec.with) == "string" and type(sender) == "string" then
		-- (1.13.1: the same name in other capitals, as it was typed: the one the game writes is kept)
		if G.Fold(rec.with) == G.Fold(sender) then
			rec.with = sender
			return rec
		end
		-- (1.13.1, OctoWoW: a first name alone, or with my realm as 1.13.0 left it: the player of that first name who
		-- writes about this very trade, unless their collection is another one)
		local first = G:Surnames() and ((not string.find(rec.with, "-", 1, true) and rec.with) or G:RealmForm(rec.with))
		if first and G.Fold(first) == G.Fold(CuratorOctoFull.Match(sender, "^([^%-]+)") or "") and not (uid and rec.wuid and rec.wuid ~= uid) then
			rec.with = sender
			return rec
		end
	end
	return nil
end

function T:OnOffer(f, sender)
	local id, rev, uid, flags = f[2], G.Count(f[3]), f[4], G.Count(f[5])
	if not (id and CuratorOctoFull.Match(id, "^[%w%-]+$") and CuratorOctoFull.Length(id) <= 20 and rev and uid and CuratorOctoFull.Match(uid, "^%w+$") and CuratorOctoFull.Length(uid) <= 8 and flags) then
		return
	end
	local function no(why)
		self:Send(sender, table.concat({ "X", id, rev, why }, "/"))
	end
	-- (their offer as they wrote it: what they give comes to me; 1.13.0: what goes with their copies, with what they
	-- give only: the copies I give, I choose them)
	local theirGive, theirTake = Decode(f[6] or ""), Decode(f[7] or "")
	for _, it in ipairs(theirTake or {}) do
		it.c = nil
	end
	-- (1.14.0: each corrupted copy they give with its corruption, else the offer does not read)
	if theirGive and not Told(theirGive) then
		theirGive = nil
	end
	local tag = f[8]
	if tag and not (CuratorOctoFull.Match(tag, "^%w+$") and CuratorOctoFull.Length(tag) <= 16) then
		tag = nil
	end
	local db = ns.db
	local rec = db.trades[id]
	if rec then
		if not Mine(id, sender, uid) or rev < rec.rev then
			return
		end
		if rev == rec.rev then
			-- (1.12.0: the same number: the same version, or one written again after a game closed before
			-- saving, or two changes crossing: the newest mark is the offer)
			if not (theirGive and theirTake) or (Encode(theirTake) == Encode(rec.give) and Encode(theirGive) == Encode(rec.take)) then
				if Newer(tag, rec.tag) and rec.by == "them" then
					rec.tag = tag
				end
				return
			end
			if not Newer(tag, rec.tag) then
				return
			end
		end
		if rec.st == "done" or rec.st == "no" then
			return no("closed")
		end
		if not (theirGive and theirTake) then
			return no("version")
		end
		-- (a new version: what I had accepted of the last one comes back)
		Unescrow(rec)
		rec.rev, rec.give, rec.take, rec.tag = rev, theirTake, theirGive, tag
		rec.by, rec.st, rec.lost, rec.wuid = "them", "in", nil, uid
		rec.got, rec.agot = nil, nil
		self:Changed(rec)
		ns.Fire("TRADE_IN", rec, true)
		return
	end
	if Ignored(sender) then
		return no("refused")
	end
	local can, whyNot = self:CanTrade()
	if not can then
		return no((whyNot == "beta" and "version") or (whyNot == "guard" and "refused") or "edited")
	end
	if CuratorOctoFull.Mod(flags , 4) ~= 0 then
		return no("edited")
	end
	if not (theirGive and theirTake) then
		return no("version")
	end
	if CuratorOctoFull.Length(theirGive) == 0 and CuratorOctoFull.Length(theirTake) == 0 then
		return
	end
	-- (1.8.0: the stake of a duel I won: from the one I dueled, known or not, whatever waits)
	local duel = CuratorOctoFull.Mod(math.floor(flags / FLAG_DUEL) , 2) == 1 and ns.Duel ~= nil
	if not duel then
		if not db.strangers and not self:Known(sender) then
			return no("refused")
		end
		local open = 0
		for _, r in pairs(db.trades) do
			if r.st == "in" then
				open = open + 1
			end
		end
		if open >= self.OPEN_MAX then
			return no("busy")
		end
	end
	rec = { id = id, with = sender, wuid = uid, rev = rev, by = "them", st = "in", give = theirTake, take = theirGive, t = Now(), tag = tag }
	rec.live = ns.LiveTrade.ValidToken(f[10]) and f[10] or nil
	db.trades[id] = rec
	self:Changed(rec)
	-- (1.12.0: the duel it pays, by its number)
	local duelId = f[9]
	if duelId and not (CuratorOctoFull.Match(duelId, "^%w+$") and CuratorOctoFull.Length(duelId) <= 24) then
		duelId = nil
	end
	if duel and ns.Duel:OnPayment(rec, sender, duelId ~= "" and duelId or nil) then
		return
	end
	if duel and not self:Known(sender) and not db.strangers then
		-- (a stake of no duel of mine, from a stranger: refused as any offer of a stranger)
		db.trades[id] = nil
		self:Changed()
		return no("refused")
	end
	ns.Fire("TRADE_IN", rec, false)
end

function T:OnAccept(f, sender)
	local id, rev, uid, tag = f[2], G.Count(f[3]), f[4], f[5]
	if not (id and rev) then
		return
	end
	local rec = Mine(id, sender, uid)
	if not rec then
		return self:Send(sender, table.concat({ "X", id, rev, "unknown" }, "/"))
	end
	if rec.st == "done" and rec.rev == rev and SameTag(tag, rec.tag) then
		-- (they did not hear it: again)
		return self:Send(sender, table.concat({ "D", id, rev, rec.tag or "" }, "/"))
	end
	-- (1.12.0: the version they accepted, by its mark: not another one with the same number)
	if not (rec.st == "out" and rec.by == "me" and rec.rev == rev and SameTag(tag, rec.tag)) then
		return self:Send(sender, table.concat({ "X", id, rev, rec.st == "out" and "stale" or "closed" }, "/"))
	end
	if uid and CuratorOctoFull.Match(uid, "^%w+$") then
		rec.wuid = uid
	end
	if not self:CanTrade() or CuratorOctoFull.Length(self:Missing(rec.give)) > 0 then
		rec.st, rec.why = "no", "gone"
		self:Changed(rec)
		return self:Send(sender, table.concat({ "X", id, rev, "gone" }, "/"))
	end
	-- (1.13.0: what goes with the copies they give, to their lines)
	local theirs = Decode(f[6] or "")
	for _, it in ipairs(rec.take) do
		it.c = nil
		for _, x in ipairs(theirs or {}) do
			if x.k and Same(x, it) then
				it.c = Join(x.c)
			end
		end
	end
	-- (1.14.0: each corrupted copy they give with its corruption, else their answer does not read: nothing happens, what
	-- they put aside goes back to them)
	if not Told(rec.take) then
		for _, it in ipairs(rec.take) do
			it.c = nil
		end
		rec.st, rec.why = "no", "version"
		self:Changed(rec)
		ns.Fire("TRADE_NO", rec, "version")
		return self:Send(sender, table.concat({ "X", id, rev, "version" }, "/"))
	end
	self:Apply(rec)
	self:Send(sender, table.concat({ "D", id, rev, rec.tag or "" }, "/"))
end

function T:OnDone(f, sender)
	local id, rev, tag = f[2], G.Count(f[3]), f[4]
	local rec = id and Mine(id, sender)
	if rec and rec.st == "acc" and rec.rev == rev and SameTag(tag, rec.tag) then
		self:Apply(rec)
	end
end

function T:OnNo(f, sender)
	local id, rev, why = f[2], G.Count(f[3]), f[4]
	local rec = id and Mine(id, sender)
	if not (rec and rev and OPEN[rec.st]) or rev < rec.rev then
		return
	end
	why = WHY[why or ""] and why or "declined"
	if why == "stale" then
		-- (my answer was to a version they changed since: theirs comes)
		if rec.st == "acc" and rec.rev == rev then
			Unescrow(rec)
			rec.st = "in"
			self:Changed(rec)
		end
		return
	end
	Unescrow(rec)
	rec.st, rec.why = "no", why
	self:Changed(rec)
	ns.Fire("TRADE_NO", rec, why)
	-- (1.8.0: the stake of a duel not paid: again when we meet; 1.12.0: refused, the duel is over)
	if rec.duel and ns.Duel then
		ns.Duel:Failed(rec, why)
	end
end

-------------------------------------------------------------------------------
-- Settling: the two sides compare their trades whenever they meet
-------------------------------------------------------------------------------
local function StateOf(rec)
	if not rec then
		return "M"
	end
	if rec.st == "done" then
		return rec.dur and "D" or "N"
	elseif rec.st == "acc" then
		return "W"
	elseif rec.st == "out" or rec.st == "in" then
		return "O"
	end
	return "M"
end

-- My trades to settle with a player (or with another character of the same account).
function T:ToSettle(name, uid)
	local out = {}
	for id, rec in pairs(ns.db and ns.db.trades or {}) do
		if (rec.with == name or (uid and rec.wuid == uid)) and ToSettle(rec) then
			out[CuratorOctoFull.Length(out) + 1] = id
		end
	end
	table.sort(out)
	return out
end

-- Asks a player where my trades with them are.
function T:Check(name, ids)
	ids = ids or self:ToSettle(name, (G:Profile(name) or {}).uid)
	if CuratorOctoFull.Length(ids) == 0 then
		return false
	end
	self.checkAt[name] = GetTime()
	local list = {}
	for i = 1, math.min(CuratorOctoFull.Length(ids), 12) do
		list[i] = ids[i]
	end
	return self:Send(name, table.concat({ "K", ns.db.uid, table.concat(list, ",") }, "/"))
end

-- A message came from a player: they are there. The trades to settle with them are checked (once in
-- a while), my offers they did not get go again.
function T:Contact(sender)
	local db = ns.db
	if not (db and db.trades) then
		return
	end
	local name = Norm(sender)
	if not name or G:IsMe(name) then
		return
	end
	self.offline[name] = nil
	-- (1.8.0: a stake of a duel I owe them)
	if ns.Duel then
		ns.Duel:Contact(name)
	end
	-- (my offers they did not get: again, now that they are there; 1.12.0: what waits on the wire goes)
	if ns.Wire then
		ns.Wire:Wake(name)
	else
		for _, rec in pairs(db.trades) do
			if rec.st == "out" and rec.lost and rec.with == name then
				self:SendOffer(rec)
			end
		end
	end
	local now = GetTime()
	if self.contactAt[name] and now - self.contactAt[name] < 20 then
		return
	end
	self.contactAt[name] = now
	local uid = (G:Profile(name) or {}).uid
	local ids = self:ToSettle(name, uid)
	if CuratorOctoFull.Length(ids) > 0 then
		self:Check(name, ids)
	end
end

function T:OnCheck(f, sender)
	local uid, list = f[2], f[3]
	if not (list and list ~= "") then
		return
	end
	local out = {}
	for id in CuratorOctoFull.Gmatch((list .. ","), "([^,]*),") do
		if CuratorOctoFull.Match(id, "^[%w%-]+$") and CuratorOctoFull.Length(out) < 12 then
			out[CuratorOctoFull.Length(out) + 1] = id .. "=" .. StateOf(Mine(id, sender, uid))
		end
	end
	if CuratorOctoFull.Length(out) > 0 then
		self:Send(sender, table.concat({ "Y", ns.db.uid, table.concat(out, ",") }, "/"))
	end
	-- (they are there: mine are checked too)
	self:Contact(sender)
end

function T:OnStates(f, sender)
	local uid, list = f[2], f[3]
	if not list then
		return
	end
	for id, state in CuratorOctoFull.Gmatch(list, "([%w%-]+)=(%u)") do
		local rec = Mine(id, sender, uid)
		if rec then
			if rec.st == "done" then
				if state == "D" then
					self:Confirm(rec)
				elseif state == "W" then
					-- (they wait for my word: again)
					self:Send(sender, table.concat({ "D", id, rec.rev, rec.tag or "" }, "/"))
				elseif (state == "O" or state == "M") and Unconfirmed(rec) then
					-- (they lost it: undone here too)
					self:Reverse(rec)
				end
			elseif rec.st == "out" then
				if state == "M" then
					-- (1.12.0: they lost my offer, their game closed before saving it: it goes again)
					self:SendOffer(rec)
				end
			elseif rec.st == "acc" then
				if state == "D" or state == "N" then
					self:Apply(rec)
				elseif state == "O" then
					-- (my answer did not reach them: again; 1.13.0: with what goes with my copies; 1.14.0: my pass first)
					self:SendPass(sender)
					self:Send(sender, table.concat({ "A", id, rec.rev, ns.db.uid, rec.tag or "", Encode(rec.give, true) }, "/"))
				elseif state == "M" then
					Unescrow(rec)
					rec.st, rec.why = "no", "lost"
					self:Changed(rec)
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- The messages
-------------------------------------------------------------------------------
local OPS = { L = "OnLive", P = "OnOffer", A = "OnAccept", D = "OnDone", X = "OnNo", K = "OnCheck", Y = "OnStates", V = "OnPass" }

-- (1.14.0) The pass of a player came, before their offer, their answer or their duel: Pass.lua.
function T:OnPass(f, sender)
	if ns.Pass then
		ns.Pass:Came(sender, f[2], f[3])
	end
end

-- "T" (a trade, by whisper or Battle.net only), "N" (cards looked for), "U" (cards to spare looked
-- for), "E" (a fine card that came in a trade).
function T:OnMessage(kind, body, channel, sender)
	if not ns.db then
		return
	end
	sender = Norm(sender)
	if not sender then
		return
	end
	if kind == "T" then
		if channel ~= "WHISPER" then
			return
		end
		local f = {}
		for part in CuratorOctoFull.Gmatch((body .. "/"), "([^/]*)/") do
			f[CuratorOctoFull.Length(f) + 1] = part
		end
		local fn = OPS[f[1] or ""]
		if fn then
			self[fn](self, f, sender)
		end
	elseif kind == "N" or kind == "U" then
		self:OnList(kind, body, channel, sender)
	elseif kind == "E" and channel == "GUILD" then
		local tok, partner, gift = CuratorOctoFull.Match(body, "^(%d+[sh]?)/([^/]+)/(%d)$")
		local items = tok and Decode(tok)
		local it = items and items[1]
		if it and it.k then
			ns.Fire("GUILD_TRADE", sender, ns.Cards[it.k], it.f, Norm(partner), gift == "1")
		end
	end
end

-------------------------------------------------------------------------------
-- The cards looked for
-------------------------------------------------------------------------------
function T:Wished(card)
	local w = ns.db and ns.db.wish
	return w ~= nil and card ~= nil and w[card.key] ~= nil
end

-- Looks for a card (one not in the album), or not any more. False and "full" past T.WISH_MAX.
function T:ToggleWish(card)
	local db = ns.db
	db.wish = db.wish or {}
	if db.wish[card.key] then
		db.wish[card.key] = nil
	else
		local n = 0
		for _ in pairs(db.wish) do
			n = n + 1
		end
		if n >= self:WishMax() then
			return false, "full"
		end
		db.wish[card.key] = Now()
	end
	self.wishSig = nil
	ns.Fire("WISH_CHANGED")
	if G.ready then
		G:QueueSummary(5)
	end
	return true
end

-- How many cards I can look for.
function T:WishMax()
	return ns.Talents and ns.Talents:WishMax(self.WISH_MAX) or self.WISH_MAX
end

-- The cards I look for, in the order of the albums (those found meanwhile leave the list).
function T:Wishes()
	local db = ns.db
	local out = {}
	if not (db and db.wish) then
		return out
	end
	for key in pairs(db.wish) do
		local card = ns.Cards[key]
		if not card or C:Owned(card) then
			db.wish[key] = nil
		else
			out[CuratorOctoFull.Length(out) + 1] = card
		end
	end
	table.sort(out, function(a, b)
		if a.series ~= b.series then
			return (a.series.order or 0) < (b.series.order or 0)
		end
		return a.num < b.num
	end)
	return out
end

-- The players (of my guild, met) who look for a card.
function T:SoughtBy(card)
	local out = {}
	for _, db in ipairs({ ns.db.guild, ns.db.met }) do
		for name, m in pairs(db) do
			if m.wish and m.wish[card.key] and not G:IsMe(name) then
				out[CuratorOctoFull.Length(out) + 1] = name
			end
		end
	end
	table.sort(out)
	return out
end

-- The players who have a card to spare: they said so (it is looked for), or their album shows two
-- copies of it.
function T:HoldersOf(card)
	local out, seen = {}, {}
	for _, db in ipairs({ ns.db.guild, ns.db.met }) do
		for name, m in pairs(db) do
			if not seen[name] and not G:IsMe(name) then
				local has = m.dup and m.dup[card.key]
				if not has then
					local a = m.c and m.c[card.series.key]
					local e = a and C:Decode(card.series, a.counts, a.shinies, a.holos)
					has = e and e[card.key] and e[card.key].n >= 2
				end
				if has then
					seen[name] = true
					out[CuratorOctoFull.Length(out) + 1] = name
				end
			end
		end
	end
	table.sort(out)
	return out
end

-- My cards to spare that someone of my guild looks for (for the list I tell them).
function T:SoughtSpare()
	local out = {}
	local want = {}
	for name, m in pairs(ns.db.guild) do
		if m.wish and not G:IsMe(name) then
			for key in pairs(m.wish) do
				want[key] = true
			end
		end
	end
	for key in pairs(want) do
		local card = ns.Cards[key]
		if card then
			local spare = 0
			-- (1.14.0: a corrupted copy to spare too)
			for _, fin in ipairs(T.FINISHES) do
				spare = spare + self:Spare(card, fin, true)
			end
			if spare > 0 then
				out[CuratorOctoFull.Length(out) + 1] = card
			end
		end
	end
	table.sort(out, function(a, b)
		return a.npc < b.npc
	end)
	return out
end

-- A list of cards in as few messages as fit ("*": a new list).
local function ListMessages(kind, cards)
	local head = kind .. ":" .. VERSION .. ":"
	local msgs, cur = {}, head .. "*"
	for _, card in ipairs(cards) do
		local part = tostring(card.npc)
		if CuratorOctoFull.Length(cur) + 1 + CuratorOctoFull.Length(part) > G.MAX_LEN then
			msgs[CuratorOctoFull.Length(msgs) + 1] = cur
			cur = head .. part
		else
			cur = cur .. ";" .. part
		end
	end
	msgs[CuratorOctoFull.Length(msgs) + 1] = cur
	return msgs
end

function T:WishMessages()
	return ListMessages("N", self:Wishes())
end

function T:SpareMessages()
	return ListMessages("U", self:SoughtSpare())
end

-- (1.6.0, the talent Network) My cards to spare that a player looks for (their list as I know it).
function T:SpareFor(name)
	local m = G:Player(name)
	local out = {}
	for key in pairs((m and m.wish) or {}) do
		local card = ns.Cards[key]
		if card then
			local spare = 0
			-- (1.14.0: a corrupted copy to spare too)
			for _, fin in ipairs(T.FINISHES) do
				spare = spare + self:Spare(card, fin, true)
			end
			if spare > 0 then
				out[CuratorOctoFull.Length(out) + 1] = card
			end
		end
	end
	table.sort(out, function(a, b)
		return a.npc < b.npc
	end)
	return ListMessages("U", out)
end

function T:OnList(kind, body, channel, sender)
	local m = G:Store(sender, channel)
	local field = kind == "N" and "wish" or "dup"
	local parts = {}
	for part in CuratorOctoFull.Gmatch((body .. ";"), "([^;]*);") do
		parts[CuratorOctoFull.Length(parts) + 1] = part
	end
	if parts[1] == "*" or not m[field] then
		m[field] = {}
	end
	local n = 0
	for _ in pairs(m[field]) do
		n = n + 1
	end
	for _, part in ipairs(parts) do
		local card = ns.Cards["c" .. part]
		if card and n < self.WISH_CAP then
			if not m[field][card.key] then
				n = n + 1
			end
			m[field][card.key] = true
		end
	end
	-- (what my guild looks for changed: the list of my cards to spare goes again)
	if kind == "N" and G.ready then
		G:QueueSummary()
	end
	-- (1.6.0: the talent Network tells me who looks for my cards to spare)
	if kind == "N" and ns.Talents then
		ns.Talents:Network(Norm(sender), m[field])
	end
	ns.Fire("WISH_CHANGED")
end

-------------------------------------------------------------------------------
-- Battle.net: the friends playing this game (any faction, any realm) get the messages that way
-------------------------------------------------------------------------------
local function BNAPI()
	local B = C_BattleNet
	return B
end

-- The name of the character of a game account of Battle.net, as Curator names players. (1.13.1: OctoWoW:
-- "First-Surname", never a realm after it, Comm.lua.)
local function BNFull(g)
	return G:BNName(g)
end

-- Each friend of Battle.net playing this same game: fn(its game account (C_BattleNet)).
local function EachBN(fn)
	local B = BNAPI()
	local count = 0
	if BNGetNumFriends then
		local ok, n = pcall(BNGetNumFriends)
		count = (ok and type(n) == "number" and not Secret(n)) and n or 0
	end
	if B and B.GetFriendNumGameAccounts and B.GetFriendGameAccountInfo then
		for i = 1, count do
			local ok, num = pcall(B.GetFriendNumGameAccounts, i)
			for j = 1, (ok and type(num) == "number" and not Secret(num)) and num or 0 do
				local ok2, g = pcall(B.GetFriendGameAccountInfo, i, j)
				if ok2 and type(g) == "table" and not Secret(g) and g.isOnline and g.clientProgram == (BNET_CLIENT_WOW or "WoW")
					and g.characterName and g.characterName ~= "" and not Secret(g.characterName)
					and (not WOW_PROJECT_ID or not g.wowProjectID or g.wowProjectID == WOW_PROJECT_ID) then
					fn(g)
				end
			end
		end
	end
end

-- (1.13.1) The name Curator 1.13.0 gave each friend of Battle.net playing now (its character and its realm: on WoW
-- Forever, "Brindille-ClassicBetaPvE2"), and the one it gives them now (Comm.lua, G:FixRealms).
local function OldName(g)
	local realm = g.realmName or g.realmDisplayName
	return g.characterName .. "-" .. ((type(realm) == "string" and not Secret(realm)) and string.gsub(realm, "[%s%-]", "") or "")
end

function T:OldBNNames()
	local out = {}
	EachBN(function(g)
		local old, now = OldName(g), BNFull(g)
		if now and now ~= old then
			-- (two friends of that first name: whose it was is not known)
			if out[old] ~= nil and out[old] ~= now then
				out[old] = false
			elseif out[old] == nil then
				out[old] = now
			end
		end
	end)
	for k, v in pairs(out) do
		if v == false then
			out[k] = nil
		end
	end
	return out
end

-- The friends of Battle.net in this same game: their character, their game account.
function T:ScanBN()
	local byName, byID, byOld = {}, {}, {}
	EachBN(function(g)
		local name = BNFull(g)
		if name and not G:IsMe(name) then
			byName[name] = g.gameAccountID
			byID[g.gameAccountID] = name
			-- (1.13.1: the name 1.13.0 gave them, "First-Realm" on OctoWoW: theirs while it is theirs alone)
			local old = OldName(g)
			if old ~= name then
				byOld[old] = (byOld[old] == nil or byOld[old] == g.gameAccountID) and g.gameAccountID or false
			end
		end
	end)
	-- (1.12.0: a friend who comes into the game gets at once what waits for them on the wire)
	local was = self.bnByName or {}
	self.bnByName, self.nameByBN, self.bnByOld = byName, byID, byOld
	-- (1.13.1: OctoWoW: the names of 1.13.0 still to make over, now that a friend may have come, Comm.lua)
	if G.settled and G.realmsLeft then
		G:FixRealms(ns.db, self:OldBNNames())
	end
	if ns.Wire then
		for name in pairs(byName) do
			if not was[name] then
				ns.Wire:Wake(name)
			end
		end
	end
	ns.Fire("FRIENDS_CHANGED")
end

-- The game account a message to this player goes to (a friend of Battle.net), else nil.
function T:BNTarget(name)
	if not name then
		return nil
	end
	local id = self.bnByName[name]
	if id or type(name) ~= "string" or not G:Surnames() then
		return id
	end
	-- (1.13.1, OctoWoW: the name 1.13.0 gave a friend playing now, "First-Realm": that friend, theirs alone)
	if G:RealmForm(name) then
		local old = self.bnByOld and self.bnByOld[name]
		return old or nil
	end
	-- (a first name alone, from a menu: the one friend of Battle.net of that first name, unless another player known
	-- has it too)
	if not string.find(name, "-", 1, true) then
		local low, found, friend = G.Fold(name), nil, nil
		for n, gid in pairs(self.bnByName) do
			if G.Fold(CuratorOctoFull.Match(n, "^([^%-]+)") or n) == low then
				if found then
					return nil
				end
				found, friend = gid, n
			end
		end
		if found then
			for _, db in ipairs({ ns.db and ns.db.guild or {}, ns.db and ns.db.met or {} }) do
				for known in pairs(db) do
					if known ~= friend and G.Fold(CuratorOctoFull.Match(known, "^([^%-]+)") or known) == low and string.find(known, "-", 1, true) and not G:RealmForm(known) then
						return nil
					end
				end
			end
		end
		return found
	end
	return nil
end

-- The friends of Battle.net in this game, by name.
function T:BNFriends()
	local out = {}
	for name in pairs(self.bnByName) do
		out[CuratorOctoFull.Length(out) + 1] = name
	end
	table.sort(out)
	return out
end

function T:SendBN(id, prefix, msg)
	local B = BNAPI()
	local send = (B and B.SendGameData) or BNSendGameData
	if not send then
		return false
	end
	local ok, res = pcall(send, id, prefix, msg)
	return ok and (res == nil or res == true or res == 0)
end

-- The character of a game account of Battle.net (nil: not known).
function T:BNName(senderID)
	local name = self.nameByBN[senderID]
	if not name then
		local B = BNAPI()
		if B and B.GetGameAccountInfoByID then
			local ok, g = pcall(B.GetGameAccountInfoByID, senderID)
			if ok and type(g) == "table" and not Secret(g) and g.characterName then
				name = BNFull(g)
				if name then
					self.bnByName[name], self.nameByBN[senderID] = senderID, name
				end
			end
		end
	end
	return name
end

-- A message of Battle.net: from the character of that game account.
function T:OnBN(prefix, text, senderID)
	local name = self:BNName(senderID)
	if name then
		G:OnMessage(text, "WHISPER", name)
	end
end

-------------------------------------------------------------------------------
-- The guild roster: who is online
-------------------------------------------------------------------------------
function T:ScanRoster()
	local roster = {}
	if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
		local ok, n = pcall(GetNumGuildMembers)
		for i = 1, (ok and type(n) == "number" and not Secret(n)) and n or 0 do
			local ok2, name, _, _, _, _, _, _, _, online = pcall(GetGuildRosterInfo, i)
			local key = ok2 and type(name) == "string" and not Secret(name) and Norm(name)
			if key then
				roster[key] = online and true or false
			end
		end
	end
	-- (1.12.0: a member who comes online gets at once what waits for them on the wire)
	local was = self.roster or {}
	self.roster = roster
	if ns.Wire then
		for name, on in pairs(roster) do
			if on and was[name] == false then
				ns.Wire:Wake(name)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- A whisper to a player who is not there: the game says so in the chat; for mine, the line goes and
-- the player is offline for a while.
-------------------------------------------------------------------------------
local function NotFound(_, _, msg, ...)
	if type(msg) ~= "string" or Secret(msg) or not ERR_CHAT_PLAYER_NOT_FOUND_S then
		return false
	end
	local now = GetTime()
	for name, t in pairs(T.whispered) do
		if now - t < 5 then
			for _, n in ipairs({ name, G:Short(name) }) do
				if msg == string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, n) then
					-- (not there: the next message of theirs checks the trades at once)
					T.offline[name] = now
					T.contactAt[name] = nil
					for _, rec in pairs(ns.db and ns.db.trades or {}) do
						if rec.with == name and rec.st == "out" and not rec.lost and rec.sentAt and Now() - rec.sentAt < 10 then
							rec.lost = true
							ns.Fire("TRADES_CHANGED", rec)
						end
					end
					return true
				end
			end
		end
	end
	return false
end
T.NotFound = NotFound

-------------------------------------------------------------------------------
-- Now and then: offers too old go, what came is free after the days of the lock, the trades to settle
-- are checked with those who may be there.
-------------------------------------------------------------------------------
function T:Tick()
	local db = ns.db
	if not (db and db.trades) then
		return
	end
	local now = Now()
	local changed = false
	for _, rec in pairs(db.trades) do
		if (rec.st == "out" or rec.st == "in") and now - (rec.u or rec.t or now) > self.EXPIRE then
			rec.st, rec.why = "no", "expired"
			changed = true
		elseif Unconfirmed(rec) and now - (rec.td or now) > self.LOCK_DAYS * 86400 then
			rec.free = true
			Release(rec)
			changed = true
		elseif rec.st == "acc" and not rec.agot and now - (rec.u or rec.t or now) > self.LOCK_DAYS * 86400 then
			-- (an answer that never reached them: what was put aside comes back; 1.12.0: an answer they got
			-- waits for its trade, the checks settle it)
			if ns.Wire then
				ns.Wire:Drop(rec.with, "T:" .. VERSION .. ":A/" .. rec.id .. "/")
			end
			Unescrow(rec)
			rec.st, rec.why = "no", "lost"
			changed = true
		end
	end
	-- (1.14.0: the boosters of a trade the guard kept held, Guard.lua: released once they can be)
	for _, rec in pairs(db.trades) do
		if rec.st == "done" and (rec.ok or rec.free) then
			for _, it in ipairs(rec.take or {}) do
				if it.wait then
					changed = Release(rec, true) or changed
					break
				end
			end
		end
	end
	-- (a lock over: what came is free, the achievements count it)
	if self.lockEnds and now >= self.lockEnds then
		changed = true
	end
	if changed then
		self:Changed()
		ns.Fire("CHANGED")
	end
	-- the players with trades to settle: those online (or not known) are asked, once in a while
	local t = GetTime()
	local asked = {}
	for _, rec in pairs(db.trades) do
		local name = rec.with
		if name and not asked[name] and (ToSettle(rec) or (rec.st == "out" and rec.lost)) then
			asked[name] = true
			local online = self:Online(name)
			local every = online and self.CHECK_EVERY or self.CHECK_EVERY * 3
			if online ~= false and t - (self.checkAt[name] or -1e9) > every then
				self.checkAt[name] = t
				self.contactAt[name] = nil
				self:Contact(name)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
ns.On("LOADED", function()
	local db = ns.db
	db.trades = db.trades or {}
	db.wish = db.wish or {}
	db.held = db.held or {}
	if db.strangers == nil then
		db.strangers = true
	end
	if type(db.uid) ~= "string" or not CuratorOctoFull.Match(db.uid, "^%w+$") then
		local s = ""
		for _ = 1, 6 do
			local d = math.random(36)
			s = s .. string.sub(B36, d, d)
		end
		db.uid = s
	end
	-- (what is in the save now is saved: the other side can be told so)
	for _, rec in pairs(db.trades) do
		rec.dur = true
	end
	-- (1.12.0: the offers and the answers of before go again by the wire, once: those the other side never
	-- got come; those it has are read as the same again)
	if db.wireMig ~= 1 and ns.Wire then
		db.wireMig = 1
		for _, rec in pairs(db.trades) do
			if rec.st == "out" and rec.by == "me" then
				T:SendOffer(rec)
			elseif rec.st == "acc" then
				T:Send(rec.with, table.concat({ "A", rec.id, rec.rev, db.uid, rec.tag or "", Encode(rec.give, true) }, "/"))
			end
		end
	end
	T:Prune()
	T:CountLocks()
end)

-- (1.12.0) What the wire says: an offer, an answer the other side has; an offer that never reached them
-- in a week.
local function OnWire(text)
	local op, id, rev = CuratorOctoFull.Match(text, "^T:%d+:(%u)/([%w%-]+)/(%d+)")
	local rec = id and T:Get(id)
	return op, rec, tonumber(rev)
end

if ns.Wire then
	ns.Wire:OnAck("T", function(_, text)
		local op, rec, rev = OnWire(text)
		if not rec or rec.rev ~= rev then
			return
		end
		if op == "P" and rec.st == "out" then
			rec.got, rec.lost = Now(), nil
			T:Changed(rec)
		elseif op == "A" and rec.st == "acc" then
			rec.agot = Now()
			T:Changed(rec)
		end
	end)
	ns.Wire:OnLost("T", function(_, text)
		local op, rec, rev = OnWire(text)
		if op == "P" and rec and rec.st == "out" and rec.rev == rev then
			rec.st, rec.why = "no", "expired"
			T:Changed(rec)
			ns.Fire("TRADE_NO", rec, "expired")
			if rec.duel and ns.Duel then
				ns.Duel:Failed(rec, "expired")
			end
		end
	end)
end

local f = CreateFrame("Frame")
T.frame = f
f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "BN_CHAT_MSG_ADDON", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_INFO_CHANGED",
			"GUILD_ROSTER_UPDATE" }) do
			pcall(f.RegisterEvent, f, e)
		end
		local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
		if add then
			pcall(add, "CHAT_MSG_SYSTEM", NotFound)
		end
		T:ScanBN()
		T:ScanRoster()
		if C_GuildInfo and C_GuildInfo.GuildRoster then
			pcall(C_GuildInfo.GuildRoster)
		end
		-- (a moment after the login: the trades to settle are checked with those who are there)
		ns.Delay(15, function()
			T:Tick()
		end, T)
		if CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker then
			T.ticker = CuratorOctoFull.Timer.NewTicker(T.TICK, function()
				T:Tick()
			end)
		end
	elseif event == "BN_CHAT_MSG_ADDON" then
		local prefix, text, _, senderID = unpack(arg, 1, arg.n)
		if not Secret(prefix) and prefix == "Curator" and type(text) == "string" and not Secret(text) and not Secret(senderID) then
			T:OnBN(prefix, text, senderID)
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		T:ScanRoster()
	else
		T:ScanBN()
	end
end)

do
    local live = {}
    ns.LiveTrade = live
    local prefix = "T:" .. VERSION .. ":L/"
    local inviteTime, idleTime = 40, 300
    local sequence = 0

    local function token(id)
        return type(id) == "string" and string.len(id) <= 24 and string.find(id, "^%w+$") ~= nil
    end
    live.ValidToken = token

    local function samePlayer(a, b)
        return a and b and G.Fold(a) == G.Fold(b)
    end

    local function send(s, op, data)
        return ns.Wire:Send(s.with, prefix .. s.id .. "/" .. op .. "/" .. (data or ""), inviteTime)
    end

    local function eligible(name)
        return name and not G:IsMe(name) and T:CanTrade() and not Ignored(name)
            and not (ns.Bans and ns.Bans:Sender(name))
    end

    local function session(id, name, state)
        return { id = id, with = name, state = state, host = state == "waiting",
            untilTime = GetTime() + inviteTime, give = {}, take = {}, sent = "", rev = 0, remoteRev = 0 }
    end

    local function changed(s)
        ns.Fire("LIVE_TRADE_CHANGED", s)
    end

    function live:Close(s, reason, notify)
        if self.current ~= s then return end
        self.current = nil
        ns.CancelOwner(s)
        ns.Wire:Drop(s.with, prefix .. s.id .. "/")
        s.state = reason
        if notify then send(s, "C", reason) end
        changed(s)
    end

    function live:Watch(s)
        ns.Delay(1, function()
            if self.current ~= s then return end
            if GetTime() >= s.untilTime then
                self:Close(s, "expired", true)
            elseif s.attached and not ns.LiveTradeUI:Showing(s) then
                self:Close(s, "closed", true)
            else
                self:Watch(s)
            end
        end, s)
    end

    function live:Invite(name)
        name = G:Canon(Norm(name))
        if not eligible(name) then return false, "unavailable" end
        if self.current then return false, "busy" end
        sequence = sequence + 1
        local id = (ns.db.uid or "") .. Base36(Now()) .. Base36(sequence) .. Base36(math.random(0, 46655))
        local s = session(id, name, "waiting")
        if not token(id) or not send(s, "I") then return false, "unavailable" end
        self.current = s
        self:Watch(s)
        ns.Fire("LIVE_TRADE_OPEN", s)
        return true
    end

    function live:Agree(s)
        if self.current ~= s or s.state ~= "invited" then return end
        if not eligible(s.with) or not send(s, "A") then
            self:Close(s, "closed", true)
            return
        end
        s.state, s.untilTime = "open", GetTime() + idleTime
        changed(s)
        ns.Fire("LIVE_TRADE_OPEN", s)
    end

    function live:Sync(s)
        if self.current ~= s or s.state ~= "open" or s.sync then return end
        if T.Encode(s.give) == s.sent then return end
        s.sync = ns.Delay(.18, function()
            s.sync = nil
            if self.current ~= s or s.state ~= "open" then return end
            local data = T.Encode(s.give)
            if data == s.sent then return end
            local revision = s.rev + 1
            ns.Wire:Drop(s.with, prefix .. s.id .. "/U/")
            if send(s, "U", revision .. "/" .. data) then
                s.sent, s.rev, s.untilTime = data, revision, GetTime() + idleTime
            end
        end, s)
    end

    function live:Submit(s)
        if self.current ~= s or not s.host or s.state ~= "open" then return end
        local draft = T:Draft(s.with, s.give, s.take)
        draft.live = s.id
        local rec = T:Propose(draft)
        if rec then self:Close(s, "sent") end
        return rec
    end

    function live:MatchOffer(rec)
        local s = self.current
        if s and not s.host and s.state == "open" and rec.live == s.id and samePlayer(s.with, rec.with) then
            self:Close(s, "sent")
            return s
        end
    end

    function T:OnLive(f, sender)
        local id, op = f[2], f[3]
        if not token(id) then return end
        local s = live.current
        if op == "I" then
            if not eligible(sender) or (not ns.db.strangers and not T:Known(sender)) then return end
            if s then
                if s.id ~= id or not samePlayer(s.with, sender) then
                    send(session(id, sender, "invited"), "C", "busy")
                end
                return
            end
            s = session(id, sender, "invited")
            live.current = s
            live:Watch(s)
            ns.Fire("LIVE_TRADE_INVITE", s)
            return
        end
        if not (s and s.id == id and samePlayer(s.with, sender)) then return end
        if op == "C" then
            local reason = f[4]
            live:Close(s, (reason == "declined" or reason == "busy" or reason == "expired") and reason or "closed")
        elseif op == "A" and s.state == "waiting" then
            s.state, s.untilTime = "open", GetTime() + idleTime
            changed(s)
        elseif op == "U" and s.state == "open" then
            local revision, data = G.Count(f[4]), f[5]
            if not (revision and revision > s.remoteRev and data and string.len(data) <= 255
                and not string.find(data, "~", 1, true)) then return end
            local items = Decode(data)
            if not items then return end
            s.take, s.remoteRev, s.untilTime = items, revision, GetTime() + idleTime
            changed(s)
        end
    end
end
