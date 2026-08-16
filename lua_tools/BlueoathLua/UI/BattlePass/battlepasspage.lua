local BattlePassPage = class("UI.BattlePass.BattlePassPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TgIndexType = {
  PassLevel_1 = 1,
  PassTask_2 = 2,
  PassRank_3 = 3
}
local ImgRankRes = {
  "uipic_ui_teaching_bg_paihangban_nom1",
  "uipic_ui_teaching_bg_paihangban_nom2",
  "uipic_ui_teaching_bg_paihangban_nom3",
  "uipic_ui_teaching_bg_paihangban_qitamingci"
}
local IndexOffset = 5
local RealIndexOffset = 4.5
local periodId

function BattlePassPage:DoInit()
  self.mPartFriendRankList = self.tab_Widgets.partFriendRankList:GetLuaTableParts()
  self.mFriendList = {}
  self.mRefreshEffectShowMap = {}
end

function BattlePassPage:DoOnOpen()
  local customparam = {}
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.DIAMOND
  })
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.LUCKY
  })
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.BATTLEPASSGOLD
  })
  self:OpenTopPageNoTitle("BattlePassPage", 1, true, nil, customparam)
  self.mTgIndex = Logic.battlepassLogic.BattlePassPage_TgIndex or TgIndexType.PassLevel_1
  self.mTgTaskIndex = Logic.battlepassLogic.BattlePassPage_TgTaskIndex or TgTaskIndexType.WeekTask_1
  self.tab_Widgets.tgGroupTab:SetActiveToggleIndex(self.mTgIndex - 1)
  self.tab_Widgets.tgGroupTask:SetActiveToggleIndex(self.mTgTaskIndex - 1)
  self:RegisterRedDot(self.tab_Widgets.reddotWeekTask, TgTaskIndexType.WeekTask_1)
  self:RegisterRedDot(self.tab_Widgets.reddotAchiTask, TgTaskIndexType.AchiTask_2)
  self:GetBattleConfig()
end

function BattlePassPage:RegisterAllEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupTab, self, "", self._SwitchTogs)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupTask, self, "", self._SwitchTogsTask)
  self:RegisterEvent(LuaEvent.BattlePass_Update, function()
    self:ShowPage()
  end)
  self:RegisterEvent(LuaEvent.Friend_GetFriendList, function(target, data)
    self.mFriendList = clone(data.List) or {}
    self:sortFriendList()
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGetExp, function()
    self.tab_Widgets.tgGroupTab:SetActiveToggleIndex(1)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGetAll, function()
    local isCan = Logic.battlepassLogic:CanRewardGet()
    if isCan then
      Service.battlepassService:SendGetAllReward()
    else
      noticeManager:ShowTipById(3310011)
    end
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBuyLevel, function()
    local curPassLevel = Data.battlepassData:GetPassLevel()
    local max = Logic.battlepassLogic:GetBattlePassMaxLevel()
    if curPassLevel >= max then
      noticeManager:ShowTipById(3310006)
      return
    end
    UIHelper.OpenPage("BattlePassBuyLevelPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnImgLock, function()
    UIHelper.OpenPage("AdvanceBattlePassPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAdvance, function()
    UIHelper.OpenPage("AdvanceBattlePassPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelp, function()
    UIHelper.OpenPage("HelpPage", {content = 3310001})
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnShop, function()
    local paramCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
    local shopId = paramCfg.shop_id
    moduleManager:JumpToFunc(FunctionID.Shop, shopId)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGotoDaily, function()
    moduleManager:JumpToFunc(FunctionID.Task, TaskType.Daily)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnRewardpreview, function()
    UIHelper.OpenPage("BattlePassRewardPreviewPage")
  end)
  self:RegisterEvent(LuaEvent.BattlePass_RecieveBuyLevel, function()
    local curPassLevel = Data.battlepassData:GetPassLevel()
    UIHelper.SetText(self.tab_Widgets.textEffectLvlNum, curPassLevel)
    self.tab_Widgets.objEffectLevelUp:SetActive(true)
  end)
  self:RegisterEvent(LuaEvent.BattlePass_EffectBuyType, function(page, param)
    local buyType = param
    self.tab_Widgets.objEffectAdvance:SetActive(true)
    local showReward = function(callback)
      local paramCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
      local rewards = {}
      if buyType == BATTLEPASS_BUYTYPE.Advance2 then
        if paramCfg.advance_reward_2 > 0 then
          rewards = Logic.rewardLogic:FormatRewardById(paramCfg.advance_reward_2)
        end
      elseif 0 < paramCfg.advance_reward_1 then
        rewards = Logic.rewardLogic:FormatRewardById(paramCfg.advance_reward_1)
      end
      if 0 < #rewards then
        UIHelper.OpenPage("GetRewardsPage", {
          Rewards = rewards,
          DontMerge = true,
          callBack = callback
        })
      elseif callback ~= nil then
        callback()
      end
    end
    if buyType == BATTLEPASS_BUYTYPE.Advance2 then
      UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnEffectAdvanceClose, function()
        self.tab_Widgets.objEffectAdvance:SetActive(false)
        showReward(function()
          eventManager:SendEvent(LuaEvent.BattlePass_RecieveBuyLevel)
        end)
      end)
    else
      UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnEffectAdvanceClose, function()
        self.tab_Widgets.objEffectAdvance:SetActive(false)
        showReward()
      end)
    end
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnEffectLevelUpClose, function()
    self.tab_Widgets.objEffectLevelUp:SetActive(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnEffectLevelUpGetReward, function()
    local isCan = Logic.battlepassLogic:CanRewardGet()
    if isCan then
      Service.battlepassService:SendGetAllReward()
    end
    self.tab_Widgets.objEffectLevelUp:SetActive(false)
  end)
  self:RegisterEvent(LuaEvent.BattlePass_RecieveGetAllReward, function()
    self:SetRewardPartialListIndex(true)
  end)
  self:RegisterEvent(LuaEvent.BattlePass_RecieveRefreshRandTask, function(handler, param)
    local index = param.TaskIndex
    self.mRefreshEffectShowMap[index] = true
    self:ShowPage()
  end)
end

function BattlePassPage:DoOnHide()
end

function BattlePassPage:DoOnClose()
end

function BattlePassPage:SendGetFriendList()
  local lasttime = self.mLastSendTime or 0
  if lasttime ~= 0 then
    local nowtime = time.getSvrTime()
    if nowtime - lasttime < 1 then
      logDebug("dt < 1s , ignore to send rpc")
      return
    end
  end
  self.mLastSendTime = time.getSvrTime()
  Service.friendService:SendGetFriendList()
end

function BattlePassPage:_SwitchTogs(index)
  self.mTgIndex = index + 1
  Logic.battlepassLogic.BattlePassPage_TgIndex = self.mTgIndex
  if self.mTgIndex == TgIndexType.PassRank_3 then
    self:SendGetFriendList()
  end
  self:ShowPage()
end

function BattlePassPage:_SwitchTogsTask(index)
  self.mTgTaskIndex = index + 1
  Logic.battlepassLogic.BattlePassPage_TgTaskIndex = self.mTgTaskIndex
  self:ShowPage()
end

function BattlePassPage:ShowPage()
  local tgIndex = self.mTgIndex or TgIndexType.PassLevel_1
  if tgIndex == TgIndexType.PassLevel_1 then
    self:ShowRewardPartial()
  elseif tgIndex == TgIndexType.PassTask_2 then
    self:ShowTaskPartial()
  elseif tgIndex == TgIndexType.PassRank_3 then
    self:ShowRankPartial()
  else
    logError("undefined tg index", tgIndex)
  end
end

function BattlePassPage:ShowRewardPartial()
  self.tab_Widgets.objRewardAndTask:SetActive(true)
  self.tab_Widgets.objRewardPartial:SetActive(true)
  self.tab_Widgets.objTaskPartial:SetActive(false)
  self.tab_Widgets.objFriendRankList:SetActive(false)
  self.tab_Widgets.objTopRewardButtonGroup:SetActive(true)
  self.tab_Widgets.objTopTaskButtonGroup:SetActive(false)
  self:ShowRewardAndTaskTop()
  self.tab_Widgets.itemRewardLvl:SetActive(false)
  self.mLevelRewardList = Logic.battlepassLogic:GetLevelRewardList() or {}
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentRewardLvl, self.tab_Widgets.itemRewardLvl, #self.mLevelRewardList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateLevelRewardPart(index, part)
    end
  end)
  self:SetRewardPartialListIndex()
  self:ShowTargetLevelReward()
  local passType = Data.battlepassData:GetPassType()
  if passType >= BATTLEPASS_TYPE.ADVANCED then
    self.tab_Widgets.objImgLock:SetActive(false)
    self.tab_Widgets.btnAdvance.gameObject:SetActive(false)
    self.tab_Widgets.btnAdvanceAlready.gameObject:SetActive(true)
  else
    self.tab_Widgets.objImgLock:SetActive(true)
    self.tab_Widgets.btnAdvance.gameObject:SetActive(true)
    self.tab_Widgets.btnAdvanceAlready.gameObject:SetActive(false)
  end
  local title = ""
  local deadlinetime = ""
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.BattlePass)
  if activityId ~= nil and 0 < activityId then
    local activityCfg = configManager.GetDataById("config_activity", activityId)
    title = activityCfg.name
    local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
    local startTimeFormat = time.formatTimeToMDHM(startTime)
    local endTimeFormat = time.formatTimeToMDHM(endTime)
    deadlinetime = "" .. startTimeFormat .. "-" .. endTimeFormat
  else
    logError("err activityId ", activityId)
  end
  UIHelper.SetText(self.tab_Widgets.textTitle, title)
  UIHelper.SetText(self.tab_Widgets.textTime, deadlinetime)
end

function BattlePassPage:GetBattleConfig()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.BattlePass)
  if activityId ~= nil and 0 < activityId then
    local activityCfg = configManager.GetDataById("config_activity", activityId)
    self.periodId = activityCfg.period
    if self.periodId ~= 0 and self.periodId ~= nil then
      self.startTime, self.endTime = PeriodManager:GetStartAndEndPeriodTime(self.periodId)
    else
      logError("error eriodId")
    end
  else
    logError("err activityId ", activityId)
  end
end

function BattlePassPage:SetRewardPartialListIndex(isForce)
  local isSetForce = isForce or false
  if not isSetForce and self.mFlagSetListIndex ~= nil and self.mFlagSetListIndex == true then
    return
  end
  if self.mLevelRewardList == nil then
    self.mLevelRewardList = Logic.battlepassLogic:GetLevelRewardList() or {}
  end
  local setindex = -1
  for index, cfg in ipairs(self.mLevelRewardList) do
    local isCan = Logic.battlepassLogic:CanLevelRewardGet(cfg.level)
    if isCan then
      setindex = index - 1
      break
    end
  end
  if setindex == -1 then
    local curPassLevel = Data.battlepassData:GetPassLevel()
    setindex = curPassLevel - 1
  end
  self.tab_Widgets.contentRewardLvl.scrollRect.horizontalNormalizedPosition = setindex / (#self.mLevelRewardList - RealIndexOffset)
  self.mFlagSetListIndex = true
end

function BattlePassPage:ShowTargetLevelReward()
  local targetRewardLevelCfg = Logic.battlepassLogic:GetTargetRewardLevelCfg(self.mBaseLevel)
  if targetRewardLevelCfg ~= nil then
    self.tab_Widgets.objTargetLevelShow:SetActive(true)
    UIHelper.SetLocText(self.tab_Widgets.textTargetLvl, 3310008, targetRewardLevelCfg.level)
    local free_rewardids = {}
    if targetRewardLevelCfg.free_level_reward > 0 then
      table.insert(free_rewardids, targetRewardLevelCfg.free_level_reward)
    end
    local free_rewards = Logic.rewardLogic:FormatRewards(free_rewardids)
    self.tab_Widgets.objTargetRewardFree:SetActive(false)
    UIHelper.CreateSubPart(self.tab_Widgets.objTargetRewardFree, self.tab_Widgets.rectTargetRewardFree, #free_rewards, function(subindex, subpart)
      local rewarditem = free_rewards[subindex]
      local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
      UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
      UIHelper.SetImage(subpart.img_icon, display.icon)
      UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
      UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
        Logic.itemLogic:ShowItemInfo(rewarditem.Type, rewarditem.ConfigId)
      end)
    end)
    local pay_rewardids = {}
    if 0 < targetRewardLevelCfg.pay_level_reward then
      table.insert(pay_rewardids, targetRewardLevelCfg.pay_level_reward)
    end
    local pay_rewards = Logic.rewardLogic:FormatRewards(pay_rewardids)
    self.tab_Widgets.objTargetRewardPay:SetActive(false)
    UIHelper.CreateSubPart(self.tab_Widgets.objTargetRewardPay, self.tab_Widgets.rectTargetRewardPay, #pay_rewards, function(subindex, subpart)
      local rewarditem = pay_rewards[subindex]
      local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
      UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
      UIHelper.SetImage(subpart.img_icon, display.icon)
      UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
      UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
        Logic.itemLogic:ShowItemInfo(rewarditem.Type, rewarditem.ConfigId)
      end)
    end)
  else
    self.tab_Widgets.objTargetLevelShow:SetActive(false)
  end
end

function BattlePassPage:ShowTaskPartial()
  self.tab_Widgets.objRewardAndTask:SetActive(true)
  self.tab_Widgets.objRewardPartial:SetActive(false)
  self.tab_Widgets.objTaskPartial:SetActive(true)
  self.tab_Widgets.objFriendRankList:SetActive(false)
  self.tab_Widgets.objTopRewardButtonGroup:SetActive(false)
  self.tab_Widgets.objTopTaskButtonGroup:SetActive(true)
  self:ShowRewardAndTaskTop()
  self.tab_Widgets.itemTask:SetActive(false)
  local tgTaskIndex = self.mTgTaskIndex or TgTaskIndexType.WeekTask_1
  if tgTaskIndex == TgTaskIndexType.WeekTask_1 then
    self.mPerweekPassTaskList = Logic.battlepassLogic:GetPerWeekPassTaskList() or {}
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTask, self.tab_Widgets.itemTask, #self.mPerweekPassTaskList, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        self:updatePerweekPassTaskPart(index, part)
      end
    end)
  elseif tgTaskIndex == TgTaskIndexType.AchiTask_2 then
    self.mAchievePassTaskList = Logic.battlepassLogic:GetAchievePassTaskList() or {}
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTask, self.tab_Widgets.itemTask, #self.mAchievePassTaskList, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        self:updateAchievePassTaskPart(index, part)
      end
    end)
  else
    logError("undefined tg index", tgTaskIndex)
  end
end

function BattlePassPage:ShowRankPartial()
  self.tab_Widgets.objRewardAndTask:SetActive(false)
  self.tab_Widgets.objFriendRankList:SetActive(true)
  local myUid = Data.userData:GetUserUid()
  local myRank = 0
  for rank, frienddata in ipairs(self.mFriendList) do
    if frienddata.UserInfo.Uid == myUid then
      myRank = rank
      frienddata.UserInfo.LogoffTime = frienddata.UserInfo.LoginTime
      break
    end
  end
  self:sortFriendList()
  UIHelper.SetText(self.mPartFriendRankList.textRank, myRank)
  UIHelper.SetText(self.mPartFriendRankList.textName, Data.userData:GetUserName())
  UIHelper.SetLocText(self.mPartFriendRankList.textLevel, 3300041, Data.userData:GetUserLevel())
  local _, curHeadFrameInfo = Logic.playerHeadFrameLogic:GetHeadFrameByUid(Data.userData:GetUserData())
  local config = Logic.shipLogic:GetShipShowByHeroId(Data.userData:GetSecretaryId())
  if config then
    UIHelper.SetImage(self.mPartFriendRankList.imgHeadQuality, UserHeadQualityImg[config.quality])
    UIHelper.SetImage(self.mPartFriendRankList.imgHead, config.ship_icon5)
  end
  if curHeadFrameInfo then
    UIHelper.SetImage(self.mPartFriendRankList.imgHeadFrame, curHeadFrameInfo.icon)
  end
  self.mPartFriendRankList.itemPlayer:SetActive(false)
  UIHelper.SetInfiniteItemParam(self.mPartFriendRankList.contentPalyer, self.mPartFriendRankList.itemPlayer, #self.mFriendList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updatePlayerRankPart(index, part)
    end
  end)
  local passLevel = Data.battlepassData:GetPassLevel()
  UIHelper.SetLocText(self.mPartFriendRankList.textPassLevel, 3300038, passLevel)
  local passType = Data.battlepassData:GetPassType()
  local bpparamCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
  if passType == BATTLEPASS_TYPE.ADVANCED then
    UIHelper.SetImage(self.mPartFriendRankList.imgPassType, bpparamCfg.pay_icon)
  else
    UIHelper.SetImage(self.mPartFriendRankList.imgPassType, bpparamCfg.free_icon)
  end
end

function BattlePassPage:updatePlayerRankPart(index, part)
  local frienddata = self.mFriendList[index]
  if 0 < index and index <= 3 then
    UIHelper.SetImage(part.imgBg, ImgRankRes[index])
  else
    UIHelper.SetImage(part.imgBg, ImgRankRes[4])
  end
  local icon, quality = Logic.meritLogic:GetUserHead(frienddata.UserInfo)
  UIHelper.SetImage(part.imgQuality, quality)
  UIHelper.SetImage(part.imgHead, icon)
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetHeadFrameByUid(frienddata.UserInfo)
  UIHelper.SetImage(part.imgHeadFrame, headFrameInfo.icon)
  UIHelper.SetText(part.textRank, index)
  UIHelper.SetText(part.textName, frienddata.UserInfo.Uname)
  UIHelper.SetLocText(part.textLevel, 3300041, frienddata.UserInfo.Level)
  local LogoffTime = frienddata.UserInfo.LogoffTime
  local userBattlePassLevel = "0"
  if LogoffTime ~= nil then
    if LogoffTime > self.startTime or LogoffTime == 0 then
      userBattlePassLevel = frienddata.UserInfo.BattlePassLevel
    else
      userBattlePassLevel = "1"
    end
  else
    userBattlePassLevel = "1"
  end
  UIHelper.SetLocText(part.textPassLevel, 3300038, userBattlePassLevel)
  local bpparamCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
  if frienddata.UserInfo.BattlePassType == BATTLEPASS_TYPE.ADVANCED and frienddata.UserInfo.LogoffTime > self.startTime then
    UIHelper.SetImage(part.imgPassType, bpparamCfg.pay_icon)
  else
    UIHelper.SetImage(part.imgPassType, bpparamCfg.free_icon)
  end
  local playerUid = frienddata.UserInfo.Uid
  local funcViewUserInfo = function(target, go)
    local uid = Data.userData:GetUserUid()
    if uid == playerUid then
      return
    end
    local paramTab = {
      Position = go.transform.position,
      Uid = playerUid
    }
    UIHelper.OpenPage("UserInfoTip", paramTab)
  end
  UGUIEventListener.AddButtonOnClick(part.btnView, funcViewUserInfo, self)
  UGUIEventListener.AddButtonOnClick(part.btnHead, funcViewUserInfo, self)
end

function BattlePassPage:ShowRewardAndTaskTop()
  UIHelper.SetLocText(self.tab_Widgets.textLv, 3300039, Data.battlepassData:GetPassLevel())
  local passExp = Data.battlepassData:GetPassExp()
  local passExpMax = Logic.battlepassLogic:GetPassExpMax()
  local process = 0
  if 0 < passExpMax then
    process = passExp / passExpMax
  else
    passExp = 0
  end
  self.tab_Widgets.sliderExp.value = process
  UIHelper.SetText(self.tab_Widgets.textExp, "" .. passExp .. "/" .. passExpMax)
end

function BattlePassPage:updateLevelRewardPart(index, part)
  local cfg = self.mLevelRewardList[index]
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local curPassType = Data.battlepassData:GetPassType()
  local curIndex = self.tab_Widgets.contentRewardLvl:getCurrentRowOrColumnIndex() + IndexOffset
  local curShowIndex = curIndex > #self.mLevelRewardList and #self.mLevelRewardList or curIndex
  local showLevel = self.mLevelRewardList[curShowIndex].level
  self.mBaseLevel = curPassLevel > showLevel and curPassLevel or showLevel
  local targetRewardLevelCfg = Logic.battlepassLogic:GetTargetRewardLevelCfg(self.mBaseLevel)
  local lasttarget = self.mLastTarget or 0
  local tarcfg = targetRewardLevelCfg or {}
  local curtar = tarcfg.level or 0
  if curtar ~= lasttarget then
    self.mLastTarget = curtar
    self:ShowTargetLevelReward()
  end
  local isCan = Logic.battlepassLogic:CanLevelRewardGet(cfg.level)
  if isCan then
    part.objLevel:SetActive(false)
    part.btnGetReward.gameObject:SetActive(true)
    local level = cfg.level
    UGUIEventListener.AddButtonOnClick(part.btnGetReward, function()
      Service.battlepassService:SendGetReward({PassLevel = level})
    end)
  else
    part.objLevel:SetActive(true)
    part.btnGetReward.gameObject:SetActive(false)
    UIHelper.SetLocText(part.textLevel, 3300038, cfg.level)
  end
  part.objRewardFree:SetActive(false)
  part.objRewardPay:SetActive(false)
  if 0 < cfg.free_level_reward then
    local rewards = Logic.rewardLogic:FormatRewards({
      cfg.free_level_reward
    })
    local isGet = Data.battlepassData:IsPassLevelNormalRewardGet(cfg.level)
    UIHelper.CreateSubPart(part.objRewardFree, part.rectRewardFree, #rewards, function(subindex, subpart)
      local rewarditem = rewards[subindex]
      local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
      UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
      UIHelper.SetImage(subpart.img_icon, display.icon)
      UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
      UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
        Logic.itemLogic:ShowItemInfo(rewarditem.Type, rewarditem.ConfigId)
      end)
      subpart.obj_get:SetActive(isGet)
      local isLock = curPassLevel < cfg.level or curPassType < BATTLEPASS_TYPE.NORMAL
      subpart.obj_lock:SetActive(isLock)
    end)
    part.rectRewardFree.gameObject:SetActive(true)
  else
    part.rectRewardFree.gameObject:SetActive(false)
  end
  if 0 < cfg.pay_level_reward then
    local rewards = Logic.rewardLogic:FormatRewards({
      cfg.pay_level_reward
    })
    local isGet = Data.battlepassData:IsPassLevelAdvancedRewardGet(cfg.level)
    UIHelper.CreateSubPart(part.objRewardPay, part.rectRewardPay, #rewards, function(subindex, subpart)
      local rewarditem = rewards[subindex]
      local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
      UIHelper.SetLocText(subpart.tx_num, 710082, rewarditem.Num)
      UIHelper.SetImage(subpart.img_icon, display.icon)
      UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
      UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
        Logic.itemLogic:ShowItemInfo(rewarditem.Type, rewarditem.ConfigId)
      end)
      subpart.obj_get:SetActive(isGet)
      local isLock = curPassLevel < cfg.level or curPassType < BATTLEPASS_TYPE.ADVANCED
      subpart.obj_lock:SetActive(isLock)
    end)
    part.rectRewardPay.gameObject:SetActive(true)
  else
    part.rectRewardPay.gameObject:SetActive(false)
  end
end

function BattlePassPage:updatePassTaskPart(index, part, cfg)
  local taskId = cfg.id
  local taskData = Data.battlepassData:GetPassTaskData(taskId)
  UIHelper.SetText(part.textDetail, cfg.task_name)
  local processStr, processVal = Logic.battlepassLogic:GetTaskProcessStr(taskId)
  UIHelper.SetText(part.textProgress, processStr)
  part.sliderProcess.value = processVal
  if cfg.task_type == BATTLEPASS_TASK_TYPE.Rand then
    local isShowEffect = self.mRefreshEffectShowMap[index] or false
    if isShowEffect then
      self.mRefreshEffectShowMap[index] = nil
      part.objEffect:SetActive(false)
      part.objEffect:SetActive(true)
    end
    local taskData = Data.battlepassData:GetPassTaskData(taskId)
    if taskData.Status >= BATTLEPASS_TASK_STATUS.Finished then
      part.btnRefresh.gameObject:SetActive(false)
    else
      part.btnRefresh.gameObject:SetActive(true)
    end
    UGUIEventListener.AddButtonOnClick(part.btnRefresh, function()
      local refreshCountFree, refreshCountPay = Data.battlepassData:GetCurRefreshCount()
      local paramCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
      local content = ""
      local costNum = 0
      if refreshCountFree < paramCfg.free_refresh_count then
        local havecount = paramCfg.free_refresh_count - refreshCountFree
        content = UIHelper.GetLocString(3310002, havecount)
      elseif refreshCountPay < paramCfg.pay_refresh_count then
        local havecount = paramCfg.pay_refresh_count - refreshCountPay
        local num = paramCfg.pay_refresh_price[refreshCountPay + 1]
        local display = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, CurrencyType.DIAMOND)
        local coststr = "" .. num .. "" .. display.name
        costNum = num
        content = UIHelper.GetLocString(3310003, coststr, havecount)
      else
        noticeManager:ShowTipById(3310005)
        return
      end
      local refreshC = refreshCountFree + refreshCountPay
      local refreshCA = paramCfg.free_refresh_count + paramCfg.pay_refresh_count
      local contentR = UIHelper.GetLocString(3310004, refreshC, refreshCA)
      local callback = function()
        self:_DotRefresh(CurrencyType.DIAMOND, costNum)
        local taskindex = index
        Service.battlepassService:SendRefreshRandomTask({TaskId = taskId, TaskIndex = taskindex})
      end
      UIHelper.OpenPage("BattlePassNotice", {
        Content = content,
        ContentR = contentR,
        Callback = callback
      })
    end)
  else
    part.btnRefresh.gameObject:SetActive(false)
  end
  if taskData.Status == BATTLEPASS_TASK_STATUS.Recieved then
    part.objFinish:SetActive(true)
    part.objUnderWay:SetActive(false)
    part.btnGoto.gameObject:SetActive(false)
    part.btnGet.gameObject:SetActive(false)
  elseif taskData.Status == BATTLEPASS_TASK_STATUS.Finished then
    part.objFinish:SetActive(false)
    part.objUnderWay:SetActive(false)
    part.btnGoto.gameObject:SetActive(false)
    part.btnGet.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnGet, function()
      if not Logic.battlepassLogic:IsBattlePassActivityOpen() then
        noticeManager:ShowTipById(270022)
        return
      end
      Service.battlepassService:SendRecieveTaskReward({TaskId = taskId})
    end)
  elseif cfg.go_up_to > 0 then
    part.objFinish:SetActive(false)
    part.objUnderWay:SetActive(false)
    part.btnGoto.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
      if not Logic.battlepassLogic:IsBattlePassActivityOpen() then
        noticeManager:ShowTipById(270022)
        return
      end
      moduleManager:JumpToFunc(cfg.go_up_to, table.unpack(cfg.go_up_to_parm))
    end)
  else
    part.objFinish:SetActive(false)
    part.objUnderWay:SetActive(true)
    part.btnGoto.gameObject:SetActive(false)
  end
  local subpart = part.partTaskReward:GetLuaTableParts()
  local display = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, CurrencyType.BATTLEPASSEXP)
  UIHelper.SetLocText(subpart.tx_num, 710082, cfg.battlepass_exp)
  UIHelper.SetImage(subpart.img_icon, display.icon)
  UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
  UGUIEventListener.AddButtonOnClick(subpart.btn_reward, function()
    UIHelper.OpenPage("ItemInfoPage", display)
  end)
end

function BattlePassPage:updatePerweekPassTaskPart(index, part)
  local cfg = self.mPerweekPassTaskList[index]
  self:updatePassTaskPart(index, part, cfg)
end

function BattlePassPage:updateAchievePassTaskPart(index, part)
  local cfg = self.mAchievePassTaskList[index]
  self:updatePassTaskPart(index, part, cfg)
end

function BattlePassPage:sortFriendList()
  table.sort(self.mFriendList, function(a, b)
    if a.UserInfo.LogoffTime > self.startTime and b.UserInfo.LogoffTime > self.startTime then
      if a.UserInfo.BattlePassLevel ~= b.UserInfo.BattlePassLevel then
        return a.UserInfo.BattlePassLevel > b.UserInfo.BattlePassLevel
      end
    elseif a.UserInfo.LogoffTime ~= b.UserInfo.LogoffTime then
      return a.UserInfo.LogoffTime > b.UserInfo.LogoffTime
    end
    if a.UserInfo.BattlePassType ~= b.UserInfo.BattlePassType then
      return a.UserInfo.BattlePassType > b.UserInfo.BattlePassType
    end
    if a.UserInfo.Level ~= b.UserInfo.Level then
      return a.UserInfo.Level > b.UserInfo.Level
    end
    if a.UserInfo.BattlePassExpUpdateTime ~= b.UserInfo.BattlePassExpUpdateTime then
      return a.UserInfo.BattlePassExpUpdateTime < b.UserInfo.BattlePassExpUpdateTime
    end
    if a.UserInfo.Uid ~= b.UserInfo.Uid then
      return a.UserInfo.Uid < b.UserInfo.Uid
    end
    return false
  end)
end

function BattlePassPage:_DotRefresh(currencyType, costNum)
  local dotInfo = {
    info = "battlepass_refresh",
    cost_num = {currencyType, costNum}
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

return BattlePassPage
