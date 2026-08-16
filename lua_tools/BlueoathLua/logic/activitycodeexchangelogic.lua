local ActivityCodeExchangeLogic = class("logic.ActivityCodeExchangeLogic")

function ActivityCodeExchangeLogic:initialize()
  self:ResetData()
end

function ActivityCodeExchangeLogic:ResetData()
end

function ActivityCodeExchangeLogic:GetAxesByExgId(actId, exgId)
  local actData = configManager.GetDataById("config_activity", actId)
  local x = 0
  local y = 0
  local HorizList = actData.p1
  local ExgId = exgId
  local reminder = ExgId % #HorizList
  local quotient = math.floor(ExgId / #HorizList)
  if reminder == 0 then
    x = quotient
    y = #HorizList
  else
    x = quotient + 1
    y = reminder
  end
  return x, y
end

function ActivityCodeExchangeLogic:GetCanExg(actId, exgId)
  local isInfinite, remainNum = self:GetRemainChangeTime(actId, exgId)
  local codeNum = self:GetCodeChangeTime(actId, exgId)
  local canChange = false
  if isInfinite and 0 < codeNum or 0 < remainNum and 0 < codeNum then
    canChange = true
  end
  local maxChange = codeNum
  if 0 < remainNum and 0 < codeNum and remainNum < codeNum then
    maxChange = remainNum
  end
  return canChange, maxChange
end

function ActivityCodeExchangeLogic:GetCanExgCode(team)
  local consume = team[1]
  local rate_num = configManager.GetDataById("config_parameter", 357).value
  local canChange = rate_num <= Logic.bagLogic:GetBagItemNum(consume)
  local maxChange = math.floor(Logic.bagLogic:GetBagItemNum(consume) / rate_num)
  return canChange, maxChange
end

function ActivityCodeExchangeLogic:GetCodeChangeTime(actId, exgId)
  local actData = configManager.GetDataById("config_activity", actId)
  local x, y = self:GetAxesByExgId(actId, exgId)
  local x_id = actData.p1[x]
  local y_id = actData.p2[y]
  local vertBagNum = actData.p1[x] ~= -1 and Logic.bagLogic:GetBagItemNum(x_id) or -1
  local horizBagNum = actData.p2[y] ~= -1 and Logic.bagLogic:GetBagItemNum(y_id) or -1
  if x_id == -1 and y_id == -1 then
    return -1
  elseif x_id == -1 and y_id ~= -1 then
    return horizBagNum
  elseif x_id ~= -1 and y_id == -1 then
    return vertBagNum
  end
  local codeNum = horizBagNum
  if vertBagNum < horizBagNum then
    codeNum = vertBagNum
  end
  return codeNum
end

function ActivityCodeExchangeLogic:GetRemainChangeTime(actId, exgId)
  local actData = configManager.GetDataById("config_activity", actId)
  local limitNum = actData.p4[exgId][2]
  local receptData = Data.activityCodeExchangeData:GetReceiptData()
  local receptNum = receptData[exgId] or 0
  local remainNum = limitNum - receptNum
  local isInfinite = limitNum == -1
  return isInfinite, remainNum
end

function ActivityCodeExchangeLogic:GetStateByAxes(x, y, lenY)
  local exgId = (x - 1) * lenY + y
  local receptData = Data.activityCodeExchangeData:GetReceiptData()
  local receptNum = receptData[exgId] or 0
  if 0 < receptNum then
    return true
  end
  return false
end

function ActivityCodeExchangeLogic:ShowCodeExgReward(state)
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.JCodeExchange)
  local RewardId = configManager.GetDataById("config_activity", actId).p4[state.id][1]
  local rewardids = {}
  local count = state.num
  while 0 < count do
    table.insert(rewardids, RewardId)
    count = count - 1
  end
  if actId then
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = Logic.rewardLogic:FormatRewards(rewardids)
    })
  end
end

function ActivityCodeExchangeLogic:ShowCodeExgCode(state)
  local showDatas = {}
  table.insert(showDatas, state)
  UIHelper.OpenPage("GetRewardsPage", {Rewards = showDatas})
end

return ActivityCodeExchangeLogic
