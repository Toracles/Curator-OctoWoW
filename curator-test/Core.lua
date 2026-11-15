local ADDON, ns = "Curator", CuratorOctoFull
-- (1.7.0) Nothing of the addon in the globals of the game: what a /run typed in the chat could reach
-- (the collection, what adds to it) stays out of its way. The save itself is hidden while the game
-- runs (Core.lua, ADDON_LOADED and PLAYER_LOGOUT).

ns.name = ADDON
ns.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "1.6.0"
ns.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

-- (1.14.0, his word: the words of the case in each language) A texture of the addon with words on it (a case of the
-- month: its front, its lid, the back of its cards), in the language of the game: its name with the suffix of that
-- language when there is one (ns.CaseWords, Data/Crate*.lua: [name] = { [locale] = suffix }; enUS for any language but
-- French, whose words are those of the texture itself). Any other name as it is.
function ns.CaseTexture(name)
	local w = type(name) == "string" and ns.CaseWords and ns.CaseWords[name]
	if not w then
		return name
	end
	local sfx = w[ns.locale or "enUS"]
	if sfx == nil and ns.locale ~= "frFR" then
		sfx = w.enUS
	end
	return sfx and (name .. sfx) or name
end

-- Card rarities. text: label color on dark backgrounds (WoW item quality colors), ink: on the
-- parchment of the card, frame: accent color (banners, counters), glow: light effects.
-- The card frames are iron, bronze, silver, gold, radiant gold and, for the mythic cards (one per
-- album), crimson set with radiant gold and rubies.
ns.RARITY = {
	{ key = "common", label = "Common", text = { 0.92, 0.92, 0.95 }, ink = { 0.30, 0.28, 0.26 }, frame = { 0.80, 0.82, 0.87 }, glow = { 0.85, 0.88, 1.00 } },
	{ key = "uncommon", label = "Uncommon", text = { 0.12, 1.00, 0.00 }, ink = { 0.08, 0.42, 0.07 }, frame = { 0.36, 0.95, 0.36 }, glow = { 0.30, 1.00, 0.30 } },
	{ key = "rare", label = "Rare", text = { 0.25, 0.58, 1.00 }, ink = { 0.08, 0.31, 0.68 }, frame = { 0.32, 0.62, 1.00 }, glow = { 0.32, 0.64, 1.00 } },
	{ key = "epic", label = "Epic", text = { 0.70, 0.35, 1.00 }, ink = { 0.42, 0.14, 0.64 }, frame = { 0.78, 0.44, 1.00 }, glow = { 0.70, 0.30, 1.00 } },
	{ key = "legendary", label = "Legendary", text = { 1.00, 0.55, 0.10 }, ink = { 0.66, 0.33, 0.00 }, frame = { 1.00, 0.70, 0.24 }, glow = { 1.00, 0.55, 0.10 } },
	{ key = "mythic", label = "Mythic", text = { 1.00, 0.30, 0.42 }, ink = { 0.62, 0.05, 0.14 }, frame = { 1.00, 0.42, 0.50 }, glow = { 1.00, 0.22, 0.32 } },
}
ns.MYTHIC = CuratorOctoFull.Length(ns.RARITY)

-- Sounds (sound kit ids). Classic era sounds first, newer ones fall back on them.
ns.SND = {
	packShake = { 1161 },               -- crinkling paper
	packOpen = { 64329, 1161 },         -- unwrap
	packDrop = { 1201 },                -- the pack lands (a book put down)
	packTear = { 2580, 1161 },          -- its wrapping torn off (a gift unwrapped)
	-- the light of the pack climbs a colour (holy impacts, from low to uber; green: gems picked up)
	tell = { [2] = { 1221 }, [3] = { 1270 }, [4] = { 1516 }, [5] = { 1272 }, [6] = { 1273 } },
	-- the pack bursts: paper torn, a bind, an arcane explosion, a thunder clap, an infernal falling
	burst = { [1] = { 1161 }, [2] = { 3961, 1161 }, [3] = { 3961, 1516 }, [4] = { 6539, 1516 }, [5] = { 3090, 6539 }, [6] = { 7315, 3090 } },
	whoosh = { 7080 },                  -- the cards fly out of the pack
	rumble = { 1485 },                  -- the ground shakes before a legendary or mythic card
	crackle = { 1506 },                 -- red lightning (mythic)
	-- a card of the best rarities turned over: the blow under its fanfare
	impact = { [4] = { 6539 }, [5] = { 3090 }, [6] = { 7315, 3090 } },
	tick = { 1221 },                    -- the album fills up (gems picked up)
	cardLand = { 1209 },                -- put down paper
	cardFlip = { 1192 },                -- pick up paper
	hover = { [2] = { 832 }, [3] = { 1204 }, [4] = { 740 }, [5] = { 741 }, [6] = { 741 } },
	reveal = { [2] = { 1221 }, [3] = { 1516, 1430 }, [4] = { 31578, 619 }, [5] = { 63971, 888 }, [6] = { 63971, 888 } },
	gong = { 12827, 4654 },             -- the troll gong, with the mythic cards
	charge = { 742 },                   -- precast holy high
	shiny = { 1642, 1221 },
	holo = { 8473, 1642 },              -- reputation level up chime
	-- the forged finishes of the dungeons and the raids: lightning and its thunder; the chest of the
	-- titans opening
	thunder = { 1483, 1506 },
	thunderRoll = { 3090 },
	-- (1.14.0, his word: no stone at a titanforged card, the sounds of the game only) the toast of a warforged item of
	-- the game (UI_WARFORGED_ITEM_LOOT_TOAST), else of a legendary one, else the level up; the chest of the titans
	-- opening before (4782)
	titan = { 51561, 63971, 888 },
	-- the forge of the titans (a titanforged card turned over): their music, their halls waking, their
	-- lightning, the blows of their forge, the stone shaking, their bolt, their fanfare
	titanMusic = { 15873, 5334 },         -- the theme of the titans of Ulduar (the intro of Ironforge)
	titanWake = { 12906, 11982 },         -- the energy of their halls (1.14.0: the chest of the titans opening, 4782, no more)
	titanBolt = { 13021, 10824, 1506 },   -- lightning strikes
	titanBolt2 = { 8439, 10008, 1483 },
	forgeBlow = { 13990, 930 },           -- the press of their forge (a colossal stone falling)
	forgeQuake = { 15395, 3090 },         -- the stone shaking (a thunder clap)
	forgeLast = { 15408, 7315 },          -- a shock wave
	titanStrike = { 10014, 1273 },        -- a blow of holy light
	titanFanfare = { 51561, 63971, 888 }, -- the fanfare of a titanforged item
	-- the boosters of the dungeons and the raids: their chains, the seal that breaks
	chains = { 1206, 1188 },
	chainSnap = { 1502, 1206 },
	chainHang = { 3400 },
	sealBreak = { 6533, 6488 },
	-- ... and the way each place destroys it: fire, ooze, an explosion, a crash, claws
	ignite = { 1484 },
	melt = { 6764, 3541 },
	blast = { 4100, 6765 },
	shatter = { 6488, 6533 },
	slash = { 46, 3264 },
	-- the dark echo of the light of a sealed pack climbing a colour
	tellDark = { [3] = { 3085 }, [4] = { 1517 }, [5] = { 3231 }, [6] = { 5694 } },
	contract = { 1192 },                -- the parchment unrolls
	ink = { 832 },                      -- a card goes into the contract
	seal = { 1201 },                    -- the seal comes down
	burn = { 1401 },                    -- the contract vanishes (a scroll evaporates)
	ach = { 12891, 31578, 888 },        -- an achievement earned (achievement fanfare, epic loot, level up)
	questDone = { 73277, 878 },         -- a quest of the collector done (a world quest, a quest complete)
	levelUp = { 888 },                  -- a level of collector gained (the level up of the game)
	xpTick = { 1221 },                  -- the experience of a booster fills its bar
	-- the rewards claimed: a box opened, coins; the light of the experience flying to its bar and
	-- landing in it; the stamp on a quest claimed; a booster put in its album
	claim = { 64329, 120 },
	coins = { 120 },
	orb = { 7080 },
	orbHit = { 1270, 1221 },
	stamp = { 1201 },
	place = { 1201 },
	-- a level, a new rank: the fanfare of a legendary item over the level up of the game
	levelSting = { 31578, 888 },
	rankUp = { 63971, 31578, 888 },
	click = { 856 },
	page = { 836 },
	open = { 829 },
	close = { 830 },
	warning = { 8959, 830 },            -- a mandatory update (1.4): the raid warning
	-- (1.12.0) Hallow's End: a treat (a quest complete), bats flying off (a swarm of them, the cry of a duskbat), the
	-- wail of a banshee
	hallowTreat = { 878 },
	hallowBats = { 6526, 3369, 1221 },
	hallowWail = { 1171, 3417 },
	-- (1.12.0, as in Curator Midnight) a corrupted card turned over: the toast of a corrupted item of 8.3, the eye of
	-- N'Zoth
	corruptLoot = { 147833, 3085 },
	nzothEye = { 146824 },
}

local function playOne(id)
	if not id or id <= 0 then
		return false
	end
	-- (1.11.0: the sounds of Curator off, in its options)
	if ns.db and ns.db.mute then
		return false
	end
	local ok, willPlay, handle = pcall(PlaySound, id, "SFX")
	if ok and willPlay ~= false then
		return true, handle
	end
	return false
end

-- Plays the first sound of the list the client can play. Returns true and the sound handle.
function ns.Play(list)
	-- (1.14.0, a player's word: pages turned fast, an arrow held or Shift-clicked, UI/Skin.lua: one sound now and then)
	if ns.quietTurn then
		return false
	end
	if type(list) == "number" then
		return playOne(list)
	end
	if type(list) ~= "table" then
		return false
	end
	for _, id in ipairs(list) do
		local ok, handle = playOne(id)
		if ok then
			return true, handle
		end
	end
	return false
end

-- Same, for sounds made to loop (spell precast): stopped after the given time.
function ns.PlayFor(list, seconds, owner)
	local ok, handle = ns.Play(list)
	if ok and handle and StopSound then
		ns.Delay(seconds, function()
			StopSound(handle, 300)
		end, owner)
	end
end

function ns.Print(msg, ...)
	if CuratorOctoFull.Select("#", unpack(arg, 1, arg.n)) > 0 then
		msg = string.format(msg, unpack(arg, 1, arg.n))
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cffe8c26a" .. ADDON .. "|r " .. msg)
end

-- "12 345": the thousands apart, as the language writes them.
function ns.Num(n)
	n = math.floor(tonumber(n) or 0)
	local digits = tostring(math.abs(n))
	local sep = ns.L[","]
	local out = ""
	while CuratorOctoFull.Length(digits) > 3 do
		out = sep .. string.sub(digits, -3) .. out
		digits = string.sub(digits, 1, -4)
	end
	return (n < 0 and "-" or "") .. digits .. out
end

-- "0,3 %", "90,2 %": a chance (0 to 1) as the language writes it, with the decimals it needs.
function ns.Pct(p)
	local v = (tonumber(p) or 0) * 100
	local s = string.format((v >= 1 and "%.1f" or "%.2f"), v)
	s = string.gsub(string.gsub(s, "0+$", ""), "%.$", "")
	s = string.gsub(s, "%.", ns.L["."])
	return string.format(ns.L["%s%%"], s)
end

-- "5 h 12 min", "3 d 4 h", "12 min".
function ns.Duration(sec)
	local L = ns.L
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local d, h, m = math.floor(sec / 86400), math.floor(CuratorOctoFull.Mod(sec , 86400) / 3600), math.floor(CuratorOctoFull.Mod(sec , 3600) / 60)
	if d > 0 then
		return string.format(L["%d d %d h"], d, h)
	elseif h > 0 then
		return string.format(L["%d h %d min"], h, m)
	end
	return string.format(L["%d min"], math.max(1, m))
end

-- (1.12.0) The languages Curator can be shown in, besides the game's (Options: its language): those of the
-- Latin letters, which the fonts of every client have, and the language of the game itself.
ns.LATIN_LANGS = { "enUS", "frFR", "deDE", "esES", "ptBR" }

function ns.LangChoices()
	local client = GetLocale and GetLocale() or "enUS"
	if client == "enGB" then
		client = "enUS"
	elseif client == "esMX" then
		client = "esES"
	end
	local out, seen = {}, {}
	for _, l in ipairs(ns.LATIN_LANGS) do
		out[CuratorOctoFull.Length(out) + 1], seen[l] = l, true
	end
	if not seen[client] and ns.LocaleTables and ns.LocaleTables[client] then
		out[CuratorOctoFull.Length(out) + 1] = client
	end
	return out
end

-- (1.12.0) The language chosen for Curator, when it is not the game's: its words and the names of its cards.
-- (At the load of the save, before any window is made; changed in the options, it takes after a reload.)
function ns.ApplyLanguage()
	local db = ns.db
	local want = db and db.lang
	if type(want) ~= "string" then
		return
	end
	for _, l in ipairs(ns.LangChoices()) do
		if l == want then
			if want ~= ns.locale then
				ns.SetLocale(want)
			end
			return
		end
	end
	db.lang = nil
end

-- Font file of the client language (CJK and Cyrillic clients use other files).
function ns.SetFont(fs, size, flags)
	local file = GameFontNormal and GameFontNormal.GetFont and GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF"
	fs:SetFont(file or "Fonts\\FRIZQT__.TTF", size, flags or "")
end

-------------------------------------------------------------------------------
-- Saved data
-------------------------------------------------------------------------------
-- (1.14.0, his word: no booster of welcome, neither for a new collection nor after a reset; the booster bar gives the
-- first ones)

local DEFAULTS = {
	version = 3,
	cards = {},      -- [cardKey] = { n = copies, s = shiny copies, h = holographic copies, t = first server time }
	packs = {},      -- [seriesKey] = unopened boosters
	bar = 0,         -- the points of the booster bar toward the next booster (ns.PACK_POINTS for one: Rewards.lua)
	dbar = 0,        -- (1.4.1) the points of the bar of the dungeons and the raids
	opened = 0,
	welcomed = false,
	announce = true, -- share the best pulls with the guild
	guild = {},      -- what guild members shared: [name] = { t = time, s = { [series] = summary }, c = { [series] = collection } }
	minimap = { angle = 200 }, -- the button around the minimap (hide = true: no button)
	keepOne = true,  -- contracts leave one copy of each card in the album
	contracts = 0,   -- contracts signed
	ach = {},        -- achievements earned: [id] = server time
	stats = {},      -- for the achievements (see ns.Stats)
	met = {},        -- what other players met showed: [name] = { t, i = profile, s = summaries, c = albums }
	visited = {},    -- [seriesKey] = true: the places one of the characters has been to
	farm = {},       -- [dungeonKey] = seriesKey: the album that gets the boosters earned in that dungeon
	chars = {},      -- [name] = { quests, obj, skills }: what each character did (see Rewards.lua)
	cinematic = true, -- the entrance of the legendary and mythic cards (UI/Cinematic.lua)
	showcase = {},   -- the cards pinned to the showcase of the profile, in their order (card keys)
	history = {},    -- the finest pulls (the record of the profile): { k = card key, f = finish, t = server time, s = how }
	journal = {},    -- (1.7.0) each card worth it that came, when and how: one line each (Collection.lua)
	live = true,     -- the boosters the guild opens, shown live (UI/Live.lua)
	xp = 0,          -- the experience of the collector (its level: Level.lua)
	choice = {},     -- the boosters to choose: [kind] = how many ("zone", "dungeon", "raid")
	dropped = {},    -- [seriesKey] = true: the albums boosters have come for
	quests = {},     -- the quests of the day, the week and the month (Quests.lua)
	achClaimed = {}, -- the rewards of the achievements claimed: [id] = server time
	fresh = {},      -- the cards new in the album, not yet seen there: [cardKey] = true
	trades = {},     -- the trades with other players: [id] = trade (Trade.lua)
	wish = {},       -- the cards looked for: [cardKey] = server time
	held = {},       -- [seriesKey] = boosters that came in trades not confirmed yet (they wait)
	oldPacksGone = false, -- the boosters kept from before 1.2 taken away (1.2.1: once, see ADDON_LOADED)
	strangers = true, -- offers of trades from players I do not know are welcome
	inns = {},       -- (1.8.0) the loyalty card, the travel passport, the loyalty of the innkeepers (Inns.lua)
	-- (1.8.0: pvp, the trophies of PvP, the cards of the combatants, the war board; 1.14.0, his word: gone until the rework
	-- of the PvP, Pvp.lua)
	rubies = 0,      -- (1.11.0) the rubies of the collector (Rubies.lua)
	ruby = {},       -- (1.11.0) the boosters bought with them this week, the catch-up of 1.11.0 (Rubies.lua)
}

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			if type(v) == "table" then
				dst[k] = {}
				CopyDefaults(dst[k], v)
			else
				dst[k] = v
			end
		end
	end
end

-- Counters of the achievements: cards found on creatures (on bosses), dungeons and raids completed
-- ([series] = times), players whose collection was viewed ([name] = true), and the feats.
function ns.Stats()
	local db = ns.db
	db.stats = db.stats or {}
	local st = db.stats
	st.found = st.found or 0
	st.bossFound = st.bossFound or 0
	st.done = st.done or {}
	st.seen = st.seen or {}
	return st
end

-------------------------------------------------------------------------------
-- The seal of the save: written when the game saves (logout, reload), checked when it loads. A
-- save edited outside the game no longer matches it, and the collection shows to the other
-- players as edited. (This code can be read: it stops the edits, not a determined cheater.)
-- (1.7.0) The launcher of Curator makes this seal again, the same way, as soon as the save changes
-- (launcher/src/core/save.ts). It checks the saves whose way of sealing it knows (db.sealv, written
-- with the seal): the salt, UNSEALED or what is hashed changed here, or what the launcher reads of the
-- save to check its code (cid, exportAt, edited, test, xp, opened, contracts, stats.found and
-- bossFound, the n, s, h of the cards, ach), SEAL_V goes up by one and the launcher learns the new way
-- before it checks those saves. The keys are hashed in the order of their bytes (1.7.0), the same
-- whatever the language of the game, and the launcher's; a seal of before, made in the order of the
-- game, is still good when its save is loaded.
-------------------------------------------------------------------------------
local SALT = "Hoard seal 1"
local SEAL_V = 2

local function Hash(str)
	local a, b = 5381, 52711
	for i = 1, CuratorOctoFull.Length(str) do
		local c = CuratorOctoFull.Byte(str, i)
		a = CuratorOctoFull.Mod((a * 33 + c) , 2147483647)
		b = CuratorOctoFull.Mod((b * 31 + c * 7 + 3) , 2147483629)
	end
	return string.format(("%08x%08x"), a, b)
end

-- The order of the game (the seals of before 1.7.0).
local function ByName(a, b)
	return tostring(a) < tostring(b)
end

-- The order of the bytes.
local function ByBytes(a, b)
	a, b = tostring(a), tostring(b)
	for i = 1, math.min(CuratorOctoFull.Length(a), CuratorOctoFull.Length(b)) do
		local x, y = CuratorOctoFull.Byte(a, i), CuratorOctoFull.Byte(b, i)
		if x ~= y then
			return x < y
		end
	end
	return CuratorOctoFull.Length(a) < CuratorOctoFull.Length(b)
end

local function Sorted(t, less)
	local keys = {}
	for k in pairs(t) do
		keys[CuratorOctoFull.Length(keys) + 1] = k
	end
	table.sort(keys, less)
	return keys
end

local function Flat(t, less)
	local out = {}
	for _, k in ipairs(Sorted(t, less)) do
		local v = t[k]
		if type(v) == "table" then
			v = "{" .. Flat(v, less) .. "}"
		end
		out[CuratorOctoFull.Length(out) + 1] = tostring(k) .. "=" .. tostring(v)
	end
	return table.concat(out, ",")
end

-- What is not sealed: the seal, what other players showed, and the settings. Everything else is.
-- (1.1: compact, compactAt, compactW: the boosters in a small window, where it is and how wide; tour:
-- the guided tour of the album was seen; 1.2: barAt, barHide: where the booster bar was moved, hidden)
local UNSEALED = { seal = true, guild = true, met = true, minimap = true, announce = true, keepOne = true,
	plain = true, cam = true, zoom = true, version = true, farm = true, cinematic = true, entrances = true, fresh = true,
	strangers = true, presence = true, seen = true, scan = true, scanRef = true, scanMap = true,
	compact = true, compactAt = true, compactW = true, tour = true, barAt = true, barHide = true, barWidth = true }
-- (scanRef, scanMap: left by a tool of the admin build of 0.23.2, out of the seal for good)

-- The seal of a collection (the keys in the order of their bytes; old: in the order of the game, as
-- before 1.7.0).
function ns.Seal(db, old)
	local less = old and ByName or ByBytes
	local parts = { SALT }
	for _, field in ipairs(Sorted(db, less)) do
		local v = db[field]
		if UNSEALED[field] then
			-- left out
		elseif field == "cards" and type(v) == "table" then
			for _, k in ipairs(Sorted(v, less)) do
				local e = v[k]
				if type(e) == "table" then
					parts[CuratorOctoFull.Length(parts) + 1] = tostring(k) .. ":" .. tostring(e.n or 0) .. ":" .. tostring(e.s or 0) .. ":" .. tostring(e.h or 0)
				end
			end
		elseif type(v) == "table" then
			parts[CuratorOctoFull.Length(parts) + 1] = tostring(field) .. "{" .. Flat(v, less) .. "}"
		else
			parts[CuratorOctoFull.Length(parts) + 1] = tostring(field) .. "=" .. tostring(v)
		end
	end
	return Hash(table.concat(parts, ";"))
end

-- (1.14.1) A number that is not whole, as OctoWoW writes it: 16 digits, not all those it holds
-- (0.04316672109740049... is written 0.0431667210974005). Read back, it is another number, and its 14
-- digits (tostring, what the seal reads) may be other ones when it lay on the edge between two: the seal
-- no longer matched, and the save was taken for one edited outside the game (Lodging.lua: the rest and
-- the dish of the inns, counted in fractions of seconds). So at the logout, before the seal, every number
-- of the sealed part that is not whole is kept to 12 digits: written and read back, the seal reads the
-- same digits in it. (A number that is not a number, or infinite, the game cannot write back: 0.)
local SHORT = "%.12g"

local function Short(v)
	if v ~= v or v == CuratorOctoFull.Huge or v == -CuratorOctoFull.Huge then
		return 0
	end
	if v == math.floor(v) then
		return v
	end
	return tonumber(string.format(SHORT, v)) or 0
end

-- Every number of the sealed part kept short (Short), in its place.
local function Steady(db)
	local seen = {}
	local function walk(t, top, depth)
		if seen[t] or depth > 60 then
			return
		end
		seen[t] = true
		for k, v in pairs(t) do
			if not (top and UNSEALED[k]) then
				if type(v) == "number" then
					local s = Short(v)
					if s ~= v then
						t[k] = s
					end
				elseif type(v) == "table" then
					walk(v, false, depth + 1)
				end
			end
		end
	end
	walk(db, true, 0)
end

-- (1.14.1) The numbers of the sealed part of a save written before 1.14.1 that lay on the edge of two
-- ways of reading them in 14 digits: the game may have written either one way's number (each: the table
-- that holds it, its key, the number read, one under the edge and one over it).
local function Edges(db)
	local out, seen = {}, {}
	local function walk(t, top, depth)
		if seen[t] or depth > 60 then
			return
		end
		seen[t] = true
		for k, v in pairs(t) do
			if not (top and UNSEALED[k]) then
				if type(v) == "number" then
					if v == v and v ~= CuratorOctoFull.Huge and v ~= -CuratorOctoFull.Huge and v ~= math.floor(v) then
						local e = math.abs(v) * 1e-15
						if tostring(v - e) ~= tostring(v + e) then
							out[CuratorOctoFull.Length(out) + 1] = { t = t, k = k, v = v, lo = v - e, hi = v + e }
						end
					end
				elseif type(v) == "table" then
					walk(v, false, depth + 1)
				end
			end
		end
	end
	walk(db, true, 0)
	return out
end
-- (the most numbers on an edge tried each way: 2^5 seals at most)
local EDGES = 5

-- The game saves now: the seal goes with what it saves (and the way it was made, for the launcher).
-- (1.14.1) Its numbers kept short first (Short): the game writes and reads back the ones the seal read.
function ns.SealNow(db)
	Steady(db)
	db.sealv = SEAL_V
	db.seal = ns.Seal(db)
end

-- A save that does not match its seal, or that lost it. A seal of before 1.7.0 matches in the order of
-- the game. (1.9.1) The game writes no save without its seal (every one since 0.9 carries it, from the
-- first logout): a save that holds anything without it had it taken out, even with all that 0.9 adds,
-- to pass for a save of before. Only an empty one is new.
-- (1.14.1) A save written before 1.14.1 whose numbers on an edge (Edges) match its seal read one way or
-- the other was never edited: the game wrote them so. It is sealed again at the next logout, kept short.
function ns.Tampered(db)
	if type(db) ~= "table" then
		return false
	end
	if type(db.seal) == "string" then
		if db.seal == ns.Seal(db) or db.seal == ns.Seal(db, true) then
			return false
		end
		local edges = Edges(db)
		if CuratorOctoFull.Length(edges) == 0 or CuratorOctoFull.Length(edges) > EDGES then
			return true
		end
		local found = false
		for mask = 0, 2 ^ CuratorOctoFull.Length(edges) - 1 do
			local m = mask
			for _, e in ipairs(edges) do
				e.t[e.k] = (CuratorOctoFull.Mod(m , 2) == 1) and e.hi or e.lo
				m = math.floor(m / 2)
			end
			if ns.Seal(db) == db.seal then
				found = true
				break
			end
		end
		for _, e in ipairs(edges) do
			e.t[e.k] = e.v
		end
		return not found
	end
	return next(db) ~= nil
end

-- Empties a collection: its cards, its level, its achievements, its showcase and its finest pulls.
-- full: everything it earned with them too (its boosters, what the places and the characters gave,
-- the boosters to choose, the quests, the trades): it starts over as a new one. The achievement of
-- the testers of the beta stays (its reward waits again: the level starts over).
function ns.EmptyCollection(db, full)
	CuratorOctoFull.Wipe(db.cards)
	if full then
		CuratorOctoFull.Wipe(db.packs)
		db.bar, db.dbar = 0, 0
		CuratorOctoFull.Wipe(db.visited)
		CuratorOctoFull.Wipe(db.farm)
		CuratorOctoFull.Wipe(db.chars)
		CuratorOctoFull.Wipe(db.choice)
		CuratorOctoFull.Wipe(db.quests)
		CuratorOctoFull.Wipe(db.dropped)
		-- (1.14.0: the rewards to choose waiting go with the boosters to choose they replace)
		if type(db.offers) == "table" then
			CuratorOctoFull.Wipe(db.offers)
		end
		db.welcomePacks, db.boosters = nil, nil
	end
	-- (the achievements Beta tester and Pioneer stay, but not on a save edited outside the game: their
	-- marks may have been written there)
	local beta = db.ach and db.ach.beta
	local pioneer = db.ach and db.ach.pioneer
	if db.edited then
		beta, db.beta = nil, nil
		pioneer, db.pioneer = nil, nil
	end
	db.xp = 0
	db.levelClaims = {}
	db.opened, db.contracts = 0, 0
	db.ach, db.stats, db.achClaimed = {}, {}, {}
	-- (1.14.0: the experience the albums complete gave, kept with their achievements, goes with them: Achievements.lua)
	db.achXP = nil
	db.ach.beta = beta
	db.ach.pioneer = pioneer
	-- (1.6.0: the talents go with the level; the reconversions made stay)
	local t = db.talents
	if type(t) == "table" then
		db.talents = { respecs = t.respecs, respecAt = t.respecAt }
	end
	if ns.Talents then
		ns.Talents.pending = nil
	end
	CuratorOctoFull.Wipe(db.fresh)
	CuratorOctoFull.Wipe(db.showcase)
	CuratorOctoFull.Wipe(db.history)
	-- (1.8.0: the signed cards of the innkeepers go with the cards; the rest of the inns with what the
	-- places gave)
	if ns.Inns then
		ns.Inns:Empty(full)
	end
	-- (1.8.0: the cards of the combatants go with the cards, the rest of the PvP with the rest; 1.14.0: what the PvP of
	-- before kept, all of it, Pvp.lua)
	db.pvp = nil
	-- (1.8.0: the duels with a stake go: their stakes went with the cards; 1.14.0: gone with the PvP)
	db.duels = nil
	-- (1.10.0: the golden quest under way and the golden boosters waiting go with what the places gave; the week
	-- a golden quest was turned in stays: no second one that week)
	if full and type(db.golden) == "table" then
		db.golden = { doneWeek = db.golden.doneWeek }
	end
	-- (1.14.0: the main goes with the characters, their chests with them; the release of OctoWoW stays gone
	-- through: Reroll.lua)
	if full then
		db.main = nil
	end
	-- (1.7.0: its journal goes with it, and for the website it is a new collection: a new id)
	db.journal = {}
	db.cid = nil
	db.test, db.edited, db.editedWhy = nil, nil, nil
	-- (1.11.0: the rubies go with the levels and the achievements they came from: Rubies.lua; the cards
	-- appraised with the cards: Expertise.lua)
	ns.Fire("COLLECTION_EMPTIED", db, full)
end

-- The collection emptied (/curator reset confirm; the button of the window of a suspended Curator). (1.14.0, his
-- word: it starts over from zero, as a new one, every collection; before, only a test or edited one, the others keeping
-- their boosters, their bars, their cases, their rewards to choose.) Its cards, its boosters to open and its bars, its
-- rewards to choose, its displays, its cases and their cards, its albums unlocked, its level, its achievements, its
-- rubies, its talents, its quests, its trades, its characters and their chests: all go (Reroll.lua: RR:EmptyRest, as
-- at the release of OctoWoW); the achievements Beta tester and Pioneer stay (not on a save edited outside the
-- game), the gift codes taken stay taken, the release stays gone through; the boosters of welcome of a new collection
-- come again at the next login. An edited one was suspended (Beta.lua): Curator works again.
function ns.ResetCollection()
	local db = ns.db
	if not db then
		return
	end
	local suspended = db.edited and true or false
	ns.EmptyCollection(db, true)
	if ns.Reroll and ns.Reroll.EmptyRest then
		ns.Reroll:EmptyRest(db)
	end
	db.title = nil
	db.welcomed, db.welcomePacks = false, nil
	-- (1.14.0, later: started over on a realm of OctoWoW before its release went through: it goes through now)
	if suspended and ns.Reroll and ns.Reroll.StartedOver then
		ns.Reroll:StartedOver()
	end
	ns.Print(ns.L["Collection emptied."])
	if suspended then
		ns.Print(ns.L["Curator is back: your collection starts over."])
	end
	-- (every page that shows what went: painted again)
	for _, e in ipairs({ "CHANGED", "CLAIMS_CHANGED", "OFFERS_CHANGED", "CHOICE_CHANGED", "CASES_CHANGED", "DISPLAYS_CHANGED",
		"COPIES_CHANGED", "RUBIES_CHANGED", "TALENTS_CHANGED", "QUESTS_CHANGED", "GOLDEN_CHANGED", "MARKET_CHANGED", "MAIN_CHANGED",
		"CHEST_CHANGED" }) do
		ns.Fire(e)
	end
	if suspended then
		ns.Fire("UNSUSPENDED")
	end
end

local callbacks = {}
function ns.On(event, fn)
	callbacks[event] = callbacks[event] or {}
	CuratorOctoFull.Insert(callbacks[event], fn)
end
function ns.Fire(event, ...)
	for _, fn in ipairs(callbacks[event] or {}) do
		fn(unpack(arg, 1, arg.n))
	end
end

-------------------------------------------------------------------------------
-- Series and boosters
-------------------------------------------------------------------------------
local byKey
function ns.SeriesByKey(key)
	if not byKey then
		byKey = {}
		for _, s in ipairs(ns.Series or {}) do
			byKey[s.key] = s
		end
	end
	return byKey[key]
end

function ns.Packs(s)
	-- (1.13.0: a limited edition of no booster, the Hardcup Saison 3, never has any)
	if s and s.limited then
		return 0
	end
	return (ns.db and s and ns.db.packs[s.key]) or 0
end

-- (1.14.0, his word) given: they came from a trade or from a display opened (bought, given): its album stays as it
-- was, locked if it was (Level.lua: LV:Unlocked).
function ns.AddPacks(s, n, given)
	if not (ns.db and s) then
		return
	end
	-- (1.13.0: an album of a limited edition of no booster, the Hardcup Saison 3: its cards come from a gift code only,
	-- Gifts.lua)
	if s.limited and (n or 0) > 0 then
		return
	end
	-- (1.14.0: its album as it must be, else nothing comes: Guard.lua)
	if (n or 0) > 0 and ns.Guard and not ns.Guard:Allow(s) then
		return
	end
	ns.db.packs[s.key] = math.max(0, ns.Packs(s) + n)
	if n > 0 and not given then
		-- (an album boosters have come for: it can get the boosters to choose; unlocked)
		ns.db.dropped = ns.db.dropped or {}
		ns.db.dropped[s.key] = true
	end
	ns.Fire("CHANGED")
end

-- Boosters waiting in all the albums.
function ns.TotalPacks()
	local n = 0
	for _, s in ipairs(ns.Series or {}) do
		n = n + ns.Packs(s)
	end
	return n
end

-- The starting zone of the character's people: the album a new collector begins with.
local HOME = {
	Human = "elwynn", Dwarf = "dunmorogh", Gnome = "dunmorogh", NightElf = "teldrassil",
	Orc = "durotar", Troll = "durotar", Tauren = "mulgore", Scourge = "tirisfal", Undead = "tirisfal",
}
function ns.HomeSeries()
	local zone = ns.Rewards and ns.Rewards:ZoneSeries()
	if zone then
		return zone
	end
	local race = UnitRace and CuratorOctoFull.Select(2, UnitRace("player"))
	local s = race and HOME[race] and ns.SeriesByKey(HOME[race])
	if not s then
		-- the other peoples (the Skyborne of Forever and their isle): the first zone of their faction
		local faction = UnitFactionGroup and UnitFactionGroup("player")
		s = ns.SeriesByKey(faction == "Horde" and "durotar" or "elwynn")
	end
	return s or (ns.Series and ns.Series[1])
end

-------------------------------------------------------------------------------
-- (1.4.0) Hoard is now Curator. The game keeps the save of an addon under the name of its folder: the
-- collection of Hoard (HoardDB) is read through a folder Hoard that comes with Curator (its table of
-- contents alone, loaded first). The first time, it moves over when Curator has nothing of its own yet
-- (no card, no booster opened), and the save of Hoard is emptied: the collection then lives in
-- Curator's save alone (a reset of Curator never brings it back). Its seal stays good: the salt has
-- not changed. The whole Hoard of before still running (its folder not replaced): said, nothing moves.
-------------------------------------------------------------------------------
local function OurSave(db)
	return type(db) == "table" and type(db.cards) == "table" and type(db.packs) == "table"
		and (type(db.seal) == "string" or type(db.version) == "number")
end

-- A collection with nothing of its own yet.
local function Blank(db)
	if type(db) ~= "table" then
		return true
	end
	return (type(db.cards) ~= "table" or next(db.cards) == nil) and (tonumber(db.opened) or 0) == 0
end

-- The collection of Hoard moved to Curator (true), or not.
function ns.FromHoard()
	ns.hoardStill, ns.hoardKept = nil, nil
	local old = rawget(_G, "HoardDB")
	if not OurSave(old) then
		return false
	end
	local before = rawget(_G, "Hoard")
	if type(before) == "table" and type(before.Collection) == "table" then
		ns.hoardStill = true
		return false
	end
	if not Blank(rawget(_G, "CuratorOctoFullDB")) then
		ns.hoardKept = true
		return false
	end
	CuratorOctoFullDB = old
	_G.HoardDB = nil
	return true
end

-- (1.7.0) The save, out of the globals while the game runs: a /run typed in the chat no longer
-- reaches the collection (sealed at the logout with what it holds then, whatever changed it). Put
-- back where the game writes it from at the logout (the game writes it right after).
-- (1.14.0) Curator plays with a copy of the save made when it loads: the table the game loaded stays behind,
-- and another addon that took it then (one loaded before Curator gets the event first) holds a table that
-- nothing reads any more: what it changes there goes nowhere. At the logout, a copy again where the game
-- writes it from, sealed: what is changed in it after that is no longer under the seal (the next login takes
-- the save for one edited outside the game).

-- A table and all it holds, copied.
local function Copy(t, seen)
	if type(t) ~= "table" then
		return t
	end
	if seen[t] then
		return seen[t]
	end
	local out = {}
	seen[t] = out
	for k, v in pairs(t) do
		out[Copy(k, seen)] = Copy(v, seen)
	end
	return out
end

-- The collection, copied where the game writes it from (should the copy fail, the collection itself: a save
-- written without it would be a collection lost).
local function PutOut()
	local db = ns.db
	if type(db) ~= "table" then
		return
	end
	local ok, copy = pcall(Copy, db, {})
	CuratorOctoFullDB = ok and copy or db
end

-- (1.10.0) The seal made again at the very end of the logout, should something of the addon have changed
-- the save after it all the same (in a PLAYER_LOGOUT of its own, against the rule of LOGOUT below): this
-- frame asks for the event at the login, once every file is loaded, and gets it after the others. The save
-- the game writes then matches its seal, whatever the order. (1.14.0) And the copy where the game writes it
-- from made again: what was done to the one put there before (changed, replaced) does not stay.
local last = CreateFrame("Frame")
CuratorOctoFull.SetScript(last, "OnEvent", function()
	if type(ns.db) ~= "table" then
		return
	end
	if ns.db.seal ~= ns.Seal(ns.db) then
		ns.SealNow(ns.db)
	end
	PutOut()
end)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
CuratorOctoFull.SetScript(events, "OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON then
		ns.movedFromHoard = ns.FromHoard()
		local fresh = CuratorOctoFullDB == nil
		-- (1.14.0) the copy Curator plays with (see above); the table the game loaded leaves the globals only once
		-- the copy is ready (should the copy itself fail, the game writes the save back as it found it)
		local db = Copy(CuratorOctoFullDB or {}, {})
		-- a save that no longer matches its seal was edited outside the game (1.14.1: and why, kept for the
		-- author: the seal here, a save of the beta put back in Reroll.lua)
		if ns.Tampered(db) then
			db.edited = true
			db.editedWhy = { k = "seal", t = (GetServerTime and CuratorOctoFull.ServerTime()) or 0, v = ns.version }
		end
		CopyDefaults(db, DEFAULTS)
		-- (0.17.1 kept the entrances off under another name: gone, they play unless turned off)
		db.entrances = nil
		-- (1.2: one booster bar instead of a gauge for each album, which starts where the fullest of them
		-- was; no more epic card sure to come after a run of boosters without one)
		if type(db.progress) == "table" then
			local best = 0
			for _, p in pairs(db.progress) do
				if type(p) == "number" and p > best then
					best = p
				end
			end
			db.bar = math.max(tonumber(db.bar) or 0, math.min(math.floor(best), 99))
		end
		db.progress, db.pity = nil, nil
		ns.db = db
		if ns.Collection then
			ns.Collection:Init()
		end
		-- (1.14.0) the release of OctoWoW, before anything reads the collection: what the beta leaves of it (Reroll.lua)
		if ns.Reroll then
			ns.Reroll:Release()
		end
		-- (1.14.0) what the cards and their albums must stay, checked against the files of the albums (Guard.lua)
		if ns.Guard then
			ns.Guard:Take()
		end
		-- (1.14.0) what the draws of the cases take, kept apart now, before any addon loaded after Curator runs (Cases.lua)
		if ns.Cases then
			ns.Cases:Take()
		end
		local first = ns.Series and ns.Series[1]
		if first and db.boosters then
			-- 0.4 and before: one count of boosters, all of them Elwynn
			db.packs[first.key] = (db.packs[first.key] or 0) + db.boosters
			db.boosters = nil
		end
		-- (1.2.1: the boosters kept from before 1.2, when they came far too easily, are taken away once:
		-- those to open, those to choose, those that came in a trade not confirmed yet. A new collection
		-- has none: 1.14.0, no booster of welcome either.)
		if not db.oldPacksGone then
			local gone = 0
			if not fresh then
				for _, t in ipairs({ db.packs, db.choice, db.held }) do
					for _, n in pairs(t) do
						gone = gone + math.max(0, tonumber(n) or 0)
					end
					CuratorOctoFull.Wipe(t)
				end
			end
			db.oldPacksGone = true
			ns.oldPacksGone = gone > 0 and gone or nil
		end
		db.version = DEFAULTS.version
		CuratorOctoFullDB = nil
		-- (1.12.0) the language chosen for Curator
		ns.ApplyLanguage()
		ns.Fire("LOADED")
	elseif event == "PLAYER_LOGOUT" then
		-- (1.10.0) whatever fails on the way, the seal is made: a save written without it would be taken for
		-- one edited outside the game at the next login (what failed is told as any error is; 1.14.0: and
		-- nothing that fails in the telling stops the rest)
		local function Safely(fn, ...)
			local ok, err = pcall(fn, unpack(arg, 1, arg.n))
			if not ok and geterrorhandler then
				pcall(geterrorhandler(), err)
			end
		end
		-- (a show of the author's build may have lent the album another collection: the real one first)
		if ns.RestoreDB then
			Safely(ns.RestoreDB)
		end
		-- (1.14.0) first of all, where the game writes it from: the collection as it is, should what follows never
		-- come to its end (put there again, sealed, at the end)
		PutOut()
		-- (1.10.0) what the session changed in the save and puts back when the game closes, put back now,
		-- before the code and the seal (UI/Golden.lua: the settings of the name plates). Never in a
		-- PLAYER_LOGOUT of its own: the game gives that event to the frames in an order that is not ours,
		-- and the save changed after its seal is taken at the next login for a save edited outside the game.
		Safely(ns.Fire, "LOGOUT")
		-- (1.7.0) the code of the collection, for the launcher (Export.lua): made before the seal, which
		-- holds what making it may set (the id of a collection that has none yet, the moment of the code)
		if ns.Export then
			Safely(ns.Export.Save, ns.Export)
		end
		-- the game saves now: the seal goes with what it saves (1.14.0: and the copy of the collection, with it)
		if ns.db then
			Safely(ns.SealNow, ns.db)
			PutOut()
		end
	elseif event == "PLAYER_LOGIN" then
		last:RegisterEvent("PLAYER_LOGOUT")
		ns.Fire("LOGIN")
		-- (1.14.0, his word: no booster of welcome; those a test build of before left waiting go, never given)
		if ns.db then
			ns.db.welcomePacks = nil
		end
		-- (1.4.0: the collection of Hoard, come over or not)
		if ns.movedFromHoard then
			ns.Print(ns.L["Hoard is now Curator: your collection came along. After your next logout, you can delete the folder Hoard of your addons."])
		elseif ns.hoardStill then
			ns.Print(ns.L["The Hoard of before is still installed: replace its folder (Interface\\AddOns\\Hoard) with the one that comes with Curator, then reload. Your collection will then move to Curator."])
		elseif ns.hoardKept then
			ns.Print(ns.L["Curator already has a collection of its own: the one of Hoard stays where it is."])
		end
		-- (1.2.1: the boosters kept from before 1.2 that were taken away)
		if ns.oldPacksGone then
			ns.Print(ns.L["The boosters kept from before 1.2 are taken away (%d): they came far too easily. New ones come with the booster bar, above your experience bar."], ns.oldPacksGone)
			ns.oldPacksGone = nil
		end
		if ns.db and not ns.db.welcomed then
			ns.db.welcomed = true
			ns.Print(ns.L["Your collection starts here. Type /curator to open your album."])
			ns.Print(ns.L["Fill the booster bar (above your experience bar) where an album lives: defeat creatures that give experience, complete quests and their objectives, discover places, gain levels; in a dungeon or a raid, defeat its creatures and its bosses. Each time it is full: a booster of the album of the place."])
		end
	end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------
local function Help()
	local L = ns.L
	ns.Print("Curator %s | OctoWoW: %s", ns.Beta and ns.Beta:VersionText() or ns.version, "CloudNine_Ex")
	ns.Print(L["/curator: open the inventory, on your boosters"])
	ns.Print(L["/curator album: the album of the place you are in"])
	ns.Print(L["/curator open: open a booster"])
	ns.Print(L["/curator view [name]: the collection of a player (your target, else yours)"])
	ns.Print(L["/curator boosters: your boosters, their odds"])
	ns.Print(L["/curator compact: open the boosters in a small window you can move, or in full screen"])
	ns.Print(L["/curator bar: show or hide the booster bar (Shift-drag moves it, /curator bar reset puts it back)"])
	ns.Print(L["/curator tour: a guided tour of the album"])
	ns.Print(L["/curator news: what is new in this version"])
	ns.Print(L["/curator profile: your profile, your level and the track of its rewards"])
	ns.Print(L["/curator reward: your rewards to choose, one among three"])
	ns.Print(L["/curator achievements: your achievements"])
	ns.Print(L["/curator quests: your quests"])
	ns.Print(L["/curator inventory: every copy of your cards, your boosters and your displays"])
	ns.Print(L["/curator cases: your cases, their keys and the cards they gave"])
	ns.Print(L["/curator golden: your golden quest of the week"])
	ns.Print(L["/curator search name: find a card by its name"])
	ns.Print(L["/curator markers: the markers of the golden quests, on or off"])
	ns.Print(L["/curator talents: your talents (from level 5)"])
	ns.Print(L["/curator inns: your rest, your dish of the day, your leads, your loyalty card and your travel passport"])
	ns.Print(L["/curator leads: the leads of the tavern on the screen, shown or hidden"])
	ns.Print(L["/curator discovery: the discovery of the Paladin Collection Case No. 1, while it lasts"])
	ns.Print(L["/curator site: the website of Curator and its app"])
	ns.Print(L["/curator active: the talent to use of your tree"])
	ns.Print(L["/curator contract: write an exchange contract"])
	ns.Print(L["/curator trade [name]: a trade with a player (your target), else your trades"])
	ns.Print(L["/curator minimap: show or hide the minimap button"])
	ns.Print(L["/curator reset: empty the collection"])
	ns.Print(L["/curator announce: share your best pulls with your guild, or not"])
	ns.Print(L["/curator cinematic: the entrance of the legendary and mythic cards, on or off"])
	ns.Print(L["/curator live: the boosters your guild opens, live, on or off"])
	ns.Print(L["/curator presence: share your presence with the author of Curator, or not"])
	ns.Print(L["/curator rubies: your rubies, what they come from and what they buy"])
	ns.Print(L["/curator counter: the ruby counter (the ledger)"])
	ns.Print(L["/curator save: save your collection by logging out"])
	ns.Print(L["/curator chat [message]: the chat channel of the collectors of your faction"])
	ns.Print(L["/curator options: the options of Curator (the size of the album, what is shown, what is shared)"])
	ns.Print(L["/curator log: the journal of your trades (what went and came), for a bug"])
	ns.Print(L["/curator gift: redeem a gift code from the author"])
	ns.Print(L["/curator main: your main character, or make this one your main"])
	ns.Print(string.format(L["/curator chest: the chest of this character (a reroll under level %d)"], ns.Reroll and ns.Reroll.LEVEL or 15))
	ns.Print(L["/curator stats: every rate of Curator, and what your talents change"])
	if ns.Admin then
		-- (1.8.0: the previews, for the author only: the players discover the cards by playing)
		ns.Print(L["/curator test [album | dungeon | raid] [mythic | legendary | epic | rare] [thunderforged | titanforged]: a preview booster with that card (nothing is kept)"])
		ns.Print(L["/curator test corrupt [1-100] [mythic | legendary | epic | rare]: a booster of Hallow's End with a corrupted card at that corruption (nothing is kept)"])
		ns.Admin:Help()
	end
	ns.Print(L["Shift-click a card (in your album, a booster, a profile) to show it in the chat."])
	ns.Print(L["Fill the booster bar (above your experience bar) where an album lives: defeat creatures that give experience, complete quests and their objectives, discover places, gain levels; in a dungeon or a raid, defeat its creatures and its bosses. Each time it is full: a booster of the album of the place."])
end

-- The series to use when none is given: the zone (or dungeon) you are in, else the album's,
-- else the starting zone of the character.
function ns.CurrentSeries()
	return (ns.Rewards and ns.Rewards:ZoneSeries()) or (ns.Album and ns.Album.series) or ns.HomeSeries()
end

-- Opens a booster of the given series; without one: the zone's, the album's, else any album
-- that has boosters waiting.
function ns.OpenBooster(opts)
	if not ns.db or (ns.Beta and ns.Beta:Blocked()) then
		return
	end
	opts = opts or {}
	-- (1.14.0, after its test: a reroll opens no booster, Reroll.lua; a preview of the author opens anywhere)
	if not opts.test and ns.Reroll and ns.Reroll:NoOpening() then
		ns.Reroll:SayNoOpening()
		return
	end
	local s = opts.series
	if not s then
		local zone, album = ns.Rewards and ns.Rewards:ZoneSeries(), ns.Album and ns.Album.series
		if zone and (opts.test or ns.Packs(zone) > 0) then
			s = zone
		elseif album and (opts.test or ns.Packs(album) > 0) then
			s = album
		else
			for _, x in ipairs(ns.Series) do
				if ns.Packs(x) > 0 then
					s = x
					break
				end
			end
		end
		s = s or ns.CurrentSeries()
	end
	-- (1.13.0: the album of a limited edition of no booster, the Hardcup Saison 3: none, not even to test)
	if s and s.limited then
		ns.Print(ns.L["No booster for this album: its cards come from a gift code of the website."])
		return
	end
	if not opts.test and ns.Packs(s) <= 0 then
		ns.Print(ns.L["No booster left."] .. " " .. ns.L["Fill the booster bar (above your experience bar) where an album lives: defeat creatures that give experience, complete quests and their objectives, discover places, gain levels; in a dungeon or a raid, defeat its creatures and its bosses. Each time it is full: a booster of the album of the place."])
		return
	end
	ns.Booster:Open(s, opts)
end

-- /curator test: the words for the best card of the preview booster, in English or in French: its
-- rarity, its finish (thunderforged, titanforged; the words of the finishes before 1.3 too). Both can
-- be given.
local TEST_RARITY = {
	mythic = 6, mythique = 6, legendary = 5, legendaire = 5, epic = 4, epique = 4, rare = 3,
}
local TEST_FINISH = {
	thunderforged = "shiny", thunder = "shiny", shiny = "shiny", brillant = "shiny", brillante = "shiny",
	titanforged = "holo", titan = "holo", holo = "holo", holographic = "holo", holographique = "holo",
}
-- (1.12.0) /curator test corrupt [N]: a booster of Hallow's End (an album of an event), its card corrupted at N % (1 to
-- 100; else as it comes)
local TEST_CORRUPT = {
	corrupt = true, corrupted = true, corruption = true, corrompu = true, corrompue = true, corrompre = true,
	verderbt = true, corrupta = true, corrompida = true,
}
-- (1.14.0) /curator test caisse [rank] [finish] [weapon]: the opening of a case (UI/Crate.lua), the card it stops on
-- of that rank of the cases (their own: rare, restricted, classified, covert, priceless; by their words or their
-- colours), thunderforged or titanforged; a priceless card of that weapon (its words: CR.WEAPONS; a class for Atiesh)
local TEST_CRATE = { caisse = true, crate = true, case = true }
-- (1.14.0) /curator test reroll | coffre | principal | sortie: the rerolls and the release of OctoWoW (UI/Reroll.lua)
local TEST_REROLL = {
	reroll = "reroll", rerolls = "reroll", coffre = "chest", chest = "chest", principal = "main", main = "main",
	sortie = "release", release = "release", forever = "release",
}
local TEST_CRATE_RANK = {
	rare = 1, bleu = 1, blue = 1,
	restreint = 2, restricted = 2, violet = 2, purple = 2,
	classifie = 3, classified = 3, rose = 3, pink = 3,
	secret = 4, covert = 4, rouge = 4, red = 4,
	inestimable = 5, priceless = 5, ["or"] = 5, gold = 5, dore = 5, artefact = 5, artifact = 5,
}
local TEST_CRATE_FINISH = {
	thunderforged = "thunder", thunder = "thunder", tonnerre = "thunder", foudre = "thunder",
	titanforged = "titan", titan = "titan", titans = "titan", holo = "titan",
}

-- The letters with an accent, plain (to find an album by its name however it is typed).
local PLAIN = {
	["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
	["À"] = "a", ["Á"] = "a", ["Â"] = "a", ["Ã"] = "a", ["Ä"] = "a", ["Å"] = "a",
	["ç"] = "c", ["Ç"] = "c", ["ñ"] = "n", ["Ñ"] = "n", ["ß"] = "ss",
	["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e", ["È"] = "e", ["É"] = "e", ["Ê"] = "e", ["Ë"] = "e",
	["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i", ["Ì"] = "i", ["Í"] = "i", ["Î"] = "i", ["Ï"] = "i",
	["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["Ò"] = "o", ["Ó"] = "o", ["Ô"] = "o", ["Õ"] = "o", ["Ö"] = "o",
	["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u", ["Ù"] = "u", ["Ú"] = "u", ["Û"] = "u", ["Ü"] = "u",
	["ý"] = "y", ["ÿ"] = "y", ["Ý"] = "y", ["œ"] = "oe", ["Œ"] = "oe", ["æ"] = "ae", ["Æ"] = "ae",
}

local function Plain(text)
	text = string.gsub((text or ""), "[\195\197][\128-\191]", PLAIN)
	return (string.gsub(string.lower(text), "[%s%p]", ""))
end
ns.Plain = Plain

-- An album by its key or its name ("moltencore", "coeur du magma"), or one of the dungeons
-- ("dungeon", "donjon") or of the raids ("raid") at random.
local function FindSeries(query)
	local q = Plain(query)
	if q == "" then
		return nil
	end
	local any = q == "dungeons" or q == "donjons" or q == "instances"
	local dungeon = q == "dungeon" or q == "donjon" or q == "instance"
	if q == "raids" then
		q = "raid"
	end
	local pool = {}
	for _, s in ipairs(ns.Series) do
		if s.dungeon and (any or (dungeon and not s.raid) or (q == "raid" and s.raid)) then
			pool[CuratorOctoFull.Length(pool) + 1] = s
		end
	end
	if CuratorOctoFull.Length(pool) > 0 then
		return pool[math.random(CuratorOctoFull.Length(pool))]
	end
	for _, s in ipairs(ns.Series) do
		if s.key == q then
			return s
		end
	end
	for _, s in ipairs(ns.Series) do
		if string.find(Plain(ns.Collection:SeriesName(s)), q, 1, true) or string.find(Plain(s.name), q, 1, true) then
			return s
		end
	end
	return false
end
ns.FindSeries = FindSeries

-- /curator test [album] [rarity] [finish]: a preview booster. (1.8.0: the author's only, his build: the
-- players discover the cards by playing; ns.PreviewBooster for the tests of the addon)
local function Test(arg)
	arg = arg or ""
	local first = Plain((CuratorOctoFull.Match(arg, "^(%S+)") or ""))
	-- (31 October: the tests of the author's build itself, UI/Admin.lua: an enchanter, a banker here)
	if ns.Admin and ns.Admin.TestWord and ns.Admin:TestWord(first, arg) then
		return
	end
	-- (1.14.3) /curator test inventaire: my inventory as another player sees it, page by page, each page made as it goes to
	-- them and read back as it comes (Comm.lua), on the page of another player's inventory (UI/Inventory.lua); nothing sent
	if (first == "inventaire" or first == "inventory" or first == "inv") and ns.Album and ns.Album.ShowPlayer and ns.Guild then
		ns.Album:ShowPlayer(ns.Guild:Me())
		return
	end
	-- (1.14.3) /curator test nouveautes: the window of the news as it comes after an update, those of the newest version
	-- (UI/Mandatory.lua); nothing saved
	if (first == "nouveautes" or first == "news" or first == "maj" or first == "update") and ns.NewsWindow then
		ns.NewsWindow:Show({ ns.NewsWindow.NEWS[1] })
		return
	end
	-- (1.14.0) the sounds of a titanforged card and those that could replace them, each by its number (UI/Admin.lua)
	if (first == "son" or first == "sons" or first == "sound" or first == "sounds") and ns.Admin and ns.Admin.TestSounds then
		ns.Admin:TestSounds(CuratorOctoFull.Match(arg, "^%S+%s+(%S+)"))
		return
	end
	-- (1.14.0) the opening of a case, as in CS2: the case of the month (the Paladin Collection Case No. 1), nothing kept
	-- (UI/Crate.lua)
	if TEST_CRATE[first] and ns.CrateUI then
		local tier, finish, line, class
		local words = {}
		local n = 0
		for word in CuratorOctoFull.Gmatch(arg, "%S+") do
			n = n + 1
			local w = Plain(word)
			local l, c = ns.CrateUI:WeaponWord(w)
			if n == 1 then
				-- (the word of the test itself)
			elseif TEST_CRATE_RANK[w] then
				tier = TEST_CRATE_RANK[w]
			elseif TEST_CRATE_FINISH[w] then
				finish = TEST_CRATE_FINISH[w]
			else
				-- (a card of the case by its name: /curator test caisse tirion, secret redemption, bénédiction des
				-- rois; else a priceless card of that weapon: /curator test caisse sulfuras, atiesh druide, rang14)
				words[CuratorOctoFull.Length(words) + 1] = word
				if l or c then
					line, class = l or line, c or class
				end
			end
		end
		ns.CrateUI:Test(tier, finish, line, class, CuratorOctoFull.Length(words) > 0 and table.concat(words, " ") or nil)
		return
	end
	-- (1.14.0) the rerolls and the release of OctoWoW (UI/Reroll.lua): this character as a reroll under level 15,
	-- on a copy of the collection; its chest opened; the window of the main; the collection as the release makes it,
	-- on a copy. Nothing kept: again, back to the true one.
	if TEST_REROLL[first] and ns.RerollUI then
		ns.RerollUI:Test(TEST_REROLL[first])
		return
	end
	-- (1.14.0, his idea) /curator test pattern [number] [rarity]: twelve titanforged copies of a card side by side, each with its
	-- pattern (Patterns.lua), from the page of that number (UI/PatternsView.lua); nothing kept
	if (first == "pattern" or first == "patterns" or first == "motif" or first == "motifs") and ns.PatternView then
		local from, rarity, cases, rank
		for word in CuratorOctoFull.Gmatch(arg, "%S+") do
			local w = Plain(word)
			if tonumber(w) then
				from = tonumber(w)
			elseif TEST_CRATE[w] or w == "caisses" or w == "cases" or w == "crates" then
				-- (his word: the cards of the cases, /curator test pattern caisse [rank])
				cases = true
			elseif cases and TEST_CRATE_RANK[w] then
				rank = TEST_CRATE_RANK[w]
			elseif TEST_RARITY[w] then
				rarity = TEST_RARITY[w]
			end
		end
		ns.PatternView:Test(from, rarity, cases, rank)
		return
	end
	-- (his idea, 31 October) /curator test usure [rarity]: the wear, ten copies of a card of the grade 10 to 1, then two by
	-- chance (UI/PatternsView.lua, Wear.lua); nothing kept
	if (first == "usure" or first == "wear" or first == "etat" or first == "état") and ns.PatternView then
		local rarity
		for word in CuratorOctoFull.Gmatch(arg, "%S+") do
			local w = Plain(word)
			if TEST_RARITY[w] then
				rarity = TEST_RARITY[w]
			end
		end
		ns.PatternView:TestWear(rarity)
		return
	end
	-- (1.14.0) /curator test bourse: the Steamwheedle Exchange on a copy of the collection, its news made up, the website
	-- played here (UI/Market.lua); again, back to the true one
	if (first == "bourse" or first == "market" or first == "hv" or first == "exchange" or first == "borse" or first == "bolsa"
		or first == "birzha") and ns.MarketUI and ns.MarketUI.Test then
		ns.MarketUI:Test()
		return
	end
	-- (1.14.0) /curator test pass: the pass of the app asked for now, as from the release of OctoWoW, on the true
	-- collection (nothing changes in it); again, back to normal (Pass.lua)
	if (first == "pass" or first == "passe" or first == "laissezpasser") and ns.Pass then
		ns.Pass:Test()
		return
	end
	-- (1.14.0) /curator test guard: what another addon could do, done now: a common card made mythic in memory; Curator
	-- gives nothing more until /reload (Guard.lua)
	if (first == "guard" or first == "garde" or first == "gardien") and ns.Guard and ns.Guard.Test then
		ns.Guard:Test()
		return
	end
	-- (1.12.1: a character banned by its name, for this session only: UI/Admin.lua, Bans.lua)
	if (first == "ban" or first == "banni" or first == "bannir") and ns.Admin and ns.Admin.TestBan then
		ns.Admin:TestBan((string.gsub(arg, "^%S+%s*", "")))
		return
	end
	-- (1.12.1: the reminders to save, at once: the one of the time played, then the one of a great card of the album of
	-- the place; nothing kept, UI/Save.lua)
	if (first == "save" or first == "sauvegarde" or first == "rappel" or first == "reminder") and ns.Save then
		ns.Save:Remind()
		-- (the card of the highest rarity the album has)
		local s, card = ns.CurrentSeries(), nil
		for r = CuratorOctoFull.Length(ns.RARITY), 1, -1 do
			card = card or (s and s.byRarity and s.byRarity[r] and s.byRarity[r][1])
		end
		if card then
			ns.Save:Remind(card, "holo")
		end
		return
	end
	-- (1.10.0: a golden booster, of the album named or of the place; a preview as the others: nothing kept)
	if first == "or" or first == "gold" or first == "golden" then
		local s = FindSeries((string.gsub(arg, "^%S+%s*", "")))
		if s == false then
			ns.Print(ns.L["No album by that name."])
			return
		end
		ns.OpenBooster({ test = true, series = s or nil, golden = { t = 0 } })
		return
	end
	local rarity, finish, words = nil, nil, {}
	local corrupt, gauge = false, nil
	for word in CuratorOctoFull.Gmatch(arg, "%S+") do
		local w = Plain(word)
		local num = tonumber(w)
		if TEST_RARITY[w] then
			rarity = TEST_RARITY[w]
		elseif TEST_FINISH[w] then
			finish = TEST_FINISH[w]
		elseif TEST_CORRUPT[w] then
			corrupt = true
		elseif num and corrupt then
			gauge = math.max(1, math.min(100, math.floor(num)))
		else
			words[CuratorOctoFull.Length(words) + 1] = word
		end
	end
	local s = FindSeries(table.concat(words, " "))
	if s == false then
		ns.Print(ns.L["No album by that name."])
		return
	end
	if corrupt then
		-- (1.12.0) the corrupted cards are those of the albums of an event: the one named, else Hallow's End's
		if not (s and s.event) then
			s = ns.Hallow and ns.Hallow:Series()
		end
		if not s then
			ns.Print(ns.L["No album by that name."])
			return
		end
		ns.OpenBooster({ test = true, series = s, force = rarity or 3, corrupt = gauge or true })
		return
	end
	-- (a finish alone: on a rare card; nothing: a booster as they come, 1.2)
	local force = rarity or (finish and 3) or nil
	ns.OpenBooster({ test = true, series = s or nil, force = force, shiny = finish == "shiny", holo = finish == "holo" })
end
ns.PreviewBooster = Test

SLASH_CURATOR1 = "/curator"
SlashCmdList.CURATOR = function(msg)
	msg = string.gsub(string.gsub((msg or ""), "^%s+", ""), "%s+$", "")
	local cmd, arg = CuratorOctoFull.Match(msg, "^(%S*)%s*(.-)$")
	cmd = string.lower(cmd)
	local rest = string.lower(arg)
	-- (1.13.0, after its first test: /curator opens the inventory on its boosters, /curator album the album of the place)
	if cmd == "" then
		ns.Album:Toggle()
	elseif cmd == "album" then
		ns.Album:ToggleHere()
	elseif cmd == "open" then
		ns.OpenBooster()
	elseif cmd == "view" or cmd == "voir" or cmd == "inspect" or cmd == "collection" then
		ns.Players:ShowCommand(arg)
	elseif cmd == "achievements" or cmd == "ach" or cmd == "hautsfaits" or cmd == "hf" then
		ns.Album:Open("ach")
	elseif cmd == "quests" or cmd == "quest" or cmd == "quetes" or cmd == "quêtes" then
		ns.Album:Open("quests")
	elseif cmd == "inventory" or cmd == "inv" or cmd == "inventaire" then
		-- (1.13.0) every copy of the collection, one line each (UI/Inventory.lua)
		if ns.InventoryUI then
			ns.InventoryUI:Open()
		end
	elseif cmd == "talents" or cmd == "talent" or cmd == "spec" or cmd == "specialization" or cmd == "specialisation" or cmd == "spé" then
		ns.Album:Open("talents")
	elseif cmd == "inns" or cmd == "inn" or cmd == "auberges" or cmd == "auberge" or cmd == "passport" or cmd == "passeport" or cmd == "carnet" then
		-- (1.8.0) the inns: the loyalty card, the travel passport (1.14.0: the rest, the dish of the day, the leads)
		ns.Album:ShowInns()
	elseif cmd == "leads" or cmd == "lead" or cmd == "pistes" or cmd == "spuren" or cmd == "pistas" or cmd == "rumors" or cmd == "rumeurs" then
		-- (not "piste": the reward track of the profile, below)
		-- (1.14.0) the leads of the tavern on the screen, shown or hidden (UI/Lodging.lua)
		if ns.LodgingUI then
			ns.LodgingUI:Toggle()
		end
	elseif cmd == "pvp" or cmd == "jcj" or cmd == "war" or cmd == "guerre" or cmd == "front" then
		-- (1.8.0) the PvP: the combatants, the war board, the front of the collectors (1.14.0, his word: gone until its
		-- rework; its quests stay)
		ns.Print(ns.L["The PvP of Curator is being reworked: it comes back in a later version. Its quests stay."])
	elseif cmd == "active" or cmd == "actif" or cmd == "instinct" then
		-- (1.14.0) the talent to use of the tree (the first one of the bar of the boosters: UI/BoosterBar.lua)
		local TL = ns.Talents
		if TL and not (ns.Beta and ns.Beta:Blocked()) then
			local id = TL:BarActives()[1]
			if not id then
				ns.Print(ns.L["No talent to use yet: the third tier of your tree holds one."])
			else
				local ok, why = TL:Activate(id)
				if not ok and why == "ready" then
					ns.Print(ns.L["%s recharges: ready in %s."], TL:Name(id), ns.Duration(TL:Left(id)))
				end
			end
		end
	elseif cmd == "catchup" or cmd == "rattrapage" then
		ns.Rewards:OpenCatchUp(arg)
	elseif cmd == "boosters" or cmd == "booster" or cmd == "tirage" or cmd == "tirages" then
		ns.Album:ShowBoosters()
	elseif cmd == "compact" or cmd == "small" or cmd == "window" or cmd == "petit" or cmd == "reduit" or cmd == "réduit"
		or cmd == "fenetre" or cmd == "fenêtre" then
		ns.Booster:ToggleSmall()
	elseif cmd == "bar" or cmd == "barre" then
		if ns.BoosterBar then
			ns.BoosterBar:Command(rest)
		end
	elseif cmd == "tour" or cmd == "tuto" or cmd == "tutorial" or cmd == "tutoriel" or cmd == "guide" or cmd == "visite" then
		if ns.Tour then
			ns.Tour:Start()
		end
	elseif cmd == "profile" or cmd == "profil" then
		ns.Album:ShowProfile("overview")
	elseif cmd == "level" or cmd == "niveau" or cmd == "track" or cmd == "piste" then
		ns.Album:ShowProfile("track")
	elseif cmd == "reward" or cmd == "rewards" or cmd == "recompense" or cmd == "récompense" or cmd == "recompenses"
		or cmd == "récompenses" or cmd == "belohnung" or cmd == "recompensa" then
		-- (1.14.0) the rewards of the levels to choose (UI/Offers.lua)
		if ns.OffersUI then
			ns.OffersUI:Show()
		end
	elseif cmd == "golden" or cmd == "gold" or cmd == "or" or cmd == "doree" or cmd == "dorée" then
		-- (1.10.0: the golden quest of the week, where it stands)
		if ns.GoldenUI then
			ns.GoldenUI:ShowStatus()
		end
	elseif cmd == "search" or cmd == "find" or cmd == "chercher" or cmd == "recherche" or cmd == "cherche" then
		-- (1.10.0: a card by its name)
		if ns.Search then
			ns.Search:Show(arg)
		end
	elseif cmd == "markers" or cmd == "marqueurs" or cmd == "marks" then
		-- (1.10.0: the ! and ? over the leaders, on the map and the minimap)
		ns.db.goldMarks = (ns.db.goldMarks == false) and true or false
		ns.Print(ns.db.goldMarks and ns.L["Golden quest markers: on."] or ns.L["Golden quest markers: off."])
		ns.Fire("GOLDEN_CHANGED")
	elseif cmd == "announce" then
		ns.db.announce = not ns.db.announce
		ns.Print(ns.db.announce and ns.L["Guild announcements: on."] or ns.L["Guild announcements: off."])
	elseif (cmd == "cinematic" or cmd == "cinematique" or cmd == "cinématique" or cmd == "cine") and rest == "debug" then
		-- (a line in the chat for each entrance: how its creature was measured and framed)
		ns.db.cinedebug = not ns.db.cinedebug or nil
		ns.Print("cinematic debug: " .. (ns.db.cinedebug and "on" or "off"))
	elseif cmd == "cinematic" or cmd == "cinematique" or cmd == "cinématique" or cmd == "cine" then
		ns.db.cinematic = not ns.Cinematic:Enabled()
		ns.Print(ns.db.cinematic and ns.L["Cinematics: on."] or ns.L["Cinematics: off."])
	elseif cmd == "presence" or cmd == "présence" then
		ns.Presence:Toggle()
	elseif (cmd == "log" or cmd == "journal") and ns.Wire then
		-- (1.12.0: the journal of the wire, what went to the other players and what came, for a bug told)
		local lines = ns.Wire:Journal(tonumber(rest) or 40)
		ns.Print(string.format(ns.L["The journal of the trades (%d lines):"], CuratorOctoFull.Length(lines)))
		for _, line in ipairs(lines) do
			print("|cff9d9d9d" .. line .. "|r")
		end
	elseif cmd == "gift" or cmd == "gifts" or cmd == "code" or cmd == "cadeau" or cmd == "cadeaux" or cmd == "geschenk"
		or cmd == "regalo" or cmd == "presente" then
		-- (1.12.0) a gift code of the author: its window, to paste it in (too long for the chat), Gifts.lua
		if ns.GiftUI then
			ns.GiftUI:Show(arg)
		end
	elseif cmd == "main" or cmd == "principal" or cmd == "haupt" or cmd == "hauptcharakter" then
		-- (1.14.0) the main character: who it is, this one made the main (UI/Reroll.lua)
		if ns.RerollUI then
			ns.RerollUI:Ask(true)
		end
	elseif cmd == "chest" or cmd == "coffre" or cmd == "truhe" or cmd == "cofre" or cmd == "bau" then
		-- (1.14.0) the chest of a reroll (UI/Reroll.lua)
		if ns.RerollUI then
			ns.RerollUI:ShowChest()
		end
	elseif cmd == "stats" or cmd == "stat" or cmd == "statistics" or cmd == "statistiques" or cmd == "statistik" or cmd == "statistiken"
		or cmd == "estadisticas" or cmd == "estadísticas" or cmd == "estatisticas" or cmd == "estatísticas" or cmd == "rates" then
		-- (1.15.0) the page of the statistics (UI/Rates.lua): every rate, and what the talents change
		if ns.Album and ns.Album.ShowRates then
			ns.Album:ShowRates()
		end
	elseif cmd == "admin" and ns.Admin then
		-- (31 October, his word: the console of the author, every command in it; its players: /curator admin joueurs)
		if ns.Admin.Console and not (rest == "joueurs" or rest == "players" or rest == "liste" or rest == "list") then
			ns.Admin.Console:Toggle()
		else
			ns.Admin:Toggle()
		end
	elseif cmd == "scan" and ns.Admin then
		ns.Admin:Scan()
	elseif cmd == "live" or cmd == "direct" then
		ns.db.live = not ns.db.live
		ns.Print(ns.db.live and ns.L["Live openings of the guild: on."] or ns.L["Live openings of the guild: off."])
	elseif cmd == "news" or cmd == "nouveautes" or cmd == "nouveautés" or cmd == "neuigkeiten" or cmd == "novedades" or cmd == "novidades"
		or cmd == "whatsnew" then
		-- (1.14.3, his word) what is new in this version, its window (UI/Mandatory.lua: ns.NewsWindow)
		if ns.NewsWindow then
			ns.NewsWindow:Show()
		end
	elseif cmd == "alerts" or cmd == "alertes" or cmd == "alert" or cmd == "alerte" then
		-- (1.14.3, the players' word: the alerts and the panel of the guild moved where they like, UI/Live.lua)
		if ns.Live and ns.Live.Mover then
			ns.Live:Mover()
		end
	elseif cmd == "test" and ns.Admin then
		Test(arg)
	elseif (cmd == "give" or cmd == "donner" or cmd == "donne") and ns.Admin and ns.Admin.Give then
		-- (1.12.0) the author's gifts to himself, to test everything (his build: UI/Admin.lua)
		ns.Admin:Give(arg)
	elseif (cmd == "verrou" or cmd == "verrous" or cmd == "lock" or cmd == "locks") and ns.Admin and ns.Admin.Locks then
		-- (1.14.0) the albums unlocked of his collection, locked again to test (his build: UI/Admin.lua)
		ns.Admin:Locks(arg)
	elseif cmd == "cases" or cmd == "case" or cmd == "caisse" or cmd == "caisses" or cmd == "kiste" or cmd == "kisten" or cmd == "caja"
		or cmd == "cajas" or cmd == "caixa" or cmd == "caixas" then
		-- (1.14.0) the cases (UI/Crate.lua): the case of the month, its keys, the cards it gave
		if ns.CrateUI and ns.CrateUI.Show then
			ns.CrateUI:Show()
		end
	elseif cmd == "contract" or cmd == "contrat" then
		ns.Album:Open("contract")
	elseif cmd == "trade" or cmd == "trades" or cmd == "echange" or cmd == "échange" or cmd == "echanges" or cmd == "échanges" then
		ns.Players:TradeCommand(arg)
	elseif cmd == "site" or cmd == "web" or cmd == "website" or cmd == "app" or cmd == "appli" then
		-- (1.8.0) the website of Curator, its address to copy, and its app
		if ns.SiteWindow then
			ns.SiteWindow:Show()
		end
	elseif cmd == "duel" or cmd == "duels" then
		-- (1.8.0) a duel with a stake (1.14.0, his word: gone with the PvP until its rework)
		ns.Print(ns.L["The PvP of Curator is being reworked: it comes back in a later version. Its quests stay."])
	elseif cmd == "discovery" or cmd == "decouverte" or cmd == "découverte" or cmd == "entdeckung" or cmd == "descubrimiento"
		or cmd == "descoberta" then
		-- (1.14.0, his word) the discovery of the Paladin Collection Case No. 1 (UI/DiscoveryPage.lua), while it lasts
		local Q = ns.Quests
		if Q and Q.EventOn and Q:EventOn("paladin") and ns.Album.ShowDiscovery then
			ns.Album:ShowDiscovery()
		else
			ns.Print(ns.L["The discovery is over."])
		end
	elseif cmd == "social" or cmd == "guild" or cmd == "guilde" then
		-- (1.14.2: /curator guild, the section of the guild, UI/Social.lua)
		ns.Album:ShowSocial((cmd == "guild" or cmd == "guilde") and "guild" or nil)
	elseif cmd == "minimap" then
		ns.db.minimap.hide = not ns.db.minimap.hide or nil
		if ns.MinimapButton then
			ns.MinimapButton:Update()
		end
		ns.Print(ns.db.minimap.hide and ns.L["Minimap button hidden (/curator minimap to show it)."] or ns.L["Minimap button shown."])
	elseif cmd == "plain" and ns.Admin then
		-- diagnostics: default lighting and facing for the 3D models
		ns.db.plain = not ns.db.plain or nil
		ns.Print("plain = %s", tostring(ns.db.plain and true or false))
		ns.ReframeCards()
		ns.Fire("CHANGED")
	elseif (cmd == "cam" or cmd == "zoom") and ns.Admin then
		-- the framing of the creatures on the cards: /curator zoom 0 (whole) to 1 (the head and
		-- shoulders), /curator cam 1.2 (farther, smaller); without a number, back to the default
		ns.db[cmd] = tonumber(rest)
		ns.Print("%s = %s", cmd, tostring(ns.db[cmd] or "default"))
		ns.ReframeCards()
		ns.Fire("CHANGED")
	elseif cmd == "chat" or cmd == "canal" or cmd == "tchat" or cmd == "kanal" or cmd == "channel" then
		-- (1.12.1) the chat channel of the collectors of the faction (Channel.lua): the chat opened on it, or a
		-- message said there
		if ns.Channel then
			ns.Channel:Open(arg)
		end
	elseif cmd == "save" or cmd == "sauvegarde" or cmd == "sauvegarder" or cmd == "sauver" or cmd == "speichern"
		or cmd == "guardar" or cmd == "salvar" then
		-- (1.12.1) the save at hand: the interface reloads, the game writes the save (UI/Save.lua)
		if ns.Save then
			ns.Save:Now("command")
		end
	elseif cmd == "options" or cmd == "option" or cmd == "settings" or cmd == "config" or cmd == "reglages" or cmd == "réglages"
		or cmd == "parametres" or cmd == "paramètres" then
		-- (1.11.0) the options of Curator, in the options of the game (UI/Options.lua)
		if ns.Options then
			ns.Options:Open()
		end
	elseif cmd == "rubies" or cmd == "ruby" or cmd == "rubis" or cmd == "rubine" or cmd == "rubíes" then
		-- (1.11.0) the rubies: how many, what they come from, what they buy (Rubies.lua)
		if ns.RubiesUI then
			ns.RubiesUI:Tell()
		end
	elseif cmd == "antiquarian" or cmd == "antiquaire" or cmd == "reseller" or cmd == "revendeur" then
		-- (1.12.0) the antiquarian is gone; the reseller is met at the vendors of general goods only (Reseller.lua)
		ns.Print(ns.L["The reseller stands at the vendors of general goods and of trade supplies: talk to one of them to see his cards."])
	elseif cmd == "counter" or cmd == "comptoir" or cmd == "shop" or cmd == "boutique" or cmd == "ledger" or cmd == "registre" then
		-- (1.11.0) the ruby counter, at its tab: the boosters to choose, the ledger (UI/Rubies.lua)
		if ns.RubiesUI then
			local tab = (cmd == "ledger" or cmd == "registre") and "ledger" or "packs"
			ns.RubiesUI:OpenShop(nil, tab)
		end
	elseif cmd == "reset" then
		if rest == "confirm" then
			ns.ResetCollection()
		else
			ns.Print(ns.L["Type /curator reset confirm to empty your collection."])
		end
	else
		Help()
	end
end

-- (1.8.0) The tuning of the models of the cards is the author's (his build): what an older version left of
-- it in a player's save goes (out of the seal).
ns.On("LOADED", function()
	if not ns.Admin and ns.db then
		ns.db.plain, ns.db.cam, ns.db.zoom = nil, nil, nil
	end
end)

-------------------------------------------------------------------------------
-- (1.13.0) An action the game blocked: its red line ("Interface action failed because of an AddOn") names no
-- addon. Said in the chat once a session for each: the addon, the function it tried, and the place of the code
-- that called it (the game tells it while it blocks the action, the calls that led to it still under way). A
-- build being tested says it of every addon; a published one, of Curator only.
-------------------------------------------------------------------------------
ns.blocked = {}

-- (the first place of an addon in the calls under way, past those of the game's own code when there are some; the
-- calls of this watcher, on top of them, left out)
function ns.BlockedAt(stack)
	if type(stack) ~= "string" then
		return nil
	end
	local first
	local top = true
	for line in CuratorOctoFull.Gmatch(stack, "[^\n]+") do
		local addon, file, n = CuratorOctoFull.Match(line, "AddOns[/\\]([^/\\]+)[/\\](.-%.lua)[^:\n]*:(%d+)")
		file = file and string.gsub(file, "\\", "/")
		if not (top and addon == ADDON and file == "Core.lua") then
			top = false
			if addon then
				local at = addon .. "/" .. file .. ":" .. n
				first = first or at
				if not string.find(addon, "^Blizzard_") then
					return at
				end
			end
		end
	end
	return first
end

local blockWatch = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
	pcall(blockWatch.RegisterEvent, blockWatch, e)
end
CuratorOctoFull.SetScript(blockWatch, "OnEvent", function(_, _, addon, fn)
	if (issecretvalue and (issecretvalue(addon) or issecretvalue(fn))) or type(addon) ~= "string" or type(fn) ~= "string" then
		return
	end
	local M = ns.Mandatory
	if addon ~= ADDON and M and M.Armed and M:Armed() then
		return
	end
	local key = addon .. "|" .. fn
	local seen = ns.blocked[key]
	if seen then
		seen.n = seen.n + 1
		return
	end
	local stack
	if type(debugstack) == "function" then
		local ok, s = pcall(debugstack, 2, 40, 0)
		stack = ok and s or nil
	end
	local at = ns.BlockedAt(stack)
	ns.blocked[key] = { n = 1, at = at }
	ns.Print(ns.L["The game blocked an action of %s: %s (%s)."], addon, fn, at or "?")
end)

-- Addon compartment (minimap addon menu)
function Curator_OnAddonCompartmentClick()
	ns.Album:Toggle()
end
