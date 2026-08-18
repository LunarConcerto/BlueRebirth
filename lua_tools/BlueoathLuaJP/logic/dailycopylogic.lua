local DailyCopyLogic = class("logic.DailyCopyLogic")

function DailyCopyLogic:initialize()
end

function DailyCopyLogic:ResetData()
  self:SetDailyCopyTime(time.getSvrTime())
  self.dailyCopyInfo = nil
  self.dailyGroupId = nil
  self.BuildShipId = nil
  self.BuildShipReward = nil
  self.SelectBuffInfo = {}
  self.BBattleExStar = -1
  self.BBattleTExStar = 0
  self.RecordExSelectBuff = {}
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
    local activityData = activityDatas[1]
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
      totalTimes = activityData.p2[1]
      if Logic.userLogic:CheckMonthCardPrivilege() then
        totalTimes = totalTimes + activityData.p3[1]
      end
      if Logic.userLogic:CheckBigMonthCardPrivilege() then
        totalTimes = totalTimes + activityData.p3[2]
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

function DailyCopyLogic:CheckOpenTreaty(chapterId)
  local passCopyIdTab = self:GetPassCopy(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  if #passCopyIdTab == 0 then
    return false
  end
  local passCopyMap = {}
  for _, v in ipairs(passCopyIdTab) do
    passCopyMap[v] = v
  end
  for _, id in ipairs(chapterConfig.treaty_open_copy) do
    if passCopyMap[id] == nil then
      return false
    end
  end
  return true
end

function DailyCopyLogic:GetTreatyData(chapterConfig)
  local copyId = chapterConfig.treaty_copy[1]
  local copyConfig = Logic.copyLogic:GetCopyDConfigById(copyId)
  copyConfig.PassEx = self:CheckExCopyPass(chapterConfig.id)
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  local copyInfo = dailyCopyData[chapterConfig.id]
  copyConfig.SelectEx = copyInfo and copyInfo.SelectEx or false
  copyConfig.ExStar = copyInfo and copyInfo.ExStar or 0
  return copyConfig
end

function DailyCopyLogic:GetExBuff(dailyGroupInfo)
  local buffConfig = configManager.GetData("config_treaty_buff")
  local showBuff = {}
  for _, v in ipairs(dailyGroupInfo.treaty_show_buff) do
    table.insert(showBuff, buffConfig[v])
  end
  table.sort(showBuff, function(data1, data2)
    return data1.order < data2.order
  end)
  return showBuff
end

function DailyCopyLogic:CheckExCopyPass(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  local copyId = chapterConfig.treaty_copy[1]
  local passCopyIdTab = self:GetPassCopy(chapterId)
  local passEx = false
  for _, v in ipairs(passCopyIdTab) do
    if v == copyId then
      passEx = true
      break
    end
  end
  return passEx
end

function DailyCopyLogic:GetExDropInfo(dailyGroupInfo, star, isLevel)
  local chapterInfo = self:GetChapterByGroup(dailyGroupInfo)
  local pass = self:CheckExCopyPass(chapterInfo.id)
  local firstPassDrop, firstDropList
  if not pass then
    firstPassDrop = dailyGroupInfo.treaty_dropinfo_pass
    firstDropList = DropRewardsHelper.GetDropDisplay(firstPassDrop)
  end
  star = star + 1 > #dailyGroupInfo.treaty_dropinfo_basic and #dailyGroupInfo.treaty_dropinfo_basic or star + 1
  local baseDrop = dailyGroupInfo.treaty_dropinfo_basic[star]
  local baseDropList = DropRewardsHelper.GetDropDisplay(baseDrop)
  local extraDrop = dailyGroupInfo.treaty_dropinfo_extra[star]
  local extraDropList = DropRewardsHelper.GetDropDisplay(extraDrop)
  local listNum = 0
  local dropList = {}
  local dropItemList = {}
  if firstPassDrop then
    dropList = clone(firstPassDrop)
    dropItemList = clone(firstDropList)
    for i, v in ipairs(baseDrop) do
      table.insert(dropList, v)
    end
    for i, v in ipairs(baseDropList) do
      table.insert(dropItemList, v)
    end
  elseif isLevel then
    dropList = clone(baseDrop)
    dropItemList = clone(baseDropList)
    local rewardTimse = Logic.dailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo)
    if rewardTimse and 0 < rewardTimse then
      for i, v in ipairs(extraDrop) do
        table.insert(dropList, v)
      end
      for i, v in ipairs(extraDropList) do
        table.insert(dropItemList, v)
      end
    end
    listNum = #baseDropList
  else
    local rewardTimse = Logic.dailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo)
    if rewardTimse and 0 < rewardTimse then
      dropList = clone(extraDrop)
      dropItemList = clone(extraDropList)
      for i, v in ipairs(baseDrop) do
        table.insert(dropList, v)
      end
      for i, v in ipairs(baseDropList) do
        table.insert(dropItemList, v)
      end
      listNum = #extraDropList
    else
      dropList = clone(baseDrop)
      dropItemList = clone(baseDropList)
    end
  end
  return dropList, dropItemList, listNum
end

function DailyCopyLogic:SetSelectBuff(param)
  self.SelectBuffInfo = param
end

function DailyCopyLogic:GetSelectBuff()
  return self.SelectBuffInfo
end

function DailyCopyLogic:CheckTreatyBattle(chapterInfo, copyId)
  for i, v in ipairs(chapterInfo.treaty_copy) do
    if copyId == v then
      return true
    end
  end
  return false
end

function DailyCopyLogic:GetChapterByGroup(dailyGroupInfo)
  local copyInfo = Logic.dailyCopyLogic:GetDailyChapterInfo(dailyGroupInfo)
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(copyInfo.id)
  return configManager.GetDataById("config_chapter", chapterId)
end

function DailyCopyLogic:SetBeforeBattleExStar(starNum)
  self.BBattleExStar = starNum
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  self.BBattleTExStar = 0
  for _, v in pairs(dailyCopyData) do
    self.BBattleTExStar = self.BBattleTExStar + v.ExStar
  end
end

function DailyCopyLogic:GetBBattleExStar()
  return self.BBattleExStar, self.BBattleTExStar
end

function DailyCopyLogic:CRShowTreaty(copyId, chapterInfo)
  if chapterInfo.class_type ~= ChapterType.DailyCopy then
    return false
  end
  local isTreaty = chapterInfo.treaty_copy[1] == copyId
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  local copyInfo = dailyCopyData[chapterInfo.id]
  local starChange = self.BBattleExStar < copyInfo.ExStar
  return isTreaty and starChange
end

function DailyCopyLogic:TreatyPlatformDot(success)
  local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
  local chapterInfo = Logic.copyLogic:GetCopyChapter(copyInfo.CopyId)
  local isTreaty = self:CheckTreatyBattle(chapterInfo, copyInfo.CopyId)
  if not isTreaty then
    return
  end
  local fleetId = Logic.fleetLogic:GetBattleFleetId()
  local exBuff = {}
  if #self.SelectBuffInfo.selectBuff > 0 then
    for _, v in ipairs(self.SelectBuffInfo.selectBuff) do
      table.insert(exBuff, v.id)
    end
  end
  local exCopyData = self:GetTreatyData(chapterInfo)
  local exStarNum = self.SelectBuffInfo.starNum >= exCopyData.ExStar and self.SelectBuffInfo.starNum or exCopyData.ExStar
  local dotInfo = {
    info = "finish_copy",
    copy_displayID = copyInfo.CopyId,
    ["end"] = success and 0 or 1,
    treaty_buff_level = exStarNum,
    treaty_buff_id = exBuff,
    team_num = fleetId
  }
  RetentionHelper.Retention(PlatformDotType.battlelog, dotInfo)
end

function DailyCopyLogic:CheckTreatyReward()
  local taskInfoTab = Logic.taskLogic:GetAllTaskListByType(TaskType.TreatyTask)
  for _, v in ipairs(taskInfoTab) do
    if v.State == TaskState.FINISH then
      return true
    end
  end
  return false
end

function DailyCopyLogic:SetRecordExSelectBuff(params)
  local id = params.dailyGroupId
  local selectBuff = params.selectBuff
  self.RecordExSelectBuff[id] = selectBuff
end

function DailyCopyLogic:GetRecordExSelectBuff(dailyGroupId)
  return self.RecordExSelectBuff[dailyGroupId] ~= nil and self.RecordExSelectBuff[dailyGroupId] or {}
end

return DailyCopyLogic
