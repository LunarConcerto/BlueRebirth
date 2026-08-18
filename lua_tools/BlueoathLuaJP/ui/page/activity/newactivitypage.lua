local NewActivityPage = class("UI.Activity.NewActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.Task.TaskOperate")
local togName = {
  3702002,
  3702003,
  3702004,
  3702005
}

function NewActivityPage:DoInit()
  self.bigActPeriod = {}
  self.selectPeriodIdx = 1
end

function NewActivityPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self.OnBtnHelpClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rank, self.OnBtnRankClick, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self.UpdateTaskData, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self.ShowReward, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActPointsData, self.ShowPointsInfo, self)
  self:RegisterEvent(LuaEvent.UpdateGuildBigActItemsData, self.ShowItemInfo, self)
end

function NewActivityPage:DoOnOpen()
  self.bigActPeriod = Logic.guildLogic:GetBigActPeriod()
  self:CreatActstage()
  self:ShowPointsInfo()
  self:ShowItemInfo()
  self:UpdateTaskData()
end

function NewActivityPage:CreatActstage()
  self.tab_Widgets.group_base:ClearToggles()
  local actCfg = Logic.guildLogic:GetBigActCfg()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_baseItem, self.tab_Widgets.trans_baseRoot, #actCfg.period_area, function(index, uiPart)
    if self.bigActPeriod[index] ~= nil then
      UIHelper.SetText(uiPart.txt_desc, UIHelper.GetString(togName[index]))
      UIHelper.SetText(uiPart.txt_checkDesc, UIHelper.GetString(togName[index]))
      local startStr, endStr = Logic.guildLogic:GetBigActPeriodTime(index)
      local timeStr = string.format(UIHelper.GetString(3702007), startStr, endStr)
      UIHelper.SetText(uiPart.txt_time, timeStr)
      UIHelper.SetText(uiPart.txt_checkTime, timeStr)
      self.tab_Widgets.group_base:RegisterToggle(uiPart.tog_clickTog)
      local isIn = Logic.guildLogic:CheckBigActPeriodGetReward(index)
      if not isIn then
        self.tab_Widgets.group_base:ResigterToggleUnActive(index - 1, function()
          noticeManager:OpenTipPage(self, 3702006)
        end)
      end
      self:RegisterRedDot(uiPart.dot_reward, index)
    else
      uiPart.gameObject:SetActive(false)
    end
    if index == self.selectPeriodIdx then
      uiPart.tog_clickTog.isOn = true
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_base, self, "", self.SwitchTogs)
end

function NewActivityPage:SwitchTogs(togIndex)
  local index = togIndex + 1
  self.selectPeriodIdx = index
  self:CreateTaskList()
end

function NewActivityPage:CreateTaskList()
  local bigActData = Data.guildData:GetGuildBigActivityData()
  local taskList = bigActData:GetTaskListByIdx(self.selectPeriodIdx)
  local isIn = Logic.guildLogic:CheckBigActIsInPeriod(self.selectPeriodIdx)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_taskItem, self.tab_Widgets.trans_taskContent, #taskList, function(index, uiPart)
    local data = taskList[index]
    UIHelper.SetText(uiPart.txt_des, data.Config.desc)
    uiPart.obj_numDes:SetActive(data.FinishNum > 1)
    local finishStr = ""
    if data.FinishNum > 1 then
      finishStr = data.FinishNum
    end
    UIHelper.SetText(uiPart.txt_num, finishStr)
    local strProgress = data.Count .. "/" .. data.Config.goal[#data.Config.goal]
    if data.RewardTime > 0 then
      uiPart.btn_getReward.gameObject:SetActive(false)
      uiPart.obj_get:SetActive(true)
      uiPart.btn_goto.gameObject:SetActive(false)
      uiPart.obj_over:SetActive(false)
      UIHelper.SetText(uiPart.txt_progress, "")
      uiPart.obj_progress:SetActive(false)
    elseif 0 < data.FinishTime then
      uiPart.btn_getReward.gameObject:SetActive(true)
      uiPart.obj_get:SetActive(false)
      uiPart.btn_goto.gameObject:SetActive(false)
      uiPart.obj_over:SetActive(false)
      UIHelper.SetText(uiPart.txt_progress, strProgress)
      uiPart.obj_progress:SetActive(true)
      UGUIEventListener.AddButtonOnClick(uiPart.btn_getReward, self.GetTaskReward, self, data)
    else
      uiPart.btn_getReward.gameObject:SetActive(false)
      uiPart.obj_get:SetActive(false)
      uiPart.btn_goto.gameObject:SetActive(true)
      uiPart.obj_over:SetActive(not isIn)
      UIHelper.SetText(uiPart.txt_progress, strProgress)
      uiPart.obj_progress:SetActive(true)
      UGUIEventListener.AddButtonOnClick(uiPart.btn_goto, self.GoToTask, self, data.Config)
    end
    local rewards = configManager.GetDataById("config_rewards", data.Config.reward).rewards
    UIHelper.CreateSubPart(uiPart.obj_rewardsItem, uiPart.trans_rewards, #rewards, function(index2, uiPart2)
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

function NewActivityPage:UpdateTaskData()
  local bigActData = Data.guildData:GetGuildBigActivityData()
  bigActData:ResetTaskList()
  self:CreateTaskList()
end

function NewActivityPage:ShowPointsInfo()
  local itemId = Logic.guildLogic:GetBigActScoreItem()
  local itemCfg = configManager.GetDataById("config_item_info", itemId)
  UIHelper.SetImage(self.tab_Widgets.img_scoreItem, itemCfg.icon)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_scoreItem, self.ShowItemDetail, self, itemId)
  local bigData = Data.guildData:GetGuildBigActivityData()
  local score = bigData:GetUserPoints()
  UIHelper.SetText(self.tab_Widgets.txt_score, score)
end

function NewActivityPage:ShowItemInfo()
  local itemId = Logic.guildLogic:GetBigActMultipleItem()
  local itemCfg = configManager.GetDataById("config_item_info", itemId)
  UIHelper.SetImage(self.tab_Widgets.img_reward, itemCfg.icon)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self.ShowItemDetail, self, itemId)
  local bigData = Data.guildData:GetGuildBigActivityData()
  local num = bigData:GetItemNum()
  UIHelper.SetText(self.tab_Widgets.txt_reward, num)
end

function NewActivityPage:ShowItemDetail(go, param)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.ITEM, param))
end

function NewActivityPage:OnBtnHelpClick()
  UIHelper.OpenPage("HelpPage", {content = 3702008})
end

function NewActivityPage:OnBtnRankClick()
  local inGuild = Data.guildData:inGuild()
  if inGuild then
    UIHelper.OpenPage("ActivityRankPage")
  else
    noticeManager:ShowTipById(710055)
  end
end

function NewActivityPage:GetTaskReward(go, param)
  Service.taskService:SendTaskReward(param.TaskId, param.Type)
end

function NewActivityPage:GoToTask(go, param)
  TaskOperate.TaskJumpByKind(param.goal[1], param.go_up_to)
end

function NewActivityPage:ShowReward(args)
  if args.TaskType ~= TaskType.GuildBigAct or #args.Rewards <= 0 then
    return
  end
  local res = {}
  for _, v in pairs(args.Rewards) do
    local temp = {}
    temp.Type = v.Type
    temp.ConfigId = v.ConfigId
    temp.Num = v.Num
    temp.Id = v.Id
    table.insert(res, temp)
  end
  UIHelper.OpenPage("GetRewardsPage", {Rewards = res})
end

function NewActivityPage:DoOnHide()
end

function NewActivityPage:DoOnClose()
end

return NewActivityPage
