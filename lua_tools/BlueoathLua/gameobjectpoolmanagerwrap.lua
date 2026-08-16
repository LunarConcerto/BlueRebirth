local m = {}

function m:LuaGetGameObject(path, parent, maxNum)
end

function m:GetGameObjectDirect(path, parent, maxNum, isLuaSpawn)
end

function m:GetGameObjectAsync(path, finishCallback, parent)
end

function m:Register(path, preNum, maxNum)
end

function m:RegisterAsync(path, preNum, finishCallback, maxNum)
end

function m:LuaUnspawn(obj)
end

function m:Unspawn(obj, isLuaUnspawn)
end

function m:LuaUnspawnDelay(obj, duration)
end

function m:LuaUnspawnAndDestory(obj)
end

function m:UnspawnAndDestory(obj, isLuaUnspawn)
end

function m:UnspawnObjectsGettedByLua()
end

function m:GetDebugInfos()
end

function m:Release()
end

return m
