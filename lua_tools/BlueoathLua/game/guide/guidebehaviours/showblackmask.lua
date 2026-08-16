local ShowBlackMask = class("game.Guide.guidebehaviours.ShowBlackMask", GR.requires.BehaviourBase)

function ShowBlackMask:doBehaviour()
  GR.guideManager.guidePage:ShowBlackMask(self.objParam)
  self:onDone()
end

return ShowBlackMask
