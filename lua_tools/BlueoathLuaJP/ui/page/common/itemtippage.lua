local ItemTipPage = class("UI.Common.ItemTipPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")

function ItemTipPage:DoInit()
end

function ItemTipPage:DoOnOpen()
  self:_Refresh()
end

function ItemTipPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_2ok, self._Ok, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_2cancel, self._Cancel, self)
end

function ItemTipPage:_Refresh()
  self:_ShowTip()
  self:_ShowItems()
  self:_ShowButton()
end

function ItemTipPage:_ShowTip()
  local widgets = self:GetWidgets()
  local tip = self:GetParam().Tip or ""
  UIHelper.SetText(widgets.tx_tip, tip)
end

function ItemTipPage:_ShowItems()
  local widgets = self:GetWidgets()
  local items = self:GetParam().Items or {}
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #items, function(index, tabPart)
    local temp = items[index]
    local item = CommonRewardItem:new()
    item:Init(index, temp, tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, self._ShowItemDetail, self, temp)
  end)
end

function ItemTipPage:_ShowItemDetail(go, item)
  Logic.itemLogic:ShowItemInfo(item.Type, item.ConfigId)
end

function ItemTipPage:_ShowButton()
end

function ItemTipPage:_Cancel()
  local func = self:GetParam().Func
  if func then
    func(1)
  end
  self:_CloseSelf()
end

function ItemTipPage:_Ok()
  local func = self:GetParam().Func
  if func then
    func(2)
  end
  self:_CloseSelf()
end

function ItemTipPage:_CloseSelf()
  UIHelper.ClosePage("ItemTipPage")
end

function ItemTipPage:DoOnHide()
end

function ItemTipPage:DoOnClose()
end

return ItemTipPage
