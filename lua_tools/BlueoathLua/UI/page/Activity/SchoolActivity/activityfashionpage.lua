local ActivityFashionPage = class("ui.page.Activity.SchoolActivity.ActivityFashionPage", LuaUIPage)

function ActivityFashionPage:DoInit()
  self.mFashionParts = {
    self.tab_Widgets.luaPart1,
    self.tab_Widgets.luaPart2,
    self.tab_Widgets.luaPart3,
    self.tab_Widgets.luaPart4
  }
end

function ActivityFashionPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ActivityFashionPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
end

function ActivityFashionPage:DoOnHide()
end

function ActivityFashionPage:DoOnClose()
end

function ActivityFashionPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local fashionIds = activityCfg.p1 or {}
  local url = activityCfg.p6[1]
  for nIndex, luapart in ipairs(self.mFashionParts) do
    local part = luapart:GetLuaTableParts()
    local fashionId = fashionIds[nIndex]
    if fashionId == nil then
      luapart.gameObject:SetActive(false)
      return
    else
      luapart.gameObject:SetActive(true)
    end
    local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
    local shipShowCfg = configManager.GetDataById("config_ship_show", fashionCfg.belong_to_ship)
    UIHelper.SetText(part.textName, shipShowCfg.ship_name)
    UIHelper.SetText(part.textFashion, fashionCfg.name)
    local periodId = activityCfg.p2[nIndex]
    local startTime, endTime = PeriodManager:GetPeriodTime(periodId)
    local startTimeFormat = time.formatTimeToYMD(startTime)
    UIHelper.SetText(part.textOpenTime, startTimeFormat)
    local functionId = activityCfg.p3[nIndex]
    local functionCfg = configManager.GetDataById("config_function_info", functionId)
    UIHelper.SetText(part.textGet, functionCfg.name)
    local isOpen = PeriodManager:IsInPeriod(periodId)
    local isHave = Logic.fashionLogic:CheckFashionOwn(fashionId)
    if isHave then
      part.objGetalready:SetActive(true)
      part.objBtnClose:SetActive(false)
      part.objBtnGoto:SetActive(false)
    else
      part.objGetalready:SetActive(false)
      part.objBtnClose:SetActive(not isOpen)
      part.objBtnGoto:SetActive(isOpen)
    end
    local functionparams = activityCfg.p4 or {}
    local functionparam = functionparams[nIndex] or 0
    UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
      if not Data.activityData:IsActivityOpen(self.mActivityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      if 0 < functionparam then
        moduleManager:JumpToFunc(functionId, functionparam)
      else
        moduleManager:JumpToFunc(functionId)
      end
    end)
    UGUIEventListener.AddButtonOnLongPress(part.btnImage, function()
      if url == nil or url == "" then
        logError("url is empty")
        return
      end
      local deviceWidth = platformManager:GetScreenWidth()
      local deviceHeight = platformManager:GetScreenHeight()
      local posX = 0
      local posY = 0
      if isWindows then
        deviceWidth = 700
        deviceHeight = 400
        posX = -1
        posY = -1
      end
      platformManager:openCustomWebView(url, deviceWidth, deviceHeight, posX, posY, "1")
    end)
  end
end

return ActivityFashionPage
