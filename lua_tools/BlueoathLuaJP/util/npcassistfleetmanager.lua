local NpcAssistFleetManager = class("util.NpcAssistFleetManager")
local NPC_HERO_ID_START = 10000000
local IdGen = InitINC(NPC_HERO_ID_START, 1000)

function NpcAssistFleetManager:initialize()
  self:ResetData()
end

function NpcAssistFleetManager:GenHeroId(assistId)
  if not self.npcIdMap[assistId] then
    local heroId = IdGen()
    self.npcIdMap[assistId] = heroId
  end
  return self.npcIdMap[assistId]
end

function NpcAssistFleetManager:ResetData()
  self.npcIdMap = {}
  self.npcAssistUIShips = {}
  self.uiShipIds = {}
  self.npcAssistBattleShips = {}
  self.hasNpcAssist = false
  self.npcEquips = {}
  self.fleetData = {}
end

function NpcAssistFleetManager:SetNpcFleetData(fleetData)
  self.fleetData = fleetData
end

function NpcAssistFleetManager:GetNpcFleetData()
  return self.fleetData
end

function NpcAssistFleetManager:IsNpcHeroId(heroId)
  return heroId >= NPC_HERO_ID_START
end

function NpcAssistFleetManager:CreateNpcShip4Battle(assistInfoId, position)
  local assistInfoRec = configManager.GetDataById("config_assist_ship_info", assistInfoId)
  local shipMainRec = configManager.GetDataById("config_ship_main", assistInfoRec.ship_main_id)
  local ship = {}
  ship.Index = position - 1
  ship.HeroId = assistInfoId
  ship.NpcAssist = true
  ship.Level = assistInfoRec.ship_level
  ship.TemplateId = tonumber(assistInfoRec.ship_main_id)
  ship.CurHp = tonumber(configManager.GetDataById("config_battle_config", 169).data)
  ship.Advance = shipMainRec.break_level
  ship.Fashioning = assistInfoRec.ship_fashion_id
  local skills = {}
  local skillIds = shipMainRec.direct_activate_talent_id
  local skillLvs = assistInfoRec.ship_skill_level
  if #skillIds ~= #skillLvs then
    logError("[NpcAssistFleetManager]:\229\138\169\230\136\152\232\136\176\233\152\159\230\138\128\232\131\189\229\146\140\230\138\128\232\131\189\231\173\137\231\186\167\230\149\176\231\187\132\233\149\191\229\186\166\228\184\141\231\155\184\231\173\137, \232\161\168\230\160\188\239\188\154assist_ship_info:" .. tostring(assistInfoId))
    return {}
  end
  local skillCount = #skillIds
  for i = 1, skillCount do
    local info = {}
    info.PSkillLv = skillLvs[i] or 1
    info.PSkillId = skillIds[i]
    table.insert(skills, info)
  end
  ship.PSkill = skills
  ship.AssistInfoId = assistInfoId
  local equips = {}
  local equipIds = assistInfoRec.equip
  local equipLvs = assistInfoRec.equip_level
  if #equipIds ~= #equipLvs then
    logError("[NpcAssistFleetManager]:\229\138\169\230\136\152\232\136\176\233\152\159\232\163\133\229\164\135\229\146\140\232\163\133\229\164\135\231\173\137\231\186\167\230\149\176\231\187\132\233\149\191\229\186\166\228\184\141\231\155\184\231\173\137, \232\161\168\230\160\188\239\188\154assist_ship_info:" .. tostring(assistInfoId))
    return {}
  end
  local nEquipMaxNum = 6
  for i = 1, nEquipMaxNum do
    if equipIds[i] and equipIds[i] ~= 0 then
      equips[i] = self:_GetOneEquipInfo(i, equipIds[i], equipLvs[i], assistInfoRec.ship_main_id)
    end
  end
  ship.Equips = equips
  local attrMap = {}
  local attrs = {}
  local attrTbl = Logic.attrLogic:GetAttrTableShow()
  for index, attrId in pairs(attrTbl) do
    local name = Logic.attrLogic:GetAttrStringById(attrId)
    local attrValue = assistInfoRec[name]
    if attrValue ~= nil then
      if attrMap[attrId] then
        attrMap[attrId] = attrMap[attrId] + attrValue
      else
        attrMap[attrId] = attrValue
      end
    end
  end
  local shipBreak = configManager.GetDataById("config_ship_break", assistInfoRec.ship_main_id)
  local effectList = shipBreak.ship_break_effect_id_list
  for i, effId in ipairs(effectList) do
    local shipBreakEffect = configManager.GetDataById("config_ship_break_effect", effId)
    if attrMap[shipBreakEffect.type] then
      attrMap[shipBreakEffect.type] = attrMap[shipBreakEffect.type] + shipBreakEffect.value
    else
      attrMap[shipBreakEffect.type] = shipBreakEffect.value
    end
  end
  for attrId, attrValue in pairs(attrMap) do
    local attrInfo = {}
    attrInfo.AttrId = attrId
    attrInfo.AttrValue = attrValue
    table.insert(attrs, attrInfo)
  end
  ship.Attr = attrs
  return ship
end

function NpcAssistFleetManager:_GetOneEquipInfo(nIndex, nEquipId, nLevel, nShipMainId)
  local attr = Logic.equipLogic:GetCurEquipFinaAttrByLv(nEquipId, nLevel)
  local attrNew = {}
  for k, v in pairs(attr) do
    local attrInfo = {}
    attrInfo.AttrId = v.id
    attrInfo.AttrValue = v.value
    table.insert(attrNew, attrInfo)
  end
  local result = {}
  result.AttrValue = attrNew
  result.EquipTid = nEquipId
  result.EquipIndex = nIndex
  result.EquipLv = nLevel
  local shipEquip = configManager.GetDataById("config_ship_equip", nShipMainId)
  result.PlaneNum = shipEquip.plane_number[nIndex]
  return result
end

function NpcAssistFleetManager:ReplaceNpcShips4Train(heroInfo, ret)
  local battleShip = {}
  for position, shipId in ipairs(heroInfo) do
    local uiship = self.npcAssistUIShips[shipId]
    local ship = self:CreateNpcShip4Battle(uiship.assistId, position)
    battleShip[position] = ship
  end
  ret.BattlePlayer.FleetInfo.Ships = battleShip
end

function NpcAssistFleetManager:ReplaceNpcShip4Battle(ret, copyId)
  local currShips = ret.BattlePlayer.FleetInfo.Ships
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  local assistFleet = copyDisplay.assist_fleet
  local totalCount = copyDisplay.assist_fleet_num
  local assistShips = {}
  for i, assistId in ipairs(assistFleet) do
    if assistId ~= 0 then
      local ship = self:CreateNpcShip4Battle(assistId, i)
      table.insert(assistShips, ship)
    else
      table.insert(assistShips, 0)
    end
  end
  local result = {}
  local tidMap = {}
  result[1] = currShips[1]
  if assistShips[1] ~= 0 then
    result[1] = assistShips[1]
    result[1].Index = 0
  else
    if not currShips[1] then
      result[1] = assistShips[2]
    end
    table.remove(assistShips, 1)
  end
  local tid = self:GetTidById(result[1].HeroId)
  tidMap[tid] = true
  local remainCount = totalCount - 1
  local lastIndex = 2
  if 0 < remainCount then
    for _, assistShip in ipairs(assistShips) do
      local asTid = self:GetTidById(assistShip.HeroId)
      if asTid and asTid ~= 0 and not tidMap[asTid] then
        result[lastIndex] = assistShip
        assistShip.Index = lastIndex - 1
        tidMap[asTid] = true
        lastIndex = lastIndex + 1
        remainCount = remainCount - 1
        if remainCount <= 0 then
          break
        end
      end
    end
  end
  if 0 < remainCount then
    for _, ship in ipairs(currShips) do
      local heroTid = self:GetTidById(ship.HeroId)
      if ship and not tidMap[heroTid] then
        result[lastIndex] = ship
        ship.Index = lastIndex - 1
        lastIndex = lastIndex + 1
        remainCount = remainCount - 1
        if remainCount <= 0 then
          break
        end
      end
    end
  end
  ret.BattlePlayer.FleetInfo.Ships = result
end

function NpcAssistFleetManager:ReplaceFirstFleet(firstFleet, assistShipIds, copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  local totalCount = copyDisplay.assist_fleet_num
  local result = {}
  local tidMap = {}
  result[1] = firstFleet[1]
  if assistShipIds[1] ~= 0 then
    result[1] = assistShipIds[1]
  else
    if not firstFleet[1] then
      result[1] = assistShipIds[2]
    end
    table.remove(assistShipIds, 1)
  end
  local tid = self:GetTidById(result[1])
  tidMap[tid] = true
  local remainCount = totalCount - 1
  local lastIndex = 2
  if 0 < remainCount then
    for _, asId in ipairs(assistShipIds) do
      local asTid = self:GetTidById(asId)
      if asTid and asTid ~= 0 and not tidMap[asTid] then
        result[lastIndex] = asId
        tidMap[asTid] = true
        lastIndex = lastIndex + 1
        remainCount = remainCount - 1
        if remainCount <= 0 then
          break
        end
      end
    end
  end
  local sortFirst = clone(firstFleet)
  table.sort(sortFirst, function(l, r)
    local lp = Logic.attrLogic:GetBattlePower(l)
    local rp = Logic.attrLogic:GetBattlePower(r)
    return lp > rp
  end)
  if 0 < remainCount then
    for _, heroId in ipairs(sortFirst) do
      local heroTid = self:GetTidById(heroId)
      if heroId and heroId ~= 0 and not tidMap[heroTid] then
        result[lastIndex] = heroId
        lastIndex = lastIndex + 1
        remainCount = remainCount - 1
        if remainCount <= 0 then
          break
        end
      end
    end
  end
  return result
end

function NpcAssistFleetManager:CreateNpcShips4UI(copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  local assistFleet = copyDisplay.assist_fleet
  local assistShipIds = {}
  for i, assistId in ipairs(assistFleet) do
    if assistId ~= 0 then
      local ship = self:CreateNpcShip4UI(assistId)
      self:AddNpcAssistUIShip(ship)
      self:FixNpcAttr(ship.HeroId)
      table.insert(assistShipIds, ship.HeroId)
    else
      table.insert(assistShipIds, 0)
    end
  end
  return assistShipIds
end

function NpcAssistFleetManager:CreateNpcShip4UI(assistInfoId)
  local assistInfoRec = configManager.GetDataById("config_assist_ship_info", assistInfoId)
  local shipMainRec = configManager.GetDataById("config_ship_main", assistInfoRec.ship_main_id)
  local shipInfoRec = configManager.GetDataById("config_ship_info", shipMainRec.ship_info_id)
  local shipShowRec = Logic.shipLogic:GetShipShowByInfoId(shipMainRec.ship_info_id)
  local ship = {}
  ship.HeroId = assistInfoId
  ship.TemplateId = assistInfoRec.ship_main_id
  ship.Lvl = assistInfoRec.ship_level
  ship.Exp = 0
  ship.CurHp = tonumber(configManager.GetDataById("config_battle_config", 169).data)
  ship.Intensify = {}
  ship.Advance = shipMainRec.break_level
  ship.type = shipInfoRec.ship_type
  ship.shipCountry = shipInfoRec.ship_country
  ship.quality = shipInfoRec.quality
  ship.Lock = false
  ship.Status = 0
  ship.BattlePower = assistInfoRec.ship_fight_grade
  ship.MaxHp = assistInfoRec.hp
  ship.SupplyCost = assistInfoRec.ship_supply_cost
  ship.CreateTime = ship.TemplateId
  ship.assistId = assistInfoId
  ship.Fashioning = assistInfoRec.ship_fashion_id
  ship.UpdateTime = 0
  ship.Mood = 0
  ship.Affection = 0
  ship.PSKillLevelMap = {}
  ship.fleetId = shipInfoRec.sf_id
  ship.CombinationInfo = {
    ComLv = 0,
    ComGrade = 0,
    Combine = 0,
    BeCombined = 0
  }
  local equipIds = assistInfoRec.equip
  local equipLvs = assistInfoRec.equip_level
  if #equipIds < 6 or #equipLvs < 6 then
    logError("[NpcAssistFleetManager]:\229\138\169\230\136\152\232\136\176\233\152\159\232\163\133\229\164\135\229\146\140\232\163\133\229\164\135\230\149\176\233\135\143\229\176\143\228\186\1426, assist_ship_info:" .. tostring(assistInfoId))
    return {}
  end
  if #equipIds ~= #equipLvs then
    logError("[NpcAssistFleetManager]:\229\138\169\230\136\152\232\136\176\233\152\159\232\163\133\229\164\135\229\146\140\232\163\133\229\164\135\231\173\137\231\186\167\230\149\176\231\187\132\233\149\191\229\186\166\228\184\141\231\155\184\231\173\137, assist_ship_info:" .. tostring(assistInfoId))
    return {}
  end
  ship.Equips = self:_formatEquipInfo(clone(assistInfoRec.equip))
  for i, tid in ipairs(equipIds) do
    self:CreateEquip(tid, equipLvs[i] or 0)
  end
  ship.PSkill = {}
  ship.PSKillMap = {}
  local skillIds = shipMainRec.direct_activate_talent_id
  local skillLvs = assistInfoRec.ship_skill_level
  if #skillIds ~= #skillLvs then
    logError("[NpcAssistFleetManager]:\229\138\169\230\136\152\232\136\176\233\152\159\230\138\128\232\131\189\229\146\140\230\138\128\232\131\189\231\173\137\231\186\167\230\149\176\231\187\132\233\149\191\229\186\166\228\184\141\231\155\184\231\173\137, assist_ship_info:" .. tostring(assistInfoId))
    return {}
  end
  for i, skillId in ipairs(skillIds) do
    local t = {}
    t.PSkillId = skillId
    t.PSkillExp = 0
    t.Replace = 0
    table.insert(ship.PSkill, t)
    ship.PSKillLevelMap[skillId] = skillLvs[i]
  end
  return ship
end

function NpcAssistFleetManager:AddAttr(attrDic, attrType, attrValue)
  if attrDic[attrType] then
    attrDic[attrType] = attrDic[attrType] + attrValue
  else
    attrDic[attrType] = attrValue
  end
end

function NpcAssistFleetManager:FixNpcAttr(heroId)
  local npcShip = self:GetNpcShipById(heroId)
  local heroAttr = Logic.attrLogic:GetHeroAttr(npcShip)
  local assistInfoRec = configManager.GetDataById("config_assist_ship_info", npcShip.assistId)
  local shipMainRec = configManager.GetDataById("config_ship_main", assistInfoRec.ship_main_id)
  npcShip.EquipAttrs = heroAttr:GetHeroEquipAttr()
  npcShip.BasicAttrs = heroAttr:GetHeroBasicAttr()
  local basicAttrs = npcShip.BasicAttrs
  local attrTbl = Logic.attrLogic:GetAttrTableShow()
  for index, attrId in pairs(attrTbl) do
    local name = Logic.attrLogic:GetAttrStringById(attrId)
    local attrValue = assistInfoRec[name]
    if attrValue and attrValue ~= -1 then
      basicAttrs[attrId] = attrValue
    end
  end
  local finalAttrs = {}
  for atype, avalue in pairs(npcShip.BasicAttrs) do
    self:AddAttr(finalAttrs, atype, avalue)
  end
  for atype, avalue in pairs(npcShip.EquipAttrs) do
    self:AddAttr(finalAttrs, atype, avalue)
  end
  npcShip.FinalAttrs = finalAttrs
  local shipBreak = configManager.GetDataById("config_ship_break", assistInfoRec.ship_main_id)
  local effectList = shipBreak.ship_break_effect_id_list
  for i, effId in ipairs(effectList) do
    local shipBreakEffect = configManager.GetDataById("config_ship_break_effect", effId)
    if finalAttrs[shipBreakEffect.type] then
      finalAttrs[shipBreakEffect.type] = finalAttrs[shipBreakEffect.type] + shipBreakEffect.value
    else
      finalAttrs[shipBreakEffect.type] = shipBreakEffect.value
    end
  end
  local attackGrade = Logic.attrLogic:GetAttackGrade(heroId)
  finalAttrs[AttrType.ATTACK_GRADE] = attackGrade
end

function NpcAssistFleetManager:GetNpcFinalAttrs(heroId)
  local npcShip = self:GetNpcShipById(heroId)
  return npcShip.FinalAttrs
end

function NpcAssistFleetManager:GetNpcBasicAttrs(heroId)
  local npcShip = self:GetNpcShipById(heroId)
  return npcShip.BasicAttrs
end

function NpcAssistFleetManager:GetNpcEquipAttrs(heroId)
  local npcShip = self:GetNpcShipById(heroId)
  return npcShip.EquipAttrs
end

function NpcAssistFleetManager:CreateEquip(tid, level)
  local equip = clone(configManager.GetDataById("config_equip", tid))
  equip.EquipId = tid + 100000000
  equip.TemplateId = tid
  equip.Star = 1
  equip.EnhanceLv = level
  self.npcEquips[equip.EquipId] = equip
end

function NpcAssistFleetManager:GetNpcEquip(tid)
  return self.npcEquips[tid]
end

function NpcAssistFleetManager:GetTidById(heroId)
  local heroData = Data.heroData:GetHeroById(heroId)
  local tid = heroData.TemplateId
  local shipMainRec = configManager.GetDataById("config_ship_main", tid)
  return shipMainRec.ship_info_id
end

function NpcAssistFleetManager:Clear()
  self:ResetData()
end

function NpcAssistFleetManager:CheckNpcAssist(copyId)
  local copyDisplay = configManager.GetDataById("config_copy_display", copyId)
  local assistFleet = copyDisplay.assist_fleet
  return not table.empty(assistFleet)
end

function NpcAssistFleetManager:SetNpcAssist(hasNpcAssist)
  self.hasNpcAssist = hasNpcAssist
end

function NpcAssistFleetManager:GetNpcAssist()
  return self.hasNpcAssist
end

function NpcAssistFleetManager:AddNpcAssistBattleShip(battleShip)
  self.npcAssistBattleShips[battleShip.HeroId] = battleShip
end

function NpcAssistFleetManager:GetNpcBattleShipById(heroId)
  return self.npcAssistBattleShips[heroId]
end

function NpcAssistFleetManager:AddNpcAssistUIShip(uiShip)
  self.npcAssistUIShips[uiShip.HeroId] = uiShip
end

function NpcAssistFleetManager:GetNpcShipById(heroId)
  return self.npcAssistUIShips[heroId]
end

function NpcAssistFleetManager:SetUIShipIds(uiShipIds)
  self.uiShipIds = uiShipIds
end

function NpcAssistFleetManager:GetUIShipIds()
  return self.uiShipIds
end

function NpcAssistFleetManager:CreateStartBaseHeroList()
  local heroList = {}
  for i, shipId in ipairs(self.uiShipIds) do
    table.insert(heroList, shipId)
  end
  return heroList
end

function NpcAssistFleetManager:GetTrainAllShips()
  local ships = {}
  for id, ship in pairs(self.npcAssistUIShips) do
    table.insert(ships, ship)
  end
  return ships
end

function NpcAssistFleetManager:_formatEquipInfo(equipConfig)
  local res = Data.heroData:_getDefaultEquipInfo()
  if not table.empty(equipConfig) then
    for index, equipId in ipairs(equipConfig) do
      if res[index] then
        res[index].EquipsId = equipId + 100000000
      end
    end
  end
  return {
    [FleetType.Normal] = res
  }
end

return NpcAssistFleetManager
