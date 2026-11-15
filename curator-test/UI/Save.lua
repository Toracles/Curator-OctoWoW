local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local A = ns.Album
local C = ns.Collection
local T = ns.Toast

-------------------------------------------------------------------------------
-- (1.12.1) The save at hand. The game writes the save of an addon to the disk only when the interface reloads or
-- the character logs out: a game that closes on its own (a crash, a computer turned off) loses all that came since.
-- The scroll in the title bar of the album (left of the gear) and /curator save reload the interface: the game writes
-- the save, and the Curator app sends it on to the website. Its tooltip tells what is not saved yet. A reminder comes
-- after a long while of play with something new since the last save, and after a great card (legendary, mythic,
-- titanforged, corrupted at 100 %); never in a fight, while away, while cards are turned over, nor in a battleground
-- or an arena. The reminders: off in the options. After the reload, a line and a toast say the save is made.
-------------------------------------------------------------------------------
local SV = {}
ns.Save = SV

SV.EVERY = 45 * 60 -- the reminder: the last save this old, something new since (and again as long after it)
SV.GAP = 15 * 60   -- the reminder of a great card: none within this long of another reminder
SV.CALM = 3        -- ... once its cards are turned over, and all has been quiet this many seconds
SV.WAIT = 600      -- ... given up past this long (a fight that never ends)
SV.HOLD = 9        -- a reminder stays this long on the screen (longer with the mouse over it)
SV.NOTE = 300      -- the save told after the reload asked for less than this long before
SV.TICK = 30
SV.ICON = { "Interface\\Icons\\INV_Scroll_03", { 0.08, 0.92, 0.08, 0.92 } }
local GOLD = { 1, 0.82, 0 }

-- (the states of the booster scene while its cards are drawn and turned over: no reload then)
local TURNING = { opening = true, omen = true, shaking = true, dealing = true, cards = true, redraw = true }

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

local function After(sec, fn)
	if CuratorOctoFull.Timer and CuratorOctoFull.Timer.After then
		CuratorOctoFull.Timer.After(sec, fn)
	else
		ns.Delay(sec, fn, SV)
	end
end

-- What came since the last save: the save loaded with this session is the one on the disk.
function SV:Reset()
	self.got = { cards = 0, new = 0, opened = 0, earned = 0, levels = 0, ach = 0, xp = 0, rubies = 0, pts = 0, quests = 0,
		trades = 0, great = {} }
	self.pending, self.watching, self.nagAt = nil, nil, nil
end
SV:Reset()

-- How long since the last save (the start of this session).
function SV:Age()
	return self.since and math.max(0, GetTime() - self.since) or 0
end

-- Something worth saving came since.
function SV:Worth()
	local g = self.got
	return g.cards + g.opened + g.earned + g.levels + g.ach + g.quests + g.trades > 0 or g.xp > 0 or g.rubies > 0
		or g.pts >= 1
end

-- The reminders are on (the options).
function SV:Reminds()
	return ns.db ~= nil and ns.db.saveRemind ~= false
end

-- The reminder is due: the last save is old, something came since (the scroll of the album glows).
function SV:Due()
	return self:Reminds() and self:Worth() and self.since ~= nil and self:Age() >= self.EVERY
end

-- The cards of a booster or of a contract drawn and turned over.
function SV:Turning()
	local B = ns.Booster
	return B ~= nil and B.Showing ~= nil and B:Showing() and TURNING[B.state or ""] == true
end

-- No reminder now (why): a fight, away, a booster being opened, a scene of Curator on the screen, a battleground.
function SV:Busy()
	if InCombatLockdown and InCombatLockdown() then
		return "fight"
	end
	if UnitIsAFK and UnitIsAFK("player") then
		return "away"
	end
	local B = ns.Booster
	if B and B.Showing and B:Showing() and B.state ~= "done" then
		return "booster"
	end
	if T and T.Waits and T:Waits() then
		return "scene"
	end
	if IsInInstance then
		local _, kind = IsInInstance()
		if kind == "pvp" or kind == "arena" then
			return "pvp"
		end
	end
	return nil
end

-------------------------------------------------------------------------------
-- What comes
-------------------------------------------------------------------------------
-- A great card: legendary or mythic, titanforged, or corrupted at 100 %.
local function Great(card, finish, corruption)
	return (card.rarity or 0) >= 5 or finish == "holo"
		or (finish == "corrupt" and (tonumber(corruption) or 0) >= (C.CORRUPT_FULL or 100))
end

-- (the rarest first, a forged or corrupted copy before a plain one)
local function Rank(card, finish)
	return (card.rarity or 0) * 10 + ((finish == "holo" or finish == "corrupt") and 2 or (finish == "shiny" and 1 or 0))
end

-- Every copy that comes, whatever brings it (a booster, a card found, a contract, a trade): counted, the great ones
-- kept to be told (the three finest, in the tooltip) and reminded.
function SV:Gained(card, finish, corruption, new)
	local g = self.got
	g.cards = g.cards + 1
	if new then
		g.new = g.new + 1
	end
	-- (as the album keeps it: no forged copy in an album of an event, no corrupted one elsewhere)
	local event = card.series ~= nil and card.series.event ~= nil
	if finish == true or (event and finish ~= "corrupt") or (not event and finish == "corrupt") then
		finish = nil
	end
	if not Great(card, finish, corruption) then
		return
	end
	local list = g.great
	list[CuratorOctoFull.Length(list) + 1] = { card = card, finish = finish, rank = Rank(card, finish) }
	table.sort(list, function(a, b)
		return a.rank > b.rank
	end)
	while CuratorOctoFull.Length(list) > 3 do
		CuratorOctoFull.Remove(list)
	end
	self:Watch(card, finish)
end

do
	local add = C.Add
	function C:Add(card, finish, corruption)
		local new, e = add(self, card, finish, corruption)
		if card then
			SV:Gained(card, finish, corruption, new)
		end
		return new, e
	end
end

ns.On("BOOSTER_OPENED", function()
	SV.got.opened = SV.got.opened + 1
end)
ns.On("PACK_EARNED", function(_, n)
	SV.got.earned = SV.got.earned + math.max(0, tonumber(n) or 1)
end)
ns.On("XP_GAINED", function(n, _, before, after)
	local g = SV.got
	g.xp = g.xp + math.max(0, tonumber(n) or 0)
	g.levels = g.levels + math.max(0, (tonumber(after) or 0) - (tonumber(before) or 0))
end)
ns.On("ACH_EARNED", function()
	SV.got.ach = SV.got.ach + 1
end)
ns.On("RUBIES_CHANGED", function(n)
	n = tonumber(n) or 0
	if n > 0 then
		SV.got.rubies = SV.got.rubies + n
	end
end)
ns.On("PROGRESS", function(_, points)
	SV.got.pts = SV.got.pts + math.max(0, tonumber(points) or 0)
end)
ns.On("QUEST_CLAIMED", function()
	SV.got.quests = SV.got.quests + 1
end)
ns.On("TRADE_DONE", function()
	SV.got.trades = SV.got.trades + 1
end)

-- The trades done that the other side sees not saved on mine yet (their cards wait for it).
function SV:TradesWaiting()
	local n = 0
	local db = ns.db
	for _, rec in pairs(db and type(db.trades) == "table" and db.trades or {}) do
		if type(rec) == "table" and rec.st == "done" and not rec.dur then
			n = n + 1
		end
	end
	return n
end

-------------------------------------------------------------------------------
-- What it says
-------------------------------------------------------------------------------
local function Counts(cards, opened, earned, levels, ach)
	local out = {}
	if (cards or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["Cards: %d"], cards)
	end
	if (opened or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["Boosters opened: %d"], opened)
	end
	if (earned or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["Boosters earned: %d"], earned)
	end
	if (levels or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["Collector levels: +%d"], levels)
	end
	if (ach or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["Achievements: +%d"], ach)
	end
	return out
end

-- (1.13.0, after its first test) The same, in a few words each: "14 cards", "2 boosters earned". The reminder and what a save
-- put in safety say them so: "Cards: 14 · Boosters earned: 2" on a reminder that saves with a click read as rewards to come.
local function One(n, one, many)
	return n == 1 and L[one] or string.format(L[many], n)
end
local function Compact(cards, opened, earned, levels, ach)
	local out = {}
	if (cards or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = One(cards, "1 card", "%d cards")
	end
	if (opened or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = One(opened, "1 booster opened", "%d boosters opened")
	end
	if (earned or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = One(earned, "1 booster earned", "%d boosters earned")
	end
	if (levels or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = One(levels, "1 collector level gained", "%d collector levels gained")
	end
	if (ach or 0) > 0 then
		out[CuratorOctoFull.Length(out) + 1] = One(ach, "1 achievement", "%d achievements")
	end
	return out
end

-- "+1,200 XP · +60 rubies · +250 pts" (nil: none).
local function Smalls(g)
	local out = {}
	if g.xp > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["+%s XP"], ns.Num(g.xp))
	end
	if g.rubies > 0 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["+%s rubies"], ns.Num(g.rubies))
	end
	if g.pts >= 1 then
		out[CuratorOctoFull.Length(out) + 1] = string.format(L["+%s pts"], ns.Num(math.floor(g.pts)))
	end
	return CuratorOctoFull.Length(out) > 0 and table.concat(out, "  ·  ") or nil
end

-- What came since the last save, a line each: { text, r, g, b }.
function SV:Lines()
	local g, out = self.got, {}
	for i, text in ipairs(Counts(g.cards, nil, nil, nil, nil)) do
		out[CuratorOctoFull.Length(out) + 1] = { text, 1, 1, 1 }
		if i == 1 and g.new > 0 then
			out[CuratorOctoFull.Length(out) + 1] = { string.format(L["New cards: %d"], g.new), 1, 1, 1 }
		end
	end
	for _, it in ipairs(g.great) do
		local c = ns.RARITY[it.card.rarity] and ns.RARITY[it.card.rarity].text or { 1, 1, 1 }
		local fin = C:FinishName(it.card, it.finish)
		out[CuratorOctoFull.Length(out) + 1] = { "   " .. C:Name(it.card) .. (fin and ("  ·  " .. fin) or ""), c[1], c[2], c[3] }
	end
	for _, text in ipairs(Counts(nil, g.opened, g.earned, g.levels, g.ach)) do
		out[CuratorOctoFull.Length(out) + 1] = { text, 1, 1, 1 }
	end
	local small = Smalls(g)
	if small then
		out[CuratorOctoFull.Length(out) + 1] = { small, 1, 0.86, 0.55 }
	end
	return out
end

-- The same, in a few words (the name of a reminder: its line says they are not in safety yet).
function SV:Short()
	local g = self.got
	local parts = Compact(g.cards, g.opened, g.earned, g.levels, g.ach)
	if CuratorOctoFull.Length(parts) == 0 then
		return Smalls(g) or ""
	end
	return table.concat(parts, "  ·  ", 1, math.min(2, CuratorOctoFull.Length(parts)))
end

-- What a save put in safety (its note, made before the reload): a part each, the cards first, the rubies last.
local function SafeParts(note)
	local parts = Compact(tonumber(note.c), tonumber(note.o), tonumber(note.e), tonumber(note.l), tonumber(note.a))
	local small = Smalls({ xp = tonumber(note.x) or 0, rubies = tonumber(note.r) or 0, pts = 0 })
	if small then
		parts[CuratorOctoFull.Length(parts) + 1] = small
	end
	return parts
end

-- The tooltip of the scroll.
function SV:Tooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
	GameTooltip:AddLine(L["Save your collection"], 1, 1, 1)
	GameTooltip:AddLine(L["The interface reloads, and the game writes your collection to its files (a few seconds)."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(L["The game writes it only then, or when you log out: if the game closes on its own, what came since is lost."], 0.85, 0.85, 0.85, true)
	GameTooltip:AddLine(" ")
	local lines = self:Lines()
	if CuratorOctoFull.Length(lines) > 0 then
		-- (1.13.0, after its first test: what came is already yours, the save only writes it; said so, the gold lines read as
		-- rewards that the save would give)
		GameTooltip:AddLine(string.format(L["Earned since your last save (%s of play), not written yet:"], ns.Duration(self:Age())), GOLD[1], GOLD[2], GOLD[3], true)
		for _, l in ipairs(lines) do
			GameTooltip:AddLine(l[1], l[2], l[3], l[4])
		end
		GameTooltip:AddLine(L["Saving gives nothing more: it puts all of it in safety."], 0.62, 0.62, 0.66, true)
	else
		GameTooltip:AddLine(L["Nothing new to save."], 0.62, 0.62, 0.66)
	end
	local waiting = self:TradesWaiting()
	if waiting > 0 then
		GameTooltip:AddLine(string.format(L["Trades that wait for your save: %d"], waiting), 1, 0.62, 0.25, true)
	end
	if ns.APP then
		GameTooltip:AddLine(L["The Curator app then sends it to your page of the website."], 0.55, 0.88, 0.55, true)
	end
	if InCombatLockdown and InCombatLockdown() then
		GameTooltip:AddLine(L["Not during a fight."], 1, 0.3, 0.3)
	end
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- The save
-------------------------------------------------------------------------------
-- The interface reloads: the game writes the save. Not in a fight (the interface of the game would wait for its
-- end), nor while cards are turned over. (1.13.0, after its third test) The game no longer lets an addon reload the
-- interface: its Reload, called by Curator, is blocked ("Interface action failed because of an AddOn") and the
-- interface stays as it was. A macro of the game still reloads it, as /reload typed in the chat: the scroll of the
-- album, a reminder, Save on my side in a trade and Reload now in the options reload through one (the key, below).

-- A save now, or why not (said when say): no collection, a fight, cards being turned over.
function SV:Can(say)
	if not ns.db then
		return false
	end
	if InCombatLockdown and InCombatLockdown() then
		if say then
			ns.Print(L["Not during a fight: saving reloads the interface. Save once the fight is over."])
		end
		return false
	end
	if self:Turning() then
		if say then
			ns.Print(L["Once the cards are turned over: saving reloads the interface."])
		end
		return false
	end
	return true
end

-- The save asked for: what it puts in safety, told after the reload (SV:Start).
function SV:Note()
	local g = self.got
	ns.db.saveNote = { t = Now(), c = g.cards, o = g.opened, e = g.earned, l = g.levels, a = g.ach, x = math.floor(g.xp), r = math.floor(g.rubies) }
end

-- The save asked for where no macro of the game reloads (/curator save, a click without the key): /reload to type,
-- what it puts in safety told after it. False: the interface does not reload of itself.
function SV:Now(why)
	if not self:Can(true) then
		return false
	end
	self:Note()
	ns.Print(L["Type /reload to save your collection: the game no longer lets an addon reload the interface."])
	return false
end

-------------------------------------------------------------------------------
-- The key: the reload by a macro of the game
-------------------------------------------------------------------------------
-- One button of the game's macros (/reload), laid over the button the mouse is on (the scroll, a reminder, Save on my
-- side, Reload now) while it stays there. Never in a fight: the game forbids moving it then, so it is put away as one
-- begins, and the button under it is the one clicked (it says why the save waits). What the button under it does on
-- the mouse goes on: its tooltip and its light, the pause of a reminder, its right click. (Its left click alone
-- reloads, a save asked for each time but for Reload now; a reload the game did not do after all: said.)
local key

local function Calm()
	return not (InCombatLockdown and InCombatLockdown())
end

-- (what the button under it does when the mouse comes onto it or leaves it)
local function Forward(target, script)
	local fn = target.GetScript and target:GetScript(script)
	if fn then
		local ok, err = pcall(fn, target)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

-- The button of the game's macros (nil: the game gives none).
function SV:Key()
	if key ~= nil then
		return key or nil
	end
	local ok, b = pcall(CreateFrame, "Button", "CuratorSaveKey", UIParent, "SecureActionButtonTemplate")
	if not (ok and b and b.SetAttribute) then
		key = false
		return nil
	end
	b:SetAttribute("macrotext", "/reload")
	b:RegisterForClicks("AnyUp", "AnyDown")
	b:Hide()
	CuratorOctoFull.SetScript(b, "PreClick", function(self, button, down)
		SV:KeyPre(self, button, down)
	end)
	CuratorOctoFull.SetScript(b, "PostClick", function(self, button, down)
		SV:KeyPost(self, button, down)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		local c = self.cover
		if c then
			if c.target.LockHighlight then
				c.target:LockHighlight()
			end
			Forward(c.target, "OnEnter")
		end
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		SV:Uncover(true)
	end)
	-- (the button under it gone, or no longer one that saves: put away)
	CuratorOctoFull.SetScript(b, "OnUpdate", function(self)
		local c = self.cover
		if c and (not c.target:IsVisible() or (c.opts.when and not c.opts.when(c.target))) then
			SV:Uncover(true)
		elseif not c and Calm() then
			self:Hide()
		end
	end)
	key = b
	return b
end

-- The key over target, the mouse on it (opts: why, when = still one that saves, save = false for a reload that saves
-- nothing, click = after a click). False: not now (a fight, nothing to lay it on).
function SV:Cover(target, opts)
	opts = opts or {}
	if not (Calm() and target and target.IsVisible and target:IsVisible()) or (opts.when and not opts.when(target)) then
		return false
	end
	local b = self:Key()
	if not b then
		return false
	end
	local ok = pcall(function()
		local k = CuratorOctoFull.GetEffectiveScale(target) / CuratorOctoFull.GetEffectiveScale(UIParent)
		local l, bottom, w, h = CuratorOctoFull.GetRect(target)
		b:ClearAllPoints()
		b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * k - 1, bottom * k - 1)
		CuratorOctoFull.SetSize(b, w * k + 2, h * k + 2)
		b:SetFrameStrata(target:GetFrameStrata())
		b:SetFrameLevel(math.min(9900, target:GetFrameLevel() + 8))
	end)
	if not ok then
		return false
	end
	local c = b.cover
	if c and c.target ~= target and c.target.UnlockHighlight then
		pcall(c.target.UnlockHighlight, c.target)
	end
	b.cover = { target = target, opts = opts }
	b:SetAttribute("type1", nil)
	b:Show()
	return true
end

-- The key put away (leave: the mouse left, the button under it told).
function SV:Uncover(leave)
	local b = key
	if not b then
		return
	end
	local c = b.cover
	b.cover = nil
	if c then
		if c.target.UnlockHighlight then
			pcall(c.target.UnlockHighlight, c.target)
		end
		if leave then
			Forward(c.target, "OnLeave")
		end
	end
	if Calm() then
		b:SetAttribute("type1", nil)
		b:Hide()
	end
end

-- Before the macro: the left click reloads when a save can be made now (else why not, said once a click, as it is
-- released), what it puts in safety noted.
function SV:KeyPre(b, button, down)
	if not Calm() then
		return
	end
	local c = b.cover
	local go = button == "LeftButton" and c ~= nil and not (c.opts.when and not c.opts.when(c.target))
	if go and c.opts.save ~= false then
		go = self:Can(not down)
	end
	b:SetAttribute("type1", go and "macro" or nil)
	if not go then
		return
	end
	if c.opts.save ~= false then
		self:Note()
	end
	self.reloading = c.opts.why or true
	if not self.awaiting then
		self.awaiting = true
		After(3, function()
			SV.awaiting = nil
			if SV.reloading then
				SV.reloading = nil
				ns.Print(L["The game did not reload the interface: type /reload to save your collection."])
			end
		end)
	end
end

-- After it (once a click, as it is released): what the button under it does then.
function SV:KeyPost(b, button, down)
	if down then
		return
	end
	local c = b.cover
	if c and c.opts.click then
		local ok, err = pcall(c.opts.click, c.target, button)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

-- What the reminders and the scroll lay the key with.
SV.TOAST = {
	why = "toast",
	when = function()
		return T.current ~= nil and T.current.save == true
	end,
	click = function()
		T:Next(true)
	end,
}
SV.SCROLL = {
	why = "button",
	click = function()
		GameTooltip:Hide()
		ns.Play(ns.SND.click)
	end,
}
SV.TRADE = {
	why = "trade",
	when = function(b)
		return b.action == "reload"
	end,
}
SV.LANGUAGE = { why = "language", save = false }

-- The save made (after the reload asked for): a line in the chat, what it put in safety, then a toast once the loading
-- screen is gone.
function SV:Saved(note)
	local app = ns.APP and true or false
	if app then
		ns.Print(L["Your collection is saved."] .. " " .. L["The Curator app sends it to your page of the website."])
	else
		ns.Print(L["Your collection is saved."])
	end
	local parts = SafeParts(note)
	if CuratorOctoFull.Length(parts) > 0 then
		ns.Print(string.format(L["In safety: %s"], table.concat(parts, "  ·  ")))
	end
	-- (the toast: three of them at most; nothing came, the app)
	local line = CuratorOctoFull.Length(parts) > 0 and table.concat(parts, "  ·  ", 1, math.min(3, CuratorOctoFull.Length(parts))) or (app and L["The Curator app sends it to your page of the website."]) or ""
	After(4, function()
		T:Push({
			title = L["Saved"],
			name = L["Your collection is safe"],
			color = GOLD,
			line = line,
			tex = SV.ICON,
			sound = ns.SND.page,
		})
	end)
end

-- A reminder: of a great card (card, finish), else of the time gone since the last save. A click saves.
function SV:Remind(card, finish)
	self.nagAt = GetTime()
	local item
	if card then
		local r = ns.RARITY[card.rarity]
		item = {
			title = L["Not saved yet!"],
			name = C:Name(card),
			color = r and r.text or GOLD,
			line = L["Click: save it now (the interface reloads)."],
			card = card,
			finish = finish,
		}
	else
		item = {
			title = string.format(L["Not saved for %s"], ns.Duration(self:Age())),
			name = self:Short(),
			color = GOLD,
			line = L["Not in safety yet. Click: save it (the interface reloads)."],
			tex = SV.ICON,
		}
	end
	item.hold = self.HOLD
	item.sound = ns.SND.page
	item.save = true
	item.onClick = function()
		SV:Now("toast")
	end
	T:Push(item)
	self:Paint()
	return item
end

-- Every so often: the glow of the scroll, and the reminder when it is due (as long after the one before).
function SV:Tick()
	self:Paint()
	if not self:Due() then
		return
	end
	if self.nagAt and GetTime() - self.nagAt < self.EVERY then
		return
	end
	if self:Busy() then
		return
	end
	self:Remind()
end

-- A great card came: its reminder once its cards are turned over and all is quiet, unless another reminder came
-- within SV.GAP. (The finest of those that came meanwhile.)
function SV:Watch(card, finish)
	local p = self.pending
	local rank = Rank(card, finish)
	if not p or rank > p.rank then
		self.pending = { card = card, finish = finish, rank = rank, at = GetTime() }
	end
	if self.watching then
		return
	end
	self.watching, self.calm = true, 0
	After(1, function()
		SV:Poll()
	end)
end

function SV:Poll()
	local p = self.pending
	if not p then
		self.watching = nil
		return
	end
	local now = GetTime()
	if now - p.at > self.WAIT then
		self.pending, self.watching = nil, nil
		return
	end
	if self:Busy() then
		self.calm = 0
	else
		self.calm = (self.calm or 0) + 1
		if self.calm >= self.CALM then
			self.pending, self.watching = nil, nil
			if self:Reminds() and not (self.nagAt and now - self.nagAt < self.GAP) then
				self:Remind(p.card, p.finish)
			end
			return
		end
	end
	After(1, function()
		SV:Poll()
	end)
end

-------------------------------------------------------------------------------
-- The scroll in the title bar of the album
-------------------------------------------------------------------------------
local function Pulse(b, elapsed)
	b.t = (b.t or 0) + elapsed
	b.glow:SetAlpha(0.45 + 0.5 * (0.5 + 0.5 * math.sin(b.t * 3)))
end

function SV:Build(f)
	if not f or f.save then
		return
	end
	local b = CreateFrame("Button", nil, f)
	CuratorOctoFull.SetSize(b, 18, 18)
	-- (over the title bar, as the gear and the purse: the pieces of the template of the window stand at 500 and more)
	b:SetFrameLevel(f.gear and f.gear:GetFrameLevel() or math.max(f:GetFrameLevel() + 520, f.CloseButton and (f.CloseButton:GetFrameLevel() + 2) or 0))
	if f.gear then
		b:SetPoint("RIGHT", f.gear, "LEFT", -8, 0)
	elseif f.wallet then
		b:SetPoint("RIGHT", f.wallet, "LEFT", -10, 0)
	elseif f.CloseButton then
		b:SetPoint("RIGHT", f.CloseButton, "LEFT", -6, 0)
	else
		b:SetPoint("TOPRIGHT", -60, -3)
	end
	-- (a light behind it while a reminder is due)
	b.glow = b:CreateTexture(nil, "BACKGROUND")
	b.glow:SetTexture(ns.MEDIA .. "Glow")
	b.glow:SetBlendMode("ADD")
	b.glow:SetVertexColor(1, 0.8, 0.35)
	CuratorOctoFull.SetSize(b.glow, 48, 48)
	b.glow:SetPoint("CENTER")
	b.glow:SetAlpha(0)
	b.glow:Hide()
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	ns.SetIcon(b.icon, SV.ICON)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.hl, 1, 1, 1, 0.2)
	CuratorOctoFull.SetScript(b, "OnClick", function()
		GameTooltip:Hide()
		if InCombatLockdown and InCombatLockdown() then
			ns.Play(ns.SND.close)
		else
			ns.Play(ns.SND.click)
		end
		SV:Now("button")
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		SV:Tooltip(self)
		SV:Cover(self, SV.SCROLL)
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	f.save = b
	self.button = b
	self:Paint()
end

-- The scroll as things are: hidden on another player's collection, dimmed in a fight, glowing while a reminder is due.
function SV:Paint()
	local b = self.button
	if not b then
		return
	end
	CuratorOctoFull.SetShown(b, ns.db ~= nil and not A.member)
	local fight = InCombatLockdown and InCombatLockdown() and true or false
	CuratorOctoFull.SetDesaturated(b.icon, fight)
	local k = fight and 0.6 or 1
	b.icon:SetVertexColor(k, k, k)
	local due = self:Due() and true or false
	if due ~= (b.due or false) then
		b.due = due
		CuratorOctoFull.SetShown(b.glow, due)
		b.glow:SetAlpha(due and 0.45 or 0)
		CuratorOctoFull.SetScript(b, "OnUpdate", due and Pulse or nil)
	end
end

do
	local build = A.Build
	function A:Build(...)
		local r = build(self, unpack(arg, 1, arg.n))
		if self.frame and not self.frame.save then
			SV:Build(self.frame)
		end
		return r
	end
	local paintTabs = A.PaintTabs
	function A:PaintTabs(...)
		local r = paintTabs(self, unpack(arg, 1, arg.n))
		SV:Paint()
		return r
	end
end

-------------------------------------------------------------------------------
-- The session
-------------------------------------------------------------------------------
-- The start of a session: the save loaded is the one on the disk. The save asked for before the reload, told.
function SV:Start()
	self.since = GetTime()
	local db = ns.db
	local note = db and db.saveNote
	if note ~= nil then
		db.saveNote = nil
		local t = type(note) == "table" and tonumber(note.t)
		if t and math.abs(Now() - t) <= self.NOTE then
			self:Saved(note)
		end
	end
	if not self.ticker and CuratorOctoFull.Timer and CuratorOctoFull.Timer.NewTicker then
		self.ticker = CuratorOctoFull.Timer.NewTicker(self.TICK, function()
			SV:Tick()
		end)
	end
end

ns.On("LOGIN", function()
	SV:Start()
end)

-- (the scroll dimmed in a fight, and back; the key put away as a fight begins: the game still lets it be moved then)
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
CuratorOctoFull.SetScript(ev, "OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" then
		SV:Uncover(true)
	end
	SV:Paint()
end)
