local BathDetailsPage = class("UI.Bathroom.BathDetailsPage", LuaUIPage)
local BathTimeControl = require("ui.page.Bathroom.BathTimeControl")
local bathRoomPage = require("ui.page.Bathroom.BathRoomPage")
local TICKET_ID = 90001

function BathDetailsPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabgirlinrepair = nil
  self.heroDetail = nil
  self.heroInfo = nil
  self.shipInfo = nil
  self.m_timer = nil
  self.autoStatus = 0
end

function BathDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeDetail, self._ClickCloseDetail, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_finish, self._ClickOpenFinish, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_auto, self._ClickAuto, self)
  self:RegisterEvent(LuaEvent.BathEndOk, self._FinishBath, self)
  self:RegisterEvent(LuaEvent.BathAutoTicket, self._AutoTicket, self)
end

function BathDetailsPage:DoOnOpen()
  local param = self:GetParam()
  local openType = param[2]
  if openType == 1 then
    self:_OpenDetailsPage(param[1])
  else
    self:_FinishBath(param[1])
  end
end

function BathDetailsPage:_OpenDetailsPage(param)
  self.m_tabgirlinrepair = param
  self.tab_Widgets.obj_details:SetActive(true)
  self.tab_Widgets.obj_left:SetActive(next(self.m_tabgirlinrepair) ~= nil)
  self.tab_Widgets.obj_right:SetActive(next(self.m_tabgirlinrepair) ~= nil)
  self.tab_Widgets.obj_hint:SetActive(next(self.m_tabgirlinrepair) == nil)
  local shipTab = {}
  for _, v in pairs(self.m_tabgirlinrepair) do
    table.insert(shipTab, v)
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_shipItem, self.tab_Widgets.trans_shipTab, #shipTab, function(nIndex, tabPart)
    local shipShow = Logic.shipLogic:GetShipShowByHeroId(shipTab[nIndex].HeroId)
    if nIndex == 1 then
      tabPart.obj_select:SetActive(true)
      self:_SelectShip({
        tabPart,
        shipTab[nIndex],
        shipInfo
      })
    else
      tabPart.obj_select:SetActive(false)
    end
    if tabPart.im_mood then
      local moodInfo = Logic.marryLogic:GetLoveInfo(shipTab[nIndex].HeroId, MarryType.Mood, true)
      if moodInfo then
        tabPart.im_mood.gameObject:SetActive(true)
        UIHelper.SetImage(tabPart.im_mood, moodInfo.mood_icon, true)
      end
    end
    if tabPart.im_kuang then
      local marryInfo = Logic.marryLogic:GetLoveInfo(shipTab[nIndex].HeroId, MarryType.Kuang)
      if marryInfo.MarryTime then
        tabPart.im_kuang.gameObject:SetActive(marryInfo.MarryTime ~= 0)
      end
    end
    UIHelper.SetImage(tabPart.img_head, shipShow.ship_icon_bathroom)
    tabPart.txt_name.text = Logic.shipLogic:GetRealName(shipTab[nIndex].HeroId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_girl, function()
      self:_SelectShip({
        tabPart,
        shipTab[nIndex],
        shipInfo
      })
    end)
  end)
end

function BathDetailsPage:_SelectShip(param)
  if self.heroDetail ~= nil then
    self.heroDetail[1].obj_select:SetActive(false)
  end
  self.heroInfo = param[2]
  self.shipInfo = param[3]
  self.heroDetail = param
  self.heroDetail[1].obj_select:SetActive(true)
  self.tab_Widgets.txt_name.text = Logic.shipLogic:GetRealName(self.heroInfo)
  local curHeroInfo = Data.heroData:GetHeroById(self.heroInfo.HeroId)
  self.tab_Widgets.txt_expLv.text = "Lv." .. math.tointeger(curHeroInfo.Lvl)
  local sumExp = Logic.shipLogic:GetMaxExp(curHeroInfo.Lvl - 1)
  local needExp = Logic.shipLogic:GetHeroLevelExp(curHeroInfo.Lvl)
  self.tab_Widgets.txt_expValue.text = math.tointeger(curHeroInfo.Exp) .. "/" .. needExp
  if needExp == 0 then
    self.tab_Widgets.slider_exp.value = 1
  else
    self.tab_Widgets.slider_exp.value = math.tointeger(curHeroInfo.Exp) / needExp
  end
  self.tab_Widgets.txt_feelLv.text = "Lv.1"
  self.tab_Widgets.txt_feelValue.text = "50/100"
  self.tab_Widgets.slider_feel.value = 0.5
  self.tab_Widgets.txt_moodValue.text = "50/100"
  self.tab_Widgets.slider_mood.value = 0.5
  self.tab_Widgets.tog_auto.isOn = self.heroInfo.IsAuto == 1
  local giftTab = Logic.bathroomLogic:GetHeroLikeGift(self.heroInfo.TemplateId)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_giftItem, self.tab_Widgets.trans_gift, #giftTab, function(nIndex, tabPart)
    UIHelper.SetImage(tabPart.img_picture, giftTab[nIndex].icon)
    UIHelper.SetImage(tabPart.img_quality, giftTab[nIndex].quility_background)
  end)
  if self.heroInfo.BuffId == 0 then
    self.tab_Widgets.obj_buff:SetActive(false)
    self.tab_Widgets.obj_noBuff:SetActive(true)
  else
    local buffInfo = configManager.GetDataById("config_value_effect", self.heroInfo.BuffId)
    if 0 > self.heroInfo.BuffTime + buffInfo.time - time.getSvrTime() then
      self.tab_Widgets.obj_buff:SetActive(false)
      self.tab_Widgets.obj_noBuff:SetActive(true)
    else
      self.tab_Widgets.obj_buff:SetActive(true)
      self.tab_Widgets.obj_noBuff:SetActive(false)
      UIHelper.SetImage(self.tab_Widgets.img_curBuff, buffInfo.buff_icon)
      UIHelper.SetImage(self.tab_Widgets.img_buffBg, buffInfo.buff_background)
      self.tab_Widgets.txt_buffDesc.text = buffInfo.desc
    end
  end
end

function BathDetailsPage:CreateCountDown()
  self.m_timer = self.m_timer or Timer.New()
  local timer = self.m_timer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:_SetLeftTime()
  end, 1, -1)
  timer:Start()
  self:_SetLeftTime()
end

function BathDetailsPage:_SetLeftTime()
  if self.heroInfo.StartTime == 0 then
    self:_BathEnd()
    return
  end
  local svrTime = time.getSvrTime()
  local limitTime = configManager.GetDataById("config_bathroom_item", TICKET_ID).time
  local bagInfo = Logic.bagLogic:ItemInfoById(TICKET_ID)
  local ticket = bagInfo == nil and 0 or bagInfo.num
  local surplusTime = self.heroInfo.StartTime + limitTime - svrTime
  if self.heroInfo.IsAuto == 1 then
    if surplusTime <= 0 then
      if 0 < ticket then
        self.heroInfo.StartTime = svrTime
        surplusTime = self.heroInfo.StartTime + limitTime - svrTime
      else
        self:_BathEnd()
        return
      end
    end
  elseif surplusTime <= 0 then
    self:_BathEnd()
    return
  end
  self.tab_Widgets.txt_time.text = self._TransTimeStr(surplusTime)
end

function BathDetailsPage._TransTimeStr(left)
  local sec = left % 60
  left = math.floor(left / 60)
  local min = left % 60
  left = math.floor(left / 60)
  local hour = left % 24
  local day = math.floor(left / 24)
  return string.format("%02d:%02d:%02d", hour, min, sec)
end

function BathDetailsPage:_ClickCloseDetail()
  if self.m_timer and self.m_timer.running then
    self.m_timer:Stop()
  end
  Service.bathroomService:SendGetBathroomInfo()
  UIHelper.ClosePage("BathDetailsPage")
end

function BathDetailsPage:_ClickOpenFinish()
  local param = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_BathEnd()
      end
    end
  }
  local str = string.format(UIHelper.GetString(300004), self.shipInfo.ship_name)
  noticeManager:ShowMsgBox(str, param, UILayer.ATTENTION)
end

function BathDetailsPage:_BathEnd()
  local dotinfo = {
    info = "ui_bathing_finish",
    type = 1
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BathDetailsPage:_FinishBath(param)
  local hero = param.heroInfo
  self.tab_Widgets.obj_details:SetActive(false)
  self.tab_Widgets.obj_finish:SetActive(true)
  if self.m_timer and self.m_timer.running then
    self.m_timer:Stop()
  end
  local girlCard = CSUIHelper.GetObjComponent(self.tab_Widgets.obj_girl, BabelTime.Lobby.UI.LuaPart.GetClassType())
  ShipCardItem:LoadVerticalCard(hero.HeroId, girlCard)
  BathTimeControl:RemovePoolHero(hero.HeroId)
  local hero = Data.heroData:GetHeroById(hero.HeroId)
  self.tab_Widgets.txt_finishLv.text = "Lv." .. math.tointeger(hero.Lvl)
  self.tab_Widgets.txt_finishTime.text = time.formatTimerToDHMS(math.tointeger(param.BathTime))
  self.tab_Widgets.txt_finishExp.text = "+" .. math.tointeger(param.AddExp)
  self.tab_Widgets.obj_finishFeel:SetActive(false)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_stars, self.tab_Widgets.trans_stars, hero.Advance, function(nIndex, part)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_finishTrue, self._ClickCloseFinish, self, param)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeFinish, self._ClickCloseFinish, self, param)
end

function BathDetailsPage:_ClickCloseFinish(obj, param)
  UIHelper.ClosePage("BathDetailsPage")
  if param.endType == BathEndType.Finish then
    eventManager:SendEvent(LuaEvent.CloseBathFinish, param.heroInfo)
  elseif param.endType == BathEndType.AllBath then
    eventManager:SendEvent(LuaEvent.BathStartAllFinish, param.heroInfo)
  end
  eventManager:SendEvent(LuaEvent.BathroomFinish)
end

function BathDetailsPage:_ClickAuto()
  if self.tab_Widgets.tog_auto.isOn then
    self.autoStatus = 1
  else
    self.autoStatus = 0
  end
  Service.bathroomService:SendBathAuto(self.heroInfo.HeroId, self.autoStatus)
end

function BathDetailsPage:_AutoTicket()
  if self.autoStatus == 1 then
    self.tab_Widgets.tog_auto.isOn = true
  else
    self.tab_Widgets.tog_auto.isOn = false
  end
  self.heroInfo.IsAuto = self.autoStatus
end

function BathDetailsPage:DoOnClose()
  BathTimeControl:StartTimer()
end

return BathDetailsPage
