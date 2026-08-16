local EquipNewTestService = class("servic.EquipNewTestService", Service.BaseService)

function EquipNewTestService:initialize()
  self:_InitHandlers()
end

function EquipNewTestService:_InitHandlers()
  self:BindEvent("equipnewtestcopy.ReceiveRewards", self._RrceiveEquipNewRewards, self)
  self:BindEvent("equipnewtestcopy.UpdateEquipNewData", self._UpdateEquipNewTestInfo, self)
end

function EquipNewTestService:GetEquipNewTestRewards(arg, state)
  arg = dataChangeManager:LuaToPb(arg, equipnewtestcopy_pb.TGETDAMAGEREWARDARG)
  self:SendNetEvent("equipnewtestcopy.ReceiveRewards", arg, state)
end

function EquipNewTestService:_RrceiveEquipNewRewards(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_RrceiveEquipNewRewards failed " .. errmsg)
  else
    local tab = {Reward = state}
    eventManager:SendEvent(LuaEvent.FetchRewardBox, tab)
  end
end

function EquipNewTestService:_UpdateEquipNewTestInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_UpdateEquipNewTestInfo failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, equipnewtestcopy_pb.TGETEQUIPNEWTESTCOPYINFO)
    Data.equipNewTestData:SetData(info)
    self:SendLuaEvent(LuaEvent.EquipNewTestReceiveRewards)
  end
end

return EquipNewTestService
