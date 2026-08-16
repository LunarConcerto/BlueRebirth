local EquipLogic = class("logic.EquipLogic")

function EquipLogic:initialize()
  self:ResetData()
  self:RegisterAllEvent()
end

function EquipLogic:ResetData()
  self.cacheDisReward = {}
  self.cacheObj = {}
  self.m_inActivity = false
  self.m_l2e = {}
  self.m_autoDelete = false
  self:_HandleConfig()
  self.modi = true
end

function EquipLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdateActivity, self._OnUpdateActivity, self)
end

function EquipLogic:_OnUpdateActivity()
  self.modi = true
end

function EquipLogic:_HandleConfig()
  self:_HandleEquipConfig()
end

function EquipLogic:_HandleEquipConfig()
  local l2e = {}
  local configs = configManager.GetData("config_equip")
  for id, config in pairs(configs) do
    if #config.copy_display_id > 0 then
      for _, copyId in ipairs(config.copy_display_id) do
        if l2e[copyId] then
          table.insert(l2e[copyId], id)
        else
          l2e[copyId] = {id}
        end
      end
    end
  end
  self.m_l2e = l2e
end

function EquipLogic:GetEquipConfigById(templateId)
  return configManager.GetDataById("config_equip", templateId)
end

function EquipLogic:GetIcon(id)
  local config = configManager.GetDataById("config_equip", id)
  return config.icon
end

function EquipLogic:GetName(id)
  local config = configManager.GetDataById("config_equip", id)
  return config.name
end

function EquipLogic:GetDesc(id)
  return ""
end

function EquipLogic:GetQuality(id)
  local config = configManager.GetDataById("config_equip", id)
  return config.quality
end

function EquipLogic:GetFrame(id)
  return "", ""
end

function EquipLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_equip", id)
  return config.icon
end

function EquipLogic:GetQualityByEquipId(equipId)
  local equip = Data.equipData:GetEquipDataById(equipId)
  if equip == nil then
    logError("EQUIP DATA ERROR: can not find equip data about equipId:" .. equipId)
    return 0
  end
  local config = configManager.GetDataById("config_equip", equip.TemplateId)
  return config.quality
end

function EquipLogic:GetItemId(id)
  local config = configManager.GetDataById("config_fragment", id)
  return config.item_id
end

function EquipLogic:m_LLAttrCheck(tid, copyId)
  local isll, copys = self:IsLLEquip(tid)
  if isll then
    if not copyId or copyId == 0 then
      return false
    else
      return table.containV(copys, copyId)
    end
  end
  return true
end

function EquipLogic:GetCurEquipProperty(id, copyId)
  local equip = Logic.equipLogic:GetEquipById(id)
  local tid = equip.TemplateId
  if not self:m_LLAttrCheck(tid, copyId) then
    return {}
  end
  local config = configManager.GetDataById("config_equip", tid)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  local counter = 0
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, equip.EnhanceLv)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, equip.EnhanceLv)
    end
  end
  for k, v in pairs(attr) do
    if v.value == 0 then
      attr[k] = nil
    end
  end
  return attr
end

function EquipLogic:GetCurEquipPropertyByTid(tid, copyId)
  if not self:m_LLAttrCheck(tid, copyId) then
    return {}
  end
  local config = configManager.GetDataById("config_equip", tid)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, 0)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, 0)
    end
  end
  for k, v in pairs(attr) do
    if v.value == 0 then
      attr[k] = nil
    end
  end
  return attr
end

function EquipLogic:GetCurEquipFinaAttr(id)
  local attr = Logic.equipLogic:GetCurEquipProperty(id)
  return self:_DealShowEquipAttr(attr)
end

function EquipLogic:GetCurEquipFinaAttrByLv(TemplateId, EquipLv)
  local config = configManager.GetDataById("config_equip", TemplateId)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  local counter = 0
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, EquipLv)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, EquipLv)
    end
  end
  for k, v in pairs(attr) do
    if v.value == 0 then
      attr[k] = nil
    end
  end
  table.sort(attr, function(data1, data2)
    return data1.sort < data2.sort
  end)
  return self:_DealShowEquipAttr(attr)
end

function EquipLogic:GetNextEquipFinaAttrByLv(TemplateId, EquipLv)
  local config = configManager.GetDataById("config_equip", TemplateId)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  local counter = 0
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, EquipLv, true)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, EquipLv, true)
    end
  end
  for k, v in pairs(attr) do
    if v.value == 0 then
      attr[k] = nil
    end
  end
  return self:_DealShowEquipAttr(attr)
end

function EquipLogic:_DealShowEquipAttr(attr)
  if attr[21] then
    attr[21].value = configManager.GetDataById("config_battle_range", attr[21].value).desc
  end
  if attr[39] then
    attr[39].value = configManager.GetDataById("config_battle_range", attr[39].value).desc
  end
  if attr[58] then
    local str = (attr[59].value - 1) * attr[58].value / 1000
    str = tonumber(string.format("%.1f", str))
    attr[58].value = str
  end
  if attr[60] then
    local str = attr[59].value * attr[60].value / 1000
    str = tonumber(string.format("%.1f", str))
    attr[60].value = str
  end
  local temp = {}
  for k, v in pairs(attr) do
    local tabConfig = configManager.GetDataById("config_attribute", k)
    if tabConfig.equip_if_show == 1 then
      temp[#temp + 1] = v
    end
  end
  table.sort(temp, function(data1, data2)
    return data1.sort < data2.sort
  end)
  return temp
end

function EquipLogic:GetNextEquipFinaAttr(id)
  local attr = Logic.equipLogic:GetNextEquipProperty(id)
  return self:_DealShowEquipAttr(attr)
end

function EquipLogic:Calculated(equipProp, attr, addProperty, EnhanceLv, isNext)
  EnhanceLv = EnhanceLv or 0
  local tabConfig = configManager.GetDataById("config_attribute", tonumber(equipProp[1]))
  local prop = configManager.GetDataById("config_prop", tonumber(equipProp[1]))
  local tmp = {}
  tmp.name = tabConfig.attr_name
  tmp.type = prop.prop_value_type
  tmp.id = tabConfig.id
  tmp.desc = tabConfig.attr_direction
  tmp.icon = tabConfig.attr_icon
  tmp.sort = tabConfig.equip_show_sort
  tmp.attr = tonumber(equipProp[1])
  local total = 0
  local add = 0
  if addProperty[tabConfig.id] then
    total = addProperty[tabConfig.id].value * EnhanceLv
    add = addProperty[tabConfig.id].value
    addProperty[tabConfig.id].calculated = true
  end
  if prop.prop_value_type == 1 then
    if isNext then
      tmp.value = equipProp[2] + total + add
      tmp.addProperty = add
    else
      tmp.value = equipProp[2] + total
    end
  elseif isNext then
    tmp.value = equipProp[2] + total + add
    tmp.addProperty = add
  else
    tmp.value = equipProp[2] + total
  end
  attr[tmp.attr] = tmp
end

function EquipLogic:GetEnhanceProp(enhanceProp)
  local result = {}
  for i = 1, #enhanceProp do
    local tmp = {}
    tmp.value = enhanceProp[i][2]
    tmp.calculated = false
    result[enhanceProp[i][1]] = tmp
  end
  return result
end

function EquipLogic:GetNextEquipProperty(id)
  local equip = Logic.equipLogic:GetEquipById(id)
  local config = configManager.GetDataById("config_equip", equip.TemplateId)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  local counter = 0
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, equip.EnhanceLv, true)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, equip.EnhanceLv, true)
    end
  end
  table.sort(attr, function(data1, data2)
    return data1.sort < data2.sort
  end)
  return attr
end

function EquipLogic:EquipBagOverlay(equipInfo, fleetType)
  fleetType = fleetType or FleetType.Normal
  local tabRes = {}
  local tabHeroEquip = {}
  local tabOtherEquip = {}
  local allEquipTab = {}
  local tabSortTool = {}
  local OverLay = function(equip)
    return not self:IsAEquip(equip.TemplateId)
  end
  for i, v in ipairs(equipInfo) do
    if Data.equipData:GetEquipHero(v.EquipId, fleetType) ~= 0 then
      tabHeroEquip[v.EquipId] = v
    elseif OverLay(v) then
      local state = Logic.equipLogic:GetTowerLockStatus(v.EquipId, fleetType)
      local index = self:_SortTool(tabSortTool, v.TemplateId, v.Star, v.EnhanceLv, state)
      if index then
        table.insert(tabOtherEquip[index].tabEquipId, v.EquipId)
        tabOtherEquip[index].Num = tabOtherEquip[index].Num + 1
      else
        local haveTid = tabSortTool[v.TemplateId]
        if haveTid then
          local haveStar = tabSortTool[v.TemplateId][v.Star]
          if haveStar then
            local haveLv = tabSortTool[v.TemplateId][v.Star][v.EnhanceLv]
            if haveLv then
              local haveState = tabSortTool[v.TemplateId][v.Star][v.EnhanceLv][state]
              if haveState == nil then
                tabSortTool[v.TemplateId][v.Star][v.EnhanceLv][state] = i
              end
            else
              tabSortTool[v.TemplateId][v.Star][v.EnhanceLv] = {
                [state] = i
              }
            end
          else
            tabSortTool[v.TemplateId][v.Star] = {
              [v.EnhanceLv] = {
                [state] = i
              }
            }
          end
        else
          tabSortTool[v.TemplateId] = {
            [v.Star] = {
              [v.EnhanceLv] = {
                [state] = i
              }
            }
          }
        end
        v.tabEquipId = {
          v.EquipId
        }
        v.Num = 1
        tabOtherEquip[i] = v
      end
    else
      v.tabEquipId = {
        v.EquipId
      }
      v.Num = 1
      tabOtherEquip[i] = v
    end
  end
  for k, v in pairs(tabOtherEquip) do
    table.insert(allEquipTab, v)
  end
  return tabHeroEquip, allEquipTab
end

function EquipLogic:_SortTool(tabTool, tid, star, enhanceLv, state)
  if tabTool[tid] and tabTool[tid][star] and tabTool[tid][star][enhanceLv] and tabTool[tid][star][enhanceLv][state] then
    return tabTool[tid][star][enhanceLv][state]
  end
  return nil
end

function EquipLogic:GetEquipConfig(equipBagInfo, equipTypes, heroId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local equipAll = {}
  heroId = heroId or -1
  local equipHero
  for i, v in pairs(equipBagInfo) do
    local equipConfig = configManager.GetDataById("config_equip", v.TemplateId)
    local isConform = Logic.equipLogic:CheckEquipType(equipConfig, equipTypes)
    equipHero = Data.equipData:GetEquipHero(v.EquipId, fleetType)
    if isConform and equipHero ~= heroId then
      local equipAllInfo = {}
      for k, n in pairs(equipConfig) do
        equipAllInfo[k] = n
      end
      for j, x in pairs(v) do
        equipAllInfo[j] = x
      end
      table.insert(equipAll, equipAllInfo)
    end
  end
  return equipAll
end

function EquipLogic:CheckEquipType(equipConfig, equipTypes)
  if equipTypes == nil then
    return true
  end
  for i = 1, #equipConfig.ewt_id do
    for j = 1, #equipTypes do
      if equipConfig.ewt_id[i] == equipTypes[j] then
        return true
      end
    end
  end
  return false
end

function EquipLogic:GetEquipOccupySize()
  local equipData = Data.equipData:GetEquipData()
  local count = 0
  for k, v in pairs(equipData) do
    if v.HeroId == 0 and self:InCapacity(v.TemplateId) then
      count = count + 1
    end
  end
  return count
end

function EquipLogic:GetEquipTypeConfig()
  local screenType = configManager.GetData("config_equip_wear_type")
  local arrType = {}
  for i, v in pairs(screenType) do
    table.insert(arrType, v)
  end
  table.sort(arrType, function(a, b)
    return a.ewt_id < b.ewt_id
  end)
  local title = {
    ewt_id = 0,
    ewt_desc = UIHelper.GetString(190003),
    equip_show_name = UIHelper.GetString(190003)
  }
  local tab = {title}
  for _, v in pairs(arrType) do
    table.insert(tab, v)
  end
  local actEquipTitle = {
    ewt_id = #screenType + 1,
    ewt_desc = UIHelper.GetString(7205000),
    equip_show_name = UIHelper.GetString(7205000)
  }
  table.insert(tab, actEquipTitle)
  return tab
end

function EquipLogic:GetEquipById(equipid)
  local allEquip = Data.equipData:GetEquipData()
  local equip = allEquip[equipid]
  equip = equip or npcAssistFleetMgr:GetNpcEquip(equipid)
  return equip
end

function EquipLogic:GetSpecificEquipNum(templateId, equipId, fleetType)
  if Data.equipData:GetEquipDataById(equipId) == nil then
    return 0
  end
  local equips = Data.equipData:GetEquipsByTid(templateId)
  local Condition = function(equip, equipId, fleetType)
    local heroId = Data.equipData:GetEquipHero(equip.EquipId, fleetType)
    return heroId == 0 and equip.EquipId ~= equipId
  end
  local count = 0
  for _, equip in pairs(equips) do
    if Condition(equip, equipId, fleetType) then
      count = count + 1
    end
  end
  local can, quality = self:CanUseCommonRiseEquip(templateId)
  if can then
    local common = #Data.equipData:GetCommonEquips(quality)
    count = count + common
  end
  return count
end

function EquipLogic:GetEquipCanCostNum(tid)
  local equips = Data.equipData:GetEquipsByTid(tid)
  local count = 0
  for _, equip in pairs(equips) do
    if self:IsDeployHeroByType(equip.EquipId, FleetType.Normal) then
      count = count + 1
    end
  end
  return count
end

function EquipLogic:CanUseCommonRiseEquip(templateId)
  local quality = self:GetEquipConfigById(templateId).quality
  return quality >= HeroRarityType.SR, quality
end

function EquipLogic:GetSpecificEquipInfo(equipId)
  local equipBagInfo = Data.equipData:GetEquipData()
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local tabTemp = {}
  local can, quality = self:CanUseCommonRiseEquip(equip.TemplateId)
  local heroId
  for _, v in pairs(equipBagInfo) do
    heroId = Data.equipData:GetEquipHero(v.EquipId)
    if can then
      if v.TemplateId == equip.TemplateId and heroId == 0 and equipId ~= v.EquipId or self:IsCommonRiseEquipByQuality(v.TemplateId, quality) then
        table.insert(tabTemp, v)
      end
    elseif v.TemplateId == equip.TemplateId and heroId == 0 and equipId ~= v.EquipId then
      table.insert(tabTemp, v)
    end
  end
  return tabTemp
end

function EquipLogic:IsCommonRiseEquipByQuality(templateId, quality)
  local config = self:GetEquipConfigById(templateId)
  return config.equip_type_id == CommonRiseEquipTag and quality == config.quality
end

function EquipLogic:IsCommonRiseEquip(templateId)
  local config = self:GetEquipConfigById(templateId)
  return config.equip_type_id == CommonRiseEquipTag
end

function EquipLogic:IsEquipIntensify(equipid)
  local equip = Logic.equipLogic:GetEquipById(equipid)
  if 0 ~= equip.Star or 0 ~= equip.EnhanceLv then
    return true
  end
  return false
end

function EquipLogic:GetEquipTag(tabTrenchId)
  local equipType = ""
  for i = 1, #tabTrenchId do
    local wearType = configManager.GetDataById("config_equip_wear_type", tabTrenchId[i])
    if wearType ~= nil then
      local symbol = "/"
      if i == #tabTrenchId then
        symbol = ""
      end
      equipType = equipType .. wearType.ewt_desc .. symbol
    end
  end
  return equipType
end

function EquipLogic:GetTrenchEquipType(tabTrenchId)
  local equipType = ""
  for i = 1, #tabTrenchId do
    if tabTrenchId[i] ~= 0 then
      local wearType = configManager.GetDataById("config_equip_wear_type", tabTrenchId[i])
      if equipType == "" then
        equipType = wearType.equip_show_name
      elseif equipType ~= wearType.equip_show_name then
        equipType = UIHelper.GetString(170001)
        return equipType
      end
    else
      noticeManager:ShowMsgBox("\232\163\133\229\164\135\230\167\189\228\189\141\228\191\161\230\129\175\232\142\183\229\143\150\229\164\177\232\180\165,\232\175\183\230\163\128\230\159\165ShipLogic:GetShipEquipInfo")
    end
  end
  return equipType
end

function EquipLogic:GetEquipMaxStar(tid)
  return configManager.GetDataById("config_equip", tid).star_max
end

function EquipLogic:GetEquipMaxLv(TemplateId)
  return configManager.GetDataById("config_equip", TemplateId).enhance_level_max
end

function EquipLogic:GetLockedEquipMaxLv()
  return configManager.GetDataById("config_equip_levelbreak_item", 1).level_rank[2]
end

function EquipLogic:CheckHeroEquip(heroId, fleetType)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  local tmp = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
  for nIndex = 1, #tmp do
    if self:CheckHeroEquipByIndex(heroId, nIndex, fleetType) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckHeroEquipByIndex(heroId, nIndex, fleetType)
  fleetType = fleetType or FleetType.Normal
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  local heroEquip = Data.heroData:GetEquipsByType(heroId, fleetType)
  local tmp = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
  local typeMap = {}
  if heroEquip[nIndex].EquipsId == 0 and tmp[nIndex].open then
    local tabTrenchId = tmp[nIndex].equipAttr
    for i = 1, #tabTrenchId do
      if tabTrenchId[i] ~= 0 then
        local wearType = configManager.GetDataById("config_equip_wear_type", tabTrenchId[i])
        typeMap[wearType.ewt_id] = true
      end
    end
  else
    return false
  end
  local equips = Data.equipData:GetEquipData()
  local TypeMatch = function(types, map)
    for _, type in ipairs(types) do
      if map[type] then
        return true
      end
    end
    return false
  end
  local config, templateId
  for id, equip in pairs(equips) do
    templateId = equip.TemplateId
    equipHero = Data.equipData:GetEquipHero(id, fleetType)
    config = configManager.GetDataById("config_equip", templateId)
    if config and equipHero == 0 and TypeMatch(config.ewt_id, typeMap) and self:CheckHeroMaxWearNum(heroId, templateId) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckEquipQualityEx(heroId, fleetType)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local tmp = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
  if self:CheckEquipQualityByIndexEx(heroId, tmp, fleetType) then
    return true
  end
  return false
end

function EquipLogic:CheckEquipQualityByIndexEx(heroId, shipEquips, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local noEquip = true
  local tEquips = Data.heroData:GetEquipsByType(heroId, fleetType)
  for nIndex = 1, #shipEquips do
    local equipId = tEquips[nIndex].EquipsId
    if equipId ~= 0 then
      noEquip = false
    end
  end
  if noEquip then
    return false
  end
  local type2Quality = {}
  local tqTmp
  local equpData = Data.equipData
  local equips = equpData:GetEquipData()
  local getEquipInfo = equpData.GetEquipHero
  local confMgr = configManager
  local getDataById = configManager.GetDataById
  local tabEquipName = "config_equip"
  local ewt_id, templateId, equipHero, confQuality
  for id, equip in pairs(equips) do
    templateId = equip.TemplateId
    equipHero = getEquipInfo(equpData, id, fleetType)
    config = getDataById(tabEquipName, templateId)
    if config and equipHero == 0 then
      for _, wid in ipairs(config.ewt_id) do
        ewt_id = wid
        confQuality = config.quality
        tqTmp = type2Quality[ewt_id]
        if tqTmp == nil then
          type2Quality[ewt_id] = {confQuality, templateId}
        elseif confQuality > tqTmp[1] then
          tqTmp[1] = confQuality
          tqTmp[2] = templateId
        end
      end
    end
  end
  local tabTrenchId
  local tabWearName = "config_equip_wear_type"
  local wearType, quality, equip
  for nIndex = 1, #shipEquips do
    equip = tEquips[nIndex].EquipsId
    if equip ~= 0 then
      quality = self:GetQualityByEquipId(equip)
      for _, tid in ipairs(shipEquips[nIndex].equipAttr) do
        wearType = getDataById(tabWearName, tid)
        tqTmp = type2Quality[wearType.ewt_id]
        if tqTmp and quality < tqTmp[1] and self:CheckHeroMaxWearNum(heroId, tqTmp[2]) then
          return true
        end
      end
    end
  end
  return false
end

function EquipLogic:CheckEquipQualityByIndex(heroId, nIndex, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local equipId = Data.heroData:GetEquipsByType(heroId, fleetType)[nIndex].EquipsId
  if not equipId or equipId == 0 then
    return false
  end
  local quality = self:GetQualityByEquipId(equipId)
  if quality == HeroRarityType.SSR then
    return false
  end
  local equipObj = Data.equipData
  local equips = equipObj:GetEquipData()
  local typeMap = Logic.shipLogic:GetShipEquipPosTypes(heroInfo.TemplateId, nIndex)
  local TypeMatch = function(types, map)
    if next(map) == nil then
      return true
    end
    for _, type in ipairs(types) do
      if map[type] then
        return true
      end
    end
    return false
  end
  local config, templateId, equipHero
  for id, equip in pairs(equips) do
    templateId = equip.TemplateId
    equipHero = equipObj:GetEquipHero(id, fleetType)
    config = configManager.GetDataById("config_equip", templateId)
    if config and equipHero == 0 and TypeMatch(config.ewt_id, typeMap) and quality < self:GetQuality(templateId) and self:CheckHeroMaxWearNum(heroId, templateId) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckEquipIntensify(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  for k, v in pairs(heroInfo.Equips) do
    local equip = Logic.equipLogic:GetEquipById(v)
    if self:CheckIntensifyByEquip(equip) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckIntensifyByEquip(equip)
  if equip then
    local equipMaxLv = Logic.equipLogic:GetEquipMaxLv(equip.TemplateId)
    local equipMaxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
    local curEquipLv = equip.EnhanceLv
    local renovate
    if equipMaxStar > equip.Star then
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
    else
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
    end
    local itemTbl, canEnhance = Logic.equipIntensifyLogic:GetExpItemTableByEquipId(equip.EquipId)
    if curEquipLv >= renovate.need_enhance_level and equipMaxStar > equip.Star then
      if self:_CheckEquipRise(renovate, equip) then
        return true
      end
    elseif equipMaxLv > curEquipLv and canEnhance then
      return true
    end
  end
  return false
end

function EquipLogic:CheckEquipEnhance(heroId, fleetType)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local tmp = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
  for nIndex = 1, #tmp do
    if self:CheckEquipEnhanceByIndex(heroId, nIndex, fleetType) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckEquipEnhanceByIndex(heroId, index, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local v = Data.heroData:GetEquipsByType(heroId, fleetType)[index].EquipsId
  if v <= 0 then
    return false
  end
  local equip = Logic.equipLogic:GetEquipById(v)
  if equip == nil then
    return false
  end
  return self:CheckIntensifyByEquip(equip)
end

function EquipLogic:CheckEquipRise(heroId, fleetType)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local tmp = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
  for nIndex = 1, #tmp do
    if self:CheckEquipRiseByIndex(heroId, nIndex, fleetType) then
      return true
    end
  end
  return false
end

function EquipLogic:CheckEquipRiseByIndex(heroId, index, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  if Logic.towerLogic:IsTowerType(fleetType) then
    return false
  end
  local v = Data.heroData:GetEquipsByType(heroId, fleetType)[index].EquipsId
  local equip = Logic.equipLogic:GetEquipById(v)
  if equip then
    local equipMaxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
    local curEquipLv = equip.EnhanceLv
    local renovate
    if equipMaxStar > equip.Star then
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
    else
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
    end
    if curEquipLv >= renovate.need_enhance_level and equipMaxStar > equip.Star and self:_CheckEquipRise(renovate, equip) then
      return true
    end
  end
  return false
end

function EquipLogic:_CheckEquipRise(renovate, equip)
  if not renovate then
    local equipMaxStar = self:GetEquipMaxStar(equip.TemplateId)
    if equipMaxStar > equip.Star then
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
    else
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
    end
  end
  local equipMaxLv = Logic.equipLogic:GetEquipMaxLv(equip.TemplateId)
  if equip.EnhanceLv < renovate.need_enhance_level or equip.EnhanceLv == equipMaxLv or equip.Star == renovate.renovate_level then
    return false
  end
  local cons = 0
  for k, value in pairs(renovate.item_array) do
    local num, itemEnough = self:_GetConsumesNum(value[1], value[2], value[3])
    if itemEnough then
      cons = cons + 1
    end
  end
  if cons == #renovate.item_array and renovate.equip_self_count == 0 then
    return true
  end
  local item, equipEnough = self:_GetConsumesNum(BagItemType.EQUIP, equip.TemplateId, renovate.equip_self_count, equip.EquipId)
  if renovate.equip_self_count ~= 0 and equipEnough and cons == #renovate.item_array then
    return true
  end
  return false
end

function EquipLogic:GetRiseStartMaterial(equipId)
  local isMaxStar = Logic.equipLogic:IsMaxStar(equipId)
  local equip = Logic.equipLogic:GetEquipById(equipId)
  local renovateInfo
  if isMaxStar then
    renovateInfo = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
  else
    renovateInfo = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
  end
  local consumes = {}
  for k, v in pairs(renovateInfo.item_array) do
    table.insert(consumes, v)
  end
  return consumes
end

function EquipLogic:_GetConsumesNum(itemType, id, connum, equipId)
  equipId = equipId or 0
  local enough, num = true
  if itemType == BagItemType.CURRENCY then
    num = Data.userData:GetCurrency(id)
  elseif itemType == BagItemType.ITEM then
    num = Logic.bagLogic:GetBagItemNum(id)
  elseif itemType == BagItemType.EQUIP then
    num = Logic.equipLogic:GetSpecificEquipNum(id, equipId)
  else
    num = 0
  end
  if connum > num then
    enough = false
  end
  return num, enough
end

function EquipLogic:CanAddAEquipByIndex(heroId, index, fleetType)
  if not self:InActivity() then
    return false
  end
  fleetType = fleetType or FleetType.Normal
  local heroEquips = Data.heroData:GetEquipsByType(heroId, fleetType)
  if heroEquips[index].EquipsId == 0 or heroEquips.state == MEquipState.LOCK then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  local equips = Data.equipData:GetEquipData()
  local TypeMatch = function(types, map)
    for _, type in ipairs(types) do
      if map[type] then
        return true
      end
    end
    return false
  end
  local typeMap = Logic.shipLogic:GetShipEquipPosTypes(heroInfo.TemplateId, index)
  local config, templateId
  for id, equip in pairs(equips) do
    templateId = equip.TemplateId
    equipHero = Data.equipData:GetEquipHero(id, fleetType)
    config = configManager.GetDataById("config_equip", templateId)
    if config and equipHero == 0 and self:IsAEquip(templateId) and TypeMatch(config.ewt_id, typeMap) and self:CheckHeroMaxWearNum(heroId, templateId) then
      return true
    end
  end
  return false
end

function EquipLogic:IsNewEquip(equipId)
  local equipInfoArr = Data.equipData:GetRecordNewEquip()
  if next(equipInfoArr) == nil then
    return false
  end
  for k, v in ipairs(equipInfoArr) do
    if v.EquipId == equipId then
      return true
    end
  end
  return false
end

function EquipLogic:RmEquipByHeroId()
  local equipInfoArr = Data.equipData:GetRecordNewEquip()
  local newHeroId = Data.heroData:GetRecordNewHero()
  for i = 1, #newHeroId do
    local heroInfo = Data.heroData:GetHeroById(newHeroId[i])
    if heroInfo then
      for j = 1, #heroInfo.Equips do
        for k, v in ipairs(equipInfoArr) do
          if v.EquipId == heroInfo.Equips[j] then
            equipInfoArr[k] = nil
          end
        end
      end
    end
  end
end

function EquipLogic:ShowEquipDetails(equipId)
  local equipInfoArr = Data.equipData:GetRecordNewEquip()
  if next(equipInfoArr) == nil then
    return false
  end
  for k, v in ipairs(equipInfoArr) do
    if v.EquipId == equipId then
      table.remove(equipInfoArr, k)
      return true
    end
  end
  return false
end

function EquipLogic:IsInDismantle(equipId)
  local equips = Logic.dismantleLogic:GetDismantleEquip()
  return equips[equipId]
end

function EquipLogic:InDismantleNum(tabEquipId)
  local count = 0
  for k, v in ipairs(tabEquipId) do
    if Logic.equipLogic:IsInDismantle(v) then
      count = count + 1
    end
  end
  return count
end

function EquipLogic:IsHighQuality(templateId)
  return self:GetQuality(templateId) >= HeroRarityType.SR
end

function EquipLogic:GetMaxUninstallNum()
  return 40
end

function EquipLogic:HaveDismantleEquip()
  return Logic.dismantleLogic:GetDismantleNum() ~= 0
end

function EquipLogic:GetEquipTidByEquipId(equipId)
  if self:GetEquipById(equipId) then
    return self:GetEquipById(equipId).TemplateId
  else
    logError("FATAL ERROR:EQUIP can not find equip info about:" .. equipId)
    return 0
  end
end

function EquipLogic:HaveHighQualityEquip(tabEquipId)
  local count = 0
  for k, v in ipairs(tabEquipId) do
    local tid = self:GetEquipTidByEquipId(v)
    if 0 < tid and self:IsHighQuality(tid) then
      return true
    end
  end
  return false
end

function EquipLogic:HaveIntensifyEquip(tabEquipId)
  local count = 0
  for k, v in pairs(tabEquipId) do
    if self:IsEquipIntensify(v) then
      return true
    end
  end
  return false
end

function EquipLogic:HaveEquip(templateId)
  local equipData = Data.equipData:GetEquipData()
  for k, v in pairs(equipData) do
    if v.TemplateId == templateId then
      return true
    end
  end
  return false
end

function EquipLogic:GetDismantleReward(tabEquipId)
  local tabRes = {}
  for k, v in pairs(tabEquipId) do
    local tabTemp = self:GetDismantleRewardByEquip(v)
    for key, value in ipairs(tabTemp) do
      table.insert(tabRes, value)
    end
  end
  if #tabRes ~= 0 then
    tabRes = self:MergeSameRes(tabRes)
  end
  local factor = self:GetDismantleGetRadio()
  for i, v in ipairs(tabRes) do
    v[3] = math.ceil(v[3] * factor)
  end
  return tabRes
end

function EquipLogic:FormatDismantReward(rewards)
  local res = {}
  for _, v in ipairs(rewards) do
    table.insert(res, {
      Type = v[1],
      ConfigId = v[2],
      Num = v[3]
    })
  end
  return res
end

function EquipLogic:SetDisRewardCache(selects)
  local rewards = self:GetDismantleReward(selects)
  rewards = self:FormatDismantReward(rewards)
  self.cacheDisReward = rewards
end

function EquipLogic:GetDisRewardCache()
  return self.cacheDisReward
end

function EquipLogic:ResetDisRewardCache()
  self.cacheDisReward = {}
end

function EquipLogic:MergeSameRes(tabRes)
  if #tabRes == 0 then
    return {}
  end
  local tabMiddle = {}
  for _, v in ipairs(tabRes) do
    local temp = {
      v[1],
      v[2],
      v[3]
    }
    table.insert(tabMiddle, temp)
  end
  tabRes = tabMiddle
  table.sort(tabRes, function(data1, data2)
    if data1[1] ~= data2[1] then
      return data1[1] < data2[1]
    elseif data1[2] ~= data2[2] then
      return data1[2] < data2[2]
    else
      return data1[3] < data2[3]
    end
  end)
  local tabTemp = {}
  local pole = tabRes[1]
  local sum = pole[3]
  table.insert(tabTemp, pole)
  for i = 2, #tabRes do
    if self:IsSame(pole, tabRes[i]) then
      sum = sum + tabRes[i][3]
      tabTemp[#tabTemp][3] = sum
    else
      pole = tabRes[i]
      sum = pole[3]
      table.insert(tabTemp, pole)
    end
  end
  return tabTemp
end

function EquipLogic:IsSame(item1, item2)
  return item1[1] == item2[1] and item1[2] == item2[2]
end

function EquipLogic:GetDismantleGetRadio()
  local value = configManager.GetDataById("config_parameter", 61).value
  return value / 10000
end

function EquipLogic:GetDismantleRewardByEquip(equipId)
  local tid = self:GetEquipTidByEquipId(equipId)
  if tid <= 0 then
    return {}
  end
  local tabRes = {}
  local temp = self:GetBaseDismantleReward(tid)
  table.insert(tabRes, temp)
  local enhance = self:GetEnhanceNeedRes(equipId)
  for k, v in pairs(enhance) do
    table.insert(tabRes, v)
  end
  local rise = self:GetRiseNeedRes(equipId)
  for k, v in pairs(rise) do
    table.insert(tabRes, v)
  end
  return tabRes
end

function EquipLogic:GetBaseDismantleReward(tid)
  return configManager.GetDataById("config_equip", tid).dismantling_get
end

function EquipLogic:GetEnhanceNeedRes(equipId)
  local enhanceExp = self:GetEquipById(equipId).EnhanceExp
  local lv, temp
  local res = {}
  while 0 < enhanceExp do
    lv = self:GetLvByExp(enhanceExp)
    temp = Logic.equipIntensifyLogic:GetExpItemTable(lv)
    if #temp == 0 then
      logError("can not find dismantle equip intensity item:EquipId:" .. equipId .. " lv:" .. lv)
      break
    end
    temp = temp[#temp]
    self:_tryMergeArray(res, temp)
    enhanceExp = enhanceExp - temp.exp
  end
  return res
end

function EquipLogic:_tryMergeArray(tab, item)
  if #tab == 0 then
    table.insert(tab, {
      GoodsType.EQUIP_ENHANCE_ITEM,
      item.id,
      1
    })
    return tab
  end
  for i = 1, #tab do
    if tab[i][2] == item.id then
      tab[i][3] = tab[i][3] + 1
      return tab
    end
  end
  table.insert(tab, {
    GoodsType.EQUIP_ENHANCE_ITEM,
    item.id,
    1
  })
  return tab
end

function EquipLogic:GetRiseNeedRes(equipId)
  local star = self:GetEquipById(equipId).Star
  local tabRes = {}
  for i = 1, star do
    local tabNeedItem = configManager.GetDataById("config_equip_enhance_renovate", i)
    local item = tabNeedItem.item_array
    for k, v in pairs(item) do
      table.insert(tabRes, v)
    end
  end
  local commonRes = Data.equipData:GetRiseCommonEquip(equipId)
  for id, num in pairs(commonRes) do
    table.insert(tabRes, {
      GoodsType.EQUIP,
      id,
      num
    })
  end
  return tabRes
end

function EquipLogic:IsDefaultSelect(equipId)
  local train = self:IsEquipIntensify(equipId)
  local quality = self:GetQuality(Logic.equipLogic:GetEquipById(equipId).TemplateId)
  local candel = self:CanDelectById(equipId)
  return quality < HeroRarityType.SR and not train and candel
end

function EquipLogic:IsEquipBagFullAfterAdd(addNum)
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  return equipSize < size + addNum
end

function EquipLogic:IsEquipBagFull()
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  return size >= equipSize
end

function EquipLogic:GetLvByExp(exp)
  if exp <= 0 then
    return 0
  end
  lv = 0
  while 0 < exp do
    exp = exp - self:GetLvExp(lv + 1)
    lv = lv + 1
  end
  return lv - 1
end

function EquipLogic:GetLvExp(lv)
  if lv <= 0 then
    return 0
  end
  local lvlConfig = configManager.GetDataById("config_equip_enhance_level_exp", lv)
  return lvlConfig.exp
end

function EquipLogic:GetMaxExp(lv)
  if lv <= 0 then
    return 0
  end
  local curLvExp = 0
  for i = 1, lv do
    local exp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
    curLvExp = curLvExp + exp
  end
  return curLvExp
end

function EquipLogic:IsShowStrAttr(attr)
  return attr == 21 or attr == 39
end

function EquipLogic:IsShowFloatAttr(attr)
  return attr == 58 or attr == 60
end

function EquipLogic:IsShowIntAttr(attr)
  return attr ~= 21 and attr ~= 39 and attr ~= 58 and attr ~= 60
end

function EquipLogic:IsMaxStar(equipId)
  local equip = Data.equipData:GetEquipDataById(equipId)
  local maxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
  return maxStar <= equip.Star
end

function EquipLogic:CanRiseStar(equipId)
  if Logic.equipLogic:IsMaxStar(equipId) then
    return false
  end
  local equip = Data.equipData:GetEquipDataById(equipId)
  local riseConfig = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
  return equip.EnhanceLv >= riseConfig.need_enhance_level
end

function EquipLogic:IsRiseNeedSelf(equipId)
  local riseConfig
  local equip = Data.equipData:GetEquipDataById(equipId)
  if Logic.equipLogic:IsMaxStar(equipId) then
    riseConfig = configManager.GetDataById("config_equip_enhance_renovate", equip.Star)
  else
    riseConfig = configManager.GetDataById("config_equip_enhance_renovate", equip.Star + 1)
  end
  return riseConfig.equip_self_count > 0
end

function EquipLogic:_isPlane(tid)
  local typ = configManager.GetDataById("config_equip", tid).equip_type_id
  return configManager.GetDataById("config_equip_type", typ).calculate_type == EquipBaseType.PLANE
end

function EquipLogic:_getPlaneAttr(heroId, id, fleetType)
  fleetType = fleetType or FleetType.Normal
  local equip = Data.equipData:GetEquipDataById(id)
  local extraMap = {
    [EquipType.FIGHTPLANE] = AttrType.FIGHTPLANE,
    [EquipType.TORPEDOPLANE] = AttrType.TORPEDOPLANE,
    [EquipType.BOMBPLANE] = AttrType.BOMBPLANE
  }
  local hero = Data.heroData:GetHeroById(heroId)
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  local equipType = self:GetEquipConfigById(equip.TemplateId).ewt_id
  local baseConfig = configManager.GetDataById("config_ship_equip", hero.TemplateId).plane_number
  local breakConfig = configManager.GetDataById("config_ship_break", hero.TemplateId)
  local res = 0
  if equips ~= nil then
    for k, v in ipairs(equips) do
      if id ~= 0 and id == v.EquipsId then
        res = baseConfig[k]
        break
      end
    end
  end
  local ret = {}
  for i, v in ipairs(breakConfig.value_effect_id_list) do
    local valueEffect = configManager.GetDataById("config_value_effect", v)
    table.insert(ret, {
      power = breakConfig.value_effect_power_list[i],
      values = valueEffect.values
    })
  end
  local attr = {}
  Logic.attrLogic:DisposeAttrBuff(attr, ret)
  local planeAttr = {}
  for i, v in ipairs(equipType) do
    local attrid = extraMap[v]
    if attrid then
      local extra = attr[attrid] or 0
      planeAttr[attrid] = extra + res
    end
  end
  return planeAttr
end

function EquipLogic:_getPlaneNum(heroId, id, fleetType)
  fleetType = fleetType or FleetType.Normal
  local attr = self:_getPlaneAttr(heroId, id, fleetType)
  local fightNum = attr[AttrType.FIGHTPLANE] or 0
  local torpedorNum = attr[AttrType.TORPEDOPLANE] or 0
  local bombNum = attr[AttrType.BOMBPLANE] or 0
  return fightNum + torpedorNum + bombNum
end

function EquipLogic:GetShipPlaneAttr(heroId, fleetType)
  local attr = {}
  attr[AttrType.FIGHTPLANE] = 0
  attr[AttrType.TORPEDOPLANE] = 0
  attr[AttrType.BOMBPLANE] = 0
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  local id
  for _, equip in ipairs(equips) do
    id = equip.EquipsId
    if 0 < id then
      local data = self:GetEquipById(id)
      if data == nil then
        return attr
      end
      local tid = data.TemplateId
      if self:_isPlane(tid) then
        local planeAttr = self:_getPlaneAttr(heroId, id, fleetType)
        local fightNum = planeAttr[AttrType.FIGHTPLANE] or 0
        local torpedorNum = planeAttr[AttrType.TORPEDOPLANE] or 0
        local bombNum = planeAttr[AttrType.BOMBPLANE] or 0
        attr[AttrType.FIGHTPLANE] = attr[AttrType.FIGHTPLANE] + fightNum
        attr[AttrType.TORPEDOPLANE] = attr[AttrType.TORPEDOPLANE] + torpedorNum
        attr[AttrType.BOMBPLANE] = attr[AttrType.BOMBPLANE] + bombNum
      end
    end
  end
  return attr
end

function EquipLogic:GetEquipType(templateId)
  return self:GetEquipConfigById(templateId).equip_type_id
end

function EquipLogic:GetEquipAttrNum(euqipId, attrId)
  local attr = Logic.equipLogic:GetCurEquipProperty(euqipId)
  if attr[attrId] then
    return attr[attrId].value
  end
  return 0
end

function EquipLogic:CheckEquipIntensifyAndSend(equipId, itemId, num)
  if num <= 0 then
    return
  end
  local equip = Data.equipData:GetEquipDataById(equipId)
  if equip == nil then
    return
  end
  local maxLv = self:GetEquipMaxLv(equip.TemplateId)
  if maxLv <= equip.EnhanceLv then
    return
  end
  local maxStar = self:GetEquipMaxStar(equip.TemplateId)
  local targetLv = self:_getIntensifyTargetLv(equip.TemplateId, equip.Star, maxStar)
  if targetLv <= equip.EnhanceLv and maxStar > equip.Star then
    return
  end
  local item = Logic.bagLogic:ItemInfoById(itemId)
  if item == nil then
    return
  end
  if num > item.num then
    num = item.num
  end
  local over, num = self:CheckIntensifyExpOverflow(equipId, targetLv, itemId, num)
  if over then
  end
  Service.equipService:SendEnhance(equipId, itemId, num)
end

function EquipLogic:CheckIntensifyExpOverflow(equipId, targetLv, item, num)
  local equip = Data.equipData:GetEquipDataById(equipId)
  local lvExp = self:GetEquipUpNeedExp(targetLv)
  local needExp = lvExp - equip.EnhanceExp
  local over = needExp < self:_getProvideExp(item, num)
  if over then
    for i = num, 1, -1 do
      if needExp <= self:_getProvideExp(item, i) and needExp > self:_getProvideExp(item, i - 1) then
        num = i
        break
      end
    end
  end
  return over, num
end

function EquipLogic:_getProvideExp(item, num)
  return num * self:GetEquipEnhanveItemConfigById(item).exp
end

function EquipLogic:_getIntensifyTargetLv(templateId, star, maxStar)
  if maxStar <= star then
    return self:GetEquipConfigById(templateId).enhance_level_max
  else
    return self:GetEquipRiseConfigByStar(star + 1).need_enhance_level
  end
end

function EquipLogic:GetEquipRiseConfigByStar(star)
  return configManager.GetDataById("config_equip_enhance_renovate", star)
end

function EquipLogic:GetEquipEnhanveItemConfigById(itemId)
  return configManager.GetDataById("config_equip_enhance_item", itemId)
end

function EquipLogic:GetEquipUpExpConfigByLv(lv)
  return configManager.GetDataById("config_equip_enhance_level_exp", lv).exp
end

function EquipLogic:GetEquipUpNeedExp(lv)
  local res = 0
  for i = 1, lv do
    res = res + self:GetEquipUpExpConfigByLv(lv)
  end
  return res
end

function EquipLogic:CheckChangeEquipRPC(heroId, old, new, type)
  local ok, hero = Data.heroData:VerifyHero(heroId)
  local newEquip
  if not ok then
    return false, ""
  end
  ok, newEquip = Data.equipData:VerifyEquip(new)
  if ok and not self:CheckLvlLimit(newEquip.TemplateId, hero.Lvl) then
    return false, UIHelper.GetString(170017)
  end
  return true, ""
end

function EquipLogic:PoolHave(name)
  return self.cacheObj[name] ~= nil
end

function EquipLogic:PoolAdd(obj, id)
  if self.cacheObj[id] == nil then
    self.cacheObj[id] = obj
  end
end

function EquipLogic:PoolGet(id)
  return self.cacheObj[id] ~= nil, self.cacheObj[id]
end

function EquipLogic:PoolRelease()
  self.cacheObj = {}
end

function EquipLogic:GetCopyRecordEquip(heroInfo)
  local equipTab = heroInfo.Equip
  local shipEquip = configManager.GetDataById("config_ship_equip", heroInfo.Tid)
  local result = {}
  for i = 1, #shipEquip.equip_attr_condition do
    local tmp = {}
    tmp.equipAttr = shipEquip["equip_attr_num_" .. i]
    tmp.equipInfo = equipTab[i]
    local condition = shipEquip.equip_attr_condition[i]
    if GetTableLength(condition) ~= 0 then
      for _, v in ipairs(condition) do
        local res, _ = Logic.gameLimitLogic.CheckConditionById(v, {
          Advance = heroInfo.AdvLevel
        })
        if not res then
          local limitConfig = Logic.gameLimitLogic.GetLimitConfig(v)
          shipEquip = configManager.GetDataById("config_ship_equip", heroInfo.Tid + limitConfig.limit_param[1] - heroInfo.AdvLevel)
          tmp.equipAttr = shipEquip["equip_attr_num_" .. i]
        end
      end
    end
    table.insert(result, tmp)
  end
  return result
end

function EquipLogic:GetCopyRecordEquipAttr(equip)
  local config = configManager.GetDataById("config_equip", equip.Tid)
  local addProperty = Logic.equipLogic:GetEnhanceProp(config.enhance_prop)
  local attr = {}
  for i = 1, #config.equip_prop do
    Logic.equipLogic:Calculated(config.equip_prop[i], attr, addProperty, equip.Level)
  end
  for k, v in pairs(addProperty) do
    if v.calculated == false then
      Logic.equipLogic:Calculated({k, 0}, attr, addProperty, equip.Level)
    end
  end
  for k, v in pairs(attr) do
    if v.value == 0 then
      attr[k] = nil
    end
  end
  return self:_DealShowEquipAttr(attr)
end

function EquipLogic:AutoAddHerosEquip(heroIds, type, isAdd)
  type = type or FleetType.Normal
  if isAdd then
    local res = self:GetAutoAddRmdEx(heroIds, type)
    if table.empty(res) then
      return false, UIHelper.GetString(920000056)
    end
    local units = {}
    for heroId, rmd in pairs(res) do
      local autoUnit
      if not table.empty(rmd) then
        autoUnit = self:_GenAutoUnit(heroId, rmd)
        table.insert(units, autoUnit)
      else
        logError("rmd equip is empty, heroId :" .. heroId)
      end
    end
    Service.heroService:SendAutoEquip(units, type)
    return true, ""
  elseif table.empty(heroIds) then
    return false, UIHelper.GetString(1704011)
  else
    Service.heroService:SendAutoUnEquip(heroIds, type)
    return true, ""
  end
end

function EquipLogic:UnEquipHeroFiler(heroId, fleetType)
  local equipTemp = {}
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  for index, id in ipairs(equips) do
    if id.EquipsId > 0 and id.state == MEquipState.OPEN then
      return true
    end
  end
  return false
end

function EquipLogic:AutoSetEquips(heroId, isAdd, type)
  type = type or FleetType.Normal
  if isAdd then
    local res = self:GetAutoAddRmdEx({heroId}, type)
    if res[heroId] == nil then
      return false, UIHelper.GetString(920000056)
    else
      local rmd = res[heroId]
      local autoUnit = self:_GenAutoUnit(heroId, rmd)
      Service.heroService:SendAutoEquip({autoUnit}, type)
      return not table.empty(rmd), ""
    end
  else
    local temp = {}
    local equips = Data.heroData:GetEquipsByType(heroId, type)
    for index, id in ipairs(equips) do
      if id.EquipsId > 0 and id.state == MEquipState.OPEN then
        temp[index] = id
      end
    end
    Service.heroService:SendAutoUnEquip({heroId}, type)
    return not table.empty(temp), UIHelper.GetString(920000057)
  end
end

function EquipLogic:_GenAutoUnit(heroId, rmd)
  local equips = {}
  for index, id in pairs(rmd) do
    table.insert(equips, {Index = index, EquipId = id})
  end
  return {HeroId = heroId, ArrEquip = equips}
end

function EquipLogic:GetAutoAddRmdEx(heroIds, fleetType)
  local heroInfo, equips, equipInfo, emptySlots, haveSlots
  local hDataObj = Data.heroData
  local eDataObj = Data.equipData
  local orginEquip, equipTypes, selects, resMap, select = {}, {}, {}, {}
  local gent2es = function(sets1, sets2, equip)
    if equip == nil then
      return
    end
    local tid = equip.TemplateId
    local id = equip.EquipId
    local types = configManager.GetDataById("config_equip", tid).ewt_id
    for _, type in ipairs(types) do
      if sets1[type] == nil then
        sets1[type] = {}
      end
      sets1[type][id] = equip
    end
    sets2[id] = true
  end
  local res, t2es, ues = {}, {}, {}
  for _, heroId in ipairs(heroIds) do
    heroInfo = hDataObj:GetHeroById(heroId)
    equips = hDataObj:GetEquipsByType(heroId, fleetType)
    equipInfo = Logic.shipLogic:GetShipEquipInfo(heroInfo.TemplateId, heroInfo)
    emptySlots, haveSlots = {}, {}
    local acount = 0
    for index, id in ipairs(equips) do
      if equipInfo[index] and equipInfo[index].open then
        if id.EquipsId == 0 then
          emptySlots[index] = id.EquipsId
        elseif id.state ~= MEquipState.LOCK then
          haveSlots[index] = id.EquipsId
        end
      end
    end
    local counter = function(sets, tid)
      local var = sets[tid]
      if var then
        sets[tid] = var + 1
      else
        sets[tid] = 1
      end
    end
    local acounter = function(count, tid)
      if self:IsAEquip(tid) then
        count = count + 1
      end
    end
    local rmd, resTMap = {}, {}
    for index, id in pairs(haveSlots) do
      local curEquip = eDataObj:GetEquipDataById(id)
      equipTypes = equipInfo[index].equipAttr
      orginEquip = self:_getEquipsByTypesEx(equipTypes, t2es)
      selects = self:_matchEquipsEx(orginEquip, heroId, resTMap, fleetType, resMap, id, ues)
      if 0 < #selects then
        self:_autoChangeSort(selects, heroInfo.TemplateId)
        if self:_checkRmdChange(selects[1], id, heroInfo.TemplateId) then
          select = selects[1]
          rmd[index] = select.EquipId
          gent2es(t2es, ues, curEquip)
          resMap[select.EquipId] = true
          counter(resTMap, select.TemplateId)
          acounter(acount, select.TemplateId)
        end
      end
    end
    for index, _ in pairs(emptySlots) do
      equipTypes = equipInfo[index].equipAttr
      orginEquip = self:_getEquipsByTypesEx(equipTypes, t2es)
      selects = self:_matchEquipsEx(orginEquip, heroId, resTMap, fleetType, resMap, 0, ues)
      if 0 < #selects then
        self:_autoAddSort(selects, heroInfo.TemplateId)
        select = selects[1]
        rmd[index] = select.EquipId
        resMap[select.EquipId] = true
        counter(resTMap, select.TemplateId)
        acounter(acount, select.TemplateId)
      end
    end
    if next(rmd) ~= nil then
      res[heroId] = rmd
    end
  end
  return res
end

function EquipLogic:_matchEquipsEx(equips, heroId, rmdTMap, fleetType, rmdMap, curEquip)
  fleetType = fleetType or FleetType.Normal
  local match, tid = false, 0
  local res = {}
  local ok, hero = Data.heroData:VerifyHero(heroId)
  if not ok then
    return res
  end
  for id, equip in pairs(equips) do
    tid = equip.TemplateId
    match = rmdMap[id] == nil and not self:IsDeployHeroByType(id, fleetType) and self:_checkHeroMaxWearNum(rmdTMap, heroId, tid, fleetType) and self:_autoFilter(tid) and self:CheckLvlLimit(tid, hero.Lvl) or id == curEquip
    if match then
      table.insert(res, equip)
    end
  end
  return res
end

function EquipLogic:_autoFilter(tid)
  return not self:IsLLEquip(tid)
end

function EquipLogic:_checkHeroMaxWearNum(cacheRmd, heroId, templateId, type)
  local ok, max = self:GetHeroMaxWearNumById(templateId)
  if not ok then
    return true, ""
  end
  if heroId == nil or heroId <= 0 then
    return true, ""
  end
  local count = cacheRmd[templateId] or 0
  local temp
  local equips = Data.heroData:GetEquipsByType(heroId, type)
  for index, id in ipairs(equips) do
    if 0 < id.EquipsId then
      temp = Data.equipData:GetEquipDataById(id.EquipsId).TemplateId
      if temp == templateId then
        count = count + 1
      end
    end
  end
  return max > count, UIHelper.GetString(1300002)
end

function EquipLogic:_getEquipsByTypesEx(types, t2es)
  local dataObj = Data.equipData
  if #types == 1 and table.empty(t2es) then
    return dataObj:GetEquipsByType(types[1])
  end
  local getRes = function(args, res)
    for id, equip in pairs(args) do
      if res[id] == nil then
        res[id] = equip
      end
    end
  end
  local res, temp, t2estemp = {}
  for _, type in ipairs(types) do
    temp = dataObj:GetEquipsByType(type)
    getRes(temp, res)
    t2estemp = t2es[type]
    if t2estemp then
      getRes(t2estemp, res)
    end
  end
  return res
end

function EquipLogic:_autoAddSort(equips, sm_id)
  local quality1, quality2, rmd1, rmd2
  table.sort(equips, function(data1, data2)
    rmd1 = self:_isMatchHeroRmd(data1.TemplateId, sm_id)
    rmd2 = self:_isMatchHeroRmd(data2.TemplateId, sm_id)
    quality1 = self:GetQuality(data1.TemplateId)
    quality2 = self:GetQuality(data2.TemplateId)
    if rmd1 ~= rmd2 then
      return rmd1 > rmd2
    elseif quality1 ~= quality2 then
      return quality1 > quality2
    elseif data1.Star ~= data2.Star then
      return data1.Star > data2.Star
    elseif data1.EnhanceLv ~= data2.EnhanceLv then
      return data1.EnhanceLv > data2.EnhanceLv
    else
      return data1.TemplateId > data2.TemplateId
    end
  end)
end

function EquipLogic:_autoChangeSort(equips, sm_id)
  local quality1, quality2, rmd1, rmd2
  table.sort(equips, function(data1, data2)
    rmd1 = self:_isMatchHeroRmd(data1.TemplateId, sm_id)
    rmd2 = self:_isMatchHeroRmd(data2.TemplateId, sm_id)
    quality1 = self:GetQuality(data1.TemplateId)
    quality2 = self:GetQuality(data2.TemplateId)
    if rmd1 ~= rmd2 then
      return rmd1 > rmd2
    elseif quality1 ~= quality2 then
      return quality1 > quality2
    elseif data1.Star ~= data2.Star then
      return data1.Star > data2.Star
    else
      return data1.EnhanceLv > data2.EnhanceLv
    end
  end)
end

function EquipLogic:_isMatchHeroRmd(equipTid, heroTid)
  if self:IsAEquip(equipTid) then
    if self:InActivity() then
      return 2
    else
      return -1
    end
  end
  local rmdTypes = Logic.shipLogic:GetRmdEquipType(heroTid)
  if #rmdTypes <= 0 then
    return 0
  end
  local equipType = Logic.equipLogic:GetEquipType(equipTid)
  return table.containV(rmdTypes, equipType) and 1 or 0
end

function EquipLogic:_checkRmdChange(equip, equipId, sm_id)
  local data = Data.equipData:GetEquipDataById(equipId)
  local rmd1 = self:_isMatchHeroRmd(equip.TemplateId, sm_id)
  local rmd2 = self:_isMatchHeroRmd(data.TemplateId, sm_id)
  if rmd1 > rmd2 then
    return true
  end
  local quality1 = self:GetQuality(equip.TemplateId)
  local quality2 = self:GetQuality(data.TemplateId)
  if quality1 > quality2 then
    return true
  end
  if quality1 == quality2 and equip.Star > data.Star then
    return true
  end
  if quality1 == quality2 and equip.Star == data.Star and equip.EnhanceLv > data.EnhanceLv then
    return true
  end
  return false
end

function EquipLogic:_getEquipsByTypes(types)
  local dataObj = Data.equipData
  if #types == 1 then
    return dataObj:GetEquipsByType(types[1])
  end
  local res, temp = {}, {}
  for _, type in ipairs(types) do
    temp = dataObj:GetEquipsByType(type)
    for id, equip in pairs(temp) do
      if res[id] == nil then
        res[id] = equip
      end
    end
  end
  return res
end

function EquipLogic:CheckChangeEquip(heroId, tabTrenchId)
  local equipBagData = Data.equipData:GetEquipData()
  for index, equipData in pairs(equipBagData) do
    local equipType = self:GetEquipType(equipData.TemplateId)
    if heroId ~= equipData.HeroId then
      for i = 1, #tabTrenchId do
        if equipType == tabTrenchId[i] then
          return true
        end
      end
    end
  end
  return false
end

function EquipLogic:GetEquipRisePSkillById(templateId)
  return self:GetEquipConfigById(templateId).renovate_skill
end

function EquipLogic:GetHeroMaxWearNumById(templateId)
  local max = self:GetEquipConfigById(templateId).max_number
  return 0 < max, max
end

function EquipLogic:CheckPSkillOpen(equipId, pskillId)
  if equipId == nil then
    return false, nil
  end
  local equipData = Data.equipData:GetEquipDataById(equipId)
  if equipData.PSkillList == nil then
    return false, nil
  end
  local pskillList = equipData.PSkillList
  for index, info in ipairs(pskillList) do
    if info.PSkillId == pskillId and info.PSkillLv > 0 then
      return true, info
    end
  end
  return false, nil
end

function EquipLogic:CheckPSkillMax(equipId, pskillId)
  return self:IsMaxStar(equipId)
end

function EquipLogic:CheckHeroMaxWearNum(heroId, templateId, type)
  local ok, max = self:GetHeroMaxWearNumById(templateId)
  if not ok then
    return true, ""
  end
  if heroId == nil or heroId <= 0 then
    return true, ""
  end
  local count = 0
  local temp
  local equips = Data.heroData:GetEquipsByType(heroId, type)
  for index, id in ipairs(equips) do
    if 0 < id.EquipsId then
      temp = Data.equipData:GetEquipDataById(id.EquipsId).TemplateId
      if temp == templateId then
        count = count + 1
      end
    end
  end
  return max > count, UIHelper.GetString(1300002)
end

function EquipLogic:GetHeroMaxWearStr(templateId)
  local ok, max = self:GetHeroMaxWearNumById(templateId)
  if not ok then
    return false, ""
  end
  if max == 1 then
    return true, UIHelper.GetString(1300000)
  end
  if 1 < max then
    return true, string.format(UIHelper.GetString(1300001), max)
  end
end

function EquipLogic:GetIndexByEquipId(equipId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local heroId = Data.equipData:GetEquipHero(equipId, fleetType)
  if heroId <= 0 then
    logError("equip no hero, heroId::", equipId)
    return 0
  end
  local equips = Data.heroData:GetEquipsByType(heroId, fleetType)
  for index = EquipIndex.Min, EquipIndex.Max do
    if equips[index].EquipsId == equipId then
      return index
    end
  end
  logError("equip inf error, heroId::", equipId)
  return 0
end

function EquipLogic:GetTrenchByEquipId(equipId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local heroId = Data.equipData:GetEquipHero(equipId, fleetType)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local equipTrench = Logic.shipLogic:GetShipEquipInfo(shipInfo.TemplateId, shipInfo)
  local index = self:GetIndexByEquipId(equipId, fleetType)
  return equipTrench[index].equipAttr
end

function EquipLogic:DotGetEquip(type, id)
  local dotinfo = {info = type, equip_id = id}
  RetentionHelper.Retention(PlatformDotType.equipGetLog, dotinfo)
end

function EquipLogic:IsTowerLock(equipId, fleetType)
  return Data.equipData:GetEquipState(equipId, fleetType) == MEquipState.LOCK and self:_InTowerLock(equipId, fleetType)
end

function EquipLogic:IsBindLock(equipId, fleetType)
  if fleetType == FleetType.Normal then
    return Data.equipData:GetEquipState(equipId, fleetType) == MEquipState.LOCK
  elseif fleetType == FleetType.Tower or fleetType == FleetType.LimitTower then
    local normalEquipState = Data.equipData:GetEquipState(equipId, FleetType.Normal)
    local towerEquipState = Data.equipData:GetEquipState(equipId, fleetType)
    return towerEquipState == MEquipState.LOCK and towerEquipState == normalEquipState
  end
end

function EquipLogic:GetTowerLockStatus(equipId, fleetType)
  local lock = Data.equipData:GetEquipState(equipId, fleetType) == MEquipState.LOCK
  if lock then
    return 1
  end
  lock = self:_InTowerLock(equipId, fleetType)
  if lock then
    return 2
  end
  return 0
end

function EquipLogic:IsDeployHeroByType(equipId, fleetType)
  return Data.equipData:GetEquipHero(equipId, fleetType) ~= 0 or self:_InTowerLock(equipId, fleetType)
end

function EquipLogic:_InTowerLock(equipId, fleetType)
  return (not Data.towerData:IsLockEquip(equipId) or not Logic.towerLogic:IsTowerNormalType(fleetType)) and Data.towerActivityData:IsLockEquip(equipId) and Logic.towerLogic:IsTowerLimitType(fleetType)
end

function EquipLogic:InActivity()
  if self.modi then
    self.m_inActivity = Logic.activityLogic:GetActivityIdByType(ActivityType.AEquip) ~= nil
    self.modi = false
  end
  return self.m_inActivity, 0
end

function EquipLogic:IsAEquip(tid)
  return self:GetEquipConfigById(tid).activity_equip > 0, 0
end

function EquipLogic:CanDevelop(tid)
  return not self:IsAEquip(tid) and #self:GetEquipConfigById(tid).enhance_prop ~= 0
end

function EquipLogic:InCapacity(tid)
  return not self:IsAEquip(tid) and not (self:GetEquipConfigById(tid).no_pack > 0)
end

function EquipLogic:CanDelect(tid)
  return not self:IsAEquip(tid) and not (self:GetEquipConfigById(tid).no_resolve > 0), UIHelper.GetString(7600002)
end

function EquipLogic:CanDelectById(equipId)
  local tid = self:GetEquipTidByEquipId(equipId)
  if 0 < tid then
    return self:CanDelect(tid)
  else
    return false
  end
end

function EquipLogic:GetAEquipPointCur(equipId)
  return Data.equipactivityData:GetPowerPointByEquipId(equipId)
end

function EquipLogic:GetAEquipPointMax(tid)
  return self:GetEquipConfigById(tid).max_energy
end

function EquipLogic:IsAEquipPointGot(equipId)
  return Data.equipactivityData:GetIsRewardByEquipId(equipId) > 0
end

function EquipLogic:CanChange(heroId, index, equipId, fleetType)
  return true, ""
end

function EquipLogic:GetAPointName(tid)
  return self:GetEquipConfigById(tid).energy_name
end

function EquipLogic:GetAAddTip(equipId)
  local rule = Data.equipactivityData:GetAddRule(equipId)
  return 0 < rule and self:GetAAddConfigById(rule).desc or ""
end

function EquipLogic:GetAEquipReward(tid)
  local id = self:GetEquipConfigById(tid).reward
  return Logic.rewardLogic:GetAllShowRewardByDropId(id)
end

function EquipLogic:CheckGetAEquipPointReward(equipId)
  local tid = self:GetEquipTidByEquipId(equipId)
  if tid == 0 then
    return false, "unknown equip"
  end
  if not self:IsAEquip(tid) then
    return false, "not activity equip"
  end
  if self:IsAEquipPointGot(equipId) then
    return false, UIHelper.GetString(7600004)
  end
  local cur = self:GetAEquipPointCur(equipId)
  local max = self:GetAEquipPointMax(tid)
  if cur < max then
    return false, UIHelper.GetString(7600005)
  end
  return true, ""
end

function EquipLogic:IsLLEquip(tid)
  local config = self:GetEquipConfigById(tid)
  local copyIds = config and config.copy_display_id or {}
  return 0 < #copyIds, copyIds
end

function EquipLogic:HaveLLEquip(copyId)
  return self.m_l2e[copyId] and #self.m_l2e[copyId] > 0, self.m_l2e[copyId]
end

function EquipLogic:CheckLLEquipById(copyId, equips)
  local res = {}
  local ok, conf, tid = false, {}, 0
  for _, id in ipairs(equips) do
    tid = Data.equipData:GetEquipDataById(id).TemplateId
    ok, conf = self:IsLLEquip(tid)
    if ok and not table.containV(conf, copyId) then
      table.insert(res, id)
    end
  end
  return 0 < #res, res
end

function EquipLogic:IsLvLEquip(tid)
  local config = self:GetEquipConfigById(tid)
  local minlv = config and config.need_shiplevel or 0
  return 0 < minlv, minlv
end

function EquipLogic:CheckLvlLimit(tid, lv)
  local need, min = self:IsLvLEquip(tid)
  if not need then
    return true
  end
  return lv >= min
end

function EquipLogic:CheckLvlLimitSafe(tid, heroId)
  local hero = Data.heroData:GetHeroById(heroId)
  if not hero then
    logError("find hero data fail heroId:" .. heroId)
    return false, -1
  end
  local min = 0
  ok, min = self:IsLvLEquip(tid)
  if ok then
    return min <= hero.Lvl, min
  else
    return true, 0
  end
end

function EquipLogic:GetAAddConfigById(id)
  return configManager.GetDataById("config_equip_activity_extrapoint", id)
end

function EquipLogic:GetAEquipUseUp()
  return 2
end

function EquipLogic:EquipIsHaveEffect(equipId)
  local equipData = configManager.GetDataById("config_equip", equipId)
  if equipData.skill_fashion_id ~= nil and #equipData.skill_fashion_id ~= 0 then
    return true
  end
  return false
end

function EquipLogic:EquipEffectSort(equipEffectByType, showType, fashionId)
  local equipEffect = configManager.GetDataById("config_equip_fashion_showtype", showType).fashion_id
  local mapFashion = {}
  local mapEquip = {}
  local fashionTabId = configManager.GetDataById("config_fashion", fashionId).skill_fashion_id
  for k, v in pairs(equipEffectByType) do
    mapEquip[v] = true
  end
  if mapEquip[equipEffect] == nil then
    table.insert(equipEffectByType, 1, equipEffect)
  end
  if fashionTabId == nil or #fashionTabId == 0 then
    return equipEffectByType
  else
    local fashionEffect = self:FashionEquipEffectSort(fashionId, showType)
    for k, v in pairs(fashionEffect) do
      mapFashion[v] = v
    end
    for k, v in pairs(equipEffectByType) do
      if mapFashion[v] then
        mapFashion[v] = nil
      end
    end
    for k, v in pairs(mapFashion) do
      table.insert(equipEffectByType, v)
    end
    return equipEffectByType
  end
end

function EquipLogic:FashionEquipEffectSort(fashionId, showType)
  local fashionTabId = configManager.GetDataById("config_fashion", fashionId).skill_fashion_id
  local fashionEffect = {}
  for k, v in pairs(fashionTabId) do
    local skillFashion = configManager.GetDataById("config_skill_fashion", v)
    local effectType = configManager.GetDataById("config_equip_fashion_type", skillFashion.equip_wear_type).equip_type
    if effectType == showType then
      table.insert(fashionEffect, v)
    end
  end
  return fashionEffect
end

function EquipLogic:AllEquipEffectType(heroId)
  local mapHave = {
    [EquipBigType.One] = {},
    [EquipBigType.Two] = {},
    [EquipBigType.Three] = {},
    [EquipBigType.Four] = {},
    [EquipBigType.Five] = {},
    [EquipBigType.Six] = {}
  }
  local equips = Data.heroData:GetEquipsByType(heroId)
  for k, v in pairs(equips) do
    if v.EquipsId ~= 0 then
      local equipInfo = Logic.equipLogic:GetEquipById(v.EquipsId)
      local equipData = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      if equipData.skill_fashion_id ~= nil and #equipData.skill_fashion_id ~= 0 then
        for index, equipWearType in pairs(equipData.ewt_id) do
          local equipFashionType = configManager.GetDataById("config_equip_fashion_type", equipWearType)
          if equipFashionType == nil then
            logError("type is nil")
          end
          local equipType = equipFashionType.equip_type
          for key, value in pairs(equipData.skill_fashion_id) do
            if mapHave[equipType][tonumber(value)] == nil then
              mapHave[equipType][value] = value
            end
          end
        end
      end
    end
  end
  return mapHave
end

function EquipLogic:GetEquipEffectByType(heroId, type)
  local equipEffcetType = {}
  local mapEffects = self:AllEquipEffectType(heroId)
  for k, v in pairs(mapEffects[type]) do
    table.insert(equipEffcetType, v)
  end
  return equipEffcetType
end

function EquipLogic:GetSerMapEffects(heroId)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local mapSerEffects = {
    [EquipBigType.One] = {},
    [EquipBigType.Two] = {},
    [EquipBigType.Three] = {},
    [EquipBigType.Four] = {},
    [EquipBigType.Five] = {},
    [EquipBigType.Six] = {}
  }
  for k, v in pairs(shipInfo.EquipEffects) do
    for key, value in pairs(v.EffectId) do
      mapSerEffects[v.type][value] = true
    end
  end
  return mapSerEffects
end

function EquipLogic:SaveEquipEffect()
  local equipEffectTab = {}
  local index = Logic.fleetLogic:GetBattleFleetId(FleetType.Normal)
  local heroData = Data.fleetData:GetFleetData(FleetType.Normal)
  for _, heroId in pairs(heroData[index].heroInfo) do
    local effectType = {}
    local heroFashionId = Logic.shipLogic:GetShipFashioning(heroId)
    local equips = Data.heroData:GetEquipsByType(heroId)
    local serMapEffects = Logic.equipLogic:GetSerMapEffects(heroId)
    effectType = self:HeroEquipEffect(equips, serMapEffects, effectType)
    effectType = self:FashionEffect(heroFashionId, serMapEffects, effectType)
    if next(effectType) ~= nil then
      equipEffectTab[heroId] = effectType
    end
  end
  return equipEffectTab
end

function EquipLogic:HeroEquipEffect(equips, serMapEffects, effectType)
  for _, v in pairs(equips) do
    if v.EquipsId ~= 0 then
      local equipInfo = Logic.equipLogic:GetEquipById(v.EquipsId)
      local equipData = configManager.GetDataById("config_equip", equipInfo.TemplateId)
      if equipData.skill_fashion_id ~= nil and #equipData.skill_fashion_id ~= 0 then
        for _, skFashionId in pairs(equipData.skill_fashion_id) do
          local skillFashionData = configManager.GetDataById("config_skill_fashion", tonumber(skFashionId))
          if serMapEffects[skillFashionData.equip_fashion_show_type] ~= nil and serMapEffects[skillFashionData.equip_fashion_show_type][tonumber(skFashionId)] then
            if effectType[skillFashionData.equip_wear_type] == nil then
              effectType[skillFashionData.equip_wear_type] = {}
            end
            local isHave = false
            for k, v in pairs(effectType[skillFashionData.equip_wear_type]) do
              if tonumber(v) == tonumber(skFashionId) then
                isHave = true
              end
            end
            if not isHave then
              table.insert(effectType[skillFashionData.equip_wear_type], tonumber(skFashionId))
            end
          end
          effectType = self:OrginEquipEffect(equipData, serMapEffects, effectType, skillFashionData.equip_fashion_show_type)
        end
      end
    end
  end
  return effectType
end

function EquipLogic:FashionEffect(heroFashionId, serMapEffects, effectType)
  local fashionTabId = configManager.GetDataById("config_fashion", heroFashionId).skill_fashion_id
  for _, v in pairs(fashionTabId) do
    local skillFashionData = configManager.GetDataById("config_skill_fashion", tonumber(v))
    if serMapEffects[skillFashionData.equip_fashion_show_type] ~= nil and serMapEffects[skillFashionData.equip_fashion_show_type][tonumber(v)] then
      if effectType[skillFashionData.equip_wear_type] == nil then
        effectType[skillFashionData.equip_wear_type] = {}
      end
      local isHave = false
      for k, value in pairs(effectType[skillFashionData.equip_wear_type]) do
        if tonumber(value) == tonumber(v) then
          isHave = true
        end
      end
      if not isHave then
        table.insert(effectType[skillFashionData.equip_wear_type], tonumber(v))
        serMapEffects[skillFashionData.equip_fashion_show_type][tonumber(v)] = nil
      end
    end
  end
  return effectType
end

function EquipLogic:OrginEquipEffect(equipData, serMapEffects, effectType, equipType)
  for _, value in pairs(equipData.ewt_id) do
    for i, v in pairs(serMapEffects) do
      if next(v) ~= nil then
        local equipEffect = configManager.GetDataById("config_equip_fashion_showtype", i).fashion_id
        if v[equipEffect] then
          local skillFashionData = configManager.GetDataById("config_skill_fashion", tonumber(equipEffect))
          if equipType ~= nil and i == equipType then
            if effectType[value] == nil then
              effectType[value] = {}
            end
            local isSame = false
            for _, effectId in pairs(effectType[value]) do
              if effectId == equipEffect then
                isSame = true
              end
            end
            if not isSame then
              table.insert(effectType[value], tonumber(equipEffect))
            end
            serMapEffects[skillFashionData.equip_fashion_show_type][tonumber(equipEffect)] = nil
          end
        end
      end
    end
  end
  return effectType
end

function EquipLogic:_PlayAdvio(effectId)
  local url = configManager.GetDataById("config_parameter", 329).arrValue
  local urlAll = platformManager:GetEquipEffectUrl(url[1], effectId)
  self:_GetBrowseInfoCallBack(urlAll)
end

function EquipLogic:_GetBrowseInfoCallBack(str)
  local size = configManager.GetDataById("config_parameter", 330).arrValue
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  if isWindows then
    deviceWidth = size[1]
    deviceHeight = size[2]
    posX = -1
    posY = -1
  end
  platformManager:openCustomWebView(str, deviceWidth, deviceHeight, posX, posY, "1", nil, true)
end

function EquipLogic:SetAutoDelete(isOn)
  self.m_autoDelete = isOn
end

function EquipLogic:GetAutoDelete()
  return self.m_autoDelete
end

return EquipLogic
