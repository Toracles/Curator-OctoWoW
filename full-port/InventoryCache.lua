-- Cache the last local view only. Never cache a reseller transaction.
-- Cache records point at the real copies; all normal mutation routes invalidate it.
function IU:InvalidateSurvey()
    self.surveyCache = nil
end
local survey = IU.Survey
function IU:Survey()
    if self.sell then self:InvalidateSurvey(); return survey(self) end
    local cache = self.surveyCache
    if not (cache and cache.db == ns.db and cache.filter == self.filter
        and cache.sort == self.sort and cache.rarity == self.rarity and cache.card == self.card
        and cache.series == self.series and cache.dupes == self.dupes) then
        local value = survey(self)
        cache = { db = ns.db, filter = self.filter, sort = self.sort, rarity = self.rarity,
            card = self.card, series = self.series, dupes = self.dupes, value = value }
        self.surveyCache = cache
    end
    local value, chips, gems = cache.value, {}, {}
    -- Header code adds object/case counts: keep cached counts immutable.
    for k, v in pairs(value.chips) do chips[k] = v end
    for k, v in pairs(value.gems) do gems[k] = v end
    return { lines = value.lines, copies = value.copies, chips = chips, gems = gems, taken = value.taken }
end
for _, event in ipairs({ "LOADED", "CHANGED", "COPIES_CHANGED", "CASES_CHANGED", "DISPLAYS_CHANGED",
    "GOLDEN_CHANGED", "TRADES_CHANGED", "LIVE_TRADE_CHANGED", "SHOWCASE_CHANGED", "TALENTS_CHANGED",
    "MAIN_CHANGED", "FOREVER_RESET", "COPY_CERTIFIED", "COPY_RESTORED", "COPY_RESTORING",
    "CASE_RESTORED", "CASE_RESTORING", "CARD_APPRAISED", "CARD_PURIFIED", "CARD_SEALED",
    "BANK_CHANGED", "ENCHANTER_CHANGED", "MASTER_CHANGED", "CHEST_CHANGED" }) do
    ns.On(event, function() IU:InvalidateSurvey() end)
end
-- Direct grants/removals invalidate even before their caller fires CHANGED.
local function watch(object, keys)
    for _, key in ipairs(keys) do
        local old = object[key]
        if old then
            object[key] = function(self, ...)
                IU:InvalidateSurvey()
                return old(self, unpack(arg, 1, arg.n))
            end
        end
    end
end
watch(C, { "Add" })
watch(CP, { "Added", "Take", "Put", "Stamp", "Purified" })
