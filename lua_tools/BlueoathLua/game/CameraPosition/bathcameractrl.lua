local BathCameraCtrl = class("game.CameraPosition.BathCameraCtrl")
local TWEEN_DURATION = 0.5
local BathPosTab = {
  {
    Pos = {
      -13.946,
      0.41994,
      -4.17324
    },
    Rot = {
      6.066,
      -89.971,
      -0.075
    }
  },
  {
    Pos = {
      -15.9,
      0.18,
      -3.3
    },
    Rot = {
      6.066,
      -72.4,
      -0.075
    }
  },
  {
    Pos = {
      -16.54,
      0.2,
      -4.2
    },
    Rot = {
      6.066,
      -94.84,
      -0.075
    }
  },
  {
    Pos = {
      -16.6,
      0.2,
      -3.9
    },
    Rot = {
      6.066,
      -91.21,
      -0.075
    }
  },
  {
    Pos = {
      -15.8,
      0.24,
      -4.6
    },
    Rot = {
      6.066,
      -103.7,
      -0.075
    }
  },
  {
    Pos = {
      -15.7,
      0.17,
      -5.1
    },
    Rot = {
      6.066,
      -103.37,
      -0.075
    }
  },
  {
    Pos = {
      -16.5,
      0.28,
      -4.2
    },
    Rot = {
      6.066,
      -62.5,
      -0.075
    }
  }
}

function BathCameraCtrl:initialize()
  self.currPos = 1
  self.gameCamera = GR.cameraManager:getGameCamera(GameCameraType.BathRoomSceneCamera)
  local cameraTween = self.gameCamera:getComponent(0, TweenPosition.GetClassType())
  if not cameraTween then
    self.tweenPos = self.gameCamera:addComponent(0, TweenPosition.GetClassType())
    self.tweenRot = self.gameCamera:addComponent(0, TweenRotation.GetClassType())
  else
    self.tweenPos = cameraTween
    self.tweenRot = self.gameCamera:getComponent(0, TweenRotation.GetClassType())
  end
  self.transCam = self.gameCamera:getCamTrans()
  self.transBase = self.gameCamera:getTransBase()
end

function BathCameraCtrl:InitCamPos()
  local pos = Vector3.New(-13.946, 0.41994, -4.17324)
  local eur = Vector3.New(6.066, -89.971, -0.075)
  self.transBase.localPosition = pos
  self.transBase.localEulerAngles = eur
  self.transCam.localPosition = Vector3.zero
  self.transCam.localEulerAngles = Vector3.zero
  self.gameCamera.mObjGameCamera:SetFov(37.2991)
end

function BathCameraCtrl:CameraPosChange(shipPos)
  shipPos = shipPos + 1
  if self.currPos == shipPos then
    return
  end
  local paramTab = {}
  paramTab.startPos = Vector3.NewFromTab(BathPosTab[self.currPos].Pos)
  paramTab.endPos = Vector3.NewFromTab(BathPosTab[shipPos].Pos)
  paramTab.startRot = Vector3.NewFromTab(BathPosTab[self.currPos].Rot)
  paramTab.endRot = Vector3.NewFromTab(BathPosTab[shipPos].Rot)
  self:_PlayCameraChange(paramTab)
  self.currPos = shipPos
end

function BathCameraCtrl:_PlayCameraChange(paramTab)
  self.tweenPos:ResetToInit()
  self.tweenRot:ResetToInit()
  self.tweenPos.from = paramTab.startPos
  self.tweenPos.to = paramTab.endPos
  self.tweenPos.duration = TWEEN_DURATION
  self.tweenRot.from = paramTab.startRot
  self.tweenRot.to = paramTab.endRot
  self.tweenRot.duration = TWEEN_DURATION
  self.tweenRot:SetOnFinished(function()
    eventManager:SendEvent(LuaEvent.BathCamMoveOver)
  end)
  self.tweenPos:Play(true)
  self.tweenRot:Play(true)
end

return BathCameraCtrl
