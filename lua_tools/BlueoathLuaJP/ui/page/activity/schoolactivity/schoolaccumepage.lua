local SchoolAccumePage = class("ui.page.Activity.SchoolActivity.SchoolAccumePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local accumuItemId = 17001
local SchoolAccumeFace = {School = 1, Accume = 2}

function SchoolAccumePage:DoInit()
  self.activityId = 0
  self.actConfig = 0
  self.activityType = 0
  self.allTaskInfo = nil
  self.schoolTaskInfo = nil
  self.accumeTaskInfo = nil
  self.m_isClick = false
  self.currFace = SchoolAccumeFace.School
end

function SchoolAccumePage:DoOnOpen()
  local params = self:GetParam() or {}
  self.activityId = params.activityId
  self.activityType = params.activityType
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  accumuItemId = configManager.GetDataById("config_parameter", 362).value
  self.currFace = Logic.residentGameLogic:GetSAFace()
  self:_ShowPage()
  self:_ClickSwitch()
end

function SchoolAccumePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetTaskReward, self.onGetTaskReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_aSwitch, self._ClickSwitch, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_sSwitch, self._ClickSwitch, self)
end

function SchoolAccumePage:_ShowPage()
  self.allTaskInfo = Logic.taskLogic:GetTaskListByTypeWithRewardSort(TaskType.Activity, self.activityId, true)
  if self.allTaskInfo == nil then
    logError("allTaskInfo is nil")
    return
  end
  self.schoolTaskInfo = {}
  self.accumeTaskInfo = {}
  local schoolTaskIdTab = self.actConfig.p1
  local accumeTaskIdTab = self.actConfig.p2
  for _, v in pairs(self.allTaskInfo) do
    for _, schoolTaskId in ipairs(schoolTaskIdTab) do
      if schoolTaskId == v.TaskId then
        table.insert(self.schoolTaskInfo, v)
        break
      end
    end
    for _, accumeTaskId in ipairs(accumeTaskIdTab) do
      if accumeTaskId == v.TaskId then
        table.insert(self.accumeTaskInfo, v)
        break
      end
    end
  end
  local ownCount = Data.bagData:GetItemNum(accumuItemId)
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, accumuItemId)
  UIHelper.SetText(self.tab_Widgets.txt_sItemNum, ownCount)
  UIHelper.SetText(self.tab_Widgets.txt_aItemNum, ownCount)
  self:_ShowSchoolPage()
  self:_ShowAccumePage()
end

function SchoolAccumePage:_ShowSchoolPage()
  if #self.schoolTaskInfo == 0 then
    logError("schoolTaskInfo is nil")
    return
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_sTask, self.tab_Widgets.obj_sItem, #self.schoolTaskInfo, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local taskInfo = self.schoolTaskInfo[index]
      self:updateItemPart(taskInfo, index, part)
    end
  end)
end

function SchoolAccumePage:_ShowAccumePage()
  if #self.accumeTaskInfo == 0 then
    logError("accumeTaskInfo is nil")
    return
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_aTask, self.tab_Widgets.obj_aItem, #self.accumeTaskInfo, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local taskInfo = self.accumeTaskInfo[index]
      self:updateItemPart(taskInfo, index, part)
    end
  end)
end

function SchoolAccumePage:updateItemPart(taskInfo, index, part)
  UIHelper.SetText(part.textProcess, taskInfo.ProgressStr)
  UIHelper.SetText(part.textDesc, taskInfo.Config.desc)
  local rewards = Logic.rewardLogic:FormatRewardById(taskInfo.Config.rewards)
  UIHelper.CreateSubPart(part.objItem, part.rectRewards, #rewards, function(nIndex, luaPart)
    local tabReward = Logic.activityLogic:GetRewardInfo(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    UIHelper.SetImage(luaPart.im_icon, tabReward.icon)
    UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(luaPart.tx_rewardNum, rewards[nIndex].Num)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_icon, self._ClickItem, self, rewards[nIndex])
  end)
  if taskInfo.State == TaskState.TODO then
    part.objGet:SetActive(false)
    part.textProcess.gameObject:SetActive(true)
    part.btnReward.gameObject:SetActive(false)
    if taskInfo.Config.go_up_to > 0 then
      part.btnGoto.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btnGoto, function()
        if not Data.activityData:IsActivityOpen(self.activityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        moduleManager:JumpToFunc(taskInfo.Config.go_up_to, table.unpack(taskInfo.Config.go_up_to_parm))
      end)
    else
      part.btnGoto.gameObject:SetActive(false)
      if part.btnUncom ~= nil then
        part.btnUncom.gameObject:SetActive(true)
      end
    end
  else
    part.btnGoto.gameObject:SetActive(false)
    if part.btnUncom ~= nil then
      part.btnUncom.gameObject:SetActive(false)
    end
    if taskInfo.Data.RewardTime ~= 0 then
      part.objGet:SetActive(true)
      part.btnReward.gameObject:SetActive(false)
    else
      part.objGet:SetActive(false)
      part.textProcess.gameObject:SetActive(true)
      part.btnReward.gameObject:SetActive(true)
      UGUIEventListener.AddButtonOnClick(part.btnReward, function()
        if not Data.activityData:IsActivityOpen(self.activityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        local taskinfo = taskInfo.Data
        Service.taskService:SendTaskReward(taskinfo.TaskId, taskinfo.Type)
      end)
    end
  end
end

function SchoolAccumePage:onGetTaskReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "SchoolAccumePage")
  self:_ShowPage()
end

function SchoolAccumePage:_ClickSwitch()
  self.m_isClick = true
  local animatorArr = self.tab_Widgets.animator:GetComponentsInChildren(UnityEngine_Animator.GetClassType())
  self.m_animList = {}
  for i = 0, animatorArr.Length - 1 do
    table.insert(self.m_animList, animatorArr[i])
  end
  Logic.residentGameLogic:SetSAFace(self.currFace)
  if self.currFace == SchoolAccumeFace.School then
    self.currFace = SchoolAccumeFace.Accume
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("Float", -1)
    end
  else
    self.currFace = SchoolAccumeFace.School
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("Float", 1)
    end
  end
end

function SchoolAccumePage:_ClickItem(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function SchoolAccumePage:DoOnHide()
end

function SchoolAccumePage:DoOnClose()
end

return SchoolAccumePage
