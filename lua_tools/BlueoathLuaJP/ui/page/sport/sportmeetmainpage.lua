local SportMeetMainPage = class("UI.Sport.SportChallengePage", LuaUIPage)
local FromRank = 1
local ToRank = 200
local isPassCopyId = 1610100

function SportMeetMainPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.partContainer = {}
  self.isFirst = false
end

function SportMeetMainPage:DoOnOpen()
  self.param = self:GetParam()
  self.activityId = self.param.activityId
  self.activityType = self.param.activityType
  self.diffArr = configManager.GetDataById("config_parameter", 500).arrValue
  if self.activityId then
    local config = configManager.GetDataById("config_activity", self.activityId)
    if config then
      self.param.p2 = config.p2[1]
      self.param.period = config.period
    end
  end
  self.periodInfo = configManager.GetDataById("config_period", self.param.period)
  self.chapterInfo = configManager.GetDataById("config_chapter", self.param.p2)
  self:CreateCopyItem()
  Service.sportMeetService:GetUserRankData()
  self:GetRankData()
  self:GetTickCount()
  self:SetSportFinishTxt()
  self:ShowMask()
  self:SetRedDot()
end

function SportMeetMainPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_help, function()
    logError("help")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_rank, function()
    UIHelper.OpenPage("SportRankPage", {
      periodId = self.param.period,
      copyList = self.chapterInfo.level_list
    })
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_reward, function()
    UIHelper.OpenPage("SportScoreRewardPage")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_mask, function()
    noticeManager:ShowMsgBox(UIHelper.GetString(920000818))
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTips, function()
    noticeManager:ShowMsgBox(UIHelper.GetString(920000819))
  end, self)
  self:RegisterEvent(LuaEvent.UpdateSportInfo, self.SetUserSportRankInfo, self)
  self:RegisterEvent(LuaEvent.UpdateSportTickInfo, self.SetSportFreeInfo, self)
  self:RegisterEvent(LuaEvent.GetSportRewardRecInfo, function()
    local isShow = Data.sportMeetData:GetSportPointsCanRec()
    self.m_tabWidgets.obj_redDot:SetActive(isShow)
  end, self)
end

function SportMeetMainPage:ShowMask()
  local copyData = Data.copyData:GetCopyInfoById(isPassCopyId)
  self.m_tabWidgets.btn_mask.gameObject:SetActive(copyData == nil or copyData.FirstPassTime == 0)
  local isInPeriod = PeriodManager:IsInPeriod(self.param.period)
  self.m_tabWidgets.btn_closeTips.gameObject:SetActive(not isInPeriod)
end

function SportMeetMainPage:SetRedDot()
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  PlayerPrefs.SetBool(uid .. "SportMeetMainPage", false)
  eventManager:SendEvent(LuaEvent.UpdateSportRedDot)
end

function SportMeetMainPage:GetRankData()
  local arg = {FromRankNo = FromRank, ToRankNo = ToRank}
  for i = 1, 3 do
    arg.type = i
    Service.sportMeetService:GetSportRankData(arg)
  end
end

function SportMeetMainPage:GetTickCount()
  Service.sportMeetService:GetUserSportTickData()
  Service.sportMeetService:GetPointsRewardDetailData()
end

function SportMeetMainPage:SetUserSportRankInfo()
  local sportMeetData = Data.sportMeetData:GetMySportRankData()
  for i, v in pairs(self.partContainer) do
    local data = sportMeetData[i]
    local rankStr = data and data.data.RankNo or 0
    if rankStr == 0 then
      rankStr = "\227\129\170\227\129\151"
    end
    local scoreStr = data and (data.data.FastestTime or data.data.HighestScore) or 0
    if scoreStr == 0 then
      scoreStr = "\227\129\170\227\129\151"
    else
      scoreStr = scoreStr .. Data.sportMeetData:GetSportMeetScoreTimeString(i)
    end
    UIHelper.SetText(v.part.text_RankNum, rankStr)
    UIHelper.SetText(v.part.text_ScoreNum, scoreStr)
  end
end

function SportMeetMainPage:GetRefreshTime()
  local now = time.getSvrTime()
  local startY = time.formatTimerToY(now)
  local startM = time.formatTimerToM(now)
  local startD = Mathf.Floor(time.formatTimerToD(now) + 1)
  if string.len(startM) < 2 then
    startM = "0" .. startM
  end
  if string.len(startD) < 2 then
    startD = "0" .. startD
  end
  local refreshSTr = startY .. startM .. startD .. "00" .. "00" .. "00"
  local refreshTime = Mathf.Floor(time.getIntervalByString(refreshSTr))
  return refreshTime
end

function SportMeetMainPage:SetSportFreeInfo()
  local sportMeetData = Data.sportMeetData:GetSportTickCount()
  UIHelper.SetText(self.m_tabWidgets.txt_num, sportMeetData.tickCount)
  local isOpenTimer = false
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.param.period)
  local periodconfig = configManager.GetDataById("config_period", self.param.period)
  local now = time.getSvrTime()
  local startY = time.formatTimerToY(now)
  local startM = time.formatTimerToM(now)
  local startD = Mathf.Floor(time.formatTimerToD(now) + 1)
  if string.len(startM) < 2 then
    startM = "0" .. startM
  end
  if string.len(startD) < 2 then
    startD = "0" .. startD
  end
  local refreshSTr = startY .. startM .. startD .. "00" .. "00" .. "00"
  local refreshTime = Mathf.Floor(time.getIntervalByString(refreshSTr))
  for i, v in pairs(self.partContainer) do
    local data = sportMeetData.freeList[i]
    if data ~= nil then
      local str = self:GetTimeStr(refreshTime)
      UIHelper.SetText(v.part.txt_cd, str)
      v.part.obj_freetTips:SetActive(data.FreeCount > 0)
      v.part.obj_cd:SetActive(data.FreeCount <= 0)
      if data.FreeCount <= 0 then
        isOpenTimer = true
      end
    else
      logError("\231\129\173\230\156\137\231\155\184\229\133\179\231\154\132\230\180\187\229\138\168")
    end
  end
  if sportMeetData.tickCount <= 0 then
    isOpenTimer = true
  end
  self.m_tabWidgets.obj_ticketTime:SetActive(sportMeetData.tickCount <= 0)
  local day = math.floor(time.getSvrTime() / 86400)
  if self.copyTimer ~= nil then
    self:StopTimer(self.copyTimer)
    self.copyTimer = nil
  end
  self.copyTimer = self:CreateTimer(function()
    if refreshTime < time.getSvrTime() then
      refreshTime = self:GetRefreshTime()
      Service.sportMeetService:GetUserSportTickData()
      for i, v in pairs(self.partContainer) do
        local str = self:GetTimeStr(refreshTime)
        UIHelper.SetText(v.part.txt_cd, str)
        v.part.obj_freetTips:SetActive(true)
        v.part.obj_cd:SetActive(false)
      end
    end
    local str = self:GetTimeStr(refreshTime)
    for i, v in pairs(self.partContainer) do
      local data = sportMeetData[i]
      UIHelper.SetText(v.part.txt_cd, str)
    end
    UIHelper.SetText(self.m_tabWidgets.txt_ticketTime, str)
    self:SetSportFinishTxt()
  end, 1, -1, false)
  self:StartTimer(self.copyTimer)
end

function SportMeetMainPage:SetSportFinishTxt()
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.param.period)
  local day, hour, min = time.getDHMDiff(endTime)
  UIHelper.SetText(self.m_tabWidgets.txt_remainTime, day .. UIHelper.GetString(920000021) .. hour .. UIHelper.GetString(920000031) .. min .. UIHelper.GetString(920000032))
end

function SportMeetMainPage:GetTimeStr(endTime)
  local nowTime = time.getSvrTime()
  local diff = endTime - nowTime
  if diff < 0 then
    diff = diff * -1
  end
  local temp = diff % 86400
  local hour = math.floor(temp / 3600)
  local min = math.floor(temp / 60 % 60)
  local second = temp % 60
  return hour .. ":" .. min .. ":" .. second
end

function SportMeetMainPage:CreateCopyItem()
  self.copyList = self.chapterInfo.level_list
  local sportCopyData = Data.sportMeetData:GetMySportRankData()
  self.copyImgArr = configManager.GetDataById("config_parameter", 505).arrValue
  table.sort(self.copyList, function(l, r)
    return r < l
  end)
  UIHelper.CreateSubPart(self.m_tabWidgets.item_copy, self.m_tabWidgets.trans_Copy, #self.copyList, function(index, part)
    local copydisplay = configManager.GetDataById("config_copy_display", self.copyList[index])
    local sportData = sportCopyData and sportCopyData[self.copyList[index]] or nil
    local tabDropInfo = Logic.copyLogic:GetDropInfo()
    UIHelper.SetImage(part.img_bg, self.copyImgArr[index])
    local trs = part.img_bg.gameObject.transform.localPosition
    if not self.isFirst then
      part.img_bg.gameObject.transform.localPosition = Vector3.New(trs.x + self.diffArr[index][1], trs.y + self.diffArr[index][2], trs.z)
    end
    self.tabSerData = Data.copyData:GetCopyInfoById(self.copyList[index])
    local dropIds = copydisplay.drop_info_id
    local DropInfoType = {firstPassReward = 3}
    for i, v in ipairs(dropIds) do
      if tabDropInfo[v].type == DropInfoType.firstPassReward and self.tabSerData and self.tabSerData.FirstPassTime ~= 0 then
        table.remove(dropIds, i)
        break
      end
    end
    dropIds = Logic.copyLogic:FilterDropId(dropIds)
    local dropInfo = DropRewardsHelper.GetDropDisplay(dropIds)
    self:CreateDropItem(part, dropIds, dropInfo)
    UGUIEventListener.AddButtonOnClick(part.btn_enter, function()
      UIHelper.OpenPage("SportChallengePage", {
        copyId = self.copyList[index],
        periodId = self.param.period,
        chapterInfo = self.chapterInfo
      })
    end)
    self.partContainer[self.copyList[index]] = {part = part}
  end)
  self.isFirst = true
end

function SportMeetMainPage:CreateDropItem(part, dropIds, dropInfo)
  UIHelper.CreateSubPart(part.item_reward, part.con_drop, #dropInfo, function(nIndex, nPart)
    local displayInfo = dropInfo[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(nPart.Image, displayInfo.icon)
    UIHelper.SetText(nPart.tx_dropRate, itemInfo.drop_rate)
    UGUIEventListener.AddButtonOnClick(nPart.btn_dropitem, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, dropIds)
    end)
  end)
end

return SportMeetMainPage
