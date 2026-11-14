local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA

-------------------------------------------------------------------------------
-- (1.12.0) Hallow's End in the game (Hallow.lua): trick or treat at the innkeepers (a line in their window,
-- once a day), the bats of a trick across the screen, the alerts of its boosters, and the event told once at a
-- login while it lasts.
-------------------------------------------------------------------------------
local HU = {}
ns.HallowUI = HU

-- (the jack-o'-lantern of the game: its bag of treats)
local PUMPKIN = "Interface\\Icons\\INV_Misc_Bag_28_Halloween"
local BATS, BAT_TIME = 14, 2.6
local ORANGE = { 1, 0.62, 0.22 }

local function Series()
	return ns.Hallow and ns.Hallow:Series()
end

-------------------------------------------------------------------------------
-- The bats of a trick: out of the middle of the screen, every way, their wings beating
-------------------------------------------------------------------------------
function HU:Build()
	if self.frame then
		return self.frame
	end
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetAllPoints()
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:EnableMouse(false)
	f:Hide()
	f.bats = {}
	for i = 1, BATS do
		local t = f:CreateTexture(nil, "OVERLAY")
		t:SetTexture(MEDIA .. "Bat")
		t:SetTexCoord(0, 0.5, 0, 1)
		f.bats[i] = t
	end
	self.frame = f
	return f
end

function HU:Bats()
	local f = self:Build()
	local W, H = UIParent:GetWidth() or 1920, UIParent:GetHeight() or 1080
	for i, t in ipairs(f.bats) do
		local a = (i / BATS) * math.pi * 2 + math.random() * 0.5
		local size = 60 + math.random() * 80
		t.size = size
		t.path = { a = a, reach = (0.55 + math.random() * 0.35) * math.max(W, H), lift = (math.random() - 0.5) * 0.4, ph = math.random() * 3 }
		CuratorOctoFull.SetSize(t, size, size * 0.5)
		t:SetAlpha(0)
	end
	f:Show()
	ns.Play(ns.SND.hallowBats)
	local start = GetTime()
	CuratorOctoFull.SetScript(f, "OnUpdate", function(self)
		local e = (GetTime() - start) / BAT_TIME
		if e >= 1 then
			CuratorOctoFull.SetScript(self, "OnUpdate", nil)
			self:Hide()
			return
		end
		for i, t in ipairs(self.bats) do
			local p = t.path
			local u = math.min(1, e * (1.1 + 0.03 * i))
			local d = p.reach * (u ^ 0.8)
			local x = math.cos(p.a) * d
			local y = math.sin(p.a) * d * 0.7 + p.lift * d + math.sin(u * 9 + p.ph) * 12
			t:ClearAllPoints()
			t:SetPoint("CENTER", self, "CENTER", x, y)
			local k = 0.4 + 0.9 * u
			CuratorOctoFull.SetSize(t, t.size * k, t.size * 0.5 * k)
			local up = CuratorOctoFull.Mod(math.floor(GetTime() * 9 + i) , 2) == 0
			local l, r = up and 0 or 0.5, up and 0.5 or 1
			if math.cos(p.a) < 0 then
				l, r = r, l
			end
			t:SetTexCoord(l, r, 0, 1)
			t:SetAlpha(math.min(1, u * 6) * (1 - math.max(0, (e - 0.75) / 0.25)))
		end
	end)
end

-------------------------------------------------------------------------------
-- Trick or treat, at the innkeepers
-------------------------------------------------------------------------------
ns.Gossip:Provide("inn", function()
	local H = ns.Hallow
	if not (ns.db and H and H:On()) then
		return {}
	end
	if H:TreatedToday() then
		return { { text = string.format(L["Trick or treat! (again in %s)"], ns.Duration(H:NextIn())), icon = PUMPKIN, click = function()
			ns.Gossip:Say(L["Off with you! Come back tomorrow for another treat."])
		end } }
	end
	return { { text = L["Trick or treat!"], icon = PUMPKIN, click = function()
		local got = H:Treat()
		-- (1.12.0, later: H.TREAT_PACKS boosters for a treat)
		local n = H.TREAT_PACKS or 1
		if got == "trick" then
			HU:Bats()
			ns.Gossip:Say(string.format(L["Boo! A trick... and here is your treat all the same: %d boosters of Hallow's End."], n))
		elseif got == "treat" then
			ns.Play(ns.SND.hallowTreat)
			ns.Gossip:Say(string.format(L["A treat for you: %d boosters of Hallow's End. Happy Hallow's End!"], n))
		else
			ns.Gossip:Say(L["Off with you! Come back tomorrow for another treat."])
		end
	end } }
end)

-------------------------------------------------------------------------------
-- The alerts of its boosters
-------------------------------------------------------------------------------
ns.On("PACK_EARNED", function(s, n, reason, _, chest)
	if not (ns.Toast and s and s.event) or (reason ~= "treat" and reason ~= "hallow" and reason ~= "welcome") then
		return
	end
	local H = ns.Hallow
	local title, line
	if reason == "treat" then
		title = L["Treat!"]
		line = string.format(L["Boosters: %d"], ns.Packs(s))
	elseif reason == "welcome" then
		-- (1.12.0, later: the gift of welcome, once in the event)
		title = string.format(L["A gift for Hallow's End: %d boosters!"], n)
		line = L["The beta of WoW Forever ends on October 21: open them while it lasts."]
	else
		title = n > 1 and string.format(L["Bonus: %d boosters of Hallow's End!"], n) or L["Bonus: a booster of Hallow's End!"]
		line = string.format(L["One for every %d boosters earned while it lasts."], H and H.BONUS_EVERY or 3)
	end
	-- (1.14.0: the bonus of a reroll, in its chest: Reroll.lua)
	if chest then
		line = string.format(L["In this character's chest: it opens at level %d."], ns.Reroll and ns.Reroll.LEVEL or 15)
	end
	ns.Toast:Push({
		title = title,
		name = ns.Collection:SeriesName(s),
		color = ORANGE,
		line = line,
		pack = s.pack,
		sound = ns.SND.hallowTreat,
		onClick = function()
			if chest and ns.RerollUI then
				ns.RerollUI:ShowChest()
				return
			end
			ns.OpenBooster({ series = s })
		end,
	})
end)

-- The event told once at a login while it lasts (each time it comes back: its window).
function HU:Tell()
	local H = ns.Hallow
	local s = Series()
	if not (ns.db and H and s and H:On() and ns.Toast) then
		return false
	end
	local st = H:State()
	local w = H:Window()
	if not (st and w) or st.told == w[1] then
		return false
	end
	st.told = w[1]
	ns.Toast:Push({
		title = L["Hallow's End in Curator!"],
		name = string.format(L["A limited album: %s left"], ns.Duration(H:Left())),
		color = ORANGE,
		line = L["Trick or treat at an innkeeper, once a day."],
		tex = { PUMPKIN, { 0.07, 0.93, 0.07, 0.93 } },
		sound = ns.SND.hallowTreat,
		onClick = function()
			-- (1.14.0, after the test of the cases, his word: no tab of Hallow's End any more; its album)
			local hs = H and H:Series()
			if hs then
				ns.Album:ShowSeries(hs)
			end
		end,
	})
	return true
end

ns.On("LOGIN", function()
	ns.Delay(14, function()
		HU:Tell()
		-- (1.12.0, later: the gift of welcome, after the toast of the event)
		ns.Delay(4, function()
			if ns.Hallow then
				ns.Hallow:Welcome()
			end
		end, HU)
	end, HU)
end)
