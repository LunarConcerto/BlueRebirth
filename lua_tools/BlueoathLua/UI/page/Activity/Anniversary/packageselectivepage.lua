local PackageSelectivePage = class("ui.page.Activity.Anniversary.PackageSelectivePage", LuaUIPage)

function PackageSelectivePage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.serSelectiveInfo = {}
end

function PackageSelectivePage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:_ShowActivityTime()
  self:_ShowPackage()
end

function PackageSelectivePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdatePackageSelect, self._ShowPackage, self)
  self:RegisterEvent(LuaEvent.RechargeGetRewards, self._ShowRechargeRewards, self)
  self:RegisterEvent(LuaEvent.RechargeGetRewardsErr, self._ShowErrMsg, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeBuy, self._ClickCloseBuy, self)
end

function PackageSelectivePage:_ShowActivityTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.txt_actTime, startTime .. " - " .. endTime)
end

function PackageSelectivePage:_ShowPackage()
  local packageIdTab = self.actConfig.p1
  local serData = Data.rechargeData:GetSelectiveInfo()
  for _, v in ipairs(serData) do
    self.serSelectiveInfo[v.RechargeId] = v.BuyTimes
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.iil_package, self.tab_Widgets.obj_item, #packageIdTab, function(tabParts, index)
    for nIndex, tabPart in pairs(tabParts) do
      local packageInfo = configManager.GetDataById("config_recharge_selective", packageIdTab[tonumber(nIndex)])
      tabPart.tx_title.text = packageInfo.name
      tabPart.obj_times.gameObject:SetActive(packageInfo.limit ~= -1)
      local buyTimes = self.serSelectiveInfo[packageInfo.id] and self.serSelectiveInfo[packageInfo.id] or 0
      local repertory = packageInfo.limit - buyTimes
      tabPart.tx_times.text = repertory
      tabPart.obj_unable:SetActive(packageInfo.limit ~= -1 and repertory <= 0)
      tabPart.obj_basicReward:SetActive(packageInfo.basic_reward ~= 0)
      tabPart.obj_plus:SetActive(packageInfo.basic_reward ~= 0)
      if packageInfo.basic_reward ~= 0 then
        local basicReward = Logic.rewardLogic:FormatRewardById(packageInfo.basic_reward)
        local rewardInfo = Logic.bagLogic:GetItemByTempateId(basicReward[1].Type, basicReward[1].ConfigId)
        UIHelper.SetImage(tabPart.im_basicRBg, QualityIcon[rewardInfo.quality])
        UIHelper.SetImage(tabPart.img_basicIcon, tostring(rewardInfo.icon))
        tabPart.tx_basicNum.text = basicReward[1].Num
        UGUIEventListener.AddButtonOnClick(tabPart.btn_basicReward, self._ClickItem, self, basicReward[1])
      end
      local canSelectInfo = Logic.packageSelectiveLogic:GetCanSelectInfo(packageInfo.id)
      local selectedReward = Logic.packageSelectiveLogic:GetSelectPackageById(packageInfo.id)
      UIHelper.CreateSubPart(tabPart.obj_selectReward, tabPart.trans_selectReward, #canSelectInfo, function(index, part)
        local reward = selectedReward[index]
        part.obj_none:SetActive(reward == nil)
        part.im_quality.gameObject:SetActive(reward ~= nil)
        if reward ~= nil then
          local itemInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
          UIHelper.SetImage(part.im_quality, QualityIcon[itemInfo.quality])
          UIHelper.SetImage(part.img_icon, tostring(itemInfo.icon))
          part.tx_num.text = reward.Num
          UGUIEventListener.AddButtonOnClick(part.btn_reward, self._OpenDetails, self, packageInfo)
        else
          UGUIEventListener.AddButtonOnClick(part.btn_add, self._OpenDetails, self, packageInfo)
        end
      end)
      if table.nums(selectedReward) < #canSelectInfo then
        tabPart.tx_buy.text = UIHelper.GetString(270047)
        UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, self._OpenDetails, self, packageInfo)
      else
        tabPart.tx_buy.text = UIHelper.GetString(190012)
        UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, self._OpneBuyPackage, self, {packageInfo, selectedReward})
      end
    end
  end)
end

function PackageSelectivePage:_OpenDetails(go, packageInfo)
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  UIHelper.OpenPage("PackageSelectiveChoosePage", packageInfo)
end

function PackageSelectivePage:_OpneBuyPackage(go, params)
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  local packageInfo = params[1]
  local selectedReward = params[2]
  local allReward = {}
  if packageInfo.basic_reward ~= 0 then
    local basicReward = Logic.rewardLogic:FormatRewardById(packageInfo.basic_reward)
    table.insert(allReward, {
      Type = basicReward[1].Type,
      ConfigId = basicReward[1].ConfigId,
      Num = basicReward[1].Num
    })
  end
  table.insertto(allReward, selectedReward)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_buyItem, self.tab_Widgets.trans_buyItem, #allReward, function(nIndex, tabParts)
    local reward = allReward[nIndex]
    local itemInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
    UIHelper.SetImage(tabParts.img_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetImage(tabParts.img_icon, tostring(itemInfo.icon))
    tabParts.text_num.text = reward.Num
    tabParts.text_name.text = itemInfo.name
    UGUIEventListener.AddButtonOnClick(tabParts.btn_reward, self._ClickItem, self, reward)
  end)
  local currencyIcon = Logic.goodsLogic:GetSmallIcon(packageInfo.cost[1], GoodsType.CURRENCY)
  UIHelper.SetImage(self.tab_Widgets.img_coseIcon, currencyIcon)
  UIHelper.SetText(self.tab_Widgets.txt_coseNum, packageInfo.cost[2])
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_buyPackage, self._BuyPackage, self, params)
  self.tab_Widgets.obj_buy:SetActive(true)
end

function PackageSelectivePage:_ClickCloseBuy()
  self.tab_Widgets.obj_buy:SetActive(false)
end

function PackageSelectivePage:_BuyPackage(go, params)
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  local packageInfo = params[1]
  local tabInfo = {
    Type = GoodsType.CURRENCY,
    CurrencyId = packageInfo.cost[1],
    CostNum = packageInfo.cost[2]
  }
  local tabCondition = {tabInfo}
  local isCan = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if not isCan then
    return
  end
  local selectedReward = params[2]
  local selectIndex = {}
  for _, v in pairs(selectedReward) do
    table.insert(selectIndex, v.Index - 1)
  end
  Service.rechargeService:SendDirectBuySelectItem(self.activityId, packageInfo.id, selectIndex)
  Logic.packageSelectiveLogic:SetSelectPackage({
    id = packageInfo.id,
    reward = {}
  })
  self:_ClickCloseBuy()
end

function PackageSelectivePage:_ShowRechargeRewards()
  local rewards = Data.rechargeData:GetRechargeRewardData()
  Logic.rewardLogic:ShowCommonReward(rewards, "PackageSelectivePage", nil)
  self:_ShowPackage()
end

function PackageSelectivePage:_ClickItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function PackageSelectivePage:_ShowErrMsg(msg)
  if param == ErrorCode.ErrPackageSelectiveNoReward then
    noticeManager:ShowTipById(270048)
  elseif param == ErrorCode.ErrPackageSelectiveBuyMax then
    noticeManager:ShowTipById(270049)
  else
    logError("send message return errmsg:" .. param)
  end
end

function PackageSelectivePage:DoOnHide()
end

function PackageSelectivePage:DoOnClose()
end

return PackageSelectivePage
