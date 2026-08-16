local MeritPage = class("UI.Activity.MeritPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local rankRemainNum = 6
local peopleNum = 40
local maxNum = 9999

function MeritPage:DoInit()
  self.tabTogs = {
    self.tab_Widgets.tog_merit,
    self.tab_Widgets.tog_rank
  }
  self.index = 0
  self.openID = nil
  self.tabRankInfo = {}
  self.tabRankById = {}
  self.getRank = true
end

function MeritPage:DoOnOpen()
  self.m_tabParams = self:GetParam()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = "\230\180\187\229\138\168\230\142\146\232\161\140",
    ChapterId = nil
  })
  for i, tog in ipairs(self.tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  local args = {
    Start = #self.tabRankInfo,
    End = #self.tabRankInfo + peopleNum
  }
  self.tab_Widgets.slider_grade.interactable = false
  local index = Logic.activityLogic:GetMeritTogLastIndex()
  self:_HideShowPage(index)
  self.tab_Widgets.tog_group:SetActiveToggleIndex(index)
  Service.meritService:SendBigActivity()
  Service.meritService:SendMeritRankInfo(args)
  self.tab_Widgets.obj_gradeNoReward:SetActive(false)
  self.tab_Widgets.obj_noReward:SetActive(false)
  self:_ShowUserInfo()
end

function MeritPage:_ShowUserInfo()
  local userInfo = Data.userData:GetUserData()
  local icon, qualityIcon = Logic.meritLogic:GetUserHead(userInfo.Head)
  UIHelper.SetImage(self.tab_Widgets.im_userIcon, icon)
  UIHelper.SetImage(self.tab_Widgets.im_userQuality, qualityIcon)
  UIHelper.SetText(self.tab_Widgets.tx_userName, userInfo.Uname)
end

function MeritPage:RegisterAllEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rankTips, self._ClickTips, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_gradeTips, self._ClickTips, self)
  self:RegisterEvent(LuaEvent.UpdateMeritRank, self._UpdateMeritRank, self)
  self:RegisterEvent(LuaEvent.UpdateMeritInfo, self._UpdateMeritInfo, self)
  self.tab_Widgets.ScrollbarVer.onValueChanged:AddListener(function(msg)
    self:_OnScrollRectChange(self, msg)
  end)
end

function MeritPage:_OnScrollRectChange(go, volume)
  if self.tab_Widgets.ScrollbarVer.value <= rankRemainNum / #self.tabRankInfo and self.getRank then
    self.getRank = false
    local args = {
      Start = #self.tabRankInfo,
      End = #self.tabRankInfo + peopleNum
    }
    Service.meritService:SendMeritRankInfo(args)
  end
end

function MeritPage:_UpdateMeritInfo()
  local activityData = configManager.GetData("config_activity")
  local activityType = {}
  for v, k in pairs(activityData) do
    if k.type == 5 then
      table.insert(activityType, k)
    end
  end
  local openActivityData = Data.activityData:GetActivityData()
  for v, k in pairs(openActivityData) do
    for index, key in pairs(activityType) do
      if key.id == v then
        self.openID = key.id
      end
    end
  end
  local configData = configManager.GetDataById("config_activity", self.openID)
  UIHelper.SetImage(self.tab_Widgets.im_meritIcon, configData.p8[2])
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodFirstListTime(configData.period, self.openID)
  local endTimeFormat = time.formatTimeToYMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, endTimeFormat)
  local activityData = Logic.activityLogic:GetOpenActivityByTypes(ActivityType.Festival, ActivityType.BigActivity)
  if 0 < #activityData then
    self:_LoadRwardInfo(configData)
    self:_LoadUserReward()
  end
end

function MeritPage:_HideShowPage(index)
  if index == MeritType.Grade then
    self.tab_Widgets.obj_rightGrade:SetActive(true)
    self.tab_Widgets.obj_rightRank:SetActive(false)
    self.tab_Widgets.obj_meritMask:SetActive(false)
    self.tab_Widgets.obj_rankMask:SetActive(true)
    self.tab_Widgets.obj_yellowTips:SetActive(false)
  elseif index == MeritType.Rank then
    self.tab_Widgets.obj_rightGrade:SetActive(false)
    self.tab_Widgets.obj_rightRank:SetActive(true)
    self.tab_Widgets.obj_meritMask:SetActive(true)
    self.tab_Widgets.obj_rankMask:SetActive(false)
    self.tab_Widgets.obj_yellowTips:SetActive(true)
    if self.openID then
      self:_LoadRankInfo(self.tabRankInfo)
    end
  end
end

function MeritPage:_SwitchTogs(index)
  self:_HideShowPage(index)
  Logic.activityLogic:SetMeritTogLastIndex(index)
  self.index = index
end

function MeritPage:_UpdateMeritRank(rankData)
  self.getRank = true
  if rankData.List ~= nil then
    for v, k in pairs(rankData.List) do
      table.insert(self.tabRankInfo, k)
    end
  end
  self:_LoadUserRank()
  if self.index == MeritType.Rank then
    self:_LoadRankInfo(rankData.List)
  end
end

function MeritPage:_LoadRwardInfo(configData)
  local userMeritInfo = Data.meritData:GetData()
  local wanjiafenduan = userMeritInfo.Percent
  if wanjiafenduan == -1 then
    self.tab_Widgets.im_percent.transform.localScale = Vector2.New(0, 0)
    UIHelper.SetText(self.tab_Widgets.tx_percent, "\228\187\138\230\151\165\230\156\170\229\143\130\229\138\160")
    self.tab_Widgets.slider_grade.gameObject:SetActive(false)
  else
    self.tab_Widgets.slider_grade.gameObject:SetActive(true)
    self.tab_Widgets.im_percent.transform.localScale = Vector2.New(1 - wanjiafenduan / 100, 1 - wanjiafenduan / 100)
    UIHelper.SetText(self.tab_Widgets.tx_percent, math.modf(wanjiafenduan) .. "%")
    UIHelper.SetText(self.tab_Widgets.tx_progress, math.modf(wanjiafenduan) .. "%")
    self.tab_Widgets.slider_grade.value = 1 - wanjiafenduan / 100
  end
  UIHelper.SetText(self.tab_Widgets.tx_meritNum, math.modf(userMeritInfo.Merits))
  local rewardId
  for v, k in pairs(configData.p5[1]) do
    local rewardData = configManager.GetDataById("config_big_activity_reward", k)
    if wanjiafenduan >= rewardData.p1 and wanjiafenduan <= rewardData.p2 then
      rewardId = rewardData.reward
    end
  end
  if rewardId ~= nil then
    self.tab_Widgets.obj_gradeNoReward:SetActive(false)
    local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
    UIHelper.CreateSubPart(self.tab_Widgets.obj_rewardItem, self.tab_Widgets.trans_rewardItem, #rewardInfo, function(nIndex, luaPart)
      local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo[nIndex])
      UIHelper.SetImage(luaPart.im_icon, tabReward.texIcon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_num, rewardInfo[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_item, self._ShowRewardInfo, self, rewardInfo[nIndex])
    end)
  else
    self.tab_Widgets.obj_gradeNoReward:SetActive(true)
  end
end

function MeritPage:_LoadUserRank()
  local userMeritInfo = Data.meritData:GetData()
  if userMeritInfo.HistoryMerits == 0 then
    UIHelper.SetText(self.tab_Widgets.tx_rank, "\230\156\170\228\184\138\230\166\156")
  elseif userMeritInfo.Rank == -1 then
    local place = math.ceil(userMeritInfo.MeritsMax / userMeritInfo.HistoryMerits * maxNum)
    if 30000 < place then
      UIHelper.SetText(self.tab_Widgets.tx_rank, "30000\229\144\141\228\187\165\229\164\150")
    else
      UIHelper.SetText(self.tab_Widgets.tx_rank, math.modf(place))
    end
  else
    UIHelper.SetText(self.tab_Widgets.tx_rank, math.modf(userMeritInfo.Rank))
  end
end

function MeritPage:_LoadRankInfo(rankData)
  local configData = configManager.GetDataById("config_activity", self.openID)
  local rewardId
  local rewardData = {}
  local goodPlayer = configManager.GetDataById("config_parameter", 120).arrValue
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.iil_girlsv, self.tab_Widgets.obj_girlItem, #self.tabRankInfo, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local icon, quality = Logic.meritLogic:GetUserHead(self.tabRankInfo[nIndex].UserInfo)
      UIHelper.SetImage(tabPart.im_gongxun, configData.p8[3])
      UIHelper.SetImage(tabPart.im_girl, icon)
      UIHelper.SetText(tabPart.tx_rankNum, math.modf(self.tabRankInfo[nIndex].Rank))
      UIHelper.SetText(tabPart.tx_name, self.tabRankInfo[nIndex].UserInfo.Uname)
      UIHelper.SetText(tabPart.tx_gongxunNum, math.modf(self.tabRankInfo[nIndex].Merits))
      tabPart.im_ranKBg.gameObject:SetActive(false)
      UIHelper.SetImage(tabPart.im_rankIcon, quality)
      if self.tabRankInfo[nIndex].Rank <= #goodPlayer then
        UIHelper.SetImage(tabPart.im_ranKBg, goodPlayer[nIndex][1])
        UIHelper.SetImage(tabPart.im_bg, goodPlayer[nIndex][3])
      else
        UIHelper.SetImage(tabPart.im_bg, "uipic_ui_bigactivity_bg_di4")
      end
      for v, k in pairs(configData.p5[2]) do
        rewardData = configManager.GetDataById("config_big_activity_reward", k)
        if nIndex >= rewardData.p1 and nIndex <= rewardData.p2 then
          rewardId = rewardData.reward
        end
      end
      if rewardId ~= nil then
        local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
        local num = 0
        if #rewardInfo < 2 then
          num = #rewardInfo
        else
          num = 2
        end
        UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.trans_reward, num, function(index, luaPart)
          local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo[index])
          UIHelper.SetImage(luaPart.im_record, tabReward.texIcon)
          UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
          UIHelper.SetText(luaPart.tx_num, rewardInfo[index].Num)
          UGUIEventListener.AddButtonOnClick(luaPart.btn_reward, self._ShowRewardInfo, self, rewardInfo[index])
        end)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_girl, self._ShowHeadInfo, self, self.tabRankInfo[nIndex].Uid)
    end
  end)
end

function MeritPage:_LoadUserReward()
  local rewardId
  local userMeritInfo = Data.meritData:GetData()
  local configData = configManager.GetDataById("config_activity", self.openID)
  for v, k in pairs(configData.p5[2]) do
    rewardData = configManager.GetDataById("config_big_activity_reward", k)
    if userMeritInfo.Rank >= rewardData.p1 and userMeritInfo.Rank <= rewardData.p2 then
      rewardId = rewardData.reward
    end
  end
  if rewardId == nil then
    self.tab_Widgets.obj_noReward:SetActive(true)
  else
    self.tab_Widgets.obj_noReward:SetActive(false)
    local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
    local num = 0
    if #rewardInfo < 2 then
      num = #rewardInfo
    else
      num = 2
    end
    UIHelper.CreateSubPart(self.tab_Widgets.obj_userReward, self.tab_Widgets.trans_userReward, num, function(index, luaPart)
      local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo[index])
      UIHelper.SetImage(luaPart.im_userRewardIcon, tabReward.texIcon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_userRewardNum, rewardInfo[index].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_userReward, self._ShowRewardInfo, self, rewardInfo[index])
    end)
  end
end

function MeritPage:_ShowHeadInfo(go, uid)
  if uid == Data.userData:GetUserUid() then
    noticeManager:ShowTip("\232\191\153\230\152\175\228\189\160\232\135\170\229\183\177")
    return
  end
  local paramTab = {
    Uid = uid,
    Position = go.transform.position
  }
  UIHelper.OpenPage("UserInfoTip", paramTab)
end

function MeritPage:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function MeritPage:_ClickTips()
  UIHelper.OpenPage("MeritRewardPage", self.index)
end

function MeritPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
end

function MeritPage:DoOnClose()
  self.tab_Widgets.tog_group:ClearToggles()
end

return MeritPage
