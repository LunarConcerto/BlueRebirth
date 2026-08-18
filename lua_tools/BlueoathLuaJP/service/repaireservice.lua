local RepaireService = class("servic.RepaireService", Service.BaseService)

function RepaireService:initialize()
  self:_InitHandlers()
end

function RepaireService:_InitHandlers()
  self:BindEvent("repair.RepairHero", self._GetRepaireService, self)
end

function RepaireService:SendGetRepair(heroId, mType)
  mType = mType or 0
  local args = {HeroIds = heroId, Type = mType}
  args = dataChangeManager:LuaToPb(args, repair_pb.TREPAIRARG)
  self:SendNetEvent("repair.RepairHero", args)
end

function RepaireService:_GetRepaireService(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetRepaireService err", err)
  else
    self:SendLuaEvent("getRepaireMsg")
  end
end

return RepaireService
