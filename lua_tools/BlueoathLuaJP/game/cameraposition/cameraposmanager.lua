local CameraPosManager = class("game.CameraPosition.CameraPosManager")
local cameraPosition = require("game.CameraPosition.CameraPosition")
local cameraSwitch = require("game.CameraPosition.CameraPosSwitch")
local m_type = 0
local cameraBase = {
  "modelCameraBase",
  "sceneCameraBase"
}

function CameraPosManager:initialize()
  self.m_curAngle = 0
  self.m_cameraPosTab = {}
end

function CameraPosManager:Init(roomConfig, tblConfig)
  self.m_curAngle = 0
  for i, v in ipairs(cameraBase) do
    cameraSwi = cameraSwitch:new(i)
    cameraPos = cameraPosition:new(roomConfig[cameraBase[i]], tblConfig, i)
    table.insert(self.m_cameraPosTab, {
      cameraPos = cameraPos,
      cameraSwitch = cameraSwi
    })
  end
end

function CameraPosManager:CameraPosChange(type)
  m_type = type
  for i, v in ipairs(self.m_cameraPosTab) do
    local paramTab = v.cameraPos:GetPosAndEuler(type)
    v.cameraSwitch:PlayCameraChange(paramTab, type)
  end
end

function CameraPosManager:ResetCameraPos(shipPos, type)
  m_type = type
  self.m_curAngle = 0
  logError("ResetCameraPos")
  for i, v in ipairs(self.m_cameraPosTab) do
    v.cameraPos:InitCameraPosEur(shipPos, type)
    local paramTab = v.cameraPos:GetPosAndEuler(type)
    v.cameraSwitch:CameraChangeImme(paramTab)
  end
end

function CameraPosManager:ModelChange(shipPos, type)
  m_type = type
  for i, v in ipairs(self.m_cameraPosTab) do
    v.cameraPos:InitCameraPosEur(shipPos, type)
  end
end

function CameraPosManager:DragCamera(shipPos, angle)
  self.m_curAngle = angle
  for i, v in ipairs(self.m_cameraPosTab) do
    v.cameraPos:DragCameraByAngle(self.m_curAngle, m_type, shipPos)
  end
end

function CameraPosManager:GetCameraPos()
  for i, v in ipairs(self.m_cameraPosTab) do
    if i == 2 then
      return v.cameraPos:GetCameraPos()
    end
  end
end

return CameraPosManager
