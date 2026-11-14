local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })
local Ease = ns.Ease

-------------------------------------------------------------------------------
-- (1.14.0, after its first test) A card of a case looked at alone, in the window of the cases (UI/Crate.lua), held in
-- the hand as the card that comes out of a case is (turned to its back, closer with the wheel; 1 November: Back closes
-- it, and the window with it; a click beside it no more):
-- * a card of the collection not won yet: as the case shows it (the album of its collection, UI/CaseAlbum.lua);
-- * a card that came out of a contract (UI/Contract.lua): as a card comes out of a case, in its light, without the case
--   nor its band (CR:RevealWon).
-- (1.14.0, after its second test) A card won is shown big in the album, as the cards of the boosters are
-- (UI/CaseDetail.lua: its socle, its panel, its copies, its expertise at a banker, the scene of the expert): CR:ViewCard
-- leads there.
-------------------------------------------------------------------------------
local CR = ns.CrateUI

local function Colour(tier)
	local r = CR.RANKS[tier] or CR.RANKS[1]
	return r.color, r.text or r.color
end

-- (what the viewer had of its own, gone with its expertise: nothing to build any more)
function CR:BuildViewer()
	local f = self:Build()
	return f.inspect
end

-------------------------------------------------------------------------------
-- A card looked at alone
-------------------------------------------------------------------------------
-- The window of the cases with the card alone, the scene of its case away.
function CR:Alone(case)
	local f = self:Build()
	self:BuildViewer()
	self:Stop()
	self:CloseInspect(true)
	self.real, self.edition = case, case
	self:MakeCase()
	f:Show()
	self:Layout()
	for _, x in ipairs({ f.case, f.panel, f.band, f.buttons, f.reveal, f.hint, f.title, f.sub }) do
		x:Hide()
	end
	self.state = "view"
	return f
end

-- Its words under it: a card of the collection not won yet.
function CR:ViewWords(pick)
	local ins = self.frame.inspect
	local CI, CC = ns.CrateItems, ns.CrateCard
	local _, ink = Colour(pick.tier)
	local col = Colour(pick.tier)
	if pick.weapon then
		ins.name:SetText(CC.WeaponName(pick.weapon) or L["Priceless card"])
		ins.from:SetText(CC.WeaponNote(pick.weapon) or "")
	elseif pick.secret then
		ins.name:SetText(L["Priceless card"])
		ins.from:SetText(L["A weapon of legend. Which one stays a mystery."])
	elseif pick.entry then
		ins.name:SetText(CI:Name(pick.entry))
		ins.from:SetText(CI:From(pick.entry))
	end
	ins.name:SetTextColor(ink[1], ink[2], ink[3])
	ins.rank:SetText(L[CR.RANKS[pick.tier].label])
	ins.rank:SetTextColor(col[1], col[2], col[3])
	ins.extra:SetText(L["Not in your collection yet."])
	ins.extra:SetTextColor(0.6, 0.6, 0.64)
	ins.extra:Show()
	ins.from:ClearAllPoints()
	ins.from:SetPoint("TOP", ins.extra, "BOTTOM", 0, -8)
	-- (1 November: the button of a certificate, for a copy certified only: CR:ViewCopy)
	if ins.certBtn then
		ins.certBtn:Hide()
	end
end

-- The card held (a pick of UI/Crate.lua: its rank, its entry or its weapon, its wear, its finish).
function CR:ViewHold(pick)
	local f = self.frame
	local ins = f.inspect
	ins.pick, ins.won = pick, false
	local col = Colour(pick.tier)
	ins.card:Set({ tier = pick.tier, entry = pick.entry, weapon = pick.weapon, secret = pick.secret and not pick.weapon,
		wear = pick.wear, finish = pick.finish, pt = pick.pt, def = pick.def or (self.own and self.own.def) }, self.RANKS)
	-- (no case of an expert, unless a copy appraised asks for it: CR:ViewCopy)
	if ins.card.SetSlab then
		ins.card:SetSlab(nil)
	end
	ins.card:SetLive(true)
	ins.card:SetBack(self.own and self.own.def.art and self.own.def.art.back or nil)
	if ns.Inspect and ins.card.turn then
		ns.Inspect:Reset(ins.card, 0, 1)
	end
	ins.glow:SetVertexColor(col[1], col[2], col[3], 0.5)
	ns.CancelOwner(ins.card)
	if pick.entry then
		ns.Delay(0.2, function()
			ns.CrateItems:Play(pick.entry, ins.card)
		end, ins.card)
	end
	ins:SetAlpha(0)
	ins:Show()
	ns.Play(ns.SND.cardFlip)
	ns.Tween(0.25, function(e, raw)
		ins:SetAlpha(raw)
		ins.card:SetScale(0.85 + 0.15 * e)
	end, nil, Ease.outBack, ins)
end

-- A card won (id: its number, Cases.lua): shown big in the album of its collection (UI/CaseDetail.lua).
function CR:ViewCard(id)
	local A = ns.Album
	if A and A.ShowCaseCopy then
		return A:ShowCaseCopy(id)
	end
end

-- A card of a collection not won yet, looked at alone (entry: its card; nil: the golden card of the priceless rank).
function CR:ViewEntry(case, tier, entry)
	self:Alone(case or (ns.Cases and ns.Cases.EDITION))
	self.viewing = true
	local pick = entry and { tier = tier, entry = entry } or { tier = self.TOP, secret = true }
	self:ViewHold(pick)
	self:ViewWords(pick)
end

-- (1.14.0, after its second test) A copy of a card of a case looked at alone (another player's: shown in the chat, in
-- their showcase): as they have it, its wear on it (once appraised: its grade, in its case), its finish.
function CR:ViewCopy(w)
	local CS, CD = ns.Cases, ns.CaseDetail
	if not (w and CS and CD and CS:Known(w.c)) then
		return
	end
	local desc = CD.DescOf(w)
	self:Alone(w.c)
	self.viewing = true
	local pick = CD.PickOf(desc, w)
	self:ViewHold(pick)
	self:ViewWords(pick)
	local ins = self.frame.inspect
	local E = ns.Expertise
	-- (31 October, his word: never its condition in words, it shows on the card)
	local text = (w.ap and E and tonumber(w.g)) and string.format(L["Appraised: %s"], E.Label(tonumber(w.g))) or nil
	if w.f and self.FINISH_NAME[w.f] then
		text = text and (L[self.FINISH_NAME[w.f]] .. "  ·  " .. text) or L[self.FINISH_NAME[w.f]]
	end
	-- (1 November, his word: titanforged, certified by a master of the mages: its family and its number; its certificate a
	-- click away, Mages.lua, UI/Mages.lua)
	local MG = ns.Mages
	local tag = MG and MG.Tag(w, true)
	if tag then
		text = (text and (text .. "  ·  ") or "") .. tag
	end
	ins.extra:SetText(text or "")
	ins.extra:SetTextColor(0.92, 0.92, 0.94)
	self:PaintCertButton(ins, tag and w or nil)
	if w.ap and tonumber(w.g) and ins.card.SetSlab then
		ins.card:SetSlab(CD.Label(desc, w))
	end
end

-- (1 November) The button of the certificate of the mages of a card looked at (w: its copy, certified; nil: none).
function CR:PaintCertButton(ins, w)
	local b = ins.certBtn
	if not w then
		if b then
			b:Hide()
		end
		if ins.back then
			ins.back:ClearAllPoints()
			ins.back:SetPoint("TOP", ins.hint, "BOTTOM", 0, -12)
		end
		return
	end
	if not b then
		local S = ns.Skin
		b = S.Button(ins.words, L["See the certificate"], 200, 24)
		b:SetFrameLevel(ins.words:GetFrameLevel() + 5)
		b:SetPoint("TOP", ins.hint, "BOTTOM", 0, -12)
		CuratorOctoFull.SetScript(b, "OnClick", function(self)
			local MU = ns.MagesUI
			if MU and self.copy then
				MU:ShowCaseCertOf(self.copy)
			end
		end)
		ins.certBtn = b
	end
	b.copy = w
	b:Show()
	-- (Back under it)
	if ins.back then
		ins.back:ClearAllPoints()
		ins.back:SetPoint("TOP", b, "BOTTOM", 0, -8)
	end
end

-- (the card put down)
function CR:OnInspectClosed()
	self.ceremony = nil
end

-------------------------------------------------------------------------------
-- A card that came out of a contract
-------------------------------------------------------------------------------
-- As a card comes out of a case, in its light: no case, no band (rec: the card won, Cases.lua: CS:Contract).
function CR:RevealWon(rec)
	if not rec then
		return
	end
	local f = self:Alone(rec.c)
	self.viewing = nil
	self.contract = true
	f.title:SetText(L["Exchange contract"])
	f.title:Show()
	local fo = self:Forced(rec)
	self.forced = fo
	local pick = self:Pick(fo.tier, fo)
	pick.wear, pick.finish, pick.pt = fo.wear, fo.finish, fo.pt
	self.win = pick
	self.land = 0
	self.state = "out"
	-- (what came, in the chat too, as the card comes: CR:Told)
	self.pending, self.pendingHow = rec, "contract"
	-- (the weapon of a priceless card would make its entrance: none comes of a contract)
	if f.arm then
		ns.CrateCard.Arm(f.arm, nil)
	end
	self:Reveal()
end
