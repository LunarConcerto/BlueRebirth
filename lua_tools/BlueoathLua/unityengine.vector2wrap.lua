local m = {}

function m:Set(newX, newY)
end

function m.Lerp(a, b, t)
end

function m.LerpUnclamped(a, b, t)
end

function m.MoveTowards(current, target, maxDistanceDelta)
end

function m.Scale(a, b)
end

function m:Normalize()
end

function m:ToString()
end

function m:GetHashCode()
end

function m:Equals(other)
end

function m.Reflect(inDirection, inNormal)
end

function m.Perpendicular(inDirection)
end

function m.Dot(lhs, rhs)
end

function m.Angle(from, to)
end

function m.SignedAngle(from, to)
end

function m.Distance(a, b)
end

function m.ClampMagnitude(vector, maxLength)
end

function m.SqrMagnitude(a)
end

function m.Min(lhs, rhs)
end

function m.Max(lhs, rhs)
end

function m.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed)
end

return m
