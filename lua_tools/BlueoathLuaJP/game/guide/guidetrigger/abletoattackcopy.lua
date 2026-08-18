local AbleToAttackCopy = class("game.guide.guideTrigger.AbleToAttackCopy", GR.requires.GuideTriggerBase)

function AbleToAttackCopy:initialize(nType)
  self.type = nType
  self.passedCopy = nil
  self.ableAttackCopy = nil
end

function AbleToAttackCopy:onStart(param)
  local tblParam = param
  self.passedCopy = tblParam.passedCopy
  self.ableAttackCopy = tblParam.notPassCopy
  self.nChapterId = tblParam.curChapterId
  local bPass = self:_check()
  if bPass then
    self:sendTrigger()
  end
end

function AbleToAttackCopy:tick()
  local bPass = self:_check()
  if bPass then
    self:sendTrigger()
  end
end

function AbleToAttackCopy:_check()
  local tblSeaCopyInfo = Data.copyData:GetCopyServiceData()
  local bPassOld = false
  local bPassTarget = false
  for i, v in pairs(tblSeaCopyInfo) do
    if v.BaseId == self.passedCopy and v.FirstPassTime > 0 then
      bPassOld = true
    end
    if v.BaseId == self.ableAttackCopy and v.FirstPassTime > 0 then
      bPassTarget = true
    end
  end
  local tblPlotCopyInfo = Data.copyData:GetPlotCopyServiceData()
  for i, v in pairs(tblPlotCopyInfo) do
    if v.BaseId == self.passedCopy and v.FirstPassTime > 0 then
      bPassOld = true
    end
    if v.BaseId == self.ableAttackCopy and v.FirstPassTime > 0 then
      bPassTarget = true
    end
  end
  local nChapterId = GR.guideHub:getGuideCachedata():GetSeacopyChapterId()
  if nChapterId ~= self.nChapterId then
    return false
  end
  local bPageOpen = UIHelper.IsPageOpen("CopyPage", "SeaCopyPage")
  if not bPageOpen then
    return false
  end
  local bPass = bPassOld and not bPassTarget
  if not bPass then
    return false
  end
  return true
end

return AbleToAttackCopy
