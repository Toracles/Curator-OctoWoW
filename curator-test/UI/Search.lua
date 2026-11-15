local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin

-------------------------------------------------------------------------------
-- (1.10.0) The search of a card in the album: on the contents, the button of the magnifier (or /curator
-- search name) opens a field; the cards whose name holds what is typed come under it (in the language of
-- the game, in English too; the case and the accents do not count), the ones that begin with it first. A click
-- (or Enter: the first one) opens the album on the card.
-------------------------------------------------------------------------------
local SE = {}
ns.Search = SE

SE.MAX = 8

-- Lower case, the accents of the Latin letters gone (é: e), the Cyrillic in lower case (Comm.lua).
local ACCENTS = {
	["à"] = "a", ["á"] = "a", ["â"] = "a", ["ä"] = "a", ["ã"] = "a", ["å"] = "a", ["ç"] = "c", ["è"] = "e", ["é"] = "e",
	["ê"] = "e", ["ë"] = "e", ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i", ["ñ"] = "n", ["ò"] = "o", ["ó"] = "o",
	["ô"] = "o", ["ö"] = "o", ["õ"] = "o", ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u", ["ý"] = "y", ["ÿ"] = "y",
	["œ"] = "oe", ["æ"] = "ae",
}

function SE.Fold(s)
	s = ns.Guild.Fold(tostring(s or ""))
	s = string.gsub(s, "[\195\197][\128-\191]", function(c)
		return ACCENTS[c] or c
	end)
	s = string.gsub(s, "[%s%-']+", " ")
	return s
end

-- Every card with what is searched in it: its name here, its name in English.
function SE:Index()
	if self.index then
		return self.index
	end
	local list = {}
	for _, s in ipairs(ns.Series or {}) do
		for _, card in ipairs(s.list or {}) do
			local here = ns.Collection:Name(card)
			local en = s.names and s.names.enUS and s.names.enUS[card.npc] or here
			list[CuratorOctoFull.Length(list) + 1] = { card = card, a = SE.Fold(here), b = SE.Fold(en) }
		end
	end
	self.index = list
	return list
end

-- The cards whose name holds the text (those that begin with it first, then the shorter names), at most max.
function SE:Find(text, max)
	local q = string.gsub(string.gsub(SE.Fold(text), "^ +", ""), " +$", "")
	if CuratorOctoFull.Length(q) < 2 then
		return {}
	end
	local hits = {}
	for _, it in ipairs(self:Index()) do
		local ia, ib = string.find(it.a, q, 1, true), string.find(it.b, q, 1, true)
		if ia or ib then
			local first = (ia == 1) or (ib == 1)
			hits[CuratorOctoFull.Length(hits) + 1] = { card = it.card, first = first, len = CuratorOctoFull.Length(it.a) }
		end
	end
	table.sort(hits, function(x, y)
		if x.first ~= y.first then
			return x.first
		end
		if x.len ~= y.len then
			return x.len < y.len
		end
		return x.card.npc < y.card.npc
	end)
	local out = {}
	for i = 1, math.min(max or self.MAX, CuratorOctoFull.Length(hits)) do
		out[i] = hits[i].card
	end
	return out, CuratorOctoFull.Length(hits)
end

-------------------------------------------------------------------------------
-- The field and its results
-------------------------------------------------------------------------------
function SE:Build()
	if self.frame then
		return self.frame
	end
	local f = CreateFrame("Frame", "CuratorSearch", UIParent, CuratorOctoFull.BackdropTemplate())
	CuratorOctoFull.SetSize(f, 360, 64)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
	end
	f:Hide()
	tinsert(UISpecialFrames, "CuratorSearch")
	f.title = S.Text(f, "GameFontNormal", "LEFT")
	f.title:SetPoint("TOPLEFT", 12, -10)
	f.title:SetText(L["Search a card"])
	local box = S.Inset(f)
	box:SetPoint("TOPLEFT", 10, -28)
	box:SetPoint("TOPRIGHT", -10, -28)
	box:SetHeight(26)
	local eb = CreateFrame("EditBox", nil, box)
	eb:SetPoint("TOPLEFT", 8, -2)
	eb:SetPoint("BOTTOMRIGHT", -8, 2)
	CuratorOctoFull.SetAutoFocus(eb, false)
	eb:SetFontObject(GameFontHighlight)
	eb:SetMaxLetters(40)
	CuratorOctoFull.SetScript(eb, "OnTextChanged", function()
		SE:Update()
	end)
	CuratorOctoFull.SetScript(eb, "OnEnterPressed", function()
		local first = SE.results and SE.results[1]
		if first then
			SE:Go(first)
		end
	end)
	CuratorOctoFull.SetScript(eb, "OnEscapePressed", function()
		SE:Hide()
	end)
	f.eb = eb
	f.rows = {}
	for i = 1, self.MAX do
		local i = i; local r = CreateFrame("Button", nil, f)
		r:SetHeight(22)
		r:SetPoint("TOPLEFT", 12, -60 - (i - 1) * 24)
		r:SetPoint("TOPRIGHT", -12, -60 - (i - 1) * 24)
		r:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
		r.name = S.Text(r, "GameFontNormal", "LEFT")
		r.name:SetPoint("LEFT", 4, 0)
		r.album = S.Text(r, "GameFontHighlightSmall", "RIGHT")
		r.album:SetPoint("RIGHT", -4, 0)
		r.album:SetTextColor(0.62, 0.62, 0.62)
		CuratorOctoFull.SetScript(r, "OnClick", function(self)
			if self.card then
				SE:Go(self.card)
			end
		end)
		r:Hide()
		f.rows[i] = r
	end
	f.more = S.Text(f, "GameFontHighlightSmall", "LEFT")
	f.more:SetTextColor(0.62, 0.62, 0.62)
	self.frame = f
	return f
end

function SE:Show(text)
	local f = self:Build()
	f:ClearAllPoints()
	local album = ns.Album and ns.Album.frame
	if album and album:IsShown() then
		f:SetPoint("BOTTOM", album, "BOTTOM", 0, 34)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	end
	f:Show()
	f.eb:SetText(text or "")
	f.eb:SetFocus()
	self:Update()
end

function SE:Hide()
	if self.frame then
		self.frame.eb:ClearFocus()
		self.frame:Hide()
	end
end

function SE:Toggle()
	if self.frame and self.frame:IsShown() then
		return self:Hide()
	end
	self:Show()
end

function SE:Update()
	local f = self.frame
	local text = f.eb:GetText() or ""
	local list, all = self:Find(text)
	self.results = list
	for i, r in ipairs(f.rows) do
		local card = list[i]
		r.card = card
		if card then
			local col = ns.RARITY[card.rarity].text
			r.name:SetText(ns.Collection:Name(card))
			r.name:SetTextColor(col[1], col[2], col[3])
			local owned = ns.Collection:Owned(card)
			r.album:SetText(ns.Collection:SeriesName(card.series) .. "  ·  " .. (owned and L["In your album"] or L["Missing"]))
			r:Show()
		else
			r:Hide()
		end
	end
	local n = CuratorOctoFull.Length(list)
	local h = 64 + n * 24
	f.more:ClearAllPoints()
	f.more:SetPoint("TOPLEFT", 14, -60 - n * 24)
	if (all or 0) > n then
		f.more:SetText(string.format(L["%d more: type more of the name."], all - n))
		h = h + 18
	elseif CuratorOctoFull.Length(SE.Fold(text)) >= 2 and n == 0 then
		f.more:SetText(L["No card with this name."])
		h = h + 18
	else
		f.more:SetText("")
	end
	f:SetHeight(h)
end

-- The album opened on the card.
function SE:Go(card)
	self:Hide()
	ns.Play(ns.SND.page)
	ns.Album:ShowCard(card)
end

-------------------------------------------------------------------------------
-- The button of the magnifier, on the contents of the album
-------------------------------------------------------------------------------
function SE:Button()
	local A = ns.Album
	local f = A and A.frame
	if not (f and f.toc) or f.searchBtn then
		return f and f.searchBtn
	end
	local b = CreateFrame("Button", nil, f)
	CuratorOctoFull.SetSize(b, 24, 24)
	b:SetPoint("LEFT", f.gauge, "RIGHT", 12, 0)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	CuratorOctoFull.SetScript(b, "OnClick", function()
		ns.Play(ns.SND.click)
		SE:Toggle()
	end)
	CuratorOctoFull.SetScript(b, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Search a card"], 1, 1, 1)
		GameTooltip:AddLine(L["Type a part of its name: the album opens on it."], 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(b, "OnLeave", function()
		GameTooltip:Hide()
	end)
	b:Hide()
	f.searchBtn = b
	-- (on the contents only)
	CuratorOctoFull.HookScript(f.toc, "OnShow", function()
		b:Show()
	end)
	CuratorOctoFull.HookScript(f.toc, "OnHide", function()
		b:Hide()
		SE:Hide()
	end)
	CuratorOctoFull.SetShown(b, f.toc:IsShown())
	return b
end

if ns.Album and ns.Album.Build then
	local build = ns.Album.Build
	ns.Album.Build = function(self, ...)
		local r = build(self, unpack(arg, 1, arg.n))
		if self.frame and self.frame.toc then
			SE:Button()
		end
		return r
	end
end
