local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection

-------------------------------------------------------------------------------
-- (1.14.0) A card of a case, as CS2 shows what comes out of one (UI/Crate.lua): nothing of the cards of the boosters.
-- (1.14.0, the Paladin collection redone by its author: the cards of a collection with a style of its own, its picture
-- over all of each card under the thin frame of its rank, nothing round it: CC.STYLES. What follows: the others.)
-- Each rank its own card, one lore of the game each, painted as the frames of the albums:
-- * Rare: the steel of the dwarves, its plates riveted, blue runes of the titans cut in it, bronze at its corners, a
--   keystone over it (a spark on its rune stones now and then).
-- * Restricted: the arcane of Dalaran: violet and gold, crystals floating over it; a circle of runes turning behind
--   its creature.
-- * Classified: the crystals of the Void: polished stone of the Void, marbled, its veins beating, rose gold round it,
--   clusters of pink crystals at its corners, an orb of the Void on a stand of rose gold over it.
-- * Covert: the Molten Core: obsidian and lava (its glow breathing), two great horns over it, flames between them;
--   embers rising behind and before its creature.
-- * Priceless: the Light: gold as gold is, chiselled, a vine carved round it, rubies and sapphires set in it, a sun
--   of gold over it; its shine moving with the light (the mouse), rays turning behind it, sparks on it, its sheen.
-- Its creature in its window, alive, turning a little to and fro (a scene of the game framed as the window of a card:
-- UI/Card.lua, ns.Creatures.Stage); a client without model scenes, its portrait.
-- Its wear on it (31 October, his word: as the cards of the boosters, never its condition in words): the pieces of
-- UI/Wear.lua put together by its seed, none on a 10, a card worn through at 1 (Cases.lua: CS.WearOf).
-- Forged as the cards of the boosters are, on the metal of its frame (what its rank is, its runes, its lacquer, its
-- crystals, its lava, its gems, never covered; nor its window, nor its plate): thunderforged, lightning crawling all over
-- its frame and striking it from above every few seconds, its metal in the cold light of the storm; titanforged, its
-- metal in all the colours of the rainbow, flowing as it turns and as the light moves, and in its window the foil and the
-- light of the prism behind its creature. A light along its edge, twinkles on it, a sweep of light over it now and then.
-- All of it stays on it held in the hand and turned (UI/Inspect.lua), its words with it.
-- The golden card of the secret: the card of the priceless rank, its medal and its question mark in its window.
-- A priceless card is a weapon of legend (UI/Crate.lua: CR.WEAPONS): in its window, the weapon itself, a model of the
-- game standing (its blade up, its broad side to the eye) and turning to and fro; its name in the language of the game.
-- The cards of the case of the month (CrateItems.lua): a spell, its icon in a medallion of light, the ring of its rank
-- round it, its tree and what it does under it (the words of the game, smaller until they fit); a figure, its creature
-- as the creatures of the albums; an armour, the character of the player wearing it (a dressing room of the game: its
-- shirt, its tabard and its cloak taken off, its weapons sheathed), turning slowly, the icon of its chest in its place
-- while it dresses.
-------------------------------------------------------------------------------
local CC = {}
ns.CrateCard = CC

-- the parts of its textures (in points of a texture of 512 x 717 for the card): its window, its plate
local TW, TH = 512, 717
local WIN = { 24, 24, 488, 552 }
local PLATE = { 24, 566, 488, 693 }
local function TC(x0, y0, x1, y1, w, h)
	return (x0 + 0.5) / w, (x1 - 0.5) / w, (y0 + 0.5) / h, (y1 - 0.5) / h
end
-- (each rank: CrateRank1..5, 1024 x 1024: its frame, the light of its metal alone, under them its parts and its glow)
local FRAME_TC = { TC(0, 0, 512, 717, 1024, 1024) }
local LIGHT_TC = { TC(512, 0, 1024, 717, 1024, 1024) }
-- the glow of a rank: over the card and a margin of GM round it
local GM = 24
-- (the textures of the finishes of the cards of the boosters, drawn on a card of 366 x 512 in a texture of 512: the
-- same shape as this one)
local RIM_R = 366 / 512
-- the forged finishes: the colour of their sweep
CC.FIN_TINT = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.9, 0.66 } }

-- The art of each rank: where its glow is in its texture; its parts round the card (key, their part of the texture,
-- their mirror, where they are on the card, behind its frame or over it, their blend, their size on the card).
CC.ART = {
	{ glow = { 154, 720, 294, 911 }, tone = 1, parts = {
		{ "keystone", 0, 720, 150, 820, false, false, 181, -52 },
	} },
	{ glow = { 338, 720, 478, 911 }, tone = 1, parts = {
		{ "crystals", 0, 720, 240, 870, false, false, 136, -132 },
		{ "shardL", 244, 720, 334, 830, false, false, -46, -62 },
		{ "shardR", 244, 720, 334, 830, true, false, 468, -62 },
	} },
	{ glow = { 358, 720, 498, 911 }, tone = 0.85, parts = {
		{ "orb", 0, 720, 210, 890, false, false, 151, -112 },
		{ "clusterTL", 214, 720, 354, 860, false, false, -40, -40 },
		{ "clusterTR", 214, 720, 354, 860, true, false, 412, -40 },
		{ "clusterBL", 214, 720, 354, 860, false, true, -40, 617 },
		{ "clusterBR", 214, 720, 354, 860, true, true, 412, 617 },
	} },
	{ glow = { 272, 720, 412, 911 }, tone = 0.66, parts = {
		{ "hornL", 0, 720, 200, 980, false, false, -24, -206, true },
		{ "hornR", 0, 720, 200, 980, true, false, 336, -206, true },
		{ "flame1", 204, 720, 268, 840, false, false, 135, -75, true, "ADD", 49, 93 },
		{ "flame2", 204, 720, 268, 840, false, false, 178, -96, true, "ADD", 60, 114 },
		{ "flame3", 204, 720, 268, 840, false, false, 219, -120, true, "ADD", 73, 138 },
		{ "flame4", 204, 720, 268, 840, false, false, 274, -96, true, "ADD", 60, 114 },
		{ "flame5", 204, 720, 268, 840, false, false, 327, -75, true, "ADD", 49, 93 },
	} },
	{ glow = { 244, 720, 384, 911 }, tone = 1, glint = "CrateGlint5", parts = {
		{ "sun", 0, 720, 240, 910, false, false, 136, -128 },
	} },
}
local MAX_OVER, MAX_UNDER = 6, 7
-- (its sparks: where its gems and its gold catch the light, in points of its texture; how often; their size, colour)
local SPARKS = {
	{ every = { 2.6, 1.5 }, size = 40, colour = { 0.72, 0.86, 1 }, spots = { { 256, -2 }, { 256, -2 }, { 19, 19 }, { 493, 19 },
		{ 19, 698 }, { 493, 698 } } },
	{ every = { 1.1, 0.9 }, size = 44, colour = { 0.9, 0.76, 1 }, spots = { { 256, -70 }, { 256, -70 }, { 214, -52 }, { 298, -52 },
		{ -12, -18 }, { 524, -18 }, { 15, 340 }, { 497, 340 }, { 256, 557 }, { 54, 54 }, { 458, 54 } } },
	{ every = { 0.9, 0.9 }, size = 44, colour = { 1, 0.72, 0.92 }, spots = { { 256, -50 }, { 240, -66 }, { -22, -22 },
		{ 534, -22 }, { -22, 739 }, { 534, 739 }, { 15, 210 }, { 497, 210 }, { 15, 340 }, { 497, 340 }, { 15, 470 },
		{ 497, 470 }, { 256, 557 } } },
	nil,
	{ every = { 0.3, 0.4 }, size = 46, colour = { 1, 0.92, 0.7 }, spots = { { 256, -26 }, { 256, -26 }, { 284, -75 },
		{ 313, -26 }, { 199, -26 }, { 228, -75 }, { 30, 30 }, { 482, 30 }, { 30, 687 }, { 482, 687 }, { 15, 330 },
		{ 497, 330 }, { 256, 557 }, { 120, 18 }, { 392, 18 }, { 18, 160 }, { 494, 160 } } },
}
-- (the orb of the classified rank: its middle, its size)
local ORB_X, ORB_Y, ORB_R = 256, -50, 40
-- (the parts that move: the crystals floating, the flames)
local FLOAT = { crystals = { 5, 1.5, 0 }, shardL = { 4, 1.8, 1.0 }, shardR = { 4, 1.8, 2.6 } }
local EMBERS = 16

-------------------------------------------------------------------------------
-- (1.14.0, the Paladin collection redone by its author) The style of the cards of a collection (its case,
-- Data/Crate*.lua: art.style): the picture of each card over all of it (its entry: pic, Media/<pic>, 512 x 1024, the
-- shape of ART on the card), under a thin frame of its rank (Media/<frames><rank>, 512 x 1024: its frame, 512 x 717;
-- under it its glow, a quarter of its size, the card and a margin of GM round it, nothing in the margin): nothing past
-- the edges of the card (in the case of the expert it stays inside it), no creature, no words of a spell over its
-- picture; the band of its name at its foot (PLATE). The metal of its frames for the titanforged finish
-- (Media/<foil><rank>); the shine of its gold under the light (glint: its two textures of four lights, by rank); where
-- its gems catch the light (sparks), embers rising over its picture (embers: by rank). The priceless cards of its case
-- (its weapons of legend: priceless) still, nothing on them moving of itself: their reflections over them as on a
-- holographic card, as the light comes (CC.Shine).
-- Every style the same shape: its picture (ART), what is seen of it over the band of its name (VIEW), the band (PLATE).
-------------------------------------------------------------------------------
local ART = { 10, 10, 502, 707 }
local VIEW = { 20, 20, 492, 606 }
local SPLATE = { 20, 606, 492, 697 }
CC.STYLE_ART, CC.STYLE_VIEW, CC.STYLE_PLATE = ART, VIEW, SPLATE
CC.STYLES = {
	pal = {
		frames = "CratePal", foil = "CratePalFoil", glint = { [5] = "CratePalGlint5" }, glow = { 0, 720, 140, 911 },
		-- its words on the band of its name: the middle of its name, of its rank (on two lines: theirs), its width
		nameY = 641, rankY = 677, nameY2 = 636, rankY2 = 682, nameW = 420,
		embers = { [4] = true },
		sparks = {
			{ every = { 2.6, 1.5 }, size = 38, colour = { 0.72, 0.86, 1 }, spots = { { 256, 20 }, { 256, 20 }, { 256, 605 },
				{ 26, 26 }, { 486, 26 }, { 26, 691 }, { 486, 691 } } },
			{ every = { 1.3, 1.0 }, size = 42, colour = { 0.9, 0.76, 1 }, spots = { { 256, 22 }, { 256, 22 }, { 256, 605 },
				{ 29, 29 }, { 483, 29 }, { 29, 688 }, { 483, 688 } } },
			{ every = { 1.0, 0.9 }, size = 44, colour = { 1, 0.72, 0.92 }, spots = { { 256, 22 }, { 256, 22 }, { 256, 605 },
				{ 29, 29 }, { 483, 29 }, { 29, 688 }, { 483, 688 } } },
			-- (the card of Arthas, in Stratholme burning: the ruby of the crown over the city, those of its corners)
			{ every = { 1.0, 0.9 }, size = 44, colour = { 1, 0.66, 0.36 }, spots = { { 256, 23 }, { 256, 23 }, { 256, 605 },
				{ 24, 24 }, { 488, 24 }, { 24, 693 }, { 488, 693 } } },
			{ every = { 0.3, 0.4 }, size = 46, colour = { 1, 0.92, 0.7 }, spots = { { 256, 24 }, { 256, 24 }, { 230, 40 },
				{ 282, 40 }, { 29, 29 }, { 483, 29 }, { 29, 688 }, { 483, 688 }, { 256, 605 }, { 106, 604 }, { 406, 604 },
				{ 24, 200 }, { 488, 200 }, { 24, 450 }, { 488, 450 }, { 150, 24 }, { 362, 24 } } },
		},
	},
}

-- The case of a card (its def, Data/Crate*.lua) when it has one: the one of its entry, of its weapon of legend (a weapon
-- of its own), or the one it was given (the golden card of the secret of a case).
local weaponOf
function CC.WeaponArt(w)
	local id = type(w) == "table" and w.id or w
	if not weaponOf then
		weaponOf = {}
		for _, def in pairs(ns.Crates or {}) do
			if type(def) == "table" then
				for _, x in ipairs(type(def.priceless) == "table" and def.priceless or {}) do
					if type(x) == "table" and tonumber(x[1]) then
						weaponOf[tonumber(x[1])] = { x = x, def = def }
					end
				end
			end
		end
	end
	local o = id and weaponOf[tonumber(id) or 0]
	if o then
		return o.x, o.def
	end
end

function CC.DefOf(pick)
	if not pick then
		return nil
	end
	if pick.weapon then
		local _, def = CC.WeaponArt(pick.weapon)
		return def
	end
	if pick.entry then
		return pick.entry.def
	end
	return pick.def
end

-- The style of a card (nil: the cards of the ranks of the first cases, their parts round them).
function CC.StyleOf(pick)
	local def = CC.DefOf(pick)
	local key = def and def.art and def.art.style
	return key and CC.STYLES[key] or nil
end

-- (the reflections of a priceless card of a style: four, the light from the left, from the right, from above, from below;
-- where the light rests when nothing brings it elsewhere: from above on the left)
local SHINES = 4
local REST_X, REST_Y = -0.6, 0.8

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

local function Text(parent, size, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	ns.SetFont(fs, size, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 1)
	return fs
end

-- Its layers over one another, whatever level it is given: its window (and what turns or rises behind its creature),
-- its creature, what rises before it, the golden card of the secret, what is over it, its sheen. (1.14.0, after its
-- second test: in its case, appraised (M:SetSlab), all of it a level up: the backing of its case at its own level, under
-- it; its case over it.)
local function Relevel(f)
	local lv = f:GetFrameLevel()
	local base = lv + (f.slabOff or 0)
	if f.base == base and f.lv == lv then
		return
	end
	f.base, f.lv = base, lv
	if f.slabLow then
		f.slabLow:SetFrameLevel(lv)
	end
	local sl = f.slab
	if sl then
		sl.high:SetFrameLevel(base + 12)
		sl.wordsF:SetFrameLevel(base + 13)
	end
	if f.hotF then
		f.hotF:SetFrameLevel(base + 11)
	end
	f.low:SetFrameLevel(base)
	f.win:SetFrameLevel(base + 1)
	f.winTex:SetFrameLevel(base + 1)
	if f.scene then
		f.scene:SetFrameLevel(base + 2)
	end
	if f.arm then
		f.arm:SetFrameLevel(base + 2)
		for _, o in ipairs({ f.arm.scene or false, f.arm.model or false }) do
			if o then
				o:SetFrameLevel(base + 2)
			end
		end
	end
	if f.spell then
		f.spell:SetFrameLevel(base + 2)
	end
	if f.dress then
		f.dress:SetFrameLevel(base + 2)
	end
	f.front:SetFrameLevel(base + 3)
	f.secret:SetFrameLevel(base + 5)
	f.over:SetFrameLevel(base + 7)
	f.forge:SetFrameLevel(base + 8)
	f.sheenBox:SetFrameLevel(base + 9)
	if f.wearF then
		f.wearF:SetFrameLevel(base + 9)
	end
	f.backF:SetFrameLevel(base + 10)
	local h = f.held3
	if h then
		for i, n in ipairs(h.levels) do
			h.frames[i]:SetFrameLevel(base + n)
		end
		if h.slabLowF then
			h.slabLowF:SetFrameLevel(lv)
			h.slabHigh:SetFrameLevel(base + 12)
			h.slabTexts:SetFrameLevel(base + 13)
		end
	end
end

-- A part of the card (in points of its texture) on the card (k: its points for one of the texture).
local function Place(t, card, x0, y0, x1, y1)
	local k = card.k
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", card, "TOPLEFT", x0 * k, -y0 * k)
	CuratorOctoFull.SetSize(t, (x1 - x0) * k, (y1 - y0) * k)
end

local function At(t, card, x, y, w, h)
	local k = card.k
	t:ClearAllPoints()
	t:SetPoint("CENTER", card, "TOPLEFT", x * k, -y * k)
	CuratorOctoFull.SetSize(t, w * k, (h or w) * k)
end

-------------------------------------------------------------------------------
-- (1.14.0) The weapon of a priceless card: { id (its item), class (the class of its version), faction (its side) }.
-- The game knows an item once it asked the server for it: until then its name waits, and its model (its icon in its
-- place if it is long to come). Its model in a scene of the game of its own (as the creatures of the cards): the
-- weapon alone, by its link; measured once loaded, standing (its long side up, its blade up: its grip is where its
-- model starts; its broad side to the eye), as long as a share of the height of its frame whatever its size; turning
-- to and fro. A client whose scenes do not show it: a model frame of the item, measured by its file (an actor of a
-- small scene out of sight). Never hidden by its alpha (the client draws a model whatever the alpha of its frame):
-- hidden, the camera of its scene looks at it from so far that it is less than a point, or its model frame is a
-- point.
-------------------------------------------------------------------------------
-- the seconds a weapon is waited for before its icon stands in its place (until it comes); its turn to and fro
-- (either way, how fast), its turn at rest (a little of its side); its length, a share of the height of its frame; the
-- field of view of its camera (little perspective); the seconds its scene is given to show it before its model frame
-- takes its place; a weapon that stands otherwise (ARM_POSE[id] = { pitch, roll, yaw })
local ARM_WAIT = 2
local ARM_SWING, ARM_SPEED, ARM_FACE = 0.62, 0.6, 0.3
local ARM_FILL = 0.74
local ARM_FOV = 0.5
local ARM_SCENE_WAIT = 2.5
-- (its model frame draws it as long as its own diagonal, or so: this much farther, some three quarters of it)
local ARM_CAM = 1.75
local ARM_POSE = {}
-- (how its scene projects, against the rule, when the screen tells nothing: what the client of the author showed, a
-- weapon framed by the rule coming out some 0.45 of its length; ReadScene)
local ARM_CAL = 0.45
CC.ARM_WAIT, CC.ARM_POSE, CC.ARM_CAM, CC.ARM_FILL, CC.ARM_FOV = ARM_WAIT, ARM_POSE, ARM_CAM, ARM_FILL, ARM_FOV
CC.ARM_SWING, CC.ARM_SPEED, CC.ARM_FACE, CC.ARM_CAL = ARM_SWING, ARM_SPEED, ARM_FACE, ARM_CAL

-- Whether the game knows an item now, and asking it for one.
local function Known(id)
	if C_Item and C_Item.IsItemDataCachedByID then
		return C_Item.IsItemDataCachedByID(id) and true or false
	end
	return GetItemInfo and GetItemInfo(id) ~= nil or false
end
local function Ask(id)
	if C_Item and C_Item.RequestLoadItemDataByID then
		pcall(C_Item.RequestLoadItemDataByID, id)
	end
end
CC.Ask = Ask

-- The name of a weapon in the language of the game (nil: not known yet, asked for).
function CC.WeaponName(w)
	local id = w and w.id
	if not id then
		return nil
	end
	local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
	if not name and GetItemInfo then
		name = GetItemInfo(id)
	end
	if not name then
		Ask(id)
	end
	return name
end

-- What it is, under its name (nil: nothing): the class of its version (Atiesh), its side (the weapons of rank 14).
function CC.WeaponNote(w)
	if not w then
		return nil
	end
	if w.class then
		local names = LOCALIZED_CLASS_NAMES_MALE
		return (names and names[w.class]) or w.class
	elseif w.faction then
		local side = (w.faction == "Alliance" and FACTION_ALLIANCE) or (w.faction == "Horde" and FACTION_HORDE) or w.faction
		return L["Rank 14 weapon"] .. "  ·  " .. side
	end
end

-- Its icon (nil: none).
function CC.WeaponIcon(w)
	local id = w and w.id
	if not id then
		return nil
	end
	local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
	if not icon and GetItemIcon then
		icon = GetItemIcon(id)
	end
	return icon
end

-- Its link, which its scene shows it by (the game's, else one of its own).
local function ItemLink(id)
	local link = GetItemInfo and CuratorOctoFull.Select(2, GetItemInfo(id))
	return link or string.format(("item:%d"), id)
end

-- The bounds of the model of a file, measured once: fn(box) once known (nil: it cannot be). One file at a time, in
-- an actor of a small model scene in a corner of the screen, under the rest and in the dark.
local Gauge = { boxes = {}, waiting = {}, queue = {} }
CC.Gauge = Gauge
local GETTERS = { "GetActiveBoundingBox", "GetMaxBoundingBox" }

function Gauge:Scene()
	if self.scene == nil then
		local ok, sc = pcall(CreateFrame, "ModelScene", nil, UIParent)
		if ok and sc and sc.CreateActor then
			CuratorOctoFull.SetSize(sc, 4, 4)
			sc:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
			sc:SetFrameStrata("BACKGROUND")
			sc:SetFrameLevel(0)
			sc:EnableMouse(false)
			sc.actor = sc:CreateActor()
			pcall(sc.actor.SetAlpha, sc.actor, 0)
			sc:Hide()
			self.scene = sc
		else
			self.scene = false
		end
	end
	return self.scene or nil
end

function Gauge:Ask(file, fn)
	if not file then
		fn(nil)
		return
	end
	local box = self.boxes[file]
	if box ~= nil then
		fn(box or nil)
		return
	end
	local w = self.waiting[file]
	if w then
		w[CuratorOctoFull.Length(w) + 1] = fn
		return
	end
	self.waiting[file] = { fn }
	self.queue[CuratorOctoFull.Length(self.queue) + 1] = file
	self:Next()
end

function Gauge:Next()
	if self.file then
		return
	end
	local file = CuratorOctoFull.Remove(self.queue, 1)
	local sc = self:Scene()
	if not file then
		if sc then
			sc:Hide()
		end
		return
	end
	if not (sc and sc.actor.SetModelByFileID) then
		self:Done(file, false)
		return
	end
	local token = {}
	self.file, self.token = file, token
	sc:Show()
	pcall(sc.actor.ClearModel, sc.actor)
	if not pcall(sc.actor.SetModelByFileID, sc.actor, file) then
		self:Done(file, false)
		return
	end
	-- (loaded: measured)
	CuratorOctoFull.SetScript(sc, "OnUpdate", function()
		if self.token == token and sc.actor:IsLoaded() then
			CuratorOctoFull.SetScript(sc, "OnUpdate", nil)
			self:Loaded()
		end
	end)
	-- (a file that does not load: its weapon stands as it comes)
	ns.Delay(3, function()
		if self.token == token then
			self:Done(file, false)
		end
	end, self)
end

function Gauge:Loaded()
	local file = self.file
	if not file then
		return
	end
	local a, box = self.scene.actor, nil
	for _, getter in ipairs(GETTERS) do
		if not box and a[getter] then
			local ok, x1, y1, z1, x2, y2, z2 = pcall(a[getter], a)
			if ok and type(x1) == "table" and type(y1) == "table" then
				x1, y1, z1, x2, y2, z2 = x1.x, x1.y, x1.z, y1.x, y1.y, y1.z
			end
			if ok and type(x1) == "number" and type(y1) == "number" and type(z1) == "number" and type(x2) == "number"
				and type(y2) == "number" and type(z2) == "number" and x2 > x1 and y2 > y1 and z2 > z1 then
				box = { x1, y1, z1, x2, y2, z2 }
			end
		end
	end
	self:Done(file, box or false)
end

function Gauge:Done(file, box)
	self.boxes[file] = box
	if self.file == file then
		self.file, self.token = nil, nil
		if self.scene then
			CuratorOctoFull.SetScript(self.scene, "OnUpdate", nil)
		end
	end
	local list = self.waiting[file]
	self.waiting[file] = nil
	for _, fn in ipairs(list or {}) do
		local ok, err = pcall(fn, box or nil)
		if not ok and geterrorhandler then
			geterrorhandler()(err)
		end
	end
	self:Next()
end

-- How a weapon of these bounds stands: its long side up, its blade up, its broad side to the eye. Its pitch and its
-- roll stand it (the eye looks along x; y across, z up), its turn shows its broad side.
function CC.Pose(box)
	local x1, y1, z1, x2, y2, z2 = box[1], box[2], box[3], box[4], box[5], box[6]
	local e = { x2 - x1, y2 - y1, z2 - z1 }
	local c = { (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2 }
	local long = 3
	if e[1] > e[long] then
		long = 1
	end
	if e[2] > e[long] then
		long = 2
	end
	-- (its blade on the side of its middle: its grip where its model starts)
	local s = c[long] >= 0 and 1 or -1
	local pitch, roll, wide, deep = 0, 0, 0, 0
	if long == 3 then
		roll = s > 0 and 0 or math.pi
		wide, deep = e[2], e[1]
	elseif long == 1 then
		pitch = -s * math.pi / 2
		wide, deep = e[2], e[3]
	else
		roll = s * math.pi / 2
		wide, deep = e[3], e[1]
	end
	return pitch, roll, (deep > wide) and math.pi / 2 or 0
end

-- The light on a weapon: warm, from the front left (as the light of the cards).
local armLight
local function ArmLight()
	if not armLight and CreateColor and CreateVector3D then
		armLight = { omnidirectional = false, point = CreateVector3D(-1, 0, -0.35), ambientIntensity = 0.8,
			ambientColor = CreateColor(1, 0.95, 0.86), diffuseIntensity = 0.9, diffuseColor = CreateColor(1, 0.93, 0.8) }
	end
	return armLight
end

-- (the light of its scene: warm, from the front, a little from the left and from above, as on the cards)
local function SceneLight(sc)
	local n = math.sqrt(1 + 0.45 * 0.45 + 0.55 * 0.55)
	pcall(sc.SetLightVisible, sc, true)
	pcall(sc.SetLightType, sc, (Enum and Enum.ModelLightType and Enum.ModelLightType.Directional) or 0)
	pcall(sc.SetLightDirection, sc, -1 / n, 0.45 / n, -0.55 / n)
	pcall(sc.SetLightAmbientColor, sc, 0.78, 0.74, 0.68)
	pcall(sc.SetLightDiffuseColor, sc, 0.95, 0.88, 0.74)
end

-- How the scenes of this client project, against the rule: what the screen showed of its own scene (ReadScene), else
-- of the last scene of a weapon read, else what the creatures read (UI/Card.lua), else ARM_CAL. CC.SceneCal(false):
-- all of it forgotten, read again.
local sceneCal
local ARMS = setmetatable({}, { __mode = "k" })
local function SceneScale(m)
	return (m and m.cal) or sceneCal or (ns.Creatures and ns.Creatures.cal) or ARM_CAL
end
local function ScaleFrom(m)
	return ((m and m.cal) and "its scene") or (sceneCal and "another weapon") or ((ns.Creatures and ns.Creatures.cal) and "the creatures")
		or "by default"
end
CC.SceneScale = SceneScale
function CC.SceneCal(v)
	if v ~= nil then
		sceneCal = v or nil
		if v == false then
			for m in pairs(ARMS) do
				m.cal, m.reads = nil, nil
			end
		end
	end
	return sceneCal
end
local function Rule(sc, w, h)
	local ok, fov = pcall(sc.GetCameraFieldOfView, sc)
	if not (ok and type(fov) == "number" and fov > 0.05 and fov < 3) then
		fov = ARM_FOV
	end
	return math.sqrt(w * w + h * h) / (2 * math.tan(fov / 2))
end

-- Its camera: at it, as far as makes its length that share of the height of its scene (the field of view of a scene
-- spans its diagonal: UI/Card.lua); hidden (or not standing yet), so far that it is less than a point.
local FAR = 3000
local function ArmCamera(m)
	local sc = m.scene
	if not sc then
		return
	end
	local w, h = sc:GetWidth() or 0, sc:GetHeight() or 0
	local d = FAR
	if m.mode == "scene" and m.ready and m.visible and w > 0 and h > 0 then
		d = Rule(sc, w, h) * SceneScale(m) * (m.len or 1) / (ARM_FILL * h)
	end
	m.dist = d
	sc:SetCameraPosition(d, 0, 0)
	sc:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
end

-- How its scene projects, read on the screen (nil: it cannot be): two points in front of its camera, at a distance of
-- their own, whatever its weapon and wherever its camera (hidden, it is so far away that the ends of the weapon are
-- less than a point apart: the screen cannot tell how far, 1.14.0 read them so and its weapons came out far too
-- small). Twice: the second time as far apart as the first one says (a third of its height). Kept when it agrees with
-- the rule within three times (as the creatures read it: UI/Card.lua). The answer may come from 0 to 1, from the
-- middle (in pixels), or from a corner in points or in pixels: the middle of the scene tells which.
local READ_AT, READ_TRIES = 3, 20
local function ReadScene(m)
	local sc = m.scene
	local w, h = sc:GetWidth() or 0, sc:GetHeight() or 0
	if not (w > 0 and h > 0) then
		return nil
	end
	local x = (m.dist or FAR) - READ_AT
	local function P(z)
		local ok, px, py = pcall(sc.Project3DPointTo2D, sc, x, 0, z)
		if ok and type(px) == "number" and type(py) == "number" and px == px and py == py then
			return px, py
		end
	end
	local xc, yc = P(0)
	if not (xc and yc) then
		return nil
	end
	local unit
	if xc > 0.4 and xc < 0.6 and yc > 0.4 and yc < 0.6 then
		unit = 1 / h
	elseif math.abs(xc) < 0.05 and math.abs(yc) < 0.05 then
		unit = CuratorOctoFull.GetEffectiveScale(sc)
	elseif xc > 0 and yc > 0 then
		local ux, uy = xc / (w / 2), yc / (h / 2)
		if math.abs(ux - uy) / uy < 0.06 then
			unit = uy
		end
	end
	if not unit then
		return nil
	end
	local rule, cal = Rule(sc, w, h), 1
	for _, share in ipairs({ 0.15, 0.3 }) do
		local s = share * h * READ_AT / (rule * cal)
		local _, yt = P(s)
		local _, yb = P(-s)
		if not (yt and yb) then
			return nil
		end
		local K = math.abs(yt - yb) / unit * READ_AT / (2 * s)
		if not (K > rule / 3 and K < rule * 3) then
			return nil
		end
		cal = K / rule
	end
	return cal
end

-- Its scene read, once it kept its size and its camera since the frame before (what the screen shows is what that
-- frame placed): shown, its weapon there or not yet; a few times at most. Every weapon framed again by it.
local function TryRead(m)
	local sc = m.scene
	if not sc or m.mode ~= "scene" or m.cal or (m.reads or 0) >= READ_TRIES then
		return
	end
	local w, h = sc:GetWidth() or 0, sc:GetHeight() or 0
	local still = m.seenW == w and m.seenH == h and m.seenD == m.dist
	m.seenW, m.seenH, m.seenD = w, h, m.dist
	if not (still and w > 0 and h > 0 and m:IsVisible()) then
		return
	end
	m.reads = (m.reads or 0) + 1
	local cal = ReadScene(m)
	if not cal then
		return
	end
	m.cal, sceneCal = cal, cal
	if ns.db and ns.db.cinedebug and ns.Print then
		ns.Print(string.format(("weapon scene %.0f x %.0f read: %.3f of the rule (try %d)"), w, h, cal, m.reads))
	end
	for other in pairs(ARMS) do
		ArmCamera(other)
	end
end

-- Its model frame (its scene does not show it): as large as its frame, shown; as small as a point, hidden. (Again
-- each time its frame changes its size: CC.ArmFit.)
local function ModelPlace(m)
	local pm = m.model
	if not pm then
		return
	end
	pm:ClearAllPoints()
	if m.mode == "model" and m.ready and m.visible then
		pm:SetAllPoints(m)
	else
		pm:SetPoint("CENTER", m, "CENTER")
		CuratorOctoFull.SetSize(pm, 1, 1)
	end
end
CC.ArmFit = ModelPlace

-- Its turn (yaw): in its scene, or in its model frame.
function CC.ArmFace(m, yaw)
	m.facing = yaw
	if m.mode == "scene" then
		m.actor:SetYaw(yaw)
	elseif m.model then
		m.model:SetFacing(yaw)
	end
end

function CC.ArmFacing(m)
	return m.facing or 0
end

-- Stood up, from the bounds of its model (ARM_POSE: otherwise), shown when it is to be; then m.onReady(m).
local function Stand(m, box)
	local w = m.weapon
	local pose = ARM_POSE[w.id]
	local pitch, roll, yaw = 0, 0, 0
	if pose then
		pitch, roll, yaw = pose[1], pose[2], pose[3]
	elseif box then
		pitch, roll, yaw = CC.Pose(box)
	end
	m.pose = { pitch, roll, yaw }
	m.len = box and math.max(box[4] - box[1], box[5] - box[2], box[6] - box[3]) or 1
	m.ready = true
	if m.mode == "scene" then
		local a = m.actor
		-- (its bounds are those of its model: as large as the actor draws it)
		local ok, k = pcall(a.GetScale, a)
		m.scale = (ok and type(k) == "number" and k > 0.01 and k < 100) and k or 1
		m.len = m.len * m.scale
		pcall(a.SetUseCenterForOrigin, a, true, true, true)
		pcall(a.SetPitch, a, pitch)
		pcall(a.SetRoll, a, roll)
		ArmCamera(m)
	else
		local pm = m.model
		pcall(pm.SetPitch, pm, pitch)
		pcall(pm.SetRoll, pm, roll)
		ModelPlace(m)
	end
	CC.ArmFace(m, yaw + ARM_FACE)
	if ns.db and ns.db.cinedebug and ns.Print then
		local list = {}
		for _, b in ipairs(m.boxes or { box }) do
			list[CuratorOctoFull.Length(list) + 1] = string.format(("%.2f x %.2f x %.2f"), b[4] - b[1], b[5] - b[2], b[6] - b[3])
		end
		local sc = m.scene
		ns.Print(string.format(("weapon %d: %s, bounds %s, length %.2f (actor %.2f), camera %s, scene %s, scale %.3f (%s), creatures %s"), w.id,
			m.mode, CuratorOctoFull.Length(list) > 0 and table.concat(list, " / ") or "none", m.len or 0, m.scale or 1,
			(m.mode == "scene") and string.format(("%.2f"), m.dist or 0) or "of the model frame",
			sc and string.format(("%.0f x %.0f"), sc:GetWidth() or 0, sc:GetHeight() or 0) or "none", SceneScale(m), ScaleFrom(m),
			(ns.Creatures and ns.Creatures.cal) and string.format(("%.3f"), ns.Creatures.cal) or "unread"))
	end
	if m.onReady then
		m.onReady(m)
	end
end

-- Its model frame loaded (its scene does not show it): measured by its file, stood up.
local function ModelLoaded(pm)
	local m = pm.owner
	local w = m and m.weapon
	if not w or m.ready or m.mode ~= "model" then
		return
	end
	pcall(pm.UseModelCenterToTransform, pm, true)
	pcall(pm.SetPosition, pm, 0, 0, 0)
	pcall(pm.SetPortraitZoom, pm, 0)
	pcall(pm.SetCamDistanceScale, pm, ARM_CAM)
	local light = ArmLight()
	if light then
		pcall(pm.SetLight, pm, true, light)
	end
	local ok, file = pcall(pm.GetModelFileID, pm)
	local token = {}
	m.token = token
	Gauge:Ask(ok and file or nil, function(box)
		if m.token == token and m.weapon == w and not m.ready then
			Stand(m, box)
		end
	end)
end

-- Its model frame in the place of its scene (a point until it stands), the item put in it.
local function ToModel(m)
	m.mode = "model"
	if m.actor then
		pcall(m.actor.ClearModel, m.actor)
	end
	ArmCamera(m)
	local pm = m.model
	if not pm then
		m.mode = "none"
		return
	end
	pm:Show()
	ModelPlace(m)
	pm:ClearModel()
	local ok, result = pcall(pm.SetItem, pm, m.weapon.id)
	if not ok or result == false then
		pm:Hide()
		m.mode = "none"
	elseif not pm.hasLoadScript then
		ModelLoaded(pm)
	end
end

-- The bounds its actor gives, once it gives them (nil: not yet): those of its animation, else those of all of them
-- (the files of the weapons give them as tight as the weapon itself, the same for both); all of them as well (for the
-- debug line).
local function Bounds(a, getter)
	if not a[getter] then
		return nil
	end
	local ok, x1, y1, z1, x2, y2, z2 = pcall(a[getter], a)
	if ok and type(x1) == "table" and type(y1) == "table" then
		x1, y1, z1, x2, y2, z2 = x1.x, x1.y, x1.z, y1.x, y1.y, y1.z
	end
	if ok and type(x1) == "number" and type(y1) == "number" and type(z1) == "number" and type(x2) == "number"
		and type(y2) == "number" and type(z2) == "number" and x2 > x1 and y2 > y1 and z2 > z1 then
		return { x1, y1, z1, x2, y2, z2 }
	end
end
local function ActorBox(a)
	local all = {}
	for _, getter in ipairs(GETTERS) do
		local b = Bounds(a, getter)
		if b then
			all[CuratorOctoFull.Length(all) + 1] = b
		end
	end
	return all[1], all
end

-- A frame made to show a weapon, on its parent at that level: its scene in it, and its model frame for a client whose
-- scenes do not show it (nil: the client has neither). CC.Arm(m, w): its weapon (nil: none), shown once it stands;
-- CC.ArmShow(m, on): shown, or hidden all the same; CC.ArmTick(m, elapsed) each frame: true once it stands (m.pose:
-- pitch, roll, yaw).
function CC.NewArm(parent, level)
	local m = CreateFrame("Frame", nil, parent)
	m:SetFrameLevel(level)
	m:EnableMouse(false)
	local ok, sc = pcall(CreateFrame, "ModelScene", nil, m)
	if ok and sc and sc.CreateActor then
		local actor
		for _, template in ipairs({ false, "ModelSceneActorTemplate" }) do
			local made, a = pcall(sc.CreateActor, sc, nil, template or nil)
			if made and a then
				actor = a
				break
			end
		end
		if actor and actor.SetModelByHyperlink then
			sc:SetAllPoints()
			sc:SetFrameLevel(level)
			sc:EnableMouse(false)
			pcall(sc.EnableMouseWheel, sc, false)
			pcall(sc.SetCameraNearClip, sc, 0.05)
			pcall(sc.SetCameraFarClip, sc, 4000)
			pcall(sc.SetAllowOverlappedModels, sc, true)
			pcall(sc.SetCameraFieldOfView, sc, ARM_FOV)
			SceneLight(sc)
			m.scene, m.actor = sc, actor
		elseif sc then
			sc:Hide()
		end
	end
	local okM, pm = pcall(CreateFrame, "PlayerModel", nil, m)
	if okM and pm and pm.SetItem then
		pm:SetFrameLevel(level)
		pm:EnableMouse(false)
		pm.owner = m
		pm.hasLoadScript = CuratorOctoFull.SetScript(pm, "OnModelLoaded", ModelLoaded)
		pm:Hide()
		m.model = pm
	end
	m:Hide()
	if not (m.scene or m.model) then
		return nil
	end
	ArmCamera(m)
	ARMS[m] = true
	return m
end

function CC.Arm(m, w)
	m.weapon, m.set, m.ready, m.pose, m.token, m.len, m.dist, m.boxes, m.scale = w, nil, nil, nil, nil, nil, nil, nil, nil
	m.wait, m.since, m.visible = 0, 0, true
	m.mode = m.scene and "scene" or "model"
	if m.actor then
		pcall(m.actor.ClearModel, m.actor)
	end
	if m.model then
		m.model:ClearModel()
		m.model:Hide()
	end
	ArmCamera(m)
	if not w then
		m:Hide()
		return
	end
	m:Show()
	if not Known(w.id) then
		Ask(w.id)
	end
	CC.ArmTick(m, 0)
end

function CC.ArmShow(m, on)
	m.visible = on and true or false
	ArmCamera(m)
	ModelPlace(m)
end

function CC.ArmTick(m, elapsed)
	local w = m and m.weapon
	if not w then
		return false
	end
	TryRead(m)
	if m.ready then
		return true
	end
	m.wait = (m.wait or 0) + (elapsed or 0)
	if not m.set then
		if not Known(w.id) then
			return false
		end
		m.set, m.since = true, 0
		if m.mode == "scene" then
			local ok, yes = pcall(m.actor.SetModelByHyperlink, m.actor, ItemLink(w.id))
			if not ok or yes == false then
				ToModel(m)
			end
		else
			ToModel(m)
		end
		return false
	end
	if m.mode == "scene" then
		m.since = m.since + (elapsed or 0)
		local a = m.actor
		local box, all
		if a:IsLoaded() then
			box, all = ActorBox(a)
		end
		if box then
			m.boxes = all
			Stand(m, box)
			return true
		elseif m.since > ARM_SCENE_WAIT then
			-- (its scene does not show it: its model frame)
			ToModel(m)
		end
	end
	return m.ready == true
end

-- Its icon in its window, in a ring of gold (on): while its model does not come, or for good on a client without
-- model frames.
local function ArmIcon(f, on)
	local icon = on and not f.armArtFallback and CC.WeaponIcon(f.weapon) or nil
	if icon then
		f.armIcon:SetTexture(icon)
	end
	CuratorOctoFull.SetShown(f.armIcon, icon ~= nil)
	CuratorOctoFull.SetShown(f.armRing, icon ~= nil)
end

-- A card dressed with its weapon (nil: none): its model asked for, shown once it stands. (1.14.0, the Paladin collection
-- redone: flat, a weapon drawn, in the layers of its picture: no model, no icon.)
local function ArmUp(f, w, flat)
	f.weapon = w
	f.flatWeapon = (w and flat) and true or nil
	-- (its turn to and fro from now: as the weapon of an entrance ends it, UI/Crate.lua: CR:Entrance)
	f.armT = 0
	ArmIcon(f, false)
	if f.arm then
		CC.Arm(f.arm, (not flat) and w or nil)
	elseif w and not flat then
		ArmIcon(f, true)
	end
end

-- Each frame: its model set once the game knows its weapon, its icon in its place while it waits too long; standing,
-- it turns to and fro.
-- (where its weapon faces: as it stands, swinging to and fro, turned as the card held in the hand is)
local function ArmYaw(f)
	local arm = f.arm
	return arm.pose[3] + ARM_FACE + math.sin((f.armT or 0) * ARM_SPEED) * ARM_SWING + (f.held and (f.heldYaw or 0) or 0)
end

local function ArmStep(f, elapsed)
	local arm = f.arm
	if not (arm and arm.weapon) then
		return
	end
	if not CC.ArmTick(arm, elapsed) then
		if arm.wait > ARM_WAIT and not f.armIcon:IsShown() then
			ArmIcon(f, true)
		end
		return
	end
	if f.live ~= false then
		f.armT = (f.armT or 0) + ((f.held and f.frozen) and 0 or elapsed)
		CC.ArmFace(arm, ArmYaw(f))
	end
end

-------------------------------------------------------------------------------
-- (1.14.0) A spell of the case of the month: its icon in its medallion, its tree, what it does (asked for while the
-- game does not have it, again now and then)
-------------------------------------------------------------------------------
-- (in points of its texture: the middle of its icon, its size; its tree; what it does: its top, its width, its height
-- at most, its size and the least of it; the shade under the words)
local SPELL_X, SPELL_Y, SPELL_S = 256, 196, 172
local TREE_Y = 322
local DESC_Y, DESC_W, DESC_H, DESC_SIZE, DESC_MIN = 344, 404, 196, 25, 15
local SHADE_Y = 286
-- the seconds between two askings of what a spell does, how long it is asked for
local DESC_AGAIN, DESC_GIVE_UP = 0.25, 12

-- What it does, as small as it needs to fit under its tree (the client cuts what is still too long).
local function FitDesc(f)
	local d = f.spell.desc
	local size = DESC_SIZE
	while true do
		ns.SetFont(d, math.max(7, size * f.k))
		local ok, h = pcall(d.GetStringHeight, d)
		if not ok or type(h) ~= "number" or h <= DESC_H * f.k or size <= DESC_MIN then
			break
		end
		size = size - 1
	end
end

local function SpellText(f)
	local e = f.spellEntry
	if not e then
		return
	end
	local text = ns.CrateItems:Description(e)
	if text then
		f.descPending = nil
		f.spell.desc:SetText(text)
		FitDesc(f)
	else
		f.spell.desc:SetText("")
	end
end

-- A card dressed with its spell (nil: none).
local function SpellUp(f, e)
	local sp = f.spell
	f.spellEntry, f.descPending, f.descAt, f.descSince = e, nil, 0, 0
	if not (sp and e) then
		if sp then
			sp:Hide()
		end
		return
	end
	local col = f.col or { 1, 1, 1 }
	sp.icon:SetTexture(ns.CrateItems:Icon(e) or "Interface\\Icons\\INV_Misc_QuestionMark")
	sp.halo:SetVertexColor(col[1], col[2], col[3], 0.6)
	sp.ring:SetVertexColor(math.min(1, col[1] * 0.5 + 0.55), math.min(1, col[2] * 0.5 + 0.5), math.min(1, col[3] * 0.5 + 0.35), 1)
	sp.tree:SetText(ns.CrateItems:Tree(e) or "")
	f.descPending = true
	SpellText(f)
	sp:Show()
end

local function SpellStep(f, elapsed)
	if not (f.descPending and f.spellEntry) then
		return
	end
	f.descSince = (f.descSince or 0) + elapsed
	if f.descSince > DESC_GIVE_UP then
		f.descPending = nil
		return
	end
	if (f.t or 0) >= (f.descAt or 0) then
		f.descAt = (f.t or 0) + DESC_AGAIN
		SpellText(f)
	end
end

-------------------------------------------------------------------------------
-- (1.14.0) An armour of the case of the month: the character of the player wearing it, in a dressing room of the game
-------------------------------------------------------------------------------
-- (what it takes off first: its shirt, its tabard, its cloak; the seconds a piece the game does not know yet is waited
-- for, the character at most; its turn: where it starts, how fast)
local BARE = { 4, 19, 15 }
local PIECE_WAIT, UNIT_WAIT = 3, 8
local ARMOUR_FACE, ARMOUR_TURN = 0.2, 0.45

-- The icon of its chest in the ring of gold of the window (on): while it dresses, or for good when it cannot.
local function ArmourIcon(f, on)
	local icon = on and f.armour and ns.CrateItems:Icon(f.armour) or nil
	if icon then
		f.armIcon:SetTexture(icon)
	end
	CuratorOctoFull.SetShown(f.armIcon, icon ~= nil)
	CuratorOctoFull.SetShown(f.armRing, icon ~= nil)
end

-- A card dressed with its armour (nil: none): the character of the player, its pieces put on one by one (DressStep).
local function DressUp(f, e)
	f.armour = e
	local m = f.dress
	if not e then
		if m then
			m:Hide()
			pcall(m.ClearModel, m)
		end
		return
	end
	if not m then
		local ok, dm = pcall(CreateFrame, "DressUpModel", nil, f.win)
		if ok and dm and dm.TryOn then
			dm:SetAllPoints()
			dm:EnableMouse(false)
			pcall(dm.EnableMouseWheel, dm, false)
			f.dress, m = dm, dm
			f.base = nil
			Relevel(f)
		end
	end
	ArmourIcon(f, true)
	if not m then
		return
	end
	m.step, m.piece, m.wait, m.since = "unit", 1, 0, 0
	m:Show()
	pcall(m.SetAutoDress, m, true)
	pcall(m.SetUnit, m, "player")
	pcall(m.SetPortraitZoom, m, 0)
	pcall(m.SetCamDistanceScale, m, 1.05)
	pcall(m.SetPosition, m, 0, 0, 0)
	pcall(m.SetFacing, m, ARMOUR_FACE)
	ns.CrateItems:Ask(e)
end

-- Each frame: the character loaded, what it takes off, its pieces put on (a piece the game does not know yet waited
-- for a while, else left out); dressed, it turns slowly.
local function DressStep(f, elapsed)
	local m, e = f.dress, f.armour
	if not (m and e and m:IsShown()) then
		return
	end
	m.since = (m.since or 0) + (elapsed or 0)
	if m.step == "unit" then
		local ok, ready = pcall(m.IsGeoReady, m)
		if ok and not ready then
			if m.since > UNIT_WAIT then
				m.step = "lost"
				m:Hide()
			end
			return
		end
		for _, slot in ipairs(BARE) do
			pcall(m.UndressSlot, m, slot)
		end
		pcall(m.SetSheathed, m, true)
		m.step = "items"
	end
	if m.step == "items" then
		while m.piece <= CuratorOctoFull.Length(e.items) do
			local id = e.items[m.piece]
			local ok, r = pcall(m.TryOn, m, string.format(("item:%d"), id))
			if ok and r == 3 and m.wait < PIECE_WAIT then
				if m.wait == 0 then
					Ask(id)
				end
				m.wait = m.wait + (elapsed or 0)
				return
			end
			m.piece, m.wait = m.piece + 1, 0
		end
		m.step = "done"
		ArmourIcon(f, false)
	end
	if m.step == "done" and f.live ~= false then
		pcall(m.SetFacing, m, ARMOUR_FACE + (f.dressT or 0) * ARMOUR_TURN + (f.held and f.heldYaw or 0))
	end
end

-------------------------------------------------------------------------------
-- (1.14.0) Its forged finish, on a frame of its own over its frame, drawn the same way flat and held in the hand (where
-- the card is turned in 3D, its pieces follow it: card:SetPose).
-- * thunderforged: as the cards of the albums are (UI/Card.lua, Card:Crackle): the two drawings of their lightning
--   (ThunderArcs) crawling over it, one then the other, faint; every few seconds (card:Strike: now) it strikes, the
--   whole card crackling three times; the cold light along its edge (CardRim); their twinkles, anywhere on it
-- * titanforged: the metal of its frame in all the colours of the rainbow (CrateFoil<rank>: the metal of its frame in
--   its alpha, its facets in grey), flowing with the time and the turn of the card; the light along its edge through
--   the colours; in its window, behind its creature, a foil of all the colours and the light of the prism (two wheels
--   of rays of the rainbow turning each its way), as on the cards of the albums; its twinkles of all the colours, on
--   the metal of its frame
-- (each texture over the whole card is cut in cells, so that the card held in the hand bends it with it)
-------------------------------------------------------------------------------
local TAU = math.pi * 2
local FOIL_COLS, FOIL_ROWS = 8, 12
local TWINKLES = 16
-- (titanforged: how much of its metal the colours take)
CC.PRISM_A = 0.55
-- (thunderforged: the cold light of its edge, as on the cards of the albums)
local THUNDER_RIM = { 0.42, 0.68, 1 }

-- (the colours of the rainbow: h from 0 to 1, round)
local function Rainbow(h)
	return 0.5 + 0.5 * math.cos(TAU * h), 0.5 + 0.5 * math.cos(TAU * (h - 1 / 3)), 0.5 + 0.5 * math.cos(TAU * (h - 2 / 3))
end
CC.Rainbow = Rainbow

-- (1.14.0, his idea) the colours of a titanforged card of its pattern (Patterns.lua: pat, its look), else those of the
-- rainbow
local function Hue(pat, h)
	if pat and pat.tint then
		return ns.Patterns.Color(pat, h)
	end
	return Rainbow(h)
end

-- (a texture of a cell made flat again: its corners where it is)
local function Unwarp(t)
	if t.ClearVertexOffsets then
		t:ClearVertexOffsets()
	elseif t.SetVertexOffset then
		for v = 1, 4 do
			t:SetVertexOffset(v, 0, 0)
		end
	end
end

-- (a small piece of its finish where it is on the card, w x h points of its texture at x, y: flat, or where the card
-- held in the hand puts its corners)
local function PlaceFx(self, t, x, y, w, h)
	local k = self.k
	t:ClearAllPoints()
	t:SetPoint("CENTER", self, "TOPLEFT", x * k, -y * k)
	CuratorOctoFull.SetSize(t, w * k, (h or w) * k)
	if self.held and self.R and ns.Card3D then
		local cx, cy = x * k - self.W / 2, self.H / 2 - y * k
		local hw, hh = w * k / 2, (h or w) * k / 2
		ns.Card3D.WarpQuad(self, t, cx - hw, cy - hh, cx + hw, cy + hh)
		t.warped = true
	elseif t.warped then
		Unwarp(t)
		t.warped = nil
	end
end

-- (cells over a grid of the card, for a texture laid over the whole card: where each is, from 0 to 1, its left, its
-- right, its top, its foot)
local function FxCells(f, parent, grid, layer, sub)
	local m = ns.Card3D.Cells(f, parent, grid, layer, sub)
	local xs, ys = grid.xs, grid.ys
	local gw, gh = grid.x2 - grid.x1, grid.y2 - grid.y1
	m.part = {}
	for k = 1, CuratorOctoFull.Length(m) do
		local t, i, j = m[k], m.ci[k], m.cj[k]
		m.part[k] = { (xs[i] - grid.x1) / gw, (xs[i + 1] - grid.x1) / gw, (grid.y2 - ys[j]) / gh, (grid.y2 - ys[j + 1]) / gh }
		t:SetBlendMode("ADD")
		t:Show()
	end
	return m
end

-- (its cells given a texture, each its part of it: u1, how much of its width is the card)
local function CellsTexture(m, file, u1)
	u1 = u1 or 1
	for k = 1, CuratorOctoFull.Length(m) do
		local t, p = m[k], m.part[k]
		t:SetTexture(file)
		t:SetTexCoord(p[1] * u1, p[2] * u1, p[3], p[4])
	end
end

-- Its forge: the frame of its finish, its cells, its small pieces.
CC.CellsTexture = CellsTexture

local function BuildForge(f)
	local w, h = f.W, f.H
	local ff = CreateFrame("Frame", nil, f)
	ff:SetAllPoints()
	ff:SetFrameLevel(f:GetFrameLevel() + 8)
	ff:Hide()
	f.forge = ff
	local D = ns.Card3D
	local fin = { tw = {} }
	f.fin = fin
	fin.grid = D.Grid(-w / 2, -h / 2, w / 2, h / 2, FOIL_COLS, FOIL_ROWS)
	fin.foil = FxCells(f, ff, fin.grid, "BORDER", 1)
	CellsTexture(fin.foil, MEDIA .. "CrateFoil1")
	-- (the colours of each cell, from its left to its right: kept to be given again)
	if CreateColor then
		for k = 1, CuratorOctoFull.Length(fin.foil) do
			local t = fin.foil[k]
			t.c1, t.c2 = CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 1)
		end
	end
	fin.rimGrid = D.Grid(-w / 2, -h / 2, w / 2, h / 2, 3, 4)
	-- (31 October, his word: titanforged, its frame shows the shapes of its pattern too: the foil of its window on the
	-- metal of its frame, Media\\Holo\\C<v>_<i>, three of them shown by weights that turn, as its window)
	fin.facets = {}
	for i = 1, 3 do
		fin.facets[i] = FxCells(f, ff, fin.rimGrid, "BORDER", 2 + i)
	end
	fin.rim = FxCells(f, ff, fin.rimGrid, "BORDER", 6)
	CellsTexture(fin.rim, MEDIA .. "CardRim", RIM_R)
	-- (thunderforged: the two drawings of the lightning of the cards of the albums, over the whole card as on them)
	fin.arcs = {}
	for i = 1, 2 do
		fin.arcs[i] = FxCells(f, ff, fin.rimGrid, "ARTWORK", 5)
		CellsTexture(fin.arcs[i], MEDIA .. "ThunderArcs" .. i, RIM_R)
	end
	for i = 1, TWINKLES do
		local tw = Tex(ff, "OVERLAY", 6, "Twinkle", "ADD")
		tw:Hide()
		fin.tw[i] = { tex = tw, cycle = -1 }
	end
end

-- CC.New(parent, w): a card of a case w wide (its height after it: 717 / 512). card:Set(pick, ranks) (pick: tier,
-- card, word, finish; weapon: its weapon, a priceless card; entry: a card of the case of the month; secret: the golden
-- card of the secret), card:Sweep(), card:Strike(), card:SetLive(on).
function CC.New(parent, w)
	local h = w * TH / TW
	local f = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(f, w, h)
	f.W, f.H, f.k = w, h, w / TW
	f.phase = math.random()
	local k = f.k
	local base = f:GetFrameLevel()
	-- (what is under its window, on a frame of its own: held in the hand, it steps aside)
	local low = CreateFrame("Frame", nil, f)
	low:SetAllPoints()
	low:SetFrameLevel(base)
	f.low = low
	-- behind it: its rays (the priceless rank), the parts of its rank behind its frame (wings, horns, flames)
	f.rays = {}
	for i = 1, 2 do
		local r = Tex(low, "BACKGROUND", -8 + i - 1, "Rays", "ADD")
		r:SetPoint("CENTER", f, "CENTER", 0, 0)
		CuratorOctoFull.SetSize(r, h * (i == 1 and 1.75 or 1.45), h * (i == 1 and 1.75 or 1.45))
		r:Hide()
		f.rays[i] = r
	end
	f.under = {}
	for i = 1, MAX_UNDER do
		f.under[i] = Tex(low, "BACKGROUND", math.min(-1, -7 + i))
		f.under[i]:Hide()
	end
	-- its window: its ground, the light behind its creature
	f.ground = Tex(low, "BACKGROUND", 0)
	Place(f.ground, f, unpack(WIN))
	f.aura = Tex(low, "BACKGROUND", 1, "Glow", "ADD")
	f.aura:SetPoint("CENTER", f, "TOPLEFT", (WIN[1] + WIN[3]) / 2 * k, -(WIN[2] + (WIN[4] - WIN[2]) * 0.46) * k)
	CuratorOctoFull.SetSize(f.aura, (WIN[3] - WIN[1]) * k * 1.1, (WIN[3] - WIN[1]) * k * 1.1)
	-- (1.14.0, the Paladin collection redone) the picture of a card of a style, over all of it under its frame; over it the
	-- reflections of a priceless card (still, as much as the light comes from their side: CC.Shine)
	f.art = Tex(low, "BACKGROUND", -6)
	Place(f.art, f, unpack(ART))
	f.art:Hide()
	f.layers = {}
	for i = 1, SHINES do
		local t = Tex(low, "BACKGROUND", -6 + i, nil, "ADD")
		Place(t, f, unpack(ART))
		t:Hide()
		f.layers[i] = t
	end
	local win = CreateFrame("Frame", nil, f)
	Place(win, f, unpack(WIN))
	win:SetFrameLevel(base + 1)
	f.win = win
	-- (the pieces drawn in its window, on a frame of their own; its creature, its armour, its weapon in the window itself)
	local wt = CreateFrame("Frame", nil, win)
	wt:SetAllPoints()
	wt:SetFrameLevel(base + 1)
	f.winTex = wt
	-- (behind its creature: the circle of runes, embers)
	f.rune = Tex(wt, "ARTWORK", 0, "TitanRing", "ADD")
	f.rune:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(f.rune, (WIN[3] - WIN[1]) * k * 0.92, (WIN[3] - WIN[1]) * k * 0.92)
	f.rune:Hide()
	f.orbGlow = Tex(low, "BACKGROUND", -6, "Glow", "ADD")
	f.orbGlow:Hide()
	f.pic = wt:CreateTexture(nil, "ARTWORK", nil, 2)
	f.pic:SetAllPoints()
	f.pic:Hide()
	-- (titanforged: a foil of all the colours over its ground, three of them shown by weights that turn; the light of the
	-- prism behind its creature, two wheels of rays of the rainbow)
	f.winFoil = {}
	for i = 1, 3 do
		local fo = Tex(wt, "BACKGROUND", i, "TitanWindow" .. i, "ADD")
		Place(fo, f, unpack(WIN))
		fo:Hide()
		f.winFoil[i] = fo
	end
	-- (31 October, his word: the foil of the window of the cards of the cases seen better) a second one, mirrored, over
	-- it: twice its light, its shapes everywhere
	f.winFoil2 = {}
	for i = 1, 3 do
		local fo = Tex(wt, "BACKGROUND", 3 + i, "TitanWindow" .. i, "ADD")
		fo:SetTexCoord(1, 0, 1, 0)
		Place(fo, f, unpack(WIN))
		fo:Hide()
		f.winFoil2[i] = fo
	end
	f.glory = {}
	for i = 1, 2 do
		local g = Tex(wt, "BORDER", i, "PrismRays", "ADD")
		g:SetPoint("CENTER", f.aura, "CENTER")
		local gs = (WIN[3] - WIN[1]) * k * (i == 1 and 1.05 or 0.7)
		CuratorOctoFull.SetSize(g, gs, gs)
		g:Hide()
		f.glory[i] = g
	end
	f.scene = ns.Creatures and ns.Creatures.Stage and ns.Creatures.Stage(win, base + 2, { live = true, spin = true, playerModel = true }) or nil
	-- (the weapon of a priceless card in its place: a model frame, the weapon standing and turning in it; its icon in a
	-- ring of gold when it has no model)
	local arm = CC.NewArm(win, base + 2)
	if arm then
		arm:SetAllPoints()
		arm.onReady = function()
			ArmIcon(f, false)
			if f.armArtFallback then
				f:SetPic(nil)
				f.ground:Show()
				f.aura:Show()
			end
		end
		f.arm = arm
	end
	local isz = (WIN[3] - WIN[1]) * k * 0.46
	f.armIcon = wt:CreateTexture(nil, "ARTWORK", nil, 3)
	f.armIcon:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(f.armIcon, isz, isz)
	f.armIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.armIcon:Hide()
	local round = CuratorOctoFull.CreateMaskTexture(wt)
	round:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	round:SetAllPoints(f.armIcon)
	CuratorOctoFull.AddMaskTexture(f.armIcon, round)
	f.armRing = Tex(wt, "ARTWORK", 4, "IconRing")
	f.armRing:SetPoint("CENTER", f.armIcon, "CENTER")
	CuratorOctoFull.SetSize(f.armRing, isz * 1.22, isz * 1.22)
	f.armRing:SetVertexColor(1, 0.84, 0.4)
	f.armRing:Hide()
	-- (1.14.0) a spell of the case of the month: its medallion (its light, its icon cut round, the ring of its rank), its
	-- tree, what it does on a shade
	local sp = CreateFrame("Frame", nil, win)
	sp:SetAllPoints()
	sp:SetFrameLevel(base + 2)
	sp:Hide()
	f.spell = sp
	-- (the shade: FadeMask, clear on its left and solid on its right, turned to be clear at its top and solid at its foot)
	sp.shade = Tex(sp, "BACKGROUND", 0, "FadeMask")
	sp.shade:SetPoint("TOPLEFT", f, "TOPLEFT", WIN[1] * k, -SHADE_Y * k)
	sp.shade:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", WIN[3] * k, -WIN[4] * k)
	sp.shade:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
	sp.shade:SetVertexColor(0, 0, 0, 0.72)
	sp.halo = Tex(sp, "BORDER", 0, "Glow", "ADD")
	At(sp.halo, f, SPELL_X, SPELL_Y, SPELL_S * 2.1)
	sp.icon = sp:CreateTexture(nil, "ARTWORK", nil, 1)
	At(sp.icon, f, SPELL_X, SPELL_Y, SPELL_S)
	sp.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	local disc = CuratorOctoFull.CreateMaskTexture(sp)
	disc:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	disc:SetAllPoints(sp.icon)
	CuratorOctoFull.AddMaskTexture(sp.icon, disc)
	sp.ring = Tex(sp, "ARTWORK", 2, "IconRing")
	At(sp.ring, f, SPELL_X, SPELL_Y, SPELL_S * 1.24)
	sp.tree = Text(sp, math.max(8, 22 * k), "OUTLINE")
	sp.tree:SetPoint("CENTER", f, "TOPLEFT", SPELL_X * k, -TREE_Y * k)
	sp.tree:SetTextColor(1, 0.84, 0.42)
	sp.desc = Text(sp, math.max(7, DESC_SIZE * k))
	sp.desc:SetPoint("TOP", f, "TOPLEFT", SPELL_X * k, -DESC_Y * k)
	sp.desc:SetWidth(DESC_W * k)
	sp.desc:SetJustifyH("CENTER")
	sp.desc:SetJustifyV("TOP")
	CuratorOctoFull.SetWordWrap(sp.desc, true)
	sp.desc:SetTextColor(0.95, 0.93, 0.88)
	local front = CreateFrame("Frame", nil, f)
	front:SetAllPoints()
	front:SetFrameLevel(base + 3)
	f.front = front
	f.embers = {}
	for i = 1, EMBERS do
		local e = Tex(CuratorOctoFull.Mod(i , 3) == 0 and front or wt, "OVERLAY", 0, "Glow", "ADD")
		e:Hide()
		f.embers[i] = { tex = e }
	end
	-- the golden card of the secret, over the window
	local sec = CreateFrame("Frame", nil, f)
	sec:SetAllPoints()
	sec:SetFrameLevel(base + 5)
	sec:Hide()
	f.secret = sec
	sec.shine = Tex(sec, "BORDER", 0, "Glow", "ADD")
	sec.shine:SetVertexColor(1, 0.86, 0.45, 0.75)
	sec.shine:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(sec.shine, (WIN[3] - WIN[1]) * k, (WIN[3] - WIN[1]) * k)
	sec.medal = Tex(sec, "ARTWORK", 0, "AchMedal")
	sec.medal:SetPoint("CENTER", f.aura, "CENTER")
	CuratorOctoFull.SetSize(sec.medal, (WIN[3] - WIN[1]) * k * 0.74, (WIN[3] - WIN[1]) * k * 0.74)
	sec.q = Text(sec, math.max(14, 100 * k), "THICKOUTLINE")
	sec.q:SetPoint("CENTER", sec.medal, "CENTER", 0, 2)
	sec.q:SetText("?")
	sec.q:SetTextColor(1, 0.95, 0.72)

	-- over it: the shadow of the edges of the window, its frame, its forged finish, its glow, its wear, the parts of its
	-- rank over it, its words, its sparks
	local o = CreateFrame("Frame", nil, f)
	o:SetAllPoints()
	o:SetFrameLevel(base + 7)
	f.over = o
	f.vig = Tex(o, "BACKGROUND", 0, "Vignette")
	Place(f.vig, f, unpack(WIN))
	f.vig:SetVertexColor(0, 0, 0, 0.85)
	f.frame = Tex(o, "BORDER", 0)
	f.frame:SetAllPoints()
	-- its forged finish: on a frame of its own over its frame (BuildForge)
	BuildForge(f)
	-- (the shine of the gold of the priceless rank under a light from each side)
	f.gloss = {}
	for i = 1, 4 do
		local gl = Tex(o, "BORDER", 7, nil, "ADD")
		gl:SetAllPoints()
		gl:Hide()
		f.gloss[i] = gl
	end
	f.glow = Tex(o, "ARTWORK", -2, nil, "ADD")
	f.glow:SetPoint("TOPLEFT", f, "TOPLEFT", -GM * k, GM * k)
	CuratorOctoFull.SetSize(f.glow, (TW + 2 * GM) * k, (TH + 2 * GM) * k)
	-- (31 October, his word: the cards of the cases rarer than those of the boosters) titanforged: an aura of all the
	-- colours all along its edge, in and out of it, the light running round it (CrateAura1..3, by weights that turn)
	f.titanAura = {}
	for i = 1, 3 do
		local a = Tex(o, "ARTWORK", -3, "CrateAura" .. i, "ADD")
		a:SetPoint("TOPLEFT", f, "TOPLEFT", -GM * k, GM * k)
		CuratorOctoFull.SetSize(a, (TW + 2 * GM) * k, (TH + 2 * GM) * k)
		a:Hide()
		f.titanAura[i] = a
	end
	-- (the parts over it, each over the one before it)
	f.parts = {}
	for i = 1, MAX_OVER do
		f.parts[i] = Tex(o, "ARTWORK", i - 1)
		f.parts[i]:Hide()
	end
	f.name = Text(o, math.max(9, 34 * k), "OUTLINE")
	f.name:SetPoint("CENTER", f, "TOPLEFT", (PLATE[1] + PLATE[3]) / 2 * k, -(PLATE[2] + 44) * k)
	CuratorOctoFull.SetWordWrap(f.name, false)
	f.name:SetWidth(410 * k)
	f.rank = Text(o, math.max(8, 25 * k), "OUTLINE")
	f.rank:SetPoint("CENTER", f, "TOPLEFT", (PLATE[1] + PLATE[3]) / 2 * k, -(PLATE[2] + 92) * k)
	f.sparks = {}
	for i = 1, 4 do
		local s = Tex(o, "OVERLAY", 1, "Twinkle", "ADD")
		s:Hide()
		f.sparks[i] = { tex = s }
	end
	-- (the sheen that passes over it: of the colour of its finish on a forged card, gold on a priceless one)
	local sb = CreateFrame("Frame", nil, f)
	sb:SetAllPoints()
	sb:SetFrameLevel(base + 9)
	CuratorOctoFull.SetClipsChildren(sb, true)
	f.sheenBox = sb
	f.sheen = Tex(sb, "OVERLAY", 0, "Sheen", "ADD")
	CuratorOctoFull.SetSize(f.sheen, w * 1.5, h * 1.2)
	f.sheen:SetAlpha(0)
	-- (31 October, his word: the cards of the cases worn as those of the boosters) its wear, over all that is printed on it,
	-- its forged finish too, under its back (UI/Wear.lua: its pieces on a frame of their own; in 3D cells over its words)
	local wf = CreateFrame("Frame", nil, f)
	wf:SetAllPoints()
	wf:SetFrameLevel(base + 9)
	wf:Hide()
	f.wearF = wf
	f.wearFlip, f.wearTurn = {}, {}
	-- (1.14.0) its back, seen when it is turned in the hand (UI/Inspect.lua): the one of its case (card:SetBack)
	local bk = CreateFrame("Frame", nil, f)
	bk:SetAllPoints()
	bk:SetFrameLevel(base + 10)
	bk:Hide()
	f.backF = bk
	f.backT = bk:CreateTexture(nil, "ARTWORK")
	f.backT:SetAllPoints()
	-- (1.14.0, after its second test) over both sides: the card white-hot for an instant (the light of the verdict of an
	-- expert, UI/Expertise.lua), as the cards of the boosters
	local hot = CreateFrame("Frame", nil, f)
	hot:SetAllPoints()
	hot:SetFrameLevel(base + 11)
	f.hotF = hot
	f.hot = hot:CreateTexture(nil, "OVERLAY")
	f.hot:SetAllPoints()
	f.hot:SetTexture(MEDIA .. "CardMask")
	f.hot:SetBlendMode("ADD")
	f.hot:SetAlpha(0)

	for key, fn in pairs(CC.methods) do
		f[key] = fn
	end
	f:SetBack(nil)
	CuratorOctoFull.SetScript(f, "OnUpdate", CC.Update)
	return f
end

-------------------------------------------------------------------------------
-- What a card of a case does
-------------------------------------------------------------------------------
local M = {}
CC.methods = M

-- Its rank (1 to 5): its frame, its ground, its glow, the steel of its frame, the parts of its rank, what moves on it.
function M:SetRank(tier)
	tier = math.max(1, math.min(CuratorOctoFull.Length(CC.ART), tier or 1))
	-- (1.14.0, the Paladin collection redone: the frames of its style, nothing round it)
	local st = self.style
	local look = (st and st.frames or "CrateRank") .. tier
	if self.look == look then
		return
	end
	self.look = look
	self.tier = tier
	local art = CC.ART[tier]
	local file = MEDIA .. (st and st.frames or "CrateRank") .. tier
	self.frame:SetTexture(file)
	self.ground:SetTexture(MEDIA .. "CrateGround" .. tier)
	self.ground:SetTexCoord(0, 1, 0, 1)
	self.glow:SetTexture(file)
	if st then
		self.frame:SetTexCoord(TC(0, 0, TW, TH, 512, 1024))
		local g = st.glow
		self.glow:SetTexCoord(TC(g[1], g[2], g[3], g[4], 512, 1024))
		CellsTexture(self.fin.foil, MEDIA .. st.foil .. tier)
	else
		self.frame:SetTexCoord(unpack(FRAME_TC))
		local g = art.glow
		self.glow:SetTexCoord(TC(g[1], g[2], g[3], g[4], 1024, 1024))
		CellsTexture(self.fin.foil, MEDIA .. "CrateFoil" .. tier)
	end
	-- (the parts of its rank: over its frame, or under it)
	local no, nu = 0, 0
	for _, p in ipairs(st and {} or art.parts) do
		local t
		if p[10] then
			nu = nu + 1
			t = self.under[nu]
		else
			no = no + 1
			t = self.parts[no]
		end
		if t then
			t:SetTexture(file)
			local u0, u1, v0, v1 = TC(p[2], p[3], p[4], p[5], 1024, 1024)
			if p[6] then
				u0, u1 = u1, u0
			end
			if p[7] then
				v0, v1 = v1, v0
			end
			t:SetTexCoord(u0, u1, v0, v1)
			t:SetBlendMode(p[11] or "BLEND")
			-- (where it is on the card, its size there: the art of the part, or the size given it)
			local pw, ph = p[12] or (p[4] - p[2]), p[13] or (p[5] - p[3])
			Place(t, self, p[8], p[9], p[8] + pw, p[9] + ph)
			t.key, t.x, t.y, t.w, t.h = p[1], p[8], p[9], pw, ph
			t:Show()
		end
	end
	for i = no + 1, MAX_OVER do
		self.parts[i]:Hide()
		self.parts[i].key = nil
	end
	for i = nu + 1, MAX_UNDER do
		self.under[i]:Hide()
		self.under[i].key = nil
	end
	-- (the shine of its gold: its four lights, from its two textures)
	local glint
	if st then
		glint = st.glint and st.glint[tier]
	else
		glint = art.glint
	end
	self.glint = glint
	for i, gl in ipairs(self.gloss) do
		if glint then
			gl:SetTexture(MEDIA .. glint .. (i <= 2 and "a" or "b"))
			local x0 = (CuratorOctoFull.Mod(i , 2) == 1) and 0 or 512
			gl:SetTexCoord(TC(x0, 0, x0 + 512, 717, 1024, 1024))
			gl:SetAlpha(0)
			gl:Show()
		else
			gl:Hide()
		end
	end
	At(self.orbGlow, self, ORB_X, ORB_Y, ORB_R * 4.2)
	self.orbGlow:SetVertexColor(1, 0.3, 0.8)
	CuratorOctoFull.SetShown(self.orbGlow, tier == 3 and not st)
	-- (what moves on it, by its rank; nothing round a card of a style)
	for _, r in ipairs(self.rays) do
		CuratorOctoFull.SetShown(r, tier == 5 and not st)
		r:SetVertexColor(1, 0.8, 0.38)
	end
	CuratorOctoFull.SetShown(self.rune, tier == 2 and not st)
	self.rune:SetVertexColor(0.72, 0.48, 1)
	for _, e in ipairs(self.embers) do
		e.tex:Hide()
		e.age = nil
	end
	for _, s in ipairs(self.sparks) do
		s.tex:Hide()
		s.age = nil
	end
end

-- The part of its rank over it or behind it named key (keystone, crystals, orb, clusterTL, hornL, flame1, sun...), when
-- it has it.
function M:Part(key)
	for _, t in ipairs(self.parts) do
		if t.key == key and t:IsShown() then
			return t
		end
	end
	for _, t in ipairs(self.under) do
		if t.key == key and t:IsShown() then
			return t
		end
	end
end

-- Dressed as pick: { tier, card, word, finish } (secret: the golden card of the secret); ranks: the ranks of the
-- cases (UI/Crate.lua: their colours, their words).
function M:Set(pick, ranks, opening3D)
	opening3D = opening3D or pick.opening3D
	Relevel(self)
	self.pick = pick
	local rank = ranks[pick.tier]
	local col = rank.color
	self.col = col
	-- (1.14.0, the Paladin collection redone) its style: the one of its collection (its picture over all of it, under the
	-- thin frame of its rank), else the cards of the first cases
	local st = CC.StyleOf(pick)
	if st ~= self.style or self.laid == nil then
		self.style = st
		self:Lay()
	end
	self:SetRank(pick.tier)
	local secret = pick.secret and true or false
	CuratorOctoFull.SetShown(self.secret, secret)
	self.aura:SetVertexColor(col[1], col[2], col[3], 0.32)
	-- its forged finish when it came so (its time from its start); (1.14.0, his idea) titanforged, its pattern
	self.t = 0
	self.pat = (not secret) and pick.finish == "titan" and ns.Patterns and ns.Patterns:Look(pick.pt) or nil
	self:SetFinish((not secret) and pick.finish or nil)
	-- its wear (none on the golden card of the secret): UI/Wear.lua, from what Cases.lua tells of it (CS.WearOf)
	if ns.WearUI then
		ns.WearUI.Set(self, (not secret) and pick.wear or nil, true)
	end
	-- its words (a weapon: its name once the game knows it)
	local weapon = (not secret) and pick.weapon or nil
	local entry = (not secret) and (not weapon) and pick.entry or nil
	self.namePending = nil
	if secret then
		self.name:SetText(L["Priceless card"])
		self.name:SetTextColor(1, 0.86, 0.42)
		self.rank:SetText("")
	else
		if weapon then
			local name = CC.WeaponName(weapon)
			self.name:SetText(name or L["Priceless card"])
			self.namePending = (name == nil) or nil
		elseif entry then
			self.name:SetText(ns.CrateItems:Name(entry))
		else
			self.name:SetText(pick.card and C:Name(pick.card) or "")
		end
		self.name:SetTextColor(1, 1, 1)
		-- (1.14.0: titanforged, its pattern after its rank)
		-- (1 November, his word: its pattern written on the card no more: the masters of the mages tell it, Mages.lua)
		self.rank:SetText(L[rank.label])
		local tc = rank.text or col
		self.rank:SetTextColor(tc[1], tc[2], tc[3])
	end
	self:FitName()
	-- (a card of a style: its picture; a weapon of legend of its case, its picture and its reflections; the golden card of
	-- the secret, the light of the priceless rank behind its medal)
	local wart = st and weapon and CC.WeaponArt(weapon) or nil
	local pic
	if st then
		pic = (entry and entry.pic) or (wart and wart.pic) or (secret and "CrateGround5") or nil
	end
	self:SetPic(pic and (MEDIA .. pic) or nil, wart)
	CuratorOctoFull.SetShown(self.ground, pic == nil)
	CuratorOctoFull.SetShown(self.aura, pic == nil)
	-- its weapon, standing in its window; a spell, its medallion; an armour, the character wearing it; else its creature:
	-- in its scene, alive; else its portrait
	self.armArtFallback = opening3D and weapon and pic ~= nil
	ArmUp(self, weapon, pic ~= nil and not self.armArtFallback)
	SpellUp(self, (not pic) and entry and entry.kind == "spell" and entry or nil)
	DressUp(self, (not pic) and entry and entry.kind == "set" and entry or nil)
	local display
	if not (secret or weapon) and (not pic or opening3D) then
		if entry then
			display = entry.kind == "npc" and entry.display or nil
		else
			display = pick.card and pick.card.display or nil
		end
	end
	local sc = self.scene
	local modelShown = false
	if sc then
		if display then sc:Show() end
		modelShown = ns.Creatures.Put(sc, display)
		CuratorOctoFull.SetShown(sc, modelShown and true or false)
	end
	if modelShown and pic then
		self:SetPic(nil)
		self.ground:Show()
		self.aura:Show()
	end
	if not modelShown and display and not pic then
		local w, h = self.win:GetWidth(), self.win:GetHeight()
		local ok = display and SetPortraitTextureFromCreatureDisplayID and pcall(SetPortraitTextureFromCreatureDisplayID, self.pic, display)
		if ok then
			local kk = (1 - w / h) / 2
			if w < h then
				self.pic:SetTexCoord(kk, 1 - kk, 0, 1)
			end
			self.pic:Show()
		else
			local portrait = ns.Portraits and ns.Portraits[display]
			if portrait then
				self.pic:SetTexture(MEDIA .. "Portraits\\" .. display)
				self.pic:SetTexCoord(unpack(portrait))
				self.pic:Show()
			else
				self.pic:Hide()
			end
		end
	else
		self.pic:Hide()
	end
	self.t, self.nextSheen, self.nextSpark, self.nextEmber, self.nameAt = 0, 1.2, 0.3, 0, 0
	self.sweepT = nil
	self.sheen:SetAlpha(0)
	if self.held then
		self:HeldSync()
	end
	CC.Update(self, 0)
end

-- Its name made smaller until it fits its plate (the client cuts what is still too long). (1.14.0, after its second test:
-- a small card, in the slots of the pages of an album, UI/CaseAlbum.lua: smaller still, and on two lines when it must.)
local SMALL_K = 0.3
function M:FitName()
	local k = self.k
	local fs = self.name
	local st = self.style
	local room = (st and st.nameW or 410) * k
	local small = k < SMALL_K
	local size = math.max(9, (st and 31 or 34) * k)
	local least = small and 6 or 8
	CuratorOctoFull.SetWordWrap(fs, false)
	if fs.SetMaxLines then
		CuratorOctoFull.SetMaxLines(fs, 1)
	end
	ns.SetFont(fs, size, "OUTLINE")
	while size > least and ns.TextWidth(fs) > room do
		size = size - 0.5
		ns.SetFont(fs, size, "OUTLINE")
	end
	local two = small and ns.TextWidth(fs) > room
	if two then
		ns.SetFont(fs, math.max(least, 7), "OUTLINE")
		CuratorOctoFull.SetWordWrap(fs, true)
		if fs.SetMaxLines then
			CuratorOctoFull.SetMaxLines(fs, 2)
		end
	end
	if small or self.twoLines then
		self.twoLines = two or nil
		self:PlaceWords(two)
	end
end

-- Its name and its rank on its plate (two: its name on two lines), where its style puts them.
function M:PlaceWords(two)
	local k, st = self.k, self.style
	local mid = (PLATE[1] + PLATE[3]) / 2 * k
	local ny = st and (two and st.nameY2 or st.nameY) or (PLATE[2] + (two and 50 or 44))
	local ry = st and (two and st.rankY2 or st.rankY) or (PLATE[2] + (two and 104 or 92))
	self.name:ClearAllPoints()
	self.name:SetPoint("CENTER", self, "TOPLEFT", mid, -ny * k)
	self.rank:ClearAllPoints()
	self.rank:SetPoint("CENTER", self, "TOPLEFT", mid, -ry * k)
end

-- (1.14.0, the Paladin collection redone) Its pieces where its style puts them: the light behind its creature (and the
-- golden card of the secret over it), the foil of its window (titanforged), its words; the shadow of the edges of its
-- window (a style has its own, in its frame).
function M:Lay()
	local k, st = self.k, self.style
	self.laid = true
	local box = st and VIEW or WIN
	self.aura:ClearAllPoints()
	self.aura:SetPoint("CENTER", self, "TOPLEFT", (box[1] + box[3]) / 2 * k, -(box[2] + (box[4] - box[2]) * 0.46) * k)
	for _, fo in ipairs(self.winFoil) do
		Place(fo, self, unpack(box))
	end
	for _, fo in ipairs(self.winFoil2) do
		Place(fo, self, unpack(box))
	end
	CuratorOctoFull.SetShown(self.vig, not st)
	self.name:SetWidth((st and st.nameW or 410) * k)
	ns.SetFont(self.rank, math.max(8, (st and 22 or 25) * k), "OUTLINE")
	self.twoLines = nil
	self:PlaceWords(false)
	self.look = nil
end

-- Its picture (file: a texture; nil: none) and the reflections of its weapon of legend (wart: the weapon of its case,
-- Data/Crate*.lua: shine, its four textures, the light from the left, from the right, from above, from below): its
-- picture still, its reflections over it as much as the light comes from their side (CC.Shine).
function M:SetPic(file, wart)
	local on = file ~= nil
	CuratorOctoFull.SetShown(self.art, on)
	if on then
		self.art:SetTexture(file, "CLAMP", "CLAMP")
		self.art:SetTexCoord(0, 1, 0, 1)
		self.art:SetAlpha(1)
	end
	local shine = on and wart and wart.shine or nil
	for i, t in ipairs(self.layers) do
		if shine then
			t:SetTexture(MEDIA .. shine .. i, "CLAMP", "CLAMP")
			t:SetTexCoord(0, 1, 0, 1)
			t:SetBlendMode("ADD")
			t:SetVertexColor(1, 1, 1)
			t:SetAlpha(0)
			t:Show()
		else
			t:Hide()
		end
	end
	self.layered = shine and true or nil
	if self.layered then
		CC.Light(self, self.t or 0)
		CC.Shine(self)
	end
	if self.held then
		self:HeldSync()
	end
end

-- A sheen passing over it, now.
function M:Sweep(dur)
	self.sweepT, self.sweepDur = 0, dur or 1
end

-- Its forged finish ("thunder", "titan"; nil: none): its forge shown, all of it at its start.
function M:SetFinish(kind)
	local fin = self.fin
	self.finish = kind
	CuratorOctoFull.SetShown(self.forge, kind ~= nil and self.facing ~= "back" and not self.flatBack)
	for _, tw in ipairs(fin.tw) do
		tw.tex:Hide()
		tw.cycle = -1
	end
	-- (1.14.0, his idea: a pattern of colours of its own, Patterns.lua: the foil of its window and its light without
	-- their colours, in those of the pattern)
	local pat = kind == "titan" and self.pat or nil
	local tint = pat ~= nil and pat.tint ~= nil
	-- (31 October, his wish: titanforged cards always different) the foil of its window, its own (Patterns.lua: wv; 1
	-- the one of before; Media\\Holo)
	local wv = (pat and pat.wv) or 1
	-- (the foil of its frame: the one of its window on its metal; the 1, of before, its own: the first)
	-- (the foil of its frame: its own variant, the one of the frame of its pattern, pv; the foil of the window of that
	-- variant on the metal of its frame)
	local cv = (pat and pat.pv) or 1
	-- (31 October, his word: the frames of the other ranks showed through: the metal of its kind of frame only, K the
	-- cards of a style, C the others)
	local kindOf = self.style and "K" or "C"
	if self.winV ~= wv .. kindOf .. cv then
		self.winV = wv .. kindOf .. cv
		for i = 1, 3 do
			local file = wv <= 1 and (MEDIA .. "TitanWindow" .. i) or (MEDIA .. "Holo\\W" .. string.format(("%02d"), wv) .. "_" .. i)
			self.winFoil[i]:SetTexture(file)
			-- (the second, mirrored, lit a third of the rainbow further)
			self.winFoil2[i]:SetTexture(wv <= 1 and (MEDIA .. "TitanWindow" .. (CuratorOctoFull.Mod(i , 3) + 1)) or (MEDIA .. "Holo\\W" .. string.format(("%02d"), wv) .. "_" .. (CuratorOctoFull.Mod(i , 3) + 1)))
			CellsTexture(fin.facets[i], MEDIA .. "Holo\\" .. kindOf .. string.format(("%02d"), cv) .. "_" .. i)
		end
	end
	for _, list in ipairs({ self.winFoil, self.winFoil2 }) do
		for i, fo in ipairs(list) do
			CuratorOctoFull.SetShown(fo, kind == "titan")
			fo:SetAlpha(0)
			CuratorOctoFull.SetDesaturated(fo, tint)
			if tint then
				fo:SetVertexColor(ns.Patterns.Color(pat, (i - 1) / 3))
			else
				fo:SetVertexColor(1, 1, 1)
			end
		end
	end
	for i, a in ipairs(self.titanAura) do
		CuratorOctoFull.SetShown(a, kind == "titan")
		a:SetAlpha(0)
		CuratorOctoFull.SetDesaturated(a, tint)
		if tint then
			a:SetVertexColor(ns.Patterns.Color(pat, (i - 1) / 3))
		else
			a:SetVertexColor(1, 1, 1)
		end
	end
	for i = 1, 3 do
		for _, t in ipairs(fin.facets[i]) do
			CuratorOctoFull.SetShown(t, kind == "titan")
			t:SetAlpha(0)
			CuratorOctoFull.SetDesaturated(t, tint)
			if tint then
				t:SetVertexColor(ns.Patterns.Color(pat, (i - 1) / 3))
			else
				t:SetVertexColor(1, 1, 1)
			end
		end
	end
	for i, g in ipairs(self.glory) do
		-- (31 October, his word: the light of the prism behind a creature, of the cards of the boosters: not over the
		-- picture of a card of a style)
		CuratorOctoFull.SetShown(g, kind == "titan" and not self.style)
		g:SetAlpha(0)
		CuratorOctoFull.SetDesaturated(g, tint)
		if tint then
			g:SetVertexColor(ns.Patterns.Color(pat, (i - 1) * 0.5))
		else
			g:SetVertexColor(1, 1, 1)
		end
	end
	-- (titanforged: the colours of the titans laid over its metal, whatever it is, gold or dark; thunderforged: the
	-- lightning of the cards of the albums over it)
	for _, t in ipairs(fin.foil) do
		t:SetBlendMode("BLEND")
		CuratorOctoFull.SetShown(t, kind == "titan")
	end
	for i = 1, 2 do
		for _, t in ipairs(fin.arcs[i]) do
			CuratorOctoFull.SetShown(t, kind == "thunder")
			t:SetAlpha(0)
		end
	end
	self.crackleAt, self.flourishT = nil, nil
	if kind then
		-- (its colours, its light at once)
		CC.Forged(self, self.t or 0, 0)
	end
end

-- (thunderforged) It crackles now, three times, as when its lightning strikes.
function M:Strike()
	if self.finish == "thunder" then
		self.crackleAt = self.t or 0
	end
end

-- (titanforged) Its colours go once round the rainbow, bright.
function M:Flourish()
	if self.finish == "titan" then
		self.flourishT = 0
	end
end

-- Its creature alive and turning (on), or still.
function M:SetLive(on)
	self.live = on and true or false
end

-- The back of its cards (art: a texture of the art of its case, Media/<art>, the card in its 512 x 717 of 512 x 1024; nil:
-- the back of the boosters of the zones).
function M:SetBack(art)
	if art then
		-- (1.14.0: its words in the language of the game, Core.lua: ns.CaseTexture)
		self.backT:SetTexture(MEDIA .. ns.CaseTexture(art))
		self.backT:SetTexCoord(0, 1, 0, TH / 1024)
	else
		self.backT:SetTexture(MEDIA .. "Back")
		self.backT:SetTexCoord(0, RIM_R, 0, 1)
	end
	self.backArt = art
	if self.held then
		self:HeldSync()
	end
end

-------------------------------------------------------------------------------
-- (1.14.0, after its second test) Appraised, in the case of the expert, as the cards of the boosters are (UI/Card.lua:
-- the same slab of acrylic, its label printed, ns.SlabBuild, ns.SlabLabel): flat around it, and in 3D held in the
-- hand, as thick as it is (its faces, its edges: ns.Card3D.DepthPaint).
-------------------------------------------------------------------------------
-- Its pieces, made the first time it is appraised: the card a level up, the backing of its case at its own level.
function M:BuildSlab()
	if self.slab then
		return self.slab
	end
	self.slabOff = 1
	local low = CreateFrame("Frame", nil, self)
	low:SetAllPoints()
	self.slabLow = low
	local base = self:GetFrameLevel() + 1
	local sl = ns.SlabBuild(self, low, base + 12, base + 13)
	self.base = nil
	Relevel(self)
	return sl
end

-- Its case (info: as Expertise.lua's E:LabelOf: grade, word, name, album, num, marks, cert, color), or none (nil).
function M:SetSlab(info)
	local sl = self.slab
	if not info then
		if sl then
			sl.high:Hide()
			sl.back:Hide()
			sl.wordsF:Hide()
		end
		local was = self.slabInfo ~= nil
		self.slabInfo = nil
		if was and self.held and self.held3 then
			self:SlabHold(false)
			self.heldPose = nil
		end
		return
	end
	sl = self:BuildSlab()
	self.slabInfo = info
	ns.SlabLabel(sl, info)
	sl.high:Show()
	sl.back:Show()
	sl.wordsF:Show()
	self:SlabAlpha(self.slabA or 1)
	self:SlabSide(self.facing ~= "back")
	if self.held3 then
		self:SlabHeld()
		if self.held then
			self:SlabHold(false)
			self:SlabHold(true)
			self:HeldSync()
			for _, e in ipairs(self.held3.layers) do
				e.mesh.pose, e.mesh.on = nil, nil
			end
			for _, q in ipairs(self.held3.quads) do
				q.pose, q.x1, q.on = nil, nil, nil
			end
			self.held3.slabGlare.pose, self.held3.slabGlare.on = nil, nil
			self.heldPose = nil
		end
	end
end

-- How much of its case is seen (0 to 1: the case coming down on it, UI/Expertise.lua), flat or held.
function M:SlabAlpha(a)
	a = math.max(0, math.min(1, a or 1))
	self.slabA = a
	local sl = self.slab
	if not sl then
		return
	end
	for _, t in ipairs({ sl.paper, sl.paperBack, sl.band, sl.front, sl.emblem, sl.holo }) do
		t:SetAlpha(a)
	end
	sl.barcode:SetAlpha(0.85 * a)
	local h = self.held3
	if h and h.slabBackL then
		h.slabBackL.alpha = a
	end
	if h and h.slabOn then
		h.slabTexts:SetAlpha(a)
	else
		sl.back:SetAlpha(a)
		sl.wordsF:SetAlpha(a)
	end
end

-- The side of its case seen: its label printed, or the back of its paper.
function M:SlabSide(front)
	local sl = self.slab
	if not sl then
		return
	end
	CuratorOctoFull.SetShown(sl.paper, front)
	CuratorOctoFull.SetShown(sl.paperBack, not front)
	CuratorOctoFull.SetShown(sl.emblem, front)
	CuratorOctoFull.SetShown(sl.holo, front)
	CuratorOctoFull.SetShown(sl.barcode, front and self.slabInfo ~= nil and self.slabInfo.cert ~= nil and not self.slabInfo.seal and not self.slabInfo.titan)
	CuratorOctoFull.SetShown(sl.labelF, front)
end

-------------------------------------------------------------------------------
-- (1.14.0) In the hand, in 3D (UI/Inspect.lua), as the cards of the albums are (UI/Card.lua, ns.Card3D): turned all the
-- way round to its back, tilted up and down, in perspective. Its pieces drawn flat step aside while it is held, and cells
-- of them are moved where the card puts their corners (read every frame: what moves on them moves on it); its words follow
-- it, turned and scaled with it, gone when it is seen too much from the side; its creature (its character in its armour)
-- is seen through its window, the camera going round it as the eye goes round the card. What sparkles fast on it (its
-- forged finish, its embers, its sparks, its sheen) waits for it to be flat again, and its weapon of legend shows its
-- icon meanwhile. It is held only while it moves or shows its back: at rest, face up, it is flat again, all of it alive.
-------------------------------------------------------------------------------
-- (where a piece drawn flat is now, from the middle of the card: left, bottom, right, top; nil: nowhere yet)
local function RectOf(f, src)
	local l, b, w, h = src:GetLeft(), src:GetBottom(), src:GetWidth(), src:GetHeight()
	local cl, cb = f:GetLeft(), f:GetBottom()
	if not (l and b and w and h and cl and cb) then
		return nil
	end
	local x1, y1 = l - cl - f.W / 2, b - cb - f.H / 2
	return x1, y1, x1 + w, y1 + h
end

local function BuildHeld(f)
	local D = ns.Card3D
	local W, H, k = f.W, f.H, f.k
	local base = f:GetFrameLevel() + (f.slabOff or 0)
	local h = { layers = {}, quads = {}, words = {}, pose = 0, frames = {} }
	f.held3 = h
	-- (under the window of its creature (as low as what it stands for: the client draws by level, the window over it), over
	-- it, its words (over its forge: BuildForge), its back, the light of the room)
	h.levels = { 0, 7, 9, 10, 11 }
	for i, n in ipairs(h.levels) do
		local fr = CreateFrame("Frame", nil, f)
		fr:SetAllPoints(f)
		fr:SetFrameLevel(base + n)
		fr:Hide()
		h.frames[i] = fr
	end
	h.low, h.high, h.texts, h.back, h.light = unpack(h.frames)
	local function X(tx)
		return tx * k - W / 2
	end
	local function Y(ty)
		return H / 2 - ty * k
	end
	local wx1, wy1, wx2, wy2 = X(WIN[1]), Y(WIN[4]), X(WIN[3]), Y(WIN[2])
	h.win = { wx1, wy1, wx2, wy2 }
	local gm = GM * k
	h.grids = {
		card = D.Grid(-W / 2, -H / 2, W / 2, H / 2, 6, 8),
		light = D.Grid(-W / 2, -H / 2, W / 2, H / 2, 4, 5, W * 22 / 512),
		win = D.Grid(wx1, wy1, wx2, wy2, 4, 4),
		glow = D.Grid(-W / 2 - gm, -H / 2 - gm, W / 2 + gm, H / 2 + gm, 3, 4),
		-- (1.14.0, the Paladin collection redone) the picture of a card of a style, what is seen of it over its name
		art = D.Grid(X(ART[1]), Y(ART[4]), X(ART[3]), Y(ART[2]), 5, 7),
		view = D.Grid(X(VIEW[1]), Y(VIEW[4]), X(VIEW[3]), Y(VIEW[2]), 4, 4),
	}
	-- (a piece over a grid: the side of the card it is on; live: its colour or its part of its texture may change;
	-- always: shown on its side whatever its frame)
	local function L(src, grid, frame, layer, sub, side, opts)
		local e = opts or {}
		e.src, e.side, e.mesh = src, side, D.Cells(f, frame, h.grids[grid], layer, sub)
		h.layers[CuratorOctoFull.Length(h.layers) + 1] = e
		return e
	end
	-- (a small piece, one cell, where it is drawn flat: turn, it turns as it does; round, cut round as it is)
	local function Q(src, frame, layer, sub, opts)
		local t = frame:CreateTexture(nil, layer, nil, sub)
		if t.SetSnapToPixelGrid then
			t:SetSnapToPixelGrid(false)
			t:SetTexelSnappingBias(0)
		end
		t:Hide()
		local q = opts or {}
		q.src, q.t = src, t
		if q.round then
			local m = CuratorOctoFull.CreateMaskTexture(frame)
			m:SetTexture(MEDIA .. "CircleMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			m:SetAllPoints(t)
			CuratorOctoFull.AddMaskTexture(t, m)
			q.mask = m
		end
		h.quads[CuratorOctoFull.Length(h.quads) + 1] = q
		return q
	end
	-- behind: its rays, the parts of its rank behind its frame, its ground, the light behind its creature, its runes
	Q(f.rays[1], h.low, "BACKGROUND", -8, { turn = true })
	Q(f.rays[2], h.low, "BACKGROUND", -7, { turn = true })
	Q(f.orbGlow, h.low, "BACKGROUND", -6)
	for i, t in ipairs(f.under) do
		Q(t, h.low, "BACKGROUND", math.min(-1, -7 + i))
	end
	L(f.ground, "win", h.low, "BACKGROUND", 0, "front")
	Q(f.aura, h.low, "BACKGROUND", 1)
	Q(f.rune, h.low, "ARTWORK", 0, { turn = true })
	L(f.pic, "win", h.low, "ARTWORK", 1, "front")
	-- (1.14.0, the Paladin collection redone) the picture of a card of a style; the reflections of a priceless card over it
	-- (still: only how much of each, as the card turns)
	L(f.art, "art", h.low, "BACKGROUND", -6, "front", { live = true, wrap = "CLAMP" })
	for i, t in ipairs(f.layers) do
		L(t, "art", h.low, "BACKGROUND", -6 + i, "front", { wrap = "CLAMP" })
	end
	-- a spell: its shade, its medallion; a weapon or an armour: its icon in its ring of gold; the golden card of the secret
	local sp = f.spell
	Q(sp.shade, h.low, "ARTWORK", 2)
	Q(sp.halo, h.low, "ARTWORK", 3)
	Q(sp.icon, h.low, "ARTWORK", 4, { round = true })
	Q(sp.ring, h.low, "ARTWORK", 5)
	Q(f.armIcon, h.low, "ARTWORK", 4, { round = true })
	Q(f.armRing, h.low, "ARTWORK", 5)
	Q(f.secret.shine, h.low, "OVERLAY", 0)
	Q(f.secret.medal, h.low, "OVERLAY", 1)
	-- over it: the shadow of the edges of its window, its frame, the shine of its gold, its glow, its wear, its parts
	L(f.vig, "win", h.high, "BACKGROUND", 0, "front")
	L(f.frame, "card", h.high, "BORDER", 0, "front")
	for _, gl in ipairs(f.gloss) do
		L(gl, "card", h.high, "BORDER", 7, "front", { live = true })
	end
	L(f.glow, "glow", h.high, "ARTWORK", -2, "front", { live = true })
	for _, a in ipairs(f.titanAura) do
		L(a, "glow", h.high, "ARTWORK", -3, "front", { live = true })
	end
	for i, t in ipairs(f.parts) do
		Q(t, h.high, "ARTWORK", i - 1)
	end
	-- its back, seen from behind (its left on the right)
	L(f.backT, "card", h.back, "ARTWORK", 0, "back", { flip = true, always = true, alpha = 1 })
	-- the light of the room on each side
	h.glare = D.Cells(f, h.light, h.grids.light, "OVERLAY", 2)
	h.backGlare = D.Cells(f, h.light, h.grids.light, "OVERLAY", 3)
	for _, m in ipairs({ h.glare, h.backGlare }) do
		for _, t in ipairs(m) do
			t:SetTexture(MEDIA .. "Sheen")
			t:SetBlendMode("ADD")
		end
	end
	-- (1.14.0) titanforged: its foil in its window, the light of the prism behind its creature (a card of a style: over
	-- what is seen of its picture)
	for i, fo in ipairs(f.winFoil) do
		L(fo, "win", h.low, "BACKGROUND", 2 + i, "front", { live = true, plain = true })
		L(fo, "view", h.low, "BACKGROUND", 2 + i, "front", { live = true, styled = true })
	end
	for _, fo in ipairs(f.winFoil2) do
		L(fo, "win", h.low, "BACKGROUND", 6, "front", { live = true, plain = true })
		L(fo, "view", h.low, "BACKGROUND", 6, "front", { live = true, styled = true })
	end
	for i, g in ipairs(f.glory) do
		Q(g, h.low, "BORDER", i, { turn = true })
	end
	-- its embers (behind its creature, before it), the sparks of its gems and of its gold
	for _, e in ipairs(f.embers) do
		if e.tex:GetParent() == f.winTex then
			Q(e.tex, h.low, "OVERLAY", 0, { live = true })
		else
			Q(e.tex, h.high, "OVERLAY", 3, { live = true })
		end
	end
	for _, sk in ipairs(f.sparks) do
		Q(sk.tex, h.high, "OVERLAY", 4, { turn = true, live = true })
	end
	-- the sweep of its sheen
	h.sweep = D.Cells(f, h.high, h.grids.light, "OVERLAY", 5)
	for _, t in ipairs(h.sweep) do
		t:SetTexture(MEDIA .. "Sheen")
		t:SetBlendMode("ADD")
	end
	-- its words, letter by letter (M:LayGlyphs; wrap: the width of the lines of what a spell does)
	h.wordList = { { fs = f.name }, { fs = f.rank }, { fs = sp.tree }, { fs = sp.desc, wrap = DESC_W }, { fs = f.secret.q } }
	h.glyphs, h.nGlyphs = {}, 0
	h.measure = h.texts:CreateFontString(nil, "OVERLAY")
	h.measure:Hide()
	h.L, h.Q = L, Q
	-- (31 October) its wear in cells over its words (UI/Wear.lua: Mesh, HeldPaint)
	if ns.WearUI then
		ns.WearUI.Held(f, h)
	end
	return h
end

-- (1.14.0, after its second test) Its case in 3D: its backing under the card (at the level of the card), its labels,
-- its face and its edges over it (as far from it as the case is thick: SetPose), the words of its label on a frame of
-- their own; made once, the first time it is held in its case.
function M:SlabHeld()
	local h, sl = self.held3, self.slab
	if not (h and sl) or h.slabBuilt then
		return
	end
	h.slabBuilt = true
	local D = ns.Card3D
	local box, lab = sl.box, sl.lab
	h.grids.slab = D.Grid(box[1], box[2], box[3], box[4], 6, 10)
	h.grids.label = D.Grid(lab[1], lab[2], lab[3], lab[4], 6, 2)
	h.grids.slabF = D.Grid(box[1], box[2], box[3], box[4], 6, 10)
	h.grids.slabF.z = D.DepthOf(self, "slab")
	local lv = self:GetFrameLevel()
	local base = lv + (self.slabOff or 0)
	local function Level(n)
		local fr = CreateFrame("Frame", nil, self)
		fr:SetAllPoints(self)
		fr:SetFrameLevel(n)
		fr:Hide()
		return fr
	end
	h.slabLowF, h.slabHigh, h.slabTexts = Level(lv), Level(base + 12), Level(base + 13)
	h.slabBackL = h.L(sl.back, "slab", h.slabLowF, "BACKGROUND", -8, "both", { alpha = self.slabA or 1 })
	h.L(sl.paper, "label", h.slabHigh, "ARTWORK", -4, "both")
	h.L(sl.paperBack, "label", h.slabHigh, "ARTWORK", -4, "both")
	h.L(sl.band, "label", h.slabHigh, "ARTWORK", -3, "both")
	h.slabPlate = h.L(sl.front, "slabF", h.slabHigh, "ARTWORK", 0, "both")
	h.slabDepth = D.DepthBuild(h.slabHigh, "ARTWORK", -7)
	local function R(rect)
		return function()
			return rect[1], rect[2], rect[3], rect[4]
		end
	end
	h.Q(sl.emblem, h.slabHigh, "ARTWORK", -2, { rect = R(sl.emblemRect) })
	h.Q(sl.barcode, h.slabHigh, "ARTWORK", -2, { rect = R(sl.barcodeRect) })
	h.Q(sl.holo, h.slabHigh, "OVERLAY", 0, { rect = R(sl.holoRect) })
	-- the light of the room on the acrylic: over the whole case
	h.slabGlare = D.Cells(self, h.slabHigh, h.grids.slabF, "OVERLAY", 2)
	for _, t in ipairs(h.slabGlare) do
		t:SetTexture(MEDIA .. "Sheen")
		t:SetBlendMode("ADD")
	end
	h.slabWords = {}
end

-- The words of its label on the frame of its case in 3D (on), or back on its label (off).
function M:SlabHold(on)
	local h, sl = self.held3, self.slab
	if not (h and sl and h.slabBuilt) then
		return
	end
	if on then
		if h.slabOn then
			return
		end
		h.slabOn = true
		sl.high:SetAlpha(0)
		sl.wordsF:SetAlpha(0)
		sl.back:SetAlpha(0)
		local rects = { [sl.labelF] = sl.lab }
		CuratorOctoFull.Wipe(h.slabWords)
		for _, fs in ipairs(sl.words) do
			local w = { fs = fs, parent = fs:GetParent(), points = {}, a = fs:GetAlpha(), shown = fs:IsShown() }
			for i = 1, fs:GetNumPoints() do
				w.points[i] = { fs:GetPoint(i) }
			end
			-- (placed by the middle of its words: turned and scaled, they stay where they were printed)
			w.x, w.y = ns.Card3D.RestCenter(self, fs, rects)
			fs:SetParent(h.slabTexts)
			fs:SetWidth(0)
			fs:SetJustifyH("CENTER")
			-- (31 October, his word: in letters, bent with the case, narrowed to the room of their narrow font)
			w.fit, w.frame = true, h.slabTexts
			h.sgfree = h.sgfree or {}
			w.pool = h.sgfree
			h.slabWords[CuratorOctoFull.Length(h.slabWords) + 1] = w
		end
		h.slabTexts:SetAlpha(self.slabA or 1)
		h.slabLowF:Show()
		h.slabHigh:Show()
		h.slabTexts:Show()
	else
		if not h.slabOn then
			return
		end
		h.slabOn = nil
		sl.high:SetAlpha(1)
		sl.wordsF:SetAlpha(self.slabA or 1)
		sl.back:SetAlpha(self.slabA or 1)
		for _, w in ipairs(h.slabWords) do
			ns.Card3D.GlyphRelease(h, w)
			local fs = w.fs
			fs:SetParent(w.parent)
			fs:ClearAllPoints()
			for _, p in ipairs(w.points) do
				fs:SetPoint(unpack(p))
			end
			fs:SetWidth(fs.slabW or 0)
			fs:SetJustifyH(fs.slabJ or "LEFT")
			fs:SetAlpha(w.a)
			CuratorOctoFull.SetShown(fs, w.shown)
			if fs.SetTextScale then
				fs:SetTextScale(1)
			end
			if fs.SetRotation then
				CuratorOctoFull.SetRotation(fs, 0)
			end
		end
		CuratorOctoFull.Wipe(h.slabWords)
		h.slabLowF:Hide()
		h.slabHigh:Hide()
		h.slabTexts:Hide()
		ns.Card3D.DepthHide(h.slabDepth)
	end
end

-- Its case where the card is (SetPose, its grids projected): the words of its label placed, turned and scaled with it
-- (gone seen too much from the side, or from behind), its edges, the light of the room on its acrylic.
local function SlabPose(f, front)
	local h, sl = f.held3, f.slab
	local D = ns.Card3D
	if not (h and h.slabOn and f.slabInfo) then
		if h and h.slabDepth then
			D.DepthHide(h.slabDepth)
		end
		return
	end
	local Project = D.Project
	for _, wd in ipairs(h.slabWords) do
		local fs = wd.fs
		local px, py = Project(f, wd.x, wd.y)
		local ax, ay = Project(f, wd.x + 4, wd.y)
		local qx, qy = Project(f, wd.x, wd.y + 4)
		local k = math.min(math.sqrt((ax - px) ^ 2 + (ay - py) ^ 2), math.sqrt((qx - px) ^ 2 + (qy - py) ^ 2)) / 4
		-- (31 October, his word: in letters, bent with the case; a word the atlas cannot write: turned and scaled)
		if wd.glyph ~= false and (wd.text ~= fs:GetText() or wd.size ~= CuratorOctoFull.Select(2, fs:GetFont())) then
			D.GlyphSet(f, h, wd)
		end
		fs:ClearAllPoints()
		fs:SetPoint("CENTER", f, "CENTER", px, py)
		if wd.gtex then
			fs:SetAlpha(0)
			local on = wd.shown and fs:GetText() ~= nil
			if wd.gon ~= on then
				wd.gon = on
				for _, e in ipairs(wd.gtex) do
					CuratorOctoFull.SetShown(e.t, on)
				end
			end
			D.GlyphPlace(f, wd, k)
		else
			if fs.SetTextScale then
				fs:SetTextScale(math.max(0.05, k))
			end
			if fs.SetRotation then
				CuratorOctoFull.SetRotation(fs, math.atan2(ay - py, ax - px))
			end
			fs:SetAlpha(wd.a * math.max(0, math.min(1, (k - 0.3) / 0.25)))
		end
	end
	CuratorOctoFull.SetShown(h.slabTexts, front)
	local style = f.slabInfo.seal and "seal" or "slab"
	h.slabDepthA = f.slabA or 1
	D.DepthPaint(f, h.slabDepth, sl.box, D.DepthOf(f, style), style, h.slabDepthA)
	local R = f.R
	local nx, ny = R[3], R[6]
	local d = (ny - nx) * f.H * 0.5
	D.Band(h.slabGlare, d * 0.7071, -d * 0.7071 + f.H * 0.15, f.H * 2.6)
end

-- The pieces in 3D take the look of the pieces drawn flat (their textures, their parts of them, their colours).
function M:HeldSync()
	local h = self.held3
	if not h then
		return
	end
	local D = ns.Card3D
	for _, e in ipairs(h.layers) do
		D.Dress(e.mesh, e.src, e.flip, e.wrap)
		e.mesh.a = nil
		e.u0, e.r = nil, nil
	end
	for _, q in ipairs(h.quads) do
		local t, src = q.t, q.src
		t:SetTexture(src:GetTexture())
		t:SetTexCoord(src:GetTexCoord())
		t:SetVertexColor(src:GetVertexColor())
		t:SetBlendMode(src:GetBlendMode() or "BLEND")
		CuratorOctoFull.SetDesaturated(t, src:IsDesaturated() and true or false)
	end
	-- (31 October) its wear: its pieces cut into cells again
	if ns.WearUI then
		ns.WearUI.Mesh(self)
	end
end

-- Held in the hand (in 3D), or put down (flat again, as it was).
function M:Hold(on)
	on = on and true or false
	if on == (self.held or false) or (on and not (ns.Card3D and ns.Can3D and ns.Can3D())) then
		return
	end
	local h = self.held3 or BuildHeld(self)
	local flat = { self.low, self.winTex, self.spell, self.front, self.secret, self.over, self.sheenBox, self.wearF }
	local win = self.win
	if on then
		self.held = true
		for _, x in ipairs(flat) do
			x:SetAlpha(0)
		end
		for _, x in ipairs(h.frames) do
			x:Show()
		end
		-- (its weapon of legend: in its window, turning with it; its icon while its model does not stand)
		if self.weapon and not self.flatWeapon then
			ArmIcon(self, not (self.arm and self.arm.ready))
		end
		CuratorOctoFull.SetClipsChildren(win, false)
		-- (1.14.0, after its second test) its case, when it is in one: held with it
		if self.slab and self.slabInfo then
			self:SlabHeld()
			self:SlabHold(true)
		end
		-- its words, letter by letter, on a frame of their own (its words drawn flat step aside with their frames)
		self:LayGlyphs()
		self:HeldSync()
		for _, e in ipairs(h.layers) do
			e.mesh.pose, e.mesh.on, e.mesh.a = nil, nil, nil
		end
		for _, m in ipairs({ h.glare, h.backGlare, h.sweep, h.slabGlare or false }) do
			if m then
				m.pose, m.on, m.a = nil, nil, nil
			end
		end
		h.sweepX, h.sweepY, h.sweepR = nil, nil, nil
		for _, q in ipairs(h.quads) do
			q.pose, q.x1, q.on = nil, nil, nil
		end
		self.heldPose, self.facing = nil, nil
	else
		self.held = false
		for _, x in ipairs(flat) do
			x:SetAlpha(1)
		end
		for _, x in ipairs(h.frames) do
			x:Hide()
		end
		for _, gl in ipairs(h.glyphs) do
			gl.on, gl.shown = false, false
			CC.GlyphHide(gl)
		end
		h.nGlyphs = 0
		if self.slab then
			self:SlabHold(false)
		end
		-- its forge flat again, shown
		for _, m in ipairs({ self.fin.foil, self.fin.rim, self.fin.arcs[1], self.fin.arcs[2], self.fin.facets[1],
			self.fin.facets[2], self.fin.facets[3] }) do
			for _, t in ipairs(m) do
				Unwarp(t)
			end
		end
		CuratorOctoFull.SetShown(self.forge, self.finish ~= nil)
		-- its window, its creature and its camera, its armour as they were
		CuratorOctoFull.SetClipsChildren(win, false)
		Place(win, self, unpack(WIN))
		win:Show()
		for _, m in ipairs({ self.scene or false, self.dress or false, self.arm or false }) do
			if m then
				m:ClearAllPoints()
				m:SetAllPoints(win)
			end
		end
		if self.arm then
			CC.ArmFit(self.arm)
		end
		local sc = self.scene
		if sc and sc.owner then
			sc.owner.held = false
			ns.Creatures.Frame(sc)
		end
		if self.weapon and not self.flatWeapon then
			ArmIcon(self, not (self.arm and self.arm.ready))
			if self.arm then
				CC.ArmShow(self.arm, true)
			end
		end
		self.heldYaw, self.heldPitch, self.heldPose, self.facing = nil, nil, nil, nil
	end
end

-- Its creature still while it moves (UI/Inspect.lua), or alive again.
function M:Freeze(on)
	self.frozen = on and true or false
end

-- A client that cannot draw it in 3D: flat, its back once it is turned past a quarter.
function M:SetTurn(yaw)
	local back = math.cos(yaw or 0) < 0
	if back == (self.flatBack or false) then
		return
	end
	self.flatBack = back
	for _, x in ipairs({ self.low, self.win, self.front, self.secret, self.over, self.sheenBox }) do
		CuratorOctoFull.SetShown(x, not back)
	end
	if self.wearF then
		CuratorOctoFull.SetShown(self.wearF, not back and self.wearOn == true)
	end
	CuratorOctoFull.SetShown(self.secret, not back and self.pick ~= nil and self.pick.secret == true)
	CuratorOctoFull.SetShown(self.forge, not back and self.finish ~= nil)
	CuratorOctoFull.SetShown(self.backF, back)
end

-- Held in the hand, turned (yaw: round its upright axis, all the way; its back past a quarter turn) and tilted (pitch:
-- its top toward the eye), in perspective; at rest face up, flat again.
function M:SetPose(yaw, pitch)
	pitch = pitch or 0
	local D = ns.Card3D
	if not (D and ns.Can3D and ns.Can3D()) then
		return self:SetTurn(yaw, pitch)
	end
	local cy, sy, cp, spt = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
	if cy > 0.99999 and math.abs(pitch) < 1e-4 then
		self:Hold(false)
		return
	end
	self:Hold(true)
	local h = self.held3
	local p = self.heldPose
	if p and math.abs(p[1] - yaw) < 1e-5 and math.abs(p[2] - pitch) < 1e-5 then
		return
	end
	local side = (cy * cp >= 0) and "front" or "back"
	if side ~= self.facing then
		self.facing = side
		CuratorOctoFull.SetShown(self.win, side == "front")
		CuratorOctoFull.SetShown(h.texts, side == "front")
		CuratorOctoFull.SetShown(self.forge, side == "front" and self.finish ~= nil)
		self:SlabSide(side == "front")
	end
	self.heldPose = { yaw, pitch }
	-- the turn, then the tilt: R = Rx(pitch) Ry(yaw); the eye at its distance
	local R = self.R or {}
	self.R = R
	R[1], R[2], R[3] = cy, 0, sy
	R[4], R[5], R[6] = spt * sy, cp, -spt * cy
	R[7], R[8], R[9] = -cp * sy, spt, cp * cy
	self.eye = D.EYE * self.H
	self.heldYaw, self.heldPitch = yaw, pitch
	h.pose = h.pose + 1
	-- (1.14.0, after its second test) its case: its face turned to the eye, as far from it as the case is thick (seen from
	-- behind, the face of its back: the same acrylic the other way round)
	if h.grids.slabF then
		local depth = D.DepthOf(self, (self.slabInfo and self.slabInfo.seal) and "seal" or "slab")
		h.grids.slabF.z = (side == "front") and depth or -depth
		local plate = h.slabPlate
		if (plate.flip or false) ~= (side == "back") then
			plate.flip = side == "back"
			D.Dress(plate.mesh, plate.src, plate.flip, plate.wrap)
			plate.mesh.a, plate.mesh.pose = nil, nil
		end
	end
	for _, g in pairs(h.grids) do
		D.ProjectGrid(self, g)
	end
	-- its forge: its cells where the card puts them (its small pieces as they are drawn)
	local fin = self.fin
	D.ProjectGrid(self, fin.grid)
	D.Warp(fin.foil)
	D.ProjectGrid(self, fin.rimGrid)
	D.Warp(fin.rim)
	D.Warp(fin.arcs[1])
	D.Warp(fin.arcs[2])
	for i = 1, 3 do
		D.Warp(fin.facets[i])
	end
	-- its window: what the card shows of it (the largest rectangle in it) clips its creature, as large as the card is near
	-- there, its camera round it
	local wx1, wy1, wx2, wy2 = h.win[1], h.win[2], h.win[3], h.win[4]
	local ulx, uly = D.Project(self, wx1, wy2)
	local urx, ury = D.Project(self, wx2, wy2)
	local llx, lly = D.Project(self, wx1, wy1)
	local lrx, lry = D.Project(self, wx2, wy1)
	local x1, y1, x2, y2
	if side == "front" then
		x1, y1, x2, y2 = D.Inside(ulx, uly, urx, ury, llx, lly, lrx, lry)
	end
	local win = self.win
	win:ClearAllPoints()
	if x1 then
		win:SetPoint("BOTTOMLEFT", self, "CENTER", x1, y1)
		win:SetPoint("TOPRIGHT", self, "CENTER", x2, y2)
	else
		win:SetPoint("CENTER", self, "CENTER", 0, 0)
		CuratorOctoFull.SetSize(win, 0.01, 0.01)
	end
	for _, m in ipairs({ self.scene or false, self.dress or false, self.arm or false }) do
		if m then
			m:ClearAllPoints()
			m:SetAllPoints(win)
		end
	end
	if self.arm then
		CC.ArmFit(self.arm)
		-- (turned with the card at once, not a frame after it)
		if self.arm.ready and self.arm.pose and self.live ~= false then
			CC.ArmFace(self.arm, ArmYaw(self))
		end
	end
	local sc = self.scene
	if sc and sc.owner then
		sc.owner.held, sc.owner.heldYaw, sc.owner.heldPitch = true, yaw, pitch
		ns.OrbitScene(sc)
	end
	-- its words follow it, letter by letter
	self:PlaceGlyphs()
	-- its case, its words, its edges
	SlabPose(self, side == "front")
	-- the light of the room on it: it moves over it as it turns, brighter the more it leans
	local nx, ny = R[3], R[6]
	local lean = math.min(1, 2.2 * math.sqrt(nx * nx + ny * ny))
	local d = (ny - nx) * self.H * 0.5
	h.glareA = D.GLARE * lean
	D.Band((side == "front") and h.glare or h.backGlare, d * 0.7071, -d * 0.7071, self.H * 2)
	self:HeldPaint()
end

-------------------------------------------------------------------------------
-- (1.14.0) Its words held in the hand: letter by letter, each where the card puts it (turned with it, as large as the
-- card is near there), so that they stay printed on it as it turns: a font string cannot be squeezed one way only, so
-- each letter keeps its shape and their places follow the card; gone when it is seen too much from the side. Laid out
-- as the client lays out its words flat (by the widths of the font, wrapped as it wraps them).
-------------------------------------------------------------------------------
local UTF8 = "[%z\1-\127\194-\244][\128-\191]*"

local function Chars(s)
	local t = {}
	for ch in CuratorOctoFull.Gmatch(s, UTF8) do
		t[CuratorOctoFull.Length(t) + 1] = ch
	end
	return t
end

local function Plain(s)
	return (string.gsub(string.gsub(string.gsub((s or ""), "|c%x%x%x%x%x%x%x%x", ""), "|r", ""), "|T.-|t", ""))
end

-- (the width of a text in the font of the measure)
local function Width(m, s)
	m:SetText(s)
	local w = (m.GetUnboundedStringWidth and m:GetUnboundedStringWidth()) or m:GetStringWidth()
	return w or 0
end

-- (its lines, as the client wraps them in w points: by words, a word too long by its letters; nil: as they are)
local function WrapLines(m, text, w)
	local lines = {}
	for para in CuratorOctoFull.Gmatch((text .. "\n"), "(.-)\n") do
		if not w then
			lines[CuratorOctoFull.Length(lines) + 1] = para
		else
			local line = ""
			for word in CuratorOctoFull.Gmatch(para, "%S+") do
				local try = (line == "") and word or (line .. " " .. word)
				if Width(m, try) <= w + 0.5 then
					line = try
				else
					if line ~= "" then
						lines[CuratorOctoFull.Length(lines) + 1] = line
						line = ""
					end
					if Width(m, word) <= w + 0.5 then
						line = word
					else
						for _, ch in ipairs(Chars(word)) do
							if line ~= "" and Width(m, line .. ch) > w + 0.5 then
								lines[CuratorOctoFull.Length(lines) + 1] = line
								line = ch
							else
								line = line .. ch
							end
						end
					end
				end
			end
			lines[CuratorOctoFull.Length(lines) + 1] = line
		end
	end
	return lines
end
CC.WrapLines = WrapLines

-- (31 October, his word: no more floating words) A letter of the atlas of Friz Quadrata, the font of the game
-- (Media\Glyphs\Friz, Data/Glyphs.lua), as the cards of the boosters draw theirs (UI/Card.lua): a small piece of the
-- atlas bent with the card; a letter it has not (Cyrillic, Korean, Chinese): a letter of the client, turned and scaled.
local GLYPHS = MEDIA .. "Glyphs\\Friz"
local GLYPH_OUTLINE = 0.065
local OUTLINE_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.7071, 0.7071 }, { -0.7071, 0.7071 }, { 0.7071, -0.7071 }, { -0.7071, -0.7071 } }

-- (a letter put away: its pieces back to the pool, its letter of the client hidden)
function CC.GlyphHide(gl, pool)
	if gl.layers then
		for _, e in ipairs(gl.layers) do
			e.t:Hide()
			if pool then
				pool[CuratorOctoFull.Length(pool) + 1] = e.t
			end
		end
		if pool then
			gl.layers = nil
		end
	end
	if gl.fs then
		gl.fs:Hide()
	end
end

-- Its words laid out letter by letter: where each letter is on the card at rest (from its middle), in the font, the
-- colour and the shadow of its word: a piece of the atlas around where the client puts it.
function M:LayGlyphs()
	local h = self.held3
	local D = ns.Card3D
	local G = ns.Glyphs
	local m = h.measure
	h.gpool = h.gpool or {}
	local rects = { [self] = { -self.W / 2, -self.H / 2, self.W / 2, self.H / 2 } }
	local mx1, my1, mx2, my2 = RectOf(self, self.secret.medal)
	if mx1 then
		rects[self.secret.medal] = { mx1, my1, mx2, my2 }
	end
	local n = 0
	for _, w in ipairs(h.wordList) do
		local _, w = _, w; local fs = w.fs
		w.text, w.seen = fs:GetText(), (fs:IsVisible() and fs:IsShown()) and true or false
		local text = Plain(w.text)
		local font, size, flags = fs:GetFont()
		if w.seen and font and string.find(text, "%S") then
			m:SetFont(font, size, flags or "")
			local wrap = w.wrap and w.wrap * self.k or nil
			local lines = WrapLines(m, text, wrap)
			m:SetText("Ag")
			local lh = (CuratorOctoFull.GetStringHeight(m) or size) + ((fs.GetSpacing and fs:GetSpacing()) or 0)
			local cx, cy = D.RestCenter(self, fs, rects, wrap ~= nil)
			local just = (fs.GetJustifyH and fs:GetJustifyH()) or "CENTER"
			local r, g, b = 1, 1, 1
			if fs.GetTextColor then
				r, g, b = fs:GetTextColor()
			end
			local sr, sg, sb, sa = 0, 0, 0, 1
			if fs.GetShadowColor then
				sr, sg, sb, sa = fs:GetShadowColor()
			end
			local ox, oy = 1, -1
			if fs.GetShadowOffset then
				ox, oy = fs:GetShadowOffset()
			end
			local outline = flags and string.find(flags, "OUTLINE") ~= nil
			local alpha = fs:GetAlpha()
			local top = cy + CuratorOctoFull.Length(lines) * lh / 2
			for li, line in ipairs(lines) do
				local lw = Width(m, line)
				local bw = math.max(wrap or 0, lw)
				local x0 = (just == "LEFT" and cx - bw / 2) or (just == "RIGHT" and cx + bw / 2 - lw) or (cx - lw / 2)
				local y = top - (li - 0.5) * lh
				local acc, prev = "", 0
				for _, ch in ipairs(Chars(line)) do
					acc = acc .. ch
					local now = Width(m, acc)
					if string.find(ch, "%S") then
						n = n + 1
						local gl = h.glyphs[n]
						if not gl then
							gl = {}
							h.glyphs[n] = gl
						end
						CC.GlyphHide(gl, h.gpool)
						gl.shown = false
						local x = x0 + (prev + now) / 2
						local cp = D.Codes and D.Codes(ch)[1]
						local gg = G and cp and G[cp]
						if gg and gg[7] > 0 then
							-- (a piece of the atlas: as wide as the client set it, centred where it set it, on its line)
							local em = size
							local left = x - gg[9] * em / 2
							local base = y - (G.asc - G.desc) / 2 * em
							local x1, y2 = left + gg[5] * em, base + gg[6] * em
							gl.q = { x1, y2 - gg[8] * em, x1 + gg[7] * em, y2 }
							gl.layers = {}
							local function Add(dx, dy, cr, cg, cb, ca, sub)
								local t = CuratorOctoFull.Remove(h.gpool)
								if not t then
									t = h.texts:CreateTexture(nil, "OVERLAY")
									t:SetTexture(GLYPHS, "CLAMP", "CLAMP")
								end
								t:SetDrawLayer("OVERLAY", sub)
								t:SetTexCoord(gg[1], gg[2], gg[3], gg[4])
								t:SetVertexColor(cr or 0, cg or 0, cb or 0)
								local q = gl.q
								t:ClearAllPoints()
								t:SetPoint("TOPLEFT", self, "CENTER", q[1] + dx, q[4] + dy)
								CuratorOctoFull.SetSize(t, math.max(0.01, q[3] - q[1]), math.max(0.01, q[4] - q[2]))
								t:Hide()
								gl.layers[CuratorOctoFull.Length(gl.layers) + 1] = { t = t, dx = dx, dy = dy, a = ca or 1 }
							end
							if outline then
								local d = GLYPH_OUTLINE * em
								for _, o in ipairs(OUTLINE_DIRS) do
									Add(o[1] * d, o[2] * d, 0, 0, 0, 1, -2)
								end
							end
							if (ox or 0) ~= 0 or (oy or 0) ~= 0 then
								Add(ox or 0, oy or 0, sr, sg, sb, sa, -1)
							end
							Add(0, 0, r or 1, g or 1, b or 1, 1, 0)
						else
							if not gl.fs then
								gl.fs = h.texts:CreateFontString(nil, "OVERLAY")
							end
							local gfs = gl.fs
							gfs:SetFont(font, size, flags or "")
							gfs:SetText(ch)
							gfs:SetTextColor(r or 1, g or 1, b or 1, 1)
							gfs:SetShadowColor(sr or 0, sg or 0, sb or 0, sa or 1)
							gfs:SetShadowOffset(ox or 0, oy or 0)
							gl.q = nil
						end
						gl.x, gl.y, gl.a, gl.on = x, y, alpha, true
					end
					prev = now
				end
			end
		end
	end
	for i = n + 1, CuratorOctoFull.Length(h.glyphs) do
		local gl = h.glyphs[i]
		gl.on, gl.shown = false, false
		CC.GlyphHide(gl, h.gpool)
	end
	h.nGlyphs = n
	-- (placed with the next pose)
	self.heldPose = nil
end

-- Its letters where the card puts them: a piece of the atlas bent with it (its corners where the card puts them); a
-- letter of the client turned with it, as large as it is near there; fading as it is seen from the side.
function M:PlaceGlyphs()
	local h = self.held3
	local D = ns.Card3D
	local Project, WarpQuad = D.Project, D.WarpQuad
	for i = 1, h.nGlyphs or 0 do
		local gl = h.glyphs[i]
		local px, py = Project(self, gl.x, gl.y)
		local ax, ay = Project(self, gl.x + 4, gl.y)
		local qx, qy = Project(self, gl.x, gl.y + 4)
		local ex = math.sqrt((ax - px) ^ 2 + (ay - py) ^ 2) / 4
		local ey = math.sqrt((qx - px) ^ 2 + (qy - py) ^ 2) / 4
		local seen = math.max(0, math.min(1, (ex / math.max(ey, 1e-6) - 0.22) / 0.25))
		if gl.q and gl.layers then
			local q = gl.q
			for _, e in ipairs(gl.layers) do
				local t = e.t
				WarpQuad(self, t, q[1] + e.dx, q[2] + e.dy, q[3] + e.dx, q[4] + e.dy)
				t:SetAlpha(gl.a * seen * e.a)
				if not gl.shown then
					t:Show()
				end
			end
			gl.shown = true
		elseif gl.fs then
			local fs = gl.fs
			fs:ClearAllPoints()
			fs:SetPoint("CENTER", self, "CENTER", px, py)
			if fs.SetTextScale then
				fs:SetTextScale(math.max(0.05, math.sqrt(ex * ey)))
			end
			if fs.SetRotation then
				CuratorOctoFull.SetRotation(fs, math.atan2(ay - py, ax - px))
			end
			fs:SetAlpha(gl.a * seen)
			if not gl.shown then
				gl.shown = true
				fs:Show()
			end
		end
	end
end

-- Every frame while it is held: the pieces in 3D shown as the pieces drawn flat are, with their light; the small pieces
-- where they are now, turned as they are.
function M:HeldPaint()
	local h = self.held3
	if not (self.held and h and self.R) then
		return
	end
	local D = ns.Card3D
	local pose = h.pose
	local front = self.facing ~= "back"
	-- (31 October) its wear, in cells where the card puts them (hidden with its words when its back is seen)
	if ns.WearUI then
		ns.WearUI.HeldPaint(self, pose)
	end
	-- (its words changed meanwhile, shown or hidden: their letters laid out again, placed with the next pose)
	for _, w in ipairs(h.wordList) do
		if w.text ~= w.fs:GetText() or w.seen ~= (w.fs:IsVisible() and w.fs:IsShown()) then
			self:LayGlyphs()
			break
		end
	end
	local styled = self.style ~= nil
	for _, e in ipairs(h.layers) do
		local src = e.src
		local a = e.alpha or src:GetAlpha()
		local on = (e.side == "both" or ((e.side == "back") ~= front)) and (e.always or (src:IsVisible() and a > 0.002))
			and not ((e.plain and styled) or (e.styled and not styled))
		if on and e.live then
			D.Recoord(e)
		end
		D.Paint(e.mesh, on and true or false, a, pose)
	end
	for _, q in ipairs(h.quads) do
		local src, t = q.src, q.t
		local on = front and src:IsVisible() and src:GetAlpha() > 0.002
		if on then
			local x1, y1, x2, y2
			if q.rect then
				x1, y1, x2, y2 = q.rect()
			else
				x1, y1, x2, y2 = RectOf(self, src)
			end
			if x1 and x2 - x1 > 0.01 and y2 - y1 > 0.01 then
				if x1 ~= q.x1 or y1 ~= q.y1 or x2 ~= q.x2 or y2 ~= q.y2 then
					q.x1, q.y1, q.x2, q.y2 = x1, y1, x2, y2
					t:ClearAllPoints()
					t:SetPoint("TOPLEFT", self, "CENTER", x1, y2)
					CuratorOctoFull.SetSize(t, x2 - x1, y2 - y1)
					q.pose = nil
				end
				if q.pose ~= pose then
					D.WarpQuad(self, t, x1, y1, x2, y2)
					q.pose = pose
					if q.mask then
						-- (cut round as the card shows it: within the box of its corners)
						local bx1, by1, bx2, by2 = CuratorOctoFull.Huge, CuratorOctoFull.Huge, -CuratorOctoFull.Huge, -CuratorOctoFull.Huge
						for _, c in ipairs({ { x1, y1 }, { x1, y2 }, { x2, y1 }, { x2, y2 } }) do
							local px, py = D.Project(self, c[1], c[2])
							bx1, bx2 = math.min(bx1, px), math.max(bx2, px)
							by1, by2 = math.min(by1, py), math.max(by2, py)
						end
						q.mask:ClearAllPoints()
						q.mask:SetPoint("BOTTOMLEFT", self, "CENTER", bx1, by1)
						q.mask:SetPoint("TOPRIGHT", self, "CENTER", bx2, by2)
					end
				end
				t:SetAlpha(src:GetAlpha())
				if q.turn and src.GetRotation then
					CuratorOctoFull.SetRotation(t, CuratorOctoFull.GetRotation(src))
				end
				if q.live then
					t:SetVertexColor(src:GetVertexColor())
				end
			else
				on = false
			end
		end
		if on ~= q.on then
			q.on = on
			CuratorOctoFull.SetShown(t, on and true or false)
		end
	end
	-- the sweep of its sheen, as over it flat
	local sh = self.sheen
	local son = front and sh:IsVisible() and sh:GetAlpha() > 0.002
	if son then
		local _, _, _, x, y = sh:GetPoint(1)
		if x ~= h.sweepX or y ~= h.sweepY then
			h.sweepX, h.sweepY = x, y
			D.Band(h.sweep, x or 0, y or 0, sh:GetWidth())
		end
		local r, g, b = sh:GetVertexColor()
		if r ~= h.sweepR or g ~= h.sweepG or b ~= h.sweepB then
			h.sweepR, h.sweepG, h.sweepB = r, g, b
			for _, t in ipairs(h.sweep) do
				t:SetVertexColor(r, g, b)
			end
		end
	end
	D.Paint(h.sweep, son and true or false, sh:GetAlpha(), pose)
	D.Paint(h.glare, front and (h.glareA or 0) > 0.002, h.glareA or 0, pose)
	D.Paint(h.backGlare, not front and (h.glareA or 0) > 0.002, h.glareA or 0, pose)
	-- (1.14.0, after its second test) its case: the light of the room on its acrylic; its edges as much as it is seen
	if h.slabGlare then
		local ga = (self.slabInfo and h.slabOn) and (0.05 + 0.6 * (h.glareA or 0)) * (self.slabA or 1) or 0
		D.Paint(h.slabGlare, ga > 0.002, ga, pose)
	end
	if h.slabDepth and h.slabOn and self.slabInfo and h.slabDepthA ~= (self.slabA or 1) then
		local style = self.slabInfo.seal and "seal" or "slab"
		h.slabDepthA = self.slabA or 1
		D.DepthPaint(self, h.slabDepth, self.slab.box, D.DepthOf(self, style), style, h.slabDepthA)
	end
end

-------------------------------------------------------------------------------
-- What moves on it, each frame
-------------------------------------------------------------------------------
-- (its glow by its rank: the runes steady, the arcane breathing, the veins of the Void beating as a heart, the lava
-- breathing, the gold shining)
local function GlowAlpha(tier, t)
	if tier == 1 then
		return 0.78 + 0.12 * math.sin(t * 1.7)
	elseif tier == 2 then
		return 0.62 + 0.26 * math.sin(t * 2.2)
	elseif tier == 3 then
		-- (two beats, then a rest)
		local c = CuratorOctoFull.Mod(t , 1.5)
		local beat = math.max(math.exp(-((c - 0.12) / 0.07) ^ 2), 0.75 * math.exp(-((c - 0.42) / 0.08) ^ 2))
		return 0.45 + 0.5 * beat
	elseif tier == 4 then
		return 0.6 + 0.3 * (0.5 + 0.5 * math.sin(t * 2.4)) * (0.82 + 0.18 * math.sin(t * 7.3))
	end
	return 0.7 + 0.22 * math.sin(t * 1.8)
end
CC.GlowAlpha = GlowAlpha

-- (an ember: from the foot of the window, up, swaying, dying)
local function Ember(self, e, elapsed)
	local box = self.style and VIEW or WIN
	if not e.age then
		e.age = 0
		e.life = 1.4 + math.random() * 1.6
		e.x = box[1] + 30 + math.random() * (box[3] - box[1] - 60)
		e.y = box[4] - 6 - math.random() * 60
		e.vy = 38 + math.random() * 60
		e.size = 12 + math.random() * 14
		e.phase = math.random() * 6.3
		local hot = math.random()
		e.tex:SetVertexColor(1, 0.35 + 0.4 * hot, 0.08 + 0.12 * hot)
		e.tex:Show()
	end
	e.age = e.age + elapsed
	local p = e.age / e.life
	if p >= 1 or e.y < box[2] + 20 then
		e.age = nil
		e.tex:Hide()
		return
	end
	e.y = e.y - e.vy * elapsed
	local x = e.x + math.sin(e.age * 2.2 + e.phase) * 9
	local sz = e.size * (1 - 0.45 * p)
	At(e.tex, self, x, e.y, sz, sz * 1.5)
	e.tex:SetAlpha(math.min(1, p * 6) * (1 - p) ^ 0.7)
end

-- (a spark on a gem or on the gold: it grows, turns a little, goes)
local function Spark(self, s, elapsed)
	s.age = s.age + elapsed
	local p = s.age / 0.7
	if p >= 1 then
		s.age = nil
		s.tex:Hide()
		return
	end
	local a = math.sin(p * math.pi)
	At(s.tex, self, s.x, s.y, s.size * (0.4 + 0.6 * a))
	s.tex:SetAlpha(a)
	CuratorOctoFull.SetRotation(s.tex, p * 0.8)
end

-- The light on it: from where the mouse is round it (near it, all its own), else going slowly round it (a priceless card
-- of a style, still: resting above it on its left); its direction (x right, y up) and its strength.
function CC.Light(self, t)
	local lx, ly
	if self.layered then
		lx, ly = REST_X, REST_Y
	else
		lx, ly = math.cos(t * 0.6), math.sin(t * 0.6)
	end
	local power = 0.7
	local left, top = self:GetLeft(), self:GetTop()
	if GetCursorPosition and left and top then
		local cx, cy = GetCursorPosition()
		local scale = CuratorOctoFull.GetEffectiveScale(self)
		if scale and scale > 0 then
			cx, cy = cx / scale, cy / scale
			local dx, dy = (cx - (left + self.W / 2)) / (self.W / 2), (cy - (top - self.H / 2)) / (self.H / 2)
			local d = math.sqrt(dx * dx + dy * dy)
			if d < 4 then
				local k = math.min(1, (4 - d) / 2)
				if d > 0.05 then
					dx, dy = dx / d, dy / d
				else
					dx, dy = lx, ly
				end
				lx, ly = lx * (1 - k) + dx * k, ly * (1 - k) + dy * k
				local n = math.sqrt(lx * lx + ly * ly)
				if n > 1e-3 then
					lx, ly = lx / n, ly / n
				end
				power = 0.7 + 0.3 * k
			end
		end
	end
	self.lightX, self.lightY, self.lightPower = lx, ly, power
	return lx, ly, power
end

-- (the weights of the four lights of a texture, from the left, the right, above, below, for a light from lx, ly)
local function Weights(lx, ly)
	return math.max(0, -lx), math.max(0, lx), math.max(0, ly), math.max(0, -ly)
end
CC.Weights = Weights

-- (1.14.0, after the test of the Paladin collection by its author) The reflections of a priceless card of a style: nothing
-- on it moves of itself; each of its four reflections (SetPic) as much as the light comes from its side (CC.Light: the
-- mouse round it, the nearer the brighter; held in the hand, its turn too: turned to a side, the light of that side), as
-- a holographic card under a lamp.
function CC.Shine(self)
	local lx, ly, power = self.lightX or REST_X, self.lightY or REST_Y, self.lightPower or 0.7
	local R = self.held and self.R
	if R then
		lx, ly = lx + (R[3] or 0) * 2.4, ly - (R[6] or 0) * 2.4
	end
	local a, b, c, d = Weights(lx, ly)
	local sum = a + b + c + d
	if sum > 1e-3 then
		a, b, c, d = a / sum, b / sum, c / sum, d / sum
	end
	local k = 0.45 + 0.55 * power
	local L = self.layers
	L[1]:SetAlpha(a * k)
	L[2]:SetAlpha(b * k)
	L[3]:SetAlpha(c * k)
	L[4]:SetAlpha(d * k)
end

-- (its gems, still, as the light comes to them: each where the light comes from, the nearer its side the brighter; none
-- of itself)
local function Glints(self, sk)
	local lx, ly, power = self.lightX or REST_X, self.lightY or REST_Y, self.lightPower or 0.7
	local n, last = 0, nil
	for _, spot in ipairs(sk.spots) do
		local x, y = spot[1], spot[2]
		if not (last and last[1] == x and last[2] == y) then
			last = spot
			local dx, dy = x - TW / 2, TH / 2 - y
			local dl = math.sqrt(dx * dx + dy * dy)
			local b = dl > 1 and math.max(0, (dx * lx + dy * ly) / dl) ^ 8 * power or 0
			local s = self.sparks[n + 1]
			if s and b > 0.06 then
				n = n + 1
				s.age = nil
				At(s.tex, self, x, y, sk.size * (0.5 + 0.5 * b))
				s.tex:SetVertexColor(sk.colour[1], sk.colour[2], sk.colour[3])
				CuratorOctoFull.SetRotation(s.tex, 0.4)
				s.tex:SetAlpha(math.min(1, b * 1.2))
				s.tex:Show()
			end
		end
	end
	for i = n + 1, CuratorOctoFull.Length(self.sparks) do
		self.sparks[i].tex:Hide()
		self.sparks[i].age = nil
	end
end

-- (a number in 0..1 that looks random, the same for the same n)
local function Hash(n)
	local x = math.sin(n * 12.9898) * 43758.5453
	return x - math.floor(x)
end

-- (where a twinkle of a titanforged card may come: on the metal of its frame, its sides, its top, its foot, round its
-- plate; in points of its texture)
local TWINKLE_SPOTS = { { 15, 120 }, { 15, 300 }, { 15, 470 }, { 497, 120 }, { 497, 300 }, { 497, 470 }, { 128, 14 },
	{ 384, 14 }, { 128, 703 }, { 384, 703 }, { 70, 559 }, { 442, 559 }, { 15, 640 }, { 497, 640 }, { 30, 30 }, { 482, 30 } }
-- (31 October, his word: the cards of the cases rarer than those of the boosters, more of them seen) glints over its
-- picture too, smaller
local TWINKLE_WIN = { { 90, 110 }, { 420, 90 }, { 150, 300 }, { 370, 260 }, { 110, 470 }, { 400, 430 }, { 256, 160 },
	{ 250, 520 }, { 60, 230 }, { 455, 340 } }

-- (titanforged: the colours of the rainbow laid over its metal (its facets in them), each cell from its left to its right;
-- phi: where they are)
local function PrismLight(fin, phi, a, pat)
	local m = fin.foil
	local grad = m[1] and m[1].SetGradient and m[1].c1
	for k = 1, CuratorOctoFull.Length(m) do
		local t, p = m[k], m.part[k]
		local v = (p[3] + p[4]) / 2
		local r1, g1, b1 = Hue(pat, p[1] * 0.9 + v * 0.45 + phi)
		local r2, g2, b2 = Hue(pat, p[2] * 0.9 + v * 0.45 + phi)
		r1, g1, b1 = 0.1 + 0.9 * r1, 0.1 + 0.9 * g1, 0.1 + 0.9 * b1
		r2, g2, b2 = 0.1 + 0.9 * r2, 0.1 + 0.9 * g2, 0.1 + 0.9 * b2
		if grad then
			t.c1:SetRGBA(r1, g1, b1, a)
			t.c2:SetRGBA(r2, g2, b2, a)
			t:SetGradient("HORIZONTAL", t.c1, t.c2)
		else
			t:SetVertexColor((r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2, a)
		end
	end
end

-- (its twinkles, each its own cycle: thunderforged, four of the colour of the storm, anywhere on it, as on the cards of
-- the albums; titanforged, ten of all the colours, on the metal of its frame)
local function Twinkles(self, fin, t, kind)
	local ph = self.phase or 0
	local titan = kind == "titan"
	local n = titan and TWINKLES or 4
	for i, tw in ipairs(fin.tw) do
		if i > n or not kind then
			tw.tex:Hide()
		else
			local period = (2.1 + i * 0.37) * (titan and 0.62 or 1)
			local x = (t + i * 0.83 + ph * 2) / period
			local cycle = math.floor(x)
			local u = x - cycle
			if cycle ~= tw.cycle then
				tw.cycle = cycle
				if titan then
					-- (the first ten on the metal of its frame; the others over its picture, smaller, 31 October)
					local spots = i > 10 and TWINKLE_WIN or TWINKLE_SPOTS
					local spot = spots[1 + CuratorOctoFull.Mod(math.floor(Hash(cycle * 7 + i * 13 + ph * 50) * CuratorOctoFull.Length(spots)) , CuratorOctoFull.Length(spots))]
					tw.x, tw.y = spot[1] + (i > 10 and (Hash(cycle * 5 + i) - 0.5) * 60 or 0), spot[2] + (i > 10 and (Hash(cycle * 11 + i) - 0.5) * 60 or 0)
					tw.size = i > 10 and (22 + 20 * Hash(cycle + i)) or (36 + 32 * Hash(cycle + i))
					local r, g, b = Hue(self.pat, Hash(cycle * 3 + i * 5))
					tw.tex:SetVertexColor(0.45 + 0.55 * r, 0.45 + 0.55 * g, 0.45 + 0.55 * b)
				else
					tw.x, tw.y = TW * (0.12 + math.random() * 0.76), TH * (0.08 + math.random() * 0.84)
					tw.size = (0.1 + math.random() * 0.12) * TW
					tw.tex:SetVertexColor(0.62, 0.84, 1)
				end
				tw.tex:Show()
			end
			if u < 0.35 then
				local a = math.sin(u / 0.35 * math.pi)
				local size = titan and tw.size * (0.5 + 0.5 * a) or tw.size
				-- (a card of a style: nothing past its edges)
				if self.style then
					size = math.min(size, 2 * math.min(tw.x, TW - tw.x, tw.y, TH - tw.y))
				end
				PlaceFx(self, tw.tex, tw.x, tw.y, size)
				tw.tex:SetAlpha(a)
				CuratorOctoFull.SetRotation(tw.tex, u * 1.2)
			else
				tw.tex:SetAlpha(0)
			end
		end
	end
end

-- (thunderforged, each frame, as on the cards of the albums (Card:Crackle): its lightning crawling over it, one drawing
-- then the other, faint; every few seconds (card:Strike: now) it strikes, the whole card crackling three times; the
-- cold light of its edge with it)
local function Crackle(self, fin, t)
	local ph = self.phase or 0
	local every = 2.3 + ph * 1.4
	local u = CuratorOctoFull.Mod((t + ph * 7) , every)
	local at = self.crackleAt
	if at then
		if t - at < 0.34 then
			u = math.max(0, t - at)
		else
			self.crackleAt = nil
		end
	end
	local a1, a2, ra
	if u < 0.34 then
		local on = CuratorOctoFull.Mod(math.floor(u / 0.085) , 2) == 0
		a1, a2, ra = on and 1 or 0.3, on and 0.75 or 0.2, on and 0.9 or 0.5
	else
		local step = math.floor((t + ph * 3) * 14)
		local h = 0.16 + 0.3 * Hash(step + ph * 100)
		a1 = (CuratorOctoFull.Mod(step , 2) == 0) and h or 0.04
		a2 = (CuratorOctoFull.Mod(step , 2) == 1) and h or 0.04
		ra = 0.32 + 0.1 * math.sin(t * 3.1 + ph * 4)
	end
	for _, c in ipairs(fin.arcs[1]) do
		c:SetAlpha(a1)
	end
	for _, c in ipairs(fin.arcs[2]) do
		c:SetAlpha(a2)
	end
	local r = THUNDER_RIM
	for _, c in ipairs(fin.rim) do
		c:SetVertexColor(r[1], r[2], r[3], ra)
	end
end

-- (titanforged, each frame: the colours of its metal flowing with the time, with the turn of the card held in the hand
-- or where the light comes from (card:Flourish: once round all of them, bright); its edge through the colours; in its
-- window, its foil by three weights, the light of the prism turning, breathing)
local function Prism(self, fin, t, elapsed)
	local ph = self.phase or 0
	local R = self.held and self.R
	local tx, ty
	if R then
		tx, ty = R[3] or 0, -(R[6] or 0)
	else
		tx, ty = (self.lightX or 0) * 0.3, (self.lightY or 0) * 0.3
	end
	local boost, spin = 0, 0
	if self.flourishT then
		self.flourishT = self.flourishT + elapsed
		local e = self.flourishT / 1.8
		if e >= 1 then
			self.flourishT = nil
		else
			boost, spin = 0.9 * (1 - e), 1 - (1 - e) ^ 3
		end
	end
	-- (1.14.0: a pattern, its light at its own speed, its own way, from its own start)
	local pat = self.pat
	local phi = t * 0.11 * (pat and pat.speed * pat.dir or 1) + ph * 2.1 + (pat and pat.phase or 0) + tx * 0.9 + ty * 0.6 + spin
	PrismLight(fin, phi, math.min(1, CC.PRISM_A * (pat and pat.tint and pat.power or 1) + boost * 0.3), pat)
	local r, g, b = Hue(pat, phi * 1.3)
	-- (31 October: its edge brighter, 0.36 before)
	local ra = math.min(1, 0.62 + 0.14 * math.sin(t * 1.5 + ph * 5) + boost * 0.5)
	for _, c in ipairs(fin.rim) do
		c:SetVertexColor(0.55 + 0.45 * r, 0.5 + 0.45 * g, 0.45 + 0.55 * b, ra)
	end
	local w, sum = {}, 0
	for i = 1, 3 do
		local c = (1 + math.cos(phi * TAU - TAU * (i - 1) / 3)) / 2
		w[i] = c * c
		sum = sum + w[i]
	end
	local lean = R and math.min(1, math.sqrt(tx * tx + ty * ty)) or 0
	-- (over the picture of a card of a style, not behind a creature: a veil of its colours, the light of the prism fainter)
	-- (31 October, his word: the foil did not show on them; 0.38 before)
	local veil = self.style and 0.85 or 1
	for i, fo in ipairs(self.winFoil) do
		fo:SetAlpha(math.min(1, (0.9 + 0.4 * lean + boost) * w[i] / sum) * veil)
	end
	-- (31 October, his word) the second foil of its window, its own weights (a third of a turn further), and the foil of
	-- its frame, bright
	for i, fo in ipairs(self.winFoil2) do
		local j = CuratorOctoFull.Mod((i + 1) , 3) + 1
		fo:SetAlpha(math.min(1, (0.8 + 0.4 * lean + boost) * w[j] / sum) * veil)
	end
	local pulse = 0.85 + 0.15 * math.sin(t * 2.1 + ph * 3)
	for i, au in ipairs(self.titanAura) do
		au:SetAlpha(math.min(1, (1.5 * pulse + boost) * w[i] / sum + 0.18))
	end
	for i = 1, 3 do
		local a = math.min(1, (1.25 + 0.4 * lean + boost) * w[i] / sum)
		for _, c in ipairs(fin.facets[i]) do
			c:SetAlpha(a)
		end
	end
	local breath = math.sin(t * 1.3 + ph * 4)
	CuratorOctoFull.SetRotation(self.glory[1], t * 0.1 + ph * 3)
	self.glory[1]:SetAlpha(math.min(1, 0.5 + 0.12 * breath + boost * 0.5) * (self.style and 0.45 or 1))
	CuratorOctoFull.SetRotation(self.glory[2], -t * 0.16 + 0.4)
	self.glory[2]:SetAlpha(math.min(1, 0.34 + 0.1 * breath + boost * 0.4) * (self.style and 0.45 or 1))
end

-- Its forged finish, each frame (thunderforged: Crackle; titanforged: Prism), its twinkles.
function CC.Forged(self, t, elapsed)
	local fin, kind = self.fin, self.finish
	if kind == "thunder" then
		Crackle(self, fin, t)
	elseif kind == "titan" then
		Prism(self, fin, t, elapsed)
	end
	Twinkles(self, fin, t, kind)
end

-- Each frame: its creature turning to and fro, what moves by its rank, its forged finish, a sheen over it now and then
-- (forged or priceless).
function CC.Update(self, elapsed)
	Relevel(self)
	self.t = (self.t or 0) + elapsed
	local t = self.t
	local sc = self.scene
	-- (1.14.0, the option of the creatures as a still picture: it stays as it is, paused, UI/Card.lua Look)
	if sc and self.live ~= false and not self.held and not self.frozen and not (ns.db and ns.db.still) and (sc.SetRotation or sc.SetFacing) and sc:IsShown() then
		CuratorOctoFull.SetRotation(sc, 0.35 + math.sin(t * 0.55) * 0.55)
	end
	-- (its weapon: its model, standing and turning; its name once the game knows it. A spell: what it does, once the
	-- game knows it; an armour: put on, turning, still while the card is held)
	if not (self.held or self.frozen) then
		self.dressT = (self.dressT or 0) + elapsed
	end
	ArmStep(self, elapsed)
	SpellStep(self, elapsed)
	DressStep(self, elapsed)
	if self.namePending and self.weapon and t >= (self.nameAt or 0) then
		self.nameAt = t + 0.25
		local name = CC.WeaponName(self.weapon)
		if name then
			self.namePending = nil
			self.name:SetText(name)
			self:FitName()
		end
	end
	local tier = self.tier or 1
	local st = self.style
	-- (1.14.0, a priceless card of a style: still, its glow too; its reflections as the light comes)
	self.glow:SetAlpha(self.layered and 0.74 or GlowAlpha(tier, t))
	if self.layered then
		CC.Light(self, t)
		CC.Shine(self)
	end
	if st then
		-- (a card of a style: nothing turns round it; its embers when its style has them)
		if st.embers and st.embers[tier] then
			if t >= (self.nextEmber or 0) then
				self.nextEmber = t + 0.12 + math.random() * 0.16
				for _, e in ipairs(self.embers) do
					if not e.age then
						Ember(self, e, 0)
						break
					end
				end
			end
			for _, e in ipairs(self.embers) do
				if e.age then
					Ember(self, e, elapsed)
				end
			end
		end
	elseif tier == 2 then
		CuratorOctoFull.SetRotation(self.rune, t * 0.22)
		self.rune:SetAlpha(0.32 + 0.1 * math.sin(t * 1.3))
	elseif tier == 3 then
		self.orbGlow:SetAlpha(0.35 + 0.45 * (GlowAlpha(3, t) - 0.45) / 0.5)
	elseif tier == 4 then
		-- (embers rising, one more now and then)
		if t >= (self.nextEmber or 0) then
			self.nextEmber = t + 0.12 + math.random() * 0.16
			for _, e in ipairs(self.embers) do
				if not e.age then
					Ember(self, e, 0)
					break
				end
			end
		end
		for _, e in ipairs(self.embers) do
			if e.age then
				Ember(self, e, elapsed)
			end
		end
	elseif tier == 5 then
		CuratorOctoFull.SetRotation(self.rays[1], t * 0.10)
		CuratorOctoFull.SetRotation(self.rays[2], -t * 0.16)
		self.rays[1]:SetAlpha(0.30 + 0.06 * math.sin(t * 0.9))
		self.rays[2]:SetAlpha(0.20 + 0.06 * math.sin(t * 1.3 + 1))
	end
	-- (the shine of its gold as the light moves; less of it under a forged finish)
	if self.glint then
		local lx, ly, power = CC.Light(self, t)
		local w = { Weights(lx, ly) }
		local forged = self.finish ~= nil
		for i, gl in ipairs(self.gloss) do
			gl:SetAlpha(w[i] * power * (forged and 0.5 or 0.85))
		end
	end
	if self.finish then
		CC.Forged(self, t, elapsed)
	end
	-- (its parts that move: the crystals floating, the flames)
	for _, p in ipairs(tier == 4 and self.under or self.parts) do
		local key = p.key
		if key and p:IsShown() then
			local fl = FLOAT[key]
			if fl then
				Place(p, self, p.x, p.y - math.sin(t * fl[2] + fl[3]) * fl[1], p.x + p.w, p.y + p.h - math.sin(t * fl[2] + fl[3]) * fl[1])
			elseif string.sub(key, 1, 5) == "flame" then
				local i = tonumber(string.sub(key, 6)) or 1
				local s = 0.86 + 0.1 * math.sin(t * 9.0 + i * 1.7) + 0.06 * math.sin(t * 21 + i * 3.1)
				local sway = math.sin(t * 5.3 + i * 2.1) * 2.5
				p:ClearAllPoints()
				p:SetPoint("BOTTOM", self, "TOPLEFT", (p.x + p.w / 2 + sway) * self.k, -(p.y + p.h) * self.k)
				CuratorOctoFull.SetSize(p, p.w * (0.94 + 0.06 * s) * self.k, p.h * s * self.k)
				p:SetAlpha(0.78 + 0.22 * math.sin(t * 13 + i * 2.3) ^ 2)
			end
		end
	end
	-- (the sparks of its gems, of its gold; a priceless card of a style, still: its gems as the light comes to them)
	local sk = (st and st.sparks or SPARKS)[tier]
	if sk and self.layered then
		Glints(self, sk)
	elseif sk then
		if t >= (self.nextSpark or 0) then
			self.nextSpark = t + sk.every[1] + math.random() * sk.every[2]
			for _, s in ipairs(self.sparks) do
				if not s.age then
					local spot = sk.spots[math.random(CuratorOctoFull.Length(sk.spots))]
					s.x, s.y, s.age, s.size = spot[1], spot[2], 0, sk.size
					s.tex:SetVertexColor(sk.colour[1], sk.colour[2], sk.colour[3])
					s.tex:Show()
					break
				end
			end
		end
		for _, s in ipairs(self.sparks) do
			if s.age then
				Spark(self, s, elapsed)
			end
		end
	end
	local pick = self.pick
	local forged = self.finish ~= nil
	local shiny = pick and (forged or (tier == 5 and not self.layered))
	if shiny and t >= (self.nextSheen or 1.2) and not self.sweepT then
		self.nextSheen = t + 3.2
		self:Sweep(1.1)
	end
	if self.sweepT then
		self.sweepT = self.sweepT + elapsed
		local raw = math.min(1, self.sweepT / self.sweepDur)
		local col = forged and CC.FIN_TINT[self.finish] or { 1, 0.84, 0.45 }
		self.sheen:SetVertexColor(col[1], col[2], col[3])
		self.sheen:ClearAllPoints()
		self.sheen:SetPoint("CENTER", self, "CENTER", (raw * 2 - 1) * self.W * 1.1, 0)
		self.sheen:SetAlpha(math.sin(raw * math.pi) * 0.8)
		if raw >= 1 then
			self.sweepT = nil
			self.sheen:SetAlpha(0)
		end
	end
	if self.wearOn and ns.WearUI then
		ns.WearUI.Tick(self, t)
	end
	if self.held then
		self:HeldPaint()
	end
end
