local SetGuideInfluenceData = class("game.Guide.guidebehaviours.SetGuideInfluenceData", GR.requires.BehaviourBase)

function SetGuideInfluenceData:doBehaviour()
  local tblParam = self.objParam
  local objType = tblParam[1]
  local nData = tblParam[2]
  GR.guideHub:setGuideInfluenceData(objType, nData)
  self:onDone()
end

return SetGuideInfluenceData
