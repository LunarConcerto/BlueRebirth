local TeachLevelDetailPage = class("UI.Copy.TeachLevelDetailPage", LuaUIPage)
local MIN_TICKET_NUM = 0
local MAX_TICKET_NUM = 1

function TeachLevelDetailPage:DoInit()
  self.m_dataConfInfo = nil
  self.m_desConfInfo = nil
  self.m_tabFleetData = nil
  self.nBossId = 0
  self.nBossHp = 0
  self.bIsRunning = false
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function TeachLevelDetailPage:DoOnOpen()
  self:OpenTopPage("LevelDetailsPage", 1, "\229\133\179\229\141\161\232\175\166\230\131\133", self, true)
  local tabParam = self.param
  self.bIsRunning = false
  self.nBossId = tabParam.BossId
  self.nBossHp = tabParam.bossHp
  self.nBaseId = tabParam.BaseId
  self.m_dataConfInfo = Logic.copyLogic:GetCopyDataConfig(tabParam.BaseId)
  self.m_desConfInfo = Logic.copyLogic:GetCopyDesConfig(self.m_dataConfInfo.copy_id)
  self:_ShowAreaInfo()
  self:_CreateFleetInfo()
  self:_ShowStarRequire(7)
  self.m_tabWidgets.tog_repaire.isOn = Logic.copyLogic:GetAutoRepaireInfo()
end

function TeachLevelDetailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_battle, function()
    self:_ClickBattle()
  end)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_repaire, self._ClickTogRepaire, self)
end

function TeachLevelDetailPage:_UpdateInfo()
  self.m_tabWidgets.im_fightPlanMask.gameObject:SetActive(self.bIsRunning)
  self.m_tabWidgets.obj_chase:SetActive(self.bIsRunning)
end

function TeachLevelDetailPage:_ShowStarRequire(param)
  local tabStarRequire = self.m_desConfInfo.star_require
  local tabOne = tabStarRequire[1]
  local tabTwo = tabStarRequire[2]
  local tabThree = tabStarRequire[3]
  self.m_tabWidgets.txt_starOne.text = configManager.GetDataById("config_evaluate", tabOne).description
  self.m_tabWidgets.txt_starTwo.text = configManager.GetDataById("config_evaluate", tabTwo).description
  self.m_tabWidgets.txt_starThree.text = configManager.GetDataById("config_evaluate", tabThree).description
  self.m_tabWidgets.obj_starOneSelect:SetActive(param & 1 == 1)
  self.m_tabWidgets.obj_starTwoSelcet:SetActive(param & 2 == 2)
  self.m_tabWidgets.obj_starThreeSelcet:SetActive(param & 4 == 4)
end

function TeachLevelDetailPage:_CreateOutItem()
  local tabDropInfo = Logic.copyLogic:GetDropInfo()
  local tabDropInfoId = self.m_desConfInfo.drop_info_id
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_outItem, self.m_tabWidgets.trans_outItem, #tabDropInfoId, function(nIndex, tabPart)
    local itemInfo = tabDropInfo[tabDropInfoId[nIndex]]
    if itemInfo ~= nil then
      UIHelper.SetImage(tabPart.im_outItem, itemInfo.icon)
      tabPart.im_outItem:SetNativeSize()
      UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
        Logic.rewardLogic:OnClickDropItem(itemInfo, self.m_desConfInfo.drop_info_id)
      end)
    end
  end)
end

function TeachLevelDetailPage:_ShowAreaInfo()
  self.m_tabWidgets.txt_areaDescription.text = self.m_desConfInfo.description
  self.m_tabWidgets.txt_areaName.text = self.m_desConfInfo.name
  self.m_tabWidgets.txt_fightTime.text = self.m_dataConfInfo.battle_time
  self.m_tabWidgets.txt_fightTime.text = Logic.copyLogic:OnNumberInvert(tonumber(self.m_tabWidgets.txt_fightTime.text))
end

function TeachLevelDetailPage:_CreateFleetInfo()
  self.m_tabWidgets.txt_repaireNum.text = 0
  self.m_tabWidgets.txt_supply.text = 0
  local shipsInfo = Logic.teachCopyLogic:GetFleetInfo(self.nBaseId)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cardFleet, self.m_tabWidgets.trans_cardBg, #shipsInfo, function(nIndex, tabPart)
    local shipInfo = shipsInfo[nIndex]
    tabPart.obj_fleetInfo.gameObject:SetActive(true)
    tabPart.sliderHP.value = 1
    local shipMainInfo = Logic.teachCopyLogic:GetShipMainInfo(shipInfo.si_id)
    local shipShow = Logic.shipLogic:GetShipShowByInfoId(shipInfo.si_id)
    tabPart.txt_Hp.text = shipMainInfo.hp .. "/" .. shipMainInfo.hp
    tabPart.im_state.gameObject:SetActive(false)
    tabPart.txt_pos01.text = nIndex
    tabPart.txt_pos02.text = nIndex
    tabPart.obj_iconBg01:SetActive(nIndex == 1)
    tabPart.obj_iconBg02:SetActive(nIndex ~= 1)
    UIHelper.CreateSubPart(tabPart.obj_star, tabPart.trans_star, 6, function(index, part)
      part.obj_gray:SetActive(true)
      part.obj_star:SetActive(false)
      for i = 1, 1 do
        if index == i then
          part.obj_star:SetActive(true)
        end
      end
    end)
    UIHelper.SetImage(tabPart.im_hp, "uipic_ui_card_im_xuetiao_lv")
    UIHelper.SetImage(tabPart.im_girl, tostring(shipShow.ship_icon1), true)
    UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipShow.ship_type])
  end)
end

function TeachLevelDetailPage:_ClickBattle()
  stageMgr:Goto(EStageType.eStageSimpleBattle, tostring(self.nBaseId))
end

return TeachLevelDetailPage
