local SetGuidePageSort = class("game.Guide.guidebehaviours.SetGuidePageSort", GR.requires.BehaviourBase)

function SetGuidePageSort:doBehaviour()
  local objGuidePage = GR.guideHub:getGuidePage()
  if objGuidePage == nil then
    logError("objGuidePage is nil")
    return
  end
  local tblParam = self.objParam
  local nLayer = tblParam[1]
  local nSort = tblParam[2]
  local tblCSharpParam = {}
  tblCSharpParam.guidePage = objGuidePage.cs_page
  tblCSharpParam.nLayer = nLayer
  tblCSharpParam.nSort = nSort
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetGuidePageSort, tblCSharpParam)
  self:onDone()
end

return SetGuidePageSort
