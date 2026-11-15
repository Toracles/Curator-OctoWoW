local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
local B = {}
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

-- (1.14.0, his word) Curator works on OctoWoW only: its client, the version 1.60 and after (16000 to 19999 in the
-- numbers of the interface; Classic Era is 1.15, its 115xx). Elsewhere (Classic Era, Retail) it is locked as a beta past
-- its day: its window says so (UI/Mandatory.lua), nothing is earned. The author's build (UI/Admin.lua) and the test build
-- of Classic Era (EraTest.lua) work everywhere, for his tests.
function B:ForeverClient()
	local toc = GetBuildInfo and CuratorOctoFull.Select(4, GetBuildInfo())
	toc = tonumber(toc) or 0
	return toc >= 16000 and toc < 20000
end

function B:Elsewhere()
	return not CuratorOctoFull.IsOctoClient() and not self:ForeverClient() and ns.Admin == nil and not ns.TEST_BUILD
end

-- A beta build past its day, a build made obsolete by a mandatory update (Mandatory.lua), a collection
-- suspended, or a player banned; (1.14.0) or a game that is not OctoWoW.
function B:Over()
	return (ns.Mandatory ~= nil and ns.Mandatory:Locked()) or self:Suspended() or self:Banned()
		or self:Elsewhere()
end

-- (1.14.0) Not OctoWoW: said in its window each time something is asked of this copy, and in the chat and a toast
-- (once a minute at most).
function B:TellElsewhere()
	local now = (GetTime and GetTime()) or 0
	if not self.toldElsewhere or now - self.toldElsewhere >= 60 then
		self.toldElsewhere = now
		ns.Print(L["Curator is made for OctoWoW: it does not work in this version of the game, and nothing is earned here."])
		if ns.Toast then
			ns.Toast:Push({
				title = L["Only on OctoWoW"],
				name = "Curator " .. ns.version,
				color = { 1, 0.55, 0.25 },
				line = L["Your collection waits for you on OctoWoW."],
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
function B:VersionText() return ns.version end

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
	-- (1.14.0: not OctoWoW, its own window)
	if self:Elsewhere() then
		self:TellElsewhere()
		return true
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
	-- (1.14.0: not OctoWoW, its window a moment after the login; an update missed shows its own, Mandatory.lua)
	if B:Elsewhere() then
		ns.Delay(4, function()
			if not (ns.Mandatory and ns.Mandatory:Locked()) then
				B:TellElsewhere()
			end
		end, B)
		return
	end

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
	local line = L["A newer version of Curator is out (%s): update yours."]
	ns.Print(line, ver)
	if ns.Toast then
		ns.Toast:Push({
			title = L["New version"],
			name = "Curator " .. ver,
			color = { 1, 0.82, 0 },
			line = L["Update yours."],
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
