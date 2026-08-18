local UI3DModelBase = class("ui.framework.UI3DModelBase")
local RootPrefabPath = "ui/pages/common/ui3dmodel"
local typeName = {
  [CamDataType.Settle] = "set",
  [CamDataType.Display] = "get",
  [CamDataType.Detaile] = "details",
  [CamDataType.Study] = "school"
}

function UI3DModelBase:initialize(rawImage, renderDirectly, renderToGlobal, cameraType)
  self.cameraType = cameraType
  self.gameCamera = GR.cameraManager:showCamera(cameraType, false)
  self.m_objRoot = GR.objectPoolManager:LuaGetGameObject(RootPrefabPath)
  self.m_objRoot.transform.parent = nil
  self.m_camera = self.gameCamera:GetCam()
  local transCamRoot = self.gameCamera:getTransBase().parent
  transCamRoot.parent = self.m_objRoot.transform
  transCamRoot.localEulerAngles = Vector3.zero
  transCamRoot.localPosition = Vector3.zero
  self.m_light = self.m_objRoot:GetComponentInChildren(UnityEngine_Light.GetClassType())
  self.m_renderToGlobal = renderToGlobal or false
  if not renderDirectly then
    if rawImage ~= nil then
      self:_SetRenderTexture(rawImage, self.m_camera)
    end
  else
    self:_SetRenderCamera(self.m_camera)
    self.m_bg = self.m_camera:GetComponent(UI3DCameraBackground.GetClassType())
  end
end

function UI3DModelBase:SetCamerParam(tabCameraParam)
  local transform = self.gameCamera:getTransBase()
  transform.localPosition = Vector3.NewFromTab(tabCameraParam.cameraRelativePos)
  transform.localEulerAngles = Vector3.NewFromTab(tabCameraParam.cameraRelativeRot)
  if tabCameraParam.usePerspective then
    self.m_camera.orthographic = false
    self.m_camera.nearClipPlane = 0.1
  else
    self.m_camera.orthographic = true
    self.m_camera.orthographicSize = tabCameraParam.size
    self.m_camera.nearClipPlane = -10
  end
  self.m_camera.fieldOfView = tabCameraParam.fieldOfView
end

function UI3DModelBase:SetCommonCamParam(tblParam)
  if tblParam ~= nil then
    local nDepth = tblParam.depth
    if nDepth ~= nil then
      self.m_camera.depth = nDepth
    end
    local nClearFlag = tblParam.clearFlags
    if nClearFlag ~= nil then
      self.m_camera.clearFlags = nClearFlag
    end
  end
end

function UI3DModelBase:ChangeObj(objParam)
  self:DestroyObj()
  self:CreateObj(objParam)
end

function UI3DModelBase:Show()
  self:setCameraEnable(true)
  if self.m_3dObj ~= nil then
    self:ObjShow()
  end
end

function UI3DModelBase:Hide()
  if self.m_3dObj ~= nil then
    self:ObjHide()
  end
  self:setCameraEnable(false)
end

function UI3DModelBase:Destroy()
  self:Hide()
  self:DestroyObj()
  self:Clear()
  GR.objectPoolManager:LuaUnspawnAndDestory(self.m_objRoot)
end

function UI3DModelBase:setCameraEnable(bEnable)
  if self.gameCamera == nil then
    return
  end
  if self.gameCamera:isDestroyed() then
    return
  end
  self.m_camera.enabled = bEnable
end

function UI3DModelBase:_SetRenderTexture(rawImg, camera)
  local rect = rawImg.rectTransform.sizeDelta
  local ratio = Screen.height / 750
  local width, height = math.floor(rect.x * ratio), math.floor(rect.y * ratio)
  local desc = RenderTextureDescriptor(width, height)
  desc.useMipMap = false
  desc.autoGenerateMips = false
  desc.depthBufferBits = 24
  desc.msaaSamples = 1 < ratio and 2 or 4
  local rt = RenderTexture(desc)
  rt.wrapMode = 1
  camera.targetTexture = rt
  rawImg.texture = rt
  self.m_rt = rt
  camera.clearFlags = 2
  camera.allowHDR = false
end

function UI3DModelBase:_SetRenderCamera(camera)
  if self.m_renderToGlobal then
    GR.renderBufferManager:Register(camera)
    camera.clearFlags = 3
  else
    camera.clearFlags = 2
  end
end

function UI3DModelBase:Clear()
  if not IsNil(self.m_rt) then
    GameObject.Destroy(self.m_rt)
    self.m_rt = nil
  end
  if not self.gameCamera:isDestroyed() then
    if self.m_renderToGlobal then
      GR.renderBufferManager:Unregister(self.m_camera)
    end
    local cbk = self.m_camera.gameObject:GetComponent(UI3DCameraBackground.GetClassType())
    cbk:Clear()
  end
  GR.cameraManager:destroyCamera(self.cameraType, true)
end

function UI3DModelBase:Get3dObj()
  return self.m_3dObj
end

function UI3DModelBase:ResetEulerAngels()
  if self.m_3dObj then
    self.m_3dObj.transform.localEulerAngles = Vector3.zero
  end
end

function UI3DModelBase:SetLightPosition(pos)
  if self.m_3dObj then
    self.m_light.transform.position = pos
    self.m_light.transform:LookAt(self.m_3dObj.transform.position)
  end
end

function UI3DModelBase:SetBackgroundSize(dx, dy)
  self.m_bg:SetBackgroundSize(-dx, -dy, dx, dy)
end

function UI3DModelBase:SetBackgroundTex(tex)
  self.m_bg:SetBackgroundTex(tex)
end

function UI3DModelBase:SetPostEffect()
  self.m_bg:SetPostEffect()
end

function UI3DModelBase:ApplyCameraParam(type)
end

function UI3DModelBase:CreateObj(objParam)
end

function UI3DModelBase:DestroyObj()
end

function UI3DModelBase:ObjShow()
end

function UI3DModelBase:ObjHide()
end

return UI3DModelBase
