local m = {}

function m:Start()
end

function m:Shutdown()
end

function m:GetCurStage()
end

function m:GetCurStageType()
end

function m:GetCurrentEnterParam()
end

function m:Goto(_nextStateType, enterParam, allowSameState)
end

function m:Tick(deltaTime)
end

function m:lateUpdate()
end

function m:IsLoading()
end

function m:GetLoadProgress()
end

return m
