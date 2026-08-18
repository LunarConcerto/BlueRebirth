local SportMeetData = class("data.SportMeetData", Data.BaseData)
local SportMeet = {
  AttackBee = 1,
  Track = 2,
  Steeplechase = 3
}
local sportActivity = {
  [1] = "AckBee",
  [2] = "Stee",
  [3] = "Track"
}

function SportMeetData:initialize()
  self:ResetData()
end

function SportMeetData:ResetData()
  self.AttackBeeData = {}
  self.TrackData = {}
  self.SteeplechaseData = {}
  self.mySportData = {}
  self.sportCopyData = {}
  self.sportTickCount = {}
  self.configData = {}
end

function SportMeetData:SetData(param)
  if param.Type == SportMeet.AttackBee then
    self.AttackBeeData = param.Data
  elseif param.Type == SportMeet.Track then
    self.TrackData = param.Data
  elseif param.Type == SportMeet.Steeplechase then
    self.SteeplechaseData = param.Data
  end
end

function SportMeetData:GetData(fucIndex)
  local data = {}
  if fucIndex == SportMeet.AttackBee then
    data = self.AttackBeeData
  elseif fucIndex == SportMeet.Track then
    data = self.TrackData
  elseif fucIndex == SportMeet.Steeplechase then
    data = self.SteeplechaseData
  end
  return data
end

function SportMeetData:SetMySportRankData(data)
  self.mySportData = data
  for i = 1, SportMeet.Steeplechase do
    local info = data[sportActivity[i]]
    self.sportCopyData[info.CopyId] = {
      data = data[sportActivity[i]] or {},
      copyId = info.CopyId
    }
  end
end

function SportMeetData:GetMySportRankData()
  return self.sportCopyData or nil
end

function SportMeetData:SetSportTickCount(data)
  self.sportTickCount = {}
  local freeList = {}
  for i = 1, #data.FreeCountList do
    local copydata = data.FreeCountList[i]
    freeList[copydata.CopyId] = copydata
  end
  self.sportTickCount.freeList = freeList
  self.sportTickCount.tickCount = data.TickCount
end

function SportMeetData:GetSportTickCount()
  return self.sportTickCount or {}
end

function SportMeetData:GetSportMeetRankConfigData()
  self.configData = configManager.GetData("config_sportsmeet_rank")
  return self.configData
end

function SportMeetData:SetCurrentSportConfigData()
  if self.configData == nil then
    self:GetSportMeetRankConfigData()
  end
  if self.rankData ~= nil then
    return self.rankData
  end
  self.rankData = {}
  for i = 1, #self.configData do
    local data = self.configData[i]
    if self.rankData[data.copy_id] == nil then
      self.rankData[data.copy_id] = {}
    end
    table.insert(self.rankData[data.copy_id], data)
  end
  return self.rankData
end

function SportMeetData:GetSportAtCfgDataByIndex(index)
  local data = self:SetCurrentSportConfigData()
  return data[index]
end

function SportMeetData:GetSportCfgByIndexRange(sportIndex, rangeIndex)
  local sportCfgData = self:GetSportAtCfgDataByIndex(sportIndex)
  for i, v in ipairs(sportCfgData) do
    if rangeIndex >= v.range[1] and rangeIndex <= v.range[2] then
      return v
    end
  end
end

function SportMeetData:GetSportAwardCfg()
  if self.sportAwardData == nil then
    self.sportAwardData = configManager.GetData("config_sportsmeet_award")
  end
  return self.sportAwardData
end

function SportMeetData:GetSportAwardCfgByPoint()
  local data = self:GetSportAwardCfg()
  if self.pointData ~= nil then
    return self.pointData, self.sportAwardData
  else
    self.pointData = {}
  end
  for i, v in ipairs(data) do
    if v.hot_point == 1 then
      table.insert(self.pointData, v)
    end
  end
  return self.pointData, self.sportAwardData
end

function SportMeetData:GetSettleMentData()
  local data = configManager.GetData("config_sportsmeet_score")
end

function SportMeetData:SetSportMeetPonits(data)
  self.sportMeetPonitsData = data
end

function SportMeetData:GetSportMeetScoreTimeString(copyId)
  local index = copyId % 10
  local timeStr = ""
  if index == 2 or index == 3 then
    timeStr = "s"
  end
  return timeStr
end

function SportMeetData:GetSportPointsCanRec()
  local canRec = false
  if self.sportMeetPonitsData ~= nil then
    local score = self.sportMeetPonitsData.TotalPoints
    if self.sportAwardData == nil then
      self:GetSportAwardCfg()
    end
    local canRecCount = 0
    for i = 1, #self.sportAwardData do
      local config = self.sportAwardData[i]
      if score >= config.score then
        canRecCount = canRecCount + 1
      end
    end
    if canRecCount > #self.sportMeetPonitsData.ReceivedList then
      canRec = true
    end
  end
  return canRec
end

return SportMeetData
