local AdventureData = class("data.AdventureData", Data.BaseData)

function AdventureData:initialize()
  self.EnemyIndex = 0
  self.Role = {}
  self.Enemy = {}
end

function AdventureData:SetData(data)
  if not data then
    return
  end
  if data.Role then
    for index, value in ipairs(data.Role) do
      self.Role[value.RoleId] = value
    end
  end
  if data.Enemy then
    for index, value in ipairs(data.Enemy) do
      self.Enemy[value.Index] = value.Damage
    end
  end
  self.EnemyIndex = data.EnemyIndex
end

function AdventureData:GetLevelById(id)
  return self.Role[id].Level
end

function AdventureData:GetHpById(id)
  return self.Role[id].Hp
end

function AdventureData:GetIndex()
  return self.EnemyIndex
end

function AdventureData:GetEnemyDamage()
  return self.Enemy[self.EnemyIndex] or 0
end

return AdventureData
