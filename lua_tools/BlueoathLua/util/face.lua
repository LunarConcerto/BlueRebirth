local Face = class("util.Face")
local json = require("cjson")

function Face:initialize()
end

function Face:InitFaceTracking(girlId, gameObject, camPos)
  XRFace.InitFaceTracking(girlId, gameObject, camPos)
end

function Face:ClearFaceTracking()
  XRFace.ClearFaceTracking()
end

function Face:VerifyPermission(func)
  XRFace.VerifyPermission(func)
end

function Face:StartRecord(maxTime, callback)
  maxTime = maxTime or 10
  local code = 0
  XRFace.VerifyPermission(function(permission)
    if not permission then
      code = 1
    else
      XRFace.StartRecord(maxTime)
    end
    callback(code)
  end)
end

function Face:CancelRecord()
  XRFace.CancelRecord()
end

function Face:EndRecord()
  XRFace.EndRecord()
end

function Face:LoadSummary()
  local str = XRFace.LoadSummary()
  self.summary = json.decode(str)
  if not self.summary then
    self.summary = {
      dict = {}
    }
  end
  return self.summary.dict
end

function Face:Play(girlId, fileName)
  XRFace.Play(girlId, fileName)
end

function Face:Stop()
  XRFace.Stop()
end

function Face:Delete(girlId, fileName)
  XRFace.Delete(girlId, fileName)
end

function Face:ChangeMode(mode)
  XRFace.ChangeMode(mode)
end

function Face:Mute(isMute)
  XRFace.Mute(isMute)
end

function Face:IsSupport()
  return XRFace.IsSupport15()
end

return Face
