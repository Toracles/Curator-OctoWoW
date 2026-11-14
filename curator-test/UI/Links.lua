local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local MEDIA = ns.MEDIA
local C = ns.Collection
local Ease = ns.Ease
local S = ns.Skin

-- Cards shown in the chat. What is sent is plain text, "[Curator: Lardeur #448S]": the name of the card
-- in the language of who sends it, its creature, its finish (S shiny or thunderforged, H holographic
-- or titanforged). Everyone reads it; with Curator it shows as a link in the colour of the card's
-- rarity, its name in your own language. Over the link, the card in a tooltip; a click opens it big;
-- a shift-click puts it in the chat again. Shift-click a card of the album, of a booster or of a
-- profile to show it. (1.14.0, his idea) A titanforged card, the pattern of its copy after its H (Patterns.lua):
-- "[Curator: Lardeur #448H245]". (1 November, his word: « quand on partage la carte dans le chat, qu'on voit le saphir »)
-- Certified by a master of the mages, its certificate after it (Mages.lua: MG.Pack, "<when>-<master>"):
-- "[Curator: Lardeur #448H245~tnsxgg-2cn]": its family and its number on the link, its certificate a click away. Its
-- number shows only so: the masters' to tell.
-- (1.14.3, his word of November 6: « quand on clique sur la carte du gars qui a share sa carte on voit aussi la vrai carte
-- (usure/titanforged type etc ??) ») The copy shown goes with it, the very card: its wear, its case and its grade once
-- appraised, its restorations, its corruption and its seal, its signature, as a trade carries them (Copies.lua: CP.Pack),
-- never who had it; after its name, behind " =", where a Curator of before reads nothing and shows the card as before:
-- "[Curator: Lardeur =1a2b-3c4d #448H245~tnsxgg-2cn]" ("=*": signed by its innkeeper).
local K = {}
ns.Links = K

local LETTER = { shiny = "S", holo = "H" }
local FINISH = { S = "shiny", H = "holo" }
-- "[Curator: <name> #<creature><finish>]" (and "[Hoard: ...]", the cards shown by the players still on
-- Hoard, 1.3.1 and before)
local TOKENS = { "%[Curator: ([^%[%]]-) #(%d+)([SH]?)(%d*)~?([0-9a-z%-]*)%]", "%[Hoard: ([^%[%]]-) #(%d+)([SH]?)(%d*)~?([0-9a-z%-]*)%]" }
-- (1.14.3) the copy after the name, as it goes (a whole line of the chat holds 255 letters)
local COPY_MAX = 160
local GOLD = S.GOLD

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- The links of the addons are the client's own ("addon:..."): their clicks come through the
-- EventRegistry. A client without them shows the cards as coloured names only.
K.clickable = (EventRegistry ~= nil and EventRegistry.RegisterCallback ~= nil)
	and not (LinkUtil and LinkUtil.IsLinkHandlerRegistered and not LinkUtil.IsLinkHandlerRegistered("addon"))

-- (1.14.0) The pattern of a titanforged card shown (nil: none).
local function PatternOf(finish, pattern)
	return finish == "holo" and ns.Patterns and ns.Patterns.Number(pattern) or nil
end

-- (1 November) The certificate of the mages of a titanforged card shown, as it travels ("<when>-<master>"; nil: none, or
-- not one, Mages.lua).
local function CertOf(finish, pattern, tc)
	local MG = ns.Mages
	if not (MG and type(tc) == "string" and tc ~= "" and PatternOf(finish, pattern)) then
		return nil
	end
	return MG.Unpack(tc) and tc or nil
end
K.CertOf = CertOf

-- (the certificate of a copy of mine of that pattern, when none is given: the card shown from my album)
local function MyCert(card, finish, pattern)
	local CP, MG = ns.Copies, ns.Mages
	local pt = PatternOf(finish, pattern)
	if not (pt and CP and MG and card) then
		return nil
	end
	for _, r in ipairs(CP:List(card.key)) do
		if CP.Pattern(r) == pt and MG.Of(r) then
			return MG.Pack(MG.Of(r))
		end
	end
	return nil
end

-- (1.14.3) A copy as it goes with its card (nil: nothing to tell, or too long): what a trade carries of it (Copies.lua:
-- CP.Pack), never the character it came to first, who had it before, nor when it came; "*" first: signed by its
-- innkeeper. (A copy of another player's inventory: its seal as it came, Comm.lua.)
local function CopyText(rec, key)
	local CP = ns.Copies
	if type(rec) ~= "table" or not (CP and CP.Pack) then
		return nil
	end
	local r = {}
	for k, v in pairs(rec) do
		r[k] = v
	end
	-- (nor when nor how it came: nothing of that shows with it)
	r.ch, r.o, r.theirs, r.t, r.w = nil, nil, nil, nil, nil
	local th = type(rec.theirs) == "table" and rec.theirs or nil
	if th and type(th.seal) == "table" then
		r.seal = th.seal
	end
	local ok, pack = pcall(CP.Pack, r, key)
	if not (ok and type(pack) == "string" and pack ~= "") or CuratorOctoFull.Length(pack) > COPY_MAX or string.find(pack, "[%[%]#|=~:%*]") then
		return nil
	end
	return (rec.sg and "*" or "") .. pack
end
K.CopyText = CopyText

-- A copy back from what came with a card (nil: none, or it does not read): a record as mine are (CP.Unpack), its
-- finish the card's; a corruption only on a card that can have one (an album of an event).
local function CopyOf(text, card, finish)
	local CP = ns.Copies
	if type(text) ~= "string" or text == "" or CuratorOctoFull.Length(text) > COPY_MAX + 1 or not (CP and CP.Unpack and card) then
		return nil
	end
	local signed = string.sub(text, 1, 1) == "*"
	if signed then
		text = string.sub(text, 2)
	end
	local rec = CP.Unpack(text)
	if type(rec) ~= "table" then
		return nil
	end
	if rec.cor and not (card.series and card.series.event) then
		return nil
	end
	rec.o = nil
	rec.f = rec.cor and "c" or (CP.FK and CP.FK[finish or ""]) or nil
	if rec.f ~= "h" then
		rec.pt, rec.tc = nil, nil
	end
	rec.sg = (signed and rec.f == nil) or nil
	return rec
end
K.CopyOf = CopyOf

-- The case of a copy shown (appraised, its case closed: its grade, its marks, its certificate; sealed: its reliquary),
-- nil: none.
function K:CopyLabel(card, rec)
	local CP, E, SL, MG = ns.Copies, ns.Expertise, ns.Masters, ns.Mages
	if type(rec) ~= "table" or not card then
		return nil
	end
	local g = CP.Grade(rec)
	if g and rec.sl ~= false and E and E.LabelOf then
		local info = E:LabelOf(card, g / 100, E.DecodeMarks(rec.m), rec.ce, nil, { titan = MG and MG.Label(rec) or nil })
		if info and type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0 then
			info.restored = {}
			for i, v in ipairs(rec.r) do
				info.restored[i] = type(v) == "table" and tonumber(v[1]) or 0
			end
		end
		return info
	end
	if type(rec.seal) == "table" and SL and SL.LabelOf then
		local x = rec.seal
		return SL:LabelOf(card, nil, { g = x.g, s = x.s, c = x.c, t = x.t, by = x.by, k = rec.cor })
	end
	return nil
end

-- The text a card is sent as (1.14.3, rec: the copy shown, its very card with it).
function K:Token(card, finish, pattern, tc, rec)
	if finish == true then
		finish = "shiny"
	end
	local cert = CertOf(finish, pattern, tc)
	local copy = rec and CopyText(rec, card.key) or nil
	return string.format(("[Curator: %s%s #%d%s%s%s]"), C:Name(card), copy and (" =" .. copy) or "", card.npc, LETTER[finish] or "",
		PatternOf(finish, pattern) or "", cert and ("~" .. cert) or "")
end

-- The modifier of the links of the game (shift, unless it was changed) is down.
function K:Modified()
	if IsModifiedClick then
		local ok, on = pcall(IsModifiedClick, "CHATLINK")
		if ok and on then
			return true
		end
	end
	return (IsShiftKeyDown and IsShiftKeyDown()) and true or false
end

-- (1.14.3) What the line being typed still holds of room (a line of the chat: 255 letters at most).
local function Room()
	local U = ChatFrameUtil
	local get = (U and U.GetActiveWindow) or ChatEdit_GetActiveWindow
	local ok, box = false, nil
	if get then
		ok, box = pcall(get)
	end
	if ok and type(box) == "table" and box.GetText then
		local ok2, t = pcall(box.GetText, box)
		if ok2 and type(t) == "string" and not Secret(t) then
			return 255 - CuratorOctoFull.Length(t)
		end
	end
	return 255
end

-- Puts a card in the chat: in the line being typed, else in a new one. (1 November: tc, the certificate of the mages of
-- a titanforged copy; none given, the one of my copy of that pattern. 1.14.3: rec, the copy shown, its very card with it;
-- its certificate, its own.)
function K:Insert(card, finish, pattern, tc, rec)
	if finish == true then
		finish = "shiny"
	end
	if type(rec) == "table" then
		local MG = ns.Mages
		tc = CertOf(finish, pattern, tc) or CertOf(finish, pattern, MG and MG.Pack(MG.Of(rec)) or nil)
	else
		rec = nil
		tc = CertOf(finish, pattern, tc) or MyCert(card, finish, pattern)
	end
	local text = self:Token(card, finish, pattern, tc, rec)
	-- (a line of the chat too long with it, or no more room for it in the line being typed: the card without its copy)
	if rec and CuratorOctoFull.Length(text) > math.min(230, Room()) then
		text = self:Token(card, finish, pattern, tc)
	end
	local U = ChatFrameUtil
	local insert = (U and U.InsertLink) or ChatEdit_InsertLink
	if insert then
		local ok, done = pcall(insert, text)
		if ok and done then
			ns.Play(ns.SND.click)
			return true
		end
	end
	local open = (U and U.OpenChat) or ChatFrame_OpenChat
	if open and pcall(open, text) then
		ns.Play(ns.SND.click)
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- In the chat: the text becomes a link
-------------------------------------------------------------------------------
-- "addon:Curator:card:<creature>:<finish 0/1/2>:<who showed it>" (1.14.0: ":<pattern>" after it, a titanforged card;
-- 1 November: ":<certificate>" after that, certified by a master of the mages: its family and its number in its name;
-- 1.14.3: ":<pattern>:<certificate>:<the copy>", the copy shown, its grade or its seal in its name)
function K:Link(card, finish, author, pattern, tc, copy)
	local rec = copy and CopyOf(copy, card, finish) or nil
	if rec and rec.f == "c" then
		finish = "corrupt"
	end
	local f = C:FinishName(card, finish)
	local pt = PatternOf(finish, pattern)
	local cert = CertOf(finish, pt, tc)
	local tag = cert and ns.Mages.TagOf(pt, ns.Mages.Unpack(cert), false, true)
	local extra = ""
	local g = rec and ns.Copies.Grade(rec)
	if g and rec.sl ~= false then
		extra = " · " .. ns.Expertise.Text(g / 100)
	elseif rec and type(rec.seal) == "table" and ns.Masters then
		extra = " · " .. ns.Masters.Roman(ns.Masters.Valid(rec.seal.g))
	end
	local text = C:Name(card) .. (f and (" · " .. f) or "") .. (tag and (" · " .. tag) or "") .. extra
	local color = "ff" .. Hex(ns.RARITY[card.rarity].text)
	if not self.clickable then
		return string.format(("|c%s[%s]|r"), color, text)
	end
	if rec then
		return string.format(("|c%s|Haddon:Curator:card:%d:%d:%s:%s:%s:%s|h[%s]|h|r"), color, card.npc, ns.Guild.FinishCode(finish), author or "",
			pt or "", (pt and cert) or "", copy, text)
	end
	return string.format(("|c%s|Haddon:Curator:card:%d:%d:%s%s%s|h[%s]|h|r"), color, card.npc, ns.Guild.FinishCode(finish), author or "",
		pt and (":" .. pt) or "", (pt and cert) and (":" .. cert) or "", text)
end

-- A message with cards in it, as it shows (nil: no card in it).
function K:Convert(msg, author)
	if type(msg) ~= "string" or Secret(msg) or not (string.find(msg, "[Curator: ", 1, true) or string.find(msg, "[Hoard: ", 1, true)) then
		return nil
	end
	if Secret(author) or type(author) ~= "string" or string.find(author, "|", 1, true) then
		author = nil
	end
	local changed = false
	local out = msg
	for _, token in ipairs(TOKENS) do
		out = string.gsub(out, token, function(name, npc, letter, pt, tc)
			local card = ns.Cards["c" .. npc]
			if not card then
				return nil
			end
			changed = true
			-- (1.14.3: the copy shown, after its name)
			local copy = type(name) == "string" and CuratorOctoFull.Match(name, " =(%*?[^=]+)$") or nil
			return K:Link(card, FINISH[letter], author, pt ~= "" and tonumber(pt) or nil, tc ~= "" and tc or nil, copy)
		end)
	end
	return changed and out or nil
end

-- The channels of the chat; for a whisper of mine, the card is mine (not the one of who gets it).
local EVENTS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_CHANNEL", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_COMMUNITIES_CHANNEL",
}

local function Filter(_, event, msg, author, ...)
	local who = author
	if type(event) ~= "string" or string.find(event, "_BN_", 1, true) or event == "CHAT_MSG_COMMUNITIES_CHANNEL" then
		who = nil
	elseif event == "CHAT_MSG_WHISPER_INFORM" then
		who = ns.Guild:Me()
	else
		-- a message of mine (the twelfth argument of the event: who wrote it): the card is mine, named as
		-- I name myself (1.1.1: the link of my own card opened as the card of another player)
		local guid = CuratorOctoFull.Select(10, unpack(arg, 1, arg.n))
		if type(guid) == "string" and not Secret(guid) and UnitGUID and guid == UnitGUID("player") then
			who = ns.Guild:Me()
		end
	end
	local new = K:Convert(msg, who)
	if new then
		return false, new, author, unpack(arg, 1, arg.n)
	end
	return false
end
K.Filter = Filter

do
	local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
	if add then
		for _, e in ipairs(EVENTS) do
			pcall(add, e, Filter)
		end
	end
end

-- What a link of a card holds: the card, its finish, who showed it (1.14.0: the pattern of a titanforged one; 1 November:
-- its certificate of the mages, Mages.lua).
function K:Parse(link)
	if type(link) ~= "string" or Secret(link) then
		return nil
	end
	local npc, f, author, pt, tc, copy = CuratorOctoFull.Match(link, "^addon:Curator:card:(%d+):(%d):?([^:]*):?(%d*):?([0-9a-z%-]*):?(.*)$")
	if not npc then
		npc, f, author = CuratorOctoFull.Match(link, "^addon:Hoard:card:(%d+):(%d):?([^:]*)")
	end
	local card = npc and ns.Cards["c" .. npc]
	if not card then
		return nil
	end
	local finish = ns.Guild.FinishOf(f)
	-- (1.14.3: the copy shown, the very card)
	local rec = (copy and copy ~= "") and CopyOf(copy, card, finish) or nil
	if rec and rec.f == "c" then
		finish = "corrupt"
	end
	local pattern = PatternOf(finish, pt)
	return card, finish, (author ~= "" and author) or nil, pattern, CertOf(finish, pattern, tc), rec
end

-- A click on a link: the card, big; with shift, the card goes in the chat again.
function K:OnClick(link)
	local card, finish, author, pattern, tc, rec = self:Parse(link)
	if not card then
		return false
	end
	if self:Modified() then
		self:Insert(card, finish, pattern, tc, rec)
	else
		self:View(card, finish, author, pattern, nil, tc, rec)
	end
	return true
end

-- The arguments of the EventRegistry: the owner first, then those of the event. The link is the
-- first one of the addon, the frame before it (for the tooltip).
local function FindLink(...)
	for i = 1, CuratorOctoFull.Select("#", unpack(arg, 1, arg.n)) do
		local v = CuratorOctoFull.Select(i, unpack(arg, 1, arg.n))
		if type(v) == "string" and not Secret(v) and (string.find(v, "^addon:Curator:") or string.find(v, "^addon:Hoard:card:")) then
			return v, i
		end
	end
end

-- (1.14.0) The owner the EventRegistry keeps (where every addon reads it): a table with nothing in it, not the
-- module.
local OWNER = {}

if K.clickable then
	EventRegistry:RegisterCallback("SetItemRef", function(...)
		local link = FindLink(unpack(arg, 1, arg.n))
		if link then
			K:OnClick(link)
		end
	end, OWNER)
	EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkEnter", function(...)
		local link, i = FindLink(unpack(arg, 1, arg.n))
		if link then
			local frame = i > 1 and CuratorOctoFull.Select(i - 1, unpack(arg, 1, arg.n)) or nil
			K:LinkTooltip(type(frame) == "table" and frame.IsObjectType and frame or UIParent, link)
		end
	end, OWNER)
	EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkLeave", function()
		if K.tipShown then
			K.tipShown = false
			GameTooltip:Hide()
		end
	end, OWNER)
end

-------------------------------------------------------------------------------
-- The tooltip of a card shown by someone
-------------------------------------------------------------------------------
-- Its name, its rarity and finish, its creature, its album, what I have of it, who showed it (1.14.0: the pattern of a
-- titanforged one; 1 November: told by its certificate of the mages only, Mages.lua).
function K:AddLines(tooltip, card, finish, author, pattern, tc, rec)
	local r = ns.RARITY[card.rarity]
	tooltip:AddLine(C:Name(card), 1, 0.85, 0.5)
	local f = C:FinishName(card, finish)
	tooltip:AddLine(L[r.label] .. (f and (" · " .. f) or ""), r.text[1], r.text[2], r.text[3])
	-- (1.14.3: the copy shown, as it is)
	if type(rec) == "table" then
		self:CopyLines(tooltip, card, rec)
	end
	local pt = PatternOf(finish, pattern)
	local MG = ns.Mages
	local cert = MG and CertOf(finish, pt, tc) and MG.Unpack(tc)
	if cert then
		tooltip:AddLine(string.format(L["Certified by the mages: %s"], MG.TagOf(pt, cert)), 0.86, 0.92, 1)
		tooltip:AddLine(string.format(L["Certified by %s on %s"], MG.MasterName(cert.m) or L["a master of the mages"], date("%d/%m/%Y", cert.t)), 0.7, 0.74, 0.84)
	end
	tooltip:AddLine(C:Line(card), 0.8, 0.8, 0.85)
	tooltip:AddLine(string.format(("%s · %d/%d"), C:SeriesName(card.series), card.num, card.series.official or CuratorOctoFull.Length(card.series.list)), 0.62, 0.62, 0.62)
	local e = C:Entry(card)
	if e and e.n > 0 then
		tooltip:AddLine(string.format(L["In your album: %d"], e.n), 0.4, 1, 0.4)
		-- (1.11.0) its grade, when it was appraised
		local g = ns.Expertise and ns.Expertise:Grade(card)
		if g then
			tooltip:AddLine(string.format(L["Appraised: %s"], ns.Expertise.Label(g)), 1, 1, 1)
			local m = ns.Expertise:Marks(card)
			if m then
				tooltip:AddLine(ns.Expertise.MarksText(m), 0.78, 0.8, 0.86, true)
			end
		end
	else
		tooltip:AddLine(L["Not in your album yet"], 0.62, 0.62, 0.62)
	end
	if author and not ns.Guild:IsMe(author) then
		tooltip:AddLine(string.format(L["Shown by %s"], ns.Guild:Short(author)), 0.8, 0.8, 0.8)
	end
end

-- The hint of what a click does on a card that can be shown.
function K:AddHint(tooltip, click)
	if click then
		tooltip:AddLine(L["Click to view"], GOLD[1], GOLD[2], GOLD[3])
	end
	tooltip:AddLine(L["Shift-click: show it in the chat"], GOLD[1], GOLD[2], GOLD[3])
end

-- (1.14.3) What a copy shown says of itself: its grade and its marks in its case (its case opened), its restorations,
-- its seal, its corruption, its signature.
function K:CopyLines(tooltip, card, rec)
	local CP, E, SL = ns.Copies, ns.Expertise, ns.Masters
	local g = CP.Grade(rec)
	if g and rec.sl ~= false then
		tooltip:AddLine(string.format(L["Grade: %s"], E.Label(g / 100)), 1, 1, 1)
		local m = E.DecodeMarks(rec.m)
		if m then
			tooltip:AddLine(E.MarksText(m), 0.78, 0.8, 0.86, true)
		end
	elseif g then
		tooltip:AddLine(L["Its case opened: its grade is known at its next appraisal."], 0.72, 0.86, 1, true)
	end
	if type(rec.r) == "table" and CuratorOctoFull.Length(rec.r) > 0 then
		tooltip:AddLine(CuratorOctoFull.Length(rec.r) == 1 and L["Restored once"] or string.format(L["Restored %d times"], CuratorOctoFull.Length(rec.r)), 0.66, 0.9, 1)
	end
	local n = type(rec.seal) == "table" and SL and SL.Valid(rec.seal.g) or nil
	if n then
		tooltip:AddLine(string.format(L["Sealed: %s"], SL.Label(n)), 1, 1, 1)
	end
	if rec.f == "c" and tonumber(rec.cor) then
		tooltip:AddLine(string.format(L["A corrupted copy: %d %%"], tonumber(rec.cor)), 0.82, 0.6, 1)
	end
	if rec.sg then
		tooltip:AddLine(L["Signed by its innkeeper"], 1, 0.86, 0.5)
	end
end

function K:LinkTooltip(owner, link)
	local card, finish, author, pattern, tc, rec = self:Parse(link)
	if not card then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
	self:AddLines(GameTooltip, card, finish, author, pattern, tc, rec)
	self:AddHint(GameTooltip, true)
	GameTooltip:Show()
	self.tipShown = true
end

-------------------------------------------------------------------------------
-- A card shown, big: its own window
-------------------------------------------------------------------------------
-- (1 November: 42 higher, the button of its creature in 3D under the card with its words under it, and room for the
-- certificate of the mages above the buttons)
local W, H = 600, 516
local CARD_X, CARD_Y = 26, -74

function K:Build()
	if self.frame then
		return
	end
	local f = S.Window("CuratorCardView", W, H)
	f:SetPoint("CENTER", 0, 30)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	self.frame = f
	tinsert(UISpecialFrames, "CuratorCardView")
	if f.SetPortraitToAsset then
		f:SetPortraitToAsset(MEDIA .. "Icon")
	end
	f:SetTitle("Curator")
	CuratorOctoFull.SetScript(f.CloseButton, "OnClick", function()
		K:Hide()
	end)
	f.drag = S.DragBar(f, 22)

	-- the card in the hand: it turns all the way round, closer with the mouse wheel (UI/Inspect.lua; held
	-- in a frame placed without an offset, so that it stays in place)
	local cw, ch = ns.CARD_SIZES.huge[1], ns.CARD_SIZES.huge[2]
	f.spot = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.spot, 1, 1)
	f.spot:SetPoint("CENTER", f, "TOPLEFT", CARD_X + cw / 2, CARD_Y - ch / 2)
	f.holder = CreateFrame("Frame", nil, f)
	CuratorOctoFull.SetSize(f.holder, 1, 1)
	f.holder:SetPoint("CENTER", f.spot, "CENTER")
	local card = ns.NewCard(f.holder, "huge")
	card:SetPoint("CENTER", f.holder, "CENTER")
	ns.Inspect:Attach(card, f.holder, { zoom = { 0.9, 1.15, 1 } })
	f:EnableMouseWheel(true)
	CuratorOctoFull.SetScript(f, "OnMouseWheel", function(_, delta)
		ns.Inspect:Zoom(card, delta)
	end)
	f.card = card
	-- light of the card's rarity behind it
	f.halo = f:CreateTexture(nil, "BORDER")
	f.halo:SetTexture(MEDIA .. "Glow")
	f.halo:SetBlendMode("ADD")
	f.halo:SetPoint("CENTER", card, "CENTER")
	CuratorOctoFull.SetSize(f.halo, 480, 560)
	f.hint = S.Text(f, "GameFontDisableSmall")
	f.hintY = -ch / 2 - 8
	f.hint:SetPoint("TOP", f.spot, "CENTER", 0, f.hintY)
	f.hint:SetText(L["Drag to turn the card · Mouse wheel to zoom"])

	local x1 = CARD_X + ns.CARD_SIZES.huge[1] + 30
	local textW = W - x1 - 24
	f.name = S.Text(f, "GameFontNormalHuge", "LEFT")
	f.name:SetPoint("TOPLEFT", x1, -66)
	f.name:SetWidth(textW)
	f.name:SetWordWrap(true)
	f.gem = f:CreateTexture(nil, "ARTWORK")
	CuratorOctoFull.SetSize(f.gem, 20, 20)
	f.gem:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", -2, -7)
	f.rar = S.Text(f, "GameFontNormalLarge", "LEFT")
	f.rar:SetPoint("LEFT", f.gem, "RIGHT", 5, 0)
	f.rar:SetWidth(textW - 24)
	f.rar:SetWordWrap(false)
	-- (a legendary or mythic card: its entrance again)
	f.replay = S.Button(f, L["Replay its entrance"], textW, 24)
	CuratorOctoFull.SetScript(f.replay, "OnClick", function(self)
		if f.shown then
			ns.Inspect:Replay(f.shown, f.finish, self, true)
		end
	end)
	f.line = S.Text(f, "GameFontHighlight", "LEFT")
	f.line:SetPoint("TOPLEFT", f.gem, "BOTTOMLEFT", 2, -10)
	f.line:SetWidth(textW)
	f.rule = S.Divider(f, textW, 0.9)
	f.rule:SetPoint("TOPLEFT", f.line, "BOTTOMLEFT", 0, -10)
	f.album = S.Text(f, "GameFontHighlight", "LEFT")
	f.album:SetPoint("TOPLEFT", f.rule, "BOTTOMLEFT", 0, -10)
	f.album:SetWidth(textW)
	f.mine = S.Text(f, "GameFontHighlight", "LEFT")
	f.mine:SetPoint("TOPLEFT", f.album, "BOTTOMLEFT", 0, -8)
	f.mine:SetWidth(textW)
	f.by = S.Text(f, "GameFontHighlight", "LEFT")
	f.by:SetPoint("TOPLEFT", f.mine, "BOTTOMLEFT", 0, -8)
	f.by:SetWidth(textW)
	f.by:SetTextColor(0.8, 0.8, 0.8)
	-- (1 November, his word: a titanforged card shown in the chat, its certificate of the mages: its family and its
	-- number, who certified it; the certificate itself a click away, Mages.lua, UI/Mages.lua)
	f.cert = S.Text(f, "GameFontHighlight", "LEFT")
	f.cert:SetPoint("TOPLEFT", f.by, "BOTTOMLEFT", 0, -8)
	f.cert:SetWidth(textW)
	f.cert:SetWordWrap(true)
	f.certBtn = S.Button(f, L["See the certificate"], textW, 24)
	f.certBtn:SetPoint("TOPLEFT", f.cert, "BOTTOMLEFT", 0, -8)
	CuratorOctoFull.SetScript(f.certBtn, "OnClick", function()
		local MU = ns.MagesUI
		if MU and f.shown and f.tc then
			MU:ShowCertOf(f.shown, f.finish, f.pattern, f.tc, f)
		end
	end)
	f.certBtn:Hide()
	f.replay:SetPoint("TOPLEFT", f.by, "BOTTOMLEFT", 0, -12)

	-- their collection (who showed it), my album
	f.theirs = S.Button(f, "", textW, 24)
	f.theirs:SetPoint("BOTTOMLEFT", x1, 54)
	CuratorOctoFull.SetScript(f.theirs, "OnClick", function()
		ns.Play(ns.SND.click)
		local who = f.author
		K:Hide()
		if who then
			ns.Players:Show(who)
		end
	end)
	f.mineBtn = S.Button(f, L["My album"], textW, 24)
	f.mineBtn:SetPoint("BOTTOMLEFT", x1, 22)
	CuratorOctoFull.SetScript(f.mineBtn, "OnClick", function()
		ns.Play(ns.SND.click)
		local c = f.shown
		K:Hide()
		if c then
			ns.Album:ShowCard(c)
		end
	end)
	f.link = S.Button(f, L["Show in the chat"], textW, 24)
	f.link:SetPoint("BOTTOMLEFT", f.theirs, "TOPLEFT", 0, 8)
	CuratorOctoFull.SetScript(f.link, "OnClick", function()
		if f.shown then
			K:Insert(f.shown, f.finish, f.pattern, f.tc, f.rec)
		end
	end)
	-- a trade with who showed it: this card asked for
	f.trade = S.Button(f, L["I want it"], textW, 24)
	f.trade:SetPoint("BOTTOMLEFT", f.link, "TOPLEFT", 0, 8)
	CuratorOctoFull.SetScript(f.trade, "OnClick", function()
		local c, who, finish = f.shown, f.author, f.finish
		if c and who then
			ns.Play(ns.SND.click)
			K:Hide()
			ns.Album:StartTrade(who, nil, { { k = c.key, f = finish, n = 1 } })
		end
	end)
	CuratorOctoFull.SetScript(f.trade, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["I want it"], 1, 1, 1)
		if f.author then
			GameTooltip:AddLine(string.format(L["A trade with %s, this card asked for: then choose what you give."], ns.Guild:Short(f.author)), 0.85, 0.85, 0.85, true)
		end
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(f.trade, "OnLeave", function()
		GameTooltip:Hide()
	end)
	-- a card I do not have: looked for, or not any more
	f.wish = S.Button(f, "", textW, 24)
	CuratorOctoFull.SetScript(f.wish, "OnClick", function()
		local c = f.shown
		if c and ns.Trade then
			local ok, why = ns.Trade:ToggleWish(c)
			ns.Play(ok and ns.SND.ink or ns.SND.close)
			if not ok and why == "full" then
				ns.Print(L["You already look for %d cards: stop looking for one first."], ns.Trade:WishMax())
			end
			K:PaintWish()
		end
	end)

	CuratorOctoFull.SetScript(f, "OnUpdate", function(_, elapsed)
		K.t = (K.t or 0) + elapsed
		-- the card in the hand; left alone a while, its creature turns slowly in it
		local tn = card.turn
		if tn.dragging or tn.target or tn.vy ~= 0 then
			f.idle = 0
		else
			f.idle = (f.idle or 0) + elapsed
			if f.idle > 2.5 then
				card.turnFacing = (card.turnFacing or 0.4) + elapsed * 0.35
			end
		end
		ns.Inspect:Update(card, elapsed)
		card:Tick(K.t)
	end)
	CuratorOctoFull.SetScript(f, "OnHide", function()
		card.turn.dragging = false
		ns.CancelOwner(K)
		-- (its certificate, shown beside it, with it)
		local MU = ns.MagesUI
		if MU and MU.HideCertWindow then
			MU:HideCertWindow(f)
		end
	end)
end

-- Opens a card shown by someone (author: who showed it, nil for an unknown one).
-- (1.14.0, his idea: pattern, the pattern of a titanforged copy, Patterns.lua; 1 November: tc, its certificate of the
-- mages, Mages.lua)
-- (1.14.3: rec, the copy shown, the very card: its wear, in its case or its reliquary, its corruption, its signature)
function K:View(card, finish, author, pattern, wear, tc, rec)
	self:Build()
	local f = self.frame
	if finish == true then
		finish = "shiny"
	end
	rec = type(rec) == "table" and rec or nil
	if rec then
		wear = wear or (ns.Wear and ns.Wear.Of(rec)) or nil
		if rec.f == "c" then
			finish = "corrupt"
		end
	end
	f.shown, f.finish, f.author, f.pattern, f.rec = card, finish, author, pattern, rec
	f.tc = CertOf(finish, pattern, tc)
	local r = ns.RARITY[card.rarity]
	f.card:SetCard(card, { owned = true, finish = finish, facing = 0.4, pattern = pattern, wear = wear,
		corrupt = (rec and finish == "corrupt") and tonumber(rec.cor) or nil, signed = (rec and rec.sg) and true or nil })
	f.card:ShowSide("front")
	-- (1.14.3: in its case, a little smaller: its case fits, as in the album)
	local info = rec and self:CopyLabel(card, rec) or nil
	f.card:SlabAlpha(1)
	f.card:SetSlab(info)
	local t = f.card.turn
	if t then
		t.min, t.max = info and 0.66 or 0.9, info and 1.02 or 1.15
	end
	ns.Inspect:Reset(f.card, 0, info and 0.8 or 1)
	-- (1 November: a card of a portrait has its button under it, « See in 3D », UI/Inspect.lua: the words under the button)
	local b3 = f.card.see3D
	f.hint:ClearAllPoints()
	if b3 and b3:IsShown() then
		f.hint:SetPoint("TOP", b3, "BOTTOM", 0, -6)
	else
		f.hint:SetPoint("TOP", f.spot, "CENTER", 0, f.hintY)
	end
	f.halo:SetVertexColor(r.glow[1], r.glow[2], r.glow[3])
	f.halo:SetAlpha(0.16 + 0.05 * card.rarity)
	f.gem:SetTexture(MEDIA .. "Gem" .. card.rarity)
	S.SetFontObject(f.name, "GameFontNormalHuge")
	f.name:SetText(C:Name(card))
	if ns.TextWidth(f.name) > f.name:GetWidth() * 0.98 then
		S.Fit(f.name, C:Name(card), f.name:GetWidth() * 0.98, 19, 14)
	end
	f.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	local fin = C:FinishName(card, finish)
	f.rar:SetText(L[r.label] .. (fin and (" · " .. fin) or ""))
	f.rar:SetTextColor(r.text[1], r.text[2], r.text[3])
	-- (1 November: titanforged, certified by a master of the mages: its family and its number, who certified it; not
	-- certified: said so, its number the masters' to tell)
	local MG = ns.Mages
	local pat = PatternOf(finish, pattern)
	local cert = f.tc and MG and MG.Unpack(f.tc)
	if cert then
		-- (who certified it and when, on a line of its own: « Par Archimage Shymm, le 21/09/2026 »)
		f.cert:SetText(string.format(L["Certified by the mages: %s"], MG.TagOf(pat, cert)) .. "\n|cffa9a9b4"
			.. string.format(L["By %s, on %s"], MG.MasterName(cert.m) or L["a master of the mages"], date("%d/%m/%Y", cert.t)) .. "|r")
		f.cert:SetTextColor(0.86, 0.92, 1)
	elseif pat then
		f.cert:SetText(L["Not certified by a master of the mages"])
		f.cert:SetTextColor(0.6, 0.62, 0.7)
	else
		f.cert:SetText("")
	end
	CuratorOctoFull.SetShown(f.certBtn, cert and true or false)
	if ns.MagesUI and ns.MagesUI.HideCertWindow then
		ns.MagesUI:HideCertWindow(f)
	end
	f.line:SetText(C:Line(card))
	f.album:SetText(string.format(("%s · %d/%d"), C:SeriesName(card.series), card.num, card.series.official or CuratorOctoFull.Length(card.series.list)))
	-- (1.13.0: a card of a picture, the Hardcup Saison 3, has no entrance to play again)
	CuratorOctoFull.SetShown(f.replay, card.rarity >= 5 and not (card.art and card.art.fill))
	-- (1 November: under its certificate, when it has one)
	f.replay:ClearAllPoints()
	if cert then
		f.replay:SetPoint("TOPLEFT", f.certBtn, "BOTTOMLEFT", 0, -8)
	elseif pat then
		f.replay:SetPoint("TOPLEFT", f.cert, "BOTTOMLEFT", 0, -12)
	else
		f.replay:SetPoint("TOPLEFT", f.by, "BOTTOMLEFT", 0, -12)
	end
	f.replay:SetEnabled(not (ns.Cinematic and ns.Cinematic:IsPlaying()))
	local e = C:Entry(card)
	if e and e.n > 0 then
		f.mine:SetText(string.format(L["In your album: %d"], e.n))
		f.mine:SetTextColor(0.4, 1, 0.4)
	else
		f.mine:SetText(L["Not in your album yet"])
		f.mine:SetTextColor(0.62, 0.62, 0.62)
	end
	local other = author and not ns.Guild:IsMe(author)
	f.by:SetText(other and string.format(L["Shown by %s"], ns.Guild:Short(author)) or "")
	CuratorOctoFull.SetShown(f.theirs, other and true or false)
	if other then
		f.theirs:SetLabel(string.format(L["%s's collection"], ns.Guild:Short(author)))
	end
	f.link:ClearAllPoints()
	f.link:SetPoint("BOTTOMLEFT", other and f.theirs or f.mineBtn, "TOPLEFT", 0, 8)
	-- (a card of another player: ask them for it; a card I do not have: look for it)
	local tradeOk = other and ns.Trade and ns.Trade:CanTrade() and ns.Trade:CanReach(author) ~= false
	CuratorOctoFull.SetShown(f.trade, tradeOk and true or false)
	local owned = e and e.n > 0
	CuratorOctoFull.SetShown(f.wish, ns.Trade ~= nil and not owned)
	f.wish:ClearAllPoints()
	f.wish:SetPoint("BOTTOMLEFT", tradeOk and f.trade or f.link, "TOPLEFT", 0, 8)
	self:PaintWish()
	f.idle = 0
	ns.CancelOwner(self)
	if not f:IsShown() then
		f:SetAlpha(0)
		f:Show()
		ns.Tween(0.2, function(k)
			f:SetAlpha(k)
		end, nil, Ease.outQuad, self)
	end
	-- (over the album, when it is open)
	f:Raise()
	ns.Play(ns.SND.cardFlip)
	ns.Delay(0.25, function()
		f.card:Animate(K)
		f.card:PlayVoice()
	end, self)
end

-- The button of the card looked for.
function K:PaintWish()
	local f = self.frame
	local c = f and f.shown
	if not (c and ns.Trade) then
		return
	end
	f.wish:SetLabel(ns.Trade:Wished(c) and L["Stop looking for it"] or L["Look for it"])
end

function K:Hide()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
		ns.Play(ns.SND.close)
	end
end
