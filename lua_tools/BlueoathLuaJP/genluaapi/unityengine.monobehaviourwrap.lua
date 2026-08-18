local m = {}

function m:IsInvoking()
end

function m:CancelInvoke()
end

function m:Invoke(methodName, time)
end

function m:InvokeRepeating(methodName, time, repeatRate)
end

function m:StartCoroutine(methodName)
end

function m:StopCoroutine(routine)
end

function m:StopAllCoroutines()
end

function m.print(message)
end

return m
