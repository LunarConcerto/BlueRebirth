local HomeInfrastructureState = class("Game.GameState.Home.HomeInfrastructureState", require("Game.GameState.GameState"))
local super = HomeInfrastructureState.super
local infrasScene
local InfrastructureMap = {
  [MBuildingType.Office] = SceneType.Office,
  [MBuildingType.ElectricFactory] = SceneType.ElectricFactory,
  [MBuildingType.OilFactory] = SceneType.OilFactory,
  [MBuildingType.ResourceFactory] = SceneType.ResourceFactory,
  [MBuildingType.DormRoom] = SceneType.DormRoom,
  [MBuildingType.FoodFactory] = SceneType.FoodFactory,
  [MBuildingType.ItemFactory] = SceneType.ItemFactory
}
local InfrastructureCameraMap = {
  [MBuildingType.Office] = GameCameraType.OfficeSceneCamera,
  [MBuildingType.ElectricFactory] = GameCameraType.ElectricFactorySceneCamera,
  [MBuildingType.OilFactory] = GameCameraType.OilFactorySceneCamera,
  [MBuildingType.ResourceFactory] = GameCameraType.ResourceFactorySceneCamera,
  [MBuildingType.DormRoom] = GameCameraType.DormRoomSceneCamera,
  [MBuildingType.FoodFactory] = GameCameraType.FoodFactorySceneCamera,
  [MBuildingType.ItemFactory] = GameCameraType.ItemFactorySceneCamera
}

function HomeInfrastructureState:initialize()
  super.initialize(self)
end

function HomeInfrastructureState:onStart(param)
  super.onStart(self)
  local objCam = GR.cameraManager:showCamera(InfrastructureCameraMap[param.btype])
  objCam:ResetToConfig()
  local index = Data.buildingData:GetDormIndex(param.buildingId)
  infrasScene = homeEnvManager:ChangeScene(InfrastructureMap[param.btype], false, {index = index})
  GR.baseBuilding3DManager:Init(param.models)
end

function HomeInfrastructureState:onEnd()
  super.onEnd(self)
  GR.baseBuilding3DManager:Clear()
end

return HomeInfrastructureState
