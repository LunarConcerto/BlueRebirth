local ATowerHelpPage = class("UI.TowerActivity.ATowerHelpPage", LuaUIPage)

function ATowerHelpPage:DoInit()
end

function ATowerHelpPage:DoOnOpen()
end

function ATowerHelpPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
end

function ATowerHelpPage:btn_close()
  UIHelper.ClosePage("ATowerHelpPage")
end

return ATowerHelpPage
