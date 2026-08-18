local SportScoreRewardPage = class("UI.Sport.SportScoreRewardPage", LuaUIPage)

function SportScoreRewardPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.partContainer = {}
  self.scorePointsCon = {}
end

function SportScoreRewardPage:DoOnOpen()
  self.param = self:GetParam()
  self.pointData, self.awardData = Data.sportMeetData:GetSportAwardCfgByPoint()
  self:LoadRewardInfo(self.awardData)
  self:LoadPointsInfo(self.pointData)
  self:GetPointsRewardDetailData()
  self:LoadContentPoint(self.pointData[1])
end

function SportScoreRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, function()
    UIHelper.ClosePage("SportScoreRewardPage")
  end, self)
  self:RegisterEvent(LuaEvent.GetSportRewardRecInfo, self.GetSportRewardRecInfo, self)
  self:RegisterEvent(LuaEvent.ReceiveRewardBack, self.ReceiveRewardBack, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_receive, function()
    local canRec = self:GetAllReceiveState()
    if canRec then
      Service.sportMeetService:GetAllPointsReward()
    else
      noticeManager:ShowTip(UIHelper.GetString(920000821))
    end
  end, self)
  UGUIEventListener.AddOnScrollRectChangedCB(self.m_tabWidgets.scr_content.gameObject, self.OnValueChanged, self)
end

function SportScoreRewardPage:GetPointsRewardDetailData()
  Service.sportMeetService:GetPointsRewardDetailData()
end

function SportScoreRewardPage:OnValueChanged(go, value)
  value = tostring(value)
  local var = string.sub(value, 2)
  local floatV = string.sub(var, 1, 8)
  floatV = floatV + 0.0
  local currentScore = 0
  if floatV < 0 then
    floatV = 0
  end
  if 1 < floatV then
    floatV = 1
  end
  local all = #self.awardData
  local num = Mathf.Ceil(all * floatV)
  if num < 1 then
    num = 1
  end
  if all <= num then
    num = all
  end
  local orederLarge = true
  if currentScore < self.awardData[num].score then
    orederLarge = true
  else
    orederLarge = false
  end
  local nextData = self:GetNextPointData(self.awardData[num].score, orederLarge)
  if nextData ~= nil then
    currentScore = nextData.score
    self:LoadContentPoint(nextData)
  end
end

function SportScoreRewardPage:GetNextPointData(score, isLarge)
  local nextPointData = clone(self.pointData)
  for i = 1, #nextPointData do
    local data = nextPointData[i]
    if score < data.score then
      if isLarge then
        return data
      elseif 1 < i then
        return nextPointData[i - 1]
      end
    end
  end
  return nil
end

function SportScoreRewardPage:Test()
  UIHelper.CreateSubPart(self.m_tabWidgets.item_obj, self.m_tabWidgets.trs_con, 20, function(index, part)
    UIHelper.SetText(part.txt_score, index)
  end)
end

local temdata

function SportScoreRewardPage:LoadContentPoint(data)
  temdata = data
  local part = self.m_tabWidgets.luaPart:GetLuaTableParts()
  local rewardConfig = data
  UIHelper.SetText(part.txt_score, rewardConfig.score .. "PT")
  local rewardId = rewardConfig.rewards
  local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
  local isReceive = self:GetReceiveDeatilByScore(rewardConfig.score)
  local isReach = self.totalScore and self.totalScore >= rewardConfig.score or false
  local rewardInfo = rewards[1]
  local itemType = rewardInfo[1]
  local itemId = rewardInfo[2]
  local num = rewardInfo[3]
  local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
  local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
  UIHelper.SetImage(part.icon, icon)
  UIHelper.SetImageByQuality(part.img_bg, quality)
  UIHelper.SetText(part.txt_num, "x" .. num)
  part.img_unlock.gameObject:SetActive(not isReach)
  part.img_check.gameObject:SetActive(isReceive)
  part.img_canRec.gameObject:SetActive(isReach and not isReceive)
end

function SportScoreRewardPage:LoadPointsInfo(data)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_score, self.m_tabWidgets.trs_pointsCon, #data, function(index, part)
    local pointData = data[index]
    UIHelper.SetText(part.txt_score, pointData.score .. "PT")
    part.obj_check:SetActive(false)
    part.obj_reach:SetActive(false)
    local scoreData = {
      index = index,
      part = part,
      data = pointData
    }
    self.scorePointsCon[pointData.score] = scoreData
  end)
end

function SportScoreRewardPage:LoadRewardInfo(data)
  UIHelper.CreateSubPart(self.m_tabWidgets.item_obj, self.m_tabWidgets.trs_con, #data, function(index, part)
    local rewardConfig = data[index]
    UIHelper.SetText(part.txt_score, rewardConfig.score .. "PT")
    local rewardId = rewardConfig.rewards
    local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
    local showRewards = Logic.rewardLogic:FormatReward(rewards)
    local rewardInfo = rewards[1]
    local itemType = rewardInfo[1]
    local itemId = rewardInfo[2]
    local num = rewardInfo[3]
    local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
    local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
    UIHelper.SetImage(part.icon, icon)
    UIHelper.SetImageByQuality(part.img_bg, quality)
    UIHelper.SetText(part.txt_num, "x" .. num)
    part.img_unlock.gameObject:SetActive(true)
    part.img_check.gameObject:SetActive(false)
    part.img_canRec.gameObject:SetActive(false)
    
    local function clickFunc()
      self:SendGetReward(rewardConfig.score)
    end
    
    UGUIEventListener.AddButtonOnClick(part.btn_icon, function()
      self:GetRewardBack(rewardConfig.score, showRewards)
    end)
    self.partContainer[rewardConfig.score] = part
  end)
end

function SportScoreRewardPage:GetRewardBack(score, reward)
  local isReceived = self:GetReceiveDeatilByScore(score)
  local isReach = score <= self.totalScore
  local state = RewardState.UnReceivable
  if isReceived then
    state = RewardState.Received
  elseif not isReceived and isReach then
    state = RewardState.Receivable
  else
    state = RewardState.UnReceivable
  end
  
  local function back()
    self:SendGetReward(score)
    UIHelper.ClosePage("BoxRewardPage")
  end
  
  UIHelper.OpenPage("BoxRewardPage", {
    rewardState = state,
    rewards = reward,
    callback = back
  })
end

function SportScoreRewardPage:SendGetReward(piont)
  if self:GetReceiveDeatilByScore(piont) then
    logError("isReceive")
    return
  elseif piont > self.ScorePt then
    noticeManager:ShowTip(UIHelper.GetString(920000820))
    return
  end
  Service.sportMeetService:GetPointsReward(piont)
end

function SportScoreRewardPage:GetSportReceiveInfo()
end

function SportScoreRewardPage:GetSportRewardRecInfo(data)
  local isShow = Data.sportMeetData:GetSportPointsCanRec()
  self.m_tabWidgets.obj_redDot:SetActive(isShow)
  self.ScorePt = data.TotalPoints
  UIHelper.SetText(self.m_tabWidgets.txt_score, data.TotalPoints)
  if self.MaxScore == nil then
    self.MaxScore = self.awardData[#self.awardData].score
  end
  local slider = self.m_tabWidgets.Slider
  self.totalScore = data.TotalPoints
  self.receiveList = data.ReceivedList
  local value = self:GetSliderValue(data.TotalPoints)
  slider.value = value
  if next(data.ReceivedList) ~= nil then
    table.sort(data.ReceivedList, function(l, r)
      return l < r
    end)
  end
  self:RefreshScoreCon(self.receiveList)
  if temdata == nil then
    self:LoadContentPoint(self.pointData[1])
  else
    self:LoadContentPoint(temdata)
  end
end

function SportScoreRewardPage:SetSliderInfo()
  local partObj = self.m_tabWidgets.obj_score
  local trs = partObj:GetComponent(RectTransform.GetClassType())
  local trs_slider = self.m_tabWidgets.trs_slider
  self.sliderWidgth = trs_slider.sizeDelta.x
  local widgth = trs.sizeDelta.x
  local index = tostring(#self.pointData)
  local finialTrs = self.m_tabWidgets.trs_pointsCon:Find(index).gameObject:GetComponent(Transform.GetClassType())
  local indexWidgth = (finialTrs.localPosition.x - widgth * (index - 1)) / (index - 1)
  local finialSilderV = (finialTrs.localPosition.x + widgth / 2) / trs_slider.sizeDelta.x
  table.sort(self.pointData, function(l, r)
    return l.id < r.id
  end)
  self.scoreTab = {}
  table.insert(self.scoreTab, {
    index = 0,
    score = 0,
    widthPoint = 0,
    sliderValue = 0
  })
  for i = 1, #self.pointData do
    local pointscore = self.pointData[i].score
    local widthPoint = (indexWidgth + widgth) * (i - 1) + widgth / 2
    local sliderValue = finialSilderV / #self.pointData * i
    table.insert(self.scoreTab, {
      index = i,
      score = pointscore,
      widthPoint = widthPoint,
      sliderValue = sliderValue
    })
  end
  table.insert(self.scoreTab, {
    index = #self.pointData + 1,
    score = 9999,
    widthPoint = self.sliderWidgth,
    sliderValue = 1
  })
end

function SportScoreRewardPage:GetSliderValue(score)
  self:SetSliderInfo()
  local max = 0
  local min = 0
  local value = 0
  for i = 1, #self.scoreTab do
    if score < self.scoreTab[i].score then
      max = i
      break
    end
  end
  if 1 < max then
    local maxInfo = self.scoreTab[max]
    local minInfo = self.scoreTab[max - 1]
    local perValue = (maxInfo.widthPoint - minInfo.widthPoint) / (maxInfo.score - minInfo.score)
    value = (minInfo.widthPoint + perValue * (score - minInfo.score)) / self.sliderWidgth
  else
    value = 0
  end
  return value
end

function SportScoreRewardPage:ReceiveRewardBack(data)
  for v, k in pairs(data) do
    Logic.rewardLogic:ShowCommonReward(k, "SportScoreRewardPage", nil)
  end
  self:GetPointsRewardDetailData()
end

function SportScoreRewardPage:GetReceiveDeatilByScore(score)
  if self.receiveList == nil then
    return false
  end
  for i, v in ipairs(self.receiveList) do
    if v == score then
      return true
    end
  end
  return false
end

function SportScoreRewardPage:GetAllReceiveState()
  for k, v in pairs(self.awardData) do
    local rewardConfig = v
    local isRec = self:GetReceiveDeatilByScore(rewardConfig.score)
    if isRec == false and self.totalScore >= rewardConfig.score then
      return true
    end
  end
  return false
end

function SportScoreRewardPage:RefreshScoreCon(data)
  for i, v in pairs(self.partContainer) do
    local isReceive = self:GetReceiveDeatilByScore(i)
    local isReach = i <= self.totalScore
    local part = v
    v.img_check.gameObject:SetActive(isReceive)
    v.btn_icon.enabled = not isReceive
    v.img_unlock.gameObject:SetActive(not isReach)
    v.img_canRec.gameObject:SetActive(isReach and not isReceive)
  end
  for k, v in pairs(self.scorePointsCon) do
    local isReceive = self:GetReceiveDeatilByScore(k)
    local isReach = k <= self.totalScore
    local part = v.part
    part.obj_check:SetActive(isReceive)
    part.obj_reach:SetActive(isReach)
  end
end

return SportScoreRewardPage
