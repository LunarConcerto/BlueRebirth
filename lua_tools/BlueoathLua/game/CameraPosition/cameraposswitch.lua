local CameraPosSwitch = class("game.CameraPosition.CameraPosSwitch")

function CameraPosSwitch:initialize(index)
  self.gameCamera = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera)
  local cameraTween = self.gameCamera:getComponent(1, TweenPosition.GetClassType(), index)
  if not cameraTween then
    self.tweenPos = self.gameCamera:addComponent(1, TweenPosition.GetClassType(), index)
    self.tweenRot = self.gameCamera:addComponent(1, TweenRotation.GetClassType(), index)
    self.gyroCtrl = self.gameCamera:addComponent(1, GyroController.GetClassType(), index)
  else
    self.tweenPos = cameraTween
    self.tweenRot = self.gameCamera:getComponent(1, TweenRotation.GetClassType(), index)
    self.gyroCtrl = self.gameCamera:getComponent(1, GyroController.GetClassType(), index)
  end
  self.transCam = self.gameCamera:GetTransByPriority(1, index)
end

function CameraPosSwitch:PlayCameraChange(paramTab, mType)
  self.tweenPos:ResetToInit()
  self.tweenRot:ResetToInit()
  self.tweenPos.from = paramTab.startPos
  self.tweenPos.to = paramTab.endPos
  self.tweenPos.duration = paramTab.duration
  self.tweenRot.from = paramTab.startRot
  self.tweenRot.to = paramTab.endRot
  self.tweenRot.duration = paramTab.duration
  self.curType = mType
  self.tweenRot:SetOnFinished(function()
    self.gyroCtrl.initEuler = paramTab.endRot
  end)
  self.tweenPos:Play(true)
  self.tweenRot:Play(true)
end

function CameraPosSwitch:CameraChangeImme(paramTab)
  self.transCam.localPosition = paramTab.endPos
  self.transCam.localEulerAngles = paramTab.endRot
end

return CameraPosSwitch
