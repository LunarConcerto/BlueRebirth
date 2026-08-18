local LimitGiftPage = class("UI.Activity.LimitGiftPage", LuaUIPage)

function LimitGiftPage:DoInit()
  self.selectIndex = 1
  self.rechargeId = 0
  self.limitGiftList = {}
  self.limitTimer = nil
end

function LimitGiftPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self.OnBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self.OnBtnRightClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self.OnBtnLeftClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_buy, self.OnBtnBuyClick, self)
end

function LimitGiftPage:DoOnOpen()
  local params = self:GetParam()
  if type(params) == "number" then
    self.selectIndex = params
  elseif type(params) == "table" and next(params) then
    self.selectIndex = params[1]
  else
    self.selectIndex = 1
  end
  self.limitGiftList = Data.activityData:GetLimitGiftList()
  self:ShowLimitGift(self.selectIndex)
end

function LimitGiftPage:ShowLimitGift(index)
  if #self.limitGiftList <= 0 then
    return
  end
  if index > #self.limitGiftList then
    index = #self.limitGiftList
  end
  self.tab_Widgets.btn_right.gameObject:SetActive(index < #self.limitGiftList)
  self.tab_Widgets.btn_left.gameObject:SetActive(1 < index)
  self.rechargeId = self.limitGiftList[index].id
  local cfg = configManager.GetDataById("config_recharge", self.limitGiftList[index].id)
  UIHelper.SetText(self.tab_Widgets.txt_title, cfg.show_name)
  UIHelper.SetText(self.tab_Widgets.txt_des, cfg.desc)
  local icon = Logic.goodsLogic:GetSmallIcon(cfg.currency_type, GoodsType.CURRENCY)
  UIHelper.SetImage(self.tab_Widgets.img_cost, tostring(icon), true)
  UIHelper.SetText(self.tab_Widgets.txt_cost, cfg.true_cost)
  self.tab_Widgets.btn_buy.gameObject:SetActive(true)
  self:CloseLimitTime()
  local starTime = time.getSvrTime()
  local remainTime = self.limitGiftList[index].endTime - starTime
  if 0 <= remainTime then
    local function func()
      local curTime = time.getSvrTime()
      
      local curRemainTime = self.limitGiftList[index].endTime - curTime
      if 0 < curRemainTime then
        local timeRemainStr = time.getHoursString(curRemainTime)
        UIHelper.SetText(self.tab_Widgets.txt_time, timeRemainStr)
      else
        self:CloseLimitTime()
        self.tab_Widgets.btn_buy.gameObject:SetActive(false)
      end
    end
    
    self.limitTimer = Timer.New(func, 1, -1, false)
    self.limitTimer:Start()
  else
    self.tab_Widgets.btn_buy.gameObject:SetActive(false)
  end
  local rewards = configManager.GetDataById("config_rewards", cfg.reward).rewards
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_rewards, #rewards, function(index, uiPart)
    local rewardInfo = rewards[index]
    local itemType = rewardInfo[1]
    local itemId = rewardInfo[2]
    local num = "x" .. rewardInfo[3]
    local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
    local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
    local name = Logic.goodsLogic:GetName(itemId, itemType)
    UIHelper.SetImage(uiPart.img_icon, icon)
    UIHelper.SetImageByQuality(uiPart.img_bg, quality)
    UIHelper.SetText(uiPart.txt_num, num)
    UIHelper.SetText(uiPart.txt_name, name)
    
    local function clickFunc()
      Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
    end
    
    UGUIEventListener.AddButtonOnClick(uiPart.btn_clickBtn, clickFunc)
  end)
end

function LimitGiftPage:CloseLimitTime()
  if self.limitTimer then
    self.limitTimer:Stop()
    self.limitTimer = nil
  end
end

function LimitGiftPage:OnBtnRightClick()
  self.selectIndex = self.selectIndex + 1
  self:ShowLimitGift(self.selectIndex)
end

function LimitGiftPage:OnBtnLeftClick()
  self.selectIndex = self.selectIndex - 1
  self:ShowLimitGift(self.selectIndex)
end

function LimitGiftPage:OnBtnBuyClick()
  if self.rechargeId <= 0 then
    return
  end
  local cfg = configManager.GetDataById("config_recharge", self.rechargeId)
  local tabCondition = {
    {
      CurrencyId = cfg.currency_type,
      CostNum = cfg.true_cost
    }
  }
  local isCan = conditionCheckManager:CheckCurrencyIsEnough(tabCondition, true)
  if not isCan then
    logError("\233\146\177\228\184\141\229\164\159 cfg.currency_type:%d cfg.true_cost:%d", cfg.currency_type, cfg.true_cost)
    return
  end
  Service.rechargeService:DirectBuyItemCallBack(self.rechargeId)
  self:OnBtnCloseClick()
end

function LimitGiftPage:OnBtnCloseClick()
  Data.activityData:SetLimitGiftListState()
  UIHelper.ClosePage(self:GetName())
end

function LimitGiftPage:DoOnHide()
  self:CloseLimitTime()
end

function LimitGiftPage:DoOnClose()
  self:CloseLimitTime()
end

return LimitGiftPage
