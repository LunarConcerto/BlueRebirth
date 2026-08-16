local HomeBuildState = class("Game.GameState.Home.HomeBuildState", require("Game.GameState.GameState"))
local super = HomeBuildState.super
local shotIndex = 1
local sceneShot = {
  {
    SR = {type = 1, time = 10},
    SSR = {type = 2, time = 15},
    EQUIP = {type = 3, time = 5}
  },
  {
    SR = {type = 1, time = 10},
    SSR = {type = 2, time = 15},
    EQUIP = {type = 3, time = 5}
  }
}
local equipEffects = {
  SSR = {
    "effects/prefabs/eff2d_buildequip_light_yellow_1",
    "effects/prefabs/eff2d_buildequip_light_yellow_2",
    "effects/prefabs/eff2d_buildequip_light_yellow_3",
    "effects/prefabs/eff2d_buildequip_light_yellow_4"
  },
  SR = {
    "effects/prefabs/eff2d_buildequip_light_violet_1",
    "effects/prefabs/eff2d_buildequip_light_violet_2",
    "effects/prefabs/eff2d_buildequip_light_violet_3",
    "effects/prefabs/eff2d_buildequip_light_violet_4"
  }
}

function HomeBuildState:initialize()
  super.initialize(self)
  self.BehaviorResult = 0
  self.BehaviorStartTime = 0
  self.BehaviorEndTime = 0
  self.ShipName = nil
  self:__clearObj()
  self.buildScene = nil
  self.reflects = nil
end

function HomeBuildState:onStart(param)
  super.onStart(self)
  UIHelper.OpenPage("SkipScenePage", LuaEvent.SkipBuildScene)
  SoundManager.Instance:PlayMusic("Role_unlock")
  self.gameCamera = GR.cameraManager:showCamera(GameCameraType.BuildSceneCamera)
  self.buildScene = homeEnvManager:ChangeScene(SceneType.BUILD)
  self.reflects = self.buildScene:GetComponentsInChildren(ReflectUseBase.GetClassType())
  for i = 0, self.reflects.Length - 1 do
    self.reflects[i].enabled = false
  end
  self:_SetTimeline()
end

function HomeBuildState:_SetTimeline()
  local sceneType = Logic.homeLogic:GetDefaultScene()
  local timelineTab = sceneShot[sceneType]
  local haveSSR, buildType = Logic.buildShipLogic:GetHaveSSR()
  local timelineInfo
  if buildType == ExtractType.SHIP then
    timelineInfo = haveSSR == true and timelineTab.SSR or timelineTab.SR
  elseif buildType == ExtractType.EQUIP then
    timelineInfo = timelineTab.EQUIP
  end
  self.haveSSR = haveSSR
  self.buildType = buildType
  local buildShotCtrl = self.buildScene:GetComponent(BuildShotCtrl.GetClassType())
  if buildType == ExtractType.EQUIP then
    local nodes = buildShotCtrl:GetEquipEffectNodes()
    self:CreateEquipEffects(haveSSR, nodes)
  end
  buildShotCtrl:PlayShot(timelineInfo.type)
  self.gameCamera:SetNearClipPlane(0.1)
  local dotInfo = {
    info = "ui_explore_animation"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  self:_StartTimer(function()
    self:_NormalFinish()
  end, timelineInfo.time)
  if buildType == ExtractType.EQUIP then
    SoundManager.Instance:PlayAudio("Effect_zhuangbeibox_open")
    local openDuration = 1
    self:_StartTimer(function()
      if self.haveSSR then
        SoundManager.Instance:PlayAudio("Effect_zhuangbeibox_ssr")
      else
        SoundManager.Instance:PlayAudio("Effect_zhuangbeibox_sr")
      end
    end, 2.1 + openDuration)
  end
end

function HomeBuildState:CreateEquipEffects(haveSSR, nodes)
  if #nodes < 4 then
    logError("CreateEquipEffects effect nodes count < 4" .. printTable(nodes))
    return
  end
  self.effObjs = {}
  local effs = {}
  if haveSSR then
    effs = equipEffects.SSR
  else
    effs = equipEffects.SR
  end
  for i, eff in ipairs(effs) do
    local node = nodes[i]
    local obj = UIHelper.CreateUIEffect(eff, node)
    table.insert(self.effObjs, obj)
  end
end

function HomeBuildState:ClearEquipEffects()
  for i, obj in ipairs(self.effObjs) do
    UIHelper.DestroyUIEffect(obj)
  end
  self.effObjs = {}
end

function HomeBuildState:_StartTimer(callback, duration)
  self.timers = self.timers or {}
  local timer = Timer.New(function()
    if callback then
      callback()
    end
  end, duration, 1, false)
  timer:Start()
  table.insert(self.timers, timer)
  return timer
end

function HomeBuildState:_StopTimer()
  if self.timers ~= nil then
    for i, timer in ipairs(self.timers) do
      timer:Stop()
    end
  end
  self.timers = nil
end

function HomeBuildState:onEnd()
  super.onEnd(self)
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
  self.gameCamera:SetNearClipPlane(0.3)
  GR.cameraManager:hideLastCamera()
  for i = 0, self.reflects.Length - 1 do
    self.reflects[i].enabled = true
  end
  if self.shipGirlObj then
    GR.shipGirlManager:destroyShipGirl(self.shipGirlObj)
  end
  UIHelper.SetUILock(false)
  if self.co ~= nil then
    coroutine.stop(self.co)
  end
  self:__clearObj()
  self:_StopTimer()
end

function HomeBuildState:registerAllEvents()
  self:registerEvent(LuaEvent.SkipBuildScene, self._SkipFinish)
  self:registerEvent(LuaEvent.DisconnectServer, self._PauseTimeLine)
  self:registerEvent(LuaEvent.UserKick, self._PauseTimeLine)
end

function HomeBuildState:_PauseTimeLine()
  if self.buildScene ~= nil then
    local buildShotCtrl = self.buildScene:GetComponent(BuildShotCtrl.GetClassType())
    buildShotCtrl:StopShot()
  end
end

function HomeBuildState:_ConnectOk()
end

function HomeBuildState:__clearObj()
  self.gameCamera = nil
  self.shipGirlObj = nil
end

function HomeBuildState:_SkipFinish()
  if self.buildType == ExtractType.EQUIP then
    self:ClearEquipEffects()
  else
    self:_PauseTimeLine()
  end
  self:_Show2DShip()
end

function HomeBuildState:_NormalFinish()
  if self.buildType == ExtractType.EQUIP then
    self:ClearEquipEffects()
  else
    self:_PauseTimeLine()
  end
  self:_Show2DShip()
end

function HomeBuildState:_Show2DShip()
  self:_StopTimer()
  if self.buildType == ExtractType.SHIP then
    eventManager:SendEvent(LuaEvent.HomeSwitchState, {
      HomeStateID.MAIN,
      HomeStateID.BUILD
    })
    UIHelper.Back()
  else
    local rewards = Logic.buildShipLogic:GetExtractReward()
    if rewards then
      UIHelper.OpenPage("GetRewardsPage", {
        Rewards = rewards,
        Page = "BuildShipPage",
        DontMerge = true,
        callBack = function()
          self:_PauseTimeLine()
          eventManager:SendEvent(LuaEvent.HomeSwitchState, {
            HomeStateID.MAIN,
            HomeStateID.BUILD
          })
          UIHelper.Back()
        end
      })
    else
      eventManager:SendEvent(LuaEvent.HomeSwitchState, {
        HomeStateID.MAIN,
        HomeStateID.BUILD
      })
      UIHelper.Back()
    end
  end
end

return HomeBuildState
