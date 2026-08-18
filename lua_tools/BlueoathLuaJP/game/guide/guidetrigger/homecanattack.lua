local HomeCanAttack = class("game.guide.guideTrigger.HomeCanAttack", GR.requires.GuideTriggerBase)

function HomeCanAttack:initialize(nType)
  self.type = nType
  self.guideCacheData = GR.guideHub:getGuideCachedata()
end

function HomeCanAttack:tick()
  local nCurStage = stageMgr:GetCurStageType()
  if nCurStage ~= EStageType.eStageMain then
    return
  end
  if not UIHelper.IsPageOpen("HomePage") then
    return
  end
  if UIHelper.IsPageOpen("AssistQuickpage") then
    return
  end
  if self.guideCacheData:IsHomePageHideShow() then
    self:sendTrigger()
  elseif UIHelper.IsPageOpen("FleetPage") then
    self:sendTrigger()
  end
end

return HomeCanAttack
