local RepaireBehaviour = class("game.Guide.guidebehaviours.RepaireBehaviour", GR.requires.BehaviourBase)

function RepaireBehaviour:doBehaviour()
  local tblNeedRepairShips = self:_getNeedReapirShip()
  local nCount = #tblNeedRepairShips
  if nCount == 0 then
    self:onDone()
  else
    local tblHeroInfo = {}
    for k, nHeroId in pairs(tblNeedRepairShips) do
      local tblOneHeroInfo = Data.heroData:GetHeroById(nHeroId)
      table.insert(tblHeroInfo, tblOneHeroInfo)
    end
    local nNeedGold = Logic.repaireLogic:CalculateNeedAllGold(tblHeroInfo)
    local nCurGold = Data.userData:GetCurrency(CurrencyType.GOLD)
    if nNeedGold > nCurGold then
      self:onDone()
      return
    end
    eventManager:RegisterEvent("getRepaireMsg", self._onReceiveRepaire, self)
    Service.repaireService:SendGetRepair(tblNeedRepairShips)
  end
end

function RepaireBehaviour:_onReceiveRepaire()
  eventManager:UnregisterEvent("getRepaireMsg", self._onReceiveRepaire, self)
  self:onDone()
end

function RepaireBehaviour:_getNeedReapirShip()
  local tblFleetShips = Data.fleetData:GetShipByFleet(1)
  local tblResult = {}
  for k, nHeroId in pairs(tblFleetShips) do
    local heroInfo = Logic.attrLogic:GetHeroFianlAttrById(nHeroId)
    local curHp = Logic.shipLogic:GetHeroHp(nHeroId)
    if curHp < heroInfo[AttrType.HP] then
      table.insert(tblResult, nHeroId)
    end
  end
  return tblResult
end

return RepaireBehaviour
