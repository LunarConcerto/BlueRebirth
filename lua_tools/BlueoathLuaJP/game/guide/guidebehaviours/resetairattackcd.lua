local ResetAirAttackCD = class("game.Guide.guidebehaviours.ResetAirAttackCD", GR.requires.BehaviourBase)

function ResetAirAttackCD:doBehaviour()
  GR.guideManager.guidePage:ShowResetAirAttack(self.objParam)
  self:onDone()
end

return ResetAirAttackCD
