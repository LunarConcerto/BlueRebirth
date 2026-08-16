local MubarCameraCtrl = class("game.CameraPosition.MubarCameraCtrl")
local OFFSET_X = -0.019
local OFFSET_Y = 0.5
local OFFSET_Z = 1.229
local InitEur = Vector3.New(45.5, 179.1, 0)
local TargetEur = Vector3.New(22, 179.1, 0)

function MubarCameraCtrl:initialize()
  self.gameCamera = GR.cameraManager:getGameCamera(GameCameraType.MubarSceneCamera)
  self.transCam = self.gameCamera:getCamTrans()
  self.transSecond = self.gameCamera:GetTransByPriority(1, index)
  self.transFirst = self.gameCamera:GetTransByPriority(0, index)
  local cameraTween = self.gameCamera:getComponent(1, TweenPosition.GetClassType())
  local secondCameraRot = self.gameCamera:getComponent(1, TweenRotation.GetClassType())
  if not cameraTween then
    self.tweenPos = self.gameCamera:addComponent(1, TweenPosition.GetClassType())
    self.secondTweenRot = self.gameCamera:addComponent(1, TweenRotation.GetClassType())
  else
    self.tweenPos = cameraTween
    self.secondTweenRot = secondCameraRot
  end
  local cameraRot = self.gameCamera:addComponent(0, TweenRotation.GetClassType())
  if not cameraRot then
    self.tweenRot = self.gameCamera:addComponent(0, TweenRotation.GetClassType())
  else
    self.tweenRot = cameraRot
  end
  self.InitPos = Vector3.NewFromTab(configManager.GetDataById("config_parameter", 405).arrValue[1])
  self.orignalLocalPos = Vector3.zero
  self.beforeTimer = nil
  self.cameraPos = nil
end

function MubarCameraCtrl:InitCamPos()
  self.transSecond.localPosition = self.InitPos
  self.transSecond.localEulerAngles = InitEur
  self.transCam.localPosition = Vector3.zero
  self.transCam.localEulerAngles = Vector3.zero
  self.transFirst.localPosition = Vector3.zero
  self.gameCamera.mObjGameCamera:SetFov(60)
end

function MubarCameraCtrl:CameraPosChange(currPos, targetPos, duration, clickChapter)
  self:StopAutoMove()
  if not clickChapter then
    self.transFirst.localEulerAngles = Vector3.zero
  end
  self.transFirst.localPosition = Vector3.zero
  if self.cameraPos ~= nil then
    self.transSecond.localPosition = Vector3.New(self.cameraPos.x + OFFSET_X, OFFSET_Y, self.cameraPos.z + OFFSET_Z)
  end
  local paramTab = {}
  if currPos == nil then
    paramTab.startPos = self.InitPos
    paramTab.startSecondAngle = InitEur
  else
    paramTab.startPos = Vector3.New(currPos[1] + OFFSET_X, OFFSET_Y, currPos[3] + OFFSET_Z)
    paramTab.startSecondAngle = TargetEur
  end
  if targetPos == nil then
    paramTab.endPos = self.InitPos
    paramTab.endSecondAngle = InitEur
  else
    paramTab.endPos = Vector3.New(targetPos[1] + OFFSET_X, OFFSET_Y, targetPos[3] + OFFSET_Z)
    self.cameraPos = Vector3.NewFromTab(targetPos)
    paramTab.endSecondAngle = TargetEur
  end
  paramTab.startAngle = self.transFirst.localEulerAngles
  paramTab.endAngle = Vector3.zero
  paramTab.duration = duration
  paramTab.palyAngleTween = clickChapter
  self.orignalLocalPos = paramTab.endPos
  self:_PlayCameraChange(paramTab)
end

function MubarCameraCtrl:_PlayCameraChange(paramTab)
  self.tweenPos:ResetToInit()
  self.tweenRot.from = Vector3.zero
  self.tweenRot:ResetToInit()
  self.secondTweenRot:ResetToInit()
  self.tweenPos.from = paramTab.startPos
  self.tweenPos.to = paramTab.endPos
  self.tweenPos.duration = paramTab.duration
  self.tweenRot.from = paramTab.startAngle
  self.tweenRot.to = paramTab.endAngle
  self.tweenRot.duration = paramTab.duration
  self.secondTweenRot.from = paramTab.startSecondAngle
  self.secondTweenRot.to = paramTab.endSecondAngle
  self.secondTweenRot.duration = paramTab.duration
  self.tweenPos:Play(true)
  self.secondTweenRot:Play(true)
  if paramTab.palyAngleTween then
    self.tweenRot:Play(true)
  end
  self.tweenPos:SetOnFinished(function()
    self:StartAutoMove(paramTab.palyAngleTween)
  end)
end

function MubarCameraCtrl:StartAutoMove(noAuto)
  if noAuto then
    return
  end
  self:StopAutoMove()
  local rotateAngle = 0
  self.beforeTimer = FrameTimer.New(function()
    if 360 <= rotateAngle then
      rotateAngle = 0
    end
    rotateAngle = rotateAngle + 0.01
    self:AutoMoveCameraByAngle(rotateAngle, self.cameraPos)
  end, 1, -1)
  self.beforeTimer:Start()
end

function MubarCameraCtrl:AutoMoveCameraByAngle(rotateAngle, targetPos)
  self.transSecond.localPosition = Vector3.zero
  local curPos = self:__getAnglePos(rotateAngle, self.orignalLocalPos, targetPos)
  self.transFirst.localPosition = curPos
  local curEur = self:__getAngleEuler(rotateAngle, Vector3(0, 0, 0))
  self.transFirst.localEulerAngles = curEur
end

function MubarCameraCtrl:__getAngleEuler(angle, orignalEuler)
  local curEuler = Vector3.New(0, angle, 0) + orignalEuler
  return curEuler
end

function MubarCameraCtrl:__getAnglePos(angle, orignalPos, targetPos)
  local startDir = orignalPos - targetPos
  local point = Quaternion.AngleAxis(angle, Vector3.up):MulVec3(startDir)
  local curPoint = point + targetPos
  return curPoint
end

function MubarCameraCtrl:StopAutoMove()
  if self.beforeTimer ~= nil then
    self.beforeTimer:Stop()
    self.beforeTimer = nil
  end
end

return MubarCameraCtrl
