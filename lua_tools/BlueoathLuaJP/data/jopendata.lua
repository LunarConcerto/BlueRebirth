local JOpenData = class("data.JOpenData", Data.BaseData)

function JOpenData:initialize()
  self.FetchHeroTime = 0
  self.FetchEquipTime = 0
  self.selectIndex = nil
end

function JOpenData:SetData(data)
  if data then
    self.FetchHeroTime = data.FetchHeroTime
    self.FetchEquipTime = data.FetchEquipTime
  end
end

function JOpenData:GetFetchHeroTime()
  return self.FetchHeroTime
end

function JOpenData:GetFetchEquipTime()
  return self.FetchEquipTime
end

function JOpenData:SetSelectIndex(selectIndex)
  self.selectIndex = selectIndex
end

function JOpenData:ResetSelectIndex()
  self.selectIndex = nil
end

function JOpenData:GetSelectIndex()
  return self.selectIndex
end

return JOpenData
