local MubarOutpostData = class("data.MubarOutpostData", Data.BaseData)

function MubarOutpostData:initialize()
  self:ResetData()
end

function MubarOutpostData:ResetData()
  self.allData = {}
  self.m_speedUpMaxNum = 0
end

function MubarOutpostData:GetHeroDataById(heroId)
  local heroData
  if heroId ~= nil then
    heroData = Data.heroData:GetHeroById(heroId)
  end
  return heroData
end

function MubarOutpostData:GetAllOutpostDataById(id)
  local config = configManager.GetMultiDataByKey("config_outpost_level", "outpost_id", id)
  return config
end

function MubarOutpostData:GetCurrentLevelData(id, level)
  local config = self:GetAllOutpostDataById(id)
  for key, value in pairs(config) do
    if value.level == level then
      return value
    end
  end
  return nil
end

function MubarOutpostData:SetSpeedUpMaxNum(num)
  self.m_speedUpMaxNum = num
end

function MubarOutpostData:GetSpeedUpMaxNum()
  return self.m_speedUpMaxNum
end

function MubarOutpostData:SetMubarOutPostInfoData(data)
  self.allData = data
  return self.allData
end

function MubarOutpostData:GetOutPostData()
  return self.allData.BuildingInfos
end

function MubarOutpostData:GetOutPostHeroData()
  local heroData = {}
  local allOutpostData = Data.mubarOutpostData:GetOutPostData()
  if allOutpostData then
    for i = 1, #allOutpostData do
      if allOutpostData[i].HeroList ~= nil then
        for j = 1, #allOutpostData[i].HeroList do
          if not table.containValue(heroData, allOutpostData[i].HeroList[j]) then
            table.insert(heroData, allOutpostData[i].HeroList[j])
          end
        end
      end
    end
  end
  return heroData
end

function MubarOutpostData:GetOutPostDataById(outpostId)
  if self.allData.BuildingInfos then
    for i = 1, #self.allData.BuildingInfos do
      if self.allData.BuildingInfos[i].Id == outpostId then
        return self.allData.BuildingInfos[i]
      end
    end
  end
  return nil
end

function MubarOutpostData:SetOutPostData(index, data)
  if self.allData ~= nil then
    self.allData[index].HeroList = data
  end
end

return MubarOutpostData
