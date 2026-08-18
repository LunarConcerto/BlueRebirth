local BeStrongLogic = class("logic.BeStrongLogic")

function BeStrongLogic:initialize()
  self:ResetData()
end

function BeStrongLogic:ResetData()
  self.toStrongPageData = nil
end

function BeStrongLogic:SetStrongPageData(data)
  self.toStrongPageData = data
end

function BeStrongLogic:GetStrongPageData()
  local data = self.toStrongPageData
  self.toStrongPageData = nil
  return data
end

return BeStrongLogic
