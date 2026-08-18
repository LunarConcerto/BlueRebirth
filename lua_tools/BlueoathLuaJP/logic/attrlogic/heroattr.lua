local HeroAttr = class("logic.AttrLogic.HeroAttr", require("logic.AttrLogic.Attr"))
local HeroBasicAttr = require("logic.AttrLogic.HeroBasicAttr")
local HeroEquipAttr = require("logic.AttrLogic.HeroEquipAttr")

function HeroAttr:initialize(heroInfo, fleetType, copyId)
  self.totalAttr = {}
  self.finalAttr = {}
  self:_GetHeroAttr(heroInfo.Lvl, heroInfo.TemplateId)
  self:_GetIntensify(heroInfo.Intensify)
  self:_GetRemould(heroInfo.ArrRemouldEffect)
  local equip = Data.heroData:GetEquipsByType(heroInfo.HeroId, fleetType)
  equip = self:_formatEquip(equip)
  local isNpc = npcAssistFleetMgr:IsNpcHeroId(heroInfo.HeroId)
  self:_GetEquipAttr(equip, isNpc, copyId)
  self:_GetCombineAttr(heroInfo)
  self:_GetFinalAttr()
end

function HeroAttr:_formatEquip(data)
  if data then
    local res = {}
    for _, info in pairs(data) do
      table.insert(res, info.EquipsId)
    end
    return res
  end
  return {}
end

function HeroAttr:_GetHeroAttr(lv, tId)
  self.basicAttr = HeroBasicAttr:new(lv, tId)
  self.totalAttr.basicAttr = self.basicAttr
end

function HeroAttr:_GetIntensify(intensifyArr)
  for _, attr in ipairs(intensifyArr) do
    self.basicAttr:AddAttr(self.basicAttr.attrDic, attr.AttrType, attr.IntensifyLvl)
  end
end

function HeroAttr:_GetCombineAttr(heroInfo)
  local combineData = heroInfo.CombinationInfo
  if combineData.Combine and combineData.Combine > 0 then
    local combHero = Data.heroData:GetHeroById(combineData.Combine)
    if combHero == nil then
      return
    end
    local otherCombineDate = Logic.shipCombinationLogic:GetCombineData(combineData.Combine)
    local baseProp, _ = Logic.shipCombinationLogic:GetCombAttrTab(combineData.Combine, otherCombineDate.ComLv)
    for _, propInfo in pairs(baseProp) do
      self.basicAttr:AddAttr(self.basicAttr.attrDic, propInfo[1], propInfo[2])
    end
  end
end

function HeroAttr:GetTalentAttr(heroInfo)
  local shipConfig = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local shipInfoCfg = configManager.GetDataById("config_ship_info", shipConfig.ship_info_id)
  local shipType = shipInfoCfg.ship_type
  local talentAttr = Data.talentData:GetTalentAttrByType(shipType)
  if talentAttr == nil then
    return
  end
  for k, v in pairs(talentAttr) do
    self.basicAttr:AddAttr(self.basicAttr.attrDic, k, v)
  end
end

function HeroAttr:_GetRemould(ArrRemouldEffect)
  local allAttr = Logic.remouldLogic:CountFinalAttr(ArrRemouldEffect)
  if allAttr == nil then
    return
  end
  for _, attr in ipairs(allAttr) do
    self.basicAttr:AddAttr(self.basicAttr.attrDic, attr[1], attr[2])
  end
end

function HeroAttr:_GetEquipAttr(equipArr, isNpc, copyId)
  self.equipAttr = HeroEquipAttr:new(equipArr, isNpc, copyId)
  self.totalAttr.equipAttr = self.equipAttr
end

function HeroAttr:_GetFinalAttr()
  self.finalAttr = {}
  for k, v in pairs(self.totalAttr) do
    for i, j in pairs(v.attrDic) do
      self:AddAttr(self.finalAttr, i, j)
    end
  end
end

function HeroAttr:GetHeroBasicAttr()
  return self.basicAttr.attrDic
end

function HeroAttr:GetHeroEquipAttr()
  return self.equipAttr.attrDic
end

function HeroAttr:GetFinalAttr()
  return self.finalAttr
end

return HeroAttr
