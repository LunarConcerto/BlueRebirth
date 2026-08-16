local MarryAffterPage = class("UI.Marry.MarryAffterPage", LuaUIPage)

function MarryAffterPage:DoInit()
end

function MarryAffterPage:DoOnOpen()
  self.param = self:GetParam()
  self:_Dotinfo()
  self:_LoadInformation()
end

function MarryAffterPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_marry, self._ClickBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tips, self._ClickTip, self)
end

function MarryAffterPage:_Dotinfo()
  local shipInfoId = Logic.shipLogic:GetShipInfoIdByHeroId(self.param[1])
  local name = Logic.shipLogic:GetName(shipInfoId)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  local dotinfo = {
    info = "ui_open_marryafter",
    ship_name = name,
    affection = math.modf(num / 10000)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function MarryAffterPage:_LoadInformation()
  if self.param[4] == MarryAffterType.MarryProcess then
    self.effectObj = plotManager:GetMarryEff()
  end
  local eventListner = self.tab_Widgets.animator_root.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  self.tab_Widgets.tween_content:Play(true)
  eventListner.enabled = self.param[4] == MarryAffterType.MarryProcess
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
  local createTime = time.formatTimerToYMD(singleGirl.CreateTime)
  local marryTime = time.formatTimerToYMD(singleGirl.MarryTime)
  UIHelper.SetText(self.tab_Widgets.tx_createTime, createTime)
  UIHelper.SetText(self.tab_Widgets.tx_marryTime, "\232\170\147\231\186\166\230\151\165" .. marryTime)
  UIHelper.SetImage(self.tab_Widgets.im_loveIcon, loveInfo.affection_icon)
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
  if self.param[4] == MarryAffterType.GirlInfo then
    local sliderTween = self:_CreateSliderTween(self.tab_Widgets.slider_love.gameObject, 0.5, 0, math.modf(num / 10000) / max)
    sliderTween:Play(true)
  end
  local shipInfo = Data.heroData:GetHeroById(self.param[1])
  local shipConfig = Logic.shipLogic:GetShipShowByHeroId(shipInfo.HeroId)
  local position = configManager.GetDataById("config_ship_position", shipConfig.ss_id).affection_position
  local scale = configManager.GetDataById("config_ship_position", shipConfig.ss_id).affection_scale
  self.tab_Widgets.im_girl.transform.anchoredPosition3D = Vector3.New(position[1], position[2], 0)
  self.tab_Widgets.im_girl.transform.localScale = Vector3.New(scale / 10000, scale / 10000, scale / 10000)
  self.tab_Widgets.obj_marryEff:SetActive(self.param[4] == MarryAffterType.GirlInfo)
  self.tab_Widgets.btn_marry.gameObject:SetActive(self.param[4] == MarryAffterType.GirlInfo)
  self.tab_Widgets.btn_tips.gameObject:SetActive(self.param[4] == MarryAffterType.GirlInfo)
  self:_ShowCondition()
end

function MarryAffterPage:_ShowCondition()
  local marry_cost = configManager.GetDataById("config_parameter", 162).arrValue
  local marry_allow_affection = configManager.GetDataById("config_parameter", 163).value
  local ringNum = Logic.bagLogic:ItemInfoById(marry_cost[2])
  if ringNum == nil then
    ringNum = 0
  else
    ringNum = math.tointeger(ringNum.num)
  end
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.param[1], MarryType.Love)
  UIHelper.SetText(self.tab_Widgets.tx_attribute, loveInfo.affection_adddescribe)
end

function MarryAffterPage:_ClickClose(...)
  if self.param[4] == MarryAffterType.GirlInfo then
    UIHelper.ClosePage("MarryAffterPage")
  end
end

function MarryAffterPage:_ClickBack(...)
  local ringTypeInfo = Data.heroData:GetHeroById(self.param[1])
  if ringTypeInfo.MarryType == 0 then
    ringTypeInfo.MarryType = 1
  end
  UIHelper.OpenPage("MarryProcessPage", {
    self.param[1],
    MarryProcess.After,
    ringTypeInfo.MarryType
  })
end

function MarryAffterPage:_CreateSliderTween(go, duration, from, to)
  local tweenSlider = TweenSlider.Add(go, duration, from, to)
  return tweenSlider
end

function MarryAffterPage:_ClickTip()
  UIHelper.OpenPage("HelpPage", {content = 1500013})
end

function MarryAffterPage:DoOnHide()
end

function MarryAffterPage:DoOnClose()
  if self.effectObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.effectObj)
    self.effectObj = nil
  end
end

return MarryAffterPage
