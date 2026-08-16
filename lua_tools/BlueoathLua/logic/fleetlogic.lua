local FleetLogic = class("logic.FleetLogic")
FleetLogic.m_curBattleFleetId = {}
FleetCardType = {FleetCard = 1, FleetHeroCard = 2}
local SupplyToGasoId = 1
local SupplyToBulletId = 2
local GuideNeedFleetId = 1
local m_tabFleetName = {
  2400001,
  2400002,
  2400003,
  2400004,
  2400005
}

function FleetLogic:initialize()
  self.m_imageFleetShip = nil
  self:ResetData()
  self:RegisterAllEvent()
end

function FleetLogic:ResetData()
  self.guideFlag = false
  self.curSelectTog = 1
  self.heroCommonData = nil
  self.heroScrollPos = 0
  self.attackAdditionTab = {}
  self.m_hideAutoTip = false
end

function FleetLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.TowerReceiveBuff, self.ResetTowerAttack, self)
  eventManager:RegisterEvent(LuaEvent.TowerActivityReceiveBuff, self.ResetActTowerAttack, self)
  eventManager:RegisterEvent(LuaEvent.HERO_TryUpdateHeroExData, self.ResetAttack, self)
end

function FleetLogic:SetScrollPos(pos)
  self.heroScrollPos = pos < 0 and 0 or pos
end

function FleetLogic:GetScrollPos()
  return self.heroScrollPos
end

function FleetLogic:SetImageFleetShip(imageFleetShip, fleetType)
  fleetType = fleetType ~= nil and fleetType or FleetType.Normal
  if self.m_imageFleetShip == nil then
    self.m_imageFleetShip = {}
  end
  self.m_imageFleetShip[fleetType] = imageFleetShip
end

function FleetLogic:GetImageFleetShip(fleetId, fleetType)
  if self.m_imageFleetShip and self.m_imageFleetShip[fleetType] then
    return self.m_imageFleetShip[fleetType][fleetId]
  end
  return nil
end

function FleetLogic:SetImageStrategy(fleetList)
  if self.m_imageFleetShip then
    for type, fleet in ipairs(fleetList) do
      local temp = {}
      for fleetId, v in ipairs(fleet) do
        if temp[fleetId] then
          temp[fleetId].strategyId = v.strategyId
        end
      end
      self.m_imageFleetShip[type] = temp
    end
  end
end

function FleetLogic:SetSelectTog(index)
  self.curSelectTog = index
end

function FleetLogic:GetSelectTog()
  return self.curSelectTog
end

function FleetLogic:GetGuideFlag()
  return self.guideFlag
end

function FleetLogic:SetGuideFlag(param)
  self.guideFlag = param
end

function FleetLogic:ChangeHeroTable()
  local tabHero = Data.heroData:GetHeroData()
  local newTab = {}
  for k, v in pairs(tabHero) do
    table.insert(newTab, v)
  end
  return newTab
end

function FleetLogic:GetFleetName(fleetId, fleetType)
  if fleetType == FleetType.Preset then
    return "\233\162\132\232\174\190\232\136\176\233\152\159"
  end
  if Logic.towerLogic:IsTowerType(fleetType) then
    return UIHelper.GetString(1700034)
  end
  local fleetInfo = Data.fleetData:GetFleetData(fleetType)
  local name = fleetInfo[fleetId].tacticName
  if name == "" then
    name = UIHelper.GetString(m_tabFleetName[fleetId])
  end
  return name
end

function FleetLogic:InitFleetInfo(tabFleet)
  for i = 1, #tabFleet do
    if tabFleet[i].tacticName == "" then
      tabFleet[i].tacticName = UIHelper.GetString(m_tabFleetName[i])
      tabFleet[i].modeId = i
    end
  end
  return tabFleet
end

function FleetLogic:CheckOnFleet(fleetHid, heroId)
  for i = 1, #fleetHid do
    for k, v in pairs(fleetHid[i]) do
      if k == heroId then
        return true, i
      end
    end
  end
  return false
end

function FleetLogic:CheckOnSameFleet(fleetHid, heroId)
  for k, v in pairs(fleetHid) do
    if k == heroId then
      return true
    end
  end
  return false
end

function FleetLogic:GetFleetTemplateId(mType)
  local heroData = Data.heroData:GetHeroData()
  local fleetTemplateId = {}
  local heroIdTab = Logic.fleetLogic:GetFleetHeroId(mType)
  for i = 1, #heroIdTab do
    fleetTemplateId[i] = {}
    for k, v in pairs(heroIdTab[i]) do
      if heroData[k] ~= nil then
        local shipId = heroData[k].TemplateId
        fleetTemplateId[i][shipId] = heroData[k].HeroId
      end
    end
  end
  return fleetTemplateId
end

function FleetLogic:CheckFleetTid(fleetTid, heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  for tid, hero in pairs(fleetTid[self.curSelectTog]) do
    local hero = Data.heroData:GetHeroById(hero)
    local isSameShip = Logic.shipLogic:CheckSameShipMain(heroInfo.TemplateId, tid)
    if isSameShip then
      return fleetTid, true
    end
  end
  fleetTid[self.curSelectTog][heroInfo.TemplateId] = heroId
  return fleetTid, false
end

function FleetLogic:RemoveFleetTid(fleetTid, heroId)
  for i = 1, #fleetTid do
    for k, v in pairs(fleetTid[i]) do
      if v == heroId then
        fleetTid[i][k] = nil
        return fleetTid
      end
    end
  end
  return fleetTid
end

function FleetLogic:IsHasFleet(mType)
  local fleetData = Data.fleetData:GetFleetData(mType)
  for k, v in pairs(fleetData) do
    if v.heroInfo and #v.heroInfo > 0 then
      return true
    end
  end
  return false
end

function FleetLogic:GetShipDataListByFleet(fleetId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local heroDataList = {}
  local shipIds = Data.fleetData:GetShipByFleet(fleetId, fleetType)
  for i, shipId in ipairs(shipIds) do
    local heroData = Data.heroData:GetHeroById(shipId)
    table.insert(heroDataList, heroData)
  end
  return heroDataList
end

function FleetLogic:GetSplitFleets(splitTeam, shipList)
  local fleetList = {}
  local fleetIndex = 1
  if 1 < #splitTeam then
    for _, team in ipairs(splitTeam) do
      local singleFleet = {}
      for _, index in ipairs(team) do
        if table.containKey(shipList, index) then
          table.insert(singleFleet, shipList[index])
        end
      end
      if 0 < #singleFleet then
        fleetList[fleetIndex] = singleFleet
        fleetIndex = fleetIndex + 1
      end
    end
  end
  return fleetList
end

function FleetLogic:SetBattleFleetId(fleetId, fleetType)
  fleetType = fleetType ~= nil and fleetType or FleetType.Normal
  self.m_curBattleFleetId[fleetType] = fleetId
  if Logic.towerLogic:IsTowerType(fleetType) then
    self.attackAdditionTab[fleetType] = {}
  end
end

function FleetLogic:GetBattleFleetId(fleetType)
  fleetType = fleetType ~= nil and fleetType or FleetType.Normal
  local curFleetId = 1
  if self.m_curBattleFleetId[fleetType] ~= nil then
    curFleetId = self.m_curBattleFleetId[fleetType]
  end
  return curFleetId
end

function FleetLogic:GetShipExp(dictId, bFlag, bMVP, evaluate, bNotJoin)
  local config = configManager.GetDataById("config_fleet", dictId)
  local flagRatio = configManager.GetDataById("config_parameter", 33).value
  local mvpRatio = configManager.GetDataById("config_parameter", 32).value
  local evaluateArr = configManager.GetDataById("config_parameter", 34).arrValue
  if bNotJoin then
    return 0
  end
  local basic = config.ship_exp
  local finalExp = basic
  if bFlag then
    finalExp = finalExp * flagRatio * 1.0E-4
  end
  if bMVP then
    finalExp = finalExp * mvpRatio * 1.0E-4
  end
  finalExp = finalExp * evaluateArr[evaluate] * 1.0E-4
  return finalExp
end

function FleetLogic:GetShipBaseExp(enemyFleetId)
  return configManager.GetDataById("config_fleet", enemyFleetId).ship_exp
end

function FleetLogic:GetPlayerExp(num)
  local config = configManager.GetDataById("config_parameter", 52)
  return config.arrValue[num] or 0
end

function FleetLogic:GetSupplyToGaso()
  local gaso = configManager.GetDataById("config_parameter", SupplyToGasoId).value
  return gaso
end

function FleetLogic:GetSupplyToBullet()
  local bullet = configManager.GetDataById("config_parameter", SupplyToBulletId).value
  return bullet
end

function FleetLogic:GetHeroFleetMap()
  local result = Data.fleetData:GetHeroInFleetId()
  return result
end

function FleetLogic:IsLastFleet(f_id)
  local config = configManager.GetDataById("config_fleet", f_id)
  return config.is_last_fleet == 1
end

function FleetLogic:RmvHeroinFleet(heroId)
  local data = Data.fleetData:GetFleetData()
  local tabFleetData = clone(data)
  for k, v in pairs(tabFleetData) do
    for key, value in pairs(v.heroInfo) do
      if value == heroId then
        table.remove(v.heroInfo, key)
      end
    end
  end
  local tacticsTab = {tactics = tabFleetData}
  Service.fleetService:SendSetFleet(tacticsTab)
end

function FleetLogic:RmvHerosinFleet(tabHeroId)
  local data = Data.fleetData:GetFleetData()
  local tabFleetData = clone(data)
  for _, heroId in ipairs(tabHeroId) do
    for _, fleetInfo in ipairs(tabFleetData) do
      for key, value in pairs(fleetInfo.heroInfo) do
        if value == heroId then
          table.remove(fleetInfo.heroInfo, key)
        end
      end
    end
  end
  local tacticsTab = {tactics = tabFleetData}
  Service.fleetService:SendSetFleet(tacticsTab)
end

function FleetLogic:GetMaxPower()
  local data = Data.fleetData:GetFleetData()
  local tabFleetData = clone(data)
  local maxpower = 0
  local maxpoweridx = 0
  local minpower = 2000000000
  local minpoweridx = 0
  for index, fleetInfo in ipairs(tabFleetData) do
    local totalAttack = 0
    local heroInfo = fleetInfo.heroInfo
    if heroInfo ~= nil then
      for _, heroId in ipairs(heroInfo) do
        local heroAttr = Logic.attrLogic:GetBattlePower(heroId, self.fleetType)
        totalAttack = totalAttack + heroAttr
      end
    end
    if maxpower < totalAttack then
      maxpower = totalAttack
      maxpoweridx = index
    end
    if minpower > totalAttack then
      minpower = totalAttack
      minpoweridx = index
    end
  end
  if maxpower <= Data.fleetData:GetMaxPower() then
    maxpoweridx = nil
  end
  if minpower <= Data.fleetData:GetMinPower() then
    minpoweridx = nil
  end
  return maxpoweridx, minpoweridx
end

function FleetLogic:GetFleetHeroSfId()
  local data = Data.fleetData:GetFleetData()
  local res = {}
  for _, fleetInfo in ipairs(data) do
    for _, heroId in pairs(fleetInfo.heroInfo) do
      local tid = Data.heroData:GetHeroById(heroId).TemplateId
      local sf_id = Logic.shipLogic:GetSfidBySmid(tid)
      table.insert(res, sf_id)
    end
  end
  return res
end

function FleetLogic:GetHeroFleetName(heroId)
  local fleetInfo = Data.fleetData:GetFleetData()
  for index, info in ipairs(fleetInfo) do
    if table.containV(info.heroInfo, heroId) then
      return info.tacticName, index
    end
  end
  return ""
end

function FleetLogic:CheckOnFleetSameFId(fleetData, tId)
  local heroInfoTab = fleetData[self.curSelectTog].heroInfo
  for i, v in ipairs(heroInfoTab) do
    local heroInfo = Data.heroData:GetHeroById(v)
    local isSameShip = Logic.shipLogic:CheckSameShipMain(heroInfo.TemplateId, tId)
    if isSameShip then
      return true
    end
  end
  return false
end

function FleetLogic:GetFleetHeroId(mType)
  local fleetInfo = Data.fleetData:GetFleetData(mType)
  local shipIds = {}
  if fleetInfo ~= nil then
    for i = 1, #fleetInfo do
      shipIds[i] = {}
      for j = 1, #fleetInfo[i].heroInfo do
        local temp = fleetInfo[i].heroInfo[j]
        shipIds[i][temp] = i
      end
    end
  end
  return shipIds
end

function FleetLogic:CheckOnOtherFleet(heroId, fleetHid)
  for i, v in ipairs(fleetHid) do
    if v[heroId] ~= nil and i ~= self.curSelectTog then
      return true
    end
  end
  return false
end

function FleetLogic:CheckIsOnFleet(heroId, fleetHid)
  for i, v in ipairs(fleetHid) do
    if v[heroId] ~= nil and i ~= self.curSelectTog then
      return true, v[heroId]
    end
  end
  return false, nil
end

function FleetLogic:GetCurFleetName(curFleetTab, heroId)
  for index, info in ipairs(curFleetTab) do
    if table.containV(info.heroInfo, heroId) then
      return info.tacticName, index
    end
  end
  return ""
end

function FleetLogic:RemoveFleetHero(curFleetTab, dragId)
  for i = 1, #curFleetTab do
    for k, _ in pairs(curFleetTab[i]) do
      if i == self.curSelectTog then
        break
      end
      if k == dragId then
        curFleetTab[i][k] = nil
        return curFleetTab
      end
    end
  end
  return curFleetTab
end

function FleetLogic:PlatformDotSaveFleet(curFleetTab, changeIdTab, fleetType)
  local fleetInfo = Data.fleetData:GetFleetData()
  local teamNum = {}
  local team = {}
  for _, v in pairs(changeIdTab) do
    table.insert(teamNum, v)
    oldFleetH = fleetInfo[v].heroInfo
    newFleetH = curFleetTab[v].heroInfo
    local sub_team = {}
    if next(newFleetH) == nil then
      table.insert(team, sub_team)
    else
      for k, heroId in pairs(newFleetH) do
        if heroId ~= oldFleetH[k] then
          heroInfo = Data.heroData:GetHeroById(heroId)
          local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
          sub_team[tostring(k)] = shipInfo.ship_name
        end
      end
      table.insert(team, sub_team)
    end
  end
  local dotInfo = {
    info = "battleship_team",
    team_num = teamNum,
    team = team,
    type = fleetType - 1
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function FleetLogic:GetFleetHeroInfo(curFleetTab, allHeroInfo)
  local tempTab = {}
  for _, heroInfo in ipairs(allHeroInfo) do
    tempTab[heroInfo.HeroId] = heroInfo
  end
  local fleetHero = {}
  local otherHero = {}
  for _, v in ipairs(curFleetTab) do
    local fleetHeroTab = v.heroInfo
    for _, heroId in ipairs(fleetHeroTab) do
      if tempTab[heroId] ~= nil then
        table.insert(fleetHero, tempTab[heroId])
        tempTab[heroId] = nil
      end
    end
  end
  for _, v in pairs(tempTab) do
    table.insert(otherHero, v)
  end
  return fleetHero, otherHero
end

function FleetLogic:FleetHeroSort(curFleetTab, allHeroInfo, filterRule, sortRule, descend, recommend, fleetType)
  local fleetHero, otherHero = self:GetFleetHeroInfo(curFleetTab, allHeroInfo)
  if next(fleetHero) ~= nil then
    if Logic.towerLogic:IsTowerType(fleetType) then
      fleetHero = HeroSortHelper.FilterAndSort(fleetHero, filterRule, sortRule, descend, recommend, fleetType)
    else
      fleetHero = HeroSortHelper.FilterAndSort(fleetHero, filterRule, sortRule, descend, recommend)
    end
  end
  if next(otherHero) ~= nil then
    if Logic.towerLogic:IsTowerType(fleetType) then
      otherHero = HeroSortHelper.FilterAndSort(otherHero, filterRule, sortRule, descend, recommend, fleetType)
    else
      otherHero = HeroSortHelper.FilterAndSort(otherHero, filterRule, sortRule, descend, recommend)
    end
  end
  if next(fleetHero) ~= nil then
    table.insertto(fleetHero, otherHero)
    return fleetHero
  else
    return otherHero
  end
end

function FleetLogic:GetShipNumByFleet(fleetId, shipType)
  local fleetData = Data.fleetData:GetFleetDataById(fleetId)
  local heroInfo = fleetData.heroInfo
  local result = 0
  if heroInfo then
    for index, heroId in ipairs(heroInfo) do
      local typ = Logic.shipLogic:GetHeroTypeByHeroId(heroId)
      if shipType == typ then
        result = result + 1
      end
    end
  end
  return result
end

function FleetLogic:GetShipTableByFleet(fleetId, typ)
  local fleetData = Data.fleetData:GetFleetDataById(fleetId, typ)
  return fleetData.heroInfo
end

function FleetLogic:SetCommonHeroData(heroData)
  self.heroCommonData = heroData
end

function FleetLogic:GetCommonHeroData()
  return self.heroCommonData
end

function FleetLogic:IsShipLocked(fleetData, heroId)
  local lockedMap = fleetData and fleetData.lockedHeroMap or nil
  if lockedMap and lockedMap[heroId] then
    return true
  end
  return false
end

function FleetLogic:GetCurFleetAttr()
  local curFleetShip = Data.fleetData:GetShipByFleet(self.curSelectTog)
  local totalAttack = 0
  for _, v in pairs(curFleetShip) do
    local heroAttr = Logic.attrLogic:GetBattlePower(v)
    totalAttack = totalAttack + heroAttr
  end
  return totalAttack
end

function FleetLogic:GetFleetPower(fleetId, fleetType)
  local fleetShip = Data.fleetData:GetShipByFleet(fleetId, fleetType)
  local totalAttack = 0
  for _, v in pairs(fleetShip) do
    local heroAttr = Logic.attrLogic:GetBattlePower(v, fleetType)
    totalAttack = totalAttack + heroAttr
  end
  return totalAttack
end

function FleetLogic:CheckFleetAttackConditions(heroInfo, continueCallback, fleetType, copyInfo)
  local displayConfig = Logic.copyLogic:GetCopyDesConfig(copyInfo.copyId)
  local chapterConfig = configManager.GetDataById("config_chapter", copyInfo.chapterId)
  if not (not copyInfo.copyImp or copyInfo.copyImp:CheckTime()) or not copyInfo.copyImp:CheckActCondition() then
    return false
  end
  local checkGameLimit, descId = self:_CheckGameLimit(displayConfig)
  if not checkGameLimit then
    noticeManager:ShowMsgBox(UIHelper.GetLocString(610002, UIHelper.GetLocString(descId)))
    return false
  end
  local canSupply = self:_UserSupplyNumIsEnough(heroInfo, displayConfig)
  if not canSupply then
    UIHelper.OpenPage("BuyResourcePage", BuyResource.Supply)
    return false
  end
  if chapterConfig.class_type == ChapterType.DailyCopy then
    local dailyCopyInfo, dailyGroupId = Logic.dailyCopyLogic:GetDCBattleInfo()
    if not self:_CheckDailyCopyOpen(dailyCopyInfo) then
      noticeManager:ShowTip(UIHelper.GetString(410005))
      return false
    end
    local girlLevelType = dailyCopyInfo.ship_level_type
    result = copyInfo.copyImp.ShipLevelFunc[girlLevelType]()
    if not result then
      noticeManager:ShowTip("\230\136\152\229\167\172\231\173\137\231\186\167\228\184\141\229\164\159")
      return false
    end
  end
  if #heroInfo <= 0 then
    noticeManager:OpenTipPage(self, 110007)
    return false
  end
  if fleetType == FleetType.Tower then
    local towerCopyId = Logic.towerLogic:GetCopyIdNow()
    if towerCopyId ~= copyInfo.copyId then
      noticeManager:ShowTipById(1700038)
      return false
    end
    local minNum = configManager.GetDataById("config_parameter", 211).value
    if minNum > #heroInfo then
      noticeManager:OpenTipPage(self, 1700033)
      return false
    end
    if copyInfo.exercises == BattleMode.Normal then
      local canBattle = Logic.towerLogic:CheckFleetBattleCount(heroInfo, chapterConfig.relation_chapter_id)
      if not canBattle then
        return false
      end
    end
  end
  if copyInfo.exercises ~= BattleMode.Normal then
    local exercisesPoint = Data.userData:GetCurrency(CurrencyType.EXERCISES)
    local displayConfig = Logic.copyLogic:GetCopyDesConfig(copyInfo.copyId)
    if exercisesPoint < displayConfig.exercises_point then
      noticeManager:OpenTipPage(self, 1701001)
      return false
    end
    continueCallback()
    return
  end
  if Logic.copyLogic:CheckFlagShipDamage(heroInfo) then
    noticeManager:ShowMsgBox(110011)
    return false
  end
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(toRetire)
        if toRetire then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("HeroRetirePage")
        end
      end
    }
    noticeManager:ShowMsgBox(110012, tabParams)
    return false
  end
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(toEquip)
        if toEquip then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("DismantlePage")
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(1000014), tabParams)
    return false
  end
  if Logic.copyLogic:CheckShipSink(heroInfo) then
    noticeManager:ShowMsgBox(UIHelper.GetString(1000015))
    return false
  end
  local anyDamage = Logic.copyLogic:CheckAnyShipDamage(heroInfo)
  if fleetType == FleetType.Tower and copyInfo.exercises == BattleMode.Normal then
    if anyDamage then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(goBattle)
          if goBattle then
            UIHelper.OpenPage("TowerLockWarnPage", {
              callback = function()
                continueCallback()
              end
            })
          end
        end
      }
      noticeManager:ShowMsgBox(110013, tabParams)
      return false
    else
      UIHelper.OpenPage("TowerLockWarnPage", {
        callback = function()
          continueCallback()
        end
      })
    end
  elseif anyDamage then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(goBattle)
        if goBattle then
          continueCallback()
        end
      end
    }
    noticeManager:ShowMsgBox(110013, tabParams)
    return false
  else
    continueCallback()
  end
  return true
end

function FleetLogic:_CheckDailyCopyOpen(copyInfo)
  local weekDay = time.getWeekday()
  local weeks = copyInfo.is_available
  for k, v in pairs(weeks) do
    if weekDay == v then
      return true
    end
  end
  return false
end

function FleetLogic:_CheckGameLimit(displayConfig)
  local limitIds = displayConfig.ship_limit
  local pass = true
  for k, limitId in pairs(limitIds) do
    if not Logic.gameLimitLogic.CheckConditionById(limitId, self.curSelectTog) then
      pass = false
      break
    end
  end
  return pass, displayConfig.shiplimit_desc
end

function FleetLogic:_UserSupplyNumIsEnough(heroInfo, desConfInfo)
  local _, expend = self:_GetSupplyNum(heroInfo, desConfInfo)
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  if expend <= supply then
    return true
  end
  return false
end

function FleetLogic:_GetSupplyNum(heroInfo, desConfInfo)
  if #heroInfo == 0 then
    return 0, 0
  end
  local expend = 0
  local count = #heroInfo
  local config = Logic.copyLogic:GetCopyDesConfig(desConfInfo.id).total_supple_num
  expend = config[count]
  return count, expend
end

function FleetLogic:CanAddFleetHeroNum()
  local retTab = {}
  local fleetSfIdTab = {}
  local tabHero = Data.heroData:GetHeroData()
  local fleetHeroInfo = Data.fleetData:GetHeroInFleetId()
  for heroId, v in pairs(fleetHeroInfo) do
    if v == GuideNeedFleetId then
      local siId = Logic.shipLogic:GetShipInfoId(tabHero[heroId].TemplateId)
      local sfId = Logic.shipLogic:GetShipFleetId(siId)
      fleetSfIdTab[sfId] = v
    end
  end
  for _, heroInfo in pairs(tabHero) do
    local siId = Logic.shipLogic:GetShipInfoId(heroInfo.TemplateId)
    local sfId = Logic.shipLogic:GetShipFleetId(siId)
    if fleetSfIdTab[sfId] == nil then
      table.insert(retTab, heroInfo)
    end
  end
  return #retTab
end

function FleetLogic:GetAttackAddition(heroInfo, attack, fleetType)
  if self.attackAdditionTab[fleetType] == nil then
    self.attackAdditionTab[fleetType] = {}
  end
  if self.attackAdditionTab[fleetType][heroInfo.HeroId] == nil then
    local hurtPer = Logic.towerLogic:CalTowerHurtPer(heroInfo.TemplateId, fleetType)
    self.attackAdditionTab[fleetType][heroInfo.HeroId] = math.round(attack * (hurtPer / 100))
  end
  return self.attackAdditionTab[fleetType][heroInfo.HeroId]
end

function FleetLogic:GetFleetNum(fleetType)
  local fleetNum = Data.fleetData:GetFleetData(fleetType)
  return #fleetNum
end

function FleetLogic:ResetTowerAttack()
  self.attackAdditionTab[FleetType.Tower] = {}
end

function FleetLogic:ResetActTowerAttack()
  self.attackAdditionTab[FleetType.LimitTower] = {}
end

function FleetLogic:ResetAttack()
  self.attackAdditionTab = {}
end

function FleetLogic:GetFleetAttr(fleetHero)
  local totalAttack = 0
  local totalFire = 0
  local maxSpeed = 0
  for _, heroId in ipairs(fleetHero) do
    local heroAttack = Logic.attrLogic:GetBattlePower(heroId)
    totalAttack = totalAttack + heroAttack
    local heroAttr = Logic.attrLogic:GetHeroFinalShowAttrById(heroId)
    totalFire = totalFire + heroAttr[AttrType.ATTACK_GRADE]
    maxSpeed = maxSpeed + heroAttr[AttrType.SPEED]
  end
  maxSpeed = math.floor(maxSpeed / #fleetHero)
  return totalAttack, totalFire, maxSpeed
end

function FleetLogic:HerosAutoEquipWrap(fleetType, fleetHeros)
  local ok, res = self:GetAutoAddHeros(fleetType, fleetHeros)
  if not ok then
    return false, res
  else
    ok, res = Logic.equipLogic:AutoAddHerosEquip(res, fleetType, true)
    if not ok then
      return false, res
    end
    return true, ""
  end
end

function FleetLogic:HerosAutoUnEquipWrap(fleetType)
  local heros = Data.heroData:GetHeroData()
  local arg = {}
  local equipLogic = Logic.equipLogic
  for id, _ in pairs(heros) do
    if equipLogic:UnEquipHeroFiler(id, fleetType) then
      table.insert(arg, id)
    end
  end
  if #arg <= 0 then
    return false, UIHelper.GetString(1704011)
  end
  local ok, res = Logic.equipLogic:AutoAddHerosEquip(arg, fleetType, false)
  if not ok then
    return false, res
  end
  return true, ""
end

function FleetLogic:GetAutoAddHeros(fleetType, fleetHeros)
  fleetHeros = fleetHeros or {}
  local data = Data.heroData
  local filter = function(info)
    if info then
      local open = false
      local equips = data:GetEquipsByType(info.HeroId, fleetType)
      for _, id in ipairs(equips) do
        if id.state == MEquipState.OPEN then
          open = true
          break
        end
      end
      return info.Lvl > 1 and open
    else
      return false
    end
  end
  local option = self:GetAutoOption()
  local max = self:_GetAutoMax()
  local fleets, fleetMap = {}, {}
  local bf, bo = true, true
  for _, id in ipairs(fleetHeros) do
    local info = data:GetHeroById(id)
    if filter(info) then
      table.insert(fleets, info)
      fleetMap[id] = true
    end
  end
  bf = 0 < #fleets
  local res = HeroSortHelper.AutoEquipSortAndFilter(fleets, option, #fleets, true, {FleetType = fleetType})
  local len = max - #fleets
  if 0 < len then
    local all = data:GetHeroData()
    local candidate = {}
    for id, v in pairs(all) do
      if filter(v) and not fleetMap[id] then
        table.insert(candidate, v)
      end
    end
    bo = 0 < #candidate
    local other = HeroSortHelper.AutoEquipSortAndFilter(candidate, option, max - #fleets, true, {FleetType = fleetType})
    table.insertto(res, other)
  end
  if not bf and not bo then
    return false, UIHelper.GetString(1704002)
  end
  return true, res
end

function FleetLogic:_GetAutoMax()
  return configManager.GetDataById("config_parameter", 355).value
end

function FleetLogic:GetAutoOption()
  local value = Data.guideData:GetSettingByKey("LOGIC_FLEET_ALLEQUIPOPTION")
  return value and Unserialize(value) or AutoAddOption.FIGHT
end

function FleetLogic:GetHideAutoTip()
  return self.m_hideAutoTip
end

function FleetLogic:GetHideAutoField()
  local playerPrefsKey = PlayerPrefsKey.FleetAutoAddTip
  local tgIsON = false
  if playerPrefsKey then
    tgIsON = PlayerPrefs.GetBool(playerPrefsKey, false)
  end
  self.m_hideAutoTip = tgIsON
  return tgIsON
end

function FleetLogic:SetAutoOption(option)
  Service.guideService:SendUserSetting({
    {
      Key = "LOGIC_FLEET_ALLEQUIPOPTION",
      Value = tostring(option)
    }
  })
end

function FleetLogic:SetHideAutoField(bool)
  local playerPrefsKey = PlayerPrefsKey.FleetAutoAddTip
  if playerPrefsKey then
    PlayerPrefs.SetBool(playerPrefsKey, bool)
  end
  self.m_hideAutoTip = bool
end

function FleetLogic:CheckFleetHeroNum(copyId, fleetHeros)
  local result = clone(fleetHeros)
  local displayConfig = Logic.copyLogic:GetCopyDesConfig(copyId)
  local totalCount = displayConfig.assist_fleet_num
  while result and totalCount < #result do
    table.remove(result, #result)
    if #result == 0 then
      break
    end
  end
  return result
end

return FleetLogic
