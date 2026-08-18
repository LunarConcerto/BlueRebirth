local ShowOptionalBtn = class("game.Guide.guidebehaviours.ShowOptionalBtn", GR.requires.BehaviourBase)

function ShowOptionalBtn:doBehaviour()
  local bShow = self.objParam
  GR.guideManager.guidePage:ShowOptionalBtn(bShow)
  if bShow then
    self:registerEvent(LuaEvent.GuideUserOpe, self.onUserOpe)
  else
    self:onDone()
  end
end

function ShowOptionalBtn:onUserOpe(nId)
  if nId == 0 then
    self:onDone()
  end
end

return ShowOptionalBtn
