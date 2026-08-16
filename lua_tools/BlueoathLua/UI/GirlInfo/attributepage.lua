local AttributePage = class("UI.GirlInfo.AttributePage", LuaUIPage)

function AttributePage:DoInit()
end

function AttributePage:DoOnOpen()
  local param = self:GetParam()
  self.m_propNum = param[1]
  self.tabShipInfo = param[2]
  self:_LoadRwardInfo()
  self:_LoadMoodInfo()
end

function AttributePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGroup, function()
    self:_ClickBeforeBack()
  end)
end

function AttributePage:_LoadRwardInfo()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_PropItem, self.tab_Widgets.trans_Prop, #self.m_propNum, function(nIndex, tabPart)
    local aType = self.m_propNum[nIndex].type
    local tabConfig = configManager.GetDataById("config_attribute", aType)
    UIHelper.SetText(tabPart.tx_name, tabConfig.attr_name .. ":")
    UIHelper.SetImage(tabPart.im_icon, tabConfig.attr_icon)
    UIHelper.SetText(tabPart.tx_des, tabConfig.attr_direction)
  end)
end

function AttributePage:_LoadMoodInfo()
  UIHelper.SetText(self.tab_Widgets.tx_titlleSecond, UIHelper.GetString(1500016))
  UIHelper.SetText(self.tab_Widgets.tx_moodContent, UIHelper.GetString(1500017))
end

function AttributePage:_ClickBeforeBack()
  UIHelper.ClosePage("AttributePage")
end

function AttributePage:DoOnHide()
end

function AttributePage:DoOnClose()
end

return AttributePage
