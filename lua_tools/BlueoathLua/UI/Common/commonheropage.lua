local CommonHeroPage = class("UI.Common.CommonHeroPage", LuaUIPage)
local MOVE_DISTANCE = 0.18
local HEROROOT_OFFSET = 110
local fleetHeroItem = require("ui.page.Fleet.fleetHeroItem")
local reapireHeroItem = require("ui.page.Repaire.RepaireHeroItem")
local wishHeroItem = require("ui.page.Illustrate.WishHeroItem")
local bathHeroItem = require("ui.page.Bathroom.BathHeroItem")
local commonGoodsItem = require("ui.page.Common.CommonGoodsItem")
local bathTimeControl = require("ui.page.Bathroom.BathTimeControl")

function CommonHeroPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
    if CommonHeroPage.lastPos == nil then
      CommonHeroPage.lastPos = self.m_tabWidgets.content.anchoredPosition
    end
  end
  self.m_heroData = nil
  self.m_type = nil
  self.m_pageObj = nil
  self.m_otherData = nil
  self.m_sortway = true
  self.m_tabInParams = {}
  self.m_tabOutParams = {}
  self.m_tabSortHero = {}
  self.m_opened = false
  self.m_chapterId = 0
  self.m_orginSize = nil
end

function CommonHeroPage:DoOnOpen()
  local param = self:GetParam()
  self:InitPage(param)
  local position = param[5]
  local tweenPos = self.m_tabWidgets.tween_pos
  local from = tweenPos.from
  local to = tweenPos.to
  tweenPos.from = Vector3(from.x, -100, 0)
  tweenPos.to = position ~= nil and Vector3.New(to.x, 180, 0) or Vector3.New(to.x, 100, 0)
  tweenPos:Play(true)
  self:_HeroAutoShowWrap()
end

function CommonHeroPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.UpdateHeroItem, self._UpdateItem, self)
  self:RegisterEvent(LuaEvent.SaveHeroSort, self._SaveSortData, self)
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHeroLockInfo, self)
  self:RegisterEvent(LuaEvent.CommonHeroClose, self.PlayCloseTween, self)
  self:RegisterEvent(LuaEvent.UpdateCommonPage, self.InitPage, self)
  self:RegisterEvent(LuaEvent.CloseStrategy, self._UpdateItem, self)
  self:RegisterEvent(LuaEvent.EQUIP_AutoAddOk, self._OnAutoAddOk, self)
  self:RegisterEvent(LuaEvent.EQUIP_AutoUnAddOk, self._OnAutoUnAddOk, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_sort, self._SortOrder, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_screen, self._ClickScreen, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_leftSlider, self._ClickLeftSlider, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_rightSlider, self._ClickRightSlider, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_allequip, self._OnClickAllEquip, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_allout, self._OnClickAllOut, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ask, self._OnClickHelp, self)
end

function CommonHeroPage:InitPage(param)
  self:SaveNewParam(param)
  self.m_pageObj = param[1]
  self.m_type = param[2]
  self.m_heroData = param[3]
  self.m_otherData = param[4]
  self.m_notSaveSort = param.notSaveSort
  self.m_chapterId = param.chapterId == nil and 0 or param.chapterId
  self.m_recommend = self:GetRecommend()
  self.m_tabWidgets.obj_screen:SetActive(self.m_type ~= CommonHeroItem.Goods)
  self.m_tabWidgets.obj_sort:SetActive(self.m_type ~= CommonHeroItem.Goods)
  self.m_tabWidgets.scrollRectGoods.gameObject:SetActive(self.m_type == CommonHeroItem.Goods)
  self.m_tabWidgets.scrollRect.gameObject:SetActive(self.m_type ~= CommonHeroItem.Goods)
  self:_showBgAndSlider(self.m_type)
  if self.m_type == CommonHeroItem.Goods then
    self:_OpenGoods()
  else
    local tempSort
    if not self.m_notSaveSort then
      tempSort = Logic.sortLogic:GetHeroSort(self.m_type)
    else
      tempSort = Logic.sortLogic:GetHeroSortTemp(self.m_type)
    end
    self:_DealSortData(tempSort)
    if self.m_type == CommonHeroItem.BathRoom then
      bathTimeControl:Init()
    else
      self:SetTabSortHero()
    end
    self.m_tabWidgets.txt_screen.text = HeroSortHelper.GetSortName(self.m_tabOutParams[2])
    if self.m_type == CommonHeroItem.Fleet or self.m_type == CommonHeroItem.TowerFleet then
      local scrollPos = Logic.fleetLogic:GetScrollPos()
      if 0 < scrollPos then
        self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition = scrollPos
      end
      self.m_tabWidgets.txt_num.text = #self.m_heroData .. "<color=#677c99>" .. "/" .. Logic.shipLogic:GetBaseShipNum() .. "</color>"
    elseif self.m_type == CommonHeroItem.Wish then
      local str = string.format("%s:%d", UIHelper.GetLocString(951044), Logic.wishLogic:GetBanHeroCount())
      UIHelper.SetText(self.m_tabWidgets.txt_num, str)
      self.m_tabWidgets.txt_title.text = ""
    elseif self.m_type == CommonHeroItem.Repaire then
      self.m_tabWidgets.txt_num.text = string.format(UIHelper.GetString(110030), #self.m_heroData)
    else
      self.m_tabWidgets.txt_title.gameObject:SetActive(false)
      self.m_tabWidgets.txt_num.text = string.format("\232\136\185\229\157\158", #self.m_heroData)
    end
    self:_LoadHeroItem(self.m_tabSortHero)
    self.m_opened = true
    local useLastPos = param.useLastPos
    if useLastPos then
      self.m_tabWidgets.content.anchoredPosition = CommonHeroPage.lastPos
    end
  end
end

function CommonHeroPage:_OpenGoods()
  self.m_tabWidgets.txt_num.text = ""
  self.m_tabWidgets.txt_title.text = ""
  local goodsTab = self:_SortGoods()
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.scrollRectGoods, self.m_tabWidgets.obj_goodsItem, #goodsTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = commonGoodsItem:new()
      item:Init(self.m_pageObj, tabPart, self.m_heroData[nIndex], nIndex, self.m_otherData)
    end
  end)
end

function CommonHeroPage:_SortGoods()
  local tabGoods = self.m_heroData
  table.sort(tabGoods, function(data1, data2)
    return data1.id < data2.id
  end)
  return tabGoods
end

function CommonHeroPage:_ClickScreen()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  if self.m_type == CommonHeroItem.Fleet or self.m_type == CommonHeroItem.TowerFleet then
    self.m_tabOutParams.showRecommend = true
  end
  if self.m_type == CommonHeroItem.BathRoom then
    self.m_tabOutParams.SortType = MHeroSortType.BathSelect
  end
  UIHelper.OpenPage("SortPage", self.m_tabOutParams)
end

function CommonHeroPage:_UpdateHeroSort(tabSortParams)
  self.m_tabInParams = tabSortParams
  self.m_tabOutParams = tabSortParams
  self.m_tabWidgets.txt_screen.text = HeroSortHelper.GetSortName(self.m_tabOutParams[2])
  self:_SortOrder()
end

function CommonHeroPage:_SortOrder()
  if self.m_tabWidgets.tog_sort.isOn then
    self.m_sortway = true
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
  else
    self.m_sortway = false
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
  end
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  self:SetTabSortHero()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonHeroPage:_DealSortData(param)
  local tabSelectData = param
  self.m_sortway = tabSelectData[1]
  if self.m_sortway then
    self.m_tabWidgets.tog_sort.isOn = true
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
  else
    self.m_tabWidgets.tog_sort.isOn = false
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
  end
  self.m_tabOutParams = tabSelectData[2]
end

function CommonHeroPage:_SaveSortData()
  local tabSelectData = {}
  tabSelectData[1] = self.m_sortway
  tabSelectData[2] = self.m_tabOutParams
  if self.m_notSaveSort then
    Logic.sortLogic:SetHeroSortTemp(self.m_type, tabSelectData)
  else
    Logic.sortLogic:SetHeroSort(self.m_type, tabSelectData)
  end
  if self.m_type == CommonHeroItem.BathRoom then
    local sortData = Serialize(tabSelectData)
    Service.guideService:SendUserSetting({
      {
        Key = "BathRoomSort",
        Value = sortData
      }
    })
  end
end

function CommonHeroPage:_UpdateItem(param)
  self.m_recommend = self:GetRecommend()
  if param ~= nil then
    if param.heroTab ~= nil then
      self.m_heroData = param.heroTab
      if self.m_type == CommonHeroItem.Wish then
        local str = string.format("%s:%d", UIHelper.GetLocString(951044), Logic.wishLogic:GetBanHeroCount())
        UIHelper.SetText(self.m_tabWidgets.txt_num, str)
        Logic.wishLogic:SetBanHero(param.heroTab)
      elseif self.m_type == CommonHeroItem.Repaire then
        self.m_tabWidgets.txt_num.text = string.format(UIHelper.GetString(110030), #param.heroTab)
      end
    end
    self.m_otherData = param.otherParam
  end
  self:SetTabSortHero()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonHeroPage:_LoadHeroItem(heroTab)
  if self.m_type == CommonHeroItem.BathRoom then
    bathTimeControl:ClearPoolHero()
  end
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.scrollRect, self.m_tabWidgets.obj_bottomCardItem, #heroTab, function(tabParts, startIndex, endIndex)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    if self.m_type == CommonHeroItem.BathRoom then
      bathTimeControl:SetShowItemRange(startIndex, endIndex, tabTemp)
    end
    for nIndex, tabPart in pairs(tabTemp) do
      if self.m_type == CommonHeroItem.Fleet or self.m_type == CommonHeroItem.TowerFleet then
        local item = fleetHeroItem:new()
        item:Init(self.m_pageObj, tabPart, heroTab[nIndex], nIndex, self.m_otherData, heroTab, self.m_chapterId, tabTemp)
      elseif self.m_type == CommonHeroItem.Repaire then
        local item = reapireHeroItem:new()
        item:Init(self.m_pageObj, tabPart, heroTab[nIndex], nIndex)
      elseif self.m_type == CommonHeroItem.Wish then
        local item = wishHeroItem:new()
        item:Init(self.m_pageObj, tabPart, heroTab[nIndex], nIndex, self.m_tabWidgets)
      elseif self.m_type == CommonHeroItem.BathRoom then
        local item = bathHeroItem:new()
        item:Init(self.m_pageObj, tabPart, heroTab[nIndex], nIndex, self.m_otherData, bathTimeControl, tabTemp)
      end
    end
  end)
end

function CommonHeroPage:_UpdateHeroLockInfo()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonHeroPage:_ClickLeftSlider()
  local i = self.m_tabWidgets.Scrollbar.value
  i = i - MOVE_DISTANCE
  if i <= 0 then
    self.m_tabWidgets.Scrollbar.value = 0
  else
    self.m_tabWidgets.Scrollbar.value = i
  end
end

function CommonHeroPage:_ClickRightSlider()
  local i = self.m_tabWidgets.Scrollbar.value
  i = i + MOVE_DISTANCE
  if 1 <= i then
    self.m_tabWidgets.Scrollbar.value = 1
  else
    self.m_tabWidgets.Scrollbar.value = i
  end
end

function CommonHeroPage:PlayCloseTween()
  self.m_tabWidgets.tween_pos:Play(false)
end

function CommonHeroPage:_RecordStopPos()
  CommonHeroPage.lastPos = self.m_tabWidgets.content.anchoredPosition
  if self.m_type == CommonHeroItem.Fleet or self.m_type == CommonHeroItem.TowerFleet then
    Logic.fleetLogic:SetScrollPos(self.m_tabWidgets.sv_AllItems.horizontalNormalizedPosition)
  end
end

function CommonHeroPage:DoOnHide()
  bathTimeControl:StopTimer()
  self:_RecordStopPos()
  self:_SaveSortData()
end

function CommonHeroPage:DoOnClose()
  bathTimeControl:StopTimer()
  self:_RecordStopPos()
  self:_SaveSortData()
end

function CommonHeroPage:SetTabSortHero()
  if self.m_type == CommonHeroItem.Fleet or self.m_type == CommonHeroItem.TowerFleet then
    self.m_tabSortHero = Logic.fleetLogic:FleetHeroSort(self.m_otherData, self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, self.m_recommend, self.m_pageObj.fleetType)
    self:SortForTrain()
  elseif self.m_type == CommonHeroItem.Wish then
    self.m_heroData = Data.wishData:GetBanHeroList()
    self.m_tabSortHero = HeroSortHelper.FilterAndSort(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, self.m_recommend)
  elseif self.m_type == CommonHeroItem.BathRoom then
    self.m_tabSortHero = Logic.bathroomLogic:BathHeroSort(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, self.m_recommend)
  elseif self.m_type ~= CommonHeroItem.Goods then
    self.m_tabSortHero = HeroSortHelper.FilterAndSort(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, self.m_recommend)
  end
end

function CommonHeroPage:SortForTrain()
  local lockedIndex = 1
  local lockedMap = {}
  local count = #self.m_tabSortHero
  for i = count, 1, -1 do
    local heroInfo = self.m_tabSortHero[i]
    local isLocked = Logic.fleetLogic:IsShipLocked(self.m_pageObj.m_tabFleetData[1], heroInfo.HeroId)
    if isLocked then
      if lockedIndex ~= i then
        lockedMap[lockedIndex] = heroInfo
        table.remove(self.m_tabSortHero, i)
      end
      lockedIndex = lockedIndex + 1
    end
  end
  for i, v in pairs(lockedMap) do
    table.insert(self.m_tabSortHero, i, v)
  end
end

function CommonHeroPage:GetRecommend()
  if self.m_pageObj.GetRecommend then
    return self.m_pageObj:GetRecommend()
  end
  return {}
end

function CommonHeroPage:_showBgAndSlider(type)
  local widgets = self:GetWidgets()
  if type == CommonHeroItem.Goods then
    widgets.obj_image_di_2:SetActive(true)
    widgets.obj_ditiao_2:SetActive(true)
    widgets.obj_image_di:SetActive(false)
    widgets.obj_ditiao:SetActive(false)
  else
    widgets.obj_image_di:SetActive(true)
    widgets.obj_ditiao:SetActive(true)
    widgets.obj_image_di_2:SetActive(false)
    widgets.obj_ditiao_2:SetActive(false)
  end
end

function CommonHeroPage:_OnClickAllEquip()
  local fleetType = self.m_pageObj.fleetType
  local tip = Logic.fleetLogic:GetHideAutoTip()
  local heros = {}
  if self.m_otherData[1] and self.m_otherData[1].heroInfo then
    heros = self.m_otherData[1].heroInfo
  end
  if tip then
    local ok, msg = Logic.fleetLogic:HerosAutoEquipWrap(fleetType, heros)
    if not ok then
      noticeManager:ShowTip(msg)
    end
  else
    UIHelper.OpenPage("TowerEquipPage", {FleetType = fleetType, FleetHero = heros})
  end
end

function CommonHeroPage:_OnClickAllOut()
  local fleetType = self.m_pageObj.fleetType
  local ok, msg = Logic.fleetLogic:HerosAutoUnEquipWrap(fleetType)
  if not ok then
    noticeManager:ShowTip(msg)
  end
end

function CommonHeroPage:_OnAutoAddOk()
  noticeManager:ShowTip(UIHelper.GetString(1704001))
end

function CommonHeroPage:_OnAutoUnAddOk()
  noticeManager:ShowTip(UIHelper.GetString(1704010))
end

function CommonHeroPage:_OnClickHelp()
  UIHelper.OpenPage("HelpPage", {
    content = UIHelper.GetString(1704012)
  })
end

function CommonHeroPage:_HeroAutoShowWrap()
  local show = self.m_pageObj and self.m_pageObj.fleetType and Logic.towerLogic:IsTowerType(self.m_pageObj.fleetType)
  self:_HeroRootOffset(show)
end

function CommonHeroPage:_HeroRootOffset(enable)
  local widgets = self:GetWidgets()
  if self.m_orginSize == nil then
    local size = widgets.trans_heroview.sizeDelta
    self.m_orginSize = size
  end
  widgets.obj_auto:SetActive(enable)
  if enable then
    widgets.trans_heroview.sizeDelta = Vector2.New(self.m_orginSize.x - HEROROOT_OFFSET, self.m_orginSize.y)
  else
    widgets.trans_heroview.sizeDelta = self.m_orginSize
  end
end

return CommonHeroPage
