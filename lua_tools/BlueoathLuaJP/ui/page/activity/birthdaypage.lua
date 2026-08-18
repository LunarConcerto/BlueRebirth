local BirthdayPage = class("UI.Activity.BirthdayPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local Formula = {
  flour = 1,
  fruit = 2,
  cake = 3
}

function BirthdayPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.showTask = false
  self.m_popObj = nil
  self.m_rectTranArr = {}
  self.lastPos = nil
  self.isClickCard = false
  self.chooseCakeId = 0
  self.ishelp = false
end

function BirthdayPage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.mActivityId = params.activityId
  local Idata = Data.activityBirthdayData:GetBirthdayFreshData()
  if not Idata then
    if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
      noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
    else
      Service.activityBirthdayService:GetBirthdayRefresh()
    end
  else
    self:_ShowPage()
  end
  Logic.activityBirthdayLogic:SetBirthdayCakeDot(false)
  eventManager:SendEvent(LuaEvent.BirthdayCakePageOpen)
end

function BirthdayPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateBirthdayInfo, self._ShowPage, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.FetchRewardBox, self._ShowPage, self)
  self:RegisterEvent(LuaEvent.GetFeedReward, self._GetFeedReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_task, self._ClickShowTask, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickCloseTask, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickShowHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closehelp, self._ClickCloseHelp, self)
end

function BirthdayPage:_ShowPage()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.m_affair = Data.activityBirthdayData:GetBirthdayaffairInfo()
  self.m_teams = Data.activityBirthdayData:GetBirthdayteamsInfo()
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(actData.period, actData.period_area)
  UIHelper.SetText(self.tab_Widgets.tx_time, time.formatTimeToMDHM(startTime) .. "-" .. time.formatTimeToMDHM(endTime))
  self:_ShowTeams()
  self:_ShowAffair()
  self:_ShowFormula()
  self:_ShowTasks()
  self:_ShowHelp()
end

function BirthdayPage:_ShowTeams()
  self.m_teams = Data.activityBirthdayData:GetBirthdayteamsInfo()
  local infoA = self.m_teams[BirthdayTeams.A] or {}
  local girlA = configManager.GetDataById("config_item_info", infoA.girl)
  local cakeA = configManager.GetDataById("config_item_info", infoA.cake)
  UIHelper.SetImage(self.tab_Widgets.girlA, girlA.icon)
  UIHelper.SetImage(self.tab_Widgets.im_cakeA, cakeA.icon)
  local strA = string.format(UIHelper.GetString(4200010), cakeA.name)
  UIHelper.SetText(self.tab_Widgets.TextA, strA)
  local infoB = self.m_teams[BirthdayTeams.B] or {}
  local girlB = configManager.GetDataById("config_item_info", infoB.girl)
  local cakeB = configManager.GetDataById("config_item_info", infoB.cake)
  UIHelper.SetImage(self.tab_Widgets.girlB, girlB.icon)
  UIHelper.SetImage(self.tab_Widgets.im_cakeB, cakeB.icon)
  local strB = string.format(UIHelper.GetString(4200010), cakeB.name)
  UIHelper.SetText(self.tab_Widgets.TextB, strB)
end

function BirthdayPage:_ShowFormula()
  local actConfig = configManager.GetDataById("config_activity", self.mActivityId)
  local formulaList = actConfig.p4
  local languageList = actConfig.p3
  UIHelper.CreateSubPart(self.tab_Widgets.obj_makecake, self.tab_Widgets.trans_cake, #formulaList, function(index, tabPart)
    local info = formulaList[index]
    UIHelper.SetImage(tabPart.im_cake, configManager.GetDataById("config_item_info", info[Formula.cake]).icon)
    UIHelper.SetImage(tabPart.im_flour, configManager.GetDataById("config_item_info", info[Formula.flour]).icon)
    UIHelper.SetImage(tabPart.im_fruit, configManager.GetDataById("config_item_info", info[Formula.fruit]).icon)
    UIHelper.SetText(tabPart.tx_numcake, Logic.bagLogic:GetBagItemNum(info[Formula.cake]))
    UIHelper.SetText(tabPart.tx_numflour, "x" .. Logic.bagLogic:GetBagItemNum(info[Formula.flour]))
    UIHelper.SetText(tabPart.tx_numfruit, "x" .. Logic.bagLogic:GetBagItemNum(info[Formula.fruit]))
    UIHelper.SetImage(tabPart.im_bg, configManager.GetDataById("config_item_info", info[Formula.cake]).shop_bg)
    tabPart.im_Gray.Gray = Logic.bagLogic:GetBagItemNum(info[Formula.cake]) <= 0
    UIHelper.SetText(tabPart.tx_explain, UIHelper.GetString(languageList[index]))
    if Logic.bagLogic:GetBagItemNum(info[Formula.cake]) > 0 then
      self:_SetDrag(tabPart, info[Formula.cake])
    else
      self:_SetClick(tabPart, info[Formula.cake])
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_flour, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.ITEM, info[Formula.flour]))
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fruit, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.ITEM, info[Formula.fruit]))
    end)
    if 0 < Logic.bagLogic:GetBagItemNum(info[Formula.fruit]) and 0 < Logic.bagLogic:GetBagItemNum(info[Formula.flour]) then
      tabPart.btn_get.gameObject:SetActive(false)
      tabPart.btn_make.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_make, function()
        if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
          noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
        else
          local tab = {CakeFormula = index}
          Service.activityBirthdayService:MakeBirthdayCake(tab, tab)
        end
      end)
    else
      tabPart.btn_get.gameObject:SetActive(true)
      tabPart.btn_make.gameObject:SetActive(false)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_get, function()
        self:_ClickShowTask()
      end)
    end
  end)
end

function BirthdayPage:_ShowAffair()
  local affairList = configManager.GetDataById("config_activity", self.mActivityId).p5
  local Max = affairList[1][1]
  local cur = self.m_affair
  self.tab_Widgets.Slider.size = cur / Max
  local iconList = configManager.GetDataById("config_activity", self.mActivityId).p7
  local ReceiveInfo = Data.activityBirthdayData:GetBirthdayReceiveInfo()
  UIHelper.CreateSubPart(self.tab_Widgets.rewardItem, self.tab_Widgets.RewardBat, #affairList, function(index, tabPart)
    local info = affairList[index]
    local stage = info[1]
    tabPart.tx_stage.gameObject:SetActive(info[2] ~= 0)
    tabPart.trans_reward.gameObject:SetActive(info[2] ~= 0)
    if info[2] ~= 0 then
      UIHelper.SetText(tabPart.tx_stage, stage)
      local rewardState
      local rewards = {}
      if stage <= self.m_affair then
        if ReceiveInfo[stage] then
          rewardState = RewardState.Received
        else
          rewardState = RewardState.Receivable
        end
      else
        rewardState = RewardState.UnReceivable
      end
      UIHelper.SetImage(tabPart.im_bg, iconList[rewardState])
      rewards = Logic.rewardLogic:FormatRewardById(info[2])
      local param = {}
      param.rewardState = rewardState
      param.rewards = rewards
      
      function param.callback()
        if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
          noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
        else
          local tab = {Level = stage}
          Service.activityBirthdayService:GetBirthdayAffairReward(tab, rewards)
        end
      end
      
      UGUIEventListener.AddButtonOnClick(tabPart.btn_bg, self._BtnRewardBox, self, param)
    end
  end)
end

function BirthdayPage:_BtnRewardBox(go, param)
  UIHelper.OpenPage("BoxRewardPage", param)
end

function BirthdayPage:_ShowTasks()
  local widgets = self.tab_Widgets
  widgets.obj_task.gameObject:SetActive(self.showTask)
  if not self.showTask then
    return
  end
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.mActivityId)
  if tabTaskInfo == nil then
    logError("BirthdayPage _ShowTasks tabTaskInfo is nil")
    return
  end
  local sortTaskInfo = Logic.taskLogic:GetSortTaskListByType(tabTaskInfo)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemInfo, self.tab_Widgets.trans_itemInfo, #sortTaskInfo, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_des, sortTaskInfo[index].Config.desc)
    local max = string.split(sortTaskInfo[index].ProgressStr, "/")
    UIHelper.SetText(tabPart.tx_num, "<color=#8be8ff>" .. max[1] .. "</color>" .. "/" .. max[2])
    if sortTaskInfo[index].Data.RewardTime ~= 0 then
      tabPart.im_get.gameObject:SetActive(false)
      UIHelper.SetText(tabPart.tx_num, "<color=#8be8ff>" .. max[2] .. "</color>" .. "/" .. max[2])
    else
      tabPart.im_get.gameObject:SetActive(true)
    end
    tabPart.im_get.gameObject:SetActive(sortTaskInfo[index].Data.RewardTime ~= 0)
    tabPart.btn_go.gameObject:SetActive(sortTaskInfo[index].State == TaskState.TODO and 0 < sortTaskInfo[index].Config.go_up_to)
    tabPart.btn_fetch.gameObject:SetActive(sortTaskInfo[index].State == TaskState.FINISH)
    local dropAloneTab = configManager.GetDataById("config_drop_item", sortTaskInfo[index].Config.drop_id).drop_alone[1]
    local tmp_show = {}
    local tmp_dropAlone = {
      dropAloneTab[1],
      dropAloneTab[2],
      dropAloneTab[3]
    }
    table.insert(tmp_show, tmp_dropAlone)
    local tmp_drop = {
      GoodsType.ITEM,
      configManager.GetDataById("config_activity", self.mActivityId).p6[1],
      1
    }
    table.insert(tmp_show, tmp_drop)
    if #tmp_show ~= 0 then
      UIHelper.CreateSubPart(tabPart.obj_rewardItem, tabPart.trans_rewardItem, #tmp_show, function(nIndex, luaPart)
        local reward = tmp_show[nIndex]
        local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
        UIHelper.SetImage(luaPart.im_quality, QualityIcon[rewardInfo.quality])
        UIHelper.SetImage(luaPart.im_loginIcon, tostring(rewardInfo.icon))
        UIHelper.SetText(luaPart.tx_rewardNum, reward[3])
        local tmp = {
          Type = reward[1],
          ConfigId = reward[2]
        }
        UGUIEventListener.AddButtonOnClick(luaPart.btn_look, self._ShowItemInfo, self, tmp)
      end)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_go, self.btn_go, self, sortTaskInfo[index])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fetch, self.btn_fetch, self, sortTaskInfo[index])
  end)
end

function BirthdayPage:btn_go(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  moduleManager:JumpToFunc(args.Config.go_up_to, table.unpack(args.Config.go_up_to_parm))
end

function BirthdayPage:btn_fetch(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function BirthdayPage:_GetBirthdayTaskReward(go, args)
  if args.State == TaskState.TODO then
    TaskOperate.TaskJumpByKind(args.Config.goal[1], args.Config.go_up_to)
  elseif args.State == TaskState.FINISH then
    local ok, msg = Logic.taskLogic:CheckGetReward(args.Data)
    if not ok then
      noticeManager:ShowTip(msg)
      return
    end
    Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
  end
end

function BirthdayPage:_ClickShowTask()
  if self.showTask == false then
    self.showTask = true
  end
  self:_ShowPage()
end

function BirthdayPage:_ClickCloseTask()
  if self.showTask == true then
    self.showTask = false
  end
  self:_ShowPage()
end

function BirthdayPage:_SetDrag(tabPart, cakeId)
  UGUIEventListener.AddButtonOnPointDown(tabPart.obj_cake, function()
    self:OnDragCard(tabPart, cakeId)
  end)
  UGUIEventListener.AddButtonOnPointUp(tabPart.obj_cake, function()
    if self.m_popObj ~= nil then
      self.tab_Widgets.obj_float:SetActive(false)
      self:ClickFleetCard(tabPart, cakeId)
    end
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.obj_cake, function()
  end)
end

function BirthdayPage:_SetClick(tabPart, cakeId)
  UGUIEventListener.AddButtonOnPointDown(tabPart.obj_cake, function()
  end)
  UGUIEventListener.AddButtonOnPointUp(tabPart.obj_cake, function()
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.obj_cake, function()
    self.isClickCard = true
    self:ClickFleetCard(tabPart, cakeId)
  end)
end

function BirthdayPage:ClickFleetCard(tabPart, cakeId)
  if self.isClickCard then
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.ITEM, cakeId))
  end
  if self.isClickCard and self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    self.m_popObj = nil
  end
  self.isClickCard = true
end

function BirthdayPage:OnDragCard(tabPart, cakeId)
  self.isClickCard = false
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    if self.btnDrag ~= nil then
      UGUIEventListener.ClearDragListener(self.btnDrag)
      self.btnDrag = nil
    end
  end
  self.chooseCakeId = cakeId
  self.m_popObj = nil
  self.tab_Widgets.obj_float:SetActive(true)
  self.m_popObj = UIHelper.CreateGameObject(tabPart.obj_cake, self.tab_Widgets.tran_float)
  self.tab_Widgets.tran_float.position = tabPart.obj_cake.transform.position
  self.m_popObj.transform.pivot = Vector2.New(0.5, 0.5)
  self.m_popObj.transform.position = Vector3.New(tabPart.obj_cake.transform.position.x - 10, tabPart.obj_cake.transform.position.y - 10, 0)
  self:AddCardDrag(tabPart.obj_cake, self.m_popObj.transform, cakeId)
  self.btnDrag = tabPart.obj_cake
end

function BirthdayPage:AddCardDrag(objDrag, dragTran, cakeId)
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if self.m_popObj == nil then
      return
    end
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    dragTran.position = worldPos
    self:_DragCard(dragPos, camera)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    UGUIEventListener.ClearDragListener(objDrag)
    local camera = eventData.pressEventCamera
    local dragPos = eventData.position
    self:_UpdateCake(dragPos, camera, cakeId)
    self.btnDrag = nil
  end, nil, nil)
  self.isClickCard = true
end

function BirthdayPage:_UpdateCake(objPos, camera, cakeId)
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
    self.tab_Widgets.obj_float:SetActive(false)
    self.m_popObj = nil
  end
  local widgets = self:GetWidgets()
  if widgets.rectTran_girlA:RectangleContainsScreenPoint(objPos, camera) or widgets.rectTran_girlB:RectangleContainsScreenPoint(objPos, camera) then
    self.curPos = self:GetPos(objPos, camera)
    self:FeedGirl(self.curPos, cakeId)
  else
    return
  end
end

function BirthdayPage:_DragCard(objPos, camera)
  self.isClickCard = false
  local widgets = self:GetWidgets()
  local pos = self:GetPos(objPos, camera)
  if widgets.rectTran_girlA:RectangleContainsScreenPoint(objPos, camera) or widgets.rectTran_girlB:RectangleContainsScreenPoint(objPos, camera) then
    self.lastPos = pos
  end
end

function BirthdayPage:GetPos(objPos, camera)
  local widgets = self:GetWidgets()
  if widgets.rectTran_girlA:RectangleContainsScreenPoint(objPos, camera) then
    return 1
  elseif widgets.rectTran_girlB:RectangleContainsScreenPoint(objPos, camera) then
    return 2
  end
  return 0
end

function BirthdayPage:FeedGirl(curPos, cakeId)
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
  else
    local infoA = self.m_teams[curPos]
    local tab = {TeamId = curPos, Cake = cakeId}
    local tab1 = {
      Cake = clone(cakeId),
      trueCake = clone(infoA.cake)
    }
    Service.activityBirthdayService:FeedBirthdayCake(tab, tab1)
  end
end

function BirthdayPage:_ShowItemInfo(go, award)
  if award.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
  end
end

function BirthdayPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "BirthdayPage")
  self:_ShowPage()
end

function BirthdayPage:_ShowTips(taskInfo)
  eventManager:SendEvent(LuaEvent.ShowRewardTaskEffect, taskInfo)
end

function BirthdayPage:_GetFeedReward(state)
  local tcake = state.trueCake
  local cake = state.Cake
  local affair = 1
  if cake == tcake then
    affair = 2
  end
  noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(4200007), affair))
end

function BirthdayPage:_ClickShowHelp()
  if self.ishelp == false then
    self.ishelp = true
  end
  self:_ShowPage()
end

function BirthdayPage:_ClickCloseHelp()
  if self.ishelp == true then
    self.ishelp = false
  end
  self:_ShowPage()
end

function BirthdayPage:_ShowHelp()
  local widgets = self.tab_Widgets
  widgets.obj_help.gameObject:SetActive(self.ishelp)
end

function BirthdayPage:DoOnClose()
end

return BirthdayPage
