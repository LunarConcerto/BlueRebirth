local Strengthen_Page = class("UI.GirlInfo.Strengthen_Page", LuaUIPage)
local COEFFICIENT = 2
local SLIDERBGWIDTH = 346.36
local SLIDERBGHEIGHT = 19

function Strengthen_Page:DoInit()
  Logic.selectedShipPageLogic:Reset()
  self.itemCount = 0
  self.tabSeq = {}
  self.tabEff = {}
end

function Strengthen_Page:DoOnOpen()
  local widgets = self:GetWidgets()
  self.m_strengthHeroId = self:GetParam().heroId
  self.m_selectedIdArr = {}
  local bUseDiamond = widgets.tog_strength.isOn
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
  RetentionHelper.Retention(PlatformDotType.uilog, {
    info = "ui_ship_intensify"
  })
end

function Strengthen_Page:UpdateGirlTog(heroId)
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToBeginning()
  widgets.tween_dongHua:Play(true)
  self.m_playingAnim = false
  widgets.explode:SetActive(false)
  noticeManager:CloseTip()
  self:_CloseEffect()
  local heroId = heroId
  self.m_strengthHeroId = heroId
  self.m_selectedIdArr = {}
  local bUseDiamond = widgets.tog_strength.isOn
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
  RetentionHelper.Retention(PlatformDotType.uilog, {
    info = "ui_ship_intensify"
  })
end

function Strengthen_Page:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self._Add, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_strength, self._Strength, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_strength, self._DiamondStrength, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._EndIntensifyAmim, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectBlue, self._SetRHeroSelect, self, widgets.tog_selectBlue)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectOther, self._SetTypeMatchCancel, self, widgets.tog_selectOther)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_selectTwelve, self._SetSelectMore, self, widgets.tog_selectTwelve)
  self:RegisterEvent(LuaEvent.UpdataSelect, self._UpdateSelectInfo, self)
  self:RegisterEvent(LuaEvent.HeroIntensifySuccess, self._IntensifySuccess, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI)
  self:RegisterEvent(LuaEvent.GuideSettingReceive, self._OnSetOk)
end

function Strengthen_Page:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function Strengthen_Page:_GirlInfoTween(delta)
  local widgets = self:GetWidgets()
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    widgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    widgets.tween_dongHua.from = widgets.obj_dongHua.transform.anchoredPosition3D
    widgets.tween_dongHua:ResetToBeginning()
    widgets.tween_dongHua:Play(true)
  end
end

function Strengthen_Page:_OnSetOk(settings)
  for _, setting in pairs(settings) do
    if setting.Key == "LOGIC_HERO_INTENSIFY_MORESELECT" then
      local selectMax = Logic.strengthen_PageLogic:GetSelectHeroMax()
      local selectHero = self.m_selectedIdArr
      if selectMax < #selectHero then
        table.filter(selectHero, function(heroId, index)
          return index <= selectMax
        end)
      end
      self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, self.m_data.bUseDiamond)
      self:_LoadStrengProp()
      self:_LoadShipItem()
    end
  end
end

function Strengthen_Page:DoOnHide()
  self.m_playingAnim = false
end

function Strengthen_Page:DoOnClose()
  self.m_playingAnim = false
end

function Strengthen_Page:_UpdateShipInfo()
  self.m_selectedIdArr = {}
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, self.m_data.bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
end

function Strengthen_Page:_UpdateSelectInfo(tabParam)
  self:_CloseEffect()
  self.m_selectedIdArr = tabParam[1]
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, self.m_data.bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
end

function Strengthen_Page:_PlayAddAnim()
  if self.m_playingAnim then
    return
  else
    self.m_playingAnim = true
  end
  local data = self.m_data
  local partArr = self.m_propPartArr
  local emptyVec2 = Vector2.New(0, SLIDERBGHEIGHT)
  local fullVec2 = Vector2.New(SLIDERBGWIDTH, SLIDERBGHEIGHT)
  local SingleCircleTime = 0.2
  local count = 0
  self.tabSeq = {}
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, self.m_data.bUseDiamond)
  self:_LoadShipItem()
  self:_SetDiamond()
  for i, prop in ipairs(data.propertyArr) do
    local part = partArr[i]
    local pData = data.propertyArr[i]
    local realAddExp = pData.realAddExp + pData.curExp
    local needExp = pData.needExp
    if 0 < realAddExp then
      table.insert(self.tabEff, part.eff)
      count = count + 1
      local seq = UISequence.NewSequence(part.gameObject, false)
      while realAddExp > needExp do
        seq:AppendCallback(function()
          part.trans_slideradd.sizeDelta = fullVec2
        end)
        seq:AppendInterval(0.1)
        local sizeNow = part.trans_slidernow.sizeDelta
        seq:Append(part.trans_slidernow:TweenSizeDetla(sizeNow, fullVec2, SingleCircleTime))
        if realAddExp ~= needExp then
          seq:AppendCallback(function()
            part.trans_slidernow.sizeDelta = emptyVec2
          end)
        end
        realAddExp = realAddExp - needExp
      end
      if 0 < realAddExp then
        seq:AppendCallback(function()
          part.trans_slideradd.sizeDelta = Vector2.New(realAddExp / needExp * SLIDERBGWIDTH, SLIDERBGHEIGHT)
        end)
        seq:AppendInterval(0.1)
        seq:Append(part.trans_slidernow:TweenSizeDetla(emptyVec2, Vector2.New(realAddExp / needExp * SLIDERBGWIDTH, SLIDERBGHEIGHT), SingleCircleTime))
      end
      if realAddExp == needExp then
        seq:AppendCallback(function()
          part.trans_slidernow.sizeDelta = emptyVec2
          part.trans_slideradd.sizeDelta = emptyVec2
        end)
      end
      seq:AppendCallback(function()
        count = count - 1
        if count == 0 then
          self.m_playingAnim = false
          self:_LoadStrengProp()
        end
      end)
      part.eff.gameObject:SetActive(true)
      table.insert(self.tabSeq, seq)
      seq:Play(true)
    else
      part.eff.gameObject:SetActive(false)
    end
  end
end

function Strengthen_Page:_EndIntensifyAmim()
  self:_EndAddTwn()
  self:_SetMask(false)
  self:_LoadStrengProp()
end

function Strengthen_Page:_EndAddTwn()
  self:_CloseEffect()
  if self.tabSeq then
    for _, v in ipairs(self.tabSeq) do
      v:ResetToEnd()
      v:Destroy()
    end
    self.tabSeq = {}
  end
  self.m_playingAnim = false
end

function Strengthen_Page:_IntensifySuccess()
  self.m_selectedIdArr = {}
  self:_SetMask(true)
  eventManager:SendEvent(LuaEvent.ShowStrengthEffect)
  self:_ShowEquipDismantleTip()
end

function Strengthen_Page:_ShowEquipDismantleTip()
  Logic.dockLogic:EquipDeleteTipWRAP()
end

function Strengthen_Page:_SetMask(bo)
  local widgets = self:GetWidgets()
  widgets.im_mask:SetActive(bo)
end

function Strengthen_Page:_CloseEffect()
  if self.tabEff then
    for _, v in pairs(self.tabEff) do
      v.gameObject:SetActive(false)
    end
    self.tabEff = {}
  end
end

function Strengthen_Page:_LoadStrengProp()
  local data = self.m_data
  local widgets = self:GetWidgets()
  self.m_propPartArr = {}
  UIHelper.CreateSubPart(widgets.obj_property, widgets.trans_propparent, #data.propertyArr, function(nIndex, tabPart)
    self.m_propPartArr[nIndex] = tabPart
    if self.tabSeq[nIndex] ~= nil then
      GameObject.Destroy(self.tabSeq[nIndex])
    end
    local propData = data.propertyArr[nIndex]
    local aType = propData.propId
    local maxPowerValue = propData.maxValue
    local nowExp = propData.curExp
    local provideExp = propData.addExp
    local addProp = propData.addValue
    local bOverflow = propData.bOverflow
    local needExp = propData.needExp
    UIHelper.SetImage(tabPart.icon, propData.icon)
    tabPart.name.text = propData.name
    tabPart.maxnum.text = "MAX:" .. Mathf.ToInt(propData.maxValue)
    tabPart.tip.text = string.format(UIHelper.GetString(180008), tostring(propData.maxAdd))
    tabPart.num.text = Mathf.ToInt(propData.curValue)
    if propData.bOverflow then
      UIHelper.SetText(tabPart.radio, "MAX")
    elseif data.bUseDiamond then
      tabPart.radio.text = string.format("%s(+%s)/%s", Mathf.ToInt(nowExp + provideExp), Mathf.ToInt(provideExp * (1 - 1 / data.ratio)), needExp)
    else
      tabPart.radio.text = string.format("%s/%s", Mathf.ToInt(nowExp + provideExp), needExp)
    end
    local tempnum = 0
    if 0 < provideExp and maxPowerValue ~= 0 then
      tempnum = (provideExp + nowExp) / needExp
      tabPart.addnum.text = string.format("+%s", math.floor(tempnum))
    elseif provideExp ~= nil and maxPowerValue ~= 0 then
      tempnum = provideExp / needExp
      tabPart.addnum.text = string.format("+%s", math.floor(tempnum))
    else
      tabPart.addnum.text = ""
    end
    local isMax = self:_PropMaxCheck(propData, tempnum)
    if isMax then
      UIHelper.SetText(tabPart.addnum, "")
    end
    local nowsliderlength
    if needExp ~= 0 and not isMax then
      nowsliderlength = SLIDERBGWIDTH * nowExp / needExp
    else
      nowsliderlength = SLIDERBGWIDTH
    end
    if nowsliderlength > SLIDERBGWIDTH then
      nowsliderlength = SLIDERBGWIDTH
    end
    if data.bUseDiamond then
      tabPart.img_slideradd.color = Color.New(0.26666666666666666, 0.1450980392156863, 0.8666666666666667, 1)
    else
      tabPart.img_slideradd.color = Color.New(0.13725490196078433, 0.35294117647058826, 0.7764705882352941, 1)
    end
    tabPart.trans_slidernow.sizeDelta = Vector2.New(nowsliderlength, SLIDERBGHEIGHT)
    local addsliderlength
    if needExp ~= 0 and not isMax then
      addsliderlength = SLIDERBGWIDTH * (provideExp + nowExp) / needExp
    else
      addsliderlength = 0
    end
    if addsliderlength > SLIDERBGWIDTH then
      addsliderlength = SLIDERBGWIDTH
    end
    tabPart.trans_slideradd.sizeDelta = Vector2.New(addsliderlength, SLIDERBGHEIGHT)
    if isMax and maxPowerValue ~= 0 then
      tabPart.radio.text = "MAX"
    end
    if maxPowerValue == 0 then
      tabPart.radio.text = "MAX"
      tabPart.img_slideradd.color = Color.New(0.5764705882352941, 0.6549019607843137, 0.8, 1)
      tabPart.trans_slidernow.sizeDelta = Vector2.New(SLIDERBGWIDTH, SLIDERBGHEIGHT)
      tabPart.tip.text = ""
    end
    tabPart.addnum.gameObject:SetActive(#data.heroAttr ~= 0)
  end)
  self.tabSeq = {}
end

function Strengthen_Page:_PropMaxCheck(data, add)
  return data.curValue >= data.maxValue or data.curValue + add >= data.maxValue
end

function Strengthen_Page:_LoadShipItem()
  local widgets = self:GetWidgets()
  local data = self.m_data
  local strengthHeroId = self.m_strengthHeroId
  self.itemCount = #data.heroAttr
  local selectMax = Logic.strengthen_PageLogic:GetSelectHeroMax()
  self:UnregisterAllById(LuaEvent.ShowStrengthEffect)
  UIHelper.CreateSubPart(widgets.obj_ship, widgets.trans_ship, selectMax, function(nIndex, tabPart)
    local heroData = data.heroAttr[nIndex]
    tabPart.im_bg.gameObject:SetActive(heroData ~= nil)
    tabPart.obj_rmd:SetActive(false)
    if heroData ~= nil then
      self:_LoadIcon(heroData, tabPart)
      local show = self:_isShowRmd(strengthHeroId, heroData.heroId)
      tabPart.obj_rmd:SetActive(show)
      UGUIEventListener.AddButtonOnClick(tabPart.shipitem, function()
        if #self.m_selectedIdArr >= nIndex then
          table.remove(self.m_selectedIdArr, nIndex)
        end
        self.m_data = self.GenDisplayData(strengthHeroId, self.m_selectedIdArr, data.bUseDiamond)
        self:_LoadShipItem()
        self:_LoadStrengProp()
        self:_SetDiamond()
      end)
      local tailTrans = tabPart.tail_effect:GetComponent(RectTransform.GetClassType())
      tabPart.tail_effect:SetActive(false)
      tailTrans.anchoredPosition = Vector3.zero
      tabPart.box_effect:SetActive(false)
      widgets.explode:SetActive(false)
      self:RegisterEvent(LuaEvent.ShowStrengthEffect, function()
        self:_PlayStrengthenAnim(tabPart.item_trans, tabPart.tail_effect, tabPart.box_effect, nIndex)
      end)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.shipitem, function()
        self:_OpenSelectPage()
      end)
    end
  end)
end

function Strengthen_Page:_isShowRmd(strengthHero, selectHero)
  local tid1 = Data.heroData:GetHeroById(strengthHero).TemplateId
  local tid2 = Data.heroData:GetHeroById(selectHero).TemplateId
  return Logic.strengthen_PageLogic:IsSameType(tid1, tid2)
end

function Strengthen_Page:_PlayStrengthenAnim(parentRectTrans, tailEffect, boxEffect, index)
  local widgets = self:GetWidgets()
  local heroWorldPos = widgets.hero_pos.position
  local dest = parentRectTrans:InverseTransformPoint(heroWorldPos)
  boxEffect:SetActive(true)
  self:PerformDelay(0.517, function()
    local tailTrans = tailEffect:GetComponent(RectTransform.GetClassType())
    tailTrans.gameObject:SetActive(true)
    local duration = 0.4
    local tween = UIHelper.GetTween(tailEffect, ETweenType.ETT_POSITION)
    tween:ResetToInit()
    tween.from = Vector3.zero
    tween.to = dest
    tween.duration = duration
    tween:Play(true)
    self:PerformDelay(duration, function()
      if index == self.itemCount then
        widgets.explode:SetActive(true)
        self:_PlayAddAnim()
        self:PerformDelay(2, function()
          self:_CloseEffect()
          widgets.explode:SetActive(false)
        end)
        self:PerformDelay(4, function()
          self:_SetMask(false)
        end)
        self:PerformDelay(1.0, function()
          local equipIds = Logic.dockLogic:GetHeroEquipsInfo()
          if not tog then
            noticeManager:OpenTipPage(self, UIHelper.GetString(180001))
          end
        end)
      end
    end)
    self:PerformDelay(duration + 0.6, function()
      tailTrans.gameObject:SetActive(false)
      tailTrans.anchoredPosition = Vector3.zero
      boxEffect:SetActive(false)
    end)
  end)
end

function Strengthen_Page:_LoadIcon(heroData, tabPart)
  local quality = Data.heroData:GetHeroById(heroData.heroId).quality
  UIHelper.SetImage(tabPart.im_bg, QualityIcon[quality])
  UIHelper.SetImage(tabPart.icon, heroData.icon)
  tabPart.tx_lv.text = "Lv." .. Mathf.ToInt(heroData.lv)
  for i = 1, 6 do
    local stri = tostring(i)
    tabPart[stri]:SetActive(i <= tonumber(heroData.breakLv))
  end
end

function Strengthen_Page:_OpenSelectPage()
  local data = self.m_data
  local tabParam = {}
  tabParam.m_tabShipInfo = Data.heroData:GetHeroById(self.m_strengthHeroId)
  tabParam.m_selectedIdList = self.m_selectedIdArr
  tabParam.m_selectMax = Logic.strengthen_PageLogic:GetSelectHeroMax()
  tabParam.m_strengthHeroId = self.m_strengthHeroId
  local tabRemainHero = self:GetRemainHero()
  UIHelper.OpenPage("CommonSelectPage", {
    CommonHeroItem.Strengthen,
    tabRemainHero,
    tabParam
  })
end

function Strengthen_Page:_Add()
  self:_EndIntensifyAmim()
  local heroInfo = Data.heroData:GetHeroById(self.m_strengthHeroId)
  local remainHeroArr = self:GetRemainHero()
  local addIdArr = Logic.strengthen_PageLogic:ScreenShip(remainHeroArr, heroInfo.TemplateId)
  local selectMax = Logic.strengthen_PageLogic:GetSelectHeroMax()
  if #addIdArr ~= 0 then
    if selectMax > #self.m_selectedIdArr then
      for k, v in pairs(self.m_selectedIdArr) do
        for key, value in pairs(addIdArr) do
          if v == value.HeroId or Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(value.HeroId) then
            table.remove(addIdArr, key)
          end
        end
      end
      local addCount = 0
      for k, v in pairs(addIdArr) do
        table.insert(self.m_selectedIdArr, v.HeroId)
        addCount = addCount + 1
        if #self.m_selectedIdArr == selectMax then
          break
        end
      end
      if addCount <= 0 then
        local tipContent = UIHelper.GetString(180017)
        noticeManager:OpenTipPage(self, tipContent)
      end
    else
      noticeManager:OpenTipPage(self, "\230\167\189\228\189\141\229\183\178\230\187\161,\230\151\160\230\179\149\228\184\128\233\148\174\230\183\187\229\138\160")
    end
  else
    local tipContent = UIHelper.GetString(180007)
    noticeManager:OpenTipPage(self, tipContent)
  end
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, self.m_data.bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
end

function Strengthen_Page:_Strength()
  local data = self.m_data
  if self.m_playingAnim then
    return
  end
  if #self.m_selectedIdArr == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(180010))
    return
  end
  if self:_CheckAllPropMax() then
    noticeManager:ShowTip(UIHelper.GetString(180015))
    return
  end
  if self:_CheckNoGains() then
    local str = UIHelper.GetString(180013)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ConfirmStrength()
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
    return
  end
  if data.bUseDiamond then
    local singleCost = Mathf.ToInt(configManager.GetDataById("config_parameter", 31).value)
    local cType, costNum = CurrencyType.DIAMOND, singleCost * #self.m_selectedIdArr
    if not Logic.currencyLogic:CheckCurrencyEnough(cType, costNum) then
      noticeManager:OpenTipPage(self, "\233\146\187\231\159\179\228\184\141\232\182\179")
      return
    end
    local strOverflow = data.bOverflow and "\n" .. UIHelper.GetString(180014) or ""
    local str = string.format(UIHelper.GetString(110004) .. strOverflow, costNum)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ConfirmStrength()
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
    return
  end
  self:_ConfirmStrength()
end

function Strengthen_Page:_ConfirmStrength()
  local data = self.m_data
  Service.heroService:SendHeroIntensify(self.m_strengthHeroId, self.m_selectedIdArr, data.bUseDiamond)
  Logic.dockLogic:SroreHeroEquipInfo(self.m_selectedIdArr)
end

function Strengthen_Page:_CheckNoGains()
  local data = self.m_data
  for _, prop in pairs(data.propertyArr) do
    if prop.realAddExp > 0 then
      return false
    end
  end
  return true
end

function Strengthen_Page:_CheckAllPropMax()
  local data = self.m_data
  for _, prop in pairs(data.propertyArr) do
    if prop.curValue < prop.maxValue then
      return false
    end
  end
  return true
end

function Strengthen_Page:_DiamondStrength()
  local data = self.m_data
  self.m_data = self.GenDisplayData(self.m_strengthHeroId, self.m_selectedIdArr, not data.bUseDiamond)
  self:_LoadStrengProp()
  self:_LoadShipItem()
  self:_SetDiamond()
end

function Strengthen_Page:_CheckInOutpostBuilding()
  local selectData = self.m_selectedIdArr
  if not selectData then
    return false
  end
  for i = 1, #selectData do
    local isIn, _ = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(selectData[i])
    if isIn then
      return true
    end
  end
  return false
end

function Strengthen_Page:_SetTypeMatchCancel(go, isOn, toggle)
  if moduleManager:CheckFunc(FunctionID.HERO_Intensity_NoTypeMatch, true) then
    Logic.strengthen_PageLogic:SetTypeMatchCancel(isOn)
  else
    toggle.isOn = not isOn
  end
end

function Strengthen_Page:_SetRHeroSelect(go, isOn, toggle)
  if moduleManager:CheckFunc(FunctionID.HERO_Intensity_AddRHero, true) then
    Logic.strengthen_PageLogic:SetRHeroSelect(isOn)
  else
    toggle.isOn = not isOn
  end
end

function Strengthen_Page:_SetSelectMore(go, isOn, toggle)
  if moduleManager:CheckFunc(FunctionID.HERO_Intensity_MORESELECT, true) then
    Logic.strengthen_PageLogic:SetMoreSelect(isOn)
  else
    toggle.isOn = not isOn
  end
end

function Strengthen_Page._DealProvideExp(tabProvideExp, ratio)
  local tabResult = {}
  for k, v in pairs(tabProvideExp) do
    tabResult[k] = v * ratio
  end
  return tabResult
end

function Strengthen_Page._GetPropName(sm_id)
  local PropName = {}
  local needPower = configManager.GetDataById("config_ship_need_power_exp", sm_id).need_power_exp
  for key, value in pairs(needPower) do
    local pType = value[1]
    local tabTemp = configManager.GetDataById("config_attribute", pType)
    local temp = {}
    table.insert(temp, pType)
    table.insert(temp, tabTemp.attr_name)
    PropName[key] = temp
  end
  return PropName
end

function Strengthen_Page:_SetDiamond()
  local costNum = #self.m_selectedIdArr
  local widgets = self:GetWidgets()
  local singleCost = Mathf.ToInt(configManager.GetDataById("config_parameter", 31).value)
  local ratio = 1 <= costNum and costNum or 1
  local diamondNum = singleCost * ratio
  UIHelper.SetText(widgets.txt_dianum, diamondNum)
  local typeCancel, dTypeCancel = Logic.strengthen_PageLogic:IsTypeMatchCancel()
  local rSelect, dRSelect = Logic.strengthen_PageLogic:IsRHeroSelect()
  local moreSelect, dMoreSelect = Logic.strengthen_PageLogic:IsMoreSelect()
  widgets.tog_selectOther.gameObject:SetActive(dTypeCancel)
  widgets.tog_selectBlue.gameObject:SetActive(dRSelect)
  widgets.tog_selectTwelve.gameObject:SetActive(dMoreSelect)
  widgets.tog_selectOther.isOn = typeCancel
  widgets.tog_selectBlue.isOn = rSelect
  widgets.tog_selectTwelve.isOn = moreSelect
end

function Strengthen_Page:GetRemainHero()
  return Logic.selectedShipPageLogic:FilterHero(self.m_strengthHeroId, Data.heroData:GetHeroData())
end

function Strengthen_Page.GenDisplayData(heroId, consumeHeroIdArr, bUseDiamond)
  local data = {}
  data.ratio = 2
  data.bUseDiamond = bUseDiamond
  data.diamondNeed = data.ratio * #consumeHeroIdArr
  data.propertyArr = Strengthen_Page.GenPropertyData(heroId, consumeHeroIdArr, bUseDiamond, data.ratio)
  data.heroAttr = Strengthen_Page.GenHeroData(consumeHeroIdArr)
  data.bOverflow = false
  for _, prop in ipairs(data.propertyArr) do
    if prop.bOverflow then
      data.bOverflow = true
    end
  end
  return data
end

function Strengthen_Page.GenHeroData(consumeHeroIdArr)
  local heroArr = {}
  for i, heroId in ipairs(consumeHeroIdArr) do
    local heroInfo = Data.heroData:GetHeroById(heroId)
    local shipShow = Logic.shipLogic:GetShipShowByHeroId(heroId)
    local heroData = {}
    heroData.heroId = heroId
    heroData.icon = Logic.shipLogic:GetHeroSquareIcon(shipShow.ss_id)
    heroData.lv = heroInfo.Lvl
    heroData.breakLv = heroInfo.Advance
    heroArr[i] = heroData
  end
  return heroArr
end

function Strengthen_Page.GenPropertyData(heroId, consumeHeroIdArr, bUseDiamond, ratio)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local sm_id = heroInfo.TemplateId
  local breakMax = Logic.shipLogic:GetBreakMaxByShipMainId(sm_id)
  local breakLv = heroInfo.Advance
  local last_sm_id = breakLv == 1 and sm_id or sm_id - 1
  local maxPower = configManager.GetDataById("config_ship_max_power", sm_id).max_power_prop
  local lastMaxPower = configManager.GetDataById("config_ship_max_power", last_sm_id).max_power_prop
  local needPower = configManager.GetDataById("config_ship_need_power_exp", sm_id).need_power_exp
  local maxPowerDic = {}
  local subMaxPowerDic = {}
  local provideProp = {}
  local insensifyLvl = {}
  local nowProp = {}
  local intensify = heroInfo.Intensify
  local needPowerDic = {}
  for k, arr in pairs(maxPower) do
    maxPowerDic[arr[1]] = arr[2]
    if last_sm_id == sm_id then
      subMaxPowerDic[arr[1]] = arr[2]
    else
      subMaxPowerDic[arr[1]] = arr[2] - lastMaxPower[k][2]
    end
  end
  for _, value in pairs(intensify) do
    insensifyLvl[value.AttrType] = value.IntensifyLvl
  end
  for _, value in pairs(intensify) do
    local tabTemp = {}
    nowProp[value.AttrType] = value.CurExp
  end
  for _, need in ipairs(needPower) do
    needPowerDic[need[1]] = need[2]
  end
  local remainHeroArr = Logic.selectedShipPageLogic:FilterHero(heroId, Data.heroData:GetHeroData())
  local attrNameArr = Strengthen_Page._GetPropName(sm_id)
  local consumeHeroTIdArr = Logic.selectedShipPageLogic:ConvertTabId(consumeHeroIdArr, remainHeroArr)
  local totalExpDic = Logic.selectedShipPageLogic:GetTotalExpNum(consumeHeroTIdArr, attrNameArr, sm_id)
  if bUseDiamond then
    provideProp = Strengthen_Page._DealProvideExp(totalExpDic, ratio)
  else
    provideProp = totalExpDic
  end
  local ret = {}
  for _, attrData in pairs(attrNameArr) do
    local pData = {}
    local propId = attrData[1]
    local name = attrData[2]
    if needPowerDic[propId] then
      pData.propId = propId
      pData.name = name
      local attrConf = configManager.GetDataById("config_attribute", propId)
      pData.icon = attrConf.attr_icon
      pData.maxAdd = subMaxPowerDic[propId]
      pData.curExp = nowProp[propId] or 0
      pData.addExp = provideProp[propId]
      pData.needExp = needPowerDic[propId]
      local basicAttr = Logic.attrLogic:GetHeroBasicAttrById(heroId)
      pData.curValue = basicAttr[propId]
      local purelv = insensifyLvl[propId] or 0
      pData.maxValue = basicAttr[propId] - purelv + maxPowerDic[propId]
      local addValue = provideProp[propId] / needPowerDic[propId]
      local bOverflow = purelv * needPowerDic[propId] + provideProp[propId] + pData.curExp > maxPowerDic[propId] * needPowerDic[propId]
      addValue = bOverflow and pData.maxValue - pData.curValue or addValue
      pData.addValue = addValue
      pData.bOverflow = bOverflow
      pData.realAddExp = bOverflow and addValue * needPowerDic[propId] - pData.curExp or provideProp[propId]
      table.insert(ret, pData)
    end
  end
  return ret
end

return Strengthen_Page
