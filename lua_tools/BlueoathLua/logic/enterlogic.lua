local EnterLogic = class("logic.EnterLogic")

function EnterLogic:initialize()
end

function EnterLogic:GetHomeEnter()
  local result = {}
  local configAll = configManager.GetData("config_home_activity_enter")
  for i, config in pairs(configAll) do
    local actId = config.activity_id
    if 0 < actId and config.special_enter == 0 and Logic.activityLogic:CheckActivityOpenById(actId) then
      table.insert(result, config)
    end
  end
  return result
end

function EnterLogic:GetCopyEnterByType(chapterType)
  local result = {}
  local configAll = configManager.GetData("config_home_activity_enter")
  for i, config in pairs(configAll) do
    local actId = config.activity_id
    local flag = false
    for index, value in pairs(config.chapter_type) do
      if value == chapterType then
        flag = true
      end
    end
    if 0 < actId and flag and Logic.activityLogic:CheckActivityOpenById(actId) then
      table.insert(result, config)
    end
  end
  return result
end

return EnterLogic
