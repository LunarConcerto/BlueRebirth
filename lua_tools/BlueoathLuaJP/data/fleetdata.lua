local FleetData = class("data.FleetData", Data.BaseData)
FleetSubType = {
  Home = 1,
  Train = 2,
  Tower = 4,
  Preset = 5,
  GuideWar = 6
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
    if info.exHeroInfo == nil then
      info.exHeroInfo = {}
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
  return self.FleetInfo[fleetType] or self:GetGuildWarFleetData()
end

function FleetData:GetGuildWarFleetData()
  if self.guildWarFleet == nil then
    self.guildWarFleet = {}
    local oneFleet = {}
    oneFleet.strategyId = 0
    oneFleet.tacticName = "\229\189\147\229\137\141\230\181\183\229\159\159"
    oneFleet.type = 4
    oneFleet.heroInfo = {}
    oneFleet.formationId = 2
    oneFleet.modeId = 1
    table.insert(self.guildWarFleet, oneFleet)
  end
  return self.guildWarFleet
end

function FleetData:SetGuildWarFleetData(fleetData)
  if self.guildWarFleet == nil then
    self.guildWarFleet = clone(fleetData)
  end
  return self.guildWarFleet
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

function FleetData:GetExShipByFleet(fleetId, fleetType)
  local fleetInfo = self:GetFleetData(fleetType)
  local shipIds = {}
  if fleetInfo[fleetId] ~= nil then
    local shipList = fleetInfo[fleetId].exHeroInfo
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
    if v.exHeroInfo ~= nil and 0 < #v.exHeroInfo then
      for key, value in ipairs(v.exHeroInfo) do
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

function FleetData:SaveGuildWarLockData(data)
  self.GuidWarHeroData = {}
  local tabHero = Data.heroData:GetHeroData()
  for i = 1, #data do
    local sf_id
    local heroData = Data.heroData:GetHeroById(data[i])
    if heroData then
      local si_id = Logic.shipLogic:GetShipInfoIdByTid(heroData.TemplateId)
      sf_id = Logic.shipLogic:GetShipFleetId(si_id)
      self.GuidWarHeroData[sf_id] = sf_id
    end
  end
end

function FleetData:GetGuildWarLockData()
  return self.GuidWarHeroData
end

return FleetData
