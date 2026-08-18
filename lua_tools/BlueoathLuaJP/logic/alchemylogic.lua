local AlchemyLogic = class("logic.AlchemyLogic")

function AlchemyLogic:initialize()
  self:ResetData()
end

function AlchemyLogic:ResetData()
  self.selectFormulaIndex = 1
  self.selectTogIndex = 0
end

function AlchemyLogic:GetAlchemyItemConf(id)
  local itemConfig = configManager.GetDataById("config_ryza_alchemy_item", id)
  return itemConfig
end

function AlchemyLogic:GetAlchemyFormula(id)
  local formulaConf = configManager.GetDataById("config_ryza_alchemy_formula", id)
  return formulaConf
end

function AlchemyLogic:GetAlchemyItemType(id)
  local itemTypeConf = configManager.GetDataById("config_ryza_alchemy_type", id)
  return itemTypeConf
end

function AlchemyLogic:SetSelectFormula(index)
  self.selectFormulaIndex = index
end

function AlchemyLogic:GetSelectFormula()
  return self.selectFormulaIndex
end

function AlchemyLogic:SetSelectTog(index)
  self.selectTogIndex = index
end

function AlchemyLogic:GetSelectTog()
  return self.selectTogIndex
end

function AlchemyLogic:GetAlchemyFormulaByType(fType)
  local formulaTab = {}
  local formulaData = Data.alchemyData:GetOwnAlchemy()
  for _, v in pairs(formulaData) do
    if v.formula_type == fType then
      table.insert(formulaTab, v)
    end
  end
  table.sort(formulaTab, function(a, b)
    return a.id < b.id
  end)
  return formulaTab
end

function AlchemyLogic:CheckExpendNum(fId)
  local formulaConf = self:GetAlchemyFormula(fId)
  local expendTab = {}
  for _, itemId in ipairs(formulaConf.item_group) do
    local itemConf = self:GetAlchemyItemConf(itemId)
    local materialType = itemConf.materials[1]
    local materialId = itemConf.materials[2]
    local num = itemConf.materials[3]
    if expendTab[materialId] == nil then
      expendTab[materialId] = {expendNum = num, expendType = materialType}
    else
      expendTab[materialId].expendNum = expendTab[materialId].expendNum + num
    end
  end
  for id, info in pairs(expendTab) do
    local limitNum = info.expendNum
    local ownValue = 0
    local expendType = info.expendType
    if expendType == GoodsType.CURRENCY then
      ownValue = Data.userData:GetCurrency(id)
    elseif expendType == GoodsType.EQUIP then
      _, ownValue = self:GetEquipInfoByTid(id)
    else
      ownValue = Data.bagData:GetItemNum(id)
    end
    if limitNum > ownValue then
      return false, expendType, id
    end
  end
  return true
end

function AlchemyLogic:CheckExpendByMaterial(formulaItemConf, formulaAddItem)
  local formulaItemId = formulaItemConf.id
  local material = formulaItemConf.materials
  if material[1] == GoodsType.CURRENCY then
    value = Data.userData:GetCurrency(material[2])
  elseif material[1] == GoodsType.EQUIP then
    _, value = self:GetEquipInfoByTid(material[2])
  else
    value = Data.bagData:GetItemNum(material[2])
  end
  for id, v in pairs(formulaAddItem) do
    if v.materialId == material[2] and formulaItemId ~= id then
      value = value - 1
    end
  end
  if value < material[3] then
    return false
  end
  return true
end

function AlchemyLogic:SaveClickedFormula(formulaId)
  local ownFormula = Data.alchemyData:CheckOwnAlchemy(formulaId)
  if not ownFormula then
    return false
  end
  local clickedFormulaTab = Logic.alchemyLogic:GetClickedFormulaTab()
  local strRecord = ""
  for k, v in pairs(clickedFormulaTab) do
    strRecord = strRecord .. ";" .. v
  end
  strRecord = strRecord .. ";" .. formulaId
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetString(uid .. "ClickedFormula", strRecord)
end

function AlchemyLogic:GetClickedFormulaTab()
  local uid = Data.userData:GetUserUid()
  local clickedFormulaTab = {}
  local strRecord = PlayerPrefs.GetString(uid .. "ClickedFormula")
  if strRecord == nil then
    return {}
  end
  local str = string.split(strRecord, ";")
  for k, v in pairs(str) do
    if v ~= nil and v ~= "" then
      clickedFormulaTab[tonumber(v)] = tonumber(v)
    end
  end
  return clickedFormulaTab
end

function AlchemyLogic:RecoredFormulaId(formulaId)
  local clickedFormulaTab = Logic.alchemyLogic:GetClickedFormulaTab()
  for _, id in pairs(clickedFormulaTab) do
    if id == formulaId then
      return true
    end
  end
  return false
end

function AlchemyLogic:CheckShowRed(formulaId)
  local ownFormula = Data.alchemyData:CheckOwnAlchemy(formulaId)
  if not ownFormula then
    return false
  end
  local recored = self:RecoredFormulaId(formulaId)
  return not recored
end

function AlchemyLogic:GetExpendGoodsConfig(material)
  local config
  local materialType = material[1]
  local materialId = material[2]
  if materialType == GoodsType.EQUIP then
    config = Logic.equipLogic:GetEquipConfigById(materialId)
  else
    config = Logic.itemLogic:GetItemConf(materialId)
  end
  return config
end

function AlchemyLogic:GetEquipInfoByTid(tid)
  local equipData = Data.equipData:GetTidMapEquip(tid)
  local equipInfoTab = {}
  for _, v in pairs(equipData) do
    if v.HeroId == 0 and v.EnhanceLv == 0 then
      table.insert(equipInfoTab, v)
    end
  end
  return equipInfoTab, #equipInfoTab
end

return AlchemyLogic
