local TowerLogic = class("logic.TowerLogic")
local buffDes = {
  [1] = 1703001,
  [2] = 1703002,
  [3] = 1703002
}

function TowerLogic:initialize()
  self.chapterTable = {}
  self.towerEquipFlag = {}
  self.towerHurtFlag = {}
  self.towerRoad = nil
  self:initChapterTable()
end

function TowerLogic:SetTowerRoadPos(value)
  self.towerRoad = value
end

function TowerLogic:GetTowerRoadPos()
  return self.towerRoad
end

function TowerLogic:SetTowerEquipFlag(_bool, fleetType)
  self.towerEquipFlag[fleetType] = _bool
end

function TowerLogic:GetTowerEquipFlag(fleetType)
  return self.towerEquipFlag[fleetType]
end

function TowerLogic:SetTowerHurtFlag(_bool, fleetType)
  self.towerHurtFlag[fleetType] = _bool
end

function TowerLogic:GetTowerHurtFlag(fleetType)
  return self.towerHurtFlag[fleetType]
end

function TowerLogic:SetTowerCamera(camera)
  self.camera = camera
end

function TowerLogic:GetTowerCamera()
  return self.camera
end

function TowerLogic:SetTowerCamera(camera)
  self.camera = camera
end

function TowerLogic:GetTowerCamera()
  return self.camera
end

function TowerLogic:FormatThemeIndex(themeIndex, themeLen)
  local themeIndex = math.fmod(themeIndex + 1, themeLen)
  if themeIndex == 0 then
    themeIndex = themeLen
  end
  return themeIndex
end

function TowerLogic:IsCopyMax()
  local towerData = Data.towerData:GetData()
  if not towerData or not towerData.ChapterId then
    return false
  end
  return towerData.PassLastChapterId > 0
end

function TowerLogic:IsChapterMax()
  local towerData = Data.towerData:GetData()
  if not towerData or not towerData.ChapterId then
    return false
  end
  return towerData.ChapterId == self.chapterMax
end

function TowerLogic:GetChapterMax()
  local towerData = Data.towerData:GetData()
  if not towerData or not towerData.ChapterId then
    return 0
  end
  return self.chapterMax
end

function TowerLogic:initChapterTable()
  local chapterIdPre = 0
  local chapterIdNext = 0
  local chapterId = self:GetInitChapterId()
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  chapterIdNext = chapterConfig.next_chapter
  local chapterInfo = {}
  chapterInfo.chapterIdPre = chapterIdPre
  chapterInfo.chapterIdNext = chapterIdNext
  self.chapterTable[chapterId] = chapterInfo
  while 0 < chapterIdNext do
    chapterIdPre = chapterId
    chapterId = chapterIdNext
    local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
    chapterIdNext = chapterConfig.next_chapter
    local chapterInfo = {}
    chapterInfo.chapterIdPre = chapterIdPre
    chapterInfo.chapterIdNext = chapterIdNext
    self.chapterTable[chapterId] = chapterInfo
  end
  self.chapterMax = chapterId
end

function TowerLogic:ShowTowerReset(chapterId)
  local timeLeft = Logic.towerLogic:GetLeftTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontTwo(timeLeft)
  local text = string.format(UIHelper.GetString(1700023), timeFormat)
  local paramConfig = configManager.GetDataById("config_parameter", 202).arrValue
  UIHelper.OpenPage("TowerOpenPage", {
    text = text,
    img = paramConfig[2]
  })
end

function TowerLogic:GetRewardText(rewardInfo)
  local chapterId = rewardInfo.ChapterId
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", chapterConfig.relation_chapter_id)
  local themeIndex = self:FormatThemeIndex(rewardInfo.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    if rewardInfo.AreaIndex + 1 == #themeConfig.copy_list and rewardInfo.CopyIndex + 1 == #themeConfig.copy_list[#themeConfig.copy_list] then
      return UIHelper.GetString(1700016)
    else
      local chapterNum = #themeConfig.copy_list
      local copySum = 0
      for i = 1, chapterNum do
        copySum = copySum + #themeConfig.copy_list[i]
      end
      local index = 0
      for i = 1, rewardInfo.AreaIndex do
        index = index + #themeConfig.copy_list[i]
      end
      index = index + rewardInfo.CopyIndex
      local str = index .. "/" .. copySum
      if not rewardInfo.Reward or 0 >= #rewardInfo.Reward then
        return string.format(UIHelper.GetString(1700057), str)
      else
        return string.format(UIHelper.GetString(1700017), str)
      end
    end
  elseif not rewardInfo.Reward or 0 >= #rewardInfo.Reward then
    return UIHelper.GetString(1700064)
  else
    return ""
  end
end

function TowerLogic:ShowTowerTheme()
  local text = UIHelper.GetString(1700019)
  local paramConfig = configManager.GetDataById("config_parameter", 202).arrValue
  UIHelper.OpenPage("TowerOpenPage", {
    text = text,
    img = paramConfig[3]
  })
end

function TowerLogic:GetInitChapterId()
  local paramConfig = configManager.GetDataById("config_parameter", 203)
  return paramConfig.value
end

function TowerLogic:GetNextChapterId(chapterId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return chapterConfig.next_chapter
end

function TowerLogic:GetPreChapterId(chapterId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return chapterConfig.prev_chapter
end

function TowerLogic:GetCopyListByThemeId(themeId)
  local copyTbl = {}
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  local chapterNum = #themeConfig.copy_list
  for i = 1, chapterNum do
    for i, v in ipairs(themeConfig.copy_list[i]) do
      table.insert(copyTbl, v)
    end
  end
  return copyTbl
end

function TowerLogic:GetLeftTime()
  local towerData = Data.towerData:GetData() or {}
  local flag = towerData.ChapterId and towerData.ChapterId > 0
  if not flag then
    return 0
  end
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local resetTime = towerData.ResetTime
  local timeNow = time.getSvrTime()
  local timeLeft = resetTime + chapterTowerConfig.reset_period - timeNow
  return timeLeft
end

function TowerLogic:GetProgress()
  local towerData = Data.towerData:GetData() or {}
  local flag = towerData.ChapterId and towerData.ChapterId > 0
  if not flag then
    return "0/0"
  end
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    local index, sum = self:GetCopyIndexAndSum()
    return index .. "/" .. sum
  else
    return self:GetMultiIndex()
  end
end

function TowerLogic:GetCopyIndexAndSum()
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    local chapterNum = #themeConfig.copy_list
    local copySum = 0
    for i = 1, chapterNum do
      copySum = copySum + #themeConfig.copy_list[i]
    end
    local index = 0
    for i = 1, towerData.AreaIndex do
      index = index + #themeConfig.copy_list[i]
    end
    index = index + towerData.CopyIndex
    if self:IsCopyMax() then
      index = index + 1
    end
    return index, copySum
  else
    local copyList = Data.towerData:GetCopyList()
    local len = #copyList
    for i = len, 1, -1 do
      local copyConfig = configManager.GetDataById("config_copy_display", copyList[i])
      if 0 >= copyConfig.pskill_id then
        return copyConfig.copy_index, 0
      end
    end
    return 0, 0
  end
end

function TowerLogic:GetRecordName()
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    local index = 0
    for i = 1, towerData.AreaIndex do
      index = index + #themeConfig.copy_list[i]
    end
    index = index + towerData.CopyIndex
    if self:IsCopyMax() then
      index = index + 1
    end
    if index <= 0 then
      return chapterConfig.name
    else
      return string.format("%s-%d", chapterConfig.name, index)
    end
  else
    local copyList = Data.towerData:GetCopyList()
    local len = #copyList
    for i = len, 1, -1 do
      local copyConfig = configManager.GetDataById("config_copy_display", copyList[i])
      if 0 >= copyConfig.pskill_id then
        return string.format("%s %s", chapterConfig.name, copyConfig.copy_index)
      end
    end
    return chapterConfig.name
  end
end

function TowerLogic:GetShipBattleInfo(tId, fleetType)
  local shipCount = self:GetShipBattleCount(tId, fleetType)
  shipCount = shipCount == nil and 0 or shipCount
  local totalCount = self:GetShipBattleTimes(fleetType)
  local num = 0 < totalCount - shipCount and totalCount - shipCount or 0
  local countText = num .. "/" .. totalCount
  return totalCount - shipCount, countText
end

function TowerLogic:GetTowerConfigByFleetType(fleetType)
  if fleetType == FleetType.Tower then
    local towerData = Data.towerData:GetData() or {}
    local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
    local towerId = chapterConfig.relation_chapter_id
    return configManager.GetDataById("config_chapter_tower", towerId)
  elseif fleetType == FleetType.LimitTower then
    local chapterId = Logic.towerActivityLogic:GetTowerActivity()
    local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
    local towerId = chapterConfig.relation_chapter_id
    return configManager.GetDataById("config_tower_activity", towerId)
  end
end

function TowerLogic:GetShipBattleTimes(fleetType)
  local config = self:GetTowerConfigByFleetType(fleetType)
  return config.battle_point_default
end

function TowerLogic:GetShipBattleCount(templateId, fleetType)
  if fleetType == FleetType.Tower then
    return Data.towerData:GetShipBattleCount(templateId)
  elseif fleetType == FleetType.LimitTower then
    return Data.towerActivityData:GetShipBattleCount(templateId)
  end
end

function TowerLogic:IfNeedEquipTransplant(fleetType)
  if fleetType ~= FleetType.LimitTower and fleetType ~= FleetType.Tower then
    logError("\232\136\176\233\152\159\231\177\187\229\158\139\228\184\141\230\152\175\231\136\172\229\161\148\231\177\187\229\158\139")
    return
  end
  local needShowTip = false
  local heroIds = {}
  local heroTab = Data.heroData:GetHeroData()
  local fleetHeroIdTab = Data.fleetData:GetShipByFleet(1, fleetType)
  for heroId, _ in pairs(heroTab) do
    local normalShipEquips = Data.heroData:GetEquipsByType(heroId, FleetType.Normal)
    local towerShipEquips = Data.heroData:GetEquipsByType(heroId, fleetType)
    for i = 1, #normalShipEquips do
      if normalShipEquips[i].state == MEquipState.LOCK and (towerShipEquips[i].EquipsId ~= normalShipEquips[i].EquipsId or towerShipEquips[i].state ~= normalShipEquips[i].state) then
        table.insert(heroIds, heroId)
        if table.containV(fleetHeroIdTab, heroId) then
          needShowTip = true
        end
      end
    end
  end
  if 0 < #heroIds then
    local args = {HeroList = heroIds, EquipType = fleetType}
    Service.heroService:_SendEquipLockTransplant(args)
  end
  return needShowTip
end

function TowerLogic:CheckFleetBattleCount(fleetHero, chapterConfig)
  if chapterConfig.tactic_type == FleetType.Tower then
    local towerId = chapterConfig.relation_chapter_id
    local towerData = Data.towerData:GetData()
    local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
    if chapterTowerConfig.daily_battle_time - towerData.DailyCount + towerData.DailyCountEx <= 0 then
      noticeManager:ShowTipById(1700035)
      return false
    end
  end
  return true
end

function TowerLogic:CalTowerHurtPer(templateId, fleetType)
  local battleTimeDefault = self:GetShipBattleTimes(fleetType)
  local shipBattleCount = self:GetShipBattleCount(templateId, fleetType)
  local userPoint = battleTimeDefault - shipBattleCount
  local hurtPer = ScriptManager:RunCmd("TowerHurtPer", nil, userPoint, battleTimeDefault)
  local value = math.ceil(hurtPer / 10000 * 100)
  return value <= 0 and 0 or value
end

function TowerLogic:GetCopyIdNow()
  local towerData = Data.towerData:GetData() or {}
  if towerData.PassLastChapterId > 0 then
    return nil
  end
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  return themeConfig.copy_list[towerData.AreaIndex + 1][towerData.CopyIndex + 1]
end

function TowerLogic:GetHeroIdList(fleetType)
  local heroMap = {}
  local fleetDataTower = Data.fleetData:GetShipByFleet(1, fleetType)
  for i, v in ipairs(fleetDataTower) do
    heroMap[v] = true
  end
  local fleetData = {}
  local heroList
  if fleetType == FleetType.Tower then
    heroList = Data.towerData:GetHeroIdList()
  elseif fleetType == FleetType.LimitTower then
    heroList = Data.towerActivityData:GetHeroIdList()
  end
  for i, v in ipairs(heroList) do
    if heroMap[v] == true then
      table.insert(fleetData, v)
    end
  end
  return fleetData
end

function TowerLogic:CheckTowerEquip(fleetType)
  local fleetDataTower = Data.fleetData:GetShipByFleet(1, fleetType)
  for i, v in ipairs(fleetDataTower) do
    local shipEquips = Data.heroData:GetEquipsByType(v, fleetType)
    local flag = true
    for key, value in ipairs(shipEquips) do
      if value.EquipsId ~= 0 then
        flag = false
      end
    end
    if flag == true then
      return true
    end
  end
  return false
end

function TowerLogic:CheckTowerHurt(fleetType)
  local fleetDataTower = Data.fleetData:GetShipByFleet(1, fleetType)
  for i, v in ipairs(fleetDataTower) do
    local heroInfo = Data.heroData:GetHeroById(v)
    local hurtPer = Logic.towerLogic:CalTowerHurtPer(heroInfo.TemplateId, fleetType)
    if hurtPer <= 0 then
      return true
    end
  end
  return false
end

function TowerLogic:GetChapterType()
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  return themeConfig.type
end

function TowerLogic:GetMultiCopyIdInit()
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  return themeConfig.copy_list[1][1]
end

function TowerLogic:GetBuffDes(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local des = ""
  local pskillId = copyConfig.pskill_id
  if 0 < pskillId then
    des = des .. copyConfig.description
    if chapterTowerConfig.desc_simplify == 0 then
      des = des .. UIHelper.GetString(1703009)
    end
  end
  local buffList = copyConfig.special_buff
  for index, id in ipairs(buffList) do
    local buffConfig = configManager.GetDataById("config_special_buff", id)
    des = des .. UIHelper.GetString(buffConfig.language_id)
  end
  return des
end

function TowerLogic:GetAllBuffDes()
  local result = {}
  local copyList = Data.towerData:GetCopyList()
  for index, copyId in ipairs(copyList) do
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local pskillId = copyConfig.pskill_id
    if 0 < pskillId then
      table.insert(result, copyConfig.description)
    end
  end
  return result
end

function TowerLogic:GetMultiIndex()
  local copyList = Data.towerData:GetCopyList()
  local len = #copyList
  for i = len, 1, -1 do
    local copyConfig = configManager.GetDataById("config_copy_display", copyList[i])
    if copyConfig.pskill_id <= 0 then
      return copyConfig.copy_index
    end
  end
  return UIHelper.GetString(510002)
end

function TowerLogic:GetCopyNumByTheme(themeConfig)
  local typ = themeConfig.type
  local sum = 0
  if typ == TowerType.Solo then
    for index, value in ipairs(themeConfig.copy_list) do
      sum = sum + #value
    end
  elseif typ == TowerType.Multi then
    local copyMap = Logic.copyLogic:TowerGetCopyMapByTheme(themeConfig)
    for i, v in pairs(copyMap) do
      sum = sum + 1
    end
  end
  return sum
end

function TowerLogic:GetRewardIndex()
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    return towerData.AreaIndex + 1
  else
    return self:GetRewardIndexMulti(themeConfig.area_final_copy) + 1
  end
end

function TowerLogic:GetRewardIndexMulti(copyList)
  local copyMap = Data.towerData:GetCopyMap()
  local len = #copyList
  for i = len, 1, -1 do
    local copyListSub = copyList[i]
    for index, copyId in ipairs(copyListSub) do
      if copyMap[copyId] == true then
        return i
      end
    end
  end
  return 0
end

function TowerLogic:GetCopyAttack()
  local copyAttack = {}
  local copyList = Data.towerData:GetCopyList()
  if #copyList <= 0 then
    local copyInit = self:GetMultiCopyIdInit()
    copyAttack[copyInit] = true
  else
    local copyIdPre = copyList[#copyList]
    local copyClearMap = Data.towerData:GetCopyMap()
    local copyConfig = configManager.GetDataById("config_copy_display", copyIdPre)
    for i, v in ipairs(copyConfig.branch_copy) do
      if not copyClearMap[v] then
        copyAttack[v] = true
      end
    end
  end
  return copyAttack
end

function TowerLogic:GetCopyState(copyId)
  local copyMapClear = Data.towerData:GetCopyMap()
  local copyMapAttack = Logic.towerLogic:GetCopyAttack()
  if copyMapClear[copyId] then
    return TowerCopyState.Clear
  elseif copyMapAttack[copyId] then
    return TowerCopyState.Attack
  else
    return TowerCopyState.Lock
  end
end

function TowerLogic:CopyClick(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local state = self:GetCopyState(copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  if isBuff then
    local buffDes = Logic.towerLogic:GetBuffDes(copyId)
    local tips, callback, title, isHideCancel
    if state == TowerCopyState.Attack then
      function callback()
        Service.towerService:SendReceiveBuff({CopyId = copyId})
      end
      
      tips = string.format(UIHelper.GetString(1703003), buffDes)
      title = UIHelper.GetString(1703008)
      isHideCancel = false
    elseif state == TowerCopyState.Lock then
      function callback()
      end
      
      tips = string.format(UIHelper.GetString(1703005), buffDes)
      title = UIHelper.GetString(1703007)
      isHideCancel = true
    end
    noticeManager:ShowSuperNotice(tips, "", false, false, callback, nil, nil, nil, title, nil, isHideCancel)
  else
    local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
    local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
    local areaConfig = {
      copyType = CopyType.COMMONCOPY,
      tabSerData = copyData,
      chapterId = chapterId,
      IsRunningFight = false,
      copyId = copyId
    }
    if Logic.copyLogic:IsAssistFleet(copyId) then
      UIHelper.OpenPage("FleetPage", {
        subType = 2,
        copyId = areaConfig.copyId,
        chapterId = areaConfig.chapterId
      })
    else
      local isHasFleet = Logic.fleetLogic:IsHasFleet()
      if not isHasFleet then
        noticeManager:OpenTipPage(self, 110007)
        return
      end
      UIHelper.OpenPage("LevelDetailsPage", areaConfig)
    end
  end
end

function TowerLogic:IsCopyAttack(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  if chapterConfig.tactic_type == FleetType.LimitTower then
    local copyAttackMap = Logic.towerActivityLogic:GetCopyAttack()
    return copyAttackMap[copyId]
  end
  local towerData = Data.towerData:GetData() or {}
  local chapterConfig = configManager.GetDataById("config_chapter", towerData.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = self:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  if themeConfig.type == TowerType.Solo then
    local copyIdNow = themeConfig.copy_list[towerData.AreaIndex + 1][towerData.CopyIndex + 1]
    return copyIdNow == copyId
  else
    local copyAttackMap = self:GetCopyAttack()
    return copyAttackMap[copyId]
  end
end

function TowerLogic:GetAllPath(themeConfig)
  local copyMap = {}
  local pathMap = {}
  local copyId = themeConfig.copy_list[1][1]
  self:TowerMultiSearch(copyMap, pathMap, copyId)
  return pathMap
end

function TowerLogic:TowerMultiSearch(copyMap, pathMap, copyId)
  if not copyMap[copyId] then
    copyMap[copyId] = true
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    for i, v in ipairs(copyConfig.branch_copy) do
      pathMap[copyId .. "_" .. v] = true
      self:TowerMultiSearch(copyMap, pathMap, v)
    end
  end
end

function TowerLogic:IsNotDeadRoad()
  local copyList = Data.towerData:GetCopyList()
  if #copyList <= 0 then
    return true
  end
  local copyId = copyList[#copyList]
  local copyMap = {}
  for i = 1, #copyList - 1 do
    copyMap[copyList[i]] = true
  end
  return self:CheckAvailableSearch(copyId, copyMap)
end

function TowerLogic:CheckAvailable(copyId)
  local copyMap = Data.towerData:GetCopyMap()
  return self:CheckAvailableSearch(copyId, copyMap)
end

function TowerLogic:CheckAvailableSearch(copyId, copyMapPre)
  local copyMap = clone(copyMapPre)
  copyMap[copyId] = true
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  if #copyConfig.branch_copy <= 0 then
    return true
  end
  local searchAvailable = {}
  for i, v in ipairs(copyConfig.branch_copy) do
    if not copyMap[v] then
      table.insert(searchAvailable, v)
    end
  end
  if #searchAvailable <= 0 then
    return false
  end
  for i, v in ipairs(searchAvailable) do
    if self:CheckAvailableSearch(v, copyMap) then
      return true
    end
  end
  return false
end

function TowerLogic:IsTowerType(fleetType)
  return fleetType == FleetType.Tower or fleetType == FleetType.LimitTower
end

function TowerLogic:IsTowerNormalType(fleetType)
  return fleetType == FleetType.Tower
end

function TowerLogic:IsTowerLimitType(fleetType)
  return fleetType == FleetType.LimitTower
end

return TowerLogic
