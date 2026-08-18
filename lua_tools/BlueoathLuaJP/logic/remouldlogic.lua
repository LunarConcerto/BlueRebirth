local RemouldLogic = class("logic.RemouldLogic")

function RemouldLogic:initialize()
end

function RemouldLogic:ResetData()
  self.CurrStageLv = 0
  self.beforeRemouldData = nil
end

function RemouldLogic:GetRemouldStageById(stageId)
  local remouldStageConfig = configManager.GetDataById("config_ship_remould_template", stageId)
  return remouldStageConfig
end

function RemouldLogic:GetRemouldEffectById(effectId)
  local remouldEffectConfig = configManager.GetDataById("config_ship_remould_effect", effectId)
  return remouldEffectConfig
end

function RemouldLogic:GetRemouldModelById(id)
  local modelConf = configManager.GetDataById("config_ship_remould_show", id)
  return modelConf
end

function RemouldLogic:CkeckHeroRemouldLimit(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(heroId)
  return shipInfoConfig.min_level <= heroInfo.Lvl
end

function RemouldLogic:CkeckHeroRemoulding(heroId)
  local remouldData = self:GetHeroRemouldData(heroId)
  if next(remouldData.ArrRemouldEffect) ~= nil then
    return true
  end
  return false
end

function RemouldLogic:CkeckHeroRemouldMax(heroId)
  local remouldData = self:GetHeroRemouldData(heroId)
  self.shipInfoConf = Logic.shipLogic:GetShipInfoByHeroId(heroId)
  if #self.shipInfoConf.remould_template == remouldData.RemouldLV then
    return true
  end
  return false
end

function RemouldLogic:CkeckHeroRemouldStageOpen(heroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(heroId)
  return #shipInfoConfig.remould_template > 0
end

function RemouldLogic:CkeckHeroRemouldOpen(heroId)
  local limit = self:CkeckHeroRemouldLimit(heroId)
  local stageOpen = self:CkeckHeroRemouldStageOpen(heroId)
  return limit and stageOpen
end

function RemouldLogic:CountFinalAttr(arrRemouldEffect)
  local attrValue = {}
  local mapAttrValue = {}
  local tabAttrValue = {}
  if arrRemouldEffect == nil then
    return
  end
  for k, v in pairs(arrRemouldEffect) do
    local remouldItem = configManager.GetDataById("config_ship_remould_effect", v)
    for id, value in pairs(remouldItem.remould_effect_type) do
      if value[1] == RemouldEffectType.Attr then
        table.insert(attrValue, value)
      end
    end
  end
  for k, value in pairs(attrValue) do
    if mapAttrValue[value[2]] then
      mapAttrValue[value[2]] = mapAttrValue[value[2]] + value[3]
    else
      mapAttrValue[value[2]] = value[3]
    end
  end
  for k, v in pairs(mapAttrValue) do
    table.insert(tabAttrValue, {k, v})
  end
  return tabAttrValue
end

function RemouldLogic:GetHeroRemouldData(heroId)
  local remouldData = {}
  local heroData = Data.heroData:GetHeroById(heroId)
  remouldData.ArrRemouldEffect = {}
  for i, v in ipairs(heroData.ArrRemouldEffect) do
    remouldData.ArrRemouldEffect[v] = v
  end
  remouldData.RemouldLV = heroData.RemouldLV
  return remouldData
end

function RemouldLogic:CheckOwnRemouldFashion(heroId, fashionId)
  local remoulded = self:CkeckHeroRemoulding(heroId)
  if not remoulded then
    return false
  end
  local heroData = Data.heroData:GetHeroById(heroId)
  for _, effId in ipairs(heroData.ArrRemouldEffect) do
    local effConfig = self:GetRemouldEffectById(effId)
    for _, v in ipairs(effConfig.remould_effect_type) do
      if v[1] == RemouldEffectType.Fashion and fashionId == v[2] then
        return true
      end
    end
  end
  return false
end

function RemouldLogic:GetStageAllInfo(heroId)
  local allEffectTab = {}
  local heroData = Data.heroData:GetHeroById(heroId)
  for _, effId in pairs(heroData.ArrRemouldEffect) do
    local effInfo = self:GetRemouldEffectById(effId)
    local remouldEffTab = effInfo.remould_effect_type
    for _, v in ipairs(remouldEffTab) do
      local effType = v[1]
      if allEffectTab[effType] == nil then
        allEffectTab[effType] = {}
      end
      if effType == RemouldEffectType.Attr then
        table.insert(allEffectTab[effType], v)
      else
        allEffectTab[effType] = v
      end
    end
  end
  return allEffectTab
end

function RemouldLogic:DisposeAttrEff(effectType)
  local effectTab = {}
  local attrTab = {}
  for _, v in ipairs(effectType) do
    local effType = v[1]
    if effectTab[effType] == nil then
      effectTab[effType] = {}
    end
    if effType == RemouldEffectType.Attr then
      table.insert(effectTab[effType], v)
    else
      effectTab[effType] = v
    end
  end
  return effectTab
end

function RemouldLogic:GetDisplayAttr(attrTab)
  local attrDisplay = {}
  for _, v in ipairs(attrTab) do
    local attrId = v[2]
    local attrNum = v[3]
    if attrDisplay[attrId] ~= nil then
      local allNum = attrDisplay[attrId][3] + attrNum
      local tab = {
        v[1],
        v[2],
        allNum
      }
      attrDisplay[attrId] = tab
    else
      attrDisplay[attrId] = v
    end
  end
  local retTab = {}
  for _, v in pairs(attrDisplay) do
    table.insert(retTab, v)
  end
  return retTab
end

function RemouldLogic:GetRemouldEffectData(effectId, completeEffTab)
  local effectData = {}
  effectData.config = self:GetRemouldEffectById(effectId)
  effectData.isCompleted = completeEffTab[effectId] ~= nil
  local isLock = false
  for i, v in ipairs(effectData.config.remould_prev) do
    if completeEffTab[v] ~= nil then
      isLock = false
      break
    end
    isLock = true
  end
  effectData.isLock = isLock
  return effectData
end

function RemouldLogic:CheckStageFinish(stageLv)
  return stageLv > self.CurrStageLv
end

function RemouldLogic:SetCurrStageLv(stageLv)
  self.CurrStageLv = stageLv
end

function RemouldLogic:GetCurrSelectStage(remouldLV, stageTab)
  local selectStage = remouldLV < #stageTab and remouldLV + 1 or #stageTab
  for i, v in ipairs(stageTab) do
    local stageConfig = Logic.remouldLogic:GetRemouldStageById(v)
    if #stageConfig.remould_item_group == 0 and i == selectStage then
      selectStage = remouldLV
    end
  end
  return selectStage
end

function RemouldLogic:CheckFirstEnterRecord(heroId, uid)
  local recorded = PlayerPrefs.GetBool("RemouldFirstSceneAnim" .. uid .. heroId, false)
  return recorded
end

function RemouldLogic:RecordSceneAnim(uid, index)
  PlayerPrefs.SetBool("RemouldSceneAnim" .. index .. uid, true)
end

function RemouldLogic:CheckSceneAnimRecorded(index)
  local uid = Data.userData:GetUserUid()
  local recorded = PlayerPrefs.GetBool("RemouldSceneAnim" .. index .. uid, false)
  return recorded
end

function RemouldLogic:SetBeforeRemouldData(data)
  self.beforeRemouldData = data
end

function RemouldLogic:GetBeforeRemouldData()
  return self.beforeRemouldData
end

return RemouldLogic
