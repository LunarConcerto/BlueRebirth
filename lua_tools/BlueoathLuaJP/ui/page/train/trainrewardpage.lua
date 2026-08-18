local TrainRewardPage = class("UI.Train.TrainRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TrainRewardPage:DoInit()
end

function TrainRewardPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.StarReward, self._OnReceiveCallback, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._OnBtnClose, self)
end

function TrainRewardPage:DoOnOpen()
  UIHelper.OpenPage("RewardTipPage")
  self:_UpdateList()
end

function TrainRewardPage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function TrainRewardPage:_UpdateList()
  local params = self:GetParam()
  local datas = Logic.copyLogic:GetStarRewardDatas(params.chapterId)
  local count = #datas
  UIHelper.CreateSubPart(self.tab_Widgets.objListItem, self.tab_Widgets.transList, count, function(nIndex, tabPart)
    local data = datas[nIndex]
    tabPart.btn_receive.gameObject:SetActive(data.state == RewardState.Receivable)
    tabPart.btn_unreceivable.gameObject:SetActive(data.state == RewardState.UnReceivable)
    tabPart.txt_received.gameObject:SetActive(data.state == RewardState.Received)
    UIHelper.SetText(tabPart.txt_count, data.starNeed)
    UIHelper.SetText(tabPart.txt_progress, string.format("%d/%d", data.starNum, data.starNeed))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_receive, function()
      self:_OnBtnReceive(params.chapterId, data.index)
    end, self)
    local rc = #data.rewards
    if 3 < rc then
      rc = 3
    end
    UIHelper.CreateSubPart(tabPart.reward_item, tabPart.reward_trans, rc, function(rIndex, rewardPart)
      local reward = data.rewards[rIndex]
      local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
      UIHelper.SetImage(rewardPart.icon, display.icon)
      UIHelper.SetImage(rewardPart.bg, QualityIcon[display.quality])
      UIHelper.SetText(rewardPart.desc, "x" .. tostring(reward.Num))
      UGUIEventListener.AddButtonOnClick(rewardPart.btn, function()
        self:_ShowItemInfo(display)
      end)
    end)
  end)
end

function TrainRewardPage:_ShowItemInfo(displayData)
  UIHelper.OpenPage("ItemInfoPage", displayData)
end

function TrainRewardPage:_OnBtnReceive(chapterId, level)
  Service.copyService:SendStarReward(chapterId, level)
end

function TrainRewardPage:_OnReceiveCallback(state)
  local chapterId = state.ChapterId
  local index = state.Index
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local chapterTrain = configManager.GetDataById("config_chapter_training", chapter.relation_chapter_id)
  local rewardId = chapterTrain.star_reward[index]
  if rewardId then
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    self:_ShowTips({rewards = rewards, config = nil})
  end
  self:_UpdateList()
end

function TrainRewardPage:_OnBtnClose()
  UIHelper.ClosePage(self:GetName())
end

function TrainRewardPage:DoOnHide()
end

return TrainRewardPage
