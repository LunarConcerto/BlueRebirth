local PlayerHeadFramePage = class("ui.page.PlayerHeadFramePage", LuaUIPage)

function PlayerHeadFramePage:DoInit()
  self.m_curHeadFrame = 0
  self.m_allHeadFrameList = {}
  self.m_ownedHeadFrameList = {}
  self.m_userInfo = {}
  self.headFrameIndex = 1
  self.selectType = 0
  self.m_allShipCfg = {}
  self.sortway = true
  self.tabParts = {}
  self.m_tabInParams = {}
  self.m_tabOutParams = {}
  self.shipSelect = 1
  self.tabHeadParts = {}
  self.headSelect = 1
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function PlayerHeadFramePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseHFPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self._ClickConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_BtnBuy, self.ClickBuyBtn, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_HELP, self.ClickHelpBtn, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_Check, self.ClickCheckBtn, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_BtnSort, self.ClickSortBtn, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tg_Content, self, nil, self.SwitchToggle)
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self.UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.UpdateShipHeadBuy, self.ShipHeadBuySuccess, self)
  self:RegisterEvent(LuaEvent.UpdateShipHeadUnlock, self.ShipHeadUnlock, self)
end

function PlayerHeadFramePage:DoOnOpen()
  self.m_curHeadFrame, _ = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  self.m_allHeadFrameList = Data.playerHeadFrameData:GetAllHeadFrameData()
  self.m_ownedHeadFrameList = Data.playerHeadFrameData:GetOwnedHeadFrameData()
  self.m_allShipCfg = Logic.headLogic:GetAllShipCfg()
  self.userInfo = Data.userData:GetUserData()
  self:SwitchToggle(self.selectType)
  self:CheckAllHeadRedData()
end

function PlayerHeadFramePage:DoReset()
  self.selectType = 0
  self.headFrameIndex = 1
  self.shipSelect = 1
  self.headSelect = 1
end

function PlayerHeadFramePage:_RefreshView()
  self:_ShowHeadFrameList()
  self:_ShowHeadFrameDetail()
  self.tab_Widgets.obj_framedetail:SetActive(true)
  self.tab_Widgets.btn_confirm.gameObject:SetActive(true)
  self.tab_Widgets.btn_Check.gameObject:SetActive(false)
  self.tab_Widgets.btn_BtnSort.gameObject:SetActive(false)
  local contentStr = UIHelper.GetString(3600000)
  UIHelper.SetText(self.tab_Widgets.txt_title, contentStr)
end

function PlayerHeadFramePage:_ShowHeadFrameList()
  local allFrameList = self:_MakeAllHeadFrame()
  local ownedFrameList = self.m_ownedHeadFrameList
  local curHeadId = Data.userData:GetUserHead()
  local isMarry = Logic.playerHeadFrameLogic:IsSecretaryMarried(curHeadId)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_frameItem, self.tab_Widgets.rect_Content, #allFrameList, function(index, tabPart)
    local index = allFrameList[index].id
    tabPart.img_select:SetActive(self.headFrameIndex == index)
    tabPart.img_icon.gameObject:SetActive(true)
    tabPart.img_quality.gameObject:SetActive(true)
    tabPart.img_SelectItem:SetActive(false)
    tabPart.btn_Back.gameObject:SetActive(false)
    tabPart.img_New.gameObject:SetActive(false)
    tabPart.txt_name.gameObject:SetActive(false)
    tabPart.img_equip.gameObject:SetActive(index == self.m_curHeadFrame)
    local frameInfo = self.m_allHeadFrameList[index]
    if frameInfo == nil then
      tabPart.btn_frameItem.gameObject:SetActive(false)
    else
      local icon, qualityIcon = Data.userData:GetUserHeadIcon(self.userInfo)
      UIHelper.SetImage(tabPart.img_quality, qualityIcon)
      UIHelper.SetImage(tabPart.img_icon, icon)
      local frameImg = frameInfo.icon
      UIHelper.SetImage(tabPart.img_frame, frameImg)
      if index == InitialHeadFrame.Marry then
        tabPart.img_lock.gameObject:SetActive(not isMarry)
      else
        tabPart.img_lock.gameObject:SetActive(ownedFrameList[index] == nil)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_frameItem, self._SelectHFItem, self, {id = index})
    end
  end)
end

function PlayerHeadFramePage:_ShowHeadFrameDetail()
  local curId = self.headFrameIndex
  local widgets = self:GetWidgets()
  widgets.btn_BtnBuy.gameObject:SetActive(false)
  widgets.obj_Cost:SetActive(false)
  local config = configManager.GetDataById("config_profile", self.userInfo.Head)
  if config then
    UIHelper.SetImage(widgets.img_quality, UserHeadQualityImg[ShipHeadQuality])
    UIHelper.SetImage(widgets.img_icon, config.image)
  end
  local frameInfo = self.m_allHeadFrameList[curId]
  local curHeadId = Data.userData:GetUserHead()
  UIHelper.SetImage(widgets.img_frame, frameInfo.icon)
  UIHelper.SetText(widgets.txt_name, frameInfo.name)
  UIHelper.SetText(widgets.txt_framedesc, frameInfo.description)
  widgets.im_lock:SetActive(self.m_ownedHeadFrameList[curId] == nil)
  widgets.txt_limit.gameObject:SetActive(self.m_ownedHeadFrameList[curId] == nil)
  if self.m_ownedHeadFrameList[curId] == nil then
    UIHelper.SetText(widgets.txt_limit, UIHelper.GetString(290013))
  end
end

function PlayerHeadFramePage:_CloseHFPage()
  self:DoReset()
  UIHelper.ClosePage("PlayerHeadFramePage")
end

function PlayerHeadFramePage:_ClickConfirm()
  if self.selectType == ShipHeadSelect.HeadFrame then
    local selectedId = self.headFrameIndex
    local isOwned = self.m_ownedHeadFrameList[selectedId]
    if not isOwned then
      noticeManager:ShowTip(UIHelper.GetString(290011))
      return
    end
    if selectedId == InitialHeadFrame.Marry then
      local curHeadId = Data.userData:GetUserHead()
      local isMarry = Logic.playerHeadFrameLogic:IsSecretaryMarried(curHeadId)
      if not isMarry then
        noticeManager:ShowTip(UIHelper.GetString(3600011))
        return
      end
    end
    local argTab = {headFrameId = selectedId}
    Service.userService:SetPlayerHeadFrame(argTab)
    noticeManager:ShowTip(UIHelper.GetString(290012))
    self:_CloseHFPage()
  elseif self.selectType == ShipHeadSelect.HeadDetails then
    local heroInfo = self.m_tabSortHero[self.shipSelect]
    if heroInfo.IllustrateState ~= IllustrateState.UNLOCK then
      noticeManager:ShowTip(UIHelper.GetString(3600005))
      return
    end
    local profileCfg = self.shipHeadList[self.headSelect - 1]
    local headUnlock = Data.headData:GetShipHeadUnlockState(profileCfg.id)
    if not headUnlock then
      noticeManager:ShowTip(UIHelper.GetString(3600006))
      return
    end
    local param = {}
    param.shipFleetId = profileCfg.belongshipid
    param.profileID = profileCfg.id
    Service.userService:SendHeadSetRecord(param)
    self:_CloseHFPage()
  end
end

function PlayerHeadFramePage:_SelectHFItem(go, param)
  self.headFrameIndex = param.id
  self:_RefreshView()
end

function PlayerHeadFramePage:_MakeAllHeadFrame()
  local tmp = {}
  local oriTemp = self.m_allHeadFrameList
  for _, v in pairs(oriTemp) do
    table.insert(tmp, v)
  end
  return tmp
end

function PlayerHeadFramePage:DoOnHide()
  self:SaveSortData()
  Data.headData:SetRedRecord()
end

function PlayerHeadFramePage:DoOnClose()
  self:SaveSortData()
  Data.headData:SetRedRecord()
end

function PlayerHeadFramePage:_CallBackFunc()
end

function PlayerHeadFramePage:SwitchToggle(index)
  self.selectType = index
  if index == ShipHeadSelect.HeadFrame then
    self:_RefreshView()
  elseif index == ShipHeadSelect.HeadPortrait then
    self.headSelect = 1
    self:RefreshShipGirlView()
  elseif index == ShipHeadSelect.HeadDetails then
    self:RefreshShipHeadView()
    self:SelectDefaultHead()
  end
end

function PlayerHeadFramePage:RefreshShipGirlView()
  self.tab_Widgets.obj_framedetail:SetActive(false)
  self.tab_Widgets.btn_confirm.gameObject:SetActive(false)
  self.tab_Widgets.btn_Check.gameObject:SetActive(true)
  self.tab_Widgets.btn_BtnSort.gameObject:SetActive(true)
  local contentStr = UIHelper.GetString(3600001)
  UIHelper.SetText(self.tab_Widgets.txt_title, contentStr)
  self:DealSortData()
  self:ShowShipGirlList()
end

function PlayerHeadFramePage:DealSortData()
  local tabSelectData = Logic.sortLogic:GetHeroSort(CommonHeroItem.HeadPortrait)
  self.m_tabOutParams = tabSelectData[2]
end

function PlayerHeadFramePage:ShowShipGirlList()
  local heroData = Logic.illustrateLogic:GetHeadIllustrateByShowTag()
  self.m_heroData = heroData
  self.m_tabSortHero = HeroSortHelper.HeadFilterAndSort(self.m_heroData, self.m_tabOutParams[1])
  self:HaveHeroId()
  self:LoadHeroItem(self.m_tabSortHero)
end

function PlayerHeadFramePage:HaveHeroId()
  self.tabHeroId = {}
  for _, v in pairs(self.m_tabSortHero) do
    table.insert(self.tabHeroId, v.IllustrateId)
  end
end

function PlayerHeadFramePage:LoadHeroItem(heroTab)
  local config = configManager.GetDataById("config_profile", self.userInfo.Head)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_frameItem, self.tab_Widgets.rect_Content, #heroTab, function(index, tabPart)
    self.tabParts[index] = tabPart
    tabPart.img_select.gameObject:SetActive(false)
    tabPart.img_SelectItem.gameObject:SetActive(index == self.shipSelect)
    tabPart.btn_Back.gameObject:SetActive(false)
    tabPart.img_quality.gameObject:SetActive(true)
    tabPart.txt_name.gameObject:SetActive(true)
    tabPart.img_icon.gameObject:SetActive(true)
    local heroInfo = heroTab[index]
    local tabHero = Logic.shipLogic:GetPictureData(heroInfo.IllustrateId)
    tabPart.img_equip.gameObject:SetActive(tabHero.sf_id == config.belongshipid)
    local fashionData = Logic.fashionLogic:GetDefaultFashionData(tabHero.sf_id)
    local shipRed = Data.headData:GetRedDotBySFId(tabHero.sf_id)
    tabPart.img_New.gameObject:SetActive(shipRed)
    local shipShowData = configManager.GetDataById("config_ship_show", fashionData.ship_show_id)
    UIHelper.SetImage(tabPart.img_quality, UserHeadQualityImg[shipShowData.quality])
    UIHelper.SetImage(tabPart.img_icon, shipShowData.ship_icon5)
    tabPart.txt_name.gameObject:SetActive(true)
    UIHelper.SetText(tabPart.txt_name, shipShowData.ship_name)
    tabPart.img_lock.gameObject:SetActive(heroInfo.IllustrateState > IllustrateState.UNLOCK)
    local _, curHeadFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
    if curHeadFrameInfo then
      UIHelper.SetImage(tabPart.img_frame, curHeadFrameInfo.icon)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_frameItem, self.SelectShipItem, self, {id = index})
  end)
  self:SelectShipItem(self, {
    id = self.shipSelect
  })
end

function PlayerHeadFramePage:UpdateHeroLockInfo()
  self:HaveHeroId()
  self:LoadHeroItem(self.m_tabSortHero)
end

function PlayerHeadFramePage:_UpdateHeroSort(tabSortParams)
  self.m_tabInParams = tabSortParams
  self.m_tabOutParams = tabSortParams
  self:SortOrder()
end

function PlayerHeadFramePage:SortOrder()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  Logic.illustrateLogic:SetSortRule(self.sortway)
  self.m_tabSortHero = HeroSortHelper.HeadFilterAndSort(self.m_heroData, self.m_tabOutParams[1])
  self:HaveHeroId()
  self:LoadHeroItem(self.m_tabSortHero)
end

function PlayerHeadFramePage:SelectShipItem(go, param)
  self.tabParts[self.shipSelect].img_SelectItem:SetActive(false)
  self.shipSelect = param.id
  self.tabParts[self.shipSelect].img_SelectItem:SetActive(true)
end

function PlayerHeadFramePage:ClickHelpBtn()
  UIHelper.OpenPage("HelpPage", {content = 3600003})
end

function PlayerHeadFramePage:ClickCheckBtn()
  if #self.m_tabSortHero <= 0 then
    noticeManager:ShowTipById(3600009)
    return
  end
  self:SwitchToggle(ShipHeadSelect.HeadDetails)
end

function PlayerHeadFramePage:ClickSortBtn()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  UIHelper.OpenPage("SortPage", {
    self.m_tabOutParams[1],
    nil,
    SortType = MHeroSortType.Head
  })
end

function PlayerHeadFramePage:UpdateHeroSort(tabSortParams)
  self.m_tabInParams = tabSortParams
  self.m_tabOutParams = tabSortParams
  self:SortOrder()
end

function PlayerHeadFramePage:ClickBuyBtn()
  local profileCfg = self.shipHeadList[self.headSelect - 1]
  local heroInfo = self.m_tabSortHero[self.shipSelect]
  if heroInfo.IllustrateState > IllustrateState.UNLOCK then
    noticeManager:ShowTipById(3600007)
    return
  end
  local buyNum = Data.headData:GetHeadBuyCountBySFId(profileCfg.belongshipid)
  local cost = profileCfg.cost[2] * (1 + profileCfg.costrate * buyNum)
  local priceTab = {}
  table.insert(priceTab, {
    GoodsType.CURRENCY,
    profileCfg.cost[1],
    cost
  })
  local tabCondition = Logic.shopLogic:GetTableBuyCurrency(priceTab, buyNum)
  local canBuy = conditionCheckManager:CheckConditionsIsEnough(tabCondition, true)
  if not canBuy then
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(buy)
      if buy then
        UIHelper.ClosePage("NoticePage")
        local param = {}
        param.shipFleetId = profileCfg.belongshipid
        param.profileID = profileCfg.id
        Service.userService:SendHeadBuyRecord(param)
      end
    end
  }
  local currencyConf = configManager.GetDataById("config_currency", profileCfg.cost[1])
  local name = cost .. currencyConf.name
  local str = string.format(UIHelper.GetString(3600004), name, profileCfg.name)
  noticeManager:ShowMsgBox(str, tabParams)
end

function PlayerHeadFramePage:RefreshShipHeadView()
  self.tab_Widgets.obj_framedetail:SetActive(false)
  self.tab_Widgets.btn_Check.gameObject:SetActive(false)
  self.tab_Widgets.btn_BtnSort.gameObject:SetActive(false)
  self.tab_Widgets.btn_confirm.gameObject:SetActive(true)
  local tabHero = Logic.shipLogic:GetPictureData(self.m_tabSortHero[self.shipSelect].IllustrateId)
  local fashionData = Logic.fashionLogic:GetDefaultFashionData(tabHero.sf_id)
  local shipShowData = configManager.GetDataById("config_ship_show", fashionData.ship_show_id)
  local contentStr = string.format(UIHelper.GetString(3600002), shipShowData.ship_name)
  UIHelper.SetText(self.tab_Widgets.txt_title, contentStr)
  self:ShowShipHeadList()
end

function PlayerHeadFramePage:ShowShipHeadList()
  local heroInfo = self.m_tabSortHero[self.shipSelect]
  local tabHero = Logic.shipLogic:GetPictureData(heroInfo.IllustrateId)
  local profileList = Logic.headLogic:GetProfileCfgBySFid(tabHero.sf_id)
  if profileList == nil then
    self:SwitchToggle(1)
    return
  end
  local param = {}
  param.shipFleetId = tabHero.sf_id
  Service.userService:SendHeadBuyCountRecord(param)
  self:SortAndGetHeadList(profileList)
  self:LoadHeroHeadItem()
end

function PlayerHeadFramePage:SortAndGetHeadList(profileList)
  local shipHeadList = Data.headData:GetSortHeadList(profileList)
  self.shipHeadList = {}
  for _, v in pairs(shipHeadList) do
    self.shipHeadList[#self.shipHeadList + 1] = v
  end
end

function PlayerHeadFramePage:LoadHeroHeadItem()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_frameItem, self.tab_Widgets.rect_Content, #self.shipHeadList + 1, function(index, tabPart)
    self.tabHeadParts[index] = tabPart
    tabPart.img_select.gameObject:SetActive(false)
    tabPart.img_SelectItem.gameObject:SetActive(self.headSelect == index)
    if index == 1 then
      tabPart.btn_Back.gameObject:SetActive(true)
      tabPart.img_quality.gameObject:SetActive(false)
      tabPart.img_icon.gameObject:SetActive(false)
      tabPart.img_lock.gameObject:SetActive(false)
      tabPart.img_New.gameObject:SetActive(false)
      tabPart.txt_name.gameObject:SetActive(false)
      tabPart.img_equip.gameObject:SetActive(false)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_Back, self.GoBack, self, nil)
    else
      tabPart.btn_Back.gameObject:SetActive(false)
      tabPart.txt_name.gameObject:SetActive(true)
      local headInfo = self.shipHeadList[index - 1]
      UIHelper.SetImage(tabPart.img_icon, headInfo.image)
      UIHelper.SetImage(tabPart.img_quality, UserHeadQualityImg[ShipHeadQuality])
      UIHelper.SetText(tabPart.txt_name, headInfo.name)
      local headRed = Data.headData:GetRedDotBySFIdAndPId(headInfo.belongshipid, headInfo.id)
      tabPart.img_New.gameObject:SetActive(headRed)
      tabPart.img_equip.gameObject:SetActive(self.userInfo.Head == headInfo.id)
      local unlock = Data.headData:GetShipHeadUnlockState(headInfo.id)
      tabPart.img_lock.gameObject:SetActive(not unlock)
      local _, curHeadFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
      if curHeadFrameInfo then
        UIHelper.SetImage(tabPart.img_frame, curHeadFrameInfo.icon)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_frameItem, self.SelectShipHeadItem, self, {id = index})
    end
  end)
end

function PlayerHeadFramePage:GoBack(go, param)
  self:SwitchToggle(ShipHeadSelect.HeadPortrait)
end

function PlayerHeadFramePage:SelectDefaultHead()
  if self.headSelect <= 1 then
    for index, v in pairs(self.shipHeadList) do
      if self.userInfo.Head == v.id then
        self:SelectShipHeadItem(self, {
          id = index + 1
        })
        return
      end
    end
    self:SelectShipHeadItem(self, {id = 2})
  else
    self:SelectShipHeadItem(self, {
      id = self.headSelect
    })
  end
end

function PlayerHeadFramePage:SelectShipHeadItem(go, param)
  self.tabHeadParts[self.headSelect].img_SelectItem.gameObject:SetActive(false)
  self.headSelect = param.id
  self.tabHeadParts[self.headSelect].img_SelectItem.gameObject:SetActive(true)
  self:ShowSelectHeadDetail()
  local cfgIndex = self.headSelect - 1
  Data.headData:DetailRedDotBySFIdAndPId(self.shipHeadList[cfgIndex].belongshipid, self.shipHeadList[cfgIndex].id)
  if self.shipHeadList[cfgIndex].shownew > 0 then
    Data.headData:DetailRedDotRecord(self.shipHeadList[cfgIndex].id)
  end
  self.tabHeadParts[self.headSelect].img_New.gameObject:SetActive(false)
  self:CheckAllHeadRedData()
end

function PlayerHeadFramePage:ShowSelectHeadDetail()
  local profileCfg = self.shipHeadList[self.headSelect - 1]
  local widgets = self:GetWidgets()
  self.tab_Widgets.obj_framedetail:SetActive(true)
  UIHelper.SetImage(widgets.img_quality, UserHeadQualityImg[ShipHeadQuality])
  UIHelper.SetImage(widgets.img_icon, profileCfg.image)
  local _, curHeadFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  UIHelper.SetImage(widgets.img_frame, curHeadFrameInfo.icon)
  UIHelper.SetText(widgets.txt_name, profileCfg.name)
  UIHelper.SetText(widgets.txt_framedesc, profileCfg.desc)
  local unlock = Data.headData:GetShipHeadUnlockState(profileCfg.id)
  widgets.im_lock:SetActive(not unlock)
  widgets.txt_limit.gameObject:SetActive(not unlock)
  if profileCfg.type == 1 and not unlock then
    widgets.btn_BtnBuy.gameObject:SetActive(true)
    widgets.obj_Cost:SetActive(true)
    UIHelper.SetText(widgets.txt_limit, "")
    local buyNum = Data.headData:GetHeadBuyCountBySFId(profileCfg.belongshipid)
    local cost = profileCfg.cost[2] * (1 + tonumber(profileCfg.costrate) * buyNum)
    local icon = Logic.goodsLogic:GetSmallIcon(profileCfg.cost[1], GoodsType.CURRENCY)
    UIHelper.SetImage(widgets.img_ImgIcon, tostring(icon), true)
    UIHelper.SetText(widgets.txt_Text, tostring(cost))
  else
    if not unlock then
      UIHelper.SetText(widgets.txt_limit, profileCfg.dropdesc)
    end
    widgets.btn_BtnBuy.gameObject:SetActive(false)
    widgets.obj_Cost:SetActive(false)
  end
end

function PlayerHeadFramePage:SaveSortData()
  if #self.m_tabOutParams <= 0 then
    return
  end
  local tabSelectData = {}
  tabSelectData[1] = self.sortway
  tabSelectData[2] = self.m_tabOutParams
  Logic.sortLogic:SetHeroSort(CommonHeroItem.HeadPortrait, tabSelectData)
end

function PlayerHeadFramePage:ShipHeadBuySuccess()
  local profileCfg = self.shipHeadList[self.headSelect - 1]
  local param = {}
  param.shipFleetId = profileCfg.belongshipid
  Service.userService:SendHeadBuyCountRecord(param)
end

function PlayerHeadFramePage:ShipHeadUnlock(param)
  local widgets = self:GetWidgets()
  if self.selectType == ShipHeadSelect.HeadDetails then
    local profileCfg = self.shipHeadList[self.headSelect - 1]
    if param == profileCfg.id then
      self.tabHeadParts[self.headSelect - 1].img_lock.gameObject:SetActive(true)
      widgets.im_lock:SetActive(false)
      widgets.txt_limit.gameObject:SetActive(false)
      widgets.btn_BtnBuy.gameObject:SetActive(false)
      widgets.obj_Cost:SetActive(false)
    end
  elseif self.selectType == ShipHeadSelect.HeadDetails then
  end
  widgets.im_tanhao2:SetActive(true)
  self:CheckHeadRedDot()
  self:CheckHeadRedDot()
end

function PlayerHeadFramePage:CheckAllHeadRedData()
  local allRed = Data.headData:GetRedDot()
  self:GetWidgets().im_tanhao2:SetActive(allRed)
end

function PlayerHeadFramePage:CheckHeadRedDot()
  if #self.tabParts < 0 or self.selectType ~= ShipHeadSelect.HeadPortrait then
    return
  end
  for index, v in pairs(self.tabParts) do
    local heroInfo = self.m_tabSortHero[index]
    local tabHero = Logic.shipLogic:GetPictureData(heroInfo.IllustrateId)
    local shipRed = Data.headData:GetRedDotBySFId(tabHero.sf_id)
    v.img_New.gameObject:SetActive(shipRed)
  end
end

function PlayerHeadFramePage:CheckHeadRedDot()
  if #self.tabHeadParts < 0 or self.selectType ~= ShipHeadSelect.HeadDetails then
    return
  end
  for index, v in pairs(self.tabHeadParts) do
    if 1 < index then
      local headRed = Data.headData:GetRedDotBySFIdAndPId(self.shipHeadList[index - 1].belongshipid, self.shipHeadList[index - 1].id)
      v.img_New.gameObject:SetActive(headRed)
      local unlock = Data.headData:GetShipHeadUnlockState(self.shipHeadList[index - 1].id)
      v.img_lock.gameObject:SetActive(not unlock)
    end
  end
end

return PlayerHeadFramePage
