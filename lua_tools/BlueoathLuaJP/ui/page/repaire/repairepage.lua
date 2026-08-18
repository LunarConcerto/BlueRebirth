local RepairePage = class("UI.Repair.RepairPage", LuaUIPage)

function RepairePage:DoInit()
  self.m_tabWidgets = nil
  self.isClickAll = false
  self.bUpdatePos = false
  self.bRepaireCard = false
  self.pop = nil
  self.popShip = nil
  self.m_tabHaveHero = nil
  self.repairTabpart = nil
  self.userData = nil
  self.m_tabFleetData = nil
  self.secretaryFleet = nil
  self.tabNeedRepaire = {}
  self.tabGridFleetInfo = {}
  self.tabDontDragIndex = {}
  self.m_rectTranArr = {}
  self.needAllGold = 0
  self.clickPos = 0
  self.repairPosIndex = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_GetServiceHeroInfo()
end

function RepairePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._InitRepaire, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closePage, self._ClosePage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_allRepair, self._ClickAllRepair, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_dock, self._ClickDock, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_attack, self._ClickAttack, self)
  self:RegisterEvent(LuaEvent.CloseLeftPage, self._ClosePage, self)
end

function RepairePage:_ClickDock()
  UIHelper.OpenPage("DockPage")
end

function RepairePage:_ClickAttack()
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if isHasFleet then
    UIHelper.OpenPage("CopyPage")
  else
    noticeManager:ShowMsgBox(110007)
  end
end

function RepairePage:_InitFleet()
  self.m_tabFleetData = Data.fleetData:GetFleetData()
  self.secretaryFleet = Data.userData:GetUserData().SecretaryId
end

function RepairePage:DoOnOpen()
  local param = self:GetParam()
  local showBgTrain = param and param.showBgTrain or false
  self.tab_Widgets.bgTrain:SetActive(showBgTrain)
  self:_InitFleet()
  UIHelper.SetUILock(true)
  local tweenMiddle = self.m_tabWidgets.tween_middle
  tweenMiddle:SetOnFinished(self.SetUILock)
  tweenMiddle:Play(true)
  if not showBgTrain then
    eventManager:SendEvent(LuaEvent.HomePlayTween, true)
  end
  self.userData = Data.userData:GetCurrency(1)
  UIHelper.OpenPage("CommonHeroPage", {
    self,
    CommonHeroItem.Repaire,
    self.tabNeedRepaire
  })
  self:_LoadGirdFleetCard(false)
  self.m_tabWidgets.btn_allMask:SetActive(true)
  eventManager:SendEvent(LuaEvent.HomePageOtherPageOpen, LeftOpenInde.Repaire)
  local dotinfo = {
    info = "ui_left_repair"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function RepairePage:GetFleetPos(objPos, camera)
  for i, v in ipairs(self.m_rectTranArr) do
    if v:RectangleContainsScreenPoint(objPos, camera) then
      return i
    end
  end
  return nil
end

function RepairePage:SetUILock()
  UIHelper.SetUILock(false)
end

function RepairePage:_GetServiceHeroInfo()
  self.m_tabHaveHero = Data.heroData:GetHeroData()
  self.tabNeedRepaire = Logic.repaireLogic:GetRepairShip(self.m_tabHaveHero)
end

function RepairePage:_InitRepaire()
  local haveSecretaryFleet = false
  local tabSecretaryFleet
  if self.isClickAll then
    for k, v in pairs(self.tabGridFleetInfo) do
      if v.HeroId == self.secretaryFleet then
        tabSecretaryFleet = v
        haveSecretaryFleet = true
      end
    end
    self:_LoadGirdFleetCard(true)
  else
    if self.tabGridFleetInfo[self.repairPosIndex].HeroId == self.secretaryFleet then
      tabSecretaryFleet = self.tabGridFleetInfo[self.repairPosIndex]
      haveSecretaryFleet = true
    end
    self:_LoadGirdFleetCard(true)
  end
  if haveSecretaryFleet then
    eventManager:SendEvent("changeShipGirl")
  end
  self:_GetServiceHeroInfo()
end

function RepairePage:_ClickAllRepair()
  local tabHero = {}
  local tabHeroTid = {}
  if next(self.tabGridFleetInfo) ~= nil then
    if self.userData >= self.needAllGold then
      for k, v in pairs(self.tabGridFleetInfo) do
        table.insert(tabHero, v.HeroId)
        table.insert(tabHeroTid, v.TemplateId)
      end
      self.isClickAll = true
      Service.repaireService:SendGetRepair(tabHero)
    else
      noticeManager:ShowMsgBox(110002)
    end
  else
    noticeManager:OpenTipPage(self, 360001)
  end
  local repair_name, repair_mainID = Logic.repaireLogic:ReapireRecordData(tabHeroTid)
  local countInfo = {
    time = 0,
    type = 1,
    repair_name = repair_name,
    repair_mainID = repair_mainID
  }
  RetentionHelper.Retention(PlatformDotType.service, countInfo)
end

function RepairePage:_UpdateFleet(objPos, camera)
  self:_SetFleetPos(objPos, camera)
  if self.pop ~= nil then
    GameObject.Destroy(self.pop)
    self.m_tabWidgets.obj_float:SetActive(false)
    self.pop = nil
  else
    return
  end
end

function RepairePage:_SetRepaireCardPos(objPos, pos, camera)
  local widgets = self:GetWidgets()
  if widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) and pos then
    if self.tabDontDragIndex[pos] or self.isClickAll then
      return
    elseif self.tabGridFleetInfo[pos] then
      local temInfo = self.tabGridFleetInfo[pos]
      self.tabGridFleetInfo[pos] = self.popShip
      self:_RemoveSelectShip()
      table.insert(self.tabNeedRepaire, temInfo)
    else
      self.tabGridFleetInfo[pos] = self.popShip
      self:_RemoveSelectShip()
    end
  end
end

function RepairePage:_SetGridFleetPos(objPos, pos, camera)
  local widgets = self:GetWidgets()
  if widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) and pos then
    local temp = self.tabGridFleetInfo[pos]
    self.tabGridFleetInfo[pos] = self.tabGridFleetInfo[self.clickPos]
    self.tabGridFleetInfo[self.clickPos] = temp
  else
    table.insert(self.tabNeedRepaire, self.tabGridFleetInfo[self.clickPos])
    self.tabGridFleetInfo[self.clickPos] = nil
  end
end

function RepairePage:_SetFleetPos(objPos, camera)
  local pos
  if self.bUpdatePos then
    pos = self:GetFleetPos(objPos, camera)
    if self.bRepaireCard then
      self:_SetRepaireCardPos(objPos, pos, camera)
    else
      self:_SetGridFleetPos(objPos, pos, camera)
    end
    eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
      heroTab = self.tabNeedRepaire
    })
    self:_LoadGirdFleetCard(false)
    self.needAllGold = Logic.repaireLogic:CalculateNeedAllGold(self.tabGridFleetInfo)
    self.m_tabWidgets.txt_allGold.text = math.tointeger(self.needAllGold)
    self.m_tabWidgets.btn_allMask:SetActive(self.needAllGold == 0)
  end
  self.bUpdatePos = false
end

function RepairePage:_RemoveSelectShip()
  for i = 1, #self.tabNeedRepaire do
    local ship = self.tabNeedRepaire[i]
    if ship.HeroId == self.popShip.HeroId then
      table.remove(self.tabNeedRepaire, i)
      return
    end
  end
end

function RepairePage:_SetGirdFleetInfo(tabPart, nIndex)
  tabPart.obj_Drag:SetActive(true)
  local heroId = self.tabGridFleetInfo[nIndex].HeroId
  local haveShip = Data.heroData:GetHeroById(heroId)
  if not haveShip then
    logError("heroId info nil")
    return
  end
  local heroInfo = Logic.attrLogic:GetHeroFianlAttrById(heroId)
  local curHp = Logic.shipLogic:GetHeroHp(heroId)
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroInfo[AttrType.HP])
  local shipInfo = Logic.shipLogic:GetShipInfoById(haveShip.TemplateId)
  if hpStatus >= DamageLevel.SmallDamage then
    tabPart.im_state.gameObject:SetActive(true)
    UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfo.ship_type])
    UIHelper.SetImage(tabPart.im_state, ShipBattleHpState[hpStatus])
  else
    tabPart.im_state.gameObject:SetActive(false)
  end
  UIHelper.SetImage(tabPart.im_hp, NewHpStatusImg[hpStatus + 1])
  ShipCardItem:LoadHorizontalCard(heroId, tabPart.childpart)
  local curHp = Logic.shipLogic:GetHeroHp(self.tabGridFleetInfo[nIndex].HeroId)
  tabPart.txt_hp.text = math.tointeger(curHp) .. "/" .. math.tointeger(heroInfo[AttrType.HP])
  local curHpPer = curHp / heroInfo[AttrType.HP]
  tabPart.slider_hp.value = curHpPer
  self:_UpdateGridFleetInfo(nIndex, tabPart, haveShip, curHpPer)
  tabPart.txt_name.text = shipInfo.ship_name
  tabPart.txt_lv.text = math.tointeger(self.tabGridFleetInfo[nIndex].Lvl)
  local startNum = self.tabGridFleetInfo[nIndex].Advance
  UIHelper.CreateSubPart(tabPart.obj_starItem, tabPart.trans_star, startNum, function(nIndex, part)
    part.obj_star:SetActive(true)
  end)
end

function RepairePage:_LoadGirdFleetCard(isShowEffect)
  self.m_girdFleetItem = {}
  self.m_rectTranArr = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_LoadCard, self.m_tabWidgets.trans_loadCardContent, 6, function(nIndex, tabPart)
    self.m_girdFleetItem[nIndex] = tabPart
    self.m_rectTranArr[nIndex] = tabPart.rectTranSelf
    tabPart.choose_mask:SetActive(false)
    if self.tabGridFleetInfo[nIndex] then
      self:_SetGirdFleetInfo(tabPart, nIndex)
      UGUIEventListener.AddButtonOnPointDown(tabPart.obj_repaireHero, function()
        self:_OnClickCard(tabPart, haveShip, nIndex, nil, false)
      end)
      UGUIEventListener.AddButtonOnPointUp(tabPart.obj_repaireHero, function()
        tabPart.choose_mask:SetActive(false)
        if self.pop ~= nil then
          GameObject.Destroy(self.pop)
          self.m_tabWidgets.obj_float:SetActive(false)
          self.pop = nil
        end
      end)
      self:_RepaireItemShowEffect(isShowEffect, nIndex, tabPart)
    else
      tabPart.obj_Drag:SetActive(false)
    end
  end)
end

function RepairePage:_RepaireItemShowEffect(isShowEffect, nIndex, tabPart)
  if isShowEffect then
    local heroId = self.tabGridFleetInfo[nIndex].HeroId
    local heroInfo = Logic.attrLogic:GetHeroFianlAttrById(heroId)
    if nIndex == self.repairPosIndex and not self.isClickAll then
      self:_RepaireOneAndShowEffect(tabPart, nIndex, heroInfo)
    end
    if self.isClickAll then
      self:_ClickRepaireAllAndShowEffect(tabPart, heroInfo)
    end
  end
end

function RepairePage:_RepaireOneAndShowEffect(tabPart, nIndex, heroInfo)
  tabPart.txt_gold.text = 0
  tabPart.slider_hp.value = 1
  tabPart.effect_repaire.gameObject:SetActive(false)
  tabPart.txt_hp.text = math.tointeger(heroInfo[AttrType.HP]) .. "/" .. math.tointeger(heroInfo[AttrType.HP])
  UIHelper.SetImage(tabPart.im_hp, NewHpStatusImg[1])
  tabPart.obj_mask:SetActive(true)
  self.tabDontDragIndex[nIndex] = self.repairPosIndex
  self.tabGridFleetInfo[self.repairPosIndex] = nil
  self:_GetCoinNum(self.tabGridFleetInfo)
  self:_GetEffectCallBack(nIndex, tabPart)
end

function RepairePage:_ClickRepaireAllAndShowEffect(tabPart, heroInfo)
  tabPart.txt_gold.text = 0
  tabPart.effect_repaire.gameObject:SetActive(false)
  tabPart.obj_mask:SetActive(true)
  tabPart.slider_hp.value = 1
  tabPart.txt_hp.text = math.tointeger(heroInfo[AttrType.HP]) .. "/" .. math.tointeger(heroInfo[AttrType.HP])
  UIHelper.SetImage(tabPart.im_hp, NewHpStatusImg[1])
  self.tabDontDragIndex = self.tabGridFleetInfo
  self.m_tabWidgets.txt_allGold.text = 0
  self.m_tabWidgets.btn_allMask:SetActive(true)
  tabPart.effect_repaire.gameObject:SetActive(false)
  tabPart.obj_mask:SetActive(false)
  self.tabGridFleetInfo = {}
  self.tabDontDragIndex = {}
  self.isClickAll = false
  self:_LoadGirdFleetCard(false)
end

function RepairePage:_GetEffectCallBack(nIndex, tabPart)
  tabPart.obj_mask:SetActive(false)
  tabPart.effect_repaire.gameObject:SetActive(false)
  tabPart.obj_repaireHero:SetActive(false)
  self.tabGridFleetInfo[self.repairPosIndex] = nil
  self:_LoadGirdFleetCard(false)
  self.tabDontDragIndex[nIndex] = nil
  self.isClickAll = false
end

function RepairePage:_GetCoinNum(tabGridFleetInfo)
  self.m_tabWidgets.txt_allGold.text = math.tointeger(Logic.repaireLogic:CalculateNeedAllGold(tabGridFleetInfo))
  local shipNum = Logic.repaireLogic:GridLength(tabGridFleetInfo)
  if shipNum == 0 then
    self.m_tabWidgets.txt_allGold.text = 0
    self.m_tabWidgets.btn_allMask:SetActive(true)
  end
end

function RepairePage:_UpdateGridFleetInfo(nIndex, tabPart, haveShip, curHpPer)
  local tabConfig = configManager.GetDataById("config_ship_main", haveShip.TemplateId)
  local needGold = tabConfig.fixed_money * (1 - curHpPer)
  if needGold % 1 ~= 0 then
    needGold = needGold - needGold % 1 + 1
  end
  tabPart.txt_gold.text = math.tointeger(needGold)
  self.needAllGold = Logic.repaireLogic:CalculateNeedAllGold(self.tabGridFleetInfo)
  self.m_tabWidgets.txt_allGold.text = math.tointeger(self.needAllGold)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_repaire, function()
    local tabHero = {}
    local tabHeroTid = {}
    if self.userData >= needGold then
      self.repairPosIndex = nIndex
      self.repairTabpart = tabPart
      table.insert(tabHero, self.tabGridFleetInfo[nIndex].HeroId)
      table.insert(tabHeroTid, self.tabGridFleetInfo[nIndex].TemplateId)
      self.isClickAll = false
      Service.repaireService:SendGetRepair(tabHero)
    else
      noticeManager:ShowMsgBox(110002)
    end
    local repair_name, repair_mainID = Logic.repaireLogic:ReapireRecordData(tabHeroTid)
    local countInfo = {
      time = 0,
      type = 1,
      repair_name = repair_name,
      repair_mainID = repair_mainID
    }
    RetentionHelper.Retention(PlatformDotType.service, countInfo)
  end)
end

function RepairePage:_OnClickCard(tabPart, shipInfo, clickIndex, originObj, isFleetCard)
  self.clickPos = clickIndex
  self.popShip = shipInfo
  self.bRepaireCard = isFleetCard
  local obj = tabPart.objSelf
  self.m_tabWidgets.obj_float:SetActive(true)
  self.pop = UIHelper.CreateGameObject(tabPart.gameObject, self.m_tabWidgets.tran_float)
  self.m_tabWidgets.tran_float.position = obj.transform.position
  self.pop.transform.pivot = Vector2.New(0.5, 0.5)
  self.pop.transform.position = Vector3.New(obj.transform.position.x - 10, obj.transform.position.y - 10, 0)
  if not originObj then
    tabPart.choose_mask:SetActive(true)
    self:AddCardDrag(obj, self.pop.transform)
  end
  self.bUpdatePos = true
end

function RepairePage:AddCardDrag(objDrag, dragTran)
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    dragTran.position = worldPos
    self:_DragCard(dragPos, camera)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    local camera = eventData.pressEventCamera
    local finalPos = eventData.position
    self:_UpdateFleet(finalPos, camera)
  end, nil, nil)
end

function RepairePage:_DragCard(objPos, camera)
  local widgets = self:GetWidgets()
  local pos = self:GetFleetPos(objPos, camera)
  if self.lastPos and self.lastPos ~= pos and self.clickPos ~= self.lastPos then
    local item = self.m_girdFleetItem[self.lastPos]
    item.choose_mask:SetActive(false)
    self.lastPos = nil
  end
  if widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) and pos then
    local item = self.m_girdFleetItem[pos]
    item.choose_mask:SetActive(true)
    self.lastPos = pos
  elseif self.lastPos then
    local item = self.m_girdFleetItem[self.lastPos]
    item.choose_mask:SetActive(false)
    self.lastPos = nil
  end
end

function RepairePage:_ClickClose()
  UIHelper.SetUILock(true)
  local tweenMiddle = self.m_tabWidgets.tween_middle
  tweenMiddle:SetOnFinished(self._ClosePage)
  eventManager:SendEvent(LuaEvent.CommonHeroClose)
  tweenMiddle:Play(false)
end

function RepairePage:_ClosePage()
  eventManager:SendEvent(LuaEvent.HomePageOtherPageClose)
  UIHelper.ClosePage("RepairePage")
  UIHelper.ClosePage("CommonHeroPage")
end

function RepairePage:DoOnHide()
end

function RepairePage:DoOnClose()
  UIHelper.SetUILock(false)
end

function RepairePage:OnDragHeroCard(tabPart, shipInfo, clickIndex, isFleetCard, eventData)
  self.popShip = shipInfo
  self.m_clickPos = clickIndex
  self.bRepaireCard = isFleetCard
  local delta = eventData.delta
  if self.pop == nil and delta.y > 10 and delta.x < 3 and delta.x > -3 then
    self.m_tabWidgets.obj_float:SetActive(true)
    local widgets = self:GetWidgets()
    self.pop = UIHelper.CreateGameObject(tabPart.gameObject, self.m_tabWidgets.tran_float)
    self.pop.transform.pivot = Vector2.New(0.5, 0.5)
    tabPart.fixDrag:StopMove()
  end
  if self.pop then
    tabPart.fixDrag:OnEndDrag(eventData)
    tabPart.fixDrag.bEnable = false
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    self.pop.transform.position = finalPos
    self:_DragCard(dragPos, camera)
    tabPart.objGolden:SetActive(true)
    tabPart.objMask:SetActive(true)
  end
  self.bUpdatePos = true
end

function RepairePage:OnEndDrag(eventData, fixDrag)
  self.m_tabWidgets.obj_float:SetActive(false)
  GameObject.Destroy(self.pop)
  self.pop = nil
  local camera = eventData.pressEventCamera
  local finalPos = eventData.position
  self:_UpdateFleet(finalPos, camera)
  local fix = fixDrag
  fix:OnEndDrag(eventData)
  fix.bEnable = true
end

return RepairePage
