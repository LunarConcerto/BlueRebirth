local BaseService = class("service.BaseService")
local Socket_net = require("socket_net")
Socket_net.Init()
BattleLauncher:Init()

function BaseService:initialize()
end

function BaseService:SendLuaEvent(eventName, param)
  eventManager:SendEvent(eventName, param)
end

function BaseService:BindEvent(eventName, handler, target)
  target = target or self
  local pbType = protobufTypeManager[eventName]
  Socket_net.registerHandler(eventName, handler, target, pbType)
end

function BaseService:UnBindEvent(eventName)
  Socket_net.removeHandler(eventName)
end

function BaseService:SendNetEvent(method, args, state, waitRecv)
  if waitRecv == nil then
    waitRecv = true
  end
  if nil ~= method then
    Socket_net.send1(method, args, state, waitRecv)
  end
end

return BaseService
