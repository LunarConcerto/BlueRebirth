local ConditionCheckManager = class("util.ConditionCheckManager")

function ConditionCheckManager:initialize()
  self.BuyResParam = 0
end

function ConditionCheckManager:CheckOneCurrencyIsEnough(tabCondition, isAutoOpen)
  local currencyId = tabCondition.CurrencyId
  local nCostNum = tabCondition.CostNum
  local currencyConf = configManager.GetDataById("config_currency", currencyId)
  if currencyConf == nil then
    return
  end
  local currencyName = currencyConf.name
  local userCurrencyData = Logic.shopLogic:GetUserCurrencyNum(currencyId)
  if nCostNum <= userCurrencyData then
    return true
  end
  local resType = 0
  local config = Logic.goodsLogic:GetConfigByTypeAndId(currencyId, GoodsType.CURRENCY)
  if isAutoOpen and next(config.drop_path) == nil then
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, currencyId)
  else
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, currencyId)
    globalNoitceManager:OpenCurrencyNotEnoughTipInfo(currencyName)
  end
  return false
end

function ConditionCheckManager:CheckCurrencyIsEnough(tabConditions, isAutoOpen)
  if tabConditions == nil or type(tabConditions) ~= "table" or #tabConditions < 1 then
    logError("tabConditions err")
    return
  end
  for i = 1, #tabConditions do
    local tabOneCondition = tabConditions[i]
    if not self:CheckOneCurrencyIsEnough(tabOneCondition, isAutoOpen) then
      return false
    end
  end
  return true
end

function ConditionCheckManager:CheckConditionsIsEnough(tabConditions, isAutoOpen)
  if tabConditions == nil or type(tabConditions) ~= "table" then
    logError("tabConditions err")
    return
  end
  if #tabConditions < 1 then
    return true
  end
  for i = 1, #tabConditions do
    local tabOneCondition = tabConditions[i]
    if not self:CheckConditionIsEnough(tabOneCondition, isAutoOpen) then
      return false
    end
  end
  return true
end

function ConditionCheckManager:CheckUserLevelIsUp(targetLevel)
  local userLevel = Data.userData:GetUserData().Level
  return targetLevel <= userLevel
end

function ConditionCheckManager:CheckUserExp(targetExp)
  local userExp = Data.userData:GetUserData().Exp
  return targetExp <= userExp
end

function ConditionCheckManager:CheckUserVipLevel(targetVipLevel)
  local userVipLevel = Data.userData:GetUserData().VipLevel
  return targetVipLevel <= userVipLevel
end

function ConditionCheckManager:CheckUserVipExp(targetVipExp)
  local userVipExp = Data.userData:GetUserData().VipExp
  return targetVipExp <= userVipExp
end

function ConditionCheckManager:Checkvalid(str)
  if str == nil then
    return false
  end
  if str == "" then
    return false
  end
  if str == "[]" then
    return false
  end
  return true
end

function ConditionCheckManager:CheckItemIsEnough(tabCondition, isAutoOpen)
  local currencyId = tabCondition.CurrencyId
  local nCostNum = tabCondition.CostNum
  local tableInfo = Logic.shopLogic:GetTableIndexConfById(tabCondition.Type)
  if tableInfo.bag_index ~= 1 then
    logError("\230\154\130\230\151\182\228\184\141\230\148\175\230\140\129\232\191\153\231\167\141\231\177\187\229\158\139:", type)
    return false
  end
  local userCurrencyData = Logic.bagLogic:GetBagItemNum(currencyId)
  local currencyConf = Logic.bagLogic:GetItemByConfig(currencyId)
  local currencyName = currencyConf.name
  if nCostNum <= userCurrencyData then
    return true
  end
  if isAutoOpen ~= nil then
    noticeManager:ShowTip(string.format(UIHelper.GetString(270001), currencyName))
    globalNoitceManager:ShowItemInfoPage(tabCondition.Type, currencyId)
  end
  return false
end

function ConditionCheckManager:CheckConditionIsEnough(tabCondition, isAutoOpen)
  local type = tabCondition.Type
  if type == GoodsType.CURRENCY then
    return ConditionCheckManager:CheckOneCurrencyIsEnough(tabCondition, isAutoOpen)
  else
    return ConditionCheckManager:CheckItemIsEnough(tabCondition, isAutoOpen)
  end
end

function ConditionCheckManager:CheckGoodEnough(tblCondition)
  local nGoodsType = tblCondition[1]
  local nId = tblCondition[2]
  local nNum = tblCondition[3]
  if nGoodsType == GoodsType.CURRENCY then
    local tblParam = {}
    tblParam.CurrencyId = nId
    tblParam.CostNum = nNum
    return self:CheckOneCurrencyIsEnough(tblParam)
  elseif nGoodsType == GoodsType.ITEM then
    local nHaveNum = Logic.bagLogic:GetBagItemNum(nId)
    return nNum <= nHaveNum
  elseif nGoodsType == GoodsType.SHIP then
    local nHaveNum = Data.heroData:GetHeroCountByTemplateId(nId)
    return nNum <= nHaveNum
  elseif nGoodsType == GoodsType.REWARD_SHIPLEVELUP_ITEM then
    local nHaveNum = Logic.bagLogic:GetBagItemNum(nId)
    return nNum <= nHaveNum
  else
    logError("\228\184\141\230\148\175\230\140\129\231\154\132\231\177\187\229\158\139 " .. tostring(nGoodsType))
  end
end

function ConditionCheckManager:CheckGoodsEnough(tblConditions)
  local nCount = #tblConditions
  for i = 1, nCount do
    local tblParam = tblConditions[i]
    local bEnough = self:CheckGoodEnough(tblParam)
    if not bEnough then
      return false
    end
  end
  return true
end

return ConditionCheckManager
