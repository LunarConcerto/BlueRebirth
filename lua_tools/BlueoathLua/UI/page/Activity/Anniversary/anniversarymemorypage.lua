local AnniversaryMemoryPage = class("ui.page.Activity.Anniversary.AnniversaryMemoryPage", LuaUIPage)
local MemoryTotalNum = 7
local NewMemoryNum = 6

function AnniversaryMemoryPage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.tabParts = {}
  self.memoryData = nil
end

function AnniversaryMemoryPage:DoOnOpen()
  Service.activityService:SendGetStateCount()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:_ShowActivityTime()
  self:_ShowTask()
end

function AnniversaryMemoryPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._CloseMemory, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_memory, self._OpenMemory, self)
  UGUIEventListener.AddOnEndDrag(self.tab_Widgets.scroll_drag, self._DragItem, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.GetStatCountRet, self._CreateReport, self)
  self:RegisterEvent(LuaEvent.TaskTriggerRet, self._ShowTask, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._OnShareOver, self)
  self:RegisterEvent(LuaEvent.ShareStart, self._OnShareStart, self)
end

function AnniversaryMemoryPage:_ShowActivityTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_actTime, startTime .. " - " .. endTime)
end

function AnniversaryMemoryPage:_ShowTask()
  local arrTask = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  self.taskInfo = arrTask[1]
  local taskId = self.actConfig.p1[1]
  local taskData = self.taskInfo.Data
  self.taskInfo.eventType = taskData.EventType
  local reward = Logic.rewardLogic:FormatRewardById(self.taskInfo.Config.rewards)
  local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1].Type, reward[1].ConfigId)
  UIHelper.SetImage(self.tab_Widgets.im_rewardBg, QualityIcon[rewardInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.im_reward, tostring(rewardInfo.icon))
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self._ClickItem, self, reward[1])
  local imgGet = self.taskInfo.State == TaskState.FINISH and "uipic_ui_anniversarymemory_bu_kelingqu" or "uipic_ui_anniversarymemory_bu_bukelingqu"
  UIHelper.SetImage(self.tab_Widgets.img_get, imgGet)
  if self.taskInfo.State ~= TaskState.RECEIVED then
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self._GetReward, self)
  end
end

function AnniversaryMemoryPage:_CreateReport(ret)
  self.memoryData = ret
  local pageNum = ret.CreateDays == 0 and NewMemoryNum or MemoryTotalNum
  self.tab_Widgets.scroll_fix.Total = pageNum
  self.tab_Widgets.scroll_fix.DragThreshold = 1 / pageNum
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_pages, pageNum, function(index, tabPart)
    for i = 1, MemoryTotalNum do
      tabPart["page" .. tostring(i)]:SetActive(false)
    end
    table.insert(self.tabParts, tabPart)
    tabPart["page" .. tostring(index)]:SetActive(true)
    tabPart["timeLimit" .. tostring(index)]:SetActive(ret.CreateDays == 0)
    tabPart["obj_details" .. tostring(index)]:SetActive(ret.CreateDays ~= 0)
    if ret.CreateDays == 0 and index == NewMemoryNum then
      tabPart.btn_share6.gameObject:SetActive(platformManager:ShowShare())
      UGUIEventListener.AddButtonOnClick(tabPart.btn_share6, self._ClickShare, self)
    end
    if ret.CreateDays ~= 0 then
      self:_SetMemoryDetails(ret, index, tabPart)
    end
  end)
end

function AnniversaryMemoryPage:_SetMemoryDetails(ret, index, tabPart)
  if index == 1 then
    local tabUserInfo = Data.userData:GetUserData()
    local createTime = time.formatTimeToYMD(tabUserInfo.CreateTime)
    UIHelper.SetText(tabPart.txt_createTime, createTime)
  elseif index == 2 then
    UIHelper.SetText(tabPart.txt_work, ret.CreateDays)
  elseif index == 3 then
    tabPart.none3:SetActive(ret.Build == 0 and ret.Steel == 0 and ret.Alum == 0 and ret.Illustrate == 0 and ret.Supply == 0 and ret.Gold == 0 and ret.Bath == 0)
    UIHelper.SetText(tabPart.txt_buildNum, ret.Build)
    UIHelper.SetText(tabPart.txt_stell, ret.Steel)
    UIHelper.SetText(tabPart.txt_aluminum, ret.Alum)
    UIHelper.SetText(tabPart.txt_allShip, ret.Illustrate)
    UIHelper.SetText(tabPart.txt_supple, ret.Supply)
    UIHelper.SetText(tabPart.txt_goods, ret.Gold)
    UIHelper.SetText(tabPart.txt_bath, ret.Bath)
    local supplyMean = self.actConfig.p2[1][1]
    local desc = supplyMean <= ret.Supply and UIHelper.GetString(390002) or UIHelper.GetString(390001)
    UIHelper.SetText(tabPart.txt_desc, desc)
  elseif index == 4 then
    tabPart.none4:SetActive(ret.Copy == 0)
    tabPart.obj_battle:SetActive(ret.Copy ~= 0)
    UIHelper.SetText(tabPart.txt_battle, ret.Copy)
  elseif index == 5 then
    tabPart.none5:SetActive(ret.BathTimeHero == 0)
    tabPart.obj_girlBath:SetActive(ret.BathTimeHero ~= 0)
    if ret.BathTimeHero ~= 0 then
      local hero = Logic.shipLogic:GetDefaultShipShowById(ret.BathTimeHero)
      UIHelper.SetText(tabPart.txt_bathGirl, hero.ship_name)
      UIHelper.SetText(tabPart.txt_bathGirl2, hero.ship_name)
      local time = math.ceil(ret.BathMaxTime / 3600)
      UIHelper.SetText(tabPart.txt_bathTime, time)
      UIHelper.SetImage(tabPart.im_girlBath, hero.ship_draw)
      UIHelper.SetText(tabPart.tx_bathName, hero.ship_name)
    end
  elseif index == 6 then
    tabPart.none6:SetActive(ret.FirstMarry == 0)
    tabPart.obj_girlMarry:SetActive(ret.FirstMarry ~= 0)
    if ret.FirstMarry ~= 0 then
      local hero = Logic.shipLogic:GetDefaultShipShowById(ret.FirstMarry)
      UIHelper.SetText(tabPart.txt_marry6, hero.ship_name)
      UIHelper.SetImage(tabPart.im_girlMarry, hero.ship_draw)
      local createTime = time.formatTimeToYMD(ret.FirstMarryTime)
      UIHelper.SetText(tabPart.txt_marryTime, createTime)
      local marryNum = ret.Marry - 1
      UIHelper.SetText(tabPart.txt_marryNum, marryNum)
      UIHelper.SetText(tabPart.tx_marryName, hero.ship_name)
    end
  elseif index == 7 then
    local supplyTab = self.actConfig.p2
    local goldTab = self.actConfig.p3
    local supplyPercent = self:_GetDataPercent(ret.Supply, supplyTab)
    local showExpend = 0 < supplyPercent
    local goldPercent = self:_GetDataPercent(ret.Gold, goldTab)
    local expendPercent = supplyPercent > goldPercent and supplyPercent or goldPercent
    UIHelper.SetText(tabPart.txt_expend, expendPercent .. "%")
    local battleTab = self.actConfig.p5
    local battlePercent = self:_GetDataPercent(ret.Copy, battleTab)
    local showBattle = 0 < battlePercent
    UIHelper.SetText(tabPart.txt_battle7, battlePercent .. "%")
    local marryTab = self.actConfig.p6
    local marryPercent = self:_GetDataPercent(ret.Marry, marryTab)
    local showMarry = 0 < marryPercent
    UIHelper.SetText(tabPart.txt_marry, ret.Marry)
    if not showExpend and not showBattle and not showMarry then
      tabPart.none7:SetActive(true)
    else
      local tab = {
        {
          id = 1,
          percent = supplyPercent,
          obj = tabPart.obj_expend
        },
        {
          id = 2,
          percent = battlePercent,
          obj = tabPart.obj_battle7
        },
        {
          id = 3,
          percent = marryPercent,
          obj = tabPart.obj_marry
        }
      }
      table.sort(tab, function(data1, data2)
        if data1.percent ~= data2.percent then
          return data1.percent > data2.percent
        else
          return data1.id < data2.id
        end
      end)
      for i, v in ipairs(tab) do
        v.obj:SetActive(0 < v.percent and i == 1)
      end
    end
    tabPart.btn_share.gameObject:SetActive(platformManager:ShowShare())
    UGUIEventListener.AddButtonOnClick(tabPart.btn_share, self._ClickShare, self)
  end
end

function AnniversaryMemoryPage:_GetDataPercent(value, dataTab)
  local percent = 0
  for _, v in ipairs(dataTab) do
    if value >= v[1] and value <= v[2] then
      percent = v[3]
      break
    end
  end
  return percent
end

function AnniversaryMemoryPage:_OpenMemory()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  self.tab_Widgets.obj_memory:SetActive(true)
end

function AnniversaryMemoryPage:_CloseMemory()
  local timer = self:CreateTimer(function()
    self.tab_Widgets.scroll_fix.CurPage = 1
  end, 0.1, 1, false)
  self:StartTimer(timer)
  self.tab_Widgets.obj_memory:SetActive(false)
end

function AnniversaryMemoryPage:_DragItem()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    return
  end
  local pageIndex = self.tab_Widgets.scroll_fix.CurPage
  if self.memoryData.CreateDays ~= 0 then
    if pageIndex == 3 then
      for i = 1, 4 do
        self:_PlayTween(self.tabParts[pageIndex]["tween_summary" .. tostring(i)])
      end
    elseif pageIndex == 4 and self.memoryData.Copy ~= 0 then
      for i = 1, 1 do
        self:_PlayTween(self.tabParts[pageIndex]["tween_battle" .. tostring(i)])
      end
    elseif pageIndex == 5 and self.memoryData.BathTimeHero ~= 0 then
      for i = 1, 3 do
        self:_PlayTween(self.tabParts[pageIndex]["tween_bath" .. tostring(i)])
      end
    elseif pageIndex == 6 and self.memoryData.FirstMarry ~= 0 then
      for i = 1, 3 do
        self:_PlayTween(self.tabParts[pageIndex]["tween_marry" .. tostring(i)])
      end
    end
  end
  if self.memoryData.CreateDays ~= 0 and pageIndex == MemoryTotalNum and self.taskInfo.State == TaskState.TODO then
    Service.taskService:SendTaskTrigger(self.taskInfo.eventType)
  elseif self.memoryData.CreateDays == 0 and pageIndex == NewMemoryNum and self.taskInfo.State == TaskState.TODO then
    Service.taskService:SendTaskTrigger(self.taskInfo.eventType)
  end
end

function AnniversaryMemoryPage:_PlayTween(objTween)
  objTween:ResetToInit()
  objTween:Play(true)
end

function AnniversaryMemoryPage:_GetReward()
  if self.actConfig.period > 0 and not PeriodManager:IsInPeriodArea(self.actConfig.period, self.actConfig.period_area) then
    noticeManager:ShowTipById(270022)
    return
  end
  if self.taskInfo.State == TaskState.TODO then
    noticeManager:ShowTipById(390003)
  elseif self.taskInfo.State == TaskState.FINISH then
    Service.taskService:SendTaskReward(self.taskInfo.TaskId, TaskType.Activity)
  end
end

function AnniversaryMemoryPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "AnniversaryMemoryPage")
  self:_ShowTask()
end

function AnniversaryMemoryPage:_ClickItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function AnniversaryMemoryPage:_ClickShare()
  shareManager:Share(self:GetName(), nil, nil)
end

function AnniversaryMemoryPage:_OnShareStart()
  if self.memoryData.CreateDays == 0 then
    self.tabParts[NewMemoryNum].btn_share6.gameObject:SetActive(false)
  else
    self.tabParts[MemoryTotalNum].btn_share.gameObject:SetActive(false)
  end
  self.tab_Widgets.btn_back:SetActive(false)
end

function AnniversaryMemoryPage:_OnShareOver()
  if self.memoryData.CreateDays == 0 then
    self.tabParts[NewMemoryNum].btn_share6.gameObject:SetActive(platformManager:ShowShare())
  else
    self.tabParts[MemoryTotalNum].btn_share.gameObject:SetActive(platformManager:ShowShare())
  end
  self.tab_Widgets.btn_back:SetActive(true)
end

function AnniversaryMemoryPage:DoOnHide()
end

function AnniversaryMemoryPage:DoOnClose()
end

return AnniversaryMemoryPage
