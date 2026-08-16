local SelectedShipPageLogic = class("logic.SelectedShipPageLogic")

function SelectedShipPageLogic:initialize()
  self.isShowProp = false
  self.sortway = true
  self.sortParam = {
    {},
    1
  }
  self.selectData = {}
end

function SelectedShipPageLogic:ResetData()
  self.isShowProp = false
  self.sortway = true
  self.sortParam = {
    {},
    1
  }
end

function SelectedShipPageLogic:SetSelectedData(selectedData)
  self.isShowProp = selectedData[1]
  self.sortway = selectedData[2]
  self.sortParam = selectedData[3]
end

function SelectedShipPageLogic:GetSelectedData()
  self.selectData[1] = self.isShowProp
  self.selectData[2] = self.sortway
  self.selectData[3] = self.sortParam
  return self.selectData
end

function SelectedShipPageLogic:Reset()
  self.selectedData = {}
end

function SelectedShipPageLogic:FilterHero(heroId, tabHaveShip)
  local fleetMap = Logic.fleetLogic:GetHeroFleetMap()
  local secretaryId = Data.userData:GetUserData().SecretaryId
  local bathHero = Data.bathroomData:GetBathHeroId()
  local arrProgress = Data.studyData:GetStudyData().ArrProgress
  local arrProgressSet = {}
  for _, v in ipairs(arrProgress) do
    arrProgressSet[v.HeroId] = 0
  end
  local filterFunc = function(v, k)
    local id = v.HeroId
    return heroId ~= id and not Logic.shipLogic:IsInFleet(id) and not v.Lock and not Logic.shipLogic:IsInCrusade(id) and arrProgressSet[id] == nil and secretaryId ~= id and bathHero[id] == nil
  end
  local tmp = {}
  for k, v in pairs(tabHaveShip) do
    tmp[k] = v
  end
  table.filter(tmp, filterFunc)
  local tabRemainHero = {}
  for _, v in pairs(tmp) do
    table.insert(tabRemainHero, v)
  end
  return tabRemainHero
end

function SelectedShipPageLogic:ConvertTabId(tabHeroId, tabHaveShip)
  local tabTemplateId = {}
  for key, value in pairs(tabHeroId) do
    for k, v in pairs(tabHaveShip) do
      if v.HeroId == value then
        table.insert(tabTemplateId, v.TemplateId)
        break
      end
    end
  end
  return tabTemplateId
end

function SelectedShipPageLogic:ConvertId(HeroId, tabShipInfo)
  local TemplateId
  for k, v in pairs(tabHaveShip) do
    if v.HeroId == HeroId then
      TemplateId = v.TemplateId
      break
    end
  end
  return TemplateId
end

function SelectedShipPageLogic:GetProp(selectHero, strengHero)
  local providePower = configManager.GetDataById("config_ship_provide_power_exp", selectHero).provide_power_exp
  local same = Logic.strengthen_PageLogic:IsSameType(selectHero, strengHero)
  if same then
    local factor = self:GetIntensifyFactor()
    local res = {}
    for index, table in ipairs(providePower) do
      res[index] = {
        table[1],
        table[2] * factor
      }
    end
    return res
  else
    return providePower
  end
end

function SelectedShipPageLogic:GetTotalExpNum(tabTemplateId, tabAttrName, sm_id)
  local tabTemp = {}
  local sum = 0
  local type1 = Logic.strengthen_PageLogic:GetIntensifyType(sm_id)
  local type2 = 0
  local factor = self:GetIntensifyFactor()
  local tempFactor = 1
  for m, n in pairs(tabAttrName) do
    for k, v in pairs(tabTemplateId) do
      type2 = Logic.strengthen_PageLogic:GetIntensifyType(v)
      tempFactor = type1 == type2 and factor or 1
      local providePower = configManager.GetDataById("config_ship_provide_power_exp", v).provide_power_exp
      for key, value in pairs(providePower) do
        if n[1] == value[1] then
          sum = Mathf.ToInt(sum + value[2] * tempFactor)
        end
      end
    end
    tabTemp[n[1]] = sum
    sum = 0
  end
  return tabTemp
end

function SelectedShipPageLogic:GetIntensifyFactor()
  return configManager.GetDataById("config_parameter", 110).value * 1.0E-4
end

function SelectedShipPageLogic:GetShipSort()
  local sortData = self:GetSelectedData()
  return sortData[2]
end

return SelectedShipPageLogic
