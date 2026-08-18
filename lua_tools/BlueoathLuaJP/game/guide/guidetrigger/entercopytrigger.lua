local EnterCopyTrigger = class("game.guide.guideTrigger.EnterCopyTrigger", GR.requires.GuideTriggerBase)

function EnterCopyTrigger:initialize(nType, nCopyId)
  self.type = nType
  self.param = nCopyId
end

function EnterCopyTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageSimpleBattle then
    return
  end
  local objStage = stageMgr:GetCurStageObj()
  local param = Logic.copyLogic:GetAttackCopyInfo()
  if param == nil then
    logError("param is nil")
    return
  end
  local nCurCopyId = param.CopyId
  if nCurCopyId == self.param then
    self:sendTrigger()
  end
end

return EnterCopyTrigger
