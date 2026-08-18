local PresetFleetLogic = class("logic.PresetFleetLogic")

function PresetFleetLogic:initialize()
  self:ResetData()
end

function PresetFleetLogic:ResetData()
  self.m_presetData = nil
  self.nameNum = -1
  self.redDot = 0
  self.CurIndex = 0
  self.m_todoInfos = {}
  self.m_isServixce = false
  self.m_isRetire = false
  self.m_onFleetShip = {}
  self.setModi = false
  self.noDotSend = false
  self.isModiCorr = false
end

function PresetFleetLogic:SetCurIndex(index)
  self.CurIndex = index
end

function PresetFleetLogic:GetCurIndex()
  return self.CurIndex
end

function PresetFleetLogic:GetCorr()
  return self.isModiCorr
end

function PresetFleetLogic:ReSetCorr(tmp)
  self.isModiCorr = tmp
end

function PresetFleetLogic:isSetModi()
  self.setModi = true
end

function PresetFleetLogic:ReSetModi()
  self.setModi = false
end

function PresetFleetLogic:GetSetModi()
  return self.setModi
end

function PresetFleetLogic:IsnoDotSend()
  self.noDotSend = true
end

function PresetFleetLogic:SetFleetNIL(dataret)
  self.m_presetData = dataret
end

function PresetFleetLogic:GetPresetFleetLength()
  return #self.m_presetData
end

function PresetFleetLogic:GetNameNum()
  if self.nameNum == -1 or self.nameNum == 0 then
    self.nameNum = Data.presetFleetData:GetPresetNameNum()
    if self.nameNum == 0 then
      self.nameNum = 1
    end
  end
  return self.nameNum
end

function PresetFleetLogic:SetNameNum(num)
  self.nameNum = num
end

function PresetFleetLogic:PresetGetRedDot()
  if self.redDot == 1 then
    return self.redDot
  end
  self.redDot = Data.presetFleetData:GetRedDotValue()
  return self.redDot
end

function PresetFleetLogic:SetRedDot(dot)
  self.redDot = dot
end

function PresetFleetLogic:GetData()
  self:RefreshGetData()
  return self.m_presetData
end

function PresetFleetLogic:GetDataByIndex(index)
  return self.m_presetData[index]
end

function PresetFleetLogic:SetIsService(booll)
  self.m_isServixce = booll
end

function PresetFleetLogic:GetIsService()
  return self.m_isServixce
end

function PresetFleetLogic:SetStrategyId(fleetId, strategyId)
  self.m_presetData = self:GetData()
  self.m_presetData[fleetId].strategyId = strategyId
  self:isSetModi()
  eventManager:SendEvent(LuaEvent.PRESET_SelectHero)
end

function PresetFleetLogic:GetStrategyId(fleetId)
  return self.m_presetData[fleetId].strategyId
end

function PresetFleetLogic:RefreshGetData()
  local total = self:GetTotalNum()
  local data = self.m_presetData
  local res = {}
  if data then
    for i = 1, total do
      if data[i] then
        table.insert(res, data[i])
      end
    end
  end
  self.m_presetData = res
  return self.m_presetData
end

function PresetFleetLogic:GetTotalNum()
  local totalNumconf = configManager.GetDataById("config_parameter", 255)
  local totalNum = totalNumconf.value
  return totalNum
end

function PresetFleetLogic:DeleteFleet(index)
  local ok = self:CanDeleteFleet(index)
  if ok then
    table.remove(self.m_presetData, index)
    self:isSetModi()
  else
  end
  eventManager:SendEvent(LuaEvent.PRESET_SelectHero)
end

function PresetFleetLogic:CanDeleteFleet(index)
  local presetData = self.m_presetData
  if presetData then
    for i, v in pairs(presetData) do
      if i == index then
        return true
      end
    end
  end
  return false
end

function PresetFleetLogic:SetPresetHeros(index, heros, exHeroList, Name, strategyId, bool)
  if self.m_presetData[index] == nil then
    self.m_presetData[index] = self:GenPresetTemplate(index)
  end
  if not Name or bool then
  else
    self.m_presetData[index].Name = Name
  end
  if strategyId then
    self.m_presetData[index].strategyId = strategyId
  end
  if heros then
    self.m_presetData[index].heroList = heros
  end
  if exHeroList then
    self.m_presetData[index].exHeroList = exHeroList
  end
  self:isSetModi()
  eventManager:SendEvent(LuaEvent.PRESET_SelectHero)
end

function PresetFleetLogic:GenPresetTemplate(index)
  local defaultName = UIHelper.GetString(920000486)
  local maxNum = self:GetNameNum()
  defaultName = defaultName .. maxNum
  maxNum = maxNum + 1
  self:SetNameNum(maxNum)
  return {
    modeId = index,
    strategyId = 0,
    Name = defaultName,
    heroList = {}
  }
end

function PresetFleetLogic:GenPresetTemplateItem(index)
  return {
    modeId = index,
    strategyId = 0,
    Name = UIHelper.GetString(920000486),
    heroList = {}
  }
end

function PresetFleetLogic:GenStrategyTemplate(strategy)
  return {
    formationId = 0,
    tacticName = UIHelper.GetString(920000486),
    strategyId = strategy,
    modeId = 1,
    type = 1,
    heroInfo = {}
  }
end

function PresetFleetLogic:SortPresetData(fleetData)
  local data = fleetData
  local temp = {}
  for i, v in pairs(data) do
    if v.heroList ~= nil and #v.heroList ~= 0 then
      table.insert(temp, v)
    end
  end
  self.m_presetData = temp
  return self.m_presetData
end

function PresetFleetLogic:CheckChangeName(index, newName)
  if type(newName) ~= "string" or newName == "" then
    return false, UIHelper.GetString(1900010)
  end
  local _, len = string.gsub(newName, ".[\128-\191]*", "")
  local lenMin = configManager.GetDataById("config_parameter", 259).value
  if len < lenMin then
    return false, UIHelper.GetString(920000487)
  end
  return true, ""
end

function PresetFleetLogic:SetChangeName(index, newName)
  local tempNameData = clone(self.m_presetData)
  tempNameData[index].Name = newName
  self:isSetModi()
  self:SendPresetService(tempNameData)
end

function PresetFleetLogic:SendPresetService(tempNameData)
  local datas = self:GetData()
  if tempNameData then
    datas = tempNameData
  end
  local num = self:GetNameNum()
  local dot = self:PresetGetRedDot()
  local args = {}
  for _, data in ipairs(datas) do
    if data.heroList ~= nil and next(data.heroList) ~= nil then
      table.insert(args, {
        modeId = data.modeId,
        Name = data.Name,
        strategyId = data.strategyId,
        heroList = data.heroList,
        exHeroList = data.exHeroList
      })
    end
  end
  local presetFleetTab = {}
  if self.noDotSend then
    presetFleetTab = {presetfleet = args, NameNum = num}
  else
    presetFleetTab = {
      presetfleet = args,
      NameNum = num,
      redDot = dot
    }
  end
  if self.setModi then
    Service.presetFleetService:SetPresetFleets(presetFleetTab)
  end
end

function PresetFleetLogic:GetNextOpenLevel()
  local totalNumconf = configManager.GetDataById("config_parameter", 255)
  local totalNum = totalNumconf.value
  return totalNum, 999
end

function PresetFleetLogic:SetTacrticOver(index)
  local data = self.m_presetData[index]
  local tempData = {}
  tempData[1] = self:GenStrategyTemplate(data.strategyId)
  return tempData
end

function PresetFleetLogic:GetRepeatHeroList(index, curSelectTog)
  self.m_onFleetShip = Logic.fleetLogic:GetFleetHeroId(FleetType.Normal)
  local repeatedHeroList = {}
  local repeatedFleetList = {}
  for i, v in ipairs(self.m_presetData[index].heroList) do
    local ok, heroId, fleetId = self:CheckOnOtherFleet(v, self.m_onFleetShip, curSelectTog)
    if ok then
      table.insert(repeatedHeroList, heroId)
      table.insert(repeatedFleetList, fleetId)
    end
  end
  if repeatedHeroList ~= nil and next(repeatedHeroList) ~= nil and repeatedFleetList ~= nil and next(repeatedFleetList) ~= nil then
    return true, repeatedHeroList, repeatedFleetList
  else
    return false, nil, nil
  end
end

function PresetFleetLogic:CheckOnOtherFleet(heroId, fleetHid, curSelectTog)
  for i, v in ipairs(fleetHid) do
    if v[heroId] ~= nil and i ~= curSelectTog then
      return true, heroId, i
    end
  end
  return false, nil, nil
end

function PresetFleetLogic:GetNewIndex()
  local MaxIndex = 0
  for i, v in ipairs(self.m_presetData) do
    if i > MaxIndex then
      MaxIndex = i
    end
  end
  return MaxIndex
end

function PresetFleetLogic:GetPresetFleetShip(fleetId, typ)
  local data = clone(self.m_presetData)
  return data[fleetId].heroList
end

function PresetFleetLogic:GetRedDotState()
  local isRedUnRead = self:IsRedUnRead()
  local isOpenFunction = self:IsPresetOpen()
  if isRedUnRead and isOpenFunction then
    return true
  else
    return false
  end
end

function PresetFleetLogic:IsRedUnRead()
  local dot = Data.presetFleetData:GetRedDotValue()
  if dot == 0 then
    return true
  else
    return false
  end
end

function PresetFleetLogic:IsPresetOpen()
  return moduleManager:CheckFunc(FunctionID.PresetFleet, false) and true or false
end

function PresetFleetLogic:CheckStrategyFuncOpen()
  if moduleManager:CheckFunc(FunctionID.Strategy, false) then
    return true
  end
  return false
end

function PresetFleetLogic:SendMatchTactic(m_data)
  if m_data == nil then
    local tempTab = Data.presetFleetData:GetPresetFleetData()
    m_data = tempTab[1]
  end
  local heroList = {}
  local limitCounts = configManager.GetDataById("config_parameter", 534).arrValue
  local tabLen = #m_data.heroList >= limitCounts[1] and limitCounts[1] or #m_data.heroList
  local heroInfo = {}
  heroInfo.HeroIdList = {}
  heroInfo.HeroInfo = {}
  for i = 1, tabLen do
    local heroId = m_data.heroList[i]
    if heroId then
      table.insert(heroInfo.HeroIdList, heroId)
      local heroData = Data.heroData:GetHeroById(heroId)
      local temp = {}
      temp.Hid = heroId
      temp.Tid = heroData.TemplateId
      temp.Fashioning = heroData.Fashioning
      temp.Level = heroData.Lvl
      temp.Advance = heroData.Advance
      table.insert(heroInfo.HeroInfo, temp)
    end
  end
  heroInfo.StrategyId = m_data.strategyId
  table.insert(heroList, heroInfo)
  if m_data.exHeroList then
    tabLen = #m_data.heroList >= limitCounts[2] and limitCounts[2] or #m_data.heroList
    local exHeroInfo = {}
    exHeroInfo.HeroIdList = {}
    exHeroInfo.HeroInfo = {}
    for i = 1, tabLen do
      local heroId = m_data.exHeroList[i]
      if heroId then
        table.insert(exHeroInfo.HeroIdList, heroId)
        local heroData = Data.heroData:GetHeroById(heroId)
        local temp = {}
        temp.Hid = heroId
        temp.Tid = heroData.TemplateId
        temp.Fashioning = heroData.Fashioning
        temp.Level = heroData.Lvl
        temp.Advance = heroData.Advance
        table.insert(exHeroInfo.HeroInfo, temp)
      end
    end
    exHeroInfo.StrategyId = 0
    table.insert(heroList, exHeroInfo)
  end
  return heroList
end

return PresetFleetLogic
