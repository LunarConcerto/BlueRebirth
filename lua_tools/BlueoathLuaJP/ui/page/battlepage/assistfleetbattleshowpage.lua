local AssistFleetbattleShowPage = class("UI.BattlePage.AssistFleetbattleShowPage", LuaUIPage)

function AssistFleetbattleShowPage:DoInit()
  self.show_duration = configManager.GetDataById("config_parameter", 90).value
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function AssistFleetbattleShowPage:DoOnOpen()
  local widgets = self:GetWidgets()
  self.copyId = self.cs_page.param:GetInt("copyId", -1)
  local support_fleet_item_data = self:GetSupportFleetItemData()
  local random_hero_idnex = math.random(#support_fleet_item_data.HeroList)
  local select_hero = support_fleet_item_data.HeroList[random_hero_idnex]
  local ship_show = Logic.shipLogic:GetShipShowByHeroId(select_hero)
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

function AssistFleetbattleShowPage:PreClose()
  local fun = self.cs_page.param:GetObject("SupportResultCallBack", nil)
  UIHelper.ClosePage("AssistFleetbattleShowPage")
  fun()
end

function AssistFleetbattleShowPage:GetSupportFleetItemData()
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

return AssistFleetbattleShowPage
