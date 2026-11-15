local octoConstants = {}
local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
octoConstants.MEDIA = ns.MEDIA
local C = ns.Collection
local S = ns.Skin

-- Card textures are 366x512 inside a 512x512 file (half size: 183x256 in 256x256).
octoConstants.TEX_R = 366 / 512
-- Layout of the card face, as fractions of the 366x512 artwork (see the texture generator).
octoConstants.ART_L, octoConstants.ART_T, octoConstants.ART_R, octoConstants.ART_B = 24 / 366, 24 / 512, 24 / 366, 194 / 512
octoConstants.MEDAL_X, octoConstants.MEDAL_Y = 50 / 366, 48 / 512
octoConstants.NAME_Y, octoConstants.NAME_H = 320 / 512, 40 / 512 -- centre and usable height of the name ribbon
octoConstants.NAME_W = 0.84                        -- usable width of the ribbon, as a fraction of the card
octoConstants.TYPE_Y, octoConstants.RAR_Y = 371 / 512, 414 / 512
octoConstants.NUM_X, octoConstants.NUM_Y = 46 / 366, 452 / 512  -- number: from the right edge; series mark on the left
octoConstants.SET_X = 52 / 366
-- (1.14.0, his idea) the pattern of a titanforged copy: on the line of the number, after the mark of the album (its
-- left), clear of the number (a long one: smaller)
octoConstants.PATTERN_X = 70 / 366
octoConstants.GEM_Y, octoConstants.GEM_S = 486 / 512, 34 / 366
octoConstants.COUNT_Y = 300 / 512                 -- just above the ribbon
-- (1.12.0) the skull on the crest of a mythic card of Hallow's End: its size (a share of the width of the card) and
-- the height of its middle; its spikes (width, height, middle); the pumpkin of the game in the medallion of the crest
-- of the other rarities (its middle, the radius of the medallion inside, on the card of 366 x 512)
octoConstants.CREST_SKULL = { 74 / 366, 26 / 512 }
octoConstants.CREST_SPIKES = { 84 / 366, 111 / 366, 19.5 / 512 }
octoConstants.CREST_ICON = "Interface\\Icons\\INV_Misc_Bag_28_Halloween"
octoConstants.CREST_MEDAL = { [1] = { 28, 21 }, [2] = { 28, 22 }, [3] = { 28, 23 }, [4] = { 29, 24 }, [5] = { 31, 29 } }
octoConstants.ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
octoConstants.INK = { 0.25, 0.16, 0.07 }
-- (1.14.0) the light of the contraband of the Hardcup Saison 3 (its rays)
octoConstants.SMUGGLE_GLOW = { 0.9, 0.06, 0.1 }
-- (1.12.0, later) the plate of a limited edition (EditionPlate, 256 x 64), between the mark of the album and the number:
-- its width (a share of the card), its height (a share of the card: two lines; one on a small card)
octoConstants.PLATE_W, octoConstants.PLATE_H, octoConstants.PLATE_H_S = 0.44, 0.072, 0.05
-- (a small card: narrower, a little to the left, clear of its number)
octoConstants.PLATE_W_S, octoConstants.PLATE_X_S = 0.36, -0.03

ns.CARD_SIZES = {
	small = { 112, 157 },
	-- (the cards of a booster of a zone, 1.2: ten; 1.14.0: eight)
	mid = { 134, 188 },
	big = { 180, 252 },
	-- (the five cards of a booster of a dungeon or a raid, 1.4)
	lair = { 200, 280 },
	huge = { 264, 370 },
}

-- Reveal animations, first one the model has wins.
octoConstants.ANIM_CREATURE = { 55, 74, 16, 17, 18, 118, 57 } -- battle roar, roar, attacks
octoConstants.ANIM_PERSON = { 67, 66, 113, 60 }               -- wave, bow, salute, talk

-------------------------------------------------------------------------------
-- The creature
-------------------------------------------------------------------------------
-- The creature of a card stands in a scene of the game (a ModelScene, as in the entrances of the best
-- cards) with one actor. Once it is loaded its bounding box is measured, and the camera is placed from
-- it, so that the creature fills the window of the card whatever its size. (A model frame frames the
-- whole box of its model, wings and tail spread: the big creatures came out tiny, and a person stood
-- from head to toe in a lot of air.) A tall creature, a person, is framed from the shins up, the others
-- whole. /curator zoom (0: whole, 1: the head and shoulders) and /curator cam (its distance: more, smaller)
-- change it on every card. A client without model scenes: a model frame, as before.
octoConstants.FOV = 0.45         -- the field of view of the camera (radians): little perspective
octoConstants.PITCH = -0.05      -- the camera a little lower than the creature, looking up at it
octoConstants.FREE_TOP = 0.06    -- the top of the window kept clear (the medallion, the ornaments)
octoConstants.FREE_BOTTOM = 0.07 -- the bottom of the window, behind the ribbon of the name
octoConstants.FILL_W = 1         -- the share of the width of the window a wide creature takes
octoConstants.LIFT = 0.35        -- a creature smaller than the window: how high it stands above the ribbon
octoConstants.STEP_BACK = 0.35   -- the camera steps back by this share of its depth: its near parts fit too
-- (1.12.0) a wide creature (a dragon and its wings, a long beast seen from the side) fitted to the width of the
-- window came out as a thin line across it: it stands at least this share of the height its window gives,
-- its sides past the edges when they must
octoConstants.MIN_TALL = 0.5
-- (1.12.0) the box of all its animations (a dragon flying, a giant stamping: far larger than the creature
-- standing), taken at once when the box of its animation of the moment was not given yet, made the big creatures
-- tiny on the cards that measured them first: only after ACTIVE_WAIT seconds without the other one, and
-- replaced by it when it comes (looked for MAX_WAIT seconds)
octoConstants.ACTIVE_WAIT, octoConstants.MAX_WAIT = 0.6, 6
octoConstants.ART_W, octoConstants.ART_H = 1 - octoConstants.ART_L - octoConstants.ART_R, 1 - octoConstants.ART_T - octoConstants.ART_B
-- (a creature whose box the client does not give: framed as a person until it does)
octoConstants.GUESS = { -0.5, -0.56, 0, 0.5, 0.56, 2.12 }

-- The boxes measured (by display: each creature once), and how the scenes of this client project,
-- read once on the screen (nil: by the rule).
octoConstants.BOXES = {}
ns.Creatures = { boxes = octoConstants.BOXES, cal = nil }
local calTries = 0

-- Lighting: the game's collection frames use a light from the front left.
local lightNormal, lightBlack
local function Lights()
	if not lightNormal and CreateColor and CreateVector3D then
		lightNormal = { omnidirectional = false, point = CreateVector3D(-1, 0, 0), ambientIntensity = 0.75, ambientColor = CreateColor(0.95, 0.95, 1), diffuseIntensity = 0.7, diffuseColor = CreateColor(1, 0.96, 0.88) }
		lightBlack = { omnidirectional = false, point = CreateVector3D(-1, 0, 0), ambientIntensity = 0, ambientColor = CreateColor(0, 0, 0), diffuseIntensity = 0, diffuseColor = CreateColor(0, 0, 0) }
	end
	return lightNormal, lightBlack
end
-- (the same light in a scene: from the front, a little from the left and from above)
local function Unit(x, y, z)
	local l = math.sqrt(x * x + y * y + z * z)
	return x / l, y / l, z / l
end
local LX, LY, LZ = Unit(-1, 0.45, -0.55)

-- The bounding box of the creature once the client has it (nil before): its two corners; (1.12.0) the box of its
-- animation of the moment, or with all (all its animations, that box marked max) the other one when it does
-- not come.
octoConstants.GETTERS_ACTIVE, octoConstants.GETTERS_ALL = { "GetActiveBoundingBox" }, { "GetActiveBoundingBox", "GetMaxBoundingBox" }
local function Measure(actor, all)
	if not actor:IsLoaded() then
		return nil
	end
	for _, getter in ipairs(all and octoConstants.GETTERS_ALL or octoConstants.GETTERS_ACTIVE) do
		local ok, x1, y1, z1, x2, y2, z2 = false
		if actor[getter] then
			ok, x1, y1, z1, x2, y2, z2 = pcall(actor[getter], actor)
		end
		if ok and type(x1) == "table" and type(y1) == "table" then
			-- (two vectors rather than six numbers)
			local lo, hi = x1, y1
			x1, y1, z1, x2, y2, z2 = lo.x, lo.y, lo.z, hi.x, hi.y, hi.z
		end
		if ok and type(x1) == "number" and type(y1) == "number" and type(z1) == "number" and type(x2) == "number"
			and type(y2) == "number" and type(z2) == "number" then
			local dx, dy, hz = x2 - x1, y2 - y1, z2 - z1
			if hz > 0.05 and dx > 0.01 and dy > 0.01 and hz < 5000 and dx < 5000 and dy < 5000 then
				return { x1, y1, z1, x2, y2, z2, max = (getter == "GetMaxBoundingBox") or nil }
			end
		end
	end
end

-- How large one unit is at a distance of one, in points of the scene: the rule of the game (its field
-- of view spans the diagonal of the scene), corrected by what the screen showed.
local function Rule(sc, w, h)
	local ok, fov = pcall(sc.GetCameraFieldOfView, sc)
	if not (ok and type(fov) == "number" and fov > 0.05 and fov < 3) then
		fov = octoConstants.FOV
	end
	return math.sqrt(w * w + h * h) / (2 * math.tan(fov / 2))
end

-- The part framed: 0 the whole creature, 1 its head and shoulders. A tall one (a person) from the
-- shins up: the taller for its breadth, the closer. (studio: the zoom the player chose left aside)
local function Zoom(box, studio)
	local db = ns.db or {}
	if db.zoom and not studio then
		return math.max(0, math.min(1, db.zoom))
	end
	local tall = (box[6] - box[3]) / math.max(0.01, box[4] - box[1], box[5] - box[2])
	return 0.32 * math.max(0, math.min(1, (tall - 1) / 0.85))
end

-- The camera, from the box of the creature: the part framed fills the window between the ribbon of
-- the name and the top of it (or its width, for a wide creature), in the middle.
local function Place(sc)
	local box, actor, c = sc.box, sc.actor, sc.owner
	if not box then
		-- (not measured yet: the camera looks away, nothing of it is drawn)
		actor:SetYaw(0)
		sc:SetCameraPosition(1000, 0, 0)
		sc:SetCameraOrientationByYawPitchRoll(0, 0, 0)
		sc.pose = nil
		return
	end
	local db = ns.db or {}
	local yaw = sc.yaw or 0
	actor:SetYaw(yaw)
	local x1, y1, z1, x2, y2, z2 = unpack(box)
	local dx, dy, hz = x2 - x1, y2 - y1, z2 - z1
	-- its half width on the screen, its half depth, the middle of it (it faces +x, the camera looks
	-- along -x: the screen goes along y)
	local half, deep, tx, ty
	if c.spin then
		-- (it turns: framed whatever its facing, around the axis it turns about)
		local r = 0
		for _, px in ipairs({ x1, x2 }) do
			for _, py in ipairs({ y1, y2 }) do
				r = math.max(r, math.sqrt(px * px + py * py))
			end
		end
		half, deep, tx, ty = r, r, 0, 0
	else
		local co, si = math.cos(yaw), math.sin(yaw)
		local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
		half = (math.abs(dx * si) + math.abs(dy * co)) / 2
		deep = (math.abs(dx * co) + math.abs(dy * si)) / 2
		tx, ty = cx * co - cy * si, cx * si + cy * co
	end
	local framed = hz * (1 - 0.62 * Zoom(box, c.studio))
	local aw, ah = c.W * octoConstants.ART_W, c.H * octoConstants.ART_H
	local K = Rule(sc, aw, ah) * (ns.Creatures.cal or 1)
	local usable = ah * (1 - octoConstants.FREE_TOP - octoConstants.FREE_BOTTOM)
	-- its size: the part framed as tall as the window, or the creature as wide (1.12.0: never less tall than
	-- MIN_TALL of the window)
	local cam = math.max(0.2, (not c.studio and db.cam) or 1)
	local fitH = usable / framed
	local fitW = aw * octoConstants.FILL_W / math.max(0.01, 2 * half)
	local fit = math.min(fitH, math.max(fitW, fitH * octoConstants.MIN_TALL)) / cam
	local d = K / fit + octoConstants.STEP_BACK * deep
	-- (stepped back for its near parts: never smaller than MIN_TALL all the same)
	d = math.min(d, K * cam / (fitH * octoConstants.MIN_TALL))
	local s = K / d
	-- its bottom on the ribbon: a little higher when it is smaller than the window, its top under the
	-- top of the window when it is larger
	local free = usable - s * framed
	local bottom = -ah / 2 + ah * octoConstants.FREE_BOTTOM + (free > 0 and free * octoConstants.LIFT or free)
	local tz = (z2 - framed) - bottom / s
	sc.pose = { tx, ty, tz, d }
	-- (a card held in the hand, in 3D: the camera goes round the creature as the eye goes round the card)
	if c.held then
		ns.OrbitScene(sc)
		return
	end
	-- the camera in front of it, a little lower, looking at that point
	local nx, ny, nz = math.cos(-octoConstants.PITCH) * math.cos(math.pi), math.cos(-octoConstants.PITCH) * math.sin(math.pi), math.sin(-octoConstants.PITCH)
	sc:SetCameraPosition(tx - nx * d, ty - ny * d, tz - nz * d)
	sc:SetCameraOrientationByYawPitchRoll(math.pi, octoConstants.PITCH, 0)
end

-- A card held, turned (yaw) and tilted (pitch, its top toward the eye): the camera of its creature
-- goes round it the same way, at the same distance, around the same point (the middle of the window):
-- the creature turns with the card, as a figure set in it.
function ns.OrbitScene(sc)
	local p, c = sc.pose, sc.owner
	if not p then
		return
	end
	local tx, ty, tz, d = p[1], p[2], p[3], p[4]
	local yaw, e = c.heldYaw or 0, octoConstants.PITCH + (c.heldPitch or 0)
	sc:SetCameraPosition(tx + d * math.cos(e) * math.cos(yaw), ty - d * math.cos(e) * math.sin(yaw), tz + d * math.sin(e))
	sc:SetCameraOrientationByYawPitchRoll(math.pi - yaw, e, 0)
end

local function Debug(sc, what)
	if ns.db and ns.db.cinedebug and sc.box then
		local b = sc.box
		local card = sc.owner.card
		ns.Print(string.format(("card: %s, %s, box %.2f x %.2f x %.2f, zoom %.2f, scale %s"), tostring(card and C:Name(card)), what,
			b[4] - b[1], b[5] - b[2], b[6] - b[3], Zoom(b, sc.owner.studio), tostring(ns.Creatures.cal and string.format(("%.3f"), ns.Creatures.cal) or "rule")))
	end
end

-- How the scenes of this client project, read once on the screen: the middle of what is framed and
-- two points above and below it, the camera placed the frame before. The answer may come from 0 to 1,
-- from the middle (in pixels), or from a corner in points or in pixels (whatever the scale of the
-- card): the middle of the scene tells which. Kept when it agrees with itself and is not far from the
-- rule. false: not now (the card is squeezed by a flip).
local function Calibrate(sc)
	local c = sc.owner
	if c.held then
		-- (a card held: its camera goes round, another card reads the screen)
		return true
	end
	local w, h = sc:GetWidth(), sc:GetHeight()
	local aw, ah = c.W * octoConstants.ART_W, c.H * octoConstants.ART_H
	if not sc.pose or math.abs(w - aw) > 1 or math.abs(h - ah) > 1 then
		return false
	end
	calTries = calTries + 1
	local tx, ty, tz, d = unpack(sc.pose)
	-- (two points along the up of the camera, as far from the camera as the middle)
	local ux, uz = -math.sin(octoConstants.PITCH), math.cos(octoConstants.PITCH)
	local sep = d * 0.05
	local function P(k)
		local ok, px, py = pcall(sc.Project3DPointTo2D, sc, tx + ux * sep * k, ty, tz + uz * sep * k)
		if ok and type(px) == "number" and type(py) == "number" and px == px and py == py then
			return px, py
		end
	end
	local xc, yc = P(0)
	local _, yt = P(1)
	local _, yb = P(-1)
	local unit
	if xc and yc and yt and yb and w > 0 and h > 0 then
		if xc > 0.4 and xc < 0.6 and yc > 0.4 and yc < 0.6 then
			unit = 1 / h
		elseif math.abs(xc) < 0.05 and math.abs(yc) < 0.05 then
			unit = CuratorOctoFull.GetEffectiveScale(sc)
		elseif xc > 0 and yc > 0 then
			local ux2, uy2 = xc / (w / 2), yc / (h / 2)
			if math.abs(ux2 - uy2) / uy2 < 0.06 then
				unit = uy2
			end
		end
	end
	local rule = Rule(sc, w, h)
	local K = unit and math.abs(yt - yb) / unit * d / (2 * sep)
	if K and K > rule / 3 and K < rule * 3 then
		local was = ns.Creatures.cal or 1
		ns.Creatures.cal = K / rule
		Debug(sc, "measured on the screen")
		if math.abs(K / rule - was) > 0.01 then
			-- every creature already framed: again, with it
			for other in pairs(ns.AllCards) do
				local m = other.model
				if m.actor and m.box then
					Place(m)
				end
			end
		end
	end
	return true
end

-- (1.12.0, later) The stages of a corruption, as the corrupted gear of Visions of N'Zoth showed them: from 1 %, 40, 60,
-- 80 % (its light the red of N'Zoth from 80 %); and the light the creature of a corrupted card stands in, by stage
-- (its ambient light, the light on it).
local function CorruptStage(k)
	k = tonumber(k) or 0
	return (k >= 80 and 4) or (k >= 60 and 3) or (k >= 40 and 2) or ((k > 0) and 1) or 0
end
octoConstants.CORRUPT_LIGHT = {
	{ { 0.6, 0.65, 0.86 }, { 0.6, 0.74, 1 } },
	{ { 0.46, 0.5, 0.8 }, { 0.54, 0.72, 1.05 } },
	{ { 0.34, 0.37, 0.72 }, { 0.5, 0.7, 1.15 } },
	{ { 0.5, 0.18, 0.25 }, { 1.1, 0.3, 0.3 } },
}

-- (1.14.0, his word: the creatures of the cards in 2D, then « fixe » and cut out) The option of the creatures as a still
-- picture (ns.db.still): each creature stays in its pose, cut out on the backdrop of its card, without its movements, its
-- reveal or its slow turn in the detail of a card (UI/Options.lua). The entrances of the best cards keep theirs.
local function Still()
	return (ns.db and ns.db.still) and true or false
end

-- The look of the creature in its scene: lit, or a black shape for a card not found yet (still).
local function Look(sc)
	local db = ns.db or {}
	local actor = sc.actor
	sc:SetLightVisible(true)
	sc:SetLightType((Enum and Enum.ModelLightType and Enum.ModelLightType.Directional) or 0)
	sc:SetLightDirection(LX, LY, LZ)
	if sc.silhouette and not db.plain then
		sc:SetLightAmbientColor(0, 0, 0)
		sc:SetLightDiffuseColor(0, 0, 0)
		pcall(actor.SetParticleOverrideScale, actor, 0)
		pcall(sc.SetPaused, sc, true)
	else
		sc:SetLightAmbientColor(0.95 * 0.75, 0.95 * 0.75, 0.75)
		sc:SetLightDiffuseColor(0.7, 0.96 * 0.7, 0.88 * 0.7)
		-- (1.11.0) a titanforged card: its creature in the light of the prism, as it was last (Card:PrismLight; none
		-- yet while its face has not been shown)
		local p = sc.prism
		if p and p[9] and not db.plain then
			sc:SetLightAmbientColor(p[1], p[2], p[3])
			sc:SetLightDiffuseColor(p[4], p[5], p[6])
			sc:SetLightDirection(p[7], p[8], p[9])
		end
		-- (1.12.0, later) a corrupted card: its creature in the cold light of the Void, darker as it climbs; in the red
		-- of N'Zoth from 80 %
		local cl = octoConstants.CORRUPT_LIGHT[CorruptStage(sc.corruptK)]
		if cl and not db.plain then
			sc:SetLightAmbientColor(cl[1][1], cl[1][2], cl[1][3])
			sc:SetLightDiffuseColor(cl[2][1], cl[2][2], cl[2][3])
		end
		pcall(actor.SetParticleOverrideScale, actor, nil)
		-- (a card held that moves: its creature still; the creatures as a still picture: always)
		pcall(sc.SetPaused, sc, (sc.owner.frozen or Still()) and true or false)
	end
end

-- Every frame until the creature is measured (and the scenes read once): its box, then the camera.
-- (Its look again once it is loaded: what a creature still loading is told may not stay.)
local function Poll(sc, elapsed)
	local actor = sc.actor
	if sc.slow then
		-- (a creature that takes long to come: looked for twice a second only)
		sc.slow = sc.slow + elapsed
		if sc.slow < 0.5 then
			return
		end
		elapsed, sc.slow = sc.slow, 0
	end
	if not sc.box or sc.guess or (sc.box.max and sc.boxWait < octoConstants.MAX_WAIT) then
		-- (1.12.0: the box of all its animations only when the other one does not come; that one when it comes)
		local box = Measure(actor, sc.boxWait > octoConstants.ACTIVE_WAIT)
		if box and box.max and sc.box and sc.box.max then
			box = nil
		end
		if box then
			octoConstants.BOXES[sc.display] = box
			sc.box, sc.guess = box, nil
			Place(sc)
			Debug(sc, box.max and "measured (all its animations)" or "measured")
		elseif sc.box and not sc.guess then
			-- (framed by the box of all its animations: the one of the moment looked for a while longer)
			if actor:IsLoaded() then
				sc.boxWait = sc.boxWait + elapsed
			end
		elseif actor:IsLoaded() then
			-- loaded, its box not given yet: looked at from far away (in case the client gives the box of
			-- what a camera sees only), then framed as a person after a second, until it comes
			sc.boxWait = sc.boxWait + elapsed
			if sc.boxWait > 1 and not sc.box then
				sc.box, sc.guess = octoConstants.GUESS, true
				Place(sc)
			elseif sc.boxWait > 0.08 and not sc.far and not sc.box then
				sc.far = true
				sc:SetCameraPosition(300, 0, 1)
				sc:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
			elseif sc.boxWait > 6 then
				sc.guess = nil -- (it never will)
			end
		else
			-- not loaded yet: after a moment it is looked at from far away (a speck), in case the client
			-- loads only what a camera sees
			sc.loadWait = sc.loadWait + elapsed
			if sc.loadWait > 0.25 and not sc.far then
				sc.far = true
				sc:SetCameraPosition(300, 0, 1)
				sc:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
			elseif sc.loadWait > 10 and not sc.slow then
				sc.slow = 0
			end
		end
		if not sc.box then
			return
		end
	end
	if not sc.loaded then
		if not actor:IsLoaded() then
			-- (its box known, the creature itself still loading)
			sc.loadWait = sc.loadWait + elapsed
			if sc.loadWait > 10 and not sc.slow then
				sc.slow = 0
			end
			return
		end
		sc.loaded = true
		Look(sc)
		-- a reveal animation asked for while the creature was still loading
		local go = sc.pendingAnim
		if go then
			sc.pendingAnim = nil
			go()
		end
	end
	if sc.guess then
		return
	end
	if not ns.Creatures.cal and calTries < 6 then
		if not sc.placed then
			sc.placed = true -- (read on the screen the next frame, the camera in place)
			return
		end
		if not Calibrate(sc) then
			return
		end
	end
	-- (1.12.0: framed by the box of all its animations, the other one still looked for)
	if sc.box and sc.box.max and sc.boxWait < octoConstants.MAX_WAIT then
		return
	end
	CuratorOctoFull.SetScript(sc, "OnUpdate", nil)
end

-- Puts the creature of the card in its scene (its box known: framed at once).
local function Load(sc)
	local actor = sc.actor
	local db = ns.db or {}
	sc.yaw = (db.plain and not sc.owner.studio) and 0 or (sc.facing or 0.4)
	sc.box = octoConstants.BOXES[sc.display]
	sc.guess, sc.far, sc.placed, sc.slow, sc.loadWait, sc.boxWait = nil, nil, nil, nil, 0, 0
	actor:ClearModel()
	actor:Show()
	actor:SetPosition(0, 0, 0)
	if not (sc.display and sc.display > 0) then
		-- (no creature: an empty window)
		sc.box = nil
		Place(sc)
		CuratorOctoFull.SetScript(sc, "OnUpdate", nil)
		return
	end
	actor:SetModelByCreatureDisplayID(sc.display)
	actor:SetAnimation(0, 0, 1)
	Look(sc)
	Place(sc)
	CuratorOctoFull.SetScript(sc, "OnUpdate", Poll)
end

-- The facing of the creature (the detail of a card and the window of a card shown turn it).
local function SceneRotation(sc, yaw)
	sc.yaw = yaw
	if sc.box then
		if sc.owner.spin then
			sc.actor:SetYaw(yaw)
		else
			Place(sc)
		end
	end
end

-- The scene of a card, with its actor (nil: a client without model scenes).
local function NewScene(c, art, level)
	local ok, sc = pcall(CreateFrame, "ModelScene", nil, art)
	if not (ok and sc and sc.CreateActor) then
		return nil
	end
	local actor
	for _, template in ipairs({ false, "ModelSceneActorTemplate" }) do
		local made, a = pcall(sc.CreateActor, sc, nil, template or nil)
		if made and a then
			actor = a
			break
		end
	end
	if not actor then
		sc:Hide()
		return nil
	end
	sc:SetAllPoints()
	sc:SetFrameLevel(level)
	-- (the clicks and the mouse go through it, to the card)
	sc:EnableMouse(false)
	pcall(sc.EnableMouseWheel, sc, false)
	pcall(sc.SetCameraNearClip, sc, 0.05)
	pcall(sc.SetCameraFarClip, sc, 4000)
	pcall(sc.SetAllowOverlappedModels, sc, true)
	pcall(sc.SetCameraFieldOfView, sc, octoConstants.FOV)
	sc.actor, sc.owner = actor, c
	sc.SetRotation = SceneRotation
	Place(sc)
	return sc
end

-------------------------------------------------------------------------------
-- (1.7.0) A creature alone, as the window of a card shows it: for the studio of the author's build
-- (UI/AdminStudio.lua), whose photos go to the website. Framed the way of the cards, not with the zoom,
-- the distance or the plain view a player chose for theirs; still (its animation paused).
-------------------------------------------------------------------------------
-- A scene filling a frame of the size of the window of a card (nil: a client without model scenes). (1.14.0) opts.live:
-- its creature not still (the cards of the cases, UI/CrateCard.lua); opts.spin: framed whatever its facing, for one that
-- turns (scene:SetRotation(yaw)).
function ns.Creatures.Stage(parent, level, opts)
	local w, h = parent:GetWidth(), parent:GetHeight()
	if not (w > 0 and h > 0) then
		return nil
	end
	opts = opts or {}
	return NewScene({ W = w / octoConstants.ART_W, H = h / octoConstants.ART_H, frozen = not opts.live, studio = true, spin = opts.spin }, parent, level)
end

-- Its creature (0 or nil: none).
function ns.Creatures.Put(sc, display)
	sc.display = display
	sc.facing = nil
	sc.loaded = false
	Load(sc)
end

-- Framed for good: loaded, measured (or framed as a person, its box never given), the scenes of the
-- client read.
function ns.Creatures.Ready(sc)
	return (sc.display or 0) > 0 and sc.loaded == true and sc.box ~= nil and not sc.guess and sc:GetScript("OnUpdate") == nil
end

-- Framed again (with what the screen said of the scenes since).
function ns.Creatures.Frame(sc)
	Place(sc)
end

-- What a creature can play: an actor cannot tell, a model frame can. A few small model frames, in a
-- corner of the screen, under the rest and in the dark, load each creature once and keep what they
-- found (several at once: the cards of a booster are turned over together).
local Probe = { known = {}, waiting = {}, order = {}, frames = {}, fails = {} }
octoConstants.PROBES = 3
octoConstants.PROBED = {}
for _, list in ipairs({ octoConstants.ANIM_CREATURE, octoConstants.ANIM_PERSON }) do
	for _, a in ipairs(list) do
		octoConstants.PROBED[CuratorOctoFull.Length(octoConstants.PROBED) + 1] = a
	end
end

-- (an answer that fails is told, and does not stop the others)
local function Call(fn, ...)
	local ok, err = pcall(fn, unpack(arg, 1, arg.n))
	if not ok and geterrorhandler then
		geterrorhandler()(err)
	end
end

function Probe:Frame(i)
	local f = self.frames[i]
	if not f then
		f = CreateFrame("PlayerModel", nil, UIParent)
		CuratorOctoFull.SetSize(f, 24, 24)
		f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
		f:SetFrameStrata("BACKGROUND")
		f:SetFrameLevel(0)
		CuratorOctoFull.SetScript(f, "OnModelLoaded", function(m)
			local _, black = Lights()
			if black then
				CuratorOctoFull.SetLight(m, true, black)
			end
			CuratorOctoFull.SetParticlesEnabled(m, false)
			CuratorOctoFull.SetCamDistanceScale(m, 8)
			Probe:Loaded(m)
		end)
		f:Hide()
		self.frames[i] = f
	end
	return f
end

-- fn(has) once it is known: has[anim] for the animations of the reveals.
function Probe:Ask(display, fn)
	if not display or display <= 0 then
		return
	end
	local has = self.known[display]
	if has then
		fn(has)
		return
	end
	local w = self.waiting[display]
	if w then
		w[CuratorOctoFull.Length(w) + 1] = fn
		return
	end
	self.waiting[display] = { fn }
	self.order[CuratorOctoFull.Length(self.order) + 1] = display
	self:Pump()
end

-- Each free model frame takes the next creature; the others are emptied and hidden.
function Probe:Pump()
	for i = 1, octoConstants.PROBES do
		local f = self:Frame(i)
		if not f.display then
			local display = CuratorOctoFull.Remove(self.order, 1)
			if display then
				self:Start(f, display)
			elseif f:IsShown() then
				f:ClearModel()
				f:Hide()
			end
		end
	end
end

function Probe:Start(f, display)
	local token = {}
	f.display, f.token = display, token
	-- (a creature that does not load: nothing to play this time)
	ns.Delay(2, function()
		if f.token == token then
			self:Finish(f, nil)
		end
	end, self)
	f:Show()
	f:ClearModel()
	if not pcall(f.SetDisplayInfo, f, display) then
		self:Finish(f, nil)
	end
end

function Probe:Loaded(f)
	if not f.display then
		return
	end
	local has = {}
	for _, a in ipairs(octoConstants.PROBED) do
		local ok, yes = pcall(f.HasAnimation, f, a)
		has[a] = (ok and yes) and true or false
	end
	self:Finish(f, has)
end

-- The answer for the creature of a frame (nil: it did not load; twice: nothing to play, for good);
-- the frame takes the next one.
function Probe:Finish(f, has)
	local display = f.display
	f.display, f.token = nil, nil
	if not has then
		self.fails[display] = (self.fails[display] or 0) + 1
		if self.fails[display] >= 2 then
			has = {}
		end
	end
	if has then
		self.known[display] = has
	end
	local waiters = self.waiting[display]
	self.waiting[display] = nil
	self:Pump()
	for _, fn in ipairs(waiters or {}) do
		Call(fn, has or {})
	end
end

-- Every creature on the cards framed again (/curator zoom, /curator cam, /curator plain).
local ApplyModelLook
function ns.ReframeCards()
	for c in pairs(ns.AllCards) do
		local m = c.model
		if m.actor then
			-- (a creature still being measured is framed once it is)
			if m.display and m.box then
				m.yaw = (ns.db and ns.db.plain) and 0 or (m.facing or 0.4)
				Look(m)
				Place(m)
			end
		elseif m.display and m.loaded then
			ApplyModelLook(m)
		end
	end
end

-- A client without model scenes: the model frame places its camera itself, from the bounds of the
-- model.
function ApplyModelLook(m)
	if not m.display then
		return
	end
	local db = ns.db or {}
	CuratorOctoFull.SetRotation(m, db.plain and 0 or (m.facing or 0.4))
	CuratorOctoFull.SetPortraitZoom(m, db.zoom or m.zoom or 0)
	CuratorOctoFull.SetCamDistanceScale(m, db.cam or m.cam or 1)
	local normal, black = Lights()
	if db.plain and normal then
		-- diagnostics: the client's own lighting, model facing the camera
		CuratorOctoFull.SetLight(m, false, normal)
		CuratorOctoFull.SetParticlesEnabled(m, true)
		CuratorOctoFull.SetPaused(m, false)
	elseif m.silhouette then
		if black then
			CuratorOctoFull.SetLight(m, true, black)
		end
		CuratorOctoFull.SetParticlesEnabled(m, false)
		CuratorOctoFull.SetPaused(m, true)
	else
		if normal then
			CuratorOctoFull.SetLight(m, true, normal)
		end
		CuratorOctoFull.SetParticlesEnabled(m, true)
		CuratorOctoFull.SetPaused(m, Still())
	end
end

-- Splits a name in two at the space nearest to its middle.
local function SplitName(text)
	local mid, best = CuratorOctoFull.Length(text) / 2, nil
	for i in CuratorOctoFull.Gmatch(text, "() ") do
		if not best or math.abs(i - mid) < math.abs(best - mid) then
			best = i
		end
	end
	if best then
		return string.sub(text, 1, best - 1), string.sub(text, best + 1)
	end
end

-- Puts a name on the ribbon: one line, shrunk to fit; a name still too long goes on two lines
-- when the ribbon is tall enough, otherwise the client ends it with "..." (the tooltip has it whole).
local function SetName(fs, text, size, minSize, ribbonH, width)
	local maxW = width * 0.95
	local two = ribbonH / 2.3
	local floor = math.max(minSize, math.min(size, two >= 7.5 and two or minSize))
	local s = size
	while true do
		ns.SetFont(fs, s)
		fs:SetText(text)
		if ns.TextWidth(fs) <= maxW or s <= floor then
			break
		end
		s = math.max(floor, s - 0.5)
	end
	if ns.TextWidth(fs) <= maxW or two < 7.5 then
		return
	end
	local a, b = SplitName(text)
	if not a then
		return
	end
	s = math.min(size, two)
	while s >= 7 do
		ns.SetFont(fs, s)
		fs:SetText(a)
		local wa = ns.TextWidth(fs)
		fs:SetText(b)
		local wb = ns.TextWidth(fs)
		if math.max(wa, wb) <= maxW then
			fs:SetText(a .. "\n" .. b)
			return
		end
		s = s - 0.5
	end
	ns.SetFont(fs, floor)
	fs:SetText(text)
end

local function Ink(fs, r, g, b)
	fs:SetTextColor(r, g, b)
	fs:SetShadowOffset(0, 0)
end

-- A card not found yet is grey and darker all over (frame, ribbon, parchment, gem): the cards found
-- stand out at a glance. k: how bright the grey part stays.
local function Grey(tex, on, k)
	CuratorOctoFull.SetDesaturated(tex, on)
	k = on and k or 1
	tex:SetVertexColor(k, k, k)
end

local Card = {}
Card.__index = Card

-- Every card made (weak: a card thrown away is forgotten), for the entrances of the best cards that
-- hide their creatures while they play.
ns.AllCards = ns.AllCards or setmetatable({}, { __mode = "k" })

function ns.NewCard(parent, size)
	local W, H = unpack(ns.CARD_SIZES[size or "big"])
	local small = size == "small"
	local sfx = small and "_S" or ""
	local c = CreateFrame("Button", nil, parent)
	c.W, c.H, c.size, c.sfx = W, H, size or "big", sfx
	CuratorOctoFull.SetSize(c, W, H)
	c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local lvl = c:GetFrameLevel()
	local fs = H / 252

	-- behind the card
	c.shadow = c:CreateTexture(nil, "BACKGROUND", nil, -2)
	c.shadow:SetTexture(octoConstants.MEDIA .. "Shadow")
	c.shadow:SetPoint("CENTER", 4, -6)
	CuratorOctoFull.SetSize(c.shadow, W / 0.62, H / 0.82)
	c.shadow:SetAlpha(0.8)
	c.glow = c:CreateTexture(nil, "BACKGROUND", nil, -1)
	c.glow:SetTexture(octoConstants.MEDIA .. "CardGlow")
	c.glow:SetBlendMode("ADD")
	c.glow:SetPoint("CENTER")
	CuratorOctoFull.SetSize(c.glow, W / 0.46 * 1.05, H / 0.64 * 1.05)
	c.glow:SetAlpha(0)

	-- face: dark backing and parchment, the painting, the creature, then the metal frame
	local f = CreateFrame("Frame", nil, c)
	f:SetAllPoints()
	f:SetFrameLevel(lvl + 1)
	c.front = f
	f.base = f:CreateTexture(nil, "BACKGROUND")
	f.base:SetAllPoints()
	f.base:SetTexture(octoConstants.MEDIA .. "Body" .. sfx)
	f.base:SetTexCoord(0, octoConstants.TEX_R, 0, 1)

	local art = CreateFrame("Frame", nil, f)
	art:SetPoint("TOPLEFT", W * octoConstants.ART_L, -H * octoConstants.ART_T)
	art:SetPoint("BOTTOMRIGHT", -W * octoConstants.ART_R, H * octoConstants.ART_B)
	CuratorOctoFull.SetClipsChildren(art, true)
	art:SetFrameLevel(lvl + 2)
	c.art = art
	-- the photo of the album's place. It is twice as wide as tall: the window shows its middle.
	art.bg = art:CreateTexture(nil, "BACKGROUND")
	art.bg:SetAllPoints()
	art.bg:SetTexture(octoConstants.MEDIA .. "StudioElwynn")
	local u = (W * (1 - octoConstants.ART_L - octoConstants.ART_R)) / (H * (1 - octoConstants.ART_T - octoConstants.ART_B)) / 2
	c.artCrop = { 0.5 - u / 2, 0.5 + u / 2, 0, 1 }
	art.bg:SetTexCoord(unpack(c.artCrop))
	-- a soft shade toward the edges of the window, so the creature stands out from the photo
	art.shade = art:CreateTexture(nil, "BACKGROUND", nil, 1)
	art.shade:SetAllPoints()
	art.shade:SetTexture(octoConstants.MEDIA .. "Vignette")
	-- (1.11.0) a titanforged card: the foil of its window, on the photo and under the creature (the creature
	-- stands in front of it); the same rays as on the frame, that go on from it, and a little cracked ice (the
	-- window stretched over TitanWindow1..3; shown by the weights of the foil of the frame, Card:Holo)
	local wf = CreateFrame("Frame", nil, art)
	wf:SetAllPoints()
	wf:SetFrameLevel(lvl + 3)
	art.foilF = wf
	art.foil = {}
	for i = 1, 3 do
		local t = wf:CreateTexture(nil, "ARTWORK", nil, i)
		t:SetAllPoints()
		t:SetTexture(octoConstants.MEDIA .. "TitanWindow" .. i .. sfx)
		t:SetBlendMode("ADD")
		t:Hide()
		art.foil[i] = t
	end

	-- light rays of the best cards, between the backdrop and the creature
	local rf = CreateFrame("Frame", nil, art)
	rf:SetAllPoints()
	rf:SetFrameLevel(lvl + 4)
	local aw = W * (1 - octoConstants.ART_L - octoConstants.ART_R)
	art.rays = rf:CreateTexture(nil, "ARTWORK")
	art.rays:SetTexture(octoConstants.MEDIA .. "Rays")
	art.rays:SetBlendMode("ADD")
	art.rays:SetPoint("CENTER", 0, H * 0.04)
	CuratorOctoFull.SetSize(art.rays, aw * 1.9, aw * 1.9)
	art.rays:Hide()
	-- mythic cards: a second wheel of golden rays turning the other way, and the light breathes
	art.rays2 = rf:CreateTexture(nil, "ARTWORK", nil, 1)
	art.rays2:SetTexture(octoConstants.MEDIA .. "Rays")
	art.rays2:SetBlendMode("ADD")
	art.rays2:SetPoint("CENTER", 0, H * 0.04)
	CuratorOctoFull.SetSize(art.rays2, aw * 2.5, aw * 2.5)
	art.rays2:SetVertexColor(1, 0.78, 0.36)
	art.rays2:Hide()
	-- (1.11.0) a titanforged card: behind its creature, the light of the prism (two wheels of rays of all the
	-- colours, turning each its way, a soft light in their middle)
	art.glory = rf:CreateTexture(nil, "ARTWORK", nil, 2)
	art.glory:SetTexture(octoConstants.MEDIA .. "PrismRays")
	art.glory:SetBlendMode("ADD")
	art.glory:SetPoint("CENTER", 0, -H * 0.02)
	CuratorOctoFull.SetSize(art.glory, aw * 1.55, aw * 1.55)
	art.glory:Hide()
	art.glory2 = rf:CreateTexture(nil, "ARTWORK", nil, 3)
	art.glory2:SetTexture(octoConstants.MEDIA .. "PrismRays")
	art.glory2:SetBlendMode("ADD")
	art.glory2:SetPoint("CENTER", 0, -H * 0.02)
	CuratorOctoFull.SetSize(art.glory2, aw * 0.95, aw * 0.95)
	art.glory2:Hide()

	-- the creature: in a scene of the game, or a model frame (a client without scenes)
	local m = NewScene(c, art, lvl + 5)
	if not m then
		m = CreateFrame("PlayerModel", nil, art)
		m:SetAllPoints()
		m:SetFrameLevel(lvl + 5)
		m.hasLoadScript = CuratorOctoFull.SetScript(m, "OnModelLoaded", function(self)
			ApplyModelLook(self)
			self.loaded = true
			-- a reveal animation asked for while the creature was still loading
			local go = self.pendingAnim
			if go then
				self.pendingAnim = nil
				go()
			end
		end)
	end
	c.model = m
	ns.AllCards[c] = true
	-- (1.8.0) a picture in place of the creature: the cards of the combatants of PvP (UI/Pvp.lua)
	local pf = CreateFrame("Frame", nil, art)
	pf:SetAllPoints()
	pf:SetFrameLevel(lvl + 5)
	art.pic = pf:CreateTexture(nil, "ARTWORK")
	art.pic:Hide()
	-- (31 October, his idea: the creatures in 2D) The portrait of its creature (Portraits.lua, Media\Portraits): the
	-- studio of the author photographed every creature as the cards show it; a card shows its picture, turned in 3D too
	-- (a creature in 3D cannot follow the card: it stays in a flat rectangle of the screen). No creature loaded then.
	local prf = CreateFrame("Frame", nil, art)
	prf:SetAllPoints()
	prf:SetFrameLevel(lvl + 5)
	art.portraitF = prf
	art.portrait = prf:CreateTexture(nil, "ARTWORK")
	art.portrait:SetAllPoints()
	art.portrait:Hide()
	-- (1.11.0) a titanforged card: over its creature, in its window, stars that twinkle on it and motes of
	-- light of all the colours that rise around it (Card:Sparkle)
	local sf = CreateFrame("Frame", nil, art)
	sf:SetAllPoints()
	sf:SetFrameLevel(lvl + 6)
	art.sparkF = sf
	art.sparks = {}
	for i = 1, 9 do
		local t = sf:CreateTexture(nil, "OVERLAY", nil, (i <= 3) and 2 or 1)
		t:SetTexture(octoConstants.MEDIA .. ((i <= 3) and "Twinkle" or "Glow"))
		t:SetBlendMode("ADD")
		t:SetAlpha(0)
		t:Hide()
		t.cycle = -1
		art.sparks[i] = t
	end

	local o = CreateFrame("Frame", nil, f)
	o:SetAllPoints()
	o:SetFrameLevel(lvl + 6)
	c.over = o
	o.border = o:CreateTexture(nil, "ARTWORK")
	o.border:SetAllPoints()
	o.border:SetTexture(octoConstants.MEDIA .. "Frame1" .. sfx)
	o.border:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	-- (1.14.0, his idea) the metal of the frame of the titans in the colour of a pattern (TitanGold: its gold in grey, the same on the
	-- six frames; Card:PaintPattern)
	o.metal = o:CreateTexture(nil, "ARTWORK", nil, 1)
	o.metal:SetAllPoints()
	o.metal:SetTexture(octoConstants.MEDIA .. "TitanGold" .. sfx)
	o.metal:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	o.metal:Hide()
	o.gem = o:CreateTexture(nil, "OVERLAY")
	o.gem:SetTexture(octoConstants.MEDIA .. "Gem1")
	CuratorOctoFull.SetSize(o.gem, W * octoConstants.GEM_S, W * octoConstants.GEM_S)
	o.gem:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.GEM_Y)
	-- (1.12.0) the crest of a mythic card of Hallow's End: the skull of the bosses of the game, its spikes behind it
	-- (a client without them: the skull of the raid targets)
	o.crestBack = o:CreateTexture(nil, "OVERLAY", nil, 1)
	CuratorOctoFull.SetSize(o.crestBack, W * octoConstants.CREST_SPIKES[1], W * octoConstants.CREST_SPIKES[2])
	o.crestBack:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.CREST_SPIKES[3])
	o.crestBack.ok = S.Atlas(o.crestBack, "BossBanner-SkullSpikes")
	o.crestBack:Hide()
	o.crest = o:CreateTexture(nil, "OVERLAY", nil, 2)
	CuratorOctoFull.SetSize(o.crest, W * octoConstants.CREST_SKULL[1], W * octoConstants.CREST_SKULL[1])
	o.crest:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.CREST_SKULL[2])
	if not S.Atlas(o.crest, "BossBanner-SkullCircle") then
		o.crest:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
	end
	o.crest:Hide()
	-- (the other rarities: the pumpkin of the game, round, in the medallion of their crest)
	o.crestIcon = o:CreateTexture(nil, "OVERLAY", nil, 1)
	o.crestIcon:SetTexture(octoConstants.CREST_ICON)
	o.crestIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	o.crestMask = CuratorOctoFull.CreateMaskTexture(o)
	o.crestMask:SetTexture(octoConstants.ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	o.crestMask:SetAllPoints(o.crestIcon)
	CuratorOctoFull.AddMaskTexture(o.crestIcon, o.crestMask)
	o.crestIcon:Hide()
	o.set = o:CreateTexture(nil, "OVERLAY")
	o.set:SetTexture(octoConstants.MEDIA .. "SetElwynn")
	CuratorOctoFull.SetSize(o.set, W * 0.06, W * 0.06)
	o.set:SetPoint("CENTER", c, "TOPLEFT", W * octoConstants.SET_X, -H * octoConstants.NUM_Y)
	o.set:SetVertexColor(0.36, 0.24, 0.12, 0.85)

	-- level, in the medallion (white on the blue enamel, like the game's level circles)
	o.level = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.level, math.max(7, 13 * fs), "OUTLINE")
	o.level:SetPoint("CENTER", c, "TOPLEFT", W * octoConstants.MEDAL_X, -H * octoConstants.MEDAL_Y + 0.5)
	o.level:SetTextColor(1, 1, 1)
	-- name, on the ribbon
	o.name = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.name, math.max(8.5, 14 * fs))
	o.name:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.NAME_Y)
	o.name:SetWidth(W * octoConstants.NAME_W)
	CuratorOctoFull.SetWordWrap(o.name, false)
	o.name:SetJustifyH("CENTER")
	o.name:SetTextColor(1, 0.93, 0.78)
	o.name:SetShadowOffset(1, -1)
	o.name:SetShadowColor(0, 0, 0, 1)
	-- ink on the parchment
	o.sub = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.sub, math.max(7, 10 * fs))
	o.sub:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.TYPE_Y)
	o.sub:SetWidth(W * 0.78)
	CuratorOctoFull.SetWordWrap(o.sub, false)
	Ink(o.sub, octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	o.rar = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.rar, math.max(7.5, 11 * fs))
	o.rar:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.RAR_Y)
	Ink(o.rar, octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	o.num = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.num, math.max(6.5, 8.5 * fs))
	o.num:SetPoint("RIGHT", c, "TOPRIGHT", -W * octoConstants.NUM_X, -H * octoConstants.NUM_Y)
	Ink(o.num, 0.40, 0.29, 0.17)
	-- (1.14.0, his idea) the pattern of a titanforged copy, small, on the line of its number, after the mark of its album
	-- (Patterns.lua)
	o.pattern = o:CreateFontString(nil, "OVERLAY")
	o.patternSize = math.max(6, 7.5 * fs)
	ns.SetFont(o.pattern, o.patternSize)
	o.pattern:SetPoint("LEFT", c, "TOPLEFT", W * octoConstants.PATTERN_X, -H * octoConstants.NUM_Y)
	o.pattern:SetJustifyH("LEFT")
	Ink(o.pattern, 0.40, 0.29, 0.17)
	o.pattern:Hide()
	if small then
		o.sub:Hide()
	end
	-- (1.12.0, later) the plate of a limited edition: the name of its album, its year ("Hallow's End", "2026 Edition";
	-- a small card, the year only)
	-- (under the words of the card: they are in OVERLAY too)
	o.edition = o:CreateTexture(nil, "OVERLAY", nil, -1)
	o.edition:SetTexture(octoConstants.MEDIA .. "EditionPlate")
	local px = small and W * octoConstants.PLATE_X_S or 0
	CuratorOctoFull.SetSize(o.edition, W * (small and octoConstants.PLATE_W_S or octoConstants.PLATE_W), H * (small and octoConstants.PLATE_H_S or octoConstants.PLATE_H))
	o.edition:SetPoint("CENTER", c, "TOP", px, -H * octoConstants.NUM_Y)
	o.edition:Hide()
	o.edName = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.edName, math.max(6.5, 7.5 * fs))
	o.edName:SetPoint("CENTER", c, "TOP", 0, -H * octoConstants.NUM_Y + H * 0.0135)
	o.edName:SetWidth(W * octoConstants.PLATE_W * 0.84)
	CuratorOctoFull.SetWordWrap(o.edName, false)
	o.edName:SetTextColor(1, 0.74, 0.32)
	o.edName:SetShadowOffset(1, -1)
	o.edName:SetShadowColor(0, 0, 0, 1)
	o.edName:Hide()
	o.edYear = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.edYear, math.max(5.5, 6.2 * fs))
	o.edYear:SetPoint("CENTER", c, "TOP", px, -H * octoConstants.NUM_Y - (small and 0 or H * 0.0135))
	o.edYear:SetWidth(W * octoConstants.PLATE_W * 0.84)
	CuratorOctoFull.SetWordWrap(o.edYear, false)
	o.edYear:SetTextColor(1, 0.9, 0.7)
	o.edYear:SetShadowOffset(1, -1)
	o.edYear:SetShadowColor(0, 0, 0, 1)
	o.edYear:Hide()
	c.small = small

	-- missing card mark
	o.question = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.question, math.max(16, 44 * fs), "OUTLINE")
	o.question:SetPoint("CENTER", art, "CENTER", 0, 0)
	o.question:SetText("?")
	o.question:SetTextColor(1, 1, 1, 0.6)
	o.question:Hide()
	o.dim = o:CreateTexture(nil, "BACKGROUND")
	o.dim:SetAllPoints(art)
	CuratorOctoFull.ColorTexture(o.dim, 0, 0, 0, 0.3)
	o.dim:Hide()
	o.cover = o:CreateTexture(nil, "BACKGROUND", nil, 1)
	o.cover:SetAllPoints(art)
	CuratorOctoFull.ColorTexture(o.cover, 0.03, 0.035, 0.05, 1)
	o.cover:Hide()

	-- badges
	local badge = CreateFrame("Frame", nil, c)
	badge:SetFrameLevel(lvl + 8)
	-- red leather pennant (256 x 96 texture), its body spans 44..246 px
	local bw = W * 0.52
	CuratorOctoFull.SetSize(badge, bw, bw * 96 / 256)
	badge:SetPoint("CENTER", c, "TOPRIGHT", -bw * 0.38, -H * 0.075)
	badge.tex = badge:CreateTexture(nil, "ARTWORK")
	badge.tex:SetAllPoints()
	badge.tex:SetTexture(octoConstants.MEDIA .. "TagNew")
	badge.text = badge:CreateFontString(nil, "OVERLAY")
	ns.SetFont(badge.text, math.max(7, 9.5 * fs), "")
	badge.text:SetPoint("CENTER", bw * (145 / 256 - 0.5), 0.5)
	badge.text:SetTextColor(1, 0.95, 0.82)
	badge.text:SetShadowOffset(1, -1)
	badge.text:SetShadowColor(0, 0, 0, 1)
	badge.text:SetText(L["New!"])
	badge:Hide()
	c.badge = badge
	o.count = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.count, math.max(8, 12 * fs), "OUTLINE")
	o.count:SetPoint("BOTTOMLEFT", c, "TOPLEFT", W * octoConstants.ART_L + 5, -H * octoConstants.COUNT_Y)
	o.count:SetTextColor(1, 0.95, 0.85)
	-- (1.12.0) the corruption of a corrupted card, in the violet of the Void
	o.corrupt = o:CreateFontString(nil, "OVERLAY")
	ns.SetFont(o.corrupt, math.max(8, 12 * fs), "OUTLINE")
	o.corrupt:SetPoint("BOTTOMRIGHT", c, "TOPRIGHT", -W * octoConstants.ART_R - 5, -H * octoConstants.COUNT_Y)
	o.corrupt:SetTextColor(0.8, 0.48, 1)
	o.corrupt:SetText("")
	-- (1.8.0) the signature of an innkeeper, friend of the house, across the foot of the picture: in gold
	-- ink, as on a photo, its shadow under it (Inns.lua)
	local aw0 = W * (1 - octoConstants.ART_L - octoConstants.ART_R)
	local sw = aw0 * 0.86
	local sx = (aw0 - sw) / 2 + W * 0.02
	o.signW = sw
	o.signShade = o:CreateTexture(nil, "OVERLAY", nil, 1)
	CuratorOctoFull.SetSize(o.signShade, sw, sw / 2)
	o.signShade:SetPoint("BOTTOMLEFT", art, "BOTTOMLEFT", sx + 1, H * 0.01 - 1)
	o.signShade:SetVertexColor(0, 0, 0, 0.75)
	o.signShade:Hide()
	o.sign = o:CreateTexture(nil, "OVERLAY", nil, 2)
	CuratorOctoFull.SetSize(o.sign, sw, sw / 2)
	o.sign:SetPoint("BOTTOMLEFT", art, "BOTTOMLEFT", sx, H * 0.01)
	o.sign:SetVertexColor(1, 0.86, 0.5, 0.95)
	o.sign:Hide()

	-- finishes, clipped to the card: twinkles and a sweep of light over a thunderforged or titanforged
	-- card; the best cards (epic and up) catch the light now and then.
	local sh = CreateFrame("Frame", nil, c)
	sh:SetAllPoints()
	CuratorOctoFull.SetClipsChildren(sh, true)
	sh:SetFrameLevel(lvl + 7)
	sh.mask = CuratorOctoFull.CreateMaskTexture(sh)
	sh.mask:SetTexture(octoConstants.MEDIA .. "CardMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	sh.mask:SetAllPoints(c)
	-- (1.3: every finish is forged, the shiny and holographic cards of the zones too.) Thunderforged:
	-- lightning crawling over the card (two drawings of it, that flicker) and a cold light along its edge.
	-- Titanforged (1.11.0): a frame of its own, as a jeweller would make it (TitanFrame: enamel of the colour
	-- of its rarity over a guilloche, set in polished gold, diamonds), a foil of prism over its frame (fine rays
	-- of all the colours out of the middle of its guilloche, and facets) whose light goes round the card and
	-- whose colours flow with the angle of the card, a dust of stars that glitters, its diamonds that sparkle,
	-- a light along its edge that turns through the colours; its creature stands over a foil of its own (in the
	-- window, under it), in the light of the prism.
	sh.rim = sh:CreateTexture(nil, "ARTWORK", nil, 3)
	sh.rim:SetAllPoints()
	sh.rim:SetTexture(octoConstants.MEDIA .. "CardRim")
	sh.rim:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.rim:SetBlendMode("ADD")
	-- (the foil: the same rays and facets in the three textures, each of them lit on its own third of the card
	-- and a third of the rainbow further; shown together by weights that turn with the angle, Card:Holo. How much
	-- of it shows where is in the textures themselves: the enamel all of it, the ribbon and the gold less, the
	-- window of the creature none, the panel of the words a breath. (Its first build gave it to a mask; the
	-- client drew it over the creature and the words all the same.))
	sh.prism = {}
	for i = 1, 3 do
		local f = sh:CreateTexture(nil, "ARTWORK", nil, 1)
		f:SetAllPoints()
		f:SetTexture(octoConstants.MEDIA .. "TitanPrism" .. i .. sfx)
		f:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
		f:SetBlendMode("ADD")
		sh.prism[i] = f
	end
	-- (its dust: two veils of stars over the frame, the card as the frames are; Card:Dust)
	sh.glitter = {}
	for i = 1, 2 do
		local g = sh:CreateTexture(nil, "ARTWORK", nil, 6)
		g:SetAllPoints()
		g:SetTexture(octoConstants.MEDIA .. "TitanDust" .. i .. sfx)
		g:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
		g:SetBlendMode("ADD")
		sh.glitter[i] = g
	end
	sh.arcs = {}
	for i = 1, 2 do
		local t = sh:CreateTexture(nil, "ARTWORK", nil, 5)
		t:SetAllPoints()
		t:SetTexture(octoConstants.MEDIA .. "ThunderArcs" .. i)
		t:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
		t:SetBlendMode("ADD")
		sh.arcs[i] = t
	end
	-- (1.14.0) the contraband of the Hardcup Saison 3: the embers in the cracks of its iron alight (SmuggleFx: their light
	-- alone), breathing as a fire under ash (Card:Smoulder)
	sh.embers = sh:CreateTexture(nil, "ARTWORK", nil, 4)
	sh.embers:SetAllPoints()
	sh.embers:SetTexture(octoConstants.MEDIA .. "SmuggleFx" .. sfx)
	sh.embers:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.embers:SetBlendMode("ADD")
	sh.embers:Hide()
	sh.twinkles = {}
	for i = 1, 4 do
		local tw = sh:CreateTexture(nil, "OVERLAY", nil, 1)
		tw:SetTexture(octoConstants.MEDIA .. "Twinkle")
		tw:SetBlendMode("ADD")
		tw:SetAlpha(0)
		tw.cycle = -1
		sh.twinkles[i] = tw
	end
	sh.sheen = sh:CreateTexture(nil, "OVERLAY")
	sh.sheen:SetTexture(octoConstants.MEDIA .. "Sheen")
	sh.sheen:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(sh.sheen, H * 2, H * 2)
	sh.sheen:SetPoint("CENTER")
	CuratorOctoFull.AddMaskTexture(sh.sheen, sh.mask)
	-- (1.12.0) a corrupted card (an album of an event): the Void drowning its frame at 100 %, the eyes of N'Zoth that
	-- open on it (from 60 %, more from 80 %) (Card:SetCorruption); (1.12.0, later) as the corrupted gear of Visions of
	-- N'Zoth showed it on the characters: stains of the Void that creep over it from its edges, deep blue and black
	-- (sh.void: CorruptStain1..4, a stage from 1 %, 40, 60, 80 %), the veins of electric light that run through them and
	-- burn along their edge (sh.glow: CorruptGlow1..4, in light; both in the red of N'Zoth from 80 %), the stage
	-- before under them while the next spreads (sh.voidOld, sh.glowOld); the motes of the Void that rise from them
	-- (sh.motes, not on a small card)
	sh.voidFull = sh:CreateTexture(nil, "ARTWORK", nil, 2)
	sh.voidFull:SetAllPoints()
	sh.voidFull:SetTexture(octoConstants.MEDIA .. "CorruptFull" .. sfx)
	sh.voidFull:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.voidFull:Hide()
	sh.void = sh:CreateTexture(nil, "ARTWORK", nil, 1)
	sh.void:SetAllPoints()
	sh.void:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.void:Hide()
	sh.voidOld = sh:CreateTexture(nil, "ARTWORK", nil, 0)
	sh.voidOld:SetAllPoints()
	sh.voidOld:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.voidOld:Hide()
	sh.glow = sh:CreateTexture(nil, "ARTWORK", nil, 3)
	sh.glow:SetAllPoints()
	sh.glow:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.glow:SetBlendMode("ADD")
	sh.glow:Hide()
	sh.glowOld = sh:CreateTexture(nil, "ARTWORK", nil, 3)
	sh.glowOld:SetAllPoints()
	sh.glowOld:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	sh.glowOld:SetBlendMode("ADD")
	sh.glowOld:Hide()
	sh.motes = {}
	if not small then
		for i = 1, 7 do
			local t = sh:CreateTexture(nil, "OVERLAY", nil, 1)
			t:SetTexture(octoConstants.MEDIA .. "Glow")
			t:SetBlendMode("ADD")
			t:SetAlpha(0)
			t:Hide()
			sh.motes[i] = t
		end
	end
	sh.eyes = {}
	for i = 1, 2 do
		local t = sh:CreateTexture(nil, "ARTWORK", nil, 4)
		t:SetAllPoints()
		t:SetTexture(octoConstants.MEDIA .. "CorruptEyes" .. i .. sfx)
		t:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
		t:Hide()
		sh.eyes[i] = t
	end
	-- (1.12.0) the cards of Hallow's End: bats that fly across their window now and then (Card:Haunt; two
	-- drawings of a bat side by side, its wings up and down)
	sh.bats = {}
	for i = 1, 2 do
		local bat = sh:CreateTexture(nil, "OVERLAY", nil, 2)
		bat:SetTexture(octoConstants.MEDIA .. "Bat")
		bat:SetTexCoord(0, 0.5, 0, 1)
		bat:SetAlpha(0)
		bat:Hide()
		sh.bats[i] = bat
	end
	sh:Hide()
	c.shine = sh

	-- back
	-- (his idea, 31 October: the wear of its copy, UI/Wear.lua; on the card itself, over all that is printed on it, its
	-- pennant too, under its back and its case)
	c.wearF = CreateFrame("Frame", nil, c)
	c.wearF:SetAllPoints()
	c.wearF:SetFrameLevel(lvl + 9)
	c.wearF:Hide()
	c.wearFlip, c.wearTurn = {}, {}

	local b = CreateFrame("Frame", nil, c)
	b:SetAllPoints()
	b:SetFrameLevel(lvl + 10)
	b.tex = b:CreateTexture(nil, "ARTWORK")
	b.tex:SetAllPoints()
	b.tex:SetTexture(octoConstants.MEDIA .. "Back" .. sfx)
	b.tex:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	b.glow = b:CreateTexture(nil, "OVERLAY")
	b.glow:SetAllPoints()
	b.glow:SetTexture(octoConstants.MEDIA .. "CardRim")
	b.glow:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	b.glow:SetBlendMode("ADD")
	b.glow:SetAlpha(0)
	-- the gem in the middle of the back lights up in the colour of the card, the light breaks
	-- through the back before it is turned over, and a reflection follows the mouse over it
	b.core = b:CreateTexture(nil, "ARTWORK", nil, 2)
	b.core:SetTexture(octoConstants.MEDIA .. "Glow")
	b.core:SetBlendMode("ADD")
	b.core:SetPoint("CENTER")
	CuratorOctoFull.SetSize(b.core, W * 0.7, W * 0.7)
	b.core:SetAlpha(0)
	b.cracks = b:CreateTexture(nil, "ARTWORK", nil, 3)
	b.cracks:SetAllPoints()
	b.cracks:SetTexture(octoConstants.MEDIA .. "CardCracks")
	b.cracks:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
	b.cracks:SetBlendMode("ADD")
	b.cracks:SetAlpha(0)
	b.mask = CuratorOctoFull.CreateMaskTexture(b)
	b.mask:SetTexture(octoConstants.MEDIA .. "CardMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	b.mask:SetAllPoints(c)
	b.sheen = b:CreateTexture(nil, "OVERLAY", nil, 1)
	b.sheen:SetTexture(octoConstants.MEDIA .. "Sheen")
	b.sheen:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(b.sheen, H * 1.6, H * 1.6)
	b.sheen:SetPoint("CENTER")
	b.sheen:SetAlpha(0)
	CuratorOctoFull.AddMaskTexture(b.sheen, b.mask)
	b:Hide()
	c.back = b

	-- over both sides: the card white-hot for an instant (when it is turned over, when its light
	-- swells)
	local hot = CreateFrame("Frame", nil, c)
	hot:SetAllPoints()
	hot:SetFrameLevel(lvl + 11)
	hot.tex = hot:CreateTexture(nil, "OVERLAY")
	hot.tex:SetAllPoints()
	hot.tex:SetTexture(octoConstants.MEDIA .. "CardMask")
	hot.tex:SetBlendMode("ADD")
	hot.tex:SetAlpha(0)
	c.hot = hot.tex

	for k, v in pairs(Card) do
		if k ~= "__index" then
			c[k] = v
		end
	end
	c.facing = "front"
	return c
end

-------------------------------------------------------------------------------
-- Content
-------------------------------------------------------------------------------

local function LevelShort(card)
	-- (1.13.0: a participant of the Hardcup Saison 3, a picture: no level)
	if card.art and card.art.fill then
		return ""
	end
	if card.lo == card.hi then
		return tostring(card.lo)
	end
	return card.lo .. "-" .. card.hi
end

-- opts: owned (default true), shiny, count, new, facing
function Card:SetCard(card, opts)
	opts = opts or {}
	-- (held in the hand: put down, then held again as it was, with what it shows now)
	local pose = self.held and { self.heldYaw or 0, self.heldPitch or 0 }
	if pose then
		self:Hold(false)
	end
	self.animWait = nil
	self.card, self.opts = card, opts
	local r = ns.RARITY[card.rarity]
	local owned = opts.owned ~= false
	local o, art, m = self.over, self.art, self.model
	local s = card.series
	local fs = self.H / 252
	-- (1.14.0) the contraband of the Hardcup Saison 3 (RVN, Curator Hardcup 1.0.2): a mythic card here, in the look of the
	-- contraband: its frame of blackened iron, its gem, its parchment charred, its words light on it, its embers
	local smuggle = card.smuggle == true
	o.border:SetTexture(octoConstants.MEDIA .. (smuggle and "Frame7" or ("Frame" .. card.rarity)) .. self.sfx)
	o.gem:SetTexture(octoConstants.MEDIA .. (smuggle and "GemSmuggle" or ("Gem" .. card.rarity)))
	self.front.base:SetTexture(octoConstants.MEDIA .. (smuggle and "BodySmuggle" or "Body") .. self.sfx)
	if smuggle then
		Ink(o.sub, 0.86, 0.78, 0.74)
	else
		Ink(o.sub, octoConstants.INK[1], octoConstants.INK[2], octoConstants.INK[3])
	end
	o.set:SetTexture(octoConstants.MEDIA .. (s.set or "SetElwynn"))
	art.bg:SetTexture(octoConstants.MEDIA .. (s.studio or "StudioElwynn"))
	art.bg:SetTexCoord(unpack(self.artCrop))
	local missing = not owned
	Grey(self.front.base, missing, 0.5)
	Grey(o.border, missing, 0.55)
	Grey(o.gem, missing, 0.45)
	Grey(art.bg, missing, 0.62)
	if missing then
		o.set:SetVertexColor(0.2, 0.2, 0.2, 0.6)
	else
		o.set:SetVertexColor(0.36, 0.24, 0.12, 0.85)
	end
	if card.rarity >= 4 and owned then
		local g = smuggle and octoConstants.SMUGGLE_GLOW or r.glow
		art.rays:SetVertexColor(g[1], g[2], g[3])
		art.rays.base = (card.rarity >= 6 and 0.55) or (card.rarity == 5 and 0.5) or 0.28
		art.rays:SetAlpha(art.rays.base)
		art.rays:Show()
	else
		art.rays:Hide()
	end
	CuratorOctoFull.SetShown(art.rays2, card.rarity >= 6 and owned)
	-- (the second wheel: the gold of the mythic cards, the dark red of the contraband)
	if smuggle then
		art.rays2:SetVertexColor(0.55, 0.04, 0.06)
	else
		art.rays2:SetVertexColor(1, 0.78, 0.36)
	end
	-- texts
	local lvl = owned and LevelShort(card) or "?"
	ns.SetFont(o.level, math.max(7, ((CuratorOctoFull.Length(lvl) > 2) and 10 or 13) * fs), "OUTLINE")
	o.level:SetText(lvl)
	if missing then
		o.level:SetTextColor(0.62, 0.62, 0.62)
	else
		o.level:SetTextColor(1, 1, 1)
	end
	-- (SetName sets the font before the text: the client refuses text on a font string without one)
	SetName(o.name, owned and C:Name(card) or "???", math.max(8.5, 14 * fs), 7, self.H * octoConstants.NAME_H, self.W * octoConstants.NAME_W)
	if missing then
		o.name:SetTextColor(0.58, 0.58, 0.58)
	else
		o.name:SetTextColor(1, 0.93, 0.78)
	end
	-- the line under the name: smaller when it is long (the longest titles of the characters)
	local subSize = math.max(7, 10 * fs)
	ns.SetFont(o.sub, subSize)
	o.sub:SetText(owned and C:TypeLine(card) or "")
	while subSize > 7 and ns.TextWidth(o.sub) > self.W * 0.78 do
		subSize = subSize - 0.5
		ns.SetFont(o.sub, subSize)
	end
	o.rar:SetText(smuggle and L["Contraband"] or L[r.label])
	o.num:SetText(string.format(("%d/%d"), card.num, s.official or CuratorOctoFull.Length(s.list)))
	if missing then
		o.rar:SetTextColor(0.16, 0.16, 0.16)
		o.num:SetTextColor(0.16, 0.16, 0.16)
	elseif smuggle then
		o.rar:SetTextColor(0.96, 0.36, 0.3)
		o.num:SetTextColor(0.74, 0.58, 0.54)
	else
		o.rar:SetTextColor(r.ink[1], r.ink[2], r.ink[3])
		o.num:SetTextColor(0.40, 0.29, 0.17)
	end
	CuratorOctoFull.SetShown(o.question, not owned)
	CuratorOctoFull.SetShown(o.dim, not owned)
	-- (1.12.0, later) a card of an album of an event, a limited edition: its plate (the year of the edition)
	self:PaintEdition(card, missing)
	-- (1.8.0) a card signed for the collector by its innkeeper (opts.signed)
	local sign = owned and opts.signed and ns.Inns and ns.Inns:Signature(card.npc) or nil
	if sign then
		o.sign:SetTexture(sign)
		o.signShade:SetTexture(sign)
		self:SignatureShown(1)
	end
	CuratorOctoFull.SetShown(o.sign, sign ~= nil)
	CuratorOctoFull.SetShown(o.signShade, sign ~= nil)
	-- (1.8.0) a picture of its own (card.art = { file, coords, aspect, icon }): a whole character standing
	-- at the foot of the window, or an icon in its middle
	local pic = art.pic
	if card.art and card.art.fill then
		-- (1.13.0, the Hardcup Saison 3: the picture of a participant fills the window of his card, its middle kept, a
		-- little more of its top, where the face is; none while the card is not found: its question mark alone)
		local aw, ah = self.W * octoConstants.ART_W, self.H * octoConstants.ART_H
		pic:SetTexture(card.art.file)
		local ratio = aw / ah
		if ratio >= 1 then
			local v = 1 / ratio
			local top = (1 - v) * 0.35
			pic:SetTexCoord(0, 1, top, top + v)
		else
			local u = ratio
			pic:SetTexCoord((1 - u) / 2, (1 + u) / 2, 0, 1)
		end
		pic:ClearAllPoints()
		pic:SetAllPoints(art)
		CuratorOctoFull.SetDesaturated(pic, false)
		pic:SetVertexColor(1, 1, 1)
		CuratorOctoFull.SetShown(pic, owned)
	elseif card.art then
		pic:SetTexture(card.art.file)
		pic:SetTexCoord(unpack(card.art.coords or { 0, 1, 0, 1 }))
		pic:ClearAllPoints()
		local aw, ah = self.W * octoConstants.ART_W, self.H * octoConstants.ART_H
		if card.art.icon then
			local sz = math.min(aw, ah) * 0.62
			CuratorOctoFull.SetSize(pic, sz, sz)
			pic:SetPoint("CENTER", art, "CENTER", 0, 0)
		else
			-- (as tall as the window, else as wide: a weapon held out stays in it)
			local aspect = card.art.aspect or 0.5
			local h = ah * 0.98
			local w = h * aspect
			if w > aw * 0.98 then
				w = aw * 0.98
				h = w / aspect
			end
			CuratorOctoFull.SetSize(pic, w, h)
			pic:SetPoint("BOTTOM", art, "BOTTOM", 0, 0)
		end
		Grey(pic, missing, 0.6)
		pic:Show()
	else
		pic:Hide()
	end
	-- (31 October, his idea: the creatures in 2D) its portrait when the studio took it (a card not found yet: its black
	-- shape, as its creature was); its creature then not loaded (UI/Inspect.lua: shown in 3D on asking)
	local por = not card.art and ns.Portraits and card.display and ns.Portraits[card.display] or nil
	local pt = art.portrait
	self.portraitOn = por ~= nil
	-- (its creature in 3D, asked for this card only: UI/Inspect.lua, I:Live3D)
	if self.liveCard ~= card then
		self.live3D, self.liveCard = nil, nil
	end
	if por then
		pt:SetTexture(octoConstants.MEDIA .. "Portraits\\" .. card.display, "CLAMP", "CLAMP")
		pt:SetTexCoord(por[1], por[2], por[3], por[4])
		local v = owned and 1 or 0
		pt:SetVertexColor(v, v, v)
		CuratorOctoFull.SetShown(pt, not self.live3D)
	else
		pt:Hide()
	end
	if self.see3D then
		CuratorOctoFull.SetShown(self.see3D, por ~= nil and owned and ns.Can3D())
		self.see3D:SetText(L[self.live3D and "See the card" or "See in 3D"])
	end
	-- the creature
	m.display = (not por or self.live3D) and card.display and card.display > 0 and card.display or nil
	m.silhouette = not owned
	m.facing = opts.facing or 0.4
	m.pendingAnim = nil
	self:ReloadModel()
	-- extras
	local b = self.back
	b.core:SetAlpha(0)
	b.cracks:SetAlpha(0)
	b.sheen:SetAlpha(0)
	-- (1.12.0) its back, the one of the opening of its booster (wherever it is turned over: in the hand, in the album,
	-- in the window of a card of the chat)
	self:SetBack(card)
	self.hot:SetAlpha(0)
	self:SetFinish()
	CuratorOctoFull.SetShown(self.badge, opts.new and true or false)
	if owned and opts.count and opts.count > 1 and not opts.new then
		o.count:SetText("x" .. opts.count)
	else
		o.count:SetText("")
	end
	if pose then
		self:SetPose(pose[1], pose[2])
	end
end

-- (1.14.0) Its finish shown again (another copy of it shown: UI/Copies.lua, CU:Apply; its pattern), held in the hand
-- too: put down, then held again as it was, with what it shows now (as Card:SetCard does).
function Card:Refinish()
	local pose = self.held and { self.heldYaw or 0, self.heldPitch or 0 }
	if pose then
		self:Hold(false)
	end
	self:SetFinish()
	if pose then
		self:SetPose(pose[1], pose[2])
	end
end

-- (1.8.0) How much of the signature shows (0 to 1, from its left: the hand that writes it).
function Card:SignatureShown(k)
	local o = self.over
	k = math.max(0.001, math.min(1, k or 1))
	for _, t in ipairs({ o.sign, o.signShade }) do
		t:SetTexCoord(0, k, 0, 1)
		t:SetWidth(o.signW * k)
	end
end

-- The signature written as one watches, in dur seconds (then done()).
function Card:WriteSignature(dur, done, owner)
	self:SignatureShown(0)
	ns.Tween(dur or 1.4, function(e)
		self:SignatureShown(e)
	end, function()
		self:SignatureShown(1)
		if done then
			done()
		end
	end, ns.Ease and ns.Ease.inOutQuad, owner or self)
end

-- Loads the creature again: a model frame lets go of its model while hidden.
function Card:ReloadModel()
	local m = self.model
	self.needModel = false
	m.loaded = false
	if m.actor then
		Load(m)
	elseif m.display and m.SetDisplayInfo then
		m:ClearModel()
		m:SetDisplayInfo(m.display)
		ApplyModelLook(m)
		if m.SetAnimation then m:SetAnimation(0) end
		if not m.hasLoadScript then m.loaded = true end
	else
		m:ClearModel()
	end
end

-- The option of the creatures as a still picture switched (UI/Options.lua): every card made, at once.
function ns.ApplyStillCards()
	for c in pairs(ns.AllCards) do
		local m = c.model
		if m and m.SetPaused then
			pcall(m.SetPaused, m, (c.frozen or m.silhouette or Still()) and true or false)
		end
	end
end

-- Only one side is drawn at a time: a card fading in face down must not let its face
-- (or its creature, or its shiny finish) show through the back.
-- deferModel: the face is still squeezed by a flip, the creature is loaded once it is wide again.
function Card:ApplySide(deferModel)
	local front = self.facing ~= "back"
	CuratorOctoFull.SetShown(self.back, not front)
	local f = self.front
	if front and not f:IsShown() then
		f:Show()
		if deferModel then
			self.needModel = true
		else
			self:ReloadModel()
		end
	elseif not front and f:IsShown() then
		f:Hide()
		self.model.pendingAnim = nil
	end
	self:SetFinish()
	if self.held then
		self:HeldSync()
	end
end

-- (1.12.0) The back of a card: the one of the opening of its booster. Of the night for Hallow's End (BackHallow; what
-- glows on it, the face of its jack-o'-lantern, BackHallowFace: warm as a candle, in the colour of the card for the best
-- ones), of the dungeons for the dungeons and the raids (BackDungeon), else the back of the boosters of the zones (Back).
-- In a booster, its scene lights what glows on it after this (UI/Booster.lua, UI/HallowLair.lua).
octoConstants.BACK_CANDLE = { 1, 0.6, 0.2 }
function Card:SetBack(card)
	local s = card and card.series
	local b = self.back
	local look = (s and s.look == "hallow" and "hallow") or (s and s.dungeon and "dungeon") or "zone"
	if look == "hallow" then
		b.tex:SetTexture(octoConstants.MEDIA .. "BackHallow" .. self.sfx)
		b.cracks:SetTexture(octoConstants.MEDIA .. "BackHallowFace" .. self.sfx)
		local col = ((card.rarity or 1) >= 4 and ns.RARITY[card.rarity] and ns.RARITY[card.rarity].glow) or octoConstants.BACK_CANDLE
		b.cracks:SetVertexColor(col[1], col[2], col[3])
		b.cracks:SetAlpha(0.2)
	else
		b.tex:SetTexture(octoConstants.MEDIA .. (look == "dungeon" and "BackDungeon" or ("Back" .. self.sfx)))
		b.cracks:SetTexture(octoConstants.MEDIA .. "CardCracks")
		b.cracks:SetVertexColor(1, 1, 1)
	end
	self.backLook = look
end

-- The finish shown: opts.finish ("shiny", "holo"), or the older opts.shiny / opts.holo.
function Card:Finish()
	local o = self.opts or {}
	if o.owned == false then
		return nil
	end
	return o.finish or (o.holo and "holo") or (o.shiny and "shiny") or nil
end

-- The colour of the twinkles and of the sweep of light, by look.
octoConstants.TINT = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.9, 0.66 }, hallow = { 1, 0.56, 0.16 }, smuggle = { 1, 0.3, 0.24 } }
octoConstants.NO_TINT = { 1, 1, 1 }

-- (1.12.0) The cards of Hallow's End, by rarity: the light along their edge (its colour, how bright), what moves on
-- them (fx: the two drawings of HallowFx<rarity>_1/_2, in light; flame: they flicker as a fire, else they drift as
-- ghosts), the bats that fly across their window (how many at most, how often), their sparks (their colour; none:
-- no sparks).
octoConstants.HALLOW = {
	[1] = { rim = { 0.62, 0.68, 0.64 }, a = 0.06, bats = 0 },
	[2] = { rim = { 0.42, 1, 0.32 }, a = 0.2, fx = true, bats = 0 },
	[3] = { rim = { 0.45, 0.74, 1 }, a = 0.24, fx = true, bats = 1, every = 9 },
	[4] = { rim = { 0.74, 0.42, 1 }, a = 0.28, fx = true, bats = 2, every = 7.5, spark = { 0.85, 0.6, 1 } },
	[5] = { rim = { 1, 0.52, 0.1 }, a = 0.34, fx = true, flame = true, bats = 2, every = 6, spark = { 1, 0.62, 0.2 } },
	[6] = { rim = { 1, 0.18, 0.2 }, a = 0.4, fx = true, flame = true, bats = 2, every = 5, spark = { 1, 0.35, 0.25 }, skull = true },
}
Card.HALLOW = octoConstants.HALLOW

-- Sets the finish layer: shown on the face of a card owned that is thunderforged or titanforged, or of
-- the best rarities (a glint of light now and then).
function Card:SetFinish()
	local sh = self.shine
	if ns.WearUI then
		ns.WearUI.Set(self, (self.opts or {}).wear, self.facing ~= "back")
	end
	local finish = self:Finish()
	local look = finish and C:FinishLook(self.card, finish) or nil
	-- (1.12.0) a corrupted card: the look of its album (Hallow's End), its corruption over it (Card:SetCorruption)
	local corrupt = 0
	local unknown = false
	if look == "corrupt" then
		look = nil
		local op = self.opts or {}
		if op.creep ~= nil then
			-- (a corrupted card turned over in a booster: as much as has spread over it yet, B:VoidWake)
			corrupt = math.max(0, math.floor(tonumber(op.creep) or 0))
		elseif op.corruptUnknown then
			-- (1.14.0: a corrupted copy asked for in a trade, its copy not chosen yet: its corruption not known, "?")
			corrupt, unknown = C.CORRUPT_MIN, true
		else
			corrupt = math.floor(tonumber(op.corrupt) or C:Corruption(self.card))
			if corrupt <= 0 then
				corrupt = C.CORRUPT_MIN
			end
		end
	end
	self:SetCorruption(corrupt, self.spreadTw ~= nil)
	if unknown and self.over and self.over.corrupt and self.facing ~= "back" then
		self.over.corrupt:SetText("?")
	end
	local owned = (self.opts or {}).owned ~= false
	local glint = not finish and self.card and self.card.rarity >= 4 and owned
	-- (1.12.0) a card of Hallow's End: its frame of the night, whatever its finish; without one, the light of a
	-- pumpkin flickers on it and its bats fly
	local hallow = self.card ~= nil and self.card.series ~= nil and self.card.series.look == "hallow"
	sh.kind = look or ((hallow and owned) and "hallow") or (glint and "glint") or nil
	-- (1.14.0) the contraband of the Hardcup Saison 3, found: its embers breathe whatever its finish; without one, its edge
	-- in their red (its look: "smuggle")
	local smuggle = self.card ~= nil and self.card.smuggle == true and owned
	sh.smuggle = smuggle or nil
	CuratorOctoFull.SetShown(sh.embers, smuggle)
	if smuggle and not look then
		sh.kind = "smuggle"
	end
	-- (1.11.0) a titanforged card wears the frame of the titans, of the colour of its rarity; its creature stands
	-- over a foil of its own, in the light of the prism (1.14.0: the contraband, its own: Frame7, TitanFrame7)
	if self.card then
		local frame = (hallow and "HallowFrame") or ((look == "titan") and "TitanFrame") or "Frame"
		self.over.border:SetTexture(octoConstants.MEDIA .. frame .. ((self.card.smuggle and not hallow) and 7 or self.card.rarity) .. self.sfx)
	end
	self:SetCrest()
	self:TitanWindow(look == "titan")
	-- (1.14.0, his idea) the pattern of a titanforged copy (opts.pattern): its look, its number written on it (Patterns.lua)
	local pat = (look == "titan" and ns.Patterns and ns.Patterns:Look((self.opts or {}).pattern)) or nil
	if pat or self.pat then
		self.pat = pat
		-- (the metal: on the frame of the titans only, not on the one of Hallow's End nor on the iron of the contraband)
		self:PaintPattern(pat, not hallow and not (self.card and self.card.smuggle))
	end
	if self.facing == "back" or not sh.kind then
		sh:Hide()
		return
	end
	CuratorOctoFull.SetShown(sh.rim, look == "thunder" or look == "titan" or sh.kind == "hallow" or sh.kind == "smuggle")
	-- (1.12.0) a card of Hallow's End: the look of its rarity
	local hd = sh.kind == "hallow" and (octoConstants.HALLOW[self.card.rarity] or octoConstants.HALLOW[1]) or nil
	sh.hallow = hd
	for i, bat in ipairs(sh.bats) do
		CuratorOctoFull.SetShown(bat, hd ~= nil and i <= hd.bats)
		bat:SetAlpha(0)
		bat.flight = nil
	end
	-- (the two layers of the lightning of a thunderforged card carry what moves on a card of Hallow's End)
	for i = 1, 2 do
		local arc = sh.arcs[i]
		if hd and hd.fx then
			arc:SetTexture(octoConstants.MEDIA .. "HallowFx" .. self.card.rarity .. "_" .. i .. self.sfx)
			arc:SetAlpha(0)
			arc.hallow = true
		elseif arc.hallow then
			arc:SetTexture(octoConstants.MEDIA .. "ThunderArcs" .. i)
			arc.hallow = nil
		end
	end
	CuratorOctoFull.SetShown(sh.arcs[1], look == "thunder" or (hd ~= nil and hd.fx == true))
	CuratorOctoFull.SetShown(sh.arcs[2], look == "thunder" or (hd ~= nil and hd.fx == true))
	for _, f in ipairs(sh.prism) do
		CuratorOctoFull.SetShown(f, look == "titan")
	end
	CuratorOctoFull.SetShown(sh.glitter[1], look == "titan")
	CuratorOctoFull.SetShown(sh.glitter[2], look == "titan")
	local tint = (hd and (hd.spark or hd.rim)) or octoConstants.TINT[look or sh.kind] or octoConstants.NO_TINT
	for _, tw in ipairs(sh.twinkles) do
		CuratorOctoFull.SetShown(tw, look ~= nil or (hd ~= nil and hd.spark ~= nil))
		tw:SetVertexColor(tint[1], tint[2], tint[3])
		tw.cycle = -1
	end
	sh.sheen:SetVertexColor(tint[1], tint[2], tint[3])
	if look == "thunder" then
		sh.rim:SetVertexColor(0.42, 0.68, 1)
		sh.rim:SetAlpha(0.4)
		sh.arcs[1]:SetAlpha(0)
		sh.arcs[2]:SetAlpha(0)
	elseif look == "titan" then
		sh.rim:SetVertexColor(1, 0.74, 0.3)
		sh.rim:SetAlpha(0.24)
		sh.holoT, sh.hx, sh.hy, sh.dustPh = nil, 0, 0, nil
		self:Holo(sh, self.tickT or 0)
		-- (1.14.0, his idea) its twinkles and its sweep in the light of its pattern
		local s = pat and pat.spark
		if s then
			for _, tw in ipairs(sh.twinkles) do
				tw:SetVertexColor(s[1], s[2], s[3])
			end
			sh.sheen:SetVertexColor(s[1], s[2], s[3])
		end
	elseif hd then
		sh.rim:SetVertexColor(hd.rim[1], hd.rim[2], hd.rim[3])
		sh.rim:SetAlpha(hd.a)
	elseif sh.kind == "smuggle" then
		sh.rim:SetVertexColor(0.95, 0.12, 0.08)
		sh.rim:SetAlpha(0.3)
	end
	if smuggle then
		sh.embers:SetAlpha(0.6)
	end
	sh:Show()
end

-- (31 October, his wish: titanforged copies always different) The texture of a variant of a foil of a titanforged
-- card: 1 the ones of before (TitanWindow1..3, TitanPrism1..3, TitanDust1..2), else Media\\Holo (W, P, D: the window,
-- the frame, the dust; its number on two digits, the texture of it).
octoConstants.HOLO_OLD = { W = "TitanWindow", P = "TitanPrism", D = "TitanDust" }
function Card.HoloFile(kind, v, i, sfx)
	if not v or v <= 1 then
		return octoConstants.MEDIA .. octoConstants.HOLO_OLD[kind] .. i .. (sfx or "")
	end
	return octoConstants.MEDIA .. "Holo\\" .. kind .. string.format(("%02d"), v) .. "_" .. i
end

-- Its foils: those of that variant of the window, of the frame and of the dust (set once for each).
function Card:HoloSet(wv, pv, dv)
	local sh, art = self.shine, self.art
	local key = wv .. "." .. pv .. "." .. dv
	if self.holoKey == key then
		return
	end
	self.holoKey = key
	for i, t in ipairs(art.foil) do
		t:SetTexture(Card.HoloFile("W", wv, i, self.sfx))
	end
	for i, t in ipairs(sh.prism) do
		t:SetTexture(Card.HoloFile("P", pv, i, self.sfx))
	end
	for i, t in ipairs(sh.glitter) do
		t:SetTexture(Card.HoloFile("D", dv, i, self.sfx))
	end
end

-- (1.14.0, his idea) The pattern of a titanforged copy (pat: its look, Patterns.lua; nil: none): a pattern of colours of its own,
-- the foils of its frame and of its window without their colours (Card:Holo lights them in its colours, and its dust),
-- the light behind its creature in them; the metal of its frame in its colour (framed: the frame of the titans); its
-- number written small on it. None: as a titanforged card was.
function Card:PaintPattern(pat, framed)
	local sh, art, o = self.shine, self.art, self.over
	-- (31 October, his wish) its foils of their own: the window, the frame, the dust (Patterns.lua: wv, pv, dv)
	self:HoloSet(pat and pat.wv or 1, pat and pat.pv or 1, pat and pat.dv or 1)
	local metal = (pat and framed and pat.metal) or nil
	CuratorOctoFull.SetShown(o.metal, metal ~= nil)
	if metal then
		o.metal:SetVertexColor(metal[1], metal[2], metal[3])
	end
	for _, d in ipairs(sh.glitter) do
		d:SetVertexColor(1, 1, 1)
	end
	local tint = pat ~= nil and pat.tint ~= nil
	for _, list in ipairs({ sh.prism, art.foil }) do
		for _, f in ipairs(list) do
			CuratorOctoFull.SetDesaturated(f, tint)
			if not tint then
				f:SetVertexColor(1, 1, 1)
			end
		end
	end
	for i, g in ipairs({ art.glory, art.glory2 }) do
		CuratorOctoFull.SetDesaturated(g, tint)
		if tint then
			g:SetVertexColor(ns.Patterns.Color(pat, (i - 1) * 0.5))
		else
			g:SetVertexColor(1, 1, 1)
		end
	end
	-- (1 November, 9 h 22, his word: « retirer le pattern sur les cartes puisqu'on a maintenant les maîtres des mages »:
	-- its number written on the card no more, the masters of the mages tell it on its certificate, Mages.lua)
	local written = false
	CuratorOctoFull.SetShown(o.pattern, written)
	-- (held in the hand: its word as it is now, not as it was when the card was taken, Card:HeldPaint)
	local h = self.held and self.held3
	if h then
		for _, w in ipairs(h.words) do
			if w.fs == o.pattern then
				w.shown = written
			end
		end
	end
	if pat and written then
		ns.SetFont(o.pattern, o.patternSize or 7.5)
		o.pattern:SetText(string.format(L["Pattern %d"], pat.n))
		o.pattern:ClearAllPoints()
		if o.edition:IsShown() then
			-- (a limited edition: over its plate, in the middle)
			o.pattern:SetPoint("CENTER", self, "TOP", 0, -self.H * (octoConstants.NUM_Y - 0.052))
		else
			o.pattern:SetPoint("LEFT", self, "TOPLEFT", self.W * octoConstants.PATTERN_X, -self.H * octoConstants.NUM_Y)
			-- (clear of the number: smaller when they would meet)
			local room = self.W * (1 - octoConstants.NUM_X - octoConstants.PATTERN_X - 0.035) - ns.TextWidth(o.num)
			local w = ns.TextWidth(o.pattern)
			if w > room and room > 0 then
				ns.SetFont(o.pattern, math.max(4.5, (o.patternSize or 7.5) * room / w))
			end
		end
	end
end

-- (1.14.0) The contraband of the Hardcup Saison 3: its embers breathe as a fire under ash (two slow waves, a quicker one),
-- now and then they flare; its edge (no finish of its own) in their red, with them.
function Card:Smoulder(sh, t)
	local ph = self.phase or 0
	local f = 0.55 + 0.2 * math.sin(t * 1.7 + ph * 5) + 0.12 * math.sin(t * 4.3 + ph * 9) + 0.06 * math.sin(t * 11 + ph)
	local every = 5.5 + ph * 2
	local u = (CuratorOctoFull.Mod((t + ph * 13) , every)) / 0.9
	if u < 1 then
		f = f + 0.45 * math.sin(u * math.pi)
	end
	f = math.max(0.15, math.min(1, f))
	sh.embers:SetAlpha(f)
	if sh.kind == "smuggle" then
		sh.rim:SetAlpha(0.16 + 0.3 * f)
	end
end

-- (1.12.0) Its corruption (0: none): written over the ribbon, right; the eyes of N'Zoth from 60 % (three), from 80 %
-- (three more); at 100 %, its frame drowned in the Void and its picture in the light of it. (1.12.0, later) As the
-- corrupted gear of Visions of N'Zoth showed it: its stains and their veins, a stage from 1 %, 40, 60 and 80 %, deep
-- blue and electric, then in the red of N'Zoth; its creature and its picture in the light of the Void. live: while it
-- spreads (Card:SpreadCorruption: what is coming comes on its own); else as it is.
octoConstants.VOID = { 0.25, 0.55, 1 }
octoConstants.VOID_RED = { 1, 0.16, 0.22 }
octoConstants.STAIN = { { 0.1, 0.14, 0.36 }, { 0.36, 0.05, 0.09 } }  -- (the stains: blue, red)
octoConstants.GLOW = { { 0.2, 0.62, 1 }, { 1, 0.14, 0.2 } }          -- (their veins)
octoConstants.STAIN_A, octoConstants.GLOW_A = 0.97, 1
-- (its picture, by stage)
octoConstants.CORRUPT_ART = { { 0.86, 0.88, 1 }, { 0.72, 0.74, 0.95 }, { 0.58, 0.6, 0.88 }, { 0.68, 0.4, 0.5 } }
local Stage = CorruptStage
local function Red(stage)
	return stage >= 4 and 2 or 1
end
function Card:CorruptLayers(stage, old)
	local sh = self.shine
	local st, gl = old and sh.voidOld or sh.void, old and sh.glowOld or sh.glow
	local key = old and "old" or "now"
	sh.corruptFiles = sh.corruptFiles or {}
	local n = math.max(1, stage)
	if sh.corruptFiles[key] ~= n .. self.sfx then
		sh.corruptFiles[key] = n .. self.sfx
		st:SetTexture(octoConstants.MEDIA .. "CorruptStain" .. n .. self.sfx)
		gl:SetTexture(octoConstants.MEDIA .. "CorruptGlow" .. n .. self.sfx)
	end
	local c, g = octoConstants.STAIN[Red(n)], octoConstants.GLOW[Red(n)]
	st:SetVertexColor(c[1], c[2], c[3])
	gl:SetVertexColor(g[1], g[2], g[3])
end
function Card:SetCorruption(k, live)
	local sh, o = self.shine, self.over
	k = math.max(0, math.min(100, k or 0))
	self.corrupt = k > 0 and k or nil
	sh.corrupt = self.corrupt
	if not live then
		self:StopCorruptFades()
	end
	local on = k > 0 and self.facing ~= "back"
	local stage = Stage(k)
	sh.stage = on and stage or nil
	if on then
		self:CorruptLayers(stage)
	end
	CuratorOctoFull.SetShown(sh.void, on)
	CuratorOctoFull.SetShown(sh.glow, on)
	CuratorOctoFull.SetShown(sh.voidFull, on and k >= 100)
	-- (wholly corrupted: the Void that drowns it in the red of N'Zoth too)
	sh.voidFull:SetVertexColor(0.86, 0.32, 0.42)
	CuratorOctoFull.SetShown(sh.eyes[1], on and k >= 60)
	CuratorOctoFull.SetShown(sh.eyes[2], on and k >= 80)
	local red = on and stage >= 4
	for _, e in ipairs(sh.eyes) do
		if red then
			e:SetVertexColor(1, 0.5, 0.48)
		else
			e:SetVertexColor(1, 1, 1)
		end
	end
	if not on then
		sh.voidOld:Hide()
		sh.glowOld:Hide()
		for _, m in ipairs(sh.motes) do
			m:Hide()
		end
	end
	self:CorruptAlpha()
	o.corrupt:SetText(on and string.format(("%d %%"), k) or "")
	local owned = (self.opts or {}).owned ~= false
	-- (its creature in the light of the Void: Look)
	local m = self.model
	local ck = (on and owned) and k or nil
	if m and m.corruptK ~= ck then
		m.corruptK = ck
		if m.actor and m.loaded then
			Look(m)
		end
	end
	if on then
		local full = k >= 100
		if red then
			o.corrupt:SetTextColor(1, full and 0.3 or 0.38, full and 0.42 or 0.38)
		else
			o.corrupt:SetTextColor(0.45, 0.78, 1)
		end
		-- (its picture in the light of the Void, darker as it climbs; its portrait too)
		if owned then
			local a = octoConstants.CORRUPT_ART[stage]
			if full then
				self.art.bg:SetVertexColor(0.62, 0.36, 0.55)
			else
				self.art.bg:SetVertexColor(a[1], a[2], a[3])
			end
			if self.portraitOn then
				local c = full and { 0.62, 0.36, 0.55 } or a
				self.art.portrait:SetVertexColor(c[1], c[2], c[3])
			end
			self.voidLit = true
			return
		end
	end
	-- (no longer corrupted, another copy of it shown: its picture in its own light again)
	if self.voidLit then
		self.voidLit = nil
		Grey(self.art.bg, not owned, 0.62)
		if self.portraitOn then
			local v = owned and 1 or 0
			self.art.portrait:SetVertexColor(v, v, v)
		end
	end
end

-- (1.12.0) The light of each piece of its corruption: as it is, its stains breathing, its veins pulsing and its eyes
-- blinking (sh.breath, sh.pulse, sh.blink: Card:Haunt, every frame), each times how far it has come yet when it
-- spreads (sh.fade: from 0 to 1).
function Card:CorruptAlpha()
	local sh = self.shine
	local f = sh.fade or {}
	local fv = f.void or 1
	local b = sh.breath or 1
	local p = sh.pulse or 1
	local blink = sh.blink or {}
	-- (all of it going at once: the Light washing it off, Card:PurgeCorruption)
	local all = f.all or 1
	sh.void:SetAlpha(octoConstants.STAIN_A * b * fv * all)
	sh.glow:SetAlpha(math.min(1, octoConstants.GLOW_A * p * fv * all))
	-- (the stage before goes as the next comes over it)
	local was = (1 - fv * fv) * all
	sh.voidOld:SetAlpha(octoConstants.STAIN_A * b * was)
	sh.glowOld:SetAlpha(math.min(1, octoConstants.GLOW_A * p * was))
	sh.eyes[1]:SetAlpha((blink[1] or 1) * (f.eye1 or 1) * all)
	sh.eyes[2]:SetAlpha((blink[2] or 1) * (f.eye2 or 1) * all)
	sh.voidFull:SetAlpha((f.full or 1) * all)
end

-- (1.12.0) The Light washes the corruption off the card (a Master of Priests: Seal.lua, UI/Seal.lua): its veins, its
-- eyes and the Void fade out together while its gauge counts down to nothing. done: once it is gone (the card is
-- then drawn again as it is now).
function Card:PurgeCorruption(from, dur, owner, done)
	local sh, o = self.shine, self.over
	from = math.max(0, math.min(100, math.floor(tonumber(from) or 0)))
	self:StopCorruptFades()
	if self.purgeTw then
		ns.CancelTween(self.purgeTw)
		self.purgeTw = nil
	end
	sh.fade = { all = 1 }
	local shown
	self.purgeTw = ns.Tween(math.max(0.05, dur or 1.5), function(e)
		sh.fade.all = (1 - e) ^ 0.7
		local k = math.floor(from * (1 - e) + 0.5)
		if k ~= shown then
			shown = k
			o.corrupt:SetText(k > 0 and string.format(("%d %%"), k) or "")
			self.corrupt = k > 0 and k or nil
			sh.corrupt = self.corrupt
		end
		self:CorruptAlpha()
	end, function()
		self.purgeTw = nil
		self:StopCorruptFades()
		if done then
			done()
		end
	end, ns.Ease.inOutQuad, owner or self)
end

-- What was coming of it, there at once.
function Card:StopCorruptFades()
	local sh = self.shine
	for _, tw in pairs(sh.fadeTw or {}) do
		ns.CancelTween(tw)
	end
	sh.fadeTw, sh.fade = nil, nil
	sh.voidOld:Hide()
	sh.glowOld:Hide()
end

-- A piece of its corruption comes ("void": a stage of its veins over the one before, from: that stage; "eye1",
-- "eye2": the eyes of N'Zoth opening; "full": the Void drowning its frame), in dur seconds.
function Card:CorruptFade(key, dur, owner, from)
	local sh = self.shine
	sh.fade = sh.fade or {}
	sh.fadeTw = sh.fadeTw or {}
	if sh.fadeTw[key] then
		ns.CancelTween(sh.fadeTw[key])
	end
	if key == "void" then
		if from and from >= 1 then
			self:CorruptLayers(from, true)
			sh.voidOld:Show()
			sh.glowOld:Show()
		else
			sh.voidOld:Hide()
			sh.glowOld:Hide()
		end
	end
	sh.fade[key] = 0
	self:CorruptAlpha()
	sh.fadeTw[key] = ns.Tween(dur, function(e)
		sh.fade[key] = e
		self:CorruptAlpha()
	end, function()
		if sh.fadeTw then
			sh.fadeTw[key] = nil
		end
		if sh.fade then
			sh.fade[key] = nil
		end
		if key == "void" then
			sh.voidOld:Hide()
			sh.glowOld:Hide()
		end
		self:CorruptAlpha()
	end, ns.Ease.outQuad, owner or self)
end

-- (1.12.0, as in Curator Midnight) The corruption spreads over the card, from a gauge to another (a corrupted card
-- turned over in a booster, a corrupted copy fused into it): its veins creep over it, a stage after the other, the
-- eyes of N'Zoth open on it, the Void drowns it at 100 %; its gauge counts. done: once it is all there.
octoConstants.CREEP_IN = 0.6   -- (out of nothing: the first veins come over most of the way)
octoConstants.STAGE_IN = 0.32  -- (a stage over the one before)
function Card:SpreadCorruption(from, to, dur, owner, done)
	from = math.max(0, math.min(100, math.floor(tonumber(from) or 0)))
	to = math.max(from, math.min(100, math.floor(tonumber(to) or from)))
	dur = math.max(0.05, dur or 1)
	owner = owner or self
	if self.spreadTw then
		ns.CancelTween(self.spreadTw)
		self.spreadTw = nil
	end
	local shown
	local function At(v)
		local k = math.floor(v + 0.5)
		if k == shown then
			return
		end
		local was = shown or from
		shown = k
		-- (what the card shows meanwhile, if it is drawn again: SetFinish)
		if self.opts then
			self.opts.creep = k
		end
		self:SetCorruption(k, true)
		local s0, s1 = Stage(was), Stage(k)
		if s1 > s0 then
			self:CorruptFade("void", s0 == 0 and math.max(0.35, dur * octoConstants.CREEP_IN) or octoConstants.STAGE_IN, owner, s0)
		end
		if was < 60 and k >= 60 then
			self:CorruptFade("eye1", 0.45, owner)
		end
		if was < 80 and k >= 80 then
			self:CorruptFade("eye2", 0.45, owner)
		end
		if was < 100 and k >= 100 then
			self:CorruptFade("full", 0.6, owner)
		end
	end
	self.spreadTw = true
	At(from)
	self.spreadTw = ns.Tween(dur, function(e)
		At(from + (to - from) * e)
	end, function()
		self.spreadTw = nil
		At(to)
		if self.opts then
			self.opts.creep = nil
		end
		if done then
			done()
		end
	end, ns.Ease.inOutQuad, owner)
end

-- (1.12.0, later) The plate of a limited edition: on the cards of an album of an event (its year: the series', or
-- that of Hallow's End), dim on a card not found yet.
function Card:PaintEdition(card, missing)
	local o = self.over
	local s = card and card.series
	-- (1.13.0: a limited edition too, the Hardcup Saison 3)
	local year = s and (s.event and (s.edition or (ns.Hallow and ns.Hallow.EDITION)) or (s.limited and s.edition))
	local on = year ~= nil
	CuratorOctoFull.SetShown(o.edition, on)
	CuratorOctoFull.SetShown(o.edName, on and not self.small)
	CuratorOctoFull.SetShown(o.edYear, on)
	if not on then
		return
	end
	o.edName:SetText(C:SeriesName(s))
	o.edYear:SetText(string.format(L["%d Edition"], year))
	local k = missing and 0.45 or 1
	o.edition:SetVertexColor(k, k, k)
	o.edName:SetTextColor(1 * k, 0.74 * k, 0.32 * k)
	o.edYear:SetTextColor(1 * k, 0.9 * k, 0.7 * k)
end

-- (1.12.0) The crest of a mythic card of Hallow's End (the skull of the bosses), shown or not, greyed with a card
-- not found yet.
function Card:SetCrest()
	local o, card = self.over, self.card
	local hallow = card ~= nil and card.series ~= nil and card.series.look == "hallow" and self.facing ~= "back"
	local skull = hallow and card.rarity >= 6
	local medal = hallow and not skull and octoConstants.CREST_MEDAL[card.rarity] or nil
	CuratorOctoFull.SetShown(o.crest, skull)
	CuratorOctoFull.SetShown(o.crestBack, skull and o.crestBack.ok == true)
	CuratorOctoFull.SetShown(o.crestIcon, medal ~= nil)
	local missing = (self.opts or {}).owned == false
	if skull then
		Grey(o.crest, missing, 0.55)
		Grey(o.crestBack, missing, 0.55)
	elseif medal then
		local d = self.W * 2 * medal[2] / 366
		CuratorOctoFull.SetSize(o.crestIcon, d, d)
		o.crestIcon:ClearAllPoints()
		o.crestIcon:SetPoint("CENTER", self, "TOP", 0, -self.H * medal[1] / 512)
		Grey(o.crestIcon, missing, 0.5)
	end
end

-- (1.12.0) A card of Hallow's End: the light of its rarity on its edge, flickering as a candle does; what moves on it
-- (its ghosts drifting, its candles, its flames: two drawings in turn, a fire faster); now and then a bat flies across
-- its window, its wings beating (the two drawings of the texture in turn), more often on the best ones.
octoConstants.BAT_FLIGHT = 1.9

-- (1.12.0, later) The motes of the Void that rise from the stains of a corrupted card: more as it climbs (two to seven),
-- each its own way up from the foot and the edges, in the colour of its veins; fading in and out.
octoConstants.MOTE_LIFE = 2.6
function Card:VoidMotes(sh, t, stage)
	local motes = sh.motes
	if not motes[1] then
		return
	end
	local n = ({ 2, 3, 5, 7 })[stage] or 0
	local g = stage >= 4 and octoConstants.VOID_RED or octoConstants.VOID
	local ph = self.phase or 0
	for i, m in ipairs(motes) do
		if i > n then
			m:Hide()
		else
			local life = octoConstants.MOTE_LIFE + (CuratorOctoFull.Mod(i , 3)) * 0.6
			local cyc = (t + ph * 17 + i * 0.83) / life
			local u = cyc - math.floor(cyc)
			local seed = math.floor(cyc) * 7.31 + i * 3.7 + ph * 13
			local h1 = math.sin(seed * 12.9898) * 43758.5453
			h1 = h1 - math.floor(h1)
			local h2 = math.sin(seed * 78.233) * 12543.1
			h2 = h2 - math.floor(h2)
			-- (from the foot or an edge, up and inward, a little sway)
			local side = h2 < 0.5 and h1 * 0.25 or (1 - h1 * 0.25)
			local x = side + (0.5 - side) * u * 0.35 + 0.02 * math.sin(u * 9 + i)
			local y = 0.94 - u * (0.5 + 0.3 * h2)
			m:ClearAllPoints()
			m:SetPoint("CENTER", self, "TOPLEFT", self.W * x, -self.H * y)
			local size = self.W * (0.05 + 0.04 * h1) * (1 - 0.4 * u)
			CuratorOctoFull.SetSize(m, size, size)
			m:SetVertexColor(g[1], g[2], g[3])
			m:SetAlpha(0.85 * math.sin(u * math.pi) * (sh.fade and sh.fade.all or 1))
			m:Show()
		end
	end
end

function Card:Haunt(sh, t)
	local ph = self.phase or 0
	local hd = sh.hallow or octoConstants.HALLOW[1]
	-- (a candle: two slow waves and a fast tremble)
	local f = 0.5 + 0.22 * math.sin(t * 2.3 + ph * 5) + 0.12 * math.sin(t * 5.9 + ph * 11) + 0.08 * math.sin(t * 17 + ph)
	sh.rim:SetAlpha(hd.a * (0.55 + 0.9 * f))
	local k = sh.corrupt
	if k and sh.stage then
		-- (corrupted: its edge in the light of the Void, more as it climbs, red from 80 %; its stains breathe, slowly;
		-- its veins pulse, faster as it climbs, and now and then the Void surges through them; its eyes blink, each set
		-- on its own; its motes rise)
		local stage = sh.stage
		local v = math.min(1, k / 100)
		local c = hd.rim
		local to = stage >= 4 and octoConstants.VOID_RED or octoConstants.VOID
		sh.rim:SetVertexColor(c[1] + (to[1] - c[1]) * (0.35 + 0.65 * v), c[2] + (to[2] - c[2]) * (0.35 + 0.65 * v), c[3] + (to[3] - c[3]) * (0.35 + 0.65 * v))
		sh.rim:SetAlpha(math.max(sh.rim:GetAlpha(), (0.25 + 0.45 * v) * (0.7 + 0.3 * math.sin(t * 1.3 + ph * 4))))
		sh.blink = sh.blink or {}
		for i = 1, 2 do
			local u = CuratorOctoFull.Mod((t + ph * 7 + i * 2.3) , (4.2 + i * 1.3))
			sh.blink[i] = (u < 0.16) and 0.15 or 1
		end
		sh.breath = (0.9 + 0.1 * math.sin(t * 0.9 + ph * 3)) / octoConstants.STAIN_A
		local speed = 1.6 + 0.55 * stage
		local p = 0.55 + 0.25 * math.sin(t * speed + ph * 5) + 0.12 * math.sin(t * speed * 2.7 + ph * 9)
		-- (a surge: every few seconds, the light runs through them all at once)
		local every = 6.5 - stage
		local u = (CuratorOctoFull.Mod((t + ph * 11) , every)) / 0.55
		if u < 1 then
			p = p + 0.75 * math.sin(u * math.pi)
		end
		sh.pulse = p
		self:CorruptAlpha()
		self:VoidMotes(sh, t, stage)
	end
	if hd.fx then
		local a1
		if hd.flame then
			-- (a fire: the two drawings in turn, fast, never quite out)
			a1 = 0.5 + 0.3 * math.sin(t * 7.3 + ph * 3) + 0.2 * math.sin(t * 13.1 + ph * 7)
		else
			-- (ghosts: one drawing slowly becoming the other)
			a1 = 0.5 + 0.5 * math.sin(t * 0.8 + ph * 2)
		end
		a1 = math.max(0, math.min(1, a1))
		local k = hd.flame and (0.75 + 0.25 * f) or 0.85
		sh.arcs[1]:SetAlpha(a1 * k)
		sh.arcs[2]:SetAlpha((1 - a1) * k)
	end
	for i, bat in ipairs(sh.bats) do
		if i <= hd.bats then
			local every = (hd.every or 7.5) + i * 2.9 + ph * 1.7
			local u = (CuratorOctoFull.Mod((t + ph * 13 + i * 3.1) , every)) / octoConstants.BAT_FLIGHT
			if u <= 1 then
				if not bat.flight then
					-- (each flight its own way: its height, its side, its size)
					local seed = math.floor((t + ph * 13 + i * 3.1) / every) + i * 7 + ph * 31
					local h1 = math.sin(seed * 12.9898) * 43758.5453
					h1 = h1 - math.floor(h1)
					local h2 = math.sin(seed * 78.233) * 12543.1
					h2 = h2 - math.floor(h2)
					bat.flight = { y = 0.14 + 0.3 * h1, dir = (h2 < 0.5) and 1 or -1, size = (0.15 + 0.07 * h2) * self.W }
					CuratorOctoFull.SetSize(bat, bat.flight.size, bat.flight.size * 0.5)
				end
				local fl = bat.flight
				local x = fl.dir > 0 and (-0.15 + 1.3 * u) or (1.15 - 1.3 * u)
				local y = fl.y + 0.035 * math.sin(u * math.pi * 3)
				bat:ClearAllPoints()
				bat:SetPoint("CENTER", self, "TOPLEFT", self.W * x, -self.H * y)
				-- (its wings: up and down, eight beats a second; facing where it flies)
				local up = CuratorOctoFull.Mod(math.floor(t * 8 + i) , 2) == 0
				local l, r = up and 0 or 0.5, up and 0.5 or 1
				if fl.dir < 0 then
					l, r = r, l
				end
				bat:SetTexCoord(l, r, 0, 1)
				bat:SetAlpha(0.9 * math.min(1, math.sin(u * math.pi) * 3))
			else
				bat.flight = nil
				bat:SetAlpha(0)
			end
		end
	end
end

-- (1.11.0) The hologram of a titanforged card: its foil of prism over its frame (TitanPrism1..3: the same fine
-- rays of all the colours and the same facets in the three, each lit on its own third of the card and a third of
-- the rainbow further), shown together by weights that turn with an angle: the light goes round the card, the
-- colours flow along its rays and from facet to facet, while the rays and the facets stay where they are, as on
-- a foil. The angle drifts slowly on its own, and follows the turn of the card held in the hand (shown big, it
-- leans toward the mouse), fast: a little tilt goes a long way through the colours. Not the mouse over a card
-- flat (since 0.11, what is on a card stays put under it). Along its edge, a light that turns through the
-- colours; its dust of stars, two veils of it, that glitter in turn. In its window, under its creature, a foil
-- of its own shown by the same weights (the rays of the frame go on into it), the light of the prism turning
-- behind the creature; the creature in the light of the prism, stars and motes of light over it.
octoConstants.TAU = math.pi * 2
octoConstants.WINDOW = 1.9        -- (how bright the foil of the window is, beside the foil of the frame)

-- A colour of the rainbow (hue from 0 to 1).
local function Rainbow(h)
	h = (CuratorOctoFull.Mod(h , 1)) * 6
	local i = math.floor(h)
	local f = h - i
	if i == 0 then
		return 1, f, 0
	elseif i == 1 then
		return 1 - f, 1, 0
	elseif i == 2 then
		return 0, 1, f
	elseif i == 3 then
		return 0, 1 - f, 1
	elseif i == 4 then
		return f, 0, 1
	end
	return 1, 0, 1 - f
end

function Card:Holo(sh, t)
	local ph = self.phase or 0
	if sh.dustPh ~= ph then
		sh.dustPh = ph
		self:Dust(sh)
	end
	local dt = math.min(0.1, math.max(0, t - (sh.holoT or t)))
	sh.holoT = t
	local tx, ty = 0, 0
	local R = self.held and self.R
	if R then
		tx, ty = R[3] or 0, -(R[6] or 0)
	end
	-- (held: the card turns smoothly already; put down: the colours settle back)
	local k = (R or dt <= 0) and 1 or math.min(1, dt * 3)
	local hx, hy = sh.hx or 0, sh.hy or 0
	hx, hy = hx + (tx - hx) * k, hy + (ty - hy) * k
	sh.hx, sh.hy = hx, hy
	local lean = math.min(1, math.sqrt(hx * hx + hy * hy))
	-- (1.14.0, his idea) a copy with a pattern: its light goes round at its own speed, its own way (Patterns.lua)
	local pat = self.pat
	-- the foil: its three lights weighed by the angle; just turned over in a booster (Forge.lua), once round all its
	-- colours, bright
	local phi = (pat and (t * 0.45 * pat.speed * pat.dir + pat.phase) or t * 0.45) + ph * 2.1 + hx * 3.4 + hy * 2.3
	local boost = 0
	if self.flourish then
		local e = (GetTime() - self.flourish) / 1.8
		if e >= 1 or e < 0 then
			self.flourish = nil
		else
			phi = phi + octoConstants.TAU * (1 - (1 - e) ^ 3)
			boost = 0.9 * (1 - e)
		end
	end
	local w, sum = sh.fw or {}, 0
	sh.fw = w
	local sharp = pat and pat.sharp or 2
	for i = 1, 3 do
		local c = (1 + math.cos(phi - octoConstants.TAU * (i - 1) / 3)) / 2
		w[i] = (sharp == 2) and c * c or c ^ sharp
		sum = sum + w[i]
	end
	local strength = (1.15 + 0.5 * lean + boost) * (pat and pat.power or 1)
	-- (1.14.0, his idea) a pattern of colours of its own: each light of the foil, without its colours, in the colour of the pattern
	-- at its place in the round
	local tint = pat and pat.tint and ns.Patterns.Color
	for i, f in ipairs(sh.prism) do
		f:SetAlpha(math.min(1, strength * w[i] / sum))
		if tint then
			f:SetVertexColor(tint(pat, phi / octoConstants.TAU + (i - 1) / 3))
		end
	end
	-- the light along its edge: gold, through the colours (a pattern: through its own)
	local r, g, b
	if tint then
		r, g, b = tint(pat, phi / octoConstants.TAU)
	else
		r, g, b = Rainbow(phi / octoConstants.TAU)
	end
	sh.rim:SetVertexColor(0.62 + 0.38 * r, 0.52 + 0.4 * g, 0.3 + 0.5 * b)
	-- the dust: two veils, each its own part of the stars, that glitter in turn
	local dust, dustSpeed = pat and pat.dust or 1, pat and pat.dustSpeed or 1
	for i, d in ipairs(sh.glitter) do
		local pulse = 0.5 + 0.5 * math.sin(t * (1.7 + 0.4 * i) * dustSpeed + ph * 5 + i * math.pi)
		d:SetAlpha(math.min(1, (0.2 + 0.7 * pulse * pulse) * (0.75 + 0.25 * lean) * dust))
		-- (a pattern of colours of its own: its stars in them)
		if tint then
			d:SetVertexColor(tint(pat, phi / octoConstants.TAU + 0.5 + i * 0.25))
		end
	end
	-- its window: the foil under the creature, by the same weights; behind the creature, the light of the prism
	-- turning, that breathes; the creature in its light
	local art = self.art
	if self.titanWin then
		local ws = (octoConstants.WINDOW + 0.5 * lean + boost) * (pat and pat.window or 1)
		for i, f in ipairs(art.foil) do
			f:SetAlpha(math.min(1, ws * w[i] / sum))
			if tint then
				f:SetVertexColor(tint(pat, phi / octoConstants.TAU + (i - 1) / 3))
			end
		end
		local breath = math.sin(t * 1.3 + ph * 4)
		local ga = pat and pat.glory or 1
		CuratorOctoFull.SetRotation(art.glory, t * (pat and pat.gs1 or 0.1) + ph * 3)
		art.glory:SetAlpha(math.min(1, (0.34 + 0.06 * breath + 0.5 * boost) * ga))
		CuratorOctoFull.SetRotation(art.glory2, t * (pat and pat.gs2 or -0.17) + ph * 5)
		art.glory2:SetAlpha(math.min(1, (0.24 - 0.05 * breath + 0.4 * boost) * ga))
		self:PrismLight(phi, lean, boost)
	end
end

-- (where the stars of its dust are: the two veils over its frame, each the right way round or mirrored by the
-- card, its own sky among four; the same on every frame)
function Card:Dust(sh)
	local ph = self.phase or 0
	for i, g in ipairs(sh.glitter) do
		local x = math.sin((ph + i * 0.37) * 91.7) * 43758.5453
		if x - math.floor(x) > 0.5 then
			g:SetTexCoord(octoConstants.TEX_R, 0, 0, 1)
		else
			g:SetTexCoord(0, octoConstants.TEX_R, 0, 1)
		end
	end
end

-- (1.11.0) The window of a titanforged card (on: a titanforged card, off: another): its foil under the creature,
-- the light of the prism behind it in place of the rays of its rarity, its photo a little darker (the light stands
-- out on it), the stars and motes over the creature, the creature in the light of the prism; off, as its rarity has
-- them.
function Card:TitanWindow(on)
	local art, m = self.art, self.model
	if not on and not self.titanWin then
		return
	end
	for _, f in ipairs(art.foil) do
		CuratorOctoFull.SetShown(f, on)
	end
	CuratorOctoFull.SetShown(art.glory, on)
	CuratorOctoFull.SetShown(art.glory2, on)
	-- (a small card, as on a page of the album: two stars and three motes)
	local small = self.size == "small"
	for i, s in ipairs(art.sparks) do
		CuratorOctoFull.SetShown(s, on and not (small and (i == 3 or i > 6)))
		s:SetAlpha(0)
		s.cycle = -1
	end
	if on then
		self.titanWin = true
		art.rays:Hide()
		art.rays2:Hide()
		art.bg:SetVertexColor(0.84, 0.84, 0.84)
		if m.actor then
			m.prism = m.prism or {}
		end
		return
	end
	self.titanWin = nil
	local card, owned = self.card, (self.opts or {}).owned ~= false
	CuratorOctoFull.SetShown(art.rays, card ~= nil and card.rarity >= 4 and owned)
	CuratorOctoFull.SetShown(art.rays2, card ~= nil and card.rarity >= 6 and owned)
	Grey(art.bg, not owned, 0.62)
	if m.prism then
		m.prism = nil
		if m.actor then
			Look(m)
		end
	end
end

-- (1.11.0) The creature of a titanforged card in the light of the prism: a light of the colour the foil shows at its
-- angle (white, through the colours), that swings across the creature as the light of the foil goes round; in its
-- shadows, a little of the opposite colour. Brighter as the card leans, and when it has just been turned over.
local function Near(p, i, v)
	return p[i] and math.abs(p[i] - v) < 0.004
end
function Card:PrismLight(phi, lean, boost)
	local sc = self.model
	local p = sc and sc.prism
	if not (p and sc.actor) then
		return
	end
	local h = phi / octoConstants.TAU
	-- (1.14.0, his idea) a pattern of colours of its own: the creature in its light
	local pat = self.pat
	local tint = pat and pat.tint and ns.Patterns.Color
	local r, g, b, r2, g2, b2
	if tint then
		r, g, b = tint(pat, h)
		r2, g2, b2 = tint(pat, h + 0.5)
	else
		r, g, b = Rainbow(h)
		r2, g2, b2 = Rainbow(h + 0.5)
	end
	local sat = 0.38 + 0.3 * boost
	local power = math.min(1.4, 0.8 + 0.2 * lean + 0.6 * boost)
	local dr = math.min(1, ((1 - sat) + sat * r) * power)
	local dg = math.min(1, ((1 - sat) + sat * g) * power)
	local db = math.min(1, ((1 - sat) + sat * b) * power)
	local ar, ag, ab = 0.58 + 0.1 * r2, 0.58 + 0.1 * g2, 0.62 + 0.1 * b2
	local s, c = math.sin(phi), math.cos(phi)
	local lx, ly, lz = Unit(-1, 0.45 + 0.8 * s, -0.55 + 0.25 * c)
	if Near(p, 1, ar) and Near(p, 2, ag) and Near(p, 3, ab) and Near(p, 4, dr) and Near(p, 5, dg) and Near(p, 6, db)
		and Near(p, 7, lx) and Near(p, 8, ly) and Near(p, 9, lz) then
		return
	end
	p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9] = ar, ag, ab, dr, dg, db, lx, ly, lz
	-- (a creature still loading, or seen as a shape, or the client's own light asked for: told once it is there)
	if sc.loaded and not sc.silhouette and not (ns.db and ns.db.plain) then
		sc:SetLightAmbientColor(ar, ag, ab)
		sc:SetLightDiffuseColor(dr, dg, db)
		sc:SetLightDirection(lx, ly, lz)
	end
end

-- (1.11.0) Over the creature of a titanforged card: three stars that twinkle on it, each at a new place each time
-- round, and six motes of light of the colours of the prism that rise around it, slowly, and fade.
local GLINTS = {
	{ 1, 0.96, 0.84 }, { 1, 0.35, 0.4 }, { 1, 0.72, 0.3 }, { 1, 0.96, 0.45 }, { 0.42, 1, 0.55 }, { 0.38, 0.85, 1 },
	{ 0.52, 0.5, 1 }, { 0.92, 0.48, 1 },
}
-- (one of them: star, on the creature; or mote, rising around it. 1.14.0, his idea: glints, the colours of a pattern, Patterns.lua)
local function Spark(s, i, t, aw, ah, ph, glints)
	local GLINTS = glints or GLINTS
	local star = i <= 3
	local period = star and (1.7 + i * 0.43) or (2.6 + (i - 3) * 0.37)
	local x = (t + i * 0.61 + ph * 3) / period
	local cycle = math.floor(x)
	local u = x - cycle
	if cycle ~= s.cycle then
		s.cycle = cycle
		local col
		if star then
			-- (on the creature: the middle of the window)
			s.fx, s.fy = 0.3 + math.random() * 0.4, 0.22 + math.random() * 0.5
			s.size = 0.1 + math.random() * 0.07
			col = (math.random() < 0.5) and GLINTS[1] or GLINTS[1 + math.random(CuratorOctoFull.Length(GLINTS) - 1)]
		else
			-- (around it: from its feet up)
			s.fx, s.fy = 0.12 + math.random() * 0.76, 0.04 + math.random() * 0.22
			s.size = 0.05 + math.random() * 0.04
			s.rise = 0.35 + math.random() * 0.3
			s.sway = (math.random() - 0.5) * 0.08
			col = GLINTS[1 + math.random(CuratorOctoFull.Length(GLINTS) - 1)]
		end
		s:SetVertexColor(col[1], col[2], col[3])
	end
	local a, px, py, sz
	if star then
		a = (u < 0.4) and math.sin(u / 0.4 * math.pi) or 0
		px, py = s.fx * aw, s.fy * ah
		sz = s.size * aw * (0.6 + 0.4 * a)
		CuratorOctoFull.SetRotation(s, u * 1.4)
	else
		a = 0.85 * math.sin(u * math.pi) ^ 1.5
		px = (s.fx + s.sway * math.sin(u * 3.1)) * aw
		py = (s.fy + s.rise * u) * ah
		sz = s.size * aw
	end
	s:ClearAllPoints()
	s:SetPoint("CENTER", s:GetParent(), "BOTTOMLEFT", px, py)
	CuratorOctoFull.SetSize(s, math.max(0.5, sz), math.max(0.5, sz))
	s:SetAlpha(a)
end

function Card:Sparkle(t)
	local art = self.art
	local aw, ah = art:GetWidth(), art:GetHeight()
	if not (aw and ah) or aw < 8 or ah < 8 then
		return
	end
	local ph = self.phase or 0
	local glints = self.pat and self.pat.glints
	for i, s in ipairs(art.sparks) do
		if s:IsShown() then
			Spark(s, i, t, aw, ah, ph, glints)
		end
	end
end

-- The reflection on the back: where the light falls (dx, dy from the middle of the card) and how
-- bright it is.
function Card:BackLight(dx, dy, alpha)
	local s = self.back.sheen
	s:ClearAllPoints()
	s:SetPoint("CENTER", self, "CENTER", dx, dy)
	s:SetAlpha(alpha)
end

-- Card width during a flip: the shadow and the glow follow the squeeze, and the window of its art
-- (its frame is painted on the card: they narrow together).
function Card:SetFlipSize(w, h)
	CuratorOctoFull.SetSize(self, w, h)
	-- (the wear of its copy squeezed with it, UI/Wear.lua)
	if self.wearOn and ns.WearUI then
		ns.WearUI.Fit(self, w, h)
	end
	self.shadow:SetWidth(w / 0.62)
	self.glow:SetWidth(w / 0.46 * 1.05)
	local art = self.art
	art:ClearAllPoints()
	art:SetPoint("TOPLEFT", w * octoConstants.ART_L, -h * octoConstants.ART_T)
	art:SetPoint("BOTTOMRIGHT", -w * octoConstants.ART_R, h * octoConstants.ART_B)
end

-- Front or back, instantly (and facing you: not turned in the hand any more).
function Card:ShowSide(side)
	self.animWait = nil
	if self.held then
		self:Hold(false)
	end
	self:Freeze(false)
	self.facing = side
	self:ApplySide()
	self:SetFaceDetailsShown(true)
	self:SetFlipSize(self.W, self.H)
	if self.turned then
		self.turned = nil
		if self.glare then
			self.glare:SetAlpha(0)
		end
		self.badge:SetAlpha(1)
		self.back.sheen:SetAlpha(0)
		self:SlabSqueeze(1, 1)
	end
	-- (its case, when it is in one: its label from the side shown, its shadow)
	self:SlabSide(side ~= "back")
	self:SlabShadow()
end

-------------------------------------------------------------------------------
-- Turned in the hand (a card looked at closely: UI/Inspect.lua)
-------------------------------------------------------------------------------
-- The light of the room on the card, over both its sides: a band of it runs over the card as it turns.
function Card:Glare()
	if not self.glare then
		local f = self.hot:GetParent()
		local m = CuratorOctoFull.CreateMaskTexture(f)
		m:SetTexture(octoConstants.MEDIA .. "CardMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		m:SetAllPoints(self)
		local g = f:CreateTexture(nil, "OVERLAY", nil, 1)
		g:SetTexture(octoConstants.MEDIA .. "Sheen")
		g:SetBlendMode("ADD")
		CuratorOctoFull.SetSize(g, self.H * 1.8, self.H * 1.8)
		g:SetPoint("CENTER")
		CuratorOctoFull.AddMaskTexture(g, m)
		g:SetAlpha(0)
		self.glare = g
	end
	return self.glare
end

-- yaw: round its upright axis, all the way (its back shows past a quarter turn); pitch: a little toward
-- you or away. As in a flip, the card is narrower as it turns; its texts fade before they no longer fit,
-- the window of its creature closes when it is too narrow; its creature turns with it (the card is a
-- window on it); the light runs over it; its shadow moves.
function Card:SetTurn(yaw, pitch)
	pitch = pitch or 0
	self.turned = true
	local W, H = self.W, self.H
	local cy, sy = math.cos(yaw), math.sin(yaw)
	local cp, sp = math.cos(pitch), math.sin(pitch)
	local kx = math.abs(cy)
	self:SetFlipSize(math.max(1, W * kx), H * cp * (1 + 0.05 * math.abs(sy)))
	local side = (cy >= 0) and "front" or "back"
	if side ~= self.facing then
		self.facing = side
		self:ApplySide(true)
	end
	local o = self.over
	local read = math.max(0, math.min(1, (kx - 0.8) / 0.12))
	-- (1.11.0) its case squeezed with it
	self:SlabSqueeze(math.max(0.01, kx), read)
	for _, k in ipairs({ "name", "sub", "rar", "num", "pattern", "count", "level", "corrupt" }) do
		o[k]:SetAlpha(self.tiny and 0 or read)
	end
	o.gem:SetAlpha(read)
	o.crest:SetAlpha(read)
	o.crestBack:SetAlpha(read)
	o.crestIcon:SetAlpha(read)
	o.set:SetAlpha(0.85 * read)
	self.badge:SetAlpha(read)
	local shut = math.max(0, math.min(1, (0.5 - kx) / 0.2))
	CuratorOctoFull.SetShown(o.cover, shut > 0)
	o.cover:SetAlpha(shut)
	if side == "front" and kx > 0.5 and self.needModel then
		self:ReloadModel()
	end
	local m = self.model
	if m.SetRotation then
		CuratorOctoFull.SetRotation(m, ((Still() and m.facing) or self.turnFacing or 0.4) + yaw)
	end
	-- the light: brighter the more it leans, from the side the card turns away from
	local lean = math.min(1, math.abs(sy) * 1.3 + math.abs(sp) * 1.6)
	local dx, dy = -sy * W * 0.75, sp * H * 0.75 - sy * H * 0.18
	local g = self:Glare()
	g:ClearAllPoints()
	g:SetPoint("CENTER", self, "CENTER", dx, dy)
	g:SetAlpha(0.42 * lean * math.min(1, kx * 4))
	if side == "back" then
		self:BackLight(dx * 0.8, dy * 0.8, 0.35 * lean)
	end
	self.shadow:ClearAllPoints()
	self.shadow:SetPoint("CENTER", 4 - sy * 18, -6 - sp * 12)
end

-- Texts and the creature are hidden while the card is squeezed by a flip.
function Card:SetFaceDetailsShown(shown)
	if self.over.cover.tw then
		ns.CancelTween(self.over.cover.tw)
		self.over.cover.tw = nil
	end
	self.over.cover:SetAlpha(1)
	CuratorOctoFull.SetShown(self.over.cover, not shown)
	-- (a tiny card, its texts too small to read: they are written beside it)
	for _, k in ipairs({ "name", "sub", "rar", "num", "pattern", "count", "level", "corrupt", "edName", "edYear" }) do
		self.over[k]:SetAlpha((shown and not self.tiny) and 1 or 0)
	end
	self.over.edition:SetAlpha(shown and 1 or 0)
	self.over.gem:SetAlpha(shown and 1 or 0)
	self.over.crest:SetAlpha(shown and 1 or 0)
	self.over.crestBack:SetAlpha(shown and 1 or 0)
	self.over.crestIcon:SetAlpha(shown and 1 or 0)
	self.over.set:SetAlpha(shown and 0.85 or 0)
	if not shown then
		self.over.question:Hide()
	elseif self.opts and self.opts.owned == false then
		self.over.question:Show()
	end
end

-- Turns the card over. onMid runs when the card is edge-on, onDone at the end.
function Card:Flip(dur, onMid, onDone, owner)
	dur = dur or 0.34
	local W, H = self.W, self.H
	local mid, details = false, false
	local cover = self.over.cover
	self:SetFaceDetailsShown(false)
	local function showDetails()
		details = true
		if self.needModel then
			self:ReloadModel()
		end
		self:SetFaceDetailsShown(true)
		-- the creature appears: the cover over the art window fades away
		cover:SetAlpha(1)
		cover:Show()
		local tw
		tw = ns.Tween(0.3, function(e)
			cover:SetAlpha(1 - e)
		end, function()
			cover:Hide()
			if cover.tw == tw then
				cover.tw = nil
			end
		end, ns.Ease.outQuad, owner)
		cover.tw = tw
	end
	ns.Tween(dur, function(e)
		local k = math.abs(math.cos(e * math.pi))
		self:SetFlipSize(math.max(1, W * k), H * (1 + 0.07 * math.sin(e * math.pi)))
		if not mid and e >= 0.5 then
			mid = true
			self.facing = (self.facing == "back") and "front" or "back"
			self:ApplySide(true)
			if onMid then
				onMid()
			end
		end
		-- the face is wide enough again: art and texts come back before the end
		if mid and not details and e >= 0.8 then
			showDetails()
		end
	end, function()
		self:SetFlipSize(W, H)
		if not details then
			showDetails()
		end
		if onDone then
			onDone()
		end
	end, ns.Ease.inOutCubic, owner)
end

-- Plays the creature's reveal animation, then back to idle.
function Card:Animate(owner, force)
	local m, card = self.model, self.card
	-- (the creatures as a still picture: none)
	if not card or m.silhouette or not m.display or Still() then
		return
	end
	-- (a card held that moves: its creature still; it plays once the card is still)
	if self.frozen then
		self.animWait = { owner = owner }
		return
	end
	if m.loaded == false and not force then
		-- the creature is still loading: play it as soon as it is there (or try anyway after a second)
		local go
		go = function()
			if m.pendingAnim == go then
				m.pendingAnim = nil
			end
			self:Animate(owner, true)
		end
		m.pendingAnim = go
		ns.Delay(1, function()
			if m.pendingAnim == go then
				go()
			end
		end, owner)
		return
	end
	local list = card.friendly and octoConstants.ANIM_PERSON or octoConstants.ANIM_CREATURE
	local back = card.friendly and 2.4 or 1.9
	if m.actor then
		-- (an actor cannot tell what it can play: the probe tells)
		local display = m.display
		Probe:Ask(display, function(has)
			if m.display ~= display or m.silhouette or not m:IsVisible() then
				return
			end
			for _, anim in ipairs(list) do
				if has[anim] then
					m.actor:SetAnimation(anim, 0, 1)
					ns.Delay(back, function()
						if m.display == display then
							m.actor:SetAnimation(0, 0, 1)
						end
					end, owner)
					return
				end
			end
		end)
		return
	end
	for _, anim in ipairs(list) do
		local ok, has = pcall(m.HasAnimation, m, anim)
		if ok and has and m.SetAnimation then
			m:SetAnimation(anim)
			ns.Delay(back, function()
				m:SetAnimation(0)
			end, owner)
			return
		end
	end
end

function Card:PlayVoice()
	if self.card and self.card.sound and self.card.sound > 0 then
		ns.Play(self.card.sound)
	end
end

-- A twinkle lights up at a new place each time around, over the card.
-- (1.11.0) The diamonds of the frame of the titans (where they are on a card of 366 x 512, and how large they
-- sparkle): its crest, three corners, the sides.
octoConstants.JEWELS = { { 183, 15, 1.35 }, { 350.5, 15.5, 1 }, { 15.5, 496.5, 1 }, { 350.5, 496.5, 1 }, { 15, 170, 0.7 },
	{ 351, 170, 0.7 }, { 15, 412, 0.7 }, { 351, 412, 0.7 } }

local function Twinkle(self, tw, i, t)
	local period = 2.1 + i * 0.37
	local x = (t + i * 0.83 + (self.phase or 0) * 2) / period
	local cycle = math.floor(x)
	local u = x - cycle
	if cycle ~= tw.cycle then
		tw.cycle = cycle
		local size = (0.1 + math.random() * 0.12) * self.W
		local px, py = self.W * (0.12 + math.random() * 0.76), -self.H * (0.08 + math.random() * 0.84)
		-- (the titanforged cards: mostly on a diamond of their frame)
		if self.shine.kind == "titan" and math.random() < 0.7 then
			local j = octoConstants.JEWELS[math.random(CuratorOctoFull.Length(octoConstants.JEWELS))]
			size = (0.14 + math.random() * 0.06) * self.W * j[3]
			px, py = self.W * j[1] / 366, -self.H * j[2] / 512
		end
		CuratorOctoFull.SetSize(tw, size, size)
		tw:ClearAllPoints()
		tw:SetPoint("CENTER", self, "TOPLEFT", px, py)
	end
	if u < 0.35 then
		local a = math.sin(u / 0.35 * math.pi)
		tw:SetAlpha(a)
		CuratorOctoFull.SetRotation(tw, u * 1.2)
	else
		tw:SetAlpha(0)
	end
end

-- A number in 0..1 that looks random, the same for the same n.
local function Hash(n)
	local x = math.sin(n * 12.9898) * 43758.5453
	return x - math.floor(x)
end

-- The lightning of a thunderforged card: it crawls over the card, one drawing then the other, faint;
-- every few seconds it strikes, and the whole card crackles three times.
function Card:Crackle(sh, t)
	local ph = self.phase or 0
	local every = 2.3 + ph * 1.4
	local u = CuratorOctoFull.Mod((t + ph * 7) , every)
	local a1, a2
	if u < 0.34 then
		local on = CuratorOctoFull.Mod(math.floor(u / 0.085) , 2) == 0
		a1, a2 = on and 1 or 0.3, on and 0.75 or 0.2
		sh.rim:SetAlpha(on and 0.9 or 0.5)
	else
		local step = math.floor((t + ph * 3) * 14)
		local h = 0.16 + 0.3 * Hash(step + ph * 100)
		a1 = (CuratorOctoFull.Mod(step , 2) == 0) and h or 0.04
		a2 = (CuratorOctoFull.Mod(step , 2) == 1) and h or 0.04
		sh.rim:SetAlpha(0.32 + 0.1 * math.sin(t * 3.1 + ph * 4))
	end
	sh.arcs[1]:SetAlpha(a1)
	sh.arcs[2]:SetAlpha(a2)
end

-- Continuous effects (finishes, light rays, glow of the best cards), driven by the owner's OnUpdate.
function Card:Tick(t)
	self.tickT = t
	local sh = self.shine
	if sh:IsShown() then
		local kind = sh.kind
		-- the sweep of light: often on the thunderforged and titanforged cards, now and then on the others
		local every = (kind == "glint" or kind == "hallow" or kind == "smuggle") and 7.5 or 3.2
		local u = (CuratorOctoFull.Mod((t + (self.phase or 0) * 3) , every)) / 1.3
		if u <= 1 then
			-- the band leans like "/" and sweeps across the card from top left to bottom right
			local reach = (self.W + self.H) * 0.36 + self.H * 0.12
			local d = (-1 + 2 * u) * reach
			sh.sheen:ClearAllPoints()
			sh.sheen:SetPoint("CENTER", self, "CENTER", d * 0.7071, -d * 0.7071)
			sh.sheen:SetAlpha(math.sin(u * math.pi) * (((kind == "glint" or kind == "hallow" or kind == "smuggle") and 0.4) or 0.7))
		else
			sh.sheen:SetAlpha(0)
		end
		if sh.smuggle then
			self:Smoulder(sh, t)
		end
		if kind == "thunder" then
			self:Crackle(sh, t)
		elseif kind == "hallow" then
			self:Haunt(sh, t)
		elseif kind == "titan" then
			local breath = math.sin(t * 1.5 + (self.phase or 0) * 5)
			sh.rim:SetAlpha((0.18 + 0.08 * breath) * (self.pat and self.pat.rim or 1))
			self:Holo(sh, t)
			if self.titanWin then
				self:Sparkle(t)
			end
		end
		if kind ~= "glint" and kind ~= "smuggle" then
			for i, tw in ipairs(sh.twinkles) do
				Twinkle(self, tw, i, t)
			end
		end
	end
	local art = self.art
	if art.rays:IsShown() then
		CuratorOctoFull.SetRotation(art.rays, t * 0.25)
		if art.rays2:IsShown() then
			local breath = math.sin(t * 2.2 + (self.phase or 0) * 4)
			art.rays:SetAlpha(art.rays.base + 0.15 * breath)
			CuratorOctoFull.SetRotation(art.rays2, -t * 0.16)
			art.rays2:SetAlpha(0.3 - 0.1 * breath)
		end
	end
	-- (his idea, 31 October: the scratches of its wear glint as the light runs across them, UI/Wear.lua)
	if self.wearOn and ns.WearUI then
		ns.WearUI.Tick(self, t)
	end
	-- (held in the hand: its pieces in 3D follow what was just done to them)
	if self.held then
		self:HeldPaint()
	end
end

-------------------------------------------------------------------------------
-- In the hand, in 3D (1.3.1)
-------------------------------------------------------------------------------
-- A card held (looked at closely in a booster, shown big in the album, opened from the chat) is drawn
-- in perspective, as a real card turned in the hand: all the way round, tilted up and down, the side
-- nearer the eye larger. Each of its pieces is cut in cells whose corners are moved where the card
-- puts them (SetVertexOffset): its lines stay straight. Its pieces drawn flat step aside meanwhile, and
-- are read every frame (their texture, their part of it, their colour, their light): what is done to
-- them (a finish that crackles, twinkles, a flash) shows on the card in 3D. Its words cannot be bent:
-- they follow it, turned and scaled with it, and fade when it is seen too much from the side. Its
-- creature is a figure set in its window: seen through it (the window, cut to what the card shows of
-- it, clips it), it turns with the card (ns.OrbitScene), and stands still while the card moves
-- (Card:Freeze).
octoConstants.EYE = 3.5        -- the distance of the eye from the card, in heights of the card: the perspective
octoConstants.GLARE = 0.3      -- the light of the room on a card turned toward it
octoConstants.ROUND = 22 / 366 -- the round of the corners of the card, in widths of it (its light stops there)

-- Can this client move the corners of a texture? (Without it: the card is squeezed, as before.)
local can3D
function ns.Can3D()
	if can3D == nil then
		local probe = UIParent:CreateTexture(nil, "BACKGROUND")
		can3D = (probe.SetVertexOffset ~= nil) and true or false
		probe:Hide()
	end
	return can3D
end

-- Where a point of the card (from its middle, at rest) is seen, and how much nearer it is (its scale).
local function Project(c, x, y)
	local R = c.R
	local px, py, pz = R[1] * x + R[2] * y, R[4] * x + R[5] * y, R[7] * x + R[8] * y
	local k = c.eye / (c.eye - pz)
	return px * k, py * k, k
end

-- (1.14.0, after its second test) The same, of a point out of the plane of the card: z toward the eye at rest (the faces
-- of the case of a card appraised, of the reliquary of a card sealed).
local function Project3(c, x, y, z)
	local R = c.R
	local px, py, pz = R[1] * x + R[2] * y + R[3] * z, R[4] * x + R[5] * y + R[6] * z, R[7] * x + R[8] * y + R[9] * z
	local k = c.eye / (c.eye - pz)
	return px * k, py * k, k
end

-- A grid over a part of the card: its lines (x from left to right, y from top to bottom), and where the
-- card puts their crossings. round: its four corner cells as large as the round of the corners of the
-- card, their outer corner drawn in to the round (chamfer): a light over the card does not go past it.
-- (1.11.0: before, those cells were left out, and their light with them.)
octoConstants.CHAMFER = 1 - math.sqrt(0.5)
local function Grid(x1, y1, x2, y2, cols, rows, round)
	local function Lines(a, b, n)
		local t = {}
		if round then
			local r = (b > a) and round or -round
			t[1] = a
			for i = 0, n - 2 do
				t[CuratorOctoFull.Length(t) + 1] = a + r + (b - a - 2 * r) * i / (n - 2)
			end
			t[CuratorOctoFull.Length(t) + 1] = b
		else
			for i = 0, n do
				t[i + 1] = a + (b - a) * i / n
			end
		end
		return t
	end
	return { x1 = x1, y1 = y1, x2 = x2, y2 = y2, xs = Lines(x1, x2, cols), ys = Lines(y2, y1, rows), cols = cols, rows = rows,
		chamfer = round and round * octoConstants.CHAMFER or nil, px = {}, py = {} }
end

-- (1.11.0) A grid of lines given (x from left to right, y from top to bottom): the hologram of a titanforged
-- card, its lines along the windows of its frame (each cell as much of it as the frame shows there); round:
-- the round of the corners of the card, its four outer corners drawn in to it.
local function GridAt(xs, ys, round)
	return { x1 = xs[1], y1 = ys[CuratorOctoFull.Length(ys)], x2 = xs[CuratorOctoFull.Length(xs)], y2 = ys[1], xs = xs, ys = ys, cols = CuratorOctoFull.Length(xs) - 1, rows = CuratorOctoFull.Length(ys) - 1,
		chamfer = round and round * octoConstants.CHAMFER or nil, px = {}, py = {} }
end

-- Cells over a grid, each anchored where it is at rest (i, j: its column and its row).
local function Cells(c, parent, g, layer, sub)
	local m = { grid = g, ci = {}, cj = {} }
	local xs, ys = g.xs, g.ys
	for j = 1, g.rows do
		for i = 1, g.cols do
			do
				local t = parent:CreateTexture(nil, layer, nil, sub)
				t:SetPoint("TOPLEFT", c, "CENTER", xs[i], ys[j])
				CuratorOctoFull.SetSize(t, xs[i + 1] - xs[i], ys[j] - ys[j + 1])
				if t.SetSnapToPixelGrid then
					t:SetSnapToPixelGrid(false)
					t:SetTexelSnappingBias(0)
				end
				t:Hide()
				local k = CuratorOctoFull.Length(m) + 1
				m[k], m.ci[k], m.cj[k] = t, i, j
			end
		end
	end
	return m
end

-- Each crossing of a grid, where the card puts it (the four outer corners of a grid chamfered: drawn in). (1.14.0, after
-- its second test: a grid out of the plane of the card, at its depth g.z: a face of a case.)
local function ProjectGrid(c, g)
	local xs, ys, px, py, ch, z = g.xs, g.ys, g.px, g.py, g.chamfer, g.z
	local cols, rows = g.cols + 1, g.rows + 1
	local n = 0
	for j = 1, rows do
		local y = ys[j]
		for i = 1, cols do
			n = n + 1
			if z then
				px[n], py[n] = Project3(c, xs[i], y, z)
			elseif ch and (i == 1 or i == cols) and (j == 1 or j == rows) then
				px[n], py[n] = Project(c, xs[i] + ((i == 1) and ch or -ch), y + ((j == 1) and -ch or ch))
			else
				px[n], py[n] = Project(c, xs[i], y)
			end
		end
	end
end

-- The corners of each cell moved to their points (vertices: 1 upper left, 2 lower left, 3 upper
-- right, 4 lower right).
local function Warp(m)
	local g = m.grid
	local xs, ys, px, py, w = g.xs, g.ys, g.px, g.py, g.cols + 1
	for k = 1, CuratorOctoFull.Length(m) do
		local i, j = m.ci[k], m.cj[k]
		local xl, xr, yt, yb = xs[i], xs[i + 1], ys[j], ys[j + 1]
		local a, b = (j - 1) * w + i, j * w + i
		local t = m[k]
		t:SetVertexOffset(1, px[a] - xl, py[a] - yt)
		t:SetVertexOffset(2, px[b] - xl, py[b] - yb)
		t:SetVertexOffset(3, px[a + 1] - xr, py[a + 1] - yt)
		t:SetVertexOffset(4, px[b + 1] - xr, py[b + 1] - yb)
	end
end

-- A single cell (a small piece: the gem, a twinkle) moved to where the card puts its corners.
local function WarpQuad(c, t, x1, y1, x2, y2)
	local ax, ay = Project(c, x1, y2)
	local bx, by = Project(c, x1, y1)
	local cx, cy = Project(c, x2, y2)
	local dx, dy = Project(c, x2, y1)
	t:SetVertexOffset(1, ax - x1, ay - y2)
	t:SetVertexOffset(2, bx - x1, by - y1)
	t:SetVertexOffset(3, cx - x2, cy - y2)
	t:SetVertexOffset(4, dx - x2, dy - y1)
end

-- Shown or hidden, its light; its corners moved again when the card has moved since.
local function Paint(m, on, a, pose)
	if on and m.pose ~= pose then
		Warp(m)
		m.pose = pose
	end
	if on ~= m.on then
		m.on = on
		for i = 1, CuratorOctoFull.Length(m) do
			CuratorOctoFull.SetShown(m[i], on)
		end
	end
	if on and a ~= m.a then
		m.a = a
		for i = 1, CuratorOctoFull.Length(m) do
			m[i]:SetAlpha(a)
		end
	end
end

-- The part of its texture a piece shows: left, right, top, bottom.
local function TexCoordOf(src)
	local ulx, uly, llx, lly, urx = src:GetTexCoord()
	if type(ulx) ~= "number" then
		return 0, 1, 0, 1
	end
	return ulx, urx, uly, lly
end

-- The cells take the look of the piece they stand for, each its part of the texture.
local function Dress(m, src, flip, wrap)
	local tex = src:GetTexture()
	local u0, u1, v0, v1 = TexCoordOf(src)
	if flip then
		u0, u1 = u1, u0
	end
	local r, g, b, a = src:GetVertexColor()
	local blend = src:GetBlendMode() or "BLEND"
	local desat = src:IsDesaturated() and true or false
	local grid = m.grid
	local xs, ys, gx, gy = grid.xs, grid.ys, grid.x1, grid.y2
	local w, h = grid.x2 - grid.x1, grid.y2 - grid.y1
	for k = 1, CuratorOctoFull.Length(m) do
		local t, i, j = m[k], m.ci[k], m.cj[k]
		if wrap then
			-- (1.14.0: a mode of its own, else repeated)
			local mode = (wrap == true) and "REPEAT" or wrap
			t:SetTexture(tex, mode, mode)
		else
			t:SetTexture(tex)
		end
		local fl, fr = (xs[i] - gx) / w, (xs[i + 1] - gx) / w
		local ft, fb = (gy - ys[j]) / h, (gy - ys[j + 1]) / h
		t:SetTexCoord(u0 + (u1 - u0) * fl, u0 + (u1 - u0) * fr, v0 + (v1 - v0) * ft, v0 + (v1 - v0) * fb)
		t:SetVertexColor(r or 1, g or 1, b or 1, (a or 1) * (m.w and m.w[k] or 1))
		t:SetBlendMode(blend)
		CuratorOctoFull.SetDesaturated(t, desat)
	end
end

-- (1.11.0) A piece whose part of its texture moves, or its colour (the hologram, its dust, the light along the
-- edge of a titanforged card): its cells follow it.
local function Recoord(L)
	local src, m = L.src, L.mesh
	local r, g, b, a = src:GetVertexColor()
	if r ~= L.r or g ~= L.g or b ~= L.b or a ~= L.a then
		L.r, L.g, L.b, L.a = r, g, b, a
		for k = 1, CuratorOctoFull.Length(m) do
			m[k]:SetVertexColor(r or 1, g or 1, b or 1, (a or 1) * (m.w and m.w[k] or 1))
		end
	end
	local u0, u1, v0, v1 = TexCoordOf(src)
	if u0 == L.u0 and u1 == L.u1 and v0 == L.v0 and v1 == L.v1 then
		return
	end
	L.u0, L.u1, L.v0, L.v1 = u0, u1, v0, v1
	local grid = m.grid
	local xs, ys, gx, gy = grid.xs, grid.ys, grid.x1, grid.y2
	local w, h = grid.x2 - grid.x1, grid.y2 - grid.y1
	for k = 1, CuratorOctoFull.Length(m) do
		local i, j = m.ci[k], m.cj[k]
		local fl, fr = (xs[i] - gx) / w, (xs[i + 1] - gx) / w
		local ft, fb = (gy - ys[j]) / h, (gy - ys[j + 1]) / h
		m[k]:SetTexCoord(u0 + (u1 - u0) * fl, u0 + (u1 - u0) * fr, v0 + (v1 - v0) * ft, v0 + (v1 - v0) * fb)
	end
end

-- A band of light over the cells (the sweep of a finish, the light of the room): the texture of the
-- sheen, its middle at (gx, gy) of the card, size its side.
local function Band(m, gx, gy, size)
	local g = m.grid
	local xs, ys = g.xs, g.ys
	for k = 1, CuratorOctoFull.Length(m) do
		local i, j = m.ci[k], m.cj[k]
		m[k]:SetTexCoord(0.5 + (xs[i] - gx) / size, 0.5 + (xs[i + 1] - gx) / size, 0.5 - (ys[j] - gy) / size, 0.5 - (ys[j + 1] - gy) / size)
	end
end

-- Where a word sits on the card at rest (its middle), from how it is anchored.
octoConstants.POINT_X = { LEFT = 1, TOPLEFT = 1, BOTTOMLEFT = 1, RIGHT = -1, TOPRIGHT = -1, BOTTOMRIGHT = -1 }
octoConstants.POINT_Y = { TOP = -1, TOPLEFT = -1, TOPRIGHT = -1, BOTTOM = 1, BOTTOMLEFT = 1, BOTTOMRIGHT = 1 }
local function Corner(point, x1, y1, x2, y2)
	local fx = (string.find(point, "LEFT") and 0) or (string.find(point, "RIGHT") and 1) or 0.5
	local fy = (string.find(point, "TOP") and 1) or (string.find(point, "BOTTOM") and 0) or 0.5
	return x1 + (x2 - x1) * fx, y1 + (y2 - y1) * fy
end
-- (box: a word of the label of a case, its box as wide as it was set, placed by its middle as it is)
local function RestCenter(c, fs, rects, box)
	local point, rel, relPoint, x, y = fs:GetPoint(1)
	if not point then
		return 0, 0
	end
	local r = rects[rel] or rects[c]
	local ax, ay = Corner(relPoint or point, r[1], r[2], r[3], r[4])
	ax, ay = ax + (x or 0), ay + (y or 0)
	local w = 0
	if octoConstants.POINT_X[point] then
		w = box and fs:GetWidth() or 0
		if w <= 0 then
			w = fs:GetStringWidth() or 0
		end
	end
	local h = (octoConstants.POINT_Y[point] and CuratorOctoFull.GetStringHeight(fs)) or 0
	return ax + (octoConstants.POINT_X[point] or 0) * w / 2, ay + (octoConstants.POINT_Y[point] or 0) * h / 2
end

-------------------------------------------------------------------------------
-- (31 October, his wish: the words of a card part of it as it turns, not a text over it) The words of a card held in 3D
-- drawn letter by letter: each letter a small piece of the atlas of Friz Quadrata, the font of the game (Media\Glyphs\Friz,
-- Data/Glyphs.lua), laid where the client lays the text, its corners turned with the card as every piece of it (WarpQuad):
-- the words bend with it. A word with a letter the atlas has not (Cyrillic, Korean, Chinese) or a code of the client in it
-- (a texture, a link): as before, turned and scaled. Its shadow, its outline: the same letters, darker, under them.
-------------------------------------------------------------------------------
octoConstants.GLYPHS = octoConstants.MEDIA .. "Glyphs\\Friz"
octoConstants.GLYPH_OUTLINE = 0.065
octoConstants.OUTLINE_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.7071, 0.7071 }, { -0.7071, 0.7071 }, { 0.7071, -0.7071 }, { -0.7071, -0.7071 } }

-- The code points of a text (UTF-8).
local function Codes(s)
	local out, i, n = {}, 1, CuratorOctoFull.Length(s)
	while i <= n do
		local b = CuratorOctoFull.Byte(s, i)
		local cp, len
		if b < 128 then
			cp, len = b, 1
		elseif b >= 240 then
			cp, len = (CuratorOctoFull.Mod(b , 8)) * 262144 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 1) or 128) , 64)) * 4096 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 2) or 128) , 64)) * 64 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 3) or 128) , 64)), 4
		elseif b >= 224 then
			cp, len = (CuratorOctoFull.Mod(b , 16)) * 4096 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 1) or 128) , 64)) * 64 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 2) or 128) , 64)), 3
		elseif b >= 192 then
			cp, len = (CuratorOctoFull.Mod(b , 32)) * 64 + (CuratorOctoFull.Mod((CuratorOctoFull.Byte(s, i + 1) or 128) , 64)), 2
		else
			cp, len = 65533, 1
		end
		out[CuratorOctoFull.Length(out) + 1] = cp
		i = i + len
	end
	return out
end

-- The letters of a word at rest (wd: its font string, where it stands): their quads in the card (left, bottom, right, top,
-- then their part of the atlas), or false.
local function GlyphLayout(wd)
	local G = ns.Glyphs
	local fs = wd.fs
	local text = fs:GetText()
	if not (G and text) then
		return false
	end
	text = string.gsub(string.gsub(text, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
	if string.find(text, "|", 1, true) then
		return false
	end
	local codes = Codes(text)
	local adv = 0
	for _, cp in ipairs(codes) do
		local g = G[cp]
		if not g then
			return false
		end
		adv = adv + g[9]
	end
	local _, em = fs:GetFont()
	if not em or em <= 0 then
		return false
	end
	local width = adv * em
	-- (where its text stands: by its middle; set by its right or its left, from that side, as the client wrote it)
	local sw = fs:GetStringWidth() or width
	-- (31 October, his word: the words of a label, of a seal, of a card of a case in letters too: narrowed to the room
	-- the client gave them in their own font, the narrow one of the printers of labels)
	local kx = 1
	if wd.fit and sw > 0 and width > sw * 1.02 then
		kx = math.max(0.5, sw / width)
		width = width * kx
	end
	local point = wd.points[1] and wd.points[1][1] or "CENTER"
	local left
	if octoConstants.POINT_X[point] == -1 then
		left = wd.x + sw / 2 - width
	elseif octoConstants.POINT_X[point] == 1 then
		left = wd.x - sw / 2
	else
		left = wd.x - width / 2
	end
	local base = wd.y - (G.asc - G.desc) / 2 * em
	local q, pen = {}, left
	for _, cp in ipairs(codes) do
		local g = G[cp]
		if g[7] > 0 then
			local x1, y2 = pen + g[5] * em * kx, base + g[6] * em
			q[CuratorOctoFull.Length(q) + 1] = { x1, y2 - g[8] * em, x1 + g[7] * em * kx, y2, g[1], g[2], g[3], g[4] }
		end
		pen = pen + g[9] * em * kx
	end
	return q, em
end

-- Its letters given back to the card (hidden, to be taken again).
local function GlyphRelease(h, wd)
	local pool = wd.pool or h.gfree
	for _, e in ipairs(wd.gtex or {}) do
		e.t:Hide()
		pool[CuratorOctoFull.Length(pool) + 1] = e.t
	end
	wd.gtex = nil
end

-- A word laid again in letters (its text, its font, its colour, its shadow, its outline as they are now).
local function GlyphSet(c, h, wd)
	GlyphRelease(h, wd)
	local fs = wd.fs
	wd.text, wd.size = fs:GetText(), CuratorOctoFull.Select(2, fs:GetFont())
	local q, em = GlyphLayout(wd)
	if not q then
		wd.glyph = false
		return
	end
	wd.glyph = true
	local list = {}
	local r, g, b, a = fs:GetTextColor()
	local pool, frame = wd.pool or h.gfree, wd.frame or h.texts
	local function Add(dx, dy, cr, cg, cb, ca, sub)
		for _, e in ipairs(q) do
			local t = CuratorOctoFull.Remove(pool)
			if not t then
				t = frame:CreateTexture(nil, "ARTWORK")
				t:SetTexture(octoConstants.GLYPHS, "CLAMP", "CLAMP")
			end
			t:SetDrawLayer("ARTWORK", sub)
			t:SetTexCoord(e[5], e[6], e[7], e[8])
			CuratorOctoFull.SetShown(t, fs:IsShown())
			t:SetVertexColor(cr, cg, cb)
			local x1, y1, x2, y2 = e[1] + dx, e[2] + dy, e[3] + dx, e[4] + dy
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", c, "CENTER", x1, y2)
			CuratorOctoFull.SetSize(t, math.max(0.01, x2 - x1), math.max(0.01, y2 - y1))
			list[CuratorOctoFull.Length(list) + 1] = { t = t, x1 = x1, y1 = y1, x2 = x2, y2 = y2, a = ca or 1 }
		end
	end
	local _, _, flags = fs:GetFont()
	if flags and string.find(flags, "OUTLINE") then
		local d = octoConstants.GLYPH_OUTLINE * em
		for _, o in ipairs(octoConstants.OUTLINE_DIRS) do
			Add(o[1] * d, o[2] * d, 0, 0, 0, 1, -2)
		end
	end
	local sx, sy = fs:GetShadowOffset()
	if (sx or 0) ~= 0 or (sy or 0) ~= 0 then
		local sr, sg, sb, sa = fs:GetShadowColor()
		Add(sx, sy, sr or 0, sg or 0, sb or 0, sa or 1, -1)
	end
	Add(0, 0, r or 1, g or 1, b or 1, a or 1, 0)
	wd.gtex, wd.gon = list, fs:IsShown()
end

-- The largest upright rectangle in the window as the card shows it (its left and right sides stand
-- upright: the card turns round its upright axis first; its top and its bottom lean when it is turned
-- and tilted at once): a few widths tried around its middle. nil: too narrow to see through.
octoConstants.WIDTHS, octoConstants.SHIFTS = { 1, 0.85, 0.7, 0.55, 0.4 }, { 0, -0.15, 0.15 }
local function Inside(ulx, uly, urx, ury, llx, lly, lrx, lry)
	local xl, xr = math.max(ulx, llx), math.min(urx, lrx)
	if xr - xl < 2 or urx - ulx < 1 or lrx - llx < 1 then
		return nil
	end
	local function Top(x)
		return uly + (ury - uly) * (x - ulx) / (urx - ulx)
	end
	local function Bottom(x)
		return lly + (lry - lly) * (x - llx) / (lrx - llx)
	end
	local mid, span = (xl + xr) / 2, xr - xl
	local best, bx1, by1, bx2, by2 = 0
	for _, f in ipairs(octoConstants.WIDTHS) do
		for _, s in ipairs(octoConstants.SHIFTS) do
			local x1 = math.max(xl, mid + span * (s - f / 2))
			local x2 = math.min(xr, mid + span * (s + f / 2))
			local y2 = math.min(Top(x1), Top(x2))
			local y1 = math.max(Bottom(x1), Bottom(x2))
			local area = (x2 - x1) * (y2 - y1)
			if x2 - x1 > 1 and y2 - y1 > 1 and area > best then
				best, bx1, by1, bx2, by2 = area, x1, y1, x2, y2
			end
		end
	end
	if bx1 then
		return bx1, by1, bx2, by2
	end
end

-------------------------------------------------------------------------------
-- (1.14.0, after its second test) The case of a card as a thing in 3D (« un objet en 3D quand on l'inspecte »): the case
-- of the expert a slab of acrylic as thick as the real ones, the reliquary of a warlock of iron and thicker. Held in the
-- hand, its face turned to the eye is over the card, as far from it as the case is thick (the face of the back seen from
-- behind: the same acrylic, the same iron, the other way round), and its four edges stand between its two faces, each
-- where the eye sees it and lit by where it faces (the light of the room, from the upper left, in front); those turned
-- away are hidden.
-------------------------------------------------------------------------------
-- how thick a case is, half of it each side of the card (in widths of the card)
octoConstants.DEPTH = { slab = 0.038, seal = 0.06 }
-- (each edge cut along its length: its texture follows the eye along it)
octoConstants.EDGE_SEGS = 8
octoConstants.DLX, octoConstants.DLY, octoConstants.DLZ = -0.30, 0.62, 0.72
do
	local n = math.sqrt(octoConstants.DLX * octoConstants.DLX + octoConstants.DLY * octoConstants.DLY + octoConstants.DLZ * octoConstants.DLZ)
	octoConstants.DLX, octoConstants.DLY, octoConstants.DLZ = octoConstants.DLX / n, octoConstants.DLY / n, octoConstants.DLZ / n
end
-- how its edges take the light: the acrylic clear and bright, the iron dark
octoConstants.EDGE_LOOK = {
	slab = { tex = "SlabEdge", amb = 0.62, dif = 0.5, tint = { 0.86, 0.93, 1 }, alpha = 0.95 },
	seal = { tex = "SealEdge", amb = 0.4, dif = 0.66, tint = { 0.84, 0.86, 0.9 }, alpha = 1 },
}
-- (each edge: its start and its end, corners of the case (1: its left, 2: its bottom, 3: its right, 4: its top), its
-- outward side)
octoConstants.EDGES = {
	{ 1, 4, 3, 4, 0, 1 },
	{ 3, 4, 3, 2, 1, 0 },
	{ 3, 2, 1, 2, 0, -1 },
	{ 1, 2, 1, 4, -1, 0 },
}

-- Half the thickness of the case of a card (style: "slab", "seal"), in points.
local function DepthOf(c, style)
	return c.W * (octoConstants.DEPTH[style] or octoConstants.DEPTH.slab)
end

-- Its four edges, made once on a frame (layer, sub): strips cut along their length.
local function DepthBuild(frame, layer, sub)
	local dp = { edges = {} }
	for i = 1, 4 do
		local e = {}
		for s = 1, octoConstants.EDGE_SEGS do
			local t = frame:CreateTexture(nil, layer, nil, sub)
			if t.SetSnapToPixelGrid then
				t:SetSnapToPixelGrid(false)
				t:SetTexelSnappingBias(0)
			end
			t:Hide()
			e[s] = t
		end
		dp.edges[i] = e
	end
	return dp
end

-- Its edges where the card is (c.R, c.eye): the case of the rectangle box (from the middle of the card: x1, y1, x2, y2),
-- half as thick as d, in its style; a: how much of it is seen (the case coming down on the card).
local function DepthPaint(c, dp, box, d, style, a)
	local look = octoConstants.EDGE_LOOK[style] or octoConstants.EDGE_LOOK.slab
	if dp.style ~= style then
		dp.style = style
		for _, e in ipairs(dp.edges) do
			for _, t in ipairs(e) do
				t:SetTexture(octoConstants.MEDIA .. look.tex)
			end
		end
	end
	-- (where each piece rests, along its edge: its corners are moved from there)
	local geom = box[1] .. ":" .. box[2] .. ":" .. box[3] .. ":" .. box[4]
	local placed = dp.geom == geom
	dp.geom = geom
	local R, eye = c.R, c.eye
	for i, def in ipairs(octoConstants.EDGES) do
		local e = dp.edges[i]
		local ax, ay, bx, by = box[def[1]], box[def[2]], box[def[3]], box[def[4]]
		local nx, ny = def[5], def[6]
		local rx, ry, rz = R[1] * nx + R[2] * ny, R[4] * nx + R[5] * ny, R[7] * nx + R[8] * ny
		local mx, my = (ax + bx) / 2, (ay + by) / 2
		local cx, cy, cz = R[1] * mx + R[2] * my, R[4] * mx + R[5] * my, R[7] * mx + R[8] * my
		-- (seen when its outward side faces the eye, from its middle)
		local seen = (-rx * cx - ry * cy + rz * (eye - cz)) > 0
		if seen and a > 0.002 then
			local lit = math.min(1.25, look.amb + look.dif * math.max(0, rx * octoConstants.DLX + ry * octoConstants.DLY + rz * octoConstants.DLZ))
			local tint = look.tint
			for s = 1, octoConstants.EDGE_SEGS do
				local t = e[s]
				local f0, f1 = (s - 1) / octoConstants.EDGE_SEGS, s / octoConstants.EDGE_SEGS
				local px0, py0 = ax + (bx - ax) * f0, ay + (by - ay) * f0
				local px1, py1 = ax + (bx - ax) * f1, ay + (by - ay) * f1
				local x1, x2 = math.min(px0, px1), math.max(px0, px1)
				local y1, y2 = math.min(py0, py1), math.max(py0, py1)
				x2, y2 = math.max(x2, x1 + 1), math.max(y2, y1 + 1)
				if not placed or not t.placed then
					t.placed = true
					t:ClearAllPoints()
					t:SetPoint("TOPLEFT", c, "CENTER", x1, y2)
					CuratorOctoFull.SetSize(t, x2 - x1, y2 - y1)
					t:SetTexCoord(0, 1, f0, f1)
				end
				-- (its texture across it: its front at its left, its back at its right; along it: from its start)
				local ux, uy = Project3(c, px0, py0, d)
				local lx, ly = Project3(c, px1, py1, d)
				local qx, qy = Project3(c, px0, py0, -d)
				local wx, wy = Project3(c, px1, py1, -d)
				t:SetVertexOffset(1, ux - x1, uy - y2)
				t:SetVertexOffset(2, lx - x1, ly - y1)
				t:SetVertexOffset(3, qx - x2, qy - y2)
				t:SetVertexOffset(4, wx - x2, wy - y1)
				t:SetVertexColor(tint[1] * lit, tint[2] * lit, tint[3] * lit, look.alpha * a)
				if not e.on then
					t:Show()
				end
			end
			e.on = true
		elseif e.on then
			e.on = nil
			for _, t in ipairs(e) do
				t:Hide()
			end
		end
	end
end

-- Its edges hidden.
local function DepthHide(dp)
	for _, e in ipairs(dp.edges) do
		if e.on then
			e.on = nil
			for _, t in ipairs(e) do
				t:Hide()
			end
		end
	end
end

-- (1.14.0) What a card of a case needs to be held in the hand in 3D as these are (UI/CrateCard.lua): the same eye, the
-- same grids and cells, the same light; (after its second test) the same case in 3D.
ns.Card3D = {
	EYE = octoConstants.EYE, GLARE = octoConstants.GLARE, ROUND = octoConstants.ROUND, ROUND_MASK = octoConstants.ROUND_MASK, Project = Project, Grid = Grid, GridAt = GridAt,
	Cells = Cells, ProjectGrid = ProjectGrid, Warp = Warp, WarpQuad = WarpQuad, Paint = Paint, TexCoordOf = TexCoordOf,
	Dress = Dress, Recoord = Recoord, Band = Band, RestCenter = RestCenter, Inside = Inside,
	Project3 = Project3, DepthOf = DepthOf, DepthBuild = DepthBuild, DepthPaint = DepthPaint, DepthHide = DepthHide,
}
-- (31 October, his word: no more floating words: the words of the cards of the cases, of their labels, in letters too,
-- UI/CrateCard.lua) A word laid in letters (wd: { fs, x, y, points, frame, pool, fit }), given back, placed where the card
-- puts it (k: how large the card is near it; its letters fading as it is seen from the side).
ns.Card3D.GlyphSet = GlyphSet
ns.Card3D.GlyphRelease = GlyphRelease
ns.Card3D.GlyphPlace = function(c, wd, k)
	local fade = (wd.a or 1) * math.max(0, math.min(1, (k - 0.08) / 0.12))
	for _, e in ipairs(wd.gtex or {}) do
		WarpQuad(c, e.t, e.x1, e.y1, e.x2, e.y2)
		e.t:SetAlpha(fade * e.a)
	end
end
ns.Card3D.Codes = Codes

-------------------------------------------------------------------------------
-- (1.11.0) The case of a card appraised (Expertise.lua, UI/Expertise.lua): a slab of clear acrylic around it,
-- its label printed above it (its name, its album, its number, its four marks, its certificate, its grade, a
-- hologram), as the graders of cards seal theirs. Flat, around the card; held in 3D (the detail of a card), it
-- turns with the card: its backing behind it, its rim and its label over it, the words of the label following
-- it as the words of the card do. The geometry matches its textures (Slab*.tga).
-------------------------------------------------------------------------------
octoConstants.SLAB = { mx = 21 / 264, mb = 20 / 370, gap = 11 / 370, label = 80 / 370, mt = 17 / 370, li = 12 / 264 }
octoConstants.LABEL_W = 282 -- (the label of the card of 264 points: its pieces placed on it in its points)
octoConstants.LABEL_INK = { 0.13, 0.09, 0.05 }
-- (1.12.0) a corrupted card sealed by a Master of Warlocks (Seal.lua): the same case, in the look of the warlocks (its
-- reliquary of dark iron, its runes of fel, its pact on black vellum, the wax of its seal: Seal*.tga), in bone ink
octoConstants.SEAL_INK = { 0.9, 0.86, 0.76 }
octoConstants.SEAL_SIGIL = { 0.5, 0.95, 0.38 }
octoConstants.LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, ptBR = true, itIT = true }

-- The rectangle of the slab and of its label, from the middle of the card (x right, y up): x1, y1, x2, y2.
local function SlabRects(W, H)
	local x1, x2 = -W / 2 - W * octoConstants.SLAB.mx, W / 2 + W * octoConstants.SLAB.mx
	local y1, y2 = -H / 2 - H * octoConstants.SLAB.mb, H / 2 + H * (octoConstants.SLAB.gap + octoConstants.SLAB.label + octoConstants.SLAB.mt)
	return { x1, y1, x2, y2 }, { x1 + W * octoConstants.SLAB.li, H / 2 + H * octoConstants.SLAB.gap, x2 - W * octoConstants.SLAB.li, H / 2 + H * (octoConstants.SLAB.gap + octoConstants.SLAB.label) }
end
ns.SlabRects = SlabRects

-- The font of a label: narrow, as the printers of labels use (the default font of a client in another script).
local function LabelFont(fs, size, flags)
	local file = (octoConstants.LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] and "Fonts\\ARIALN.TTF") or nil
	if file then
		fs:SetFont(file, size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
end

-- (1.12.0) The font of a pact: the letters of the grimoires (the default font of a client in another script).
local function PactFont(fs, size, flags)
	local file = (octoConstants.LATIN[ns.locale or (GetLocale and GetLocale()) or "enUS"] and "Fonts\\MORPHEUS.TTF") or nil
	if file then
		fs:SetFont(file, size, flags or "")
	else
		ns.SetFont(fs, size, flags)
	end
end

-- A texture placed on the card at rest: its rectangle from the middle of the card (x1, y1, x2, y2).
local function PlaceRect(t, c, r)
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", c, "CENTER", r[1], r[4])
	CuratorOctoFull.SetSize(t, math.max(0.01, r[3] - r[1]), math.max(0.01, r[4] - r[2]))
end

-- The pieces of the case, flat, made the first time a card is sealed: its backing behind the card (a texture of the frame
-- low, under the body of the card), its label, its rim and its gloss over it (on a frame at the level high), the words of
-- its label over them (at the level words). (1.14.0, after its second test: the same for a card of a case,
-- UI/CrateCard.lua: ns.SlabBuild.)
local function SlabBuild(self, low, high, words)
	local W, H = self.W, self.H
	local box, lab = SlabRects(W, H)
	local k = W / 264
	local sl = { box = box, lab = lab, k = k }
	self.slab = sl
	-- behind the card: its backing (in the frame of its face, under its body)
	sl.back = low:CreateTexture(nil, "BACKGROUND", nil, -8)
	sl.back:SetTexture(octoConstants.MEDIA .. "SlabBack")
	PlaceRect(sl.back, self, box)
	-- over the card: its label, its rim, a gloss; the words of the label over them
	sl.high = CreateFrame("Frame", nil, self)
	sl.high:SetAllPoints()
	sl.high:SetFrameLevel(high)
	sl.paper = sl.high:CreateTexture(nil, "ARTWORK", nil, -4)
	sl.paper:SetTexture(octoConstants.MEDIA .. "SlabLabel")
	PlaceRect(sl.paper, self, lab)
	sl.paperBack = sl.high:CreateTexture(nil, "ARTWORK", nil, -4)
	sl.paperBack:SetTexture(octoConstants.MEDIA .. "SlabLabelBack")
	PlaceRect(sl.paperBack, self, lab)
	sl.paperBack:Hide()
	sl.band = sl.high:CreateTexture(nil, "ARTWORK", nil, -3)
	sl.band:SetTexture(octoConstants.MEDIA .. "SlabBand")
	PlaceRect(sl.band, self, lab)
	-- (the pieces of the label, in its points from its top left)
	local function OnLabel(x, y, w, h)
		return { lab[1] + x * k, lab[4] - (y + h) * k, lab[1] + (x + w) * k, lab[4] - y * k }
	end
	sl.emblemRect = OnLabel(16, 22, 36, 36)
	sl.emblem = sl.high:CreateTexture(nil, "ARTWORK", nil, -2)
	sl.emblem:SetTexture(octoConstants.MEDIA .. "Icon")
	sl.emblem:SetVertexColor(0.92, 0.86, 0.74)
	PlaceRect(sl.emblem, self, sl.emblemRect)
	sl.barcodeRect = OnLabel(octoConstants.LABEL_W - 78 - 72, 60, 64, 12)
	sl.barcode = sl.high:CreateTexture(nil, "ARTWORK", nil, -2)
	sl.barcode:SetTexture(octoConstants.MEDIA .. "SlabBarcode")
	sl.barcode:SetAlpha(0.85)
	PlaceRect(sl.barcode, self, sl.barcodeRect)
	sl.front = sl.high:CreateTexture(nil, "ARTWORK", nil, 0)
	sl.front:SetTexture(octoConstants.MEDIA .. "SlabFront")
	PlaceRect(sl.front, self, box)
	sl.holoRect = OnLabel(octoConstants.LABEL_W - 26, 56, 20, 20)
	sl.holo = sl.high:CreateTexture(nil, "OVERLAY", nil, 0)
	sl.holo:SetTexture(octoConstants.MEDIA .. "SlabHolo")
	PlaceRect(sl.holo, self, sl.holoRect)
	-- the light that passes over the acrylic now and then (and the sweep of a fresh seal)
	sl.gloss = sl.high:CreateTexture(nil, "OVERLAY", nil, 2)
	sl.gloss:SetTexture(octoConstants.MEDIA .. "Sheen")
	sl.gloss:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(sl.gloss, (box[4] - box[2]) * 1.6, (box[4] - box[2]) * 1.6)
	sl.gloss:SetPoint("CENTER", self, "CENTER", 0, (box[2] + box[4]) / 2)
	sl.gloss:SetAlpha(0)
	-- the words of the label: on a frame over everything, anchored to the label
	sl.wordsF = CreateFrame("Frame", nil, self)
	sl.wordsF:SetAllPoints()
	sl.wordsF:SetFrameLevel(words)
	sl.labelF = CreateFrame("Frame", nil, sl.wordsF)
	sl.labelF:SetPoint("TOPLEFT", self, "CENTER", lab[1], lab[4])
	CuratorOctoFull.SetSize(sl.labelF, lab[3] - lab[1], lab[4] - lab[2])
	local function Word(size, flags, point, x, y, w, justify)
		local fs = sl.labelF:CreateFontString(nil, "OVERLAY")
		LabelFont(fs, math.max(5, size * k), flags)
		fs:SetPoint(point, sl.labelF, "TOPLEFT", x * k, -y * k)
		if w then
			fs:SetWidth(w * k)
			CuratorOctoFull.SetWordWrap(fs, false)
			fs.slabW = w * k
		end
		fs:SetJustifyH(justify or "LEFT")
		fs.slabJ = justify or "LEFT"
		fs:SetTextColor(octoConstants.LABEL_INK[1], octoConstants.LABEL_INK[2], octoConstants.LABEL_INK[3])
		fs:SetShadowOffset(0, 0)
		return fs
	end
	local midW = octoConstants.LABEL_W - 64 - 78 - 6
	sl.name = Word(14, "", "TOPLEFT", 64, 11, midW)
	sl.album = Word(9.5, "", "TOPLEFT", 64, 29, midW)
	sl.marks = Word(8.5, "", "TOPLEFT", 64, 43, midW)
	sl.cert = Word(7.5, "", "TOPLEFT", 64, 61, 74)
	sl.word = Word(9, "", "TOP", octoConstants.LABEL_W - 39, 11, 74, "CENTER")
	sl.grade = Word(31, "", "CENTER", octoConstants.LABEL_W - 39, 45, nil, "CENTER")
	-- (where its grade and its hologram are, from the middle of the card: the scene of an appraisal)
	sl.gradeAt = { lab[1] + (octoConstants.LABEL_W - 39) * k, lab[4] - 45 * k, 31 * k }
	sl.holoAt = { (sl.holoRect[1] + sl.holoRect[3]) / 2, (sl.holoRect[2] + sl.holoRect[4]) / 2 }
	sl.words = { sl.name, sl.album, sl.marks, sl.cert, sl.word, sl.grade }
	sl.high:Hide()
	sl.back:Hide()
	sl.wordsF:Hide()
	return sl
end
ns.SlabBuild = SlabBuild

function Card:BuildSlab()
	if self.slab then
		return self.slab
	end
	local lvl = self:GetFrameLevel()
	return SlabBuild(self, self.front, lvl + 12, lvl + 13)
end

local SlabLabel

-- Sealed in its case (info: Expertise.lua, E:LabelOf: grade, word, name, album, num, marks, cert, color), or
-- taken out of it (nil).
function Card:SetSlab(info)
	local sl = self.slab
	if not info then
		if sl then
			sl.high:Hide()
			sl.back:Hide()
			sl.wordsF:Hide()
		end
		local was = self.slabInfo ~= nil
		self.slabInfo = nil
		self:SlabShadow()
		-- (taken out while held: the words of its label back on it, the pose drawn again)
		if was and self.held and self.held3 then
			self:SlabHold(false)
			self.heldPose = nil
			if self.held3.slabGlare then
				self.held3.slabGlare.pose, self.held3.slabGlare.on = nil, nil
			end
		end
		return
	end
	sl = self:BuildSlab()
	self.slabInfo = info
	SlabLabel(sl, info)
	sl.high:Show()
	sl.back:Show()
	sl.wordsF:Show()
	self:SlabSide(self.facing ~= "back")
	self:SlabShadow()
	if self.held3 then
		self:SlabHeld()
		if self.held then
			-- (sealed while held: its words placed again, the pieces dressed, the pose drawn again)
			self:SlabHold(false)
			self:SlabHold(true)
			self:HeldSync()
			for _, Ly in ipairs(self.held3.layers) do
				Ly.mesh.pose, Ly.mesh.on = nil, nil
			end
			for _, q in ipairs(self.held3.quads) do
				q.pose, q.x1, q.on = nil, nil, nil
			end
			if self.held3.slabGlare then
				self.held3.slabGlare.pose, self.held3.slabGlare.on = nil, nil
			end
			self.heldPose = nil
		end
	end
end

-- The words, the inks and the look of the case of info (Expertise.lua, E:LabelOf; a seal: Seal.lua), on its pieces sl
-- (SlabBuild). (1.14.0, after its second test: the cards of the cases too, UI/CrateCard.lua: ns.SlabLabel.)
function SlabLabel(sl, info)
	-- (1.12.0) sealed by a warlock: the reliquary and its pact; appraised: the slab of the expert
	local seal = info.seal == true
	local style = seal and "seal" or "slab"
	if sl.style ~= style then
		sl.style = style
		local pre = seal and "Seal" or "Slab"
		sl.back:SetTexture(octoConstants.MEDIA .. pre .. "Back")
		sl.paper:SetTexture(octoConstants.MEDIA .. pre .. "Label")
		sl.paperBack:SetTexture(octoConstants.MEDIA .. pre .. "LabelBack")
		sl.band:SetTexture(octoConstants.MEDIA .. pre .. "Band")
		sl.front:SetTexture(octoConstants.MEDIA .. pre .. "Front")
		sl.holo:SetTexture(octoConstants.MEDIA .. (seal and "SealWax" or "SlabHolo"))
		sl.emblem:SetTexture(octoConstants.MEDIA .. (seal and "SealSigil" or "Icon"))
		local ec = seal and octoConstants.SEAL_SIGIL or { 0.92, 0.86, 0.74 }
		sl.emblem:SetVertexColor(ec[1], ec[2], ec[3])
		local ink = seal and octoConstants.SEAL_INK or octoConstants.LABEL_INK
		for _, fs in ipairs(sl.words) do
			fs:SetTextColor(ink[1], ink[2], ink[3])
		end
		-- (the pact: its number and its master on one line, where the barcode was)
		local cw = (seal and 136 or 74) * sl.k
		sl.cert:SetWidth(cw)
		sl.cert.slabW = cw
		sl.certW = seal and 136 or 74
		local F = seal and PactFont or LabelFont
		F(sl.word, 9 * sl.k, "")
		F(sl.grade, 31 * sl.k, "")
	end
	local ink = seal and octoConstants.SEAL_INK or octoConstants.LABEL_INK
	local SL = ns.Masters
	local certW = seal and 136 or ((type(info.titan) == "table") and 132 or 74)
	if sl.certW ~= certW then
		sl.certW = certW
		sl.cert:SetWidth(certW * sl.k)
		sl.cert.slabW = certW * sl.k
	end
	sl.name:SetText(info.name or "")
	local m = info.marks
	if seal then
		sl.album:SetText(string.format(("%s  %s  ·  %d %%"), info.album or "", info.num or "", info.corrupt or 0))
		if m and SL then
			sl.marks:SetText(string.format(("%s %s · %s %s · %s %s · %s %s"), L["RUN"], SL.Roman(m[1]), L["SOU"], SL.Roman(m[2]), L["BND"], SL.Roman(m[3]), L["SHD"], SL.Roman(m[4])))
		else
			sl.marks:SetText("")
		end
		local pact = info.cert and string.format(L["Pact No. %s"], ns.Expertise and ns.Expertise.CertText(info.cert) or tostring(info.cert)) or ""
		if info.by and info.by ~= "" then
			pact = pact .. "  ·  " .. string.format(L["sealed by %s"], info.by)
		end
		sl.cert:SetText(pact)
		sl.barcode:Hide()
		sl.grade:SetText(info.roman or (SL and SL.Roman(info.grade)) or "")
	else
		sl.album:SetText(((info.album or "") .. "  " .. (info.num or "")))
		-- (1.13.0: a copy restored at an enchanter, Restore.lua: how many times and when, in the place of its album, in
		-- the ink of the enchanters)
		local rs = type(info.restored) == "table" and info.restored or nil
		if rs and CuratorOctoFull.Length(rs) > 0 then
			local days = {}
			for i = math.max(1, CuratorOctoFull.Length(rs) - 1), CuratorOctoFull.Length(rs) do
				local d = date("%d/%m/%y", tonumber(rs[i]) or 0)
				-- (1 November, 12 h 56: the same day twice, once)
				if days[CuratorOctoFull.Length(days)] ~= d then
					days[CuratorOctoFull.Length(days) + 1] = d
				end
			end
			sl.album:SetText(string.format(L["RESTORED ×%d · %s"], CuratorOctoFull.Length(rs), table.concat(days, ", ")))
			sl.album:SetTextColor(0.25, 0.16, 0.55)
		else
			sl.album:SetTextColor(octoConstants.LABEL_INK[1], octoConstants.LABEL_INK[2], octoConstants.LABEL_INK[3])
		end
		if m then
			sl.marks:SetText(string.format(("%s %d · %s %d · %s %d · %s %d"), L["CEN"], m[1], L["COR"], m[2], L["EDG"], m[3], L["SUR"], m[4]))
		else
			sl.marks:SetText("")
		end
		local certText = info.cert and (string.format(L["No. %s"], ns.Expertise and ns.Expertise.CertText(info.cert) or tostring(info.cert))) or ""
		-- (1 November, his word: a titanforged copy certified by a master of the mages, Mages.lua: its family and its
		-- number after its certificate, where the barcode was, in the colour of its family, darkened for the paper)
		local titan = type(info.titan) == "table" and info.titan or nil
		if titan then
			local c = titan.color or { 0.5, 0.4, 0.2 }
			local fam = ns.Expertise and ns.Expertise.Upper(titan.family or "") or string.upper(tostring(titan.family or ""))
			certText = (certText ~= "" and (certText .. "  ·  ") or "") .. string.format(("|cff%02x%02x%02x%s %s|r"), math.floor(c[1] * 0.58 * 255),
				math.floor(c[2] * 0.58 * 255), math.floor(c[3] * 0.58 * 255), fam, tostring(titan.n or ""))
		end
		sl.cert:SetText(certText)
		CuratorOctoFull.SetShown(sl.barcode, info.cert ~= nil and not titan)
		-- (1.14.0, Signature, a talent of the Archivist: the name of the collector, in the place of its album)
		if info.by and not (rs and CuratorOctoFull.Length(rs) > 0) then
			sl.album:SetText(string.format(L["APPRAISED FOR %s"], ns.Expertise and ns.Expertise.Upper(info.by) or string.upper(info.by)))
			sl.album:SetTextColor(0.42, 0.26, 0.06)
		end
		-- (1.13.0: a copy restored, its grade with its decimals, as the language writes them)
		sl.grade:SetText(info.text or tostring(info.grade or ""))
	end
	sl.word:SetText(ns.Expertise and ns.Expertise.Upper(info.word or "") or string.upper((info.word or "")))
	local c = info.color or { 1, 1, 1 }
	sl.band:SetVertexColor(c[1], c[2], c[3])
	-- (1 November: certified by a master of the mages, the hologram of the expert in the colour of its family)
	local holoTint = (not seal and type(info.titan) == "table" and info.titan.color) or nil
	-- (1.14.0, Luxury Case, a talent of the Archivist: a 9 or a 10 in a golden case)
	local lux = info.lux == true and not seal
	if sl.lux ~= lux then
		sl.lux = lux
		local f, b, h = { 1, 1, 1 }, { 1, 1, 1 }, { 1, 1, 1 }
		if lux then
			f, b, h = { 1, 0.84, 0.46 }, { 1, 0.86, 0.52 }, { 1, 0.78, 0.32 }
		end
		sl.front:SetVertexColor(f[1], f[2], f[3])
		sl.back:SetVertexColor(b[1], b[2], b[3])
		sl.holo:SetVertexColor(h[1], h[2], h[3])
		sl.paper:SetVertexColor(lux and 1 or 1, lux and 0.95 or 1, lux and 0.82 or 1)
		sl.holoTint = nil
	end
	if holoTint then
		local h = lux and { 1, 0.78, 0.32 } or { 1, 1, 1 }
		sl.holo:SetVertexColor(h[1] * (0.45 + 0.55 * holoTint[1]), h[2] * (0.45 + 0.55 * holoTint[2]), h[3] * (0.45 + 0.55 * holoTint[3]))
		sl.holoTint = true
	elseif sl.holoTint then
		local h = lux and { 1, 0.78, 0.32 } or { 1, 1, 1 }
		sl.holo:SetVertexColor(h[1], h[2], h[3])
		sl.holoTint = nil
	end
	-- (a 10: its number in gold, the others in the ink of the label; a seal: X in the fel of its rank, VII and up in
	-- its light)
	if seal then
		local g = info.grade or 0
		if g >= 7 then
			sl.grade:SetTextColor(0.55 + 0.45 * c[1], 0.55 + 0.45 * c[2], 0.55 + 0.45 * c[3])
		else
			sl.grade:SetTextColor(ink[1], ink[2], ink[3])
		end
	elseif (info.grade or 0) >= 10 then
		sl.grade:SetTextColor(0.72, 0.5, 0.06)
	else
		sl.grade:SetTextColor(octoConstants.LABEL_INK[1], octoConstants.LABEL_INK[2], octoConstants.LABEL_INK[3])
	end
	-- (the longest words a little smaller, to fit their room)
	local room = (octoConstants.LABEL_W - 64 - 78 - 6) * sl.k
	local F = seal and PactFont or LabelFont
	for _, x in ipairs({ { sl.name, 14, F }, { sl.album, 9.5, LabelFont }, { sl.marks, 8.5, LabelFont }, { sl.cert, 7.5, LabelFont, certW },
		{ sl.word, 9, F, 74 }, { sl.grade, 31, F, 74 } }) do
		local fs, size, font = x[1], x[2], x[3]
		local least = size * 0.62
		local w = x[4] and (x[4] * sl.k) or room
		font(fs, size * sl.k, "")
		-- (its whole width: GetStringWidth stops at the width of its box)
		while size > least and ns.TextWidth(fs) > w do
			size = size - 0.5
			font(fs, size * sl.k, "")
		end
	end
end
ns.SlabLabel = SlabLabel

-- How much of the case is seen (0 to 1: the case coming down on the card, UI/Expertise.lua), flat or held.
function Card:SlabAlpha(a)
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
		sl.wordsF:SetAlpha(a * (self.slabRead or 1))
	end
end

-- The side of the case seen: the label printed, or the back of its paper.
function Card:SlabSide(front)
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

-- The shadow of the card: the case's while it is in one.
function Card:SlabShadow()
	local W, H = self.W, self.H
	self.shadow:ClearAllPoints()
	if self.slabInfo and self.slab then
		local b = self.slab.box
		self.shadow:SetPoint("CENTER", self, "CENTER", (b[1] + b[3]) / 2 + 5, (b[2] + b[4]) / 2 - 7)
		CuratorOctoFull.SetSize(self.shadow, (b[3] - b[1]) / 0.62, (b[4] - b[2]) / 0.82)
	else
		self.shadow:SetPoint("CENTER", 4, -6)
		CuratorOctoFull.SetSize(self.shadow, W / 0.62, H / 0.82)
	end
end

-- (a card squeezed by a turn, a client without 3D: its case squeezed with it, its words gone past a little)
function Card:SlabSqueeze(kx, read)
	local sl = self.slab
	if not (sl and self.slabInfo) then
		return
	end
	local function Sq(r)
		return { r[1] * kx, r[2], r[3] * kx, r[4] }
	end
	PlaceRect(sl.back, self, Sq(sl.box))
	PlaceRect(sl.front, self, Sq(sl.box))
	for _, t in ipairs({ sl.paper, sl.paperBack, sl.band }) do
		PlaceRect(t, self, Sq(sl.lab))
	end
	PlaceRect(sl.emblem, self, Sq(sl.emblemRect))
	PlaceRect(sl.holo, self, Sq(sl.holoRect))
	PlaceRect(sl.barcode, self, Sq(sl.barcodeRect))
	self.slabRead = read
	sl.wordsF:SetAlpha(read * (self.slabA or 1))
end

-- The pieces of the card in 3D, made the first time it is held.
local function BuildHeld(c)
	local W, H = c.W, c.H
	local lvl = c:GetFrameLevel()
	local h = { layers = {}, quads = {}, words = {}, pose = 0 }
	c.held3 = h
	local function Level(n, parent)
		local f = CreateFrame("Frame", nil, parent or c)
		f:SetAllPoints(c)
		f:SetFrameLevel(lvl + n)
		f:Hide()
		return f
	end
	-- (at the levels of the pieces they stand for: the body and the photo on its face, under the window
	-- of the creature; the frame of metal over it, then the finishes, the pennant, the words, the back,
	-- a flash)
	h.low = Level(1, c.front)
	h.high, h.fin, h.badge, h.texts, h.back, h.hot = Level(6), Level(7), Level(8), Level(9), Level(10), Level(11)
	-- (31 October) the letters of its words held: taken from here, given back here
	h.gfree = {}
	local wx1, wx2 = -W / 2 + W * octoConstants.ART_L, W / 2 - W * octoConstants.ART_R
	local wy1, wy2 = -H / 2 + H * octoConstants.ART_B, H / 2 - H * octoConstants.ART_T
	local round = W * octoConstants.ROUND
	-- (fine cells where the drawing is fine, larger ones for the soft lights; the lights that cover the
	-- whole card stop at its round corners)
	h.grids = {
		card = Grid(-W / 2, -H / 2, W / 2, H / 2, 6, 8),
		soft = Grid(-W / 2, -H / 2, W / 2, H / 2, 3, 4),
		light = Grid(-W / 2, -H / 2, W / 2, H / 2, 4, 5, round),
		win = Grid(wx1, wy1, wx2, wy2, 4, 4),
	}
	-- (the hologram of a titanforged card: its lines along the windows of its frame, on a card of 366 x 512)
	do
		local bx = W * 30 / 366
		local xs = { -W / 2, -W / 2 + bx }
		for i = 1, 3 do
			xs[CuratorOctoFull.Length(xs) + 1] = -W / 2 + bx + (W - 2 * bx) * i / 4
		end
		xs[CuratorOctoFull.Length(xs) + 1] = W / 2 - bx
		xs[CuratorOctoFull.Length(xs) + 1] = W / 2
		local ys = {}
		for i, p in ipairs({ 0, 26, 117, 208, 298, 350, 412, 473, 512 }) do
			ys[i] = H / 2 - H * p / 512
		end
		h.grids.holo = GridAt(xs, ys, W * octoConstants.ROUND)
	end
	h.win = { wx1, wy1, wx2, wy2 }
	local o, sh, b = c.over, c.shine, c.back
	local function L(src, grid, frame, layer, sub, opts)
		local e = opts or {}
		e.src, e.mesh = src, Cells(c, frame, h.grids[grid], layer, sub)
		h.layers[CuratorOctoFull.Length(h.layers) + 1] = e
		return e
	end
	-- (alpha: a piece made invisible while held, its own light set here)
	L(c.front.base, "card", h.low, "BACKGROUND", 0, { alpha = 1 })
	L(c.art.bg, "win", h.low, "BACKGROUND", 1, { alpha = 1 })
	L(c.art.shade, "win", h.low, "BACKGROUND", 2, { alpha = 1 })
	-- (31 October, his idea: the creatures in 2D) its portrait, over the photo and its foil, turning with the card
	L(c.art.portrait, "win", h.low, "ARTWORK", 5, { wrap = "CLAMP" })
	-- (1.11.0) the foil of the window of a titanforged card: on the photo, under the creature (1.14.0, his idea: live, its colour
	-- follows the one of a pattern, Card:Holo)
	for i, f in ipairs(c.art.foil) do
		L(f, "win", h.low, "ARTWORK", i, { live = true })
	end
	L(o.border, "card", h.high, "ARTWORK", 0)
	-- (1.14.0, his idea) the metal of the frame in the colour of a pattern
	L(o.metal, "card", h.high, "ARTWORK", 1)
	-- (the foil of the frame and its dust: how much of them shows where is in their textures)
	for _, f in ipairs(sh.prism) do
		L(f, "holo", h.fin, "ARTWORK", 1, { live = true })
	end
	L(sh.rim, "soft", h.fin, "ARTWORK", 3, { live = true })
	L(sh.glitter[1], "holo", h.fin, "ARTWORK", 6, { live = true })
	L(sh.glitter[2], "holo", h.fin, "ARTWORK", 6, { live = true })
	L(sh.arcs[1], "card", h.fin, "ARTWORK", 5)
	L(sh.arcs[2], "card", h.fin, "ARTWORK", 5)
	-- (1.14.0) the embers of the contraband of the Hardcup Saison 3
	L(sh.embers, "card", h.fin, "ARTWORK", 4, { live = true })
	-- (1.12.0) the corruption of a corrupted card
	L(sh.voidFull, "card", h.fin, "ARTWORK", 2)
	L(sh.voidOld, "card", h.fin, "ARTWORK", 0, { live = true })
	L(sh.void, "card", h.fin, "ARTWORK", 1, { live = true })
	L(sh.glowOld, "card", h.fin, "ARTWORK", 3, { live = true })
	L(sh.glow, "card", h.fin, "ARTWORK", 3, { live = true })
	L(sh.eyes[1], "card", h.fin, "ARTWORK", 4, { live = true })
	L(sh.eyes[2], "card", h.fin, "ARTWORK", 4, { live = true })
	-- (the back is seen from behind: its left on the right)
	L(b.tex, "card", h.back, "ARTWORK", 0, { flip = true })
	L(b.cracks, "soft", h.back, "ARTWORK", 3, { flip = true })
	L(b.glow, "soft", h.back, "OVERLAY", 0, { flip = true })
	L(c.hot, "soft", h.hot, "OVERLAY", 0)
	-- the light: the sweep of a finish, the light of the room on each side
	h.sweep = Cells(c, h.fin, h.grids.light, "OVERLAY", 0)
	h.glare = Cells(c, h.fin, h.grids.light, "OVERLAY", 2)
	h.backGlare = Cells(c, h.back, h.grids.light, "OVERLAY", 2)
	for _, m in ipairs({ h.sweep, h.glare, h.backGlare }) do
		for _, t in ipairs(m) do
			t:SetTexture(octoConstants.MEDIA .. "Sheen")
			t:SetBlendMode("ADD")
		end
	end
	-- the small pieces, one cell each (rect: where they are on the card at rest; turn: they turn)
	local function Q(src, frame, layer, sub, rect, turn)
		local t = frame:CreateTexture(nil, layer, nil, sub)
		if t.SetSnapToPixelGrid then
			t:SetSnapToPixelGrid(false)
			t:SetTexelSnappingBias(0)
		end
		t:Hide()
		h.quads[CuratorOctoFull.Length(h.quads) + 1] = { src = src, t = t, rect = rect, turn = turn }
	end
	local function Box(cx, cy, w, hh)
		return function()
			return cx - w / 2, cy - hh / 2, cx + w / 2, cy + hh / 2
		end
	end
	local gs = W * octoConstants.GEM_S
	Q(o.gem, h.high, "OVERLAY", 0, Box(0, H / 2 - H * octoConstants.GEM_Y, gs, gs))
	-- (1.12.0) the skull on the crest of a mythic card of Hallow's End, its spikes behind it
	Q(o.crestBack, h.high, "OVERLAY", 1, Box(0, H / 2 - H * octoConstants.CREST_SPIKES[3], W * octoConstants.CREST_SPIKES[1], W * octoConstants.CREST_SPIKES[2]))
	Q(o.crest, h.high, "OVERLAY", 2, Box(0, H / 2 - H * octoConstants.CREST_SKULL[2], W * octoConstants.CREST_SKULL[1], W * octoConstants.CREST_SKULL[1]))
	-- (the pumpkin of the medallion: where it is, as big as it is; round as on the flat card)
	Q(o.crestIcon, h.high, "OVERLAY", 1, function()
		local cw, ch = CuratorOctoFull.GetSize(o.crestIcon)
		local _, _, _, _, y = o.crestIcon:GetPoint(1)
		if not (cw and y) then
			return nil
		end
		local cy = H / 2 + y
		return -cw / 2, cy - ch / 2, cw / 2, cy + ch / 2
	end)
	do
		local q = h.quads[CuratorOctoFull.Length(h.quads)]
		local m = CuratorOctoFull.CreateMaskTexture(h.high)
		m:SetTexture(octoConstants.ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		m:SetAllPoints(q.t)
		CuratorOctoFull.AddMaskTexture(q.t, m)
	end
	Q(o.set, h.high, "OVERLAY", 0, Box(-W / 2 + W * octoConstants.SET_X, H / 2 - H * octoConstants.NUM_Y, W * 0.06, W * 0.06))
	-- (1.12.0, later: the plate of a limited edition)
	Q(o.edition, h.high, "OVERLAY", -1, Box(c.small and W * octoConstants.PLATE_X_S or 0, H / 2 - H * octoConstants.NUM_Y, W * (c.small and octoConstants.PLATE_W_S or octoConstants.PLATE_W), H * (c.small and octoConstants.PLATE_H_S or octoConstants.PLATE_H)))
	for _, tw in ipairs(sh.twinkles) do
		local _, tw = _, tw; Q(tw, h.fin, "OVERLAY", 1, function()
			local _, _, _, x, y = tw:GetPoint(1)
			if not x then
				return nil
			end
			local w, hh = CuratorOctoFull.GetSize(tw)
			local cx, cy = -W / 2 + x, H / 2 + y
			return cx - w / 2, cy - hh / 2, cx + w / 2, cy + hh / 2
		end, true)
	end
	local bw, bh = CuratorOctoFull.GetSize(c.badge)
	local bcx, bcy = W / 2 - bw * 0.38, H / 2 - H * 0.075
	h.badgeRect = { bcx - bw / 2, bcy - bh / 2, bcx + bw / 2, bcy + bh / 2 }
	Q(c.badge.tex, h.badge, "ARTWORK", 0, Box(bcx, bcy, bw, bh))
	Q(b.core, h.back, "ARTWORK", 2, Box(0, 0, W * 0.7, W * 0.7))
	h.Q, h.L, h.Level = Q, L, Level
	-- (his idea, 31 October: the pieces of its wear held with it, UI/Wear.lua)
	if ns.WearUI then
		ns.WearUI.Held(c, h)
	end
	return h
end

-- (1.11.0) The case in 3D: its backing under the body of the card, its rim and its label over everything, the
-- words of its label on a frame of their own; made once, the first time a card sealed is held.
function Card:SlabHeld()
	local h, sl = self.held3, self.slab
	if not (h and sl) or h.slabBuilt then
		return
	end
	h.slabBuilt = true
	local box, lab = sl.box, sl.lab
	h.grids.slab = Grid(box[1], box[2], box[3], box[4], 6, 10)
	h.grids.label = Grid(lab[1], lab[2], lab[3], lab[4], 6, 2)
	-- (1.14.0, after its second test: its face over the card, as far from it as the case is thick; SetPose)
	h.grids.slabF = Grid(box[1], box[2], box[3], box[4], 6, 10)
	h.grids.slabF.z = DepthOf(self, "slab")
	h.slabHigh = h.Level(12)
	h.slabTexts = h.Level(13)
	-- (its backing: drawn as the case is, its flat piece hidden meanwhile)
	h.slabBackL = h.L(sl.back, "slab", h.low, "BACKGROUND", -8, { alpha = self.slabA or 1 })
	h.L(sl.paper, "label", h.slabHigh, "ARTWORK", -4)
	h.L(sl.paperBack, "label", h.slabHigh, "ARTWORK", -4)
	h.L(sl.band, "label", h.slabHigh, "ARTWORK", -3)
	h.slabPlate = h.L(sl.front, "slabF", h.slabHigh, "ARTWORK", 0)
	-- (its four edges, under its labels and its face)
	h.slabDepth = DepthBuild(h.slabHigh, "ARTWORK", -7)
	local function R(rect)
		return function()
			return rect[1], rect[2], rect[3], rect[4]
		end
	end
	h.Q(sl.emblem, h.slabHigh, "ARTWORK", -2, R(sl.emblemRect))
	h.Q(sl.barcode, h.slabHigh, "ARTWORK", -2, R(sl.barcodeRect))
	h.Q(sl.holo, h.slabHigh, "OVERLAY", 0, R(sl.holoRect))
	-- the light of the room on the acrylic: over the whole case
	h.slabGlare = Cells(self, h.slabHigh, h.grids.slabF, "OVERLAY", 2)
	for _, t in ipairs(h.slabGlare) do
		t:SetTexture(octoConstants.MEDIA .. "Sheen")
		t:SetBlendMode("ADD")
	end
	h.slabWords = {}
end

-- The words of the label put on the frame of the case in 3D (on), or back on the label (off).
function Card:SlabHold(on)
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
			-- (placed by the middle of its words, not of its box: in 3D its box is as wide as its words and they
			-- stand in its middle, so that scaled and turned they stay where they were printed, whatever the
			-- client does of a box set wider than its words)
			w.x, w.y = RestCenter(self, fs, rects)
			fs:SetParent(h.slabTexts)
			fs:SetWidth(0)
			fs:SetJustifyH("CENTER")
			-- (31 October, his word: the words of the label of its case in letters too, on the case, narrowed to their room)
			w.slab, w.fit, w.frame = true, true, h.slabTexts
			h.sgfree = h.sgfree or {}
			w.pool = h.sgfree
			h.slabWords[CuratorOctoFull.Length(h.slabWords) + 1] = w
		end
		h.slabTexts:SetAlpha(self.slabA or 1)
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
		for _, w in ipairs(h.slabWords or {}) do
			GlyphRelease(h, w)
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
		if h.slabWords then
			CuratorOctoFull.Wipe(h.slabWords)
		end
		h.slabHigh:Hide()
		h.slabTexts:Hide()
	end
end

-- The look of the pieces in 3D, from the pieces drawn flat (their texture, colour, light).
function Card:HeldSync()
	local h = self.held3
	if not h then
		return
	end
	for _, L in ipairs(h.layers) do
		Dress(L.mesh, L.src, L.flip, L.wrap)
		L.mesh.a = nil
		L.u0, L.r = nil, nil
	end
	for _, q in ipairs(h.quads) do
		local t, src = q.t, q.src
		-- (1.12.0: a piece of an atlas of the game, the skull on the crest of a card of Hallow's End: the same atlas)
		local atlas = src.GetAtlas and src:GetAtlas()
		if atlas then
			t:SetAtlas(atlas)
		else
			t:SetTexture(src:GetTexture())
			t:SetTexCoord(TexCoordOf(src))
		end
		t:SetVertexColor(src:GetVertexColor())
		t:SetBlendMode(src:GetBlendMode() or "BLEND")
		CuratorOctoFull.SetDesaturated(t, src:IsDesaturated() and true or false)
	end
	-- (his idea, 31 October: the wear of its copy cut into cells that lie on the card held, UI/Wear.lua)
	if ns.WearUI then
		ns.WearUI.Mesh(self)
	end
	local sheen = self.shine.sheen
	local r, g, b = sheen:GetVertexColor()
	for _, t in ipairs(h.sweep) do
		t:SetVertexColor(r or 1, g or 1, b or 1)
	end
end

-- Held in the hand (in 3D), or put down (flat again, as it was).
function Card:Hold(on)
	on = on and true or false
	if on == (self.held or false) or (on and not ns.Can3D()) then
		return
	end
	local h = self.held3 or BuildHeld(self)
	local W, H = self.W, self.H
	local o, f, art, m = self.over, self.front, self.art, self.model
	-- (31 October, his test: the rays behind the creature of the best cards, held, were cut to the flat rectangle of the
	-- creature, a square of light on the card turned: hidden while it is held)
	local hidden = { f.base, art.bg, art.shade, art.foilF, art.rays:GetParent(), art.portraitF, o, self.shine, self.back,
		self.hot:GetParent(), self.badge, self.wearF }
	if on then
		self.held = true
		for _, x in ipairs(hidden) do
			x:SetAlpha(0)
		end
		if self.glare then
			self.glare:SetAlpha(0)
		end
		for _, x in ipairs({ h.low, h.high, h.fin, h.badge, h.texts, h.back, h.hot }) do
			x:Show()
		end
		-- the words: on a frame of their own, placed by the card
		local rects = { [self] = { -W / 2, -H / 2, W / 2, H / 2 }, [self.badge] = h.badgeRect }
		CuratorOctoFull.Wipe(h.words)
		for _, fs in ipairs({ o.level, o.name, o.sub, o.rar, o.num, o.pattern, o.count, o.corrupt, o.edName, o.edYear, self.badge.text }) do
			local w = { fs = fs, parent = fs:GetParent(), points = {}, a = fs:GetAlpha(), shown = fs:IsShown() }
			for i = 1, fs:GetNumPoints() do
				w.points[i] = { fs:GetPoint(i) }
			end
			w.x, w.y = RestCenter(self, fs, rects)
			fs:SetParent(h.texts)
			-- (under the wear of its copy, as on the card put down, UI/Wear.lua: its cells over them)
			w.layer, w.sub = fs:GetDrawLayer()
			fs:SetDrawLayer("ARTWORK", 0)
			h.words[CuratorOctoFull.Length(h.words) + 1] = w
		end
		-- (1.11.0) its case, when it is in one
		if self.slab then
			self:SlabHeld()
			self:SlabHold(true)
		end
		self:HeldSync()
		for _, L in ipairs(h.layers) do
			L.mesh.pose, L.mesh.on = nil, nil
		end
		for _, m2 in ipairs({ h.sweep, h.glare, h.backGlare, h.slabGlare }) do
			m2.pose, m2.on, m2.a = nil, nil, nil
		end
		h.sweepX, h.sweepY = nil, nil
		for _, q in ipairs(h.quads) do
			q.pose, q.x1, q.on = nil, nil, nil
		end
		self.heldPose = nil
	else
		self.held = false
		for _, x in ipairs(hidden) do
			x:SetAlpha(1)
		end
		for _, x in ipairs({ h.low, h.high, h.fin, h.badge, h.texts, h.back, h.hot }) do
			x:Hide()
		end
		for _, w in ipairs(h.words) do
			GlyphRelease(h, w)
			local fs = w.fs
			fs:SetParent(w.parent)
			fs:SetDrawLayer(w.layer or "OVERLAY", w.sub or 0)
			fs:ClearAllPoints()
			for _, p in ipairs(w.points) do
				fs:SetPoint(unpack(p))
			end
			fs:SetAlpha(w.a)
			CuratorOctoFull.SetShown(fs, w.shown)
			if fs.SetTextScale then
				fs:SetTextScale(1)
			end
			if fs.SetRotation then
				CuratorOctoFull.SetRotation(fs, 0)
			end
		end
		CuratorOctoFull.Wipe(h.words)
		if self.slab then
			self:SlabHold(false)
		end
		-- the window of the creature, the creature and its camera, the shadow, the glow as they were
		art:ClearAllPoints()
		art:SetPoint("TOPLEFT", W * octoConstants.ART_L, -H * octoConstants.ART_T)
		art:SetPoint("BOTTOMRIGHT", -W * octoConstants.ART_R, H * octoConstants.ART_B)
		m:ClearAllPoints()
		m:SetAllPoints(art)
		self:SlabShadow()
		self.glow:ClearAllPoints()
		self.glow:SetPoint("CENTER")
		CuratorOctoFull.SetSize(self.glow, W / 0.46 * 1.05, H / 0.64 * 1.05)
		self.heldYaw, self.heldPitch, self.heldPose = nil, nil, nil
		self:Freeze(false)
		if m.actor and m.box then
			Place(m)
		end
	end
end

-- Its creature still (while the card moves), or living again (and playing what it was asked to play
-- meanwhile).
function Card:Freeze(on)
	on = on and true or false
	if (self.frozen or false) == on then
		return
	end
	self.frozen = on
	local m = self.model
	if m.SetPaused then
		pcall(m.SetPaused, m, on or (m.silhouette and true) or Still())
	end
	local w = not on and self.animWait
	if w then
		self.animWait = nil
		self:Animate(w.owner)
	end
end

-- Held in the hand, turned (yaw: round its upright axis, all the way; its back past a quarter turn)
-- and tilted (pitch: its top toward the eye), in perspective. A client that cannot move the corners
-- of a texture: squeezed, as before (SetTurn).
function Card:SetPose(yaw, pitch)
	pitch = pitch or 0
	if not ns.Can3D() then
		return self:SetTurn(yaw, pitch)
	end
	self:Hold(true)
	local h = self.held3
	-- its creature turned on its own as it is asked (the detail of a card turns it, left alone): in a
	-- scene, the camera still goes round it as round the card; a model frame turns it with the card
	local m = self.model
	-- (the creatures as a still picture: it keeps its facing)
	local facing = (Still() and (m.facing or 0.4)) or self.turnFacing or 0.4
	if m.actor then
		if m.yaw ~= facing then
			CuratorOctoFull.SetRotation(m, facing)
		end
	elseif m.SetRotation then
		CuratorOctoFull.SetRotation(m, facing + yaw)
	end
	local p = self.heldPose
	if p and math.abs(p[1] - yaw) < 1e-5 and math.abs(p[2] - pitch) < 1e-5 and p[3] == self.facing then
		return
	end
	self.turned = true
	local cy, sy, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
	-- (the side it shows; its creature comes back at once in a scene, once it is wide in a model frame)
	local side = (cy * cp >= 0) and "front" or "back"
	if side ~= self.facing then
		self.facing = side
		self:ApplySide(not m.actor)
		self:SlabSide(side == "front")
	end
	self.heldPose = { yaw, pitch, self.facing }
	-- the turn, then the tilt: R = Rx(pitch) Ry(yaw); the eye at EYE heights of the card
	local R = self.R or {}
	self.R = R
	R[1], R[2], R[3] = cy, 0, sy
	R[4], R[5], R[6] = sp * sy, cp, -sp * cy
	R[7], R[8], R[9] = -cp * sy, sp, cp * cy
	self.eye = octoConstants.EYE * self.H
	self.heldYaw, self.heldPitch = yaw, pitch
	h.pose = h.pose + 1
	-- (1.14.0, after its second test) its case: its face turned to the eye, as far from the card as the case is thick (seen
	-- from behind, the face of its back, its acrylic or its iron the other way round)
	local style = (self.slabInfo and self.slabInfo.seal) and "seal" or "slab"
	local depth = DepthOf(self, style)
	if h.grids.slabF then
		h.grids.slabF.z = (side == "front") and depth or -depth
	end
	local plate = h.slabPlate
	if plate and (plate.flip or false) ~= (side == "back") then
		plate.flip = side == "back"
		Dress(plate.mesh, plate.src, plate.flip, plate.wrap)
		plate.mesh.a, plate.mesh.pose = nil, nil
	end
	for _, g in pairs(h.grids) do
		ProjectGrid(self, g)
	end
	local H = self.H
	local front = side == "front"
	-- the window of the creature: what the card shows of it (the largest rectangle in it); the creature
	-- as large as the card is near there, its camera round it
	local wx1, wy1, wx2, wy2 = h.win[1], h.win[2], h.win[3], h.win[4]
	local ulx, uly = Project(self, wx1, wy2)
	local urx, ury = Project(self, wx2, wy2)
	local llx, lly = Project(self, wx1, wy1)
	local lrx, lry = Project(self, wx2, wy1)
	local x1, y1, x2, y2
	if front then
		x1, y1, x2, y2 = Inside(ulx, uly, urx, ury, llx, lly, lrx, lry)
	end
	local art = self.art
	art:ClearAllPoints()
	if x1 then
		art:SetPoint("BOTTOMLEFT", self, "CENTER", x1, y1)
		art:SetPoint("TOPRIGHT", self, "CENTER", x2, y2)
	else
		art:SetPoint("CENTER", self, "CENTER", 0, 0)
		CuratorOctoFull.SetSize(art, 0.01, 0.01)
	end
	local mx, my, mk = Project(self, 0, (wy1 + wy2) / 2)
	m:ClearAllPoints()
	m:SetPoint("CENTER", self, "CENTER", mx, my)
	CuratorOctoFull.SetSize(m, (wx2 - wx1) * mk, (wy2 - wy1) * mk)
	if m.actor then
		ns.OrbitScene(m)
	end
	if front and cy * cp > 0.5 and self.needModel then
		self:ReloadModel()
	end
	-- the shadow on the table, the glow behind: under the card as it is seen (its case, when it is in one)
	local g = (self.slabInfo and h.grids.slab) or h.grids.soft
	local w = g.cols + 1
	local n = w * (g.rows + 1)
	local bx1, by1, bx2, by2 = CuratorOctoFull.Huge, CuratorOctoFull.Huge, -CuratorOctoFull.Huge, -CuratorOctoFull.Huge
	for _, k in ipairs({ 1, w, n - w + 1, n }) do
		bx1, bx2 = math.min(bx1, g.px[k]), math.max(bx2, g.px[k])
		by1, by2 = math.min(by1, g.py[k]), math.max(by2, g.py[k])
	end
	local bcx, bcy, bw, bh = (bx1 + bx2) / 2, (by1 + by2) / 2, math.max(1, bx2 - bx1), math.max(1, by2 - by1)
	self.shadow:ClearAllPoints()
	self.shadow:SetPoint("CENTER", self, "CENTER", bcx + 4 - R[3] * 14, bcy - 6 - R[6] * 10)
	CuratorOctoFull.SetSize(self.shadow, bw / 0.62, bh / 0.82)
	self.glow:ClearAllPoints()
	self.glow:SetPoint("CENTER", self, "CENTER", bcx, bcy)
	CuratorOctoFull.SetSize(self.glow, bw / 0.46 * 1.05, bh / 0.64 * 1.05)
	-- the words follow the card: placed, turned and scaled with it; seen too much from the side, gone (the
	-- words of its label too)
	local all = h.words
	if h.slabWords and CuratorOctoFull.Length(h.slabWords) > 0 then
		all = {}
		for _, wd in ipairs(h.words) do
			all[CuratorOctoFull.Length(all) + 1] = wd
		end
		for _, wd in ipairs(h.slabWords) do
			all[CuratorOctoFull.Length(all) + 1] = wd
		end
	end
	for _, wd in ipairs(all) do
		local fs = wd.fs
		local px, py = Project(self, wd.x, wd.y)
		local ax, ay = Project(self, wd.x + 4, wd.y)
		local qx, qy = Project(self, wd.x, wd.y + 4)
		local k = math.min(math.sqrt((ax - px) ^ 2 + (ay - py) ^ 2), math.sqrt((qx - px) ^ 2 + (qy - py) ^ 2)) / 4
		-- (31 October) its letters, when the atlas has them all: in the card, bent with it (laid again when its text or its
		-- size changed)
		if wd.glyph ~= false and (wd.text ~= fs:GetText() or wd.size ~= CuratorOctoFull.Select(2, fs:GetFont())) then
			GlyphSet(self, h, wd)
		end
		if wd.gtex then
			fs:SetAlpha(0)
			local fade = wd.a * math.max(0, math.min(1, (k - 0.08) / 0.12))
			for _, e in ipairs(wd.gtex) do
				WarpQuad(self, e.t, e.x1, e.y1, e.x2, e.y2)
				e.t:SetAlpha(fade * e.a)
			end
		end
		fs:ClearAllPoints()
		fs:SetPoint("CENTER", self, "CENTER", px, py)
		if not wd.gtex then
			if fs.SetTextScale then
				fs:SetTextScale(math.max(0.05, k))
			end
			if fs.SetRotation then
				CuratorOctoFull.SetRotation(fs, math.atan2(ay - py, ax - px))
			end
			fs:SetAlpha(wd.a * math.max(0, math.min(1, (k - 0.3) / 0.25)))
		end
	end
	CuratorOctoFull.SetShown(h.texts, front)
	if h.slabTexts then
		CuratorOctoFull.SetShown(h.slabTexts, front and self.slabInfo ~= nil)
	end
	-- (its four edges, where the eye sees them)
	if h.slabDepth then
		if self.slabInfo and h.slabOn then
			h.slabDepthA = self.slabA or 1
			DepthPaint(self, h.slabDepth, self.slab.box, depth, style, h.slabDepthA)
		else
			DepthHide(h.slabDepth)
		end
	end
	-- the light of the room on the card: it moves over it as it turns, brighter the more it leans
	local nx, ny = R[3], R[6]
	local lean = math.min(1, 2.2 * math.sqrt(nx * nx + ny * ny))
	local d = (ny - nx) * H * 0.5
	h.glareA = octoConstants.GLARE * lean
	Band(front and h.glare or h.backGlare, d * 0.7071, -d * 0.7071, H * 2)
	if h.slabGlare then
		Band(h.slabGlare, d * 0.7071, -d * 0.7071 + H * 0.15, H * 2.6)
	end
	self:HeldPaint()
end

-- Every frame (Tick): the pieces in 3D shown as the pieces drawn flat are, with their light; the small
-- pieces that move (the twinkles), the sweep of a finish, the light of the room.
function Card:HeldPaint()
	local h = self.held3
	if not (self.held and h and self.R) then
		return
	end
	local pose = h.pose
	for _, L in ipairs(h.layers) do
		local src = L.src
		local a = L.alpha or src:GetAlpha()
		local on = src:IsVisible() and a > 0.002
		if on and L.live then
			Recoord(L)
		end
		Paint(L.mesh, on, a, pose)
	end
	-- (a word seen as its frame of before is: the pennant hidden, its word too; its letters with it)
	for _, w in ipairs(h.words) do
		local on = w.shown and w.parent:IsVisible()
		if on ~= w.fs:IsShown() then
			CuratorOctoFull.SetShown(w.fs, on)
		end
		if w.gtex and w.gon ~= on then
			w.gon = on
			for _, e in ipairs(w.gtex) do
				CuratorOctoFull.SetShown(e.t, on)
			end
		end
	end
	for _, w in ipairs(h.slabWords or {}) do
		local on = w.shown and w.parent:IsVisible()
		if on ~= w.fs:IsShown() then
			CuratorOctoFull.SetShown(w.fs, on)
		end
		if w.gtex and w.gon ~= on then
			w.gon = on
			for _, e in ipairs(w.gtex) do
				CuratorOctoFull.SetShown(e.t, on)
			end
		end
	end
	for _, q in ipairs(h.quads) do
		local src, t = q.src, q.t
		local on = src:IsVisible() and src:GetAlpha() > 0.002
		if on then
			local x1, y1, x2, y2 = q.rect()
			if x1 then
				if x1 ~= q.x1 or y1 ~= q.y1 or x2 ~= q.x2 or y2 ~= q.y2 then
					q.x1, q.y1, q.x2, q.y2 = x1, y1, x2, y2
					t:ClearAllPoints()
					t:SetPoint("TOPLEFT", self, "CENTER", x1, y2)
					CuratorOctoFull.SetSize(t, math.max(0.01, x2 - x1), math.max(0.01, y2 - y1))
					q.pose = nil
				end
				if q.pose ~= pose then
					WarpQuad(self, t, x1, y1, x2, y2)
					q.pose = pose
				end
				t:SetAlpha(src:GetAlpha())
				if q.turn then
					CuratorOctoFull.SetRotation(t, CuratorOctoFull.GetRotation(src))
				end
			else
				on = false
			end
		end
		if on ~= q.on then
			q.on = on
			CuratorOctoFull.SetShown(t, on)
		end
	end
	-- (his idea, 31 October: the wear of its copy, its cells where the card puts them, UI/Wear.lua)
	if ns.WearUI then
		ns.WearUI.HeldPaint(self, pose)
	end
	-- the sweep of a finish passes over the card as over the flat one
	local sheen = self.shine.sheen
	local on = sheen:IsVisible() and sheen:GetAlpha() > 0.002
	if on then
		local _, _, _, x, y = sheen:GetPoint(1)
		local gx, gy = x or 0, y or 0
		if gx ~= h.sweepX or gy ~= h.sweepY then
			h.sweepX, h.sweepY = gx, gy
			Band(h.sweep, gx, gy, sheen:GetWidth())
		end
	end
	Paint(h.sweep, on, sheen:GetAlpha(), pose)
	local front = self.facing ~= "back"
	Paint(h.glare, front and (h.glareA or 0) > 0.002, h.glareA or 0, pose)
	Paint(h.backGlare, not front and (h.glareA or 0) > 0.002, h.glareA or 0, pose)
	if h.slabGlare then
		local ga = self.slabInfo and (0.05 + 0.6 * (h.glareA or 0)) * (self.slabA or 1) or 0
		Paint(h.slabGlare, ga > 0.002, ga, pose)
	end
	-- (its edges as much as the case is seen: the case coming down on the card)
	if h.slabDepth and self.slabInfo and h.slabOn and h.slabDepthA ~= (self.slabA or 1) then
		local style = self.slabInfo.seal and "seal" or "slab"
		h.slabDepthA = self.slabA or 1
		DepthPaint(self, h.slabDepth, self.slab.box, DepthOf(self, style), style, h.slabDepthA)
	end
end
