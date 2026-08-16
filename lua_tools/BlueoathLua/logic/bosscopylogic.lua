local BossCopyLogic = class("logic.BossCopyLogic")
local json = require("cjson")
BossStage = {
  ActBattleBoss = 1,
  ActKillBoss = 2,
  PlotFirstBoss = 3,
  PlotSecondBoss = 4
}
ActBattleBossStage = {
  BattleStart = 0,
  Battling = 1,
  BattleEnd = 2
}
SingleBossStatus = {
  Locked = 0,
  UnLockedAndLive = 1,
  Killed = 2
}

function BossCopyLogic:initialize()
end

function BossCopyLogic:ResetData()
  self.fastPlotId = 0
end

function BossCopyLogic:GetBossCopyConfig()
  local BossCopyConf = configManager.GetData("config_boss_copy_main")
  return BossCopyConf
end

function BossCopyLogic:GetActBossConfig()
  local conf = configManager.GetData("config_boss_copy_activity")
  return conf
end

function BossCopyLogic:HaveAliveBoss()
  local bossData = Data.copyData:GetBossInfo()
  local bossList = Logic.bossCopyLogic:SortBossList(bossData.BossList)
  for _, bossInfo in ipairs(bossList) do
    local status = self:GetSingleBossStatusById(bossInfo.BossId)
    if status == SingleBossStatus.UnLockedAndLive then
      return true
    end
  end
  return false
end

function BossCopyLogic:GetBossByBossId(bossID)
  local bossData = Data.copyData:GetBossInfo()
  if bossID < 1 or bossID > #bossData.BossList then
    return nil, false
  end
  for _, v in ipairs(bossData.BossList) do
    if bossID == v.BossId then
      return v, true
    end
  end
  return nil, false
end

function BossCopyLogic:GetKillBossReward(copyDisId)
  local bossCopyConf = self:GetActBossConfig()
  for _, v in ipairs(bossCopyConf) do
    for _, id in ipairs(v.copy_display_id) do
      if id == copyDisId then
        return v.rewards
      end
    end
  end
end

function BossCopyLogic:GetSingleBossStatusById(bossID)
  local bossInfo, ok = self:GetBossByBossId(bossID)
  if ok then
    local timeNow = time.getSvrTime()
    if timeNow >= bossInfo.UnlockTime and bossInfo.UnlockTime > 0 then
      if 0 < bossInfo.Hp then
        return SingleBossStatus.UnLockedAndLive
      else
        return SingleBossStatus.Killed
      end
    else
      return SingleBossStatus.Locked
    end
  else
    logError("BossCopyLogic:GetSingleBossStatusById GetBossByBossId Err")
  end
end

function BossCopyLogic:GetActBossInfoByCopyId(copyDisId)
  local bossData = Data.copyData:GetBossInfo()
  local bossList = Logic.bossCopyLogic:SortBossList(bossData.BossList)
  local bossCopyConf = self:GetActBossConfig()
  for i, v in ipairs(bossCopyConf) do
    for _, id in ipairs(v.copy_display_id) do
      if id == copyDisId then
        return bossList[i], v
      end
    end
  end
end

function BossCopyLogic:SortBossList(tab)
  table.sort(tab, function(data1, data2)
    return data1.BossId < data2.BossId
  end)
  return tab
end

function BossCopyLogic:GetBossCopyStage(isBossPlot)
  local bossCopyConf = self:GetBossCopyConfig()
  local activityBossConf = self:GetActBossConfig()
  local serCopyData = Data.copyData:GetBossCopyInfo()
  local bossData = Data.copyData:GetBossInfo()
  local isPlot = isBossPlot or false
  local chapterOne, chapterTwo = 0, 0
  if bossData.BossList == nil or #bossData.BossList == 0 then
    chapterOne = #activityBossConf
  else
    for key, value in pairs(activityBossConf) do
      if next(bossData) ~= nil and (bossData.Status == ActBattleBossStage.BattleEnd or bossData.BossList[key].Hp == 0) then
        chapterOne = chapterOne + 1
      end
    end
  end
  for id, v in ipairs(bossCopyConf) do
    for i, copyId in ipairs(v.copy_display_id) do
      if i == 2 and serCopyData[copyId] ~= nil and 0 < serCopyData[copyId].FirstPassTime then
        chapterTwo = chapterTwo + 1
      end
    end
  end
  if next(bossData) == nil then
    chapterOne = #activityBossConf
  end
  if isBossPlot then
    if chapterTwo == #bossCopyConf then
      return BossStage.PlotSecondBoss
    else
      return BossStage.PlotFirstBoss
    end
  elseif chapterOne == #activityBossConf then
    return BossStage.ActKillBoss
  else
    return BossStage.ActBattleBoss
  end
end

function BossCopyLogic:CheckPlotStartRecorded()
  local uid = Data.userData:GetUserUid()
  local recordId = PlayerPrefs.GetInt("BossPlotStartId" .. uid, 0)
  if recordId ~= 0 then
    return true
  end
  return false
end

function BossCopyLogic:CheckPlotEndRecorded()
  local uid = Data.userData:GetUserUid()
  local recordId = PlayerPrefs.GetInt("BossPlotEndId" .. uid, 0)
  if recordId ~= 0 then
    return true
  end
  return false
end

function BossCopyLogic:IsInBossBattleStage()
  local res = false
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  if activityID then
    local actBossRec = configManager.GetDataById("config_activity", activityID)
    local startTime, endTime = PeriodManager:GetOnePeriodTimeByIndex(actBossRec.period, actBossRec.period_area[1])
    local curtime = time.getSvrTime()
    if startTime <= curtime and endTime >= curtime then
      res = true
    end
  end
  return res
end

function BossCopyLogic:GetBossStageByTime(time)
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  if activityID then
    local actBossRec = configManager.GetDataById("config_activity", activityID)
    local startTime, endTime = PeriodManager:GetOnePeriodTimeByIndex(actBossRec.period, actBossRec.period_area[1])
    if time >= startTime and time <= endTime then
      return BossStage.ActBattleBoss
    else
      return BossStage.ActKillBoss
    end
  end
  return BossStage.ActKillBoss
end

function BossCopyLogic:SetFastPlot()
  self.fastPlotId = Data.copyData:GetFarestPlotCopyId()
end

function BossCopyLogic:ResetFastPlot()
  self.fastPlotId = 0
end

function BossCopyLogic:CheckFirstPassBoss(bossPlotId)
  local plotBossCopy = false
  local plotCopyData = Data.copyData:GetPlotCopyDataCopyId(bossPlotId)
  if plotCopyData ~= nil and plotCopyData.FirstPassTime > 0 then
    plotBossCopy = true
  end
  if self.fastPlotId ~= 0 and self.fastPlotId ~= bossPlotId and plotBossCopy then
    return true
  end
  return false
end

function BossCopyLogic:CheckBlackEffRecorded()
  local uid = Data.userData:GetUserUid()
  local recorded = PlayerPrefs.GetBool("BlackEffRecorded" .. uid, false)
  return recorded
end

return BossCopyLogic
