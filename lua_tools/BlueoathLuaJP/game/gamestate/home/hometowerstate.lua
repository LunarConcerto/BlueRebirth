local HomeTowerState = class("Game.GameState.Home.HomeTowerState", require("Game.GameState.GameState"))
local super = HomeTowerState.super

function HomeTowerState:initialize()
  super.initialize(self)
end

function HomeTowerState:registerAllEvents()
  self:registerEvent(LuaEvent.TowerMove, self._towerMove)
end

function HomeTowerState:onStart(param)
  super.onStart(self)
  self.m_scene = homeEnvManager:ChangeScene(SceneType.TOWER)
  self.gameCamera = GR.cameraManager:showCamera(GameCameraType.TowerSceneCamera)
  self.m_camera = self.gameCamera:GetCam()
  Logic.towerLogic:SetTowerCamera(self.gameCamera)
end

function HomeTowerState:onEnd()
  super.onEnd(self)
  self.m_scene = nil
  self.gameCamera = nil
  self.m_camera = nil
end

function HomeTowerState:_towerMove(param)
  if param == 0 then
    return
  end
  local pos = self.m_camera.transform.localPosition
  self.m_camera.transform.localPosition = Vector3.New(pos.x, pos.y, pos.z - param)
end

return HomeTowerState
