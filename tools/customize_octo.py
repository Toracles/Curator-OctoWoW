"""Apply presentation and HUD changes to the generated OctoWoW port."""

from pathlib import Path
import re


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


def apply(root: Path):
    changes = {
        "UI/BoosterBar.lua": booster_bar,
        "Core.lua": lambda text: replace(text, "barAt = true, barHide = true }",
                                         "barAt = true, barHide = true, barWidth = true }"),
        "Achievements.lua": lambda text: re.sub(
            r'Def\(\{ id = "(beta|pioneer|hardcup)",[^\n]+\n[^\n]+\n[^\n]+\}\)',
            r'Def({ id = "\1", gone = true })', text, count=3).replace(
                '{ key = "hardcup", ach = "hardcup", name = "Hardcup Survivor" },', ""),
        "UI/Album.lua": lambda text: cut(text, "-- A beta build says so", "function A:Reveal()")
            .replace("\tself:BetaMark()\n", ""),
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
