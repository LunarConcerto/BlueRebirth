local FashionPage = class("UI.Fashion.FashionPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local gccount = 0
local NumBGImg = {
  [1] = "uipic_ui_fashion_bg_n_di",
  [2] = "uipic_ui_fashion_bg_r_di",
  [3] = "uipic_ui_fashion_bg_sr_di",
  [4] = "uipic_ui_fashion_bg_ssr_di",
  [5] = "uipic_ui_fashion_bg_ur_di"
}
local CheckImg = {
  [1] = "uipic_ui_fashion_bg_zhanshi_n",
  [2] = "uipic_ui_fashion_bg_zhanshi_r",
  [3] = "uipic_ui_fashion_bg_zhanshi_sr",
  [4] = "uipic_ui_fashion_bg_zhanshi_ssr",
  [5] = "uipic_ui_fashion_bg_zhanshi_ur"
}
local GetBtnState = {
  Have = 1,
  Wear = 2,
  DontHave = 3,
  HaveNoHero = 4
}
local GetLanguage = {
  [1] = 910005,
  [2] = 910006
}

function FashionPage:DoInit()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_check, self._OnClickCheck, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_2dto3d, self._OnClick2dTo3d, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OnClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_goto_get, self._OnClickGet, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.img_bg, self._OnClickCancelCheck, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_showorhide, self._OnClickShowDress, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_equipfashion, self._OnClickEquipFashion, self)
  UGUIEventListener.AddOnDrag(self.tab_Widgets.img_bg, self.__OnDrag, self)
  UGUIEventListener.AddOnEndDrag(self.tab_Widgets.img_bg, self.__OnDragEnd, self)
  self.is3D = false
  local key = PlayerPrefs.FormatKey("FashionHideMech")
  self.m_showDress = PlayerPrefs.GetInt(key, 1) == 1
  self:SetDressShowState(self.m_showDress)
  self.tab_Widgets.btn_showorhide.gameObject:SetActive(false)
end

function FashionPage:DoOnOpen()
  self:OpenTopPage("FashionPage", 1, UIHelper.GetString(910017), self, true, nil, {
    {5, 2},
    {5, 1},
    {5, 23}
  })
  self.isPreview = self.param.isPreview
  if self.isPreview then
    local fashionId = self.param.fashionId
    local fashionCfg = Logic.fashionLogic:GetFashionConfig(fashionId)
    self.shipShow = configManager.GetDataById("config_ship_show", fashionCfg.ship_show_id)
    self.fashionId = fashionId
    self.heroId = self.param.heroId
    self.shipInfo = Logic.shipLogic:GetShipInfoBySsId(fashionCfg.ship_show_id)
    if self.heroId then
      self.heroInfo = Data.heroData:GetHeroById(self.heroId)
    else
      self.heroInfo = {
        type = self.shipInfo.ship_type,
        quality = self.shipInfo.quality,
        Advance = 1
      }
    end
    self.itemInfoParams = self.param.itemInfoPageParam
    self.sf_id = fashionCfg.belong_to_ship
  else
    self.heroId = self.param.heroId
    self.heroInfo = Data.heroData:GetHeroById(self.heroId)
    self.shipInfo = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
    self.sf_id = self.shipInfo.sf_id
  end
  self.c_data = Logic.fashionLogic:GetFashionConfigData(self.sf_id)
  self:_RegisterModeBInput()
  self.tab_Widgets.tween_huakuai:SetOnFinished(function()
    UIHelper.SetUILock(false)
  end)
  self:InitShow()
end

function FashionPage:RegisterAllEvent()
  self:RegisterEvent(LuaCSharpEvent.EnhanceIndex, self.ChangeIndex, self)
  self:RegisterEvent(LuaEvent.UpdateFashionInfo, self.UpdateFashionData, self)
  self:RegisterEvent(LuaEvent.WearFashionSuccess, self.WearFashionSuccess, self)
  self:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self.BuyGoodsCallBack, self)
end

function FashionPage:ChangeIndex(index, noEff)
  if self.curIndex ~= index + 1 and not noEff then
    self.tab_Widgets.obj_eff:SetActive(false)
    self.tab_Widgets.obj_eff:SetActive(true)
  end
  self.curIndex = index + 1
  self.curConfig = self.c_data[self.curIndex]
  self.ss_config = configManager.GetDataById("config_ship_show", self.curConfig.ship_show_id)
  self:UpdateModelShow()
  UIHelper.SetImage(self.tab_Widgets.img_get, "uipic_ui_fashion_bu_01")
  self.tab_Widgets.btn_goto_get.gameObject:SetActive(true)
  local isOwn = self:CheckOwn(self.curConfig.id)
  if isOwn then
    if self.heroId then
      if self.curFashion.id == self.curConfig.id then
        self.getBtnState = GetBtnState.Wear
        UIHelper.SetImage(self.tab_Widgets.img_get, "uipic_ui_fashion_bu_02")
        self.tab_Widgets.txt_get.text = configManager.GetDataById("config_language", 910007).content
      else
        self.getBtnState = GetBtnState.Have
        self.tab_Widgets.txt_get.text = configManager.GetDataById("config_language", 910008).content
      end
    else
      self.getBtnState = GetBtnState.HaveNoHero
      self.tab_Widgets.txt_get.text = configManager.GetDataById("config_language", 910008).content
    end
  else
    self.getBtnState = GetBtnState.DontHave
    if self.curConfig.get_type == -1 then
      self.tab_Widgets.btn_goto_get.gameObject:SetActive(false)
    else
      self.tab_Widgets.txt_get.text = configManager.GetDataById("config_language", self.curConfig.get_language_id).content
    end
  end
  self.tab_Widgets.txt_nohero.gameObject:SetActive(self.heroId == nil)
end

function FashionPage:InitShow()
  UIHelper.SetImage(self.tab_Widgets.img_icon_type, NewCardShipTypeImg[self.heroInfo.type])
  UIHelper.SetImage(self.tab_Widgets.img_bg, FashionQualityImg[self.heroInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.img_num, NumBGImg[self.heroInfo.quality])
  self:Create3DShow()
  local shipName = ""
  if self.isPreview then
    shipName = self.shipInfo.ship_name
  else
    shipName = self.heroInfo.Name ~= "" and self.heroInfo.Name or Logic.shipLogic:GetName(self.shipInfo.si_id)
  end
  self.tab_Widgets.txt_name.text = shipName
  UIHelper.CreateSubPart(self.tab_Widgets.obj_star, self.tab_Widgets.tran_starbase, self.heroInfo.Advance)
  self:UpdateFashionData()
end

function FashionPage:SetGirlInfo(ss_config)
  local shipPosConf = configManager.GetDataById("config_ship_position", ss_config.ss_id)
  local position = shipPosConf.fashion_position1
  self.tab_Widgets.img_2dgirl.transform.localPosition = Vector3.New(position[1], position[2], 0)
  local scaleSize = shipPosConf.fashion_scale1 / 10000
  local mirror = shipPosConf.fashion_inversion1
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  self.tab_Widgets.img_2dgirl.transform.localScale = scale
  self.position = position
  self.scale = scale
end

function FashionPage:WearFashionSuccess()
  noticeManager:ShowTip(UIHelper.GetString(910014))
  self:UpdateFashionData()
end

function FashionPage:UpdateFashionData()
  self.ownFashion = Logic.fashionLogic:GetOwnFashionByHeroId(self.sf_id, self.heroId)
  if self.heroId then
    self.curFashion = Logic.fashionLogic:GetCurFashionData(self.heroId)
  else
    self.curFashion = Logic.fashionLogic:GetFashionConfig(self.fashionId)
  end
  self.tab_Widgets.txt_num.text = table.nums(self.ownFashion) .. "/" .. #self.c_data
  self.ss_config = configManager.GetDataById("config_ship_show", self.curFashion.ship_show_id)
  self:UpdateCard()
end

function FashionPage:CheckOwn(id)
  if self.ownFashion[id] then
    return true
  else
    return false
  end
end

function FashionPage:UpdateCard()
  if self.tab_cards then
    for i = 1, #self.tab_cards do
      self:UpdateCardInfo(i, self.tab_cards[i])
    end
  else
    self:LoadCard()
  end
  self:ChangeIndex(self.curIndex - 1, true)
end

function FashionPage:UpdateCardInfo(index, tabPart)
  local cfg = self.c_data[index]
  tabPart.txt_name.text = cfg.name
  UIHelper.SetImage(tabPart.im_clothes_icon, cfg.icon)
  UIHelper.SetImage(tabPart.im_clothes_name, CardFashionNameImg[cfg.quality_show])
  UIHelper.SetImage(tabPart.im_clothes_quality, CardFashionTypeImg[cfg.quality_show])
  if self:CheckOwn(cfg.id) then
    tabPart.obj_locked:SetActive(false)
  else
    tabPart.obj_locked:SetActive(true)
    tabPart.txt_locked.text = cfg.limit_tip
  end
  local fashionTabId = configManager.GetDataById("config_fashion", cfg.id).skill_fashion_id
  self.tab_Widgets.btn_equipfashion.gameObject:SetActive(self.isPreview == nil)
  tabPart.btn_equipfashion.gameObject:SetActive(fashionTabId ~= nil and #fashionTabId ~= 0)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_equipfashion, self._ClickFashionEffect, self, cfg)
end

function FashionPage:_ClickFashionEffect(go, cfg)
  UIHelper.OpenPage("EquipFashionShowPage", cfg.id)
end

function FashionPage:LoadCard()
  self.tab_cards = {}
  self.tab_Widgets.trans_clothes:Clear()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_clothesItem, self.tab_Widgets.trans_clothes.gameObject.transform, #self.c_data, function(index, tabPart)
    self:UpdateCardInfo(index, tabPart)
    if self.isPreview then
      if self.fashionId == self.c_data[index].id then
        self.curIndex = index
      end
    elseif self.curFashion.id == self.c_data[index].id then
      self.curIndex = index
    end
    self.tab_cards[index] = tabPart
  end)
  for i = 1, #self.tab_cards do
    self.tab_Widgets.trans_clothes:AddItem(self.tab_cards[i].gameObject)
  end
  self.tab_Widgets.trans_clothes:Enable(self.curIndex - 1)
end

function FashionPage:SetDressShowState(isShow)
  self.tab_Widgets.obj_hide:SetActive(isShow)
  self.tab_Widgets.obj_show:SetActive(not isShow)
  if self.is3D then
    self.m_objModel:HideMech(isShow)
  end
end

function FashionPage:__OnDrag(go, eventData)
  self.m_isDrag = true
  if self.is3D then
    self:__On3DDrag(go, eventData)
  elseif self.m_isCheck then
    self:__On2DDragCheck(go, eventData)
  end
  self:__CheckGC()
end

function FashionPage:__On2DDragCheck(go, eventData)
  Logic.girlInfoLogic:GirlDrag2D(go, eventData, self.tab_Widgets.img_2dgirl.transform)
end

function FashionPage:__On3DDrag(go, eventData)
  local delta = eventData.delta
  if self.m_objModel == nil then
    return
  end
  local targetTran = self.m_objModel:Get3dObj().transform
  local angles = targetTran.localEulerAngles
  angles.y = angles.y - delta.x
  targetTran.localEulerAngles = angles
end

function FashionPage:__OnDragEnd()
  self.m_isDrag = false
end

function FashionPage:__CheckGC()
  gccount = gccount + 1
  if 20 < gccount then
    gccount = 0
    collectgarbage("collect")
  end
end

function FashionPage:_RegisterModeBInput()
  local tabParam = {
    zoom = function(param)
      self:_OnModeBZoom(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function FashionPage:_OnModeBZoom(delta)
  if not self.m_isCheck or self.is3D then
    return
  end
  Logic.girlInfoLogic:GirlPinch2D(delta, self.tab_Widgets.img_2dgirl.transform, self.curConfig.ship_show_id)
end

function FashionPage:_OnClickShowDress()
  self.m_showDress = not self.m_showDress
  self:SetDressShowState(self.m_showDress)
end

function FashionPage:_OnClickCancelCheck()
  if self.m_isDrag then
    return
  end
  if self.m_isCheck and not self.m_isTween then
    self.m_isCheck = false
    self.tab_Widgets.obj_common:SetActive(true)
    self:SetTopVisibleByPos(true)
    UIHelper.SetImage(self.tab_Widgets.img_bg, FashionQualityImg[self.heroInfo.quality])
    if self.is3D then
      self.m_objModel:ResetEulerAngels()
      self:__ResetModelPos()
      self.m_objModel:SetBackgroundTex(self.tab_Widgets.img_bg.mainTexture)
    else
      local grilTrans = self.tab_Widgets.img_2dgirl.transform
      grilTrans.localPosition = Vector3.New(self.position[1], self.position[2], 0)
      grilTrans.localScale = self.scale
    end
  end
end

function FashionPage:_OnClickCheck()
  if not self.m_isCheck then
    self.m_isCheck = true
    self.tab_Widgets.obj_common:SetActive(false)
    self:SetTopVisibleByPos(false)
    self.m_isTween = true
    UIHelper.SetImage(self.tab_Widgets.img_bg, CheckImg[self.heroInfo.quality])
    if self.is3D then
      local modelObj = self.m_objModel:Get3dObj()
      self.m_objModel:SetBackgroundTex(self.tab_Widgets.img_bg.mainTexture)
      local seq = UISequence.NewSequence(modelObj.gameObject)
      seq:Join(modelObj.transform:TweenLocalMoveX(self.modelStartPos, self.modelCheckPos, 0.4))
      seq:AppendCallback(function()
        self.m_isTween = false
      end)
      seq:ResetToBeginning()
      seq:Play(true)
    else
      UIHelper.SetImage(self.tab_Widgets.img_bg, CheckImg[self.heroInfo.quality])
      local shipPosConf = configManager.GetDataById("config_ship_position", self.curConfig.ship_show_id)
      local tween_2dgirl = self.tab_Widgets.tween_2dgirl
      local grilTrans = self.tab_Widgets.img_2dgirl.transform
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
  end
end

function FashionPage:_OnClickGet()
  if self.getBtnState == GetBtnState.Have then
    self:WearFashion(self.curConfig.id)
  elseif self.getBtnState == GetBtnState.DontHave then
    self:JumpFunc(self.curConfig)
  elseif self.getBtnState == GetBtnState.HaveNoHero then
    noticeManager:ShowTip(UIHelper.GetString(910010))
    return false
  end
end

function FashionPage:JumpFunc(config)
  if config.get_type == 2 then
    if config.get_id == FunctionID.Remould then
      moduleManager:JumpToFunc(config.get_id, self.heroId)
    else
      moduleManager:JumpToFunc(config.get_id, config.get_p1)
    end
  elseif config.get_type == 1 then
    local buyParams, errMsg = Logic.shopLogic:GetFashionBuyParams(self.curConfig.id)
    if errMsg ~= nil then
      noticeManager:ShowTip(errMsg)
      return
    end
    local param = ItemInfoPage:GenFashionData(buyParams.shopId, buyParams.buyNum, buyParams.fashionCfg, buyParams.goodsCfg, buyParams.gridId, false)
    UIHelper.OpenPage("ItemInfoPage", param)
  end
end

function FashionPage:WearFashion(fashionId)
  Service.fashionService:EquipFashion(fashionId, 1, self.heroId)
end

function FashionPage:_OnClickHelp()
  UIHelper.OpenPage("HelpPage", {
    content = UIHelper.GetString(910001)
  })
end

function FashionPage:_OnClick2dTo3d()
  self.is3D = not self.is3D
  self.tab_Widgets.btn_showorhide.gameObject:SetActive(self.is3D)
  self.tab_Widgets.obj_eff:SetActive(false)
  self.tab_Widgets.obj_eff:SetActive(true)
  UIHelper.SetUILock(true)
  self:UpdateModelShow()
end

function FashionPage:UpdateModelShow()
  self.tab_Widgets.tween_huakuai:Play(self.is3D)
  self.tab_Widgets.img_bg.color = Color.New(255, 255, 255, self.is3D and 0 or 255)
  self.tab_Widgets.img_2dgirl.gameObject:SetActive(not self.is3D)
  self:SetGirlInfo(self.ss_config)
  if self.is3D then
    local param = {
      showID = self.curConfig.ship_show_id
    }
    if self:__CheckModelChange(param) then
      self:__ChangeModelShow(param)
    end
    self:__ResetModelPos()
    self.m_objModel:HideMech(self.m_showDress)
    self.m_objModel:SetBackgroundTex(self.tab_Widgets.img_bg.mainTexture)
  else
    UIHelper.SetImage(self.tab_Widgets.img_2dgirl, self.ss_config.ship_draw)
  end
  if self.m_objModel then
    self.m_objModel:setCameraEnable(self.is3D)
  end
end

function FashionPage:__CheckModelChange(param)
  if self.lastModelParam == nil then
    self.lastModelParam = param
    return true
  else
    local isOn = self.lastModelParam.showID ~= param.showID
    self.lastModelParam = param
    return isOn
  end
end

function FashionPage:__ChangeModelShow(param)
  if self.m_objModel:Get3dObj() == nil then
    local objModel = self.m_objModel
    objModel:ChangeObj(param)
    objModel:ApplyCameraParam(CamDataType.Detaile)
    local camera = objModel.m_camera
    local size = camera.orthographicSize
    local hu = UIManager:GetUIHeight() / 2
    self.modelStartPos = -size / hu * self.tab_Widgets.trans_3DStart.localPosition.x
    self.modelCheckPos = -size / hu * self.tab_Widgets.trans_3DCheck.localPosition.x
  else
    local sm_config = configManager.GetDataById("config_ship_model", self.ss_config.model_id)
    local dressUpid = sm_config.standard_normal
    if self.ss_config.model_id == self.modelRes then
      self.m_objModel:DressUp(dressUpid)
    else
      self.m_objModel:ChangeObj(param)
    end
  end
  self.modelRes = self.ss_config.model_id
end

function FashionPage:BuyGoodsCallBack(param)
  local isFashion, ssIdTab, fashionTabId = Logic.rewardLogic:_CheckFashionInReward(param.Reward)
  if isFashion then
    local dotInfo = {info = "shop_buy", fashion_id = fashionTabId}
    RetentionHelper.Retention(PlatformDotType.fashionGetLog, dotInfo)
  end
  Logic.rewardLogic:ShowFashion({
    rewards = param.Reward
  })
end

function FashionPage:__ResetModelPos()
  local trans = self.m_objModel:Get3dObj().transform
  local pos = trans.position
  trans.position = Vector3.New(self.modelStartPos, pos.y, pos.z)
end

function FashionPage:Create3DShow()
  local rct = self.tab_Widgets.img_bg:GetComponent(RectTransform.GetClassType())
  local dx = rct.sizeDelta.x / UIManager:GetUIWidth()
  local dy = rct.sizeDelta.y / UIManager:GetUIHeight()
  self.m_objModel = UIHelper.Create3DModelNoRT(nil, CamDataType.Detaile, false, self.tab_Widgets.img_bg.mainTexture, dx, dy)
end

function FashionPage:_OnClickEquipFashion()
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  local param = {
    heroId = self.heroId,
    fashionId = self.curConfig.id
  }
  UIHelper.OpenPage("EquipFashionPage", param)
end

function FashionPage:DoOnHide()
  inputManager:UnregisterAllInput(self)
  local key = PlayerPrefs.FormatKey("FashionHideMech")
  local value = self.m_showDress and 1 or 0
  PlayerPrefs.SetInt(key, value)
  PlayerPrefs.Save()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.lastModelParam = nil
    self.m_objModel = nil
  end
end

function FashionPage:DoOnClose()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.lastModelParam = nil
    self.m_objModel = nil
  end
end

return FashionPage
