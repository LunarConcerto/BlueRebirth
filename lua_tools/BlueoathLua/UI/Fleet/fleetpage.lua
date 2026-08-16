local FleetPage = class("UI.Fleet.FleetPage", LuaUIPage)
local fleetCardItem = require("ui.page.Fleet.FleetCardItem")
local FleetHomePage = require("ui.page.Fleet.FleetHomePage")
local FleetTrainPage = require("ui.page.Fleet.FleetTrainPage")
local FleetTrainLvPage = require("ui.page.Fleet.FleetTrainLvPage")
local FleetTowerPage = require("ui.page.Fleet.FleetTowerPage")
local POP_OFFSET = -10
local ShowBack = false
local LAYOUT_PREFERRED = 160
local SubPage = {
  FleetHomePage,
  FleetTrainPage,
  FleetTrainLvPage,
  FleetTowerPage
}

function FleetPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_popObj = nil
  self.m_tabFleetData = {}
  self.m_onFleetShip = {}
  self.m_lastTogIndex = nil
  self.m_popShip = nil
  self.m_bNeedSave = false
  self.m_bUpdatePos = false
  self.m_clickPos = 0
  self.m_onFleetTid = {}
  self.m_isClickAttack = false
  self.m_fleetCardItem = {}
  self.fleetSweepData = {}
  self.m_isNeedRefreshSweepData = false
  self.isClickCard = true
  self.lastPos = nil
  self.curPos = nil
  self.togPart = {}
  self.m_saveTogInfo = nil
  self.btnDrag = nil
  self.m_tabHero = {}
  self.m_heroData = {}
  self.m_recordModelId = {}
  self.m_rectTranArr = {}
  self.fleetToGirlInfo = false
  self.updateTog = false
  self.isLevelOpen = false
  self.fleetType = 0
  self.copyInfo = nil
  self.m_battleMode = BattleMode.Normal
  UIHelper.SetUILock(true)
  local tweenMiddle = self.m_tabWidgets.tween_middle
  tweenMiddle:SetOnFinished(self.SetUILock)
  tweenMiddle:Play(true)
end

function FleetPage:DoOnOpen()
  if not self.fleetToGirlInfo then
    npcAssistFleetMgr:Clear()
  end
  if Data.copyData:GetMatchingState() then
    noticeManager:ShowTip(UIHelper.GetString(6100012))
    Data.copyData:SetMatchingState(false)
    local arg = {
      uid = Data.userData:GetUserData().Uid
    }
    Service.matchService:SendMatchLeave(arg)
  end
  local curTog = Logic.fleetLogic:GetSelectTog()
  if self.m_lastTogIndex ~= curTog then
    self.m_lastTogIndex = curTog
    self.updateTog = true
  end
  local params = self:GetParam()
  self.subType = params and params.subType or FleetSubType.Home
  self.fleetType = params and params.fleetType or FleetType.Normal
  self.m_tabWidgets.btn_history.gameObject:SetActive(Logic.towerLogic:IsTowerType(self.fleetType))
  self.copyInfo = params and params.copyInfo or nil
  self.copyId = self.copyInfo and self.copyInfo.copyId or 0
  self.chapterId = self.copyInfo and self.copyInfo.chapterId or 0
  self.fleetImp = SubPage[self.subType]:new()
  self.fleetImp:Init(self)
  self.fleetImp:RegisterAllEvent()
  self:_CreateToggle()
  if params ~= nil then
    self.isLevelOpen = params.isLevelOpen and true or false
  end
  self.fleetImp:DoOnOpen(self.isLevelOpen)
  local record = PlayerPrefs.GetInt("fleetShowBack", 0)
  ShowBack = record == 1
  self:_InitFleet()
  if self.updateTog then
    self:_SwitchTogs(self.m_lastTogIndex)
    self.updateTog = false
  else
    self:_LoadFleetCard(self.m_lastTogIndex)
    eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
      otherParam = self.m_tabFleetData
    })
  end
  local dotInfo = {
    info = "ui_ship_team"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.INTO_FLEET_UI)
  eventManager:SendEvent(LuaEvent.FleetOpen)
  self:_ShowExercisesPart()
  self:showPreset()
  self:ShowSweepingCopyInfo()
end

function FleetPage:onRectRefresh(tblParts)
  self.tblParts = tblParts
end

function FleetPage:SetUILock()
  UIHelper.SetUILock(false)
end

function FleetPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.CloseStrategy, self._InitFleet, self)
  self:RegisterEvent(LuaEvent.GetFleetMsg, self._InitFleet, self)
  self:RegisterEvent(LuaEvent.CloseLeftPage, self._ClosePage, self)
  self:RegisterEvent(LuaEvent.StartSweepCopy, self.ReceiveMsg, self)
  self:RegisterEvent("getRepaireMsg", self._RefreshFleet, self)
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._OnUpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateFleetSweepInfo, self._UpdateSweepInfo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closePage, self._ClosePage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_overturn, self._ClickOverturn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_exercises, self._ClickExercises, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_presetfleetpage, self._ClickPresetFleet, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_history, self.btn_history, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, function(self, param)
    self:_DestoryFloat()
  end)
end

function FleetPage:_DestoryFloat()
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    self.m_tabWidgets.obj_float:SetActive(false)
    self.m_popObj = nil
    self.m_bUpdatePos = false
    local item = self.m_fleetCardItem[self.lastPos]
    if item ~= nil then
      item.tabPart.objGolden:SetActive(false)
      item.tabPart.objMask:SetActive(false)
      item.tabPart.obj_white:SetActive(false)
    end
    if not UIPageManager:IsExistPage("CommonHeroPage") then
      eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
        otherParam = self.m_tabFleetData
      })
    end
  end
end

function FleetPage:_InitFleet()
  self.fleetImp:_InitFleet()
  self:_ShowStrategy()
end

function FleetPage:_CreateToggle()
  self.fleetImp:_CreateToggle()
end

function FleetPage:_ShowStrategy()
  local strategyId = 0
  if self.subType ~= FleetSubType.Train then
    strategyId = Data.fleetData:GetStrategyDataById(self.m_lastTogIndex, self.fleetType)
  else
    strategyId = self.m_tabFleetData[1].strategyId
  end
  local widgets = self:GetWidgets()
  local strategyName = UIHelper.GetString(980007)
  local strategyTips = ""
  if 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    strategyName = strategyConfig.strategy_name
    strategyTips = Logic.strategyLogic:GetStrategyTips(strategyId)
  end
  UIHelper.SetText(widgets.txtStrategyName, strategyName)
  UIHelper.SetText(widgets.txtStrategyTips, strategyTips)
  local conditionRes = Logic.strategyLogic:CheckConditionByFleet(self.m_lastTogIndex, self.fleetType)
  widgets.objStrategyTips:SetActive(0 < strategyId and not conditionRes)
  widgets.objStrategyOk:SetActive(0 < strategyId and conditionRes)
  self:RegisterRedDot(widgets.redDotStrategy, self.m_lastTogIndex, self.fleetType)
end

function FleetPage:_SwitchTogs(index)
  self.m_tabHero = {}
  self.m_lastTogIndex = index
  self:_ShowStrategy()
  local togItem = self.togPart[self.m_lastTogIndex]
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
  Logic.fleetLogic:SetSelectTog(self.m_lastTogIndex)
end

function FleetPage:_RegainTogPos()
  local m_rect = self.m_saveTogInfo[1].objSelect:GetComponent(RectTransform.GetClassType())
  local curWidth = m_rect.rect.width * m_rect.localScale.x
  if curWidth < LAYOUT_PREFERRED then
    self.m_saveTogInfo[1].layout.preferredWidth = m_rect.rect.width * m_rect.localScale.x
  end
end

function FleetPage:_RegainTog()
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

function FleetPage:_TogSelect()
  if self.coSelect ~= nil then
    coroutine.wait(0.075, self.coSelect)
  end
  local togItem = self.togPart[self.m_lastTogIndex]
  self:_TogTweenPlay(togItem)
  self.curTimer = FrameTimer.New(function()
    self:_SelectTogPos(togItem)
  end, togItem.tweenScale.duration, -1)
  self.curTimer:Start()
end

function FleetPage:_SelectTogPos(togItem)
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

function FleetPage:_TogTweenPlay(togItem)
  togItem.fleetName.text = self.m_tabFleetData[self.m_lastTogIndex].tacticName
  togItem.objSelect:SetActive(true)
  togItem.objNormal:SetActive(false)
  togItem.tweenScale:Play()
end

function FleetPage:_ClearTogInfo()
  if self.co ~= nil then
    coroutine.stop(self.co)
  end
  if self.coSelect ~= nil then
    coroutine.stop(self.coSelect)
  end
end

function FleetPage:_ClosePage()
  if self.fleetImp._ClosePage then
    self.fleetImp:_ClosePage()
  end
  eventManager:SendEvent(LuaEvent.SaveHeroSort)
  eventManager:SendEvent(LuaEvent.HomePageOtherPageClose)
  eventManager:SendEvent(LuaEvent.RefreshMatchState)
  UIHelper.ClosePage("CommonHeroPage")
  UIHelper.ClosePage(self:GetName())
end

function FleetPage:_ClickOverturn()
  for i = 1, #self.m_fleetCardItem do
    local item = self.m_fleetCardItem[i]
    item:TurnCard(ShowBack)
  end
  ShowBack = not ShowBack
  if ShowBack then
    PlayerPrefs.SetInt("fleetShowBack", 1)
  else
    PlayerPrefs.SetInt("fleetShowBack", 0)
  end
end

function FleetPage:GetFleetPos(objPos, camera)
  for i, v in ipairs(self.m_rectTranArr) do
    if v:RectangleContainsScreenPoint(objPos, camera) then
      return i
    end
  end
  return nil
end

function FleetPage:_DragCard(objPos, camera)
  local widgets = self:GetWidgets()
  self.isClickCard = false
  local pos = self:GetFleetPos(objPos, camera)
  self:_PlayTween()
  if not widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
    self:_PlayTween()
  else
    local item = self.m_fleetCardItem[pos]
    if item ~= nil and item.tabPart.txt_hint.enabled then
      item.tabPart.objGolden:SetActive(true)
      item.tabPart.objMask:SetActive(true)
      item.tabPart.obj_white:SetActive(true)
      self.lastPos = pos
    end
  end
end

function FleetPage:_PlayTween()
  if self.lastPos ~= nil and self.m_clickPos ~= self.lastPos then
    local item = self.m_fleetCardItem[self.lastPos]
    item.tabPart.objGolden:SetActive(false)
    item.tabPart.objMask:SetActive(false)
    item.tabPart.obj_white:SetActive(false)
  end
end

function FleetPage:_UpdateFleet(objPos, camera)
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    self.m_tabWidgets.obj_float:SetActive(false)
    self.m_popObj = nil
  end
  local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.m_lastTogIndex, self.fleetType)
  if fleetIsSweeping then
    self:_PlayTween()
    local showText = string.format(UIHelper.GetString(960000032))
    noticeManager:OpenTipPage(self, showText)
    return
  end
  self:_SetFleetPos(objPos, camera)
end

function FleetPage:_SetFleetPos(objPos, camera)
  local widgets = self:GetWidgets()
  if self.m_bUpdatePos then
    self.m_bNeedSave = true
    if not self.m_recordModelId[self.m_lastTogIndex] then
      self.m_recordModelId[self.m_lastTogIndex] = self.m_lastTogIndex
    end
    local heroInfo = self.m_tabFleetData[self.m_lastTogIndex].heroInfo
    if not widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
      self:_RemoveHero(heroInfo)
      self:_ChangeShipEnd()
    else
      self.curPos = self:GetFleetPos(objPos, camera)
      local isEmpty = heroInfo[self.curPos] == nil
      if self.fleetImp.CanAddCard and not self.fleetImp:CanAddCard(not isEmpty) and isEmpty then
        self:_ChangeShipEnd()
        return
      end
      if self.curPos == nil then
        self:_ChangeShipEnd()
        return
      end
      local onOtherFleet = Logic.fleetLogic:CheckOnOtherFleet(self.m_popShip.HeroId, self.m_onFleetShip)
      if onOtherFleet then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemove()
            else
              self:_CancelRemove()
            end
          end
        }
        noticeManager:ShowMsgBox(200002, tabParams)
        return
      else
        self:SetPosShip()
      end
    end
  end
  self.m_bUpdatePos = false
end

function FleetPage:SetPosShip()
  local heroInfo = self.m_tabFleetData[self.m_lastTogIndex].heroInfo
  if heroInfo[self.curPos] ~= nil then
    self:_PosOccupy(heroInfo, self.curPos)
  else
    self:_PosNotOccupy(heroInfo)
  end
  self:_ChangeShipEnd()
end

function FleetPage:_ChangeShipEnd()
  self:_LoadFleetCard(self.m_lastTogIndex)
  eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
    otherParam = self.m_tabFleetData
  })
  Logic.fleetLogic:SetImageFleetShip(self.m_tabFleetData, self.fleetType)
  self:_ShowStrategy()
  if self.fleetImp.OnFleetChanged then
    self.fleetImp:OnFleetChanged()
  end
  Logic.fleetLogic:SetCommonHeroData(nil)
  for i = 0, self.m_tabWidgets.obj_outDrag.transform.childCount - 1 do
    local child = self.m_tabWidgets.obj_outDrag.transform:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
end

function FleetPage:_ConfirmRemove()
  for i = 1, #self.m_tabFleetData do
    local heroInfo = self.m_tabFleetData[i].heroInfo
    for j = 1, #heroInfo do
      if heroInfo[j] == self.m_popShip.HeroId then
        heroInfo[j] = nil
        break
      end
    end
    local temp = {}
    for _, v in pairs(heroInfo) do
      table.insert(temp, v)
    end
    self.m_tabFleetData[i].heroInfo = temp
  end
  self.m_onFleetTid = Logic.fleetLogic:RemoveFleetTid(self.m_onFleetTid, self.m_popShip.HeroId)
  self:SetPosShip()
end

function FleetPage:_CancelRemove()
  self:_ChangeShipEnd()
end

function FleetPage:_RemoveHero(heroInfo)
  if self.fleetImp.CanRemoveCard and not self.fleetImp:CanRemoveCard(self.m_popShip.HeroId) then
    return
  end
  if self.isLevelOpen and self.fleetImp.RemoveCard and not self.fleetImp:RemoveCard(self.m_onFleetShip) then
    noticeManager:OpenTipPage(self, 921003)
    return
  end
  for i = 1, #heroInfo do
    if heroInfo[i] == self.m_popShip.HeroId then
      table.remove(heroInfo, i)
    end
  end
  local curTogFleetHero = self.m_onFleetShip[self.m_lastTogIndex]
  if curTogFleetHero[self.m_popShip.HeroId] ~= nil then
    curTogFleetHero[self.m_popShip.HeroId] = nil
    self.m_onFleetTid = Logic.fleetLogic:RemoveFleetTid(self.m_onFleetTid, self.m_popShip.HeroId, self.m_lastTogIndex)
    self.m_onFleetShip = Logic.fleetLogic:RemoveFleetHero(self.m_onFleetShip, self.m_popShip.HeroId)
    self.curPos = #heroInfo + 1
    local item = self.m_fleetCardItem[self.curPos]
    self.m_onFleetShip[self.m_lastTogIndex] = curTogFleetHero
    SoundManager.Instance:PlayAudio("UI_jianniang_out")
  end
end

function FleetPage:_PlaySound()
  SoundManager.Instance:PlayAudio("UI_Tween_FleetPage_0006")
end

function FleetPage:_PosOccupy(heroInfo, pos)
  local befShip = heroInfo[pos]
  local hero = Data.heroData:GetHeroById(befShip)
  local isGuide = Logic.fleetLogic:GetGuideFlag()
  if isGuide and hero.TemplateId == 10210511 then
    return
  end
  if Logic.fleetLogic:CheckOnSameFleet(self.m_onFleetShip[self.m_lastTogIndex], self.m_popShip.HeroId) then
    heroInfo[pos] = self.m_popShip.HeroId
    heroInfo[self.m_clickPos] = befShip
    self:_PlaySound()
  else
    self.m_onFleetTid, inFleet = Logic.fleetLogic:CheckFleetTid(self.m_onFleetTid, self.m_popShip.HeroId)
    if inFleet then
      noticeManager:OpenTipPage(self, 110009)
      self.m_onFleetShip = Logic.fleetLogic:RemoveFleetHero(self.m_onFleetShip, self.m_popShip.HeroId)
    else
      heroInfo[pos] = self.m_popShip.HeroId
      self.m_onFleetTid = Logic.fleetLogic:RemoveFleetTid(self.m_onFleetTid, befShip, self.m_lastTogIndex)
      self.m_onFleetShip = Logic.fleetLogic:RemoveFleetHero(self.m_onFleetShip, self.m_popShip.HeroId)
      local curTogFleetHero = self.m_onFleetShip[self.m_lastTogIndex]
      if curTogFleetHero[befShip] ~= nil then
        curTogFleetHero[befShip] = nil
      end
      curTogFleetHero[self.m_popShip.HeroId] = self.m_lastTogIndex
      self.m_onFleetShip[self.m_lastTogIndex] = curTogFleetHero
      self:_PlaySound()
    end
  end
end

function FleetPage:_UpdateSweepInfo()
  self:ShowSweepingCopyInfo()
end

function FleetPage:_PosNotOccupy(heroInfo)
  self.m_onFleetTid, inFleet = Logic.fleetLogic:CheckFleetTid(self.m_onFleetTid, self.m_popShip.HeroId)
  if inFleet then
    if Logic.fleetLogic:CheckOnSameFleet(self.m_onFleetShip[self.m_lastTogIndex], self.m_popShip.HeroId) then
      noticeManager:OpenTipPage(self, 110014)
    else
      noticeManager:OpenTipPage(self, 110009)
    end
    self.m_bUpdatePos = false
    self.curPos = nil
    self.m_onFleetShip = Logic.fleetLogic:RemoveFleetHero(self.m_onFleetShip, self.m_popShip.HeroId)
    return
  else
    self.curPos = #heroInfo + 1
    local item = self.m_fleetCardItem[self.curPos]
    table.insert(heroInfo, self.m_popShip.HeroId)
    self.m_onFleetShip = Logic.fleetLogic:RemoveFleetHero(self.m_onFleetShip, self.m_popShip.HeroId)
    self.m_onFleetShip[self.m_lastTogIndex][self.m_popShip.HeroId] = self.m_lastTogIndex
    self:_PlaySound()
  end
end

function FleetPage:_RecordInfoLoadFleet()
  self:_LoadFleetCard(self.m_lastTogIndex)
  Logic.fleetLogic:SetSelectTog(self.m_lastTogIndex)
  eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
    otherParam = self.m_tabFleetData
  })
  local togItem = self.togPart[self.m_lastTogIndex]
  togItem.layout.preferredWidth = LAYOUT_PREFERRED
  self.m_saveTogInfo = {
    togItem,
    self.m_lastTogIndex
  }
  self:ShowSweepingCopyInfo()
end

function FleetPage:_LoadFleetCard(toggeIndex, isShowEffect)
  local fleetInfo = self.m_tabFleetData[toggeIndex].heroInfo
  local firstEmptyPos = true
  self.m_fleetCardItem = {}
  self.m_rectTranArr = {}
  self.m_tabHero = {}
  local totalCount = self.m_tabFleetData[toggeIndex].totalCount or 6
  local totalAttack = 0
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cardItem, self.m_tabWidgets.trans_card, 6, function(nIndex, tabPart)
    local heroId = fleetInfo[nIndex]
    table.insert(self.m_tabHero, heroId)
    if heroId ~= nil then
      local heroAttr = Logic.attrLogic:GetBattlePower(heroId, self.fleetType, self.copyId)
      totalAttack = totalAttack + heroAttr
    end
    local showText = false
    if heroId == nil and firstEmptyPos then
      firstEmptyPos = false
      showText = true
    end
    local item = fleetCardItem:new()
    item:Init(self, nIndex, heroId, tabPart, toggeIndex, showText, self.curPos, ShowBack, self.m_tabHero, nIndex > totalCount, self.chapterId)
    self.m_fleetCardItem[nIndex] = item
    self.m_rectTranArr[nIndex] = tabPart.rectTranSelf
    if heroId then
      local recommendTbl = self:GetRecommend()
      local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(heroId)
      tabPart.recommend:SetActive(recommendTbl[shipInfoId])
    else
      tabPart.recommend:SetActive(false)
    end
  end)
  self.curPos = nil
  self.m_tabWidgets.txt_attack.text = totalAttack
end

function FleetPage:OnDragCard(tabPart, shipInfo, clickIndex, originObj, type)
  if type == FleetCardType.FleetCard then
    local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.m_lastTogIndex, self.fleetType)
    if fleetIsSweeping then
      local showText = string.format(UIHelper.GetString(960000032))
      noticeManager:OpenTipPage(self, showText)
      return
    end
  elseif type == FleetCardType.FleetHeroCard then
    local onOtherFleet, fleetId = Logic.fleetLogic:CheckIsOnFleet(shipInfo.HeroId, self.m_onFleetShip)
    if onOtherFleet then
      local isSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(fleetId, self.fleetType)
      if isSweeping then
        local showText = string.format(UIHelper.GetString(960000032))
        noticeManager:OpenTipPage(self, showText)
        return
      end
    end
  end
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    if self.btnDrag ~= nil then
      self.btnDrag = nil
      self.m_bUpdatePos = false
    end
  end
  local onFleetSameTId = Logic.fleetLogic:CheckOnFleetSameFId(self.m_tabFleetData, shipInfo.TemplateId)
  local _, heroInFleetIndex = Logic.fleetLogic:GetCurFleetName(self.m_tabFleetData, shipInfo.HeroId)
  if originObj and (onFleetSameTId or self.m_lastTogIndex == heroInFleetIndex) then
    return
  end
  self.m_popObj = nil
  self.m_popShip = shipInfo
  self.m_clickPos = clickIndex
  self.m_tabWidgets.obj_float:SetActive(true)
  local obj = tabPart.objSelf
  self.m_popObj = UIHelper.CreateGameObject(tabPart.gameObject, self.m_tabWidgets.tran_float)
  self.m_tabWidgets.tran_float.position = obj.transform.position
  self.m_popObj.transform.pivot = Vector2.New(0.5, 0.5)
  self.m_popObj.transform.position = Vector3.New(obj.transform.position.x + POP_OFFSET, obj.transform.position.y + POP_OFFSET, 0)
  tabPart.objGolden:SetActive(true)
  tabPart.objMask:SetActive(true)
  local part = self.m_popObj:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
  part.objGolden:SetActive(false)
  part.objMask:SetActive(false)
  if originObj then
    CSUIHelper.SetParent(originObj.transform, self.m_tabWidgets.obj_outDrag.gameObject.transform)
    self:AddHeroDrag(originObj, self.m_popObj.transform, tabPart.fixDrag, clickIndex, tabPart)
  else
    tabPart.obj_white:SetActive(true)
    part.obj_white:SetActive(false)
    self:AddCardDrag(tabPart.objCopy, self.m_popObj.transform)
  end
  self.btnDrag = tabPart.objCopy
  self.m_bUpdatePos = true
end

function FleetPage:AddHeroDrag(objDrag, dragTran, fixDrag, nIndex, tabPart)
  local orginTran = tabPart.btnDrag.gameObject.transform
  local thresholdOut = 60
  local bOut = false
  local fix = objDrag:GetComponent(FixScrollDrag.GetClassType())
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if self.m_popObj == nil or IsNil(dragTran) then
      return
    end
    if self.tblParts[nIndex] ~= nil then
      orginTran = self.tblParts[nIndex].btnDrag.gameObject.transform
    end
    local dragPos = eventData.position
    local originPos = orginTran.position
    local dragLocalPos = dragTran.localPosition
    local originLocalPos = orginTran.localPosition
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    if not bOut and dragLocalPos.y - originLocalPos.y < thresholdOut then
      worldPos.x = originPos.x
    elseif not bOut then
      bOut = true
      fix:OnEndDrag(eventData)
      fix:StopMove()
      fix.bEnable = false
    end
    dragTran.position = worldPos
    self:_DragCard(dragPos, camera)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    local camera = eventData.pressEventCamera
    local finalPos = eventData.position
    self:_UpdateFleet(finalPos, camera)
    fix:OnEndDrag(eventData)
    fix.bEnable = true
  end, nil, nil)
end

function FleetPage:AddCardDrag(objDrag, dragTran)
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if self.m_popObj == nil or IsNil(dragTran) then
      return
    end
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    dragTran.position = worldPos
    self:_DragCard(dragPos, camera)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    local camera = eventData.pressEventCamera
    local dragPos = eventData.position
    self:_UpdateFleet(dragPos, camera)
  end, nil, nil)
end

function FleetPage:OnClickCard(tabPart, param, index, heroData)
  local isGuide = Logic.fleetLogic:GetGuideFlag()
  self.m_heroData = heroData
  if isGuide then
    self.btnDrag = nil
    eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
      otherParam = self.m_tabFleetData
    })
    return
  end
  if self.isClickCard then
    if index ~= nil then
      tabPart.objGolden:SetActive(true)
    end
    self:_StartTimer(param)
  end
  self.isClickCard = true
end

function FleetPage:_StartTimer(param)
  local m_timer = self:CreateTimer(function()
    self:_OpenGirlInfo(param)
  end, 0.05, 1, false)
  self:StartTimer(m_timer)
end

function FleetPage:_OpenGirlInfo(param)
  self.fleetImp:_OpenGirlInfo(param, self.m_heroData)
end

function FleetPage:ShowSweepingCopyInfo()
  self.m_isNeedRefreshSweepData = false
  self.m_desConfInfo = {}
  local fleetIsSweeping, fleetSweepData = Logic.copyLogic:FleetIsSweepingCopy(self.m_lastTogIndex, self.fleetType)
  self.fleetSweepData = fleetSweepData
  self.m_tabWidgets.obj_autobattle:SetActive(false)
  self.localTimer = {}
  if fleetIsSweeping then
    self.m_desConfInfo = configManager.GetDataById("config_copy_display", fleetSweepData.copyId)
    local timeNow = time.getSvrTime()
    self:SetSweepCopyCountName(self.m_tabWidgets.sweep_times, fleetSweepData)
    self:SweepCopyRemianTime(self.m_tabWidgets.sweep_time, fleetSweepData)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_jumpsweep, function()
      self.m_isNeedRefreshSweepData = true
      local configInfo, copyType = Logic.copyLogic:GetCopyTypeByChapterId(self.fleetSweepData.chaperId)
      if copyType ~= 0 then
        if copyType == Logic.copyLogic.SelectCopyType.DailyCopy then
          local groupId = configManager.GetDataById("config_chapter", self.fleetSweepData.chaperId)
          UIHelper.OpenPage("DailyCopyDetailPage", {
            dailyGroupId = groupId.dailygroup_id
          })
        else
          UIHelper.OpenPage("CopyPage", {
            selectCopy = Logic.copyLogic.SelectCopyType.SeaCopy,
            chapterId = self.fleetSweepData.chaperId,
            SelectedChapIndex = self.fleetSweepData.chaperId
          })
        end
      else
        local activityConfig = configManager.GetMultiDataByKeyValue("config_activity", "audobattle_chapter", self.fleetSweepData.chaperId)
        local openActivityId
        for i = 1, #activityConfig do
          if activityConfig[i].type == 29 and PeriodManager:IsInPeriod(activityConfig[i].period) then
            openActivityId = activityConfig[i].id
          end
        end
        if openActivityId == nil then
          logError("\230\180\187\229\138\168\230\156\137\233\151\174\233\162\152\230\136\150\232\128\133\231\130\185\229\135\187\230\151\182\233\151\180\230\156\137\233\151\174\233\162\152\239\188\140", activityConfig, ",activityid", openActivityId)
          local showText = string.format(UIHelper.GetString(960000024))
          noticeManager:OpenTipPage(self, showText)
        else
          UIHelper.OpenPage("ActivityCopyPage", {activityId = openActivityId})
        end
      end
    end, self)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, self._ClickStopSweepOption, self)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.sweep_btn_finish, self._ClickFinishSweepCopy, self)
    self:StopAllTimer()
    local timer = self:CreateTimer(function()
      self:SweepCopyRemianTime(self.m_tabWidgets.sweep_time, fleetSweepData)
    end, 1, -1, false)
    self:StartTimer(timer)
  else
    self:StopAllTimer()
  end
  self.m_tabWidgets.obj_autobattle:SetActive(fleetIsSweeping)
end

function FleetPage:_ClickStopSweepOption()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_ClickFinishSweepCopy()
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(960000029), tabParams)
end

function FleetPage:_ClickFinishSweepCopy()
  local config = {
    fleetId = self.fleetSweepData.fleetId,
    copyId = self.fleetSweepData.copyId,
    sweepCounts = 1
  }
  Service.copyService:StopSweepCopy(config)
end

function FleetPage:SetSweepCopyCountName(txt, data)
  local timeNow = time.getSvrTime()
  if timeNow > data.endTime then
    timeNow = data.endTime
    self.m_tabWidgets.sweep_copyname.text = string.format(UIHelper.GetString(960000028))
    self.m_tabWidgets.sweep_obj_finish:SetActive(true)
    self.m_tabWidgets.sweep_obj_cancel:SetActive(false)
  else
    self.m_tabWidgets.sweep_copyname.text = self.m_desConfInfo.name
    self.m_tabWidgets.sweep_obj_finish:SetActive(false)
    self.m_tabWidgets.sweep_obj_cancel:SetActive(true)
  end
  local passTime = timeNow - data.startTime
  local count, _ = math.modf(passTime / self.m_desConfInfo.autobattle_time)
  txt.text = count .. "/" .. data.sweepCounts
end

function FleetPage:SweepCopyRemianTime(txt, data)
  local timeNow = time.getSvrTime()
  local duringTime = data.endTime - timeNow
  self:SetSweepCopyCountName(self.m_tabWidgets.sweep_times, data)
  if duringTime < 0 then
    UIHelper.SetText(txt, UIHelper.GetCountDownStr(0))
    self:StopAllTimer()
  else
    local showTime = duringTime % self.m_desConfInfo.autobattle_time
    UIHelper.SetText(txt, UIHelper.GetCountDownStr(showTime))
  end
end

function FleetPage:DoOnHide()
  self:_ClearTogInfo()
  self:_DestoryFloat()
  self.fleetImp:DoOnHide()
  self:UnregisterAllRedDotEvent()
  UIHelper.ClosePage("CommonHeroPage")
  Logic.fleetLogic:SetImageFleetShip(nil)
end

function FleetPage:DoOnClose()
  UIHelper.SetUILock(false)
  self:_ClearTogInfo()
  self.m_saveTogInfo = nil
  Logic.fleetLogic:SetImageFleetShip(nil)
  if self.fleetImp.DoOnClose then
    self.fleetImp:DoOnClose()
  end
end

function FleetPage:GetRecommend()
  return self:GetRecommendByFleet(self.m_lastTogIndex)
end

function FleetPage:GetRecommendByFleet(fleetId)
  local strategyId = self:GetStrategyId()
  local recommendTbl = {}
  if 0 < strategyId then
    local strategyConfig = configManager.GetDataById("config_strategy", strategyId)
    local recommend = strategyConfig.recommend
    for i, v in pairs(recommend) do
      recommendTbl[v] = true
    end
  end
  return recommendTbl
end

function FleetPage:GetStrategyId()
  return self:GetStrategyIdByFleet(self.m_lastTogIndex)
end

function FleetPage:GetStrategyIdByFleet(fleetId)
  return self.m_tabFleetData[fleetId] and self.m_tabFleetData[fleetId].strategyId or 0
end

function FleetPage:CanEventDataCreate(eventData)
  local bGuideCanDrag = GR.guideHub:getGuideCachedata():IsFleetCanDrag()
  if bGuideCanDrag then
    return true
  else
    local delta = eventData.delta
    return delta.y > 10 and delta.x < 3 and delta.x > -3
  end
end

function FleetPage:_ClickExercises()
  self.copyInfo.exercises = BattleMode.Exercises
  if self.fleetImp._ClickAttack then
    self.fleetImp:_ClickAttack(BattleMode.Exercises)
  end
end

function FleetPage:_ShowExercisesPart()
  if self.copyId == 0 then
    self.m_tabWidgets.obj_exercises:SetActive(false)
    return
  end
  local displayConfig = Logic.copyLogic:GetCopyDesConfig(self.copyId)
  self.m_tabWidgets.obj_exercises:SetActive(displayConfig.exercises_point ~= -1 and displayConfig.is_match == 0)
end

function FleetPage:_RefreshFleet()
  self:_LoadFleetCard(self.m_lastTogIndex)
end

function FleetPage:showPreset()
  local userInfo = Data.userData:GetUserData()
  local curLevel = userInfo.Level
  local presetInfo = configManager.GetDataById("config_function_info", 59)
  local lookLevel = presetInfo.lookLevel
  if Logic.towerLogic:IsTowerType(self.fleetType) then
    self.m_tabWidgets.btn_presetfleetpage.gameObject.transform.localPosition = Vector3.New(-227.4, 205, 0)
  else
    self.m_tabWidgets.btn_presetfleetpage.gameObject.transform.localPosition = Vector3.New(58.5, 205, 0)
  end
  self.m_tabWidgets.btn_presetfleetpage.gameObject:SetActive(curLevel >= lookLevel and not Logic.towerLogic:IsTowerType(self.fleetType))
end

function FleetPage:_ClickPresetFleet()
  local fleetIndex = self.m_lastTogIndex
  eventManager:SendEvent(LuaEvent.Preset_2_Fleet)
  UIHelper.OpenPage("PresetFleetPage", {
    index = fleetIndex,
    fleetsInfo = self.m_tabFleetData,
    fleetType = self.fleetType
  })
end

function FleetPage:btn_history()
  local fleetIndex = self.m_lastTogIndex
  UIHelper.OpenPage("HistoryFleetPage", {
    index = fleetIndex,
    copyId = self.copyId,
    chapterId = self.chapterId,
    fleetType = self.fleetType
  })
end

function FleetPage:_OnUpdateHero()
  if ShowBack then
    self:_LoadFleetCard(self.m_lastTogIndex)
    eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
      otherParam = self.m_tabFleetData
    })
  end
end

function FleetPage:OnClickFirstGirl()
  local objFirstItem = self.m_fleetCardItem[1]
  self:OnClickCard(objFirstItem.tabPart, objFirstItem.heroInfo.HeroId, nil, objFirstItem.heroTab)
end

return FleetPage
