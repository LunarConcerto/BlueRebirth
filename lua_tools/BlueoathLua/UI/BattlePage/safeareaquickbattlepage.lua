local SafeAreaQuickBattlePage = class("UI.BattlePage.SafeAreaQuickBattlePage", LuaUIPage)

function SafeAreaQuickBattlePage:DoInit()
  self.show_duration = configManager.GetDataById("config_parameter", 178).value * 0.001
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SafeAreaQuickBattlePage:DoOnOpen()
  local widgets = self:GetWidgets()
  self.copyId = self.cs_page.param:GetInt("copyId", -1)
  self.safearea_lev = self.cs_page.param:GetInt("safeareaLev", -1)
  self.ship_main_id = self.cs_page.param:GetInt("shipMainId", -1)
  self.cur_num = self.cs_page.param:GetInt("cur_num", -1)
  self.max_num = self.cs_page.param:GetInt("max_num", -1)
  self.selectHeroUid = self.cs_page.param:GetInt("selectHeroUid", -1)
  local config_safearea_model = configManager.GetDataById("config_safearea", self.safearea_lev)
  if config_safearea_model == nil then
    logError("config_safearea not find lev" .. tostring(self.safearea_lev))
  end
  local desc = config_safearea_model.desc
  local str = string.format(UIHelper.GetString(510005), desc)
  UIHelper.SetText(widgets.text_safeareaName_bg, str)
  UIHelper.SetText(widgets.text_safeareaName, str)
  local cur2maxstr = string.format(UIHelper.GetString(100021), tostring(self.cur_num), tostring(self.max_num))
  UIHelper.SetText(widgets.text_limits, cur2maxstr)
  local hero_data
  if self.selectHeroUid == -1 then
    hero_data = Data.heroData:GetHeroById(Data.userData:GetSecretaryId())
  else
    hero_data = Data.heroData:GetHeroById(self.selectHeroUid)
  end
  local ship_info = Logic.shipLogic:GetShipInfoById(hero_data.TemplateId)
  local ship_show = Logic.shipLogic:GetShipShowByHeroId(hero_data.HeroId)
  local shipTypeConfig = configManager.GetDataById("config_ship_type", ship_info.ship_type)
  local random_str = UIHelper.GetString(shipTypeConfig.safearea_quickbattle_languageId)
  UIHelper.SetText(widgets.text_quickbattleName_bg, random_str)
  UIHelper.SetText(widgets.text_quickbattleName, random_str)
  UIHelper.SetImage(widgets.ship_image, ship_show.ship_draw)
  local position = configManager.GetDataById("config_ship_position", ship_show.ss_id).support_fleet_position4
  local scale = configManager.GetDataById("config_ship_position", ship_show.ss_id).support_fleet_scale4 / 10000
  local mirror = configManager.GetDataById("config_ship_position", ship_show.ss_id).support_fleet_inversion4
  local scale3
  if mirror == 0 then
    scale3 = Vector3.New(scale, scale, scale)
  else
    scale3 = Vector3.New(-1 * scale, scale, scale)
  end
  local pos3 = Vector3.New(position[1], position[2], 0)
  widgets.ship_image.transform.localPosition = pos3
  widgets.ship_image.transform.localScale = scale3
  local timer = Timer.New(function()
    self:PreClose()
  end, self.show_duration, 1, false)
  timer:Start()
end

function SafeAreaQuickBattlePage:PreClose()
  local cs_page = self.cs_page
  local cs_name = cs_page.name
  local param = cs_page.param
  local fun = param:GetObject("SafeAreaResultCallBack", nil)
  UIHelper.ClosePage("SafeAreaQuickBattlePage")
  fun()
end

return SafeAreaQuickBattlePage
