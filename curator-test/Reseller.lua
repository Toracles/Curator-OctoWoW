local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.12.0) The reseller, in the place of the antiquarian of 1.11.0. He stands at the vendors of general goods and
-- of trade supplies, and only there (Data/Resellers.lua: their ids, and the titles they go by in each language;
-- UI/Reseller.lua: his window, beside theirs). He sells cards of every album, any of them, drawn at random: RV.STOCK
-- a day (the day of the quests, 5:00 in Paris), drawn for each collection (the same all day long, whatever the
-- character), for rubies, and dear (RV.PRICE, by rarity); now and then forged (RV.FORGE_ODDS: thunderforged,
-- titanforged), and dearer then (RV.FINISH_X); never a card of an album of an event (a limited edition: Hallow.lua).
-- A card bought comes as a card found, in the journal as a card bought for rubies ("r", as the antiquarian's:
-- Collection.lua, Export.lua). He buys back what a collection holds, for next to nothing (RV.BUY, by rarity, more for a
-- forged copy; 1.14.0, a player's word: everything, its last copies too, below). (1.13.0) As many as the player wants (no limit a
-- day any more), copy by copy, from the inventory as the reseller sees it (UI/Inventory.lua: the copies he takes, a box
-- to tick on each); and dearer, what he sells: the sale of the copies has no limit now.
-- What is kept (db.resell, under the seal of the save): d (the day), got (the cards of the day bought: [i] = true),
-- paid (the rubies he paid that day), sold (the copies he bought back that day); the counters of ns.Stats:
-- resellBought, resold.
-------------------------------------------------------------------------------
local RV = {}
ns.Reseller = RV

RV.STOCK = 5
-- what a card costs, by rarity (common to mythic; 1.13.0: far dearer, the sale of the copies has no limit now: 240,
-- 500, 1200, 3000, 8000, 20000 before; after its second test, the economy redone: 600, 1500, 5000, 20000, 75000, 250000
-- before; then, the author in his game, dearer again: a card chosen worth more than a booster to choose, an epic card
-- two displays of a zone, a mythic card about a year of a fan; 800, 2000, 6000, 25000, 100000, 400000 for a while)
RV.PRICE = { 2000, 5000, 15000, 60000, 250000, 1000000 }
-- a card of the day forged, now and then: titanforged one time in 15, thunderforged one time in 5
RV.FORGE_ODDS = { holo = 1 / 15, shiny = 1 / 5 }
-- what a copy brings, by rarity; a forged copy, more (1.13.0, after its second test: five times as much, the economy redone;
-- 1, 2, 4, 10, 25, 60 before; past the guard of the week, a quarter of it: Rubies.lua, RB.GUARD)
RV.BUY = { 5, 10, 20, 50, 125, 300 }
-- (a forged card: what it costs, what a forged copy brings, so many times as much)
RV.FINISH_X = { shiny = 2, holo = 3, corrupt = 2 }
-- (1.13.0: no limit a day to what he pays any more; 50 rubies before)
RV.DAY_CAP = nil

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

-- The day of the quests (5:00 in Paris), as the inns count it.
function RV:Today()
	if ns.Inns and ns.Inns.Today then
		return ns.Inns:Today()
	end
	return math.floor(((GetServerTime and CuratorOctoFull.ServerTime()) or time()) / 86400)
end

-- The state of the day (a new day: a new one).
function RV:State()
	local db = ns.db
	if not db then
		return nil
	end
	local today = self:Today()
	local r = db.resell
	if type(r) ~= "table" or r.d ~= today then
		r = { d = today, got = {}, paid = 0, sold = 0 }
		db.resell = r
	end
	if type(r.got) ~= "table" then
		r.got = {}
	end
	r.paid = math.max(0, math.floor(tonumber(r.paid) or 0))
	r.sold = math.max(0, math.floor(tonumber(r.sold) or 0))
	return r
end

-------------------------------------------------------------------------------
-- What he sells
-------------------------------------------------------------------------------
-- Every card he can have: all the albums, those of an event aside (made once).
function RV:Pool()
	if not self.pool then
		local pool = {}
		for _, s in ipairs(ns.Series or {}) do
			-- (1.13.0: nor a limited edition, the Hardcup Saison 3: its cards come from a gift code only)
			if not s.event and not s.limited then
				for _, card in ipairs(s.list or {}) do
					pool[CuratorOctoFull.Length(pool) + 1] = card
				end
			end
		end
		self.pool = pool
	end
	return self.pool
end

-- A number of a text (the same text, the same number), for the draw of the day.
local M = 2147483647
local function Hash(text)
	local h = 7
	for i = 1, CuratorOctoFull.Length(text) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(text, i)) , M)
	end
	return h > 0 and h or 1
end

-- How many cards he has (1.14.0: Harbor Contacts, a talent of the Smuggler: more).
function RV:StockSize()
	local TL = ns.Talents
	return self.STOCK + ((TL and TL.ResellBonus) and TL:ResellBonus() or 0)
end

-- The cards of the day: drawn among all of them (Park and Miller), for this collection and this day.
function RV:Stock()
	local pool = self:Pool()
	local n = math.min(self:StockSize(), CuratorOctoFull.Length(pool))
	local id = (ns.Export and ns.Export.Id and ns.Export:Id()) or "curator"
	local day = self:Today()
	-- (1.14.0, Tip-off: one of them surely missing from the albums)
	local TL = ns.Talents
	local tip = TL ~= nil and TL.Has ~= nil and TL:Has("tip")
	local key = id .. ":" .. tostring(day) .. ":" .. n .. (tip and ":t" or "")
	if self.stockKey == key and self.stock then
		return self.stock
	end
	local x = Hash(key)
	-- (their finishes: drawn apart, the cards of the day the same as without them)
	local y = Hash(key .. ":forged")
	local out, seen, fin = {}, {}, {}
	local tries = 0
	while CuratorOctoFull.Length(out) < n and tries < n * 50 do
		tries = tries + 1
		x = CuratorOctoFull.Mod((x * 16807) , M)
		local card = pool[(CuratorOctoFull.Mod(x , CuratorOctoFull.Length(pool))) + 1]
		if card and not seen[card] then
			seen[card] = true
			out[CuratorOctoFull.Length(out) + 1] = card
			y = CuratorOctoFull.Mod((y * 16807) , M)
			local u = y / M
			local odds = self.FORGE_ODDS
			fin[CuratorOctoFull.Length(out)] = (u < odds.holo and "holo") or (u < odds.holo + odds.shiny and "shiny") or nil
		end
	end
	if tip and CuratorOctoFull.Length(out) > 0 then
		local any = false
		for _, card in ipairs(out) do
			if not ns.Collection:Owned(card) then
				any = true
				break
			end
		end
		if not any then
			-- (the last card of the day: one missing, drawn the same way all day)
			local miss = {}
			for _, card in ipairs(pool) do
				if not seen[card] and not ns.Collection:Owned(card) then
					miss[CuratorOctoFull.Length(miss) + 1] = card
				end
			end
			if CuratorOctoFull.Length(miss) > 0 then
				out[CuratorOctoFull.Length(out)] = miss[(CuratorOctoFull.Mod(Hash(key .. ":tip") , CuratorOctoFull.Length(miss))) + 1]
			end
		end
	end
	self.stock, self.stockFinish, self.stockKey = out, fin, key
	return out
end

-- The finish of a card of the day: "shiny" (thunderforged), "holo" (titanforged), or nil.
function RV:StockFinish(i)
	self:Stock()
	return self.stockFinish and self.stockFinish[i] or nil
end

-- What a card costs (forged: so many times as much; the talents can make it cheaper).
function RV:Price(card, finish)
	local base = card and (self.PRICE[card.rarity or 1] or self.PRICE[1]) or 0
	base = base * (self.FINISH_X[finish or "normal"] or 1)
	-- (1.14.0, Shrewd Negotiator: his forged cards cheaper)
	local TL = ns.Talents
	if TL and TL.ResellPrice then
		base = math.floor(base * TL:ResellPrice(finish) + 0.5)
	end
	return ns.Rubies and ns.Rubies:Price(base, "resell") or base
end

-- Whether a card of the day can be bought: true, or false and why ("closed", "card": not one of his, "sold":
-- bought already, "rubies").
function RV:CanBuy(i)
	if Closed() then
		return false, "closed"
	end
	local card = self:Stock()[i or 0]
	if not card then
		return false, "card"
	end
	local st = self:State()
	if not st then
		return false, "closed"
	end
	if st.got[i] then
		return false, "sold"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:Price(card, self:StockFinish(i)))) then
		return false, "rubies"
	end
	return true
end

-- A card of the day bought: into the collection, as a card found. True, the card and its price; or false and why.
function RV:Buy(i)
	local ok, why = self:CanBuy(i)
	if not ok then
		return false, why
	end
	local card = self:Stock()[i]
	local finish = self:StockFinish(i)
	local price = self:Price(card, finish)
	local paid, err = ns.Rubies:Spend(price, "resell")
	if not paid then
		return false, err
	end
	local st = self:State()
	st.got[i] = true
	local stats = ns.Stats()
	stats.resellBought = (tonumber(stats.resellBought) or 0) + 1
	local new = ns.Collection:Grant(card, finish, "r")
	ns.Fire("RESELL_BOUGHT", card, price, new, finish)
	return true, card, price, finish
end

-- (1.14.0, Profits) A card bought from the reseller: a part of its price back.
ns.On("RESELL_BOUGHT", function(_, price)
	local TL = ns.Talents
	if TL and TL:Has("profits") and (tonumber(price) or 0) > 0 then
		TL:Rubies(math.floor(price * TL:V("profits")), "profits")
	end
end)

-------------------------------------------------------------------------------
-- What he buys back
-------------------------------------------------------------------------------
-- (1.14.0, a player's word) He takes everything the collection holds: every copy (its finest, its last one, the one its
-- innkeeper signed, a corrupted one, a reliquary, a card of a limited edition), the cards of the cases, the cases
-- closed, their keys. Never what is not free: a copy at an enchanter, one that came in a trade not free yet (its
-- quarantine), one bought at the Bourse not free yet, one staked on a duel; nothing without the pass, nothing when
-- Curator is closed. (The inventory shows his duplicates first, and says when a copy is the last one of its card:
-- UI/Inventory.lua.)
RV.FINISHES = { "normal", "shiny", "holo", "corrupt" }
-- a card of a case, by its rank (Rare to Priceless; forged: RV.CASE_FINISH_X), a case closed, a key
RV.CASE_BUY = { 15, 40, 120, 400, 2500 }
RV.CASE_FINISH_X = { thunder = 2, titan = 3 }
RV.CASE_ITEM = 15
RV.KEY_ITEM = 63

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- Why a copy cannot be sold now (nil: it can): "away" (at an enchanter), "locked" (came in a trade, not free yet),
-- "staked" (on a duel), "market" (bought at the Bourse, not free yet).
function RV:Held(card, rec)
	local CP = ns.Copies
	if not (CP and card and rec) then
		return "copy"
	end
	local why = CP:Stuck(card.key, rec)
	if why then
		return why
	end
	local MK = ns.Market
	if MK and MK.Quarantined and MK:Quarantined(rec.i) then
		return "market"
	end
	return nil
end

-- The copies of a card he would take, in a finish.
function RV:Spare(card, finish)
	local CP = ns.Copies
	if not (CP and card) then
		return 0
	end
	local n = 0
	for _, r in ipairs(CP:Free(card.key, finish)) do
		if not self:Held(card, r) then
			n = n + 1
		end
	end
	return n
end

-- What a copy brings (its full price: past the guard of the week, a quarter of it, RV:OfferNow). (1.14.0: Patter, and
-- Receiver for a forged copy, talents of the Smuggler: more.)
function RV:Offer(card, finish)
	local base = card and (self.BUY[card.rarity or 1] or self.BUY[1]) or 0
	base = base * (self.FINISH_X[finish or "normal"] or 1)
	local TL = ns.Talents
	if TL and TL.ResellOffer then
		base = base * TL:ResellOffer(finish)
	end
	return ns.Rubies.LocalPrice(base)
end

-- (1.13.0, after its second test) What copies bringing n rubies at their full price pay now, the guard of the week taken
-- into account (Rubies.lua: RB:Guarded).
function RV:PaysNow(n)
	local RB = ns.Rubies
	return (RB and RB.Guarded) and RB:Guarded(n) or n
end

function RV:OfferNow(card, finish)
	return self:PaysNow(self:Offer(card, finish))
end

-- The rubies he can still pay today (1.13.0: no limit).
function RV:PayLeft()
	return CuratorOctoFull.Huge
end

-- Every copy he would take: { card, finish, n (the copies), offer (what one brings) }, those the collection
-- has the most of first, then the rarest.
function RV:Spares()
	local out = {}
	for _, s in ipairs(ns.Series or {}) do
		for _, card in ipairs(s.list or {}) do
			for _, finish in ipairs(self.FINISHES) do
				local n = self:Spare(card, finish)
				if n > 0 then
					out[CuratorOctoFull.Length(out) + 1] = { card = card, finish = finish, n = n, offer = self:Offer(card, finish), album = s }
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a.n ~= b.n then
			return a.n > b.n
		end
		if a.card.rarity ~= b.card.rarity then
			return a.card.rarity > b.card.rarity
		end
		return (a.card.key or "") < (b.card.key or "")
	end)
	return out
end

-- Whether he takes something now: true, or false and why ("closed"). (1.14.3, his word: no more pass of the app for
-- him, Pass.lua: the Exchange alone asks for it.)
function RV:Open()
	if Closed() then
		return false, "closed"
	end
	return true
end

-- Whether he takes a copy of a card in a finish: true, or false and why ("closed", "copy": none free).
function RV:CanSell(card, finish)
	local ok, why = self:Open()
	if not ok then
		return false, why
	end
	if self:Spare(card, finish) <= 0 then
		return false, "copy"
	end
	if self:Offer(card, finish) <= 0 then
		return false, "copy"
	end
	return true
end

-- A copy sold: out of the collection, its rubies in. True and the rubies; or false and why. (1.13.0) id: the copy
-- sold (nil: the least precious free one).
function RV:Sell(card, finish, id)
	local ok, why = self:CanSell(card, finish)
	if not ok then
		return false, why
	end
	-- (1.14.0: the card changed by another addon this session: nothing sold; Guard.lua)
	if ns.Guard and not (ns.Guard:Allow(card.series, card) and ns.Guard:AllowAll()) then
		return false, "guard"
	end
	local CP, MK = ns.Copies, ns.Market
	if not (CP and MK and MK.TakeOut and ns.Collection:Entry(card)) then
		return false, "copy"
	end
	finish = finish or "normal"
	local rec
	id = tonumber(id)
	if id then
		rec = CP:Get(card.key, id)
		if not rec or (CP.Finish(rec) or "normal") ~= finish or self:Held(card, rec) then
			return false, "copy"
		end
	else
		for _, r in ipairs(CP:Free(card.key, finish)) do
			if not self:Held(card, r) then
				rec = r
				break
			end
		end
		if not rec then
			return false, "copy"
		end
	end
	-- (it leaves as a thing put on sale at the Bourse leaves: its counts, its corruption, its reliquary, its signature
	-- on another copy if there is one: Market.lua)
	if not MK.TakeOut({ k = "c", key = card.key, id = rec.i }) then
		return false, "copy"
	end
	-- (what it pays: its price, or a quarter of it past the guard of the week)
	local offer = ns.Rubies:Gain(self:Offer(card, finish), "resold")
	-- (1.14.0, Pawnbroker: the copy can be bought back at that price for 3 days; never a corrupted one, its corruption
	-- its own)
	if finish ~= "corrupt" then
		self:Pawned(card, finish, offer)
	end
	self:Sold(offer)
	-- (several sold at once: told once, at the end: RV:SellCopies)
	if not self.quiet then
		ns.Fire("RESOLD", card, finish, offer)
		ns.Fire("CHANGED")
	end
	return true, offer
end

-- What a sale counts: the rubies of the day, the copies sold.
function RV:Sold(offer)
	local st = self:State()
	st.paid = st.paid + (offer or 0)
	st.sold = st.sold + 1
	local stats = ns.Stats()
	stats.resold = (tonumber(stats.resold) or 0) + 1
end

-- Every copy of a card he takes in a finish, while he pays: how many went, and the rubies.
function RV:SellAll(card, finish)
	local n, rubies = 0, 0
	while self:CanSell(card, finish) do
		local ok, got = self:Sell(card, finish)
		if not ok then
			break
		end
		n, rubies = n + 1, rubies + (got or 0)
	end
	return n, rubies
end

-------------------------------------------------------------------------------
-- (1.13.0) Thing by thing: the inventory as the reseller sees it (UI/Inventory.lua)
-------------------------------------------------------------------------------
-- The copies of a card he would take (can: [id] = true), and why each of the others stays (why: [id] = "away",
-- "locked", "staked", "market", "closed").
function RV:SellableCopies(card)
	local can, why = {}, {}
	local CP = ns.Copies
	if not (card and CP) then
		return can, why
	end
	local list = CP:List(card.key)
	local ok, w = self:Open()
	for _, r in ipairs(list) do
		local held = (not ok and w) or self:Held(card, r)
		if held then
			why[r.i] = held
		elseif self:Offer(card, CP.Finish(r) or "normal") > 0 then
			can[r.i] = true
		else
			why[r.i] = "copy"
		end
	end
	return can, why
end

-- What a copy brings (its finish: CP.Finish).
function RV:OfferFor(card, rec)
	local CP = ns.Copies
	return self:Offer(card, (CP and CP.Finish(rec)) or "normal")
end

-- (1.14.0, a player's word) A card of a case: what it brings (by its rank, more forged), why it stays (nil: he takes
-- it; "market": bought at the Bourse, not free yet).
function RV:CaseOffer(w)
	if type(w) ~= "table" then
		return 0
	end
	local tier = math.max(1, math.min(CuratorOctoFull.Length(self.CASE_BUY), math.floor(tonumber(w.r) or 1)))
	if w.w then
		tier = CuratorOctoFull.Length(self.CASE_BUY)
	end
	local base = self.CASE_BUY[tier] * (self.CASE_FINISH_X[w.f or ""] or 1)
	local TL = ns.Talents
	if TL and TL.ResellOffer then
		base = base * TL:ResellOffer((w.f == "thunder" and "shiny") or (w.f == "titan" and "holo") or "normal")
	end
	return ns.Rubies.LocalPrice(base)
end

function RV:CaseHeld(w)
	if type(w) ~= "table" then
		return "copy"
	end
	if w.mq and (tonumber(w.mq) or 0) > Now() then
		return "market"
	end
	-- (1 November: at an enchanter, Restore.lua)
	if type(w.aw) == "table" then
		return "away"
	end
	return nil
end

-- The cases closed of an edition, the keys, he takes: how many (those bought at the Bourse not free yet stay).
function RV:FreeCases(case)
	local MK = ns.Market
	if MK and MK.FreeCases then
		return MK:FreeCases(case)
	end
	return ns.Cases and ns.Cases:Count(case) or 0
end

function RV:FreeKeys(case)
	return ns.Cases and ns.Cases:Keys(case) or 0
end

-- What a thing of the inventory brings: { card, id } a copy, { won = id } a card of a case, { case = edition } a case,
-- { key = edition } a key.
function RV:ThingOffer(x)
	if type(x) ~= "table" then
		return 0
	end
	if x.card then
		local rec = ns.Copies and ns.Copies:Get(x.card.key, x.id)
		return rec and self:OfferFor(x.card, rec) or 0
	elseif x.won then
		local w = ns.Cases and ns.Cases:Card(x.won)
		return w and self:CaseOffer(w) or 0
	elseif x.case then
		return self.CASE_ITEM
	elseif x.key then
		return self.KEY_ITEM
	end
	return 0
end

-- One thing that is not a copy sold (a card of a case, a case, a key): true and the rubies, or false and why.
function RV:SellThing(x)
	local ok, why = self:Open()
	if not ok then
		return false, why
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard"
	end
	local CS, MK = ns.Cases, ns.Market
	if not (CS and MK and MK.TakeOut) then
		return false, "copy"
	end
	local offer
	if x.won then
		local w = CS:Card(x.won)
		if not w or self:CaseHeld(w) then
			return false, "copy"
		end
		offer = self:CaseOffer(w)
		if not MK.TakeOut({ k = "w", id = w.i }) then
			return false, "copy"
		end
	elseif x.case then
		if self:FreeCases(x.case) <= 0 or not MK.TakeOut({ k = "x", edition = x.case }) then
			return false, "copy"
		end
		offer = self.CASE_ITEM
	elseif x.key then
		if self:FreeKeys(x.key) <= 0 or not CS:MoveKeys(x.key, -1) then
			return false, "copy"
		end
		offer = self.KEY_ITEM
	else
		return false, "copy"
	end
	local got = ns.Rubies:Gain(offer, "resold")
	self:Sold(got)
	return true, got
end

-- Things sold ({ { card = card, id = its number } a copy, { won = id }, { case = edition }, { key = edition }, ... }):
-- each one he still takes goes, its rubies in; told once at the end. How many went, and the rubies.
function RV:SellCopies(list)
	local CP = ns.Copies
	local n, rubies = 0, 0
	if not CP or not self:Open() then
		return 0, 0
	end
	self.quiet = true
	local ok, err = pcall(function()
		for _, x in ipairs(type(list) == "table" and list or {}) do
			if x.card then
				local card, id = x.card, tonumber(x.id)
				local rec = card and id and CP:Get(card.key, id)
				if rec and self:SellableCopies(card)[id] then
					local done, got = self:Sell(card, CP.Finish(rec) or "normal", id)
					if done then
						n, rubies = n + 1, rubies + (got or 0)
					end
				end
			else
				local done, got = self:SellThing(x)
				if done then
					n, rubies = n + 1, rubies + (got or 0)
				end
			end
		end
	end)
	self.quiet = nil
	-- (1.14.0, Clearance: 20 copies or more at once, more for the whole lot)
	local TL = ns.Talents
	if n >= 20 and TL and TL:Has("liquidation") and rubies > 0 then
		local more = ns.Rubies:Gain(math.floor(rubies * TL:V("liquidation")), "resold")
		rubies = rubies + more
	end
	if n > 0 then
		ns.Fire("RESOLD_MANY", n, rubies)
		ns.Fire("CHANGED")
	end
	if not ok then
		error(err, 0)
	end
	return n, rubies
end

-------------------------------------------------------------------------------
-- (1.14.0) The talents of the Smuggler at the reseller: the copies he keeps for a while (Pawnbroker), the card of his
-- stall at his buying price (Baron of Booty Bay), the card he gives once a week (Special Delivery)
-------------------------------------------------------------------------------
RV.PAWN_TIME = 3 * 86400

-- The copies sold that can be bought back: { { k = card key, f = finish, p = what he paid, t = when } }, those of the
-- last 3 days.
function RV:Pawns()
	local db = ns.db
	if not db then
		return {}
	end
	local now = (GetServerTime and CuratorOctoFull.ServerTime()) or time()
	local list = type(db.pawn) == "table" and db.pawn or {}
	local out = {}
	for _, x in ipairs(list) do
		if type(x) == "table" and ns.Cards[x.k or ""] and now - (tonumber(x.t) or 0) < self.PAWN_TIME then
			out[CuratorOctoFull.Length(out) + 1] = x
		end
	end
	db.pawn = CuratorOctoFull.Length(out) > 0 and out or nil
	return out
end

function RV:Pawned(card, finish, paid)
	local TL = ns.Talents
	if not (TL and TL:Has("pawn") and card and ns.db) then
		return
	end
	local list = self:Pawns()
	list[CuratorOctoFull.Length(list) + 1] = { k = card.key, f = (finish ~= "normal" and finish) or nil, octoPrice = true, p = math.max(0, math.floor(tonumber(paid) or 0)),
		t = (GetServerTime and CuratorOctoFull.ServerTime()) or time() }
	-- (the last 30 at most)
	while CuratorOctoFull.Length(list) > 30 do
		CuratorOctoFull.Remove(list, 1)
	end
	ns.db.pawn = list
end

-- A copy bought back (its place in RV:Pawns). True and the card; false and why ("here", "card", "rubies").
function RV:BuyBackPrice(x)
    -- New pawn receipts already contain the revised price.
    return x.octoPrice and x.p or ns.Rubies.LocalPrice(x.p)
end

function RV:BuyBack(i)
	local list = self:Pawns()
	local x = list[i or 0]
	if not x then
		return false, "card"
	end
	if not self.here then
		return false, "here"
	end
	local card = ns.Cards[x.k]
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return false, "guard"
	end
	local paid, why = ns.Rubies:Spend(self:BuyBackPrice(x), "resell")
	if not paid then
		return false, why or "rubies"
	end
	CuratorOctoFull.Remove(list, i)
	ns.db.pawn = CuratorOctoFull.Length(list) > 0 and list or nil
	ns.Collection:Grant(card, x.f, "r")
	ns.Fire("CHANGED")
	return true, card
end

-- Baron of Booty Bay: a card of the stall (rare at most), once a week, at what he would pay for a copy of it.
function RV:BaronPrice(i)
	local card = self:Stock()[i or 0]
	if not card then
		return nil
	end
	local finish = self:StockFinish(i)
	local base = (self.BUY[card.rarity or 1] or self.BUY[1]) * (self.FINISH_X[finish or "normal"] or 1)
	return ns.Rubies.LocalPrice(base)
end

function RV:CanBaron(i)
	local TL = ns.Talents
	if not (TL and TL:Ready("baron")) then
		return false, "ready"
	end
	local card = self:Stock()[i or 0]
	if not card or card.rarity > 3 then
		return false, "card"
	end
	local st = self:State()
	if not st or st.got[i] then
		return false, "sold"
	end
	if not self.here then
		return false, "here"
	end
	if not ns.Rubies:Has(self:BaronPrice(i)) then
		return false, "rubies"
	end
	return true
end

function RV:Baron(i)
	local ok, why = self:CanBaron(i)
	if not ok then
		return false, why
	end
	local card, finish = self:Stock()[i], self:StockFinish(i)
	if ns.Guard and not ns.Guard:Allow(card.series, card) then
		return false, "guard"
	end
	local price = self:BaronPrice(i)
	local paid, err = ns.Rubies:Spend(price, "resell")
	if not paid then
		return false, err or "rubies"
	end
	self:State().got[i] = true
	local TL = ns.Talents
	TL:Use("baron")
	TL:Summit("baron")
	local new = ns.Collection:Grant(card, finish, "r")
	ns.Fire("RESELL_BOUGHT", card, price, new, finish)
	ns.Fire("TALENT_PROC", "baron", card)
	return true, card, price
end

-- Special Delivery: once a week, at the reseller, an uncommon card the collection misses (of the albums visited first).
function RV:Deliver()
	local TL = ns.Talents
	if not (TL and TL:Ready("delivery") and ns.db) then
		return nil
	end
	if ns.Guard and not ns.Guard:AllowAll() then
		return nil
	end
	local visited, any = {}, {}
	for _, card in ipairs(self:Pool()) do
		if card.rarity == 2 and not ns.Collection:Owned(card) then
			any[CuratorOctoFull.Length(any) + 1] = card
			if ns.db.visited and card.series and ns.db.visited[card.series.key] then
				visited[CuratorOctoFull.Length(visited) + 1] = card
			end
		end
	end
	local list = CuratorOctoFull.Length(visited) > 0 and visited or any
	if CuratorOctoFull.Length(list) == 0 then
		return nil
	end
	local card = list[math.random(CuratorOctoFull.Length(list))]
	TL:Use("delivery")
	ns.Collection:Grant(card, nil, "r")
	ns.Fire("TALENT_CARD", "delivery", card)
	ns.Fire("CHANGED")
	return card
end

ns.On("RESELLER", function(here)
	if here then
		RV:Deliver()
	end
end)

-------------------------------------------------------------------------------
-- Where he stands: a vendor of general goods or of trade supplies (by its id; else by the title the game gives it)
-------------------------------------------------------------------------------
local function NpcId(unit)
	if not UnitGUID then
		return nil
	end
	local ok, guid = pcall(UnitGUID, unit or "npc")
	if not ok or type(guid) ~= "string" then
		return nil
	end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind ~= "Creature" then
		return nil
	end
	return tonumber(id)
end
RV.NpcId = NpcId

-- The title of the vendor in its tooltip (the line under its name).
local tip
local function Title(unit)
	if not (CreateFrame and UnitExists and UnitExists(unit)) then
		return nil
	end
	if not tip then
		tip = CreateFrame("GameTooltip", "CuratorResellTip", nil, "GameTooltipTemplate")
	end
	tip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
	local ok = pcall(tip.SetUnit, tip, unit)
	if not ok then
		return nil
	end
	local fs = _G["CuratorResellTipTextLeft2"]
	local text = fs and fs:GetText() or nil
	tip:Hide()
	return text
end

-- A vendor of the kind given (ids: [npc] = faction; titles: by language), by its id, else by its title.
local function OfKind(unit, ids, titles)
	local id = NpcId(unit)
	if id and ids and ids[id] then
		return true
	end
	local title = titles and Title(unit)
	if title then
		title = string.gsub(string.gsub(string.gsub(title, "\194\160", " "), "^<", ""), ">$", "")
		for _, t in ipairs(titles[GetLocale and GetLocale() or "enUS"] or {}) do
			if title == t then
				return true
			end
		end
		for _, t in ipairs(titles.enUS or {}) do
			if title == t then
				return true
			end
		end
	end
	return false
end

-- A vendor of general goods (the vendor the window of the merchant is open with).
function RV:IsGeneralGoods(unit)
	return OfKind(unit or "npc", ns.GENERAL_GOODS, ns.GENERAL_GOODS_TITLES)
end

-- A vendor of trade supplies.
function RV:IsTradeGoods(unit)
	return OfKind(unit or "npc", ns.TRADE_GOODS, ns.TRADE_GOODS_TITLES)
end

-- A vendor where the reseller stands: of general goods, or of trade supplies.
function RV:IsHis(unit)
	return self:IsGeneralGoods(unit) or self:IsTradeGoods(unit)
end

-- (the window of a merchant: the reseller there or not, told to his window, UI/Reseller.lua)
local ev = CreateFrame and CreateFrame("Frame")
if ev then
	ev:RegisterEvent("MERCHANT_SHOW")
	ev:RegisterEvent("MERCHANT_CLOSED")
	CuratorOctoFull.SetScript(ev, "OnEvent", function(_, event)
		if not ns.db then
			return
		end
		if event == "MERCHANT_SHOW" then
			RV.here = RV:IsHis("npc")
			ns.Fire("RESELLER", RV.here)
		else
			if RV.here then
				RV.here = false
				ns.Fire("RESELLER", false)
			end
		end
	end)
end
