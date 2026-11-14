local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0) The cards of a case of a collection of the month (Data/Crate*.lua: the Paladin Collection, its case No. 1), as the
-- opening of a case shows them (UI/Crate.lua, UI/CrateCard.lua). Besides the weapons of legend of the priceless rank
-- (UI/Crate.lua: CR.WEAPONS), three kinds of cards:
-- * a spell (Rare): its icon, its name and what it does, in the language of the game (asked for when the game does not
--   have it yet); its sound: the one of its cast, then the one of what it does;
-- * a figure of the game (Restricted: the masters of the capitals; Classified: the great figures): its creature, alive;
--   its name and its title in the language of the game (QuestieDB); where it is; its voice;
-- * an armour (Covert): the character of the player wearing it, turning; its name (the game's), where it comes from;
--   the sound of heavy metal put down.
-- Each card is an entry: { kind ("spell", "npc", "set"), key (its own in the case), def (the case) } and what its kind
-- needs.
-- (1.14.0, the Paladin collection redone by its author) A card may come with its picture (pic: Media/<pic>, the whole
-- card under its frame, UI/CrateCard.lua) and the part of it the tiles of the case show (tile: { its middle from its top,
-- 0 to 1; how much of its width }): a figure of another time of the game then (no creature of its own in it: its name and
-- its title from the case, its voice a voice of the game), a figure of the covert rank (covert: the same as the heroes).
-------------------------------------------------------------------------------
local CI = {}
ns.CrateItems = CI

-- the trees of the talents of the paladin, in the order of the cards of its spells
CI.TREES = { "Holy", "Protection", "Retribution" }
-- the seconds between the sound of the cast of a spell and the one of what it does
CI.EFFECT_DELAY = 0.42
-- the sound of an armour: heavy metal picked up, then put down
CI.ARMOUR = { { 1190 }, { 1207 } }
CI.ARMOUR_DELAY = 0.35
-- (the places when the game cannot name them: English)
local MAPS = { [1453] = "Stormwind City", [1455] = "Ironforge", [1422] = "Western Plaguelands", [1423] = "Eastern Plaguelands" }
local INSTANCES = {
	[189] = "Scarlet Monastery", [309] = "Zul'Gurub", [329] = "Stratholme", [409] = "Molten Core", [469] = "Blackwing Lair",
	[531] = "Temple of Ahn'Qiraj", [533] = "Naxxramas",
}

local function Safe(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b, c = pcall(fn, unpack(arg, 1, arg.n))
	if ok then
		return a, b, c
	end
end

-- The cards of a case (its key: Data/Crate*.lua), by rank (1 to 4), in the order of its data; made once. Nil: no such
-- case.
function CI:Case(key)
	self.cases = self.cases or {}
	local c = self.cases[key]
	if c then
		return c
	end
	local def = ns.Crates and ns.Crates[key]
	if type(def) ~= "table" then
		return nil
	end
	c = { def = def, key = key, {}, {}, {}, {} }
	for _, s in ipairs(def.spells or {}) do
		local t = c[1]
		t[CuratorOctoFull.Length(t) + 1] = { kind = "spell", key = "s" .. s[1], id = s[1], tree = s[2], cast = s[3], effect = s[4], en = s[5], def = def,
			pic = s.pic, tile = s.tile }
	end
	for _, m in ipairs(def.masters or {}) do
		local t = c[2]
		t[CuratorOctoFull.Length(t) + 1] = { kind = "npc", key = "n" .. m[1], npc = m[1], display = m[2], sound = m[3], map = m[4], master = true, def = def,
			pic = m.pic, tile = m.tile }
	end
	-- (the heroes, the classified rank; the figures of the covert rank, as they are; film: its entrance, UI/CaseFilm.lua)
	for r, list in pairs({ [3] = def.heroes, [4] = def.covert }) do
		for _, h in ipairs(list or {}) do
			local t = c[r]
			t[CuratorOctoFull.Length(t) + 1] = { kind = "npc", key = "n" .. h[1], npc = h[1], display = h[2], sound = h[3], map = h.map, inst = h.inst,
				def = def, pic = h.pic, tile = h.tile, film = h.film }
		end
	end
	for _, s in ipairs(def.sets or {}) do
		local t = c[4]
		t[CuratorOctoFull.Length(t) + 1] = { kind = "set", key = "a" .. s[1], id = s[1], items = s[2], where = s[3], side = s[4], en = s[5], chest = s[6], def = def }
	end
	self.cases[key] = c
	return c
end

-------------------------------------------------------------------------------
-- Its words
-------------------------------------------------------------------------------
local function SpellName(id)
	if C_Spell and C_Spell.GetSpellName then
		local n = Safe(C_Spell.GetSpellName, id)
		if type(n) == "string" and n ~= "" then
			return n
		end
	end
	if GetSpellInfo then
		local n = Safe(GetSpellInfo, id)
		if type(n) == "string" and n ~= "" then
			return n
		end
	end
end

local function SetName(id)
	local n = Safe(C_Item and C_Item.GetItemSetInfo or GetItemSetInfo, id)
	if type(n) == "string" and n ~= "" then
		return n
	end
end

-- (the game names the instances by their map once GetRealZoneText takes one: two of them told apart)
local realZone
local function InstanceName(id)
	if realZone == nil then
		local a, b = Safe(GetRealZoneText, 36), Safe(GetRealZoneText, 34)
		realZone = type(a) == "string" and type(b) == "string" and a ~= "" and b ~= "" and a ~= b
	end
	if realZone then
		local n = Safe(GetRealZoneText, id)
		if type(n) == "string" and n ~= "" then
			return n
		end
	end
end

-- An album of the game for that place (its name in this language: Collection.lua), else nil.
local function Album(field, id)
	for _, s in ipairs(ns.Series or {}) do
		if s[field] == id then
			return s
		end
	end
end

-- A place by its uiMap (map) or its instance (inst), in the language of the game.
function CI:PlaceName(map, inst)
	local C = ns.Collection
	if inst then
		local s = Album("instance", inst)
		if s and C then
			return C:SeriesName(s)
		end
		return InstanceName(inst) or INSTANCES[inst] or "?"
	end
	if map then
		local s = Album("map", map)
		if s and C then
			return C:SeriesName(s)
		end
		if C_Map and C_Map.GetMapInfo then
			local info = Safe(C_Map.GetMapInfo, map)
			if type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
				return info.name
			end
		end
		return MAPS[map] or "?"
	end
end

-- Its name in the language of the game (a spell, an armour the game does not know yet: its English name).
function CI:Name(e)
	if not e then
		return "?"
	end
	if e.kind == "spell" then
		return SpellName(e.id) or e.en or "?"
	elseif e.kind == "npc" then
		local names = e.def.names or {}
		local own = names[ns.locale]
		return (own and own[e.npc]) or (names.enUS and names.enUS[e.npc]) or "?"
	elseif e.kind == "set" then
		return SetName(e.id) or e.en or "?"
	end
	return "?"
end

-- The title of a figure (nil: none).
function CI:Title(e)
	if not (e and e.kind == "npc") then
		return nil
	end
	local subs = e.def.subs or {}
	local own = subs[ns.locale]
	return (own and own[e.npc]) or (subs.enUS and subs.enUS[e.npc]) or nil
end

-- The tree of a spell (Holy, Protection, Retribution), in this language.
function CI:Tree(e)
	local t = e and self.TREES[e.tree or 0]
	return t and L[t] or nil
end

-- Where an armour comes from: its instance, the dungeon sets, the honour of a side.
function CI:Source(e)
	local w = e.where
	if w == "d1" then
		return L["Dungeon set 1"]
	elseif w == "d2" then
		return L["Dungeon set 2"]
	elseif w == "pvp" then
		local side = (e.side == "A" and (FACTION_ALLIANCE or "Alliance")) or (e.side == "H" and (FACTION_HORDE or "Horde")) or nil
		return side and (L["PvP"] .. "  ·  " .. side) or L["PvP"]
	elseif type(w) == "number" then
		return self:PlaceName(nil, w)
	end
	return ""
end

-- What is said under it in what the case holds: the tree of a spell, the city of a master, where a figure is, where
-- an armour comes from.
function CI:Sub(e)
	if not e then
		return ""
	end
	if e.kind == "spell" then
		return self:Tree(e) or ""
	elseif e.kind == "npc" then
		-- (a figure of another time of the game: its title)
		if not (e.map or e.inst) then
			return self:Title(e) or ""
		end
		return self:PlaceName(e.map, e.inst) or ""
	elseif e.kind == "set" then
		return self:Source(e) or ""
	end
	return ""
end

-- What is said of it when it is inspected or comes out: a spell of the paladin and its tree, a master of the paladins
-- in his city, the title of a figure and where it is, where an armour comes from.
function CI:From(e)
	if not e then
		return ""
	end
	if e.kind == "spell" then
		return string.format(L["Paladin spell  ·  %s"], self:Tree(e) or "")
	elseif e.kind == "npc" then
		local title = self:Title(e)
		if not (e.map or e.inst) then
			return title or ""
		end
		local place = self:PlaceName(e.map, e.inst) or ""
		if e.master then
			return string.format(L["Master of the paladins in %s"], place)
		end
		return title and (title .. "  ·  " .. place) or place
	elseif e.kind == "set" then
		return self:Source(e) or ""
	end
	return ""
end

-- (1.14.0, the Paladin collection redone) Its picture (a texture of the addon; nil: none, the card shows what the game
-- gives of it), and the part of it a tile of the case shows (tw, th: its width and its height in points): left, right,
-- top, bottom of its texture. (A picture is the shape of the art of its card: 492 x 697 points.)
local ART_W, ART_H = 492, 697
function CI:Pic(e)
	return e and e.pic and (ns.MEDIA .. e.pic) or nil
end

function CI.TileCoords(tile, tw, th, spell)
	local t = type(tile) == "table" and tile or {}
	local cy = tonumber(t[1]) or (spell and 0.5 or 0.36)
	local zw = math.max(0.2, math.min(1, tonumber(t[2]) or (spell and 1 or 0.8)))
	local zh = zw * ART_W / ART_H * (th / math.max(1, tw))
	if zh > 1 then
		zw, zh = zw / zh, 1
	end
	local cx = tonumber(t[3]) or 0.5
	local u0 = math.max(0, math.min(1 - zw, cx - zw / 2))
	local v0 = math.max(0, math.min(1 - zh, cy - zh / 2))
	return u0, u0 + zw, v0, v0 + zh
end

-------------------------------------------------------------------------------
-- What the game gives of it
-------------------------------------------------------------------------------
-- Its icon (a texture or a file of the game; nil: none, a figure shows its portrait).
function CI:Icon(e)
	if not e then
		return nil
	end
	if e.kind == "spell" then
		local icon = C_Spell and C_Spell.GetSpellTexture and Safe(C_Spell.GetSpellTexture, e.id)
		if not icon and GetSpellTexture then
			icon = Safe(GetSpellTexture, e.id)
		end
		return icon
	elseif e.kind == "set" then
		local id = e.chest or (e.items and e.items[1])
		local icon = id and C_Item and C_Item.GetItemIconByID and Safe(C_Item.GetItemIconByID, id)
		if not icon and id and GetItemIcon then
			icon = Safe(GetItemIcon, id)
		end
		return icon
	end
	return nil
end

-- What a spell does, in the language of the game (nil: not known yet, asked for; "" when it says nothing).
function CI:Description(e)
	if not (e and e.kind == "spell") then
		return nil
	end
	local text
	if C_Spell and C_Spell.GetSpellDescription then
		text = Safe(C_Spell.GetSpellDescription, e.id)
	elseif GetSpellDescription then
		text = Safe(GetSpellDescription, e.id)
	end
	if type(text) == "string" and text ~= "" then
		return text
	end
	self:Ask(e)
	return nil
end

-- The game asked for what it does not have yet: a spell, the pieces of an armour.
function CI:Ask(e)
	if not e then
		return
	end
	if e.kind == "spell" then
		if C_Spell and C_Spell.RequestLoadSpellData then
			Safe(C_Spell.RequestLoadSpellData, e.id)
		end
	elseif e.kind == "set" and C_Item and C_Item.RequestLoadItemDataByID then
		for _, id in ipairs(e.items or {}) do
			Safe(C_Item.RequestLoadItemDataByID, id)
		end
	end
end

-- Its sound: a spell, its cast then what it does (only what it does when it has no cast); a figure, its voice; an
-- armour, heavy metal. Owner: what cancels the second sound (ns.CancelOwner).
function CI:Play(e, owner)
	if not e or ns.db and ns.db.mute then
		return
	end
	if e.kind == "spell" then
		local cast, effect = e.cast, e.effect
		local played = cast ~= 0 and ns.Play(cast)
		if effect ~= 0 then
			if played then
				ns.Delay(self.EFFECT_DELAY, function()
					ns.Play(effect)
				end, owner)
			else
				ns.Play(effect)
			end
		end
	elseif e.kind == "npc" then
		ns.Play(e.sound)
	elseif e.kind == "set" then
		ns.Play(self.ARMOUR[1])
		ns.Delay(self.ARMOUR_DELAY, function()
			ns.Play(self.ARMOUR[2])
		end, owner)
	end
end

-------------------------------------------------------------------------------
-- (the test of the author: /curator test caisse tirion, secret redemption...) A card of a case by a word of its name
-- (its English one or the one of this language, plain), in a rank or in all of them: the entry, its rank, and whether
-- its name is that word (else it holds it).
-------------------------------------------------------------------------------
function CI:Find(key, word, tier)
	local c = self:Case(key)
	local Plain = ns.Plain
	if not (c and Plain and word and word ~= "") then
		return nil
	end
	local q = Plain(word)
	local best, bestTier
	for r = 1, 4 do
		if not tier or tier == r then
			for _, e in ipairs(c[r]) do
				local names = { Plain(self:Name(e)) }
				if e.en then
					names[CuratorOctoFull.Length(names) + 1] = Plain(e.en)
				end
				if e.kind == "npc" then
					names[CuratorOctoFull.Length(names) + 1] = Plain((e.def.names.enUS or {})[e.npc] or "")
				end
				for _, n in ipairs(names) do
					if n == q then
						return e, r, true
					elseif not best and n ~= "" and string.find(n, q, 1, true) then
						best, bestTier = e, r
					end
				end
			end
		end
	end
	return best, bestTier, false
end
