local FleetOrderPage = class("UI.Activity.FleetOrderPage", LuaUIPage)

function FleetOrderPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.m_fleetType = FleetType.Normal
  self.nCopyId = 0
  self.m_displayConfig = nil
  self.m_fleetTranArr = {}
  self.m_fleetItem = {}
  self.lastPos = 0
  self.oriPos = 0
end

function FleetOrderPage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.nCopyId = params.copyId
  self.m_displayConfig = Logic.copyLogic:GetCopyDesConfig(self.nCopyId)
  Logic.fleetOrderLogic:ResetData()
  self:_ShowPage()
end

function FleetOrderPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.SetFleetMsg, self._ShowPage, self)
  self:RegisterEvent(LuaEvent.FleetOrderChange, self._ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickOk, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCancel, self)
end

function FleetOrderPage:_ShowPage()
  local widgets = self.tab_Widgets
  local max_fleet = self.m_displayConfig.max_fleet
  local fleetList = Logic.fleetOrderLogic:GetOrderFleets()
  local exp_up = Logic.fleetOrderLogic:GetExpUpMap(self.nCopyId)
  UIHelper.CreateSubPart(widgets.fleet, widgets.Content, #fleetList, function(index, tabPart)
    local fleet_info = fleetList[index]
    UIHelper.SetText(tabPart.tx_name, fleet_info.tacticName)
    local strategyId = fleet_info.strategyId
    if strategyId and 0 < strategyId then
      local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
      UIHelper.SetText(tabPart.tx_strategy, strategyConfig.strategy_name)
    else
      UIHelper.SetText(tabPart.tx_strategy, UIHelper.GetString(980011))
    end
    local totalAttack = 0
    local heroList = clone(fleet_info.heroInfo)
    UIHelper.CreateSubPart(tabPart.obj_shipslot, tabPart.rect_shipslot, #heroList, function(nIndex, luaPart)
      local heroId = heroList[nIndex]
      local heroData = Data.heroData:GetHeroById(heroId)
      if heroId ~= nil then
        if npcAssistFleetMgr:IsNpcHeroId(heroId) then
          totalAttack = totalAttack + heroData.BattlePower
        else
          local heroAttr = Logic.attrLogic:GetBattlePower(heroId, fleet_info.type, self.nCopyId)
          totalAttack = totalAttack + heroAttr
        end
      end
      luaPart.exp_up.gameObject:SetActive(exp_up[heroId] == true)
      self:_SetFleetBasicInfoNew(heroId, luaPart, fleet_info.type)
    end)
    UIHelper.SetText(tabPart.tx_effectiveness, totalAttack)
    local canChangePos = true
    local isSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(index, fleet_info.type)
    canChangePos = not isSweeping
    if canChangePos == true then
      self.m_fleetTranArr[index] = tabPart
      self:_SetFleetDrag(tabPart, index)
    else
      self:_SetFleetClick(tabPart, index)
    end
    tabPart.obj_autobattle:SetActive(isSweeping)
    tabPart.im_NvNMask:SetActive(0 < max_fleet and index > max_fleet)
  end)
end

function FleetOrderPage:GetSubmarineStrategy(exHeroList)
  local heroId = exHeroList[1]
  if heroId then
    local sm_id = Data.heroData:GetHeroById(heroId).TemplateId
    local pskillArr = Logic.shipLogic:GetAllPSkillArrbyShipMainId(sm_id)
    for _, pskillId in ipairs(pskillArr) do
      local showSkillId = Logic.shipLogic:GetReplaceSkillId(pskillId, heroId)
      if type(pskillId) ~= "table" then
        local id = Logic.shipLogic:GetPSkillDisplayIdByGroupId(showSkillId)
        local cfg = configManager.GetDataById("config_pskill_dict_display", id)
        if cfg.flag_skill == 1 then
          return cfg.skill_name
        end
      end
    end
    return ""
  else
    return ""
  end
end

function FleetOrderPage:_SetFleetBasicInfoNew(heroId, tabPart, m_fleetType)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local totalHp = Logic.shipLogic:GetHeroMaxHp(heroId, m_fleetType)
  local curHp = Logic.shipLogic:GetHeroHp(heroId, m_fleetType)
  local isAssist = npcAssistFleetMgr:IsNpcHeroId(heroId)
  tabPart.assist_tag:SetActive(isAssist)
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, totalHp)
  UIHelper.SetImage(tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
  UIHelper.SetStar(tabPart.obj_star, tabPart.trans_star, heroInfo.Advance)
  ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart, VerCardType.Icon5, nil, m_fleetType)
  tabPart.slider.value = curHp / totalHp
  tabPart.textLv.text = Mathf.ToInt(heroInfo.Lvl)
end

function FleetOrderPage:_ClickOk()
  Logic.fleetOrderLogic:SendSetFleetsOrder()
  UIHelper.ClosePage(self:GetName())
end

function FleetOrderPage:_ClickCancel()
  UIHelper.ClosePage(self:GetName())
end

function FleetOrderPage:_SetFleetDrag(tabPart, oriIndex)
  local param = {OriIndex = oriIndex}
  UGUIEventListener.AddButtonOnPointDown(tabPart.obj_fleet, function()
    self:OnDrag(tabPart, param)
  end)
  UGUIEventListener.AddButtonOnPointUp(tabPart.obj_fleet, function()
    if self.m_popObj ~= nil then
      self.tab_Widgets.obj_float:SetActive(false)
    end
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.obj_fleet, function()
  end)
end

function FleetOrderPage:OnDrag(tabPart, param)
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
  end
  self.tab_Widgets.obj_float:SetActive(true)
  self.m_popObj = UIHelper.CreateGameObject(tabPart.obj_fleet, self.tab_Widgets.obj_float.transform)
  self.tab_Widgets.obj_float.transform.position = tabPart.obj_fleet.transform.position
  self.m_popObj.transform.pivot = Vector2.New(0.5, 0.5)
  self.m_popObj.transform.position = Vector3.New(tabPart.obj_fleet.transform.position.x - 10, tabPart.obj_fleet.transform.position.y - 10, 0)
  self:_AddFleetDrag(tabPart.obj_fleet, self.m_popObj.transform, param)
end

function FleetOrderPage:_AddFleetDrag(objDrag, dragTran, param)
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if self.m_popObj == nil then
      return
    end
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    dragTran.position = worldPos
    self:_DragFleet(dragPos, camera, param)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    UGUIEventListener.ClearDragListener(objDrag)
    local camera = eventData.pressEventCamera
    local dragPos = eventData.position
    self:_UpdateFleets(dragPos, camera, param)
  end, nil, nil)
end

function FleetOrderPage:_DragFleet(objPos, camera, param)
  local pos = self:_GetFleetPos(objPos, camera)
  local oriPos = param.OriIndex
  if pos == nil then
    for index, part in pairs(self.m_fleetTranArr) do
      if index ~= self.lastPos and index ~= oriPos then
        part.im_xuanzhong:SetActive(false)
      end
    end
  else
    for index, part in pairs(self.m_fleetTranArr) do
      if index ~= pos and index ~= oriPos then
        part.im_xuanzhong:SetActive(false)
      else
        part.im_xuanzhong:SetActive(true)
        self.lastPos = pos
      end
    end
  end
end

function FleetOrderPage:_UpdateFleets(objPos, camera, param)
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    self.tab_Widgets.obj_float:SetActive(false)
    self.m_popObj = nil
  end
  for _, part in pairs(self.m_fleetTranArr) do
    part.im_xuanzhong:SetActive(false)
  end
  local pos = self:_GetFleetPos(objPos, camera)
  if pos == nil then
    if self.lastPos > 0 then
      Logic.fleetOrderLogic:SetFleetsOrder(self.lastPos, param.OriIndex)
    end
  else
    Logic.fleetOrderLogic:SetFleetsOrder(pos, param.OriIndex)
  end
end

function FleetOrderPage:_GetFleetPos(objPos, camera)
  for i, v in pairs(self.m_fleetTranArr) do
    if v.rectTranSelf:RectangleContainsScreenPoint(objPos, camera) then
      return i
    end
  end
  return nil
end

function FleetOrderPage:_SetFleetClick(tabPart)
  UGUIEventListener.AddButtonOnPointDown(tabPart.rect_drag, function()
  end)
  UGUIEventListener.AddButtonOnPointUp(tabPart.rect_drag, function()
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.rect_drag, function()
  end)
end

function FleetOrderPage:DoOnClose()
end

return FleetOrderPage
