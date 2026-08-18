local ShipInBattleCheck = class("game.guide.guideTrigger.ShipInBattleCheck", GR.requires.GuideTriggerBase)

function ShipInBattleCheck:initialize(nType, nFleetType)
  self.type = nType
  self.nFleetType = nFleetType
end

function ShipInBattleCheck:onStart(param)
  self.nShipNum = param
  local nCount = self:_getFleetShipCount()
  if nCount >= self.nShipNum then
    self:sendTrigger()
    return
  end
  eventManager:RegisterEvent(LuaEvent.ShipInBattle, self._onInBattleEnd, self)
end

function ShipInBattleCheck:_onInBattleEnd(tblParam)
  local nFleetType = tblParam[1]
  local tblHeroInfo = tblParam[2]
  if nFleetType ~= self.nFleetType then
    return
  end
  local nCount = GetTableLength(tblHeroInfo)
  if nCount >= self.nShipNum then
    self:sendTrigger()
  end
end

function ShipInBattleCheck:onEnd()
  eventManager:UnregisterEvent(LuaEvent.ShipInBattle, self._onInBattleEnd, self)
end

function ShipInBattleCheck:_getFleetShipCount()
  local tblShipList = Data.fleetData:GetShipByFleet(1, self.nFleetType)
  local nCount = GetTableLength(tblShipList)
  return nCount
end

return ShipInBattleCheck
