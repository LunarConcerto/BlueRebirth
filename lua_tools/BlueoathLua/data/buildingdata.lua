local BuildingData = class("data.BuildingData", Data.BaseData)

function BuildingData:initialize()
  self:ResetData()
end

function BuildingData:ResetData()
  self.datas = {
    BuildingDatas = {},
    BuildingTypes = {},
    Lands = {}
  }
  self.m_buildingHeros = {}
end

function BuildingData:_getBuildType(Tid)
  return configManager.GetDataById("config_buildinginfo", Tid).type
end

function BuildingData:IsInited()
  return self.inited == true
end

function BuildingData:UpdateBuildingHero()
  self.m_buildingHeros = {}
  local datas = self.datas.BuildingDatas
  for id, info in pairs(datas) do
    for _, heroId in ipairs(info.HeroList) do
      local cfg = configManager.GetDataById("config_buildinginfo", info.Tid)
      self.m_buildingHeros[heroId] = info
    end
  end
end

function BuildingData:SetData(buildingData)
  self.inited = true
  if buildingData.BuildingInfos then
    local datas = self.datas.BuildingDatas
    local types = self.datas.BuildingTypes
    for _, info in pairs(buildingData.BuildingInfos) do
      local btype = self:_getBuildType(info.Tid)
      types[btype] = types[btype] or {}
      types[btype][info.Id] = true
      info.HeroEffectTime = {}
      for i, v in ipairs(info.HeroEffectTimeList) do
        info.HeroEffectTime[v.HeroId] = v.EffectTime
      end
      datas[info.Id] = info
    end
    self:UpdateBuildingHero()
    Logic.buildingLogic:RefreshBuildingHeroSfId()
    self:SetDormIndex()
  end
  if buildingData.LandList then
    local curLands = self.datas.Lands
    for i, info in ipairs(buildingData.LandList) do
      curLands[info.Index] = info.BuildingId
    end
  end
  if buildingData.WorkerStrength then
    self.datas.WorkerStrength = buildingData.WorkerStrength
  end
  if buildingData.WorkerRecover then
    self.datas.WorkerRecover = buildingData.WorkerRecover
  end
  if buildingData.WorkerUpdateTime then
    self.datas.WorkerUpdateTime = buildingData.WorkerUpdateTime
  end
  if buildingData.Food then
    self.datas.Food = buildingData.Food
  end
  if buildingData.FoodMax then
    self.datas.FoodMax = buildingData.FoodMax
  end
  if buildingData.Electric then
    self.datas.Electric = buildingData.Electric
  end
  if buildingData.ElectricMax then
    self.datas.ElectricMax = buildingData.ElectricMax
  end
  if buildingData.NormalPlotUpdateTime then
    self.datas.NormalPlotUpdateTime = buildingData.NormalPlotUpdateTime
  end
  if buildingData.NormalPlotDatas then
    self.datas.NormalPlotDatas = {}
    for i, plotData in ipairs(buildingData.NormalPlotDatas) do
      self.datas.NormalPlotDatas[plotData.BuildingId] = self.datas.NormalPlotDatas[plotData.BuildingId] or {}
      self.datas.NormalPlotDatas[plotData.BuildingId][plotData.HeroId] = plotData.PlotId
    end
  end
  if buildingData.SpecialPlotDatas then
    self.datas.SpecialPlotDatas = {}
    for i, plotData in ipairs(buildingData.SpecialPlotDatas) do
      self.datas.SpecialPlotDatas[plotData.BuildingId] = self.datas.SpecialPlotDatas[plotData.BuildingId] or {}
      self.datas.SpecialPlotDatas[plotData.BuildingId][plotData.HeroId] = plotData.PlotId
    end
  end
  if buildingData.NormalTriggeredHeroIds then
    self.datas.NormalTriggeredHeroIds = self.datas.NormalTriggeredHeroIds or {}
    for i, heroId in ipairs(buildingData.NormalTriggeredHeroIds) do
      self.datas.NormalTriggeredHeroIds[heroId] = true
    end
  end
  if buildingData.SpecialTriggeredHeroPlots then
    self.datas.SpecialTriggeredHeroPlots = self.datas.SpecialTriggeredHeroPlots or {}
    for i, triggerData in ipairs(buildingData.SpecialTriggeredHeroPlots) do
      for heroId, plotId in pairs(triggerData) do
        self.datas.SpecialTriggeredHeroPlots[heroId] = plotId
      end
    end
  end
end

function BuildingData:SetDormIndex()
  if self.dormCount and self.dormCount >= 3 then
    return
  end
  self.dormCount = 0
  self.dormIndex = {}
  local index = 1
  table.sort(self.datas.BuildingDatas, function(l, r)
    return l.Id < r.Id
  end)
  for _, info in pairs(self.datas.BuildingDatas) do
    local cfg = configManager.GetDataById("config_buildinginfo", info.Tid)
    if cfg.type == MBuildingType.DormRoom then
      self.dormIndex[info.Id] = index
      index = index + 1
      self.dormCount = self.dormCount + 1
    end
  end
end

function BuildingData:GetDormIndex(buildingId)
  local index = self.dormIndex[buildingId] or 1
  return index
end

function BuildingData:RemoveNormalPlot(args)
  if self.datas.NormalPlotDatas[args.BuildingId] and self.datas.NormalPlotDatas[args.BuildingId][args.HeroId] == args.PlotId then
    self.datas.NormalPlotDatas[args.BuildingId] = nil
  end
end

function BuildingData:RemoveSpecialPlot(args)
  if self.datas.SpecialPlotDatas[args.BuildingId] and self.datas.SpecialPlotDatas[args.BuildingId][args.HeroId] == args.PlotId then
    self.datas.SpecialPlotDatas[args.BuildingId] = nil
  end
end

function BuildingData:GetBuildingById(id)
  local data = self.datas.BuildingDatas
  if data[id] then
    return data[id]
  else
    return nil
  end
end

function BuildingData:GetBuildingData()
  return self.datas.BuildingDatas or {}
end

function BuildingData:GetBuildingsByType(type)
  local res = {}
  local data = self.datas
  if data.BuildingTypes[type] then
    for id, _ in pairs(data.BuildingTypes[type]) do
      local info = data.BuildingDatas[id]
      if info then
        table.insert(res, info)
      end
    end
  end
  table.sort(res, function(l, r)
    return l.Id < r.Id
  end)
  return res
end

function BuildingData:GetBuildingCountByType(type)
  local count = 0
  local data = self.datas
  if data.BuildingTypes[type] then
    for id, _ in pairs(data.BuildingTypes[type]) do
      local info = data.BuildingDatas[id]
      if info then
        count = count + 1
      end
    end
  end
  return count
end

function BuildingData:GetBuildingByIndex(index)
  local data = self.datas
  if data.Lands and data.Lands[index] then
    local buildingId = data.Lands[index]
    local info = data.BuildingDatas[buildingId]
    return info, info ~= nil
  end
  return nil, false
end

function BuildingData:HaveBuilding()
  return self.datas.BuildingDatas and next(self.datas.BuildingDatas) ~= nil
end

function BuildingData:GetOffice()
  local officeData
  for id, data in pairs(self.datas.BuildingDatas) do
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if cfg.type == MBuildingType.Office then
      officeData = data
      break
    end
  end
  if officeData == nil then
    logError("======Exception: No office data!==========")
  end
  return officeData
end

function BuildingData:GetWorkerStrength()
  return self.datas.WorkerStrength or 0
end

function BuildingData:SetWorkerStrength(strength)
  self.datas.WorkerStrength = strength
end

function BuildingData:GetMaxWorkerByLv(officeLevel)
  local workerCfg = configManager.GetDataById("config_worker", 1)
  local maxStrength = workerCfg.workerhpmax
  if 1 <= officeLevel and officeLevel <= #workerCfg.workerhplevelup then
    for i = 1, officeLevel do
      maxStrength = maxStrength + workerCfg.workerhplevelup[i]
    end
  end
  return maxStrength
end

function BuildingData:GetMaxWorkerStrength()
  local office = self:GetOffice()
  local maxStrength = self:GetMaxWorkerByLv(office.Level)
  return maxStrength
end

function BuildingData:GetWorkerRecover()
  return self.datas.WorkerRecover or 0
end

function BuildingData:GetWorkerUpdateTime()
  return self.datas.WorkerUpdateTime or 0
end

function BuildingData:GetElectricMax()
  return self.datas.ElectricMax or 0
end

function BuildingData:GetCurElectric()
  return self.datas.Electric or 0
end

function BuildingData:GetFoodMax()
  return self.datas.FoodMax or 0
end

function BuildingData:UpdateCurFood()
  local cost = 0
  for id, data in pairs(self.datas.BuildingDatas) do
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    local foodCost = cfg.foodcost
    cost = cost + #data.HeroList * foodCost
  end
  self.datas.Food = cost
  return cost
end

function BuildingData:GetCurFood()
  return self.datas.Food or 0
end

function BuildingData:GetCurBuildingCount()
  local count = 0
  local data = self.datas.BuildingDatas
  if data then
    for id, info in pairs(data) do
      count = count + 1
    end
  end
  return count
end

function BuildingData:GetBuildingHeroCount()
  local count = 0
  local capacity = 0
  local data = self.datas.BuildingDatas
  if data then
    for id, info in pairs(data) do
      count = count + #info.HeroList
      local cfg = configManager.GetDataById("config_buildinginfo", info.Tid)
      capacity = capacity + cfg.heronumber
    end
  end
  return count, capacity
end

function BuildingData:IsInBuilding(heroId)
  return self.m_buildingHeros[heroId] ~= nil
end

function BuildingData:GetBuildingHeroMap()
  return self.m_buildingHeros
end

function BuildingData:GetHeroBuilding(heroId)
  return self.m_buildingHeros[heroId]
end

function BuildingData:GetHeroBuildingType(heroId)
  local buildingData = self.m_buildingHeros[heroId]
  if buildingData then
    local cfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    return cfg.type
  end
  return nil
end

function BuildingData:GetBuildingHero()
  local res = {}
  for id, _ in pairs(self.m_buildingHeros) do
    table.insert(res, id)
  end
  return res
end

function BuildingData:GetNormalPlots()
  return self.datas.NormalPlotDatas
end

function BuildingData:GetSpecialPlots()
  local sprcialPlotDetas = {}
  for buildId, heroPlotTab in pairs(self.datas.SpecialPlotDatas) do
    sprcialPlotDetas[buildId] = {}
    for heroId, plotId in pairs(heroPlotTab) do
      local forbidden = Logic.forbiddenHeroLogic:CheckForbiddenInSystem(heroId, ForbiddenType.PersonalPlot)
      if not forbidden then
        sprcialPlotDetas[buildId][heroId] = plotId
      end
    end
    if next(sprcialPlotDetas[buildId]) == nil then
      sprcialPlotDetas[buildId] = nil
    end
  end
  return sprcialPlotDetas
end

function BuildingData:GetNormalPlotUpdateTime()
  return self.datas.NormalPlotUpdateTime
end

function BuildingData:GetPresetById(buildingId)
  local buildingData = self.datas.BuildingDatas[buildingId]
  return buildingData.TacticList
end

return BuildingData
