local CostTimeBehaviour = class("game.Guide.guidebehaviours.CostTimeBehaviour", GR.requires.BehaviourBase)

function CostTimeBehaviour:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.TIME_CAN_COST, self.objParam)
  self:onDone()
end

return CostTimeBehaviour
