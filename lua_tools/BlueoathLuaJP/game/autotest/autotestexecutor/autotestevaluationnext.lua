local AutoTestEvaluationNext = class("game.AutoTest.AutoTestExecutor.AutoTestEvaluationNext", GR.requires.Executor)

function AutoTestEvaluationNext:init()
  self.nWaitFrame = 0
  self.nTargetFrame = 5
  self.strName = "AutoTestEvaluationNext"
end

function AutoTestEvaluationNext:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  if UIPageManager:IsExistPage("EvaluationPage") then
    GR.autoTestManager:clickBtn("MainRoot/EvaluationPage/Next")
  end
end

function AutoTestEvaluationNext:resetImp()
  self.nWaitFrame = 0
end

return AutoTestEvaluationNext
