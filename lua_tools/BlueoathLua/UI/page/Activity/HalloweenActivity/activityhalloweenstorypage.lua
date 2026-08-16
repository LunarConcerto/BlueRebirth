local ActivityHalloweenStoryPage = class("ui.page.Activity.HalloweenActivity.ActivityHalloweenStoryPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local plotCopyDetailPage = require("ui.page.Copy.PlotCopyDetailPage")

function ActivityHalloweenStoryPage:DoInit()
end

function ActivityHalloweenStoryPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ActivityHalloweenStoryPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetCopyData, self.ShowPage, self)
end

function ActivityHalloweenStoryPage:DoOnHide()
end

function ActivityHalloweenStoryPage:DoOnClose()
end

function ActivityHalloweenStoryPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  self.mPlotList = activityCfg.p1
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentStory, self.tab_Widgets.itemStory, #self.mPlotList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemStoryPart(index, part)
    end
  end)
  local curCandy = Data.bagData:GetItemNum(HalloweenStoryCandyItemId)
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, HalloweenStoryCandyItemId)
  UIHelper.SetImage(self.tab_Widgets.imgCandy, display.icon_small)
  UIHelper.SetText(self.tab_Widgets.textCandy, "x" .. curCandy)
  local iteracItemCfgs = configManager.GetData("config_interaction_item")
  local rewardids = {}
  for _, interacItemCfg in pairs(iteracItemCfgs) do
    if interacItemCfg.reward > 0 then
      table.insert(rewardids, interacItemCfg.reward)
    end
  end
  local candySum = 0
  local rewards = Logic.rewardLogic:FormatRewards(rewardids)
  for _, rewarddata in ipairs(rewards) do
    if rewarddata.ConfigId == HalloweenStoryCandyItemId then
      candySum = rewarddata.Num
    end
  end
  UIHelper.SetLocText(self.tab_Widgets.textRefresh, 7600003, curCandy, candySum)
end

function ActivityHalloweenStoryPage:updateItemStoryPart(index, part)
  local plotData = self.mPlotList[index]
  local copyId = plotData[1]
  local requireCandy = plotData[2]
  local curCandy = Data.bagData:GetItemNum(HalloweenStoryCandyItemId)
  local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyId)
  UIHelper.SetText(part.textStoryTitle, copyDisplayCfg.name)
  UIHelper.SetText(part.textStoryTitleLock, copyDisplayCfg.name)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local isUnlock = requireCandy <= curCandy
  local isNewCopy = copyData ~= nil and copyData.FirstPassTime <= 0 or copyData == nil
  part.objImgStoryBg:SetActive(isUnlock)
  part.objImgStoryLockBg:SetActive(not isUnlock)
  part.btnStart.gameObject:SetActive(isUnlock)
  part.objImgCandy:SetActive(not isUnlock)
  part.objImgNew:SetActive(isUnlock and isNewCopy)
  if not isUnlock then
    local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, HalloweenStoryCandyItemId)
    UIHelper.SetImage(part.imgCandy, display.icon_small)
    UIHelper.SetText(part.textCandyNumber, "x" .. requireCandy)
  end
  UGUIEventListener.AddButtonOnClick(part.btnStart, function()
    local chapterTypeCfg = configManager.GetDataById("config_chapter_type", ChapterType.HalloweenPlot)
    if chapterTypeCfg.function_id > 0 and not moduleManager:CheckFunc(chapterTypeCfg.function_id, true) then
      return
    end
    if copyData == nil then
      noticeManager:OpenTipPage(self, UIHelper.GetString(7600006))
    else
      if Logic.copyLogic:CheckEquipBagFull() then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(toEquip)
            if toEquip then
              UIHelper.ClosePage("NoticePage")
              UIHelper.OpenPage("DismantlePage")
            end
          end
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(1000014), tabParams)
        return
      end
      if copyDisplayCfg.copy_display_type == 1 then
        local isHasFleet = Logic.fleetLogic:IsHasFleet()
        if not isHasFleet then
          noticeManager:OpenTipPage(self, 110007)
          return
        end
        plotCopyDetailPage:_OpenLevelPage(copyData, copyId)
      else
        plotCopyDetailPage:_OpenPlotPage(copyData.BaseId)
      end
    end
  end)
end

return ActivityHalloweenStoryPage
