local DismantleConfirmPage = class("UI.Bag.DismantleConfirmPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local DismantleType = {DismantleItem = 1, DismantleEquip = 2}

function DismantleConfirmPage:DoInit()
  self.selectTab = {}
  self.dismantleType = 0
end

function DismantleConfirmPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_closeTip, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
end

function DismantleConfirmPage:DoOnOpen()
  local params = self:GetParam()
  self.selectTab = params.selectTab
  self.dismantleType = params.dismantleType
  local rewards = {}
  if self.dismantleType == DismantleType.DismantleEquip then
    self.tab_Widgets.txt_title.text = UIHelper.GetString(910000417)
    self.tab_Widgets.txt_Tips.text = UIHelper.GetString(910000418)
    rewards = Logic.equipLogic:GetDismantleReward(self.selectTab)
  else
    self.tab_Widgets.txt_title.text = UIHelper.GetString(4700016)
    self.tab_Widgets.txt_Tips.text = UIHelper.GetString(4700017)
    rewards = Logic.bagLogic:GetItemDismantleReward(self.selectTab)
  end
  self:_Refresh(rewards)
end

function DismantleConfirmPage:_Refresh(rewards)
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
  if self.dismantleType == DismantleType.DismantleEquip then
    Logic.equipLogic:SetDisRewardCache(self.selectTab)
    Service.equipService:SendDismantleEquip(self.selectTab)
  else
    local dismantleTab = {}
    for k, v in pairs(self.selectTab) do
      table.insert(dismantleTab, {templateId = k, num = v})
    end
    Service.bagService:SendSaleItem(dismantleTab)
  end
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
