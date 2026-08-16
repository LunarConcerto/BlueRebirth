local StepBeginState = class("game.Guide.GuideStepStates.StepBeginState", GR.requires.GuideStepBase)

function StepBeginState:onStart()
  self.objTriggerListner = GR.guideHub.requireTriggerListner:new(self.onTriggerPoint, self)
  self:reset()
  self:Retention()
  local config = self.step.config
  local startBehaviour = config.BeginBehaviour
  local strWaitPointType = type(config.WaitStartPoint)
  if strWaitPointType == "number" then
    self.nTriggerPoint = config.WaitStartPoint
  elseif strWaitPointType == "table" then
    self.nTriggerPoint = config.WaitStartPoint[1]
  end
  GR.guideHub:logError("StepBeginState onStart" .. tostring(config.Note) .. "  stepId:" .. tostring(self.step.nId))
  self:initBehaviour(startBehaviour)
  self:initTrigger()
end

function StepBeginState:initBehaviour(startBehaviour)
  if startBehaviour ~= nil then
    self:buildBehaviours(startBehaviour)
    self:doAllBehaviours()
  else
    self.bBehaviourEnd = true
    self:tryEnd()
  end
end

function StepBeginState:initTrigger()
  if self.nTriggerPoint ~= nil then
    local config = self.step.config
    self.objTriggerListner:register(config.WaitStartPoint)
  else
    self.bTriggerEnd = true
    self:tryEnd()
  end
end

function StepBeginState:Retention()
  local nNodeId = self.step.mGuidePara.tblParagraphaConfig.id
  local nStageId = self.step.mGuidePara.mGuideStage.nId
  local nId = self.step.nId
  local tblParam = {
    big_step = tostring(nStageId),
    middle_steps = tostring(nNodeId),
    small_steps = tostring(nId),
    info = "open"
  }
  RetentionHelper.Retention(PlatformDotType.newPlayer, tblParam)
end

function StepBeginState:onTriggerPoint(nPointId)
  if self.nTriggerPoint == nPointId then
    self.bTriggerEnd = true
    self:tryEnd()
  end
end

function StepBeginState:onAllBehaviourDone()
  self.bBehaviourEnd = true
  self:tryEnd()
end

function StepBeginState:onEnd()
  self.objTriggerListner:unRegister()
  GR.guideHub:logError("StepBeginState onEnd " .. tostring(self.step.config.Note))
  self.step:changeState(GUIDESTEP_STATE.WAIT_OPERATE)
  self:reset()
end

function StepBeginState:interrupt()
  self:removeAllEvents()
  if self.objTriggerListner ~= nil then
    self.objTriggerListner:unRegister()
  end
  self:reset()
end

function StepBeginState:reset()
  self.bTriggerEnd = false
  self.bBehaviourEnd = false
end

function StepBeginState:tryEnd()
  if self.bTriggerEnd and self.bBehaviourEnd then
    GR.guideHub:logError("beginstate end")
    self:endState()
  end
end

return StepBeginState
