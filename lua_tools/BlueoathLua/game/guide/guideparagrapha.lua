local GuideParagrapha = class("Game.Guide.GuideParagrapha", require("Game.Guide.GuideStageNode"))
local super = GuideParagrapha.super
local requireStep = require("Game.Guide.GuideStep")

function GuideParagrapha:initialize(paragraphaConfig, objGuideStage)
  self.tabSteps = nil
  self.bIsDoing = nil
  self.mGuideStage = objGuideStage
  self.mCurStep = nil
  self.tblParagraphaConfig = paragraphaConfig
  self.tblStepConfig = paragraphaConfig.config
  self.nStepLength = #self.tblStepConfig
  self:init()
end

function GuideParagrapha:init()
  self.tabSteps = {}
  local count = self.nStepLength
  for i = 1, count do
    local stepId = self.tblStepConfig[i]
    local objStep = requireStep:new(stepId, self, i)
    self.tabSteps[i] = objStep
  end
end

function GuideParagrapha:start(nStartStepIndex)
  self:reset()
  if nStartStepIndex == nil then
    self:doStep(self.tabSteps[1])
  else
    self:doStep(self.tabSteps[nStartStepIndex])
  end
end

function GuideParagrapha:checkJump()
  local tblJumpConfig = self.tblParagraphaConfig.jumpCondition
  if tblJumpConfig == nil then
    return false
  end
  local nConditionId = tblJumpConfig[1]
  local objParam = tblJumpConfig[2]
  local bOpposite = tblJumpConfig[3]
  local bJump = GR.guideHub:ismeetOneCondition(nConditionId, objParam, bOpposite)
  return bJump
end

function GuideParagrapha:reset()
  for k, v in pairs(self.tabSteps) do
    v:reset()
  end
end

function GuideParagrapha:havePassKeyPoint(nIndex)
  local nKeyPoint = self.tblParagraphaConfig.keyPoint
  if nKeyPoint == nil then
    nKeyPoint = self.nStepLength
  end
  return nIndex >= nKeyPoint
end

function GuideParagrapha:getCurStep()
  return self.mCurStep
end

function GuideParagrapha:notifyParamDone()
  self.mGuideStage:onNodeDone(self)
end

function GuideParagrapha:getRecallNodeId()
  return self.tblParagraphaConfig.recallNodeId
end

function GuideParagrapha:doStep(objStep)
  self.mCurStep = objStep
  objStep:start()
end

function GuideParagrapha:getNextNodeId()
  if self.tblParagraphaConfig.nextNodeId ~= nil then
    return self.tblParagraphaConfig.nextNodeId
  end
end

function GuideParagrapha:getCurStep()
  return self.mCurStep
end

function GuideParagrapha:onStepDone(objStep)
  if self.mCurStep.index == self.nStepLength then
    self:notifyParamDone()
  else
    local newStep = self.mCurStep.index + 1
    self:doStep(self.tabSteps[newStep])
  end
end

function GuideParagrapha:getDoingParam()
  if self.mCurStep == nil then
    logError("curStep is nil")
    return
  end
  return self.tblParagraphaConfig.id, self.mCurStep.index
end

function GuideParagrapha:interrupt()
  self:reset()
end

return GuideParagrapha
