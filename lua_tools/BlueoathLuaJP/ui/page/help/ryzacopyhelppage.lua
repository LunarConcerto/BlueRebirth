local RyzaCopyHelpPage = class("UI.Help.RyzaCopyHelpPage", LuaUIPage)

function RyzaCopyHelpPage:DoInit()
end

function RyzaCopyHelpPage:DoOnOpen()
end

function RyzaCopyHelpPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_bg, self._ClickClose, self)
end

function RyzaCopyHelpPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

return RyzaCopyHelpPage
