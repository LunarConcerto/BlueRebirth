local Strengthen_PageLogic = class("logic.Strengthen_PageLogic")

function Strengthen_PageLogic:initialize()
  self:ResetData()
end

function Strengthen_PageLogic:ResetData()
  self.isFirstIn = true
end

function Strengthen_PageLogic:SetOpenRecord(isFirst)
  self.isFirst = isFirst
end

function Strengthen_PageLogic:GetOpenRecord()
  if self.isFirstIn then
    self.isFirstIn = false
    return false
  else
    return self.isFirst
  end
end

function Strengthen_PageLogic:ScreenShip(tabRemainShip, sm_id)
  local tabTemp = {}
  local type1 = self:GetIntensifyType(sm_id)
  local type2 = 0
  local typeCancel = self:IsTypeMatchCancel()
  local rSelect = self:IsRHeroSelect()
  local filter = function(hero, type)
    local typeOk, qualityUp = true, HeroRarityType.N
    if not typeCancel then
      typeOk = self:GetIntensifyType(hero.TemplateId) == type
    end
    if rSelect then
      qualityUp = HeroRarityType.R
    end
    return hero.Lvl == 1 and 1 >= hero.Advance and not Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(hero.HeroId) and #hero.Intensify == 0 and not Logic.shipLogic:IsInBuilding(hero.HeroId) and typeOk and qualityUp >= hero.quality
  end
  for k, v in pairs(tabRemainShip) do
    if filter(v, type1) then
      table.insert(tabTemp, v)
    end
  end
  table.sort(tabTemp, function(data1, data2)
    r = data1.HeroId < data2.HeroId
    return r
  end)
  return tabTemp
end

function Strengthen_PageLogic:GetIntensifyType(sm_id)
  return configManager.GetDataById("config_ship_need_power_exp", sm_id).enhance_type
end

function Strengthen_PageLogic:IsSameType(sm_id1, sm_id2)
  local type1 = self:GetIntensifyType(sm_id1)
  local type2 = self:GetIntensifyType(sm_id2)
  return type1 == type2
end

function Strengthen_PageLogic:GetPropName(tabHaveHero, tId)
  local tabChiName = {}
  if 0 < #tabHaveHero then
    local providePower = configManager.GetDataById("config_ship_provide_power_exp", tId).provide_power_exp
    for key, value in pairs(providePower) do
      local tabTemp = configManager.GetDataById("config_attribute", value[1])
      local temp = {}
      table.insert(temp, value[1])
      table.insert(temp, tabTemp.attr_name)
      tabChiName[key] = temp
    end
  end
  return tabChiName
end

function Strengthen_PageLogic:GetSelectHeroMax()
  return self:IsMoreSelect() and 12 or 6
end

function Strengthen_PageLogic:IsTypeMatchCancel()
  if not moduleManager:CheckFunc(FunctionID.HERO_Intensity_NoTypeMatch, false) then
    return false, false
  end
  local value = Data.guideData:GetSettingByKey("LOGIC_HERO_INTENSIFY_TypeMatchCancel")
  return value and Unserialize(value) or false, true
end

function Strengthen_PageLogic:IsRHeroSelect()
  if not moduleManager:CheckFunc(FunctionID.HERO_Intensity_AddRHero, false) then
    return false, false
  end
  local value = Data.guideData:GetSettingByKey("LOGIC_HERO_INTENSIFY_RHeroSelect")
  return value and Unserialize(value) or false, true
end

function Strengthen_PageLogic:IsMoreSelect()
  if not moduleManager:CheckFunc(FunctionID.HERO_Intensity_MORESELECT, false) then
    return false, false
  end
  local value = Data.guideData:GetSettingByKey("LOGIC_HERO_INTENSIFY_MORESELECT")
  return value and Unserialize(value) or false, true
end

function Strengthen_PageLogic:SetTypeMatchCancel(isOn)
  Service.guideService:SendUserSetting({
    {
      Key = "LOGIC_HERO_INTENSIFY_TypeMatchCancel",
      Value = tostring(isOn)
    }
  })
end

function Strengthen_PageLogic:SetRHeroSelect(isOn)
  Service.guideService:SendUserSetting({
    {
      Key = "LOGIC_HERO_INTENSIFY_RHeroSelect",
      Value = tostring(isOn)
    }
  })
end

function Strengthen_PageLogic:SetMoreSelect(isOn)
  Service.guideService:SendUserSetting({
    {
      Key = "LOGIC_HERO_INTENSIFY_MORESELECT",
      Value = tostring(isOn)
    }
  })
end

return Strengthen_PageLogic
