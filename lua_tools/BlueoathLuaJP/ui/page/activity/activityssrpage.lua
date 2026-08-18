local ActivitySSRPage = class("UI.Activity.ActivitySSRPage", LuaUIPage)
local HeroRarity = {
  [1] = "N",
  [2] = "R",
  [3] = "SR",
  [4] = "SSR"
}
local actId = Logic.activityLogic:GetOpenActivityByType(Activity.ActivitySSR)
local seekTimes = configManager.GetDataById("config_parameter", 273).value

function ActivitySSRPage:DoInit()
  self.m_timer = nil
  self.actSSRInfo = {}
  self.confirmShipId = nil
  self.isSeeking = false
  self.remainCount = 0
  self.allCount = 0
  self.mapHero = {}
  self.tabAllHero = {}
  self.lastIndex = nil
  self.mapAllHero = {}
  self.m_frameTimer = nil
end

function ActivitySSRPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_share, function()
    self:_ClickShare()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_seek, function()
    self:_ClickSeek()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, function()
    self:_ClickHelp()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, function()
    self:_ClickGet()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_save, function()
    self:_ClickSave()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_change, function()
    self:_ClickChange()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, function()
    self:_ClickSureFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, function()
    self:_ClickBack()
  end)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.UpadateActData, self._UpdatePage, self)
  self:RegisterEvent(LuaEvent.ErrorActData, self._ErrorActData, self)
  self:RegisterEvent(LuaEvent.ActivitySSRRand, self._UpateActSSRRand, self)
  self:RegisterEvent(LuaEvent.ActivitySSRSelect, self._UpateActSSRSelect, self)
end

function ActivitySSRPage:DoOnOpen()
  self.isSeeking = false
  local params = self:GetParam()
  self.mActivityId = params.activityId
  self:InItPage()
  self:_UpdatePage()
  self:_DealData()
  self:_ShowHelpInfo()
end

function ActivitySSRPage:InItPage()
  local widgets = self:GetWidgets()
  widgets.obj_queren:SetActive(false)
  widgets.obj_get:SetActive(false)
  widgets.obj_change:SetActive(false)
  widgets.obj_share:SetActive(false)
  widgets.obj_seeking:SetActive(false)
  widgets.btn_share.gameObject:SetActive(false)
  local tabAllHero = {}
  local tabSSRHero = configManager.GetDataById("config_activity", actId[1].id).p4
  local tabSRHero = configManager.GetDataById("config_activity", actId[1].id).p5
  for k, v in pairs(tabSSRHero) do
    table.insert(self.tabAllHero, v[1])
  end
  for k, v in pairs(tabSRHero) do
    table.insert(self.tabAllHero, v[1])
  end
  for k, v in pairs(self.tabAllHero) do
    self.mapAllHero[k] = v
  end
end

function ActivitySSRPage:_UpdatePage(...)
  self.actSSRInfo = Data.activitySSRData:GetData()
  if self.isSeeking then
    return
  end
  if self.actSSRInfo.SelectShipId ~= 0 then
    if self.actSSRInfo.SaveShipId == 0 then
      self:_FirstShowGirl()
    else
      self:_ChangeShowGirl()
    end
  end
  self:_ShowGirlInfo()
end

function ActivitySSRPage:_UpateActSSRRand()
  local widgets = self:GetWidgets()
  widgets.obj_seeking:SetActive(false)
  UIHelper.SetUILock(true)
  if self.actSSRInfo.SaveShipId ~= 0 then
    local gO = self.mapHero[self.actSSRInfo.SaveShipId]
    gO.gameObject:SetActive(false)
  end
  local time = configManager.GetDataById("config_parameter", 366).value
  self.m_frameTimer = self:CreateTimer(function()
    self:_UpdateCharge()
  end, time / 1000, -1)
  self:StartTimer(self.m_frameTimer)
  self.m_timer = self:CreateTimer(function()
    self:_SeekOver()
  end, seekTimes, 1, false)
  self:StartTimer(self.m_timer)
end

function ActivitySSRPage:_UpdateCharge(...)
  local randomNum = math.random(1, #self.tabAllHero)
  local id = self.mapAllHero[randomNum]
  local gameObj = self.mapHero[id]
  if self.lastIndex ~= nil then
    local lastGO = self.mapHero[self.lastIndex]
    lastGO:SetActive(false)
  end
  gameObj.gameObject:SetActive(true)
  self.lastIndex = id
end

function ActivitySSRPage:_UpateActSSRSelect()
  self.isSeeking = false
  local var = Data.activitySSRData:GetData()
  if self.lastIndex ~= nil and self.actSSRInfo.SaveShipId ~= 0 then
    local gO = self.mapHero[self.lastIndex]
    gO:SetActive(false)
  end
  if self.actSSRInfo.SaveShipId ~= 0 then
    local gO = self.mapHero[self.actSSRInfo.SaveShipId]
    gO:SetActive(true)
    self.lastIndex = self.actSSRInfo.SaveShipId
  end
  self:_ShowGirlInfo()
end

function ActivitySSRPage:_DealData()
  local tabAllHero = {}
  local tabSSRHero = configManager.GetDataById("config_activity", actId[1].id).p4
  local tabSRHero = configManager.GetDataById("config_activity", actId[1].id).p5
  local tabLeftHero = {}
  local tabRightHero = {}
  for k, v in pairs(tabSSRHero) do
    if v[3] == SSRDirection.Left then
      table.insert(tabLeftHero, v[1])
    elseif v[3] == SSRDirection.Right then
      table.insert(tabRightHero, v[1])
    end
  end
  for k, v in pairs(tabSRHero) do
    if v[3] == SSRDirection.Left then
      table.insert(tabLeftHero, v[1])
    elseif v[3] == SSRDirection.Right then
      table.insert(tabRightHero, v[1])
    end
  end
  self:_ShowLeftActivityGirl(tabLeftHero)
  self:_ShowRightActivityGirl(tabRightHero)
  self.tabLeftHero = tabLeftHero
  self.tabRightHero = tabRightHero
  if self.actSSRInfo.SelectShipId ~= 0 then
    local gO = self.mapHero[self.actSSRInfo.SelectShipId]
    gO.gameObject:SetActive(true)
    self.lastIndex = self.actSSRInfo.SelectShipId
  end
end

function ActivitySSRPage:_ShowLeftActivityGirl(tabLeftHero, isSure)
  if isSure == nil then
    isSure = true
  end
  if self.actSSRInfo.SaveShipId ~= 0 and self.actSSRInfo.SelectShipId ~= 0 then
    isSure = false
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.ill_content, #tabLeftHero, function(nIndex, tabPart)
    local shipShow = Logic.shipLogic:GetShipShowById(tabLeftHero[nIndex])
    local shipInfo = Logic.shipLogic:GetShipInfoById(tabLeftHero[nIndex])
    if isSure then
      tabPart.obj_xuanzhong:SetActive(self.actSSRInfo.SaveShipId == tabLeftHero[nIndex])
    else
      tabPart.obj_xuanzhong:SetActive(self.actSSRInfo.SelectShipId == tabLeftHero[nIndex])
    end
    if shipInfo and shipShow then
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShow.ship_icon5))
      UIHelper.SetImage(tabPart.im_pinzhi, UserHeadQualityImg[shipInfo.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_ship, function()
        self:_OpenIllustrate(tabLeftHero[nIndex], tabLeftHero)
      end)
    end
    if self.mapHero[tabLeftHero[nIndex]] == nil then
      self.mapHero[tabLeftHero[nIndex]] = {}
    end
    self.mapHero[tabLeftHero[nIndex]] = tabPart.obj_xuanzhong
  end)
end

function ActivitySSRPage:_ShowRightActivityGirl(tabRightHero, isSure)
  if isSure == nil then
    isSure = true
  end
  if self.actSSRInfo.SaveShipId ~= 0 and self.actSSRInfo.SelectShipId ~= 0 then
    isSure = false
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_rightItem, self.tab_Widgets.ill_rightContent, #tabRightHero, function(nIndex, tabPart)
    local shipShow = Logic.shipLogic:GetShipShowById(tabRightHero[nIndex])
    local shipInfo = Logic.shipLogic:GetShipInfoById(tabLeftHero[nIndex])
    if isSure then
      tabPart.obj_xuanzhong:SetActive(self.actSSRInfo.SaveShipId == tabRightHero[nIndex])
    else
      tabPart.obj_xuanzhong:SetActive(self.actSSRInfo.SelectShipId == tabRightHero[nIndex])
    end
    if shipInfo and shipShow then
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShow.ship_icon5))
      UIHelper.SetImage(tabPart.im_pinzhi, UserHeadQualityImg[shipInfo.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btn_ship, function()
        self:_OpenIllustrate(tabRightHero[nIndex], tabRightHero)
      end)
    end
    self.mapHero[tabRightHero[nIndex]] = tabPart.obj_xuanzhong
  end)
end

function ActivitySSRPage:_OpenIllustrate(templateId, tabAllHero)
  local shipInfo = Logic.shipLogic:GetShipShowById(templateId)
  if shipInfo == nil then
    return
  end
  local tabHeroId = {}
  for k, v in pairs(tabAllHero) do
    local spInfo = Logic.shipLogic:GetShipShowById(v)
    table.insert(tabHeroId, spInfo.ss_id)
  end
  UIHelper.OpenPage("IllustrateInfo", {
    id = shipInfo.sf_id,
    tabHeroId = tabHeroId,
    Type = IllustrateType.ActivitySSR
  })
end

function ActivitySSRPage:_ShowGirlInfo()
  local widgets = self:GetWidgets()
  local count = configManager.GetDataById("config_activity", actId[1].id).p6
  local allCount = count[1]
  if self.actSSRInfo.DayShareCount ~= 0 then
    allCount = count[1] + count[2]
  end
  self.allCount = allCount
  self.remainCount = allCount - self.actSSRInfo.DaySelectCount
  UIHelper.SetText(widgets.tx_times, self.remainCount .. "/" .. allCount)
  widgets.tx_cv.gameObject:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  widgets.im_type.gameObject:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  widgets.tx_name.gameObject:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  widgets.im_pinzhi.gameObject:SetActive(false)
  widgets.obj_message:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  if self.actSSRInfo.SaveShipId == 0 then
    local defaultDraw = configManager.GetDataById("config_parameter", 274).arrValue
    UIHelper.SetImage(widgets.im_girl, defaultDraw[1])
    widgets.im_girl.gameObject:SetActive(false)
    UIHelper.SetImage(widgets.im_pinzhi, "uipic_ui_ssrevent_im_taizi")
    widgets.im_pinzhi.gameObject:SetActive(true)
    return
  end
  widgets.im_girl.gameObject:SetActive(true)
  local shipCVConfig = Logic.shipLogic:GetShipShowHandBookById(self.actSSRInfo.SaveShipId)
  UIHelper.SetText(widgets.tx_cv, shipCVConfig.ship_character_voice)
  local shipInfo = Logic.shipLogic:GetShipInfoById(self.actSSRInfo.SaveShipId)
  if shipInfo == nil then
    return
  end
  local girlDraw = configManager.GetDataById("config_ship_show", shipInfo.sf_id).ship_draw
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  UIHelper.SetImage(widgets.im_type, NewCardShipTypeImg[shipInfo.ship_type])
  UIHelper.SetImage(widgets.im_pinzhi, GetShipImage[shipInfo.quality])
  self.tab_Widgets.obj_before:SetActive(false)
  self.tab_Widgets.obj_card:SetActive(true)
  widgets.obj_sr:SetActive(shipInfo.quality == 3)
  widgets.obj_ssr:SetActive(shipInfo.quality == 4)
  UIHelper.SetText(widgets.tx_name, name)
  UIHelper.SetText(widgets.tx_cv, shipCVConfig.ship_character_voice)
  local spcGirl1 = configManager.GetDataById("config_parameter", 367).arrValue
  local nomral = configManager.GetDataById("config_parameter", 368).arrValue
  if spcGirl1[1][1] == self.actSSRInfo.SaveShipId then
    widgets.im_girl.transform.localPosition = Vector2.New(spcGirl1[1][2], spcGirl1[1][3])
  elseif spcGirl1[2][1] == self.actSSRInfo.SaveShipId then
    widgets.im_girl.transform.localPosition = Vector2.New(spcGirl1[2][2], spcGirl1[2][3])
  elseif spcGirl1[3][1] == self.actSSRInfo.SaveShipId then
    widgets.im_girl.transform.localPosition = Vector2.New(spcGirl1[3][2], spcGirl1[3][3])
  else
    widgets.im_girl.transform.localPosition = Vector2.New(nomral[1], nomral[2])
  end
  UIHelper.SetImage(widgets.im_girl, girlDraw)
end

function ActivitySSRPage:_ShowHelpInfo()
  local activityInfo = configManager.GetDataById("config_activity", actId[1].id)
  local periodInfo = configManager.GetDataById("config_period", activityInfo.period)
  local startTime = PeriodManager:GetPeriodTime(activityInfo.period, activityInfo.period_area)
  local startTimeFormat = time.formatTimerToMDH(startTime)
  local endTimeFormat = time.formatTimerToMDH(startTime + periodInfo.duration)
  UIHelper.SetText(self.tab_Widgets.tx_tips, UIHelper.GetString(2300001))
  UIHelper.SetText(self.tab_Widgets.tx_date, startTimeFormat .. "-" .. endTimeFormat)
end

function ActivitySSRPage:_ClickSeek()
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  if self.remainCount == 0 and self.actSSRInfo.DayShareCount ~= 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(2300006))
    return
  elseif self.actSSRInfo.DayShareCount == 0 and self.remainCount == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(2300010))
    return
  end
  self.isSeeking = true
  self.tab_Widgets.obj_before:SetActive(true)
  self.tab_Widgets.obj_sr:SetActive(false)
  self.tab_Widgets.obj_ssr:SetActive(false)
  self.tab_Widgets.obj_card:SetActive(false)
  Service.activitySSRService:SendActivitySSRRand()
end

function ActivitySSRPage:_SeekOver()
  local widgets = self:GetWidgets()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
    self.m_timer = nil
  end
  if self.m_frameTimer ~= nil then
    self.m_frameTimer:Stop()
    self.m_frameTimer = nil
  end
  if self.actSSRInfo.SaveShipId == 0 then
    UIHelper.SetText(widgets.tx_ok, UIHelper.GetString(920000207))
  else
    UIHelper.SetText(widgets.tx_ok, UIHelper.GetString(920000532))
  end
  if self.lastIndex ~= nil then
    local lastGO = self.mapHero[self.lastIndex]
    lastGO:SetActive(false)
  end
  local gO = self.mapHero[self.actSSRInfo.SelectShipId]
  gO:SetActive(true)
  self.lastIndex = self.actSSRInfo.SelectShipId
  self:_FirstShowGirl()
end

function ActivitySSRPage:_FirstShowGirl()
  local widgets = self:GetWidgets()
  widgets.obj_seeking:SetActive(false)
  widgets.obj_get:SetActive(true)
  local selectShipId = self.actSSRInfo.SelectShipId
  local shipInfo = Logic.shipLogic:GetShipInfoById(selectShipId)
  local shipShow = Logic.shipLogic:GetShipShowById(selectShipId)
  if shipInfo == nil then
    return
  end
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local str = string.format(UIHelper.GetString(2300003), HeroRarity[shipInfo.quality], name)
  UIHelper.SetImage(widgets.im_getGirl, tostring(shipShow.ship_icon2))
  UIHelper.SetImage(widgets.bg_girlQuality, GetShipImageRand[shipInfo.quality])
  UIHelper.SetImage(widgets.im_girlType, NewCardShipTypeImg[shipInfo.ship_type])
  UIHelper.SetImage(widgets.im_littlequality, LightQualityIcon[shipInfo.quality], true)
  UIHelper.SetText(widgets.tx_gilrName, name)
  UIHelper.SetText(widgets.tx_con, str)
  local shipTypeConfig = configManager.GetDataById("config_ship_type", shipInfo.ship_type)
  UIHelper.SetImage(widgets.im_getTypeIcon, shipTypeConfig.wordsimage)
  UIHelper.SetUILock(false)
end

function ActivitySSRPage:_ClickGet()
  local widgets = self:GetWidgets()
  widgets.obj_get:SetActive(false)
  if self.actSSRInfo.SaveShipId ~= 0 then
    self:_ChangeShowGirl()
  else
    self.confirmShipId = self.actSSRInfo.SelectShipId
    self.isSeeking = false
    Service.activitySSRService:SendSecletShipId(self.confirmShipId)
  end
end

function ActivitySSRPage:_ChangeShowGirl()
  local widgets = self:GetWidgets()
  local selectShipId = self.actSSRInfo.SelectShipId
  local saveShipId = self.actSSRInfo.SaveShipId
  if selectShipId == 0 or saveShipId == 0 then
    logError("_ChangeShowGirl\229\135\189\230\149\176\233\148\153\232\175\175\232\136\176\229\168\152id\228\184\186\231\169\186")
    return
  end
  local newShipShow = Logic.shipLogic:GetShipShowById(selectShipId)
  local newShipInfo = Logic.shipLogic:GetShipInfoById(selectShipId)
  local oldShipShow = Logic.shipLogic:GetShipShowById(saveShipId)
  local oldShipInfo = Logic.shipLogic:GetShipInfoById(saveShipId)
  if newShipShow == nil or oldShipShow == nil then
    return
  end
  widgets.obj_change:SetActive(true)
  local newName = Logic.shipLogic:GetName(newShipShow.sf_id)
  local oldName = Logic.shipLogic:GetName(oldShipShow.sf_id)
  UIHelper.SetImage(widgets.im_oldGirl, tostring(oldShipShow.ship_icon2))
  UIHelper.SetImage(widgets.bg_oldQuality, GetShipImageRand[oldShipInfo.quality])
  UIHelper.SetImage(widgets.im_oldType, NewCardShipTypeImg[oldShipInfo.ship_type])
  UIHelper.SetImage(widgets.im_oldlittlequality, BlackQualityIcon[oldShipInfo.quality], true)
  UIHelper.SetText(widgets.tx_oldName, oldName)
  local oldShipTypeConfig = configManager.GetDataById("config_ship_type", oldShipInfo.ship_type)
  UIHelper.SetImage(widgets.im_oldTypeIcon, oldShipTypeConfig.wordsimage)
  UIHelper.SetImage(widgets.im_newGirl, tostring(newShipShow.ship_icon2))
  UIHelper.SetImage(widgets.bg_newQuality, GetShipImageRand[newShipInfo.quality])
  UIHelper.SetImage(widgets.im_newType, NewCardShipTypeImg[newShipInfo.ship_type])
  UIHelper.SetImage(widgets.im_newlittlequality, LightQualityIcon[newShipInfo.quality], true)
  UIHelper.SetText(widgets.tx_newName, newName)
  local newShipTypeConfig = configManager.GetDataById("config_ship_type", newShipInfo.ship_type)
  UIHelper.SetImage(widgets.im_newTypeIcon, newShipTypeConfig.wordsimage)
end

function ActivitySSRPage:_ClickSave(...)
  local shipInfo = Logic.shipLogic:GetShipInfoById(self.actSSRInfo.SaveShipId)
  if shipInfo == nil then
    return
  end
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local str = string.format(UIHelper.GetString(2300009), HeroRarity[shipInfo.quality], name)
  self.tab_Widgets.obj_queren:SetActive(true)
  self:_ShowConfirmPage(str, self.actSSRInfo.SaveShipId)
end

function ActivitySSRPage:_ClickChange(...)
  local shipInfo = Logic.shipLogic:GetShipInfoById(self.actSSRInfo.SelectShipId)
  local oldshipInfo = Logic.shipLogic:GetShipInfoById(self.actSSRInfo.SaveShipId)
  if shipInfo == nil then
    return
  end
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local oldname = Logic.shipLogic:GetName(oldshipInfo.sf_id)
  local str = string.format(UIHelper.GetString(2300008), HeroRarity[oldshipInfo.quality], oldname, HeroRarity[shipInfo.quality], name)
  self.tab_Widgets.obj_queren:SetActive(true)
  self:_ShowConfirmPage(str, self.actSSRInfo.SelectShipId)
end

function ActivitySSRPage:_ShowConfirmPage(content, shipId)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_queren, content)
  self.confirmShipId = shipId
end

function ActivitySSRPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 2300002})
end

function ActivitySSRPage:_ClickBack()
  self.tab_Widgets.obj_queren:SetActive(false)
end

function ActivitySSRPage:_ClickSureFun()
  Service.activitySSRService:SendSecletShipId(self.confirmShipId)
  self.tab_Widgets.obj_queren:SetActive(false)
  self.tab_Widgets.obj_change:SetActive(false)
end

function ActivitySSRPage:_ClickShare()
  if self.actSSRInfo.SaveShipId == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(2300007))
    return
  end
  self:_ShowSharePicture()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName(), QRCodeType.RightDown, OpenSharePage.ActSSR)
end

function ActivitySSRPage:_ShowSharePicture()
  local widgets = self:GetWidgets()
  widgets.obj_share:SetActive(true)
  if self.actSSRInfo.SaveShipId == 0 then
    UIHelper.SetImage(widgets.im_girl, "uipic_ui_lihui_1_aokelan_hei")
    return
  end
  widgets.im_girl.gameObject:SetActive(true)
  local shipCVConfig = Logic.shipLogic:GetShipShowHandBookById(self.actSSRInfo.SaveShipId)
  UIHelper.SetText(widgets.tx_shareCvName, shipCVConfig.ship_character_voice)
  local shipInfo = Logic.shipLogic:GetShipInfoById(self.actSSRInfo.SaveShipId)
  if shipInfo == nil then
    return
  end
  local girlDraw = configManager.GetDataById("config_ship_show", shipInfo.sf_id).ship_draw
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local shipTypeConfig = configManager.GetDataById("config_ship_type", shipInfo.ship_type)
  UIHelper.SetImage(widgets.im_shareType_des, shipTypeConfig.wordsimage)
  UIHelper.SetImage(widgets.im_shareType, NewCardShipTypeImg[shipInfo.ship_type])
  UIHelper.SetImage(widgets.im_shareQuality, GetShipShareImageRand[shipInfo.quality])
  UIHelper.SetText(widgets.tx_shareGirl, name)
  UIHelper.SetText(widgets.tx_shareCvName, shipCVConfig.ship_character_voice)
  UIHelper.SetImage(widgets.im_shareGirl, girlDraw)
  widgets.obj_ssrShareQuality:SetActive(shipInfo.quality == 4)
  widgets.obj_srShareQuality:SetActive(shipInfo.quality == 3)
end

function ActivitySSRPage:_ShareOver()
  self.tab_Widgets.obj_share:SetActive(false)
  self:ShareComponentShow(true)
  Service.activitySSRService:SendActivitySSRShare()
end

function ActivitySSRPage:_ErrorActData(err)
  if err == ErrorCode.ErrActSSRTime then
    noticeManager:ShowTip(UIHelper.GetString(2300004))
  elseif err == ErrorCode.ErrChangeGirl then
    noticeManager:ShowTip(UIHelper.GetString(2300005))
  elseif err == ErrorCode.ErrNoTimes then
    noticeManager:ShowTip(UIHelper.GetString(2300006))
  end
end

function ActivitySSRPage:DoOnHide()
end

function ActivitySSRPage:DoOnClose()
  UIHelper.SetUILock(false)
end

return ActivitySSRPage
