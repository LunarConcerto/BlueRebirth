local SettlementNext = class("game.AutoTest.AutoTestExecutor.SettlementNext", GR.requires.Executor)

function SettlementNext:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "SettlementNext"
end

function SettlementNext:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if UIPageManager:IsExistPage("SettlementPage") then
    GR.autoTestManager:clickBtn("MainRoot/SettlementPage/Next")
  end
end

function SettlementNext:resetImp()
  self.nWaitFrame = 0
end

return SettlementNext
