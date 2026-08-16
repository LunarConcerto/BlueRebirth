local EquipNewTestData = class("data.EquipNewTestData", Data.BaseData)

function EquipNewTestData:initialize()
  self:_InitHandlers()
end

function EquipNewTestData:_InitHandlers()
  self:ResetData()
end

function EquipNewTestData:ResetData()
  self.m_teams = {}
  self.data = nil
end

function EquipNewTestData:SetData(data)
  self.data = data
  if data.EquipNewTestInfo and #data.EquipNewTestInfo > 0 then
    for _, Info in pairs(data.EquipNewTestInfo) do
      local receiveInfo = {}
      if Info.ReceivedRewards and 0 < #Info.ReceivedRewards then
        for _, received in pairs(Info.ReceivedRewards) do
          receiveInfo[received.DamageIndex] = received.ReceiveTime
        end
      end
      local tmpp = {
        maxDamage = Info.MaxDamage,
        receiveInfo = receiveInfo
      }
      self.m_teams[Info.Id] = tmpp
    end
  end
end

function EquipNewTestData:GetData()
  return self.m_teams
end

function EquipNewTestData:GetMaxDamageByCopy(copyIndex)
  if self.m_teams[copyIndex] then
    return self.m_teams[copyIndex].maxDamage or 0
  else
    return 0
  end
end

function EquipNewTestData:GetReceivedRewardsByCopy(copyIndex)
  if self.m_teams[copyIndex] then
    return self.m_teams[copyIndex].receiveInfo or {}
  else
    return {}
  end
end

return EquipNewTestData
