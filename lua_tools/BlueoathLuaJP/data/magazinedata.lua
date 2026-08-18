local MagazineData = class("data.MagazineData", Data.BaseData)

function MagazineData:initialize()
  self.heroMap = {}
  self.rewardData = {}
  self.data = {}
  self.unLockMap = {}
end

function MagazineData:SetRewardData(data)
  if data then
    self.rewardData = {}
    for i, magazineSub in ipairs(data.MagazineSub) do
      self.rewardData[magazineSub.MagazineId] = {}
      for index, info in ipairs(magazineSub.MagazineSubReward) do
        self.rewardData[magazineSub.MagazineId][info.Index] = info.Time
      end
    end
    self.heroMap = {}
    for index, heroInfo in ipairs(data.MagazineHero) do
      self.heroMap[heroInfo.Index] = heroInfo.HeroId
    end
    self.unLockMap = {}
    for index, info in ipairs(data.MagazineUnLock) do
      self.unLockMap[info.MagazineId] = info.Time
    end
  end
end

function MagazineData:SetData(data)
  if data then
    self.data = {}
    for i, v in ipairs(data.MagazineIdList) do
      self.data[v] = true
    end
  end
end

function MagazineData:GetData(data)
  return self.data
end

function MagazineData:IsOpenById(id)
  return self.data[id]
end

function MagazineData:IsUnLockById(id)
  local time = self.unLockMap[id] or 0
  return 0 < time
end

function MagazineData:GetHeroMap()
  return self.heroMap
end

function MagazineData:GetHeroIdByIndex(index)
  return self.heroMap[index] or 0
end

function MagazineData:GetFetchRewardTime(magazineId, index)
  if not self.rewardData[magazineId] then
    return 0
  end
  return self.rewardData[magazineId][index] or 0
end

return MagazineData
