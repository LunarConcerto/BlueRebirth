local MiniGameData = class("data.MiniGameData", Data.BaseData)

function MiniGameData:initialize()
  self.scoreMap = {}
end

function MiniGameData:SetData(data)
end

function MiniGameData:SetScore(id, score)
  self.scoreMap[id] = score
end

function MiniGameData:GetScore(id)
  return self.scoreMap[id] or 0
end

return MiniGameData
