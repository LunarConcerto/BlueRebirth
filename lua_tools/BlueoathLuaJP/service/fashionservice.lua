local FashionService = class("servic.FashionService", Service.BaseService)

function FashionService:initialize()
  self:_InitHandlers()
end

function FashionService:_InitHandlers()
  self:BindEvent("fashion.updateData", self._FashionUpdate, self)
  self:BindEvent("fashion.fashionReplaceReward", self._FashionReplaceReward, self)
  self:BindEvent("fashion.Equip", self._EquipFashion, self)
end

function FashionService:EquipFashion(fashionTid, fashionState, heroId)
  local arg = {
    FashionTid = fashionTid,
    EquipStatus = fashionState,
    HeroId = heroId
  }
  arg = dataChangeManager:LuaToPb(arg, fashion_pb.TFASHIONEQUIPARG)
  self:SendNetEvent("fashion.Equip", arg)
end

function FashionService:_FashionUpdate(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Fashion Update failed err:" .. err .. errmsg)
  else
    local fashionInfo = dataChangeManager:PbToLua(ret, fashion_pb.TFASHIONLIST)
    Data.fashionData:SetData(fashionInfo)
    self:SendLuaEvent(LuaEvent.UpdateFashionInfo)
  end
end

function FashionService:_FashionReplaceReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Fashion replace failed err:" .. err .. errmsg)
  else
    local fashionInfo = dataChangeManager:PbToLua(ret, fashion_pb.TFASHIONREPLACEREWARD)
    Data.fashionData:SetFashionReplaceReward(fashionInfo)
  end
end

function FashionService:_EquipFashion(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Wear fashion failed err:" .. err .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.WearFashionSuccess)
  end
end

return FashionService
