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
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.bu_goto, self._ClickShop, self)
end

function ChristmasStoryPage:DoOnHide()
end

function ChristmasStoryPage:DoOnClose()
end

function ChristmasStoryPage:_ClickShop()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local shopId = activityCfg.shop_id
  UIHelper.OpenPage("ShopPage", {shopId = shopId})
end

function ChristmasStoryPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.tx_time, startTimeFormat .. "-" .. endTimeFormat)
  self.mPlotList = activityCfg.p1
  UIHelper.CreateSubPart(self.tab_Widgets.itemStory, self.tab_Widgets.trans_content, #activityCfg.p1, function(index, uiPart)
    local index = tonumber(index)
    self:updateItemStoryPart(index, uiPart, activityCfg)
  end)
end

function ChristmasStoryPage:updateItemStoryPart(index, part, activityCfg)
  local plotData = activityCfg.p1[index]
  local copyId = plotData[1]
  local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyId)
  UIHelper.SetText(part.textName, copyDisplayCfg.name)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local isUnlock = copyData ~= nil
  local isNewCopy = copyData ~= nil and copyData.FirstPassTime <= 0 or copyData == nil
  part.obj_lockBg:SetActive(not isUnlock)
  part.objClear:SetActive(copyData ~= nil and copyData.FirstPassTime > 0)
  local isStory = copyDisplayCfg.copy_display_type ~= 1
  part.objImgStory:SetActive(isStory)
  part.objImgBattle:SetActive(not isStory)
  UIHelper.SetImage(part.itemIcon, activityCfg.p2[index])
  UIHelper.SetImage(part.img_lock, activityCfg.p3[index])
  part.btnItem.gameObject.transform.localPosition = Vector3.New(activityCfg.p4[index], activityCfg.p5[index], 0)
  part.btnItem.gameObject.transform.localScale = Vector3.New(activityCfg.p6[index], activityCfg.p6[index], 1)
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
