local IllustrateInfo = class("UI.Illustrate.IllustrateInfo", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local rightTag = {
  Perform = 0,
  Property = 1,
  Discuss = 2,
  Strategy = 3
}
local rightPage = {
  [rightTag.Perform] = "PerformPage",
  [rightTag.Property] = "PropertyPage",
  [rightTag.Discuss] = "IlluDiscuss_Page",
  [rightTag.Strategy] = "StrategyPage"
}
local girlOffSet = {
  [rightTag.Perform] = Vector3.New(-210, 0, 0),
  [rightTag.Property] = Vector3.New(0, 0, 0),
  [rightTag.Discuss] = Vector3.New(0, 0, 0)
}
local damageLvMap = {
  [true] = DamageLevel.NonDamage,
  [false] = DamageLevel.BigDamage
}
local mirror = {
  [0] = 1,
  [1] = -1
}
local e_ModelShow = {
  ALL = 1,
  PO = 2,
  COMMON = 3
}

function IllustrateInfo:DoInit()
  self.m_tabWidgets = nil
  self.m_is3D = false
  self.m_rightTagPre = -1
  self.m_rightTag = rightTag.Perform
  self.m_illustrateId = 0
  self.m_isCheck = false
  self.m_isCommon = true
  self.m_isTween = false
  self.m_page = {}
  self.m_isDrag = false
  self.m_cachModelStr = ""
  self.type = nil
  self.tabHeroId = {}
  self.delta = 0
  self.timer = nil
  self.tagGroup = {}
  self:_RegisterTogGroup()
  self.first = true
end

function IllustrateInfo:_SetSsId(ss_id)
  self.ss_id = ss_id
end

function IllustrateInfo:_GetSsId()
  return self.ss_id or 0
end

function IllustrateInfo:DoOnOpen()
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, true)
  local param = self.tabChangeParam or self:GetParam()
  if type(param) == "table" then
    self.m_illustrateId = param.id or param
    self.tabHeroId = param.tabHeroId or {}
    self.type = param.Type or IllustrateType.Picture
  else
    self.m_illustrateId = param
    self.tabHeroId = {}
    self.type = IllustrateType.Picture
  end
  self.tab_Widgets.tog_property.gameObject:SetActive(self.type ~= IllustrateType.ActivitySSR)
  local ss_id = Logic.illustrateLogic:GetIllustrateShowId(self.m_illustrateId)
  self:_SetSsId(ss_id)
  local isOpenAnimoji = Face:IsSupport()
  self.tab_Widgets.btn_animoji.gameObject:SetActive(isOpenAnimoji)
  if self.type == IllustrateType.Picture then
    self:OpenTopPage("IllustrateInfo", 1, "\229\155\190\233\137\180", self, true)
  elseif self.type == IllustrateType.ActivitySSR then
    self:OpenTopPage("IllustrateInfo", 1, "\229\141\161\230\177\160\228\191\161\230\129\175", self, true)
  end
  self.tab_Widgets.tween_2d:SetOnFinished(function()
    UIHelper.SetUILock(false)
  end)
  self:DoOnOpenInit()
  local shipName = Data.illustrateData:GetIllustrateById(self.m_illustrateId).Name
  local dotinfo = {
    info = "ui_handbook_details",
    ship_name = shipName
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  local tabParam = {
    zoom = function(param)
      self:__onModeBZoom(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function IllustrateInfo:DoOnOpenInit()
  local widgets = self:GetWidgets()
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(self.m_illustrateId)
  if illustrateState == IllustrateState.LOCK then
    self.m_rightTag = rightTag.Discuss
  else
    self.m_rightTag = rightTag.Perform
  end
  self:_InitTagTween(self.m_illustrateId)
  self:_UnActiveTagGroup()
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(self.m_illustrateId)
  if illustrateState == IllustrateState.LOCK then
    self.m_rightTagPre = rightTag.Perform
    self.m_page[rightTag.Perform] = self:OpenSubPage("PerformPage", self.m_illustrateId)
    self.m_page[rightTag.Discuss] = self:OpenSubPage("IlluDiscuss_Page", {
      heroId = self.m_illustrateId,
      isNpc = false
    })
    for i, v in pairs(rightTag) do
      if v ~= rightTag.Discuss and self.m_page[v] then
        self.m_page[v].gameObject.transform.localPosition = Vector3.New(3000, 0, 0)
      end
    end
  else
    self.m_page[rightTag.Property] = self:OpenSubPage("PropertyPage", self.m_illustrateId)
    self.m_page[rightTag.Discuss] = self:OpenSubPage("IlluDiscuss_Page", {
      heroId = self.m_illustrateId,
      isNpc = false
    })
    self.m_page[rightTag.Perform] = self:OpenSubPage("PerformPage", self.m_illustrateId)
    for i, v in pairs(rightTag) do
      if v ~= self.m_rightTag and self.m_page[v] then
        self.m_page[v].gameObject.transform.localPosition = Vector3.New(3000, 0, 0)
      end
    end
  end
  widgets.btn_share.gameObject:SetActive(illustrateState ~= IllustrateState.LOCK and platformManager:ShowShare())
  local illustrateId = self.m_illustrateId
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(illustrateId)
  self:_Init3DObj(illustrateId)
  self:_init2D3DPosition()
  self:_ShowRightTag(illustrateState, self.m_rightTag)
  if self.first then
    self.first = false
    self.timer = FrameTimer.New(function()
      self:_ShowButton(self.m_rightTag)
    end, 1, 1)
    self.timer:Start()
  else
    self:_ShowButton(self.m_rightTag)
  end
  self:_ShowBaseInfo(illustrateId)
  self:_ShowSwitch2D3D(self.m_is3D)
  self:_ShowIllustrate(illustrateId)
  self:_GirlTween()
  self:_GirlInfoTween()
  self:_SetShip(illustrateState)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.left_tag, self, nil, self._SwitchTag)
end

function IllustrateInfo:_GetPositionTo()
  local widgets = self:GetWidgets()
  local ss_id = self:_GetSsId()
  local config = configManager.GetDataById("config_ship_position", ss_id)
  local pos = Vector3.New(config.ship_position2[1], config.ship_position2[2], 0)
  return pos + girlOffSet[self.m_rightTag]
end

function IllustrateInfo:_init2D3DPosition()
  if self.m_isCheck then
    return
  end
  local widgets = self:GetWidgets()
  local ss_id = self:_GetSsId()
  local config = configManager.GetDataById("config_ship_position", ss_id)
  if self.m_is3D then
    local modelTrans = self.m_objModel:Get3dObj().transform
    local pos = modelTrans.localPosition
    modelTrans.localPosition = Vector3.New(self.modelStartPos[self.m_rightTag], pos.y, pos.z)
    UGUIEventListener.RemoveButtonOnPointUpListener(widgets.im_quality.gameObject)
  else
    UGUIEventListener.AddButtonOnPointUp(widgets.im_quality, self._OnPointUp, self)
    local mirrorValue = mirror[config.ship_inversion2]
    widgets.trans_girl.localPosition = Vector3.New(config.ship_position2[1], config.ship_position2[2], 0) + girlOffSet[self.m_rightTag]
    widgets.im_2dgirl.transform.localScale = Vector3.New(config.ship_scale2 / 10000 * mirrorValue, config.ship_scale2 / 10000, 1)
  end
  widgets.shipInfo:SetActive(true)
end

function IllustrateInfo:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_check, self._CheckIllustrate, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_share, self._ShareIllustrate, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_2dto3d, self._Switch2D3D, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_get, self._ShowGetApproach, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_quality, self._CancelCheck, self)
  UGUIEventListener.AddOnDrag(widgets.im_quality, self.im_quality_drag, self)
  UGUIEventListener.AddOnEndDrag(widgets.im_quality, self.im_quality_drag_end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_animoji, self._OpenAnimoji, self)
  self:RegisterEvent(LuaEvent.UpdateIllustrate, self._UpdataIllustrate, self)
  self:RegisterEvent(LuaEvent.PlayBehaviour, self._PlayBehaviour, self)
  self:RegisterEvent(LuaEvent.CloseIllustrate, self._CloseIllustrate, self)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, function(self, notification)
    self:_ShowSubtitle(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, function(self)
    self:_CloseSubtitle()
  end)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.FASHION_SwitchFashion, self._OnSwitchFashion, self)
  widgets.tog_common.isOn = self.m_isCommon
  widgets.tx_common.gameObject:SetActive(self.m_isCommon)
  widgets.tx_destroy.gameObject:SetActive(not self.m_isCommon)
  widgets.im_common.gameObject:SetActive(self.m_isCommon)
  widgets.im_destroy.gameObject:SetActive(not self.m_isCommon)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_common, self._SwitchState, self)
  UGUIEventListener.AddButtonOnPointUp(widgets.im_quality, self._OnPointUp, self)
end

function IllustrateInfo:_ShareIllustrate()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function IllustrateInfo:_ShareOver()
  self:ShareComponentShow(true)
end

function IllustrateInfo:_CloseIllustrate()
  local widgets = self:GetWidgets()
  if self.m_objModel ~= nil then
    UI3DModelManager.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
end

function IllustrateInfo:_PlayBehaviour(param)
  if self.m_objModel then
    local type = Logic.illustrateLogic:GetModuleDressType(param.id)
    self:_CheckModelPlay(type)
    local obj = self.m_objModel:Get3dObj()
    obj:playBehaviour(param.behName, false, nil)
    self:_UISwitchState(false)
    self:_TickEnableUISwitchState(obj:getCurBehaviourLength())
  end
end

function IllustrateInfo:_TickEnableUISwitchState(duration)
  local timer = self:CreateTimer(function()
    self:_UISwitchState(true)
  end, duration, 1, false)
  self:StartTimer(timer)
end

function IllustrateInfo:_CheckModelPlay(type)
  local common = self.m_isCommon
  if type == e_ModelShow.PO and common then
    self:_SwitchState()
  elseif type == e_ModelShow.COMMON and not common then
    self:_SwitchState()
  end
end

function IllustrateInfo:_UISwitchState(enable)
  local widgets = self:GetWidgets()
  UIHelper.DisableButton(widgets.tog_common, not enable)
end

function IllustrateInfo:_ShowIllustrateInfo(illustrateId, tagIndex, is3D)
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(illustrateId)
  if illustrateState == IllustrateState.CLOSE then
    logError("\230\156\170\229\188\128\230\148\190\230\136\152\229\167\172\229\155\190\233\137\180\228\184\141\228\188\154\230\137\147\229\188\128\229\155\190\233\137\180\232\175\166\230\131\133\233\161\181,\229\155\190\233\137\180id" .. illustrateId)
    return
  end
  self.m_illustrateId = illustrateId
  if is3D then
    self.m_is3D = is3D
    Logic.illustrateLogic:SetIs3D(is3D)
  end
  self.m_rightTag = tagIndex or rightTag.Perform
  self:_Init3DObj(illustrateId)
  self:_init2D3DPosition()
  self:_ShowRightTag(illustrateState, tagIndex)
  self:_ShowButton(tagIndex)
  self:_ShowBaseInfo(illustrateId)
  self:_ShowSwitch2D3D(self.m_is3D)
  self:_ShowIllustrate(illustrateId)
  self:_SetShip(illustrateState)
end

function IllustrateInfo:_SetShip(illustrateState)
  local widgets = self:GetWidgets()
  if illustrateState == IllustrateState.LOCK and self.type == IllustrateType.Picture then
    widgets.im_2dgirl.color = Color.New(0.5, 0.5, 0.5, 1)
  else
    widgets.im_2dgirl.color = Color.New(1, 1, 1, 1)
  end
end

function IllustrateInfo:_ShowRightTag(illustrateState, tagIndex)
  local widgets = self:GetWidgets()
  tagIndex = tagIndex or rightTag.Perform
  self.m_rightTag = tagIndex
  if illustrateState == IllustrateState.UNLOCK then
    widgets.left_tag:SetActiveToggleIndex(tagIndex)
  elseif illustrateState == IllustrateState.LOCK then
    widgets.left_tag:SetActiveToggleIndex(rightTag.Discuss)
  else
    logError("\232\175\165\230\136\152\229\167\172\230\156\170\229\188\128\230\148\190,\230\151\160\229\155\190\233\137\180\228\191\161\230\129\175")
  end
end

function IllustrateInfo:_Init3DObj(illustrateId)
  local widgets = self:GetWidgets()
  if self.m_objModel ~= nil then
    UI3DModelManager.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  local damageLv
  if self.m_rightTag == rightTag.Property then
    damageLv = Logic.illustrateLogic:GetDamageLv()
  else
    damageLv = DamageLevel.NonDamage
  end
  local ss_id = self:_GetSsId()
  local dressID = self:_getDressID(ss_id, damageLv)
  local param = {showID = illustrateId, dressID = dressID}
  self:__Create3DShow(param)
  self:__ResetModelPos()
end

function IllustrateInfo:__Create3DShow(param)
  local widgets = self:GetWidgets()
  self.m_objModel = UIHelper.Create3DModelNoRT(param, CamDataType.Detaile, false, widgets.im_quality.mainTexture)
  local camera = self.m_objModel.m_camera
  local hu = UIManager:GetUIHeight() / 2
  self.modelStartPos = {}
  for i = rightTag.Perform, rightTag.Discuss do
    local startPos = widgets.trans3DPos_Start.localPosition.x + girlOffSet[i].x
    self.modelStartPos[i] = -camera.orthographicSize / hu * startPos
  end
  self.modelCheckPos = -camera.orthographicSize / hu * widgets.trans3DPos_Check.localPosition.x
end

function IllustrateInfo:__ResetModelPos()
  self.m_objModel:ApplyCameraParam(CamDataType.Detaile)
  local trans = self.m_objModel:Get3dObj().transform
  local pos = trans.position
  trans.position = Vector3.New(self.modelStartPos[self.m_rightTag], pos.y, pos.z)
end

function IllustrateInfo:_dressUp(illustrateId)
  local damageLv = Logic.illustrateLogic:GetDamageLv()
  local ss_id = self:_GetSsId()
  local dressID = self:_getDressID(ss_id, damageLv)
  self.m_objModel:DressUp(dressID)
end

function IllustrateInfo:_getDressID(ss_id, damagelv)
  local config = configManager.GetDataById("config_ship_show", ss_id)
  local res = configManager.GetDataById("config_ship_model", config.model_id)
  if damagelv == DamageLevel.NonDamage then
    return res.standard_normal
  else
    return res.standard_dapo
  end
end

function IllustrateInfo:_ShowIllustrate(illustrateId)
  local widgets = self:GetWidgets()
  local is3D = self.m_is3D
  widgets.im_2dgirl.gameObject:SetActive(not is3D)
  widgets.im_quality.color = Color.New(255, 255, 255, is3D and 0 or 255)
  self.m_objModel.m_camera.enabled = is3D
  if is3D then
    self.m_objModel:SetBackgroundTex(widgets.im_quality.mainTexture)
  else
    local ss_id = Logic.illustrateLogic:GetIllustrateShowId(self.m_illustrateId)
    self:_SetSsId(ss_id)
    local image = configManager.GetDataById("config_ship_show", ss_id).ship_draw
    UIHelper.SetImage(widgets.im_2dgirl, image)
  end
end

function IllustrateInfo:_ShowButton(index)
  self:_StopTimer()
  index = index or rightTag.Perform
  local widgets = self:GetWidgets()
  widgets.toggroup.gameObject:SetActive(index == rightTag.Property and self.m_is3D)
  if index == rightTag.Property then
    widgets.tog_common.isOn = self.m_isCommon
  end
  local have = Logic.illustrateLogic:HaveIllustrate(self.m_illustrateId)
  local isOpenAnimoji = Face:IsSupport()
  local tweenPosition = configManager.GetDataById("config_parameter", 278).arrValue
  FrameTimer.New(function()
    for k, v in pairs(self.tabTags) do
      local position = self.tagGroup[k]:GetComponent(RectTransform.GetClassType())
      position = position.anchoredPosition
      if k == index + 1 then
        self.tabTags[k].from = position
        self.tabTags[k].to = Vector3.New(tweenPosition[1], position.y, 0)
        self.tabTags[k]:Play(true)
      else
        self.tabTags[k].from = position
        self.tabTags[k].to = Vector3.New(tweenPosition[2], position.y, 0)
        self.tabTags[k]:Play(true)
      end
    end
  end, 1, 1):Start()
  if self.type == IllustrateType.ActivitySSR then
    widgets.btn_check.gameObject:SetActive(false)
    widgets.obj_2dto3d.gameObject:SetActive(false)
    widgets.btn_animoji.gameObject:SetActive(false)
    widgets.btn_share.gameObject:SetActive(false)
    return
  end
  widgets.btn_check.gameObject:SetActive(have)
  widgets.obj_2dto3d.gameObject:SetActive(have)
  if have then
    widgets.btn_animoji.gameObject:SetActive(isOpenAnimoji)
  else
    widgets.btn_animoji.gameObject:SetActive(false)
  end
end

function IllustrateInfo:_GirlTween()
  local widgets = self:GetWidgets()
  if self.m_is3D then
    local modelObj = self.m_objModel:Get3dObj()
    local from = modelObj.transform.localPosition.x
    local to = self.modelStartPos[self.m_rightTag]
    if from ~= to then
      local seq = UISequence.NewSequence(modelObj.gameObject)
      seq:Join(modelObj.transform:TweenLocalMoveX(from, to, 0.15))
      seq:AppendCallback(function()
        self.m_isTween = false
      end)
      seq:ResetToBeginning()
      seq:Play(true)
    end
  else
    local tween_girl = widgets.tween_girl
    local pos_to = self:_GetPositionTo()
    tween_girl.from = widgets.trans_girl.localPosition
    tween_girl.to = pos_to
    if tween_girl.from ~= tween_girl.to then
      tween_girl:ResetToBeginning()
      tween_girl:Play(true)
    end
  end
end

function IllustrateInfo:_GirlInfoTween()
  local widgets = self:GetWidgets()
  if (self.m_rightTag == rightTag.Property or self.m_rightTag == rightTag.Discuss) and self.m_rightTagPre == rightTag.Perform then
    widgets.tween_girlInfo:Play(false)
  elseif (self.m_rightTagPre == rightTag.Property or self.m_rightTagPre == rightTag.Discuss) and self.m_rightTag == rightTag.Perform then
    widgets.tween_girlInfo:Play(true)
  end
end

function IllustrateInfo:_RegisterTogGroup()
  local widgets = self:GetWidgets()
  self.tagGroup = {
    widgets.tog_perform,
    widgets.tog_property,
    widgets.tog_discuss,
    widgets.tog_strategy
  }
  for _, tog in ipairs(self.tagGroup) do
    widgets.left_tag:RegisterToggle(tog)
  end
end

function IllustrateInfo:_InitTagTween(illustrateState)
  local widgets = self:GetWidgets()
  if illustrateState == IllustrateState.LOCK then
    self.tabTags = {
      [3] = widgets.twnPos_discuss
    }
  else
    self.tabTags = {
      widgets.twnPos_perform,
      widgets.twnPos_property,
      widgets.twnPos_discuss,
      widgets.twnPos_strategy
    }
  end
end

function IllustrateInfo:_UnActiveTagGroup()
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(self.m_illustrateId)
  if illustrateState == IllustrateState.LOCK then
    local widgets = self:GetWidgets()
    widgets.left_tag:ResigterToggleUnActive(rightTag.Property, self._lockTips)
    widgets.left_tag:ResigterToggleUnActive(rightTag.Strategy, self._lockTips)
  end
end

function IllustrateInfo:_lockTips()
  noticeManager:ShowTipById(500001)
end

function IllustrateInfo:_UnRegisterTogGroup()
  local widgets = self:GetWidgets()
  widgets.left_tag:ClearToggles()
end

function IllustrateInfo:_UpdataIllustrate(param)
  self:_ShowIllustrateInfo(param[1], param[2])
end

function IllustrateInfo:_SwitchTag(index)
  self.m_rightTagPre = self.m_rightTag
  self.m_rightTag = index
  local pageBefore = rightPage[self.m_rightTagPre]
  if pageBefore then
    self.m_page[self.m_rightTagPre]:TweenOut()
  end
  local pageNow = rightPage[self.m_rightTag]
  if pageNow then
    self.m_page[self.m_rightTag]:TweenIn()
  end
  self:_ShowButton(index)
  self:_GirlTween()
  self:_GirlInfoTween()
end

function IllustrateInfo:_SwitchState(index)
  if not self.m_is3D then
    return
  end
  self.m_isCommon = not self.m_isCommon
  local widgets = self:GetWidgets()
  widgets.tx_common.gameObject:SetActive(self.m_isCommon)
  widgets.tx_destroy.gameObject:SetActive(not self.m_isCommon)
  widgets.im_common.gameObject:SetActive(self.m_isCommon)
  widgets.im_destroy.gameObject:SetActive(not self.m_isCommon)
  Logic.illustrateLogic:SetDamageLv(damageLvMap[self.m_isCommon])
  self:_dressUp(self.m_illustrateId)
end

function IllustrateInfo:_OpenAnimoji()
  local ss_id = self:_GetSsId()
  UIHelper.OpenPage("AnimojiPage", ss_id)
end

function IllustrateInfo:_ShowGetApproach()
  local tid = Logic.illustrateLogic:GetIllustrateTid(self.m_illustrateId)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.SHIP, tid, true))
end

function IllustrateInfo:_CheckIllustrate()
  local widgets = self:GetWidgets()
  if not self.m_isCheck then
    self.m_isCheck = true
    local widgets = self:GetWidgets()
    widgets.shipInfo:SetActive(false)
    widgets.otheritem:SetActive(false)
    self:SetTopVisibleByPos(false)
    self.m_page[self.m_rightTag].gameObject.transform.localPosition = Vector3.New(3000, 0, 0)
    self.m_isTween = true
    local ss_id = self:_GetSsId()
    local config = configManager.GetDataById("config_ship_position", ss_id)
    if self.m_is3D then
      local modelObj = self.m_objModel:Get3dObj()
      local tween = modelObj.gameObject:GetComponent(UITweener.GetClassType())
      if not tween then
        modelObj.transform:TweenLocalMoveX(self.modelStartPos[self.m_rightTag], self.modelCheckPos, 0.15)
        tween = modelObj.gameObject:GetComponent(UITweener.GetClassType())
      end
      tween:SetOnFinished(function()
        self.m_isTween = false
      end)
      tween:ResetToBeginning()
      tween:Play(true)
    else
      local tween_girl = widgets.tween_girl
      local im_2d = widgets.im_2dgirl
      local pos_to = Vector3.New(config.ship_position3[1], config.ship_position3[2], 0)
      tween_girl.from = widgets.trans_girl.localPosition
      tween_girl.to = pos_to
      tween_girl:SetOnFinished(function()
        local mirrorValue = mirror[config.ship_inversion3]
        im_2d.transform.localScale = Vector3.New(config.ship_scale3 / 10000 * mirrorValue, config.ship_scale3 / 10000, 1)
        self.m_isTween = false
      end)
      tween_girl:ResetToBeginning()
      tween_girl:Play(true)
    end
    local shipName = Data.illustrateData:GetIllustrateById(self.m_illustrateId).Name
    local dotinfo = {
      info = "ui_check",
      entrance = 2,
      type = self.m_is3D and 2 or 1,
      ship_name = shipName
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
end

function IllustrateInfo:_CancelCheck()
  if self.m_isDrag then
    return
  end
  if self.m_isCheck and not self.m_isTween then
    self.m_isCheck = false
    local widgets = self:GetWidgets()
    widgets.im_2dgirl.transform.localPosition = Vector3.zero
    if self.m_objModel then
      self.m_objModel:ResetEulerAngels()
      self:__ResetModelPos()
    end
    widgets.shipInfo:SetActive(true)
    widgets.otheritem:SetActive(true)
    local isOpenAnimoji = Face:IsSupport()
    self.tab_Widgets.btn_animoji.gameObject:SetActive(isOpenAnimoji)
    self:SetTopVisibleByPos(true)
    self.m_page[self.m_rightTag].gameObject.transform.localPosition = Vector3.New(0, 0, 0)
    self:_ShowButton(self.m_rightTag)
    self:_init2D3DPosition()
    local illustrateInfo = Data.illustrateData:GetIllustrateById(self.m_illustrateId)
    UIHelper.SetImage(widgets.im_quality, GirlEquipQualityBgTexture[illustrateInfo.quality])
  end
end

function IllustrateInfo:_Switch2D3D()
  self.m_is3D = not self.m_is3D
  Logic.illustrateLogic:SetIs3D(self.m_is3D)
  UIHelper.SetUILock(true)
  self:_ShowSwitch2D3D(self.m_is3D)
  self:_SwitchWidgetSet()
  self:_ShowIllutrateObj(self:_GetSsId(), true)
  self:_ShowButton(self.m_rightTag)
end

function IllustrateInfo:_SwitchWidgetSet()
  local widgets = self:GetWidgets()
  local is3D = self.m_is3D
  widgets.im_2dgirl.gameObject:SetActive(not is3D)
  widgets.im_quality.color = Color.New(255, 255, 255, is3D and 0 or 255)
  self.m_objModel.m_camera.enabled = is3D
  if is3D then
    self.m_objModel:SetBackgroundTex(widgets.im_quality.mainTexture)
  end
end

function IllustrateInfo:_ShowSwitch2D3D(is3D)
  local widgets = self:GetWidgets()
  widgets.tween_2d:Play(is3D)
  local timer = self:CreateTimer(function()
    local is3D = Logic.illustrateLogic:GetIs3D()
  end, 0.5, 1, false)
  self:StartTimer(timer)
  self:_init2D3DPosition()
end

function IllustrateInfo:_ShowBaseInfo()
  local widgets = self:GetWidgets()
  local illustrateInfo = Data.illustrateData:GetIllustrateById(self.m_illustrateId)
  UIHelper.SetText(widgets.txt_name, illustrateInfo.Name)
  local config = configManager.GetDataById("config_ship_handbook", self.m_illustrateId)
  UIHelper.SetText(widgets.txt_CVname, "CV:" .. config.ship_character_voice)
  UIHelper.SetImage(widgets.im_type, NewCardShipTypeImg[illustrateInfo.type])
  UIHelper.SetImage(widgets.im_quality, GirlQualityBgTexture[illustrateInfo.quality])
  local shipTypeConfig = configManager.GetDataById("config_ship_type", illustrateInfo.type)
  UIHelper.SetImage(widgets.img_type_name, shipTypeConfig.wordsimage)
  local qualityPath = configManager.GetDataById("config_quality_param", illustrateInfo.quality).togglelist_imgbg
  UIHelper.SetImage(widgets.img_BG, qualityPath)
end

function IllustrateInfo:im_quality_drag(go, eventData, targetTran)
  self.m_isDrag = true
  if self.m_is3D then
    self:_On3DDrag(go, eventData)
  else
    self:_On2DDrag(go, eventData)
    self:_OnSliderDrag(go, eventData)
  end
end

function IllustrateInfo:im_quality_drag_end(go, eventData, targetTran)
  self.m_isDrag = false
end

function IllustrateInfo:_On3DDrag(go, eventData)
  local targetTran = self.m_objModel:Get3dObj().transform
  local delta = eventData.delta
  if not IsNil(targetTran) then
    local angles = targetTran.localEulerAngles
    angles.y = angles.y - delta.x
    targetTran.localEulerAngles = angles
  end
end

function IllustrateInfo:_On2DDrag(go, eventData)
  local widgets = self:GetWidgets()
  local targetTran = widgets.im_2dgirl.transform
  if not self.m_isCheck then
    return
  end
  Logic.girlInfoLogic:GirlDrag2D(go, eventData, targetTran)
end

function IllustrateInfo:_ShowSubtitle(textContent)
  local widgets = self:GetWidgets()
  widgets.txt_talk.text = textContent
  widgets.obj_talk:SetActive(true)
end

function IllustrateInfo:_CloseSubtitle()
  local widgets = self:GetWidgets()
  widgets.txt_talk.text = ""
  widgets.obj_talk:SetActive(false)
end

function IllustrateInfo:DoOnHide()
  if self.m_objModel ~= nil then
    UI3DModelManager.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  self.m_cachModelStr = ""
end

function IllustrateInfo:DoOnClose()
  self:_UnRegisterTogGroup()
  self:_StopTimer()
  Logic.illustrateLogic:SetDamageLv(DamageLevel.NonDamage)
  if self.m_objModel ~= nil then
    UI3DModelManager.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  inputManager:UnregisterAllInput(self)
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
end

function IllustrateInfo:_StopTimer()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
end

function IllustrateInfo:__onModeBZoom(delta)
  if self.m_is3D or not self.m_isCheck then
    return
  end
  Logic.girlInfoLogic:GirlPinch2D(delta, self.tab_Widgets.im_2dgirl.transform, self.m_illustrateId)
end

function IllustrateInfo:_OnSwitchFashion(data)
  local ss_id = data.ship_show_id
  self:_ShowIllutrateObj(ss_id)
end

function IllustrateInfo:_ShowIllutrateObj(ss_id, force)
  force = force or false
  local showConfig = configManager.GetDataById("config_ship_show", ss_id)
  local equalCheck = function(num1, num2)
    return num1 == num2
  end
  local widgets = self:GetWidgets()
  if not force and equalCheck(ss_id, self:_GetSsId()) then
    return
  end
  local damageLv = Logic.illustrateLogic:GetDamageLv()
  local dressID = self:_getDressID(ss_id, damageLv)
  local param = {showID = ss_id, dressID = dressID}
  local sm_config = configManager.GetDataById("config_ship_model", showConfig.model_id)
  if equalCheck(self.m_cachModelStr, sm_config.model) then
    self.m_objModel:DressUp(dressID)
  else
    self.m_objModel:ChangeObj(param)
    self.m_cachModelStr = sm_config.model
  end
  self:__ResetModelPos()
  UIHelper.SetImage(widgets.im_2dgirl, showConfig.ship_draw)
  self:_SetSsId(ss_id)
  self:_init2D3DPosition()
end

function IllustrateInfo:_OnSliderDrag(go, eventData)
  self.delta = self.delta + eventData.delta.x
end

function IllustrateInfo:_OnPointUp(go, param)
  if self.m_is3D or self.m_isCheck then
    return
  end
  if math.abs(self.delta) > 10 then
    self:_ChangeHero(self.delta > 0 and -1 or 1)
  end
  self.delta = 0
end

function IllustrateInfo:_ChangeHero(step)
  if next(self.tabHeroId) == nil then
    return
  end
  local widgets = self:GetWidgets()
  local curIndex
  for k, v in ipairs(self.tabHeroId) do
    if v == self.m_illustrateId then
      curIndex = k
    end
  end
  if curIndex == nil then
    logError("FATAL ERROR:can not find change index")
    return
  end
  local nextIndex = curIndex + step
  if 1 <= nextIndex and nextIndex <= #self.tabHeroId then
    self.m_illustrateId = self.tabHeroId[nextIndex]
    local ss_id = Logic.illustrateLogic:GetIllustrateShowId(self.m_illustrateId)
    self:_SetSsId(ss_id)
    widgets.left_tag:RemoveToggleUnActive(rightTag.Property)
    widgets.left_tag:RemoveToggleUnActive(rightTag.Strategy)
    self.tabChangeParam = {
      id = self.m_illustrateId,
      tabHeroId = self.tabHeroId,
      Type = self.type
    }
    self:_UnRegisterTogGroup()
    self:_RegisterTogGroup()
    self:DoOnOpenInit()
    self:_UpdataIllustrate({
      self.tabHeroId[nextIndex],
      self.m_rightTag
    })
  end
  self.m_cachModelStr = ""
end

return IllustrateInfo
