local SearchGoodsData = class("data.SearchGoodsData", Data.BaseData)

function SearchGoodsData:initialize()
  self:ResetData()
end

function SearchGoodsData:ResetData()
  self.data = nil
  self.curTeamId = 1
  self.receiveTime = 0
  self.searchInfo = {}
  self.m_isUpdate = false
end

function SearchGoodsData:SetData(data)
  self:SetSearchGoodsInfo(data)
end

function SearchGoodsData:SetSearchGoodsInfo(data)
  self.data = data
  if data.TeamId then
    self.curTeamId = data.TeamId
  end
  if data.ReceiveTime then
    self.receiveTime = data.ReceiveTime
  end
  if data.SearchInfo then
    for _, v in pairs(data.SearchInfo) do
      self.searchInfo[v.Id] = v.State
    end
  end
  self.m_isUpdate = true
end

function SearchGoodsData:GetLastReceiveTime()
  return self.receiveTime or 0
end

function SearchGoodsData:GetCurTeamId()
  return self.curTeamId or 1
end

function SearchGoodsData:GetSearchMap()
  return self.searchInfo or {}
end

function SearchGoodsData:GetIsUpdate()
  return self.m_isUpdate
end

return SearchGoodsData
