local HideSimpleTip = class("game.Guide.guidebehaviours.HideSimpleTip", GR.requires.BehaviourBase)

function HideSimpleTip:doBehaviour()
  local strPath = self.objParam
  GR.guideManager.guidePage:ShowSimpleTip(strPath, false)
  self:onDone()
end

return HideSimpleTip
