local InstructionPage = class("UI.DailyCopy.InstructionPage", LuaUIPage)

function InstructionPage:DoInit()
end

function InstructionPage:DoOnOpen()
end

function InstructionPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnClose, self._btnClose, self)
end

function InstructionPage:_btnClose()
  UIHelper.ClosePage("InstructionPage")
end

return InstructionPage
