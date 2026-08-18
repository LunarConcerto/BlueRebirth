local SportRankRewardPage = class("UI.Sport.SportRankRewardPage", LuaUIPage)

function SportRankRewardPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SportRankRewardPage:DoOnOpen()
  self.param = self:GetParam()
  self.index = self.param.copyId
  self.configData = Data.sportMeetData:GetSportAtCfgDataByIndex(self.index)
  self:LoadConfigData(self.configData)
end

function SportRankRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, function()
    UIHelper.ClosePage("SportRankRewardPage")
  end, self)
  self:RegisterEvent(LuaEvent.UpdatePlotCopy, self.DoOnOpen, self)
end

function SportRankRewardPage:LoadConfigData(data)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trs_content, #data, function(index, part)
    local configData = data[index]
    UIHelper.SetText(part.txt_Rank, configData.range_desc)
    UIHelper.SetImage(part.img_BG, configData.rank_pic[1])
    local rewardId = configData.rank_reward
    local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
    UIHelper.CreateSubPart(part.obj_item, part.trs_RewardList, #rewards, function(index2, uiPart2)
      local rewardInfo = rewards[index2]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(uiPart2.img_Icon, icon)
      UIHelper.SetImageByQuality(uiPart2.img_BG, quality)
      UIHelper.SetText(uiPart2.tx_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, false)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart2.btn_clickBtn, clickFunc)
    end)
  end)
end

function SportRankRewardPage:LoadData()
  for i = 1, 10 do
    local data = Data.sportMeetData:GetSportCfgByIndexRange(self.index, i)
  end
end

return SportRankRewardPage
