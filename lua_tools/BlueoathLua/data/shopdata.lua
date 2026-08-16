local ShopData = class("data.ShopData", Data.BaseData)

function ShopData:initialize()
  self:_InitHandlers()
end

function ShopData:_InitHandlers()
  self:ResetData()
end

function ShopData:ResetData()
  self.m_shopInfo = {}
  self.m_refreshTime = 0
  self.m_recommendGoods = {}
  self.m_opendCondGoods = {}
  self.m_shopGoodsConf = configManager.GetData("config_shop_goods")
end

function ShopData:SetShopsInfo(msg)
  if msg.ShopInfo ~= nil then
    for _, info in pairs(msg.ShopInfo) do
      self.m_shopInfo[info.ShopId] = info
    end
  end
  self.m_recommendGoods = msg.GoodList
  self.m_refreshTime = time.getSvrTime()
  if msg.CondGoodList ~= nil then
    for _, info in pairs(msg.CondGoodList) do
      local goodType = info.Type
      if self.m_opendCondGoods[goodType] == nil then
        self.m_opendCondGoods[goodType] = {}
      end
      if self.m_opendCondGoods[goodType][info.GoodId] == nil then
        self.m_opendCondGoods[goodType][info.GoodId] = true
      end
    end
  end
end

function ShopData:GetShopsInfo()
  return SetReadOnlyMeta(self.m_shopInfo)
end

function ShopData:GetShopInfoById(shopId)
  local shopInfo = self.m_shopInfo[shopId]
  if not shopInfo then
    logError("GetShopInfoById Shop Data is nil, shopId:", shopId)
  end
  local shopGoodsInfo = shopInfo.ShopGoodsData
  local shopGoodsRet = {}
  for i = 1, #shopGoodsInfo do
    local goodsId = shopGoodsInfo[i].GoodsId
    if self.m_shopGoodsConf[goodsId] then
      shopGoodsInfo[i].GridId = i - 1
      shopGoodsInfo[i].Visible = self.m_shopGoodsConf[goodsId].goods_visible == 1
      table.insert(shopGoodsRet, shopGoodsInfo[i])
    end
  end
  self.m_shopInfo[shopId].ShopGoodsData = shopGoodsRet
  return self.m_shopInfo[shopId]
end

function ShopData:GetRefreshTime()
  return self.m_refreshTime
end

function ShopData:GetRecommendGoods()
  return self.m_recommendGoods
end

function ShopData:GetOpendCondGood(goodType, goodId)
  return self.m_opendCondGoods
end

function ShopData:SortBySellStatus(shipIdTab)
  for _, v in ipairs(shipIdTab) do
    local shopInfo = self.m_shopInfo[v]
    if shopInfo then
      table.sort(shopInfo.ShopGoodsData, function(data1, data2)
        if data1.Status ~= data2.Status then
          return data1.Status < data2.Status
        else
          return data1.GoodsId < data2.GoodsId
        end
      end)
      self.m_shopInfo[v] = shopInfo
    end
  end
end

function ShopData:GetShopDataById(shopId)
  return self.m_shopInfo[shopId]
end

return ShopData
