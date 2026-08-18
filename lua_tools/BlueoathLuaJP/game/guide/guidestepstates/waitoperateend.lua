local WaitOperateEnd = class("game.Guide.GuideStepStates.WaitOperateEnd", GR.requires.GuideStepBase)

function WaitOperateEnd:onStart()
  self.objTriggerListner = GR.guideHub.requireTriggerListner:new(self.onTriggerPoint, self)
  local config = self.step.config
  local strWaitPointType = type(config.WaitEndPoint)
  if strWaitPointType == "number" then
    self.waitEndPoint = config.WaitEndPoint
  elseif strWaitPointType == "table" then
    self.waitEndPoint = config.WaitEndPoint[1]
  end
  GR.guideHub:logError("WaitOperateEnd onStart " .. tostring(config.Note))
  if self.waitEndPoint ~= nil then
    self.objTriggerListner:register(config.WaitEndPoint)
  else
    self:endState()
  end
end

function WaitOperateEnd:onTriggerPoint(nPoint)
  if self.waitEndPoint == nPoint then
    self:endState()
  end
end

function WaitOperateEnd:onEnd()
  self:rentention()
  self.objTriggerListner:unRegister()
  GR.guideHub:logError("WaitOperateEnd onEnd " .. tostring(self.step.config.Note))
  local tblBehaviour = self.step.config.EndBehaviour
  if tblBehaviour ~= nil then
    self:buildBehaviours(tblBehaviour)
    self:doAllBehaviours()
  end
  self.step:notifyStepDone()
end

function WaitOperateEnd:rentention()
  local nNodeId = self.step.mGuidePara.tblParagraphaConfig.id
  local nStageId = self.step.mGuidePara.mGuideStage.nId
  local nId = self.step.nId
  local tblParam = {
    big_step = tostring(nStageId),
    middle_steps = tostring(nNodeId),
    small_steps = tostring(nId),
    info = "end"
  }
  RetentionHelper.Retention(PlatformDotType.newPlayer, tblParam)
end

function WaitOperateEnd:interrupt()
  self:removeAllEvents()
  if self.objTriggerListner ~= nil then
    self.objTriggerListner:unRegister()
  end
end

return WaitOperateEnd
