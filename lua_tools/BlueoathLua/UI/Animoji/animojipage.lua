local AnimojiPage = class("UI.Animoji.AnimojiPage", LuaUIPage)
AnimojiImageMap = {
  [true] = "uipic_ui_animoji_bu_zhengzailuxiang",
  [false] = "uipic_ui_animoji_bu_kaishiluxiang"
}

function AnimojiPage:DoInit()
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_3dgirl)
  self.m_heroData = {}
  self.sortway = true
  self.m_tabOutParams = {}
  self.m_tabSortHero = {}
  self.faceDataItem = {}
  self.tabFaceInfo = {}
  self.tabFaceClickIcon = {}
  self.sf_id = nil
  self.num = 1
  self.togRecord = false
  self.startTimerCount = 1
  self.startBoFangCount = 0
  self.isLuZhi = true
  self.isCanSend = true
  self.tabFaceFirst = {}
  self.tabClickIcon = {}
  self.globalIsTrack = -1
  self.tabHide = {
    self.tab_Widgets.obj_recordObj,
    self.tab_Widgets.obj_buttomObj,
    self.tab_Widgets.obj_shareObj,
    self.tab_Widgets.obj_deleteObj,
    self.tab_Widgets.obj_recordChangeObj,
    self.tab_Widgets.obj_startObj
  }
end

function AnimojiPage:DoOnOpen()
  self:OpenTopPage("AnimojiPage", 5, "\233\162\156\232\137\186", self, true)
  self.sf_id = self:GetParam()
  self:StartShowPage()
  self:_ShowPicture()
  self:_LoadFaceBagFnc()
end

function AnimojiPage:StartShowPage()
  local widgets = self:GetWidgets()
  self.changeState = ChangeType.CanChange
  self.recordState = AnimojiType.NoRecord
  widgets.obj_tips:SetActive(false)
  widgets.tog_record.isOn = false
  widgets.obj_tipsDelete.gameObject:SetActive(false)
  widgets.obj_downloadObj:SetActive(false)
  widgets.obj_shareObj:SetActive(not self.isLuZhi)
  widgets.obj_deleteObj:SetActive(not self.isLuZhi)
  self:ShowHideUI()
  self:StartCreate3DModel()
  UIHelper.SetImage(widgets.im_select, AnimojiImageMap[widgets.tog_record.isOn])
end

function AnimojiPage:ShowHideUI(...)
  local widgets = self:GetWidgets()
  widgets.obj_luzhiInfo:SetActive(self.isLuZhi)
  widgets.obj_biaoQingInfo:SetActive(not self.isLuZhi)
  widgets.obj_luZhi:SetActive(self.isLuZhi)
  widgets.obj_biaoQing:SetActive(not self.isLuZhi)
  widgets.tog_start.gameObject:SetActive(not self.isLuZhi)
end

function AnimojiPage:StartCreate3DModel(...)
  local dressID = Logic.fashionLogic:GetOwnFashion(self.sf_id)
  local realDressId = Logic.fashionLogic:GetFashionDataById(dressID)
  local param = {
    showID = self.sf_id,
    dressID = realDressId
  }
  self.m_objModel = UIHelper.Create3DModel(param, self.tab_Widgets.im_3dgirl, CamDataType.Detaile)
  self.tab_Widgets.im_3dgirl.transform.localScale = Vector3.New(1, 1, 1)
  self.tab_Widgets.btn_reset.gameObject:SetActive(false)
  self:_Show3DModelPosition()
end

function AnimojiPage:_Show3DModelPosition()
  local widgets = self:GetWidgets()
  self.m_objModel:HideMech(false)
  local mi = self.m_objModel.m_3dObj.gameObject:GetComponent(ModelInterface.GetClassType())
  local position = mi.headTra.position
  local resName = self.m_objModel.m_3dObj.resName
  local mData = configManager.GetDataById("config_model_camera_config", resName)
  local isQidai = configManager.GetDataById("config_ship_model", resName)
  self.tab_Widgets.im_qidai.gameObject:SetActive(isQidai.animoji_switch == 0)
  self.tab_Widgets.im_lock.gameObject:SetActive(isQidai.animoji_switch == 0)
  self.tab_Widgets.obj_3dgirl:SetActive(isQidai.animoji_switch == 1)
  local camPos = Vector3.New(position.x + mData.animojiCameraRelativePos[1], position.y + mData.animojiCameraRelativePos[2], position.z + mData.animojiCameraRelativePos[3])
  self.m_objModel.m_camera.transform.position = camPos
  self.m_objModel.m_camera.orthographicSize = mData.animojiSize
  self.m_objModel.m_camera.transform.localEulerAngles = Vector3.New(mData.animojiCameraRelativeRot[1], mData.animojiCameraRelativeRot[2], mData.animojiCameraRelativeRot[3])
  Face:InitFaceTracking(self.sf_id, self.m_objModel.m_3dObj.gameObject, camPos)
end

function AnimojiPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.AnimojiDelete, self._LoadFaceBagFnc, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_jingyin, self._JingYinFnc, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_record, self._RecordFnc, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reset, self._ResetFnc, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_start, self._StartFnc, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_download, self._DownloadFnc, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_share, self._ShareFnc, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_delete, self._DeleteFnc, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_recordChange, self._RecordChangeFnc, self)
  UGUIEventListener.AddOnDrag(self.tab_Widgets.scrRect, function()
    self:_OnDrag()
  end, nil, nil)
  self:RegisterEvent(LuaCSharpEvent.FaceTracked, self.FaceTracked, self)
end

function AnimojiPage:_OnDrag()
  if self.tab_Widgets.faceScrollbarVer.value == 1 then
    self.tab_Widgets.im_bian.gameObject:SetActive(false)
  elseif self.tab_Widgets.faceScrollbarVer.value == 0 and #self.tabFaceInfo < 6 then
    self.tab_Widgets.im_bian.gameObject:SetActive(false)
  else
    self.tab_Widgets.im_bian.gameObject:SetActive(true)
  end
end

function AnimojiPage:FaceTracked(param)
  if self.globalIsTrack == param then
    return
  end
  self.globalIsTrack = param
  local isTracked = self.globalIsTrack
  if isTracked then
    self.tab_Widgets.obj_tishi:SetActive(false)
  else
    self.tab_Widgets.obj_tishi:SetActive(true)
  end
  self.tab_Widgets.obj_noSure:SetActive(not isTracked)
  self.tab_Widgets.obj_sure:SetActive(isTracked)
end

function AnimojiPage:_MusicSwitch(isOpen)
  if isOpen then
    SoundManager.Instance:NotifyFocusStateChange(true)
    SoundManager.Instance:PlayMusic("Role_unlock_finish")
  else
    SoundManager.Instance:NotifyFocusStateChange(false)
    SoundManager.Instance:PlayMusic("Role_unlock")
  end
end

function AnimojiPage:_ShowPicture()
  local tabHero = {}
  self.m_tabOutParams = {
    [HeroFilterType.Lock] = {
      [1] = 1
    }
  }
  self.m_heroData = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Normal)
  self.m_tabSortHero = HeroSortHelper.PictureFilterAndSort(self.m_heroData, self.m_tabOutParams, self.sortway)
  table.sort(self.m_tabSortHero, function(data1, data2)
    return data1.quality - data2.quality > 0
  end)
  for v, k in pairs(self.m_tabSortHero) do
    if k.IllustrateState == IllustrateState.UNLOCK then
      local shId = Logic.shipLogic:GetShipShowByInfoId(k.IllustrateId)
      local dressIDs = Logic.fashionLogic:GetOwnFashion(k.IllustrateId)
      for v1, _ in pairs(dressIDs) do
        local realDressId = Logic.fashionLogic:GetFashionConfig(v1)
        if realDressId then
          k.showID = realDressId.ship_show_id
          if k.showID == self.sf_id then
            self.num = v
          end
          local kr = clone(k)
          table.insert(tabHero, kr)
        end
      end
    end
  end
  self:_LoadHeroItem(tabHero)
end

function AnimojiPage:_LoadHeroItem(tabHero)
  self.tabClickIcon = {}
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.ill_girlItem, self.tab_Widgets.obj_girlItem, #tabHero, function(luaPart)
    for nIndex, tabPart in pairs(luaPart) do
      nIndex = tonumber(nIndex)
      local data = Logic.shipLogic:GetShipShowConfig(tabHero[nIndex].showID)
      local tabHeroIcon = data.ship_icon2
      UIHelper.SetImage(tabPart.im_icon, tabHeroIcon)
      UIHelper.SetImage(tabPart.im_quality, VerCardQualityImg[tabHero[nIndex].quality])
      UIHelper.SetText(tabPart.tx_name, tabHero[nIndex].Name)
      table.insert(self.tabClickIcon, tabPart)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
        self:_Show3DModel(tabHero[nIndex], tabPart, nIndex, tabHero[nIndex].showID)
      end)
      local shId = Logic.shipLogic:GetShipShowByInfoId(tabHero[nIndex].IllustrateId)
      tabPart.im_click.gameObject:SetActive(tabHero[nIndex].showID == self.sf_id)
    end
  end)
  self.timer = self:CreateTimer(function()
    self:Jump()
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
end

function AnimojiPage:Jump(...)
  if self.num == #self.m_tabSortHero then
    self.tab_Widgets.ScrollbarVer.value = 0
  elseif self.num == 1 then
    self.tab_Widgets.ScrollbarVer.value = 1
  else
    self.tab_Widgets.ScrollbarVer.value = (#self.m_tabSortHero - self.num) / #self.m_tabSortHero
  end
end

function AnimojiPage:_Show3DModel(tabHero, tabPart, nIndex, showId)
  if self.changeState == ChangeType.CanChange then
    local widgets = self:GetWidgets()
    self.sf_id = showId
    if self.m_objModel ~= nil then
      UIHelper.Close3DModel(self.m_objModel)
      self.m_objModel = nil
    end
    for k, v in pairs(self.tabClickIcon) do
      v.im_click.gameObject:SetActive(false)
    end
    tabPart.im_click.gameObject:SetActive(true)
    local param = {showID = showId}
    self.tab_Widgets.obj_3dgirl:SetActive(false)
    self.m_objModel = UIHelper.Create3DModel(param, widgets.im_3dgirl, CamDataType.Detaile)
    self:_Show3DModelPosition()
    widgets.im_3dgirl.transform.localScale = Vector3.New(1, 1, 1)
    if self.isLuZhi then
      self.recordState = AnimojiType.NoRecord
    end
    self:_LoadFaceBagFnc()
  end
end

function AnimojiPage:_HideBoFang()
  if self.tab_Widgets.tog_start.isOn then
    self.tab_Widgets.tog_start.isOn = false
    self.startBoFangCount = 0
    UIHelper.SetText(self.tab_Widgets.tx_time, UIHelper.GetScondCount(self.startBoFangCount))
    self.changeState = ChangeType.CanChange
    Face:Stop()
    if self.isLuZhi then
      Face:ChangeMode(Mode.LuZhi)
    else
      Face:ChangeMode(Mode.Play)
    end
    self:StopTimer(self.timerStartBoFang)
  end
end

function AnimojiPage:_getDressID(illustrateId, damageLv)
  local showConfig = configManager.GetDataById("config_ship_show", illustrateId)
  local res = configManager.GetDataById("config_ship_model", showConfig.model_id)
  return res.standard_normal
end

function AnimojiPage:_JingYinFnc()
  Face:Mute(self.tab_Widgets.tog_jingyin.isOn)
end

function AnimojiPage:_RecordFnc()
  local maxTime = 10
  self.typeNum = nil
  if self.isCanSend then
    self.isCanSend = false
    Face:StartRecord(maxTime, function(code)
      self.typeNum = code
      self:_CallRecordFnc()
    end)
  end
end

function AnimojiPage:_CallRecordFnc()
  self.isCanSend = true
  Face:ChangeMode(Mode.LuZhi)
  if self.typeNum == 0 then
    self.togRecord = not self.togRecord
    self:_HideBoFang()
    self.tab_Widgets.tog_record.isOn = self.togRecord
    self.recordState = AnimojiType.RecordIng
    self.startTimerCount = 1
    UIHelper.SetText(self.tab_Widgets.tx_recordTime, UIHelper.GetScondCount(self.startTimerCount))
    UIHelper.SetImage(self.tab_Widgets.im_select, AnimojiImageMap[self.togRecord])
    if self.togRecord == true then
      self.isStart = true
      self.changeState = ChangeType.NoChange
      self.tab_Widgets.obj_deleteObj.gameObject:SetActive(false)
      self.tab_Widgets.obj_shareObj.gameObject:SetActive(false)
      self.tab_Widgets.tog_start.gameObject:SetActive(false)
      self.tab_Widgets.btn_reset.gameObject:SetActive(true)
      self.tab_Widgets.obj_recordChangeObj:SetActive(false)
      self.tab_Widgets.obj_tips:SetActive(false)
      self:_MusicSwitch(false)
      self.timerStartScond = self:CreateTimer(function()
        self:_StartScond()
      end, 1, -1, false)
      self:StartTimer(self.timerStartScond)
      self:_StartBiaoqingTimer()
      self.tab_Widgets.obj_jingyinObj:SetActive(false)
    else
      self:SucessFnc()
    end
  elseif self.typeNum == 1 then
    UIHelper.SetText(self.tab_Widgets.tx_tips, UIHelper.GetString(990005))
    self.tab_Widgets.obj_tips:SetActive(true)
    self.systemTips = self:CreateTimer(function()
      self:_SystemTipsFnc()
    end, 2, 1, false)
    self:StartTimer(self.systemTips)
    self.tab_Widgets.tog_record.isOn = self.togRecord
    UIHelper.SetImage(self.tab_Widgets.im_select, AnimojiImageMap[self.togRecord])
  else
    self.tab_Widgets.tog_record.isOn = self.togRecord
    UIHelper.SetImage(self.tab_Widgets.im_select, AnimojiImageMap[self.togRecord])
  end
end

function AnimojiPage:SucessFnc(...)
  if self.isStart then
    self.isStart = false
    Face:EndRecord()
    self.togRecord = false
    self.tab_Widgets.tog_record.isOn = self.togRecord
    self.recordState = AnimojiType.Recorded
    self.changeState = ChangeType.CanChange
    self.tab_Widgets.obj_jingyinObj:SetActive(true)
    if #self.tabFaceInfo == 0 then
      self.tab_Widgets.obj_deleteObj.gameObject:SetActive(false)
      self.tab_Widgets.obj_shareObj.gameObject:SetActive(false)
      self.tab_Widgets.tog_start.gameObject:SetActive(false)
    else
      self.tab_Widgets.obj_deleteObj.gameObject:SetActive(true)
      self.tab_Widgets.obj_shareObj.gameObject:SetActive(true)
      self.tab_Widgets.tog_start.gameObject:SetActive(true)
    end
    self.tab_Widgets.tx_recordTime.gameObject:SetActive(false)
    self.tab_Widgets.obj_tips:SetActive(true)
    UIHelper.SetText(self.tab_Widgets.tx_tips, UIHelper.GetString(990001))
    self.tab_Widgets.loading:SetActive(true)
    UIHelper.SetUILock(true)
    self:_StartSucessTimer()
    self.tab_Widgets.btn_reset.gameObject:SetActive(false)
    self.tab_Widgets.obj_recordChangeObj:SetActive(true)
    self:StopTimer(self.timerStartScond)
    self:_StopBiaoqingTimer()
    UIHelper.SetImage(self.tab_Widgets.im_select, AnimojiImageMap[self.togRecord])
  end
end

function AnimojiPage:_StartBiaoqingTimer(...)
  local maxTime = 10
  if self.timerBiaoQing == nil then
    self.timerBiaoQing = self:CreateTimer(function()
      self:_StopRecord()
    end, maxTime, 1, false)
    self:StartTimer(self.timerBiaoQing)
  end
end

function AnimojiPage:_StopBiaoqingTimer(...)
  if self.timerBiaoQing ~= nil then
    self:StopTimer(self.timerBiaoQing)
    self.timerBiaoQing = nil
  end
end

function AnimojiPage:_StartSucessTimer(...)
  if self.timerTips == nil then
    self.timerTips = self:CreateTimer(function()
      self:_RecordSucess()
    end, 2, 1, false)
    self:StartTimer(self.timerTips)
  end
end

function AnimojiPage:_StopSucessTimer(...)
  if self.timerTips ~= nil then
    self:StopTimer(self.timerTips)
    self.timerTips = nil
  end
end

function AnimojiPage:_StartScond()
  self.startTimerCount = self.startTimerCount + 1
  UIHelper.SetText(self.tab_Widgets.tx_recordTime, UIHelper.GetScondCount(self.startTimerCount))
end

function AnimojiPage:_StopRecord()
  self:SucessFnc()
end

function AnimojiPage:_RecordSucess()
  UIHelper.SetText(self.tab_Widgets.tx_tips, UIHelper.GetString(990001))
  self.tab_Widgets.obj_tips:SetActive(false)
  self:_StopSucessTimer()
  self:_MusicSwitch(true)
  UIHelper.SetUILock(false)
  self.tab_Widgets.loading:SetActive(false)
  self:_LoadFaceBagFnc()
end

function AnimojiPage:_ResetFnc()
  self.togRecord = false
  Face:CancelRecord()
  self.recordState = AnimojiType.NoRecord
  self.changeState = ChangeType.CanChange
  self.tab_Widgets.obj_jingyinObj:SetActive(true)
  self.tab_Widgets.btn_reset.gameObject:SetActive(false)
  self.tab_Widgets.obj_recordChangeObj:SetActive(true)
  self.tab_Widgets.tx_recordTime.gameObject:SetActive(false)
  self.tab_Widgets.tog_record.isOn = self.togRecord
  UIHelper.SetImage(self.tab_Widgets.im_select, AnimojiImageMap[self.togRecord])
  self:StopTimer(self.timerBiaoQing)
  self:_StopBiaoqingTimer()
  self:StopTimer(self.timerStartScond)
  self.startTimerCount = 1
  UIHelper.SetText(self.tab_Widgets.tx_recordTime, UIHelper.GetScondCount(self.startTimerCount))
  self:_StartMusicTimer()
  self:_LoadFaceBagFnc()
end

function AnimojiPage:_StartMusicTimer(...)
  if self.timerMusic == nil then
    self.tab_Widgets.loading:SetActive(true)
    UIHelper.SetUILock(true)
    self.timerMusic = self:CreateTimer(function()
      self:_StopMusicTimer()
    end, 1, 1, false)
    self:StartTimer(self.timerMusic)
  end
end

function AnimojiPage:_StopMusicTimer(...)
  self:_MusicSwitch(true)
  self.tab_Widgets.loading:SetActive(false)
  UIHelper.SetUILock(false)
  if self.timerMusic ~= nil then
    self:StopTimer(self.timerMusic)
    self.timerMusic = nil
  end
end

function AnimojiPage:_StartFnc()
  self.startBoFangCount = 0
  UIHelper.SetText(self.tab_Widgets.tx_time, UIHelper.GetScondCount(self.startBoFangCount))
  if self.tab_Widgets.tog_start.isOn then
    self.changeState = ChangeType.NoChange
    Face:ChangeMode(Mode.Play)
    self.tab_Widgets.obj_noSure:SetActive(false)
    self.tab_Widgets.obj_sure:SetActive(false)
    self.tab_Widgets.obj_tishi:SetActive(false)
    self:_MusicSwitch(false)
    self.timerStartBoFang = self:CreateTimer(function()
      self:_StartBoFang()
    end, 1, -1, false)
    self:StartTimer(self.timerStartBoFang)
    Face:Play(self.faceDataItem.id, self.faceDataItem.fileName)
  else
    self.changeState = ChangeType.CanChange
    self.globalIsTrack = -1
    Face:Stop()
    if self.isLuZhi then
      Face:ChangeMode(Mode.LuZhi)
    else
      Face:ChangeMode(Mode.Play)
    end
    self:StopTimer(self.timerStartBoFang)
    self:_MusicSwitch(true)
  end
end

function AnimojiPage:_StartBoFang()
  if self.faceDataItem.length > self.startBoFangCount then
    self.startBoFangCount = self.startBoFangCount + 1
    UIHelper.SetText(self.tab_Widgets.tx_time, UIHelper.GetScondCount(self.startBoFangCount))
  else
    self.changeState = ChangeType.CanChange
    self.globalIsTrack = -1
    if self.isLuZhi then
      Face:ChangeMode(Mode.LuZhi)
    else
      Face:ChangeMode(Mode.Play)
    end
    self:StopTimer(self.timerStartBoFang)
    self.tab_Widgets.tog_start.isOn = not self.tab_Widgets.tog_start.isOn
    self:_MusicSwitch(true)
    UIHelper.SetText(self.tab_Widgets.tx_time, UIHelper.GetScondCount(0))
  end
end

function AnimojiPage:_DownloadFnc()
end

function AnimojiPage:_ShareFnc()
  self:_HideBoFang()
  self.tab_Widgets.obj_hideBg:SetActive(false)
  self.tab_Widgets.obj_tishi:SetActive(false)
  self.tab_Widgets.obj_noSure:SetActive(false)
  self.tab_Widgets.obj_sure:SetActive(false)
  Face:Play(self.faceDataItem.id, self.faceDataItem.fileName)
  Face:ChangeMode(Mode.Play)
  self.isLuPing = nil
  Replay:StartRecording(false, function(isType)
    self.isLuPing = isType
    self:_CallShareFnc()
  end)
end

function AnimojiPage:_CallShareFnc()
  if self.isLuPing == 0 then
    local timeFace = self.faceDataItem.length
    self:_HideSence()
    self:_MusicSwitch(false)
    self.timeFace = self:CreateTimer(function()
      self:_StopPlay()
    end, timeFace, 1, false)
    self:StartTimer(self.timeFace)
  elseif self.isLuPing == 1 then
    self:_MusicSwitch(true)
    UIHelper.SetText(self.tab_Widgets.tx_tips, UIHelper.GetString(990003))
    self.tab_Widgets.obj_tips:SetActive(true)
    self.systemTips = self:CreateTimer(function()
      self:_SystemTipsFnc()
    end, 2, 1, false)
    self:StartTimer(self.systemTips)
  end
end

function AnimojiPage:_SystemTipsFnc()
  self.tab_Widgets.obj_tips:SetActive(false)
  self:StopTimer(self.systemTips)
end

function AnimojiPage:_StopPlay()
  Replay:StopRecording()
  self:_ShowSence()
  self:StopTimer(self.timeFace)
  self:_MusicSwitch(true)
  self.replayPreviewFace = self:CreateTimer(function()
    self:_ReadyToPreview()
  end, timeFace, 2, false)
  self:StartTimer(self.replayPreviewFace)
end

function AnimojiPage:_ReadyToPreview()
  Replay:Preview()
  self:StopTimer(self.replayPreviewFace)
end

function AnimojiPage:_DeleteFnc()
  self:_HideBoFang()
  if self.isLuZhi then
    self.recordState = AnimojiType.NoRecord
  else
    self.recordState = AnimojiType.Recorded
  end
  self.tab_Widgets.tog_start.isOn = false
  self:_AnimojiDeleteTips()
  Face:Delete(self.faceDataItem.id, self.faceDataItem.fileName)
  self.tab_Widgets.obj_tipsDelete.gameObject:SetActive(true)
  self.timerTipsDelete = self:CreateTimer(function()
    self:_RecordDelete()
  end, 1, 1, false)
  self:StartTimer(self.timerTipsDelete)
  self:_LoadFaceBagFnc()
end

function AnimojiPage:_AnimojiDeleteTips()
  self.tab_Widgets.obj_tipsDelete.gameObject:SetActive(false)
  self:StopTimer(self.timerTipsDelete)
end

function AnimojiPage:_RecordDelete(...)
  self.tab_Widgets.obj_tipsDelete.gameObject:SetActive(false)
  self:StopTimer(self.timerTipsDelete)
end

function AnimojiPage:_RecordChangeFnc(...)
  self:_HideBoFang()
  self.isLuZhi = not self.isLuZhi
  if self.isLuZhi then
    self.recordState = AnimojiType.NoRecord
    Face:ChangeMode(Mode.LuZhi)
    self.globalIsTrack = -1
  else
    if self.tab_Widgets.faceScrollbarVer.value == 1 then
      self.tab_Widgets.im_bian.gameObject:SetActive(false)
    elseif self.tab_Widgets.faceScrollbarVer.value == 0 and #self.tabFaceInfo < 6 then
      self.tab_Widgets.im_bian.gameObject:SetActive(false)
    else
      self.tab_Widgets.im_bian.gameObject:SetActive(true)
    end
    self.recordState = AnimojiType.Recorded
    Face:ChangeMode(Mode.Play)
    self.globalIsTrack = -1
  end
  if not self.isLuZhi then
    self.tab_Widgets.obj_tishi:SetActive(false)
    self.tab_Widgets.obj_noSure:SetActive(false)
    self.tab_Widgets.obj_sure:SetActive(false)
  end
  self:ShowHideUI()
  if #self.tabFaceInfo == 0 then
    self.tab_Widgets.obj_deleteObj.gameObject:SetActive(false)
    self.tab_Widgets.obj_shareObj.gameObject:SetActive(false)
    self.tab_Widgets.tog_start.gameObject:SetActive(false)
  else
    self.tab_Widgets.obj_shareObj:SetActive(not self.isLuZhi)
    self.tab_Widgets.obj_deleteObj:SetActive(not self.isLuZhi)
  end
  eventManager:SendEvent(LuaEvent.AnimojiDelete)
  if not self.isLuZhi then
    self:_LoadFaceBagFnc()
  end
end

function AnimojiPage:_LoadFaceBagFnc()
  self.tabFaceClickIcon = {}
  local faceData = Face:LoadSummary()
  local tabFace = {}
  local num = 0
  for v, k in pairs(faceData) do
    if v == tostring(self.sf_id) then
      for key, value in pairs(faceData[v]) do
        table.insert(tabFace, value)
      end
    end
  end
  self.tabFaceInfo = tabFace
  self.faceDataItem = tabFace[1]
  if self.recordState == AnimojiType.Recorded and #tabFace ~= 0 then
    self.tab_Widgets.obj_deleteObj:SetActive(true)
    self.tab_Widgets.obj_shareObj:SetActive(true)
    self.tab_Widgets.tog_start.gameObject:SetActive(true)
  else
    self.tab_Widgets.obj_deleteObj:SetActive(false)
    self.tab_Widgets.obj_shareObj:SetActive(false)
    self.tab_Widgets.tog_start.gameObject:SetActive(false)
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_biaoQingItem, self.tab_Widgets.trans_biaoQingItem, #tabFace, function(nIndex, tabPart)
    local strIcon = configManager.GetDataById("config_ship_show", tabFace[nIndex].id).ship_icon_animoji
    UIHelper.SetImage(tabPart.im_icon, strIcon)
    table.insert(self.tabFaceClickIcon, tabPart)
    tabPart.im_clickIcon:SetActive(nIndex == 1)
    self:_OnDrag()
    UGUIEventListener.AddOnEndDrag(tabPart.btn_icon, self._OnDrag, self)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      self:_ShowFace(tabFace[nIndex], nIndex)
    end)
  end)
end

function AnimojiPage:_ShowFace(faceData, nIndex)
  if self.changeState == ChangeType.CanChange then
    self.faceDataItem = faceData
    for v, k in pairs(self.tabFaceClickIcon) do
      if v == nIndex then
        k.im_clickIcon:SetActive(true)
      else
        k.im_clickIcon:SetActive(false)
      end
    end
  end
end

function AnimojiPage:_HideSence()
  for v, k in pairs(self.tabHide) do
    k:SetActive(false)
  end
  UIHelper.ClosePage("TopPage")
end

function AnimojiPage:_ShowSence()
  self.tab_Widgets.obj_hideBg:SetActive(true)
  for v, k in pairs(self.tabHide) do
    k:SetActive(true)
  end
  if self.isLuZhi then
    Face:ChangeMode(Mode.LuZhi)
  end
  self:OpenTopPage("AnimojiPage", 5, "\233\162\156\232\137\186", self, true)
end

function AnimojiPage:DoOnHide()
  self:_MusicSwitch(true)
  Face:Stop()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.obj_3dgirl:SetActive(false)
    self.m_objModel = nil
  end
end

function AnimojiPage:DoOnClose()
  self:_MusicSwitch(true)
  Face:Stop()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.obj_3dgirl:SetActive(false)
    self.m_objModel = nil
  end
  self:StopTimer(self.timer)
  Face:ClearFaceTracking()
end

return AnimojiPage
