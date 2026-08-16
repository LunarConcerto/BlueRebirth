local m = {}

function m:ChangeScene(resPath, refresh)
end

function m:ApplyScenePostProcess()
end

function m:HideCurScene()
end

function m:DestroyCurScene()
end

function m:ShowCurScene()
end

function m:UnLoadAllGameScene()
end

function m:SwitchTOD_Noon()
end

function m:SwitchTOD_Afternoon(totalTime, currentTime)
end

function m:SwitchTOD_Day2Night()
end

function m:SwitchTOD_Night()
end

function m:SwitchTOD_Morning(totalTime, currentTime)
end

function m:SwitchTOD_Night2Day()
end

function m:SwitchTOD_BattleDay2Night()
end

function m:SwitchTOD_BattleNight2Day()
end

function m:SetOriginalSunDir()
end

function m:AfternoonOrMorningTime(currentTime)
end

return m
