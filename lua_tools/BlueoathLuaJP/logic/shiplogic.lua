local ShipLogic = class("logic.ShipLogic")
local girllist_max = 20
local HP_COEFFICIENT = 10000000000

function ShipLogic:initialize()
  self:ResetData()
end

function ShipLogic:ResetData()
  self.m_ship2equipType = {}
  self.m_shipBreakMaxLv = {}
  self.m_BreakConversionNumMubo = {}
  self.m_shipCountryItem = {}
  self.m_shipTypeItem = {}
  self.tabSelectBreakItemMubo = {}
  self:_HandleConfig()
end

function ShipLogic:_HandleConfig()
  self:_HandleShipEquipConfig()
  self:HandleShipBreakInfo()
  self:BreakItemsConversionMubo()
  self:SetCountryItems()
  self:SetTypeItems()
end

function ShipLogic:_HandleShipEquipConfig()
  local shipEquip = configManager.GetData("config_ship_equip")
  local ship2equip = {}
  local len, types
  for sm_id, config in pairs(shipEquip) do
    len = #config.equip_attr_condition
    local indexmap = {}
    for i = 1, len do
      types = config["equip_attr_num_" .. i]
      if types == nil then
        logError("handle ship equip config error ,please check ship_equip config,make sure equip_attr_condition and equip_attr_num_* match")
        break
      end
      local typemap = {}
      for _, type in ipairs(types) do
        if type ~= 0 then
          local wear = configManager.GetDataById("config_equip_wear_type", type).ewt_id
          typemap[wear] = true
        end
      end
      indexmap[i] = typemap
    end
    ship2equip[sm_id] = indexmap
  end
  self.m_ship2equipType = ship2equip
end

function ShipLogic:HandleShipBreakInfo()
  local shipMain = configManager.GetData("config_ship_main")
  for _, config in pairs(shipMain) do
    if self.m_shipBreakMaxLv[config.ship_info_id] == nil or config.break_level > self.m_shipBreakMaxLv[config.ship_info_id] then
      self.m_shipBreakMaxLv[config.ship_info_id] = config.break_level
    end
  end
end

function ShipLogic:BreakItemsConversionMubo()
  local count1 = configManager.GetDataById("config_parameter", 507).value
  local count2 = configManager.GetDataById("config_parameter", 508).value
  self.m_BreakConversionNumMubo[18051] = count2
  self.m_BreakConversionNumMubo[17512] = count1 * count2
end

function ShipLogic:GetBreakItemsNumMubo(ItemId)
  if self.m_BreakConversionNumMubo[ItemId] == nil then
    return 1
  end
  return self.m_BreakConversionNumMubo[ItemId]
end

function ShipLogic:SetCountryItems()
  self.m_shipCountryItem = {}
  local configAllNew = configManager.GetData("config_ship_exp_item")
  for _, v in pairs(configAllNew) do
    if v.ship_country ~= nil and #v.ship_country > 0 then
      for _, countryId in pairs(v.ship_country) do
        if self.m_shipCountryItem[countryId] == nil then
          self.m_shipCountryItem[countryId] = {}
        end
        if not table.containV(self.m_shipCountryItem[countryId], v.id) then
          table.insert(self.m_shipCountryItem[countryId], v.id)
        end
      end
    end
  end
end

function ShipLogic:IsCountryShip(countryId)
  return self.m_shipCountryItem[countryId] ~= nil
end

function ShipLogic:SetTypeItems()
  self.m_shipTypeItem = {}
  local configAllNew = configManager.GetData("config_ship_exp_item")
  for _, v in pairs(configAllNew) do
    if v.ship_type ~= nil and #v.ship_type > 0 then
      for _, typeId in pairs(v.ship_type) do
        if self.m_shipTypeItem[typeId] == nil then
          self.m_shipTypeItem[typeId] = {}
        end
        if not table.containV(self.m_shipTypeItem[typeId], v.id) then
          table.insert(self.m_shipTypeItem[typeId], v.id)
        end
      end
    end
  end
end

function ShipLogic:IsTypeShip(typeId)
  return self.m_shipTypeItem[typeId]
end

function ShipLogic:GetShipInfoIdByTid(tid)
  return configManager.GetDataById("config_ship_main", tid).ship_info_id
end

function ShipLogic:GetShipInfoById(TemplateId)
  local shipInfo = configManager.GetDataById("config_ship_main", TemplateId)
  if not shipInfo then
    return nil
  end
  return configManager.GetDataById("config_ship_info", shipInfo.ship_info_id)
end

function ShipLogic:GetShipInfoBySiId(si_id)
  return configManager.GetDataById("config_ship_info", si_id)
end

function ShipLogic:GetShipInfoByHeroId(heroId)
  local shipInfoId = Logic.shipLogic:GetInfoIdByHeroId(heroId)
  return self:GetShipInfoBySiId(shipInfoId)
end

function ShipLogic:GetShipInfoBySsId(ss_id)
  local shipInfo = configManager.GetDataById("config_ship_info", ss_id, true)
  if shipInfo == nil then
    local shipShow = self:GetShipShowConfig(ss_id)
    shipInfo = self:GetShipInfoBySiId(shipShow.sf_id)
  end
  return shipInfo
end

function ShipLogic:GetShipShowById(TemplateId)
  local shipInfo = configManager.GetDataById("config_ship_main", TemplateId)
  if not shipInfo then
    return nil
  end
  return self:GetShipShowByInfoId(shipInfo.ship_info_id)
end

function ShipLogic:GetShipShowByHeroId(heroId)
  local fashionId = self:GetShipFashioning(heroId)
  return self:GetShipShowByFashionId(fashionId)
end

function ShipLogic:GetShipShowByFashionId(fashionId)
  if fashionId then
    local fashionData = configManager.GetDataById("config_fashion", fashionId)
    if fashionData then
      return configManager.GetDataById("config_ship_show", fashionData.ship_show_id)
    end
  end
  return nil
end

function ShipLogic:GetShipShowConfig(cid)
  return configManager.GetDataById("config_ship_show", cid)
end

function ShipLogic:GetShipFashioning(heroId)
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    return heroData.Fashioning
  else
    return nil
  end
end

function ShipLogic:GetDefaultShipShowByInfoId(si_id)
  local si_config = configManager.GetDataById("config_ship_info", si_id)
  if si_config then
    local sf_id = si_config.sf_id
    local fashionData = Logic.fashionLogic:GetDefaultFashionData(sf_id)
    return configManager.GetDataById("config_ship_show", fashionData.ship_show_id)
  end
  return nil
end

function ShipLogic:GetDefaultShipShowById(TemplateId)
  local shipInfo = configManager.GetDataById("config_ship_main", TemplateId)
  if not shipInfo then
    return nil
  end
  return self:GetDefaultShipShowByInfoId(shipInfo.ship_info_id)
end

function ShipLogic:GetShipShowByInfoId(si_id)
  local si_config = configManager.GetDataById("config_ship_info", si_id)
  if si_config then
    local sf_id = si_config.sf_id
    local fashionData = Logic.fashionLogic:GetDefaultFashionData(sf_id)
    return configManager.GetDataById("config_ship_show", fashionData.ship_show_id)
  end
  return nil
end

function ShipLogic:GetShipShowHandBookById(TemplateId)
  local shipInfo = configManager.GetDataById("config_ship_main", TemplateId)
  if not shipInfo then
    return nil
  end
  return configManager.GetDataById("config_ship_handbook", shipInfo.ship_info_id)
end

function ShipLogic:GetShipInfoId(sm_id)
  local shipInfo = configManager.GetDataById("config_ship_main", sm_id)
  if shipInfo == nil then
    logError("config_ship_main err. sm_id:" .. sm_id)
    return
  end
  return shipInfo.ship_info_id
end

function ShipLogic:GetSfIdBySmId(sm_id)
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(sm_id)
  local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
  return sf_id
end

function ShipLogic:GetShipTag(templateId)
  local shipInfo = configManager.GetDataById("config_ship_main", templateId)
  if shipInfo == nil then
    logError("config_ship_main err. sm_id:" .. templateId)
    return
  end
  return shipInfo.ship_tag_array
end

function ShipLogic:GetHeroMaxHp(heroId, fleetType)
  fleetType = fleetType or FleetType.Normal
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    local heroData = Data.heroData:GetHeroById(heroId)
    return npcAssistFleetMgr:GetNpcFinalAttrs(heroId)[AttrType.HP]
  else
    local finalAttrs = Logic.attrLogic:GetHeroFinalShowAttrById(heroId, fleetType)
    return finalAttrs[AttrType.HP]
  end
end

function ShipLogic:GetHeroLevelExp(level, country)
  local shipLevelExp = configManager.GetDataById("config_ship_levelup", level)
  if country == HeroCampType.Mubar then
    shipLevelExp = configManager.GetDataById("config_ship_levelup_mub", level)
  end
  local levelExp
  if shipLevelExp.exp ~= nil then
    levelExp = shipLevelExp.exp
  end
  return levelExp
end

function ShipLogic:GetAllHeroLevelExp(fLv, tLv, country)
  local levelExp = 0
  if tLv <= fLv then
    logError("\230\150\185\230\179\149\232\176\131\231\148\168\233\148\153\232\175\175")
    return levelExp
  end
  for i = fLv, tLv - 1 do
    local shipLevelExp = configManager.GetDataById("config_ship_levelup", i)
    if country == HeroCampType.Mubar then
      shipLevelExp = configManager.GetDataById("config_ship_levelup_mub", i)
    end
    levelExp = levelExp + shipLevelExp.exp
  end
  return levelExp
end

function ShipLogic:GetHeroCountryBySMId(sm_id)
  local smCfg = configManager.GetDataById("config_ship_main", sm_id)
  local shipCountry = configManager.GetDataById("config_ship_info", smCfg.ship_info_id).ship_country
  return shipCountry
end

function ShipLogic:GetHeroTypeBySMId(sm_id)
  local smCfg = configManager.GetDataById("config_ship_main", sm_id)
  local shipType = configManager.GetDataById("config_ship_info", smCfg.ship_info_id).ship_type
  return shipType
end

function ShipLogic:GetMaxExp(lv)
  if lv <= 0 then
    return 0
  end
  local lvlConfig = configManager.GetDataById("config_ship_levelup", lv)
  local curLvExp = 0
  for i = 1, lv do
    local exp = configManager.GetDataById("config_ship_levelup", i).exp
    curLvExp = curLvExp + exp
  end
  return curLvExp
end

function ShipLogic:GetLvByExp(exp)
  if exp <= 0 then
    return 0
  end
  lv = 0
  while 0 <= exp do
    exp = exp - self:GetLvExp(lv + 1)
    lv = lv + 1
  end
  return lv
end

function ShipLogic:GetPreLv(curExp, addExp, curLv)
  local preExp = curExp - addExp
  if 0 < preExp then
    return curLv
  end
  preExp = -preExp
  local preLv = curLv
  local add
  for i = curLv - 1, 0, -1 do
    add = Logic.shipLogic:GetLvExp(i)
    preExp = preExp - add
    preLv = preLv - 1
    if preExp <= 0 then
      return preLv
    end
  end
  return 1
end

function ShipLogic:GetLvExp(lv)
  if lv <= 0 then
    return 0
  end
  local lvlConfig = configManager.GetDataById("config_ship_levelup", lv)
  return lvlConfig.exp
end

function ShipLogic:GetHeroIcon(ss_id)
  local siConfig = configManager.GetDataById("config_ship_show", ss_id)
  local strIcon = siConfig.ship_icon1
  return strIcon
end

function ShipLogic:GetHeroCardIcon(ss_id, bBreak)
  local siConfig = configManager.GetDataById("config_ship_show", ss_id)
  local strIcon = bBreak and siConfig.ship_icon2_po or siConfig.ship_icon2
  return strIcon
end

function ShipLogic:GetHeroSquareIcon(ss_id, bBreak)
  local siConfig = configManager.GetDataById("config_ship_show", ss_id)
  local strIcon = bBreak and siConfig.ship_icon5_po or siConfig.ship_icon5
  return strIcon
end

function ShipLogic:GetHeroCircleIcon(ss_id, bBreak)
  local siConfig = configManager.GetDataById("config_ship_show", ss_id)
  local strIcon = bBreak and siConfig.ship_icon4_po or siConfig.ship_icon4
  return strIcon
end

function ShipLogic:GetHeroType(ss_id)
  local siConfig = configManager.GetDataById("config_ship_show", ss_id)
  local type = siConfig.ship_type
  return type
end

function ShipLogic:GetInfoIdByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return self:GetShipInfoId(heroInfo.TemplateId)
end

function ShipLogic:GetHeroTypeByHeroId(heroId)
  local shipShow = self:GetShipShowByHeroId(heroId)
  local type
  if shipShow then
    type = shipShow.ship_type
  end
  return type
end

function ShipLogic:GetHeroTagByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return self:GetShipTag(heroInfo.TemplateId)
end

function ShipLogic:GetShipInfoIdByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return self:GetShipInfoId(heroInfo.TemplateId)
end

function ShipLogic:GetPictureHero(IllustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(IllustrateId)
  local data = Logic.shipLogic:GetShipShowById(sm_id)
  if data then
    return data.ship_icon2
  end
  return ""
end

function ShipLogic:GetIcon2Black(IllustrateId)
  local shipShowId = Logic.illustrateLogic:GetIllustrateShowId(IllustrateId)
  local data = Logic.shipLogic:GetShipShowConfig(shipShowId)
  if data then
    return data.ship_icon2_black
  end
  return ""
end

function ShipLogic:GetPictureData(IllustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(IllustrateId)
  local data = Logic.shipLogic:GetShipShowById(sm_id)
  if data then
    return data
  end
  return nil
end

function ShipLogic:GetHeroModelPath(ss_id)
  local ssConfig = configManager.GetDataById("config_ship_show", ss_id)
  local model = configManager.GetDataById("config_ship_model", ssConfig.model_id).model
  return model
end

function ShipLogic:GetHeroModelConfigById(model_id)
  return configManager.GetDataById("config_ship_model", model_id).model
end

function ShipLogic:GetHeroMaxGasoline(si_id)
  local siConfig = configManager.GetDataById("config_ship_info", si_id)
  local max_gasoline = siConfig.max_gasoline
  return max_gasoline
end

function ShipLogic:GetHeroMaxAmmunition(si_id)
  local siConfig = configManager.GetDataById("config_ship_info", si_id)
  local max_ammunition = siConfig.max_ammunition
  return max_ammunition
end

function ShipLogic:GetHeroHpStatus(hp, maxHp)
  local percent = hp / maxHp
  local daMin = configManager.GetDataById("config_ship_hp_state", 4).hp_min_percent
  local zhongMin = configManager.GetDataById("config_ship_hp_state", 3).hp_min_percent
  local xiaoMin = configManager.GetDataById("config_ship_hp_state", 2).hp_min_percent
  local normalMin = configManager.GetDataById("config_ship_hp_state", 1).hp_min_percent
  if percent > normalMin then
    return DamageLevel.NonDamage
  elseif percent > xiaoMin then
    return DamageLevel.SmallDamage
  elseif percent > zhongMin then
    return DamageLevel.MiddleDamage
  elseif percent > daMin then
    return DamageLevel.BigDamage
  else
    return DamageLevel.Sinking
  end
end

function ShipLogic:GetHeroOilOrAmmo(value, maxValue)
  local percent = value / maxValue * 10000
  local thirty = tonumber(configManager.GetDataById("config_parameter", 4).value)
  local ten = tonumber(configManager.GetDataById("config_parameter", 5).value)
  if percent <= 0 then
    return 3
  elseif percent < thirty then
    return 2
  elseif percent < ten then
    return 1
  else
    return 0
  end
end

function ShipLogic:GetIcon(si_id)
  local config = configManager.GetDataById("config_ship_show", si_id)
  return config.ship_icon5
end

function ShipLogic:GetName(si_id)
  local config = configManager.GetDataById("config_ship_info", si_id)
  return config.ship_name
end

function ShipLogic:GetRealName(heroId)
  local name
  if heroId then
    local singleGirl = Data.heroData:GetHeroById(heroId)
    if singleGirl.Name ~= nil and singleGirl.Name ~= "" then
      name = singleGirl.Name
    else
      local si_id = self:GetInfoIdByHeroId(heroId)
      name = self:GetName(si_id)
    end
  end
  return name
end

function ShipLogic:GetShipNameBySmId(sm_id)
  local config = self:GetShipInfoById(sm_id)
  return config.ship_name
end

function ShipLogic:GetDesc(si_id)
  return ""
end

function ShipLogic:GetQuality(si_id)
  local config = configManager.GetDataById("config_ship_info", si_id)
  if config == nil then
    logError("get ship quality failture si_id:" .. si_id)
  end
  return config.quality
end

function ShipLogic:GetQualityByInfoId(si_id)
  local config = configManager.GetDataById("config_ship_info", si_id)
  if config == nil then
    logError("get ship quality failture si_id:" .. si_id)
  end
  return config.quality
end

function ShipLogic:GetQualityByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return self:GetQualityByInfoId(self:GetShipInfoId(heroInfo.TemplateId))
end

function ShipLogic:GetQualityByShowId(ss_id)
  local shipInfo = self:GetShipInfoBySsId(ss_id)
  return shipInfo.quality
end

function ShipLogic:GetFrame(si_id)
  return "", ""
end

function ShipLogic:GetTexIcon(si_id)
  local config = configManager.GetDataById("config_ship_show", si_id)
  return config.ship_icon5
end

function ShipLogic:GetRemouldTimes(si_id)
  local config = configManager.GetDataById("config_ship_info", si_id)
  return config.remould_level
end

function ShipLogic:GetBreakMaxByShipMainId(sm_id)
  return self:GetBreakMaxByShipFleetId(self:GetShipFleetId(self:GetShipInfoId(sm_id)))
end

function ShipLogic:GetBreakMaxByShipInfoId(si_id)
  return self:GetBreakMaxByShipFleetId(self:GetShipFleetId(si_id))
end

function ShipLogic:GetBreakMaxByShipFleetId(sf_id)
  local config = configManager.GetDataById("config_ship_fleet", sf_id)
  return config.break_num + 1
end

function ShipLogic:GetNameByShowId(ss_id)
  local config = configManager.GetDataById("config_ship_show", ss_id)
  return config.ship_name
end

function ShipLogic:GetIcon3(si_id)
  local config = configManager.GetDataById("config_ship_show", si_id)
  return config.ship_icon3
end

function ShipLogic:GetIcon3Dapo(si_id)
  local config = configManager.GetDataById("config_ship_show", si_id)
  return config.ship_icon3_po
end

function ShipLogic:GetDressupId(model, curHp, maxHp)
  local config = configManager.GetDataById("config_ship_model", model)
  local shipStatus = self:GetHeroHpStatus(curHp, maxHp)
  if shipStatus > DamageLevel.SmallDamage then
    return config.standard_dapo
  else
    return config.standard_normal
  end
end

function ShipLogic:GetARSecClear(model)
  local config = configManager.GetDataById("config_ship_model", model)
  return config.ar_sec_clear
end

function ShipLogic:CheckAdvanceCosumeHeroFit(heroTId, consumeTId)
  local config = configManager.GetDataById("config_ship_break", heroTId)
  local breakItem = config.break_item
  local consumeHeroArr = breakItem[1]
  if #breakItem == 0 then
    return true
  end
  return table.containV(consumeHeroArr, consumeTId)
end

function ShipLogic:CheckAdvanceCosumeNumFit(heroTId, num, itemNum)
  local config = configManager.GetDataById("config_ship_break", heroTId)
  local breakItem = config.break_item
  local consumeHeroNum = breakItem[2]
  if #breakItem == 0 then
    return true
  end
  return consumeHeroNum == num + itemNum
end

function ShipLogic:GetShipFleetId(si_id)
  local config = configManager.GetDataById("config_ship_info", si_id)
  return config.sf_id
end

function ShipLogic:GetShipUniqueIdById(heroId)
  local uniqueId
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local shipInfoId = Logic.shipLogic:GetShipInfoIdByTid(heroData.TemplateId)
    uniqueId = Logic.shipLogic:GetShipFleetId(shipInfoId)
  end
  return uniqueId
end

function ShipLogic:GetSfidBySmid(sm_id)
  local si_id = configManager.GetDataById("config_ship_main", sm_id).ship_info_id
  return configManager.GetDataById("config_ship_info", si_id).sf_id
end

function ShipLogic:CheckSameShipMain(idA, idB)
  local si_idA = self:GetShipInfoId(idA)
  local si_idB = self:GetShipInfoId(idB)
  local sf_idA = self:GetShipFleetId(si_idA)
  local sf_idB = self:GetShipFleetId(si_idB)
  return sf_idA == sf_idB
end

function ShipLogic:GetPSkillLvMax(pskillId)
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  return config.max_level
end

function ShipLogic:GetPSkillMaterials(pskillId)
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  return config.upgrade_materials, config.upgrade_materials_mub
end

function ShipLogic:GetNextReplaceSkillId(oripskillId, level, replaceId)
  local config = configManager.GetDataById("config_pskill_dict_group", oripskillId)
  local skill_replace = config.skill_replace
  local nextid = replaceId ~= nil and replaceId ~= 0 and replaceId or oripskillId
  if #skill_replace == 0 then
    return nextid
  end
  for _, info in ipairs(skill_replace) do
    if level + 1 >= info[1] then
      nextid = info[2]
    end
  end
  return nextid
end

function ShipLogic:GetPSkillLvByExp(pskillExp)
  local config = configManager.GetData("config_ship_talent_upgrade_exp")
  for lv = 1, GetTableLength(config) do
    pskillExp = pskillExp - config[lv].exp
    if pskillExp < 0 then
      return lv
    end
  end
  return GetTableLength(config)
end

function ShipLogic:GetTotalExpByPSkillLv(pskillLv)
  local config = configManager.GetData("config_ship_talent_upgrade_exp")
  if pskillLv <= 0 then
    return 0
  end
  local res = 0
  for lv = 1, pskillLv do
    res = res + config[lv].exp
  end
  return res
end

function ShipLogic:GetPSkillLvLowerAndUpper(pskillLv)
  local config = configManager.GetData("config_ship_talent_upgrade_exp")
  if pskillLv <= 1 then
    return 0, config[1].exp
  end
  local lower, upper = 0
  for lv = 1, pskillLv - 1 do
    lower = lower + config[lv].exp
  end
  upper = lower + config[pskillLv].exp
  return lower, upper
end

function ShipLogic:GetPSkillShowDesc(pskillId, heroId, tid)
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  local des = config.desc
  if self:_isMAIN_GUN_CDPSkill(pskillId) then
    local cd = 0
    if heroId then
      cd = Logic.attrLogic:GetHeroFinalShowAttrById(heroId)[AttrType.MAIN_GUN_CD]
    elseif tid then
      cd = Logic.attrLogic:GetHeroBaseAttrByTid(tid)[AttrType.MAIN_GUN_CD]
    end
    cd = math.tointeger(cd)
    des = string.format(des, cd)
  end
  return des
end

function ShipLogic:_isMAIN_GUN_CDPSkill(pskillId)
  return pskillId == 4000 or pskillId == 4001 or pskillId == 4002
end

function ShipLogic:GetPSkillDesc(pskillId, lv, bUp)
  if type(pskillId) == "table" then
    return ""
  end
  lv = lv or 1
  local did = self:GetPSkillDisplayIdByGroupId(pskillId)
  local config = configManager.GetDataById("config_pskill_dict_display", did)
  if config == nil then
    return ""
  end
  local desc_val = config.desc_val
  local replArr = {}
  local index = 1
  for i = 1, #desc_val, 3 do
    local curValue = desc_val[i] + desc_val[i + 1] * (lv - 1)
    if Mathf.Abs(curValue - Mathf.ToInt(curValue)) < 0.01 then
      curValue = Mathf.ToInt(curValue)
    end
    local addValue = desc_val[i + 1]
    local pmStr = desc_val[i + 1] >= 0 and "+" or "-"
    local replStr
    local bPercent = desc_val[i + 2] == 0
    if bPercent and bUp then
      replStr = string.format("%s%%(%s%s%%)", curValue, pmStr, addValue)
    elseif not bPercent and bUp then
      replStr = string.format("%s(%s%s)", curValue, pmStr, addValue)
    elseif bPercent and not bUp then
      replStr = string.format("%s%%", curValue)
    elseif not bPercent and not bUp then
      replStr = string.format("%s", curValue)
    end
    if addValue ~= 0 then
      replStr = UIHelper.SetColor(replStr, config.desc_color[index])
    end
    table.insert(replArr, replStr)
    index = index + 1
  end
  return string.formatEx(config.desc2, replArr)
end

function ShipLogic:GetPSkillName(pskillId)
  if type(pskillId) == "table" then
    return UIHelper.GetString(920000070)
  end
  local id = self:GetPSkillDisplayIdByGroupId(pskillId)
  return self:GetPSkillDisplayConfigById(id).skill_name
end

function ShipLogic:GetPSkillIcon(pskillId, tid)
  if type(pskillId) == "table" then
    if tid then
      return self:_GetSpSkillIcon(tid)
    else
      return self:GetPSkillIcon(pskillId[1])
    end
  end
  local id = self:GetPSkillDisplayIdByGroupId(pskillId)
  return self:GetPSkillDisplayConfigById(id).skill_icon
end

function ShipLogic:_GetSpSkillIcon(templateId)
  return configManager.GetDataById("config_ship_main", templateId).ship_weapon
end

function ShipLogic:GetPSkillType(pskillId)
  if type(pskillId) == "table" then
    return self:GetPSkillType(pskillId[1])
  end
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  return config.talent_type
end

function ShipLogic:GetRecommendSkillBookId(pskillId)
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  if config.talent_type == TalentType.ATTACK then
    return configManager.GetDataById("config_parameter", 166).value
  elseif config.talent_type == TalentType.DEFEND then
    return configManager.GetDataById("config_parameter", 167).value
  elseif config.talent_type == TalentType.ASSIST then
    return configManager.GetDataById("config_parameter", 168).value
  end
end

function ShipLogic:GetPSkillDisplayIdByGroupId(skillGroupDictId)
  return configManager.GetDataById("config_pskill_dict_group", skillGroupDictId).pskill_dict_display_id
end

function ShipLogic:GetPSkillDisplayConfigById(id)
  return configManager.GetDataById("config_pskill_dict_display", id)
end

function ShipLogic:GetAllPSkillArrbyShipMainId(sm_id)
  local config = configManager.GetDataById("config_ship_main", sm_id)
  local arr = {}
  table.insert(arr, config.pskill_show_id)
  table.insertto(arr, config.direct_activate_talent_id)
  table.insertto(arr, config.condition_activate_talent_id)
  return arr
end

function ShipLogic:GetShipEquipInfo(templateId, shipInfo)
  local shipEquip = configManager.GetDataById("config_ship_equip", templateId)
  local result = {}
  for i = 1, #shipEquip.equip_attr_condition do
    local tmp = {}
    tmp.equipAttr = shipEquip["equip_attr_num_" .. i]
    if tmp.equipAttr[1] and tmp.equipAttr[1] > 0 then
      tmp.open = true
      tmp.advanceDesc = ""
      local condition = shipEquip.equip_attr_condition[i]
      if GetTableLength(condition) ~= 0 then
        for _, v in ipairs(condition) do
          local res, _ = Logic.gameLimitLogic.CheckConditionById(v, shipInfo.HeroId)
          if not res then
            local limitConfig = Logic.gameLimitLogic.GetLimitConfig(v)
            tmp.open = false
            tmp.advanceDesc = limitConfig.desc
            shipEquip = configManager.GetDataById("config_ship_equip", templateId + limitConfig.limit_param[1] - shipInfo.Advance)
            tmp.equipAttr = shipEquip["equip_attr_num_" .. i]
          end
        end
      end
      table.insert(result, tmp)
    end
  end
  return result
end

function ShipLogic:GetShipOpenEquipNum(shipInfo)
  local openEquipNum = 0
  local tabShipEquip = self:GetShipEquipInfo(shipInfo.TemplateId, shipInfo)
  for k, v in pairs(tabShipEquip) do
    if v.open then
      openEquipNum = openEquipNum + 1
    end
  end
  return openEquipNum
end

function ShipLogic:GetHeroHp(heroId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local hp = heroInfo.CurHp / HP_COEFFICIENT
  if 1 < hp then
    hp = 1
  end
  local maxHp = Logic.shipLogic:GetHeroMaxHp(heroId, fleetType)
  hp = maxHp * hp
  return math.ceil(hp)
end

function ShipLogic:GetSportMeetAssistShioHp(heroId, fleetType, lostHp)
  fleetType = fleetType or FleetType.Normal
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local maxHp = Logic.shipLogic:GetHeroMaxHp(heroId, fleetType)
  return math.ceil(maxHp - lostHp)
end

function ShipLogic:GetBaseShipNum()
  local down = configManager.GetDataById("config_parameter", 20).value
  local up = configManager.GetDataById("config_parameter", 129).value
  local heroBagSize = Data.heroData:GetHeroBagSize()
  return Mathf.ToInt(Mathf.Clamp(heroBagSize, down, up))
end

function ShipLogic:GetBreakMinLevel(tid)
  local res = configManager.GetDataById("config_ship_break", tid).min_level
  if res == nil then
    logError("Can't find break config about " .. tid)
  end
  return res
end

function ShipLogic:GetBreakItem(tid)
  local res = configManager.GetDataById("config_ship_break", tid).break_item
  if res == nil then
    logError("Can't find break config about " .. tid)
  end
  return res
end

function ShipLogic:GetBreakItemMubo(tid)
  local res = configManager.GetDataById("config_ship_break", tid).break_item_mub
  if res == nil then
    logError("Can't find shipbreak config about break_item_mub" .. tid)
  end
  return res
end

function ShipLogic:CheckBreakItemMubo(tid, itemId)
  local res = configManager.GetDataById("config_ship_break", tid).break_usableitem_mub
  if res == nil then
    logError("Can't find shipbreak config about break_item_mub" .. tid)
    return false
  end
  local isRight = false
  for _, v in pairs(res) do
    if v == itemId then
      isRight = true
      break
    end
  end
  return isRight
end

function ShipLogic:GetBreakCost(tid)
  local res = configManager.GetDataById("config_ship_break", tid).currency_cost
  if res == nil then
    logError("Can't find break config about " .. tid)
  end
  return res
end

function ShipLogic:GetShipTypeIcon(shipType)
  local typeInfo = configManager.GetDataById("config_ship_type", shipType)
  return typeInfo.wordsimage
end

function ShipLogic:GetSpSkill(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).pskill_sp_talent_id
end

function ShipLogic:GetAttackWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).attack * 0.001
end

function ShipLogic:GetTorpedoWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).torpedo_attack * 0.001
end

function ShipLogic:GetToshipWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).ship_bomb_attack * 0.001
end

function ShipLogic:GetToAirWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).ship_air_control * 0.001
end

function ShipLogic:GetPlaneControlWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).plane_air_control * 0.001
end

function ShipLogic:GetAir2ShipWorth(sm_id)
  return Logic.attrLogic:GetCombatEff(sm_id).plane_bomb_attack * 0.001
end

function ShipLogic:GetTorpedoFactor(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).torpedo_coefficient * 0.001
end

function ShipLogic:GetAttackFactor(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).fire_coefficient * 0.001
end

function ShipLogic:GetToshipFactor(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).attack_ship_coefficient * 0.001
end

function ShipLogic:GetToAirFactor(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).air_combat_coefficient * 0.001
end

function ShipLogic:GetHeroCharcater(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).character, configManager.GetDataById("config_ship_main", sm_id).characterlevel
end

function ShipLogic:GetHeroCharcaterStr(sm_id)
  local ids = configManager.GetDataById("config_ship_main", sm_id).character
  local res = {}
  for _, id in ipairs(ids) do
    local name = configManager.GetDataById("config_character", id).name
    table.insert(res, name)
  end
  return res
end

function ShipLogic:GetHeroCharcaterMaxLevel(sm_id)
  return configManager.GetDataById("config_ship_main", sm_id).charactermaxlevel
end

function ShipLogic:GetCharacterName(charId)
  return configManager.GetDataById("config_character", charId).name
end

function ShipLogic:GetRmdEquipType(sm_id)
  return configManager.GetDataById("config_ship_equip", sm_id).recommend_equip
end

function ShipLogic:GetShipEquipPosTypes(sm_id, index)
  local temp = self.m_ship2equipType
  if temp and temp[sm_id] then
    temp = temp[sm_id]
    return temp[index] or {}
  end
  return {}
end

function ShipLogic:IsLock(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return heroInfo.Lock
end

function ShipLogic:IsInFleet(heroId)
  local map = Logic.fleetLogic:GetHeroFleetMap()
  return not not map[heroId]
end

function ShipLogic:GetHeroFleet(heroId)
  local map = Logic.fleetLogic:GetHeroFleetMap()
  for k, v in pairs(map) do
    if k == heroId then
      return v
    end
  end
  return 0
end

function ShipLogic:IsInCrusade(heroId)
  local assistData = Data.assistNewData:GetAssistData()
  if assistData == nil or #assistData == 0 then
    return false
  end
  for i, v in ipairs(assistData) do
    if v.HeroList and table.containV(v.HeroList, heroId) then
      return true
    end
  end
  return false
end

function ShipLogic:IsSecretary(heroId)
  local tabUserInfo = Data.userData:GetUserData()
  if tabUserInfo.SecretaryId == heroId then
    return true
  end
  return false
end

function ShipLogic:IsInBuilding(heroId)
  return Data.buildingData:IsInBuilding(heroId)
end

function ShipLogic:RemoveFleetShip(tabHero)
  local tabTemp = {}
  for k, v in pairs(tabHero) do
    if Logic.shipLogic:GetHeroFleet(v.HeroId) == 0 then
      tabTemp[#tabTemp + 1] = v
    end
  end
  return tabTemp
end

function ShipLogic:IsHasHero(heroId)
  local arrHero = Data.heroData:GetHeroData()
  return arrHero ~= nil and arrHero[heroId] ~= nil
end

function ShipLogic:CheckHasShip(sm_id)
  local tblSfId = self:GetAllHeroSfId()
  local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
  local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
  return self.tblSfId[sf_id] ~= nil
end

function ShipLogic:GetHeroPSkillExp(heroId, pskillId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local exp = heroInfo.PSKillMap[pskillId] or 0
  assert(exp, "hero:" .. tostring(heroId) .. "has no pskill:" .. tostring(pskillId))
  return exp
end

function ShipLogic:GetPSkillArrbyHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return heroInfo.PSkill
end

function ShipLogic:GetPSkillActiveArrbyHeroId(heroId)
  local arr = self:GetPSkillArrbyHeroId(heroId)
  for i = #arr, 1, -1 do
    local pskillId = arr[i].PSkillId
    if not self:CheckHeroPSkillActive(heroId, pskillId) then
      table.remove(arr, i)
    end
  end
  return arr
end

function ShipLogic:IsFlagShip(heroId)
  return heroId == Data.userData:GetUserData().SecretaryId
end

function ShipLogic:GetHeroTid(heroId)
  return Data.heroData:GetHeroById(heroId).TemplateId
end

function ShipLogic:CheckBreakConditionFit(heroId, consumeHeroArr, consumeItemArr)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local heroTId = heroInfo.TemplateId
  local config = configManager.GetDataById("config_ship_break", heroTId)
  local minLvNeed = config.min_level
  if minLvNeed > heroInfo.Lvl then
    return false, UIHelper.GetString(180005)
  end
  local maxBreak = self:GetBreakMaxByShipMainId(heroTId)
  if maxBreak <= heroInfo.Advance then
    return false, UIHelper.GetString(920000071)
  end
  local cType, costNum = config.currency_cost[2], config.currency_cost[3]
  if not Logic.currencyLogic:CheckCurrencyEnough(cType, costNum) then
    return false, UIHelper.GetString(180004)
  end
  for _, consumeId in pairs(consumeHeroArr) do
    local consumeHeroInfo = Data.heroData:GetHeroById(consumeId)
    if consumeHeroInfo.HeroId == heroId then
      return false, UIHelper.GetString(920000609)
    end
    local bConsumeFit = Logic.shipLogic:CheckAdvanceCosumeHeroFit(heroTId, consumeHeroInfo.TemplateId)
    if not bConsumeFit then
      return false, UIHelper.GetString(920000610)
    end
    if Logic.shipLogic:IsLock(consumeHeroInfo.HeroId) then
      return false, UIHelper.GetString(180020)
    end
    if Logic.shipLogic:IsInFleet(consumeHeroInfo.HeroId) then
      return false, UIHelper.GetString(110014)
    end
    if Logic.shipLogic:IsInCrusade(consumeHeroInfo.HeroId) then
      return false, UIHelper.GetString(971020)
    end
    if Logic.studyLogic:CheckHeroAlreadyStudy(consumeHeroInfo.HeroId) then
      return false, UIHelper.GetString(180018)
    end
    if Logic.bathroomLogic:CheckInBath(consumeHeroInfo.HeroId) then
      return false, UIHelper.GetString(180019)
    end
  end
  local consumeItemNum = 0
  if consumeItemArr and 0 < #consumeItemArr then
    consumeItemNum = #consumeItemArr
  end
  if not self:CheckAdvanceCosumeNumFit(heroTId, #consumeHeroArr, consumeItemNum) then
    return false, UIHelper.GetString(180006)
  end
  return true
end

function ShipLogic:CheckBreakConditionFitMubo(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local heroTId = heroInfo.TemplateId
  local config = configManager.GetDataById("config_ship_break", heroTId)
  local minLvNeed = config.min_level
  if minLvNeed > heroInfo.Lvl then
    return false, UIHelper.GetString(180005)
  end
  local maxBreak = Logic.shipLogic:GetShipMaxBreakLvBySMId(heroTId)
  if maxBreak <= heroInfo.Advance then
    return false, UIHelper.GetString(920000071)
  end
  if #config.currency_cost > 0 then
    local cType, costNum = config.currency_cost[2], config.currency_cost[3]
    if not Logic.currencyLogic:CheckCurrencyEnough(cType, costNum) then
      return false, UIHelper.GetString(180004)
    end
  end
  local tabBreakItem = Logic.shipLogic:GetBreakItemMubo(heroTId)
  if 0 < #tabBreakItem then
    local selectItemCount = Logic.shipLogic:GetMuboSelectBreakItemCount(heroTId)
    if selectItemCount ~= tabBreakItem[2] then
      return false, UIHelper.GetString(180003)
    end
  end
  return true
end

function ShipLogic:ShowShipStarInfo(advance)
  if advance == 0 then
    return 0, 0
  end
  local defaultShowStar = 6
  local line = math.modf(advance / defaultShowStar)
  local subCount = math.fmod(advance, defaultShowStar)
  if subCount == 0 then
    line = line - 1
    subCount = defaultShowStar
  end
  return line, subCount
end

function ShipLogic:GetMuboSelectBreakItemCount(tid)
  local count = 0
  local breakItem = Logic.shipLogic:GetBreakItemMubo(tid)
  local selectBreakItemsMubo = Logic.shipLogic:GetConsumeBreakItemMubo()
  for k, v in pairs(selectBreakItemsMubo) do
    if k == breakItem[1] then
      count = count + v
    else
      local num = Logic.shipLogic:GetBreakItemsNumMubo(k)
      count = count + num * v
    end
  end
  return count
end

function ShipLogic:GetRmdBreakHero(heroId)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return nil
  end
  local ok, heroInfo = Data.heroData:VerifyHero(heroId)
  if not ok then
    return nil
  end
  local tid = heroInfo.TemplateId
  local conf = configManager.GetDataById("config_ship_break", tid).break_item
  if next(conf) == nil then
    return nil
  else
    local function array2map(array)
      local map = {}
      
      for i, v in ipairs(array) do
        map[v] = i
      end
      return map
    end
    
    local map = array2map(conf[1])
    
    local function develop(hero)
      if hero then
        local id = hero.HeroId
        return Logic.shipLogic:CheckHasBreak(id) or Logic.shipLogic:CheckHasIntensify(id) or hero.Lvl > 1
      end
      return false
    end
    
    local function filter(hero)
      if hero == nil then
        return false
      end
      local tid = hero.TemplateId
      local id = hero.HeroId
      local noself = id ~= heroId
      local consumefix = map[tid] ~= nil
      local nolock = not self:IsLock(id)
      local nofleet = not self:IsInFleet(id)
      local noasset = not self:IsInCrusade(id)
      local nobath = not Logic.bathroomLogic:CheckInBath(id)
      local nodev = not develop(hero)
      return noself and consumefix and nolock and nofleet and noasset and nobath and nodev
    end
    
    local function sorter(heros)
      return table.sort(heros, function(h1, h2)
        return h1.TemplateId < h2.TemplateId
      end)
    end
    
    local allHero = Data.heroData:GetHeroData()
    local candidate = {}
    for _, v in pairs(allHero) do
      if filter(v) then
        table.insert(candidate, v)
      end
    end
    if #candidate == 0 then
      return nil
    end
    if 1 < #candidate then
      sorter(candidate)
    end
    local res = {}
    for i, v in ipairs(candidate) do
      if i <= conf[2] then
        table.insert(res, v.HeroId)
      end
    end
    return res
  end
end

function ShipLogic:GetBreakEffectList(templateId)
  return configManager.GetDataById("config_ship_break", templateId).ship_break_effect_id_list
end

function ShipLogic:GetHeroPSkillLv(heroId, pskillId)
  if type(pskillId) == "table" then
    return -1
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  return heroInfo.PSKillLevelMap[pskillId] or 1
end

function ShipLogic:CheckHeroPSkillActive(heroId, pskillId)
  if type(pskillId) == "table" then
    return true, ""
  end
  local config = configManager.GetDataById("config_pskill_dict_group", pskillId)
  local bRet, msg = Logic.gameLimitLogic.CheckConditionByIdGroup(config.active_condition, heroId)
  return bRet, msg
end

function ShipLogic:CheckHeroPSkillReachMax(heroId, pskillId)
  local lv = self:GetHeroPSkillLv(heroId, pskillId)
  local max = self:GetPSkillLvMax(pskillId)
  return lv >= max
end

function ShipLogic:CheckHighQuality(heroId)
  local sm_id = Data.heroData:GetHeroById(heroId).TemplateId
  local quality = self:GetQualityByInfoId(self:GetShipInfoId(sm_id))
  return quality > HeroRarityType.N
end

function ShipLogic:CheckHasIntensify(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local intensify = heroInfo.Intensify
  return 0 < #intensify
end

function ShipLogic:CheckHasBreak(heroId)
  local sm_id = Data.heroData:GetHeroById(heroId).TemplateId
  local config = configManager.GetDataById("config_ship_main", sm_id)
  local breakLevel = config.break_level
  return 1 < breakLevel
end

function ShipLogic:DotBreakCondition(heroId)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return false
  end
  local heroTId = heroInfo.TemplateId
  local config = configManager.GetDataById("config_ship_break", heroTId)
  local minLvNeed = config.min_level
  if minLvNeed > heroInfo.Lvl then
    return false
  end
  local maxBreak = self:GetBreakMaxByShipMainId(heroTId)
  if maxBreak <= heroInfo.Advance then
    return false
  end
  if #config.currency_cost > 0 then
    local cType, costNum = config.currency_cost[2], config.currency_cost[3]
    if not Logic.currencyLogic:CheckCurrencyEnough(cType, costNum) then
      return false
    end
  end
  local res = configManager.GetDataById("config_ship_break", heroTId).break_item
  if next(res) == nil then
    return true
  else
    local expendTid = res[1][1]
    local allHero = Data.heroData:GetHeroData()
    local consumeHeroArr = {}
    for k, heroInfo in pairs(allHero) do
      if heroInfo and heroInfo.TemplateId == expendTid then
        table.insert(consumeHeroArr, heroInfo.HeroId)
      end
    end
    local fit = self:_checkHeroList(heroId, heroTId, consumeHeroArr)
    if fit >= res[2] then
      return true
    end
  end
  return false
end

function ShipLogic:_checkHeroList(heroId, heroTId, consumeHeroArr)
  local meetNum = 0
  for _, consumeId in pairs(consumeHeroArr) do
    local consumeHeroInfo = Data.heroData:GetHeroById(consumeId)
    local bNotSelf = consumeHeroInfo.HeroId ~= heroId
    local bConsumeFit = Logic.shipLogic:CheckAdvanceCosumeHeroFit(heroTId, consumeHeroInfo.TemplateId)
    local bNotLock = not Logic.shipLogic:IsLock(consumeHeroInfo.HeroId)
    local bNotInFleet = not Logic.shipLogic:IsInFleet(consumeHeroInfo.HeroId)
    if bNotSelf and bConsumeFit and bNotLock and bNotInFleet then
      meetNum = meetNum + 1
    end
  end
  return meetNum
end

function ShipLogic:IsNewShip(heroId)
  local heroIdArr = Data.heroData:GetRecordNewHero()
  if next(heroIdArr) == nil then
    return false
  end
  for i = 1, #heroIdArr do
    if heroIdArr[i] == heroId then
      return true
    end
  end
  return false
end

function ShipLogic:ClearNewReward(heroId)
  local heroIdArr = Data.heroData:GetRecordNewHero()
  if next(heroIdArr) == nil then
    return
  end
  for i = 1, #heroIdArr do
    if heroIdArr[i] == heroId then
      table.remove(heroIdArr, i)
    end
  end
end

function ShipLogic:CheckHaveNShip()
  local heroDataTab = Data.heroData:GetHeroData()
  for k, heroInfo in pairs(heroDataTab) do
    local inFleet = Logic.shipLogic:IsInFleet(heroInfo.HeroId)
    local shipInfo = self:GetShipInfoById(heroInfo.TemplateId)
    local shipQuality = self:GetQualityByInfoId(shipInfo.si_id)
    if shipQuality == ShipQuality.N and heroInfo.Lvl == 1 and inFleet == false then
      return true
    end
  end
  return false
end

function ShipLogic:CheckFlagShipEquip()
  local tabUserInfo = Data.userData:GetUserData()
  local equipDataTab = Data.equipData:GetEquipData()
  local shipInfo = Data.heroData:GetHeroById(tabUserInfo.SecretaryId)
  local equipTrench = Logic.shipLogic:GetShipEquipInfo(shipInfo.TemplateId, shipInfo)
  local tabTrenchId = equipTrench[1].equipAttr
  local equipTab = Logic.equipLogic:GetEquipConfig(equipDataTab, tabTrenchId, tabUserInfo.SecretaryId)
  local meetContation = {}
  for i, v in ipairs(equipTab) do
    if v.HeroId == 0 then
      table.insert(meetContation, v)
    end
  end
  if #meetContation ~= 0 then
    return true
  end
  return false
end

function ShipLogic:GetAllHeroSfId()
  local tabShipInfoFleetId = {}
  for tid, num in pairs(Data.heroData:GetCurrAllHeroTid()) do
    tabShipInfoFleetId[self:GetShipInfoById(tid).sf_id] = 1
  end
  return tabShipInfoFleetId
end

function ShipLogic:GetAllHeroTid()
  return Data.heroData:GetCurrAllHeroTid()
end

function ShipLogic:GetRidHeroId(heroId)
  local displayInfo = Data.heroData:GetHeroData()
  local heroTab = {}
  for k, v in pairs(displayInfo) do
    if k ~= heroId then
      heroTab[k] = v
    end
  end
  return heroTab
end

function ShipLogic:GetRidHeroTid(heroTid)
  local displayInfo = Data.heroData:GetHeroData()
  local heroTab = {}
  for k, v in pairs(displayInfo) do
    if v.TemplateId ~= heroTid then
      heroTab[k] = v
    end
  end
  return heroTab
end

function ShipLogic:GetShipTypeName(typeTab)
  local nameTab = ""
  for i, v in ipairs(typeTab) do
    local typeInfo = configManager.GetDataById("config_ship_type", v)
    if i == 1 then
      nameTab = typeInfo.name
    else
      nameTab = nameTab .. "\227\128\129" .. typeInfo.name
    end
  end
  return nameTab
end

function ShipLogic:GetExpItemTable(level, country, shipType)
  local configAll = {}
  local isCountryShip = self:IsCountryShip(country)
  local isTypeShip = self:IsTypeShip(shipType)
  local configAllNew = configManager.GetData("config_ship_exp_item")
  for _, v in pairs(configAllNew) do
    local isAdd = true
    if isCountryShip then
      if not table.containV(v.ship_country, country) then
        isAdd = false
      end
    elseif #v.ship_country > 0 then
      isAdd = false
    end
    if isTypeShip then
      if not table.containV(v.ship_type, shipType) then
        isAdd = false
      end
    elseif 0 < #v.ship_type then
      isAdd = false
    end
    if isAdd then
      if #v.level_limit == 0 then
        table.insert(configAll, v)
      elseif level >= v.level_limit[1] and level <= v.level_limit[2] then
        table.insert(configAll, v)
      end
    end
  end
  table.sort(configAll, function(a, b)
    return a.exp < b.exp
  end)
  return configAll
end

function ShipLogic:GetLevelUpInfoByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local shipCountry = Logic.shipLogic:GetHeroCountryBySMId(heroInfo.TemplateId)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  local level = heroInfo.Lvl
  local config_use = self:GetExpItemTable(level, shipCountry, shipType)
  local itemTableByLevel = {}
  local expLeftByLevel = {}
  local canLvUp = true
  local exp = heroInfo.Exp
  local maxLevel = Logic.shipLogic:GetLevelUpMaxById(heroId)
  local levelUp = 0
  while maxLevel >= level + levelUp do
    levelUp = levelUp + 1
    local upLv = level + levelUp
    local expNeed = Logic.shipLogic:GetAllHeroLevelExp(level, upLv, shipCountry)
    local expLevelUp = expNeed - exp
    itemTableByLevel[levelUp], canLvUp, expLeftByLevel[levelUp] = self:GetExpItemTableByExp(config_use, expLevelUp, upLv)
    if not canLvUp then
      break
    end
  end
  return itemTableByLevel, expLeftByLevel
end

function ShipLogic:GetLevelUpMaxById(heroId)
  local maxLevel = Logic.shipLogic:GetLevelMaxByHeroId(heroId) - 1
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local advanceLvMax = Logic.shipLogic:GetLevelMaxByAdvance(heroInfo.TemplateId)
  local maxLevelLimit = advanceLvMax - 1
  local shipMainCfg = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local breakTimes = #shipMainCfg.unlock_item
  local advanceLv = 0
  if 0 < breakTimes then
    for i = 1, breakTimes do
      local shipAdvanceCfg = configManager.GetDataById("config_ship_advance", i)
      if i == 1 then
        advanceLv = shipAdvanceCfg.initial_level
      elseif i == breakTimes and heroInfo.Lvl == shipAdvanceCfg.max_level then
        advanceLv = shipAdvanceCfg.max_level
      end
      if heroInfo.Lvl >= shipAdvanceCfg.initial_level and heroInfo.Lvl < shipAdvanceCfg.max_level then
        advanceLv = shipAdvanceCfg.max_level
      end
    end
  end
  return math.min(maxLevel, maxLevelLimit, advanceLv)
end

function ShipLogic:GetExpItemTableByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local level = heroInfo.Lvl
  local exp = heroInfo.Exp
  local shipCountry = Logic.shipLogic:GetHeroCountryBySMId(heroInfo.TemplateId)
  local expNeed = Logic.shipLogic:GetHeroLevelExp(level, shipCountry)
  local expLevelUp = expNeed - exp
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  local configAll = self:GetExpItemTable(level, shipCountry, shipType)
  return self:GetExpItemTableByExp(configAll, expLevelUp, level)
end

function ShipLogic:GetExpItemIdLessByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local level = heroInfo.Lvl
  local shipCountry = Logic.shipLogic:GetHeroCountryBySMId(heroInfo.TemplateId)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  local configAll = self:GetExpItemTable(level, shipCountry, shipType)
  return configAll[1].id
end

function ShipLogic:GetExpItemTableByExp(configAll, expLevelUp, level)
  local result = {}
  local expAllSum = 0
  for i = 1, #configAll do
    local config = configAll[i]
    if #config.level_limit == 0 or level >= config.level_limit[1] and level <= config.level_limit[2] then
      local exp = config.exp
      local num = Logic.bagLogic:GetBagItemNum(config.id)
      if 0 < num then
        local resultSub = {}
        resultSub.Id = config.id
        if expLevelUp <= exp * num then
          resultSub.Num = math.ceil(expLevelUp / exp)
          expAllSum = expAllSum + exp * math.ceil(expLevelUp / exp)
          table.insert(result, resultSub)
          return result, true, expAllSum - expLevelUp
        else
          resultSub.Num = num
          expAllSum = expAllSum + exp * num
          table.insert(result, resultSub)
          expLevelUp = expLevelUp - exp * num
        end
      end
    end
  end
  if 0 < expAllSum then
    return result, false, expAllSum - expLevelUp
  else
    return nil, false, nil
  end
end

function ShipLogic:GetLevelMaxByHeroId(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local shipConfig = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local shipInfoCfg = configManager.GetDataById("config_ship_info", shipConfig.ship_info_id)
  local talentLv = Data.talentData:GetTalentLvByType(shipInfoCfg.ship_type)
  local maxLv = shipConfig.ship_levelup_max + talentLv
  return maxLv
end

function ShipLogic:GetLevelMaxByAdvance(templateId)
  local shipAdvanceCfgs = configManager.GetData("config_ship_advance")
  local maxLv = 0
  for _, v in pairs(shipAdvanceCfgs) do
    if maxLv < v.max_level then
      maxLv = v.max_level
    end
  end
  if templateId then
    local shipConfig = configManager.GetDataById("config_ship_main", templateId)
    local shipInfoCfg = configManager.GetDataById("config_ship_info", shipConfig.ship_info_id)
    local talentLv = Data.talentData:GetTalentLvByType(shipInfoCfg.ship_type)
    maxLv = maxLv + talentLv
  end
  return maxLv
end

function ShipLogic:CheckLevelUpByItem(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local level = heroInfo.Lvl
  local shipCountry = Logic.shipLogic:GetHeroCountryBySMId(heroInfo.TemplateId)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  local configAll = Logic.shipLogic:GetExpItemTable(level, shipCountry, shipType)
  if #configAll == 0 then
    return false
  end
  for i, v in ipairs(configAll) do
    local id = v.id
    local num = Logic.bagLogic:GetBagItemNum(id)
    if 0 < num then
      return true
    end
  end
  return false
end

function ShipLogic:CheckLevelUpMax(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if not heroInfo then
    return true
  end
  local level = heroInfo.Lvl
  local maxLevelHero = Logic.shipLogic:GetLevelMaxByHeroId(heroId)
  local levelMax = Logic.shipLogic:GetLevelMaxByAdvance(heroInfo.TemplateId)
  levelMax = math.min(levelMax, maxLevelHero)
  return level >= levelMax
end

function ShipLogic:CheckLevelUpMaxById(heroId, itemId)
  local config = configManager.GetDataById("config_ship_exp_item", itemId)
  if #config.level_limit == 0 then
    return true
  end
  local minLevel = config.level_limit[1]
  local maxLevel = config.level_limit[2]
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local level = heroInfo.Lvl
  if maxLevel < level or minLevel > level then
    return false
  end
  return true
end

function ShipLogic:GetHeroSFIdByTemplateId(templateId)
  local sm_config = configManager.GetDataById("config_ship_main", templateId)
  if sm_config then
    local si_config = configManager.GetDataById("config_ship_info", sm_config.ship_info_id)
    if si_config then
      return si_config.sf_id
    end
  end
  return nil
end

function ShipLogic.GetHeroAttrBuff(heroId, fleetType)
  local ret = {}
  fleetType = fleetType or FleetType.Normal
  local heroInfo = Data.heroData:GetHeroById(heroId)
  for k, v in pairs(heroInfo.PSKillLevelMap) do
    local skillInfo = configManager.GetDataById("config_pskill_dict_group", k)
    for i, effecId in ipairs(skillInfo.level_value_effect) do
      local valueEffect = configManager.GetDataById("config_value_effect", effecId)
      local power = ScriptManager:RunCmd(skillInfo.script_list[i], skillInfo.param_list[i], v)
      table.insert(ret, {
        power = power,
        values = valueEffect.values
      })
    end
  end
  local breakInfo = configManager.GetDataById("config_ship_break", heroInfo.TemplateId)
  for i, v in ipairs(breakInfo.value_effect_id_list) do
    local valueEffect = configManager.GetDataById("config_value_effect", v)
    table.insert(ret, {
      power = breakInfo.value_effect_power_list[i],
      values = valueEffect.values
    })
  end
  local shipMainInfo = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local lvconfig = configManager.GetDataById("config_ship_levelup", heroInfo.Lvl)
  local factor = lvconfig and lvconfig.attribute_level or 0
  for i, v in ipairs(shipMainInfo.level_value_effect) do
    local valueEffect = configManager.GetDataById("config_value_effect", v)
    if not valueEffect then
      logError(heroInfo.TemplateId, v, shipMainInfo.level_value_effect)
    end
    local power = ScriptManager:RunCmd(shipMainInfo.script_list[i], shipMainInfo.param_list[i], factor)
    table.insert(ret, {
      power = power,
      values = valueEffect.values
    })
  end
  local maxPowerName = "config_ship_max_power"
  local shipPowerInfo = configManager.GetDataById(maxPowerName, heroInfo.TemplateId)
  local lvlList = {}
  local insensifyLvl = {}
  for _, value in pairs(heroInfo.Intensify) do
    insensifyLvl[value.AttrType] = value.IntensifyLvl
  end
  for i, v in ipairs(shipPowerInfo.max_power_prop) do
    local prop = v[1]
    lvlList[i] = insensifyLvl[prop] or 0
  end
  for i, v in ipairs(shipPowerInfo.level_value_effect) do
    local valueEffect = configManager.GetDataById("config_value_effect", v)
    local power = ScriptManager:RunCmd(shipPowerInfo.script_list[i], shipPowerInfo.param_list[i], lvlList)
    table.insert(ret, {
      power = power,
      values = valueEffect.values
    })
  end
  local equips = Data.heroData:GetEquipsByType(heroInfo.HeroId, fleetType)
  local equipId
  for _, info in pairs(equips) do
    equipId = info.EquipsId
    if equipId ~= 0 then
      local equip = Logic.equipLogic:GetEquipById(equipId)
      if equip then
        for i, skill in ipairs(equip.PSkillList) do
          local skillInfo = configManager.GetDataById("config_pskill_dict_group", skill.PSkillId)
          for i, effecId in ipairs(skillInfo.level_value_effect) do
            local valueEffect = configManager.GetDataById("config_value_effect", effecId)
            local power = ScriptManager:RunCmd(skillInfo.script_list[i], skillInfo.param_list[i], skill.PSkillLv)
            table.insert(ret, {
              power = power,
              values = valueEffect.values
            })
          end
        end
      end
    end
  end
  return ret
end

function ShipLogic:GetShipFleetByHeroId(heroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(heroId)
  local sfConfig = configManager.GetDataById("config_ship_fleet", shipInfoConfig.sf_id)
  return sfConfig
end

function ShipLogic:DisposeSkillArr(skillAttr, heroId)
  local skillSerData = clone(Data.heroData:GetHeroById(heroId).PSkill)
  for i, skillId in ipairs(skillAttr) do
    if type(skillId) ~= "table" then
      for _, v in ipairs(skillSerData) do
        if v.PSkillId == skillId then
          v.inSkillAttr = true
        end
      end
    end
  end
  for _, v in ipairs(skillSerData) do
    if v.inSkillAttr == nil then
      table.insert(skillAttr, v.PSkillId)
    end
  end
  return skillAttr
end

function ShipLogic:SendHeroLockByType(heroId, bLock, hander)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local sf_id = Logic.shipLogic:GetHeroSFIdByTemplateId(shipInfo.TemplateId)
  local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
  if sf_config.lock_type == 1 and bLock == false then
    noticeManager:OpenTipPage(hander, 950000001)
    return
  else
    Service.heroService:SendHeroLock(heroId, bLock)
  end
end

function ShipLogic:GetReplaceSkillId(pSkillId, heroId)
  local skillSerData = Data.heroData:GetHeroById(heroId).PSkill
  for _, v in ipairs(skillSerData) do
    if v.PSkillId == pSkillId and v.Replace ~= 0 then
      return v.Replace
    end
  end
  return pSkillId
end

function ShipLogic:SameCharacterHeroInBuilding(heroId, sfid)
  local _, cachBuildingFids, _ = self:GetSCFidsForBOB()
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local sf_id = self:GetShipUniqueIdById(heroId)
    for cachesf_id, cache_heroid in pairs(cachBuildingFids) do
      local isSameShip = Logic.shipLogic:CheckSameShipCharacterBySfid(sf_id, cachesf_id)
      if isSameShip then
        return true, sf_id, cachesf_id, cache_heroid
      end
    end
    return false, 0, 0, 0
  else
    return false, 0, 0, 0
  end
end

function ShipLogic:SameCharacterHeroInOutPosting(heroId, sfid)
  local _, _, cachOutpostFids = self:GetSCFidsForBOB()
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local sf_id = self:GetShipUniqueIdById(heroId)
    for cachesf_id, _ in pairs(cachOutpostFids) do
      local isSameShip = Logic.shipLogic:CheckSameShipCharacterBySfid(sf_id, cachesf_id)
      if isSameShip then
        return true, sf_id, cachesf_id
      end
    end
    return false, 0, 0
  else
    return false, 0, 0
  end
end

function ShipLogic:SameCharacterHeroInBathing(heroId, sfid)
  local cachBathFids, _, _ = self:GetSCFidsForBOB()
  local heroData = Data.heroData:GetHeroById(heroId)
  if heroData then
    local sf_id = self:GetShipUniqueIdById(heroId)
    for cachesf_id, _ in pairs(cachBathFids) do
      local isSameShip = Logic.shipLogic:CheckSameShipCharacterBySfid(sf_id, cachesf_id)
      if isSameShip then
        return true, sf_id, cachesf_id
      end
    end
    return false, 0, 0
  else
    return false, 0, 0
  end
end

function ShipLogic:GetSCFidsForBOB()
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local cachBathFids = Logic.buildingLogic:GetHeroUniqueTids(bathHero)
  local buildingHero = Data.buildingData:GetBuildingHero()
  local cachBuildingFids = Logic.buildingLogic:GetHeroUniqueTids(buildingHero)
  local outpostHero = Data.mubarOutpostData:GetOutPostHeroData()
  local cachOutpostFids = Logic.buildingLogic:GetHeroUniqueTids(outpostHero)
  return cachBathFids, cachBuildingFids, cachOutpostFids
end

function ShipLogic:CheckSameShipCharacterByTID(idA, idB)
  local si_idA = self:GetShipInfoId(idA)
  local si_idB = self:GetShipInfoId(idB)
  local sf_idA = self:GetShipFleetId(si_idA)
  local sf_idB = self:GetShipFleetId(si_idB)
  return self:CheckSameShipCharacterBySfid(sf_idA, sf_idB)
end

function ShipLogic:CheckSameShipCharacterBySfid(sf_idA, sf_idB)
  local sf_configA = configManager.GetDataById("config_ship_fleet", sf_idA)
  for _, asid in pairs(sf_configA.same_character) do
    if asid == sf_idB then
      return true
    end
  end
  return false
end

function ShipLogic:CheckShipCanCombine(heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local fleetId = heroInfo.fleetId
  return configManager.GetDataById("config_ship_fleet", fleetId).combination_open == 1
end

function ShipLogic:CheckShipCanCombineBySs_id(ss_Id)
  local fleetId = configManager.GetDataById("config_ship_show", ss_Id).sf_id
  return configManager.GetDataById("config_ship_fleet", fleetId).combination_open == 1
end

function ShipLogic:GetShipMaxBreakLv(si_id)
  if self.m_shipBreakMaxLv[si_id] == nil then
    return 0
  end
  return self.m_shipBreakMaxLv[si_id]
end

function ShipLogic:GetShipMaxBreakLvBySMId(sm_id)
  local smCfg = configManager.GetDataById("config_ship_main", sm_id)
  if smCfg == nil then
    return 0
  end
  return self:GetShipMaxBreakLv(smCfg.ship_info_id)
end

function ShipLogic:GetShipMaxLv()
  return configManager.GetDataById("config_parameter", 70).value
end

function ShipLogic:ResetConsumeBreakItemMubo()
  self.tabSelectBreakItemMubo = {}
end

function ShipLogic:SetConsumeBreakItemMubo(tabSelectItem)
  self.tabSelectBreakItemMubo = tabSelectItem
end

function ShipLogic:GetConsumeBreakItemMubo()
  return self.tabSelectBreakItemMubo
end

return ShipLogic
