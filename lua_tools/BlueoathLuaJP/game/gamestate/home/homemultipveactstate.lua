local HomeMultiPveActState = class("Game.GameState.Home.HomeMultiPveActState", require("Game.GameState.GameState"))
local super = HomeMultiPveActState.super

function HomeMultiPveActState:initialize()
  super.initialize(self)
  self.gameCamera = nil
  self.scene = nil
end

function HomeMultiPveActState:registerAllEvents()
end

function HomeMultiPveActState:onStart()
  super.onStart(self)
  self.gameCamera = GR.cameraManager:showCamera(GameCameraType.MultiPveSceneCamera)
  self.scene = homeEnvManager:ChangeScene(SceneType.MultiPveAct)
end

function HomeMultiPveActState:onEnd()
  super.onEnd(self)
  self.gameCamera = nil
  self.scene = nil
end

return HomeMultiPveActState
