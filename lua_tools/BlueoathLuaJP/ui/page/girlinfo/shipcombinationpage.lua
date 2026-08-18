local ShipCombinationPage = class("ui.page.GirlInfo.ShipCombinationPage", LuaUIPage)
local MAXCOMBINELV = 100
local AddNumColor = "006F0F"
local CostNotEnoughColor = "E71B23"
local BreakMeetColor = "00B018"
local BreakNotMeetColor = "EA3940"
local MAXHeroADVANCE = 6
local MAXGRADE = 9
local OpenType = {DOCK = 1, ILLUSTRATE = 2}

function ShipCombinationPage:DoInit()
  self.illustrateId = nil
  self.heroId = nil
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.heroInfo = {}
  self.openType = OpenType.DOCK
  self.showMax = false
end

function ShipCombinationPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween, self)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI, self)
  self:RegisterEvent(LuaEvent.UpdateShipCombinationInfo, self._OnUpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_levelup, self._OnLevelUpBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_levelupfast, self._OnLevelUpFastBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_breakup, self._OnBreakBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_open, self._OnLevelUpBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_showmax, self._OnShowMaxBtnClick, self)
end

function ShipCombinationPage:DoOnOpen()
  local param = self:GetParam()
  self.illustrateId = param.illustrateId
  self.heroId = param.heroId
  self.openType = self.heroId and OpenType.DOCK or OpenType.ILLUSTRATE
  self:_UpdateView()
end

function ShipCombinationPage:DoOnHide()
end

function ShipCombinationPage:DoOnClose()
end

function ShipCombinationPage:UpdateGirlTog(heroId)
  self.heroId = heroId
  self.showMax = false
  self:_UpdateView()
end

function ShipCombinationPage:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function ShipCombinationPage:_GirlInfoTween(delta)
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

function ShipCombinationPage:_UpdateView()
  local combConf, nextStageConf
  local shipCombineLv = 0
  local propBaseTab, propBasePercentTab, nextAddPropTab, nextAddPropPercentTab = {}, {}, {}, {}
  local hasOpenFunc = false
  
  local function showAttrFunc(propBaseTab, propBasePercentTab, nextAddPropTab, nextAddPropPercentTab)
    local propTab = table.append(propBaseTab, propBasePercentTab)
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_propItem, self.m_tabWidgets.trans_propTrans, #propTab, function(index, uiPart)
      local propInfo = propTab[index]
      local value = propInfo[2]
      local valueEffectConf = configManager.GetDataById("config_value_effect", propInfo[1])
      local strValues = valueEffectConf.values
      local strTab = string.split(strValues, ",")
      local attrConf = configManager.GetDataById("config_attribute", tonumber(strTab[1]))
      local propName = attrConf.attr_name
      local attricon = attrConf.attr_icon
      UIHelper.SetText(uiPart.txt_propName, propName)
      UIHelper.SetImage(uiPart.im_icon, attricon)
      if index <= #propBaseTab then
        UIHelper.SetText(uiPart.txt_num, "+" .. value)
      else
        local attrTab = {}
        local percentPropTab = {
          {
            power = value,
            values = valueEffectConf.values
          }
        }
        attrTab = Logic.attrLogic:DisposeAttrBuff(attrTab, percentPropTab)
        if attrConf and attrConf.attr_display ~= "" then
          local params = clone(attrConf.params)
          value = ScriptManager:RunCmd(attrConf.attr_display, params, attrTab)
        end
        UIHelper.SetText(uiPart.txt_num, "+" .. value .. "%")
      end
      if nextAddPropTab and 0 < #nextAddPropTab then
        for _, v in pairs(nextAddPropTab) do
          if v[1] == propInfo[1] then
            local strAddNum = "(+" .. v[2] .. ")"
            uiPart.txt_addNum.gameObject:SetActive(true)
            UIHelper.SetTextColor(uiPart.txt_addNum, strAddNum, AddNumColor)
          end
        end
      else
        uiPart.txt_addNum.gameObject:SetActive(false)
      end
      if nextAddPropPercentTab and 0 < table.nums(nextAddPropPercentTab) then
        for _, v in pairs(nextAddPropPercentTab) do
          if v[1] == propInfo[1] then
            local valueEffectConf = configManager.GetDataById("config_value_effect", v[1])
            local strValues = valueEffectConf.values
            local strTab = string.split(strValues, ",")
            local attrConf = configManager.GetDataById("config_attribute", strTab[1])
            local addValue = 0
            local addAttrTab = {}
            local addBuff = {
              {
                power = v[2],
                values = valueEffectConf.values
              }
            }
            local addAttrTab = Logic.attrLogic:DisposeAttrBuff(addAttrTab, addBuff)
            if attrConf and attrConf.attr_display ~= "" then
              local params = clone(attrConf.params)
              addValue = ScriptManager:RunCmd(attrConf.attr_display, params, addAttrTab)
            end
            local strAddNum = "(+" .. addValue .. "%)"
            uiPart.txt_addNum.gameObject:SetActive(true)
            UIHelper.SetTextColor(uiPart.txt_addNum, strAddNum, AddNumColor)
          end
        end
      else
        uiPart.txt_addNum.gameObject:SetActive(false)
      end
    end)
  end
  
  local function showSkillFunc(nowStageConf, nextStageConf, combineLv)
    self.m_tabWidgets.sv_skillScrollView.verticalNormalizedPosition = 1
    local lvRange = nowStageConf.level
    local hasBreak = false
    if self.openType == OpenType.DOCK then
      hasBreak = Logic.shipCombinationLogic:IfBreakUp(self.heroId, combineLv)
    end
    local pSkillId = 0
    local pSkillLv = 0
    if combineLv == lvRange[2] and hasBreak and nextStageConf then
      pSkillId = nextStageConf.skill_id[1]
      pSkillLv = nextStageConf.skill_id[2]
    else
      pSkillId = nowStageConf.skill_id[1]
      pSkillLv = nowStageConf.skill_id[2]
    end
    local name = Logic.shipLogic:GetPSkillName(pSkillId)
    local desc = Logic.shipLogic:GetPSkillDesc(pSkillId, pSkillLv, false)
    local type = Logic.shipLogic:GetPSkillType(pSkillId)
    local icon = Logic.shipLogic:GetPSkillIcon(pSkillId)
    local color = TalentColor[type]
    UIHelper.SetTextColor(self.m_tabWidgets.tx_skillName, name, color)
    UIHelper.SetImage(self.m_tabWidgets.im_skillIcon, icon)
    UIHelper.SetText(self.m_tabWidgets.tx_skillDesc, desc)
    self.m_tabWidgets.tx_skillDescNextLv.gameObject:SetActive(false)
    if self.openType == OpenType.DOCK and nextStageConf and combineLv == lvRange[2] and not hasBreak then
      local pSkillNextId = nextStageConf.skill_id[1]
      local pSkillNextLv = nextStageConf.skill_id[2]
      local desc = Logic.shipLogic:GetPSkillDesc(pSkillNextId, pSkillNextLv, false)
      self.m_tabWidgets.tx_skillDescNextLv.gameObject:SetActive(true)
      UIHelper.SetText(self.m_tabWidgets.tx_skillDescNextLv, desc)
    end
  end
  
  if self.openType == OpenType.ILLUSTRATE then
    if not Logic.shipLogic:CheckShipCanCombineBySs_id(self.illustrateId) then
      return
    end
    combConf = Logic.shipCombinationLogic:GetCombineConfBySs_id(self.illustrateId)
    shipCombineLv = 0
    shipGrade = 0
    propBaseTab, propBasePercentTab = Logic.shipCombinationLogic:GetCombAttrTabBySs_id(self.illustrateId)
    hasOpenFunc = false
    self.m_tabWidgets.btn_open.gameObject:SetActive(false)
    self.m_tabWidgets.btn_breakup.gameObject:SetActive(false)
    self.m_tabWidgets.btn_levelup.gameObject:SetActive(false)
    self.m_tabWidgets.btn_levelupfast.gameObject:SetActive(false)
    self.m_tabWidgets.trans_costItemContent.gameObject:SetActive(false)
    self.m_tabWidgets.btn_showmax.gameObject:SetActive(false)
  elseif self.openType == OpenType.DOCK then
    if not Logic.shipLogic:CheckShipCanCombine(self.heroId) then
      logError("\232\136\176\229\168\152\228\184\141\232\131\189\229\164\159\229\133\177\233\184\163\239\188\140heroID:%d", self.heroId)
      return
    end
    local combinationTab = Logic.shipCombinationLogic:GetCombineData(self.heroId)
    if Logic.shipCombinationLogic:CheckIsOpenCombine(self.heroId) then
      shipCombineLv = combinationTab.ComLv
      hasOpenFunc = true
    else
      if self.showMax then
        shipCombineLv = MAXCOMBINELV
      else
        shipCombineLv = 1
      end
      hasOpenFunc = false
    end
    combConf, nextStageConf = Logic.shipCombinationLogic:GetCombineConf(self.heroId, shipCombineLv)
    local heroInfo = Data.heroData:GetHeroById(self.heroId)
    propBaseTab, propBasePercentTab = Logic.shipCombinationLogic:GetCombAttrTab(self.heroId, shipCombineLv)
    nextAddPropTab, nextAddPropPercentTab = Logic.shipCombinationLogic:GetNextAddAttrTab(self.heroId, shipCombineLv)
    local isMaxLv = shipCombineLv == MAXCOMBINELV
    local lvRangeTab = combConf.level
    local showBreakBtn = shipCombineLv == lvRangeTab[2] and not Logic.shipCombinationLogic:IfBreakUp(self.heroId, shipCombineLv)
    if showBreakBtn and nextStageConf and 0 < nextStageConf.break_star then
      self.m_tabWidgets.tx_textStar.gameObject:SetActive(true)
      local str = UIHelper.GetLocString(4900017, nextStageConf.break_star)
      local isMeet = heroInfo.Advance >= nextStageConf.break_star
      if isMeet then
        str = UIHelper.SetColor(str, BreakMeetColor)
      else
        str = UIHelper.SetColor(str, BreakNotMeetColor)
      end
      UIHelper.SetText(self.m_tabWidgets.tx_textStar, str)
    else
      self.m_tabWidgets.tx_textStar.gameObject:SetActive(false)
    end
    self.m_tabWidgets.btn_open.gameObject:SetActive(not hasOpenFunc and not isMaxLv)
    self.m_tabWidgets.btn_breakup.gameObject:SetActive(showBreakBtn and not isMaxLv)
    self.m_tabWidgets.btn_levelup.gameObject:SetActive(hasOpenFunc and not showBreakBtn and not isMaxLv)
    self.m_tabWidgets.btn_levelupfast.gameObject:SetActive(hasOpenFunc and not showBreakBtn and not isMaxLv)
    self.m_tabWidgets.btn_showmax.gameObject:SetActive(not hasOpenFunc)
    local costItemTab = {}
    local _, levelUpItemTab = self:_CheckLvUpCostIsEnough(shipCombineLv)
    local _, breakItemTab = self:_CheckBreakUpCostIsEnough(shipCombineLv)
    if Logic.shipCombinationLogic:CheckIsOpenCombine(self.heroId) then
      if shipCombineLv == lvRangeTab[2] and not Logic.shipCombinationLogic:IfBreakUp(self.heroId, shipCombineLv) then
        costItemTab = breakItemTab
      else
        costItemTab = levelUpItemTab
      end
    else
      costItemTab = breakItemTab
    end
    if 0 < table.nums(costItemTab) then
      self.m_tabWidgets.trans_costItemContent.gameObject:SetActive(true)
      UIHelper.CreateSubPart(self.m_tabWidgets.obj_costItem, self.m_tabWidgets.trans_costItemContent, #costItemTab, function(index, uipart)
        local costItemInfo = costItemTab[index]
        local icon = Logic.goodsLogic:GetIcon(costItemInfo[2], costItemInfo[1])
        UIHelper.SetImage(uipart.im_icon, icon)
        local quality = Logic.goodsLogic:GetQuality(costItemInfo[2], costItemInfo[1])
        UIHelper.SetImageByQuality(uipart.img_quality_todo, quality)
        local needNum = costItemInfo[3]
        local haveNum = Logic.bagLogic:GetConsumeCurrNum(costItemInfo[1], costItemInfo[2])
        local haveNumStr = tostring(haveNum)
        if needNum > haveNum then
          haveNumStr = UIHelper.SetColor(haveNumStr, CostNotEnoughColor)
        end
        UIHelper.SetText(uipart.tx_num, haveNumStr .. "/" .. tostring(needNum))
        local itemName = Logic.goodsLogic:GetName(costItemInfo[2], costItemInfo[1])
        UIHelper.SetText(uipart.tx_name, itemName)
        
        local function showItemInfo()
          Logic.itemLogic:ShowItemInfo(costItemInfo[1], costItemInfo[2], true)
        end
        
        UGUIEventListener.AddButtonOnClick(uipart.btn_reward, showItemInfo)
      end)
    else
      self.m_tabWidgets.trans_costItemContent.gameObject:SetActive(false)
    end
  end
  if hasOpenFunc then
    UIHelper.SetLocText(self.m_tabWidgets.tx_propeffect, 4900006)
    local str = "Lv:" .. shipCombineLv
    if shipCombineLv == MAXCOMBINELV then
      str = str .. "(MAX)"
    end
    UIHelper.SetText(self.m_tabWidgets.tx_levelnum, str)
  else
    local showMaxBtnTxt = self.m_tabWidgets.btn_showmax.gameObject:GetComponentInChildren(UIText.GetClassType())
    local showMaxBtnStr = ""
    if self.showMax then
      showMaxBtnStr = UIHelper.GetString(4900033)
    else
      showMaxBtnStr = UIHelper.GetString(4900032)
    end
    UIHelper.SetText(showMaxBtnTxt, showMaxBtnStr)
    UIHelper.SetText(self.m_tabWidgets.tx_propeffect, UIHelper.GetString(4900036))
    if self.openType == OpenType.ILLUSTRATE then
      local lvStr = "Lv:" .. MAXCOMBINELV .. "(MAX)"
      UIHelper.SetText(self.m_tabWidgets.tx_levelnum, lvStr)
    elseif self.openType == OpenType.DOCK then
      UIHelper.SetLocText(self.m_tabWidgets.tx_levelnum, 4900003)
    end
  end
  showAttrFunc(propBaseTab, propBasePercentTab, nextAddPropTab, nextAddPropPercentTab)
  showSkillFunc(combConf, nextStageConf, shipCombineLv)
end

function ShipCombinationPage:_OnLevelUpBtnClick()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local selfStar = heroInfo.Advance
  local combineData = heroInfo.CombinationInfo
  if Logic.shipCombinationLogic:CheckIsOpenCombine(self.heroId) then
    local isEnough = self:_CheckLvUpCostIsEnough(combineData.ComLv)
    if not isEnough then
      noticeManager:ShowTip(UIHelper.GetString(4900014))
      return
    end
  else
    local isEnough = self:_CheckBreakUpCostIsEnough(1)
    if not isEnough then
      noticeManager:ShowTip(UIHelper.GetString(4900013))
      return
    end
  end
  Service.heroService:_SendCombinationLevelUp(self.heroId)
end

function ShipCombinationPage:_OnLevelUpFastBtnClick()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local selfStar = heroInfo.Advance
  local combineData = heroInfo.CombinationInfo
  local isEnough = self:_CheckLvUpCostIsEnough(combineData.ComLv)
  if not isEnough then
    noticeManager:ShowTip(UIHelper.GetString(4900014))
    return
  end
  Service.heroService:_SendCombinationLevelUpFast(self.heroId)
end

function ShipCombinationPage:_OnBreakBtnClick()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local selfStar = heroInfo.Advance
  local combineData = heroInfo.CombinationInfo
  local isEnough = self:_CheckBreakUpCostIsEnough(combineData.ComLv)
  if not isEnough then
    noticeManager:ShowTip(UIHelper.GetString(4900018))
    return
  end
  local _, nextConf = Logic.shipCombinationLogic:GetCombineConf(self.heroId, combineData.ComLv)
  if nextConf then
    local needStar = nextConf.break_star
    if selfStar < needStar then
      local strTip = string.format(UIHelper.GetString(4900017), needStar)
      noticeManager:ShowTip(strTip)
      return
    end
    Service.heroService:_SendCombinationBreakUp(self.heroId)
  end
end

function ShipCombinationPage:_CheckLvUpCostIsEnough(combineLv)
  local isEnough = true
  local costItemTab = {}
  local combConf, nextConf = Logic.shipCombinationLogic:GetCombineConf(self.heroId, combineLv)
  if Logic.shipCombinationLogic:IfBreakUp(self.heroId, combineLv) then
    if nextConf then
      costItemTab = nextConf.levelup_item
    end
  elseif combineLv < MAXCOMBINELV then
    costItemTab = combConf.levelup_item
  end
  for _, costItem in pairs(costItemTab) do
    local haveNum = Logic.bagLogic:GetConsumeCurrNum(costItem[1], costItem[2])
    if haveNum < costItem[3] then
      isEnough = false
      break
    end
  end
  return isEnough, costItemTab
end

function ShipCombinationPage:_CheckBreakUpCostIsEnough(combineLv)
  local isEnough = true
  local costItemTab = {}
  local conf, nextConf = Logic.shipCombinationLogic:GetCombineConf(self.heroId, combineLv)
  if Logic.shipCombinationLogic:CheckIsOpenCombine(self.heroId) then
    if nextConf then
      costItemTab = nextConf.break_item
    end
  elseif combineLv == 1 then
    costItemTab = conf.break_item
  end
  for _, costItem in pairs(costItemTab) do
    local haveNum = Logic.bagLogic:GetConsumeCurrNum(costItem[1], costItem[2])
    if haveNum < costItem[3] then
      isEnough = false
      break
    end
  end
  return isEnough, costItemTab
end

function ShipCombinationPage:_OnUpdateHero(param)
  if param.isLevelUp then
    local combineData = Logic.shipCombinationLogic:GetCombineData(self.heroId)
    if combineData.ComLv > 1 then
      noticeManager:ShowTip(UIHelper.GetString(4900015))
    else
      noticeManager:ShowTip(UIHelper.GetString(4900011))
    end
  elseif param.isBreak then
    noticeManager:ShowTip(UIHelper.GetString(4900035))
  end
  self:_UpdateView()
end

function ShipCombinationPage:_OnShowMaxBtnClick()
  self.showMax = not self.showMax
  self:_UpdateView()
end

return ShipCombinationPage
