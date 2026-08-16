local vivoSDKInterface = class("game.vivoSDKInterface.vivoSDKInterface")
local MAJOR_KEY = "1"
local SCENE_KEY = "2"
local FPS_KEY = "3"
local FRAMEDROP_KEY = "4"
local QUALITYMODLE_KEY = "5"
local QUALITYEFFECT_KEY = "6"
local PLAYER_KEY = "7"
local NETLATENCY_KEY = "8"
local RESULT_KEY = "9"
local GET_SYSTEM_STATUS_KEY = "10"
local TARGET_REFRASH = "11"
local RESOLUTION_KEY = "12"
local HEIGHT_THREAD = "14"
local TEMP_KEY = "1"
local CPUCAP_KEY = "2"

function vivoSDKInterface:initialize()
  self:initSceneName()
end

function vivoSDKInterface:initSceneName()
  self.sceneNames = {}
  self.sceneNames.DEFAULT_SCENE = "0"
  self.sceneNames.LAUNCH_SCENE = "1"
  self.sceneNames.UPDATE_SCENE = "2"
  self.sceneNames.LOGIN_SCENE = "3"
  self.sceneNames.MAIN_ACTIVITY_SCENE = "4"
  self.sceneNames.LOADING_SELF_SCENE = "5"
  self.sceneNames.LOADING_OTHERS_SCENE = "6"
  self.sceneNames.GAME_SCENE = "7"
  self.sceneNames.MELEE_SCENE = "8"
  self.sceneNames.OVER_SCENE = "20"
end

function vivoSDKInterface:startFPSCounter()
  if not self:canSendSDKInfo() then
    return
  end
  if self.FPSCounter == nil then
    self.FPSCounter = require("game.FPSCounter"):new()
  end
  self.FPSCounter:start()
end

function vivoSDKInterface:checkCanSendSDKInfo()
  local isVivoNew = DeviceAdapter.isVivoNew()
  if not isVivoNew then
    return false
  end
  local strPL = platformManager:GetPL()
  if strPL ~= "vivo" then
    return false
  end
  local strDeviceModelName = SystemInfo.deviceModel
  if string.find(strDeviceModelName, "vivo") ~= nil then
    return true
  end
  return false
end

function vivoSDKInterface:canSendSDKInfo()
  return self:checkCanSendSDKInfo()
end

function vivoSDKInterface:sendToSDKImpl(strId, value)
  platformManager:SendVivoSDKinfo(strId, tostring(value))
end

function vivoSDKInterface:sendAPPVersion()
  if not self:canSendSDKInfo() then
    return
  end
  local strVersion = HotPatchFacade.PackageVersion
  self:sendToSDKImpl(MAJOR_KEY, strVersion)
end

function vivoSDKInterface:sendChangeScene(strScene)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(SCENE_KEY, strScene)
end

function vivoSDKInterface:sendFPS(nFPS)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(FPS_KEY, nFPS)
end

function vivoSDKInterface:sendLowFPS()
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(FRAMEDROP_KEY, 1)
end

function vivoSDKInterface:sendQuality(nQuality)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(QUALITYMODLE_KEY, nQuality)
  self:sendToSDKImpl(QUALITYEFFECT_KEY, nQuality)
end

function vivoSDKInterface:sendGameWin(nWin)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(RESULT_KEY, nWin)
end

function vivoSDKInterface:sendInfoType(nValue)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(GET_SYSTEM_STATUS_KEY, nValue)
end

function vivoSDKInterface:sendTargetFrameCount(nValue)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(TARGET_REFRASH, nValue)
end

function vivoSDKInterface:sendTargetDisplay(nValue)
  if not self:canSendSDKInfo() then
    return
  end
  self:sendToSDKImpl(RESOLUTION_KEY, nValue)
end

function vivoSDKInterface:sendMainThread()
  if not self:canSendSDKInfo() then
    return
  end
  local strValue = platformManager:GetTid()
  self:sendToSDKImpl(HEIGHT_THREAD, strValue)
end

return vivoSDKInterface
