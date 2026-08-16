ScriptManager = {}
ScriptManager = class("ScriptManager")
require("config.ClientScript.ScriptInit")

function ScriptManager:RunCmdWithArray(funcname, args, datas)
  local f = _G[funcname]
  if f == nil then
    logError("not find funcion name = " .. tostring(funcname))
    return 0
  end
  return f(self, args, datas)
end

function ScriptManager:RunCmd(funcname, args, ...)
  local f = _G[funcname]
  if f == nil then
    logError("not find funcion name = " .. tostring(funcname))
    return 0
  end
  return f(self, args, ...)
end

function ScriptManager:GetLevel()
  return Data.userData:GetLevel()
end

function ScriptManager:GetVipLevel()
  return Data.userData:GetVipLevel()
end

function ScriptManager:GetCurrency(curid)
  return Data.userData:GetCurrency(curid)
end

function ScriptManager:GetPower()
  return Data.userData:GetPower()
end

function ScriptManager:GetCreateDay()
  return PeriodManager:GetDaysFromTime(Data.userData:GetCreateTime())
end

function ScriptManager:GetSvrStartDay()
  return PeriodManager:GetSvrStartDay()
end

function ScriptManager:GetAdvanceByHeroId(heroId)
  return Data.heroData:GetHeroById(heroId).Advance
end

function ScriptManager:GetLevelByHeroId(heroId)
  return Data.heroData:GetHeroById(heroId).Lvl
end

function ScriptManager:GetTypeByHeroId(heroId)
  return Logic.shipLogic:GetHeroTypeByHeroId(heroId)
end

function ScriptManager:GetTagByHeroId(heroId)
  return Logic.shipLogic:GetHeroTagByHeroId(heroId)
end

function ScriptManager:GetInfoIdByHeroId(heroId)
  return Logic.shipLogic:GetInfoIdByHeroId(heroId)
end

function ScriptManager:GetQualityByHeroId(heroId)
  return Logic.shipLogic:GetQualityByHeroId(heroId)
end

function ScriptManager:GetCountryByHeroId(heroId)
  return Data.heroData:GetHeroById(heroId).shipCountry
end

function ScriptManager:GetTemplateIdByHeroId(heroId)
  return Data.heroData:GetHeroById(heroId).TemplateId
end

function ScriptManager:GetTowerLevel()
  return Data.towerData:GetMaxLevel() or 0
end

function ScriptManager:GetEquipTableByHeroId(heroId)
  local result = {}
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if heroInfo == nil then
    logError("Data.heroData:GetHeroById err. heroId:" .. heroId)
    return result
  end
  return heroInfo.Equips
end

function ScriptManager:GetAssistFleetSupportId(copyId)
  return 0
end

function ScriptManager:GetCopyPassLock(copyId)
  return Logic.copyLogic:IsCopyPassById(copyId)
end

function ScriptManager:IsPassLBCopy(copyType, copyId)
  local info = Logic.copyLogic:GetCopyData(copyType, copyId)
  if info == nil then
    return false
  end
  return info.LBPoint >= 10000
end

function ScriptManager:GetAssistFleetShip(copyId)
  return {}
end

function ScriptManager:GetShipTableByFleet(fleetId, typ)
  local imageFleetShip = Logic.fleetLogic:GetImageFleetShip(fleetId, typ)
  if typ == FleetType.Preset then
    local presetFleetShipList = Logic.presetFleetLogic:GetPresetFleetShip(fleetId, typ)
    return presetFleetShipList
  end
  if imageFleetShip then
    return imageFleetShip.heroInfo
  else
    return Logic.fleetLogic:GetShipTableByFleet(fleetId, typ)
  end
end

function ScriptManager:GetStrategyIdInBattle()
  return 0
end

function ScriptManager:GetHeroListInBattle()
  local result = {}
  return result
end

function ScriptManager:GetAccRecharge()
  return Data.rechargeData:GetAccRecharge()
end

function ScriptManager:GetAccRechargeRmb()
  return Data.rechargeData:GetAccRechargeRmb()
end

function ScriptManager:GetBagItemsNumById(goodId)
  return Data.bagData:GetItemNum(goodId)
end

function ScriptManager:CheckBigMonthCard()
  return Logic.userLogic:CheckBigMonthCardPrivilege()
end

function ScriptManager:Debug(...)
  logDebug(...)
end

function ScriptManager:Error(...)
  logError(...)
end
