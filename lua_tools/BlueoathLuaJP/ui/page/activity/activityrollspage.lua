local ActivityRollsPage = class("UI.Activity.ActivityRollsPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local State = {
  INI = 0,
  NULL = 1,
  GET = 2,
  CHOOSE = 3,
  TIPS = 4
}
local CardShow = {Front = 1, Back = 0}
local ROLLTIME = 10

function ActivityRollsPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.actRollsInfo = {}
  self.m_curSelectTeam = 0
  self.m_pageState = State.INI
  self.m_tabPartsInfo = {}
  self.m_cardState = {}
  self.m_isRollRefresh = 0
end

function ActivityRollsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_roll, function()
    self:_ClickRoll()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get_ok, function()
    self:_ClickGetOk()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_before, function()
    self:_ClickBefore()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_after, function()
    self:_ClickAfter()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, function()
    self:_ClickOk()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, function()
    self:_ClickBack()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, function()
    self:_ClickHelp()
  end)
  self:RegisterEvent(LuaEvent.ErrorRollsData, self._ShowErrorMsg, self)
  self:RegisterEvent(LuaEvent.UpdateActivityRolls, self._UpdatePage, self)
  self:RegisterEvent(LuaEvent.ActivityRollsRand, self._RandOver, self)
  self:RegisterEvent(LuaEvent.ActivityRollsSelect, self._SelectOver, self)
end

function ActivityRollsPage:_ShowErrorMsg()
  noticeManager:OpenTipPage(self, UIHelper.GetString(270016))
end

function ActivityRollsPage:_UpdatePage()
  self.actRollsInfo = Data.activityRollsData:GetData()
end

function ActivityRollsPage:_RandOver()
  self.actRollsInfo = Data.activityRollsData:GetData()
  self:_ShowAnim(self.actRollsInfo)
end

function ActivityRollsPage:_ShowAnim()
  for i, v in pairs(self.m_tabPartsInfo) do
    self:__PlayCardAnimiByState(i, v, CardShow.Back, nil)
  end
  self:_ShowBgCards(false)
  local actData = configManager.GetDataById("config_activity", self.activityId)
  local tick = actData.p5[1]
  self.m_isRollRefresh = 0
  self.tab_Widgets.obj_animiMask:SetActive(true)
  for i, v in pairs(self.m_tabPartsInfo) do
    local dalay = 0.5 + i * tick
    local m_timer = self:CreateTimer(function()
      self:_TickCharge(i)
    end, dalay, 1, false)
    self:StartTimer(m_timer)
  end
  self.m_timerShowPage = self:CreateTimer(function()
    if self.m_cardState[10] == 1 and self.m_isRollRefresh == 1 then
      self.m_pageState = State.GET
      self.tab_Widgets.obj_animiMask:SetActive(false)
      self:_ShowPage()
      self.m_isRollRefresh = 0
    end
  end, 0.5, -1, false)
  self:StartTimer(self.m_timerShowPage)
end

function ActivityRollsPage:_SelectOver()
  self:ChangePageState(State.NULL)
  self:_ShowPage()
end

function ActivityRollsPage:_TickCharge(index)
  local tmp_v = self.m_tabPartsInfo[index]
  self:__PlayCardAnimiByState(index, tmp_v, nil, 1)
  if index == 10 then
    local m_timer = self:CreateTimer(function()
      self.m_isRollRefresh = 1
    end, 1, 1, false)
    self:StartTimer(m_timer)
  end
end

function ActivityRollsPage:__PlayCardAnimiByState(indexCard, tabpartCard, FloatStatic, FloatRoll)
  local tmp_v = tabpartCard
  local animatorArr = tmp_v.gameObject:GetComponentsInChildren(UnityEngine_Animator.GetClassType())
  self.m_animList = {}
  for i = 0, animatorArr.Length - 1 do
    table.insert(self.m_animList, animatorArr[i])
  end
  if FloatStatic then
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("FloatStatic", FloatStatic)
    end
    self.m_cardState[indexCard] = FloatStatic
  end
  if FloatRoll then
    SoundManager.Instance:PlayAudio("Effect_heiping")
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("FloatRoll", FloatRoll)
    end
    self.m_cardState[indexCard] = FloatRoll
  end
end

function ActivityRollsPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.m_pageState = self:__GetState()
  local isRoll = Data.activityRollsData:GetRollsFreshState()
  if not isRoll then
    Service.activityRollsService:SendUpdateActRollsInfo()
  end
  self.tab_Widgets.obj_animiMask:SetActive(false)
  self:_ShowPage()
end

function ActivityRollsPage:_ClickRoll()
  self.actRollsInfo = Data.activityRollsData:GetData()
  local time = self.actRollsInfo.DaySelectCount
  if 1 <= time then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4400010))
    return
  end
  if self.actRollsInfo.SelectShipTeam.ShipId ~= nil and next(self.actRollsInfo.SelectShipTeam.ShipId) ~= nil then
    logError("not nil!!", self.actRollsInfo.SelectShipTeam.ShipId)
    return
  end
  Service.activityRollsService:SendRandShips()
end

function ActivityRollsPage:_ClickGetOk()
  self.actRollsInfo = Data.activityRollsData:GetData()
  if self.actRollsInfo.SelectShipTeam.ShipId ~= nil and next(self.actRollsInfo.SelectShipTeam.ShipId) ~= nil then
    if self.actRollsInfo.SaveShipTeam.ShipId ~= nil and next(self.actRollsInfo.SaveShipTeam.ShipId) ~= nil then
      self:ChangePageState(State.CHOOSE)
      self:_ShowPage()
    else
      self:ChangePageState(State.NULL)
      Service.activityRollsService:SendSecletShips(ActivityRollsSelect.CHOOSE_SELECT_NEW)
    end
  else
    self:_ShowPage()
  end
end

function ActivityRollsPage:_ClickBefore()
  self.m_curSelectTeam = ActivityRollsSelect.CHOOSE_SAVE_OLD
  self:ChangePageState(State.TIPS)
  self:_ShowPage()
end

function ActivityRollsPage:_ClickAfter()
  self.m_curSelectTeam = ActivityRollsSelect.CHOOSE_SELECT_NEW
  self:ChangePageState(State.TIPS)
  self:_ShowPage()
end

function ActivityRollsPage:_ClickOk()
  if self.m_curSelectTeam ~= ActivityRollsSelect.CHOOSE_SELECT_NEW and self.m_curSelectTeam ~= ActivityRollsSelect.CHOOSE_SAVE_OLD then
    self:_ShowPage()
  end
  Service.activityRollsService:SendSecletShips(self.m_curSelectTeam)
end

function ActivityRollsPage:_ClickBack()
  self:ChangePageState(State.CHOOSE)
  self:_ShowPage()
end

function ActivityRollsPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 4400012})
end

function ActivityRollsPage:_ShowPage()
  local widgets = self.tab_Widgets
  self.actRollsInfo = Data.activityRollsData:GetData()
  self:_ShowBgCards(true)
  self:_ShowGetCards()
  self:_ShowChooseCards()
  self:_ShowTips()
end

function ActivityRollsPage:__GetState()
  if self.m_pageState ~= State.INI then
  else
    self.actRollsInfo = Data.activityRollsData:GetData()
    if next(self.actRollsInfo.SelectShipTeam.ShipId) ~= nil then
      if next(self.actRollsInfo.SaveShipTeam.ShipId) ~= nil then
        self:ChangePageState(State.CHOOSE)
      else
        self:ChangePageState(State.GET)
      end
    else
      self:ChangePageState(State.NULL)
    end
  end
  return self.m_pageState
end

function ActivityRollsPage:_ShowBgCards(isShowAnimi)
  self.actRollsInfo = Data.activityRollsData:GetData()
  local CardsList = self.actRollsInfo.SaveShipTeam.ShipId
  if not isShowAnimi then
    CardsList = self.actRollsInfo.SelectShipTeam.ShipId
  end
  local actData = configManager.GetDataById("config_activity", self.activityId)
  local positions = actData.p3
  UIHelper.CreateSubPart(self.tab_Widgets.item_card, self.tab_Widgets.trans_right, ROLLTIME, function(index, tabPart)
    self.m_tabPartsInfo[index] = tabPart
    if CardsList ~= nil and 0 < #CardsList then
      if isShowAnimi then
        self:__PlayCardAnimiByState(index, tabPart, CardShow.Front, nil)
      end
      self:__ShowCommonCard(tabPart, CardsList[index])
    elseif isShowAnimi then
      self:__PlayCardAnimiByState(index, tabPart, CardShow.Back, nil)
    end
    tabPart.item_card.transform.anchoredPosition = Vector2.New(positions[index][1], positions[index][2])
  end)
end

function ActivityRollsPage:_ShowGetCards()
  self.tab_Widgets.obj_get:SetActive(self.m_pageState == State.GET)
  if self.m_pageState ~= State.GET then
    return
  end
  if next(Data.activityRollsData:GetData().SelectShipTeam.ShipId) == nil then
    logWarning("SelectShipTeam nil! ")
    return
  end
  self.actRollsInfo = Data.activityRollsData:GetData()
  local CardsList = self.actRollsInfo.SelectShipTeam.ShipId
  self:__ShowCommonCardsList(CardsList, self.tab_Widgets.trans_get_card, self.tab_Widgets.item_get_card)
end

function ActivityRollsPage:_ShowChooseCards()
  self.tab_Widgets.obj_choose:SetActive(self.m_pageState == State.CHOOSE)
  if self.m_pageState ~= State.CHOOSE then
    return
  end
  if next(Data.activityRollsData:GetData().SelectShipTeam.ShipId) == nil or next(Data.activityRollsData:GetData().SaveShipTeam.ShipId) == nil then
    logWarning("SelectShipTeam nil or SaveShipTeam nil!")
    return
  end
  self.actRollsInfo = Data.activityRollsData:GetData()
  local CardsListOld = self.actRollsInfo.SaveShipTeam.ShipId
  self:__ShowCommonCardsList(CardsListOld, self.tab_Widgets.trans_card_before, self.tab_Widgets.item_card_before)
  local CardsListNew = self.actRollsInfo.SelectShipTeam.ShipId
  self:__ShowCommonCardsList(CardsListNew, self.tab_Widgets.trans_card_after, self.tab_Widgets.item_card_after)
end

function ActivityRollsPage:_ShowTips()
  self.tab_Widgets.obj_tip:SetActive(self.m_pageState == State.TIPS)
  local txt = ""
  if self.m_curSelectTeam == ActivityRollsSelect.CHOOSE_SELECT_NEW then
    txt = UIHelper.GetString(4400008)
  elseif self.m_curSelectTeam == ActivityRollsSelect.CHOOSE_SAVE_OLD then
    txt = UIHelper.GetString(4400009)
  end
  UIHelper.SetText(self.tab_Widgets.tx_titleTips, txt)
  if self.m_pageState ~= State.TIPS then
    return
  end
end

function ActivityRollsPage:__ShowCommonCard(tabPart, heroTid)
  local itemInfo = ItemInfoPage.GenDisplayData(GoodsType.SHIP, heroTid)
  local shipShow = Logic.shipLogic:GetShipShowById(heroTid)
  local actData = configManager.GetDataById("config_activity", self.activityId)
  local QualityIconList = actData.p4
  UIHelper.SetImage(tabPart.im_girl, shipShow.ship_icon1)
  UIHelper.SetImage(tabPart.im_quality, QualityIconList[itemInfo.quality])
  UIHelper.SetText(tabPart.tx_name, itemInfo.name)
end

function ActivityRollsPage:__ShowCommonCardsList(CardsList, Content, Item)
  UIHelper.CreateSubPart(Item, Content, #CardsList, function(index, tabPart)
    if CardsList ~= nil and next(CardsList) ~= nil then
      self:__ShowCommonCard(tabPart, CardsList[index])
    end
  end)
end

function ActivityRollsPage:ChangePageState(state)
  self.m_pageState = state
end

function ActivityRollsPage:DoOnClose()
end

return ActivityRollsPage
