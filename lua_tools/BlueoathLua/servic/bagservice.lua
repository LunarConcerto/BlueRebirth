local BagService = class("servic.BagService", Service.BaseService)

function BagService:initialize()
  self:_InitHandlers()
end

function BagService:_InitHandlers()
  self:BindEvent("bag.GetBagInfo", self._GetBagInfoRet, self)
  self:BindEvent("bag.UpdateBagData", self._UpdateItemInfo, self)
  self:BindEvent("bag.GetNormalTreasureInfo", self._GetTreasureInfo, self)
  self:BindEvent("bag.GetSelectTreasureInfo", self._GetTreasureInfo, self)
  self:BindEvent("bag.CompositeItem", self._CompositeItem, self)
  self:BindEvent("periodbag.UpdatePeriodBagData", self._UpdatePeriodBagRet, self)
end

function BagService:SendComposite(arg)
  local args = {
    tid = arg.tid,
    num = arg.num
  }
  args = dataChangeManager:LuaToPb(args, bag_pb.TCOMPOSITEITEMARG)
  self:SendNetEvent("bag.CompositeItem", args)
end

function BagService:_CompositeItem(ret, state, err, errmsg)
  if err ~= 0 then
    logError("CompositeItem failed err: " .. err)
  end
  self:SendLuaEvent(LuaEvent.GetPaperInfo, err)
end

function BagService:SendGetBagInfo(arg)
  arg = dataChangeManager:LuaToPb(arg, bag_pb.TGETBAGINFOARG)
  self:SendNetEvent("bag.GetBagInfo", arg)
end

function BagService:_GetBagInfoRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetBagInfo failed err: " .. err)
  else
    local info = dataChangeManager:PbToLua(ret, bag_pb.TBAGINFORET)
    Data.bagData:SetData(info)
    if info.bagType == BagType.ITEM_BAG then
      self:SendLuaEvent(LuaEvent.GetBagItemMsg)
    elseif info.bagType == BagType.EQUIP_BAG then
      Data.equipData:SetData(info.equipList)
      self:SendLuaEvent(LuaEvent.GetBagEquipMsg)
    end
  end
end

function BagService:_UpdateItemInfo(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, bag_pb.TBAGINFORET)
    Data.bagData:SetData(info)
    self:SendLuaEvent(LuaEvent.UpdateBagItem)
  else
    logError("UpdateItemInfo err" .. err)
  end
end

function BagService:SendGetNoramlTreasureItem(treasureId, openTreasureNum)
  local args = {treasureId = treasureId, treasureNum = openTreasureNum}
  arg = dataChangeManager:LuaToPb(args, bag_pb.TBAGNORMALTREASUREINFOARG)
  self:SendNetEvent("bag.GetNormalTreasureInfo", arg)
end

function BagService:SendGetSelectTreasureItem(treasure_Id, pos, openNum)
  local args = {
    treasureId = treasure_Id,
    position = pos,
    num = openNum
  }
  arg = dataChangeManager:LuaToPb(args, bag_pb.TBAGSELECTTREASUREINFOARG)
  self:SendNetEvent("bag.GetSelectTreasureInfo", arg)
end

function BagService:_GetTreasureInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetTreasureInfo failed err: " .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, bag_pb.TBAGTREASUREINFORET)
    self:SendLuaEvent(LuaEvent.GetTreasureInfo, info)
  end
end

function BagService:_UpdatePeriodBagRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("UpdatePeriodBagData failed err: " .. err .. errmsg)
  else
    local info = dataChangeManager:PbToLua(ret, periodbag_pb.TPERIODBAGINFORET)
    Data.bagData:SetPeriodData(info)
  end
end

return BagService
