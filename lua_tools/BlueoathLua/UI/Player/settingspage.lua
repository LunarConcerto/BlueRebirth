local SettingsPage = class("UI.Player.SettingsPage", LuaUIPage)
local QualityItem = require("ui.page.Player.QualityItem")
local controlScaleUIBase = 1

function SettingsPage:DoInit()
  self:InitGlobalToggleGroup()
  self.mTgList_AnimMode = {
    self.tab_Widgets.tgAnimMode_Normal,
    self.tab_Widgets.tgAnimMode_Simple
  }
end

function SettingsPage:DoOnOpen()
  self.m_data = self.param or SettingHelper.GetAllSetting()
  local data = self.m_data
  local widgets = self:GetWidgets()
  self.m_showObj = {
    [0] = widgets.obj_sound,
    [1] = widgets.obj_operate,
    [2] = widgets.obj_others
  }
  self.mapSettingAfter = Logic.setLogic:GetSettingAfter()
  self:InitUI()
  self:RefreshVolumeSlider(data.volumeData)
  self:RefreshOperate(data.operateData)
  self:RefreshOther(data.otherData)
  self:RefreshSpeed(data.speedData)
  self:RefreshTorpedoOperate(data.operateData)
  self:_LoadQucikChallenge()
  widgets.tog_group:SetActiveToggleIndex(1)
  local dotinfo = {
    info = "ui_set_battle"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  local curStage = stageMgr:GetCurStageType()
  if curStage == EStageType.eStagePvpBattle then
    widgets.tog_others.gameObject:SetActive(false)
  end
end

function SettingsPage:_LoadQucikChallenge()
  self.tabQuickChallenge = Logic.setLogic:GetQuickChallenge()
  local stage = {}
  if table.nums(self.tabQuickChallenge) == 0 then
    return
  end
  if self.tabQuickChallenge[SetConditionEnum.CopyAutoAttack][1] then
    if self.tabQuickChallenge[SetConditionEnum.CopyAutoAttack][2] == -1 then
      self.tab_Widgets.tx_autoattack.gameObject:SetActive(false)
    else
      stage = configManager.GetDataById("config_safearea", self.tabQuickChallenge[SetConditionEnum.CopyAutoAttack][2])
      self.tab_Widgets.tx_autoattack.text = string.format(configManager.GetDataById("config_function_info", SetConditionEnum.CopyAutoAttack).open_show_name, stage.desc)
      self.tab_Widgets.tx_autoattack.color = Color.New(0.16862745098039217, 0.803921568627451, 0.22745098039215686, 1)
      self.tab_Widgets.tx_autoattack.gameObject:SetActive(true)
    end
  else
    if self.tabQuickChallenge[SetConditionEnum.CopyAutoAttack][2] ~= 0 then
      stage = configManager.GetDataById("config_safearea", self.tabQuickChallenge[SetConditionEnum.CopyAutoAttack][2])
      self.tab_Widgets.tx_autoattack.text = string.format(configManager.GetDataById("config_function_info", SetConditionEnum.CopyAutoAttack).comment, stage.desc)
    else
      UIHelper.SetText(self.tab_Widgets.tx_autoattack, UIHelper.GetString(100010))
    end
    self.tab_Widgets.tx_autoattack.color = Color.New(1.0, 0 / 255, 0 / 255, 1)
  end
end

function SettingsPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSetting, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_bg, self._CloseSetting, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_scale, self, nil, self.OnScaleChange)
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
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_bgm, self, nil, self._ChangeBgmValue)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_audio, self, nil, self._ChangeAudioValue)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group_cv, self, nil, self._ChangeCvValue)
  UGUIEventListener.AddButtonOnClick(widgets.btn_reset, self.OnClickReset, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_nosound, self.OnClickNoSound, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_grouptorpedo, self, nil, self._SetOperateTorpedoMode)
  self.tab_Widgets.tgGroupAnimMode:ClearToggles()
  for _, toggle in ipairs(self.mTgList_AnimMode) do
    self.tab_Widgets.tgGroupAnimMode:RegisterToggle(toggle)
  end
  local animMode = CacheUtil.GetUseSimpleAnim()
  self.tab_Widgets.tgGroupAnimMode:SetActiveToggleIndex(animMode)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupAnimMode, self, "", self._SwitchTogs_AnimMode)
  self:_CheckFuncUnlock()
end

function SettingsPage:_CheckFuncUnlock()
  local widgets = self:GetWidgets()
  local conf = configManager.GetDataById("config_function_info", tostring(FunctionID.DoubleSpeed))
  if not moduleManager:CheckFunc(FunctionID.DoubleSpeed, false) then
    widgets.otherGroup:ResigterToggleUnActive(1, function()
      if not moduleManager:CheckFunc(FunctionID.DoubleSpeed, false) then
        noticeManager:ShowTip(conf.comment)
      end
    end)
  end
  local conf2 = configManager.GetDataById("config_function_info", tostring(FunctionID.TripleSpeed))
  if not moduleManager:CheckFunc(FunctionID.TripleSpeed, false) then
    widgets.otherGroup:ResigterToggleUnActive(2, function()
      if not moduleManager:CheckFunc(FunctionID.TripleSpeed, false) then
        noticeManager:ShowTip(conf2.comment)
      end
    end)
  end
end

function SettingsPage:DoOnHide()
end

function SettingsPage:DoOnClose()
  self:SaveAll()
end

function SettingsPage:_CloseSetting()
  UIHelper.ClosePage("SettingsPage")
end

function SettingsPage:SaveAll()
  SettingHelper.SaveAllSetting()
end

function SettingsPage:_SetShowType(types)
  for i, v in pairs(self.m_showObj) do
    v:SetActive(types == i)
  end
end

function SettingsPage:_SetControlScale(value)
  SettingHelper.SetControlScale(value)
end

function SettingsPage:_SetOperateMode(mode)
  SettingHelper.SetOperateMode(OperateMode[mode])
end

function SettingsPage:_SetSpeedMode(index)
  SettingHelper.SetSpeedMode(SpeedIndexMode[index])
end

function SettingsPage:_SetOperateTorpedoMode(mode)
  SettingHelper.SetTorpedoMode(TorpedoMode[mode])
end

function SettingsPage:_SetPlayerSkipSkillAnim(go, isSkip)
  local widgets = self:GetWidgets()
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipPlayerSkipSkillAnim, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  if self.mapSettingAfter ~= nil and self.mapSettingAfter[SettingDict.SkipMySkillAnim] ~= nil then
    widgets.tog_player.isOn = self.mapSettingAfter[SettingDict.SkipMySkillAnim]
    widgets.tog_player.interactable = false
    noticeManager:ShowTip(UIHelper.GetString(100023))
  else
    widgets.tog_player.interactable = true
    SettingHelper.SetPlayerSkipSkillAnim(isSkip)
  end
end

function SettingsPage:_SetEnemySkipSkillAnim(go, isSkip)
  local widgets = self:GetWidgets()
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipEnemySkipSkillAnim, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  if self.mapSettingAfter ~= nil and self.mapSettingAfter[SettingDict.SkipEnemySkillAnim] ~= nil then
    widgets.tog_enemy.isOn = self.mapSettingAfter[SettingDict.SkipEnemySkillAnim]
    widgets.tog_enemy.interactable = false
    noticeManager:ShowTip(UIHelper.GetString(100023))
  else
    widgets.tog_enemy.interactable = true
    SettingHelper.SetEnemySkipSkillAnim(isSkip)
  end
end

function SettingsPage:_SetSkipSkillAnimResul(go, isSkip)
  local widgets = self:GetWidgets()
  local isOpen = moduleManager:CheckFunc(FunctionID.SkipShipSkillFeedBack, false)
  if isSkip and not isOpen then
    noticeManager:ShowTip(UIHelper.GetString(100022))
  end
  if self.mapSettingAfter ~= nil and self.mapSettingAfter[SettingDict.SkipOtherAnim] ~= nil then
    widgets.tog_hitmiss.interactable = false
    noticeManager:ShowTip(UIHelper.GetString(100023))
    widgets.tog_hitmiss.isOn = self.mapSettingAfter[SettingDict.SkipOtherAnim]
  else
    widgets.tog_hitmiss.interactable = true
    SettingHelper.SetSkipSkillAnimResul(isSkip)
  end
end

function SettingsPage:_SetBattleResultAutoContinueSearch(go, isSkip)
  SettingHelper.SetBattleResultAutoContinueSearch(isSkip)
end

function SettingsPage:_SetBathroomAnimShow(go, isOpen)
  SettingHelper.SetBathroomAnim(isOpen)
end

function SettingsPage:_SetShowOperationWhenAnim(index)
  SettingHelper.SetShowOperationWhenAnim(index == 0)
end

function SettingsPage:_SetEnemyTorpedoAnim(go, isSkip)
  local widgets = self:GetWidgets()
  if self.mapSettingAfter ~= nil and self.mapSettingAfter[SettingDict.SkipEnemyTorpedoAnim] ~= nil then
    widgets.tog_enemyTorpedoAnim.interactable = false
    noticeManager:ShowTip(UIHelper.GetString(100023))
    widgets.tog_enemyTorpedoAnim.isOn = self.mapSettingAfter[SettingDict.SkipEnemyTorpedoAnim]
  else
    widgets.tog_enemyTorpedoAnim.interactable = true
    SettingHelper.SetEnemyTorpedoAnim(isSkip)
  end
end

function SettingsPage:_SetNearBulletAnim(go, isSkip)
  SettingHelper.SetNearBulletAnim(isSkip)
end

function SettingsPage:_SetSkillAnimSpeed(index)
  SettingHelper.SetSkillAnimSpeed(index)
end

function SettingsPage:_SetSkipHitCameraZoom(go, isSkip)
  SettingHelper.SetSkipHitCameraZoom(isSkip)
end

function SettingsPage:_ChangeBgmValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("Pause_all_music")
  else
    SoundManager.Instance:PlayAudio("Resume_all_music")
  end
  SettingHelper.SetBGMVolume(volume)
  SoundManager.Instance:SetBGMVolume(volume)
end

function SettingsPage:_ChangeAudioValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("SFX_Mute")
  else
    SoundManager.Instance:PlayAudio("SFX_Unmute")
  end
  SettingHelper.SetAudioVolume(volume)
  SoundManager.Instance:SetAudioVolume(volume)
end

function SettingsPage:_ChangeCvValue(index)
  local volume = index == 3 and 100 or 33 * index
  if index == 0 then
    SoundManager.Instance:PlayAudio("CV_Mute")
  else
    SoundManager.Instance:PlayAudio("CV_Unmute")
  end
  SettingHelper.SetCVVolume(volume)
  SoundManager.Instance:SetCVVolume(volume)
end

function SettingsPage:OnClickReset()
  local widgets = self:GetWidgets()
  self.m_data.volumeData = {
    bgm = 3,
    audio = 3,
    cv = 3
  }
  widgets.tog_group_bgm:SetActiveToggleIndex(self.m_data.volumeData.bgm)
  widgets.tog_group_audio:SetActiveToggleIndex(self.m_data.volumeData.audio)
  widgets.tog_group_cv:SetActiveToggleIndex(self.m_data.volumeData.cv)
end

function SettingsPage:OnClickNoSound()
  local widgets = self:GetWidgets()
  self.m_data.volumeData = {
    bgm = 0,
    audio = 0,
    cv = 0
  }
  widgets.tog_group_bgm:SetActiveToggleIndex(self.m_data.volumeData.bgm)
  widgets.tog_group_audio:SetActiveToggleIndex(self.m_data.volumeData.audio)
  widgets.tog_group_cv:SetActiveToggleIndex(self.m_data.volumeData.cv)
end

function SettingsPage:_SwitchTogs_AnimMode(index)
  SettingHelper.SetAnimMode(index)
end

function SettingsPage:OnScaleChange(index)
  local value = 0.1 * (index - 2)
  self:_SetControlScale(value)
end

function SettingsPage:InitGlobalToggleGroup()
  local widgets = self:GetWidgets()
  widgets.tog_group:ClearToggles()
  widgets.tog_group:RegisterToggle(widgets.tog_sound)
  widgets.tog_group:RegisterToggle(widgets.tog_operate)
  widgets.tog_group:RegisterToggle(widgets.tog_others)
  widgets.modeGroup:ClearToggles()
  widgets.modeGroup:RegisterToggle(widgets.tog_rudder)
  widgets.modeGroup:RegisterToggle(widgets.tog_direct)
  widgets.speedGroup:ClearToggles()
  widgets.speedGroup:RegisterToggle(widgets.tog_mode1)
  widgets.speedGroup:RegisterToggle(widgets.tog_mode2)
  widgets.otherGroup:ClearToggles()
  widgets.otherGroup:RegisterToggle(widgets.tog_speed1)
  widgets.otherGroup:RegisterToggle(widgets.tog_speed2)
  widgets.otherGroup:RegisterToggle(widgets.tog_speed3)
  widgets.tog_showGroup:ClearToggles()
  widgets.tog_showGroup:RegisterToggle(widgets.tog_show)
  widgets.tog_showGroup:RegisterToggle(widgets.tog_hide)
  widgets.tog_grouptorpedo:ClearToggles()
  widgets.tog_grouptorpedo:RegisterToggle(widgets.tog_manualtorpedo)
  widgets.tog_grouptorpedo:RegisterToggle(widgets.tog_autotorpedo)
end

function SettingsPage:RefreshVolumeSlider(data)
  local widgets = self:GetWidgets()
  local bgmIndex = data.bgm == 100 and 3 or data.bgm / 33
  local audioIndex = data.audio == 100 and 3 or data.audio / 33
  local cvIndex = data.cv == 100 and 3 or data.cv / 33
  widgets.tog_group_bgm:SetActiveToggleIndex(bgmIndex)
  widgets.tog_group_audio:SetActiveToggleIndex(audioIndex)
  widgets.tog_group_cv:SetActiveToggleIndex(cvIndex)
end

function SettingsPage:RefreshOperate(data)
  local widgets = self:GetWidgets()
  widgets.modeGroup:SetActiveToggleIndex(data.operateMode)
  widgets.tog_showGroup:SetActiveToggleIndex(IsShowAnim[data.showAnim])
end

function SettingsPage:RefreshTorpedoOperate(data)
  local widgets = self:GetWidgets()
  widgets.tog_grouptorpedo:SetActiveToggleIndex(data.torpedoMode)
end

function SettingsPage:RefreshSpeed(data)
  local widgets = self:GetWidgets()
  widgets.speedGroup:SetActiveToggleIndex(SpeedModeIndex[data.speedMode])
end

function SettingsPage:RefreshOther(data)
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

function SettingsPage:InitUI()
  local widgets = self:GetWidgets()
  local data = self.m_data
  local index = data.controlScale * 10 + 2
  index = Mathf.ToInt(index)
  widgets.tog_group_scale:SetActiveToggleIndex(index)
end

return SettingsPage
