local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.12.0) The window of the gift codes of the author (Gifts.lua): the code pasted in a box (a code is too
-- long for the chat), what it gives said as soon as it is read, or why it cannot be redeemed here, and the
-- button that redeems it. From the boosters of the inventory (the bar under the page), or /curator gift.
-------------------------------------------------------------------------------
local GU = {}
ns.GiftUI = GU

GU.WIDTH = 520
local LEFT, RIGHT = 24, 24
local BOX_H = 96
local GREEN, RED, DIM = { 0.45, 1, 0.45 }, { 1, 0.36, 0.28 }, { 0.75, 0.75, 0.8 }

local WHY = {
	damaged = "This code is not valid: it may be cut or changed. Copy it again, all of it.",
	version = "This code needs a newer version of Curator: update it first.",
	nokey = "This version of Curator cannot read gift codes.",
	used = "This code was already redeemed.",
	expired = "This code has expired.",
	closed = "Curator is closed: nothing can be received.",
	-- (1.14.0: Guard.lua)
	guard = "Curator gives nothing until /reload: another addon changed its cards.",
}

-- The code in what was pasted: a whole message, the code in it (cut by the lines of a chat: put together;
-- the words glued after it then: its signature as long as the key makes it).
local function CodeIn(text)
	if type(text) ~= "string" then
		return nil
	end
	local want = ns.Gifts:SigLetters()
	local function Trim(code)
		local head, p, s = CuratorOctoFull.Match(code, "^(CG%d+)%.([%w%-_]+)%.([%w%-_]+)$")
		if not head then
			return code
		end
		if want and CuratorOctoFull.Length(s) > want then
			s = string.sub(s, 1, want)
		end
		return head .. "." .. p .. "." .. s
	end
	local code = CuratorOctoFull.Match(text, "CG%d+%.[%w%-_]+%.[%w%-_]+")
	if code and (not want or CuratorOctoFull.Length(CuratorOctoFull.Match(code, "([%w%-_]+)$")) >= want) then
		return Trim(code)
	end
	local joined = string.gsub(text, "%s+", "")
	local whole = CuratorOctoFull.Match(joined, "CG%d+%.[%w%-_]+%.[%w%-_]+")
	return whole and Trim(whole) or code
end
GU.CodeIn = CodeIn

-- Who a code is for, said.
local function For(to)
	local kind = ns.Gifts.Kind(to)
	if kind == "cid" then
		return L["This code is for another collection."]
	end
	return string.format(L["This code is for another player: %s."], to)
end

function GU:Build()
	if self.frame then
		return self.frame
	end
	local f = S.Window("CuratorGift", self.WIDTH, 360)
	f:SetPoint("CENTER", 0, 80)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	tinsert(UISpecialFrames, "CuratorGift")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle(L["Gift code"])
	f.drag = S.DragBar(f, 22)
	if f.CloseButton then
		CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
			GU:Hide()
		end)
	end
	f.head = S.Text(f, "GameFontNormalLarge", "LEFT")
	CuratorOctoFull.SetWordWrap(f.head, true)
	f.intro = S.Text(f, "GameFontHighlight", "LEFT")
	CuratorOctoFull.SetWordWrap(f.intro, true)
	f.intro:SetSpacing(2)

	-- the box of the code: a text of several lines, in a frame that scrolls
	f.box = S.Inset(f)
	f.box:SetHeight(BOX_H)
	f.box:EnableMouse(true)
	local sf = CreateFrame("ScrollFrame", nil, f.box)
	sf:SetPoint("TOPLEFT", 9, -7)
	sf:SetPoint("BOTTOMRIGHT", -9, 7)
	sf:EnableMouseWheel(true)
	local eb = CreateFrame("EditBox", nil, sf)
	eb:SetMultiLine(true)
	eb:SetAutoFocus(false)
	eb:SetMaxLetters(ns.Gifts.MAX_CODE * 3)
	eb:SetFontObject(GameFontHighlightSmall or GameFontHighlight)
	eb:SetWidth(self.WIDTH - LEFT - RIGHT - 18)
	eb:SetHeight(BOX_H - 14)
	sf:SetScrollChild(eb)
	CuratorOctoFull.SetScript(sf, "OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		local y = math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 14))
		self:SetVerticalScroll(y)
	end)
	CuratorOctoFull.SetScript(f.box, "OnMouseDown", function()
		eb:SetFocus()
	end)
	CuratorOctoFull.SetScript(eb, "OnEscapePressed", function()
		GU:Hide()
	end)
	CuratorOctoFull.SetScript(eb, "OnTextChanged", function()
		GU:Read()
	end)
	-- (the line of the cursor kept in sight)
	CuratorOctoFull.SetScript(eb, "OnCursorChanged", function(self, _, y, _, h)
		local top = -(y or 0)
		local view = sf:GetHeight() or (BOX_H - 14)
		local now = sf:GetVerticalScroll() or 0
		if top < now then
			sf:SetVerticalScroll(top)
		elseif top + (h or 12) > now + view then
			sf:SetVerticalScroll(top + (h or 12) - view)
		end
	end)
	f.scroll = sf
	f.edit = eb
	f.hint = S.Text(f.box, "GameFontDisableSmall", "LEFT")
	f.hint:SetPoint("TOPLEFT", 11, -9)
	f.hint:SetText(L["Paste the code here (Ctrl+V)"])

	-- what the code gives, or why not
	f.result = S.Text(f, "GameFontNormal", "LEFT")
	CuratorOctoFull.SetWordWrap(f.result, true)
	f.result:SetSpacing(3)
	f.note = S.Text(f, "GameFontHighlightSmall", "LEFT")
	CuratorOctoFull.SetWordWrap(f.note, true)
	f.note:SetTextColor(1, 0.88, 0.6)

	f.redeem = ns.Hud.ClaimButton(f, 220, 36, L["Redeem"])
	CuratorOctoFull.SetScript(f.redeem, "OnClick", function()
		GU:Redeem()
	end)
	f.close = S.Button(f, L["Close"], 120, 24)
	CuratorOctoFull.SetScript(f.close, "OnClick", function()
		GU:Hide()
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		eb:ClearFocus()
	end)
	self.frame = f
	return f
end

-- Everything from the top down, each text as tall as its lines: the window as tall as all of it.
function GU:Layout()
	local f = self.frame
	local width = self.WIDTH
	f.head:ClearAllPoints()
	f.head:SetPoint("TOPLEFT", 70, -34)
	f.head:SetWidth(width - 70 - RIGHT)
	local y = math.max(74, 34 + (f.head:GetStringHeight() or 16) + 14)
	f.intro:ClearAllPoints()
	f.intro:SetPoint("TOPLEFT", LEFT, -y)
	f.intro:SetWidth(width - LEFT - RIGHT)
	y = y + (f.intro:GetStringHeight() or 12) + 10
	f.box:ClearAllPoints()
	f.box:SetPoint("TOPLEFT", LEFT, -y)
	f.box:SetPoint("TOPRIGHT", -RIGHT, -y)
	y = y + BOX_H + 10
	f.result:ClearAllPoints()
	f.result:SetPoint("TOPLEFT", LEFT, -y)
	f.result:SetWidth(width - LEFT - RIGHT)
	local rh = (f.result:GetText() or "") ~= "" and (f.result:GetStringHeight() or 12) or 12
	y = y + rh + 6
	f.note:ClearAllPoints()
	f.note:SetPoint("TOPLEFT", LEFT, -y)
	f.note:SetWidth(width - LEFT - RIGHT)
	if (f.note:GetText() or "") ~= "" then
		y = y + (f.note:GetStringHeight() or 10) + 6
	end
	y = y + 8
	f.redeem:ClearAllPoints()
	f.redeem:SetPoint("TOP", -70, -y)
	f.close:ClearAllPoints()
	f.close:SetPoint("LEFT", f.redeem, "RIGHT", 16, 0)
	f:SetHeight(y + 36 + 20)
end

-- What the code in the box gives (or why it cannot be redeemed): said under it, the button on when it can.
function GU:Read()
	local f = self.frame
	if not f then
		return
	end
	local text = f.edit:GetText() or ""
	CuratorOctoFull.SetShown(f.hint, text == "")
	-- (the code just redeemed: what it gave stays said until another one comes)
	if self.done and text == "" then
		return
	end
	self.done = nil
	local code = CodeIn(text)
	self.code = code
	f.note:SetText("")
	if not code then
		f.result:SetText(string.find(text, "%S") and L[WHY.damaged] or "")
		f.result:SetTextColor(RED[1], RED[2], RED[3])
		f.redeem:SetEnabled(false)
		self:Layout()
		return
	end
	local ok, why, g = ns.Gifts:Check(code)
	local lines = g and ns.Gifts:Lines(g) or nil
	if ok then
		local parts = { L["This code gives you:"] }
		for _, line in ipairs(lines) do
			parts[CuratorOctoFull.Length(parts) + 1] = "   ·  " .. line
		end
		if g.ends then
			local now = (GetServerTime and CuratorOctoFull.ServerTime()) or time()
			parts[CuratorOctoFull.Length(parts) + 1] = "|cffb4b4bc" .. string.format(L["To redeem within %s."], ns.Duration(g.ends - now)) .. "|r"
		end
		f.result:SetText(table.concat(parts, "\n"))
		f.result:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
	else
		local msg = why == "other" and For(g.to) or L[WHY[why] or WHY.damaged]
		if lines then
			msg = msg .. "\n|cffb4b4bc" .. table.concat(lines, ", ") .. "|r"
		end
		f.result:SetText(msg)
		f.result:SetTextColor(RED[1], RED[2], RED[3])
	end
	if g and g.note and g.note ~= "" then
		f.note:SetText(string.format(L["A word from the author: %s"], g.note))
	end
	f.redeem:SetLabel(L["Redeem"])
	f.redeem:SetEnabled(ok and true or false)
	f.redeem:SetPulse(ok and true or false)
	self:Layout()
end

-- (1.13.0) The album of the cards a gift gave (the first one), nil: none.
local function CardsAlbum(g)
	local c = g and ns.Gifts:Cards(g)[1]
	return c and c.series or nil
end

-- The button: the code redeemed (then the boosters to see; 1.13.0: the album of its cards).
function GU:Redeem()
	local f = self.frame
	if self.done then
		local s = CardsAlbum(self.done)
		self:Hide()
		if ns.Album and s then
			ns.Album:ShowSeries(s)
		elseif ns.Album then
			ns.Album:ShowBoosters()
		end
		return
	end
	if not self.code then
		return
	end
	local ok, why, g = ns.Gifts:Redeem(self.code)
	if not ok then
		ns.Play(ns.SND.close)
		f.result:SetText(why == "other" and For(g.to) or L[WHY[why] or WHY.damaged])
		f.result:SetTextColor(RED[1], RED[2], RED[3])
		f.redeem:SetEnabled(false)
		self:Layout()
		return
	end
	self.done = g
	self.code = nil
	local lines = ns.Gifts:Lines(g)
	f.edit:SetText("")
	f.hint:Show()
	local parts = { L["Received! Thank you for playing Curator."] }
	for _, line in ipairs(lines) do
		parts[CuratorOctoFull.Length(parts) + 1] = "   ·  " .. line
	end
	f.result:SetText(table.concat(parts, "\n"))
	f.result:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
	local boosters = false
	for _, kind in ipairs(ns.Gifts.KINDS) do
		if g.give[kind] then
			boosters = true
		end
	end
	f.redeem:SetLabel((CardsAlbum(g) and L["See the album"]) or (boosters and L["See my boosters"]) or L["Close"])
	f.redeem:SetEnabled(true)
	f.redeem:SetPulse(false)
	self:Layout()
end

-- Shown (with a code in it, when one came with /curator gift).
function GU:Show(code)
	local f = self:Build()
	f.head:SetText(L["A gift from the author of Curator"])
	f.intro:SetText(L["Paste the code you received, then redeem it. A code is for one player only, and works once."])
	self.done = nil
	f.edit:SetText((type(code) == "string" and string.find(code, "%S")) and code or "")
	self:Read()
	self:Layout()
	if not f:IsShown() then
		ns.Play(ns.SND.open)
	end
	f:Show()
	f:Raise()
	f.edit:SetFocus()
end

function GU:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

-- Redeemed: said in the chat and by an alert (the boosters to choose wait in the inventory, its boosters).
ns.On("GIFT_REDEEMED", function(g)
	local lines = ns.Gifts:Lines(g)
	ns.Print(string.format(L["Gift code redeemed: %s."], table.concat(lines, ", ")))
	local boosters = false
	for _, kind in ipairs(ns.Gifts.KINDS) do
		if g.give[kind] then
			boosters = true
		end
	end
	-- (1.13.0: the cards of an album: its emblem, a click opens it)
	local album = CardsAlbum(g)
	if ns.Toast then
		ns.Toast:Push({
			title = L["A gift from the author!"],
			name = lines[1] or "",
			color = { 1, 1, 1 },
			line = (CuratorOctoFull.Length(lines) > 1 and table.concat(lines, ", ", 2)) or (boosters and L["Put it in the album you want: the inventory, Boosters."] or ""),
			-- (1.12.1: a code of experience alone, the orb of the experience)
			tex = (album and { album.set or "SetElwynn" }) or (boosters and { "PackZoneChoice" }) or ((g.give.xp and not g.give.rubies) and { "XPOrb" }) or { "Ruby" },
			sound = ns.SND.questDone,
			onClick = function()
				if ns.Album and album then
					ns.Album:ShowSeries(album)
				elseif ns.Album then
					ns.Album:ShowBoosters()
				end
			end,
		})
	end
end)
