local MagazineLogic = class("logic.MagazineLogic")
MagazineState = {
  Active = 1,
  UnLock = 2,
  Lock = 3
}
MagazineSpecial = {Normal = 0, Special = 1}

function MagazineLogic:initialize()
  self.tagMapList = {}
  self.tagMapMap = {}
  self:InitTagMap()
end

function MagazineLogic:GetSortAndOpen()
  local result = {}
  local configAll = configManager.GetData("config_magazine_info")
  for i, config in pairs(configAll) do
    if Data.magazineData:IsOpenById(config.id) then
      table.insert(result, config)
    end
  end
  table.sort(result, function(a, b)
    if a.order ~= b.order then
      return a.order > b.order
    else
      return a.id < b.id
    end
  end)
  return result
end

function MagazineLogic:GetLatest()
  local configAll = self:GetSortAndOpen()
  if #configAll <= 0 then
    return nil
  end
  return configAll[#configAll]
end

function MagazineLogic:GetLeftTaskFinishNum(magazineId)
  local config = configManager.GetDataById("config_magazine_info", magazineId)
  local taskList = config.task_left_id
  local sum = 0
  for i, taskId in ipairs(taskList) do
    local state = Logic.taskLogic:GetTaskFinishState(taskId, TaskType.Magazine)
    if state ~= TaskState.TODO then
      sum = sum + 1
    end
  end
  return sum
end

function MagazineLogic:InitTagMap()
  local configAll = configManager.GetData("config_ship_handbook")
  for id, v in pairs(configAll) do
    for i, tagId in ipairs(v.magazine_tag) do
      if not self.tagMapList[tagId] then
        self.tagMapList[tagId] = {}
      end
      table.insert(self.tagMapList[tagId], id)
      if not self.tagMapMap[tagId] then
        self.tagMapMap[tagId] = {}
      end
      self.tagMapMap[tagId][id] = true
    end
  end
end

function MagazineLogic:GetHeroListByTagId(tagId)
  return self.tagMapList[tagId] or {}
end

function MagazineLogic:IsTag(id, tagId)
  return self.tagMapMap[tagId][id] or false
end

function MagazineLogic:GetAllHeroByTagId(tagId)
  local data = Data.heroData:GetHeroData()
  local heroTab = {}
  for k, v in pairs(data) do
    local sm_config = configManager.GetDataById("config_ship_main", v.TemplateId)
    local si_config = configManager.GetDataById("config_ship_info", sm_config.ship_info_id)
    if self:IsTag(si_config.sf_id, tagId) then
      heroTab[k] = v
    end
  end
  return heroTab
end

function MagazineLogic:CheckMagazineLevel(magazineId, level, num)
  local tblAllHeroData = Data.heroData:GetHeroData()
  local config = configManager.GetDataById("config_magazine_info", magazineId)
  local shipList = config.content_ship
  local sum = 0
  local sfidMap = {}
  for heroId, tblHero in pairs(tblAllHeroData) do
    local sfid = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if not sfidMap[sfid] and level <= tblHero.Lvl and self:IsInList(shipList, sfid) then
      sum = sum + 1
      sfidMap[sfid] = true
      if num <= sum then
        return sum
      end
    end
  end
  return sum
end

function MagazineLogic:CheckMagazineAffection(magazineId, affection, num)
  local tblAllHeroData = Data.heroData:GetHeroData()
  local config = configManager.GetDataById("config_magazine_info", magazineId)
  local shipList = config.content_ship
  local sum = 0
  local sfidMap = {}
  for heroId, tblHero in pairs(tblAllHeroData) do
    local sfid = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if not sfidMap[sfid] and affection <= tblHero.Affection and self:IsInList(shipList, sfid) then
      sum = sum + 1
      sfidMap[sfid] = true
      if num <= sum then
        return sum
      end
    end
  end
  return sum
end

function MagazineLogic:CheckMagazineStar(magazineId, advance, num)
  local tblAllHeroData = Data.heroData:GetHeroData()
  local config = configManager.GetDataById("config_magazine_info", magazineId)
  local shipList = config.content_ship
  local sum = 0
  local sfidMap = {}
  for heroId, tblHero in pairs(tblAllHeroData) do
    local sfid = Logic.shipLogic:GetShipUniqueIdById(heroId)
    if not sfidMap[sfid] and advance <= tblHero.Advance and self:IsInList(shipList, sfid) then
      sum = sum + 1
      sfidMap[sfid] = true
      if num <= sum then
        return sum
      end
    end
  end
  return sum
end

function MagazineLogic:IsInList(list, value)
  for i, v in ipairs(list) do
    if value == v then
      return true
    end
  end
  return false
end

function MagazineLogic:GetMagazineState(id)
  local configs = Logic.magazineLogic:GetSortAndOpen()
  if configs[1].id == id and PeriodManager:IsInPeriodArea(configs[1].period, configs[1].task_period_area) then
    return MagazineState.Active
  elseif Data.magazineData:IsUnLockById(id) then
    return MagazineState.UnLock
  else
    return MagazineState.Lock
  end
end

return MagazineLogic
