local CopyData = class("data.CopyData", Data.BaseData)

function CopyData:initialize()
  self:ResetData()
end

function CopyData:ResetData()
  self.CopyInfo = {}
  self.SeaInfo = {}
  self.TrainInfo = {}
  self.TrainAdvInfo = {}
  self.TrainLvInfo = {}
  self.ActPlotInfo = {}
  self.ActSeaInfo = {}
  self.GoodsCopy = {}
  self.DailyCopy = {}
  self.WalkDogCopy = {}
  self.EquipTestCopy = {}
  self.EquipNewTestCopy = {}
  self.BossCopyInfo = {}
  self.MubarCopyInfo = {}
  self.MultiPersonPlotCopyInfo = {}
  self.AllCopyInfo = {}
  self.plotCopyId = 0
  self.seaCopyId = 0
  self.maxTrainCopyId = 0
  self.maxTrainAdvCopyId = 0
  self.maxActPlotId = nil
  self.maxCopyId = {}
  self.ChapterInfo = {}
  self.newSeaDetail = nil
  self.isPassNewCopy = false
  self.isFirstOpenRun = false
  self.isPassNewCopyByType = {}
  self.isFirstOpenRunById = {}
  self.newPassTrainCopy = nil
  self.newPassTrainAdvCopy = nil
  self.newPassPlot = false
  self.isPassNewDailyCopy = false
  self.isPassDailyCopyId = 0
  self.bossInfo = {}
  self.sweepCopyInfo = {}
  self.maxSweepTeamNum = 0
  self.sweepingCopyIds = {}
  self.matchingState = false
  self.copyExtraInfo = {}
end

function CopyData:SetData(param)
  self:ResetRunSign()
  local setIndex = false
  if param then
    if param.BaseInfo then
      for i = 1, #param.BaseInfo do
        local baseId = param.BaseInfo[i].BaseId
        local oldBaseInfo = self.AllCopyInfo[baseId]
        if oldBaseInfo ~= nil and not oldBaseInfo.IsRunningFight and param.BaseInfo[i].IsRunningFight then
          self.isFirstOpenRunById[baseId] = true
        else
          self.isFirstOpenRunById[baseId] = false
        end
        local copyInfo = param.BaseInfo[i]
        self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
      end
    end
    if param.MaxCopyId ~= nil then
      local maxCopyIdOld = self.maxCopyId[param.CopyType]
      if maxCopyIdOld and maxCopyIdOld ~= param.MaxCopyId then
        setIndex = true
      end
      self.maxCopyId[param.CopyType] = param.MaxCopyId
    end
    if param.StarInfo ~= nil then
      for i, info in ipairs(param.StarInfo) do
        self.ChapterInfo[info.ChapterId] = info
      end
    end
  end
  if param.CopyType == ChapterType.PlotCopy then
    if param.MaxCopyId ~= nil then
      self.isPassNewCopy = self.plotCopyId ~= param.MaxCopyId
      if self.plotCopyId ~= 0 and self.isPassNewCopy then
        self.newPassPlot = true
      end
      self.plotCopyId = param.MaxCopyId
    end
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.CopyInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
  end
  if param.CopyType == ChapterType.SeaCopy then
    if param.MaxCopyId ~= nil then
      self.isPassNewCopy = self.seaCopyId ~= param.MaxCopyId
      self.seaCopyId = param.MaxCopyId
    end
    self.newSeaDetail = nil
    for i = 1, #param.BaseInfo do
      local oldBaseInfo = self.SeaInfo[param.BaseInfo[i].BaseId]
      if oldBaseInfo ~= nil and not oldBaseInfo.IsRunningFight and param.BaseInfo[i].IsRunningFight then
        self.isFirstOpenRun = true
      end
      if self.SeaInfo[param.BaseInfo[i].BaseId] == nil then
        self.newSeaDetail = param.BaseInfo[i]
      end
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.SeaInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
    for i, info in ipairs(param.StarInfo) do
      self.ChapterInfo[info.ChapterId] = info
    end
  end
  if param.CopyType == ChapterType.Train then
    if param.MaxCopyId ~= nil then
      self.isPassNewCopy = self.maxTrainCopyId ~= param.MaxCopyId
      self.maxTrainCopyId = param.MaxCopyId
    end
    self.newPassTrainCopy = nil
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      copyInfo.StarNum = self:StarLevel2Num(copyInfo.StarLevel)
      local oldInfo = self.TrainInfo[copyInfo.BaseId]
      if oldInfo and not oldInfo.Pass and copyInfo.Pass then
        self.newPassTrainCopy = copyInfo
      end
      self.TrainInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
    for i, info in ipairs(param.StarInfo) do
      self.ChapterInfo[info.ChapterId] = info
    end
  end
  if param.CopyType == ChapterType.TrainAdvance then
    if param.MaxCopyId ~= nil then
      self.isPassNewCopy = self.maxTrainAdvCopyId ~= param.MaxCopyId
      self.maxTrainAdvCopyId = param.MaxCopyId
    end
    self.newPassTrainAdvCopy = nil
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.StarNum = self:StarLevel2Num(copyInfo.StarLevel)
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      local oldInfo = self.TrainAdvInfo[copyInfo.BaseId]
      if oldInfo and not oldInfo.Pass and copyInfo.Pass then
        self.newPassTrainAdvCopy = copyInfo
      end
      self.TrainAdvInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
    for i, info in ipairs(param.StarInfo) do
      self.ChapterInfo[info.ChapterId] = info
    end
  end
  if param.CopyType == ChapterType.TrainLv then
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.TrainLvInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
    for i, info in ipairs(param.StarInfo) do
      self.ChapterInfo[info.ChapterId] = info
    end
  end
  if param.CopyType == ChapterType.ActPlotCopy then
    if param.MaxCopyId ~= nil then
      self.isPassNewCopy = self.maxActPlotId ~= param.MaxCopyId
      self.maxActPlotId = param.MaxCopyId
    end
    if self.maxActPlotId == 0 and #param.BaseInfo == 1 then
      self.maxActPlotId = param.BaseInfo[1].BaseId
    end
    for i = 1, #param.BaseInfo do
      self.ActPlotInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
    end
  end
  if param.CopyType == ChapterType.ActSeaCopy then
    for i = 1, #param.BaseInfo do
      self.ActSeaInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
    end
    for i, info in ipairs(param.StarInfo) do
      self.ChapterInfo[info.ChapterId] = info
    end
  end
  if param.CopyType == ChapterType.GoodsCopy then
    for i = 1, #param.BaseInfo do
      self.GoodsCopy[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
    end
  end
  if param.CopyType == ChapterType.DailyCopy then
    self.isPassNewDailyCopy = false
    self.isPassDailyCopyId = 0
    for i = 1, #param.BaseInfo do
      if self.DailyCopy[param.BaseInfo[i].BaseId] ~= nil and self.DailyCopy[param.BaseInfo[i].BaseId].FirstPassTime == 0 and 0 < param.BaseInfo[i].FirstPassTime then
        self.isPassNewDailyCopy = true
        self.isPassDailyCopyId = param.BaseInfo[i].BaseId
      end
      self.DailyCopy[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = param.BaseInfo[i]
    end
  end
  if param.CopyType == ChapterType.WalkDog and #param.BaseInfo > 0 then
    self.WalkDogCopy = param.BaseInfo[1]
  end
  if param.CopyType == ChapterType.EquipTestCopy and #param.BaseInfo > 0 then
    self.EquipTestCopy = param.BaseInfo
  end
  if param.CopyType == ChapterType.EquipNewTestCopy and #param.BaseInfo > 0 then
    self.EquipNewTestCopy = param.BaseInfo
  end
  if setIndex then
    local uid = Data.userData:GetUserData().Uid
    if uid and 0 < uid then
      local chapterType = param.CopyType
      local chapterId, _ = Logic.copyLogic:GetFarestId(chapterType)
      PlayerPrefs.SetInt(uid .. "SeaCopyPage" .. param.CopyType, chapterId)
    end
  end
  if param.CopyType == ChapterType.BossCopy then
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.BossCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
  end
  if param.CopyType == ChapterType.MubarCopy then
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.MubarCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
  end
  if param.CopyType == ChapterType.MultiPersonPlotCopy then
    for i = 1, #param.BaseInfo do
      local copyInfo = param.BaseInfo[i]
      copyInfo.Pass = 0 < copyInfo.FirstPassTime
      self.MultiPersonPlotCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
      self.AllCopyInfo[param.BaseInfo[i].BaseId] = copyInfo
    end
  end
end

function CopyData:StarLevel2Num(starLevel)
  if starLevel & 4 == 4 then
    return 3
  elseif starLevel & 2 == 2 then
    return 2
  elseif starLevel & 1 == 1 then
    return 1
  end
  return 0
end

function CopyData:GetChapterDataById(chapterId)
  return self.ChapterInfo[chapterId]
end

function CopyData:GetChapterStar(chapterId)
  local chapterData = self.ChapterInfo[chapterId]
  return chapterData and chapterData.StarNum or 0
end

function CopyData:GetRewardBoxStatus(chapterId, index)
  local chapterData = self.ChapterInfo[chapterId]
  if chapterData == nil then
    return false
  end
  local starRewardBoxInfo = chapterData.StarRewardBox
  for i, v in ipairs(starRewardBoxInfo) do
    if index == v.Index then
      return v.RewardTime == 1
    end
  end
  return false
end

function CopyData:GetCopyServiceData()
  return SetReadOnlyMeta(self.SeaInfo)
end

function CopyData:GetFarestSeaCopyId()
  return self.seaCopyId
end

function CopyData:GetPlotCopyServiceData()
  return SetReadOnlyMeta(self.CopyInfo)
end

function CopyData:GetFarestPlotCopyId()
  return self.plotCopyId
end

function CopyData:GetTrainServiceData()
  return SetReadOnlyMeta(self.TrainInfo)
end

function CopyData:GetFarestTrainCopyId()
  return self.maxTrainCopyId
end

function CopyData:GetTrainAdvServiceData()
  return SetReadOnlyMeta(self.TrainAdvInfo)
end

function CopyData:GetFirstAvailableTrainAdvCopyId()
  for i, copyInfo in pairs(self.TrainAdvInfo) do
    if not copyInfo.Pass then
      return copyInfo.BaseId
    end
  end
  return nil
end

function CopyData:GetTrainLvServiceData()
  return SetReadOnlyMeta(self.TrainLvInfo)
end

function CopyData:GetFarestTrainAdvCopyId()
  return self.maxTrainAdvCopyId
end

function CopyData:GetCopyDataByCopyId(copyId)
  return self.SeaInfo[copyId]
end

function CopyData:GetPlotCopyDataCopyId(copyId)
  return self.CopyInfo[copyId]
end

function CopyData:GetTrainCopyDataCopyId(copyId)
  return self.TrainInfo[copyId]
end

function CopyData:GetTrainAdvCopyDataCopyId(copyId)
  return self.TrainAdvInfo[copyId]
end

function CopyData:GetNewSeaDetail()
  return self.newPassPlot, self.newSeaDetail
end

function CopyData:IsPassNewCopy()
  return self.isPassNewCopy
end

function CopyData:IsFirstOpenRun()
  return self.isFirstOpenRun
end

function CopyData:ResetRunSign()
  self.isFirstOpenRun = false
end

function CopyData:GetActPlotData()
  return self.ActPlotInfo
end

function CopyData:GetActSeaData()
  return self.ActSeaInfo
end

function CopyData:GetGoodsCopyData()
  return self.GoodsCopy
end

function CopyData:GetFarestActPlotId()
  return self.maxActPlotId
end

function CopyData:GetActSeaDataByCopyId(copyId)
  return self.ActSeaInfo[copyId]
end

function CopyData:GetActPlotCopyDataCopyId(copyId)
  return self.ActPlotInfo[copyId]
end

function CopyData:GetNewPassTrainCopy()
  return self.newPassTrainCopy
end

function CopyData:SetNewPassTrainCopy(newPassTrainCopy)
  self.newPassTrainCopy = newPassTrainCopy
end

function CopyData:GetNewPassTrainAdvCopy()
  return self.newPassTrainAdvCopy
end

function CopyData:SetNewPassTrainAdvCopy(newPassTrainAdvCopy)
  self.newPassTrainAdvCopy = newPassTrainAdvCopy
end

function CopyData:ResetPassPlot()
  self.newPassPlot = false
end

function CopyData:GetDailyCopyByCopyId(copyId)
  return self.DailyCopy[copyId]
end

function CopyData:GetCopyInfoById(copyId)
  return self.AllCopyInfo[copyId]
end

function CopyData:GetCopyInfo()
  return self.AllCopyInfo
end

function CopyData:GetFarestCopyId(typ)
  return self.maxCopyId[typ] or 0
end

function CopyData:IsFirstOpenRunById(baseId)
  return self.isFirstOpenRunById[baseId] or false
end

function CopyData:GetPassNewDaily()
  return self.isPassNewDailyCopy
end

function CopyData:GetPassDailyCopyId()
  return self.isPassDailyCopyId
end

function CopyData:GetWalkDogData()
  return self.WalkDogCopy
end

function CopyData:IsNotSameDay()
  if self.refreshTime == 0 then
    return false
  end
  local timeNow = time.getSvrTime()
  local timeFormatRefresh = os.date("*t", self.refreshTime)
  local timeFormatNow = os.date("*t", timeNow)
  return timeFormatRefresh.day ~= timeFormatNow.day
end

function CopyData:GetBossCopyInfo()
  return self.BossCopyInfo
end

function CopyData:SetBossInfo(params)
  if next(params.BossList) == nil and next(self.bossInfo) ~= nil then
    if params.AtkCount ~= nil then
      self.bossInfo.AtkCount = params.AtkCount
    end
    if params.Status == ActBattleBossStage.BattleEnd then
      for _, v in ipairs(self.bossInfo.BossList) do
        v.Hp = 0
      end
    end
    self.bossInfo.Status = params.Status
  else
    self.bossInfo = params
  end
end

function CopyData:SetCopyMatchTempData(arg)
  self.matchData = {}
  self.matchData.args = {
    ChapterId = arg.chapterId,
    CopyId = arg.copyId,
    IsRunningFight = arg.isRunningFight,
    TacticId = arg.tacticId,
    CacheId = arg.cacheId,
    HeroList = arg.heroList,
    StrategyId = arg.strategyId,
    DailyGroupId = arg.dailyGroupId,
    BattleMode = arg.battleMode,
    AnimMode = arg.animMode,
    Power = arg.power,
    ExBuff = arg.exBuff
  }
end

function CopyData:GetCopyMatchTempData()
  if self.matchData and self.matchData.args ~= nil then
    return self.matchData.args
  end
end

function CopyData:SetMatchingState(state)
  if state ~= nil then
    self.matchingState = state
  end
end

function CopyData:GetMatchingState()
  if self.matchingState == nil then
    self.matchingState = false
  end
  return self.matchingState
end

function CopyData:SetMatchPlayerTempData(data)
  self.matchPlayerData = data
end

function CopyData:GetMatchPlayerTempData()
  return self.matchPlayerData
end

function CopyData:GetSweepingCopyIds()
  return self.sweepingCopyIds
end

function CopyData:SetSweepCopyInfo(params)
  self.sweepCopyInfo = {}
  self.sweepingCopyIds = {}
  if params then
    self:SetMaxFleetNum(params.sweepFleetsNum)
    if params.data ~= nil and #params.data > 0 then
      local num = #params.data
      for i = 1, #params.data do
        local sweepInfo = params.data[i]
        if sweepInfo ~= nil then
          self.sweepCopyInfo[i] = sweepInfo
          self.sweepingCopyIds[i] = self.sweepCopyInfo[i].copyId
        end
      end
    else
    end
  end
end

function CopyData:GetSweepCopyInfo()
  if self.sweepCopyInfo ~= nil and #self.sweepCopyInfo > 0 then
    return self.sweepCopyInfo
  else
    return nil
  end
end

function CopyData:SetMaxFleetNum(num)
  self.maxSweepTeamNum = num
end

function CopyData:GetMaxFleetNum()
  return self.maxSweepTeamNum
end

function CopyData:GetBossInfo()
  return self.bossInfo
end

function CopyData:GetMubarCopyInfoById(copyId)
  return self.MubarCopyInfo[copyId]
end

function CopyData:SetCopyExtraInfo(ret)
  for i, v in ipairs(ret.CopyRewardTimes) do
    self.copyExtraInfo[v.Chapter] = v.RewardTime
  end
end

function CopyData:GetCopyRewardCount(chapterId)
  return self.copyExtraInfo[chapterId] ~= nil and self.copyExtraInfo[chapterId] or 0
end

return CopyData
