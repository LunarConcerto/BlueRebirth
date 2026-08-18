local SportChallengePage = class("UI.Sport.SportChallengePage", LuaUIPage)
local taskType = TaskType.Sport
local FromRank = 1
local ToRank = 200
local txtColor = {
  [1] = "FFFFFF",
  [2] = "FF0000"
}
local titleStr = {
  [1] = UIHelper.GetString(920000822),
  [2] = UIHelper.GetString(920000823),
  [3] = UIHelper.GetString(920000824)
}

function SportChallengePage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SportChallengePage:DoOnOpen()
  self.param = self:GetParam()
  self.copyId = self.param.copyId and self.param.copyId or 0
  Logic.copyLogic:SetCurCopyId(self.copyId)
  self.m_displayConfig = Logic.copyLogic:GetCopyDesConfig(self.copyId)
  self.periodId = self.param.periodId
  self.chapterInfo = self.param.chapterInfo
  self:OpenTopPage("SportChallengePage", 1, titleStr[self.copyId % 10], self, true)
  self:ShowCopyDetailsInfo()
  self:ShowChallengeInfo()
  self:SetSportFreeInfo()
  self:InitFleetInfo()
  self:SetSportFinishTxt()
  self:GetTickCount()
  Service.sportMeetService:GetUserRankData()
  self:SetRedDot()
  self:GetRankData()
end

function SportChallengePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_help, function()
    logError("help")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_rank, function()
    UIHelper.OpenPage("SportRankPage", {
      periodId = self.param.periodId,
      copyId = self.copyId,
      copyList = self.chapterInfo.level_list
    })
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_reward, function()
    UIHelper.OpenPage("SportScoreRewardPage")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_train, function()
    self.battleMode = BattleMode.Exercises
    if self:CanBattle() then
      self:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
      Service.cacheDataService:SendCacheData("copy.StartBase", "SportChallengePage")
    end
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Challenge, function()
    self.battleMode = BattleMode.Normal
    if self:CanBattle() then
      self:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
      Service.cacheDataService:SendCacheData("copy.StartBase", "SportChallengePage")
    end
  end, self)
  self:RegisterEvent(LuaEvent.UpdatePlotCopy, self.DoOnOpen, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdateSportTickInfo, self.RefreshTickCount, self)
  self:RegisterEvent(LuaEvent.CopyStartBase, function(handler, ret)
    self:CopyEnter(ret)
  end)
  self:RegisterEvent(LuaEvent.UpdateSportInfo, self.SetUserSportRankInfo, self)
  self:RegisterEvent(LuaEvent.GetSportRewardRecInfo, function()
    self:SetRedDot()
  end, self)
end

function SportChallengePage:GetRankData()
  local arg = {FromRankNo = FromRank, ToRankNo = ToRank}
  for i = 1, 3 do
    arg.type = i
    Service.sportMeetService:GetSportRankData(arg)
  end
end

function SportChallengePage:SetRedDot()
  local isShow = Data.sportMeetData:GetSportPointsCanRec()
  self.m_tabWidgets.obj_redDot:SetActive(isShow)
end

function SportChallengePage:SetUserSportRankInfo()
  local sportMeetData = Data.sportMeetData:GetMySportRankData()
  self:ShowCopyDetailsInfo()
end

function SportChallengePage:CanBattle()
  local sportMeetData = Data.sportMeetData:GetSportTickCount()
  local isInPeriod = PeriodManager:IsInPeriod(self.periodId)
  local data = sportMeetData.freeList[self.copyId]
  local isHasFleet = Logic.fleetLogic:IsHasFleet(FleetType.Normal)
  if not isHasFleet then
    noticeManager:ShowMsgBox(110007)
    return false
  end
  if self.battleMode == BattleMode.Exercises then
    local exercisesPoint = Data.userData:GetCurrency(CurrencyType.EXERCISES)
    if exercisesPoint < self.m_displayConfig.exercises_point then
      noticeManager:OpenTipPage(self, 1701001)
      return false
    end
  else
    if Logic.copyLogic:CheckDockFull() then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_ClikAllDock()
          end
        end,
        nameOk = UIHelper.GetString(180029)
      }
      noticeManager:ShowMsgBox(110012, tabParams)
      return false
    end
    if Logic.copyLogic:CheckEquipBagFull() then
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_ClikToEquipPage()
          end
        end
      }
      noticeManager:ShowMsgBox(1000014, tabParams)
      return false
    end
  end
  local now = time.getSvrTime()
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.periodId)
  if not isInPeriod or now >= endTime then
    noticeManager:ShowMsgBox(UIHelper.GetString(270022))
    return false
  end
  if self.battleMode ~= BattleMode.Exercises and sportMeetData and sportMeetData.tickCount <= 0 and (data == nil or data and 0 >= data.FreeCount) then
    noticeManager:ShowMsgBox(810030)
    return false
  end
  return true
end

function SportChallengePage:_ClikAllDock()
  UIHelper.OpenPage("HeroRetirePage")
end

function SportChallengePage:_ClikToEquipPage()
  UIHelper.ClosePage("NoticePage")
  UIHelper.OpenPage("DismantlePage")
end

function SportChallengePage:_OnGetReward(args)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = args.Rewards
  })
  self:ShowChallengeInfo()
end

function SportChallengePage:GetTickCount()
  Service.sportMeetService:GetUserSportTickData()
end

function SportChallengePage:RefreshTickCount()
  local sportMeetData = Data.sportMeetData:GetSportTickCount()
  UIHelper.SetText(self.m_tabWidgets.txt_num, sportMeetData.tickCount)
  self:SetSportFreeInfo()
end

function SportChallengePage:_InitNpcAssist()
  npcAssistFleetMgr:Clear()
  self.assistShipIds = npcAssistFleetMgr:CreateNpcShips4UI(self.copyId)
  self.hasNpcAssist = npcAssistFleetMgr:CheckNpcAssist(self.copyId)
  npcAssistFleetMgr:SetNpcAssist(self.hasNpcAssist)
  if self.hasNpcAssist then
    self.m_tabFleetData = clone(self.m_tabFleetData)
    for index = 1, #self.m_tabFleetData do
      local assistShipIds = clone(self.assistShipIds)
      self.m_tabFleetData[index].heroInfo = npcAssistFleetMgr:ReplaceFirstFleet(self.m_tabFleetData[index].heroInfo, assistShipIds, self.copyId)
    end
  end
end

function SportChallengePage:_CacheDataRet(cacheId)
  local chapter = Logic.copyLogic:GetChapterByCopyId(self.copyId)
  Service.copyService:SendStartBase(chapter.id, self.copyId, false, 1, cacheId, -1, nil, self.battleMode)
end

function SportChallengePage:SetSportFinishTxt()
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.periodId)
  local day, hour, min = time.getDHMDiff(endTime)
  local part = self.m_tabWidgets.part_info:GetLuaTableParts()
  UIHelper.SetText(part.txt_Ttime, day .. UIHelper.GetString(920000021) .. hour .. UIHelper.GetString(920000031) .. min .. UIHelper.GetString(920000032))
end

function SportChallengePage:InitFleetInfo()
  self.assistShipIds = npcAssistFleetMgr:CreateNpcShips4UI(self.copyId)
  self.hasNpcAssist = npcAssistFleetMgr:CheckNpcAssist(self.copyId)
  npcAssistFleetMgr:SetNpcAssist(self.hasNpcAssist)
  local data = Data.fleetData:GetFleetData(FleetType.Normal)
  self.m_tabFleetData = clone(data)
  local nShip = 1
  if self:_SetSelectFleetTip() ~= nil then
    nShip = self:_SetSelectFleetTip()
  else
    logError("\230\178\161\230\156\137\232\139\177\233\155\132\239\188\129")
    return
  end
  local fleetData = clone(self.m_tabFleetData[nShip])
  fleetData.heroInfo = Logic.fleetLogic:CheckFleetHeroNum(self.copyId, fleetData.heroInfo, false)
  npcAssistFleetMgr:SetUIShipIds(self.assistShipIds)
  local copyDisplay = configManager.GetDataById("config_copy_display", self.copyId)
  if self.hasNpcAssist then
    self.m_tabFleetData[1].heroInfo = self.assistShipIds
    npcAssistFleetMgr:SetNpcFleetData(self.m_tabFleetData)
  end
end

function SportChallengePage:_SetSelectFleetTip()
  local nShip = Logic.fleetLogic:GetSelectTog()
  local heroInfo = self.m_tabFleetData[nShip]
  for index = nShip, #self.m_tabFleetData do
    if #self.m_tabFleetData[index].heroInfo > 0 then
      return index
    end
  end
  for index = 1, nShip do
    if #self.m_tabFleetData[index].heroInfo > 0 then
      return index
    end
  end
  return nil
end

function SportChallengePage:CopyEnter(ret)
  local userData = Data.userData:GetUserData()
  if ret.Rid == nil then
    noticeManager:ShowMsgBox(UIHelper.GetString(920000185))
    return
  end
  self.param.tabSerData = Logic.copyLogic:MakeDefaultCopyInfo(self.copyId)
  local safeLv = self.m_safeStageId == 0 and 0 or self.param.tabSerData.SfLv
  local safePoint = self.m_safeStageId == 0 and 0 or self.param.tabSerData.SfPoint
  Logic.copyLogic:SetAttackCopyInfo(self.copyId, false, safeLv, safePoint)
  local isStrat = {}
  local SetConditions = {
    1,
    2,
    3,
    4
  }
  local SetQucikConditions = {}
  SetQucikConditions, isStrat = Logic.setLogic:GenSetCondition(self.copyId, safeLv)
  Logic.setLogic:SetQuickChallenge(isStrat)
  Logic.copyLogic:SetUserEnterBattle(true)
  Logic.copyLogic:SetEnterLevelInfo(false)
  homeEnvManager:EnterBattle()
end

function SportChallengePage:ShowCopyDetailsInfo()
  local sportCopyData = Data.sportMeetData:GetMySportRankData()
  local copydisplay = configManager.GetDataById("config_copy_display", self.copyId)
  local part = self.m_tabWidgets.part_info:GetLuaTableParts()
  self.copyImgArr = configManager.GetDataById("config_parameter", 501).arrValue
  local index = self.copyId % 10
  if index == 1 then
    index = 3
  elseif index == 3 then
    index = 1
  end
  local imgstr = self.copyImgArr[index]
  UIHelper.SetImage(part.img_bg, imgstr)
  local sportData = sportCopyData and sportCopyData[self.copyId] or nil
  UIHelper.SetText(part.txt_des, copydisplay.description)
  local tabDropInfo = Logic.copyLogic:GetDropInfo()
  self.tabSerData = Data.copyData:GetCopyInfoById(self.copyId)
  local data = sportData
  local rankStr = data and data.data.RankNo or 0
  if rankStr == 0 then
    rankStr = "\227\129\170\227\129\151"
  end
  local scoreStr = data and (data.data.FastestTime or data.data.HighestScore) or 0
  if scoreStr == 0 then
    scoreStr = "\227\129\170\227\129\151"
  else
    scoreStr = scoreStr .. Data.sportMeetData:GetSportMeetScoreTimeString(self.copyId)
  end
  UIHelper.SetText(part.text_RankNum, rankStr)
  UIHelper.SetText(part.text_ScoreNum, scoreStr)
  local dropIds = copydisplay.drop_info_id
  local DropInfoType = {firstPassReward = 3}
  for i, v in ipairs(dropIds) do
    if tabDropInfo[v].type == DropInfoType.firstPassReward and self.tabSerData and self.tabSerData.FirstPassTime ~= 0 then
      table.remove(dropIds, i)
      break
    end
  end
  dropIds = Logic.copyLogic:FilterDropId(dropIds)
  local dropInfo = DropRewardsHelper.GetDropDisplay(dropIds)
  self:CreateDropItem(part, dropIds, dropInfo)
end

function SportChallengePage:CreateDropItem(part, dropIds, dropInfo)
  UIHelper.CreateSubPart(part.item_reward, part.con_drop, #dropInfo, function(nIndex, nPart)
    local displayInfo = dropInfo[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(nPart.Image, displayInfo.icon)
    UIHelper.SetImage(nPart.bg_pinzhidi, QualityIcon[displayInfo.quality])
    UIHelper.SetText(nPart.tx_dropRate, itemInfo.drop_rate)
    UGUIEventListener.AddButtonOnClick(nPart.btn_dropitem, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, dropIds)
    end)
  end)
end

function SportChallengePage:SetSportFreeInfo()
  local sportMeetData = Data.sportMeetData:GetSportTickCount()
  if sportMeetData == nil then
    logError("sportMeet data is nil")
    return
  end
  local isOpenTimer = false
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.periodId)
  local periodconfig = configManager.GetDataById("config_period", self.periodId)
  local now = time.getSvrTime()
  local startY = time.formatTimerToY(now)
  local startM = time.formatTimerToM(now)
  local startD = Mathf.Floor(time.formatTimerToD(now) + 1)
  if string.len(startM) < 2 then
    startM = "0" .. startM
  end
  if string.len(startD) < 2 then
    startD = "0" .. startD
  end
  local refreshSTr = startY .. startM .. startD .. "00" .. "00" .. "00"
  local refreshTime = Mathf.Floor(time.getIntervalByString(refreshSTr))
  if sportMeetData.tickCount <= 0 then
    isOpenTimer = true
  end
  local data = sportMeetData.freeList[self.copyId]
  self.m_tabWidgets.obj_freeTips:SetActive(data and 0 < data.FreeCount)
  self.m_tabWidgets.obj_ticket:SetActive(data and 0 >= data.FreeCount)
  local str = data and 0 < data.FreeCount and " " or "-1"
  local color = txtColor[1]
  self.m_tabWidgets.txt_costNum.color = Color.New(1, 1, 1, 1)
  if sportMeetData.tickCount <= 0 and data and 0 >= data.FreeCount then
    color = txtColor[2]
    self.m_tabWidgets.txt_costNum.color = Color.New(1.0, 0 / 255, 0 / 255, 1)
  end
  UIHelper.SetText(self.m_tabWidgets.txt_costNum, str)
  local day = math.floor(time.getSvrTime() / 86400)
  self.copyTimer = self:CreateTimer(function()
    local str = self:GetTimeStr(refreshTime)
    UIHelper.SetText(self.m_tabWidgets.txt_ticketTime, str)
    self:SetSportFinishTxt()
  end, 1, -1, false)
  self:StartTimer(self.copyTimer)
  UIHelper.SetText(self.m_tabWidgets.txt_num, sportMeetData.tickCount)
  self.m_tabWidgets.obj_ticketTime:SetActive(sportMeetData.tickCount <= 0)
end

function SportChallengePage:GetTimeStr(endTime)
  local nowTime = time.getSvrTime()
  local diff = endTime - nowTime
  if diff < 0 then
    diff = diff * -1
  end
  local temp = diff % 86400
  local hour = math.floor(temp / 3600)
  local min = math.floor(temp / 60 % 60)
  local second = temp % 60
  return hour .. ":" .. min .. ":" .. second
end

function SportChallengePage:GetTaskListByType(taskType, activityId)
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
  return Logic.taskLogic:SortTask(tabResult)
end

function SportChallengePage:ShowChallengeInfo()
  self.sportAchieveData = self:LoadSportAchieveDataByCopyId(self.copyId)
  local tabTaskInfo = self:GetTaskListByType(taskType)
  if tabTaskInfo == nil then
    return
  end
  local copyAchieveInfo = {}
  for i, v in ipairs(tabTaskInfo) do
    if v.Config and v.Config.copy_id == self.copyId then
      table.insert(copyAchieveInfo, v)
    end
  end
  table.sort(copyAchieveInfo, function(l, r)
    return l.Config.id < r.Config.id
  end)
  UIHelper.CreateSubPart(self.m_tabWidgets.item_achieve, self.m_tabWidgets.trs_content, #copyAchieveInfo, function(index, part)
    local achieveInfo = copyAchieveInfo[index]
    UIHelper.SetText(part.txt_name, achieveInfo.Config.desc)
    if achieveInfo.State == TaskState.TODO then
      achieveInfo.ProgressStr = achieveInfo.Data.Count > achieveInfo.Config.goal[3] and achieveInfo.Config.goal[3] or achieveInfo.Data.Count .. "/" .. achieveInfo.Config.goal[3]
      UIHelper.SetText(part.txt_progress, achieveInfo.ProgressStr)
    elseif achieveInfo.State == TaskState.FINISH then
      UIHelper.SetText(part.txt_progress, achieveInfo.ProgressStr)
    elseif achieveInfo.State == TaskState.RECEIVED then
      UIHelper.SetText(part.txt_progress, achieveInfo.ProgressStr)
    end
    part.Btn_Empty.gameObject:SetActive(achieveInfo.State == TaskState.TODO)
    part.Btn_GetReward.gameObject:SetActive(achieveInfo.State == TaskState.FINISH)
    part.Btn_CheckReward.gameObject:SetActive(achieveInfo.State == TaskState.RECEIVED)
    local rewardCfg = configManager.GetDataById("config_rewards", achieveInfo.Config.reward)
    local rewards = Logic.rewardLogic:FormatReward(rewardCfg.rewards)
    
    local function back()
      Service.taskService:SendTaskReward(achieveInfo.TaskId, achieveInfo.Data.Type)
    end
    
    UGUIEventListener.AddButtonOnClick(part.Btn_Empty, function()
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.UnReceivable,
        rewards = rewards
      })
    end, self)
    UGUIEventListener.AddButtonOnClick(part.Btn_CheckReward, function()
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.Received,
        rewards = rewards
      })
    end, self)
    UGUIEventListener.AddButtonOnClick(part.Btn_GetReward, function()
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.Receivable,
        rewards = rewards,
        callback = back
      })
    end, self)
  end)
end

function SportChallengePage:LoadSportAchieveDataByCopyId(copyid)
  return configManager.GetMultiDataByKey("config_sportsmeet_achieve", "copy_id", copyid)
end

return SportChallengePage
