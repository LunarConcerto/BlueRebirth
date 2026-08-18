local TaskRewardPage = class("UI.Guild.TaskRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TaskRewardPage:DoInit()
end

function TaskRewardPage:DoOnOpen()
  self:ShowPage()
end

function TaskRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.onBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnConfirm, self.onBtnCloseClick, self)
end

function TaskRewardPage:DoOnHide()
end

function TaskRewardPage:DoOnClose()
end

function TaskRewardPage:ShowPage()
  self.mTodayRandomPoolList = Data.guildtaskData:GetTodayRandomRewardInfo()
  self.mTodayFinishTaskCount = Data.guildtaskData:GetTodayFinishTaskCount()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentRewardList, self.tab_Widgets.itemTemplate, #self.mTodayRandomPoolList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateRewardInfoPart(index, part)
    end
  end)
end

function TaskRewardPage:updateRewardInfoPart(index, part)
  local rewardinfo = self.mTodayRandomPoolList[index]
  UIHelper.SetLocText(part.textTitle, 710072, rewardinfo.EnterNum)
  part.objImgAlreadyGet:SetActive(self.mTodayFinishTaskCount >= rewardinfo.EnterNum)
  local rewards = Logic.rewardLogic:FormatRewardById(rewardinfo.RewardId)
  UIHelper.CreateSubPart(part.objRewardTemplate, part.rectRewardList, #rewards, function(nIndex, tabPart)
    local rewarditem = rewards[nIndex]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.textNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
end

function TaskRewardPage:onBtnCloseClick()
  UIHelper.ClosePage("TaskRewardPage")
end

return TaskRewardPage
