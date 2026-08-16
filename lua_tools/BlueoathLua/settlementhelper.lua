SettlementHelper = {}
local m = SettlementHelper
local g = _G
local rawget = rawget
local rawset = rawset
_ENV = setmetatable({}, {
  __index = function(t, k)
    return rawget(m, k) or rawget(g, k)
  end,
  __newindex = m
})
local HP_ACCURACY = 169
local heroCampCache = {}

function ReadOldToGenShipList(fleetId, fleetType)
  fleetType = fleetType or FleetType.Normal
  local shipList = {}
  local isNpcAssist = npcAssistFleetMgr:GetNpcAssist()
  if isNpcAssist then
    local shipIds = npcAssistFleetMgr:GetUIShipIds()
    for i, heroId in ipairs(shipIds) do
      local data
      if npcAssistFleetMgr:IsNpcHeroId(heroId) then
        data = npcAssistFleetMgr:GetNpcShipById(heroId)
      else
        data = Data.heroData:GetHeroById(heroId)
      end
      local newData = {}
      local mainConfig = configManager.GetDataById("config_ship_main", data.TemplateId)
      local infoConfig = Logic.shipLogic:GetShipInfoBySiId(mainConfig.ship_info_id)
      newData.heroId = data.HeroId
      newData.sm_id = data.TemplateId
      newData.si_id = mainConfig.ship_info_id
      newData.oldLevel = data.Lvl
      local shipInfo = Data.heroData:GetHeroById(heroId)
      if shipInfo.Name ~= "" and not npcAssistFleetMgr:IsNpcHeroId(heroId) then
        newData.name = shipInfo.Name
      else
        newData.name = infoConfig.ship_name
      end
      newData.type = mainConfig.type
      newData.oldExp = data.Exp
      newData.oldMood = 0
      newData.oldLove = 0
      newData.preTowerPoint = 100
      table.insert(shipList, newData)
    end
  else
    local shipDataList = Logic.fleetLogic:GetShipDataListByFleet(fleetId, fleetType)
    for i, data in ipairs(shipDataList) do
      local newData = {}
      local mainConfig = configManager.GetDataById("config_ship_main", data.TemplateId)
      local infoConfig = Logic.shipLogic:GetShipInfoBySiId(mainConfig.ship_info_id)
      newData.heroId = data.HeroId
      newData.sm_id = data.TemplateId
      newData.si_id = mainConfig.ship_info_id
      newData.oldLevel = data.Lvl
      local shipInfo = Data.heroData:GetHeroById(data.HeroId)
      if shipInfo.Name ~= "" and not npcAssistFleetMgr:IsNpcHeroId(data.HeroId) then
        newData.name = shipInfo.Name
      else
        newData.name = infoConfig.ship_name
      end
      newData.type = mainConfig.type
      newData.oldExp = data.Exp
      newData.bullet = data.CurAmmunition
      newData.oil = data.CurGasoline
      _, newData.oldMood = Logic.marryLogic:GetLoveInfo(data.HeroId, MarryType.Mood)
      _, newData.oldLove = Logic.marryLogic:GetLoveInfo(data.HeroId, MarryType.Love)
      newData.preTowerPoint = Logic.settlementLogic:GetTowerPoint(data.TemplateId, fleetType)
      table.insert(shipList, newData)
    end
  end
  return shipList
end

function ReadNewToGenShipList(shipList, myFleetId, param, fleetType)
  fleetType = fleetType or FleetType.Normal
  assert(shipList and myFleetId, "args has nil")
  local hasShipExp = param.shouldAddShipExp
  local isNpcAssist = npcAssistFleetMgr:GetNpcAssist()
  if isNpcAssist then
    local shipIds = npcAssistFleetMgr:GetUIShipIds()
    local leadHeroId = shipIds[1]
    for i, data in ipairs(shipList) do
      local newId = shipIds[i]
      local newData
      if npcAssistFleetMgr:IsNpcHeroId(newId) then
        newData = npcAssistFleetMgr:GetNpcShipById(newId)
      else
        newData = Data.heroData:GetHeroById(newId)
      end
      data.addExp = 0
      data.hp = Logic.shipLogic:GetHeroHp(newData.HeroId, fleetType)
      data.maxHp = Logic.shipLogic:GetHeroMaxHp(newData.HeroId, fleetType)
      data.cacheHp = SettlementHelper.genDisPlayCacheHp(data.cacheHp, data.maxHp)
      data.status = Logic.shipLogic:GetHeroHpStatus(data.hp, data.maxHp)
      data.newMood = 0
      data.newLove = 0
    end
  else
    for i, data in ipairs(shipList) do
      data.hp = Logic.shipLogic:GetHeroHp(data.heroId, fleetType)
      data.maxHp = Logic.shipLogic:GetHeroMaxHp(data.heroId, fleetType)
      if data.cacheHp == nil then
        data.cacheHp = 0
      end
      data.cacheHp = SettlementHelper.genDisPlayCacheHp(data.cacheHp, data.maxHp)
      data.addExp = 0
      data.status = Logic.shipLogic:GetHeroHpStatus(data.hp, data.maxHp)
      _, data.newMood = Logic.marryLogic:GetLoveInfo(data.heroId, MarryType.Mood)
      _, data.newLove = Logic.marryLogic:GetLoveInfo(data.heroId, MarryType.Love)
    end
  end
  local config = configManager.GetDataById("config_pskill_sp_talent", 2).parameter[1]
  Logic.spSkillLogic:SpAddHerosExp(shipList, config)
end

function genDisPlayCacheHp(cacheHp, maxHp)
  local battleConf = configManager.GetDataById("config_battle_config", HP_ACCURACY)
  local hp_accuracy = tonumber(battleConf.data)
  return math.ceil(cacheHp / hp_accuracy * maxHp)
end

function HandleEnemyListFormL2DResult(enemyList, enemyInfo)
  local battleConf = configManager.GetDataById("config_battle_config", HP_ACCURACY)
  local hp_accuracy = tonumber(battleConf.data)
  for i = 0, enemyInfo.shipsInfo.Count - 1 do
    local ship = enemyInfo.shipsInfo[i]
    local data = {}
    local siConfig = Logic.shipLogic:GetShipInfoBySiId(ship.dictId)
    data.heroId = ship.shipUid
    data.name = siConfig.ship_name
    data.si_id = ship.dictId
    data.hp = math.ceil(ship.hp / hp_accuracy * ship.hpMax)
    data.maxHp = ship.hpMax
    data.status = Logic.shipLogic:GetHeroHpStatus(data.hp, data.maxHp)
    data.uid = ship.shipUid
    data.totalDamage = ship.damage
    data.bSelf = false
    data.joinBattle = ship.joinBattle
    table.insert(enemyList, data)
  end
end

function GetEnemyFleetShipsList(fleetList)
  local fleetShipList = {}
  for i = 1, #fleetList do
    local fleet = fleetList[i]
    local shipList = {}
    HandleEnemyListFormL2DResult(shipList, fleet)
    local info = {}
    info.fleetUid = fleet.fleetUid
    info.percent = fleet.percent
    info.findNumByNPC = fleet.findNumByNPC
    info.dictId = fleet.dictId
    info.shipList = shipList
    table.insert(fleetShipList, info)
  end
  return fleetShipList
end

function HandleMyListFormL2DResult(shipList, myInfo)
  local shipListCount = #shipList
  local shipInfoCount = myInfo.shipsInfo.Count
  local nFinalCount = 0
  if shipListCount > shipInfoCount then
    nFinalCount = shipInfoCount
  else
    nFinalCount = shipListCount
  end
  local mvpDamage = 0
  for i = 1, nFinalCount do
    local info = myInfo.shipsInfo[i - 1]
    local ship = shipList[i]
    ship.totalDamage = info.damage
    mvpDamage = mvpDamage < info.damage and info.damage or mvpDamage
    ship.gunDamage = info.gunDamage
    ship.torpedoDamage = info.torpedoDamage
    ship.bombDamage = info.bombDamage
    ship.carriarTorpedoDamage = info.carriarTorpedoDamage
    ship.bSelf = true
    ship.joinBattle = info.joinBattle
    ship.maxHp = Logic.shipLogic:GetHeroMaxHp(ship.heroId)
    ship.uid = info.shipUid
    ship.petDictId = info.petDictId
    ship.wakeup = info.petWakeup
    ship.layer = LayerMask.NameToLayer("UI3DObject")
  end
  for i = 1, #shipList do
    local ship = shipList[i]
    ship.mvpDamage = mvpDamage
  end
  local bSetMVP = false
  for i, ship in ipairs(shipList) do
    if not bSetMVP and ship.totalDamage == mvpDamage and ship.totalDamage ~= 0 then
      ship.mvp = true
      bSetMVP = true
    else
      ship.mvp = false
    end
  end
end

function HandleMyPSkillsFormL2DResult(shipList, l2dResult)
  SettlementHelper.HandlePSkillsFromL2DResultImpl(shipList, l2dResult)
end

function HandleEnemyPSkillsFormL2DResult(shipList, l2dResult)
  SettlementHelper.HandlePSkillsFromL2DResultImpl(shipList, l2dResult)
end

function HandlePSkillsFromL2DResultImpl(shipList, l2dResult)
  local cacheHps = SettlementHelper.GetFleetCacheHp(l2dResult)
  local shipPSkills = SettlementHelper.GetFleetPSkillInfo(l2dResult)
  local battleConf = configManager.GetDataById("config_battle_config", HP_ACCURACY)
  local hp_accuracy = tonumber(battleConf.data)
  for i = 1, #shipList do
    local ship = shipList[i]
    ship.PSkillList = {}
    if shipPSkills[ship.uid] then
      ship.PSkillList = shipPSkills[ship.uid]
    end
    ship.cacheHp = 0
    if cacheHps[ship.uid] then
      local cacheHp = cacheHps[ship.uid]
      ship.cacheHp = cacheHp
    end
  end
end

function GetMyFleetInfos(l2dResult)
  local Infos = {}
  for i = 0, l2dResult.resultInfos.Count - 1 do
    local info = l2dResult.resultInfos[i]
    if info.isPlayer then
      table.insert(Infos, info)
    end
  end
  return Infos
end

function GetEnemyFleetInfos(l2dResult)
  local Infos = {}
  for i = 0, l2dResult.resultInfos.Count - 1 do
    local info = l2dResult.resultInfos[i]
    if not info.isPlayer then
      table.insert(Infos, info)
    end
  end
  return Infos
end

function GetFleetPSkillInfo(l2dResult)
  local Infos = {}
  if l2dResult.shipTriggerPSkills.Count < 1 then
    return Infos
  end
  for i = 0, l2dResult.shipTriggerPSkills.Count - 1 do
    local info = l2dResult.shipTriggerPSkills[i]
    local temp
    if SettlementHelper.CheckSettlementShowSkill(info.skillGroupDictId) then
      temp = {
        shipUID = info.shipUID,
        skillGroupDictId = info.skillGroupDictId,
        skillMainDictId = info.skillMainDictId,
        targetUID = info.targetUID
      }
    end
    if temp then
      if Infos[info.shipUID] then
        local iscopy = false
        for i, v in ipairs(Infos[info.shipUID]) do
          if v.skillGroupDictId == temp.skillGroupDictId then
            iscopy = true
            break
          end
        end
        if not iscopy then
          table.insert(Infos[info.shipUID], temp)
        end
      else
        Infos[info.shipUID] = {temp}
      end
    end
  end
  return Infos
end

function CheckSettlementShowSkill(skillGroupDictId)
  local pskillDisplayDictId = configManager.GetDataById("config_pskill_dict_group", skillGroupDictId).pskill_dict_display_id
  local type = Logic.shipLogic:GetPSkillDisplayConfigById(pskillDisplayDictId).trigger_display_type
  return type == 3
end

function GetFleetCacheHp(l2dResult)
  local Infos = {}
  if l2dResult.playerShipHpCache.Count < 1 then
    return Infos
  end
  for i = 0, l2dResult.playerShipHpCache.Count - 1 do
    local info = l2dResult.playerShipHpCache[i]
    Infos[info.shipUID] = info.hp
  end
  return Infos
end

local cacheHpTest = {
  [4] = 10000000000,
  [6] = 10000000000,
  [9] = 10000000000
}
local pskillTest = {
  [4] = {
    shipUID = 4,
    skillGroupDictId = 4,
    skillMainDictId = 4,
    targetUID = 4
  }
}
