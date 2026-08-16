local TowerActivityData = class("data.TowerActivityData", Data.BaseData)

function TowerActivityData:initialize()
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
  self.SavePassCopyIdList = {}
  self.PassCopyIdList = {}
  self.SavePassStageCopyIdList = {}
end

function TowerActivityData:SetData(data)
  logDebug("======================TowerActivityData SetData=================", data)
  self.data = data
  self:SetShipBattleCount()
  if data and data.HeroIdList and #data.HeroIdList > 0 then
    self.heroIdList = data.HeroIdList
  end
  if data.LockEquipList == nil or next(data.LockEquipList) == nil then
    self.lockEquipList = {}
  else
    for _, v in pairs(data.LockEquipList) do
      self.lockEquipList[v] = true
    end
  end
  if data and data.SavePassCopyIdList then
    self.SavePassCopyIdList = data.SavePassCopyIdList
  end
  if data and data.SavePassStageCopyIdList then
    self.SavePassStageCopyIdList = data.SavePassStageCopyIdList
  end
  if data and data.PassCopyIdList then
    self.PassCopyIdList = data.PassCopyIdList
  end
end

function TowerActivityData:GetData()
  return self.data
end

function TowerActivityData:SetShipBattleCount()
  if next(self.data.SfID2Count) ~= nil then
    for _, v in pairs(self.data.SfID2Count) do
      self.shipBattleCount[v.SfID] = v.Count
    end
  else
    self.shipBattleCount = {}
  end
end

function TowerActivityData:GetShipBattleCount(tId)
  local sf_id = Logic.shipLogic:GetSfidBySmid(tId)
  return self.shipBattleCount[sf_id] or 0
end

function TowerActivityData:GetHistoryMax()
  return self.data.HistoryMax or 0
end

function TowerActivityData:ResetHeroIdList()
  self.heroIdList = {}
end

function TowerActivityData:GetHeroIdList()
  return self.heroIdList or {}
end

function TowerActivityData:IsLockEquip(equipId)
  return self.lockEquipList[equipId] ~= nil
end

function TowerActivityData:GetAllCopyList()
  return clone(self.SavePassCopyIdList) or {}
end

function TowerActivityData:GetStageCopyList()
  return clone(self.SavePassStageCopyIdList) or {}
end

function TowerActivityData:GetAllCopyTimesMap()
  local copyTimesMap = {}
  for index, copyId in pairs(self.SavePassCopyIdList) do
    local times = copyTimesMap[copyId] or 0
    copyTimesMap[copyId] = times + 1
  end
  return copyTimesMap
end

function TowerActivityData:GetCopyList()
  return self.PassCopyIdList or {}
end

function TowerActivityData:GetQuickNumber()
  return self.data.QuickNumber or 0
end

function TowerActivityData:GetCopyMap()
  local copyMap = {}
  local copyList = self:GetCopyList()
  for _, copyId in ipairs(copyList) do
    copyMap[copyId] = true
  end
  return copyMap
end

return TowerActivityData
