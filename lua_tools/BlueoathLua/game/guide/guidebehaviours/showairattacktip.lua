local ShowAirAttackTip = class("game.Guide.guidebehaviours.ShowAirAttackTip", GR.requires.BehaviourBase)

function ShowAirAttackTip:doBehaviour()
  local bShow = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.CheckAirAttack, bShow)
  self:onDone()
end

return ShowAirAttackTip
