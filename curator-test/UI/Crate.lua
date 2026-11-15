local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.14.0, its first test) The opening of a case, as the case openings of CS2 make it, with ranks of its own: nothing of
-- the rarities of the boosters and of the albums.
-- * The ranks of a case, their colours and their chances (those of CS2): rare (blue), restricted (purple), classified
--   (pink), covert (red), and priceless (gold), hidden behind one golden card with its question mark, never told how
--   many there are.
-- * First the case itself, in the room of the case (a hall blurred behind it): the case in 3D in the light
--   (UI/CrateBox.lua), turning slowly, turned with the mouse; under it what it holds, its cards in their rows by rank,
--   each inspected with a click (the card of the case, large: UI/CrateCard.lua).
-- * Opened: its latches spring, its lid rises, its light pours out and its dust of gold with it; what it holds goes
--   away and a band of its cards comes in its place, which runs past a mark, very fast at first, then slower and
--   slower, a tick each time a card goes under the mark, and it stops on one of them, anywhere in its width (the near
--   misses come from there, never placed on purpose). That card then comes out of the band, large, in its light: its
--   creature alive in its window, its condition on it (its scratches) and under it (the bar of the five conditions), and
--   now and then a forged finish, thunderforged or titanforged (their look on its frame). The sounds of its rank. A weapon
--   of legend makes its entrance first, as the gold of the cases of CS2: out of its golden card bursting in the band,
--   turning, to the middle, then into its card (CR:Entrance).
-- * (1.14.0, after its first test) Shown, the case falls before the eye, as CS2 shows a case taken from the inventory:
--   from over the top of the screen, turning, down onto its shadow, a jolt and a puff of dust; then what it holds and the
--   buttons. Back from the card that came out, the case that gave it goes in a blaze of light, rising into sparks; then
--   another one falls, while the player has one (for real), else the case stays as a ghost of itself, grey.
-- * The priceless cards: weapons of legend, as the knives of the cases of CS2 (CR.WEAPONS): Sulfuras, Thunderfury, the
--   four Atiesh, the Corrupted Ashbringer, Benediction, Anathema, Rhok'delar, Lok'delar, Quel'Serrar, Ashkandi, the
--   Dark Edge of Insanity, the Arcanite Reaper, the weapons of rank 14. A case with weapons of its own (its priceless
--   cards, Data/Crate*.lua) draws those only.
-- * The case of the month (CR.CASE: the case of the Paladin Collection N° 1, Data/CratePaladin.lua, CrateItems.lua; its
--   first edition; its case and the back of its cards in its own art). (1.14.0, the Paladin collection redone by its
--   author: 20 cards and its two weapons, each its picture over all of the card, in the frames of the Silver Hand,
--   UI/CrateCard.lua): spells (rare), the masters of the paladins of the capitals (restricted), great figures of the
--   paladins (classified), the prince of Lordaeron (covert), and its own weapons of legend, Sulfuras and Thunderfury,
--   in their layers. The room of its case: the banner of the paladins in the cathedral of Stormwind. What it holds is
--   shown from the least rare to the rarest, one after another, each tile the part of its picture the case shows,
--   scrolled with the wheel when they are more than the screen has room for.
-- * A card inspected (one of the case, or the card that came out): large, alive, turned in the hand to its back.
-- * (1.14.0) For real (CR:Show: /curator caisses, the inventory, the alert of a case found): the cases of its edition to
--   open and their keys (Cases.lua), a key bought here (CS.KEY_PRICE rubies). Opened, a case and a key go and its card
--   is drawn and kept (Cases.lua) before anything is shown: the band then runs to that card (its rank, its card or its
--   weapon, its condition, its finish), and a window closed before its end loses nothing. What the case holds shows
--   the cards of its collection the player has (how many of each), those he has not yet dimmed.
-- * The test of the author (his build: /curator test caisse [rank] [thunderforged|titanforged] [a card] [weapon]): that
--   case, nothing kept.
-------------------------------------------------------------------------------
local CR = {}
ns.CrateUI = CR

-- the ranks of a case: their words, their colours (those of CS2); the last one of gold, hidden behind its golden card
CR.RANKS = {
	{ key = "rare", label = "Rare", color = { 75 / 255, 105 / 255, 1 } },
	{ key = "restricted", label = "Restricted", color = { 136 / 255, 70 / 255, 1 } },
	{ key = "classified", label = "Classified", color = { 177 / 255, 48 / 255, 193 / 255 } },
	{ key = "covert", label = "Covert", color = { 235 / 255, 75 / 255, 75 / 255 } },
	{ key = "priceless", label = "Priceless", color = { 203 / 255, 172 / 255, 6 / 255 }, text = { 1, 0.84, 0.26 }, golden = true },
}
CR.TOP = CuratorOctoFull.Length(CR.RANKS)
-- their chances (those of CS2)
CR.TIERS = { { 1, 0.7992 }, { 2, 0.1598 }, { 3, 0.032 }, { 4, 0.0064 }, { CR.TOP, 0.0026 } }
-- the case of the month (Data/Crate*.lua: its key)
CR.CASE = "paladin1"
-- (no such case: the cards of the case of the first test, as many of each rank as a case of CS2 holds (the golden card
-- after them), its creatures taken among the cards of these rarities of the albums, the greater ones for the better
-- ranks)
CR.CONTENTS = { { 1, 7 }, { 2, 5 }, { 3, 3 }, { 4, 2 } }
CR.SOURCE = { { 1, 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6 } }
-- (1.14.0) The priceless cards: weapons of legend, each line as likely as another; one of its versions then (the four
-- of Atiesh, by the class that bears it; the weapons of rank 14, of the grand marshals of the Alliance and of the high
-- warlords of the Horde), among those the game knows. Its words for the test (/curator test caisse sulfuras...).
local RANK14 = {}
for _, side in ipairs({
	{ "Alliance", { 12584, 18827, 18830, 18833, 18836, 18838, 18843, 18847, 18855, 18865, 18867, 18869, 18873, 18876,
		23451, 23454, 23455, 23456, 234570, 235479, 235480, 235481 } },
	{ "Horde", { 16345, 18828, 18831, 18835, 18837, 18840, 18844, 18848, 18860, 18866, 18868, 18871, 18874, 18877,
		23464, 23465, 23466, 23467, 234548, 235476, 235477, 235478 } },
}) do
	for _, id in ipairs(side[2]) do
		RANK14[CuratorOctoFull.Length(RANK14) + 1] = { id = id, faction = side[1] }
	end
end
RANK14.words = { "rang14", "rank14", "r14", "rang", "rank", "14", "pvp", "jcj" }
CR.WEAPONS = {
	{ { id = 17182 }, words = { "sulfuras" } },
	{ { id = 19019 }, words = { "thunderfury", "lamebenie", "cherchevent" } },
	{ { id = 22632, class = "DRUID" }, { id = 22589, class = "MAGE" }, { id = 22631, class = "PRIEST" },
		{ id = 22630, class = "WARLOCK" }, words = { "atiesh" } },
	{ { id = 22691 }, words = { "ashbringer", "portecendres", "corrompu", "corrupted" } },
	{ { id = 18608 }, words = { "benediction" } },
	{ { id = 18609 }, words = { "anathema", "anatheme" } },
	{ { id = 18713 }, words = { "rhokdelar" } },
	{ { id = 18715 }, words = { "lokdelar" } },
	{ { id = 18348 }, words = { "quelserrar" } },
	{ { id = 19364 }, words = { "ashkandi" } },
	{ { id = 21134 }, words = { "darkedge", "insanity", "folie", "demence" } },
	{ { id = 12784 }, words = { "arcanite", "reaper", "faucheuse" } },
	RANK14,
}
-- (the words of the classes for a version of Atiesh)
CR.WEAPON_CLASSES = {
	druide = "DRUID", druid = "DRUID", mage = "MAGE", pretre = "PRIEST", priest = "PRIEST", demoniste = "WARLOCK",
	warlock = "WARLOCK", hexenmeister = "WARLOCK", priester = "PRIEST", druida = "DRUID", brujo = "WARLOCK",
	sacerdote = "PRIEST",
}
-- (1.14.0, after its second test) The weapons of legend by their item, taken as this file loads (nothing of another
-- addon since): what another player sends (their showcase, a link in the chat) names one of them, or nothing; its
-- class and its side as this list has them, never as they were sent (Comm.lua, UI/CaseShow.lua).
do
	local of = {}
	for _, line in ipairs(CR.WEAPONS) do
		for _, w in ipairs(line) do
			of[w.id] = { id = w.id, class = w.class, faction = w.faction }
		end
	end
	-- A weapon of legend by its item (its number, or its digits as sent: seven at most, no zero first), else nil.
	function CR.WeaponOf(id)
		if type(id) == "string" then
			if not CuratorOctoFull.Match(id, "^[1-9]%d?%d?%d?%d?%d?%d?$") then
				return nil
			end
			id = tonumber(id)
		end
		local w = type(id) == "number" and of[id] or nil
		return w and { id = w.id, class = w.class, faction = w.faction } or nil
	end
end
-- the cards of the band (the one it stops on, and the one under the mark at first, follow the width of the band:
-- cards on both sides of the mark, from its start to its end); their size (as the band of CS2 shows them), the gap
-- between two of them, the band as wide as this at most
CR.CARDS = 60
CR.W, CR.H, CR.GAP, CR.MAX_W = 188, 141, 6, 1100
-- the run: its seconds (a little more or less each time), how it slows down (the power of its easing: from the full
-- speed down to none), and where in its card it stops (as far as this part of its width from its middle, either way:
-- always on the card, never in a gap)
CR.SPIN, CR.SPIN_MORE, CR.SLOW, CR.LAND = 6.5, 0.4, 3, 0.42
-- a tick at most every this many seconds (the fastest of the run brings some twenty-five cards a second)
CR.TICK_GAP = 0.03
-- the forged finishes of a card of a case, as the boosters forge theirs: titanforged one card in fifty, thunderforged
-- one in twelve or so (the rarest first)
CR.FINISHES = { { "titan", 0.02 }, { "thunder", 0.08 } }
CR.FINISH_NAME = { thunder = "Thunderforged", titan = "Titanforged" }
-- the condition of a card: a grade of the expert (Expertise.lua), the step of its lowest grade; their colours on the bar
CR.CONDITION = { { 9, "Mint" }, { 7, "Excellent" }, { 5, "Good" }, { 3, "Worn" }, { 1, "Poor" } }
CR.WEAR_COLOURS = { { 0.33, 0.78, 1 }, { 0.42, 0.9, 0.55 }, { 0.98, 0.86, 0.35 }, { 1, 0.56, 0.24 }, { 0.92, 0.28, 0.28 } }
-- the card that comes out (its width), and the seconds of what follows the stop: the card, its words, what it came
-- with, the buttons
CR.CARD_W = 300
CR.AT_CARD, CR.AT_WORDS, CR.AT_EXTRA, CR.AT_BUTTONS = 0.75, 1.35, 1.9, 2.4
-- the screen of the case: the cards it holds in rows of so many at most (their width between these), as many rows
-- shown at once at most (the others scrolled to); the case as wide as this part of the height of the screen (between
-- these, and as the room left allows), drawn this wide and scaled; the room it takes over its middle (its lid open:
-- UI/CrateBox.lua) and under it, in its widths
CR.PER_ROW, CR.ITEM_MIN, CR.ITEM_MAX, CR.ITEM_GAP = 10, 74, 108, 10
-- (fewer cards in a row on a narrower screen, down to 6, until each is that wide: their names on two lines at most)
CR.ITEM_FIT = 96
CR.MAX_ROWS = 3
-- (under each card its name, on two lines when it is long, and its album or what it is)
CR.ITEM_TEXT = 44
CR.CASE_K, CR.CASE_MIN, CR.CASE_MAX, CR.CASE_BASE = 0.70, 420, 760, 520
CR.CASE_UP, CR.CASE_DOWN = 0.36, 0.26
-- the opening, in seconds from the click: its latches, its lid rising, what it holds going, the band coming, its run;
-- and back to the case: its lid coming down
CR.AT_LID, CR.AT_AWAY, CR.AT_BAND, CR.AT_RUN, CR.LID_TIME, CR.SHUT_TIME = 0.12, 0.18, 0.5, 0.85, 0.6, 0.4
-- the dust of gold out of the case open: its specks, the seconds each rises
CR.DUST, CR.DUST_LIFE = 14, 2.6
-- (1.14.0, after its first test) the fall of the case (seconds: its fall, its bounce), its vanishing (seconds; its
-- sparks), its ghost (its alpha), the puffs of dust where it lands
CR.FALL, CR.BOUNCE, CR.VANISH, CR.MOTES, CR.GHOST, CR.PUFFS = 0.62, 0.26, 0.95, 18, 0.36, 7
-- (1.14.0) the entrance of a weapon of legend (CR:Entrance), as CS2 shows the gold of its cases: its flight out of
-- the band, its stay in the middle, its way into its card (seconds); its size in the middle (points: its model drawn
-- as long as the diagonal of its frame, its camera as far as on its card); its turn (radians a second at first, at
-- the end; the seconds it takes to slow down)
CR.ARM_OUT, CR.ARM_HOLD, CR.ARM_IN = 1.1, 1.0, 0.65
CR.ARM_SIZE = 620
CR.ARM_SPIN = { 18, 0.9, 0.45 }

-- the gold of the light of the case, the words of the forged finishes, the dark of the band
local GOLD = { 1, 0.78, 0.26 }
local FINISH_INK = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.86, 0.46 } }
local BAND = { 0.05, 0.05, 0.07 }
-- the tick of a card under the mark (an option of the game ticked, else the scroll of the chat)
local SND_TICK = { 856, 1115 }
-- the lid rising (a box opened, else a heavy book put down), and coming down
local SND_LID = { 64329, 1201 }
local SND_SHUT = { 1201 }

local function Text(parent, size, flags, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	ns.SetFont(fs, size, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 1)
	return fs
end

local function Tex(parent, layer, sub, file, blend)
	local t = parent:CreateTexture(nil, layer, nil, sub)
	if file then
		t:SetTexture(MEDIA .. file)
	end
	if blend then
		t:SetBlendMode(blend)
	end
	return t
end

-- (1.14.0, for real) the seconds a first click arms the button of a key (its rubies: a second click within them buys
-- it, as the other buttons that spend rubies)
CR.ARM = 3
local function Armed(b)
	return b.armed ~= nil and GetTime() - b.armed < CR.ARM
end

-- The colour of a rank, and of its words.
local function Colour(tier)
	return CR.RANKS[tier].color
end
local function Ink(tier)
	local r = CR.RANKS[tier]
	return r.text or r.color
end

-- The sounds of a rank coming out (those of the boosters, louder as it climbs; the priceless one, the gong and the
-- fanfare of the titans).
local function Fanfare(tier)
	local S_ = ns.SND
	local list = ({
		{ S_.reveal[3] },
		{ S_.reveal[4] },
		{ S_.reveal[5], S_.impact[4] },
		{ S_.reveal[6], S_.impact[5], S_.rumble },
		{ S_.gong, S_.titanFanfare, S_.impact[6] },
	})[tier] or {}
	for _, snd in ipairs(list) do
		ns.Play(snd)
	end
end

-- The portrait of a creature in a texture, cut to its width and its height, its middle kept (false: the client has
-- none, or the creature none).
local function Portrait(tex, display, w, h)
	if not (display and SetPortraitTextureFromCreatureDisplayID and pcall(SetPortraitTextureFromCreatureDisplayID, tex, display)) then
		return false
	end
	if w >= h then
		local k = (1 - h / w) / 2
		tex:SetTexCoord(0, 1, k, 1 - k)
	else
		local k = (1 - w / h) / 2
		tex:SetTexCoord(k, 1 - k, 0, 1)
	end
	return true
end

-------------------------------------------------------------------------------
-- The case and the draw
-------------------------------------------------------------------------------
-- The cards of some rarities among all the albums (never the limited edition of no booster, the Hardcup Saison 3).
local pools = {}
local function Pool(rarities)
	local key = table.concat(rarities, ",")
	local p = pools[key]
	if not p then
		p = {}
		for _, s in ipairs(ns.Series or {}) do
			if s.byRarity and not s.limited then
				for _, r in ipairs(rarities) do
					for _, card in ipairs(s.byRarity[r] or {}) do
						p[CuratorOctoFull.Length(p) + 1] = card
					end
				end
			end
		end
		pools[key] = p
	end
	return p
end

-- The case: its cards of each rank, and the list of what it holds. The case of the month (CR.CASE): its own cards,
-- from the least rare to the rarest (the rare ones, the restricted, the classified, the covert, the golden card last),
-- each in the order of its data. Else the case of the first test: creatures drawn among all the albums (none twice by
-- its name), in the order of their names, by rank, the golden card last.
function CR:MakeCase()
	local CI = ns.CrateItems
	-- (the edition shown for real, else the case of the month)
	local own = CI and CI:Case(self.edition or self.CASE)
	-- (the case in the art of its edition, else in the one of the first test)
	local box = self.frame and self.frame.case
	if box and box.SetArt then
		box:SetArt(own and own.def.art and own.def.art.box or nil)
	end
	-- (1.14.0, the Paladin collection redone) the room of its case: its own picture, else the hall
	self:Room(own and own.def.art or nil)
	if own then
		local case, list = {}, {}
		for r = 1, self.TOP - 1 do
			case[r] = own[r]
			for _, e in ipairs(own[r] or {}) do
				list[CuratorOctoFull.Length(list) + 1] = { tier = r, entry = e }
			end
		end
		-- (the golden card of the secret, in the style of its case)
		list[CuratorOctoFull.Length(list) + 1] = { tier = self.TOP, secret = true, def = own.def }
		self.case, self.caseList, self.own = case, list, own
		return list
	end
	self.own = nil
	local case, list, seen = {}, {}, {}
	for _, c in ipairs(self.CONTENTS) do
		local _, c = _, c; local r, n = c[1], c[2]
		local p = Pool(self.SOURCE[r])
		local got = {}
		local tries = 0
		while CuratorOctoFull.Length(got) < math.min(n, CuratorOctoFull.Length(p)) and tries < n * 60 do
			tries = tries + 1
			local card = p[math.random(CuratorOctoFull.Length(p))]
			local name = C:Name(card)
			if not seen[name] then
				seen[name] = true
				got[CuratorOctoFull.Length(got) + 1] = card
			end
		end
		table.sort(got, function(a, b)
			return C:Name(a) < C:Name(b)
		end)
		case[r] = got
		for _, card in ipairs(got) do
			list[CuratorOctoFull.Length(list) + 1] = { tier = r, card = card }
		end
	end
	list[CuratorOctoFull.Length(list) + 1] = { tier = self.TOP, secret = true }
	self.case, self.caseList = case, list
	return list
end

-- (1.14.0, the Paladin collection redone) The room of a case (art: its art, Data/Crate*.lua; nil: the hall of the
-- first cases): its picture (room; its width over its height: roomAspect), how dark it is made under what is over it
-- (roomDim).
function CR:Room(art)
	local f = self.frame
	if not f then
		return
	end
	local file = art and art.room or nil
	f.room:SetTexture(MEDIA .. (file or "CrateRoom"))
	self.roomAspect = (file and tonumber(art.roomAspect)) or 2
	CuratorOctoFull.ColorTexture(f.bg, 0.01, 0.01, 0.015, (file and tonumber(art.roomDim)) or 0.5)
end

-- A rank drawn with the chances of the case.
function CR:Roll()
	local x = math.random()
	for _, t in ipairs(self.TIERS) do
		if x < t[2] then
			return t[1]
		end
		x = x - t[2]
	end
	return self.TIERS[1][1]
end

-- A card of a rank, at random: one of the case, of that rank (an entry of the case of the month, a creature of the case
-- of the first test; no case yet, or none of it: one of all the albums, of the rarities that rank takes them from).
function CR:Draw(tier)
	local own = self.case and self.case[tier]
	if own and CuratorOctoFull.Length(own) > 0 then
		return own[math.random(CuratorOctoFull.Length(own))]
	end
	local p = Pool(self.SOURCE[tier] or { 6 })
	return p[math.random(CuratorOctoFull.Length(p))]
end

-- Whether the game has an item (a weapon of another time it does not have is never drawn).
local function Exists(id)
	if C_Item and C_Item.DoesItemExistByID then
		local ok, yes = pcall(C_Item.DoesItemExistByID, id)
		return not ok or yes ~= false
	end
	return true
end

-- A weapon of the priceless cards, at random: a line (each as likely as another; line: that one), then one of its
-- versions the game has (class: that version of Atiesh). A copy, its own.
function CR:DrawWeapon(line, class)
	local lines = self.WEAPONS
	-- (1.14.0, the Paladin collection redone: a case with weapons of its own, one of them, each as likely)
	local own = self.own and self.own.def.priceless
	if own and not line then
		local mine = {}
		for _, x in ipairs(own) do
			for i, l in ipairs(lines) do
				for _, w in ipairs(l) do
					if w.id == x[1] then
						mine[CuratorOctoFull.Length(mine) + 1] = { id = w.id, class = w.class, faction = w.faction, line = i }
					end
				end
			end
		end
		if CuratorOctoFull.Length(mine) > 0 then
			return mine[math.random(CuratorOctoFull.Length(mine))]
		end
	end
	for _ = 1, 40 do
		local i = line or math.random(CuratorOctoFull.Length(lines))
		local known = {}
		for _, w in ipairs(lines[i] or {}) do
			if Exists(w.id) and (not class or w.class == class) then
				known[CuratorOctoFull.Length(known) + 1] = w
			end
		end
		if CuratorOctoFull.Length(known) == 0 and class then
			class = nil
		elseif CuratorOctoFull.Length(known) > 0 then
			local w = known[math.random(CuratorOctoFull.Length(known))]
			return { id = w.id, class = w.class, faction = w.faction, line = i }
		else
			line = nil
		end
	end
	return { id = lines[1][1].id, line = 1 }
end

-- The line of the weapons a word says (sulfuras, atiesh, rang14...: their words, plain), and a class of Atiesh.
function CR:WeaponWord(word)
	for i, l in ipairs(self.WEAPONS) do
		for _, w in ipairs(l.words or {}) do
			if w == word then
				return i
			end
		end
	end
	return nil, self.WEAPON_CLASSES[word]
end

-- A card of a rank drawn for the band: a card of the case (an entry: a spell, a figure, an armour; a creature for the
-- case of the first test); the priceless one, a weapon (its golden card in the band). The card it stops on: the one
-- asked for, when one was (its weapon, its entry).
function CR:Pick(tier, forced)
	local f = forced or {}
	if tier == self.TOP then
		-- (for real: the weapon Cases.lua drew, that very version)
		local w = f.tier == tier and f.weapon
		if w then
			return { tier = tier, weapon = { id = w.id, class = w.class, faction = w.faction, line = w.line }, secret = true }
		end
		return { tier = tier, weapon = self:DrawWeapon(f.line, f.class), secret = true }
	end
	if f.entry and f.tier == tier then
		return { tier = tier, entry = f.entry }
	end
	local x = self:Draw(tier)
	if type(x) == "table" and x.kind then
		return { tier = tier, entry = x }
	end
	return { tier = tier, card = x }
end

-- The name of a card in the language of the game: its entry, its weapon (nil while the game does not know it), its
-- creature.
function CR:PickName(pick)
	if pick.entry then
		return ns.CrateItems:Name(pick.entry)
	elseif pick.weapon then
		return ns.CrateCard.WeaponName(pick.weapon)
	elseif pick.card then
		return C:Name(pick.card)
	end
	return nil
end

-- The game asked for what the cards of the case need (the spells, the pieces of the armours), as the case is shown.
function CR:AskEntries()
	local own = self.own
	if not own then
		return
	end
	for r = 1, self.TOP - 1 do
		for _, e in ipairs(own[r] or {}) do
			ns.CrateItems:Ask(e)
		end
	end
end

-- The game asked for all the weapons (their names, their models), as the case is shown: known by the time one comes.
function CR:AskWeapons()
	for _, l in ipairs(self.WEAPONS) do
		for _, w in ipairs(l) do
			if Exists(w.id) then
				ns.CrateCard.Ask(w.id)
			end
		end
	end
end

-- The word of the condition of a grade (1 to 10).
function CR:Word(g)
	g = tonumber(g) or 1
	for _, step in ipairs(self.CONDITION) do
		if g >= step[1] then
			return step[2]
		end
	end
	return self.CONDITION[CuratorOctoFull.Length(self.CONDITION)][2]
end

-- What a card comes with (a test: nothing kept): its wear (31 October, his word: as the cards of the boosters, never its
-- condition in words: a grade drawn as a case draws it, its marks and its seed, UI/Wear.lua), and its forged finish
-- ("thunder", "titan"; nil: none; finish: that one, for the test).
function CR:Extras(finish)
	local E, W = ns.Expertise, ns.Wear
	local g = (E and E.Draw) and E:Draw() or math.random(1, 10)
	local seed = math.random(1, 999998)
	local wear = W and { g = g, m = W.MarksFor(g, W.Rng(seed + 77)), seed = seed } or nil
	if not finish then
		local r = math.random()
		for _, f in ipairs(self.FINISHES) do
			if r < f[2] then
				finish = f[1]
				break
			end
			r = r - f[2]
		end
	end
	return wear, finish
end

-------------------------------------------------------------------------------
-- A card as the case and its band show it (as CS2 shows what a case holds): its ground and the light of its rank
-- rising from its foot, its creature, its edge and the band of colour of its rank; the golden one of the priceless rank,
-- its medal, its question mark.
-------------------------------------------------------------------------------
local function NewTile(parent)
	local t = CreateFrame("Frame", nil, parent)
	t.ground = Tex(t, "BACKGROUND", 0, "CrateTile")
	t.ground:SetAllPoints()
	t.ground:SetTexCoord(0, 0.5, 0, 96 / 256)
	t.light = Tex(t, "BORDER", 0, "CrateTile")
	t.light:SetAllPoints()
	t.light:SetTexCoord(0.5, 1, 0, 96 / 256)
	t.gold = Tex(t, "BORDER", 1, "CrateTile")
	t.gold:SetAllPoints()
	t.gold:SetTexCoord(0, 0.5, 128 / 256, 224 / 256)
	-- (1.14.0, the Paladin collection redone) a card with its picture: the part of it the case shows, all the tile, the
	-- light of its rank rising over it
	t.art = t:CreateTexture(nil, "BORDER")
	t.art:SetPoint("TOPLEFT", 1, -1)
	t.art:SetPoint("BOTTOMRIGHT", -1, 1)
	t.art:Hide()
	-- (its creature in a medallion: its portrait cut round, a halo of its rank behind it, a ring of its rank round it)
	t.halo = Tex(t, "BORDER", 2, "Glow", "ADD")
	t.halo:SetPoint("CENTER", 0, 3)
	t.pic = t:CreateTexture(nil, "ARTWORK", nil, 0)
	t.pic:SetPoint("CENTER", 0, 3)
	t.round = CuratorOctoFull.CreateMaskTexture(t)
	t.round:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	t.round:SetPoint("CENTER", t.pic, "CENTER")
	CuratorOctoFull.AddMaskTexture(t.pic, t.round)
	t.icon = t:CreateTexture(nil, "ARTWORK", nil, 1)
	t.icon:SetPoint("CENTER", 0, 3)
	t.ring = Tex(t, "ARTWORK", 3, "IconRing")
	t.ring:SetPoint("CENTER", 0, 3)
	CuratorOctoFull.SetDesaturated(t.ring, true)
	t.medal = Tex(t, "ARTWORK", 2, "AchMedal")
	t.medal:SetPoint("CENTER", 0, 1)
	t.q = Text(t, 22, "THICKOUTLINE")
	t.q:SetPoint("CENTER", 0, 1)
	t.q:SetText("?")
	t.q:SetTextColor(1, 0.95, 0.72)
	-- (31 October, his word: in the band, no more the cards to come: their rank only, its colour behind a question mark)
	t.blind = t:CreateTexture(nil, "BACKGROUND", nil, 2)
	t.blind:SetPoint("TOPLEFT", 1, -1)
	t.blind:SetPoint("BOTTOMRIGHT", -1, 1)
	t.blind:Hide()
	t.edge = Tex(t, "OVERLAY", 0, "CrateTile")
	t.edge:SetAllPoints()
	t.edge:SetTexCoord(0.5, 1, 128 / 256, 224 / 256)
	t.bar = t:CreateTexture(nil, "OVERLAY", nil, 1)
	t.bar:SetPoint("BOTTOMLEFT")
	t.bar:SetPoint("BOTTOMRIGHT")
	t.bar:SetHeight(3)
	return t
end

local function DressTile(t, pick, w, h, blind)
	CuratorOctoFull.SetSize(t, w, h)
	local col = Colour(pick.tier)
	CuratorOctoFull.ColorTexture(t.bar, col[1], col[2], col[3], 1)
	t.bar:SetHeight(math.max(3, math.floor(h / 32)))
	local secret = pick.secret and true or false
	t.light:SetDrawLayer("BORDER")
	t.blind:Hide()
	t.q:SetPoint("CENTER", 0, 1)
	t.q:SetTextColor(1, 0.95, 0.72)
	-- (31 October, his word: a card of the band, blind: its rank only, its colour behind, a question mark; more tension.
	-- The priceless one as it was: gold, its medal, its question mark)
	if blind and not secret then
		t.gold:Hide()
		t.medal:Hide()
		t.art:Hide()
		t.pic:Hide()
		t.icon:Hide()
		t.ring:Hide()
		CuratorOctoFull.ColorTexture(t.blind, col[1] * 0.42, col[2] * 0.42, col[3] * 0.42, 1)
		t.blind:Show()
		t.light:Show()
		t.light:SetVertexColor(col[1], col[2], col[3], 0.95)
		t.halo:Show()
		CuratorOctoFull.SetSize(t.halo, h * 1.1, h * 1.1)
		t.halo:SetVertexColor(col[1], col[2], col[3], 0.55)
		t.q:Show()
		ns.SetFont(t.q, math.max(16, math.floor(h * 0.5)), "THICKOUTLINE")
		t.q:SetPoint("CENTER", 0, 2)
		t.q:SetTextColor(math.min(1, 0.74 + col[1] * 0.26), math.min(1, 0.74 + col[2] * 0.26), math.min(1, 0.74 + col[3] * 0.26))
		return
	end
	CuratorOctoFull.SetShown(t.gold, secret)
	CuratorOctoFull.SetShown(t.medal, secret)
	CuratorOctoFull.SetShown(t.q, secret)
	t.art:Hide()
	CuratorOctoFull.SetShown(t.light, not secret)
	CuratorOctoFull.SetShown(t.halo, not secret)
	CuratorOctoFull.SetShown(t.ring, not secret)
	if secret then
		t.pic:Hide()
		t.icon:Hide()
		local m = h * 0.92
		CuratorOctoFull.SetSize(t.medal, m, m)
		ns.SetFont(t.q, math.max(14, h * 0.30), "THICKOUTLINE")
		return
	end
	t.light:SetVertexColor(col[1], col[2], col[3], 0.62)
	local s = math.floor(h * 0.74)
	CuratorOctoFull.SetSize(t.pic, s, s)
	CuratorOctoFull.SetSize(t.round, s, s)
	CuratorOctoFull.SetSize(t.halo, s * 1.7, s * 1.7)
	t.halo:SetVertexColor(col[1], col[2], col[3], 0.4)
	CuratorOctoFull.SetSize(t.ring, s * 1.16, s * 1.16)
	t.ring:SetVertexColor(math.min(1, col[1] * 1.25 + 0.15), math.min(1, col[2] * 1.25 + 0.15), math.min(1, col[3] * 1.25 + 0.15), 0.95)
	-- (a card of the case of the month: its picture; a figure, its portrait; a spell, an armour, its icon cut round)
	local e = pick.entry
	if e then
		local CI = ns.CrateItems
		local art = CI:Pic(e)
		if art then
            -- The 1.12 client can draw equal-layer textures in either order.
            t.light:SetDrawLayer("ARTWORK")
			t.art:SetTexture(art)
			t.art:SetTexCoord(CI.TileCoords(e.tile, w, h, e.kind == "spell"))
			t.art:Show()
			t.pic:Hide()
			t.icon:Hide()
			t.halo:Hide()
			t.ring:Hide()
			t.light:SetVertexColor(col[1], col[2], col[3], 0.55)
			return
		end
		if e.kind == "npc" and Portrait(t.pic, e.display, s, s) then
			t.pic:Show()
		else
			-- (a figure without its portrait: the light of the paladins)
			t.pic:SetTexture(ns.CrateItems:Icon(e) or (e.kind == "npc" and "Interface\\Icons\\Spell_Holy_HolyBolt") or "Interface\\Icons\\INV_Misc_QuestionMark")
			t.pic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			t.pic:Show()
		end
		t.icon:Hide()
		return
	end
	local card = pick.card
	if Portrait(t.pic, card.display, s, s) then
		t.pic:Show()
		t.icon:Hide()
	else
		-- (no creature to show: the emblem of its album)
		t.pic:Hide()
		t.icon:SetTexture(MEDIA .. ((card.series and card.series.set) or "SetElwynn"))
		CuratorOctoFull.SetSize(t.icon, s * 0.78, s * 0.78)
		t.icon:Show()
	end
end

-------------------------------------------------------------------------------
-- The scene
-------------------------------------------------------------------------------
function CR:Build()
	if self.frame then
		return self.frame
	end
	self.STEP = self.W + self.GAP
	local f = CreateFrame("Frame", "CuratorCrate", UIParent)
	f:SetAllPoints(UIParent)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorCrate")
	CuratorOctoFull.SetScript(f, "OnHide", function()
		CR:Stop()
		CR:CloseInspect(true)
		CR.state = nil
		-- (for real: a window closed before its card came out, its card said in the chat; it is kept)
		CR:Told()
	end)
	self.frame = f
	f.tiles, f.items = {}, {}
	-- the room: a hall in the blur, darker at its edges, a light falling on the case
	f.room = Tex(f, "BACKGROUND", -8, "CrateRoom")
	f.room:SetAllPoints()
	f.bg = f:CreateTexture(nil, "BACKGROUND", nil, -7)
	f.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.bg, 0.01, 0.01, 0.015, 0.5)
	f.vig = Tex(f, "BACKGROUND", -6, "Vignette")
	f.vig:SetAllPoints()
	f.vig:SetVertexColor(0, 0, 0, 1)
	f.spot = Tex(f, "BACKGROUND", -5, "Spotlight", "ADD")
	f.spot:SetVertexColor(1, 0.9, 0.7, 0.16)

	-- the case, its light when it opens, the glints of its latches, the light out of its seam, its dust of gold
	local case = ns.CrateBox.New(f, self.CASE_BASE)
	case:SetFrameLevel(f:GetFrameLevel() + 5)
	case:Paint()
	case:SetIdle(true)
	case:SetDraggable(true)
	f.case = case
	f.halo = Tex(f, "BACKGROUND", -4, "Glow", "ADD")
	f.halo:SetVertexColor(1, 0.82, 0.5, 1)
	f.halo:SetAlpha(0)
	local fx = CreateFrame("Frame", nil, f)
	fx:SetAllPoints()
	fx:SetFrameLevel(f:GetFrameLevel() + 12)
	f.fx = fx
	f.flare = Tex(fx, "OVERLAY", 0, "Flare", "ADD")
	f.flare:SetVertexColor(1, 0.86, 0.55, 1)
	f.flare:SetAlpha(0)
	f.sparks = {}
	for i = 1, 2 do
		local sp = Tex(fx, "OVERLAY", 1, "Twinkle", "ADD")
		sp:SetVertexColor(1, 0.9, 0.6, 1)
		sp:SetAlpha(0)
		f.sparks[i] = sp
	end
	f.dust = {}
	for i = 1, self.DUST do
		local d = Tex(fx, "OVERLAY", 2, (CuratorOctoFull.Mod(i , 3) == 0) and "Twinkle" or "Spark", "ADD")
		d:SetVertexColor(1, 0.84, 0.48, 1)
		d:SetAlpha(0)
		f.dust[i] = { tex = d, phase = (i - 1) / self.DUST, cycle = -1 }
	end
	f.hint = Text(fx, 11)
	f.hint:SetTextColor(0.62, 0.62, 0.66)
	f.hint:SetText(L["Turn it with the mouse."])
	-- (1.14.0, after its first test) the puffs of dust where the case lands; the sparks it goes into as it vanishes
	f.puffs = {}
	for i = 1, self.PUFFS do
		local p = Tex(fx, "ARTWORK", 0, "Puff")
		p:SetVertexColor(0.78, 0.72, 0.62, 1)
		p:SetAlpha(0)
		f.puffs[i] = p
	end
	f.motes = {}
	for i = 1, self.MOTES do
		local m = Tex(fx, "OVERLAY", 3, (CuratorOctoFull.Mod(i , 3) == 0) and "Twinkle" or "Spark", "ADD")
		m:SetVertexColor(1, 0.86, 0.5, 1)
		m:SetAlpha(0)
		f.motes[i] = m
	end
	f.vring = Tex(fx, "OVERLAY", 4, "Ring", "ADD")
	f.vring:SetVertexColor(1, 0.86, 0.5, 1)
	f.vring:SetAlpha(0)

	-- what it holds: a band of the dark of the room, its words, its cards
	local panel = CreateFrame("Frame", nil, f)
	panel:SetFrameLevel(f:GetFrameLevel() + 3)
	f.panel = panel
	panel.bg = panel:CreateTexture(nil, "BACKGROUND")
	panel.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(panel.bg, BAND[1], BAND[2], BAND[3], 0.84)
	for _, side in ipairs({ "TOP", "BOTTOM" }) do
		local line = panel:CreateTexture(nil, "BORDER")
		line:SetPoint(side .. "LEFT")
		line:SetPoint(side .. "RIGHT")
		line:SetHeight(1)
		CuratorOctoFull.ColorTexture(line, GOLD[1], GOLD[2], GOLD[3], side == "TOP" and 0.4 or 0.2)
	end
	panel.head = Text(panel, 13)
	panel.head:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -12)
	panel.head:SetTextColor(0.85, 0.85, 0.88)
	panel.head:SetText(L["Contains one of the following:"])
	panel.inspect = Text(panel, 11)
	panel.inspect:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -24, -14)
	panel.inspect:SetTextColor(0.6, 0.6, 0.64)
	panel.inspect:SetText(L["Click a card to inspect it."])
	-- (its rows scrolled with the wheel, a bar on its right)
	panel.track = panel:CreateTexture(nil, "BORDER")
	CuratorOctoFull.ColorTexture(panel.track, 1, 1, 1, 0.08)
	panel.track:Hide()
	panel.thumb = panel:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.ColorTexture(panel.thumb, GOLD[1], GOLD[2], GOLD[3], 0.7)
	panel.thumb:Hide()
	panel:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(panel, "OnMouseWheel", function(_, delta)
		if CR.state == "case" then
			CR:ScrollItems(delta > 0 and -1 or 1)
		end
	end)

	-- the band, and the window the cards run in
	local band = CreateFrame("Frame", nil, f)
	band:SetFrameLevel(f:GetFrameLevel() + 2)
	band:Hide()
	f.band = band
	band.bg = band:CreateTexture(nil, "BACKGROUND")
	band.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(band.bg, BAND[1], BAND[2], BAND[3], 0.94)
	for _, side in ipairs({ "TOP", "BOTTOM" }) do
		local line = band:CreateTexture(nil, "BORDER")
		line:SetPoint(side .. "LEFT")
		line:SetPoint(side .. "RIGHT")
		line:SetHeight(1)
		CuratorOctoFull.ColorTexture(line, GOLD[1], GOLD[2], GOLD[3], 0.4)
	end
	local clip = CreateFrame("Frame", nil, band)
	clip:SetPoint("TOPLEFT", 0, -1)
	clip:SetPoint("BOTTOMRIGHT", 0, 1)
	CuratorOctoFull.SetClipsChildren(clip, true)
	f.clip = clip
	local strip = CreateFrame("Frame", nil, clip)
	CuratorOctoFull.SetSize(strip, self.CARDS * self.STEP, self.H)
	f.strip = strip

	-- over the cards: the shadows of its two ends, the mark and its light, a gem at each end of it
	local over = CreateFrame("Frame", nil, band)
	over:SetAllPoints(clip)
	over:SetFrameLevel(band:GetFrameLevel() + 40)
	f.over = over
	for _, side in ipairs({ "LEFT", "RIGHT" }) do
		local t = over:CreateTexture(nil, "ARTWORK")
		t:SetTexture(MEDIA .. "FadeMask")
		t:SetVertexColor(BAND[1], BAND[2], BAND[3], 1)
		t:SetPoint("TOP" .. side)
		t:SetPoint("BOTTOM" .. side)
		t:SetWidth(170)
		-- (FadeMask: clear on its left, solid on its right; turned over for the left end)
		if side == "LEFT" then
			t:SetTexCoord(1, 0, 0, 1)
		end
	end
	f.markGlow = Tex(over, "OVERLAY", 0, "Beam", "ADD")
	f.markGlow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.75)
	f.markGlow:SetWidth(36)
	f.markGlow:SetPoint("TOP", over, "TOP", 0, 16)
	f.markGlow:SetPoint("BOTTOM", over, "BOTTOM", 0, -16)
	f.mark = over:CreateTexture(nil, "OVERLAY", nil, 1)
	CuratorOctoFull.ColorTexture(f.mark, GOLD[1], GOLD[2], GOLD[3], 0.95)
	f.mark:SetWidth(3)
	f.mark:SetPoint("TOP", over, "TOP", 0, 10)
	f.mark:SetPoint("BOTTOM", over, "BOTTOM", 0, -10)
	for _, side in ipairs({ "TOP", "BOTTOM" }) do
		local g = over:CreateTexture(nil, "OVERLAY", nil, 2)
		CuratorOctoFull.ColorTexture(g, GOLD[1], GOLD[2], GOLD[3], 1)
		CuratorOctoFull.SetSize(g, 11, 11)
		CuratorOctoFull.SetRotation(g, math.pi / 4)
		g:SetPoint("CENTER", f.mark, side, 0, 0)
	end

	-- at the top: its title and what it is
	f.title = Text(f, 28, "OUTLINE")
	f.title:SetTextColor(1, 0.82, 0.3)
	f.sub = Text(f, 13)
	f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -8)
	f.sub:SetTextColor(0.78, 0.78, 0.82)

	-- at the foot: the button that opens the case, the one that closes the scene
	local bar = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(bar, 380, 30)
	bar:SetFrameLevel(f:GetFrameLevel() + 10)
	f.buttons = bar
	f.open = S.Button(bar, L["Open the case"], 220, 30)
	f.open:SetPoint("LEFT", bar, "LEFT", 0, 0)
	CuratorOctoFull.SetScript(f.open, "OnClick", function()
		CR:Open()
	end)
	f.quit = S.Button(bar, L["Close"], 140, 30)
	f.quit:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
	CuratorOctoFull.SetScript(f.quit, "OnClick", function()
		f:Hide()
	end)
	-- (1.14.0, for real) the key of the edition bought (a first click arms it, a second one buys it), between them; what
	-- the case can do now under them; their words under the mouse
	f.key = S.Button(bar, "", 220, 30)
	f.key:SetPoint("LEFT", f.open, "RIGHT", 12, 0)
	CuratorOctoFull.SetScript(f.key, "OnClick", function()
		CR:KeyClick()
	end)
	CuratorOctoFull.SetScript(f.key, "OnEnter", function(b)
		CR:KeyTip(b)
	end)
	CuratorOctoFull.SetScript(f.key, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.batchButtons = {}
	local previous = f.open
	for _, count in ipairs({ 5, 10, 20 }) do
		local quantity = count
		local b = S.Button(bar, quantity .. "×", 58, 30)
		b:SetPoint("LEFT", previous, "RIGHT", 8, 0)
		CuratorOctoFull.SetScript(b, "OnClick", function() CR:StartBatch(quantity) end)
		CuratorOctoFull.SetScript(b, "OnEnter", function(self) CR:OpenTip(self, quantity) end)
		CuratorOctoFull.SetScript(b, "OnLeave", function() GameTooltip:Hide() end)
		f.batchButtons[quantity] = b
		previous = b
	end
	f.key:ClearAllPoints()
	f.key:SetPoint("LEFT", previous, "RIGHT", 12, 0)
	f.key:SetWidth(174)
	f.key:Hide()
	local status = CreateFrame("Frame", nil, f)
	status:SetAllPoints(f)
	status:SetFrameLevel(f:GetFrameLevel() + 65)
	f.batchStatus = Text(status, 14, "OUTLINE")
	f.batchStatus:SetPoint("TOP", f.sub, "BOTTOM", 0, -5)
	f.batchStatus:SetTextColor(1, 0.84, 0.26)
	f.batchStatus:Hide()
	CuratorOctoFull.SetScript(f.open, "OnEnter", function(b)
		CR:OpenTip(b)
	end)
	CuratorOctoFull.SetScript(f.open, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.why = Text(bar, 12)
	f.why:SetPoint("TOP", bar, "BOTTOM", 0, -10)
	f.why:SetWidth(640)
	f.why:SetTextColor(0.78, 0.74, 0.62)
	f.why:Hide()

	-- what comes out: the dark over the band, the light behind the card, the card, its words, the bar of its condition,
	-- the buttons
	local rv = CreateFrame("Frame", nil, f)
	rv:SetAllPoints()
	rv:SetFrameLevel(f:GetFrameLevel() + 60)
	rv:Hide()
	f.reveal = rv
	rv.dim = rv:CreateTexture(nil, "BACKGROUND")
	rv.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(rv.dim, 0, 0, 0, 0.78)
	rv.glow = Tex(rv, "BORDER", 0, "Glow", "ADD")
	CuratorOctoFull.SetSize(rv.glow, 760, 760)
	rv.rays = Tex(rv, "BORDER", 1, "Rays", "ADD")
	CuratorOctoFull.SetSize(rv.rays, 680, 680)
	rv.flash = Tex(rv, "OVERLAY", 7, "Glow", "ADD")
	CuratorOctoFull.SetSize(rv.flash, 900, 900)
	rv.ring = Tex(rv, "OVERLAY", 6, "Ring", "ADD")
	rv.card = ns.CrateCard.New(rv, self.CARD_W)
	rv.card:SetFrameLevel(rv:GetFrameLevel() + 5)
	-- (1.14.0) the coming of a forged card, as in the boosters (UI/Booster.lua: Thunderstrike; UI/Forge.lua: TitanStrike):
	-- behind the card, the light of the prism and its pillar; over it, the lightning, its bolts, the waves, the shards,
	-- the sparks; over everything, the flash and the light along the edges of the screen
	local bk = CreateFrame("Frame", nil, rv)
	bk:SetAllPoints()
	bk:SetFrameLevel(rv:GetFrameLevel() + 2)
	rv.behind = bk
	rv.prismRays = { Tex(bk, "BORDER", 3, "PrismRays", "ADD"), Tex(bk, "BORDER", 4, "PrismRays", "ADD") }
	rv.beams = {}
	for i = 1, 3 do
		rv.beams[i] = Tex(bk, "ARTWORK", 2, "Beam", "ADD")
	end
	rv.spikes = Tex(bk, "ARTWORK", 1, "Spikes", "ADD")
	local fx = CreateFrame("Frame", nil, rv)
	fx:SetAllPoints()
	fx:SetFrameLevel(rv:GetFrameLevel() + 30)
	rv.fx = fx
	rv.lightning = {}
	for i = 1, 2 do
		local b = Tex(fx, "OVERLAY", 5, "Lightning", "ADD")
		if i == 2 then
			b:SetTexCoord(1, 0, 0, 1)
		end
		rv.lightning[i] = b
	end
	rv.bolts = {}
	for i = 1, 3 do
		rv.bolts[i] = Tex(fx, "OVERLAY", 3, "StrikeBolt", "ADD")
	end
	rv.rings = {}
	for i = 1, 12 do
		rv.rings[i] = Tex(fx, "OVERLAY", 2, "Ring", "ADD")
	end
	rv.flare = Tex(fx, "OVERLAY", 4, "Flare", "ADD")
	rv.prismFlash = Tex(fx, "OVERLAY", 2, "PrismRays", "ADD")
	if ns.Particles then
		rv.sparks = ns.Particles:New(fx, 40)
		rv.streaks = ns.Particles:New(fx, 60, "Streak")
		rv.stars = ns.Particles:New(fx, 40, "Twinkle")
		rv.shards = ns.Particles:New(fx, 30, "PrismShard", "ADD", 4)
		rv.shards.spin = true
		rv.motes = ns.Particles:New(fx, 30)
	end
	local top = CreateFrame("Frame", nil, rv)
	top:SetAllPoints()
	top:SetFrameLevel(rv:GetFrameLevel() + 70)
	rv.edge = Tex(top, "OVERLAY", 5, "Edge", "ADD")
	rv.edge:SetAllPoints()
	rv.white = top:CreateTexture(nil, "OVERLAY", nil, 7)
	rv.white:SetAllPoints()
	CuratorOctoFull.ColorTexture(rv.white, 1, 1, 1, 1)
	self:FxClear()
	local words = CreateFrame("Frame", nil, rv)
	words:SetAllPoints()
	words:SetFrameLevel(rv:GetFrameLevel() + 40)
	rv.words = words
	rv.name = Text(words, 22, "OUTLINE")
	rv.rank = Text(words, 14, "OUTLINE")
	rv.rank:SetPoint("TOP", rv.name, "BOTTOM", 0, -6)
	rv.extra = Text(words, 15, "OUTLINE")
	rv.extra:SetPoint("TOP", rv.rank, "BOTTOM", 0, -10)
	-- (31 October, his word: no more the bar of the five conditions; its condition shows on the card, its wear)
	rv.note = Text(words, 11)
	rv.note:SetPoint("TOP", rv.extra, "BOTTOM", 0, -12)
	rv.note:SetTextColor(0.66, 0.66, 0.7)
	rv.again = S.Button(words, L["Open another case"], 220, 28)
	rv.again:SetPoint("TOP", rv.note, "BOTTOM", 0, -20)
	CuratorOctoFull.SetScript(rv.again, "OnClick", function()
		CR:Back()
	end)
	-- (1.14.0) the card that came out inspected: large, turned in the hand to its back (a click on it does it too)
	rv.inspect = S.Button(words, L["Inspect"], 140, 28)
	rv.inspect:SetPoint("RIGHT", rv.again, "LEFT", -12, 0)
	CuratorOctoFull.SetScript(rv.inspect, "OnClick", function()
		CR:Inspect(CR.win)
	end)
	rv.close = S.Button(words, L["Close"], 140, 28)
	rv.close:SetPoint("LEFT", rv.again, "RIGHT", 12, 0)
	CuratorOctoFull.SetScript(rv.close, "OnClick", function()
		f:Hide()
	end)
	rv.card:EnableMouse(true)
	CuratorOctoFull.SetScript(rv.card, "OnMouseUp", function(_, button)
		if button == "LeftButton" and rv.inspect:IsVisible() and rv.inspect:GetAlpha() > 0.5 then
			CR:Inspect(CR.win)
		end
	end)
	-- (its rays turn; the light of the prism behind a titanforged card turns; the card shakes as lightning strikes it)
	CuratorOctoFull.SetScript(rv, "OnUpdate", function(_, elapsed)
		rv.spin = (rv.spin or 0) + elapsed * 0.22
		CuratorOctoFull.SetRotation(rv.rays, rv.spin)
		CR:FxTick(elapsed)
	end)
	-- (1.14.0) the weapon of a priceless card in its entrance (CR:Entrance): over the card, loaded while the band runs
	f.arm = ns.CrateCard.NewArm(f, f:GetFrameLevel() + 90)
	if f.arm then
		CuratorOctoFull.SetScript(f.arm, "OnUpdate", function(m, elapsed)
			ns.CrateCard.ArmTick(m, elapsed)
		end)
	end

	-- a card inspected (of the case, or the one that came out): the dark, its light, the card held in the hand (dragged it
	-- turns all the way round to its back, a click on it turns it over, the wheel brings it closer: UI/Inspect.lua), its
	-- words; Back, and it goes
	local ins = CreateFrame("Frame", nil, f)
	ins:SetAllPoints()
	ins:SetFrameLevel(f:GetFrameLevel() + 80)
	ins:EnableMouse(true)
	ins:Hide()
	f.inspect = ins
	-- (31 October, his word: no words over one another: a room of its own, the hall in the dark, nothing of what is behind
	-- it seen through)
	ins.room = Tex(ins, "BACKGROUND", -8, "CrateRoom")
	ins.room:SetAllPoints()
	ins.dim = ins:CreateTexture(nil, "BACKGROUND", nil, -7)
	ins.dim:SetAllPoints()
	CuratorOctoFull.ColorTexture(ins.dim, 0, 0, 0, 0.82)
	ins.vig = Tex(ins, "BACKGROUND", -6, "Vignette")
	ins.vig:SetAllPoints()
	ins.vig:SetVertexColor(0, 0, 0, 1)
	ins.glow = Tex(ins, "BORDER", 0, "Glow", "ADD")
	CuratorOctoFull.SetSize(ins.glow, 700, 700)
	-- (where it is held: a point placed by the layout; on it, without an offset, the frame scaled for the zoom, the card in it)
	ins.spot = CreateFrame("Frame", nil, ins)
	CuratorOctoFull.SetSize(ins.spot, 1, 1)
	ins.holder = CreateFrame("Frame", nil, ins.spot)
	CuratorOctoFull.SetSize(ins.holder, 1, 1)
	ins.holder:SetPoint("CENTER", ins.spot, "CENTER")
	ins.holder:SetFrameLevel(ins:GetFrameLevel() + 2)
	ins.card = ns.CrateCard.New(ins.holder, self.CARD_W)
	ins.card:SetFrameLevel(ins:GetFrameLevel() + 5)
	if ns.Inspect then
		ns.Inspect:Attach(ins.card, ins.holder, { zoom = { 0.85, 1.5, 1 }, lean = false })
	end
	local iw = CreateFrame("Frame", nil, ins)
	iw:SetAllPoints()
	iw:SetFrameLevel(ins:GetFrameLevel() + 40)
	ins.words = iw
	ins.name = Text(iw, 22, "OUTLINE")
	ins.rank = Text(iw, 14, "OUTLINE")
	ins.rank:SetPoint("TOP", ins.name, "BOTTOM", 0, -6)
	ins.extra = Text(iw, 14, "OUTLINE")
	ins.extra:SetPoint("TOP", ins.rank, "BOTTOM", 0, -8)
	ins.from = Text(iw, 12)
	ins.from:SetPoint("TOP", ins.extra, "BOTTOM", 0, -8)
	ins.from:SetTextColor(0.7, 0.7, 0.74)
	ins.from:SetWidth(420)
	ins.hint = Text(iw, 11)
	ins.hint:SetPoint("TOP", ins.from, "BOTTOM", 0, -16)
	ins.hint:SetTextColor(0.55, 0.55, 0.6)
	ins.hint:SetText(L["Drag to turn the card · Mouse wheel to zoom"])
	-- (1 November, his word: « si on appuie sur un endroit où y'a pas de bouton, ça ferme le sous menu. J'aimerai un
	-- "Retour" »: a click beside the card does nothing any more; Back under its words, the one way back)
	ins.back = S.Button(ins, L["Back"], 150, 26)
	ins.back:SetPoint("TOP", ins.hint, "BOTTOM", 0, -12)
	ins.back:SetFrameLevel(ins:GetFrameLevel() + 45)
	CuratorOctoFull.SetScript(ins.back, "OnClick", function()
		ns.Play(ns.SND.close)
		CR:CloseInspect()
	end)
	ins:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(ins, "OnMouseWheel", function(_, delta)
		if ns.Inspect and ins.card.turn then
			ns.Inspect:Zoom(ins.card, delta)
		end
	end)
	CuratorOctoFull.SetScript(ins, "OnUpdate", function(_, elapsed)
		if ns.Inspect and ins.card.turn then
			ns.Inspect:Update(ins.card, elapsed)
			-- (31 October, his word: no words over one another; the card brought closer, its words step aside under it)
			local z = ins.card.turn.zoom or 1
			ins.words:SetAlpha(1 - math.max(0, math.min(1, (z - 1.02) / 0.12)))
		end
	end)

	-- (the light out of the case, breathing while it is open; its dust)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		CR:Breathe(elapsed)
	end)
	return f
end

-- The places on this screen. The band as wide as the screen allows, its cards on both sides of the mark (CR.FROM, the
-- one under the mark at first; CR.WIN, the one it stops on: as many after it as before the first); what the case holds
-- as wide, in its place; above them the case, as large as the height of the screen allows; the title at the top, the
-- buttons at the foot.
function CR:Layout()
	local f = self.frame
	-- (a screen lower than 768 points, its interface large: the scene made smaller, laid out as on 768)
	local uw, uh = UIParent:GetWidth() or 1024, UIParent:GetHeight() or 768
	local fs = math.min(1, uh / 768)
	f:SetScale(fs)
	local sw, sh = uw / fs, uh / fs
	local k = math.max(1, math.min(1.4, sh / 768))
	-- (the room the rest takes besides the case and what it holds: 214, the title at the top and its words, the buttons
	-- and the margin at the foot, the least of the gaps; for real, the line under the buttons too)
	local rest = 214 + (self.real and 24 or 0)
	local bw = math.floor(math.min(self.MAX_W, math.max(600, sw - 160)))
	local bh = self.H + 30
	self.bandW = bw
	-- (the cards needed on one side of the mark to fill half of the band)
	local half = math.ceil((bw / 2 + self.W / 2) / self.STEP)
	self.FROM = half + 1
	self.WIN = self.CARDS - half
	-- (the room: its picture as wide as the screen, its middle kept)
	local aspect = sw / sh
	local ra = self.roomAspect or 2
	if aspect <= ra then
		f.room:SetTexCoord(0.5 - aspect / (2 * ra), 0.5 + aspect / (2 * ra), 0, 1)
	else
		f.room:SetTexCoord(0, 1, 0.5 - ra / (2 * aspect), 0.5 + ra / (2 * aspect))
	end

	-- what the case holds: its cards, their size, the height it takes (as many rows shown as the screen has room for
	-- beside the smallest case, CR.MAX_ROWS at most; the others scrolled to)
	local function Width(n)
		return math.floor((bw - 48 - (n - 1) * self.ITEM_GAP) / n)
	end
	local per = self.PER_ROW
	while per > 6 and Width(per) < self.ITEM_FIT do
		per = per - 1
	end
	self.per = per
	local iw = math.max(self.ITEM_MIN, math.min(self.ITEM_MAX, Width(per)))
	local ih = math.floor(iw * 0.75)
	self.itemW, self.itemH = iw, ih
	local all = self:Slots()
	local rowH = ih + self.ITEM_TEXT
	local function Height(r)
		return 12 + 18 + 12 + r * rowH + (r - 1) * 8 + 8
	end
	local rows = math.max(1, math.min(all, self.MAX_ROWS))
	while rows > 1 and rest + self.CASE_MIN * (self.CASE_UP + self.CASE_DOWN) + Height(rows) > sh do
		rows = rows - 1
	end
	self.visRows = rows
	self.scroll = math.max(0, math.min(self.scroll or 0, all - rows))
	local ph = Height(rows)
	self.panelH = ph

	-- the case: its size (as the room left by the rest allows: 214, the title at the top and its words, the buttons and
	-- the margin at the foot, the least of the gaps), the room it takes (above and under its middle)
	local room = (sh - rest - ph) / (self.CASE_UP + self.CASE_DOWN)
	local cw = math.floor(math.max(self.CASE_MIN, math.min(self.CASE_MAX, sh * self.CASE_K, room)))
	local scale = cw / self.CASE_BASE
	self.caseScale, self.caseW = scale, cw
	self.sceneH = sh
	local up, down = cw * self.CASE_UP, cw * self.CASE_DOWN
	self.caseUp, self.caseDown = up, down

	-- from the top: the title, the case, what it holds (and the band in its place), the buttons; the room left given to
	-- the gaps between them
	local top = sh / 2
	local need = rest + up + down + ph
	local spare = math.max(0, sh - need - 60)
	local g1 = 14 * k + spare * 0.20
	local g2 = 16 * k + spare * 0.16
	local g3 = 20 * k + spare * 0.10
	f.title:ClearAllPoints()
	f.title:SetPoint("TOP", f, "TOP", 0, -32)
	local caseY = top - 34 - 60 - g1 - up
	local panelTop = caseY - down - g2
	local midY = panelTop - ph / 2
	-- (the band in the upper part of the place of what the case held: under the case, as in CS2)
	local bandY = panelTop - bh / 2 - 12
	self.caseY, self.midY, self.bandY = caseY, midY, bandY
	f.case:SetScale(scale)
	f.case:ClearAllPoints()
	f.case:SetPoint("CENTER", f, "CENTER", 0, caseY / scale)
	f.spot:ClearAllPoints()
	CuratorOctoFull.SetSize(f.spot, cw * 1.15, (up + down) * 2.9)
	f.spot:SetPoint("BOTTOM", f, "CENTER", 0, caseY - down * 0.9)
	f.halo:ClearAllPoints()
	CuratorOctoFull.SetSize(f.halo, cw * 1.5, cw * 0.95)
	f.halo:SetPoint("CENTER", f, "CENTER", 0, caseY + cw * 0.04)
	CuratorOctoFull.SetSize(f.flare, cw * 1.25, cw * 0.16)
	for _, sp in ipairs(f.sparks) do
		CuratorOctoFull.SetSize(sp, cw * 0.16, cw * 0.16)
	end
	f.hint:ClearAllPoints()
	f.hint:SetPoint("BOTTOM", f, "CENTER", 0, panelTop + 5)
	f.panel:ClearAllPoints()
	CuratorOctoFull.SetSize(f.panel, bw, ph)
	f.panel:SetPoint("CENTER", f, "CENTER", 0, midY)
	f.band:ClearAllPoints()
	CuratorOctoFull.SetSize(f.band, bw, bh)
	f.band:SetPoint("CENTER", f, "CENTER", 0, bandY)
	f.buttons:ClearAllPoints()
	f.buttons:SetPoint("TOP", f, "CENTER", 0, midY - ph / 2 - g3)
	self:PlaceItems()

	-- the card that comes out, and the one inspected: a little over the middle, their words under them
	local cy = 64
	self.cardX, self.cardY = 0, cy
	local ch = self.CARD_W * 717 / 512
	for _, o in ipairs({ f.reveal, f.inspect }) do
		if o.spot then
			o.spot:ClearAllPoints()
			o.spot:SetPoint("CENTER", o, "CENTER", 0, cy)
			o.card:ClearAllPoints()
			o.card:SetPoint("CENTER", o.holder, "CENTER", 0, 0)
		else
			o.card:ClearAllPoints()
			o.card:SetPoint("CENTER", o, "CENTER", 0, cy)
		end
		o.glow:ClearAllPoints()
		o.glow:SetPoint("CENTER", o, "CENTER", 0, cy)
		o.name:ClearAllPoints()
		o.name:SetPoint("TOP", o, "CENTER", 0, cy - ch / 2 - 16)
	end
	local rv = f.reveal
	for _, t in ipairs({ rv.rays, rv.flash, rv.ring }) do
		t:ClearAllPoints()
		t:SetPoint("CENTER", rv, "CENTER", 0, cy)
	end
end

-------------------------------------------------------------------------------
-- What the case holds
-------------------------------------------------------------------------------
-- The i-th card shown in the case (made the first time): its tile, its highlight, under it its name and its album; a
-- click inspects it.
function CR:Item(i)
	local f = self.frame
	local it = f.items[i]
	if it then
		return it
	end
	it = NewTile(f.panel)
	it:EnableMouse(true)
	it.hl = it:CreateTexture(nil, "OVERLAY", nil, 2)
	it.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(it.hl, 1, 1, 1, 0.1)
	it.hl:SetBlendMode("ADD")
	it.hl:Hide()
	it.name = Text(it, 11)
	it.name:SetPoint("TOPLEFT", it, "BOTTOMLEFT", 0, -5)
	it.name:SetJustifyH("LEFT")
	CuratorOctoFull.SetWordWrap(it.name, false)
	it.sub = Text(it, 10)
	it.sub:SetPoint("TOPLEFT", it.name, "BOTTOMLEFT", 0, -2)
	it.sub:SetJustifyH("LEFT")
	CuratorOctoFull.SetWordWrap(it.sub, false)
	it.sub:SetTextColor(0.6, 0.6, 0.64)
	-- (1.14.0, for real: how many of it the player has, on its corner)
	it.badge = Text(it, 12, "OUTLINE")
	it.badge:SetDrawLayer("OVERLAY", 7)
	it.badge:SetPoint("TOPRIGHT", it, "TOPRIGHT", -5, -4)
	it.badge:SetTextColor(1, 0.86, 0.4)
	it.badge:Hide()
	CuratorOctoFull.SetScript(it, "OnEnter", function(self)
		CR:ItemTip(self)
	end)
	CuratorOctoFull.SetScript(it, "OnLeave", function(self)
		self.hl:Hide()
		GameTooltip:Hide()
	end)
	CuratorOctoFull.SetScript(it, "OnMouseUp", function(self)
		CR:Inspect(self.pick)
	end)
	f.items[i] = it
	return it
end

-- The width of a text on one line, whatever the width of its font string.
local function Unbounded(fs)
	local ok, w = pcall(fs.GetUnboundedStringWidth, fs)
	if ok and type(w) == "number" then
		return w
	end
	return S.Width(fs)
end

-- The lines a text takes in that width, its words wrapped as the client wraps them (a language without spaces: by its
-- length).
local function LinesOf(fs, text, w)
	local lines, line = 1, ""
	for word in CuratorOctoFull.Gmatch(text, "%S+") do
		local try = line == "" and word or (line .. " " .. word)
		fs:SetText(try)
		if line ~= "" and Unbounded(fs) > w then
			lines, line = lines + 1, word
		else
			line = try
		end
	end
	fs:SetText(text)
	return math.max(lines, math.ceil(Unbounded(fs) / math.max(1, w)))
end

-- A name under a card of the case, as wide as it: on one line (smaller when it needs), else on two (smaller until it
-- takes no more).
local function Fit2(fs, text, w)
	CuratorOctoFull.SetWordWrap(fs, false)
	if fs.SetMaxLines then
		CuratorOctoFull.SetMaxLines(fs, 1)
	end
	S.Fit(fs, text, w, 11, 9)
	if S.Width(fs) > w then
		local size = 10
		ns.SetFont(fs, size)
		CuratorOctoFull.SetWordWrap(fs, true)
		if fs.SetMaxLines then
			CuratorOctoFull.SetMaxLines(fs, 2)
		end
		fs:SetText(text)
		while size > 8 and LinesOf(fs, text, w) > 2 do
			size = size - 0.5
			ns.SetFont(fs, size)
		end
	end
end

-- A card shown in the case dressed as what it is: { tier, card } (the priceless one: its golden card).
function CR:DressItem(it, pick)
	it.pick = pick
	local iw, ih = self.itemW, self.itemH
	DressTile(it, pick, iw, ih)
	it.name:SetWidth(iw)
	it.sub:SetWidth(iw)
	CuratorOctoFull.SetWordWrap(it.name, false)
	if it.name.SetMaxLines then
		CuratorOctoFull.SetMaxLines(it.name, 1)
	end
	if pick.secret then
		local ink = Ink(pick.tier)
		it.name:SetTextColor(ink[1], ink[2], ink[3])
		S.Fit(it.name, L["Priceless card"], iw, 11, 8.5)
		it.sub:SetText("")
	elseif pick.entry then
		it.name:SetTextColor(0.95, 0.95, 0.96)
		Fit2(it.name, ns.CrateItems:Name(pick.entry), iw)
		S.Fit(it.sub, ns.CrateItems:Sub(pick.entry), iw, 10, 8)
	else
		it.name:SetTextColor(0.95, 0.95, 0.96)
		S.Fit(it.name, C:Name(pick.card), iw, 11, 8.5)
		S.Fit(it.sub, pick.card.series and C:SeriesName(pick.card.series) or "", iw, 10, 8)
	end
	-- (1.14.0, for real: how many of it the player has (the golden card: his weapons of legend); one he has not yet,
	-- dimmed)
	local o = self:Has(pick)
	local missing = self.real ~= nil and o == nil
	CuratorOctoFull.SetShown(it.badge, o ~= nil)
	if o then
		it.badge:SetText("x" .. ns.Num(o.n))
	end
	CuratorOctoFull.SetDesaturated(it.pic, missing)
	it.pic:SetAlpha(missing and 0.5 or 1)
	CuratorOctoFull.SetDesaturated(it.art, missing)
	it.art:SetAlpha(missing and 0.45 or 1)
	it.light:SetAlpha(missing and 0.4 or 1)
	it.halo:SetAlpha(missing and 0.4 or 1)
	if not pick.secret then
		local c = missing and 0.6 or 0.95
		it.name:SetTextColor(c, c, c + 0.01)
	end
	it:Show()
end

-- The places of what the case holds: from the left, in its order, so many in a row, one after another (the ranks
-- following each other, the golden card last). self.slots[i] = { row, column }; self.itemRows: its rows.
function CR:Slots()
	local list = self.caseList or {}
	local per = self.per or self.PER_ROW
	local slots = {}
	local row, col = 0, 0
	for i = 1, CuratorOctoFull.Length(list) do
		if i > 1 then
			if col + 1 >= per then
				row, col = row + 1, 0
			else
				col = col + 1
			end
		end
		slots[i] = { row, col }
	end
	self.slots, self.itemRows = slots, CuratorOctoFull.Length(list) > 0 and (row + 1) or 1
	return self.itemRows
end

-- What the case holds, in its rows from the left, in its order: the rows shown (from self.scroll, self.visRows of
-- them), the others hidden; the bar of the scroll on its right when they are not all shown.
function CR:PlaceItems()
	local f = self.frame
	local list = self.caseList or {}
	local iw, ih = self.itemW, self.itemH
	if not self.slots or CuratorOctoFull.Length(self.slots) ~= CuratorOctoFull.Length(list) then
		self:Slots()
	end
	local vis = self.visRows or self.itemRows
	local top = self.scroll or 0
	for i, pick in ipairs(list) do
		local it = self:Item(i)
		local row, col = self.slots[i][1], self.slots[i][2]
		if row >= top and row < top + vis then
			self:DressItem(it, pick)
			it:ClearAllPoints()
			it:SetPoint("TOPLEFT", f.panel, "TOPLEFT", 24 + col * (iw + self.ITEM_GAP), -(12 + 18 + 12) - (row - top) * (ih + self.ITEM_TEXT + 8))
		else
			it:Hide()
		end
	end
	for i = CuratorOctoFull.Length(list) + 1, CuratorOctoFull.Length(f.items) do
		f.items[i]:Hide()
	end
	-- (the bar of the scroll: its thumb as long as the rows shown are of them all, where they are)
	local p = f.panel
	local more = self.itemRows > vis
	CuratorOctoFull.SetShown(p.track, more)
	CuratorOctoFull.SetShown(p.thumb, more)
	if more then
		local h = p:GetHeight() - (12 + 18 + 12) - 8
		p.track:ClearAllPoints()
		p.track:SetPoint("TOPRIGHT", p, "TOPRIGHT", -8, -(12 + 18 + 12))
		CuratorOctoFull.SetSize(p.track, 3, h)
		local th = math.max(16, h * vis / self.itemRows)
		p.thumb:ClearAllPoints()
		p.thumb:SetPoint("TOP", p.track, "TOP", 0, -(h - th) * top / math.max(1, self.itemRows - vis))
		CuratorOctoFull.SetSize(p.thumb, 3, th)
	end
end

-- What the case holds scrolled by so many rows (the wheel: up, -1).
function CR:ScrollItems(rows)
	local vis = self.visRows or self.itemRows or 1
	local max = math.max(0, (self.itemRows or 1) - vis)
	local s = math.max(0, math.min(max, (self.scroll or 0) + rows))
	if s ~= (self.scroll or 0) then
		self.scroll = s
		GameTooltip:Hide()
		self:PlaceItems()
		ns.Play(SND_TICK)
	end
end

-- Its words over a card shown in the case: its name, its rank, its album; the golden one, its secret kept.
function CR:ItemTip(it)
	local pick = it.pick
	if not pick then
		return
	end
	it.hl:Show()
	GameTooltip:SetOwner(it, "ANCHOR_TOP")
	local ink, col = Ink(pick.tier), Colour(pick.tier)
	if pick.secret then
		GameTooltip:AddLine(L["Priceless card"], ink[1], ink[2], ink[3])
		GameTooltip:AddLine(L["A weapon of legend. Which one stays a mystery."], 1, 1, 1, true)
	elseif pick.entry then
		-- (a spell: its tooltip of the game; a figure, an armour: its name, its rank, what it is)
		local e = pick.entry
		local CI = ns.CrateItems
		local shown = e.kind == "spell" and GameTooltip.SetSpellByID and pcall(GameTooltip.SetSpellByID, GameTooltip, e.id)
		if shown and GameTooltip:NumLines() > 0 then
			GameTooltip:AddLine(" ")
		else
			GameTooltip:ClearLines()
			GameTooltip:AddLine(CI:Name(e), ink[1], ink[2], ink[3])
		end
		GameTooltip:AddLine(L[self.RANKS[pick.tier].label], col[1], col[2], col[3])
		GameTooltip:AddLine(CI:From(e), 0.7, 0.7, 0.74, true)
	else
		GameTooltip:AddLine(C:Name(pick.card), ink[1], ink[2], ink[3])
		GameTooltip:AddLine(L[self.RANKS[pick.tier].label], col[1], col[2], col[3])
		if pick.card.series then
			GameTooltip:AddLine(C:SeriesName(pick.card.series), 0.7, 0.7, 0.74)
		end
	end
	-- (1.14.0, for real: the copies he has of it)
	if self.real then
		local o = self:Has(pick)
		if o then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(string.format(L["Yours: %d"], o.n), 1, 0.86, 0.4)
			if o.thunder > 0 then
				GameTooltip:AddLine(string.format(L["Thunderforged: %d"], o.thunder), FINISH_INK.thunder[1], FINISH_INK.thunder[2], FINISH_INK.thunder[3])
			end
			if o.titan > 0 then
				GameTooltip:AddLine(string.format(L["Titanforged: %d"], o.titan), FINISH_INK.titan[1], FINISH_INK.titan[2], FINISH_INK.titan[3])
			end
		else
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Not in your collection yet."], 0.6, 0.6, 0.64)
		end
	end
	GameTooltip:AddLine(L["Click a card to inspect it."], 0.55, 0.55, 0.6)
	GameTooltip:Show()
end

-- A card inspected, large, held in the hand: a card of the case (its creature alive; the golden one: its secret kept), or
-- (1.14.0) the card that came out, as it came (its condition, its forged finish, the weapon of a priceless card). Dragged,
-- it turns all the way round to its back (the back of the case); a click on it turns it over; Back closes it (1 November:
-- a click beside it no more).
-- (The card that came out steps aside meanwhile: the client would draw its creature over the one held.)
function CR:Inspect(pick)
	local f = self.frame
	if not (f and f:IsShown() and pick) then
		return
	end
	local won = pick == self.win
	if not ((self.state == "case" and not won) or (self.state == "out" and won)) then
		return
	end
	GameTooltip:Hide()
	local ins = f.inspect
	ins.pick, ins.won = pick, won
	local col, ink = Colour(pick.tier), Ink(pick.tier)
	local weapon = won and pick.weapon or nil
	ins.card:Set({ tier = pick.tier, card = pick.card, entry = pick.entry, weapon = weapon, secret = pick.secret and not weapon,
		wear = won and pick.wear or nil, finish = won and pick.finish or nil, pt = won and pick.pt or nil, def = pick.def or (self.own and self.own.def) }, self.RANKS)
	ins.card:SetLive(true)
	ins.card:SetBack(self.own and self.own.def.art and self.own.def.art.back or nil)
	if ns.Inspect and ins.card.turn then
		ns.Inspect:Reset(ins.card, 0, 1)
	end
	ins.glow:SetVertexColor(col[1], col[2], col[3], 0.5)
	ns.CancelOwner(ins.card)
	local CI = ns.CrateItems
	if weapon then
		ins.name:SetText(ns.CrateCard.WeaponName(weapon) or L["Priceless card"])
		ins.from:SetText(ns.CrateCard.WeaponNote(weapon) or "")
	elseif pick.secret then
		ins.name:SetText(L["Priceless card"])
		ins.from:SetText(L["A weapon of legend. Which one stays a mystery."])
	elseif pick.entry then
		-- (a card of the case of the month: its name, its rank, what it is; its sound)
		ins.name:SetText(CI:Name(pick.entry))
		ins.from:SetText(CI:From(pick.entry))
		ns.Delay(0.2, function()
			CI:Play(pick.entry, ins.card)
		end, ins.card)
	else
		ins.name:SetText(C:Name(pick.card))
		ins.from:SetText(pick.card.series and string.format(L["A creature of %s, for the test."], C:SeriesName(pick.card.series)) or "")
	end
	ins.rank:SetText(L[self.RANKS[pick.tier].label])
	-- (the card that came out: its forged finish; its condition shows on it, never in words: 31 October, his word)
	local extra = won and pick.finish and L[self.FINISH_NAME[pick.finish]] or nil
	if extra then
		local fi = FINISH_INK[pick.finish]
		ins.extra:SetText(extra)
		ins.extra:SetTextColor(fi[1], fi[2], fi[3])
	else
		ins.extra:SetText("")
	end
	CuratorOctoFull.SetShown(ins.extra, extra ~= nil)
	ins.from:ClearAllPoints()
	ins.from:SetPoint("TOP", extra and ins.extra or ins.rank, "BOTTOM", 0, extra and -8 or -10)
	ins.name:SetTextColor(ink[1], ink[2], ink[3])
	ins.rank:SetTextColor(col[1], col[2], col[3])
	if won then
		f.reveal.card:Hide()
	end
	ins:SetAlpha(0)
	ins:Show()
	ns.Play(ns.SND.cardFlip)
	ns.Tween(0.25, function(e, raw)
		ins:SetAlpha(raw)
		ins.card:SetScale(0.85 + 0.15 * e)
	end, nil, Ease.outBack, ins)
end

function CR:CloseInspect(now)
	local f = self.frame
	local ins = f and f.inspect
	if not (ins and ins:IsShown()) then
		return
	end
	ns.CancelOwner(ins)
	ns.CancelOwner(ins.card)
	-- (the card that came out back in its place, its creature, its armour or its weapon loaded again)
	local won = ins.won
	ins.won = nil
	if won then
		local rv, win = f.reveal, self.win
		rv.card:Show()
		if win and not now then
			rv.card:Set({ tier = win.tier, card = win.card, entry = win.entry, weapon = win.weapon, wear = win.wear, finish = win.finish, pt = win.pt }, self.RANKS)
			rv.card:SetLive(true)
		end
	end
	local function gone()
		ins:Hide()
		ins.card:SetScale(1)
		if CR.PaintCertButton then
			CR:PaintCertButton(ins, nil)
		end
		if ns.Inspect and ins.card.turn then
			ns.Inspect:Reset(ins.card, 0, 1)
		end
		-- (1.14.0, after its first test: a card viewed alone, from the inventory or an album: the window goes with it)
		if CR.viewing and not now then
			CR.viewing = nil
			f:Hide()
		end
	end
	if CR.OnInspectClosed then
		CR:OnInspectClosed()
	end
	if now then
		gone()
		return
	end
	ns.Tween(0.15, function(_, raw)
		ins:SetAlpha(1 - raw)
	end, gone, Ease.linear, ins)
end

-------------------------------------------------------------------------------
-- (1.14.0) The cases for real (Cases.lua): their edition, its cases and its keys, the cards of its collection the player
-- has
-------------------------------------------------------------------------------
-- Why a case cannot be opened now, said under the buttons ("key": with the price of a key).
local WHY = {
	none = "No case of this edition to open: they come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100).",
	key = "To open it, a key of its edition: %s.",
	rubies = "Not enough rubies.",
	closed = "Curator is closed: no case can be opened.",
	case = "Curator is closed: no case can be opened.",
}
-- (1.14.0, after its test: a reroll opens nothing; its words name the main, Reroll.lua: already in the language of
-- the player, they come back as they are from the table of the words)
setmetatable(WHY, { __index = function(_, k)
	if k == "reroll" and ns.Reroll then
		return ns.Reroll:Why()
	end
end })

-- The case of an edition (nil: the case of the month), for real: its cases, its keys, the cards of its collection the
-- player has. An opening that runs is left as it is.
function CR:Show(case)
	local CS = ns.Cases
	if not CS then
		return
	end
	case = case or CS.EDITION
	if not CS:Known(case) then
		return
	end
	local f = self:Build()
	if f:IsShown() and self.real == case and self.state and self.state ~= "case" then
		return
	end
	self:Stop()
	self:CloseInspect(true)
	self.real, self.edition, self.forced = case, case, nil
	f.key.armed = nil
	self:MakeCase()
	self:AskWeapons()
	self:AskEntries()
	self.scroll = 0
	f:Show()
	self:Layout()
	f.title:SetText(L[(self.own and self.own.def.title) or "Test case"])
	self:ShowCase("fall")
end

-- The copies the player has of a card shown in the case: { n, thunder, titan, step, word: the finest condition among
-- them } (the golden card: his weapons of legend, all of them), else nil (or not for real).
function CR:Has(pick)
	if not (self.real and pick) then
		return nil
	end
	if pick.secret then
		local all
		for _, o in pairs(self.weapons or {}) do
			all = all or { n = 0, thunder = 0, titan = 0, step = 99 }
			all.n, all.thunder, all.titan = all.n + o.n, all.thunder + o.thunder, all.titan + o.titan
			if (o.step or 99) < all.step then
				all.step, all.word = o.step, o.word
			end
		end
		return all
	end
	return pick.entry and self.cards and self.cards[pick.entry.key] or nil
end

-- What a case of the edition shown for real can do now: its words at the top (its cases, its keys), the cards of its
-- collection the player has (the count over what it holds, each card), the buttons (open it, a key); under them why it
-- cannot be opened (why: what was just refused, else what it lacks). Not for real: the buttons of the test.
function CR:PaintReal(why)
	local f = self.frame
	if not f then
		return
	end
	local CS = ns.Cases
	local bar, key = f.buttons, f.key
	if not (self.real and CS) then
		key:Hide()
		f.why:Hide()
		bar:SetWidth(380)
		f.open:SetWidth(220)
		f.quit:SetWidth(140)
		for _, b in pairs(f.batchButtons) do b:Hide() end
		f.panel.inspect:SetText(L["Click a card to inspect it."])
		self.cards, self.weapons = nil, nil
		return
	end
	local case = self.real
	local n, keys = CS:Count(case), CS:Keys(case)
	local RB = ns.Rubies
	local words0 = string.format(L["Cases to open: %d  ·  Keys: %d"], n, keys)
	if RB then
		words0 = words0 .. "  ·  " .. string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13))
	end
	f.sub:SetText(words0)
	-- (the cards of its collection he has: how many of its cards, his weapons of legend)
	self.cards, self.weapons = CS:Owned(case)
	local have, total = 0, 0
	for r = 1, self.TOP - 1 do
		for _, e in ipairs((self.own and self.own[r]) or {}) do
			total = total + 1
			if self.cards[e.key] then
				have = have + 1
			end
		end
	end
	local arms = 0
	for _, o in pairs(self.weapons) do
		arms = arms + o.n
	end
	local name = L[(CS.COLLECTION and CS.COLLECTION[case]) or "Paladin Collection 2026"]
	local words = string.format(L["%s: %d / %d cards"], name, have, total)
	if arms > 0 then
		words = words .. "  ·  " .. string.format(L["Weapons of legend: %d"], arms)
	end
	f.panel.inspect:SetText(words)
	self:PlaceItems()
	-- (the buttons: open it, a key between it and the one that closes)
	bar:SetWidth(650)
	f.open:SetText(L["Open the case"])
	f.open:SetWidth(132)
	f.quit:SetWidth(120)
	key:Show()
	if Armed(key) then
		key:SetText(L["Confirm"])
	else
		key:SetText(L["Buy a key"] .. "  " .. (RB and RB.Text(CS:KeyPrice(), 14) or tostring(CS:KeyPrice())))
	end
	local ok, lack = CS:CanOpen(case)
	local busy = self.batch ~= nil or (self.state ~= nil and self.state ~= "case" and self.state ~= "shutting")
	local available = not busy and CS:Openable(case) or 0
	for count, b in pairs(f.batchButtons) do
		b:Show()
		CuratorOctoFull.SetEnabled(b, available >= count)
	end
	CuratorOctoFull.SetEnabled(f.open, (ok and not busy) and true or false)
	CuratorOctoFull.SetEnabled(key, (not busy and lack ~= "closed" and lack ~= "case") and true or false)
	-- (under them: what was refused, else what it lacks)
	local say = why or (not ok and lack) or nil
	local text = say and WHY[say]
	if say == "guard" and ns.Guard then
		text = ns.Guard.SHORT
	end
	if text then
		text = L[text]
		if say == "key" then
			text = string.format(text, RB and RB.Text(CS:KeyPrice(), 12) or tostring(CS:KeyPrice()))
		end
		f.why:SetText(text)
		if why then
			f.why:SetTextColor(1, 0.45, 0.4)
		else
			f.why:SetTextColor(0.78, 0.74, 0.62)
		end
		f.why:Show()
	else
		f.why:Hide()
	end
end

-- A key of the edition shown, bought: a first click arms the button, a second one within its seconds buys it.
function CR:KeyClick()
	local f = self.frame
	local CS = ns.Cases
	local b = f and f.key
	if not (b and self.real and CS) or (self.state ~= "case" and self.state ~= "shutting") then
		return
	end
	if not Armed(b) then
		b.armed = GetTime()
		ns.Play(ns.SND.click)
		self:PaintReal()
		self:KeyTip(b)
		return
	end
	b.armed = nil
	GameTooltip:Hide()
	local ok, why = CS:BuyKey(self.real, 1)
	if not ok then
		ns.Play(ns.SND.close)
		self:PaintReal(why)
		return
	end
	ns.Play(ns.SND.coins)
	ns.Play(ns.SND.claim)
	f.case:Kick(0.3)
	ns.Print(L["A key of the %s, for %s."], L[(self.own and self.own.def.title) or "Test case"], ns.Rubies.Text(CS:KeyPrice()))
	self:PaintReal()
end

-- The words of the button of a key: what it is, its price, the rubies of the player, how to buy it.
function CR:KeyTip(b)
	local CS = ns.Cases
	if not (self.real and CS) then
		return
	end
	local RB = ns.Rubies
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(string.format(L["A key of the %s"], L[(self.own and self.own.def.title) or "Test case"]), 1, 0.84, 0.26)
	GameTooltip:AddLine(L["One key opens one case of its edition."], 0.9, 0.9, 0.92, true)
	if RB then
		GameTooltip:AddLine(string.format(L["Price: %s"], RB.Text(CS:KeyPrice(), 13)), 1, 0.82, 0.25)
		GameTooltip:AddLine(string.format(L["Your rubies: %s"], RB.Text(RB:Balance(), 13)), 0.85, 0.85, 0.88)
	end
	if Armed(b) then
		GameTooltip:AddLine(L["Click again to confirm."], 0.3, 1, 0.3)
	else
		GameTooltip:AddLine(L["Click, then click again to confirm."], 0.3, 1, 0.3)
	end
	GameTooltip:Show()
end

-- The words of the button that opens the case, for real: its cases, its keys, where the cases come from.
function CR:OpenTip(b, count)
	local CS = ns.Cases
	if not (self.real and CS) then
		return
	end
	GameTooltip:SetOwner(b, "ANCHOR_TOP")
	GameTooltip:AddLine(L[(self.own and self.own.def.title) or "Test case"], 1, 0.84, 0.26)
	GameTooltip:AddLine(string.format(L["Cases to open: %d  ·  Keys: %d"], CS:Count(self.real), CS:Keys(self.real)), 0.9, 0.9, 0.92)
	if count then
		GameTooltip:AddLine(string.format(L["Open %d cases"], count), 1, 1, 1)
	end
	GameTooltip:AddLine(L["A case and a key of its edition: one card, yours."], 0.85, 0.85, 0.88, true)
	GameTooltip:AddLine(L["The cases come from the creatures that give experience (1 in 100) and the quests turned in (4 in 100)."], 0.6, 0.6, 0.64, true)
	GameTooltip:Show()
end

-- What the band stops on, as Cases.lua drew it (rec: its record): its rank, its card (the entry of the case) or its
-- weapon, its condition, its finish.
function CR:Forced(rec)
	-- (31 October, his word: its wear, as Cases.lua lets it out, never its condition in words)
	local fo = { real = true, tier = rec.r, finish = rec.f, wear = ns.Cases.WearOf(rec), pt = ns.Cases.Pattern(rec) }
	if rec.w then
		fo.tier = self.TOP
		fo.weapon = { id = rec.w, line = rec.l, class = rec.cl, faction = rec.fa }
	elseif rec.e and self.own then
		for r = 1, self.TOP - 1 do
			for _, e in ipairs(self.own[r] or {}) do
				if e.key == rec.e then
					fo.entry, fo.tier = e, r
				end
			end
		end
	end
	return fo
end

-- The card that came out of a case for real, said in the chat once (as it comes out, or as the window closes before).
function CR:Told()
	local rec = self.pending
	if not rec then
		return
	end
	-- (1.14.0, after its first test: a card come out of an exchange contract, UI/CaseView.lua, said as such)
	local how = self.pendingHow
	self.pending, self.pendingHow = nil, nil
	local tier = tonumber(rec.r) or 1
	local rank = self.RANKS[tier] or self.RANKS[1]
	local name
	if rec.w then
		name = ns.CrateCard.WeaponName({ id = rec.w }) or L["Priceless card"]
	else
		local fo = self:Forced(rec)
		name = (fo.entry and ns.CrateItems:Name(fo.entry)) or "?"
	end
	local ink = Ink(tier)
	local what = string.format(("|cff%02x%02x%02x%s|r"), math.floor(ink[1] * 255 + 0.5), math.floor(ink[2] * 255 + 0.5), math.floor(ink[3] * 255 + 0.5), name)
	-- (31 October: its forged finish, never its condition in words)
	if rec.f and self.FINISH_NAME[rec.f] then
		ns.Print(how == "contract" and L["Out of an exchange contract: %s (%s, %s)."] or L["Out of the case: %s (%s, %s)."], what, L[rank.label],
			L[self.FINISH_NAME[rec.f]])
	else
		ns.Print(how == "contract" and L["Out of an exchange contract: %s (%s)."] or L["Out of the case: %s (%s)."], what, L[rank.label])
	end
end

-------------------------------------------------------------------------------
-- The band
-------------------------------------------------------------------------------
-- The i-th card of the band (made the first time): its tile (as CS2 shows them), the light under it when the band stops
-- on it; its tile grows from its middle.
function CR:Tile(i)
	local f = self.frame
	local t = f.tiles[i]
	if t then
		return t
	end
	t = CreateFrame("Frame", nil, f.strip)
	CuratorOctoFull.SetSize(t, self.W, self.H)
	t:SetPoint("LEFT", f.strip, "LEFT", (i - 1) * self.STEP, 0)
	t.glow = Tex(t, "BACKGROUND", -1, "CardGlow", "ADD")
	t.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(t.glow, self.W * 1.55, self.H * 1.7)
	t.glow:SetAlpha(0)
	local face = NewTile(t)
	face:SetPoint("CENTER")
	t.face = face
	f.tiles[i] = t
	return t
end

-- A card of the band dressed as a pick: { tier, card }.
function CR:Dress(t, pick)
	t.pick = pick
	t:SetAlpha(1)
	t.face:SetScale(1)
	t.face:SetAlpha(1)
	t.glow:SetAlpha(0)
	DressTile(t.face, pick, self.W, self.H, true)
end

-- The band filled anew: each card drawn from the case with its chances; the one it stops on, its rank forced or drawn
-- as the others (its weapon too, when one was asked for); the band at its start, the first card under the mark. (The
-- priceless one shows its golden card in the band, its weapon for later.)
function CR:Fill(tier, finish)
	local f = self.frame
	for i = 1, self.CARDS do
		local stop = i == self.WIN
		local r = (stop and tier) or self:Roll()
		self:Dress(self:Tile(i), self:Pick(r, stop and self.forced or nil))
	end
	local win = f.tiles[self.WIN].pick
	local fo = self.forced
	if fo and fo.real then
		-- (for real: as Cases.lua drew them)
		win.wear, win.finish, win.pt = fo.wear, fo.finish, fo.pt
	else
		win.wear, win.finish = self:Extras(finish)
		-- (1.14.0: a test, titanforged: a pattern to see)
		win.pt = win.finish == "titan" and ns.Cases.DrawPattern() or nil
	end
	self.win = win
	-- (1.14.0, after the test of the Paladin collection by its author: a card with a film of its own that will come,
	-- Arthas, Sulfuras: its film read while the band runs, UI/CaseFilm.lua)
	local film = self:FilmOf(win)
	if film and ns.CaseFilm then
		ns.CaseFilm:Preload(film, f)
	end
	-- (the weapon of a priceless card that will come: its model loaded for its entrance while the band runs, out of
	-- sight)
	if f.arm then
		f.arm:ClearAllPoints()
		f.arm:SetPoint("CENTER", f, "CENTER", self.cardX or 0, self.cardY or 0)
		CuratorOctoFull.SetSize(f.arm, self.ARM_SIZE, self.ARM_SIZE)
		-- (1.14.0, the Paladin collection redone: a weapon of a case of its own is drawn in its card, no model comes)
		local flat = win.weapon and ns.CrateCard.StyleOf(win) ~= nil
		ns.CrateCard.Arm(f.arm, (not flat) and win.weapon or nil)
		ns.CrateCard.ArmShow(f.arm, false)
	end
	self:MoveTo(self:Center(self.FROM))
	self.under = nil
end

-- The middle of the i-th card on the band, and the band moved so that this point of it is under the mark.
function CR:Center(i)
	return (i - 1) * self.STEP + self.W / 2
end

function CR:MoveTo(p)
	local f = self.frame
	self.at = p
	f.strip:ClearAllPoints()
	f.strip:SetPoint("LEFT", f.clip, "LEFT", self.bandW / 2 - p, 0)
end

-- The card under the mark at this point of the band (a new one each time the mark crosses the middle of a gap).
function CR:Under(p)
	return math.floor((p + self.GAP / 2) / self.STEP) + 1
end

-------------------------------------------------------------------------------
-- The case shown, opened, shown again
-------------------------------------------------------------------------------
-- /curator test caisse: the case of the month (else a case of the first test), shown; tier: the rank of the card it
-- will stop on (nil: drawn), finish: that card forged so ("thunder", "titan"); query: that card (by a word of its name, in that rank
-- when one is given); line, class: its weapon (a priceless card: that line of the weapons, that version of Atiesh),
-- unless the words name a card of the case.
function CR:Test(tier, finish, line, class, query)
	local f = self:Build()
	self:Stop()
	self:CloseInspect(true)
	self:Told()
	self.real, self.edition = nil, nil
	self:MakeCase()
	local entry
	if query and self.own then
		local e, r, exact = ns.CrateItems:Find(self.CASE, query, tier ~= self.TOP and tier or nil)
		if e and (exact or not (line or class)) then
			entry, tier, line, class = e, r, nil, nil
		end
	end
	if (line or class) and not tier then
		tier = self.TOP
	end
	self.forced = { tier = tier, finish = finish, line = line, class = class, entry = entry }
	self:AskWeapons()
	self:AskEntries()
	self.scroll = 0
	f:Show()
	self:Layout()
	if self.own then
		f.title:SetText(L[self.own.def.title or "Test case"])
		f.sub:SetText(L["A preview of the opening: nothing is kept."])
	else
		f.title:SetText(L["Test case"])
		f.sub:SetText(L["A preview of the opening: random cards, nothing is kept."])
	end
	self:ShowCase("fall")
end

-- Whether the case shown is a ghost of itself: for real, the player has none of its edition left.
function CR:IsGhost()
	return self.real ~= nil and ns.Cases ~= nil and ns.Cases:Count(self.real) <= 0
end

-- The case where it rests, as it is (its scale, its place, its colours or its ghost, no fall, no turn).
function CR:Settle(ghost)
	local f = self.frame
	local case = f.case
	local s = self.caseScale or 1
	case:SetScale(s)
	case:ClearAllPoints()
	case:SetPoint("CENTER", f, "CENTER", 0, (self.caseY or 0) / s)
	case.dropLift, case.dropYaw, case.dropPitch, case.moving = nil, nil, nil, nil
	case:SetGhost(ghost)
	case:SetAlpha(ghost and self.GHOST or 1)
	case:Paint()
end

-- The case shown, shut, what it holds under it. how: nil, at once; "fall", it falls before the eye first; "vanish", the
-- case that gave its card goes first, then another falls. (For real, none of its edition left: its ghost, grey, still.)
function CR:ShowCase(how)
	local f = self.frame
	local case = f.case
	if how ~= "vanish" then
		f.reveal:Hide()
		f.band:Hide()
	end
	f.case:Show()
	f.title:Show()
	f.sub:Show()
	self.viewing, self.contract = nil, nil
	-- (falling, or going: its buttons off until it rests)
	if how == "vanish" then
		self.state = "vanishing"
	elseif how == "fall" then
		self.state = "falling"
	end
	f.panel:Show()
	f.buttons:Show()
	f.open:Enable()
	-- (for real: its cases, its keys, the cards of its collection the player has; the buttons as they can be used)
	self:PaintReal()
	for _, sp in ipairs(f.sparks) do
		sp:SetAlpha(0)
	end
	CuratorOctoFull.SetShown(f.hint, not case.flat)
	local function Ready()
		self.state = "case"
		self.lidOpen = nil
		case:SetLid(0)
		case:SetPulse(1)
		case:SetDraggable(true)
		f.flare:SetAlpha(0)
		f.halo:SetAlpha(0)
		for _, d in ipairs(f.dust) do
			d.tex:SetAlpha(0)
		end
		f.panel:ClearAllPoints()
		f.panel:SetPoint("CENTER", f, "CENTER", 0, self.midY)
		-- (for real: its buttons usable again)
		self:PaintReal()
		self:ContinueBatch()
	end
	-- (what it holds, the buttons, the words over it: coming in)
	local function Appear()
		ns.Tween(0.35, function(e)
			f.panel:SetAlpha(e)
			f.panel:ClearAllPoints()
			f.panel:SetPoint("CENTER", f, "CENTER", 0, self.midY - 14 * (1 - e))
			f.buttons:SetAlpha(e)
			f.hint:SetAlpha(e)
		end, nil, Ease.outQuad, self)
	end
	-- (the next case: falling; none left, its ghost coming in)
	local function Arrive()
		if self:IsGhost() then
			self:Settle(true)
			local a0 = self.GHOST
			case:SetAlpha(0)
			ns.Tween(0.4, function(e)
				case:SetAlpha(a0 * e)
			end, nil, Ease.outQuad, self)
			Ready()
			Appear()
			return
		end
		self:Fall(function()
			Ready()
			Appear()
		end)
	end
	if how == nil then
		self:Settle(self:IsGhost())
		f.panel:SetAlpha(1)
		f.buttons:SetAlpha(1)
		f.hint:SetAlpha(1)
		Ready()
		return
	end
	f.panel:SetAlpha(0)
	f.buttons:SetAlpha(0)
	f.hint:SetAlpha(0)
	case:SetDraggable(false)
	if how == "vanish" then
		self.state = "vanishing"
		ns.Delay(0.2, function()
			self:Vanish(Arrive)
		end, self)
		return
	end
	self.state = "falling"
	Arrive()
end

-- (1.14.0, after its first test) The case so high over its shadow (in widths of its frame), turned and tilted so much
-- more: painted at once (a case drawn flat paints only when asked).
function CR:Drop(lift, yaw, pitch)
	local case = self.frame.case
	case.dropLift, case.dropYaw, case.dropPitch = lift, yaw, pitch
	if not case.idle then
		case:Paint()
	end
end

-- The case falls before the eye: from over the top of the screen, faster and faster, turning, down onto its shadow;
-- a jolt, a puff of dust where it lands, a small bounce. done: then.
function CR:Fall(done)
	local f = self.frame
	local case = f.case
	self.state = "falling"
	self:Settle(false)
	case:SetLid(0)
	case.moving = true
	-- (from over the top of the screen: its middle as high over its rest as the screen is above it, and its half)
	local cw = self.caseW or self.CASE_BASE
	local high = ((self.sceneH or 768) / 2 - (self.caseY or 0) + (self.caseUp or cw * 0.36) * 1.3) / cw + 0.1
	local turn, tilt = 0.85, -0.14
	self:Drop(high, turn, tilt)
	case:SetAlpha(1)
	ns.Play(ns.SND.whoosh)
	ns.Tween(self.FALL, function(_, raw)
		-- (fallen as far as gravity takes it in that time; its turn and its tilt settling as it comes)
		local left = 1 - raw
		self:Drop(high * (1 - raw * raw), turn * left * left, tilt * left)
	end, function()
		self:Drop(0, 0, 0)
		case:Kick(1)
		ns.Play(ns.SND.packDrop)
		ns.Play(ns.SND.impact[4])
		self:Puff()
		-- (a small bounce, and it rests)
		ns.Tween(self.BOUNCE, function(_, raw)
			self:Drop(0.045 * math.sin(math.pi * raw), 0, 0)
		end, function()
			self:Drop(0, 0, 0)
			case.moving = nil
			if done then
				done()
			end
		end, Ease.linear, self)
	end, Ease.linear, self)
end

-- The puffs of dust where the case lands: out from under it, either way, rising a little, fading.
function CR:Puff()
	local f = self.frame
	local cw = self.caseW or self.CASE_BASE
	local y0 = (self.caseY or 0) - (self.caseDown or cw * 0.26) * 0.55
	for i, p in ipairs(f.puffs) do
		local i, p = i, p; local side = (CuratorOctoFull.Mod(i , 2) == 0) and 1 or -1
		local x0 = side * cw * (0.10 + 0.05 * math.random())
		local dx = side * cw * (0.16 + 0.14 * math.random())
		local s0 = cw * (0.10 + 0.05 * math.random())
		local s1 = s0 * (2.2 + math.random())
		local dy = 6 + math.random() * 22
		local life = 0.55 + math.random() * 0.35
		CuratorOctoFull.SetRotation(p, math.random() * math.pi * 2)
		ns.Tween(life, function(e, raw)
			p:ClearAllPoints()
			p:SetPoint("CENTER", f, "CENTER", x0 + dx * e, y0 + dy * e)
			local s = s0 + (s1 - s0) * e
			CuratorOctoFull.SetSize(p, s, s * 0.62)
			p:SetAlpha(0.42 * (1 - raw) * math.min(1, raw * 6))
		end, function()
			p:SetAlpha(0)
		end, Ease.outQuad, self, (i - 1) * 0.015)
	end
end

-- The case that gave its card goes, as by magic: its light swelling gold, a ring of light, it shrinks and rises as it
-- fades, into sparks of gold that rise and go out. done: then (it is gone, shut again, where it rests).
function CR:Vanish(done)
	local f = self.frame
	local case = f.case
	self.state = "vanishing"
	case:SetDraggable(false)
	case.moving = true
	local s0 = self.caseScale or 1
	local cw = self.caseW or self.CASE_BASE
	local y0 = self.caseY or 0
	ns.Play(ns.SND.holo)
	ns.Play(ns.SND.shiny)
	f.halo:ClearAllPoints()
	f.halo:SetPoint("CENTER", f, "CENTER", 0, y0)
	f.vring:ClearAllPoints()
	f.vring:SetPoint("CENTER", f, "CENTER", 0, y0)
	local a0 = case:GetAlpha()
	ns.Tween(self.VANISH, function(e, raw)
		local k = 1 - 0.32 * e
		case:SetScale(s0 * k)
		case:ClearAllPoints()
		case:SetPoint("CENTER", f, "CENTER", 0, y0 / (s0 * k))
		self:Drop(0.22 * e, 0.5 * e, 0)
		case:SetAlpha(a0 * (1 - raw) ^ 1.6)
		f.halo:SetAlpha(0.95 * math.sin(math.pi * math.min(1, raw * 1.25)))
		CuratorOctoFull.SetSize(f.halo, cw * (1.2 + 0.6 * raw), cw * (0.85 + 0.45 * raw))
		local rs = cw * (0.3 + 1.3 * raw)
		CuratorOctoFull.SetSize(f.vring, rs, rs)
		f.vring:SetAlpha(0.8 * (1 - raw))
	end, function()
		f.halo:SetAlpha(0)
		-- (the light of the case where the layout puts it again: over it, as wide)
		f.halo:ClearAllPoints()
		CuratorOctoFull.SetSize(f.halo, cw * 1.5, cw * 0.95)
		f.halo:SetPoint("CENTER", f, "CENTER", 0, y0 + cw * 0.04)
		f.vring:SetAlpha(0)
		case:SetAlpha(0)
		case:SetLid(0)
		self:Settle(false)
		case:SetAlpha(0)
		if done then
			done()
		end
	end, Ease.outQuad, self)
	-- (its sparks: out of all of it, rising, drifting, going out)
	for i, m in ipairs(f.motes) do
		local i, m = i, m; local x0 = (math.random() - 0.5) * cw * 0.62
		local yy = y0 + (math.random() - 0.4) * cw * 0.3
		local rise = cw * (0.18 + 0.3 * math.random())
		local drift = (math.random() - 0.5) * cw * 0.2
		local s = 6 + math.random() * 12
		local life = 0.7 + math.random() * 0.6
		ns.Tween(life, function(e, raw)
			m:ClearAllPoints()
			m:SetPoint("CENTER", f, "CENTER", x0 + drift * e, yy + rise * e)
			CuratorOctoFull.SetSize(m, s, s)
			m:SetAlpha(math.sin(math.pi * raw) * 0.95)
		end, function()
			m:SetAlpha(0)
		end, Ease.outQuad, self, 0.05 + (i - 1) * (self.VANISH * 0.6 / self.MOTES))
	end
end

-- Opened: its latches spring, it jolts, its lid rises and its light pours out; what it holds goes away and the band
-- comes in its place, filled from it, and runs.
function CR:Open()
	local f = self.frame
	if not (f and f:IsShown()) or self.state ~= "case" then
		return
	end
	-- (for real: a case and a key go, its card drawn and kept by Cases.lua, before anything is shown; the band then runs
	-- to it. Nothing opened: why, under the buttons)
	if self.real then
		local CS = ns.Cases
		local rec, why
		-- (1.14.2, his word: « on peut voir sur les récompenses la carte qu'il va drop avant de voir le truc qui défile »:
		-- opening already as Cases.lua keeps its card, so that what it tells then (CASES_CHANGED, RUBIES_CHANGED, below)
		-- paints nothing again: what it holds goes away as it was, the count of its cards with it)
		self.state = "opening"
		if CS then
			rec, why = CS:Open(self.real)
		end
		if not rec then
			self.state = "case"
			self:ClearBatch()
			ns.Play(ns.SND.close)
			self:PaintReal(why or "closed")
			return
		end
		self.forced = self:Forced(rec)
		self.pending, self.pendingHow = rec, nil
		if self.batch then
			self.batch.opened = self.batch.opened + 1
			self:PaintBatch()
		end
	end
	self:CloseInspect(true)
	GameTooltip:Hide()
	self.state = "opening"
	local case = f.case
	f.open:Disable()
	for _, b in pairs(f.batchButtons) do b:Disable() end
	f.key.armed = nil
	case:SetDraggable(false)
	ns.Play(ns.SND.chainSnap)
	case:Kick(0.7)
	-- (a glint on each latch)
	local s = self.caseScale or 1
	for i, sp in ipairs(f.sparks) do
		local i, sp = i, sp; local x, y = case:LatchScreen(i)
		sp:ClearAllPoints()
		sp:SetPoint("CENTER", f, "CENTER", x * s, self.caseY + y * s)
		ns.Tween(0.4, function(_, raw)
			sp:SetAlpha(math.sin(raw * math.pi))
			CuratorOctoFull.SetRotation(sp, raw * 1.2)
		end, nil, Ease.linear, self, (i - 1) * 0.05)
	end
	ns.Tween(0.15, function(e)
		f.buttons:SetAlpha(1 - e)
		f.hint:SetAlpha(1 - e)
	end, function()
		f.buttons:Hide()
		f.hint:Hide()
	end, Ease.outQuad, self)
	-- its lid: up past its stop a little, then back to it; the light out of its seam, flaring then settling
	ns.Delay(self.AT_LID, function()
		ns.Play(SND_LID)
	end, self)
	ns.Tween(self.LID_TIME, function(e, raw)
		case:SetLid(e)
		local x, y = case:MouthScreen()
		f.flare:ClearAllPoints()
		f.flare:SetPoint("CENTER", f, "CENTER", x * s, self.caseY + y * s)
		f.flare:SetAlpha(0.9 * math.sin(math.min(1, raw * 1.6) * math.pi * 0.5) * (1 - 0.6 * raw))
		f.halo:SetAlpha(0.5 * raw)
	end, function()
		self.lidOpen = true
	end, Ease.outBack, self, self.AT_LID)
	-- what it holds goes down and away; the band comes, filled
	ns.Tween(0.3, function(e)
		f.panel:SetAlpha(1 - e)
		f.panel:ClearAllPoints()
		f.panel:SetPoint("CENTER", f, "CENTER", 0, self.midY - 18 * e)
	end, function()
		f.panel:Hide()
	end, Ease.inQuad, self, self.AT_AWAY)
	ns.Delay(self.AT_BAND, function()
		self:Fill(self.forced.tier, self.forced.finish)
		f.band:SetAlpha(0)
		f.band:Show()
		ns.Tween(0.25, function(e)
			f.band:SetAlpha(e)
			f.band:ClearAllPoints()
			f.band:SetPoint("CENTER", f, "CENTER", 0, self.bandY - 16 * (1 - e))
		end, nil, Ease.outQuad, self)
	end, self)
	ns.Delay(self.AT_RUN, function()
		self:Spin()
	end, self)
end

-- (1.14.2) A case being opened, what came not shown yet: its lid, its band (nothing must tell it before them).
function CR:Hiding()
	local f = self.frame
	return f ~= nil and f:IsShown() and (self.state == "opening" or self.state == "spin")
end

-- Back to the case, shut again, what it holds under it (another case of the same): the card and the band going away.
function CR:Back()
	local f = self.frame
	if not (f and f:IsShown()) or self.spinning then
		return
	end
	-- (1.14.0, after its first test: a card come out of a contract, UI/CaseView.lua: back to the contracts)
	if self.contract then
		self.contract = nil
		f:Hide()
		return
	end
	ns.CancelOwner(self)
	if self.batch and not self.batch.advance then self:ClearBatch() end
	local rv, band = f.reveal, f.band
	local a0, b0 = rv:GetAlpha(), band:GetAlpha()
	rv.again:Hide()
	rv.inspect:Hide()
	rv.close:Hide()
	self:CloseInspect(true)
	ns.Tween(0.25, function(e)
		rv:SetAlpha(a0 * (1 - e))
		band:SetAlpha(b0 * (1 - e))
	end, function()
		rv:Hide()
		rv:SetAlpha(1)
		band:Hide()
		band:SetAlpha(1)
		self:ResetBand()
	end, Ease.outQuad, self)
	-- (the case that gave it goes, as by magic; another falls, or its ghost stays)
	self:ShowCase("vanish")
end

-- The light of the case while it is open: breathing, the flare of its seam with it; its dust of gold rising.
function CR:Breathe(elapsed)
	local f = self.frame
	local case = f.case
	-- (the button of a key armed, its seconds gone: its price again)
	if f.key.armed and not Armed(f.key) then
		f.key.armed = nil
		self:PaintReal()
	end
	local open = case:GetLid() > 0 and not (self.state == "opening" and not self.lidOpen)
	self.breath = (self.breath or 0) + elapsed
	if open and (self.state == "spin" or self.state == "out") then
		local p = 0.82 + 0.18 * math.sin(self.breath * 3.2)
		case:SetPulse(p)
		-- (the flare stays on its seam as it turns)
		local s = self.caseScale or 1
		local x, y = case:MouthScreen()
		f.flare:ClearAllPoints()
		f.flare:SetPoint("CENTER", f, "CENTER", x * s, self.caseY + y * s)
		f.flare:SetAlpha(0.32 * p * case:GetLid())
		f.halo:SetAlpha(0.42 * p * case:GetLid())
	end
	-- (its dust: each speck rises from the mouth of the case, drifting, and fades; another in its place)
	local lid = case:GetLid()
	if lid <= 0 or case.flat then
		if self.dusty then
			self.dusty = nil
			for _, d in ipairs(f.dust) do
				d.tex:SetAlpha(0)
			end
		end
		return
	end
	self.dusty = true
	local s = self.caseScale or 1
	local mx, my = case:MouthScreen()
	local life = self.DUST_LIFE
	for _, d in ipairs(f.dust) do
		local age = (self.breath / life + d.phase)
		local cycle = math.floor(age)
		local u = age - cycle
		if cycle ~= d.cycle then
			d.cycle = cycle
			d.x0 = (math.random() - 0.5) * self.caseW * 0.62
			d.drift = (math.random() - 0.5) * 40
			d.size = 6 + math.random() * 10
			d.rise = 70 + math.random() * 70
		end
		local t = d.tex
		t:ClearAllPoints()
		t:SetPoint("CENTER", f, "CENTER", mx * s + d.x0 + d.drift * u, self.caseY + my * s + 10 + d.rise * u)
		CuratorOctoFull.SetSize(t, d.size, d.size)
		-- (1.14.0, after its first test: fading with the case as it vanishes)
		t:SetAlpha(math.sin(u * math.pi) * 0.85 * math.min(1, lid) * case:GetAlpha())
	end
end

-------------------------------------------------------------------------------
-- The run
-------------------------------------------------------------------------------
-- The band runs, faster first, then slower down to its stop.
function CR:Spin()
	local f = self.frame
	if not (f and f:IsShown()) or self.spinning then
		return
	end
	self.state = "spin"
	f.reveal:Hide()
	self.spinning = true
	local from = self:Center(self.FROM)
	local land = (math.random() * 2 - 1) * self.LAND * self.W
	local to = self:Center(self.WIN) + land
	self.land = land
	local dist = to - from
	local slow = self.SLOW
	local dur = self.SPIN + (math.random() * 2 - 1) * self.SPIN_MORE
	self.under = self:Under(from)
	self.tickAt = nil
	ns.Tween(dur, function(e)
		local p = from + dist * e
		self:MoveTo(p)
		local u = self:Under(p)
		if u ~= self.under then
			self.under = u
			local now = GetTime()
			if not self.tickAt or now - self.tickAt >= self.TICK_GAP then
				self.tickAt = now
				self.ticks = (self.ticks or 0) + 1
				ns.Play(SND_TICK)
			end
		end
	end, function()
		self:MoveTo(to)
		self:Landed()
	end, function(t)
		return 1 - (1 - t) ^ slow
	end, self)
end

-- The band stopped: its card lit, the others dimmed; then the card comes out.
function CR:Landed()
	local f = self.frame
	self.spinning = false
	self.state = "out"
	local t = f.tiles[self.WIN]
	local col = Colour(self.win.tier)
	ns.Play(ns.SND.packDrop)
	t.glow:SetVertexColor(col[1], col[2], col[3])
	ns.Tween(0.3, function(e)
		t.glow:SetAlpha(0.95 * e)
		t.face:SetScale(1 + 0.08 * e)
	end, nil, Ease.outBack, self)
	ns.Tween(0.45, function(e)
		for i, o in ipairs(f.tiles) do
			if i ~= self.WIN then
				o:SetAlpha(1 - 0.65 * e)
			end
		end
	end, nil, Ease.outQuad, self)
	ns.Delay(self.AT_CARD, function()
		self:Reveal()
	end, self)
end

-- The card that came out, flying out of the band, large, in its light; its words, then what it came with, then the
-- buttons.
function CR:Reveal()
	local f = self.frame
	local rv = f.reveal
	local win = self.win
	local tier = win.tier
	local top = tier == self.TOP
	local col, ink = Colour(tier), Ink(tier)
	local card = rv.card
	-- (for real: what came, in the chat too)
	self:Told()
	card:Set({ tier = tier, card = win.card, entry = win.entry, weapon = win.weapon, wear = win.wear, finish = win.finish, pt = win.pt }, self.RANKS)
	card:SetLive(true)
	rv.glow:SetVertexColor(col[1], col[2], col[3])
	rv.rays:SetVertexColor(col[1], col[2], col[3])
	rv.flash:SetVertexColor(col[1], col[2], col[3])
	rv.ring:SetVertexColor(col[1], col[2], col[3])
	for _, w in ipairs({ rv.name, rv.rank, rv.extra, rv.note, rv.again, rv.inspect, rv.close }) do
		w:SetAlpha(0)
	end
	rv.again:Hide()
	rv.inspect:Hide()
	rv.close:Hide()
	rv.card:SetBack(self.own and self.own.def.art and self.own.def.art.back or nil)
	self:FxClear()
	rv.dim:SetAlpha(0)
	rv.glow:SetAlpha(0)
	rv.rays:SetAlpha(0)
	rv.flash:SetAlpha(0)
	rv.ring:SetAlpha(0)
	card:SetAlpha(0)
	rv:Show()
	-- (the names: the card in the colour of its rank, its rank; the condition it came in on the bar. A weapon the game
	-- does not know yet: its name as soon as it does)
	local wname = win.weapon and ns.CrateCard.WeaponName(win.weapon)
	if win.weapon then
		rv.name:SetText(wname or L["Priceless card"])
	else
		rv.name:SetText(self:PickName(win) or "?")
	end
	if win.weapon and not wname then
		self:NameLater(1)
	end
	rv.name:SetTextColor(ink[1], ink[2], ink[3])
	rv.rank:SetText(L[self.RANKS[tier].label])
	rv.rank:SetTextColor(col[1], col[2], col[3])
	-- (31 October, his word: its condition on the card, its wear, never in words: no more its word nor its bar; its forged
	-- finish)
	if win.finish then
		local ink = FINISH_INK[win.finish]
		rv.extra:SetText(L[self.FINISH_NAME[win.finish]])
		rv.extra:SetTextColor(ink[1], ink[2], ink[3])
	else
		rv.extra:SetText("")
	end
	rv.note:SetText((win.weapon and ns.CrateCard.WeaponNote(win.weapon)) or (win.entry and ns.CrateItems:From(win.entry)) or "")
	-- (1.14.0, after the test of the Paladin collection by its author: a card with a film of its own, Arthas, Sulfuras,
	-- the entrances on: its fanfare when the film is over)
	local film = ns.CaseFilm and ns.CaseFilm:Enabled() and self:FilmOf(win) or nil
	if not film then
		Fanfare(tier)
	end
	-- (out of the band: from the card it stopped on, as large as it, to the middle, large; a weapon of legend makes its
	-- entrance first, its model there)
	local tile = (not self.contract) and f.tiles[self.WIN] or nil
	local x0, y0 = -(self.land or 0), self.bandY
	local x1, y1 = self.cardX, self.cardY
	local b0 = f.band:GetAlpha()
	ns.Tween(0.3, function(e)
		rv.dim:SetAlpha(e)
		f.band:SetAlpha(b0 + (0.15 - b0) * e)
		if tile then
			tile.face:SetAlpha(1 - e)
		end
	end, nil, Ease.outQuad, self)
	local lead = 0
	if win.weapon and self:Entrance(x0, y0, x1, y1) then
		lead = self.ARM_OUT + self.ARM_HOLD + self.ARM_IN - 0.5
	elseif film and self:Film(film, x1, y1, tier, top) then
		-- (its words when its film is over: CR:Film)
		return
	else
		if f.arm then
			ns.CrateCard.Arm(f.arm, nil)
		end
		self:CardOut(x0, y0, x1, y1, tier, top)
	end
	self:Words(lead)
end

-- The card out of the band, from the card it stopped on (as large as it) to the middle, large, in its light; the flash
-- and the ring of the better ranks.
function CR:CardOut(x0, y0, x1, y1, tier, top)
	local rv = self.frame.reveal
	local card = rv.card
	local ch = self.CARD_W * 717 / 512
	local k0 = self.H / ch
	ns.Tween(0.55, function(e, raw)
		local k = k0 + (1 - k0) * e
		local x = x0 + (x1 - x0) * math.min(1, raw * 1.15)
		local y = y0 + (y1 - y0) * math.min(1, raw * 1.15)
		card:SetScale(k)
		card:ClearAllPoints()
		card:SetPoint("CENTER", rv, "CENTER", x / k, y / k)
		card:SetAlpha(math.min(1, raw * 4))
		rv.glow:SetAlpha(0.5 * raw)
		rv.rays:SetAlpha(((tier >= 3) and 0.6 or 0.32) * raw)
	end, nil, Ease.outBack, self)
	if tier >= 3 then
		ns.Tween(0.6, function(_, raw)
			rv.flash:SetAlpha((top and 0.95 or 0.6) * (1 - raw))
			local s = 220 + 520 * raw
			CuratorOctoFull.SetSize(rv.ring, s, s)
			rv.ring:SetAlpha(0.8 * (1 - raw))
		end, nil, Ease.linear, self, 0.2)
	end
end

-- (1.14.0) The entrance of a weapon of legend, as CS2 shows the gold of its cases: the golden card bursts in the band,
-- in a flash and a ring of gold; the weapon comes out of it turning fast, flies to the middle growing, turns there
-- slower and slower in its light; then it goes into the window of its card, which comes around it, and becomes the
-- weapon of the card (as large, turned the same way: one takes the place of the other). False: its model is not
-- standing (loaded while the band ran, out of sight: CR:Fill), the card comes out as the others. (Its model shown or
-- hidden, never faded: the client draws a model whatever its alpha.)
function CR:Entrance(x0, y0, x1, y1)
	local f = self.frame
	local rv, arm = f.reveal, f.arm
	local CC = ns.CrateCard
	if not (arm and arm.weapon and arm.weapon == self.win.weapon and CC.ArmTick(arm, 0)) then
		return false
	end
	local card = rv.card
	local OUT, HOLD, IN = self.ARM_OUT, self.ARM_HOLD, self.ARM_IN
	local total = OUT + HOLD + IN
	local S0, S1 = self.H * 1.2, self.ARM_SIZE
	-- (where it goes: the window of its card, a frame as tall as the window: its weapon as long as the one of the card)
	local k = self.CARD_W / 512
	local wx, wy = x1, y1 + (717 / 2 - (24 + 552) / 2) * k
	local S2 = (552 - 24) * k
	self.entering = true
	card:SetScale(1)
	card:ClearAllPoints()
	card:SetPoint("CENTER", rv, "CENTER", x1, y1)
	card:SetAlpha(0)
	if card.arm then
		CC.ArmShow(card.arm, false)
	end
	local function place(x, y, size)
		arm:ClearAllPoints()
		arm:SetPoint("CENTER", f, "CENTER", x, y)
		CuratorOctoFull.SetSize(arm, size, size)
		CC.ArmFit(arm)
	end
	place(x0, y0, S0)
	CC.ArmShow(arm, true)
	-- the golden card bursts: its flash, its ring of gold, where it was
	ns.Play(ns.SND.burst[5])
	ns.Play(ns.SND.whoosh)
	for _, t in ipairs({ rv.flash, rv.ring }) do
		t:ClearAllPoints()
		t:SetPoint("CENTER", rv, "CENTER", x0, y0)
	end
	ns.Tween(0.7, function(_, raw)
		rv.flash:SetAlpha(0.95 * (1 - raw))
		local s = 160 + 820 * raw
		CuratorOctoFull.SetSize(rv.ring, s, s)
		rv.ring:SetAlpha(0.9 * (1 - raw))
	end, function()
		for _, t in ipairs({ rv.flash, rv.ring }) do
			t:ClearAllPoints()
			t:SetPoint("CENTER", rv, "CENTER", x1, y1)
		end
	end, Ease.linear, self)
	-- the weapon out of it, to the middle, growing; its light behind it there
	ns.Tween(OUT, function(e)
		place(x0 + (x1 - x0) * e, y0 + (y1 - y0) * e, S0 + (S1 - S0) * e)
	end, nil, Ease.outCubic, self)
	ns.Tween(HOLD, function(_, raw)
		rv.glow:SetAlpha(0.55 * raw)
		rv.rays:SetAlpha(0.6 * raw)
	end, nil, Ease.outQuad, self, OUT * 0.6)
	-- its turn all along: fast, then slower and slower, ending turned as the weapon of its card will be then
	local pose = arm.pose
	local v0, v1, tau = self.ARM_SPIN[1], self.ARM_SPIN[2], self.ARM_SPIN[3]
	local function turned(t)
		return v1 * t + (v0 - v1) * tau * (1 - math.exp(-t / tau))
	end
	local cardEnd = CC.ARM_FACE + math.sin(total * CC.ARM_SPEED) * CC.ARM_SWING
	local phase = CuratorOctoFull.Mod((cardEnd - turned(total)) , (2 * math.pi))
	ns.Tween(total, function(_, raw)
		CC.ArmFace(arm, pose[3] + phase + turned(raw * total))
	end, nil, Ease.linear, self)
	-- into its card: the card comes around it, the weapon goes into its window and becomes the weapon of the card; a
	-- pulse of gold as it goes in
	ns.Tween(IN, function(e, raw)
		place(x1 + (wx - x1) * e, y1 + (wy - y1) * e, S1 + (S2 - S1) * e)
		card:SetAlpha(math.min(1, raw * 1.6))
		local ks = 0.9 + 0.1 * e
		card:SetScale(ks)
		card:ClearAllPoints()
		card:SetPoint("CENTER", rv, "CENTER", x1 / ks, y1 / ks)
	end, function()
		CC.Arm(arm, nil)
		if card.arm then
			CC.ArmShow(card.arm, true)
		end
		self.entering = nil
	end, Ease.outCubic, self, OUT + HOLD)
	ns.Delay(OUT + HOLD + IN * 0.4, function()
		ns.Play(ns.SND.impact[5])
		ns.Tween(0.5, function(_, raw)
			rv.flash:SetAlpha(0.6 * (1 - raw))
		end, nil, Ease.linear, self)
	end, self)
	return true
end

-- (1.14.0, after the test of the Paladin collection by its author) The film of a card when it has one: the one of its
-- entry (a figure: Arthas), the one of its weapon of legend (Sulfuras), Data/Crate*.lua.
function CR:FilmOf(pick)
	if not pick then
		return nil
	end
	if pick.entry and pick.entry.film then
		return pick.entry.film
	end
	local wart = pick.weapon and ns.CrateCard.WeaponArt(pick.weapon)
	return wart and wart.film or nil
end

-- (1.14.0, after the test of the Paladin collection by its author) The film of a card (CR:FilmOf, UI/CaseFilm.lua)
-- over the scene: its last image goes into the window of the card, which comes around it there (as soon as it is
-- skipped: there, at once), in its light, its fanfare; then its words. False: no film (the entrances off).
function CR:Film(film, x1, y1, tier, top)
	local f = self.frame
	local k = self.CARD_W / 512
	-- (the window of its picture: the middle of the card, 492 x 697 points of it)
	local into = { x = x1, y = y1, w = 492 * k, h = 697 * k }
	local played = ns.CaseFilm:Play(film, f, into, function()
		self.entering = nil
		Fanfare(tier)
		self:FilmOut(x1, y1, tier, top)
		self:Words(0.3)
	end, ns.GetTimeScale(self))
	if not played then
		return false
	end
	self.entering = true
	if f.arm then
		ns.CrateCard.Arm(f.arm, nil)
	end
	return true
end

-- (the card where the last image of its film went into it: there, coming in its light; the flash and the ring of its
-- rank)
function CR:FilmOut(x1, y1, tier, top)
	local rv = self.frame.reveal
	local card = rv.card
	card:SetScale(1)
	card:ClearAllPoints()
	card:SetPoint("CENTER", rv, "CENTER", x1, y1)
	ns.Tween(0.5, function(_, raw)
		card:SetAlpha(raw)
		rv.glow:SetAlpha(0.5 * raw)
		rv.rays:SetAlpha(((tier >= 3) and 0.6 or 0.32) * raw)
	end, nil, Ease.outQuad, self)
	if tier >= 3 then
		ns.Tween(0.6, function(_, raw)
			rv.flash:SetAlpha((top and 0.95 or 0.6) * (1 - raw))
			local s = 220 + 520 * raw
			CuratorOctoFull.SetSize(rv.ring, s, s)
			rv.ring:SetAlpha(0.8 * (1 - raw))
		end, nil, Ease.linear, self, 0.45)
	end
end

-- Its words, then what it came with, then the buttons, in their time (lead: so many seconds later, after an entrance);
-- with its words, the sound of a card of the case of the month (a spell, a voice, an armour).
function CR:Words(lead)
	local rv = self.frame.reveal
	ns.Tween(0.3, function(e)
		rv.name:SetAlpha(e)
		rv.rank:SetAlpha(e)
	end, nil, Ease.outQuad, self, lead + self.AT_WORDS - self.AT_CARD)
	local entry = self.win and self.win.entry
	if entry then
		ns.Delay(lead + self.AT_WORDS - self.AT_CARD, function()
			ns.CrateItems:Play(entry, self)
		end, self)
	end
	ns.Delay(lead + self.AT_EXTRA - self.AT_CARD, function()
		self:Extra()
	end, self)
	ns.Delay(lead + self.AT_BUTTONS - self.AT_CARD, function()
		if self:AdvanceBatch() then return end
		-- (for real: another case while there is one and a key for it, else back to the case: a key to buy, the collection;
		-- a card come out of a contract: back to the contracts)
		if self.contract then
			rv.again:SetText(L["Back to the contracts"])
		elseif self.real then
			local CS = ns.Cases
			rv.again:SetText((CS and CS:CanOpen(self.real)) and L["Open another case"] or L["Back to the case"])
		else
			rv.again:SetText(L["Open another case"])
		end
		rv.again:Show()
		rv.inspect:Show()
		rv.close:Show()
		ns.Tween(0.25, function(e)
			rv.again:SetAlpha(e)
			rv.inspect:SetAlpha(e)
			rv.close:SetAlpha(e)
		end, nil, Ease.outQuad, self)
	end, self)
end

-- The name of the weapon that came out, once the game knows it (asked again a while).
function CR:NameLater(n)
	ns.Delay(0.25, function()
		local w = self.win and self.win.weapon
		local name = w and ns.CrateCard.WeaponName(w)
		if name then
			self.frame.reveal.name:SetText(name)
		elseif w and n < 40 then
			self:NameLater(n + 1)
		end
	end, self)
end

-- What the card came with: its forged finish, the note (what its weapon is); the thunder over it when it came
-- thunderforged, the light of the titans when titanforged.
function CR:Extra()
	local rv = self.frame.reveal
	ns.Tween(0.35, function(e)
		rv.extra:SetAlpha(e)
		rv.note:SetAlpha(e)
	end, nil, Ease.outQuad, self)
	local finish = self.win.finish
	if finish == "thunder" then
		ns.Play(ns.SND.thunder)
		ns.Delay(0.12, function()
			ns.Play(ns.SND.thunderRoll)
		end, self)
		self:Thunderstrike()
	elseif finish == "titan" then
		-- (1.14.0, his word: the toast of a warforged item of the game, at once; no blow, no chime before it)
		ns.Play(ns.SND.titanFanfare)
		self:PrismStrike()
	end
end

-------------------------------------------------------------------------------
-- (1.14.0) The coming of a forged card, as in the boosters: its pieces (UI/Booster.lua: B:Ring, B:Flare, B:Beam,
-- B:Spikes, B:Bolts, B:Flash, B:EdgeGlow, B:Shake), then the lightning that strikes a thunderforged card and the light
-- of the prism through a titanforged one (UI/Booster.lua: B:Thunderstrike; UI/Forge.lua: B:TitanStrike).
-------------------------------------------------------------------------------
local WHITE, PEARL, CYAN, ROSE = { 1, 1, 1 }, { 1, 0.97, 0.92 }, { 0.55, 0.92, 1 }, { 1, 0.6, 0.92 }
local STORM, STORM_PALE = { 0.55, 0.8, 1 }, { 0.9, 0.97, 1 }
local SPECTRUM = {
	{ 1, 0.35, 0.4 }, { 1, 0.72, 0.3 }, { 1, 0.96, 0.45 }, { 0.42, 1, 0.55 }, { 0.38, 0.85, 1 }, { 0.52, 0.5, 1 }, { 0.92, 0.48, 1 },
}

-- Everything of a coming gone at once (a new card, the scene shown again).
function CR:FxClear()
	local rv = self.frame and self.frame.reveal
	if not (rv and rv.fx) then
		return
	end
	ns.CancelOwner(rv.fx)
	for _, t in ipairs({ rv.flare, rv.prismFlash, rv.spikes, rv.edge, rv.white, rv.prismRays[1], rv.prismRays[2] }) do
		t:SetAlpha(0)
	end
	for _, list in ipairs({ rv.beams, rv.lightning, rv.bolts, rv.rings }) do
		for _, t in ipairs(list) do
			t:SetAlpha(0)
			t.busy = false
		end
	end
	for _, p in ipairs({ rv.sparks, rv.streaks, rv.stars, rv.shards, rv.motes }) do
		if p and p.Clear then
			p:Clear()
		end
	end
	rv.prism, rv.shakeT = nil, nil
	self:Unshake()
end

-- (the card back where it is, after it shook)
function CR:Unshake()
	local rv = self.frame.reveal
	if rv.shook then
		rv.shook = nil
		local card = rv.card
		local k = card:GetScale()
		card:ClearAllPoints()
		card:SetPoint("CENTER", rv, "CENTER", (self.cardX or 0) / k, (self.cardY or 0) / k)
	end
end

-- Each frame of the reveal: the light of the prism turning behind its card; the card shaking, dying away.
function CR:FxTick(elapsed)
	local rv = self.frame.reveal
	local pr = rv.prism
	if pr then
		pr.ang = pr.ang + pr.spin * elapsed
		pr.k = pr.k + (1 - pr.k) * math.min(1, elapsed * 3)
		local d = pr.size * pr.k
		local a, b = rv.prismRays[1], rv.prismRays[2]
		a:ClearAllPoints()
		a:SetPoint("CENTER", rv.behind, "CENTER", self.cardX or 0, self.cardY or 0)
		CuratorOctoFull.SetSize(a, d, d)
		CuratorOctoFull.SetRotation(a, pr.ang)
		b:ClearAllPoints()
		b:SetPoint("CENTER", rv.behind, "CENTER", self.cardX or 0, self.cardY or 0)
		CuratorOctoFull.SetSize(b, d * 0.68, d * 0.68)
		CuratorOctoFull.SetRotation(b, -pr.ang * 1.6 + 0.4)
	end
	if rv.shakeT and rv.shakeT > 0 and not self.entering then
		rv.shakeT = math.max(0, rv.shakeT - elapsed)
		local amp = rv.shakeA * rv.shakeT / rv.shakeD
		local card = rv.card
		local k = card:GetScale()
		card:ClearAllPoints()
		card:SetPoint("CENTER", rv, "CENTER", ((self.cardX or 0) + (math.random() * 2 - 1) * amp) / k,
			((self.cardY or 0) + (math.random() * 2 - 1) * amp) / k)
		rv.shook = true
		if rv.shakeT <= 0 then
			self:Unshake()
		end
	end
end

-- The card shakes, dying away (the stronger shake wins).
function CR:FxShake(dur, amp)
	local rv = self.frame.reveal
	local left = (rv.shakeT or 0) > 0 and rv.shakeA * rv.shakeT / rv.shakeD or 0
	if amp >= left then
		rv.shakeT, rv.shakeD, rv.shakeA = dur, dur, amp
	end
end

-- A shock wave: a ring that grows from (x, y) to size and fades (file: "Ring", soft, or "Shock", a sharp front; flat: its
-- height for a width of 1, a wave along the ground).
function CR:FxRing(x, y, color, size, dur, alpha, delay, file, flat)
	local rv = self.frame.reveal
	local r
	for _, t in ipairs(rv.rings) do
		if not t.busy then
			r = t
			break
		end
	end
	if not r then
		return
	end
	r.busy = true
	r:SetTexture(ns.MEDIA .. (file or "Ring"))
	r:ClearAllPoints()
	r:SetPoint("CENTER", rv.fx, "CENTER", x, y)
	r:SetVertexColor(color[1], color[2], color[3])
	CuratorOctoFull.SetSize(r, 1, 1)
	r:SetAlpha(0)
	local fl = flat or 1
	ns.Tween(dur or 0.6, function(e, raw)
		local k = (size or 400) * (0.15 + 0.85 * e)
		CuratorOctoFull.SetSize(r, k, k * fl)
		r:SetAlpha((alpha or 0.8) * (1 - raw) * math.min(1, raw * 8))
	end, function()
		r:SetAlpha(0)
		r.busy = false
	end, Ease.outCubic, rv.fx, delay)
end

-- The long streak of light of an impact, across (x, y).
function CR:FxFlare(x, y, color, width, dur, alpha)
	local rv = self.frame.reveal
	local f = rv.flare
	f:ClearAllPoints()
	f:SetPoint("CENTER", rv.fx, "CENTER", x, y)
	f:SetVertexColor(color[1], color[2], color[3])
	ns.Tween(dur or 0.5, function(e, raw)
		CuratorOctoFull.SetSize(f, math.max(1, width * (0.3 + 0.7 * e)), 46 + 34 * (1 - raw))
		f:SetAlpha((alpha or 1) * (1 - raw) ^ 1.3)
	end, function()
		f:SetAlpha(0)
	end, Ease.outCubic, rv.fx)
end

-- A pillar of light out of (x, y), up, w wide and h high: it shoots out, then narrows and fades.
function CR:FxBeam(i, x, y, color, w, h, dur, alpha)
	local rv = self.frame.reveal
	local b = rv.beams[i]
	b:ClearAllPoints()
	b:SetPoint("BOTTOM", rv.behind, "CENTER", x, y)
	b:SetVertexColor(color[1], color[2], color[3])
	CuratorOctoFull.SetSize(b, 1, 1)
	ns.Tween(dur, function(_, raw)
		local out = Ease.outCubic(math.min(1, raw / 0.16))
		CuratorOctoFull.SetSize(b, math.max(1, w * (1 - 0.55 * raw)), math.max(1, h * out))
		local fade = raw < 0.16 and 1 or (1 - (raw - 0.16) / 0.84) ^ 1.4
		b:SetAlpha((alpha or 1) * fade)
	end, function()
		b:SetAlpha(0)
	end, Ease.linear, rv.fx)
end

-- Needles of light bursting out behind (x, y).
function CR:FxSpikes(x, y, color, size, dur, alpha)
	local rv = self.frame.reveal
	local t = rv.spikes
	t:ClearAllPoints()
	t:SetPoint("CENTER", rv.behind, "CENTER", x, y)
	t:SetVertexColor(color[1], color[2], color[3])
	local turn = (math.random() - 0.5) * 0.6
	ns.Tween(dur or 0.5, function(e, raw)
		local k = size * (0.35 + 0.65 * e)
		CuratorOctoFull.SetSize(t, k, k)
		CuratorOctoFull.SetRotation(t, turn * raw)
		t:SetAlpha((alpha or 1) * (1 - raw) ^ 1.5)
	end, function()
		t:SetAlpha(0)
	end, Ease.outCubic, rv.fx)
end

-- Lightning around (x, y) for an instant.
function CR:FxBolts(x, y, size, color)
	local rv = self.frame.reveal
	for i, t in ipairs(rv.bolts) do
		local i, t = i, t; local a = math.random() * math.pi * 2
		t:ClearAllPoints()
		t:SetPoint("CENTER", rv.fx, "CENTER", x + math.cos(a) * size * 0.12, y + math.sin(a) * size * 0.12)
		CuratorOctoFull.SetSize(t, size * (0.8 + 0.3 * math.random()), size * (0.8 + 0.3 * math.random()))
		CuratorOctoFull.SetRotation(t, math.random() * math.pi * 2)
		t:SetVertexColor(color[1], color[2], color[3])
		ns.Tween(0.22, function(_, raw)
			t:SetAlpha((raw < 0.3 and 1 or (1 - raw) / 0.7) * (0.55 + 0.45 * math.random()))
		end, function()
			t:SetAlpha(0)
		end, Ease.linear, rv.fx, (i - 1) * 0.04)
	end
	ns.Play(ns.SND.crackle)
end

-- The flash over the whole screen; the light along its edges, swelling at once and dying away.
function CR:FxFlash(color, peak, dur)
	local f = self.frame.reveal.white
	f:SetVertexColor(color[1], color[2], color[3])
	f:SetAlpha(peak)
	ns.Tween(dur, function(e)
		f:SetAlpha(peak * (1 - e))
	end, nil, Ease.outQuad, self.frame.reveal.fx)
end

function CR:FxEdge(color, peak, dur)
	local e = self.frame.reveal.edge
	e:SetVertexColor(color[1], color[2], color[3])
	ns.Tween(dur, function(_, raw)
		if raw < 0.12 then
			e:SetAlpha(peak * raw / 0.12)
		else
			e:SetAlpha(peak * (1 - (raw - 0.12) / 0.88) ^ 1.3)
		end
	end, function()
		e:SetAlpha(0)
	end, Ease.linear, self.frame.reveal.fx)
end

-- Thunderforged: a bolt of lightning falls from the sky on the card, three times bright; the screen goes white and
-- blue, lightning crackles around it, waves, sparks; the card shakes; its own lightning strikes it at once.
function CR:Thunderstrike()
	local rv = self.frame.reveal
	local x, y = self.cardX or 0, self.cardY or 0
	local c = rv.card
	for i, b in ipairs(rv.lightning) do
		local i, b = i, b; b:ClearAllPoints()
		b:SetPoint("BOTTOM", rv.fx, "CENTER", x + (i - 1.5) * 14, y - 30)
		CuratorOctoFull.SetSize(b, i == 1 and 190 or 120, 1150)
		ns.Tween(0.55, function(_, raw)
			-- (three strokes, the last one fading)
			local k = (raw < 0.12 and 1) or (raw < 0.2 and 0.25) or (raw < 0.34 and 0.95) or (raw < 0.42 and 0.3) or (1 - raw) / 0.58 * 0.9
			b:SetAlpha(k * (i == 1 and 1 or 0.6))
		end, function()
			b:SetAlpha(0)
		end, Ease.linear, rv.fx, (i - 1) * 0.05)
	end
	self:FxFlash({ 0.82, 0.92, 1 }, 0.5, 0.5)
	self:FxEdge(STORM, 0.62, 1.1)
	self:FxBolts(x, y, 520, STORM_PALE)
	ns.Delay(0.2, function()
		self:FxBolts(x, y + 30, 600, STORM)
	end, rv.fx)
	self:FxRing(x, y, STORM, 640, 0.6, 0.85, 0, "Shock")
	self:FxRing(x, y, WHITE, 420, 0.5, 0.5, 0.05)
	self:FxRing(x, y - c.H / 2 + 10, STORM_PALE, 760, 0.6, 0.6, 0.02, "Shock", 0.3)
	if rv.streaks then
		rv.streaks:Burst(x, y, STORM_PALE, 34, 560, 0.6, 40, 0.8)
		rv.sparks:Burst(x, y, STORM, 26, 300, 0.9, 20)
		rv.stars:Burst(x, y, WHITE, 10, 220, 1.0, 22)
	end
	self:FxShake(0.45, 11)
	c:Strike()
end

-- Titanforged: the light of a prism goes through it: a white light, bursting out of it in all the colours; behind it,
-- wheels of rays of the rainbow that turn and stay; a pillar of white light edged with blue and rose; waves of each
-- colour one after the other; shards of crystal and stars of every colour; motes rising; its colours go once round the
-- rainbow, bright.
function CR:PrismStrike()
	local rv = self.frame.reveal
	local x, y = self.cardX or 0, self.cardY or 0
	local c = rv.card
	self:FxFlash(PEARL, 0.55, 0.7)
	self:FxEdge(PEARL, 0.6, 1.5)
	local fl = rv.prismFlash
	local turn = (math.random() - 0.5) * 0.5
	fl:ClearAllPoints()
	fl:SetPoint("CENTER", rv.fx, "CENTER", x, y)
	ns.Tween(0.95, function(e, raw)
		local d = c.H * (1.2 + 2.4 * e)
		CuratorOctoFull.SetSize(fl, d, d)
		CuratorOctoFull.SetRotation(fl, turn * raw)
		fl:SetAlpha((raw < 0.08) and (raw / 0.08) or (1 - raw) ^ 1.6)
	end, function()
		fl:SetAlpha(0)
	end, Ease.outCubic, rv.fx)
	rv.prism = { size = c.H * 2.6, k = 0.55, ang = math.random() * 6.28, spin = 0.16 }
	for i, t in ipairs(rv.prismRays) do
		local i, t = i, t; t:SetVertexColor(1, 1, 1)
		local to = (i == 1) and 1 or 0.75
		ns.Tween(0.35, function(e)
			t:SetAlpha(to * e)
		end, nil, Ease.outQuad, rv.fx)
		-- (then they stay, softer, as long as the card is there)
		ns.Tween(1.6, function(e)
			t:SetAlpha(to * (1 - 0.5 * e))
		end, nil, Ease.inOutQuad, rv.fx, 3.2)
	end
	local foot = y - c.H * 0.45
	self:FxBeam(1, x, foot, PEARL, 300, 1400, 1.5, 1)
	self:FxBeam(2, x - 26, foot, CYAN, 220, 1250, 1.6, 0.55)
	self:FxBeam(3, x + 26, foot, ROSE, 220, 1250, 1.6, 0.55)
	for i, col in ipairs(SPECTRUM) do
		self:FxRing(x, y, col, 560 + 70 * i, 0.85, 0.7, 0.035 * (i - 1), "Shock")
	end
	self:FxRing(x, y, WHITE, 1250, 1.0, 0.45, 0.1, "Shock")
	self:FxRing(x, y - c.H * 0.5, PEARL, 1050, 0.8, 0.55, 0.02, "Shock", 0.3)
	self:FxSpikes(x, y, PEARL, 980, 0.7, 0.9)
	self:FxFlare(x, y, PEARL, 1400, 0.7, 0.9)
	if rv.shards then
		for _, col in ipairs(SPECTRUM) do
			rv.shards:Burst(x, y, col, 3, 560, 1.15, 34, 1, 0.7)
			rv.stars:Burst(x, y, col, 2, 300, 1.1, 22)
		end
		rv.streaks:Burst(x, y, PEARL, 30, 620, 0.7, 40, 0.8)
		rv.stars:Burst(x, y, WHITE, 8, 220, 1.0, 22)
		ns.Delay(0.24, function()
			self:FxRing(x, y, PEARL, 520, 0.5, 0.6, 0, "Shock")
			for i = 1, CuratorOctoFull.Length(SPECTRUM), 2 do
				rv.shards:Burst(x, y, SPECTRUM[i], 1, 380, 1.0, 26, 1, 0.6)
			end
			rv.stars:Burst(x, y, PEARL, 6, 200, 0.9, 20)
		end, rv.fx)
		for k = 0, 2 do
			local k = k; ns.Delay(0.15 + 0.35 * k, function()
				for i = 1 + k, CuratorOctoFull.Length(SPECTRUM), 3 do
					rv.motes:Rise(x - c.W * 0.7, x + c.W * 0.7, y - c.H * 0.5, SPECTRUM[i], 4, 300, 2.2, 14)
				end
			end, rv.fx)
		end
	end
	self:FxShake(0.4, 8)
	c:Flourish()
	c:Sweep(1.2)
end

-- The cards of the band as they were before it stopped: none lit, none dimmed.
function CR:ResetBand()
	for _, t in ipairs(self.frame.tiles) do
		t:SetAlpha(1)
		t.face:SetScale(1)
		t.face:SetAlpha(1)
		t.glow:SetAlpha(0)
	end
end

-- Everything that runs stopped (the scene closed, a new case): its moves, its lights, the band as it stands.
function CR:Stop()
	ns.CancelOwner(self)
	self:ClearBatch()
	self.spinning = false
	self.lidOpen = nil
	local f = self.frame
	if not f then
		return
	end
	self:ResetBand()
	f.reveal:Hide()
	f.reveal:SetAlpha(1)
	-- (an entrance cut short: its weapon gone, its lights back over the card; a film, stopped, its sound with it)
	self.entering = nil
	if ns.CaseFilm then
		ns.CaseFilm:Stop()
	end
	if f.arm then
		ns.CrateCard.Arm(f.arm, nil)
	end
	local rv = f.reveal
	for _, t in ipairs({ rv.flash, rv.ring }) do
		t:ClearAllPoints()
		t:SetPoint("CENTER", rv, "CENTER", self.cardX or 0, self.cardY or 0)
	end
end

-- (1.14.0) A case found, a key bought, a case opened, rubies earned or spent: the case shown for real painted again,
-- while it waits.
for _, e in ipairs({ "CASES_CHANGED", "RUBIES_CHANGED" }) do
	local _, e = _, e; ns.On(e, function()
		local f = CR.frame
		local st = CR.state
		if f and f:IsShown() and CR.real and (st == "case" or st == "shutting" or st == "falling" or st == "vanishing") then
			-- (a case found while its ghost waits there: it falls)
			if st ~= "falling" and st ~= "vanishing" and f.case.ghost and not CR:IsGhost() then
				return CR:ShowCase("fall")
			end
			-- (while one falls or goes: its words now, its buttons still off until it rests)
			CR:PaintReal()
		end
	end)
end

-- (1.14.0) The alert of a case found (Cases.lua): its name, how many there are to open and their keys (a reroll: in its
-- chest); a click shows it.
ns.On("CASE_DROPPED", function(case, n, how, chest)
	local CS, T = ns.Cases, ns.Toast
	local def = ns.Crates and ns.Crates[case]
	if not (CS and T and def) then
		return
	end
	n = tonumber(n) or 1
	local RR = ns.Reroll
	local line
	if chest then
		line = string.format(L["In this character's chest: it opens at level %d."], RR and RR.LEVEL or 15)
	else
		line = string.format(L["Cases to open: %d  ·  Keys: %d"], CS:Count(case), CS:Keys(case))
	end
	local art = def.art and def.art.box
	T:Push({
		title = n > 1 and string.format(L["Cases found: %d"], n) or L["A case!"],
		name = L[def.title or "Test case"],
		color = { 1, 0.84, 0.26 },
		line = line,
		tex = { art and (art .. "Top") or "CrateTop", { 0.209, 0.791, 0, 0.582 } },
		sound = ns.SND.packDrop,
		onClick = function()
			if chest then
				if ns.RerollUI and ns.RerollUI.ShowChest then
					ns.RerollUI:ShowChest()
				end
			else
				CR:Show(case)
			end
		end,
	})
end)

local BATCH_SPEED = 5

function CR:StartBatch(count)
    if not self.real or self.batch or not self.frame or not self.frame:IsShown()
        or self.state ~= "case" or not ns.Cases then
        return
    end
    if count > ns.Cases:Openable(self.real) then
        self:PaintReal()
        return
    end
    self.batch = { total = count, opened = 0 }
    ns.SetTimeScale(self, BATCH_SPEED)
    self:Open()
end

function CR:PaintBatch()
    local batch = self.batch
    local status = self.frame.batchStatus
    CuratorOctoFull.SetShown(status, batch ~= nil)
    if batch then
        status:SetText(string.format(L["Cases opened: %d / %d"], batch.opened, batch.total))
    end
end

function CR:ClearBatch()
    if not self.batch then
        return
    end
    self.batch = nil
    ns.SetTimeScale(self, 1)
    self:PaintBatch()
end

function CR:AdvanceBatch()
    local batch = self.batch
    if not batch or batch.opened >= batch.total then
        if batch then ns.SetTimeScale(self, 1) end
        return false
    end
    -- Leave each reward on screen briefly before the next case begins.
    ns.Delay(1.6, function()
        batch.advance = true
        self:Back()
    end, self)
    return true
end

function CR:ContinueBatch()
    local batch = self.batch
    if batch and batch.advance then
        batch.advance = nil
        -- Let the case settle and the panel reappear before opening it.
        ns.Delay(0.45, function()
            if self.batch == batch then self:Open() end
        end, self)
    end
end
