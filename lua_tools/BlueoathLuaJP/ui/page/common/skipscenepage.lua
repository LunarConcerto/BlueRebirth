local SkipScenePage = class("UI.Common.SkipScenePage", LuaUIPage)

function SkipScenePage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SkipScenePage:DoOnOpen()
end

function SkipScenePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_skip, self._ClickSkip, self)
end

function SkipScenePage:_ClickSkip(...)
  local event = self:GetParam()
  eventManager:SendEvent(event)
end

function SkipScenePage:DoOnHide()
end

function SkipScenePage:DoOnClose()
end

return SkipScenePage
