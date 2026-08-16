local WishCdPage = class("UI.Illustrate.WishCdPage", LuaUIPage)

function WishCdPage:DoInit()
end

function WishCdPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnBtnOkClick, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancle, self._OnBtnCancleClick, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnBtnCancleClick, self)
end

function WishCdPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local stype = params.type
  if stype == "desc" then
    widgets.cd_desc_root.gameObject:SetActive(true)
    widgets.cd_result_root.gameObject:SetActive(false)
    self:_InitDesc()
  else
    widgets.cd_desc_root.gameObject:SetActive(false)
    widgets.cd_result_root.gameObject:SetActive(true)
    self:_InitCdResult()
  end
end

function WishCdPage:_InitDesc()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.desc_info_1, Logic.wishLogic:GetBanHeroAddTimeStr())
  UIHelper.SetText(widgets.desc_info_2, Logic.wishLogic:GetResChargeTimeStrByQuality(ShipQuality.SR))
  UIHelper.SetText(widgets.desc_info_3, Logic.wishLogic:GetResChargeTimeStrByQuality(ShipQuality.SSR))
  UIHelper.SetText(widgets.desc_info_4, Logic.wishLogic:GetChargeUpStr(ShipQuality.SR))
  UIHelper.SetText(widgets.desc_info_5, Logic.wishLogic:GetChargeUpStr(ShipQuality.SSR))
  UIHelper.SetText(widgets.desc_info_6, Logic.wishLogic:GetHeroChargeTimeStrByQuality(ShipQuality.SR))
  UIHelper.SetText(widgets.desc_info_7, Logic.wishLogic:GetHeroChargeTimeStrByQuality(ShipQuality.SSR))
end

function WishCdPage:_InitCdResult()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.result_info_1, Logic.wishLogic:GetBanHeroAddTimeStr())
  UIHelper.SetText(widgets.result_info_2, Logic.wishLogic:GetVowResultAddTimeStr())
  UIHelper.SetText(widgets.result_info_3, Logic.wishLogic:GetLimitTimeStr())
  local finalTimeStr, isLimit = Logic.wishLogic:GetFinalChargeTimeStr()
  UIHelper.SetText(widgets.result_info_4, finalTimeStr)
  local maxStr = isLimit and UIHelper.GetString(951032) or ""
  UIHelper.SetText(widgets.max, maxStr)
end

function WishCdPage:_ClosePage()
  UIHelper.ClosePage("WishCdPage")
end

function WishCdPage:_OnBtnOkClick()
  self:_ClosePage()
end

function WishCdPage:_OnBtnCancleClick()
  self:_ClosePage()
end

function WishCdPage:DoOnHide()
end

function WishCdPage:DoOnClose()
end

return WishCdPage
