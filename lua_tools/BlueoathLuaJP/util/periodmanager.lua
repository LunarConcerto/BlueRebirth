PeriodManager = {}
PeriodManager = class("PeriodManager")
local REF = {
  LOCAL = 1,
  WEEK = 2,
  SINCE = 3,
  DAY = 4,
  MONTH = 5,
  CREATE = 6,
  SINCE_WEEK_PERIOD = 7,
  SINCE_DAY_PERIOD = 8,
  ODD_MONTH = 9
}
REFID_PERDAY = 1
STATUSTIME = {
  PERIOD_REFRESH_BEFORE = 1,
  PERIOD_REFRESH_CURRENT = 2,
  PERIOD_REFRESH_AFTER = 3
}
MAX_END_TIME = 2000000000

function PeriodManager:setPeriod(periodId)
  self.mRec = configManager.GetDataById("config_period", periodId)
  self.mCheckTime = time.getSvrTime()
  self:calTime()
  self.mDurationTime = self.mRec.duration
end

function PeriodManager:GetDaysFromTime(timeStart)
  local rec = configManager.GetDataById("config_refresh", 1)
  local cal = os.date("*t", timeStart)
  cal.hour = rec.p4
  cal.min = rec.p5
  cal.sec = rec.p6
  local t = os.time(cal)
  local now = time.getSvrTime()
  return math.floor((now - t) / 3600 / 24) + 1
end

function PeriodManager:GetSvrStartDay()
  local timeStart = time.getSvrStartTime()
  return self:getDaysFromTime(timeStart)
end

function PeriodManager:calTime()
  local timeNow = self.mCheckTime
  local timeStart = time.getSvrStartTime()
  local rec = self.mRec
  local switch = {
    [REF.LOCAL] = function()
      local cal = os.date("*t", timeNow)
      cal.year = rec.p1
      cal.month = rec.p2
      cal.day = rec.p3
      return cal
    end,
    [REF.WEEK] = function()
      local cal = os.date("*t", timeNow)
      local wday = rec.p1 + 1
      cal.day = cal.day + (wday - cal.wday)
      return cal
    end,
    [REF.SINCE] = function()
      local cal = os.date("*t", timeStart)
      cal.day = cal.day + rec.p3
      return cal
    end,
    [REF.DAY] = function()
      local cal = os.date("*t", timeNow)
      return cal
    end,
    [REF.MONTH] = function()
      local cal = os.date("*t", timeNow)
      cal.day = rec.p3
      return cal
    end,
    [REF.CREATE] = function()
      local ctime = Data.userData:GetCreateTime()
      local cal = os.date("*t", ctime)
      cal.hour = rec.p4
      cal.min = rec.p5
      cal.sec = rec.p6
      local rtime = os.time(cal)
      if ctime < rtime then
        cal.day = cal.day + rec.p3 - 1
      else
        cal.day = cal.day + rec.p3
      end
      return cal
    end,
    [REF.SINCE_WEEK_PERIOD] = function()
      local cal = os.date("*t", timeStart)
      cal.day = cal.day - cal.wday + 1 + rec.p3 % 7
      cal.hour = rec.p4
      cal.min = rec.p5
      cal.sec = rec.p6
      local periodTime = 604800 * rec.p1
      local tt = os.time(cal)
      local time = timeNow - tt
      local num = math.floor(time / periodTime)
      local periodStart = tt + num * periodTime + (rec.p2 - 1) * 86400 * 7
      cal = os.date("*t", periodStart)
      return cal
    end,
    [REF.SINCE_DAY_PERIOD] = function()
      local cal = os.date("*t", timeStart)
      cal.day = cal.day + rec.p3 % 7
      cal.hour = rec.p4
      cal.min = rec.p5
      cal.sec = rec.p6
      local periodTime = 604800 * rec.p1
      local tt = os.time(cal)
      local time = timeNow - tt
      if time < 0 then
        time = 0
      end
      local num = math.floor(time / periodTime)
      local periodStart = tt + num * periodTime + (rec.p2 - 1) * 86400 * 7
      cal = os.date("*t", periodStart)
      return cal
    end,
    [REF.ODD_MONTH] = function()
      local cal = os.date("*t", timeNow)
      if rec.p1 == 1 then
        if cal.month % 2 == 0 then
          cal.month = cal.month - 1
        end
      elseif rec.p1 == 2 and cal.month % 2 ~= 0 then
        cal.month = cal.month - 1
      end
      cal.day = rec.p3
      cal.hour = rec.p4
      cal.min = rec.p5
      cal.sec = rec.p6
      local rtime = os.time(cal)
      if rtime > timeNow then
        cal.month = cal.month - 2
      end
      return cal
    end
  }
  local f = switch[rec.type]
  if f == nil then
    return false
  end
  local cal_last = f()
  cal_last.hour = rec.p4
  cal_last.min = rec.p5
  cal_last.sec = rec.p6
  self.mLastDate = cal_last
  self.mLastTime = os.time(cal_last)
  if timeNow < self.mLastTime then
    self.mLastTime = self:prev()
  end
  if rec.start_time and rec.start_time > 0 and self.mLastTime < rec.start_time then
    self.mLastTime = rec.start_time
  end
end

function PeriodManager:prev()
  local rec = self.mRec
  local switch = {
    [REF.WEEK] = function(t)
      t.day = t.day - 7
      return t
    end,
    [REF.DAY] = function(t)
      t.day = t.day - 1
      return t
    end,
    [REF.MONTH] = function(t)
      t.month = t.month - 1
      return t
    end,
    [REF.ODD_MONTH] = function(t)
      t.month = t.month - 2
      return t
    end
  }
  local f = switch[rec.type]
  local lastTime = self.mLastTime
  if f ~= nil then
    local t = f(self.mLastDate)
    lastTime = os.time(t)
  end
  return lastTime
end

function PeriodManager:next()
  local rec = self.mRec
  local switch = {
    [REF.WEEK] = function(t)
      t.day = t.day + 7
      return t
    end,
    [REF.DAY] = function(t)
      t.day = t.day + 1
      return t
    end,
    [REF.MONTH] = function(t)
      t.month = t.month + 1
      return t
    end,
    [REF.SINCE_WEEK_PERIOD] = function(t)
      t.day = t.day + rec.p1 * 7
      return t
    end,
    [REF.SINCE_DAY_PERIOD] = function(t)
      t.day = t.day + rec.p1 * 7
      return t
    end,
    [REF.ODD_MONTH] = function(t)
      t.month = t.month + 2
      return t
    end
  }
  local f = switch[rec.type]
  local nextTime = 0
  if f ~= nil then
    local t = f(self.mLastDate)
    nextTime = os.time(t)
  end
  return nextTime
end

function PeriodManager:getDurationArea()
  local durationCur = time.getSvrTime() - self.mLastTime
  for idx, duration in ipairs(self.mRec.duration_list) do
    durationCur = durationCur - duration
    if durationCur < 0 then
      return idx
    end
  end
  return #self.mRec.duration_list
end

function PeriodManager:IsInPeriods(periodIdList)
  local periodIds = periodIdList
  if type(periodIdList) ~= "table" then
    periodIds = {periodIdList}
  end
  for i, periodId in pairs(periodIds) do
    if PeriodManager:IsInPeriod(periodId) then
      return true
    end
  end
  return false
end

function PeriodManager:IsInPeriod(periodId)
  self:setPeriod(periodId)
  local timeNow = time.getSvrTime()
  local sp = timeNow - self.mLastTime
  if sp < 0 then
    return false
  end
  if 0 < self.mDurationTime and sp > self.mDurationTime then
    return false
  end
  if self.mRec.end_time and 0 < self.mRec.end_time and timeNow >= self.mRec.end_time then
    return false
  end
  return true
end

function PeriodManager:IsInPeriodArea(periodId, periodArea)
  self:setPeriod(periodId)
  local timeNow = time.getSvrTime()
  local sp = timeNow - self.mLastTime
  if sp < 0 then
    return false
  end
  if 0 < self.mDurationTime and sp > self.mDurationTime then
    return false
  end
  if self.mRec.end_time and 0 < self.mRec.end_time and timeNow >= self.mRec.end_time then
    return false
  end
  if #periodArea < 1 then
    return true
  end
  local idx = self:getDurationArea()
  for i, v in ipairs(periodArea) do
    if v == idx then
      return true
    end
  end
  return false
end

function PeriodManager:GetNextPeriodStartTime()
  local timeNow = time.getSvrTime()
  local t = self.mLastTime
  if timeNow > t then
    t = self:next()
  end
  return t
end

function PeriodManager:GetPeriodStartTime()
  return self.mLastTime
end

function PeriodManager:GetPeriodEndTime()
  local timeNow = time.getSvrTime()
  if self.mDurationTime == 0 then
    if self.mRec.end_time and 0 < self.mRec.end_time then
      return self.mRec.end_time
    end
    return MAX_END_TIME
  end
  local lastEndTime = self.mLastTime + self.mDurationTime
  if self.mRec.end_time and 0 < self.mRec.end_time and lastEndTime >= self.mRec.end_time then
    lastEndTime = self.mRec.end_time
  end
  return lastEndTime
end

function PeriodManager:GetCurrStartTime()
  return self.mLastTime
end

function PeriodManager:setRefresh(refreshId)
  self.mRec = configManager.GetDataById("config_refresh", refreshId)
  self.mCheckTime = time.getSvrTime()
  self:calTime()
end

function PeriodManager:CheckRefresh(refreshId, reftime)
  self:setRefresh(refreshId)
  logDebug("checkRefresh(" .. tostring(refreshId) .. "," .. tostring(reftime) .. ")")
  if reftime >= self.mLastTime then
    return 0
  end
  local rec = self.mRec
  local switch = {
    [REF.WEEK] = 604800,
    [REF.DAY] = 86400
  }
  local basesp = switch[rec.type]
  if not basesp then
    return 1
  end
  self.mCheckTime = reftime
  self:calTime()
  local timeNow = time.getSvrTime()
  logDebug("timeNow =" .. tostring(timeNow) .. ", basesp = " .. tostring(basesp) .. ")")
  return math.floor((timeNow - self.mLastTime) / basesp)
end

function PeriodManager:GetNextRefreshTime(refreshId)
  self:setRefresh(refreshId)
  local timeNow = time.getSvrTime()
  local t = self.mLastTime
  if timeNow > t then
    t = self:next()
  end
  return t
end

function PeriodManager:GetCurrRefreshTime(refreshId)
  self:setRefresh(refreshId)
  local timeNow = time.getSvrTime()
  local t = self.mLastTime
  return t
end

function PeriodManager:GetNextRefreshTimeInIds(refreshIds)
  if #refreshIds == 0 then
    logError("Period refreshids len can not be 0")
    return 0
  end
  local t = self:GetNextRefreshTime(refreshIds[1])
  for i = 2, #refreshIds do
    local nextTime = self:GetNextRefreshTime(refreshIds[i])
    if t > nextTime then
      t = nextTime
    end
  end
  return t
end

function PeriodManager:GetStatusTimeInRefreshAndPeriod(refreshId, periodId)
  PeriodManager:setPeriod(periodId)
  local periodSTime = self.mLastTime
  local timeNow = time.getSvrTime()
  logDebug("Period time now is ", os.date("*t", timeNow))
  logDebug("Period period start time is ", os.date("*t", periodSTime))
  local endtime = self.mLastTime + self.mDurationTime
  if self.mDurationTime == 0 then
    endtime = MAX_END_TIME
  end
  if self.mRec.end_time and 0 < self.mRec.end_time and endtime > self.mRec.end_time then
    endtime = self.mRec.end_time
  end
  if periodSTime <= timeNow and timeNow < endtime then
    return STATUSTIME.PERIOD_REFRESH_CURRENT
  end
  PeriodManager:setRefresh(refreshId)
  local refreshSTime = self.mLastTime
  logDebug("Period refresh start time is ", os.date("*t", refreshSTime))
  if periodSTime < refreshSTime then
    return STATUSTIME.PERIOD_REFRESH_BEFORE
  else
    return STATUSTIME.PERIOD_REFRESH_AFTER
  end
end

function PeriodManager:IsInSameRefreshDay(t1, t2)
  local refreshRec = configManager.GetDataById("config_refresh", 1)
  local dt = refreshRec.p4 * 3600 + refreshRec.p5 * 60 + refreshRec.p6
  t1 = t1 - dt
  t2 = t2 - dt
  local d1 = os.date("*t", math.abs(t1))
  local d2 = os.date("*t", math.abs(t2))
  local ret = d1.year == d2.year and d1.month == d2.month and d1.day == d2.day
  return ret
end

function PeriodManager:GetTodayRefreshStartTime()
  local refreshRec = configManager.GetDataById("config_refresh", 1)
  local dt = refreshRec.p4 * 3600 + refreshRec.p5 * 60 + refreshRec.p6
  local now = time.getSvrTime()
  local nowDate = os.date("*t", now)
  local passed = nowDate.hour * 3600 + nowDate.min * 60 + nowDate.sec
  if dt < passed then
    return now - passed + dt
  end
  return now - 86400 - passed + dt
end

function PeriodManager:GetStartAndEndPeriodTime(periodId)
  PeriodManager:setPeriod(periodId)
  local endtime = self.mLastTime + self.mDurationTime
  if self.mDurationTime == 0 then
    endtime = MAX_END_TIME
  end
  if self.mRec.end_time and 0 < self.mRec.end_time and endtime > self.mRec.end_time then
    endtime = self.mRec.end_time
  end
  return self.mLastTime, endtime
end

function PeriodManager:GetStartAndEndPeriodListTime(periodId)
  PeriodManager:setPeriod(periodId)
  local periodList = 0
  for v, k in pairs(self.mRec.duration_list) do
    periodList = periodList + k
  end
  return self.mLastTime, self.mLastTime + periodList
end

function PeriodManager:GetStartAndEndPeriodFirstListTime(periodId, openId)
  local actvityData = configManager.GetDataById("config_activity", openId)
  return self:GetPeriodTime(periodId, actvityData.p1)
end

function PeriodManager:GetPeriodTime(periodId, periodArea)
  if periodArea == nil or #periodArea <= 0 then
    return PeriodManager:GetStartAndEndPeriodTime(periodId)
  end
  PeriodManager:setPeriod(periodId)
  local startTime, endTime = PeriodManager:GetPeriodTimeByIndex(periodId, periodArea[1])
  if #self.mRec.duration_list ~= 0 then
    for i = 2, #periodArea do
      local startTimeNew, endTimeNew = PeriodManager:GetPeriodTimeByIndex(periodId, periodArea[i])
      startTime = math.min(startTime, startTimeNew)
      endTime = math.max(endTime, endTimeNew)
    end
  end
  return startTime, endTime
end

function PeriodManager:GetOnePeriodTimeByIndex(periodId, periodIndex)
  PeriodManager:setPeriod(periodId)
  local startTime, endTime = PeriodManager:GetPeriodTimeByIndex(periodId, periodIndex)
  return startTime, endTime
end

function PeriodManager:GetPeriodTimeByIndex(periodId, periodIndex)
  local lastEndTime = 0
  local startTime = 0
  if periodIndex <= 0 or periodIndex > #self.mRec.duration_list then
    logError("GetPeriodTimeByIndex periodIndex err. periodIndex:%s, len:%s", periodIndex, #self.mRec.duration_list)
    return
  end
  if #self.mRec.duration_list ~= 0 then
    for k, v in ipairs(self.mRec.duration_list) do
      if periodIndex > k then
        startTime = startTime + self.mRec.duration_list[k]
      elseif k == periodIndex then
        lastEndTime = self.mRec.duration_list[k]
        break
      end
    end
  end
  return self.mLastTime + startTime, self.mLastTime + startTime + lastEndTime
end

function PeriodManager:GetCountDownPeriodTime(periodId)
  PeriodManager:setPeriod(periodId)
  local timeNow = time.getSvrTime()
  local sp = timeNow - self.mLastTime
  if sp < 0 then
    return -1
  end
  if 0 < self.mDurationTime and sp > self.mDurationTime then
    return -1
  end
  local duration = self.mDurationTime
  if self.mDurationTime == 0 then
    duration = MAX_END_TIME
  end
  if self.mRec.end_time and 0 < self.mRec.end_time and timeNow + duration >= self.mRec.end_time then
    duration = self.mRec.end_time - timeNow
  end
  if sp > duration then
    return -1
  end
  return duration - sp
end
