local NewFirstRechargePage = class("UI.page.NewFirstRechargePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local RechargePage = require("ui.page.Recharge.RechargePage")

function NewFirstRechargePage:DoInit()
  self.mTogList = {
    self.tab_Widgets.objFirstRechargePartial,
    self.tab_Widgets.objMonthPartial
  }
  self.mTogIndex = 1
  self.achieveId = Logic.achieveLogic:GetGlobalAchieveId()
end

function NewFirstRechargePage:RegisterAllEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupLabel, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMask, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_recharge, self._Recharge, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fetch, self._Fetch, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_monthCard, self._OnMonthCardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_check, self._CheckPrivilege, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosCheck, self._CheckPrivilege, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosAutoBuy, self._OnSubMonthCardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_iosBuy, self._OnMonthCardClick, self)
  self:RegisterEvent(LuaEvent.UpdataRechargeInfo, self.OnBuySuccess, self)
  self:RegisterEvent(LuaEvent.FreeSubscribeStateCallBack, self._UpdateFreeState, self)
  self:RegisterEvent(LuaEvent.BuyRechargeItem, self._BuyItem, self)
end

function NewFirstRechargePage:DoOnOpen()
  self.tab_Widgets.tgGroupLabel:SetActiveToggleIndex(self.mTogIndex - 1)
end

function NewFirstRechargePage:ShowPage()
  for tgindex, obj in ipairs(self.mTogList) do
    obj:SetActive(tgindex == self.mTogIndex)
  end
  if self.mTogIndex == 1 then
    self:ShowFirstRechargePartial()
  else
    self:ShowMonthPartial()
  end
end

function NewFirstRechargePage:_SwitchTogs(index)
  self.mTogIndex = index + 1
  self:ShowPage()
end

function NewFirstRechargePage:ShowFirstRechargePartial()
  local achieveConfig = configManager.GetDataById("config_achievement", self.achieveId)
  local rewardId = achieveConfig.rewards
  local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
  local num = #rewards
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_item, num, function(index, tabPart)
    local rewardInfo = rewards[index]
    local displayInfo = Logic.goodsLogic.AnalyGoods(rewardInfo)
    UIHelper.SetImage(tabPart.imgIcon, displayInfo.texIcon)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    tabPart.textName.text = displayInfo.name
    tabPart.textNum.text = rewardInfo.Num
    UGUIEventListener.AddButtonOnClick(tabPart.button, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewardInfo.Type, rewardInfo.ConfigId))
    end)
  end)
  local status = Logic.taskLogic:GetTaskFinishState(self.achieveId, TaskType.Achieve)
  self.tab_Widgets.btn_recharge.gameObject:SetActive(status == TaskState.TODO)
  self.tab_Widgets.btn_fetch.gameObject:SetActive(status == TaskState.FINISH)
  self.tab_Widgets.btn_fetched.gameObject:SetActive(status == TaskState.RECEIVED)
end

function NewFirstRechargePage:ShowMonthPartial()
  local os = platformManager:GetOS()
  self.monthCard, self.subscribeCard = Logic.rechargeLogic:GetMonthCardData()
  self.tab_Widgets.obj_monthCard:SetActive(not self.subscribeCard)
  self.tab_Widgets.obj_iosMonth:SetActive(self.subscribeCard ~= nil)
  if not self.subscribeCard then
    if not self.monthCard then
      return
    end
    local showName = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and self.monthCard.name or self.monthCard.show_name
    UIHelper.SetText(self.tab_Widgets.txt_month_name, showName)
    UIHelper.SetText(self.tab_Widgets.txt_month_price, self.monthCard.true_cost)
    local days = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if days and 0 < days then
      self.tab_Widgets.txt_cardTime.gameObject:SetActive(true)
      UIHelper.SetText(self.tab_Widgets.txt_cardTime, UIHelper.GetString(920000293) .. tostring(math.tointeger(days)) .. UIHelper.GetString(920000030))
    else
      self.tab_Widgets.txt_cardTime.gameObject:SetActive(false)
    end
  else
    Logic.rechargeLogic:GetFreeSubscribeState()
    if not self.monthCard then
      return
    end
    local monthDays = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if monthDays and 0 < monthDays then
      self.tab_Widgets.btn_iosBuy.enabled = false
      UIHelper.SetImage(self.tab_Widgets.img_iosBuy, "uipic_ui_shop_bg_jingxuanlibao_goumai")
      UIHelper.SetText(self.tab_Widgets.txt_iosBuy, UIHelper.GetString(920000294))
    else
      self.tab_Widgets.btn_iosBuy.enabled = true
      UIHelper.SetImage(self.tab_Widgets.img_iosBuy, "uipic_ui_shouchong_bu_yueka_goumai")
      UIHelper.SetText(self.tab_Widgets.txt_iosBuy, UIHelper.GetString(920000295))
    end
    local days = Logic.rechargeLogic:GetDaysRemaining(self.monthCard.id)
    if days and 0 < days then
      self.tab_Widgets.txt_iosMonthTime.gameObject:SetActive(true)
      UIHelper.SetText(self.tab_Widgets.txt_iosMonthTime, UIHelper.GetString(920000293) .. tostring(math.tointeger(days)) .. UIHelper.GetString(920000030))
    else
      self.tab_Widgets.txt_iosMonthTime.gameObject:SetActive(false)
    end
  end
end

function NewFirstRechargePage:_UpdateFreeState(ret)
  if not self.subscribeCard then
    return
  end
  if ret == 0 and 0 > self.subscribeCard.free_duration then
    self.tab_Widgets.btn_iosAutoBuy.enabled = true
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_shop_bg_jingxuanlibao_goumai")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, UIHelper.GetString(920000296))
    return
  end
  local subscribeDays = Logic.rechargeLogic:GetSubscribeRemaining()
  if subscribeDays then
    self.tab_Widgets.btn_iosAutoBuy.enabled = false
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_shop_bg_jingxuanlibao_goumai")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, UIHelper.GetString(920000297))
  else
    self.tab_Widgets.btn_iosAutoBuy.enabled = true
    UIHelper.SetImage(self.tab_Widgets.img_iosAutoBuy, "uipic_ui_shouchong_bu_yueka_goumai")
    UIHelper.SetText(self.tab_Widgets.txt_iosAuto, UIHelper.GetString(920000298))
  end
end

function NewFirstRechargePage:_OnMonthCardClick()
  local monthCard = self.monthCard
  if monthCard then
    self:ShowRecharge(monthCard)
  end
end

function NewFirstRechargePage:ShowRecharge(rechargeCfg)
  local args = {}
  
  function args.func(param)
    eventManager:SendEvent(LuaEvent.BuyRechargeItem, rechargeCfg)
  end
  
  local days = Logic.rechargeLogic:GetDaysRemaining(rechargeCfg.id)
  if days and 0 < days then
    args.days = days
  end
  args.info = rechargeCfg
  self.buyGift = rechargeCfg
  UIHelper.OpenPage("MonthCardBuyPage", args)
end

function NewFirstRechargePage:_CheckPrivilege()
  local monthCard = self.monthCard
  if monthCard then
    UIHelper.OpenPage("PrivilegePage", monthCard.privilegedesc)
  end
end

function NewFirstRechargePage:_OnSubMonthCardClick()
  local monthCard = self.subscribeCard
  if monthCard then
    self:ShowRecharge(monthCard)
  end
end

function NewFirstRechargePage:OnBuySuccess()
  self:ShowMonthPartial()
  if self.buyGift ~= nil and self.buyGift.paytype then
    local serverData = Logic.rechargeLogic:GetServerDataById(self.buyGift.id)
    local buyTimes = serverData == nil and 0 or serverData.BuyTimes
    local dotInfo = {
      info = "success_rechage",
      type = self.buyGift.paytype,
      cost = self.buyGift.true_cost,
      recharge_id = self.buyGift.id,
      buy_time = buyTimes
    }
    RetentionHelper.Retention(PlatformDotType.recharge, dotInfo)
    self.buyGift = nil
  end
end

function NewFirstRechargePage:_BuyItem(info)
  if self.mRechargePage == nil then
    self.mRechargePage = RechargePage:new(self)
  end
  self.mRechargePage:_BuyItem(info)
end

function NewFirstRechargePage:DoOnClose()
  Logic.activityLogic:SetFirstRecharge(true)
end

function NewFirstRechargePage:DoOnHide()
end

function NewFirstRechargePage:_Recharge()
  if platformManager:useSDK() then
    Logic.shopLogic:OpenRechargeShop()
  end
end

function NewFirstRechargePage:_Fetch()
  Service.taskService:SendTaskReward(self.achieveId, TaskType.Achieve)
end

function NewFirstRechargePage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "NewFirstRechargePage")
end

return NewFirstRechargePage
