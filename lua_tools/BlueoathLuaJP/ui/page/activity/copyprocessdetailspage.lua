local CopyProcessDetailsPage = class("UI.Copy.CopyProcessDetailsPage", LuaUIPage)

function CopyProcessDetailsPage:DoInit()
  self.tab_Widgets = self:GetWidgets()
  self.select = 1
end

function CopyProcessDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._OnClickClose, self)
end

function CopyProcessDetailsPage:DoOnOpen()
  self:InitToggle()
  self.tab_Widgets.toggle_group:SetActiveToggleIndex(self.select - 1)
  self:_LoadView()
end

function CopyProcessDetailsPage:_LoadView()
  local widgets = self.tab_Widgets
  local effValue, effDescid, tabSort = Logic.activityExtractLogic:GetPassCopyEffectAll()
  local type = tabSort[self.select]
  local effectconf = configManager.GetDataById("config_value_effect", effDescid[type])
  local desc = string.format(effectconf.activity_effect_desc, effValue[type])
  UIHelper.SetText(widgets.DesText, desc)
  UIHelper.SetText(widgets.Name, effectconf.desc)
end

function CopyProcessDetailsPage:InitToggle()
  local widgets = self.tab_Widgets
  local effValue, effDescid, tabSort = Logic.activityExtractLogic:GetPassCopyEffectAll()
  UIHelper.CreateSubPart(widgets.toggle, widgets.content_toggle, #tabSort, function(index, luaPart)
    local type = tabSort[index]
    local effid = effDescid[type]
    local effectconf = configManager.GetDataById("config_value_effect", effid)
    UIHelper.SetImage(luaPart.icon, effectconf.buff_icon)
    widgets.toggle_group:RegisterToggle(luaPart.tog_tubiao)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.toggle_group, self, nil, self.OnPhaseToggle)
end

function CopyProcessDetailsPage:OnPhaseToggle(index)
  self.select = index + 1
  self:_LoadView()
end

function CopyProcessDetailsPage:_OnClickClose()
  UIHelper.ClosePage("CopyProcessDetailsPage")
end

function CopyProcessDetailsPage:DoOnHide()
end

function CopyProcessDetailsPage:DoOnClose()
end

return CopyProcessDetailsPage
