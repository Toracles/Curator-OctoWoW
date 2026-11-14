local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.14.0, after the test of the cases, his word) The discovery of the Paladin Collection Case No. 1: an event of its
-- own, in the place of Hallow's End among the tabs of the album (UI/DiscoveryPage.lua), while it lasts (D.WINDOWS, the
-- time of the server). Its quests (Quests.lua: the boards palDaily and palWeekly) give a case of the collection each,
-- half of them of the paladins (their spells, their deeds, a paladin of the account played), half of them the quests
-- of every day.
-- What makes the quests of the paladins count, here:
-- * the spells of the player (UNIT_SPELLCAST_SUCCEEDED): known by their names, in the language of the client (the
--   names of the spells below, each by the number of its first rank: every rank of a spell has its name);
-- * what the player does as a paladin (Rewards.lua: ACTIVITY, KILLED): the creatures, the undead, the demons, the
--   elites, the quests, the bosses and the dungeons;
-- * and for every class: the undead, the dungeons where the Light fights the Scourge and the Scarlet Crusade, the
--   fallen raised (Redemption, Resurrection, Ancestral Spirit, Rebirth), the cases found, opened, appraised.
-- A quest of a spell comes only when a paladin of the account knows that spell (its spell book read at each login and
-- each time it learns: c.pal, the groups it knows); a quest of a deed of a paladin, when a paladin of the account is
-- of its level (c.class, c.level: kept for each character, Rewards.lua: R:Char).
-------------------------------------------------------------------------------
local D = {}
ns.Discovery = D

D.KEY = "paladin"
D.CASE = "paladin1"
-- when it lasts: from, to (the time of the server). 2026: from October 29 to December 1, 5:00 in Paris.
D.WINDOWS = { { 1793246400, 1796097600 } }

local function Secret(v)
	return issecretvalue and issecretvalue(v)
end

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- The window of the event now (from, to), nil when it does not last.
function D:Window(now)
	now = now or Now()
	for _, w in ipairs(self.WINDOWS) do
		if now >= w[1] and now < w[2] then
			return w
		end
	end
	return nil
end

function D:On(now)
	return self:Window(now) ~= nil
end

-- Over for good: past its last window.
function D:Over(now)
	now = now or Now()
	for _, w in ipairs(self.WINDOWS) do
		if now < w[2] then
			return false
		end
	end
	return true
end

-- How long it still lasts (0: over).
function D:Left(now)
	now = now or Now()
	local w = self:Window(now)
	return w and math.max(0, w[2] - now) or 0
end

-------------------------------------------------------------------------------
-- The spells: each group, the spells it counts (the number of the first rank of each)
-------------------------------------------------------------------------------
D.SPELLS = {
	light = { 635 },                                   -- Holy Light
	flash = { 19750 },                                 -- Flash of Light
	judge = { 20271 },                                 -- Judgement
	-- the seals: of Righteousness, of the Crusader, of Light, of Wisdom, of Justice, of Command
	seal = { 21084, 21082, 20165, 20166, 20164, 20375 },
	hammer = { 853 },                                  -- Hammer of Justice
	exorcism = { 879 },                                -- Exorcism
	turn = { 2878 },                                   -- Turn Undead
	purify = { 1152, 4987 },                           -- Purify, Cleanse
	hands = { 633 },                                   -- Lay on Hands
	shield = { 498, 642 },                             -- Divine Protection, Divine Shield
	-- the blessings: of Might, of Wisdom, of Kings, of Salvation, of Light, of Sanctuary, of Sacrifice, and the greater
	-- ones
	bless = { 19740, 19742, 20217, 1038, 19977, 20911, 6940, 25782, 25894, 25898, 25895, 25890, 25899 },
	protect = { 1022, 1044 },                          -- Blessing of Protection, Blessing of Freedom
	wrath = { 24275 },                                 -- Hammer of Wrath
	holywrath = { 2812 },                              -- Holy Wrath
	consecrate = { 26573 },                            -- Consecration (a talent)
	shock = { 20473 },                                 -- Holy Shock (a talent)
	holyshield = { 20925 },                            -- Holy Shield (a talent)
	steed = { 13819, 23214 },                          -- Summon Warhorse, Summon Charger
	redeem = { 7328 },                                 -- Redemption
	-- (every class that raises the fallen: Resurrection, Ancestral Spirit, Rebirth; Redemption above)
	rez = { 2006, 2008, 20484 },
}
-- the quests each group counts (Quests.lua: KINDS)
D.KINDS = {
	light = { "palLight" }, flash = { "palFlash" }, judge = { "palJudge" }, seal = { "palSeal" }, hammer = { "palHammer" },
	exorcism = { "palExorcism" }, turn = { "palTurn" }, purify = { "palPurify" }, hands = { "palHands" }, shield = { "palShield" },
	bless = { "palBless" }, protect = { "palProtect" }, wrath = { "palWrath" }, holywrath = { "palHolyWrath" },
	consecrate = { "palConsecrate" }, shock = { "palShock" }, holyshield = { "palHolyShield" }, steed = { "palSteed" },
	redeem = { "palRedeem", "rez" }, rez = { "rez" },
}
-- the dungeons where the Light fights (their albums)
D.LIGHT = { scarlet = true, downs = true, stratholme = true, scholomance = true }

-- The name of a spell in the language of the client (nil: the client does not have it).
local function SpellName(id)
	local name
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		name = ok and n or nil
	elseif GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, id)
		name = ok and n or nil
	end
	if type(name) ~= "string" or Secret(name) or name == "" then
		return nil
	end
	return name
end
D.SpellName = SpellName

-- The groups of each name (made once the client has the names of its spells).
function D:Names()
	if self.byName then
		return self.byName
	end
	local by, any = {}, false
	for group, ids in pairs(self.SPELLS) do
		for _, id in ipairs(ids) do
			local name = SpellName(id)
			if name then
				any = true
				by[name] = by[name] or {}
				local list = by[name]
				local seen = false
				for _, g in ipairs(list) do
					seen = seen or g == group
				end
				if not seen then
					list[CuratorOctoFull.Length(list) + 1] = group
				end
			end
		end
	end
	-- (none known yet: asked again later)
	if any then
		self.byName = by
	end
	return by
end

-- The names of the dungeons of the Light, for the text of their quests: those of their albums, in their order.
D.LIGHT_ORDER = { "scarlet", "downs", "stratholme", "scholomance" }
-- (all: "A, B, C and D"; else "A, B, C or D")
function D:LightText(all)
	local names = {}
	for _, key in ipairs(self.LIGHT_ORDER) do
		local s = ns.SeriesByKey and ns.SeriesByKey(key)
		if s then
			names[CuratorOctoFull.Length(names) + 1] = (ns.Collection and ns.Collection.SeriesName and ns.Collection:SeriesName(s)) or s.name
		end
	end
	if CuratorOctoFull.Length(names) == 0 then
		return nil
	elseif CuratorOctoFull.Length(names) == 1 then
		return names[1]
	end
	local last = CuratorOctoFull.Remove(names)
	return string.format(ns.L[all and "%s and %s" or "%s or %s"], table.concat(names, ", "), last)
end

-- (their names in English, when the client does not give them)
D.EN = {
	light = { "Holy Light" }, flash = { "Flash of Light" }, judge = { "Judgement" }, hammer = { "Hammer of Justice" },
	exorcism = { "Exorcism" }, turn = { "Turn Undead" }, purify = { "Purify", "Cleanse" }, hands = { "Lay on Hands" },
	shield = { "Divine Protection", "Divine Shield" }, protect = { "Blessing of Protection", "Blessing of Freedom" },
	wrath = { "Hammer of Wrath" }, holywrath = { "Holy Wrath" }, consecrate = { "Consecration" }, shock = { "Holy Shock" },
	holyshield = { "Holy Shield" }, redeem = { "Redemption" },
}

-- The names of the spells of a group, for the text of its quest: "Holy Light", "Purify or Cleanse" (nil: none).
function D:SpellText(group)
	local ids = self.SPELLS[group] or {}
	local en = self.EN[group] or {}
	local names, seen = {}, {}
	for i, id in ipairs(ids) do
		local name = SpellName(id) or en[i]
		if name and not seen[name] then
			seen[name] = true
			names[CuratorOctoFull.Length(names) + 1] = name
		end
	end
	if CuratorOctoFull.Length(names) == 0 then
		return nil
	elseif CuratorOctoFull.Length(names) == 1 then
		return names[1]
	end
	local last = CuratorOctoFull.Remove(names)
	return string.format(ns.L["%s or %s"], table.concat(names, ", "), last)
end

-- The icon of a quest of a spell: the icon of its first spell (nil: the client does not have it).
function D:SpellIcon(group)
	local ids = self.SPELLS[group]
	local id = ids and ids[1]
	if not id then
		return nil
	end
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, tex = pcall(C_Spell.GetSpellTexture, id)
		if ok and tex and not Secret(tex) then
			return tex
		end
	elseif GetSpellTexture then
		local ok, tex = pcall(GetSpellTexture, id)
		if ok and tex and not Secret(tex) then
			return tex
		end
	end
	return nil
end

-------------------------------------------------------------------------------
-- The characters of the account: their class, their level, what a paladin knows
-------------------------------------------------------------------------------
-- The class of the character played ("PALADIN"...; nil: not known).
function D:Class()
	if not UnitClass then
		return nil
	end
	local ok, _, file = pcall(UnitClass, "player")
	if not ok or type(file) ~= "string" or Secret(file) then
		return nil
	end
	return file
end

function D:IsPaladin()
	return self:Class() == "PALADIN"
end

-- The names of the spells of the spell book of the character played (nil: the client cannot tell).
function D:BookNames()
	local out
	local SB = C_SpellBook
	local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
	if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemName then
		local ok, lines = pcall(SB.GetNumSpellBookSkillLines)
		if ok and type(lines) == "number" and not Secret(lines) then
			out = {}
			for i = 1, lines do
				local ok2, info = pcall(SB.GetSpellBookSkillLineInfo, i)
				if ok2 and type(info) == "table" then
					local first, n = tonumber(info.itemIndexOffset) or 0, tonumber(info.numSpellBookItems) or 0
					for slot = first + 1, first + n do
						local ok3, name = pcall(SB.GetSpellBookItemName, slot, bank)
						if ok3 and type(name) == "string" and not Secret(name) and name ~= "" then
							out[name] = true
						end
					end
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
		local ok, tabs = pcall(GetNumSpellTabs)
		if ok and type(tabs) == "number" then
			out = {}
			for t = 1, tabs do
				local ok2, _, _, first, n = pcall(GetSpellTabInfo, t)
				if ok2 and type(first) == "number" and type(n) == "number" then
					for slot = first + 1, first + n do
						local ok3, name = pcall(GetSpellBookItemName, slot, "spell")
						if ok3 and type(name) == "string" and not Secret(name) and name ~= "" then
							out[name] = true
						end
					end
				end
			end
		end
	end
	return out
end

-- What is kept of the character played: its class, its level; for a paladin, the groups of the spells it knows; for a
-- class that raises the fallen, whether it can (rez).
function D:Keep()
	if not (ns.db and ns.Rewards and ns.Rewards.Char) then
		return
	end
	local c = ns.Rewards:Char()
	local cls = self:Class()
	if cls then
		c.class = cls
	end
	if ns.Rewards.KeepLevel then
		ns.Rewards:KeepLevel()
	end
	local book = self:BookNames()
	if not book then
		return
	end
	local known = {}
	local any = false
	for group, ids in pairs(self.SPELLS) do
		for _, id in ipairs(ids) do
			local name = SpellName(id)
			if name and book[name] then
				known[group] = true
				any = true
			end
		end
	end
	c.pal = (cls == "PALADIN" and any) and known or nil
	c.rez = (known.redeem or known.rez) and true or nil
end

-- The characters of the account (as kept), the one played among them.
local function Chars()
	return (ns.db and type(ns.db.chars) == "table") and ns.db.chars or {}
end

-- The highest level of a paladin of the account (0: none).
function D:PalLevel()
	local best = 0
	for _, c in pairs(Chars()) do
		if type(c) == "table" and c.class == "PALADIN" and type(c.level) == "number" and c.level > best then
			best = c.level
		end
	end
	if self:IsPaladin() then
		local lvl = UnitLevel and UnitLevel("player")
		if type(lvl) == "number" and not Secret(lvl) and lvl > best then
			best = lvl
		end
	end
	return best
end

-- Whether a paladin of the account knows a spell of a group.
function D:PalKnows(group)
	for _, c in pairs(Chars()) do
		if type(c) == "table" and c.class == "PALADIN" and type(c.pal) == "table" and c.pal[group] then
			return true
		end
	end
	return false
end

-- Whether a character of the account raises the fallen.
function D:CanRez()
	for _, c in pairs(Chars()) do
		if type(c) == "table" and c.rez then
			return true
		end
	end
	return false
end

-- (Quests.lua: a quest of the paladins the account can do) A quest of a spell: a paladin who knows it; else a paladin of
-- its level.
function D:CanPal(kind)
	local Q = ns.Quests
	local k = Q and Q.KINDS[kind]
	if not k then
		return false
	end
	if k.spells then
		return self:PalKnows(k.spells)
	end
	return self:PalLevel() >= (k.pal or 1)
end

-------------------------------------------------------------------------------
-- What counts: the quests (Quests.lua), the counters of the achievements (Achievements.lua: the spells of the
-- paladins by their group, stats.pal; the fallen raised, rez; the undead defeated, scourge; the dungeons of the Light
-- completed, lightDone) and the secret ones (their flags: sBubble, sSacrifice, sUndead, sMassRez, sChapel, sCulling,
-- sPatience, sLightDay, sVigil). What a reroll does counts for no achievement (Reroll.lua: RR:Counts).
-------------------------------------------------------------------------------
local function Add(kind, n, arg)
	if ns.Quests then
		ns.Quests:Add(kind, n or 1, arg)
	end
end

local function Counts()
	return ns.db ~= nil and ns.Stats ~= nil and (ns.Reroll == nil or ns.Reroll:Counts())
end

local function Up(key, n)
	local st = ns.Stats()
	st[key] = (tonumber(st[key]) or 0) + (n or 1)
end

local function Flag(key)
	local st = ns.Stats()
	if not st[key] then
		st[key] = true
		if ns.Achievements and ns.Achievements.Queue then
			ns.Achievements:Queue()
		end
	end
end
D.HEARTH = 8690       -- Hearthstone
D.DIVINE_INT = 19752  -- Divine Intervention
D.BUBBLE_HEARTH = 10  -- the seconds between the bubble and the hearthstone
D.MASS_REZ = 60       -- three raised in so many seconds

-- The race of the character played: undead (nil: not known).
local function Undead()
	if not UnitRace then
		return false
	end
	local ok, _, file, id = pcall(UnitRace, "player")
	if not ok then
		return false
	end
	if Secret(file) or Secret(id) then
		return false
	end
	return file == "Scourge" or file == "Undead" or id == 5
end

-- The counters and the secret ones of a spell cast (its groups, its name).
function D:CountSpell(groups, name)
	if not Counts() then
		return
	end
	local st = ns.Stats()
	if type(st.pal) ~= "table" then
		st.pal = {}
	end
	local now = GetTime()
	for _, g in ipairs(groups or {}) do
		if g == "rez" or g == "redeem" then
			Up("rez")
			-- (three raised within a minute)
			local t = self.rezAt or {}
			t[CuratorOctoFull.Length(t) + 1] = now
			while CuratorOctoFull.Length(t) > 3 do
				CuratorOctoFull.Remove(t, 1)
			end
			self.rezAt = t
			if CuratorOctoFull.Length(t) == 3 and t[3] - t[1] <= self.MASS_REZ then
				Flag("sMassRez")
			end
		end
		if g ~= "rez" then
			st.pal[g] = (tonumber(st.pal[g]) or 0) + 1
		end
		if g == "shield" then
			self.bubbleAt = now
		end
		if g == "light" and Undead() then
			Flag("sUndead")
		end
	end
	if name and name == SpellName(self.HEARTH) and self.bubbleAt and now - self.bubbleAt <= self.BUBBLE_HEARTH then
		Flag("sBubble")
	end
	if name and name == SpellName(self.DIVINE_INT) then
		Flag("sSacrifice")
	end
end

-- A spell of the player, cast (once for each cast).
function D:OnSpell(unit, guid, spellID)
	if unit ~= "player" or type(spellID) ~= "number" or Secret(spellID) then
		return
	end
	if guid ~= nil and not Secret(guid) then
		if guid == self.lastCast then
			return
		end
		self.lastCast = guid
	end
	local name = SpellName(spellID)
	local groups = name and self:Names()[name]
	-- (the counters and the secret ones: the hearthstone after a bubble, Divine Intervention among them)
	self:CountSpell(groups, name)
	if not groups then
		return
	end
	local done = {}
	for _, g in ipairs(groups) do
		for _, kind in ipairs(self.KINDS[g] or {}) do
			if not done[kind] then
				done[kind] = true
				Add(kind, 1)
			end
		end
	end
end

-- (Rewards.lua) what the player did: as a paladin, the quests of the paladins; the dungeons of the Light, every class.
ns.On("ACTIVITY", function(kind, n, s)
	n = n or 1
	if D:IsPaladin() then
		if kind == "kill" then
			Add("palKill", n)
		elseif kind == "quest" then
			Add("palQuest", n)
		elseif kind == "dungeonBoss" then
			Add("palBoss", n)
		elseif kind == "dungeonDone" then
			Add("palDungeon", n)
		end
	end
	if type(s) == "table" and D.LIGHT[s.key] then
		if kind == "dungeonBoss" then
			Add("lightBoss", n)
		elseif kind == "dungeonDone" then
			Add("lightDone", n)
			if Counts() then
				Up("lightDone", n)
				-- (the four of them between two daily resets)
				local st = ns.Stats()
				local day = ns.Quests and ns.Quests:ResetKey("day")
				if type(st.lightDay) ~= "table" or st.lightDay.d ~= day then
					st.lightDay = { d = day }
				end
				st.lightDay[s.key] = true
				local all = true
				for key in pairs(D.LIGHT) do
					all = all and st.lightDay[key] == true
				end
				if all then
					Flag("sLightDay")
				end
			end
		end
	end
end)
ns.On("KILLED", function(card, elite, inside, rare)
	local t = type(card) == "table" and card.type or nil
	if t == 6 then
		Add("scourge", 1)
		if Counts() then
			Up("scourge")
		end
	end
	if D:IsPaladin() then
		if t == 6 then
			Add("palUndead", 1)
		elseif t == 3 then
			Add("palDemon", 1)
		end
		-- (31 October, his word: the rares only, no more the elites)
		if rare and not inside then
			Add("palElite", 1)
		end
	end
end)
-- (Cases.lua) the cases found (not those the quests of the discovery give), opened, their cards appraised
ns.On("CASE_DROPPED", function(_, n, how)
	if how ~= "discovery" then
		Add("caseFind", tonumber(n) or 1)
	end
end)
ns.On("CASE_OPENED", function(_, rec)
	Add("caseOpen", 1)
	if not Counts() then
		return
	end
	-- (where it was opened: the Eastern Plaguelands, Stratholme)
	local R = ns.Rewards
	local here = R and R.ZoneSeries and R:ZoneSeries()
	if here and here.key == "eastplague" then
		Flag("sChapel")
	elseif here and here.key == "stratholme" then
		Flag("sCulling")
	end
	-- (ten in a row, nothing above the Rare rank)
	local st = ns.Stats()
	if type(rec) == "table" and (tonumber(rec.r) or 0) <= 1 then
		st.caseRare = (tonumber(st.caseRare) or 0) + 1
		if st.caseRare >= 10 then
			Flag("sPatience")
		end
	else
		st.caseRare = 0
	end
end)
-- (a quest of the discovery claimed between midnight and one in the morning)
ns.On("QUEST_CLAIMED", function(board)
	if type(board) ~= "table" or board.section ~= "discovery" or not Counts() then
		return
	end
	local fmt = date or (os and os.date)
	local t = fmt and fmt("*t")
	if type(t) == "table" and t.hour == 0 then
		Flag("sVigil")
	end
end)
ns.On("CASE_APPRAISED", function()
	Add("caseAppraise", 1)
end)

local f = CreateFrame("Frame")
D.frame = f
f:RegisterEvent("PLAYER_LOGIN")
CuratorOctoFull.SetScript(f, "OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		for _, e in ipairs({ "SPELLS_CHANGED", "PLAYER_LEVEL_UP" }) do
			pcall(f.RegisterEvent, f, e)
		end
		if f.RegisterUnitEvent then
			pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")
		else
			pcall(f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED")
		end
		D:Keep()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		D:OnSpell(unpack(arg, 1, arg.n))
	elseif event == "SPELLS_CHANGED" or event == "PLAYER_LEVEL_UP" then
		-- (a second after the first of them: the spell book changes many times in a row at a login, or when a trainer
		-- teaches; a change after the book was read reads it again)
		if not (CuratorOctoFull.Timer and CuratorOctoFull.Timer.After) then
			D:Keep()
		elseif not D.keeping then
			D.keeping = true
			CuratorOctoFull.Timer.After(1, function()
				D.keeping = nil
				D:Keep()
			end)
		end
	end
end)
