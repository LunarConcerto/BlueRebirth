local ActivityGalgameLogic = class("logic.ActivityGalgameLogic")

function ActivityGalgameLogic:initialize()
  self:ResetData()
end

function ActivityGalgameLogic:ResetData()
end

function ActivityGalgameLogic:GetGalgamePlotCopy(tabp1, forbidPlotId)
  local copyList = {}
  for _, list in pairs(copyList) do
    for _, v in pairs(list) do
      table.insert(copyList, v)
    end
  end
  if forbidPlotId == nil or #forbidPlotId == 0 then
    return copyList
  else
    local showPlotTab = {}
    for _, v in ipairs(copyList) do
      if not table.containV(forbidPlotId, v) then
        table.insert(showPlotTab, v)
      end
    end
    return showPlotTab
  end
end

function ActivityGalgameLogic:GetGalgamePlotCopy_Extra(chapterId, forbidPlotId)
  local chapterConf = configManager.GetDataById("config_chapter", chapterId)
  if forbidPlotId == nil or #forbidPlotId == 0 then
    return chapterConf.level_list
  else
    local showPlotTab = {}
    for _, v in ipairs(chapterConf.level_list) do
      if not table.containV(forbidPlotId, v) then
        table.insert(showPlotTab, v)
      end
    end
    return showPlotTab
  end
end

function ActivityGalgameLogic:IsClearCopy(id)
  local copyData = Data.copyData:GetCopyInfoById(id)
  return copyData ~= nil and copyData.FirstPassTime ~= 0
end

function ActivityGalgameLogic:CheckOpenLimit(chapterId)
  local seaChapterInfo = Logic.copyLogic:GetChaperConfById(chapterId)
  local copyDisplay = Logic.copyLogic:GetCopyDesConfig(seaChapterInfo.level_list[1])
  if copyDisplay.sea_area_unlock == 0 then
    return true
  else
    local copyData = Data.copyData:GetCopyInfoById(seaChapterInfo.level_list[1])
    if self:IsClearCopy(copyDisplay.sea_area_unlock) and copyData ~= nil then
      return true
    end
  end
  local plotDisplay = Logic.copyLogic:GetCopyDesConfig(copyDisplay.sea_area_unlock)
  return false, plotDisplay.name
end

function ActivityGalgameLogic:CheckOpenNewPlot(actId)
  if not Logic.activityLogic:CheckActivityOpenById(actId) then
    return false
  end
  local plotIdTab = self:GetRecoredId()
  local actConfig = configManager.GetDataById("config_activity", actId)
  local plotCopyIdTab = Logic.activityGalgameLogic:GetGalgamePlotCopy(actConfig.p1[1], actConfig.p5)
  for _, plotId in ipairs(plotCopyIdTab) do
    local copyData = Data.copyData:GetCopyInfoById(plotId)
    local copyPlotConfig = Logic.copyLogic:GetCopyDesConfig(plotId)
    local startTime, _ = PeriodManager:GetPeriodTime(copyPlotConfig.activity_period, copyPlotConfig.activity_period_area)
    local serverTime = time.getSvrTime()
    if startTime < serverTime and copyData ~= nil and copyData.FirstPassTime == 0 and plotIdTab[plotId] == nil then
      return true
    end
  end
  return false
end

function ActivityGalgameLogic:RecordPlotId(plotId)
  local plotIdTab = self:GetRecoredId()
  if plotIdTab[plotId] ~= nil then
    return
  end
  local strRecord = ""
  for k, v in pairs(plotIdTab) do
    strRecord = strRecord .. ";" .. v
  end
  strRecord = strRecord .. ";" .. plotId
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetString(uid .. "GalgamePlotHistory", strRecord)
end

function ActivityGalgameLogic:GetRecoredId()
  local plotIdTab = {}
  local uid = Data.userData:GetUserUid()
  local strRecord = PlayerPrefs.GetString(uid .. "GalgamePlotHistory")
  if strRecord == nil then
    return nil
  end
  local his = string.split(strRecord, ";")
  for _, v in pairs(his) do
    if v ~= nil and v ~= "" then
      plotIdTab[tonumber(v)] = tonumber(v)
    end
  end
  return plotIdTab
end

function ActivityGalgameLogic:CheckTaskReward(actId)
  if not Logic.activityLogic:CheckActivityOpenById(actId) then
    return false
  end
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, actId)
  for _, v in ipairs(tabTaskInfo) do
    if v.State == TaskState.FINISH then
      return true
    end
  end
  return false
end

function ActivityGalgameLogic:CheckOpenExtraPlot(actId)
  if not Logic.activityLogic:CheckActivityOpenById(actId) then
    return false
  end
  local actConfig = configManager.GetDataById("config_activity", actId)
  local plotCopyIdTab = Logic.activityGalgameLogic:GetGalgamePlotCopy_Extra(actConfig.p1[1])
  for _, v in ipairs(plotCopyIdTab) do
    local plotCopyInfo = Logic.copyLogic:GetCopyDesConfig(v)
    local ownExpendItem = Data.bagData:GetItemNum(plotCopyInfo.activity_item[1])
    local isClear = Logic.activityGalgameLogic:IsClearCopy(plotCopyInfo.id)
    if not isClear and ownExpendItem >= plotCopyInfo.activity_item[2] then
      return true
    end
  end
  return false
end

function ActivityGalgameLogic:CheckNewChapter(actId)
  if not Logic.activityLogic:CheckActivityOpenById(actId) then
    return false
  end
  local actConfig = configManager.GetDataById("config_activity", actId)
  local plotCopyIdTab = {}
  for _, chapterId in pairs(actConfig.p2) do
    local chapterConf = configManager.GetDataById("config_chapter", chapterId)
    table.insert(plotCopyIdTab, chapterConf.level_list[1])
  end
  for _, plotId in ipairs(plotCopyIdTab) do
    local copyData = Data.copyData:GetCopyInfoById(plotId)
    local copyPlotConfig = Logic.copyLogic:GetCopyDesConfig(plotId)
    local startTime, _ = PeriodManager:GetPeriodTime(copyPlotConfig.activity_period, copyPlotConfig.activity_period_area)
    local serverTime = time.getSvrTime()
    if startTime < serverTime and copyData ~= nil and copyData.FirstPassTime == 0 then
      return true
    end
  end
  return false
end

function ActivityGalgameLogic:CheckCanRandom(actId)
  if not Logic.activityLogic:CheckActivityOpenById(actId) then
    return false
  end
  local actConfig = configManager.GetDataById("config_activity", actId)
  local curPoolId = Data.activityExtractData:GetDrawID()
  if curPoolId == 0 then
    return false
  end
  local curPoolConf = configManager.GetDataById("config_activity_extract", curPoolId)
  local num = Data.bagData:GetItemNum(curPoolConf.item_cost[2])
  return num >= curPoolConf.item_cost[3]
end

return ActivityGalgameLogic
