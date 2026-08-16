local m = {}

function m:BaseInit(parent, templatepath, priority)
end

function m:Init(parent, config)
end

function m:AddComponent(priority, type, index)
end

function m:GetComponent(priority, type, index)
end

function m:GetTransByPriority(priority, index)
end

function m:AddCameraCtrl(ctrlBase)
end

function m:RemoveCameraCtrl(ctrlBase)
end

function m:Enable()
end

function m:Disable()
end

function m:ShowCameraPath(cameraPath, cameraIndex, trans, callBack)
end

function m:StopCameraController()
end

function m:SetCameraOrthographic(flag)
end

function m:ScreenPointToRay(pos, index)
end

function m:SetClearFlags(clearFlags, index)
end

function m:SetCullingMask(cullingMask, index)
end

function m:GetCullingMask(index)
end

function m:SetFov(fov, index)
end

function m:GetFov(index)
end

function m:SetDepth(depth, index)
end

function m:GetDepth(index)
end

function m:WorldToScreenPoint(position, index)
end

function m:SetNearClipPlane(nearClipPlane, index)
end

function m:GetNearClipPlane(index)
end

function m:SetFarClipPlane(farClipPlane, index)
end

function m:GetFarClipPlane(index)
end

function m:GetCamTrans(index)
end

function m:GetCam(index)
end

function m:Destroy(bRlease)
end

return m
