local QRCodePage = class("UI.Share.QRCodePage", LuaUIPage)

function QRCodePage:DoInit()
  self.tab_imgQR = {
    [QRCodeType.RightDown] = self.tab_Widgets.img_qr,
    [QRCodeType.LeftDown] = self.tab_Widgets.img_spQR
  }
end

function QRCodePage:DoOnOpen()
  self.qrType = self.param and self.param or QRCodeType.RightDown
  self:_SetInfo()
end

function QRCodePage:_SetInfo()
  local showInfo = self.qrType == QRCodeType.RightDown
  self.tab_Widgets.obj_userInfo:SetActive(showInfo)
  if showInfo then
    self.tab_Widgets.text_playerName.text = Data.userData:GetUserName()
    self.tab_Widgets.text_playerLevel.text = math.tointeger(Data.userData:GetUserLevel())
    self.tab_Widgets.text_serverName.text = Logic.loginLogic.SDKInfo.name
  end
  local showQR = platformManager.qrcode ~= nil and platformManager.qrcode ~= ""
  self.tab_Widgets.obj_showQR:SetActive(showQR and self.qrType == QRCodeType.RightDown)
  self.tab_Widgets.obj_spQR:SetActive(showQR and self.qrType == QRCodeType.LeftDown)
  self.tab_Widgets.obj_noQR:SetActive(not showQR)
  if showQR then
    self.tab_imgQR[self.qrType].texture = UIHelper.GenerateQRImageConstantSize(platformManager.qrcode)
  end
end

function QRCodePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.CreateShareEffect, self._ShowEffect, self)
end

function QRCodePage:_ShareOver()
  UIHelper.ClosePage("QRCodePage")
end

function QRCodePage:_ShowEffect(show)
  if show then
    self:_AddEffect()
  else
    self:_DestroyEffect()
  end
end

function QRCodePage:_AddEffect()
  local effectPath = "effects/prefabs/ui/eff_ui_share_shine"
  self.effectObj = UIHelper.CreateUIEffect(effectPath, self.cs_page.gameObject.transform)
  self.effectObj:AddComponent(UISortEffectComponent.GetClassType())
  self.effectObj.transform.position = Vector3.New(0, 0, 0)
  SoundManager.Instance:PlayAudio("Effect_eff_ui_share_shine")
end

function QRCodePage:_DestroyEffect()
  if self.effectObj ~= nil then
    UIHelper.DestroyUIEffect(self.effectObj)
    self.effectObj = nil
  end
end

function QRCodePage:DoOnHide()
end

function QRCodePage:DoOnClose()
  self:_DestroyEffect()
end

return QRCodePage
