local SetPlayerSpeed = class("game.Guide.guidebehaviours.SetPlayerSpeed", GR.requires.BehaviourBase)

function SetPlayerSpeed:doBehaviour()
  local nTarget = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetPlayerSpeedToNormal, nTarget)
  self:onDone()
end

return SetPlayerSpeed
