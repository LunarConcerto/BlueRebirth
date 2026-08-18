local ChangeCopyPageTog = class("game.Guide.guidebehaviours.ChangeCopyPageTog", GR.requires.BehaviourBase)

function ChangeCopyPageTog:doBehaviour()
  local nTog = self.objParam
  eventManager:SendEvent(LuaEvent.ChangeCopyToggle, nTog - 1)
  self:onDone()
end

return ChangeCopyPageTog
