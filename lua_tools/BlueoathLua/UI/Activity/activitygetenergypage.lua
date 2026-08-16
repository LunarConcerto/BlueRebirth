local ActivityGetEnergyPage = class("UI.Activity.ActivityGetEnergyPage", LuaUIPage)

function ActivityGetEnergyPage:DoInit()
end

function ActivityGetEnergyPage:DoOnOpen()
  self:_Refresh()
end

function ActivityGetEnergyPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._CloseSelf, self)
end

function ActivityGetEnergyPage:_Refresh()
  self:_ShowEquipInfo()
end

function ActivityGetEnergyPage:_ShowEquipInfo()
  local widgets = self:GetWidgets()
  local _, equips = Logic.settlementLogic:ShowAEquipPointTip()
  local tid, id, logic
  logic = Logic.equipLogic
  UIHelper.CreateSubPart(widgets.obj_equip, widgets.trans_equip, #equips, function(index, tabPart)
    id = equips[index]
    tid = logic:GetEquipTidByEquipId(id)
    local name = logic:GetAPointName(tid)
    local e_name = logic:GetName(tid)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[logic:GetQuality(tid)])
    UIHelper.SetImage(tabPart.im_equip, logic:GetIcon(tid))
    UIHelper.SetText(tabPart.tx_equip, name)
    UIHelper.SetText(tabPart.tx_eName, e_name)
    local max = logic:GetAEquipPointMax(tid)
    local cur = logic:GetAEquipPointCur(id)
    local add = max > cur and "+" .. Data.equipactivityData:GetPointAddById(id) or "MAX"
    cur = Mathf.Min(logic:GetAEquipPointCur(id), max)
    UIHelper.SetText(tabPart.tx_progress, cur .. " /" .. max)
    tabPart.sld_progress.value = cur / max
    UIHelper.SetText(tabPart.tx_up, add)
  end)
end

function ActivityGetEnergyPage:_CloseSelf()
  UIHelper.ClosePage("ActivityGetEnergyPage")
end

function ActivityGetEnergyPage:DoOnHide()
end

function ActivityGetEnergyPage:DoOnClose()
end

return ActivityGetEnergyPage
