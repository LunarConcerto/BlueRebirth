oldPairs = pairs

function pairs(tbl)
  if tbl == nil then
    logError("table is nil")
    return
  end
  if next(tbl) == nil then
    local metaTbl = getmetatable(tbl)
    if metaTbl == nil then
      return oldPairs(tbl)
    elseif metaTbl.tostring ~= nil then
      local strName = metaTbl.tostring()
      if strName == "readOnlyMeta" then
        local tblData = metaTbl.data
        if tblData ~= nil then
          return oldPairs(tblData)
        else
          logError("data is nil")
          return oldPairs(tbl)
        end
      else
        return oldPairs(tbl)
      end
    else
      return oldPairs(tbl)
    end
  else
    return oldPairs(tbl)
  end
end

oldIPairs = ipairs

function ipairs(tbl)
  if next(tbl) == nil then
    local metaTbl = getmetatable(tbl)
    if metaTbl == nil then
      return oldIPairs(tbl)
    elseif metaTbl.tostring ~= nil then
      local strName = metaTbl.tostring()
      if strName == "readOnlyMeta" then
        local tblData = metaTbl.data
        if tblData ~= nil then
          return oldIPairs(tblData)
        else
          logError("data is nil")
          return oldIPairs(tbl)
        end
      else
        return oldIPairs(tbl)
      end
    else
      return oldIPairs(tbl)
    end
  else
    return oldIPairs(tbl)
  end
end

function SetReadOnlyMeta(tblData)
  if not isDebug then
    return tblData
  end
  local tblAgency = {}
  local meta = {}
  meta.__index = tblData
  
  function meta.__newindex(k, v)
    rawset(tblData, k, v)
    logError("\232\191\153\228\184\170\232\161\168\230\152\175\229\143\170\232\175\187\231\154\132 !!!!!")
  end
  
  function meta.tostring()
    return "readOnlyMeta"
  end
  
  meta.data = tblData
  setmetatable(tblAgency, meta)
  return tblAgency
end

function GetReadOnlyData(tblReadonly)
  if __IsTableReadOnly(tblReadonly) then
    local meta = getmetatable(tblReadonly)
    return meta.data
  else
    return tblReadonly
  end
end

function GetTableLength(tblReadonly)
  if __IsTableReadOnly(tblReadonly) then
    local meta = getmetatable(tblReadonly)
    return table.nums(meta.data)
  else
    return table.nums(tblReadonly)
  end
end

function __IsTableReadOnly(tbl)
  if not isDebug then
    return false
  end
  local meta = getmetatable(tbl)
  if meta == nil or meta.tostring == nil then
    return false
  end
  if meta.tostring() == "readOnlyMeta" then
    return true
  end
  return false
end

math.oldceil = math.ceil
math.oldfloor = math.floor

function math.ceil(num)
  return math.oldceil(num - 1.0E-6)
end

function math.floor(num)
  return math.oldfloor(num + 1.0E-6)
end
