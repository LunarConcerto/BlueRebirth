local SetBuildPageTog = class("game.Guide.guidebehaviours.SetBuildPageTog", GR.requires.BehaviourBase)

function SetBuildPageTog:doBehaviour()
  local nType = self.objParam
  eventManager:SendEvent(LuaEvent.BuildShipChangeTog, nType)
  self:onDone()
end

return SetBuildPageTog
