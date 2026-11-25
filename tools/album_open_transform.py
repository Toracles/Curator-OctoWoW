"""Focused transformations for responsive first album opening."""
from pathlib import Path

def album_open(text):
    def change(old, new):
        nonlocal text
        if old not in text:
            raise ValueError("Missing album opening anchor: " + old[:80])
        text = text.replace(old, new, 1)
    change("function A:Build()\n", "function A:Build()\n\tif self.buildJob and not self.buildRunning then self:FinishBuild(); return end\n")
    change("\t\tf.slots[i] = c\n", "\t\tf.slots[i] = c\n\t\tself:BuildStep()\n")
    change("\t\ttoc.rows[i] = t\n", "\t\ttoc.rows[i] = t\n\t\tself:BuildStep()\n")
    change("\tself:BuildContents()\n\tself:BuildDetail()", "\tself:BuildStep()\n\tself:BuildContents()\n\tself:BuildStep()\n\tself:BuildDetail()\n\tself:BuildStep()")
    # Leave the list container and waiting notice available; defer seven unused cards.
    start = text.index("\tfor i = 1, ROWS_PER_PAGE do", text.index("function A:BuildGuild()"))
    end = text.index("\tlist.empty =", start)
    rows = text[start:end]
    text = text[:start] + text[end:]
    method = "function A:BuildGuildRows()\n\tlocal list = self.frame.list\n\tif list.rows[1] then return end\n" + rows + "\tself:HookBack(list)\nend\n\n"
    change("function A:BuildGuild()", method + "function A:BuildGuild()")
    change("function A:RefreshGuild()\n", "function A:RefreshGuild()\n\tself:BuildGuildRows()\n")
    text = text.replace("\tself:BuildDetail()\n\tself:BuildStep()", "\tself:BuildDetail()\n\tself:BuildStep()\n\tif self.buildRunning and self.BuildInventory then self:BuildInventory(); self:BuildStep() end", 1)
    return text + "\n" + (Path(__file__).resolve().parents[1] / "full-port/AlbumOpen.lua").read_text(encoding="utf-8")

def social_open(text):
    anchor = "\t-- the guild list: in the part on the right\n"
    if anchor not in text:
        raise ValueError("Missing social list anchor")
    return text.replace(anchor, anchor + "\tself:BuildGuildRows()\n", 1)

def minimap_open(text):
    anchor = "\t\tns.Album:Toggle()"
    if anchor not in text:
        raise ValueError("Missing minimap opening anchor")
    return text.replace(anchor, "\t\tns.Album:ToggleFromMinimap()", 1)

def inventory_open(text):
    def change(old, new):
        nonlocal text
        if old not in text:
            raise ValueError("Missing inventory anchor: " + old[:80])
        text = text.replace(old, new, 1)
    change("function IU:Keepers()", "function IU:Keepers(all)")
    change("for _, x in ipairs(CP:All()) do", "for _, x in ipairs(all or CP:All()) do")
    change("\tlocal keeper, count = self:Keepers()\n\tfor _, x in ipairs(CP:All()) do",
           "\tlocal all = CP:All()\n\tlocal keeper, count = self:Keepers(all)\n\tfor _, x in ipairs(all) do")
    change("return { lines = lines, chips = chips, gems = gems, taken = taken }",
           "return { lines = lines, chips = chips, gems = gems, taken = taken, copies = all }")
    change("\t\tlocal all = CP:All()\n\t\tlocal graded = 0", "\t\tlocal all = sv.copies\n\t\tlocal graded = 0")
    change("\t\tpage.cells[i] = NewCell(page, i, x0)\n", "\t\tpage.cells[i] = NewCell(page, i, x0)\n\t\tself:BuildStep()\n")
    change("\tpage.lens = NewLens(page)", "\tpage.lens = NewLens(page)\n\tself:BuildStep()")
    return text
