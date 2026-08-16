local SortPage = class("UI.Sort.SortPage", LuaUIPage)
local SortIndex = {
  [0] = HeroSortType.Rarity,
  [1] = HeroSortType.Lvl,
  [2] = HeroSortType.Property,
  [3] = HeroSortType.CreateTime,
  [4] = HeroSortType.AttackGrade,
  [5] = HeroSortType.Mood,
  [6] = HeroSortType.BathFleet
}

function SortPage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabTypeIndex = {}
  self.m_tabCampIndex = {}
  self.m_tabRarityIndex = {}
  self.m_tabLockIndex = {}
  self.m_tabEquipTypeIndex = {}
  self.m_tabTypeInfo = nil
  self.m_tabRarityInfo = nil
  self.m_tabCampInfo = nil
  self.m_tabLockInfo = nil
  self.m_tabEquipTypeInfo = nil
  self.m_tabTypeTog = {}
  self.m_tabRarityTog = {}
  self.m_tabCampTog = {}
  self.m_tabLockTog = {}
  self.m_tabEquipTypeTog = {}
  self.m_tabScreenIndex = {}
  self.m_tabBackParams = {}
  self.m_i2type = {}
  self.m_i2quality = {}
  self.m_i2country = {}
  self.m_FilterI2V = {}
  self.m_i2equip = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SortPage:_RegisterI2V()
  self.m_FilterI2V = {
    [HeroFilterType.Camp] = self.m_i2country,
    [HeroFilterType.Rarity] = self.m_i2quality,
    [HeroFilterType.Index] = self.m_i2type,
    [HeroFilterType.EquipType] = self.m_i2equip
  }
end

function SortPage:DoOnOpen()
  self.m_tabParams = self:GetParam()
  self.m_tabBackParams = clone(self.m_tabParams)
  self.m_tabScreenIndex = self.m_tabParams[1]
  self.sortRule = self.m_tabParams[2]
  self.m_sortType = self.m_tabParams.SortType or MHeroSortType.Default
  self:_LoadItem()
end

function SortPage:RegisterAllEvent()
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_ok, self._Confirm, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_cancel, self._Cancel, self)
end

function SortPage:_getSortAndFilterConfig(type)
  type = type or MHeroSortType.Default
  local keys = configManager.GetDataById("config_shiplist_option", type).shiplist_sequence_id
  local res = {}
  for _, id in pairs(keys) do
    local info = configManager.GetDataById("config_shiplist_sequence", id)
    table.insert(res, info)
  end
  return res
end

function SortPage:_LoadItem()
  local tabTogGroup = {}
  local tabSortInfo = {}
  local tabTypeInfo = {}
  local tabCampInfo = {}
  local tabRarityInfo = {}
  local tabLockInfo = {}
  local tabEquipInfo = {}
  self.m_tabWidgets.img_recommend:SetActive(self:GetParam().showRecommend)
  self.m_tabWidgets.tg_recommend.gameObject:SetActive(self:GetParam().showRecommend)
  if self.m_sortType == MHeroSortType.Picture then
    self.m_tabWidgets.obj_lock:SetActive(true)
    self.m_tabWidgets.obj_sort:SetActive(false)
  elseif self.m_sortType == MHeroSortType.Building or self.m_sortType == MHeroSortType.BuildingList then
    self.m_tabWidgets.obj_index:SetActive(false)
    self.m_tabWidgets.obj_camp:SetActive(false)
    self.m_tabWidgets.obj_rarity:SetActive(false)
    self.m_tabWidgets.obj_lock:SetActive(false)
    self.m_tabWidgets.obj_index2:SetActive(true)
    self.m_tabWidgets.obj_sort:SetActive(true)
    self.m_tabWidgets.obj_line2:SetActive(false)
    self.m_tabWidgets.obj_line3:SetActive(false)
  elseif self.m_sortType == MHeroSortType.Equip then
    self.m_tabWidgets.obj_lock:SetActive(true)
    self.m_tabWidgets.obj_sort:SetActive(false)
    self.m_tabWidgets.obj_equipType:SetActive(true)
    self.m_tabWidgets.obj_camp:SetActive(false)
    self.m_tabWidgets.obj_rarity:SetActive(false)
    self.m_tabWidgets.obj_line3:SetActive(false)
  elseif self.m_sortType == MHeroSortType.ShopFashion then
    self.m_tabWidgets.obj_sort:SetActive(false)
    self.m_tabWidgets.obj_camp:SetActive(false)
    self.m_tabWidgets.obj_line1:SetActive(false)
    self.m_tabWidgets.obj_line3:SetActive(false)
  else
    self.m_tabWidgets.obj_lock:SetActive(false)
    self.m_tabWidgets.obj_sort:SetActive(true)
  end
  local tabTemp = self:_getSortAndFilterConfig(self.m_sortType)
  local nCount = GetTableLength(tabTemp)
  for i = 1, nCount do
    if tabTemp[i].belong == 1 then
      table.insert(tabSortInfo, tabTemp[i])
    elseif tabTemp[i].belong == 2 or tabTemp[i].belong == 8 then
      table.insert(tabTypeInfo, tabTemp[i])
    elseif tabTemp[i].belong == 3 then
      table.insert(tabCampInfo, tabTemp[i])
    elseif tabTemp[i].belong == 4 then
      table.insert(tabRarityInfo, tabTemp[i])
    elseif tabTemp[i].belong == 7 then
      table.insert(tabEquipInfo, tabTemp[i])
    else
      table.insert(tabLockInfo, tabTemp[i])
    end
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_sortItem, self.m_tabWidgets.trans_sortParent, #tabSortInfo, function(nIndex, tabPart)
    tabPart.Tx_rarityBg.text = tabSortInfo[nIndex].name
    table.insert(tabTogGroup, tabPart.Tog_rarity)
  end)
  for i, tog in ipairs(tabTogGroup) do
    self.m_tabWidgets.tog_group:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_group, self, "", self._SwitchTogs)
  if self.m_sortType == MHeroSortType.Building or self.m_sortType == MHeroSortType.BuildingList then
    self.m_tabTypeTog = self:_LoadScreenItem(self.m_tabWidgets.item_index2, self.m_tabWidgets.trans_index2, tabTypeInfo, self._SaveBuildingTypeIndex)
  else
    self.m_tabTypeTog, self.m_i2type = self:_LoadScreenItem(self.m_tabWidgets.obj_typeItem, self.m_tabWidgets.trans_typeParent, tabTypeInfo, self._SaveTypeIndex)
    self.m_tabCampTog, self.m_i2country = self:_LoadScreenItem(self.m_tabWidgets.obj_campItem, self.m_tabWidgets.trans_campParent, tabCampInfo, self._SaveCampIndex)
    self.m_tabRarityTog, self.m_i2quality = self:_LoadScreenItem(self.m_tabWidgets.obj_rarityItem, self.m_tabWidgets.trans_rarityParent, tabRarityInfo, self._SaveRarityIndex)
    self.m_tabLockTog = self:_LoadScreenItem(self.m_tabWidgets.obj_lockItem, self.m_tabWidgets.trans_lockParent, tabLockInfo, self._SaveLockIndex)
    self.m_tabEquipTypeTog, self.m_i2equip = self:_LoadScreenItem(self.m_tabWidgets.obj_equipItem, self.m_tabWidgets.trans_equip, tabEquipInfo, self._SaveEquipTypeIndex)
    self:_RegisterI2V()
  end
  if self.m_sortType == MHeroSortType.Picture then
    self:_ShowScreenSelect(self.m_tabLockTog, self.m_tabParams, HeroFilterType.Lock)
    self:_ShowScreenSelect(self.m_tabTypeTog, self.m_tabParams, HeroFilterType.Index)
  elseif self.m_sortType == MHeroSortType.Building or self.m_sortType == MHeroSortType.BuildingList then
    self:_ShowScreenSelect(self.m_tabTypeTog, self.m_tabParams, HeroFilterType.Building)
    self:_ShowSortSelect(tabTogGroup, self.m_tabParams)
  elseif self.m_sortType == MHeroSortType.Equip then
    self:_ShowScreenSelect(self.m_tabLockTog, self.m_tabParams, HeroFilterType.Lock)
    self:_ShowScreenSelect(self.m_tabEquipTypeTog, self.m_tabParams, HeroFilterType.EquipType)
    self:_ShowScreenSelect(self.m_tabTypeTog, self.m_tabParams, HeroFilterType.EquipIndex)
  else
    self:_ShowScreenSelect(self.m_tabTypeTog, self.m_tabParams, HeroFilterType.Index)
    self:_ShowSortSelect(tabTogGroup, self.m_tabParams)
  end
  self:_ShowScreenSelect(self.m_tabCampTog, self.m_tabParams, HeroFilterType.Camp)
  self:_ShowScreenSelect(self.m_tabRarityTog, self.m_tabParams, HeroFilterType.Rarity)
  self.m_tabWidgets.tg_recommend.isOn = self.m_tabScreenIndex[HeroFilterType.Recommend] ~= nil
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tg_recommend, self._Recommend, self)
end

function SortPage:_ShowSortSelect(togGroup, tabParams)
  for k, v in pairs(togGroup) do
    if tabParams[2] == SortIndex[k - 1] then
      v.isOn = true
    end
  end
end

function SortPage:_ShowScreenSelect(tabTog, tabParams, filterType)
  local v2k = function(t, val)
    for i, v in pairs(t) do
      if v == val then
        return i
      end
    end
  end
  local key
  local filteri2v = self.m_FilterI2V
  for k, v in pairs(tabTog) do
    if tabParams[1][filterType] == nil then
      tabTog[1].isOn = true
    else
      for key, value in pairs(tabParams[1][filterType]) do
        if self.m_sortType == MHeroSortType.BuildingList then
          tabTog[value].isOn = true
        elseif filteri2v[filterType] then
          key = v2k(filteri2v[filterType], value)
          if key then
            tabTog[key].isOn = true
          else
            logError("sort value 2 index err, value:" .. value .. " filter:" .. filterType)
          end
        else
          tabTog[value + 1].isOn = true
        end
      end
    end
  end
end

function SortPage:_LoadScreenItem(obj, trans, tabInfo, CallFunc)
  local tabTog, m_index2config = {}, {}
  UIHelper.CreateSubPart(obj, trans, #tabInfo, function(nIndex, tabPart)
    tabPart.Tx_rarityBg.text = tabInfo[nIndex].name
    tabTog[nIndex] = tabPart.Tog_rarity
    m_index2config[nIndex] = tabInfo[nIndex].value
    UGUIEventListener.AddButtonToggleChanged(tabPart.Tog_rarity, CallFunc, self, nIndex)
  end)
  return tabTog, m_index2config
end

function SortPage:_SwitchTogs(index)
  for k, v in pairs(HeroSortType) do
    self.sortRule = SortIndex[index]
  end
end

function SortPage:_SaveTypeIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabTypeIndex, index)
  elseif self.m_tabTypeIndex ~= nil then
    for k, v in pairs(self.m_tabTypeIndex) do
      if v == index then
        table.remove(self.m_tabTypeIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabTypeTog, index)
  if tabTemp1 ~= nil then
    self.m_tabTypeInfo = {}
    local i2type = self.m_i2type
    local value
    for index, tog in pairs(tabTemp1) do
      value = i2type[index]
      if value then
        table.insert(self.m_tabTypeInfo, value)
      end
    end
  else
    self.m_tabTypeTog[1].isOn = true
    self.m_tabTypeInfo = nil
  end
  if self.m_sortType == MHeroSortType.Equip then
    self.m_tabScreenIndex[HeroFilterType.EquipIndex] = self.m_tabTypeInfo
  else
    self.m_tabScreenIndex[HeroFilterType.Index] = self.m_tabTypeInfo
  end
end

function SortPage:_SaveBuildingTypeIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabTypeIndex, index)
  elseif self.m_tabTypeIndex ~= nil then
    for k, v in pairs(self.m_tabTypeIndex) do
      if v == index then
        table.remove(self.m_tabTypeIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabTypeTog, index)
  if tabTemp1 ~= nil then
    self.m_tabTypeInfo = {}
    for k, v in pairs(tabTemp1) do
      for key, value in pairs(HeroBuildingIndexType) do
        if self.m_sortType == MHeroSortType.Building then
          if value == k - 1 then
            table.insert(self.m_tabTypeInfo, value)
          end
        elseif self.m_sortType == MHeroSortType.BuildingList and value == k then
          table.insert(self.m_tabTypeInfo, value)
        end
      end
    end
  else
    self.m_tabTypeTog[1].isOn = true
    self.m_tabTypeInfo = nil
  end
  self.m_tabScreenIndex[HeroFilterType.Building] = self.m_tabTypeInfo
end

function SortPage:_SaveCampIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabCampIndex, index)
  elseif self.m_tabCampIndex ~= nil then
    for k, v in pairs(self.m_tabCampIndex) do
      if v == index then
        table.remove(self.m_tabCampIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabCampTog, index)
  if tabTemp1 ~= nil then
    self.m_tabCampInfo = {}
    local i2country = self.m_i2country
    local value
    for index, tog in pairs(tabTemp1) do
      value = i2country[index]
      if value then
        table.insert(self.m_tabCampInfo, value)
      end
    end
  else
    self.m_tabCampTog[1].isOn = true
    self.m_tabCampInfo = nil
  end
  self.m_tabScreenIndex[HeroFilterType.Camp] = self.m_tabCampInfo
end

function SortPage:_SaveRarityIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabRarityIndex, index)
  elseif self.m_tabRarityIndex ~= nil then
    for k, v in pairs(self.m_tabRarityIndex) do
      if v == index then
        table.remove(self.m_tabRarityIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabRarityTog, index)
  if tabTemp1 ~= nil then
    self.m_tabRarityInfo = {}
    local i2quality = self.m_i2quality
    local value
    for index, tog in pairs(tabTemp1) do
      value = i2quality[index]
      if value then
        table.insert(self.m_tabRarityInfo, value)
      end
    end
  else
    self.m_tabRarityTog[1].isOn = true
    self.m_tabRarityInfo = nil
  end
  self.m_tabScreenIndex[HeroFilterType.Rarity] = self.m_tabRarityInfo
end

function SortPage:_SaveLockIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabLockIndex, index)
  elseif self.m_tabLockIndex ~= nil then
    for k, v in pairs(self.m_tabLockIndex) do
      if v == index then
        table.remove(self.m_tabLockIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabLockTog, index)
  if index == 1 then
    self.m_tabLockTog[1].isOn = true
    self.m_tabLockInfo = nil
  else
    self.m_tabLockInfo = {}
    for k, v in ipairs(self.m_tabLockTog) do
      if k == index then
        self.m_tabLockTog[k].isOn = true
        table.insert(self.m_tabLockInfo, k - 1)
      else
        self.m_tabLockTog[k].isOn = false
      end
    end
  end
  self.m_tabScreenIndex[HeroFilterType.Lock] = self.m_tabLockInfo
end

function SortPage:_SaveEquipTypeIndex(go, isOn, index)
  if isOn then
    table.insert(self.m_tabEquipTypeIndex, index)
  elseif self.m_tabEquipTypeIndex ~= nil then
    for k, v in pairs(self.m_tabEquipTypeIndex) do
      if v == index then
        table.remove(self.m_tabEquipTypeIndex, k)
      end
    end
  end
  local tabTemp1 = self:_ScreenTogLogic(self.m_tabEquipTypeTog, index)
  if tabTemp1 ~= nil then
    self.m_tabEquipTypeInfo = {}
    local i2quality = self.m_i2equip
    local value
    for index, tog in pairs(tabTemp1) do
      value = i2quality[index]
      if value then
        table.insert(self.m_tabEquipTypeInfo, value)
      end
    end
  else
    self.m_tabEquipTypeTog[1].isOn = true
    self.m_tabEquipTypeInfo = nil
  end
  self.m_tabScreenIndex[HeroFilterType.EquipType] = self.m_tabEquipTypeInfo
end

function SortPage:_ScreenTogLogic(tabTog, index)
  local isAll = false
  local tabSelectTog = {}
  local counter = 0
  for k, v in pairs(tabTog) do
    if v.isOn == true then
      tabSelectTog[k] = v
    end
  end
  for k, v in pairs(tabSelectTog) do
    counter = counter + 1
  end
  if counter == #tabTog - 1 and tabSelectTog[1] == nil then
    isAll = true
  end
  if index == 1 then
    for k, v in pairs(tabSelectTog) do
      if k ~= 1 then
        v.isOn = false
      end
    end
    tabSelectTog = nil
  elseif index ~= 1 and not isAll then
    for k, v in pairs(tabSelectTog) do
      if k == 1 then
        v.isOn = false
        tabSelectTog[k] = nil
      end
    end
  else
    for k, v in pairs(tabSelectTog) do
      v.isOn = false
    end
    tabTog[1].isOn = true
    tabSelectTog = nil
  end
  if tabSelectTog ~= nil and next(tabSelectTog) == nil then
    tabTog[1].isOn = true
    tabSelectTog = nil
  end
  return tabSelectTog
end

function SortPage:_Confirm()
  local tabSelectData = {}
  tabSelectData[1] = self.m_tabScreenIndex
  tabSelectData[2] = self.sortRule
  eventManager:SendEvent(LuaEvent.UpdataHeroSort, tabSelectData)
  UIHelper.ClosePage("SortPage")
end

function SortPage:_Cancel()
  eventManager:SendEvent(LuaEvent.UpdataHeroSort, self.m_tabBackParams)
  UIHelper.ClosePage("SortPage")
end

function SortPage:_Recommend(go, isOn)
  if isOn then
    self.m_tabScreenIndex[HeroFilterType.Recommend] = {}
  else
    self.m_tabScreenIndex[HeroFilterType.Recommend] = nil
  end
end

function SortPage:DoOnHide()
  self.m_tabWidgets.tog_group:ClearToggles()
end

function SortPage:DoOnClose()
  self.m_tabWidgets.tog_group:ClearToggles()
end

return SortPage
