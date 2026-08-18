local BuildingOpenPage = class("UI.Building.Building2D.BuildingOpenPage", LuaUIPage)
local ImgTitle = {
  [false] = "uipic_ui_building_fo_dengjitisheng",
  [true] = "uipic_ui_building_fo_jianzaowancheng"
}

function BuildingOpenPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.param = nil
end

function BuildingOpenPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Close, function()
    self:_ClickCloseFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ok, function()
    self:_ClickCloseFun()
  end)
end

function BuildingOpenPage:DoOnOpen()
  self.param = self:GetParam()
  self.m_tabWidgets.txt_name.text = self.param.open_show_name
  if self.param.Type ~= nil and self.param.Type == RewardType.TEXT then
    UIHelper.SetImage(self.m_tabWidgets.im_title, ImgTitle[self.param.isAdding])
  else
    UIHelper.SetImage(self.m_tabWidgets.im_title, "uipic_ui_functionopen_fo_gognnengkaiqi")
  end
end

function BuildingOpenPage:_ClickCloseFun()
  UIHelper.ClosePage("BuildingOpenPage")
end

return BuildingOpenPage
