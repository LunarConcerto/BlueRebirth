local CopyBossTrigger = class("game.guide.guideTrigger.CopyBossTrigger", GR.requires.GuideTriggerBase)

function CopyBossTrigger:initialize(nType, pageName)
  self.type = nType
  self.param = pageName
end

function CopyBossTrigger:tick()
  if not UIPageManager:IsExistPage(self.param) then
    return
  end
  local copyData = Data.copyData:GetCopyServiceData()
  for i, copyInfo in pairs(copyData) do
    if copyInfo.BossId ~= 0 then
      self:sendTrigger()
    end
  end
end

return CopyBossTrigger
