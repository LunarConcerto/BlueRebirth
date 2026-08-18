local GirlAnimEndTrigger = class("game.guide.guideTrigger.GirlAnimEndTrigger", GR.requires.GuideTriggerBase)

function GirlAnimEndTrigger:initialize(nType)
  self.type = nType
end

function GirlAnimEndTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local state = Logic.homeLogic:GetModelAnimEnd()
  if state then
    self:sendTrigger()
  end
end

return GirlAnimEndTrigger
