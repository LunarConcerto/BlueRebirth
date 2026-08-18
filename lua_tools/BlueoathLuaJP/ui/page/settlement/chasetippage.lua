local ChaseTipPage = class("UI.Settlement.ChaseTipPage", LuaUIPage)

function ChaseTipPage:DoInit()
  self.m_canClose = false
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function ChaseTipPage:DoOnOpen()
  local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
  self:_SetChaseInfo(copyInfo.CopyId)
  self.m_closeCo = self:CreateTimer(function()
    self.m_canClose = true
  end, 1, 1, false)
  self:StartTimer(self.m_closeCo)
end

function ChaseTipPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_bg, self._CloseSettle, self, nil)
end

function ChaseTipPage:_CloseSettle()
  if self.m_canClose then
    local ok, value = Logic.settlementLogic:GetActivityParam()
    if ok then
      value.callback = self.param.callback
      UIHelper.OpenPage("AcRewardPage", value)
    else
      UIHelper.ClosePage(self:GetName())
      self.param.callback()
      self.param.callback = nil
    end
  end
end

function ChaseTipPage:_SetChaseInfo(copyId)
  local widgets = self:GetWidgets()
  local info = Logic.copyLogic:GetCopyDesConfig(copyId)
  UIHelper.SetText(widgets.tx_name, info.name)
  UIHelper.SetImage(widgets.im_icon, info.thumbnail)
end

function ChaseTipPage:DoOnHide()
end

function ChaseTipPage:DoOnClose()
end

return ChaseTipPage
