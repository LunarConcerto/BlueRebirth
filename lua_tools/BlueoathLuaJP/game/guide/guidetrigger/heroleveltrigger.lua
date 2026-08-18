local HeroLevelTrigger = class("game.guide.guideTrigger.HeroLevelTrigger", GR.requires.GuideTriggerBase)

function HeroLevelTrigger:initialize(nType, nLevel)
  self.type = nType
  self.param = nLevel
end

function HeroLevelTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local nLevel = Data.userData:GetUserData().Level
  if nLevel >= self.param then
    self:sendTrigger()
  end
end

return HeroLevelTrigger
