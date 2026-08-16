local RepaireLogic = class("logic.FleetLogic")
local m_dragEndPos = {
  {-1.5, 0},
  {-1.1, 0},
  {-0.7, 0},
  {-0.4, 0},
  {-0.02, 0},
  {0.2, 0}
}

function RepaireLogic:initialize()
  self.shipTab = nil
  self.tabRepaireFleet = {}
  self.sortway = true
  self.sortParam = {
    {},
    1
  }
  self.isDefalut = true
  self.bathShipNum = 0
  self.bathFinish = false
end

function RepaireLogic:ResetData()
  self.shipTab = nil
  self.tabRepaireFleet = {}
  self.sortway = true
  self.sortParam = {
    {},
    1
  }
  self.isDefalut = true
  self.bathShipNum = 0
  self.bathFinish = false
end

function RepaireLogic:SetShipNum(num)
  self.bathShipNum = num
end

function RepaireLogic:CheckShipNum()
  return self.bathShipNum == 1
end

function RepaireLogic:SetButhFinish(finish)
  self.bathFinish = finish
end

function RepaireLogic:GetButhFinish()
  return self.bathFinish
end

function RepaireLogic:GetFleetPos(objPos)
  local tempPosX = {}
  local tempPosY = {}
  local tempPos = {}
  local pos
  for i = 1, #m_dragEndPos do
    local tempX = m_dragEndPos[i][1] - objPos.x
    if tempX < 0 then
      tempX = -1 * tempX
    end
    local tempY = m_dragEndPos[i][2] - objPos.y
    if tempY < 0 then
      tempY = -1 * tempY
    end
    table.insert(tempPosX, tempX)
    table.insert(tempPosY, tempY)
    table.insert(tempPos, {tempX, tempY})
  end
  local minOfX = math.min(table.unpack(tempPosX))
  local minOfY = math.min(table.unpack(tempPosY))
  for i = 1, #tempPos do
    if tempPos[i][1] == minOfX and tempPos[i][2] == minOfY then
      pos = i
      break
    end
  end
  return pos
end

function RepaireLogic:GetRepairShip(haveHero)
  local tabNeedRepaire = {}
  for k, v in pairs(haveHero) do
    local curHp = Logic.shipLogic:GetHeroHp(v.HeroId)
    local maxHp = Logic.shipLogic:GetHeroMaxHp(v.HeroId)
    local curHpPer = curHp / maxHp
    if curHpPer < 1 then
      table.insert(tabNeedRepaire, v)
    end
  end
  return tabNeedRepaire
end

function RepaireLogic:CalculateNeedAllGold(fleetInfo)
  local all = 0
  for k, v in pairs(fleetInfo) do
    local tabConfig = configManager.GetDataById("config_ship_main", v.TemplateId)
    local curHp = Logic.shipLogic:GetHeroHp(v.HeroId)
    local maxHp = Logic.shipLogic:GetHeroMaxHp(v.HeroId)
    local curHpPer = curHp / maxHp
    local needGold = tabConfig.fixed_money
    local loveInfo = Logic.marryLogic:GetLoveInfo(v.HeroId, MarryType.Love)
    if 0 < loveInfo.affection_cost then
      needGold = needGold * loveInfo.affection_cost / 10000
    end
    all = all + math.ceil(needGold * (1 - curHpPer))
  end
  return all
end

function RepaireLogic:HeroHpShow(haveHero, fleetType)
  fleetType = fleetType or FleetType.Normal
  local maxHp = Logic.shipLogic:GetHeroMaxHp(haveHero.HeroId, fleetType)
  local curHp = Logic.shipLogic:GetHeroHp(haveHero.HeroId, fleetType)
  local curHpPer = curHp / maxHp
  return curHpPer
end

function RepaireLogic:GridLength(tabGrid)
  local length = 0
  for k, v in pairs(tabGrid) do
    length = length + 1
  end
  return length
end

function RepaireLogic:ReapireRecordData(m_tabReapireShipTid)
  local repire_mainId = {}
  local repaire_shipName = {}
  local index = 0
  for k, v in pairs(m_tabReapireShipTid) do
    index = index + 1
    local shipMainId = configManager.GetDataById("config_ship_main", v).sm_id
    repire_mainId[tostring(index)] = shipMainId
    local shipInfoId = configManager.GetDataById("config_ship_main", v).ship_info_id
    local shipName = Logic.shipLogic:GetShipInfoById(shipMainId).ship_name
    repaire_shipName[tostring(index)] = shipName
  end
  return repaire_shipName, repire_mainId
end

function RepaireLogic:CheckSameShip(shipTab, hero)
  if not shipTab then
    return false
  end
  local heroInfo = Logic.shipLogic:GetShipInfoById(hero.TemplateId)
  for _, v in pairs(shipTab) do
    local ship = Logic.shipLogic:GetShipInfoById(v.TemplateId)
    if ship.sf_id == heroInfo.sf_id then
      return true, v.HeroId == hero.HeroId, v
    end
  end
  return false
end

return RepaireLogic
