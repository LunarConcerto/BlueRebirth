local EnterStage = class("game.Guide.guidebehaviours.EnterStage", GR.requires.BehaviourBase)

function EnterStage:doBehaviour()
  self.nStageType = self.objParam
  local funcCB = function()
    self:tick()
  end
  if self.objTimer == nil then
    self.objTimer = Timer.New(funcCB, 0.1, -1)
  else
    self.objTimer:Stop()
    self.objTimer:Reset(funcCB, 0.1, -1)
  end
  self.objTimer:Start()
end

function EnterStage:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage == self.nStageType then
    self:onDone()
    self.objTimer:Stop()
    self.objTimer = nil
  end
end

return EnterStage
