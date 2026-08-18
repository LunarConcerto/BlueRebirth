local BuildData = class("data.BuildData", Data.BaseData)

function BuildData:initialize()
  self:_InitHandlers()
end

function BuildData:_InitHandlers()
  self:ResetData()
end

function BuildData:ResetData()
  self.sequeInfo = {}
  self.notesInfo = {}
  self.mapNotesInfo = {}
end

function BuildData:SetData(param)
  self.sequeInfo = param
end

function BuildData:GetData()
  return SetReadOnlyMeta(self.sequeInfo)
end

function BuildData:SetNotesData(param)
  if next(self.notesInfo) == nil then
    self.notesInfo = param
  else
    for key, value in pairs(param.List) do
      self.mapNotesInfo[value.BuildedInfo.HeroId] = value
    end
    for k, v in pairs(self.notesInfo.List) do
      if self.mapNotesInfo[v.BuildedInfo.HeroId] then
        self.notesInfo.List[k] = self.mapNotesInfo[v.BuildedInfo.HeroId]
        self.mapNotesInfo[v.BuildedInfo.HeroId] = nil
      end
    end
  end
  for key, value in pairs(self.mapNotesInfo) do
    table.insert(self.notesInfo.List, value)
  end
  for k, v in pairs(self.notesInfo.List) do
    local notesData = v.BuildedInfo.Project
    if notesData.Gold > 999 or 999 < notesData.Items[1].Count or 999 < notesData.Items[2].Count then
      table.remove(self.notesInfo.List, k)
    end
  end
end

function BuildData:GetNotesData()
  return SetReadOnlyMeta(self.notesInfo)
end

return BuildData
