local MeritRewardPage = class("UI.MeritRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function MeritRewardPage:DoInit()
  self.openID = nil
end

function MeritRewardPage:DoOnOpen()
  self.rewardType = self:GetParam()
  local activityData = configManager.GetData("config_activity")
  local activityType = {}
  for v, k in pairs(activityData) do
    if k.type == 5 then
      table.insert(activityType, k)
    end
  end
  local openActivityData = Data.activityData:GetActivityData()
  for v, k in pairs(openActivityData) do
    for index, key in pairs(activityType) do
      if key.id == v then
        self.openID = key.id
      end
    end
  end
  local configData = configManager.GetDataById("config_activity", self.openID)
  self:_LoadRwardInfo(configData)
end

function MeritRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGroup, function()
    self:_ClickBeforeBack()
  end)
end

function MeritRewardPage:_LoadRwardInfo(configData)
  local tabReward = {}
  if self.rewardType == MeritType.Grade then
    tabReward = configData.p5[1]
  elseif self.rewardType == MeritType.Rank then
    tabReward = configData.p5[2]
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_rewardItem, self.tab_Widgets.trans_rewardItem, #tabReward, function(index, tabPart)
    local rewardData = configManager.GetDataById("config_big_activity_reward", tabReward[index])
    local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardData.reward)
    if self.rewardType == MeritType.Rank then
      tabPart.obj_text:SetActive(false)
      UIHelper.SetText(tabPart.tx_des, "\231\172\172" .. rewardData.p1 .. "-" .. rewardData.p2 .. "\229\144\141")
    elseif self.rewardType == MeritType.Grade then
      tabPart.obj_text:SetActive(true)
      UIHelper.SetText(tabPart.tx_des, rewardData.p1 .. "%-" .. rewardData.p2 .. "%")
    end
    UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.trans_reward, #rewardInfo, function(nIndex, luaPart)
      local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo[nIndex])
      UIHelper.SetImage(luaPart.im_record, tabReward.texIcon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_num, rewardInfo[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_reward, self._ShowRewardInfo, self, rewardInfo[nIndex])
    end)
  end)
end

function MeritRewardPage:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function MeritRewardPage:_ClickBeforeBack()
  UIHelper.ClosePage("MeritRewardPage")
end

function MeritRewardPage:DoOnHide()
end

function MeritRewardPage:DoOnClose()
end

return MeritRewardPage
