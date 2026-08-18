local LuaGameCameraGroup = class("Game.LuaGameCamera.LuaGameCameraGroup")

function LuaGameCameraGroup:initialize()
  self.tblConfig = nil
  self.tblCameras = {}
end

function LuaGameCameraGroup:initData(tblConfig)
  self.tblConfig = tblConfig
  self:__initSubCameras()
end

function LuaGameCameraGroup:__initSubCameras()
  local tblSubCameras = self.tblConfig.subCameras
  local nCount = #tblSubCameras
  for i = 1, nCount do
    local tblConfig = tblSubCameras[i]
    local objCamera = GR.cameraManager:getNewCamerObj(tblConfig)
    self.tblCameras[i] = objCamera
    objCamera:initData(tblConfig)
  end
end

function LuaGameCameraGroup:enable(bUseCache)
  self.bEnable = true
  for k, v in pairs(self.tblCameras) do
    v:enable(bUseCache)
  end
end

function LuaGameCameraGroup:disable()
  self.bEnable = false
  for k, v in pairs(self.tblCameras) do
    v:disable()
  end
end

function LuaGameCameraGroup:destroy(bRelease)
  self.bEnable = false
  for k, v in pairs(self.tblCameras) do
    v:destroy(bRelease)
  end
end

function LuaGameCameraGroup:getTransBase(nIndex)
  return self.tblCameras[nIndex]:getTransBase()
end

function LuaGameCameraGroup:getCamTrans(nIndex)
  return self.tblCameras[nIndex]:GetCamTrans()
end

function LuaGameCameraGroup:getComponent(nPriority, objType, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  return self.tblCameras[nIndex]:getComponent(nPriority, objType)
end

function LuaGameCameraGroup:addComponent(nPriority, objType, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  return self.tblCameras[nIndex]:addComponent(nPriority, objType)
end

function LuaGameCameraGroup:GetTransByPriority(nPriority, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  return self.tblCameras[nIndex]:GetTransByPriority(nPriority)
end

function LuaGameCameraGroup:WorldToScreenPoint(pos, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  return self.tblCameras[nIndex]:WorldToScreenPoint(pos)
end

function LuaGameCameraGroup:SetNearClipPlane(nValue, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  self.tblCameras[nIndex].mObjGameCamera.nearClipPlane = nValue
end

function LuaGameCameraGroup:GetNearClipPlane(nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  return self.tblCameras[nIndex].mObjGameCamera.nearClipPlane
end

function LuaGameCameraGroup:SetFieldOfView(nValue, nIndex)
  if nIndex == nil then
    nIndex = 1
  end
  self.tblCameras[nIndex].mObjGameCamera.fieldOfView = nValue
end

function LuaGameCameraGroup:GetCSCamObj(nIndex)
  return self.tblCameras[nIndex].mObjGameCamera
end

return LuaGameCameraGroup
