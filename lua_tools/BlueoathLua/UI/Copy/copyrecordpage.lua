local CopyRecordPage = class("UI.Copy.CopyRecordPage", LuaUIPage)

function CopyRecordPage:DoInit()
  self.m_tabWidgets = nil
  self.mType = 0
  self.mRecord = {}
  self.mFleetInfo = {}
  self.mSelectPart = nil
end

function CopyRecordPage:DoOnOpen()
  local param = self:GetParam()
  self.mType = param.type
  self.mRecord = param.info
  self.fleetType = param.fleetType or FleetType.Normal
  self.tab_Widgets.obj_base:SetActive(self.mRecord.Uid)
  self.tab_Widgets.txt_name.text = self.mRecord.Uname == "" and math.tointeger(self.mRecord.Uid) or self.mRecord.Uname
  self.tab_Widgets.txt_lv.text = self.mRecord.Level and math.tointeger(self.mRecord.Level) or 0
  local mTime = self.mRecord.PassTime and time.getTimeStringFontMinute(self.mRecord.PassTime) or 0
  self.tab_Widgets.txt_time.text = mTime
  self.tab_Widgets.txt_strategy.text = self.mRecord.StrategyId ~= 0 and Logic.strategyLogic:GetNameById(self.mRecord.StrategyId) or UIHelper.GetString(980007)
  local isTower = Logic.towerLogic:IsTowerType(self.fleetType)
  if isTower then
    self.tab_Widgets.tx_record.text = time.formatTimeToYMD(self.mRecord.RecTime)
  end
  self.tab_Widgets.txt_day:SetActive(isTower)
  self.mFleetInfo = self.mRecord.Tactic
  self:_LoadFleet()
end

function CopyRecordPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CliskClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_bg, self._CliskClose, self)
end

function CopyRecordPage:_LoadFleet()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_fleetItem, self.tab_Widgets.trans_fleet, 6, function(index, tabParts)
    tabParts.obj_null:SetActive(index > #self.mFleetInfo)
    tabParts.obj_hero:SetActive(index <= #self.mFleetInfo)
    if index > #self.mFleetInfo then
      return
    end
    local heroInfo = self.mFleetInfo[index]
    local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.Tid)
    local showInfo = Logic.shipLogic:GetShipShowById(heroInfo.Tid)
    UIHelper.SetText(tabParts.txt_lv, Mathf.ToInt(heroInfo.Level))
    UIHelper.SetImage(tabParts.img_quality, HorizontalCardQulity[shipInfo.quality])
    tabParts.txt_name.text = shipInfo.ship_name
    if index == 1 then
      UIHelper.SetImage(tabParts.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
    end
    UIHelper.SetImage(tabParts.img_type, NewCardShipTypeImg[shipInfo.ship_type])
    UIHelper.SetStar(tabParts.obj_star, tabParts.trans_star, heroInfo.AdvLevel)
    tabParts.slider.value = 1 - heroInfo.CurHp / 100
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(1 - heroInfo.CurHp / 100, 1)
    UIHelper.SetImage(tabParts.imgHp, NewHpStatusImg[hpStatus + 1])
    if hpStatus >= DamageLevel.SmallDamage then
      UIHelper.SetImage(tabParts.img_icon, tostring(showInfo.ship_icon2_po))
    else
      UIHelper.SetImage(tabParts.img_icon, tostring(showInfo.ship_icon2))
    end
    UGUIEventListener.AddButtonOnClick(tabParts.btn_detail, function()
      self:_OnClickHero(heroInfo, shipInfo, showInfo, index, tabParts)
    end)
    if index == 1 then
      self:_OnClickHero(heroInfo, shipInfo, showInfo, index, tabParts)
    end
    tabParts.towertimes1:SetActive(false)
    tabParts.towertimes2:SetActive(false)
    local fleetType = self.fleetType
    local isTower = Logic.towerLogic:IsTowerType(self.fleetType)
    if isTower then
      local point = Logic.towerLogic:GetShipBattleCount(heroInfo.Tid, fleetType)
      local totalCount = Logic.towerLogic:GetShipBattleTimes(fleetType)
      local num = 0 < totalCount - point and totalCount - point or 0
      local countText = num .. "/" .. totalCount
      UIHelper.SetText(tabParts.tx_times1, countText)
      UIHelper.SetText(tabParts.tx_times2, countText)
      tabParts.towertimes1:SetActive(0 < num)
      tabParts.towertimes2:SetActive(num <= 0)
    end
  end)
end

function CopyRecordPage:_OnClickHero(heroInfo, shipInfo, showInfo, index, tabParts)
  if self.mSelectPart ~= nil then
    self.mSelectPart.obj_select:SetActive(false)
  end
  tabParts.obj_select:SetActive(true)
  self.mSelectPart = tabParts
  UIHelper.SetImage(self.tab_Widgets.img_2dgirl, showInfo.ship_draw)
  UIHelper.SetImage(self.tab_Widgets.img_bgpinzhi, GirlQualityBgTexture[shipInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.im_type, NewCardShipTypeImg[shipInfo.ship_type])
  local shipTypeConfig = configManager.GetDataById("config_ship_type", shipInfo.ship_type)
  UIHelper.SetImage(self.tab_Widgets.im_typeDes, shipTypeConfig.wordsimage)
  UIHelper.SetText(self.tab_Widgets.txt_shipName, shipInfo.ship_name)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_star, self.tab_Widgets.trans_starBase, heroInfo.AdvLevel, function(nIndex, tabPart)
  end)
  local shipCVConfig = Logic.shipLogic:GetShipShowHandBookById(heroInfo.Tid)
  UIHelper.SetText(self.tab_Widgets.txt_CVname, "CV:" .. shipCVConfig.ship_character_voice)
  self:_ShowGirl(showInfo.ss_id)
  local isAEquip, isLLEquip
  local equipTrench = Logic.equipLogic:GetCopyRecordEquip(heroInfo)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_equipItem, self.tab_Widgets.trans_equip, #equipTrench, function(nIndex, tabPart)
    local tabTrenchId = equipTrench[nIndex].equipAttr
    local equipWearType = Logic.equipLogic:GetTrenchEquipType(tabTrenchId)
    tabPart.txt_type.text = equipWearType
    if equipTrench[nIndex].equipInfo.Tid == 0 then
      UIHelper.SetImage(tabPart.img_iconBg, "uipic_ui_common_bg_kongtubiaokuang")
      tabPart.obj_equip:SetActive(false)
    else
      tabPart.obj_equip:SetActive(true)
      local shipEquipInfo = configManager.GetDataById("config_equip", equipTrench[nIndex].equipInfo.Tid)
      local txt_level = "+" .. Mathf.ToInt(equipTrench[nIndex].equipInfo.Level)
      if 0 >= equipTrench[nIndex].equipInfo.Level then
        txt_level = " "
      end
      tabPart.txt_level.text = txt_level
      tabPart.txt_name.text = shipEquipInfo.name
      UIHelper.SetStar(tabPart.obj_star, tabPart.trans_star, equipTrench[nIndex].equipInfo.StarLv)
      tabPart.trans_attr.gameObject:SetActive(true)
      UIHelper.SetImage(tabPart.img_icon, tostring(shipEquipInfo.icon))
      UIHelper.SetImage(tabPart.img_iconBg, QualityIcon[shipEquipInfo.quality])
      isAEquip = Logic.equipLogic:IsAEquip(equipTrench[nIndex].equipInfo.Tid)
      tabPart.obj_activity:SetActive(isAEquip)
      isLLEquip = Logic.equipLogic:IsLLEquip(equipTrench[nIndex].equipInfo.Tid)
      tabPart.obj_limit:SetActive(isLLEquip)
      local attr = Logic.equipLogic:GetCopyRecordEquipAttr(equipTrench[nIndex].equipInfo)
      UIHelper.CreateSubPart(tabPart.obj_attrItem, tabPart.trans_attr, 4, function(mIndex, luaPart)
        local equipInfo = attr[mIndex]
        if equipInfo then
          luaPart.txt_name.text = equipInfo.name
          if type(equipInfo.value) == "number" then
            luaPart.txt_value.text = Mathf.ToInt(equipInfo.value)
          else
            luaPart.txt_value.text = equipInfo.value
          end
          UIHelper.SetImage(luaPart.img_attr, equipInfo.icon)
          luaPart.img_attr.gameObject:SetActive(true)
          luaPart.txt_value.gameObject:SetActive(true)
          luaPart.txt_name.gameObject:SetActive(true)
        else
          luaPart.txt_name.gameObject:SetActive(false)
          luaPart.txt_value.gameObject:SetActive(false)
          luaPart.img_attr.gameObject:SetActive(false)
        end
      end)
    end
  end)
end

function CopyRecordPage:_CliskClose()
  UIHelper.ClosePage("CopyRecordPage")
end

function CopyRecordPage:_ShowGirl(id)
  local shipPosConfig = configManager.GetDataById("config_ship_position", id)
  local position = shipPosConfig.recommend_position
  local scale = shipPosConfig.recommend_scale / 10000
  local mirror = shipPosConfig.recommend_inversion
  local scale3
  if mirror == 0 then
    scale3 = Vector3.New(scale, scale, scale)
  else
    scale3 = Vector3.New(-1 * scale, scale, scale)
  end
  local pos3 = Vector3.New(position[1], position[2], 0)
  self.tab_Widgets.rect_2dgirl.anchoredPosition = pos3
  self.tab_Widgets.img_2dgirl.gameObject.transform.localScale = scale3
end

return CopyRecordPage
