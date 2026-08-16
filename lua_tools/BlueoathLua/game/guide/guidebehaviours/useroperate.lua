local UserOperate = class("game.Guide.guidebehaviours.UserOperate", GR.requires.BehaviourBase)

function UserOperate:doBehaviour()
  self.nCompId = self.objParam
  self:registerEvent(LuaEvent.GuideUserOpe, self.onUserOpe)
  GR.guideHub:enableElement(self.nCompId, true)
end

function UserOperate:onUserOpe(nId)
  if nId == self.nCompId then
    self:onDone()
  end
end

function UserOperate:onBehaviourEnd()
  GR.guideHub:disableElement()
end

return UserOperate
