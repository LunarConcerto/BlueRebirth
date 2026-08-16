local SetFatigue = class("game.Guide.guidebehaviours.SetFatigue", GR.requires.BehaviourBase)

function SetFatigue:doBehaviour()
  local tblParam = self.objParam
  local nApercent = tblParam[1]
  local nBPercent = tblParam[2]
  local tblParam = {}
  tblParam.aPercent = nApercent
  tblParam.bPercent = nBPercent
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetPlayerFatigue, tblParam)
  self:onDone()
end

return SetFatigue
