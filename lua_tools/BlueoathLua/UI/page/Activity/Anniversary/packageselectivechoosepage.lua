local PackageSelectiveChoosePage = class("ui.page.Activity.Anniversary.PackageSelectiveChoosePage", LuaUIPage)

function PackageSelectiveChoosePage:DoInit()
  self.packageInfo = {}
  self.leftPart = {}
  self.selectedReward = {}
  self.beforLeftPart = nil
  self.beforRightPart = nil
  self.canSelectInfo = nil
  self.leftIndex = 0
  self.rightIndex = 0
end

function PackageSelectiveChoosePage:DoOnOpen()
  self.packageInfo = self:GetParam()
  self.selectedReward = Logic.packageSelectiveLogic:GetSelectPackageById(self.packageInfo.id)
  self.canSelectInfo = Logic.packageSelectiveLogic:GetCanSelectInfo(self.packageInfo.id)
  self:_ShowLeftInfo()
end

function PackageSelectiveChoosePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_next, self._ClickNext, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_clean, self._ClickClean, self)
end

function PackageSelectiveChoosePage:_ShowLeftInfo()
  self.beforLeftPart = nil
  UIHelper.CreateSubPart(self.tab_Widgets.obj_leftItem, self.tab_Widgets.trans_left, #self.canSelectInfo, function(nIndex, tabParts)
    local reward = self.selectedReward[nIndex]
    tabParts.obj_item:SetActive(reward ~= nil)
    tabParts.obj_select:SetActive(false)
    if reward ~= nil then
      local itemInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
      UIHelper.SetImage(tabParts.im_quality, QualityIcon[itemInfo.quality])
      UIHelper.SetImage(tabParts.im_icon, tostring(itemInfo.icon))
      tabParts.tx_num.text = reward.Num
    end
    table.insert(self.leftPart, tabParts)
    UGUIEventListener.AddButtonOnClick(tabParts.btn_select, self._ClickPlus, self, {
      self.canSelectInfo[nIndex],
      tabParts,
      nIndex
    })
    if nIndex == 1 then
      self:_ClickPlus(nil, {
        self.canSelectInfo[nIndex],
        tabParts,
        nIndex
      })
    end
  end)
end

function PackageSelectiveChoosePage:_ClickPlus(go, params)
  local rewardsTab = params[1]
  local tabParts = params[2]
  local index = params[3]
  local selectReward = self.selectedReward[index]
  if self.beforLeftPart ~= nil and self.leftIndex ~= index then
    self.beforLeftPart.obj_select:SetActive(false)
  elseif self.beforLeftPart ~= nil then
    self.selectedReward[index] = nil
    selectReward = nil
    self.tab_Widgets.btn_ok.gameObject:SetActive(#self.canSelectInfo == table.nums(self.selectedReward))
    self.tab_Widgets.btn_next.gameObject:SetActive(#self.canSelectInfo > table.nums(self.selectedReward))
  end
  self.tab_Widgets.obj_rightSelect:SetActive(selectReward ~= nil)
  self.tab_Widgets.obj_rightEmpty:SetActive(selectReward == nil)
  tabParts.obj_select:SetActive(true)
  tabParts.obj_item:SetActive(selectReward ~= nil)
  self.beforLeftPart = tabParts
  self.leftIndex = index
  self:_ShowRightInfo(rewardsTab, selectReward)
end

function PackageSelectiveChoosePage:_ShowRightInfo(rewardsTab, selectReward)
  UIHelper.CreateSubPart(self.tab_Widgets.trans_rightItem, self.tab_Widgets.trans_right, #rewardsTab, function(nIndex, tabParts)
    local rewardId = rewardsTab[nIndex][1]
    local limitId = rewardsTab[nIndex][2]
    local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
    local itemInfo = Logic.bagLogic:GetItemByTempateId(rewardInfo[1].Type, rewardInfo[1].ConfigId)
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetImage(tabParts.im_icon, tostring(itemInfo.icon))
    tabParts.tx_rewardNum.text = rewardInfo[1].Num
    tabParts.obj_select:SetActive(selectReward ~= nil and selectReward.Index == nIndex)
    tabParts.obj_lock:SetActive(false)
    local msg
    if limitId ~= 0 then
      local reachLimit, _ = Logic.gameLimitLogic.CheckConditionById(limitId)
      if not reachLimit then
        local limitConfig = configManager.GetDataById("config_game_limits", limitId)
        msg = limitConfig.desc .. UIHelper.GetString(270035)
      end
      tabParts.obj_lock.gameObject:SetActive(not reachLimit)
    end
    if selectReward ~= nil and selectReward.Index == nIndex then
      self:_ClickRight(nil, {
        rewardInfo[1],
        msg,
        tabParts,
        nIndex
      })
    end
    UGUIEventListener.AddButtonOnClick(tabParts.btn_select, self._ClickRight, self, {
      rewardInfo[1],
      msg,
      tabParts,
      nIndex
    })
  end)
end

function PackageSelectiveChoosePage:_ClickRight(go, params)
  local selectRReward = params[1]
  local msg = params[2]
  local tabParts = params[3]
  local index = params[4]
  tabParts.obj_select:SetActive(true)
  if self.beforRightPart ~= nil and self.rightIndex ~= index then
    self.beforRightPart.obj_select:SetActive(false)
    self.selectedReward[self.leftIndex] = nil
  end
  self.beforRightPart = tabParts
  self.rightIndex = index
  self.tab_Widgets.obj_rightSelect:SetActive(selectRReward ~= nil)
  self.tab_Widgets.obj_rightEmpty:SetActive(selectRReward == nil)
  self.tab_Widgets.obj_rightLock:SetActive(msg ~= nil)
  local itemInfo = Logic.bagLogic:GetItemByTempateId(selectRReward.Type, selectRReward.ConfigId)
  UIHelper.SetImage(self.tab_Widgets.im_rSQuality, QualityIcon[itemInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.im_rSIcon, tostring(itemInfo.icon))
  self.tab_Widgets.txt_rSNum.text = selectRReward.Num
  self.tab_Widgets.tx_rSName.text = itemInfo.name
  self.tab_Widgets.txt_rSDesc.text = itemInfo.desc
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rSReward, self._ClickItem, self, selectRReward)
  if msg ~= nil then
    self.tab_Widgets.txt_lockTips.text = msg
  elseif self.beforLeftPart ~= nil and msg == nil then
    self.beforLeftPart.obj_item:SetActive(true)
    UIHelper.SetImage(self.beforLeftPart.im_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetImage(self.beforLeftPart.im_icon, tostring(itemInfo.icon))
    self.beforLeftPart.tx_num.text = selectRReward.Num
    selectRReward.Index = index
    self.selectedReward[self.leftIndex] = selectRReward
    Logic.packageSelectiveLogic:SetSelectPackage({
      id = self.packageInfo.id,
      reward = self.selectedReward
    })
  end
  self.tab_Widgets.btn_ok.gameObject:SetActive(#self.canSelectInfo == table.nums(self.selectedReward))
  self.tab_Widgets.btn_next.gameObject:SetActive(#self.canSelectInfo > table.nums(self.selectedReward))
end

function PackageSelectiveChoosePage:_ClickNext()
  local nextIndex = self:GetNextIndex(self.leftIndex + 1)
  self:_ClickPlus(nil, {
    self.canSelectInfo[nextIndex],
    self.leftPart[nextIndex],
    nextIndex
  })
end

function PackageSelectiveChoosePage:GetNextIndex(index)
  if index <= #self.canSelectInfo and self.selectedReward[index] == nil then
    return index
  else
    local x = 0
    if index < #self.canSelectInfo then
      x = index + 1
    elseif index >= #self.canSelectInfo then
      x = 1
    end
    return self:GetNextIndex(x)
  end
end

function PackageSelectiveChoosePage:_ClickClean()
  self.selectedReward = {}
  Logic.packageSelectiveLogic:SetSelectPackage({
    id = self.packageInfo.id,
    reward = self.selectedReward
  })
  self.tab_Widgets.btn_ok.gameObject:SetActive(false)
  self.tab_Widgets.btn_next.gameObject:SetActive(true)
  self:_ShowLeftInfo()
end

function PackageSelectiveChoosePage:_ClickClose()
  eventManager:SendEvent(LuaEvent.UpdatePackageSelect)
  UIHelper.ClosePage("PackageSelectiveChoosePage")
end

function PackageSelectiveChoosePage:_ClickItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function PackageSelectiveChoosePage:DoOnHide()
end

function PackageSelectiveChoosePage:DoOnClose()
end

return PackageSelectiveChoosePage
