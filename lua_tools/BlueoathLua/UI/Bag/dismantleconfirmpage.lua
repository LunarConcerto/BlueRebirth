local DismantleConfirmPage = class("UI.Bag.DismantleConfirmPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")

function DismantleConfirmPage:DoInit()
end

function DismantleConfirmPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_closeTip, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
end

function DismantleConfirmPage:DoOnOpen()
  local selectEquip = self:GetParam()
  self:_Refresh(selectEquip)
end

function DismantleConfirmPage:_Refresh(selectEquip)
  local rewards = Logic.equipLogic:GetDismantleReward(selectEquip)
  rewards = self:_formatReward(rewards)
  self:_ShowRewards(rewards)
end

function DismantleConfirmPage:_ShowRewards(rewards)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_items, #rewards, function(index, tabParts)
    local reward = rewards[index]
    local item = CommonRewardItem:new()
    item:Init(index, reward, tabParts)
    UGUIEventListener.AddButtonOnClick(tabParts.img_frame, self._ShowItemDetail, self, reward)
  end)
end

function DismantleConfirmPage:_formatReward(args)
  local res = {}
  for _, info in pairs(args) do
    table.insert(res, {
      Type = info[1],
      ConfigId = info[2],
      Num = info[3]
    })
  end
  return res
end

function DismantleConfirmPage:_ShowItemDetail(go, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

function DismantleConfirmPage:_OnClickOk()
  local selectEquip = self:GetParam()
  Logic.equipLogic:SetDisRewardCache(selectEquip)
  Service.equipService:SendDismantleEquip(selectEquip)
  self:_CloseSelf()
end

function DismantleConfirmPage:_CloseSelf()
  UIHelper.ClosePage("DismantleConfirmPage")
end

function DismantleConfirmPage:DoOnClose()
end

function DismantleConfirmPage:DoOnHide()
end

return DismantleConfirmPage
