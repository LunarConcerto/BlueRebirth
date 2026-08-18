local HomeBathRoomState = class("Game.GameState.Home.HomeBathRoomState", require("Game.GameState.GameState"))
local super = HomeBathRoomState.super
local bathroomScene, cameraCtrl
local bathCameraCtrl = require("game.CameraPosition.BathCameraCtrl")

function HomeBathRoomState:initialize()
  super.initialize(self)
  self.m_timer = nil
  self.m_tiemlineTimer = nil
end

function HomeBathRoomState:onStart(param)
  self.m_timer = nil
  self.m_tiemlineTimer = nil
  super.onStart(self)
  self.uiCamera = UIManager.uiCamera
  GR.cameraManager:showCamera(GameCameraType.BathRoomSceneCamera)
  bathroomScene = homeEnvManager:ChangeScene(SceneType.BATHROOM)
  self.bathInterface = bathroomScene:AddComponent(BathRoomSceneInterface.GetClassType())
  TimelineHelp.PlayTimeline(bathroomScene)
  cameraCtrl = bathCameraCtrl:new()
  CS.PostProcessHud.Instance:EnableBloom(true)
  self:__registerInput()
  self:_StartTimelineTimer()
  local hasAnim = Logic.bathroomLogic:IsBathAnimEnabled()
  local isOpened = Logic.bathroomLogic:GetIsOpenBathroom()
  if not hasAnim or isOpened then
    self:_SkipFinish()
  else
    SoundManager.Instance:PlayMusic("System|Bathroom_with_intro")
    UIHelper.OpenPage("SkipScenePage", LuaEvent.SkipBathTimeline)
  end
  self.currSelectPos = 0
  self.clickDown = false
end

function HomeBathRoomState:_StartTimelineTimer()
  if self.m_tiemlineTimer == nil then
    self.m_tiemlineTimer = Timer.New(function()
      self:_CloseSkip()
      TimelineHelp.PauseTimeline(bathroomScene)
    end, 9, 1, false)
  end
  self.m_tiemlineTimer:Start()
end

function HomeBathRoomState:_StopTimelineTimer()
  if self.m_tiemlineTimer ~= nil then
    self.m_tiemlineTimer:Stop()
  end
end

function HomeBathRoomState:_initCamPos()
  cameraCtrl:InitCamPos()
end

function HomeBathRoomState:__registerInput()
  local tabParam = {
    clickDown = function(param)
      self:__onClickDown(param)
    end,
    clickUp = function(param)
      self:__onClickUp(param)
    end,
    freeClickUp = function(param)
      self:__onDragEnd(param)
    end,
    freeDragMove = function(param)
      self:__onDragMove(param)
    end,
    freeDragEnd = function(param)
      self:__onDragEnd(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function HomeBathRoomState:_StartTimer(pos)
  if self.m_timer == nil then
    self.m_timer = Timer.New(function()
      self:__sendCreatCard(pos)
    end, 0.2, 1, false)
  else
    self.m_timer:Stop()
    self.m_timer:Reset(function()
      self:__sendCreatCard(pos)
    end, 0.2, 1, false)
  end
  self.m_timer:Start()
end

function HomeBathRoomState:_StopTimer()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
  end
end

function HomeBathRoomState:__onClickDown(pos)
  self.clickDown = true
  local index = self.bathInterface:CheckCollide(pos)
  if 0 < index then
    self:_StartTimer(pos)
  end
end

function HomeBathRoomState:__sendCreatCard(pos)
  local index = self.bathInterface:CheckCollide(pos)
  local screenPos = pos
  pos = self.uiCamera:ScreenToWorldPoint(pos)
  eventManager:SendEvent(LuaEvent.BathRoomModelClick, {
    index = index,
    pos = pos,
    screenPos = screenPos
  })
end

function HomeBathRoomState:__onClickUp(pos)
  if not self.clickDown then
    return
  end
  self:_StopTimer()
  local index = self.bathInterface:CheckCollide(pos)
  self.clickDown = false
  if 0 < index then
    eventManager:SendEvent(LuaEvent.BathRoomSelectModel, {index = index, pos = pos})
  else
    eventManager:SendEvent(LuaEvent.BathRoomClickBlank)
  end
end

function HomeBathRoomState:__onDragMove(pos)
  self:_StopTimer()
  pos = self.uiCamera:ScreenToWorldPoint(pos)
  eventManager:SendEvent(LuaEvent.BathRoomDrag, pos)
end

function HomeBathRoomState:__onDragEnd(pos)
  local index = self.bathInterface:CheckCollide(pos)
  local screenPos = pos
  pos = self.uiCamera:ScreenToWorldPoint(pos)
  eventManager:SendEvent(LuaEvent.BathRoomDragEnd, {
    index = index,
    pos = pos,
    screenPos = screenPos
  })
end

function HomeBathRoomState:onEnd()
  super.onEnd(self)
  self.m_timer = nil
  self.m_tiemlineTimer = nil
  GR.cameraManager:hideLastCamera()
  TimelineHelp.Clear()
  inputManager:UnregisterAllInput(self)
  CS.PostProcessHud.Instance:EnableBloom(false)
  self.currSelectPos = 0
  cameraCtrl = nil
  self.clickDown = false
end

function HomeBathRoomState:registerAllEvents()
  self:registerEvent(LuaEvent.SkipBathTimeline, self._SkipFinish)
end

function HomeBathRoomState:_SkipFinish()
  TimelineHelp.PauseTimeline(bathroomScene)
  self:_StopTimelineTimer()
  self:_CloseSkip()
end

function HomeBathRoomState:_CloseSkip()
  self:_StopTimelineTimer()
  local hasAnim = Logic.bathroomLogic:IsBathAnimEnabled()
  local isOpened = Logic.bathroomLogic:GetIsOpenBathroom()
  if hasAnim and not isOpened then
    UIHelper.Back()
  end
  eventManager:SendEvent(LuaEvent.BathRoomShowUI)
  self:_initCamPos()
end

function HomeBathRoomState:GetSceneObj()
  return bathroomScene
end

function HomeBathRoomState:GetScreenPoint(pos)
  local gameCamera = GR.cameraManager:getGameCamera(GameCameraType.BathRoomSceneCamera)
  local screenPos = gameCamera:WorldToScreenPoint(pos)
  local point = UIManager.uiCamera:ScreenToWorldPoint(screenPos)
  return point
end

function HomeBathRoomState:ChangeCamera(param)
  cameraCtrl:CameraPosChange(param)
end

return HomeBathRoomState
