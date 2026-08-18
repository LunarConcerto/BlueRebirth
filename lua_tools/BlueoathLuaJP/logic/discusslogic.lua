local DiscussLogic = class("logic.DiscussLogic")

function DiscussLogic:initialize()
  self.togIndex = 1
end

function DiscussLogic:ResetData()
  self.togIndex = 1
end

function DiscussLogic:GetCommentMaxNum()
  return configManager.GetDataById("config_parameter", 25).value
end

function DiscussLogic:GetLastTogIndex()
  return self.togIndex
end

function DiscussLogic:SetLastTogIndex(nIndex)
  self.togIndex = nIndex
end

function DiscussLogic:GetHotCommentNum()
  return configManager.GetDataById("config_parameter", 23).value
end

function DiscussLogic:GetNormalCommentMaxNum()
  return configManager.GetDataById("config_parameter", 24).value
end

function DiscussLogic:GetDiskLikeMaxNum()
  return configManager.GetDataById("config_parameter", 30).value
end

function DiscussLogic:GetDisCache(sf_id)
  local data = Data.discussData
  if data:HaveCache(sf_id) then
    return true, data:GetCahceData(sf_id)
  end
  return false, nil
end

function DiscussLogic:TryGetDisData(sf_id)
  local ok, data = self:GetDisCache(sf_id)
  if not ok then
    Service.discussService:SendGetDiscuss(sf_id)
  end
  return ok, data
end

return DiscussLogic
