local ActivityBirthdayData = class("data.ActivityBirthdayData", Data.BaseData)
BirthdayTeams = {A = 1, B = 2}

function ActivityBirthdayData:initialize()
  self:ResetData()
end

function ActivityBirthdayData:ResetData()
  self.m_teams = {}
  self.m_affair = 0
  self.stage = {}
  self.data = nil
end

function ActivityBirthdayData:SetData(data)
  self:SetBirthdayInfo(data)
end

function ActivityBirthdayData:SetBirthdayInfo(data)
  self.data = data
  if data.BirthdayAffair then
    self.m_affair = data.BirthdayAffair
  end
  if data.GirlsAndCake and #data.GirlsAndCake > 0 then
    for _, v in pairs(data.GirlsAndCake) do
      local tmp = {
        girl = v.Girl,
        cake = v.Cake
      }
      self.m_teams[v.TeamId] = tmp
    end
  end
  if data.Stage and 0 < #data.Stage then
    for _, v in pairs(data.Stage) do
      self.stage[v] = v
    end
  end
end

function ActivityBirthdayData:GetBirthdayaffairInfo()
  return self.m_affair or 0
end

function ActivityBirthdayData:GetBirthdayteamsInfo()
  return self.m_teams or {}
end

function ActivityBirthdayData:GetBirthdayReceiveInfo()
  return self.stage
end

function ActivityBirthdayData:GetBirthdayFreshData()
  return self.data
end

return ActivityBirthdayData
