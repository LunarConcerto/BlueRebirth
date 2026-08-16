local CheckFPSResult = class("game.Guide.guidebehaviours.CheckFPSResult", GR.requires.BehaviourBase)

function CheckFPSResult:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.CheckFPSResult, FPSCheckParam)
  self:onDone()
end

return CheckFPSResult
