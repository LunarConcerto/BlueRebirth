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
  self:InItPage()
  self:_ShowHelpInfo()
  self:_ShowActivityGirl()
  self:_UpdatePage()
end

function ActivitySSRPage:InItPage()
  local widgets = self:GetWidgets()
  widgets.obj_queren:SetActive(false)
  widgets.obj_get:SetActive(false)
  widgets.obj_change:SetActive(false)
  widgets.obj_share:SetActive(false)
  widgets.obj_seeking:SetActive(false)
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
  widgets.obj_seeking:SetActive(true)
  self.m_timer = self:CreateTimer(function()
    self:_SeekOver()
  end, seekTimes, 1, false)
  self:StartTimer(self.m_timer)
end

function ActivitySSRPage:_UpateActSSRSelect()
  self.isSeeking = false
  self:_ShowGirlInfo()
end

function ActivitySSRPage:_ShowActivityGirl()
  local tabAllHero = {}
  local tabSSRHero = configManager.GetDataById("config_activity", actId[1].id).p4
  local tabSRHero = configManager.GetDataById("config_activity", actId[1].id).p5
  for k, v in pairs(tabSSRHero) do
    table.insert(tabAllHero, v[1])
  end
  for k, v in pairs(tabSRHero) do
    table.insert(tabAllHero, v[1])
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.ill_content, self.tab_Widgets.obj_item, #tabAllHero, function(tabParts)
    for nIndex, tabPart in pairs(tabParts) do
      nIndex = tonumber(nIndex)
      local shipInfo = Logic.shipLogic:GetShipShowById(tabAllHero[nIndex])
      if shipInfo then
        UIHelper.SetImage(tabPart.im_girl, tostring(shipInfo.ship_icon5))
        UIHelper.SetImage(tabPart.im_pinzhi, UserHeadQualityImg[shipInfo.quality])
        UGUIEventListener.AddButtonOnClick(tabPart.btn_ship, function()
          self:_OpenIllustrate(tabAllHero[nIndex], tabAllHero)
        end)
      end
    end
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
  widgets.im_pinzhi.gameObject:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  widgets.obj_message:SetActive(self.actSSRInfo.SaveShipId ~= 0)
  if self.actSSRInfo.SaveShipId == 0 then
    local defaultDraw = configManager.GetDataById("config_parameter", 274).arrValue
    UIHelper.SetImage(widgets.im_girl, defaultDraw[1])
    return
  end
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
  UIHelper.SetText(widgets.tx_name, name)
  UIHelper.SetText(widgets.tx_cv, shipCVConfig.ship_character_voice)
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
  if self.remainCount == 0 and self.actSSRInfo.DayShareCount ~= 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(2300006))
    return
  elseif self.actSSRInfo.DayShareCount == 0 and self.remainCount == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(2300010))
    return
  end
  self.isSeeking = true
  Service.activitySSRService:SendActivitySSRRand()
end

function ActivitySSRPage:_SeekOver()
  local widgets = self:GetWidgets()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
    self.m_timer = nil
  end
  if self.actSSRInfo.SaveShipId == 0 then
    UIHelper.SetText(widgets.tx_ok, "\231\161\174\229\174\154")
  else
    UIHelper.SetText(widgets.tx_ok, "\229\165\189\231\154\132,\228\184\139\228\184\128\230\173\165")
  end
  self:_FirstShowGirl()
end

function ActivitySSRPage:_FirstShowGirl()
  local widgets = self:GetWidgets()
  widgets.obj_seeking:SetActive(false)
  widgets.obj_get:SetActive(true)
  local selectShipId = self.actSSRInfo.SelectShipId
  local shipInfo = Logic.shipLogic:GetShipShowById(selectShipId)
  if shipInfo == nil then
    return
  end
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local str = string.format(UIHelper.GetString(2300003), HeroRarity[shipInfo.quality], name)
  UIHelper.SetImage(widgets.im_getGirl, tostring(shipInfo.ship_icon1))
  UIHelper.SetImage(widgets.bg_girlQuality, GetShipImageRand[shipInfo.quality])
  UIHelper.SetImage(widgets.im_girlType, NewCardShipTypeImg[shipInfo.ship_type])
  UIHelper.SetImage(widgets.im_littlequality, LightQualityIcon[shipInfo.quality])
  UIHelper.SetText(widgets.tx_gilrName, name)
  UIHelper.SetText(widgets.tx_con, str)
  local shipTypeConfig = configManager.GetDataById("config_ship_type", shipInfo.ship_type)
  UIHelper.SetImage(widgets.im_getTypeIcon, shipTypeConfig.wordsimage)
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
  local newShipInfo = Logic.shipLogic:GetShipShowById(selectShipId)
  local oldShipInfo = Logic.shipLogic:GetShipShowById(saveShipId)
  if newShipInfo == nil or oldShipInfo == nil then
    return
  end
  widgets.obj_change:SetActive(true)
  local newName = Logic.shipLogic:GetName(newShipInfo.sf_id)
  local oldName = Logic.shipLogic:GetName(oldShipInfo.sf_id)
  UIHelper.SetImage(widgets.im_oldGirl, tostring(oldShipInfo.ship_icon1))
  UIHelper.SetImage(widgets.bg_oldQuality, GetShipImageRand[oldShipInfo.quality])
  UIHelper.SetImage(widgets.im_oldType, NewCardShipTypeImg[oldShipInfo.ship_type])
  UIHelper.SetImage(widgets.im_oldlittlequality, BlackQualityIcon[oldShipInfo.quality])
  UIHelper.SetText(widgets.tx_oldName, oldName)
  local oldShipTypeConfig = configManager.GetDataById("config_ship_type", oldShipInfo.ship_type)
  UIHelper.SetImage(widgets.im_oldTypeIcon, oldShipTypeConfig.wordsimage)
  UIHelper.SetImage(widgets.im_newGirl, tostring(newShipInfo.ship_icon1))
  UIHelper.SetImage(widgets.bg_newQuality, GetShipImageRand[newShipInfo.quality])
  UIHelper.SetImage(widgets.im_newType, NewCardShipTypeImg[newShipInfo.ship_type])
  UIHelper.SetImage(widgets.im_newlittlequality, LightQualityIcon[newShipInfo.quality])
  UIHelper.SetText(widgets.tx_newName, newName)
  local newShipTypeConfig = configManager.GetDataById("config_ship_type", newShipInfo.ship_type)
  UIHelper.SetImage(widgets.im_newTypeIcon, newShipTypeConfig.wordsimage)
end

function ActivitySSRPage:_ClickSave(...)
  local shipInfo = Logic.shipLogic:GetShipShowById(self.actSSRInfo.SaveShipId)
  if shipInfo == nil then
    return
  end
  local name = Logic.shipLogic:GetName(shipInfo.sf_id)
  local str = string.format(UIHelper.GetString(2300009), HeroRarity[shipInfo.quality], name)
  self.tab_Widgets.obj_queren:SetActive(true)
  self:_ShowConfirmPage(str, self.actSSRInfo.SaveShipId)
end

function ActivitySSRPage:_ClickChange(...)
  local shipInfo = Logic.shipLogic:GetShipShowById(self.actSSRInfo.SelectShipId)
  local oldshipInfo = Logic.shipLogic:GetShipShowById(self.actSSRInfo.SaveShipId)
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
  UIHelper.OpenPage("HelpPage", {
    content = 2300002,
    openType = OpenSharePage.ActSSR
  })
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
