local ConditionCheckHelper = class("Game.Guide.ConditionCheckHelper")

function ConditionCheckHelper.isMeetCondition(nConditionId, objParam, bOpposite)
  if nConditionId == nil or nConditionId == 0 then
    return true
  end
  local checkFunc = ConditionCheckHelper.tabConditionToFunc[nConditionId]
  local bOriResult = checkFunc(objParam)
  if bOpposite then
    return not bOriResult
  else
    return bOriResult
  end
end

function ConditionCheckHelper.__HaveNShip()
  local result = Logic.shipLogic:CheckHaveNShip()
  return result
end

function ConditionCheckHelper.__FlagChangeEquip()
  local result = Logic.shipLogic:CheckFlagShipEquip()
  return result
end

function ConditionCheckHelper.__NoneStudy()
  local result = Logic.studyLogic:CheckCanStudy()
  return result
end

function ConditionCheckHelper.__OneStudyFinish()
  local result = Logic.studyLogic:CheckOneFinish()
  return result
end

function ConditionCheckHelper.__TwoStudyFinish()
  local result = Logic.studyLogic:CheckTwoFinish()
  return result
end

function ConditionCheckHelper.__NoneStudyFinish()
  local result = Logic.studyLogic:CheckNoneFinish()
  return result
end

function ConditionCheckHelper.__BagNoneShowUse()
  local result = Logic.bagLogic:CheckUseEquipOff()
  return result
end

function ConditionCheckHelper.__BagShowUse()
  local result = Logic.bagLogic:CheckUseEquipOff()
  return not result
end

function ConditionCheckHelper.__SelectShipSortUp()
  local result = Logic.selectedShipPageLogic:GetShipSort()
  return not result
end

function ConditionCheckHelper.__SelectShipSortDown()
  local result = Logic.selectedShipPageLogic:GetShipSort()
  return result
end

function ConditionCheckHelper.__OperateRudder()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return objOperate == 0
end

function ConditionCheckHelper.__OperateLeftRight()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return objOperate == 1
end

function ConditionCheckHelper.__CheckNShipNoIntensify()
  local result = Logic.dockLogic:CheckIntensify()
  return result
end

function ConditionCheckHelper.__CheckNShipIntensify()
  local result = Logic.dockLogic:CheckIntensify()
  return not result
end

function ConditionCheckHelper.__LastBattleCanAccord()
  return GR.luaInteraction:getFpsCounterAccord(FPSCheckParam.name, FPSCheckParam.lowFPSCount, FPSCheckParam.average)
end

function ConditionCheckHelper.__LastBattleCanNotAccord()
  return not GR.luaInteraction:getFpsCounterAccord(FPSCheckParam.name, FPSCheckParam.lowFPSCount, FPSCheckParam.average)
end

function ConditionCheckHelper.__GoodsNotEnough(param)
  return not conditionCheckManager:CheckGoodsEnough(param)
end

function ConditionCheckHelper.__PassCopy(nCopyId)
  local bPass = Logic.copyLogic:IsCopyPassById(nCopyId)
  return bPass
end

function ConditionCheckHelper.__NotPassCopy(nCopyId)
  local bPass = Logic.copyLogic:IsCopyPassById(nCopyId)
  return not bPass
end

function ConditionCheckHelper.__IsSecretySame(targetId)
  if Data.userData == nil then
    return false
  end
  local nSecretaryId = Data.userData:GetSecretaryId()
  local nShipMainId = Data.heroData:GetHeroById(nSecretaryId).TemplateId
  local tblShipMain = configManager.GetDataById("config_ship_main", nShipMainId)
  local nShipInfoId = tblShipMain.ship_info_id
  return nShipInfoId == targetId
end

function ConditionCheckHelper.__getFleetShipCount(tblParam)
  local nTargetNum = 0
  local nNeedNum = 0
  local bNeedCheck = false
  local strType = type(tblParam)
  if strType == "number" then
    nTargetNum = tblParam
  elseif strType == "table" then
    bNeedCheck = true
    nTargetNum = tblParam[1]
    nNeedNum = tblParam[2]
  end
  local tblShipList = Data.fleetData:GetShipByFleet(1)
  local nCount = GetTableLength(tblShipList)
  local curFreeNum = Logic.fleetLogic:CanAddFleetHeroNum()
  if nTargetNum <= nCount then
    return true
  end
  if nTargetNum > nCount + curFreeNum then
    return true
  end
end

function ConditionCheckHelper.__getChangeNameTime(nTargetNum)
  local nChangeTime = Data.userData:ChangeNameTimes()
  return nTargetNum <= nChangeTime
end

function ConditionCheckHelper.__GuideEvent(objParam, bOpposite)
  local nEventType = objParam[1]
  local objEventParam = objParam[2]
  local serviceEventData = Data.guideData:GetGuideEvent()
  local param = serviceEventData[nEventType]
  local bResult = false
  if param ~= nil and objEventParam <= param then
    bResult = true
  end
  if bOpposite then
    bResult = not bResult
  end
  return bResult
end

function ConditionCheckHelper.__IsBattleAuto()
  return GR.luaInteraction:getBattleAuto()
end

function ConditionCheckHelper.__IsBattleNotAuto()
  return not GR.luaInteraction:getBattleAuto()
end

function ConditionCheckHelper.__IsWindowsRudder()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return isWindows and objOperate == 0
end

function ConditionCheckHelper.__IsWindowsLeftRight()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return isWindows and objOperate == 1
end

function ConditionCheckHelper.__IsPhoneRudder()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return not isWindows and objOperate == 0
end

function ConditionCheckHelper.__IsPhoneLeftRight()
  local objOperate = CacheUtil.GetBattleRotationOpe()
  return not isWindows and objOperate == 1
end

function ConditionCheckHelper.__IsWindows()
  return isWindows
end

function ConditionCheckHelper.__IsPhone()
  return not isWindows
end

function ConditionCheckHelper.__IsOaklandEquipBlue(nEquipTId)
  local bHaveUnEquipItem = false
  local equipData = Data.equipData:GetEquipData()
  for k, v in pairs(equipData) do
    local nHeroId = v.HeroId
    local nTemplateId = v.TemplateId
    if nHeroId ~= nil and nHeroId ~= 0 then
      local equipConfig = configManager.GetDataById("config_equip", nTemplateId)
      if equipConfig.quality >= 2 then
        local tid = Data.heroData:GetHeroById(nHeroId).TemplateId
        local shipInfoId = Logic.shipLogic:GetShipInfoIdByTid(tid)
        local nShipFleetId = Logic.shipLogic:GetShipFleetId(shipInfoId)
        if nShipFleetId == 1021051 then
          return true
        end
      end
    elseif nEquipTId ~= nil and nTemplateId == nEquipTId then
      bHaveUnEquipItem = true
    end
  end
  return not bHaveUnEquipItem
end

function ConditionCheckHelper.__HaveEquipRised()
  local tblEquips = Data.equipData:GetEquipData()
  for k, v in pairs(tblEquips) do
    if v.Star > 0 then
      return true
    end
  end
  return false
end

function ConditionCheckHelper.__EquipEnhaceLv(tblParam)
  local strType = type(tblParam)
  local bCheckResources = false
  local nTargetLv
  if strType == "number" then
    nTargetLv = tblParam
  elseif strType == "table" then
    nTargetLv = tblParam[1]
    bCheckResources = true
  end
  local tblEquips = Data.equipData:GetEquipData()
  for k, v in pairs(tblEquips) do
    if nTargetLv <= v.EnhanceLv then
      return true
    end
  end
  if bCheckResources then
    local tblParam = tblParam[2]
    return ConditionCheckHelper.__GoodsNotEnough(tblParam)
  end
  return false
end

function ConditionCheckHelper.__IntensifyRawCheck(nTemplateId)
  local nHaveNum = Data.heroData:GetHeroCountByTemplateId(nTemplateId)
  if nHaveNum <= 0 then
    return true
  end
  local tblHeroDatas = Data.heroData:GetHeroData()
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
    return v.TemplateId == nTemplateId and fleetMap[id] == nil and not v.Lock and not Logic.shipLogic:IsInCrusade(id) and arrProgressSet[id] == nil and secretaryId ~= id and bathHero[id] == nil and v.Lvl == 1 and v.quality == 1 and #v.Intensify == 0 and 1 >= v.Advance
  end
  for k, v in pairs(tblHeroDatas) do
    local bCanRaw = filterFunc(v)
    if bCanRaw then
      return false
    end
  end
  return true
end

function ConditionCheckHelper.__OaklandBreakCheck()
  local tblAllHeros = Data.heroData:GetHeroData()
  for k, v in pairs(tblAllHeros) do
    local tid = v.TemplateId
    local shipInfoId = Logic.shipLogic:GetShipInfoIdByTid(tid)
    local nShipFleetId = Logic.shipLogic:GetShipFleetId(shipInfoId)
    if nShipFleetId == 1021051 then
      if v.Lvl < 5 then
        return true
      end
      if v.Advance > 1 then
        return true
      end
    end
  end
end

function ConditionCheckHelper.__PageOpen(strPageName)
  return UIHelper.IsPageOpen(strPageName)
end

function ConditionCheckHelper.__PageNotOpen(strPageName)
  return not UIHelper.IsPageOpen(strPageName)
end

function ConditionCheckHelper.__BuildLandCannotBuild(tblParam)
  local nIndex = tblParam[1]
  local nBuildType = tblParam[2]
  if Data == nil then
    return true
  end
  local tblBuildingData = Data.buildingData
  if tblBuildingData == nil then
    return true
  end
  local tblOneBuildingData, bHaveBuilding = tblBuildingData:GetBuildingByIndex(nIndex)
  if bHaveBuilding then
    return true
  end
  for i = 2, 10 do
    tblOneBuildingData, bHaveBuilding = tblBuildingData:GetBuildingByIndex(i)
    if tblOneBuildingData ~= nil then
      local nTid = tblOneBuildingData.Tid
      local nBuildingType = tblBuildingData:_getBuildType(nTid)
      if nBuildingType == nBuildType then
        return true
      end
    end
  end
  local tblConfig = configManager.GetData("config_buildinginfo")
  local nTid
  for k, v in pairs(tblConfig) do
    if v.type == nBuildType and v.level == 1 then
      nTid = v.id
      break
    end
  end
  if nTid == nil then
    logError("cannot find Type " .. tostring(nBuildType))
    return true
  end
  local strResult = Logic.buildingLogic:CheckUpgradeCost(nTid, 1)
  return strResult ~= nil
end

function ConditionCheckHelper.__SpecifiedBuildingHaveGirl(nBuildType)
  if Data == nil then
    return true
  end
  local tblBuildingData = Data.buildingData
  if tblBuildingData == nil then
    return true
  end
  local tblOneBuildingData, bHaveBuilding = tblBuildingData:GetBuildingByIndex(nBuildType)
  if not bHaveBuilding then
    return true
  end
  local objGirl = next(tblOneBuildingData.HeroList)
  if objGirl ~= nil then
    return true
  end
  return false
end

function ConditionCheckHelper.__ItemFactoryCanNotProducte(tblParam)
  local nRecipeId = tblParam[1]
  local nCount = tblParam[2]
  local strResult = Logic.buildingLogic:CheckProduceItemCost(nRecipeId, nCount)
  return strResult ~= nil
end

function ConditionCheckHelper.__FunctionOpen(nFuncId)
  local nFuncId = nFuncId
  return moduleManager:CheckFunc(nFuncId, false)
end

function ConditionCheckHelper.__FunctionNotOpen(nFuncId)
  local nFuncId = nFuncId
  return not moduleManager:CheckFunc(nFuncId, false)
end

function ConditionCheckHelper.__FleetHaveShip()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  return isHasFleet
end

function ConditionCheckHelper.__FleetDontHaveShip()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  return not isHasFleet
end

function ConditionCheckHelper.__DontHaveShipOrPassCopy()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    return true
  end
  local bPass = Logic.copyLogic:IsCopyPassById(1600100)
  return bPass
end

ConditionCheckHelper.tabConditionToFunc = {
  [GUIDE_CONDITION.HAVE_N_SHIP] = ConditionCheckHelper.__HaveNShip,
  [GUIDE_CONDITION.FLAG_CHANGE_EQUIP] = ConditionCheckHelper.__FlagChangeEquip,
  [GUIDE_CONDITION.NONE_STUDY] = ConditionCheckHelper.__NoneStudy,
  [GUIDE_CONDITION.ONE_STUDY_FINISH] = ConditionCheckHelper.__OneStudyFinish,
  [GUIDE_CONDITION.TWO_STUDY_FINISH] = ConditionCheckHelper.__TwoStudyFinish,
  [GUIDE_CONDITION.NONE_STUDY_FINISH] = ConditionCheckHelper.__NoneStudyFinish,
  [GUIDE_CONDITION.BAG_SHOW_USE] = ConditionCheckHelper.__BagShowUse,
  [GUIDE_CONDITION.SELECT_SHIP_SORT_UP] = ConditionCheckHelper.__SelectShipSortUp,
  [GUIDE_CONDITION.BAG_NONE_SHOW_USE] = ConditionCheckHelper.__BagNoneShowUse,
  [GUIDE_CONDITION.SELECT_SHIP_SORT_DOWN] = ConditionCheckHelper.__SelectShipSortDown,
  [GUIDE_CONDITION.OPERATE_RUDDER] = ConditionCheckHelper.__OperateRudder,
  [GUIDE_CONDITION.OPERATE_LEFT_RIGHT] = ConditionCheckHelper.__OperateLeftRight,
  [GUIDE_CONDITION.N_SHIP_NO_INTENSIFY] = ConditionCheckHelper.__CheckNShipNoIntensify,
  [GUIDE_CONDITION.N_SHIP_INTENSIFY] = ConditionCheckHelper.__CheckNShipIntensify,
  [GUIDE_CONDITION.BattleFpsCanAccord] = ConditionCheckHelper.__LastBattleCanAccord,
  [GUIDE_CONDITION.BattleFpsCannotAccord] = ConditionCheckHelper.__LastBattleCanNotAccord,
  [GUIDE_CONDITION.GuideEvent] = ConditionCheckHelper.__GuideEvent,
  [GUIDE_CONDITION.PassCopy] = ConditionCheckHelper.__PassCopy,
  [GUIDE_CONDITION.SecretaryId] = ConditionCheckHelper.__IsSecretySame,
  [GUIDE_CONDITION.GoodsNotEnough] = ConditionCheckHelper.__GoodsNotEnough,
  [GUIDE_CONDITION.ShipInBattle] = ConditionCheckHelper.__getFleetShipCount,
  [GUIDE_CONDITION.ChangeNameTime] = ConditionCheckHelper.__getChangeNameTime,
  [GUIDE_CONDITION.BattleAuto] = ConditionCheckHelper.__IsBattleAuto,
  [GUIDE_CONDITION.BattleNotAuto] = ConditionCheckHelper.__IsBattleNotAuto,
  [GUIDE_CONDITION.Windows_Rudder] = ConditionCheckHelper.__IsWindowsRudder,
  [GUIDE_CONDITION.Windows_Left_Right] = ConditionCheckHelper.__IsWindowsLeftRight,
  [GUIDE_CONDITION.Phone_Left_Right] = ConditionCheckHelper.__IsPhoneLeftRight,
  [GUIDE_CONDITION.Phone_Rudder] = ConditionCheckHelper.__IsPhoneRudder,
  [GUIDE_CONDITION.IsWindows] = ConditionCheckHelper.__IsWindows,
  [GUIDE_CONDITION.IsPhone] = ConditionCheckHelper.__IsPhone,
  [GUIDE_CONDITION.OaklandEquipBlue] = ConditionCheckHelper.__IsOaklandEquipBlue,
  [GUIDE_CONDITION.HaveEquipRised] = ConditionCheckHelper.__HaveEquipRised,
  [GUIDE_CONDITION.EquipEnhaceLv] = ConditionCheckHelper.__EquipEnhaceLv,
  [GUIDE_CONDITION.IntensifyRawCheck] = ConditionCheckHelper.__IntensifyRawCheck,
  [GUIDE_CONDITION.OaklandBreakCheck] = ConditionCheckHelper.__OaklandBreakCheck,
  [GUIDE_CONDITION.PageOpen] = ConditionCheckHelper.__PageOpen,
  [GUIDE_CONDITION.PageNotOpen] = ConditionCheckHelper.__PageNotOpen,
  [GUIDE_CONDITION.BuildLandCannotBuild] = ConditionCheckHelper.__BuildLandCannotBuild,
  [GUIDE_CONDITION.SpecifiedBuildingHaveGirl] = ConditionCheckHelper.__SpecifiedBuildingHaveGirl,
  [GUIDE_CONDITION.ItemFactoryCanNotProducte] = ConditionCheckHelper.__ItemFactoryCanNotProducte,
  [GUIDE_CONDITION.FunctionOpen] = ConditionCheckHelper.__FunctionOpen,
  [GUIDE_CONDITION.FunctionNotOpen] = ConditionCheckHelper.__FunctionNotOpen,
  [GUIDE_CONDITION.FleetHaveShip] = ConditionCheckHelper.__FleetHaveShip,
  [GUIDE_CONDITION.FleetDontHaveShip] = ConditionCheckHelper.__FleetDontHaveShip,
  [GUIDE_CONDITION.NotPassCopy] = ConditionCheckHelper.__NotPassCopy,
  [GUIDE_CONDITION.DontHaveShipOrPassCopy] = ConditionCheckHelper.__DontHaveShipOrPassCopy
}
return ConditionCheckHelper
