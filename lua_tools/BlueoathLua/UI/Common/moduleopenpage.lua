local ModuleOpenPage = class("UI.Common.ModuleOpenPage", LuaUIPage)

function ModuleOpenPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.param = nil
end

function ModuleOpenPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Close, function()
    self:_ClickCloseFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ok, function()
    self:_ClickCloseFun()
  end)
end

function ModuleOpenPage:DoOnOpen()
  self.param = self:GetParam()
  self.m_tabWidgets.txt_name.text = self.param.open_show_name
end

function ModuleOpenPage:_ClickCloseFun()
  UIHelper.ClosePage("ModuleOpenPage")
  if self.param.is_open_page ~= "" then
    UIHelper.OpenPage(self.param.is_open_page)
  else
    moduleManager:SetOpenPageUpdateModule(self.param)
  end
end

function ModuleOpenPage:GetCurPageConf(pageName)
  local conf = configManager.GetData("config_ui_config")
  for k, v in pairs(conf) do
    if k == pageName then
      return v
    end
  end
  return nil
end

return ModuleOpenPage
