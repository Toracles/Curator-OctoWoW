local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0) The cards and their albums, kept from the other addons of the game. The definitions of the cards
-- (ns.Cards) and of their albums stay within reach of another addon through the widgets that show them (a frame
-- that shows a card keeps it, and the card its album): it could change a rarity, a creature, an album, a pool of a
-- booster, the places of an album, and Curator would give from what it then reads. What they must be is kept here,
-- out of reach: as the files of the albums wrote them (taken as those files load, this file right after them, before
-- any other addon can run), and as Curator built its cards from them (G:Take, at the loading of the save, after
-- C:Init: checked against the files). Curator checks it where it gives: an album and its cards before a booster of
-- it opens or its points come, a card before it comes (found, bought, won, given), and all of it before what the
-- player does (a contract, a trade, a reward claimed, a gift...), and on its own, a little at a time. Something
-- changed: Curator gives nothing more (no card, booster, point, experience nor ruby; a reward claimed stays to claim)
-- until the game loads its data again (/reload), and says so. Nothing is flagged, nothing of the collection is lost.
-- What is kept: of a card, the line of its album (its creature, its rarity in the file, type, family, levels, model,
-- sound, friendly) and what C:Init made of it (its key, its place, its album, its rarity, its creature of an event,
-- its picture); of an album, every field of its own that is no table (its key, kind, places, levels...), its levels,
-- its bosses, its pictures, its cards in their order and by rarity (the cards themselves); of ns.Cards, the card of
-- each key and no other; of ns.Series, the albums in their order. A table of these with a metatable is changed too
-- (what it says could then change from one reading to the next). The caches built once from them (the albums by key,
-- by place, the album achievements, the cards of the reseller) are built at G:Take, from what was just checked.
-------------------------------------------------------------------------------
local G = {}
ns.Guard = G

local type, pairs, ipairs, next, rawget, getmetatable, floor = type, pairs, ipairs, next, rawget, getmetatable, math.floor

-- The check on its own, a little at a time: a step every G.STEP seconds (an album, or G.KEYS_STEP keys of ns.Cards),
-- all of it in a few tens of seconds; no moment of the game waits on it.
G.STEP = 0.25
G.KEYS_STEP = 600
-- Between two lines of a gain refused in the chat (seconds).
G.SAY_EVERY = 60
-- What is said: the first time, then once in a while; and in short (a gain refused in a window).
G.TEXT = "Another addon changed the data of the cards of Curator during this session: Curator gives nothing more (cards, boosters, experience, rubies) until the game reloads (/reload). Turn off the addon that does it."
G.AGAIN = "Curator gives nothing until the game reloads (/reload): another addon changed the data of its cards."
G.SHORT = "Curator gives nothing until /reload: another addon changed its cards."

-- (a card is known by its album and its place in it: album * PLACES + place)
local PLACES = 65536

-- The fields Curator writes on an album for itself, which say nothing of what it gives: its name in this language
-- (C:SeriesName), its place in the contents of the album (UI/Album.lua). Never watched, whatever a file of an album
-- may have.
local OWN = { localName = true, order = true }

local function Scalar(v)
	local t = type(v)
	return t == "string" or t == "number" or t == "boolean"
end

local function Now()
	return (GetTime and GetTime()) or 0
end

local function Plain(t)
	return type(t) == "table" and getmetatable(t) == nil
end

local function Count(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

-------------------------------------------------------------------------------
-- What the files of the albums wrote, now (nothing of another addon has run since they loaded)
-------------------------------------------------------------------------------
-- RAW[i]: the album, its fields that are no table, its lines (each: its creature, its rarity in the file, type,
-- family, lowest level, highest level, model, sound, friendly, then its key once Curator made it), its levels, its
-- bosses, its pictures.
local RAW = {}
for i, s in ipairs(ns.Series or {}) do
	local r = { s = s, scalars = {}, keys = {}, rows = {}, hadCards = type(s.cards) == "table" }
	for k, v in pairs(s) do
		r.keys[k] = true
		if Scalar(v) and not OWN[k] then
			r.scalars[k] = v
		end
	end
	for j, row in ipairs(type(s.cards) == "table" and s.cards or {}) do
		r.rows[j] = { row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], false }
	end
	if type(s.levels) == "table" then
		r.levels = { s.levels[1], s.levels[2] }
	end
	if type(s.bosses) == "table" then
		r.bosses = {}
		for j, id in ipairs(s.bosses) do
			r.bosses[j] = id
		end
	end
	if type(s.pictures) == "table" then
		r.pictures = {}
		for k, v in pairs(s.pictures) do
			r.pictures[k] = v
		end
	end
	RAW[i] = r
end
-- (the fields an album can have that are no table: those of any album in its file, and those Curator gives them, whether
-- a dungeon, its creatures mostly elite; another one Curator writes for itself, its name in this language or its place
-- in the contents of the album, says nothing of what it gives)
local VOCAB = { dungeon = true, mostlyElite = true }
for _, r in ipairs(RAW) do
	for k in pairs(r.scalars) do
		VOCAB[k] = true
	end
end
for k in pairs(OWN) do
	VOCAB[k] = nil
end

-------------------------------------------------------------------------------
-- What they must stay (G:Take)
-------------------------------------------------------------------------------
local CARD = {}  -- [a card] = its album and its place (album * PLACES + place)
local ALBUM = {} -- [an album] = what counts of it
local MAP = {}   -- [a key] = the card ns.Cards gives for it
local COUNT = 0  -- the keys of ns.Cards
local taken = false
local broken     -- what was found changed (nil: nothing)
local saidAt

-- The rarity of a line of an album, as C:Init makes it (the dungeons and the raids have no common card).
local function Rarity(a, row)
	return (a.dungeon and row[2] < 3) and 3 or row[2]
end

-- A card as it must be.
local function CardOk(c)
	local code = CARD[c]
	if not code or not Plain(c) then
		return false
	end
	local i = floor(code / PLACES)
	local j = code - i * PLACES
	local r = RAW[i]
	local a = ALBUM[r.s]
	local row = r.rows[j]
	local npc = row[1]
	return rawget(c, "key") == row[10] and rawget(c, "npc") == npc and rawget(c, "rarity") == Rarity(a, row)
		and rawget(c, "base") == row[2] and rawget(c, "type") == row[3] and rawget(c, "family") == row[4]
		and rawget(c, "lo") == row[5] and rawget(c, "hi") == row[6] and rawget(c, "display") == row[7]
		and rawget(c, "sound") == row[8] and rawget(c, "friendly") == row[9] and rawget(c, "num") == j
		and rawget(c, "series") == r.s and rawget(c, "real") == (a.offset and (npc - a.offset) or nil)
		and rawget(c, "hkey") == (r.pictures and r.pictures[npc] or nil)
end

-- A list as it must be: the same values, in their order, and no more.
local function SameList(t, want)
	if not Plain(t) or CuratorOctoFull.Length(t) ~= CuratorOctoFull.Length(want) then
		return false
	end
	for i = 1, CuratorOctoFull.Length(want) do
		if rawget(t, i) ~= want[i] then
			return false
		end
	end
	return rawget(t, CuratorOctoFull.Length(want) + 1) == nil
end

-- A table of keys and values as it must be: the same ones, and no more.
local function SameMap(t, want, n)
	if not Plain(t) then
		return false
	end
	local count = 0
	for k, v in pairs(t) do
		if want[k] ~= v then
			return false
		end
		count = count + 1
	end
	return count == n
end

-- An album as it must be, its cards with it.
local function AlbumOk(s)
	local a = ALBUM[s]
	if not a or not Plain(s) then
		return false
	end
	for k, v in pairs(a.scalars) do
		if rawget(s, k) ~= v then
			return false
		end
	end
	-- (and no field more, whatever its value: a kind, a place, an event it had not; a table there too)
	for k in pairs(s) do
		if VOCAB[k] and not a.present[k] then
			return false
		end
	end
	-- (an album without cards: none built for it, none to come)
	if a.none then
		return rawget(s, "list") == nil and rawget(s, "byRarity") == nil
	end
	-- its cards, in their order: at each place, the card of that place, as it must be
	-- (no hole either: the length of a list is what a draw takes, # in Lua; cards put past a hole would count)
	local list = rawget(s, "list")
	if not Plain(list) or rawget(list, a.n + 1) ~= nil or CuratorOctoFull.Length(list) ~= a.n then
		return false
	end
	for j = 1, a.n do
		local c = rawget(list, j)
		if c == nil or CARD[c] ~= a.code + j or not CardOk(c) then
			return false
		end
	end
	-- by rarity: the cards of the album of each rarity, in their order, and no other
	local by = rawget(s, "byRarity")
	if not Plain(by) or rawget(by, CuratorOctoFull.Length(a.counts) + 1) ~= nil or CuratorOctoFull.Length(by) ~= CuratorOctoFull.Length(a.counts) then
		return false
	end
	local rows = RAW[a.i].rows
	for rr = 1, CuratorOctoFull.Length(a.counts) do
		local pool = rawget(by, rr)
		local n = a.counts[rr]
		if not Plain(pool) or rawget(pool, n + 1) ~= nil or CuratorOctoFull.Length(pool) ~= n then
			return false
		end
		local last = 0
		for k = 1, n do
			local c = rawget(pool, k)
			local code = c ~= nil and CARD[c] or nil
			local j = code and (code - a.code) or 0
			if j <= last or j > a.n or Rarity(a, rows[j]) ~= rr then
				return false
			end
			last = j
		end
	end
	if not SameMap(rawget(s, "bossSet"), a.bossSet, a.bossCount) then
		return false
	end
	if a.bosses and not SameList(rawget(s, "bosses"), a.bosses) then
		return false
	end
	if a.levels and not SameList(rawget(s, "levels"), a.levels) then
		return false
	end
	if a.pictures and not SameMap(rawget(s, "pictures"), a.pictures, a.pictureCount) then
		return false
	end
	return true
end

-- Everything as it must be: every album and its cards, ns.Cards, ns.Series.
local function AllOk()
	local series, cards = ns.Series, ns.Cards
	if not (Plain(series) and Plain(cards)) or rawget(series, CuratorOctoFull.Length(RAW) + 1) ~= nil or CuratorOctoFull.Length(series) ~= CuratorOctoFull.Length(RAW) then
		return false
	end
	for i, r in ipairs(RAW) do
		if rawget(series, i) ~= r.s or not AlbumOk(r.s) then
			return false
		end
	end
	for key, c in pairs(MAP) do
		if rawget(cards, key) ~= c then
			return false
		end
	end
	return Count(cards) == COUNT
end

-- Something was found changed: nothing more is given until the game reloads; said at once.
local function Break(what)
	if broken then
		return
	end
	broken = what or "?"
	saidAt = nil
	G:Say()
end

-------------------------------------------------------------------------------
-- At the loading of the save, once Curator built its cards (Core.lua, after C:Init)
-------------------------------------------------------------------------------
-- Checks what Curator built against what the files wrote, keeps it as what it must stay, and builds the caches made
-- once from them. True when all of it is as the files wrote it.
function G:Take()
	if taken then
		-- (the save loaded again in the same session: what was kept stays; checked again)
		if not broken and not AllOk() then
			Break("load")
		end
		return broken == nil
	end
	taken = true
	local bad
	for i, r in ipairs(RAW) do
		local s = r.s
		if ns.Series[i] ~= s then
			bad = bad or ("album " .. i)
		end
		-- (C:Init: a dungeon or a raid, its cards rare at least; an event, its creatures past its offset)
		local scalars = {}
		for k, v in pairs(r.scalars) do
			scalars[k] = v
		end
		if r.hadCards then
			scalars.dungeon = r.scalars.kind == "dungeon"
		end
		local a = {
			i = i, code = i * PLACES, n = CuratorOctoFull.Length(r.rows), scalars = scalars, dungeon = scalars.dungeon == true,
			offset = r.scalars.event and r.scalars.offset or nil, counts = {}, bossSet = {}, bossCount = 0,
			levels = r.levels, bosses = r.bosses, pictures = r.pictures, none = not r.hadCards, present = {},
		}
		for rr = 1, CuratorOctoFull.Length(ns.RARITY) do
			a.counts[rr] = 0
		end
		-- (its fields: those of its file, whatever their value, and the one C:Init gives it that counts; the caches'
		-- after them)
		for k in pairs(r.keys) do
			a.present[k] = true
		end
		if r.hadCards then
			a.present.dungeon = true
		end
		ALBUM[s] = a
		local list = rawget(s, "list")
		for j, row in ipairs(r.rows) do
			row[10] = "c" .. row[1]
			local c = type(list) == "table" and rawget(list, j) or nil
			local rr = Rarity(a, row)
			if a.counts[rr] then
				a.counts[rr] = a.counts[rr] + 1
			end
			if type(c) ~= "table" then
				bad = bad or (tostring(r.scalars.key) .. " " .. j)
			else
				CARD[c] = a.code + j
				if not CardOk(c) then
					bad = bad or row[10]
				end
				MAP[row[10]] = c
			end
		end
		for _, id in ipairs(r.bosses or {}) do
			if not a.bossSet[id] then
				a.bossSet[id] = true
				a.bossCount = a.bossCount + 1
			end
		end
		if r.pictures then
			a.pictureCount = Count(r.pictures)
		end
	end
	COUNT = Count(MAP)
	if not bad and not AllOk() then
		bad = "built"
	end
	-- (the caches built once from them, built now from what was just checked: the albums by key, by place and the
	-- creatures mostly elite of the dungeons, the album achievements, the cards of the reseller)
	if ns.SeriesByKey then
		ns.SeriesByKey("")
	end
	if ns.Rewards and ns.Rewards.Warm then
		ns.Rewards:Warm()
	end
	if ns.Achievements and ns.Achievements.Build then
		ns.Achievements:Build()
	end
	if ns.Reseller and ns.Reseller.Pool then
		ns.Reseller:Pool()
	end
	-- (what the caches wrote on the albums, once: kept as they are now, their fields that count; none other comes)
	for _, r in ipairs(RAW) do
		local a = ALBUM[r.s]
		for k, v in pairs(r.s) do
			if Scalar(v) and a.scalars[k] == nil and VOCAB[k] then
				a.scalars[k] = v
				a.present[k] = true
			end
		end
	end
	if bad then
		Break("files " .. bad)
	end
	return broken == nil
end

-------------------------------------------------------------------------------
-- The checks
-------------------------------------------------------------------------------
-- Whether Curator gives now. s: an album the gain comes from or goes to, card: a card that comes (each checked now,
-- with the cards of the album). False: said in the chat (and nothing more is given until the game reloads). (A trade
-- that settles, G:Trading: what the other player gave comes, its card and its album as they must be, whatever was
-- found changed before.)
function G:Allow(s, card)
	if not taken then
		return true
	end
	if broken and not self.trading then
		self:Say()
		return false
	end
	if s and not AlbumOk(s) then
		Break("album " .. tostring(rawget(s, "key")))
		return false
	end
	if card and not CardOk(card) then
		Break("card " .. tostring(rawget(card, "key")))
		return false
	end
	return true
end

-- Whether Curator gives now, everything checked (what the player does: a contract, a trade, a reward claimed...).
-- (Checked once a moment: the rewards claimed at once, a batch of them, are one check; fresh: checked again all the
-- same, before a draw among the cards.)
local allAt
function G:AllowAll(fresh)
	if not taken then
		return true
	end
	if broken then
		self:Say()
		return false
	end
	local now = Now()
	if allAt == now and not fresh then
		return true
	end
	if not AllOk() then
		Break("all")
		return false
	end
	allAt = now
	return true
end

-- Whether a card is as it must be (no line said).
function G:CardOk(card)
	return not taken or (card ~= nil and CardOk(card))
end

-- Whether nothing comes now: something was found changed, and no trade settles (G:Trading).
function G:Stopped()
	return broken ~= nil and not self.trading
end

-- A trade that settles (Trade.lua): what the other player gave comes and what I gave comes back, as they were, each
-- card and its album checked; nothing of a trade made is lost because something was found changed this session.
-- fn(...) run so; what it returns.
function G:Trading(fn, ...)
	local was = self.trading
	self.trading = true
	local out = { pcall(fn, unpack(arg, 1, arg.n)) }
	self.trading = was
	if not out[1] then
		error(out[2], 0)
	end
	return unpack(out, 2, table.maxn(out))
end

-- Whether something was found changed this session.
function G:Broken()
	return broken ~= nil
end

-- What was found changed (for the tests of the author).
function G:What()
	return broken
end

-- The gain refused, said: at once the first time, then once in a while.
function G:Say()
	local now = Now()
	if saidAt and now - saidAt < self.SAY_EVERY then
		return
	end
	local first = saidAt == nil
	saidAt = now
	if ns.Print then
		ns.Print("|cffff5a5a" .. (first and L[G.TEXT] or L[G.AGAIN]) .. "|r")
	end
	if first and UIErrorsFrame and UIErrorsFrame.AddMessage then
		pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, L[G.SHORT], 1, 0.35, 0.35)
	end
	-- (the build of the author: what was found changed, to tell it apart from a mistake of the check)
	if first and ns.Admin and ns.Print then
		ns.Print("|cff909090(Guard: " .. tostring(broken) .. ")|r")
	end
end

-- Now and then, everything checked on its own, a step at a time: the albums one by one, then the keys of ns.Cards a part at
-- a time, then the count of its keys and the end of ns.Series; then again.
local stepAt, stepKey = 0, nil
function G:Step()
	if not taken or broken then
		return
	end
	local n = CuratorOctoFull.Length(RAW)
	if stepAt < n then
		stepAt = stepAt + 1
		local r = RAW[stepAt]
		if not Plain(ns.Series) or CuratorOctoFull.Length(ns.Series) ~= n or rawget(ns.Series, stepAt) ~= r.s or not AlbumOk(r.s) then
			Break("step")
		end
		return
	end
	local cards = ns.Cards
	if not Plain(cards) then
		return Break("step")
	end
	for _ = 1, self.KEYS_STEP do
		local key, c = next(MAP, stepKey)
		if key == nil then
			-- (all the keys gone through: their count, the end of ns.Series; then again from the first album)
			if Count(cards) ~= COUNT or rawget(ns.Series, n + 1) ~= nil then
				Break("step")
			end
			stepAt, stepKey = 0, nil
			return
		end
		if rawget(cards, key) ~= c then
			return Break("step")
		end
		stepKey = key
	end
end

-- The steps it takes to check everything once.
function G:Steps()
	return CuratorOctoFull.Length(RAW) + math.ceil(COUNT / self.KEYS_STEP) + 1
end

-------------------------------------------------------------------------------
-- The test of the author (his build: /curator test guard)
-------------------------------------------------------------------------------
-- What another addon could do, done now: a common card of the album of the place (else of Elwynn) made mythic, in
-- memory only (the save keeps nothing of it). From the next gain on (a creature killed, a booster opened, a quest
-- turned in), or within a minute on its own, Curator says it and gives nothing; /reload: as before.
local FR = {
	["(Test: %s, a common card of the album %s, made mythic in memory, as another addon could do it. From now on Curator gives nothing: kill a creature, open a booster or wait a minute, it says so. /reload: back to normal, nothing of it is kept.)"] =
		"(Test : %s, une carte commune de l'album %s, rendue mythique en mémoire, comme pourrait le faire un autre addon. À partir de maintenant, Curator ne donne plus rien : tue une créature, ouvre un booster ou attends une minute, il le dit. /reload : tout redevient normal, rien n'en est gardé.)",
	["(Test: no common card to change here.)"] = "(Test : aucune carte commune à changer ici.)",
}
local function TT(k)
	return (GetLocale and GetLocale() == "frFR" and FR[k]) or k
end
G.TEST_TEXT = FR

function G:Test()
	local C = ns.Collection
	local s = ns.CurrentSeries and ns.CurrentSeries()
	local pool = s and s.byRarity and s.byRarity[1]
	if not (pool and pool[1]) then
		s = ns.SeriesByKey and ns.SeriesByKey("elwynn")
		pool = s and s.byRarity and s.byRarity[1]
	end
	local card = pool and pool[1]
	if not (card and C) then
		ns.Print(TT("(Test: no common card to change here.)"))
		return
	end
	card.rarity = CuratorOctoFull.Length(ns.RARITY)
	ns.Print(string.format(TT("(Test: %s, a common card of the album %s, made mythic in memory, as another addon could do it. From now on Curator gives nothing: kill a creature, open a booster or wait a minute, it says so. /reload: back to normal, nothing of it is kept.)"), C:Name(card), C:SeriesName(s)))
end

ns.On("LOGIN", function()
	if G.ticker or not (CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker) then
		return
	end
	G.ticker = CuratorOctoFull.Timer.NewTicker(G.STEP, function()
		G:Step()
	end)
end)
