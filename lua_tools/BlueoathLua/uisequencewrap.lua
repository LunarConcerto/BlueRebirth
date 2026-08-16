local m = {}

function m.NewSequence(go, _bDestroyAtFinish)
end

function m:SetDestroyAtFinish(bDestroy)
end

function m:Destroy()
end

function m:Clear()
end

function m:Append(tween)
end

function m:AppendCallback(callback)
end

function m:AppendInterval(interval)
end

function m:Insert(atPosition, tween)
end

function m:InsertCallback(atPosition, callback)
end

function m:Join(tween)
end

function m:Prepend(tween)
end

function m:PrependCallback(callback)
end

function m:PrependInterval(interval)
end

function m:ResetToBeginning()
end

function m:ResetToInit()
end

function m:ResetToEnd()
end

return m
