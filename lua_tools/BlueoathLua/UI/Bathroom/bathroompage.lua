local BathRoomPage = class("UI.Bathroom.BathRoomPage", LuaUIPage)
local BathRoomScene = require("Game.GameState.Home.HomeBathRoomState")
local BathNotice = require("ui.page.Bathroom.BathNoticePage")
local bathGift = require("ui.page.Bathroom.BathGiftPage")
local bathTimeControl = require("ui.page.Bathroom.BathTimeControl")
local BathroomMsg = {
  Login = 0,
  Start = 1,
  Exchage = 2,
  Replace = 3,
  BathAll = 4
}
local m_dragRange = {
  maxX = 1.62,
  minX = -1.62,
  maxY = 0.77,
  minY = -0.27
}
local m_nudeModelPath = {
  "commonmodels/modelnaked/model_naked_child_001",
  "commonmodels/modelnaked/model_naked_primary_001",
  "commonmodels/modelnaked/model_naked_middle_001",
  "commonmodels/modelnaked/model_naked_senior_001",
  "commonmodels/modelnaked/model_naked_black_001"
}
local SprayPath = "effects/prefabs/eff3d_repair_spray"
local WaterWavePath = "effects/prefabs/eff3d_repair_waterwave"
local ExpPath = "effects/prefabs/ui/eff_bathroom_exp"
local StarPath = "effects/prefabs/ui/eff_bathroom_star"
local BATH_CURRENCY_ID = 13
local MAX_REPAIR = 6
local DRESSUP_ID = 999999
local PO_DRESSUP_ID = 999998
local TICKET_ID = 90001
local MODEL_OFFSET = 0.55

function BathRoomPage:DoInit()
  self.m_tabgirlinrepair = {}
  self.tab_Widgets.obj_root:SetActive(false)
  self.m_tabHaveHero = Data.heroData:GetHeroData()
  self.m_tabmodel = {}
  self.m_numRepair = 0
  self.m_co = nil
  self.m_buffTab = {}
  self.m_exchengInfo = {}
  self.selectShipPos = 0
  self.selectShip = nil
  self.m_startPos = 0
  self.openDetail = false
  self.stayTime = 0
  self.giftId = {}
  self.buffId = {}
  self.selectParam = nil
  self.btnDrag = nil
  self.isAllAuto = 0
  self.cameraMove = false
  self.tblParts = nil
  self.moodBound = configManager.GetDataById("config_parameter", 142).arrValue
  self.giftMoodValue = configManager.GetDataById("config_parameter", 220).value
  self.moodValue = configManager.GetDataById("config_parameter", 212).value
  self.status = -1
  self.startShipMood = 0
  bathGift:Init(self)
end

function BathRoomPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGift, function()
    bathGift:_ClickCloseGift()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fleet, self._ClickFleet, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_allAutoTicket, function()
    bathGift:_ClickAllAuto()
  end)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_auto, function()
    bathGift:_ClickAuto()
  end)
  self:RegisterEvent(LuaEvent.BathRoomShowUI, self._ShowUI)
  self:RegisterEvent(LuaEvent.BathRoomModelClick, self._OnClickGirlModel, self)
  self:RegisterEvent(LuaEvent.BathRoomDrag, self._OnDragMove, self)
  self:RegisterEvent(LuaEvent.BathRoomDragEnd, self._OnDragEnd, self)
  self:RegisterEvent(LuaEvent.BathroomInfo, self._UpdateBathHero, self)
  self:RegisterEvent(LuaEvent.BathEndOk, self._FinishBath, self)
  self:RegisterEvent(LuaEvent.BathroomFinish, self._CheckFinishBath, self)
  self:RegisterEvent(LuaEvent.BathRoomSelectModel, function(self, param)
    bathGift:_OnSelectModel(param)
  end)
  self:RegisterEvent(LuaEvent.BathRoomClickBlank, function()
    bathGift:_ClickCloseGift()
  end)
  self:RegisterEvent(LuaEvent.BathGiftOk, function(self, param)
    bathGift:_SendGiftRet(param)
  end)
  self:RegisterEvent(LuaEvent.BathAutoTicket, function()
    bathGift:_AutoTicketCallBack()
  end)
  self:RegisterEvent(LuaEvent.BathAllAuto, function()
    bathGift:_AllAutoCallBack()
  end)
  self:RegisterEvent(LuaEvent.BathCamMoveOver, function()
    bathGift:_CameraMoveOver()
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, function(self, notification)
    bathGift:_ShowSubtitle(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, function(self)
    bathGift:_CloseSubtitle()
  end)
  self:RegisterEvent(LuaEvent.BATH_ClickBathingCard, function(self, param)
    bathGift:_OnClickBathCard(param)
  end)
  self:RegisterEvent(LuaEvent.CloseBathFinish, function(self, param)
    self:_FinishRemoveModel(param)
  end)
  self:RegisterEvent(LuaEvent.BathStartAll, function(self, param)
    self:_BathStartAll(param)
  end)
  self:RegisterEvent(LuaEvent.BathStartAllFinish, self._OpenShowFinish, self)
end

function BathRoomPage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.BATHROOM
  })
  if UIPageManager:IsExistPage("ItemInfoPage") then
    UIHelper.ClosePage("ItemInfoPage")
  end
  self:OpenTopPage("BathRoomPage", 1, UIHelper.GetString(300008), self, true, function()
    Logic.bathroomLogic:IsOpenBathroom(false)
    UIHelper.Back()
  end, {
    {5, 13}
  })
  SoundManager.Instance:PlayAudio("SFX_Bathroom")
  self.tab_Widgets.obj_root:SetActive(true)
  BathNotice:Init(self)
  local state = PlayerPrefs.GetInt("BathHintState", 1)
  local recordTime = PlayerPrefs.GetInt("BathHintTime", 1)
  if state == 1 then
    local isSame = time.isSameDay(recordTime, os.time())
    state = isSame and 1 or 0
    PlayerPrefs.SetInt("BathHintState", state)
  end
  self.tab_Widgets.tog_hint.isOn = state == 1
end

function BathRoomPage:_UpdateBathHero()
  local bathroomInfo = Logic.bathroomLogic:GetBathHero()
  self.status = Logic.bathroomLogic:GetSvrStatus()
  if self.status == BathroomMsg.Login and next(self.m_tabgirlinrepair) == nil then
    self.m_numRepair = 0
    for k, v in pairs(bathroomInfo) do
      self:_AddShipModel(v, v.Pos)
      self.m_numRepair = self.m_numRepair + 1
      self.m_tabgirlinrepair[k] = v
    end
    self:_CheckFinishBath()
    if next(self.m_tabgirlinrepair) ~= nil then
      self.tab_Widgets.obj_redDot:SetActive(true)
    end
    self.isAllAuto = Data.bathroomData:GetAllAuto()
    bathTimeControl:AllAutoInPool(self.isAllAuto == 1)
    self.tab_Widgets.tog_allAutoTicket.isOn = self.isAllAuto == 1
    self.tab_Widgets.tog_auto.interactable = self.isAllAuto ~= 1
    if self.selectShipPos ~= 0 then
      BathRoomScene:ChangeCamera(self.selectShipPos)
      local selectShip = self.m_tabgirlinrepair[self.selectShipPos]
      bathGift.girlModel = self.m_tabmodel[selectShip.HeroId].girl
      bathGift:_RefreshGiftItem()
      bathGift:MoveBuffImage(true)
    end
  elseif self.status == BathroomMsg.Start then
    bathGift:_StopMoodEffTimer()
    self:_AddGirlModel()
  elseif self.status == BathroomMsg.Exchage then
    self:_ExchengGirlModel()
  elseif self.status == BathroomMsg.Replace then
    self:_ReplaceGirlModel(true)
  elseif self.status == BathroomMsg.BathAll then
    return
  end
  self:_RefreshBathData(bathroomInfo)
end

function BathRoomPage:_RefreshBathData(bathroomInfo)
  Logic.bathroomLogic:SetSvrStatus(-1)
  self.m_tabgirlinrepair = bathroomInfo
  Logic.repaireLogic:SetShipNum(self.m_numRepair)
  self:_RefreshHeroInfo()
end

function BathRoomPage:_CheckFinishBath()
  for k, v in pairs(self.m_tabgirlinrepair) do
    if v.StartTime == 0 and v.BathTime ~= 0 then
      Service.bathroomService:SendBathEnd(v.HeroId, v)
      local dotinfo = {
        info = "ui_bathing_finish",
        type = 0
      }
      RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      return
    end
  end
end

function BathRoomPage:_FinishBath(param)
  bathGift:_ClickCloseGift()
  UIHelper.ClosePage("BathFleetPage")
  UIHelper.OpenPage("BathDetailsPage", {param, 2})
end

function BathRoomPage:_FinishRemoveModel(param)
  UIHelper.SetUILock(true)
  local hero = param
  self:_RemoveShipModel(hero.HeroId)
  for i, v in pairs(self.m_tabgirlinrepair) do
    if v.HeroId == hero.HeroId then
      self.m_tabgirlinrepair[i] = nil
    end
  end
  self.m_numRepair = self.m_numRepair - 1
  Logic.repaireLogic:SetShipNum(self.m_numRepair)
  self:_RefreshHeroInfo()
  UIHelper.SetUILock(false)
end

function BathRoomPage:_OnClickCard(tabPart, shipInfo, clickIndex, originObj)
  if self.pop ~= nil then
    GameObject.Destroy(self.pop)
    self.m_isCardDrag = false
    if self.btnDrag ~= nil then
      self.btnDrag = nil
    end
  end
  if Logic.forbiddenHeroLogic:CheckForbiddenInSystem(shipInfo.HeroId, ForbiddenType.Bath) then
    return
  end
  local sameShipInPool, _, _ = Logic.repaireLogic:CheckSameShip(self.m_tabgirlinrepair, shipInfo)
  if sameShipInPool then
    return
  end
  self.pop = nil
  self.clickPos = clickIndex
  self.popShip = shipInfo
  local obj = tabPart.objSelf
  self.tab_Widgets.obj_float:SetActive(true)
  self.pop = UIHelper.CreateGameObject(tabPart.gameObject, self.tab_Widgets.tran_float)
  self.tab_Widgets.tran_float.position = obj.transform.position
  self.pop.transform.pivot = Vector2.New(0.5, 0.5)
  self.pop.transform.position = Vector3.New(obj.transform.position.x - 10, obj.transform.position.y - 10, 0)
  tabPart.objGolden:SetActive(true)
  tabPart.objMask:SetActive(true)
  local part = self.pop:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
  part.objGolden:SetActive(true)
  part.objMask:SetActive(false)
  if originObj then
    CSUIHelper.SetParent(originObj.transform, self.tab_Widgets.obj_outDrag.gameObject.transform)
    local objEvent = UIHelper.CreateGameObject(self.tab_Widgets.obj_sourceEvent, tabPart.objSelf.transform)
    objEvent.name = "obj_event"
    UGUIEventListener.AddButtonOnPointDown(objEvent, function()
      self:_OnClickCard(tabPart, shipInfo, clickIndex, objEvent)
    end)
    UGUIEventListener.AddButtonOnPointUp(objEvent, function()
      tabPart.objGolden:SetActive(false)
      tabPart.objMask:SetActive(false)
      if self.pop ~= nil then
        GameObject.Destroy(self.pop)
        self.tab_Widgets.obj_float:SetActive(false)
        self.pop = nil
      end
    end)
    UGUIEventListener.AddButtonOnClick(objEvent, function()
      eventManager:SendEvent(LuaEvent.BATH_ClickBathingCard, shipInfo)
    end, self)
    self:_AddCardDrag(tabPart, originObj, self.pop.transform, originObj:GetComponent(FixScrollDrag.GetClassType()), clickIndex, tabPart)
  end
  self.btnDrag = originObj
end

function BathRoomPage:_AddCardDrag(tabPart, objDrag, dragTran, fixDrag, nIndex)
  local orginTran = tabPart.btnDrag.gameObject.transform
  local thresholdOut = 80
  local bOut = false
  local fix = objDrag:GetComponent(FixScrollDrag.GetClassType())
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if IsNil(dragTran) then
      return
    end
    if self.tblParts[nIndex] ~= nil then
      orginTran = self.tblParts[nIndex].btnDrag.gameObject.transform
    end
    self.m_isCardDrag = true
    self.m_curDragTabPart = tabPart
    local dragPos = eventData.position
    local originPos = orginTran.position
    local dragLocalPos = dragTran.localPosition
    local originLocalPos = orginTran.localPosition
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    if not bOut and dragLocalPos.y - originLocalPos.y < thresholdOut then
      finalPos.x = originPos.x
    elseif not bOut then
      bOut = true
      fix:OnEndDrag(eventData)
      fix.bEnable = false
    end
    dragTran.position = finalPos
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    self.btnDrag = nil
    fix:OnEndDrag(eventData)
    fix.bEnable = true
  end, nil, nil)
end

function BathRoomPage:_OnDragMove(param)
  if self.m_isModelDrag then
    self.pop.transform.position = param
  end
end

function BathRoomPage:_OnDragEnd(param)
  if self.m_isModelDrag then
    self.m_isModelDrag = false
    self:_OnModelDragEnd(param)
  end
  if self.m_isCardDrag then
    self:_OnCardDragEnd(param)
    self.m_isCardDrag = false
  end
end

function BathRoomPage:_OnModelDragEnd(param)
  local pos = param.pos
  if pos.x <= m_dragRange.maxX and pos.x >= m_dragRange.minX and pos.y <= m_dragRange.maxY and pos.y >= m_dragRange.minY then
    if self.m_modelIndex ~= param.index and param.index ~= 0 then
      local putPosShip = self.m_tabgirlinrepair[param.index]
      local dragPosShip = self.m_tabgirlinrepair[self.m_modelIndex]
      self.m_exchengInfo = {
        putShip = putPosShip,
        putPonit = param.index,
        dragShip = dragPosShip,
        dragPonit = self.m_modelIndex
      }
      Logic.bathroomLogic:SetSvrStatus(BathroomMsg.Exchage)
      Service.bathroomService:SendBathStart(dragPosShip.HeroId, param.index)
    else
      self:_HideShipModel(self.m_tabgirlinrepair[self.m_modelIndex].HeroId, true)
    end
  else
    local dragPosShip = self.m_tabgirlinrepair[self.m_modelIndex]
    bathGift:_ClickOpenFinish(dragPosShip)
  end
  self:_DestroyPop()
end

function BathRoomPage:_ExchengGirlModel()
  if self.m_exchengInfo.putShip ~= nil then
    local dragModelInfo = self.m_tabmodel[self.m_exchengInfo.dragShip.HeroId]
    local putModelInfo = self.m_tabmodel[self.m_exchengInfo.putShip.HeroId]
    self:_HideShipModel(self.m_exchengInfo.putShip.HeroId, false)
    bathGift:_ExchangeBuff(self.m_exchengInfo.putShip, self.m_exchengInfo.dragShip, {
      self.m_exchengInfo.putPonit,
      self.m_exchengInfo.dragPonit
    })
    self:_ExchangeModel(dragModelInfo, self.m_exchengInfo.putPonit)
    self:_ExchangeModel(putModelInfo, self.m_exchengInfo.dragPonit)
  else
    self:_RemoveShipModel(self.m_exchengInfo.dragShip.HeroId)
    self:_AddShipModel(self.m_exchengInfo.dragShip, self.m_exchengInfo.putPonit)
  end
  SoundManager.Instance:PlayAudio("Effect_Eff_Bathroom_inwater")
end

function BathRoomPage:_ReplaceGirlModel(refreshHero)
  local position = self.m_startPos
  local oldShip = self.m_tabgirlinrepair[position]
  local newShip = clone(self.popShip)
  newShip.BuffId = oldShip.BuffId
  newShip.BuffTime = oldShip.BuffTime
  newShip.StartTime = oldShip.StartTime
  self.m_tabgirlinrepair[position] = newShip
  self.m_buffTab[newShip.HeroId] = clone(self.m_buffTab[oldShip.HeroId])
  local img_buff = self.m_buffTab[oldShip.HeroId].image
  if img_buff ~= nil then
    GameObject.Destroy(img_buff)
  end
  self.m_buffTab[oldShip.HeroId] = nil
  self:_RemoveShipModel(oldShip.HeroId)
  self:_AddShipModel(newShip, position)
  if refreshHero then
    self:_RefreshHeroInfo()
  end
  local oldShipName = Logic.shipLogic:GetShipInfoById(oldShip.TemplateId).ship_name
  local newShipName = Logic.shipLogic:GetShipInfoById(newShip.TemplateId).ship_name
  local dotinfo = {
    info = "ui_change",
    quit_name = oldShipName,
    entry_name = newShipName
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BathRoomPage:_ExchangeModel(modelInfo, index)
  modelInfo.girl.transform:SetParent(self.m_tabModelPos[index], false)
  modelInfo.eff.transform:SetParent(self.m_tabModelPos[index], false)
  modelInfo.expEff.transform:SetParent(self.m_tabModelPos[index], false)
  modelInfo.starEff.transform:SetParent(self.m_tabModelPos[index], false)
  self:_HideShipModel(self.m_tabgirlinrepair[index].HeroId, true)
end

function BathRoomPage:_OnCardDragEnd(param)
  self.m_curDragTabPart.objMask:SetActive(false)
  self.m_curDragTabPart.objGolden:SetActive(false)
  self.m_curDragTabPart = nil
  local finalPos = param.pos
  local index = param.index
  self:_UpdateRepairGirl(finalPos, index)
end

function BathRoomPage:_OnAddRepairGirl(targetPos)
  self.m_tabgirlinrepair[targetPos] = self.popShip
  self:_AddShipModel(self.popShip, targetPos)
  local ship = Logic.shipLogic:GetShipInfoById(self.popShip.TemplateId)
  local dotinfo = {
    info = "ui_bathing_ship",
    ship_name = ship.ship_name
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BathRoomPage:_RefreshHeroInfo()
  eventManager:SendEvent(LuaEvent.UpdateHeroItem, {
    otherParam = self.m_tabgirlinrepair,
    heroTab = self.m_tabHaveHero
  })
  for i = 0, self.tab_Widgets.obj_outDrag.transform.childCount - 1 do
    local child = self.tab_Widgets.obj_outDrag.transform:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
end

function BathRoomPage:_DestroyPop()
  if self.pop ~= nil then
    GameObject.Destroy(self.pop)
    self.tab_Widgets.obj_float:SetActive(false)
    self.pop = nil
  end
end

function BathRoomPage:_UpdateRepairGirl(objPos, index)
  if objPos.x <= m_dragRange.maxX and objPos.x >= m_dragRange.minX and objPos.y <= m_dragRange.maxY and objPos.y >= m_dragRange.minY then
    self.m_startPos, oldShip = self:_GetModelPos(index)
    local inBuilding = Logic.buildingLogic:IsBuildingHero(self.popShip.HeroId)
    local inOutpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpost(self.popShip.HeroId)
    if inBuilding then
      local str = UIHelper.GetLocString(300014)
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_NextCheck()
          end
        end
      }
      noticeManager:ShowMsgBox(str, tabParams)
      return
    end
    if inOutpost then
      local str = UIHelper.GetLocString(4600020)
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            self:_NextCheck()
          end
        end
      }
      noticeManager:ShowMsgBox(str, tabParams)
      return
    end
    self:_NextCheck()
  end
end

function BathRoomPage:_NextCheck()
  if oldShip then
    local oldShipName = Logic.shipLogic:GetRealName(oldShip.HeroId)
    local newShipName = Logic.shipLogic:GetRealName(self.popShip.HeroId)
    local str = UIHelper.GetLocString(300013, oldShipName, newShipName)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_BathReplace(oldShip, self.popShip.HeroId)
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
  elseif self.m_numRepair < MAX_REPAIR then
    self:_BathStartCheck(function()
      self:_BathStart()
    end)
  else
    noticeManager:ShowTip(UIHelper.GetString(300001))
  end
  self:_DestroyPop()
end

function BathRoomPage:_BathStartCheck(callback)
  if not self.tab_Widgets.tog_hint.isOn then
    local cost = configManager.GetDataById("config_bathroom_item", TICKET_ID).price
    local str = UIHelper.GetLocString(300011, cost)
    BathNotice:OpenNotice(str, function()
      callback()
    end)
  else
    callback()
  end
end

function BathRoomPage:_BathReplace(oldHero, newHeroId)
  Logic.bathroomLogic:SetSvrStatus(BathroomMsg.Replace)
  Service.bathroomService:SendBathReplace(oldHero.HeroId, newHeroId, oldHero)
end

function BathRoomPage:_BathStart()
  local cost = configManager.GetDataById("config_bathroom_item", TICKET_ID).price
  local currEnough = Logic.currencyLogic:CheckCurrencyEnoughAndTips(BATH_CURRENCY_ID, cost)
  if not currEnough then
    return
  elseif self.m_startPos == 0 then
    logError("\230\148\190\231\189\174\231\154\132\228\189\141\231\189\174\230\156\137\233\151\174\233\162\152\239\188\154 " .. self.m_startPos)
  else
    Logic.bathroomLogic:SetSvrStatus(BathroomMsg.Start)
    self.startShipMood = self.popShip.Mood
    Service.bathroomService:SendBathStart(self.popShip.HeroId, self.m_startPos)
  end
end

function BathRoomPage:_AddGirlModel()
  self:_OnAddRepairGirl(self.m_startPos)
  self.m_numRepair = self.m_numRepair + 1
  Logic.repaireLogic:SetShipNum(self.m_numRepair)
end

function BathRoomPage:_AddShipModel(shipInfo, modelPos)
  local ship = Logic.shipLogic:GetShipShowByHeroId(shipInfo.HeroId)
  local shipModel = configManager.GetDataById("config_ship_model", ship.model_id)
  local headType = shipModel.head_type
  self.m_tabmodel[shipInfo.HeroId] = {}
  local createParam = {
    showID = ship.ss_id,
    dressID = shipModel.standard_bathroom,
    enableHeadLook = false
  }
  local shipgirl = GR.shipGirlManager:createShipGirlDirBehaviour(createParam, 0, self.m_tabModelPos[modelPos], "bath_loop")
  local scal = shipModel.scale_bathroom
  shipgirl:setModelScale(Vector3.New(scal, scal, scal))
  local girlObj = shipgirl.gameObject
  local girlpos = shipModel.position_y_bathroom
  girlObj.transform.localPosition = Vector3.New(0, girlpos, 0)
  local shipPos = self.m_tabModelPos[modelPos].transform.position
  self.m_buffTab[shipInfo.HeroId] = {}
  self.m_buffTab[shipInfo.HeroId].pos = BathRoomScene:GetScreenPoint(Vector3.New(shipPos.x, shipPos.y + MODEL_OFFSET, shipPos.z))
  self.m_buffTab[shipInfo.HeroId].modelIndex = modelPos
  bathGift:_ShowBathGift(shipInfo, false)
  self.m_tabmodel[shipInfo.HeroId].girl = shipgirl
  local sprayObj = GR.objectPoolManager:LuaGetGameObject(SprayPath)
  self.m_tabmodel[shipInfo.HeroId].eff = sprayObj
  sprayObj.transform:SetParent(self.m_tabModelPos[modelPos].transform, false)
  local expEff = GR.objectPoolManager:LuaGetGameObject(ExpPath)
  expEff.transform:SetParent(self.m_tabModelPos[modelPos].transform, false)
  self.m_tabmodel[shipInfo.HeroId].expEff = expEff
  local starEff = GR.objectPoolManager:LuaGetGameObject(StarPath)
  starEff.transform:SetParent(self.m_tabModelPos[modelPos].transform, false)
  self.m_tabmodel[shipInfo.HeroId].starEff = starEff
  local m_EffectCo = coroutine.start(function()
    coroutine.wait(2, m_EffectCo)
    if self.m_tabmodel[shipInfo.HeroId] then
      GR.objectPoolManager:LuaUnspawnAndDestory(sprayObj)
      local waterWaveObj = GR.objectPoolManager:LuaGetGameObject(WaterWavePath)
      waterWaveObj.transform:SetParent(self.m_tabModelPos[modelPos].transform, false)
      self.m_tabmodel[shipInfo.HeroId].eff = waterWaveObj
    end
  end)
  SoundManager.Instance:PlayAudio("Effect_Eff_Bathroom_inwater")
end

function BathRoomPage:_RemoveShipModel(heroId)
  if self.m_tabmodel[heroId] then
    GR.shipGirlManager:destroyShipGirl(self.m_tabmodel[heroId].girl)
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_tabmodel[heroId].eff)
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_tabmodel[heroId].expEff)
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_tabmodel[heroId].starEff)
    self.m_tabmodel[heroId] = nil
  end
  if self.m_buffTab[heroId] then
    local img_buff = self.m_buffTab[heroId].image
    if img_buff ~= nil then
      GameObject.Destroy(img_buff)
    end
    self.m_buffTab[heroId] = nil
  end
end

function BathRoomPage:_HideShipModel(heroId, active)
  if self.m_tabmodel[heroId] then
    self.m_tabmodel[heroId].girl.gameObject:SetActive(active)
    self.m_tabmodel[heroId].eff:SetActive(active)
    self.m_tabmodel[heroId].expEff:SetActive(active)
    self.m_tabmodel[heroId].starEff:SetActive(active)
  end
  if self.m_buffTab[heroId].image then
    local img_buff = self.m_buffTab[heroId].image
    img_buff.gameObject:SetActive(active)
  end
end

function BathRoomPage:_OnClickGirlModel(param)
  if self.selectShipPos ~= 0 then
    return
  end
  self.tab_Widgets.obj_select:SetActive(false)
  local index = param.index
  local pos = param.pos
  if self.m_tabgirlinrepair[index] then
    local modelInfo = self.m_tabgirlinrepair[index]
    if self.m_buffTab[modelInfo.HeroId].image then
      local buff = self.m_buffTab[modelInfo.HeroId].image
      buff.gameObject:SetActive(false)
    end
    self.m_modelIndex = index
    if self.pop ~= nil then
      GameObject.Destroy(self.pop)
    end
    self.pop = nil
    self.tab_Widgets.obj_float:SetActive(true)
    self.pop = UIHelper.CreateGameObject(self.tab_Widgets.obj_ReapireFleet, self.tab_Widgets.tran_float)
    self.tab_Widgets.tran_float.position = Vector3.New(0, 0, 0)
    self.pop.transform.position = pos
    self.pop:SetActive(true)
    local luaPart = self.pop:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
    local heroInfo = Logic.attrLogic:GetHeroFianlAttrById(self.m_tabgirlinrepair[index].HeroId)
    local curHp = Logic.shipLogic:GetHeroHp(self.m_tabgirlinrepair[index].HeroId)
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroInfo[AttrType.HP])
    UIHelper.SetImage(luaPart.im_hp, NewCardHpStatus[hpStatus + 1])
    ShipCardItem:LoadVerticalCard(self.m_tabgirlinrepair[index].HeroId, luaPart.childpart, VerCardType.FleetBottom)
    luaPart.slider_hp.value = curHp / heroInfo[AttrType.HP]
    luaPart.txt_level.text = math.tointeger(self.m_tabgirlinrepair[index].Lvl)
    luaPart.objGolden:SetActive(true)
    luaPart.objMask:SetActive(false)
    local hero = Data.heroData:GetHeroById(self.m_tabgirlinrepair[index].HeroId)
    UIHelper.CreateSubPart(luaPart.obj_stars, luaPart.trans_stars, hero.Advance, function(nIndex, part)
    end)
    self.m_isModelDrag = true
    self:_HideShipModel(self.m_tabgirlinrepair[index].HeroId, false)
  end
end

function BathRoomPage:_GetModelPos(index)
  if self.m_tabgirlinrepair[index] then
    return index, self.m_tabgirlinrepair[index]
  end
  if index == 0 then
    for i = 1, MAX_REPAIR do
      if not self.m_tabgirlinrepair[i] then
        return i, nil
      end
    end
  end
  return index, nil
end

function BathRoomPage:_ShowUI()
  local objScene = BathRoomScene:GetSceneObj()
  if not IsNil(objScene) then
    self.m_tabModelPos = {}
    for i = 1, MAX_REPAIR do
      self.m_tabModelPos[i] = objScene.transform:Find("POS/POS_00" .. i).transform
    end
  end
  Service.bathroomService:SendGetBathroomInfo()
  self:OpenSubPage("CommonHeroPage", {
    self,
    CommonHeroItem.BathRoom,
    self.m_tabHaveHero,
    self.m_tabgirlinrepair,
    notSaveSort = true
  }, nil, false)
  local bagInfo = Logic.bagLogic:ItemInfoById(TICKET_ID)
  local itemNum = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  local userData = Data.userData:GetUserData()
  local currencyNum = userData.Bath == nil and 0 or math.tointeger(userData.Bath)
  local dotinfo = {
    info = "ui_bathing",
    currency_num = currencyNum,
    item_num = itemNum
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.stayTime = time.getSvrTime()
  Logic.bathroomLogic:IsOpenBathroom(true)
  self.tab_Widgets.obj_allAuto:SetActive(true)
end

function BathRoomPage:DoOnHide()
  if self.stayTime ~= 0 then
    bathGift:_StopMoodEffTimer()
    self.m_tabgirlinrepair = {}
    for k, v in pairs(self.m_tabmodel) do
      self:_RemoveShipModel(k)
    end
    self.m_tabmodel = {}
    eventManager:SendEvent(LuaEvent.HomeSwitchState, {
      HomeStateID.MAIN,
      HomeStateID.BATHROOM
    })
    if self.m_co then
      coroutine.stop(self.m_co)
      self.m_co = nil
    end
    Logic.bathroomLogic:SetSvrStatus(BathroomMsg.Login)
  end
  self.stayTime = 0
  UIHelper.ClosePage("BathFleetPage")
end

function BathRoomPage:DoOnClose()
  Logic.bathroomLogic:BathStatistics({
    bathInfo = self.m_tabgirlinrepair,
    gift = self.giftId,
    buff = self.buffId,
    time = self.stayTime
  })
  bathGift:_StopMoodEffTimer()
  for k, v in pairs(self.m_tabmodel) do
    self:_RemoveShipModel(k)
  end
  self.m_tabmodel = {}
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.BATHROOM
  })
  if self.m_co then
    coroutine.stop(self.m_co)
    self.m_co = nil
  end
  Logic.bathroomLogic:SetSvrStatus(BathroomMsg.Login)
end

function BathRoomPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 300010})
end

function BathRoomPage:onRectRefresh(tblParts)
  self.tblParts = tblParts
end

function BathRoomPage:_ClickFleet()
  UIHelper.OpenPage("BathFleetPage", {
    self.m_tabgirlinrepair
  })
end

function BathRoomPage:_BathStartAll(param)
  self.endHeroInfo = param.EndHeroData
  local allHeroId = param.AllHeroId
  for _, v in ipairs(allHeroId) do
    self.m_startPos = v.Pos
    self.popShip = Data.heroData:GetHeroById(v.HeroId)
    if self.m_tabgirlinrepair[v.Pos] then
      self:_ReplaceGirlModel(false)
    else
      bathGift:_StopMoodEffTimer()
      self:_AddGirlModel()
    end
  end
  self:_RefreshBathData(Logic.bathroomLogic:GetBathHero())
  self:_OpenShowFinish()
end

function BathRoomPage:_OpenShowFinish()
  for i, v in pairs(self.endHeroInfo) do
    v.endType = BathEndType.AllBath
    v.heroInfo = Data.heroData:GetHeroById(v.HeroId)
    BathRoomPage:_FinishBath(v)
    table.remove(self.endHeroInfo, i)
    return
  end
end

return BathRoomPage
