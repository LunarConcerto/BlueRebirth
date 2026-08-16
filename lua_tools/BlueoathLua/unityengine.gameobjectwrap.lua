local m = {}

function m.CreatePrimitive(type)
end

function m:GetComponent(type)
end

function m:GetComponentInChildren(type, includeInactive)
end

function m:GetComponentInParent(type)
end

function m:GetComponents(type)
end

function m:GetComponentsInChildren(type)
end

function m:GetComponentsInParent(type)
end

function m.FindWithTag(tag)
end

function m:SendMessageUpwards(methodName, options)
end

function m:SendMessage(methodName, options)
end

function m:BroadcastMessage(methodName, options)
end

function m:AddComponent(componentType)
end

function m:SetActive(value)
end

function m:CompareTag(tag)
end

function m.FindGameObjectWithTag(tag)
end

function m.FindGameObjectsWithTag(tag)
end

function m.Find(name)
end

return m
