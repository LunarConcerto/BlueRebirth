local AlchemyData = class("data.AlchemyData", Data.BaseData)

function AlchemyData:initialize()
  self:ResetData()
end

function AlchemyData:ResetData()
  self.OwnAlchemy = {}
  self.OwnAlchemyMap = {}
  self.FastFormulaMap = {}
end

function AlchemyData:SetData(data)
  self.OwnAlchemyMap = {}
  self.FastFormulaMap = {}
  self.OwnAlchemy = {}
  for _, v in ipairs(data.allFormula) do
    local formulaConf = configManager.GetDataById("config_ryza_alchemy_formula", v.templateId)
    table.insert(self.OwnAlchemy, formulaConf)
  end
  for key, value in ipairs(data.allFormula) do
    self.OwnAlchemyMap[value.templateId] = key
  end
  for key, value in ipairs(data.fastFormula) do
    self.FastFormulaMap[value] = key
  end
end

function AlchemyData:GetOwnAlchemy()
  return self.OwnAlchemy
end

function AlchemyData:CheckOwnAlchemy(formulaId)
  return self.OwnAlchemyMap[formulaId] ~= nil
end

function AlchemyData:CheckFastAlchemy(formulaId)
  return self.FastFormulaMap[formulaId] ~= nil
end

return AlchemyData
