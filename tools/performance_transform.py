"""Performance changes kept separate from generated data and transaction logic."""
from pathlib import Path
PORT = Path(__file__).resolve().parents[1] / "full-port"

def responsive_album(text):
    start = text.index('\tfor _, e in ipairs({ "CHANGED", "GUILD_CHANGED"')
    end = text.index('\t-- each creature defeated moves the gauge', start)
    events = text[start:end].replace('A:Refresh()', 'A:RequestRefresh()')
    text = text[:start] + events + text[end:]
    text = text.replace('function A:Refresh()\n', 'function A:Refresh()\n\tself:CancelRefresh()\n', 1)
    text = text.replace('function A:Hide()\n', 'function A:Hide()\n\tself:CancelRefresh()\n', 1)
    return text + "\n" + (PORT / "AlbumRefresh.lua").read_text(encoding="utf-8")

def responsive_inventory(text):
    old = "local function Dress(c, card, rec)\n\tlocal opts, info, sig = Look(card, rec)"
    new = "local function Dress(c, card, rec, opts, info, sig)\n\tif not opts then opts, info, sig = Look(card, rec) end"
    if old not in text: raise ValueError("Missing inventory dressing anchor")
    text = text.replace(old, new, 1)
    text = text.replace("\tlocal _, info = Look(card, rec)\n\tSeat(cell, info ~= nil)\n\tDress(c, card, rec)",
                        "\tlocal opts, info, sig = Look(card, rec)\n\tSeat(cell, info ~= nil)\n\tDress(c, card, rec, opts, info, sig)", 1)
    start = text.index('local function Changed()')
    text = text[:start] + text[start:].replace('A:Refresh()', 'A:RequestRefresh()', 1)
    return text + "\n" + (PORT / "InventoryCache.lua").read_text(encoding="utf-8")
