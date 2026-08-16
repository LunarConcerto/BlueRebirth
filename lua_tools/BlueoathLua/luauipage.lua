LuaUIPage = class("UI.LuaUIPage")

function LuaUIPage:Init(cs_page)
  self.cs_page = cs_page
  self.tab_eventHandlers = {}
  self.m_effObjcts = {}
  self.m_timerTable = {}
  self.redDot_eventHandlers = {}
  self.tab_Widgets = self.cs_page:GetComponentsNeed()
end

function LuaUIPage:GetComponentNeed(tabFields)
  self.tab_Widgets = self.cs_page:GetComponentsNeed()
end

function LuaUIPage:GetName()
  return self.cs_page.name
end

function LuaUIPage:SetToNoView(_bool)
  return self.cs_page:SetToNoView(_bool)
end

function LuaUIPage:GetWidgets()
  return self.tab_Widgets
end

function LuaUIPage:GetParam()
  if self.param == nil then
    self.param = self.cs_page:GetParam()
  end
  return self.param
end

function LuaUIPage:SaveNewParam(param)
  self.param = param
  self.cs_page:SaveParam(self.param)
end

function LuaUIPage:CloseSelf()
  self.cs_page:CloseSelf()
end

function LuaUIPage:DoLoad()
end

function LuaUIPage:DoOpen()
  self:DoInit()
end

function LuaUIPage:DoShow()
  local pageName = self:GetName()
  local config = configManager.GetDataById("config_ui_config", pageName)
  if config.page_type == 1 then
    RetentionHelper.SkipAllBehaviour()
  end
  if config.info and config.info ~= "" then
    RetentionHelper.Retention(PlatformDotType.uilog, {
      info = config.info
    })
  end
  if config.bgm == "home" then
    homeEnvManager:PlayHomeBgm()
  elseif config.bgm ~= "" then
    SoundManager.Instance:PlayMusic(config.bgm)
  end
  self.param = self.cs_page:GetParam()
  self:RegisterAllEvent()
  self:autoRegisterRedDot()
  self:__ShowScene()
  self:DoOnOpen()
end

function LuaUIPage:__ShowScene()
  local pageName = self:GetName()
  local config = configManager.GetDataById("config_ui_config", pageName)
  if config.page_type == 1 and config.canShowScene == 1 then
    GR.cameraManager:hideLastCamera()
  elseif config.page_type == 1 and config.canShowScene == 0 then
    GR.cameraManager:showLastCamera()
    eventManager:SendEvent(LuaEvent.HomeResetShip)
  end
end

function LuaUIPage:DoHide()
  self:UnregisterAllEvent()
  self:DestroyAllEffect()
  self:StopAllTimer()
  self:CloseTopPage()
  self:DoOnHide()
  eventManager:SendEvent(LuaEvent.OnPageHide, self:GetName())
end

function LuaUIPage:DoClose()
  self:UnregisterAllEvent()
  self:UnregisterAllRedDotEvent()
  self:DestroyAllEffect()
  self:StopAllTimer()
  self:CloseTopPage()
  self:DoOnClose()
  eventManager:SendEvent(LuaEvent.OnPageHide, self:GetName())
end

function LuaUIPage:RegisterAllEvent()
end

function LuaUIPage:autoRegisterRedDot()
  local redDotTable = self.cs_page:GetRedDotList()
  if not redDotTable then
    return
  end
  for i, redDot in pairs(redDotTable) do
    if redDot and redDot.autoRegister then
      self:RegisterRedDot(redDot)
    end
  end
end

function LuaUIPage:RegisterEvent(eventId, funcCallback)
  table.insert(self.tab_eventHandlers, {eventId, funcCallback})
  eventManager:RegisterEvent(eventId, funcCallback, self)
end

function LuaUIPage:UnregisterEvent(eventId, funcCallback)
  eventManager:UnregisterEvent(eventId, funcCallback, self)
end

function LuaUIPage:UnregisterAllById(eventId)
  for i = #self.tab_eventHandlers, 1, -1 do
    local eventParam = self.tab_eventHandlers[i]
    if eventParam[1] == eventId then
      self:UnregisterEvent(eventParam[1], eventParam[2])
      table.remove(self.tab_eventHandlers, i)
    end
  end
end

function LuaUIPage:UnregisterAllEvent()
  for i = 1, #self.tab_eventHandlers do
    local eventParam = self.tab_eventHandlers[i]
    self:UnregisterEvent(eventParam[1], eventParam[2])
  end
  self.tab_eventHandlers = {}
end

function LuaUIPage:UnregisterAllRedDotEvent()
  for id, v in pairs(self.redDot_eventHandlers) do
    self:UnRegisterRedDotById(id)
  end
  self.redDot_eventHandlers = {}
end

function LuaUIPage:UnRegisterRedDotById(id)
  local redDotEventTbl = self.redDot_eventHandlers[id]
  if redDotEventTbl then
    for index, funcCallback in pairs(redDotEventTbl) do
      self:UnregisterEvent(funcCallback[1], funcCallback[2])
    end
  end
  self.redDot_eventHandlers[id] = {}
end

function LuaUIPage:RegisterRedDotEvent(id, eventId, funcCallback)
  if self.redDot_eventHandlers[id] == nil then
    self.redDot_eventHandlers[id] = {}
  end
  table.insert(self.redDot_eventHandlers[id], {eventId, funcCallback})
  eventManager:RegisterEvent(eventId, funcCallback, self)
end

function LuaUIPage:OpenSubPage(pageName, param)
  if pageName ~= nil then
    eventManager:SendEvent(LuaEvent.OpenPage, pageName)
    local temp = OCDictionary("luaParam", param)
    return self.cs_page:OpenSubPage(pageName, temp)
  end
end

function LuaUIPage:CloseSubPage(pageName)
  if pageName ~= nil then
    self.cs_page:CloseSubPage(pageName)
  end
end

function LuaUIPage:SetAdditionOrder(order)
  self.cs_page:SetAdditionOrder(order)
end

function LuaUIPage:GetAdditionOrder()
  return self.cs_page:GetAdditionOrder()
end

function LuaUIPage:OpenTopPage(pageName, pageType, title, pageSelf, isEffect, closeFunc, customInfo)
  local topTable = {
    PageName = pageName,
    Title = title,
    PageType = pageType,
    IsEffect = isEffect,
    CloseFunc = closeFunc,
    CustomInfo = customInfo
  }
  local param = OCDictionary("luaParam", topTable)
  self.cs_page:ShowTopPage(param)
end

function LuaUIPage:OpenTopPageNoTitle(pageName, pageType, isEffect, closeFunc, customInfo)
  local config = configManager.GetDataById("config_ui_config", pageName)
  local title = config.topName
  self:OpenTopPage(pageName, pageType, title, nil, isEffect, closeFunc, customInfo)
end

function LuaUIPage:CloseTopPage()
  self.cs_page:HideTopPage()
end

function LuaUIPage:SetTopVisibleByPos(show)
  self.cs_page:SetTopPageVisibleByPos(show)
end

function LuaUIPage:CreateUIEffect(resPath, transParent)
  transParent = transParent or self.cs_page.gameObject.transform
  local effObj = UIHelper.CreateUIEffect(resPath, transParent)
  table.insert(self.m_effObjcts, effObj)
  return effObj
end

function LuaUIPage:DestroyAllEffect()
  if next(self.m_effObjcts) then
    for i, v in ipairs(self.m_effObjcts) do
      UIHelper.DestroyUIEffect(v)
    end
  end
  self.m_effObjcts = {}
end

function LuaUIPage:DestroyEffect(effObj)
  if next(self.m_effObjcts) then
    for k, v in ipairs(self.m_effObjcts) do
      if v == effObj then
        table.remove(self.m_effObjcts, k)
        UIHelper.DestroyUIEffect(effObj)
        return
      end
    end
  end
end

function LuaUIPage:CreateTimer(func, duration, loop, scale)
  local timer = Timer.New(func, duration, loop, scale)
  table.insert(self.m_timerTable, timer)
  return timer
end

function LuaUIPage:StartTimer(timer)
  if next(self.m_timerTable) then
    for k, v in pairs(self.m_timerTable) do
      if v == timer then
        timer:Start()
        return
      end
    end
  end
end

function LuaUIPage:ResetTimer(timer, func, duration, loop, scale)
  if next(self.m_timerTable) then
    for k, v in pairs(self.m_timerTable) do
      if v == timer then
        timer:Reset(func, duration, loop, scale)
        return
      end
    end
  end
end

function LuaUIPage:StopAllTimer()
  if next(self.m_timerTable) then
    for k, v in pairs(self.m_timerTable) do
      v:Stop()
    end
  end
  self.m_timerTable = {}
end

function LuaUIPage:StopTimer(timer)
  if next(self.m_timerTable) then
    for k, v in pairs(self.m_timerTable) do
      if v == timer then
        table.remove(self.m_timerTable, k)
        v:Stop()
        return
      end
    end
  end
end

function LuaUIPage:TryStopTimer(timer)
  if timer then
    self:StopTimer(timer)
    timer = nil
  end
end

function LuaUIPage:PerformDelay(delayTime, callback, timeScale)
  if callback == nil then
    return
  end
  local timer = Timer.New(function()
    callback()
  end, delayTime, 1, timeScale)
  table.insert(self.m_timerTable, timer)
  timer:Start()
  return timer
end

function LuaUIPage:DoInit()
end

function LuaUIPage:DoOnOpen()
end

function LuaUIPage:DoOnHide()
end

function LuaUIPage:DoOnClose()
end

function LuaUIPage:RegisterRedDotByParamList(redDot, redDotIdList, redDotParamList)
  redDot:SetKeys(redDotIdList)
  redDotManager:RegisterRedDotByParamList(self, redDot, redDotParamList)
end

function LuaUIPage:RegisterRedDotById(redDot, redDotIdList, ...)
  redDot:SetKeys(redDotIdList)
  self:RegisterRedDot(redDot, ...)
end

function LuaUIPage:RegisterRedDot(redDot, ...)
  redDotManager:RegisterRedDot(self, redDot, ...)
end

function LuaUIPage:SetDesignatedObjEnable(enable)
  self.cs_page:SetDesignatedObjEnable(enable)
end

function LuaUIPage:SetActiveSelf(_bool)
  self.cs_page.gameObject:SetActive(_bool)
end

function LuaUIPage:ShareComponentShow(show)
  self:SetDesignatedObjEnable(show)
  self:SetTopVisibleByPos(show)
end

return LuaUIPage
