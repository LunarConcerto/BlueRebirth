local BathGiftPage = class("UI.Bathroom.BathGiftPage")
local BathRoomScene = require("Game.GameState.Home.HomeBathRoomState")
local BathTimeControl = require("ui.page.Bathroom.BathTimeControl")
local BathNotice = require("ui.page.Bathroom.BathNoticePage")
local parent
local MODEL_OFFSET = 0.53
local BATH_CURRENCY_ID = 13

function BathGiftPage:Init(page)
  parent = page
  self.widgetsTab = page.tab_Widgets
  self.girlModel = nil
  self.playingBehaviour = false
  self.currMoodSlider = 0
  self.currMoodNum = 0
  self.showMValueTimer = nil
  self.showMSliderTimer = nil
  self.openMEffTimer = nil
  self.giftMoveTimer = nil
end

function BathGiftPage:_OnSelectModel(param)
  self.widgetsTab.obj_crit:SetActive(false)
  SoundManager.Instance:PlayAudio("UI_Button_BathGiftPage_0003")
  if parent.cameraMove then
    return
  end
  if parent.m_tabgirlinrepair[param.index] == nil then
    self:_ClickCloseGift()
    return
  end
  if param.index == parent.selectShipPos or parent.openDetail then
    if self.girlModel ~= nil and not self.playingBehaviour then
      self:_PlayBathClick()
    end
    parent.openDetail = parent.openDetail == true and false
    return
  end
  self:_StopMoodEffTimer()
  self.widgetsTab.obj_moodUp:SetActive(false)
  self.widgetsTab.btn_fleet.gameObject:SetActive(false)
  BathRoomScene:ChangeCamera(param.index)
  self:MoveBuffImage(true)
  if self.girlModel then
    self.playingBehaviour = false
    self.girlModel:playBehaviour("bath_loop", true)
  end
  parent.selectShip = parent.m_tabgirlinrepair[param.index]
  BathTimeControl:SetDetailsTime(parent.selectShip, self.widgetsTab.txt_surplusTime)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_finish, function()
    self:_ClickOpenFinish(parent.selectShip)
  end)
  if parent.isAllAuto == 1 then
    self.widgetsTab.tog_auto.isOn = true
  else
    self.widgetsTab.tog_auto.isOn = parent.selectShip.IsAuto == 1
  end
  self:SetDetailsCard()
  self.widgetsTab.obj_addMoodEff:SetActive(false)
  self.widgetsTab.obj_select:SetActive(false)
  parent.selectShipPos = param.index
  self.widgetsTab.obj_gift:SetActive(true)
  self.widgetsTab.obj_bathPart:SetActive(false)
  self:_RefreshGiftItem()
end

function BathGiftPage:_OnClickBathCard(heroId)
  local findIndex = function(data, id)
    for index, info in pairs(data) do
      if id == info.HeroId then
        return index
      end
    end
    return 0
  end
  local index = findIndex(parent.m_tabgirlinrepair, heroId)
  if 0 < index then
    self:_OnSelectModel({index = index})
  end
end

function BathGiftPage:_RefreshGiftItem()
  if parent.selectShipPos == 0 then
    return
  end
  local giftConfig, likeGift = Logic.bathroomLogic:GetGiftList(parent.selectShip.TemplateId)
  eventManager:SendEvent(LuaEvent.SaveHeroSort)
  eventManager:SendEvent(LuaEvent.UpdateCommonPage, {
    self,
    CommonHeroItem.Goods,
    giftConfig,
    likeGift
  })
end

function BathGiftPage:_ClickCloseGift()
  if parent.selectShipPos == 0 or parent.cameraMove then
    return
  end
  self:_StopMoodEffTimer()
  self:_CloseSubtitle()
  self.playingBehaviour = false
  if self.girlModel then
    self.girlModel:playBehaviour("bath_loop", true)
    self.girlModel = nil
  end
  BathRoomScene:ChangeCamera(0)
  self:MoveBuffImage(true)
  parent.selectShipPos = 0
  self.widgetsTab.obj_gift:SetActive(false)
  self.widgetsTab.obj_bathPart:SetActive(true)
  self.widgetsTab.obj_select:SetActive(false)
  eventManager:SendEvent(LuaEvent.UpdateCommonPage, {
    parent,
    CommonHeroItem.BathRoom,
    parent.m_tabHaveHero,
    parent.m_tabgirlinrepair,
    notSaveSort = true
  })
  BathTimeControl:ClearDetailsTime()
  self.widgetsTab.obj_moodUp:SetActive(true)
  self.widgetsTab.btn_fleet.gameObject:SetActive(true)
end

function BathGiftPage:_ClickGift(tabPart, giftInfo)
  self.widgetsTab.obj_crit:SetActive(false)
  if not self.widgetsTab.tog_hint.isOn then
    local cost = configManager.GetDataById("config_gift", giftInfo.id).price
    local str = string.format(UIHelper.GetString(300012), cost[3])
    BathNotice:OpenNotice(str, function()
      self:_SendGift(giftInfo)
    end)
  else
    self:_SendGift(giftInfo)
  end
end

function BathGiftPage:_SendGift(giftInfo)
  local cost = configManager.GetDataById("config_gift", giftInfo.id).price
  local currEnough = Logic.currencyLogic:CheckCurrencyEnoughAndTips(BATH_CURRENCY_ID, cost[3])
  if not currEnough then
    return
  end
  self:_StopMoodEffTimer()
  Service.bathroomService:SendBathService(parent.selectShip.HeroId, giftInfo.id)
  local dotinfo = {
    info = "ui_bathing_gift"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  if parent.giftId[parent.selectShipPos] == nil then
    parent.giftId[parent.selectShipPos] = {}
    table.insert(parent.giftId[parent.selectShipPos], giftInfo.id)
  else
    table.insert(parent.giftId[parent.selectShipPos], giftInfo.id)
  end
end

function BathGiftPage:_SendGiftRet(param)
  if parent.buffId[param.Pos] == nil then
    parent.buffId[param.Pos] = {}
    table.insert(parent.buffId[param.Pos], math.tointeger(param.BuffId))
  else
    table.insert(parent.buffId[param.Pos], math.tointeger(param.BuffId))
  end
  local shipInfo = parent.m_tabgirlinrepair[param.Pos]
  shipInfo.BuffId = param.BuffId
  if param.IsCrit == 1 then
    self.widgetsTab.obj_crit:SetActive(true)
  end
  self:_ShowBathGift(shipInfo)
  self:SetDetailsCard()
end

function BathGiftPage:_ShowBathGift(shipInfo, showTip)
  showTip = showTip == nil and true or showTip
  local buffInfo = parent.m_buffTab[shipInfo.HeroId]
  local shipPos = parent.m_tabModelPos[buffInfo.modelIndex].transform.position
  local pos = BathRoomScene:GetScreenPoint(Vector3.New(shipPos.x, shipPos.y + MODEL_OFFSET, shipPos.z))
  if parent.status == 1 then
    parent.status = -1
    self.currMoodNum = parent.startShipMood
    self.currMoodSlider = self.currMoodNum / parent.moodBound[2]
    self:_PlayAddMoodEff(pos, shipInfo.HeroId, parent.moodValue)
    return
  end
  if not shipInfo.BuffId or shipInfo.BuffId == 0 then
    return
  end
  local buffConfig = configManager.GetDataById("config_value_effect", shipInfo.BuffId)
  if 0 > shipInfo.BuffTime + buffConfig.time - time.getSvrTime() then
    return
  end
  if showTip then
    local str = string.format(UIHelper.GetString(300015), math.floor(parent.giftMoodValue / 10000))
    local tipPos = Vector3.New(0, -0.15, 0)
    noticeManager:ShowTip(str .. buffConfig.desc, tipPos)
  end
  local img_buff
  if buffInfo.image ~= nil then
    img_buff = buffInfo.image
    self:_PlayAddMoodEff(pos, shipInfo.HeroId, parent.giftMoodValue)
  else
    local createBuff = UIHelper.CreateGameObject(self.widgetsTab.obj_buff, self.widgetsTab.trans_buffList)
    if parent.selectShipPos ~= 0 then
      createBuff.transform.position = Vector3.New(pos.x, pos.y, 0)
      if showTip then
        self:_PlayAddMoodEff(pos, shipInfo.HeroId, parent.giftMoodValue)
      end
    else
      createBuff.transform.position = Vector3.New(buffInfo.pos.x, buffInfo.pos.y, 0)
    end
    createBuff:SetActive(true)
    local targetPos = parent.m_tabModelPos[buffInfo.modelIndex].transform.position
    buffInfo.posDep = Vector3.New(targetPos.x, targetPos.y + MODEL_OFFSET, targetPos.z)
    img_buff = createBuff.gameObject:GetComponent(UIImage.GetClassType())
    buffInfo.image = img_buff
  end
  UIHelper.SetImage(img_buff, buffConfig.buff_icon, true)
end

function BathGiftPage:_ExchangeBuff(putModel, dragCard, param)
  local putBuff = parent.m_buffTab[putModel.HeroId]
  local dragBuff = parent.m_buffTab[dragCard.HeroId]
  local putPos = Vector3.New(dragBuff.pos.x, putBuff.pos.y, 0)
  local dragPos = Vector3.New(putBuff.pos.x, dragBuff.pos.y, 0)
  local img_buff2 = putBuff.image
  if img_buff2 ~= nil then
    img_buff2.gameObject.transform.position = Vector3.New(putPos.x, putPos.y, 0)
    img_buff2.gameObject:SetActive(true)
    local targetPos2 = parent.m_tabModelPos[param[2]].transform.position
    putBuff.posDep = Vector3.New(targetPos2.x, targetPos2.y + MODEL_OFFSET, targetPos2.z)
  end
  local img_buff1 = dragBuff.image
  if img_buff1 ~= nil then
    img_buff1.gameObject.transform.position = Vector3.New(dragPos.x, dragPos.y, 0)
    img_buff1.gameObject:SetActive(true)
    local targetPos1 = parent.m_tabModelPos[param[1]].transform.position
    dragBuff.posDep = Vector3.New(targetPos1.x, targetPos1.y + MODEL_OFFSET, targetPos1.z)
  end
  parent.m_buffTab[putModel.HeroId].pos = putPos
  parent.m_buffTab[dragCard.HeroId].pos = dragPos
  parent.m_buffTab[putModel.HeroId].modelIndex = param[2]
  parent.m_buffTab[dragCard.HeroId].modelIndex = param[1]
end

function BathGiftPage:_ClickOpenFinish(dragInfo)
  local param = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_BathEnd(dragInfo)
      else
        self:_CancelBathEnd(dragInfo)
      end
    end
  }
  local shipName = Logic.shipLogic:GetRealName(dragInfo.HeroId)
  local str = string.format(UIHelper.GetString(300004), shipName)
  noticeManager:ShowMsgBox(str, param, UILayer.ATTENTION)
end

function BathGiftPage:_BathEnd(dragInfo)
  local dotinfo = {
    info = "ui_bathing_finish",
    type = 1
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  if parent.selectShipPos ~= 0 then
    self:_ClickCloseGift()
  end
  self.girlModel = nil
  Service.bathroomService:SendBathEnd(dragInfo.HeroId, dragInfo)
end

function BathGiftPage:_CancelBathEnd(dragInfo)
  parent:_HideShipModel(dragInfo.HeroId, true)
end

function BathGiftPage:_ClickAllAuto()
  if self.widgetsTab.tog_allAutoTicket.isOn then
    parent.isAllAuto = 1
  else
    parent.isAllAuto = 0
  end
  Service.bathroomService:SendAllAuto(parent.isAllAuto)
end

function BathGiftPage:_AllAutoCallBack()
  BathTimeControl:AllAutoInPool(parent.isAllAuto == 1)
  self.widgetsTab.tog_allAutoTicket.isOn = parent.isAllAuto == 1
  self.widgetsTab.tog_auto.interactable = parent.isAllAuto ~= 1
  parent:_RefreshHeroInfo()
  parent.autoStatus = parent.isAllAuto
  self:_AutoTicketCallBack()
end

function BathGiftPage:_ClickAuto()
  if parent.isAllAuto == 1 then
    noticeManager:ShowMsgBox("\230\181\180\229\174\164\229\164\132\228\186\142\229\133\168\233\131\168\232\135\170\229\138\168\231\187\173\232\180\185\230\168\161\229\188\143\239\188\140\230\154\130\230\151\182\230\151\160\230\179\149\230\137\167\232\161\140\230\173\164\230\147\141\228\189\156\227\128\130")
    return
  end
  if self.widgetsTab.tog_auto.isOn then
    parent.autoStatus = 1
  else
    parent.autoStatus = 0
  end
  Service.bathroomService:SendBathAuto(parent.selectShip.HeroId, parent.autoStatus)
end

function BathGiftPage:_AutoTicketCallBack()
  self.widgetsTab.tog_auto.isOn = parent.autoStatus == 1
  if parent.selectShipPos ~= 0 then
    parent.selectShip.IsAuto = parent.autoStatus
  end
  parent:_RefreshHeroInfo()
end

function BathGiftPage:SetDetailsCard()
  local heroId = parent.selectShip.HeroId
  ShipCardItem:LoadVerticalCard(heroId, self.widgetsTab.verticalCard, VerCardType.FleetBottom)
  local moodInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
  UIHelper.SetImage(self.widgetsTab.im_mood, moodInfo.mood_icon, true)
  local girlData = Data.heroData:GetHeroById(heroId)
  self.currMoodNum = Logic.marryLogic:GetMoodNum(girlData, heroId)
  self.currMoodSlider = self.currMoodNum / parent.moodBound[2]
  self.widgetsTab.slider_detailShip.value = self.currMoodNum / parent.moodBound[2]
end

function BathGiftPage:_CameraMoveOver()
  self:MoveBuffImage(false)
  if parent.selectShipPos == 0 then
    return
  end
  local pos = BathRoomScene:GetScreenPoint(parent.m_tabModelPos[parent.selectShipPos].transform.position)
  if parent.m_tabgirlinrepair[parent.selectShipPos] == nil then
    self:_ClickCloseGift()
    return
  end
  self.girlModel = parent.m_tabmodel[parent.selectShip.HeroId].girl
  self:_PlayBathClick()
end

function BathGiftPage:MoveBuffImage(status)
  parent.cameraMove = status
  if not status then
    self:_StopMoveBuffTimer()
    self:_SetMoveBuff()
    return
  end
  if self.giftMoveTimer == nil then
    self.giftMoveTimer = FrameTimer.New(function()
      self:_SetMoveBuff()
    end, 1, -1)
  end
  self.giftMoveTimer:Start()
end

function BathGiftPage:_SetMoveBuff()
  for _, buffInfo in pairs(parent.m_buffTab) do
    if buffInfo.posDep ~= nil then
      local pos = BathRoomScene:GetScreenPoint(buffInfo.posDep)
      buffInfo.image.gameObject.transform.position = Vector3.New(pos.x, pos.y, 0)
    end
  end
end

function BathGiftPage:_StopMoveBuffTimer()
  if self.giftMoveTimer and self.giftMoveTimer.running then
    self.giftMoveTimer:Stop()
    self.giftMoveTimer = nil
  end
end

function BathGiftPage:_ShowSubtitle(textContent)
  self.widgetsTab.obj_talk:SetActive(true)
  self.widgetsTab.txt_talk.text = textContent
end

function BathGiftPage:_CloseSubtitle()
  self.widgetsTab.txt_talk.text = ""
  self.widgetsTab.obj_talk:SetActive(false)
end

function BathGiftPage:_PlayBathClick()
  self.playingBehaviour = true
  self.girlModel:playBehaviour("bath_click", false, function()
    self.playingBehaviour = false
    self.girlModel:playBehaviour("bath_loop", true)
  end)
end

function BathGiftPage:_PlayAddMoodEff(pos, heroId, mood)
  local currMoodSlider = self.currMoodSlider
  local currMoodNum = self.currMoodNum
  self.widgetsTab.obj_addMoodEff.transform.position = Vector3.New(pos.x, pos.y + 0.1, 0)
  self.widgetsTab.img_moodEff1.fillAmount = currMoodSlider
  self.widgetsTab.img_moodEff2.fillAmount = currMoodSlider
  self.widgetsTab.txt_moodEff.text = math.floor(currMoodNum / 10000)
  self.widgetsTab.txt_addMood.text = math.floor(mood / 10000)
  self.widgetsTab.obj_addMoodEff:SetActive(true)
  local moodNum = currMoodNum < parent.moodBound[2] and currMoodNum + mood or currMoodNum
  local moodSlider = moodNum / parent.moodBound[2] >= 1 and 1 or moodNum / parent.moodBound[2]
  self.openMEffTimer = Timer.New(function()
    self.openMEffTimer:Stop()
    self.openMEffTimer = nil
    local diff = (moodSlider - currMoodSlider) * 0.1
    self.showMSliderTimer = FrameTimer.New(function()
      self:_ShowMSlider(moodNum, moodSlider, diff)
    end, 2, -1)
    self.showMSliderTimer:Start()
  end, 0.8, 1)
  self.openMEffTimer:Start()
end

function BathGiftPage:_ShowMSlider(moodNum, moodSlider, diff)
  local m_fill = self.widgetsTab.img_moodEff1.fillAmount
  if moodSlider <= m_fill then
    self.showMSliderTimer:Stop()
    self.showMSliderTimer = nil
    self.widgetsTab.txt_moodEff.text = moodNum <= parent.moodBound[2] and math.floor(moodNum / 10000) or math.floor(parent.moodBound[2] / 10000)
    self.showMValueTimer = Timer.New(function()
      self.showMValueTimer:Stop()
      self.showMValueTimer = nil
      self.widgetsTab.obj_addMoodEff:SetActive(false)
    end, 1, 1)
    self.showMValueTimer:Start()
    return
  end
  self.widgetsTab.img_moodEff1.fillAmount = m_fill + diff
  self.widgetsTab.img_moodEff2.fillAmount = m_fill + diff
end

function BathGiftPage:_StopMoodEffTimer()
  if self.showMValueTimer ~= nil then
    self.showMValueTimer:Stop()
    self.showMValueTimer = nil
  end
  if self.showMSliderTimer ~= nil then
    self.showMSliderTimer:Stop()
    self.showMSliderTimer = nil
  end
  if self.openMEffTimer ~= nil then
    self.openMEffTimer:Stop()
    self.openMEffTimer = nil
  end
  if self.giftMoveTimer ~= nil then
    self.giftMoveTimer:Stop()
    self.giftMoveTimer = nil
  end
  self.widgetsTab.obj_addMoodEff:SetActive(false)
end

return BathGiftPage
