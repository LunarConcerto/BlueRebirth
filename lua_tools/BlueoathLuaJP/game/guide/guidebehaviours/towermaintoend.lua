local TowerMainToEnd = class("game.Guide.guidebehaviours.TowerMainToEnd", GR.requires.BehaviourBase)

function TowerMainToEnd:doBehaviour()
  local bOpen = UIHelper.IsPageOpen("TowerRoadPage")
  if not bOpen then
    self:onDone()
    return
  end
  eventManager:RegisterEvent(LuaEvent.TowerMove, self._onTowerPageOnRefresh, self)
end

function TowerMainToEnd:_onTowerPageOnRefresh()
  local strPath = "MainRoot/TowerRoadPage/rodecopys"
  local transRootUI = UIManager.rootUI
  local transScrollRect = transRootUI:Find(strPath)
  local objScrollRect = transScrollRect.gameObject:GetComponent(UIScrollRect.GetClassType())
  objScrollRect.verticalNormalizedPosition = 0
  eventManager:UnregisterEvent(LuaEvent.TowerMove, self._onTowerPageOnRefresh, self)
  self:onDone()
end

return TowerMainToEnd
