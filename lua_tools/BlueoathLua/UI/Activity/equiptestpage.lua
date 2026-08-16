local EquipTestPage = class("UI.Activity.EquipTestPage", LuaUIPage)
local txtGrades = {
  "txt_s",
  "txt_ss",
  "txt_sss"
}
local sgrades = {
  "s",
  "ss",
  "sss"
}
local progress = {
  0.247,
  0.565,
  1
}

function EquipTestPage:DoOpen()
  local activities = Logic.activityLogic:GetOpenActivityByType(ActivityType.EquipTest)
  if #activities <= 0 then
    logError("TestShip Activity not open")
    return
  end
  local widgets = self:GetWidgets()
  self.activityCfg = activities[1]
  local periodInfo = configManager.GetDataById("config_period", self.activityCfg.period)
  local startTime = PeriodManager:GetPeriodTime(self.activityCfg.period, self.activityCfg.period_area)
  local startTimeFormat = time.formatTimerToMDH(startTime)
  local endTimeFormat = time.formatTimerToMDH(startTime + periodInfo.duration)
  UIHelper.SetText(widgets.txt_time, string.format("%s~%s", startTimeFormat, endTimeFormat))
  UIHelper.SetLocText(widgets.txt_tips, self.activityCfg.p5[1])
  UIHelper.SetLocText(widgets.txt_equipname, self.activityCfg.p6[1])
  UIHelper.SetLocText(widgets.txt_attr, self.activityCfg.p6[2])
  UIHelper.SetLocText(widgets.txt_des1, self.activityCfg.p6[3])
  UIHelper.SetLocText(widgets.txt_des2, self.activityCfg.p6[4])
  UIHelper.SetLocText(widgets.txt_dialog1, self.activityCfg.p8[1])
  UIHelper.SetLocText(widgets.txt_dialog2, self.activityCfg.p8[2])
  UIHelper.SetLocText(widgets.txt_dialog3, self.activityCfg.p8[3])
  UIHelper.SetLocText(widgets.txt_dialog1, self.activityCfg.p8[1])
  UIHelper.SetLocText(widgets.txt_dialog2, self.activityCfg.p8[2])
  UIHelper.SetLocText(widgets.txt_dialog3, self.activityCfg.p8[3])
  UIHelper.SetImage(widgets.img_bg, self.activityCfg.p10[1])
  UIHelper.SetImage(widgets.img_quality, self.activityCfg.p10[2])
  UIHelper.SetImage(widgets.img_equip, self.activityCfg.p10[3])
  UIHelper.SetImage(widgets.img_title, self.activityCfg.p11[1])
  local damageData = self.activityCfg.p4
  local sssDamage = damageData[#damageData][1]
  local startPos = widgets.obj_start.position.x
  local endPos = widgets.obj_end.position.x
  for i, data in ipairs(damageData) do
    local arrowX = data[1] / sssDamage * (endPos - startPos) + startPos
    local oldPos = widgets["obj_" .. sgrades[i]].position
    widgets["obj_" .. sgrades[i]].position = Vector3.New(arrowX, oldPos.y, oldPos.z)
  end
  local maxDamage = Data.equipTestCopyData:GetMaxDamage()
  local level = Logic.equipTestCopyLogic:GetLevelByDamage(self.activityCfg, maxDamage)
  for i = 1, #txtGrades do
    local content = UIHelper.GetLocString(self.activityCfg.p7[i], self.activityCfg.p4[i][1])
    if i < level then
      content = UIHelper.SetColor(content, "ffffff")
    end
    UIHelper.SetText(widgets[txtGrades[i]], content)
  end
  local percent = maxDamage / sssDamage
  widgets.slider.value = percent
  UIHelper.SetLocText(widgets.txt_damage, 1300013, maxDamage)
  self:UpdateBoxes()
  self:UpdateStars()
  if Logic.redDotLogic.EquipTest(self.activityCfg.id) then
    self:WriteOpenedFlag()
  end
end

function EquipTestPage:WriteOpenedFlag()
  local startTime = PeriodManager:GetPeriodTime(self.activityCfg.period, self.activityCfg.period_area)
  local userId = Data.userData:GetUserUid()
  PlayerPrefs.SetString(string.format("eqptst%s%s", userId, startTime), "eqptst")
end

function EquipTestPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_help, self.OnBtnHelp, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_copy, self.OnBtnCopy, self)
  self:RegisterEvent(LuaEvent.EquipTestReceiveRewards, self.OnReceive, self)
end

function EquipTestPage:UpdateStars()
  local widgets = self:GetWidgets()
  local maxDamage = Data.equipTestCopyData:GetMaxDamage()
  local level = Logic.equipTestCopyLogic:GetLevelByDamage(self.activityCfg, maxDamage)
  UIHelper.CreateSubPart(widgets.obj_star, widgets.trans_star, level, function(nIndex, tabPart)
  end)
end

function EquipTestPage:UpdateBoxes()
  local widgets = self:GetWidgets()
  local boxCfg = configManager.GetDataById("config_starbox", 5)
  local rewardData = self.activityCfg.p4
  local receiveData = Data.equipTestCopyData:GetReceivedRewards()
  local curMaxDamage = Data.equipTestCopyData:GetMaxDamage()
  local recvMap = {}
  for j, recv in ipairs(receiveData) do
    recvMap[recv.RewardId] = true
  end
  for i, data in ipairs(rewardData) do
    local tabPart = widgets["box_" .. sgrades[i]]:GetLuaTableParts()
    if curMaxDamage >= data[1] then
      if recvMap[data[2]] then
        UIHelper.SetImage(tabPart.icon, boxCfg.recieved_icon)
        tabPart.Effect:SetActive(false)
      else
        UIHelper.SetImage(tabPart.icon, boxCfg.open_icon)
        tabPart.Effect:SetActive(true)
      end
    else
      UIHelper.SetImage(tabPart.icon, boxCfg.unopen_icon)
      tabPart.Effect:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn, self.OnBtnBox, self, i)
  end
end

function EquipTestPage:OnBtnHelp()
  UIHelper.OpenPage("HelpPage", {
    content = self.activityCfg.p9[1]
  })
end

function EquipTestPage:OnReceive(rewardInfo)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewardInfo.Rewards,
    Page = "EquipTestPage",
    DontMerge = true
  })
  self:UpdateBoxes()
  self:UpdateStars()
end

function EquipTestPage:OnBtnBox(obj, index)
  local rewardData = self.activityCfg.p4[index]
  local rewardCfg = configManager.GetDataById("config_rewards", rewardData[2])
  local rewards = Logic.rewardLogic:FormatReward(rewardCfg.rewards)
  local state = RewardState.UnReceivable
  local receiveData = Data.equipTestCopyData:GetReceivedRewards()
  local curMaxDamage = Data.equipTestCopyData:GetMaxDamage()
  local recvMap = {}
  for j, recv in ipairs(receiveData) do
    recvMap[recv.RewardId] = true
  end
  if curMaxDamage >= rewardData[1] then
    if recvMap[rewardData[2]] then
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.Received,
        rewards = rewards
      })
    else
      local maxDamage = Data.equipTestCopyData:GetMaxDamage()
      if maxDamage >= rewardData[1] then
        Service.equipTestCopyService:ReceiveRewards(rewardData[2])
      end
    end
  else
    UIHelper.OpenPage("BoxRewardPage", {
      rewardState = RewardState.UnReceivable,
      rewards = rewards
    })
  end
end

function EquipTestPage:OnBtnCopy()
  local copyIds = self.activityCfg.p1
  local maxDamage = Data.equipTestCopyData:GetMaxDamage()
  local level = Logic.equipTestCopyLogic:GetLevelByDamage(self.activityCfg, maxDamage)
  if level > #copyIds then
    level = #copyIds
  end
  local copyId = copyIds[level]
  local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    copyId = copyId,
    tabSerData = copyData,
    chapterId = chapterId,
    IsRunningFight = false
  }
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

return EquipTestPage
