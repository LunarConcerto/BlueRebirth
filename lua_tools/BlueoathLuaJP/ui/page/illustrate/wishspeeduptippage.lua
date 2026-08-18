local WishSpeedupTipPage = class("UI.Illustrate.WishSpeedupTipPage", LuaUIPage)

function WishSpeedupTipPage:DoInit()
  self.timer = nil
  self.time = 0
end

function WishSpeedupTipPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnBtnCancleClick, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnBtnOkClick, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancle, self._OnBtnCancleClick, self)
end

function WishSpeedupTipPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local itemId = params.itemId
  local itemType = params.itemType
  local isSuper = params.isSuper
  self.okCallback = params.okCallback
  local iconId = Logic.goodsLogic:GetTexIcon(itemId, itemType)
  UIHelper.SetImage(widgets.icon, iconId, false)
  local name = Logic.goodsLogic:GetName(itemId, itemType)
  UIHelper.SetText(widgets.icon_name, name)
  if isSuper then
    UIHelper.SetLocText(widgets.icon_time, 951028)
    UIHelper.SetLocText(widgets.tx_content, 951043, name)
    UIHelper.SetImage(widgets.icon_fd, QualityIcon[4])
    local coolTime = Logic.wishLogic:GetCurCoolDownTime()
    UIHelper.SetLocText(widgets.tx_tip_top, 951025, time.getTimeStringFontDynamic(coolTime, true))
    self:_StartTimer(coolTime)
  else
    local quality = Logic.wishLogic:GetQuality(itemId)
    UIHelper.SetImage(widgets.icon_fd, QualityIcon[quality])
    local decTime = Logic.wishLogic:GetWishItemTime(itemId)
    UIHelper.SetText(widgets.icon_time, time.getTimeStringFontDynamic(decTime, true))
    UIHelper.SetLocText(widgets.tx_content, 951021)
    local limitTime = Logic.wishLogic:GetLimitTime()
    UIHelper.SetLocText(widgets.tx_tip_top, 951022, time.getTimeStringFontDynamic(limitTime, true))
  end
end

function WishSpeedupTipPage:_InitUI()
end

function WishSpeedupTipPage:_ClosePage()
  UIHelper.ClosePage("WishSpeedupTipPage")
end

function WishSpeedupTipPage:_OnBtnOkClick()
  if self.okCallback then
    self.okCallback()
  end
  self:_ClosePage()
end

function WishSpeedupTipPage:_OnBtnCancleClick()
  self:_ClosePage()
end

function WishSpeedupTipPage:_StartTimer(coolTime)
  local widgets = self:GetWidgets()
  self.time = coolTime
  self.timer = self:CreateTimer(function()
    self.time = self.time - 1
    UIHelper.SetLocText(widgets.tx_tip_top, 951025, time.getTimeStringFontDynamic(self.time, true))
    if self.time < 0 then
      self:_StopTimer()
    end
  end, 1, -1, false)
  self:StartTimer(self.timer)
end

function WishSpeedupTipPage:_StopTimer()
  if self.timer then
    self:StopTimer(self.timer)
    self.timer = nil
  end
end

function WishSpeedupTipPage:DoOnHide()
  self:_StopTimer()
end

function WishSpeedupTipPage:DoOnClose()
  self:_StopTimer()
end

return WishSpeedupTipPage
