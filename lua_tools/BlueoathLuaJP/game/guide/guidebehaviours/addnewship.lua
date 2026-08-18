local AddNewShip = class("game.Guide.guidebehaviours.AddNewShip", GR.requires.BehaviourBase)

function AddNewShip:doBehaviour()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.GameLogicTrigger, "guide_add_newgirl")
  self:onDone()
end

return AddNewShip
