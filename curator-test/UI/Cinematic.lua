local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

-- The entrance of the legendary and mythic cards, as a scene of the game. (1.12.0) First the black, between two
-- black bands: the line of the creature written in the middle of the screen letter by letter while its voice says it
-- (a creature without a line: its cry in the dark). Then the screen goes dark, its own music playing; the creature
-- stands in the shadow, close, before
-- the place of its album, wearing the light of its power; the light falls on it as it roars (or
-- speaks its line, with its words under the screen) and the camera pulls back; it turns to you,
-- gathers its power and strikes at you (a spell thrown, a breath, a blow, the ground shaking...);
-- its name comes on the banner of the bosses while it turns slowly; then the card is turned over
-- under a flash. A click skips it, /curator cinematic turns it off. What each creature does is in
-- Data/Cinematic.lua.
local Cin = {}
ns.Cinematic = Cin

local BAR = 0.11 -- the black bands, a share of the height of the screen

-- The creature stands in a scene of the game (a ModelScene, as the Adventure Guide and the
-- collections have) with one actor: its bounding box is measured once it is loaded, and the
-- camera is placed from it, so that every creature takes the same share of the screen, whatever
-- its size. The camera has two values: zoom (0: the whole creature, 1: its head and shoulders)
-- and distance (1: the part framed fills 0.85 of the height of the screen, as a creature fills a
-- card; larger: smaller).
local FILL = 0.85
local FOV = 0.6       -- the field of view of the camera (radians)
local PITCH = -0.06   -- the camera a little lower than the creature, looking up at it
-- A client without model scenes: a model frame, whose camera the client places itself, from the
-- bounds of the model. It draws its creature as large as the diagonal of the frame; on a card (a
-- frame nearly square, 1.08 times as wide as tall) it shows it whole. The frame of the scene takes
-- the whole screen, far wider: its distances are multiplied by the ratio of the two diagonals
-- (Cin.camK).
local CARD_DIAG = math.sqrt(1 + 1.08 * 1.08)
-- the camera at the three moments: in the shadow (a little closer to its face), when the light
-- falls (pulled back), under its name (coming slowly a little closer)
local CAM = {
	dark = { zoom = 0.3, dist = 1.3 }, darkTo = { zoom = 0.45, dist = 1.22 },
	lit = { zoom = 0, dist = 1.62 }, title = { dist = 1.48 },
}

-- What changes with the rarity: the moments of the scene (seconds from its start), the light, the
-- colours, the sounds.
local STYLE = {
	[5] = {
		impact = 1.75, title = 2.15, beat = 3.65, exit = 5.3,
		tint = { 1, 0.62, 0.22 }, rays2 = nil,
		ambient = { 1, 0.9, 0.78 }, ambientI = 0.62, diffuse = { 1, 0.86, 0.62 }, diffuseI = 1.05,
		embers = { { 1, 0.78, 0.35 }, { 1, 0.62, 0.2 } },
		open = { 1485 },             -- a rumble under the ground
		impactSnd = { 1273, 888 },   -- a blow of holy light
		titleSnd = { 63971, 888 },
		skull = false,
	},
	[6] = {
		impact = 2.75, title = 3.15, beat = 4.75, exit = 6.8,
		tint = { 1, 0.16, 0.22 }, rays2 = { 1, 0.78, 0.36 },
		ambient = { 1, 0.62, 0.58 }, ambientI = 0.55, diffuse = { 1, 0.8, 0.62 }, diffuseI = 1.1,
		embers = { { 1, 0.25, 0.25 }, { 1, 0.7, 0.3 } },
		open = { 6594, 6595, 1485 }, -- a bell tolls (the Horde's for its albums)
		impactSnd = { 12827, 4654 },  -- the gong
		titleSnd = { 63971, 888 },
		skull = true,
	},
}

-- The waves around the creature when its card has a finish.
local FINISH_WAVES = {
	thunder = { { 0.55, 0.8, 1 }, { 0.9, 0.97, 1 }, { 0.35, 0.55, 1 }, { 0.7, 0.9, 1 }, { 1, 1, 1 } },
	titan = { { 1, 0.35, 0.4 }, { 1, 0.8, 0.3 }, { 0.42, 1, 0.55 }, { 0.38, 0.85, 1 }, { 0.92, 0.48, 1 } },
}

-- The music of the moment: the one of the creature (its city, its lair, its raid: Data/Cinematic.lua),
-- the first one the client has; else the "intro" moment of a capital (its album's own, for the albums
-- of the capitals), else the Valley of Heroes for the Alliance, Orgrimmar for the Horde, Ironforge
-- for the others, and the Undercity for the mythic cards.
local CITY_MUSIC = { [1453] = 2541, [1455] = 5334, [1457] = 3900, [1454] = 3402, [1456] = 7076, [1458] = 6080 }
local function Music(card, role)
	local theme = role and ns.CinematicThemes and ns.CinematicThemes[role.theme]
	if theme then
		local list = {}
		for i, kit in ipairs(theme) do
			list[i] = kit
		end
		list[CuratorOctoFull.Length(list) + 1] = 2541
		return list
	end
	local s = card.series or {}
	local kit = s.city and CITY_MUSIC[s.city]
	if not kit then
		if card.rarity >= 6 then
			kit = 6080
		elseif s.side == "A" then
			kit = 2541
		elseif s.side == "H" then
			kit = 3402
		else
			kit = 5334
		end
	end
	return { kit, 2541 }
end

-- Animations, the first one the model has wins: its roar when the light falls on it, the blow
-- that follows, its stance in between. The characters salute rather than roar.
local ANIM = {
	creature = {
		roar = { 55, 74, 130, 54, 118, 57, 17, 16, 18 },        -- battle roar, roar, special, cast, attacks
		blow = { 57, 118, 58, 53, 54, 17, 18, 16 },             -- special attacks, casts, attacks
		stance = { 25, 26, 27, 0 },                             -- ready
	},
	character = {
		roar = { 55, 82, 113, 64 },                             -- battle roar, flex, salute, exclamation
		blow = { 54, 57, 113, 66 },                             -- cast, special, salute, bow
		stance = { 0 },
	},
}

-- The strike at you (Data/Cinematic.lua gives each creature its own). The colours of the powers:
local COLOUR = {
	holy = { 1, 0.85, 0.45 }, fire = { 1, 0.45, 0.12 }, frost = { 0.45, 0.75, 1 }, nature = { 0.4, 0.95, 0.3 },
	storm = { 0.55, 0.75, 1 }, shadow = { 0.62, 0.3, 1 }, arcane = { 0.85, 0.45, 1 }, fel = { 0.45, 1, 0.2 },
	physical = { 1, 0.92, 0.82 }, sand = { 1, 0.78, 0.4 }, blood = { 0.9, 0.08, 0.1 },
}
-- what a power leaves at the edges of the screen when it reaches you (how it is drawn, how strong)
local EDGE = {
	fire = { "StrikeBurn", "ADD", 0.95 }, fel = { "StrikeBurn", "ADD", 0.95 }, blood = { "StrikeBurn", "ADD", 0.95 },
	holy = { "StrikeBurn", "ADD", 0.8 }, sand = { "StrikeSmoke", "ADD", 0.7 }, frost = { "StrikeFrost", "ADD", 0.95 },
	shadow = { "StrikeSmoke", "ADD", 0.7 }, arcane = { "StrikeSmoke", "ADD", 0.65 }, nature = { "StrikeSmoke", "ADD", 0.7 },
	storm = { "StrikeSmoke", "ADD", 0.55 }, physical = { "StrikeSmoke", "BLEND", 0.85 },
}
-- Each way of striking: the animations of its gathering and of its release (after the one of the
-- spell, the first one the model has), how long it takes to reach you, how hard the screen shakes,
-- the mark it leaves in the middle of the screen, and the camera while it gathers (zoom, distance).
local STRIKE = {
	bolt = { pre = { 51, 52, 31, 0 }, cast = { 53, 54, 32, 16 }, travel = 0.34, shake = 10, mark = "StrikeOrb", cam = { 0.12, 1.4 } },
	beam = { pre = { 51, 52, 31, 0 }, cast = { 53, 54, 32, 16 }, travel = 0.2, shake = 9, mark = "StrikeOrb", cam = { 0.15, 1.38 } },
	breath = { pre = { 51, 52, 55, 74 }, cast = { 53, 182, 54, 55, 74, 16 }, travel = 0.42, shake = 8, cam = { 0.35, 1.3 } },
	blow = { pre = { 56, 27, 26, 25, 0 }, cast = { 57, 58, 18, 17, 16, 118 }, travel = 0.17, shake = 12, mark = "StrikeSlash", cam = { 0.05, 1.75 } },
	claw = { pre = { 56, 74, 27, 25, 0 }, cast = { 17, 16, 18, 57, 118 }, travel = 0.17, shake = 12, mark = "StrikeClaw", cam = { 0.05, 1.75 } },
	smash = { pre = { 56, 55, 52, 27, 0 }, cast = { 181, 58, 18, 16, 54, 55 }, travel = 0.12, shake = 18, mark = "StrikeCracks", cam = { 0, 1.7 } },
	nova = { pre = { 52, 51, 31, 0 }, cast = { 54, 53, 32, 55 }, travel = 0.3, shake = 10, cam = { 0.1, 1.45 } },
	bless = { pre = { 52, 51, 0 }, cast = { 54, 53, 113 }, travel = 0.5, shake = 0, mark = "StrikeRunes", cam = { 0.12, 1.45 } },
}
local GATHER = 0.8   -- the gathering of the strike (seconds)
local AFTER = 1.05   -- from the light falling to the strike
-- The chat types of the voice lines: the colour of the chat, the format of the line (the emotes carry
-- the name in their text).
local CHAT = {
	[0] = { "MONSTER_SAY", "CHAT_MONSTER_SAY_GET", { 1, 1, 0.62 } },
	[1] = { "MONSTER_YELL", "CHAT_MONSTER_YELL_GET", { 1, 0.25, 0.25 } },
	[2] = { "MONSTER_EMOTE", nil, { 1, 0.5, 0.25 } },
	[3] = { "RAID_BOSS_EMOTE", nil, { 1, 0.87, 0 } },
	[4] = { "MONSTER_WHISPER", "CHAT_MONSTER_WHISPER_GET", { 1, 0.71, 0.76 } },
}
CHAT[5], CHAT[6], CHAT[7] = CHAT[4], CHAT[1], CHAT[3]
-- the creature that carries the impact of the strike in front of you: an invisible one (its model
-- is only there to wear the spell visual)
local STALKER = 11686

-- The role of a card: { theme, school, strike, aura, pre, cast, imp, hit, line } (Data/Cinematic.lua).
local function Role(card)
	local r = ns.CinematicRoles and ns.CinematicRoles[card.real or card.npc]
	if type(r) ~= "table" or not STRIKE[r[3]] then
		return nil
	end
	return {
		theme = r[1], school = COLOUR[r[2]] and r[2] or "physical", strike = r[3], aura = r[4] or 0,
		pre = type(r[5]) == "table" and r[5] or nil, cast = type(r[6]) == "table" and r[6] or nil,
		imp = r[7] or 0, hit = r[8] or 0, line = type(r[9]) == "table" and r[9] or nil,
	}
end

-- The music of a creature, for the booster of its dungeon (UI/Booster.lua): the sound kits to try.
function Cin:MusicOf(card)
	return Music(card, Role(card))
end

-- The text of a voice line in the language of the client (nil: none in this language).
local function LineText(npc, line)
	local texts = ns.CinematicLines and ns.CinematicLines[npc]
	if not texts then
		return nil
	end
	local loc = ns.locale or (GetLocale and GetLocale()) or "enUS"
	local text = texts[loc] or ((loc == "enUS" or loc == "enGB") and texts.enUS)
	if not text or text == "" then
		return nil
	end
	local me = UnitName and UnitName("player") or ""
	return (string.gsub(text, "%$[nN]", me))
end

-- (1.12.0) A creature without a line of its own says a line as such creatures say them: a villain its threat (an
-- undead, a demon, a dragon often one of theirs, a machine always), a beast or an elemental what it does (an emote,
-- its name in it), a friendly character its greeting (a friendly beast what it does); on Hallow's End, one time in
-- two, a line of the night. Always the same one for the same creature. chat: how it is said (CHAT). (Their words in
-- the other languages: Locale112.lua.)
local CLICHE = {
	villain = { chat = 1,
		"You dare enter my domain?", "None shall pass!", "You should never have come here.",
		"Your bones will join the others!", "I will crush you like an insect!", "Prepare to meet your doom!",
		"Fools! You have sealed your fate!", "Bow before me!", "At last, a worthy challenge!",
		"No one leaves this place alive!", "Your journey ends here!", "Another fool seeking glory...",
	},
	undead = { chat = 1, "Join us in death!", "Your soul will be mine!", "Death is only the beginning.", "The living have no place here!" },
	demon = { chat = 1, "Your world will burn!", "The Legion will consume you!", "I will feast on your soul!", "Kneel before your new master!" },
	dragon = { chat = 1, "Insolent mortals!", "You are nothing but ashes in the wind!", "Your kind is nothing but prey!", "You dare disturb my slumber?" },
	machine = { chat = 1, "Intruder detected.", "Target acquired. Commencing extermination.", "Threat level: negligible." },
	beast = { chat = 2,
		"%s growls menacingly.", "%s bares its fangs!", "%s lets out a terrifying howl!", "%s goes into a frenzy!",
		"%s sniffs the air... and turns toward you.", "%s paws at the ground.", "%s circles you, waiting for its moment.",
	},
	elemental = { chat = 2, "%s rumbles with fury!", "%s surges with raw power!", "%s crackles ominously." },
	friend = { chat = 0,
		"Well met, adventurer!", "Ah, a collector! I have heard of you.", "May your path be safe, friend.",
		"Stand with me, and we shall prevail!", "Azeroth needs heroes like you.", "Keep your blade sharp and your wits sharper.",
	},
	pet = { chat = 2, "%s sniffs at you curiously.", "%s looks at you with gentle eyes.", "%s nudges you playfully." },
	hallow = { chat = 1,
		"Trick or treat? I choose... trick!", "Your candy... or your soul!", "The night of the dead has come!",
		"Light your lanterns... while you still can.",
	},
}
Cin.CLICHE = CLICHE
-- (the types of creature of the game: those that do not speak, those of the elements; the speakers with lines of their
-- own kind)
local MUTE = { [1] = true, [8] = true, [12] = true, [14] = true }
local ELEMENTS = { [4] = true, [11] = true, [13] = true }
local KIN = { [6] = "undead", [3] = "demon", [2] = "dragon" }

-- Its cliché: the text in the language of the client and how it is said (nil: a card with no creature).
local function Cliche(card)
	local id = tonumber(card.real or card.npc)
	if not id then
		return nil
	end
	local ty = tonumber(card.type) or 0
	local pool
	if card.friendly then
		pool = MUTE[ty] and CLICHE.pet or CLICHE.friend
	elseif MUTE[ty] then
		pool = CLICHE.beast
	elseif ELEMENTS[ty] then
		pool = CLICHE.elemental
	elseif ty == 9 then
		pool = CLICHE.machine
	elseif card.series and card.series.look == "hallow" and CuratorOctoFull.Mod(id , 2) == 0 then
		pool = CLICHE.hallow
	elseif KIN[ty] and CuratorOctoFull.Mod(id , 3) ~= 0 then
		pool = CLICHE[KIN[ty]]
	else
		pool = CLICHE.villain
	end
	local text = pool[CuratorOctoFull.Mod(math.floor(id / 6) , CuratorOctoFull.Length(pool)) + 1]
	return L[text], pool.chat
end
Cin.Cliche = Cliche

-------------------------------------------------------------------------------
-- Building
-------------------------------------------------------------------------------
local function Light(style, on)
	if not (CreateColor and CreateVector3D) then
		return nil
	end
	local t = style.tint
	if not on then
		-- the shadow: no light on its face, only a light from behind and above that draws the edges
		-- of its head and shoulders in the colour of its rarity (the light of the game goes from
		-- the camera to the creature along -x: +x comes from behind it)
		return {
			omnidirectional = false, point = CreateVector3D(0.75, 0, -0.66),
			ambientIntensity = 0.05, ambientColor = CreateColor(t[1], t[2], t[3]),
			diffuseIntensity = 1.3, diffuseColor = CreateColor(t[1], t[2], t[3]),
		}
	end
	local a, d = on == "flash" and style.tint or style.ambient, style.diffuse
	-- from the front, a little from the left and from above
	return {
		omnidirectional = false, point = CreateVector3D(-1, 0.45, -0.55),
		ambientIntensity = on == "flash" and 0.9 or style.ambientI, ambientColor = CreateColor(a[1], a[2], a[3]),
		diffuseIntensity = style.diffuseI, diffuseColor = CreateColor(d[1], d[2], d[3]),
	}
end

-- A text in a font of the game, made smaller (down to minSize) until it fits the width.
local function FitFont(fs, fontObject, text, width, size, minSize)
	S.SetFontObject(fs, fontObject)
	fs:SetText(text)
	local fo = _G[fontObject]
	if not (fo and fo.GetFont) then
		return
	end
	local file, _, flags = fo:GetFont()
	while file and size > minSize and ns.TextWidth(fs) > width do
		size = size - 1
		fs:SetFont(file, size, flags or "")
	end
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

-- The banner of the bosses (the one the game shows when a boss falls), for the name of the card.
local function BuildLegacyBanner(b)
	CuratorOctoFull.SetSize(b, 440, 100)
	b.trim = Tex(b, "BACKGROUND", 0)
	b.trim:SetAllPoints(b)
	b.back = Tex(b, "BACKGROUND", 1)
	b.back:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
	b.back:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
	CuratorOctoFull.ColorTexture(b.back, 0.045, 0.025, 0.02, 0.96)
	b.gem = Tex(b, "ARTWORK", 0, "Gem6")
	CuratorOctoFull.SetSize(b.gem, 25, 25)
	b.gem:SetPoint("TOP", b, "TOP", 0, 12)
	b.title = S.Text(b, "GameFontNormalHuge")
	b.title:SetPoint("TOP", b, "TOP", 0, -20)
	b.title:SetWidth(404)
	CuratorOctoFull.SetWordWrap(b.title, false)
	b.sub = S.Text(b, "GameFontNormalLarge")
	b.sub:SetPoint("TOP", b.title, "BOTTOM", 0, -5)
	b.line = S.Text(b, "GameFontHighlight")
	b.line:SetPoint("TOP", b.sub, "BOTTOM", 0, -5)
	b.line:SetWidth(404)
	b.line:SetTextColor(0.86, 0.86, 0.86)
	b.legacy = true
	b:Hide()
	return b
end

local function BuildBanner(parent)
	local b = CreateFrame("Frame", nil, parent)
	if not (S.HasAtlas("BossBanner-BgBanner-Top") and S.HasAtlas("BossBanner-BgBanner-Bottom")
		and S.HasAtlas("BossBanner-BgBanner-Mid") and S.HasAtlas("BossBanner-BottomFillagree")) then
		return BuildLegacyBanner(b)
	end
	CuratorOctoFull.SetSize(b, 440, 156)
	local function Piece(layer, sub, atlas, blend)
		local t = b:CreateTexture(nil, layer, nil, sub)
		if not S.Atlas(t, atlas, true) then
			t:Hide()
			t.missing = true
		end
		if blend then
			t:SetBlendMode(blend)
		end
		t:SetAlpha(0)
		return t
	end
	b.top = Piece("BORDER", 0, "BossBanner-BgBanner-Top")
	b.top:SetPoint("TOP", 0, -44)
	b.topGlow = Piece("BORDER", 1, "BossBanner-BgBanner-Top", "ADD")
	b.topGlow:SetPoint("TOP", 0, -44)
	b.bottom = Piece("BORDER", 0, "BossBanner-BgBanner-Bottom")
	b.bottom:SetPoint("BOTTOM")
	b.bottomGlow = Piece("BORDER", 1, "BossBanner-BgBanner-Bottom", "ADD")
	b.bottomGlow:SetPoint("BOTTOM")
	b.mid = Piece("BACKGROUND", 0, "BossBanner-BgBanner-Mid")
	b.mid:SetPoint("TOPLEFT", b.top, "TOPLEFT", 0, -34)
	b.mid:SetPoint("BOTTOMRIGHT", b.bottom, "BOTTOMRIGHT", 0, 25)
	-- (the glow of the middle follows the glows of the top and of the bottom as they widen)
	b.midGlow = Piece("BACKGROUND", 1, "BossBanner-BgBanner-Mid", "ADD")
	b.midGlow:SetPoint("TOPLEFT", b.topGlow, "TOPLEFT", 0, -34)
	b.midGlow:SetPoint("BOTTOMRIGHT", b.bottomGlow, "BOTTOMRIGHT", 0, 25)
	-- in its middle on top: the skull of the bosses (mythic cards) or the gem of the rarity in the
	-- ring of the portraits (legendary cards)
	b.skull = Piece("OVERLAY", 0, "BossBanner-SkullCircle")
	b.skull:SetPoint("CENTER", b.top, "TOP", 0, -20)
	b.spikes = Piece("ARTWORK", 0, "BossBanner-SkullSpikes")
	b.spikes:SetPoint("CENTER", b.skull, "CENTER", -1, 6)
	b.gem = b:CreateTexture(nil, "OVERLAY", nil, 0)
	b.gem:SetTexture(MEDIA .. "Gem5")
	CuratorOctoFull.SetSize(b.gem, 34, 34)
	b.gem:SetPoint("CENTER", b.skull, "CENTER", 0, 0)
	b.gem:SetAlpha(0)
	b.ring = Piece("OVERLAY", 1, "BossBanner-PortraitBorder")
	b.ring:SetPoint("CENTER", b.skull, "CENTER", 0, 0)
	b.left = Piece("ARTWORK", 0, "BossBanner-LeftFillagree")
	b.right = Piece("ARTWORK", 0, "BossBanner-RightFillagree")
	b.bottomFill = Piece("ARTWORK", 0, "BossBanner-BottomFillagree")
	b.bottomFill:SetPoint("BOTTOM", 0, 8)
	b.flash = Piece("OVERLAY", 4, "BossBanner-RedFlash", "ADD")
	b.flash:SetPoint("CENTER", b.skull, "CENTER", 0, 3)
	b.bolts = {}
	for i, dx in ipairs({ 15, -15, 0 }) do
		local t = Piece("OVERLAY", 2 + i, "BossBanner-RedLightning", "ADD")
		t:SetPoint("CENTER", b.spikes, "CENTER", dx, dx == 0 and 0 or -4)
		b.bolts[i] = t
	end
	-- the name, the rarity (and finish), the line of the card
	b.title = S.Text(b, "QuestFont_Enormous")
	b.title:SetPoint("TOP", b.top, "TOP", 0, -47)
	CuratorOctoFull.SetWordWrap(b.title, false)
	b.sub = S.Text(b, "GameFontNormalLarge")
	b.sub:SetPoint("TOP", b.bottomFill, "BOTTOM", 0, -2)
	b.line = S.Text(b, "GameFontHighlight")
	b.line:SetPoint("TOP", b.sub, "BOTTOM", 0, -5)
	b.line:SetTextColor(0.86, 0.86, 0.86)
	for _, fs in ipairs({ b.title, b.sub, b.line }) do
		fs:SetAlpha(0)
	end
	b:Hide()
	return b
end

function Cin:Build()
	if self.frame then
		return
	end
	local f = CreateFrame("Frame", "CuratorCinematic", UIParent)
	f:SetAllPoints(UIParent)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel(600)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	f.curtain = Tex(f, "BACKGROUND", -8)
	f.curtain:SetAllPoints()
	CuratorOctoFull.ColorTexture(f.curtain, 0, 0, 0, 1)

	-- the stage: the place of the album behind, the light behind the creature, the creature
	local st = CreateFrame("Frame", nil, f)
	st:SetAllPoints(f)
	st:SetFrameLevel(f:GetFrameLevel() + 2)
	f.stage = st
	f.backdrop = Tex(st, "BACKGROUND", -6)
	f.tint = Tex(st, "BACKGROUND", -5, nil, "ADD")
	CuratorOctoFull.ColorTexture(f.tint, 1, 1, 1, 1)
	f.shade = Tex(st, "BACKGROUND", -4, "Vignette")
	f.floor = Tex(st, "BORDER", 0, "Glow", "ADD")
	f.rays = Tex(st, "BORDER", 1, "Rays", "ADD")
	f.rays2 = Tex(st, "BORDER", 2, "Rays", "ADD")
	f.bolts = {}
	for i = 1, 4 do
		local t = st:CreateTexture(nil, "BORDER", nil, 3)
		if not S.Atlas(t, "BossBanner-RedLightning") then
			t:SetTexture(MEDIA .. "Rays")
		end
		t:SetBlendMode("ADD")
		t:SetAlpha(0)
		f.bolts[i] = t
	end
	-- the creature: a model frame (it tells which animations the creature has: an actor of a scene
	-- cannot), and the scene with its actor that shows it (a client without model scenes: the
	-- model frame shows it)
	local m = CreateFrame("PlayerModel", nil, st)
	m:SetFrameLevel(st:GetFrameLevel() + 3)
	m.hasLoadScript = CuratorOctoFull.SetScript(m, "OnModelLoaded", function(self)
		self.loaded = true
		Cin:ApplyLook()
		if not Cin.frame.scene then
			Cin:WearAura()
		end
		local go = self.pending
		if go then
			self.pending = nil
			go()
		end
	end)
	f.model = m
	local ok, scene = pcall(CreateFrame, "ModelScene", nil, st)
	if ok and scene and scene.CreateActor then
		local actor
		for _, template in ipairs({ false, "ModelSceneActorTemplate" }) do
			local made, a = pcall(scene.CreateActor, scene, nil, template or nil)
			if made and a then
				actor = a
				break
			end
		end
		if actor then
			scene:SetFrameLevel(st:GetFrameLevel() + 4)
			-- (a click goes through it, to the scene that skips the entrance)
			scene:EnableMouse(false)
			scene:EnableMouseWheel(false)
			pcall(scene.SetCameraNearClip, scene, 0.05)
			pcall(scene.SetCameraFarClip, scene, 2000)
			-- (other models on the screen: drawn apart from them)
			pcall(scene.SetAllowOverlappedModels, scene, true)
			f.scene, f.actor = scene, actor
			-- a second actor, invisible, that carries the impact of the strike in front of you
			for _, template in ipairs({ false, "ModelSceneActorTemplate" }) do
				local made, a = pcall(scene.CreateActor, scene, nil, template or nil)
				if made and a then
					a:Hide()
					f.impact = a
					break
				end
			end
		else
			scene:Hide()
		end
	end

	-- In front of the creature: the client draws the models of a strata after its textures, so what
	-- must come over the creature (the sparks, the strike, the flash, the bands, the banner, the
	-- words) is in a strata above it.
	local top = CreateFrame("Frame", nil, f)
	top:SetAllPoints()
	top:SetFrameStrata("TOOLTIP")
	top:SetFrameLevel(50)
	f.layer = top

	-- sparks and embers, shock waves, the strike, the flash
	local fx = CreateFrame("Frame", nil, top)
	fx:SetAllPoints()
	fx:SetFrameLevel(top:GetFrameLevel() + 1)
	f.fx = fx
	self.embers = ns.Particles:New(fx, 160)
	self.sparks = ns.Particles:New(fx, 120)
	self.stars = ns.Particles:New(fx, 40, "Twinkle")
	f.rings = {}
	for i = 1, 6 do
		local r = Tex(fx, "OVERLAY", 2, "Ring", "ADD")
		r:SetAlpha(0)
		f.rings[i] = r
	end
	-- the strike: a wash of its colour, the power at the edges of the screen, its marks in the middle,
	-- the ball of a spell and its halo
	f.wash = Tex(fx, "ARTWORK", 0)
	f.wash:SetAllPoints(f)
	CuratorOctoFull.ColorTexture(f.wash, 1, 1, 1, 1)
	f.wash:SetBlendMode("ADD")
	f.wash:SetAlpha(0)
	f.edge = Tex(fx, "ARTWORK", 1, "StrikeBurn", "ADD")
	f.edge:SetAllPoints(f)
	f.edge:SetAlpha(0)
	f.marks = {}
	for i = 1, 2 do
		local t = Tex(fx, "ARTWORK", 3, "StrikeSlash", "ADD")
		t:SetAlpha(0)
		f.marks[i] = t
	end
	f.orb = Tex(fx, "OVERLAY", 3, "StrikeOrb", "ADD")
	f.orb:SetAlpha(0)
	f.halo = Tex(fx, "OVERLAY", 4, "StrikeOrb", "ADD")
	f.halo:SetAlpha(0)
	f.flash = Tex(fx, "OVERLAY", 7)
	f.flash:SetAllPoints(f)
	CuratorOctoFull.ColorTexture(f.flash, 1, 1, 1, 1)
	f.flash:SetAlpha(0)

	-- the black bands of the cinema, the words of the creature, the line that says how to skip
	local bars = CreateFrame("Frame", nil, top)
	bars:SetAllPoints()
	bars:SetFrameLevel(top:GetFrameLevel() + 5)
	f.top = Tex(bars, "ARTWORK", 0)
	CuratorOctoFull.ColorTexture(f.top, 0, 0, 0, 1)
	f.bottom = Tex(bars, "ARTWORK", 0)
	CuratorOctoFull.ColorTexture(f.bottom, 0, 0, 0, 1)
	f.skip = S.Text(bars, "GameFontDisableSmall", "RIGHT")
	f.skip:SetPoint("BOTTOMRIGHT", -28, 18)
	f.skip:SetText(L["Click to skip"])
	f.words = S.Text(bars, "GameFontHighlightLarge", "CENTER")
	-- (large, as the words of a cinematic of the game)
	ns.SetFont(f.words, 20, "")
	f.words:SetShadowColor(0, 0, 0, 1)
	f.words:SetShadowOffset(1, -1)
	CuratorOctoFull.SetWordWrap(f.words, true)
	f.words:SetAlpha(0)

	-- (1.12.0) the black before the entrance, over the creature; the line of the creature written on it, its name
	-- over it
	local vf = CreateFrame("Frame", nil, top)
	vf:SetAllPoints()
	vf:SetFrameLevel(top:GetFrameLevel() + 3)
	f.veil = Tex(vf, "BACKGROUND", 0)
	f.veil:SetAllPoints(f)
	CuratorOctoFull.ColorTexture(f.veil, 0, 0, 0, 1)
	f.veil:SetAlpha(0)
	f.sayName = bars:CreateFontString(nil, "OVERLAY")
	ns.SetFont(f.sayName, 15, "")
	f.sayName:SetShadowColor(0, 0, 0, 1)
	f.sayName:SetShadowOffset(1, -1)
	f.sayName:SetAlpha(0)
	f.say = bars:CreateFontString(nil, "OVERLAY")
	f.say:SetJustifyH("LEFT")
	f.say:SetJustifyV("TOP")
	CuratorOctoFull.SetWordWrap(f.say, false)
	f.say:SetShadowColor(0, 0, 0, 1)
	f.say:SetShadowOffset(2, -2)
	f.say:SetAlpha(0)
	f.sayMeasure = bars:CreateFontString(nil, "OVERLAY")
	CuratorOctoFull.SetWordWrap(f.sayMeasure, false)
	f.sayMeasure:SetAlpha(0)

	-- the banner of the name
	local tf = CreateFrame("Frame", nil, top)
	tf:SetAllPoints()
	tf:SetFrameLevel(top:GetFrameLevel() + 10)
	f.banner = BuildBanner(tf)

	CuratorOctoFull.SetScript(f, "OnMouseUp", function()
		if Cin.playing and (Cin.t or 0) > 0.4 then
			Cin:Skip()
		end
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		Cin:Tick(elapsed)
	end)
end

-------------------------------------------------------------------------------
-- Playing
-------------------------------------------------------------------------------
function Cin:Enabled()
	return not (ns.db and ns.db.cinematic == false)
end

function Cin:IsPlaying()
	return self.playing and true or false
end

-- The look of the creature: the shadow, or the light of the scene.
local function Unit(x, y, z)
	local l = math.sqrt(x * x + y * y + z * z)
	return x / l, y / l, z / l
end
function Cin:ApplyLook()
	local f = self.frame
	local m = f.model
	if f.scene then
		local sc, st, lit = f.scene, self.style, self.lit
		local t = st.tint
		sc:SetLightVisible(true)
		sc:SetLightType((Enum and Enum.ModelLightType and Enum.ModelLightType.Directional) or 0)
		if not lit then
			-- the shadow: no light on its face, only a light from behind and above that draws the
			-- edges of its head and shoulders in the colour of its rarity
			sc:SetLightDirection(Unit(0.75, 0, -0.66))
			sc:SetLightAmbientColor(t[1] * 0.05, t[2] * 0.05, t[3] * 0.05)
			sc:SetLightDiffuseColor(t[1], t[2], t[3])
		else
			local a = lit == "flash" and t or st.ambient
			local ai = lit == "flash" and 0.9 or st.ambientI
			local d, di = st.diffuse, math.min(1, st.diffuseI)
			-- from the front, a little from the left and from above
			sc:SetLightDirection(Unit(-1, 0.45, -0.55))
			sc:SetLightAmbientColor(a[1] * ai, a[2] * ai, a[3] * ai)
			sc:SetLightDiffuseColor(d[1] * di, d[2] * di, d[3] * di)
		end
		-- (the model frame only answers the animations: no light, no sparkles of its own)
		local black = Light(st, false)
		if black then
			black.diffuseIntensity = 0
			CuratorOctoFull.SetLight(m, true, black)
		end
		CuratorOctoFull.SetParticlesEnabled(m, false)
		return
	end
	local light = Light(self.style, self.lit)
	if light then
		CuratorOctoFull.SetLight(m, true, light)
	end
	CuratorOctoFull.SetParticlesEnabled(m, self.role ~= nil or (self.lit ~= nil and self.lit ~= false))
	CuratorOctoFull.SetPaused(m, false)
end

function Cin:SetLit(on)
	self.lit = on
	if self.frame.scene or self.frame.model.loaded then
		self:ApplyLook()
	end
end

-- Animation: the first one of the list the model has (once it is there).
function Cin:Animate(list, back, after)
	local m, actor = self.frame.model, self.frame.actor
	local function go()
		for _, a in ipairs(list) do
			local _, a = _, a; local ok, has = pcall(m.HasAnimation, m, a)
			if ok and has then
				if actor then
					actor:SetAnimation(a, 0, 1)
				else
					m:SetAnimation(a)
				end
				self.anim = a
				if self.animBack then
					ns.CancelTween(self.animBack)
					self.animBack = nil
				end
				if back then
					self.animBack = ns.Delay(after or 1.9, function()
						self.animBack = nil
						self:Animate(back)
					end, self)
				end
				return
			end
		end
	end
	if m.loaded then
		go()
	else
		m.pending = go
	end
end

-- The camera: portrait zoom (1: the face), distance (1: the creature whole), facing; a move to
-- target values over dur seconds. The facing also drifts slowly (spin, radians per second).
-- (each value has its move: a new move of one does not stop the others)
function Cin:CamTo(dur, to, ease)
	local cam = self.cam
	cam.tw = cam.tw or {}
	for k, v in pairs(to) do
		local k, v = k, v; if cam.tw[k] then
			ns.CancelTween(cam.tw[k])
		end
		local from = cam[k]
		cam.tw[k] = ns.Tween(dur, function(e)
			cam[k] = from + (v - from) * e
		end, nil, ease or Ease.inOutCubic, self)
	end
end

function Cin:Fade(region, to, dur, ease, delay)
	local from = region:GetAlpha()
	if region.tw then
		ns.CancelTween(region.tw)
	end
	local tw
	tw = ns.Tween(dur, function(e)
		region:SetAlpha(from + (to - from) * e)
	end, function()
		if region.tw == tw then
			region.tw = nil
		end
	end, ease or Ease.outQuad, self, delay)
	region.tw = tw
end

function Cin:Flash(color, peak, dur, delay)
	local fl = self.frame.flash
	fl:SetVertexColor(color[1], color[2], color[3])
	ns.Tween(dur, function(_, raw)
		local a = raw < 0.12 and (raw / 0.12) or (1 - (raw - 0.12) / 0.88)
		fl:SetAlpha(peak * math.max(0, a))
	end, function()
		fl:SetAlpha(0)
	end, Ease.linear, self, delay)
end

function Cin:Ring(color, size, dur, alpha, delay, x, y)
	local f = self.frame
	for _, r in ipairs(f.rings) do
		local _, r = _, r; if not r.busy then
			r.busy = true
			r:ClearAllPoints()
			r:SetPoint("CENTER", f, "CENTER", x or 0, y or self.H * 0.06)
			r:SetVertexColor(color[1], color[2], color[3])
			CuratorOctoFull.SetSize(r, 1, 1)
			ns.Tween(dur, function(e, raw)
				local k = size * (0.12 + 0.88 * e)
				CuratorOctoFull.SetSize(r, k, k)
				r:SetAlpha(alpha * (1 - raw) * math.min(1, raw * 8))
			end, function()
				r:SetAlpha(0)
				r.busy = false
			end, Ease.outCubic, self, delay)
			return
		end
	end
end

-- A crackle of lightning behind the creature, in the colour of the mythic cards.
function Cin:Bolt(i, x, y, size, delay)
	local t = self.frame.bolts[i]
	local c = self.style.tint
	t:SetVertexColor(c[1], c[2] + 0.15, c[3] + 0.1)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.frame, "CENTER", x, y)
	CuratorOctoFull.SetSize(t, size, size)
	CuratorOctoFull.SetRotation(t, math.random() * 0.8 - 0.4)
	ns.Tween(0.32, function(_, raw)
		t:SetAlpha(raw < 0.2 and raw / 0.2 or (1 - (raw - 0.2) / 0.8))
	end, function()
		t:SetAlpha(0)
	end, Ease.linear, self, delay)
end

function Cin:Shake(seconds, amount)
	self.shakeT, self.shakeK = seconds, amount
end

-- Where the scene plays: over the whole screen, or over the small window of the boosters when the
-- booster opens there (at its size and scale: laid out as on a screen of that size, and cut to it).
function Cin:Place()
	local f = self.frame
	local B = ns.Booster
	-- (an entrance played again from the album or the chat: over the whole screen)
	local full = self.opts and self.opts.full
	local win = not full and B and B.Small and B:Small() and B.frame and B.frame:IsShown() and B.frame or nil
	f:ClearAllPoints()
	if win then
		f:SetScale(win:GetScale())
		CuratorOctoFull.SetSize(f, win:GetWidth(), win:GetHeight())
		f:SetPoint("CENTER", win, "CENTER", 0, 0)
	else
		f:SetScale(1)
		CuratorOctoFull.SetSize(f, UIParent:GetWidth(), UIParent:GetHeight())
		f:SetAllPoints(UIParent)
	end
	if f.SetClipsChildren then
		CuratorOctoFull.SetClipsChildren(f, win ~= nil and f.scene ~= nil)
	end
	self.small = win ~= nil
	-- (the line that says how to skip: as large as the buttons of the small window)
	local ui = win and (B.uiK or 1) or 1
	if f.skip.SetScale then
		f.skip:SetScale(ui)
	else
		ui = 1
	end
	f.skip:ClearAllPoints()
	f.skip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28 / ui, 18 / ui)
end

-- Lays the scene out on the screen (its size can change between two cards).
function Cin:Layout()
	local f = self.frame
	local W, H = f:GetWidth(), f:GetHeight()
	if not W or W <= 0 or not H or H <= 0 then
		W, H = 1920, 1080
	end
	self.W, self.H = W, H
	local band = H * BAR
	CuratorOctoFull.SetSize(f.top, W, band)
	CuratorOctoFull.SetSize(f.bottom, W, band)
	f.backdrop:SetAllPoints(f.stage)
	f.tint:SetAllPoints(f.backdrop)
	f.shade:SetAllPoints(f.backdrop)
	CuratorOctoFull.SetSize(f.floor, W * 0.85, H * 0.32)
	f.floor:SetPoint("CENTER", f.stage, "CENTER", 0, -H * 0.27)
	CuratorOctoFull.SetSize(f.rays, H * 1.15, H * 1.15)
	f.rays:SetPoint("CENTER", f.stage, "CENTER", 0, H * 0.06)
	CuratorOctoFull.SetSize(f.rays2, H * 1.5, H * 1.5)
	f.rays2:SetPoint("CENTER", f.stage, "CENTER", 0, H * 0.06)
	-- the creature: a scene as large as the screen (its edges never cut it); the model frame that
	-- answers the animations, tiny, under the lower band. (Without a scene: the model frame as
	-- large as the screen, its distances made longer by the ratio of the diagonals.)
	local m = f.model
	m:ClearAllPoints()
	if f.scene then
		f.scene:ClearAllPoints()
		CuratorOctoFull.SetSize(f.scene, W, H)
		f.scene:SetPoint("CENTER", f.stage, "CENTER", 0, H * 0.035)
		CuratorOctoFull.SetSize(m, 24, 24)
		m:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 6)
	else
		CuratorOctoFull.SetSize(m, W, H)
		m:SetPoint("CENTER", f.stage, "CENTER", 0, H * 0.035)
	end
	self.camK = math.sqrt(1 + (W / H) ^ 2) / CARD_DIAG
	f.words:ClearAllPoints()
	f.words:SetPoint("CENTER", f, "BOTTOM", 0, band * 0.52)
	f.words:SetWidth(W * 0.72)
	local b = f.banner
	b:SetScale(1.15)
	b:ClearAllPoints()
	b:SetPoint("CENTER", f, "CENTER", 0, -H * 0.335 / 1.15)
	-- the photo of the place is twice as wide as tall: the part that matches the screen
	local screen = W / H
	if screen < 2 then
		local u = screen / 2
		self.crop = { 0.5 - u / 2, 0.5 + u / 2, 0, 1 }
	else
		local v = 2 / screen
		self.crop = { 0, 1, 0.5 - v / 2, 0.5 + v / 2 }
	end
end

-- The banner comes as the one of the bosses: the skull (or the gem) first, then the banner opens
-- from its middle, the side ornaments slide out, the texts appear, a glow runs over it.
function Cin:ShowBanner()
	local b = self.frame.banner
	local mythic = self.style.skull
	local col = ns.RARITY[self.card.rarity]
	FitFont(b.title, b.legacy and "GameFontNormalHuge" or "QuestFont_Enormous", C:Name(self.card), 410, 30, 18)
	b.title:SetTextColor(1, 0.82, 0.1)
	local sub = L[col.label]
	local f = C:FinishName(self.card, self.opts.finish)
	if f then
		sub = sub .. "  ·  " .. f
	end
	b.sub:SetText(sub)
	b.sub:SetTextColor(col.text[1], col.text[2], col.text[3])
	local line = C:TypeLine(self.card)
	local where = C:SeriesName(self.card.series)
	b.line:SetText((line ~= "" and (line .. "  ·  ") or "") .. where)
	local glow = self.style.tint
	if b.legacy then
		CuratorOctoFull.ColorTexture(b.trim, glow[1], glow[2], glow[3], 0.85)
		b.gem:SetTexture(MEDIA .. "Gem" .. self.card.rarity)
		b:SetAlpha(0)
		b:Show()
		self:Fade(b, 1, 0.28)
		return
	end
	for _, t in ipairs({ b.topGlow, b.bottomGlow, b.midGlow }) do
		t:SetVertexColor(glow[1], glow[2], glow[3])
	end
	-- (a client without the art of the bosses shows the gem of the rarity alone, even for a mythic card)
	local skull = mythic and not b.skull.missing
	CuratorOctoFull.SetShown(b.skull, skull)
	CuratorOctoFull.SetShown(b.spikes, skull and not b.spikes.missing)
	CuratorOctoFull.SetShown(b.flash, skull and not b.flash.missing)
	CuratorOctoFull.SetShown(b.gem, not skull)
	CuratorOctoFull.SetShown(b.ring, not mythic and not b.ring.missing)
	b.gem:SetTexture(MEDIA .. "Gem" .. self.card.rarity)
	b:SetAlpha(1)
	b:Show()
	local center = skull and b.skull or b.ring
	center:SetAlpha(0)
	-- the circle drops in, five times its size
	ns.Tween(0.15, function(e)
		local k = 5 - 4 * e
		CuratorOctoFull.SetSize(center, 44 * k, 44 * k)
		center:SetAlpha(math.min(1, e * 1.5))
		if not skull then
			CuratorOctoFull.SetSize(b.gem, 30 * k, 30 * k)
			b.gem:SetAlpha(math.min(1, e * 1.5))
		end
	end, nil, Ease.linear, self)
	if skull then
		b.spikes:SetAlpha(0)
		self:Fade(b.spikes, 1, 0.1, nil, 0.1)
		-- the red flash and the lightning on the skull
		ns.Tween(0.75, function(_, raw)
			local k = raw < 0.33 and (2.5 - 1.5 * raw / 0.33) or 1
			CuratorOctoFull.SetSize(b.flash, 92 * k, 92 * k)
			b.flash:SetAlpha(raw < 0.33 and 1 or (1 - (raw - 0.33) / 0.67))
		end, function()
			b.flash:SetAlpha(0)
		end, Ease.linear, self)
		for i, t in ipairs(b.bolts) do
			local i, t = i, t; ns.Tween(0.5, function(_, raw)
				t:SetAlpha(raw < 0.4 and raw / 0.4 or (1 - (raw - 0.4) / 0.6))
				local k = 1 + 0.25 * raw
				CuratorOctoFull.SetSize(t, 122 * k, 118 * 0.75)
			end, function()
				t:SetAlpha(0)
			end, Ease.linear, self, 0.25 + i * 0.02)
		end
	end
	-- the banner opens from its middle (the middle piece follows the top and the bottom)
	for _, t in ipairs({ b.top, b.bottom, b.mid }) do
		local _, t = _, t; t:SetAlpha(0)
		ns.Tween(0.3, function(e)
			if t ~= b.mid then
				t:SetWidth(440 * (0.1 + 0.9 * e))
			end
			t:SetAlpha(math.min(1, e * 1.4))
		end, nil, Ease.outCubic, self, 0.1)
	end
	b.bottomFill:SetAlpha(0)
	self:Fade(b.bottomFill, 1, 0.15)
	-- the ornaments slide out of the circle
	for side, t in pairs({ [-1] = b.left, [1] = b.right }) do
		local side, t = side, t; t:SetAlpha(0)
		ns.Tween(0.3, function(e)
			t:ClearAllPoints()
			t:SetPoint("CENTER", center, "CENTER", side * (10 + 37 * e), 6)
			t:SetAlpha(math.min(1, e * 3))
		end, nil, Ease.outQuad, self)
	end
	for _, fs in ipairs({ b.title, b.sub, b.line }) do
		fs:SetAlpha(0)
	end
	self:Fade(b.title, 1, 0.25, nil, 0.2)
	self:Fade(b.sub, 1, 0.25, nil, 0.35)
	self:Fade(b.line, 1, 0.25, nil, 0.5)
	-- a glow runs over the banner
	for _, t in ipairs({ b.topGlow, b.bottomGlow, b.midGlow }) do
		local _, t = _, t; ns.Tween(1.1, function(_, raw)
			if t ~= b.midGlow then
				t:SetWidth(440 * (0.5 + 1.1 * math.min(1, raw / 0.45)))
			end
			t:SetAlpha(raw < 0.2 and raw / 0.2 or math.max(0, 1 - (raw - 0.2) / 0.8))
		end, function()
			t:SetAlpha(0)
		end, Ease.linear, self, 0.9)
	end
end

-- Plays the entrance of a card (rarity 5 or 6). opts: finish. onReveal() runs under the last flash
-- (the card is turned over there), onDone() once the scene is gone. False if it cannot play.
function Cin:Play(card, opts, onReveal, onDone)
	if self.playing or not card or card.rarity < 5 then
		return false
	end
	-- (1.13.0, the Hardcup Saison 3: a card of a picture has no creature to make its entrance)
	if card.art and card.art.fill then
		return false
	end
	self:Build()
	local f = self.frame
	if not (card.display and card.display > 0 and (f.scene or (f.model.SetDisplayInfo and f.model.SetAnimation))) then return false end
	ns.CancelOwner(self)
	self:HideCards()
	self.card, self.opts, self.onReveal, self.onDone = card, opts or {}, onReveal, onDone
	self.style = STYLE[card.rarity] or STYLE[5]
	self.kind = card.friendly and ANIM.character or ANIM.creature
	self.role = Role(card)
	self.auraOn = false
	self.playing, self.t, self.revealed = true, 0, false
	self.shakeT, self.spin, self.emberT = 0, 0, 0
	self.cam = { zoom = CAM.dark.zoom, dist = CAM.dark.dist, rot = 0.15 }
	self.lit = false
	self.phase = "dark"
	local st = self.style
	f:SetAlpha(1)
	-- (over the whole screen, or over the small window of the boosters)
	self:Place()
	f:Show()
	self:Layout()

	-- what is shown at first: black, and the bands coming in
	f.curtain:SetAlpha(0)
	self:Fade(f.curtain, 1, 0.35)
	local band = self.H * BAR
	ns.Tween(0.5, function(e)
		f.top:ClearAllPoints()
		f.top:SetPoint("BOTTOM", f, "TOP", 0, -band * e)
		f.bottom:ClearAllPoints()
		f.bottom:SetPoint("TOP", f, "BOTTOM", 0, band * e)
	end, nil, Ease.outCubic, self)
	f.skip:SetAlpha(0)
	self:Fade(f.skip, 1, 0.4, nil, 0.8)
	local s = card.series or {}
	f.backdrop:SetTexture(MEDIA .. (s.studio or "StudioElwynn"))
	f.backdrop:SetTexCoord(unpack(self.crop))
	f.backdrop:SetVertexColor(0.5, 0.5, 0.55)
	f.backdrop:SetAlpha(0)
	f.tint:SetVertexColor(st.tint[1], st.tint[2], st.tint[3])
	f.tint:SetAlpha(0)
	f.shade:SetAlpha(1)
	f.floor:SetVertexColor(st.tint[1], st.tint[2], st.tint[3])
	f.floor:SetAlpha(0)
	f.rays:SetVertexColor(st.tint[1], st.tint[2], st.tint[3])
	f.rays:SetAlpha(0)
	f.rays2:SetVertexColor(1, 0.78, 0.36)
	f.rays2:SetAlpha(0)
	f.banner:Hide()
	for _, r in ipairs(f.rings) do
		r:SetAlpha(0)
		r.busy = false
	end
	self:ClearStrike()

	-- the creature, in the shadow, drawn at once: the dark hides it. (Its alpha is never touched: a
	-- model whose alpha was changed stays undrawn in the client until the alpha of its frame changes.)
	local m = f.model
	m.loaded, m.pending = false, nil
	m:Show()
	m:ClearModel()
	local loaded = false
	if m.SetDisplayInfo then
		local ok, result = pcall(m.SetDisplayInfo, m, card.display)
		loaded = ok and result ~= false
	end
	if not loaded and not f.scene then
		self:Stop()
		return false
	end
	if not m.hasLoadScript then m.loaded = loaded end
	if loaded and m.SetAnimation then m:SetAnimation(0) end
	self.box, self.K, self.measured, self.measureTries, self.pose = nil, nil, false, 0, nil
	if f.scene then
		local actor = f.actor
		f.scene:Show()
		actor:ClearModel()
		actor:Show()
		actor:SetPosition(0, 0, 0)
		actor:SetYaw(self.cam.rot)
		if card.display and card.display > 0 then
			actor:SetModelByCreatureDisplayID(card.display)
		end
		actor:SetAnimation(0, 0, 1)
		pcall(f.scene.SetCameraFieldOfView, f.scene, FOV)
		-- (the invisible one that will carry the impact of its strike: shown from now on, so that its
		-- model is loaded when the strike comes)
		local imp = f.impact
		if imp then
			imp:Hide()
			imp:ClearModel()
			if self.role and self.role.imp > 0 then
				imp:SetPosition(0, 0, 0)
				imp:SetModelByCreatureDisplayID(STALKER)
				imp:Show()
			end
		end
	end
	self:ApplyLook()
	if not f.scene and m.loaded and not m.hasLoadScript then self:WearAura() end
	self.anim = 0

	-- the sounds of the creature: its cry, its roar, its blow (see Data/Cinematic.lua)
	local snd = (ns.CinematicSounds or {})[card.real or card.npc] or {}
	local cry = (snd[3] and snd[3] > 0) and snd[3] or card.sound
	if snd[3] == -1 then
		cry = nil
	end
	local roar, blow = snd[1], snd[2]
	local role = self.role
	local voice = role and role.line and role.line[1] and role.line[1] > 0
	if role and ns.db and ns.db.cinedebug then
		local a = f.actor or f.model
		ns.Print(string.format(("cinematic: %s: music %s, strike %s (%s), aura %d, gathering %d, release %d, impact %d, line %d, spell visuals %s"), 
			tostring(C:Name(card)), role.theme, role.strike, role.school, role.aura, role.pre and role.pre[1] or 0,
			role.cast and role.cast[1] or 0, role.imp, role.line and role.line[1] or 0,
			(a.SetSpellVisualKit or a.ApplySpellVisualKit) and "yes" or "no"))
	end

	-- (1.12.0) first the black, its line written there letter by letter with its voice (without a line: its cry in
	-- the dark); then its entrance (Cin:Begin)
	self.cue = {
		cry = ((not card.friendly or (role and snd[3] and snd[3] > 0)) and cry and cry > 0) and cry or nil,
		roar = roar, blow = blow, voice = voice,
	}
	self:Prologue()
	return true
end

-- (1.12.0) The black before the entrance: the line of the creature written in the middle of the screen letter by
-- letter while its voice says it, its name over it (only in the languages the game has its words in; in another, its
-- voice alone); a creature without a line: its cry in the dark, a line as such creatures say them written there
-- (Cliche). Then its entrance.
local LINE_HOLD = 1.0  -- (once written: a moment to read it, at least)
local LINE_MAX = 9     -- (whatever its voice: never longer)
local CLICHE_HOLD = 1.3 -- (a line without a voice: a moment more to read it)
function Cin:SoftSpokenVoice()
	if not (ns.db and ns.db.softSpokenMythic == true and self.card.rarity == 6) then return end
	local spoken = _G.Spoken
	local voices = _G.CuratorSoftSpokenVoices
	local voice = voices and voices[self.card.real or self.card.npc]
	if not (voice and spoken and spoken.IsCompatible and spoken:IsCompatible(1)
		and spoken.GetQueueSize and spoken:GetQueueSize() == 0
		and spoken.IsPaused and not spoken:IsPaused()) then
		return
	end
	return voice, spoken
end

function Cin:PlaySoftSpoken()
	local voice, spoken = self:SoftSpokenVoice()
	if not voice then return false end
	local source = spoken:GetSource("curator-mythic")
	if not source then
		source = spoken:RegisterSource("curator-mythic", {
			title = L["Mythic voices via SoftSpoken"], addon = "Curator", interClipGap = 0,
		})
	end
	if not source:CanPlay() then return false end
	local localized = (ns.locale == "frFR" and voice.frFR) or voice.enUS
	local recording = type(localized) == "table" and localized or voice
	local words = recording.text or localized
	if type(words) ~= "string" or type(recording.path) ~= "string"
		or type(recording.length) ~= "number" or recording.length <= 0 then return false end
	local clip = {
		key = "curator-mythic:" .. (self.card.real or self.card.npc),
		path = recording.path, length = recording.length,
		present = { header = C:Name(self.card), transcript = words, portrait = { kind = "none" } },
	}
	clip.startCallback = function()
		if self.spokenClip ~= clip then return end
		self.spokenActive = true
		self:TypeLine(words, 1)
		local line = self.line
		line.done, line.doneT, line.hold = true, 0, 0.2
		self.frame.say:SetText(table.concat(line.chars))
	end
	clip.stopCallback = function()
		if self.spokenClip == clip then self.spokenActive = nil end
	end
	self.spokenClip, self.spokenSource = clip, source
	local ok = pcall(source.Enqueue, source, clip)
	if ok and self.spokenActive then return true end
	self:StopSoftSpoken()
	return false
end

function Cin:StopSoftSpoken()
	local clip, source = self.spokenClip, self.spokenSource
	self.spokenClip, self.spokenSource, self.spokenActive = nil, nil, nil
	if clip then source:Remove(clip) end
end


function Cin:Prologue()
	local f = self.frame
	self.phase = "line"
	self.line, self.lineOver, self.t0 = nil, false, nil
	f.veil:SetAlpha(1)
	f.say:SetAlpha(0)
	f.sayName:SetAlpha(0)
	if self:SoftSpokenVoice() then
		ns.Delay(0.55, function()
			if not self:PlaySoftSpoken() then self:NativePrologue(0.55) end
		end, self)
	else
		self:NativePrologue(0)
	end
end

function Cin:NativePrologue(elapsed)
	local card, role, cue = self.card, self.role, self.cue or {}
	local line = role and role.line
	local text = line and LineText(card.real or card.npc, line)
	if cue.voice or text then
		ns.Delay(math.max(0, 0.55 - elapsed), function()
			if cue.voice then
				local ok, handle = ns.Play(line[1])
				self.voice = ok and handle or nil
			end
			self:TypeLine(text, line[2])
		end, self)
		return
	end
	-- (a creature without a line of its own: its cry in the dark, and one of the lines such creatures say written there)
	if cue.cry then
		ns.Delay(math.max(0, 0.45 - elapsed), function()
			ns.Play(cue.cry)
		end, self)
	end
	local cliche, chat = Cliche(card)
	if cliche then
		ns.Delay(math.max(0, 0.6 - elapsed), function()
			self:TypeLine(cliche, chat)
			if self.line then
				self.line.hold = CLICHE_HOLD
			end
		end, self)
		return
	end
	local wait = 0.75
	if cue.cry then
		wait = card.rarity >= 6 and 1.95 or 1.65
	end
	ns.Delay(math.max(0, wait - elapsed), function()
		self:Begin()
	end, self)
end

-- The line written in the black (nil: its voice alone, for its time).
local SIGNS = { koKR = true, zhCN = true, zhTW = true }
function Cin:TypeLine(text, chatType)
	local f, card = self.frame, self.card
	local ln = { t = 0, n = 0, chars = {}, shown = "" }
	self.line = ln
	if not text then
		ln.done, ln.doneT, ln.hold = true, 0, 2.4
		return
	end
	local chat = CHAT[chatType or 1] or CHAT[1]
	local name = C:Name(card)
	local words, named = text, chat[2] ~= nil
	if not named then
		-- (an emote carries the name in its text)
		if string.find(text, "%%s") then
			words = string.gsub(text, "%%s", function()
				return name
			end)
		else
			words = name .. " " .. text
		end
	end
	local info = ChatTypeInfo and ChatTypeInfo[chat[1]]
	local c = (info and info.r) and { info.r, info.g, info.b } or chat[3]
	local W, H = self.W or 1920, self.H or 1080
	local size = math.max(16, math.min(30, math.floor(H * 0.028 + 0.5)))
	ns.SetFont(f.say, size, "")
	ns.SetFont(f.sayMeasure, size, "")
	-- (its lines broken once: the words never move while the letters come)
	local maxW = W * 0.6
	local lines, cur = {}, nil
	for word in CuratorOctoFull.Gmatch(words, "%S+") do
		local try = cur and (cur .. " " .. word) or word
		f.sayMeasure:SetText(try)
		if cur and (f.sayMeasure:GetStringWidth() or 0) > maxW then
			lines[CuratorOctoFull.Length(lines) + 1] = cur
			cur = word
		else
			cur = try
		end
	end
	lines[CuratorOctoFull.Length(lines) + 1] = cur or ""
	local widest = 0
	for _, l in ipairs(lines) do
		f.sayMeasure:SetText(l)
		widest = math.max(widest, f.sayMeasure:GetStringWidth() or 0)
	end
	f.sayMeasure:SetText("")
	for ch in CuratorOctoFull.Gmatch(table.concat(lines, "\n"), "[%z\1-\127\194-\244][\128-\191]*") do
		ln.chars[CuratorOctoFull.Length(ln.chars) + 1] = ch
	end
	local gap = math.floor(size * 0.3)
	local tall = CuratorOctoFull.Length(lines) * size + (CuratorOctoFull.Length(lines) - 1) * gap
	f.say:SetSpacing(gap)
	CuratorOctoFull.SetSize(f.say, math.ceil(widest) + 10, tall + 10)
	f.say:ClearAllPoints()
	f.say:SetPoint("TOP", f, "CENTER", 0, tall / 2 + H * 0.02)
	f.say:SetTextColor(c[1], c[2], c[3])
	f.say:SetText("")
	f.say:SetAlpha(1)
	CuratorOctoFull.SetShown(f.sayName, named)
	if named then
		ns.SetFont(f.sayName, math.max(13, math.floor(size * 0.62)), "")
		f.sayName:SetText(name)
		f.sayName:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
		f.sayName:ClearAllPoints()
		f.sayName:SetPoint("BOTTOM", f, "CENTER", 0, tall / 2 + H * 0.02 + size * 0.7)
		self:Fade(f.sayName, 0.92, 0.45)
	end
	-- (letters a second: those of an alphabet, those of signs)
	ln.rate = SIGNS[ns.locale or "enUS"] and 7 or 17
	ln.hold = LINE_HOLD
end

-- Every frame of the black: one more letter (or a few); once written, it waits for the voice to end.
function Cin:LineTick(elapsed)
	local ln = self.line
	if not ln or self.lineOver then
		return
	end
	ln.t = ln.t + elapsed
	if not ln.done then
		local n = math.min(CuratorOctoFull.Length(ln.chars), math.floor(ln.t * ln.rate))
		if n > ln.n then
			for i = ln.n + 1, n do
				ln.shown = ln.shown .. ln.chars[i]
			end
			ln.n = n
			self.frame.say:SetText(ln.shown)
		end
		if n >= CuratorOctoFull.Length(ln.chars) then
			ln.done, ln.doneT = true, ln.t
		end
		return
	end
	local speaking = self.spokenActive == true
	if self.voice and C_Sound and C_Sound.IsPlaying then
		local ok, on = pcall(C_Sound.IsPlaying, self.voice)
		speaking = ok and on == true
	end
	local limit = self.spokenClip and math.max(LINE_MAX, self.spokenClip.length + 1) or LINE_MAX
	if (not speaking and ln.t - (ln.doneT or 0) >= (ln.hold or LINE_HOLD)) or ln.t > limit then
		self:EndLine()
	end
end

-- The line said: it fades, the black lifts on the entrance.
function Cin:EndLine()
	if self.lineOver then
		return
	end
	self.lineOver = true
	self:StopSoftSpoken()
	local f = self.frame
	self:Fade(f.say, 0, 0.35)
	if f.sayName:GetAlpha() > 0 then
		self:Fade(f.sayName, 0, 0.35)
	end
	ns.Delay(0.4, function()
		self:Begin()
	end, self)
end

-- The entrance, after the black: the screen dark, the creature in the shadow; the light falls on it as it roars;
-- its strike at you, its name. (The moments of the entrance count from its beginning: Cin.t0.)
function Cin:Begin()
	if not self.playing or self.t0 then
		return
	end
	local f, card, role, st = self.frame, self.card, self.role, self.style
	local s = card.series or {}
	local cue = self.cue or {}
	local roar, blow = cue.roar, cue.blow
	self.lineOver = true
	self.phase = "dark"
	self.t0 = self.t
	self:Fade(f.veil, 0, 0.7)
	local open = st.open
	if card.rarity >= 6 and s.side == "H" then
		open = { 6595, 6594, 1485 }
	end
	ns.Play(open)
	ns.Delay(0.15, function()
		local ok, handle = ns.Play(Music(card, role))
		self.music = ok and handle or nil
	end, self)
	local dark = card.rarity >= 6 and 0.45 or 0.3
	ns.Delay(dark, function()
		-- (darker and redder before a mythic card)
		self:Fade(f.backdrop, card.rarity >= 6 and 0.3 or 0.42, 0.9)
		self:Fade(f.tint, card.rarity >= 6 and 0.2 or 0.12, 0.9)
		self:Fade(f.floor, 0.35, 1.2)
		self:Fade(f.rays, 0.22, 1.2)
		self:CamTo(st.impact - dark, { zoom = CAM.darkTo.zoom, dist = CAM.darkTo.dist, rot = 0 }, Ease.linear)
	end, self)
	if card.rarity >= 6 then
		-- the red lightning: the creature seen for an instant
		for k, at in ipairs({ 1.1, 2.0 }) do
			local k, at = k, at; ns.Delay(at, function()
				ns.Play({ 4936, 1483 })
				self:Flash({ 1, 0.35, 0.35 }, k == 1 and 0.45 or 0.3, 0.3)
				self:SetLit("flash")
				ns.Delay(0.12, function()
					if self.phase == "dark" then
						self:SetLit(false)
					end
				end, self)
				for i = 1, 2 do
					local x = (i == 1 and -1 or 1) * self.W * (0.12 + math.random() * 0.16)
					local y = self.H * (0.08 + math.random() * 0.2)
					self:Bolt(i + (k - 1) * 2, x, y, self.H * (0.24 + math.random() * 0.12), (i - 1) * 0.06)
				end
			end, self)
		end
		ns.Delay(2.25, function()
			ns.Play(open)
		end, self)
	end

	-- the light falls on it: it roars, the camera pulls back
	ns.Delay(st.impact, function()
		self.phase = "lit"
		self:SetLit(true)
		ns.Play(st.impactSnd)
		-- its roar (a character: its greeting); its line was said in the black, before
		if card.friendly then
			if card.sound and card.sound > 0 then
				ns.Play(card.sound)
			end
		elseif roar and roar > 0 then
			ns.Play(roar)
		end
		local col = st.tint
		self:Flash({ 1, 0.92, 0.8 }, card.rarity >= 6 and 0.95 or 0.85, 0.8)
		self:CamTo(0.8, { zoom = CAM.lit.zoom, dist = CAM.lit.dist, rot = 0.5 }, Ease.outCubic)
		self:Fade(f.backdrop, 0.62, 0.6)
		self:Fade(f.tint, 0.2, 0.6)
		self:Fade(f.floor, 0.7, 0.4)
		f.rays:SetAlpha(1)
		self:Fade(f.rays, 0.55, 1.6, nil, 0.3)
		if st.rays2 then
			f.rays2:SetAlpha(0.8)
			self:Fade(f.rays2, 0.4, 1.6, nil, 0.3)
		end
		self:Shake(card.rarity >= 6 and 0.75 or 0.45, card.rarity >= 6 and 10 or 7)
		self:Ring(col, self.H * 0.9, 0.8, 0.8)
		self:Ring({ 1, 0.92, 0.75 }, self.H * 1.15, 1.0, 0.55, 0.12)
		local cy = self.H * 0.06
		self.sparks:Burst(0, cy, col, 50, self.H * 0.42, 1.4, 30)
		ns.Delay(0.2, function()
			self.sparks:Burst(0, cy, { 1, 0.9, 0.65 }, 30, self.H * 0.3, 1.2, 22)
		end, self)
		self.stars:Burst(0, cy, { 1, 0.95, 0.8 }, 16, self.H * 0.35, 1.5, 28)
		if card.rarity >= 6 then
			self:Ring(st.rays2, self.H * 1.35, 1.2, 0.45, 0.25)
			ns.Delay(0.45, function()
				self.sparks:Burst(0, cy, col, 30, self.H * 0.25, 1.2, 20)
			end, self)
		end
		local waves = FINISH_WAVES[C:FinishLook(card, self.opts.finish)]
		if waves then
			-- waves of lightning (thunderforged), of all the colours of a prism (titanforged)
			for k, rc in ipairs(waves) do
				local k, rc = k, rc; self:Ring(rc, self.H * (0.5 + 0.1 * k), 0.9, 0.4, 0.3 + 0.07 * k)
				ns.Delay(0.3 + 0.06 * k, function()
					self.stars:Burst(0, cy, rc, 4, self.H * 0.3, 1.3, 24)
				end, self)
			end
		end
		self:Animate(self.kind.roar, self.kind.stance, card.friendly and 2.4 or 2.0)
	end, self)

	if role then
		-- it turns to you, gathers its power and strikes at you; then its name on the banner of the
		-- bosses, while it turns slowly
		local def = STRIKE[role.strike]
		local s0 = st.impact + AFTER
		local hit = s0 + GATHER + def.travel
		local title = hit + 0.5
		local exit = title + (card.rarity >= 6 and 1.85 or 1.7)
		ns.Delay(s0, function()
			self:Gather()
		end, self)
		ns.Delay(s0 + GATHER, function()
			self:Release()
		end, self)
		ns.Delay(hit, function()
			self:Hit()
		end, self)
		ns.Delay(title, function()
			self:Title(exit - title)
		end, self)
		ns.Delay(exit, function()
			self:Exit()
		end, self)
		return true
	end

	-- its name on the banner of the bosses, the creature turns slowly
	ns.Delay(st.title, function()
		self:Title(st.exit - st.title)
	end, self)
	ns.Delay(st.beat, function()
		self:Animate(self.kind.blow, self.kind.stance, 1.6)
		if not card.friendly and blow and blow > 0 then
			ns.Delay(0.25, function()
				ns.Play(blow)
			end, self)
		end
		self:Shake(0.2, 4)
		self.sparks:Burst(0, self.H * 0.04, st.tint, 16, self.H * 0.2, 0.9, 18)
	end, self)
	ns.Delay(st.exit, function()
		self:Exit()
	end, self)
	return true
end

-- Its name on the banner of the bosses; the creature turns slowly until the end (dur seconds).
function Cin:Title(dur)
	local st = self.style
	self.phase = "title"
	ns.Play(st.titleSnd)
	local look = C:FinishLook(self.card, self.opts.finish)
	if look == "thunder" then
		ns.Play(ns.SND.thunder)
		ns.Play(ns.SND.thunderRoll)
	elseif look == "titan" then
		-- (1.11.0: the light of a prism, its crystal chime; the press of the forge of the titans before. 1.14.0, his
		-- word: the toast of a warforged item of the game, Core.lua: SND.titan)
		ns.Play(ns.SND.titan)
	end
	self:ShowBanner()
	self.spin = 0.11
	self:CamTo(dur, { dist = CAM.title.dist }, Ease.inOutCubic)
end

-------------------------------------------------------------------------------
-- The strike at you
-------------------------------------------------------------------------------
-- A spell visual kit on the creature (persistent, or played once).
function Cin:Kit(kit, oneShot)
	if not kit or kit <= 0 then
		return
	end
	local f = self.frame
	if f.scene then
		local a = f.actor
		if a.SetSpellVisualKit then
			pcall(a.SetSpellVisualKit, a, kit, oneShot and true or false)
		end
	elseif f.model.ApplySpellVisualKit then
		pcall(f.model.ApplySpellVisualKit, f.model, kit, oneShot and true or false)
	end
end

-- The light of its power, worn in the shadow (once the creature is there).
function Cin:WearAura()
	local r = self.role
	if r and r.aura > 0 and not self.auraOn and self.playing then
		self.auraOn = true
		self:Kit(r.aura, false)
	end
end

-- A point of the body of the creature on the screen (from the middle of the screen), at the share h
-- of its height (0: its feet, 1: the top of its head).
function Cin:BodyPoint(h)
	local b, pose = self.box, self.pose
	local want = FILL * self.H / math.max(0.2, self.cam.dist)
	if self.frame.scene and b and pose then
		local z = b.top - b.hz + b.hz * h
		return 0, self.H * 0.035 + (z - pose[3]) * want / pose[4]
	end
	return 0, self.H * 0.035 + (h - 0.5) * want
end

-- Everything of the strike put away.
function Cin:ClearStrike()
	local f = self.frame
	for _, t in ipairs({ f.wash, f.edge, f.orb, f.halo, f.words, f.marks[1], f.marks[2] }) do
		if t.tw then
			ns.CancelTween(t.tw)
			t.tw = nil
		end
		t:SetAlpha(0)
	end
	for _, k in ipairs({ "preSound", "castSound" }) do
		if self[k] and StopSound then
			StopSound(self[k], 150)
		end
		self[k] = nil
	end
end

-- A list of animations: the one of the spell first, then those of the way it strikes.
local function Anims(kit, list)
	local out = {}
	if kit and kit[2] and kit[2] > 0 then
		out[1] = kit[2]
	end
	for _, a in ipairs(list) do
		out[CuratorOctoFull.Length(out) + 1] = a
	end
	return out
end

-- It turns to you and gathers its power: the kit of the gathering on it, its animation and sound, the
-- light gathering in its hands (or in its mouth, before a breath), the camera.
function Cin:Gather()
	local f, r = self.frame, self.role
	local def = STRIKE[r.strike]
	local col = COLOUR[r.school]
	self.phase = "strike"
	self.spin = 0
	self:CamTo(0.35, { rot = 0 }, Ease.outCubic)
	self:CamTo(GATHER, { zoom = def.cam[1], dist = def.cam[2] }, Ease.inOutQuad)
	if r.pre then
		self:Kit(r.pre[1], false)
		local ok, handle = ns.Play(r.pre[3])
		self.preSound = ok and handle or nil
	end
	self:Animate(Anims(r.pre, def.pre))
	local melee = r.strike == "blow" or r.strike == "claw" or r.strike == "smash"
	local x, y = self:BodyPoint(r.strike == "breath" and 0.86 or (melee and 0.62 or 0.6))
	self.from = { x, y }
	local h = f.halo
	h:SetVertexColor(col[1], col[2], col[3])
	h:ClearAllPoints()
	h:SetPoint("CENTER", f, "CENTER", x, y)
	local peak = melee and 0.35 or 0.8
	ns.Tween(GATHER, function(e, raw)
		local k = self.H * (0.05 + 0.09 * e) * (1 + 0.12 * math.sin(raw * 30))
		CuratorOctoFull.SetSize(h, k, k)
		h:SetAlpha(peak * math.min(1, raw * 3))
	end, nil, Ease.outQuad, self)
	if not melee then
		self.sparks:Gather(x, y, col, 24, self.H * 0.26, 0.6, 14)
		ns.Delay(0.35, function()
			self.sparks:Gather(x, y, col, 18, self.H * 0.2, 0.45, 12)
		end, self)
	elseif r.strike == "smash" then
		self:Fade(f.floor, 0.95, GATHER)
	end
end

-- The release: the kit of the release on it, its animation and sound; what it throws comes at you.
function Cin:Release()
	local f, r = self.frame, self.role
	local def = STRIKE[r.strike]
	local col = COLOUR[r.school]
	if self.preSound and StopSound then
		StopSound(self.preSound, 150)
	end
	self.preSound = nil
	if r.cast then
		self:Kit(r.cast[1], true)
		local ok, handle = ns.Play(r.cast[3])
		self.castSound = ok and handle or nil
	end
	self:Animate(Anims(r.cast, def.cast), self.kind.stance, 1.5)
	self:Fade(f.halo, 0, 0.12)
	local x, y = self.from[1], self.from[2]
	local travel = def.travel
	if r.strike == "bolt" or r.strike == "beam" or r.strike == "bless" then
		-- the ball of the spell, from its hands to you, growing as it comes
		local o = f.orb
		o:SetVertexColor(col[1], col[2], col[3])
		local far = r.strike == "bless" and 1.2 or 2.6
		local peak = r.strike == "bless" and 0.6 or 1
		local spin = (math.random() - 0.5) * 6
		ns.Tween(travel, function(e, raw)
			o:ClearAllPoints()
			o:SetPoint("CENTER", f, "CENTER", x * (1 - e), y * (1 - e))
			local k = self.H * (0.08 + far * e)
			CuratorOctoFull.SetSize(o, k, k)
			o:SetAlpha(peak * math.min(1, raw * 6))
			CuratorOctoFull.SetRotation(o, spin * raw)
		end, nil, r.strike == "bless" and Ease.inOutQuad or Ease.inQuad, self)
		if r.strike == "beam" then
			self:Fade(f.wash, 0.3, travel, Ease.inQuad)
			f.wash:SetVertexColor(col[1], col[2], col[3])
		end
		self.sparks:Burst(x, y, col, 16, self.H * 0.12, 0.5, 14)
	elseif r.strike == "breath" then
		-- the breath fills the screen as it comes
		self:SetEdge(r)
		self:Fade(f.edge, 0.95, travel, Ease.inQuad)
		f.wash:SetVertexColor(col[1], col[2], col[3])
		self:Fade(f.wash, 0.28, travel, Ease.inQuad)
		for k = 0, 2 do
			local k = k; ns.Delay(k * 0.12, function()
				self.sparks:Burst(x, y, col, 22, self.H * 0.75, 0.55, 18, 0.8, 3.2)
			end, self)
		end
	elseif r.strike == "blow" or r.strike == "claw" then
		-- it rushes at you
		self:CamTo(travel, { dist = 0.62, zoom = 0.5 }, Ease.inQuad)
	elseif r.strike == "nova" then
		-- the wave spreads from it
		local cx, cy = self:BodyPoint(0.45)
		self:Ring(col, self.H * 2.6, travel + 0.45, 0.95, 0, cx, cy)
		self:Ring({ 1, 1, 1 }, self.H * 2.1, travel + 0.4, 0.5, 0.05, cx, cy)
		f.wash:SetVertexColor(col[1], col[2], col[3])
		self:Fade(f.wash, 0.22, travel, Ease.inQuad)
	elseif r.strike == "smash" then
		self:CamTo(travel, { dist = 1.62 }, Ease.inQuad)
	end
end

-- The edge of the screen in the power of the creature.
function Cin:SetEdge(r)
	local e = EDGE[r.school] or EDGE.physical
	local f = self.frame
	local col = COLOUR[r.school]
	f.edge:SetTexture(MEDIA .. e[1])
	f.edge:SetBlendMode(e[2])
	if r.school == "physical" then
		-- (dust)
		f.edge:SetVertexColor(0.5, 0.45, 0.38)
	else
		f.edge:SetVertexColor(col[1], col[2], col[3])
	end
end

-- A mark in the middle of the screen: texture, size, place, rotation, colour, blend.
local function Mark(t, file, w, h, x, y, rot, col, blend)
	t:SetTexture(MEDIA .. file)
	t:SetBlendMode(blend)
	t:SetVertexColor(col[1], col[2], col[3])
	t:ClearAllPoints()
	t:SetPoint("CENTER", t:GetParent(), "CENTER", x, y)
	CuratorOctoFull.SetSize(t, w, h)
	CuratorOctoFull.SetRotation(t, rot)
end

-- It reaches you: the flash, the marks on the screen, the shake, the impact of the spell in front of
-- you, its sound; then it stands back.
function Cin:Hit()
	local f, r = self.frame, self.role
	local def = STRIKE[r.strike]
	local col = COLOUR[r.school]
	local W, H = self.W, self.H
	ns.Play(r.hit)
	local light = { 0.55 + 0.45 * col[1], 0.55 + 0.45 * col[2], 0.55 + 0.45 * col[3] }
	local peak = ({ bolt = 0.65, beam = 0.7, breath = 0.4, blow = 0.5, claw = 0.45, smash = 0.5, nova = 0.55, bless = 0.3 })[r.strike]
	self:Flash(light, peak, 0.45)
	if def.shake > 0 then
		self:Shake(r.strike == "smash" and 0.8 or 0.5, def.shake)
	end
	self:Impact()
	local physical = r.school == "physical" or r.school == "blood"
	local m1, m2 = f.marks[1], f.marks[2]
	local function show(t, alpha, hold, fade, grow, delay)
		local w0, h0 = t:GetWidth(), t:GetHeight()
		t:SetAlpha(0)
		t.tw = ns.Tween(0.08 + hold + fade, function(_, raw)
			local el = raw * (0.08 + hold + fade)
			local a = el < 0.08 and el / 0.08 or (el < 0.08 + hold and 1 or 1 - (el - 0.08 - hold) / fade)
			t:SetAlpha(alpha * math.max(0, a))
			local k = 1 + (grow or 0) * raw
			CuratorOctoFull.SetSize(t, w0 * k, h0 * k)
		end, function()
			t:SetAlpha(0)
		end, Ease.linear, self, delay)
	end
	-- the edges of the screen, in its power (not after a blow of a weapon or of claws)
	if not (physical and (r.strike == "blow" or r.strike == "claw")) and r.strike ~= "bless" then
		if r.strike ~= "breath" then
			self:SetEdge(r)
		end
		local from = f.edge:GetAlpha()
		local top = (EDGE[r.school] or EDGE.physical)[3]
		if f.edge.tw then
			ns.CancelTween(f.edge.tw)
		end
		f.edge.tw = ns.Tween(1.4, function(_, raw)
			local a = raw < 0.08 and (from + (top - from) * raw / 0.08) or top * (1 - (raw - 0.08) / 0.92)
			f.edge:SetAlpha(math.max(0, a))
		end, function()
			f.edge:SetAlpha(0)
		end, Ease.linear, self)
	end
	if r.strike == "bolt" or r.strike == "beam" then
		-- the ball bursts on you
		local o = f.orb
		local k0 = o:GetWidth()
		o.tw = ns.Tween(0.5, function(e, raw)
			CuratorOctoFull.SetSize(o, k0 * (1 + 0.4 * e), k0 * (1 + 0.4 * e))
			o:SetAlpha(1 - raw)
		end, function()
			o:SetAlpha(0)
		end, Ease.outQuad, self)
		if f.wash:GetAlpha() > 0 then
			self:Fade(f.wash, 0, 0.8)
		end
		if r.school == "storm" then
			Mark(m1, "StrikeBolt", H * 1.25, H * 1.25, 0, 0, math.random() * 6.28, col, "ADD")
			show(m1, 1, 0.12, 0.5, 0.15)
		elseif r.school == "holy" or r.school == "arcane" then
			Mark(m1, "StrikeRunes", H * 0.95, H * 0.95, 0, 0, 0, col, "ADD")
			show(m1, 0.9, 0.25, 0.9, 0.25)
		end
	elseif r.strike == "breath" or r.strike == "nova" then
		self:Fade(f.wash, 0, 0.9, nil, 0.1)
	elseif r.strike == "blow" then
		local c = physical and { 1, 0.95, 0.9 } or col
		-- (square textures: the game turns them inside their square)
		Mark(m1, "StrikeSlash", W * 1.05, W * 1.05, 0, H * 0.02, -0.45, c, "ADD")
		show(m1, 1, 0.12, 0.55, 0.08)
		Mark(m2, "StrikeSlash", W * 0.9, W * 0.9, 0, -H * 0.04, 0.55, c, "ADD")
		show(m2, 0.85, 0.1, 0.5, 0.08, 0.09)
	elseif r.strike == "claw" then
		if physical then
			Mark(m1, "StrikeClaw", H * 0.95, H * 0.95, W * 0.04, 0, (math.random() - 0.5) * 0.4, { 0.75, 0.05, 0.05 }, "BLEND")
		else
			Mark(m1, "StrikeClaw", H * 0.95, H * 0.95, W * 0.04, 0, (math.random() - 0.5) * 0.4, col, "ADD")
		end
		show(m1, 0.95, 0.2, 0.7, 0.05)
	elseif r.strike == "smash" then
		local c = physical and { 1, 0.85, 0.65 } or col
		Mark(m1, "StrikeCracks", H * 1.3, H * 1.3, 0, -H * 0.5 + H * 0.65 - H * 0.02, 0, c, "ADD")
		show(m1, 0.95, 0.25, 0.8, 0.03)
		local fy = -H * 0.3
		self:Ring(c, H * 1.6, 0.7, 0.8, 0, 0, fy)
		self:Ring({ 1, 1, 1 }, H * 2.2, 0.9, 0.45, 0.08, 0, fy)
		self.sparks:Burst(0, fy, c, 30, H * 0.5, 0.9, 20, 0.6, 1.4)
	elseif r.strike == "bless" then
		Mark(m1, "StrikeRunes", H * 0.9, H * 0.9, 0, H * 0.02, 0, col, "ADD")
		show(m1, 0.85, 0.5, 1.2, 0.2)
		local o = f.orb
		o.tw = ns.Tween(1.2, function(_, raw)
			o:SetAlpha(0.6 * (1 - raw))
		end, function()
			o:SetAlpha(0)
		end, Ease.linear, self)
		f.wash:SetVertexColor(col[1], col[2], col[3])
		f.wash:SetAlpha(0.22)
		self:Fade(f.wash, 0, 1.4)
		self.stars:Burst(0, 0, col, 22, H * 0.45, 1.6, 26)
	end
	-- sparks flying past you
	if r.strike ~= "bless" then
		self.sparks:Burst(0, 0, col, 36, H * 0.7, 0.9, 22, 0.8, 2.6)
	end
	-- (a blow: the creature an instant behind the flash, the marks on the screen. An actor of a scene
	-- only: a model frame would lose its creature when hidden.)
	if (r.strike == "blow" or r.strike == "claw") and f.scene then
		local who = f.actor
		who:Hide()
		ns.Delay(0.1, function()
			if self.playing and self.phase ~= "out" then
				who:Show()
			end
		end, self)
	end
	-- it stands back (after a blow, from close to you), wearing its power again; the sound of its
	-- release fades
	ns.Delay((r.strike == "blow" or r.strike == "claw") and 0.16 or 0, function()
		self:CamTo(0.6, { zoom = 0, dist = CAM.lit.dist * 0.95 }, Ease.outCubic)
	end, self)
	ns.Delay(0.6, function()
		if self.castSound and StopSound then
			StopSound(self.castSound, 400)
		end
		self.castSound = nil
	end, self)
	ns.Delay(0.45, function()
		self.phase = "lit"
		if r.aura > 0 then
			self:Kit(r.aura, false)
		end
	end, self)
end

-- The impact of the spell in front of you: an invisible creature between the camera and the creature,
-- wearing the visual of the impact (a scene only; nothing if the client has not this visual).
function Cin:Impact()
	local f, r = self.frame, self.role
	local a = f.impact
	if not (a and r and r.imp > 0 and self.pose and self.K and a.SetSpellVisualKit) then
		return
	end
	local tx, ty, tz, d = self.pose[1], self.pose[2], self.pose[3], self.pose[5]
	local yaw, pitch = math.pi, PITCH
	local nx, ny, nz = math.cos(-pitch) * math.cos(yaw), math.cos(-pitch) * math.sin(yaw), math.sin(-pitch)
	-- a third of the way from the camera to the creature
	local e = d * 0.33
	pcall(a.SetPosition, a, tx - nx * (d - e), ty - ny * (d - e), tz - nz * (d - e))
	-- (the impacts of the game are about two yards high: made about half the height of the screen)
	pcall(a.SetScale, a, math.max(0.02, self.H * 0.5 * e / (self.K * 2)))
	a:Show()
	pcall(a.SetSpellVisualKit, a, r.imp, true)
end

-- The end: the banner goes, a flash, the card is turned over under it, the scene fades out.
function Cin:Exit(quick)
	if not self.playing or self.phase == "out" then
		return
	end
	self.phase = "out"
	self:StopSoftSpoken()
	local f = self.frame
	ns.CancelOwner(self)
	local b = f.banner
	if b:IsShown() then
		local from = b:GetAlpha()
		ns.Tween(quick and 0.15 or 0.35, function(e)
			b:SetAlpha(from * (1 - e))
		end, nil, Ease.outQuad, self)
	end
	local lead = quick and 0.05 or 0.15
	self:Flash({ 1, 0.96, 0.88 }, 1, 0.9, lead)
	ns.Delay(lead + 0.11, function()
		-- (the creature goes under the flash: it does not fade with the scene)
		f.model:Hide()
		if f.actor then
			f.actor:Hide()
		end
		self:Reveal()
		local from = f:GetAlpha()
		ns.Tween(0.55, function(e)
			f:SetAlpha(from * (1 - e))
		end, function()
			self:Finish()
		end, Ease.inQuad, self)
	end, self)
	if self.music and StopSound then
		StopSound(self.music, 2000)
		self.music = nil
	end
	if quick and self.voice and StopSound then
		StopSound(self.voice, 300)
		self.voice = nil
	end
	for _, k in ipairs({ "preSound", "castSound" }) do
		if self[k] and StopSound then
			StopSound(self[k], 200)
		end
		self[k] = nil
	end
	for _, w in ipairs({ f.words, f.say, f.sayName }) do
		if w:GetAlpha() > 0 then
			self:Fade(w, 0, 0.25)
		end
	end
	self.lineOver = true
end

-- The creatures of the cards on the screen: the client draws every model above the frames, even those
-- of a higher strata or level, so they would show through the scene. Hidden for its time; back (their
-- creature loaded again) under its last flash.
function Cin:HideCards()
	self:ShowCards()
	local hidden = {}
	for c in pairs(ns.AllCards or {}) do
		local m = c.model
		if m and m:IsShown() and m:IsVisible() then
			m:Hide()
			hidden[CuratorOctoFull.Length(hidden) + 1] = c
		end
	end
	self.hiddenCards = hidden
end

-- A card turned over while an entrance plays: its creature waits for the end of it too.
function Cin:HideCard(c)
	if self.playing and self.hiddenCards and c.model and c.model:IsShown() then
		c.model:Hide()
		CuratorOctoFull.Insert(self.hiddenCards, c)
	end
end

function Cin:ShowCards()
	local hidden = self.hiddenCards
	self.hiddenCards = nil
	for _, c in ipairs(hidden or {}) do
		c.model:Show()
		if c.front:IsShown() and c.model.display then
			c:ReloadModel()
		end
	end
end

function Cin:Reveal()
	self:ShowCards()
	if not self.revealed then
		self.revealed = true
		local fn = self.onReveal
		self.onReveal = nil
		if fn then
			fn()
		end
	end
end

function Cin:Finish()
	self:StopSoftSpoken()
	self:ShowCards()
	local f = self.frame
	f:Hide()
	f:SetAlpha(1)
	f.model:ClearModel()
	if f.actor then
		f.actor:ClearModel()
	end
	if f.impact then
		f.impact:Hide()
		f.impact:ClearModel()
	end
	self:ClearStrike()
	if self.voice and StopSound then
		StopSound(self.voice, 800)
	end
	self.voice, self.role = nil, nil
	-- (1.12.0: the black and its line)
	f.veil:SetAlpha(0)
	f.say:SetAlpha(0)
	f.sayName:SetAlpha(0)
	self.line, self.cue, self.t0 = nil, nil, nil
	self.embers:Clear()
	self.sparks:Clear()
	self.stars:Clear()
	self.playing = false
	self.phase = nil
	local fn = self.onDone
	self.onDone = nil
	if fn then
		fn()
	end
	-- the alerts that waited for the end of the scene
	if ns.Toast and ns.Toast.Resume then
		ns.Toast:Resume()
	end
end

-- A click: straight to the end.
function Cin:Skip()
	if self.playing and self.phase ~= "out" then
		self:Exit(true)
	end
end

-- The booster scene closed under it: gone at once, the card stays as it was.
function Cin:Stop()
	if not self.playing then
		return
	end
	ns.CancelOwner(self)
	if self.music and StopSound then
		StopSound(self.music, 500)
		self.music = nil
	end
	if self.voice and StopSound then
		StopSound(self.voice, 300)
		self.voice = nil
	end
	self.onReveal = nil
	self.revealed = true
	self.onDone = nil
	self:Finish()
end

-------------------------------------------------------------------------------
-- The camera of the scene
-------------------------------------------------------------------------------
-- The camera looks at (tx, ty, tz) from the distance d, from the front of the creature (it faces
-- +x: the camera stands on its side, turned by half a turn), a little from below.
function Cin:PlaceCamera(tx, ty, tz, d)
	local sc = self.frame.scene
	local yaw, pitch = math.pi, PITCH
	local nx, ny, nz = math.cos(-pitch) * math.cos(yaw), math.cos(-pitch) * math.sin(yaw), math.sin(-pitch)
	sc:SetCameraPosition(tx - nx * d, ty - ny * d, tz - nz * d)
	sc:SetCameraOrientationByYawPitchRoll(yaw, pitch, 0)
end

-- Once the creature is loaded: its bounding box (false until the client has it).
function Cin:Measure()
	local actor = self.frame.actor
	if not actor:IsLoaded() then
		return false
	end
	local ok, x1, y1, z1, x2, y2, z2 = pcall(actor.GetActiveBoundingBox, actor)
	if ok and type(x1) == "table" and type(y1) == "table" then
		-- (two vectors rather than six numbers)
		local lo, hi = x1, y1
		x1, y1, z1, x2, y2, z2 = lo.x, lo.y, lo.z, hi.x, hi.y, hi.z
	end
	if not (ok and type(x1) == "number" and type(z1) == "number" and type(x2) == "number" and type(z2) == "number") then
		return false
	end
	local hz = z2 - z1
	if not (hz > 0.05) then
		return false -- not ready yet
	end
	self.box = { cx = (x1 + x2) / 2, cy = ((y1 or 0) + (y2 or 0)) / 2, cz = (z1 + z2) / 2, top = z2, hz = hz }
	self.K = self:Rule()
	return true
end

-- How large one unit of height is on the screen (the height on screen, in points, times the
-- distance): the rule of the game, its field of view spanning the diagonal of the scene.
function Cin:Rule()
	local sc = self.frame.scene
	local ok, fov = pcall(sc.GetCameraFieldOfView, sc)
	if not (ok and type(fov) == "number" and fov > 0.05 and fov < 3) then
		fov = FOV
	end
	self.fov = fov
	local w, h = sc:GetWidth(), sc:GetHeight()
	return math.sqrt(w * w + h * h) / (2 * math.tan(fov / 2))
end

-- The same measure read on the screen, for the first frames: the middle of what was framed and its
-- two ends projected by the scene, with the camera placed the frame before (pose). The answer may
-- come in points, in pixels or from 0 to 1, from a corner or from the middle: the middle of the frame
-- tells which. Kept when it agrees with itself and is not far from the rule.
function Cin:Remeasure(pose)
	local sc = self.frame.scene
	local tx, ty, tz, framed, d = pose[1], pose[2], pose[3], pose[4], pose[5]
	self.measureTries = self.measureTries + 1
	local function P(z)
		local ok, px, py = pcall(sc.Project3DPointTo2D, sc, tx, ty, z)
		if ok and type(px) == "number" and type(py) == "number" and px == px and py == py then
			return px, py
		end
	end
	local xc, yc = P(tz)
	local _, yt = P(tz + framed / 2)
	local _, yb = P(tz - framed / 2)
	local w, h = sc:GetWidth(), sc:GetHeight()
	local unit, how
	if xc and yc and yt and yb and w > 0 and h > 0 then
		if xc > w / 8 and yc > h / 8 then
			local ux, uy = xc / (w / 2), yc / (h / 2)
			if math.abs(ux - uy) / uy < 0.06 then
				unit, how = uy, "points"
			end
		elseif xc > 0.4 and xc < 0.6 and yc > 0.4 and yc < 0.6 then
			unit, how = 1 / h, "0-1"
		elseif math.abs(xc) < w / 8 and math.abs(yc) < h / 8 then
			unit, how = 1, "middle"
		end
	end
	local rule = self:Rule()
	local K = unit and math.abs(yt - yb) / unit * d / framed
	local kept = K and K > rule / 3 and K < rule * 3
	if kept then
		self.K = K
	end
	if kept or self.measureTries >= 6 then
		self.measured = true
		if ns.db and ns.db.cinedebug then
			ns.Print(string.format(("cinematic: %s, box %.2f, K %.0f (rule %.0f, fov %.2f), %s, measure %s (%s %s / %s %s), scene %.0fx%.0f"), 
				tostring(C:Name(self.card)), self.box.hz, self.K, rule, self.fov or -1, kept and "measured" or "rule",
				tostring(how), tostring(xc and string.format(("%.1f"), xc)), tostring(yc and string.format(("%.1f"), yc)),
				tostring(yt and string.format(("%.1f"), yt)), tostring(yb and string.format(("%.1f"), yb)), w, h))
		end
	end
end

-- Every frame: the part of the creature framed (from the whole of it to its head and shoulders,
-- with the zoom), its height on the screen (with the distance), the facing.
function Cin:SceneCamera()
	local f, cam = self.frame, self.cam
	local actor = f.actor
	actor:SetYaw(cam.rot)
	if not self.box then
		if not self:Measure() then
			-- (until it is measured, the camera stays far away)
			self:PlaceCamera(0, 0, 1, 60)
			return
		end
		-- (it is there: the light of its power on it)
		self:WearAura()
	end
	local b = self.box
	local z = math.max(0, math.min(1, cam.zoom))
	local framed = b.hz * (1 - 0.62 * z)
	local tz = b.cz + (b.top - 0.19 * b.hz - b.cz) * z
	-- (the middle of its box turns with it)
	local c, s = math.cos(cam.rot), math.sin(cam.rot)
	local tx, ty = b.cx * c - b.cy * s, b.cx * s + b.cy * c
	local want = FILL * self.H / math.max(0.2, cam.dist)
	if not self.measured and self.pose then
		self:Remeasure(self.pose)
	end
	local d = self.K * framed / want
	self:PlaceCamera(tx, ty, tz, d)
	self.pose = { tx, ty, tz, framed, d }
end

-------------------------------------------------------------------------------
-- Every frame: the camera, the drift of the facing, the shake, the rays, the embers.
-------------------------------------------------------------------------------
function Cin:Tick(elapsed)
	if not self.playing then
		return
	end
	self.t = (self.t or 0) + elapsed
	-- (1.12.0: the line in the black, letter by letter)
	if self.phase == "line" then
		self:LineTick(elapsed)
	end
	local f, m, cam = self.frame, self.frame.model, self.cam
	if self.spin and self.spin ~= 0 then
		cam.rot = cam.rot + self.spin * elapsed
	end
	if f.scene then
		self:SceneCamera()
	else
		CuratorOctoFull.SetPortraitZoom(m, math.max(0, math.min(1, cam.zoom)))
		CuratorOctoFull.SetCamDistanceScale(m, cam.dist * (self.camK or 1))
		CuratorOctoFull.SetRotation(m, cam.rot)
	end
	-- the shake of the blows
	local sx, sy = 0, 0
	if self.shakeT and self.shakeT > 0 then
		self.shakeT = self.shakeT - elapsed
		local k = (self.shakeK or 6) * math.max(0, math.min(1, self.shakeT / 0.4))
		sx, sy = (math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k
	end
	f.stage:ClearAllPoints()
	f.stage:SetPoint("TOPLEFT", f, "TOPLEFT", sx, sy)
	f.stage:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", sx, sy)
	-- the place of the album, slowly closer
	local crop = self.crop
	if crop then
		local z = math.min(0.05, self.t * 0.008)
		local du, dv = (crop[2] - crop[1]) * z / 2, (crop[4] - crop[3]) * z / 2
		f.backdrop:SetTexCoord(crop[1] + du, crop[2] - du, crop[3] + dv, crop[4] - dv)
	end
	CuratorOctoFull.SetRotation(f.rays, self.t * 0.2)
	CuratorOctoFull.SetRotation(f.rays2, -self.t * 0.13)
	-- embers rising all along
	self.emberT = (self.emberT or 0) + elapsed
	if self.phase ~= "out" and self.emberT > 0.12 then
		self.emberT = 0
		local cols = self.style.embers
		local W, H = self.W, self.H
		self.embers:Rise(-W * 0.38, W * 0.38, -H * 0.36, cols[math.random(1, CuratorOctoFull.Length(cols))], 2, H * 0.55, 2.4, 12)
	end
end
