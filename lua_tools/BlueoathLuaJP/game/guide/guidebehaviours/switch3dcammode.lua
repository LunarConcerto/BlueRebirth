local Switch3DCamMode = class("game.Guide.guidebehaviours.Switch3DCamMode", GR.requires.BehaviourBase)

function Switch3DCamMode:doBehaviour()
  local nMode = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetSearchCamMode, nMode)
  self:onDone()
end

return Switch3DCamMode
