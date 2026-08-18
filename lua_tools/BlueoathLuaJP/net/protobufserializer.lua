local s = {}

function s.serializ(obj)
  if obj.SerializeToString == nil then
    logWarning("obj:" .. tostring(obj) .. " is not a proto class.")
    return
  end
  return obj:SerializeToString()
end

function s.deserializ(typeKey, data)
  local ins = ProtobufTypeManager[key]()
  ins:ParseFromString(data)
  return ins
end

ProtobufSerializer = s
return ProtobufSerializer
