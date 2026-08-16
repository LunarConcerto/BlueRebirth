local TowerEquipPage = class("UI.Dock.TowerEquipPage", LuaUIPage)
local index2option = {
  [0] = AutoAddOption.LEVEL,
  [1] = AutoAddOption.FIGHT,
  [2] = AutoAddOption.ATTACK
}

function TowerEquipPage:DoInit()
end

function TowerEquipPage:DoOnOpen()
  self:_Refresh()
end

function TowerEquipPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._OnClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._OnClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_hint, self._OnClickTip, self)
end

function TowerEquipPage:_Refresh()
  local widgets = self:GetWidgets()
  widgets.tog_hint.isOn = Logic.fleetLogic:GetHideAutoField()
  widgets.togglegroup:ClearToggles()
  widgets.togglegroup:RegisterToggle(widgets.tog_level)
  widgets.togglegroup:RegisterToggle(widgets.tog_fight)
  widgets.togglegroup:RegisterToggle(widgets.tog_attack)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.togglegroup, self, nil, self._OnSwitchTog)
  local option = Logic.fleetLogic:GetAutoOption()
  local index = -1
  for k, v in pairs(index2option) do
    if v == option then
      index = k
    end
  end
  if index < 0 then
    logError("can't find auto sort option ,set default option")
    index = 0
  end
  widgets.togglegroup:SetActiveToggleIndex(index)
end

function TowerEquipPage:_OnSwitchTog(index)
  Logic.fleetLogic:SetAutoOption(index2option[index])
end

function TowerEquipPage:_OnClickClose()
  self:CloseSelf()
end

function TowerEquipPage:_OnClickOk()
  local fleetType = self:GetParam().FleetType
  local heros = self:GetParam().FleetHero
  local ok, msg = Logic.fleetLogic:HerosAutoEquipWrap(fleetType, heros)
  if not ok then
    noticeManager:ShowTip(msg)
  else
    self:CloseSelf()
  end
end

function TowerEquipPage:_OnClickTip(go, isOn)
  Logic.fleetLogic:SetHideAutoField(isOn)
end

function TowerEquipPage:DoOnHide()
  self:_CloseTog()
end

function TowerEquipPage:DoOnClose()
  self:_CloseTog()
end

function TowerEquipPage:_CloseTog()
  local widgets = self:GetWidgets()
  widgets.togglegroup:ClearToggles()
end

return TowerEquipPage
