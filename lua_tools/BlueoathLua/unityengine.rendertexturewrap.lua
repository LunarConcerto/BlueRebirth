local m = {}

function m.ReleaseTemporary(temp)
end

function m:GetNativeDepthBufferPtr()
end

function m:DiscardContents(discardColor, discardDepth)
end

function m:MarkRestoreExpected()
end

function m:ResolveAntiAliasedSurface()
end

function m:SetGlobalShaderProperty(propertyName)
end

function m:Create()
end

function m:Release()
end

function m:IsCreated()
end

function m:GenerateMips()
end

function m:ConvertToEquirect(equirect, eye)
end

function m.SupportsStencil(rt)
end

function m.GetTemporary(desc)
end

return m
