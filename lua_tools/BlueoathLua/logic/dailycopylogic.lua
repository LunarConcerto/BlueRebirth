local DailyCopyLogic = class("logic.DailyCopyLogic")

function DailyCopyLogic:initialize()
end

function DailyCopyLogic:ResetData()
  self:SetDailyCopyTime(time.getSvrTime())
  self.dailyCopyInfo = nil
  self.dailyGroupId = nil
  self.BuildShipId = nil
  self.BuildShipReward = nil
end

function DailyCopyLogic:GetBuildShipInfo()
  return self.BuildShipId, self.BuildShipReward
end

function DailyCopyLogic:SetBuildShipInfo(info)
  if info and info.BuildShipId and info.BuildShipId > 0 then
    self.BuildShipId = info.BuildShipId
    self.BuildShipReward = info.BuildShipReward
  end
end

function DailyCopyLogic:ResetBuildShipInfo()
  self.BuildShipId = nil
  self.BuildShipReward = nil
end

function DailyCopyLogic:SetDCBattleInfo(copyInfo, dailyGroupId)
  self.dailyCopyInfo = copyInfo
  self.dailyGroupId = dailyGroupId
end

function DailyCopyLogic:GetDCBattleInfo()
  return self.dailyCopyInfo, self.dailyGroupId
end

function DailyCopyLogic:SetDailyCopyTime(time)
  self.lastTime = time
end

function DailyCopyLogic:GetDailyCopyTime()
  return self.lastTime
end

function DailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo)
  local totalTimes = self:GetRewardTotalTimes(dailyGroupInfo)
  local challengeTimes = Data.dailyCopyData:GetSuccessTimesById(dailyGroupInfo.id)
  return math.tointeger(totalTimes - challengeTimes) <= 0 and 0 or math.tointeger(totalTimes - challengeTimes)
end

function DailyCopyLogic:GetRewardTotalTimes(dailyGroupInfo)
  local activityDatas = Logic.activityLogic:GetOpenActivityByType(ActivityType.Extra)
  local totalTimes = 0
  if 0 < #activityDatas then
    for k, activityData in ipairs(activityDatas) do
      local flag = false
      for i, v in pairs(activityData.p1) do
        if v == dailyGroupInfo.id then
          flag = true
        end
      end
      local isActivity = true
      for i, typ in pairs(activityData.p6) do
        if Logic.activityLogic:CheckOpenActivityByType(typ) then
          isActivity = false
        end
      end
      if flag and isActivity then
        totalTimes = totalTimes + activityData.p2[1]
        if Logic.userLogic:CheckMonthCardPrivilege() then
          totalTimes = totalTimes + activityData.p3[1]
        end
        if Logic.userLogic:CheckBigMonthCardPrivilege() then
          totalTimes = totalTimes + activityData.p3[2]
        end
      end
    end
  end
  return totalTimes
end

function DailyCopyLogic:GetDailyChapterIndex(dailyGroupConfig)
  for index, periodId in pairs(dailyGroupConfig.period) do
    if PeriodManager:IsInPeriods(periodId) then
      return index
    end
  end
  logError("dailyGroupInfo no open chapter, check period:%s SvrStartTime:%s SvrTime:%s", dailyGroupConfig.period, time.getSvrStartTime(), time.getSvrTime())
  return 1
end

function DailyCopyLogic:GetDailyChapterInfo(dailyGroupInfo)
  local index = self:GetDailyChapterIndex(dailyGroupInfo)
  local chapterId = dailyGroupInfo.chapterid[index]
  return configManager.GetDataById("config_daily_chapter", chapterId)
end

function DailyCopyLogic:GetPassCopy(chapterId)
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  if dailyCopyData[chapterId] == nil then
    return {}
  end
  return dailyCopyData[chapterId].PassCopy
end

function DailyCopyLogic:IsFirstChallenge(chapterId, level)
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  if dailyCopyData[chapterId] ~= nil then
    for i = 1, #dailyCopyData[chapterId].CopyId do
      if dailyCopyData[chapterId].CopyId[i] == level then
        return false
      end
    end
  end
  return true
end

function DailyCopyLogic:CheckCopyTimes(info)
  local curTime = time.getSvrTime()
  local lastTime = Logic.dailyCopyLogic:GetDailyCopyTime()
  if time.isSameDay(curTime, lastTime) then
    local copyData = Data.dailyCopyData:GetDailyCopyData()
    if copyData ~= nil and copyData[info.id] ~= nil then
      local data = copyData[info.id]
      return data.ChallengeTimes < info.challenge_time
    end
  end
  return true
end

function DailyCopyLogic:CheckDailyCopyPeriod(dailyGroupInfo, isNotice)
  local chapterIndex = Logic.dailyCopyLogic:GetDailyChapterIndex(dailyGroupInfo)
  local result = PeriodManager:IsInPeriods(dailyGroupInfo.is_available[chapterIndex])
  if not result and isNotice then
    noticeManager:ShowTip(dailyGroupInfo.is_available_show[chapterIndex])
  end
  return result
end

function DailyCopyLogic:GetDailyCopyLevelList(dailyChapterId)
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(dailyChapterId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return chapterConfig.level_list
end

function DailyCopyLogic:GetDailyCopyInfo()
  local result = {}
  local config = configManager.GetData("config_chapter")
  for k, v in pairs(config) do
    if v.class_type == ChapterType.DailyCopy then
      local chapterData = Logic.dailyCopyLogic:GetPassCopy(v.id) or {}
      if 0 < #chapterData then
        table.insert(result, v.level_list[#chapterData])
      else
        table.insert(result, 0)
      end
    end
  end
  return result
end

function DailyCopyLogic:GetDropInfo(dailyGroupInfo, nIndex)
  local baseDrop = dailyGroupInfo.drop_info_id[nIndex]
  baseDrop = Logic.copyLogic:FilterDropId(baseDrop)
  local baseDropItemList = DropRewardsHelper.GetDropDisplay(baseDrop)
  local extraDrop = dailyGroupInfo.extra_drop_info_id[nIndex]
  extraDrop = Logic.copyLogic:FilterDropId(extraDrop)
  local extraDropItemList = DropRewardsHelper.GetDropDisplay(extraDrop)
  local dropList = clone(baseDrop)
  local dropItemList = clone(baseDropItemList)
  local rewardTimse = Logic.dailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo)
  if rewardTimse and 0 < rewardTimse then
    for i, v in ipairs(extraDrop) do
      table.insert(dropList, v)
    end
    for i, v in ipairs(extraDropItemList) do
      table.insert(dropItemList, v)
    end
  end
  return dropList, dropItemList, #baseDropItemList
end

function DailyCopyLogic:CheckDailyCopyByIndex(index)
  if index <= 0 then
    return true
  end
  local config = configManager.GetData("config_chapter")
  for k, v in pairs(config) do
    if v.class_type == ChapterType.DailyCopy then
      local chapterData = Logic.dailyCopyLogic:GetPassCopy(v.id) or {}
      if index <= #chapterData then
        return true
      end
    end
  end
  return false
end

return DailyCopyLogic
