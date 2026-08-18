local BuildShipData = class("data.BuildShipData", Data.BaseData)
EXTRACT_RESET_TYPE = {Normal = 0, UpEquip = 1}

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
  self.ResetTypeCount = {}
  self.ExtractInfo = {}
  self.EndTime = {}
  self.HasRewardChanged = {}
  self.TenRefreshInfo = {}
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
  if param.TenRefreshInfo ~= nil then
    for i = 1, #param.TenRefreshInfo do
      local info = param.TenRefreshInfo[i]
      self.TenRefreshInfo[info.BuildID] = info.RefreshState
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
  if param.ResetTypeCount ~= nil and 0 < #param.ResetTypeCount then
    self.ResetTypeCount = {}
    for _, v in ipairs(param.ResetTypeCount) do
      self.ResetTypeCount[v.Id] = v.Count
    end
  end
  if param.ExtractInfo ~= nil and 0 < #param.ExtractInfo then
    self.ExtractInfo = {}
    for _, v in ipairs(param.ExtractInfo) do
      self.ExtractInfo[v.Id] = {}
      for _, vv in ipairs(v.UpCount) do
        self.ExtractInfo[v.Id][vv.UpId] = vv.Count
      end
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
      if v.UpCount then
        for j = 1, #v.UpCount do
          limits[v.UpCount[j]] = 1
        end
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

function BuildShipData:GetTenFreeRefreshInfo()
  return self.TenRefreshInfo
end

function BuildShipData:GetBuildShipCount(buildId)
  local count = self.TotalCount[buildId]
  return count == nil and 0 or count
end

function BuildShipData:GetResetTypeCount(resetType)
  local count = self.ResetTypeCount[resetType] or 0
  return count
end

function BuildShipData:GetExtractUpCount(resetType, upId)
  local data = self.ExtractInfo[resetType] or {}
  local count = data[upId] or 0
  return count
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

function BuildShipData:GetUpShip_InExtractByBulidId(buildId)
  local heroIdArr = {}
  local ssr = clone(self:GetSSR_InExtractByBulidId(buildId))
  local sr = clone(self:GetSR_InExtractByBulidId(buildId))
  if next(sr) ~= nil and 0 < #sr then
    for i = 1, #sr do
      table.insert(ssr, sr[i])
    end
  end
  if next(ssr) ~= nil then
    for i, v in ipairs(ssr) do
      if v[1] and 0 < v[1] then
        table.insert(heroIdArr, v[1])
      end
    end
  end
  return heroIdArr
end

function BuildShipData:GetSSR_InExtractByBulidId(buildId)
  local config = configManager.GetDataById("config_extract_ship", buildId)
  if config and config.ssr_up_ship_info then
    return config.ssr_up_ship_info
  end
  return nil
end

function BuildShipData:GetSR_InExtractByBulidId(buildId)
  local config = configManager.GetDataById("config_extract_ship", buildId)
  if config and config.sr_up_ship_info then
    return config.sr_up_ship_info
  end
  return nil
end

function BuildShipData:GetAttributeDataByType(type, shipInfoId)
  if self.typeConfig == nil then
    self:SortAttributeConfigByType()
  end
  local shipInfoCfg = configManager.GetDataById("config_ship_info", shipInfoId)
  local shipTypeids = {}
  if self.typeConfig[type] ~= nil and shipInfoCfg then
    for j = 1, #shipInfoCfg.attr_dock_show do
      for i, v in ipairs(self.typeConfig[type]) do
        if v.id == shipInfoCfg.attr_dock_show[j] then
          table.insert(shipTypeids, v)
        end
      end
    end
    return shipTypeids
  end
  return nil
end

function BuildShipData:SortAttributeConfigByType()
  local config = configManager.GetData("config_attribute")
  self.typeConfig = {}
  for i, v in pairs(config) do
    local data = v
    if next(data) ~= nil then
      if self.typeConfig[data.attr_type] == nil then
        self.typeConfig[data.attr_type] = {}
      end
      table.insert(self.typeConfig[data.attr_type], data)
    end
  end
  return self.typeConfig
end

return BuildShipData
