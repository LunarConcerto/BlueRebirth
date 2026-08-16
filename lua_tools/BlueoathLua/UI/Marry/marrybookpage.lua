local MarryBookPage = class("UI.Marry.MarryBookPage", LuaUIPage)
local FontColor = {
  [true] = "757e8f",
  [false] = "a2adba"
}

function MarryBookPage:DoInit()
end

function MarryBookPage:DoOnOpen()
  self.param = self:GetParam()
  self:_LoadInformation()
  self:_Dotinfo()
end

function MarryBookPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_marry, self._ClickMarry, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tips, self._ClickTip, self)
end

function MarryBookPage:_Dotinfo()
  local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
  local name = Logic.shipLogic:GetName(shipInfoId)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  local dotinfo = {
    info = "ui_open_marrybook",
    ship_name = name,
    affection = math.modf(num / 10000)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function MarryBookPage:_LoadInformation()
  self.tab_Widgets.tween_content:Play(true)
  local userData = Data.userData:GetUserData()
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  local noMarry = configManager.GetDataById("config_parameter", 155).arrValue
  local marryed = configManager.GetDataById("config_parameter", 156).arrValue
  local singleGirl = Data.heroData:GetHeroById(self.param[1])
  if singleGirl.Name ~= "" then
    UIHelper.SetText(self.tab_Widgets.tx_girlName, singleGirl.Name)
    self.tab_Widgets.tx_des.text = string.format(loveInfo.affection_describe, singleGirl.Name)
  else
    UIHelper.SetText(self.tab_Widgets.tx_girlName, self.param[2])
    self.tab_Widgets.tx_des.text = string.format(loveInfo.affection_describe, self.param[2])
  end
  local time = time.formatTimerToYMD(singleGirl.CreateTime)
  UIHelper.SetText(self.tab_Widgets.tx_createTime, time)
  UIHelper.SetImage(self.tab_Widgets.im_loveIcon, loveInfo.affection_icon, true)
  local marry_allow_affection = configManager.GetDataById("config_parameter", 163).value
  self.tab_Widgets.obj_no_marry:SetActive(num < marry_allow_affection)
  UIHelper.SetImage(self.tab_Widgets.im_girl, self.param[3])
  UIHelper.SetText(self.tab_Widgets.tx_userName, userData.Uname)
  local max = 0
  if singleGirl.MarryTime == 0 then
    max = math.modf(noMarry[2] / 10000)
  else
    max = math.modf(marryed[2] / 10000)
  end
  UIHelper.SetText(self.tab_Widgets.tx_value, math.modf(num / 10000) .. "/" .. max)
  self.tab_Widgets.slider_love.interactable = false
  self.tab_Widgets.slider_love.value = math.modf(num / 10000) / max
  local sliderTween = self:_CreateSliderTween(self.tab_Widgets.slider_love.gameObject, 0.5, 0, math.modf(num / 10000) / max)
  sliderTween:Play(true)
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(self.param[1])
  local position = configManager.GetDataById("config_ship_position", shipConfig.ss_id).affection_position
  local scale = configManager.GetDataById("config_ship_position", shipConfig.ss_id).affection_scale
  self.tab_Widgets.im_girl.transform.anchoredPosition3D = Vector3.New(position[1], position[2], 0)
  self.tab_Widgets.im_girl.transform.localScale = Vector3.New(scale / 10000, scale / 10000, scale / 10000)
  self:_ShowCondition()
end

function MarryBookPage:_ShowCondition()
  local marry_cost = configManager.GetDataById("config_parameter", 162).arrValue
  local marry_allow_affection = configManager.GetDataById("config_parameter", 163).value
  local ringNum = Logic.bagLogic:ItemInfoById(marry_cost[2])
  if ringNum == nil then
    ringNum = 0
  else
    ringNum = math.tointeger(ringNum.num)
  end
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  self.tab_Widgets.im_condOne.gameObject:SetActive(marry_allow_affection <= num)
  self.tab_Widgets.im_condTwo.gameObject:SetActive(ringNum >= marry_cost[3])
  self.tab_Widgets.tx_condOne.text = UIHelper.SetColor(UIHelper.GetString(1500005), FontColor[marry_allow_affection <= num])
  self.tab_Widgets.tx_condTwo.text = UIHelper.SetColor(UIHelper.GetString(1500006), FontColor[ringNum >= marry_cost[3]])
  if marry_allow_affection <= num and ringNum >= marry_cost[3] then
    self.tab_Widgets.obj_eff:SetActive(true)
  else
    self.tab_Widgets.obj_eff:SetActive(false)
  end
  UIHelper.SetText(self.tab_Widgets.tx_attribute, loveInfo.affection_adddescribe)
end

function MarryBookPage:_ClickClose(...)
  UIHelper.ClosePage("MarryBookPage")
end

function MarryBookPage:_ClickMarry(...)
  if Logic.forbiddenHeroLogic:CheckForbiddenInSystem(self.param[1], ForbiddenType.Marry) then
    return
  end
  local marry_cost = configManager.GetDataById("config_parameter", 162).arrValue
  local marry_allow_affection = configManager.GetDataById("config_parameter", 163).value
  local ringNum = Logic.bagLogic:ItemInfoById(marry_cost[2])
  if ringNum == nil then
    ringNum = 0
  else
    ringNum = math.tointeger(ringNum.num)
  end
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  if marry_allow_affection > num then
    noticeManager:OpenTipPage(self, UIHelper.GetString(1500007))
  elseif ringNum < marry_cost[3] then
    globalNoitceManager:_OpenGoShopBox(marry_cost[2])
  else
    local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
    local name = Logic.shipLogic:GetName(shipInfoId)
    local dotinfo = {info = "ui_marry", ship_name = name}
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    UIHelper.OpenPage("SelectMarryRingPage", {
      self.param[1],
      ringNum
    })
  end
end

function MarryBookPage:_CreateSliderTween(go, duration, from, to)
  local tweenSlider = TweenSlider.Add(go, duration, from, to)
  return tweenSlider
end

function MarryBookPage:_ClickTip()
  UIHelper.OpenPage("HelpPage", {content = 1500013})
end

function MarryBookPage:DoOnHide()
end

function MarryBookPage:DoOnClose()
end

return MarryBookPage
