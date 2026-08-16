local PauseBattle = class("game.Guide.guidebehaviours.PauseBattle", GR.requires.BehaviourBase)

function PauseBattle:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.PAUSE_BATTLE, true)
  self:onDone()
end

return PauseBattle
