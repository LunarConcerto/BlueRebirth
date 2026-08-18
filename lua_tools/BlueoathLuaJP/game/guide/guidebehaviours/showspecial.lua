local ShowSpecial = class("game.Guide.guidebehaviours.ShowSpecial", GR.requires.BehaviourBase)

function ShowSpecial:doBehaviour()
  local tblParam = self.objParam
  local strPath = tblParam[1]
  local bShow = tblParam[2]
  GR.guideManager.guidePage:ShowSpecial(strPath, bShow)
  self:onDone()
end

return ShowSpecial
