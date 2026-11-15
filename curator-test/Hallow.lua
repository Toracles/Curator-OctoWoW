local _, ns = "Curator", CuratorOctoFull

-------------------------------------------------------------------------------
-- (1.12.0) Hallow's End: the album of the creatures of the night (Data/Hallow.lua), a limited edition. Its
-- boosters (five cards, the lair of a dungeon in the colours of a pumpkin: UI/Lair.lua) come only while the
-- event lasts (H.WINDOWS, the time of the server):
-- * trick or treat at an innkeeper, once a day (the day of the quests: 5:00 in Paris), a booster of the album;
-- * every H.BONUS_EVERY boosters earned anywhere else (the bars, the quests, the inns, the front), one of them;
-- * and the creature of one of its cards, defeated where it counts (giving experience; a dungeon not too low),
--   finds that card now and then, as the cards of the albums are found.
-- Once it is over, nothing gives them any more: the cards stay, the boosters waiting still open, the trades and
-- the contracts go on. No booster to choose, no card of the reseller, no contract made to measure goes to the album (it
-- would make its cards from others), and it counts in no total of the collection (an achievement of all the
-- cards would no longer be within reach once it is over): its own achievement only.
-- What is kept (db.hallow): day (the day of the last treat), earn (the boosters earned toward the next bonus),
-- treats, tricks, bonus (how many of each), told (the start of the event told), welcome (the window of the event
-- whose gift came).
-- (1.12.0, later) Generous: the beta of OctoWoW ends on October 21, in the middle of it. A gift of welcome
-- (H.WELCOME boosters, once), H.TREAT_PACKS boosters for a treat, the bonus every H.BONUS_EVERY boosters, the cards
-- found twice as often on their creatures, and quests aplenty (Quests.lua: each one claimed gives way to another).
-------------------------------------------------------------------------------
local H = {}
ns.Hallow = H

H.KEY = "hallow"
-- when it lasts: from, to (the time of the server). 2026: from October 16, 5:00 in Paris. (1.14.0, his word: "Hallow's
-- End is over, it comes back next year": it ends on October 29 at 5:00 in Paris, when the discovery of the Paladin
-- Collection Case No. 1 begins (Discovery.lua), instead of November 2: no treat at the innkeepers, no bonus, no gift, no
-- card on its creatures, no display of it any more. Next year: its window of 2027 here.)
H.WINDOWS = { { 1792101600, 1793246400 } }
H.BONUS_EVERY = 2 -- the boosters earned elsewhere for one of the album (3 before the beta's end was known)
H.TRICK = 0.25    -- a trick before the treat, now and then (bats: the treat comes all the same)
H.TREAT_PACKS = 3 -- the boosters of a treat (1 before)
H.WELCOME = 10    -- the gift of welcome, once in the event
H.EDITION = 2026  -- (the year on the plate of its cards, a limited edition: UI/Card.lua)
-- (1.12.0, later) the theme of its boosters, by the author: played in their lair in the place of the music of its master
-- (UI/Lair.lua), again each time it ends
H.MUSIC = ns.MEDIA .. "HallowTheme.ogg"
H.MUSIC_LENGTH = 93.8
-- the chance to find a card of the album on its creature, by its rarity in the album (as the albums: twice theirs)
H.FIND = { 0.024, 0.016, 0.01, 0.006, 0.003, 0.001 }

local function Now()
	return (GetServerTime and CuratorOctoFull.ServerTime()) or time()
end

-- The album (nil: this build has none).
function H:Series()
	if self.series == nil then
		self.series = (ns.SeriesByKey and ns.SeriesByKey(self.KEY)) or false
	end
	return self.series or nil
end

-- The window of the event now (from, to), nil when it does not last.
function H:Window(now)
	now = now or Now()
	for _, w in ipairs(self.WINDOWS) do
		if now >= w[1] and now < w[2] then
			return w
		end
	end
	return nil
end

-- It lasts (and Curator is open: a beta past its day, an update missed, a collection suspended or banned
-- give nothing).
function H:On(now)
	if not self:Series() or (ns.Beta and ns.Beta:Over()) then
		return false
	end
	return self:Window(now) ~= nil
end

-- The seconds it still lasts (0: not on).
function H:Left(now)
	now = now or Now()
	local w = self:Window(now)
	return w and math.max(0, w[2] - now) or 0
end

-- When it ends (the end of the window it is in, else of the last one).
function H:Ends(now)
	local w = self:Window(now) or self.WINDOWS[CuratorOctoFull.Length(self.WINDOWS)]
	return w and w[2] or 0
end

-- Over (a window gone, none to come).
function H:Over(now)
	now = now or Now()
	for _, w in ipairs(self.WINDOWS) do
		if now < w[2] then
			return false
		end
	end
	return true
end

function H:State()
	local db = ns.db
	if not db then
		return nil
	end
	if type(db.hallow) ~= "table" then
		db.hallow = {}
	end
	return db.hallow
end

-- The day of the treats (the day of the quests, as the stamps of the inns).
function H:Today()
	return ns.Inns and ns.Inns.Today and ns.Inns:Today() or math.floor(Now() / 86400)
end

function H:TreatedToday()
	local s = self:State()
	return s ~= nil and s.day == self:Today()
end

-- The seconds until the next treat.
function H:NextIn()
	return ns.Inns and ns.Inns.NextIn and ns.Inns:NextIn() or (86400 - CuratorOctoFull.Mod(Now() , 86400))
end

-- Trick or treat, at an innkeeper: its booster of the day. "treat" or "trick" (a trick first: the booster
-- all the same), else false and why: "off" (the event does not last), "today" (once a day).
function H:Treat()
	if not self:On() then
		return false, "off"
	end
	local st = self:State()
	if not st then
		return false, "off"
	end
	if st.day == self:Today() then
		return false, "today"
	end
	-- (1.14.0: the cards changed by another addon this session: the treat stays for later; Guard.lua)
	if ns.Guard and not ns.Guard:AllowAll() then
		return false, "guard"
	end
	st.day = self:Today()
	local trick = (ns.Rewards and ns.Rewards:Roll() or math.random()) < self.TRICK
	st.treats = (tonumber(st.treats) or 0) + 1
	if trick then
		st.tricks = (tonumber(st.tricks) or 0) + 1
	end
	ns.Rewards:Give(self:Series(), self.TREAT_PACKS, "treat")
	ns.Fire("HALLOW_TREAT", trick)
	return trick and "trick" or "treat"
end

-- The boosters earned elsewhere: every H.BONUS_EVERY of them, one of the album.
function H:Earned(s, n)
	if not self:On() or (s and s.event) or (n or 0) <= 0 then
		return
	end
	local st = self:State()
	if not st then
		return
	end
	st.earn = (tonumber(st.earn) or 0) + n
	local give = 0
	while st.earn >= self.BONUS_EVERY do
		st.earn = st.earn - self.BONUS_EVERY
		give = give + 1
	end
	if give > 0 then
		st.bonus = (tonumber(st.bonus) or 0) + give
		ns.Rewards:Give(self:Series(), give, "hallow")
	end
end

-- (1.12.0, later) The gift of welcome: H.WELCOME boosters, once in a window of the event (at a login). How many came
-- (0: none now).
function H:Welcome()
	if not self:On() then
		return 0
	end
	local st = self:State()
	local w = self:Window()
	if not (st and w) or st.welcome == w[1] then
		return 0
	end
	-- (1.14.0: the cards changed by another addon this session: the gift waits for the next login; Guard.lua)
	if ns.Guard and not ns.Guard:Allow(self:Series()) then
		return 0
	end
	st.welcome = w[1]
	ns.Rewards:Give(self:Series(), self.WELCOME, "welcome")
	ns.Fire("HALLOW_WELCOME", self.WELCOME)
	return self.WELCOME
end

-- The boosters earned until the next bonus one.
function H:ToBonus()
	local st = self:State()
	return self.BONUS_EVERY - ((st and tonumber(st.earn)) or 0)
end

-- A creature defeated where it counts (Rewards.lua): the card of the album it is on, now and then.
function H:OnKill(npc)
	local s = self:Series()
	if not npc or not s or not self:On() then
		return
	end
	local card = ns.Cards["c" .. (s.offset + npc)]
	if card and card.series == s then
		-- (a creature of the night: the quests of Hallow's End count it)
		ns.Fire("HALLOW_KILL", card)
		ns.Rewards:Find(card, self.FIND[card.rarity] or self.FIND[1])
	end
end

-- The album can get boosters to choose, the reseller's cards, a contract made to measure: never.
function H.Closed(s)
	return s ~= nil and s.event ~= nil
end

ns.On("PACK_EARNED", function(s, n, reason)
	if reason ~= "hallow" and reason ~= "treat" and reason ~= "welcome" then
		H:Earned(s, n)
	end
end)
