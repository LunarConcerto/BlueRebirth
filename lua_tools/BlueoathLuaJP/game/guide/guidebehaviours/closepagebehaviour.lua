local ClosePageBehaviour = class("game.Guide.guidebehaviours.ClosePageBehaviour", GR.requires.BehaviourBase)

function ClosePageBehaviour:doBehaviour()
  local strPageName = self.objParam
  UIHelper.ClosePageImp(strPageName)
  self:onDone()
end

return ClosePageBehaviour
