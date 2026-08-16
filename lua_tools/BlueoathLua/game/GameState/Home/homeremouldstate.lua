local HomeRemouldState = class("Game.GameState.Home.HomeRemouldState", require("Game.GameState.GameState"))
local super = HomeRemouldState.super
local InitCorePos = {
  -2.48,
  0.3,
  -13.1
}
local sceneObj, modelObj

function HomeRemouldState:initialize()
  super.initialize(self)
  self.timer = nil
  self.OpenSkip = false
end

function HomeRemouldState:registerAllEvents()
  self:registerEvent(LuaEvent.SkipRemouldScene, self._SkipFinish)
end

function HomeRemouldState:onStart(param)
  super.onStart(self)
  self.gameCamera = GR.cameraManager:showCamera(GameCameraType.RemouldSceneCamera)
  sceneObj = homeEnvManager:ChangeScene(SceneType.Remould, true, {index = param})
  self.m_camera = self.gameCamera:GetCam()
  self.transCam = self.gameCamera:getCamTrans()
  self.transCam.localPosition = self:_Adapt3DPosition(InitCorePos)
  self:CreateCoreModel(param)
  self:_ShowSceneAnimation(param)
end

function HomeRemouldState:onEnd()
  super.onEnd(self)
  sceneObj = nil
  self.gameCamera = nil
  self.m_camera = nil
  self:_DestroyCoreModel()
end

function HomeRemouldState:_StartTimer(callback, duration)
  self.timer = Timer.New(function()
    if callback then
      callback()
    end
  end, duration, 1, false)
  self.timer:Start()
  return self.timer
end

function HomeRemouldState:_NormalFinish()
  if self.OpenSkip then
    UIHelper.Back()
  end
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.REMOULD
  })
  eventManager:SendEvent(LuaEvent.OpenRemouldPage)
end

function HomeRemouldState:_SkipFinish()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self:_NormalFinish()
end

function HomeRemouldState:CreateCoreModel(index)
  self:_DestroyCoreModel()
  local modelPath = Logic.remouldLogic:GetRemouldModelById(tostring(index)).model
  modelObj = GR.objectPoolManager:LuaGetGameObject(modelPath)
  modelObj.transform:SetParent(sceneObj.transform, false)
end

function HomeRemouldState:_DestroyCoreModel()
  if modelObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(modelObj)
    modelObj = nil
  end
end

function HomeRemouldState:_ShowSceneAnimation(param)
  local scenePath = Logic.remouldLogic:GetRemouldModelById(tostring(param)).animation
  if scenePath ~= "" then
    self.OpenSkip = Logic.remouldLogic:CheckSceneAnimRecorded(param)
    if self.OpenSkip then
      UIHelper.OpenPage("SkipScenePage", LuaEvent.SkipRemouldScene)
    end
    self:_StartTimer(function()
      self:_NormalFinish()
    end, 11)
  end
end

function HomeRemouldState:_Adapt3DPosition(pos)
  local radio = string.format("%.2f", ResolutionHelper.real2Standard)
  if tonumber(radio) <= 1 then
    return Vector3.NewFromTab({
      pos[1] * radio,
      pos[2],
      pos[3]
    })
  else
    return Vector3.NewFromTab({
      pos[1] * radio - 0.34,
      pos[2],
      pos[3]
    })
  end
end

return HomeRemouldState
