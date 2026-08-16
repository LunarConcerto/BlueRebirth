local m = {}

function m:SetLightDirty()
end

function m:AddCommandBuffer(evt, buffer)
end

function m:AddCommandBufferAsync(evt, buffer, queueType)
end

function m:RemoveCommandBuffer(evt, buffer)
end

function m:RemoveCommandBuffers(evt)
end

function m:RemoveAllCommandBuffers()
end

function m:GetCommandBuffers(evt)
end

function m.GetLights(type, layer)
end

return m
