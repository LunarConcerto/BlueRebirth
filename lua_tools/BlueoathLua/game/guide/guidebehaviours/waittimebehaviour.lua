local WaitTimeBehaviour = class("game.Guide.guidebehaviours.WaitTimeBehaviour", GR.requires.BehaviourBase)

function WaitTimeBehaviour:doBehaviour()
  local nWaitTime = self.objParam
  local funcCB = function()
    self:_onTimeEnd()
  end
  if self.objTimer == nil then
    self.objTimer = Timer.New(funcCB, nWaitTime)
  else
    self.objTimer:Reset(funcCB, nWaitTime)
  end
  self.objTimer:Start()
end

function WaitTimeBehaviour:_onTimeEnd()
  self:onDone()
end

function WaitTimeBehaviour:interrupt()
  if self.objTimer ~= nil then
    self.objTimer:Stop()
  end
end

return WaitTimeBehaviour
