local HomeGirlClickTrigger = class("game.guide.guideTrigger.HomeGirlClickTrigger", GR.requires.GuideTriggerBase)

function HomeGirlClickTrigger:initialize(nType)
  self.type = nType
end

function HomeGirlClickTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local state = Logic.homeLogic:GetModelClick()
  if state then
    self:sendTrigger()
  end
end

return HomeGirlClickTrigger
