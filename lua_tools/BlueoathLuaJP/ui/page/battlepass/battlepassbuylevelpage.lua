local BattlePassBuyLevelPage = class("UI.BattlePass.BattlePassBuyLevelPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function BattlePassBuyLevelPage:DoInit()
  self.mBuyNum = 1
end

function BattlePassBuyLevelPage:DoOnOpen()
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local max = Logic.battlepassLogic:GetBattlePassMaxLevel()
  if curPassLevel >= max then
    noticeManager:ShowTipById(3310006)
    UIHelper.ClosePage(self:GetName())
    return
  end
  local targetRewardLevelCfg = Logic.battlepassLogic:GetTargetRewardLevelCfg()
  if targetRewardLevelCfg ~= nil then
    local curPassLevel = Data.battlepassData:GetPassLevel()
    local buyNum = targetRewardLevelCfg.level - curPassLevel
    if buyNum > self.mBuyNum then
      self.mBuyNum = buyNum
    end
  end
  self:ShowPage()
end

function BattlePassBuyLevelPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSub, function()
    self:SetBuyNum(self.mBuyNum - 1)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAdd, function()
    self:SetBuyNum(self.mBuyNum + 1)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSubTen, function()
    self:SetBuyNum(self.mBuyNum - 10)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAddTen, function()
    self:SetBuyNum(self.mBuyNum + 10)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBuy, function()
    self:Calculate()
    local needNum = self.mBuyLevelCost
    local haveNum = Data.userData:GetCurrency(self.mBuyLevelPrice[1])
    if needNum > haveNum then
      globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, self.mBuyLevelPrice[1])
      return
    end
    Service.battlepassService:SendBuyPassLevel({
      BuyLevel = self.mBuyNum
    })
  end)
  self:RegisterEvent(LuaEvent.BattlePass_Update, function()
    UIHelper.ClosePage(self:GetName())
  end)
end

function BattlePassBuyLevelPage:DoOnHide()
end

function BattlePassBuyLevelPage:DoOnClose()
end

function BattlePassBuyLevelPage:SetBuyNum(num)
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local max = Logic.battlepassLogic:GetBattlePassMaxLevel()
  local maxnum = max - curPassLevel
  local prenum = self.mBuyNum
  if num < 1 then
    num = 1
    if prenum == num then
      noticeManager:ShowTipById(3300050)
    end
  end
  if maxnum < num then
    num = maxnum
    if prenum == num then
      noticeManager:ShowTipById(3300051)
    end
  end
  self.mBuyNum = num
end

function BattlePassBuyLevelPage:Calculate()
  local curPassType = Data.battlepassData:GetPassType()
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local buyToLevel = curPassLevel + self.mBuyNum
  local buylevelcost = 0
  local bpparamCfg = Logic.battlepassLogic:GetDefaultBattlePassParamConfig()
  local buylevelprice = bpparamCfg.buy_level_price
  local rewardids = {}
  for lvl = curPassLevel + 1, buyToLevel do
    local cfg = configManager.GetDataById("config_battlepass_level", lvl)
    if curPassType == BATTLEPASS_TYPE.ADVANCED and 0 < cfg.pay_level_reward then
      table.insert(rewardids, cfg.pay_level_reward)
    end
    if 0 < cfg.free_level_reward then
      table.insert(rewardids, cfg.free_level_reward)
    end
    buylevelcost = buylevelcost + buylevelprice[2]
  end
  self.mBuyToLevel = buyToLevel
  self.mBuyLevelCost = buylevelcost
  self.mRewardIds = rewardids
  self.mBuyLevelPrice = buylevelprice
end

function BattlePassBuyLevelPage:ShowPage()
  self:Calculate()
  UIHelper.SetText(self.tab_Widgets.textNum, self.mBuyNum)
  self.mBuyRewards = Logic.rewardLogic:FormatRewards(self.mRewardIds)
  self.tab_Widgets.itemReward:SetActive(false)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentReward, self.tab_Widgets.itemReward, #self.mBuyRewards, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateBuyRewardPart(index, part)
    end
  end)
  UIHelper.SetLocText(self.tab_Widgets.textRewardTips, 3310009, self.mBuyToLevel, #self.mBuyRewards)
  UIHelper.SetLocText(self.tab_Widgets.textLevelTips, 3310010, self.mBuyNum, self.mBuyToLevel)
  local display = ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, self.mBuyLevelPrice[1])
  UIHelper.SetImage(self.tab_Widgets.imgPriceCurrency, display.icon_small)
  UIHelper.SetText(self.tab_Widgets.textPriceNum, self.mBuyLevelCost)
end

function BattlePassBuyLevelPage:updateBuyRewardPart(index, part)
  local rewarditem = self.mBuyRewards[index]
  local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
  UIHelper.SetLocText(part.tx_num, 710082, rewarditem.Num)
  UIHelper.SetImage(part.img_icon, display.icon)
  UIHelper.SetImage(part.img_quality, QualityIcon[display.quality])
  UGUIEventListener.AddButtonOnClick(part.btn_reward, function()
    UIHelper.OpenPage("ItemInfoPage", display)
  end)
end

return BattlePassBuyLevelPage
