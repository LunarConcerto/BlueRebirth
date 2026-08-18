local ShipCombinationStatusPage = class("ui.page.GirlInfo.ShipCombinationStatusPage", LuaUIPage)
local MaxCombineLv = 100

function ShipCombinationStatusPage:DoInit()
  self.heroId = nil
  self.heroInfo = nil
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.parentPage = nil
end

function ShipCombinationStatusPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween, self)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.UpdateShipCombinaRelation, self._OnUpdateHero, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_selectBtn1, self._SelectCombineHero, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_selectBtn2, self._SelectCombineHero, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_levelup, self._JumpCombineLv, self)
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateView, self)
end

function ShipCombinationStatusPage:DoOnOpen()
  local param = self:GetParam()
  self.heroId = param.heroId
  self.parentPage = param.parent
  self:_UpdateView()
end

function ShipCombinationStatusPage:DoOnHide()
end

function ShipCombinationStatusPage:DoOnClose()
end

function ShipCombinationStatusPage:_UpdateView()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local combInfo = heroInfo.CombinationInfo
  local combineHeroId = combInfo.Combine
  
  local function SetHeroShow(heroId, luaPart)
    local heroInfo = Data.heroData:GetHeroById(heroId)
    local sid = heroInfo.fleetId
    local HeroIcon = Logic.shipLogic:GetHeroCardIcon(sid, false)
    local Quality = heroInfo.quality
    local Name = Logic.shipLogic:GetName(sid)
    local Lv = heroInfo.Lvl
    local ShipType = heroInfo.type
    local uiTab = luaPart:GetLuaTableParts()
    UIHelper.SetImage(uiTab.im_icon, HeroIcon)
    UIHelper.SetImage(uiTab.im_quality, VerCardQualityImg[Quality])
    UIHelper.SetText(uiTab.tx_name, Name)
    UIHelper.SetText(uiTab.tx_lv, Lv)
    UIHelper.SetImage(uiTab.im_type, CardShipTypeImgMin[ShipType])
    UIHelper.SetStar(uiTab.obj_star, uiTab.trans_star, heroInfo.Advance)
  end
  
  SetHeroShow(self.heroId, self.m_tabWidgets.lp_ship1)
  local haveCombineHero = 0 < combineHeroId and Logic.shipLogic:IsHasHero(combineHeroId)
  self.m_tabWidgets.obj_ship2:SetActive(haveCombineHero)
  self.m_tabWidgets.obj_combEffect:SetActive(haveCombineHero)
  self.m_tabWidgets.obj_noeffect:SetActive(not haveCombineHero)
  self.m_tabWidgets.obj_levelup:SetActive(haveCombineHero)
  if haveCombineHero then
    SetHeroShow(combineHeroId, self.m_tabWidgets.lp_ship2)
    local combineHeroData = Logic.shipCombinationLogic:GetCombineData(combineHeroId)
    local combineLv = combineHeroData.ComLv
    local combineAttr, combineAttrPercent = Logic.shipCombinationLogic:GetCombAttrTab(combineHeroId, combineLv)
    local attrTab = table.append(combineAttr, combineAttrPercent)
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_prop, self.m_tabWidgets.trans_prop, #attrTab, function(index, uiPart)
      local attrInfo = attrTab[index]
      local valueEffectConf = configManager.GetDataById("config_value_effect", attrInfo[1])
      local strValues = valueEffectConf.values
      local strTab = string.split(strValues, ",")
      local attrConf = configManager.GetDataById("config_attribute", tonumber(strTab[1]))
      local propName = attrConf.attr_name
      local propIcon = attrConf.attr_icon
      UIHelper.SetImage(uiPart.im_icon, propIcon)
      UIHelper.SetText(uiPart.tx_name, propName)
      if index <= #combineAttr then
        UIHelper.SetText(uiPart.tx_num, "+" .. attrInfo[2])
      else
        local value = 0
        local attrTab = {}
        local percentPropTab = {
          {
            power = attrInfo[2],
            values = valueEffectConf.values
          }
        }
        attrTab = Logic.attrLogic:DisposeAttrBuff(attrTab, percentPropTab)
        if attrConf and attrConf.attr_display ~= "" then
          local params = clone(attrConf.params)
          value = ScriptManager:RunCmd(attrConf.attr_display, params, attrTab)
        end
        UIHelper.SetText(uiPart.tx_num, "+" .. value .. "%")
      end
    end)
    local combConf, nextCombConf = Logic.shipCombinationLogic:GetCombineConf(combineHeroId, combineLv)
    local lvRang = combConf.level
    local pSkillId = 0
    local pSkillLv = 0
    local hasBreak = Logic.shipCombinationLogic:IfBreakUp(combineHeroId, combineLv)
    if combineLv == lvRang[2] and hasBreak and nextCombConf then
      pSkillId = nextCombConf.skill_id[1]
      pSkillLv = nextCombConf.skill_id[2]
    else
      pSkillId = combConf.skill_id[1]
      pSkillLv = combConf.skill_id[2]
    end
    local name = Logic.shipLogic:GetPSkillName(pSkillId)
    local desc = Logic.shipLogic:GetPSkillDesc(pSkillId, pSkillLv, false)
    local type = Logic.shipLogic:GetPSkillType(pSkillId)
    local icon = Logic.shipLogic:GetPSkillIcon(pSkillId)
    local color = TalentColor[type]
    UIHelper.SetTextColor(self.m_tabWidgets.tx_skill, name, color)
    UIHelper.SetImage(self.m_tabWidgets.im_skillicon, icon)
    UIHelper.SetText(self.m_tabWidgets.tx_skilldesc, desc)
    self.m_tabWidgets.btn_levelup.gameObject:SetActive(combineLv < MaxCombineLv)
  end
end

function ShipCombinationStatusPage:UpdateGirlTog(heroId)
  self.heroId = heroId
  self:_UpdateView()
end

function ShipCombinationStatusPage:_OnUpdateHero()
  self:_UpdateView()
  local combData = Logic.shipCombinationLogic:GetCombineData(self.heroId)
  if combData.Combine > 0 then
    noticeManager:ShowTip(UIHelper.GetString(4900027))
  else
    noticeManager:ShowTip(UIHelper.GetString(4900028))
  end
end

function ShipCombinationStatusPage:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function ShipCombinationStatusPage:_GirlInfoTween(delta)
  local widgets = self:GetWidgets()
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    widgets.tween_dongHua.gameObject.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    widgets.tween_dongHua.from = widgets.tween_dongHua.gameObject.transform.anchoredPosition3D
    widgets.tween_dongHua:ResetToBeginning()
    widgets.tween_dongHua:Play(true)
  end
end

function ShipCombinationStatusPage:_SelectCombineHero()
  local allCombineHeroData = Data.heroData:GetAllCombinationHero()
  if table.nums(allCombineHeroData) > 0 then
    local selectedIdList
    local combineHeroData = Logic.shipCombinationLogic:GetCombineData(self.heroId)
    if combineHeroData.Combine and 0 < combineHeroData.Combine then
      selectedIdList = {
        combineHeroData.Combine
      }
    end
    UIHelper.OpenPage("CommonSelectPage", {
      CommonHeroItem.Combination,
      allCombineHeroData,
      {
        m_selectMax = 1,
        MainHeroId = self.heroId,
        m_selectedIdList = selectedIdList
      }
    })
  else
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("PicturePage")
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(4900021), tabParams)
  end
end

function ShipCombinationStatusPage:_JumpCombineLv()
  if self.parentPage then
    local heroInfo = Data.heroData:GetHeroById(self.heroId)
    local combInfo = heroInfo.CombinationInfo
    local combineHeroId = combInfo.Combine
    self.parentPage:JumpToHeroCombineLv(combineHeroId)
  end
end

return ShipCombinationStatusPage
