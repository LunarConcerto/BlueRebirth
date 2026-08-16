local MidTip = class("game.Guide.guidebehaviours.MidTip", GR.requires.BehaviourBase)

function MidTip:doBehaviour()
  local tblParam = self.objParam
  local bShow = tblParam[1]
  local strLanId = tblParam[2]
  GR.guideManager.guidePage:ShowTip(bShow, strLanId)
  self:onDone()
end

return MidTip
