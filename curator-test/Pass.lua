local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0) The pass of the collection: the proof, signed by the website of Curator, that it belongs to a player whose
-- app of Curator is linked to his Battle.net account on the website. The website makes it (lib/pass.ts), the app
-- writes it in Feed.lua, the first of the news of the front (a text of news of its own, Front.lua reads none of it):
--   curator-feed 1 / pass 1 / t <when it was made> / s <its salt> / c <the mark of a collection of the player>... /
--   n <the mark of the first name of one of his characters>...
-- A mark (PS.Mark): the first PS.HEX hexadecimal digits of the SHA-256 of "<c or n>:<salt>:<what>". The other side
-- of a trade reads a pass, and finds in it only what it knows already (the first name of who trades with it): the
-- other characters of the player and his collections stay his own.
-- What asks for it, from the release of WoW Forever on (as the rules of the rerolls, Reroll.lua: RR:Active):
-- * the trades and the duels for a stake (Trade.lua: T:CanTrade; Duel.lua), the cards sold to the reseller
--   (Reseller.lua), and the market to come: this collection must be in a pass the website made less than PS.DAYS days
--   ago (the app makes it again every quarter of an hour while it runs); for a trade or a duel, this character too
--   (its first name: the other side checks it there, and would refuse);
-- * the other side of a trade or of a duel: it sends its own pass before each offer, answer or duel (T:1:V, on the
--   wire, which keeps the order of the messages to a player). An offer, an answer or a duel from a player whose pass
--   did not come, or does not hold (not signed by the website, older than PS.DAYS days, without the first name of the
--   character who sends it), is refused ("pass"); one to a player who has no pass himself comes back refused
--   ("nopass").
-- (1.14.3, his word of November 5: the trades and the reseller ask for it no more, on either side: Trade.lua,
-- Reseller.lua. The Exchange alone asks for it, this collection in a pass, whatever the character: Market.lua, PS:Ok
-- of false. My pass still goes before my offers and answers when I have one, for the Curators of before.)
-- What is kept: nothing (the passes of the others, for the session).
-------------------------------------------------------------------------------
local PS = { theirs = {} }
ns.Pass = PS

PS.DAYS = 5      -- a pass holds this many days after the website made it (a pass given cannot be taken back: a player
                 -- caught, suspended or banned trades with his last one at most so long)
PS.AHEAD = 3600  -- a pass made later than now by more than this: a clock gone wrong, not believed
PS.MAX = 800     -- the longest text of a pass believed (the website makes them shorter)
PS.HEX = 10      -- the hexadecimal digits of a mark (an even count)
PS.SITE = "curator-wow.com/download"

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- The first name of a character: "Brindille" of "Brindille-Realm", of "Brindille-Fourchue", of "Brindille Fourchue".
function PS.First(name)
	return type(name) == "string" and CuratorOctoFull.Match(name, "^%s*([^%s%-]+)") or nil
end

-- A-Z in small letters, nothing else (the website does the same, whatever the language of the game).
function PS.Lower(s)
	return (string.gsub(s, "[A-Z]", function(c)
		return string.char(CuratorOctoFull.Byte(c) + 32)
	end))
end

-- The mark of a collection ("c") or of a first name ("n") in a pass of that salt (nil: no SHA-256 here).
function PS.Mark(kind, salt, what)
	local F = ns.Front
	if not (F and F.Sha256 and type(salt) == "string" and type(what) == "string") then
		return nil
	end
	local d = F.Sha256(kind .. ":" .. salt .. ":" .. what)
	return (string.gsub(string.sub(d, 1, PS.HEX / 2), ".", function(c)
		return string.format(("%02x"), CuratorOctoFull.Byte(c))
	end))
end

-- This collection in a pass (its mark there; worked out once a pass).
local function HasCollection(p, cid)
	p.hit = p.hit or {}
	local h = p.hit[cid]
	if h == nil then
		local m = PS.Mark("c", p.s, cid)
		h = m ~= nil and p.cids[m] == true
		p.hit[cid] = h
	end
	return h
end

-- A first name in a pass (its mark there; worked out once a pass and a name).
function PS.HasName(p, first)
	if not (p and type(first) == "string") then
		return false
	end
	p.named = p.named or {}
	local key = PS.Lower(first)
	local h = p.named[key]
	if h == nil then
		local m = PS.Mark("n", p.s, key)
		h = m ~= nil and p.names[m] == true
		p.named[key] = h
	end
	return h
end

-- Does Curator ask for a pass now? From the release of WoW Forever (the author's test, PS.test: true, or false never).
function PS:Required()
	if self.test ~= nil then
		return self.test == true
	end
	local RR = ns.Reroll
	return RR ~= nil and RR.Active ~= nil and RR:Active() or false
end

-------------------------------------------------------------------------------
-- A pass
-------------------------------------------------------------------------------
-- A pass in a text (nil: not one): { t (when the website made it), s (its salt), cids = { [mark] = true }, names = {
-- [mark] = true } }.
function PS:Parse(text)
	if type(text) ~= "string" or CuratorOctoFull.Length(text) > self.MAX then
		return nil
	end
	local lines = {}
	for line in CuratorOctoFull.Gmatch((text .. "\n"), "([^\n]*)\n") do
		lines[CuratorOctoFull.Length(lines) + 1] = line
	end
	if lines[1] ~= "curator-feed 1" or lines[2] ~= "pass 1" then
		return nil
	end
	local p = { cids = {}, names = {}, n = 0 }
	for i = 3, CuratorOctoFull.Length(lines) do
		local k, v = CuratorOctoFull.Match(lines[i], "^(%a) (.+)$")
		local hex = v ~= nil and not string.find(v, "[^0-9a-f]")
		if k == "t" then
			p.t = tonumber(CuratorOctoFull.Match(v, "^(%d+)$"))
		elseif k == "s" and hex and CuratorOctoFull.Length(v) >= 8 and CuratorOctoFull.Length(v) <= 32 then
			p.s = v
		elseif k == "c" and hex and CuratorOctoFull.Length(v) == self.HEX then
			p.cids[v] = true
			p.n = p.n + 1
		elseif k == "n" and hex and CuratorOctoFull.Length(v) == self.HEX then
			p.names[v] = true
		end
	end
	if not (p.t and p.s) or p.n == 0 then
		return nil
	end
	return p
end

-- Made less than PS.DAYS days ago (and not much later than now).
function PS:Fresh(p, now)
	now = now or Now()
	return p ~= nil and p.t <= now + self.AHEAD and now - p.t <= self.DAYS * 86400
end

-- A pass signed by the website: its text, its signature (hexadecimal). The pass, or nil.
function PS:Signed(text, sig)
	local F, key = ns.Front, ns.FEED_KEY
	local p = self:Parse(text)
	if not (p and F and F.Check and type(key) == "table" and type(sig) == "string" and CuratorOctoFull.Length(sig) <= 1024 and F:Check(text, sig, key)) then
		return nil
	end
	return p
end

-------------------------------------------------------------------------------
-- Mine
-------------------------------------------------------------------------------
-- The passes of Feed.lua signed by the website: { { p, text, sig } } (checked once: Feed.lua changes only when the
-- game loads it).
function PS:Read()
	local list = ns.FEED
	if self.readOf == list and self.read then
		return self.read
	end
	local out = {}
	for _, e in ipairs(type(list) == "table" and list or {}) do
		if type(e) == "table" and type(e[1]) == "string" and type(e[2]) == "string" and string.find(e[1], "\npass 1\n", 1, true) then
			local p = self:Signed(e[1], e[2])
			if p then
				out[CuratorOctoFull.Length(out) + 1] = { p = p, text = e[1], sig = e[2] }
			end
		end
	end
	self.readOf, self.read = list, out
	return out
end

-- My pass now: { p, text, sig }, or nil and why: "app" (no pass here: no app of Curator linked on this computer, or
-- it never wrote one), "collection" (passes, but none of this collection: the app has not sent it to the website
-- yet), "old" (made more than PS.DAYS days ago: the app has not run since).
function PS:Mine()
	local cid = ns.db and ns.db.cid
	local best, why = nil, "app"
	for _, x in ipairs(self:Read()) do
		if not (type(cid) == "string" and HasCollection(x.p, cid)) then
			if why == "app" then
				why = "collection"
			end
		elseif not self:Fresh(x.p) then
			why = "old"
		elseif not best or x.p.t > best.p.t then
			best = x
		end
	end
	if best then
		return best
	end
	return nil, why
end

-- This character in a pass (its first name, as the other side of a trade checks it: PS:Came). True when the game does
-- not say its name.
function PS:Named(p)
	local first = PS.First(UnitName and UnitName("player") or nil)
	if not first then
		return true
	end
	return PS.HasName(p, first)
end

-- Can this collection sell to the reseller (trade: trade, duel for a stake)? true, or false and why (PS:Mine; for a
-- trade, "character" too: this character not in the pass yet, which the other side would refuse).
function PS:Ok(trade)
	if not self:Required() then
		return true
	end
	local mine, why = self:Mine()
	if not mine then
		return false, why
	end
	if trade and not self:Named(mine.p) then
		return false, "character"
	end
	return true
end

-- What to tell the player when he has no pass (why: PS:Ok; none: the one of the Exchange). (1.14.3: the Exchange alone
-- asks for it, its own words.)
function PS:Text(why)
	if why == nil then
		local _, w = self:Ok(false)
		why = w or "app"
	end
	if why == "collection" then
		return L["Your Curator app has not sent this collection to the website yet: log out of the game once, then wait a few minutes."]
	elseif why == "character" then
		return L["Your Curator app has not sent this character to the website yet: log out of the game once with it, then wait a few minutes."]
	elseif why == "old" then
		return string.format(L["Your Curator app has not checked your collection for %d days: open it, then reload your interface."], self.DAYS)
	end
	return string.format(L["The Exchange needs the Curator app, linked to your Battle.net account on the website: %s"], self.SITE)
end

-- My pass as it goes to the other side of a trade: its text (its lines separated by ~) and its signature; nil: none.
function PS:Wire()
	local mine = self:Mine()
	if not mine then
		return nil
	end
	return (string.gsub(mine.text, "\n", "~")), mine.sig
end

-------------------------------------------------------------------------------
-- Theirs
-------------------------------------------------------------------------------
-- The pass of the other side of a trade came (its text as it goes, its signature): it holds for this player if the
-- website signed it, less than PS.DAYS days ago, and the first name of the character who sent it is in it.
function PS:Came(sender, text, sig)
	if type(sender) ~= "string" or type(text) ~= "string" then
		return false
	end
	local p = self:Signed((string.gsub(text, "~", "\n")), sig)
	local first = PS.First(sender)
	local ok = p ~= nil and self:Fresh(p) and first ~= nil and PS.HasName(p, first)
	self.theirs[sender] = { ok = ok, t = p and p.t or nil, why = (not p and "sig") or (not self:Fresh(p) and "old") or (not ok and "name") or nil }
	return ok
end

-- The pass of this player holds (none asked before the release of WoW Forever).
function PS:Holds(sender)
	if not self:Required() then
		return true
	end
	local x = sender and self.theirs[sender]
	return x ~= nil and x.ok and x.t ~= nil and Now() - x.t <= self.DAYS * 86400 or false
end

-------------------------------------------------------------------------------
-- The test of the author (his build: /curator test pass)
-------------------------------------------------------------------------------
-- The pass asked for now, as from the release of WoW Forever, on the true collection (nothing changes in it), until
-- asked again; what the pass of this collection holds said.
local FR = {
	["(Test: the pass of the app asked for now, as after the release of WoW Forever: for the trades and the sales to the reseller, on your side and on the other one. /curator test pass again: back to normal.)"] =
		"(Test : le laissez-passer de l'appli est demandé dès maintenant, comme après la sortie de WoW Forever : pour les échanges et les ventes au revendeur, de ton côté comme de celui de l'autre joueur. Retape /curator test pass pour revenir à la normale.)",
	["(Test over: the pass of the app is asked for again only from the release of WoW Forever.)"] =
		"(Test terminé : le laissez-passer de l'appli n'est de nouveau demandé qu'à partir de la sortie de WoW Forever.)",
	["(Your pass: made by the website %d h ago; this collection and this character are in it.)"] =
		"(Ton laissez-passer : fait par le site il y a %d h ; cette collection et ce personnage y sont.)",
	["(Your pass: made by the website %d h ago; this collection is in it, not this character yet.)"] =
		"(Ton laissez-passer : fait par le site il y a %d h ; cette collection y est, pas encore ce personnage.)",
}
local function TT(k)
	return (GetLocale and GetLocale() == "frFR" and FR[k]) or k
end
PS.TEST_TEXT = FR

function PS:Test()
	if self.test then
		self.test = nil
		ns.Print(TT("(Test over: the pass of the app is asked for again only from the release of WoW Forever.)"))
		ns.Fire("CHANGED")
		return
	end
	self.test = true
	ns.Print(TT("(Test: the pass of the app asked for now, as after the release of WoW Forever: for the trades and the sales to the reseller, on your side and on the other one. /curator test pass again: back to normal.)"))
	local mine, why = self:Mine()
	if not mine then
		ns.Print(self:Text(why))
	elseif self:Named(mine.p) then
		ns.Print(string.format(TT("(Your pass: made by the website %d h ago; this collection and this character are in it.)"), math.max(0, math.floor((Now() - mine.p.t) / 3600))))
	else
		ns.Print(string.format(TT("(Your pass: made by the website %d h ago; this collection is in it, not this character yet.)"), math.max(0, math.floor((Now() - mine.p.t) / 3600))))
		ns.Print(self:Text("character"))
	end
	ns.Fire("CHANGED")
end
