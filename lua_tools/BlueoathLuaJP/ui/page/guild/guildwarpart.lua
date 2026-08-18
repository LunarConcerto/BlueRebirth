local GuildWarPart = class("ui.page.Guild.GuildWarPart")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local GREENCOLOR = "34ff3e"
local RankBg = {
  [1] = "uipic_ui_guildwar_rank_diban_1",
  [2] = "uipic_ui_guildwar_rank_diban_2",
  [3] = "uipic_ui_guildwar_rank_diban_3"
}
local configInfo = {
  [1] = {
    Name = UIHelper.GetString(810051),
    configStr = "guild_reward"
  },
  [2] = {
    Name = UIHelper.GetString(810050),
    configStr = "battle_reward"
  }
}
local showDamageType = {Current = 1, Next = 2}

function GuildWarPart:initialize(page)
  self.guildPage = page
  self.widgetsTab = page.tab_Widgets.lp_GuildWar:GetLuaTableParts()
  self.pointsData = {}
  self.selectedPointIndex = 1
  self.lastRankListNum = 0
  self.playerRankUIPart = self.widgetsTab.lp_player_rank:GetLuaTableParts()
  self.countDownTimer = nil
  self.checkDayTimer = nil
  self.openTime = 0
  self.activityOpen = true
  self.showReportDetial = false
  self.reportViewHight = 0
  self.reportViewAlpha = 1
  self.model3d = nil
  self.modelCamTrans = nil
  self.showGuildRank = true
  self.canRotateCamera = false
  self.noOperationTime = 0
  self.cameraInitPos = nil
  self.cameraInitAngle = nil
  self.basePointUITab = {}
  self.personRankList = nil
  self.selectPersonRankIdx = 1
  self.selectRewardIndex = 1
  self:RegisterEvent()
  self:OnInit()
end

function GuildWarPart:RegisterEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_enter, self.OnEnterBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_rank, self.OnOpenRankBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_closeRank, self.OnCloseRankBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_reward, self.OnOpenRewardBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_rewardClose, self.OnCloseRewardBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_add, self.OnAddCountBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_reportDetailBtn, self.OnShowReportDetialBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_rankType, self.OnChangeRankClick, self)
  UGUIEventListener.AddButtonOnClick(self.playerRankUIPart.btn_view, self.OnPlayRankViewClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_help, self.OnHelpBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_change, self.OnChangeBtnClick, self)
end

function GuildWarPart:DoOnShow()
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarInfo, self.UpdateGuildPartView, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarRank, self.UpdataRankView, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarReport, self.UpdateReportView, self)
  eventManager:RegisterEvent(LuaEvent.ShowGuildWarBossReward, self.ShowRewardView, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildWarBaseInfo, self.UpdateGuildPartBaseView, self)
  LateUpdateBeat:Add(self.Update, self)
end

function GuildWarPart:UnRegisterEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarInfo, self.UpdateGuildPartView, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarRank, self.UpdataRankView, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarReport, self.UpdateReportView, self)
  eventManager:UnregisterEvent(LuaEvent.ShowGuildWarBossReward, self.ShowRewardView, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildWarBaseInfo, self.UpdateGuildPartBaseView, self)
  LateUpdateBeat:Remove(self.Update, self)
end

function GuildWarPart:OnInit()
  self.reportViewHight = self.widgetsTab.trans_reportRect.rect.height
  self.reportViewAlpha = self.widgetsTab.im_reportBg.color.a
  local paramterConf = configManager.GetDataById("config_parameter", 466)
  self.maxRankNum = paramterConf.arrValue[1]
  self.getRankStep = paramterConf.arrValue[2]
  local paramterCameraConf = configManager.GetDataById("config_parameter", 473)
  self.cameraInitPos = paramterCameraConf.arrValue[1]
  self.cameraInitAngle = paramterCameraConf.arrValue[2]
end

function GuildWarPart:Show()
  self:DoOnShow()
  self.showTime = time.getSvrTime()
  self.activityOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.GuildWarAct)
  if self.activityOpen then
    local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.GuildWarAct)
    if actId == nil or actId <= 0 then
      return
    end
    local actConf = configManager.GetDataById("config_activity", actId)
    self:show3DModel(actConf)
    
    local function func()
      self:UpdateGuildWarRemainTime(actConf.period)
    end
    
    func()
    if self.countDownTimer == nil then
      self.countDownTimer = self.guildPage:CreateTimer(func, 1, -1, false)
      self.guildPage:StartTimer(self.countDownTimer)
    end
    self.widgetsTab.btn_add.gameObject:SetActive(true)
    Service.guildService:SendGuildWarInfo()
    Service.guildService:SendGuildWarReport()
    Service.guildService:SendGuildWarBossReward()
    
    local function checkSameDayFunc()
      local timeNow = time.getSvrTime()
      if not time.isSameDay(self.showTime, timeNow) then
        self.showTime = timeNow
        Service.guildService:SendGuildWarInfo()
        Service.guildService:SendGuildWarReport()
        Service.guildService:SendGuildWarBossReward()
      end
    end
    
    if self.checkDayTimer == nil then
      self.checkDayTimer = self.guildPage:CreateTimer(checkSameDayFunc, 3, -1, false)
      self.guildPage:StartTimer(self.checkDayTimer)
    end
  else
    local actConf = configManager.GetDataById("config_activity", Activity.GuildWar)
    self:show3DModel(actConf)
    self:UpdateGuildPartViewLocal(actConf)
    self.widgetsTab.btn_add.gameObject:SetActive(false)
  end
  self:ShowAllDamageUpList()
end

function GuildWarPart:CloseCheckDayTimer()
  if self.checkDayTimer == nil then
    self.guildPage:StopTimer(self.checkDayTimer)
    self.checkDayTimer = nil
  end
end

local showReportDetialTime = 5

function GuildWarPart:Update()
  self:RotateCamera()
  local noOperation = false
  if Application.isMobilePlatform then
    noOperation = Input.touchCount <= 0
  else
    noOperation = not Input.anyKey
  end
  if noOperation then
    self.noOperationTime = self.noOperationTime + Time.deltaTime
    if self.noOperationTime > 5 and self.showReportDetial == true then
      self:OnShowReportDetialBtnClick()
    end
  else
    self.noOperationTime = 0
  end
end

function GuildWarPart:OnAddCountBtnClick()
  if self.widgetsTab.obj_conditionOb.gameObject.activeSelf then
    self.widgetsTab.obj_conditionOb.gameObject:SetActive(false)
  else
    local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.GuildWarAct)
    if 0 < actId then
      self.widgetsTab.obj_conditionOb.gameObject:SetActive(true)
      local guildData = Data.guildData:GetGuildWarData()
      local actConf = configManager.GetDataById("config_activity", actId)
      local conditionTab = actConf.p4
      local languageId = actConf.p3[1]
      local contentStr = UIHelper.GetString(languageId)
      local temCount = 0
      UIHelper.CreateSubPart(self.widgetsTab.obj_conditionItem, self.widgetsTab.trans_conditionRoot, #conditionTab, function(index, uiPart)
        local condition = conditionTab[index]
        local itemType = condition[1]
        local itemId = condition[2]
        local needNum = condition[3]
        local addCount = condition[4]
        local itemName = Logic.goodsLogic:GetName(itemId, itemType)
        local showStr = string.format(contentStr, itemName, needNum, addCount)
        temCount = temCount + addCount
        if guildData.maxChallengeCount >= temCount then
          showStr = UIHelper.SetColor(showStr, GREENCOLOR)
        end
        UIHelper.SetText(uiPart.condition, showStr)
      end)
    end
  end
end

function GuildWarPart:UpdateGuildWarRemainTime(periodId)
  local remainTime = PeriodManager:GetCountDownPeriodTime(periodId)
  self.activityOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.GuildWarAct)
  local period_config = configManager.GetDataById("config_period", periodId)
  remainTime = remainTime - (period_config.duration_list[2] and period_config.duration_list[2] or 0) - (period_config.duration_list[3] and period_config.duration_list[3] or 0)
  if 0 <= remainTime and self.activityOpen then
    local timeRemainStr = time.getTimeStringFontDynamic(remainTime, true)
    timeRemainStr = string.gsub(timeRemainStr, "%d", function(s)
      return UIHelper.SetColor(s, "ffed52")
    end)
    timeRemainStr = UIHelper.GetString(810019) .. timeRemainStr
    UIHelper.SetText(self.widgetsTab.txt_time, timeRemainStr)
  else
    UIHelper.SetLocText(self.widgetsTab.txt_time, 810020)
    self.guildPage:StopTimer(self.countDownTimer)
    self.activityOpen = false
  end
end

function GuildWarPart:UpdateEnterCount(guildData)
  local curChallangeCount = 0
  if 0 < guildData.curChallangeCount then
    curChallangeCount = guildData.curChallangeCount
  end
  local countStr = curChallangeCount .. "/" .. guildData.maxChallengeCount .. "\230\172\161"
  UIHelper.SetText(self.widgetsTab.txt_challengeCount, countStr)
  self.widgetsTab.obj_conditionOb.gameObject:SetActive(false)
end

function GuildWarPart:UpdateGuildPartView()
  local guildWarData = Data.guildData:GetGuildWarData()
  local pointInfos = guildWarData.pointInfos
  for id, info in pairs(pointInfos) do
    local config = configManager.GetDataById("config_guildwar_base_info", id)
    self:SetPointsData(id, info, config)
  end
  self:CreatFortifiedPoints()
  self:UpdateEnterCount(guildWarData)
end

function GuildWarPart:UpdateGuildPartBaseView(baseId)
  local pointData = self.pointsData[baseId]
  if pointData == nil then
    logError("GuildWarPart:UpdateGuildPartBaseView pointData is nil. baseId:", baseId)
    local actConf = configManager.GetDataById("config_activity", Activity.GuildWar)
    self:UpdateGuildPartViewLocal(actConf)
    pointData = self.pointsData[baseId]
  end
  local guildWarData = Data.guildData:GetGuildWarData()
  local pointInfos = guildWarData.pointInfos
  local config = configManager.GetDataById("config_guildwar_base_info", baseId)
  self:SetPointsData(baseId, pointInfos[baseId], config)
  if self.selectedPointIndex == baseId then
    local progerssStr = self.pointsData[baseId].stageName .. ":" .. self.pointsData[baseId].lapName
    UIHelper.SetText(self.widgetsTab.txt_progress, progerssStr)
  end
end

function GuildWarPart:UpdateGuildPartViewLocal(actConf)
  for _, id in pairs(actConf.p1) do
    local config = configManager.GetDataById("config_guildwar_base_info", id)
    self:SetPointsDataLocal(id, config)
  end
  self:CreatFortifiedPoints()
  local countStr = 0 .. "/" .. 0 .. "\230\172\161"
  UIHelper.SetText(self.widgetsTab.txt_challengeCount, countStr)
  UIHelper.SetLocText(self.widgetsTab.txt_time, 810020)
end

function GuildWarPart:CreatFortifiedPoints()
  self.widgetsTab.group_base:ClearToggles()
  self.basePointUITab = {}
  UIHelper.CreateSubPart(self.widgetsTab.obj_baseItem, self.widgetsTab.trans_baseRoot, #self.pointsData, function(index, uiPart)
    local pointData = self.pointsData[index]
    local pointConf = configManager.GetDataById("config_guildwar_base_info", pointData.id)
    UIHelper.SetText(uiPart.txt_desc, pointConf.desc)
    UIHelper.SetImage(uiPart.im_bg, pointConf.pic)
    self.basePointUITab[index] = uiPart
    self.widgetsTab.group_base:RegisterToggle(uiPart.tog_clickTog)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.group_base, self, "", self._SwitchTogs)
  self.widgetsTab.group_base:SetActiveToggleIndex(0)
end

function GuildWarPart:_SwitchTogs(togIndex)
  local index = togIndex + 1
  self.selectedPointIndex = index
  local pointData = self.pointsData[index]
  for k, v in pairs(self.basePointUITab) do
    v.tw_desc:Play(index == k)
  end
  local progerssStr = pointData.stageName .. ":" .. pointData.lapName
  UIHelper.SetText(self.widgetsTab.txt_progress, progerssStr)
  self:SetCameraTrans(self.selectedPointIndex)
end

function GuildWarPart:SetPointsData(pointId, severData, confInfo)
  self.pointsData[pointId] = {}
  self.pointsData[pointId].id = severData.BaseId
  self.pointsData[pointId].curStage = severData.CurStageId
  self.pointsData[pointId].curLap = severData.CurSectionId
  self.pointsData[pointId].desc = confInfo.desc
  self.pointsData[pointId].stageName = string.format(UIHelper.GetString(810001), StageName[severData.CurStageId])
  self.pointsData[pointId].lapName = string.format(UIHelper.GetString(810002), tostring(severData.CurSectionId))
  self.pointsData[pointId].lapDes = confInfo.lap_name
  self.pointsData[pointId].copyId = confInfo.copydisplay_id[severData.CurStageId]
  self.pointsData[pointId].stageRewardIds = confInfo.stage_reward
  self.pointsData[pointId].allStage = confInfo.stage
  self.pointsData[pointId].allLap = confInfo.lap
  self.pointsData[pointId].cameraPos = confInfo.camera_position
  self.pointsData[pointId].cameraRotatePos = confInfo.camera_rotate_position
end

function GuildWarPart:SetPointsDataLocal(pointId, confInfo)
  self.pointsData[pointId] = {}
  self.pointsData[pointId].id = confInfo.id
  self.pointsData[pointId].curStage = confInfo.stage[1]
  self.pointsData[pointId].curLap = confInfo.lap[1][1]
  self.pointsData[pointId].desc = confInfo.desc
  self.pointsData[pointId].stageName = string.format(UIHelper.GetString(810001), StageName[confInfo.stage[1]])
  self.pointsData[pointId].lapName = string.format(UIHelper.GetString(810002), tostring(confInfo.lap[1][1]))
  self.pointsData[pointId].lapDes = confInfo.lap_name
  self.pointsData[pointId].copyId = confInfo.copydisplay_id[confInfo.stage[1]]
  self.pointsData[pointId].stageRewardIds = confInfo.stage_reward
  self.pointsData[pointId].allStage = confInfo.stage
  self.pointsData[pointId].allLap = confInfo.lap
  self.pointsData[pointId].cameraPos = confInfo.camera_position
  self.pointsData[pointId].cameraRotatePos = confInfo.camera_rotate_position
end

function GuildWarPart:OnEnterBtnClick()
  if self.activityOpen == false then
    noticeManager:ShowTipById(810020)
    return
  else
    local myGuild = Data.guildData:getMyGuildInfo()
    local joinTime = myGuild.mJoinGuildTime
    local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.GuildWarAct)
    local actConf = configManager.GetDataById("config_activity", actId)
    local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(actConf.period)
    if joinTime >= startTime and joinTime <= endTime then
      noticeManager:ShowTipById(810028)
      return
    end
    local selectPointData = self.pointsData[self.selectedPointIndex]
    if selectPointData then
      local copyId = selectPointData.copyId
      local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
      local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
      local param = {
        copyType = CopyType.COMMONCOPY,
        tabSerData = copyData,
        chapterId = chapterId,
        IsRunningFight = copyData.IsRunningFight == true,
        copyId = copyId,
        pointInfo = selectPointData,
        showSweepBtn = false
      }
      if Logic.copyLogic:IsAssistFleet(copyId) then
        UIHelper.OpenPage("FleetPage", {
          subType = 2,
          copyId = param.copyId,
          chapterId = param.chapterId
        })
      else
        local isHasFleet = Logic.fleetLogic:IsHasFleet()
        if not isHasFleet then
          noticeManager:OpenTipPage(self, 110007)
          return
        end
        UIHelper.OpenPage("LevelDetailsPage", param)
      end
    else
      logError("\233\128\137\230\139\169\230\141\174\231\130\185\230\149\176\230\141\174\229\135\186\233\148\153", self.selectedPointIndex)
    end
  end
end

function GuildWarPart:OnOpenRankBtnClick()
  self.lastRankListNum = 0
  self.widgetsTab.obj_rankList:SetActive(true)
  self.widgetsTab.obj_guildList:SetActive(self.showGuildRank == true)
  self.widgetsTab.obj_personList:SetActive(self.showGuildRank == false)
  if self.showGuildRank then
    UIHelper.SetLocText(self.widgetsTab.tx_ranktitle, 810021)
    UIHelper.SetLocText(self.widgetsTab.tx_changerank, 810022)
    Service.guildService:SendGuildWarRankInfo(1, self.getRankStep)
  else
    UIHelper.SetLocText(self.widgetsTab.tx_ranktitle, 810022)
    UIHelper.SetLocText(self.widgetsTab.tx_changerank, 810021)
    Service.guildService:SendGuildWarPersonRank()
  end
end

function GuildWarPart:OnCloseRankBtnClick()
  self.selectPersonRankIdx = 1
  self.widgetsTab.obj_rankList:SetActive(false)
end

function GuildWarPart:UpdataRankView(showGuildRank)
  if showGuildRank == true then
    self:UpdataGuildRankView()
  else
    self:UpdatePersonRankView()
  end
end

function GuildWarPart:UpdataGuildRankView()
  local guildWarData = Data.guildData:GetGuildWarData()
  local rankListData = guildWarData.playerRankListData
  local canPullData = false
  local rankListNum = table.nums(rankListData)
  self.widgetsTab.obj_ranknone:SetActive(rankListNum <= 0)
  if rankListNum <= 0 then
    return
  end
  if table.nums(rankListData) > self.lastRankListNum then
    self.lastRankListNum = table.nums(rankListData)
    canPullData = true
  end
  local maxNum = self.maxRankNum
  
  local function setRankUI(uiPart, data, isSelf)
    if not isSelf then
      UIHelper.SetText(uiPart.tx_rank, data.Rank)
    elseif data.Rank > self.maxRankNum then
      UIHelper.SetText(uiPart.tx_rank, "\230\156\170\228\184\138\230\166\156")
      uiPart.btn_view.gameObject:SetActive(false)
    else
      UIHelper.SetText(uiPart.tx_rank, data.Rank)
      uiPart.btn_view.gameObject:SetActive(true)
    end
    local white = Color.New(255, 255, 255, 255)
    local normalColor = Color.New(0.3764, 0.4941, 0.6392, 1.0)
    if data.Rank <= 3 then
      uiPart.tx_rank.color = white
      uiPart.tx_guildname.color = white
      uiPart.tx_guildlevel.color = white
      uiPart.tx_progress.color = white
      uiPart.tx_integral.color = white
      uiPart.im_bg.enabled = true
      UIHelper.SetImage(uiPart.im_bg, RankBg[data.Rank])
    else
      uiPart.tx_rank.color = normalColor
      uiPart.tx_guildname.color = normalColor
      uiPart.tx_guildlevel.color = normalColor
      uiPart.tx_progress.color = normalColor
      uiPart.tx_integral.color = normalColor
      uiPart.im_bg.enabled = false
    end
    UIHelper.SetText(uiPart.tx_guildname, data.Name)
    UIHelper.SetText(uiPart.tx_guildlevel, "LV." .. data.Level)
    local killInfoTab = {}
    for _, killInfo in pairs(data.KillList) do
      killInfoTab[killInfo.BaseID] = killInfo.KillCount
    end
    local killInfoStr = table.concat(killInfoTab, "/")
    UIHelper.SetText(uiPart.tx_progress, killInfoStr)
    UIHelper.SetText(uiPart.tx_integral, data.Score)
    UIHelper.SetImage(uiPart.im_rating, GuildWarGradeImg[data.Grade])
  end
  
  UIHelper.SetInfiniteItemParam(self.widgetsTab.trans_rankContent, self.widgetsTab.obj_rankItem, #rankListData, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for index, luaPart in pairs(tabTemp) do
      if index <= maxNum then
        local rankData = rankListData[index]
        setRankUI(luaPart, rankData, false)
      else
        return
      end
      if index >= #rankListData and index < maxNum and canPullData then
        Service.guildService:SendGuildWarRankInfo(#rankListData, #rankListData + self.getRankStep)
      end
    end
  end)
  if guildWarData.selfRankData and table.nums(guildWarData.selfRankData) > 1 then
    self.widgetsTab.lp_player_rank.gameObject:SetActive(true)
    setRankUI(self.playerRankUIPart, guildWarData.selfRankData, true)
  else
    self.widgetsTab.lp_player_rank.gameObject:SetActive(false)
  end
end

function GuildWarPart:OnChangeRankClick()
  self.showGuildRank = not self.showGuildRank
  self.widgetsTab.obj_guildList:SetActive(self.showGuildRank == true)
  self.widgetsTab.obj_personList:SetActive(self.showGuildRank == false)
  local guildWarData = Data.guildData:GetGuildWarData()
  if self.showGuildRank then
    UIHelper.SetLocText(self.widgetsTab.tx_ranktitle, 810021)
    UIHelper.SetLocText(self.widgetsTab.tx_changerank, 810022)
    local rankListNum = table.nums(guildWarData.playerRankListData)
    self.widgetsTab.obj_ranknone:SetActive(rankListNum <= 0)
    if rankListNum <= 0 then
      Service.guildService:SendGuildWarRankInfo(1, self.getRankStep)
    end
  else
    UIHelper.SetLocText(self.widgetsTab.tx_ranktitle, 810022)
    UIHelper.SetLocText(self.widgetsTab.tx_changerank, 810021)
    self.personRankList = guildWarData.personRankList
    local rankDatas = self.personRankList[self.selectPersonRankIdx]
    if rankDatas ~= nil then
      if table.nums(rankDatas) <= 0 then
        self.widgetsTab.obj_ranknone:SetActive(true)
        return
      else
        self.widgetsTab.obj_ranknone:SetActive(false)
      end
    else
      self.widgetsTab.obj_ranknone:SetActive(true)
    end
    if 0 >= #guildWarData.personRankList then
      Service.guildService:SendGuildWarPersonRank()
    else
      if self.personRankList == nil then
        self.personRankList = guildWarData.personRankList
      end
      self:UpdatePersonRankView()
    end
  end
end

function GuildWarPart:UpdatePersonRankView()
  self.rankTotalData = self.pointsData
  UIHelper.CreateSubPart(self.widgetsTab.tg_toggle.gameObject, self.widgetsTab.tg_togglesGroup.transform, #self.pointsData + 1, function(index, uipart)
    if index == 1 then
      UIHelper.SetText(uipart.tx_name, UIHelper.GetString(810052))
    else
      local pointData = self.pointsData[index - 1]
      local desc = pointData.desc
      UIHelper.SetText(uipart.tx_name, desc)
    end
    self.widgetsTab.tg_togglesGroup:RegisterToggle(uipart.tg_toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.tg_togglesGroup, self, "", self.SwitchPersonRankToggle)
  self.widgetsTab.tg_togglesGroup:SetActiveToggleIndex(0)
end

function GuildWarPart:SwitchPersonRankToggle(index)
  self.selectPersonRankIdx = index == 0 and 9999 or index
  local guildWarData = Data.guildData:GetGuildWarData()
  self.personRankList = guildWarData.personRankList
  local rankDatas = self.personRankList[self.selectPersonRankIdx]
  if rankDatas ~= nil then
    self.widgetsTab.trans_personRankContent.gameObject:SetActive(true)
    if 0 >= table.nums(rankDatas) then
      self.widgetsTab.obj_ranknone:SetActive(true)
      return
    else
      self.widgetsTab.obj_ranknone:SetActive(false)
    end
    UIHelper.CreateSubPart(self.widgetsTab.obj_personRankItem, self.widgetsTab.trans_personRankContent, #rankDatas, function(index, uipart)
      local rankData = rankDatas[index]
      local icon, quality = Data.userData:GetUserHeadIcon(rankData.UserInfo)
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetHeadFrameByUid(rankData.UserInfo)
      UIHelper.SetText(uipart.tx_rank, rankData.RankNo)
      UIHelper.SetText(uipart.tx_name, rankData.UserInfo.Uname)
      local lvText = "Lv." .. rankData.UserInfo.Level
      UIHelper.SetText(uipart.tx_level, lvText)
      UIHelper.SetText(uipart.tx_damage, rankData.Damge)
      UIHelper.SetText(uipart.tx_score, rankData.Score)
      UIHelper.SetImageByQuality(uipart.im_bg, quality)
      UIHelper.SetImage(uipart.im_head, icon)
      UIHelper.SetImage(uipart.im_frame, headFrameInfo.icon)
      uipart.sld_process.value = rankData.Percent / 10000
      local process = string.format("%0.2f", rankData.Percent / 100)
      UIHelper.SetText(uipart.tx_progress, process .. "%")
    end)
  else
    self.widgetsTab.trans_personRankContent.gameObject:SetActive(false)
    self.widgetsTab.obj_ranknone:SetActive(true)
  end
end

function GuildWarPart:OnPlayRankViewClick()
  local guildWarData = Data.guildData:GetGuildWarData()
  local guildCount = #guildWarData.playerRankListData
  local rate = (guildWarData.selfRankData.Rank - 1) / (#guildWarData.playerRankListData - 5)
  local scrollView = self.widgetsTab.obj_rank:GetComponent(UIScrollRect.GetClassType())
  scrollView.verticalNormalizedPosition = math.min(1 - rate, 1)
end

function GuildWarPart:OnOpenRewardBtnClick()
  self.widgetsTab.obj_rewardList:SetActive(true)
  self:ShowRewardList()
end

function GuildWarPart:OnCloseRewardBtnClick()
  self.widgetsTab.obj_rewardList:SetActive(false)
end

function GuildWarPart:ShowRewardList()
  UIHelper.CreateSubPart(self.widgetsTab.rewardToggle, self.widgetsTab.rewardToggleGroup.transform, #self.pointsData + 1, function(index, uiPart)
    if index <= #self.pointsData then
      local pointInfo = self.pointsData[index]
      UIHelper.SetText(uiPart.txt_name, pointInfo.desc)
    else
      local name = UIHelper.GetString(810044)
      UIHelper.SetText(uiPart.txt_name, name)
    end
    self.widgetsTab.rewardToggleGroup:RegisterToggle(uiPart.tg_toggle)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.rewardToggleGroup, self, "", self.SwitchRewardTog)
  self.widgetsTab.rewardToggleGroup:SetActiveToggleIndex(0)
end

function GuildWarPart:SwitchRewardTog(index)
  self.tempIndex = index
  self:ShowSelectIndexInfo()
  local pointIndex = index + 1
  if pointIndex <= #self.pointsData then
    local pointInfo = self.pointsData[pointIndex]
    UIHelper.SetText(self.widgetsTab.tx_rewardDesc, UIHelper.GetLocString(self.selectRewardIndex == 1 and 810049 or 810016, pointInfo.desc))
    self:ShowPointRewardDetial(pointInfo)
  else
    UIHelper.SetText(self.widgetsTab.tx_rewardDesc, UIHelper.GetString(810017))
    self:ShowRankRewardDetial()
  end
end

function GuildWarPart:OnChangeBtnClick()
  if self.selectRewardIndex == 1 then
    self.selectRewardIndex = 2
  else
    self.selectRewardIndex = 1
  end
  self:SwitchRewardTog(self.tempIndex or 0)
end

function GuildWarPart:ShowSelectIndexInfo()
  self.widgetsTab.btn_change.gameObject:SetActive(self.tempIndex ~= #self.pointsData)
  UIHelper.SetText(self.widgetsTab.tx_rewardMode, configInfo[self.selectRewardIndex].Name)
end

function GuildWarPart:ShowPointRewardDetial(pointData)
  local stageRewardIds = pointData.stageRewardIds
  UIHelper.CreateSubPart(self.widgetsTab.obj_rewardItem, self.widgetsTab.trans_rewardContent, #stageRewardIds, function(index, uiPart)
    local stageName = string.format(UIHelper.GetString(810001), StageName[pointData.allStage[index]])
    UIHelper.SetText(uiPart.tx_stage, stageName)
    UIHelper.SetText(uiPart.tx_lap, tostring(pointData.lapDes[index]))
    local stageRewardId = stageRewardIds[index]
    local rewardId = configManager.GetDataById("config_guildwar_reward", stageRewardId)[configInfo[self.selectRewardIndex].configStr]
    local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
    UIHelper.CreateSubPart(uiPart.obj_rewardItem, uiPart.trans_rewardTrans, #rewards, function(index2, uiPart2)
      local rewardInfo = rewards[index2]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(uiPart2.img_icon, icon)
      UIHelper.SetImageByQuality(uiPart2.img_bg, quality)
      UIHelper.SetText(uiPart2.txt_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart2.btn_clickBtn, clickFunc)
    end)
  end)
end

function GuildWarPart:ShowRankRewardDetial()
  local rankConfTab = configManager.GetData("config_guildwar_rank")
  UIHelper.CreateSubPart(self.widgetsTab.obj_rewardItem, self.widgetsTab.trans_rewardContent, #rankConfTab, function(index, uiPart)
    local rankConf = rankConfTab[index]
    UIHelper.SetText(uiPart.tx_stage, rankConf.rank_name)
    UIHelper.SetText(uiPart.tx_lap, rankConf.range_desc)
    local rewardId = rankConf.rank_reward
    local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
    UIHelper.CreateSubPart(uiPart.obj_rewardItem, uiPart.trans_rewardTrans, #rewards, function(index2, uiPart2)
      local rewardInfo = rewards[index2]
      local itemType = rewardInfo[1]
      local itemId = rewardInfo[2]
      local num = "x" .. rewardInfo[3]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      UIHelper.SetImage(uiPart2.img_icon, icon)
      UIHelper.SetImageByQuality(uiPart2.img_bg, quality)
      UIHelper.SetText(uiPart2.txt_num, num)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart2.btn_clickBtn, clickFunc)
    end)
  end)
end

function GuildWarPart:UpdateReportView(setButtom)
  local guildWarData = Data.guildData:GetGuildWarData()
  local reportList = guildWarData.report
  if next(reportList) == nil then
    return
  end
  UIHelper.CreateSubPart(self.widgetsTab.obj_reportItem, self.widgetsTab.trans_reportTrans, #reportList, function(index, uiPart)
    local reportInfo = reportList[index]
    local desc = self.pointsData[reportInfo.baseId].desc
    local reportStr
    if reportInfo.type == GuildWarReportType.EnterType then
      reportStr = string.format(UIHelper.GetString(810004), reportInfo.playerName, desc, reportInfo.sectionId)
    elseif reportInfo.type == GuildWarReportType.DamageType then
      reportStr = string.format(UIHelper.GetString(810005), reportInfo.playerName, desc, reportInfo.sectionId, reportInfo.damage, reportInfo.score)
    elseif reportInfo.type == GuildWarReportType.KillBossType then
      reportStr = string.format(UIHelper.GetString(810006), reportInfo.playerName, desc, reportInfo.sectionId, reportInfo.damage, reportInfo.score)
    end
    UIHelper.SetText(uiPart.txt_report, reportStr)
  end)
end

function GuildWarPart:OnShowReportDetialBtnClick()
  self.widgetsTab.trans_reportRect:GetComponent(UIScrollRect.GetClassType()):StopMovement()
  if self.showReportDetial == false then
    self.showReportDetial = true
    self.widgetsTab.trans_reportRect:SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, self.reportViewHight * 3)
    self:UpdateReportView(false)
    self.widgetsTab.im_reportBg.color = Color.New(1, 1, 1, 1)
    UIHelper.SetText(self.widgetsTab.txt_reportBtnText, "\229\133\179\233\151\173")
  else
    self.showReportDetial = false
    self.widgetsTab.trans_reportRect:SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, self.reportViewHight)
    self:UpdateReportView(false)
    self.widgetsTab.im_reportBg.color = Color.New(1, 1, 1, self.reportViewAlpha)
    UIHelper.SetText(self.widgetsTab.txt_reportBtnText, "\229\177\149\229\188\128")
  end
end

local speed = 5

function GuildWarPart:show3DModel(actConf)
  if self.model3d == nil then
    local path = actConf.p5[1]
    local creatParam = {resPath = path}
    local tabCameraParam = {
      cameraRelativePos = self.cameraInitPos,
      cameraRelativeRot = self.cameraInitAngle,
      fieldOfView = 50,
      size = 0,
      usePerspective = true
    }
    self.model3d = UIHelper.CreateOther3DModel(creatParam, self.widgetsTab.rm_baseModel, tabCameraParam)
    self.model3d.m_camera.farClipPlane = 100
    self.modelCamTrans = self.model3d.gameCamera:getTransBase()
  end
end

function GuildWarPart:SetCameraTrans(pointIndex)
  self.canRotateCamera = false
  self.modelCamTrans.localPosition = Vector3.NewFromTab(self.cameraInitPos)
  self.modelCamTrans.localEulerAngles = Vector3.NewFromTab(self.cameraInitAngle)
  local targetPos = self.pointsData[pointIndex].cameraPos
  local tweenPos = UIHelper.GetTween(self.modelCamTrans.gameObject, ETweenType.ETT_POSITION)
  if tweenPos ~= nil then
    tweenPos:Stop()
    tweenPos:ResetToInit()
    tweenPos.to = Vector3.NewFromTab(targetPos)
  else
    tweenPos = TweenPosition.Begin(self.modelCamTrans.gameObject, 2, Vector3.NewFromTab(targetPos))
  end
  tweenPos:SetOnFinished(function()
    self.canRotateCamera = true
  end)
  tweenPos:Play(true)
end

function GuildWarPart:RotateCamera()
  if self.canRotateCamera and self.model3d ~= nil and self.modelCamTrans ~= nil then
    local centerPoint = self.pointsData[self.selectedPointIndex].cameraRotatePos
    self.modelCamTrans:RotateAround(Vector3.NewFromTab(centerPoint), Vector3.up, speed * Time.deltaTime)
  end
end

function GuildWarPart:ShowAllDamageUpList()
  if self.activityOpen then
    UIHelper.CreateSubPart(self.widgetsTab.obj_damageUp, self.widgetsTab.trans_damageUp, 2, function(index, uiPart)
      local damageUpList = {}
      local period = showDamageType.Current
      if index == 1 then
        UIHelper.SetText(uiPart.txt_title, UIHelper.GetString(810053))
      else
        UIHelper.SetText(uiPart.txt_title, UIHelper.GetString(810054))
        period = showDamageType.Next
      end
      damageUpList = Logic.guildLogic:GetPeriodAdditionByPeriod(period)
      if #damageUpList <= 0 then
        uiPart.txt_title.transform.parent.gameObject:SetActive(false)
      else
        self:ShowDamageUpList(damageUpList, uiPart, period)
      end
    end)
  else
    UIHelper.CreateSubPart(self.widgetsTab.obj_damageUp, self.widgetsTab.trans_damageUp, 1, function(index, uiPart)
      local damageUpList = {}
      local period = showDamageType.Next
      UIHelper.SetText(uiPart.txt_title, UIHelper.GetString(810054))
      damageUpList = Logic.guildLogic:GetPeriodAdditionByPeriod(period)
      if #damageUpList <= 0 then
        uiPart.txt_title.transform.parent.gameObject:SetActive(false)
      else
        self:ShowDamageUpList(damageUpList, uiPart, period)
      end
    end)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.widgetsTab.trans_damageUp)
end

function GuildWarPart:ShowDamageUpList(damageUpList, part, period)
  UIHelper.CreateSubPart(part.obj_rateList, part.trans_rateList, #damageUpList, function(index, uiPart)
    local rate = damageUpList[index]
    local str = string.format(UIHelper.GetString(810055), rate)
    UIHelper.SetText(uiPart.txt_rate, str)
    local fleetList = Logic.guildLogic:GetPeriodAdditionFleet(period, rate)
    self:ShowDamageUpFleet(fleetList, uiPart)
  end)
  LayoutRebuilder.ForceRebuildLayoutImmediate(part.trans_rateList)
end

function GuildWarPart:ShowDamageUpFleet(fleetList, part)
  UIHelper.CreateSubPart(part.obj_rate, part.trans_rate, #fleetList, function(index, uiPart)
    local config = configManager.GetDataById("config_ship_show", fleetList[index])
    local bg = QualityIcon[config.quality]
    UIHelper.SetImage(uiPart.img_bg, bg)
    UIHelper.SetImage(uiPart.img_icon, config.ship_icon5)
    UGUIEventListener.AddButtonOnClick(uiPart.btn_bg, self.ShowShipInfo, self, fleetList[index])
  end)
  LayoutRebuilder.ForceRebuildLayoutImmediate(part.trans_rate)
end

function GuildWarPart:ShowShipInfo(go, param)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData("ShipSimple", param))
end

function GuildWarPart:ShowRewardView(data)
  UIHelper.OpenPage("GetRewardsPage", {
    RewardType = RewardType.GUILDWAR,
    Rewards = data,
    Desc = UIHelper.GetString(810007)
  })
end

function GuildWarPart:OnHelpBtnClick()
  UIHelper.OpenPage("HelpPage", {content = 810015})
end

function GuildWarPart:OnHide()
  self:UnRegisterEvent()
  if self.model3d ~= nil then
    UI3DModelManager.Close3DModel(self.model3d)
    self.canRotateCamera = false
    self.model3d = nil
  end
  self:CloseCheckDayTimer()
end

function GuildWarPart:OnClose()
  self:UnRegisterEvent()
  if self.model3d ~= nil then
    UI3DModelManager.Close3DModel(self.model3d)
    self.canRotateCamera = false
    self.model3d = nil
  end
  self:CloseCheckDayTimer()
  self.personRankList = nil
  self.selectPersonRankIdx = 1
end

return GuildWarPart
