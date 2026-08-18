local DismantleLogic = class("logic.DismantleLogic")

function DismantleLogic:initialize()
  self:ResetData()
end

function DismantleLogic:ResetData()
  self.m_delEquips = {}
  self.m_count = 0
  self.tabHeroDismantleEquip = {}
end

function DismantleLogic:GetDismantleSortSet()
  local localRecord = Logic.bagLogic:GetSortRecord()
  local dismantleSort = {}
  dismantleSort.Type = localRecord.Type
  dismantleSort.Sort = localRecord.Sort
  dismantleSort.Screen = localRecord.Screen
  dismantleSort.Order = 1
  dismantleSort.UseEquip = 0
  dismantleSort.AttrEquip = 0
  return dismantleSort
end

function DismantleLogic:AddDismantleEquip(equipId)
  local have = self.m_delEquips[equipId]
  if not have and Logic.equipLogic:CanDelectById(equipId) then
    self.m_count = self.m_count + 1
    self.m_delEquips[equipId] = true
  end
end

function DismantleLogic:SetDismantleEquip(tabEquipId)
  tabEquipId = tabEquipId or {}
  for _, id in ipairs(tabEquipId) do
    self:AddDismantleEquip(id)
  end
end

function DismantleLogic:RemoveDismantleEquip(equipId)
  local have = self.m_delEquips[equipId]
  if have then
    self.m_count = self.m_count - 1
    self.m_delEquips[equipId] = nil
  end
end

function DismantleLogic:ResetDismantleEquip()
  self.m_delEquips = {}
  self.m_count = 0
end

function DismantleLogic:GetDismantleEquip()
  return self.m_delEquips or {}
end

function DismantleLogic:GetDismantleNum()
  return self.m_count
end

function DismantleLogic:GetEquipDataInfo(equipIds)
  local tabEquip = {}
  for k, v in pairs(equipIds) do
    local equipData = Data.equipData:GetEquipDataById(v)
    table.insert(tabEquip, equipData)
  end
  return tabEquip
end

function DismantleLogic:ToArray(map)
  local array = {}
  for id, _ in pairs(map) do
    table.insert(array, id)
  end
  return array
end

return DismantleLogic
