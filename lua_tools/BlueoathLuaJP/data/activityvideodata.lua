local ActivityVideoData = class("data.ActivityVideoData", Data.BaseData)

function ActivityVideoData:initialize()
  self.VideoMap = {}
end

function ActivityVideoData:SetData(data)
  if not data then
    return
  end
  if data.Id and #data.Id > 0 then
    for _, v in pairs(data.Id) do
      self.VideoMap[v] = v
    end
  end
end

function ActivityVideoData:GetActVideoMap()
  return self.VideoMap
end

function ActivityVideoData:IsVideoWatched(id)
  return self.VideoMap[id] ~= nil and self.VideoMap[id] == id
end

return ActivityVideoData
