local ARKitPage = class("UI.ARkit.ARKitPage", LuaUIPage)
local multiple = 0.1

function ARKitPage:DoInit()
  self.isClickAction = false
  self.curSliderNum = 0
  self.m_objModel = nil
  self.m_use3dTouch = false
  self.brightEnough = false
  self.isClickStart = false
  self.hideOrShow = false
  self.isCanDrag = false
  self.isFirstOpen = true
  self.tab_Widgets.btn_photograph.gameObject:SetActive(platformManager:ShowShare())
end

function ARKitPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_start, self._ClickStart, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._LoadStartInfo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_set, self._ShowTitle, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_photograph, self._ShareHome, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._HomeShareOver, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_add, self._AddGirl, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reduce, self._ReduceGirl, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_hideShow, self._BtnHideShowFnc, self)
  UGUIEventListener.AddOnSliderChangedCB(self.tab_Widgets.sld_girl, self._SliderGirlSacle, self)
  self:RegisterEvent(LuaCSharpEvent.ARBrightness, self._ARBrightness, self)
  self:RegisterEvent(LuaCSharpEvent.ARFlushGirlPosition, self.RefreshModel, self)
end

function ARKitPage:DoOnOpen()
  self:_LoadSliderNum()
  self:_LoadStartInfo()
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, true)
end

function ARKitPage:_ARBrightness(param)
  if param < 0.3 then
    self.brightEnough = false
  else
    self.brightEnough = true
  end
end

function ARKitPage:_LoadSliderNum(...)
  self.min = configManager.GetDataById("config_ar_config", 25).data
  self.maxNum = configManager.GetDataById("config_ar_config", 24).data
  self.curSliderNum = 0.5
end

function ARKitPage:_LoadStartInfo()
  if self.isFirstOpen then
    XR:InitHome()
    self.isFirstOpen = false
  else
    XR:ResetHome()
  end
  self.curScaleNum = self.curSliderNum * (self.maxNum - self.min) + self.min
  XR:ApplyScale(self.curScaleNum)
  self.isClickStart = false
  self.isCanDrag = false
  self.tab_Widgets.tween_set:ResetToInit()
  UIHelper.SetText(self.tab_Widgets.text_tip, UIHelper.GetString(1430030))
  self.tab_Widgets.text_tip.gameObject:SetActive(false)
  self.tab_Widgets.obj_tip:SetActive(false)
  self.tab_Widgets.obj_in:SetActive(false)
  self.tab_Widgets.obj_out:SetActive(true)
  self.isClickAction = false
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  self.tab_Widgets.btn_start.gameObject:SetActive(true)
  self.tab_Widgets.obj_zhunXin:SetActive(true)
  self.tab_Widgets.obj_start:SetActive(true)
  self.tab_Widgets.obj_arkit:SetActive(false)
  self.curSliderNum = 0.5
end

function ARKitPage:_ClickStart()
  if self.brightEnough then
    eventManager:FireEventToCSharp(LuaCSharpEvent.ARPutConfirm)
    self.isCanDrag = not self.isCanDrag
    self.tab_Widgets.obj_start:SetActive(false)
    self.tab_Widgets.obj_arkit:SetActive(true)
    self:_Create3DModel()
  else
    UIHelper.SetText(self.tab_Widgets.text_tip, UIHelper.GetString(1430030))
    self.tab_Widgets.text_tip.gameObject:SetActive(true)
    self.tab_Widgets.obj_tip:SetActive(true)
  end
end

function ARKitPage:_Create3DModel()
  local cameraPosition = XR:FetchCameraPosition()
  local tabUserInfo = Data.userData:GetUserData()
  local heroInfo = Data.heroData:GetHeroById(tabUserInfo.SecretaryId)
  if heroInfo == nil then
    return
  end
  local shipShow = Logic.shipLogic:GetShipShowByHeroId(tabUserInfo.SecretaryId)
  local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(tabUserInfo.SecretaryId)
  local curHp = Logic.shipLogic:GetHeroHp(heroInfo.HeroId)
  self.m_modelDress = Logic.shipLogic:GetDressupId(shipShow.model_id, curHp, heroAttr[AttrType.HP])
  self.m_secClear = Logic.shipLogic:GetARSecClear(shipShow.model_id)
  XR:ApplySecClear(self.m_secClear)
  local param = {
    showID = shipShow.ss_id,
    dressID = self.m_modelDress
  }
  self.m_objModel = UIHelper.Create3DModel(param)
  self.hideMech = PlayerPrefs.GetInt("HideMech", 0) == 1
  if self.m_objModel.m_3dObj then
    local centerPos = XR:FetchCenterPosition()
    self.m_objModel.m_3dObj.transform.position = centerPos
    self.m_objModel.m_3dObj.transform:LookAt(Vector3.New(cameraPosition.x, centerPos.y, cameraPosition.z))
    self.m_objModel:SetLightPosition(cameraPosition)
    self.m_objModel.m_3dObj:changeSpecifyPartState(not self.hideMech)
    local girlData = Data.heroData:GetHeroById(heroInfo.HeroId)
    local loginName = "login"
    if girlData.MarryTime ~= 0 then
      loginName = "login_m"
    end
    self.m_objModel.m_3dObj:playBehaviour(loginName, false, function()
      self.m_objModel.m_3dObj:playBehaviour("stand_loop", true)
    end)
  end
  self:_ShowGirlScale()
  if self.m_objModel.m_3dObj then
    self:__registerModeBInput()
  end
end

function ARKitPage:RefreshModel()
  if self.m_objModel and self.m_objModel.m_3dObj then
    local cameraPosition = XR:FetchCameraPosition()
    local centerPos = XR:FetchCenterPosition()
    self.m_objModel.m_3dObj.transform.position = centerPos
    self.m_objModel.m_3dObj.transform:LookAt(Vector3.New(cameraPosition.x, centerPos.y, cameraPosition.z))
  end
end

function ARKitPage:__registerModeBInput()
  local tabParam = {
    dragMove = function(param)
      self:__onModeBDrag(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function ARKitPage:__onModeBDrag(delta)
  if not self.isCanDrag then
    return
  end
  if not IsNil(self.m_objModel.m_3dObj.transform) then
    local angles = self.m_objModel.m_3dObj.transform.localEulerAngles
    angles.y = angles.y - delta.x
    self.m_objModel.m_3dObj.transform.localEulerAngles = angles
  end
end

function ARKitPage:_BtnHideShowFnc()
  self.tab_Widgets.obj_hide:SetActive(self.hideOrShow)
  self.hideOrShow = not self.hideOrShow
  if self.isClickAction then
    self.tab_Widgets.tween_set:ResetToEnd()
  else
    self.tab_Widgets.tween_set:ResetToInit()
  end
  self.tab_Widgets.tween_rota:Play(self.hideOrShow)
end

function ARKitPage:_ShowTitle()
  self.isClickAction = not self.isClickAction
  local widgets = self:GetWidgets()
  local user = Data.userData:GetUserData()
  widgets.obj_in:SetActive(self.isClickAction)
  widgets.obj_out:SetActive(not self.isClickAction)
  widgets.tween_set:Play(self.isClickAction)
  local ss_id = Logic.shipLogic:GetShipShowByHeroId(user.SecretaryId).ss_id
  local iid = Logic.illustrateLogic:Ssid2Sfid(ss_id)
  local subActionConfig = Logic.illustrateLogic:GetSubActions(ss_id)
  self:_ShowSubTitle(iid, subActionConfig, widgets.obj_subaction, widgets.trans_subaction)
  self:_ShowBaseInfo(iid)
end

function ARKitPage:_ShowSubTitle(illustrateId, subtitleConfig, obj, trans)
  local widgets = self:GetWidgets()
  local indexName = 1
  UIHelper.CreateSubPart(obj, trans, #subtitleConfig, function(index, tabPart)
    local config = Logic.illustrateLogic:GetSubTitleConfig(subtitleConfig[index])
    local unlock = Logic.illustrateLogic:IsUnLockBehaviour(illustrateId, config.behaviour_name)
    tabPart.obj_weidianji:SetActive(not unlock)
    tabPart.obj_dianji:SetActive(unlock)
    if config.special_name == "" then
      UIHelper.SetText(tabPart.tx_subtitle, config.ship_dialogue)
      UIHelper.SetText(tabPart.tx_subtitle_wei, config.ship_dialogue)
    else
      UIHelper.SetText(tabPart.tx_subtitle, config.special_name .. indexName)
      UIHelper.SetText(tabPart.tx_subtitle_wei, config.special_name .. indexName)
      indexName = indexName + 1
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_subtitle, function()
      if not unlock then
        noticeManager:ShowTip(UIHelper.GetString(500000))
      else
        local param = {
          behName = config.behaviour_name
        }
        self:PlayARKitBehaviour(param)
      end
    end)
  end)
end

function ARKitPage:_ShowBaseInfo(illustrateId)
  local widgets = self:GetWidgets()
  local infoConfig = Data.illustrateData:GetIllustrateById(illustrateId)
  local cv = Logic.illustrateLogic:GetCvConfig(illustrateId)
  UIHelper.SetText(widgets.tx_name, cv)
  local countryConfig = configManager.GetDataById("config_country_info", infoConfig.shipCountry)
  UIHelper.SetText(widgets.tx_country, countryConfig.country_name)
end

function ARKitPage:PlayARKitBehaviour(param)
  if self.m_objModel then
    local obj = self.m_objModel:Get3dObj()
    obj:playBehaviour(param.behName, false, nil)
  end
end

function ARKitPage:_AddGirl()
  if self.curSliderNum >= 1 then
    self.curSliderNum = 1
  else
    self.curSliderNum = self.curSliderNum + multiple
  end
  self:_ShowGirlScale()
end

function ARKitPage:_ReduceGirl()
  if self.curSliderNum <= 0 then
    self.curSliderNum = 0
  else
    self.curSliderNum = self.curSliderNum - multiple
  end
  self:_ShowGirlScale()
end

function ARKitPage:_SliderGirlSacle(param)
  self.curSliderNum = param
  self:_ShowGirlScale()
end

function ARKitPage:_ShowGirlScale()
  self.curScaleNum = self.curSliderNum * (self.maxNum - self.min) + self.min
  self.tab_Widgets.sld_girl.value = self.curSliderNum
  self.m_objModel.m_3dObj:setModelScale(Vector3.New(self.curScaleNum, self.curScaleNum, self.curScaleNum))
  XR:ApplyScale(self.curScaleNum)
end

function ARKitPage:_Check3dTouch()
  local have3dTouch = UIHelper.Check3dTouch()
  self.tab_Widgets.tog_use3dTouch.gameObject:SetActive(have3dTouch)
  self.tab_Widgets.tog_use3dTouch.isOn = have3dTouch
  self.m_use3dTouch = have3dTouch
end

function ARKitPage:_Use3dTouch()
  if self.tab_Widgets.tog_use3dTouch.isOn then
    self.m_use3dTouch = true
    self.tab_Widgets.script_pressure.enabled = true
  else
    self.m_use3dTouch = false
    self.tab_Widgets.script_pressure.enabled = false
  end
end

function ARKitPage:_ShareHome()
  eventManager:SendEvent(LuaEvent.HomePauseBehavior, true)
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function ARKitPage:_Use3dTouchShare()
  if self.m_use3dTouch and platformManager:ShowShare() then
    self:_ShareHome()
    self.tab_Widgets.script_pressure.enabled = false
  end
end

function ARKitPage:_HomeShareOver()
  self:ShareComponentShow(true)
  eventManager:SendEvent(LuaEvent.HomePauseBehavior, false)
  self.tab_Widgets.script_pressure.enabled = true
  self.tab_Widgets.obj_start:SetActive(false)
  self.tab_Widgets.tween_set:Play(self.isClickAction)
end

function ARKitPage:_ClickClose()
  UIHelper.Back()
  eventManager:SendEvent(LuaEvent.IsHideHomePage, false)
end

function ARKitPage:DoOnHide()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
end

function ARKitPage:DoOnClose()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  XR:ClearHome()
  inputManager:UnregisterAllInput(self)
  eventManager:SendEvent(LuaEvent.IsCloseHomeGirl, false)
end

return ARKitPage
