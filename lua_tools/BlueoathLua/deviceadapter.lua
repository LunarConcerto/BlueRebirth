DeviceAdapter = {}
local DeviceQuality = require("game.Quality.Config.DeviceQuality")
local GPUQuality = require("game.Quality.Config.GPUQuality")
local deviceConf, gpuConf
local isInit = false

function DeviceAdapter.getDefaultQuality()
  if not isInit then
    DeviceAdapter.init()
    isInit = true
  end
  if isEditor or isWindows then
    return GlobalQuality.SuperHigh
  end
  if deviceConf and deviceConf.level then
    return deviceConf.level
  end
  if gpuConf then
    return gpuConf.level
  end
  return GlobalQuality.High
end

function DeviceAdapter.init()
  local deviceModel = SystemInfo.deviceModel
  for k, v in pairs(DeviceQuality) do
    if string.find(deviceModel, k) ~= nil then
      deviceConf = v
      break
    end
  end
  local graphicsDeviceName = SystemInfo.graphicsDeviceName
  for k, v in pairs(GPUQuality) do
    if string.find(graphicsDeviceName, k) ~= nil then
      gpuConf = v
      break
    end
  end
end

function DeviceAdapter.isInstancingBug()
  if deviceConf and deviceConf.instancingBug then
    return deviceConf.instancingBug == 1
  end
  return gpuConf and gpuConf.instancingBug == 1
end

function DeviceAdapter.isRGBAHalfClose()
  if not isAndroid then
    return false
  end
  local seniorInfo = PlatformWrapper:GetSensorInfo()
  local isTiantian = string.find(string.lower(seniorInfo), "tiantianvm") ~= nil
  return isTiantian and SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES2
end

function DeviceAdapter.isForceARGBHalf()
  if gpuConf and gpuConf.forceARGBHalf then
    return gpuConf.forceARGBHalf == 1
  end
  return false
end

function DeviceAdapter.needOriginDepth()
  if deviceConf and deviceConf.needOriginDepth then
    return deviceConf.needOriginDepth == 1
  end
  return false
end

function DeviceAdapter.getUnsafeOffset()
  if deviceConf and deviceConf.unsafeOffset then
    return deviceConf.unsafeOffset
  end
  return 0
end

function DeviceAdapter.getHighFps()
  if deviceConf and deviceConf.highFps then
    return deviceConf.highFps
  end
  return 0
end

function DeviceAdapter.getHideAR()
  if deviceConf and deviceConf.hideAR then
    return deviceConf.hideAR == 1
  end
  return false
end

function DeviceAdapter.isForceLow()
  if gpuConf and gpuConf.forceLow then
    return gpuConf.forceLow == 1
  end
  return false
end

function DeviceAdapter.isCloseShadow()
  if gpuConf and gpuConf.closeShadow then
    return gpuConf.closeShadow == 1
  end
  return false
end

function DeviceAdapter.isVivoNew()
  if deviceConf and deviceConf.vivo_120 then
    return deviceConf.vivo_120 == 1
  end
  return false
end
