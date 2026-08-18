local RepaireData = class("data.RepaireData", Data.BaseData)

function RepaireData:initialize()
  self:ResetData()
end

function RepaireData:ResetData()
  self.RepaireInfo = {}
end

function RepaireData:_InitRepairData(arrCopyInfo)
  self.RepaireInfo = arrCopyInfo
end

function RepaireData:GetRepaireServiceData()
  return SetReadOnlyMeta(self.RepaireInfo)
end

return RepaireData
