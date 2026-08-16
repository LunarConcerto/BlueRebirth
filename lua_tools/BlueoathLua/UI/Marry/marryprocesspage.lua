local MarryProcessPage = class("UI.Marry.MarryProcessPage", LuaUIPage)
local RingEffType = {
  [1] = "effects/prefabs/ui/eff2d_marry_jiezhizhuanchang02",
  [2] = "effects/prefabs/ui/eff2d_marry_jiezhizhuanchang01"
}
local AudioName = {
  [1] = "Effect_eff2d_marry_jiezhizhuanchang02",
  [2] = "Effect_eff2d_marry_jiezhizhuanchang01"
}
local effectPath = "ui/pages/marryeff"

function MarryProcessPage:DoInit()
  self.plotNum = 0
  self.m_timer = nil
  self.m_nameTimer = nil
  self.delta = 0
  self.marryEffPage = nil
  self.churchEff = nil
  self.effectObj = nil
  self.objVideoPlayProcess = nil
  SoundManager.Instance:PlayMusic("System|Wedding_RingBox")
end

function MarryProcessPage:DoOnOpen()
  self.param = self:GetParam()
  self:_LoadInformation()
  UIHelper.SetText(self.tab_Widgets.tx_ringTip, UIHelper.GetString(1500010))
  self.tab_Widgets.im_drag.gameObject:SetActive(true)
end

function MarryProcessPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.PlotTriggerEnd, self._PlotTriggerEnd, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self.SkipPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ringOne, self.OpenRing, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ringTwo, self.OpenRing, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.obj_continue, self.ContinueVideo, self)
  self:RegisterEvent(LuaEvent.MarryOpenPlot, self._OpenPlot, self)
end

function MarryProcessPage:_LoadInformation()
  self.tab_Widgets.alp_text.gameObject:SetActive(true)
  self.tab_Widgets.btn_skip.gameObject:SetActive(false)
  self.tab_Widgets.obj_ringOne:SetActive(self.param[3] == SelectMarryRing.RingOne)
  self.tab_Widgets.obj_ringTwo:SetActive(self.param[3] == SelectMarryRing.RingSecond)
end

function MarryProcessPage:OpenRing()
  self.tab_Widgets.im_drag.gameObject:SetActive(false)
  self.tab_Widgets.im_hand.gameObject:SetActive(false)
  SoundManager.Instance:PlayAudio(AudioName[self.param[3]])
  self.ringEff = UIHelper.CreateUIEffect(RingEffType[self.param[3]], self.tab_Widgets.obj_ringEff)
  local bgTime = configManager.GetDataById("config_parameter", 199).value / 10000
  self.m_bgTimer = self:CreateTimer(function()
    self:_TickBgCharge()
  end, bgTime, 1, false)
  self:StartTimer(self.m_bgTimer)
end

function MarryProcessPage:CreateEff()
  if self.effectObj == nil then
    self.effectObj = UIHelper.CreateUIEffect(effectPath, self.marryEffPage.gameObject.transform)
  end
  self.effectObj.transform:SetParent(self.marryEffPage.gameObject.transform)
  self.effectObj:AddComponent(UISortEffectComponent.GetClassType())
  self.effectObj.transform.position = Vector3.New(0, 0, 0)
  self.effectObj.transform.localScale = Vector3.New(1, 1, 1)
end

function MarryProcessPage:_DestroyEffect()
  if self.effectObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.effectObj)
    self.effectObj = nil
  end
  if self.endEffObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.endEffObj)
    self.endEffObj = nil
  end
  if self.whiteEffObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.whiteEffObj)
    self.whiteEffObj = nil
  end
end

function MarryProcessPage:_DestroyRingEffect(...)
  if self.ringEff ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.ringEff)
    self.ringEff = nil
  end
end

function MarryProcessPage:_TickBgCharge(...)
  self.tab_Widgets.imgBlack.gameObject:SetActive(true)
  self:StopTimer(self.m_bgTimer)
  local heroInfo = Data.heroData:GetHeroById(self.param[1])
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MARRY,
    heroInfo
  })
  self.tab_Widgets.btn_skip.gameObject:SetActive(1 < Data.illustrateData:GetAllMarryNum() or self.param[2] == MarryProcess.After)
  SoundManager.Instance:PlayMusic("Story|BGM_story_silence")
  local mp4 = "movie/" .. configManager.GetDataById("config_parameter", 198).arrValue[1] .. ".mp4"
  self.objVideoPlayProcess = UIHelper.InitAndPlayVideo(mp4, self.tab_Widgets.video_obj, function()
    self:_TickCharge()
  end)
  self:BeginCheckVideoPause(self.objVideoPlayProcess)
end

function MarryProcessPage:_TickCharge(...)
  if self.objPauseCheckTimer ~= nil then
    self.objPauseCheckTimer:Stop()
  end
  self.tab_Widgets.imgBlack.gameObject:SetActive(false)
  UIHelper.DestroyVideoProcess(self.objVideoPlayProcess)
  self:_DestroyRingEffect()
  self.tab_Widgets.btn_skip.gameObject:SetActive(false)
  self.tab_Widgets.im_drag.gameObject:SetActive(false)
  self.tab_Widgets.im_bg:SetActive(false)
  self.tab_Widgets.im_white:SetActive(false)
  self.tab_Widgets.video_obj.gameObject:SetActive(false)
  SoundManager.Instance:PlayMusic("System|Wedding_Church")
  eventManager:SendEvent(LuaEvent.PlayMarry, nil)
end

function MarryProcessPage:_OpenPlot()
  self.marryEffPage = self.tab_Widgets.obj_self
  self.tab_Widgets.im_bg:SetActive(true)
  self.tab_Widgets.im_white:SetActive(true)
  self:_whitePlotEff(function()
    local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
    plotManager:OpenPlotByType(PlotTriggerType.marriage_before, shipInfoId)
    self.marryEffPage = plotManager:GetMarryPlotPage()
    self:CreateEff()
    plotManager:SetMarryEff(self.effectObj, self.tab_Widgets.obj_self)
  end)
end

function MarryProcessPage:_PlotTriggerEnd()
  self.marryEffPage = self.tab_Widgets.obj_self
  self.effectObj = plotManager:GetMarryEff()
  self.plotNum = self.plotNum + 1
  if self.plotNum == 1 then
    self:CreateEff()
    self:ShowCGHand()
  elseif self.plotNum == 2 and self.param[2] == MarryProcess.Before then
    self:_marrySuccessEff(function()
      local shipInfo = Data.heroData:GetHeroById(self.param[1])
      local shipConfig = Logic.shipLogic:GetShipShowById(shipInfo.TemplateId)
      local shipInfoConfig = Logic.shipLogic:GetShipInfoById(shipInfo.TemplateId)
      local htid = shipInfo.TemplateId
      local image = Logic.shipLogic:GetDefaultShipShowById(htid)
      self.marryEffPage = UIHelper.OpenPage("MarryAffterPage", {
        self.param[1],
        shipInfoConfig.ship_name,
        image.ship_draw,
        MarryAffterType.MarryProcess
      })
      self:CreateEff()
      self.m_nameTimer = self:CreateTimer(function()
        self:_NameTickCharge(shipInfoConfig.ship_name, shipInfoConfig.ship_name)
      end, 3, 1, false)
      self:StartTimer(self.m_nameTimer)
    end)
  elseif self.plotNum == 2 and self.param[2] == MarryProcess.After then
    self:_marrySuccessEff(function()
      UIHelper.ClosePage("MarryProcessPage")
    end)
  end
end

function MarryProcessPage:_marrySuccessEff(callBackFun)
  self.tab_Widgets.im_drag.gameObject:SetActive(false)
  SoundManager.Instance:PlayMusic("System|Wedding_End")
  self:_whitePlotEff(function()
    self:_endPlotEff(function()
      self:_whitePlotEff(function()
        callBackFun()
      end)
    end)
  end)
end

function MarryProcessPage:_endPlotEff(callBackFun)
  if self.endEffObj == nil then
    self.endEffObj = UIHelper.CreateUIEffect("effects/prefabs/ui/eff2d_marry_success", self.marryEffPage.gameObject.transform)
    self.endEffObj:AddComponent(UISortEffectComponent.GetClassType())
    self.endEffObj.transform.position = Vector3.New(0, 0, 0)
    self.endEffObj.transform.localScale = Vector3.New(1, 1, 1)
  end
  local time = 4
  self.endtimer = self:CreateTimer(function()
    if self.endEffObj ~= nil then
      GR.objectPoolManager:LuaUnspawnAndDestory(self.endEffObj)
      self.endEffObj = nil
    end
    callBackFun()
  end, time, 1, false)
  self:StartTimer(self.endtimer)
end

function MarryProcessPage:_NameTickCharge(ship_name, ship_startname)
  self:StopTimer(self.m_nameTimer)
  UIHelper.OpenPage("ChangeNamePage", {
    self.param[1],
    ship_name,
    ship_startname,
    ChangeNameType.Marry
  })
end

function MarryProcessPage:ShowCGHand(...)
  self.tab_Widgets.im_drag.gameObject:SetActive(false)
  self.tab_Widgets.obj_handEff:SetActive(true)
  self.m_secondTimer = self:CreateTimer(function()
    self:SecondPlot()
  end, 1.5, 1, false)
  self:StartTimer(self.m_secondTimer)
end

function MarryProcessPage:SecondPlot(...)
  self:StopTimer(self.m_secondTimer)
  local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
  plotManager:OpenPlotByType(PlotTriggerType.marriage_after, shipInfoId)
  self.marryEffPage = plotManager:GetMarryPlotPage()
  self:CreateEff()
  plotManager:SetMarryEff(self.effectObj, self.tab_Widgets.obj_self)
end

function MarryProcessPage:SkipPage()
  self.tab_Widgets.im_bg:SetActive(false)
  self.tab_Widgets.beijing:SetActive(false)
  self.tab_Widgets.btn_skip.gameObject:SetActive(false)
  self.tab_Widgets.obj_continue:SetActive(false)
  self:_TickCharge()
end

function MarryProcessPage:DoOnHide()
end

function MarryProcessPage:DoOnClose()
  self:_DestroyEffect()
  homeEnvManager:PlayHomeBgm()
  if self.objPauseCheckTimer ~= nil then
    self.objPauseCheckTimer:Stop()
  end
end

function MarryProcessPage:_whitePlotEff(callBackFun)
  if self.whiteEffObj == nil then
    self.whiteEffObj = UIHelper.CreateUIEffect("effects/prefabs/ui/eff2d_marry_2dto3d", self.marryEffPage.gameObject.transform)
    self.whiteEffObj:AddComponent(UISortEffectComponent.GetClassType())
    self.whiteEffObj.transform.position = Vector3.New(0, 0, 0)
    self.whiteEffObj.transform.localScale = Vector3.New(1, 1, 1)
  end
  local time = 1.5
  self.whitetimer = self:CreateTimer(function()
    if self.whiteEffObj ~= nil then
      GR.objectPoolManager:LuaUnspawnAndDestory(self.whiteEffObj)
      self.whiteEffObj = nil
    end
    callBackFun()
  end, time, 1, false)
  self:StartTimer(self.whitetimer)
end

function MarryProcessPage:BeginCheckVideoPause(objVideoPlay)
  local funcCheck = function()
    if IsNil(self.tab_Widgets.obj_continue) then
      return
    end
    if IsNil(objVideoPlay) then
      return
    end
    local mediaPlayer = objVideoPlay:GetMediaPlayer()
    if IsNil(mediaPlayer) == nil then
      return
    end
    local objControl = mediaPlayer.Control
    if IsNil(objControl) then
      return
    end
    local bPaused = objControl:IsPaused()
    local bShow = bPaused
    if self.tab_Widgets.obj_continue.activeSelf ~= bShow then
      self.tab_Widgets.obj_continue:SetActive(bShow)
    end
  end
  if self.objPauseCheckTimer == nil then
    self.objPauseCheckTimer = Timer.New(funcCheck, 0.01, -1)
  else
    self.objPauseCheckTimer:Reset(funcCheck, 0.01, -1)
  end
  self.objPauseCheckTimer:Start()
end

function MarryProcessPage:ContinueVideo()
  if IsNil(self.objVideoPlayProcess) then
    return
  end
  UIHelper.ContinueVideo(self.objVideoPlayProcess)
end

return MarryProcessPage
