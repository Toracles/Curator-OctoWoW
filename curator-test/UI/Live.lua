local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

-- The boosters the guild opens, live. When a guild member opens a booster that holds a legendary or
-- a mythic card, or a holographic (titanforged) one, a small panel comes under the alerts: their pack
-- shakes, its light climbs to the colour of the best card inside; when they turn that card over, it
-- shows on the panel. A click on it opens their album. /curator live turns it off.
-- (1.14.2, his word: "when someone of your guild opens a booster or a case, as soon as it is a rare or better we all see
-- it with a small animation; I want it to come out more often: rare at least, and titanforged and thunderforged too")
-- * A booster from a rare card up, or with a forged card whatever its rarity (Comm.lua: G.Worth). The card it shows comes
--   with it (G.Star): its light climbs to the colour of that card; the pull of that card (turned over, epic or better, or
--   forged) shows it; a rare one, not forged, sends none: it shows once its light has climbed.
-- * Every case opened (Cases.lua: the cases of the Paladin Collection): the case in its own art (UI/CrateBox.lua) shakes,
--   its light climbs from the colour of the Rare rank to the one of the rank of what came while the band of its opener
--   runs (UI/Crate.lua), its lid opens and what came shows, as the small cards of the cases are (UI/CaseCards.lua).
-- * One panel at a time: the others wait their turn (QUEUE at most, one of each member: the finer one), and the panel
--   shown goes sooner while another waits; a card turned over meanwhile shows when its turn comes (no alert of its own).
--   Its sounds as before, one panel after the other, a breath between two.
-- (1.14.3, the players' word: "a fully hide and move function", "turn off pop-ups from other people's pulls", "only
-- the epic or legendary cards of the guild") The switch of the options turns off all that comes from the guild on the
-- screen: this panel, the alerts of its pulls, its trades and its achievements (UI/Toast.lua), the golden quests in
-- the chat (UI/Golden.lua); epic and better only, the rest of the guild left out (V:Allows); the alerts and this panel
-- moved together where the player likes (V:Mover).
local V = { queue = {} }
ns.Live = V
-- (what calls the next panel: never cancelled with the panel shown)
local NEXT = {}

local W, H = 276, 96
local WAIT = 45      -- seconds the panel waits for the card to be turned over
local HOLD = 4.5     -- then shows it, as long as the alerts of the game
local FADE = 1.5
local STEP = 0.7     -- the light climbs a colour every STEP seconds
local PACK_W, PACK_H = 28, 56
-- (1.14.2) the openings waiting their turn, at most; how long one waits at most (its card not come yet); while another
-- waits, a panel waits its card so long at most once its light climbed, and shows it so long; the breath between two
-- panels; a card that sends no pull (a rare one, not forged): shown so long after its light climbed
local QUEUE, STALE, BUSY, HOLD_BUSY, GAP, SOON = 3, 60, 10, 3, 0.6, 2.4
-- (1.14.2) the case on the panel (UI/CrateBox.lua: its frame this wide), the card that came out of it (UI/CaseCards.lua);
-- the seconds its band runs before its card comes out at its opener's (UI/Crate.lua: CR.AT_RUN, CR.SPIN, CR.AT_CARD),
-- less the way of the message; so many while another waits; its light climbs a rank this far apart, the last one this
-- long before its card
local CASE_W, CASE_CARD = 84, 42
local CASE_RUN, CASE_BUSY, CASE_STEP, CASE_LAST = 7.6, 4, 1.2, 1

local function Fit(fs, text, width, size, minSize)
	ns.SetFont(fs, size)
	fs:SetText(text)
	while size > minSize and ns.TextWidth(fs) > width do
		size = size - 0.5
		ns.SetFont(fs, size)
	end
end

-- (1.14.2) The sounds of the panel: one at a time (a second within this many seconds of the last one is left out).
local SOUND_GAP = 1
local lastSound = -100
local function Sound(snd)
	local now = GetTime()
	if now - lastSound < SOUND_GAP then
		return
	end
	lastSound = now
	ns.Play(snd)
end

-- The colour of a rank of the cases (UI/Crate.lua: CR.RANKS), of its words.
local function RankOf(r)
	local CR = ns.CrateUI
	local ranks = CR and CR.RANKS
	return ranks and (ranks[r] or ranks[1]) or { label = "Rare", color = { 0.29, 0.41, 1 } }
end

function V:Build()
	if self.frame then
		return
	end
	local f = CreateFrame("Button", "CuratorLive", UIParent)
	CuratorOctoFull.SetSize(f, W, H)
	-- (1.14.3: under the alerts, where the player put them)
	local x, y = self:AlertsAt()
	f:SetPoint("TOP", UIParent, "TOP", x, y - self.PANEL_GAP)
	-- over the album, under the booster scene (a booster of mine being opened leaves no room for it)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(120)
	f:Hide()
	self.frame = f
	f.bg = f:CreateTexture(nil, "BACKGROUND")
	f.bg:SetTexture("Interface\\LootFrame\\LootToast")
	f.bg:SetTexCoord(0.28222656, 0.55175781, 0.578125, 0.953125)
	CuratorOctoFull.SetSize(f.bg, W, H)
	f.bg:SetPoint("CENTER")
	-- the pack, its light behind it
	f.halo = f:CreateTexture(nil, "BORDER")
	f.halo:SetTexture(MEDIA .. "Glow")
	f.halo:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.halo, 124, 140)
	f.halo:SetPoint("CENTER", f, "TOPLEFT", 48, -49)
	f.halo:SetAlpha(0)
	-- the rays that turn behind it, as behind the best cards of a booster
	f.rays = f:CreateTexture(nil, "BORDER", nil, 1)
	f.rays:SetTexture(MEDIA .. "Rays")
	f.rays:SetBlendMode("ADD")
	CuratorOctoFull.SetSize(f.rays, 104, 104)
	f.rays:SetPoint("CENTER", f, "TOPLEFT", 48, -49)
	f.rays:SetAlpha(0)
	f.pack = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.pack, PACK_W, PACK_H)
	f.pack:SetPoint("CENTER", f, "TOPLEFT", 48, -49)
	f.pack.bottom = f.pack:CreateTexture(nil, "ARTWORK")
	f.pack.bottom:SetAllPoints()
	f.pack.top = f.pack:CreateTexture(nil, "ARTWORK", nil, 1)
	f.pack.top:SetPoint("TOPLEFT")
	f.pack.top:SetPoint("TOPRIGHT")
	f.pack.top:SetHeight(PACK_H * 64 / 512)
	f.pack.wash = f.pack:CreateTexture(nil, "OVERLAY")
	f.pack.wash:SetAllPoints()
	f.pack.wash:SetTexture(MEDIA .. "Glow")
	f.pack.wash:SetBlendMode("ADD")
	f.pack.wash:SetAlpha(0)
	-- the card, once it is turned over (as on the alerts of the cards)
	local card = ns.NewCard(f, "small")
	card:SetScale(0.4)
	card:SetPoint("CENTER", f, "TOPLEFT", 48 / 0.4, -49 / 0.4)
	card:EnableMouse(false)
	card.shadow:SetAlpha(0.5)
	card:Hide()
	f.card = card
	-- the texts keep to the panel: made smaller first, then cut by the client
	f.textW = 170
	f.label = S.Text(f, "GameFontNormal", "LEFT")
	f.label:SetPoint("TOPLEFT", 81, -23)
	f.label:SetWidth(f.textW + 8)
	CuratorOctoFull.SetWordWrap(f.label, false)
	f.name = S.Text(f, "GameFontNormalMed3", "LEFT")
	f.name:SetPoint("TOPLEFT", 84, -41)
	f.name:SetWidth(f.textW)
	CuratorOctoFull.SetWordWrap(f.name, false)
	f.line = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.line:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -3)
	f.line:SetWidth(f.textW)
	CuratorOctoFull.SetWordWrap(f.line, true)
	CuratorOctoFull.SetMaxLines(f.line, 2)
	-- the flash of the card turned over
	f.flash = f:CreateTexture(nil, "OVERLAY")
	if not S.Atlas(f.flash, "loottoast-glow") then
		CuratorOctoFull.ColorTexture(f.flash, 1, 0.9, 0.6, 0.25)
	end
	CuratorOctoFull.SetSize(f.flash, 286, 109)
	f.flash:SetPoint("CENTER")
	f.flash:SetBlendMode("ADD")
	f.flash:SetAlpha(0)

	f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	CuratorOctoFull.SetScript(f, "OnClick", function(_, button)
		local who, s, case = V.sender, V.series, V.case
		V:Stop()
		if button == "LeftButton" and who then
			if case then
				-- (1.14.2: a case, their collection)
				ns.Album:ShowPlayer(who)
			elseif s then
				ns.Album:ShowMember(who, s)
			end
		end
	end)
	CuratorOctoFull.SetScript(f, "OnEnter", function()
		V.paused = true
	end)
	CuratorOctoFull.SetScript(f, "OnLeave", function()
		V.paused = false
	end)
	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		V:Step(elapsed)
	end)
end

-- (1.14.2) The case and the card that comes out of it, on the panel: made the first time a case comes (false: not here).
function V:BuildCase()
	local f = self.frame
	if f.box then
		return true
	end
	if not (ns.CrateBox and ns.CaseCards) then
		return false
	end
	local box = ns.CrateBox.New(f, CASE_W)
	box:SetPoint("CENTER", f, "TOPLEFT", 48, -50)
	box:SetFrameLevel(f:GetFrameLevel() + 2)
	box:Hide()
	f.box = box
	local cc = ns.CaseCards.New(f, CASE_CARD)
	cc:SetPoint("CENTER", f, "TOPLEFT", 48, -49)
	cc:SetFrameLevel(f:GetFrameLevel() + 3)
	-- (so small, its name on its plate could not be read: written beside it)
	cc.name:Hide()
	cc:Hide()
	f.caseCard = cc
	return true
end

-- (1.14.3) Whether something of the guild may show on the screen (rarity: the one of its card, nil: none, an achievement,
-- a golden quest): the switch of the options on (db.live), and its epic cards and better only when asked (db.liveEpic).
V.EPIC = 4
function V:Allows(rarity)
	local db = ns.db
	if not db or db.live == false then
		return false
	end
	if rarity and db.liveEpic and rarity < self.EPIC then
		return false
	end
	return true
end

-- Is the panel free to show a booster: on, out of combat, no booster or entrance of mine on screen.
function V:Free()
	if not self:Allows() or self.state then
		return false
	end
	if InCombatLockdown and InCombatLockdown() then
		return false
	end
	local scene = _G.CuratorBoosterScene
	if (scene and scene:IsShown()) or (ns.Cinematic and ns.Cinematic:IsPlaying()) then
		return false
	end
	return true
end

-- Whether a pull is the card a booster waits for: the one it shows (1.14.2); from a version of before, the card of its
-- best rarity (legendary or mythic), else its holographic one.
local function Waits(e, card, finish)
	if e.star then
		return card == e.star
	end
	if e.best >= 5 then
		return card.rarity >= e.best
	end
	return finish == "holo"
end

-- (1.14.2) Whether the guild hears of a card turned over (UI/Booster.lua, UI/OpenAll.lua: an epic card or better, or a
-- forged one): else its panel shows it once its light climbed.
local function PullComes(card, finish)
	return card.rarity >= 4 or finish ~= nil
end

-- (1.14.2) An opening comes (e: what the panel shows): on the panel at once when it is free; while it shows another, it
-- waits its turn (one of each member, the finer one; QUEUE at most); else (off, a fight, a booster of mine on the screen)
-- nothing, as before.
function V:Push(e)
	if not self:Allows() then
		return false
	end
	e.at = GetTime()
	if not self.state then
		if not self:Free() then
			return false
		end
		return self:Play(e)
	end
	for i, q in ipairs(self.queue) do
		if q.sender == e.sender then
			if not q.turned and e.score > q.score then
				self.queue[i] = e
				return true
			end
			return false
		end
	end
	if CuratorOctoFull.Length(self.queue) >= QUEUE then
		return false
	end
	self.queue[CuratorOctoFull.Length(self.queue) + 1] = e
	return true
end

-- A guild member opens a booster with a fine card inside (O): best, its rarity; finish, its finest
-- finish. (1.14.2) star: the card it shows, its finish.
function V:Start(sender, s, best, finish, star, starFinish)
	local top = star and star.rarity or best
	-- (1.14.3: its epic cards and better only, when asked)
	if not self:Allows(tonumber(top) or 0) then
		return false
	end
	local G = ns.Guild
	return self:Push({ sender = sender, s = s, best = best, finish = finish, star = star, starFinish = starFinish,
		score = G.OpenScore(top, (star and starFinish) or finish) })
end

-- (1.14.2) A guild member opens a case (v: what came, Comm.lua: its edition, its rank, its card, its finish).
function V:StartCase(sender, case, v)
	-- (1.14.3: epic and better only, when asked: from the Restricted rank, the second, as the purple of the epic cards)
	if not self:Allows((tonumber(v.r) or 1) + 2) then
		return false
	end
	local fin = (v.f == "titan" and "holo") or (v.f == "thunder" and "shiny") or nil
	return self:Push({ sender = sender, case = case, rec = v, score = ns.Guild.OpenScore((tonumber(v.r) or 1) + 1, fin) })
end

-- (1.14.2) An opening on the panel: its pack (or its case) shakes, its light climbs.
function V:Play(e)
	self:Build()
	local f = self.frame
	if e.case and not self:BuildCase() then
		return false
	end
	ns.CancelOwner(self)
	self.cur = e
	self.sender, self.series, self.best, self.finish, self.case = e.sender, e.s, e.best, e.finish, e.case
	self.state, self.clock, self.paused, self.t = "wait", 0, false, 0
	f.pack.wash:SetAlpha(0)
	f.flash:SetAlpha(0)
	f.halo:SetAlpha(0)
	f.rays:SetAlpha(0)
	f.card:Hide()
	f.halo:Show()
	f.rays:Show()
	if f.box then
		f.box:SetIdle(false)
		f.box:Hide()
	end
	if f.caseCard then
		f.caseCard:Hide()
	end
	local busy = CuratorOctoFull.Length(self.queue) > 0
	local who = ns.Guild:Short(e.sender)
	if e.case then
		-- (the case in the art of its edition, its lid shut; its light from the Rare rank to the rank of its card)
		local def = ns.Crates and ns.Crates[e.case]
		local box = f.box
		f.pack:Hide()
		box:SetArt(def and def.art and def.art.box or nil)
		box:SetLid(0)
		box:SetAlpha(1)
		box:ClearAllPoints()
		box:SetPoint("CENTER", f, "TOPLEFT", 48, -50)
		box:Show()
		box:SetIdle(true)
		self.top, self.first = math.max(1, math.min(5, tonumber(e.rec.r) or 1)), 1
		self.step, self.color = 1, RankOf(1).color
		self.run = busy and CASE_BUSY or CASE_RUN
		self.revealAt = self.run
		Fit(f.label, string.format(L["%s is opening a case..."], who), f.textW + 8, 12, 8)
		Fit(f.name, L[(def and def.title) or "Case"], f.textW, 14, 10)
	else
		-- (from rare; a booster without a rare card, 1.2: the colour of its best card; 1.14.2: the card it shows, its colour)
		local top = math.max(1, math.min(CuratorOctoFull.Length(ns.RARITY), (e.star and e.star.rarity) or tonumber(e.best) or 3))
		local first = math.min(3, top)
		self.top, self.first = top, first
		self.step, self.color = first, ns.RARITY[first].glow
		local climbed = (top - first) * STEP
		if e.turned then
			-- (its card came while it waited its turn)
			self.revealAt = climbed + 0.8
		elseif e.star and not PullComes(e.star, e.starFinish) then
			self.revealAt = climbed + SOON
		else
			self.revealAt = nil
		end
		self.climbed = climbed
		local pack = e.s.pack or "PackElwynn"
		f.pack.bottom:SetTexture(MEDIA .. pack .. "Bottom")
		f.pack.top:SetTexture(MEDIA .. pack .. "Top")
		f.pack:Show()
		Fit(f.label, string.format(L["%s is opening a booster..."], who), f.textW + 8, 12, 8)
		Fit(f.name, C:SeriesName(e.s), f.textW, 14, 10)
	end
	f.name:SetTextColor(1, 1, 1)
	Fit(f.line, L["Live"], f.textW, 10, 8.5)
	f.line:SetTextColor(1, 0.35, 0.3)
	f:SetAlpha(0)
	f:Show()
	ns.Tween(0.25, function(k)
		f:SetAlpha(k)
	end, nil, Ease.outQuad, self)
	-- (a case: its latches, as at its opener's)
	Sound(e.case and ns.SND.chainSnap or ns.SND.packShake)
	return true
end

-- The card it was waiting for (P): the pack bursts, the card comes.
function V:Reveal(card, finish)
	local f = self.frame
	local r = card.rarity
	self.state, self.clock = "shown", 0
	if self.cur then
		self.cur.shown = card
	end
	self.color = ns.RARITY[r].glow
	f.pack:Hide()
	f.card:Show()
	-- (1.14.2: a card shown from what its opening told, a forged finish of the albums only)
	f.card:SetCard(card, { owned = true, finish = (finish == "holo" or finish == "shiny") and finish or nil })
	f.card:ShowSide("front")
	f.halo:SetVertexColor(self.color[1], self.color[2], self.color[3])
	f.halo:SetAlpha(0.9)
	f.rays:SetVertexColor(self.color[1], self.color[2], self.color[3])
	Fit(f.label, string.format(L["%s got"], ns.Guild:Short(self.sender)), f.textW + 8, 12, 8)
	Fit(f.name, C:Name(card), f.textW, 14, 10)
	local c = ns.RARITY[r].text
	f.name:SetTextColor(c[1], c[2], c[3])
	Fit(f.line, ns.Toast.Line(card, finish), f.textW, 10, 8.5)
	f.line:SetTextColor(0.8, 0.8, 0.8)
	f.flash:SetAlpha(1)
	ns.Tween(0.7, function(_, raw)
		f.flash:SetAlpha(1 - raw)
		f.halo:SetAlpha(0.9 - 0.5 * raw)
		f.rays:SetAlpha(0.8 - 0.5 * raw)
	end, nil, Ease.linear, self)
	lastSound = GetTime()
	ns.Play(ns.SND.reveal[r] or ns.SND.cardFlip)
	if ns.SND.impact[r] then
		ns.Play(ns.SND.impact[r])
	end
	ns.Delay(0.3, function()
		f.card:Animate(V)
	end, self)
end

-- (1.14.2) What came out of the case: its lid springs open, its light pours out, the case goes and its card comes in its
-- place; the sound of its rank, as the window of the cases plays it (the first ones).
local CASE_SOUNDS = { { "reveal", 3 }, { "reveal", 4 }, { "reveal", 5 }, { "reveal", 6, "impact", 5 }, { "gong", nil, "impact", 6 } }
function V:RevealCase()
	local f = self.frame
	local e = self.cur
	local v = e.rec
	local CR, CM = ns.CrateUI, ns.CaseCards
	local tier = math.max(1, math.min(5, tonumber(v.r) or 1))
	local rank = RankOf(tier)
	self.state, self.clock = "shown", 0
	self.color = rank.color
	local box, cc = f.box, f.caseCard
	box:Kick(1)
	ns.Tween(0.3, function(k)
		box:SetLid(k)
	end, nil, Ease.outBack, self)
	ns.Tween(0.3, function(k)
		box:SetAlpha(1 - k)
	end, function()
		box:SetIdle(false)
		box:Hide()
	end, Ease.inQuad, self, 0.35)
	-- (what came: as the small cards of the cases show it; its wear never told by a message)
	local x = CM.Look(v) or { tier = tier }
	x.wear, x.grade, x.count = nil, nil, nil
	cc:Set(x)
	cc:SetAlpha(0)
	cc:Show()
	ns.Tween(0.35, function(k)
		cc:SetAlpha(k)
		cc:ClearAllPoints()
		cc:SetPoint("CENTER", f, "TOPLEFT", 48, -55 + 6 * k)
	end, nil, Ease.outBack, self, 0.4)
	local col = rank.color
	f.halo:SetVertexColor(col[1], col[2], col[3])
	f.rays:SetVertexColor(col[1], col[2], col[3])
	f.halo:SetAlpha(0.9)
	local def = ns.Crates and ns.Crates[e.case]
	Fit(f.label, string.format(L["%s got"], ns.Guild:Short(self.sender)), f.textW + 8, 12, 8)
	Fit(f.name, CM.Name(v), f.textW, 14, 10)
	local ink = rank.text or col
	f.name:SetTextColor(ink[1], ink[2], ink[3])
	local fin = v.f and CR and CR.FINISH_NAME and CR.FINISH_NAME[v.f]
	local line = L[rank.label] .. (fin and (" · " .. L[fin]) or "") .. "  ·  " .. L[(def and (def.short or def.title)) or "Case"]
	Fit(f.line, line, f.textW, 10, 8.5)
	f.line:SetTextColor(0.8, 0.8, 0.8)
	f.flash:SetAlpha(1)
	ns.Tween(0.7, function(_, raw)
		f.flash:SetAlpha(1 - raw)
		f.halo:SetAlpha(0.9 - 0.5 * raw)
		f.rays:SetAlpha(0.8 - 0.5 * raw)
	end, nil, Ease.linear, self, 0.35)
	lastSound = GetTime()
	local snd = CASE_SOUNDS[tier]
	local S_ = ns.SND
	ns.Play(snd[2] and S_[snd[1]][snd[2]] or S_[snd[1]])
	if snd[3] then
		ns.Play(S_[snd[3]][snd[4]])
	end
end

-- A pull of the guild (P): taken by the panel when it is the card it waits for, from that member, of
-- that booster's album: the card of its best rarity (legendary or mythic), else its holographic one.
-- (A panel under a booster or an entrance of mine on the screen lets the alert show it instead.)
-- (1.14.2: the card it shows; the card of an opening waiting its turn, shown when it comes: no alert of its own.)
function V:Claim(sender, card, finish)
	if self.passing then
		return false
	end
	local e = self.cur
	if e and not e.case and e.sender == sender and card.series == e.s then
		if self.state == "wait" and Waits(e, card, finish) then
			local scene = _G.CuratorBoosterScene
			if (scene and scene:IsShown()) or (ns.Cinematic and ns.Cinematic:IsPlaying()) then
				self:Stop()
				return false
			end
			self:Reveal(card, finish)
			return true
		end
		-- (1.14.2: the card it shows already, its pull come after it: no alert of its own)
		if self.state ~= "wait" and e.shown == card and not e.claimed then
			e.claimed = true
			return true
		end
	end
	for _, q in ipairs(self.queue) do
		if not q.case and not q.turned and q.sender == sender and card.series == q.s and Waits(q, card, finish) then
			q.turned, q.card, q.cardFinish = true, card, finish
			return true
		end
	end
	return false
end

-- (1.14.2) An opening that waited its turn and cannot show (off, a fight, a booster of mine on the screen): the card turned
-- over meanwhile comes as an alert (UI/Toast.lua), as it would have without the panel.
function V:Pass(e)
	if e.turned and e.card then
		self.passing = true
		ns.Fire("GUILD_PULL", e.sender, e.card, e.cardFinish)
		self.passing = nil
	end
end

-- (1.14.2) The next opening waiting its turn (those waiting too long go, but one whose card came).
function V:Next()
	if self.state then
		return
	end
	local now = GetTime()
	while self.queue[1] do
		local e = CuratorOctoFull.Remove(self.queue, 1)
		if e.turned or now - e.at <= STALE then
			if self:Free() then
				return self:Play(e)
			end
			self:Pass(e)
		end
	end
end

function V:Stop()
	ns.CancelOwner(self)
	self.state, self.sender, self.series, self.case, self.cur = nil, nil, nil, nil, nil
	if self.frame then
		self.frame:Hide()
		if self.frame.box then
			self.frame.box:SetIdle(false)
		end
	end
	-- (1.14.2: the next one, after a breath)
	if self.queue[1] then
		ns.CancelOwner(NEXT)
		ns.Delay(GAP, function()
			V:Next()
		end, NEXT)
	end
end

-- The light that climbs (each colour a step), the pack that shakes, the waiting, the hold and the
-- fade.
function V:Step(elapsed)
	local f = self.frame
	if not self.state then
		return
	end
	self.t = (self.t or 0) + elapsed
	self.clock = self.clock + elapsed
	local t = self.t
	local busy = self.queue[1] ~= nil
	if f.card:IsShown() then
		f.card:Tick(t)
	end
	CuratorOctoFull.SetRotation(f.rays, t * 0.5)
	local e = self.cur
	if self.state == "wait" and e and e.case then
		-- (1.14.2) the case: its light climbs a rank at a time toward the end of its run, a jolt at each; its card then
		local k = self.run / CASE_RUN
		local step = 1
		for r = 2, self.top do
			if self.clock >= (CASE_RUN - CASE_LAST - CASE_STEP * (self.top - r)) * k then
				step = r
			end
		end
		if step > self.step then
			self.step = step
			self.color = RankOf(step).color
			f.box:Kick(0.3 + 0.12 * step)
			if step == self.top then
				Sound(ns.SND.tell[math.min(6, step + 1)] or ns.SND.packShake)
			end
		end
		local col = self.color
		if e.rec.f == "titan" and self.step == self.top then
			-- (a titanforged card inside: its light beats in the gold and the pale blue of the titans)
			local b = 0.5 + 0.5 * math.sin(t * 2.4)
			col = { 1 - 0.45 * b, 0.78 + 0.07 * b, 0.32 + 0.68 * b }
		elseif e.rec.f == "thunder" and self.step == self.top and math.sin(t * 7.3) > 0.82 then
			-- (thunderforged: a flash of its lightning now and then)
			col = { 0.75, 0.9, 1 }
		end
		f.halo:SetVertexColor(col[1], col[2], col[3])
		f.rays:SetVertexColor(col[1], col[2], col[3])
		f.halo:SetAlpha(math.min(1, 0.55 + 0.09 * self.step + 0.2 * math.sin(t * 5)))
		f.rays:SetAlpha(0.2 + 0.08 * self.step)
		if self.clock >= self.revealAt then
			self:RevealCase()
		end
	elseif self.state == "wait" then
		-- a colour higher every STEP seconds, up to the best rarity inside (1.14.2: the card it shows)
		local top = self.top or self.best
		local step = math.min(top, self.first + math.floor(self.clock / STEP))
		if step > self.step then
			self.step = step
			self.color = ns.RARITY[step].glow
			f.pack.wash:SetAlpha(0.8)
			if step == top then
				Sound(ns.SND.tell[step] or ns.SND.packShake)
			end
		end
		local col = self.color
		local fin = (e and e.star) and e.starFinish or self.finish
		if fin == "holo" and self.step == top then
			-- (a titanforged card inside: its light beats in the gold and the pale blue of the titans)
			local k = 0.5 + 0.5 * math.sin(t * 2.4)
			col = { 1 - 0.45 * k, 0.78 + 0.07 * k, 0.32 + 0.68 * k }
		elseif fin == "shiny" and self.step == top and math.sin(t * 7.3) > 0.82 then
			-- (1.14.2: thunderforged, a flash of its lightning now and then)
			col = { 0.75, 0.9, 1 }
		end
		f.halo:SetVertexColor(col[1], col[2], col[3])
		f.rays:SetVertexColor(col[1], col[2], col[3])
		f.pack.wash:SetVertexColor(col[1], col[2], col[3])
		f.pack.wash:SetAlpha(math.max(0, f.pack.wash:GetAlpha() - elapsed * 1.6))
		local k = 0.6 + 0.1 * (self.step - 3) + 0.2 * math.sin(t * 5)
		f.halo:SetAlpha(math.min(1, k))
		f.rays:SetAlpha(0.25 + 0.12 * (self.step - 3))
		-- it shakes more as its light climbs, in bursts
		local amp = (0.8 + 0.6 * (self.step - 3)) * (0.6 + 0.4 * math.max(0, math.sin(t * 2.3)))
		f.pack:ClearAllPoints()
		f.pack:SetPoint("CENTER", f, "TOPLEFT", 48 + (math.random() * 2 - 1) * amp, -49 + (math.random() * 2 - 1) * amp)
		if e and e.turned and self.revealAt and self.clock >= self.revealAt then
			return self:Reveal(e.card, e.cardFinish)
		end
		if e and e.star and self.revealAt and self.clock >= self.revealAt then
			return self:Reveal(e.star, e.starFinish)
		end
		-- (1.14.2: another waits its turn: its card from what its opening told, sooner; else it goes)
		local limit = WAIT
		if busy then
			limit = math.min(WAIT, (self.climbed or 0) + BUSY)
		end
		if self.clock >= limit then
			if e and e.star then
				return self:Reveal(e.star, e.starFinish)
			end
			-- (the card was never shown: the panel goes quietly)
			self.state, self.clock = "out", 0
		end
	elseif self.state == "shown" then
		if self.paused then
			self.clock = 0
		elseif self.clock >= (busy and HOLD_BUSY or HOLD) then
			self.state, self.clock = "out", 0
		end
	elseif self.state == "out" then
		if self.paused and (f.card:IsShown() or (f.caseCard and f.caseCard:IsShown())) then
			-- (the mouse over the card shown keeps it there)
			self.state, self.clock = "shown", 0
			f:SetAlpha(1)
			return
		end
		f:SetAlpha(1 - math.min(1, self.clock / FADE))
		if self.clock >= FADE then
			self:Stop()
		end
	end
end

-------------------------------------------------------------------------------
-- (1.14.3) Where the alerts show: moved by the player
-------------------------------------------------------------------------------
-- The alerts of Curator (UI/Toast.lua) and, this far under them, this panel: their top, from the top of the screen
-- (db.alertsAt = { x, y }: x from its middle), as they were first unless moved.
V.ALERTS_X, V.ALERTS_Y = 0, -110
V.PANEL_GAP = 105
local TOAST_W, TOAST_H = 300, 101

function V:AlertsAt()
	local at = ns.db and ns.db.alertsAt
	local x = type(at) == "table" and tonumber(at.x) or nil
	local y = type(at) == "table" and tonumber(at.y) or nil
	if not (x and y) then
		return self.ALERTS_X, self.ALERTS_Y
	end
	return x, y
end

-- The alerts and this panel where they go now.
function V:Place()
	local x, y = self:AlertsAt()
	local T = ns.Toast
	if T and T.frame then
		T.frame:ClearAllPoints()
		T.frame:SetPoint("TOP", UIParent, "TOP", x, y)
	end
	if self.frame then
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOP", UIParent, "TOP", x, y - self.PANEL_GAP)
	end
	if self.mover then
		self.mover:ClearAllPoints()
		self.mover:SetPoint("TOP", UIParent, "TOP", x, y)
	end
end

-- Their first places back.
function V:ResetPlace()
	if ns.db then
		ns.db.alertsAt = nil
	end
	self:Place()
end

-- Where the frame that moves them was left: kept, the alerts and this panel there.
function V:SaveMover()
	local m = self.mover
	if not (m and ns.db and UIParent) then
		return
	end
	local l, t, w = m:GetLeft(), m:GetTop(), m:GetWidth()
	if not (l and t and w) then
		return
	end
	local k = m:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local x = math.floor((l + w / 2) * k - UIParent:GetWidth() / 2 + 0.5)
	local y = math.floor(t * k - UIParent:GetHeight() + 0.5)
	ns.db.alertsAt = { x = x, y = y }
	self:Place()
end

local function Box(m, w, h, y, text)
	local b = CreateFrame("Frame", nil, m, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(b, w, h)
	b:SetPoint("TOP", m, "TOP", 0, y)
	if b.SetBackdrop then
		b:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 14,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		b:SetBackdropBorderColor(1, 0.82, 0.2, 0.9)
	end
	b.text = b:CreateFontString(nil, "OVERLAY")
	ns.SetFont(b.text, 13, "OUTLINE")
	b.text:SetPoint("CENTER")
	b.text:SetTextColor(1, 0.86, 0.4)
	b.text:SetText(text)
	return b
end

-- The frame that moves them (the options, /curator alerts): the place of the alerts and of this panel under them,
-- dragged where the player likes; Done, Reset (their first places). Its own place kept as it is left.
function V:Mover()
	local m = self.mover
	if not m then
		m = CreateFrame("Frame", "CuratorAlertsMover", UIParent)
		CuratorOctoFull.SetSize(m, TOAST_W, self.PANEL_GAP + H)
		m:SetFrameStrata("FULLSCREEN_DIALOG")
		m:SetFrameLevel(250)
		m:SetClampedToScreen(true)
		m:SetMovable(true)
		m:EnableMouse(true)
		m:RegisterForDrag("LeftButton")
		CuratorOctoFull.SetScript(m, "OnDragStart", function(self)
			self:StartMoving()
		end)
		CuratorOctoFull.SetScript(m, "OnDragStop", function(self)
			self:StopMovingOrSizing()
			if self.SetUserPlaced then
				self:SetUserPlaced(false)
			end
			V:SaveMover()
		end)
		CuratorOctoFull.SetScript(m, "OnMouseUp", function(self, button)
			if button == "RightButton" then
				self:Hide()
			end
		end)
		m.toast = Box(m, TOAST_W, TOAST_H, 0, L["The alerts of Curator"])
		m.live = Box(m, W, H, -self.PANEL_GAP, L["Your guild, live"])
		for _, b in ipairs({ m.toast, m.live }) do
			b:EnableMouse(false)
		end
		m.hint = m:CreateFontString(nil, "OVERLAY")
		ns.SetFont(m.hint, 12, "OUTLINE")
		m.hint:SetPoint("TOP", m, "BOTTOM", 0, -6)
		m.hint:SetTextColor(1, 1, 1)
		m.hint:SetText(L["Drag to move them, then Done."])
		m.done = S.Button(m, L["Done"], 110, 24)
		m.done:SetPoint("TOPRIGHT", m.hint, "BOTTOM", -4, -6)
		CuratorOctoFull.SetScript(m.done, "OnClick", function()
			ns.Play(ns.SND.click)
			m:Hide()
		end)
		m.reset = S.Button(m, L["Reset"], 110, 24)
		m.reset:SetPoint("TOPLEFT", m.hint, "BOTTOM", 4, -6)
		CuratorOctoFull.SetScript(m.reset, "OnClick", function()
			ns.Play(ns.SND.click)
			V:ResetPlace()
		end)
		self.mover = m
	end
	self:Place()
	m:Show()
	m:Raise()
end

ns.On("GUILD_OPEN", function(sender, s, best, finish, star, starFinish)
	V:Start(sender, s, best, finish, star, starFinish)
end)

-- (1.14.2) A case opened by a member of the guild (Comm.lua).
ns.On("GUILD_CASE", function(sender, case, v)
	V:StartCase(sender, case, v)
end)
