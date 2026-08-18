local NpcCanMove = class("game.Guide.guidebehaviours.NpcCanMove", GR.requires.BehaviourBase)

function NpcCanMove:doBehaviour()
  local bCanMove = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetNpcCanMove, bCanMove)
  self:onDone()
end

return NpcCanMove
