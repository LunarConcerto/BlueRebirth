local XR = class("util.XR")

function XR:CheckARSupport(includeARKit, includeARCore)
  return XRHome.CheckSupport(includeARKit, includeARCore)
end

function XR:SetActive(active)
  XRBattle.LocalActive = active
end

function XR:IsSupport()
  local hideAR = DeviceAdapter.getHideAR()
  if hideAR then
    return false
  end
  return XRBattle.IsSupport()
end

function XR:IsSupportHome()
  local hideAR = DeviceAdapter.getHideAR()
  if hideAR then
    return false
  end
  return XRHome.IsSupport()
end

function XR:InitHome()
  return XRHome.Init()
end

function XR:FetchCameraPosition()
  return XRHome.FetchCameraPosition()
end

function XR:FetchCenterPosition()
  return XRHome.FetchCenterPosition()
end

function XR:ApplyScale(scale)
  return XRHome.ApplyScale(scale)
end

function XR:ApplySecClear(sec)
  return XRHome.ApplySecClear(sec)
end

function XR:ClearHome()
  return XRHome.Clear()
end

function XR:ResetHome()
  return XRHome.Reset()
end

return XR
