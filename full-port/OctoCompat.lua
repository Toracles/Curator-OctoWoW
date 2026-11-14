-- Compatibility helpers used by the mechanically converted upstream modules.
CuratorOctoFull = {}
local ns = CuratorOctoFull

function ns.Length(value)
    if type(value) == "string" then return string.len(value) end
    return ns.ArraySize(value)
end

function ns.Mod(value, divisor)
    -- Lua 5.1 modulo uses floor division, including for negative offsets.
    return value - math.floor(value / divisor) * divisor
end

function ns.Select(index, ...)
    if index == "#" then return arg.n end
    if index < 0 then index = arg.n + index + 1 end
    if index > arg.n then return end
    if index < 1 then error("index out of range") end
    return unpack(arg, index, arg.n)
end

local callbackArguments = {
    OnEvent = function(frame, fn)
        return fn(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end,
    OnUpdate = function(frame, fn) return fn(frame, arg1) end,
    OnMouseWheel = function(frame, fn) return fn(frame, arg1) end,
    OnMouseUp = function(frame, fn) return fn(frame, arg1) end,
    OnMouseDown = function(frame, fn) return fn(frame, arg1) end,
    OnClick = function(frame, fn) return fn(frame, arg1, arg2) end,
    OnValueChanged = function(frame, fn) return fn(frame, arg1, arg2) end,
    OnKeyDown = function(frame, fn) return fn(frame, arg1) end,
    OnDoubleClick = function(frame, fn) return fn(frame, arg1) end,
    OnTextChanged = function(frame, fn) return fn(frame, arg1) end,
}

function ns.SetScript(frame, handler, callback)
    if not callback then return frame:SetScript(handler, nil) end
    local call = callbackArguments[handler]
    if call then
        return frame:SetScript(handler, function() return call(this or frame, callback) end)
    end
    return frame:SetScript(handler, function() return callback(this or frame) end)
end

function ns.ServerTime()
    if GetServerTime then return GetServerTime() end
    return time()
end

function ns.SetSize(region, width, height)
    if region.SetSize then return region:SetSize(width, height) end
    region:SetWidth(width)
    region:SetHeight(height)
end

function ns.ColorTexture(region, red, green, blue, alpha)
    if region.SetColorTexture then return region:SetColorTexture(red, green, blue, alpha) end
    region:SetTexture(red, green, blue, alpha)
end

local timers = {}
local clock
local function schedule(seconds, callback, count)
    if not clock then
        clock = CreateFrame("Frame")
        clock:SetScript("OnUpdate", function()
            local now = GetTime()
            for i = table.getn(timers), 1, -1 do
                local timer = timers[i]
                if timer.cancelled then
                    table.remove(timers, i)
                elseif timer.due <= now then
                    if timer.remaining == 1 then
                        table.remove(timers, i)
                    else
                        if timer.remaining then timer.remaining = timer.remaining - 1 end
                        timer.due = now + timer.interval
                    end
                    local ok, why = pcall(timer.callback, timer)
                    if not ok then geterrorhandler()(why) end
                end
            end
            if table.getn(timers) == 0 then clock:Hide() end
        end)
    end
    local interval = math.max(0, seconds)
    local timer = {due = GetTime() + interval, interval = interval, callback = callback, remaining = count}
    function timer:Cancel() self.cancelled = true end
    function timer:IsCancelled() return self.cancelled == true end
    table.insert(timers, timer)
    clock:Show()
    return timer
end

ns.Timer = C_Timer or {
    After = function(seconds, callback)
        schedule(seconds, function() callback() end, 1)
    end,
    NewTicker = function(seconds, callback, count) return schedule(seconds, callback, count) end,
}

function ns.SetShown(region, visible)
    if region.SetShown then return region:SetShown(visible) end
    if visible then region:Show() else region:Hide() end
end

function ns.SetClipsChildren(frame, enabled)
    if frame.SetClipsChildren then frame:SetClipsChildren(enabled) end
end

-- Masked layers retain their textures on Vanilla. The renderer cannot clip
-- those layers to the alpha of a second texture, so decorative layers may spill.
function ns.CreateMaskTexture(frame, name, layer)
    if frame.CreateMaskTexture then return frame:CreateMaskTexture(name, layer) end
    local mask = frame:CreateTexture(name, layer or "BACKGROUND")
    mask:Hide()
    return mask
end

function ns.AddMaskTexture(texture, mask)
    if texture.AddMaskTexture and mask then texture:AddMaskTexture(mask) end
end

function ns.RemoveMaskTexture(texture, mask)
    if texture.RemoveMaskTexture and mask then texture:RemoveMaskTexture(mask) end
end

function ns.Wipe(values)
    for key in pairs(values) do values[key] = nil end
    return values
end

local nativeChat = C_ChatInfo
ns.Chat = setmetatable({}, {__index = nativeChat or {}})
if not ns.Chat.SendAddonMessage and SendAddonMessage then
    ns.Chat.SendAddonMessage = function(prefix, message, channel, target)
        return SendAddonMessage(prefix, message, channel, target)
    end
end
if not ns.Chat.SendChatMessage and SendChatMessage then
    ns.Chat.SendChatMessage = SendChatMessage
end
if not ns.Chat.RegisterAddonMessagePrefix and ns.Chat.SendAddonMessage then
    -- Vanilla has no prefix-registration step.
    ns.Chat.RegisterAddonMessagePrefix = function() return true end
end

local angles = setmetatable({}, {__mode = "k"})
function ns.SetRotation(region, radians)
    if region.SetRotation then return region:SetRotation(radians) end
    if region.SetFacing then return region:SetFacing(radians) end
    if not region.SetTexCoord then return end
    angles[region] = radians
    local c, s = math.cos(radians) * .5, math.sin(radians) * .5
    region:SetTexCoord(.5-c+s,.5-s-c, .5-c-s,.5-s+c,
        .5+c+s,.5+s-c, .5+c-s,.5+s+c)
end

function ns.GetRotation(region)
    if region.GetRotation then return region:GetRotation() end
    return angles[region] or 0
end

ns.Gmatch = string.gmatch or string.gfind
function ns.Match(value, pattern, offset)
    if string.match then return string.match(value, pattern, offset) end
    local function capture(first, last, ...)
        if not first then return end
        if arg.n > 0 then return unpack(arg,1,arg.n) end
        return string.sub(value,first,last)
    end
    return capture(string.find(value,pattern,offset))
end

function ns.Byte(value, first, last)
    if not last then return string.byte(value, first or 1) end
    local n = string.len(value)
    first = first or 1
    if first < 0 then first = n + first + 1 end
    if last < 0 then last = n + last + 1 end
    local bytes = {}
    for index = math.max(1, first), math.min(n, last) do
        table.insert(bytes, string.byte(value, index))
    end
    return unpack(bytes)
end

function ns.ArraySize(values)
    local high = 1
    while values[high] ~= nil do high = high * 2 end
    local low = math.floor(high / 2)
    while high - low > 1 do
        local mid = math.floor((low + high) / 2)
        if values[mid] == nil then high = mid else low = mid end
    end
    return low
end

local hasSetn = table.setn and pcall(table.setn, {}, 0)
ns.Huge = math.huge or 1 / 0

function ns.Insert(values, position, value)
    if hasSetn then table.setn(values, ns.ArraySize(values)) end
    if value == nil then return table.insert(values, position) end
    return table.insert(values, position, value)
end

function ns.Remove(values, position)
    if hasSetn then table.setn(values, ns.ArraySize(values)) end
    return table.remove(values, position)
end


