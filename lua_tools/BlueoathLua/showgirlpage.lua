ShowGirlPage = class("UI.Settlement.ShowGirlPage", LuaUIPage)
local QualitySprite = {
  [HeroRarityType.N] = "obj_N",
  [HeroRarityType.R] = "obj_R",
  [HeroRarityType.SR] = "obj_SR",
  [HeroRarityType.SSR] = "obj_SSR",
  [HeroRarityType.UR] = "obj_UR"
}
local modelQualityBg = {
  "uipic_ui_common_bg_baisepinzhi",
  "uipic_ui_common_bg_lansepinzhi",
  "uipic_ui_common_bg_zisepinzhi",
  "uipic_ui_common_bg_jinsepinzhi",
  "uipic_ui_common_bg_caisepinzhi"
}
local Content = {txt_remould = "\230\148\185%s"}
local HeroTypeKind = {
  [HeroIndexType.Destroyer] = "uipic_ui_common_im_quzhu_da",
  [HeroIndexType.LightCruiser] = "uipic_ui_common_im_qingxun_da",
  [HeroIndexType.HeavyCruiser] = "uipic_ui_common_im_zhongxun_da",
  [HeroIndexType.Battlecruiser] = "uipic_ui_common_im_zhanlie_da",
  [HeroIndexType.Battleship] = "uipic_ui_common_im_zhanlie_da",
  [HeroIndexType.HeavyAircraftCarrier] = "uipic_ui_common_im_hangmu_da"
}
local BGTexPath = {
  [HeroRarityType.N] = "uipic_ui_getship_bg_n",
  [HeroRarityType.R] = "uipic_ui_getship_bg_r",
  [HeroRarityType.SR] = "uipic_ui_getship_bg_sr",
  [HeroRarityType.SSR] = "uipic_ui_getship_bg_ssr",
  [HeroRarityType.UR] = "uipic_ui_getship_bg_ur"
}
local BUILD_ONE = 1
local spEffectTab = {
  [13000] = "effects/prefabs/ui/eff2d_item_shine01",
  [110003] = "effects/prefabs/ui/eff2d_item_shine02"
}
local showFashionBg = {
  "uipic_ui_fashion_bg_zhanshi_n",
  "uipic_ui_fashion_bg_zhanshi_r",
  "uipic_ui_fashion_bg_zhanshi_sr",
  "uipic_ui_fashion_bg_zhanshi_ssr",
  "uipic_ui_fashion_bg_zhanshi_ur"
}

function ShowGirlPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.quality = 0
  self.bNew = false
  self.girlId = 0
  self.m_model = nil
  self.index = 0
  self.textContent = {}
  self.girlObj = nil
  self.skip3d = 0
  self.effTab = {
    {
      "obj_eff_ui_chouka_shan_01",
      "obj_eff_ui_chouka_shan_02"
    },
    {
      "obj_eff_ui_chouka_shan_03",
      "obj_eff_ui_chouka_shan_04"
    },
    {
      "obj_eff_ui_chouka_shan_05",
      "obj_eff_ui_chouka_shan_06"
    },
    {
      "obj_eff_ui_chouka_shan_07",
      "obj_eff_ui_chouka_shan_08"
    },
    {
      "obj_eff_ui_chouka_shan_09",
      "obj_eff_ui_chouka_shan_08"
    }
  }
  self.showNum = 1
  self.m_tabWidgets.btn_share.gameObject:SetActive(platformManager:ShowShare())
  self.bBattleOpen = false
  self.spEffObj = {}
  self.showType = ShowGirlType.Girl
end

function ShowGirlPage:DoOnOpen()
  SoundManager.Instance:PlayMusic("Role_unlock")
  self:_UpdatePage()
end

function ShowGirlPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_back, self.OnClickBack, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_next, self.OnClickNext, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_lock, self.OnClickLock, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_modelNext, self._OpenGirlImage, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_share, self.OnClickShare, self)
  self:RegisterEvent(LuaEvent.SendHeroLock, self._HeroClockCallBack)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, function(self, notification)
    self:_ShowSubtitle(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowGirlEffect, function(self, notification)
    self:_ShowEffect(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowGirlStopAction, function(self, notification)
    self:_StopPlayAction(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowGirlContinueAction, function(self)
    self:_ContinuePlayAction()
  end)
  self:RegisterEvent(LuaEvent.ShareOver, self._SetShareShow, self)
end

function ShowGirlPage:_UpdatePage()
  self.showType = self.param.showType ~= nil and self.param.showType or ShowGirlType.Girl
  if self.showType == ShowGirlType.Girl then
    if type(self.param.girlId) == "table" then
      self.girlId = self.param.girlId[self.showNum]
      self.heroId = self.param.HeroId[self.showNum]
      if self.girlId == nil then
        if self.param.getWay == GetGirlWay.plot then
          self:_ClosePage()
        else
          self:_BackPage()
        end
        return
      end
    else
      self.girlId = self.param.girlId
      self.heroId = self.param.HeroId
    end
    if self.heroId and self.heroId > 0 then
      self.girlSsId = Logic.shipLogic:GetShipShowByHeroId(self.heroId).ss_id
    else
      self.girlSsId = Logic.shipLogic:GetShipShowByInfoId(self.girlId).ss_id
    end
  else
    self.girlSsId = self.param.girlId[self.showNum]
    if self.girlSsId == nil then
      self:_BackPage()
      return
    end
  end
  self.spReward = self:_EditReawrdParam(self.param.spReward)
  self.transReward = self:_EditReawrdParam(self.param.transReward)
  if self.showType == ShowGirlType.Fashion then
    self.replaceReward = self:_EditReawrdParam(Data.fashionData:GetFashionReplaceReward().ReplaceReward)
  end
  if self.showType == ShowGirlType.Fashion then
    self.spReward = self.replaceReward
  end
  if self.param.battleOpen == nil then
  end
  self.bBattleOpen = self.param.battleOpen
  if self.showType == ShowGirlType.Girl then
    self.bNew = Logic.illustrateLogic:IsFirstGetHero(self.girlId)
    self.quality = Logic.shipLogic:GetQuality(self.girlId)
  else
    self.bNew = true
    self.quality = Logic.shipLogic:GetQualityByShowId(self.girlSsId)
  end
  if self.param.getWay == GetGirlWay.build and self.param.buildNum == BUILD_ONE or self.param.getWay == GetGirlWay.plot then
    self:_SetGirlModel(self.girlSsId)
  elseif self.bNew or self.quality == HeroRarityType.SR or self.quality == HeroRarityType.SSR then
    self:_SetGirlModel(self.girlSsId)
  else
    self:_SetGirlImage(self.girlSsId)
  end
  self:GetWidgets().btn_lock.gameObject:SetActive(self.heroId ~= nil and self.heroId > 0)
  if self.param.getWay ~= nil then
    local name = Logic.shipLogic:GetRealName(self.heroId)
    RetentionHelper.Retention(PlatformDotType.getLog, {
      info = self.param.getWay,
      ship_name = name
    })
  end
  if self.param.getWay == GetGirlWay.girl then
    local nameGirl = Logic.shipLogic:GetRealName(self.heroId)
    RetentionHelper.Retention(PlatformDotType.uilog, {
      info = "ui_formulabuild_get",
      ship_name = nameGirl,
      cost_num = self.param.formula
    })
  end
end

function ShowGirlPage:_EditReawrdParam(rewardParam)
  local reward
  if rewardParam ~= nil and next(rewardParam) ~= nil then
    if type(self.param.girlId) == "table" then
      reward = rewardParam[self.showNum].Reward
    else
      reward = rewardParam
    end
  end
  return reward
end

function ShowGirlPage:_ShowEffect(mType)
  mType = tonumber(mType)
  local effectObj = self.effTab[self.quality][mType]
  if effectObj ~= nil then
    self.m_tabWidgets[effectObj]:SetActive(true)
    SoundManager.Instance:PlayAudio("Effect_zhaomu_flash")
  end
end

function ShowGirlPage:_StopPlayAction(duration)
  if self.girlObj == nil then
    return
  end
  self.girlObj:PauseBehaviour()
  if duration ~= 0 then
    local m_timer = self:CreateTimer(function()
      self:_ContinuePlayAction()
    end, duration, 1, false)
    self:StartTimer(m_timer)
  end
end

function ShowGirlPage:_ContinuePlayAction()
  self:StopTimer()
  if self.girlObj == nil then
    return
  end
  self.girlObj:ContinueBehaviour()
end

function ShowGirlPage:_ShowSubtitle(textContent)
  if self.showType == ShowGirlType.Fashion then
    UIHelper.SetText(self.m_tabWidgets.txt_fashionContent, textContent)
  else
    self:GetWorldNum(textContent)
    local textShowContent = utf8.sub(textContent, 1, self.worldNum + 1)
    UIHelper.SetText(self.m_tabWidgets.txt_content, textShowContent)
    self.textContent = textContent
  end
end

function ShowGirlPage:DoOnHide()
  self:_ClearModel()
end

function ShowGirlPage:DoOnClose()
  self:_ClearModel()
  self:StopTimer()
  SectionBehaviourMsg:DestoryBehaviour()
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
end

function ShowGirlPage:_SetGirlModel(id)
  local widgets = self:GetWidgets()
  widgets.obj_shipModel:SetActive(true)
  widgets.btn_back.gameObject:SetActive(false)
  widgets.img_showModel.enabled = false
  if self.showType == ShowGirlType.Girl then
    UIHelper.SetImage(widgets.img_showModel, modelQualityBg[self.quality])
  else
    UIHelper.SetImage(widgets.img_showModel, showFashionBg[self.quality])
  end
  local createParam = {showID = id}
  self.m_model = UIHelper.Create3DModelNoRT(createParam, CamDataType.Detaile, self.bBattleOpen, self.m_tabWidgets.img_showModel.mainTexture)
  if self.bBattleOpen then
    self.m_model.m_camera.depth = 1
  end
  widgets.raw_girl.gameObject:SetActive(false)
  self.girlObj = self.m_model:Get3dObj()
  self.girlObj:playBehaviour("get_3d", false, function()
    self:_SetGirlImage(id)
    self:_ClearModel()
  end)
end

function ShowGirlPage:_ClearModel()
  local widgets = self:GetWidgets()
  if self.m_model ~= nil then
    self:StopTimer()
    if self.bBattleOpen then
      self.m_model.m_camera.depth = 0
    end
    UIHelper.Close3DModel(self.m_model)
    widgets.img_showModel.gameObject:SetActive(false)
    widgets.raw_girl.gameObject:SetActive(false)
    self.girlObj = nil
    local dotInfo = {
      info = "ui_explore_meet",
      type = self.skip3d
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
    self.skip3d = 0
    self.m_model = nil
  end
end

function ShowGirlPage:_SetGirlImage(id)
  local widgets = self:GetWidgets()
  widgets.obj_content:SetActive(false)
  widgets.obj_fashion:SetActive(false)
  widgets.obj_shipModel:SetActive(false)
  widgets.btn_back.gameObject:SetActive(true)
  widgets.img_new.gameObject:SetActive(self.bNew)
  local position = configManager.GetDataById("config_ship_position", self.girlSsId)
  local grilTrans = widgets.img_picture.transform
  local scaleSize = position.ship_scale3 / 10000
  local mirror = position.ship_inversion3
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = scale
  widgets.tween_girl.from = Vector3.New(1000, position.ship_position3[2], 0)
  widgets.tween_girl.to = Vector3.New(position.ship_position3[1], position.ship_position3[2], 0)
  txtIcon = configManager.GetDataById("config_ship_show", id).ship_draw
  UIHelper.SetImage(widgets.img_picture, txtIcon, false)
  if self.showType == ShowGirlType.Girl then
    widgets.obj_talk:SetActive(true)
    self:SetQuality()
    self:SetTalkContent()
    self:_SetBaseInfo()
    self:_SetLock()
  else
    self:SetFashionTalk()
    self:SetFashionInfo()
  end
  widgets.tween_girl:SetOnFinished(function()
    widgets.obj_fashion:SetActive(self.showType == ShowGirlType.Fashion)
    widgets.obj_content:SetActive(self.showType == ShowGirlType.Girl)
  end)
  widgets.tween_girl:Play()
  if self.param.getWay == GetGirlWay.build and self.quality == HeroRarityType.SSR then
    UIHelper.VibrateTrigger()
  end
  self:ShowSpReward()
  self:ShowTransReward()
end

function ShowGirlPage:SetFashionInfo()
  local widgets = self:GetWidgets()
  UIHelper.SetImage(widgets.img_bg, showFashionBg[self.quality])
  local fashionId = self.param.fashionTab[self.showNum]
  local fashionConfig = Logic.fashionLogic:GetFashionConfig(fashionId)
  local color = self.quality == 3 and "48a2ff" or "ff7599"
  UIHelper.SetTextColor(widgets.tx_fashionName, fashionConfig.name, color)
  local siConfig = Logic.shipLogic:GetShipInfoBySsId(self.girlSsId)
  UIHelper.SetText(widgets.tx_fShipName, siConfig.ship_name)
  local heroInfo = Data.heroData:GetHeroBySfId(siConfig.sf_id)
  widgets.obj_fNoHero:SetActive(heroInfo == nil)
end

function ShowGirlPage:SetTalkContent()
  local widgets = self:GetWidgets()
  local model = Logic.shipLogic:GetHeroModelPath(self.girlSsId)
  local action = "get"
  SectionBehaviourMsg:PlayCVSubtitle(model, "CV_" .. action .. "_" .. model, "zm_" .. action .. "_" .. model)
end

function ShowGirlPage:SetQuality()
  local widgets = self:GetWidgets()
  for k, v in pairs(QualitySprite) do
    widgets[v]:SetActive(self.quality == k)
  end
  UIHelper.SetImage(widgets.img_bg, BGTexPath[self.quality])
end

function ShowGirlPage:ShowSpReward()
  if self.spReward == nil then
    return
  end
  local rewardTips = UIHelper.GetString(910012)
  if self.showType == ShowGirlType.Fashion then
    rewardTips = UIHelper.GetString(910013)
  end
  local widgets = self:GetWidgets()
  widgets.trans_spReward.gameObject:SetActive(true)
  UIHelper.CreateSubPart(widgets.obj_spReward, widgets.trans_spReward, #self.spReward, function(index, tabPart)
    local rewardInfo = self.spReward[index]
    local displayInfo = Logic.goodsLogic.AnalyGoods(rewardInfo)
    UIHelper.SetImage(tabPart.imgIcon, displayInfo.texIcon)
    if spEffectTab[displayInfo.ConfigId] ~= nil then
      local effPath = spEffectTab[displayInfo.ConfigId]
      local eff = self:CreateUIEffect(effPath, tabPart.trans_eff)
      table.insert(self.spEffObj, eff)
    end
    tabPart.textName.text = displayInfo.name
    tabPart.textNum.text = rewardInfo.Num
    tabPart.txt_tips.text = rewardTips
  end)
end

function ShowGirlPage:ShowTransReward()
  if self.transReward == nil or #self.transReward == 0 then
    return
  end
  local name = Logic.shipLogic:GetRealName(self.heroId)
  local msg = string.format(UIHelper.GetString(1110022), "<color=#" .. ShipQualityColor[self.quality] .. ">" .. name .. "</color>")
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = self.transReward,
    Desc = msg
  })
end

function ShowGirlPage:ShowFashionReplaceReward()
  if self.replaceReward == nil or #self.replaceReward == 0 then
    self:_ClickClose()
    return
  end
  self.param.callback = nil
  local fashionId = self.param.fashionTab[self.showNum]
  local name = Logic.fashionLogic:GetFashionConfig(fashionId).name
  local msg = string.format(UIHelper.GetString(910011), "<color=#" .. ShipQualityColor[self.quality] .. ">" .. name .. "</color>")
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = self.replaceReward,
    Desc = msg,
    callBack = function()
      self:_ClickClose()
    end
  })
end

function ShowGirlPage:_SetBaseInfo()
  local widgets = self:GetWidgets()
  widgets.txt_name.text = Logic.shipLogic:GetName(self.girlId)
  widgets.txt_nameShu.text = Logic.shipLogic:GetName(self.girlId)
  widgets.txt_kind.text = HeroTypeContent[Logic.shipLogic:GetHeroType(self.girlSsId)]
  UIHelper.SetImage(widgets.img_kind, HeroTypeKind[Logic.shipLogic:GetHeroType(self.girlSsId)])
  local remouldTimes = self.showType == ShowGirlType.Girl and Logic.shipLogic:GetRemouldTimes(self.girlId) or 0
  widgets.txt_remould.text = string.format(Content.txt_remould, remouldTimes)
  widgets.txt_remould.gameObject:SetActive(remouldTimes ~= 0)
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.NEW_GIRL)
end

function ShowGirlPage:_SetLock()
  local widgets = self:GetWidgets()
  if self.heroId ~= nil then
    local isLock = Logic.shipLogic:IsLock(self.heroId)
    UIHelper.SetImage(widgets.im_lock, LockGirlStatus[isLock])
  end
end

function ShowGirlPage:_OpenGirlImage()
  self.skip3d = 1
  self.girlObj:ContinueBehaviour()
  self:_SetGirlImage(self.girlSsId)
  self:_ClearModel()
end

function ShowGirlPage:OnClickBack()
  if self.heroId ~= nil then
    local quality = Logic.shipLogic:GetQuality(self.girlId)
    local isLock = Logic.shipLogic:IsLock(self.heroId)
    if not isLock and (self.bNew or quality >= HeroRarityType.SR) then
      local tabParam = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          self:_ClickCall(bool)
        end
      }
      noticeManager:ShowMsgBox(310002, tabParam)
      return
    end
  elseif self.showType == ShowGirlType.Fashion then
    self:ShowFashionReplaceReward()
    return
  end
  self:_ClickClose()
end

function ShowGirlPage:OnClickNext(...)
  if (utf8.len(self.textContent) - self.index * self.worldNum) / self.worldNum > 1 then
    self.index = self.index + 1
  else
    self.index = 0
  end
  local textShowContent = utf8.sub(self.textContent, self.index * self.worldNum + 1, self.index * self.worldNum + (self.worldNum + 1))
  UIHelper.SetText(self.m_tabWidgets.txt_content, textShowContent)
end

function ShowGirlPage:_ClickCall(bool)
  if bool then
    self:_ClickOKLock()
  end
  self:_ClickClose()
end

function ShowGirlPage:_ClickOKLock()
  Logic.shipLogic:SendHeroLockByType(self.heroId, true, self)
end

function ShowGirlPage:_ClickCancelFun()
  if self.param.getWay == GetGirlWay.plot then
    self:_ClosePage()
  else
    self:_BackPage()
  end
  if self.param.getWay ~= GetGirlWay.plot then
    eventManager:SendEvent(LuaEvent.ShowGirlEnd)
  end
end

function ShowGirlPage:_ClickClose()
  self.showNum = self.showNum + 1
  if type(self.param.girlId) == "table" then
    self:StopTimer()
    SectionBehaviourMsg:DestoryBehaviour()
    self:_UpdatePage()
  elseif self.param.getWay == GetGirlWay.plot then
    self:_ClosePage()
  else
    self:_BackPage()
  end
  if self.param.getWay ~= GetGirlWay.plot then
    eventManager:SendEvent(LuaEvent.ShowGirlEnd)
  end
  for _, effobj in ipairs(self.spEffObj) do
    self:DestroyEffect(effobj)
  end
end

function ShowGirlPage:OnClickShare()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function ShowGirlPage:OnClickLock()
  local widgets = self:GetWidgets()
  if self.heroId ~= nil then
    local shipInfo = Data.heroData:GetHeroById(self.heroId)
    Logic.shipLogic:SendHeroLockByType(self.heroId, not shipInfo.Lock, self)
  end
end

function ShowGirlPage:_HeroClockCallBack(param)
  local widgets = self:GetWidgets()
  local shipInfo = Data.heroData:GetHeroById(self.heroId)
  UIHelper.SetImage(widgets.im_lock, LockGirlStatus[shipInfo.Lock])
  local shipInfoPara = Data.heroData:GetHeroById(param.HeroId)
  local m_quality = Logic.shipLogic:GetQualityByHeroId(param.HeroId)
  local shipColor = ShipQualityColor[m_quality]
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(param.HeroId)
  local str = string.format(LockTipInfo[shipInfoPara.Lock], shipColor, shipConfig.ship_name)
  noticeManager:OpenTipPage(self, str)
end

function ShowGirlPage:GetWorldNum(str)
  local allWidth = 860
  local fontSize = 26
  local width = 0
  local worldNum = 0
  local lenInByte = #str
  local i = 1
  while i < lenInByte + 1 do
    worldNum = worldNum + 1
    local curByte = string.byte(str, i)
    local szType
    local byteCount = 1
    if 0 < curByte and curByte <= 127 then
      if curByte == 10 then
        if allWidth >= width then
          width = allWidth
        else
          width = allWidth * 2
        end
      end
      byteCount = 1
    elseif 192 <= curByte and curByte <= 223 then
      byteCount = 2
    elseif 224 <= curByte and curByte <= 239 then
      byteCount = 3
    elseif 240 <= curByte and curByte <= 247 then
      byteCount = 4
    end
    local char = string.sub(str, i, i + byteCount - 1)
    i = i + byteCount
    if byteCount == 1 then
      width = width + fontSize * 0.5
    else
      width = width + fontSize
    end
    if width >= allWidth * 2 then
      break
    end
  end
  self.worldNum = worldNum
end

function ShowGirlPage:_SetShareShow()
  self:ShareComponentShow(true)
  local widgets = self:GetWidgets()
  local ssConfig = Logic.shipLogic:GetShipShowConfig(self.girlSsId)
  local heroInfo = Data.heroData:GetHeroBySfId(ssConfig.sf_id)
  widgets.obj_fNoHero:SetActive(heroInfo == nil)
end

function ShowGirlPage:_BackPage()
  local callback = self.param.callback
  self.param.callback = nil
  UIHelper.Back()
  if callback then
    callback()
  end
end

function ShowGirlPage:_ClosePage()
  local callback = self.param.callback
  self.param.callback = nil
  UIHelper.ClosePage("ShowGirlPage")
  if callback then
    callback()
  end
end

function ShowGirlPage:SetFashionTalk()
  self.m_tabWidgets.txt_fashionContent.text = ""
  local fashionId = self.param.fashionTab[self.showNum]
  local fashionConfig = Logic.fashionLogic:GetFashionConfig(fashionId)
  if fashionConfig.cv_show == "" then
    logError("fashion cv_show is nil: ", fashionId)
    return
  end
  local model = Logic.shipLogic:GetHeroModelPath(self.girlSsId)
  local action = fashionConfig.cv_show
  SectionBehaviourMsg:PlayCVSubtitle(model, "CV_" .. action .. "_" .. model, "zm_" .. action .. "_" .. model)
end

return ShowGirlPage
