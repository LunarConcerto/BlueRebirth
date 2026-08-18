local CopyLogic = class("logic.CopyLogic")
local PLOT_COPY_MAX = 6
CopyLogic.SelectCopyType = {
  PlotCopy = 0,
  SeaCopy = 1,
  DailyCopy = 3,
  PlotMainCopy = 4
}
Copy_Display_Type = {
  SeaCopy = 1,
  PlotCopy = 2,
  MiniGame = 3,
  BossCopy = 4
}
ButtomTogType = {
  OUTPUT = 0,
  LLEQUIP = 1,
  KILLBOSS = 2
}

function CopyLogic:initialize()
  self:ResetData()
end

function CopyLogic:ResetData()
  self.nSelectedChapter = {}
  self.tabChapterConfig = configManager.GetData("config_chapter")
  self.tabAllCopyId = {}
  self.tabAllRunningCopyId = {}
  self.tabDailyCopyId = {}
  self.bAutoRepaire = true
  self.nTogsIndex = 0
  self.enterSign = EnterCopySign.Home
  self.isInBattle = false
  self.chase = {}
  self.tabSaveAttackCopyInfo = {}
  self.currDisplayPlotIndex = nil
  self.cachFirstTime = 0
  self.selectTog = -1
  self.plotScrollPos = 1
  self.hasNpcAssist = false
  self.clickPlotDetail = nil
  self.randFactors = {}
  self.actTog = -1
  self.attackSafeInfo = {}
  self.boxStateByType = {}
  self.chapterByType = {}
  self.muborChapterConfig = {}
  self:_editCopyDisplayConfig()
  self.currCopyNight = {}
  self.belongChapterTab = {}
  self.currBattleType = {}
  self.isLoad = false
  self.copyBgPos = {}
  self.inNewChapter = false
  self.plotCopyId = 0
  self.BBattleAttack = 0
  self.jumpPlotDetailsId = 0
  self.SeaCopyActivityToggle = 0
  self.SeaCopyActivityToggleLast = 0
  self.m_curCopyId = 0
  self.tempAnimMode = -1
  self.isInPve = false
end

function CopyLogic:GetIsLoad()
  return self.isLoad
end

function CopyLogic:SetIsLoad(_bool)
  self.isLoad = _bool
end

function CopyLogic:GetBoxStateByType(typ)
  if self.boxStateByType[typ] == nil then
    return true
  end
  return self.boxStateByType[typ]
end

function CopyLogic:SetBoxStateByType(typ, _bool)
  self.boxStateByType[typ] = _bool
end

function CopyLogic:GetChapterByType(typ)
  return self.chapterByType[typ]
end

function CopyLogic:SetActSelectTog(index)
  self.actTog = index
end

function CopyLogic:GetActSelectTog(index)
  return self.actTog
end

function CopyLogic:SetRandFactors(copyId, randFactor)
  self.randFactors[copyId] = randFactor
end

function CopyLogic:GetRandFactors(copyId)
  return self.randFactors[copyId]
end

function CopyLogic:SetSelectPlotDetail(param)
  self.clickPlotDetail = param
end

function CopyLogic:GetPlotDetail()
  return self.clickPlotDetail
end

function CopyLogic:SetPlotScrollPos(pos)
  self.plotScrollPos = pos < 0 and 0 or pos
end

function CopyLogic:GetPlotScrollPos()
  return self.plotScrollPos
end

function CopyLogic:SetSelectTog(index)
  self.selectTog = index
end

function CopyLogic:GetSelectTog()
  return self.selectTog
end

function CopyLogic:CachCurFirstTime(firstTime)
  self.cachFirstTime = firstTime
end

function CopyLogic:GetCurFirstTime()
  return self.cachFirstTime or 0
end

function CopyLogic:SetUserEnterBattle(isIn)
  self.isInBattle = isIn
end

function CopyLogic:GetUserCurStatus()
  return self.isInBattle
end

function CopyLogic:SetInPveState(isIn)
  self.isInPve = isIn
end

function CopyLogic:GetInPveState()
  return self.isInPve
end

function CopyLogic:SetChase(chase)
  self.chase = chase
end

function CopyLogic:GetChase()
  return self.chase
end

function CopyLogic:SetRunningFlog(copyId, runningFlog)
  self.chase[copyId] = runningFlog
end

function CopyLogic:SetSelectChapter(mType, id)
  self.nSelectedChapter[mType] = id
end

function CopyLogic:GetSelectChapter(mType)
  self.nSelectedChapter[mType] = self.nSelectedChapter[mType] == nil and 0 or self.nSelectedChapter[mType]
  return self.nSelectedChapter[mType]
end

function CopyLogic:GetAutoRepaireInfo()
  return self.bAutoRepaire
end

function CopyLogic:SetAutoRepaireInfo(isAuto)
  self.bAutoRepaire = isAuto
end

function CopyLogic:GetCurSeaChapterSection()
  return self:_getFarestId(ChapterType.SeaCopy)
end

function CopyLogic:GetCurPlotChapterSection()
  return self:_getFarestId(ChapterType.PlotCopy)
end

function CopyLogic:OnNumberInvert(textTime)
  local minString, secString
  local sec = Mathf.ToInt(textTime % 60)
  local min = Mathf.ToInt(textTime / 60 - textTime / 60 % 1)
  if min < 10 then
    minString = "0" .. tostring(min) .. "'"
  else
    minString = tostring(min) .. "'"
  end
  if sec < 10 then
    secString = "0" .. tostring(sec) .. "\""
  else
    secString = tostring(sec) .. "\""
  end
  return minString .. secString
end

function CopyLogic:GetAreaConfig(chapterId)
  local chapterConf = configManager.GetDataById("config_chapter", chapterId)
  local tabLevelConfig = chapterConf.level_list
  local tabAreaDesConfig = {}
  for k, v in pairs(tabLevelConfig) do
    table.insert(tabAreaDesConfig, configManager.GetDataById("config_copy_display", v))
  end
  return tabAreaDesConfig
end

function CopyLogic:GetCopyDataConfig(id)
  local copyConfig = configManager.GetDataById("config_copy", id)
  return copyConfig
end

function CopyLogic:GetCopyDesConfig(id)
  local copyDesInfo = configManager.GetDataById("config_copy_display", id)
  return copyDesInfo
end

function CopyLogic:GetStarReauire(tab)
  local des = configManager.GetDataById("config_evaluate", tab).description
  return des
end

function CopyLogic:GetDropInfo()
  local tabDropInfo = configManager.GetData("config_drop_info")
  return tabDropInfo
end

function CopyLogic:FilterDropId(dropIdList)
  local result = {}
  for i, dropId in ipairs(dropIdList) do
    local dropCfg = configManager.GetDataById("config_drop_info", dropId)
    local itemCount = #dropCfg.item_info
    if 0 < itemCount then
      table.insert(result, dropId)
    end
  end
  return result
end

function CopyLogic:GetOilAndAmmoTicket()
  local tabGasTicket = configManager.GetDataById("config_parameter", 6)
  local gasTicket = tabGasTicket.value / 10000
  gasTicket = gasTicket - gasTicket % 0.01
  local tabAmmTicket = configManager.GetDataById("config_parameter", 9)
  local AmmTicket = tabAmmTicket.value / 10000
  AmmTicket = AmmTicket - AmmTicket % 0.01
  return gasTicket, AmmTicket
end

function CopyLogic:GetBattleConfig()
  local maxPo = tonumber(configManager.GetDataById("config_battle_config", 6).data)
  local minPo = tonumber(configManager.GetDataById("config_battle_config", 7).data)
  return maxPo, minPo
end

function CopyLogic:GetFleetConfig(id)
  local configFleet = configManager.GetDataById("config_fleet", id)
  return configFleet
end

function CopyLogic:GetChaperConfById(id)
  return configManager.GetDataById("config_chapter", id)
end

function CopyLogic:GetShipEnemyConfig(id)
  local configEnemy = configManager.GetDataById("config_ship_enemy", id)
  return configEnemy
end

function CopyLogic:SetTogsIndex(nIndex)
  self.nTogsIndex = nIndex
end

function CopyLogic:GetTogsIndex()
  return self.nTogsIndex
end

function CopyLogic:SetCopySign(sign)
  self.enterSign = sign
end

function CopyLogic:GetCopySign()
  return self.enterSign
end

function CopyLogic:SetEnterLevelInfo(isEnter)
  self.isEnter = isEnter
end

function CopyLogic:GetEnterLevelInfo()
  return self.isEnter
end

function CopyLogic:GetCopyChaseInfo(nChapterId, copyid)
  local chapterConf = configManager.GetDataById("config_chapter", nChapterId)
  for k, v in ipairs(chapterConf.level_list) do
    if v == copyid then
      return chapterConf.running_level_list[k]
    end
  end
  return nil
end

function CopyLogic:ShowMsgBox(msgId, okFunc)
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(ok)
      logError("bool:", ok)
      if ok then
        okFunc()
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(msgId), tabParams)
end

function CopyLogic:SetAttackCopyInfo(copyId, isChaseFighting, sfLv, sfPoint)
  self.tabSaveAttackCopyInfo = {CopyId = copyId, IsRunningFight = isChaseFighting}
  self.attackSafeInfo = {
    CopyId = copyId,
    SfLv = sfLv,
    SfPoint = sfPoint
  }
end

function CopyLogic:GetAttackCopyInfo()
  return self.tabSaveAttackCopyInfo
end

function CopyLogic:CheckChaseOpen(copyId)
  return Data.copyData:IsFirstOpenRun()
end

function CopyLogic:GetPassPlotChapterInfo()
  local chapterId, copyId = self:GetCurPlotChapterSection()
  local copyInfo = Data.copyData:GetPlotCopyDataCopyId(copyId)
  if copyInfo ~= nil and copyInfo.FirstPassTime ~= 0 then
    local nextCopyId = self.tabAllCopyId[copyId].nextCopyId
    if self.tabAllCopyId[nextCopyId] ~= nil and self.tabAllCopyId[nextCopyId].chapterId ~= chapterId then
      chapterId = self.tabAllCopyId[nextCopyId].chapterId
    end
  end
  local tabTemp = {}
  local chaterConf = configManager.GetData("config_chapter")
  for k, v in pairs(chaterConf) do
    if v.class_type == ChapterType.PlotCopy and chapterId >= v.id then
      table.insert(tabTemp, v)
    end
  end
  table.sort(tabTemp, function(a, b)
    return a.id < b.id
  end)
  return tabTemp
end

function CopyLogic:GetPassChapterInfoByClassId(classId)
  local tabTemp = {}
  if classId == ChapterPlotType.MainPlot then
    local chaterConf = configManager.GetData("config_chapter")
    local chapterId, copyId, _ = self:GetLastChapterAndCopyById(classId)
    local copyInfo = Data.copyData:GetPlotCopyDataCopyId(copyId)
    if copyInfo ~= nil and copyInfo.FirstPassTime ~= 0 then
      local nextCopyId = self.tabAllCopyId[copyId].nextCopyId
      if self.tabAllCopyId[nextCopyId] ~= nil and self.tabAllCopyId[nextCopyId].chapterId ~= chapterId then
        chapterId = self.tabAllCopyId[nextCopyId].chapterId
      end
    end
    for k, v in pairs(chaterConf) do
      if chapterId >= v.id and v.chapter_plot_type == classId then
        table.insert(tabTemp, v)
      end
    end
  else
    local chapterList = configManager.GetDataById("config_chapter_plot_type", classId).chapter_list
    for _, v in pairs(chapterList) do
      local chapterInfo = configManager.GetDataById("config_chapter", v)
      local copyInfo = Data.copyData:GetCopyInfoById(chapterInfo.level_list[1])
      if chapterInfo.chapter_plot_type == classId and copyInfo ~= nil then
        table.insert(tabTemp, chapterInfo)
      end
    end
  end
  table.sort(tabTemp, function(a, b)
    return a.id < b.id
  end)
  return tabTemp
end

function CopyLogic:GetPassChapterInfoByClassIdAndPartId(classId, partId)
  local tabTemp = {}
  local tabTempAll = {}
  if classId == ChapterPlotType.MainPlot then
    local chaterConf = configManager.GetData("config_chapter")
    local chapterId, copyId, _ = self:GetLastChapterAndCopyById(classId)
    local copyInfo = Data.copyData:GetPlotCopyDataCopyId(copyId)
    if copyInfo ~= nil and copyInfo.FirstPassTime ~= 0 then
      local nextCopyId = self.tabAllCopyId[copyId].nextCopyId
      if self.tabAllCopyId[nextCopyId] ~= nil and self.tabAllCopyId[nextCopyId].chapterId ~= chapterId then
        chapterId = self.tabAllCopyId[nextCopyId].chapterId
      end
    end
    for k, v in pairs(chaterConf) do
      if v.chapter_plot_type == classId then
        if chapterId >= v.id then
          table.insert(tabTemp, v)
        end
        table.insert(tabTempAll, v)
      end
    end
  else
    local chapterList = configManager.GetDataById("config_chapter_plot_type", classId).chapter_list
    for _, v in pairs(chapterList) do
      local chapterInfo = configManager.GetDataById("config_chapter", v)
      local copyInfo = Data.copyData:GetCopyInfoById(chapterInfo.level_list[1])
      if chapterInfo.chapter_plot_type == classId then
        if copyInfo ~= nil then
          table.insert(tabTemp, chapterInfo)
        end
        table.insert(tabTempAll, chapterInfo)
      end
    end
  end
  table.sort(tabTemp, function(a, b)
    return a.id < b.id
  end)
  table.sort(tabTempAll, function(a, b)
    return a.id < b.id
  end)
  local chapterList2 = configManager.GetDataById("config_chapter_plot_type", classId).chapter_list2
  local chapterPartList = chapterList2[partId]
  local partMap = {}
  for _, cId in pairs(chapterPartList) do
    partMap[cId] = cId
  end
  local tabPartTemp = {}
  local tabPartTempAll = {}
  for k, v in pairs(tabTemp) do
    if partMap[v.id] == v.id then
      table.insert(tabPartTemp, v)
    end
  end
  for k, v in pairs(tabTempAll) do
    if partMap[v.id] == v.id then
      table.insert(tabPartTempAll, v)
    end
  end
  return tabPartTemp, tabPartTempAll
end

function CopyLogic:GetAllPlotChapterInfoById(id)
  local chapterId, copyId, _ = self:GetLastChapterAndCopyById(id)
  local tabTemp = {}
  local chaterConf = configManager.GetData("config_chapter")
  for k, v in pairs(chaterConf) do
    if v.chapter_plot_type == id then
      table.insert(tabTemp, v)
    end
  end
  table.sort(tabTemp, function(a, b)
    return a.id < b.id
  end)
  return tabTemp
end

function CopyLogic:_CheckPlotCopyIsOpen(id)
  local period_Info = configManager.GetDataById("config_chapter", id).chapter_period
  if period_Info == nil or period_Info == 0 then
    return true
  end
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(period_Info)
  local now = time.getSvrTime()
  if startTime <= now and endTime >= now then
    return true
  end
  return false
end

function CopyLogic:GetLastChapterAndCopyById(classId)
  local chapterInfoList = configManager.GetDataById("config_chapter_plot_type", classId)
  if chapterInfoList and chapterInfoList.chapter_list then
    local list = chapterInfoList.chapter_list
    for i = 1, #list do
      local ispass, copyId = self:IsChapterPassByChapterId(list[i])
      if not ispass then
        return list[i], copyId, false
      end
    end
    local config_level = configManager.GetDataById("config_chapter", chapterInfoList.chapter_list[#list]).level_list
    return chapterInfoList.chapter_list[#list], config_level[#config_level], true
  end
end

function CopyLogic:CheckPlotClassCopyIsOpen(classId)
  local plot_type_config = configManager.GetDataById("config_chapter_plot_type", classId)
  local plot_StartTime = time.getIntervalByString(string.format("%d%02d%02d%02d%02d%02d", plot_type_config.p1, plot_type_config.p2, plot_type_config.p3, plot_type_config.p4, plot_type_config.p5, plot_type_config.p6))
  local timeNow = time.getSvrTime()
  if plot_StartTime > timeNow then
    return false
  end
  return true
end

function CopyLogic:FleetIsSweepingCopy(fleetId, fleetType)
  local sweeping = false
  if fleetType ~= FleetType.Normal then
    return sweeping, nil
  end
  local sweepInfo = Data.copyData:GetSweepCopyInfo()
  if sweepInfo ~= nil then
    for i = 1, #sweepInfo do
      if sweepInfo[i].fleetId == fleetId then
        sweeping = true
        return sweeping, sweepInfo[i]
      end
    end
  end
  return sweeping, nil
end

function CopyLogic:GetCopyTypeByChapterId(id)
  if id == nil then
    return nil, nil
  end
  local config = configManager.GetDataById("config_chapter", id)
  local copyType = 0
  if config == nil then
    return config, nil
  end
  if config.class_type == 9 then
    copyType = Logic.copyLogic.SelectCopyType.DailyCopy
  elseif config.class_type == 2 then
    copyType = Logic.copyLogic.SelectCopyType.SeaCopy
  end
  return config, copyType
end

function CopyLogic:GetFleetIsSweeping(fleetId)
  local sweepInfo = Data.copyData:GetSweepCopyInfo()
  if sweepInfo ~= nil then
    for i = 1, #sweepInfo do
      if fleetId == sweepInfo[i].fleetId then
        return true
      end
    end
  end
  return false
end

function CopyLogic:CurrentCopyIsSweeping(copyId)
  local isSweeping = false
  local sweepInfo = Data.copyData:GetSweepingCopyIds()
  if sweepInfo ~= nil then
    for i = 1, #sweepInfo do
      if sweepInfo[i] == copyId then
        isSweeping = true
      end
    end
  end
  return isSweeping
end

function CopyLogic:GetChapterIdByCopyId(copyId)
  if self.tabAllCopyId[copyId] ~= nil then
    return self.tabAllCopyId[copyId].chapterId
  elseif self.tabAllRunningCopyId[copyId] ~= nil then
    return self.tabAllRunningCopyId[copyId].chapterId
  end
  return nil
end

function CopyLogic:GetChatperFirshCopy(chapter)
  local sections = configManager.GetDataById("config_chapter", chapter).level_list
  if 0 < #sections then
    return sections[1]
  else
    logError("Copy Fatal:chapter:" .. chapter .. "not exist copy,Please Check chapter")
  end
end

function CopyLogic:GetInitChapterId(id)
  return configManager.GetDataById("config_parameter", id).value
end

function CopyLogic:GetInitChapterIdByType(chapterType)
  local activityTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  return activityTypeConfig.start_chapter
end

function CopyLogic:RecordAttackBeforeCopyData()
  local copyId = Data.copyData:GetFarestPlotCopyId()
  if copyId == 0 then
    self.plotchapterId = self:GetInitChapterId(12)
  else
    self.plotchapterId = self.tabAllCopyId[copyId].chapterId
  end
end

function CopyLogic:GetRecordCopyData()
  return self.plotchapterId
end

function CopyLogic:_editCopyDisplayConfig()
  for chapterId, chapterInfo in pairs(self.tabChapterConfig) do
    for i = 1, #chapterInfo.level_list do
      local nextId = 0
      if i < #chapterInfo.level_list then
        nextId = chapterInfo.level_list[i + 1]
      elseif chapterInfo.next_chapter ~= 0 then
        nextId = self.tabChapterConfig[chapterInfo.next_chapter].level_list[1]
      end
      self.tabAllCopyId[chapterInfo.level_list[i]] = {
        copyId = chapterInfo.level_list[i],
        nextCopyId = nextId,
        chapterId = chapterId
      }
    end
    for i = 1, #chapterInfo.treaty_copy do
      local nextId = 0
      self.tabAllCopyId[chapterInfo.treaty_copy[i]] = {
        copyId = chapterInfo.treaty_copy[i],
        nextCopyId = nextId,
        chapterId = chapterId
      }
    end
    for i = 1, #chapterInfo.running_level_list do
      local nextId = 0
      if i < #chapterInfo.running_level_list then
        nextId = chapterInfo.running_level_list[i + 1]
      elseif chapterInfo.next_chapter ~= 0 then
        nextId = self.tabChapterConfig[chapterInfo.next_chapter].running_level_list[1]
      end
      self.tabAllRunningCopyId[chapterInfo.running_level_list[i]] = {
        copyId = chapterInfo.running_level_list[i],
        nextCopyId = nextId,
        chapterId = chapterId,
        generalCopyId = chapterInfo.level_list[i]
      }
    end
    if (chapterInfo.class_type == ChapterType.TrainAdvance or chapterInfo.class_type == ChapterType.TrainLv) and 0 < chapterInfo.relation_chapter_id then
      local trainInfo = configManager.GetDataById("config_chapter_training", chapterInfo.training_chapter_id)
      if not table.empty(trainInfo.training_level_list) then
        local levelList = {}
        for i, group in ipairs(trainInfo.training_level_list) do
          for j, copyId in ipairs(group) do
            table.insert(levelList, copyId)
          end
        end
        local count = #levelList
        for i = 1, count do
          local nextId = 0
          if i < count then
            nextId = levelList[i + 1]
          end
          self.tabAllCopyId[levelList[i]] = {
            copyId = levelList[i],
            nextCopyId = nextId,
            chapterId = chapterId
          }
        end
      end
    end
    if chapterInfo.class_type == ChapterType.DailyCopy then
      self.tabDailyCopyId[chapterInfo.relation_chapter_id] = chapterId
    end
    if chapterInfo.class_type == ChapterType.Tower then
      self:_editCopyDisplayConfigTower(chapterInfo, chapterId)
    end
    if chapterInfo.class_type == ChapterType.TowerActivity then
      self:_editTowerActivity(chapterInfo, chapterId)
    end
    if chapterInfo.class_type == ChapterType.MubarCopy then
      table.insert(self.muborChapterConfig, chapterInfo)
    end
  end
  table.sort(self.muborChapterConfig, function(data1, data2)
    return data1.id < data2.id
  end)
end

function CopyLogic:_editTowerActivity(chapterInfo)
  local copyMap = self:ATowerGetCopyMap(chapterInfo)
  for copyId, v in pairs(copyMap) do
    self.tabAllCopyId[copyId] = {
      copyId = copyId,
      chapterId = chapterInfo.id
    }
  end
end

function CopyLogic:TowerGetCopyMapByChapter(chapterInfo)
  local copyMap = {}
  local copyId = chapterInfo.copy_list[1][1]
  self:TowerMultiSearch(copyMap, copyId)
  return copyMap
end

function CopyLogic:_editCopyDisplayConfigTower(chapterInfo, chapterId)
  local towerInfo = configManager.GetDataById("config_chapter_tower", chapterInfo.relation_chapter_id)
  local topicList = towerInfo.tower_topic
  for i = 1, #topicList do
    local topicId = topicList[i]
    local copyList = {}
    local themeConfig = configManager.GetDataById("config_tower_topic", topicId)
    if themeConfig.type == TowerType.Solo then
      local chapterNum = #themeConfig.copy_list
      for i = 1, chapterNum do
        for i, v in ipairs(themeConfig.copy_list[i]) do
          table.insert(copyList, v)
        end
      end
      for j = 1, #copyList do
        local copyId = copyList[j]
        local nextId = 0
        if i < #copyList then
          nextId = copyList[i + 1]
        end
        self.tabAllCopyId[copyId] = {
          copyId = copyId,
          nextCopyId = nextId,
          chapterId = chapterId
        }
      end
    else
      local copyMap = self:TowerGetCopyMapByTheme(themeConfig)
      for copyId, v in pairs(copyMap) do
        self.tabAllCopyId[copyId] = {copyId = copyId, chapterId = chapterId}
      end
    end
  end
end

function CopyLogic:TowerGetCopyMapByTheme(themeConfig)
  local copyMap = {}
  local copyId = themeConfig.copy_list[1][1]
  self:TowerMultiSearch(copyMap, copyId)
  return copyMap
end

function CopyLogic:TowerMultiSearch(copyMap, copyId)
  if not copyMap[copyId] then
    copyMap[copyId] = true
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    for i, v in ipairs(copyConfig.branch_copy) do
      self:TowerMultiSearch(copyMap, v)
    end
  end
end

function CopyLogic:ATowerGetCopyMap(chapterConfig)
  local copyMap = {}
  local copyId = chapterConfig.level_list[1]
  self:TowerMultiSearch(copyMap, copyId)
  return copyMap
end

function CopyLogic:_getFarestId(copyType)
  local copyId = 0
  local chapter = 0
  if copyType == ChapterType.PlotCopy then
    copyId = Data.copyData:GetFarestPlotCopyId()
  elseif copyType == ChapterType.SeaCopy then
    copyId = Data.copyData:GetFarestSeaCopyId()
  elseif copyType == ChapterType.Train then
    copyId = Data.copyData:GetFarestTrainCopyId()
  elseif copyType == ChapterType.TrainAdvance then
    copyId = Data.copyData:GetFarestTrainAdvCopyId()
  else
    copyId = Data.copyData:GetFarestCopyId(copyType)
  end
  if copyId == 0 then
    if copyType == ChapterType.PlotCopy then
      chapter = self:GetInitChapterId(12)
    elseif copyType == ChapterType.SeaCopy then
      chapter = self:GetInitChapterId(82)
    elseif copyType == ChapterType.Train then
      chapter = self:GetInitChapterId(112)
    elseif copyType == ChapterType.TrainAdvance then
      chapter = self:GetInitChapterId(113)
    else
      chapter = self:GetInitChapterIdByType(copyType)
    end
    copyId = self:GetChaperConfById(chapter).level_list[1]
    if copyType == ChapterType.TrainAdvance then
      copyId = Data.copyData:GetFirstAvailableTrainAdvCopyId() or 0
    end
  else
    local copyInfo
    if self.tabAllCopyId[copyId] == nil then
      logError("\229\156\168chapter\232\161\168\228\184\173\230\178\161\230\156\137\228\189\191\231\148\168copyId:", copyId)
    end
    chapter = self.tabAllCopyId[copyId].chapterId
    if copyType == ChapterType.PlotCopy then
      copyInfo = Data.copyData:GetPlotCopyDataCopyId(self.tabAllCopyId[copyId].nextCopyId)
    elseif copyType == ChapterType.SeaCopy then
      copyInfo = Data.copyData:GetCopyDataByCopyId(self.tabAllCopyId[copyId].nextCopyId)
    elseif copyType == ChapterType.Train then
      copyInfo = Data.copyData:GetTrainCopyDataCopyId(self.tabAllCopyId[copyId].nextCopyId)
    elseif copyType == ChapterType.TrainAdvance then
      copyInfo = Data.copyData:GetTrainAdvCopyDataCopyId(self.tabAllCopyId[copyId].nextCopyId)
    else
      copyInfo = Data.copyData:GetCopyInfoById(self.tabAllCopyId[copyId].nextCopyId)
    end
    if copyInfo ~= nil then
      copyId = self.tabAllCopyId[copyId].nextCopyId
      chapter = self.tabAllCopyId[copyId].chapterId
    end
  end
  return chapter, copyId
end

function CopyLogic:GetNewChapter()
  local passPlot, detail = Data.copyData:GetNewSeaDetail()
  if not detail or not passPlot then
    return false
  end
  local passPlotId = Data.copyData:GetFarestPlotCopyId()
  local info = self:GetCopyDesConfig(detail.BaseId)
  Data.copyData:ResetPassPlot()
  if info.sea_area_unlock == passPlotId then
    local chapterId = self:GetChapterIdByCopyId(detail.BaseId)
    local chapterInfo = self:GetChaperConfById(chapterId)
    if chapterInfo.level_list[1] == detail.BaseId then
      return true, chapterInfo
    end
  end
  return false
end

function CopyLogic:GetCopyData(copyType, copyId)
  if copyType == ChapterType.PlotCopy then
    return Data.copyData:GetPlotCopyDataCopyId(copyId)
  elseif copyType == ChapterType.SeaCopy then
    return Data.copyData:GetCopyDataByCopyId(copyId)
  elseif copyType == ChapterType.Train then
    return Data.copyData:GetTrainCopyDataCopyId(copyId)
  elseif copyType == ChapterType.TrainAdvance then
    return Data.copyData:GetTrainAdvCopyDataCopyId(copyId)
  end
  return nils
end

function CopyLogic:GetDisplayChapterId()
  local farestChapter, _ = Logic.copyLogic:GetCurSeaChapterSection()
  self.userInfo = Data.userData:GetUserData()
  self.uid = tostring(self.userInfo.Uid)
  local selectChapter = PlayerPrefs.GetInt(self.uid .. "SeaCopyPage" .. ChapterType.SeaCopy, farestChapter)
  return selectChapter ~= 0 and selectChapter or farestChapter, farestChapter
end

function CopyLogic:GetPlotCopyChapter(chapter, type)
  local levelTab = chapter.level_list
  local displayPage = 0
  local pageLevelInfo = {}
  for i = 1, #levelTab do
    local index = math.ceil(i / PLOT_COPY_MAX)
    if pageLevelInfo[index] == nil then
      pageLevelInfo[index] = {}
    end
    table.insert(pageLevelInfo[index], levelTab[i])
    if displayPage == 0 then
      local undone = self:_CheckUndoneId(levelTab[i], type)
      if undone then
        displayPage = index
      end
    end
  end
  local isOpenNew = displayPage ~= 0
  displayPage = displayPage == 0 and 1 or displayPage
  return pageLevelInfo, displayPage, isOpenNew
end

function CopyLogic:GetCurrDisplayPlotIndex()
  return self.currDisplayPlotIndex
end

function CopyLogic:SetCurrDisplayPlotIndex(index)
  self.currDisplayPlotIndex = index
end

function CopyLogic:_CheckUndoneId(id, type)
  local copyData = Data.copyData:GetCopyInfoById(id)
  if copyData == nil or copyData.FirstPassTime == 0 then
    return true
  end
  return false
end

function CopyLogic:MatchJoinByCopyId(copyId)
  self._MatchJoinCopyID = -1
  if self:CheckCopyIsMatch(copyId) then
    self._MatchJoinCopyID = self:GetCopyIdByCopy_DisplayId(copyId)
  end
  return self._MatchJoinCopyID
end

function CopyLogic:GetCopyIdByCopy_DisplayId(copyId)
  local copyConfig = configManager.GetMultiDataByKey("config_copy", "copy_id", copyId)
  for i, c in pairs(copyConfig) do
    if c.copy_id == copyId then
      return c.r_id
    end
  end
  logError("Can not find copyDisplayId by:", copyId)
  return 0
end

function CopyLogic:CheckCopyIsMatch(copyId)
  local copy_Config = configManager.GetDataById("config_copy_display", copyId)
  if copy_Config.is_match > 0 then
    return true
  end
  return false
end

function CopyLogic:GetFleetNum(copyId)
  return 4
end

function CopyLogic:CheckPlotChapterLock(ChapterId)
  local userLevel = Data.userData:GetUserData().Level
  local firstDisplayId = Logic.copyLogic:GetChatperFirshCopy(ChapterId)
  local config = Logic.copyLogic:GetCopyDesConfig(firstDisplayId)
  if userLevel < config.level_limit then
    return true, config.level_limit
  end
  return false, 0
end

function CopyLogic:CheckPlotChapterItemLock(ChapterId)
  local userLevel = Data.userData:GetUserData().Level
  local firstDisplayId = Logic.copyLogic:GetChatperFirshCopy(ChapterId)
  local config = Logic.copyLogic:GetCopyDesConfig(firstDisplayId)
  config = Data.copyData:GetCopyInfoById(firstDisplayId)
  if not config then
    return true
  end
  if config.Pass == true or config.FirstPassTime ~= nil and config.FirstPassTime >= 0 then
    return false
  end
  return true
end

function CopyLogic:DropInfoSort(tabTemp, descend)
  table.sort(tabTemp, function(data1, data2)
    local i = 0
    while i <= 0 do
      local state = self:SortHeroByQuailty(data1, data2, descend)
      if state == 0 then
        i = i + 1
      else
        return state == 2
      end
    end
  end)
  return tabTemp
end

function CopyLogic:SortHeroByQuailty(data1, data2, descend)
  return CopyLogic._SortImp(data1.quality, data2.quality, descend)
end

function CopyLogic._SortImp(data1, data2, descend)
  if descend then
    if data2 < data1 then
      return 2
    elseif data1 < data2 then
      return 1
    else
      return 0
    end
  elseif data1 < data2 then
    return 2
  elseif data2 < data1 then
    return 1
  else
    return 0
  end
end

function CopyLogic:GetTrainChapters()
  local trainChapters = {}
  local ctypes = {
    ChapterType.Train,
    ChapterType.TrainLv
  }
  local isTrainAdvShow = moduleManager:CheckFuncCanShow(FunctionID.TrainAdv)
  if isTrainAdvShow then
    table.insert(ctypes, ChapterType.TrainAdvance)
  end
  if XR:IsSupport() then
    table.insert(ctypes, ChapterType.AR)
  end
  local userLevel = Data.userData:GetUserLevel()
  for i, c in pairs(self.tabChapterConfig) do
    if table.containV(ctypes, c.class_type) then
      local chapter = clone(c)
      local chapterTrain = configManager.GetDataById("config_chapter_training", chapter.relation_chapter_id)
      local chapterData = Data.copyData:GetChapterDataById(chapter.id)
      if c.class_type == ChapterType.TrainLv then
        local total = 0
        for i, g in ipairs(chapterTrain.training_level_list) do
          total = total + #g
        end
        chapter.totalLevels = total
      else
        chapter.totalLevels = #chapter.level_list
      end
      chapter.passNum = chapterData and chapterData.PassNum or 0
      chapter.totalStars = chapter.totalLevels * 3
      chapter.starNum = chapterData and chapterData.StarNum or 0
      chapter.rank = chapterData and chapterData.Rank and chapterData.Rank / 10000 or 0
      chapter.training_reward_show = chapterTrain.training_reward_show
      chapter.star_need = chapterTrain.star_need
      chapter.star_reward = chapterTrain.star_reward
      chapter.training_level_list = chapterTrain.training_level_list
      chapter.training_level_name_list = chapterTrain.training_level_name_list
      local firstCopyId = chapter.level_list[1]
      local lastCopyId = chapter.level_list[#chapter.level_list]
      chapter.isOpen = userLevel >= chapterTrain.open_level
      if c.class_type == ChapterType.Train then
        chapter.isFinish = chapter.passNum == chapter.totalLevels
      elseif c.class_type == ChapterType.TrainAdvance then
        chapter.isFinish = chapter.starNum == chapter.totalStars
      elseif c.class_type == ChapterType.TrainLv then
        chapter.isFinish = chapter.passNum == chapter.totalLevels
      elseif c.class_type == ChapterType.AR then
        chapter.isFinish = false
      end
      table.insert(trainChapters, chapter)
    end
  end
  table.sort(trainChapters, function(l, r)
    if l.isOpen ~= r.isOpen then
      if l.isOpen and not r.isOpen then
        return true
      else
        return false
      end
    else
      return l.id < r.id
    end
  end)
  return trainChapters
end

function CopyLogic:IsCopyOpen(copyId, copyType)
  local datas
  if copyType == ChapterType.PlotCopy then
    datas = Data.copyData:GetPlotCopyServiceData()
  elseif copyType == ChapterType.SeaCopy then
    datas = Data.copyData:GetCopyServiceData()
  elseif copyType == ChapterType.Train then
    datas = Data.copyData:GetTrainServiceData()
  elseif copyType == ChapterType.TrainAdvance then
    datas = Data.copyData:GetTrainAdvServiceData()
  elseif copyType == ChapterType.TrainLv then
    datas = Data.copyData:GetTrainLvServiceData()
  end
  local isOpen = false
  for id, copyData in pairs(datas) do
    if copyData.BaseId == copyId then
      isOpen = true
      break
    end
  end
  return isOpen
end

function CopyLogic:IsCopyOpenById(copyId)
  if not self:CheckOpenByCopyId(copyId) then
    return false
  end
  local data = Data.copyData:GetCopyInfoById(copyId)
  return data ~= nil
end

function CopyLogic:IsCopyPassById(copyId)
  local data = Data.copyData:GetCopyInfoById(copyId)
  if data then
    return data.FirstPassTime > 0
  end
  return false
end

function CopyLogic:GetTrainLevels(chapterId)
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local isAdvance = chapter.class_type == ChapterType.TrainAdvance
  local copyIds = chapter.level_list
  local levelDatas = {}
  local lastOpenId, serviceDatas
  if isAdvance then
    serviceDatas = Data.copyData:GetTrainAdvServiceData()
  else
    serviceDatas = Data.copyData:GetTrainServiceData()
  end
  local displayData, serviceData
  for i, copyId in ipairs(copyIds) do
    displayData = clone(configManager.GetDataById("config_copy_display", copyId))
    serviceData = serviceDatas[copyId]
    if serviceData then
      for k, v in pairs(serviceData) do
        displayData[k] = v
      end
      displayData.locked = false
    else
      displayData.StarNum = 0
      displayData.Pass = false
      displayData.locked = true
    end
    table.insert(levelDatas, displayData)
  end
  return levelDatas
end

function CopyLogic:GetTrainLvLevels(chapterId)
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local chapterTrain = configManager.GetDataById("config_chapter_training", chapter.relation_chapter_id)
  local levelList = chapterTrain.training_level_list
  local levelDatas = {}
  local serviceDatas = Data.copyData:GetTrainLvServiceData()
  local level_list = chapterTrain.training_level_list
  local name_list = chapterTrain.training_level_name_list
  for i, group in ipairs(level_list) do
    local g = {}
    g.Name = name_list[i]
    g.CopyList = {}
    local passCount = 0
    for k, copyId in ipairs(group) do
      local displayData = clone(configManager.GetDataById("config_copy_display", copyId))
      local serviceData = serviceDatas[copyId]
      displayData.Locked = serviceData == nil
      if serviceData then
        for k, v in pairs(serviceData) do
          displayData[k] = v
        end
        passCount = passCount + 1
      end
      table.insert(g.CopyList, displayData)
    end
    g.PassCount = passCount
    table.insert(levelDatas, g)
  end
  return levelDatas
end

function CopyLogic:GetStarRewardDatas(chapterId)
  local datas = {}
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local chapterTrain = configManager.GetDataById("config_chapter_training", chapter.relation_chapter_id)
  local chapterData = Data.copyData:GetChapterDataById(chapter.id)
  if chapter.class_type ~= ChapterType.TrainAdvance then
    return
  end
  local rewardLevels = chapterTrain.star_need
  local rewards = chapterTrain.star_reward
  local starNum = chapterData and chapterData.StarNum or 0
  for i, starNeed in ipairs(rewardLevels) do
    local data = {}
    data.starNum = starNum
    data.starNeed = starNeed
    if starNeed > starNum then
      data.state = RewardState.UnReceivable
    else
      local received = false
      if chapterData then
        for k, v in pairs(chapterData.StarReward) do
          if v.Index == i and 0 < v.RewardTime then
            received = true
            break
          end
        end
      end
      data.state = received and RewardState.Received or RewardState.Receivable
    end
    data.index = i
    data.rewards = Logic.rewardLogic:FormatRewardById(rewards[i])
    table.insert(datas, data)
  end
  table.sort(datas, function(l, r)
    if l.state == r.state then
      return l.index < r.index
    end
    return l.state < r.state
  end)
  return datas
end

function CopyLogic:GetTargetStars(chapterId, curStars)
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local chapterTrain = configManager.GetDataById("config_chapter_training", chapter.relation_chapter_id)
  for i, target in ipairs(chapterTrain.star_need) do
    if curStars < target then
      return target
    end
  end
  return curStars
end

function CopyLogic:CheckAnyShips(heroIds, callback)
  local hasShip = 0 < #heroIds
  if callback then
    callback(hasShip)
  end
  return hasShip
end

function CopyLogic:CheckFlagShipDamage(heroIds, callback, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroIds[1])
  local heroHpPer = Logic.repaireLogic:HeroHpShow(heroInfo, fleetType)
  local maxPo, minPo = Logic.copyLogic:GetBattleConfig()
  local heavyDamage = heroHpPer >= minPo and heroHpPer <= maxPo
  if callback then
    callback(heavyDamage)
  end
  return heavyDamage
end

function CopyLogic:CheckDockFull(callback)
  local dockFull = Logic.dockLogic:IsReachMax()
  if callback then
    callback(dockFull)
  end
  return dockFull
end

function CopyLogic:CheckEquipBagFull(callback)
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  local isFull = size >= equipSize
  if callback then
    callback(isFull)
  end
  return isFull
end

function CopyLogic:CheckAnyShipDamage(heroIds, callback, fleetType, isMain)
  local heavyDamage = false
  local maxPo, minPo = Logic.copyLogic:GetBattleConfig()
  local count = #heroIds
  local startIdx = 2
  if not isMain then
    startIdx = 1
  end
  for i = startIdx, count do
    local hero = Data.heroData:GetHeroById(heroIds[i])
    local heroHpPercentage = Logic.repaireLogic:HeroHpShow(hero, fleetType)
    if minPo <= heroHpPercentage and maxPo >= heroHpPercentage then
      heavyDamage = true
      break
    end
  end
  if callback then
    callback(heavyDamage)
  end
  return heavyDamage
end

function CopyLogic:GetTrainStrategyIds(copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  local strategyTable = copyDisplay.training_strategy
  local strategyIds = {}
  for i, s in pairs(strategyTable) do
    strategyIds[s[1]] = s[2]
  end
  return strategyIds
end

function CopyLogic:CheckShipSink(heroIds, callback)
  local heavySink = false
  local count = #heroIds
  for i = 1, count do
    local hero = Data.heroData:GetHeroById(heroIds[i])
    if hero.CurHp <= 0 then
      heavySink = true
      break
    end
  end
  if callback then
    callback(heavySink)
  end
  return heavySink
end

function CopyLogic:GetActConfig(chapterId)
  local chapterConf = configManager.GetDataById("config_chapter", chapterId)
  local actChapterId = chapterConf.relation_chapter_id
  local actCopyConfig = configManager.GetDataById("config_big_activity_chapter", actChapterId)
  return actCopyConfig
end

function CopyLogic:GetActLevelConf(levelId)
  local displayInfo = {}
  local displayInfo = configManager.GetDataById("config_copy_display", levelId)
  local actInfo = configManager.GetDataById("config_big_activity_copy_display", displayInfo.big_activity_copy_display_id)
  for k, v in pairs(actInfo) do
    if displayInfo[k] == nil then
      displayInfo[k] = v
    end
  end
  return displayInfo
end

function CopyLogic:GetCopyChapter(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  if chapterId then
    return configManager.GetDataById("config_chapter", chapterId)
  end
  return nil
end

function CopyLogic:IsTrainCopy(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local isTrain = false
  if chapterId then
    local chapter = configManager.GetDataById("config_chapter", chapterId)
    if chapter and chapter.class_type >= ChapterType.Train and chapter.class_type <= ChapterType.TrainLv then
      isTrain = true
    end
  end
  return isTrain
end

function CopyLogic:GetPreChapterName(chapterId)
  local chapters = configManager.GetData("config_chapter")
  for i, chapter in pairs(chapters) do
    if chapter.next_chapter == chapterId then
      return chapter.name
    end
  end
  return ""
end

function CopyLogic:GetChapterTypeByCopyId(copyId)
  local chapterConfig = self:GetChapterByCopyId(copyId)
  return chapterConfig.class_type
end

function CopyLogic:GetChapterByCopyId(copyId)
  if self.tabAllCopyId[copyId] == nil then
    logError("copyDisplayId\229\156\168chapter\232\161\168\228\184\173\230\178\161\230\156\137\229\188\149\231\148\168 copyDisplayId =", copyId)
  end
  return configManager.GetDataById("config_chapter", self.tabAllCopyId[copyId].chapterId)
end

function CopyLogic:GetNameByCopyId(copyId)
  local copyDisplayConfig = configManager.GetDataById("config_copy_display", copyId)
  local chapterInfo = self:GetChapterByCopyId(copyId)
  return chapterInfo.class_name .. copyDisplayConfig.str_index
end

function CopyLogic:GetFullNameById(copyId)
  local copyDisplayConfig = configManager.GetDataById("config_copy_display", copyId)
  if copyDisplayConfig.full_name == "" then
    logError("full is nil, copyDisplayId:", copyId)
  end
  return copyDisplayConfig.full_name
end

function CopyLogic:SetTrainLvGroup(groupIndex)
  self.lastGroupIndex = groupIndex
end

function CopyLogic:GetTrainLvGroup()
  return self.lastGroupIndex
end

function CopyLogic:SetTrainIndex(index)
  self.trainIndex = index
end

function CopyLogic:GetTrainIndex()
  return self.trainIndex
end

function CopyLogic:GetNewTrainChapter()
  local copy = Data.copyData:GetNewPassTrainCopy()
  copy = copy or Data.copyData:GetNewPassTrainAdvCopy()
  if not copy then
    return false
  end
  local chapterId = self:GetChapterIdByCopyId(copy.BaseId)
  if chapterId then
    local chapterInfo = self:GetChaperConfById(chapterId)
    local count = #chapterInfo.level_list
    if chapterInfo.level_list[count] == copy.BaseId then
      local nextChapter = self:GetChaperConfById(chapterInfo.next_chapter)
      Data.copyData:SetNewPassTrainCopy(nil)
      Data.copyData:SetNewPassTrainAdvCopy(nil)
      return true, nextChapter
    end
  end
  return false
end

function CopyLogic:_OnGetARBattleResult(win)
  if win then
    Service.taskService:SendTaskTrigger(TaskKind.ARBATTLEWIN)
  end
  self:UnRegisterARBattleResult()
end

function CopyLogic:RegisterARBattleResult()
  if eventManager:HaveListener(LuaCSharpEvent.ARBattleResult) then
    self:UnRegisterARBattleResult()
  end
  eventManager:RegisterEvent(LuaCSharpEvent.ARBattleResult, self._OnGetARBattleResult, self)
end

function CopyLogic:UnRegisterARBattleResult()
  eventManager:UnregisterEvent(LuaCSharpEvent.ARBattleResult, self._OnGetARBattleResult)
end

function CopyLogic:QuickToChapter(chapterId, index)
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  if chapter.class_type == ChapterType.TrainLv then
    Logic.copyLogic:SetTrainLvGroup(index)
  end
  UIHelper.OpenPage("TrainLevelPage", {chapter = chapter})
end

function CopyLogic:ShowRandFactorsNew(key)
  local show = true
  local setValue = Data.guideData:GetSettingByKey(key)
  if setValue then
    show = false
  end
  return show
end

function CopyLogic:GetCopyRecommend(copyId)
  local copyInfo = self:GetCopyDesConfig(copyId)
  local recommend = {}
  local recommendFleet = copyInfo.recommend
  if #recommendFleet == 0 then
    recommend.Tactic = {}
    return recommend
  end
  local TacticTab = {}
  local temp = {}
  for position, shipId in ipairs(recommendFleet) do
    local ship = npcAssistFleetMgr:CreateNpcShip4Battle(shipId, position)
    TacticTab[position] = {}
    TacticTab[position].Tid = ship.TemplateId
    TacticTab[position].Level = ship.Level
    TacticTab[position].AdvLevel = ship.Advance
    TacticTab[position].CurHp = 1
    local equipMap = {}
    for i, v in ipairs(ship.Equips) do
      equipMap[v.EquipIndex] = v
    end
    local EquipTab = {}
    for i = 1, 6 do
      EquipTab[i] = {}
      EquipTab[i].Tid = equipMap[i] and equipMap[i].EquipTid or 0
      EquipTab[i].Level = equipMap[i] and equipMap[i].EquipLv or 0
      EquipTab[i].StarLv = equipMap[i] and math.floor(equipMap[i].EquipLv % 5 == 0 and equipMap[i].EquipLv / 5 - 1 or equipMap[i].EquipLv / 5) or 0
    end
    TacticTab[position].Equip = EquipTab
  end
  recommend.Tactic = TacticTab
  recommend.Uname = UIHelper.GetString(1430032)
  recommend.StrategyId = copyInfo.recommend_tactics
  return recommend
end

function CopyLogic:DailyChapterId2ChapterId(dailyChapterId)
  return self.tabDailyCopyId[dailyChapterId]
end

function CopyLogic:GetCurrSafeConfig(stageId, lv, point, isDetail)
  local configInfo = {}
  point = point and point or 0
  lv = lv == 0 and 1 or lv
  local stageConfig = configManager.GetDataById("config_stage", stageId)
  local safeConfig = configManager.GetDataById("config_safearea", lv)
  local _, sliderValue = self:GetSafeCurrProgress(stageConfig, lv, point)
  configInfo.sliderValue = sliderValue
  configInfo.levelId = safeConfig.id
  configInfo.name = safeConfig.desc
  if not isDetail then
    configInfo.sliderImage = safeConfig.slider_image
    configInfo.nameColor = safeConfig.copy_text_color
  else
    configInfo.sliderImage = safeConfig.small_slider_image
    configInfo.nameColor = safeConfig.text_color
  end
  configInfo.effect_outline_color = safeConfig.effect_outline_color
  return configInfo
end

function CopyLogic:IsSafeArea(stageId, lv, point, isDetail)
  local config = self:GetCurrSafeConfig(stageId, lv, point, isDetail)
  return config.sliderValue > 0.9999999 and config.levelId == 7
end

function CopyLogic:GetSafeCurrProgress(stageConfig, lv, point)
  local currIndex = 0
  local sliderValue = 0
  for i, v in ipairs(stageConfig.safe_area) do
    if v == lv then
      currIndex = i
    end
  end
  if currIndex ~= #stageConfig.safe_area then
    point = point - stageConfig.safe_area_score[currIndex]
    local currMaxSafe = stageConfig.safe_area_score[currIndex + 1] - stageConfig.safe_area_score[currIndex]
    sliderValue = point / currMaxSafe
  else
    sliderValue = 1
  end
  return currIndex, sliderValue
end

function CopyLogic:IsDirectOpenSafeArea()
  return configManager.GetDataById("config_parameter", 181).value == 1
end

function CopyLogic:ShowSafeUpEff(baseId)
  if baseId == self.attackSafeInfo.CopyId then
    local copyInfo = Data.copyData:GetCopyInfoById(self.attackSafeInfo.CopyId)
    if self.attackSafeInfo.SfLv < copyInfo.SfLv then
      return true
    end
  end
  return false
end

function CopyLogic:GetLastAttackSafeInfo()
  local result = self.attackSafeInfo
  self.attackSafeInfo = {}
  return result
end

function CopyLogic:GetSafeUpEff(sfLv)
  local safeConfig = configManager.GetDataById("config_safearea", sfLv)
  return safeConfig.levelup_effect, safeConfig.change_time / 10000
end

function CopyLogic:ClearSafeInfo()
  self.attackSafeInfo = {}
end

function CopyLogic:GetSafeEffectDispId(copyId)
  local copyDisplayConf = self:GetCopyDesConfig(copyId)
  if copyDisplayConf.stageid <= 0 then
    return copyId
  end
  local dispId = 0
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local sfLv = copyData.SfLv
  local stageConf = configManager.GetDataById("config_stage", copyDisplayConf.stageid)
  for m, effectList in ipairs(stageConf.safe_effect) do
    if 0 < #effectList then
      for _, effectId in ipairs(effectList) do
        if 0 < effectId then
          local effectConf = configManager.GetDataById("config_safearea_effect", effectId)
          if effectConf.type == SafeEffectType.Copy then
            dispId = effectConf.p2
            break
          end
        end
      end
    end
    if sfLv == stageConf.safe_area[m] or 0 < dispId then
      break
    end
  end
  if dispId == 0 then
    return copyId
  end
  return dispId
end

function CopyLogic:GetCopyIdByRunningCopyId(rCopyId)
  if self.tabAllCopyId[rCopyId] ~= nil then
    return self.tabAllCopyId[rCopyId].copyId
  elseif self.tabAllRunningCopyId[rCopyId] ~= nil then
    return self.tabAllRunningCopyId[rCopyId].generalCopyId
  end
  return nil
end

function CopyLogic:GetCopyDropShip(chapterId, mode)
  local copySerData = Data.copyData:GetCopyInfo()
  local chapterConf = self:GetChaperConfById(chapterId)
  local battleCopyId = 0
  for i, v in ipairs(chapterConf.level_list) do
    if copySerData[v] == nil then
      battleCopyId = v
    end
  end
  if battleCopyId == 0 then
    return
  end
  local displayConfig = self:GetCopyDesConfig(battleCopyId)
  if not displayConfig then
    return
  end
  local dropShipTab = {}
  if displayConfig.drop_sr_shipid ~= 0 then
    local info = {}
    info.shipBg = QualityIcon[HeroRarityType.SR]
    info.shipIcon = Logic.shipLogic:GetIcon(displayConfig.drop_sr_shipid)
    info.shipName = Logic.shipLogic:GetName(displayConfig.drop_sr_shipid)
    info.nameColor = "5106C3"
    info.copyIndex = self:GetCopyDesConfig(displayConfig.drop_sr_copydisplayid).str_index
    table.insert(dropShipTab, info)
  end
  if displayConfig.drop_ssr_shipid ~= 0 and copySerData[displayConfig.drop_ssr_copydisplayid] == nil then
    local info = {}
    info.shipBg = QualityIcon[HeroRarityType.SSR]
    info.shipIcon = Logic.shipLogic:GetIcon(displayConfig.drop_ssr_shipid)
    info.shipName = Logic.shipLogic:GetName(displayConfig.drop_ssr_shipid)
    info.nameColor = "FCC714"
    info.copyIndex = self:GetCopyDesConfig(displayConfig.drop_ssr_copydisplayid).str_index
    table.insert(dropShipTab, info)
  end
  return dropShipTab
end

function CopyLogic:SeaCopyBoxById(chapterId)
  local chapterStar = Data.copyData:GetChapterStar(chapterId)
  local config = Logic.copyLogic:GetChaperConfById(chapterId)
  local star_reward = config.star_reward
  local star_cond = config.star_cond
  local len = #star_reward
  local num = 0
  for index = 1, len do
    local status = Data.copyData:GetRewardBoxStatus(chapterId, index)
    if chapterStar >= star_cond[index] and status == false then
      num = num + 1
    end
  end
  return num
end

function CopyLogic:GetFarestId(chapterType)
  return self:_getFarestId(chapterType)
end

function CopyLogic:CheckOpenByCopyId(copyId, isNoti)
  local chapterId = self:GetChapterIdByCopyId(copyId)
  return Logic.copyChapterLogic:CheckAllByChapterId(chapterId, isNoti)
end

function CopyLogic:GetTacticType(chapterId)
  return configManager.GetDataById("config_chapter", chapterId).tactic_type or 1
end

function CopyLogic:GetClassType(chapterId)
  return configManager.GetDataById("config_chapter", chapterId).class_type or 0
end

function CopyLogic:GetCopySafeInfo(copyId)
  local config = self:GetCopyDesConfig(copyId)
  local serData = Data.copyData:GetCopyInfoById(copyId)
  local safeLv = config.stageid == 0 and 0 or serData.SfLv
  local safePoint = config.stageid == 0 and 0 or serData.SfPoint
  return safeLv, safePoint
end

function CopyLogic:MakeDefaultCopyInfo(copyId)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  if copyData then
    return copyData
  end
  local result = {}
  result.Rid = 0
  result.StarLevel = 0
  result.BaseId = copyId
  result.IsRunningFight = false
  result.SfPoint = 0
  result.SfInfo = {}
  result.SfLv = 0
  result.FirstPassTime = 0
  result.LBPoint = 0
  result.DropHeroIds = {}
  result.IsFake = true
  return result
end

function CopyLogic:GetShortTitle(copyId)
  local res = ""
  local chapter = self:GetCopyChapter(copyId)
  if chapter then
    res = chapter.class_name
  end
  local copy = self:GetCopyDConfigById(copyId)
  if copy then
    res = res .. " " .. copy.str_index
  end
  return res
end

function CopyLogic:GetCopyDConfigById(copyId)
  return configManager.GetDataById("config_copy_display", copyId)
end

function CopyLogic:GetFleetTypeById(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  return chapterConfig.tactic_type
end

function CopyLogic:DisplayChapterBelong(chapterType)
  self.belongChapterTab = {}
  for _, v in pairs(self.tabChapterConfig) do
    if v.class_type == chapterType and next(v.belong_chapter_list) ~= nil then
      self.belongChapterTab[v.id] = {}
      for i, j in ipairs(v.belong_chapter_list) do
        local copyInfo = Logic.copyLogic:GetChaperConfById(j)
        table.insert(self.belongChapterTab[v.id], i, copyInfo)
      end
    end
  end
end

function CopyLogic:GetChapterBelong(chapterId)
  return self.belongChapterTab[chapterId]
end

function CopyLogic:SetCurrBattleMode(copyType, mode)
  self.currBattleType[copyType] = mode
end

function CopyLogic:GetCurrBattleMode(copyType)
  return self.currBattleType[copyType] == nil and 0 or self.currBattleType[copyType]
end

function CopyLogic:CheckIsDay(copyType)
  if next(self.currBattleType) and self.currBattleType[copyType] then
    return self.currBattleType[copyType] == SeaCopyStage.Day
  end
  return false
end

function CopyLogic:GetBattleModeChapter(chapterType, mode)
  local copySerData = Data.copyData:GetCopyInfo()
  local seaChapterId = {}
  for _, v in pairs(self.tabChapterConfig) do
    if v.class_type == chapterType and mode == v.chapter_type then
      local copyInfo = Logic.copyLogic:GetChaperConfById(v.id)
      if copySerData[copyInfo.level_list[1]] ~= nil then
        table.insert(seaChapterId, v.id)
      end
    end
  end
  table.sort(seaChapterId, function(a, b)
    return a < b
  end)
  return seaChapterId
end

function CopyLogic:GetTypeInfoById(modeId)
  return configManager.GetDataById("config_chapter_type_info", modeId)
end

function CopyLogic:GetNeedChapterId(currId, allChapterId, isNext)
  local currIndex = 0
  for i, v in ipairs(allChapterId) do
    if currId == v then
      currIndex = i
    end
  end
  local needIndex = isNext and currIndex + 1 or currIndex - 1
  if needIndex <= 0 or needIndex > #allChapterId then
    logError("not exit chapter id: ", needIndex)
    return currId
  else
    return allChapterId[needIndex]
  end
end

function CopyLogic:GetChapterIndexMode(index, chapterId)
  local chapterInfo = self:GetChaperConfById(chapterId)
  if #chapterInfo.belong_chapter_list == 0 then
    return index
  end
  local newChapterId = chapterInfo.belong_chapter_list[index + 1]
  local newChapterInfo = self:GetChaperConfById(newChapterId)
  return newChapterInfo.chapter_type
end

function CopyLogic:SetCopyBgPos(chapterId, pos)
  if Logic.copyLogic:GetUserCurStatus() then
    local copySerInfo = Data.copyData:GetCopyInfoById(self.tabSaveAttackCopyInfo.CopyId)
    if copySerInfo.FirstPassTime ~= 0 then
      return
    end
  end
  if chapterId == nil then
    self.copyBgPos = {}
    return
  end
  self.copyBgPos[chapterId] = pos
end

function CopyLogic:GetCopyBgPos(chapterId)
  if self.copyBgPos[chapterId] == nil then
    return Vector3.New(0, 0, 0)
  end
  return self.copyBgPos[chapterId]
end

function CopyLogic:GetChapterIdByMode(chapterId, modeType)
  local chapterTab = Logic.copyLogic:GetChaperConfById(chapterId)
  for _, v in ipairs(chapterTab.belong_chapter_list) do
    local chapterInfo = self:GetChaperConfById(v)
    if chapterInfo.chapter_type == modeType then
      return v
    end
  end
  return 0
end

function CopyLogic:IsChapterPassByChapterId(chapterId)
  local config_level = configManager.GetDataById("config_chapter", chapterId).level_list
  if config_level then
    for i = 1, #config_level do
      if not self:IsCopyPassById(config_level[i]) then
        return false, config_level[i]
      end
    end
  end
  return true, nil
end

function CopyLogic:SetMubarCopyOutpostSelectedIndex(chapterId)
  self.MubarCopyOutpostSelectedIndex = chapterId
end

function CopyLogic:GetMubarCopyOutpostSelectedIndex()
  return self.MubarCopyOutpostSelectedIndex
end

function CopyLogic:SetInNew(valid)
  if Logic.copyLogic:GetUserCurStatus() then
    return
  end
  self.inNewChapter = valid
end

function CopyLogic:CheckInNew()
  return self.inNewChapter
end

function CopyLogic:CheckPatrolOpenRecord(chapterId)
  local uid = Data.userData:GetUserUid()
  local isRecord = PlayerPrefs.GetBool("PatrolChapterOpen" .. uid .. chapterId, false)
  if not isRecord then
    return true
  end
  return false
end

function CopyLogic:RecordPatrolOpen(chapterId)
  local uid = Data.userData:GetUserUid()
  local isRecord = PlayerPrefs.GetBool("PatrolChapterOpen" .. uid .. chapterId, false)
  if not isRecord then
    PlayerPrefs.SetBool("PatrolChapterOpen" .. uid .. chapterId, true)
  end
end

function CopyLogic:SetCurCopyPlotId(copyId)
  self.plotCopyId = copyId
end

function CopyLogic:GetCurCopyPlotId()
  return self.plotCopyId
end

function CopyLogic:SetBBattleAttack(value)
  self.BBattleAttack = value
end

function CopyLogic:GetBBattleAttack()
  return self.BBattleAttack
end

function CopyLogic:CheckJumpPlotDetails()
  return self.jumpPlotDetailsId
end

function CopyLogic:SetJumpPlotDetails(id)
  self.jumpPlotDetailsId = id
end

function CopyLogic:IsAssistFleet(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  if copyConfig.use_assist_mode == 0 or nil then
    return false
  else
    return true
  end
end

function CopyLogic:GetMubarChapterConfig()
  return self.muborChapterConfig
end

function CopyLogic:CheckChapterIsOpen(chapterId)
  local chapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  local copySerData = Data.copyData:GetCopyInfo()
  return copySerData[chapterConfig.level_list[1]] ~= nil
end

function CopyLogic:GetMatchCopyType(copyId)
  local type = -1
  local copy_displayConfig = configManager.GetDataById("config_copy", copyId)
  if copy_displayConfig ~= nil then
    if copy_displayConfig.match_player_num and copy_displayConfig.match_player_num > 0 then
      type = copy_displayConfig.match_type
    end
  else
    type = 0
  end
  return type
end

function CopyLogic:GetOtherCopyMode(chapterId)
  local chapterModelId = configManager.GetDataById("config_chapter", chapterId).belong_chapter_list
  for _, v in ipairs(chapterModelId) do
    local mode = configManager.GetDataById("config_chapter", v).chapter_type
    if mode ~= ChildChapterType.Day and mode ~= ChildChapterType.New then
      return true
    end
  end
  return false
end

function CopyLogic:IsGuildWarCopy(chapterInfo)
  if chapterInfo and chapterInfo.class_type and chapterInfo.class_type == ChapterType.GuildWarCopy then
    return true
  end
  return false
end

function CopyLogic:SetSeaCopyActivityToggle(Tog)
  self.SeaCopyActivityToggle = Tog
end

function CopyLogic:GetSeaCopyActivityToggle()
  return self.SeaCopyActivityToggle
end

function CopyLogic:SetSeaCopyActivityToggleLast(Tog)
  self.SeaCopyActivityToggleLast = Tog
end

function CopyLogic:GetSeaCopyActivityToggleLast()
  return self.SeaCopyActivityToggleLast
end

function CopyLogic:IsCurrCopyNvN()
  local copyId = self.m_curCopyId
  local displayData = configManager.GetDataById("config_copy_display", copyId)
  return displayData.max_fleet > 0
end

function CopyLogic:IsInCopy()
  logError("curr copy id:" .. self.m_curCopyId)
  return self.m_curCopyId > 0
end

function CopyLogic:SetTempAnimMode(mode)
  logError("SetTempAnimMode:" .. mode)
  self.tempAnimMode = mode
end

function CopyLogic:GetTempAnimMode()
  logError("GetTempAnimMode:" .. self.tempAnimMode)
  return self.tempAnimMode
end

function CopyLogic:GetNvNRandFactors(buffList, bid)
  local buffShow = {}
  for _, b_id in pairs(buffList) do
    local tmp = {
      Factors = {b_id},
      GroupId = b_id,
      SetId = b_id
    }
    table.insert(buffShow, tmp)
  end
  local index = 0
  for i, f in pairs(buffShow) do
    if bid == f.SetId then
      index = i
    end
  end
  return buffShow, index
end

function CopyLogic:GetCurCopyId()
  return self.m_curCopyId
end

function CopyLogic:SetCurCopyId(_copyid)
  self.m_curCopyId = _copyid
end

return CopyLogic
