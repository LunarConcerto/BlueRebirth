local EquipTestCopyData = class("data.EquipTestCopyData", Data.BaseData)

function EquipTestCopyData:initialize()
  self:ResetData()
end

function EquipTestCopyData:ResetData()
  self.equipTestData = {}
end

function EquipTestCopyData:SetData(param)
  if param.MaxDamage then
    self.equipTestData.MaxDamage = param.MaxDamage
  end
  if param.ReceivedRewards then
    self.equipTestData.ReceivedRewards = param.ReceivedRewards
  end
end

function EquipTestCopyData:GetMaxDamage()
  return self.equipTestData.MaxDamage
end

function EquipTestCopyData:GetReceivedRewards()
  return self.equipTestData.ReceivedRewards
end

return EquipTestCopyData
