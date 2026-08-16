HomePage = class("UI.Home.HomePage", LuaUIPage)
local homeFunItem = require("ui.page.Home.HomeFunItem")
local actEnter = require("ui.page.Home.HomeActivityEnter")
local m_tabPartId = {
  Left = "1",
  Down = "2",
  Right = "3"
}
local IS_LEAVE_BATTLE = "eStageSimpleBattle"
local FIRST_LOGIN = "firstLogin"
local QusetionID = 114
local MobilePhoneID = 107
local MEDAL_LIMIT = 100
local tabUIs = {
  {id = 1},
  {id = 2},
  {
    id = 31,
    reddotIds = {32}
  },
  {id = 4}
}
local ShopGiftRedDotId = 46
local CumuRechargeRedDotId = 51
local WorldBossID = 16

function HomePage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_CreateRight()
  Logic.bagLogic:_SetBagSort()
  self.m_bSelectLeft = false
  self.m_secretaryInfo = nil
  self.m_modelDress = nil
  self.m_bShowHideBtn = true
  self.bFirstLogin = false
  self.bInitPage = true
  self.m_timer = nil
  self.m_bottomObj = nil
  self.m_timerCallBack = nil
  self.isCanCloseMusic = false
  self.bCouldHide = true
  self.bClickShow = true
  self.m_bShowBtn = false
  self.m_use3dTouch = false
  actEnter:Init(self)
  self.build_timer = nil
  self.uid = Data.userData:GetUserUid()
end

function HomePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_showBtn, self._ClickHideBtn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_tempset, self._OpenSetting, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_plot, self._OpenPlotPage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_chat, self._OpenChat)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_task, self._OpenTask)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_photograph, self._ShareHome, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_use3dTouch, self._Use3dTouch, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_giftCommit, self._GiftCommit, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_ARKit, self._OpenARKit, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_announcement, self._ClickAnnouncementBtn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_assist, self._OpenAssistTip, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_moduleselect, self._ShowModuleSelect, self, false)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_modulefg, self._ShowModuleSelect, self, true)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_mail, self._OpenMail, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_friend, self._OpenFriend, self)
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._PlayerData, self)
  self:RegisterEvent("changeShipGirl", self._ChangeShipGirl, self)
  Logic.battleManager:RegisterBattleEvent("matchLeaveMsg", self, "Homepage_OnReceiveMatchLeave")
  Logic.battleManager:RegisterBattleEvent("matchJoinMsg", self, "Homepage_ReceiveMatchJoin")
  self:RegisterEvent(LuaEvent.MagazineBack, self.MagazineBack, self)
  self:RegisterEvent(LuaEvent.HomeTimerStart, self._StartTimer, self)
  self:RegisterEvent(LuaEvent.HomeTimerStop, self._StopTimer, self)
  self:RegisterEvent(LuaEvent.ShowHomePageBtn, self._ClickModel, self)
  self:RegisterEvent(LuaEvent.UpdateHomeRedDot, self._UpdateRedDot, self)
  self:RegisterEvent(LuaEvent.HomeClickShip, self._HomeClickShip, self)
  self:RegisterEvent(LuaEvent.HomePageOtherPageOpen, self._OnLeftOpen, self)
  self:RegisterEvent(LuaEvent.HomePageOtherPageClose, self._OnLeftClose, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._HomeShareOver, self)
  self:RegisterEvent(LuaEvent.SDKQuestionCallBack, self._InitActiveBrowse, self)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, function(self, notification)
    self:_ShowSubtitle(notification)
  end, self)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, function(self)
    self:_CloseSubtitle()
  end)
  self:RegisterEvent(LuaCSharpEvent.Trigger3dTouch, function(self)
    self:_Use3dTouchShare()
  end)
  self:RegisterEvent(LuaCSharpEvent.CarouselImage, function(self, notification)
    actEnter:_CarouselImage(notification)
  end, self)
  self:RegisterEvent(LuaEvent.UpdateActivity, function()
    actEnter:_CreateBanner()
    self:_ShowActivityEnter()
    self:_ShowEnter()
  end)
  self:RegisterEvent(LuaEvent.IsHideHomePage, self._ShowBottomBtn, self)
  self:RegisterEvent(LuaEvent.AnnouncementState, self._ChangeAnnouncementState, self)
  self:RegisterEvent(LuaEvent.UpdateSignInfo, self._UpdateSignInfo, self)
  self:RegisterRedDotById(self.m_tabWidgets.shop_reddot, {ShopGiftRedDotId, CumuRechargeRedDotId}, ShopGiftRedDotId)
  self:RegisterEvent(LuaEvent.RefreshActiveBrowse, self._InitActiveBrowse, self)
  self:RegisterEvent(LuaEvent.RefreshSetSecretary, self._RefreshSetSecretary, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_act, self._ActGotoPage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bosscopy, self._ClickBossEnter, self)
end

function HomePage:DoOnOpen()
  self.hideMech = PlayerPrefs.GetInt("HideMech", 0) == 1
  self.isOpenMonthCard = false
  self.isCloseMonthCard = false
  self.bCouldHide = true
  self:OpenTopPage(nil, 0, nil, self)
  self:_InitHomePartShow()
  self.m_bSelectLeft = Logic.homeLogic:GetLeftPageState()
  self:_CreateLeft(self.nCurIndex)
  if self.param == IS_LEAVE_BATTLE then
    self:_UpdateHome()
  elseif self.param == FIRST_LOGIN then
    self.bFirstLogin = true
    self:_StartTimer()
  elseif self.m_bSelectLeft then
    self:_UpdateHome()
  end
  Logic.copyLogic:SetCopySign(EnterCopySign.Home)
  self:_UpdateRedDot()
  self:_PlayerData()
  local dotInfo = {
    info = "ui_main_scene"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  local updateModule = moduleManager:OpenPageOpenModule()
  if updateModule ~= nil then
    moduleManager:SetOpenPageUpdateModule(nil)
  end
  self:_MainTask()
  self:_InitActiveBrowse()
  if platformManager:useSDK() then
    self:_Check3dTouch()
  end
  self:_ShowMagazineEnter()
  self:_ShowActivityEnter()
  Logic.copyLogic:SetSelectPlotDetail()
  if self.m_tabWidgets.obj_hide.activeSelf then
    actEnter:_CreateBanner()
  end
  self:Refresh()
  self:BuildSuccess()
  self.m_tabWidgets.btn_announcement.gameObject:SetActive(false)
  announcementManager:EnableAnnouncement()
  if self.param then
    local funcId = self.param.funcId
    if funcId == FunctionID.BuildShip then
      UIHelper.OpenPage("BuildShipPage", self.param.childParam)
      self.param.funcId = nil
    elseif funcId == FunctionID.BuildShipGirl then
      self:_OnLeftOpen(2)
      UIHelper.OpenPage("BuildShipGirlPage", self.param.childParam)
      self.param.funcId = nil
    end
  end
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
  self:_SetSecretary()
  self:_CorSignCheck()
  self:_RegisterActSSRRedDot()
  eventManager:SendEvent(LuaEvent.PlayNewYearEff)
end

function HomePage:Refresh()
  Logic.homeLogic:UserRefresh()
end

function HomePage:_InitActiveBrowse()
  local browseInfo = Logic.homeLogic:GetActiveBrowseList()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_browse, self.m_tabWidgets.trans_buttonList_up, #browseInfo, function(nIndex, tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_browse, function()
      if platformManager:useSDK() then
        local now = time.getSvrTime()
        if self.timeClickBrowse and now - self.timeClickBrowse < 2 then
          return
        end
        self.timeClickBrowse = now
        local url = platformManager:GetFinallyQuestionnaire(browseInfo[nIndex].content)
        self:_GetBrowseInfoCallBack(url)
      end
    end, self)
    local img_str = browseInfo[nIndex].button_ico
    UIHelper.SetImage(tabPart.img_browse, img_str)
  end)
end

function HomePage:_ShowMagazineEnter()
  local config = Logic.magazineLogic:GetLatest()
  local widgets = self:GetWidgets()
  widgets.btn_magazine.gameObject:SetActive(config)
  if not config then
    return
  end
  UGUIEventListener.AddButtonOnClick(widgets.btn_magazine, function()
    self:_ClickHideBtn()
    self.m_tabWidgets.btn_photograph.gameObject:SetActive(false)
    self.m_tabWidgets.obj_ARKit:SetActive(false)
    moduleManager:JumpToFunc(FunctionID.Magazine)
  end)
end

function HomePage:MagazineBack()
  local widgets = self:GetWidgets()
  self:_ClickHideBtn()
end

function HomePage:_ShowActivityEnter()
  self:_ShowEnter()
  self:_UpdateBossEnter()
end

function HomePage:_ShowActivityNationalDayEnter()
  local btnEnter = self.tab_Widgets.btnActivityNationalDay
  local showType = ActivityPageShowType.NationalDay
  local activityData = Logic.activityLogic:GetOpenActivityByShowType(showType)
  btnEnter.gameObject:SetActive(0 < #activityData)
  if 0 < #activityData then
    UGUIEventListener.AddButtonOnClick(btnEnter, function()
      local pageParam = {showType = showType}
      UIHelper.OpenPage("ActivityPage", pageParam)
    end)
  end
end

function HomePage:_ShowEnter()
  local configs = Logic.enterLogic:GetHomeEnter()
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.activity, widgets.trans_act, #configs, function(index, tabPart)
    local config = configs[index]
    local img = tabPart.img_activity
    local txt = tabPart.txt_activity
    img.gameObject:SetActive(config)
    txt.gameObject:SetActive(config and config.activity_name ~= "")
    if config then
      UIHelper.SetText(txt, config.activity_name)
      UIHelper.SetImage(img, config.activity_icon)
      if #config.reddot_id > 0 then
        self:RegisterRedDotByParamList(tabPart.reddot, config.reddot_id, config.reddot_param)
      end
      UGUIEventListener.AddButtonOnClick(img, function()
        moduleManager:JumpToFunc(config.jump_function, table.unpack(config.jump_para))
      end)
    end
  end)
end

function HomePage:_ShowSchoolActivityEnter()
  local activityData = Logic.activityLogic:GetOpenActivityByTypes(ActivityType.SchoolSign, ActivityType.SchoolActivity, ActivityType.SchoolAccumu)
  local imgActivitySchool = self.tab_Widgets.imgActivitySchool
  imgActivitySchool.gameObject:SetActive(0 < #activityData)
  if 0 < #activityData then
    UGUIEventListener.AddButtonOnClick(imgActivitySchool, function()
      local activityId = 0
      local activityIdList = {
        25,
        26,
        27,
        28
      }
      for _, aid in ipairs(activityIdList) do
        local cfg = configManager.GetDataById("config_activity", aid)
        for _, reddotid in ipairs(cfg.red_dot) do
          local result = redDotManager:GetStateById(reddotid, RedDotType.Normal, {
            cfg.id
          })
          if result then
            activityId = aid
            break
          end
        end
        if 0 < activityId then
          break
        end
      end
      local pageParam = {
        showType = ActivityPageShowType.School,
        activityId = activityId
      }
      UIHelper.OpenPage("ActivityPage", pageParam)
    end)
  end
end

function HomePage:_Check3dTouch()
  local have3dTouch = UIHelper.Check3dTouch()
  self.m_tabWidgets.tog_use3dTouch.gameObject:SetActive(have3dTouch)
  self.m_tabWidgets.tog_use3dTouch.isOn = have3dTouch
  self.m_tabWidgets.script_pressure.enabled = have3dTouch
  self.m_use3dTouch = have3dTouch
end

function HomePage:_Use3dTouch()
  if self.m_tabWidgets.tog_use3dTouch.isOn then
    self.m_use3dTouch = true
    self.m_tabWidgets.script_pressure.enabled = true
  else
    self.m_use3dTouch = false
    self.m_tabWidgets.script_pressure.enabled = false
  end
end

function HomePage:_ShareHome()
  eventManager:SendEvent(LuaEvent.HomePauseBehavior, true)
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function HomePage:_Use3dTouchShare()
  if self.m_use3dTouch and self.m_bShowBtn then
    self:_ShareHome()
    self.m_tabWidgets.script_pressure.enabled = false
  end
end

function HomePage:_HomeShareOver()
  self:ShareComponentShow(true)
  eventManager:SendEvent(LuaEvent.HomePauseBehavior, false)
  self.m_tabWidgets.script_pressure.enabled = true
  self.m_tabWidgets.btn_photograph.gameObject:SetActive(self.m_bShowBtn and platformManager:ShowShare())
  self:_ShowARKit(self.m_bShowBtn)
end

function HomePage:_UpdateSignInfo()
  self:_CorSignCheck()
end

function HomePage:_CorSignCheck()
  if self.m_signTimer ~= nil then
    self.m_signTimer:Stop()
    self.m_signTimer = nil
  end
  self.m_signTimer = FrameTimer.New(function()
    self:_CorSignCall()
  end, 0, 1)
  self.m_signTimer:Start()
end

function HomePage:_CorSignCall()
  local isSign = Logic.activityLogic:IsSignToday()
  local isGuide = GR.guideManager:isPlayingGuide()
  local isBuild = Logic.buildShipLogic:GetDisplay()
  local isMounthReward = Logic.rechargeLogic:CheckLoginRewards()
  local isBigMonthReward = Logic.rechargeLogic:CheckLoginBigMonthRewards()
  local dailyLoginActivtyId = Logic.activityLogic:GetLoginActivityCanReward()
  local isLoginActivityReward_Vocation = 0 < dailyLoginActivtyId
  self.needOpenAnnounce = platformManager:GetAnnounceState(AnnouncementType.Maintenance) and not announcementManager:Opened()
  if self.needOpenAnnounce and not isGuide and not isBuild and not self.announceOpen then
    self.announceOpen = true
    announcementManager:OpenAnnouncement(function()
      self.announceOpen = false
      self:_CorSignCheck()
    end)
  end
  if not self.announceOpen and not self.needOpenAnnounce and not isGuide and not isBuild then
    if not isSign then
      Data.activityData:SetTag(0)
      UIHelper.OpenPage("ActivityPage")
    end
    if isSign and isLoginActivityReward_Vocation then
      UIHelper.OpenPage("ActivityPage", {
        GotoParam = {dailyLoginActivtyId}
      })
      return
    end
  end
  if isGuide then
    self:_PlayLoginAnim()
  elseif isSign and not self.needOpenAnnounce then
    if isMounthReward then
      self:_ShowMonthCardReward()
    elseif not self.isOpenMonthCard or self.isOpenMonthCard and self.isCloseMonthCard then
      if isBigMonthReward then
        self:_ShowBigMonthCardReward()
      else
        self:_PlayLoginAnim()
      end
    end
  end
end

function HomePage:_ShowMonthCardReward()
  local rewards = Data.rechargeData:GetRechargeMonthRewardData()
  self.isOpenMonthCard = true
  Logic.rewardLogic:ShowCommonReward(rewards, "HomePage", function()
    self.isCloseMonthCard = true
    self:_CorSignCheck()
  end, RewardType.MONTHCARD)
end

function HomePage:_ShowBigMonthCardReward()
  local rewards = Data.rechargeData:GetRechargeExtraRewardData()
  Logic.rewardLogic:ShowCommonReward(rewards, "HomePage", function()
    self:_PlayLoginAnim()
  end, RewardType.BIGMONTHCARD)
end

function HomePage:_PlayWaitAnim()
  eventManager:SendEvent(LuaEvent.PlayWaitAnim)
end

function HomePage:_PlayLoginAnim()
  local firstOpen = self.bFirstLogin and self.bInitPage
  if firstOpen then
    eventManager:SendEvent(LuaEvent.PlayLoginAnim)
  end
  self.bFirstLogin = false
  self.bInitPage = false
end

function HomePage:_StartTimer()
  if self.m_timerCallBack == nil then
    function self.m_timerCallBack()
      self:_PlayWaitAnim()
    end
  end
  local duration = configManager.GetDataById("config_parameter", 42).value / 10000
  if self.m_timer == nil then
    self.m_timer = self:CreateTimer(self.m_timerCallBack, duration, 1, false)
  else
    self:ResetTimer(self.m_timer, self.m_timerCallBack, duration, 1, false)
  end
  self:StartTimer(self.m_timer)
end

function HomePage:_StopTimer()
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function HomePage:_OpenPlotPage()
  plotManager:OpenPlotPage(1)
end

function HomePage:_OnLeftOpen(curIndex)
  Logic.homeLogic:SetLeftPageState(true)
  self:_setObjHideShow(false)
  self.m_tabWidgets.obj_bottom:SetActive(false)
  self.m_tabWidgets.trans_bottomContent.gameObject:SetActive(false)
  self.m_bSelectLeft = true
  self.nCurIndex = curIndex
  self:_CreateLeft(self.nCurIndex)
  self.bCouldHide = false
  self.m_tabWidgets.obj_turnBtn:SetActive(false)
  self.m_tabWidgets.btn_showBtn.gameObject:SetActive(false)
end

function HomePage:_OnLeftClose()
  self.bCouldHide = true
  actEnter:_CreateBanner()
  self:_UpdateHome()
end

function HomePage:_UpdateRedDot()
  self:_CreateBottom()
end

function HomePage:_ReceiveMatchJoin(ret)
end

function HomePage:_OnReceiveMatchLeave()
end

function HomePage:_OpenSetting()
  UIHelper.OpenPage("LvliPage")
end

function HomePage:_ShowSubtitle(textContent)
  self.m_tabWidgets.obj_talk:SetActive(true)
  self.m_tabWidgets.tween_talk:Play(not self.m_bShowBtn)
  self.m_tabWidgets.txt_talk.text = textContent
end

function HomePage:_CloseSubtitle()
  self.m_tabWidgets.txt_talk.text = ""
  self.m_tabWidgets.obj_talk:SetActive(false)
end

function HomePage:_CreateLeft(cur)
  if cur ~= 0 then
    self.isCanCloseMusic = true
    SoundManager.Instance:PlayMusic("UI_Tween_BuildShipPage_0001")
  elseif cur == 0 and self.isCanCloseMusic then
    self.isCanCloseMusic = false
    SoundManager.Instance:PlayMusic("UI_Button_RepairePage_0005")
  end
  local tabConfig = configManager.GetDataById("config_home_page", m_tabPartId.Left)
  local fifterShowTag = Logic.homeLogic:FilterShowBtn(tabConfig.function_id)
  self.leftFuncs = fifterShowTag
  if cur == nil then
    self.nCurIndex = 0
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_leftItem, self.m_tabWidgets.trans_leftContent, #fifterShowTag, function(nIndex, tabPart)
      local functionId = fifterShowTag[nIndex]
      local funConfig = configManager.GetDataById("config_function_info", tostring(functionId))
      local redDotIdList = funConfig.focus
      if redDotIdList and 0 < #redDotIdList then
        self:RegisterRedDotById(tabPart.red_dot, redDotIdList)
      end
      self:SetBuildRed(functionId, tabPart)
      local item = homeFunItem:new()
      item:Init(self, tabPart, nIndex, fifterShowTag[nIndex])
    end)
  else
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_leftItem, self.m_tabWidgets.trans_leftContent, #fifterShowTag, function(nIndex, tabPart)
      local functionId = fifterShowTag[nIndex]
      local funConfig = configManager.GetDataById("config_function_info", tostring(functionId))
      local redDotIdList = funConfig.focus
      if redDotIdList and 0 < #redDotIdList then
        self:RegisterRedDotById(tabPart.redDot, redDotIdList)
      end
      self:SetBuildRed(functionId, tabPart)
      if self.m_bSelectLeft and cur == nIndex and tonumber(functionId) ~= FunctionID.BuildShip then
        tabPart.tween_pos:Play(true)
        tabPart.obj_line:SetActive(true)
        tabPart.obj_select:SetActive(true)
      else
        tabPart.tween_pos:Play(false)
        tabPart.obj_line:SetActive(false)
        tabPart.obj_select:SetActive(false)
      end
    end)
  end
end

function HomePage:SetBuildRed(funId, part)
  if tonumber(funId) ~= FunctionID.BuildShip then
    part.obj_effNew:SetActive(false)
    return
  end
  local newOpen = Logic.buildShipLogic:CheckNewBuildOpen()
  part.obj_effNew:SetActive(newOpen)
end

function HomePage:_CreateBottom()
  local tabConfig = configManager.GetDataById("config_home_page", m_tabPartId.Down)
  local fifterShowTag = Logic.homeLogic:FilterShowBtn(tabConfig.function_id)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_bottomItem, self.m_tabWidgets.trans_bottomContent, #fifterShowTag, function(nIndex, tabPart)
    local item = homeFunItem:new()
    item:Init(self, tabPart, nIndex, fifterShowTag[nIndex])
  end)
end

function HomePage:_CreateRight()
  local tabConfig = configManager.GetDataById("config_home_page", m_tabPartId.Right)
  local functionId = tabConfig.function_id
  for k, v in pairs(functionId) do
    local funConfig = configManager.GetDataById("config_function_info", v)
    UIHelper.SetImage(self.m_tabWidgets["img_right" .. tostring(k)], funConfig.icon)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets["btn_right" .. tostring(k)], function()
      self:_OnClickBtn(k, v)
    end)
  end
end

function HomePage:_OnClickBtn(nIndex, functionId, tabPart)
  if functionId == "7" then
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      noticeManager:OpenTipPage(self, 110007)
      return
    end
  end
  if moduleManager:CheckFunc(functionId, true) then
    local isLeft = Logic.homeLogic:GetIsLeft(tostring(functionId))
    if isLeft then
      self:_LeftFun(nIndex, functionId)
      return
    end
    if tabPart ~= nil then
      self.m_bottomObj = tabPart.obj_select
      self.m_bottomObj:SetActive(true)
    end
    if tonumber(functionId) == FunctionID.ARKit then
      self.m_bottomObj:SetActive(false)
    end
    if tonumber(functionId) == FunctionID.Building and BabelTimeSDK.AppleReview == BabelTimeSDK.IS_REVIEW then
      functionId = FunctionID.BathRoom
    end
    local suc = moduleManager:JumpToFunc(functionId)
  end
end

function HomePage:_LeftFun(nIndex, functionId)
  if not self.m_bSelectLeft or self.nCurIndex ~= nIndex then
    if self.nCurIndex ~= 0 then
      local funcId = self.leftFuncs[self.nCurIndex]
      moduleManager:CloseToFunc(funcId)
    end
    local suc = moduleManager:JumpToFunc(functionId)
    if suc and tonumber(functionId) ~= FunctionID.BuildShip then
      self.m_bSelectLeft = true
      self.m_bShowHideBtn = false
      self:_CreateLeft(nIndex)
      self.nCurIndex = nIndex
      self:_setObjHideShow(self.m_bShowHideBtn)
    end
    return
  end
  if self.m_bSelectLeft then
    self.m_bSelectLeft = false
    local funcId = self.leftFuncs[self.nCurIndex]
    moduleManager:CloseToFunc(funcId)
    self.nCurIndex = 0
  end
end

function HomePage:_UpdateHome()
  self.nCurIndex = 0
  self.m_bSelectLeft = false
  self:_CreateLeft(self.nCurIndex)
  self:_setObjHideShow(true)
  self.m_tabWidgets.obj_bottom:SetActive(true)
  self.m_tabWidgets.obj_chat:SetActive(true)
  self.m_tabWidgets.trans_bottomContent.gameObject:SetActive(true)
  Logic.homeLogic:SetLeftPageState(false)
  if self.m_bShowBtn then
    self.m_tabWidgets.obj_top:SetActive(true)
  end
  self.m_bShowHideBtn = true
  self:_StartTimer()
  eventManager:SendEvent(LuaEvent.HomePlayTween, false)
  self.m_tabWidgets.obj_turnBtn:SetActive(true)
  self.m_tabWidgets.btn_showBtn.gameObject:SetActive(true)
  local dotInfo = {
    info = "ui_main_scene"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function HomePage:_ChangeShipGirl()
  eventManager:SendEvent(LuaEvent.HomeResetModel)
  self.m_tabWidgets.obj_talk:SetActive(false)
  UIHelper.SetUILock(true)
  local tween_girlMask = UIHelper.GetTween(self.m_tabWidgets.obj_girlMask, ETweenType.ETT_ALPHA, "normal")
  tween_girlMask:SetOnFinished(function()
    self:_ReverseMask(tween_girlMask)
  end)
  self.m_tabWidgets.obj_girlMask:SetActive(true)
  tween_girlMask:Play(true)
end

function HomePage:_ReverseMask(tween_girlMask)
  local tabUserInfo = Data.userData:GetUserData()
  local heroInfo = Data.heroData:GetHeroById(tabUserInfo.SecretaryId)
  if heroInfo == nil then
    return
  end
  local shipInfo = Logic.shipLogic:GetShipShowByHeroId(heroInfo.HeroId)
  local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(tabUserInfo.SecretaryId)
  local curHp = Logic.shipLogic:GetHeroHp(heroInfo.HeroId)
  self.m_modelDress = Logic.shipLogic:GetDressupId(shipInfo.model_id, curHp, heroAttr[AttrType.HP])
  local param = {
    showID = self.m_secretaryInfo.ss_id,
    dressID = self.m_modelDress,
    heroID = tabUserInfo.SecretaryId
  }
  RetentionHelper.OtherEndAllBehaviour()
  local isMarry = false
  if tabUserInfo.HeadShow and tabUserInfo.HeadShow == 1 then
    isMarry = true
  end
  eventManager:SendEvent(LuaEvent.IsMarry, isMarry)
  eventManager:SendEvent(LuaEvent.HomeChangeShipGirl, {
    param,
    true,
    false,
    false
  })
  UIHelper.SetImage(self.m_tabWidgets.img_head, tostring(self.m_secretaryInfo.ship_icon4))
  local tween_girlMaskReverse = UIHelper.GetTween(self.m_tabWidgets.obj_girlMask, ETweenType.ETT_ALPHA, "reverse")
  tween_girlMaskReverse:SetOnFinished(function()
    self:_CloseMask(tween_girlMask, tween_girlMaskReverse)
  end)
  tween_girlMaskReverse:Play(false)
  eventManager:SendEvent(LuaEvent.HideGirlMech, not self.hideMech)
end

function HomePage:_CloseMask(tween_girlMask, tween_girlMaskReverse)
  UIHelper.SetUILock(false)
  self.m_tabWidgets.obj_girlMask.gameObject:SetActive(false)
  tween_girlMaskReverse:ResetToInit()
  tween_girlMask:ResetToInit()
end

function HomePage:_PlayerData()
  local tabUserInfo = Data.userData:GetUserData()
  self.m_tabWidgets.txt_playerName.text = tabUserInfo.Uname
  self.m_tabWidgets.txt_level.text = Mathf.ToInt(tabUserInfo.Level)
  local currNeedExp = configManager.GetDataById("config_player_levelup", Mathf.ToInt(tabUserInfo.Level)).exp
  local currExp = tabUserInfo.Exp
  local currLevel = tabUserInfo.Level
  self.m_tabWidgets.txt_sliderValue.text = Mathf.ToInt(currExp) .. "/" .. Mathf.ToInt(currNeedExp)
  self.m_tabWidgets.slider.value = Mathf.ToInt(currExp) / Mathf.ToInt(currNeedExp)
  local heroInfo = Data.heroData:GetHeroById(tabUserInfo.SecretaryId)
  if heroInfo == nil then
    return
  end
  local shipShow = Logic.shipLogic:GetShipShowByHeroId(heroInfo.HeroId)
  if shipShow ~= nil then
    local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(tabUserInfo.SecretaryId)
    local curHp = Logic.shipLogic:GetHeroHp(heroInfo.HeroId)
    self.m_modelDress = Logic.shipLogic:GetDressupId(shipShow.model_id, curHp, heroAttr[AttrType.HP])
    self.m_secretaryInfo = shipShow
    local heroName = Logic.shipLogic:GetRealName(heroInfo.HeroId)
    self.m_tabWidgets.txt_name.text = heroName
    local shipInfoConfig = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
    UIHelper.SetImage(self.m_tabWidgets.img_type, CardShipTypeImgMin[shipInfoConfig.ship_type], true)
    UIHelper.SetImage(self.m_tabWidgets.img_head, self.m_secretaryInfo.ship_icon4)
  end
  self:_ShowMedal()
end

function HomePage:_ShowMedal()
  local medalValue = Data.userData:GetCurrency(CurrencyType.MEDAL)
  if medalValue <= 0 then
    self.m_tabWidgets.obj_medal:SetActive(false)
    self.m_tabWidgets.rect_userInfo.anchoredPosition = Vector2.New(self.m_tabWidgets.rect_userInfo.anchoredPosition.x, -611)
    return
  end
  local iconTab = Logic.currencyLogic:GetMedalIconTab()
  self.m_tabWidgets.rect_userInfo.anchoredPosition = Vector2.New(self.m_tabWidgets.rect_userInfo.anchoredPosition.x, -597)
  self.m_tabWidgets.obj_medal:SetActive(true)
  UIHelper.SetImage(self.m_tabWidgets.img_primaryMedal, iconTab[1])
  UIHelper.SetImage(self.m_tabWidgets.img_highMedal, iconTab[2])
  if medalValue < MEDAL_LIMIT then
    self.m_tabWidgets.txt_pMedalNum.text = "x" .. math.tointeger(medalValue)
    self.m_tabWidgets.txt_hMedalNum.text = "x0"
  else
    local highNum = math.floor(medalValue / MEDAL_LIMIT)
    local primaryNum = medalValue % MEDAL_LIMIT
    self.m_tabWidgets.txt_hMedalNum.text = "x" .. math.tointeger(highNum)
    self.m_tabWidgets.txt_pMedalNum.text = "x" .. math.tointeger(primaryNum)
  end
end

function HomePage:_ConcealName(param)
  self.m_tabWidgets.obj_name:SetActive(not param)
end

function HomePage:_SetSecretary()
  local param = {}
  local secretaryId = configManager.GetDataById("config_parameter", 17).value
  if self.m_secretaryInfo == nil or self.m_secretaryInfo.ship_icon == "1" then
    local ship = Logic.shipLogic:GetShipShowById(secretaryId)
    self.m_secretaryInfo = ship
    param = {
      showID = ship.ss_id,
      dressID = configManager.GetDataById("config_ship_model", ship.model_id).standard_normal
    }
  else
    param = {
      showID = self.m_secretaryInfo.ss_id,
      dressID = self.m_modelDress,
      heroID = Data.userData:GetUserData().SecretaryId
    }
  end
  local changeGirl = Logic.homeLogic:GetChangeGirl()
  local playLogin = changeGirl
  self.m_bSelectLeft = Logic.homeLogic:GetLeftPageState()
  local tabUserInfo = Data.userData:GetUserData()
  local isMarry = false
  if tabUserInfo.HeadShow and tabUserInfo.HeadShow == 1 then
    isMarry = true
  end
  eventManager:SendEvent(LuaEvent.IsMarry, isMarry)
  eventManager:SendEvent(LuaEvent.HomeChangeShipGirl, {
    param,
    self.m_bSelectLeft,
    playLogin,
    changeGirl
  })
  eventManager:SendEvent(LuaEvent.HideGirlMech, not self.hideMech)
  Logic.homeLogic:SetChangeGirl(false)
  self.param = nil
end

function HomePage:_ClickModel(bHideBtn)
  if not self.bCouldHide then
    return
  end
  if bHideBtn then
    self:_ShowBottomBtn(bHideBtn)
  elseif self.bClickShow then
    self:_ShowBottomBtn(bHideBtn)
  end
end

function HomePage:_TurnShowBtn(curBack)
  UIHelper.SetUILock(true)
  self.m_tabWidgets.script_pressure.enabled = false
  local tweenRota = self.m_tabWidgets.tween_rota
  tweenRota:SetOnFinished(function()
    UIHelper.SetUILock(false)
    self.m_tabWidgets.script_pressure.enabled = true
    if not curBack then
      self.m_tabWidgets.tweenPos_right.gameObject:SetActive(false)
      self.m_tabWidgets.tweenPos_left.gameObject:SetActive(false)
      self.m_tabWidgets.tweenPos_other.gameObject:SetActive(false)
    end
  end)
  tweenRota:Play(not curBack)
end

function HomePage:_ClickHideBtn()
  self.bClickShow = self.m_bShowBtn
  self:_ShowBottomBtn(not self.bClickShow)
  self:_ConcealName(not self.bClickShow)
end

function HomePage:_ShowARKit(param)
  local isSupportHome = XR:IsSupportHome()
  local bNotInGuide = not GR.guideHub:isInGuide()
  self.m_tabWidgets.obj_ARKit:SetActive(param and isSupportHome and bNotInGuide)
end

function HomePage:_ShowBottomBtn(bHideBtn)
  UIHelper.SetUILock(false)
  local isSupportHome = XR:IsSupportHome()
  local bNotInGuide = not GR.guideHub:isInGuide()
  if bHideBtn == self.m_bShowBtn then
    return
  end
  if bHideBtn then
    self.m_tabWidgets.obj_top:SetActive(false)
    self:_ConcealName(true)
    self.m_tabWidgets.trans_bottomContent.gameObject:SetActive(false)
    self.m_tabWidgets.obj_bottom:SetActive(false)
    self.m_tabWidgets.obj_chat:SetActive(false)
    self.m_tabWidgets.tweenPos_left:Play(true)
    self.m_tabWidgets.tweenPos_right:Play(true)
    self:_noticeGuideCacheData(false)
    self.m_tabWidgets.tweenPos_other:Play(true)
    self.m_bShowBtn = true
    self:_TurnShowBtn(false)
    self.m_tabWidgets.tween_talk:Play(false)
    self.m_tabWidgets.btn_photograph.gameObject:SetActive(platformManager:useSDK() and platformManager:ShowShare())
    self.m_tabWidgets.obj_ARKit:SetActive(isSupportHome and bNotInGuide)
  else
    self.m_tabWidgets.obj_top:SetActive(true)
    self:_ConcealName(false)
    self.m_tabWidgets.trans_bottomContent.gameObject:SetActive(true)
    self.m_tabWidgets.obj_bottom:SetActive(true)
    actEnter:_CreateBanner()
    self.m_tabWidgets.tweenPos_right.gameObject:SetActive(true)
    self.m_tabWidgets.tweenPos_left.gameObject:SetActive(true)
    self.m_tabWidgets.tweenPos_other.gameObject:SetActive(true)
    self.m_tabWidgets.obj_chat:SetActive(true)
    self.m_tabWidgets.tweenPos_left:Play(false)
    self.m_tabWidgets.tweenPos_right:Play(false)
    self.m_tabWidgets.tweenPos_other:Play(false)
    eventManager:SendEvent(LuaEvent.HomeCameraChange, true)
    self:_noticeGuideCacheData(true)
    self.m_bShowBtn = false
    self:_TurnShowBtn(true)
    self.m_tabWidgets.tween_talk:Play(true)
    self.m_tabWidgets.btn_photograph.gameObject:SetActive(false)
    self.m_tabWidgets.obj_ARKit:SetActive(false)
  end
end

function HomePage:_MatchJoinARKit()
  Logic.battleManager:JoinArPcp()
end

function HomePage:_OpenChat()
  local haveUnRead = Logic.chatLogic:HaveUnReadMsgByChannel(ChatChannel.Personal)
  if haveUnRead then
    Data.chatData:SetChatChannel(ChatChannel.Personal)
    local uid = Data.chatData:GetNowChatUserInfo()
    Data.chatData:ResetUnReadNumByUid(uid)
  end
  UIHelper.OpenPage("ChatPage")
end

function HomePage:_GetBrowseInfoCallBack(str)
  if str == "" then
    noticeManager:OpenTipPage(self, "\230\180\187\229\138\168\231\187\147\230\157\159")
    return
  end
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  if isWindows then
    deviceWidth = 700
    deviceHeight = 400
    posX = -1
    posY = -1
  end
  platformManager:openCustomWebView(str, deviceWidth, deviceHeight, posX, posY, "1")
end

function HomePage:_HomeClickShip(animName)
  local dotInfo = {
    info = "click_ship",
    ship_name = self.m_secretaryInfo.ship_name,
    behavior_name = animName
  }
  RetentionHelper.Retention(PlatformDotType.clickLog, dotInfo)
end

function HomePage:_OpenTask()
  UIHelper.OpenPage("TaskPage")
end

function HomePage:_MainTask()
  local widgets = self:GetWidgets()
  local typeOrder = {
    TaskType.Grow,
    TaskType.Main,
    TaskType.Daily,
    TaskType.Week
  }
  local firstTodoTask
  for _, type in ipairs(typeOrder) do
    firstTodoTask = Logic.taskLogic:GetFirstTaskByType(type)
    if firstTodoTask then
      break
    end
  end
  widgets.txt_task.gameObject:SetActive(firstTodoTask)
  widgets.txt_taskdone.gameObject:SetActive(not firstTodoTask)
  if firstTodoTask then
    UIHelper.SetText(widgets.txt_taskTitle, firstTodoTask.Config.title)
    UIHelper.SetText(widgets.txt_task, firstTodoTask.Config.desc)
  else
    UIHelper.SetText(widgets.txt_taskTitle, "")
    UIHelper.SetText(widgets.txt_taskdone, UIHelper.GetString(340019))
  end
end

function HomePage:_OpenAssistTip()
  if not moduleManager:CheckFunc(FunctionID.SupportFleet, true) then
    return
  end
  UIHelper.OpenPage("AssistQuickpage")
end

function HomePage:_ShowModuleSelect(go, isOn)
  local widgets = self:GetWidgets()
  widgets.obj_moduleselect:SetActive(isOn)
end

function HomePage:_OpenMail()
  if moduleManager:CheckFunc(FunctionID.Email, true) then
    moduleManager:JumpToFunc(FunctionID.Email, nil)
  end
end

function HomePage:_OpenFriend()
  if moduleManager:CheckFunc(FunctionID.Friend, true) then
    Logic.friendLogic:SetTogIndex(-1)
    moduleManager:JumpToFunc(FunctionID.Friend, nil)
  end
end

function HomePage:DoOnHide()
  self.bShowBtn = false
  RetentionHelper.SkipAllBehaviour()
  eventManager:SendEvent(LuaEvent.HomeResetModel)
  if self.m_bottomObj ~= nil then
    self.m_bottomObj:SetActive(false)
  end
  actEnter:ResetBanner()
  announcementManager:DisableAnnoucement()
  self:_StopTimer()
  self:_ShowModuleSelect(nil, false)
  eventManager:SendEvent(LuaEvent.StopNewYearEff)
end

function HomePage:DoOnClose()
  actEnter:ClearBannerTimer()
  eventManager:SendEvent(LuaEvent.StopNewYearEff)
  Logic.battleManager:UnRegisterBattleEvent("matchLeaveMsg", "Homepage__OnReceiveMatchLeave")
  Logic.battleManager:UnRegisterBattleEvent("matchJoinMsg", "Homepage_ReceiveMatchJoin")
end

function HomePage:_GiftCommit()
  local si_id = self.m_tabWidgets.giftInput.text
  si_id = si_id == "" and 1053031 or si_id
  UIHelper.OpenPage("ShowGirlPage", {
    girlId = tonumber(si_id),
    HeroId = heroId
  })
end

function HomePage:BuildSuccess()
  self.build_timer = self:CreateTimer(function()
    self:_TickBuildCharge()
  end, 10, -1, false)
  self:StartTimer(self.build_timer)
end

function HomePage:_TickBuildCharge()
  self:StartTimer(self.build_timer)
  local sequeData = Data.buildData:GetData()
  local timeServer = time.getSvrTime()
  for v, k in pairs(sequeData.BuildingList) do
    if timeServer >= k.EndTime then
      Service.buildService:SendBuildGirlInfo()
    end
  end
end

function HomePage:_OpenARKit()
  UIHelper.OpenPage("ARKitPage")
end

function HomePage:_ChangeAnnouncementState(ret)
  self.m_tabWidgets.btn_announcement.gameObject:SetActive(ret)
end

function HomePage:_ClickAnnouncementBtn()
  announcementManager:OpenAnnouncement()
end

function HomePage:_setObjHideShow(bShow)
  self.m_tabWidgets.obj_hide:SetActive(bShow)
  self:_noticeGuideCacheData(bShow)
end

function HomePage:_noticeGuideCacheData(bShow)
  GR.guideHub:getGuideCachedata():SetHomePageIsHideShow(bShow)
end

function HomePage:_InitHomePartShow()
  self.m_tabWidgets.obj_talk:SetActive(false)
  self.m_tabWidgets.obj_top:SetActive(not self.m_bShowBtn)
  self.m_tabWidgets.obj_hide:SetActive(self.m_bShowHideBtn and self.bClickShow)
  self:_setObjHideShow(self.m_bShowHideBtn)
end

function HomePage:_RegisterActSSRRedDot()
  local widgets = self:GetWidgets()
  widgets.im_redDotAct.gameObject:SetActive(false)
  local redId, actId = Logic.activitySSRLogic:RegisterRed()
  if redId then
    self:RegisterRedDotById(widgets.im_redDotAct, {redId}, actId)
  end
end

function HomePage:_ActGotoPage()
  local actId = Logic.activitySSRLogic:ActGotoPage()
  local config = configManager.GetDataById("config_activity", actId)
  local actIndex = config.banner_goto
  local openPage = config.banner_gotopage
  if openPage ~= "" then
    UIHelper.OpenPage(openPage, actIndex)
  else
    Data.activityData:SetTag(actId)
    UIHelper.OpenPage("ActivityPage")
  end
end

function HomePage:_WalkDog()
  local serverData = Data.copyData:GetWalkDogData()
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = serverData,
    chapterId = WalkDogChapterId,
    IsRunningFight = false,
    copyId = serverData.BaseId
  }
  Logic.copyLogic:SetEnterLevelInfo(true)
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function HomePage:_RefreshSetSecretary()
  self:_PlayerData()
  self:_SetSecretary()
end

function HomePage:_OnClickBattlePass()
  if not Logic.battlepassLogic:IsBattlePassActivityOpen() then
    logError("activity not open")
    return
  end
  if not moduleManager:CheckFunc(FunctionID.BattlePass, true) then
    return
  end
  UIHelper.OpenPage("BattlePassPage")
end

function HomePage:_ClickBossEnter()
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  if activityID then
    local timeNow = time.getSvrTime()
    local stage = Logic.bossCopyLogic:GetBossStageByTime(timeNow)
    if stage == BossStage.ActBattleBoss then
      PlayerPrefs.SetInt(PlayerPrefsKey.ActBossEnter .. self.uid, timeNow)
    end
    self:_UpdateBossEnter()
    local bossConf = configManager.GetDataById("config_home_activity_enter", WorldBossID)
    moduleManager:JumpToFunc(bossConf.jump_function, table.unpack(bossConf.jump_para))
  end
end

function HomePage:_UpdateBossEnter()
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  if activityID then
    self.m_tabWidgets.btn_bosscopy.gameObject:SetActive(true)
  else
    self.m_tabWidgets.btn_bosscopy.gameObject:SetActive(false)
    return
  end
  local timeNow = time.getSvrTime()
  local timeClick = PlayerPrefs.GetInt(PlayerPrefsKey.ActBossEnter .. self.uid, 0)
  local stage1 = Logic.bossCopyLogic:GetBossStageByTime(timeNow)
  local stage2 = Logic.bossCopyLogic:GetBossStageByTime(timeClick)
  if stage1 == BossStage.ActBattleBoss and stage2 == BossStage.ActKillBoss and timeNow > timeClick then
    self.tab_Widgets.obj_bossNew:SetActive(true)
    self.tab_Widgets.obj_bossClear:SetActive(false)
  elseif stage1 == BossStage.ActKillBoss then
    self.tab_Widgets.obj_bossNew:SetActive(false)
    self.tab_Widgets.obj_bossClear:SetActive(true)
  else
    self.tab_Widgets.obj_bossNew:SetActive(false)
    self.tab_Widgets.obj_bossClear:SetActive(false)
  end
end

return HomePage
