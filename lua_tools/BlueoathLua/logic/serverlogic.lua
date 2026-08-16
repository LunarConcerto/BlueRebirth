local ServerLogic = class("logic.ServerLogic")

function ServerLogic:initialize()
  self:ResetData()
end

function ServerLogic:ResetData()
  self.serverNameTab = {}
end

function ServerLogic:GetServerNameById(groupid)
  if self.serverNameTab[groupid] == nil then
    local serverList = platformManager:getServiceList()
    for _, v in ipairs(serverList) do
      self.serverNameTab[v.groupid] = v.name
    end
  end
  return self.serverNameTab[tostring(groupid)]
end

return ServerLogic
