local ActivityRankRewardPage = class("UI.Activity.ActivityRankRewardPage", LuaUIPage)

function ActivityRankRewardPage:DoInit()
end

function ActivityRankRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.OnBtnCloseClick, self)
end

function ActivityRankRewardPage:DoOnOpen()
  self:ShowRankRewardsList()
  self:ShowRankTips()
end

function ActivityRankRewardPage:ShowRankRewardsList()
  local count = Logic.guildLogic:GetBigActRankRewardCount()
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local selfData = bigActRankData:GetGuildSelfRankData()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_rewards, count, function(index, uiPart)
    local cfg = configManager.GetDataById("config_guildactivityrankreward", index)
    local isSelf = false
    local rankStr = ""
    if #cfg.ranklist == 1 or cfg.ranklist[1] == cfg.ranklist[2] then
      rankStr = string.format(UIHelper.GetString(3702010), cfg.ranklist[1])
      if selfData.rankNo == cfg.ranklist[1] then
        isSelf = true
      end
    else
      rankStr = cfg.ranklist[1] .. "-" .. string.format(UIHelper.GetString(3702010), cfg.ranklist[2])
      if selfData.rankNo ~= nil and selfData.rankNo >= cfg.ranklist[1] and selfData.rankNo <= cfg.ranklist[2] then
        isSelf = true
      end
    end
    uiPart.obj_self:SetActive(isSelf)
    UIHelper.SetText(uiPart.txt_rankNum, rankStr)
    local tipStr = string.format(UIHelper.GetString(3702009), cfg.score)
    UIHelper.SetText(uiPart.txt_tips, tipStr)
    local rewards = configManager.GetDataById("config_rewards", cfg.reward).rewards
    UIHelper.CreateSubPart(uiPart.obj_item, uiPart.trans_rewards, #rewards, function(index2, uiPart2)
      local rewardInfo = rewards[index2]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(uiPart2.img_icon, icon)
      UIHelper.SetImageByQuality(uiPart2.img_bg, quality)
      UIHelper.SetText(uiPart2.txt_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart2.btn_clickBtn, clickFunc)
    end)
  end)
end

function ActivityRankRewardPage:ShowRankTips()
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local selfData = bigActRankData:GetGuildSelfRankData()
  local selfRate = 1
  if selfData.currentRate then
    selfRate = selfData.currentRate / 100
  end
  local tipStr = string.format(UIHelper.GetString(3702001), selfRate)
  UIHelper.SetText(self.tab_Widgets.txt_tips, tipStr)
end

function ActivityRankRewardPage:OnBtnCloseClick()
  UIHelper.ClosePage(self:GetName())
end

function ActivityRankRewardPage:DoOnHide()
end

function ActivityRankRewardPage:DoOnClose()
end

return ActivityRankRewardPage
