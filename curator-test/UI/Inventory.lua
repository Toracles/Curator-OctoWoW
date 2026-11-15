local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin
local Hud = ns.Hud
local Ease = ns.Ease
local A = ns.Album
local C = ns.Collection
local CP = ns.Copies
local E = ns.Expertise
local SL = ns.Masters

-------------------------------------------------------------------------------
-- (1.13.0) The inventory, a tab of the album: every copy of the collection, each one the card it is (its finish, its
-- corruption, its signature; in its case when it was appraised, in its reliquary when it was sealed), its number among
-- its copies on a plate under it, what holds it across it (at an enchanter and for how long, signed, waiting after a
-- trade, put on a duel, its case opened). Under the mouse it rises and leans toward it, in 3D (one card for all of
-- them, over the one under the mouse: UI/Card.lua, Card:SetPose), its story in its tooltip; a click shows it big.
-- Filtered (the appraised ones, the restored ones, those at an enchanter, the forged ones, the forged ones certified by
-- a master of the mages (1 November), the corrupted ones, one card;
-- a rarity: the gems of the head of the window), sorted (the newest, the oldest, the rarest, the finest grade, by
-- album), page by page (the arrows, the wheel of the mouse).
-- (1.13.0, after its first test) The first tab of the album, where it opens (the minimap button, /curator): on its
-- boosters, the page of the boosters (UI/Boosters.lua: the booster of the place you are in, the others, the golden ones,
-- the displays, the boosters to choose, their odds, the gift codes), its tab gone; the bar of its filters over both
-- (IU:Bar): Boosters, then the copies.
-- (1.13.0, after its first test) The inventory as the reseller sees it (IU:OpenSeller: at the reseller only,
-- Reseller.lua): the copies he takes first, a box to tick on each, those that stay dimmed and why; what the copies
-- ticked bring; a button to tick every copy shown (of the filter, of the rarity, of the card), one to untick them;
-- Sell, then Confirm: the rubies fly to the purse. As many as the player wants. Leaving the merchant ends it.
-------------------------------------------------------------------------------
local IU = { filter = "all", sort = "new", page = 1 }
ns.InventoryUI = IU
-- (1.14.0) The copy each cell of the page shows ({ card, rec }): kept here, not on the cell, which another addon
-- reaches (EnumerateFrames): the copies are the save's own tables.
local ITEMS = setmetatable({}, { __mode = "k" })

-- What a cell shows ({ card, rec }; nil: nothing).
function IU:ItemOf(cell)
	return ITEMS[cell]
end

local GOLD = S.GOLD
local ARM = 3 -- (seconds) a first click on Sell arms it, a second one within confirms
local ARM_WARN = 6 -- (1.14.0) longer when the sale takes the last copy of a card out of the album
local RESELLER_ICON = "Interface\\Icons\\INV_Misc_Bag_10"

-- the grid: COLS x ROWS copies a page, small cards at K of their size, the plate of each under it; a copy in its case
-- smaller, its case in the room of a card (UI/Card.lua: ns.SlabRects, the case around a card)
local COLS, ROWS = 7, 3
local PER = COLS * ROWS
local SW, SH = ns.CARD_SIZES.small[1], ns.CARD_SIZES.small[2]
local K = 0.85
local CELL_W, CARD_H = SW * K, SH * K
local PLATE_H, PLATE_GAP = 15, 2
local CELL_H = CARD_H + PLATE_GAP + PLATE_H
local GAP_X, GAP_Y = 11, 9
local GRID_TOP = 30
local BOX = ns.SlabRects and ns.SlabRects(SW, SH) or { -SW * 0.58, -SH * 0.554, SW * 0.58, SH * 0.792 }
local KC = math.min(CELL_W / (BOX[3] - BOX[1]), CARD_H / (BOX[4] - BOX[2]))
-- (the middle of a case, over the middle of its card)
local CASE_DY = (BOX[2] + BOX[4]) / 2
-- the copy under the mouse: so much larger, so far leaning toward it (round its upright axis, toward its top)
local LIFT = 1.14
local LEAN_YAW, LEAN_PITCH = 0.5, 0.36
-- (1.13.0, after its first test) the bar of the filters, over the copies and over the page of the boosters: so high
local BAR_H = 30
IU.BAR_H = BAR_H
-- (1 November) the arrows of the pages at the foot of the album (UI/Album.lua: f.pager, 36 right of the middle, 67 wide):
-- how far right of the middle they reach, and a little room; the order of the copies stays on their right
local SORT_GAP = 78

local FILTERS = {
	-- (1 November, his word: « dans "TOUT" je veux qu'il soit en premier quand on clique sur "inventaire" et que y'a aussi
	-- les caisses et les clés dans "tout" vraiment je veux tout »: Everything first, where the inventory opens; what waits
	-- to be opened before the copies, the boosters, the displays, the cases, the keys: IU:AllItems, UI/CaseInventory.lua)
	{ key = "all", label = "Everything" },
	-- (the boosters: their own page under the bar, 1.13.0 after its first test)
	{ key = "packs", label = "Boosters" },
	-- (1.14.0: the cases and their keys, Cases.lua: their own pages, UI/CaseInventory.lua; no copy of the albums in them.
	-- The cards of the cases are among the copies: every copy, the appraised ones, the forged ones)
	{ key = "cases", label = "Cases" },
	{ key = "keys", label = "Keys" },
	{ key = "graded", label = "Appraised" },
	{ key = "restored", label = "Restored" },
	{ key = "away", label = "At an enchanter" },
	{ key = "forged", label = "Forged" },
	-- (1 November, his word: « avoir un onglet Forgé - Certifié »: the titanforged copies certified by a master of the
	-- mages, Mages.lua; the cards of the cases with them)
	{ key = "certified", label = "Forged - Certified" },
	{ key = "corrupt", label = "The corrupted ones" },
}
IU.FILTERS = FILTERS
local SORTS = { "new", "old", "rarity", "grade", "album" }
local SORT_LABEL = { new = "The newest first", old = "The oldest first", rarity = "The rarest first", grade = "The finest grade first",
	album = "By album" }

-- the ink of the number of a copy: of its finish; appraised, in its case; sealed, in its reliquary
local INK = { n = { 0.86, 0.86, 0.9 }, s = { 0.55, 0.78, 1 }, h = { 1, 0.8, 0.42 }, c = { 0.82, 0.58, 1 } }
local INK_GRADED, INK_SEALED = { 1, 0.93, 0.72 }, { 0.62, 1, 0.48 }
-- (the gem of its finish before its number: the gems of the finishes of the album, UI/Album.lua)
local FIN_GEM = { s = "Gem7", h = "Gem8", c = "GemCorrupt" }
local COUNT_HEX = "bfa873" -- (the counts of the filters)

-- what holds a copy, across its card: its word, its colour, its icon
local STATE = {
	away = { word = "At an enchanter", color = { 0.6, 0.85, 1 }, icon = MEDIA .. "RestoreCircle" },
	locked = { word = "Waits (a trade)", color = { 1, 0.72, 0.4 }, icon = MEDIA .. "Hourglass" },
	staked = { word = "On a duel", color = { 1, 0.55, 0.45 }, blades = true },
	signed = { word = "Signed", color = { 1, 0.86, 0.5 } },
	opened = { word = "Case opened", color = { 0.72, 0.86, 1 }, icon = MEDIA .. "CaseIcon" },
}
-- (the sell mode) why the reseller leaves a copy: in a word on its plate, in a line in its tooltip (said: by the
-- tooltip of the copy already, UI/Copies.lua). (1.14.0, a player's word: he takes everything, its finest copy, its
-- last one, a corrupted one, a signed one, a card of a limited edition; only what is not free stays.)
local STAYS = {
	away = { "At an enchanter", "At an enchanter: it cannot leave your album until it is back." },
	locked = { "Waits (a trade)", nil },
	staked = { "On a duel", nil },
	market = { "In quarantine", "Bought at the Exchange not long ago: it waits for the end of its quarantine." },
	closed = { "Curator is closed", "Curator is closed: nothing can be sold." },
	-- (1.14.0: no pass of the collection, Pass.lua: the line of the foot says why)
	pass = { "Needs the app", "Selling to the reseller needs the Curator app, linked to your Battle.net account on the website." },
	copy = { "Stays", nil },
}
IU.STAYS = STAYS
-- (1.14.0, a player's word: the last copy of a card, sold: the card leaves the album; said in orange)
local LAST = { 1, 0.55, 0.3 }
IU.LAST = LAST

local function Want(f, rec)
	if f == "graded" then
		return CP.Grade(rec) ~= nil and rec.sl ~= false
	elseif f == "restored" then
		return type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0
	elseif f == "away" then
		return CP.Away(rec)
	elseif f == "forged" then
		return rec.f == "s" or rec.f == "h"
	elseif f == "certified" then
		return rec.f == "h" and ns.Mages ~= nil and ns.Mages.Of(rec) ~= nil
	elseif f == "corrupt" then
		return rec.f == "c"
	elseif f == "cases" or f == "keys" then
		return false
	end
	return true
end
IU.Want = Want

local function Key(card, id)
	return card.key .. ":" .. tostring(id)
end

-- How a copy is drawn (the options of its card: its finish, its corruption, its signature), its case (appraised,
-- its case closed: Expertise.lua) or its reliquary (sealed: Seal.lua), and a word of all that (its card set again only
-- when it changes: setting it loads its creature again).
local function Look(card, rec)
	-- (1.14.0: a titanforged copy, its pattern, Patterns.lua)
	local opts = { owned = true, finish = CP.Finish(rec), corrupt = rec.f == "c" and tonumber(rec.cor) or nil, signed = rec.sg == true,
		pattern = CP.Pattern(rec), wear = ns.Wear and ns.Wear.Of(rec) or nil }
	local info
	-- (1.14.3: a copy of another player's inventory: the label of its case, of its reliquary, as it came, Comm.lua)
	local th = type(rec.theirs) == "table" and rec.theirs or nil
	if th then
		info = th.info
	elseif CP.Grade(rec) and rec.sl ~= false then
		info = E and E.LabelOf and E:LabelOf(card, nil, nil, nil, rec.i) or nil
	elseif rec.ws then
		info = SL and SL.LabelOf and SL:LabelOf(card, rec.i) or nil
	end
	local sig = table.concat({ card.key, tostring(rec.i), opts.finish or "n", tostring(opts.corrupt or 0), opts.signed and "1" or "0", tostring(opts.pattern or 0),
		info and ((info.seal and "s" or "g") .. tostring(info.grade) .. tostring(info.text or "") .. tostring(info.restored and CuratorOctoFull.Length(info.restored) or 0)) or "-" }, ":")
	return opts, info, sig
end

-- A card drawn as a copy (its creature loaded again only when it shows another). On a card this small, the label of
-- its case says its name and its grade only (the rest too small to be read, too long for its room).
local function Dress(c, card, rec)
	local opts, info, sig = Look(card, rec)
	if c.sig ~= sig then
		c.sig = sig
		c:SetCard(card, opts)
		c:ShowSide("front")
		c:SlabAlpha(1)
		c:SetSlab(info)
		local sl = info and c.slab
		if sl then
			for _, fs in ipairs({ sl.album, sl.marks, sl.cert, sl.word }) do
				fs:SetText("")
			end
		end
	end
	return info
end

-- Where the mouse is over a frame, from its middle: -1 to 1 across it, each way (more past its edges).
local function Offset(frame)
	local x, y = GetCursorPosition()
	local cx, cy = frame:GetCenter()
	local s = frame:GetEffectiveScale()
	if not (x and cx and s and s > 0) then
		return 0, 0
	end
	local w, h = frame:GetWidth() or 1, frame:GetHeight() or 1
	return (x / s - cx) / math.max(1, w / 2), (y / s - cy) / math.max(1, h / 2)
end

local function Clamp(v)
	return math.max(-1, math.min(1, v))
end

-- The portrait of the window: the reseller's bag while he looks at the inventory, the album's own otherwise.
local function Portrait(f, selling)
	if f.SetPortraitToAsset and f.invPortrait ~= (selling and true or false) then
		f.invPortrait = selling and true or false
		f:SetPortraitToAsset(selling and RESELLER_ICON or (MEDIA .. "Icon"))
	end
end

-------------------------------------------------------------------------------
-- What is shown
-------------------------------------------------------------------------------
-- (the sell mode) Whether the reseller takes a copy: true; or false and why (Reseller.lua: RV:SellableCopies, once a
-- card each time the inventory is painted).
function IU:Takes(card, rec)
	local RV = ns.Reseller
	if not (RV and RV.SellableCopies) then
		return false, "closed"
	end
	local cache = self.takes
	if not cache then
		cache = {}
		self.takes = cache
	end
	local t = cache[card.key]
	if not t then
		local can, why = RV:SellableCopies(card)
		t = { can = can or {}, why = why or {} }
		cache[card.key] = t
	end
	if t.can[rec.i] then
		return true
	end
	return false, t.why[rec.i] or "copy"
end

-- (1.14.0, a player's word) The finest copy of each card (the one that stays when its duplicates go: its finest finish,
-- the most precious, the oldest), and how many copies of each card there are.
local FIN_RANK = { c = 4, h = 3, s = 2 }
function IU:Keepers()
	local keeper, count = {}, {}
	for _, x in ipairs(CP:All()) do
		local k, r = x.card.key, x.rec
		count[k] = (count[k] or 0) + 1
		local b = keeper[k]
		if not b then
			keeper[k] = r
		else
			local fr, fb = FIN_RANK[r.f or ""] or 1, FIN_RANK[b.f or ""] or 1
			if fr ~= fb then
				if fr > fb then
					keeper[k] = r
				end
			else
				local vr, vb = CP.Value(r), CP.Value(b)
				if vr ~= vb then
					if vr > vb then
						keeper[k] = r
					end
				elseif (r.i or 0) < (b.i or 0) then
					keeper[k] = r
				end
			end
		end
	end
	return keeper, count
end

-- What the inventory shows now, in one pass over the copies: the copies of the filter, of the rarity and of the card
-- (lines, in the order asked; in the sell mode those he takes first), how many copies each filter has (of the rarity,
-- of the card), each rarity (of the filter, of the card); the sell mode: how many he takes of all of them.
function IU:Survey()
	local lines, chips, gems = {}, {}, {}
	for _, d in ipairs(FILTERS) do
		chips[d.key] = 0
	end
	for r = 1, CuratorOctoFull.Length(ns.RARITY) do
		gems[r] = 0
	end
	local sell = self.sell ~= nil
	local taken = 0
	local filter, rarity, only = self.filter, self.rarity, self.card
	-- (1.14.0, a player's word: the copies of one album, chosen at the head of the page, IU:AlbumMenu)
	local series = not only and self.series or nil
	-- (1.14.0, a player's word: the duplicates only, every copy but the finest of each card; the last copy of a card,
	-- unique: said at the reseller)
	local dupes = self.dupes and not only or false
	local keeper, count = self:Keepers()
	for _, x in ipairs(CP:All()) do
		local card, rec = x.card, x.rec
		x.dupe = keeper[card.key] ~= rec
		x.unique = (count[card.key] or 0) <= 1
		local shown = not dupes or x.dupe
		if sell and shown then
			x.takes = self:Takes(card, rec) and true or false
			if x.takes then
				taken = taken + 1
			end
		end
		if shown and (not only or card == only) and (not series or card.series == series) then
			local ofRarity = not rarity or card.rarity == rarity
			if ofRarity then
				for _, d in ipairs(FILTERS) do
					if d.key ~= "packs" and Want(d.key, rec) then
						chips[d.key] = chips[d.key] + 1
					end
				end
			end
			if Want(filter, rec) then
				gems[card.rarity] = (gems[card.rarity] or 0) + 1
				if ofRarity then
					lines[CuratorOctoFull.Length(lines) + 1] = x
				end
			end
		end
	end
	-- (1.14.0, after its first test: the cards of the cases, UI/CaseInventory.lua: x = { case = its record, rarity, grade,
	-- order, num, t, i })
	if self.AddCases and not series then
		taken = taken + (self:AddCases(lines, chips, filter, rarity, only, sell, dupes) or 0)
	end
	-- (1.14.0, a player's word: the cases closed and the keys he takes, UI/CaseInventory.lua)
	if sell and self.ItemsTaken then
		taken = taken + self:ItemsTaken()
	end
	-- (1 November, his word: « vraiment je veux tout »: Everything holds what waits to be opened too, before the copies,
	-- counted with them; never with a rarity, one card or the duplicates only; an album chosen, its boosters and its
	-- displays only. At the reseller, the cases and the keys one by one, as on their pages: UI/CaseInventory.lua)
	local items = (self.AllItems and not rarity and not only and not dupes) and self:AllItems(series, sell) or nil
	if items then
		chips.all = (chips.all or 0) + self:ItemCount(items)
	end
	local order = {}
	for i, s in ipairs(A.Order and A:Order() or ns.Series or {}) do
		order[s] = i
	end
	local function Rarity(x)
		return x.case and x.rarity or x.card.rarity
	end
	local function Grade(x)
		if x.case then
			return x.grade or 0
		end
		return CP.Grade(x.rec) or 0
	end
	local function Order(x)
		return x.case and x.order or (order[x.card.series] or 999)
	end
	local function Num(x)
		return x.case and x.num or (x.card.num or 0)
	end
	local sort = self.sort
	table.sort(lines, function(a, b)
		if sell and a.takes ~= b.takes then
			return a.takes
		end
		local ra, rb = a.rec or a.case, b.rec or b.case
		if sort == "rarity" and Rarity(a) ~= Rarity(b) then
			return Rarity(a) > Rarity(b)
		elseif sort == "grade" then
			local ga, gb = Grade(a), Grade(b)
			if ga ~= gb then
				return ga > gb
			end
		elseif sort == "album" and Order(a) ~= Order(b) then
			return Order(a) < Order(b)
		elseif sort == "album" and Num(a) ~= Num(b) then
			return Num(a) < Num(b)
		end
		local ta, tb = tonumber(ra.t) or 0, tonumber(rb.t) or 0
		if ta ~= tb then
			if sort == "old" then
				-- (the copies of before 1.13.0, of no date: first among the oldest)
				return ta < tb
			end
			return ta > tb
		end
		if sort == "old" then
			return (ra.i or 0) < (rb.i or 0)
		end
		return (ra.i or 0) > (rb.i or 0)
	end)
	if items and filter == "all" and CuratorOctoFull.Length(items) > 0 then
		for _, x in ipairs(lines) do
			items[CuratorOctoFull.Length(items) + 1] = x
		end
		lines = items
	end
	return { lines = lines, chips = chips, gems = gems, taken = taken }
end

-- The copies shown, in the order asked (every page).
function IU:Lines()
	return self:Survey().lines
end

-- What holds a copy now (nil: nothing, it is in the album and free): a key of STATE; at an enchanter, how long it
-- still waits there (0: ready).
function IU:State(card, rec)
	if CP.Away(rec) then
		local R = ns.Restore
		return "away", R and R.Left and R:Left(rec) or nil
	end
	if rec.sg then
		return "signed"
	end
	-- (1.14.3: another player's copy: nothing of mine holds it)
	local why = (not rec.theirs) and CP:Stuck(card.key, rec) or nil
	if why == "locked" or why == "staked" then
		return why
	end
	if CP.Grade(rec) and rec.sl == false then
		return "opened"
	end
	return nil
end

-- Where a copy is now, in a word, and its colour (nil: in the album, free).
function IU:Where(card, rec)
	local st, left = self:State(card, rec)
	local d = st and STATE[st]
	if not d then
		return nil
	end
	local text = L[d.word]
	if st == "away" and left then
		text = text .. " · " .. (left > 0 and ns.Duration(left) or L["Ready"])
	end
	return text, d.color
end

-------------------------------------------------------------------------------
-- The sell mode: the inventory as the reseller sees it
-------------------------------------------------------------------------------
function IU:Selling()
	return self.sell ~= nil
end

-- Opened at the reseller (his tab, what he buys back: UI/Reseller.lua): true; false when he is not there.
function IU:OpenSeller()
	local RV = ns.Reseller
	if not (RV and RV.here) then
		return false
	end
	A:Build()
	A:HideDetail()
	-- (1.14.0, a player's word: his duplicates first, the button over the copies shows every copy)
	self:Forget()
	if not self.sell then
		self.dupesBefore = self.dupes or false
		self.dupes = true
	end
	self.sell = self.sell or { picked = {} }
	self.takes = nil
	self.card, self.filter, self.page, self.rarity = nil, "all", 1, nil
	IU.ShowPage()
	if A.frame.Raise then
		A.frame:Raise()
	end
	return true
end

-- The sell mode ended (the reseller gone, the window closed, another page of the album; quiet: not painted again).
function IU:EndSell(quiet)
	if not self.sell then
		return
	end
	self.sell = nil
	self.takes = nil
	if self.dupesBefore ~= nil then
		self.dupes = self.dupesBefore or nil
		self.dupesBefore = nil
	end
	local f = A.frame
	if f then
		Portrait(f, false)
		if not quiet and f:IsShown() and A.mode == "inventory" then
			A:Refresh()
		end
	end
end

function IU:Ticked(card, rec)
	local s = self.sell
	return s ~= nil and s.picked[Key(card, rec.i)] ~= nil
end

-- A copy ticked, or no longer (on: nil, the other way); one he does not take is never ticked. True when it is done.
function IU:Tick(card, rec, on)
	local s = self.sell
	if not (s and card and rec) then
		return false
	end
	local k = Key(card, rec.i)
	if on == nil then
		on = s.picked[k] == nil
	end
	if on and not self:Takes(card, rec) then
		return false
	end
	s.picked[k] = on and { card = card, id = rec.i } or nil
	s.armed = nil
	return true
end

-- (1.14.0, a player's word) Anything of the inventory ticked: a copy, a card of a case, a case closed, a key. Its key
-- among those ticked, what is kept of it ({ card, id }; { won = its number }; { case = its edition, n }; { key, n }).
local function LineKey(x)
	if x.card and x.rec then
		return Key(x.card, x.rec.i)
	elseif x.case then
		return "w:" .. tostring(x.case.i)
	elseif x.item then
		return (x.item == "key" and "k:" or "x:") .. tostring(x.ed) .. ":" .. tostring(x.n)
	end
end
IU.LineKey = LineKey

local function LineEntry(x)
	if x.card and x.rec then
		return { card = x.card, id = x.rec.i }
	elseif x.case then
		return { won = x.case.i }
	elseif x.item == "key" then
		return { key = x.ed, n = x.n }
	elseif x.item == "case" then
		return { case = x.ed, n = x.n }
	end
end

function IU:LineTicked(x)
	local s = self.sell
	local k = s and x and LineKey(x)
	return k ~= nil and s.picked[k] ~= nil
end

-- A line ticked, or no longer (on: nil, the other way); one he does not take is never ticked.
function IU:TickLine(x, on)
	local s = self.sell
	local k = s and x and LineKey(x)
	if not k then
		return false
	end
	if on == nil then
		on = s.picked[k] == nil
	end
	if on and not x.takes then
		return false
	end
	s.picked[k] = on and LineEntry(x) or nil
	s.armed = nil
	return true
end

local function Order(x)
	if x.card then
		return string.format(("1%s:%08d"), x.card.key, x.id or 0)
	elseif x.won then
		return string.format(("2:%08d"), x.won)
	elseif x.case then
		return string.format(("3%s:%08d"), x.case, x.n or 0)
	end
	return string.format(("4%s:%08d"), tostring(x.key), x.n or 0)
end

-- What is ticked, still there and still taken (anything else unticked), in a fixed order; what it brings.
function IU:Picked()
	local s = self.sell
	local list, rubies = {}, 0
	if not s then
		return list, 0
	end
	local RV, CS = ns.Reseller, ns.Cases
	local open = RV:Open()
	local gone = {}
	for k, x in pairs(s.picked) do
		local ok = false
		if x.card then
			local rec = CP:Get(x.card.key, x.id)
			ok = rec ~= nil and self:Takes(x.card, rec)
		elseif x.won then
			local w = CS and CS:Card(x.won)
			ok = open and w ~= nil and not RV:CaseHeld(w)
		elseif x.case then
			ok = open and (x.n or 0) <= RV:FreeCases(x.case)
		elseif x.key then
			ok = open and (x.n or 0) <= RV:FreeKeys(x.key)
		end
		if ok then
			list[CuratorOctoFull.Length(list) + 1] = x
			rubies = rubies + RV:ThingOffer(x)
		else
			gone[CuratorOctoFull.Length(gone) + 1] = k
		end
	end
	for _, k in ipairs(gone) do
		s.picked[k] = nil
	end
	table.sort(list, function(a, b)
		return Order(a) < Order(b)
	end)
	-- (1.13.0, after its second test: what they pay now, the guard of the week taken into account)
	return list, RV:PaysNow(rubies)
end

-- (1.14.0, a player's word) The cards a sale takes out of the album (every copy left of them ticked): how many.
function IU:Losses(list)
	local per, perW = {}, {}
	local CS, CD = ns.Cases, ns.CaseDetail
	for _, x in ipairs(list or {}) do
		if x.card then
			per[x.card.key] = (per[x.card.key] or 0) + 1
		elseif x.won and CS and CD then
			local w = CS:Card(x.won)
			local d = w and CD.DescOf(w)
			if d then
				perW[d.key] = (perW[d.key] or 0) + 1
			end
		end
	end
	local n = 0
	for key, k in pairs(per) do
		if k >= CuratorOctoFull.Length(CP:List(key)) then
			n = n + 1
		end
	end
	if next(perW) then
		local total = {}
		for _, w in ipairs(CS:Won()) do
			local key = CD.DescOf(w).key
			total[key] = (total[key] or 0) + 1
		end
		for key, k in pairs(perW) do
			if k >= (total[key] or 0) then
				n = n + 1
			end
		end
	end
	return n
end

-- Everything shown he takes, ticked (of the filter, of the rarity, of the card: on every page): how many more.
function IU:TickAll()
	if not self.sell then
		return 0
	end
	local n = 0
	for _, x in ipairs(self.lines or self:Survey().lines) do
		if x.takes and not self:LineTicked(x) and self:TickLine(x, true) then
			n = n + 1
		end
	end
	return n
end

-- (1.14.0, a player's word) Every copy of the page shown he takes, ticked: how many more.
function IU:TickPage()
	if not self.sell then
		return 0
	end
	local lines = self.lines or self:Survey().lines
	local first = ((self.page or 1) - 1) * PER
	local n = 0
	for i = first + 1, math.min(CuratorOctoFull.Length(lines), first + PER) do
		local x = lines[i]
		if x and x.takes and not self:LineTicked(x) and self:TickLine(x, true) then
			n = n + 1
		end
	end
	return n
end

-- (1.14.0, a player's word) The albums of the head of the page: all of them, or one only (those that hold copies,
-- with how many), in the order of the contents.
function IU:AlbumMenu(root)
	local function Choose(s)
		self.series, self.page = s, 1
		ns.Play(ns.SND.click)
		A:Refresh()
	end
	root:CreateRadio(L["All albums"], function()
		return self.series == nil
	end, function()
		Choose(nil)
	end)
	if root.SetScrollMode then
		root:SetScrollMode(400)
	end
	local have = {}
	local who = self:Who()
	if who then
		-- (1.14.3: another player's inventory: the albums they started, as their summaries tell; else every album)
		local G, any = ns.Guild, false
		for _, s in ipairs(A.Order and A:Order() or ns.Series or {}) do
			local sum = G:Summary(who, s)
			if sum and (tonumber(sum.o) or 0) > 0 then
				have[s], any = true, true
			end
		end
		if not any then
			for _, s in ipairs(A.Order and A:Order() or ns.Series or {}) do
				have[s] = true
			end
		end
	else
		for _, x in ipairs(CP:All()) do
			local s = x.card and x.card.series
			if s then
				have[s] = (have[s] or 0) + 1
			end
		end
	end
	for _, s in ipairs(A.Order and A:Order() or ns.Series or {}) do
		local _, s = _, s; if have[s] then
			root:CreateRadio(who and C:SeriesName(s) or string.format(L["%s (%d)"], C:SeriesName(s), have[s]), function(x)
				return self.series == x
			end, function(x)
				Choose(x)
			end, s)
		end
	end
end

function IU:Untick()
	if self.sell then
		self.sell.picked = {}
		self.sell.armed = nil
	end
end

-- The duplicates he takes now (every copy but the finest of each card), of the whole collection, and what they would
-- bring (his tab: UI/Reseller.lua).
function IU:Taken()
	local RV = ns.Reseller
	if not (RV and RV.SellableCopies) then
		return 0, 0
	end
	local keeper = self:Keepers()
	local n, rubies = 0, 0
	local seen = {}
	for _, x in ipairs(CP:All()) do
		local card = x.card
		local can = seen[card.key]
		if not can then
			can = RV:SellableCopies(card) or {}
			seen[card.key] = can
		end
		if keeper[card.key] ~= x.rec and can[x.rec.i] then
			n = n + 1
			rubies = rubies + RV:OfferFor(card, x.rec)
		end
	end
	return n, RV:PaysNow(rubies)
end

-- Sold: a first click arms the button, a second one within confirms. Then the copies ticked go (Reseller.lua:
-- RV:SellCopies), their rubies fly from them to the purse. True, how many, the rubies; or false.
function IU:Sell()
	local s = self.sell
	local RV = ns.Reseller
	local f = A.frame
	if not (s and RV and RV.here and f) or (ns.Beta and ns.Beta:Blocked()) then
		return false
	end
	local list = self:Picked()
	local b = f.invFoot and f.invFoot.sell
	if CuratorOctoFull.Length(list) == 0 then
		ns.Play(ns.SND.close)
		return false
	end
	if not (s.armed and GetTime() - s.armed < (s.armWait or ARM)) then
		s.armed = GetTime()
		-- (1.14.0, a player's word: the last copies of cards in it, said, and longer to confirm)
		s.lost = self:Losses(list)
		s.armWait = s.lost > 0 and ARM_WARN or ARM
		ns.Play(s.lost > 0 and ns.SND.warning or ns.SND.click)
		self:PaintSell()
		if b and b:IsMouseOver() then
			self:SellTooltip(b)
		end
		return false, "armed"
	end
	s.armed, s.lost, s.armWait = nil, nil, nil
	-- (the rubies leave from what is ticked on the page: where it is, while it is still on it)
	local from = {}
	for _, cell in ipairs(f.inv and f.inv.cells or {}) do
		local x = cell:IsShown() and ITEMS[cell]
		if x and CuratorOctoFull.Length(from) < 12 and self:LineTicked(x) then
			local px, py = Hud.Where((x.card and cell.card) or cell)
			if px then
				from[CuratorOctoFull.Length(from) + 1] = { px, py }
			end
		end
	end
	local copies = true
	for _, x in ipairs(list) do
		copies = copies and x.card ~= nil
	end
	local n, got = RV:SellCopies(list)
	self.takes = nil
	if (n or 0) <= 0 then
		ns.Play(ns.SND.close)
		A:Refresh()
		return false
	end
	s.picked = {}
	GameTooltip:Hide()
	ns.Play(ns.SND.coins)
	local RUI = ns.RubiesUI
	local glow = RUI and RUI.GLOW or { 1, 0.25, 0.32 }
	local to = f.wallet and f.wallet.gem
	if CuratorOctoFull.Length(from) == 0 and b then
		for i = 1, math.min(n, 6) do
			from[i] = b
		end
	end
	if to then
		for i, c in ipairs(from) do
			Hud.Fly(ns.Rubies.ICON, c, to, 22, 0.55, nil, glow, (i - 1) * 0.045)
		end
	end
	if b then
		Hud.Burst(b, glow, 16, 110, 14)
	end
	ns.Print(copies and L["Sold to the reseller: %d copies, for %s."] or L["Sold to the reseller: %d items, for %s."], n, ns.Rubies.Text(got or 0))
	A:Refresh()
	return true, n, got
end

function IU:SellTooltip(owner)
	local s = self.sell
	if not s then
		return
	end
	local list, rubies = self:Picked()
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	GameTooltip:AddLine(L["Sell to the reseller"], 1, 1, 1)
	-- (1.14.3, his word: no more pass of the app for the reseller, Reseller.lua)
	if CuratorOctoFull.Length(list) == 0 then
		GameTooltip:AddLine(L["Tick the copies to sell him."], 0.8, 0.8, 0.8, true)
	else
		GameTooltip:AddLine(string.format(L["%d ticked · he pays %s"], CuratorOctoFull.Length(list), ns.Rubies.Text(rubies, 13)), 1, 0.82, 0.25)
		-- (1.14.0, a player's word: the last copies of cards, said)
		local lost = self:Losses(list)
		if lost > 0 then
			GameTooltip:AddLine(string.format(L["Warning: %d cards will leave your album (their last copy)."], lost), LAST[1], LAST[2], LAST[3], true)
		end
		if s.armed and GetTime() - s.armed < (s.armWait or ARM) then
			GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
		else
			GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
		end
	end
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- A copy on the page: its card, its plate, what holds it, its box to tick
-------------------------------------------------------------------------------
local function Place(cell)
	cell:ClearAllPoints()
	cell:SetPoint("TOPLEFT", cell:GetParent(), "TOPLEFT", cell.bx + (cell.dx or 0), cell.by + (cell.dy or 0))
end

-- Its card at its place: at K, or in its case at KC, its case in the middle of the room of a card.
local function Seat(cell, cased)
	cased = cased and true or false
	if cell.cased == cased and cell.k then
		return
	end
	local c = cell.card
	local k = cased and KC or K
	cell.k, cell.cased = k, cased
	c:SetScale(k)
	c:ClearAllPoints()
	c:SetPoint("CENTER", cell, "TOP", 0, (-CARD_H / 2 - (cased and CASE_DY * KC or 0)) / k)
end

-- Where its card is in the cell (from its top left, downward): left, top, width, height; its case instead (case).
local function Rect(cell, case)
	local k = cell.k or K
	local cy = CARD_H / 2 + (cell.cased and CASE_DY * KC or 0)
	if case and cell.cased then
		return CELL_W / 2 + BOX[1] * k, cy - BOX[4] * k, (BOX[3] - BOX[1]) * k, (BOX[4] - BOX[2]) * k
	end
	local w, h = SW * k, SH * k
	return (CELL_W - w) / 2, cy - h / 2, w, h
end

local function NewCell(page, i, x0)
	local cell = CreateFrame("Button", nil, page)
	CuratorOctoFull.SetSize(cell, CELL_W, CELL_H)
	cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	cell.i = i
	cell.col, cell.row = CuratorOctoFull.Mod((i - 1) , COLS), math.floor((i - 1) / COLS)
	cell.bx, cell.by = x0 + cell.col * (CELL_W + GAP_X), -GRID_TOP - cell.row * (CELL_H + GAP_Y)
	cell.dx, cell.dy = 0, 0
	Place(cell)
	local c = ns.NewCard(cell, "small")
	c:EnableMouse(false)
	c.shadow:SetAlpha(0.6)
	cell.card = c
	Seat(cell, false)
	local lvl = c:GetFrameLevel()
	-- what holds it: a band across its card, its word (and how long), the colour of what it is
	local band = CreateFrame("Frame", nil, cell)
	band:SetFrameLevel(lvl + 20)
	band.bg = band:CreateTexture(nil, "BACKGROUND")
	band.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(band.bg, 0.02, 0.02, 0.04, 0.84)
	band.top = band:CreateTexture(nil, "BORDER")
	band.top:SetPoint("TOPLEFT")
	band.top:SetPoint("TOPRIGHT")
	band.top:SetHeight(1)
	band.bottom = band:CreateTexture(nil, "BORDER")
	band.bottom:SetPoint("BOTTOMLEFT")
	band.bottom:SetPoint("BOTTOMRIGHT")
	band.bottom:SetHeight(1)
	band.icon = band:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(band.icon, 12, 12)
	-- (a duel: two blades of light crossed)
	band.blades = {}
	for k, a in ipairs({ 0.785, -0.785 }) do
		local b = band:CreateTexture(nil, "ARTWORK", nil, 1)
		b:SetTexture(MEDIA .. "Streak")
		b:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(b, 5, 15)
		CuratorOctoFull.SetRotation(b, a)
		b:Hide()
		band.blades[k] = b
	end
	band.text = band:CreateFontString(nil, "OVERLAY")
	ns.SetFont(band.text, 9)
	band.text:SetShadowOffset(1, -1)
	band.text:SetShadowColor(0, 0, 0, 1)
	CuratorOctoFull.SetWordWrap(band.text, false)
	band.sub = band:CreateFontString(nil, "OVERLAY")
	ns.SetFont(band.sub, 8.5)
	band.sub:SetShadowOffset(1, -1)
	band.sub:SetShadowColor(0, 0, 0, 1)
	CuratorOctoFull.SetWordWrap(band.sub, false)
	band:Hide()
	cell.band = band
	-- its plate, under it: its number among its copies; in the sell mode, what it brings or why it stays
	local plate = CreateFrame("Frame", nil, cell)
	plate:SetFrameLevel(lvl + 20)
	plate:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, -(CARD_H + PLATE_GAP))
	CuratorOctoFull.SetSize(plate, CELL_W, PLATE_H)
	plate.edge = plate:CreateTexture(nil, "BACKGROUND")
	plate.edge:SetAllPoints()
	plate.bg = plate:CreateTexture(nil, "BACKGROUND", nil, 1)
	plate.bg:SetPoint("TOPLEFT", 1, -1)
	plate.bg:SetPoint("BOTTOMRIGHT", -1, 1)
	CuratorOctoFull.ColorTexture(plate.bg, 0.045, 0.04, 0.035, 0.94)
	plate.lit = plate:CreateTexture(nil, "BORDER")
	plate.lit:SetPoint("TOPLEFT", 1, -1)
	plate.lit:SetPoint("TOPRIGHT", -1, -1)
	plate.lit:SetHeight(1)
	CuratorOctoFull.ColorTexture(plate.lit, 1, 1, 1, 0.07)
	plate.gem = plate:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(plate.gem, 11, 11)
	plate.gem:Hide()
	plate.label = plate:CreateFontString(nil, "OVERLAY")
	ns.SetFont(plate.label, 10)
	plate.label:SetShadowOffset(1, -1)
	plate.label:SetShadowColor(0, 0, 0, 1)
	CuratorOctoFull.SetWordWrap(plate.label, false)
	plate.why = plate:CreateFontString(nil, "OVERLAY")
	ns.SetFont(plate.why, 9)
	plate.why:SetPoint("CENTER", 0, 0)
	CuratorOctoFull.SetWordWrap(plate.why, false)
	plate.why:SetTextColor(0.92, 0.56, 0.5)
	plate.why:SetShadowOffset(1, -1)
	plate.why:SetShadowColor(0, 0, 0, 1)
	local RUI = ns.RubiesUI
	plate.tag = RUI and RUI.Tag and RUI.Tag(plate, 11, 9.5, "OVERLAY") or nil
	if plate.tag then
		plate.tag:SetPoint("RIGHT", plate, "RIGHT", -4, 0)
		plate.tag:Hide()
	end
	cell.plate = plate
	-- its box to tick (the sell mode), over the corner of its card; over the card that rises too
	local t = CreateFrame("Frame", nil, cell)
	CuratorOctoFull.SetSize(t, 18, 18)
	t.level = lvl + 22
	t:SetFrameLevel(t.level)
	-- (a box edged in gold, dark inside; lit under the mouse)
	t.shade = t:CreateTexture(nil, "BACKGROUND")
	t.shade:SetTexture(MEDIA .. "Shadow")
	t.shade:SetPoint("TOPLEFT", -6, 5)
	t.shade:SetPoint("BOTTOMRIGHT", 8, -9)
	t.shade:SetAlpha(0.8)
	t.edge = t:CreateTexture(nil, "BORDER")
	t.edge:SetAllPoints()
	CuratorOctoFull.ColorTexture(t.edge, 0.95, 0.8, 0.46, 0.95)
	t.box = t:CreateTexture(nil, "ARTWORK")
	t.box:SetPoint("TOPLEFT", 2, -2)
	t.box:SetPoint("BOTTOMRIGHT", -2, 2)
	CuratorOctoFull.ColorTexture(t.box, 0.06, 0.05, 0.04, 0.92)
	t.lit = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.lit:SetPoint("TOPLEFT", 2, -2)
	t.lit:SetPoint("BOTTOMRIGHT", -2, 2)
	CuratorOctoFull.ColorTexture(t.lit, 1, 0.86, 0.5, 0.22)
	t.lit:Hide()
	t.check = t:CreateTexture(nil, "OVERLAY")
	t.check:SetTexture(MEDIA .. "Check")
	CuratorOctoFull.SetSize(t.check, 27, 27)
	t.check:SetPoint("CENTER", 3, 4)
	t.check:Hide()
	t:Hide()
	cell.tick = t
	CuratorOctoFull.SetScript(cell, "OnEnter", function(self)
		IU:Enter(self)
	end)
	CuratorOctoFull.SetScript(cell, "OnLeave", function(self)
		IU:Leave(self)
	end)
	CuratorOctoFull.SetScript(cell, "OnClick", function(self, button)
		IU:Click(self, button)
	end)
	return cell
end

-- The box to tick at the top right of its card (of its case); a little further out while its card rises.
local function PlaceTick(cell, raised)
	local x, y, w = Rect(cell, true)
	local t = cell.tick
	local out = raised and 5 or 0
	t:ClearAllPoints()
	t:SetPoint("CENTER", cell, "TOPLEFT", x + w - 7 + out, -(y + 7) + out)
end

-- What holds a copy, across its card (nil: nothing).
local function PaintBand(cell, st, left)
	local band = cell.band
	local d = st and STATE[st]
	cell.hasBand = d ~= nil
	if not d then
		band:Hide()
		return
	end
	local x, y, w, h = Rect(cell)
	local c = d.color
	local two = st == "away" and left ~= nil
	local bh = two and 24 or 14
	band:ClearAllPoints()
	band:SetPoint("TOPLEFT", cell, "TOPLEFT", x + 2, -(y + h * 0.76 - bh / 2))
	CuratorOctoFull.SetSize(band, w - 4, bh)
	CuratorOctoFull.ColorTexture(band.top, c[1], c[2], c[3], 0.75)
	CuratorOctoFull.ColorTexture(band.bottom, c[1], c[2], c[3], 0.75)
	local room = w - 8
	local icon = d.icon ~= nil or d.blades
	CuratorOctoFull.SetShown(band.icon, d.icon ~= nil)
	if d.icon then
		band.icon:SetTexture(d.icon)
		band.icon:SetVertexColor(st == "away" and 0.7 or 1, st == "away" and 0.9 or 1, 1)
	end
	for _, b in ipairs(band.blades) do
		CuratorOctoFull.SetShown(b, d.blades == true)
		b:SetVertexColor(c[1], c[2], c[3])
	end
	if icon then
		room = room - 13
	end
	S.Fit(band.text, L[d.word], room, 9, 6.5)
	band.text:SetTextColor(c[1], c[2], c[3])
	-- (the icon and its word, together in the middle)
	local tw = math.min(room, ns.TextWidth(band.text))
	local lead = (w - 4 - tw - (icon and 13 or 0)) / 2
	band.text:ClearAllPoints()
	band.icon:ClearAllPoints()
	if icon then
		band.icon:SetPoint("LEFT", band, "TOPLEFT", lead, -7)
		for _, b in ipairs(band.blades) do
			b:ClearAllPoints()
			b:SetPoint("CENTER", band, "TOPLEFT", lead + 6, -7)
		end
		band.text:SetPoint("LEFT", band, "TOPLEFT", lead + 13, -7)
	else
		band.text:SetPoint("LEFT", band, "TOPLEFT", lead, -7)
	end
	CuratorOctoFull.SetShown(band.sub, two)
	if two then
		local ready = left <= 0
		S.Fit(band.sub, ready and L["Ready"] or ns.Duration(left), w - 8, 8.5, 6.5)
		if ready then
			band.sub:SetTextColor(0.45, 1, 0.45)
		else
			band.sub:SetTextColor(0.86, 0.92, 1)
		end
		band.sub:ClearAllPoints()
		band.sub:SetPoint("CENTER", band, "TOP", 0, -17)
	end
	CuratorOctoFull.SetShown(band, not (IU.lensCell == cell))
end

-- A copy on the page (x: { card, rec }; nil: none), as it is; in the sell mode, its box, what it brings, why it stays.
function IU:PaintCell(cell, x)
	ITEMS[cell] = x
	CuratorOctoFull.SetShown(cell, x ~= nil)
	-- (1.14.0, after its first test: a card of a case risen under the mouse, no longer there; after its second test, its
	-- lens put away)
	if self.caseHover == cell and not (x and x.case) then
		self.caseHover = nil
	end
	if self.caseLensCell == cell and not (x and x.case) and self.LeaveCase then
		self:LeaveCase(cell)
	end
	-- (1.14.0, a player's word: a case, a key, in its slot: UI/CaseInventory.lua; a copy there now, its slot put away)
	if cell.slot and self.HideSlot and not (x and x.item) then
		self:HideSlot(cell)
	end
	if not x then
		-- (a card hidden lets go of its creature: set again when it shows)
		cell.card.sig = nil
		return
	end
	if x.item then
		return self:PaintItemCell(cell, x)
	end
	-- (1.14.0, after its first test: a card of a case, its own small card: UI/CaseInventory.lua)
	if x.case then
		return self:PaintCaseCell(cell, x)
	end
	if cell.crate then
		cell.crate:Hide()
	end
	cell.card:Show()
	local card, rec = x.card, x.rec
	local c = cell.card
	local _, info = Look(card, rec)
	Seat(cell, info ~= nil)
	Dress(c, card, rec)
	local st, left = self:State(card, rec)
	local sell = self.sell ~= nil
	local takes, why
	if sell then
		takes, why = self:Takes(card, rec)
	end
	cell.takes, cell.why = takes, why
	-- (away at an enchanter, it is not here: dimmed a little; in the sell mode, a copy he leaves: dimmed)
	cell.alpha = (sell and not takes and 0.34) or (st == "away" and 0.62) or 1
	if self.lensCell ~= cell then
		c:SetAlpha(cell.alpha)
	end
	PaintBand(cell, st, left)
	-- its plate
	local plate = cell.plate
	local ink = (info and info.seal and INK_SEALED) or (info and INK_GRADED) or INK[rec.f or "n"] or INK.n
	plate.label:SetText(ns.CopiesUI:Label(card, rec))
	-- (1.14.0, a player's word: at the reseller, the last copy of a card said: sold, the card leaves the album)
	if sell and takes and x.unique then
		plate.label:SetText(L["Last one"])
		ink = LAST
	end
	plate.label:SetTextColor(ink[1], ink[2], ink[3])
	plate.label:ClearAllPoints()
	local tag = plate.tag
	local stays = sell and not takes
	local word = stays and (STAYS[why or "copy"] or STAYS.copy) or nil
	-- (a copy that stays for what its band says: its number; for anything else, why)
	local sayWhy = word ~= nil and not cell.hasBand
	CuratorOctoFull.SetShown(plate.why, sayWhy)
	CuratorOctoFull.SetShown(plate.label, not sayWhy)
	if sayWhy then
		S.Fit(plate.why, L[word[1]], CELL_W - 8, 9, 7)
	end
	if tag then
		CuratorOctoFull.SetShown(tag, sell and takes and true or false)
		if sell and takes then
			tag:SetAmount(ns.Reseller:PaysNow(ns.Reseller:OfferFor(card, rec)), true)
		end
	end
	-- (the gem of its finish before its number)
	local gem = FIN_GEM[rec.f or ""]
	CuratorOctoFull.SetShown(plate.gem, gem ~= nil and not sayWhy)
	if gem then
		plate.gem:SetTexture(MEDIA .. gem)
	end
	local lead = (gem and not sayWhy) and 13 or 0
	plate.gem:ClearAllPoints()
	if sell and takes then
		S.Fit(plate.label, plate.label:GetText(), CELL_W - 12 - lead - (tag and tag:GetWidth() or 0), 10, 7.5)
		plate.gem:SetPoint("LEFT", plate, "LEFT", 4, 0)
		plate.label:SetPoint("LEFT", plate, "LEFT", 5 + lead, 0)
	else
		S.Fit(plate.label, plate.label:GetText(), CELL_W - 8 - lead, 10, 7.5)
		local w = math.min(CELL_W - 8, ns.TextWidth(plate.label)) + lead
		plate.gem:SetPoint("LEFT", plate, "CENTER", -w / 2, 0)
		plate.label:SetPoint("LEFT", plate, "CENTER", -w / 2 + lead, 0)
	end
	plate:SetAlpha(stays and 0.75 or 1)
	self:PaintTick(cell)
end

-- Its box ticked or not, the light of its card, the edge of its plate.
function IU:PaintTick(cell)
	local x = ITEMS[cell]
	-- (1.14.0, a player's word: a card of a case, a case, a key, ticked as a copy is: UI/CaseInventory.lua)
	if x and (x.case or x.item) then
		local sell = self.sell ~= nil
		local t = cell.tick
		local ticked = sell and x.takes and self:LineTicked(x) or false
		cell.ticked = ticked
		CuratorOctoFull.SetShown(t, sell and x.takes and true or false)
		CuratorOctoFull.SetShown(t.check, ticked)
		CuratorOctoFull.SetShown(t.lit, false)
		t:ClearAllPoints()
		t:SetPoint("CENTER", cell, "TOPLEFT", CELL_W - 7, -7)
		-- (over its case in 3D, over its card of a case and its slab)
		t:SetFrameLevel(t.level + 30)
		local e = (ticked and { 1, 0.8, 0.32, 0.95 }) or cell.edgeCol or { 0.62, 0.48, 0.2, 0.9 }
		CuratorOctoFull.ColorTexture(cell.plate.edge, e[1], e[2], e[3], e[4] or 0.9)
		if cell.slot and x.item then
			cell.slot.tickLit = ticked
			if IU.itemHover ~= cell then
				cell.slot.lit:SetAlpha(ticked and 0.3 or 0)
			end
		end
		return
	end
	local sell = self.sell ~= nil
	local t = cell.tick
	if t:GetParent() == cell and t:GetFrameLevel() ~= t.level then
		t:SetFrameLevel(t.level)
	end
	local ticked = sell and x and cell.takes and self:Ticked(x.card, x.rec) or false
	cell.ticked = ticked
	CuratorOctoFull.SetShown(t, sell and cell.takes and true or false)
	CuratorOctoFull.SetShown(t.check, ticked)
	CuratorOctoFull.SetShown(t.lit, sell and cell.takes and IU.lensCell == cell or false)
	PlaceTick(cell, IU.lensCell == cell)
	local c = cell.card
	local fk = x and x.rec.f or "n"
	local e = INK[fk] or INK.n
	-- (1.14.0: the last copy of a card ticked, its light orange)
	local warm = ticked and x and x.unique
	if ticked then
		-- (its light close around it, or around its case)
		c.glow:ClearAllPoints()
		if cell.cased then
			c.glow:SetPoint("CENTER", c, "CENTER", 0, CASE_DY)
			CuratorOctoFull.SetSize(c.glow, (BOX[3] - BOX[1]) * 1.3, (BOX[4] - BOX[2]) * 1.16)
		else
			c.glow:SetPoint("CENTER", c, "CENTER", 0, 0)
			CuratorOctoFull.SetSize(c.glow, SW * 1.5, SH * 1.28)
		end
		if warm then
			c.glow:SetVertexColor(LAST[1], LAST[2] * 0.7, LAST[3] * 0.6)
		else
			c.glow:SetVertexColor(1, 0.76, 0.28)
		end
		c.glow:SetAlpha(0.7)
		CuratorOctoFull.ColorTexture(cell.plate.edge, 1, 0.8, 0.32, 0.95)
	else
		c.glow:SetAlpha(0)
		CuratorOctoFull.ColorTexture(cell.plate.edge, e[1] * 0.55, e[2] * 0.55, e[3] * 0.55, 0.9)
	end
	-- (the card that rises over it: its light too)
	local lens = IU.lensCell == cell and A.frame and A.frame.inv and A.frame.inv.lens
	if lens then
		if ticked then
			lens.glow:SetVertexColor(1, 0.78, 0.3)
			lens.glow:SetAlpha(0.9)
		else
			lens.glow:SetVertexColor(1, 0.9, 0.6)
			lens.glow:SetAlpha(0.35)
		end
	end
end

-- The copies come in one after the other: from the side the page turns from (dir), else from below.
function IU:SlideIn(cell, dir)
	if cell.slideTw then
		ns.CancelTween(cell.slideTw)
	end
	local x0, y0 = dir and 30 * dir or 0, dir and 0 or -8
	local delay = dir and ((dir > 0 and cell.col or (COLS - 1 - cell.col)) * 0.03 + cell.row * 0.012) or (cell.i - 1) * 0.012
	cell.dx, cell.dy = x0, y0
	cell:SetAlpha(0)
	Place(cell)
	cell.slideTw = ns.Tween(dir and 0.24 or 0.2, function(e)
		cell.dx, cell.dy = x0 * (1 - e), y0 * (1 - e)
		cell:SetAlpha(e)
		Place(cell)
	end, function()
		cell.dx, cell.dy = 0, 0
		cell:SetAlpha(1)
		Place(cell)
		cell.slideTw = nil
	end, Ease.outCubic, A, delay)
end

-------------------------------------------------------------------------------
-- The copy under the mouse: it rises, it leans toward the mouse (one card in 3D for all of them, over it)
-------------------------------------------------------------------------------
local function NewLens(page)
	-- (on a frame of its own over the copies, so that its pieces stand over theirs)
	local hold = CreateFrame("Frame", nil, page)
	hold:SetAllPoints()
	hold:SetFrameLevel(page:GetFrameLevel() + 40)
	local c = ns.NewCard(hold, "small")
	c:EnableMouse(false)
	c.shadow:SetAlpha(0.85)
	c:Hide()
	c.yaw, c.pitch, c.lift = 0, 0, 1
	page.lensHold = hold
	page.lensTop = page:GetFrameLevel() + 70
	return c
end

local function PlaceLens(lens)
	local cell = lens.cell
	if not cell then
		return
	end
	local u = lens.lift or 1
	local s = cell.k * u
	lens:SetScale(s)
	lens:ClearAllPoints()
	lens:SetPoint("CENTER", cell.card, "CENTER", 0, 4 * (u - 1) / (LIFT - 1) * cell.k / s)
end

function IU:Enter(cell)
	local x = ITEMS[cell]
	local page = A.frame and A.frame.inv
	if not (x and page) then
		return
	end
	if x.item then
		return self:EnterItem(cell, x)
	end
	if x.case then
		return self:EnterCase(cell, x)
	end
	local lens = page.lens
	if self.lensCell and self.lensCell ~= cell then
		self:Leave(self.lensCell)
	end
	self.lensCell = cell
	lens.cell = cell
	Dress(lens, x.card, x.rec)
	lens:SetAlpha(cell.alpha == 1 and 1 or math.min(1, (cell.alpha or 1) + 0.25))
	lens.yaw, lens.pitch = 0, 0
	lens.lift = 1
	PlaceLens(lens)
	lens:Show()
	cell.card:SetAlpha(0)
	cell.band:Hide()
	-- (its box over the card risen: on its frame, above it)
	cell.tick:SetParent(page.lensHold)
	cell.tick:SetFrameLevel(page.lensTop)
	if lens.liftTw then
		ns.CancelTween(lens.liftTw)
	end
	lens.liftTw = ns.Tween(0.14, function(e)
		lens.lift = 1 + (LIFT - 1) * e
		PlaceLens(lens)
	end, nil, Ease.outQuad, A)
	self:PaintTick(cell)
	self:CellTooltip(cell)
end

function IU:Leave(cell)
	GameTooltip:Hide()
	local x = ITEMS[cell]
	if x and x.item then
		return self:LeaveItem(cell)
	end
	if x and x.case then
		return self:LeaveCase(cell, x)
	end
	if self.lensCell ~= cell then
		return
	end
	self.lensCell = nil
	local page = A.frame and A.frame.inv
	local lens = page and page.lens
	if lens then
		if lens.liftTw then
			ns.CancelTween(lens.liftTw)
			lens.liftTw = nil
		end
		lens.cell = nil
		lens:Hide()
		-- (hidden, it lets go of its creature: set again the next time)
		lens.sig = nil
	end
	cell.card:SetAlpha(cell.alpha or 1)
	CuratorOctoFull.SetShown(cell.band, cell.hasBand and true or false)
	cell.tick:SetParent(cell)
	cell.tick:SetFrameLevel(cell.tick.level)
	if ITEMS[cell] then
		self:PaintTick(cell)
	end
end

-- Every frame: the card risen leans toward the mouse, eased.
function IU:Lean(lens, elapsed)
	local cell = lens.cell
	if not cell then
		return
	end
	local dx, dy = Offset(cell.card)
	local a = math.min(1, (elapsed or 0) * 12)
	lens.yaw = lens.yaw + (LEAN_YAW * Clamp(dx) - lens.yaw) * a
	lens.pitch = lens.pitch + (-LEAN_PITCH * Clamp(dy) - lens.pitch) * a
	lens:SetPose(lens.yaw, lens.pitch)
end

function IU:CellTooltip(cell)
	local x = ITEMS[cell]
	if not x then
		return
	end
	if x.item then
		return self:ItemTooltip(cell, x)
	end
	if x.case then
		return self:CaseTooltip(cell, x)
	end
	local card, rec = x.card, x.rec
	GameTooltip:SetOwner(cell, cell.col >= COLS - 3 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	GameTooltip:AddLine(C:Name(card), 1, 1, 1)
	GameTooltip:AddLine(C:SeriesName(card.series) .. "  ·  " .. L[ns.RARITY[card.rarity].label], 0.7, 0.7, 0.72)
	ns.CopiesUI:Tooltip(GameTooltip, card, rec, true)
	-- (1.14.3: another player's copy: their album, a click away)
	if x.theirs then
		GameTooltip:AddLine(L["Click: see it in their album"], 0.4, 1, 0.4)
		GameTooltip:Show()
		return
	end
	-- (1.14.0, Fence's Eye: what the reseller gives for this copy, and what he sells the card for)
	if not self.sell and ns.Talents and ns.Talents.FenceLine then
		ns.Talents:FenceLine(GameTooltip, card, ns.Copies and ns.Copies.Finish and ns.Copies.Finish(rec) or nil)
	end
	if self.sell then
		GameTooltip:AddLine(" ")
		if cell.takes then
			GameTooltip:AddLine(string.format(L["He pays %s a copy."], ns.Rubies.Text(ns.Reseller:PaysNow(ns.Reseller:OfferFor(card, rec)), 13)), 1, 0.82, 0.25)
			-- (1.14.0, a player's word: its last copy, said)
			if x.unique then
				GameTooltip:AddLine(L["Its last copy: sold, the card leaves your album."], LAST[1], LAST[2], LAST[3], true)
			elseif not x.dupe then
				GameTooltip:AddLine(L["Your finest copy of this card."], 1, 0.86, 0.5, true)
			end
			GameTooltip:AddLine(self:Ticked(card, rec) and L["Click: untick it"] or L["Click: tick it"], 0.3, 1, 0.3)
		else
			local w = STAYS[cell.why or "copy"] or STAYS.copy
			if w[2] then
				GameTooltip:AddLine(L[w[2]], 1, 0.45, 0.4, true)
			end
		end
		GameTooltip:AddLine(L["Right click: show this copy"], 0.62, 0.62, 0.66)
	else
		GameTooltip:AddLine(L["Click: show this copy"], 0.4, 1, 0.4)
	end
	GameTooltip:Show()
end

function IU:Click(cell, button)
	local x = ITEMS[cell]
	if not x then
		return
	end
	-- (the sell mode: a click ticks it, or unticks it; a right click shows it big. 1.14.0, a player's word: a card of a
	-- case, a case, a key too)
	if self.sell and button ~= "RightButton" then
		if not x.takes then
			ns.Play(ns.SND.close)
			self:CellTooltip(cell)
			return
		end
		self:TickLine(x)
		local on = self:LineTicked(x)
		ns.Play(on and ns.SND.ink or ns.SND.click)
		self:PaintTicks()
		if on then
			-- (its mark comes down onto its box)
			local ck = cell.tick.check
			if ck.tw then
				ns.CancelTween(ck.tw)
			end
			ck.tw = ns.Tween(0.16, function(e)
				local k = 1.7 - 0.7 * e
				CuratorOctoFull.SetSize(ck, 27 * k, 27 * k)
				ck:SetAlpha(math.min(1, e * 2.5))
			end, function()
				CuratorOctoFull.SetSize(ck, 27, 27)
				ck:SetAlpha(1)
				ck.tw = nil
			end, Ease.outQuad, A)
		end
		self:CellTooltip(cell)
		return
	end
	if x.item then
		return self:ClickItem(cell, x, button)
	end
	if x.case then
		return self:ClickCase(cell, x, button)
	end
	ns.Play(ns.SND.cardFlip)
	if ns.Links and ns.Links.Modified and ns.Links:Modified() then
		-- (1 November: its certificate of the mages with it, Mages.lua)
		local MG = ns.Mages
		-- (1.14.3: the copy itself with it, its very card: UI/Links.lua)
		return ns.Links:Insert(x.card, CP.Finish(x.rec), CP.Pattern(x.rec), MG and MG.Pack(MG.Of(x.rec)) or nil, x.rec)
	end
	-- (1.14.3: another player's copy: its card in their album, its page)
	if x.theirs then
		local who = self:Who()
		self:Leave(cell)
		if who then
			A:ShowMember(who, x.card.series, x.card)
		end
		return
	end
	-- (that copy shown big, over the inventory: the inventory again when it closes)
	self:Leave(cell)
	ns.CopiesUI.pending = { key = x.card.key, id = x.rec.i }
	A:ShowDetail(x.card, C:Entry(x.card))
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------
-- The bar of buttons under the page: the sale (what is ticked, what it brings; tick all, untick all, Sell), or the way
-- to it while the reseller is there.
local function BuildFoot(f)
	local ft = CreateFrame("Frame", nil, f)
	ft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 3)
	ft:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 3)
	ft:SetHeight(24)
	ft:Hide()
	ft.total = S.Text(ft, "GameFontNormal", "LEFT")
	ft.total:SetPoint("LEFT", ft, "LEFT", 6, 0)
	CuratorOctoFull.SetWordWrap(ft.total, false)
	local function Btn(text, w)
		local b = S.Button(ft, text, w, 22)
		if b.SetMotionScriptsWhileDisabled then
			b:SetMotionScriptsWhileDisabled(true)
		end
		CuratorOctoFull.SetScript(b, "OnLeave", function()
			GameTooltip:Hide()
		end)
		return b
	end
	ft.sell = Btn("", 160)
	ft.sell:SetPoint("RIGHT", ft, "RIGHT", 0, 0)
	-- (armed: a light of gold behind it, breathing until it is confirmed)
	ft.sell.glow = ft:CreateTexture(nil, "BACKGROUND")
	ft.sell.glow:SetTexture(MEDIA .. "Glow")
	ft.sell.glow:SetBlendMode("ADD")
	ft.sell.glow:SetVertexColor(1, 0.78, 0.3)
	ft.sell.glow:SetPoint("TOPLEFT", ft.sell, "TOPLEFT", -40, 20)
	ft.sell.glow:SetPoint("BOTTOMRIGHT", ft.sell, "BOTTOMRIGHT", 40, -20)
	ft.sell.glow:SetAlpha(0)
	CuratorOctoFull.SetScript(ft.sell, "OnClick", function()
		IU:Sell()
	end)
	CuratorOctoFull.SetScript(ft.sell, "OnEnter", function(self)
		IU:SellTooltip(self)
	end)
	CuratorOctoFull.SetScript(ft.sell, "OnUpdate", function(self)
		local s = IU.sell
		if s and s.armed then
			local t = GetTime() - s.armed
			if t >= (s.armWait or ARM) then
				s.armed, s.lost, s.armWait = nil, nil, nil
				IU:PaintSell()
			else
				self.glow:SetAlpha(0.65 + 0.35 * math.sin(t * 6))
			end
		elseif self.glow:GetAlpha() > 0 then
			self.glow:SetAlpha(0)
		end
	end)
	ft.untick = Btn(L["Untick all"], 110)
	ft.untick:SetPoint("RIGHT", ft.sell, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(ft.untick, "OnClick", function()
		ns.Play(ns.SND.click)
		IU:Untick()
		IU:PaintTicks()
	end)
	ft.all = Btn("", 130)
	ft.all:SetPoint("RIGHT", ft.untick, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(ft.all, "OnClick", function()
		if IU:TickAll() > 0 then
			ns.Play(ns.SND.ink)
		end
		IU:PaintTicks()
	end)
	CuratorOctoFull.SetScript(ft.all, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Every copy shown that he takes, on every page (the album, the filter, the rarity)."], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	-- (1.14.0, a player's word: the copies of the page shown only)
	ft.pageTick = Btn("", 130)
	ft.pageTick:SetPoint("RIGHT", ft.all, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(ft.pageTick, "OnClick", function()
		if IU:TickPage() > 0 then
			ns.Play(ns.SND.ink)
		end
		IU:PaintTicks()
	end)
	CuratorOctoFull.SetScript(ft.pageTick, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Every copy of this page that he takes."], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	ft.back = Btn(L["Back"], 80)
	ft.back:SetPoint("RIGHT", ft.pageTick, "LEFT", -6, 0)
	CuratorOctoFull.SetScript(ft.back, "OnClick", function()
		ns.Play(ns.SND.page)
		IU:EndSell()
	end)
	ft.seller = Btn(L["Sell to the reseller"], 200)
	ft.seller:SetPoint("RIGHT", ft, "RIGHT", 0, 0)
	CuratorOctoFull.SetScript(ft.seller, "OnClick", function()
		ns.Play(ns.SND.click)
		IU:OpenSeller()
	end)
	CuratorOctoFull.SetScript(ft.seller, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Sell to the reseller"], 1, 1, 1)
		GameTooltip:AddLine(L["He takes them for next to nothing, as many as you want."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	-- (1.14.3: another player's inventory: their albums, where the tab of their albums was)
	ft.theirs = Btn("", 180)
	ft.theirs:SetPoint("RIGHT", ft, "RIGHT", 0, 0)
	CuratorOctoFull.SetScript(ft.theirs, "OnClick", function()
		ns.Play(ns.SND.page)
		A:SetMemberMode("contents")
	end)
	ft.theirs:Hide()
	return ft
end

local function Width(b)
	b:SetWidth(math.max(80, math.ceil(ns.TextWidth(b:GetFontString() or b.label) + 26)))
end

function A:BuildInventory()
	local f = self.frame
	if f.inv then
		return
	end
	local page = CreateFrame("Frame", nil, f.body)
	page:SetPoint("TOPLEFT", 16, -10)
	page:SetPoint("BOTTOMRIGHT", -16, 10)
	page:SetFrameLevel(f.body:GetFrameLevel() + 20)
	page:Hide()
	f.inv = page
	local w = (self.U.PAGE_W or 768) - 32
	page.w = w
	-- the order (the filters, their counts: on the bar over it, IU:Bar). (1 November: at the foot of the page, the bar of
	-- the filters all its own, a tab more, Forged - Certified; on the right, before the duplicates: A:RefreshInventory)
	page.sort = S.Button(page, "", 160, 20)
	page.sort:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 7)
	page.sort:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(page.sort, "OnClick", function(_, button)
		IU:NextSort(button == "RightButton" and -1 or 1)
	end)
	-- (1.14.0, a player's word: the copies of one album only, chosen as in the chooser of the trades, UI/Social.lua; under
	-- the copies, on the left of their pages, the bar of the filters over them being full; one card shown: its chip there)
	page.album = S.Dropdown(page, 220)
	page.album:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 4)
	page.album:SetupMenu(function(_, root)
		IU:AlbumMenu(root)
	end)
	if page.album.SetTooltip then
		page.album:SetTooltip(function(tip)
			tip:AddLine(L["Album"], 1, 1, 1)
			tip:AddLine(L["The copies of every album, or of one only."], GOLD[1], GOLD[2], GOLD[3], true)
		end)
	end
	-- (one card only: its name, the way back to every copy)
	page.only = ns.CopiesUI.Chip(page, function()
		IU.card, IU.page = nil, 1
		ns.Play(ns.SND.page)
		A:Refresh()
	end)
	page.only:SetHeight(20)
	page.only:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 6)
	-- (1.14.0, a player's word: the duplicates only, every copy but the finest of each card; at the reseller, at first)
	page.dupes = ns.CopiesUI.Chip(page, function()
		IU.dupes = not IU.dupes or nil
		IU.page = 1
		ns.Play(ns.SND.click)
		A:Refresh()
	end)
	page.dupes:SetHeight(22)
	page.dupes:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 6)
	CuratorOctoFull.SetScript(page.dupes, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Duplicates only"], 1, 1, 1)
		GameTooltip:AddLine(L["Every copy but the finest of each card: what can go without a card leaving your album."], GOLD[1], GOLD[2], GOLD[3], true)
		GameTooltip:AddLine(IU.dupes and L["Click: every copy"] or L["Click: the duplicates only"], 0.3, 1, 0.3)
		GameTooltip:Show()
	end)
	-- the copies
	local x0 = (w - (COLS * CELL_W + (COLS - 1) * GAP_X)) / 2
	page.cells = {}
	for i = 1, PER do
		page.cells[i] = NewCell(page, i, x0)
	end
	page.lens = NewLens(page)
	page.empty = S.Text(page, "GameFontHighlight")
	page.empty:SetPoint("TOP", 0, -190)
	page.empty:SetWidth(w - 120)
	CuratorOctoFull.SetWordWrap(page.empty, true)
	page.empty:SetTextColor(0.72, 0.72, 0.76)
	page:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(page, "OnMouseWheel", function(_, delta)
		A:InventoryPage(-delta)
	end)
	page.t = 0
	CuratorOctoFull.SetScript(page, "OnUpdate", function(self, elapsed)
		self.t = self.t + elapsed
		for _, cell in ipairs(self.cells) do
			if ITEMS[cell] and not ITEMS[cell].case and not ITEMS[cell].item and cell:IsShown() then
				cell.card:Tick(self.t)
			end
		end
		local lens = self.lens
		if lens:IsShown() then
			IU:Lean(lens, elapsed)
			lens:Tick(self.t)
		end
	end)
	CuratorOctoFull.SetScript(page, "OnHide", function(self)
		if IU.lensCell then
			IU:Leave(IU.lensCell)
		end
		if IU.itemHover and IU.LeaveItem then
			IU:LeaveItem(IU.itemHover)
		end
		-- (hidden, the cards let go of their creatures: every one set again when the page shows; its copies come in)
		for _, cell in ipairs(self.cells) do
			cell.card.sig = nil
		end
		self.lens.sig = nil
		IU.view = nil
	end)
	f.invFoot = BuildFoot(f)
	-- (the window closed: the sale ends)
	if f.HookScript then
		f:HookScript("OnHide", function()
			IU:EndSell(true)
		end)
	end
end

function A:ShowInventoryPage(shown)
	local f = self.frame
	if shown then
		self:BuildInventory()
	elseif IU.sell then
		-- (another page of the album: the sale ends)
		IU:EndSell(true)
	end
	-- (1.13.0, after its first test: a copy shown big over it, the page waits under it, hidden, until it closes; its
	-- plates, its bands and its cases stood over the window of the card: A:HideDetail)
	local under = (shown and self.detail and self.detail:IsShown()) and true or false
	IU.under = under or nil
	if f.inv then
		CuratorOctoFull.SetShown(f.inv, shown and not under)
		CuratorOctoFull.SetShown(f.invFoot, shown and not under)
	end
	-- (the bar of its filters: over the copies, and over the page of the boosters, a part of it)
	local bar = (shown or (self.mode == "boosters" and not self.member)) and IU:Bar() or f.invBar
	if bar then
		CuratorOctoFull.SetShown(bar, (shown and not under) or (self.mode == "boosters" and not self.member) or false)
	end
end

-- (1.13.0, after its first test) The bar of the filters of the inventory, over its copies and over its boosters (the page
-- of the boosters, UI/Boosters.lua, under it): Boosters first, then the copies, each with how many.
function IU:Bar()
	local f = A.frame
	if f.invBar then
		return f.invBar
	end
	local bar = CreateFrame("Frame", nil, f.body)
	bar:SetPoint("TOPLEFT", f.body, "TOPLEFT", 16, -10)
	bar:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", -16, -10)
	bar:SetHeight(BAR_H - 4)
	bar:SetFrameLevel(f.body:GetFrameLevel() + 40)
	bar.w = (A.U.PAGE_W or 768) - 32
	bar.chips = {}
	for i, def in ipairs(FILTERS) do
		local i, def = i, def; local b = ns.CopiesUI.Chip(bar, function()
			IU:SetFilter(def.key)
		end)
		b.def = def
		b:SetHeight(20)
		-- (1.14.0: Cases, its cases to open and their keys, under the mouse)
		if def.key == "cases" then
			CuratorOctoFull.SetScript(b, "OnEnter", function(self)
				local CS = ns.Cases
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
				GameTooltip:AddLine(L["Cases"], 1, 0.84, 0.26)
				if CS then
					GameTooltip:AddLine(string.format(L["Cases to open: %d  ·  Keys: %d"], CS:Total(), CS:Keys()), 1, 1, 1)
				end
				GameTooltip:AddLine(L["Click: show them."], 0.6, 0.6, 0.64)
				GameTooltip:Show()
			end)
			CuratorOctoFull.SetScript(b, "OnLeave", function()
				GameTooltip:Hide()
			end)
		end
		-- (Boosters counts the boosters and the displays: how many of each, under the mouse)
		if def.key == "packs" then
			CuratorOctoFull.SetScript(b, "OnEnter", function(self)
				local _, displays = IU:Counts({})
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
				GameTooltip:AddLine(string.format(L["Boosters: %d"], ns.TotalPacks()), 1, 1, 1)
				GameTooltip:AddLine(string.format(L["Displays: %d"], displays), GOLD[1], GOLD[2], GOLD[3])
				-- (1.14.2: the golden boosters, counted with them)
				local golden = IU.GoldenCount()
				if golden > 0 then
					GameTooltip:AddLine(string.format(L["Golden boosters: %d"], golden), 1, 0.84, 0.35)
				end
				GameTooltip:Show()
			end)
		end
		bar.chips[i] = b
	end
	bar:Hide()
	f.invBar = bar
	return bar
end

-- How many in each filter of the bar (the copies, from IU:Survey; the boosters and the displays: Boosters). The counts
-- of the copies kept until something changes (the page of the boosters paints the bar often).
local copyCounts
for _, e in ipairs({ "COPIES_CHANGED", "CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		copyCounts = nil
	end)
end
-- (every copy, whatever the rarity or the card chosen: the bar over the boosters)
local function CopyCounts()
	if not copyCounts then
		local chips = {}
		for _, d in ipairs(FILTERS) do
			chips[d.key] = 0
		end
		for _, x in ipairs(CP:All()) do
			for _, d in ipairs(FILTERS) do
				if d.key ~= "packs" and Want(d.key, x.rec) then
					chips[d.key] = chips[d.key] + 1
				end
			end
		end
		copyCounts = chips
	end
	return copyCounts
end
-- (1.14.2) The golden boosters waiting (Golden.lua): with the boosters, in Boosters and in the head of the inventory.
function IU.GoldenCount()
	local GQ = ns.Golden
	return GQ and GQ.PackCount and GQ:PackCount() or 0
end

function IU:Counts(chips)
	local DS = ns.Displays
	local displays, objects = 0, ns.TotalPacks() + IU.GoldenCount()
	for _, x in ipairs(DS and DS.All and DS:All() or {}) do
		displays = displays + (x.displays or 0) + (x.casedDisplays or 0)
		objects = objects + (x.displays or 0) + (x.casedDisplays or 0)
	end
	if not chips then
		chips = {}
		for k, v in pairs(CopyCounts()) do
			chips[k] = v
		end
		-- (1 November: Everything, what waits to be opened with the copies: IU:Survey)
		if self.AllItems then
			chips.all = (chips.all or 0) + self:ItemCount(self:AllItems(nil, self.sell ~= nil))
		end
	end
	chips.packs = objects
	-- (1.14.0: the cases to open, of every edition, their keys; the cards of the cases among the copies)
	if self.CaseCounts then
		self:CaseCounts(chips)
	end
	return chips, displays
end

-- (the page of the boosters, a part of the inventory: the bar of its filters over it, painted with it)
do
	local refreshBoosters = A.RefreshBoosters
	function A:RefreshBoosters(...)
		local r = refreshBoosters(self, unpack(arg, 1, arg.n))
		local f = self.frame
		if f and f.invBar and f.invBar:IsShown() then
			IU:PaintChips(f.inv, (IU:Counts()))
		end
		return r
	end
end

do
	local showDetail, hideDetail = A.ShowDetail, A.HideDetail
	function A:ShowDetail(...)
		local r = showDetail(self, unpack(arg, 1, arg.n))
		local f = self.frame
		if f and f.inv and self.mode == "inventory" and self.detail and self.detail:IsShown() and (f.inv:IsShown() or f.invFoot:IsShown()) then
			IU.under = true
			f.inv:Hide()
			f.invFoot:Hide()
			-- (the bar of its filters too: over the window of the card, it stood on its top)
			if f.invBar then
				f.invBar:Hide()
			end
		end
		return r
	end
	function A:HideDetail(...)
		local r = hideDetail(self, unpack(arg, 1, arg.n))
		if IU.under and not (self.detail and self.detail:IsShown()) then
			IU.under = nil
			local f = self.frame
			if f and f.inv and f:IsShown() and self.mode == "inventory" then
				self:Refresh()
			end
		end
		return r
	end
end

function A:InventoryPage(delta)
	local from = IU.page or 1
	local p = math.max(1, math.min(IU.pages or 1, from + delta))
	if p == from then
		return
	end
	IU.page = p
	IU.turnDir = delta > 0 and 1 or -1
	ns.Play(ns.SND.page)
	self:Refresh()
end

function IU:SetFilter(key)
	ns.Play(ns.SND.click)
	self.filter, self.page = key, 1
	-- (1.14.0, after its first test: the cases and the keys, their own pages in the inventory: UI/CaseInventory.lua)
	if key == "cases" or key == "keys" then
		self.card, self.rarity = nil, nil
		if A.mode ~= "inventory" then
			return A:SetMode("inventory")
		end
		return A:Refresh()
	end
	-- (1.13.0, after its first test: Boosters, the page of the boosters under the bar; the others, the copies)
	if key == "packs" then
		self.card, self.rarity = nil, nil
		A.boosterPick, A.dispView = nil, nil
		if A.mode ~= "boosters" then
			return A:SetMode("boosters")
		end
		return A:Refresh()
	end
	if A.mode ~= "inventory" then
		return A:SetMode("inventory")
	end
	A:Refresh()
end

function IU:SetRarity(r)
	if self.filter == "packs" then
		return
	end
	self.rarity = (self.rarity ~= r) and r or nil
	self.page = 1
	ns.Play(ns.SND.page)
	A:Refresh()
	local b = A.frame.counts[r]
	if b and b:IsMouseOver() then
		A:CountTooltip(b)
	end
end

function IU:NextSort(dir)
	local at = 1
	for i, k in ipairs(SORTS) do
		if k == self.sort then
			at = i
		end
	end
	self.sort = SORTS[CuratorOctoFull.Mod((at - 1 + (dir or 1)) , CuratorOctoFull.Length(SORTS)) + 1]
	self.page = 1
	ns.Play(ns.SND.page)
	A:Refresh()
end

-- The filters (their counts), in one line: their letters smaller when the line is too long for the page.
function IU:PaintChips(page, counts)
	local bar = self:Bar()
	local sell = self.sell ~= nil
	local boosters = A.mode == "boosters"
	-- (1.14.3: another player's inventory: their boosters, cases and keys in Everything, no page of their own)
	local theirs = self:Who() ~= nil
	-- (1 November: the order of the copies at the foot of the page, the line all for the filters)
	local room = bar.w
	local size = 10
	while true do
		-- (smaller, closer: a count one space from its word, the chips nearer each other)
		local tight = size < 10
		local gap = tight and 3 or 4
		local x = 0
		for _, b in ipairs(bar.chips) do
			local key = b.def.key
			local show = not (sell and key == "packs") and not (theirs and (key == "packs" or key == "cases" or key == "keys"))
			if show then
				ns.SetFont(b.text, size)
				local n = counts[key] or 0
				local on = (boosters and key == "packs") or (not boosters and self.filter == key)
				ns.CopiesUI.PaintChip(b, L[b.def.label] .. (tight and " " or "  ") .. "|cff" .. COUNT_HEX .. ns.Num(n) .. "|r", nil, on,
					n == 0 and not on)
				if tight then
					b:SetWidth(math.max(30, math.ceil(ns.TextWidth(b.text)) + 10))
				end
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", bar, "TOPLEFT", x, -4)
				x = x + b:GetWidth() + gap
			else
				b:Hide()
			end
		end
		if x - gap <= room or size <= 7 then
			break
		end
		size = size - 0.5
	end
	bar.size = size
end

-- The gems of the head of the window: the copies of each rarity (of the filter, of the card); a click shows only
-- them (a second one, all of them again).
function IU:PaintGems(f, gems, shown)
	for r, b in ipairs(f.counts) do
		CuratorOctoFull.SetShown(b, shown)
		if shown then
			local n = gems[r] or 0
			b.copies = n
			b.text:SetText(ns.Num(n))
			b:SetWidth(17 + math.ceil(ns.TextWidth(b.text, 30)))
			local on = self.rarity == r
			CuratorOctoFull.SetShown(b.mark, on)
			CuratorOctoFull.SetShown(b.line, on)
			b:SetAlpha(((self.rarity and not on) or n == 0) and 0.5 or 1)
		end
	end
end

-- The bar of buttons, the sale: what is ticked and what it brings, the buttons; the way to it, the reseller there.
function IU:PaintSell()
	local f = A.frame
	local ft = f and f.invFoot
	if not ft then
		return
	end
	local s = self.sell
	local RV = ns.Reseller
	-- (1.14.3: another player's inventory: nothing to sell; their albums)
	local who = self:Who()
	if who then
		s = nil
	end
	CuratorOctoFull.SetShown(ft, A.mode == "inventory")
	CuratorOctoFull.SetShown(ft.seller, not who and not s and RV ~= nil and RV.here and true or false)
	Width(ft.seller)
	if ft.theirs then
		CuratorOctoFull.SetShown(ft.theirs, who ~= nil)
		if who then
			ft.theirs:SetLabel(string.format(L["%s's albums"], ns.Guild:Short(who)))
			Width(ft.theirs)
		end
	end
	for _, k in ipairs({ "total", "sell", "untick", "all", "pageTick", "back" }) do
		CuratorOctoFull.SetShown(ft[k], s ~= nil)
	end
	if not s then
		return
	end
	local list, rubies = self:Picked()
	local n = CuratorOctoFull.Length(list)
	ft.total:SetText(n > 0 and string.format(L["%d ticked · he pays %s"], n, ns.Rubies.Text(rubies, 15)) or L["Tick the copies to sell him."])
	if n > 0 then
		ft.total:SetTextColor(1, 0.86, 0.45)
	else
		ft.total:SetTextColor(0.8, 0.8, 0.82)
	end
	local armed =s.armed and GetTime() - s.armed < (s.armWait or ARM)
	if not armed then
		s.armed, s.lost, s.armWait = nil, nil, nil
	end
	-- (1.14.0, a player's word: armed with the last copies of cards in it, said in its place)
	if armed and (s.lost or 0) > 0 then
		ft.total:SetText(string.format(L["Warning: %d cards will leave your album (their last copy)."], s.lost))
		ft.total:SetTextColor(LAST[1], LAST[2], LAST[3])
	end
	ft.sell:SetLabel(armed and string.format(L["Confirm: %s"], ns.Rubies.Text(rubies, 13)) or string.format(L["Sell: %s"], ns.Rubies.Text(rubies, 13)))
	Width(ft.sell)
	CuratorOctoFull.SetEnabled(ft.sell, n > 0)
	CuratorOctoFull.SetEnabled(ft.untick, n > 0)
	Width(ft.untick)
	-- (the copies shown he takes: every page of the filter, of the rarity, of the card)
	local shown, left = 0, 0
	for _, x in ipairs(self.lines or {}) do
		if x.takes then
			shown = shown + 1
			if not self:LineTicked(x) then
				left = left + 1
			end
		end
	end
	ft.all:SetLabel(string.format(L["Tick all (%d)"], shown))
	Width(ft.all)
	CuratorOctoFull.SetEnabled(ft.all, left > 0)
	-- (1.14.0: those of the page shown)
	local onPage, pageLeft = 0, 0
	local lines = self.lines or {}
	local first = ((self.page or 1) - 1) * PER
	for i = first + 1, math.min(CuratorOctoFull.Length(lines), first + PER) do
		local x = lines[i]
		if x and x.takes then
			onPage = onPage + 1
			if not self:LineTicked(x) then
				pageLeft = pageLeft + 1
			end
		end
	end
	ft.pageTick:SetLabel(string.format(L["Tick the page (%d)"], onPage))
	Width(ft.pageTick)
	CuratorOctoFull.SetEnabled(ft.pageTick, pageLeft > 0)
	Width(ft.back)
	-- (the line of what is ticked, short of the buttons)
	local room = (ft:GetWidth() or 762) - 12 - ft.sell:GetWidth() - ft.untick:GetWidth() - ft.all:GetWidth() - ft.pageTick:GetWidth() - ft.back:GetWidth() - 36
	if room > 40 then
		ft.total:SetWidth(room)
	end
	-- the head: how many are ticked, of those he takes
	A:SetBar(n, math.max(1, self.taken or 0), string.format(L["Ticked: %d / %d"], n, self.taken or 0))
end

-- After a tick: the boxes of the page, the bar of buttons, the head (nothing else changes).
function IU:PaintTicks()
	local f = A.frame
	local page = f and f.inv
	if not page then
		return
	end
	for _, cell in ipairs(page.cells) do
		if ITEMS[cell] and cell:IsShown() then
			self:PaintTick(cell)
		end
	end
	self:PaintSell()
	if f.invFoot.sell:IsMouseOver() then
		self:SellTooltip(f.invFoot.sell)
	end
end

function A:RefreshInventory()
	local f = self.frame
	local page = f.inv
	for _, c in ipairs(f.slots) do
		c:Hide()
		c.sig = nil
	end
	f.toc:Hide()
	f.list:Hide()
	self:RefreshFooter(false)
	-- (1.14.3: another player's inventory, as they send it; mine again, as I left it)
	local who = IU:Who()
	if who then
		return self:RefreshTheirInventory(who)
	end
	IU:Mine()
	IU.takes = nil
	local sell = IU.sell ~= nil
	-- (the boosters: the page of the boosters, never here)
	if IU.filter == "packs" then
		IU.filter = "all"
	end
	Portrait(f, sell)
	local sv = IU:Survey()
	IU.lines, IU.taken = sv.lines, sv.taken
	-- the boosters, the displays: their count
	local _, displays = IU:Counts(sv.chips)
	-- the head: what it is, how many; in the sell mode, what the reseller does
	if sell then
		self:SetTitle(L["Sell to the reseller"], L["He takes them for next to nothing, as many as you want."])
	else
		local all = CP:All()
		local graded = 0
		for _, x in ipairs(all) do
			if CP.Grade(x.rec) and x.rec.sl ~= false then
				graded = graded + 1
			end
		end
		-- (1.14.0, after its first test: the cards of the cases, copies too)
		local n = CuratorOctoFull.Length(all)
		if IU.CaseTotals then
			local cn, cg = IU:CaseTotals()
			n, graded = n + cn, graded + cg
		end
		-- (1.14.2: the golden boosters with the boosters)
		self:SetTitle(L["Inventory"], string.format(L["%s copies · %s boosters · %s displays"], ns.Num(n), ns.Num(ns.TotalPacks() + IU.GoldenCount()), ns.Num(displays)))
		self:SetBar(graded, math.max(1, n), string.format(L["Appraised: %d / %d"], graded, n))
	end
	CuratorOctoFull.SetShown(page.sort, IU.filter ~= "cases" and IU.filter ~= "keys")
	IU:PaintChips(page, sv.chips)
	IU:PaintGems(f, sv.gems, true)
	CuratorOctoFull.SetShown(page.only, IU.card ~= nil)
	CuratorOctoFull.SetShown(page.album, IU.card == nil and IU.filter ~= "cases" and IU.filter ~= "keys")
	local items = IU.filter == "cases" or IU.filter == "keys"
	CuratorOctoFull.SetShown(page.dupes, not items and IU.card == nil)
	if not items and IU.card == nil then
		ns.CopiesUI.PaintChip(page.dupes, L["Duplicates only"], nil, IU.dupes and true or false)
	end
	-- (1 November: the order on the right of the foot, before the duplicates; the pages turn in the middle, Everything
	-- having more of them. Its words smaller when they would reach the arrows of the pages)
	local dupesOn = not items and IU.card == nil
	page.sort:ClearAllPoints()
	if dupesOn then
		page.sort:SetPoint("RIGHT", page.dupes, "LEFT", -10, 0)
	else
		page.sort:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 7)
	end
	local room = page.w / 2 - SORT_GAP - (dupesOn and (page.dupes:GetWidth() + 10) or 0)
	S.Fit(page.sort:GetFontString() or page.sort.label, L[SORT_LABEL[IU.sort]], room - 26, 12, 8)
	Width(page.sort)
	if IU.card then
		ns.CopiesUI.PaintChip(page.only, string.format(L["Only: %s (all)"], C:Name(IU.card)), nil, true)
	end
	IU:PaintSell()
	-- (1.14.0, after its first test: the cases, the keys: their own page, UI/CaseInventory.lua)
	if IU.filter == "cases" or IU.filter == "keys" then
		return IU:PaintCasesPage(page, IU.filter)
	end
	if IU.HideCasesPage then
		IU:HideCasesPage(page)
	end
	return IU:PaintGrid(page, sv.lines)
end

function IU:PaintGrid(page, lines, remote)
	-- (1.14.3, remote: a page of another player's inventory, its lines only, { total, known, empty, stamp }: the pages
	-- as many as they have; their count not known yet, the page asked stays)
	local count = remote and (remote.total or 0) or CuratorOctoFull.Length(lines)
	local pages = math.max(1, math.ceil(count / PER))
	if remote and not remote.known then
		pages = math.max(pages, self.page or 1)
	end
	self.page = math.max(1, math.min(self.page or 1, pages))
	self.pages = pages
	local first = remote and 0 or (self.page - 1) * PER
	-- (a new page, filter, order, rarity: the copies come in)
	local view = table.concat({ self.filter, self.sort, self.rarity or 0, self.card and self.card.key or "", self.page, self.sell and 1 or 0,
		self.series and self.series.key or "", remote and remote.stamp or "" }, ":")
	local turned = view ~= self.view
	self.view = view
	local hovered = self.lensCell
	if hovered then
		self:Leave(hovered)
	end
	for i, cell in ipairs(page.cells) do
		local x = lines[first + i]
		self:PaintCell(cell, x)
		if x and turned then
			self:SlideIn(cell, self.turnDir)
		end
	end
	self.turnDir = nil
	-- (the copy that was under the mouse: the one there now rises)
	if hovered and ITEMS[hovered] and hovered:IsShown() and hovered:IsMouseOver() then
		self:Enter(hovered)
	end
	CuratorOctoFull.SetShown(page.empty, CuratorOctoFull.Length(lines) == 0)
	page.empty:SetText((remote and remote.empty) or (self.card and L["No copy of it here."]) or (self.dupes and L["No duplicate here."]) or L["No copy here."])
	-- (1.14.0: the album chosen, said by its menu again when it changed elsewhere)
	if page.album and page.albumShown ~= (self.series or false) then
		page.albumShown = self.series or false
		if page.album.GenerateMenu then
			page.album:GenerateMenu()
		end
	end
	local label = string.format(L["Page %d / %d"], self.page, pages)
	if self.rarity then
		local r = ns.RARITY[self.rarity]
		label = "|cff" .. A.U.Hex(r.text) .. L[r.label] .. "|r  ·  " .. label
	end
	A:ShowPager(pages > 1 or self.rarity ~= nil)
	A:SetPager(self.page, pages, label)
end

-------------------------------------------------------------------------------
-- (1.14.3, his word of November 6: « Quand je regarde la collection de quelqu'un ca serait bien de voir le full
-- inventaire ... et tout quoi! ») Another player's inventory, where their collection opens (UI/Album.lua: in the place of
-- the tab of their albums): every copy as it is, its wear, its pattern, its case, its seal; their cards of the cases;
-- their boosters, displays, cases and keys in Everything; the same filters, orders, rarities, albums and duplicates as
-- mine, page by page, each page asked of their Curator, which picks it as their own inventory would (IU:Remote, Comm.lua).
-- Read only: nothing to sell, nothing to open; a click on a copy shows its card in their album.
-------------------------------------------------------------------------------
-- Whose inventory the page shows (nil: mine).
function IU:Who()
	return (A.mode == "inventory" and A.member) or nil
end

-- The choices of the page, as another player's Curator is asked them.
function IU:Params()
	return { filter = self.filter or "all", sort = self.sort or "new", rarity = self.rarity, series = self.series, dupes = self.dupes and true or false,
		page = self.page or 1 }
end

-- Another player's inventory as it opens: Everything, its first page (their order: mine). Mine kept as I left it, set
-- again when it shows (IU:Mine).
function IU:TheirHome(who)
	if self.sell then
		self:EndSell(true)
	end
	if not self.mineState then
		self.mineState = { filter = self.filter, page = self.page, rarity = self.rarity, series = self.series, dupes = self.dupes, card = self.card }
	end
	self.theirsOf = who and ns.Guild.Fold(who) or true
	self.card, self.filter, self.page, self.rarity, self.series, self.dupes = nil, "all", 1, nil, nil, nil
end

-- Mine again, as I left it before another player's.
function IU:Mine()
	local m = self.mineState
	self.mineState, self.theirsOf = nil, nil
	if m then
		self.filter, self.page, self.rarity, self.series, self.dupes, self.card = m.filter or "all", m.page or 1, m.rarity, m.series, m.dupes, m.card
	end
end

-- (a page of mine opened by itself: another player's seen before is forgotten, mine as asked)
function IU:Forget()
	self.mineState, self.theirsOf = nil, nil
end

-- (asked by another player, Comm.lua) A page of my inventory as it shows with their choices (p: { filter, sort, rarity,
-- series, dupes, page }): its lines ({ x, n }: n the number of a copy among those of its card), how many lines in all,
-- in each filter, in each rarity; how many copies, appraised, boosters, displays. Mine as it was after it.
function IU:Remote(p)
	local keep = { self.filter, self.sort, self.rarity, self.card, self.series, self.dupes, self.sell }
	self.filter, self.sort, self.rarity, self.card, self.series, self.dupes, self.sell = p.filter or "all", p.sort or "new", p.rarity, nil, p.series,
		p.dupes or nil, nil
	local ok, sv = pcall(self.Survey, self)
	local displays = 0
	if ok and type(sv) == "table" then
		local okc, _, d = pcall(self.Counts, self, sv.chips)
		displays = (okc and tonumber(d)) or 0
	end
	self.filter, self.sort, self.rarity, self.card, self.series, self.dupes, self.sell = keep[1], keep[2], keep[3], keep[4], keep[5], keep[6], keep[7]
	if not (ok and type(sv) == "table") then
		return nil
	end
	local all = CP:All()
	local copies, graded = CuratorOctoFull.Length(all), 0
	for _, x in ipairs(all) do
		if CP.Grade(x.rec) and x.rec.sl ~= false then
			graded = graded + 1
		end
	end
	if self.CaseTotals then
		local cn, cg = self:CaseTotals()
		copies, graded = copies + cn, graded + cg
	end
	local lines = sv.lines
	local pages = math.max(1, math.ceil(CuratorOctoFull.Length(lines) / PER))
	local page = math.max(1, math.min(math.floor(tonumber(p.page) or 1), pages))
	local out = {}
	for i = (page - 1) * PER + 1, math.min(CuratorOctoFull.Length(lines), page * PER) do
		local x = lines[i]
		local n
		if x.card and x.rec then
			n = ns.CopiesUI:Index(x.card, x.rec.i)
		elseif x.case and self.CaseIndex then
			n = self:CaseIndex(x.case)
		end
		out[CuratorOctoFull.Length(out) + 1] = { x = x, n = n }
	end
	return { lines = out, total = CuratorOctoFull.Length(lines), page = page, chips = sv.chips, gems = sv.gems, copies = copies, graded = graded,
		packs = ns.TotalPacks() + IU.GoldenCount(), displays = displays }
end

-- The page of another player's inventory: what came of it (Comm.lua: G:InventoryView, asked when it is not there or
-- old), its counts (of the page that came last while it comes), why there is none (asked, in combat, no answer, a
-- Curator of before).
function A:RefreshTheirInventory(who)
	local f = self.frame
	local page = f.inv
	local G = ns.Guild
	if IU.sell then
		IU:EndSell(true)
	end
	if IU.theirsOf ~= G.Fold(who) then
		IU:TheirHome(who)
	end
	if IU.filter == "packs" or IU.filter == "cases" or IU.filter == "keys" then
		IU.filter = "all"
	end
	IU.card, IU.takes = nil, nil
	Portrait(f, false)
	local r = G:InventoryView(who, IU:Params())
	local v = r.view
	local c = v or r.last
	local short = G:Short(who)
	if c then
		self:SetTitle(string.format(L["%s's inventory"], short), string.format(L["%s copies · %s boosters · %s displays"], ns.Num(c.copies), ns.Num(c.packs), ns.Num(c.displays)))
		self:SetBar(c.graded, math.max(1, c.copies), string.format(L["Appraised: %d / %d"], c.graded, c.copies))
	else
		self:SetTitle(string.format(L["%s's inventory"], short), "")
		self:SetBar(0, 1, "")
	end
	IU:PaintChips(page, c and c.chips or {})
	IU:PaintGems(f, c and c.gems or {}, true)
	page.only:Hide()
	page.album:Show()
	page.dupes:Show()
	ns.CopiesUI.PaintChip(page.dupes, L["Duplicates only"], nil, IU.dupes and true or false)
	page.sort:Show()
	page.sort:ClearAllPoints()
	page.sort:SetPoint("RIGHT", page.dupes, "LEFT", -10, 0)
	S.Fit(page.sort:GetFontString() or page.sort.label, L[SORT_LABEL[IU.sort] or SORT_LABEL.new], page.w / 2 - SORT_GAP - page.dupes:GetWidth() - 36, 12, 8)
	Width(page.sort)
	IU:PaintSell()
	if IU.HideCasesPage then
		IU:HideCasesPage(page)
	end
	local empty
	if r.state == "wait" then
		empty = string.format(L["Waiting for %s..."], short)
	elseif r.state == "busy" then
		empty = string.format(L["%s is in combat: their inventory comes in a moment."], short)
		-- (asked again in a moment)
		if not IU.busyWake then
			IU.busyWake = true
			ns.Delay(G.INV_BUSY + 0.1, function()
				IU.busyWake = nil
				if A.frame:IsShown() and IU:Who() == who and not (A.detail and A.detail:IsShown()) then
					A:Refresh()
				end
			end, A)
		end
	elseif r.state == "old" then
		empty = string.format(L["%s must update Curator to show their inventory."], short)
	elseif r.state == "silent" then
		empty = string.format(L["%s did not answer (offline?)"], short)
	end
	return IU:PaintGrid(page, v and v.lines or {}, { total = (v and v.total) or (r.last and r.last.total) or 0, known = v ~= nil, empty = empty,
		stamp = v and tostring(v.t) or "" })
end

-- (their page came, or no answer: shown)
ns.On("INVENTORY", function(name)
	local who = IU:Who()
	if who and A.frame and A.frame:IsShown() and ns.Guild.Fold(who) == ns.Guild.Fold(name) and not (A.detail and A.detail:IsShown()) then
		A:Refresh()
	end
end)

-- (the gems of the head: on the inventory, its copies of each rarity)
do
	local setFilter = A.SetFilter
	function A:SetFilter(r)
		if self.mode == "inventory" then
			return IU:SetRarity(r)
		end
		return setFilter(self, r)
	end

	local countTooltip = A.CountTooltip
	function A:CountTooltip(b)
		if self.mode ~= "inventory" then
			return countTooltip(self, b)
		end
		local r = ns.RARITY[b.rarity]
		GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L[r.label], r.text[1], r.text[2], r.text[3])
		GameTooltip:AddLine(string.format(L["Copies: %d"], b.copies or 0), 1, 1, 1)
		GameTooltip:AddLine(IU.rarity == b.rarity and L["Click to show every copy"] or L["Click to show only these copies"], GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:Show()
	end
end

-------------------------------------------------------------------------------
-- Opened
-------------------------------------------------------------------------------
-- The inventory opened (filter: the key of one of its filters, "away" the copies at an enchanter; nil: every copy).
function IU:Open(filter)
	A:Build()
	A:HideDetail()
	local ok = false
	for _, f in ipairs(FILTERS) do
		if f.key == filter then
			ok = true
		end
	end
	-- (the boosters: not in the sale; the page of the boosters, under the bar)
	if filter == "packs" then
		self:Home()
		return IU.ShowPage("boosters")
	end
	self:Forget()
	self.card, self.filter, self.page, self.rarity = nil, ok and filter or "all", 1, nil
	IU.ShowPage()
end

-- The inventory opened on one card: its copies only.
function IU:OpenOn(card)
	A:Build()
	A:HideDetail()
	self:Forget()
	self.card, self.filter, self.page, self.rarity = card, "all", 1, nil
	IU.ShowPage()
end

-- Where the inventory opens by itself (its tab, the minimap button, /curator): (1 November, his word) on Everything,
-- its first page (on its boosters before, since the first test of 1.13.0).
function IU:Home()
	if self.sell then
		self:EndSell(true)
	end
	self:Forget()
	self.card, self.filter, self.page, self.rarity = nil, "all", 1, nil
	-- (the boosters themselves: not the albums to choose, nor the displays)
	A.boosterPick, A.dispView = nil, nil
end

-- The album shown on the inventory as it is set now (mode: "boosters", its boosters; else its copies). The album
-- closed: opened on it (never A:Show, which opens it on its boosters).
function IU.ShowPage(mode)
	mode = mode or "inventory"
	if A.frame:IsShown() then
		A:SetMode(mode)
	else
		A:Open(mode)
	end
end

-- (1.13.0, after its first test) The album opens on the inventory; its tab too, from any page. (1 November, his word:
-- on Everything, its first page; on its boosters before.)
do
	function A:Show()
		self:Build()
		if self.frame:IsShown() then
			return
		end
		IU:Home()
		self:Open("inventory")
	end

	local tabClick = A.TabClick
	function A:TabClick(mode, ...)
		if mode == "inventory" and not self.member then
			if self.mode == "inventory" and IU.filter == "all" and not IU.card and not IU.rarity and (IU.page or 1) == 1 and not IU.sell
				and not (self.detail and self.detail:IsShown()) then
				return
			end
			IU:Home()
			return tabClick(self, "inventory", unpack(arg, 1, arg.n))
		end
		-- (1.14.3: another player's inventory, its tab clicked on it: Everything, its first page)
		if mode == "inventory" and self.member and self.mode == "inventory" then
			IU:TheirHome(self.member)
		end
		return tabClick(self, mode, unpack(arg, 1, arg.n))
	end
end

local function Changed()
	if A.frame and A.frame:IsShown() and A.mode == "inventory" and not (A.detail and A.detail:IsShown()) then
		A:Refresh()
	end
end
ns.On("COPIES_CHANGED", Changed)
ns.On("DISPLAYS_CHANGED", Changed)
-- (1.14.0, after its first test: a case found, opened, a key bought, a card of a case appraised or exchanged)
ns.On("CASES_CHANGED", Changed)
-- (1.14.2: a golden booster given or opened, Golden.lua: in Everything)
ns.On("GOLDEN_CHANGED", Changed)

-- (the reseller there, or gone: the way to the sale, or its end)
ns.On("RESELLER", function(here)
	if not here then
		IU:EndSell()
	end
	if A.frame and A.frame:IsShown() and A.mode == "inventory" then
		IU:PaintSell()
	end
end)
