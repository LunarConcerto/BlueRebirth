IncreaseInfoPage = class("UI.IncreaseInfoPage", LuaUIPage)

function IncreaseInfoPage:DoInit()
  self.currencyConfig = configManager.GetDataById("config_currency", 5)
  local level = Data.userData:GetUserLevel()
  local lvUpConfig = configManager.GetDataById("config_player_levelup", level)
  local speedConf = {
    lvUpConfig.supply_increase_speed[1],
    lvUpConfig.supply_increase_speed[2]
  }
  self.max = lvUpConfig.supply_max_limit
  self.speed = speedConf[1] / (speedConf[2] / 60)
  if Logic.userLogic:CheckMonthCardPrivilege() then
    local monthSpeed = lvUpConfig.month_supply_speed_add[1] / (lvUpConfig.month_supply_speed_add[2] / 60)
    self.speed = self.speed + monthSpeed
    self.max = self.max + lvUpConfig.month_supply_max_add
  end
  if Logic.userLogic:CheckBigMonthCardPrivilege() then
    local bigmonthAdd = configManager.GetDataById("config_parameter", 256).value
    self.max = self.max + bigmonthAdd
  end
end

function IncreaseInfoPage:DoOnOpen()
  UIHelper.SetImage(self.tab_Widgets.imgCurrency, self.currencyConfig.icon)
  UIHelper.SetImage(self.tab_Widgets.imgQuality, QualityIcon[self.currencyConfig.quality])
  UIHelper.SetText(self.tab_Widgets.txtSpeed, math.floor(self.speed) .. "\231\130\185/\229\136\134\233\146\159")
  UIHelper.SetText(self.tab_Widgets.txtMax, self.max)
  local curr = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  local max = Data.userData:GetCurrencyMax(CurrencyType.SUPPLY)
  self.tab_Widgets.titleMax.gameObject:SetActive(curr >= max)
end

function IncreaseInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBlack, self.OnBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.OnBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnBuy, self.OnBtnBuyClick, self)
end

function IncreaseInfoPage:OnBtnBuyClick()
  UIHelper.ClosePage("IncreaseInfoPage")
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Supply)
end

function IncreaseInfoPage:OnBtnCloseClick()
  UIHelper.ClosePage("IncreaseInfoPage")
end

function IncreaseInfoPage:DoOnHide()
end

function IncreaseInfoPage:DoOnClose()
end

return IncreaseInfoPage
