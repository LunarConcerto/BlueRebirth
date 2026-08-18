local TowerHelpPage = class("UI.Tower.TowerHelpPage", LuaUIPage)

function TowerHelpPage:DoInit()
end

function TowerHelpPage:DoOnOpen()
end

function TowerHelpPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
end

function TowerHelpPage:btn_close()
  UIHelper.ClosePage("TowerHelpPage")
end

return TowerHelpPage
