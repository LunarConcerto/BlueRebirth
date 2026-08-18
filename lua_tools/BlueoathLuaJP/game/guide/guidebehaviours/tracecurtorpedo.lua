local TraceCurTorpedo = class("game.Guide.guidebehaviours.TraceCurTorpedo", GR.requires.BehaviourBase)

function TraceCurTorpedo:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.TraceCurTorpedo)
  self:onDone()
end

return TraceCurTorpedo
