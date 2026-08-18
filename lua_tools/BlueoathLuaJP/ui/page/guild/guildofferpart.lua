local GuildOfferPart = class("ui.page.Guild.GuildOfferPart")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local taskType = TaskType.GuildOffer
local trsName = {
  [1] = {Name = "per"},
  [2] = {Name = "guild"}
}
local serverParamStr = {
  [1] = {
    Name = "PersonalRewardProgress"
  },
  [2] = {
    Name = "GuildRewardProgress"
  }
}
local ScoreType = {Person = 1, GuildOffer = 2}

function GuildOfferPart:OnInit(page)
  self.guildOfferPage = page
  self.m_widgetsTab = page.tab_Widgets.lp_GuildOffer:GetLuaTableParts()
  self.m_Toggle_IndexCfg = {
    [1] = {
      fun = function()
        self:GetGuildOfferInfo()
      end,
      index = 1,
      obj = self.m_widgetsTab.obj_TaskPart
    },
    [2] = {
      fun = function()
        self:LoadRewardDtl()
      end,
      index = 2,
      obj = self.m_widgetsTab.RewardPart
    },
    [3] = {
      fun = function()
        self:ShowGuildRank()
      end,
      index = 3,
      obj = self.m_widgetsTab.obj_GuildRank
    }
  }
  self:RegisterEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.m_widgetsTab.tog_group, self, "", self.SwitchTogs)
end

function GuildOfferPart:Show()
  self:DoOnShow()
  self.partContainer = {}
  local actCfg = configManager.GetDataById("config_activity", ActivityType.GuildOfferAct)
  local isOnPeriod = PeriodManager:IsInPeriod(actCfg.period)
  self.m_widgetsTab.UnOpen:SetActive(not isOnPeriod)
  if isOnPeriod then
    self.m_widgetsTab.tog_group:SetActiveToggleIndex(0)
    self.userId = Data.userData:GetUserUid()
    Service.guildService:SendGuildOfferRankList(1, 100)
  end
  Service.guildService:SendGuildOfferGuildRankList(1, 100)
end

function GuildOfferPart:RegisterEvent()
  UGUIEventListener.AddButtonOnClick(self.m_widgetsTab.btn_challengeAdd, function()
    UIHelper.OpenPage("BuyTicketPage")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgetsTab.BtnHelp, function()
    UIHelper.OpenPage("HelpPage", {content = 3700001})
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgetsTab.btn_receiveAll, function()
    Service.guildService:SendReceiveAllGOReward()
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgetsTab.btn_PersonRank, function()
    self:ShowRank()
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgetsTab.btn_ClosePersonRank, function()
    self:CloseRank()
  end, self)
end

function GuildOfferPart:DoOnShow()
  eventManager:RegisterEvent(LuaEvent.UpdateGuildOfferUserInfo, self.UpdateGuildOfferUserInfo, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildOfferTaskInfo, self.UpdateGuildOfferTaskInfo, self)
  eventManager:RegisterEvent(LuaEvent.UpdateUserGOTaskInfo, self.UpdateMyGuildOfferTask, self)
  eventManager:RegisterEvent(LuaEvent.ReceiveRewardBack, self.ReceiveRewardBack, self)
  eventManager:RegisterEvent(LuaEvent.UpdataTaskList, self.UpdateMyGuildOfferTask, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarOfferRankList, self.UpdateRankList, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarOfferGuildRankList, self.UpdateGuildRankList, self)
end

function GuildOfferPart:UnRegisterEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildOfferUserInfo, self.UpdateGuildOfferUserInfo, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateUserGOTaskInfo, self.UpdateMyGuildOfferTask, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildOfferTaskInfo, self.UpdateGuildOfferTaskInfo, self)
  eventManager:UnregisterEvent(LuaEvent.ReceiveRewardBack, self.ReceiveRewardBack, self)
  eventManager:UnregisterEvent(LuaEvent.UpdataTaskList, self.UpdateMyGuildOfferTask, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarOfferRankList, self.UpdateRankList, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarOfferGuildRankList, self.UpdateGuildRankList, self)
end

function GuildOfferPart:SwitchTogs(index)
  self.FunToggleIndex = index + 1
  for i = 1, 3 do
    self.m_Toggle_IndexCfg[i].obj:SetActive(index + 1 == i)
  end
  local actCfg = configManager.GetDataById("config_activity", ActivityType.GuildOfferAct)
  local isOnPeriod = PeriodManager:IsInPeriod(actCfg.period)
  self.m_widgetsTab.periodContent.gameObject:SetActive(self.FunToggleIndex == 1 and isOnPeriod)
  self.m_Toggle_IndexCfg[index + 1].fun()
end

function GuildOfferPart:GetGuildOfferInfo()
  UIHelper.SetText(self.m_widgetsTab.txt_period, "")
  Service.guildService:SendGuildOfferInfo()
  Service.guildService:SendGuildOfferUserInfo()
  self:UpdateMyGuildOfferTask()
end

function GuildOfferPart:CreatActivityTimer()
  if self.activityTimer ~= nil then
    self.guildOfferPage:StopTimer(self.activityTimer)
    self.activityTimer = nil
  end
  local actCfg = configManager.GetDataById("config_activity", ActivityType.GuildOfferAct)
  local periodCfg = configManager.GetDataById("config_period", actCfg.period)
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(actCfg.period)
  local isOnPeriod = PeriodManager:IsInPeriod(actCfg.period)
  if isOnPeriod then
    self.activityTimer = self.guildOfferPage:CreateTimer(function()
      local now = time.getSvrTime()
      local str = time.getTimeStringFontDynamic(endTime - now)
      UIHelper.SetText(self.m_widgetsTab.txt_period, str)
      if self.FunToggleIndex == 1 then
        if self.partContainer then
          for k, v in pairs(self.partContainer) do
            local part = v
            local taskInfo = v.taskInfo
            local taskStartTime = taskInfo.Data.StartTime
            local limitTime = taskInfo.Config.limittime
            local timeStr = time.getHoursString(taskStartTime + limitTime - now)
            part.ImgOver.gameObject:SetActive(taskStartTime + limitTime - now < 0)
            UIHelper.SetText(part.txt_Time, timeStr)
          end
        end
      elseif self.FunToggleIndex == 2 then
        if self.isRefresh then
          for i = 1, ScoreType.GuildOffer do
            local perCfg, guildCfg = Data.guildOfferData:GetPerAndGdScoreCfg()
            local conTrs = i == ScoreType.Person and self.m_widgetsTab.trs_perContent or self.m_widgetsTab.trs_guildContent
            local cfgData = i == ScoreType.Person and perCfg or guildCfg
            local finialTrs = conTrs:Find(#cfgData).gameObject:GetComponent(RectTransform.GetClassType())
            if finialTrs.anchoredPosition.x > 0.1 then
              self:SetPersonSlider(i)
            end
          end
        end
        self.isRefresh = false
      end
      self:CheckUserFirstClickOnEnd24Hour(now, endTime)
    end, 1, -1, false)
    self.guildOfferPage:StartTimer(self.activityTimer)
  else
  end
end

function GuildOfferPart:CheckUserFirstClickOnEnd24Hour(now, endTime)
  if endTime - now <= 86400 and not PlayerPrefs.GetBool(self.userId .. "CheckUserFirstClickOnEnd24Hour" .. endTime, false) then
    PlayerPrefs.SetBool(self.userId .. "CheckUserFirstClickOnEnd24Hour" .. endTime, true)
    noticeManager:OpenTipPage(self, UIHelper.GetString(3700046))
  end
end

function GuildOfferPart:UpdateMyGuildOfferTask()
  local myGuildOfferTask = self:GetTaskListByType(taskType)
  Data.guildOfferData:SetReceiveTaskCount(myGuildOfferTask)
  if myGuildOfferTask == nil then
    return
  end
  self:SetMyTaskList(myGuildOfferTask)
  self:CreatActivityTimer()
end

function GuildOfferPart:ReceiveRewardBack(data)
  if next(data.Reward) ~= nil then
    for v, k in pairs(data) do
      Logic.rewardLogic:ShowCommonReward(k, "GuildOfferPart", nil)
    end
  else
    noticeManager:ShowTip(UIHelper.GetString(3310011))
  end
end

function GuildOfferPart:LoadRewardDtl()
  local perCfg, guildCfg = Data.guildOfferData:GetPerAndGdScoreCfg()
  self:LoadPerRewardDtl(perCfg)
  self:LoadGRewardDtl(guildCfg)
end

function GuildOfferPart:LoadPerRewardDtl(data)
  self:CreateScoreSubPart(data, ScoreType.Person)
end

function GuildOfferPart:LoadGRewardDtl(data)
  self:CreateScoreSubPart(data, ScoreType.GuildOffer)
end

function GuildOfferPart:CreateScoreSubPart(data, type)
  local obj = self.m_widgetsTab["obj_" .. trsName[type].Name .. "Score"]
  local trs = self.m_widgetsTab["trs_" .. trsName[type].Name .. "Content"]
  local rewardData = Data.guildOfferData:GetUserOfferInfo()[serverParamStr[type].Name]
  local score = 0
  local perScore = Data.guildOfferData:GetUserOfferInfo().PersonalPoints or 0
  if type == ScoreType.GuildOffer then
    score = Data.guildOfferData:GetGuildPoints() or 0
  else
    score = perScore
  end
  UIHelper.CreateSubPart(obj, trs, #data, function(index, part)
    local partData = data[index]
    UIHelper.SetText(part.txt_score, partData.score)
    UIHelper.SetText(part.txt_perScore, partData.personscore or 0)
    local isReach = type == ScoreType.Person and score >= partData.score or score >= partData.score and perScore >= partData.personscore
    local isRecv = self:GetRewardState(index, rewardData)
    part.obj_check:SetActive(isRecv)
    part.obj_reach:SetActive(isReach)
    local luaPart = part.RewardTemplate:GetLuaTableParts()
    luaPart.obj_reach:SetActive(isReach and not isRecv)
    luaPart.obj_unlock:SetActive(not isReach)
    luaPart.obj_check:SetActive(isRecv)
    local rewards = configManager.GetDataById("config_rewards", partData.reward).rewards
    local rewardInfo = rewards[1]
    local itemType = rewardInfo[1]
    local itemId = rewardInfo[2]
    local num = rewardInfo[3]
    local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
    local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
    UIHelper.SetImage(luaPart.icon, icon)
    UIHelper.SetImageByQuality(luaPart.img_bg, quality)
    UIHelper.SetText(luaPart.txt_num, "x" .. num)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_icon, function()
      if isReach and not isRecv then
        if type == ScoreType.Person then
          Service.guildService:SendReceiveOfferRewardPerson(index)
        else
          Service.guildService:SendReceiveOfferRewardGuild(index)
        end
      end
    end)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_unlock, function()
      if itemType == GoodsType.EQUIP then
        UIHelper.OpenPage("ShowEquipPage", {
          templateId = itemId,
          showEquipType = ShowEquipType.Simple
        })
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemType, itemId))
      end
    end)
  end)
end

function GuildOfferPart:GetRewardState(id, data)
  if data == nil then
    return false
  end
  for k, v in pairs(data) do
    if v == id then
      return true
    end
  end
  return false
end

function GuildOfferPart:GetTaskState(taskInfo)
  local status = TaskState.TODO
  if taskInfo and taskInfo.RewardTime > 0 then
    status = TaskState.RECEIVED
  elseif taskInfo and taskInfo.FinishTime ~= 0 then
    status = TaskState.FINISH
  end
  return status
end

function GuildOfferPart:GetTaskListByType(taskType, activityId)
  local tabTaskList = Data.taskData:GetTaskDataByType(taskType)
  if tabTaskList == nil then
    return nil
  end
  if taskType == TaskType.Activity and activityId == nil then
    logError("activity task, need param activityId")
    return nil
  end
  local tabResult = {}
  for _, v in pairs(tabTaskList) do
    if self:GetTaskState(v) ~= TaskState.FINISH and self:GetTaskState(v) ~= TaskState.RECEIVED then
      local config = Logic.taskLogic:GetTaskConfig(v.TaskId, v.Type)
      if config == nil then
        print("can't find task config,taskId:" .. v.TaskId .. "task Type:" .. v.Type)
      else
        local isOk = true
        if taskType == TaskType.Activity then
          isOk = activityId == config.activity_id
        end
        if isOk then
          local taskInfo = Logic.taskLogic:_GenTaskInfo(v, config)
          table.insert(tabResult, taskInfo)
        end
      end
    end
  end
  return Logic.taskLogic:SortTask(tabResult)
end

function GuildOfferPart:UpdateGuildOfferUserInfo()
  local userInfo = Data.guildOfferData:GetUserOfferInfo()
  local isExist = userInfo.IsExit and userInfo.IsExit == 1
  self.m_widgetsTab.obj_RefuseInfo:SetActive(isExist)
  UIHelper.SetText(self.m_widgetsTab.txt_perScore, userInfo.PersonalPoints)
  UIHelper.SetText(self.m_widgetsTab.txt_PerScore, userInfo.PersonalPoints)
  UIHelper.SetText(self.m_widgetsTab.txt_challengeNum, userInfo.UseOfferCount .. "/" .. userInfo.AllOfferCount)
  if self.FunToggleIndex == 2 then
    self:LoadRewardDtl()
  end
  if self.FunToggleIndex == 1 then
  end
  self.isRefresh = true
end

function GuildOfferPart:UpdateGuildOfferTaskInfo()
  local point = Data.guildOfferData:GetGuildPoints()
  UIHelper.SetText(self.m_widgetsTab.txt_guildScore, point)
  UIHelper.SetText(self.m_widgetsTab.txt_GuildScore, point)
  local offerList = Data.guildOfferData:GetOfferList()
  self.guildOffertaskList, self.taskList = Data.guildOfferData:ParaseGuildOfferTaskData(offerList)
  self:SetGuildTaskList()
end

function GuildOfferPart:ParaseGuildOfferTaskData(data)
  local taskList = {}
  local selfTaskList = {}
  for k, v in pairs(data) do
    local quality = v
    for index, taskInfo in pairs(quality.OfferList) do
      local paraseTask = taskInfo
      local config = Data.guildOfferData:LoadTaskInfoByCfgIndex(paraseTask.TaskId)
      paraseTask.Quality = quality.Quality
      paraseTask.config = config
      if paraseTask.AcceptInfo ~= nil and #paraseTask.AcceptInfo > 0 then
        for indexUser, userInfo in pairs(paraseTask.AcceptInfo) do
          if userInfo.Uid == self.userId then
            table.insert(selfTaskList, paraseTask)
          end
        end
      end
      table.insert(taskList, paraseTask)
    end
  end
  table.sort(taskList, function(l, r)
    if l.IsTaskOver ~= r.IsTaskOver then
      return l.IsTaskOver < r.IsTaskOver
    end
    if l.Quality ~= r.Quality then
      return l.Quality < r.Quality
    end
    return l.config.order < r.config.order
  end)
  return taskList, selfTaskList
end

function GuildOfferPart:SetGuildTaskList()
  if self.m_widgetsTab.scr_TaskList == nil then
    logError("scr list is nil")
  end
  if self.m_widgetsTab.obj_TaskPart == nil then
    logError("obj_TaskPart list is nil")
  end
  local guildIndex = 100
  local guildOfferCfg = configManager.GetDataById("config_guildoffer_info", 1)
  local bgStrPath = {
    [1] = guildOfferCfg.task_bg[3],
    [2] = guildOfferCfg.task_bg[2],
    [3] = guildOfferCfg.task_bg[1]
  }
  UIHelper.SetInfiniteItemParam(self.m_widgetsTab.scr_TaskList, self.m_widgetsTab.obj_guildItem, #self.guildOffertaskList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local taskInfo = self.guildOffertaskList[index]
      local cfg = Data.guildOfferData:LoadTaskInfoByCfgIndex(taskInfo.TaskId)
      UIHelper.SetText(part.txt_ScoreNum, "+" .. cfg.score)
      UIHelper.SetText(part.txt_Name, cfg.desc)
      UIHelper.SetText(part.txt_Name, cfg.desc)
      UIHelper.SetText(part.txt_RecNum, taskInfo.AcceptNum .. "/" .. cfg.applynum)
      UIHelper.SetText(part.txt_CompleteNum, taskInfo.AcceptNum .. "/" .. cfg.applynum)
      UIHelper.SetImage(part.imgBG, bgStrPath[cfg.quality])
      UIHelper.SetText(part.txt_Time, time.getHoursString(cfg.limittime))
      part.obj_time:SetActive(true)
      part.obj_RecObj:SetActive(true)
      part.Btn_GiveUp.gameObject:SetActive(false)
      part.Btn_Check.gameObject:SetActive(true)
      part.obj_CompletePro:SetActive(false)
      UGUIEventListener.AddButtonOnClick(part.Btn_Check, function()
        local openParam = {taskInfo = taskInfo, config = cfg}
        UIHelper.OpenPage("GuildOfferInfoPage", openParam)
      end)
    end
  end)
end

function GuildOfferPart:SetMyTaskList(data)
  local SelfIndex = 0
  if data == nil or #data < 1 then
    self.m_widgetsTab.obj_SelfTaskList:SetActive(false)
    self.m_widgetsTab.obj_NoTaskTips:SetActive(true)
    return
  else
    self.m_widgetsTab.obj_SelfTaskList:SetActive(true)
    self.m_widgetsTab.obj_NoTaskTips:SetActive(false)
  end
  local isMonthPri = Logic.userLogic:CheckMonthCardPrivilege()
  local taskCount = #data
  local guildOfferCfg = configManager.GetDataById("config_guildoffer_info", 1)
  local bgStrPath = {
    [1] = guildOfferCfg.task_bg[3],
    [2] = guildOfferCfg.task_bg[2],
    [3] = guildOfferCfg.task_bg[1]
  }
  UIHelper.CreateSubPart(self.m_widgetsTab.obj_item, self.m_widgetsTab.trs_selfCon, 1, function(index, part)
    if index == 2 and index > taskCount then
      part.obj_normal:SetActive(false)
      part.obj_month:SetActive(true)
      return
    end
    part.obj_normal:SetActive(true)
    part.obj_month:SetActive(false)
    part.ImgOver:SetActive(false)
    local taskInfo = data[index]
    local cfg = Data.guildOfferData:LoadTaskInfoByCfgIndex(taskInfo.TaskId)
    UIHelper.SetText(part.txt_ScoreNum, "+" .. cfg.score)
    UIHelper.SetText(part.txt_Name, cfg.desc)
    UIHelper.SetText(part.txt_Name, cfg.desc)
    UIHelper.SetImage(part.imgBG, bgStrPath[taskInfo.Config.quality])
    UIHelper.SetText(part.txt_CompleteNum, taskInfo.ProgressStr)
    part.obj_time:SetActive(true)
    part.obj_RecObj:SetActive(false)
    part.Btn_GiveUp.gameObject:SetActive(true)
    part.Btn_Check.gameObject:SetActive(false)
    part.obj_CompletePro:SetActive(true)
    part.taskInfo = taskInfo
    UGUIEventListener.AddButtonOnClick(part.Btn_GiveUp, function()
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            Service.guildService:SendGuildAbandonOffer(taskInfo.TaskId)
          end
        end
      }
      noticeManager:ShowMsgBox(UIHelper.GetString(3700044), tabParams)
    end)
    self.partContainer[SelfIndex + index] = part
  end)
end

function GuildOfferPart:OnHide()
  self:UnRegisterEvent()
end

function GuildOfferPart:OnClose()
  self:UnRegisterEvent()
end

function GuildOfferPart:UpdateRankList()
  if not self.m_widgetsTab.Rank.activeSelf then
    return
  end
  self:ShowRankList()
  self:ShowSelfRank()
end

function GuildOfferPart:ShowRank()
  Service.guildService:SendGuildOfferRankList(1, 100)
  self.m_widgetsTab.Rank:SetActive(true)
  self:ShowRankList()
  self:ShowSelfRank()
end

function GuildOfferPart:CloseRank()
  self.m_widgetsTab.Rank:SetActive(false)
end

function GuildOfferPart:ShowRankList()
  local guildWarData = Data.guildData:GetGuildWarData()
  local rankList = guildWarData.offerRankList
  UIHelper.SetInfiniteItemParam(self.m_widgetsTab.scr_RankLst, self.m_widgetsTab.obj_RankItem, #rankList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local rankInfo = rankList[index]
      UIHelper.SetText(part.tx_textRank, rankInfo.rankNo)
      UIHelper.SetText(part.tx_textName, rankInfo.userInfo.Uname)
      UIHelper.SetText(part.tx_textScore, rankInfo.points)
    end
  end)
end

function GuildOfferPart:ShowSelfRank()
  local selfRank_Widgets = self.m_widgetsTab.lp_selfRank:GetLuaTableParts()
  local guildWarData = Data.guildData:GetGuildWarData()
  local selfRankInfo = guildWarData.offerSelfRank
  if next(selfRankInfo) == nil then
    local user = Data.userData:GetUserData()
    UIHelper.SetText(selfRank_Widgets.tx_textRank, UIHelper.GetString(3700018))
    UIHelper.SetText(selfRank_Widgets.tx_textName, user.Uname)
    UIHelper.SetText(selfRank_Widgets.tx_textScore, "0")
  else
    UIHelper.SetText(selfRank_Widgets.tx_textRank, selfRankInfo.rankNo)
    UIHelper.SetText(selfRank_Widgets.tx_textName, selfRankInfo.userInfo.Uname)
    UIHelper.SetText(selfRank_Widgets.tx_textScore, selfRankInfo.points)
  end
end

function GuildOfferPart:ShowRewardList()
  local rewardList = Logic.guildLogic:GetGuildofferRankRewardConfig()
  UIHelper.CreateSubPart(self.m_widgetsTab.obj_rewardItem, self.m_widgetsTab.rect_rewardContent, #rewardList, function(index, tabPart)
    local rewardConfig = rewardList[index]
    if rewardConfig == nil then
      logError("config_guildoffer_rankreward id:%d is nil", index)
      return
    end
    local noStr = ""
    if rewardConfig.rankid[1] == rewardConfig.rankid[2] then
      noStr = tostring(rewardConfig.rankid[1])
    else
      noStr = rewardConfig.rankid[1] .. "-" .. rewardConfig.rankid[2]
    end
    UIHelper.SetText(tabPart.tx_textRank, noStr)
    local rewardsCfg = configManager.GetDataById("config_rewards", rewardConfig.reward)
    if rewardsCfg == nil then
      logError("GuildOfferPart:ShowRewardList get rewards[id:%d] config is nil", rewardConfig.reward)
      return
    end
    local rewards = rewardsCfg.rewards
    UIHelper.CreateSubPart(tabPart.obj_detailitem, tabPart.rect_detailContent, #rewards, function(idx, subPart)
      local rewardInfo = rewards[idx]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(subPart.im_icon, icon)
      UIHelper.SetImageByQuality(subPart.im_bg, quality)
      UIHelper.SetText(subPart.tx_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, false)
      end
      
      UGUIEventListener.AddButtonOnClick(subPart.btn_clickBtn, clickFunc)
    end)
  end)
end

function GuildOfferPart:UpdateGuildRankList()
  if self.FunToggleIndex ~= 3 then
    return
  end
  self:ShowGuildRankList()
  self:ShowSelfGuildRank()
end

function GuildOfferPart:ShowGuildRank()
  Service.guildService:SendGuildOfferGuildRankList(1, 100)
  self:ShowGuildRankList()
  self:ShowSelfGuildRank()
  self:ShowGuildRewardList()
end

function GuildOfferPart:ShowGuildRankList()
  local guildWarData = Data.guildData:GetGuildWarData()
  local rankList = guildWarData.offerGuildRankList
  UIHelper.SetInfiniteItemParam(self.m_widgetsTab.scr_GuildRankList, self.m_widgetsTab.obj_GuildRankItem, #rankList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local rankInfo = rankList[index]
      local serName = rankInfo.serverId
      if platformManager:getServiceList() and #platformManager:getServiceList() > 0 then
        serName = Logic.serverLogic:GetServerNameById(rankInfo.serverId)
      end
      serName = serName .. "-" .. rankInfo.name
      UIHelper.SetText(part.tx_textRank, rankInfo.rankNo)
      UIHelper.SetText(part.tx_textName, serName)
      UIHelper.SetText(part.tx_textScore, rankInfo.points)
    end
  end)
end

function GuildOfferPart:ShowSelfGuildRank()
  local selfRank_Widgets = self.m_widgetsTab.lp_selfGuildRank:GetLuaTableParts()
  local guildWarData = Data.guildData:GetGuildWarData()
  local selfRankInfo = guildWarData.offerSelfGuildRank
  local serName = Logic.loginLogic.SDKInfo and Logic.loginLogic.SDKInfo.name or selfRankInfo.serverId or UIHelper.GetString(920000277)
  if next(selfRankInfo) == nil then
    local ourGuild = Data.guildData:getOurGuildInfo()
    UIHelper.SetText(selfRank_Widgets.tx_textRank, UIHelper.GetString(3700018))
    UIHelper.SetText(selfRank_Widgets.tx_textScore, "0")
    local selfName = ourGuild:getName() or ""
    serName = serName .. "-" .. selfName
  else
    UIHelper.SetText(selfRank_Widgets.tx_textRank, selfRankInfo.rankNo)
    UIHelper.SetText(selfRank_Widgets.tx_textScore, selfRankInfo.points)
    serName = serName .. "-" .. selfRankInfo.name
  end
  UIHelper.SetText(selfRank_Widgets.tx_textName, serName)
end

function GuildOfferPart:ShowGuildRewardList()
  local rewardList = Logic.guildLogic:GetGuildofferGuildRankRewardConfig()
  UIHelper.CreateSubPart(self.m_widgetsTab.obj_guildRewardItem, self.m_widgetsTab.rect_guildRewardContent, #rewardList, function(index, tabPart)
    local rewardConfig = rewardList[index]
    if rewardConfig == nil then
      logError("config_guildoffer_guildrankreward id:%d is nil", index)
      return
    end
    local noStr = ""
    if rewardConfig.rankid[1] == rewardConfig.rankid[2] then
      noStr = tostring(rewardConfig.rankid[1])
    else
      noStr = rewardConfig.rankid[1] .. "-" .. rewardConfig.rankid[2]
    end
    UIHelper.SetText(tabPart.tx_textRank, noStr)
    local scoreDes = string.format(UIHelper.GetString(3700045), rewardConfig.limitscore)
    UIHelper.SetText(tabPart.tx_Tips, scoreDes)
    local rewardsCfg = configManager.GetDataById("config_rewards", rewardConfig.reward)
    if rewardsCfg == nil then
      logError("GuildOfferPart:ShowRewardList get rewards[id:%d] config is nil", rewardConfig.reward)
      return
    end
    local rewards = rewardsCfg.rewards
    UIHelper.CreateSubPart(tabPart.obj_detailitem, tabPart.rect_detailContent, #rewards, function(idx, subPart)
      local rewardInfo = rewards[idx]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(subPart.im_icon, icon)
      UIHelper.SetImageByQuality(subPart.im_bg, quality)
      UIHelper.SetText(subPart.tx_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, false)
      end
      
      UGUIEventListener.AddButtonOnClick(subPart.btn_clickBtn, clickFunc)
    end)
  end)
end

function GuildOfferPart:SetPersonSlider(scoreType)
  local perCfg, guildCfg = Data.guildOfferData:GetPerAndGdScoreCfg()
  local trs_slider = scoreType == ScoreType.Person and self.m_widgetsTab.sld_per or self.m_widgetsTab.sld_guild
  local itemObj = scoreType == ScoreType.Person and self.m_widgetsTab.obj_perScore or self.m_widgetsTab.obj_guildScore
  local cfgData = scoreType == ScoreType.Person and perCfg or guildCfg
  local conTrs = scoreType == ScoreType.Person and self.m_widgetsTab.trs_perContent or self.m_widgetsTab.trs_guildContent
  local score = scoreType == ScoreType.Person and Data.guildOfferData:GetUserOfferInfo().PersonalPoints or Data.guildOfferData:GetGuildPoints()
  if score ~= nil then
    self:SetSliderInfo(trs_slider, itemObj, cfgData, score, conTrs, scoreType)
  else
    trs_slider.value = 0
  end
end

function GuildOfferPart:SetSliderInfo(slider, itemObj, cfgData, score, conTrs, scoreType)
  local partObj = itemObj
  local trs = partObj:GetComponent(RectTransform.GetClassType())
  local trs_slider = slider.gameObject:GetComponent(RectTransform.GetClassType())
  local sliderWidgth = trs_slider.sizeDelta.x
  local widgth = trs.sizeDelta.x
  local index = tostring(#cfgData)
  local finialTrs = conTrs:Find(index).gameObject:GetComponent(RectTransform.GetClassType())
  local sv_widgth = scoreType == ScoreType.Person and self.m_widgetsTab.trs_SVper.localPosition.x or self.m_widgetsTab.trs_SVguild.localPosition.x
  local indexWidgth = Mathf.Abs((finialTrs.anchoredPosition.x - sv_widgth - widgth * (index - 1)) / (index - 1))
  local finialSilderV = (finialTrs.anchoredPosition.x - sv_widgth + widgth * 0.5) / sliderWidgth
  table.sort(cfgData, function(l, r)
    return l.id < r.id
  end)
  local scoreTab = {}
  table.insert(scoreTab, {
    index = 0,
    score = 0,
    widthPoint = 0,
    sliderValue = 0
  })
  for i = 1, #cfgData do
    local pointscore = cfgData[i].score
    local widthPoint = (indexWidgth + widgth) * (i - 1) + widgth / 2
    local sliderValue = finialSilderV / #cfgData * i
    table.insert(scoreTab, {
      index = i,
      score = pointscore,
      widthPoint = widthPoint,
      sliderValue = sliderValue
    })
  end
  table.insert(scoreTab, {
    index = #cfgData + 1,
    score = cfgData[#cfgData].score * 2,
    widthPoint = sliderWidgth,
    sliderValue = 1
  })
  slider.value = self:GetSliderValue(score, sliderWidgth, scoreTab)
end

function GuildOfferPart:GetSliderValue(score, widgth, scoreTab)
  local max = 0
  local value = 0
  for i = 1, #scoreTab do
    if score < scoreTab[i].score then
      max = i
      break
    end
  end
  if score > scoreTab[#scoreTab].score then
    max = #scoreTab
  end
  if 1 < max then
    local maxInfo = scoreTab[max]
    local minInfo = scoreTab[max - 1]
    local perValue = (maxInfo.widthPoint - minInfo.widthPoint) / (maxInfo.score - minInfo.score)
    value = (minInfo.widthPoint + perValue * (score - minInfo.score)) / widgth
  else
    value = 0
  end
  return value
end

return GuildOfferPart
