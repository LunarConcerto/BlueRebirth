local GuideCacheData = class("GuideCacheData")

function GuideCacheData:initialize()
end

function GuideCacheData:ResetData()
  self.settingsData = {}
end

function GuideCacheData:SetData(param)
  self.settingsData = param
end

function GuideCacheData:GetData()
  return SetReadOnlyMeta(self.settingsData)
end

function GuideCacheData:SetData(nKey, objValue)
  self.settingsData[nKey] = objValue
end

function GuideCacheData:GetData(nKey)
  return self.settingsData[nKey]
end

function GuideCacheData:SetFleetCanDrag(bCanDrag)
  self:SetData(GuideCacheDataKey.FleetPageCanDrag, bCanDrag)
end

function GuideCacheData:IsFleetCanDrag()
  local objTarget = self:GetData(GuideCacheDataKey.FleetPageCanDrag)
  if objTarget == nil then
    return false
  else
    return not objTarget
  end
end

function GuideCacheData:SetHomePageIsHideShow(bShow)
  self:SetData(GuideCacheDataKey.HomePageHideBtnShow, bShow)
end

function GuideCacheData:IsHomePageHideShow()
  local objTarget = self:GetData(GuideCacheDataKey.HomePageHideBtnShow)
  if objTarget == nil then
    return false
  else
    return objTarget
  end
end

function GuideCacheData:SetSeacopyChapterId(nChapterId)
  self:SetData(GuideCacheDataKey.SeacopyCurChapterId, nChapterId)
end

function GuideCacheData:GetSeacopyChapterId()
  local objTarget = self:GetData(GuideCacheDataKey.SeacopyCurChapterId)
  if objTarget == nil then
    return -1
  else
    return objTarget
  end
end

return GuideCacheData
