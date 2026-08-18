local ReOpenBattleSubUI = class("game.Guide.guidebehaviours.ReOpenBattleSubUI", GR.requires.BehaviourBase)

function ReOpenBattleSubUI:doBehaviour()
  local strPath = self.objParam
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.ReopenBattleSubUI, strPath)
  self:onDone()
end

return ReOpenBattleSubUI
