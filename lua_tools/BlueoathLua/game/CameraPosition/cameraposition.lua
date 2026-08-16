local CameraPosition = class("game.CameraPosition.CameraPosition")
local TypeToInfo = {
  {
    startPos = "startPos",
    endPos = "endPos",
    startRot = "startRot",
    endRot = "endRot",
    duration = "duration"
  },
  {
    startPos = "endPos",
    endPos = "startPos",
    startRot = "endRot",
    endRot = "startRot",
    duration = "duration"
  },
  {
    startPos = "startPos",
    endPos = "animEndPos",
    startRot = "startRot",
    endRot = "animEndRot",
    duration = "animDuration"
  },
  {
    startPos = "animEndPos",
    endPos = "startPos",
    startRot = "animEndRot",
    endRot = "startRot",
    duration = "animDuration"
  }
}
local cameraForShip = {
  "modelCamera",
  "sceneCamera"
}

function CameraPosition:initialize(roomConfig, posConfig, index)
  self.gameCamera = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera)
  self.transSecond = self.gameCamera:GetTransByPriority(1, index)
  self.transFirst = self.gameCamera:GetTransByPriority(0, index)
  self.gyroCtrl = self.gameCamera:getComponent(1, GyroController.GetClassType(), index)
  self.m_configInfo = {}
  self.m_cameraPos = nil
  self.orignalLocalPos = Vector3.zero
  self.orignalLocalEur = Vector3.zero
  self.m_gyroRestoreRateScale = roomConfig.gyroRestoreRateScale
  self.m_gyroVertRotateRateScale = roomConfig.gyroVertRotateRateScale
  self.m_gyroHoriRotateRateScale = roomConfig.gyroHoriRotateRateScale
  if posConfig then
    self:__disposeConfig(posConfig, index)
  else
    logError("camera\230\149\176\230\141\174\231\188\186\229\164\177")
  end
  self.gameCamera:SetFov(roomConfig.cameraFOV, index)
  self:__SetCameraFov()
end

function CameraPosition:InitCameraPosEur(shipPos, switchType)
  if next(self.m_configInfo) == nil then
    return
  end
  local angle = PlayerPrefs.GetFloat("rotateAngle", 0)
  self:DragCameraByAngle(angle, switchType, shipPos)
  local curPos = self:__getAnglePos(0, self.orignalLocalPos, shipPos)
  self.transSecond.localPosition = curPos
  local curEur = self:__getAngleEuler(0, self.orignalLocalEur)
  self.transSecond.localEulerAngles = curEur
  self.transFirst.localPosition = Vector3.New(0, 0, 0)
  self.gyroCtrl.initEuler = curEur
  self.gyroCtrl.vertRotateRateScale = self.m_gyroVertRotateRateScale
  self.gyroCtrl.horiRotateRateScale = self.m_gyroHoriRotateRateScale
  self.gyroCtrl.restoreRateScale = self.m_gyroRestoreRateScale
end

function CameraPosition:DragCameraByAngle(rotateAngle, switchType, shipPos)
  if next(self.m_configInfo) == nil then
    return
  end
  self:__setOrignalPosEur(switchType)
  local curPos = self:__getAnglePos(rotateAngle, self.orignalLocalPos, shipPos)
  self.m_cameraPos = curPos
  local curEur = self:__getAngleEuler(rotateAngle, Vector3(0, 0, 0))
  self.transFirst.localEulerAngles = curEur
end

function CameraPosition:GetPosAndEuler(switchType)
  local posInfo = {}
  for k, v in pairs(TypeToInfo[switchType]) do
    posInfo[k] = self.m_configInfo[v]
  end
  self:__setOrignalPosEur(switchType)
  return posInfo
end

function CameraPosition:GetCameraPos()
  return self.m_cameraPos
end

function CameraPosition:__disposeConfig(modelConfig, index)
  local tab = modelConfig[cameraForShip[index]]
  for i, j in pairs(modelConfig) do
    if type(j) ~= "table" then
      tab[i] = j
    end
  end
  for i, v in pairs(tab) do
    if type(v) == "table" then
      if i ~= "endPos" then
        self.m_configInfo[i] = Vector3.NewFromTab(v)
      else
        self.m_configInfo[i] = self:__Adapt3DPosition(v, tab.cameraFOV)
      end
    else
      self.m_configInfo[i] = v
    end
  end
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  if self.m_configInfo ~= nil then
    PlayerPrefs.SetInt(uid .. "JumpHomeRightPage", 1)
  else
    PlayerPrefs.SetInt(uid .. "JumpHomeRightPage", 0)
  end
end

function CameraPosition:__getAnglePos(angle, orignalPos, shipPos)
  if shipPos == nil then
    return
  end
  local startDir = orignalPos - shipPos
  local point = Quaternion.AngleAxis(angle, Vector3.up):MulVec3(startDir)
  local curPoint = point + shipPos
  return curPoint
end

function CameraPosition:__getAngleEuler(angle, orignalEuler)
  local curEuler = Vector3.New(0, angle, 0) + orignalEuler
  return curEuler
end

function CameraPosition:__setOrignalPosEur(switchType)
  switchType = switchType == 0 and CameraSwitchType.HomeToPage or switchType
  if next(self.m_configInfo) == nil then
    return
  end
  local info = {}
  for k, v in pairs(TypeToInfo[switchType]) do
    info[k] = self.m_configInfo[v]
  end
  self.orignalLocalPos = info.endPos
  self.orignalLocalEur = info.endRot
end

function CameraPosition:__Adapt3DPosition(pos, fov)
  if ResolutionHelper.resolutionType == ResolutionType.NARROW then
    local current_resolution = Screen.width / Screen.height
    local stand_resolution = 1.7777777777777777
    local temp = stand_resolution / current_resolution
    local vp = 1 - 1 / temp
    return Vector3.NewFromTab({
      pos[1] - vp,
      pos[2],
      pos[3] - vp
    })
  else
    return Vector3.NewFromTab(pos)
  end
end

function CameraPosition:__SetCameraFov()
  if ResolutionHelper.resolutionType == ResolutionType.NARROW then
    self.gameCamera:SetFov(self.m_configInfo.cameraFOV, 1)
  end
end

return CameraPosition
