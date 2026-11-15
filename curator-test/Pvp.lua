local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.8.0) The PvP of the collector. (1.14.0, after the test of the cases, his word: "everything of the PvP goes, a
-- great rework comes with 1.15.0; only its quests stay, for their rewards".) The trophies, their certification at a
-- battlemaster, the album of the combatants and those of the battlegrounds, the war board (the pay, the bounties, the
-- wanted poster), the revenges, the nemesis, the exploits, the card of the collector, the front of the collectors and
-- the duels at stake are gone (what they kept, db.pvp, db.duels: emptied once). What stays, for the quests of PvP
-- (Quests.lua): each honorable kill (the message of the game), the player defeated as the game showed him (his race,
-- his class, his level, his rank: seen on his nameplate, as a target or under the mouse), where it was made (a
-- battleground or the world), told to the quests (PVP_KILL); the battleground the player is in; the names of the
-- races and the classes.
-------------------------------------------------------------------------------
local P = { seen = {} }
ns.Pvp = P

P.RANKS = 14
P.FACTION = 2800 -- the faction of the ranks of PvP of the game (its renown: the rank, 0 to 14)
P.SEEN_KEEP = 600 -- the seconds a player seen is remembered for his kill
-- the classes of each race of each faction, as OctoWoW made them: the classic ones, its new ones (the human
-- hunter, the dwarf shaman, the gnome priest, the orc mage, the undead paladin, the troll warlock), and the Skyborne
-- (race 95: the High-Order of the Alliance, the Windshapers of the Horde, each their classes)
P.SKYBORNE = 95
P.RACE_CLASSES = {
	Alliance = {
		[1] = { 1, 2, 3, 4, 5, 8, 9 }, -- human: warrior, paladin, hunter, rogue, priest, mage, warlock
		[3] = { 1, 2, 3, 4, 5, 7 }, -- dwarf: warrior, paladin, hunter, rogue, priest, shaman
		[4] = { 1, 3, 4, 5, 11 }, -- night elf: warrior, hunter, rogue, priest, druid
		[7] = { 1, 4, 5, 8, 9 }, -- gnome: warrior, rogue, priest, mage, warlock
		[95] = { 1, 3, 4, 8, 11 }, -- skyborne (High-Order): warrior, hunter, rogue, mage, druid
	},
	Horde = {
		[2] = { 1, 3, 4, 7, 8, 9 }, -- orc: warrior, hunter, rogue, shaman, mage, warlock
		[5] = { 1, 2, 4, 5, 8, 9 }, -- undead: warrior, paladin, rogue, priest, mage, warlock
		[6] = { 1, 3, 7, 11 }, -- tauren: warrior, hunter, shaman, druid
		[8] = { 1, 3, 4, 5, 7, 8, 9 }, -- troll: warrior, hunter, rogue, priest, shaman, mage, warlock
		[95] = { 1, 3, 4, 7, 11 }, -- skyborne (Windshapers): warrior, hunter, rogue, shaman, druid
	},
}
-- (the exploits of the battlegrounds, gone: none, for what still asks)
P.FEATS, P.FEAT_BY = {}, {}
-- the races of each faction (the races of the enemy: those of the other one; the Skyborne in both)
P.RACES = { Alliance = { 1, 3, 4, 7, 95 }, Horde = { 2, 5, 6, 8, 95 } }
-- the classes of each faction (in OctoWoW, every class in both: the paladins of the undead, the shamans
-- of the dwarves)
P.CLASSES = { Alliance = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }, Horde = { 1, 2, 3, 4, 5, 7, 8, 9, 11 } }
-- the battlegrounds (their instance)
P.BG = { [489] = "wsg", [529] = "ab", [30] = "av" }
P.BG_ORDER = { "wsg", "ab", "av" }
P.BG_ID = { wsg = 489, ab = 529, av = 30 }

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-------------------------------------------------------------------------------
-- The faction, the ranks
-------------------------------------------------------------------------------
function P:Faction()
	local f = UnitFactionGroup and UnitFactionGroup("player")
	if Secret(f) then
		return nil
	end
	return (f == "Alliance" or f == "Horde") and f or nil
end

-- The faction of a race (the Skyborne, of both: the faction known of him, hint; nil: not known).
function P:FactionOfRace(race, hint)
	if race == self.SKYBORNE then
		return (hint == "Alliance" or hint == "Horde") and hint or nil
	end
	for _, f in ipairs({ "Alliance", "Horde" }) do
		for _, r in ipairs(self.RACES[f]) do
			if r == race then
				return f
			end
		end
	end
	return nil
end

function P:Enemy()
	local f = self:Faction()
	return (f == "Alliance" and "Horde") or (f == "Horde" and "Alliance") or nil
end

-- The rank of a title of the game (0: none it knows).
function P:RankOf(title)
	if type(title) ~= "string" or Secret(title) or title == "" then
		return 0
	end
	if not self.titles then
		local t = {}
		for r = 1, self.RANKS do
			for _, side in ipairs({ 0, 1 }) do
				for _, suffix in ipairs({ "", "_FEMALE" }) do
					local v = rawget(_G, string.format(("PVP_RANK_%d_%d%s"), 4 + r, side, suffix))
					if type(v) == "string" and v ~= "" then
						t[v] = r
					end
				end
			end
		end
		self.titles = t
	end
	return self.titles[title] or 0
end

-- The rank in the name of a player as the game shows it with his title ("Sergeant Thrall": 3).
function P:RankInName(pvpName, name)
	if type(pvpName) ~= "string" or Secret(pvpName) or type(name) ~= "string" then
		return 0
	end
	local i = string.find(pvpName, name, 1, true)
	if not i or i <= 1 then
		return 0
	end
	local title = string.gsub(string.sub(pvpName, 1, i - 1), "%s+$", "")
	return self:RankOf(title)
end

-------------------------------------------------------------------------------
-- The enemies seen: their race, their class, their level, their rank (for the quests of their kills)
-------------------------------------------------------------------------------
local function Get(fn, ...)
	if not fn then
		return nil
	end
	local ok, a, b, c = pcall(fn, unpack(arg, 1, arg.n))
	if not ok then
		return nil
	end
	return a, b, c
end

-- The short name of a player (without his realm).
local function Short(name)
	return type(name) == "string" and (string.gsub(name, "%-.*$", "")) or name
end
P.Short = Short

-- (1.13.1) The first name of a player, to know them by it: "Name" of "Name-Realm"; on OctoWoW, "First" of
-- "First-Surname" and of "First Surname", as the game writes it in its lines and its score.
local function First(name)
	return type(name) == "string" and (CuratorOctoFull.Match(name, "^%s*([^%s%-]+)") or name) or name
end

-- A player of the other faction, as the game shows him (unit: his nameplate, the target, the unit under the mouse):
-- remembered a while, for his kill (nothing kept in the save).
function P:See(unit)
	if not unit then
		return
	end
	local exists = Get(UnitExists, unit)
	if not exists or Secret(exists) then
		return
	end
	local player = Get(UnitIsPlayer, unit)
	if not player or Secret(player) then
		return
	end
	local enemy = Get(UnitIsEnemy, "player", unit)
	if not enemy or Secret(enemy) then
		return
	end
	local name = Get(UnitName, unit)
	if type(name) ~= "string" or Secret(name) or name == "" or name == rawget(_G, "UNKNOWNOBJECT") then
		return
	end
	local _, _, race = Get(UnitRace, unit)
	local _, _, cls = Get(UnitClass, unit)
	local lvl = Get(UnitLevel, unit)
	local pvpName = Get(UnitPVPName, unit)
	self.seen[name] = {
		race = (type(race) == "number" and not Secret(race)) and race or nil,
		cls = (type(cls) == "number" and not Secret(cls)) and cls or nil,
		lvl = (type(lvl) == "number" and not Secret(lvl) and lvl > 0) and lvl or nil,
		r = self:RankInName(pvpName, name),
		t = Now(),
	}
	-- (the oldest forgotten, now and then)
	self.sawN = (self.sawN or 0) + 1
	if CuratorOctoFull.Mod(self.sawN , 50) == 0 then
		local now = Now()
		for n, e in pairs(self.seen) do
			if now - (tonumber(e.t) or 0) > self.SEEN_KEEP then
				self.seen[n] = nil
			end
		end
	end
end

-- What is known of a player defeated (by his name).
function P:Known(name)
	return self.seen[name] or self.seen[Short(name)] or self.seen[First(name)] or nil
end

-------------------------------------------------------------------------------
-- The honorable kills
-------------------------------------------------------------------------------
-- The messages of the game for an honorable kill, as patterns: { pattern, has a rank }.
local function Pattern(fmt)
	-- (its magic letters as letters; its % left as they are, then %s and %d caught)
	local p = string.gsub(fmt, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
	p = string.gsub(string.gsub(p, "%%s", "(.-)"), "%%d", "(%%d+)")
	return "^" .. p .. "$"
end

function P:Patterns()
	if not self.patterns then
		local list = {}
		for _, k in ipairs({ "COMBATLOG_HONORGAIN_EXHAUSTION1", "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1", "COMBATLOG_HONORGAIN_NO_RANK" }) do
			local fmt = rawget(_G, k)
			if type(fmt) == "string" and string.find(fmt, "%s", 1, true) then
				list[CuratorOctoFull.Length(list) + 1] = { Pattern(fmt), not string.find(k, "NO_RANK", 1, true) }
			end
		end
		self.patterns = list
	end
	return self.patterns
end

-- A message of honor: the player defeated and his rank (nil: not an honorable kill).
function P:Parse(text)
	if type(text) ~= "string" or Secret(text) then
		return nil
	end
	for _, p in ipairs(self:Patterns()) do
		local a, b = CuratorOctoFull.Match(text, p[1])
		if a then
			if p[2] then
				return a, self:RankOf(b)
			end
			return a, 0
		end
	end
	return nil
end

-- The battleground the player is in ("wsg", "ab", "av"; nil: none).
function P:Battleground()
	if not GetInstanceInfo then
		return nil
	end
	local ok, _, kind, _, _, _, _, _, id = pcall(GetInstanceInfo)
	if ok and kind == "pvp" and type(id) == "number" and not Secret(id) then
		return self.BG[id]
	end
	return nil
end

-- An honorable kill: what the game showed of the player defeated, where it was made, told to the quests (PVP_KILL:
-- n his name, r his rank, race, cls, lvl, z the battleground, nil in the world).
function P:Kill(name, rank)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local e = self:Known(name) or {}
	local t = { n = name, r = math.max(rank or 0, e.r or 0), race = e.race, cls = e.cls, lvl = e.lvl, z = self:Battleground(), t = Now() }
	ns.Fire("PVP_KILL", t)
	return t
end

function P:OnHonor(text)
	local name, rank = self:Parse(text)
	if name then
		return self:Kill(name, rank)
	end
end

-------------------------------------------------------------------------------
-- (the card of the collector, gone: none to show, none read from the others)
-------------------------------------------------------------------------------
function P:MyCode()
	return nil
end

function P.ParseCode()
	return nil
end

-------------------------------------------------------------------------------
-- The names of the races and the classes, in the language of the game
-------------------------------------------------------------------------------
local RACE_EN = { [1] = "Human", [2] = "Orc", [3] = "Dwarf", [4] = "Night Elf", [5] = "Undead", [6] = "Tauren", [7] = "Gnome", [8] = "Troll", [95] = "Skyborne" }
local CLASS_EN = { [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue", [5] = "Priest", [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid" }
local CLASS_FILE = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST", [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }
P.CLASS_FILE = CLASS_FILE

function P:RaceName(race)
	if not race then
		return nil
	end
	local C = C_CreatureInfo
	if C and C.GetRaceInfo then
		local ok, info = pcall(C.GetRaceInfo, race)
		if ok and type(info) == "table" and type(info.raceName) == "string" and info.raceName ~= "" then
			return info.raceName
		end
	end
	return RACE_EN[race]
end

function P:ClassName(cls, female)
	if not cls then
		return nil
	end
	local file = CLASS_FILE[cls]
	local fem = rawget(_G, "LOCALIZED_CLASS_NAMES_FEMALE")
	if female and file and type(fem) == "table" and type(fem[file]) == "string" then
		return fem[file]
	end
	local C = C_CreatureInfo
	if C and C.GetClassInfo then
		local ok, info = pcall(C.GetClassInfo, cls)
		if ok and type(info) == "table" and type(info.className) == "string" and info.className ~= "" then
			return info.className
		end
	end
	local male = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
	if file and type(male) == "table" and type(male[file]) == "string" then
		return male[file]
	end
	return CLASS_EN[cls]
end

-------------------------------------------------------------------------------
-- Wiring
-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(events, "OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "CHAT_MSG_COMBAT_HONOR_GAIN", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED" }) do
			pcall(self.RegisterEvent, self, e)
		end
	elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
		P:OnHonor((unpack(arg, 1, arg.n)))
	elseif event == "PLAYER_TARGET_CHANGED" then
		P:See("target")
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		P:See("mouseover")
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		P:See((unpack(arg, 1, arg.n)))
	end
end)

-- (1.14.0, his word: the PvP of before gone, what it kept emptied once: its trophies, its cards, its war board, its
-- front, the duels at stake; the quests of PvP keep theirs, Quests.lua)
ns.On("LOADED", function()
	local db = ns.db
	if not db or db.pvpGone then
		return
	end
	db.pvpGone = 1
	db.pvp, db.duels = nil, nil
end)
