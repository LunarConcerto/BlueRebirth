local ResumeBattle = class("game.Guide.guidebehaviours.ResumeBattle", GR.requires.BehaviourBase)

function ResumeBattle:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.PAUSE_BATTLE, false)
  self:onDone()
end

return ResumeBattle
