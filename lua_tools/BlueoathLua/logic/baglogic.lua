local BagLogic = class("logic.BagLogic")
local ITEM_ID_BEGIN = 10000
local ONE_DAY_SEC = 86400

function BagLogic:initialize()
  self:ResetData()
end

function BagLogic:ResetData()
  self.SortRecordParam = {}
  self.curToggle = 0
  self.m_selectEquipSet = nil
  self.mShowAll = false
end

function BagLogic:_SetBagSort()
  if next(self.SortRecordParam) ~= nil then
    return
  end
  local localRecord = {}
  local record = Data.userData:GetOrderRecord(OrderRecord.EQUIP_BAG)
  if record == nil then
    localRecord.Type = 1
    localRecord.Sort = 0
    localRecord.Screen = 0
    localRecord.Order = 0
    localRecord.UseEquip = 0
    localRecord.AttrEquip = 0
    Logic.bagLogic:SetSortRecord(localRecord)
    return
  end
  for i, v in pairs(record) do
    if type(v) ~= "table" then
      localRecord[i] = v
    end
  end
  localRecord.UseEquip = record.OtherInfo[1]
  localRecord.AttrEquip = record.OtherInfo[2]
  Logic.bagLogic:SetSortRecord(localRecord)
end

function BagLogic:GetDefauleRecord()
  local localRecord = {}
  localRecord.Type = 1
  localRecord.Sort = 0
  localRecord.Screen = 0
  localRecord.Order = 0
  localRecord.UseEquip = 0
  localRecord.AttrEquip = 0
  return localRecord
end

function BagLogic:SetSelectEquipRecord(param)
  if param == nil then
    return
  end
  if next(self.m_selectEquipSet) == nil then
    self.m_selectEquipSet = param
  else
    for k, v in pairs(param) do
      self.m_selectEquipSet[k] = v
    end
  end
end

function BagLogic:ResetSelectEquipRecord()
  if self.m_selectEquipSet == nil then
    self.m_selectEquipSet = self:GetDefauleRecord()
    return
  end
  local temp = self:GetDefauleRecord()
  temp.UseEquip = self.m_selectEquipSet.UseEquip
  temp.AttrEquip = self.m_selectEquipSet.AttrEquip
  self.m_selectEquipSet = temp
end

function BagLogic:GetSelectEquipRecord()
  local temp = self:GetDefauleRecord()
  if self.m_selectEquipSet == nil then
    self.m_selectEquipSet = temp
  end
  return self.m_selectEquipSet
end

function BagLogic:SetSortRecord(param)
  if next(self.SortRecordParam) == nil then
    self.SortRecordParam = param
  else
    for k, v in pairs(param) do
      self.SortRecordParam[k] = v
    end
  end
end

function BagLogic:SetSceenIndex(nIndex)
  self.SortRecordParam.Screen = nIndex
end

function BagLogic:GetSortRecord()
  return self.SortRecordParam
end

function BagLogic:SetCurToggle(index)
  self.curToggle = index
end

function BagLogic:GetCurToggle()
  return self.curToggle
end

function BagLogic:ItemInfoById(tId)
  local itemTab = self:DisposeItem()
  local itemInfo
  for i, v in ipairs(itemTab) do
    if v.templateId == tId then
      itemInfo = v
      break
    end
  end
  return itemInfo
end

function BagLogic:DisposeItem()
  local itemTab = Data.bagData:GetItemData()
  local periodItemTab = Data.bagData:GetPeriodItemData()
  local dataRet = {}
  for k, v in pairs(itemTab) do
    v.itemId = 0
    table.insert(dataRet, v)
  end
  for i, j in pairs(periodItemTab) do
    if self:CheckInPeriod(j) then
      j.num = 1
      table.insert(dataRet, j)
    end
  end
  return self:_SortItem(dataRet)
end

function BagLogic:_SortItem(itemTab)
  local tab = self:_ItemConfig(itemTab)
  local r = false
  table.sort(tab, function(data1, data2)
    if data1.quality == data2.quality then
      r = data1.templateId < data2.templateId
      if data1.templateId == data2.templateId then
        r = data1.itemId < data2.itemId
      end
    else
      r = data1.quality > data2.quality
    end
    return r
  end)
  return tab
end

function BagLogic:_ItemConfig(itemTab)
  local itemInfo = {}
  for i, v in ipairs(itemTab) do
    local itemConfig = self:GetItemByConfig(v.templateId)
    local itemAllInfo = {}
    for k, n in pairs(itemConfig) do
      itemAllInfo[k] = n
    end
    for j, x in pairs(v) do
      itemAllInfo[j] = x
    end
    if not itemAllInfo.show_type or itemAllInfo.show_type == 0 or self.mShowAll then
      table.insert(itemInfo, itemAllInfo)
    end
  end
  return itemInfo
end

function BagLogic:GetItemTypeByTid(tId)
  return math.floor(tonumber(tId) / ITEM_ID_BEGIN)
end

function BagLogic:GetItemByConfig(tId)
  local index = self:GetItemTypeByTid(tId)
  local configName = configManager.GetDataById("config_table_index", index).file_name
  local item = configManager.GetDataById(configName, tId)
  return item
end

function BagLogic:GetConfig(type, tid)
  local configName = configManager.GetDataById("config_table_index", type).file_name
  local item = configManager.GetDataById(configName, tid)
  return item
end

function BagLogic:GetConsumeCurrNum(itype, tid)
  local count = 0
  if itype == GoodsType.CURRENCY then
    count = Data.userData:GetCurrency(tid)
  else
    count = Data.bagData:GetItemNum(tid)
  end
  return count
end

function BagLogic:GetGoodsByConfigId(tabItem)
  local type = tabItem[1]
  local configId = tabItem[2]
  local count = tabItem[3]
  local configItem = BagLogic.ConfigInfo[type](configId)
  local args = {}
  args.name = configItem.name
  args.icon = configItem.icon
  args.quality = configItem.quality
  args.desc = configItem.description
  args.type = type
  args.configId = tabItem[2]
  args.count = count
  return args
end

function BagLogic:GetItemByTempateId(tabIndex, tId)
  local args = {}
  if tabIndex == BagLogic.ConfigInfo.ShipConfig then
    local shipShow = Logic.shipLogic:GetShipShowById(tId)
    local shipInfo = Logic.shipLogic:GetShipInfoById(tId)
    args.name = shipInfo.ship_name
    args.icon = shipShow.ship_icon5
    args.quality = shipInfo.quality
    args.desc = shipInfo.ship_name
    args.id = tId
    args.tabIndex = tabIndex
  else
    local configName = configManager.GetDataById("config_table_index", tabIndex).file_name
    local config = configManager.GetDataById(configName, tId)
    args.name = config.name
    args.icon = config.icon
    args.iconSmall = config.iconSmall
    args.quality = config.quality
    args.desc = config.description ~= nil and config.description or ""
    args.id = tId
    args.tabIndex = tabIndex
    if tabIndex == GoodsType.FASHION then
      args.shipShowId = config.ship_show_id
      args.icon = config.icon_small
    end
    if tabIndex == GoodsType.PLAYER_HEAD_FRAME then
      args.iconSmall = config.icon_small
    end
    if tabIndex == BagLogic.ConfigInfo.ItemConfig then
      args.recommend_bg1 = config.recommend_bg1
      args.recommend_bg2 = config.recommend_bg2
      args.shop_bg = config.shop_bg
      args.drop_id = config.drop_id
    end
  end
  return args
end

function BagLogic:EquipScreenAndSort(tabEquip, screenRule, sortRule, sortOrder)
  local tabTemp = {}
  tabTemp = BagLogic._EquipScreen(tabEquip, screenRule)
  local order = {}
  order[1] = "sortEquipType"
  order[2] = sortRule
  order[3] = "sortDefult"
  table.sort(tabTemp, function(data1, data2)
    local i = 1
    while i <= #order do
      local state = BagLogic.SortFuc[order[i]](data1, data2, sortOrder)
      if state == 0 then
        i = i + 1
      else
        return state == 2
      end
    end
  end)
  return tabTemp
end

function BagLogic._EquipScreen(tabEquip, screenRule)
  local screenType = configManager.GetData("config_equip_wear_type")
  if screenRule == 0 then
    return tabEquip
  elseif screenRule == #screenType + 1 then
    local tabTemp = {}
    for _, v in ipairs(tabEquip) do
      if v.activity_equip == 1 then
        table.insert(tabTemp, v)
      end
    end
    return tabTemp
  end
  local tabTemp = {}
  for i = 1, #tabEquip do
    if tabEquip[i] ~= nil then
      local typeIdTab = tabEquip[i].ewt_id
      for j = 1, #typeIdTab do
        if tonumber(typeIdTab[j]) == tonumber(screenRule) then
          table.insert(tabTemp, tabEquip[i])
          break
        end
      end
    end
  end
  return tabTemp
end

function BagLogic.SortEquipByRarity(data1, data2, sortOrder)
  return BagLogic._SortImp(data1.quality, data2.quality, sortOrder)
end

function BagLogic.SortEquipByIntensify(data1, data2, sortOrder)
  return BagLogic._SortImp(data1.EnhanceLv, data2.EnhanceLv, sortOrder)
end

function BagLogic.SortEquipByStar(data1, data2, sortOrder)
  return BagLogic._SortImp(data1.Star, data2.Star, sortOrder)
end

function BagLogic.SortEquipByEquipId(data1, data2, sortOrder)
  return BagLogic._SortImp(data1.EquipId, data2.EquipId, sortOrder)
end

function BagLogic.SortEquipByType(data1, data2, sortOrder)
  return BagLogic._SortImp(data1.activity_equip, data2.activity_equip, not sortOrder)
end

function BagLogic._SortImp(data1, data2, descend)
  if descend then
    if data2 < data1 then
      return 2
    elseif data1 < data2 then
      return 1
    else
      return 0
    end
  elseif data1 < data2 then
    return 2
  elseif data2 < data1 then
    return 1
  else
    return 0
  end
end

BagLogic.SortFuc = {
  [EquipSortType.Rarity] = BagLogic.SortEquipByRarity,
  [EquipSortType.Intensify] = BagLogic.SortEquipByIntensify,
  [EquipSortType.Star] = BagLogic.SortEquipByStar,
  sortDefult = BagLogic.SortEquipByEquipId,
  sortEquipType = BagLogic.SortEquipByType
}
BagLogic.ConfigInfo = {ItemConfig = 1, ShipConfig = 3}

function BagLogic:GetBagItemType(id)
  return tonumber(string.sub(tostring(id), 1, 1))
end

function BagLogic:GetBagItemNum(id)
  local item = Data.bagData:GetItemById(id)
  return item and item.num or 0
end

function BagLogic:GetItemArrByItemType(itemType)
  local data = Data.bagData:GetItemData()
  local itemArr = {}
  for _, itemInfo in pairs(data) do
    if self:GetBagItemType(itemInfo.templateId) == itemType then
      table.insert(itemArr, itemInfo)
    end
  end
  return itemArr
end

function BagLogic:CheckUseEquipOff()
  if self.SortRecordParam.UseEquip == 0 then
    return true
  end
  return false
end

function BagLogic:GetRandSelectItemUseInfo(tid)
  local itemConfig = self:GetItemByConfig(tid)
  if next(itemConfig.item_id) ~= nil and itemConfig.drop_id > 0 then
    logError("item config error. id:" .. tid)
    return nil
  end
  if itemConfig.drop_id > 0 then
    local useInfo = Data.bagData:UseInfo(tid)
    return useInfo
  end
  return nil
end

function BagLogic:IsRandSelectItem(tid)
  local itemConfig = self:GetItemByConfig(tid)
  if next(itemConfig.item_id) ~= nil and itemConfig.drop_id > 0 then
    logError("item config error. id:" .. tid)
    return false
  end
  if itemConfig.drop_id > 0 then
    return true
  end
  return false
end

function BagLogic:_UpdateSelectRand()
  eventManager:SendEvent(LuaEvent.UpdateSelectRand)
end

function BagLogic:GetAllBagItem(tid)
  self.mShowAll = true
  local ret = self:ItemInfoById(tid)
  self.mShowAll = false
  return ret
end

function BagLogic:GetSelectBoxItem(tId)
  local itemConf = Logic.itemSelectLogic:GetInfo(tId)
  if #itemConf.item_id == 0 then
    logError("tId:%s item_id id nil", tId)
    return
  end
  local rewardTab = {}
  for _, v in ipairs(itemConf.item_id) do
    table.insert(rewardTab, {
      Id = 0,
      Num = v[3],
      ConfigId = v[2],
      Type = v[1]
    })
  end
  return rewardTab
end

function BagLogic:CheckInPeriod(itemData)
  local itemConfig = self:GetItemByConfig(itemData.templateId)
  local validTime = itemData.createTime + itemConfig.time_duration
  if validTime > time.getSvrTime() then
    return true
  end
  return false
end

function BagLogic:GetPeriodItemTime(duration, startTime)
  if duration == 0 or startTime == 0 then
    return duration
  end
  local remain = duration - (time.getSvrTime() - startTime)
  return remain
end

function BagLogic:GetPeriodItemByTid(tId)
  local retTab = {}
  local periodItemTab = Data.bagData:GetPeriodItemData()
  for _, v in pairs(periodItemTab) do
    if v.templateId == tId and self:CheckInPeriod(v) then
      local discountConf = Logic.itemLogic:GetDiscountConfig(v.templateId)
      local itemInfo = {}
      itemInfo.data = v
      itemInfo.config = discountConf
      table.insert(retTab, itemInfo)
    end
  end
  retTab = Logic.shopLogic:SortOwnDiscount(retTab)
  return retTab
end

function BagLogic:GetPeriodCountDown(timeInt)
  local str = ""
  local day = math.floor(timeInt / 86400)
  timeInt = timeInt % 86400
  local hour = math.floor(timeInt / 3600)
  local min = math.floor(timeInt / 60 % 60)
  local sec = timeInt % 60
  if 1 < day then
    str = string.format("%02d\229\164\169%02d\229\176\143\230\151\182", day, hour)
  else
    str = string.format("%02d:%02d:%02d", hour, min, sec)
  end
  return str
end

function BagLogic:CheckAllPeriodItem()
  local periodItemTab = Data.bagData:GetPeriodItemData()
  if next(periodItemTab) ~= nil then
    for _, v in pairs(periodItemTab) do
      if math.floor(tonumber(v.templateId) / ITEM_ID_BEGIN) == GoodsType.DISCOUNT then
        local discountConf = Logic.itemLogic:GetDiscountConfig(v.templateId)
        local duration = self:GetPeriodItemTime(discountConf.time_duration, v.createTime)
        if 0 < duration and duration < ONE_DAY_SEC then
          return true
        end
      end
    end
  end
  return false
end

return BagLogic
