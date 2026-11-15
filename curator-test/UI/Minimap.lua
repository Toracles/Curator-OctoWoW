local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- The round button on the edge of the minimap: left click opens the album, right click a booster.
-- It can be dragged around the minimap; /curator minimap hides it.
local M = {}
ns.MinimapButton = M

-- The rewards waiting: of the quests and the levels, and of the achievements. (1.14.0, after its test, his word: on a
-- reroll, those of the levels only: it claims none of the others, Reroll.lua: RR:Blocks.)
local function Blocks(what)
	return ns.Reroll ~= nil and ns.Reroll:Blocks(what)
end
local function Waiting()
	local n = ns.ClaimCount()
	if Blocks("quests") then
		n = n - CuratorOctoFull.Length(ns.Quests:Claimable())
	end
	if ns.Achievements and ns.db and not Blocks("achievements") then
		n = n + ns.Achievements:ClaimCount()
	end
	-- (1.14.0: the rewards of the levels to choose; a reroll chooses none)
	if ns.Level and ns.Level.OfferCount and not Blocks("choice") then
		n = n + ns.Level:OfferCount()
	end
	return math.max(0, n)
end

-- Distance from the centre of the minimap, past its edge: on a square minimap the button follows
-- the square (its corners are a little farther).
local function Place(b, angle)
	local a = math.rad(angle)
	local w, h = Minimap:GetWidth() / 2 + 10, Minimap:GetHeight() / 2 + 10
	local x, y = math.cos(a), math.sin(a)
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	if shape == "SQUARE" then
		local k = 1 / math.max(math.abs(x), math.abs(y))
		x, y = math.max(-1.12, math.min(1.12, x * k)), math.max(-1.12, math.min(1.12, y * k))
	end
	b:ClearAllPoints()
	b:SetPoint("CENTER", Minimap, "CENTER", x * w, y * h)
end

function M:Build()
	if self.button or not Minimap then
		return self.button
	end
	local b = CreateFrame("Button", "CuratorMinimapButton", Minimap)
	CuratorOctoFull.SetSize(b, 31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	CuratorOctoFull.SetSize(b.bg, 20, 20)
	b.bg:SetPoint("TOPLEFT", 7, -5)
	-- the sigil of the card backs, in the middle of the addon's icon
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetTexture(ns.MEDIA .. "Icon")
	b.icon:SetTexCoord(0.13, 0.87, 0.13, 0.87)
	CuratorOctoFull.SetSize(b.icon, 19, 19)
	b.icon:SetPoint("TOPLEFT", 6, -5)
	b.border = b:CreateTexture(nil, "OVERLAY")
	b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	CuratorOctoFull.SetSize(b.border, 53, 53)
	b.border:SetPoint("TOPLEFT")
	-- boosters waiting
	b.count = b:CreateFontString(nil, "OVERLAY")
	ns.SetFont(b.count, 10, "OUTLINE")
	b.count:SetPoint("BOTTOMRIGHT", 1, 0)
	b.count:SetTextColor(1, 0.86, 0.5)
	-- rewards to claim (quests done, levels reached)
	b.badge = ns.Hud.Badge(b, 16)
	b.badge:SetPoint("CENTER", b, "TOPRIGHT", -5, -5)
	b.badge:SetFrameLevel(b:GetFrameLevel() + 4)
	CuratorOctoFull.SetScript(b, "OnClick", function(_, button)
		GameTooltip:Hide()
		if button == "RightButton" then
			ns.OpenBooster()
		else
			ns.Album:Toggle()
		end
	end)
	CuratorOctoFull.SetScript(b, "OnDragStart", function(self)
		self.dragging = true
		GameTooltip:Hide()
		CuratorOctoFull.SetScript(self, "OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = CuratorOctoFull.GetEffectiveScale(Minimap)
			if mx and px and scale and scale > 0 then
				ns.db.minimap.angle = CuratorOctoFull.Mod(math.deg(math.atan2(py / scale - my, px / scale - mx)) , 360)
				Place(self, ns.db.minimap.angle)
			end
		end)
	end)
	CuratorOctoFull.SetScript(b, "OnDragStop", function(self)
		self.dragging = false
		CuratorOctoFull.SetScript(self, "OnUpdate", nil)
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		if self.dragging then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		local BT = ns.Beta
		GameTooltip:AddDoubleLine("Curator", BT and BT:VersionText() or ns.version, 1, 0.84, 0.48, 0.6, 0.6, 0.65)
		-- (1.7.0: suspended, a save edited outside the game; 1.9.1: banned for good)
		if BT and BT:Banned() then
			GameTooltip:AddLine(L["Curator banned"], 1, 0.3, 0.3)
		elseif BT and BT:Suspended() then
			GameTooltip:AddLine(L["Curator suspended"], 1, 0.3, 0.3)
		end
		local owned, total = ns.Collection:Overall()
		GameTooltip:AddLine(string.format(L["%d / %d cards"], owned, total), 0.9, 0.9, 0.95)
		local packs = ns.TotalPacks()
		if packs > 0 then
			GameTooltip:AddLine(string.format(L["Boosters: %d"], packs), 1, 0.86, 0.5)
		end
		-- (1.11.0) the rubies
		if ns.Rubies then
			GameTooltip:AddLine(string.format(L["Rubies: %s"], ns.Rubies.Text(ns.Rubies:Balance(), 14)), 1, 0.64, 0.68)
		end
		-- the level of the collector (the emblem of its rank), the rewards to claim, the boosters to
		-- choose
		local LV = ns.Level
		local level, into, need = LV.Of(LV:XP())
		local r, rank = LV.RankOf(level)
		GameTooltip:AddLine(LV.EmblemText(r, 16) .. " " .. L[rank.name] .. "  ·  " .. string.format(L["Collector level %d"], level)
			.. (need and ("  ·  " .. string.format(L["%s / %s XP"], ns.Num(into), ns.Num(need))) or ""), 0.75, 0.62, 1)
		local claim = Blocks("quests") and 0 or CuratorOctoFull.Length(ns.Quests:Claimable())
		if claim > 0 then
			GameTooltip:AddLine(string.format(L["Rewards to claim: %d (Quests tab)"], claim), 0.4, 1, 0.4)
		end
		local levels = CuratorOctoFull.Length(LV:Unclaimed())
		if levels > 0 then
			GameTooltip:AddLine(string.format(L["Rewards to claim: %d (Profile tab)"], levels), 0.4, 1, 0.4)
		end
		local offers = Blocks("choice") and 0 or LV:OfferCount()
		if offers > 0 then
			GameTooltip:AddLine(string.format(L["Rewards to choose: %d (inventory)"], offers), 0.4, 1, 0.4)
		end
		local achClaim = Blocks("achievements") and 0 or ns.Achievements:ClaimCount()
		if achClaim > 0 then
			GameTooltip:AddLine(string.format(L["Rewards to claim: %d (Achievements tab)"], achClaim), 0.4, 1, 0.4)
		end
		local choose = Blocks("choice") and 0 or LV:Choices()
		if choose > 0 then
			GameTooltip:AddLine(string.format(L["Boosters to choose: %d (inventory)"], choose), 1, 0.86, 0.5)
		end
		-- (1.14.0) the cases to open (Cases.lua)
		local cases = ns.Cases and ns.Cases:Total() or 0
		if cases > 0 then
			GameTooltip:AddLine(string.format(L["Cases to open: %d (/curator cases)"], cases), 1, 0.84, 0.26)
		end
		-- (1.13.0, after its first test: no tab of the social page until it is reworked; the trades that wait for an
		-- answer, here)
		local trades = (ns.Trade and ns.Trade.Waiting) and ns.Trade:Waiting() or 0
		if trades > 0 then
			GameTooltip:AddLine(string.format(L["Trades waiting for you: %d (/curator trade)"], trades), 0.45, 0.82, 1)
		end
		-- (1.14.0) the Steamwheedle Exchange: what is on sale, the buy orders, what is on the way (Market.lua)
		local MK = ns.Market
		local m = MK and MK.Db and MK:Db()
		if m then
			local sale, orders, way = 0, 0, 0
			for _ in pairs(m.ls) do
				sale = sale + 1
			end
			for _ in pairs(m.od) do
				orders = orders + 1
			end
			for _ in pairs(m.bu) do
				way = way + 1
			end
			for _ in pairs(m.fl) do
				way = way + 1
			end
			if sale + orders + way > 0 then
				GameTooltip:AddLine(string.format(L["Exchange: %d on sale, %d buy orders, %d on the way"], sale, orders, way), 1, 0.82, 0.25)
			end
		end
		GameTooltip:AddLine(L["Left click: open the album"], 0.75, 0.75, 0.8)
		GameTooltip:AddLine(L["Right click: open a booster"], 0.75, 0.75, 0.8)
		GameTooltip:AddLine(L["Drag: move the button"], 0.5, 0.5, 0.55)
		-- (the build of the author: the players who share their presence with him)
		if ns.Admin then
			ns.Admin:Tooltip(GameTooltip)
		end
		GameTooltip:AddLine(string.format("OctoWoW: %s", "CloudNine_Ex"), 0.5, 0.5, 0.55)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	self.button = b
	return b
end

function M:Update()
	if not ns.db then
		return
	end
	local b = self:Build()
	if not b then
		return
	end
	if ns.db.minimap.hide then
		b:Hide()
		return
	end
	Place(b, ns.db.minimap.angle or 200)
	local packs = ns.TotalPacks()
	b.count:SetText(packs > 0 and tostring(packs) or "")
	b.badge:SetCount(Waiting())
	b:Show()
end

ns.On("LOGIN", function()
	M:Update()
end)
ns.On("CLAIMS_CHANGED", function()
	if M.button and M.button:IsShown() then
		M.button.badge:SetCount(Waiting())
	end
end)
ns.On("CHANGED", function()
	if M.button and M.button:IsShown() then
		local packs = ns.TotalPacks()
		M.button.count:SetText(packs > 0 and tostring(packs) or "")
	end
end)
