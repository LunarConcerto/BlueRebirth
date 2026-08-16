local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local ChristmasSalePage = class("ui.page.Activity.Christmas.ChristmasSalePage", LuaUIPage)

function ChristmasSalePage:DoInit()
end

function ChristmasSalePage:DoOnOpen()
  self.mActivityId = Activity.SpecialChristmasFashion
  self:ShowPage()
end

function ChristmasSalePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateFashionInfo, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, function()
    UIHelper.ClosePage(self:GetName())
  end)
  self:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self.BuyGoodsCallBack, self)
end

function ChristmasSalePage:DoOnHide()
end

function ChristmasSalePage:DoOnClose()
end

local ShopQualityIcon = {
  "uipic_ui_attribute_bg_zhuangbeikuang_hui",
  "uipic_ui_attribute_bg_zhuangbeikuang_lan",
  "uipic_ui_attribute_bg_zhuangbeikuang_zi",
  "uipic_ui_attribute_bg_zhuangbeikuang_jin",
  "uipic_ui_common_bg_zhuangbeikuang_cai"
}
local goodsId = 90014

function ChristmasSalePage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local goodsCfg = configManager.GetDataById("config_shop_goods", goodsId)
  local goodsType = goodsCfg.goods[1]
  if goodsType ~= GoodsType.FASHION then
    logError("err shop goods", goodsId)
    return
  end
  local fashionId = goodsCfg.goods[2]
  local goodsInfo = Logic.bagLogic:GetItemByTempateId(goodsCfg.goods[1], goodsCfg.goods[2])
  local shipName = Logic.fashionLogic:GetFashionShipName(goodsCfg.goods[2])
  UIHelper.SetText(self.tab_Widgets.textName, shipName)
  UIHelper.SetText(self.tab_Widgets.textFashionName, goodsInfo.name)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  if self.mTimer ~= nil then
    self.mTimer:Stop()
    self.mTimer = nil
  end
  self.mTimer = self:CreateTimer(function()
    local svrTime = time.getSvrTime()
    local surplusTime = endTime - svrTime
    if surplusTime <= 0 then
      self.mTimer:Stop()
      self.mTimer = nil
      UIHelper.SetText(self.tab_Widgets.textLeftTime, "")
    else
      UIHelper.SetText(self.tab_Widgets.textLeftTime, UIHelper.GetCountDownStr(surplusTime))
    end
  end, 1, -1)
  self.mTimer:Start()
  local part = self.tab_Widgets.itemPart:GetLuaTableParts()
  UIHelper.SetText(part.textName, goodsInfo.name)
  UIHelper.SetText(part.textFashionHero, shipName)
  UIHelper.SetImage(part.imgIcon, tostring(goodsInfo.icon))
  UIHelper.SetImage(part.imgQuality, ShopQualityIcon[goodsInfo.quality])
  local buyNeedType = goodsCfg.price2
  local buyNeedCurrencyOne = buyNeedType[1]
  local type = buyNeedCurrencyOne[1]
  local currencyId = buyNeedCurrencyOne[2]
  local txt_discountAfter = buyNeedCurrencyOne[3]
  local icon = Logic.goodsLogic:GetSmallIcon(currencyId, type)
  UIHelper.SetImage(part.imgPrice, tostring(icon), true)
  UIHelper.SetText(part.textPrice, txt_discountAfter)
  local isHave = Logic.fashionLogic:CheckFashionOwn(fashionId)
  if isHave then
    part.btnBuy.gameObject:SetActive(false)
    part.btnHasBuy.gameObject:SetActive(true)
  else
    part.btnBuy.gameObject:SetActive(true)
    part.btnHasBuy.gameObject:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btnBuy, function()
      if not Data.activityData:IsActivityOpen(self.mActivityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      local buyParams, errMsg = Logic.shopLogic:GetFashionBuyParams(fashionId)
      if errMsg ~= nil then
        noticeManager:ShowTip(errMsg)
        return
      end
      local param = ItemInfoPage:GenFashionData(buyParams.shopId, buyParams.buyNum, buyParams.fashionCfg, buyParams.goodsCfg, buyParams.gridId, true)
      UIHelper.OpenPage("ItemInfoPage", param)
    end)
  end
end

function ChristmasSalePage:BuyGoodsCallBack(param)
  local isFashion, ssIdTab, fashionTabId = Logic.rewardLogic:_CheckFashionInReward(param.Reward)
  if isFashion then
    local dotInfo = {info = "shop_buy", fashion_id = fashionTabId}
    RetentionHelper.Retention(PlatformDotType.fashionGetLog, dotInfo)
  end
  Logic.rewardLogic:ShowFashion({
    rewards = param.Reward
  })
end

return ChristmasSalePage
