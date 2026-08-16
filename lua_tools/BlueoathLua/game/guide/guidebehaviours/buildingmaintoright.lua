local BuildingMainToRight = class("game.Guide.guidebehaviours.BuildingMainToRight", GR.requires.BehaviourBase)

function BuildingMainToRight:doBehaviour()
  local strPath = "MainRoot/BuildingMainPage/sv_map"
  local bOpen = UIHelper.IsPageOpen("BuildingMainPage")
  if not bOpen then
    self:onDone()
    return
  end
  local transRootUI = UIManager.rootUI
  local transScrollRect = transRootUI:Find(strPath)
  local objScrollRect = transScrollRect.gameObject:GetComponent(UIScrollRect.GetClassType())
  objScrollRect.horizontalNormalizedPosition = 1
  self:onDone()
end

return BuildingMainToRight
