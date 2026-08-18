local FleetOrderLogic = class("logic.FleetOrderLogic")

function FleetOrderLogic:initialize()
  self.m_tabFleetData = nil
  self.m_fleetType = FleetType.Normal
  self.ExpUpMap = {}
end

function FleetOrderLogic:ResetData()
  local data = Data.fleetData:GetFleetData(self.m_fleetType)
  self.tabFleetData = clone(data)
  self.m_tabFleetData = clone(data)
  self.m_changeFleets = {}
end

function FleetOrderLogic:SetFleetsOrder(setIndex, oriIndex)
  local heroInfo_Ori = clone(self.m_tabFleetData[oriIndex].heroInfo)
  local exHeroInfo_Ori = clone(self.m_tabFleetData[oriIndex].exHeroInfo)
  local strategyId_Ori = clone(self.m_tabFleetData[oriIndex].strategyId)
  self.m_tabFleetData[oriIndex].heroInfo = clone(self.m_tabFleetData[setIndex].heroInfo)
  self.m_tabFleetData[setIndex].heroInfo = heroInfo_Ori
  self.m_tabFleetData[oriIndex].exHeroInfo = clone(self.m_tabFleetData[setIndex].exHeroInfo)
  self.m_tabFleetData[setIndex].exHeroInfo = exHeroInfo_Ori
  self.m_tabFleetData[oriIndex].strategyId = clone(self.m_tabFleetData[setIndex].strategyId)
  self.m_tabFleetData[setIndex].strategyId = strategyId_Ori
  self.m_changeFleets[oriIndex] = true
  self.m_changeFleets[setIndex] = true
  eventManager:SendEvent(LuaEvent.FleetOrderChange)
end

function FleetOrderLogic:GetOrderFleets()
  return self.m_tabFleetData
end

function FleetOrderLogic:SendSetFleetsOrder()
  local tacticsTab = {
    tactics = self.m_tabFleetData
  }
  Service.fleetService:SendSetFleet(tacticsTab)
  local isStrategyFuncOpen = Logic.presetFleetLogic:CheckStrategyFuncOpen()
  if isStrategyFuncOpen then
    local recordData = self.m_tabFleetData
    for recordIndex, _ in pairs(self.m_changeFleets) do
      Service.strategyService:SendApply({
        Id = recordData[recordIndex].strategyId,
        FleetId = recordIndex,
        Level = 1,
        TacticType = recordData[recordIndex].type
      })
    end
  end
end

function FleetOrderLogic:GetCanBattleNvN(copyId)
  local displayConfig = Logic.copyLogic:GetCopyDesConfig(copyId)
  local max_fleet = displayConfig.max_fleet
  local data = Data.fleetData:GetFleetData(self.m_fleetType)
  local tabFleetData = clone(data)
  local fleetList = self:GetEnemyFleets(copyId)
  local enemyNum = #fleetList
  if enemyNum > #tabFleetData then
    logError(" \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174 6 < NvN\230\149\140\230\150\185\232\136\176\233\152\159\230\149\176\233\135\143\239\188\154", enemyNum)
  end
  local battlefleet = {}
  local errMsg = ""
  for index, fleetData in pairs(tabFleetData) do
    if index <= max_fleet then
      local isSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(fleetData.modeId, fleetData.type)
      if isSweeping then
        errMsg = UIHelper.GetString(530003)
        return false, errMsg, nil
      elseif #fleetData.heroInfo > 0 then
        if #fleetData.heroInfo < 6 then
          errMsg = UIHelper.GetString(530004)
          return false, errMsg, nil
        end
        table.insert(battlefleet, fleetData)
      end
    end
  end
  if enemyNum <= #battlefleet then
    if max_fleet > #battlefleet then
      return false, "", battlefleet, true
    else
      return true, "", battlefleet
    end
  else
    errMsg = UIHelper.GetString(530005)
    return false, errMsg, nil
  end
end

function FleetOrderLogic:GetEnemyFleets(copyId)
  local copyConfig = configManager.GetMultiDataByKey("config_copy", "copy_id", copyId)
  local fleetList = {}
  for _, c in pairs(copyConfig) do
    for _, fleetId in pairs(c.fleet_id) do
      table.insert(fleetList, fleetId)
    end
  end
  return fleetList
end

function FleetOrderLogic:GetCopyFleetHeros(copyId, tabFleetData, nToggleIndex)
  local displayConfig = Logic.copyLogic:GetCopyDesConfig(copyId)
  local max_fleet = displayConfig.max_fleet
  local tmpf = {}
  local tmph = {}
  local exTmph = {}
  if 0 < max_fleet then
    for index, fleetData in pairs(tabFleetData) do
      if index <= max_fleet and 0 < #fleetData.heroInfo then
        table.insert(tmpf, fleetData)
        for _, v in pairs(fleetData.heroInfo) do
          table.insert(tmph, v)
        end
        for _, v in pairs(fleetData.exHeroInfo) do
          table.insert(exTmph, v)
        end
      end
    end
  else
    table.insert(tmpf, tabFleetData[nToggleIndex])
    tmph = tabFleetData[nToggleIndex].heroInfo
    exTmph = tabFleetData[nToggleIndex].exHeroInfo
  end
  return tmph, tmpf, exTmph
end

function FleetOrderLogic:GetSequenceMap(copyDisplayId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyDisplayId)
  if #copyDisplay.nvn_ship_exp_up <= 0 or 0 >= copyDisplay.max_fleet then
    self:SetExpUpMap(copyDisplayId, {})
    return {}
  end
  local sids = copyDisplay.nvn_ship_exp_up
  local rule = {}
  for _, sid in pairs(sids) do
    if sid[1] == nil or 0 >= sid[1] then
      self:SetExpUpMap(copyDisplayId, {})
      return {}
    end
    local info = configManager.GetDataById("config_shiplist_sequence", sid[1])
    if 0 >= info.belong then
      logError(" belong <= 0 !! sid:", sid[1])
      self:SetExpUpMap(copyDisplayId, {})
      return {}
    end
    if rule[info.belong - 1] == nil then
      rule[info.belong - 1] = {}
    end
    table.insert(rule[info.belong - 1], info.value)
  end
  local tab_heros = Data.heroData:GetHeroData()
  local tabTemp = HeroSortHelper._Filter(tab_heros, rule)
  local heroMap = {}
  for _, Info in pairs(tabTemp) do
    heroMap[Info.HeroId] = true
  end
  self:SetExpUpMap(copyDisplayId, heroMap)
  return heroMap
end

function FleetOrderLogic:SetExpUpMap(copyDisplayId, heroMap)
  self.ExpUpMap[copyDisplayId] = heroMap
end

function FleetOrderLogic:GetExpUpMap(copyDisplayId)
  if copyDisplayId == 0 then
    return {}
  end
  if self.ExpUpMap[copyDisplayId] == nil and self.ExpUpMap[copyDisplayId] ~= {} then
    return self:GetSequenceMap(copyDisplayId)
  else
    return self.ExpUpMap[copyDisplayId]
  end
end

function FleetOrderLogic:CheckSameHeroInTab(tblBattleFleets)
  local heroMap = {}
  for _, v in pairs(tblBattleFleets) do
    for _, heroid in pairs(v.heroInfo) do
      local heroInfo = Data.heroData:GetHeroById(heroid)
      local si_id = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
      local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
      if heroMap[sf_id] == nil then
        heroMap[sf_id] = {}
      end
      table.insert(heroMap[sf_id], v.modeId)
    end
  end
  local heroTbl = {}
  for characterId, fleets in pairs(heroMap) do
    if 1 < #fleets then
      table.insert(heroTbl, characterId)
    end
  end
  if 0 < #heroTbl then
    return true, heroTbl
  end
  return false, nil
end

return FleetOrderLogic
