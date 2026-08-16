RechargePayBackPage = class("UI.Recharge.RechargePayBackPage", LuaUIPage)

function RechargePayBackPage:DoInit()
  self.m_tabWidgets = nil
end

function RechargePayBackPage:DoOnOpen()
  local payBackInfo = platformManager:GetPayBackInfo()
  self.goldNum = payBackInfo and payBackInfo.returnGold or 0
  self.cardNum = payBackInfo and payBackInfo.returnMonthCard or 0
  self.moneyNum = payBackInfo and payBackInfo.money or 0
  self:_ShowInfo(self.goldNum, self.cardNum)
end

function RechargePayBackPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self._GetReward, self)
  self:RegisterEvent(LuaEvent.RechargePayBackSuccess, self._RechargePayBackSuccess, self)
end

function RechargePayBackPage:_ShowInfo(goldNum, cardNum)
  local hascard = cardNum and 0 < cardNum
  local rmbNum = self.moneyNum
  UIHelper.SetText(self.tab_Widgets.txt_rule, configManager.GetDataById("config_language", 470002).content)
  UIHelper.SetText(self.tab_Widgets.txt_tips, configManager.GetDataById("config_language", 470003).content)
  local rewardStr = ""
  if hascard then
    rewardStr = string.format(configManager.GetDataById("config_language", 470000).content, rmbNum, goldNum, cardNum)
    self.getStr = string.format(configManager.GetDataById("config_language", 470004).content, goldNum, cardNum)
  else
    rewardStr = string.format(configManager.GetDataById("config_language", 470001).content, rmbNum, goldNum)
    self.getStr = string.format(configManager.GetDataById("config_language", 470006).content, goldNum)
  end
  UIHelper.SetText(self.tab_Widgets.txt_reward, rewardStr)
end

function RechargePayBackPage:_GetReward()
  local tblParam = {
    msgType = NoticeType.TwoButton,
    callback = function(bOk)
      if bOk then
        Service.rechargeService:GetPaybackReward(self.goldNum, self.cardNum)
      end
    end
  }
  noticeManager:ShowMsgBox(self.getStr, tblParam)
end

function RechargePayBackPage:_RechargePayBackSuccess(state)
  if state then
    local tblParam = {
      callback = function()
        self:_CloseSelf()
      end
    }
    noticeManager:ShowMsgBox(configManager.GetDataById("config_language", 470005).content, tblParam)
  else
    noticeManager:ShowMsgBox(configManager.GetDataById("config_language", 470007).content)
  end
end

function RechargePayBackPage:_CloseSelf()
  UIHelper.ClosePage("RechargePayBackPage")
end

function RechargePayBackPage:DoOnHide()
end

function RechargePayBackPage:DoOnClose()
end

return RechargePayBackPage
