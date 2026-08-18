local RewardRandomDetailsPage = class("ui.page.Activity.RewardRandomDetailsPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function RewardRandomDetailsPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.toggle = 1
end

function RewardRandomDetailsPage:DoOnOpen()
  self.select = 1
  self:InitToggle()
  self:ShowPage()
end

function RewardRandomDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._OnClickClose, self)
end

function RewardRandomDetailsPage:InitToggle()
  local widgets = self.tab_Widgets
  local configAll = configManager.GetData("config_activity_extract")
  self.configShow = {}
  for i, v in pairs(configAll) do
    if v.name ~= "" then
      table.insert(self.configShow, v)
    end
  end
  UIHelper.CreateSubPart(widgets.item_tog, widgets.content_tog, #self.configShow, function(index, luaPart)
    local config = self.configShow[index]
    UIHelper.SetText(luaPart.Text, config.name)
    widgets.content_tog_group:RegisterToggle(luaPart.select_tog)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.content_tog_group, self, nil, self.OnPhaseToggle)
end

function RewardRandomDetailsPage:ShowPage()
  self.tab_Widgets.content_tog_group:SetActiveToggleIndex(self.select - 1)
  self:_LoadView()
end

function RewardRandomDetailsPage:_LoadView()
  local curPoolConf = self.configShow[self.select]
  local drop_rewardList = curPoolConf.drop_reward_id
  local reward_key = curPoolConf.reward_key
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.obj_content, self.tab_Widgets.item, #drop_rewardList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local rewardInfo = drop_rewardList[index]
      self:updateItemRewardPart(index, part, rewardInfo, 0, reward_key)
    end
  end)
end

function RewardRandomDetailsPage:updateItemRewardPart(index, tabPart, info, restNum, reward_key)
  local rewardId = info[1]
  local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
  local reward = rewards[1]
  local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
  UIHelper.SetImage(tabPart.im_quality, QualityIcon[rewardInfo.quality])
  UIHelper.SetImage(tabPart.im_icon, tostring(rewardInfo.icon))
  UIHelper.SetText(tabPart.tx_name, rewardInfo.name)
  UIHelper.SetText(tabPart.tx_rewardNum, reward[3])
  UIHelper.SetText(tabPart.tx_num, info[2] .. "/" .. info[2])
  local iskey = false
  for k, keyid in pairs(reward_key) do
    if rewardId == keyid then
      iskey = true
    end
  end
  tabPart.bg_key.gameObject:SetActive(iskey)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
    if reward[1] == GoodsType.EQUIP then
      UIHelper.OpenPage("ShowEquipPage", {
        templateId = reward[2],
        showEquipType = ShowEquipType.Simple
      })
    else
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
    end
  end, self)
end

function RewardRandomDetailsPage:OnPhaseToggle(index)
  self.select = index + 1
  self:_LoadView()
end

function RewardRandomDetailsPage:_OnClickClose()
  UIHelper.ClosePage("RewardRandomDetailsPage")
end

function RewardRandomDetailsPage:DoOnHide()
end

function RewardRandomDetailsPage:DoOnClose()
end

return RewardRandomDetailsPage
