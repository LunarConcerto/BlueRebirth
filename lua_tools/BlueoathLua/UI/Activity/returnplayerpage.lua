local ReturnPlayerPage = class("UI.Activity.ReturnPlayerPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")

function ReturnPlayerPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.userInfo = {}
  self.achieveData = {}
  self.dayNum = 1
  self.curDay = 1
end

function ReturnPlayerPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.userInfo = Data.userData:GetUserData()
  self.achieveData = Data.taskData:GetTaskReturnData()
  self.curDay = self.userInfo.TaskReturnStage
  self.dayNum = self.userInfo.TaskReturnStage
  local tabContentInfo = configManager.GetData("config_return_stage")
  if self.curDay > #tabContentInfo then
    self.curDay = #tabContentInfo
  end
  self:_LoadDayNum()
  local index
  local toggleIndex = Logic.taskReturnLogic:GetReturnPlayerToggle()
  if toggleIndex == nil then
    index = self.curDay
  else
    index = toggleIndex
  end
  Logic.taskReturnLogic:SetReturnDay(index)
  self:_ShowDayInfo(self, tabContentInfo[index])
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[index].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[index].description)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  Logic.taskReturnLogic:SetReturnDayActivity(false)
  eventManager:SendEvent(LuaEvent.ReturnPlayerReddotCallBack)
  self.m_timer = self:CreateTimer(function()
    self:_TickCharge()
  end, 0.5, -1, false)
  self:StartTimer(self.m_timer)
end

function ReturnPlayerPage:_TickCharge()
  local actOpenTime = Data.userData:GetUserData().LastActivityReturnTime
  local duration = 86400 * configManager.GetDataById("config_activity", self.activityId).p7[1]
  local overTime = actOpenTime + duration
  local lastTime = overTime - time.getSvrTime()
  UIHelper.SetText(self.tab_Widgets.tx_time, time.getTimeStringFontDynamic(lastTime))
end

function ReturnPlayerPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_loginGet, self._ClickLoginGet, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_shop, self._ClickBtnShop, self)
  self:RegisterEvent(LuaEvent.GetReturnPlayerReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._OnUpdataTaskList, self)
end

function ReturnPlayerPage:_OnUpdataTaskList(args)
  local tabContentInfo = configManager.GetData("config_return_stage")
  local selectTog = Logic.taskReturnLogic:GetReturnDay()
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function ReturnPlayerPage:_OnGetReward(args)
  for v, k in pairs(args) do
    Logic.rewardLogic:ShowCommonReward(k, "ReturnPlayerPage", nil)
  end
  local tabContentInfo = configManager.GetData("config_return_stage")
  local selectTog = Logic.taskReturnLogic:GetReturnDay()
  self.achieveData = Data.taskData:GetTaskReturnData()
  stage = Data.userData:GetUserData().TaskReturnStage
  if self.curDay ~= stage and stage <= #tabContentInfo then
    self.curDay = stage
    selectTog = stage
    self:_LoadDayNum()
  end
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function ReturnPlayerPage:_LoadDayNum()
  self.tabPartInfo = {}
  local tabContentInfo = configManager.GetData("config_return_stage")
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dayItem, self.tab_Widgets.trans_dayItem, #tabContentInfo, function(index, tabPart)
    self:RegisterRedDot(tabPart.red_Dot, tabContentInfo[index].id)
    table.insert(self.tabPartInfo, tabPart)
    local str = tabContentInfo[index].name
    tabPart.tx_dayNum.text = str
    tabPart.tx_selected_dayNum.text = str
    UIHelper.SetImage(tabPart.im_numIcon, tabContentInfo[index].icon)
    if index <= self.userInfo.TaskReturnStage then
      tabPart.im_over:SetActive(false)
    else
      tabPart.im_over:SetActive(true)
    end
    tabPart.tx_num.gameObject:SetActive(tabContentInfo[index].count ~= 0)
    UIHelper.SetImage(tabPart.im_quality, tabContentInfo[index].bg)
    UIHelper.SetText(tabPart.tx_num, tabContentInfo[index].count)
    if index <= self.userInfo.TaskReturnStage then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        self:_ShowDayInfo(self, tabContentInfo[index])
      end)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        noticeManager:OpenTipPage(self, UIHelper.GetString(800007))
      end)
    end
  end)
end

function ReturnPlayerPage:_ShowDayInfo(go, award)
  self:StopTimer(self.timer)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  Logic.taskReturnLogic:SetReturnPlayerToggle(award.id)
  local tabContentInfo = configManager.GetData("config_return_stage")
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
  self.dayNum = award.id
  local loginInfo = configManager.GetDataById("config_task_return", award.task_stage)
  Logic.taskReturnLogic:SetReturnDay(self.dayNum)
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[self.dayNum].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[self.dayNum].description)
  self:_LoadLoginReward(loginInfo.rewards)
  self:_LoadItemInfo(award)
end

function ReturnPlayerPage:_LoadLoginReward(rewardId)
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
  local args = configManager.GetDataById("config_return_stage", self.dayNum)
  local logintabReward = {}
  table.insert(logintabReward, args.task_stage)
  local tabAchieve = Logic.taskReturnLogic:GetReturnByDays(logintabReward, self.achieveData)
  if tabAchieve[1].status == TaskState.RECEIVED then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330006)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  elseif tabAchieve[1].status == TaskState.TODO then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  else
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    if self.curDay >= self.dayNum then
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_huang")
    else
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
    end
  end
end

function ReturnPlayerPage:_ShowItemInfo(go, award)
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

function ReturnPlayerPage:_LoadItemInfo(award)
  local tabAchieve = Logic.taskReturnLogic:GetReturnByDays(award.task_return, self.achieveData)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemInfo, self.tab_Widgets.trans_itemInfo, #tabAchieve, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_des, tabAchieve[index].config.desc)
    UIHelper.SetText(tabPart.tx_num, tabAchieve[index].progressStr)
    if tabAchieve[index].status == TaskState.TODO then
      local isJump = TaskOperate.ReturnPlayerIsJump(tabAchieve[index].config.goal[1], tabAchieve[index].config.go_up_to)
      tabPart.btn_anniu.gameObject:SetActive(isJump)
      tabPart.tx_num.gameObject:SetActive(isJump)
    else
      tabPart.btn_anniu.gameObject:SetActive(true)
      tabPart.tx_num.gameObject:SetActive(true)
    end
    if tabAchieve[index].status == TaskState.RECEIVED then
      tabPart.im_anniu.gameObject:SetActive(false)
    end
    tabPart.tx_num.gameObject:SetActive(true)
    tabPart.im_get.gameObject:SetActive(tabAchieve[index].status == TaskState.RECEIVED)
    if tabAchieve[index].status == TaskState.TODO then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(800005))
      UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_hui")
    elseif tabAchieve[index].status == TaskState.FINISH then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330007))
      if self.dayNum <= self.userInfo.TaskReturnStage then
        UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_huang")
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

function ReturnPlayerPage:_NewPlayerCall(go, args)
  if args.status == TaskState.TODO then
    TaskOperate.TaskJumpByKind(args.config.goal[1], args.config.go_up_to)
  elseif args.status == TaskState.FINISH then
    local name = configManager.GetDataById("config_return_stage", self.dayNum).name
    if self.dayNum <= self.userInfo.TaskReturnStage then
      local reward = {
        TaskId = args.achieveId,
        TaskType = TaskType.Return,
        Day = self.dayNum
      }
      Service.taskService:SendTaskRewardReturn(reward)
    else
      noticeManager:OpenTipPage(self, name .. UIHelper.GetString(920000092))
    end
  end
end

function ReturnPlayerPage:_ClickLoginGet()
  local args = configManager.GetDataById("config_return_stage", self.dayNum)
  local tabReward = {}
  table.insert(tabReward, args.task_stage)
  local tabAchieve = Logic.taskReturnLogic:GetReturnByDays(tabReward, self.achieveData)
  if self.dayNum <= self.userInfo.TaskReturnStage and tabAchieve[1].status == TaskState.FINISH then
    local reward = {
      TaskId = args.task_stage,
      TaskType = TaskType.Return,
      Day = self.dayNum
    }
    Service.taskService:SendTaskRewardReturn(reward)
  elseif tabAchieve[1].status == TaskState.RECEIVED then
    noticeManager:OpenTipPage(self, UIHelper.GetString(330006))
  else
    local name = configManager.GetDataById("config_return_stage", self.dayNum).name
    local str = string.format(UIHelper.GetString(800006), name)
    noticeManager:OpenTipPage(self, str)
  end
end

function ReturnPlayerPage:_ClickBtnShop()
  self.activityId = self:GetParam().activityId
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
    return
  end
  local activityData = configManager.GetDataById("config_activity", self.activityId)
  moduleManager:JumpToFunc(FunctionID.Shop, activityData.shop_id)
end

function ReturnPlayerPage:DoOnClose()
  Logic.taskReturnLogic:SetReturnPlayerToggle(nil)
end

return ReturnPlayerPage
