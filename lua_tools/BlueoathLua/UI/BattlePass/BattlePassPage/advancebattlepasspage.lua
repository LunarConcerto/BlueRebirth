local AdvanceBattlePassPage = class("UI.BattlePass.BattlePassPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function AdvanceBattlePassPage:DoInit()
end

function AdvanceBattlePassPage:DoOnOpen()
  local customparam = {}
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.DIAMOND
  })
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.LUCKY
  })
  table.insert(customparam, {
    GoodsType.CURRENCY,
    CurrencyType.BATTLEPASSGOLD
  })
  self:OpenTopPageNoTitle("AdvanceBattlePassPage", 1, true, nil, customparam)
  self:ShowPartCommanderOrder()
  self:ShowPartSecretOrder()
end

function AdvanceBattlePassPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.BattlePass_RecieveBuyType, function(page, param)
    UIHelper.ClosePage(self:GetName())
    eventManager:SendEvent(LuaEvent.BattlePass_EffectBuyType, param)
  end)
end

function AdvanceBattlePassPage:DoOnHide()
end

function AdvanceBattlePassPage:DoOnClose()
end

function AdvanceBattlePassPage:ShowPartCommanderOrder()
  local paramCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
  local priceId = paramCfg.advance_price_1[1]
  local needNum = paramCfg.advance_price_1[2]
  local partC = self.tab_Widgets.partCommanderOrder:GetLuaTableParts()
  UGUIEventListener.AddButtonOnClick(partC.btnBuy, function()
    local haveNum = Data.userData:GetCurrency(priceId)
    if haveNum < needNum then
      globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, priceId)
      return
    end
    local content = UIHelper.GetLocString(3310007, needNum)
    local callback = function()
      Service.battlepassService:SendBuyPassType({
        BuyType = BATTLEPASS_BUYTYPE.Advance1
      })
    end
    UIHelper.OpenPage("BattlePassNotice", {Content = content, Callback = callback})
  end)
  local display = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, paramCfg.advance_price_1[1])
  UIHelper.SetImage(partC.imgCurrency, display.icon_small)
  UIHelper.SetText(partC.textPrice, paramCfg.advance_price_1[2])
  if paramCfg.advance_reward_1 > 0 then
    partC.objRewardShow:SetActive(true)
    local rewards = Logic.rewardLogic:FormatRewardById(paramCfg.advance_reward_1)
    UIHelper.CreateSubPart(partC.objItem, partC.rectContent, #rewards, function(index, subpart)
      local res = rewards[index]
      local display = ItemInfoPage.GenDisplayData(res.Type, res.ConfigId)
      UIHelper.SetImage(subpart.imgIcon, display.icon)
      UIHelper.SetImage(subpart.imgQuality, QualityIcon[display.quality])
      UIHelper.SetLocText(subpart.textNum, 710082, res.Num)
      UGUIEventListener.AddButtonOnClick(subpart.btnIcon, function()
        Logic.itemLogic:ShowItemInfo(res.Type, res.ConfigId)
      end)
      local descId = paramCfg.advance_reward_desc_1[index] or 0
      if 0 < descId then
        UIHelper.SetLocText(subpart.textItemDesc, descId)
      else
        UIHelper.SetText(subpart.textItemDesc, "")
      end
    end)
  else
    partC.objRewardShow:SetActive(false)
  end
end

function AdvanceBattlePassPage:ShowPartSecretOrder()
  local paramCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
  local priceId = paramCfg.advance_price_2[1]
  local needNum = paramCfg.advance_price_2[2]
  local partS = self.tab_Widgets.partSecretOrder:GetLuaTableParts()
  UGUIEventListener.AddButtonOnClick(partS.btnBuy, function()
    local haveNum = Data.userData:GetCurrency(priceId)
    if haveNum < needNum then
      globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, priceId)
      return
    end
    local content = UIHelper.GetLocString(3310007, needNum)
    local callback = function()
      Service.battlepassService:SendBuyPassType({
        BuyType = BATTLEPASS_BUYTYPE.Advance2
      })
    end
    UIHelper.OpenPage("BattlePassNotice", {Content = content, Callback = callback})
  end)
  local display = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, paramCfg.advance_price_2[1])
  UIHelper.SetImage(partS.imgCurrency, display.icon_small)
  UIHelper.SetText(partS.textPrice, paramCfg.advance_price_2[2])
  if paramCfg.advance_reward_2 > 0 then
    partS.objRewardShow:SetActive(true)
    local rewards = Logic.rewardLogic:FormatRewardById(paramCfg.advance_reward_2)
    UIHelper.CreateSubPart(partS.objItem, partS.rectContent, #rewards, function(index, subpart)
      local res = rewards[index]
      local display = ItemInfoPage.GenDisplayData(res.Type, res.ConfigId)
      UIHelper.SetImage(subpart.imgIcon, display.icon)
      UIHelper.SetImage(subpart.imgQuality, QualityIcon[display.quality])
      UIHelper.SetLocText(subpart.textNum, 710082, res.Num)
      UGUIEventListener.AddButtonOnClick(subpart.btnIcon, function()
        Logic.itemLogic:ShowItemInfo(res.Type, res.ConfigId)
      end)
      local descId = paramCfg.advance_reward_desc_2[index] or 0
      if 0 < descId then
        UIHelper.SetLocText(subpart.textItemDesc, descId)
      else
        UIHelper.SetText(subpart.textItemDesc, "")
      end
    end)
  else
    partS.objRewardShow:SetActive(false)
  end
end

return AdvanceBattlePassPage
