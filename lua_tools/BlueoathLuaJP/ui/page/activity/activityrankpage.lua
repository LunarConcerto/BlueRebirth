local ActivityRankPage = class("UI.Activity.ActivityRankPage", LuaUIPage)

function ActivityRankPage:DoInit()
  self.bigActPeriod = {}
  self.selectPeriodIdx = 1
end

function ActivityRankPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.OnBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cont, self.OnBtnContClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self.OnBtnRewardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeReward, self.OnBtnCloseRewardClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_actIcon, self.OnBtnActIconClick, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActRankData, self.ShowRankList, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActSelfData, self.ShowSelfRank, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActRateData, self.UpdateMultipleData, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActItemsData, self.ShowItemData, self)
end

function ActivityRankPage:DoOnOpen()
  self:SendGetRankList()
  self:ShowRankList()
  self:ShowSelfRank()
  self:ShowMultipleData()
end

function ActivityRankPage:SendGetRankList()
  Service.guildService:SendBigActivityGuildRankList(1, 100)
  Service.guildService:SendBigActivityGuildRankList(101, 200)
  Service.guildService:SendBigActivityGuildRankList(201, 300)
end

function ActivityRankPage:ShowRankList()
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local rankList = bigActRankData:GetGuildAllRankData()
  if 0 < #rankList then
    self.tab_Widgets.obj_none:SetActive(false)
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.scr_score, self.tab_Widgets.obj_scoreItem, #rankList, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        local rankInfo = rankList[index]
        self:ShowPerRank(rankInfo, part)
      end
    end)
  else
    self.tab_Widgets.obj_none:SetActive(true)
  end
end

function ActivityRankPage:ShowSelfRank()
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local selfData = bigActRankData:GetGuildSelfRankData()
  local selfRank_Widgets = self.tab_Widgets.lp_self:GetLuaTableParts()
  local ourGuildId = Data.guildData:getGuildId()
  if next(selfData) == nil or selfData.guildId ~= ourGuildId then
    UIHelper.SetText(selfRank_Widgets.txt_rankNum, UIHelper.GetString(520004))
    local serName = Logic.loginLogic.SDKInfo and Logic.loginLogic.SDKInfo.name or selfData.serverId or UIHelper.GetString(920000277)
    local ourGuild = Data.guildData:getOurGuildInfo()
    local selfName = ourGuild:getName() or ""
    serName = serName .. "-" .. selfName
    UIHelper.SetText(selfRank_Widgets.txt_name, serName)
    UIHelper.SetText(selfRank_Widgets.txt_score, "0")
    local bigActRankData = Data.guildData:GetGuildBigActivityData()
    local nowRate = bigActRankData:GetGuildCurrentRate()
    UIHelper.SetText(selfRank_Widgets.txt_rate, nowRate / 100)
    selfRank_Widgets.btn_checkReward.gameObject:SetActive(false)
    UIHelper.CreateSubPart(selfRank_Widgets.obj_rewardsItem, selfRank_Widgets.trans_rewards, 0)
  else
    self:ShowPerRank(selfData, selfRank_Widgets)
  end
end

function ActivityRankPage:ShowPerRank(data, part)
  local noStr = string.format(UIHelper.GetString(3702010), data.rankNo)
  UIHelper.SetText(part.txt_rankNum, noStr)
  local serName = data.serverId
  if platformManager:getServiceList() and #platformManager:getServiceList() > 0 then
    serName = Logic.serverLogic:GetServerNameById(data.serverId)
  end
  serName = serName .. "-" .. data.name
  UIHelper.SetText(part.txt_name, serName)
  UIHelper.SetText(part.txt_score, data.points)
  UIHelper.SetText(part.txt_rate, data.currentRate / 100)
  local rewardId = Logic.guildLogic:GetBigActRankRewardByNum(data.rankNo)
  if rewardId then
    part.btn_checkReward.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btn_checkReward, self.CheckRewards, self, {
      data.rankNo,
      data.currentRate
    })
    local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
    UIHelper.CreateSubPart(part.obj_rewardsItem, part.trans_rewards, #rewards, function(index2, uiPart2)
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
  else
    part.btn_checkReward.gameObject:SetActive(false)
    UIHelper.CreateSubPart(part.obj_rewardsItem, part.trans_rewards, 0)
  end
end

function ActivityRankPage:UpdateMultipleData()
  self:SendGetRankList()
  self:ShowMultipleData()
end

function ActivityRankPage:ShowMultipleData()
  self:ShowItemData()
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local nowRate = bigActRankData:GetGuildCurrentRate()
  UIHelper.SetText(self.tab_Widgets.txt_rate, nowRate / 100)
  local nextRate = bigActRankData:GetGuildNextRate()
  local nowNum = bigActRankData:GetGuildNextItemNum()
  local nextNum = bigActRankData:GetGuildNextItemAllNum()
  if nextRate <= 0 then
    UIHelper.SetText(self.tab_Widgets.txt_nextRate, "")
    self.tab_Widgets.obj_arrow:SetActive(false)
    self.tab_Widgets.obj_maxRate:SetActive(true)
    local sliderStr = nextNum .. "/" .. nextNum
    UIHelper.SetText(self.tab_Widgets.txt_progress, sliderStr)
    self.tab_Widgets.sl_rateProgress.value = 1
  else
    UIHelper.SetText(self.tab_Widgets.txt_nextRate, nextRate / 100)
    self.tab_Widgets.obj_maxRate:SetActive(true)
    self.tab_Widgets.obj_maxRate:SetActive(false)
    local sliderStr = nowNum .. "/" .. nextNum
    UIHelper.SetText(self.tab_Widgets.txt_progress, sliderStr)
    self.tab_Widgets.sl_rateProgress.value = nowNum / nextNum
  end
end

function ActivityRankPage:ShowItemData()
  local itemId = Logic.guildLogic:GetBigActMultipleItem()
  local itemCfg = configManager.GetDataById("config_item_info", itemId)
  UIHelper.SetImage(self.tab_Widgets.img_actIcon, itemCfg.icon)
  local bigData = Data.guildData:GetGuildBigActivityData()
  local num = bigData:GetItemNum()
  UIHelper.SetText(self.tab_Widgets.txt_actNum, num)
end

function ActivityRankPage:OnBtnCloseClick()
  UIHelper.ClosePage(self:GetName())
end

function ActivityRankPage:OnBtnContClick()
  local bigData = Data.guildData:GetGuildBigActivityData()
  local num = bigData:GetItemNum()
  if num <= 0 then
    return
  end
  local bigActRankData = Data.guildData:GetGuildBigActivityData()
  local nextRate = bigActRankData:GetGuildNextRate()
  if nextRate <= 0 then
    noticeManager:ShowTipById(3702011)
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildService:SendGuildBigActivityPresentItem()
      end
    end
  }
  local tips = UIHelper.GetString(3702000)
  noticeManager:ShowMsgBox(tips, tabParams)
end

function ActivityRankPage:OnBtnRewardClick()
  UIHelper.OpenPage("ActivityRankRewardPage")
end

function ActivityRankPage:OnBtnCloseRewardClick()
  self.tab_Widgets.obj_rewardPart:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_showItem, self.tab_Widgets.trans_showRewards, 0)
end

function ActivityRankPage:OnBtnActIconClick()
  local itemId = Logic.guildLogic:GetBigActMultipleItem()
  Logic.itemLogic:ShowItemInfo(GoodsType.ITEM, itemId, true)
end

function ActivityRankPage:CheckRewards(go, param)
  self.tab_Widgets.obj_rewardPart:SetActive(true)
  local rewardId = Logic.guildLogic:GetBigActRankRewardByNum(param[1])
  local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
  UIHelper.CreateSubPart(self.tab_Widgets.obj_showItem, self.tab_Widgets.trans_showRewards, #rewards, function(index, uiPart)
    local rewardInfo = rewards[index]
    local itemType = rewardInfo[1]
    local itemId = rewardInfo[2]
    local num = "x" .. math.floor(rewardInfo[3] * param[2] / 100)
    local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
    local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
    UIHelper.SetImage(uiPart.img_icon, icon)
    UIHelper.SetImageByQuality(uiPart.img_bg, quality)
    UIHelper.SetText(uiPart.txt_num, num)
    
    local function clickFunc()
      Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
    end
    
    UGUIEventListener.AddButtonOnClick(uiPart.btn_clickBtn, clickFunc)
  end)
end

function ActivityRankPage:DoOnHide()
end

function ActivityRankPage:DoOnClose()
end

return ActivityRankPage
