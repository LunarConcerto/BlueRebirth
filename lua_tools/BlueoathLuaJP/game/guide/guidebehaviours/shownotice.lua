local ShowNotice = class("game.Guide.guidebehaviours.ShowNotice", GR.requires.BehaviourBase)

function ShowNotice:doBehaviour()
  eventManager:SendEvent(LuaEvent.GuideShowNotice, self.objParam)
  self:registerEvent(LuaEvent.GuideUserOpe, self.onUserOpe)
end

function ShowNotice:onUserOpe()
  self:onDone()
end

return ShowNotice
