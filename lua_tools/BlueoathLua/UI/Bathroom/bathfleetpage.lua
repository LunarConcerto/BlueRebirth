local BathFleetPage = class("UI.Bathroom.BathFleetPage", LuaUIPage)
local bathHeroItem = require("ui.page.Bathroom.BathHeroItem")
local bathTimeControl = require("ui.page.Bathroom.BathTimeControl")
local LAYOUT_PREFERRED = 160
local ALL_BATH_POS = 6

function BathFleetPage:DoInit()
  self.bathHero = {}
  self.bathHeroPos = {}
  self.tabFleetData = nil
  self.lastTogIndex = nil
  self.togPart = {}
  self.m_saveTogInfo = nil
  self.absentBathHero = {}
  self.price = 0
  self.selectFleet = nil
  self.bathCost = 0
  self.HeroAndPosTab = {}
end

function BathFleetPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickBath, self)
  self:RegisterEvent(LuaEvent.BathStartAll, self._BathStartAllRet, self)
end

function BathFleetPage:DoOnOpen()
  local param = self:GetParam()[1]
  self.price = configManager.GetDataById("config_bathroom_item", 90001).price
  self.tabFleetData = Data.fleetData:GetFleetData()
  self:_CreateToggle()
  self:_SwitchTogs(1)
end

function BathFleetPage:_CreateToggle()
  local maxTogNum = Logic.fleetLogic:GetFleetNum(FleetType.Normal)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_tog, self.tab_Widgets.trans_togGroup, maxTogNum, function(nIndex, tabPart)
    tabPart.fleetIndex.text = nIndex
    UGUIEventListener.AddButtonOnClick(tabPart.btnSelect, function()
      self:_SwitchTogs(nIndex)
    end, self)
    table.insert(self.togPart, tabPart)
  end)
end

function BathFleetPage:_SwitchTogs(index)
  self.lastTogIndex = index
  local togItem = self.togPart[self.lastTogIndex]
  if self.m_saveTogInfo ~= nil then
    UIHelper.SetUILock(true)
    self.m_saveTogInfo[1].fleetIndex.text = self.m_saveTogInfo[2]
    self.m_saveTogInfo[1].objNormal:SetActive(false)
    self.m_saveTogInfo[1].tweenScale:Play(false)
    self.m_saveTogInfo[1].btnSelect.gameObject:SetActive(true)
    self.beforeTimer = FrameTimer.New(function()
      self:_RegainTogPos()
    end, self.m_saveTogInfo[1].tweenScale.duration, -1)
    self.beforeTimer:Start()
    self.co = coroutine.start(function()
      self:_RegainTog()
    end)
  else
    self:_TogTweenPlay(togItem)
    self:_RecordInfoLoadFleet()
  end
  togItem.btnSelect.gameObject:SetActive(false)
end

function BathFleetPage:_RegainTogPos()
  local m_rect = self.m_saveTogInfo[1].objSelect:GetComponent(RectTransform.GetClassType())
  local curWidth = m_rect.rect.width * m_rect.localScale.x
  if curWidth < LAYOUT_PREFERRED then
    self.m_saveTogInfo[1].layout.preferredWidth = m_rect.rect.width * m_rect.localScale.x
  end
end

function BathFleetPage:_RegainTog()
  if self.co ~= nil then
    coroutine.wait(self.m_saveTogInfo[1].tweenScale.duration, self.co)
  end
  if self.m_saveTogInfo ~= nil then
    self.beforeTimer:Stop()
    self.m_saveTogInfo[1].objSelect:SetActive(false)
    self.m_saveTogInfo[1].objNormal:SetActive(true)
    self.coSelect = coroutine.start(function()
      self:_TogSelect()
    end)
  end
end

function BathFleetPage:_TogSelect()
  if self.coSelect ~= nil then
    coroutine.wait(0.075, self.coSelect)
  end
  local togItem = self.togPart[self.lastTogIndex]
  self:_TogTweenPlay(togItem)
  self.curTimer = FrameTimer.New(function()
    self:_SelectTogPos(togItem)
  end, togItem.tweenScale.duration, -1)
  self.curTimer:Start()
end

function BathFleetPage:_SelectTogPos(togItem)
  local m_rect = togItem.objSelect:GetComponent(RectTransform.GetClassType())
  local curWidth = m_rect.rect.width * m_rect.localScale.x
  if curWidth > LAYOUT_PREFERRED then
    self.curTimer:Stop()
    self:_RecordInfoLoadFleet()
    UIHelper.SetUILock(false)
    return
  end
  togItem.layout.preferredWidth = curWidth
end

function BathFleetPage:_TogTweenPlay(togItem)
  togItem.fleetName.text = self.tabFleetData[self.lastTogIndex].tacticName
  togItem.objSelect:SetActive(true)
  togItem.objNormal:SetActive(false)
  togItem.tweenScale:Play()
end

function BathFleetPage:_ClearTogInfo()
  if self.co ~= nil then
    coroutine.stop(self.co)
  end
  if self.coSelect ~= nil then
    coroutine.stop(self.coSelect)
  end
end

function BathFleetPage:_RecordInfoLoadFleet()
  self:_LoadFleetCard()
  local togItem = self.togPart[self.lastTogIndex]
  togItem.layout.preferredWidth = LAYOUT_PREFERRED
  self.m_saveTogInfo = {
    togItem,
    self.lastTogIndex
  }
end

function BathFleetPage:_LoadFleetCard()
  self.selectFleet = self.tabFleetData[self.lastTogIndex].heroInfo
  self.m_fleetCardItem = {}
  local inBathHero = self:GetParam()[1]
  bathTimeControl:FleetSurplusTime()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_cardItem, self.tab_Widgets.trans_card, 6, function(nIndex, tabPart)
    local item = bathHeroItem:new()
    local fleetHeroInfo
    if next(self.selectFleet) == nil then
      fleetHeroInfo = nil
    else
      fleetHeroInfo = Data.heroData:GetHeroById(self.selectFleet[nIndex])
    end
    item:Init(self, tabPart, fleetHeroInfo, nIndex, inBathHero, bathTimeControl, nil)
  end)
  self.bathHeroPos = {}
  for _, v in pairs(inBathHero) do
    self.bathHero[v.HeroId] = v
    table.insert(self.bathHeroPos, v.Pos)
  end
  self.absentBathHero = {}
  for _, v in ipairs(self.selectFleet) do
    if not self.bathHero[v] then
      local heroData = Data.heroData:GetHeroById(v)
      table.insert(self.absentBathHero, heroData)
    else
      self.bathHero[v] = nil
    end
  end
  self.bathCost = 0
  self:_SetHeroInPos()
  self.tab_Widgets.tx_tips.text = string.format(UIHelper.GetString(300019), self.bathCost)
end

function BathFleetPage:_CheckBathCondition()
  if next(self.selectFleet) == nil then
    noticeManager:ShowTip(UIHelper.GetString(300016))
    return
  end
  if next(self.absentBathHero) == nil then
    noticeManager:ShowTip(UIHelper.GetString(300017))
    return
  end
  if Logic.forbiddenHeroLogic:CheckForbiddenHeroInTab(self.selectFleet, ForbiddenType.Bath) then
    return
  end
  local currEnough = Logic.currencyLogic:CheckCurrencyEnoughAndTips(13, self.bathCost)
  if not currEnough then
    return
  end
  for _, v in pairs(self.absentBathHero) do
    local inBuilding = Logic.buildingLogic:IsBuildingHero(v.HeroId)
    if inBuilding then
      local str = UIHelper.GetString(300018)
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_SendBathStartAll()
          end
        end
      }
      noticeManager:ShowMsgBox(str, tabParams)
      return
    end
  end
  self:_SendBathStartAll()
end

function BathFleetPage:_SetHeroInPos()
  table.sort(self.absentBathHero, function(data1, data2)
    return data1.Mood < data2.Mood
  end)
  self.HeroAndPosTab = {}
  for k, v in pairs(self.absentBathHero) do
    for i = 1, 6 do
      if not table.containV(self.bathHeroPos, i) then
        self.HeroAndPosTab[v.HeroId] = i
        self.bathCost = self.bathCost + self.price
        table.insert(self.bathHeroPos, i)
        break
      end
    end
  end
  local tab = {}
  if next(self.bathHero) ~= nil then
    for _, v in pairs(self.bathHero) do
      table.insert(tab, v)
    end
    table.sort(tab, function(data1, data2)
      return data1.Mood > data2.Mood
    end)
  end
  if next(tab) ~= nil then
    local index = 0
    for k, v in pairs(self.absentBathHero) do
      if not self.HeroAndPosTab[v.HeroId] then
        index = 1 + index
        self.HeroAndPosTab[v.HeroId] = tab[index].Pos
      end
    end
  end
end

function BathFleetPage:_SendBathStartAll()
  local bathTab = {}
  for i, v in pairs(self.HeroAndPosTab) do
    local infoTab = {HeroId = i, Pos = v}
    table.insert(bathTab, infoTab)
  end
  Logic.bathroomLogic:SetSvrStatus(4)
  Service.bathroomService:SendBathStartAll(bathTab)
end

function BathFleetPage:_ClickBath()
  self:_CheckBathCondition()
end

function BathFleetPage:_ClickClose()
  UIHelper.ClosePage("BathFleetPage")
end

function BathFleetPage:_BathStartAllRet()
  self:_ClickClose()
  noticeManager:ShowTip(UIHelper.GetString(300020))
end

function BathFleetPage:DoOnHide()
  bathTimeControl:StopFleetTimer()
end

function BathFleetPage:DoOnClose()
  bathTimeControl:StopFleetTimer()
  self:_ClearTogInfo()
  self.m_saveTogInfo = nil
end

return BathFleetPage
