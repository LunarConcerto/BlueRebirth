local SportRankPage = class("UI.Sport.SportRankPage", LuaUIPage)
local SportMeet = {
  AttackBee = 1,
  Track = 2,
  Steeplechase = 3,
  All = 4
}
local SportMeetInfo = {
  [SportMeet.Steeplechase] = {
    index = 1,
    Name = UIHelper.GetString(920000822),
    rankIndex = 1
  },
  [SportMeet.Track] = {
    index = 2,
    Name = UIHelper.GetString(920000823),
    rankIndex = 3
  },
  [SportMeet.AttackBee] = {
    index = 3,
    Name = UIHelper.GetString(920000824),
    rankIndex = 2
  },
  [SportMeet.All] = {
    index = 4,
    Name = "",
    rankIndex = 1
  }
}

function SportRankPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.funcIndex = SportMeet.AttackBee
end

function SportRankPage:DoOnOpen()
  self.param = self:GetParam()
  self.periodId = self.param.periodId
  if self.param.copyList ~= nil then
    self.param.copyList = clone(self.param.copyList)
    table.sort(self.param.copyList, function(l, r)
      return l < r
    end)
  end
  self.copyId = self.param.copyId or self.param.copyList[3]
  self.funcIndex = self:GetIndex(self.copyId)
  self.rankData = Data.sportMeetData:GetSportMeetRankConfigData()
  self.HeadColor = configManager.GetDataById("config_parameter", 502).arrValue[1]
  self.OtherColor = configManager.GetDataById("config_parameter", 503).arrValue[1]
  self.RankImgArr = configManager.GetDataById("config_parameter", 504).arrValue
  self:LoadToggleInfo()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(self.funcIndex - 1)
  self:SetSportFinishTxt()
end

function SportRankPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    UIHelper.ClosePage("SportRankPage")
  end, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.Btn_PreviewReward, function()
    table.sort(self.param.copyList, function(l, r)
      return l < r
    end)
    local param = {
      copyId = self.copyId or self.param.copyList[self.funcIndex]
    }
    UIHelper.OpenPage("SportRankRewardPage", param)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_group, self, nil, self._ToggleChange)
end

function SportRankPage:_ToggleChange(index)
  self.funcIndex = index + 1
  self.copyIndex = self.funcIndex == 1 and 3 or self.funcIndex == 3 and 1 or self.funcIndex
  self.copyId = self.param.copyList[self.copyIndex]
  self:LoadRankInfo(self.funcIndex)
end

function SportRankPage:GetIndex(copyId)
  local index = 1
  if copyId then
    local tempIndex = copyId % 10
    if tempIndex == 1 then
      index = 3
    elseif tempIndex == 3 then
      index = 1
    else
      index = 2
    end
  end
  return index
end

function SportRankPage:LoadToggleInfo()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_toggle, self.m_tabWidgets.trs_toggle, SportMeet.All - 1, function(index, part)
    UIHelper.SetText(part.txt_name, SportMeetInfo[index].Name)
    UIHelper.SetText(part.txt_ckeck, SportMeetInfo[index].Name)
    self.tab_Widgets.tog_group:RegisterToggle(part.Toggle)
  end)
end

function SportRankPage:SetSportFinishTxt()
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(self.periodId)
  local day, hour, min = time.getDHMDiff(endTime)
  UIHelper.SetText(self.m_tabWidgets.tx_time, day .. UIHelper.GetString(920000021) .. hour .. UIHelper.GetString(920000031) .. min .. UIHelper.GetString(920000032))
end

function SportRankPage:LoadRankInfo(fucIndex)
  self.currentRankData = Data.sportMeetData:GetData(self.copyId % 10)
  if self.currentRankData == nil then
    return
  end
  self:SetPlayerInfo(self.currentRankData.MyRank)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trs_content, #self.currentRankData.RankList, function(index, part)
    local data = self.currentRankData.RankList[index]
    self:SetPartData(part, data, false)
  end)
end

function SportRankPage:SetPlayerInfo(data)
  local part = self.m_tabWidgets.luaPart:GetLuaTableParts()
  if data.UserInfo and next(data.UserInfo) == nil then
    local user = Data.userData:GetUserData()
    data.UserInfo = user
  end
  self:SetPartData(part, data, true)
end

function SportRankPage:SetPartData(part, data, isUser)
  if data == nil then
    return
  end
  local index = data.RankNo or 4
  local color = 3 < index and self.OtherColor or self.HeadColor
  local imgStr = 3 < index and self.RankImgArr[4] or self.RankImgArr[index]
  local scoreStr = data and (data.FastestTime or data.HighestScore) or 0
  if scoreStr == 0 then
    scoreStr = "\227\129\170\227\129\151"
  else
    scoreStr = scoreStr .. Data.sportMeetData:GetSportMeetScoreTimeString(self.copyId)
  end
  if isUser then
    UIHelper.SetText(part.tx_rankNum, data.RankNo or "\229\156\143\229\164\150")
    UIHelper.SetText(part.tx_score, scoreStr)
    UIHelper.SetText(part.tx_guildName, data.UserInfo.GuildName or "")
    UIHelper.SetText(part.tx_username, data.UserInfo.Uname or "")
    local serName = Logic.loginLogic.SDKInfo and Logic.loginLogic.SDKInfo.name or UIHelper.GetString(920000277)
    serName = string.format(UIHelper.GetString(2200082), serName)
    UIHelper.SetText(part.tx_servername, serName)
    UIHelper.SetImage(part.im_bg, imgStr)
  else
    UIHelper.SetTextColor(part.tx_rankNum, data.RankNo or "\229\156\143\229\164\150", color)
    UIHelper.SetTextColor(part.tx_score, scoreStr, color)
    UIHelper.SetTextColor(part.tx_guildName, data.UserInfo.GuildName or "", color)
    UIHelper.SetTextColor(part.tx_username, data.UserInfo.Uname or "", color)
    local serName = data.UserInfo.ServerId
    if platformManager:getServiceList() and 0 < #platformManager:getServiceList() then
      serName = Logic.serverLogic:GetServerNameById(data.UserInfo.ServerId)
      serName = string.format(UIHelper.GetString(2200082), serName)
    end
    UIHelper.SetTextColor(part.tx_servername, serName or data.UserInfo.ServerId, color)
    UIHelper.SetImage(part.im_bg, imgStr)
  end
  if data.UserInfo and next(data.UserInfo) == nil then
    logError("\231\148\168\230\136\183\228\191\161\230\129\175\231\169\186\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129")
    return
  end
  local icon, quality = Data.userData:GetUserHeadIcon(data.UserInfo)
  local frame, frameInfo = Logic.playerHeadFrameLogic:GetHeadFrameByUid(data.UserInfo)
  UIHelper.SetImage(part.im_girl, icon)
  UIHelper.SetImage(part.im_frame, frameInfo.icon)
end

return SportRankPage
