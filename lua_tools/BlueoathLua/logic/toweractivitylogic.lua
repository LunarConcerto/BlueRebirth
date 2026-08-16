local TowerActivityLogic = class("logic.TowerActivityLogic")

function TowerActivityLogic:initialize()
end

function TowerActivityLogic:GetTowerActivity()
  local chapterAllConfig = configManager.GetData("config_chapter")
  for chapterId, v in pairs(chapterAllConfig) do
    if v.class_type == ChapterType.TowerActivity then
      if v.chapter_period <= 0 then
        return chapterId
      elseif v.chapter_period > 0 and PeriodManager:IsInPeriodArea(v.chapter_period, v.chapter_periodarea) then
        return chapterId
      end
    end
  end
  return 0
end

function TowerActivityLogic:GetCopyAttack(chapterId)
  local copyAttack = {}
  local copyList = Data.towerActivityData:GetCopyList()
  if #copyList <= 0 then
    local copyInit = self:GetMultiCopyIdInit(chapterId)
    copyAttack[copyInit] = true
  else
    local copyIdPre = copyList[#copyList]
    local copyClearMap = Data.towerActivityData:GetCopyMap()
    local copyConfig = configManager.GetDataById("config_copy_display", copyIdPre)
    for i, v in ipairs(copyConfig.branch_copy) do
      if not copyClearMap[v] then
        copyAttack[v] = true
      end
    end
  end
  return copyAttack
end

function TowerActivityLogic:GetAllCopyMap(chapterId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return Logic.copyLogic:ATowerGetCopyMap(chapterConfig)
end

function TowerActivityLogic:GetMultiCopyIdInit(chapterId)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  return chapterConfig.level_list[1]
end

function TowerActivityLogic:GetCopyState(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local copyMapClear = Data.towerActivityData:GetCopyMap()
  local copyMapAttack = Logic.towerActivityLogic:GetCopyAttack(chapterId)
  if copyMapClear[copyId] and not self:IsResetCopy(copyId) then
    return TowerCopyState.Clear
  elseif copyMapAttack[copyId] then
    return TowerCopyState.Attack
  else
    return TowerCopyState.Lock
  end
end

function TowerActivityLogic:IsNotDeadRoad()
  local copyList = Data.towerActivityData:GetCopyList()
  if #copyList <= 0 then
    return true
  end
  local copyId = copyList[#copyList]
  local copyMap = {}
  for i = 1, #copyList - 1 do
    copyMap[copyList[i]] = true
  end
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local resetCopyMap = self:GetResetCopyMap(chapterId)
  if resetCopyMap[copyId] then
    return true
  end
  return self:CheckAvailableSearch(copyId, copyMap, resetCopyMap)
end

function TowerActivityLogic:GetResetCopyMap(chapterId)
  local resetCopyMap = {}
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local copyMap = Logic.copyLogic:ATowerGetCopyMap(chapterConfig)
  for copyId, _ in pairs(copyMap) do
    if self:IsResetCopy(copyId) then
      resetCopyMap[copyId] = true
    end
  end
  return resetCopyMap
end

function TowerActivityLogic:IsResetCopy(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  for index, buff_id in ipairs(copyConfig.special_buff) do
    if buff_id == TowerBuffType.Reset then
      return true
    end
  end
  return false
end

function TowerActivityLogic:CheckAvailable(copyId)
  local copyMap = Data.towerActivityData:GetCopyMap()
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local resetCopyMap = self:GetResetCopyMap(chapterId)
  if resetCopyMap[copyId] then
    return true
  end
  return self:CheckAvailableSearch(copyId, copyMap, resetCopyMap)
end

function TowerActivityLogic:CheckAvailableSearch(copyId, copyMapPre, resetCopyMap)
  local copyMap = clone(copyMapPre)
  copyMap[copyId] = true
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local searchAvailable = {}
  for i, v in ipairs(copyConfig.branch_copy) do
    if resetCopyMap[v] then
      return true
    elseif not copyMap[v] then
      table.insert(searchAvailable, v)
    end
  end
  if #searchAvailable <= 0 then
    return false
  end
  for i, v in ipairs(searchAvailable) do
    if self:CheckAvailableSearch(v, copyMap, resetCopyMap) then
      return true
    end
  end
  return false
end

function TowerActivityLogic:GetLeftTime()
  local chapterId = Logic.towerActivityLogic:GetTowerActivity()
  if chapterId <= 0 then
    return 0
  end
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local startTime, endTime = PeriodManager:GetPeriodTime(chapterConfig.chapter_period, chapterConfig.chapter_periodarea)
  local timeNow = time.getSvrTime()
  local timeLeft = endTime - timeNow
  return timeLeft
end

function TowerActivityLogic:GetResetLeftTime()
  local towerData = Data.towerActivityData:GetData() or {}
  local chapterId = Logic.towerActivityLogic:GetTowerActivity()
  if chapterId <= 0 then
    return 0
  end
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_tower_activity", towerId)
  local resetTime = towerData.ResetTime or 0
  local timeNow = time.getSvrTime()
  local timeLeft = resetTime + chapterTowerConfig.reset_period - timeNow
  return timeLeft
end

function TowerActivityLogic:GetAllBuffDes()
  local copyList = Data.towerActivityData:GetAllCopyList()
  local copyMap = {}
  for index, copyId in pairs(copyList) do
    local times = copyMap[copyId] or 0
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local pskillId = copyConfig.pskill_id
    if 0 < pskillId and (copyConfig.buff_max_times == -1 or times < copyConfig.buff_max_times) then
      copyMap[copyId] = times + 1
    end
  end
  local attrMap = {}
  for copyId, times in pairs(copyMap) do
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    for index, info in pairs(copyConfig.tower_prop_id_num) do
      local attrIndex = info[1]
      local val = attrMap[attrIndex] or 0
      attrMap[attrIndex] = val + info[2] * times
    end
  end
  local attrList = {}
  for id, times in pairs(attrMap) do
    local attr = {}
    attr.id = id
    local attrConfig = configManager.GetDataById("config_tower_prop", id)
    attr.order = attrConfig.order
    attr.times = times
    attr.str = string.format(UIHelper.GetString(attrConfig.language_id), times)
    table.insert(attrList, attr)
  end
  table.sort(attrList, function(a, b)
    return a.order < b.order
  end)
  return attrList
end

function TowerActivityLogic:CopyClick(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local state = self:GetCopyState(copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local isReset = Logic.towerActivityLogic:IsResetCopy(copyId)
  local copyTimesMap = Data.towerActivityData:GetAllCopyTimesMap()
  if isBuff then
    local buffDes = Logic.towerActivityLogic:GetBuffDes(copyId)
    local tips, callback
    local title = isReset and UIHelper.GetString(2900016) or UIHelper.GetString(1703008)
    local isHideCancel
    if state == TowerCopyState.Attack then
      function callback()
        Service.towerActivityService:SendReceiveBuff({CopyId = copyId})
      end
      
      tips = isReset and UIHelper.GetString(2900017) or string.format(UIHelper.GetString(1703003), buffDes)
      local times = copyTimesMap[copyId] or 0
      if times >= copyConfig.buff_max_times and copyConfig.buff_max_times ~= -1 and not isReset then
        tips = tips .. UIHelper.GetString(2900035)
      end
      isHideCancel = false
    elseif state == TowerCopyState.Lock then
      function callback()
      end
      
      tips = isReset and UIHelper.GetString(2900018) or string.format(UIHelper.GetString(1703005), buffDes)
      local times = copyTimesMap[copyId] or 0
      if times >= copyConfig.buff_max_times and copyConfig.buff_max_times ~= -1 and not isReset then
        tips = tips .. UIHelper.GetString(2900035)
      end
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
    UIHelper.OpenPage("LevelDetailsPage", areaConfig)
  end
end

function TowerActivityLogic:GetCopyAttack()
  local copyAttack = {}
  local copyList = Data.towerActivityData:GetCopyList()
  if #copyList <= 0 then
    local chapterId = Logic.towerActivityLogic:GetTowerActivity()
    local copyInit = self:GetMultiCopyIdInit(chapterId)
    copyAttack[copyInit] = true
  else
    local copyIdPre = copyList[#copyList]
    local copyClearMap = Data.towerActivityData:GetCopyMap()
    local copyConfig = configManager.GetDataById("config_copy_display", copyIdPre)
    local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyIdPre)
    for i, v in ipairs(copyConfig.branch_copy) do
      local resetCopyMap = self:GetResetCopyMap(chapterId)
      if not copyClearMap[v] then
        copyAttack[v] = true
      elseif resetCopyMap[v] then
        copyAttack[v] = true
      end
    end
  end
  return copyAttack
end

function TowerActivityLogic:GetAddition()
  local copyList = Data.towerActivityData:GetAllCopyList()
  local sum = 0
  for i, copyId in ipairs(copyList) do
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local isBuff = 0 < copyConfig.pskill_id or 0 < #copyConfig.special_buff
    if not isBuff then
      sum = sum + 1
    end
  end
  local sumMax = configManager.GetDataById("config_parameter", 334).value
  sum = sum <= sumMax and sum or sumMax
  local rate = configManager.GetDataById("config_parameter", 335).value / 10000
  local x = sum
  local num = 0.009151 * x * x * x + 0.192544 * x + 0.990849 - 1
  return num
end

function TowerActivityLogic:GetBuffDes(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local des = ""
  local pskillId = copyConfig.pskill_id
  if 0 < pskillId then
    des = des .. copyConfig.description
  end
  local buffList = copyConfig.special_buff
  for index, id in ipairs(buffList) do
    local buffConfig = configManager.GetDataById("config_special_buff", id)
    des = des .. UIHelper.GetString(buffConfig.language_id)
  end
  return des
end

function TowerActivityLogic:GetPassNum()
  local allCopyList = Data.towerActivityData:GetStageCopyList()
  local copyList = {}
  for i, copyId in ipairs(allCopyList) do
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
    if not isBuff then
      table.insert(copyList, copyId)
    end
  end
  return #copyList
end

function TowerActivityLogic:GetQuickPassMax(config)
  local result = 0
  local historyMax = Data.towerActivityData:GetHistoryMax()
  for i, v in ipairs(config.quick_pass) do
    if v > historyMax then
      break
    end
    result = v
  end
  return result
end

return TowerActivityLogic
