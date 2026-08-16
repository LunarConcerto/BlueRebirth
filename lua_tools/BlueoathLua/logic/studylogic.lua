local StudyLogic = class("logic.StudyLogic")
StudyFlow = require("ui.page.Study.StudyFlow")

function StudyLogic:initialize(...)
  eventManager:RegisterEvent(LuaEvent.GetStudyInfo, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.StartStudy, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.FinishStudy, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.CancelStudy, self.CreateStudyFinishCountdown, self)
end

function StudyLogic:_UnRegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.GetStudyInfo, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.StartStudy, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.FinishStudy, self.CreateStudyFinishCountdown, self)
  eventManager:RegisterEvent(LuaEvent.CancelStudy, self.CreateStudyFinishCountdown, self)
end

function StudyLogic:ResetData()
  local retdotTimer = self.retdotTimer
  if retdotTimer and retdotTimer.running then
    retdotTimer:Stop()
  end
  self.retdotTimer = nil
  self.emptyCheck = false
  self.upItems = {}
  self.curUpIndex = 0
  self.selextIndexs = {}
  self.m_endSeqs = {}
  self.m_sendEnd = true
end

function StudyLogic:SetSendEnd(param)
  self.m_sendEnd = param
end

function StudyLogic:GetSendEnd()
  return self.m_sendEnd
end

function StudyLogic:AddEndSeq(seq)
  table.insert(self.m_endSeqs, seq)
end

function StudyLogic:GetStartSeq()
  if #self.m_endSeqs < 1 then
    return false, nil
  else
    local res = self.m_endSeqs[1]
    table.remove(self.m_endSeqs, 1)
    logError(res)
    return res ~= nil, res
  end
end

function StudyLogic:SetSelectIndex(param)
  self.selextIndexs = param
end

function StudyLogic:GetSelectIndex()
  return self.selextIndexs
end

function StudyLogic:GetSelectIndexById(index)
  return self.selextIndexs[index]
end

function StudyLogic:SetSelectIndexById(index, num)
  self.selextIndexs[index] = num
end

function StudyLogic:AddSelectIndex(index, num)
  num = num or 0
  if self.selextIndexs[index] then
    self.selextIndexs[index] = self.selextIndexs[index] + num
  else
    self.selextIndexs[index] = num
  end
end

function StudyLogic:RemoveZeroSelect()
  local rems = {}
  for k, v in pairs(self.selextIndexs) do
    if v == 0 then
      table.insert(rems, k)
    end
  end
  for i, v in ipairs(rems) do
    self.selextIndexs[v] = nil
  end
end

function StudyLogic:SetCurUpItem(index)
  self.curUpIndex = index
end

function StudyLogic:GetCurUpItem()
  return self.curUpIndex
end

function StudyLogic:GetUpItems()
  return self.upItems
end

function StudyLogic:AddUpItem(id, num)
  num = num or 1
  if self.upItems[id] then
    self.upItems[id] = self.upItems[id] + num
  else
    self.upItems[id] = num
  end
end

function StudyLogic:GetUpSelectNum(id)
  local num = self.upItems[id]
  return num or 0
end

function StudyLogic:SetUpItems(items)
  self.upItems = items
end

function StudyLogic:IsSelectUpItem()
  return next(self.upItems) ~= nil
end

function StudyLogic:GetUserBooks()
  return Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
end

function StudyLogic:GetFormatBooksAndSort()
  local res = {}
  local items = self:GetUserBooks()
  for k, v in ipairs(items) do
    res[k] = {
      Type = BagItemType.SHIP_TALENT_UPGRADE,
      ConfigId = v.templateId,
      Num = v.num
    }
  end
  res = self:UpItemsSort(res)
  return res
end

function StudyLogic:GetUpTime(itemId, pskillId)
  local res = self:GetUpBaseTime(itemId)
  if self:IsMatch(itemId, pskillId) then
    res = self:GetUpExtraTime(itemId)
  end
  return res
end

function StudyLogic:GetSelectItemUpTime(pskillId)
  local uptime = 0
  local upItems = self:GetUpItems()
  for id, num in pairs(upItems) do
    local temp = self:GetUpTime(id, pskillId) * num
    uptime = uptime + temp
  end
  return uptime
end

function StudyLogic:IsMatch(itemId, pskillId)
  local itemType = self:GetSkillBookConfigById(itemId).talent_type
  local pskillType = configManager.GetDataById("config_pskill_dict_group", pskillId).talent_type
  return itemType == pskillType
end

function StudyLogic:GetUpBaseTime(id)
  return self:GetSkillBookConfigById(id).not_match_reduce_time
end

function StudyLogic:GetUpExtraTime(id)
  return self:GetSkillBookConfigById(id).match_reduce_time
end

function StudyLogic:GetSkillBookConfigById(id)
  return configManager.GetDataById("config_ship_talent_upgrade_item", id)
end

function StudyLogic:GetRmdUpItems(pskillId, remainTime)
  local pType = configManager.GetDataById("config_pskill_dict_group", pskillId).talent_type
  local res = {}
  local orgin = self:_rmdSort(pskillId)
  local i = 1
  while self:_getRemainTime(pskillId, remainTime, res) > 0 and not (i > #orgin) do
    local temp = orgin[i]
    local num = res[temp.templateId]
    if num then
      if num < temp.num then
        res[temp.templateId] = res[temp.templateId] + 1
      else
        i = i + 1
      end
    else
      res[temp.templateId] = 1
    end
  end
  return res
end

function StudyLogic:_getRemainTime(pskillId, remainTime, items)
  local uptime = 0
  for id, num in pairs(items) do
    local temp = self:GetUpTime(id, pskillId) * num
    uptime = uptime + temp
  end
  return remainTime - uptime
end

function StudyLogic:_rmdSort(pskillId)
  local orgin = self:GetUserBooks()
  table.sort(orgin, function(data1, data2)
    local typ1 = self:IsMatch(data1.templateId, pskillId) and 1 or 0
    local quality1 = self:GetTextBookQuality(data1.templateId)
    local typ2 = self:IsMatch(data2.templateId, pskillId) and 1 or 0
    local quality2 = self:GetTextBookQuality(data2.templateId)
    if typ1 ~= typ2 then
      return typ1 > typ2
    elseif quality1 ~= quality2 then
      return quality1 < quality2
    end
  end)
  return orgin
end

function StudyLogic:UpItemsSort(items)
  table.sort(items, function(data1, data2)
    local quality1 = self:GetTextBookQuality(data1.ConfigId)
    local quality2 = self:GetTextBookQuality(data2.ConfigId)
    if quality1 ~= quality2 then
      return quality1 > quality2
    else
      return data1.ConfigId < data2.ConfigId
    end
  end)
  return items
end

function StudyLogic:CreateStudyFinishCountdown()
  local serverData = Data.studyData:GetStudyData()
  if not serverData or not serverData.ArrProgress then
    return
  end
  local countdownArr = {}
  local timeNow = time.getSvrTime()
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    local finishTime = Logic.studyLogic:GetStudyFinish(studyInfo.HeroId, studyInfo.PSkillId)
    local countdown = finishTime - timeNow
    if timeNow < finishTime then
      table.insert(countdownArr, countdown + 2)
    end
  end
  if #countdownArr == 0 then
    return
  end
  local minCountdown = math.min(table.unpack(countdownArr))
  self.retdotTimer = self.retdotTimer or Timer.New()
  local retdotTimer = self.retdotTimer
  if retdotTimer and retdotTimer.running then
    retdotTimer:Stop()
  end
  retdotTimer:Reset(function()
    eventManager:SendEvent(LuaEvent.UpdateHomeRedDot)
  end, minCountdown, 1, false)
  retdotTimer:Start()
end

function StudyLogic:checkStudyProgress()
  local serverData = Data.studyData:GetStudyData()
  if not serverData or not serverData.ArrProgress then
    return
  end
  local timeNow = time.getSvrTime()
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    local finishTime = Logic.studyLogic:GetStudyFinish(studyInfo.HeroId, studyInfo.PSkillId)
    if timeNow >= finishTime and finishTime > timePre then
      eventManager:SendEvent(LuaEvent.UpdateHomeRedDot)
    end
  end
  timePre = timeNow
end

function StudyLogic:SendFinshedStudy()
  local infoList = Data.studyData:GetStudyData().ArrProgress
  for i, v in ipairs(infoList) do
    if self:GetStudyFinish(v.HeroId, v.PSkillId) <= time.getSvrTime() then
      Service.studyService:SendStopStudy(v.HeroId)
    end
  end
end

function StudyLogic:SendFinshedStudyByHero(heroId)
  local infoList = Data.studyData:GetStudyData().ArrProgress
  local canSendFinish = self:GetSendEnd()
  if not canSendFinish then
    return
  end
  for i, v in ipairs(infoList) do
    if heroId == v.HeroId and self:_checkFinish(v) then
      Service.studyService:SendStopStudy(heroId)
      v.Finish = true
      self:SetSendEnd(false)
    end
  end
end

function StudyLogic:_checkFinish(v)
  local res = self:GetStudyFinish(v.HeroId, v.PSkillId) <= time.getSvrTime()
  return res and (v.Finish == nil or v.Finish == false)
end

function StudyLogic:GetStudyCapacity()
  local initNum = 2
  local extraNum = 0
  return initNum + extraNum
end

function StudyLogic:GetTextBookName(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.name
end

function StudyLogic:GetTextBookIcon(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.icon
end

function StudyLogic:GetTextBookQuality(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.quality
end

function StudyLogic:GetTextBookNotMatchExp(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.not_match_talent_type_exp
end

function StudyLogic:GetTextBookDesc(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.description
end

function StudyLogic:GetTextBookDuration(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.need_time
end

function StudyLogic:GetTextBookType(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.talent_type
end

function StudyLogic:GetTextBookMatchExp(textbookId)
  local config = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  return config.match_talent_type_exp
end

function StudyLogic:GetTextBookExp(textbookId, pskillId)
  local textbookConfig = configManager.GetDataById("config_ship_talent_upgrade_item", textbookId)
  local pskillConfig = configManager.GetDataById("config_pskill_dict_group", pskillId)
  local bookTalentType = textbookConfig.talent_type
  local pskillTalentType = pskillConfig.talent_type
  local matchExp = textbookConfig.match_talent_type_exp
  local notMatchExp = textbookConfig.not_match_talent_type_exp
  if bookTalentType == pskillTalentType then
    return matchExp, matchExp / notMatchExp
  else
    return notMatchExp, 1
  end
end

function StudyLogic:CheckHeroAlreadyStudy(heroId)
  local data = Data.studyData:GetStudyData()
  for i, v in pairs(data.ArrProgress) do
    if v.HeroId == heroId then
      return true
    end
  end
  return false
end

function StudyLogic:GetStudyFinish(heroId, pskillId)
  local data = Data.studyData:GetStudyData()
  for i, v in pairs(data.ArrProgress) do
    if v.HeroId == heroId and v.PSkillId == pskillId then
      local textbookId = v.TextbookId
      local duration = Logic.studyLogic:GetTextBookDuration(textbookId)
      local cache = v.BeginTime + duration
      return v.EndTime and v.EndTime or cache
    end
  end
  logError("study plan not found")
  return 0
end

function StudyLogic:GetHeroArrCanStudy()
  local heroMap = Data.heroData:GetHeroData()
  local heroArr = {}
  for heroId, info in pairs(heroMap) do
    for skillId, _ in pairs(info.PSKillMap) do
      if Logic.shipLogic:CheckHeroPSkillActive(heroId, skillId) and not Logic.shipLogic:CheckHeroPSkillReachMax(heroId, skillId) and not Logic.studyLogic:CheckHeroAlreadyStudy(heroId) then
        table.insert(heroArr, heroId)
        break
      end
    end
  end
  return heroArr
end

function StudyLogic:CheckHasSkillCanLvUp()
  local heroInfoMap = Data.heroData:GetHeroData()
  for heroId, info in pairs(heroInfoMap) do
    for skillId, _ in pairs(info.PSKillMap) do
      if Logic.shipLogic:CheckHeroPSkillActive(heroId, skillId) and not Logic.shipLogic:CheckHeroPSkillReachMax(heroId, skillId) and not Logic.studyLogic:CheckHeroAlreadyStudy(heroId) then
        return true
      end
    end
  end
  return false
end

function StudyLogic:GetStudyFlow()
  return StudyFlow.GetInstance()
end

function StudyLogic:GetStudyMargin()
  local capacity = self:GetStudyCapacity()
  local count = 0
  for i, data in ipairs(Data.studyData:GetStudyData().ArrProgress) do
    if self:GetStudyFinish(data.HeroId, data.PSkillId) >= time.getSvrTime() then
      count = count + 1
    end
  end
  return capacity - count
end

function StudyLogic:CheckStudyEnd()
  local serverData = Data.studyData:GetStudyData()
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    local finishTime = Logic.studyLogic:GetStudyFinish(studyInfo.HeroId, studyInfo.PSkillId)
    if finishTime <= time.getSvrTime() then
      return true
    end
  end
  return false
end

function StudyLogic:CheckStudyBook()
  local textbookArr = Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
  if #textbookArr ~= 0 then
    return true
  end
  return false
end

function StudyLogic:CheckExistHeroStudy()
  local serverData = Data.studyData:GetStudyData()
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    if self:CheckHeroAlreadyStudy(studyInfo.HeroId) then
      return true
    end
  end
  return false
end

function StudyLogic:GetFinishStudyNum()
  local serverData = Data.studyData:GetStudyData()
  local finishNum = 0
  for i, studyInfo in ipairs(serverData.ArrProgress) do
    local bFinish = Logic.studyLogic:GetStudyFinish(studyInfo.HeroId, studyInfo.PSkillId) <= time.getSvrTime()
    if bFinish == true then
      finishNum = finishNum + 1
    end
  end
  return finishNum
end

function StudyLogic:CheckOneFinish()
  local finishNum = self:GetFinishStudyNum()
  if finishNum == 1 then
    return true
  end
  return false
end

function StudyLogic:CheckTwoFinish()
  local finishNum = self:GetFinishStudyNum()
  if finishNum == 2 then
    return true
  end
  return false
end

function StudyLogic:CheckNoneFinish()
  local finishNum = self:GetFinishStudyNum()
  if finishNum == 0 then
    return true
  end
  return false
end

function StudyLogic:CheckCanStudy()
  local studying = self:CheckExistHeroStudy()
  local haveBook = self:CheckStudyBook()
  if not studying and haveBook then
    return true
  end
  return false
end

function StudyLogic:GetDisPlayGirl()
  if time.getSvrTime() % 2 == 0 then
    return 4021011
  else
    return 3063011
  end
end

function StudyLogic:GetEndTweenTime()
  return 0.5
end

function StudyLogic:CheckStudyGoOnTip()
  local playerPrefsKey = PlayerPrefsKey.StudyGoOn
  if playerPrefsKey then
    local setok = PlayerPrefs.GetBool(playerPrefsKey, false)
    local settime = PlayerPrefs.GetInt(playerPrefsKey .. "Time", 0)
    if setok then
      return not time.isSameDay(settime, time.getSvrTime())
    end
  end
  return true
end

return StudyLogic
