time = {}
local m_timeDiff = 0
local m_svrStartTime = 0
local ostimeold = os.time
local osdateold = os.date
local strYear, strMonth, strDay, strHour, strMin, strSecond, strBefore, strAfter, strOver, strMins, strHours, strColon
local bInit = true

function time.checkInit()
  if bInit then
    bInit = false
    strYear = "\229\185\180"
    strMonth = "\230\156\136"
    strDay = "\229\164\169"
    strHour = "\230\151\182"
    strMin = "\229\136\134"
    strSecond = "\231\167\146"
    strBefore = "\229\137\141"
    strAfter = "\229\144\142"
    strOver = "\229\136\176\230\156\159"
    strMins = "\229\136\134\233\146\159"
    strHours = "\229\176\143\230\151\182"
    strColon = ":"
  end
end

function time.syncTime(svrTimeInterval)
  m_timeDiff = os.time() - svrTimeInterval
  return m_timeDiff
end

function time.getSvrTime()
  return TimeUtil.GetServerTime() + 1
end

function time.setSvrStartTime(t)
  m_svrStartTime = t
end

function time.getSvrStartTime()
  return m_svrStartTime
end

function time.getTimeZoneOffset()
  local offset = platformManager:GetTimeZoneOffset()
  if offset then
    return offset * 60
  else
    return -32400
  end
end

function os.time(...)
  local args = {
    ...
  }
  local ret = ostimeold(args[1])
  if ret == nil then
    logError("time conf is err  %s", args[1])
    return 1847483647
  end
  return ret + time.getOffsetFromLocalToSvr()
end

function time.getOffsetFromLocalToSvr()
  local now = ostimeold()
  local localOffset = os.difftime(now, ostimeold(osdateold("!*t", now)))
  local localSvrOffset = localOffset + time.getTimeZoneOffset()
  return localSvrOffset
end

function os.date(format, t)
  local ret_time
  if format == "*t" and t ~= nil then
    ret_time = osdateold("*t", t - time.getOffsetFromLocalToSvr())
  else
    ret_time = osdateold(format, t)
  end
  return ret_time
end

function time.getWeekday()
  local curTime = time.getSvrTime()
  local temp = os.date("*t", curTime)
  local wday = tonumber(temp.wday)
  local ret = wday - 1
  if ret == 0 then
    return 7
  else
    return ret
  end
end

function time.getIntervalByTime(nTime)
  local curTime = time.getSvrTime()
  local temp = os.date("*t", curTime)
  local h, m, s = string.match(string.format("%06d", nTime), "(%d%d)(%d%d)(%d%d)")
  local timeString = temp.year .. "-" .. temp.month .. "-" .. temp.day .. " " .. h .. ":" .. m .. ":" .. s
  local timeInt = time.getIntervalByTimeString(timeString)
  return timeInt
end

function time.isSameDay(time1, time2)
  local day1s = math.floor((time1 - time.getTimeZoneOffset()) / 86400)
  local day2s = math.floor((time2 - time.getTimeZoneOffset()) / 86400)
  return day1s == day2s
end

function time.isSameWeek(t1, t2)
  local SECOND_OF_WEEK = 604800
  local baseTime = time.getIntervalByTimeString("1970-03-02 00:00:00")
  t1 = t1 - baseTime
  t2 = t2 - baseTime
  return math.floor(t1 / SECOND_OF_WEEK) == math.floor(t2 / SECOND_OF_WEEK)
end

function time.expireTimeString(nGenTime, nDuration)
  local nNow = time.getSvrTime()
  local nViewSec = (nDuration or 0) - (nNow - nGenTime or 0)
  return time.getHoursString(nViewSec), nViewSec <= 0, nViewSec
end

function time.getDaysBetween(checkTime, offset)
  checkTime = tonumber(checkTime or 0)
  offset = tonumber(offset or 0)
  local curTime = tonumber(time.getSvrTime()) - offset
  if os.date("%j", curTime) == 1 and os.date("%j", checkTime - offset) ~= 1 then
    return os.date("%j", curTime) - (os.date("%j", checkTime - offset) - os.date("%j", curTime - 86400))
  else
    return os.date("%j", curTime) - os.date("%j", checkTime - offset)
  end
end

function time.getServerStartDay()
  local curTime = tonumber(time.getSvrTime())
  local serverOpenTime = tonumber(time.getSvrStartTime())
  local rec = configManager.GetDataById("config_refresh", 1)
  local cal = os.date("*t", serverOpenTime)
  cal.hour = rec.p4
  cal.min = rec.p5
  cal.sec = rec.p6
  local targetTime = os.time(cal)
  local diff = curTime - targetTime
  if diff <= 0 then
    return 0
  end
  local days = diff / 86400
  return math.ceil(days)
end

function time.getDaysDiff(checkTime, isCeil)
  checkTime = tonumber(checkTime or 0)
  local curTime = tonumber(time.getSvrTime())
  local diff = curTime - checkTime
  if diff < 0 then
    diff = diff * -1
  end
  local days = diff / 86400
  if isCeil ~= nil and isCeil then
    days = math.ceil(days)
  else
    days = math.floor(days)
  end
  return days
end

function time.getDHMDiff(checkTime)
  checkTime = tonumber(checkTime or 0)
  local curTime = tonumber(time.getSvrTime())
  local diff = curTime - checkTime
  if diff < 0 then
    diff = diff * -1
  end
  local temp = diff / 86400
  local day, t2 = math.modf(temp)
  local hour, t3 = math.modf(t2 * 24)
  return day, hour, math.floor(t3 * 60)
end

function time.getIntervalByString(sTime)
  if sTime == 0 then
    return 0
  end
  if string.len(sTime) ~= 14 then
    logError("Time.getIntervalByString value = " .. tostring(sTime))
    return nil
  end
  local tDate_y = string.sub(sTime, 1, 4)
  local tDate_m = string.sub(sTime, 5, 6)
  local tDate_d = string.sub(sTime, 7, 8)
  local tTime_h = string.sub(sTime, 9, 10)
  local tTime_m = string.sub(sTime, 11, 12)
  local tTime_s = string.sub(sTime, 13, 14)
  local tt = os.time({
    year = tDate_y,
    month = tDate_m,
    day = tDate_d,
    hour = tTime_h,
    min = tTime_m,
    sec = tTime_s
  })
  local ut = os.date("*t", tt)
  local east8 = os.time(ut)
  return east8
end

function time.getIntervalByTimeString(sTime)
  local t = string.split(sTime, " ")
  local tDate = string.split(t[1], "-")
  local tTime = string.split(t[2], ":")
  local tt = os.time({
    year = tDate[1],
    month = tDate[2],
    day = tDate[3],
    hour = tTime[1],
    min = tTime[2],
    sec = tTime[3]
  })
  local ut = os.date("*t", tt)
  local east8 = os.time(ut)
  return east8
end

function time.getAppointTimer(appoint_timer, t)
  local temp = os.date("*t", appoint_timer)
  local h, m, s = string.match(string.format("%06d", t), "(%d%d)(%d%d)(%d%d)")
  local timeString = temp.year .. "-" .. temp.month .. "-" .. temp.day .. " " .. h .. ":" .. m .. ":" .. s
  local appointTimer = time.getIntervalByTimeString(timeString)
  return appointTimer
end

function time.formatTimeToYMDHMS(m_time)
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. "-" .. string.format("%02d", temp.month) .. "-" .. string.format("%02d", temp.day) .. " " .. string.format("%02d", temp.hour) .. ":" .. string.format("%02d", temp.min) .. ":" .. string.format("%02d", temp.sec)
  return timeString
end

function time.formatTimerToYMDH(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. strYear .. string.format("%02d", temp.month) .. strMonth .. string.format("%02d", temp.day) .. strDay .. string.format("%02d", temp.hour) .. strHour
  return timeString
end

function time.formatTimerToYearMonth(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. string.format("%02d", temp.month)
  return timeString
end

function time.formatTimerToY(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.year
  return timeString
end

function time.formatTimerToM(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = string.format("%02d", temp.month)
  return timeString
end

function time.formatTimerToD(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = string.format("%02d", temp.day)
  return timeString
end

function time.formatTimerToHMSColon(m_time)
  local temp = os.date("*t", m_time)
  local timeString = string.format("%02d", temp.hour) .. ":" .. string.format("%02d", temp.min) .. ":" .. string.format("%02d", temp.sec)
  return timeString
end

function time.formatTimerToMDHM(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.month .. "-" .. string.format("%02d", temp.day) .. " " .. string.format("%02d", temp.hour) .. strColon .. string.format("%02d", temp.min)
  return timeString
end

function time.str2time(strTime, numNow)
  if not strTime then
    logError("Time.str2time param is nil")
    return nil
  end
  local tabTime = os.date("*t", numNow)
  local nLen = #tostring(strTime)
  return os.time({
    year = tabTime.year,
    month = tabTime.month,
    day = tabTime.day,
    hour = tonumber(string.sub(strTime, nLen - 5, nLen - 4)) or 0,
    min = tonumber(string.sub(strTime, nLen - 3, nLen - 2)) or 0,
    sec = tonumber(string.sub(strTime, nLen - 1, nLen)) or 0
  })
end

function time.getMinutesString(checkTime)
  if tonumber(checkTime) <= 0 then
    return "00:00"
  else
    return string.format("%02d:%02d", math.floor(checkTime / 60 % 60), checkTime % 60)
  end
end

function time.getHoursString(checkTime)
  if tonumber(checkTime) <= 0 then
    return "00:00:00"
  else
    return string.format("%02d:%02d:%02d", math.floor(checkTime / 3600), math.floor(checkTime / 60 % 60), checkTime % 60)
  end
end

function time.getTimeStringFont(timeInt)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return "00" .. strHour .. "00" .. strMin .. "00" .. strSecond
  else
    return string.format("%02d%s%02d%s%02d%s", math.floor(timeInt / 3600), strHour, math.floor(timeInt / 60 % 60), strMin, timeInt % 60, strSecond)
  end
end

function time.getTimeStringFontMinute(timeInt)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return string.format("00%s00%s", strMin, strSecond)
  else
    return string.format("%02d%s%02d%s", math.floor(timeInt / 60 % 60), strMin, timeInt % 60, strSecond)
  end
end

function time.getTimeStringFontOnly(timeInt, fillZero)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return "00" .. strSecond
  else
    local day = math.floor(timeInt / 86400)
    timeInt = timeInt % 86400
    local hour = math.floor(timeInt / 3600)
    local min = math.floor(timeInt / 60 % 60)
    local second = timeInt % 60
    local result = ""
    local fmtstr = "%02d%s"
    if fillZero ~= nil and fillZero == false then
      fmtstr = "%d%s"
    end
    if 0 < day then
      return string.format(fmtstr, day, strDay)
    elseif 0 < hour then
      return string.format(fmtstr, hour, strHours)
    elseif 0 < min then
      return string.format(fmtstr, min, strMin)
    elseif 0 < second then
      return string.format(fmtstr, second, strSecond)
    else
      return string.format(fmtstr, 0, strSecond)
    end
  end
end

function time.getTimeStringFontTwo(timeInt, keepZero)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return string.format("%02d%s%02d%s", 0, strMin, 0, strSecond)
  else
    local day = math.floor(timeInt / 86400)
    timeInt = timeInt % 86400
    local hour = math.floor(timeInt / 3600)
    local min = math.floor(timeInt / 60 % 60)
    local second = timeInt % 60
    local result = ""
    if 0 < day then
      return string.format("%02d%s%02d%s", day, strDay, hour, strHours)
    elseif 0 < hour then
      return string.format("%02d%s%02d%s", hour, strHours, min, strMin)
    else
      return string.format("%02d%s%02d%s", min, strMin, second, strSecond)
    end
  end
end

function time.getTimeStringFontDynamic(timeInt, keepZero)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return "00" .. strHours .. "00" .. strMin .. "00" .. strSecond
  else
    local day = math.floor(timeInt / 86400)
    timeInt = timeInt % 86400
    local hour = math.floor(timeInt / 3600)
    local min = math.floor(timeInt / 60 % 60)
    local second = timeInt % 60
    local result = ""
    if 0 < day then
      result = string.format("%02d%s", day, strDay)
    end
    if 0 < hour or hour <= 0 and 0 < day and keepZero then
      result = string.format("%s%02d%s", result, hour, strHours)
    end
    if 0 < min or min <= 0 and keepZero then
      result = string.format("%s%02d%s", result, min, strMin)
    end
    if 0 < second or second <= 0 and keepZero then
      result = string.format("%s%02d%s", result, second, strSecond)
    end
    return result
  end
end

function time.formatTimeToHour(timeInt, keepZero)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return "00" .. strHours .. "00" .. strMin .. "00" .. strSecond
  else
    local day = math.floor(timeInt / 86400)
    timeInt = timeInt % 86400
    local hour = math.floor(timeInt / 3600)
    local result = ""
    if 0 < day then
      result = string.format("%02d%s", day, strDay)
    end
    if 0 < hour or hour <= 0 and 0 < day and keepZero then
      result = string.format("%s%02d%s", result, hour, strHours)
    end
    return result
  end
end

function time.getTimeStringDynamic(timeInt)
  time.checkInit()
  if tonumber(timeInt) <= 0 then
    return "00:00:00"
  else
    local day = math.floor(timeInt / 86400)
    timeInt = timeInt % 86400
    local hour = math.floor(timeInt / 3600)
    local min = math.floor(timeInt / 60 % 60)
    local second = timeInt % 60
    local result = ""
    if 0 < day then
      result = string.format("%02d:", day)
    end
    if 0 < hour or hour <= 0 and 0 < day then
      result = string.format("%s%02d:", result, hour)
    end
    result = string.format("%s%02d:", result, min)
    result = string.format("%s%02d", result, second)
    return result
  end
end

function time.formatTimerToDHMS(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  local timeString = m_day .. strDay .. m_hour .. strHour .. m_min .. strMin .. m_sec .. strSecond
  return timeString
end

function time.formatTimerToDHMS(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  m_sec = string.format("%02d", m_sec)
  local timeString = m_day .. strDay .. m_hour .. strHour .. m_min .. strMin .. m_sec .. strSecond
  return timeString
end

function time.formatTimerToDHMSColor(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  return string.format(UIHelper.GetString(810010013), m_day, m_hour, m_min, m_sec)
end

function time.formatTimerToDHM(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  m_sec = string.format("%02d", m_sec)
  local timeString = m_day .. strDay .. m_hour .. strHour .. m_min .. strMin
  return timeString
end

function time.formatTimerToHMS(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = string.format("%02d", lastScend)
  local timeString = m_hour .. strHour .. m_min .. strMin .. m_sec .. strSecond
  return timeString
end

function time.formatTimerToHMSColonTime(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  local timeString = m_hour .. strColon .. m_min .. strColon .. m_sec
  return timeString
end

function time.formatTimerToHMSColonZeroTime(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  if m_hour < 10 then
    m_hour = "0" .. m_hour
  end
  if m_min < 10 then
    m_min = "0" .. m_min
  end
  if m_sec < 10 then
    m_sec = "0" .. m_sec
  end
  local timeString = m_hour .. strColon .. m_min .. strColon .. m_sec
  return timeString
end

function time.formatTimerToOnlyTime(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  if 0 < m_day then
    return m_day .. strDay .. strBefore
  end
  if 0 < m_hour then
    return m_hour .. strHours .. strBefore
  end
  if 0 < m_min then
    return m_min .. strMins .. strBefore
  end
  if 0 < m_sec then
    return m_sec .. strSecond .. strBefore
  end
end

function time.formatTimerToOverTime(m_timer)
  time.checkInit()
  local temp_timer = m_timer
  local dayToScend = 86400
  local m_day = math.floor(temp_timer / dayToScend)
  local lastScend = temp_timer - m_day * dayToScend
  local m_hour = math.floor(lastScend / 3600)
  lastScend = lastScend - m_hour * 3600
  local m_min = math.floor(lastScend / 60)
  lastScend = lastScend - m_min * 60
  local m_sec = lastScend
  if 0 < m_day then
    return m_day .. strDay .. strAfter .. strOver
  end
  if 0 < m_hour then
    return m_hour .. strHours .. strAfter .. strOver
  end
  if 0 < m_min then
    return m_min .. strMins .. strAfter .. strOver
  end
  if 0 < m_sec then
    return m_sec .. strSecond .. strAfter .. strOver
  end
end

function time.inAPeriod(nTimeBegin, nTimeEnd, nTimeBetween)
  return nTimeBegin < nTimeBetween and nTimeBetween < nTimeEnd
end

function time.GetCurMonthAndDays()
  local cur = time.getSvrTime()
  local temp = os.date("*t", cur)
  local year, month = temp.year, temp.month + 1
  local dayAmount = os.date("%d", os.time({
    year = year,
    month = month,
    day = 0
  }))
  return month - 1, dayAmount
end

function time.formatTimeToYMD(m_time)
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. "." .. string.format("%d", temp.month) .. "." .. string.format("%d", temp.day)
  return timeString
end

function time.formatTimeToYMDHM(m_time)
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. "." .. string.format("%02d", temp.month) .. "." .. string.format("%02d", temp.day) .. " " .. string.format("%02d", temp.hour) .. ":" .. string.format("%02d", temp.min)
  return timeString
end

function time.formatTimeToMDHM(m_time)
  local temp = os.date("*t", m_time)
  local timeString = temp.month .. "." .. string.format("%02d", temp.day) .. " " .. string.format("%02d", temp.hour) .. ":" .. string.format("%02d", temp.min)
  return timeString
end

function time.formatTimerToYMD(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.year .. strYear .. string.format("%02d", temp.month) .. strMonth .. string.format("%02d", temp.day) .. "\230\151\165"
  return timeString
end

function time.formatTimerToMDH(m_time)
  time.checkInit()
  local temp = os.date("*t", m_time)
  local timeString = temp.month .. "\230\156\136" .. string.format("%02d", temp.day) .. "\230\151\165" .. string.format("%02d", temp.hour) .. ":" .. string.format("%02d", temp.min)
  return timeString
end
