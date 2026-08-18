local m = {}

function m.Init()
end

function m.Connect(host, port)
end

function m.Disconnect()
end

function m.GetNetState()
end

function m.IssueResend()
end

function m.Send(handle, method, buffer)
end

function m.LuaSend(handle, method, buffer, waitRecv)
end

function m.InitLuaCallbacks(stateWatcher, messageHandler)
end

function m.CleanLuaCallbacks()
end

function m.Cleanup()
end

function m.RegisterMessageHandler(method, muteLua, callback)
end

function m.CleanMessageHandler(method)
end

function m.CleanAllMessageHandler()
end

function m.BeginRecord()
end

function m.EndRecord()
end

return m
