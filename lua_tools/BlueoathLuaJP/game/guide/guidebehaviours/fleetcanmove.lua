local FleetCanMove = class("game.Guide.guidebehaviours.FleetCanMove", GR.requires.BehaviourBase)

function FleetCanMove:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetFleetCanMove, self.objParam)
  self:onDone()
end

return FleetCanMove
