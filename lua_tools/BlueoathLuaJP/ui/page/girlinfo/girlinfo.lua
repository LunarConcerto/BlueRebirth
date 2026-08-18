local GirlInfo = class("UI.GirlInfo.GirlInfo", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local m_rightPageName = {
  "GirlShowPage",
  "Strengthen_Page",
  "Break_Page",
  "Equipment_Page",
  "ShipCombinationStatusPage",
  "ShipCombinationPage"
}
local clickGirl = {
  "click1",
  "click2",
  "click3"
}
local gccount = 0
local mapHero = {}
local mood_addtime = 0
local tabUIs = {
  {
    icon = "uipic_ui_toggle_im_xiangqing",
    txt = UIHelper.GetString(920000126),
    reddotIds = {
      37,
      50,
      97
    }
  },
  {
    icon = "uipic_ui_toggle_im_qianghua",
    txt = UIHelper.GetString(920000232),
    checkLimit = true
  },
  {
    icon = "uipic_ui_newhome_im_jiandui",
    txt = UIHelper.GetString(920000233),
    reddotIds = {15}
  },
  {
    icon = "uipic_ui_toggle_im_zhuangbei",
    txt = UIHelper.GetString(920000049),
    reddotIds = {
      16,
      18,
      20,
      22
    }
  },
  {
    icon = "uipic_ui_settings_im_gongming",
    txt = UIHelper.GetString(4900024)
  },
  {
    icon = "uipic_ui_settings_im_gongmingshengji",
    txt = UIHelper.GetString(4900025)
  }
}

function GirlInfo:DoInit()
  self.m_isCheck = false
  self.m_isTween = false
  self.m_isFirstOpen = true
  mood_addtime = configManager.GetDataById("config_parameter", 139).value
  self.m_isHeng = true
end

function GirlInfo:DoOnOpen()
  local widgets = self.tab_Widgets
  mapHero = Logic.girlInfoLogic:GetMapHeroByMood()
  self:__Create3DShow()
  self.bgPos = configManager.GetDataById("config_parameter", 95).arrValue
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, true)
  self:OpenTopPage("GirlInfo", 1, UIHelper.GetString(920000051), self, true)
  self.m_heroId = self.param[1] or self.m_heroId
  self.m_tabHero = self.param[2]
  self.is3D = Logic.girlInfoLogic:GetIs3D()
  self:_SetFleetType(self.param.fleetType)
  self:__CreateStar()
  widgets.btn_animolji.gameObject:SetActive(Face:IsSupport() and self.param[3])
  widgets.obj_talk:SetActive(false)
  widgets.obj_mood:SetActive(false)
  widgets.obj_checkContent:SetActive(false)
  self:__UpdateGirlInfo(self.m_heroId)
  self.lastTogIndex = Logic.girlInfoLogic:GetLastTogIndex() or 1
  if self.param.jumpToggle then
    self.lastTogIndex = self.param.jumpToggle
  end
  if self.lastTogIndex > #self.toggleIndices then
    self.lastTogIndex = 1
  end
  if self.lastTogIndex == 2 and tabUIs[self.lastTogIndex].checkLimit and Logic.girlInfoLogic:CheckStrengthenLock(self.m_heroId) then
    self.lastTogIndex = 1
  end
  widgets.tog_group:SetActiveToggleIndex(self.lastTogIndex - 1)
  Logic.girlInfoLogic:SetLastTogIndex(self.lastTogIndex)
  if self.m_isFirstOpen then
    self.m_isFirstOpen = false
    self:__FirstUpdate()
  end
  self:__RegisterModeBInput()
  self.isSubmarine = self:CheckIsSubmarine()
end

function GirlInfo:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  SectionBehaviourMsg:DestoryBehaviour()
  Logic.girlInfoLogic:SetMapHeroByMood(mapHero)
  Logic.shipLogic:ResetConsumeBreakItemMubo()
  SoundManager.Instance:PlayAudio("Sidechain_switch")
end

function GirlInfo:DoOnClose()
  self:DoOnHide()
  inputManager:UnregisterAllInput(self)
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
  Logic.shipLogic:ResetConsumeBreakItemMubo()
end

function GirlInfo:RegisterAllEvent()
  local widgets = self.tab_Widgets
  self:RegisterEvent(LuaEvent.UpdateMoodHero, self.__UpdateMoodHero, self)
  self:RegisterEvent(LuaEvent.SendHeroLock, self.__HeroClockCallBack, self)
  self:RegisterEvent(LuaEvent.HeroBreakSuccess, self.__OnBreakIntensifySuccess, self)
  self:RegisterEvent(LuaEvent.HeroIntensifySuccess, self.__OnBreakIntensifySuccess, self)
  self:RegisterEvent(LuaEvent.MarrySuccess, self.__UpdateName, self)
  self:RegisterEvent(LuaEvent.ChangeNameSuccess, self.__UpdateName, self)
  self:RegisterEvent(LuaEvent.UpdateHeroAddAffection, self.__UpdateMoodHero, self)
  self:RegisterEvent(LuaEvent.GirlInfoShowBreakEffect, self.__ShowBreakEffect, self)
  self:RegisterEvent(LuaEvent.GirlInfoUpdateUI, self.__UpdateHeroImpl, self)
  self:RegisterEvent("switchtag", function(_, index)
    if self.isSubmarine and 2 <= index then
      index = index - 1
    end
    local tog = self.toggleParts[index + 1].tog
    self.tab_Widgets.tog_group:NotifyToggleOn(tog, true)
  end)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, function()
    eventManager:SendEvent(LuaEvent.GirlInfoUIReset)
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, self.__ShowSubtitle, self)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, self.__CloseSubtitle, self)
  UGUIEventListener.AddOnDrag(widgets.img_bgpinzhi, self.__OnDrag, self)
  UGUIEventListener.AddOnDrag(widgets.im_2dBox, self.__OnDrag, self)
  UGUIEventListener.AddOnDrag(widgets.im_3dBox, self.__OnDrag, self)
  UGUIEventListener.AddOnEndDrag(widgets.im_2dBox, self.__OnDragEnd, self)
  UGUIEventListener.AddOnEndDrag(widgets.im_3dBox, self.__OnDragEnd, self)
  UGUIEventListener.AddButtonOnPointUp(widgets.im_2dBox, self.__OnPointUp, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_Lock, self.__ClickLock, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_2dto3d, self.__ClickSwitch, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_check, self.__CheckBulidGirl, self)
  UGUIEventListener.AddButtonOnClick(widgets.img_bgpinzhi, self.__CancelCheck, self)
  UGUIEventListener.AddOnEndDrag(widgets.img_bgpinzhi, self.__OnDragEnd, self)
  UGUIEventListener.AddButtonOnClick(widgets.img_bgpinzhi, self.__OnClick, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_animolji, self.__OpenAnimolji, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_get, self._ShowGetApproach, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_2dBox, self.__ClickSpecial, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_3dBox, self.__ClickSpecial, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_love, self.__OpenMarryBook, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_effLove, self.__OpenMarryBook, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_effMarriedLove, self.__OpenMarryBook, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_changeName, self.__ChangeName, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_mood, self.__ShowMoodDesc, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fashion, self.__ClickFashion, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_changeHeng, self.__ChangeGilr, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_changeShu, self.__ChangeGilr, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_hengPicture, self.__PictureShare, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_shuPicture, self.__PictureShare, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_remould, self.__OpenRemould, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
end

function GirlInfo:__FirstUpdate()
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
  local scaleSize = configManager.GetDataById("config_ship_position", shipConfig.ss_id).ship_scale1 / 10000
  local tweenScale = self.tab_Widgets.tween_scale
  tweenScale.from = Vector3.New(0, 0, 0)
  tweenScale.to = Vector3.New(scaleSize, scaleSize, scaleSize)
  tweenScale:Play(true)
  local timer = FrameTimer.New(function()
    self:__UpdateCharge()
  end, 1, 1)
  timer:Start()
end

function GirlInfo:__UpdateCharge()
  eventManager:SendEvent(LuaEvent.UpdateGirlTog, self.m_heroId)
end

function GirlInfo:__CreateToggle()
  local widgets = self.tab_Widgets
  self.toggleIndices = self.param.toggleIndices and self.param.toggleIndices or {
    1,
    2,
    3,
    4,
    5
  }
  local heroInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  if shipType == 8 then
    if table.containV(self.toggleIndices, 2) then
      table.removebyvalue(self.toggleIndices, 2)
    end
    if table.containV(self.toggleIndices, 5) then
      table.removebyvalue(self.toggleIndices, 5)
    end
  end
  if Logic.shipLogic:CheckShipCanCombine(self.m_heroId) and not self.param.ignoreCombine then
    table.insert(self.toggleIndices, 6)
  else
    if table.containV(self.toggleIndices, 6) then
      table.removebyvalue(self.toggleIndices, 6)
    end
    self.lastTogIndex = Logic.girlInfoLogic:GetLastTogIndex() or 1
    if self.lastTogIndex > #self.toggleIndices then
      self.lastTogIndex = 1
      Logic.girlInfoLogic:SetLastTogIndex(self.lastTogIndex)
    end
  end
  local toggleCount = #self.toggleIndices
  self.toggleParts = {}
  self.tabRed = {}
  UIHelper.CreateSubPart(widgets.tog_xinxi, widgets.tog_group.transform, toggleCount, function(nIndex, tabPart)
    local index = self.toggleIndices[nIndex]
    local info = tabUIs[index]
    table.insert(self.toggleParts, tabPart)
    UIHelper.SetImage(tabPart.icon, info.icon)
    UIHelper.SetText(tabPart.txt, info.txt)
    widgets.tog_group:RegisterToggle(tabPart.tog)
    if info.checkLimit then
      local strengthenLock = Logic.girlInfoLogic:CheckStrengthenLock(self.m_heroId)
      tabPart.im_lock:SetActive(strengthenLock)
      if strengthenLock then
        widgets.tog_group:ResigterToggleUnActive(nIndex - 1, function()
          self:__UnActive()
        end)
      else
        widgets.tog_group:RemoveToggleUnActive(nIndex - 1)
      end
    end
  end)
end

function GirlInfo:__UnActive()
  noticeManager:OpenTipPage(self, 940000026)
end

local MAX_STAR_NUM = 6

function GirlInfo:__CreateStar()
  local widgets = self.tab_Widgets
  self.stars = {}
  UIHelper.CreateSubPart(widgets.obj_star, widgets.trans_starBase, MAX_STAR_NUM, function(nIndex, tabPart)
    table.insert(self.stars, tabPart)
  end)
end

function GirlInfo:_SyncParam(heroId)
  if self.param[1] then
    self.param[1] = heroId
  end
end

function GirlInfo:__UpdateGirlInfo(heroId)
  local widgets = self.tab_Widgets
  local shipInfo = Data.heroData:GetHeroById(heroId)
  if shipInfo == nil then
    logError("FATAL ERROR:can not find hero info about:" .. heroId)
    return
  end
  self.delta = 0
  self.m_heroId = heroId
  self:_SyncParam(heroId)
  local sf_id = Logic.shipLogic:GetHeroSFIdByTemplateId(shipInfo.TemplateId)
  local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
  widgets.btn_fashion.gameObject:SetActive(sf_config.is_open_fashion == 1)
  self.isNpc = npcAssistFleetMgr:IsNpcHeroId(self.m_heroId)
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  SectionBehaviourMsg:DestoryBehaviour()
  self:__HideBreakEffect()
  self:__MoodTickCharge()
  self:__UpdateHeroImpl()
  self:__UpdateMoodHero()
  widgets.tog_group:ClearToggles()
  self:__CreateToggle()
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group, self, nil, self.__SwitchTogs)
  self:__ShowRemould()
  eventManager:SendEvent(LuaEvent.GirlInfoUIReset)
  for k, v in ipairs(self.toggleParts) do
    if tabUIs[k].reddotIds then
      self:RegisterRedDotById(v.red_dot, tabUIs[k].reddotIds, self.m_heroId, self:_GetFleetType())
    end
  end
  local shipConfig = Logic.shipLogic:GetShipInfoById(shipInfo.TemplateId)
  local dotinfo = {
    info = "ui_ship_details",
    ship_name = shipConfig.ship_name
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function GirlInfo:__UpdateHeroImpl()
  local widgets = self:GetWidgets()
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(shipInfo.HeroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(shipInfo.HeroId)
  UIHelper.SetText(widgets.txt_num, shipInfo.Lvl)
  local shipTypeConfig = configManager.GetDataById("config_ship_type", shipInfo.type)
  UIHelper.SetImage(widgets.im_type_des, shipTypeConfig.wordsimage)
  UIHelper.SetImage(widgets.im_type, NewCardShipTypeImg[shipInfo.type])
  local shipCVConfig = Logic.shipLogic:GetShipShowHandBookById(shipInfo.TemplateId)
  UIHelper.SetText(widgets.txt_CVname, "CV:" .. shipCVConfig.ship_character_voice)
  widgets.obj_lock:SetActive(not self.isNpc)
  UIHelper.SetImage(widgets.im_lock, LockStatus[shipInfo.Lock])
  local quality = shipInfoConfig.quality
  local imgbg = configManager.GetDataById("config_quality_param", quality).togglelist_imgbg
  UIHelper.SetImage(widgets.img_BG, imgbg)
  UIHelper.SetImage(widgets.img_bgpinzhi, GirlQualityBgTexture[shipInfo.quality])
  self.startName = shipInfoConfig.ship_name
  self.shipName = shipInfoConfig.ship_name
  if self.isNpc then
    widgets.obj_changeName:SetActive(false)
    widgets.im_mood.gameObject:SetActive(false)
    widgets.im_love.gameObject:SetActive(false)
    widgets.obj_canMarry:SetActive(false)
    widgets.obj_married:SetActive(false)
    UIHelper.SetText(widgets.txt_name, self.shipName)
  else
    self:__UpdateName()
    local curTime = time.getSvrTime()
    if mapHero[self.m_heroId] == nil or curTime - mapHero[self.m_heroId] >= mood_addtime * 60 then
      mapHero[self.m_heroId] = curTime
      Service.heroService:_SendBathHero({
        {
          HeroId = self.m_heroId
        }
      })
    end
  end
  local shipPosConf = configManager.GetDataById("config_ship_position", shipConfig.ss_id)
  self.position = shipPosConf.ship_position1
  local grilTrans = widgets.img_2dgirl.transform
  grilTrans.localPosition = Vector3.New(self.position[1], self.position[2], 0)
  local scaleSize = shipPosConf.ship_scale1 / 10000
  local mirror = shipPosConf.ship_inversion1
  self.scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = self.scale
  self.start2dRotation = widgets.img_2dgirl.transform.localRotation
  local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(self.m_heroId)
  local curHp = Logic.shipLogic:GetHeroHp(self.m_heroId, self:_GetFleetType())
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
  self.showID = shipConfig.ss_id
  local tabTemp = configManager.GetDataById("config_ship_model", shipConfig.model_id)
  self.dressID = hpStatus < DamageLevel.MiddleDamage and tabTemp.standard_normal or tabTemp.standard_dapo
  self:__UpdateModelShow()
  local advance = shipInfo.Advance
  local line, subCount = Logic.shipLogic:ShowShipStarInfo(advance)
  for k, v in ipairs(self.stars) do
    if 0 < line then
      UIHelper.SetImage(v.img_star, ShipStarImgMubo[2])
    else
      UIHelper.SetImage(v.img_star, ShipStarImgMubo[1])
    end
    v.gameObject:SetActive(k <= subCount)
  end
end

function GirlInfo:__UpdateMoodHero()
  local widgets = self.tab_Widgets
  local heroInfo = Data.heroData:GetHeroById(self.m_heroId)
  local moodInfo = Logic.marryLogic:GetLoveInfo(self.m_heroId, MarryType.Mood)
  UIHelper.SetImage(self.tab_Widgets.im_mood, moodInfo.mood_icon, true)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.m_heroId, MarryType.Love)
  UIHelper.SetImage(self.tab_Widgets.im_love, loveInfo.affection_icon, true)
  local marry_allow_affection = Logic.marryLogic:GetAllowMarryAffection(self.m_heroId)
  widgets.obj_canMarry:SetActive(num >= marry_allow_affection and heroInfo.MarryTime == 0)
  widgets.obj_married:SetActive(heroInfo.MarryTime ~= 0 and not npcAssistFleetMgr:IsNpcHeroId(self.m_heroId))
  widgets.im_love.gameObject:SetActive(num < marry_allow_affection and heroInfo.MarryTime == 0)
end

function GirlInfo:__ShowBreakEffect(param)
  if param.hid ~= self.m_heroId then
    return
  end
  local widgets = self.tab_Widgets
  local quality = Logic.shipLogic:GetShipInfoByHeroId(self.m_heroId).quality
  local _, subCount = Logic.shipLogic:ShowShipStarInfo(param.advance)
  local tabPart = self.stars[subCount]
  tabPart.gameObject:SetActive(false)
  tabPart.star_effect:SetActive(true)
  local eff = quality < ShipQuality.SSR and widgets.sr_effect or widgets.ssr_effect
  eff:SetActive(false)
  self.breakTimer = self:PerformDelay(1.8, function()
    eff:SetActive(true)
    tabPart.gameObject:SetActive(true)
    SoundManager.Instance:PlayAudio("Effect_Eff_tupo_flash")
    self.breakTimer = self:PerformDelay(2.5, function()
      tabPart.star_effect:SetActive(false)
    end)
  end)
end

function GirlInfo:__HideBreakEffect()
  local widgets = self.tab_Widgets
  widgets.sr_effect:SetActive(false)
  widgets.ssr_effect:SetActive(false)
  for k, v in ipairs(self.stars) do
    v.star_effect:SetActive(false)
  end
  if self.breakTimer then
    self:StopTimer(self.breakTimer)
    self.breakTimer = nil
  end
end

function GirlInfo:_ShowGetApproach()
  local data = Data.heroData:GetHeroById(self.m_heroId)
  if data == nil then
    logError("get hero data error,heroId:" .. self.m_heroId)
    return
  end
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.SHIP, data.TemplateId, true))
end

function GirlInfo:__UpdateModelShow()
  local widgets = self.tab_Widgets
  widgets.tween_huakuai:Play(self.is3D)
  widgets.im_2dBox:SetActive(not self.is3D)
  widgets.img_2dgirl.gameObject:SetActive(not self.is3D)
  widgets.im_3dBox:SetActive(self.is3D)
  widgets.img_bgpinzhi.color = Color.New(255, 255, 255, self.is3D and 0 or 255)
  local shipShow = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
  self.shipDraw = shipShow.ship_draw
  self.showID = shipShow.ss_id
  if self.is3D then
    if self.m_objModel == nil then
      self:__Create3DShow()
    end
    SectionBehaviourMsg:DestoryBehaviour()
    UGUIEventListener.RemoveButtonOnPointUpListener(widgets.img_bgpinzhi.gameObject)
    local param = {
      showID = self.showID,
      dressID = self.dressID
    }
    if self:__CheckModelChange(param) or self.m_objModel:Get3dObj() == nil then
      self:__ChangeModelShow(param)
    end
    self:__ResetModelPos()
    self.m_objModel:SetBackgroundTex(widgets.img_bgpinzhi.mainTexture)
  else
    UGUIEventListener.AddButtonOnPointUp(widgets.img_bgpinzhi, self.__OnPointUp, self)
    UIHelper.SetImage(widgets.img_2dgirl, self.shipDraw)
  end
  if self.m_objModel then
    self.m_objModel:setCameraEnable(self.is3D)
  end
end

function GirlInfo:__ChangeModelShow(param)
  if self.m_objModel ~= nil then
    local widgets = self.tab_Widgets
    local objModel = self.m_objModel
    objModel:ChangeObj(param)
    objModel:ApplyCameraParam(CamDataType.Detaile)
    local trans = self.m_objModel:Get3dObj().transform
    local pos = trans.position
    local camera = objModel.m_camera
    local size = camera.orthographicSize
    local hu = UIManager:GetUIHeight() / 2
    self.modelStartPos = -size / hu * widgets.trans3DPos_Start.localPosition.x
    self.modelCheckPos = -size / hu * widgets.trans3DPos_Check.localPosition.x
    self.modelStartPosY = pos.y
    local targetTran = objModel:Get3dObj().transform
    self.start3dRotation = targetTran.localEulerAngles
  end
end

function GirlInfo:__CheckModelChange(param)
  if self.lastModelParam == nil then
    self.lastModelParam = param
    return true
  else
    local isOn = self.lastModelParam.infoID ~= param.infoID or self.lastModelParam.dressID ~= param.dressID
    self.lastModelParam = param
    return isOn
  end
end

function GirlInfo:__LoadRightPage(nindex, HeroId)
  local HeroId = self.m_heroId
  local pageIndex = self.toggleIndices[nindex]
  self.curSubPage = self:OpenSubPage(m_rightPageName[pageIndex], {
    heroId = HeroId,
    isNpc = self.isNpc,
    FleetType = self:_GetFleetType(),
    parent = self
  }, nil, false)
end

function GirlInfo:__SwitchTogs(index)
  local realIndex = index + 1
  self.index = realIndex
  Logic.girlInfoLogic:SetLastTogIndex(realIndex)
  for i, part in pairs(self.toggleParts) do
    part.tween_pos:Play(i ~= realIndex)
    part.isOn = i == realIndex
  end
  self:__LoadRightPage(realIndex)
  eventManager:SendEvent(LuaEvent.GirlInfoUIReset)
  eventManager:SendEvent(LuaEvent.GirlInfoOpenIndex, realIndex)
end

function GirlInfo:__OnDrag(go, eventData)
  self.m_isDrag = true
  if self.is3D then
    self:__On3DDrag(go, eventData)
  elseif not self.m_isCheck then
    self:__On2DDragCommon(go, eventData)
  else
    self:__On2DDragCheck(go, eventData)
  end
  self:__CheckGC()
end

function GirlInfo:__On3DDrag(go, eventData)
  local delta = eventData.delta
  if self.m_objModel == nil then
    return
  end
  local targetTran = self.m_objModel:Get3dObj().transform
  if self.m_isHeng then
    targetTran:Rotate(0, -delta.x, 0)
  else
    targetTran:Rotate(0, -delta.y, 0)
  end
end

function GirlInfo:__On2DDragCommon(go, eventData)
  local position = self.bgPos
  self.delta = self.delta + eventData.delta.x
  local scale = self.delta < 0 and 1 or -1
  local bgPosition = position[2] + scale * self.delta * position[1]
  eventManager:SendEvent(LuaEvent.GirlInfoTween, bgPosition)
end

function GirlInfo:__On2DDragCheck(go, eventData)
  Logic.girlInfoLogic:GirlDrag2D(go, eventData, self.tab_Widgets.img_2dgirl.transform, self.m_isHeng)
end

function GirlInfo:__OnPointUp(go, param)
  if math.abs(self.delta) > 10 then
    self:__ChangeHero(self.delta > 0 and -1 or 1)
  else
    eventManager:SendEvent(LuaEvent.GirlInfoTween)
  end
  self.delta = 0
  self:__CheckGC()
end

function GirlInfo:__CheckGC()
  gccount = gccount + 1
  if 20 < gccount then
    gccount = 0
    collectgarbage("collect")
  end
end

function GirlInfo:__ChangeHero(step)
  local widgets = self.tab_Widgets
  local curIndex
  for k, v in ipairs(self.m_tabHero) do
    if v == self.m_heroId then
      curIndex = k
    end
  end
  if curIndex == nil then
    logError("FATAL ERROR:can not find change index")
    return
  end
  local nextIndex = curIndex + step
  if 1 <= nextIndex and nextIndex <= #self.m_tabHero then
    self:__ChangeHeroImpl(self.m_tabHero[nextIndex])
    if Logic.girlInfoLogic:CheckStrengthenLock(self.m_tabHero[nextIndex]) then
      widgets.tog_group:SetActiveToggleIndex(0)
      Logic.girlInfoLogic:SetLastTogIndex(1)
      return
    end
  else
    eventManager:SendEvent(LuaEvent.GirlInfoTween, self.bgPos[2])
  end
end

function GirlInfo:__ChangeHeroImpl(heroId)
  local widgets = self.tab_Widgets
  self:__UpdateGirlInfo(heroId)
  widgets.tog_group:SetActiveToggleIndex(Logic.girlInfoLogic:GetLastTogIndex() - 1)
  widgets.eff_eff:SetActive(false)
  widgets.eff_eff:SetActive(true)
  self:__UpdateCharge()
end

function GirlInfo:__ClickSwitch()
  self.is3D = not self.is3D
  Logic.girlInfoLogic:SetIs3D(self.is3D)
  self:__UpdateModelShow()
  eventManager:SendEvent(LuaEvent.GirlInfoUIReset)
end

function GirlInfo:__ClickLock()
  if Logic.shipLogic:IsSecretary(self.m_heroId) then
    noticeManager:OpenTipPage(self, 310001)
    return
  end
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  Logic.shipLogic:SendHeroLockByType(self.m_heroId, not shipInfo.Lock, self)
end

function GirlInfo:__HeroClockCallBack()
  local widgets = self.tab_Widgets
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipColor = ShipQualityColor[shipInfo.quality]
  UIHelper.SetImage(widgets.im_lock, LockStatus[shipInfo.Lock])
  local str = string.format(LockTipInfo[shipInfo.Lock], shipColor, self.shipName)
  noticeManager:OpenTipPage(self, str)
end

function GirlInfo:__RegisterModeBInput()
  local tabParam = {
    zoom = function(param)
      self:__OnModeBZoom(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function GirlInfo:__OnModeBZoom(delta)
  if not self.m_isCheck or self.is3D then
    return
  end
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
  Logic.girlInfoLogic:GirlPinch2D(delta, self.tab_Widgets.img_2dgirl.transform, shipConfig.ss_id)
end

function GirlInfo:__CheckBulidGirl()
  local widgets = self:GetWidgets()
  if not self.m_isCheck then
    self.m_isCheck = true
    widgets.obj_common:SetActive(false)
    widgets.obj_checkContent:SetActive(true)
    local pageIndex = self.toggleIndices[self.index]
    self.curSubPage:SetToNoView(true)
    self:SetTopVisibleByPos(false)
    local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
    local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
    local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(shipInfo.HeroId)
    self.m_isTween = true
    if self.is3D then
      local modelObj = self.m_objModel:Get3dObj()
      local tween = modelObj.gameObject:GetComponent(UITweener.GetClassType())
      if not tween then
        modelObj.transform:TweenLocalMoveX(self.modelStartPos, self.modelCheckPos, 0.4)
        tween = modelObj.gameObject:GetComponent(UITweener.GetClassType())
      end
      tween:SetOnFinished(function()
        self.m_isTween = false
      end)
      tween:ResetToBeginning()
      tween:Play(true)
    else
      local shipPosConf = configManager.GetDataById("config_ship_position", shipConfig.ss_id)
      local tween_2dgirl = widgets.tween_2dgirl
      local grilTrans = widgets.img_2dgirl.transform
      tween_2dgirl.from = grilTrans.localPosition
      tween_2dgirl.to = Vector3.New(shipPosConf.ship_position3[1], shipPosConf.ship_position3[2], 0)
      tween_2dgirl:SetOnFinished(function()
        local scaleSize = shipPosConf.ship_scale3 / 10000
        local mirror = shipPosConf.ship_inversion3
        grilTrans.localScale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
        self.m_isTween = false
      end)
      tween_2dgirl:ResetToBeginning()
      tween_2dgirl:Play(true)
    end
    self:_ShowHideCheckBtn()
    local shipName = shipInfoConfig.ship_name
    local dotinfo = {
      info = "ui_check",
      entrance = 1,
      type = self.is3D and 2 or 1,
      ship_name = shipName
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
end

function GirlInfo:__OnDragEnd()
  self.m_isDrag = false
end

function GirlInfo:__CancelCheck()
  if self.m_isDrag then
    return
  end
  self.m_isHeng = true
  local widgets = self:GetWidgets()
  if self.m_isCheck and not self.m_isTween then
    self.m_isCheck = false
    widgets.obj_common:SetActive(true)
    widgets.obj_checkContent:SetActive(false)
    local pageIndex = self.toggleIndices[self.index]
    self.curSubPage:SetToNoView(false)
    self:SetTopVisibleByPos(true)
    if self.is3D then
      self.m_objModel:ResetEulerAngels()
      self:__ResetModelPos()
      self:_Change3dBg()
    else
      local grilTrans = widgets.img_2dgirl.transform
      grilTrans.localPosition = Vector3.New(self.position[1], self.position[2], 0)
      grilTrans.localScale = self.scale
      local girlPos = widgets.obj_midGirl.transform
      girlPos.localEulerAngles = self.start2dRotation
      self:_Change2dBg()
    end
  end
  eventManager:SendEvent(LuaEvent.GirlInfoUIReset)
end

function GirlInfo:__ShowSubtitle(textContent)
  local widgets = self.tab_Widgets
  widgets.txt_talk.text = textContent
  widgets.obj_talk:SetActive(true)
end

function GirlInfo:__CloseSubtitle()
  local widgets = self.tab_Widgets
  widgets.txt_talk.text = ""
  widgets.obj_talk:SetActive(false)
end

function GirlInfo:__OnClick()
  if self.m_isDrag then
    return
  end
  if self.m_isCheck then
    self:__CancelCheck()
    return
  end
  self:__PlayNormalAction()
end

function GirlInfo:__ClickSpecial()
  if self.m_isDrag then
    return
  end
  if self.m_isCheck then
    self:__CancelCheck()
    return
  end
  if self:__CheckSpecial() then
    self:__PlayAction("click_sp")
  else
    self:__PlayNormalAction()
  end
end

local MAX_SPECIAL_RATE = 10000

function GirlInfo:__CheckSpecial()
  local rate = configManager.GetDataById("config_parameter", 91).value
  local randomNum = math.random(1, MAX_SPECIAL_RATE)
  return rate >= randomNum
end

function GirlInfo:__PlayNormalAction()
  local contains = {}
  local shipShow = configManager.GetDataById("config_ship_show", self.showID)
  local m_modelAnimName = ScrProfileHub.GetModelAnimName(Logic.shipLogic:GetHeroModelConfigById(shipShow.model_id))
  for v, k in pairs(clickGirl) do
    if table.containValue(m_modelAnimName, k) then
      table.insert(contains, k)
    end
  end
  if self.m_heroId then
    local curfashion = Logic.fashionLogic:GetCurFashionData(self.m_heroId)
    if curfashion then
      local fashionAction = curfashion.unlock_action
      for _, name in ipairs(fashionAction) do
        table.insert(contains, name)
      end
    end
  end
  local index = math.random(1, #contains)
  local action = contains[index]
  self:__PlayAction(action)
end

function GirlInfo:__PlayAction(action)
  if self.is3D then
    local obj = self.m_objModel:Get3dObj()
    obj:playBehaviour(action, false, function()
      obj:playBehaviour("stand_loop", true)
    end)
  else
    local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
    local model = Logic.shipLogic:GetHeroModelConfigById(shipConfig.model_id)
    SectionBehaviourMsg:PlayCVSubtitle(model, "CV_" .. action .. "_" .. model, "zm_" .. action .. "_" .. model)
  end
end

function GirlInfo:__OpenAnimolji()
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  local tabShipInfo = Logic.shipLogic:GetShipInfoById(shipInfo.TemplateId)
  UIHelper.OpenPage("AnimojiPage", self.showID)
end

function GirlInfo:__OpenMarryBook()
  local singleGirl = Data.heroData:GetHeroById(self.m_heroId)
  local ship = Logic.shipLogic:GetDefaultShipShowById(singleGirl.TemplateId)
  if singleGirl.MarryTime == 0 then
    UIHelper.OpenPage("MarryBookPage", {
      self.m_heroId,
      self.shipName,
      ship.ship_draw
    })
  else
    UIHelper.OpenPage("MarryAffterPage", {
      self.m_heroId,
      self.shipName,
      ship.ship_draw,
      MarryAffterType.GirlInfo
    })
  end
end

function GirlInfo:__ChangeName()
  UIHelper.OpenPage("ChangeNamePage", {
    self.m_heroId,
    self.shipName,
    self.startName,
    ChangeNameType.GirlInfo
  })
end

function GirlInfo:__ClickFashion()
  moduleManager:JumpToFunc(FunctionID.Fashion, {
    heroId = self.m_heroId
  })
end

function GirlInfo:__ShowMoodDesc()
  local widgets = self.tab_Widgets
  local girlInfo, moodNum = Logic.marryLogic:GetLoveInfo(self.m_heroId, MarryType.Mood)
  local moodInfo = configManager.GetData("config_affection_mood")
  for v, k in pairs(moodInfo) do
    if moodNum >= k.mood_min and moodNum <= k.mood_max then
      UIHelper.SetText(widgets.tx_mood, k.mood_describe)
      widgets.obj_mood:SetActive(true)
      break
    end
  end
  local time = configManager.GetDataById("config_parameter", 160).value
  self.mood_timer = self:CreateTimer(function()
    self:__MoodTickCharge()
  end, time, 1, false)
  self:StartTimer(self.mood_timer)
end

function GirlInfo:__MoodTickCharge()
  self.tab_Widgets.obj_mood:SetActive(false)
  self:StopTimer(self.mood_timer)
  self.mood_timer = nil
end

function GirlInfo:__OnBreakIntensifySuccess(args)
  local consumedIds = args.ConsumedHeros
  local count = #self.m_tabHero
  for i = count, 1, -1 do
    local heroId = self.m_tabHero[i]
    if table.containValue(consumedIds, heroId) then
      table.remove(self.m_tabHero, i)
    end
  end
end

function GirlInfo:__UpdateName()
  local widgets = self:GetWidgets()
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self.shipName = Logic.shipLogic:GetRealName(self.m_heroId)
  UIHelper.SetText(widgets.txt_name, self.shipName)
  widgets.obj_changeName:SetActive(shipInfo.MarryTime ~= 0)
end

function GirlInfo:__Create3DShow()
  local widgets = self.tab_Widgets
  local rct = widgets.img_bgpinzhi:GetComponent(RectTransform.GetClassType())
  local dx = rct.sizeDelta.x / UIManager:GetUIWidth()
  local dy = rct.sizeDelta.y / UIManager:GetUIHeight()
  self.m_objModel = UIHelper.Create3DModelNoRT(nil, CamDataType.Detaile, false, widgets.img_bgpinzhi.mainTexture, dx, dy)
end

function GirlInfo:__ResetModelPos()
  local trans = self.m_objModel:Get3dObj().transform
  local pos = trans.position
  trans.position = Vector3.New(self.modelStartPos, self.modelStartPosY, pos.z)
  trans.localEulerAngles = self.start3dRotation
end

function GirlInfo:_SetFleetType(fleetType)
  fleetType = fleetType or FleetType.Normal
  if not table.containV(FleetType, fleetType) then
    fleetType = FleetType.Normal
  end
  self.m_fleetType = fleetType
end

function GirlInfo:_GetFleetType()
  return self.m_fleetType
end

function GirlInfo:__ChangeGilr(...)
  if not self.m_isCheck then
    return
  end
  self.m_isHeng = not self.m_isHeng
  local angle = 0
  if not self.m_isHeng then
    angle = 90
  end
  self:_ShowHideCheckBtn()
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.m_heroId)
  if self.is3D then
    local targetTran = self.m_objModel:Get3dObj().transform
    targetTran.localEulerAngles = Vector3.New(0, 0, -angle)
    if self.m_isHeng then
      targetTran.localPosition = Vector3.New(0, 0, 0)
    else
      local position = configManager.GetDataById("config_ship_position", shipConfig.ss_id).model_position
      targetTran.localPosition = Vector3.New(position[1], position[2], 0)
    end
    self:_Change3dBg()
  else
    local grilTrans = self.tab_Widgets.obj_midGirl
    grilTrans.transform.localEulerAngles = Vector3.New(0, 0, angle)
    local shipPosConf = configManager.GetDataById("config_ship_position", shipConfig.ss_id)
    self.tab_Widgets.img_2dgirl.transform.localPosition = Vector3.New(shipPosConf.ship_position3[1], shipPosConf.ship_position3[2], 0)
    self:_Change2dBg()
  end
end

function GirlInfo:_Change3dBg()
  self:_Change2dBg()
  local rct = self.tab_Widgets.img_bgpinzhi:GetComponent(RectTransform.GetClassType())
  local dx = rct.sizeDelta.x / UIManager:GetUIWidth()
  local dy = rct.sizeDelta.y / UIManager:GetUIHeight()
  UIHelper.Change3DModelBground(self.m_objModel, self.tab_Widgets.img_bgpinzhi.mainTexture, dx, dy)
end

function GirlInfo:_Change2dBg()
  local shipInfo = Data.heroData:GetHeroById(self.m_heroId)
  local bgTex
  if self.m_isHeng then
    bgTex = GirlQualityBgTexture[shipInfo.quality]
  else
    bgTex = GirlShuQualityBgTexture[shipInfo.quality]
  end
  UIHelper.SetImage(self.tab_Widgets.img_bgpinzhi, bgTex)
end

function GirlInfo:__PictureShare(...)
  if not self.m_isCheck then
    return
  end
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function GirlInfo:_ShareOver()
  self:ShareComponentShow(true)
  self.tab_Widgets.obj_common:SetActive(false)
  self:SetTopVisibleByPos(false)
end

function GirlInfo:_ShowHideCheckBtn(...)
  self.tab_Widgets.btn_changeHeng.gameObject:SetActive(self.m_isCheck and not self.m_isHeng)
  self.tab_Widgets.btn_changeShu.gameObject:SetActive(self.m_isCheck and self.m_isHeng)
  self.tab_Widgets.btn_hengPicture.gameObject:SetActive(platformManager:ShowShare() and self.m_isHeng and self.m_isCheck)
  self.tab_Widgets.btn_shuPicture.gameObject:SetActive(platformManager:ShowShare() and not self.m_isHeng and self.m_isCheck)
end

function GirlInfo:__ShowRemould()
  local showBtn = Logic.remouldLogic:CkeckHeroRemouldOpen(self.m_heroId)
  self.tab_Widgets.btn_remould.gameObject:SetActive(showBtn)
end

function GirlInfo:__OpenRemould()
  UIHelper.OpenPage("RemouldPage", self.m_heroId)
end

function GirlInfo:JumpToHeroCombineLv(heroId)
  if Logic.shipLogic:CheckShipCanCombine(heroId) then
    self.m_heroId = heroId
    local jumpToggle = 6
    Logic.girlInfoLogic:SetLastTogIndex(jumpToggle)
    self:__ChangeHeroImpl(heroId)
  end
end

function GirlInfo:CheckIsSubmarine()
  local heroInfo = Data.heroData:GetHeroById(self.m_heroId)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(heroInfo.TemplateId)
  if shipType == 8 then
    return true
  else
    return false
  end
end

return GirlInfo
