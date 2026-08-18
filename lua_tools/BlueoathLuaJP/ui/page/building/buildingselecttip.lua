local BuildingSelectTip = class("UI.Building.BuildingSelectTip", LuaUIPage)

function BuildingSelectTip:DoInit()
end

function BuildingSelectTip:DoOnOpen()
  self:_Refresh()
end

function BuildingSelectTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok1, self._OnClickBuild, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
end

function BuildingSelectTip:_Refresh()
  local widgets = self:GetWidgets()
  local tid = self:GetParam().tid
  local buildingCfg = configManager.GetDataById("config_buildinginfo", tid)
  local curStrength, maxStrength = Logic.buildingLogic:GetWorkerStreProgress()
  local levelupCfg = configManager.GetDataById("config_buildinglevelup", tid)
  local costStrength = levelupCfg.costwork
  UIHelper.SetText(widgets.tx_haveNum, string.format("%s/%s", curStrength, maxStrength))
  UIHelper.SetText(widgets.tx_costNum, costStrength)
end

function BuildingSelectTip:_OnClickBuild()
  local tid = self:GetParam().tid
  local index = self:GetParam().index
  local errMsg = Logic.buildingLogic:CheckUpgradeCost(tid, 1)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  Service.buildingService:AddBuilding(tid, index)
  self:_CloseSelf()
end

function BuildingSelectTip:_CloseSelf()
  UIHelper.ClosePage("BuildingSelectTip")
end

function BuildingSelectTip:DoOnHide()
end

function BuildingSelectTip:DoOnClose()
end

return BuildingSelectTip
