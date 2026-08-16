local TowerData = class("data.TowerData", Data.BaseData)

function TowerData:initialize()
  self.data = {}
  self.shipBattleCount = {}
  self.heroIdList = {}
  self.rewardInfo = {}
  self.lockEquipList = {}
  self.isReset = false
  self.isNewLevel = false
  self.maxLevel = 0
  self.maxArea = 0
  self.maxCopy = 0
  self.SavePassCopyId = {}
end

function TowerData:SetData(data)
  logDebug("======================Tower SetData=================", data)
  self.data = data
  self:SetShipBattleCount()
  if data and data.HeroIdList and #data.HeroIdList > 0 then
    self.heroIdList = data.HeroIdList
  end
  if data and data.RewardInfo and data.RewardInfo.ChapterId then
    self.rewardInfo = data.RewardInfo
  end
  if data and data.RewardInfo and data.RewardInfo.ChapterId then
    self.rewardInfo = data.RewardInfo
  end
  if data and data.IsReset then
    self.isReset = data.IsReset
  end
  if data and data.IsNewLevel then
    local chapterId = configManager.GetDataById("config_parameter", 203).value
    if chapterId ~= data.ChapterId then
      self.isNewLevel = data.IsNewLevel
    end
  end
  if data.LockEquipList == nil or next(data.LockEquipList) == nil then
    self.lockEquipList = {}
  else
    for _, v in pairs(data.LockEquipList) do
      self.lockEquipList[v] = true
    end
  end
  if data and data.MaxLevel then
    self.maxLevel = data.MaxLevel
  end
  if data and data.MaxArea then
    self.maxArea = data.MaxArea + 1
  end
  if data and data.MaxCopy then
    self.maxCopy = data.MaxCopy + 1
  end
  if data and data.SavePassCopyId then
    self.SavePassCopyId = data.SavePassCopyId
  end
end

function TowerData:GetData()
  return self.data
end

function TowerData:SetShipBattleCount()
  if next(self.data.SfID2Count) ~= nil then
    for _, v in pairs(self.data.SfID2Count) do
      self.shipBattleCount[v.SfID] = v.Count
    end
  else
    self.shipBattleCount = {}
  end
end

function TowerData:GetShipBattleCount(tId)
  local sf_id = Logic.shipLogic:GetSfidBySmid(tId)
  return self.shipBattleCount[sf_id] or 0
end

function TowerData:GetHeroIdList()
  return self.heroIdList
end

function TowerData:ResetHeroIdList()
  self.heroIdList = {}
end

function TowerData:GetRewardInfo()
  return self.rewardInfo
end

function TowerData:ResetRewardInfo()
  self.rewardInfo = {}
end

function TowerData:IsReset()
  return self.isReset
end

function TowerData:ResetValue()
  self.isReset = false
end

function TowerData:IsNewLevel()
  return self.isNewLevel
end

function TowerData:ResetNewLevel()
  self.isNewLevel = false
end

function TowerData:IsLockEquip(equipId)
  return self.lockEquipList[equipId] ~= nil
end

function TowerData:GetMaxLevel()
  return self.maxLevel
end

function TowerData:GetTowerDetail()
  local result = {}
  result.maxLevel = self.maxLevel
  result.maxAreaIndex = self.maxArea
  result.maxCopyIndex = self.maxCopy
  if self.data.ChapterId and self.data.ChapterId > 0 then
    if 0 < self.data.PassLastChapterId then
      local chapterConfig = configManager.GetDataById("config_chapter", self.data.ChapterId)
      local towerId = chapterConfig.relation_chapter_id
      local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
      result.level = chapterTowerConfig.level + 1
      result.areaIndex = 1
      result.copyIndex = 1
    else
      local chapterConfig = configManager.GetDataById("config_chapter", self.data.ChapterId)
      local towerId = chapterConfig.relation_chapter_id
      local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
      result.level = chapterTowerConfig.level
      result.areaIndex = self.data.AreaIndex + 1
      result.copyIndex = self.data.CopyIndex + 1
    end
  else
    result.level = 0
    result.areaIndex = 0
    result.copyIndex = 0
  end
  return result
end

function TowerData:IsShowUpgrade()
  if not self.data.ChapterId then
    return false
  end
  local chapterConfig = configManager.GetDataById("config_chapter", self.data.ChapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  return self.maxLevel > chapterTowerConfig.level and chapterConfig.next_chapter > 0
end

function TowerData:GetCopyList()
  return self.SavePassCopyId or {}
end

function TowerData:GetCopyMap()
  local copyMap = {}
  local copyList = self:GetCopyList()
  for _, copyId in ipairs(copyList) do
    copyMap[copyId] = true
  end
  return copyMap
end

return TowerData
