local DrawPreviewPage = class("UI.GirlInfo.DrawPreview", LuaUIPage)
local HeroBasicAttr = require("logic.AttrLogic.HeroBasicAttr")
local heroDev = Logic.developLogic
local e_lvstate = heroDev.E_HeroLvState
local MAXBREAKLEVEL = 5
local MAXCOMBINELV = 100
local MAXSHIPLEVEL = 90
local MAXSKILLLEVEL = 10
local PskillTypeColorMap = {
  [TalentType.ALL] = {
    236,
    161,
    43
  },
  [TalentType.ATTACK] = {
    236,
    161,
    43
  },
  [TalentType.DEFEND] = {
    65,
    122,
    227
  },
  [TalentType.ASSIST] = {
    43,
    205,
    58
  }
}
local gccount = 0

function DrawPreviewPage:DoInit()
  self.m_tabWidgets = nil
  self.m_buildingId = -1
  self.m_index = 1
  self.m_ExtractInfo = {}
  self.m_tabShipInfo = {}
  self.m_propNum = {}
  self.m_pskillArr = {}
  self.m_fleetType = FleetType.Normal
  self.is3D = false
  self.m_isHeng = true
  self.m_isCheck = false
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

local clickGirl = {
  "click1",
  "click2",
  "click3"
}

function DrawPreviewPage:DoOnOpen()
  local params = self:GetParam()
  self.page = params.page
  self:__Create3DShow()
  MAXSHIPLEVEL = configManager.GetDataById("config_parameter", 70).value
  self.m_buildingId = params.id
  self.m_ExtractInfo = Data.buildShipData:GetUpShip_InExtractByBulidId(self.m_buildingId)
  self.m_heroId = self.m_ExtractInfo[self.m_index]
  self:_SetFleetType(params.FleetType)
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_Refresh()
end

function DrawPreviewPage:_SetNextBtnShow()
  if self.m_ExtractInfo and #self.m_ExtractInfo <= 1 then
    self.m_tabWidgets.btn_Left.gameObject:SetActive(false)
    self.m_tabWidgets.btn_Right.gameObject:SetActive(false)
  else
    self.m_tabWidgets.btn_Left.gameObject:SetActive(1 < self.m_index)
    self.m_tabWidgets.btn_Right.gameObject:SetActive(self.m_index < #self.m_ExtractInfo)
  end
end

function DrawPreviewPage:_SetFleetType(fleetType)
  self.m_fleetType = fleetType
end

function DrawPreviewPage:_GetFleetType()
  return self.m_fleetType
end

function DrawPreviewPage:_Refresh()
  self:BehaviourSetActive(false)
  self:ResetScrollbar()
  self:_SetNextBtnShow()
  self.m_ship_MainId = self.m_ExtractInfo[self.m_index]
  local sm_id = self.m_ship_MainId
  local shipMain = configManager.GetDataById("config_ship_main", sm_id)
  self.m_shipInfoId = shipMain.ship_info_id
  self.m_pskillArr = shipMain.direct_activate_talent_id
  self:_ShowLeftGirlInfo()
  self:_LoadPropertInfo()
  self:_LoadSkillInfo(self.m_pskillArr)
  self:_ShowHeroChar(sm_id)
  self:_LoadGongMingInfo()
  self:ShowMagazineTag()
end

function DrawPreviewPage:ResetScrollbar()
  self.m_tabWidgets.scr_cont.value = 1
end

function DrawPreviewPage:_ShipMianIdAdd(mainId)
  return mainId + 5 + (MAXSHIPLEVEL - 80) * 2
end

function DrawPreviewPage:_ShipMianIdSub(mainId)
  return mainId - (5 + (MAXSHIPLEVEL - 80) * 2)
end

function DrawPreviewPage:_ShowLeftGirlInfo()
  local shipInfoCfg = configManager.GetDataById("config_ship_info", self.m_shipInfoId)
  UIHelper.SetImage(self.m_tabWidgets.icon_type, NewCardShipTypeImg[shipInfoCfg.ship_type])
  local shipCVConfig = Logic.shipLogic:GetShipShowHandBookById(self.m_ship_MainId)
  UIHelper.SetText(self.m_tabWidgets.txt_CVname, "CV:" .. shipCVConfig.ship_character_voice)
  UIHelper.SetText(self.m_tabWidgets.txt_name, shipInfoCfg.ship_name)
  local quality = shipInfoCfg.quality
  local imgbg = configManager.GetDataById("config_quality_param", quality)
  local shipShowCfg = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
  UIHelper.SetImage(self.m_tabWidgets.imggirl, shipShowCfg.ship_draw)
  UIHelper.SetImage(self.m_tabWidgets.img_NameBG, imgbg.preview_name_bg)
  UIHelper.SetImage(self.m_tabWidgets.imgQuality, imgbg.preview_imgbg)
  local shipPosConf = configManager.GetDataById("config_ship_position", self.m_shipInfoId)
  self.position = shipPosConf.draw_position
  local grilTrans = self.m_tabWidgets.imggirl.transform
  grilTrans.localPosition = Vector3.New(self.position[1], self.position[2], 0)
  local scaleSize = shipPosConf.draw_scale / 10000
  local mirror = shipPosConf.ship_inversion1
  self.scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = self.scale
  self.start2dRotation = self.m_tabWidgets.imggirl.transform.localRotation
end

function DrawPreviewPage:UpdateGirlInfo()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_LoadPropertInfo(self.m_tabShipInfo)
  self:ShowMagazineTag()
end

function DrawPreviewPage:UpdateGirlTog(heroId)
  self.m_tabWidgets.tween_dongHua:ResetToBeginning()
  self.m_tabWidgets.tween_dongHua:Play(true)
  noticeManager:CloseTip()
  self.m_heroId = heroId
  self:_RegisterAllDot()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_Refresh()
end

function DrawPreviewPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHero, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_closeTip, function()
    UIHelper.ClosePage("DrawPreviewPage")
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_Left, function()
    if self.m_index > 1 then
      self.m_index = self.m_index - 1
      self:_Refresh()
    end
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_Right, function()
    if self.m_index >= 1 and self.m_index < #self.m_ExtractInfo then
      self.m_index = self.m_index + 1
      self:_Refresh()
    end
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnVoice, function()
    local widgets = self.tab_Widgets
    local shipShowCfg = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
    self.showID = shipShowCfg.ss_id
    self.dressID = configManager.GetDataById("config_ship_model", shipShowCfg.model_id).standard_normal
    local param = {
      showID = self.showID,
      dressID = self.dressID
    }
    if self.m_objModel == nil then
      self:__Create3DShow()
    end
    self.m_objModel.m_camera.enabled = false
    SectionBehaviourMsg:DestoryBehaviour()
    if self:__CheckModelChange(param) or self.m_objModel:Get3dObj() == nil then
      self:__ChangeModelShow(param)
    end
    self.obj = self.m_objModel:Get3dObj()
    self.obj:playBehaviour("show_get", false, nil)
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnCheck, function()
    self:BehaviourSetActive(false)
    self:__CheckBulidGirl()
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_background, function()
    self.m_isCheck = false
    self.m_tabWidgets.obj_CheckPart:SetActive(false)
    self.is3D = false
    self:ModeChange(false)
    self:_Hide3DModel()
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_modeConvert, self._ChangeModel, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_box, self.__ClickSpecial, self)
  UGUIEventListener.AddOnDrag(widgets.im_box, self.__OnDrag, self)
  UGUIEventListener.AddOnEndDrag(widgets.im_box, self.__OnDragEnd, self)
  UGUIEventListener.AddOnDrag(widgets.img_background, self.__OnDrag, self)
  UGUIEventListener.AddButtonOnClick(widgets.img_background, self.__CancelCheck, self)
  UGUIEventListener.AddOnEndDrag(widgets.img_background, self.__OnDragEnd, self)
end

function DrawPreviewPage:BehaviourSetActive(bool)
  if self.m_objModel == nil then
    return
  end
  self.obj = self.m_objModel:Get3dObj()
  if self.obj then
    if bool then
      self.obj:ContinueBehaviour()
    else
      self.obj:PauseBehaviour()
    end
  end
end

function DrawPreviewPage:__OnClick()
  if self.m_isDrag then
    return
  end
  if self.m_isCheck then
    self:__CancelCheck()
    return
  end
  self:__PlayNormalAction()
end

function DrawPreviewPage:__ClickSpecial()
end

local MAX_SPECIAL_RATE = 10000

function DrawPreviewPage:__CheckSpecial()
  local rate = configManager.GetDataById("config_parameter", 91).value
  local randomNum = math.random(1, MAX_SPECIAL_RATE)
  return rate >= randomNum
end

function DrawPreviewPage:__PlayNormalAction()
  local contains = {}
  local shipShow = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
  local m_modelAnimName = ScrProfileHub.GetModelAnimName(Logic.shipLogic:GetHeroModelConfigById(shipShow.model_id))
  for v, k in pairs(clickGirl) do
    if table.containValue(m_modelAnimName, k) then
      table.insert(contains, k)
    end
  end
  local index = math.random(1, #contains)
  local action = contains[index]
  self:__PlayAction(action)
end

function DrawPreviewPage:__PlayAction(action)
  if self.is3D then
    local obj = self.m_objModel:Get3dObj()
    obj:playBehaviour(action, false, function()
      obj:playBehaviour("stand_loop", true)
    end)
  else
    local shipConfig = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
    local model = Logic.shipLogic:GetHeroModelConfigById(shipConfig.model_id)
    SectionBehaviourMsg:PlayCVSubtitle(model, "CV_" .. action .. "_" .. model, "zm_" .. action .. "_" .. model)
  end
end

function DrawPreviewPage:__OnDrag(go, eventData)
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

function DrawPreviewPage:__CancelCheck()
  if self.m_isDrag then
    return
  end
  self.m_isHeng = true
  local widgets = self:GetWidgets()
  if self.m_isCheck and not self.m_isTween then
    self.m_isCheck = false
    if self.is3D then
      self.m_objModel:ResetEulerAngels()
      self:_Hide3DModel()
    end
    self.is3D = false
    self.m_tabWidgets.obj_CheckPart:SetActive(false)
    self:ModeChange(false)
  end
end

function DrawPreviewPage:__On3DDrag(go, eventData)
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

function DrawPreviewPage:__On2DDragCommon(go, eventData)
  local position = self.bgPos
  self.delta = self.delta + eventData.delta.x
  local scale = self.delta < 0 and 1 or -1
  local bgPosition = position[2] + scale * self.delta * position[1]
  eventManager:SendEvent(LuaEvent.GirlInfoTween, bgPosition)
end

function DrawPreviewPage:__On2DDragCheck(go, eventData)
end

function DrawPreviewPage:__OnPointUp(go, param)
  if math.abs(self.delta) > 10 then
  else
    eventManager:SendEvent(LuaEvent.GirlInfoTween)
  end
  self.delta = 0
  self:__CheckGC()
end

function DrawPreviewPage:__OnDragEnd()
  self.m_isDrag = false
end

function DrawPreviewPage:__CheckGC()
  gccount = gccount + 1
  if 20 < gccount then
    gccount = 0
    collectgarbage("collect")
  end
end

function DrawPreviewPage:_RegisterAllDot()
  local widgets = self:GetWidgets()
  local heroId = self.m_heroId
  self:RegisterRedDot(widgets.redDot, heroId)
  self:RegisterRedDot(widgets.lf_reddot, heroId)
end

function DrawPreviewPage:__CheckBulidGirl()
  local widgets = self:GetWidgets()
  if not self.m_isCheck then
    self.m_isCheck = true
    widgets.obj_CheckPart:SetActive(self.m_isCheck)
    self:SetTopVisibleByPos(false)
    self.m_isTween = true
    widgets.obj_2dgirl:SetActive(not self.is3D)
    local shipInfoCfg = configManager.GetDataById("config_ship_info", self.m_shipInfoId)
    local quality = shipInfoCfg.quality
    UIHelper.SetImage(widgets.img_background, GirlQualityBgTexture[quality])
    widgets.img_background.color = Color.New(255, 255, 255, self.is3D and 0 or 255)
    if self.is3D then
      self:_Show3D()
    else
      self:_Show2D()
    end
    widgets.tween_huakuai:Play(self.is3D)
    if self.m_objModel then
      self.m_objModel:setCameraEnable(self.is3D)
    end
  end
end

function DrawPreviewPage:_ChangeModel()
  local widgets = self:GetWidgets()
  self.is3D = not self.is3D
  local shipInfoCfg = configManager.GetDataById("config_ship_info", self.m_shipInfoId)
  local quality = shipInfoCfg.quality
  UIHelper.SetImage(widgets.img_background, GirlQualityBgTexture[quality])
  widgets.img_background.color = Color.New(255, 255, 255, self.is3D and 0 or 255)
  widgets.obj_2dgirl:SetActive(not self.is3D)
  if self.is3D then
    self:_Show3D()
  else
    self:_Show2D()
  end
  widgets.tween_huakuai:Play(self.is3D)
  if self.m_objModel then
    self.m_objModel:setCameraEnable(self.is3D)
  end
end

function DrawPreviewPage:_Hide3DModel()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.m_objModel = nil
  end
  SectionBehaviourMsg:DestoryBehaviour()
end

function DrawPreviewPage:_Show2D()
  self:ModeChange(false)
  local widgets = self:GetWidgets()
  local shipPosConf = configManager.GetDataById("config_ship_position", self.m_shipInfoId)
  local shipShowCfg = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
  UIHelper.SetImage(widgets.im_2dgirl, shipShowCfg.ship_draw)
  local grilTrans = widgets.im_2dgirl.transform
  local scaleSize = shipPosConf.ship_scale3 / 10000
  local mirror = shipPosConf.ship_inversion3
  grilTrans.localScale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localPosition = Vector3.New(shipPosConf.ship_position3[1], shipPosConf.ship_position3[2], grilTrans.localPosition.z)
  self.m_isTween = false
end

function DrawPreviewPage:_Show3D()
  self:ModeChange(true)
  local widgets = self.tab_Widgets
  local shipShowCfg = configManager.GetDataById("config_ship_show", self.m_shipInfoId)
  self.showID = shipShowCfg.ss_id
  self.dressID = configManager.GetDataById("config_ship_model", shipShowCfg.model_id).standard_normal
  local param = {
    showID = self.showID,
    dressID = self.dressID
  }
  self:_Hide3DModel()
  if self.m_objModel == nil then
    self:__Create3DShow(param)
  end
  self.m_objModel.m_camera.enabled = self.is3D
  SectionBehaviourMsg:DestoryBehaviour()
  self:__ChangeModelShow(param)
  self:__ResetModelPos()
  self.m_objModel:SetBackgroundTex(widgets.img_background.mainTexture)
end

function DrawPreviewPage:ModeChange(is3d)
  self.page:SetActiveSelf(not is3d)
  local widgets = self.tab_Widgets
  widgets.obj_Content:SetActive(not is3d)
  widgets.obj_mask:SetActive(not is3d)
  if is3d then
    widgets.obj_Left:SetActive(not is3d)
    widgets.obj_Right:SetActive(not is3d)
  else
    self:_SetNextBtnShow()
  end
end

function DrawPreviewPage:__CheckModelChange(param)
  if self.lastModelParam == nil then
    self.lastModelParam = param
    return true
  else
    local isOn = self.lastModelParam.infoID ~= param.infoID or self.lastModelParam.dressID ~= param.dressID
    self.lastModelParam = param
    return isOn
  end
end

function DrawPreviewPage:__ResetModelPos()
  local trans = self.m_objModel:Get3dObj().transform
  local pos = trans.position
  trans.position = Vector3.New(0, self.modelStartPosY, pos.z)
  trans.localEulerAngles = self.start3dRotation
end

function DrawPreviewPage:__Create3DShow(param)
  local widgets = self.tab_Widgets
  local rct = widgets.img_background:GetComponent(RectTransform.GetClassType())
  local dx = rct.sizeDelta.x / UIManager:GetUIWidth()
  local dy = rct.sizeDelta.y / UIManager:GetUIHeight()
  self.m_objModel = UIHelper.Create3DModelNoRT(nil, CamDataType.Detaile, false, widgets.img_background.mainTexture, dx, dy)
end

function DrawPreviewPage:__ChangeModelShow(param)
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

function DrawPreviewPage:_ShowHeroFurther()
  local state, cid = heroDev:GetLHeroState(self.m_heroId)
  if state == e_lvstate.FULL then
    noticeManager:ShowTip(UIHelper.GetString(911007))
  else
    local param = {
      heroId = self.m_heroId,
      cid = 1
    }
    UIHelper.OpenPage("ShipMaxLevelupPage", param)
  end
end

function DrawPreviewPage:_UpdateHero()
  self.m_tabShipInfo = Data.heroData:GetHeroById(self.m_heroId)
  self:_Refresh()
end

function DrawPreviewPage:_GirlInfoTween(delta)
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    self.m_tabWidgets.tween_dongHua.from = self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D
    self.m_tabWidgets.tween_dongHua:ResetToBeginning()
    self.m_tabWidgets.tween_dongHua:Play(true)
  end
end

local attrStr = {
  [AttrTypeNew.Common] = "Common",
  [AttrTypeNew.Gun] = "Gun",
  [AttrTypeNew.Torpedo] = "Torpedo",
  [AttrTypeNew.Plane] = "Plane",
  [AttrTypeNew.Plane] = "Submerge"
}

function DrawPreviewPage:GetHeroAttr(lv, tId)
  self.basicAttr = HeroBasicAttr:new(lv, tId)
  return self.basicAttr.attrDic
end

function DrawPreviewPage:_LoadGongMingInfo()
  local combConf
  local shipCombineLv = 0
  local ship_fleetCfg = configManager.GetDataById("config_ship_fleet", self.m_shipInfoId)
  if ship_fleetCfg and ship_fleetCfg.combination_open == 1 then
    self.m_tabWidgets.obj_gongming:SetActive(true)
    local ship_combinationCfgs = configManager.GetMultiDataByKey("config_combination_ship", "sf_id", self.m_shipInfoId)
    local propBaseTab, propBasePercentTab = Logic.shipCombinationLogic:GetCombAttrTabBySs_id(self.m_shipInfoId)
    combConf = Logic.shipCombinationLogic:GetCombineConfBySs_id(self.m_shipInfoId)
    
    local function showAttrFunc(propBaseTab, propBasePercentTab)
      local propTab = table.append(propBaseTab, propBasePercentTab)
      UIHelper.CreateSubPart(self.m_tabWidgets.obj_propItem, self.m_tabWidgets.trans_propTrans, #propTab, function(index, uiPart)
        local propInfo = propTab[index]
        local value = propInfo[2]
        local valueEffectConf = configManager.GetDataById("config_value_effect", propInfo[1])
        local strValues = valueEffectConf.values
        local strTab = string.split(strValues, ",")
        local attrConf = configManager.GetDataById("config_attribute", tonumber(strTab[1]))
        local propName = attrConf.attr_name
        local attricon = attrConf.attr_icon
        UIHelper.SetText(uiPart.txt_propName, propName)
        UIHelper.SetImage(uiPart.im_icon, attricon)
        if index <= #propBaseTab then
          UIHelper.SetText(uiPart.txt_num, "+" .. value)
        else
          local attrTab = {}
          local percentPropTab = {
            {
              power = value,
              values = valueEffectConf.values
            }
          }
          attrTab = Logic.attrLogic:DisposeAttrBuff(attrTab, percentPropTab)
          if attrConf and attrConf.attr_display ~= "" then
            local params = clone(attrConf.params)
            value = ScriptManager:RunCmd(attrConf.attr_display, params, attrTab)
          end
          UIHelper.SetText(uiPart.txt_num, "+" .. value .. "%")
        end
      end)
    end
    
    local function showSkillFunc(nowStageConf, nextStageConf, combineLv)
      self.m_tabWidgets.sv_skillScrollView.verticalNormalizedPosition = 0
      local lvRange = nowStageConf.level
      local hasBreak = true
      local pSkillId = 0
      local pSkillLv = 0
      pSkillId = nowStageConf.skill_id[1]
      pSkillLv = nowStageConf.skill_id[2]
      local name = Logic.shipLogic:GetPSkillName(pSkillId)
      local desc = Logic.shipLogic:GetPSkillDesc(pSkillId, pSkillLv, false)
      local type = Logic.shipLogic:GetPSkillType(pSkillId)
      local icon = Logic.shipLogic:GetPSkillIcon(pSkillId)
      local color = TalentColor[type]
      UIHelper.SetTextColor(self.m_tabWidgets.tx_skillName, name, color)
      UIHelper.SetImage(self.m_tabWidgets.im_skillIcon, icon)
      UIHelper.SetText(self.m_tabWidgets.tx_skillDesc, desc)
    end
    
    showAttrFunc(propBaseTab, propBasePercentTab)
    showSkillFunc(combConf, nil, MAXCOMBINELV)
  else
    self.m_tabWidgets.obj_gongming:SetActive(false)
  end
end

function DrawPreviewPage:DisposeAttrBuff(attrBuff, heroAttrBuff)
  if heroAttrBuff ~= nil then
    for _, v in pairs(heroAttrBuff) do
      local valueTab = string.split(v.values, "|")
      for _, i in pairs(valueTab) do
        local buff = string.split(i, ",")
        local attr = tonumber(buff[1])
        local value = tonumber(buff[2])
        local propInfo = configManager.GetDataById("config_prop", attr)
        if propInfo.prop_value_type == PERCENT_VALUE then
          value = math.floor(value * PERCENT_BASE)
        end
        value = value * math.floor(v.power)
        if not attrBuff[attr] then
          attrBuff[attr] = value
        else
          attrBuff[attr] = attrBuff[attr] + value
        end
      end
    end
  end
  return attrBuff
end

function DrawPreviewPage:DealAttributeParam(attr)
  local param = {}
  for i, v in pairs(attr) do
    local info = configManager.GetDataById("config_attribute", i)
    if info then
      param[info.id] = info.id
    end
    if info and info.params ~= nil then
      local id = info.id
      for j = 2, #info.params do
        param[info.params[j]] = id
      end
    end
  end
  return param
end

function DrawPreviewPage:DealOtherRelationAttribute(id)
  local relationTab = {}
  local info = configManager.GetDataById("config_attribute", id)
  if info and info.params then
    for i = 1, #info.params do
      if id ~= info.params[i] then
        table.insert(relationTab, info.params[i])
      end
    end
  end
  return relationTab
end

function DrawPreviewPage:_LoadPropertInfo()
  local heroId = self.m_heroId
  local widgets = self:GetWidgets()
  self:_LoadAttrInfo(self.m_ship_MainId)
end

function DrawPreviewPage:_LoadAttrInfo(shipMainId)
  local shipMain = configManager.GetDataById("config_ship_main", self:_ShipMianIdAdd(self.m_ship_MainId))
  local shipInfo = configManager.GetDataById("config_ship_info", shipMain.ship_info_id)
  local tbl = shipInfo.attr_type_show
  local heroAttr = self:GetHeroAttr(MAXSHIPLEVEL, self.m_ship_MainId + 5)
  heroAttr = self:DisposeAttrBuff(heroAttr, self:GetBreakInfo())
  for index = AttrTypeNew.Common, AttrTypeNew.Plane do
    local result = false
    for nIndex = 1, #tbl do
      if index == tbl[nIndex] then
        result = true
      end
    end
    local str = attrStr[index]
    self.m_tabWidgets["obj" .. str]:SetActive(result)
  end
  self.maxPowerArr = self:GetMaxPowerBySmId(self:_ShipMianIdAdd(self.m_ship_MainId))
  for nIndex = 1, #tbl do
    local attrIndex = tbl[nIndex]
    local attrTable = Data.buildShipData:GetAttributeDataByType(attrIndex, shipMain.ship_info_id)
    local str = attrStr[attrIndex]
    UIHelper.CreateSubPart(self.m_tabWidgets["obj_" .. str], self.m_tabWidgets["trans_" .. str], #attrTable, function(nIndexSub, tabPartSub)
      local aType = attrTable[nIndexSub].id
      local tabConfig = attrTable[nIndexSub]
      local name = Logic.attrLogic:GetName(aType, shipMainId)
      UIHelper.SetText(tabPartSub.Tx_prop, name)
      UIHelper.SetImage(tabPartSub.Im_icon, tabConfig.attr_icon)
      local param = tabConfig.beizhu
      local levelup = shipMain[param .. "_levelup"] and (MAXSHIPLEVEL - 1) * shipMain[param .. "_levelup"] or 0
      local maxPower = self:GetShipMaxPowerByAttributeId(aType)
      local rate = 1
      if tabConfig.attr_unit ~= nil then
        if tabConfig.attr_unit == "%" then
          rate = 1
        elseif tabConfig.attr_unit == "\231\167\146" then
          rate = 0.001
        end
      end
      local num = (heroAttr[aType] + maxPower) * rate
      if aType == 27 then
        num = shipMain.speed_show * 0.01
        num = math.floor(num)
      end
      local relation = self:DealOtherRelationAttribute(aType)
      if next(relation) ~= nil then
        for i = 1, #relation do
          if heroAttr[relation[i]] ~= nil then
            num = num + heroAttr[relation[i]]
          end
        end
      end
      num = math.ceil(num)
      if aType == 21 then
        num = configManager.GetDataById("config_battle_range", tonumber(num)).desc
      elseif aType == 62 then
        num = num * 3
      end
      num = num .. tabConfig.attr_unit
      UIHelper.SetText(tabPartSub.Tx_num, num)
      tabPartSub.gameObject:SetActive(aType ~= AttrType.ATTACK_GRADE)
    end)
  end
  local widgets = self:GetWidgets()
  LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_content)
end

function DrawPreviewPage:GetShipMaxPowerByAttributeId(id)
  if self.maxPowerArr then
    return self.maxPowerArr[id] or 0
  end
  return 0
end

function DrawPreviewPage:GetBreakInfo()
  local ret = {}
  local breakInfo = configManager.GetDataById("config_ship_break", self:_ShipMianIdAdd(self.m_ship_MainId))
  for i, v in ipairs(breakInfo.value_effect_id_list) do
    if v ~= 62 and v ~= 63 and v ~= 64 then
      local valueEffect = configManager.GetDataById("config_value_effect", v)
      table.insert(ret, {
        power = breakInfo.value_effect_power_list[i],
        values = valueEffect.values
      })
    end
  end
  return ret
end

function DrawPreviewPage:GetMaxPowerBySmId(shipMianid)
  local maxPowerName = "config_ship_max_power"
  local config = configManager.GetDataById(maxPowerName, shipMianid)
  local attributeCfg = {}
  if config.max_power_prop then
    for i, v in ipairs(config.max_power_prop) do
      attributeCfg[v[1]] = v[2]
    end
  end
  return attributeCfg
end

function DrawPreviewPage:_LoadSkillInfo(pskillArr)
  local widgets = self:GetWidgets()
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local displayArr = {}
  for i, pskillId in ipairs(pskillArr) do
    local displayData = {}
    displayData.pskillId = pskillId
    displayData.heroId = heroId
    local showSkillId = pskillId
    displayData.name = Logic.shipLogic:GetPSkillName(showSkillId)
    displayData.icon = Logic.shipLogic:GetPSkillIcon(showSkillId)
    displayData.lv = MAXSKILLLEVEL
    displayData.desc = Logic.shipLogic:GetPSkillDesc(showSkillId, displayData.lv)
    displayData.type = Logic.shipLogic:GetPSkillType(showSkillId)
    displayData.lock, displayData.lockInfo = false, ""
    displayData.empty = false
    displayArr[i] = displayData
  end
  local colorCache
  UIHelper.CreateSubPart(widgets.obj_pskillItem, widgets.trans_pskillGrid, #displayArr, function(index, part)
    local data = displayArr[index]
    UIHelper.SetText(part.txt_name, data.name)
    colorCache = PskillTypeColorMap[data.type]
    part.txt_name.color = Color.New(colorCache[1] / 255, colorCache[2] / 255, colorCache[3] / 255, 1)
    if data.lv > 0 then
      UIHelper.SetText(part.txt_lv, "Lv." .. math.tointeger(data.lv))
    end
    UIHelper.SetImage(part.img_icon, data.icon)
    local skillId = data.pskillId
    local skillIdReal = skillId
    if type(skillId) == "table" then
      skillIdReal = skillId[1]
    end
    part.obj_lvbg:SetActive(type(skillId) ~= "table")
    UGUIEventListener.AddButtonOnClick(part.btn_click, function()
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenMaxPSkillData(skillId, self.m_ship_MainId))
    end)
  end)
end

function DrawPreviewPage:_ClickAttribute()
end

function DrawPreviewPage:_GetTid(advance, index, tid)
  if index <= advance then
    return tid - (advance - index), true
  else
    return tid + (index - advance), false
  end
end

local GIRL_CharWidth = 640
local GIRL_CharWidthSpace = 9.5

function DrawPreviewPage:_ShowHeroChar(sm_id)
  local widgets = self:GetWidgets()
  local charId, charLv
  local chars, charLvs = Logic.shipLogic:GetHeroCharcater(sm_id)
  local width, height
  local mimaLv = Logic.shipLogic:GetHeroCharcaterMaxLevel(sm_id)
  UIHelper.CreateSubPart(widgets.obj_char, widgets.trans_char, #chars, function(index, tabPart)
    charId, charLv = chars[index], charLvs[index]
    local name = Logic.shipLogic:GetCharacterName(charId)
    local desc = Logic.buildingLogic:GetCharacterAdditionStr(charId, charLv)
    UIHelper.SetText(tabPart.tx_title, name .. "  (Lv." .. charLv .. ")\239\188\154")
    width = GIRL_CharWidth - tabPart.tx_title.preferredWidth - GIRL_CharWidthSpace
    if next(desc) == nil then
      logError("can not find hero char desc,sm_id :" .. sm_id)
    else
      local item = desc[1]
      UIHelper.SetText(tabPart.tx_desc, string.format(UIHelper.GetString(item.strId), item.value))
    end
    tabPart.tx_desc.text = tabPart.tx_desc.text .. "("
    for i = mimaLv[index][1], mimaLv[index][2] do
      local desc1 = Logic.buildingLogic:GetCharacterAdditionStr(charId, i)
      local value = desc1[1].value
      if i <= charLv then
        if i == mimaLv[index][2] then
          tabPart.tx_desc.text = tabPart.tx_desc.text .. value .. "%)"
        else
          tabPart.tx_desc.text = tabPart.tx_desc.text .. value .. "%/"
        end
        tabPart.tx_desc.color = Color.New(0.2549019607843137, 0.48627450980392156, 0.8901960784313725, 1)
      elseif i == mimaLv[index][2] then
        tabPart.tx_desc.text = tabPart.tx_desc.text .. "<color=#74869B>" .. value .. "%)" .. "</color>"
      else
        tabPart.tx_desc.text = tabPart.tx_desc.text .. "<color=#74869B>" .. value .. "%/" .. "</color>"
      end
    end
    height = tabPart.rt_desc.sizeDelta.y
  end)
end

function DrawPreviewPage:ShowMagazineTag()
  local config = configManager.GetDataById("config_ship_main", self.m_ship_MainId)
  local shipInfo = configManager.GetDataById("config_ship_info", config.ship_info_id)
  local tagList = configManager.GetDataById("config_ship_handbook", shipInfo.sf_id).magazine_tag
  UIHelper.CreateSubPart(self.m_tabWidgets.tag, self.m_tabWidgets.content_tag, #tagList, function(index, tabPart)
    local config = configManager.GetDataById("config_magazine_tag", tagList[index])
    UIHelper.SetText(tabPart.tx_tag, config.name)
  end)
end

function DrawPreviewPage:DoOnHide()
  self:_Hide3DModel()
end

return DrawPreviewPage
