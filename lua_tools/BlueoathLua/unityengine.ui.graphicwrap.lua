local m = {}

function m:SetAllDirty()
end

function m:SetLayoutDirty()
end

function m:SetVerticesDirty()
end

function m:SetMaterialDirty()
end

function m:OnCullingChanged()
end

function m:Rebuild(update)
end

function m:LayoutComplete()
end

function m:GraphicUpdateComplete()
end

function m:OnRebuildRequested()
end

function m:SetNativeSize()
end

function m:Raycast(sp, eventCamera)
end

function m:PixelAdjustPoint(point)
end

function m:GetPixelAdjustedRect()
end

function m:CrossFadeColor(targetColor, duration, ignoreTimeScale, useAlpha)
end

function m:CrossFadeAlpha(alpha, duration, ignoreTimeScale)
end

function m:RegisterDirtyLayoutCallback(action)
end

function m:UnregisterDirtyLayoutCallback(action)
end

function m:RegisterDirtyVerticesCallback(action)
end

function m:UnregisterDirtyVerticesCallback(action)
end

function m:RegisterDirtyMaterialCallback(action)
end

function m:UnregisterDirtyMaterialCallback(action)
end

return m
