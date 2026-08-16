local ShopService = class("servic.ShopService", Service.BaseService)

function ShopService:initialize()
  self:_InitHandlers()
end

function ShopService:_InitHandlers()
  self:BindEvent("shop.GetShopsInfo", self._GetShopsInfoCallBack, self)
  self:BindEvent("shop.BuyGoods", self._GetBuyGoodsCallBack, self)
  self:BindEvent("shop.RefreshShop", self._GetRefreshShopCallBack, self)
  self:BindEvent("shop.UpdateShopInfo", self._UpdateShopInfoCallBack, self)
end

function ShopService:SendGetShopsInfo()
  self:SendNetEvent("shop.GetShopsInfo")
end

function ShopService:_GetShopsInfoCallBack(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.GetShopsInfoMsg)
  else
    logError("\232\142\183\229\143\150\230\156\141\229\138\161\229\153\168\228\191\161\230\129\175\233\148\153\232\175\175" .. err .. ", errmsg: " .. errmsg)
  end
end

function ShopService:SendBuyGoods(shopId, goodId, buyNum, discountId)
  discountId = discountId and discountId or {}
  local args = {
    ShopId = shopId,
    GoodId = goodId,
    BuyNum = buyNum,
    DiscountId = discountId
  }
  args = dataChangeManager:LuaToPb(args, shop_pb.TBUYGOODSARG)
  self:SendNetEvent("shop.BuyGoods", args)
end

function ShopService:_GetBuyGoodsCallBack(ret, state, err, errmsg)
  if err == 0 then
    local buyGoodsInfo = dataChangeManager:PbToLua(ret, shop_pb.TBUYGOODSRET)
    self:SendLuaEvent(LuaEvent.GetBuyGoodsMsg, buyGoodsInfo)
    self:SendLuaEvent(LuaEvent.ShopLevelGift)
  else
    logError("err: ", err, "errmsg:", errmsg)
  end
end

function ShopService:SetRefreshShopInfo(shopId)
  local args = {ShopId = shopId}
  args = dataChangeManager:LuaToPb(args, shop_pb.TSHOPREFRESHARG)
  self:SendNetEvent("shop.RefreshShop", args)
end

function ShopService:_GetRefreshShopCallBack(ret, state, err, errmsg)
  if err == 0 then
    local freshShopInfo = dataChangeManager:PbToLua(ret, shop_pb.TRETSHOPINFO)
    self:SendLuaEvent(LuaEvent.GetRefreshShopMsg)
  else
    logError("_GetRefreshShopCallBack err" .. errmsg)
  end
end

function ShopService:_UpdateShopInfoCallBack(ret, state, err, errmsg)
  if err == 0 then
    local shopsInfo = dataChangeManager:PbToLua(ret, shop_pb.TRETSHOPSINFO)
    Data.shopData:SetShopsInfo(shopsInfo)
    self:SendLuaEvent(LuaEvent.UpdateShopInfo, shopsInfo)
  else
    logError("\232\142\183\229\143\150\230\156\141\229\138\161\229\153\168\228\191\161\230\129\175\233\148\153\232\175\175" .. err .. ", errmsg: " .. errmsg)
  end
end

return ShopService
