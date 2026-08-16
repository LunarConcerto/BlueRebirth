local ActivityPaperCutData = class("data.ActivityPaperCutData")

function ActivityPaperCutData:initialize()
  self.mFormulaUseData = {}
end

function ActivityPaperCutData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.FormulaUseData ~= nil and #TRet.FormulaUseData > 0 then
    for _, data in ipairs(TRet.FormulaUseData) do
      if data.FormulaId == nil or 0 >= data.FormulaId then
        self.mFormulaUseData = {}
      else
        self.mFormulaUseData[data.FormulaId] = data
      end
    end
  end
end

function ActivityPaperCutData:GetFormulaCount(formulaId)
  local data = self.mFormulaUseData[formulaId] or {}
  local count = data.Count or 0
  return count
end

function ActivityPaperCutData:GetFormulaList()
  local list = {}
  local mFormulaUseData = self.mFormulaUseData or {}
  for _, data in pairs(mFormulaUseData) do
    if data.Count > 0 then
      table.insert(list, data.FormulaId)
    end
  end
  return list
end

return ActivityPaperCutData
