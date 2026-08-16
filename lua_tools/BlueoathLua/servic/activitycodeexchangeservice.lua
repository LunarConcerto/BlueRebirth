local ActivityCodeExchangeService = class("servic.ActivityCodeExchangeService", Service.BaseService)

function ActivityCodeExchangeService:initialize()
  self:_InitHandlers()
end

function ActivityCodeExchangeService:_InitHandlers()
  self:BindEvent("activitycodeexchange.ExchangeReward", self._ExchangeRewardRet, self)
  self:BindEvent("activitycodeexchange.ExchangeCode", self._ExchangeCodeRet, self)
  self:BindEvent("activitycodeexchange.UpdateActivityCodeExgInfo", self._RefreshActivityCodeExgInfo, self)
end

function ActivityCodeExchangeService:SendExchangeReward(arg, state)
  local args = dataChangeManager:LuaToPb(arg, activitycodeexchange_pb.TACEXCHANGEREWARDARG)
  self:SendNetEvent("activitycodeexchange.ExchangeReward", args, state)
end

function ActivityCodeExchangeService:_ExchangeRewardRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_ExchangeRewardRet err :" .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
  Logic.activityCodeExchangeLogic:ShowCodeExgReward(state)
  self:SendLuaEvent(LuaEvent.RefreshCodeExgItem)
end

function ActivityCodeExchangeService:SendExchangeCode(arg, state)
  local args = dataChangeManager:LuaToPb(arg, activitycodeexchange_pb.TACEXCHANGECODEARG)
  self:SendNetEvent("activitycodeexchange.ExchangeCode", args, state)
end

function ActivityCodeExchangeService:_ExchangeCodeRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_ExchangeCodeRet err :" .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
  Logic.activityCodeExchangeLogic:ShowCodeExgCode(state)
  self:SendLuaEvent(LuaEvent.RefreshCodeExgItem)
end

function ActivityCodeExchangeService:_RefreshActivityCodeExgInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Refresh PlayerHeadFrame  err : " .. errmsg)
    return
  end
  local info = dataChangeManager:PbToLua(ret, activitycodeexchange_pb.TACTIVITYCODEEXCHANGERET)
  Data.activityCodeExchangeData:SetData(info)
end

return ActivityCodeExchangeService
