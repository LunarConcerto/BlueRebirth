local AttrLogic = class("logic.AttrLogic.AttrLogic")
local HeroAttr = require("logic.AttrLogic.HeroAttr")
local PERCENT_VALUE = 0
local PERCENT_BASE = 10000
local ATTACK_GRADE_PARAM = 176
local AttackAttr = {
  AttrType.ATTACK,
  AttrType.TORPEDO_ATTACK,
  AttrType.SHIP_BOMB_ATTACK,
  AttrType.SHIP_AIR_CONTROL
}
local EquipAttackAttr = {
  AttrType.ATTACK,
  AttrType.TORPEDO_ATTACK,
  AttrType.SHIP_AIR_CONTROL,
  AttrType.PLANE_BOMB,
  AttrType.PLANE_TORPEDO
}
local SurviveAttr = {
  AttrType.HP,
  AttrType.DEFENSE,
  AttrType.TORPEDO_DEFENSE,
  AttrType.TO_AIR_ATTACK,
  AttrType.SPEED
}
local AddBuffFuns = {
  [1] = Logic.bathroomLogic.GetBathAttrBuff,
  [2] = Logic.marryLogic.GetMarryAttrBuff,
  [3] = Logic.shipLogic.GetHeroAttrBuff,
  [4] = Logic.shipCombinationLogic.GetCombineAttrBuff
}

function AttrLogic:initialize()
  self:RegisterAllEvent()
  self.AttrDic = {}
  self.AttrProp = nil
  self.heroMap = {}
end

function AttrLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.HERO_TryInitHeroExData, self._TryInitHeroExData, self)
  eventManager:RegisterEvent(LuaEvent.HERO_TryUpdateHeroExData, self._TryUpdateHeroExData, self)
end

function AttrLogic:_TryInitHeroExData()
  local heros = Data.heroData:GetHeroData()
  for id, hero in pairs(heros) do
    if hero then
      self:HeroBattlePower(id)
    end
  end
end

function AttrLogic:_TryUpdateHeroExData(heroId)
  if self:_canUpHeroExData() then
    local hero = Data.heroData:GetHeroById(heroId)
    if hero then
      self:_ResetAttrObj(heroId)
      self:_RecalBattlePower(heroId)
    end
  end
end

function AttrLogic:_canUpHeroExData()
  return Data.heroData:IsSetData() and Data.equipData:IsSetData()
end

function AttrLogic:GetHeroAttr(heroInfo, fleetType, copyId)
  fleetType = fleetType or FleetType.Normal
  local attr = self.AttrDic[heroInfo.HeroId]
  local copyKey = copyId and copyId or "Common"
  if attr and attr[fleetType] and attr[fleetType][copyKey] then
    return attr[fleetType][copyKey]
  elseif attr and attr[fleetType] then
    attr[fleetType][copyKey] = HeroAttr:new(heroInfo, fleetType, copyId)
    return attr[fleetType][copyKey]
  elseif attr then
    attr[fleetType] = {}
    attr[fleetType][copyKey] = HeroAttr:new(heroInfo, fleetType, copyId)
    return attr[fleetType][copyKey]
  else
    attr = {}
    attr[fleetType] = {}
    attr[fleetType][copyKey] = HeroAttr:new(heroInfo, fleetType, copyId)
    return attr[fleetType][copyKey]
  end
end

function AttrLogic:GetHeroFianlAttr(heroInfo, fleetType, copyId)
  fleetType = fleetType or FleetType.Normal
  if heroInfo.Attr and heroInfo.Attr[fleetType] then
    return heroInfo.Attr[fleetType]
  end
  local attrTemp = self:GetHeroAttr(heroInfo, fleetType, copyId)
  local finalAttr = attrTemp:GetFinalAttr()
  local attrBuffTab = {}
  for _, fun in ipairs(AddBuffFuns) do
    local heroAttrBuff = fun(heroInfo.HeroId, fleetType)
    attrBuffTab = self:DisposeAttrBuff(attrBuffTab, heroAttrBuff)
  end
  finalAttr = self:_addAttrBuff(finalAttr, attrBuffTab)
  local planeAttr = Logic.equipLogic:GetShipPlaneAttr(heroInfo.HeroId, fleetType)
  finalAttr[AttrType.FIGHTPLANE] = planeAttr[AttrType.FIGHTPLANE]
  finalAttr[AttrType.TORPEDOPLANE] = planeAttr[AttrType.TORPEDOPLANE]
  finalAttr[AttrType.BOMBPLANE] = planeAttr[AttrType.BOMBPLANE]
  local _, atkPower, _ = self:GetPowerFromAttr(heroInfo.HeroId, finalAttr)
  local paramInfo = configManager.GetDataById("config_parameter", ATTACK_GRADE_PARAM)
  finalAttr[AttrType.ATTACK_GRADE] = math.floor(paramInfo.value * 1.0 / PERCENT_BASE * atkPower)
  if heroInfo.Attr == nil then
    heroInfo.Attr = {}
  end
  heroInfo.Attr[fleetType] = finalAttr
  return finalAttr
end

function AttrLogic:GetHeroTalentAttr(heroInfo)
  local talentAttr = Data.talentData:GetTalentAttrBySMId(heroInfo.TemplateId)
  local _, atkPower, _ = self:GetPowerFromAttr(heroInfo.HeroId, talentAttr)
  local paramInfo = configManager.GetDataById("config_parameter", ATTACK_GRADE_PARAM)
  talentAttr[AttrType.ATTACK_GRADE] = math.floor(paramInfo.value * 1.0 / PERCENT_BASE * atkPower)
  return talentAttr
end

function AttrLogic:_handleTrainAdd(attr, heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local breakEff = Logic.shipLogic:GetBreakEffectList(heroInfo.TemplateId)
  local res = {}
  for k, v in pairs(attr) do
    res[k] = v
  end
  for _, effId in ipairs(breakEff) do
    res = self:_heroBreakAddImpl(res, effId)
  end
  return res
end

local function func(value, delta)
  return value + delta
end

local breakFuncMap = {
  [HeroBreakEffect.MAIN_GUN_SUB_4] = {
    func = func,
    attrType = AttrType.MAIN_GUN_CD,
    delta = -4000
  },
  [HeroBreakEffect.MIAN_GUN_SUB_5] = {
    func = func,
    attrType = AttrType.MAIN_GUN_CD,
    delta = -5000
  },
  [HeroBreakEffect.ADD_TORPEDO_1] = {
    func = func,
    attrType = AttrType.TORPEDO_NUM,
    delta = 1
  }
}

function AttrLogic:_heroBreakAddImpl(attr, effId, index)
  local temp = breakFuncMap[effId]
  if temp and attr[temp.attrType] then
    attr[temp.attrType] = temp.func(attr[temp.attrType], temp.delta)
  end
  return attr
end

function AttrLogic:GetHeroFianlAttrById(heroId, fleetType, copyId)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return self:GetNpcFinalAttrs(heroId)
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local attrs = self:GetHeroFianlAttr(heroInfo, fleetType, copyId)
  local talentAttr = self:GetHeroTalentAttr(heroInfo)
  local finalAttrs = clone(attrs)
  for k, v in pairs(talentAttr) do
    if finalAttrs[k] then
      finalAttrs[k] = finalAttrs[k] + v
    else
      finalAttrs[k] = v
    end
  end
  return finalAttrs
end

function AttrLogic:GetHeroEquipAttrById(heroId, fleetType)
  fleetType = fleetType or FleetType.Normal
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return npcAssistFleetMgr:GetNpcEquipAttrs(heroId)
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local attrTemp = self:GetHeroAttr(heroInfo, fleetType)
  return attrTemp:GetHeroEquipAttr()
end

function AttrLogic:GetHeroBasicAttrById(heroId)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return npcAssistFleetMgr:GetNpcBasicAttrs(heroId)
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local attrTemp = self:GetHeroAttr(heroInfo, nil)
  return attrTemp:GetHeroBasicAttr()
end

function AttrLogic:GetHeroFinalShowAttrById(heroId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local attr
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    attr = self:GetNpcFinalAttrs(heroId)
  else
    attr = self:GetCalFinalAttrs(heroId, fleetType)
  end
  local tabAttr = {}
  for k, v in pairs(attr) do
    local ok, value = self:_handleAttrShowValue(k, v, attr)
    if ok then
      tabAttr[k] = value or 0
    end
  end
  return tabAttr
end

function AttrLogic:GetHeroBaseAttrByTid(tid)
  local tabHeroInfo = configManager.GetDataById("config_ship_main", tid)
  local attr = {}
  local attrTbl = Logic.attrLogic:GetAttrTableShow()
  for k, v in pairs(attrTbl) do
    local attrString = Logic.attrLogic:GetAttrStringById(v)
    local temp = 0
    if tabHeroInfo[attrString] ~= nil then
      temp = tabHeroInfo[attrString]
      attr[v] = temp
    end
  end
  local tabAttr = {}
  for k, v in pairs(attr) do
    local ok, value = self:_handleAttrShowValue(k, v, attr)
    if ok then
      tabAttr[k] = value
    end
  end
  return tabAttr
end

function AttrLogic:GetCalFinalAttrs(heroId, fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local attrs = self:GetHeroFianlAttr(heroInfo, fleetType)
  local talentAttr = self:GetHeroTalentAttr(heroInfo)
  local finalAttrs = clone(attrs)
  for k, v in pairs(talentAttr) do
    if finalAttrs[k] then
      finalAttrs[k] = finalAttrs[k] + v
    else
      finalAttrs[k] = v
    end
  end
  return finalAttrs
end

function AttrLogic:GetNpcFinalAttrs(heroId)
  return npcAssistFleetMgr:GetNpcFinalAttrs(heroId)
end

function AttrLogic:_handleAttrShowValue(key, value, attr)
  if not self:CanShow(key) then
    return false, value
  end
  local tabConfig = configManager.GetDataById("config_attribute", key)
  if tabConfig and tabConfig.attr_display ~= "" then
    local params = clone(tabConfig.params)
    value = ScriptManager:RunCmd(tabConfig.attr_display, params, attr)
  end
  return true, value
end

function AttrLogic:CanShow(key)
  local attr = configManager.GetDataById("config_attribute", key, true)
  return attr and attr.girl_if_show ~= 0 or false
end

function AttrLogic:GetAttackGrade(heroId, fleetType)
  local attr = Logic.attrLogic:GetHeroFianlAttrById(heroId, fleetType)
  return attr[AttrType.ATTACK_GRADE]
end

function AttrLogic:UpdateAttr()
end

function AttrLogic:GetBattlePower(heroId, fleetType, copyId)
  if npcAssistFleetMgr:IsNpcHeroId(heroId) then
    return npcAssistFleetMgr:GetNpcShipById(heroId).BattlePower
  end
  local power = self:HeroBattlePower(heroId, fleetType, copyId)
  return math.floor(power)
end

function AttrLogic:DealTabProp(tabProp)
  local tabResult = {}
  for k, v in pairs(tabProp) do
    local attrconfig = configManager.GetDataById("config_attribute", k)
    local tabTemp = {}
    tabTemp.type = k
    tabTemp.num = v
    tabTemp.sort = attrconfig.direction_show_sort
    tabTemp.attr_direction = attrconfig.attr_direction
    if attrconfig.direction_if_show == 1 then
      tabResult[#tabResult + 1] = tabTemp
    end
  end
  table.sort(tabResult, function(data1, data2)
    return data1.sort < data2.sort
  end)
  return tabResult
end

function AttrLogic:AddBathAttr(heroInfo, finalAttr)
  local bathAttr = Logic.bathroomLogic:GetBathHeroAttr(heroInfo.HeroId)
  local tempAttr = bathAttr ~= nil and {} or finalAttr
  if bathAttr ~= nil then
    for k, v in pairs(finalAttr) do
      if bathAttr[k] ~= nil then
        tempAttr[k] = v + bathAttr[k]
      else
        tempAttr[k] = v
      end
    end
  end
  return tempAttr
end

function AttrLogic:DisposeAttrBuff(attrBuff, heroAttrBuff)
  if heroAttrBuff ~= nil then
    for _, v in pairs(heroAttrBuff) do
      local valueTab = string.split(v.values, "|")
      for _, i in pairs(valueTab) do
        local buff = string.split(i, ",")
        local attr = tonumber(buff[1])
        local value = tonumber(buff[2])
        local propInfo = configManager.GetDataById("config_prop", attr)
        if propInfo.prop_value_type == PERCENT_VALUE then
          value = math.floor(value * PERCENT_BASE)
        end
        value = value * math.floor(v.power)
        if not attrBuff[attr] then
          attrBuff[attr] = value
        else
          attrBuff[attr] = attrBuff[attr] + value
        end
      end
    end
  end
  return attrBuff
end

function AttrLogic:_addAttrBuff(finalAttr, attrBuffTab)
  local tempAttr = attrBuffTab or {}
  if finalAttr ~= nil then
    for k, v in pairs(finalAttr) do
      local tmp = tempAttr[k] or 0
      tempAttr[k] = tmp + v
    end
  end
  return tempAttr
end

function AttrLogic:GetPowerFromAttr(heroId, attrs)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if not heroInfo then
    return 0, 0, 0
  end
  local shipInfo = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  if not shipInfo then
    return 0, 0, 0
  end
  local shipType = shipInfo.ship_type2
  local atkBasePower = 0
  local atkPerPower = 0
  local defBasePower = 0
  local defPerPower = 0
  for attr, value in pairs(attrs) do
    local propInfo = configManager.GetDataById("config_prop", attr)
    if 0 < shipType and shipType <= #propInfo.attack_value then
      atkBasePower = atkBasePower + value * propInfo.attack_value[shipType]
    end
    if 0 < shipType and shipType <= #propInfo.attack_coefficient then
      atkPerPower = atkPerPower + value * 1.0 / PERCENT_BASE * propInfo.attack_coefficient[shipType]
    end
    if 0 < shipType and shipType <= #propInfo.defense_value then
      defBasePower = defBasePower + value * propInfo.defense_value[shipType]
    end
    if 0 < shipType and shipType <= #propInfo.defense_coefficient then
      defPerPower = defPerPower + value * 1.0 / PERCENT_BASE * propInfo.defense_coefficient[shipType]
    end
  end
  local atkPower = math.floor(atkBasePower * (1 + atkPerPower))
  local defPower = math.floor(defBasePower * (1 + defPerPower))
  local totalPower = atkPower + defPower
  return totalPower, atkPower, defPower
end

function AttrLogic:HeroBattlePower(heroId, fleetType, copyId)
  fleetType = fleetType or FleetType.Normal
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    return 0
  end
  if heroInfo.CombinationInfo and heroInfo.CombinationInfo.Combine and 0 < heroInfo.CombinationInfo.Combine then
    local combineHeroInfo = Data.heroData:GetHeroById(heroInfo.CombinationInfo.Combine)
    if combineHeroInfo == nil then
      return 0
    end
  end
  if heroInfo.Power and heroInfo.Power[fleetType] and not copyId then
    return heroInfo.Power[fleetType]
  end
  return self:_RecalBattlePower(heroId, fleetType, copyId)
end

function AttrLogic:_RecalBattlePower(heroId, fleetType, copyId)
  fleetType = fleetType or FleetType.Normal
  local hero = Data.heroData:GetHeroById(heroId)
  if hero then
    hero.Power = {}
    hero.Attr = {}
    local heroAttr = self:GetHeroFianlAttrById(heroId, fleetType, copyId)
    local totalPower, _, _ = self:GetPowerFromAttr(heroId, heroAttr)
    hero.Power[fleetType] = totalPower
    return totalPower
  end
  return 0
end

function AttrLogic:_ResetAttrObj(heroId)
  self.AttrDic[heroId] = {}
end

function AttrLogic:GetTotalAttackPower(heroAttr, equipAttr, coefficientTab, combatEffTab)
  combatEff = {
    [AttrType.ATTACK] = combatEffTab.attack,
    [AttrType.TORPEDO_ATTACK] = combatEffTab.torpedo_attack,
    [AttrType.SHIP_BOMB_ATTACK] = combatEffTab.ship_air_control,
    [AttrType.SHIP_AIR_CONTROL] = combatEffTab.ship_bomb_attack
  }
  local attackPowerTab = {}
  local attackPower = 0
  for _, v in ipairs(AttackAttr) do
    if heroAttr[v] ~= nil then
      local temp = heroAttr[v] * (coefficientTab[v] / 1000) * (combatEff[v] / 1000)
      attackPower = attackPower + temp
    end
  end
  local equipAttrTab = {}
  for _, v in ipairs(EquipAttackAttr) do
    if equipAttr[v] ~= nil then
      equipAttrTab[v] = equipAttr[v]
    else
      equipAttrTab[v] = 0
    end
  end
  local equipPower = 0
  for _, v in pairs(EquipAttackAttr) do
    if combatEff[v] ~= nil then
      local temp = equipAttrTab[v] * (combatEff[v] / 1000)
      equipPower = equipPower + temp
    end
  end
  equipPower = equipPower + (equipAttrTab[AttrType.PLANE_BOMB] + equipAttrTab[AttrType.PLANE_TORPEDO]) * (combatEff[AttrType.SHIP_AIR_CONTROL] / 1000)
  local heroHit = heroAttr[AttrType.HIT] ~= nil and heroAttr[AttrType.HIT] or 0
  local heroCrit = heroAttr[AttrType.CRIT] ~= nil and heroAttr[AttrType.CRIT] or 0
  local equipHit = equipAttr[AttrType.HIT] ~= nil and equipAttr[AttrType.HIT] or 0
  local equipCrit = heroAttr[AttrType.CRIT] ~= nil and heroAttr[AttrType.CRIT] or 0
  local totalBPower = (attackPower + equipPower) * (heroHit + heroCrit + equipHit + equipCrit) / 100
  return totalBPower
end

function AttrLogic:GetTotalSurvivePower(heroAttr, equipAttr, combatEffTab)
  combatEff = {
    [AttrType.HP] = combatEffTab.hp,
    [AttrType.DEFENSE] = combatEffTab.defense,
    [AttrType.TORPEDO_DEFENSE] = combatEffTab.torpedo_defense,
    [AttrType.TO_AIR_ATTACK] = combatEffTab.to_air_attack,
    [AttrType.SPEED] = combatEffTab.speed
  }
  local survivePowerTab = {}
  local heroSurvive = 0
  for _, v in ipairs(SurviveAttr) do
    if heroAttr[v] ~= nil then
      local temp = heroAttr[v] * (combatEff[v] / 1000)
      heroSurvive = heroSurvive + temp
    end
  end
  local equipSurviveTab = {}
  local equipSurvive = 0
  for _, v in ipairs(SurviveAttr) do
    if equipAttr[v] ~= nil then
      local temp = equipAttr[v] * (combatEff[v] / 1000)
      equipSurvive = equipSurvive + temp
    end
  end
  local heroDodge = heroAttr[AttrType.DODGE] ~= nil and heroAttr[AttrType.DODGE] or 0
  local heroAnticrit = heroAttr[AttrType.ANTICRIT] ~= nil and heroAttr[AttrType.ANTICRIT] or 0
  local equipDodge = equipAttr[AttrType.DODGE] ~= nil and equipAttr[AttrType.DODGE] or 0
  local equipAnticrit = equipAttr[AttrType.ANTICRIT] ~= nil and equipAttr[AttrType.ANTICRIT] or 0
  local totalSPower = (heroSurvive + equipSurvive) * (heroDodge + heroAnticrit + equipDodge + equipAnticrit) / 100 * (combatEffTab.survival_factor / 1000)
  return totalSPower
end

function AttrLogic:GetOtherPower(heroInfo)
  local advancePower = self:GetAdvancePower(heroInfo.Advance)
  local lvPower = self:GetLvPower(heroInfo.Lvl)
  local skillPower = self:GetSkillPower(heroInfo.HeroId, heroInfo.PSkill)
  local otherPower = advancePower + lvPower + skillPower
  return otherPower
end

function AttrLogic:GetBattleCoefficient(tId)
  local ret
  local shipInfo = configManager.GetDataById("config_ship_main", tId)
  if not shipInfo then
    return ret
  end
  ret = {
    [AttrType.ATTACK] = shipInfo.fire_coefficient,
    [AttrType.TORPEDO_ATTACK] = shipInfo.torpedo_coefficient,
    [AttrType.SHIP_BOMB_ATTACK] = shipInfo.attack_ship_coefficient,
    [AttrType.SHIP_AIR_CONTROL] = shipInfo.air_combat_coefficient
  }
  return ret
end

function AttrLogic:GetCombatEff(tId)
  local ret
  local shipInfo = configManager.GetDataById("config_ship_main", tId)
  if not shipInfo then
    return ret
  end
  local config = configManager.GetData("config_ship_combat_effectiveness")
  for _, v in ipairs(config) do
    if v.ship_type2 == shipInfo.ship_type2 then
      ret = v
      break
    end
  end
  return ret
end

function AttrLogic:GetAdvancePower(advance)
  local configId = 182 + advance
  local config = configManager.GetDataById("config_battle_config", configId)
  return config.data
end

function AttrLogic:GetLvPower(lv)
  local config = configManager.GetDataById("config_battle_config", 182)
  local power = config.data * lv
  return power
end

function AttrLogic:GetSkillPower(heroId, heroSkill)
  local config = configManager.GetDataById("config_battle_config", 190)
  local totalLv = 0
  for _, v in ipairs(heroSkill) do
    local temp = Logic.shipLogic:GetHeroPSkillLv(heroId, v.PSkillId)
    totalLv = totalLv + temp
  end
  local power = (totalLv - #heroSkill) * config.data
  return power
end

function AttrLogic:GetAttrShow(attrId, attrValue)
  local attrValueShow = string.gsub(tostring(attrValue), "%.0$", "")
  local prop = configManager.GetDataById("config_prop", tonumber(attrId))
  if prop.prop_value_type == 0 then
    return attrValueShow .. "%"
  end
  return attrValueShow
end

function AttrLogic:GetName(attr, tid)
  local name = configManager.GetDataById("config_attribute", attr).attr_name
  return name
end

function AttrLogic:DealTabPropNew(tabProp)
  local tabResult = {}
  for i = AttrTypeNew.Common, AttrTypeNew.Count - 1 do
    tabResult[i] = {}
  end
  for k, v in pairs(tabProp) do
    local attrconfig = configManager.GetDataById("config_attribute", k)
    local tabTemp = {}
    local attType = attrconfig.attr_type
    tabTemp.type = k
    tabTemp.num = v
    tabTemp.sort = attrconfig.girl_show_sort
    tabTemp.attr_direction = attrconfig.attr_direction
    table.insert(tabResult[attType], tabTemp)
  end
  for i = AttrTypeNew.Common, AttrTypeNew.Count - 1 do
    table.sort(tabResult[i], function(data1, data2)
      return data1.sort < data2.sort
    end)
  end
  return tabResult
end

function AttrLogic:DealTabPropDock(tabProp, heroId)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
  local attrList = shipInfo.attr_dock_show
  local tabResult = {}
  for index, k in ipairs(attrList) do
    local attrconfig = configManager.GetDataById("config_attribute", k)
    local tabTemp = {}
    tabTemp.type = k
    tabTemp.num = tabProp[k]
    tabTemp.sort = attrconfig.girl_show_sort
    tabTemp.attr_direction = attrconfig.attr_direction
    table.insert(tabResult, tabTemp)
  end
  return tabResult
end

function AttrLogic:GetAttrTableShow()
  local config = configManager.GetData("config_attribute")
  local result = {}
  for index, value in pairs(config) do
    if value.girl_if_show == 1 then
      table.insert(result, index)
    end
  end
  return result
end

function AttrLogic:GetAttrStringById(id)
  local config = configManager.GetDataById("config_attribute", id)
  return config.beizhu
end

function AttrLogic:GetHeroDataById(heroId)
  return self.heroMap[heroId]
end

function AttrLogic:GetAttrById(id, advance, lvl, skillLvl, advLv)
  local heroId = 10000000001
  local heroData = {}
  heroData.HeroId = heroId
  heroData.Advance = advance
  heroData.TemplateId = id
  local equipInfoType = {}
  local equip = {}
  for i = 1, 6 do
    equip[i] = {EquipsId = 0, state = 0}
  end
  equipInfoType[1] = equip
  heroData.Equips = equipInfoType
  heroData.Lvl = lvl
  heroData.PSkill = {}
  heroData.PSKillLevelMap = {}
  local shipMainConfig = configManager.GetDataById("config_ship_main", id)
  for i, v in ipairs(shipMainConfig.direct_activate_talent_id) do
    local skillData = {}
    skillData.PSkillId = v
    skillData.Level = skillLvl
    heroData.PSkill[i] = skillData
    heroData.PSKillLevelMap[v] = skillLvl
  end
  heroData.Intensify = {}
  heroData.AdvLv = advLv
  heroData.MarryTime = 0
  heroData.MarryType = 0
  heroData.IsFake = true
  heroData.Affection = 552500
  heroData.Mood = 1500000
  heroData.CurHp = 10000000000
  heroData.CombinationInfo = {
    ComLv = 0,
    ComGrade = 0,
    Combine = 0,
    BeCombined = 0
  }
  Data.heroData:_SetExtraInfo(heroData)
  self.heroMap[heroId] = heroData
  local attrs = self:GetHeroFianlAttr(heroData, FleetType.Normal)
  local finalAttrs = clone(attrs)
  local talentAttr = self:GetHeroTalentAttr(heroData)
  for k, v in pairs(talentAttr) do
    if finalAttrs[k] then
      finalAttrs[k] = finalAttrs[k] + v
    else
      finalAttrs[k] = v
    end
  end
  local tabAttr = {}
  for k, v in pairs(finalAttrs) do
    local ok, value = self:_handleAttrShowValue(k, v, finalAttrs)
    if ok then
      tabAttr[k] = value or 0
    end
  end
  return tabAttr
end

return AttrLogic
