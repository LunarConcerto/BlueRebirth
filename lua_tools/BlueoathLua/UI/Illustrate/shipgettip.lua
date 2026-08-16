local ShipGetTip = class("UI.Illustrate.ShipGetTip", LuaUIPage)

function ShipGetTip:DoInit()
  self.m_tabWidgets = nil
  self.m_is3D = false
  self.m_rightTag = -1
  self.m_illustrateId = 0
end

function ShipGetTip:DoOnOpen()
  local illustrateId = self:GetParam()
  self:_ShowGetAppraoch(illustrateId)
end

function ShipGetTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._CloseTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._CloseTip, self)
end

function ShipGetTip:_ShowGetAppraoch(illustrateId)
  local widgets = self:GetWidgets()
  local approachList = Logic.illustrateLogic:GetApproachConfig(illustrateId)
  UIHelper.CreateSubPart(widgets.obj_tips, widgets.trans_tips, GetTableLength(approachList), function(index, tabPart)
    local str = Logic.illustrateLogic:GetApproachStr(approachList[index])
    UIHelper.SetText(tabPart.tx_tips, str)
  end)
end

function ShipGetTip:_CloseTip()
  UIHelper.ClosePage("ShipGetTip")
end

function ShipGetTip:DoOnHide()
end

function ShipGetTip:DoOnClose()
end

return ShipGetTip
