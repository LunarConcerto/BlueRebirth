local GuideSettingsPage = class("UI.GuidePage.GuideSettingsPage", LuaUIPage)

function GuideSettingsPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_InitToggle()
  self.nOperateData = nil
end

function GuideSettingsPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UIHelper.AddToggleGroupChangeValueEvent(widgets.modeGroup, self, nil, self._SetOperateMode)
  UGUIEventListener.AddButtonOnClick(widgets.btn_certain, self._OnclickCertain, self)
end

function GuideSettingsPage:DoOnOpen()
  self:SetAdditionOrder(500)
  self.nOperateData = CacheUtil.GetBattleRotationOpe()
  self:RefreshOperate()
end

function GuideSettingsPage:RefreshOperate()
  local widgets = self:GetWidgets()
  widgets.modeGroup:SetActiveToggleIndex(self.nOperateData)
end

function GuideSettingsPage:_InitToggle()
  local widgets = self:GetWidgets()
  widgets.modeGroup:ClearToggles()
  widgets.modeGroup:RegisterToggle(widgets.tog_rudder)
  widgets.modeGroup:RegisterToggle(widgets.tog_direct)
end

function GuideSettingsPage:_SetOperateMode(mode)
  CacheUtil.SetBattleRotationOpe(OperateMode[mode])
end

function GuideSettingsPage:_OnclickCertain()
  UIHelper.ClosePage("GuideSettingsPage")
end

return GuideSettingsPage
