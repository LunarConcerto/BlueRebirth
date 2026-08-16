local ShowGuideGirl = class("game.Guide.guidebehaviours.ShowGuideGirl", GR.requires.BehaviourBase)

function ShowGuideGirl:doBehaviour()
  local tblParam = self.objParam
  if tblParam == nil or type(tblParam) ~= "table" then
    return
  end
  local bShow = tblParam[1]
  local nPosId = tblParam[2]
  local strTxt = tblParam[3]
  GR.guideManager.guidePage:ShowGuideGirl(bShow, nPosId, strTxt)
  self:onDone()
end

return ShowGuideGirl
