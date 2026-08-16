local SearchCamModelToNear = class("game.Guide.guidebehaviours.SearchCamModelToNear", GR.requires.BehaviourBase)

function SearchCamModelToNear:doBehaviour()
  CacheUtil.SetSearchCameraMode(0)
  PlayerPrefs.Save()
  Data.prefsData:SaveAll()
  self:onDone()
end

return SearchCamModelToNear
