local SelectCopy = class("game.Guide.guidebehaviours.SelectCopy", GR.requires.BehaviourBase)

function SelectCopy:doBehaviour()
  GR.guideManager.guidePage:ShowSelectCopy(self.objParam)
  self:onDone()
end

return SelectCopy
