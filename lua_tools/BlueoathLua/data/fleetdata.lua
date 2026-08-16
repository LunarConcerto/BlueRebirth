local FleetData = class("data.FleetData", Data.BaseData)
FleetSubType = {
  Home = 1,
  Train = 2,
  Tower = 4,
  Preset = 5
}

function FleetData:initialize()
  self:_InitHandlers()
end

function FleetData:_InitHandlers()
  self:ResetData()
end

function FleetData:ResetData()
  self.FleetInfo = {}
  self.heroInFleetId = {}
  self.MaxPower = 0
  self.MinPower = 0
end

function FleetData:SetData(param)
  if param and param.MaxPower then
    self.MaxPower = param.MaxPower
  end
  if param and param.MinPower then
    self.MinPower = param.MinPower
  end
  for _, info in pairs(param.tactics) do
    if self.FleetInfo[info.type] == nil then
      self.FleetInfo[info.type] = {}
    end
    self.FleetInfo[info.type][info.modeId] = info
  end
  for type, v in pairs(self.FleetInfo) do
    self.FleetInfo[type] = self:SortFleet(v)
  end
  Logic.fleetLogic:SetImageStrategy(self.FleetInfo)
  self:SetHeroInFleetId()
end

function FleetData:SortFleet(fleetTab)
  table.sort(fleetTab, function(data1, data2)
    return data1.modeId < data2.modeId
  end)
  return fleetTab
end

function FleetData:GetFleetData(fleetType)
  fleetType = fleetType ~= nil and fleetType or FleetType.Normal
  return self.FleetInfo[fleetType]
end

function FleetData:GetShipByFleet(fleetId, fleetType)
  local fleetInfo = self:GetFleetData(fleetType)
  local shipIds = {}
  if fleetInfo[fleetId] ~= nil then
    local shipList = fleetInfo[fleetId].heroInfo
    for i = 1, #shipList do
      table.insert(shipIds, shipList[i])
    end
  end
  return SetReadOnlyMeta(shipIds)
end

function FleetData:GetFleetDataById(fleetId, fleetType)
  local npcFleetData = npcAssistFleetMgr:GetNpcFleetData()
  if npcFleetData and npcFleetData[fleetId] then
    return npcFleetData[fleetId]
  end
  local shipList = self:GetFleetData(fleetType)[fleetId]
  return SetReadOnlyMeta(shipList)
end

function FleetData:GetStrategyDataById(fleetId, fleetType)
  local fleetInfo = self:GetFleetData(fleetType)[fleetId]
  if fleetInfo then
    return SetReadOnlyMeta(fleetInfo.strategyId)
  else
    logError("GetStrategyDataById err. fleetId:" .. fleetId)
    return
  end
end

function FleetData:SetHeroInFleetId()
  self.heroInFleetId = {}
  local fleetInfo = self.FleetInfo[FleetType.Normal]
  for i, v in ipairs(fleetInfo) do
    if v.heroInfo ~= nil and #v.heroInfo > 0 then
      for key, value in ipairs(v.heroInfo) do
        self.heroInFleetId[value] = v.modeId
      end
    end
  end
end

function FleetData:GetHeroInFleetId()
  return self.heroInFleetId
end

function FleetData:GetMaxPower()
  return self.MaxPower
end

function FleetData:GetMinPower()
  return self.MinPower
end

function FleetData:GetNumOfFleetUpMaxPower(fleetType, power)
  local data = self:GetFleetData(fleetType)
  local num = 0
  for index, fleetInfo in ipairs(data) do
    if data and data.MaxPower and power <= data.MaxPower then
      num = num + 1
    end
  end
  return num
end

return FleetData
