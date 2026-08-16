local BuildShipData = class("data.BuildShipData", Data.BaseData)

function BuildShipData:initialize()
  self:_InitHandlers()
end

function BuildShipData:_InitHandlers()
  self:ResetData()
end

function BuildShipData:ResetData()
  self.DrawInfo = {}
  self.DispInfo = {}
  self.FreeRefreshInfo = {}
  self.TotalCount = {}
  self.SpecialInfo = {}
  self.UsedBoxInfo = {}
  self.UsedRewardInfo = {}
  self.EndTime = {}
  self.HasRewardChanged = {}
end

function BuildShipData:SetData(param)
  if param.DrawInfo ~= nil then
    for i = 1, #param.DrawInfo do
      local drawInfo = param.DrawInfo[i]
      self.DrawInfo[drawInfo.Id] = drawInfo.Count
    end
  end
  if param.DispInfo ~= nil then
    for i = 1, #param.DispInfo do
      local dispInfo = param.DispInfo[i]
      self.DispInfo[dispInfo.Id] = dispInfo.Count
    end
  end
  if param.RefreshInfo ~= nil then
    for i = 1, #param.RefreshInfo do
      local refreshInfo = param.RefreshInfo[i]
      self.FreeRefreshInfo[refreshInfo.RefreshType] = refreshInfo.RefreshTime
    end
  end
  if param.TotalCount ~= nil then
    for i = 1, #param.TotalCount do
      local countInfo = param.TotalCount[i]
      self.TotalCount[countInfo.Id] = countInfo.Count
    end
  end
  if param.SpecialInfo ~= nil and #param.SpecialInfo > 0 then
    self.SpecialInfo = {}
    for i = 1, #param.SpecialInfo do
      local spId = param.SpecialInfo[i].Id
      if self.SpecialInfo[spId] == nil then
        self.SpecialInfo[spId] = {}
      end
      local currSpInfo = self.SpecialInfo[spId]
      local spInfo = param.SpecialInfo[i].SpecialInfo
      for j = 1, #spInfo do
        local reward = spInfo[j]
        if currSpInfo[reward.Type] == nil then
          currSpInfo[reward.Type] = {}
        end
        if currSpInfo[reward.Type][reward.ConfigId] == nil then
          currSpInfo[reward.Type][reward.ConfigId] = 0
        end
        currSpInfo[reward.Type][reward.ConfigId] = currSpInfo[reward.Type][reward.ConfigId] + reward.Num
      end
      self.SpecialInfo[spId] = currSpInfo
    end
  end
  if param.UsedRewardInfo ~= nil and 0 < #param.UsedRewardInfo then
    self.UsedRewardInfo = {}
    for _, v in pairs(param.UsedRewardInfo) do
      table.sort(v.Count, function(a, b)
        return a < b
      end)
      self.UsedRewardInfo[v.Id] = v.Count
    end
  end
  if param.UsedBoxInfo ~= nil and 0 < #param.UsedBoxInfo then
    self.UsedBoxInfo = {}
    for _, v in pairs(param.UsedBoxInfo) do
      table.sort(v.Count, function(a, b)
        return a < b
      end)
      self.UsedBoxInfo[v.Id] = v.Count
    end
  end
  if param.CloseTime ~= nil and 0 < #param.CloseTime then
    self.EndTime = {}
    for _, v in ipairs(param.CloseTime) do
      self.EndTime[v.Id] = v.CloseTime
    end
  end
  if param.RewardChange ~= nil and 0 < #param.RewardChange then
    self.HasRewardChanged = {}
    for _, v in ipairs(param.RewardChange) do
      local limits = {}
      self.HasRewardChanged[v.Id] = limits
      for j = 1, #v.Count do
        limits[v.Count[j]] = 1
      end
    end
  end
end

function BuildShipData:HasRewardBoxChanged(buildID, limitCount)
  return self.HasRewardChanged[buildID] ~= nil and self.HasRewardChanged[buildID][limitCount] ~= nil
end

function BuildShipData:GetEndtime(buildID)
  return self.EndTime[buildID]
end

function BuildShipData:GetCount(drawId)
  local count = self.DrawInfo[drawId]
  return count == nil and 0 or count
end

function BuildShipData:GetDispCount(buildId)
  local count = self.DispInfo[buildId]
  return count == nil and 1 or count + 1
end

function BuildShipData:GetFreeRefreshInfo()
  return self.FreeRefreshInfo
end

function BuildShipData:GetBuildShipCount(buildId)
  local count = self.TotalCount[buildId]
  return count == nil and 0 or count
end

function BuildShipData:GetSpecialInfo(buildId)
  local ret = next(self.SpecialInfo) ~= nil and self.SpecialInfo[buildId] or {}
  return ret
end

function BuildShipData:GetUsedRewardCoundTab(buildId)
  local countTab = self.UsedRewardInfo[buildId]
  return countTab == nil and {} or countTab
end

function BuildShipData:GetUsedBoxCoundTab(buildId)
  local countTab = self.UsedBoxInfo[buildId]
  return countTab == nil and {} or countTab
end

function BuildShipData:RefreshBuildData(buildId)
  self.TotalCount[buildId] = 0
  self.UsedBoxInfo[buildId] = {}
  self.UsedRewardInfo[buildId] = {}
end

return BuildShipData
