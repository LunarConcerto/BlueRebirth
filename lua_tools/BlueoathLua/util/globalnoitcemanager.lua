local GlobalNoitceManager = class("util.GlobalNoitceManager")

function GlobalNoitceManager:initialize()
  eventManager:RegisterEvent(LuaCSharpEvent.TimelineChangeScene, function(self, param)
    self:_ChangeScene(param)
  end, self)
end

function GlobalNoitceManager:OpenBuyResBoxInfo(currencyName, resType)
  local tipInfo = string.format(UIHelper.GetString(230009), currencyName)
  local tabParam = {
    msgType = 2,
    callback = function(bool)
      if bool then
        UIHelper.OpenPage("BuyResourcePage", resType)
      end
    end,
    nameOk = "\232\180\173\228\185\176"
  }
  noticeManager:ShowMsgBox(tipInfo, tabParam)
end

function GlobalNoitceManager:OpenCurrencyNotEnoughTipInfo(currencyName)
  local tipInfo = string.format(UIHelper.GetString(270001), currencyName)
  noticeManager:ShowTip(tipInfo)
end

function GlobalNoitceManager:_ChangeScene(param)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, param)
end

function GlobalNoitceManager:_OpenGoShopBox(itemId)
  local itemInfo = Logic.bagLogic:GetItemByConfig(itemId)
  local str = string.format(UIHelper.GetString(230009), itemInfo.name)
  local tabParam = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        local param
        if itemId == 10007 or itemId == 10180 or itemId == 10181 or itemId == 10031 then
          param = {
            shopId = ShopId.Diamond
          }
        end
        UIHelper.OpenPage("ShopPage", param)
      end
    end,
    nameOk = "\232\180\173\228\185\176"
  }
  noticeManager:ShowMsgBox(str, tabParam)
end

function GlobalNoitceManager:ShowItemInfoPage(type, id)
  UIHelper.ClosePage("ItemInfoPage")
  if type == GoodsType.CURRENCY then
    local currencyConf = configManager.GetDataById("config_currency", id)
    if id == CurrencyType.SUPPLY then
      globalNoitceManager:OpenBuyResBoxInfo(currencyConf.name, BuyResource.Supply)
      return
    elseif id == CurrencyType.GOLD then
      globalNoitceManager:OpenBuyResBoxInfo(currencyConf.name, BuyResource.Gold)
      return
    elseif id == CurrencyType.DIAMOND then
      if platformManager:useSDK() then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              Logic.shopLogic:OpenRechargeShop()
            end
          end
        }
        local tips = UIHelper.GetString(800003)
        noticeManager:ShowMsgBox(tips, tabParams)
      end
      return
    elseif id == CurrencyType.LUCKY then
      if platformManager:useSDK() then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              Logic.shopLogic:OpenLuckyRechargeShop()
            end
          end
        }
        local tips = UIHelper.GetString(270043)
        noticeManager:ShowMsgBox(tips, tabParams)
      end
      return
    end
  elseif type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = id,
      showEquipType = ShowEquipType.Simple,
      showDrop = true
    })
    return
  end
  local config = Logic.goodsLogic:GetConfigByTypeAndId(id, type)
  if config.drop_path then
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(type, id, true))
  end
end

return GlobalNoitceManager
