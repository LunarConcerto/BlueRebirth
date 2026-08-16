local m = {}

function m:SetParent(p)
end

function m:SetPositionAndRotation(position, rotation)
end

function m:Translate(translation, relativeTo)
end

function m:Rotate(eulers, relativeTo)
end

function m:RotateAround(point, axis, angle)
end

function m:LookAt(target, worldUp)
end

function m:TransformDirection(direction)
end

function m:InverseTransformDirection(direction)
end

function m:TransformVector(vector)
end

function m:InverseTransformVector(vector)
end

function m:TransformPoint(position)
end

function m:InverseTransformPoint(position)
end

function m:DetachChildren()
end

function m:SetAsFirstSibling()
end

function m:SetAsLastSibling()
end

function m:SetSiblingIndex(index)
end

function m:GetSiblingIndex()
end

function m:Find(n)
end

function m:IsChildOf(parent)
end

function m:GetEnumerator()
end

function m:GetChild(index)
end

return m
