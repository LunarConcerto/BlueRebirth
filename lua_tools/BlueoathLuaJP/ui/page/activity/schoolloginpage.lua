require("ui.page.Activity.ActivityNewYearPage")
local super = require("ui.page.Activity.ActivityNewYearPage")
local SchoolLoginPage = class("UI.Activity.SchoolLoginPage", super)

function SchoolLoginPage:RegisterAllEvent()
  super.RegisterAllEvent(self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._ShowSignDayNum, self)
end

function SchoolLoginPage:DoOnOpen()
  super.DoOnOpen(self)
  self:_ShowSignDayNum()
end

function SchoolLoginPage:OnClickSign(param)
  super.OnClickSign(self, param)
  local status = param[1]
  local taskInfo = param[2]
  local activityConfig = configManager.GetDataById("config_activity", self.activityId)
  if activityConfig.period > 0 and not PeriodManager:IsInPeriodArea(activityConfig.period, activityConfig.period_area) then
    return
  end
  if status == TaskState.FINISH then
    Service.taskService:SendTaskReward(taskInfo.TaskId, TaskType.Activity)
  end
end

function SchoolLoginPage:ShowDayNum(part, index)
  UIHelper.SetText(part.tx_daynum, index)
end

function SchoolLoginPage:_ShowSignDayNum()
  local arrTaskId = self.actConfig.p4
  local signdaynum = 0
  local currSignDay = -1
  for i, taskId in ipairs(arrTaskId) do
    local status = Logic.taskLogic:GetTaskFinishState(taskId, TaskType.Activity)
    if status == TaskState.RECEIVED then
      signdaynum = signdaynum + 1
    end
    if status == TaskState.TODO and currSignDay == -1 then
      currSignDay = i - 1
      currSignDay = currSignDay == 0 and 1 or currSignDay
      self.tabParts[currSignDay].obj_today:SetActive(true)
    end
  end
  UIHelper.SetText(self.tab_Widgets.textSignNum, signdaynum)
  if currSignDay == -1 then
    self.tabParts[#arrTaskId].obj_today:SetActive(true)
  end
end

return SchoolLoginPage
