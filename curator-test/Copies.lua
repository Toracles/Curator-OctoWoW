local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.13.0) Each copy of a card on its own: the copies of a card are no longer a count only, each one has its
-- story (when it came, how, where, by which character), its expertise (its grade, its marks, its certificate, in its
-- case or its case opened: Expertise.lua), its restorations at the enchanters (Restore.lua), its corruption and its
-- seal (Seal.lua), its signature (Inns.lua).
-- The counts of the collection stay the truth for everything that counts (db.cards[key]: n, s, h, c, cl: the
-- website, the app, the seal of the save, the contracts, the trades, the duels): the copies follow them, finish by
-- finish. A copy that leaves the collection is the one the player chose (Take, with the copies picked), else the least
-- precious of its finish. A copy that comes is made with what is known of it (Added, Stamp: C:Add, C:Log), or the one
-- a trade brings with its expertise (Expect), or the same copy coming back (Put: a trade undone). The collections of
-- before 1.13.0: their copies are made once, at the login, from the journal when it tells their story without doubt,
-- else "in the album before 1.13.0"; the appraisals of before (one a card) go on one of its copies (Migrate).
-- What is kept: db.copies[card key] = { record, ... }, db.copyId (the last number given), db.copiesV (1: made),
-- db.gradedOrphans (an appraisal of before whose card had no copy left: on its next copy). A record:
--   i its number; f its finish (nil normal, "s" thunderforged, "h" titanforged, "c" corrupted); t when it came (nil:
--   not known); w how ("b" a booster, "g" a golden booster, "f" found on a creature, "k" a contract, "t" a trade, "r"
--   the reseller, "i" an innkeeper (a bet, a signature), "c" a gift code, "e" a place explored, "x" given by the
--   author, "a" in the album before 1.13.0); z the zone; ch the character; p with whom (a trade), the ticket (a golden
--   booster), the id of the code (a gift); bn the number of its booster; tr the trade it came in; o where a copy that
--   came in a trade came from first ({ t, w, ch });
--   g its grade shown x100 (appraised), m its four marks ("9A9A"), ce its certificate, at when appraised, sl true in
--   its case (false: its case opened, its grade to appraise again); hg its true grade x100 (Restore.lua: what the
--   restorations made of it, known at the next appraisal); r its restorations ({ { t, d, a } }: when, how long (1 to
--   4), how much x100); aw at an enchanter now (Restore.lua);
--   cor its corruption; ws sealed by a Master of Warlocks; pu when it was purified; sg signed by its innkeeper;
--   (1.14.0, his idea) pt the pattern of a titanforged copy (Patterns.lua): a number of 1 to 19683 drawn once, when it is
--   made, or the first time it is seen without one (the titanforged copies of before), never again: it goes with it
--   everywhere (a trade, the Bourse, back again). No other copy has one.
--   (his idea, 31 October) wv, wq its wear: its seed, its condition hidden (Wear.lua).
-- Every value as the save keeps it, the same once written and read again: whole numbers, short strings, booleans.
-------------------------------------------------------------------------------
local CP = { expect = {}, back = {}, picked = {} }
ns.Copies = CP

-- The finish of a copy as kept, from a finish of the collection ("shiny", "holo", "corrupt"; nil and anything else
-- normal, as C:Add counts them).
CP.FK = { shiny = "s", holo = "h", corrupt = "c" }
CP.FINISH = { s = "shiny", h = "holo", c = "corrupt" }
CP.KEYS = { false, "s", "h", "c" } -- (false: the normal copies)

local function Now()
	return GetServerTime and CuratorOctoFull.ServerTime() or time()
end

local function FK(finish)
	return CP.FK[finish or ""]
end
CP.Key = FK

function CP.Finish(rec)
	return rec and CP.FINISH[rec.f or ""] or nil
end

local function Int(v)
	return math.max(0, math.floor(tonumber(v) or 0))
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

function CP:Db()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.copies) ~= "table" then
		db.copies = {}
	end
	return db.copies
end

function CP:NewId()
	local db = ns.db
	db.copyId = Int(db.copyId) + 1
	return db.copyId
end

-- How many copies of a finish an entry of the collection holds (fk: nil normal, "s", "h", "c").
function CP.Want(e, fk)
	if type(e) ~= "table" then
		return 0
	end
	local n, s, h = Int(e.n), Int(e.s), Int(e.h)
	local c = math.min(n, Int(e.c))
	if fk == "s" then
		return math.min(s, n)
	elseif fk == "h" then
		return math.min(h, n)
	elseif fk == "c" then
		return c
	end
	return math.max(0, n - s - h - c)
end

local function Count(list, fk)
	local n = 0
	for _, r in ipairs(list) do
		if r.f == fk then
			n = n + 1
		end
	end
	return n
end

-- How precious a copy is (the least precious leaves first when the player did not choose): its expertise, its
-- restorations, its seal, its corruption.
function CP.Value(rec)
	local v = 0
	if rec.g then
		v = v + 100000 + Int(rec.g)
	end
	if type(rec.r) == "table" then
		v = v + 1000 * CuratorOctoFull.Length(rec.r)
	end
	if rec.ws then
		v = v + 50000
	end
	if rec.cor then
		v = v + Int(rec.cor)
	end
	if rec.sg then
		v = v + 200000
	end
	return v
end

-- The least precious first; between two alike, the newest first (the oldest copies stay).
local function LeastFirst(a, b)
	local va, vb = CP.Value(a), CP.Value(b)
	if va ~= vb then
		return va < vb
	end
	return (a.i or 0) > (b.i or 0)
end
CP.LeastFirst = LeastFirst

-- At an enchanter now (Restore.lua): it cannot leave, nor be appraised.
function CP.Away(rec)
	return type(rec) == "table" and type(rec.aw) == "table"
end

-- (1.14.0) The patterns: their count (Patterns.lua), a pattern as the save keeps it (a whole number of 1 to it; nil:
-- not one), one drawn.
local function PatternMax()
	return (ns.Patterns and ns.Patterns.MAX) or 19683
end

local function PatternNo(v)
	v = tonumber(v)
	if v and v == math.floor(v) and v >= 1 and v <= PatternMax() then
		return v
	end
	return nil
end
CP.PatternNo = PatternNo

function CP.DrawPattern()
	return math.random(1, PatternMax())
end

-- The pattern of a titanforged copy that had none (one of before 1.14.0, one of which nothing is known): drawn from
-- the collection, its card and the number of the copy, the same each time, so that a game closed before it saves
-- gives it the same again (no collection id yet: drawn).
function CP.DerivedPattern(key, rec)
	local cid = ns.db and ns.db.cid
	local i = type(rec) == "table" and tonumber(rec.i)
	if type(cid) ~= "string" or cid == "" or type(key) ~= "string" or not i then
		return CP.DrawPattern()
	end
	local str = "pattern:" .. cid .. ":" .. key .. ":" .. tostring(math.floor(i))
	local a = 5381
	for k = 1, CuratorOctoFull.Length(str) do
		a = CuratorOctoFull.Mod((a * 33 + CuratorOctoFull.Byte(str, k)) , 2147483647)
	end
	return CuratorOctoFull.Mod(a , PatternMax()) + 1
end

-- The pattern of a copy (nil: none, or not a titanforged copy).
function CP.Pattern(rec)
	if type(rec) ~= "table" or rec.f ~= "h" then
		return nil
	end
	return PatternNo(rec.pt)
end

-- Appraised, its grade shown (x100), or nil.
function CP.Grade(rec)
	local g = type(rec) == "table" and tonumber(rec.g)
	if g and g >= 100 and g <= 1000 then
		return math.floor(g)
	end
	return nil
end

-------------------------------------------------------------------------------
-- What is said of a copy that comes now
-------------------------------------------------------------------------------
-- The zone, the character (nil: the game does not say).
function CP:Here()
	local z, ch
	if GetRealZoneText then
		local ok, v = pcall(GetRealZoneText)
		if ok and type(v) == "string" and not Secret(v) and v ~= "" then
			z = string.sub(v, 1, 48)
		end
	end
	if UnitName then
		local ok, v = pcall(UnitName, "player")
		if ok and type(v) == "string" and not Secret(v) and v ~= "" then
			ch = string.sub(v, 1, 24)
		end
	end
	return z, ch
end

-- What the copies that come now carry with them (a gift code: its id, a trade: its number...): { w, p, tr }, until
-- cleared (nil).
function CP:SetContext(ctx)
	self.ctx = ctx
end

local function Fresh(fk)
	local z, ch = CP:Here()
	local rec = { i = CP:NewId(), f = fk, t = Now(), z = z, ch = ch }
	local ctx = CP.ctx
	if ctx then
		rec.w, rec.p, rec.tr = ctx.w, ctx.p, ctx.tr
	end
	-- (1.14.0: a titanforged copy, its pattern, drawn now)
	if fk == "h" then
		rec.pt = CP.DrawPattern()
	end
	-- (his idea, 31 October: its condition, drawn now, hidden: Wear.lua)
	if ns.Wear then
		ns.Wear.Fresh(rec)
	end
	return rec
end

-- An appraisal of before whose card had no copy left: on this copy, the first that comes back (as before 1.13.0,
-- the grade showed again when a copy came back). Never on a corrupted copy.
local function Orphan(key, rec)
	local o = ns.db and ns.db.gradedOrphans
	local x = type(o) == "table" and o[key]
	if type(x) ~= "table" or rec.g or rec.f == "c" then
		return
	end
	local n = Int(x.g)
	o[key] = nil
	if next(o) == nil then
		ns.db.gradedOrphans = nil
	end
	if n < 1 or n > 10 then
		return
	end
	rec.g, rec.hg = n * 100, n * 100
	rec.m, rec.ce, rec.at, rec.sl = type(x.s) == "string" and x.s or nil, tonumber(x.c), tonumber(x.t), true
end

-------------------------------------------------------------------------------
-- The copies of a card, in step with its counts
-------------------------------------------------------------------------------
-- The copies of a card (its records, the counts followed first: made, or gone).
function CP:List(key)
	local all = self:Db()
	if not (all and key) then
		return {}
	end
	self:Reconcile(key)
	return all[key] or {}
end

-- n copies of a finish leave the records (those picked first, then the least precious, never one at an enchanter
-- while another can go, nor the signed one): the records gone.
function CP:Drop(key, list, fk, n)
	local gone = {}
	if n <= 0 then
		return gone
	end
	local function Remove(rec)
		for i, r in ipairs(list) do
			if r == rec then
				CuratorOctoFull.Remove(list, i)
				gone[CuratorOctoFull.Length(gone) + 1] = rec
				return true
			end
		end
	end
	local picked = self.picked[key]
	self.picked[key] = nil
	if type(picked) == "table" then
		for _, id in ipairs(picked) do
			if CuratorOctoFull.Length(gone) >= n then
				break
			end
			for _, r in ipairs(list) do
				if r.i == id and r.f == fk then
					Remove(r)
					break
				end
			end
		end
	end
	while CuratorOctoFull.Length(gone) < n do
		local cands = {}
		for _, r in ipairs(list) do
			if r.f == fk then
				cands[CuratorOctoFull.Length(cands) + 1] = r
			end
		end
		if CuratorOctoFull.Length(cands) == 0 then
			break
		end
		table.sort(cands, function(a, b)
			local pa = (CP.Away(a) and 2 or 0) + (a.sg and 1 or 0)
			local pb = (CP.Away(b) and 2 or 0) + (b.sg and 1 or 0)
			if pa ~= pb then
				return pa < pb
			end
			return LeastFirst(a, b)
		end)
		Remove(cands[1])
	end
	return gone
end

-- The seals of the Masters of Warlocks of a card: { { k = its corruption, i = the copy }, ... } (Seal.lua).
local function Seals(key)
	local SL = ns.Masters
	if not (SL and SL.Seals) then
		return {}
	end
	return SL:Seals(key)
end

-- The corrupted copies: the sealed ones (the copies of the seals, Seal.lua), the others the corruption of e.cl, the
-- most corrupted with the most corrupted.
function CP:Corrupt(key, e, list)
	local C = ns.Collection
	local cors = {}
	for _, r in ipairs(list) do
		if r.f == "c" then
			cors[CuratorOctoFull.Length(cors) + 1] = r
		else
			r.cor, r.ws = nil, nil
		end
	end
	if CuratorOctoFull.Length(cors) == 0 then
		return
	end
	local seals = Seals(key)
	local taken = {}
	-- (each seal on its copy: by its number, else the copy of its corruption, else the most corrupted not sealed)
	for _, x in ipairs(seals) do
		local spot
		for _, r in ipairs(cors) do
			if not taken[r] and x.i and r.i == x.i then
				spot = r
			end
		end
		if not spot then
			local want, bd = C.Gauge(x.k), nil
			for _, r in ipairs(cors) do
				if not taken[r] then
					local d = math.abs((tonumber(r.cor) or 0) - want) + (r.ws and 0 or 0.5)
					if not spot or d < bd then
						spot, bd = r, d
					end
				end
			end
		end
		if spot then
			taken[spot] = true
			spot.ws, spot.cor = true, C.Gauge(x.k)
			x.i = spot.i
		end
	end
	local rest = {}
	for _, r in ipairs(cors) do
		if not taken[r] then
			r.ws = nil
			rest[CuratorOctoFull.Length(rest) + 1] = r
		end
	end
	local cl = {}
	for i, v in ipairs(C:CorruptCopies(e)) do
		cl[i] = C.Gauge(v)
	end
	table.sort(cl, function(a, b)
		return a > b
	end)
	table.sort(rest, function(a, b)
		local ca, cb = tonumber(a.cor) or 0, tonumber(b.cor) or 0
		if ca ~= cb then
			return ca > cb
		end
		return (a.i or 0) < (b.i or 0)
	end)
	for j, r in ipairs(rest) do
		r.cor = cl[j] or C.Gauge(r.cor)
	end
end

-- The copy signed by its innkeeper: one normal copy (the one an innkeeper gave, else the oldest).
function CP:Signed(key, list)
	local signed = ns.Inns and ns.Inns:IsSigned(key) or false
	local sg
	for _, r in ipairs(list) do
		if r.sg then
			if signed and not sg and r.f == nil then
				sg = r
			else
				r.sg = nil
			end
		end
	end
	if signed and not sg then
		local best
		for _, r in ipairs(list) do
			if r.f == nil then
				local ri, bi = r.w == "i", best and best.w == "i"
				if not best or (ri and not bi) or (ri == bi and (r.i or 0) < (best.i or 0)) then
					best = r
				end
			end
		end
		if best then
			best.sg = true
		end
	end
end

-- The records of a card follow its counts: per finish, the missing copies are made (those coming back, those a trade
-- brings, else a copy of which nothing is known), those too many go (Drop).
function CP:Reconcile(key)
	local all = self:Db()
	local db = ns.db
	local e = all and db.cards[key]
	if not e or Int(e.n) <= 0 then
		if all then
			all[key] = nil
		end
		return
	end
	local list = all[key]
	if type(list) ~= "table" then
		list = {}
		all[key] = list
	end
	-- (anything else than a record in their place goes)
	for i = CuratorOctoFull.Length(list), 1, -1 do
		local r = list[i]
		if type(r) ~= "table" or not tonumber(r.i) then
			CuratorOctoFull.Remove(list, i)
		elseif r.f ~= nil and not CP.FINISH[r.f] then
			r.f = nil
		end
	end
	for _, k in ipairs(self.KEYS) do
		local fk = k or nil
		local want, have = self.Want(e, fk), Count(list, fk)
		if have > want then
			self:Drop(key, list, fk, have - want)
		end
		while have < want do
			local rec = self:PopExpected(key, fk) or { i = self:NewId(), f = fk, w = "a" }
			list[CuratorOctoFull.Length(list) + 1] = rec
			Orphan(key, rec)
			have = have + 1
		end
	end
	self:Corrupt(key, e, list)
	self:Signed(key, list)
	self:Patterns(list, key)
	-- (his idea, 31 October: every copy its condition, Wear.lua)
	if ns.Wear then
		ns.Wear:Fill(key, list)
	end
end

-- (1.14.0) Each titanforged copy has its pattern: one without (a titanforged copy of before, one of which nothing is
-- known, one a trade brought without) gets one now, once (CP.DerivedPattern); no other copy has one.
function CP:Patterns(list, key)
	for _, r in ipairs(list) do
		if r.f == "h" then
			if not PatternNo(r.pt) then
				r.pt = self.DerivedPattern(key, r)
			end
		elseif r.pt ~= nil then
			r.pt = nil
		end
	end
end

-------------------------------------------------------------------------------
-- What comes, what goes
-------------------------------------------------------------------------------
-- Copies that will come in place of new ones: back (the same copies coming back: a trade undone, a contract that
-- gave some back) or brought (a trade: their expertise, their story).
function CP:Expect(key, rec)
	if type(rec) == "table" then
		self.expect[key] = self.expect[key] or {}
		CuratorOctoFull.Insert(self.expect[key], rec)
	end
end

function CP:Put(key, recs)
	if type(recs) ~= "table" then
		return
	end
	self.back[key] = self.back[key] or {}
	for _, r in ipairs(recs) do
		if type(r) == "table" then
			CuratorOctoFull.Insert(self.back[key], r)
		end
	end
end

-- The copy expected for a card and a finish, if any (one coming back keeps its number).
function CP:PopExpected(key, fk)
	for _, q in ipairs({ self.back, self.expect }) do
		local list = q[key]
		if type(list) == "table" then
			for i, r in ipairs(list) do
				if r.f == fk then
					CuratorOctoFull.Remove(list, i)
					if CuratorOctoFull.Length(list) == 0 then
						q[key] = nil
					end
					if q == self.expect then
						-- (brought: a new copy here, its number of here, when and where it came)
						local z, ch = self:Here()
						r.i, r.t, r.z, r.ch = self:NewId(), Now(), z, ch
						local ctx = self.ctx
						if ctx then
							r.w, r.p, r.tr = r.w or ctx.w, r.p or ctx.p, r.tr or ctx.tr
						end
					elseif not tonumber(r.i) then
						r.i = self:NewId()
					end
					return r
				end
			end
		end
	end
end

-- A copy came (C:Add, its counts already up): its record. corruption: its own (a corrupted copy).
function CP:Added(card, finish, corruption)
	local all = card and self:Db()
	local e = all and ns.db.cards[card.key]
	if not e then
		return nil
	end
	local fk = FK(finish)
	local list = all[card.key]
	if type(list) ~= "table" then
		list = {}
		all[card.key] = list
	end
	-- (records out of step before it: those too many go first, this copy stays)
	local want, have = self.Want(e, fk), Count(list, fk)
	if have >= want then
		self:Drop(card.key, list, fk, have - want + 1)
	end
	local rec = self:PopExpected(card.key, fk) or Fresh(fk)
	rec.f = fk
	if fk == "c" then
		rec.cor = ns.Collection.Gauge(corruption)
	end
	list[CuratorOctoFull.Length(list) + 1] = rec
	Orphan(card.key, rec)
	self.last = rec
	self:Reconcile(card.key)
	return rec
end

-- How the copy that just came came (C:Log, called for each card kept): on the newest copy of that finish not told yet.
function CP:Stamp(card, finish, how, who)
	local db = ns.db
	local list = card and db and type(db.copies) == "table" and db.copies[card.key]
	if type(list) ~= "table" then
		return nil
	end
	local fk = FK(finish == true and "shiny" or finish)
	for i = CuratorOctoFull.Length(list), 1, -1 do
		local r = list[i]
		if r.f == fk and r.w == nil then
			r.w = (type(how) == "string" and CuratorOctoFull.Match(how, "^%a$")) or "x"
			if type(who) == "string" and who ~= "" and not Secret(who) and not r.p then
				r.p = string.sub(who, 1, 40)
			end
			if (r.w == "b" or r.w == "g") and not r.bn then
				local C = ns.Collection
				r.bn = (C and C.boosterNo) or tonumber(db.opened) or nil
			end
			return r
		end
	end
	return nil
end

-- A corrupted copy purified (Seal.lua, its counts already changed): the copy of that corruption not sealed (pick: the
-- one the player chose, its number, when it is that one), a plain copy now, its story kept. Its number (nil: none
-- matched, the copies follow the counts all the same).
function CP:Purified(key, corruption, pick)
	local all = self:Db()
	local list = all and all[key]
	if type(list) ~= "table" then
		return nil
	end
	local want = ns.Collection.Gauge(corruption)
	local spot
	for _, r in ipairs(pick ~= nil and list or {}) do
		if r.i == pick and r.f == "c" and not r.ws and ns.Collection.Gauge(r.cor) == want then
			spot = r
			break
		end
	end
	for _, r in ipairs(not spot and list or {}) do
		if r.f == "c" and not r.ws then
			if ns.Collection.Gauge(r.cor) == want then
				spot = r
				break
			end
			spot = spot or r
		end
	end
	if not spot then
		self:Reconcile(key)
		return nil
	end
	spot.f, spot.cor, spot.pu = nil, nil, Now()
	self:Reconcile(key)
	return spot.i
end

-- The copies the player chose for what comes next (the ones that leave first).
function CP:Pick(key, ids)
	self.picked[key] = (type(ids) == "table" and CuratorOctoFull.Length(ids) > 0) and ids or nil
end

-- n copies of a card in a finish leave now (before its counts go down): those of ids first (chosen), then the least
-- precious. The records that went (to keep, when they may come back: Put).
function CP:Take(key, finish, n, ids)
	local all = self:Db()
	if not (all and key) then
		return {}
	end
	local list = self:List(key)
	if type(ids) == "table" and CuratorOctoFull.Length(ids) > 0 then
		self.picked[key] = ids
	end
	local gone = self:Drop(key, list, FK(finish), Int(n))
	if CuratorOctoFull.Length(list) == 0 then
		all[key] = nil
	end
	return gone
end

-- A copy by its number (nil: not one of the collection).
function CP:Get(key, id)
	id = tonumber(id)
	for _, r in ipairs(self:List(key)) do
		if r.i == id then
			return r
		end
	end
	return nil
end

-- A copy by its number, whatever its card: the card and the record.
function CP:Find(id)
	id = tonumber(id)
	local db = ns.db
	for key, list in pairs(db and type(db.copies) == "table" and db.copies or {}) do
		for _, r in ipairs(type(list) == "table" and list or {}) do
			if r.i == id then
				return ns.Cards[key], r
			end
		end
	end
	return nil
end

-- Every copy of the collection: { card, rec } (those of the cards Curator knows).
function CP:All()
	local out = {}
	local db = ns.db
	if not db then
		return out
	end
	for key, e in pairs(db.cards) do
		local card = ns.Cards[key]
		if card and Int(e.n) > 0 then
			for _, r in ipairs(self:List(key)) do
				out[CuratorOctoFull.Length(out) + 1] = { card = card, rec = r }
			end
		end
	end
	return out
end

-- The copies of a card in a finish at an enchanter now (Restore.lua): they count, they cannot leave.
function CP:AwayCount(key, finish)
	local fk = FK(finish)
	local n = 0
	local all = ns.db and type(ns.db.copies) == "table" and ns.db.copies
	for _, r in ipairs(all and type(all[key]) == "table" and all[key] or {}) do
		if r.f == fk and CP.Away(r) then
			n = n + 1
		end
	end
	return n
end

-- A copy that came in a trade not free yet (Trade.lua: confirmed by the other side, past its days of quarantine); (1.14.0)
-- or bought at the Bourse, in its quarantine (Market.lua).
function CP.Locked(rec)
	if type(rec) ~= "table" then
		return false
	end
	if ns.Market and ns.Market.Quarantined and ns.Market:Quarantined(rec.i) then
		return true
	end
	local T = ns.Trade
	local tr = rec.tr and T and T:Get(rec.tr)
	if not tr then
		return false
	end
	return T.Unconfirmed(tr) or T.Quarantined(tr) or false
end

-- Why a copy cannot leave the collection now (nil: it can): "away" at an enchanter, "locked" (came in a trade not free
-- yet), "staked" (on a duel). (1.14.0, a player's word: everything can go, the copy signed by its innkeeper and a
-- corrupted one too: the signature stays with the card, on another copy of it if there is one, CP:Signed; the rules of
-- the contracts are theirs, Contract.lua: K:Spare.)
function CP:Stuck(key, rec)
	if self.Away(rec) then
		return "away"
	elseif self.Locked(rec) then
		return "locked"
	elseif ns.Duel and ns.Duel.StakedCopy and ns.Duel:StakedCopy(key, rec.i) then
		return "staked"
	end
	return nil
end

-- The copies of a card in a finish that can leave now, the least precious first (the one the player would give
-- without choosing).
function CP:Free(key, finish)
	local fk = FK(finish)
	local out = {}
	for _, r in ipairs(self:List(key)) do
		if r.f == fk and not self:Stuck(key, r) then
			out[CuratorOctoFull.Length(out) + 1] = r
		end
	end
	table.sort(out, LeastFirst)
	return out
end

-- The copies chosen still there and free to leave (ids: numbers), n of them at most (nil: one of them is not).
function CP:Chosen(key, finish, ids, n)
	if type(ids) ~= "table" or CuratorOctoFull.Length(ids) == 0 then
		return {}
	end
	local free = {}
	for _, r in ipairs(self:Free(key, finish)) do
		free[r.i] = true
	end
	local out, seen = {}, {}
	for _, id in ipairs(ids) do
		id = tonumber(id)
		if not (id and free[id]) or seen[id] then
			return nil
		end
		seen[id] = true
		out[CuratorOctoFull.Length(out) + 1] = id
	end
	if n and CuratorOctoFull.Length(out) > n then
		return nil
	end
	return out
end

-- The copy that shows the card (the album, its medal, the showcase, a link): its finest copy appraised (in its case
-- first), else nil.
function CP:Featured(key)
	local best, bg
	for _, r in ipairs(self:List(key)) do
		local g = CP.Grade(r)
		if g and r.sl ~= false then
			if not best or g > bg then
				best, bg = r, g
			end
		end
	end
	return best
end

-- (1.14.0) The pattern a card shows when it shows titanforged (the album, the showcase, a link): the one of the
-- titanforged copy shown first when it is shown big (UI/Copies.lua, CU:Default): its finest appraised in its case, else
-- its oldest (nil: none).
function CP:PatternOf(key)
	local best, bg, bt
	for _, r in ipairs(self:List(key)) do
		if CP.Pattern(r) then
			local g = CP.Grade(r)
			g = (g and r.sl ~= false) and g or -1
			local t = tonumber(r.t) or 0
			if not best or g > bg or (g == bg and (t < bt or (t == bt and (r.i or 0) < (best.i or 0)))) then
				best, bg, bt = r, g, t
			end
		end
	end
	return best and CP.Pattern(best) or nil
end

-- (1.14.0) The pattern of a copy by its number (a card just drawn: its copy, C:OpenBooster, ci), nil: none.
function CP:PatternById(key, id)
	return id ~= nil and CP.Pattern(self:Get(key, id)) or nil
end

-------------------------------------------------------------------------------
-- A copy in a trade: what goes with it (its expertise, its restorations, where it came from first)
--   "<grade>.<marks>.<cert>.<case>.<true grade>.<restorations>.<since>.<how>.<character>"
-- grade, true grade: x100 in base 36 (0: none); case: 1 in its case, 0 opened; restorations: "<t>-<d>-<a>+..." (t, a in
-- base 36); since: when it first came (base 36). Nothing for a copy that has nothing to tell (a plain copy).
-- (1.14.0, his word: a corrupted copy goes in a trade too) A corrupted copy always tells: its corruption and its seal
-- after the rest, ".<corruption>.<seal>" (corruption: 1 to 100; seal: "<rank>-<marks>-<pact>-<when>-<master>", pact and
-- when in base 36, empty when no Master of Warlocks sealed it); never appraised nor restored.
-- (1.14.0, his idea) A titanforged copy always tells: its pattern after the rest, ".<pattern>" (1 to 19683, Patterns.lua).
-- (1 November) Its wear goes with it, a twelfth part (Wear.lua; a copy with nothing else to tell: "w<wear>" alone): the
-- tenth then says what it is ("k<corruption>", "p<pattern>", or nothing), the eleventh its seal, or the certificate of
-- a master of the mages of a titanforged copy (Mages.lua: "<when>-<master>"; its wear may then be empty).
-------------------------------------------------------------------------------
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local function To36(n)
	n = Int(n)
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = math.floor(n / 36)
	until n == 0
	return s
end
local function From36(s)
	return type(s) == "string" and CuratorOctoFull.Match(s, "^[0-9a-z]+$") and CuratorOctoFull.Length(s) <= 8 and tonumber(s, 36) or nil
end
CP.To36, CP.From36 = To36, From36

-- A name as a payload carries it (none of the marks of the messages; 1.14.0: no letter cut in two at its end).
local function Clean(s, max)
	s = (string.gsub(tostring(s or ""), "[%c|.,/;:~*@+%-%%=]", ""))
	max = max or 24
	if CuratorOctoFull.Length(s) <= max then
		return s
	end
	s = string.sub(s, 1, max)
	local i = CuratorOctoFull.Length(s)
	while i > 1 and CuratorOctoFull.Byte(s, i) >= 128 and CuratorOctoFull.Byte(s, i) < 192 do
		i = i - 1
	end
	local b = CuratorOctoFull.Byte(s, i)
	local need = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
	if CuratorOctoFull.Length(s) - i + 1 < need then
		s = string.sub(s, 1, i - 1)
	end
	return s
end

-- Whether a copy has something to tell in a trade (1.14.0: a corrupted copy, always; a titanforged one, its pattern).
function CP.Telling(rec)
	return type(rec) == "table" and (rec.f == "c" or CP.Grade(rec) ~= nil or tonumber(rec.hg) ~= nil or (type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0)
		or CP.Pattern(rec) ~= nil) or false
end

-- (1.14.0) The seal of a corrupted copy: the one kept with it once it left (rec.seal: Trade.lua), else the seal of its
-- copy (key: its card; Seal.lua). nil: not sealed.
local function SealOf(rec, key)
	if type(rec.seal) == "table" then
		return rec.seal
	end
	local SL = ns.Masters
	if rec.ws and key and SL and SL.Record and ns.Cards and ns.Cards[key] then
		return (SL:Record(ns.Cards[key], rec.i))
	end
	return nil
end
CP.SealOf = SealOf

-- What goes with a copy in a trade (nil: nothing to tell). key: its card (1.14.0: the seal of a corrupted copy still
-- in the collection).
function CP.Pack(rec, key)
	-- (1 November, his word: the very same card on the other side: its wear with it, Wear.lua; a copy with nothing else
	-- to tell, its wear alone, "w<wear>")
	local wear = ns.Wear and ns.Wear.Pack and ns.Wear.Pack(rec)
	if not CP.Telling(rec) then
		return wear and ("w" .. wear) or nil
	end
	local rs = {}
	for _, x in ipairs(type(rec.r) == "table" and rec.r or {}) do
		if CuratorOctoFull.Length(rs) < 9 and type(x) == "table" then
			rs[CuratorOctoFull.Length(rs) + 1] = To36(x[1]) .. "-" .. math.max(1, math.min(4, Int(x[2]))) .. "-" .. To36(x[3])
		end
	end
	local o = type(rec.o) == "table" and rec.o or { t = rec.t, w = rec.w, ch = rec.ch }
	local m = type(rec.m) == "string" and CuratorOctoFull.Match(rec.m, "^[1-9A][1-9A][1-9A][1-9A]$") or ""
	local corrupt = rec.f == "c"
	local parts = {
		To36(not corrupt and CP.Grade(rec) or 0), not corrupt and m or "", To36(not corrupt and rec.ce or 0),
		(corrupt or rec.sl ~= false) and "1" or "0", To36(not corrupt and (rec.hg or rec.g) or 0),
		corrupt and "" or table.concat(rs, "+"), To36(o.t or 0), Clean(o.w, 1), Clean(o.ch, 24),
	}
	if corrupt then
		-- (its corruption, its seal: Seal.lua)
		local seal = ""
		local x = SealOf(rec, key)
		local rank = type(x) == "table" and ns.Masters and ns.Masters.Valid(x.g)
		local marks = rank and type(x.s) == "string" and CuratorOctoFull.Match(x.s, "^[1-9A][1-9A][1-9A][1-9A]$")
		if marks then
			seal = rank .. "-" .. marks .. "-" .. To36(x.c) .. "-" .. To36(x.t) .. "-" .. Clean(x.by, 40)
		end
		local k = ns.Collection and ns.Collection.Gauge(rec.cor) or math.max(1, math.min(100, Int(rec.cor)))
		parts[10], parts[11] = tostring(k), seal
	elseif CP.Pattern(rec) then
		-- (1.14.0: a titanforged copy, its pattern)
		parts[10] = tostring(CP.Pattern(rec))
	end
	-- (1 November, his idea: a titanforged copy certified by a master of the mages, its certificate with it, Mages.lua)
	local MG = ns.Mages
	local cert = (not corrupt) and parts[10] and MG and MG.Pack(MG.Of(rec)) or nil
	-- (1 November: its wear, a twelfth part; the tenth says what it is, "k" its corruption, "p" its pattern; the eleventh,
	-- its seal, or its certificate; a titanforged copy certified without its wear: its wear empty)
	if wear or cert then
		local tag = ""
		if corrupt then
			tag = "k" .. parts[10]
		elseif parts[10] then
			tag = "p" .. parts[10]
		end
		parts[10], parts[11], parts[12] = tag, (corrupt and parts[11]) or cert or "", wear or ""
	end
	return table.concat(parts, ".")
end

-- A copy from what came with it (nil: nothing to read). Its finish: the item's (1.14.0: a corrupted copy, its
-- corruption, rec.cor, and its seal, rec.seal: { g, s, c, t, by }).
function CP.Unpack(s)
	if type(s) ~= "string" or CuratorOctoFull.Length(s) > 400 then
		return nil
	end
	-- (1 November: a copy with nothing else to tell, its wear alone)
	if string.sub(s, 1, 1) == "w" and not string.find(s, ".", 1, true) then
		local x = ns.Wear and ns.Wear.Unpack and ns.Wear.Unpack(string.sub(s, 2))
		if not x then
			return nil
		end
		return { wv = x.wv, wq = x.wq, w0 = x.w0, wx = x.wx, wa = x.wa, hm = x.hm }
	end
	local f = {}
	for part in CuratorOctoFull.Gmatch((s .. "."), "([^.]*)%.") do
		f[CuratorOctoFull.Length(f) + 1] = part
	end
	if CuratorOctoFull.Length(f) ~= 9 and CuratorOctoFull.Length(f) ~= 10 and CuratorOctoFull.Length(f) ~= 11 and CuratorOctoFull.Length(f) ~= 12 then
		return nil
	end
	-- (1 November: its wear, a twelfth part: the tenth and the eleventh read as before; a titanforged copy, its
	-- certificate of the mages the eleventh, Mages.lua, its wear then maybe empty)
	local wear, cert
	if CuratorOctoFull.Length(f) == 12 then
		local tag = f[10]
		if CuratorOctoFull.Match(tag, "^p%d+$") and f[11] ~= "" then
			cert = ns.Mages and ns.Mages.Unpack(f[11])
			if not cert then
				return nil
			end
		end
		if f[12] ~= "" or not cert then
			wear = ns.Wear and ns.Wear.Unpack and ns.Wear.Unpack(f[12])
			if not wear then
				return nil
			end
		end
		if CuratorOctoFull.Match(tag, "^k%d+$") then
			f[10] = string.sub(tag, 2)
			f[12] = nil
		elseif CuratorOctoFull.Match(tag, "^p%d+$") then
			f[10] = string.sub(tag, 2)
			f[11], f[12] = nil, nil
		elseif tag == "" and f[11] == "" then
			f[10], f[11], f[12] = nil, nil, nil
		else
			return nil
		end
	end
	local rec = {}
	local g, hg = From36(f[1]), From36(f[5])
	if g and g >= 100 and g <= 1000 then
		rec.g = g
		rec.m = CuratorOctoFull.Match(f[2], "^[1-9A][1-9A][1-9A][1-9A]$") and f[2] or nil
		rec.ce = From36(f[3])
		rec.sl = f[4] ~= "0"
	end
	if hg and hg >= 100 and hg <= 1000 then
		rec.hg = hg
	end
	local rs = {}
	for part in CuratorOctoFull.Gmatch(f[6], "[^+]+") do
		local t, d, a = CuratorOctoFull.Match(part, "^([0-9a-z]+)%-([1-4])%-([0-9a-z]+)$")
		t, d, a = From36(t), tonumber(d), From36(a)
		if t and d and a and a <= 1000 and CuratorOctoFull.Length(rs) < 9 then
			rs[CuratorOctoFull.Length(rs) + 1] = { t, d, a }
		end
	end
	if CuratorOctoFull.Length(rs) > 0 then
		rec.r = rs
	end
	if CuratorOctoFull.Length(f) == 11 then
		-- (1.14.0: a corrupted copy, its corruption and its seal; never appraised nor restored)
		local k = CuratorOctoFull.Match(f[10], "^%d%d?%d?$") and tonumber(f[10])
		if not (k and k >= 1 and k <= 100) or rec.g or rec.hg or rec.r then
			return nil
		end
		rec.cor = k
		if f[11] ~= "" then
			local rank, marks, pact, t, by = CuratorOctoFull.Match(f[11], "^(%d%d?)%-([1-9A][1-9A][1-9A][1-9A])%-([0-9a-z]+)%-([0-9a-z]+)%-(.*)$")
			rank, pact, t = tonumber(rank), From36(pact), From36(t)
			if not (rank and rank >= 1 and rank <= 10 and pact and t and CuratorOctoFull.Length(by) <= 40) then
				return nil
			end
			rec.seal = { g = rank, s = marks, c = pact, t = t, by = by ~= "" and by or nil }
		end
	elseif CuratorOctoFull.Length(f) == 10 then
		-- (1.14.0: a titanforged copy, its pattern; with it, its expertise and its restorations, if any)
		local pt = CuratorOctoFull.Match(f[10], "^[1-9]%d?%d?%d?%d?$") and PatternNo(f[10])
		if not pt then
			return nil
		end
		rec.pt = pt
	elseif not (rec.g or rec.hg or rec.r) then
		return nil
	end
	local w = CuratorOctoFull.Match(f[8], "^%a$")
	rec.o = { t = From36(f[7]) or 0, w = w, ch = f[9] ~= "" and string.sub(f[9], 1, 24) or nil }
	if wear then
		rec.wv, rec.wq, rec.w0, rec.wx, rec.wa, rec.hm = wear.wv, wear.wq, wear.w0, wear.wx, wear.wa, wear.hm
	end
	if cert and rec.pt then
		rec.tc = cert
	end
	return rec
end

-------------------------------------------------------------------------------
-- The collections of before 1.13.0: their copies, once
-------------------------------------------------------------------------------
-- The lines of the journal of each card and finish ("<npc>:<finish>"), the oldest first.
local function JournalIndex()
	local idx = {}
	local C = ns.Collection
	for _, line in ipairs(type(ns.db.journal) == "table" and ns.db.journal or {}) do
		local l = C:JournalLine(line)
		if l and l.npc and l.how ~= "q" then
			local k = l.npc .. ":" .. (FK(l.f) or "")
			idx[k] = idx[k] or {}
			CuratorOctoFull.Insert(idx[k], l)
		end
	end
	for _, list in pairs(idx) do
		table.sort(list, function(a, b)
			return (a.t or 0) < (b.t or 0)
		end)
	end
	return idx
end

function CP:Migrate()
	local db = ns.db
	if not db or db.copiesV == 1 then
		return false
	end
	local all = self:Db()
	local idx = JournalIndex()
	for key, e in pairs(db.cards) do
		local card = ns.Cards[key]
		if card and Int(e.n) > 0 and type(all[key]) ~= "table" then
			local list = {}
			for _, k in ipairs(self.KEYS) do
				local fk = k or nil
				local want = self.Want(e, fk)
				local lines = card.npc and idx[card.npc .. ":" .. (fk or "")] or {}
				-- (the journal tells their story without doubt: as many lines as copies)
				local told = CuratorOctoFull.Length(lines) == want
				for j = 1, want do
					local rec = { i = self:NewId(), f = fk, w = "a" }
					local l = told and lines[j] or nil
					if l then
						rec.t, rec.w, rec.bn, rec.p = l.t, l.how or "a", l.booster, l.who
						if rec.t == 0 then
							rec.t = nil
						end
					end
					list[CuratorOctoFull.Length(list) + 1] = rec
				end
			end
			all[key] = list
		end
	end
	-- (the appraisals of before, one a card: on one of its copies, of the finish it had when appraised; a card with
	-- no copy now keeps it for its next copy)
	local graded = type(db.graded) == "table" and db.graded or {}
	local orphans = {}
	for key, x in pairs(graded) do
		local n = type(x) == "table" and Int(x.g) or 0
		if n >= 1 and n <= 10 and type(key) == "string" then
			local list = all[key]
			local spot
			for _, r in ipairs(type(list) == "table" and list or {}) do
				if not r.g and r.f ~= "c" then
					if r.f == FK(x.f) then
						spot = r
						break
					end
					spot = spot or r
				end
			end
			if spot then
				spot.g, spot.hg, spot.m, spot.ce, spot.at, spot.sl = n * 100, n * 100, x.s, tonumber(x.c), tonumber(x.t), true
			else
				orphans[key] = { g = n, s = x.s, c = x.c, t = x.t }
			end
		end
	end
	db.gradedOrphans = next(orphans) and orphans or nil
	db.graded = nil
	db.copiesV = 1
	for key in pairs(db.cards) do
		self:Reconcile(key)
	end
	ns.Fire("COPIES_CHANGED")
	return true
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function()
	if ns.db then
		CP:Migrate()
	end
end)

-- (Core.lua: the collection emptied) the copies go with the cards.
ns.On("COLLECTION_EMPTIED", function(db)
	if type(db) == "table" then
		db.copies, db.gradedOrphans, db.copiesV = nil, nil, 1
	end
	CP.expect, CP.back, CP.picked, CP.ctx = {}, {}, {}, nil
end)
