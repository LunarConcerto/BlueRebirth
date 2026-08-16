local ActivityBattleCopyPage = class("UI.Activity.ActivityBattleCopyPage", LuaUIPage)

function ActivityBattleCopyPage:DoInit()
  self.mNeedLookRefresh = false
end

function ActivityBattleCopyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ActivitySecretCopy_RefreshData, self.ShowPage, self)
end

function ActivityBattleCopyPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
  if self.mNeedLookRefresh then
    eventManager:SendEvent(LuaEvent.ActivitySecretCopy_LookRefresh)
  end
  local haslook = PlayerPrefs.GetBool("ActivitySecretCopy_Look", false)
  if not haslook then
    PlayerPrefs.SetBool("ActivitySecretCopy_Look", true)
    PlayerPrefs.Save()
    self.mNeedLookRefresh = true
  end
end

function ActivityBattleCopyPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  UIHelper.SetLocText(self.tab_Widgets.textBattleDesc, activityCfg.p5[1])
  UIHelper.SetLocText(self.tab_Widgets.textTips, activityCfg.p6[1])
  local rateinfo = activityCfg.p4
  local bestpasstime = Data.activitysecretcopyData:GetPassTimePerfect()
  UIHelper.SetText(self.tab_Widgets.textBestPassTime, bestpasstime)
  local min = rateinfo[1][1]
  local max = rateinfo[#rateinfo][1]
  local process = 0
  if bestpasstime <= 0 or bestpasstime > min then
    process = 0
  elseif bestpasstime > max then
    process = (min - bestpasstime) / (min - max)
  else
    process = 1
  end
  self.tab_Widgets.sliderRate.value = process
  for rateIndex, info in ipairs(rateinfo) do
    local luaPart = self.tab_Widgets["partBox" .. rateIndex]
    local part = luaPart:GetLuaTableParts()
    local iscan = 0 < bestpasstime and bestpasstime < info[1]
    local isGet = Data.activitysecretcopyData:IsGetRewardByRate(rateIndex)
    local isCanGet = iscan and not isGet
    part.Effect:SetActive(isCanGet)
    local boxCfg = configManager.GetDataById("config_starbox", 6)
    if iscan then
      if isGet then
        UIHelper.SetImage(part.icon, boxCfg.recieved_icon)
      else
        UIHelper.SetImage(part.icon, boxCfg.open_icon)
      end
    else
      UIHelper.SetImage(part.icon, boxCfg.unopen_icon)
    end
    local index = rateIndex
    local rewardid = rateinfo[index][2]
    UGUIEventListener.AddButtonOnClick(part.btn, function()
      if isCanGet then
        Service.activitysecretcopyService:SendGetReward({RateIndex = index, RewardId = rewardid})
      else
        local rewards = Logic.rewardLogic:FormatRewards({rewardid})
        UIHelper.OpenPage("BoxRewardPage", {
          rewardState = RewardState.UnReceivable,
          rewards = rewards
        })
      end
    end)
    local evaldescids = activityCfg.p7
    local dictId = evaldescids[rateIndex]
    local content = UIHelper.GetString(dictId)
    if iscan then
      content = UIHelper.SetColor(content, "ffffff")
    end
    UIHelper.SetText(self.tab_Widgets["textEval" .. rateIndex], content)
  end
  local copyId = activityCfg.p1[1]
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCopy, function()
    if not Data.activityData:IsActivityOpen(self.mActivityId) then
      noticeManager:ShowTipById(270022)
      return
    end
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      noticeManager:OpenTipPage(self, 110007)
      return
    end
    local copyData = self:MakeDefaultCopyInfo(copyId)
    local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
    local areaConfig = {
      copyType = CopyType.COMMONCOPY,
      copyId = copyId,
      tabSerData = copyData,
      chapterId = chapterId,
      IsRunningFight = false
    }
    UIHelper.OpenPage("LevelDetailsPage", areaConfig)
  end)
end

function ActivityBattleCopyPage:MakeDefaultCopyInfo(copyId)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  if copyData then
    return copyData
  end
  local result = {}
  result.Rid = 0
  result.StarLevel = 0
  result.BaseId = copyId
  result.IsRunningFight = false
  result.SfPoint = 0
  result.SfInfo = {}
  result.SfLv = 0
  result.FirstPassTime = 0
  result.LBPoint = 0
  result.DropHeroIds = {}
  result.IsFake = true
  return result
end

return ActivityBattleCopyPage
