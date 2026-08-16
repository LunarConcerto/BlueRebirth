local EquipIntensifyPage = class("UI.Equip.EquipIntensifyPage", LuaUIPage)

function EquipIntensifyPage:DoInit()
  self.m_tabWidgets = nil
  self.m_equipId = 0
  self.m_addNum = 0
  self.m_equipLv = 0
  self.m_needMaxExp = 0
  self.m_lastEquipLv = 0
  self.isPress = false
  self.m_equip = nil
  self.m_addExp = 0
  self.m_tabTweenSlider = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_fleetType = FleetType.Normal
end

function EquipIntensifyPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function EquipIntensifyPage:_GetFleetType()
  return self.m_fleetType
end

function EquipIntensifyPage:DoOnOpen()
  self.m_equipId = self:GetParam().EquipId
  self:_SetFleetType(self:GetParam().FleetType)
  local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  self.m_equipMaxStar = Logic.equipLogic:GetEquipMaxStar(equip.TemplateId)
  self.m_equipMaxLv = Logic.equipLogic:GetEquipMaxLv(equip.TemplateId)
  self.m_lastEquipLv = Mathf.ToInt(equip.EnhanceLv)
  self:UpdateEquipInfo()
  local dotinfo = {
    info = "ui_equip_intensify"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function EquipIntensifyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Bg, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_close, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Cancel, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Amend, self._Amend, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Intensify, self._Intensify, self)
  self:RegisterEvent(LuaEvent.UpdateBagEquip, self.UpdateEquipInfo, self)
end

function EquipIntensifyPage:UpdateEquipInfo(isEnhance)
  self.m_tempEquip = nil
  local widgets = self:GetWidgets()
  self.m_equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  local equipInfo = configManager.GetDataById("config_equip", self.m_equip.TemplateId)
  local isMaxLevel = false
  self.m_equipLv = self.m_equip.EnhanceLv
  local lock = Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()) == MEquipState.LOCK
  if not self.isPress and self.m_equipLv - self.m_lastEquipLv > 0 then
    self:_PlayUpLvTween()
    self.m_lastEquipLv = Mathf.ToInt(self.m_equipLv)
  end
  widgets.tx_name.text = equipInfo.name
  UIHelper.SetImage(widgets.im_icon, tostring(equipInfo.icon))
  UIHelper.SetImage(widgets.im_quality, QualityIcon[equipInfo.quality])
  widgets.tx_equipLv.gameObject:SetActive(self.m_equipLv > 0)
  if self.m_equipLv > 0 then
    UIHelper.SetText(widgets.tx_equipLv, "+" .. Mathf.ToInt(self.m_equipLv))
  end
  UIHelper.SetStar(widgets.obj_Star, widgets.trans_Star, self.m_equip.Star)
  UIHelper.SetText(widgets.tx_Lv, "Lv" .. Mathf.ToInt(self.m_equipLv))
  local allExp, curExp, needExp = 0, 0, 0
  if self.m_equipLv == self.m_equipMaxLv then
    for i = 1, self.m_equipLv - 1 do
      local tempExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
      allExp = allExp + tempExp
    end
    curExp = self.m_equip.EnhanceExp - allExp
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", self.m_equipLv).exp
  elseif self.m_equipLv < self.m_equipMaxLv then
    for i = 1, self.m_equipLv do
      local tempExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
      allExp = allExp + tempExp
    end
    curExp = self.m_equip.EnhanceExp - allExp
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", self.m_equipLv + 1).exp
  end
  if isEnhance then
    widgets.ui_equence:Clear()
    for i, v in ipairs(self.m_tabTweenSlider) do
      v:Destroy(v)
    end
    self.m_tabTweenSlider = {}
    self:_PlayInsTween(widgets, self.m_equipLv, self.m_equip.EnhanceExp, self.m_addExp)
  end
  widgets.slider.value = Mathf.ToInt(curExp) / needExp
  self.m_lastProgress = curExp / needExp
  UIHelper.SetText(widgets.tx_ratio, Mathf.ToInt(curExp) .. "/" .. needExp)
  local renovate
  if self.m_equipMaxStar == Mathf.ToInt(self.m_equip.Star) then
    renovate = configManager.GetDataById("config_equip_enhance_renovate", self.m_equip.Star)
    if not lock then
      local itemTbl, result = Logic.equipIntensifyLogic:GetExpItemTableByEquipId(self.m_equipId)
      widgets.btn_Amend.gameObject:SetActive(false)
      widgets.btn_Intensify.gameObject:SetActive(true)
      widgets.gray_Intensify.Gray = not result or self.m_equipLv >= self.m_equipMaxLv
    else
      widgets.btn_Amend.gameObject:SetActive(false)
      widgets.btn_Intensify.gameObject:SetActive(true)
      local enough = true
      local costItems = configManager.GetDataById("config_equip_levelbreak_item", 1).item_cost
      for _, costItem in ipairs(costItems) do
        local haveNum = Logic.bagLogic:GetConsumeCurrNum(costItem[1], costItem[2])
        if haveNum == 0 or haveNum < costItem[3] then
          enough = false
          break
        end
      end
      local testNum = Logic.bagLogic:GetConsumeCurrNum(6, 60002)
      widgets.gray_Intensify.Gray = not enough
    end
  else
    renovate = configManager.GetDataById("config_equip_enhance_renovate", self.m_equip.Star + 1)
    local itemTbl, result = Logic.equipIntensifyLogic:GetExpItemTableByEquipId(self.m_equipId)
    local isAmend = self.m_equipLv >= renovate.need_enhance_level
    widgets.btn_Amend.gameObject:SetActive(isAmend)
    widgets.btn_Intensify.gameObject:SetActive(not isAmend)
    widgets.gray_Intensify.Gray = not result
  end
  self.m_needMaxExp = self:GetNeedMaxExp(self.m_equip.EnhanceExp, renovate.need_enhance_level)
  local expLevelUp = needExp - curExp
  local consumes = Logic.equipIntensifyLogic:GetExpItemTable(self.m_equipLv)
  if lock then
    consumes = Logic.equipIntensifyLogic:GetBindIntensifyItems()
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_Consume, self.m_tabWidgets.trans_Consume, #consumes, function(nIndex, tabPart)
    if not lock then
      local value = consumes[nIndex]
      UIHelper.SetImage(tabPart.im_bg, EquipQualityIcon[value.quality])
      UIHelper.SetImage(tabPart.im_icon, tostring(value.icon))
      local content = string.format(UIHelper.GetString(170010), value.exp)
      UIHelper.SetText(tabPart.tx_name, content)
      local item = Logic.bagLogic:ItemInfoById(value.id)
      local count = 0
      if item then
        count = Mathf.ToInt(item.num)
      end
      local numNeed = math.ceil(expLevelUp / value.exp)
      if count < numNeed then
        tabPart.tx_exp.text = string.format("<color=#D54852>%d</color>/%d", count, numNeed)
      else
        tabPart.tx_exp.text = count .. "/" .. numNeed
      end
      UGUIEventListener.AddButtonOnClick(tabPart.im_icon, function()
        local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.EQUIP_ENHANCE_ITEM, value.id))
      end)
    else
      local value = consumes[nIndex]
      local haveNum = Logic.bagLogic:GetConsumeCurrNum(value.type, value.id)
      UIHelper.SetImage(tabPart.im_icon, tostring(value.icon))
      UIHelper.SetText(tabPart.tx_exp, tostring(value.num .. "/" .. haveNum))
      UGUIEventListener.AddButtonOnClick(tabPart.im_icon, function()
        local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(value.type, value.id))
      end)
    end
  end)
  if self.m_equipLv >= renovate.need_enhance_level and self.m_equip.Star < self.m_equipMaxStar or self.m_equipLv >= equipInfo.enhance_level_max then
    isMaxLevel = true
  end
  if lock then
    local equipBreakLvConf = configManager.GetDataById("config_equip_levelbreak_item", 1)
    local levelRank = equipBreakLvConf.level_rank
    if self.m_equipLv >= levelRank[1] and self.m_equipLv < levelRank[2] then
      isMaxLevel = false
    end
  end
  self:LoadProperty(isMaxLevel, self.m_equip.TemplateId, self.m_equipLv)
end

function EquipIntensifyPage:_ItemClickCB(needLv, itemInfo, itemIcon)
  SoundManager.Instance:PlayAudio("UI_Button_EquipIntensifyPage_0003")
  if needLv <= self.m_equipLv and self.m_equip.Star < self.m_equipMaxStar then
    if not noticeManager:GetIsClose() then
      return
    end
    noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167\239\188\140\232\175\183\230\148\185\228\191\174\230\143\144\229\141\135\229\188\186\229\140\150\231\173\137\231\186\167")
  elseif self.m_equipLv == self.m_equipMaxLv then
    if not noticeManager:GetIsClose() then
      return
    end
    noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167")
  else
    Logic.equipLogic:CheckEquipIntensifyAndSend(self.m_equipId, itemInfo.id, 1)
    self:_PlayItemCostEffect(itemIcon, itemInfo.id)
    self.m_tempEquip = nil
    self.m_addExp = itemInfo.exp
  end
end

function EquipIntensifyPage:_PlayUpLvTween()
  local objAddExp = GameObject.Instantiate(self.m_tabWidgets.im_addlv, self.m_tabWidgets.base_lv)
  objAddExp:SetActive(true)
  SoundManager.Instance:PlayAudio("Effect_Eff_Levelup")
  local m_tweenPosition = UIHelper.GetTween(objAddExp, ETweenType.ETT_POSITION)
  local m_tweenScale = UIHelper.GetTween(objAddExp, ETweenType.ETT_SCALE)
  m_tweenPosition:Play(true)
  m_tweenScale:Play(true)
  GameObject.Destroy(objAddExp, 1)
end

function EquipIntensifyPage:_ItemPressCB(itemId, providExp, maxLevel, itemtext, itemIcon)
  SoundManager.Instance:PlayAudio("UI_Button_EquipIntensifyPage_0003")
  self.isPress = true
  self.m_item_count = 0
  local equip = self:GetTempInfo()
  local duration = configManager.GetDataById("config_parameter", 35).value / 10000
  self:StopAllTimer()
  self.m_timer = self:CreateTimer(function()
    self:_PressLogic(itemId, providExp, maxLevel, itemtext, equip, itemIcon)
  end, duration, -1, false)
  self:StartTimer(self.m_timer)
  self.m_addExp = providExp
end

function EquipIntensifyPage:GetTempInfo()
  return self.m_tempEquip or clone(Logic.equipLogic:GetEquipById(self.m_equipId))
end

function EquipIntensifyPage:_PlayItemCostEffect(itemIcon, id)
  local have, obj = Logic.equipLogic:PoolGet(id)
  if not have then
    obj = self:_CreateCostItem(itemIcon)
    Logic.equipLogic:PoolAdd(obj, id)
  end
  self:_ResetAndPlay(obj)
end

function EquipIntensifyPage:_CreateCostItem(itemIcon)
  local iconObj = itemIcon.gameObject
  local iconTrans = iconObj:GetComponent(RectTransform.GetClassType())
  local iconCopy = UIHelper.CreateGameObject(iconObj, iconTrans.parent, false)
  local tweenPosition = UIHelper.GetTween(iconCopy, ETweenType.ETT_POSITION)
  local tweenAlpha = UIHelper.GetTween(iconCopy, ETweenType.ETT_ALPHA)
  local tweenScale = UIHelper.GetTween(iconCopy, ETweenType.ETT_SCALE)
  local starObj = self.m_tabWidgets.eff_star
  local starTrans = starObj:GetComponent(RectTransform.GetClassType())
  local toPos = iconTrans.parent:InverseTransformPoint(starTrans.position)
  local duration = 0.3
  tweenPosition.from = iconTrans.localPosition
  tweenPosition.to = toPos
  tweenPosition.duration = duration
  tweenScale.from = Vector3.one
  tweenScale.to = Vector3.zero
  tweenScale.duration = duration
  tweenAlpha.from = 1
  tweenAlpha.to = 0
  tweenAlpha.duration = duration
  return iconCopy
end

function EquipIntensifyPage:_ResetAndPlay(obj)
  local tweenPosition = UIHelper.GetTween(obj, ETweenType.ETT_POSITION)
  local tweenAlpha = UIHelper.GetTween(obj, ETweenType.ETT_ALPHA)
  local tweenScale = UIHelper.GetTween(obj, ETweenType.ETT_SCALE)
  tweenPosition:ResetToInit()
  tweenPosition:Play(true)
  tweenAlpha:ResetToInit()
  tweenAlpha:Play(true)
  tweenScale:ResetToInit()
  tweenScale:Play(true)
  self:PerformDelay(0.3, function()
    SoundManager.Instance:PlayAudio("Effect_eff_equipintensify_light")
    self.m_tabWidgets.eff_star:SetActive(false)
    self.m_tabWidgets.eff_star:SetActive(true)
  end)
end

function EquipIntensifyPage:_PressLogic(itemId, providExp, maxLevel, itemtext, equipTemp, itemIcon)
  if not noticeManager:GetIsClose() then
    return
  end
  if maxLevel <= equipTemp.EnhanceLv and equipTemp.Star < self.m_equipMaxStar then
    noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167\239\188\140\232\175\183\230\148\185\228\191\174\230\143\144\229\141\135\229\188\186\229\140\150\231\173\137\231\186\167")
    self:StopAllTimer()
  elseif equipTemp.EnhanceLv == self.m_equipMaxLv then
    noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167")
    Logic.equipLogic:CheckEquipIntensifyAndSend(self.m_equipId, itemId, self.m_item_count)
    self.m_tempEquip = nil
    self:StopAllTimer()
  else
    self.m_item_count = self.m_item_count + 1
    self:_PlayItemCostEffect(itemIcon, itemId)
    local item = Logic.bagLogic:ItemInfoById(itemId)
    if item.num < self.m_item_count then
      self:StopTimer(self.m_timer)
      return
    end
    if self:_CheckOverIntensify(itemId, self.m_item_count) then
      Logic.equipLogic:CheckEquipIntensifyAndSend(self.m_equipId, itemId, self.m_item_count)
      self.m_tempEquip = nil
      self.isPress = false
      self:StopTimer(self.m_timer)
    end
    self:_ShowProgram(equipTemp, itemId, self.m_item_count, itemtext)
  end
end

function EquipIntensifyPage:_CheckOverIntensify(itemId, itemCount)
  if self:_ProvidExp(itemId, itemCount) >= self.m_needMaxExp and self:_ProvidExp(itemId, itemCount - 1) < self.m_needMaxExp then
    return true
  end
  return false
end

function EquipIntensifyPage:_ProvidExp(itemId, count)
  local item_data = configManager.GetDataById("config_equip_enhance_item", itemId)
  return item_data.exp * count
end

function EquipIntensifyPage:_ItemUpCB(itemId, maxlevel)
  if self.isPress then
    if not noticeManager:GetIsClose() then
      return
    end
    local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
    if maxlevel <= equip.EnhanceLv and equip.Star < self.m_equipMaxStar then
      noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167\239\188\140\232\175\183\230\148\185\228\191\174\230\143\144\229\141\135\229\188\186\229\140\150\231\173\137\231\186\167")
      return
    end
    if equip.EnhanceLv == self.m_equipMaxLv then
      noticeManager:ShowMsgBox("\232\175\165\232\163\133\229\164\135\229\183\178\229\188\186\229\140\150\229\136\176\230\187\161\231\186\167")
      return
    end
    Logic.equipLogic:CheckEquipIntensifyAndSend(self.m_equipId, itemId, self.m_item_count)
    self.m_tempEquip = nil
    self.isPress = false
  end
  self:StopAllTimer()
end

function EquipIntensifyPage:_ShowProgram(equipTemp, itemId, itemCount, itemtext)
  local curLv = equipTemp.EnhanceLv
  local allExp, curExp, needExp, tempExp = 0, 0, 0, 0
  local provid_exp = self:_ProvidExp(itemId, itemCount)
  for i = 1, curLv do
    local equipExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
    allExp = allExp + equipExp
  end
  curExp = equipTemp.EnhanceExp + provid_exp - allExp
  tempExp = equipTemp.EnhanceExp + provid_exp
  local equipExp = configManager.GetDataById("config_equip_enhance_level_exp", curLv + 1).exp
  allExp = allExp + equipExp
  if allExp < equipTemp.EnhanceExp + provid_exp then
    curLv = curLv + 1
    equipTemp.EnhanceLv = curLv
    self.m_tabWidgets.tx_Lv.text = "Lv" .. Mathf.ToInt(curLv)
    self.m_tabWidgets.tx_equipLv.text = "+" .. Mathf.ToInt(curLv)
    self.m_tabWidgets.tx_equipLv.gameObject:SetActive(0 < curLv)
    self:_PlayUpLvTween()
    local isMaxLevel = false
    local equipInfo = configManager.GetDataById("config_equip", equipTemp.TemplateId)
    local renovate
    if equipTemp.Star < self.m_equipMaxStar then
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equipTemp.Star + 1)
    else
      renovate = configManager.GetDataById("config_equip_enhance_renovate", equipTemp.Star)
    end
    if curLv >= renovate.need_enhance_level and equipTemp.Star < self.m_equipMaxStar or curLv >= equipInfo.enhance_level_max then
      isMaxLevel = true
    end
    self:LoadProperty(isMaxLevel, equipTemp.TemplateId, curLv)
  end
  if equipTemp.EnhanceLv == self.m_equipMaxLv then
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", equipTemp.EnhanceLv).exp
    curExp = needExp
  else
    needExp = configManager.GetDataById("config_equip_enhance_level_exp", equipTemp.EnhanceLv + 1).exp
  end
  self.m_tabWidgets.ui_equence:Clear()
  for i, v in ipairs(self.m_tabTweenSlider) do
    v:Destroy(v)
  end
  self.m_tabTweenSlider = {}
  self:_PlayInsTween(self.m_tabWidgets, curLv, tempExp, self.m_addExp)
  self.m_lastProgress = curExp / needExp
  self.m_tabWidgets.tx_ratio.text = Mathf.ToInt(curExp) .. "/" .. needExp
  local item = Logic.bagLogic:ItemInfoById(itemId)
  local count = 0
  if item then
    count = Mathf.ToInt(item.num)
  end
  itemtext.text = Mathf.ToInt(count - itemCount)
end

function EquipIntensifyPage:LoadProperty(isMaxLevel, TemplateId, EquipLv)
  local property = Logic.equipLogic:GetCurEquipFinaAttrByLv(TemplateId, EquipLv)
  local addProperty
  if not isMaxLevel then
    addProperty = Logic.equipLogic:GetNextEquipFinaAttrByLv(TemplateId, EquipLv)
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_Attr, self.m_tabWidgets.trans_Attr, #property, function(nIndex, tabPart)
    local attr = property[nIndex]
    tabPart.tx_curname.text = attr.name
    tabPart.tx_nextname.text = attr.name
    UIHelper.SetImage(tabPart.im_curicon, attr.icon)
    UIHelper.SetImage(tabPart.im_nexticon, attr.icon)
    local txtValue
    tabPart.tx_curvalue.text = Mathf.ToInt(attr.value)
    if isMaxLevel then
      txtValue = "+" .. Mathf.ToInt(attr.value)
      UIHelper.SetTextColor(tabPart.tx_nextvalue, "(MAX)", "FF0000")
      tabPart.obj_arrow:SetActive(false)
      tabPart.tx_nextvalue.gameObject:SetActive(true)
    else
      local nextAttr = addProperty[nIndex]
      txtValue = Mathf.ToInt(nextAttr.value)
      tabPart.obj_arrow:SetActive(nextAttr.addProperty > 0)
      tabPart.tx_nextvalue.gameObject:SetActive(nextAttr.addProperty > 0)
      tabPart.tx_nextvalue.text = "(" .. "+" .. Mathf.ToInt(nextAttr.addProperty) .. ")"
    end
    tabPart.tx_nowvalue.text = txtValue
  end)
end

function EquipIntensifyPage:GetNeedMaxExp(equipExp, maxLevel)
  local allExp = 0
  local needExp = 0
  for i = 1, maxLevel do
    local tempExp = configManager.GetDataById("config_equip_enhance_level_exp", i).exp
    allExp = allExp + tempExp
  end
  needExp = allExp - equipExp
  return needExp
end

function EquipIntensifyPage:_Amend()
  local equip = Logic.equipLogic:GetEquipById(self.m_equipId)
  if self.m_equipMaxStar == Mathf.ToInt(equip.Star) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(170009))
    return
  end
  self:_Cancel()
  UIHelper.OpenPage("EquipRiseStarPage", {
    EquipId = self.m_equipId,
    FleetType = self:_GetFleetType()
  })
end

function EquipIntensifyPage:_Intensify()
  local bind = Data.equipData:GetEquipState(self.m_equipId, self:_GetFleetType()) == MEquipState.LOCK
  if not bind then
    local itemTbl, result = Logic.equipIntensifyLogic:GetExpItemTableByEquipId(self.m_equipId)
    if result then
      Logic.equipLogic:CheckEquipIntensifyAndSend(self.m_equipId, itemTbl[1].Id, itemTbl[1].Num)
    else
      local id = Logic.equipIntensifyLogic:GetExpItemIdByEquipId(self.m_equipId)
      globalNoitceManager:ShowItemInfoPage(GoodsType.EQUIP_ENHANCE_ITEM, id)
    end
  else
    if self.m_equip.EnhanceLv >= Logic.equipLogic:GetLockedEquipMaxLv() then
      noticeManager:ShowTipById(110034)
      return
    end
    local enough = true
    local costItems = configManager.GetDataById("config_equip_levelbreak_item", 1).item_cost
    for _, costItem in ipairs(costItems) do
      local haveNum = Logic.bagLogic:GetConsumeCurrNum(costItem[1], costItem[2])
      if haveNum == 0 or haveNum < costItem[3] then
        enough = false
        break
      end
    end
    if not enough then
      return
    end
    Service.equipService:SendEnhanceBind(self.m_equipId)
  end
end

function EquipIntensifyPage:_Cancel()
  UIHelper.ClosePage("EquipIntensifyPage")
end

function EquipIntensifyPage:_PlayInsTween(widgets, currentLv, currentExp, addExp)
  local preExp = currentExp - addExp
  local preLv = self:_GetPreLv(preExp)
  if currentLv < preLv then
    logError("Equip Module:preLv greater then currentLv fatel,Please check EquipIntensifyPage's _GetPreLv method")
    return
  end
  if currentLv == preLv then
    local needExp = Logic.equipLogic:GetLvExp(currentLv + 1)
    local temp = Logic.equipLogic:GetMaxExp(currentLv)
    local from = (preExp - temp) / needExp
    local to = (currentExp - temp) / needExp
    local sliderTween = self:_CreateSliderTween(widgets.slider.gameObject, 0.2, from, to)
    sliderTween:Play(true)
    return
  end
  local addLv = currentLv - preLv
  for i = 0, addLv do
    if currentLv >= self.m_equipMaxLv then
      return
    end
    if i == 0 then
      local needExp = Logic.equipLogic:GetLvExp(preLv + 1)
      local temp = Logic.equipLogic:GetMaxExp(preLv)
      local from = (preExp - temp) / needExp
      local sliderTween = self:_CreateFromTween(widgets.slider.gameObject, from)
      widgets.ui_equence:Append(sliderTween)
    elseif i == addLv then
      local needExp = Logic.equipLogic:GetLvExp(currentLv + 1)
      local temp = Logic.equipLogic:GetMaxExp(currentLv)
      local to = (currentExp - temp) / needExp
      local sliderTween = self:_CreateToTween(widgets.slider.gameObject, to)
      widgets.ui_equence:Append(sliderTween)
    else
      local sliderTween = self:_CreateNormalTween(widgets.slider.gameObject)
      widgets.ui_equence:Append(sliderTween)
    end
  end
  widgets.ui_equence:Play(true)
end

function EquipIntensifyPage:_GetPreLv(preExp)
  local preLv = Logic.equipLogic:GetLvByExp(preExp)
  return preLv
end

function EquipIntensifyPage:_CreateFromTween(go, from)
  return self:_CreateSliderTween(go, 0.2, from, 1)
end

function EquipIntensifyPage:_CreateToTween(go, to)
  return self:_CreateSliderTween(go, 0.2, 0, to)
end

function EquipIntensifyPage:_CreateNormalTween(go)
  return self:_CreateSliderTween(go, 0.2, 0, 1)
end

function EquipIntensifyPage:_CreateSliderTween(go, duration, from, to)
  local tweenSlider = TweenSlider.Add(go, duration, from, to)
  table.insert(self.m_tabTweenSlider, tweenSlider)
  return tweenSlider
end

function EquipIntensifyPage:DoOnHide()
end

function EquipIntensifyPage:DoOnClose()
  Logic.equipLogic:PoolRelease()
end

return EquipIntensifyPage
