local ShowSimpleTip = class("game.Guide.guidebehaviours.ShowSimpleTip", GR.requires.BehaviourBase)

function ShowSimpleTip:doBehaviour()
  local strPath = self.objParam
  GR.guideManager.guidePage:ShowSimpleTip(strPath, true)
  self:onDone()
end

return ShowSimpleTip
