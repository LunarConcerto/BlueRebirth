local RechargeData = class("data.RechargeData", Data.BaseData)

function RechargeData:initialize()
  self:_InitHandlers()
end

function RechargeData:_InitHandlers()
  self:ResetData()
end

function RechargeData:ResetData()
  self.rechargeInfo = {}
  self.rewardInfo = nil
  self.paybackSuccess = nil
  self.selectiveInfo = nil
end

function RechargeData:SetData(param)
  if param.MonthCard ~= nil then
    self.rechargeInfo.MonthCard = param.MonthCard
  end
  if param.WeekCard ~= nil then
    self.rechargeInfo.WeekCard = param.WeekCard
  end
  if param.SupperMonthCard ~= nil then
    self.rechargeInfo.SupperMonthCard = param.SupperMonthCard
  end
  if param.Info ~= nil then
    self.rechargeInfo.Info = param.Info
  end
  if param.AccRcharge ~= nil then
    self.rechargeInfo.AccRecharge = param.AccRcharge
  end
  if param.AccRchargeRmb ~= nil then
    self.rechargeInfo.AccRchargeRmb = param.AccRchargeRmb
  end
  if param.SelectiveInfo ~= nil then
    self.selectiveInfo = param.SelectiveInfo
  end
  if param.AccRchargeLucky ~= nil then
    self.rechargeInfo.AccRchargeLucky = param.AccRchargeLucky
  end
  if param.ActivityAccRchargeRmb ~= nil then
    self.rechargeInfo.ActivityAccRchargeRmb = param.ActivityAccRchargeRmb
  end
end

function RechargeData:SetRewardData(param)
  if param then
    self.rewardInfo = param.Reward
  end
end

function RechargeData:GetRechargeData()
  return SetReadOnlyMeta(self.rechargeInfo)
end

function RechargeData:SetExtraRewardData(param)
  if param then
    self.extraRewardInfo = param.Reward
  end
end

function RechargeData:SetMonthRewardData(param)
  if param then
    self.monthRewardInfo = param.Reward
  end
end

function RechargeData:GetRechargeExtraRewardData()
  local data = {}
  if self.extraRewardInfo ~= nil then
    for k, v in pairs(self.extraRewardInfo) do
      data[k] = v
    end
  end
  self.extraRewardInfo = nil
  return SetReadOnlyMeta(data)
end

function RechargeData:GetRechargeRewardData()
  local data = {}
  if self.rewardInfo ~= nil then
    for k, v in pairs(self.rewardInfo) do
      data[k] = v
    end
  end
  self.rewardInfo = nil
  return SetReadOnlyMeta(data)
end

function RechargeData:GetRechargeMonthRewardData()
  local data = {}
  if self.monthRewardInfo ~= nil then
    for k, v in pairs(self.monthRewardInfo) do
      data[k] = v
    end
  end
  self.monthRewardInfo = nil
  return SetReadOnlyMeta(data)
end

function RechargeData:CheckRewardData()
  return SetReadOnlyMeta(self.rewardInfo)
end

function RechargeData:CheckBigMonthRewardData()
  return SetReadOnlyMeta(self.extraRewardInfo)
end

function RechargeData:CheckMonthRewardData()
  return SetReadOnlyMeta(self.monthRewardInfo)
end

function RechargeData:SetPayBackData(state)
  self.paybackSuccess = state
end

function RechargeData:GetAccRecharge()
  if self.rechargeInfo.AccRecharge == nil then
    return 0
  end
  return self.rechargeInfo.AccRecharge
end

function RechargeData:GetAccRechargeRmb()
  if self.rechargeInfo.AccRchargeRmb == nil then
    return 0
  end
  return self.rechargeInfo.AccRchargeRmb
end

function RechargeData:GetSelectiveInfo()
  return self.selectiveInfo
end

function RechargeData:GetActivityAccRechargeRmb()
  if self.rechargeInfo.ActivityAccRchargeRmb == nil then
    return 0
  end
  return self.rechargeInfo.ActivityAccRchargeRmb
end

function RechargeData:GetAccRechargeLucky()
  if self.rechargeInfo.AccRchargeLucky == nil then
    return 0
  end
  return self.rechargeInfo.AccRchargeLucky
end

return RechargeData
