local HomeMarryState = class("Game.GameState.Home.HomeMarryState", require("Game.GameState.GameState"))
local super = HomeMarryState.super
local sceneShot = 10

function HomeMarryState:initialize()
  super.initialize(self)
end

function HomeMarryState:onStart(param)
  super.onStart(self)
  self.m_timer = nil
  self.m_scene = homeEnvManager:ChangeScene(SceneType.MARRY)
  self.heroInfo = param
end

function HomeMarryState:_play()
  local heroInfo = self.heroInfo
  local ship = Logic.shipLogic:GetDefaultShipShowById(heroInfo.TemplateId)
  local param = {
    showID = ship.ss_id,
    dressID = configManager.GetDataById("config_ship_model", ship.model_id).standard_normal,
    girlType = GirlType.Marry
  }
  self:_createShipGirl(param)
  local modle = Logic.shipLogic:GetHeroModelConfigById(ship.model_id)
  self:__initCamera(modle .. "_marry")
end

function HomeMarryState:onEnd()
  super.onEnd(self)
  self:__clearCamera()
  if self.m_timer ~= nil then
    self:_StopTimer()
  end
  if self.shipGirlObj then
    GR.shipGirlManager:destroyShipGirl(self.shipGirlObj)
    self.shipGirlObj = nil
  end
end

function HomeMarryState:__initCamera(camGroupID)
  local gameCamera = GR.cameraManager:showCamera(GameCameraType.MarrySceneCamera)
  GR.sceneManager:ApplyScenePostProcess()
  local cam0 = gameCamera:GetCamObjByIndex(0)
  local cam1 = gameCamera:GetCamObjByIndex(1)
  local camDest = gameCamera:GetCamObjByIndex(2)
  self.m_shotFade = camDest:GetCamTrans().gameObject:AddComponent(CS.CameraShotFade.GetClassType())
  self.m_shotFade:Init(camGroupID, self.shipGirlTrans, cam0, cam1, camDest)
  self.m_shotFade:Play()
end

function HomeMarryState:__clearCamera()
  GameObject.Destroy(self.m_shotFade)
  self.m_shotFade = nil
  GR.cameraManager:destroyCamera(GameCameraType.MarrySceneCamera, true)
end

function HomeMarryState:_StartTimer(duration)
  if self.m_timer == nil then
    self.m_timer = Timer.New(function()
      self:_SkipFinish()
    end, duration, 1, false)
  end
  self.m_timer:Start()
end

function HomeMarryState:registerAllEvents()
  self:registerEvent(LuaEvent.PlayMarry, self._play)
end

function HomeMarryState:_SkipFinish()
  self:_StopTimer()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.MARRY
  })
end

function HomeMarryState:_StopTimer()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
  end
  self.m_timer = nil
end

function HomeMarryState:_createShipGirl(param)
  self.shipGirlObj = GR.shipGirlManager:createShipGirl(param, LayerMask.NameToLayer("MainSceneShip"))
  self.modelName = self.shipGirlObj.resName
  self.shipName = configManager.GetDataById("config_ship_show", self.shipGirlObj.showID).ship_name
  self.shipGirlTrans = self.shipGirlObj.transform
  local marry_girl_3d_position = configManager.GetDataById("config_parameter", 190).arrValue
  self.shipGirlTrans.localPosition = Vector3.NewFromTab(marry_girl_3d_position)
  local marry_girl_3d_rotation = configManager.GetDataById("config_parameter", 193).arrValue
  self.shipGirlTrans.localEulerAngles = Vector3.NewFromTab(marry_girl_3d_rotation)
  self:__playAnim()
end

function HomeMarryState:__playAnim()
  local animName = configManager.GetDataById("config_parameter", 192).arrValue[1]
  self.shipGirlObj:playBehaviour(animName, false, function()
    eventManager:SendEvent(LuaEvent.MarryOpenPlot, {})
    self:_SkipFinish()
  end)
end

return HomeMarryState
