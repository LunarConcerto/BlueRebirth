local SyncJsonData = class("data.SyncJsonData", Data.BaseData)
local cjson = require("cjson")

function SyncJsonData:initialize()
  self.jsonMap = {}
end

function SyncJsonData:SetData(data)
  if data then
    local content = cjson.decode(data.Content)
    local content_key2number = {}
    if content then
      for i, v in pairs(content) do
        content_key2number[tonumber(i)] = v
      end
      self.jsonMap[data.Name] = content_key2number
    end
  end
end

function SyncJsonData:GetSyncJsonData(name)
  if self.jsonMap[name] == nil then
    logError("\229\164\167\230\166\130\231\142\135\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\151\174\233\162\152, can not find configTable:%s", name)
  end
  return self.jsonMap[name]
end

function SyncJsonData:GetSyncJsonDataById(name, strId)
  if self.jsonMap[name] == nil then
    logError("\229\164\167\230\166\130\231\142\135\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\151\174\233\162\152, can not find configTable:%s", name)
  end
  if self.jsonMap[name][strId] == nil then
    logError("\229\164\167\230\166\130\231\142\135\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\151\174\233\162\152, can not find id:%s in configTable:%s", strId, name)
  end
  return self.jsonMap[name][strId]
end

return SyncJsonData
