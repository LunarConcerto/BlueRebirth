local BuildingMainToLeft = class("game.Guide.guidebehaviours.BuildingMainToLeft", GR.requires.BehaviourBase)

function BuildingMainToLeft:doBehaviour()
  local strPath = "MainRoot/BuildingMainPage/sv_map"
  local bOpen = UIHelper.IsPageOpen("BuildingMainPage")
  if not bOpen then
    self:onDone()
    return
  end
  local transRootUI = UIManager.rootUI
  local transScrollRect = transRootUI:Find(strPath)
  local objScrollRect = transScrollRect.gameObject:GetComponent(UIScrollRect.GetClassType())
  objScrollRect.horizontalNormalizedPosition = 0
  self:onDone()
end

return BuildingMainToLeft
