local BuyResourcePage = class("UI.BuyResourcePage", LuaUIPage)
local content = {
  {
    id = CurrencyType.SUPPLY,
    mType = "Supply",
    title = UIHelper.GetString(230001),
    configId = {
      55,
      56,
      57
    },
    desc = UIHelper.GetString(230002),
    expend = UIHelper.GetString(230003),
    icon = "uipic_ui_common_im_bujitubiao_da"
  },
  {
    id = CurrencyType.GOLD,
    mType = "Gold",
    title = UIHelper.GetString(230004),
    configId = {
      58,
      59,
      60
    },
    desc = UIHelper.GetString(230005),
    expend = UIHelper.GetString(230003),
    icon = "uipic_ui_im_gold_da"
  }
}

function BuyResourcePage:DoInit()
  self.m_tabWidgets = nil
  self.m_buyAmount = 0
  self.m_buyCount = 0
  self.m_prices = 0
  self.m_pricesTab = nil
  self.m_userInfo = nil
  self.m_buySum = 0
  self.m_content = nil
  self.m_param = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function BuyResourcePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.img_mask, self._ClickCancel, self)
  self:RegisterEvent(LuaEvent.UpdataBuyResource, self._BuySuccess, self)
end

function BuyResourcePage:DoOnOpen()
  self.m_param = self:GetParam()
  self.m_content = content[self.m_param]
  self.m_tabWidgets.txt_title.text = self.m_content.title
  self.m_tabWidgets.txt_desc.text = self.m_content.desc
  UIHelper.SetImage(self.m_tabWidgets.img_icon, self.m_content.icon)
  local quality = Logic.currencyLogic:GetQuality(self.m_content.id)
  UIHelper.SetImage(self.m_tabWidgets.img_quality, QualityIcon[quality])
  self:_GetInfoByConfig()
  self:_SetIcon()
  self:_UpdatePage()
end

function BuyResourcePage:_BuySuccess()
  noticeManager:OpenTipPage(self, 230006)
  self:_UpdatePage()
end

function BuyResourcePage:_GetInfoByConfig()
  local configTab = self.m_content.configId
  self.m_buyAmount = configManager.GetDataById("config_parameter", configTab[1]).value
  self.m_buyCount = configManager.GetDataById("config_parameter", configTab[2]).value
  self.m_pricesTab = configManager.GetDataById("config_parameter", configTab[3]).arrValue
end

function BuyResourcePage:_UpdatePage()
  self.m_userInfo = Data.userData:GetUserData()
  local num = Data.userData:GetCurrency(self.m_content.id)
  self.m_tabWidgets.txt_num.text = math.tointeger(num)
  if self.m_content.id == CurrencyType.SUPPLY then
    self:_CheckResourceRecoverLoop(function()
      local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
      local max = Data.userData:GetCurrencyMax(CurrencyType.SUPPLY)
      self.m_tabWidgets.txt_num.text = math.tointeger(supply)
      return supply >= max
    end)
  end
  self:_ResetBuyTime()
  self:_GetExpendDiam()
  local noBuyNum = self.m_buySum >= self.m_buyCount
  self.m_tabWidgets.txt_finish.gameObject:SetActive(noBuyNum)
  self.m_tabWidgets.obj_expend:SetActive(not noBuyNum)
  if noBuyNum then
    self.m_tabWidgets.txt_finish.text = UIHelper.GetString(230007)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_true, self._ClickCancel, self)
  else
    self.m_tabWidgets.txt_spendNum.text = UIHelper.SetColor(self.m_prices, "33878c")
    self.m_tabWidgets.txt_buyNum.text = UIHelper.SetColor(self.m_buyAmount, "a6892e")
    local num = UIHelper.SetColor(string.format("%s/%s", self.m_buySum, self.m_buyCount), "d54852")
    self.m_tabWidgets.txt_hint.text = string.format(self.m_content.expend, num, 0)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_true, self._ClickTrue, self)
  end
end

function BuyResourcePage:_CheckResourceRecoverLoop(getValueCall)
  if self.recoverTimer then
    self:_StopRecoverTimer()
  end
  self.recoverTimer = self:CreateTimer(function()
    local cancle = getValueCall()
    if cancle and self.recoverTimer then
      self:_StopRecoverTimer()
    end
  end, 60, -1, false)
  self:StartTimer(self.recoverTimer)
end

function BuyResourcePage:_StopRecoverTimer()
  self.recoverTimer:Stop()
  self.recoverTimer = nil
end

function BuyResourcePage:_SetIcon()
  local enable = self.m_content.mType == "Supply"
  self.m_tabWidgets.obj_Supply:SetActive(enable)
  self.m_tabWidgets.obj_Gold:SetActive(not enable)
end

function BuyResourcePage:_ResetBuyTime()
  local buyTime = 0
  local buyNum = 0
  if self.m_param == BuyResource.Supply then
    buyTime = self.m_userInfo.BuySupplyTime
    buyNum = self.m_userInfo.BuySupplyNum
  elseif self.m_param == BuyResource.Gold then
    buyTime = self.m_userInfo.BuyGoldTime
    buyNum = self.m_userInfo.BuyGoldNum
  end
  local sameDay = time.isSameDay(buyTime, time.getSvrTime())
  if sameDay then
    self.m_buySum = math.tointeger(buyNum)
  else
    self.m_buySum = 0
  end
end

function BuyResourcePage:_GetExpendDiam()
  if self.m_buySum > #self.m_pricesTab then
    self.m_prices = self.m_pricesTab[#self.m_pricesTab]
  else
    self.m_prices = self.m_pricesTab[self.m_buySum + 1]
  end
end

function BuyResourcePage:_ClickCancel()
  UIHelper.ClosePage("BuyResourcePage")
end

function BuyResourcePage:_ClickTrue()
  if self.m_userInfo.Diamond < self.m_prices then
    self:_ClickCancel()
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, CurrencyType.DIAMOND)
    return
  end
  if self.m_param == BuyResource.Supply then
    Service.userService:_SendBuySupply()
  elseif self.m_param == BuyResource.Gold then
    Service.userService:_SendBuyGold()
  end
end

function BuyResourcePage:DoOnHide()
end

function BuyResourcePage:DoOnClose()
end

return BuyResourcePage
