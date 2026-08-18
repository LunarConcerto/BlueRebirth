local ValidCurTorpedo = class("game.Guide.guidebehaviours.ValidCurTorpedo", GR.requires.BehaviourBase)

function ValidCurTorpedo:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.ValidCurTorpedo)
  self:onDone()
end

return ValidCurTorpedo
