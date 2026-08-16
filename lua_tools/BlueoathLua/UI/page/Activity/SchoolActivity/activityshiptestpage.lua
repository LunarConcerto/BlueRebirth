local ActivityShipTestPage = class("ui.page.Activity.SchoolActivity.ActivityShipTestPage", LuaUIPage)

function ActivityShipTestPage:DoInit()
  self.mTabIndex = 1
end

function ActivityShipTestPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
  self:RefreshData()
end

function ActivityShipTestPage:RefreshData()
  Service.shiptaskService:GetAllInfo()
end

function ActivityShipTestPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ShipTask_RefreshData, self.ShowPage, self)
end

function ActivityShipTestPage:DoOnHide()
end

function ActivityShipTestPage:DoOnClose()
end

function ActivityShipTestPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local heroTid = Data.shiptaskData:GetCurrentHeroTemplateId()
  if 0 < heroTid then
    self.tab_Widgets.objShip:SetActive(true)
    self.tab_Widgets.objDefault:SetActive(false)
    local shipInfo = Logic.shipLogic:GetShipInfoIdByTid(heroTid)
    shipInfo = Logic.shipLogic:GetShipInfoBySiId(shipInfo)
    local shipshow = Logic.shipLogic:GetShipShowById(heroTid)
    if shipInfo then
      UIHelper.SetText(self.tab_Widgets.textShipName, shipInfo.ship_name)
    end
    if shipshow then
      UIHelper.SetImage(self.tab_Widgets.imgGirl, shipshow.ship_draw)
      UIHelper.SetImage(self.tab_Widgets.imgBlack, shipshow.ship_draw_black)
      Logic.activityLogic:SetGirlImgPosition(self.tab_Widgets.imgShip, shipshow)
    end
  else
    self.tab_Widgets.objShip:SetActive(false)
    self.tab_Widgets.objDefault:SetActive(true)
  end
  if self.mTimer ~= nil then
    self.mTimer:Stop()
    self.mTimer = nil
  end
  local setShipTime = Data.shiptaskData:GetSetShipTime()
  local isInCd = false
  if 0 < setShipTime then
    local parameterCfg = configManager.GetDataById("config_parameter", 331)
    local now = time.getSvrTime()
    local endTime = setShipTime + parameterCfg.value
    if now < endTime then
      isInCd = true
      do
        local callFunc = function()
          local svrTime = time.getSvrTime()
          local surplusTime = endTime - svrTime
          if surplusTime <= 0 then
            self.mTimer:Stop()
            self.mTimer = nil
            self:ShowPage()
          else
            UIHelper.SetText(self.tab_Widgets.textCdTime, UIHelper.GetCountDownStr(surplusTime))
          end
        end
        self.mTimer = self:CreateTimer(callFunc, 1, -1)
        self.mTimer:Start()
        callFunc()
      end
    end
  end
  if isInCd then
    self.tab_Widgets.objCdInfo:SetActive(true)
    self.tab_Widgets.objChangeInfo:SetActive(false)
  else
    self.tab_Widgets.objCdInfo:SetActive(false)
    self.tab_Widgets.objChangeInfo:SetActive(true)
  end
  local funcSetShip = function()
    if isInCd then
      noticeManager:ShowTipById(7400004)
      return
    end
    local displayInfo = Logic.shipLogic:GetRidHeroTid(heroTid)
    UIHelper.OpenPage("CommonSelectPage", {
      CommonHeroItem.ShipTask,
      displayInfo,
      {m_selectMax = 1}
    })
  end
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAddShip, funcSetShip)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnChange, funcSetShip)
  self.mTabInfoList = Logic.shiptaskLogic:GetTabInfoList()
  self.tab_Widgets.tgGroupTab:ClearToggles()
  UIHelper.CreateSubPart(self.tab_Widgets.objSelect, self.tab_Widgets.rectSelect, #self.mTabInfoList, function(index, part)
    local tabData = self.mTabInfoList[index]
    UIHelper.SetText(part.textType, tabData.TaskTypeName)
    UIHelper.SetText(part.textTypeUncheck, tabData.TaskTypeName)
    local taskType = tabData.TaskType
    if 0 < taskType then
      UIHelper.SetLocText(part.textNum, 7400003, tabData.TestPoint .. "/" .. tabData.TestPointSum)
      UIHelper.SetLocText(part.textNumUncheck, 7400003, tabData.TestPoint .. "/" .. tabData.TestPointSum)
    else
      UIHelper.SetText(part.textNum, "")
      UIHelper.SetText(part.textNumUncheck, "")
    end
    self:RegisterRedDotById(part.reddot, {101}, taskType)
    self.tab_Widgets.tgGroupTab:RegisterToggle(part.tgSelect)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupTab, self, "", function(go, index)
    self.mTabIndex = index + 1
    self:ShowShipTaskPartial()
  end)
  self.tab_Widgets.tgGroupTab:SetActiveToggleIndex(self.mTabIndex - 1)
end

function ActivityShipTestPage:updateItemTaskPart(index, part)
  local taskData = self.mTaskInfoList[index]
  local cfg = taskData.Config
  UIHelper.SetText(part.textDesc, cfg.test_name)
  UIHelper.SetText(part.textProcess, taskData.ProcessStr)
  UIHelper.SetText(part.textRewardNum, cfg.test_point)
  part.btnGoto.gameObject:SetActive(false)
  part.btnReward.gameObject:SetActive(false)
  part.objGet:SetActive(false)
  if taskData.Status == ShipTaskStatus.Accept then
    if cfg.go_up_to > 0 then
      part.btnGoto.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
        if not Data.activityData:IsActivityOpen(self.mActivityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        moduleManager:JumpToFunc(cfg.go_up_to, table.unpack(cfg.go_up_to_parm))
      end)
    end
  elseif taskData.Status == ShipTaskStatus.Finish then
    part.btnReward.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnReward, function()
      if not Data.activityData:IsActivityOpen(self.mActivityId) then
        noticeManager:ShowTipById(270022)
        return
      end
      local shipTid = Data.shiptaskData:GetCurrentShipTid()
      Service.shiptaskService:SendGetShipTaskReward({
        ShipTid = shipTid,
        TaskId = taskData.TaskId
      })
    end)
  elseif taskData.Status == ShipTaskStatus.Reward then
    part.objGet:SetActive(true)
  else
    logError("err Status", taskData.Status)
  end
end

function ActivityShipTestPage:updateItemAchiPart(index, part)
  local achiData = self.mAchiInfoList[index]
  local achId = achiData.AchId
  local cfg = achiData.Config
  local col1 = achiData.IsCond1 and "66991d" or "d5302e"
  UIHelper.SetTextColor(part.textDescCond1, achiData.CurMinPoint .. "/" .. cfg.task_point, col1)
  local col2 = achiData.IsCond2 and "66991d" or "d5302e"
  UIHelper.SetTextColor(part.textDescCond2, achiData.CurSumPoint .. "/" .. cfg.task_point_total, col2)
  local isCanGetReward = achiData.IsCanGetReward
  part.objEffect:SetActive(isCanGetReward)
  UGUIEventListener.AddButtonOnClick(part.btnBox, function()
    if not isCanGetReward then
      local rewards = Logic.rewardLogic:FormatRewards({
        cfg.reward
      })
      UIHelper.OpenPage("BoxRewardPage", {
        rewardState = RewardState.UnReceivable,
        rewards = rewards
      })
      return
    end
    local shipTid = Data.shiptaskData:GetCurrentShipTid()
    Service.shiptaskService:SendGetAchievementReward({ShipTid = shipTid, STAid = achId})
  end)
  local boxCfg = configManager.GetDataById("config_starbox", 7)
  local isGet = Data.shiptaskData:GetAchiIsGet(achId)
  if isGet then
    UIHelper.SetImage(part.imgBoxIcon, boxCfg.recieved_icon)
  elseif isCanGetReward then
    UIHelper.SetImage(part.imgBoxIcon, boxCfg.open_icon)
  else
    UIHelper.SetImage(part.imgBoxIcon, boxCfg.unopen_icon)
  end
end

function ActivityShipTestPage:ShowShipTaskPartial()
  local tabData = self.mTabInfoList[self.mTabIndex]
  if tabData.TaskType > 0 then
    self.tab_Widgets.objAchi:SetActive(false)
    self.tab_Widgets.objTask:SetActive(true)
    local taskType = tabData.TaskType
    self.mTaskInfoList = Logic.shiptaskLogic:GetTaskInfoList(taskType)
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTask, self.tab_Widgets.itemTask, #self.mTaskInfoList, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        self:updateItemTaskPart(index, part)
      end
    end)
  else
    self.tab_Widgets.objAchi:SetActive(true)
    self.tab_Widgets.objTask:SetActive(false)
    self.mAchiInfoList = Logic.shiptaskLogic:GetAchiInfoList()
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentAchi, self.tab_Widgets.itemAchi, #self.mAchiInfoList, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        self:updateItemAchiPart(index, part)
      end
    end)
  end
end

return ActivityShipTestPage
