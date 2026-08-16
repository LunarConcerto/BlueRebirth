local DataChangeManager = class("util.DataChangeManager")

function DataChangeManager:_getDefValue(ctype)
  if ctype == 1 or ctype == 2 or ctype == 3 or ctype == 4 then
    return 0
  elseif ctype == 5 or ctype == 6 then
    return 0.0
  elseif ctype == 7 then
    return false
  elseif ctype == 9 then
    return ""
  end
  return nil
end

function DataChangeManager:PbToLua(sourceData, pb, useDef)
  if sourceData == nil or pb == nil then
    return nil
  end
  local pbData = self:_HandlePb(pb.fields)
  return self:_PbToLuaImpl(sourceData, pbData, useDef)
end

function DataChangeManager:_PbToLuaImpl(sourceData, pbData, useDef)
  local tabTemp = {}
  for i, v in pairs(pbData) do
    local value = v[1]
    local isRepeated = v[2]
    local ctype = v[3]
    if type(value) == "table" then
      if isRepeated then
        tabTemp[i] = {}
        for _, y in ipairs(sourceData[i]) do
          table.insert(tabTemp[i], self:_PbToLuaImpl(y, value, useDef))
        end
      else
        tabTemp[i] = self:_PbToLuaImpl(sourceData[i], value, useDef)
      end
    elseif isRepeated then
      tabTemp[value] = {}
      for _, y in ipairs(sourceData[value]) do
        table.insert(tabTemp[value], y)
      end
    else
      tabTemp[value] = sourceData[value]
      if tabTemp[value] == nil and useDef then
        tabTemp[value] = self:_getDefValue(ctype)
      end
    end
  end
  return tabTemp
end

function DataChangeManager:_HandlePb(fields)
  local tabData = {}
  for _, y in ipairs(fields) do
    local isRepeated = type(y.default_value) == "table"
    if y.message_type ~= nil then
      tabData[y.name] = {
        self:_HandlePb(y.message_type.fields),
        isRepeated,
        y.cpp_type,
        y.message_type
      }
    else
      table.insert(tabData, {
        y.name,
        isRepeated,
        y.cpp_type
      })
    end
  end
  return tabData
end

function DataChangeManager:LuaToPb(sourceData, pb)
  if sourceData == nil or pb == nil then
    return nil
  end
  local pbData = self:_HandlePb(pb.fields)
  return self:_LuaToPbImpl(sourceData, pbData, pb.file_name[pb.name])
end

function DataChangeManager:_LuaToPbImpl(sourceData, pbData, pbCreator)
  local tabTemp = pbCreator()
  for i, v in pairs(pbData) do
    local value = v[1]
    local isRepeated = v[2]
    local ctype = v[3]
    local msgType = v[4]
    if msgType ~= nil then
      if sourceData[i] then
        if isRepeated then
          for _, y in ipairs(sourceData[i]) do
            table.insert(tabTemp[i], self:_LuaToPbImpl(y, value, msgType.file_name[msgType.name]))
          end
        else
          tabTemp[i] = self:_LuaToPbImpl(sourceData[i], value, msgType.file_name[msgType.name])
        end
      end
    elseif sourceData[value] then
      if isRepeated then
        for _, y in ipairs(sourceData[value]) do
          table.insert(tabTemp[value], y)
        end
      else
        tabTemp[value] = sourceData[value]
      end
    end
  end
  return tabTemp
end

return DataChangeManager
