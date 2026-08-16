local BattlePassRewardPreviewPage = class("UI.BattlePass.BattlePassPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function BattlePassRewardPreviewPage:DoInit()
end

function BattlePassRewardPreviewPage:DoOnOpen()
  local cfgs = configManager.GetData("config_battlepass_level")
  local freerewardids = {}
  for _, cfg in pairs(cfgs) do
    if cfg.free_level_reward > 0 then
      table.insert(freerewardids, cfg.free_level_reward)
    end
  end
  local free_rewards = Logic.rewardLogic:FormatRewards(freerewardids)
  self.tab_Widgets.objFreeReward:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.objFreeReward, self.tab_Widgets.rectFreeReward, #free_rewards, function(subindex, subpart)
    local rewarditem = free_rewards[subindex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
    UIHelper.SetImage(subpart.img_icon, display.icon)
    UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
      Logic.itemLogic:ShowItemInfo(rewarditem.Type, rewarditem.ConfigId)
    end)
  end)
  local payrewardids = {}
  for _, cfg in pairs(cfgs) do
    if 0 < cfg.pay_level_reward then
      table.insert(payrewardids, cfg.pay_level_reward)
    end
  end
  local pay_rewards = Logic.rewardLogic:FormatRewards(payrewardids)
  self.tab_Widgets.objPayReward:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.objPayReward, self.tab_Widgets.rectPayReward, #pay_rewards, function(subindex, subpart)
    local rewarditem = pay_rewards[subindex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
    UIHelper.SetImage(subpart.img_icon, display.icon)
    UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  local passType = Data.battlepassData:GetPassType()
  if passType >= BATTLEPASS_TYPE.ADVANCED then
    self.tab_Widgets.objFinishAdvance:SetActive(true)
    self.tab_Widgets.btnAdvance.gameObject:SetActive(false)
  else
    self.tab_Widgets.objFinishAdvance:SetActive(false)
    self.tab_Widgets.btnAdvance.gameObject:SetActive(true)
  end
end

function BattlePassRewardPreviewPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAdvance, function()
    UIHelper.OpenPage("AdvanceBattlePassPage")
  end)
end

function BattlePassRewardPreviewPage:DoOnHide()
end

function BattlePassRewardPreviewPage:DoOnClose()
end

return BattlePassRewardPreviewPage
