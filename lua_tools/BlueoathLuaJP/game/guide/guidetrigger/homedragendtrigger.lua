local HomeDragEndTrigger = class("game.guide.guideTrigger.HomeDragEndTrigger", GR.requires.GuideTriggerBase)

function HomeDragEndTrigger:initialize(nType)
  self.type = nType
end

function HomeDragEndTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local state = Logic.homeLogic:GetDragCamEnd()
  if state then
    self:sendTrigger()
  end
end

return HomeDragEndTrigger
