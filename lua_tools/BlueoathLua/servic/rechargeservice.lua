local RechargeService = class("servic.RechargeService", Service.BaseService)

function RechargeService:initialize()
  self:_InitHandlers()
end

function RechargeService:_InitHandlers()
  self:BindEvent("recharge.RechargeInfo", self._UpdateRechargeInfo, self)
  self:BindEvent("recharge.RechargeReward", self._GetRechargeReward, self)
  self:BindEvent("recharge.RechargeExTraReward", self._GetExtraReward, self)
  self:BindEvent("recharge.RechargeMonthReward", self._GetMonthReward, self)
  self:BindEvent("recharge.FreeReward", self._BuyFreeItemCallBack, self)
  self:BindEvent("recharge.GetPaybackReward", self._GetPayBackRewardCallBack, self)
  self:BindEvent("recharge.DirectBuyItem", self._DirectBuyItemCallBack, self)
  self:BindEvent("recharge.DirectBuySelectItem", self._DirectBuyItemCallBack, self)
end

function RechargeService:_UpdateRechargeInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("updateRechargeInfo Error :" .. err)
  else
    local rechargeInfo = dataChangeManager:PbToLua(ret, recharge_pb.TRECHARGEINFO)
    Data.rechargeData:SetData(rechargeInfo)
    self:SendLuaEvent(LuaEvent.UpdataRechargeInfo)
  end
end

function RechargeService:_GetRechargeReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Get Recharge Daily Reward Error:" .. err)
  else
    local rechargeInfo = dataChangeManager:PbToLua(ret, recharge_pb.TRECHARGEREWARD)
    Data.rechargeData:SetRewardData(rechargeInfo)
    self:SendLuaEvent(LuaEvent.RechargeGetRewards)
  end
end

function RechargeService:_GetExtraReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Get Rechage Extra Reward Error:" .. err)
  else
    local rechargeInfo = dataChangeManager:PbToLua(ret, recharge_pb.TRECHARGEREWARD)
    Data.rechargeData:SetExtraRewardData(rechargeInfo)
    self:SendLuaEvent(LuaEvent.RechargeGetExtraRewards)
  end
end

function RechargeService:_GetMonthReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Get Month Rechage Reward Error:" .. err)
  else
    local rechargeInfo = dataChangeManager:PbToLua(ret, recharge_pb.TRECHARGEREWARD)
    Data.rechargeData:SetMonthRewardData(rechargeInfo)
  end
end

function RechargeService:SendBuyFreeItem(id)
  local args = {RechargeId = id}
  args = dataChangeManager:LuaToPb(args, recharge_pb.TFREERECHARGEITEMARG)
  self:SendNetEvent("recharge.FreeReward", args)
end

function RechargeService:_BuyFreeItemCallBack(ret, state, err, errmsg)
  if err ~= 0 then
    logError("Buy Free Reward Error:" .. err)
  end
end

function RechargeService:GetPaybackReward(goldNum, cardNum)
  local args = {GoldNum = goldNum, CardNum = cardNum}
  args = dataChangeManager:LuaToPb(args, recharge_pb.TGETPAYBACKREWARDARG)
  self:SendNetEvent("recharge.GetPaybackReward", args)
end

function RechargeService:_GetPayBackRewardCallBack(ret, state, err, errmsg)
  Data.rechargeData:SetPayBackData(err == 0)
  self:SendLuaEvent(LuaEvent.RechargePayBackSuccess, err == 0)
end

function RechargeService:DirectBuyItemCallBack(rechargeId, discountId)
  local args = {RechargeId = rechargeId, DiscountId = discountId}
  args = dataChangeManager:LuaToPb(args, recharge_pb.TDIRECTBUYITEMARG)
  self:SendNetEvent("recharge.DirectBuyItem", args)
end

function RechargeService:_DirectBuyItemCallBack(ret, state, err, errmsg)
  if err ~= 0 then
    if err == 3217 then
      local str = UIHelper.GetString(430010)
      noticeManager:ShowTip(str)
    end
    logError("Direct Buy Item Error:" .. err)
    self:SendLuaEvent(LuaEvent.RechargeGetRewardsErr, err)
  else
    local rechargeInfo = dataChangeManager:PbToLua(ret, recharge_pb.TDIRECTBUYITEMRET)
    Data.rechargeData:SetRewardData(rechargeInfo)
    self:SendLuaEvent(LuaEvent.RechargeGetRewards)
  end
end

function RechargeService:SendDirectBuySelectItem(actId, rechargeId, selectIndex)
  local args = {
    ActivityId = actId,
    RechargeId = rechargeId,
    SelectIndex = selectIndex
  }
  args = dataChangeManager:LuaToPb(args, recharge_pb.TDIRECTBUYSELECTITEMARG)
  self:SendNetEvent("recharge.DirectBuySelectItem", args)
end

return RechargeService
