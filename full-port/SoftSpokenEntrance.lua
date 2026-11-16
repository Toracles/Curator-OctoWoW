function Cin:PlaySoftSpoken()
	if not (ns.db and ns.db.softSpokenMythic == true and self.card.rarity == 6) then return false end
	local spoken = _G.Spoken
	local voices = _G.CuratorSoftSpokenVoices
	local voice = voices and voices[self.card.real or self.card.npc]
	if not (voice and spoken and spoken.IsCompatible and spoken:IsCompatible(1)
		and spoken.GetQueueSize and spoken:GetQueueSize() == 0
		and spoken.IsPaused and not spoken:IsPaused()) then
		return false
	end
	local source = spoken:GetSource("curator-mythic")
	if not source then
		source = spoken:RegisterSource("curator-mythic", {
			title = L["Mythic voices via SoftSpoken"], addon = "Curator", interClipGap = 0,
		})
	end
	if not source:CanPlay() then return false end
	local words = (ns.locale == "frFR" and voice.frFR) or voice.enUS
	local clip = {
		key = "curator-mythic:" .. (self.card.real or self.card.npc),
		path = voice.path, length = voice.length,
		present = { header = C:Name(self.card), transcript = words, portrait = { kind = "none" } },
	}
	clip.startCallback = function()
		if self.spokenClip ~= clip then return end
		self.spokenActive = true
		self:TypeLine(words, 1)
		local line = self.line
		line.done, line.doneT, line.hold = true, 0, 0.2
		self.frame.say:SetText(table.concat(line.chars))
	end
	clip.stopCallback = function()
		if self.spokenClip == clip then self.spokenActive = nil end
	end
	self.spokenClip, self.spokenSource = clip, source
	local ok = pcall(source.Enqueue, source, clip)
	if ok and self.spokenActive then return true end
	self:StopSoftSpoken()
	return false
end

function Cin:StopSoftSpoken()
	local clip, source = self.spokenClip, self.spokenSource
	self.spokenClip, self.spokenSource, self.spokenActive = nil, nil, nil
	if clip then source:Remove(clip) end
end
