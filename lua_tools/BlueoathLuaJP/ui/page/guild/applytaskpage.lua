local ApplyTaskPage = class("UI.Guild.ApplyTaskPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ApplyTaskPage:DoInit()
end

function ApplyTaskPage:DoOnOpen()
  self:ShowPage()
end

function ApplyTaskPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCloseTip, self.onBtnCloseTipClick, self)
  self:RegisterEvent(LuaEvent.PAGE_GUILDTASK_ACCEPT, self.ShowPage, self)
end

function ApplyTaskPage:DoOnHide()
end

function ApplyTaskPage:DoOnClose()
end

function ApplyTaskPage:ShowPage()
  self.mCanApplyTaskList = Data.guildtaskData:GetUserCurrentCanAcceptTaskList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentTaskList, self.tab_Widgets.itemTask, #self.mCanApplyTaskList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateTaskPart(index, part)
    end
  end)
end

function ApplyTaskPage:updateTaskPart(index, part)
  local taskId = self.mCanApplyTaskList[index]
  local cfg = configManager.GetDataById("config_task_guild", taskId)
  UIHelper.SetText(part.txtName, cfg.desc)
  UIHelper.SetText(part.txtExtraReward, cfg.extra_reward_desc)
  UIHelper.SetLocText(part.textContriNum, 710078, cfg.per_contr_num)
  UIHelper.SetLocText(part.textExpNum, 710078, cfg.guild_exp_rewards)
  part.objNumPart:SetActive(false)
  if cfg.type == EnumGuildTaskType.Donate then
    part.objNumPart:SetActive(true)
    local havenum = Logic.guildtaskLogic:GetDonateItemNum(cfg.id)
    UIHelper.SetText(part.textHaveNum, havenum)
  end
  local rewards = Logic.rewardLogic:FormatRewardById(cfg.guild_rewards)
  UIHelper.CreateSubPart(part.objRewardTemplate, part.transRewardList, #rewards, function(nIndex, tabPart)
    local rewarditem = rewards[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId))
    end)
  end)
  UGUIEventListener.AddButtonOnClick(part.btnApply, self.btnApplyOnClick, self, {
    TaskId = cfg.id,
    Cfg = cfg
  })
end

function ApplyTaskPage:onBtnCloseTipClick()
  UIHelper.ClosePage("ApplyTaskPage")
end

function ApplyTaskPage:btnApplyOnClick(go, param)
  local postCfg = Logic.guildLogic:GetUserPostConfig()
  local todayacceptnum = Data.guildtaskData:GetUserTodayAcceptTaskCount()
  if todayacceptnum >= postCfg.apply_task_num then
    noticeManager:ShowTipById(710024)
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildtaskService:SendAcceptTask({
          TaskId = param.TaskId
        })
        UIHelper.ClosePage("ApplyTaskPage")
      end
    end
  }
  local cfg = param.Cfg
  local content = UIHelper.GetLocString(710020, cfg.title)
  noticeManager:ShowMsgBox(content, tabParams)
end

return ApplyTaskPage
