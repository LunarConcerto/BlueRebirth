local DockPage = class("UI.Dock.DockPage", LuaUIPage)
SHOWPROPNUM = 5
SHIPPERROW = 6

function DockPage:DoInit()
  self.m_tabWidgets = nil
  self.sortway = true
  self.m_tabInParams = {}
  self.m_tabOutParams = {}
  self.m_tabShowHero = {}
  self.m_tabHaveHero = {}
  self.m_showPropIndex = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function DockPage:DoOnOpen()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  local shipTotal = Logic.shipLogic:GetBaseShipNum()
  self.m_tabHaveHero = Data.heroData:GetHeroData()
  self:_GetButtonData()
  self:_CtrlTogDis(self.m_showPropIndex)
  self:_ShowSortWay(self.sortway)
  self.m_tabWidgets.txt_sortway.text = HeroSortHelper.GetSortName(self.m_tabOutParams[2])
  self.m_tabShowHero = HeroSortHelper.FilterAndSort1(self.m_tabHaveHero, self.m_tabOutParams[1], self.m_tabOutParams[2], self.sortway)
  self:_SetShipNum(#self.m_tabShowHero)
  self.m_indexMax = Logic.dockLogic:CalculatePropIndex(self.m_tabHaveHero[1], SHOWPROPNUM) + 1
  self:_LoadShipItem(self.m_tabShowHero, self.m_showPropIndex)
  self:OpenTopPage("DockPage", 1, "\232\136\185\229\157\158", self, true)
  local dotinfo = {
    info = "ui_shipyard",
    type = "main_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  eventManager:SendEvent(LuaEvent.TopAddItem, {isShow = false, CurrencyInfo = nil})
end

function DockPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_sortway, self._OpenSortPage, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_property, self._ShowProp, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_sort, self._SortOrder, self)
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_retire, self._OpenRetirePage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_handbook, self._OpenPicturePage, self)
end

function DockPage:_OpenRetirePage()
  UIHelper.OpenPage("HeroRetirePage")
end

function DockPage:_OpenPicturePage()
  Data.illustrateData:ResetHaveNew()
  UIHelper.OpenPage("PicturePage")
end

function DockPage:_SetShipNum(curNum)
  local total = Logic.shipLogic:GetBaseShipNum()
  local isUp = curNum >= total
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.txt_cardTotal, "/" .. total)
  if isUp then
    widgets.txt_cardValue.text = curNum
    widgets.txt_cardValue.color = Color.New(1.0, 0 / 255, 0 / 255, 1)
  else
    widgets.txt_cardValue.color = Color.New(1.0, 1.0, 1.0, 1)
    UIHelper.SetText(widgets.txt_cardValue, curNum)
  end
end

function DockPage:_UpdateHeroSort(tabSortParams)
  self.m_tabInParams = tabSortParams
  self.m_tabOutParams = self.m_tabInParams
  self.m_tabShowHero = HeroSortHelper.FilterAndSort1(self.m_tabHaveHero, tabSortParams[1], tabSortParams[2], self.sortway)
  self:_SetShipNum(#self.m_tabShowHero)
  self.m_tabWidgets.txt_sortway.text = HeroSortHelper.GetSortName(tabSortParams[2])
  self:_LoadShipItem(self.m_tabShowHero, self.m_showPropIndex)
end

function DockPage:_OpenSortPage()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  UIHelper.OpenPage("SortPage", self.m_tabOutParams)
end

function DockPage:_ShowProp()
  self.m_showPropIndex = self.m_showPropIndex + 1
  if self.m_showPropIndex > self.m_indexMax then
    self.m_showPropIndex = 0
  end
  self:_CtrlTogDis(self.m_showPropIndex)
  self:_LoadShipItem(self.m_tabShowHero, self.m_showPropIndex)
end

function DockPage:_CtrlTogDis(index)
  if 0 < index then
    self.m_tabWidgets.tog_property.isOn = true
    self.m_tabWidgets.obj_on:SetActive(true)
    self.m_tabWidgets.obj_off:SetActive(false)
  else
    self.m_tabWidgets.tog_property.isOn = false
    self.m_tabWidgets.obj_on:SetActive(false)
    self.m_tabWidgets.obj_off:SetActive(true)
  end
end

function DockPage:_SortOrder()
  if self.m_tabWidgets.tog_sort.isOn then
    self.sortway = true
    self.m_tabWidgets.txt_sort.text = "\233\153\141\229\186\143"
  else
    self.sortway = false
    self.m_tabWidgets.txt_sort.text = "\229\141\135\229\186\143"
  end
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  self.m_tabShowHero = HeroSortHelper.FilterAndSort1(self.m_tabShowHero, self.m_tabOutParams[1], self.m_tabOutParams[2], self.sortway)
  self:_LoadShipItem(self.m_tabShowHero, self.m_showPropIndex)
end

function DockPage:_ShowSortWay(sortway)
  if sortway then
    self.m_tabWidgets.txt_sort.text = "\233\153\141\229\186\143"
    self.m_tabWidgets.tog_sort.isOn = true
  else
    self.m_tabWidgets.txt_sort.text = "\229\141\135\229\186\143"
    self.m_tabWidgets.tog_sort.isOn = false
  end
end

function DockPage:_ShowGirlInfo(param)
  Logic.shipLogic:ClearNewReward(param)
  local heros = {}
  for k, v in ipairs(self.m_tabShowHero) do
    table.insert(heros, v.HeroId)
  end
  UIHelper.OpenPage("GirlInfo", {
    param,
    heros,
    AnimojiEnter.CanEnter
  })
end

function DockPage:_SetButtonData()
  local tabSelectData = {}
  tabSelectData[1] = self.m_showPropIndex
  tabSelectData[2] = self.sortway
  tabSelectData[3] = self.m_tabOutParams
  Logic.dockLogic:SetSelectData(tabSelectData)
end

function DockPage:_GetButtonData()
  local tabSelectData = Logic.dockLogic:GetSelectData()
  self.m_showPropIndex = tabSelectData[1]
  self.sortway = tabSelectData[2]
  self.m_tabOutParams = tabSelectData[3]
end

function DockPage:_CreateSubProp(HeroId, obj, trans, index)
  if index <= 0 then
    return
  end
  local temp = Logic.attrLogic:GetHeroFinalShowAttrById(HeroId)
  local tabTemp = Logic.attrLogic:DealTabPropDock(temp, HeroId)
  local div = #tabTemp / SHOWPROPNUM
  local divCeil = math.ceil(div)
  local loadNum = 0
  if #tabTemp > SHOWPROPNUM then
    local mod = #tabTemp % SHOWPROPNUM
    if div >= self.m_showPropIndex and self.m_showPropIndex ~= 0 then
      loadNum = SHOWPROPNUM
    else
      loadNum = mod
    end
  else
    loadNum = #tabTemp
  end
  UIHelper.CreateSubPart(obj, trans, loadNum, function(nIndex, tabPart)
    local indexNow = math.min(index, divCeil)
    local indexNew = nIndex + (indexNow - 1) * SHOWPROPNUM
    local attrInfo = tabTemp[indexNew]
    local name = Logic.attrLogic:GetName(attrInfo.type, Data.heroData:GetHeroById(HeroId).TemplateId)
    tabPart.Tx_num.text = attrInfo.num
    tabPart.Tx_prop.text = name
  end)
end

function DockPage:_CreateSkill(heroId, obj, trans)
  local skillArr = Logic.shipLogic:GetAllPSkillArrbyShipMainId(Data.heroData:GetHeroById(heroId).TemplateId)
  UIHelper.CreateSubPart(obj, trans, #skillArr, function(nIndex, tabPart)
    local skillId = skillArr[nIndex]
    local skillIdReal = skillId
    if type(skillId) == "table" then
      skillIdReal = skillId[1]
    end
    local name = Logic.shipLogic:GetPSkillName(skillId)
    local level = Logic.shipLogic:GetHeroPSkillLv(heroId, skillIdReal)
    local levelMax = Logic.shipLogic:GetPSkillLvMax(skillIdReal)
    tabPart.text_name.text = name
    if level >= levelMax then
      UIHelper.SetLocText(tabPart.text_level, 160022, "max")
    else
      UIHelper.SetLocText(tabPart.text_level, 160022, level)
    end
  end)
end

function DockPage:_LoadShipItem(shipTab, index)
  self.marriageEffectList = {}
  self:StopMarriageTimer()
  local tabFleetInfo = Logic.fleetLogic:GetHeroFleetMap()
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_girlsv, self.m_tabWidgets.obj_girlItem, #shipTab, function(tabPart)
    for nIndex, luaPart in pairs(tabPart) do
      nIndex = tonumber(nIndex)
      luaPart.Tx_num.text = math.tointeger(shipTab[nIndex].Lvl)
      for i = 1, shipTab[nIndex].Advance do
        local stri = tostring(i)
        luaPart[stri]:SetActive(true)
      end
      luaPart.im_lock.gameObject:SetActive(shipTab[nIndex].Lock)
      if shipTab[nIndex].Lock then
        UIHelper.SetImage(luaPart.im_lock, LockShip[shipTab[nIndex].Lock], true)
      end
      UIHelper.SetStar(luaPart.obj_star, luaPart.trans_starBase, shipTab[nIndex].Advance)
      ShipCardItem:LoadVerticalCard(shipTab[nIndex].HeroId, luaPart.childpart, nil, function()
        table.insert(self.marriageEffectList, luaPart.tex_anim1)
        table.insert(self.marriageEffectList, luaPart.tex_anim2)
        table.insert(self.marriageEffectList, luaPart.tex_anim3)
      end)
      UGUIEventListener.AddButtonOnClick(luaPart.Btn_item, function()
        self:_ShowGirlInfo(shipTab[nIndex].HeroId)
      end)
      local showTip = Logic.shipLogic:IsInFleet(shipTab[nIndex].HeroId)
      luaPart.Obj_fleetBg:SetActive(showTip)
      if Logic.shipLogic:IsNewShip(shipTab[nIndex].HeroId) then
        UIHelper.SetText(luaPart.Te_fleet, "NEW")
      end
      UIHelper.SetText(luaPart.tx_heroId, "heroId" .. shipTab[nIndex].HeroId)
      if Logic.shipLogic:IsInFleet(shipTab[nIndex].HeroId) then
        local fleetName = Logic.fleetLogic:GetHeroFleetName(shipTab[nIndex].HeroId)
        UIHelper.SetText(luaPart.Te_fleet, fleetName)
        local heroId = shipTab[nIndex].HeroId
        self:RegisterRedDot(luaPart.redDot, heroId)
      else
        luaPart.redDot.gameObject:SetActive(false)
      end
      luaPart.obj_support:SetActive(Logic.shipLogic:IsInCrusade(shipTab[nIndex].HeroId))
      luaPart.Obj_propbg:SetActive(0 < index and index < self.m_indexMax)
      luaPart.Obj_propMask:SetActive(0 < index)
      luaPart.trans_skill.gameObject:SetActive(index == self.m_indexMax)
      if 0 < index and index < self.m_indexMax then
        self:_CreateSubProp(shipTab[nIndex].HeroId, luaPart.Obj_prop, luaPart.trans_propbg, index)
      elseif index == self.m_indexMax then
        self:_CreateSkill(shipTab[nIndex].HeroId, luaPart.obj_skill, luaPart.trans_skill, index)
      end
      local showRemould = Logic.remouldLogic:CkeckHeroRemouldOpen(shipTab[nIndex].HeroId)
      local remouldLvMax = Logic.remouldLogic:CkeckHeroRemouldMax(shipTab[nIndex].HeroId)
      luaPart.im_remould.gameObject:SetActive(showRemould and not remouldLvMax)
      if showRemould then
        local remoulding = Logic.remouldLogic:CkeckHeroRemoulding(shipTab[nIndex].HeroId)
        local imgRemould = remoulding and "uipic_ui_gaizao_im_gaozaozhong" or "uipic_ui_gaizao_im_kegaizao"
        UIHelper.SetImage(luaPart.im_remould, imgRemould)
      end
    end
    local count = #self.marriageEffectList
    if 0 < count then
      self:PlayMarriageEffect()
    else
      self:StopMarriageTimer()
    end
  end)
end

function DockPage:PlayMarriageEffect(effectList, count)
  if not self.marriageTimer then
    local enableTime = 0.3
    local disableTime = 3.3
    local finishTime = 6.5
    local curTime = 0
    local preTime = 0
    local func = function(deltaTime)
      if curTime < enableTime and curTime + deltaTime > enableTime then
        curTime = curTime + deltaTime
        self:SetEffectEnabled(self.marriageEffectList, #self.marriageEffectList, true)
      end
      if curTime < disableTime and curTime + deltaTime > disableTime then
        curTime = curTime + deltaTime
        self:SetEffectEnabled(self.marriageEffectList, #self.marriageEffectList, false)
      end
      if curTime < finishTime and curTime + deltaTime > finishTime then
        curTime = 0
      else
        curTime = curTime + deltaTime
      end
    end
    self.marriageTimer = CustomTimer.New(func, total, -1)
    self.marriageTimer:Start()
  end
end

function DockPage:SetEffectEnabled(effectList, count, enabled)
  for i = 1, count, 3 do
    effectList[i]:SetActive(enabled)
    effectList[i + 1]:SetActive(enabled)
    effectList[i + 2]:SetActive(enabled)
  end
end

function DockPage:StopMarriageTimer()
  if self.marriageTimer then
    self.marriageEffectList = {}
    self.marriageTimer:Stop()
    self.marriageTimer = nil
  end
end

function DockPage:DoOnHide()
  self:_SetButtonData()
  self:StopMarriageTimer()
end

function DockPage:DoOnClose()
  self:_SetButtonData()
  Logic.equipLogic:RmEquipByHeroId()
  Data.heroData:ClearRecord()
  self:StopMarriageTimer()
end

return DockPage
