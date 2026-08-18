local ResetCurTorpedo = class("game.Guide.guidebehaviours.ResetCurTorpedo", GR.requires.BehaviourBase)

function ResetCurTorpedo:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.ResetCurTorpedo)
  self:onDone()
end

return ResetCurTorpedo
