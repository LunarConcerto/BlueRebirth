local m = {}

function m:GetComponent(type)
end

function m:GetComponentInChildren(t, includeInactive)
end

function m:GetComponentsInChildren(t, includeInactive)
end

function m:GetComponentInParent(t)
end

function m:GetComponentsInParent(t, includeInactive)
end

function m:GetComponents(type)
end

function m:CompareTag(tag)
end

function m:SendMessageUpwards(methodName, value, options)
end

function m:SendMessage(methodName, value)
end

function m:BroadcastMessage(methodName, parameter, options)
end

return m
