local HeroRetirePage = class("UI.Dock.HeroRetirePage", LuaUIPage)
local rewardType = {
  Gold = 1,
  Supply = 2,
  Medal = 3
}

function HeroRetirePage:DoInit()
  self.m_tabWidgets = nil
  self.m_showHero = {}
  self.m_showAllHero = {}
  self.m_selectUp = 0
  self.m_tabSelectId = {}
  self.m_selectId = nil
  self.m_tabButtom = {}
  self.m_nowTog = nil
  self.m_tabFleet = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function HeroRetirePage:DoOnOpen()
  self:OpenTopPage("HeroRetirePage", 1, UIHelper.GetString(920000069), self, true)
  local params = self:GetParam()
  self.m_selectUp = configManager.GetDataById("config_parameter", 69).value
  self:_UpdateHeroInfo()
end

function HeroRetirePage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_filterWay, self._OpenSortPage, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_sort, self._SortOrder, self, nil)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CancelSelect, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._ConfirmSelect, self)
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.SetFleetMsg, function()
    self:_UpdateHeroSort(nil)
  end, self)
  self:RegisterEvent(LuaEvent.RetireHeros, self._GetRetireHerosCallBack, self)
  self:RegisterEvent(LuaEvent.OpenEquipDisPage, self._OpenEquipDisPage, self)
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHeroData, self)
  self:RegisterEvent(LuaEvent.CancelHeroRetire, self._UpdateHeroData, self)
end

function HeroRetirePage:_UpdateHeroInfo()
  local tabHaveShip = Data.heroData:GetHeroData()
  local tabShowHero = Logic.selectedShipPageLogic:FilterHero(0, tabHaveShip)
  self.m_showAllHero = tabShowHero
  local tabButtom = Logic.dockLogic:GetSortButtom()
  self.m_tabButtom = tabButtom
  tabShowHero = HeroSortHelper.FilterAndSort1(tabShowHero, tabButtom.sortParams[1], tabButtom.sortParams[2], tabButtom.sortWay)
  self:_ShowPanel(tabShowHero)
end

function HeroRetirePage:_GetRetireRewardDes()
  self.m_tabWidgets.txt_retireBeforeDes.gameObject:SetActive(next(self.m_tabSelectId) == nil)
  self.m_tabWidgets.txt_haveRetireDes.gameObject:SetActive(next(self.m_tabSelectId) ~= nil)
  self.m_tabWidgets.btn_ok.gameObject:SetActive(next(self.m_tabSelectId) ~= nil)
  self.m_tabWidgets.btn_cancel.gameObject:SetActive(next(self.m_tabSelectId) ~= nil)
  if next(self.m_tabSelectId) == nil then
    self.m_tabWidgets.txt_retireBeforeDes.text = UIHelper.GetString(920000196)
  else
    local mergeItemInfo = Logic.dockLogic:GetHeroRetireReward(self.m_tabSelectId)
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trans_getItem, #mergeItemInfo, function(nIndex, tabPart)
      local num = mergeItemInfo[nIndex][3]
      local icon = Logic.shopLogic:GetTable_Index_Info(mergeItemInfo[nIndex]).icon_small
      UIHelper.SetImage(tabPart.im_icon, icon)
      UIHelper.SetText(tabPart.txt_num, num)
    end)
  end
end

function HeroRetirePage:_UpdateHeroData(param)
  self.m_tabSelectId = param and param or {}
  self:_UpdateHeroInfo()
end

function HeroRetirePage:_CheckIsSame(tabMergeInfo, tabItemIfo)
  if #tabMergeInfo == 0 then
    return false
  end
  for index = 1, #tabMergeInfo do
    if tabMergeInfo[index][1] == tabItemIfo[1] and tabMergeInfo[index][2] == tabItemIfo[2] then
      tabMergeInfo[index].Num = tabMergeInfo[index].Num + tabItemIfo[3]
      return true
    end
  end
  return false
end

function HeroRetirePage:_UpdateHeroSort(sortParams)
  sortParams = sortParams or Logic.dockLogic:GetSortButtom().sortParams
  self.m_tabButtom.sortParams = sortParams
  Logic.dockLogic:SetSortButtom(self.m_tabButtom)
  local tabShowHero = HeroSortHelper.FilterAndSort1(self.m_showAllHero, sortParams[1], sortParams[2], self.m_tabButtom.sortWay)
  self:_ShowPanel(tabShowHero)
end

function HeroRetirePage:_ShowPanel(tabShowHero)
  self.m_showHero = tabShowHero
  local slotNum = Logic.dockLogic:GetSlotValue(#tabShowHero, 6)
  self:_SetCardItem(slotNum, tabShowHero)
  self:_UpdateSelctShipNumText()
  self:_GetRetireRewardDes()
end

function HeroRetirePage:_SetCardItem(slotNum, tabData)
  self.m_tabPart = {}
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_shiplist, self.m_tabWidgets.obj_ship, #tabData, function(tabPart)
    local tabSelectIndex = {}
    if #self.m_tabSelectId ~= 0 then
      for k, v in pairs(self.m_tabSelectId) do
        local index = Logic.dockLogic:GetIndexByHeroId(tabData, v)
        table.insert(tabSelectIndex, index)
      end
    end
    local tabTemp = {}
    for k, v in pairs(tabPart) do
      tabTemp[tonumber(k)] = v
    end
    self.m_tabPart = tabTemp
    for index, luaPart in pairs(tabTemp) do
      luaPart.im_markbg:SetActive(false)
      ShipCardItem:LoadVerticalCard(tabData[index].HeroId, luaPart.cardPart)
      local lv = math.tointeger(tabData[index].Lvl)
      UIHelper.SetText(luaPart.tx_lv, lv)
      local isInBuilding = Data.buildingData:IsInBuilding(tabData[index].HeroId)
      local isInOutpost, _ = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(tabData[index].HeroId)
      if isInBuilding or isInOutpost then
        luaPart.obj_fleet:SetActive(true)
        local msg = UIHelper.GetString(4600029)
        if isInBuilding then
          msg = UIHelper.GetString(920000168)
        end
        UIHelper.SetText(luaPart.tx_fleet, msg)
      else
        luaPart.obj_fleet:SetActive(false)
      end
      for k, v in pairs(tabSelectIndex) do
        if v == index then
          luaPart.tog_select.isOn = true
          break
        end
      end
      UGUIEventListener.AddButtonToggleChanged(luaPart.tog_select, self._SelectCard, self, {
        heroId = tabData[index].HeroId,
        tog = luaPart.tog_select
      })
    end
  end)
end

function HeroRetirePage:_UpdateSelctShipNumText()
  local nowNum = #self.m_tabSelectId
  local UpNum = self.m_selectUp
  if nowNum > UpNum then
    local str = nowNum .. "/" .. UpNum
    UIHelper.SetTextColor(self.m_tabWidgets.tx_selectNum, str, "ff0000")
  else
    local str = "<color=#ffffff>" .. nowNum .. "</color>"
    str = str .. "/" .. "<color=#677c99>" .. UpNum .. "</color>"
    UIHelper.SetText(self.m_tabWidgets.tx_selectNum, str)
  end
  local tabButtom = Logic.dockLogic:GetSortButtom()
  local tog = tabButtom.sortWay
  if tog then
    UIHelper.SetText(self.m_tabWidgets.tx_sort, UIHelper.GetString(920000194))
  else
    UIHelper.SetText(self.m_tabWidgets.tx_sort, UIHelper.GetString(920000195))
  end
  self.m_tabWidgets.tog_sort.isOn = tog
  UIHelper.SetText(self.m_tabWidgets.tx_way, HeroSortHelper.GetSortName(tabButtom.sortParams[2]))
end

function HeroRetirePage:_SelectCard(go, isOn, params)
  for _, part in pairs(self.m_tabPart) do
    if part.tog_select.isOn then
      part.tween_select:ResetToInit()
      part.tween_select:Play(true)
    end
  end
  self.m_selectId = params.heroId
  self.m_nowTog = params.tog
  local pos = self:_IsSelected(self.m_tabSelectId, params.heroId)
  if #self.m_tabSelectId >= self.m_selectUp then
    if self.m_nowTog.isOn == true then
      self.m_nowTog.isOn = not isOn
      local str = string.format(UIHelper.GetString(200004), self.m_selectUp)
      noticeManager:ShowTip(str)
      return
    else
      table.remove(self.m_tabSelectId, pos)
      self:_UpdateSelctShipNumText()
      self:_GetRetireRewardDes()
      return
    end
  end
  if pos then
    self.m_nowTog.isOn = false
    table.remove(self.m_tabSelectId, pos)
  else
    local inbuild = Logic.shipLogic:IsInBuilding(params.heroId)
    local inOutpost, _ = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(params.heroId)
    local isCombining = Logic.shipCombinationLogic:IfCombining(params.heroId)
    local msgNum = 920000165
    if inbuild or inOutpost or isCombining then
      params.tog.isOn = not isOn
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            params.tog.isOn = true
            table.insert(self.m_tabSelectId, params.heroId)
            self:_UpdateSelctShipNumText()
            self:_GetRetireRewardDes()
          end
        end
      }
      if inbuild then
        msgNum = 920000165
      elseif inOutpost then
        msgNum = 4600035
      elseif isCombining then
        msgNum = 4900019
      end
      noticeManager:ShowMsgBox(UIHelper.GetString(msgNum), tabParams)
      return
    end
    self.m_nowTog.isOn = true
    table.insert(self.m_tabSelectId, params.heroId)
  end
  self:_UpdateSelctShipNumText()
  self:_GetRetireRewardDes()
end

function HeroRetirePage:_IsSelected(tabSelectId, heroId)
  for k, v in pairs(tabSelectId) do
    if v == heroId then
      return k
    end
  end
  return nil
end

function HeroRetirePage:_OpenSortPage()
  UIHelper.OpenPage("SortPage", self.m_tabButtom.sortParams)
end

function HeroRetirePage:_SortOrder(go, isOn)
  self.m_tabButtom.sortWay = isOn
  Logic.dockLogic:SetSortButtom(self.m_tabButtom)
  if isOn then
    UIHelper.SetText(self.m_tabWidgets.tx_sort, UIHelper.GetString(920000194))
  else
    UIHelper.SetText(self.m_tabWidgets.tx_sort, UIHelper.GetString(920000195))
  end
  local tabButtom = Logic.dockLogic:GetSortButtom()
  self.m_showHero = HeroSortHelper.FilterAndSort1(self.m_showHero, tabButtom.sortParams[1], tabButtom.sortParams[2], isOn)
  self:_ShowPanel(self.m_showHero)
end

function HeroRetirePage:_CancelSelect()
  self.m_tabSelectId = {}
  self:DoOnOpen()
end

function HeroRetirePage:_ConfirmSelect()
  if #self.m_tabSelectId < 0 then
    noticeManager:ShowTip(UIHelper.GetString(920000166))
    return
  end
  UIHelper.OpenPage("HeroRetireTip", self.m_tabSelectId)
end

function HeroRetirePage:_GetRetireHerosCallBack(param)
  self.m_tabSelectId = {}
  if next(param.Reward) ~= nil then
    local params = {
      Rewards = param.Reward,
      Page = "HeroRetirePage"
    }
    UIHelper.OpenPage("GetRewardsPage", params)
  else
    self:_OpenEquipDisPage()
  end
end

function HeroRetirePage:_OpenEquipDisPage()
  Logic.dockLogic:EquipDeleteTipWRAP()
end

function HeroRetirePage:DoOnHide()
end

function HeroRetirePage:DoOnClose()
end

return HeroRetirePage
