local m = {}

function m:CanTogglePlaySound(toggle)
end

function m:RegisterToggle(toggle)
end

function m:ResigterToggleUnActive(index, funcCB)
end

function m:RemoveToggleUnActive(index)
end

function m:SetSoundPath(soundPath)
end

function m:ClearToggles()
end

function m:RemoveToggle(toggle)
end

function m:RegisterActiveToggleChange(luafun)
end

function m:NotifyToggleOn(toggle, isOn, playSound)
end

function m:GetCurrentActiveIndex()
end

function m:SetActiveToggleIndex(index)
end

function m:SetActiveToggleOff()
end

return m
