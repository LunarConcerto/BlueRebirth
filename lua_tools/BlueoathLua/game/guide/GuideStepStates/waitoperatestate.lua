local WaitOperateState = class("game.Guide.GuideStepStates.WaitOperateState", GR.requires.GuideStepBase)

function WaitOperateState:onStart()
  self.bSendMsg = false
  local config = self.step.config
  local tblBehaviour = config.OperateBehaviour
  GR.guideHub:logError("WaitOperateState onStart")
  if config.CompID ~= nil then
    if tblBehaviour == nil then
      tblBehaviour = {}
    end
    local tblOpeBehaviour = {
      GUIDE_BEHAVIOUR.USER_OPERA,
      config.CompID
    }
    table.insert(tblBehaviour, tblOpeBehaviour)
  end
  if tblBehaviour == nil then
    self:endState()
  else
    self:buildBehaviours(tblBehaviour)
    self:doAllBehaviours()
  end
end

function WaitOperateState:onEnd()
  if self.bSendMsg then
    return
  end
  self.bSendMsg = true
  GR.guideManager:saveDoingStage()
  GR.guideHub:logError("WaitOperateState onEnd " .. tostring(self.step.config.Note) .. tostring(self.step.nId))
  self.step:changeState(GUIDESTEP_STATE.WAIT_OPERATE_END)
end

function WaitOperateState:interrupt()
  self:removeAllEvents()
end

function WaitOperateState:onAllBehaviourDone()
  self:endState()
end

return WaitOperateState
