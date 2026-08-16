local EquipData = class("data.EquipData", Data.EquipData)

function EquipData:initialize()
  self:_InitHandlers()
end

function EquipData:_InitHandlers()
  self:ResetData()
end

function EquipData:ResetData()
  self.EquipBagSize = 0
  self.EquipInfo = {}
  self.newEquip = {}
  self.equipNum = {}
  self.m_equipHeroMap = {}
  self.tabSelectEquip = {}
  self.m_isSetData = false
  self.m_cacheHeros = {}
  self.m_tid2equips = {}
  self.m_qly2cequips = {}
  self.m_type2equips = {}
end

function EquipData:IsSetData()
  return self.m_isSetData
end

function EquipData:SetData(param)
  self.m_isSetData = true
  for i, v in pairs(param.EquipInfo) do
    if v.TemplateId ~= 0 then
      self.EquipInfo[v.EquipId] = v
      self:_AddEquipExData(v)
      if 0 < v.HeroId then
        self:_CacheEquipHeros(v.HeroId)
      end
    else
      self.EquipInfo[v.EquipId] = nil
      self:_RemoveEquipExData(v.EquipId)
    end
  end
  self:_RecalHerosExData()
end

function EquipData:UpdateEquip(param)
  if next(param) == nil then
    return
  end
  self.m_isSetData = true
  self:SetRecordNewEquip(param)
  for i, v in pairs(param.EquipInfo) do
    if v.TemplateId ~= 0 then
      self.EquipInfo[v.EquipId] = v
      self:_AddEquipExData(v)
      if 0 < v.HeroId then
        self:_CacheEquipHeros(v.HeroId)
      end
    else
      self.EquipInfo[v.EquipId] = nil
      self:_RemoveEquipExData(v.EquipId)
    end
  end
  if param.EquipBagSize ~= nil then
    self.EquipBagSize = param.EquipBagSize
  end
  if param.EquipNum ~= nil and 0 < #param.EquipNum then
    for i, v in ipairs(param.EquipNum) do
      self.equipNum[v.TemplateId] = Mathf.ToInt(v.Num)
    end
  end
  self:_RecalHerosExData()
end

function EquipData:_AddEquipExData(equip)
  local tid2equips = self.m_tid2equips
  local qly2cequips = self.m_qly2cequips
  local type2equips = self.m_type2equips
  local templateId = equip.TemplateId
  local types = configManager.GetDataById("config_equip", templateId).ewt_id
  local SvrData = function(sets, item, key)
    local id = item.EquipId
    if sets[key] == nil then
      sets[key] = {
        [id] = item
      }
    else
      sets[key][id] = item
    end
  end
  SvrData(tid2equips, equip, templateId)
  if self:_IsCommonEquip(templateId) then
    local quality = self:_GetEquipQuality(templateId)
    SvrData(qly2cequips, equip, quality)
  end
  for _, type in ipairs(types) do
    SvrData(type2equips, equip, type)
  end
end

function EquipData:_RemoveEquipExData(equipId)
  local tid2equips = self.m_tid2equips
  local qly2cequips = self.m_qly2cequips
  local type2equips = self.m_type2equips
  local SvrData = function(sets, id)
    for key, equips in pairs(sets) do
      if equips[id] then
        sets[key][id] = nil
        if next(sets[key]) == nil then
          sets[key] = nil
        end
        break
      end
    end
  end
  SvrData(tid2equips, equipId)
  SvrData(qly2cequips, equipId)
  SvrData(type2equips, equipId)
end

function EquipData:_CacheEquipHeros(heroId)
  table.insert(self.m_cacheHeros, heroId)
end

function EquipData:_RecalHerosExData()
  for _, id in ipairs(self.m_cacheHeros) do
    eventManager:SendEvent(LuaEvent.HERO_TryUpdateHeroExData, id)
  end
  self.m_cacheHeros = {}
end

function EquipData:GetEquipGetNum(id)
  return self.equipNum[id] or 0
end

function EquipData:SetRecordNewEquip(param)
  if next(self.EquipInfo) == nil then
    self.newEquip = {}
  else
    for i, v in ipairs(param.EquipInfo) do
      if self.EquipInfo[v.EquipId] == nil then
        table.insert(self.newEquip, v)
      end
    end
  end
end

function EquipData:ClearRecord()
  self.newEquip = {}
end

function EquipData:GetRecordNewEquip()
  return self.newEquip
end

function EquipData:UpdateNewEquip(equipTab)
  self.newEquip = equipTab
end

function EquipData:GetEquipData()
  return SetReadOnlyMeta(self.EquipInfo)
end

function EquipData:GetEquipDataById(equipId)
  if self.EquipInfo[equipId] then
    return SetReadOnlyMeta(self.EquipInfo[equipId])
  elseif npcAssistFleetMgr:GetNpcEquip(equipId) then
    return SetReadOnlyMeta(npcAssistFleetMgr:GetNpcEquip(equipId))
  else
    return nil
  end
end

function EquipData:GetEquipBagSize()
  return self.EquipBagSize
end

function EquipData:GetRiseCommonEquip(equipId)
  local data = Data.equipData:GetEquipDataById(equipId)
  if data then
    local riseCost = data.RiseCommonEquips or {}
    local res = {}
    for _, info in ipairs(riseCost) do
      res[info.TemplateId] = info.Num
    end
    return res
  else
    return {}
  end
end

function EquipData:GetCommonEquips(quality)
  local map = self.m_qly2cequips[quality]
  if map then
    local array = {}
    for _, v in pairs(map) do
      table.insert(array, v)
    end
    return array
  else
    return {}
  end
end

function EquipData:GetEquipsByTid(templateId)
  return self.m_tid2equips[templateId] or {}
end

function EquipData:GetEquipsByType(type)
  return self.m_type2equips[type] or {}
end

function EquipData:_IsCommonEquip(templateId)
  local config = self:_GetEquipConfigById(templateId)
  return config and config.equip_type_id == CommonRiseEquipTag
end

function EquipData:_GetEquipConfigById(templateId)
  return configManager.GetDataById("config_equip", templateId)
end

function EquipData:_GetEquipQuality(templateId)
  local config = self:_GetEquipConfigById(templateId)
  return config and config.quality or 0
end

function EquipData:RefreshHeroEquipData()
  local data = Data.heroData:GetHeroData()
  local res, equipInfo = {}, {}
  for id, info in pairs(data) do
    equipInfo = info.Equips
    for type, equips in pairs(equipInfo) do
      for _, equip in ipairs(equips) do
        if equip.EquipsId > 0 then
          if res[equip.EquipsId] == nil then
            res[equip.EquipsId] = {}
          end
          res[equip.EquipsId][type] = {
            HeroId = id,
            State = equip.state
          }
        end
      end
    end
  end
  self.m_equipHeroMap = res
end

function EquipData:GetEquipState(equipId, fleetType)
  fleetType = fleetType or FleetType.Normal
  if self.m_equipHeroMap[equipId] and self.m_equipHeroMap[equipId][fleetType] then
    return self.m_equipHeroMap[equipId][fleetType].State or MEquipState.OPEN
  end
  return MEquipState.OPEN
end

function EquipData:GetEquipHero(equipId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local temp = self.m_equipHeroMap[equipId]
  if temp and temp[fleetType] then
    temp = temp[fleetType]
    return temp.HeroId or 0
  end
  return 0
end

function EquipData:ResetConsumeEquip()
  self.tabSelectEquip = {}
end

function EquipData:SetConsumeEquip(tabSelectEquip)
  self.tabSelectEquip = tabSelectEquip
end

function EquipData:GetConsumeEquip()
  return self.tabSelectEquip
end

return EquipData
