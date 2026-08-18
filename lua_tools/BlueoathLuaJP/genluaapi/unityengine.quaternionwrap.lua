local m = {}

function m.FromToRotation(fromDirection, toDirection)
end

function m.Inverse(rotation)
end

function m.Slerp(a, b, t)
end

function m.SlerpUnclamped(a, b, t)
end

function m.Lerp(a, b, t)
end

function m.LerpUnclamped(a, b, t)
end

function m.AngleAxis(angle, axis)
end

function m.LookRotation(forward, upwards)
end

function m:Set(newX, newY, newZ, newW)
end

function m.Dot(a, b)
end

function m:SetLookRotation(view)
end

function m.Angle(a, b)
end

function m.Euler(x, y, z)
end

function m:ToAngleAxis(angle, axis)
end

function m:SetFromToRotation(fromDirection, toDirection)
end

function m.RotateTowards(from, to, maxDegreesDelta)
end

function m.Normalize(q)
end

function m:GetHashCode()
end

function m:Equals(other)
end

function m:ToString()
end

return m
