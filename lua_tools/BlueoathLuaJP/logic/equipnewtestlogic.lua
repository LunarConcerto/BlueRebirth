local EquipNewTestLogic = class("logic.EquipNewTestLogic")

function EquipNewTestLogic:initialize()
  self:ResetData()
end

function EquipNewTestLogic:ResetData()
  self.noOpenPage = true
  self.m_curIndex = 1
end

function EquipNewTestLogic:SetDot(_bool)
  self.noOpenPage = _bool
end

function EquipNewTestLogic:GetDot()
  return self.noOpenPage
end

function EquipNewTestLogic:SetCopyIndex(index)
  self.m_curIndex = index
end

function EquipNewTestLogic:GetCopyIndex()
  return self.m_curIndex
end

return EquipNewTestLogic
