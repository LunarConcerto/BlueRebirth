local DisPlaySettingPage = class("UI.Player.DisPlaySettingPage", LuaUIPage)
local QualityItem = require("ui.page.Player.QualityItem")
local controlScaleUIBase = 1

function DisPlaySettingPage:DoInit()
  self.m_threeItemList = {}
  self.m_switchItemList = {}
  self.m_fenbianlvList = {}
  self.m_fourItemList = {}
  self.isSoundTrue = true
  self:InitGlobalToggleGroup()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.timer = nil
  self.mTgList_AnimMode = {
    self.tab_Widgets.tgAnimMode_Normal,
    self.tab_Widgets.tgAnimMode_Simple
  }
end

function DisPlaySettingPage:DoOnOpen()
  self:OpenTopPage("DisplaySetPage", 1, "\232\174\190\231\189\174", self, true)
  self.m_data = self.param or SettingHelper.GetAllSetting()
  local data = self.m_data
  local widgets = self:GetWidgets()
  self.m_showObj = {
    [0] = widgets.obj_picture,
    [1] = widgets.obj_sound,
    [2] = widgets.obj_operate,
    [3] = widgets.obj_other,
    [4] = widgets.obj_notice
  }
  self.tabTags = {
    widgets.tween_picture,
    widgets.tween_sound,
    widgets.tween_operate,
    widgets.tween_other,
    widgets.tween_notice
  }
  self.tabTog = {
    widgets.tog_picture,
    widgets.tog_sound,
    widgets.tog_operate,
    widgets.tog_other,
    widgets.tog_notice
  }
  self:InitUI()
  self:PlatformUISet()
  self:RefreshVolumeSlider(data.volumeData)
  self:RefreshOperate(data.operateData)
  self:RefreshOther(data.otherData)
  self:RefreshSpeed(data.speedData)
  self:RefreshNotice(data.noticeData)
  self:RefreshTorpedoOperate(data.operateData)
  local dotinfo = {
    info = "ui_set_common"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  widgets.obj_window:SetActive(false)
  self.timer = FrameTimer.New(function()
    self:FirstSetGlobal()
  end, 1, 1)
  self.timer:Start()
end

function DisPlaySettingPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UIHelper.AddToggleGroupChangeValueEvent(widgets.togp_global, self, nil, self._SetGlobalQuality)
  UGUIEventListener.AddButtonOnClick(widgets.btn_download, self.OnClickDownload, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_bgm, self, nil, self._ChangeBgmValue)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_audio, self, nil, self._ChangeAudioValue)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_cv, self, nil, self._ChangeCvValue)
  UGUIEventListener.AddButtonOnClick(widgets.btn_reset, self.OnClickReset, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_nosound, self.OnClickNoSound, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_scale, self, nil, self.OnScaleChange)
  UGUIEventListener.AddButtonOnClick(widgets.btn_switch, self.SendLogOff, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.SendLogOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_gm, self._OnClickGM, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancal, self.SendLogCancel, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group, self, nil, self._SetShowType)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.modeGroup, self, nil, self._SetOperateMode)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.speedGroup, self, nil, self._SetSpeedMode)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.otherGroup, self, nil, self._SetSkillAnimSpeed)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_player, self._SetPlayerSkipSkillAnim, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_enemy, self._SetEnemySkipSkillAnim, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_enemyTorpedoAnim, self._SetEnemyTorpedoAnim, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_nearBullet, self._SetNearBulletAnim, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_hitmiss, self._SetSkipSkillAnimResul, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_autoAttak, self._SetBattleResultAutoContinueSearch, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_bathRoom, self._SetBathroomAnimShow, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_showGroup, self, "", self._SetShowOperationWhenAnim)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_hitCameraZoom, self._SetSkipHitCameraZoom, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_supply, self._SetSupplyNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_wishwall, self._SetWishWallNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_supportfleet, self._SetSupportFleetNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_build, self._SetBuildNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_bath, self._SetBathNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_mood, self._SetMoodNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_produce, self._SetProduceNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_oil, self._SetOilNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_gold, self._SetGoldNotice, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_buildship, self._SetFreeBuildShipNotice, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_grouptorpedo, self, nil, self._SetOperateTorpedoMode)
  self.tab_Widgets.tgGroupAnimMode:ClearToggles()
  for _, toggle in ipairs(self.mTgList_AnimMode) do
    self.tab_Widgets.tgGroupAnimMode:RegisterToggle(toggle)
  end
  self:_initTogs_AnimMode()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupAnimMode, self, "", self._SwitchTogs_AnimMode)
  self:RegisterEvent(LuaEvent.QualityChange, self.CheckNeedSave, self)
  self:RegisterEvent(LuaEvent.vivoFpsSetting, self.VivoFPSChange, self)
  self:RegisterEvent(LuaEvent.LogoffOk, self.Logoff, self)
  self:_CheckFuncUnlock()
end

function DisPlaySettingPage:_CheckFuncUnlock()
  local widgets = self:GetWidgets()
  local conf = configManager.GetDataById("config_function_info", tostring(FunctionID.DoubleSpeed))
  if not moduleManager:CheckFunc(FunctionID.DoubleSpeed, false) then
    widgets.otherGroup:ResigterToggleUnActive(1, function()
      noticeManager:ShowTip(conf.comment)
    end)
  end
  local conf2 = configManager.GetDataById("config_function_info", tostring(FunctionID.TripleSpeed))
  if not moduleManager:CheckFunc(FunctionID.TripleSpeed, false) then
    widgets.otherGroup:ResigterToggleUnActive(2, function()
      noticeManager:ShowTip(conf2.comment)
    end)
  end
end

function DisPlaySettingPage:DoOnHide()
end

function DisPlaySettingPage:DoOnClose()
  self:SaveAll()
  self:SendDot()
  self:_ClearEvent()
end

function DisPlaySettingPage:SaveAll()
  SettingHelper.SaveAllSetting()
end

function DisPlaySettingPage:SendDot()
  local dotinfo = {}
  dotinfo.deviceInfo = platformManager:GetDeviceInfo()
  dotinfo.globalQuality = self.m_data.globalQuality
  dotinfo.cv = PlayerPrefs.GetFloat("cv_volume", 100)
  dotinfo.audio = PlayerPrefs.GetFloat("audio_volume", 100)
  dotinfo.bgm = PlayerPrefs.GetFloat("bgm_volume", 100)
  dotinfo.operateMode = CacheUtil.GetBattleRotationOpe()
  dotinfo.speedMode = CacheUtil.GetBattleRightAreaOpe()
  dotinfo.battleRole = GR.qualityManager:getQualityLvByType(QualityType.OutlineQuality)
  dotinfo.shadow = GR.qualityManager:getQualityLvByType(QualityType.ShadowQuality)
  dotinfo.shader = GR.qualityManager:getQualityLvByType(QualityType.ShaderQuality)
  dotinfo.resolution = GR.qualityManager:getQualityLvByType(QualityType.ResolutionQuality)
  dotinfo.bones = GR.qualityManager:getQualityLvByType(QualityType.ActionQuality)
  dotinfo.postProcess = GR.qualityManager:getQualityLvByType(QualityType.PostProcessQuality)
  dotinfo.animation = CacheUtil.GetBattleGameSpeedIndex()
  dotinfo.antiAliasing = GR.qualityManager:getQualityLvByType(QualityType.AntiAliasingQuality)
  dotinfo.FPS = GR.qualityManager:getQualityLvByType(QualityType.FpsQuality) == 0 and 30 or 60
  dotinfo.scale = string.format("%.1f", CacheUtil.GetOpeRatationAddRadio() + 1)
  dotinfo.showMode = CacheUtil.GetShowOperationWhenAnim() and 1 or 0
  dotinfo.skipEnemyTorp = CacheUtil.GetSkipEnemyTorpedoPlayAnim() and 1 or 0
  dotinfo.skipNearloss = CacheUtil.GetSkipZhiJingDanBuffAnim() and 1 or 0
  dotinfo.skipBath = Logic.setLogic:GetBathAnimOption()
  dotinfo.Autoassault = CacheUtil.GetBattleResultAutoContinueSearch() and 1 or 0
  dotinfo.skipOwnAnimation = CacheUtil.GetIsSkipSkillAnimIndex(true) and 1 or 0
  dotinfo.skipEnemyAnimation = CacheUtil.GetIsSkipSkillAnimIndex(false) and 1 or 0
  dotinfo.skipAttackAnimation = CacheUtil.GetSkipSkillAnimResult() and 1 or 0
  RetentionHelper.Retention(PlatformDotType.setting, dotinfo)
end

function DisPlaySettingPage:_ClearEvent()
end

function DisPlaySettingPage:_SetShowType(types)
  for k, v in pairs(self.tabTags) do
    local position = self.tabTog[k]:GetComponent(RectTransform.GetClassType())
    position = position.anchoredPosition
    if k == types + 1 then
      self.tabTags[k].from = position
      self.tabTags[k].to = Vector3.New(configManager.GetDataById("config_parameter", 267).arrValue[0], position.y, 0)
      self.tabTags[k]:Play(true)
    else
      self.tabTags[k].from = position
      self.tabTags[k].to = Vector3.New(configManager.GetDataById("config_parameter", 267).arrValue[1], position.y, 0)
      self.tabTags[k]:Play(true)
    end
  end
  for i, v in pairs(self.m_showObj) do
    v:SetActive(types == i)
  end
end

function DisPlaySettingPage:_SetOperateMode(mode)
  SettingHelper.SetOperateMode(OperateMode[mode])
end

function DisPlaySettingPage:_SetSpeedMode(index)
  SettingHelper.SetSpeedMode(SpeedIndexMode[index])
end

function DisPlaySettingPage:_SetPlayerSkipSkillAnim(go, isSkip)
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipPlayerSkipSkillAnim, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  SettingHelper.SetPlayerSkipSkillAnim(isSkip)
end

function DisPlaySettingPage:_SetEnemySkipSkillAnim(go, isSkip)
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipEnemySkipSkillAnim, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  SettingHelper.SetEnemySkipSkillAnim(isSkip)
end

function DisPlaySettingPage:_SetEnemyTorpedoAnim(go, isSkip)
  SettingHelper.SetEnemyTorpedoAnim(isSkip)
end

function DisPlaySettingPage:_SetNearBulletAnim(go, isSkip)
  SettingHelper.SetNearBulletAnim(isSkip)
end

function DisPlaySettingPage:_SetSkillAnimSpeed(index)
  SettingHelper.SetSkillAnimSpeed(index)
end

function DisPlaySettingPage:_SetControlScale(value)
  SettingHelper.SetControlScale(value)
end

function DisPlaySettingPage:_SetGlobalQuality(quality)
  SettingHelper.SetQuality(quality)
  self.m_data.globalQuality = quality
  self:RefreshQualitySettings()
  if quality ~= GlobalQuality.Custom then
    self.m_needSave = true
  end
end

function DisPlaySettingPage:_SetOperateTorpedoMode(mode)
  SettingHelper.SetTorpedoMode(TorpedoMode[mode])
end

function DisPlaySettingPage:OnBGMChange(volume)
  SettingHelper.SetBGMVolume(volume)
  SoundManager.Instance:SetBGMVolume(volume * 100)
end

function DisPlaySettingPage:OnAudioChange(volume)
  SettingHelper.SetAudioVolume(volume)
  SoundManager.Instance:SetAudioVolume(volume * 100)
end

function DisPlaySettingPage:OnCVChange(volume)
  SettingHelper.SetCVVolume(volume)
  SoundManager.Instance:SetCVVolume(volume * 100)
end

function DisPlaySettingPage:OnScaleChange(index)
  local value = 0.1 * (index - 2)
  self:_SetControlScale(value)
end

function DisPlaySettingPage:_SetSkipSkillAnimResul(go, isSkip)
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipShipSkillFeedBack, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  SettingHelper.SetSkipSkillAnimResul(isSkip)
end

function DisPlaySettingPage:_SetBattleResultAutoContinueSearch(go, isSkip)
  SettingHelper.SetBattleResultAutoContinueSearch(isSkip)
end

function DisPlaySettingPage:_SetBathroomAnimShow(go, isOpen)
  SettingHelper.SetBathroomAnim(isOpen)
end

function DisPlaySettingPage:_SetShowOperationWhenAnim(index)
  SettingHelper.SetShowOperationWhenAnim(index == 0)
end

function DisPlaySettingPage:_SetSkipHitCameraZoom(go, isSkip)
  SettingHelper.SetSkipHitCameraZoom(isSkip)
end

function DisPlaySettingPage:_SetSupplyNotice(go, isSkip)
  SettingHelper.SetSupplyNotice(isSkip)
end

function DisPlaySettingPage:_SetWishWallNotice(go, isSkip)
  SettingHelper.SetWishWallNotice(isSkip)
end

function DisPlaySettingPage:_SetSupportFleetNotice(go, isSkip)
  SettingHelper.SetSupportFleetNotice(isSkip)
end

function DisPlaySettingPage:_SetBuildNotice(go, isSkip)
  SettingHelper.SetBuildNotice(isSkip)
end

function DisPlaySettingPage:_SetBathNotice(go, isSkip)
  SettingHelper.SetBathNotice(isSkip)
end

function DisPlaySettingPage:_SetMoodNotice(go, isSkip)
  SettingHelper.SetMoodNotice(isSkip)
end

function DisPlaySettingPage:_SetProduceNotice(go, isSkip)
  SettingHelper.SetProduceNotice(isSkip)
end

function DisPlaySettingPage:_SetOilNotice(go, isSkip)
  SettingHelper.SetOilNotice(isSkip)
end

function DisPlaySettingPage:_SetGoldNotice(go, isSkip)
  SettingHelper.SetGoldNotice(isSkip)
end

function DisPlaySettingPage:_SetFreeBuildShipNotice(go, isSkip)
  SettingHelper.SetFreeBuildShipNotice(isSkip)
end

function DisPlaySettingPage:_initTogs_AnimMode()
  local animMode = CacheUtil.GetUseSimpleAnim()
  self.tab_Widgets.tgGroupAnimMode:SetActiveToggleIndex(animMode)
end

function DisPlaySettingPage:_SwitchTogs_AnimMode(index)
  SettingHelper.SetAnimMode(index)
end

function DisPlaySettingPage:OnClickDownload(go)
end

function DisPlaySettingPage:_ChangeBgmValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("Pause_all_music")
  else
    SoundManager.Instance:PlayAudio("Resume_all_music")
  end
  SettingHelper.SetBGMVolume(volume)
  SoundManager.Instance:SetBGMVolume(volume)
end

function DisPlaySettingPage:_ChangeAudioValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("SFX_Mute")
  else
    SoundManager.Instance:PlayAudio("SFX_Unmute")
  end
  SettingHelper.SetAudioVolume(volume)
  SoundManager.Instance:SetAudioVolume(volume)
end

function DisPlaySettingPage:_ChangeCvValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("CV_Mute")
  else
    SoundManager.Instance:PlayAudio("CV_Unmute")
  end
  SettingHelper.SetCVVolume(volume)
  SoundManager.Instance:SetCVVolume(volume)
end

function DisPlaySettingPage:OnClickReset()
  local widgets = self:GetWidgets()
  widgets.tog_group_bgm:SetActiveToggleIndex(3)
  widgets.tog_group_audio:SetActiveToggleIndex(3)
  widgets.tog_group_cv:SetActiveToggleIndex(3)
end

function DisPlaySettingPage:OnClickNoSound()
  local widgets = self:GetWidgets()
  widgets.tog_group_bgm:SetActiveToggleIndex(0)
  widgets.tog_group_audio:SetActiveToggleIndex(0)
  widgets.tog_group_cv:SetActiveToggleIndex(0)
end

function DisPlaySettingPage:SendLogOff()
  self.m_tabWidgets.obj_window:SetActive(true)
end

function DisPlaySettingPage:SendLogOk()
  self:Logoff()
  Logic.loginLogic:SetOptOff(true)
end

function DisPlaySettingPage:_OnClickGM()
  Logic.displaySettingLogic:SetAnswerState(false)
  if isWindows then
    local ret = platformManager:SubmitQuestion()
    platformManager:openCustomWebView(ret, 1000, 532, -1, -1, "0", UIHelper.GetString(2700005))
  else
    UIHelper.OpenPage("GameMasterPage", nil, 5)
  end
end

function DisPlaySettingPage:SendLogCancel()
  self.m_tabWidgets.obj_window:SetActive(false)
end

function DisPlaySettingPage:Logoff()
  platformManager:logout(function()
    stageMgr:Goto(EStageType.eStageLaunch)
  end)
end

function DisPlaySettingPage:RefreshQualitySettings()
  local data = SettingHelper.GetQualitySetting()
  local widgets = self:GetWidgets()
  local isVivoNew = DeviceAdapter.isVivoNew()
  UIHelper.CreateSubPart(widgets.item_quality, widgets.tran_grid, #data.three, function(nIndex, tabPart)
    local item
    local data = data.three[nIndex]
    item = self.m_threeItemList[nIndex] or QualityItem:new()
    self.m_threeItemList[nIndex] = item
    item:SetData(data, tabPart)
  end)
  UIHelper.CreateSubPart(widgets.item_quality1, widgets.tran_grid1, #data.switch, function(nIndex, tabPart)
    local item = self.m_switchItemList[nIndex] or QualityItem:new()
    self.m_switchItemList[nIndex] = item
    item:SetData(data.switch[nIndex], tabPart)
  end)
  UIHelper.CreateSubPart(widgets.item_quality2, widgets.tran_grid2, #data.fenbianlv, function(nIndex, tabPart)
    local item
    local data = data.fenbianlv[nIndex]
    local bNew = false
    local bFPS = data.type == QualityType.FpsQuality
    if isVivoNew and bFPS then
      bNew = self.m_fenbianlvList[nIndex] == nil
      item = self.m_fenbianlvList[nIndex] or require("ui.page.Player.vivoFpsQualityItem"):new()
    else
      item = self.m_fenbianlvList[nIndex] or QualityItem:new()
    end
    self.m_fenbianlvList[nIndex] = item
    if not bNew and isVivoNew and bFPS then
    else
      item:SetData(data, tabPart)
    end
  end)
  UIHelper.CreateSubPart(widgets.item_quality3, widgets.tran_grid3, #data.four, function(nIndex, tabPart)
    local item = self.m_fourItemList[nIndex] or QualityItem:new()
    self.m_fourItemList[nIndex] = item
    item:SetData(data.four[nIndex], tabPart)
  end)
end

function DisPlaySettingPage:InitGlobalToggleGroup()
  local widgets = self:GetWidgets()
  widgets.togp_global:ClearToggles()
  widgets.togp_global:RegisterToggle(widgets.tog_low)
  widgets.togp_global:RegisterToggle(widgets.tog_medium)
  widgets.togp_global:RegisterToggle(widgets.tog_high)
  widgets.togp_global:RegisterToggle(widgets.tog_superhigh)
  widgets.togp_global:RegisterToggle(widgets.tog_custom)
  widgets.tog_group:ClearToggles()
  widgets.tog_group:RegisterToggle(widgets.tog_picture)
  widgets.tog_group:RegisterToggle(widgets.tog_sound)
  widgets.tog_group:RegisterToggle(widgets.tog_operate)
  widgets.tog_group:RegisterToggle(widgets.tog_other)
  widgets.tog_group:RegisterToggle(widgets.tog_notice)
  widgets.modeGroup:ClearToggles()
  widgets.modeGroup:RegisterToggle(widgets.tog_rudder)
  widgets.modeGroup:RegisterToggle(widgets.tog_direct)
  widgets.tog_showGroup:ClearToggles()
  widgets.tog_showGroup:RegisterToggle(widgets.tog_show)
  widgets.tog_showGroup:RegisterToggle(widgets.tog_hide)
  widgets.otherGroup:ClearToggles()
  widgets.otherGroup:RegisterToggle(widgets.tog_speed1)
  widgets.otherGroup:RegisterToggle(widgets.tog_speed2)
  widgets.otherGroup:RegisterToggle(widgets.tog_speed3)
  widgets.speedGroup:ClearToggles()
  widgets.speedGroup:RegisterToggle(widgets.tog_spMode1)
  widgets.speedGroup:RegisterToggle(widgets.tog_spMode2)
  widgets.tog_grouptorpedo:ClearToggles()
  widgets.tog_grouptorpedo:RegisterToggle(widgets.tog_manualtorpedo)
  widgets.tog_grouptorpedo:RegisterToggle(widgets.tog_autotorpedo)
end

function DisPlaySettingPage:FirstSetGlobal()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  local widgets = self:GetWidgets()
  local data = self.m_data
  widgets.togp_global:SetActiveToggleIndex(data.globalQuality)
  local initIndex = isWindows and 1 or 0
  widgets.tog_group:SetActiveToggleIndex(initIndex)
  if data.globalQuality ~= GlobalQuality.Custom then
    self.m_needSave = true
  end
end

function DisPlaySettingPage:PlatformUISet()
  local widgets = self:GetWidgets()
  widgets.tog_picture.gameObject:SetActive(not isWindows)
  widgets.tog_notice.gameObject:SetActive(isIOS)
end

function DisPlaySettingPage:RefreshVolumeSlider(data)
  local widgets = self:GetWidgets()
  local bgmIndex = data.bgm == 100 and 3 or data.bgm / 33
  local audioIndex = data.audio == 100 and 3 or data.audio / 33
  local cvIndex = data.cv == 100 and 3 or data.cv / 33
  widgets.tog_group_bgm:SetActiveToggleIndex(bgmIndex)
  widgets.tog_group_audio:SetActiveToggleIndex(audioIndex)
  widgets.tog_group_cv:SetActiveToggleIndex(cvIndex)
end

function DisPlaySettingPage:RefreshOperate(data)
  local widgets = self:GetWidgets()
  widgets.modeGroup:SetActiveToggleIndex(data.operateMode)
  widgets.tog_showGroup:SetActiveToggleIndex(IsShowAnim[data.showAnim])
end

function DisPlaySettingPage:RefreshSpeed(data)
  local widgets = self:GetWidgets()
  widgets.speedGroup:SetActiveToggleIndex(SpeedModeIndex[data.speedMode])
end

function DisPlaySettingPage:RefreshOther(data)
  local widgets = self:GetWidgets()
  widgets.otherGroup:SetActiveToggleIndex(data.otherData.animSpeed)
  widgets.tog_enemy.isOn = data.otherData.enemy
  widgets.tog_player.isOn = data.otherData.player
  widgets.tog_hitmiss.isOn = data.otherData.hitmiss
  widgets.tog_autoAttak.isOn = data.otherData.autoAttak
  widgets.tog_enemyTorpedoAnim.isOn = data.otherData.enemyTorpedo
  widgets.tog_nearBullet.isOn = data.otherData.nearBullet
  widgets.tog_bathRoom.isOn = data.otherData.bathroom
  widgets.tog_hitCameraZoom.isOn = data.otherData.hitCameraZoom
end

function DisPlaySettingPage:RefreshNotice(data)
  local widgets = self:GetWidgets()
  widgets.tog_supply.isOn = data.supplyInTwelve
  widgets.tog_wishwall.isOn = data.wishWall
  widgets.tog_supportfleet.isOn = data.supportFleet
  widgets.tog_build.isOn = data.build
  widgets.tog_bath.isOn = data.bath
  widgets.tog_mood.isOn = data.mood
  widgets.tog_produce.isOn = data.produce
  widgets.tog_oil.isOn = data.oil
  widgets.tog_gold.isOn = data.gold
  widgets.tog_buildship.isOn = data.freeBuildShip
end

function DisPlaySettingPage:RefreshTorpedoOperate(data)
  local widgets = self:GetWidgets()
  widgets.tog_grouptorpedo:SetActiveToggleIndex(data.torpedoMode)
end

function DisPlaySettingPage:CheckNeedSave()
  if self.m_needSave then
    local widgets = self:GetWidgets()
    self:SaveAll()
    self.m_needSave = false
    widgets.togp_global:SetActiveToggleIndex(GlobalQuality.Custom)
  end
end

function DisPlaySettingPage:VivoFPSChange(nLv)
  if nLv == 1 then
    local curLv = GR.qualityManager:getGlobalQuality()
    if curLv ~= GlobalQuality.Low then
      self.m_data.globalQuality = GlobalQuality.Low
      local widgets = self:GetWidgets()
      widgets.togp_global:SetActiveToggleIndex(0)
    end
  end
end

function DisPlaySettingPage:InitUI()
  local widgets = self:GetWidgets()
  local data = self.m_data
  local index = data.controlScale * 10 + 2
  index = Mathf.ToInt(index)
  widgets.tog_group_scale:SetActiveToggleIndex(index)
end

return DisPlaySettingPage
