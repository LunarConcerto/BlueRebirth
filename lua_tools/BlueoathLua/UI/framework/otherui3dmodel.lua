local OtherUI3DModel = class("ui.framework.OtherUI3DModel", UI3DModelBase)

function OtherUI3DModel:ApplyCameraParam(param, commonCameraParam)
  if param then
    self:SetCamerParam(param)
  end
  if commonCameraParam ~= nil then
    self:SetCommonCamParam(commonCameraParam)
  end
end

function OtherUI3DModel:CreateObj(objParam)
  local parentTrans
  if self.m_objRoot then
    parentTrans = self.m_objRoot.transform
  end
  if objParam.resPath then
    self.m_bGen = true
    self.m_3dObj = GR.objectPoolManager:LuaGetGameObject(objParam.resPath)
  else
    self.m_bGen = false
    self.m_3dObj = objParam.targetObject
  end
  if parentTrans then
    self.m_3dObj.transform:SetParent(parentTrans, false)
  end
  UIHelper.SetLayer(self.m_3dObj, LayerMask.NameToLayer("UI3DObject"))
end

function OtherUI3DModel:DestroyObj()
  if self.m_3dObj ~= nil and self.m_bGen then
    GR.objectPoolManager:LuaUnspawn(self.m_3dObj)
  end
  self.m_3dObj = nil
end

function OtherUI3DModel:ObjShow()
  if self.m_bGen then
    self.m_3dObj:SetActive(true)
  end
end

function OtherUI3DModel:ObjHide()
  if self.m_bGen then
    self.m_3dObj:SetActive(false)
  end
end

return OtherUI3DModel
