local ValentineGiftPage = class("ui.page.Activity.VocationActivity.ValentineGiftPage", LuaUIPage)

function ValentineGiftPage:DoInit()
  self.mItemBoxTemplateList = {
    self.tab_Widgets.itemBoxTemplate1,
    self.tab_Widgets.itemBoxTemplate2,
    self.tab_Widgets.itemBoxTemplate3,
    self.tab_Widgets.itemBoxTemplate4
  }
end

function ValentineGiftPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ValentineGiftPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ActivityValentineLoveLetter_RefreshData, self.ShowRefreshPage, self)
  self:RegisterEvent(LuaEvent.ActivityValentineLoveLetter_GetGift, function(handler, state)
    self:onGetGift(state)
  end)
  self:RegisterEvent(LuaEvent.ActivityValentineLoveLetter_GetGift_Secretary, function(handler, state)
    self:onGetGiftSecretary()
  end)
end

function ValentineGiftPage:DoOnHide()
end

function ValentineGiftPage:DoOnClose()
end

function ValentineGiftPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textActivityTime, startTimeFormat .. "-" .. endTimeFormat)
  if self.mTimer ~= nil then
    self.mTimer:Stop()
    self.mTimer = nil
  end
  self.mTimer = self:CreateTimer(function()
    self:ShowRefreshPage()
  end, 5, -1)
  self.mTimer:Start()
  self:ShowRefreshPage()
end

function ValentineGiftPage:ShowRefreshPage()
  local part = self.mItemBoxTemplateList[1]:GetLuaTableParts()
  local boxCfg = configManager.GetDataById("config_starbox", 9)
  local isGet = Data.activityvalentineloveletterData:GetCurActShipCanGet()
  local nSecretaryId = Data.userData:GetSecretaryId()
  local sf_id = Logic.shipLogic:GetShipInfoByHeroId(nSecretaryId).sf_id
  local sfConfig = configManager.GetDataById("config_ship_fleet", sf_id)
  local curSecretaryNoGift = sfConfig.valentine_gift == 0
  local isCurSecretaryHaveSend = Data.activityvalentineloveletterData:GetHeroTidByShipTid(sf_id) ~= 0
  if isGet then
    UIHelper.SetImage(part.icon, boxCfg.recieved_icon)
  elseif curSecretaryNoGift or isCurSecretaryHaveSend then
    UIHelper.SetImage(part.icon, boxCfg.unopen_icon)
  else
    UIHelper.SetImage(part.icon, boxCfg.open_icon)
  end
  part.Effect:SetActive(not isGet)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if isGet then
      noticeManager:ShowTipById(1300062)
      return
    elseif curSecretaryNoGift then
      noticeManager:ShowTipById(1300075)
      return
    elseif isCurSecretaryHaveSend then
      noticeManager:ShowTipById(1300074)
      return
    end
    Service.activityvalentineloveletterService:SendGetRewardSecretary()
  end)
end

function ValentineGiftPage:ShowRefreshPageBefore()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local curAreaIndex = 0
  for index = 1, ValentineLoveLetterMaxNum do
    local isIn = PeriodManager:IsInPeriodArea(activityCfg.period, {index})
    if isIn then
      curAreaIndex = index
    end
  end
  if curAreaIndex == 0 then
    curAreaIndex = ValentineLoveLetterMaxNum
  end
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, {curAreaIndex})
  local nowtime = time.getSvrTime()
  local total = endTime - startTime
  local now = nowtime - startTime
  local value = 0
  if total ~= 0 then
    value = (curAreaIndex - 1) / 3 + now / total / 3
  end
  if 1 < value then
    value = 1
    if self.mTimer ~= nil then
      self.mTimer:Stop()
      self.mTimer = nil
    end
  end
  self.tab_Widgets.sliderTime.value = value
  for index, boxTemplate in ipairs(self.mItemBoxTemplateList) do
    local part = boxTemplate:GetLuaTableParts()
    local boxCfg = configManager.GetDataById("config_starbox", 9)
    local isGet = Data.activityvalentineloveletterData:GetIsGift(index)
    local isIn = index <= curAreaIndex
    local isCanGetReward = isIn and not isGet
    if isGet then
      UIHelper.SetImage(part.icon, boxCfg.recieved_icon)
    elseif isCanGetReward then
      UIHelper.SetImage(part.icon, boxCfg.open_icon)
    else
      UIHelper.SetImage(part.icon, boxCfg.unopen_icon)
    end
    part.Effect:SetActive(isCanGetReward)
    local getindex = index
    UGUIEventListener.AddButtonOnClick(part.btn, function()
      if isGet then
        noticeManager:ShowTipById(1300062)
        return
      elseif not isCanGetReward then
        noticeManager:ShowTipById(1300061)
        return
      end
      Service.activityvalentineloveletterService:SendGetReward({Index = getindex})
    end)
  end
end

function ValentineGiftPage:onGetGiftSecretary()
  self.tab_Widgets.obj_eff:SetActive(true)
  local nSecretaryId = Data.userData:GetSecretaryId()
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  self.mEffectTimer = self:CreateTimer(function()
    local sfCfg = Logic.shipLogic:GetShipFleetByHeroId(nSecretaryId)
    local itemId = sfCfg.valentine_gift
    UIHelper.OpenPage("ValentineLoveLetterPage", {ItemId = itemId})
  end, 2)
  self.mEffectTimer:Start()
end

function ValentineGiftPage:onGetGift(state)
  self.tab_Widgets.obj_eff:SetActive(true)
  local index = state.Index
  local shipTid = Data.activityvalentineloveletterData:GetShipTidByIndex(index)
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  self.mEffectTimer = self:CreateTimer(function()
    local sfCfg = configManager.GetDataById("config_ship_fleet", shipTid)
    local itemId = sfCfg.valentine_gift
    UIHelper.OpenPage("ValentineLoveLetterPage", {ItemId = itemId})
  end, 2)
  self.mEffectTimer:Start()
end

return ValentineGiftPage
