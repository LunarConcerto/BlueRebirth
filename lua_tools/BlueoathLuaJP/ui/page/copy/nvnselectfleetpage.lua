local NvNSelectFleetPage = class("UI.Activity.NvNSelectFleetPage", LuaUIPage)

function NvNSelectFleetPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.params = {}
  self.select = 1
  self.sortfleets = {}
  self.fleetType = FleetType.Normal
  self.enemyId = 0
end

function NvNSelectFleetPage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.params = self:GetParam()
  if self.params.EnemyInfo.FleetDictId == Logic.fleetLogic:GetNvNCurEnemyFleetId() then
    self.tab_Widgets.obj_fail:SetActive(true)
  end
  self.copyDisplayId = Mathf.ToInt(self.params.CopyDisplayId)
  self:InitToggle()
  self.tab_Widgets.toggroup_myfleet:SetActiveToggleIndex(self.select - 1)
  self:_ShowRight()
end

function NvNSelectFleetPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self.__ClickBattle, self)
end

function NvNSelectFleetPage:InitToggle()
  local widgets = self.tab_Widgets
  self.sortfleets = self:__GetSortFleet()
  local exp_up = Logic.fleetOrderLogic:GetExpUpMap(self.copyDisplayId)
  UIHelper.CreateSubPart(widgets.tog_myfleet, widgets.content_myfleet, #self.sortfleets, function(index, tabPart)
    local fleet_info = self.sortfleets[index]
    local colour = fleet_info.CanSelect and 222222 or 777777
    local fleetName = "<color=#" .. colour .. ">" .. self:__GetFleetName(fleet_info.FleetUid) .. "</color>"
    UIHelper.SetText(tabPart.tx_name, fleetName)
    tabPart.im_yichuzhan:SetActive(not fleet_info.CanSelect)
    widgets.toggroup_myfleet:RegisterToggle(tabPart.tog_myfleet)
    if self.sortfleets[index].CanSelect then
      widgets.toggroup_myfleet:RemoveToggleUnActive(index - 1, self._stopToggle)
    else
      widgets.toggroup_myfleet:ResigterToggleUnActive(index - 1, self._stopToggle)
    end
    local totalAttack = 0
    local heroList = fleet_info.HeroInfo
    UIHelper.CreateSubPart(tabPart.obj_myship, tabPart.rect_myship, #heroList, function(nIndex, luaPart)
      local hero = heroList[nIndex]
      local heroId = hero.HeroId
      local heroData = Data.heroData:GetHeroById(heroId)
      local hpStatus = Logic.shipLogic:GetHeroHpStatus(hero.Hp, 1)
      if heroId ~= nil then
        if npcAssistFleetMgr:IsNpcHeroId(heroId) then
          totalAttack = totalAttack + heroData.BattlePower
        else
          local heroAttr = Logic.attrLogic:GetBattlePower(heroId, self.fleetType, self.copyDisplayId)
          totalAttack = totalAttack + heroAttr
        end
      end
      UIHelper.SetImage(luaPart.imgHp, NewHpStatusImg[hpStatus + 1])
      UIHelper.SetStar(luaPart.obj_star, luaPart.trans_star, heroData.Advance)
      luaPart.exp_up.gameObject:SetActive(exp_up[heroId] == true)
      luaPart.slider.value = hero.Hp / 1
      luaPart.textLv.text = Mathf.ToInt(hero.Level)
      ShipCardItem:LoadVerticalCard(heroId, luaPart.childpart, VerCardType.Icon5, nil, self.fleetType)
    end)
    UIHelper.SetText(tabPart.tx_effectiveness, totalAttack)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.toggroup_myfleet, self, nil, function(go, index)
    self.select = index + 1
  end)
end

function NvNSelectFleetPage._stopToggle(param)
end

function NvNSelectFleetPage:_ShowRight()
  local widgets = self.tab_Widgets
  local EnemyInfo = self.params.EnemyInfo
  local fleetId = EnemyInfo.FleetDictId
  self.enemyId = fleetId
  local fleet_info = configManager.GetDataById("config_fleet", fleetId)
  local copy_enemys = EnemyInfo.HeroInfo
  local buffList = fleet_info.random_factor
  local process = "0/0"
  if EnemyInfo.BeatedCount ~= nil and EnemyInfo.TotalCount ~= nil then
    process = EnemyInfo.BeatedCount + 1 .. "/" .. EnemyInfo.TotalCount
  end
  UIHelper.SetText(widgets.process, process)
  UIHelper.SetText(widgets.effectiveness, fleet_info.recommend_ce)
  UIHelper.CreateSubPart(widgets.obj_enemyfleet, widgets.rect_enemyfleet, #copy_enemys, function(nIndex, luaPart)
    local e_id = copy_enemys[nIndex].HeroId
    local si_config = configManager.GetDataById("config_ship_info", e_id)
    local ss_Config = Logic.shipLogic:GetShipShowByInfoId(e_id)
    UIHelper.SetImage(luaPart.im_icon, ss_Config.ship_icon5)
    UIHelper.SetImage(luaPart.img_type, NewCardShipTypeImg[si_config.ship_type])
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(copy_enemys[nIndex].Hp, 1)
    UIHelper.SetImage(luaPart.imgHp, NewHpStatusImg[hpStatus + 1])
    luaPart.slider.value = copy_enemys[nIndex].Hp / 1
  end)
  UIHelper.CreateSubPart(widgets.obj_treaty_buff, widgets.rect_treaty_buff, #buffList, function(nIndex, luaPart)
    local b_id = buffList[nIndex]
    local setRec = configManager.GetDataById("config_random_factor_set", b_id)
    UIHelper.SetImage(luaPart.img_buff, setRec.set_icon)
    UIHelper.SetText(luaPart.tx_name, setRec.set_name)
    local desc = ""
    for _, fid in ipairs({b_id}) do
      local factorRec = configManager.GetDataById("config_random_factor", fid)
      desc = desc .. factorRec.factor_description
    end
    UIHelper.SetText(luaPart.tx_des, desc)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_buff, function()
      local buffShow, b_idx = Logic.copyLogic:GetNvNRandFactors(buffList, b_id)
      UIHelper.OpenPage("RanFactorDetailsPage", {
        copyDisplayId = self.copyDisplayId,
        Factors = buffShow,
        Idx = nIndex
      })
    end)
  end)
end

function NvNSelectFleetPage:__GetSortFleet()
  local tmp = {}
  local tmp1 = {}
  for _, Fleet in pairs(self.params.FleetInfo) do
    if Fleet.CanSelect == true then
      table.insert(tmp, Fleet)
    else
      table.insert(tmp1, Fleet)
    end
  end
  for _, v in pairs(tmp1) do
    table.insert(tmp, v)
  end
  if #tmp == #self.params.FleetInfo then
    return tmp
  else
    return {}
  end
end

function NvNSelectFleetPage:__GetFleetName(FleetUid)
  local fleetListOri = Data.fleetData:GetFleetData(FleetType.Normal)
  for _, v in pairs(fleetListOri) do
    if v.modeId == FleetUid then
      return v.tacticName
    end
  end
  return ""
end

function NvNSelectFleetPage:__ClickBattle()
  local fleetUid = self.sortfleets[self.select].FleetUid
  Logic.fleetLogic:SetBattleFleetId(fleetUid, 1)
  Logic.fleetLogic:SetNvNCurEnemyFleetId(self.enemyId)
  eventManager:FireEventToCSharp(LuaCSharpEvent.NvNFleetSelected, fleetUid)
  UIHelper.ClosePage(self:GetName())
end

function NvNSelectFleetPage:DoOnClose()
end

return NvNSelectFleetPage
