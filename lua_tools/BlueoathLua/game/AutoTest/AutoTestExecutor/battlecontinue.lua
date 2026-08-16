local BattleContinue = class("game.AutoTest.AutoTestExecutor.BattleContinue", GR.requires.Executor)

function BattleContinue:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "BattleContinue"
  self.bRegister = false
  self.nTriggerPoint = TRIGGER_TYPE.ADVANCE_ON_UI
  self.objTrigger = GR.guideHub.requireTriggerListner:new(self.onTriggerPoint, self)
end

function BattleContinue:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if not self.bRegister then
    self.objTrigger:unRegister()
    self.objTrigger:register(self.nTriggerPoint)
    self.bRegister = true
  end
end

function BattleContinue:onTriggerPoint(nTriggerType)
  if nTriggerType == self.nTriggerPoint then
    if self.nWaitFrame >= self.nTargetFrame then
      GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.AUTOTEST_CONTINUE_BATTLE)
      self.nWaitFrame = 0
    else
      self.nWaitFrame = self.nWaitFrame + 1
    end
  end
end

function BattleContinue:onStop()
  self.objTrigger:unRegister()
end

function BattleContinue:resetImp()
  self.nWaitFrame = 0
  self.bRegister = false
end

return BattleContinue
