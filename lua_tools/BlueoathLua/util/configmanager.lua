local ConfigManager = class("util.ConfigManager")
local cjson = require("cjson")
local WakeTable = {}
local WakeTableGroup = {}

function ConfigManager.GetDataById(strName, strId, nocheck)
  if not strName or not strId then
    local str = string.format("config:%s strId:%s", tostring(strName), tostring(strId))
    noticeManager:ShowMsgBox(str)
    return nil
  end
  local name = string.sub(strName, 8)
  if name ~= "language" and SyncJsonTable[name] then
    local data = Data.syncJsonData:GetSyncJsonDataById(name, strId)
    return data
  end
  if WakeTableGroup[strName] ~= nil then
    local num = tonumber(strId)
    if num ~= nil then
      if WakeTableGroup[strName][num] == nil then
      end
      return SetReadOnlyMeta(WakeTableGroup[strName][num])
    else
      if WakeTableGroup[strName][strId] == nil then
      end
      return SetReadOnlyMeta(WakeTableGroup[strName][strId])
    end
  end
  if WakeTable[strName] == nil then
    WakeTable[strName] = {}
  end
  if WakeTable[strName][strId] == nil then
    local strJson = SQLiteConfigManager.Instance:GetJsonData(strName, tostring(strId))
    local table = cjson.decode(strJson)
    WakeTable[strName][strId] = table
  end
  if WakeTable[strName][strId] == nil and not nocheck then
    logError("\229\164\167\230\166\130\231\142\135\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\151\174\233\162\152, can not find id:%s in configTable:%s", strId, strName)
  end
  return SetReadOnlyMeta(WakeTable[strName][strId])
end

function ConfigManager.GetData(strName)
  local name = string.sub(strName, 8)
  if name ~= "language" and SyncJsonTable[name] then
    local data = Data.syncJsonData:GetSyncJsonData(name)
    return data
  end
  if WakeTableGroup[strName] ~= nil then
    return WakeTableGroup[strName]
  else
    WakeTableGroup[strName] = {}
  end
  local dblist = SQLiteConfigManager.Instance:GetAll(strName)
  if dblist == nil or dblist.Count == 0 then
    logError("table not exist:" .. tostring(strName))
    return nil
  end
  local key, tempTable
  for i = 0, dblist.Count - 1 do
    key = dblist[i].id
    if key ~= "nil" then
      if WakeTable[strName] == nil or WakeTable[strName][key] == nil then
        tempTable = cjson.decode(SQLiteConfigManager.GetJsonStrByBytes(dblist[i].jsonbytes))
      else
        tempTable = WakeTable[strName][key]
      end
      local num = tonumber(key)
      if num ~= nil then
        WakeTableGroup[strName][num] = tempTable
      else
        WakeTableGroup[strName][key] = tempTable
      end
    end
  end
  return SetReadOnlyMeta(WakeTableGroup[strName])
end

function ConfigManager.GetMultiDataByKey(strName, strKey, strValue)
  local tabTemp = configManager.GetData(strName)
  local tabRes = {}
  for k, v in pairs(tabTemp) do
    if v[strKey] == nil then
      return
    end
    if v[strKey] == strValue then
      tabRes[k] = v
    end
  end
  return SetReadOnlyMeta(tabRes)
end

function ConfigManager.GetMultiDataByKeyValue(strName, strKey, strValue)
  local tabTemp = configManager.GetData(strName)
  local tabRes = {}
  local temIndex = 1
  for k, v in pairs(tabTemp) do
    if v[strKey] == nil then
      logError("table not exist key " .. strKey)
      return
    end
    for key, value in pairs(v[strKey]) do
      if value == strValue then
        tabRes[temIndex] = v
        temIndex = temIndex + 1
        break
      end
    end
  end
  return SetReadOnlyMeta(tabRes)
end

function ConfigManager.GetMetaData(strName)
  return ConfigManager.GetData(strName)
end

function ConfigManager.SetData(strName, data)
  if WakeTableGroup == nil then
    WakeTableGroup = {}
    setmetatable(WakeTableGroup, {__mode = "v"})
  end
  WakeTableGroup[strName] = data
  logError("  WakeTableGroup size  " .. #WakeTableGroup[strName])
  return SetReadOnlyMeta(WakeTableGroup[strName])
end

return ConfigManager
