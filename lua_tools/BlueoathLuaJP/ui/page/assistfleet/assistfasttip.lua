local AssistFastTip = class("UI.AssistFleet.AssistFastTip", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function AssistFastTip:DoInit()
end

function AssistFastTip:DoOnOpen()
  self.m_assist = self:GetParam()
  self:_Refresh()
end

function AssistFastTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._ClsoeSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_close, self._ClsoeSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._ClsoeSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._FastFinishCallBack, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_icon, self._ShowItemInfo, self)
end

function AssistFastTip:_ShowItemInfo()
  local assist = self.m_assist
  local fastConfig = Logic.assistNewLogic:GetCommandConfigById(assist.SupportId).complete_item
  if fastConfig == nil then
    logError("assist fast item config err")
    return
  end
  local check, _ = Logic.assistNewLogic:CheckFastFinish(assist.SupportId)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(fastConfig[1], fastConfig[2], not check))
end

function AssistFastTip:_Refresh()
  local widgets = self:GetWidgets()
  local assist = self.m_assist
  local check, num = Logic.assistNewLogic:CheckFastFinish(assist.SupportId)
  local str = ""
  local fastConfig = Logic.assistNewLogic:GetCommandConfigById(assist.SupportId).complete_item
  local temp = {}
  temp.Type = fastConfig[1]
  temp.ConfigId = fastConfig[2]
  temp.Num = fastConfig[3]
  local data = Logic.goodsLogic.AnalyGoods(temp)
  UIHelper.SetImage(widgets.im_quality, QualityIcon[data.quality])
  UIHelper.SetImage(widgets.im_icon, data.texIcon)
  UIHelper.SetText(widgets.tx_num, Mathf.ToInt(num))
  local str = string.format(UIHelper.GetString(971024), temp.Num)
  if not check then
    str = UIHelper.GetString(971003)
  end
  UIHelper.SetText(widgets.tx_tip, str)
  widgets.btn_ok_gary.Gray = not check
end

function AssistFastTip:_ClsoeSelf()
  UIHelper.ClosePage("AssistFastTip")
end

function AssistFastTip:_FastFinishCallBack()
  local check, _ = Logic.assistNewLogic:CheckFastFinish(self.m_assist.SupportId)
  if not check then
    local fastConfig = Logic.assistNewLogic:GetCommandConfigById(self.m_assist.SupportId).complete_item
    if fastConfig == nil then
      logError("assist fast item config err")
      return
    end
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(fastConfig[1], fastConfig[2], not check))
    return
  end
  local dotinfo = {
    info = "ui_supfleet_end",
    type = AssistCompleteType.FAST,
    copy_displayID = 0
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  Logic.assistNewLogic:SetLastFinish(self.m_assist)
  Service.assistNewService:SendAssistFinish(self.m_assist.Id, AssistCompleteType.FAST)
  self:_ClsoeSelf()
end

function AssistFastTip:DoOnHide()
end

function AssistFastTip:DoOnClose()
end

return AssistFastTip
