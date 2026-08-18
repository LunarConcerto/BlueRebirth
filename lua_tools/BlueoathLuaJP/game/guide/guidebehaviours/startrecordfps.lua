local StartRecordFPS = class("game.Guide.guidebehaviours.StartRecordFPS", GR.requires.BehaviourBase)

function StartRecordFPS:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.StartFPSCheck, FPSCheckParam)
  self:onDone()
end

return StartRecordFPS
