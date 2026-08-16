local m = {}

function m:GetLayerRoot(layer)
end

function m:GetCanvasLayerName(layer)
end

function m:SetCanvasLayer(canvas, layer, baseOrder)
end

function m:GetUIWidth()
end

function m:GetUIHeight()
end

function m:AddEvent(obj, evt, onEvt)
end

function m:RemoveEvent(obj)
end

function m:FireUIEvent(evt, param)
end

function m:FireAnimEvent(evt, param)
end

function m:FireLuaEvent(evt, param)
end

function m:FireCSharpEvent(evt, param)
end

function m:SetAdaptive()
end

function m:OnApplicationPause(pause)
end

function m:OnApplicationQuit()
end

return m
