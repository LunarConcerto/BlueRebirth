local SeaCopyPage = class("UI.Copy.SeaCopyPage", LuaUIPage)
local seaModeChoose = require("ui.page.Copy.SeaModeChoose")
local AllLBPoint = 10000
local tabChase = {}
local tabIsClick = {}

function SeaCopyPage:DoInit()
  tabChase = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabServiceData = {}
  self.nSelectedChapIndex = 0
  self.nChapterNewIndex = 0
  self.m_supportTimers = {}
  self.openAreaIsActivity = false
  self.userInfo = {}
  self.param = nil
  self.diaplayType = 0
  self.actId = 0
  self.safeUpEff = nil
  self.m_timer = nil
  self.co = nil
  self.itemParts = {}
  self.modeAllChapter = {}
  self.currTogSelect = -1
  self.togPart = {}
  self.beforeTog = nil
end

function SeaCopyPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_actHelp, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(widgets.BtnShow, self._BtnShowBox, self)
  UGUIEventListener.AddButtonOnClick(widgets.Btnhide, self._BtnHideBox, self)
  self:RegisterEvent(LuaEvent.UpdateMeritInfo, self._CreateActCopy, self)
  self:RegisterEvent(LuaEvent.UpdateActivity, self.ShowEnter, self)
  self:RegisterEvent(LuaEvent.FetchRewardBox, self._ShowStarReward, self)
end

function SeaCopyPage:DoOnOpen()
  UIHelper.ClosePage("ExRankPage")
  seaModeChoose:Init(self, self.m_tabWidgets)
  self.param = self:GetParam()
  self.openAreaIsActivity = false
  if self.param and self.param[2] then
    self.actId = self.param[2]
    local activityConfig = configManager.GetDataById("config_activity", self.actId)
    self.copyType = activityConfig.seacopy_type
    local chapterTypeConfig = configManager.GetDataById("config_chapter_type", self.copyType)
    self.chapterTypeConfig = chapterTypeConfig
    if activityConfig.type == ActivityType.Festival then
      self:_ActivityCopy()
    elseif activityConfig.type == ActivityType.BigActivity or activityConfig.type == ActivityType.NFestival then
      self.openAreaIsActivity = true
      Logic.copyLogic:DisplayChapterBelong(self.copyType)
      self:_NormalCopy()
    end
  else
    self.copyType = ChapterType.SeaCopy
    self.chapterTypeConfig = configManager.GetDataById("config_chapter_type", self.copyType)
    Logic.copyLogic:DisplayChapterBelong(self.copyType)
    self:_NormalCopy()
  end
  self.m_tabWidgets.btn_actHelp.gameObject:SetActive(false)
  self:_ShowButtons()
end

function SeaCopyPage:_ActivityCopy()
  Service.meritService:SendBigActivity()
  self.diaplayType = self.param[1]
  self.actId = self.param[2]
  self.nSelectedChapIndex = Logic.activityLogic:GetActSeaChapter(self.actId)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = "\230\180\187\229\138\168\230\181\183\229\159\159",
    ChapterId = self.nSelectedChapIndex
  })
  local topItem = Logic.activityLogic:GetTopItem(1001)
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency, topItem)
  eventManager:SendEvent(LuaEvent.CopyPageRefreshChapter, self.nSelectedChapIndex)
  self.tabChapter = Logic.copyLogic:GetChaperConfById(self.nSelectedChapIndex)
  UIHelper.SetImage(self.m_tabWidgets.im_bg, self.tabChapter.copy_background)
  local show = Logic.copyLogic:ShowRandFactorsNew("randFactorsHelp")
  if show then
    self:_ClickHelp()
    Service.guideService:SendUserSetting({
      {
        Key = "randFactorsHelp",
        Value = "notDisplayed"
      }
    })
  end
  self.m_tabWidgets.rect_content.anchoredPosition = Vector2.New(self.m_tabWidgets.rect_content.anchoredPosition.x, self.m_tabWidgets.rect_content.anchoredPosition.y - 60)
end

function SeaCopyPage:_CreateActCopy()
  if self.actId == 0 then
    return
  end
  local tabActChapterConfig = Logic.copyLogic:GetActConfig(self.nSelectedChapIndex)
  local count = #tabActChapterConfig.level_list
  local limit = Logic.meritLogic:GetExtraRewardTimes(self.actId)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_areaInfoItem, self.m_tabWidgets.trans_areaInfoContent, count, function(nIndex, tabPart)
    tabPart.obj_activity:SetActive(true)
    tabPart.tx_chapter.gameObject:SetActive(false)
    tabPart.obj_chase:SetActive(false)
    tabPart.im_chaseFight.gameObject:SetActive(false)
    tabPart.obj_BossHP:SetActive(false)
    tabPart.obj_starLevel:SetActive(false)
    tabPart.im_icon.gameObject:SetActive(false)
    tabPart.tx_name.gameObject:SetActive(false)
    tabPart.obj_nameBg:SetActive(false)
    tabPart.obj_safe:SetActive(false)
    tabPart.txt_safeName.gameObject:SetActive(false)
    tabPart.txt_actName.text = tabActChapterConfig.name_list[nIndex]
    local extraRewardNum = Logic.meritLogic:GetExtraReward(nIndex)
    extraRewardNum = extraRewardNum ~= nil and extraRewardNum or 0
    tabPart.obj_extra:SetActive(extraRewardNum < limit)
    UIHelper.SetImage(tabPart.img_actIcon, tabActChapterConfig.copy_thumbnail_list[nIndex], true)
    tabPart.im_area.transform.anchoredPosition3D = Vector2.New(self.tabChapter.copy_pos_x[nIndex], self.tabChapter.copy_pos_y[nIndex])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fun.gameObject, function()
      if not Logic.copyChapterLogic:CheckAllByChapterId(self.nSelectedChapIndex) then
        return
      end
      local isHasFleet = Logic.fleetLogic:IsHasFleet()
      if not isHasFleet then
        noticeManager:OpenTipPage(self, 110007)
        return
      end
      local param = {
        tabActChapterConfig.level_list[nIndex],
        tabActChapterConfig.name_list[nIndex],
        self.nSelectedChapIndex,
        self.actId,
        nIndex
      }
      UIHelper.OpenPage("SelectCopyPage", param)
    end)
  end)
end

function SeaCopyPage:_NormalCopy()
  Logic.copyLogic:SetCurrDisplayPlotIndex(nil)
  eventManager:SendEvent(LuaEvent.ShowOpenModule)
  self.userInfo = Data.userData:GetUserData()
  self.uid = tostring(self.userInfo.Uid)
  self.m_tabServiceData = Data.copyData:GetCopyInfo()
  self:_InitCopy()
  self:ShowEnter()
end

function SeaCopyPage:ShowEnter()
  local widgets = self:GetWidgets()
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", self.copyType)
  widgets.img_activity.gameObject:SetActive(chapterTypeConfig.show_activity_enter ~= 0)
  if chapterTypeConfig.show_activity_enter == 0 then
    return
  end
  local configs = Logic.enterLogic:GetCopyEnterByType(self.copyType)
  widgets.img_activity.gameObject:SetActive(#configs ~= 0)
  if #configs <= 0 then
    return
  end
  UIHelper.CreateSubPart(widgets.activity, widgets.trans_act, #configs, function(index, tabPart)
    local config = configs[index]
    local img = tabPart.img_activity
    local txt = tabPart.txt_activity
    img.gameObject:SetActive(config)
    txt.gameObject:SetActive(config and config.activity_name ~= "")
    if config then
      UIHelper.SetText(txt, config.activity_name)
      UIHelper.SetImage(img, config.activity_icon)
      if #config.reddot_id > 0 then
        self:RegisterRedDotByParamList(tabPart.reddot, config.reddot_id, config.reddot_param)
      end
      UGUIEventListener.AddButtonOnClick(img, function()
        moduleManager:JumpToFunc(config.jump_function, table.unpack(config.jump_para))
      end)
    end
  end)
end

function SeaCopyPage:_InitCopy()
  self.initChapterId = Logic.copyLogic:GetInitChapterIdByType(self.copyType)
  local chapterId, _ = Logic.copyLogic:GetFarestId(self.copyType)
  if self.param ~= nil and self.param.SelectedChapIndex ~= nil then
    self.nSelectedChapIndex = self.param.SelectedChapIndex
  else
    self.nSelectedChapIndex = PlayerPrefs.GetInt(self.uid .. "SeaCopyPage" .. self.copyType, chapterId)
  end
  if self.copyType == ChapterType.ActSeaCopyEx or self.copyType == ChapterType.AdventureCopy then
    self.nSelectedChapIndex = chapterId >= self.nSelectedChapIndex and self.nSelectedChapIndex or self.initChapterId
  end
  self.nChapterNewIndex = chapterId
  self.tabChapter = Logic.copyLogic:GetChaperConfById(self.nSelectedChapIndex)
  local configInfoTab = Logic.copyLogic:GetChapterBelong(self.nSelectedChapIndex)
  if next(self.tabChapter.belong_chapter_list) ~= nil and not Logic.copyLogic:CheckIsDay(self.copyType) then
    self.nSelectedChapIndex = configInfoTab[SeaCopyStage.Day].id
    PlayerPrefs.SetInt(self.uid .. "SeaCopyPage" .. self.copyType, self.nSelectedChapIndex)
  end
  GR.guideHub:getGuideCachedata():SetSeacopyChapterId(self.nSelectedChapIndex)
  self:_BattleMode()
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", self.copyType)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = chapterTypeConfig.top_text,
    ChapterId = self.nSelectedChapIndex
  })
  eventManager:SendEvent(LuaEvent.CopyPageRefreshChapter, self.nSelectedChapIndex)
  self.m_tabWidgets.rect_content.anchoredPosition = Vector2.New(0, 0)
end

function SeaCopyPage:_CreateAreaInfo()
  self.tabChapter = Logic.copyLogic:GetChaperConfById(self.nSelectedChapIndex)
  UIHelper.SetImage(self.m_tabWidgets.im_bg, self.tabChapter.copy_background)
  local tabAreaDesInfo = Logic.copyLogic:GetAreaConfig(self.nSelectedChapIndex)
  for v, k in pairs(tabAreaDesInfo) do
    if self.m_tabServiceData[k.id] ~= nil then
      if self.m_tabServiceData[k.id].IsRunningFight == false then
        tabChase[k.id] = false
      elseif self.m_tabServiceData[k.id].IsRunningFight == true and tabIsClick[k.id] == nil then
        tabChase[k.id] = true
      else
        tabChase[k.id] = tabChase[k.id]
      end
    else
      tabChase[k.id] = false
    end
  end
  local count = #tabAreaDesInfo
  local tabActChapterConfig = Logic.copyLogic:GetChaperConfById(self.nSelectedChapIndex)
  local conditionPeriod, conditionCopy = Logic.copyChapterLogic:IsOpenByChapter(self.nSelectedChapIndex)
  local isOpen = conditionPeriod and conditionCopy
  self.m_tabWidgets.obj_open:SetActive(not isOpen)
  if not isOpen then
    self.m_tabWidgets.tx_opentime:SetActive(not conditionPeriod)
    if not conditionPeriod then
      local startTime, endTime = PeriodManager:GetPeriodTime(tabActChapterConfig.chapter_period, tabActChapterConfig.chapter_periodarea)
      local startTimeFormat = time.formatTimeToMDHM(startTime)
      local endTimeFormat = time.formatTimeToMDHM(endTime)
      UIHelper.SetText(self.m_tabWidgets.tx_time, startTimeFormat .. "-" .. endTimeFormat)
    end
    self.m_tabWidgets.tx_opelimit:SetActive(not conditionCopy)
    if not conditionCopy then
      local fullName = Logic.copyLogic:GetFullNameById(tabActChapterConfig.chapter_open)
      UIHelper.SetText(self.m_tabWidgets.tx_chapter, fullName)
    end
    count = 0
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_areaInfoItem, self.m_tabWidgets.trans_areaInfoContent, count, function(nAreaIndex, tabPart)
    self:_SetAreaItem(tabAreaDesInfo[nAreaIndex], tabPart, nAreaIndex)
  end)
  self:PerformDelay(0.5, function()
    Logic.copyLogic:ClearSafeInfo()
  end)
  self:_CreateDropShip()
end

function SeaCopyPage:_SetAreaItem(tabAreaDesInfo, tabPart, nAreaIndex)
  self.tabChapter = configManager.GetDataById("config_chapter", self.nSelectedChapIndex)
  local baseId = tabAreaDesInfo.id
  local copyIsSweep = false
  self.sweepCopyInfo = Data.copyData:GetSweepCopyInfo()
  if self.sweepCopyInfo ~= nil and #self.sweepCopyInfo > 0 then
    for i = 1, #self.sweepCopyInfo do
      if baseId == self.sweepCopyInfo[i].copyId then
        copyIsSweep = true
      end
    end
  end
  tabPart.obj_activity:SetActive(false)
  tabPart.tx_name.text = tabAreaDesInfo.name
  tabPart.tx_chapter.text = tabAreaDesInfo.str_index
  tabPart.obj_autobattle:SetActive(copyIsSweep)
  tabPart.im_area.transform.anchoredPosition3D = Vector2.New(self.tabChapter.copy_pos_x[nAreaIndex], self.tabChapter.copy_pos_y[nAreaIndex])
  tabPart.obj_nameBg:SetActive(true)
  local nameBgImg = Logic.copyLogic:CheckIsDay(self.copyType) and "uipic_ui_copy_bg_guanqiamingzi_di" or "uipic_ui_copy_bg_guanqiadi_yewan"
  UIHelper.SetImage(tabPart.img_nameBg, nameBgImg)
  if self.m_tabServiceData[baseId] then
    local config = configManager.GetDataById("config_copy_display", baseId)
    local rewardTbl = DropRewardsHelper.GetDropDisplayCopy(config.drop_info_id)
    tabPart.RewardTrans.gameObject:SetActive(0 < #rewardTbl)
    UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.RewardTrans, #rewardTbl, function(indexSub, tabPartSub)
      local rewardSub = rewardTbl[indexSub]
      local rewardLen = #rewardSub
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local display = ItemInfoPage.GenDisplayData(rewardSub[1], rewardSub[2])
      UIHelper.SetImage(tabPartSub.Icon, display.icon_small)
      tabPartSub.TextNum.gameObject:SetActive(2 < rewardLen)
      if rewardLen == 3 then
        UIHelper.SetText(tabPartSub.TextNum, "x" .. rewardSub[3])
      elseif 4 <= rewardLen then
        if rewardSub[3] == rewardSub[4] then
          UIHelper.SetText(tabPartSub.TextNum, "x" .. rewardSub[3])
        else
          UIHelper.SetText(tabPartSub.TextNum, "x" .. rewardSub[3] .. "~" .. rewardSub[4])
        end
      end
    end)
    tabPart.im_area:SetActive(true)
    self:_CreateBossInfo(baseId, tabPart, tabAreaDesInfo)
    self:_CreateChaseFighting(self.m_tabServiceData[baseId], tabPart, tabAreaDesInfo)
    self:_CreateShowStar(self.m_tabServiceData[baseId].StarLevel, tabPart)
    table.insert(self.itemParts, tabPart)
    self:_CreateSafe(self.m_tabServiceData[baseId], tabPart, tabAreaDesInfo.stageid)
    if self.m_tabServiceData[baseId].FirstPassTime == 0 then
      UIHelper.SetImage(tabPart.im_icon, tabAreaDesInfo.copy_thumbnail_before)
    else
      UIHelper.SetImage(tabPart.im_icon, tabAreaDesInfo.copy_thumbnail_after)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fun.gameObject, function()
      local isHasFleet = Logic.fleetLogic:IsHasFleet()
      if not isHasFleet then
        noticeManager:OpenTipPage(self, 110007)
        return
      end
      if not Logic.copyLogic:CheckOpenByCopyId(baseId, true) then
        return
      end
      local areaConfig = {
        copyType = CopyType.COMMONCOPY,
        tabSerData = self.m_tabServiceData[baseId],
        chapterId = self.nSelectedChapIndex,
        IsRunningFight = tabChase[baseId],
        copyId = baseId,
        IsOpenActivity = self.openAreaIsActivity
      }
      Logic.copyLogic:SetEnterLevelInfo(true)
      UIHelper.OpenPage("LevelDetailsPage", areaConfig)
    end)
  else
    self:_CreateShowStar(0, tabPart)
    tabPart.obj_chase:SetActive(false)
    tabPart.im_chaseFight.gameObject:SetActive(false)
    tabPart.obj_BossHP:SetActive(false)
    UIHelper.SetImage(tabPart.im_icon, tabAreaDesInfo.copy_thumbnail_before)
    tabPart.im_area:SetActive(false)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fun, function()
      local msg = self:_CheckSeaOpenCondtion(tabAreaDesInfo)
      noticeManager:OpenTipPage(self, msg)
    end)
  end
  local isExCopyId = Logic.copyChapterLogic:IsExCopyId(self.copyType, baseId)
  tabPart.im_icon.gameObject:SetActive(not isExCopyId)
  tabPart.obj_nameBg:SetActive(not isExCopyId)
  tabPart.imgExActivityBG.gameObject:SetActive(isExCopyId)
  UIHelper.SetImage(tabPart.imgExActivityBG, tabAreaDesInfo.copy_thumbnail_before, true)
  tabPart.obj_starLevel:SetActive(not isExCopyId)
end

function SeaCopyPage:_CheckSeaOpenCondtion(tabAreaDesInfo)
  if tabAreaDesInfo.sea_area_unlock > 0 then
    local copyInfo = Data.copyData:GetPlotCopyDataCopyId(tabAreaDesInfo.sea_area_unlock)
    if not copyInfo or copyInfo.FirstPassTime == 0 then
      local lock = Logic.copyLogic:GetCopyDesConfig(tabAreaDesInfo.sea_area_unlock)
      local chapterId = Logic.copyLogic:GetChapterIdByCopyId(tabAreaDesInfo.sea_area_unlock)
      local chapterConf = Logic.copyLogic:GetChaperConfById(chapterId)
      return string.format(UIHelper.GetString(130005), chapterConf.title, lock.name)
    end
  end
  if Data.userData:GetUserLevel() < tabAreaDesInfo.level_limit then
    return string.format(UIHelper.GetString(130006), tabAreaDesInfo.level_limit)
  end
  return UIHelper.GetString(130007)
end

function SeaCopyPage:_CreateShowStar(param, tabPart)
  tabPart.obj_oneStar:SetActive(param & 1 == 1)
  tabPart.obj_oneTexiao:SetActive(param & 1 == 1)
  tabPart.obj_twoStar:SetActive(param & 2 == 2)
  tabPart.obj_twoTexiao:SetActive(param & 2 == 2)
  tabPart.obj_threeStar:SetActive(param & 4 == 4)
  tabPart.obj_threeTexiao:SetActive(param & 4 == 4)
end

function SeaCopyPage:_CreateChaseFighting(copyDataConfig, tabPart, tabAreaDesInfo)
  local chase = Logic.copyLogic:GetChase()
  if chase[copyDataConfig.BaseId] ~= nil then
    tabChase[copyDataConfig.BaseId] = chase[copyDataConfig.BaseId]
  else
    tabChase[copyDataConfig.BaseId] = tabChase[copyDataConfig.BaseId]
  end
  tabPart.obj_chase:SetActive(copyDataConfig.IsRunningFight)
  tabPart.obj_starLevel:SetActive(true)
  if copyDataConfig.IsRunningFight then
    UGUIEventListener.AddButtonOnClick(tabPart.bu_chaseFight, function()
      tabChase[copyDataConfig.BaseId] = not tabChase[copyDataConfig.BaseId]
      tabPart.im_chaseFight.gameObject:SetActive(tabChase[copyDataConfig.BaseId])
      if tabChase[copyDataConfig.BaseId] then
        self:_SetChaseShowInfo(copyDataConfig, tabPart)
      else
        tabPart.tx_levelDetail.text = "\229\133\179\229\141\161" .. tabAreaDesInfo.title
        tabPart.tx_name.text = tabAreaDesInfo.name
      end
      tabIsClick[copyDataConfig.BaseId] = true
      Logic.copyLogic:SetChase(tabChase)
    end)
    if tabChase[copyDataConfig.BaseId] then
      tabPart.im_chaseFight.gameObject:SetActive(true)
      self:_SetChaseShowInfo(copyDataConfig, tabPart)
    else
      tabPart.im_chaseFight.gameObject:SetActive(false)
    end
  else
    tabPart.im_chaseFight.gameObject:SetActive(false)
    tabPart.obj_chase:SetActive(false)
  end
end

function SeaCopyPage:_SetChaseShowInfo(copyDataConfig, tabPart)
  local chaseCopyId = Logic.copyLogic:GetCopyChaseInfo(self.nSelectedChapIndex, copyDataConfig.BaseId)
  if chaseCopyId ~= nil then
    local chaseCopyconf = Logic.copyLogic:GetCopyDesConfig(chaseCopyId)
    tabPart.tx_name.text = chaseCopyconf.name
    tabPart.tx_chapter.text = chaseCopyconf.str_index
  else
    logError("\230\178\161\230\156\137\232\191\189\229\135\187\230\136\152\231\155\184\229\133\179\233\133\141\231\189\174\230\149\176\230\141\174")
  end
end

function SeaCopyPage:_CreateBossInfo(areaId, tabPart, tabAreaDesInfo)
  tabPart.obj_BossHP:SetActive(tabAreaDesInfo.is_boss_copy == 1 and AllLBPoint - self.m_tabServiceData[areaId].LBPoint > 0 and self.m_tabServiceData[areaId].FirstPassTime == 0)
  if tabAreaDesInfo.is_boss_copy == 1 and AllLBPoint - self.m_tabServiceData[areaId].LBPoint > 0 then
    self:_ShowBossInfo(areaId, tabPart, tabAreaDesInfo)
  end
end

function SeaCopyPage:_ShowBossInfo(areaId, tabPart, tabAreaDesInfo)
  local effect_boss = tabPart.obj_BossHP.transform:Find(tabAreaDesInfo.choice_boss .. "(Clone)")
  if self.m_tabServiceData[areaId].FirstPassTime == 0 and effect_boss == nil then
    local bossPath = "effects/prefabs/ui/" .. tabAreaDesInfo.choice_boss
    local bossObj = self:CreateUIEffect(bossPath, tabPart.obj_BossHP.transform)
    local bossHp = bossObj.transform:Find("im_slider01").gameObject:GetComponent(UIImage.GetClassType())
    local bossHpDi = bossObj.transform:Find("im_slider").gameObject:GetComponent(UIImage.GetClassType())
    local bossNum = bossObj.transform:Find("Text").gameObject:GetComponent(UIText.GetClassType())
    if bossHp ~= nil then
      local point = self.m_tabServiceData[areaId].LBPoint
      local percent = (AllLBPoint - point) / AllLBPoint
      bossHp.fillAmount = percent
      bossHpDi.fillAmount = percent
      bossNum.text = math.ceil(percent * 100) .. "%"
    else
      noticeManager:ShowMsgBox("\232\142\183\229\143\150\232\161\128\230\157\161\231\187\132\228\187\182\228\191\161\230\129\175\233\148\153\232\175\175")
    end
  end
end

function SeaCopyPage:_ShowButtons()
  local chapterMax = 0
  if Logic.copyLogic:CheckIsDay(self.copyType) then
    chapterMax, _ = Logic.copyLogic:GetFarestId(self.copyType)
  else
    chapterMax = self.nChapterNewIndex
  end
  self.m_tabWidgets.btn_right.gameObject:SetActive(self.nSelectedChapIndex ~= chapterMax)
end

function SeaCopyPage:_ClickLeft()
  if self.nSelectedChapIndex > self.initChapterId then
    self.nSelectedChapIndex = Logic.copyLogic:GetNeedChapterId(self.nSelectedChapIndex, self.modeAllChapter, false)
    self:_BattleMode()
    self:_CreateAreaInfo()
  end
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex ~= self.initChapterId
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.nChapterNewIndex
  self:_UpdateCopy()
  self:_ShowButtons()
end

function SeaCopyPage:_ClickRight()
  local max = configManager.GetDataById("config_parameter", 94).value
  if not Logic.copyLogic:CheckIsDay(self.copyType) then
    max = self.nChapterNewIndex
  end
  if self.nSelectedChapIndex < self.nChapterNewIndex then
    self.nSelectedChapIndex = Logic.copyLogic:GetNeedChapterId(self.nSelectedChapIndex, self.modeAllChapter, true)
    self:_BattleMode()
    self:_CreateAreaInfo()
  elseif max > self.nSelectedChapIndex then
    local tabAreaDesInfo = Logic.copyLogic:GetAreaConfig(self.nSelectedChapIndex + 1)
    local msg = self:_CheckSeaOpenCondtion(tabAreaDesInfo[1])
    noticeManager:OpenTipPage(self, msg)
  else
    noticeManager:OpenTipPage(self, 130004)
  end
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex ~= self.initChapterId
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.nChapterNewIndex
  self:_ShowButtons()
  self:_UpdateCopy()
end

function SeaCopyPage:_UpdateCopy()
  if self.safeUpEff ~= nil then
    self:DestroyEffect(self.safeUpEff)
    self.safeUpEff = nil
  end
  if self.m_timer ~= nil and isTimer then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
  if self.co ~= nil then
    coroutine.stop(self.co)
    self.co = nil
  end
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", self.copyType)
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = chapterTypeConfig.top_text,
    ChapterId = self.nSelectedChapIndex
  })
  eventManager:SendEvent(LuaEvent.CopyPageRefreshChapter, self.nSelectedChapIndex)
  PlayerPrefs.SetInt(self.uid .. "SeaCopyPage" .. self.copyType, self.nSelectedChapIndex)
  GR.guideHub:getGuideCachedata():SetSeacopyChapterId(self.nSelectedChapIndex)
  self.tabChapter = configManager.GetDataById("config_chapter", self.nSelectedChapIndex)
  UIHelper.SetImage(self.m_tabWidgets.im_bg, self.tabChapter.copy_background)
  self:_ShowStarReward()
end

function SeaCopyPage:DoOnHide()
  if self.safeUpEff ~= nil then
    self:DestroyEffect(self.safeUpEff)
    self.safeUpEff = nil
  end
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
  if self.co ~= nil then
    coroutine.stop(self.co)
    self.co = nil
  end
  for _, tabPart in ipairs(self.itemParts) do
    self:_CreateShowStar(0, tabPart)
  end
end

function SeaCopyPage:DoOnClose()
  if self.safeUpEff ~= nil then
    self:DestroyEffect(self.safeUpEff)
    self.safeUpEff = nil
  end
  for _, timer in pairs(self.m_supportTimers) do
    if timer ~= nil then
      self:StopTimer(timer)
    end
  end
  if self.co ~= nil then
    coroutine.stop(self.co)
    self.co = nil
  end
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency)
end

function SeaCopyPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {
    title = "\231\142\169\230\179\149\232\175\180\230\152\142",
    content = 460001
  })
end

function SeaCopyPage:_CreateSafe(serInfo, tabPart, stageId)
  if stageId == 0 then
    tabPart.obj_safe:SetActive(false)
    tabPart.txt_safeName.gameObject:SetActive(false)
    return
  end
  local showUp = Logic.copyLogic:ShowSafeUpEff(serInfo.BaseId)
  if not showUp then
    self:_ShowSafeInfo(serInfo.SfLv, serInfo.SfPoint, tabPart, stageId, false)
  else
    local oldInfo = Logic.copyLogic:GetLastAttackSafeInfo()
    local oldLv = oldInfo.SfLv or serInfo.SfLv - 1
    local oldPoint = oldInfo.SfPoint or serInfo.SfPoint - 1
    self:_ShowSafeInfo(oldLv, oldPoint, tabPart, stageId, false)
    self.co = coroutine.start(function()
      coroutine.wait(0.8, self.co)
      coroutine.stop(self.co)
      self.co = nil
      tabPart.obj_safeUpEff:SetActive(true)
      local eff, duration = Logic.copyLogic:GetSafeUpEff(oldLv)
      if self.safeUpEff ~= nil then
        self:DestroyEffect(self.safeUpEff)
        self.safeUpEff = nil
      end
      self.safeUpEff = self:CreateUIEffect(eff, tabPart.obj_safeUpEff.transform)
      local effPart = self.safeUpEff:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
      local config = Logic.copyLogic:GetCurrSafeConfig(stageId, serInfo.SfLv, serInfo.SfPoint, false)
      UIHelper.SetTextColor(effPart.txt_desc, UIHelper.GetLocString(510010, config.name), config.nameColor)
      local color = config.effect_outline_color
      local outline = Color.New(color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255)
      effPart.txt_outline.effectColor = outline
      self:PerformDelay(2, function()
        if self.safeUpEff ~= nil then
          self:DestroyEffect(self.safeUpEff)
          self.safeUpEff = nil
        end
      end)
      if self.m_timer == nil then
        self.m_timer = self:CreateTimer(function()
          self:_ShowSafeInfo(serInfo.SfLv, serInfo.SfPoint, tabPart, stageId, true)
        end, duration, 1, false)
      end
      self:StartTimer(self.m_timer)
    end)
  end
end

function SeaCopyPage:_ShowSafeInfo(sfLv, sfPoint, tabPart, stageId, isTimer)
  if self.m_timer ~= nil and isTimer then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
  tabPart.obj_safe:SetActive(true)
  tabPart.txt_safeName.gameObject:SetActive(true)
  local config = Logic.copyLogic:GetCurrSafeConfig(stageId, sfLv, sfPoint, false)
  tabPart.slider_safe.value = config.sliderValue
  UIHelper.SetTextColor(tabPart.txt_safeName, config.name, config.nameColor)
  UIHelper.SetImage(tabPart.img_slider, config.sliderImage)
end

function SeaCopyPage:_ShowStarReward()
  local widgets = self:GetWidgets()
  local conditionPeriod, conditionCopy = Logic.copyChapterLogic:IsOpenByChapter(self.nSelectedChapIndex)
  local isOpen = conditionPeriod and conditionCopy
  widgets.StarReward:SetActive(isOpen)
  if not isOpen then
    return
  end
  local config = self.tabChapter
  local star_img = config.starimage
  local starpositionx = config.starpositionx
  local star_reward = config.star_reward
  local star_cond = config.star_cond
  local chapterId = self.nSelectedChapIndex
  local chapterStar = Data.copyData:GetChapterStar(chapterId)
  local len = #star_reward
  widgets.StarReward:SetActive(0 < len)
  if len <= 0 then
    return
  end
  self:RegisterRedDot(widgets.redDot, self.nSelectedChapIndex)
  local star_max = star_cond[#star_cond]
  local config_parameter
  if len == 3 then
    config_parameter = configManager.GetDataById("config_parameter", 195).arrValue
  else
    config_parameter = configManager.GetDataById("config_parameter", 194).arrValue
  end
  self.m_tabWidgets.TweenPos.from = Vector3.New(config_parameter[1][1], config_parameter[1][2], config_parameter[1][3])
  self.m_tabWidgets.TweenPos.to = Vector3.New(config_parameter[2][1], config_parameter[2][2], config_parameter[2][3])
  self.boxState = Logic.copyLogic:GetBoxStateByType(self.copyType)
  widgets.BtnShow.gameObject:SetActive(self.boxState)
  widgets.Btnhide.gameObject:SetActive(not self.boxState)
  if self.boxState == true then
    widgets.rewardTrans.position = widgets.pos_on.position
  elseif len == 3 then
    widgets.rewardTrans.position = widgets.pos_off_act.position
  else
    widgets.rewardTrans.position = widgets.pos_off.position
  end
  local unFetchTable = {}
  local unFetchRewardIds = {}
  for index = 1, len do
    local status = Data.copyData:GetRewardBoxStatus(self.nSelectedChapIndex, index)
    if chapterStar >= star_cond[index] and status == false then
      table.insert(unFetchTable, index)
      table.insert(unFetchRewardIds, star_reward[index])
    end
  end
  widgets.imgNoReward:SetActive(#unFetchTable <= 0)
  local levelNum = star_cond[#star_cond]
  local val = chapterStar * len / (levelNum * 4)
  if 1 < val then
    logError("", chapterStar, val)
  end
  widgets.Scrollbar.size = val
  widgets.imgXian:SetActive(0 < val)
  widgets.FullHandle:SetActive(1 <= chapterStar / levelNum)
  UIHelper.CreateSubPart(widgets.obj_star_reward, widgets.content_star_reward, len, function(index, tabPart)
    UIHelper.SetText(tabPart.num, star_cond[index])
    local star_box = config.star_box[index]
    local boxConfig = configManager.GetDataById("config_starbox", star_box)
    local rewardId = star_reward[index]
    local rewardState
    local rewards = {}
    UIHelper.SetImage(tabPart.imageStar, star_img[index])
    local isFetch = Data.copyData:GetRewardBoxStatus(self.nSelectedChapIndex, index)
    if chapterStar < star_cond[index] then
      UIHelper.SetImage(tabPart.icon, boxConfig.unopen_icon)
      rewardState = RewardState.UnReceivable
      rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    elseif isFetch then
      UIHelper.SetImage(tabPart.icon, boxConfig.recieved_icon)
      rewardState = RewardState.Received
      rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    else
      UIHelper.SetImage(tabPart.icon, boxConfig.open_icon)
      rewardState = RewardState.Receivable
      rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    end
    tabPart.Effect:SetActive(rewardState == RewardState.Receivable)
    tabPart.trans.localPosition = Vector3.New(boxConfig.positionx, boxConfig.positiony, 0)
    local y = tabPart.rectTrans.localPosition.y
    tabPart.rectTrans.localPosition = Vector3.New(starpositionx[index], y, 0)
    local param = {}
    param.rewardState = rewardState
    param.rewards = rewards
    
    function param.callback()
      Service.copyService:FetchRewardBox({
        ChapterId = chapterId,
        IndexList = {index}
      })
    end
    
    UGUIEventListener.AddButtonOnClick(tabPart.btn, self._BtnRewardBox, self, param)
  end)
end

function SeaCopyPage:_BtnRewardBox(go, param)
  UIHelper.OpenPage("BoxRewardPage", param)
end

function SeaCopyPage:_BtnShowBox(go)
  local widgets = self:GetWidgets()
  self.boxState = false
  Logic.copyLogic:SetBoxStateByType(self.copyType, false)
  widgets.BtnShow.gameObject:SetActive(self.boxState)
  widgets.Btnhide.gameObject:SetActive(not self.boxState)
  self.m_tabWidgets.TweenPos:Play(false)
end

function SeaCopyPage:_BtnHideBox(go)
  local widgets = self:GetWidgets()
  self.boxState = true
  Logic.copyLogic:SetBoxStateByType(self.copyType, true)
  widgets.BtnShow.gameObject:SetActive(self.boxState)
  widgets.Btnhide.gameObject:SetActive(not self.boxState)
  self.m_tabWidgets.TweenPos:Play(true)
end

function SeaCopyPage:_CreateDropShip()
  local dropShipTab = Logic.copyLogic:GetCopyDropShip(self.nSelectedChapIndex)
  self.m_tabWidgets.trans_shipDrop.gameObject:SetActive(dropShipTab ~= nil)
  if dropShipTab == nil then
    return
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_dropItem, self.m_tabWidgets.trans_shipDrop, #dropShipTab, function(index, tabPart)
    local dropInfo = dropShipTab[index]
    UIHelper.SetImage(tabPart.img_bg, dropInfo.shipBg)
    UIHelper.SetImage(tabPart.img_icon, dropInfo.shipIcon)
    tabPart.txt_tips.text = string.format(UIHelper.GetString(131000), dropInfo.copyIndex)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_drop, self._ClickDropShip, self, dropInfo)
  end)
end

function SeaCopyPage:_ClickDropShip(go, dropInfo)
  local name = "<color=#" .. dropInfo.nameColor .. ">" .. dropInfo.shipName .. "</color>"
  local str = string.format(UIHelper.GetString(131001), dropInfo.copyIndex, name)
  noticeManager:OpenTipPage(self, str)
end

function SeaCopyPage:_SwitchTogs(index)
  self.modeAllChapter = Logic.copyLogic:GetBattleModeChapter(self.copyType, index)
  local battleModeTab = Logic.copyLogic:GetChapterBelong(self.nSelectedChapIndex)
  index = index + 1
  if next(self.tabChapter.belong_chapter_list) ~= nil then
    self.nSelectedChapIndex = battleModeTab[index].id
  end
  if index == SeaCopyStage.Day then
    self.initChapterId = Logic.copyLogic:GetInitChapterIdByType(self.copyType)
    self.nChapterNewIndex, _ = Logic.copyLogic:GetFarestId(self.copyType)
  else
    self.initChapterId = self.modeAllChapter[1]
    self.nChapterNewIndex = self.modeAllChapter[#self.modeAllChapter]
  end
  local typeConfig = Logic.copyLogic:GetTypeInfoById(index)
  UIHelper.SetImage(self.m_tabWidgets.img_selectModeC, typeConfig.check_image)
  self.m_tabWidgets.txt_modeName.text = typeConfig.desc
  Logic.copyLogic:SetCurrBattleMode(self.copyType, index)
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex ~= self.initChapterId
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.nChapterNewIndex
  self:_CreateAreaInfo()
  self:_ShowButtons()
  if self.currTogSelect == -1 then
    self:_ShowStarReward()
  else
    self:_UpdateCopy()
  end
  self.currTogSelect = index
  self:DisposeTog()
end

function SeaCopyPage:_BattleMode()
  self.tabChapter = Logic.copyLogic:GetChaperConfById(self.nSelectedChapIndex)
  seaModeChoose:ShowChooseMode(self.nSelectedChapIndex, self.copyType)
end

function SeaCopyPage:DisposeTog()
  if self.beforeTog ~= nil then
    self.beforeTog.layout.preferredWidth = 0
    self.beforeTog.txt_name.gameObject:SetActive(true)
  end
  if next(self.togPart) ~= nil then
    local togItem = self.togPart[self.currTogSelect]
    togItem.txt_name.gameObject:SetActive(false)
    togItem.layout.preferredWidth = 30
    self.beforeTog = togItem
  end
end

return SeaCopyPage
