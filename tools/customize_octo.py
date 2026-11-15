"""Apply presentation and HUD changes to the generated OctoWoW port."""

from pathlib import Path
import re

FULL_PORT = Path(__file__).resolve().parents[1] / "full-port"


def replace(text, old, new):
    if old not in text:
        raise ValueError(f"Missing source anchor: {old[:100]!r}")
    return text.replace(old, new, 1)


def cut(text, start, end):
    left = text.index(start)
    return text[:left] + text[text.index(end, left + len(start)):]


def booster_bar(text):
    text = replace(text, "0.6, 1.3, 0.05", "0.4, 1.3, 0.05")
    text = replace(text, "local MIN_W, MAX_W, FREE_W = 300", "local MIN_W, MAX_W, FREE_W = 120")
    text = replace(text, "function BB:SetWidth(w)", """-- The custom width stays independent of the position and of the height scale.
function BB:DisplayWidth()
    local b = self.frame
    local scale = self:Scale()
    return math.floor((b and b.bar.w or FREE_W) * scale + 0.5)
end

function BB:SetCustomWidth(width)
    if not ns.db or type(width) ~= "number" then return end
    ns.db.barWidth = math.floor(math.max(MIN_W, math.min(MAX_W, width)) + 0.5)
    self:Place()
    self:Paint()
end

function BB:SetWidth(w)""")
    text = replace(text, "w = math.max(20, math.floor((tonumber(w) or FREE_W) + 0.5))",
                   "local custom = ns.db and tonumber(ns.db.barWidth)\n\tif custom then w = custom / self:Scale() end\n\tw = math.max(20, math.floor((tonumber(w) or FREE_W) + 0.5))")
    text = replace(text, 'b:RegisterForDrag("LeftButton")', '''b:RegisterForDrag("LeftButton")
    b:EnableMouseWheel(true)
    CuratorOctoFull.SetScript(b, "OnMouseWheel", function(_, delta)
        if not delta or delta == 0 then return end
        if IsControlKeyDown and IsControlKeyDown() then
            BB:SetScale(BB:Scale() + (delta > 0 and BB.SCALE_STEP or -BB.SCALE_STEP))
        else
            BB:SetCustomWidth(BB:DisplayWidth() + (delta > 0 and 30 or -30))
        end
    end)''')
    text = replace(text, 'GameTooltip:Show()\n\tend)\n\tCuratorOctoFull.SetScript(b, "OnLeave"',
                   '''GameTooltip:AddLine(ns.locale == "frFR"
            and "Molette : largeur. Ctrl + molette : échelle."
            or "Mouse wheel: width. Ctrl + wheel: scale.", 1, .84, .48, true)
        GameTooltip:Show()
    end)
    CuratorOctoFull.SetScript(b, "OnLeave"''')
    return replace(text, 'if arg == "reset" then\n\t\tdb.barAt, db.barHide = nil, nil', '''local _, _, amount = string.find(arg, "^width%s+(%d+)$")
    if amount then
        self:SetCustomWidth(tonumber(amount))
        ns.Print((ns.locale == "frFR" and "Largeur de la barre : " or "Booster bar width: ") .. db.barWidth)
        return
    elseif arg == "reset" then
        db.barAt, db.barHide, db.barWidth, db.barScale = nil, nil, nil, nil''')


def booster_test_button(text):
    text = replace(text, "\t-- (the pack opens one too)", '''    ft.test = S.Button(ft, ns.locale == "frFR" and "Tester" or "Test", 80, 22)
    ft.test:SetPoint("TOPLEFT", 12, -36)
    CuratorOctoFull.SetScript(ft.test, "OnClick", function()
        local series = ft.series
        if not series or series.limited then return end
        local booster = ns.Booster
        if booster:Showing() and booster.state ~= "done" then return end
        ns.Play(ns.SND.click)
        GameTooltip:Hide()
        A:Hide()
        ns.OpenBooster({ series = series, test = true, from = "boosters" })
    end)
    CuratorOctoFull.SetScript(ft.test, "OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Test booster"])
        GameTooltip:AddLine(ns.locale == "frFR"
            and "Essaie l’ouverture sans dépenser de booster ni gagner de cartes."
            or "Preview the opening without using a booster or adding cards.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    CuratorOctoFull.SetScript(ft.test, "OnLeave", function() GameTooltip:Hide() end)
\t-- (the pack opens one too)''')
    return replace(text, "\tft.series = s\n", '''\tft.series = s
    CuratorOctoFull.SetShown(ft.test, s and not s.limited)
''')


def booster_preview(text):
    text = replace(text, "function B:Again()\n", '''function B:Again()
    if self.opts and self.opts.test then return end
''')
    return replace(text, '\t\ts.again:Show()\n\t\ts.again:SetAlpha(left > 0 and 1 or 0.45)',
                   '\t\tCuratorOctoFull.SetShown(s.again, not self.opts.test)\n\t\ts.again:SetAlpha(left > 0 and 1 or 0.45)')


def inns_panel(text):
    text = replace(text, 'local function Day(t)\n\tif not t then',
                   'local function Day(t)\n\tif not CuratorOctoFull.IsCalendarTime(t) then')
    text = replace(text, 'local function DayLong(t)\n\tif not t then\n\t\treturn ""',
                   'local function DayLong(t)\n\tif not CuratorOctoFull.IsCalendarTime(t) then\n\t\treturn "—"')
    text = replace(text, '''\tif g and g.IsShown and g:IsShown() then
\t\tf:SetPoint("TOPLEFT", g, "TOPRIGHT", 14, 0)
\telseif fb and fb.IsShown and fb:IsShown() then
\t\tf:SetPoint("TOPLEFT", fb, "TOPRIGHT", 14, 0)''', '''\tif fb and fb:IsShown() then
\t\tf:SetPoint("TOPLEFT", fb, "TOPRIGHT", 14, 0)
\telseif g and g.IsShown and g:IsShown() then
\t\tf:SetPoint("TOPLEFT", g, "TOPRIGHT", 14, 0)''')
    return replace(text, 'if G and G.open and G.npc == npc then\n\t\t\tUI:Open(npc, false, true)',
                   'if G and G.open and G.npc == npc and not (ns.TavernUI and ns.TavernUI:IsBetOpen()) then\n\t\t\tUI:Open(npc, false, true)')


def inns_clock(text):
    text = replace(text, 'function I:StampedToday()\n\tlocal s = self:State()\n\treturn s ~= nil and s.day == self:Today()\nend',
                   '''function I:StampedToday(today)
    local s = self:State()
    if not s then return false end
    today = today or self:Today()
    -- Keep the previous stamp locked through the first valid reset after an invalid clock.
    if ns.Quests and ns.Quests.ResetPeriod and type(s.day) == "number" and s.day > 0
        and ns.IsCalendarTime(today * 600) and not ns.IsCalendarTime(s.day * 600) then
        s.day = today
    end
    return s.day == today
end''')
    return replace(text, '\tlocal today = self:Today()\n\tif s.day == today then',
                   '\tlocal today = self:Today()\n\tif self:StampedToday(today) then')


def tavern_bet_modal(text):
    text = replace(text, 'function UI:OpenBet(npc)', '''function UI:IsBetOpen()
    return self.frame and self.frame:IsShown()
end

function UI:OpenBet(npc)''')
    text = replace(text, '\tf:Show()\n\tns.Play(ns.SND.open)\nend\n\nfunction UI:ShowChoose(npc)', '''    local counter = ns.InnsUI and ns.InnsUI.panel
    if counter and counter:IsShown() then
        f.returnCounter = counter
        counter:Hide()
    end
    f:Show()
    if ns.Gossip then ns.Gossip:Fallback() end
    ns.Play(ns.SND.open)
end

function UI:ShowChoose(npc)''')
    return replace(text, '''\t\tif UI.state == "flip" or UI.state == "dealing" then
\t\t\tUI.state = "done"
\t\tend''', '''\t\tif UI.state == "flip" or UI.state == "dealing" then
\t\t\tUI.state = "done"
\t\tend
        local counter = f.returnCounter
        f.returnCounter = nil
        local gossip = ns.Gossip
        if gossip and gossip.open then
            if counter and gossip.npc == counter.npc then counter:Show() end
            gossip:Fallback()
        end''')


def gossip_panel(text):
    legacy = (Path(__file__).resolve().parents[1] / "full-port" / "LegacyGossip.lua").read_text(encoding="utf8")
    text = replace(text, '\tlocal f = rawget(_G, "GossipFrame")\n\tif f and f.IsShown and f:IsShown() and self.hooked',
                   '\tlocal f = rawget(_G, "GossipFrame")\n'
                   '\tif self.legacyHooked and f and f:IsVisible() then\n\t\tGossipFrameUpdate()\n\t\treturn\n\tend\n'
                   '\tif f and f.IsShown and f:IsShown() and self.hooked')
    text = replace(text, 'function G:Hook()\n', legacy + '\nfunction G:Hook()\n')
    text = replace(text, 'and GOSSIP_BUTTON_TYPE_OPTION and GOSSIP_BUTTON_TYPE_DIVIDER and GOSSIP_BUTTON_TYPE_TITLE) then\n\t\treturn false',
                   'and GOSSIP_BUTTON_TYPE_OPTION and GOSSIP_BUTTON_TYPE_DIVIDER and GOSSIP_BUTTON_TYPE_TITLE) then\n\t\treturn self:HookLegacy()')
    text = replace(text, 'function G:Close()\n', 'function G:Close()\n\tself:HideLegacyRows()\n')
    text = replace(text, 'local shown = f and f.IsShown and f:IsShown() and self.hooked',
                   'local shown = f and f.IsVisible and f:IsVisible() and (self.hooked or (self.legacyShown and not self:Other()))')
    text = replace(text, 'function G:Fallback()\n', '''local function PlaceInnCounter(gossip)
    local inns = ns.InnsUI
    local counter = inns and inns.panel
    if gossip.role == "inn" and counter and counter:IsShown() and counter.npc == gossip.npc then
        inns.Place(counter)
    end
end

function G:Fallback()
    if ns.TavernUI and ns.TavernUI:IsBetOpen() then
        if self.panel then self.panel:Hide() end
        return
    end
''')
    text = replace(text, '\t\tif self.panel then\n\t\t\tself.panel:Hide()\n\t\tend\n\t\treturn\n\tend\n\tlocal p = self.panel',
                   '\t\tif self.panel and self.panel:IsShown() then\n\t\t\tself.panel:Hide()\n'
                   '\t\t\tPlaceInnCounter(self)\n\t\tend\n\t\treturn\n\tend\n\tlocal p = self.panel')
    text = replace(text, '\t\t\t\tbgFile = "Interface\\\\DialogFrame\\\\UI-DialogBox-Background-Dark",\n', '')
    text = replace(text, '\t\tp.title = p:CreateFontString(nil, "OVERLAY")', '''\t\tlocal background = p:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("TOPLEFT", p, "TOPLEFT", 6, -6)
        background:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -6, 6)
        CuratorOctoFull.ColorTexture(background, 0.025, 0.027, 0.035, 1)
\t\tp.title = p:CreateFontString(nil, "OVERLAY")''')
    return replace(text, '\tp:Show()\n\tp:Raise()\n', '''\tp:Show()
\tp:Raise()
    PlaceInnCounter(self)
''')


def crate_art_layers(text):
    text = replace(text, 't.art = t:CreateTexture(nil, "BACKGROUND", nil, 1)',
                   't.art = t:CreateTexture(nil, "BORDER")')
    text = replace(text, '\tlocal secret = pick.secret and true or false\n\tt.blind:Hide()',
                   '\tlocal secret = pick.secret and true or false\n\tt.light:SetDrawLayer("BORDER")\n\tt.blind:Hide()')
    return replace(text, '\t\tif art then\n\t\t\tt.art:SetTexture(art)', '''\t\tif art then
            -- The 1.12 client can draw equal-layer textures in either order.
            t.light:SetDrawLayer("ARTWORK")
\t\t\tt.art:SetTexture(art)''')


def opaque_dialog(text, anchor, frame="f", inset=6):
    text = replace(text, '\t\t\tbgFile = "Interface\\\\DialogFrame\\\\UI-DialogBox-Background-Dark",\n', '')
    return replace(text, anchor, f"\tS.OpaqueBackground({frame}, {inset})\n" + anchor)


def skin_backgrounds(text):
    window_comment = "-- A window of the game:"
    text = replace(text, window_comment, r'''function S.OpaqueBackground(frame, inset)
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\Buttons\\WHITE8X8")
	bg:SetVertexColor(0.025, 0.027, 0.035, 1)
	bg:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
	bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
	return bg
end

''' + window_comment)
    text = replace(text, '\t\tlocal title = S.Text(f, "GameFontNormal")',
                   '\t\tS.OpaqueBackground(f, 11)\n\t\tlocal title = S.Text(f, "GameFontNormal")')
    for frame in ("bg", "f"):
        text = replace(text, r'			bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",' + "\n", "")
        anchor = f"\tend\n\t{frame}:ClearAllPoints()"
        text = replace(text, anchor, f"\t\tS.OpaqueBackground({frame}, 3)\n" + anchor)
    return text


def ruby_ledger(text):
    text = opaque_dialog(text, '\tf.gem = f:CreateTexture(nil, "ARTWORK")')
    return replace(text, '''\t\t\tlocal ago = math.max(0, now - (tonumber(e.t) or now))
\t\t\tr.when:SetText(ago < 60 and L["now"] or string.format(L["%s ago"], ns.Duration(ago)))''', '''\t\t\tlocal timestamp = tonumber(e.t)
            local ago = CuratorOctoFull.IsCalendarTime(timestamp) and math.max(0, now - timestamp)
            r.when:SetText(ago and (ago < 60 and L["now"] or string.format(L["%s ago"], ns.Duration(ago))) or "—")''')


def loot_toast(text):
    text = replace(text, r'''	l.bg = l:CreateTexture(nil, "BACKGROUND")
	l.bg:SetTexture("Interface\\LootFrame\\LootToast")
	l.bg:SetTexCoord(0.28222656, 0.55175781, 0.578125, 0.953125)
	CuratorOctoFull.SetSize(l.bg, LOOT_W, LOOT_H)
	l.bg:SetPoint("CENTER")''', r'''	l:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 })
	l.bg = S.OpaqueBackground(l, 5)''')
    text = replace(text, r'''	l.shine:SetTexture("Interface\\LootFrame\\LootToast")
	l.shine:SetTexCoord(0.56347656, 0.73046875, 0.57421875, 0.8671875)''',
                   '\tl.shine:SetTexture(MEDIA .. "Sheen")')
    text = replace(text, r'''	a.bg = a:CreateTexture(nil, "BACKGROUND")
	if not S.Atlas(a.bg, "ui-achievement-alert-background", true) then
		a.bg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
		a.bg:SetTexCoord(0, 0.605, 0, 0.703)
		CuratorOctoFull.SetSize(a.bg, ACH_W, ACH_H)
	end
	a.bg:SetPoint("CENTER")''', r'''	a:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 })
	a.bg = S.OpaqueBackground(a, 5)''')
    return replace(text, "\ta.unlocked:SetTextColor(0, 0, 0)", "\ta.unlocked:SetTextColor(1, 0.82, 0.4)")


def live_alerts(text):
    text = replace(text, r'''	f.bg = f:CreateTexture(nil, "BACKGROUND")
	f.bg:SetTexture("Interface\\LootFrame\\LootToast")
	f.bg:SetTexCoord(0.28222656, 0.55175781, 0.578125, 0.953125)
	CuratorOctoFull.SetSize(f.bg, W, H)
	f.bg:SetPoint("CENTER")''', r'''	f:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 })
	f.bg = S.OpaqueBackground(f, 5)''')
    return opaque_dialog(text, '\tb.text = b:CreateFontString(nil, "OVERLAY")', "b", 3)


def album_header(text):
    for old, new in (
        ("local HEAD = 72", "local HEAD = 86"),
        ("local BAR_W = 230", "local BAR_W = 230\nlocal HEADER_Y, PROGRESS_Y, SUB_Y = -19, -50, -68"),
        ("\tBAR_W = BAR_W, CW = CW, CH = CH,", "\tBAR_W = BAR_W, CW = CW, CH = CH,\n"
         "\tHEADER_Y = HEADER_Y, PROGRESS_Y = PROGRESS_Y, SUB_Y = SUB_Y,"),
        ('\tf.drag = S.DragBar(f, 22)', '''\tf.drag = S.DragBar(f, 34)
	f.CloseButton:ClearAllPoints()
	CuratorOctoFull.SetSize(f.CloseButton, 24, 24)
	f.CloseButton:SetPoint("RIGHT", f, "TOPRIGHT", -14, HEADER_Y)
	f.TitleText:ClearAllPoints()
	f.TitleText:SetPoint("CENTER", f, "TOP", 0, HEADER_Y)
	CuratorOctoFull.SetSize(f.TitleText, WIDTH - 400, 18)
	CuratorOctoFull.SetWordWrap(f.TitleText, false)
	local divider = S.Divider(f, WIDTH - 30, 0.38)
	divider:SetPoint("TOP", f, "TOP", 0, -34)'''),
        ('f.sPrev:SetPoint("TOPLEFT", 60, -25)', 'f.sPrev:SetPoint("LEFT", f, "TOPLEFT", 60, PROGRESS_Y)'),
        ('f.sub:SetPoint("TOPLEFT", 64, -55)', 'f.sub:SetPoint("TOPLEFT", 64, SUB_Y)'),
        ('bar:SetPoint("RIGHT", f, "TOPRIGHT", -16, -37)', 'bar:SetPoint("RIGHT", f, "TOPRIGHT", -16, PROGRESS_Y)'),
        ('f.goldBar:SetPoint("RIGHT", f, "TOPRIGHT", -16, -37)',
         'f.goldBar:SetPoint("RIGHT", f, "TOPRIGHT", -16, PROGRESS_Y)'),
        ('b:SetPoint("RIGHT", f, "TOPRIGHT", -16, -61)', 'b:SetPoint("RIGHT", f, "TOPRIGHT", -16, SUB_Y - 2)'),
        ('f.finRule:SetPoint("RIGHT", f, "TOPRIGHT", -16, -61)',
         'f.finRule:SetPoint("RIGHT", f, "TOPRIGHT", -16, SUB_Y - 2)'),
        ('\tf:SetTitle(title)', '\tf:SetTitle(title)\n\tS.Fit(f.TitleText, title, WIDTH - 400, 13, 9)'),
    ):
        text = replace(text, old, new)
    return text


def progress_header(text, emblem, bar, note):
    for old, new in (
        ("local TITLE_X, TITLE_ROOM = 130, 388", "local TITLE_X, TITLE_ROOM = 98, 388"),
        (f'{emblem}:SetPoint("CENTER", f, "TOPLEFT", 94, -44)',
         f'{emblem}:SetPoint("CENTER", f, "TOPLEFT", 65, U.PROGRESS_Y - 8)'),
        (f'{bar}:SetPoint("RIGHT", f, "TOPRIGHT", -16, -36)',
         f'{bar}:SetPoint("RIGHT", f, "TOPRIGHT", -20, U.PROGRESS_Y)'),
        (f'{note}:SetPoint("TOPRIGHT", {bar}, "BOTTOMRIGHT", 0, -7)',
         f'{note}:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, U.SUB_Y)'),
        ('f.title:SetPoint("LEFT", f, "TOPLEFT", TITLE_X, -38)',
         'f.title:SetPoint("LEFT", f, "TOPLEFT", TITLE_X, self.U.PROGRESS_Y)'),
        ('f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_X + 1, -55)',
         'f.sub:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_X + 1, self.U.SUB_Y)'),
    ):
        text = replace(text, old, new)
    return text


def achievement_header(text):
    text = progress_header(text, "f.aMedal", "f.aBar", "f.aNote")
    text = replace(text, "SetSize(f.aMedal, 60, 60)", "SetSize(f.aMedal, 46, 46)")
    text = replace(text, "SetSize(f.aMedal.gem, 30, 30)", "SetSize(f.aMedal.gem, 23, 23)")
    text = cut(text, '\tlocal sub = "|cff" .. Hex(col) .. title', '\tf.title:ClearAllPoints()')
    text = replace(text, '\tlocal col = AC:RankColour(rank)\n\tf.title:ClearAllPoints()',
        '\tlocal col = AC:RankColour(rank)\n'
        '\tself:SetTitle(string.format(L["%d points"], points), "|cff" .. Hex(col) .. title .. "|r")\n'
        '\tf.title:ClearAllPoints()')
    return replace(text, 'r.when:SetPoint("TOPRIGHT", r.claimed, "BOTTOMRIGHT", 0, -3)',
                   'r.when:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -16, 8)')


def guide_button(text):
    text = cut(text, '\tlocal b = CreateFrame("Button", nil, f)', '\tCuratorOctoFull.SetScript(b, "OnClick"')
    text = replace(text, '\tCuratorOctoFull.SetScript(b, "OnClick"', r'''	local b = S.Button(f, "", 88, 24)
	b:SetPoint("LEFT", f, "TOPLEFT", 16, ns.Album.U.HEADER_Y)
	b:SetFrameLevel(f:GetFrameLevel() + 500)
	b.i = b:CreateTexture(nil, "ARTWORK")
	b.i:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	b.i:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	CuratorOctoFull.SetSize(b.i, 16, 16)
	b.i:SetPoint("LEFT", 8, 0)
	b.caption = S.Text(b, "GameFontNormalSmall", "LEFT")
	b.caption:SetPoint("LEFT", b.i, "RIGHT", 6, 0)
	b.caption:SetText("Guide")
	CuratorOctoFull.SetScript(b, "OnClick"''')
    return replace(text, 'frame = self.button, inset = 12, rect = { 40, 0, 104, -40 }',
                   'frame = self.button, rect = { 16, -7, 104, -31 }')


def header_icon_button(text, button):
    text = replace(text, f"SetSize({button}, 18, 18)", f"SetSize({button}, 22, 22)")
    indent = "\t\t\t" if button == "g" else "\t"
    return replace(text, f"{button}.icon:SetAllPoints()",
                   f"CuratorOctoFull.SetSize({button}.icon, 16, 16)\n{indent}{button}.icon:SetPoint(\"CENTER\")")


SAVE_TEXT = {
    "Log out to the character selection screen to save your collection.": "Déconnecte-toi jusqu’à l’écran de sélection des personnages pour sauvegarder ta collection.",
    "If the game crashes, progress since your last save may be lost.": "Si le jeu plante, les progrès depuis ta dernière sauvegarde peuvent être perdus.",
    "Save once the fight is over.": "Sauvegarde une fois le combat terminé.",
    "Save once the cards have been revealed.": "Sauvegarde une fois les cartes révélées.",
    "Save your collection and return to the character selection screen?": "Sauvegarder ta collection et revenir à l’écran de sélection des personnages ?",
    "Save and log out": "Sauvegarder et se déconnecter",
    "Use /logout to return to the character selection screen and save your collection.": "Utilise /logout pour revenir à l’écran de sélection des personnages et sauvegarder ta collection.",
    "Click to save and log out.": "Clique pour sauvegarder et te déconnecter.",
    "/curator save: save your collection by logging out": "/curator save : sauvegarde ta collection en te déconnectant",
    "Log out to save your side of the trade.": "Déconnecte-toi pour sauvegarder ta part de l’échange.",
}


def save_locale(text):
    entries = "".join(f'\t["{key}"] = "{value}",\n' for key, value in SAVE_TEXT.items())
    return text.rstrip() + '\n\nAdd("frFR", {\n' + entries + '})\n'


def native_save(text):
    text = header_icon_button(text, "b")
    text = text.replace("InCombatLockdown and InCombatLockdown()", "Fighting()")
    text = cut(text, "-- The interface reloads: the game writes the save.", "-- A save now, or why not")
    text = replace(text, "local function Now()", '''local function Fighting()
	if InCombatLockdown and InCombatLockdown() then
		return true
	end
	local combat = UnitAffectingCombat and UnitAffectingCombat("player")
	return combat == true or combat == 1
end

local function Now()''')
    start = "-- The save asked for where no macro of the game reloads"
    end = "-------------------------------------------------------------------------------\n-- The key: the reload by a macro of the game"
    text = cut(text, start, end)
    text = replace(text, end, '''local SAVE_LOGOUT = "CURATOR_SAVE_LOGOUT"
local LOGOUT_FALLBACK = "Use /logout to return to the character selection screen and save your collection."

function SV:ConfirmLogout()
	if not self:Can(true) then
		return false
	end
	if type(Logout) ~= "function" then
		ns.Print(L[LOGOUT_FALLBACK])
		return false
	end
	self.saveOnLogout = true
	local ok, result = pcall(Logout)
	if not ok or result == false then
		self.saveOnLogout = nil
		ns.Print(L[LOGOUT_FALLBACK])
		return false
	end
	return true
end

function SV:Now()
	if not self:Can(true) then
		return false
	end
	if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
		ns.Print(L[LOGOUT_FALLBACK])
		return false
	end
	StaticPopupDialogs[SAVE_LOGOUT] = {
		text = L["Save your collection and return to the character selection screen?"],
		button1 = L["Save and log out"],
		button2 = L["Cancel"],
		OnAccept = function() SV:ConfirmLogout() end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	StaticPopup_Show(SAVE_LOGOUT)
	return true
end

ns.On("LOGOUT", function()
	if SV.saveOnLogout and ns.db then
		SV.saveOnLogout = nil
		SV:Note()
	end
end)

''' + end)
    text = replace(text, "\topts = opts or {}\n\tif not (Calm()", '''\topts = opts or {}
	-- Only the language prompt uses the reload macro.
	if opts.save ~= false then return false end
	if not (Calm()''')
    for old, new in (
        ("The interface reloads, and the game writes your collection to its files (a few seconds).",
         "Log out to the character selection screen to save your collection."),
        ("The game writes it only then, or when you log out: if the game closes on its own, what came since is lost.",
         "If the game crashes, progress since your last save may be lost."),
        ("Not during a fight: saving reloads the interface. Save once the fight is over.", "Save once the fight is over."),
        ("Once the cards are turned over: saving reloads the interface.", "Save once the cards have been revealed."),
        ("Click: save it now (the interface reloads).", "Click to save and log out."),
        ("Not in safety yet. Click: save it (the interface reloads).", "Click to save and log out."),
    ):
        text = replace(text, f'L["{old}"]', f'L["{new}"]')
    return text


def append_port(text, name):
    return text.rstrip() + "\n\n" + (FULL_PORT / name).read_text(encoding="utf8")


def octo_gifts(text):
    text = replace(text, 'if head ~= self.PREFIX then', 'if head ~= self.PREFIX and head ~= "CG2" then')
    text = replace(text, 'local key = self.key or ns.FEED_KEY\n\tif type(key)',
                   'local key\n\tif head == "CG2" then\n\t\tkey = ns.OCTO_GIFT_KEY\n\telse\n\t\tkey = self.key or ns.FEED_KEY\n\tend\n\tif type(key)')
    return replace(text,
        'ipairs({ GetNormalizedRealmName and GetNormalizedRealmName(), GetRealmName and GetRealmName(), surname })',
        'ipairs({ (GetNormalizedRealmName and GetNormalizedRealmName()) or false, (GetRealmName and GetRealmName()) or false, surname or false })')


def players_ui(text):
    text = cut(text, "-- The line of the tooltip:", "-- Opening a collection")
    text = cut(text, 'local MYTHIC_ICON =', '-- "Name-Realm" of a unit')
    text = cut(text, "-- The other players:", "local P = {}")
    return append_port(text, "PortraitTrade.lua")


def quest_catch_up(text):
    anchor = "-- Something done (kind: what a quest counts)"
    return replace(text, anchor, '''-- Active Curator objectives a batch of historical quest turn-ins can complete.
function Q:CatchUpQuestCount(n)
	if n <= 0 then return 0 end
	self:Check()
	local count = 0
	for _, board in ipairs(BOARDS) do
		local entry = ns.db.quests[board.key]
		for _, q in ipairs((entry and entry.list) or {}) do
			if Counts(q, "quest") and (q.got or 0) + n >= q.n then
				count = count + 1
			end
		end
	end
	return count
end

''' + anchor)


def trade_protocol(text):
    text = replace(text, 'local OPS = { P = "OnOffer",', 'local OPS = { L = "OnLive", P = "OnOffer",')
    text = replace(text, 'return table.concat({ "P", rec.id, rec.rev, ns.db.uid,',
                   'local body = table.concat({ "P", rec.id, rec.rev, ns.db.uid,')
    text = replace(text, 'rec.tag or "", rec.duel or "" }, "/")\nend',
                   'rec.tag or "", rec.duel or "" }, "/")\n\treturn rec.live and (body .. "/" .. rec.live) or body\nend')
    text = replace(text, '\trec.tag = self:Tag()', '\trec.tag = self:Tag()\n'
                   '\trec.live = ns.LiveTrade.ValidToken(draft.live) and draft.live or nil')
    text = replace(text, '\tdb.trades[id] = rec\n\tself:Changed(rec)\n\t-- (1.12.0: the duel',
                   '\trec.live = ns.LiveTrade.ValidToken(f[10]) and f[10] or nil\n'
                   '\tdb.trades[id] = rec\n\tself:Changed(rec)\n\t-- (1.12.0: the duel')
    return append_port(text, "LiveTrade.lua")


def trade_live_ui(text):
    text = replace(text,
        'string.format(L["Reloads your interface: your game saves the trade, and what %s received from you is free on their side at once."], who)',
        'L["Log out to save your side of the trade."]')
    for old, new in (
        ('function A:CloseTrade()\n\tlocal e = self.ed',
         'function A:CloseTrade()\n\tlocal e = self.ed\n'
         '\tif e and e.live then ns.LiveTrade:Close(e.live, "closed", true) end'),
        ('function A:RefreshTradeEditor()\n', 'function A:RefreshTradeEditor()\n'
         '\tif self.ed and self.ed.live then return ns.LiveTradeUI:Paint(self.ed) end\n'),
        ('function A:TradeMain()\n', 'function A:TradeMain()\n'
         '\tif self.ed and self.ed.live then return ns.LiveTradeUI:Submit(self.ed.live) end\n'),
        ('function A:TradeAlt(action)\n', 'function A:TradeAlt(action)\n'
         '\tif action == "liveClassic" and self.ed and self.ed.live then\n'
         '\t\treturn ns.LiveTradeUI:Classic(self.ed.live)\n\tend\n'),
        ('function A:TradePickable()\n\tlocal e = self.ed', 'function A:TradePickable()\n\tlocal e = self.ed\n'
         '\tif e and e.live and e.live.state ~= "open" then return false end'),
    ):
        text = replace(text, old, new)
    return append_port(text, "LiveTradeUI.lua")


def friendly_prices(root):
    changes = {
        "Rubies.lua": [
            ("function RB:Price(base, what)", """function RB.LocalPrice(base, what)
    base = tonumber(base) or 0
    local divisor = what == "key" and 4 or 2
    if base <= 0 then return 0 end
    return math.max(1, math.floor(base / divisor + 0.5))
end

function RB:Price(base, what)"""),
            ("return math.max(1, math.floor(base * (1 - k) + 0.5))", "return RB.LocalPrice(base * (1 - k), what)"),
        ],
        "Reseller.lua": [
            ('RV.CASE_ITEM = 30', 'RV.CASE_ITEM = 15'),
            ('RV.KEY_ITEM = 250', 'RV.KEY_ITEM = 63'),
            ('return math.floor(base + 1e-6)\nend\n\n-- (1.13.0, after its second test)',
             'return ns.Rubies.LocalPrice(base)\nend\n\n-- (1.13.0, after its second test)'),
            ('return math.floor(base + 1e-6)\nend\n\nfunction RV:CaseHeld',
             'return ns.Rubies.LocalPrice(base)\nend\n\nfunction RV:CaseHeld'),
            ('function RV:BuyBack(i)', '''function RV:BuyBackPrice(x)
    -- New pawn receipts already contain the revised price.
    return x.octoPrice and x.p or ns.Rubies.LocalPrice(x.p)
end

function RV:BuyBack(i)'''),
            ('{ k = card.key, f = (finish ~= "normal" and finish) or nil, p =',
             '{ k = card.key, f = (finish ~= "normal" and finish) or nil, octoPrice = true, p ='),
            ('ns.Rubies:Spend(x.p, "resell")', 'ns.Rubies:Spend(self:BuyBackPrice(x), "resell")'),
            ('return math.max(1, math.floor(base))\nend\n\nfunction RV:CanBaron',
             'return ns.Rubies.LocalPrice(base)\nend\n\nfunction RV:CanBaron'),
        ],
        "UI/Reseller.lua": [
            ("RB.Text(x.p, 11)", "RB.Text(RV:BuyBackPrice(x), 11)"),
            ("RB.Text(x.p, 13)", "RB.Text(RV:BuyBackPrice(x), 13)"),
            ("RB:Has(x.p)", "RB:Has(RV:BuyBackPrice(x))"),
        ],
        "Talents.lua": [
            ('return card, tonumber(bm.p) or 0', 'return card, ns.Rubies.LocalPrice(tonumber(bm.p) or 0)'),
            ('return card and RV and RV.PRICE[card.rarity] or 0',
             'return ns.Rubies.LocalPrice(card and RV and RV.PRICE[card.rarity] or 0)'),
        ],
        "Rates.lua": [("key = CS.KEY_PRICE,", "key = CS:KeyPrice(),")],
        "UI/Restore.lua": [
            ('math.floor((tonumber(x) or 0) * (k or 1) / 5 + 0.5) * 5',
             'math.floor((tonumber(x) or 0) * (k or 1) + 0.5)'),
            ('RB.Text(math.floor((q.all or 0) * k / 5 + 0.5) * 5, 12)', 'RB.Text(RB:Price(q.all, "restore"), 12)'),
            ('RB.Text(math.floor((f.price or 0) * (st.k or 1) / 5 + 0.5) * 5, 13)',
             'RB.Text(math.floor((f.price or 0) * (st.k or 1) + 0.5), 13)'),
        ],
    }
    for name, edits in changes.items():
        path = root / name
        text = path.read_text(encoding="utf8")
        for old, new in edits:
            text = replace(text, old, new)
        path.write_bytes(text.encode("utf8"))


def apply(root: Path):
    changes = {
        "UI/BoosterBar.lua": booster_bar,
        "UI/Boosters.lua": booster_test_button,
        "UI/Booster.lua": booster_preview,
        "Inns.lua": inns_clock,
        "UI/Inns.lua": inns_panel,
        "UI/Tavern.lua": tavern_bet_modal,
        "UI/Gossip.lua": gossip_panel,
        "UI/Crate.lua": crate_art_layers,
        "UI/Rubies.lua": ruby_ledger,
        "UI/Expertise.lua": lambda text: opaque_dialog(text, '\tf.icon = f:CreateTexture(nil, "ARTWORK")'),
        "UI/Displays.lua": lambda text: opaque_dialog(text, '\tf.icon = f:CreateTexture(nil, "ARTWORK")'),
        "UI/Copies.lua": lambda text: opaque_dialog(text, '\tf.title = S.Text(f, "GameFontNormal", "LEFT")'),
        "UI/Restore.lua": lambda text: opaque_dialog(text, '\tf.ring = f:CreateTexture(nil, "ARTWORK")'),
        "UI/Search.lua": lambda text: opaque_dialog(text, '\ttinsert(UISpecialFrames, "CuratorSearch")', inset=4),
        "UI/Toast.lua": loot_toast,
        "UI/Live.lua": live_alerts,
        "UI/Skin.lua": skin_backgrounds,
        "Core.lua": lambda text: replace(replace(replace(text,
            "/curator save: save your collection now (the interface reloads)",
            "/curator save: save your collection by logging out"), "barAt = true, barHide = true }",
            "barAt = true, barHide = true, barWidth = true }"),
            '\telseif cmd == "boosters" or cmd == "booster"',
            '\telseif cmd == "catchup" or cmd == "rattrapage" then\n\t\tns.Rewards:OpenCatchUp(arg)\n'
            '\telseif cmd == "boosters" or cmd == "booster"'),
        "Rewards.lua": lambda text: replace(text, 'R:Add(R:WorldSeries(), POINTS.level, "level")',
                                               'R:OctoLevelUp((unpack(arg, 1, arg.n)))'),
        "Achievements.lua": lambda text: re.sub(
            r'Def\(\{ id = "(beta|pioneer|hardcup)",[^\n]+\n[^\n]+\n[^\n]+\}\)',
            r'Def({ id = "\1", gone = true })', text, count=3).replace(
                '{ key = "hardcup", ach = "hardcup", name = "Hardcup Survivor" },', ""),
        "UI/Album.lua": lambda text: cut(album_header(text), "-- A beta build says so", "function A:Reveal()")
            .replace("\tself:BetaMark()\n", ""),
        "UI/Achievements.lua": achievement_header,
        "UI/Quests.lua": lambda text: replace(
            progress_header(text, "f.qEmblem", "f.qXP", "f.qNote").replace("Hud.Emblem(f, 56)", "Hud.Emblem(f, 46)", 1),
            'f.sub:SetPoint("TOPLEFT", 64, -55)', 'f.sub:SetPoint("TOPLEFT", 64, self.U.SUB_Y)'),
        "UI/Tour.lua": guide_button,
        "UI/Options.lua": lambda text: header_icon_button(text, "g"),
        "UI/Save.lua": native_save,
        "Data/FeedKey.lua": lambda text: append_port(text, "OctoGiftKey.lua"),
        "Gifts.lua": octo_gifts,
        "Locale112.lua": save_locale,
        "Trade.lua": trade_protocol,
        "UI/Social.lua": trade_live_ui,
        "UI/Players.lua": players_ui,
        "Quests.lua": quest_catch_up,
        "UI/Minimap.lua": lambda text: cut(text, "\t\t-- (a beta build:", "\t\tlocal owned, total"),
        "UI/Site.lua": lambda text: cut(text, "-- (1.12.0, later) The end of the beta", "local W = {}")
            .replace("W.BETA_END = 1792620000\n", "").split("\n-- (1.12.0, later) The end of the beta", 1)[0] + "\n",
        "UI/Hallow.lua": lambda text: replace(text,
            'line = L["The beta of WoW Forever ends on October 21: open them while it lasts."]',
            'line = string.format(L["Boosters: %d"], ns.Packs(s))'),
        "UI/Mandatory.lua": lambda text: cut(text, "\tlocal beta = ns.Beta and ns.Beta.BETA", "\tif f:IsShown()")
            .replace('f:SetTitle(L["Mandatory update"])', '''f:SetTitle(L["Mandatory update"])
    f.body:SetText(string.format(L["This update is mandatory: your version (%s) no longer works. Update Curator, then come back: your collection is waiting for you, nothing is lost."], ns.version or "?"))''', 1),
    }
    for name, transform in changes.items():
        path = root / name
        text = path.read_text(encoding="utf8")
        path.write_bytes(transform(text).encode("utf8"))

    friendly_prices(root)

    path = root / "Beta.lua"
    text = path.read_text(encoding="utf8")
    text = cut(text, "-- The betas.", "ns.Beta = B")
    text = replace(text, "ns.Beta = B", "local B = {}\nns.Beta = B")
    text = text.replace("(self.BETA and self:Now() >= self.UNTIL) or ", "")
    text = cut(text, "function B:Left()", "-- Something asked")
    text = replace(text, "-- Something asked", "function B:VersionText() return ns.version end\n\n-- Something asked")
    text = cut(text, "\tlocal now = (GetTime and GetTime()) or 0\n\tif not self.told or", "\treturn true\nend\n\n-- (1.8.0) The pioneers")
    text = cut(text, "-- (1.8.0) The pioneers", 'ns.On("LOGIN", function()')
    text = cut(text, "\tB:MarkPioneer()", "\nend)\n\n")
    text = re.sub(r'B\.BETA and L\["[^"]+"\] or ', "", text)
    path.write_bytes(text.encode("utf8"))

    for path in root.rglob("*"):
        if path.suffix not in (".lua", ".toc"):
            continue
        raw = path.read_bytes()
        text = raw.decode("utf8")
        text = re.sub(r"World of Warcraft[ :]+Forever|WoW\s*[:：]?\s+Forever", "OctoWoW", text, flags=re.I)
        text = re.sub(r"Cl[ée]ment Hudson", "CloudNine_Ex", text, flags=re.I)
        if path.name.startswith("Locale"):
            # The removed views have no translations to load.
            text = re.sub(
                r'(?mi)^\s*\["(?:The beta of OctoWoW|Beta tester|Played the closed beta of Curator\.|Thank you for testing Curator! At the release)[^"\r\n]*"\]\s*=\s*"[^\r\n]+"[,]?\r?\n',
                "", text,
            )
        if path.name in ("Reroll.lua",):
            text = re.sub(r'^\s*ns\.Print\(L\["OctoWoW is here![^\n]+\n', "\n", text, flags=re.M)
        if path.name == "Curator.toc":
            text = text.replace("## Title: Curator\n", "## Title: Curator OctoWoW\n")
        elif path.name == "Channel.lua":
            text = text.replace(" -- CloudNine_Ex", "")
        elif path.name == "Core.lua":
            text = text.replace('L["Curator %s, by %s"]', '"Curator %s | OctoWoW: %s"')
        elif path.name == "Minimap.lua":
            text = text.replace('L["By %s"], "CloudNine_Ex"', '"OctoWoW: %s", "CloudNine_Ex"')
        elif path.name == "Skin.lua":
            text = text.replace("UI-DialogBox-Background-Dark", "UI-DialogBox-Background")
        if text != raw.decode("utf8"):
            path.write_bytes(text.encode("utf8"))
