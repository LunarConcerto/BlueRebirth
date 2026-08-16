local LuaGameCameraManager = class("game.LuaGameCamera.LuaGameCameraManager")

function LuaGameCameraManager:initialize()
  self.tblTypeExclusiveCams = {}
  self.tblInsCams = {}
  self.tblAllConfig = require("config.ClientConfig.GameCameraConfig")
  self.objReqiuredCam = require("game.LuaGameCamera.LuaGameCamera")
  self.objLastGameCam = nil
end

function LuaGameCameraManager:showCamera(nType, bExclusiveness)
  if bExclusiveness == nil then
    bExclusiveness = true
  end
  if self.tblTypeExclusiveCams[nType] == nil then
    local tblConfig = self.tblAllConfig[nType]
    local objLuaCam = self:getNewCamerObj(tblConfig)
    objLuaCam:initData(tblConfig)
    self.tblTypeExclusiveCams[nType] = objLuaCam
  end
  local objCam = self.tblTypeExclusiveCams[nType]
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
  local objCam = self.tblTypeExclusiveCams[nType]
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
  local objCam = self.tblTypeExclusiveCams[nType]
  if objCam ~= nil then
    self.tblTypeExclusiveCams[nType] = nil
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
  return self.tblTypeExclusiveCams[nType]
end

function LuaGameCameraManager:createTypeCamIns(nType)
  local tblConfig = self.tblAllConfig[nType]
  local objLuaCam = self:getNewCamerObj(tblConfig)
  objLuaCam:initData(tblConfig)
  objLuaCam:enable()
  table.insert(self.tblInsCams, objLuaCam)
  return objLuaCam
end

function LuaGameCameraManager:destroyTypeCamIns(objLuaCam)
  if objLuaCam == nil then
    return
  end
  for k, v in pairs(self.tblInsCams) do
    if v == objLuaCam then
      self.tblInsCams[k] = nil
    end
  end
  objLuaCam:destroy(true)
end

function LuaGameCameraManager:enableInsCam(objLuaCam)
  if objLuaCam == nil then
    return
  end
  objLuaCam:enable()
end

function LuaGameCameraManager:disableInsCam(objLuaCam)
  if objLuaCam == nil then
    return
  end
  objLuaCam:disable()
end

function LuaGameCameraManager:releaseAll()
  for k, v in pairs(self.tblTypeExclusiveCams) do
    self:destroyCamera(k, true)
  end
  self.tblTypeExclusiveCams = {}
  for k, v in pairs(self.tblInsCams) do
    if v ~= nil then
      v:destroy(true)
    end
  end
  self.tblInsCams = {}
end

function LuaGameCameraManager:getNewCamerObj(tblConfig)
  return self.objReqiuredCam:new()
end

return LuaGameCameraManager
