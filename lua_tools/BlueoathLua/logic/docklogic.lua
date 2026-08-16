local DockLogic = class("logic.DockLogic")

function DockLogic:initialize()
  self:ResetData()
  self:RegisterAllEvent()
end

function DockLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.DismantleSuccess, self._OnDeleteEquipOk, self)
end

function DockLogic:RecordSelectShip(shipTab)
  self.intensifySelect = shipTab
end

function DockLogic:CheckIntensify()
  for i, v in ipairs(self.intensifySelect) do
    local heroInfo = Data.heroData:GetHeroById(v)
    if next(heroInfo.Intensify) == nil then
      return true
    end
  end
  return false
end

function DockLogic:ResetData()
  self.index = 0
  self.sortway = true
  self.sortParam = {
    {},
    2
  }
  self.isDefalut = true
  self.m_tabHeroEquipInfo = {}
  self.m_studyButtomData = {
    sortWay = true,
    sortParams = {
      {},
      2
    }
  }
  self.intensifySelect = nil
  self.m_buttomData = {
    sortWay = true,
    sortParams = {
      {},
      2
    }
  }
end

function DockLogic:GetCurrShipCount()
  local tabHaveHero = Data.heroData:GetHeroData()
  local count = 0
  for k, v in pairs(tabHaveHero) do
    count = count + 1
  end
  return count
end

function DockLogic:IsReachMax()
  local shipTotal = Logic.shipLogic:GetBaseShipNum()
  local cur = self:GetCurrShipCount()
  return shipTotal <= cur
end

function DockLogic:SetSelectData(selectData)
  self.isDefalut = false
  self.index = selectData[1]
  self.sortway = selectData[2]
  self.sortParam = selectData[3]
end

function DockLogic:GetSelectData()
  if self.isDefalut then
    self.selectData = {
      0,
      true,
      {
        {},
        2
      }
    }
  else
    self.selectData[1] = self.index
    self.selectData[2] = self.sortway
    self.selectData[3] = self.sortParam
  end
  return self.selectData
end

function DockLogic:CalculatePropIndex(tabShipInfo, showPropNum)
  if tabShipInfo == nil then
    return 0
  end
  local temp = Logic.attrLogic:GetHeroFinalShowAttrById(tabShipInfo.HeroId)
  local tabTemp = Logic.attrLogic:DealTabPropDock(temp, tabShipInfo.HeroId)
  return math.ceil(#tabTemp / showPropNum)
end

function DockLogic:FilterShipList(dockListType, heroId, templateId)
  if dockListType ~= DockListType.All and dockListType ~= DockListType.SameTid and heroId == nil then
    logError("Dock Modules:heroId can't equip nil with " .. dockListType .. "type")
  end
  if dockListType == DockListType.SameTid and templateId == nil then
    logError("Dock Modules:templateId can't equip nil with " .. dockListType .. "type")
  end
  local tabTemp = {}
  local tabHeroList = Data.heroData:GetHeroData()
  if tabHeroList == nil then
    logError("Dock Modules:Fail to get heroList")
  end
  local Tid
  if heroId == nil then
    Tid = templateId
  else
    Tid = Data.heroData:GetHeroById(heroId).TemplateId
  end
  for k, v in pairs(tabHeroList) do
    if dockListType == DockListType.All then
      tabTemp[#tabTemp + 1] = v
    elseif dockListType == DockListType.OutSelf then
      if heroId ~= k then
        tabTemp[#tabTemp + 1] = v
      end
    elseif dockListType == DockListType.SameTid then
      if v.TemplateId == Tid then
        tabTemp[#tabTemp + 1] = v
      end
    elseif dockListType == dockListType.SameTidOutSelf then
      if v.TemplateId == Tid and heroId ~= k then
        tabTemp[#tabTemp + 1] = v
      end
    else
      logError("Dock Modules:There is't " .. dockListType .. " filter type ")
    end
  end
  return tabTemp
end

function DockLogic:FilterByType(herolist, types)
  local res = {}
  for _, typ in ipairs(types) do
    for _, info in pairs(herolist) do
      if info.type == typ then
        res[#res + 1] = info
      end
    end
  end
  return res
end

function DockLogic:FilterByTids(herolist, tids)
  local res = {}
  for _, tid in ipairs(tids) do
    for _, info in pairs(herolist) do
      local si_id = Logic.shipLogic:GetShipInfoIdByTid(info.TemplateId)
      if si_id == tid then
        res[#res + 1] = info
      end
    end
  end
  return res
end

function DockLogic:GetSlotValue(totalNums, columns)
  local slotValue = 0
  if totalNums % 6 == 0 then
    slotValue = totalNums
  else
    slotValue = totalNums + 6 - totalNums % 6
  end
  return slotValue
end

function DockLogic:GetIndexByHeroId(tabHero, heroId)
  if heroId == nil then
    return 0
  end
  for k, v in pairs(tabHero) do
    if v.HeroId == heroId then
      return k
    end
  end
  return 0
end

function DockLogic:SetStudyButtom(tabData)
  self.m_studyButtomData.sortWay = tabData.sortWay
  self.m_studyButtomData.sortParams = tabData.sortParams
end

function DockLogic:GetStudyButtom()
  return self.m_studyButtomData
end

function DockLogic:SetSortButtom(tabData)
  self.m_buttomData.sortWay = tabData.sortWay
  self.m_buttomData.sortParams = tabData.sortParams
end

function DockLogic:GetSortButtom()
  return self.m_buttomData
end

function DockLogic:GetSelectShipInfo(tabSelectId)
  local tabHeroConfInfo = {}
  for k, v in pairs(tabSelectId) do
    local hero = Data.heroData:GetHeroById(v)
    if hero then
      local shipbreakConf = configManager.GetDataById("config_ship_main", hero.TemplateId).break_down_get
      for k, v in pairs(shipbreakConf) do
        table.insert(tabHeroConfInfo, v)
      end
    end
  end
  return tabHeroConfInfo
end

function DockLogic:GetHeroRetireReward(tabSelectId)
  local base = self:GetSelectShipInfo(tabSelectId)
  base = Logic.equipLogic:MergeSameRes(base)
  return base
end

function DockLogic:GetRetireRewardInfo(reward)
  local configInfo
  local goldNum = 0
  local supplyNum = 0
  local medalNum = 0
  local i = 1
  for index = 1, #reward do
    configInfo = Logic.shopLogic:GetTable_Index_Info(reward[index])
    if configInfo.id == CurrencyType.GOLD then
      goldNum = reward[1][3]
    end
    if configInfo.id == CurrencyType.SUPPLY then
      supplyNum = reward[2][3]
    end
    if configInfo.id == CurrencyType.RETIRE then
      medalNum = reward[3][3]
    end
  end
  return goldNum, supplyNum, medalNum
end

function DockLogic:SetHeroEquipsInfo(equipIds)
  self.m_tabHeroEquipInfo = {}
  for _, id in ipairs(equipIds) do
    if Logic.equipLogic:CanDelectById(id) then
      table.insert(self.m_tabHeroEquipInfo, id)
    end
  end
end

function DockLogic:GetHeroEquipsInfo()
  return self.m_tabHeroEquipInfo
end

function DockLogic:_OnDeleteEquipOk()
  local auto = Logic.equipLogic:GetAutoDelete()
  if auto then
    self:ResetHeroEquipsInfo()
  end
end

function DockLogic:ResetHeroEquipsInfo()
  self.m_tabHeroEquipInfo = {}
end

function DockLogic:GetHerosEquipInfo(HeroIds)
  local fleetType = FleetType.Normal
  local tabEquip = {}
  local equips = {}
  for _, heroId in pairs(HeroIds) do
    equips = Data.heroData:GetEquipsByType(heroId, fleetType)
    for _, v in pairs(equips) do
      if v.EquipsId ~= 0 then
        table.insert(tabEquip, v.EquipsId)
      end
    end
  end
  return tabEquip
end

function DockLogic:SroreHeroEquipInfo(HeroIds)
  local equipIds = self:GetHerosEquipInfo(HeroIds)
  self:SetHeroEquipsInfo(equipIds)
end

function DockLogic:EquipDeleteTipWRAP()
  local equipIds = self:GetHeroEquipsInfo()
  local equipLogic = Logic.equipLogic
  if next(equipIds) ~= nil then
    local auto = equipLogic:GetAutoDelete()
    local high = equipLogic:HaveHighQualityEquip(equipIds)
    if auto and not high then
      Service.equipService:SendDismantleEquip(equipIds)
    else
      UIHelper.OpenPage("EquipDismantleTip")
    end
  end
end

return DockLogic
