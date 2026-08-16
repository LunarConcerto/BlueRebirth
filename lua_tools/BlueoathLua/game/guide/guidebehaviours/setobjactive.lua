local SetObjActive = class("game.Guide.guidebehaviours.SetObjActive", GR.requires.BehaviourBase)

function SetObjActive:doBehaviour()
  local tblPara = self.objParam
  local strPath = tblPara[1]
  local bActive = tblPara[2]
  local uiRoot = UIManager.rootUI
  local target = uiRoot:Find(strPath)
  if not IsNil(target) then
    target.gameObject:SetActive(bActive)
  end
  self:onDone()
end

return SetObjActive
