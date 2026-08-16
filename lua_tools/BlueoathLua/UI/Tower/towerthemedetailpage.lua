local TowerThemeDetailPage = class("UI.Tower.TowerThemeDetailPage", LuaUIPage)

function TowerThemeDetailPage:DoInit()
end

function TowerThemeDetailPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam() or {}
  UIHelper.SetText(widgets.title, params[1])
  UIHelper.SetImage(widgets.Image, params[2])
  UIHelper.SetText(widgets.tx_tips, params[3])
end

function TowerThemeDetailPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_OK, self.btn_close, self)
end

function TowerThemeDetailPage:btn_close()
  UIHelper.ClosePage("TowerThemeDetailPage")
end

return TowerThemeDetailPage
