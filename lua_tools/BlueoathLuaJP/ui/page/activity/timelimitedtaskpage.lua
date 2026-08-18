local TimelimitedTaskPage = class("UI.Activity.TimelimitedTaskPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")

function TimelimitedTaskPage:DoInit()
  self.userInfo = {}
  self.activityData = {}
  self.curClickDayNum = 1
  self.canOpenMaxDay = 1
end

function TimelimitedTaskPage:GetCurentDay()
  local day = 1
  local activityInfo = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(activityInfo.period)
  local now = time.getSvrTime()
  local periodconfig = configManager.GetDataById("config_period", activityInfo.period)
  local startY = periodconfig.p1
  local startM = periodconfig.p2
  local startD = periodconfig.p3
  local curD = time.formatTimerToD(now)
  if startTime > now or endTime < now then
    day = 1
  else
    day = curD - startD + 1
    local tabContentInfo = configManager.GetData("config_days_activity_limited")
    if day > #tabContentInfo then
      day = #tabContentInfo
    end
  end
  self.canOpenMaxDay = day
  return day
end

function TimelimitedTaskPage:CheckIsOpen()
  local now = time.getSvrTime()
  local activityInfo = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(activityInfo.period)
  if now > endTime then
    return false
  end
  return true
end

function TimelimitedTaskPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self.userInfo = Data.userData:GetUserData()
  self:GetCurentDay()
  self.activityData = Data.taskData:GetTaskDataByType(TaskType.Activity)
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  self:_LoadDayNum()
  self.curClickDayNum = self.canOpenMaxDay
  local index
  local toggleIndex = Logic.achieveLogic:GetTimeTaskToggle()
  if toggleIndex == nil then
    index = self.canOpenMaxDay
  else
    index = toggleIndex
  end
  Logic.achieveLogic:SetTimeTaskDay(index)
  self:_ShowDayInfo(self, tabContentInfo[index])
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[index].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[index].description)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  self.userData = Data.userData:GetUserData()
  Logic.activityLogic:SetDaysActivity(false)
  eventManager:SendEvent(LuaEvent.SelfReddotCallBack)
end

function TimelimitedTaskPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_loginGet, self._ClickLoginGet, self)
  self:RegisterEvent(LuaEvent.GetTimeTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._OnUpdataTaskList, self)
end

function TimelimitedTaskPage:_OnUpdataTaskList(args)
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  local selectTog = Logic.achieveLogic:GetTimeTaskDay()
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function TimelimitedTaskPage:_OnGetReward(args)
  for v, k in pairs(args) do
    Logic.rewardLogic:ShowCommonReward(k, "TimelimitedTaskPage", nil)
  end
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  local selectTog = Logic.achieveLogic:GetTimeTaskDay()
  self.activityData = Data.taskData:GetTaskDataByType(TaskType.Activity)
  stage = self:GetCurentDay()
  if self.canOpenMaxDay ~= stage and stage <= #tabContentInfo then
    self.canOpenMaxDay = stage
    selectTog = stage
    self:_LoadDayNum()
  end
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function TimelimitedTaskPage:_LoadDayNum()
  self.tabPartInfo = {}
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dayItem, self.tab_Widgets.trans_dayItem, #tabContentInfo, function(index, tabPart)
    self:RegisterRedDot(tabPart.red_Dot, tabContentInfo[index].id)
    table.insert(self.tabPartInfo, tabPart)
    local str = tabContentInfo[index].name
    tabPart.tx_dayNum.text = str
    tabPart.tx_selected_dayNum.text = str
    UIHelper.SetImage(tabPart.im_numIcon, tabContentInfo[index].icon)
    if index <= self.canOpenMaxDay then
      tabPart.im_over:SetActive(false)
    else
      tabPart.im_over:SetActive(true)
    end
    tabPart.tx_num.gameObject:SetActive(tabContentInfo[index].count ~= 0)
    UIHelper.SetImage(tabPart.im_quality, tabContentInfo[index].bg)
    UIHelper.SetText(tabPart.tx_num, tabContentInfo[index].count)
    if index <= self.canOpenMaxDay then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        self:_ShowDayInfo(self, tabContentInfo[index])
      end)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        noticeManager:OpenTipPage(self, UIHelper.GetString(800004))
      end)
    end
  end)
end

function TimelimitedTaskPage:_ShowDayInfo(go, award)
  self:StopTimer(self.timer)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  Logic.achieveLogic:SetTimeTaskToggle(award.id)
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  for v, k in pairs(self.tabPartInfo) do
    if v == award.id then
      k.tx_selected_dayNum.gameObject:SetActive(true)
      k.tx_dayNum.gameObject:SetActive(false)
      k.tx_outLine.effectColor = Color.New(tabContentInfo[v].outlinecolor[1] / 255, tabContentInfo[v].outlinecolor[2] / 255, tabContentInfo[v].outlinecolor[3] / 255, tabContentInfo[v].outlinecolor[4] / 255)
      k.im_selete.gameObject:SetActive(true)
      k.obj_canvas.overrideSorting = true
      UIHelper.SetImage(k.im_selete, tabContentInfo[v].selected)
    else
      k.tx_selected_dayNum.gameObject:SetActive(false)
      k.tx_dayNum.gameObject:SetActive(true)
      k.obj_canvas.overrideSorting = false
      k.tx_outLine.effectColor = Color.New(0, 0, 0, 0)
      k.im_selete.gameObject:SetActive(false)
    end
  end
  self.curClickDayNum = award.id
  local loginInfo = configManager.GetDataById("config_task_activity", award.task_stage)
  local tabContentInfo = configManager.GetData("config_days_activity_limited")
  Logic.achieveLogic:SetTimeTaskDay(self.curClickDayNum)
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[self.curClickDayNum].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[self.curClickDayNum].description)
  self:_LoadLoginReward(loginInfo.rewards)
  self:_LoadItemInfo(award)
end

function TimelimitedTaskPage:_refreshGoods()
  for gridId, tabPart in pairs(self.goods) do
    local goodData = Logic.shopLogic:GetGoodDataById(ShopId.Days, gridId)
    tabPart.btn_get.gameObject:SetActive(self.canOpenMaxDay >= self.curClickDayNum and goodData.Num == 0)
    tabPart.btn_fetched.gameObject:SetActive(goodData.Num > 0)
  end
end

function TimelimitedTaskPage:_LoadGoods(shopId, goods)
  self.goods = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_gift, self.tab_Widgets.trans_gift, #goods, function(index, tabPart)
    local gridId = goods[index]
    self.goods[gridId] = tabPart
    local goodData = Logic.shopLogic:GetGoodDataById(shopId, gridId)
    local goodId = goodData.GoodsId
    local goodConfig = configManager.GetDataById("config_shop_goods", goodId)
    local goodsInfo = Logic.bagLogic:GetItemByTempateId(goodConfig.goods[1], goodConfig.goods[2])
    UIHelper.SetImage(tabPart.im_loginIcon, goodsInfo.icon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[goodsInfo.quality])
    local curIcon = Logic.currencyLogic:GetSmallIcon(goodConfig.currency[1][2])
    UIHelper.SetImage(tabPart.img_cur_origin, curIcon)
    UIHelper.SetImage(tabPart.img_cur_now, curIcon)
    UIHelper.SetText(tabPart.tx_rewardNum, "x" .. goodConfig.goods[3])
    local origin = goodConfig.price[1][1] / (goodConfig.discount[1] / 100)
    UIHelper.SetText(tabPart.tx_price_origin, origin)
    UIHelper.SetText(tabPart.tx_price_now, goodConfig.price[1][1])
    UGUIEventListener.AddButtonOnClick(tabPart.im_loginIcon, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(goodConfig.goods[1], goodConfig.goods[2]))
    end)
    tabPart.btn_get.gameObject:SetActive(self.canOpenMaxDay >= self.curClickDayNum and goodData.Num == 0)
    tabPart.btn_fetched.gameObject:SetActive(goodData.Num > 0)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, function()
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            local info = {
              goodData = goodConfig,
              shopId = ShopId.Days,
              buyNum = 1,
              goodId = goodId,
              purchaseNum = goodData.Num
            }
            Logic.shopLogic:BuyGoods(info)
          end
        end
      }
      local tips = string.format(UIHelper.GetString(800001), goodConfig.name)
      noticeManager:ShowMsgBox(tips, tabParams)
    end)
  end)
end

function TimelimitedTaskPage:_LoadLoginReward(rewardId)
  local loginInfo = configManager.GetDataById("config_rewards", rewardId).rewards
  self.loginReward = {}
  self.loginReward = loginInfo
  UIHelper.CreateSubPart(self.tab_Widgets.obj_loginItem, self.tab_Widgets.trans_loginItem, #loginInfo, function(index, tabPart)
    local reward = {
      Type = loginInfo[index][1],
      Num = loginInfo[index][3],
      ConfigId = loginInfo[index][2]
    }
    local tabReward = Logic.goodsLogic.AnalyGoods(reward)
    UIHelper.SetImage(tabPart.im_loginIcon, tabReward.texIcon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(tabPart.tx_rewardNum, "x" .. loginInfo[index][3])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_look, self._ShowItemInfo, self, loginInfo[index])
  end)
  local args = configManager.GetDataById("config_days_activity_limited", self.curClickDayNum)
  local logintabReward = {}
  table.insert(logintabReward, args.task_stage)
  local tabAchieve = Logic.achieveLogic:GetTimeTaskByDays(logintabReward, self.activityData)
  if tabAchieve[1].status == TaskState.RECEIVED then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330006)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  elseif tabAchieve[1].status == TaskState.TODO then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  else
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    if self.canOpenMaxDay >= self.curClickDayNum then
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_ryzadaysactivity_bu_01")
    else
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
    end
  end
end

function TimelimitedTaskPage:_ShowItemInfo(go, award)
  if award[1] == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award[2],
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award[1], award[2]))
  end
end

function TimelimitedTaskPage:_LoadItemInfo(award)
  local tabAchieve = Logic.achieveLogic:GetTimeTaskByDays(award.task_activity, self.activityData)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemInfo, self.tab_Widgets.trans_itemInfo, #tabAchieve, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_des, tabAchieve[index].config.desc)
    UIHelper.SetText(tabPart.tx_num, tabAchieve[index].progressStr)
    if tabAchieve[index].status == TaskState.TODO then
      local isJump = tabAchieve[index].config.go_up_to ~= -1
      tabPart.btn_anniu.gameObject:SetActive(isJump)
      tabPart.tx_num.gameObject:SetActive(isJump)
    else
      tabPart.btn_anniu.gameObject:SetActive(true)
      tabPart.tx_num.gameObject:SetActive(true)
    end
    if tabAchieve[index].status == TaskState.RECEIVED then
      tabPart.im_anniu.gameObject:SetActive(false)
    end
    tabPart.tx_num.gameObject:SetActive(tabAchieve[index].progress <= 1)
    tabPart.im_get.gameObject:SetActive(tabAchieve[index].status == TaskState.RECEIVED)
    if tabAchieve[index].status == TaskState.TODO then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(800005))
      UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_hui")
    elseif tabAchieve[index].status == TaskState.FINISH then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330007))
      if self.curClickDayNum <= self.canOpenMaxDay then
        UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_ryzadaysactivity_bu_01")
      else
        UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_hui")
      end
    elseif tabAchieve[index].status == TaskState.RECEIVED then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330006))
      tabPart.tx_num.gameObject:SetActive(false)
    end
    local reward = configManager.GetDataById("config_rewards", tabAchieve[index].config.rewards).rewards
    UIHelper.CreateSubPart(tabPart.obj_item, tabPart.trans_rewards, #reward, function(i, t)
      local tabReward = Logic.bagLogic:GetItemByTempateId(reward[i][1], reward[i][2])
      UIHelper.SetImage(t.im_icon, tabReward.icon)
      UIHelper.SetImage(t.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(t.tx_rewardNum, "x" .. reward[i][3])
      UGUIEventListener.AddButtonOnClick(t.btn_icon, self._ShowItemInfo, self, reward[i])
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_anniu, self._NewPlayerCall, self, tabAchieve[index])
  end)
end

function TimelimitedTaskPage:_NewPlayerCall(go, args)
  if not self:CheckIsOpen() then
    noticeManager:OpenTipPage(self, UIHelper.GetString(270022))
    return
  end
  if args.status == TaskState.TODO then
    local isJump = TaskOperate.JumpValidModule(args.config.go_up_to)
  elseif args.status == TaskState.FINISH then
    local name = configManager.GetDataById("config_days_activity_limited", self.curClickDayNum).name
    if self.curClickDayNum <= self.canOpenMaxDay then
      local dotinfo = {
        info = "ui_activity_task",
        achievement_id = args.achieveId
      }
      RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      local reward = {
        TaskId = args.achieveId,
        TaskType = TaskType.Activity,
        Day = self.curClickDayNum
      }
      Service.taskService:SendTaskSevenDayRewardDay(reward)
    else
      noticeManager:OpenTipPage(self, name .. UIHelper.GetString(920000092))
    end
  end
end

function TimelimitedTaskPage:_ClickLoginGet()
  if not self:CheckIsOpen() then
    noticeManager:OpenTipPage(self, UIHelper.GetString(270022))
    return
  end
  local args = configManager.GetDataById("config_days_activity_limited", self.curClickDayNum)
  local m_type = configManager.GetDataById("config_task_activity", args.task_stage)
  local tabReward = {}
  table.insert(tabReward, args.task_stage)
  local tabAchieve = Logic.achieveLogic:GetTimeTaskByDays(tabReward, self.activityData)
  if self.curClickDayNum <= self.canOpenMaxDay and tabAchieve[1].status == TaskState.FINISH then
    local reward = {
      TaskId = args.task_stage,
      TaskType = TaskType.Activity,
      Day = self.curClickDayNum
    }
    Service.taskService:SendTaskSevenDayRewardDay(reward)
    local dotinfo = {
      info = "ui_activity_login",
      day_id = self.curClickDayNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  elseif tabAchieve[1].status == TaskState.RECEIVED then
    noticeManager:OpenTipPage(self, UIHelper.GetString(330006))
  else
    local name = configManager.GetDataById("config_days_activity_limited", self.curClickDayNum).name
    local str = string.format(UIHelper.GetString(800006), name)
    noticeManager:OpenTipPage(self, str)
  end
end

function TimelimitedTaskPage:DoOnHide()
end

function TimelimitedTaskPage:DoOnClose()
  Logic.achieveLogic:SetTimeTaskToggle(nil)
end

return TimelimitedTaskPage
