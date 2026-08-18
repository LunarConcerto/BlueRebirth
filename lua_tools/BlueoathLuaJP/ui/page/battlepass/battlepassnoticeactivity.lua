local BattlePassNoticeActivity = class("UI.BattlePass.BattlePassNoticeActivity", LuaUIPage)

function BattlePassNoticeActivity:DoInit()
end

function BattlePassNoticeActivity:DoOnOpen()
  local param = self:GetParam()
  local content = param.Content or ""
  UIHelper.SetText(self.tab_Widgets.textContent, content)
  local contentR = param.ContentR or ""
  UIHelper.SetText(self.tab_Widgets.textContentR, contentR)
  local callback = param.Callback
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk, function()
    if callback ~= nil then
      callback()
    end
    UIHelper.ClosePage(self:GetName())
  end)
end

function BattlePassNoticeActivity:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCancel, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, function()
    UIHelper.ClosePage(self:GetName())
  end)
end

function BattlePassNoticeActivity:DoOnHide()
end

function BattlePassNoticeActivity:DoOnClose()
end

return BattlePassNoticeActivity
