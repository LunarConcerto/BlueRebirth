TopPage = class("UI.TopPage", LuaUIPage)

function TopPage:DoInit()
  self.m_tabWidgets = nil
  self.userData = nil
  self.title = nil
  self.pageName = nil
  self.pageType = 0
  self.isEffect = true
  self.CloseFunc = nil
  self.pvePtTimer = nil
  self.showPvePt = false
  self.IsShowOtherCurrency = false
  self.ShowCurrencyInfo = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.buyCurrencyPage = {
    [CurrencyType.GOLD] = self._ClickGold,
    [CurrencyType.DIAMOND] = self._ClickAddDiamond,
    [CurrencyType.SUPPLY] = {
      self._ClickSupply,
      self._ClickAdd
    },
    [CurrencyType.LUCKY] = self._ClickAddLucky
  }
end

function TopPage:DoOnOpen()
  self.itemParam = nil
  self.m_tabWidgets.im_icon:SetActive(false)
  self.tab_Widgets.obj_PvePt:SetActive(false)
  self.m_tabWidgets.obj_top1:SetActive(self.param.PageType == TopPageType.Home)
  self.m_tabWidgets.obj_top2:SetActive(self.param.PageType ~= TopPageType.Home)
  self.m_tabWidgets.obj_top3:SetActive(self.param.PageType == TopPageType.Animoji)
  if self.param.PageType == TopPageType.Animoji then
    self.m_tabWidgets.obj_top2:SetActive(false)
    self.m_tabWidgets.obj_top1:SetActive(false)
  end
  self.m_tabWidgets.obj_ziyuan:SetActive(self.param.PageType ~= TopPageType.User)
  self.m_tabWidgets.obj_chapter:SetActive(not self.param.PageType == TopPageType.Copy)
  self.m_tabWidgets.trans_custom.gameObject:SetActive(false)
  self.isEffect = self.param.IsEffect
  self.CloseFunc = self.param.CloseFunc
  self.m_tabWidgets.txt_title.gameObject:SetActive(self.param.Title ~= nil)
  self.pageName = self.param.PageName ~= nil and self.param.PageName or ""
  self.m_tabWidgets.txt_title.text = self.param.Title ~= nil and self.param.Title or ""
  self.m_tabWidgets.txt_title3.text = self.param.Title ~= nil and self.param.Title or ""
  if self.param.PageName and self.param.PageName == "TaskPage" or self.param.PageName == "ActivityPage" or self.param.PageName == "TrainLevelPage" then
    Logic.taskLogic:SetTopIconPos({
      self.m_tabWidgets.icon1.position,
      self.m_tabWidgets.icon2.position,
      self.m_tabWidgets.icon3.position
    })
  end
  if self.param.CustomInfo ~= nil then
    self.itemParam = self.param.CustomInfo
    self:_CreateCurrencyItem()
  end
  if self.param.PageType == TopPageType.Home then
    self:HomereSourceInfo()
  elseif self.param.PageType == TopPageType.General or self.param.PageType == TopPageType.User then
    self:_GetCurrencyBasicInfo()
  elseif self.param.PageType == TopPageType.Copy then
    local chapIndex, _ = Logic.copyLogic:GetDisplayChapterId()
    self:_UpdateTopCopy({
      TitleName = UIHelper.GetString(920000179),
      ChapterId = chapIndex
    })
    self:_GetCurrencyBasicInfo()
  else
    logError("\230\137\147\229\188\128\229\133\182\228\187\150\231\177\187\229\158\139\231\154\132\229\188\185\230\161\134\227\128\130\227\128\130\227\128\130\227\128\130")
  end
end

function TopPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._UpdateUserData, self)
  self:RegisterEvent(LuaEvent.TopAddItem, self._UpdateTopInfo, self)
  self:RegisterEvent(LuaEvent.UpdateCopyTitle, self._UpdateTopCopy, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._CreateCurrencyItem, self)
  self:RegisterEvent(LuaEvent.TopUpdateCurrency, self._UpdateCurrencyItem, self)
  self:RegisterEvent(LuaEvent.TopShowPvePt, self._ShowPvePt, self)
  self:RegisterEvent(LuaCSharpEvent.PressBack, self._OnPressBack, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeCurPage, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_supplyHome, self._ClickSupplyHome, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_addHome, self._ClickAddHome, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_goldHome, self._ClickGoldHome, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_diamondHome, self._ClickDiamondHome, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeCurPage3, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_supply, self._ClickSupply, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_add, self._ClickAdd, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_diamond, self._ClickDiamond, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_gold, self._ClickGold, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_addDiamond1, self._ClickAddDiamond, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_addDiamond2, self._ClickAddDiamond, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_pvePt, self._ClickAddPvePt, self)
end

function TopPage:_ClickAddDiamond()
  if not self:_ClickCondition() then
    return
  end
  if platformManager:useSDK() then
    Logic.shopLogic:OpenRechargeShop()
  end
end

function TopPage:_ClickAddLucky()
  if not self:_ClickCondition() then
    return
  end
  Logic.shopLogic:OpenLuckyRechargeShop()
end

function TopPage:_ClickSupplyHome()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("IncreaseInfoPage")
end

function TopPage:_ClickAddHome()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Supply)
end

function TopPage:_ClickGoldHome()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
end

function TopPage:_ClickDiamondHome(...)
  if not self:_ClickCondition() then
    return
  end
  if platformManager:useSDK() then
    Logic.shopLogic:OpenRechargeShop()
  end
end

function TopPage:_ClickDiamond()
  for i, v in pairs(InteractionItemPageType) do
    if UIPageManager:IsExistPage(v) then
      UIHelper.ClosePage(v)
    end
  end
  if not self:_ClickCondition() then
    return
  end
  if Logic.pveRoomLogic:GetInRoomState() then
    noticeManager:ShowTipById(6100064)
    return
  end
  if platformManager:useSDK() then
    Logic.shopLogic:OpenRechargeShop()
  end
end

function TopPage:_ClickOtherCurrency(type, id)
  if not self:_ClickCondition() then
    return
  end
  globalNoitceManager:ShowItemInfoPage(type, id)
end

function TopPage:_ClickOther(btn, tabParam)
  if not self:_ClickCondition() then
    return
  end
  globalNoitceManager:ShowItemInfoPage(tabParam.type, tabParam.id)
end

function TopPage:_ClickGold()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
end

function TopPage:_ClickSupply()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("IncreaseInfoPage")
end

function TopPage:_ClickAdd()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("BuyResourcePage", BuyResource.Supply)
end

function TopPage:_ClickClose()
  if Data.copyData:GetMatchingState() then
    noticeManager:ShowTip(UIHelper.GetString(6100013))
    Data.copyData:SetMatchingState(false)
    local arg = {
      uid = Data.userData:GetUserData().Uid
    }
    Service.matchService:SendMatchLeave(arg)
  end
  if self.CloseFunc ~= nil then
    self.CloseFunc()
  else
    UIHelper.ClosePage(self.pageName)
  end
end

function TopPage:_OnPressBack()
end

function TopPage:_UpdateUserData()
  self:HomereSourceInfo()
  self:_GetCurrencyBasicInfo()
  self:_CreateCurrencyItem()
  if self.showPvePt then
    self:_ShowPvePt()
  end
end

function TopPage:_UpdateTopInfo(param)
  self.IsShowOtherCurrency = param.isShow
  self.ShowCurrencyInfo = param.CurrencyInfo
  self.m_tabWidgets.obj_other:SetActive(self.IsShowOtherCurrency)
  if self.IsShowOtherCurrency then
    self:_ShowSpecailTopInfo()
  end
end

function TopPage:_ShowSpecailTopInfo()
  UIHelper.SetImage(self.m_tabWidgets.im_otherIcon, self.ShowCurrencyInfo.icon_small)
  local currencyNum = Logic.shopLogic:GetUserCurrencyNum(self.ShowCurrencyInfo.id)
  self.m_tabWidgets.txt_otherCurren.text = self:ChangeShowNum(currencyNum)
  self.m_tabWidgets.btn_other.gameObject:SetActive(true)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_other, self._ClickOther, self, {
    type = 5,
    id = self.ShowCurrencyInfo.id
  })
end

function TopPage:_UpdateTopCopy(tabParam)
  self.CloseFunc = tabParam.CloseFunc
  if tabParam.ChapterId ~= nil then
    self.m_tabWidgets.obj_chapter:SetActive(true)
    local tabChapter = configManager.GetDataById("config_chapter", tabParam.ChapterId)
    if tabChapter.class_type == ChapterType.PlotCopy and tabChapter.id ~= 1 then
      self.m_tabWidgets.tx_number.text = tabChapter.title
    else
      self.m_tabWidgets.tx_number.text = tabChapter.title
    end
    self.m_tabWidgets.tx_name.text = tabChapter.name
  else
    self.m_tabWidgets.obj_chapter:SetActive(false)
  end
  self.m_tabWidgets.txt_title.text = tabParam.TitleName
end

function TopPage:HomereSourceInfo()
  local userData = Data.userData:GetUserData()
  self.m_tabWidgets.txt_diamond1.text = self:ChangeShowNum(userData.Diamond)
  self.m_tabWidgets.txt_gold1.text = self:ChangeShowNum(userData.Gold)
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  self.m_tabWidgets.txt_supply1.text = self:ChangeShowNum(supply)
  self:_CheckResourceRecoverLoop(function()
    local max = Data.userData:GetCurrencyMax(CurrencyType.SUPPLY)
    local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
    self.m_tabWidgets.txt_supply1.text = self:ChangeShowNum(supply)
    return max <= supply
  end)
end

function TopPage:_GetCurrencyBasicInfo()
  local userData = Data.userData:GetUserData()
  self.m_tabWidgets.txt_diamond2.text = self:ChangeShowNum(userData.Diamond)
  self.m_tabWidgets.txt_gold2.text = self:ChangeShowNum(userData.Gold)
  local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  self.m_tabWidgets.txt_supply2.text = self:ChangeShowNum(supply)
  self.m_tabWidgets.obj_other:SetActive(self.IsShowOtherCurrency)
  if self.IsShowOtherCurrency then
    self:_ShowSpecailTopInfo()
  end
  self:_CheckResourceRecoverLoop(function()
    local supply = Data.userData:GetCurrency(CurrencyType.SUPPLY)
    local max = Data.userData:GetCurrencyMax(CurrencyType.SUPPLY)
    self.m_tabWidgets.txt_supply2.text = self:ChangeShowNum(supply)
    return supply >= max
  end)
end

function TopPage:_CheckResourceRecoverLoop(getValueCall)
  self.recoverTimer = self:CreateTimer(function()
    local cancle = getValueCall()
    if cancle and self.recoverTimer then
      self.recoverTimer:Stop()
    end
  end, 60, -1, false)
  self:StartTimer(self.recoverTimer)
end

function TopPage:_UpdateCurrencyItem(param)
  self.itemParam = param
  self:_CreateCurrencyItem()
end

function TopPage:_CreateCurrencyItem()
  if self.param.PageType == TopPageType.User then
    return
  end
  self.m_tabWidgets.obj_top2Title:SetActive(self.param.PageName ~= nil)
  self.m_tabWidgets.obj_ziyuan:SetActive(self.itemParam == nil)
  self.m_tabWidgets.trans_custom.gameObject:SetActive(self.itemParam ~= nil)
  if self.itemParam ~= nil then
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trans_custom, #self.itemParam, function(nIndex, tabPart)
      tabPart.obj_add:SetActive(false)
      UGUIEventListener.ClearButtonEventListener(tabPart.btn_icon.gameObject)
      UGUIEventListener.ClearButtonEventListener(tabPart.btn_add.gameObject)
      local mType = self.itemParam[nIndex][1]
      local id = self.itemParam[nIndex][2]
      local icon = ""
      local value = 0
      if mType == 5 then
        icon = Logic.currencyLogic:GetSmallIcon(id)
        value = Data.userData:GetCurrency(id)
        if self.buyCurrencyPage[id] ~= nil then
          tabPart.obj_add:SetActive(true)
          local func = self.buyCurrencyPage[id]
          if type(func) == "table" then
            UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
              SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
              func[1](self)
            end, self)
            UGUIEventListener.AddButtonOnClick(tabPart.btn_add, function()
              SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
              func[2](self)
            end, self)
          else
            UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
              SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
              func(self, mType, id)
            end, self)
            UGUIEventListener.AddButtonOnClick(tabPart.btn_add, function()
              SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
              func(self, mType, id)
            end, self)
          end
        else
          UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
            SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
            self._ClickOtherCurrency(self, mType, id)
          end, self)
        end
      else
        tabPart.obj_add:SetActive(self.itemParam[nIndex][3])
        if self.itemParam[nIndex][3] then
          UGUIEventListener.AddButtonOnClick(tabPart.btn_add, function()
            SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
            UIHelper.OpenPage("ShopPage", {
              shopId = self.itemParam[nIndex][3]
            })
          end, self)
        end
        local config = Logic.bagLogic:GetItemByConfig(id)
        value = Data.bagData:GetItemNum(id)
        icon = config.icon_small
        UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
          SoundManager.Instance:PlayAudio("UI_Button_TopPage_0004")
          self._ClickOtherCurrency(self, mType, id)
        end, self)
      end
      UIHelper.SetImage(tabPart.img_icon, icon)
      tabPart.txt_value.text = self:ChangeShowNum(value)
    end)
  end
end

function TopPage:_ClickCondition()
  if GR.guideHub:isInGuide() then
    return false
  end
  return true
end

function TopPage:ChangeShowNum(num)
  local retNum = math.tointeger(num)
  if 1000000 <= retNum then
    local temp = math.round(retNum / 10000)
    retNum = temp .. UIHelper.GetString(920000731)
  end
  return retNum
end

function TopPage:_ShowPvePt()
  if self.pvePtTimer ~= nil then
    self.pvePtTimer:Stop()
    self.pvePtTimer = nil
  end
  self.showPvePt = true
  self.tab_Widgets.obj_PvePt:SetActive(self.showPvePt)
  local pvePtOwnNum = Data.userData:GetCurrency(CurrencyType.PVEPT)
  local pvePtMaxNum = Data.userData:GetCurrencyMax(CurrencyType.PVEPT)
  UIHelper.SetText(self.tab_Widgets.txt_ptNum, pvePtOwnNum)
  self.tab_Widgets.trans_pvePt.gameObject:SetActive(false)
  self.tab_Widgets.tx_pvePtTime.gameObject:SetActive(pvePtOwnNum < pvePtMaxNum)
  if pvePtOwnNum < pvePtMaxNum then
    local userLv = Data.userData:GetUserLevel()
    local lvupTime = configManager.GetDataById("config_player_levelup", userLv).pvept_recovery[2]
    local recoverTime = Data.userData:GetRecoverTime(RECOVER.PVEPT)
    local allTime = time.getSvrTime() + (lvupTime - (time.getSvrTime() - recoverTime))
    if 1 < pvePtMaxNum - pvePtOwnNum then
      allTime = allTime + lvupTime * (pvePtMaxNum - pvePtOwnNum - 1)
    end
    str = string.format(UIHelper.GetString(6100065), time.formatTimerToHMSColonZeroTime1(allTime - time.getSvrTime()))
    self.tab_Widgets.tx_pvePtTime.text = str
    self.pvePtTimer = self:CreateTimer(function()
      str = string.format(UIHelper.GetString(6100065), time.formatTimerToHMSColonZeroTime1(allTime - time.getSvrTime()))
      self.tab_Widgets.tx_pvePtTime.text = str
    end, 1, -1, false)
    self:StartTimer(self.pvePtTimer)
  end
end

function TopPage:_ClickAddPvePt()
  if not self:_ClickCondition() then
    return
  end
  UIHelper.OpenPage("BuyResourcePage", BuyResource.PvePt)
end

function TopPage:DoOnHide()
end

function TopPage:DoOnClose()
end

return TopPage
