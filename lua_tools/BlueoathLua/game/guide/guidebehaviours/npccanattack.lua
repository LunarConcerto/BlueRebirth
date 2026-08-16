local NpcCanAttack = class("game.Guide.guidebehaviours.NpcCanAttack", GR.requires.BehaviourBase)

function NpcCanAttack:doBehaviour()
  local bCanMove = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.NpcCanAttack, bCanMove)
  self:onDone()
end

return NpcCanAttack
