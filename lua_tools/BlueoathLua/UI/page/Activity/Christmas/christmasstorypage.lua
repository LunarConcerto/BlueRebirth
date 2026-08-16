local ChristmasStoryPage = class("ui.page.Activity.Christmas.ChristmasStoryPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local plotCopyDetailPage = require("ui.page.Copy.PlotCopyDetailPage")

function ChristmasStoryPage:DoInit()
end

function ChristmasStoryPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ChristmasStoryPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetCopyData, self.ShowPage, self)
end

function ChristmasStoryPage:DoOnHide()
end

function ChristmasStoryPage:DoOnClose()
end

function ChristmasStoryPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTimeFormat .. "-" .. endTimeFormat)
  self.mPlotList = activityCfg.p1
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentStory, self.tab_Widgets.itemStory, #self.mPlotList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemStoryPart(index, part)
    end
  end)
end

function ChristmasStoryPage:updateItemStoryPart(index, part)
  local plotData = self.mPlotList[index]
  local copyId = plotData[1]
  local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyId)
  UIHelper.SetText(part.textName, copyDisplayCfg.name)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local isUnlock = copyData ~= nil
  local isNewCopy = copyData ~= nil and copyData.FirstPassTime <= 0 or copyData == nil
  part.objLockBg:SetActive(not isUnlock)
  part.objClear:SetActive(copyData ~= nil and copyData.FirstPassTime > 0)
  local isStory = copyDisplayCfg.copy_display_type ~= 1
  part.objImgStory:SetActive(isStory)
  part.objImgBattle:SetActive(not isStory)
  UIHelper.SetImage(part.itemIcon, copyDisplayCfg.copy_thumbnail_before)
  UGUIEventListener.AddButtonOnClick(part.btnItem, function()
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

return ChristmasStoryPage
