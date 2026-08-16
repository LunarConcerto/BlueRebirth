local RechargeLogic = class("logic.RechargeLogic")
local ANDROID_PL = {}

function RechargeLogic:initialize()
  self:ResetData()
end

function RechargeLogic:ResetData()
  self.os = nil
  self.pl = nil
  self.configData = nil
  self.configShowData = nil
end

function RechargeLogic:GetMonthCardData()
  local data = configManager.GetData("config_recharge")
  if self.os == nil then
    self.os = platformManager:GetOS()
  end
  if self.pl == nil then
    self.pl = platformManager:GetPL()
  end
  for k, v in pairs(data) do
    if self:IsMonthCard(v.paytype) and self:_CheckPL(v) then
      return v
    end
  end
  return nil
end

function RechargeLogic:GetBigMonthCardData()
  local data = configManager.GetData("config_recharge")
  for k, v in pairs(data) do
    if self:IsBigMonthCard(v.paytype) then
      return v
    end
  end
  return nil
end

function RechargeLogic:GetConfigShowData()
  if self.configShowData == nil then
    if self.os == nil then
      self.os = platformManager:GetOS()
    end
    if self.pl == nil then
      self.pl = platformManager:GetPL()
    end
    local data = configManager.GetData("config_recharge")
    self.configShowData = {}
    for i = 1, RechargeTogType.count - 1 do
      self.configShowData[i] = {}
    end
    local appReview = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW
    for k, v in pairs(data) do
      if self:_CheckPL(v) and (v.isshow == 1 or appReview) then
        table.insert(self.configShowData[v.tagid], v)
      end
    end
  end
  return self.configShowData
end

function RechargeLogic:_GetShowConfigData()
  if self.os == nil then
    self.os = platformManager:GetOS()
  end
  if self.pl == nil then
    self.pl = platformManager:GetPL()
  end
  local appReview = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW
  local data = configManager.GetData("config_recharge")
  local showData = {}
  for i = 1, RechargeTogType.count - 1 do
    showData[i] = {}
  end
  for k, v in pairs(data) do
    if self:_CheckPL(v) then
      if appReview then
        if v.paytype == RechargeItemType.SpacingItem then
          local isInPeriod = #v.double_period <= 0
          if not isInPeriod then
            for _, perId in pairs(v.double_period) do
              if PeriodManager:IsInPeriod(perId) then
                isInPeriod = true
                break
              end
            end
          end
          if isInPeriod then
            table.insert(showData[v.tagid], v)
          end
        elseif v.paytype ~= RechargeItemType.ShopGoods then
          table.insert(showData[v.tagid], v)
        end
      elseif v.isshow == 1 then
        local isInPeriod = true
        if v.paytype == RechargeItemType.SpacingItem or v.paytype == RechargeItemType.LuckyBuy then
          isInPeriod = #v.double_period <= 0
          if not isInPeriod then
            for _, perId in pairs(v.double_period) do
              if PeriodManager:IsInPeriod(perId) then
                isInPeriod = true
                break
              end
            end
          end
        end
        if isInPeriod then
          local ret, _ = Logic.gameLimitLogic.CheckConditionByArrId(v.random_limit)
          if ret then
            if 0 < #v.open_limit then
              local ret = Logic.shopLogic:IsOpendCondGood(RecommandGoodsType.Recharge, v.id)
              if ret then
                table.insert(showData[v.tagid], v)
              end
            else
              table.insert(showData[v.tagid], v)
            end
          end
        end
      end
    end
  end
  return showData
end

function RechargeLogic:_CheckPL(value)
  if value.channel ~= GAME_OS.all then
    if value.channel == GAME_OS[self.os] then
      return true
    elseif self.os == "android" then
      return value.channel == ANDROID_PL[self.pl]
    else
      return false
    end
  else
    return true
  end
end

function RechargeLogic:CheckRechargeStatus(rechargeId)
  local cfg = configManager.GetDataById("config_recharge", rechargeId)
  local serverData = self:GetServerDataById(rechargeId)
  local currBuyCount = serverData and serverData.LimitBuyTimes or 0
  local totalCount = cfg.buynum
  local soldOut = 0 < totalCount and currBuyCount >= totalCount
  local isShow = cfg.isshow == 1 and self:_CheckPL(cfg)
  if isShow then
    local ret, _ = Logic.gameLimitLogic.CheckConditionByArrId(cfg.random_limit)
    if ret then
      if 0 < #cfg.open_limit then
        local ret = Logic.shopLogic:IsOpendCondGood(RecommandGoodsType.Recharge, cfg.id)
        isShow = ret
      else
        isShow = ret
      end
    else
      isShow = ret
    end
  end
  return isShow, soldOut
end

function RechargeLogic:_FilterAndSortServerData(data, tagType)
  local createTime = Data.userData:GetCreateTime()
  local showData = {}
  for k, v in pairs(data) do
    local serverData = self:GetServerDataById(v.id)
    local num = serverData and serverData.LimitBuyTimes or 0
    local ignorThis = false
    ignorThis = BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW and (v.paytype == RechargeItemType.MonthCard or v.paytype == RechargeItemType.WeekCard)
    local canBuy = 0 >= v.buynum or num < v.buynum
    local lastCanbuy = true
    if canBuy and 0 < v.last_id then
      local lastServerData = self:GetServerDataById(v.last_id)
      local lastNum = lastServerData and lastServerData.LimitBuyTimes or 0
      local lastConfig = configManager.GetDataById("config_recharge", v.last_id)
      if 0 >= v.buynum or 0 >= lastConfig.buynum then
        logError("\230\156\137\229\137\141\229\144\142\231\189\174\229\133\179\231\179\187\231\154\132\231\164\188\229\140\133\229\191\133\233\161\187\233\133\141\231\189\174\228\184\186\233\153\144\232\180\173\229\149\134\229\147\129,\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165recharge\233\133\141\231\189\174  id\228\184\186" .. v.id .. "\231\154\132\229\149\134\229\147\129\229\146\140id\228\184\186" .. lastConfig.id .. "\231\154\132\229\149\134\229\147\129")
      end
      canBuy = lastNum >= lastConfig.buynum
      lastCanbuy = canBuy
    end
    if self:IsMonthCard(v.paytype) or self:IsWeekCard(v.paytype) or self:IsBigMonthCard(v.paytype) then
      local remainDays = self:GetDaysRemaining(v.id)
      if remainDays then
        v.newItem = 0 < remainDays and 1 or 0
      else
        v.newItem = 0
      end
    elseif serverData then
      if tagType == RechargeTogType.recharge then
        if serverData.Status == 0 then
          v.newItem = 1
        else
          v.newItem = 0
        end
      else
        v.newItem = canBuy and 0 or 1
      end
    else
      v.newItem = 0
    end
    v.order = ScriptManager:RunCmd(v.orderscript, v.orderparam, createTime)
    if (v.paytype == RechargeItemType.MonthCard or canBuy or lastCanbuy and v.buynum_refreshtime ~= 0) and not ignorThis then
      table.insert(showData, v)
    end
  end
  table.sort(showData, function(data1, data2)
    if data1.newItem == data2.newItem then
      return data1.order < data2.order
    else
      return data1.newItem < data2.newItem
    end
  end)
  return showData
end

function RechargeLogic:GetServerDataById(id)
  local serverData = Data.rechargeData:GetRechargeData().Info
  for k, v in pairs(serverData) do
    if v.RechargeId == id then
      return v
    end
  end
  return nil
end

function RechargeLogic:IsMonthCard(paytype)
  return paytype == RechargeItemType.MonthCard or paytype == RechargeItemType.Subscribe
end

function RechargeLogic:IsWeekCard(paytype)
  return paytype == RechargeItemType.WeekCard
end

function RechargeLogic:IsBigMonthCard(paytype)
  return paytype == RechargeItemType.BigMonthCard
end

function RechargeLogic:GetDaysRemaining(id)
  local info = configManager.GetDataById("config_recharge", id)
  local datas
  if self:IsMonthCard(info.paytype) then
    datas = Data.rechargeData:GetRechargeData().MonthCard
  elseif self:IsWeekCard(info.paytype) then
    datas = Data.rechargeData:GetRechargeData().WeekCard
  elseif self:IsBigMonthCard(info.paytype) then
    datas = Data.rechargeData:GetRechargeData().SupperMonthCard
  end
  local serverTime = time.getSvrTime()
  if datas and datas.DueDate and serverTime < datas.DueDate then
    local days = time.getDaysDiff(datas.DueDate, true)
    return days
  end
  return nil
end

function RechargeLogic:GetSubscribeRemaining()
  local datas = Data.rechargeData:GetRechargeData().MonthCard
  if datas and datas.SubsEndTime then
    return datas.SubsEndTime > time.getSvrTime()
  end
  return false
end

function RechargeLogic:CheckLoginRewards()
  local rewards = Data.rechargeData:CheckMonthRewardData()
  local result = rewards and GetTableLength(rewards) > 0 or false
  return result
end

function RechargeLogic:CheckLoginBigMonthRewards()
  local rewards = Data.rechargeData:CheckBigMonthRewardData()
  local result = rewards and GetTableLength(rewards) > 0 or false
  return result
end

function RechargeLogic:GetShowData()
  self.configData = self:_GetShowConfigData()
  local showData = {}
  for k, v in pairs(self.configData) do
    showData[k] = self:_FilterAndSortServerData(v, k)
  end
  return showData
end

function RechargeLogic:GetFreeSubscribeState()
  platformManager:GetFreeSubscribeState(function(ret)
    self:_GetFreeSubscribeStateCallBack(ret)
    eventManager:SendEvent(LuaEvent.FreeSubscribeStateCallBack, self.freeState)
  end)
end

function RechargeLogic:_GetFreeSubscribeStateCallBack(ret)
  if ret then
    local data = ret.data
    if data and data.isUseTrial then
      self.freeState = data.isUseTrial
    end
  end
end

function RechargeLogic:GetPayBackState()
  return Logic.emailLogic:HaveMailAndNoGotReward(3000)
end

function RechargeLogic:CheckMonthCardBuyType(info)
  local buyType = 0
  local serverData = self:GetServerDataById(info.id)
  local num = serverData and serverData.LimitBuyTimes or 0
  if 0 < info.buynum and num >= info.buynum then
    buyType = -1
  elseif self:GetPayBackState() then
    buyType = -2
  end
  return buyType
end

return RechargeLogic
