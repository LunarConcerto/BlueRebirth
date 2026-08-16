local MainStage = class("stage.MainStage", BaseStage)

function MainStage:initialize()
  self.states = require("Game.GameState.GameStateManager"):new()
  local statePath = {
    "Game.GameState.GameState",
    "Game.GameState.Home.HomeMainState",
    "Game.GameState.Home.HomeStudyState",
    "Game.GameState.Home.HomeBuildState",
    "Game.GameState.Home.HomeBathRoomState",
    "Game.GameState.Home.HomeMarryState",
    "Game.GameState.Home.HomeInfrastructureState",
    "Game.GameState.Home.HomeTowerState",
    "Game.GameState.Home.HomeMiniGameState",
    "Game.GameState.Home.HomeRemouldState",
    "Game.GameState.Home.HomeMubarState",
    "Game.GameState.Home.HomeMultiPveActState"
  }
  self.states:init(statePath)
end

function MainStage:StageEnter(lastPage, enterParam)
  memoryUtil.LuaMemory("\232\191\155\229\133\165Main\231\138\182\230\128\129")
  self:RegisterEvent(LuaEvent.HomeSwitchState, self.__switchState, self)
  self:RegisterEvent(LuaEvent.DisconnectServer, self.__disconnectServer, self)
  self:RegisterEvent(LuaEvent.UserKick, excMgr._UserKick)
  self:__switchState({
    HomeStateID.MAIN
  })
  addictionManager:Addiction()
  local tabTemp = {}
  if lastPage == EStageType.eStageLogin then
    eventManager:SendEvent(LuaEvent.PushAllNotice)
    tabTemp[1] = {"HomePage", "firstLogin"}
  elseif lastPage == EStageType.eStageSimpleBattle then
    local beStrongData = Logic.beStrongLogic:GetStrongPageData()
    if beStrongData then
      if beStrongData.name then
        UIHelper.OpenPage(beStrongData.name, beStrongData.param)
      end
      if beStrongData.callback then
        beStrongData.callback()
      end
    else
      self:HideUIs()
    end
  elseif lastPage == EStageType.eStagePvpBattle then
    local beStrongData = Logic.beStrongLogic:GetStrongPageData()
    if beStrongData then
      if beStrongData.name then
        UIHelper.OpenPage(beStrongData.name, beStrongData.param)
      end
      if beStrongData.callback then
        beStrongData.callback()
      end
    else
      self:HideUIs()
    end
  elseif lastPage == EStageType.eStageReplayBattle then
    UIHelper.OpenPage("HomePage")
  elseif lastPage == EStageType.eStageResumeBattle then
    UIHelper.OpenPage("HomePage")
  end
  self:OpenGroupPage(tabTemp)
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.ENTER_MAINSTAGE)
  local result = Logic.loginLogic:CheckUserKick()
  if result ~= nil and result then
    eventManager:SendEvent(LuaEvent.UserKick)
  end
  if Socket.curState == SocketConnState.Disconnected then
    eventManager:SendEvent(LuaEvent.DisconnectServer)
  end
  GR.qualityManager:getSettingByType(QualityType.AntiAliasingQuality):setNonBattleMSAA()
  QualitySettings.blendWeights = BlendWeights.FourBones
  Shader.globalMaximumLOD = GR.qualityManager:getShaderLod()
  Physics.autoSyncTransforms = true
  vivoSDKInterface:sendChangeScene(vivoSDKInterface.sceneNames.MAIN_ACTIVITY_SCENE)
end

function MainStage:HideUIs()
  local topPage = UIPageManager:GetCurrFullScreenPage()
  if topPage == "LevelDetailsPage" then
    UIHelper.ClosePage("LevelDetailsPage")
  elseif topPage == "TrainLevelPage" then
    UIHelper.ClosePage("FleetPage")
    UIHelper.ClosePage("CommonHeroPage")
  end
end

function MainStage:StageLeave()
  self:__switchState({
    HomeStateID.NULL
  })
  GR.shipGirlManager:clear()
  RetentionHelper.SkipAllBehaviour()
  self:UnregisterAllEvent()
  if UnityEngine.Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
    local large, middle, patch = string.match(UnityEngine.SystemInfo.operatingSystem, "(%d+).(%d+)")
    local ver = math.tointeger(large)
    if ver < 11 then
      local lv = GR.qualityManager:getQualityLvByType(QualityType.ShaderQuality)
      if 1 < lv then
        GR.qualityManager:setQualityLvByType(1, QualityType.ShaderQuality)
      end
    end
  end
  QualitySettings.blendWeights = GR.qualityManager:getQualityLvByType(QualityType.ActionQuality)
  Shader.globalMaximumLOD = GR.qualityManager:getShaderLod() - 1
  GR.qualityManager:getSettingByType(QualityType.AntiAliasingQuality):setBattleMSAA()
  memoryUtil.LuaMemory("\231\166\187\229\188\128Main\231\138\182\230\128\129")
  Physics.autoSyncTransforms = false
end

function MainStage:__switchState(param)
  self.states:switchState(param[1], param[2])
end

function MainStage:__disconnectServer()
  excMgr._OpenLogin()
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, true)
end

return MainStage
