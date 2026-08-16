local ShipDamageTrigger = class("game.guide.guideTrigger.ShipDamageTrigger", GR.requires.GuideTriggerBase)

function ShipDamageTrigger:initialize(nType, shipDamage)
  self.type = nType
  self.param = shipDamage
end

function ShipDamageTrigger:tick()
  local curStage = stageMgr:GetCurStageType()
  if curStage ~= EStageType.eStageMain then
    return
  end
  local fleetShips = Logic.fleetLogic:GetFleetHeroId()
  for _, fleet in ipairs(fleetShips) do
    for heroId, v in pairs(fleet) do
      local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(heroId)
      local curHp = Logic.shipLogic:GetHeroHp(heroId)
      local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
      if hpStatus >= self.param then
        if self.param == 1 then
          self:sendTrigger()
          return
        elseif self.param == 2 then
          self:sendTrigger()
          return
        elseif self.param == 3 then
          self:sendTrigger()
          return
        end
      end
    end
  end
end

return ShipDamageTrigger
