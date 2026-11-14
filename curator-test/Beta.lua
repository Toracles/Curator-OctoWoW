local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- The betas. A beta build (BETA) works until a day set when it is made (LAST_DAY: a week after),
-- then stops: the album no longer opens, nothing more is earned, no trade; the next build is in the
-- channel of the beta. The players who played it carry a mark in their save (db.beta, sealed with
-- it): the achievement Beta tester. A release (BETA false) keeps their collection as it is, and that
-- achievement. The closed beta is over: 1.1.0 to 1.7.0 were betas (1.0.0 was built as a release;
-- 1.4.0 is the first one named Curator, Hoard before); 1.8.0 is a release, and every version after it
-- is mandatory (Mandatory.lua): it no longer needs a day to stop. A build made obsolete is locked as a
-- beta past its day was. (1.8.0) The players who play before WoW Forever comes out get the mark of the
-- pioneers instead (B:MarkPioneer).
-------------------------------------------------------------------------------
-- The last day of a beta: it works until the end of that day (at the time of the player's
-- computer). To make it last longer, change the day here.
local LAST_DAY = { year = 2026, month = 10, day = 21 }

local B = {
	BETA = false,
	UNTIL = time({ year = LAST_DAY.year, month = LAST_DAY.month, day = LAST_DAY.day, hour = 23, min = 59, sec = 59 }),
}
ns.Beta = B

function B:Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- (1.7.0) A save edited outside the game (its seal no longer matches, Core.lua): Curator suspended,
-- locked as below until the collection starts over (UI/Suspended.lua: its window, its button).
function B:Suspended()
	return (ns.db and ns.db.edited) and true or false
end

-- (1.9.1) A player banned for good from Curator (Bans.lua): locked as a suspended collection is, with
-- no way out (its window, UI/Suspended.lua, has no button to start over).
function B:Banned()
	return ns.Bans ~= nil and ns.Bans:Banned()
end

-- (1.14.0, his word) Curator works on WoW Forever only: its client, the version 1.60 and after (16000 to 19999 in the
-- numbers of the interface; Classic Era is 1.15, its 115xx). Elsewhere (Classic Era, Retail) it is locked as a beta past
-- its day: its window says so (UI/Mandatory.lua), nothing is earned. The author's build (UI/Admin.lua) and the test build
-- of Classic Era (EraTest.lua) work everywhere, for his tests.
function B:ForeverClient()
	local toc = GetBuildInfo and CuratorOctoFull.Select(4, GetBuildInfo())
	toc = tonumber(toc) or 0
	return toc >= 16000 and toc < 20000
end

function B:Elsewhere()
	return not self:ForeverClient() and ns.Admin == nil and not ns.TEST_BUILD
end

-- A beta build past its day, a build made obsolete by a mandatory update (Mandatory.lua), a collection
-- suspended, or a player banned; (1.14.0) or a game that is not WoW Forever.
function B:Over()
	return (self.BETA and self:Now() >= self.UNTIL) or (ns.Mandatory ~= nil and ns.Mandatory:Locked()) or self:Suspended() or self:Banned()
		or self:Elsewhere()
end

-- (1.14.0) Not WoW Forever: said in its window each time something is asked of this copy, and in the chat and a toast
-- (once a minute at most).
function B:TellElsewhere()
	local now = (GetTime and GetTime()) or 0
	if not self.toldElsewhere or now - self.toldElsewhere >= 60 then
		self.toldElsewhere = now
		ns.Print(L["Curator is made for WoW Forever: it does not work in this version of the game, and nothing is earned here."])
		if ns.Toast then
			ns.Toast:Push({
				title = L["Only on WoW Forever"],
				name = "Curator " .. ns.version,
				color = { 1, 0.55, 0.25 },
				line = L["Your collection waits for you on WoW Forever."],
				tex = { "Beta" },
				sound = ns.SND.close,
			})
		end
	end
	if ns.MandatoryWindow then
		ns.MandatoryWindow:ShowElsewhere()
	end
end

-- What is left of it (seconds); nil past it, or for the release.
function B:Left()
	if not self.BETA then
		return nil
	end
	local left = self.UNTIL - self:Now()
	return left > 0 and left or nil
end

-- "0.23.0 beta", "1.0.0".
function B:VersionText()
	return self.BETA and string.format(L["%s beta"], ns.version) or ns.version
end

-- Something asked of a build past its day: no, and why (in the chat and a toast, once a minute at
-- most).
function B:Blocked()
	if not self:Over() then
		return false
	end
	-- (suspended: its window says why, and how to start over; banned: the same window, for good)
	if self:Suspended() or self:Banned() then
		if ns.SuspendedWindow then
			ns.SuspendedWindow:Tell()
		end
		return true
	end
	-- (obsolete: the window of the mandatory update says it)
	if ns.Mandatory and ns.Mandatory:Locked() then
		ns.Mandatory:Tell()
		return true
	end
	-- (1.14.0: not WoW Forever, its own window)
	if self:Elsewhere() then
		self:TellElsewhere()
		return true
	end
	local now = (GetTime and GetTime()) or 0
	if not self.told or now - self.told > 60 then
		self.told = now
		ns.Print(L["This beta version of Curator has expired. Thank you for testing! The next one is in the beta channel."])
		if ns.Toast then
			ns.Toast:Push({
				title = L["Beta over"],
				name = "Curator " .. ns.version,
				color = { 1, 0.55, 0.25 },
				line = L["Thank you for testing! The next one is in the beta channel."],
				tex = { "Beta" },
				sound = ns.SND.close,
			})
		end
	end
	return true
end

-- (1.8.0) The pioneers: the collectors who play Curator before WoW Forever comes out (November 4, 2026,
-- by the time of the server). A mark in the save (db.pioneer, sealed with it), then the achievement
-- Pioneer, kept when the collection starts over (Core.lua). Played after that moment: nothing.
B.PIONEER_UNTIL = 1793750400 -- 2026-11-04 00:00 UTC

function B:Pioneer()
	return ns.db ~= nil and ns.db.pioneer ~= nil
end

-- The mark, the first time (true when it comes now).
function B:MarkPioneer()
	local db = ns.db
	if not db or db.pioneer or self:Now() >= self.PIONEER_UNTIL or self:Over() then
		return false
	end
	db.pioneer = { t = self:Now(), v = ns.version }
	ns.Print(L["Thank you for playing Curator before WoW Forever comes out! You are one of its Pioneers: the achievement stays with your collection."])
	if ns.Achievements then
		ns.Achievements:Queue(3)
	end
	return true
end

ns.On("LOGIN", function()
	local db = ns.db
	if not db then
		return
	end
	-- (suspended or banned: its own window comes at the login, UI/Suspended.lua; no mark of the beta, nor
	-- of the pioneers)
	if B:Suspended() or B:Banned() then
		return
	end
	-- (1.14.0: not WoW Forever, its window a moment after the login; an update missed shows its own, Mandatory.lua)
	if B:Elsewhere() then
		ns.Delay(4, function()
			if not (ns.Mandatory and ns.Mandatory:Locked()) then
				B:TellElsewhere()
			end
		end, B)
		return
	end
	B:MarkPioneer()
	if not B.BETA then
		return
	end
	if B:Over() then
		B:Blocked()
		return
	end
	-- (a tester: the mark, then the achievement, once the first check of the achievements is done)
	if not db.beta then
		db.beta = { t = B:Now(), v = ns.version }
		ns.Print(L["Thank you for testing Curator! At the release, you keep your collection and your Beta tester achievement."])
		if ns.Achievements then
			ns.Achievements:Queue(3)
		end
	end
	ns.Print(L["Beta of Curator %s: this version still works for %s."], ns.version, ns.Duration(B:Left()))
end)

-------------------------------------------------------------------------------
-- A newer version seen on another player (their profile says which they play): told once.
-------------------------------------------------------------------------------
local function Parts(v)
	local a, b, c = CuratorOctoFull.Match(tostring(v or ""), "^(%d+)%.(%d+)%.?(%d*)$")
	return tonumber(a), tonumber(b), tonumber(c) or 0
end

-- v newer than than.
function B.Newer(v, than)
	local a1, b1, c1 = Parts(v)
	local a2, b2, c2 = Parts(than)
	if not (a1 and a2) then
		return false
	end
	if a1 ~= a2 then
		return a1 > a2
	elseif b1 ~= b2 then
		return b1 > b2
	end
	return c1 > c2
end

-- (told once a session)
local function Seen(ver)
	if B.toldVersion or not (ver and B.Newer(ver, ns.version)) then
		return
	end
	B.toldVersion = ver
	local line = B.BETA and L["A newer beta of Curator is out (%s): get it in the beta channel."] or L["A newer version of Curator is out (%s): update yours."]
	ns.Print(line, ver)
	if ns.Toast then
		ns.Toast:Push({
			title = L["New version"],
			name = "Curator " .. ver,
			color = { 1, 0.82, 0 },
			line = B.BETA and L["Get it in the beta channel."] or L["Update yours."],
			tex = { "Icon" },
			sound = ns.SND.questDone,
		})
	end
end

ns.On("PLAYER_INFO", function(name)
	local i = ns.Guild and name and ns.Guild:Profile(name)
	if i then
		Seen(i.ver)
	end
end)

-- (the hello of a player on the channel of the players with Curator: Presence.lua)
ns.On("PRESENCE", function(_, p)
	Seen(p and p.ver)
end)
