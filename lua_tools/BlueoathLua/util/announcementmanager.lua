local AnnouncementManager = class("util.AnnouncementManager")
local json = require("cjson")

function AnnouncementManager:initialize()
  self.closetime = nil
  self.opentime = nil
  self.openState = 0
  self.timer = nil
  self.upcomingTimer = nil
  self.enableAnn = false
  self.opened = false
  self.tabId = nil
  self.upcomingTimer = nil
  eventManager:RegisterEvent(LuaEvent.UpdateGameAdv, self._UpdateGameAdv, self)
  self.activeOpenTimer = nil
  self.activeCloseTimer = nil
  self.activeOpenTime = nil
  self.activeCloseTime = nil
  eventManager:RegisterEvent(LuaEvent.UpdateWebActivity, self._UpdateWebActivity, self)
end

function AnnouncementManager:_UpdateGameAdv(ret)
  if ret then
    self:_UpdateAnnouncement(ret)
  else
    self:_NoneSuperNotice()
  end
end

function AnnouncementManager:GetAnnouncementState()
  platformManager:GameAnnouncementState(function(ret)
    self:_SuperNoticeCallBack(ret)
  end)
end

function AnnouncementManager:_UpdateAnnouncement(ret)
  local noticesInfo = ret.AdvIdList
  self.opentime = nil
  self.closetime = 0
  self.tabId = {}
  self.notices = {}
  if noticesInfo then
    local serverTime = time.getSvrTime()
    for i = 1, #noticesInfo do
      local tab = {
        id = noticesInfo[i].AdvId,
        begin_time = noticesInfo[i].BeginTime,
        end_time = noticesInfo[i].EndTime
      }
      table.insert(self.notices, tab)
      if serverTime < noticesInfo[i].EndTime then
        if serverTime >= noticesInfo[i].BeginTime then
          table.insert(self.tabId, noticesInfo[i].AdvId)
          if noticesInfo[i].EndTime > self.closetime then
            self.closetime = noticesInfo[i].EndTime
          end
        elseif not self.opentime then
          self.opentime = noticesInfo[i].BeginTime
        elseif noticesInfo[i].BeginTime < self.opentime then
          self.opentime = noticesInfo[i].BeginTime
        end
      end
    end
  end
  self:_ShowSuperNotice()
end

function AnnouncementManager:_SuperNoticeCallBack(ret)
  if ret then
    local info = ret.data
    if info and 0 < #info then
      local noticesInfo = clone(info)
      local length = #noticesInfo
      self.opentime = nil
      self.closetime = 0
      self.tabId = {}
      self.notices = {}
      local serverTime = time.getSvrTime()
      for i = 1, length do
        local tab = {
          id = noticesInfo[i].id,
          begin_time = noticesInfo[i].begin_time,
          end_time = noticesInfo[i].end_time
        }
        table.insert(self.notices, tab)
        if serverTime < self.notices[i].end_time then
          if serverTime >= noticesInfo[i].begin_time then
            table.insert(self.tabId, noticesInfo[i].id)
            if noticesInfo[i].end_time > self.closetime then
              self.closetime = noticesInfo[i].end_time
            end
          elseif not self.opentime then
            self.opentime = noticesInfo[i].begin_time
          elseif noticesInfo[i].begin_time < self.opentime then
            self.opentime = noticesInfo[i].begin_time
          end
        end
      end
      self:_ShowSuperNotice()
    end
  end
end

function AnnouncementManager:_CloseSuperNotice()
  self:_ResetData()
  eventManager:SendEvent(LuaEvent.AnnouncementState, self.openState == 2)
end

function AnnouncementManager:_RefreshAnnouncement()
  self.opentime = nil
  self.closetime = nil
  self.tabId = {}
  if self.notices and #self.notices > 0 then
    local serverTime = time.getSvrTime()
    self.closetime = 0
    for i = 1, #self.notices do
      if serverTime < self.notices[i].end_time then
        if serverTime >= self.notices[i].begin_time then
          table.insert(self.tabId, self.notices[i].id)
          if self.notices[i].end_time > self.closetime then
            self.closetime = self.notices[i].end_time
          end
        elseif not self.opentime then
          self.opentime = self.notices[i].begin_time
        elseif self.notices[i].begin_time < self.opentime then
          self.opentime = self.notices[i].begin_time
        end
      end
    end
  end
  self:_ShowSuperNotice()
end

function AnnouncementManager:_ShowSuperNotice()
  local have = false
  self.openState = 0
  if self.tabId and 0 < #self.tabId then
    self.openState = self:GetOpenState()
    have = true
    if self.enableAnn and self.openState == 2 then
      self:_AnnouncementTimer()
    end
  end
  if self.opentime and 0 < self.opentime then
    have = true
    if self.enableAnn then
      self:_UpcomingTimer()
    end
  end
  if not have then
    self:_ResetData()
  end
  eventManager:SendEvent(LuaEvent.AnnouncementState, self.openState == 2)
end

function AnnouncementManager:_NoneSuperNotice()
  self:_ResetData()
  eventManager:SendEvent(LuaEvent.AnnouncementState, self.openState == 2)
end

function AnnouncementManager:_ResetData()
  self.openState = 0
  self.closetime = nil
  self.opentime = nil
  self.tabId = nil
  self.opened = false
  self.notices = nil
  self:_StopTimer()
  self:_StopUpcomingTimer()
end

function AnnouncementManager:_AnnouncementTimer()
  self:_StopTimer()
  local serverTime = time.getSvrTime()
  local duration = self.closetime - serverTime
  self.timer = Timer.New(function()
    self:_RefreshAnnouncement()
  end, duration, 1, true)
  self.timer:Start()
end

function AnnouncementManager:_UpcomingTimer()
  self:_StopUpcomingTimer()
  local serverTime = time.getSvrTime()
  local duration = self.opentime - serverTime
  self.upcomingTimer = Timer.New(function()
    self:_RefreshAnnouncement()
  end, duration, 1, true)
  self.upcomingTimer:Start()
end

function AnnouncementManager:EnableAnnouncement()
  self.enableAnn = true
  self:_ShowSuperNotice()
  self:_ShowActiveBrowse()
end

function AnnouncementManager:DisableAnnoucement()
  self:_StopUpcomingTimer()
  self:_StopTimer()
  self:_StopActivityOpenTimer()
  self:_StopActivityCloseTimer()
  self.enableAnn = false
end

function AnnouncementManager:_StopTimer()
  if self.timer then
    self.timer:Stop()
  end
  self.timer = nil
end

function AnnouncementManager:_StopUpcomingTimer()
  if self.upcomingTimer then
    self.upcomingTimer:Stop()
  end
  self.upcomingTimer = nil
end

function AnnouncementManager:GetOpenState()
  self.openState = 0
  if self.closetime then
    local serverTime = time.getSvrTime()
    if serverTime < self.closetime then
      self.openState = 2
    end
  end
  return self.openState
end

function AnnouncementManager:OpenAnnouncement(funcCallBack)
  if self.tabId then
    local uid = Data.userData:GetUserUid()
    local key = uid .. "MaintanceId"
    local strId = json.encode(self.tabId)
    PlayerPrefs.SetString(key, strId)
    if isWindows and not isEditor then
      local serverId = Logic.loginLogic.SDKInfo.groupid
      local category = 7
      self.cacheCallBack = funcCallBack
      eventManager:RegisterEvent(LuaEvent.CloseWebView, self._CloseWebView, self)
      platformManager:getSuperNoticeAndOpen(serverId, 1000, 532, -1, -1, nil, category, "\231\179\187\231\187\159\229\133\172\229\145\138")
    else
      local param = {
        aType = AnnouncementType.Maintenance,
        callBack = function()
          self.opened = true
          if funcCallBack then
            funcCallBack()
          end
        end
      }
      UIHelper.OpenPage("AnnouncementPage", param, 5)
    end
    eventManager:SendEvent(LuaEvent.OpenAnnouncement)
  else
    self.opened = true
    if funcCallBack then
      funcCallBack()
    end
  end
end

function AnnouncementManager:_CloseWebView()
  self.opened = true
  eventManager:UnregisterEvent(LuaEvent.CloseWebView, self._CloseWebView)
  if self.cacheCallBack then
    self.cacheCallBack()
    self.cacheCallBack = nil
  end
end

function AnnouncementManager:HaveRedDot()
  local uid = Data.userData:GetUserUid()
  local key = uid .. "MaintanceId"
  local strId = PlayerPrefs.GetString(key, "")
  local record = json.decode(strId)
  if self.tabId then
    if record then
      for i = 1, #self.tabId do
        local id = self.tabId[i]
        local have = false
        for j = 1, #record do
          if record[j] == id then
            have = true
            break
          end
        end
        if not have then
          return true
        end
      end
    else
      return true
    end
  end
  return false
end

function AnnouncementManager:Opened()
  return self.opened
end

function AnnouncementManager:_UpdateWebActivity(ret)
  if ret then
    self:_UpdateBrowseActivity(ret)
  end
end

function AnnouncementManager:_UpdateBrowseActivity(ret)
  local str = ret.Activity
  local bInfo = json.decode(str)
  self:_StopActivityOpenTimer()
  self:_StopActivityCloseTimer()
  self.browseInfo = {}
  self.activeOpenTime = nil
  self.activeCloseTime = nil
  for k, v in pairs(bInfo) do
    local item = clone(v)
    item.content = v.content
    item.actId = self:_GeteBrowseId(item.content)
    self.browseInfo[v.id] = item
    local serverTime = time.getSvrTime()
    if serverTime < item.begin_time then
      if self.activeOpenTime == nil then
        self.activeOpenTime = {}
      end
      table.insert(self.activeOpenTime, item.begin_time)
    end
    if self.activeCloseTime == nil then
      self.activeCloseTime = {}
    end
    table.insert(self.activeCloseTime, item.end_time)
  end
  if self.activeOpenTime then
    table.sort(self.activeOpenTime, function(data1, data2)
      return data1 < data2
    end)
  end
  if self.activeCloseTime then
    table.sort(self.activeCloseTime, function(data1, data2)
      return data1 < data2
    end)
  end
  self:_RefreshActiveBrowse()
end

function AnnouncementManager:SetBrowseActiveInfo()
  self.browseInfo = {}
  self:_StopActivityOpenTimer()
  self:_StopActivityCloseTimer()
  local info = platformManager:GetBrowseInfo()
  local serverTime = time.getSvrTime()
  self.activeOpenTime = nil
  self.activeCloseTime = nil
  for k, v in pairs(info) do
    for p, q in pairs(v) do
      local item = clone(q)
      item.content = q.content
      item.actId = self:_GeteBrowseId(item.content)
      self.browseInfo[q.id] = item
      if serverTime < item.begin_time then
        if self.activeOpenTime == nil then
          self.activeOpenTime = {}
        end
        table.insert(self.activeOpenTime, item.begin_time)
      end
      if self.activeCloseTime == nil then
        self.activeCloseTime = {}
      end
      table.insert(self.activeCloseTime, item.end_time)
    end
  end
  if self.activeOpenTime then
    table.sort(self.activeOpenTime, function(data1, data2)
      return data1 < data2
    end)
  end
  if self.activeCloseTime then
    table.sort(self.activeCloseTime, function(data1, data2)
      return data1 < data2
    end)
  end
  self:_RefreshActiveBrowse()
end

function AnnouncementManager:GetActiveBrowseList()
  local result = {}
  local serverTime = time.getSvrTime()
  if self.browseInfo then
    for k, v in pairs(self.browseInfo) do
      if self:_GetBrowseOpen(k, serverTime) then
        table.insert(result, v)
      end
    end
    table.sort(result, function(data1, data2)
      return data1.ordernum > data2.ordernum
    end)
  end
  return result
end

function AnnouncementManager:_GetBrowseOpen(id, serverTime)
  if id ~= nil and self.browseInfo and self.browseInfo[id] then
    local info = self.browseInfo[id]
    if serverTime < info.begin_time or serverTime >= info.end_time then
      return false
    end
    if info.extended_one and info.extended_one.lv then
      local lv = info.extended_one.lv
      local min_lv = lv.begin == "" and 0 or tonumber(lv.begin)
      local max_lv = lv["end"] == "" and Mathf.Infinity or tonumber(lv["end"])
      local limit = self:_CheckBrowseLvLimit(min_lv, max_lv)
      if not limit then
        return false
      end
    end
    local actId = info.actId
    if actId then
      local tabValue = Logic.homeLogic:GetAnswerQuestion()
      if tabValue then
        for k, v in pairs(tabValue) do
          if tostring(v) == tostring(actId) then
            return false
          end
        end
      end
    else
      return false
    end
  else
    return false
  end
  return true
end

function AnnouncementManager:_CheckBrowseLvLimit(min_lv, max_lv)
  local lv, ok = Data.userData:GetLevel()
  if ok then
    return min_lv <= lv and max_lv >= lv
  end
  return ok
end

function AnnouncementManager:_GeteBrowseId(str)
  if conditionCheckManager:Checkvalid(str) then
    local i = string.find(str, "actid=")
    if i then
      local j = string.find(str, "&")
      if j then
        local id = string.sub(str, i + 6, j - 1)
        return id
      else
        local id = string.sub(str, i + 6, #str)
        return id
      end
    end
  end
end

function AnnouncementManager:_ShowActiveBrowse()
  local serverTime = time.getSvrTime()
  local temp = {}
  if self.activeOpenTime then
    for i = 1, #self.activeOpenTime do
      if serverTime < self.activeOpenTime[i] then
        table.insert(temp, self.activeOpenTime[i])
      end
    end
  end
  self.activeOpenTime = temp
  temp = {}
  if self.activeCloseTime then
    for i = 1, #self.activeCloseTime do
      if serverTime < self.activeCloseTime[i] then
        table.insert(temp, self.activeCloseTime[i])
      end
    end
  end
  self.activeCloseTime = temp
  local oT = self.activeOpenTime and self.activeOpenTime[1] or nil
  local cT = self.activeCloseTime and self.activeCloseTime[1] or nil
  if oT then
    self:_ActiveOpenTimer(oT)
  end
  if cT then
    self:_ActiveCloseTimer(cT)
  end
end

function AnnouncementManager:_RefreshActiveBrowse()
  eventManager:SendEvent(LuaEvent.RefreshActiveBrowse)
  if self.enableAnn then
    self:_ShowActiveBrowse()
  end
end

function AnnouncementManager:_ActiveOpenTimer(opentime)
  self:_StopActivityOpenTimer()
  local serverTime = time.getSvrTime()
  local duration = opentime - serverTime
  self.activeOpenTimer = Timer.New(function()
    self:_RefreshActiveBrowse()
  end, duration, 1, true)
  self.activeOpenTimer:Start()
end

function AnnouncementManager:_ActiveCloseTimer(closetime)
  self:_StopActivityCloseTimer()
  local serverTime = time.getSvrTime()
  local duration = closetime - serverTime
  self.activeCloseTimer = Timer.New(function()
    self:_RefreshActiveBrowse()
  end, duration, 1, true)
  self.activeCloseTimer:Start()
end

function AnnouncementManager:_StopActivityOpenTimer()
  if self.activeOpenTimer then
    self.activeOpenTimer:Stop()
  end
  self.activeOpenTimer = nil
end

function AnnouncementManager:_StopActivityCloseTimer()
  if self.activeCloseTimer then
    self.activeCloseTimer:Stop()
  end
  self.activeCloseTimer = nil
end

return AnnouncementManager
