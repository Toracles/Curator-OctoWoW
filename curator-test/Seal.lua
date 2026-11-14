local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.12.0) The corrupted cards and their masters. A corrupted card is never appraised (Expertise.lua): it belongs
-- to the masters of the classes (the trainers of the game, their window of dialogue open: Data/Trainers.lua).
-- * A Master of Warlocks seals one of its corrupted copies, once, for good, for rubies (by its rarity): he traces his
--   runes, gives a soul to the seal, binds it and shuts its shadow in, each rite a mark from I to X; the seal gets its
--   rank, the demon it would hold, from I (an imp would break it) to X (the Dark Titan himself would stay in), a X
--   rarely. The card is shut in its reliquary (UI/Card.lua: the case, in the look of the warlocks: UI/Seal.lua), its
--   pact written on it: its name, its album, its number, its corruption, its rank and its four marks, the number of
--   its pact and the name of its master. The sealed copy stays corrupted, and is never purified.
-- * A Master of Priests purifies a corrupted copy, for rubies (by its rarity and its corruption): a plain copy again
--   (it can then be traded, put in a contract, appraised...).
-- (1.13.0) Each corrupted copy can be sealed, the copies of a card one by one (Copies.lua: the copy of each seal): the
-- card shows its finest seal (its rank in the album, its reliquary, the showcase).
-- What is kept: db.sealed ([card key] = { { g = the rank, s = its four marks ("9A9A": A for X), c = the number of its
-- pact, k = the corruption of the copy sealed, t = when, by = its master, i = the copy (1.13.0) }, ... }; a save of
-- before 1.13.0: one seal, a list of one), with the save; the counters (ns.Stats: sealed, seal10, purified).
-------------------------------------------------------------------------------
local SL = {}
ns.Masters = SL

-- the price of a seal, by rarity (common to mythic): the expertise's and half again (1.13.0: twice as dear, as the
-- expertise; 45, 75, 135, 240, 420, 675 before; after its second test, the economy redone: 90, 150, 270, 480, 840, 1350)
SL.PRICE = { 750, 1200, 2250, 3750, 6750, 11250 }
-- the price of a purification: (10 + its corruption) times this, by rarity (1.13.0: twice as dear; after its second
-- test, eight times as dear again: 1, 1.5, 2, 3, 5, 8 before)
SL.PURIFY = { 8, 12, 16, 24, 40, 64 }
-- the chance of each rank (the best first)
SL.ODDS = { { 10, 0.04 }, { 9, 0.10 }, { 8, 0.18 }, { 7, 0.22 }, { 6, 0.18 }, { 5, 0.12 }, { 4, 0.08 }, { 3, 0.05 }, { 2, 0.02 }, { 1, 0.01 } }
SL.MAX = 10
SL.ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
-- the demon each rank would hold
SL.WORDS = {
	[1] = "Imp", [2] = "Voidwalker", [3] = "Succubus", [4] = "Felhunter", [5] = "Infernal",
	[6] = "Doomguard", [7] = "Dreadlord", [8] = "Pit Lord", [9] = "Eredar Lord", [10] = "Dark Titan",
}
-- the four rites of the warlock, in his order
SL.MARKS = { "Runes", "Soul", "Bindings", "Shadow" }
-- what the warlock says of his seal, by its rank
SL.SAYS = {
	[10] = "Even the Dark Titan would not break this seal. I have never bound anything so well.",
	[9] = "An eredar lord would rage against it in vain. A masterwork.",
	[8] = "A pit lord could not tear it open. The Void is caged for good.",
	[7] = "A dreadlord would whisper at it for ages, and it would hold.",
	[6] = "A doomguard could not break it. It will hold.",
	[5] = "Strong enough to hold an infernal. The Void stays inside.",
	[4] = "It would hold a felhunter. The Void hungers at it, but it holds.",
	[3] = "A succubus might charm her way out of it. Mind it.",
	[2] = "A voidwalker would lean on it all night. A modest seal.",
	[1] = "An imp could break it, if it tried. But it is sealed, and it is yours.",
}
-- the light of each rank: the fel of a X, the violet of a IX, the green of VII and VIII, the iron below
SL.COLORS = {
	[10] = { 0.6, 1, 0.3 }, [9] = { 0.78, 0.5, 1 }, [8] = { 0.45, 0.9, 0.42 }, [7] = { 0.4, 0.78, 0.4 },
}
SL.IRON = { 0.62, 0.64, 0.6 }

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

function SL:Db()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.sealed) ~= "table" then
		db.sealed = {}
	end
	return db.sealed
end

-- (1.13.0) The seals of a card (its key): { seal, ... } ({}: none). A seal of before 1.13.0, alone: a list of one.
function SL:Seals(key)
	local db = ns.db
	local g = key and db and type(db.sealed) == "table" and db.sealed[key]
	if type(g) ~= "table" then
		return {}
	end
	if g.g ~= nil then
		g = { g }
		db.sealed[key] = g
	end
	local out = {}
	for _, x in ipairs(g) do
		if type(x) == "table" and SL.Valid(x.g) then
			out[CuratorOctoFull.Length(out) + 1] = x
		end
	end
	return out
end

-- The record of a card sealed (nil: never sealed), and its rank: its finest seal (the newest of the same rank), or the
-- seal of one of its copies (id: its number, Copies.lua).
function SL:Record(card, id)
	if not card then
		return nil
	end
	local best, bn
	for _, x in ipairs(self:Seals(card.key)) do
		local n = SL.Valid(x.g)
		if id ~= nil then
			if x.i == id then
				return x, n
			end
		elseif not best or n > bn or (n == bn and (tonumber(x.t) or 0) > (tonumber(best.t) or 0)) then
			best, bn = x, n
		end
	end
	if id ~= nil then
		return nil
	end
	return best, bn
end

-- The corruption of the copy sealed of a card, its finest seal (nil: none).
function SL:Kept(card)
	local x = self:Record(card)
	return x and ns.Collection.Gauge(x.k) or nil
end

-- (1.13.0) The corruption of each copy sealed of a card ({}: none), the highest first.
function SL:KeptAll(card)
	local out = {}
	for _, x in ipairs(card and self:Seals(card.key) or {}) do
		out[CuratorOctoFull.Length(out) + 1] = ns.Collection.Gauge(x.k)
	end
	table.sort(out, function(a, b)
		return a > b
	end)
	return out
end

-- The rank of a card of the collection sealed (nil: none).
function SL:Rank(card)
	local x, n = self:Record(card)
	if not x or not ns.Collection:Owned(card) then
		return nil
	end
	return n
end

function SL.Valid(v)
	local n = tonumber(v)
	if n and n >= 1 and n <= SL.MAX and n == math.floor(n) then
		return n
	end
	return nil
end

function SL.Roman(g)
	return g and SL.ROMAN[g] or ""
end

function SL.Word(g)
	return g and SL.WORDS[g] and L[SL.WORDS[g]] or ""
end

function SL.Says(g)
	return g and SL.SAYS[g] and L[SL.SAYS[g]] or ""
end

function SL.Color(g)
	return (g and SL.COLORS[g]) or SL.IRON
end

-- "VII · Dreadlord", in the light of the rank.
function SL.Label(g)
	if not g then
		return ""
	end
	local c = SL.Color(g)
	return string.format(("|cff%02x%02x%02x%s · %s|r"), math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), SL.Roman(g), SL.Word(g))
end

-- "Runes IX · Soul VIII · Bindings IX · Shadow X".
function SL.MarksText(m)
	if type(m) ~= "table" or CuratorOctoFull.Length(m) ~= 4 then
		return ""
	end
	local out = {}
	for i, key in ipairs(SL.MARKS) do
		out[i] = string.format(("%s %s"), L[key], SL.Roman(m[i]))
	end
	return table.concat(out, "  ·  ")
end

function SL:Marks(card, id)
	local x = self:Record(card, id)
	return x and ns.Expertise.DecodeMarks(x.s) or nil
end

-------------------------------------------------------------------------------
-- The prices
-------------------------------------------------------------------------------
function SL:SealPrice(card)
	local base = self.PRICE[(card and card.rarity) or 1] or self.PRICE[1]
	-- (1.14.0, the Archivist: Family Seal, once a week for nothing; Pact of the Week, once a week at half its price)
	local TL = ns.Talents
	if TL and TL.Ready and TL:Ready("familyseal") then
		return 0
	end
	local price = ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "seal") or base
	if TL and TL.Ready and TL:Ready("weekpact") then
		price = math.max(1, math.ceil(price / 2))
	end
	return price
end

function SL:PurifyPrice(card, k)
	local f = self.PURIFY[(card and card.rarity) or 1] or self.PURIFY[1]
	local base = math.max(1, math.ceil((10 + ns.Collection.Gauge(k)) * f))
	return ns.Rubies and ns.Rubies.Price and ns.Rubies:Price(base, "purify") or base
end

-------------------------------------------------------------------------------
-- The masters
-------------------------------------------------------------------------------
-- What an NPC is for the corrupted cards: "warlock" (a Master of Warlocks), "priest" (a Master of Priests), nil. (1.14.0, 1
-- November, his idea: "mage", a Master of Mages, who certifies the titanforged cards: Mages.lua.)
function SL:Role(npc)
	if type(npc) ~= "number" then
		return nil
	end
	if ns.WARLOCK_MASTERS and ns.WARLOCK_MASTERS[npc] then
		return "warlock"
	end
	if ns.PRIEST_MASTERS and ns.PRIEST_MASTERS[npc] then
		return "priest"
	end
	if ns.MAGE_MASTERS and ns.MAGE_MASTERS[npc] then
		return "mage"
	end
	return nil
end

local ROLES = { warlock = true, priest = true, mage = true }

-- The master talked to now (role, his name, his number), or none.
function SL:SetMaster(role, name, npc)
	if not ROLES[role or ""] then
		role, name, npc = nil, nil, nil
	end
	npc = tonumber(npc)
	if self.master == role and self.masterName == name and self.masterNpc == npc then
		return
	end
	self.master, self.masterName, self.masterNpc = role, name, npc
	ns.Fire("MASTER_CHANGED", role)
end

function SL:AtMaster(role)
	return self.master ~= nil and self.master == role
end

-------------------------------------------------------------------------------
-- The corrupted copies
-------------------------------------------------------------------------------
-- The corrupted copies of a card not sealed: their corruption, the highest first ({}: none).
function SL:Copies(card)
	local e = card and ns.Collection:Entry(card)
	if not (e and e.n > 0) then
		return {}
	end
	return ns.Collection:CorruptCopies(e)
end

-- A copy not sealed at this corruption (k), or the most corrupted one: its corruption (nil: none).
function SL:Copy(card, k)
	local list = self:Copies(card)
	if k then
		k = ns.Collection.Gauge(k)
		for _, v in ipairs(list) do
			if v == k then
				return v
			end
		end
		return nil
	end
	return list[1]
end

-- A copy not sealed at that corruption taken out of the list (the card's corruption told again).
local function TakeCopy(card, k)
	local C = ns.Collection
	local e = C:Entry(card)
	local list = C:CorruptCopies(e)
	for i, v in ipairs(list) do
		if v == k then
			CuratorOctoFull.Remove(list, i)
			break
		end
	end
	C:SyncCorrupt(card, e)
end

-- Whether a corrupted copy of a card (k: its corruption; nil: the most corrupted) can be sealed now: true, or false
-- and why ("closed", "card": not one of the collection, "copy": no corrupted copy not sealed (at that corruption),
-- "master": not at a Master of Warlocks, "rubies"). (1.13.0: each corrupted copy can be sealed, the others of a card
-- sealed already or appraised.)
function SL:CanSeal(card, k)
	if Closed() then
		return false, "closed"
	end
	if not (card and ns.Collection:Owned(card)) then
		return false, "card"
	end
	if not self:Copy(card, k) then
		return false, "copy"
	end
	if not self:AtMaster("warlock") then
		return false, "master"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:SealPrice(card))) then
		return false, "rubies"
	end
	return true
end

-- Whether a corrupted copy (k; nil: the most corrupted) can be purified now: true, or false and why ("closed",
-- "card", "copy": no corrupted copy not sealed (at that corruption), "master": not at a Master of Priests, "rubies").
function SL:CanPurify(card, k)
	if Closed() then
		return false, "closed"
	end
	if not (card and ns.Collection:Owned(card)) then
		return false, "card"
	end
	local v = self:Copy(card, k)
	if not v then
		return false, "copy"
	end
	if not self:AtMaster("priest") then
		return false, "master"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:PurifyPrice(card, v))) then
		return false, "rubies"
	end
	return true
end

-- The weights of the ranks.
-- (1.14.0, Grand Seal, a talent of the Archivist: the ranks IX and X likelier)
function SL:Odds()
	local TL = ns.Talents
	local k = (TL and TL.V) and TL:V("grandseal") or 0
	if k <= 0 then
		return self.ODDS
	end
	local out, total = {}, 0
	for i, o in ipairs(self.ODDS) do
		local w = o[2] * (o[1] >= 9 and (1 + k) or 1)
		out[i] = { o[1], w }
		total = total + w
	end
	for _, o in ipairs(out) do
		o[2] = o[2] / total
	end
	return out
end

function SL:Draw(roll)
	local x = roll or math.random()
	local odds = self:Odds()
	for _, o in ipairs(odds) do
		x = x - o[2]
		if x < 0 then
			return o[1]
		end
	end
	return odds[CuratorOctoFull.Length(odds)][1]
end

-- (1.14.0) The rank a seal of a copy would get, seen before it is paid (Golden Loupe with Glance, talents of the
-- Archivist): kept for that copy until it is sealed (db.sealPeek: [card key .. corruption] = rank).
function SL:Peek(card, k)
	local TL = ns.Talents
	if not (TL and TL:Has("goldloupe") and TL:Ready("glance") and card and ns.db) then
		return nil
	end
	local v = self:Copy(card, k)
	if not v then
		return nil
	end
	ns.db.sealPeek = type(ns.db.sealPeek) == "table" and ns.db.sealPeek or {}
	local key = card.key .. ":" .. tostring(v)
	local g = tonumber(ns.db.sealPeek[key])
	if not g then
		g = self:Draw()
		ns.db.sealPeek[key] = g
	end
	TL:Use("glance")
	return g
end

-- The rank seen already for a copy with the Golden Loupe (nil: none seen).
function SL:Peeked(card, k)
	local peek = ns.db and ns.db.sealPeek
	local v = card and self:Copy(card, k)
	if type(peek) ~= "table" or not v then
		return nil
	end
	return tonumber(peek[card.key .. ":" .. tostring(v)])
end

-- A number of pact for a card (its key and the moment: eight digits).
local function PactFor(card)
	local h = 13
	local s = "seal:" .. (card.key or "") .. ":" .. tostring(CuratorOctoFull.ServerTime())
	for i = 1, CuratorOctoFull.Length(s) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(s, i)) , 99999989)
	end
	return CuratorOctoFull.Mod((h + math.random(0, 9999)) , 100000000)
end

-- A corrupted copy sealed, once: its rubies paid, its rank and its four marks drawn, its pact, its master. What it
-- did: { card, grade, marks, cert, corrupt, by, price } (nil and why, as CanSeal). (1.13.0) pick: the copy the player
-- chose (its number), when it is that corrupted copy not sealed.
function SL:Seal(card, k, pick)
	local ok, why = self:CanSeal(card, k)
	if not ok then
		return nil, why
	end
	local v = self:Copy(card, k)
	local price = self:SealPrice(card)
	local TL = ns.Talents
	local family = TL ~= nil and TL.Ready ~= nil and TL:Ready("familyseal")
	local pact = not family and TL ~= nil and TL.Ready ~= nil and TL:Ready("weekpact")
	if price > 0 then
		local paid, err = ns.Rubies:Spend(price, "seal")
		if not paid then
			return nil, err
		end
	end
	if family then
		TL:Use("familyseal")
	elseif pact then
		TL:Use("weekpact")
	end
	-- (1.14.0: the rank seen with the Golden Loupe, as it was seen)
	local peek = ns.db.sealPeek
	local pkey = card.key .. ":" .. tostring(v)
	local grade = type(peek) == "table" and tonumber(peek[pkey]) or nil
	if type(peek) == "table" then
		peek[pkey] = nil
		if not next(peek) then
			ns.db.sealPeek = nil
		end
	end
	grade = grade or self:Draw()
	-- (1.14.0, Sealed Pact: a rank more now and then)
	if TL and TL.Has and TL:Has("pact") and grade < self.MAX and math.random() < TL:V("pact") then
		grade = grade + 1
	end
	local marks = ns.Expertise:MarksFor(grade)
	local cert = PactFor(card)
	local by = self.masterName
	-- (1.13.0: the copy sealed, the one chosen, else the corrupted copy not sealed of that corruption: Copies.lua)
	local CP = ns.Copies
	local id
	local function Fits(r)
		return r.f == "c" and not r.ws and ns.Collection.Gauge(r.cor) == v
	end
	local chosen = pick ~= nil and CP and CP:Get(card.key, pick)
	if chosen and Fits(chosen) then
		id = chosen.i
	end
	for _, r in ipairs(not id and CP and CP:List(card.key) or {}) do
		if Fits(r) then
			id = r.i
			break
		end
	end
	local g = self:Db()
	local list = self:Seals(card.key)
	list[CuratorOctoFull.Length(list) + 1] = { g = grade, s = ns.Expertise.EncodeMarks(marks), c = cert, k = v, t = CuratorOctoFull.ServerTime(), by = by, i = id }
	g[card.key] = list
	TakeCopy(card, v)
	if CP then
		CP:Reconcile(card.key)
	end
	local st = ns.Stats()
	st.sealed = (tonumber(st.sealed) or 0) + 1
	if grade >= self.MAX then
		st.seal10 = (tonumber(st.seal10) or 0) + 1
	end
	local res = { card = card, grade = grade, marks = marks, cert = cert, corrupt = v, by = by, price = price, seal = true, id = id }
	ns.Fire("CARD_SEALED", res)
	ns.Fire("CHANGED")
	for _, sv in ipairs(ns.Collection:Showcase()) do
		if sv.card == card then
			ns.Fire("SHOWCASE_CHANGED")
			break
		end
	end
	return res
end

-- A corrupted copy purified (k; nil: the most corrupted): its rubies paid, a plain copy again. What it did:
-- { card, corrupt, price, left } (left: corrupted copies still; nil and why, as CanPurify). (1.13.0) pick: the copy the
-- player chose (its number), when it is that corrupted copy not sealed.
function SL:Purify(card, k, pick)
	local ok, why = self:CanPurify(card, k)
	if not ok then
		return nil, why
	end
	local v = self:Copy(card, k)
	local price = self:PurifyPrice(card, v)
	local paid, err = ns.Rubies:Spend(price, "purify")
	if not paid then
		return nil, err
	end
	TakeCopy(card, v)
	-- (1.13.0: the copy purified keeps its story, a plain copy now: Copies.lua)
	local id = ns.Copies and ns.Copies:Purified(card.key, v, pick) or nil
	local st = ns.Stats()
	st.purified = (tonumber(st.purified) or 0) + 1
	local e = ns.Collection:Entry(card)
	local res = { card = card, corrupt = v, price = price, left = e and (tonumber(e.c) or 0) or 0, purify = true, id = id }
	ns.Fire("CARD_PURIFIED", res)
	ns.Fire("CHANGED")
	return res
end

-- What the pact of a card sealed says (nil: never sealed): its rank, its demon, its marks, its pact, its corruption,
-- its master; for the case of the card (UI/Card.lua: Card:SetSlab, seal = true). id: the seal of that copy (1.13.0;
-- nil: its finest). (1.14.3) theirs: the seal of a copy of another player's inventory, as it came (Comm.lua).
function SL:LabelOf(card, id, theirs)
	local x, n
	if type(theirs) == "table" then
		x, n = theirs, SL.Valid(theirs.g)
		if not n then
			return nil
		end
	else
		x, n = self:Record(card, id)
	end
	if not x then
		return nil
	end
	local C = ns.Collection
	return {
		seal = true,
		grade = n,
		roman = SL.Roman(n),
		word = SL.Word(n),
		name = C:Name(card),
		album = C:SeriesName(card.series),
		num = string.format(("#%d/%d"), card.num or 0, CuratorOctoFull.Length((card.series and card.series.list or {}))),
		rarity = card.rarity,
		marks = ns.Expertise.DecodeMarks(x.s),
		cert = tonumber(x.c),
		corrupt = C.Gauge(x.k),
		by = type(x.by) == "string" and x.by or nil,
		color = SL.Color(n),
	}
end

-- (the records kept as they should be: anything else in their place goes; 1.13.0: the seals of a card in a list, a
-- seal of before alone in its list)
function SL:Mend()
	local db = ns.db
	local g = db and db.sealed
	if type(g) ~= "table" or self.mended == g then
		return
	end
	self.mended = g
	for key, list in pairs(g) do
		if type(list) == "table" and list.g ~= nil then
			list = { list }
		end
		local kept = {}
		for _, x in ipairs(type(key) == "string" and type(list) == "table" and list or {}) do
			local n = type(x) == "table" and math.floor(tonumber(x.g) or 0) or 0
			if n >= 1 and n <= self.MAX then
				x.g = n
				x.k = ns.Collection.Gauge(x.k)
				if not ns.Expertise.DecodeMarks(x.s) then
					x.s = ns.Expertise.EncodeMarks(ns.Expertise:MarksFor(n))
				end
				if not tonumber(x.c) then
					x.c = PactFor({ key = key })
				end
				if x.i ~= nil and not tonumber(x.i) then
					x.i = nil
				end
				kept[CuratorOctoFull.Length(kept) + 1] = x
			end
		end
		g[key] = CuratorOctoFull.Length(kept) > 0 and kept or nil
	end
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
-- (UI/Gossip.lua: a master in the window of dialogue)
ns.On("NPC_TALK", function(role, npc, name)
	if ROLES[role or ""] then
		SL:SetMaster(role, name, npc)
	end
end)
ns.On("NPC_LEFT", function()
	if not SL.training then
		SL:SetMaster(nil)
	end
end)

-- (the window of a trainer of the game: a warlock, a priest or a mage talking to his own master)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_CLOSED" }) do
			pcall(self.RegisterEvent, self, e)
		end
		SL:Mend()
	elseif event == "TRAINER_SHOW" then
		local npc = ns.Gossip and ns.Gossip:NpcId()
		local role = SL:Role(npc)
		if role then
			SL.training = true
			local name
			if UnitName then
				local ok, n = pcall(UnitName, "npc")
				if ok and type(n) == "string" and not (issecretvalue and issecretvalue(n)) then
					name = n
				end
			end
			SL:SetMaster(role, name, npc)
		end
	elseif event == "TRAINER_CLOSED" then
		if SL.training then
			SL.training = nil
			SL:SetMaster(nil)
		end
	end
end)

-- (Core.lua: the collection emptied) the seals go with the cards.
ns.On("COLLECTION_EMPTIED", function(db)
	if type(db) == "table" then
		db.sealed = nil
	end
end)
