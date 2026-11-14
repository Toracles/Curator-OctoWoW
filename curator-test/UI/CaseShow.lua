local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local S = ns.Skin
local A = ns.Album
local CR = ns.CrateUI

-------------------------------------------------------------------------------
-- (1.14.0, after its second test: « la vitrine en jeu, et le site ») The cards of the cases in the showcase and in the
-- chat, as the cards of the boosters:
-- * pinned from their page in the album (UI/CaseDetail.lua: Pin to showcase; Collection.lua: C:PinCase), their finest
--   copy stands on its pedestal in the profile, in its case once appraised; the other players see it with the showcase
--   (Comm.lua: the message V), their own copy as it is (its condition, never a grade hidden; its grade once appraised);
-- * shown in the chat: "[Curator: <name> #k<edition>:<card>:<finish>:<condition>]" (T thunderforged, H titanforged; the
--   step of its condition 1 Mint ... 5 Poor, g and its grade once appraised). With Curator it shows as a link in the
--   colour of its rank, its name in your own language; over it, the card in a tooltip; a click shows it alone, in the
--   hand (UI/CaseView.lua: CR:ViewCopy); a shift-click puts it in the chat again. A version of before shows the text.
-------------------------------------------------------------------------------
local SH = {}
ns.CaseShow = SH

local GOLD = S.GOLD
local FIN_INK = { thunder = { 0.62, 0.84, 1 }, titan = { 1, 0.86, 0.46 } }
local FIN_LETTER = { thunder = "T", titan = "H" }
local FIN_OF = { T = "thunder", H = "titan" }
-- a card of the showcase in its case: smaller on its stand (UI/Expertise.lua: the same)
local SHOW_K = 0.82

local function Hex(c)
	return string.format(("%02x%02x%02x"), math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Words(tier)
	local r = CR.RANKS[tier] or CR.RANKS[1]
	return r.text or r.color
end

local function Coll(case)
	local CS = ns.Cases
	return L[(CS.COLLECTION and CS.COLLECTION[case]) or "Paladin Collection 2026"]
end

-- What is told of it: appraised, its grade; its finish before it (31 October, his word: never its condition in words,
-- it shows on the card, its wear; nil: nothing to tell).
local function Said(w)
	local E = ns.Expertise
	local text = (w.ap and E and tonumber(w.g)) and E.Label(tonumber(w.g)) or nil
	if w.f and CR.FINISH_NAME[w.f] then
		local fin = "|cff" .. Hex(FIN_INK[w.f]) .. L[CR.FINISH_NAME[w.f]] .. (ns.Mages and ns.Mages.Tag(w, true, true) and ("  ·  " .. ns.Mages.Tag(w, true, true)) or "") .. "|r"
		text = text and (fin .. "  ·  " .. text) or fin
	end
	return text
end

-- The lines of a card of a case and of a copy of it: its name in the colour of its rank, its collection and its rank,
-- what it is, its condition and its finish (once appraised: its grade, its marks).
function SH:Lines(tip, desc, w)
	local CD, E = ns.CaseDetail, ns.Expertise
	local tc = Words(desc.tier)
	tip:AddLine(CD.Name(desc), tc[1], tc[2], tc[3])
	tip:AddLine(Coll(desc.case) .. "  ·  " .. L[CR.RANKS[desc.tier].label], 0.7, 0.7, 0.72)
	local line = CD.Line(desc, w)
	if line ~= "" then
		tip:AddLine(line, 0.86, 0.86, 0.88, true)
	end
	if w then
		if w.ap and E and tonumber(w.g) then
			tip:AddLine(string.format(L["Appraised: %s"], E.Label(tonumber(w.g))), 1, 1, 1)
			local m = E.DecodeMarks(w.m)
			if m then
				tip:AddLine(E.MarksText(m), 0.78, 0.8, 0.86, true)
			end
		elseif Said(w) then
			tip:AddLine(Said(w), 1, 1, 1)
		end
		if w.ap and E and CR.FINISH_NAME[w.f or ""] then
			tip:AddLine(L[CR.FINISH_NAME[w.f]], FIN_INK[w.f][1], FIN_INK[w.f][2], FIN_INK[w.f][3])
		end
	end
end

-------------------------------------------------------------------------------
-- In the showcase of a profile
-------------------------------------------------------------------------------
-- A card of a case on a stand of the stage (c: the stand of a card of the boosters, UI/Profile.lua; v: { case, copy,
-- pinned }, nil: none there), in its case once appraised (as UI/Expertise.lua stands the cards of the boosters);
-- mine: my showcase.
function SH:Stand(st, c, v, mine)
	local cr = c.crate
	if not v then
		if cr then
			cr:Hide()
			cr.sig = nil
			c.crateHit:Hide()
		end
		c.caseV = nil
		return
	end
	local CD = ns.CaseDetail
	if not cr then
		cr = ns.CrateCard.New(st.holder, ns.CARD_SIZES.big[1])
		cr:SetFrameLevel(c:GetFrameLevel())
		cr:Hide()
		c.crate = cr
		local hit = CreateFrame("Button", nil, st.holder)
		hit:SetFrameLevel(cr:GetFrameLevel() + 20)
		CuratorOctoFull.SetScript(hit, "OnEnter", function(self)
			SH:StandEnter(self, c)
		end)
		CuratorOctoFull.SetScript(hit, "OnLeave", function()
			GameTooltip:Hide()
		end)
		CuratorOctoFull.SetScript(hit, "OnClick", function()
			SH:StandClick(c)
		end)
		c.crateHit = hit
	end
	local desc, w = v.case, v.copy
	local sig = table.concat({ desc.key, tostring(w.i), tostring(w.f), ns.Cases.WearKey(w), tostring(w.g), tostring(w.cl), tostring(w.fa) }, ":")
	if cr.sig ~= sig or not cr:IsShown() then
		cr.sig = sig
		cr:Set(CD.PickOf(desc, w), CR.RANKS)
		local def = ns.Crates and ns.Crates[desc.case]
		cr:SetBack(def and def.art and def.art.back or nil)
		cr:SetLive(true)
	end
	local info = (w.ap and tonumber(w.g)) and CD.Label(desc, w) or nil
	local k = (c.standK or 1) * (info and SHOW_K or 1)
	local margin = 0
	if info then
		local box = ns.SlabRects(cr.W, cr.H)
		margin = (-box[2] - cr.H / 2) * k
	end
	local w2, h2 = cr.W * k, cr.H * k
	cr:SetScale(k)
	cr:ClearAllPoints()
	cr:SetPoint("TOPLEFT", st, "TOPLEFT", (c.standX - w2 / 2) / k, (c.standBottom + margin + h2) / k)
	cr:SlabAlpha(1)
	cr:SetSlab(info)
	cr:Show()
	local hit = c.crateHit
	hit:ClearAllPoints()
	hit:SetPoint("TOPLEFT", st, "TOPLEFT", c.standX - w2 / 2, c.standBottom + margin + h2)
	CuratorOctoFull.SetSize(hit, w2, h2)
	hit:Show()
	if c.floor then
		CuratorOctoFull.SetSize(c.floor, w2 * (info and 1.4 or 1.2), 26)
	end
	c.caseV, c.caseMine = v, mine
end

function SH:StandEnter(owner, c)
	local v = c.caseV
	if not v then
		return
	end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	self:Lines(GameTooltip, v.case, v.copy)
	if c.caseMine then
		if v.pinned then
			GameTooltip:AddLine(L["In your showcase"], 1, 0.82, 0.25)
		end
		GameTooltip:AddLine(L["Click: show this copy"], 0.4, 1, 0.4)
	else
		GameTooltip:AddLine(L["Click to view"], GOLD[1], GOLD[2], GOLD[3])
	end
	GameTooltip:AddLine(L["Shift-click: show it in the chat"], GOLD[1], GOLD[2], GOLD[3])
	GameTooltip:Show()
end

-- A click: shift, in the chat; mine, shown big in the album of its collection; another player's, alone in the hand.
function SH:StandClick(c)
	local v = c.caseV
	if not v then
		return
	end
	GameTooltip:Hide()
	if ns.Links:Modified() then
		ns.Links:InsertCase(v.copy)
		return
	end
	ns.Play(ns.SND.cardFlip)
	if c.caseMine and v.copy.i and A.ShowCaseCopy then
		A:ShowCaseCopy(v.copy.i)
	else
		CR:ViewCopy(v.copy)
	end
end

-------------------------------------------------------------------------------
-- In the chat
-------------------------------------------------------------------------------
local K = ns.Links
-- "[Curator: <name> #k<edition>:<card>:<finish>:<condition>]" (1.14.0: ":<pattern>" after it, titanforged; 31 October:
-- ":w<its four marks>s<its seed>" after that, its wear, the card as it is; 1 November, his word: ":c<certificate>" between
-- them, certified by a master of the mages, Mages.lua: its family and its number on the link, its certificate a click
-- away)
local TOKEN = "%[Curator: [^%[%]]- #k(%w+):(%w+):(%a?):(g?[%d%.]+)([%w:%-]*)%]"

-- (its pattern, its certificate and its wear, after its condition: ":<pattern>:c<certificate>:w<marks>s<seed>")
local function CertPart(s)
	local tc = type(s) == "string" and (CuratorOctoFull.Match(s, ":c([0-9a-z]+%-[0-9a-z]+):") or CuratorOctoFull.Match(s, ":c([0-9a-z]+%-[0-9a-z]+)$")) or nil
	return tc and ns.Mages and ns.Mages.Unpack(tc) and tc or nil
end

local function Rest(rest)
	rest = type(rest) == "string" and rest or ""
	local pt = CuratorOctoFull.Match(rest, "^:(%d*)") or ""
	local wm, wv = CuratorOctoFull.Match(rest, ":w([1-9A][1-9A][1-9A][1-9A])s(%d+)$")
	return pt, wm, wv, CertPart(rest)
end

-- (its wear as a token and a link carry it: its marks veiled by its seed, never its grade in plain text, Cases.lua)
local function WearPart(w)
	local E, x = ns.Expertise, ns.Cases.WearOf(w)
	local wm = x and E and E.EncodeMarks and ns.Cases.Veil(E.EncodeMarks(x.m), x.seed)
	return wm and (":w" .. wm .. "s" .. tostring(x.seed)) or ""
end

-- The text a copy of a card of a case is sent as (w: its record, Cases.lua).
function K:CaseToken(w)
	local CD = ns.CaseDetail
	local desc = CD.DescOf(w)
	local what = desc.weapon and ("w" .. tostring(desc.weapon)) or (desc.entry and desc.entry.key) or "?"
	local state = (w.ap and tonumber(w.g)) and ("g" .. tostring(tonumber(w.g))) or tostring(ns.Cases.Step(ns.Cases.Word(w)))
	local name = string.gsub((CD.Name(desc) or "?"), "[%[%]]", "")
	local pt = ns.Cases.Pattern(w)
	local wear = WearPart(w)
	local MG = ns.Mages
	local tc = pt and MG and MG.Pack(MG.Of(w)) or nil
	return string.format(("[Curator: %s #k%s:%s:%s:%s%s%s%s]"), name, tostring(w.c), what, FIN_LETTER[w.f or ""] or "", state,
		(pt or wear ~= "" or tc) and (":" .. (pt or "")) or "", tc and (":c" .. tc) or "", wear)
end

-- Puts a copy of a card of a case in the chat (in the line being typed, else in a new one).
function K:InsertCase(w)
	if not (w and ns.Cases and ns.Cases:Known(w.c)) then
		return false
	end
	local text = self:CaseToken(w)
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

-- The copy a token or a link tells (a record as Cases.lua makes them, its grade hidden: none), else nil: a card of
-- the edition, or a weapon of legend of the list (UI/Crate.lua: CR.WeaponOf, its class and its side as the list has
-- them); a grade or a step whole, in their bounds.
local function CopyOf(case, what, letter, state, pt, wm, wv, tc)
	local CS, CM = ns.Cases, ns.CaseCards
	if not (CS and CM and CS:Known(case)) or type(state) ~= "string" then
		return nil
	end
	local wdef
	local weapon = CuratorOctoFull.Match(what, "^w(%d+)$")
	local tier
	if weapon then
		wdef = CR.WeaponOf and CR.WeaponOf(weapon)
		if not wdef then
			return nil
		end
		tier = CR.TOP
	else
		local e, r = CM.Entry(case, what)
		if not e then
			return nil
		end
		tier = r
	end
	local w = { c = case, e = (not wdef) and what or nil, w = wdef and wdef.id or nil, r = tier, f = FIN_OF[letter or ""],
		cl = wdef and wdef.class or nil, fa = wdef and wdef.faction or nil }
	local g = CuratorOctoFull.Match(state, "^g(%d%d?)$")
	local E = ns.Expertise
	if g then
		g = E and E.ValidGrade(g)
		if not g then
			return nil
		end
		w.ap, w.g = true, g
	else
		local step = CuratorOctoFull.Match(state, "^%d$") and tonumber(state)
		if not (step and step >= 1 and step <= CuratorOctoFull.Length(CS.CONDITION)) then
			return nil
		end
		w.cw = CS.CONDITION[step][2]
	end
	-- (1.14.0: titanforged, its pattern; 1 November: its certificate of the mages, Mages.lua)
	if w.f == "titan" and pt and pt ~= "" then
		w.pt = tonumber(pt)
		w.pt = CS.Pattern(w)
		local MG = ns.Mages
		if w.pt and tc and MG then
			w.tc = MG.Unpack(tc)
		end
	end
	-- (31 October: its wear, its marks checked by Cases.lua, its seed in its bounds)
	wv = tonumber(wv)
	if wm and wv and wv >= 1 and wv <= 999998 then
		w.wm, w.wv = wm, math.floor(wv)
	end
	return w
end

-- "addon:Curator:case:<edition>:<card>:<finish>:<condition>:<who showed it>"
function K:CaseLink(w, author)
	local CD = ns.CaseDetail
	local desc = CD.DescOf(w)
	local fin = w.f and CR.FINISH_NAME[w.f]
	local pt = ns.Cases.Pattern(w)
	-- (1 November, his word: its pattern told by the masters of the mages only: certified, its family and its number)
	local MG = ns.Mages
	local tag = MG and MG.Tag(w, true, true)
	local tc = tag and MG.Pack(MG.Of(w)) or nil
	local text = (CD.Name(desc) or "?") .. (fin and (" · " .. L[fin]) or "") .. (tag and (" · " .. tag) or "")
	local color = "ff" .. Hex(Words(desc.tier))
	if not self.clickable then
		return string.format(("|c%s[%s]|r"), color, text)
	end
	local what = desc.weapon and ("w" .. tostring(desc.weapon)) or desc.entry.key
	local state = w.ap and ("g" .. tostring(w.g)) or tostring(ns.Cases.Step(ns.Cases.Word(w)))
	local wear = WearPart(w)
	return string.format(("|c%s|Haddon:Curator:case:%s:%s:%s:%s:%s%s%s%s|h[%s]|h|r"), color, w.c, what, FIN_LETTER[w.f or ""] or "", state, author or "",
		(pt or wear ~= "" or tc) and (":" .. (pt or "")) or "", tc and (":c" .. tc) or "", wear, text)
end

-- What a link of a card of a case holds: its copy, who showed it.
function K:ParseCase(link)
	if type(link) ~= "string" or Secret(link) then
		return nil
	end
	local case, what, letter, state, author, pt = CuratorOctoFull.Match(link, "^addon:Curator:case:(%w+):(%w+):(%a?):(g?[%d%.]+):?([^:]*):?(%d*)")
	if not case then
		return nil
	end
	local wm, wv = CuratorOctoFull.Match(link, ":w([1-9A][1-9A][1-9A][1-9A])s(%d+)$")
	local w = CopyOf(case, what, letter, state, pt, wm, wv, CertPart(link))
	-- (who showed it: a name of the game, never a code of the chat)
	if author == "" or CuratorOctoFull.Length(author) > 64 or string.find(author, "[|\n\r]") then
		author = nil
	end
	return w, author
end

function K:CaseTooltip(owner, link)
	local w, author = self:ParseCase(link)
	if not w then
		return false
	end
	local CD = ns.CaseDetail
	local desc = CD.DescOf(w)
	GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
	SH:Lines(GameTooltip, desc, w)
	local mine = CuratorOctoFull.Length(CD:Copies(desc))
	if mine > 0 then
		GameTooltip:AddLine(string.format(L["In your album: %d"], mine), 0.4, 1, 0.4)
	else
		GameTooltip:AddLine(L["Not in your album yet"], 0.62, 0.62, 0.62)
	end
	if author and not ns.Guild:IsMe(author) then
		GameTooltip:AddLine(string.format(L["Shown by %s"], ns.Guild:Short(author)), 0.8, 0.8, 0.8)
	end
	self:AddHint(GameTooltip, true)
	GameTooltip:Show()
	self.tipShown = true
	return true
end

do
	-- (the messages with a card of a case in them: as links)
	local convert = K.Convert
	function K:Convert(msg, author, ...)
		local out = convert(self, msg, author, unpack(arg, 1, arg.n))
		local text = out or msg
		if type(text) ~= "string" or Secret(text) or not string.find(text, "#k", 1, true) then
			return out
		end
		if Secret(author) or type(author) ~= "string" or string.find(author, "|", 1, true) then
			author = nil
		end
		local changed = false
		text = string.gsub(text, TOKEN, function(case, what, letter, state, rest)
			local pt, wm, wv, tc = Rest(rest)
			local w = CopyOf(case, what, letter, state, pt, wm, wv, tc)
			if not w then
				return nil
			end
			changed = true
			return K:CaseLink(w, author)
		end)
		return changed and text or out
	end

	local onClick = K.OnClick
	function K:OnClick(link, ...)
		local w = self:ParseCase(link)
		if w then
			if self:Modified() then
				self:InsertCase(w)
			else
				ns.Play(ns.SND.cardFlip)
				CR:ViewCopy(w)
			end
			return true
		end
		return onClick(self, link, unpack(arg, 1, arg.n))
	end

	local tooltip = K.LinkTooltip
	function K:LinkTooltip(owner, link, ...)
		if self:CaseTooltip(owner, link) then
			return
		end
		return tooltip(self, owner, link, unpack(arg, 1, arg.n))
	end
end
