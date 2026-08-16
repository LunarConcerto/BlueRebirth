local DailyCopyLevelDetailPage = class("ui.page.Copy.DailyCopyLevelDetailPage")
local ShipLevelLimit = {
  SHIPLEVEL_LIMIT_AVERAGE_GREATER = 1,
  SHIPLEVEL_LIMIT_LOWEST_GREATER = 2,
  SHIPLEVEL_LIMIT_HIGHEST_LESS = 3,
  SHIPLEVEL_LIMIT_AVERAGE_LESS = 4
}

function DailyCopyLevelDetailPage:initialize()
end

function DailyCopyLevelDetailPage:Init(page, param, tabWidgets)
  self.ShipLevelFunc = {
    [ShipLevelLimit.SHIPLEVEL_LIMIT_AVERAGE_GREATER] = function()
      return self:AverageGreaterN()
    end,
    [ShipLevelLimit.SHIPLEVEL_LIMIT_LOWEST_GREATER] = function()
      return self:LowestGreaterN()
    end,
    [ShipLevelLimit.SHIPLEVEL_LIMIT_HIGHEST_LESS] = function()
      return self:HighestLessN()
    end,
    [ShipLevelLimit.SHIPLEVEL_LIMIT_AVERAGE_LESS] = function()
      return self:AverageLessN()
    end
  }
  self.tabWidgets = tabWidgets
  self.page = page
  self.param = param
  self.copyType = param.copyType
  self.chapterId = param.dailyChapterId
  self.copyId = param.copyId
  self.copyInfo = param.copyInfo
  self.dailyGroupId = param.dailyGroupId
  local desConfInfo = Logic.copyLogic:GetCopyDesConfig(self.copyId)
  self.page:ModifyDisplayConfig(desConfInfo, false)
  self.page:ShowAreaInfo()
  UIHelper.SetImage(self.tabWidgets.im_chapter, "uipic_ui_dailycopy_bg_01")
  self.page:CreateShowStar(0)
  self.tabWidgets.obj_star:SetActive(false)
  self.tabWidgets.obj_assistDetail:SetActive(false)
  Service.copyService:SendGetCopyInfo(self.copyId)
  Logic.dailyCopyLogic:SetDCBattleInfo(self.copyInfo, self.dailyGroupId)
end

function DailyCopyLevelDetailPage:AverageGreaterN()
  local n = self.copyInfo.ship_level
  local ships = self:_GetShips()
  local average = self:_GetAcerageLevel(ships)
  return n <= average
end

function DailyCopyLevelDetailPage:LowestGreaterN()
  local n = self.copyInfo.ship_level
  local ships = self:_GetShips()
  if ships ~= nil and 0 < #ships then
    local level = ships[1].Lvl
    for k, v in pairs(ships) do
      if level > v.Lvl then
        level = v.Lvl
      end
    end
    return n <= level
  end
  return false
end

function DailyCopyLevelDetailPage:HighestLessN()
  local n = self.copyInfo.ship_level
  local ships = self:_GetShips()
  if ships ~= nil and 0 < #ships then
    local level = ships[1].Lvl
    for k, v in pairs(ships) do
      if level < v.Lvl then
        level = v.Lvl
      end
    end
    return n > level
  end
  return false
end

function DailyCopyLevelDetailPage:AverageLessN()
  local n = self.copyInfo.ship_level
  local n = self.copyInfo.ship_level
  local ships = self:_GetShips()
  local average = self:_GetAcerageLevel(ships)
  return n > average
end

function DailyCopyLevelDetailPage:_GetShips()
  self.nBattleFleetId = self.page:GetBattleFleetId()
  local ships = Logic.fleetLogic:GetShipDataListByFleet(self.nBattleFleetId)
  return ships
end

function DailyCopyLevelDetailPage:_GetAcerageLevel(ships)
  local level = 0
  local num = 0
  for k, v in pairs(ships) do
    num = num + 1
    level = v.Lvl + level
  end
  if 0 < num then
    return level / num
  else
    return 0
  end
end

function DailyCopyLevelDetailPage:UpdateInfo()
  self.tabWidgets.obj_chase:SetActive(false)
  self.tabWidgets.obj_bossHP:SetActive(false)
end

function DailyCopyLevelDetailPage:_CreateDropItem()
  local levelList = Logic.dailyCopyLogic:GetDailyCopyLevelList(self.chapterId)
  local index = 1
  for i, v in pairs(levelList) do
    if self.copyId == v then
      index = i
    end
  end
  local dailyGroupInfo = configManager.GetDataById("config_daily_group", self.dailyGroupId)
  local dropList, dropItemList, baseDropIndex = Logic.dailyCopyLogic:GetDropInfo(dailyGroupInfo, index)
  UIHelper.CreateSubPart(self.tabWidgets.obj_outItem, self.tabWidgets.trans_outItem, #dropItemList, function(nIndex, tabPart)
    local displayInfo = dropItemList[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(tabPart.im_outItem, displayInfo.icon)
    tabPart.im_outItem:SetNativeSize()
    UIHelper.SetText(tabPart.tx_dropRate, itemInfo.drop_rate)
    tabPart.obj_extra:SetActive(nIndex > baseDropIndex)
    tabPart.obj_textDrop:SetActive(true)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, dropList)
    end)
  end)
end

function DailyCopyLevelDetailPage:CheckBattleCondition()
  local result = false
  if not self:_CheckCopyOpen() then
    noticeManager:ShowTip(UIHelper.GetString(410005))
    return result
  end
  local girlLevelType = self.copyInfo.ship_level_type
  result = self.ShipLevelFunc[girlLevelType]()
  if not result then
    noticeManager:ShowTip("\230\136\152\229\167\172\231\173\137\231\186\167\228\184\141\229\164\159")
  end
  return result
end

function DailyCopyLevelDetailPage:_CheckCopyOpen()
  local weekDay = time.getWeekday()
  local weeks = self.copyInfo.is_available
  for k, v in pairs(weeks) do
    if weekDay == v then
      return true
    end
  end
  return false
end

function DailyCopyLevelDetailPage:StartAttack()
  Service.cacheDataService:SendCacheData("copy.StartBase", "DailyCopyLevelDetailPage")
end

function DailyCopyLevelDetailPage:CacheDataRet(cacheId)
  self.nBattleFleetId = self.page:GetBattleFleetId()
  Service.copyService:SendStartBase(self.chapterId, self.copyId, false, self.nBattleFleetId, cacheId, -1, self.dailyGroupId, self.page.m_battleMode)
  self.page:UnregisterEvent(LuaEvent.CacheDataRet, self.page._CacheDataRet, self)
end

function DailyCopyLevelDetailPage:CheckTime()
  local dailyGroupInfo = configManager.GetDataById("config_daily_group", self.dailyGroupId)
  if not Logic.dailyCopyLogic:CheckDailyCopyPeriod(dailyGroupInfo, true) then
    return false
  end
  return true
end

function DailyCopyLevelDetailPage:CreateFleet()
  self.page:_InitFleet()
end

function DailyCopyLevelDetailPage:SetBottomTog()
  local togs = {
    ButtomTogType.OUTPUT
  }
  return togs
end

return DailyCopyLevelDetailPage
