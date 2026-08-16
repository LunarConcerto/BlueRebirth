local BattleAutoExe = class("game.AutoTest.AutoTestExecutor.BattleAutoExe", GR.requires.Executor)

function BattleAutoExe:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "BattleAutoExe"
end

function BattleAutoExe:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if self.nWaitFrame >= self.nTargetFrame then
    GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.BATTLE_AUTO, true)
    self:stop()
  else
    self.nWaitFrame = self.nWaitFrame + 1
  end
end

function BattleAutoExe:resetImp()
  self.nWaitFrame = 0
end

return BattleAutoExe
