local AgreementPage = class("UI.AgreementPage", LuaUIPage)

function AgreementPage:DoInit()
end

function AgreementPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_refuse, function()
    self:_ClickRefuse()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_agree, function()
    self:_ClickAgree()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_know, function()
    self:_ClickKnow()
  end)
end

function AgreementPage:DoOnOpen()
  self.aType = self.param.aType
  local url = self.param.url
  self.tab_Widgets.obj_oneButton:SetActive(self.aType ~= UserAgreementType.AgreementAndPrivacy)
  self.tab_Widgets.obj_twoButton:SetActive(self.aType == UserAgreementType.AgreementAndPrivacy)
  local tipWidth, tipHeight, posLeftX, posLeftY = self:CaculateSize()
  platformManager:openCustomWebView(url, tipWidth, tipHeight, posLeftX, posLeftY, "0", nil)
end

function AgreementPage:CaculateSize(param)
  local subwidth = self.tab_Widgets.im_notice.rect.width
  local subheight = self.tab_Widgets.im_notice.rect.height
  local subPosX = self.tab_Widgets.im_notice.anchoredPosition.x
  local subPosY = self.tab_Widgets.im_notice.anchoredPosition.y
  local uiRoot = UIManager.rootUI:GetComponent(RectTransform.GetClassType())
  local rootWidth = uiRoot.rect.width
  local rootHeight = uiRoot.rect.height
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  if isWindows then
    if param then
      deviceWidth = param.w
      deviceHeight = param.h
    else
      deviceWidth = Screen.width
      deviceHeight = Screen.height
    end
  end
  local tipWidth = subwidth * deviceWidth / rootWidth
  local tipHeight = subheight * deviceHeight / rootHeight
  subPosX = subPosX * deviceWidth / rootWidth
  subPosY = subPosY * deviceHeight / rootHeight
  local posLeftX = deviceWidth / 2 - tipWidth / 2 + subPosX
  local posLeftY = deviceHeight / 2 - tipHeight / 2 - subPosY
  return tipWidth, tipHeight, posLeftX, posLeftY
end

function AgreementPage:_ClickRefuse()
  self.callBackStatus = "1"
  self:_ClosePage()
end

function AgreementPage:_ClickAgree()
  self.callBackStatus = "2"
  self:_ClosePage()
end

function AgreementPage:_ClickKnow()
  self.callBackStatus = "0"
  self:_ClosePage()
end

function AgreementPage:DoOnHide()
end

function AgreementPage:DoOnClose()
  platformManager:closeCustomWebView()
  if self.param.callBack then
    self.param.callBack(self.callBackStatus)
  end
end

function AgreementPage:_ClosePage()
  UIHelper.ClosePage("AgreementPage")
end

return AgreementPage
