local m = {}

function m:Stop()
end

function m:Rewind(name)
end

function m:Sample()
end

function m:IsPlaying(name)
end

function m:Play()
end

function m:CrossFade(animation, fadeLength, mode)
end

function m:Blend(animation, targetWeight, fadeLength)
end

function m:CrossFadeQueued(animation, fadeLength, queue, mode)
end

function m:PlayQueued(animation, queue, mode)
end

function m:AddClip(clip, newName)
end

function m:RemoveClip(clip)
end

function m:GetClipCount()
end

function m:SyncLayer(layer)
end

function m:GetEnumerator()
end

function m:GetClip(name)
end

return m
