local StudyData = class("data.StudyData", Data.BaseData)

function StudyData:initialize()
  self:_InitHandlers()
end

function StudyData:_InitHandlers()
  self:ResetData()
  self:RegisterEvent(LuaEvent.GetStudyInfo, self.SetData)
end

function StudyData:ResetData()
  self.data = {}
end

function StudyData:SetData(proto)
  self.data = proto
end

function StudyData:GetStudyData()
  return SetReadOnlyMeta(self.data)
end

function StudyData:GetStudyByHero(heroId)
  for _, v in ipairs(self.data) do
    if v.HeroId == heroId then
      return v
    end
  end
  return nil
end

function StudyData:RemoveDataByHeroId(heroId)
  local removeIndex
  for i, v in ipairs(self.data.ArrProgress) do
    if v.HeroId == heroId then
      removeIndex = i
      break
    end
  end
  table.remove(self.data.ArrProgress, removeIndex)
end

function StudyData:AddDataManual(info)
  local temp = 0
  for i, v in ipairs(self.data.ArrProgress) do
    if v.HeroId == info.HeroId and v.PSkillId == info.PSkillId then
      temp = i
    end
  end
  if 0 < temp and temp <= #self.data.ArrProgress then
    self.data.ArrProgress[temp] = info
  else
    table.insert(self.data.ArrProgress, info)
  end
end

return StudyData
