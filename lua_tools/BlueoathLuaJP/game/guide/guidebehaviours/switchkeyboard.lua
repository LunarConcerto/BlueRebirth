local SwitchKeyboard = class("game.Guide.guidebehaviours.SwitchKeyboard", GR.requires.BehaviourBase)

function SwitchKeyboard:doBehaviour()
  local bOpen = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SwitchKeyboard, bOpen)
  self:onDone()
end

return SwitchKeyboard
