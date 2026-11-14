local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-------------------------------------------------------------------------------
-- (1.14.0, 1 November, 2 h 22, his idea; 2 h 49, his « go go go ») The masters of the mages and the titanforged cards:
-- « les maîtres des mages peuvent analyser avec précision le type de titanforged (Prisme, Black Pearl...) avec plein
-- d'info sur la titanforged, le plus possible, avec un certificat ultra stylé de la carte ; si quelqu'un veut expertiser
-- un titanforged, le certificat est obligatoire ; sur le boîtier de l'expertise on pourra voir quel type de titanforged ».
-- A master of the mages (Data/Trainers.lua: the mage trainers; Seal.lua: SL:Role, "mage") reads a titanforged copy, of a
-- booster (Copies.lua: f "h") or of a case (Cases.lua: f "titan"): all that its pattern makes of it (Patterns.lua: its
-- family, its number, its rank in its family, its colours, its light, its foils, its metal), written on its certificate.
-- The certificate stays with the copy (tc: { t = when, m = the number of the master }) and goes with it (a trade, the
-- Bourse, the showcase: MG.Pack). Paid once, as an appraisal of its rarity. A titanforged copy is appraised only once it
-- is certified (Expertise.lua, Cases.lua: CanAppraise, "cert"); its case then says its family and its number
-- (UI/Card.lua). UI/Mages.lua: the block at a master, his scene, the certificate.
-------------------------------------------------------------------------------
local MG = {}
ns.Mages = MG

-- the price of a certificate: the price of an appraisal of its rarity (Expertise.lua: E.PRICE)
MG.PRICE = { 500, 800, 1500, 2500, 4500, 7500 }
-- the twelve families of the patterns (Patterns.lua: P.LOOKS, in their order), the metal of their frames
MG.FAMILIES = { "Prism", "Gold", "Ruby", "Emerald", "Sapphire", "Amethyst", "Mother of pearl", "Aurora", "Blaze", "Glacier", "Twilight",
	"Black pearl" }
MG.METALS = { "Titan gold", "Titan gold", "Red gold", "Green gold", "Truesilver", "Arcanite", "White gold", "Thorium", "Copper", "Mithril",
	"Rose gold", "Dark iron" }
-- (the gold of the titans: the frame of a look without a metal of its own, TitanGold as it is)
MG.GOLD = { 1, 0.8, 0.38 }
-- (how fast the light of a card goes round, a radian a second for a speed of 1: UI/Card.lua, the cards of the boosters;
-- UI/CrateCard.lua, the cards of the cases)
MG.TURN = 0.45
MG.TURN_CASE = 0.11
-- (the master of the tests of the author, /curator test mage: the Archmage Shymm of Thunder Bluff)
MG.TEST_MASTER = 3047

local floor = math.floor
local TAU = math.pi * 2

local function Now()
	return GetServerTime and CuratorOctoFull.ServerTime() or time()
end

local function Closed()
	return ns.Beta ~= nil and ns.Beta:Over()
end

local function Locale()
	return ns.locale or (GetLocale and GetLocale()) or "enUS"
end

-------------------------------------------------------------------------------
-- The masters
-------------------------------------------------------------------------------
-- At a master of the mages now (Seal.lua: the window of dialogue of a mage trainer, or his window of training).
function MG:AtMaster()
	local SL = ns.Masters
	return SL ~= nil and SL:AtMaster("mage")
end

-- The number of the master talked to now (0: one of a test, or not known).
function MG:MasterNpc()
	local SL = ns.Masters
	local npc = SL and SL.masterNpc
	return (ns.MAGE_MASTERS and npc and ns.MAGE_MASTERS[npc]) and npc or 0
end

-- The name of a master of the mages (his number), in the language of the game; nil: not one known.
function MG.MasterName(npc)
	local n = ns.MAGE_MASTER_NAMES and ns.MAGE_MASTER_NAMES[tonumber(npc) or -1]
	if not n then
		return nil
	end
	return n[Locale()] or n[1]
end

-------------------------------------------------------------------------------
-- A certificate
-------------------------------------------------------------------------------
-- The certificate of a copy (rec: a copy of the albums, or a card of a case), or nil.
function MG.Of(rec)
	local tc = type(rec) == "table" and rec.tc
	if type(tc) ~= "table" then
		return nil
	end
	local t = tonumber(tc.t)
	if not (t and t > 0) then
		return nil
	end
	return tc
end

-- The pattern of a titanforged copy (case: a card of a case), nil: not one.
function MG.Pattern(rec, case)
	if case then
		return ns.Cases and ns.Cases.Pattern and ns.Cases.Pattern(rec) or nil
	end
	return ns.Copies and ns.Copies.Pattern and ns.Copies.Pattern(rec) or nil
end

-- Whether a copy waits for its certificate before an appraisal: a titanforged copy without one.
function MG.Needs(rec, case)
	return MG.Pattern(rec, case) ~= nil and MG.Of(rec) == nil
end

-- The number of a certificate (its pattern, when it was written): eight digits, the same each time.
function MG.No(pt, t)
	local h = 7
	local s = string.format(("arcane:%s:%s"), tostring(pt), tostring(t))
	for i = 1, CuratorOctoFull.Length(s) do
		h = CuratorOctoFull.Mod((h * 31 + CuratorOctoFull.Byte(s, i)) , 99999989)
	end
	return h
end

-- A certificate as it travels ("<when>-<master>", base 36), and back ({ t, m }; nil: not one).
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local function To36(n)
	n = math.max(0, floor(tonumber(n) or 0))
	local s = ""
	repeat
		local d = CuratorOctoFull.Mod(n , 36)
		s = string.sub(B36, d + 1, d + 1) .. s
		n = floor(n / 36)
	until n == 0
	return s
end
local function From36(s)
	return type(s) == "string" and CuratorOctoFull.Match(s, "^[0-9a-z]+$") and CuratorOctoFull.Length(s) <= 8 and tonumber(s, 36) or nil
end

function MG.Pack(tc)
	tc = MG.Of({ tc = tc })
	if not tc then
		return nil
	end
	return To36(tc.t) .. "-" .. To36(tonumber(tc.m) or 0)
end

function MG.Unpack(s)
	if type(s) ~= "string" or CuratorOctoFull.Length(s) > 16 then
		return nil
	end
	local a, b = CuratorOctoFull.Match(s, "^([0-9a-z]+)%-([0-9a-z]+)$")
	local t, m = From36(a), From36(b)
	-- (written after 2020 and before 2100; by a master of the mages, or of a test)
	if not (t and m and t >= 1577836800 and t < 4102444800) then
		return nil
	end
	if m ~= 0 and not (ns.MAGE_MASTERS and ns.MAGE_MASTERS[m]) then
		return nil
	end
	local out = { t = t, m = m }
	return MG.Pack(out) == s and out or nil
end

-------------------------------------------------------------------------------
-- What a certificate says
-------------------------------------------------------------------------------
-- Everything a master reads of a pattern (case: a card of a case, its light turns at its pace; nil: not a pattern):
--   n, max: its number of how many; family, name, metal, metalColor: its family, its name, the metal of its frame;
--   rank, size: its rank in its family, how many its family has; first: the first of its family (its look as it was
--   made); round: a round of its light in seconds; forward: its light goes round in the order of its colours; start: where
--   it starts (degrees); sharp: how sharp its lights are (2: as the prism); tint: its colours (none: those of the prism);
--   glints, spark: the colours of its stars and of its sparks; window, frame, dust: its three foils (1 to holo; 1: as the
--   first titanforged cards had them); stars: how much dust; glory: the light behind its creature; power: how bright its
--   foil is.
function MG.Info(pt, case)
	local P = ns.Patterns
	local look = P and P:Look(pt)
	if not look then
		return nil
	end
	local count = CuratorOctoFull.Length(P.LOOKS)
	local fam = look.family
	return {
		n = look.n,
		max = P.MAX,
		family = fam,
		name = MG.FAMILIES[fam],
		metal = MG.METALS[fam],
		metalColor = look.metal or MG.GOLD,
		rank = floor((look.n - 1) / count) + 1,
		size = floor((P.MAX - fam) / count) + 1,
		first = look.n <= count,
		round = TAU / ((case and MG.TURN_CASE or MG.TURN) * look.speed),
		speed = look.speed,
		forward = look.dir > 0,
		start = CuratorOctoFull.Mod(floor(look.phase * 180 / math.pi + 0.5) , 360),
		sharp = look.sharp,
		tint = look.tint,
		glints = look.glints,
		spark = look.spark,
		window = look.wv,
		frame = look.pv,
		dust = look.dv,
		holo = P.HOLO,
		stars = look.dust,
		glory = look.glory,
		power = look.power,
		look = look,
	}
end

-- The words of a certificate (English keys, as Locale114w.lua has them).
function MG.SpeedWord(speed)
	speed = tonumber(speed) or 1
	if speed < 0.55 then
		return "Very slow"
	elseif speed < 0.8 then
		return "Slow"
	elseif speed < 1.2 then
		return "Steady"
	elseif speed < 1.6 then
		return "Quick"
	end
	return "Very quick"
end

function MG.SharpWord(sharp)
	sharp = tonumber(sharp) or 2
	if sharp < 1.8 then
		return "Soft"
	elseif sharp < 2.5 then
		return "Crisp"
	elseif sharp < 3.5 then
		return "Sharp"
	end
	return "In flashes"
end

function MG.StarsWord(stars)
	stars = tonumber(stars) or 1
	if stars < 1.1 then
		return "Fine"
	elseif stars < 1.4 then
		return "Rich"
	elseif stars < 2 then
		return "Dense"
	end
	return "Very dense"
end

function MG.GloryWord(glory)
	glory = tonumber(glory) or 1
	if glory < 0.8 then
		return "Veiled"
	elseif glory < 1.1 then
		return "Bright"
	end
	return "Radiant"
end

-- The colour of a family (its first colour; the prism: none, its gold).
function MG.Color(info)
	local t = info and info.tint
	if t and t[1] then
		return t[1][1], t[1][2], t[1][3]
	end
	return MG.GOLD[1], MG.GOLD[2], MG.GOLD[3]
end

-- (1 November, 9 h 22, his word: « retirer le pattern sur les cartes puisqu'on a maintenant les maîtres des mages ») What
-- the texts say of the pattern of a titanforged copy: its family and its number once a master of the mages has certified
-- it ("Saphir 245", in the colour of its family; plain: without), nothing before (nil): its number is the masters' to
-- tell. TagOf: a pattern and its certificate as they travel (a link of the chat, the Bourse, a trade).
function MG.TagOf(pt, tc, case, plain)
	local info = pt and tc and MG.Info(pt, case)
	if not info then
		return nil
	end
	local text = string.format(("%s %d"), L[info.name], info.n)
	if plain then
		return text
	end
	local r, g, b = MG.Color(info)
	return string.format(("|cff%02x%02x%02x%s|r"), floor((0.3 + 0.7 * r) * 255), floor((0.3 + 0.7 * g) * 255), floor((0.3 + 0.7 * b) * 255), text)
end

function MG.Tag(rec, case, plain)
	return MG.TagOf(MG.Pattern(rec, case), MG.Of(rec), case, plain)
end

-- What a tooltip says of a titanforged copy and its certificate (nil: not titanforged): its family and its number,
-- certified (true); else that it is not (false).
function MG.Line(rec, case)
	if not MG.Pattern(rec, case) then
		return nil
	end
	local tag = MG.Tag(rec, case)
	if tag then
		return string.format(L["Certified by the mages: %s"], tag), true
	end
	return L["Not certified by a master of the mages"], false
end

-- What the label of the case of an appraised copy says of it (UI/Card.lua: its family and its number), nil: not
-- certified.
function MG.Label(rec, case)
	local pt = MG.Pattern(rec, case)
	if not (pt and MG.Of(rec)) then
		return nil
	end
	local info = MG.Info(pt, case)
	if not info then
		return nil
	end
	local r, g, b = MG.Color(info)
	return { family = L[info.name], n = info.n, color = { r, g, b } }
end

-------------------------------------------------------------------------------
-- The prices
-------------------------------------------------------------------------------
local function Priced(base)
	return (ns.Rubies and ns.Rubies.Price) and ns.Rubies:Price(base, "certify") or base
end

-- The price of a certificate of a copy of a card (its rarity).
function MG:Price(card)
	return Priced(self.PRICE[(card and card.rarity) or 1] or self.PRICE[1])
end

-- The price of a certificate of a card of a case (its rank, as the expert counts it: Cases.lua, CS.APPRAISE).
function MG:CasePrice(w)
	local CS = ns.Cases
	local k = CS and CS.APPRAISE and CS.APPRAISE[tonumber(w and w.r) or 1] or 2
	return Priced(self.PRICE[k] or self.PRICE[2])
end

-------------------------------------------------------------------------------
-- Certified
-------------------------------------------------------------------------------
-- (what is counted: how many certified, the families of them, a bit each)
local function Count(fam)
	local st = ns.Stats and ns.Stats()
	if not st then
		return
	end
	st.certified = (tonumber(st.certified) or 0) + 1
	local bits = tonumber(st.certFams) or 0
	local bit = 2 ^ (fam - 1)
	if CuratorOctoFull.Mod(floor(bits / bit) , 2) == 0 then
		st.certFams = bits + bit
	end
end

-- How many families certified (Stats: certFams).
function MG.Families()
	local st = ns.Stats and ns.Stats()
	local bits = st and tonumber(st.certFams) or 0
	local n = 0
	for i = 1, CuratorOctoFull.Length(MG.FAMILIES) do
		if CuratorOctoFull.Mod(floor(bits / 2 ^ (i - 1)) , 2) == 1 then
			n = n + 1
		end
	end
	return n
end

-- Whether a copy of a card can be certified now: true, or false and why ("closed", "card": not a copy of the
-- collection, "titan": not titanforged, "done": certified already, "away": at an enchanter, "master": not at a master
-- of the mages, "rubies").
function MG:CanCertify(card, id)
	if Closed() then
		return false, "closed"
	end
	local CP = ns.Copies
	if not (card and CP and ns.Collection:Owned(card)) then
		return false, "card"
	end
	local rec = id ~= nil and CP:Get(card.key, id) or nil
	if not rec then
		return false, "card"
	end
	if not CP.Pattern(rec) then
		return false, "titan"
	end
	if MG.Of(rec) then
		return false, "done"
	end
	if CP.Away(rec) then
		return false, "away"
	end
	if not self:AtMaster() then
		return false, "master"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:Price(card))) then
		return false, "rubies"
	end
	return true
end

-- Its certificate written: the rubies paid, the certificate on the copy. What came ({ card, id, rec, tc, info, price,
-- by }), else nil and why (as CanCertify, "guard").
function MG:Certify(card, id)
	local ok, why = self:CanCertify(card, id)
	if not ok then
		return nil, why
	end
	local CP = ns.Copies
	local rec = CP:Get(card.key, id)
	local price = self:Price(card)
	local paid, err = ns.Rubies:Spend(price, "certify")
	if not paid then
		return nil, err
	end
	local npc = self:MasterNpc()
	rec.tc = { t = Now(), m = npc }
	local info = MG.Info(CP.Pattern(rec))
	Count(info.family)
	ns.Fire("COPY_CERTIFIED", card, rec)
	if ns.Achievements and ns.Achievements.Queue then
		ns.Achievements:Queue()
	end
	return { card = card, id = id, rec = rec, tc = rec.tc, info = info, price = price, by = MG.MasterName(npc) }
end

-- The same for a card of a case (its number): true, or false and why (as CanCertify).
function MG:CanCertifyCase(id)
	if Closed() or not ns.db then
		return false, "closed"
	end
	local CS = ns.Cases
	local w = CS and CS.Own and CS.Own(id)
	if not w then
		return false, "card"
	end
	if not CS.Pattern(w) then
		return false, "titan"
	end
	if MG.Of(w) then
		return false, "done"
	end
	if type(w.aw) == "table" then
		return false, "away"
	end
	if not self:AtMaster() then
		return false, "master"
	end
	if not (ns.Rubies and ns.Rubies:Has(self:CasePrice(w))) then
		return false, "rubies"
	end
	return true
end

function MG:CertifyCase(id)
	local ok, why = self:CanCertifyCase(id)
	if not ok then
		return nil, why
	end
	local CS = ns.Cases
	local w = CS.Own(id)
	local price = self:CasePrice(w)
	local paid, err = ns.Rubies:Spend(price, "certify")
	if not paid then
		return nil, err
	end
	local npc = self:MasterNpc()
	w.tc = { t = Now(), m = npc }
	local info = MG.Info(CS.Pattern(w), true)
	Count(info.family)
	ns.Fire("CASES_CHANGED")
	ns.Fire("COPY_CERTIFIED", nil, w, true)
	if ns.Achievements and ns.Achievements.Queue then
		ns.Achievements:Queue()
	end
	return { case = true, id = id, rec = w, tc = w.tc, info = info, price = price, by = MG.MasterName(npc) }
end

-- Everything the certificate of a copy says, for the screen (rec: the copy; case: a card of a case): its info (MG.Info)
-- and who wrote it, when, its number; nil: not certified.
function MG.Read(rec, case)
	local tc = MG.Of(rec)
	local pt = MG.Pattern(rec, case)
	if not (tc and pt) then
		return nil
	end
	local info = MG.Info(pt, case)
	if not info then
		return nil
	end
	info.t = tonumber(tc.t)
	info.m = tonumber(tc.m) or 0
	info.by = MG.MasterName(info.m)
	info.no = MG.No(pt, info.t)
	return info
end
