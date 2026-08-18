local AssistFleetbattlePage = class("UI.BattlePage.AssistFleetbattlePage", LuaUIPage)

function AssistFleetbattlePage:DoInit()
  self.copyId = -1
  self.support_count = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function AssistFleetbattlePage:DoOnOpen()
  self:RegisterBtnEvent()
  local widgets = self:GetWidgets()
  widgets.ship_item:SetActive(false)
  self.copyId = self.cs_page.param:GetInt("copyId", -1)
  self.support_count = self.cs_page.param:GetInt("support_count", -1)
  local copyModelData = configManager.GetDataById("config_copy", self.copyId)
  local copyDisplayModelData = configManager.GetDataById("config_copy_display", copyModelData.copy_id)
  local support_fleet_item_data = self:GetSupportFleetItemData()
  self:FreshSupportFleetItem(support_fleet_item_data.SupportId)
  self:FreshSupportFleetShipItems(support_fleet_item_data.HeroList)
  self:FreshSupportFleetBattleRadio(copyDisplayModelData)
  self:FreshSupportFleetBattleCount(copyDisplayModelData, support_fleet_item_data.SupportId)
end

function AssistFleetbattlePage:DoOnClose()
  self:UnRegisterBtnEvent()
end

function AssistFleetbattlePage:FreshSupportFleetItem(support_fleet_item_id)
  local support_fleet_item_model_data = configManager.GetDataById("config_support_fleet_item", support_fleet_item_id)
  local widgets = self:GetWidgets()
  local support_fleet_item_luaPart = widgets.support_fleet_item:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
  UIHelper.SetText(support_fleet_item_luaPart.tx_num, support_fleet_item_model_data.name)
  UIHelper.SetImage(support_fleet_item_luaPart.im_fg, support_fleet_item_model_data.icon)
  UIHelper.SetImage(support_fleet_item_luaPart.im_bg, QualityIcon[support_fleet_item_model_data.quality])
end

function AssistFleetbattlePage:FreshSupportFleetShipItems(hero_list)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.ship_item, widgets.ship_item_parent, #hero_list, function(index, luapart)
    local ship_show = Logic.shipLogic:GetShipShowByHeroId(hero_list[index])
    local heroInfo = Logic.shipLogic:GetShipInfoByHeroId(hero)
    UIHelper.SetImage(luapart.im_icon, ship_show.ship_icon5)
    UIHelper.SetImage(luapart.im_kuang, QualityIcon[heroInfo.quality])
  end)
end

function AssistFleetbattlePage:FreshSupportFleetBattleRadio(copyDisplayModelData)
  local widgets = self:GetWidgets()
  local success_radio = copyDisplayModelData.support_fleet_battle_ratio * 0.01
  success_radio = math.floor(success_radio)
  local language_id = -1
  if success_radio == 0 or 80 <= success_radio then
    language_id = 971019
  elseif 60 <= success_radio or success_radio < 80 then
    language_id = 971018
  elseif 40 <= success_radio or success_radio < 60 then
    language_id = 971017
  elseif 20 <= success_radio or success_radio < 40 then
    language_id = 971016
  elseif 0 < success_radio or success_radio < 20 then
    language_id = 971015
  else
    language_id = 971019
  end
  UIHelper.SetText(widgets.support_success_radio, UIHelper.GetString(language_id))
end

function AssistFleetbattlePage:FreshSupportFleetBattleCount(copyDisplayModelData, support_fleet_item_id)
  local support_fleet_item_model_data = configManager.GetDataById("config_support_fleet_item", support_fleet_item_id)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.battle_count, self.support_count .. "/" .. support_fleet_item_model_data.use_count)
end

function AssistFleetbattlePage:RegisterBtnEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok.gameObject, self._OnClickOK, self, {})
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancle.gameObject, self._OnClickCancle, self, {})
  UGUIEventListener.AddButtonOnClick(widgets.btn_close.gameObject, self._OnClickClose, self, {})
end

function AssistFleetbattlePage:_OnClickOK()
  local fun = self.cs_page.param:GetObject("SupportResultCallBack", nil)
  UIHelper.ClosePage("AssistFleetbattlePage")
  fun(true)
end

function AssistFleetbattlePage:_OnClickCancle()
  logError("_OnClickCancle")
  local fun = self.cs_page.param:GetObject("SupportResultCallBack", nil)
  UIHelper.ClosePage("AssistFleetbattlePage")
  fun(false)
end

function AssistFleetbattlePage:_OnClickClose()
  logError("_OnClickClose")
  local fun = self.cs_page.param:GetObject("SupportResultCallBack", nil)
  UIHelper.ClosePage("AssistFleetbattlePage")
  fun(false)
end

function AssistFleetbattlePage:UnRegisterBtnEvent()
end

function AssistFleetbattlePage:GetSupportFleetItemData()
  local copyModelData = configManager.GetDataById("config_copy", self.copyId)
  local support_fleet_item_data = Data.assistFleetData:GetAssistInfoByCopy(copyModelData.copy_id)
  if support_fleet_item_data == nil then
    support_fleet_item_data = {}
    support_fleet_item_data.SupportId = 100001
    support_fleet_item_data.HeroList = {}
    local shipIds = Data.fleetData:GetShipByFleet(1)
    for i, shipId in ipairs(shipIds) do
      local heroData = Data.heroData:GetHeroById(shipId)
      table.insert(support_fleet_item_data.HeroList, heroData.HeroId)
    end
  end
  return support_fleet_item_data
end

return AssistFleetbattlePage
