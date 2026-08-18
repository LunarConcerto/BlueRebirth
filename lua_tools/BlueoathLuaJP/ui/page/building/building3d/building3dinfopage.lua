local Building3DInfoPage = class("UI.Building.Building3D.Building3DInfoPage", LuaUIPage)

function Building3DInfoPage:DoInit()
end

function Building3DInfoPage:DoOnOpen()
  self:_Refresh()
end

function Building3DInfoPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok1, self._OnClickUpLevel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._OnClickDownLevel, self)
end

function Building3DInfoPage:_Refresh()
  self:_ShowBuildInfo()
  self:_ShowCurEffect()
end

function Building3DInfoPage:_ShowBuildInfo()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  local name = Logic.buildingLogic:GetBuildName(data.Tid)
  local decs = Logic.buildingLogic:GetBuildDesc(data.Tid)
  local icon = Logic.buildingLogic:GetBuildIcon(data.Tid)
  UIHelper.SetText(widgets.tx_name, name)
  UIHelper.SetText(widgets.tx_level, "LV." .. data.Level)
  UIHelper.SetText(widgets.tx_desc, decs)
  UIHelper.SetImage(widgets.im_icon, icon)
end

function Building3DInfoPage:_ShowCurEffect()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  local type = Logic.buildingLogic:GetBuildType(data.Tid)
  local effects = Logic.buildingLogic:GetBuildingEffects(type)
  UIHelper.CreateSubPart(widgets.obj_heroEffect, widgets.trans_heroEffect, #effects.HeroEffects, function(index, tabPart)
    local effectFunc = effects.HeroEffects[index]
    local key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, data)
    UIHelper.SetText(tabPart.tx_key, key)
    UIHelper.SetText(tabPart.tx_value, value)
  end)
  UIHelper.CreateSubPart(widgets.obj_buildEffect, widgets.trans_buildEffect, #effects.BuildingEffects, function(index, tabPart)
    local effectFunc = effects.BuildingEffects[index]
    local key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, data)
    UIHelper.SetText(tabPart.tx_key, key)
    UIHelper.SetText(tabPart.tx_value, value)
  end)
end

function Building3DInfoPage:_OnClickUpLevel()
  local data = self:GetParam()
  local targetLevel, errMsg = Logic.buildingLogic:CheckUpgradeLevel(data)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  UIHelper.OpenPage("BuildingGradeChangeTip", {
    opType = MBuildingTipType.LevelUp,
    buildingData = data,
    targetLevel = targetLevel
  })
  self:_CloseSelf()
end

function Building3DInfoPage:_OnClickDownLevel()
  local data = self:GetParam()
  local targetLevel, errMsg = Logic.buildingLogic:CheckDegradeLevel(data)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  UIHelper.OpenPage("BuildingGradeChangeTip", {
    opType = MBuildingTipType.LevelDown,
    buildingData = data,
    targetLevel = targetLevel
  })
  self:_CloseSelf()
end

function Building3DInfoPage:_CloseSelf()
  UIHelper.ClosePage("Building3DInfoPage")
end

function Building3DInfoPage:DoOnHide()
end

function Building3DInfoPage:DoOnClose()
end

return Building3DInfoPage
