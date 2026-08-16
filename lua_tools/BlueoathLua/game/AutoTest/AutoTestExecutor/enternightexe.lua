local EnterNightExe = class("game.AutoTest.AutoTestExecutor.EnterNightExe", GR.requires.Executor)

function EnterNightExe:init()
  self.strName = "EnterNightExe"
  self.nWaitFrame = 0
  self.nTargetFrame = 20
  self.nTriggerPoint = TRIGGER_TYPE.ENTER_NIGHT
  self.bRegister = false
  self.objTriggerListner = GR.guideHub.requireTriggerListner:new(self.onTriggerPoint, self)
end

function EnterNightExe:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if not self.bRegister then
    self.objTriggerListner:unRegister()
    self.objTriggerListner:register(self.nTriggerPoint)
    self.bRegister = true
  end
end

function EnterNightExe:onTriggerPoint(nTriggerType)
  if nTriggerType == self.nTriggerPoint then
    if self.nWaitFrame >= self.nTargetFrame then
      GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.AUTOTEST_SELECT_NIGHT)
      self.nWaitFrame = 0
    else
      self.nWaitFrame = self.nWaitFrame + 1
    end
  end
end

function EnterNightExe:resetImp()
  self.objTriggerListner:unRegister()
  self.bRegister = false
  self.nWaitFrame = 0
end

return EnterNightExe
