local ActivityLogic = class("logic.ActivityLogic")

function ActivityLogic:initialize()
  self.index = 0
  self.meritIndex = 0
  self.firstRecharge = false
  self.daysActivity = true
  self.bigActivityIndex = {}
  pushNoticeManager:_BindNotice("supplyInTwelve", function()
    return self:GetPushNoticeParams("supplyInTwelve", 1, 120000)
  end)
  pushNoticeManager:_BindNotice("supplyInEighteen", function()
    return self:GetPushNoticeParams("supplyInEighteen", 2, 180000)
  end)
  self:ResetData()
  self:RegisterAllEvent()
end

function ActivityLogic:ResetData()
  self.m_signerr = 0
end

function ActivityLogic:SignOk()
  return not time.isSameDay(self.m_signerr, time.getSvrTime())
end

function ActivityLogic:_OnSignErr()
  self.m_signerr = time.getSvrTime()
end

function ActivityLogic:SetBigActivityIndex(id, index)
  self.bigActivityIndex[id] = index
end

function ActivityLogic:GetBigActivityIndex(id)
  return self.bigActivityIndex[id]
end

function ActivityLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.SIGN_SigeErr, self._OnSignErr, self)
end

function ActivityLogic:GetSignConfigByMonth(month)
  month = math.tointeger(month)
  return configManager.GetDataById("config_daily_register", month).rewards
end

function ActivityLogic:GetSignConfigByDay(month, day)
  local signConfig = self:GetSignConfigByMonth(month)
  return signConfig[day]
end

function ActivityLogic:IsSignToday()
  local lastSignTime = Data.activityData:GetLastSignTime()
  return time.isSameDay(lastSignTime, time.getSvrTime())
end

function ActivityLogic:IsLoginActivityCanReward(activityId)
  local activityConfig = configManager.GetDataById("config_activity", activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    return false
  end
  local configAll = Logic.activityLogic:GetDailyTask(activityId)
  for _, config in ipairs(configAll) do
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function ActivityLogic:GetLoginActivityCanReward()
  local activityData = Logic.activityLogic:GetOpenActivityByTypes(ActivityType.DailyLogin)
  for _, config in ipairs(activityData) do
    if self:IsLoginActivityCanReward(config.id) and config.id ~= Activity.DailyLogin_14 and config.id ~= Activity.DailyLogin_xiamo and config.id ~= Activity.DailyLogin_school then
      return config.id
    end
  end
  return 0
end

function ActivityLogic:GetRewardIcon(index, id)
  return Logic.goodsLogic:GetIcon(id, index)
end

function ActivityLogic:GetRewardQuality(index, id)
  return Logic.goodsLogic:GetQuality(id, index)
end

function ActivityLogic:GetRewardName(index, id)
  local config = configManager.GetDataById("config_table_index", index).file_name
  return configManager.GetDataById(config, id).name
end

function ActivityLogic:GetRewardInfo(index, id)
  local config = configManager.GetDataById("config_table_index", index).file_name
  return configManager.GetDataById(config, id)
end

function ActivityLogic:SetToggleIndex(index)
  self.index = index
end

function ActivityLogic:GetToggleIndex()
  return self.index
end

function ActivityLogic:GetActPlotChapter(actId)
  local chapterType = configManager.GetDataById("config_activity", actId).plot_type
  local chapterId = Logic.copyLogic:GetInitChapterIdByType(chapterType)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return chapterConfig
end

function ActivityLogic:GetActSeaChapter(actId)
  local chapterType = configManager.GetDataById("config_activity", actId).seacopy_type
  return Logic.copyLogic:GetInitChapterIdByType(chapterType)
end

function ActivityLogic:GetTopItem(actId)
  local itemInfo = configManager.GetDataById("config_activity", actId).p4
  return itemInfo
end

function ActivityLogic:GetActShopId(actId)
  local shopId = configManager.GetDataById("config_activity", actId).p6
  return shopId[1]
end

function ActivityLogic:GetActReddotId(actId)
  local redDotTab = configManager.GetDataById("config_activity", actId).red_dot
  return redDotTab
end

function ActivityLogic:GetOpenActivityByTypes(...)
  local result = {}
  local typs = {
    ...
  }
  local typMap = {}
  for index, typ in ipairs(typs) do
    typMap[typ] = true
  end
  local activityData = Data.activityData:GetActivityData()
  for activityId, state in pairs(activityData) do
    if state then
      local config = configManager.GetDataById("config_activity", activityId)
      if config and typMap[config.type] == true then
        if config.period <= 0 then
          table.insert(result, config)
        elseif config.period > 0 and PeriodManager:IsInPeriodArea(config.period, config.period_area) then
          table.insert(result, config)
        end
      end
    end
  end
  return result
end

function ActivityLogic:GetOpenActivityByShowType(showType)
  local activityData = Data.activityData:GetActivityData()
  local result = {}
  for activityId, state in pairs(activityData) do
    if state then
      local config = configManager.GetDataById("config_activity", activityId)
      if config.show_type == showType then
        if config.period <= 0 then
          table.insert(result, config)
        elseif config.period > 0 and PeriodManager:IsInPeriodArea(config.period, config.period_area) then
          table.insert(result, config)
        end
      end
    end
  end
  return result
end

function ActivityLogic:GetOpenActivityByType(typ)
  local activityData = Data.activityData:GetActivityData()
  local result = {}
  for activityId, state in pairs(activityData) do
    if state then
      local config = configManager.GetDataById("config_activity", activityId)
      if config.type == typ then
        if config.period <= 0 then
          table.insert(result, config)
        elseif config.period > 0 and PeriodManager:IsInPeriodArea(config.period, config.period_area) then
          table.insert(result, config)
        end
      end
    end
  end
  return result
end

function ActivityLogic:CheckOpenActivityByType(typ)
  local activityData = Data.activityData:GetActivityData()
  for activityId, state in pairs(activityData) do
    if state then
      local config = configManager.GetDataById("config_activity", activityId)
      if config and config.type == typ and self:CheckActivityOpenById(activityId) then
        return true
      end
    end
  end
  return false
end

function ActivityLogic:GetMeritTogLastIndex()
  return self.meritIndex
end

function ActivityLogic:SetMeritTogLastIndex(index)
  self.meritIndex = index
end

function ActivityLogic:GetActivityBanner()
  local config = configManager.GetData("config_activity")
  local appReview = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW
  local showBanner = {}
  for _, v in pairs(config) do
    if v.banner_order > 0 and self:CheckActivityOpenById(v.id) and self:CheckActivityShowFunction(v.id) then
      if appReview then
        if v.id ~= Activity.FirstRecharge then
          table.insert(showBanner, v)
        end
      else
        table.insert(showBanner, v)
      end
    end
  end
  table.sort(showBanner, function(data1, data2)
    return data1.banner_order < data2.banner_order
  end)
  return showBanner
end

function ActivityLogic:CheckOpenCommon(activityId)
  return true
end

function ActivityLogic:IsOpenGiftActivity()
  return BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW
end

function ActivityLogic:IsOpenDailyLogin()
  local activityData = configManager.GetData("config_activity")
  for _, k in pairs(activityData) do
    if k.type == ActivityType.DailyLogin and Logic.activityLogic:IsOpenDailyLoginById(k.id) then
      return true
    end
  end
  return false
end

function ActivityLogic:IsOpenDailyLoginById(activityId)
  local activityConfig = configManager.GetDataById("config_activity", activityId)
  if activityConfig.period > 0 then
    return PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area)
  end
  local configAll = Logic.activityLogic:GetDailyTask(activityId)
  for index, config in pairs(configAll) do
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status ~= TaskState.RECEIVED then
      return true
    end
  end
  return false
end

function ActivityLogic:IsOpenDaysActivity()
  local isOpen = true
  local num = configManager.GetData("config_days_activity")
  local achieveData = Data.taskData:GetAchieveData()
  for i = 1, #num do
    local args = configManager.GetDataById("config_days_activity", i)
    local logintabReward = {}
    table.insert(logintabReward, args.login_achievements)
    local tabAchieveLogin = Logic.achieveLogic:GetAchieveByDays(logintabReward, achieveData)
    if tabAchieveLogin[1].status ~= TaskState.RECEIVED then
      isOpen = true
      break
    else
      isOpen = false
    end
    local tabAchieve = Logic.achieveLogic:GetAchieveByDays(num[i].achievements, achieveData)
    for n = 1, #tabAchieve do
      if tabAchieve[n].status ~= TaskState.RECEIVED then
        isOpen = true
        break
      else
        isOpen = false
      end
    end
    if isOpen == true then
      break
    end
  end
  return isOpen
end

function ActivityLogic:IsOpenBigActivity()
  local activityData = configManager.GetData("config_activity")
  for _, k in pairs(activityData) do
    if (k.type == ActivityType.Festival or k.type == ActivityType.BigActivity) and Logic.activityLogic:CheckActivityOpenById(k.id) then
      return true
    end
  end
  return false
end

function ActivityLogic:GetOpenBigActivity()
  local openID
  local activityData = configManager.GetData("config_activity")
  for _, k in pairs(activityData) do
    if (k.type == ActivityType.Festival or k.type == ActivityType.BigActivity) and Logic.activityLogic:CheckActivityOpenById(k.id) then
      openID = k.id
      break
    end
  end
  return openID
end

function ActivityLogic:GetFirstRechargeState()
  local activityConfig = configManager.GetDataById("config_activity", Activity.FirstRecharge)
  local achieveId = activityConfig.p1[1]
  return Logic.taskLogic:GetTaskFinishState(achieveId, TaskType.Achieve)
end

function ActivityLogic:IsOpenFirstRecharge()
  local activityConfig = configManager.GetDataById("config_activity", Activity.FirstRecharge)
  if activityConfig.is_open ~= 1 then
    return false
  end
  local status = Logic.activityLogic:GetFirstRechargeState()
  return status ~= TaskState.RECEIVED
end

function ActivityLogic:IsOpenCumuActivity(activityId)
  return Logic.achieveLogic:IsCumuActivityNotFinish(activityId)
end

function ActivityLogic:IsOpenCumuRecharge(activityId)
  local activityConfig = configManager.GetDataById("config_activity", activityId)
  if activityConfig.is_open ~= 1 then
    return false
  end
  for i, pid in ipairs(activityConfig.period_list) do
    if PeriodManager:IsInPeriod(pid) then
      return true
    end
  end
  return false
end

function ActivityLogic:IsCanShowRedDot(...)
  local userInfo = Data.userData:GetUserData()
  local curDay = userInfo.NewTaskStage
  local num = configManager.GetData("config_days_activity")
  local achieveData = Data.taskData:GetAchieveData()
  if curDay > #num then
    curDay = #num
  end
  for i = 1, curDay do
    local args = configManager.GetDataById("config_days_activity", i)
    local logintabReward = {}
    table.insert(logintabReward, args.login_achievements)
    local tabAchieveLogin = Logic.achieveLogic:GetAchieveByDays(logintabReward, achieveData)
    if tabAchieveLogin[1].status == TaskState.FINISH then
      return true
    end
    local tabAchieve = Logic.achieveLogic:GetAchieveByDays(num[i].achievements, achieveData)
    for n = 1, #tabAchieve do
      if tabAchieve[n].status == TaskState.FINISH then
        return true
      end
    end
  end
  local firstLoginToday = Data.userData:IsFirstLoginToday()
  return self.daysActivity and firstLoginToday
end

function ActivityLogic:IsHaveDaysRedDot(index)
  local userInfo = Data.userData:GetUserData()
  local num = configManager.GetData("config_days_activity")
  local achieveData = Data.taskData:GetAchieveData()
  local curDay = userInfo.NewTaskStage
  if index > curDay then
    return false
  end
  local args = configManager.GetDataById("config_days_activity", index)
  local logintabReward = {}
  table.insert(logintabReward, args.login_achievements)
  local tabAchieveLogin = Logic.achieveLogic:GetAchieveByDays(logintabReward, achieveData)
  if tabAchieveLogin[1].status == TaskState.FINISH then
    return true
  end
  local tabAchieve = Logic.achieveLogic:GetAchieveByDays(num[index].achievements, achieveData)
  for n = 1, #tabAchieve do
    if tabAchieve[n].status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function ActivityLogic:IsHaveTimeTaskDaysRedDot(index)
  local userInfo = Data.userData:GetUserData()
  local num = configManager.GetData("config_days_activity_limited")
  local achieveData = Data.taskData:GetTaskDataByType(TaskType.Activity)
  local curDay, isOpen = Logic.taskLogic:GetCurentDay()
  if index > curDay or not isOpen then
    return false
  end
  local args = configManager.GetDataById("config_days_activity_limited", index)
  local logintabReward = {}
  table.insert(logintabReward, args.task_stage)
  local tabAchieveLogin = Logic.achieveLogic:GetTimeTaskByDays(logintabReward, achieveData)
  if tabAchieveLogin and tabAchieveLogin[1] and tabAchieveLogin[1].status == TaskState.FINISH then
    return true
  end
  local tabAchieve = Logic.achieveLogic:GetTimeTaskByDays(num[index].task_activity, achieveData)
  for n = 1, #tabAchieve do
    if tabAchieve[n].status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function ActivityLogic:SetFirstRecharge(_bool)
  self.firstRecharge = _bool
  eventManager:SendEvent(LuaEvent.RecommendFlag)
end

function ActivityLogic:SetDaysActivity(_bool)
  self.daysActivity = _bool
end

function ActivityLogic:FirstRechargeRedDot(_bool)
  local status = self:GetFirstRechargeState()
  if status == TaskState.FINISH then
    return true
  end
  if self.firstRecharge == true then
    return false
  end
  return self:IsOpenFirstRecharge()
end

function ActivityLogic:GetActivityIdsByType(typ)
  local result = {}
  local configAll = configManager.GetData("config_activity")
  for activityId, config in pairs(configAll) do
    if config.type == typ then
      table.insert(result, activityId)
    end
  end
  return result
end

function ActivityLogic:GetActivityIdByType(typ)
  local activityIds = self:GetActivityIdsByType(typ)
  for index, activityId in pairs(activityIds) do
    if self:CheckActivityOpenById(activityId) then
      return activityId
    end
  end
  return nil
end

function ActivityLogic:CheckActivityOpenById(id)
  local config = configManager.GetDataById("config_activity", id)
  local typ = config.type
  if config.is_open == 0 then
    return false
  end
  if typ == ActivityType.NewPlayer then
    return self:IsOpenDaysActivity(id)
  elseif typ == ActivityType.FirstRecharge then
    return self:IsOpenFirstRecharge(id)
  elseif typ == ActivityType.CumuCost or typ == ActivityType.SingleRecharge then
    return self:IsOpenCumuActivity(id)
  elseif typ == ActivityType.CumuRecharge then
    return self:IsOpenCumuRecharge(id)
  elseif typ == ActivityType.Gift then
    return self:IsOpenGiftActivity(id)
  elseif typ == ActivityType.DailyLogin then
    return self:IsOpenDailyLoginById(id)
  elseif typ == ActivityType.TimeLimitBuild then
    return self:IsOpenTimeLimitBuild(id)
  elseif typ == ActivityType.ActivitySSR then
    return self:IsOpenActivitySSR(id)
  elseif typ == ActivityType.FurnitureDecoration then
    return self:IsOpenActivityFurnitureDecoration(id)
  elseif typ == ActivityType.JChildSign then
    return self:IsOpenActivityJChildSign(id)
  elseif typ == ActivityType.HolidayReward then
    return self:IsOpenHolidayReward(id)
  elseif typ == ActivityType.JOpen then
    return self:CheckJOpen(id)
  elseif typ == ActivityType.ReturnPlayer then
    return self:IsOpenActivityReturnPlayer(id)
  elseif typ == ActivityType.BattlePass then
    return self:IsOpenActivityBattlePass(id)
  elseif typ == ActivityType.BattlePassActivity then
    return self:IsOpenActivityBattlePassActivity(id)
  elseif typ == ActivityType.TimeTaskActivity then
    return self:IsOpenTimeActivity(id)
  elseif typ == ActivityType.GuildWarAct then
    return self:IsOpenGuildWarActivity(id)
  else
    return self:CheckActivityOpenByIdDefault(id)
  end
end

function ActivityLogic:IsOpenGuildWarActivity(id)
  local activityConfig = configManager.GetDataById("config_activity", id)
  local period_config = configManager.GetDataById("config_period", activityConfig.period)
  local now = time.getSvrTime()
  local startTime, _ = PeriodManager:GetStartAndEndPeriodTime(activityConfig.period)
  local endTime = startTime + period_config.duration_list[1]
  if now >= startTime and now <= endTime then
    return true
  end
  return false
end

function ActivityLogic:IsOpenTimeActivity(id)
  local activityConfig = configManager.GetDataById("config_activity", id)
  local period_config = configManager.GetDataById("config_period", activityConfig.period)
  local now = time.getSvrTime()
  local startTime, _ = PeriodManager:GetStartAndEndPeriodTime(activityConfig.period)
  local endTime = startTime + period_config.duration
  if now >= startTime and now <= endTime then
    return true
  end
  return false
end

function ActivityLogic:CheckJOpen(id)
  local activityConfig = configManager.GetDataById("config_activity", id)
  local fetchHeroTime = Data.jOpenData:GetFetchHeroTime()
  if 0 < fetchHeroTime and 0 > fetchHeroTime + activityConfig.p8[1] - time.getSvrTime() then
    return false
  end
  return true
end

function ActivityLogic:IsOpenActivityBattlePass(id)
  local curBattlePassIndex = Data.battlepassData:GetCurWeekIndex()
  if curBattlePassIndex <= 0 then
    return false
  end
  return self:CheckActivityOpenByIdDefault(id)
end

function ActivityLogic:IsOpenActivityBattlePassActivity(id)
  local curBattlePassIndex = Data.battlepassactivityData:GetCurWeekIndex()
  if curBattlePassIndex <= 0 then
    return false
  end
  return self:CheckActivityOpenByIdDefault(id)
end

function ActivityLogic:CheckActivityOpenByIdDefault(id)
  local activityConfig = configManager.GetDataById("config_activity", id)
  if activityConfig.period > 0 then
    return PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area)
  end
  return true
end

function ActivityLogic:CheckActivityShowFunction(id)
  local v = configManager.GetDataById("config_activity", id)
  if v.show_function <= 0 or v.show_function > 0 and moduleManager:CheckFunc(v.show_function, false) then
    return true
  end
  return false
end

function ActivityLogic:GetActivityShow(showType)
  showType = showType or 0
  local configAll = configManager.GetData("config_activity")
  local result = {}
  for id, v in pairs(configAll) do
    if v.is_open == 1 and v.banner_gotopage_activity ~= "" and self:CheckActivityOpenById(id) and showType == v.show_type and self:CheckActivityShowFunction(id) then
      table.insert(result, v)
    end
  end
  table.sort(result, function(a, b)
    return a.order < b.order
  end)
  return result
end

function ActivityLogic:IsOpenTimeLimitBuild(actId)
  local activityConfig = configManager.GetDataById("config_activity", actId)
  local config = configManager.GetDataById("config_extract_ship", activityConfig.p1[1])
  if Logic.buildShipLogic:CheckActIsOpen(config.id) and Logic.buildShipLogic:CheckServerOpenDay(config.id) and Logic.buildShipLogic:CheckOtherLimit(config) then
    return true
  end
  return false
end

function ActivityLogic:GetActivityStartEndTime(actId)
  local activityConfig = configManager.GetDataById("config_activity", actId)
  return PeriodManager:GetPeriodTime(activityConfig.period, activityConfig.period_area)
end

function ActivityLogic:GetDailyTask(activityId)
  local result = {}
  local configAll = configManager.GetData("config_daily_login")
  for index, config in pairs(configAll) do
    if config.activity_id == activityId then
      table.insert(result, config)
    end
  end
  table.sort(result, function(a, b)
    return a.id < b.id
  end)
  return result
end

function ActivityLogic:GetPushNoticeParams(key, strId, strTime)
  local noticeTable = {}
  local paramList = {}
  noticeTable.key = key
  noticeTable.text = configManager.GetDataById("config_pushnotice", strId).text
  noticeTable.time = time.str2time(strTime, time.getSvrTime())
  noticeTable.repeatTime = LocalNotificationInterval.Day
  paramList.supplyInTwelve = noticeTable
  return paramList
end

function ActivityLogic:IsOpenActivitySSR(id)
  local isOpen = Data.activityData:IsActivityOpen(id)
  return isOpen
end

function ActivityLogic:IsOpenActivityFurnitureDecoration(id)
  local isOpen = Data.activityData:IsActivityOpen(id)
  return isOpen
end

function ActivityLogic:IsOpenActivityJChildSign(id)
  local isOpen = Data.activityData:IsActivityOpen(id)
  return isOpen
end

function ActivityLogic:IsOpenActivityReturnPlayer(id)
  local activityData = configManager.GetDataById("config_activity", id)
  local levelLimit = Data.userData:GetLevel() >= activityData.p2[1]
  local actOpenTime = Data.userData:GetUserData().LastActivityReturnTime or 0
  local duration = 86400 * activityData.p7[1]
  local overTime = actOpenTime + duration
  local isOpen = overTime >= time.getSvrTime() and levelLimit
  return isOpen
end

function ActivityLogic:IsOpenHolidayReward(id)
  return Data.activityData:IsActivityOpen(id)
end

function ActivityLogic:GetSignEffName()
  local isOpen = Data.activityData:IsActivityOpen(Activity.NewYearSign)
  if not isOpen then
    return
  end
  local effNameTab = configManager.GetDataById("config_activity", Activity.NewYearSign).p1
  if #effNameTab == 0 then
    return
  end
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, Activity.NewYearSign)
  for _, v in ipairs(arrTask) do
    local isSame = time.isSameDay(v.Data.RewardTime, time.getSvrTime())
    if 0 < v.Data.RewardTime and isSame then
      local dropTab = configManager.GetDataById("config_drop_item", v.Config.drop_id).drop
      local index = self:GetRewardsIndex(v.Data.Reward, dropTab)
      return effNameTab[index]
    end
  end
  return
end

function ActivityLogic:CheckNewYearSign(activityId)
  local isOpen = Data.activityData:IsActivityOpen(activityId)
  if not isOpen then
    return false
  end
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, activityId)
  for _, v in ipairs(arrTask) do
    local status = Logic.taskLogic:GetTaskFinishState(v.Data.TaskId, v.Data.Type)
    if status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function ActivityLogic:GetRewardsIndex(gotRewards, dropTab)
  for i, v in ipairs(dropTab) do
    local rewards = Logic.rewardLogic:GetAllShowRewardByDropId(v[2])
    local sameRecord = 0
    for _, k in ipairs(rewards) do
      for _, y in ipairs(gotRewards) do
        if k.ConfigId == y.ConfigId and k.Type == y.Type and k.Num == y.Num then
          sameRecord = sameRecord + 1
        end
      end
      if sameRecord == #gotRewards then
        return i
      end
    end
  end
  return 1
end

function ActivityLogic:IsShowInSimpleMode(actId)
  local config = configManager.GetDataById("config_activity", actId)
  return config and config.popup_tag_show == 1 or false
end

function ActivityLogic:SetGirlImgPosition(imgGirl, shipshowCfg)
  local shipPosConf = configManager.GetDataById("config_ship_position", shipshowCfg.ss_id)
  local position = shipPosConf.ship_position1
  imgGirl.transform.localPosition = Vector3.New(position[1], position[2], 0)
  local scaleSize = shipPosConf.ship_scale1 / 10000
  local mirror = shipPosConf.ship_inversion1
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  imgGirl.transform.localScale = scale
end

function ActivityLogic:CheckJOpenTaskReceive()
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, Activity.JOpen)
  for i, v in pairs(tabTaskInfo) do
    if v.State ~= TaskState.RECEIVED then
      return false
    end
  end
  return true
end

function ActivityLogic:CumuRechargeClickCount(itemId)
  self.count = self.count or 1
  self.lastTime = self.lastTime or 0
  local targetCount = configManager.GetDataById("config_parameter", 344).value
  local interval = configManager.GetDataById("config_parameter", 343).value
  interval = interval + 500
  interval = interval / 1000
  local nowTime = time.getSvrTime()
  if interval >= nowTime - self.lastTime then
    self.count = self.count + 1
  else
    self.count = 1
  end
  self.lastTime = nowTime
  if targetCount <= self.count then
    self.count = 0
    self.lastTime = 0
    self:CumuRechargeClickShowTip(itemId)
    return true
  end
  return false
end

function ActivityLogic:CumuRechargeClickShowTip(itemId)
  local idParamIds = {
    345,
    346,
    347,
    348,
    349,
    350,
    351,
    352,
    353,
    354
  }
  local tips = {
    431000,
    431001,
    431002,
    431003,
    431004,
    431005,
    431006,
    431007,
    431008,
    431009
  }
  for i, paramId in ipairs(idParamIds) do
    local cfg = configManager.GetDataById("config_parameter", paramId)
    if cfg ~= nil and cfg.arrValue[2] == itemId then
      noticeManager:ShowTip(UIHelper.GetString(tips[i]))
    end
  end
end

function ActivityLogic:CheckAnniversaryMemoryReward(actId)
  local isOpen = Data.activityData:IsActivityOpen(actId)
  if not isOpen then
    return false
  end
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, actId)
  if next(arrTask) == nil then
    return false
  end
  local taskInfo = arrTask[1]
  if taskInfo.State ~= TaskState.RECEIVED then
    return true
  end
  return false
end

return ActivityLogic
