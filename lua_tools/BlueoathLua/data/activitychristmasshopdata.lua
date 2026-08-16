local ActivityChristmasShopData = class("data.ActivityChristmasShopData")
BLINDBOX_CUR_ID = 17007
BLINDBOX_TOY_ID = 17008
CrystalBall_ID = 19516
ACS_BUY_WAY = {CUR = 1, TOY = 2}
ACS_BUY_SHOP = {OLD = 1, NEW = 2}
BLINDBOX_TOY_TYPE = {
  ShipGirl = 1,
  Fashion = 2,
  OtherToy = 3
}

function ActivityChristmasShopData:initialize()
  self.mBuyInfo = {}
  self.mToyInfo = {}
  self.mCrystalBallToyId = 0
  self.mIsGiveCrystalBall = 0
end

function ActivityChristmasShopData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.BuyInfo ~= nil and #TRet.BuyInfo > 0 then
    for _, info in ipairs(TRet.BuyInfo) do
      if info.BuyIndex == nil or 0 >= info.BuyIndex then
        self.mBuyInfo = {}
      else
        self.mBuyInfo[info.BuyIndex] = info.BuyCount
      end
    end
  end
  if TRet.ToyInfo ~= nil and 0 < #TRet.ToyInfo then
    for _, info in ipairs(TRet.ToyInfo) do
      if info.ToyId == nil or 0 >= info.ToyId then
        self.mToyInfo = {}
      else
        self.mToyInfo[info.ToyId] = info.OwnCount
      end
    end
  end
  if TRet.CrystalBallToyId ~= nil then
    self.mCrystalBallToyId = TRet.CrystalBallToyId
  end
  if TRet.IsGiveCrystalBall ~= nil then
    self.mIsGiveCrystalBall = TRet.IsGiveCrystalBall
  end
end

function ActivityChristmasShopData:GetToyList()
  local list = {}
  for toyId, _ in pairs(self.mToyInfo) do
    table.insert(list, toyId)
  end
  return list
end

function ActivityChristmasShopData:__GetToyListKeyToKey()
  local list = {}
  for toyId, _ in pairs(self.mToyInfo) do
    list[toyId] = toyId
  end
  return list
end

function ActivityChristmasShopData:GetCanGetToyList()
  local list = {}
  local cfgAll = configManager.GetData("config_interaction_figurte")
  local myToyList = self:__GetToyListKeyToKey()
  for toyId, cfg in pairs(cfgAll) do
    local showId = self:__GetId(toyId, cfg, myToyList)
    if showId ~= 0 then
      table.insert(list, toyId)
    end
  end
  return list
end

function ActivityChristmasShopData:__GetId(toyId, cfg, myToyList)
  if myToyList[toyId] then
    return toyId
  end
  if cfg.figure_type == BLINDBOX_TOY_TYPE.ShipGirl and Logic.illustrateLogic:HaveIllustrate(toyId) then
    return toyId
  end
  if cfg.figure_type == BLINDBOX_TOY_TYPE.Fashion and Logic.fashionLogic:CheckFashionOwn(toyId) then
    return toyId
  end
  return 0
end

function ActivityChristmasShopData:GetCrystalBallToyId()
  return self.mCrystalBallToyId or 0
end

function ActivityChristmasShopData:IsBuy(buyIndex)
  local buyc = self.mBuyInfo[buyIndex] or 0
  return 0 < buyc
end

function ActivityChristmasShopData:IsGiveCrystalBall()
  local isGive = self.mIsGiveCrystalBall or 0
  return 0 < isGive
end

return ActivityChristmasShopData
