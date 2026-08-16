local DiscussData = class("data.DiscussData", Data.BaseData)

function DiscussData:initialize()
  self:ResetData()
end

function DiscussData:ResetData()
  self.getDiscuss = nil
  self.discuss = nil
  self.m_disCache = {}
end

function DiscussData:SetStartDiscussData(discuss)
  self.getDiscuss = discuss
end

function DiscussData:GetStartDiscussData()
  return SetReadOnlyMeta(self.getDiscuss)
end

function DiscussData:SetDiscussData(discuss)
  self.discuss = discuss
end

function DiscussData:GetDiscussData()
  return self.discuss
end

function DiscussData:SetHeroLikeNum(num)
  self.getDiscuss.HeroLikeNum = num
end

function DiscussData:SetCacheData(sf_id, data)
  self.m_disCache[sf_id] = {
    LastTime = time.getSvrTime(),
    CacheDis = data
  }
end

function DiscussData:GetCahceData(sf_id)
  return self.m_disCache[sf_id].CacheDis
end

function DiscussData:HaveCache(sf_id)
  local cur = time.getSvrTime()
  local data = self.m_disCache[sf_id]
  return data and cur - data.LastTime <= 60
end

return DiscussData
