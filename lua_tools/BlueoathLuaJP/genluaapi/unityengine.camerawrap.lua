local m = {}

function m:GetCommandBuffers(evt)
end

function m:Reset()
end

function m:ResetTransparencySortSettings()
end

function m:ResetAspect()
end

function m:ResetCullingMatrix()
end

function m:SetReplacementShader(shader, replacementTag)
end

function m:ResetReplacementShader()
end

function m:SetTargetBuffers(colorBuffer, depthBuffer)
end

function m:ResetWorldToCameraMatrix()
end

function m:ResetProjectionMatrix()
end

function m:CalculateObliqueMatrix(clipPlane)
end

function m:WorldToScreenPoint(position, eye)
end

function m:WorldToViewportPoint(position, eye)
end

function m:ViewportToWorldPoint(position, eye)
end

function m:ScreenToWorldPoint(position, eye)
end

function m:ScreenToViewportPoint(position)
end

function m:ViewportToScreenPoint(position)
end

function m:ViewportPointToRay(pos, eye)
end

function m:ScreenPointToRay(pos, eye)
end

function m:CalculateFrustumCorners(viewport, z, eye, outCorners)
end

function m.FocalLengthToFOV(focalLength, sensorSize)
end

function m.FOVToFocalLength(fov, sensorSize)
end

function m:GetStereoNonJitteredProjectionMatrix(eye)
end

function m:GetStereoViewMatrix(eye)
end

function m:CopyStereoDeviceProjectionMatrixToNonJittered(eye)
end

function m:GetStereoProjectionMatrix(eye)
end

function m:SetStereoProjectionMatrix(eye, matrix)
end

function m:ResetStereoProjectionMatrices()
end

function m:SetStereoViewMatrix(eye, matrix)
end

function m:ResetStereoViewMatrices()
end

function m.GetAllCameras(cameras)
end

function m:RenderToCubemap(cubemap, faceMask)
end

function m:Render()
end

function m:RenderWithShader(shader, replacementTag)
end

function m:RenderDontRestore()
end

function m.SetupCurrent(cur)
end

function m:CopyFrom(other)
end

function m:RemoveCommandBuffers(evt)
end

function m:RemoveAllCommandBuffers()
end

function m:AddCommandBuffer(evt, buffer)
end

function m:AddCommandBufferAsync(evt, buffer, queueType)
end

function m:RemoveCommandBuffer(evt, buffer)
end

return m
