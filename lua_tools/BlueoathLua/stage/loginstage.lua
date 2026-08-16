local LoginStage = class("stage.LoginStage", BaseStage)

function LoginStage:StageEnter()
  memoryUtil.LuaMemory("\232\191\155\229\133\165\231\153\187\229\189\149\231\138\182\230\128\129")
  UIHelper.CloseAllPage(true)
  UIHelper.LoadShareIcon()
  platformManager:CheckPlFunctionState()
  dataManager:ResetAllData()
  homeEnvManager:ResetTime()
  self:registerAllEvents()
  GR.guideHub:clearGuide()
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
  self:_openLoginPage()
  SoundHelper.LoadSFX()
  local funcCB = function()
    self:__trickTickDepthCamera()
  end
  self.mFrameTimer = FrameTimer.New(funcCB, 5, 1)
  self.mFrameTimer:Start()
  vivoSDKInterface:sendMainThread()
  vivoSDKInterface:sendInfoType(2)
  vivoSDKInterface:sendAPPVersion()
  vivoSDKInterface:sendChangeScene(vivoSDKInterface.sceneNames.LAUNCH_SCENE)
  vivoSDKInterface:startFPSCounter()
end

function LoginStage:__trickTickDepthCamera()
  local objCam = GameObject.Find("Depth Camera")
  if not IsNil(objCam) then
    local objDepthCam = objCam:GetComponent("DepthCamera")
    objDepthCam:LateTick()
  end
  self.mFrameTimer:Stop()
  self.mFrameTimer = nil
end

function LoginStage:_openLoginPage()
  self:OpenGroupPage({
    {
      "LoginPage",
      {},
      1,
      false
    }
  })
end

function LoginStage:_stopDelayTimer()
  if self.delayTimer ~= nil then
    self.delayTimer:Stop()
    self.delayTimer = nil
  end
end

function LoginStage:registerAllEvents()
  self:RegisterEvent(LuaEvent.LoginOk, self._LoginOk)
  self:RegisterEvent(LuaEvent.DisconnectServer, excMgr._OpenLogin)
  self:RegisterEvent(LuaEvent.UserKick, excMgr._UserKick)
end

function LoginStage:unregisterAllEvent()
  self:UnregisterAllEvent()
end

function LoginStage:_LoginOk()
  GR.guideHub:clearGuide()
  local bCanToMain = GR.guideHub:onLoginOK()
  if bCanToMain then
    stageMgr:Goto(EStageType.eStageMain)
  else
    UIHelper.ClosePage("LoginPage")
  end
  eventManager:SendEvent(LuaEvent.HERO_TryInitHeroExData)
end

function LoginStage:_closePages()
  self:CloseGroupPage({
    {
      "CreateCharacterPage"
    },
    {"LoginPage"}
  })
end

function LoginStage:StageLeave()
  self:_stopDelayTimer()
  self:_closePages()
  self:UnregisterAllEvent()
  addictionManager:InitData()
  GR.qualityManager:getSettingByType(QualityType.AntiAliasingQuality):setBattleMSAA()
  memoryUtil.LuaMemory("\231\166\187\229\188\128\231\153\187\229\189\149\231\138\182\230\128\129")
end

return LoginStage
