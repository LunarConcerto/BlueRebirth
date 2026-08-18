local PackageSelectivePage = class("ui.page.Activity.Anniversary.PackageSelectivePage", LuaUIPage)

function PackageSelectivePage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.serSelectiveInfo = {}
  self.packagePart = {}
  self.packageInfoTab = {}
  self.tabPartTemp = {}
  self.m_timer = nil
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
  self.packageInfoTab = {}
  self.serSelectiveInfo = {}
  local packageIdTab = self.actConfig.p1
  if #packageIdTab == 0 then
    logError("\230\180\187\229\138\168\232\161\168p1\229\173\151\230\174\181\230\178\161\230\156\137\231\164\188\229\140\133id\230\149\176\230\141\174")
  end
  local serData = Data.rechargeData:GetSelectiveInfo()
  for _, v in pairs(serData) do
    self.serSelectiveInfo[v.RechargeId] = v.BuyTimes
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.iil_package, self.tab_Widgets.obj_item, #packageIdTab, function(tabParts, startIndex, endIndex)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    self.startIndex = startIndex
    self.endIndex = endIndex
    for nIndex, tabPart in pairs(tabTemp) do
      local packageInfo = configManager.GetDataById("config_recharge_selective", packageIdTab[tonumber(nIndex)])
      tabPart.tx_title.text = packageInfo.name
      tabPart.obj_times.gameObject:SetActive(packageInfo.limit ~= -1)
      local buyTimes = self.serSelectiveInfo[packageInfo.id] and self.serSelectiveInfo[packageInfo.id] or 0
      local repertory = packageInfo.limit - buyTimes
      tabPart.tx_times.text = repertory
      tabPart.obj_unable:SetActive(packageInfo.limit ~= -1 and repertory <= 0 and packageInfo.refresh_id == 0)
      tabPart.obj_countdown:SetActive(packageInfo.limit ~= -1 and repertory <= 0 and packageInfo.refresh_id ~= 0)
      if packageInfo.limit ~= -1 and repertory <= 0 and packageInfo.refresh_id ~= 0 then
        local nextRefreshTime = PeriodManager:GetNextRefreshTime(packageInfo.refresh_id)
        local surplusTime = nextRefreshTime - time.getSvrTime()
        tabPart.tx_time.text = UIHelper.GetCountDownStr(surplusTime)
        self.packageInfoTab[nIndex] = {
          nextRefreshTime,
          packageInfo.id
        }
      end
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
        part.obj_red:SetActive(reward == nil and packageInfo.limit ~= -1 and 0 < repertory and packageInfo.refresh_id ~= 0)
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
      tabPart.tx_choose.gameObject:SetActive(table.nums(selectedReward) < #canSelectInfo)
      tabPart.tx_buy.gameObject:SetActive(table.nums(selectedReward) >= #canSelectInfo)
      tabPart.obj_btnRed:SetActive(table.nums(selectedReward) >= #canSelectInfo and packageInfo.limit ~= -1 and 0 < repertory and packageInfo.refresh_id ~= 0)
      if table.nums(selectedReward) < #canSelectInfo then
        UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, self._OpenDetails, self, packageInfo)
      else
        UGUIEventListener.AddButtonOnClick(tabPart.btn_buy, self._OpneBuyPackage, self, {packageInfo, selectedReward})
      end
      self.tabPartTemp[nIndex] = tabPart
    end
  end)
  if next(self.packageInfoTab) == nil then
    self:StopTimer()
  else
    self:CreateCountDown()
  end
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
  self.tab_Widgets.img_coseIcon.gameObject:SetActive(#packageInfo.cost ~= 0)
  self.tab_Widgets.txt_coseNum.gameObject:SetActive(#packageInfo.cost ~= 0)
  if #packageInfo.cost ~= 0 then
    local currencyIcon = Logic.goodsLogic:GetSmallIcon(packageInfo.cost[1], GoodsType.CURRENCY)
    UIHelper.SetImage(self.tab_Widgets.img_coseIcon, currencyIcon)
    UIHelper.SetText(self.tab_Widgets.txt_coseNum, packageInfo.cost[2])
  end
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
  if 0 < #packageInfo.cost then
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

function PackageSelectivePage:CreateCountDown()
  if self.m_timer == nil then
    self.m_timer = self:CreateTimer(function()
      self:_SetLeftTime()
    end, 1, -1)
  else
    self:ResetTimer(self.m_timer, function()
      self:_SetLeftTime()
    end, 1, -1)
  end
  self:StartTimer(self.m_timer)
end

function PackageSelectivePage:_SetLeftTime()
  local svrTime = time.getSvrTime()
  for k, v in pairs(self.packageInfoTab) do
    local nextRefreshTime = v[1]
    local tabPart = self.tabPartTemp[k]
    local surplusTime = nextRefreshTime - svrTime
    if surplusTime <= 0 then
      Data.rechargeData:SetSelectiveInfoOnRefresh(v[2])
      eventManager:SendEvent(LuaEvent.UpdatePackageSelectFree)
      self:StopTimer()
      self:_ShowPackage()
      return
    end
    if self.m_timer and k >= self.startIndex and k <= self.endIndex and tabPart ~= nil then
      tabPart.tx_time.text = UIHelper.GetCountDownStr(surplusTime)
    end
  end
end

function PackageSelectivePage:StopTimer()
  if self.m_timer then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

function PackageSelectivePage:DoOnHide()
  self:StopTimer()
end

function PackageSelectivePage:DoOnClose()
  self:StopTimer()
end

return PackageSelectivePage
