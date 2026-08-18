RetentionHelper = {}
local BehaviourRetention = require("util.BehaviourRetention")
local json = require("cjson")

function RetentionHelper.Retention(eventId, tabInfo)
  local m_RetentionOrder = configManager.GetData("config_key_list")
  local userInfo = Data.userData:GetUserData()
  local uid = ""
  local uname = ""
  local level = ""
  tabInfo = tabInfo or {}
  if GetTableLength(userInfo) > 0 then
    uid = math.tointeger(userInfo.Uid)
    uname = userInfo.Uname
    level = math.tointeger(userInfo.Level)
    tabInfo.user_name = uname
    tabInfo.user_level = level
  end
  tabInfo.random_num = math.random(1000000, 9999999)
  local defineStr = "{"
  local contentStr = ""
  if tabInfo then
    local result = {}
    for k, v in pairs(tabInfo) do
      local p = {}
      p.key = k
      p.value = json.encode(v)
      p.order = m_RetentionOrder[k].order
      table.insert(result, p)
    end
    table.sort(result, function(a, b)
      return a.order < b.order
    end)
    local length = #result
    for i = 1, length do
      contentStr = contentStr .. "\"" .. result[i].key .. "\":" .. result[i].value
      if i < length then
        contentStr = contentStr .. ","
      end
    end
  end
  contentStr = string.gsub(contentStr, "\"", "\\\"")
  defineStr = defineStr .. contentStr .. "}"
  platformManager:retention(eventId, uid, defineStr)
end

function RetentionHelper.PlayBehaviourWithRetention(shipgirl, behaviourName, isloop, onComplete)
  local handler = BehaviourRetention.CreateHandler(shipgirl, behaviourName)
  if not handler then
    shipgirl:playBehaviour(behaviourName, isloop, onComplete)
  else
    shipgirl:playBehaviour(behaviourName, isloop, function(...)
      handler:Complete()
      if onComplete then
        onComplete(...)
      end
    end)
  end
end

function RetentionHelper.SkipAllBehaviour()
  BehaviourRetention.SkipAll()
end

function RetentionHelper.OtherEndAllBehaviour()
  BehaviourRetention.OtherEndAll()
end

function RetentionHelper.SkipGirl(shipgirl)
  BehaviourRetention.SkipGirl(shipgirl)
end

function RetentionHelper.OtherEndGirl(shipgirl)
  BehaviourRetention.OtherEndGirl(shipgirl)
end
