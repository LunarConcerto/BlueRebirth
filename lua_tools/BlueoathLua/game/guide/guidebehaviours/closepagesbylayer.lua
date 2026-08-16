local ClosePagesByLayer = class("game.Guide.guidebehaviours.ClosePagesByLayer", GR.requires.BehaviourBase)

function ClosePagesByLayer:doBehaviour()
  local nLayer = self.objParam or UILayer.MAIN
  UIPageManager:CloseByLayer(nLayer)
  self:onDone()
end

return ClosePagesByLayer
