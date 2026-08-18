local EquipTestCopyService = class("servic.EquipTestCopyService", Service.BaseService)

function EquipTestCopyService:initialize()
  self:BindEvent("equiptestcopy.UpdateData", self._UpdateData, self)
  self:BindEvent("equiptestcopy.ReceiveRewards", self._ReceiveRewards, self)
end

function EquipTestCopyService:_UpdateData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("EquipTestCopyService _UpdateData error " .. errmsg)
    return
  end
  local copyInfo = dataChangeManager:PbToLua(ret, equiptestcopy_pb.TGETEQUIPTESTCOPYINFO)
  Data.equipTestCopyData:SetData(copyInfo)
  eventManager:SendEvent(LuaEvent.EquipTestDamage)
end

function EquipTestCopyService:ReceiveRewards(rewardId)
  local args = {RewardId = rewardId}
  args = dataChangeManager:LuaToPb(args, equiptestcopy_pb.TRECEIVEREWARDSARG)
  self:SendNetEvent("equiptestcopy.ReceiveRewards", args)
end

function EquipTestCopyService:_ReceiveRewards(ret, state, err, errmsg)
  if err ~= 0 then
    logError("EquipTestCopyService _ReceiveRewards error " .. errmsg)
    return
  end
  local rewardsInfo = dataChangeManager:PbToLua(ret, equiptestcopy_pb.TRECEIVEREWARDSRET)
  eventManager:SendEvent(LuaEvent.EquipTestReceiveRewards, rewardsInfo)
end

return EquipTestCopyService
