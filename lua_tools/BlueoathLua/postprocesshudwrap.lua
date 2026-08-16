local m = {}

function m:SetBD(settings)
end

function m:ActiveStack(camObjId, enable)
end

function m:GetFullPostProcessCamera(instanceId)
end

function m:SetBloomActive(active)
end

function m:SetColorGradingActive(active)
end

function m:SetRadialBlurActive(active)
end

function m:SetVignetteActive(active)
end

function m:SetAntiAliasingActive(antiAliasing)
end

function m:EnableBloom(enable)
end

function m:EnableRadial(enable)
end

function m:EnableVignette(enable)
end

function m:EnableGrey(enable, gradualChange)
end

function m:EnableColorGrading(enable, path)
end

function m:SetActivePostProcess(active)
end

function m:EnableAllEffect(enable)
end

function m:ChangeProfileColorGrading(profilePath)
end

function m:ChangePostProcessProfile(profilePath)
end

function m:ReplaceProfileSetting(profilePath)
end

function m:ClearPostProcess()
end

function m:AllowHDR(enable)
end

function m:IsEnableAllHDR()
end

function m:SetEffectSetting(settings)
end

function m:SetRenderTexture(rt)
end

function m:CheckMainState()
end

function m:GetColorGradingRenderer()
end

return m
