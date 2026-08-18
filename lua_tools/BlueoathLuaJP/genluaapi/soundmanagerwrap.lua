local m = {}

function m:PlayAudio(audioStr)
end

function m:PlayAudioDesGameObj(audioStr, gameobject)
end

function m:PlayAudioWithCallBack(audioStr, gameobject, callbackType, asyncCallBack, cookie)
end

function m:GetAudioSource(cvStr)
end

function m:SetBGMVolume(value)
end

function m:SetAudioVolume(value)
end

function m:SetCVVolume(value)
end

function m:PauseAudio(audioStr)
end

function m:ResumeAudio(audioStr)
end

function m:StopAudio(audioStr)
end

function m:PauseMusic()
end

function m:ResumeMusic()
end

function m:MuteMusic(isMute)
end

function m:MuteAudio(isMute)
end

function m:PreLoadSingle(resId)
end

function m:PreLoad(resId)
end

function m:PreLoadGroup(groupId)
end

function m:UnLoad(resId)
end

function m:UnLoadGroup(groupId)
end

function m:UnLoadAll()
end

function m:Release()
end

function m:PlayMusic(musicId)
end

function m:ResumLastMusic()
end

function m:JumpToPosition(eventId, time)
end

function m:StopAllMusic()
end

function m:Update()
end

function m:SetMusicRTPCValue(eventId, value)
end

function m:NotifyPauseStateChange(isPause)
end

function m:NotifyFocusStateChange(isFocus)
end

function m:GetSoundDuration(eventId)
end

return m
