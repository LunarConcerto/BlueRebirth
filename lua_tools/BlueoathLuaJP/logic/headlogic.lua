local HeadLogic = class("logic.HeadLogic")

function HeadLogic:initialize()
  self.headCfg = {}
  self:RegroupProfileCfg()
end

function HeadLogic:RegroupProfileCfg()
  local cfg = configManager.GetData("config_profile")
  for _, v in pairs(cfg) do
    if self.headCfg[v.belongshipid] == nil then
      self.headCfg[v.belongshipid] = {}
    end
    table.insert(self.headCfg[v.belongshipid], v)
  end
end

function HeadLogic:GetAllShipCfg()
  return self.headCfg
end

function HeadLogic:GetProfileCfgBySFid(sfId)
  return self.headCfg[sfId]
end

return HeadLogic
