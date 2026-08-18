local WaitServiceCallMethod = class("game.Guide.guidebehaviours.WaitServiceCallMethod", GR.requires.BehaviourBase)

function WaitServiceCallMethod:doBehaviour()
  self.strMethodName = self.objParam
  eventManager:RegisterEvent(LuaEvent.SocketOnReceived, self.onServiceCall, self)
end

function WaitServiceCallMethod:onServiceCall(strMethodName)
  if self.strMethodName == strMethodName then
    eventManager:UnregisterEvent(LuaEvent.SocketOnReceived, self.onServiceCall)
    self:onDone()
  end
end

function WaitServiceCallMethod:interrupt()
  eventManager:UnregisterEvent(LuaEvent.SocketOnReceived, self.onServiceCall)
end

return WaitServiceCallMethod
