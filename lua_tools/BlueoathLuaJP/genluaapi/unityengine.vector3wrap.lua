local m = {}

function m.Slerp(a, b, t)
end

function m.SlerpUnclamped(a, b, t)
end

function m.OrthoNormalize(normal, tangent)
end

function m.RotateTowards(current, target, maxRadiansDelta, maxMagnitudeDelta)
end

function m.Lerp(a, b, t)
end

function m.LerpUnclamped(a, b, t)
end

function m.MoveTowards(current, target, maxDistanceDelta)
end

function m.SmoothDamp(current, target, currentVelocity, smoothTime, maxSpeed)
end

function m:Set(newX, newY, newZ)
end

function m.Scale(a, b)
end

function m.Cross(lhs, rhs)
end

function m:GetHashCode()
end

function m:Equals(other)
end

function m.Reflect(inDirection, inNormal)
end

function m.Normalize(value)
end

function m.Dot(lhs, rhs)
end

function m.Project(vector, onNormal)
end

function m.ProjectOnPlane(vector, planeNormal)
end

function m.Angle(from, to)
end

function m.SignedAngle(from, to, axis)
end

function m.Distance(a, b)
end

function m.ClampMagnitude(vector, maxLength)
end

function m.Magnitude(vector)
end

function m.SqrMagnitude(vector)
end

function m.Min(lhs, rhs)
end

function m.Max(lhs, rhs)
end

function m:ToString()
end

return m
