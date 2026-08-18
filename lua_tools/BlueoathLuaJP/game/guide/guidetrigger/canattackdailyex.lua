local CanAttackDailyEx = class("game.guide.guideTrigger.CanAttackDailyEx", GR.requires.GuideTriggerBase)

function CanAttackDailyEx:initialize(nType)
  self.type = nType
  self.copyids = {
    20003,
    20001,
    20004,
    20002
  }
end

function CanAttackDailyEx:tick()
  local bPassCopy = false
  for i = 1, 4 do
    local nChapterId = self.copyids[i]
    if Logic.dailyCopyLogic:CheckOpenTreaty(nChapterId) then
      bPassCopy = true
      break
    end
  end
  if not bPassCopy then
    return
  end
  if UIHelper.IsSubPageOpen("CopyPage", "DailyCopyPage") then
    self:sendTrigger()
  end
end

return CanAttackDailyEx
