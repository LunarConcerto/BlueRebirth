local EquipService = class("servic.EquipService", Service.BaseService)

function EquipService:initialize()
  self:_InitHandlers()
end

function EquipService:_InitHandlers()
  self:BindEvent("equip.RiseStar", self._RiseStar, self)
  self:BindEvent("equip.Enhance", self._Enhance, self)
  self:BindEvent("equip.EnhanceBind", self._EnhanceBind, self)
  self:BindEvent("equip.UpdateEquipBagData", self._UpdateEquipInfo, self)
  self:BindEvent("equip.Dismantle", self._DismantleRes, self)
end

function EquipService:SendDismantleEquip(tabEquipId)
  local args = {ConsumeIds = tabEquipId}
  args = dataChangeManager:LuaToPb(args, equip_pb.TEQUIPDISMANTLEARGS)
  self:SendNetEvent("equip.Dismantle", args)
end

function EquipService:_DismantleRes(ret, state, err, errmsg)
  if err ~= 0 then
    logError("dismantle errmsg:" .. err .. " " .. errmsg)
    return
  elseif ret ~= nil then
    ret = dataChangeManager:PbToLua(ret, equip_pb.TEQUIPDISMANTLERET)
    self:SendLuaEvent(LuaEvent.DismantleSuccess, ret.ItemInfo)
  else
    logError("can not get equip dismantle reward")
  end
end

function EquipService:SendRiseStar(equipId, tabSelectId)
  local args = {EquipId = equipId, ConsumeIds = tabSelectId}
  args = dataChangeManager:LuaToPb(args, equip_pb.TEQUIPRISESTARARGS)
  self:SendNetEvent("equip.RiseStar", args)
end

function EquipService:_RiseStar(ret, state, err, errmsg)
  if err ~= 0 then
    logError(errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateBagItem)
    self:SendLuaEvent(LuaEvent.EquipRiseStarSuccess)
  end
end

function EquipService:SendEnhance(equipId, itemId, itemNum)
  local param = {}
  param.EquipId = equipId
  param.ItemArr = {
    {TemplateId = itemId, ItemNum = itemNum}
  }
  local args = dataChangeManager:LuaToPb(param, equip_pb.TEQUIPENHANCEARGS)
  Service.equipService:SendNetEvent("equip.Enhance", args, equipId)
end

function EquipService:_Enhance(ret, state, err, errmsg)
  if err ~= 0 then
    logError("enhance equip errmsg:" .. errmsg)
    return
  end
  self:SendLuaEvent(LuaEvent.UpdateBagEquip, true)
  self:SendLuaEvent(LuaEvent.EquipIntenstitySuccess, state)
end

function EquipService:SendEnhanceBind(equipId, itemId, itemNum)
  local param = {}
  param.EquipId = equipId
  param.ItemArr = {
    {TemplateId = itemId, ItemNum = itemNum}
  }
  local args = dataChangeManager:LuaToPb(param, equip_pb.TEQUIPENHANCEARGS)
  Service.equipService:SendNetEvent("equip.EnhanceBind", args, equipId)
end

function EquipService:_EnhanceBind(ret, state, err, errmsg)
  if err ~= 0 then
    logError("enhance equip errmsg:" .. errmsg)
    return
  end
  self:SendLuaEvent(LuaEvent.UpdateBagEquip, true)
end

function EquipService:_UpdateEquipInfo(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, equip_pb.TEQUIPLIST)
    Data.equipData:UpdateEquip(info)
    self:SendLuaEvent(LuaEvent.UpdateEquipMsg)
  else
    logError("UpdateEquipInfo err" .. err)
  end
end

return EquipService
