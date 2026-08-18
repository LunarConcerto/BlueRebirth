local TeachUsrSetTip = class("UI.Teaching.TeachUsrSetTip", LuaUIPage)

function TeachUsrSetTip:DoInit()
  self.m_data = nil
  self.m_config = nil
end

function TeachUsrSetTip:DoOnOpen()
  self:_Refresh()
end

function TeachUsrSetTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._OnClickCancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.if_des, self._OnClickIF, self)
  widgets.dd_sex.onValueChanged:AddListener(function(index)
    self:_setSelfInfo(ETeachingIntroGroupId.SEX, index)
  end)
  widgets.dd_time.onValueChanged:AddListener(function(index)
    self:_setSelfInfo(ETeachingIntroGroupId.TIME, index)
  end)
  widgets.dd_attr.onValueChanged:AddListener(function(index)
    self:_setSelfInfo(ETeachingIntroGroupId.ATTR, index)
  end)
  widgets.if_des.onValueChanged:AddListener(function(msg)
    local up = Logic.teachingLogic:GetSignUp()
    local msg, ischarUp = Logic.chatLogic:MsgCut(msg, up)
    if ischarUp then
      noticeManager:ShowTip(UIHelper.GetString(220001))
    end
    widgets.if_des.text = msg
    self:_setSelfDesc(msg)
  end)
  self:RegisterEvent(LuaEvent.ChatMsgMask, self._OnMsgMask, self)
  self:RegisterEvent(LuaEvent.TEACHING_SetInfoOk, self._OnSetOk, self)
end

function TeachUsrSetTip:_Refresh()
  self:_ShowUsrInfo()
end

function TeachUsrSetTip:_ShowUsrInfo()
  self.m_data = Logic.teachingLogic:GetSelfInfo()
  self.m_config = Logic.teachingLogic:GetSelfInfoConfig()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_intro, self.m_data.Sign)
  widgets.if_des.characterLimit = Logic.teachingLogic:GetSignUp()
  self:_setDDOption(widgets.dd_sex, self.m_data[ETeachingIntroGroupId.SEX], self.m_config[ETeachingIntroGroupId.SEX])
  self:_setDDOption(widgets.dd_time, self.m_data[ETeachingIntroGroupId.TIME], self.m_config[ETeachingIntroGroupId.TIME])
  self:_setDDOption(widgets.dd_attr, self.m_data[ETeachingIntroGroupId.ATTR], self.m_config[ETeachingIntroGroupId.ATTR])
end

function TeachUsrSetTip:_setDDOption(ddwidget, data, config)
  local cap, names, val, imgs = "", {}, 0, {}
  for _, item in pairs(config) do
    table.insert(names, item.name)
    table.insert(imgs, item.icon)
    if data == item.order - 1 then
      cap = item.name
      val = item.order - 1
    end
  end
  UIHelper.SetDDCaptionText(ddwidget, cap)
  UIHelper.AddDDOptionsWithImg(ddwidget, names, imgs)
  UIHelper.AddDDValue(ddwidget, val)
end

function TeachUsrSetTip:_setSelfInfo(key, index)
  self.m_data[key] = index
end

function TeachUsrSetTip:_setSelfDesc(str)
  self.m_data.Sign = str
end

function TeachUsrSetTip:_OnClickOk()
  local param = self:_c2sformat()
  local ok, msg = Logic.teachingLogic:CheckSendIntro(param)
  if not ok then
    noticeManager:ShowTip(msg)
  end
end

function TeachUsrSetTip:_c2sformat()
  local data = self.m_data
  local res = {
    Sex = data[ETeachingIntroGroupId.SEX],
    Active = data[ETeachingIntroGroupId.TIME],
    Interest = data[ETeachingIntroGroupId.ATTR],
    Sign = data.Sign
  }
  return res
end

function TeachUsrSetTip:_OnMsgMask()
  noticeManager:ShowTip(UIHelper.GetString(220003))
end

function TeachUsrSetTip:_OnSetOk()
  noticeManager:ShowTip(UIHelper.GetString(2200070))
  self:_CloseSelf()
end

function TeachUsrSetTip:_CloseSelf()
  UIHelper.ClosePage("TeachingInfoPage")
end

function TeachUsrSetTip:_OnClickCancel()
  self:_CloseSelf()
end

function TeachUsrSetTip:_OnClickIF()
  local widgets = self:GetWidgets()
  widgets.if_des.placeholder.gameObject:SetActive(false)
  self.m_data.Sign = ""
end

function TeachUsrSetTip:DoOnHide()
end

function TeachUsrSetTip:DoOnClose()
end

return TeachUsrSetTip
