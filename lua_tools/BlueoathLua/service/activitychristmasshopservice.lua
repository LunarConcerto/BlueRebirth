local ActivityChristmasShopService = class("service.ActivityChristmasShopService", Service.BaseService)

function ActivityChristmasShopService:initialize()
  self:_InitHandlers()
end

function ActivityChristmasShopService:_InitHandlers()
  self:BindEvent("activitychristmasshop.BuyBlindBox", self._ReceiveBuyBlindBox, self)
  self:BindEvent("activitychristmasshop.BuyBlindItem", self._ReceiveBuyBlindItem, self)
  self:BindEvent("activitychristmasshop.SetToy", self._ReceiveSetToy, self)
  self:BindEvent("activitychristmasshop.GiveMeCrystalBall", self._ReceiveGiveMeCrystalBall, self)
  self:BindEvent("activitychristmasshop.UpdateActivityChristmasShopInfo", self._ReceiveUpdateActivityChristmasShopInfo, self)
  self:BindEvent("activitychristmasshop.OpenSpecialBlindBox", self._OpenSpecialBlindBoxRet, self)
end

function ActivityChristmasShopService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      return true
    end
    if callback ~= nil then
      callback()
    end
    return true
  end
  return false
end

function ActivityChristmasShopService:SendBuyBlindBox(arg)
  self.toyList = clone(Data.activitychristmasshopData:__GetToyListKeyToKey())
  local data = {}
  data.Index = arg.Index
  data.BuyShop = arg.BuyShop
  local msg = dataChangeManager:LuaToPb(data, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPBUYBLINDBOXARG)
  self:SendNetEvent("activitychristmasshop.BuyBlindBox", msg, arg)
end

function ActivityChristmasShopService:_ReceiveBuyBlindBox(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyBlindBox", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPBUYBLINDBOXRET)
  if self.toyList[data.ToyId] then
    self:SendLuaEvent(LuaEvent.ACShop_GetToy, {
      ToyId = data.ToyId,
      repeated = true
    })
  else
    self:SendLuaEvent(LuaEvent.ACShop_GetToy, {
      ToyId = data.ToyId,
      repeated = false
    })
  end
  if Data.activitychristmasshopData:GetCrystalBallToyId() == 0 then
    eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
  end
end

function ActivityChristmasShopService:SendBuyBlindItem(arg)
  local data = {}
  data.BuyWay = arg.BuyWay
  data.BuyTimes = arg.BuyTimes or 1
  local msg = dataChangeManager:LuaToPb(data, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPBUYBLINDITEMARG)
  self:SendNetEvent("activitychristmasshop.BuyBlindItem", msg, arg)
end

function ActivityChristmasShopService:_ReceiveBuyBlindItem(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyBlindItem", err, errmsg) then
    return
  end
  local rewards = {}
  local temp = {}
  temp.Type = GoodsType.ITEM
  temp.ConfigId = BLINDBOX_CUR_ID
  temp.Num = state.BuyTimes
  table.insert(rewards, temp)
  UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards, DontMerge = true})
end

function ActivityChristmasShopService:SendSetToy(arg)
  local data = {}
  data.ToyId = arg.ToyId
  local msg = dataChangeManager:LuaToPb(data, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPSETTOYARG)
  self:SendNetEvent("activitychristmasshop.SetToy", msg, arg)
end

function ActivityChristmasShopService:_ReceiveSetToy(ret, state, err, errmsg)
  if self:checkErr("_ReceiveSetToy", err, errmsg) then
    return
  end
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
end

function ActivityChristmasShopService:SendGiveMeCrystalBall(arg)
  self:SendNetEvent("activitychristmasshop.GiveMeCrystalBall", nil, arg)
end

function ActivityChristmasShopService:_ReceiveGiveMeCrystalBall(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGiveMeCrystalBall", err, errmsg) then
    return
  end
  local rewards = {}
  local temp = {}
  if state.IsHave then
    local repeatItem = configManager.GetDataById("config_parameter", 411).arrValue
    temp.Type = repeatItem[1]
    temp.ConfigId = repeatItem[2]
    temp.Num = repeatItem[3]
    table.insert(rewards, temp)
  else
    temp.Type = GoodsType.ITEM
    temp.ConfigId = state.ID
    temp.Num = 1
    table.insert(rewards, temp)
  end
  UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards, DontMerge = true})
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
end

function ActivityChristmasShopService:OpenSpecialBlindBox(arg)
  self.toyList = clone(Data.activitychristmasshopData:__GetToyListKeyToKey())
  local data = {}
  data.ItemId = arg.ItemId
  local msg = dataChangeManager:LuaToPb(data, activitychristmasshop_pb.TOPENSPECIALBOXARG)
  self:SendNetEvent("activitychristmasshop.OpenSpecialBlindBox", msg, arg)
end

function ActivityChristmasShopService:_OpenSpecialBlindBoxRet(ret, state, err, errmsg)
  if self:checkErr("_OpenSpecialBlindBoxRet", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPBUYBLINDBOXRET)
  if self.toyList[data.ToyId] then
    self:SendLuaEvent(LuaEvent.ACShop_GetToy, {
      ToyId = data.ToyId,
      repeated = true
    })
  else
    self:SendLuaEvent(LuaEvent.ACShop_GetToy, {
      ToyId = data.ToyId,
      repeated = false
    })
  end
end

function ActivityChristmasShopService:_ReceiveUpdateActivityChristmasShopInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateActivityChristmasShopInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, activitychristmasshop_pb.TACTIVITYCHRISTMASSHOPINFORET)
  Data.activitychristmasshopData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.ACShop_RefreshData)
end

return ActivityChristmasShopService
