local MubarOutpostService = class("servic.MubarOutpostService", Service.BaseService)

function MubarOutpostService:initialize()
  self:_InitHandlers()
end

function MubarOutpostService:_InitHandlers()
  self:BindEvent("outpost.UpdateOutPostInfo", self._UpdateOutPostInfo, self)
  self:BindEvent("outpost.UpgradeBuilding", self._UpgradeBuilding, self)
  self:BindEvent("outpost.DegradeBuilding", self._UpgradeBuilding, self)
  self:BindEvent("outpost.SpeedUpProduction", self._SpeedUpProduction, self)
  self:BindEvent("outpost.ReceiveItem", self._ReceiveItem, self)
  self:BindEvent("outpost.ReceiveAll", self._ReceiveItem, self)
end

function MubarOutpostService:_UpdateOutPostInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("outpost.UpdateOutPostInfo", "error:", err, ",msg:", errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, outpost_pb.TOUTPOSTINFO)
    Data.mubarOutpostData:SetMubarOutPostInfoData(info)
    Data.mubarOutpostData:SetSpeedUpMaxNum(info.SpeedUpTime)
    self:SendLuaEvent(LuaEvent.UpdateOutpostInfo)
  end
end

function MubarOutpostService:_SpeedUpProduction(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SpeedUpProduction:", "error:", err, ",msg:", errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, outpost_pb.TOPRECEIVERET)
    if info and info.ItemInfo then
      local param = {
        Rewards = info.ItemInfo,
        DontMerge = false
      }
      UIHelper.OpenPage("GetRewardsPage", param)
    end
  end
end

function MubarOutpostService:_ReceiveItem(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_ReceiveItem:", "error:", err, ",msg:", errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, outpost_pb.TOPRECEIVERET)
    if info and info.ItemInfo then
      local param = {
        Rewards = info.ItemInfo,
        DontMerge = false
      }
      UIHelper.OpenPage("GetRewardsPage", param)
    end
  end
end

function MubarOutpostService:_UpgradeBuilding(ret, state, err, errmsg)
  if err ~= 0 then
    logError("error:", errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateOutpostInfo)
  end
end

function MubarOutpostService:SpeedUpProduction(param)
  local info = dataChangeManager:LuaToPb(param, outpost_pb.TOPSPEEDUPPRODUCTIONARG)
  self:SendNetEvent("outpost.SpeedUpProduction", info)
end

function MubarOutpostService:GetOutpostInfo()
  self:SendNetEvent("outpost.GetOutPostInfo")
end

function MubarOutpostService:UpdateBuilding(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPUPGRADEBUILDINGARG)
  self:SendNetEvent("outpost.UpgradeBuilding", param)
end

function MubarOutpostService:DegradeBuilding(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPUPGRADEBUILDINGARG)
  self:SendNetEvent("outpost.DegradeBuilding", param)
end

function MubarOutpostService:SetHero(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPSETHEROARG)
  self:SendNetEvent("outpost.SetHero", param)
end

function MubarOutpostService:ReceiveItem(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPRECEIVEBYBUILDINGARG)
  self:SendNetEvent("outpost.ReceiveItem", param)
end

function MubarOutpostService:ReceiveAll()
  self:SendNetEvent("outpost.ReceiveAll")
end

function MubarOutpostService:SetUseCoin(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPSETUSECOINARG)
  self:SendNetEvent("outpost.SetUseCoin", param)
end

function MubarOutpostService:SaveTactic(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPSAVEBUILDINGTACTICARG)
  self:SendNetEvent("outpost.SaveTactic", param)
end

function MubarOutpostService:RemoveTactic(param)
  param = dataChangeManager:LuaToPb(param, outpost_pb.TOPSAVEBUILDINGTACTICARG)
  self:SendNetEvent("outpost.SaveTactic", param)
end

return MubarOutpostService
