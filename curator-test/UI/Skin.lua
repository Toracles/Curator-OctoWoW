local _, ns = "Curator", CuratorOctoFull
local L = setmetatable({}, { __index = function(_, k) return ns.L[k] end })

-- The look of the game: Curator's windows, tabs, buttons, menus, bars and lists are made with the
-- templates and the art of the client itself (those of its collections, its achievements and its
-- alerts), so they take the style of the client they run in. What a client lacks is drawn with
-- older art that every client has.
local S = {}
ns.Skin = S

-- Colours of the game's texts: gold titles, white values, grey for what is off.
S.GOLD = { 1, 0.82, 0 }
S.WHITE = { 1, 1, 1 }
S.GREY = { 0.5, 0.5, 0.5 }
S.SOFT = { 0.8, 0.8, 0.8 }

-------------------------------------------------------------------------------
-- Templates and art of the client
-------------------------------------------------------------------------------
local hasTemplate = {}
function S.Has(template)
	local v = hasTemplate[template]
	if v == nil then
		v = false
		if C_XMLUtil and C_XMLUtil.GetTemplateInfo then
			local ok, info = pcall(C_XMLUtil.GetTemplateInfo, template)
			v = (ok and info ~= nil) and true or false
		end
		hasTemplate[template] = v
	end
	return v
end

-- A frame made from a template of the client, or nil when the client does not have it.
function S.Make(frameType, name, parent, template)
	if S.Has(template) then
		local ok, f = pcall(CreateFrame, frameType, name, parent, template)
		if ok and f then
			return f
		end
	end
	return nil
end

local hasAtlas = {}
function S.HasAtlas(atlas)
	local v = hasAtlas[atlas]
	if v == nil then
		v = false
		if C_Texture and C_Texture.GetAtlasInfo then
			local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
			v = (ok and info ~= nil) and true or false
		end
		hasAtlas[atlas] = v
	end
	return v
end

-- An atlas of the client on a texture; false when the client does not have it.
function S.Atlas(tex, atlas, useSize)
	if S.HasAtlas(atlas) then
		tex:SetAtlas(atlas, useSize and true or false)
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- Texts
-------------------------------------------------------------------------------
local function FontObject(object)
	local fo = type(object) == "string" and _G[object] or object
	if type(fo) ~= "table" or not fo.GetFont then
		fo = GameFontNormal
	end
	return fo
end

function S.SetFontObject(fs, object)
	fs:SetFontObject(FontObject(object))
end

-- A text in a font of the game (its size, its colour and its shadow, in the font of the client's
-- language).
function S.Text(parent, object, justify, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	fs:SetFontObject(FontObject(object))
	if justify then
		fs:SetJustifyH(justify)
	end
	return fs
end

-- The width of a text on one line, whatever the width of its font string (GetStringWidth stops
-- at that width when the font string has one).
function S.Width(fs, default)
	local w
	if fs.GetUnboundedStringWidth then
		w = fs:GetUnboundedStringWidth()
	else
		w = fs:GetStringWidth()
	end
	return w or default or 0
end
ns.TextWidth = S.Width

-- A text made smaller (from size down to minSize) until it fits the width; the client cuts what
-- is still too long.
function S.Fit(fs, text, width, size, minSize)
	ns.SetFont(fs, size)
	fs:SetText(text)
	while size > minSize and S.Width(fs) > width do
		size = size - 0.5
		ns.SetFont(fs, size)
	end
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------
-- A window of the game: the frame with a portrait, a title and a close button (the collections,
-- the character...). Its border goes over the edges of what it holds, as in the game.
function S.Window(name, width, height)
	local f = S.Make("Frame", name, UIParent, "PortraitFrameTemplate")
	if not f then
		f = CreateFrame("Frame", name, UIParent, CuratorOctoFull.BackdropTemplate())
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})
		local title = S.Text(f, "GameFontNormal")
		title:SetPoint("TOP", 0, -14)
		f.TitleText = title
		function f:SetTitle(text)
			self.TitleText:SetText(text)
		end
		function f:SetPortraitToAsset()
		end
		f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		f.CloseButton:SetPoint("TOPRIGHT", -5, -5)
	end
	CuratorOctoFull.SetSize(f, width, height)
	return f
end

-- Dragging the top of a window moves it.
function S.DragBar(f, height)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	local d = CreateFrame("Frame", nil, f)
	d:SetPoint("TOPLEFT", 56, 0)
	d:SetPoint("TOPRIGHT", -28, 0)
	d:SetHeight(height or 22)
	d:EnableMouse(true)
	d:RegisterForDrag("LeftButton")
	CuratorOctoFull.SetScript(d, "OnDragStart", function()
		f:StartMoving()
	end)
	CuratorOctoFull.SetScript(d, "OnDragStop", function()
		f:StopMovingOrSizing()
	end)
	return d
end

-- A tab on the right edge of a window, with an icon and its name in a tooltip (the tabs of the
-- collections, of the character). onClick(tab) on a left click. tab:SetChecked(on).
function S.SideTab(parent, icon, tooltip, onClick)
	local t = S.Make("Frame", nil, parent, "LargeSideTabButtonTemplate")
	if t then
		t.tooltipText = tooltip
		t.Icon:SetTexture(icon)
		if t.SetFillToInterior then
			t:SetFillToInterior(true)
		end
		t:SetCustomOnMouseUpHandler(function(_, button, upInside)
			if button == "LeftButton" and upInside then
				onClick(t)
			end
		end)
		t.gap = -2
		return t
	end
	-- the side tabs of the older spellbook
	t = CreateFrame("CheckButton", nil, parent)
	CuratorOctoFull.SetSize(t, 32, 32)
	t.bg = t:CreateTexture(nil, "BACKGROUND")
	t.bg:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
	CuratorOctoFull.SetSize(t.bg, 64, 64)
	t.bg:SetPoint("TOPLEFT", -3, 11)
	t:SetNormalTexture(icon)
	t:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	t:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
	t:GetCheckedTexture():SetBlendMode("ADD")
	CuratorOctoFull.SetScript(t, "OnClick", function(self)
		self:SetChecked(not self:GetChecked())
		onClick(self)
	end)
	CuratorOctoFull.SetScript(t, "OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(tooltip)
		GameTooltip:Show()
	end)
	CuratorOctoFull.SetScript(t, "OnLeave", function()
		GameTooltip:Hide()
	end)
	t.gap = -17
	return t
end

-- The ground of a page of the collections (the toys, the heirlooms): dark tiles, gold filigree in
-- its corners, in an inset of the window.
function S.Background(parent)
	local bg = S.Make("Frame", nil, parent, "CollectionsBackgroundTemplate") or S.Make("Frame", nil, parent, "InsetFrameTemplate")
	if not bg then
		bg = CreateFrame("Frame", nil, parent, CuratorOctoFull.BackdropTemplate())
		bg:SetBackdrop({
			bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 256, edgeSize = 14,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		bg:SetBackdropBorderColor(0.6, 0.6, 0.6)
	end
	bg:ClearAllPoints()
	return bg
end

-- A dark inset of the window, for a part of a page.
function S.Inset(parent)
	local f = S.Make("Frame", nil, parent, "InsetFrameTemplate")
	if not f then
		f = CreateFrame("Frame", nil, parent, CuratorOctoFull.BackdropTemplate())
		f:SetBackdrop({
			bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 256, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
	end
	f:ClearAllPoints()
	return f
end

-- A thin line across a page (the dividers of the game's settings).
function S.Divider(parent, width, alpha)
	local t = parent:CreateTexture(nil, "ARTWORK")
	if not S.Atlas(t, "Options_HorizontalDivider") then
		CuratorOctoFull.ColorTexture(t, 1, 0.82, 0, 0.35)
	end
	CuratorOctoFull.SetSize(t, width, 1)
	t:SetAlpha(alpha or 1)
	return t
end

-------------------------------------------------------------------------------
-- Buttons
-------------------------------------------------------------------------------
-- The red button of the game. b.label is its text, b:SetLabel(text) changes it.
function S.Button(parent, text, width, height)
	local b = S.Make("Button", nil, parent, "UIPanelButtonTemplate")
	if not b then
		b = CreateFrame("Button", nil, parent)
		b:SetNormalFontObject(GameFontNormal)
		b:SetHighlightFontObject(GameFontHighlight)
		b:SetDisabledFontObject(GameFontDisable)
		b:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		b:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
		b:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
		for _, tex in ipairs({ b:GetNormalTexture(), b:GetPushedTexture(), b:GetDisabledTexture(), b:GetHighlightTexture() }) do
			tex:SetTexCoord(0, 0.625, 0, 0.6875)
		end
		-- its text, there even while it is empty
		local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		fs:SetPoint("CENTER")
		b:SetFontString(fs)
	end
	CuratorOctoFull.SetSize(b, width or 120, height or 22)
	b:SetText(text or "")
	b.label = b:GetFontString()
	function b:SetLabel(t)
		self:SetText(t)
	end
	return b
end

-- The close button of the game's windows.
function S.CloseButton(parent)
	local b = S.Make("Button", nil, parent, "UIPanelCloseButtonNoScripts") or S.Make("Button", nil, parent, "UIPanelCloseButton")
	if not b then
		b = CreateFrame("Button", nil, parent)
		CuratorOctoFull.SetSize(b, 24, 24)
		b:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		b:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	end
	return b
end

-- The small red buttons in the corner of the game's windows: "Condense" (smaller), "Expand" (larger),
-- "Exit" (close). b:SetKind(kind) changes it. Older art where the client lacks them.
local RED_OLD = {
	Condense = "Interface\\Buttons\\UI-Panel-SmallerButton-",
	Expand = "Interface\\Buttons\\UI-Panel-BiggerButton-",
	Exit = "Interface\\Buttons\\UI-Panel-MinimizeButton-",
}
function S.RedButton(parent, kind)
	local b = CreateFrame("Button", nil, parent)
	CuratorOctoFull.SetSize(b, 26, 26)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints()
	if not S.Atlas(b.hl, "RedButton-Highlight") then
		b.hl:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
	end
	b.hl:SetBlendMode("ADD")
	local function paint(pressed)
		local k = b.kind or "Exit"
		if not S.Atlas(b.icon, "RedButton-" .. k .. (pressed and "-Pressed" or "")) then
			b.icon:SetTexture(RED_OLD[k] .. (pressed and "Down" or "Up"))
		end
	end
	function b:SetKind(k)
		self.kind = k
		paint(false)
	end
	CuratorOctoFull.SetScript(b, "OnMouseDown", function()
		paint(true)
	end)
	CuratorOctoFull.SetScript(b, "OnMouseUp", function()
		paint(false)
	end)
	b:SetKind(kind)
	return b
end

-- The round arrows that turn the pages of the spellbook and of the collections. dir: -1 or 1.
-- (1.14.0, a player's word) An arrow held down goes on by itself, faster and faster; a page arrow (S.PageArrows):
-- Shift + click turns ten pages at once. Its OnClick is kept to call it again (a click let go after it went on by
-- itself does not count once more).
S.HOLD_FIRST, S.HOLD_EVERY, S.HOLD_FASTEST, S.JUMP = 0.4, 0.12, 0.04, 10

local function Turn(b, button, quiet)
	local fn = b.turn
	if not fn then
		return
	end
	ns.quietTurn = quiet or nil
	local ok, err = pcall(fn, b, button or "LeftButton", false)
	ns.quietTurn = nil
	if not ok and geterrorhandler then
		geterrorhandler()(err)
	end
end

local function StopHold(b)
	b.holdAt = nil
	if b.setScript then
		b.setScript(b, "OnUpdate", nil)
	end
end

local function Holding(b)
	if not b.holdAt then
		return
	end
	local now = GetTime and GetTime() or 0
	if not (b:IsEnabled() and b:IsVisible()) or (IsMouseButtonDown and not IsMouseButtonDown("LeftButton")) then
		return StopHold(b)
	end
	if now >= b.holdAt then
		b.held = (b.held or 0) + 1
		b.repeated = true
		Turn(b, "LeftButton", CuratorOctoFull.Mod(b.held , 4) ~= 1)
		b.holdAt = now + math.max(S.HOLD_FASTEST, S.HOLD_EVERY - 0.01 * b.held)
	end
end

function S.Arrow(parent, dir, size)
	local b = CreateFrame("Button", nil, parent)
	size = size or 32
	CuratorOctoFull.SetSize(b, size, size)
	local p = "Interface\\Buttons\\UI-SpellbookIcon-" .. (dir < 0 and "Prev" or "Next") .. "Page-"
	b:SetNormalTexture(p .. "Up")
	b:SetPushedTexture(p .. "Down")
	b:SetDisabledTexture(p .. "Disabled")
	b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	-- (its OnClick, kept: held down or Shift-clicked, it is called again)
	local set = b.SetScript
	b.setScript = set
	function b:SetScript(name, fn)
		if name ~= "OnClick" then
			return set(self, name, fn)
		end
		self.turn = fn
		if not fn then
			return set(self, "OnClick", nil)
		end
		return set(self, "OnClick", function(btn, button, down)
			-- (let go after it went on by itself: done already)
			if btn.repeated then
				btn.repeated = nil
				return
			end
			if btn.pages and IsShiftKeyDown and IsShiftKeyDown() then
				for i = 1, S.JUMP do
					if not btn:IsEnabled() then
						break
					end
					Turn(btn, button, i > 1)
				end
				return
			end
			return fn(btn, button, down)
		end)
	end
	b:HookScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" or not self:IsEnabled() or not self.turn then
			return
		end
		self.repeated, self.held = nil, 0
		self.holdAt = (GetTime and GetTime() or 0) + S.HOLD_FIRST
		set(self, "OnUpdate", Holding)
	end)
	b:HookScript("OnMouseUp", function(self)
		StopHold(self)
		-- (let go away from it: no click comes to take the mark, the next one must count)
		if self.repeated and ns.Delay then
			ns.Delay(0.05, function()
				self.repeated = nil
			end)
		end
	end)
	b:HookScript("OnHide", function(self)
		StopHold(self)
		self.repeated = nil
	end)
	return b
end

-- (1.14.0) Two arrows that turn pages: Shift + click, ten pages; held down, they go on (S.Arrow). Under the mouse,
-- their tooltip says so.
function S.PageArrows(prev, nextOne)
	for _, b in ipairs({ prev, nextOne }) do
		local _, b = _, b; if b then
			b.pages = true
			b:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:AddLine(self == prev and L["Previous page"] or L["Next page"], 1, 1, 1)
				GameTooltip:AddLine(string.format(L["Hold it down to turn the pages fast. Shift + click: %d pages at once."], S.JUMP), 0.85, 0.85, 0.85, true)
				GameTooltip:Show()
			end)
			b:HookScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
	end
end

-- The pages of a collection: "Page 1/3" and its two arrows, as under the toys. pager:Set(page,
-- pages, suffix); pager.prev and pager.next take their OnClick.
function S.Pager(parent)
	local p = CreateFrame("Frame", nil, parent)
	CuratorOctoFull.SetSize(p, 67, 32)
	p.prev = S.Arrow(p, -1)
	p.prev:SetPoint("LEFT")
	p.next = S.Arrow(p, 1)
	p.next:SetPoint("LEFT", p.prev, "RIGHT", 3, 0)
	S.PageArrows(p.prev, p.next)
	p.text = S.Text(p, "GameFontWhite", "RIGHT")
	p.text:SetPoint("RIGHT", p.prev, "LEFT", -11, 0)
	function p:Set(page, pages, label)
		self.text:SetText(label)
		CuratorOctoFull.SetEnabled(self.prev, page > 1)
		CuratorOctoFull.SetEnabled(self.next, page < pages)
	end
	return p
end

-- A list button of the collections (the mounts, the pets): dark, gold when chosen, lit under the
-- mouse. b:SetSelected(on).
function S.ListButton(parent, frameType)
	local b = CreateFrame(frameType or "Button", nil, parent)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	if not S.Atlas(b.bg, "PetList-ButtonBackground") then
		CuratorOctoFull.ColorTexture(b.bg, 0.1, 0.1, 0.1, 0.85)
	end
	b.sel = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.sel:SetAllPoints()
	if not S.Atlas(b.sel, "PetList-ButtonSelect") then
		CuratorOctoFull.ColorTexture(b.sel, 1, 0.82, 0, 0.18)
	end
	b.sel:Hide()
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints()
	if not S.Atlas(b.hl, "PetList-ButtonHighlight") then
		CuratorOctoFull.ColorTexture(b.hl, 1, 1, 1, 0.08)
	end
	function b:SetSelected(on)
		CuratorOctoFull.SetShown(self.sel, on and true or false)
	end
	return b
end

-- A check box of the game, its label on the right (GameFontNormalSmall).
function S.Check(parent, label)
	local c = S.Make("CheckButton", nil, parent, "CheckboxWithLabelTemplate")
	if c then
		CuratorOctoFull.SetSize(c, 24, 23)
	else
		c = S.Make("CheckButton", nil, parent, "UICheckButtonTemplate")
		if c then
			CuratorOctoFull.SetSize(c, 26, 26)
		else
			c = CreateFrame("CheckButton", nil, parent)
			CuratorOctoFull.SetSize(c, 26, 26)
			c:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
			c:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
			c:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
			c:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		end
	end
	if not c.Text then
		c.Text = S.Text(c, "GameFontNormalSmall", "LEFT")
		c.Text:SetPoint("LEFT", c, "RIGHT", 2, 0)
	end
	c.Text:SetText(label or "")
	return c
end

-- A round option of the game (one chosen in its group), its label on the right.
function S.Radio(parent, label)
	local r = S.Make("CheckButton", nil, parent, "UIRadioButtonTemplate")
	if not r then
		r = CreateFrame("CheckButton", nil, parent)
		CuratorOctoFull.SetSize(r, 16, 16)
		r:SetNormalTexture("Interface\\Buttons\\UI-RadioButton")
		r:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
		r:SetCheckedTexture("Interface\\Buttons\\UI-RadioButton")
		r:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
		r:SetHighlightTexture("Interface\\Buttons\\UI-RadioButton", "ADD")
		r:GetHighlightTexture():SetTexCoord(0.5, 0.75, 0, 1)
	end
	if not r.text then
		r.text = S.Text(r, "GameFontNormalSmall", "LEFT")
		r.text:SetPoint("LEFT", r, "RIGHT", 5, 0)
	end
	r.text:SetText(label or "")
	return r
end

-------------------------------------------------------------------------------
-- Menus
-------------------------------------------------------------------------------
-- A drop-down menu of the game: dd:SetupMenu(function(dropdown, root) ... end) fills it, its
-- text is the option chosen. dd:SetTooltip(function(tooltip) ... end).
function S.Dropdown(parent, width)
	local d = S.Make("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	if d then
		d:SetWidth(width)
		return d
	end
	-- a button that opens the same menu (or, without the menus of the game, takes the next option)
	d = S.Button(parent, "", width, 22)
	d.label:SetJustifyH("LEFT")
	local generator, tip
	local radios = {}
	function d:SetupMenu(gen)
		generator = gen
		self:GenerateMenu()
	end
	function d:GenerateMenu()
		if not generator then
			return
		end
		-- the text: the option chosen
		local chosen
		local root = {}
		radios = {}
		function root:CreateRadio(text, isSelected, setSelected, data)
			radios[CuratorOctoFull.Length(radios) + 1] = { isSelected = isSelected, setSelected = setSelected, data = data }
			if isSelected(data) then
				chosen = text
			end
			return {}
		end
		function root.CreateTitle()
			return {}
		end
		function root.CreateDivider()
		end
		function root.SetScrollMode()
		end
		generator(self, root)
		self:SetText(chosen or "")
	end
	function d:SetTooltip(func)
		tip = func
	end
	CuratorOctoFull.SetScript(d, "OnClick", function(self)
		if not generator then
			return
		end
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(self, function(owner, root)
				generator(owner, root)
			end)
			return
		end
		local at = 0
		for i, r in ipairs(radios) do
			if r.isSelected(r.data) then
				at = i
			end
		end
		local nextOne = radios[CuratorOctoFull.Mod(at , math.max(1, CuratorOctoFull.Length(radios))) + 1]
		if nextOne and nextOne.setSelected then
			nextOne.setSelected(nextOne.data)
		end
		self:GenerateMenu()
	end)
	CuratorOctoFull.SetScript(d, "OnEnter", function(self)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			tip(GameTooltip)
			GameTooltip:Show()
		end
	end)
	CuratorOctoFull.SetScript(d, "OnLeave", function()
		GameTooltip:Hide()
	end)
	return d
end

-------------------------------------------------------------------------------
-- Bars
-------------------------------------------------------------------------------
-- The progress bar of the game's skills and reputations (on clients that have it), else the older
-- bar of the skills. bar:SetProgress(0 to 1), bar.text. colour: "green" or "blue".
function S.Bar(parent, width, colour)
	local b = S.Make("Frame", nil, parent, "ColoredProgressBarTemplate")
	if b and ColoredProgressBarMixin and ColoredProgressBarMixin.ColorType then
		CuratorOctoFull.SetSize(b, width, 29)
		local types = ColoredProgressBarMixin.ColorType
		b:SetFillTextureByColorType(colour == "blue" and types.Blue or types.Green)
		b.text = b.Text
		function b:SetProgress(p)
			self:SetFillPercent(p)
		end
		b.tall = 29
		return b
	end
	b = CreateFrame("StatusBar", nil, parent)
	CuratorOctoFull.SetSize(b, width, 13)
	b:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
	if colour == "blue" then
		b:SetStatusBarColor(0.25, 0.4, 0.95)
	else
		b:SetStatusBarColor(0.03, 0.85, 0)
	end
	b:SetMinMaxValues(0, 1)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetPoint("TOPLEFT", 0, -1)
	b.bg:SetPoint("BOTTOMRIGHT", 0, 1)
	CuratorOctoFull.ColorTexture(b.bg, 0, 0, 0, 1)
	b.border = b:CreateTexture(nil, "OVERLAY")
	b.border:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
	CuratorOctoFull.SetSize(b.border, width + 9, 29)
	b.border:SetPoint("LEFT", -5, 0)
	b.text = S.Text(b, "TextStatusBarText")
	b.text:SetPoint("CENTER", 0, 1)
	function b:SetProgress(p)
		self:SetValue(math.max(0, math.min(1, p)))
	end
	b.tall = 13
	return b
end

-- A thin bar, as on the achievements of the game: green fill, a frame of gold metal.
function S.ThinBar(parent, width, height, colour)
	local b = CreateFrame("StatusBar", nil, parent)
	CuratorOctoFull.SetSize(b, width, height)
	b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	local c = colour or { 0, 0.6, 0 }
	b:SetStatusBarColor(c[1], c[2], c[3])
	b:SetMinMaxValues(0, 1)
	b:SetValue(0)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	CuratorOctoFull.ColorTexture(b.bg, 0, 0, 0, 0.55)
	local file = "Interface\\AchievementFrame\\UI-Achievement-ProgressBar-Border"
	local pad = math.max(3, math.floor(height * 0.36 + 0.5))
	b.left = b:CreateTexture(nil, "OVERLAY")
	b.left:SetTexture(file)
	b.left:SetTexCoord(0, 0.0625, 0, 0.75)
	b.left:SetWidth(pad + 4)
	b.left:SetPoint("TOPLEFT", -pad, pad)
	b.left:SetPoint("BOTTOMLEFT", -pad, -pad)
	b.right = b:CreateTexture(nil, "OVERLAY")
	b.right:SetTexture(file)
	b.right:SetTexCoord(0.812, 0.8745, 0, 0.75)
	b.right:SetWidth(pad + 4)
	b.right:SetPoint("TOPRIGHT", pad, pad)
	b.right:SetPoint("BOTTOMRIGHT", pad, -pad)
	b.mid = b:CreateTexture(nil, "OVERLAY")
	b.mid:SetTexture(file)
	b.mid:SetTexCoord(0.0625, 0.812, 0, 0.75)
	b.mid:SetPoint("TOPLEFT", b.left, "TOPRIGHT")
	b.mid:SetPoint("BOTTOMRIGHT", b.right, "BOTTOMLEFT")
	function b:SetProgress(p)
		self:SetValue(math.max(0, math.min(1, p)))
	end
	return b
end

-- Every button of Curator is the game's.
ns.Button = S.Button
