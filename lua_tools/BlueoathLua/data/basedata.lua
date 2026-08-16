local BaseData = class("data.BaseData")

function BaseData:initialize()
end

function BaseData:RegisterEvent(eventName, func)
  eventManager:RegisterEvent(eventName, func, self)
end

function BaseData:BindEvent(eventName, handler, target, pbType)
  Socket_net.registerHandler(eventName, handler, target, pbType)
end

function BaseData:SetData(param)
  self.data = param
end

return BaseData
