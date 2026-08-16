local UnLockShip = class("game.Guide.guidebehaviours.UnLockShip", GR.requires.BehaviourBase)

function UnLockShip:doBehaviour()
  self.nShipMainId = self.objParam
  local nSecretaryId = Data.userData:GetSecretaryId()
  local tblAllHeroData = Data.heroData:GetHeroData()
  local nTargetHeroId
  for nHeroId, tblHero in pairs(tblAllHeroData) do
    if tblHero.TemplateId == self.nShipMainId and tblHero.HeroId ~= nSecretaryId then
      local bLock = tblHero.Lock
      if not bLock then
        self:onDone()
      else
        nTargetHeroId = tblHero.HeroId
      end
    end
  end
  if nTargetHeroId == nil then
    self:onDone()
    return
  end
  eventManager:RegisterEvent(LuaEvent.SendHeroLock, self._onReceiveSetLock, self)
  Logic.shipLogic:SendHeroLockByType(nTargetHeroId, false, self)
end

function UnLockShip:_onReceiveSetLock()
  eventManager:UnregisterEvent(LuaEvent.SendHeroLock, self._onReceiveSetLock)
  self:onDone()
end

return UnLockShip
