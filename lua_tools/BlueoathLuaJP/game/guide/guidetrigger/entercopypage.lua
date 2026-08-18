local EnterCopyPage = class("game.guide.guideTrigger.EnterCopyPage", GR.requires.GuideTriggerBase)

function EnterCopyPage:initialize(nType)
  self.type = nType
end

function EnterCopyPage:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  if UIHelper.IsPageOpen("CopyPage") then
    self:sendTrigger()
  end
end

return EnterCopyPage
