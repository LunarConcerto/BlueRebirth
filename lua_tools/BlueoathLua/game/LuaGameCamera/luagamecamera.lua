local LuaGameCamera = class("Game.LuaGameCamera.LuaGameCamera")

function LuaGameCamera:initialize()
  self.mObjGameCamera = nil
  self.bMulti = false
end

function LuaGameCamera:initData(tblConfig)
  local bMulti = tblConfig.bMulti
  if bMulti == nil then
    bMulti = false
  end
  local objGameCam
  if bMulti then
    objGameCam = GR.csharpCameraManager:CreateNewCameraGroup(tblConfig)
  else
    objGameCam = GR.csharpCameraManager:CreateNormalCameraByLua(tblConfig)
  end
  self.mObjGameCamera = objGameCam
  self.bMulti = bMulti
end

function LuaGameCamera:getShot()
  return self.mObjGameCamera
end

function LuaGameCamera:GetCamObjByIndex(nIndex)
  if self.bMulti then
    return self.mObjGameCamera:GetCamObjByIndex(nIndex)
  end
end

function LuaGameCamera:enable()
  GR.csharpCameraManager:Enable(self.mObjGameCamera)
end

function LuaGameCamera:disable()
  GR.csharpCameraManager:Disable(self.mObjGameCamera)
end

function LuaGameCamera:destroy(bRelease)
  GR.csharpCameraManager:DestroyCamera(self.mObjGameCamera, bRelease)
end

function LuaGameCamera:isEnable()
  return self.mObjGameCamera:IsEnable()
end

function LuaGameCamera:isDestroyed()
  return self.mObjGameCamera:IsDestroy()
end

function LuaGameCamera:GetCamIndex(nIndex)
  if nIndex == nil then
    return 0
  else
    return nIndex - 1
  end
end

function LuaGameCamera:getTransBase(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self:GetTransByPriority(0, nIndex)
end

function LuaGameCamera:GetTransByPriority(nPriority, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetTransByPriority(nPriority, nIndex)
end

function LuaGameCamera:getCamTrans(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetCamTrans(nIndex)
end

function LuaGameCamera:getComponent(nPriority, objType, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetComponent(nPriority, objType, nIndex)
end

function LuaGameCamera:addComponent(nPriority, objType, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:AddComponent(nPriority, objType, nIndex)
end

function LuaGameCamera:ScreenPointToRay(pos, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:ScreenPointToRay(pos, nIndex)
end

function LuaGameCamera:SetClearFlags(clearFlags, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  self.mObjGameCamera:SetClearFlags(clearFlags, nIndex)
end

function LuaGameCamera:SetCullingMask(cullingMask, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  self.mObjGameCamera:SetCullingMask(cullingMask, nIndex)
end

function LuaGameCamera:GetCullingMask(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetCullingMask(nIndex)
end

function LuaGameCamera:SetFov(fov, nIndex)
  if self:isEnable() then
    nIndex = self:GetCamIndex(nIndex)
    self.mObjGameCamera:SetFov(fov, nIndex)
  end
end

function LuaGameCamera:GetFov(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetFov(nIndex)
end

function LuaGameCamera:SetDepth(depth, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  self.mObjGameCamera:SetDepth(depth, nIndex)
end

function LuaGameCamera:GetDepth(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetDepth(nIndex)
end

function LuaGameCamera:WorldToScreenPoint(position, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:WorldToScreenPoint(position, nIndex)
end

function LuaGameCamera:SetNearClipPlane(nearClipPlane, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  self.mObjGameCamera:SetNearClipPlane(nearClipPlane, nIndex)
end

function LuaGameCamera:GetNearClipPlane(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetNearClipPlane(nIndex)
end

function LuaGameCamera:SetFarClipPlane(farClipPlane, nIndex)
  nIndex = self:GetCamIndex(nIndex)
  self.mObjGameCamera:SetFarClipPlane(farClipPlane, nIndex)
end

function LuaGameCamera:GetFarClipPlane(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetFarClipPlane(nIndex)
end

function LuaGameCamera:GetCam(nIndex)
  nIndex = self:GetCamIndex(nIndex)
  return self.mObjGameCamera:GetCam(nIndex)
end

function LuaGameCamera:ResetToConfig()
  self.mObjGameCamera:ResetToConfig()
end

return LuaGameCamera
