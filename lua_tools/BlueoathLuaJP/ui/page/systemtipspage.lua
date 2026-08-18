SystemTipsPage = class("UI.SystemTipsPage", LuaUIPage)

function SystemTipsPage:DoInit()
  self.m_tabWidgets = nil
  self.openTimer = nil
end

function SystemTipsPage:DoOnOpen()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  if self.param ~= nil then
    self.txtParam = self.param[1]
    self.handler = self.param[2]
  end
  self.m_tabWidgets.txt_des.text = self.txtParam
  local conTime = tonumber(configManager.GetDataById("config_parameter", 19).value) / 10000
  self:_GetShowTimer(conTime)
end

function SystemTipsPage:_GetShowTimer(conTime)
  self.openTimer = self:CreateTimer(function()
    UIHelper.ClosePage("SystemTipsPage")
    self:StopTimer(self.openTimer)
    self.openTimer = nil
  end, conTime, 1, false)
  self:StartTimer(self.openTimer)
end

function SystemTipsPage:DoOnHide()
  if self.openTimer ~= nil then
    self:StopTimer(self.openTimer)
    self.openTimer = nil
  end
end

function SystemTipsPage:DoOnClose()
  if self.openTimer ~= nil then
    self:StopTimer(self.openTimer)
    self.openTimer = nil
  end
end

return SystemTipsPage
