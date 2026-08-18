local LuaGameCameraManager = class("game.LuaGameCamera.LuaGameCameraManager")

function LuaGameCameraManager:initialize()
  self.tblAllLuaCamera = {}
  self.tblAllConfig = require("config.ClientConfig.GameCameraConfig")
  self.objReqiuredCam = require("game.LuaGameCamera.LuaGameCamera")
  self.objLastGameCam = nil
end

function LuaGameCameraManager:showCamera(nType, bExclusiveness)
  if bExclusiveness == nil then
    bExclusiveness = true
  end
  if self.tblAllLuaCamera[nType] == nil then
    local tblConfig = self.tblAllConfig[nType]
    local objLuaCam = self:getNewCamerObj(tblConfig)
    objLuaCam:initData(tblConfig)
    self.tblAllLuaCamera[nType] = objLuaCam
  end
  local objCam = self.tblAllLuaCamera[nType]
  objCam:enable()
  if bExclusiveness then
    if self.objLastGameCam ~= nil and objCam ~= self.objLastGameCam then
      self.objLastGameCam:disable()
    end
    self.objLastGameCam = objCam
  end
  return objCam
end

function LuaGameCameraManager:hideCamera(nType, bCache)
  local objCam = self.tblAllLuaCamera[nType]
  if objCam == nil then
    return
  end
  if self.objLastGameCam == objCam then
    self.objLastGameCam = nil
  end
  if objCam ~= nil then
    objCam:disable()
  end
end

function LuaGameCameraManager:destroyCamera(nType, bRelease)
  if bRelease == nil then
    bRelease = false
  end
  local objCam = self.tblAllLuaCamera[nType]
  if objCam ~= nil then
    self.tblAllLuaCamera[nType] = nil
    objCam:destroy(bRelease)
  end
end

function LuaGameCameraManager:showLastCamera()
  if self.objLastGameCam ~= nil and not self.objLastGameCam:isEnable() then
    self.objLastGameCam:enable(true)
  end
end

function LuaGameCameraManager:hideLastCamera()
  if self.objLastGameCam ~= nil and self.objLastGameCam:isEnable() then
    self.objLastGameCam:disable(true)
  end
end

function LuaGameCameraManager:getGameCamera(nType)
  return self.tblAllLuaCamera[nType]
end

function LuaGameCameraManager:releaseAll()
  for k, v in pairs(self.tblAllLuaCamera) do
    self:destroyCamera(k, true)
  end
  self.tblAllLuaCamera = {}
end

function LuaGameCameraManager:getNewCamerObj(tblConfig)
  return self.objReqiuredCam:new()
end

return LuaGameCameraManager
