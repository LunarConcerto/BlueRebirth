local SeaCopyActivityPage = class("UI.Copy.SeaCopyActivityPage")
local plotCopyDetailPage = require("ui.page.Copy.PlotCopyDetailPage")

function SeaCopyActivityPage:Init(owner, widgets, actId)
  self.actId = actId
  local type = configManager.GetDataById("config_activity", self.actId).type
  if type ~= ActivityType.Actyishi then
    return
  end
  self.page = owner
  self.widgetsTab = widgets
  self.mPlotList = {}
  self.copyList = {}
  self.plotList = {}
  self.px, self.py = {}
  self.copy_thumbnail_before = {}
  self.copy_thumbnail_after = {}
  self.activityConfig = {}
  self.lasttTog = 0
  self:RegisterAllEvent()
  self:InitToggle()
  self:ShowPage()
end

function SeaCopyActivityPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_actcopy, self._ClickShop, self)
  eventManager:RegisterEvent(LuaEvent.GetCopyData, self.ShowPlot, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_rewardrandom, self._RewardRandom, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_buffdetail, self._BuffDetail, self)
end

function SeaCopyActivityPage:_ClickShop()
end

function SeaCopyActivityPage:ClickLimitClose()
  if self.page == nil or self.widgetsTab == nil then
    return
  end
  local lastToggle = Logic.copyLogic:GetSeaCopyActivityToggleLast()
  self:SetToggle(lastToggle)
end

function SeaCopyActivityPage:_RewardRandom()
  self.activityOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.RewardRandom)
  if self.activityOpen then
    local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.RewardRandom)
    if actId == nil or actId <= 0 then
      return
    end
    local pagename = configManager.GetDataById("config_activity", actId).banner_gotopage_activity
    UIHelper.OpenPage(pagename, {activityId = actId})
  end
end

function SeaCopyActivityPage:_BuffDetail()
  Logic.activityExtractLogic:_ClickShowDetail()
end

function SeaCopyActivityPage:_ClickLimitClose()
  self.widgetsTab.obj_open:SetActive(false)
end

function SeaCopyActivityPage:ShowPage()
  self.widgetsTab.btn_rewardrandom.gameObject:SetActive(true)
  self.widgetsTab.btn_buffdetail.gameObject:SetActive(true)
  self.widgetsTab.tran_actcopy.gameObject:SetActive(true)
  local tog = Logic.copyLogic:GetSeaCopyActivityToggle()
  self.widgetsTab.toggle_actcopy:SetActiveToggleIndex(tog)
end

function SeaCopyActivityPage:ShowPlot()
  local widgets = self.widgetsTab
  if #self.copyList == 0 or #self.plotList == 0 or #self.px == 0 or #self.py == 0 then
    self.copyList, self.plotList, self.px, self.py = self:_GetCurTogListByP()
  end
  local curtoggle = self:GetToggle() + 1
  self.mPlotList = self.plotList[curtoggle]
  self.mPx = self.px[curtoggle]
  self.mPy = self.py[curtoggle]
  local recoredPlotTab = Logic.activityGalgameLogic:GetRecoredId()
  UIHelper.CreateSubPart(widgets.im_one_2, widgets.Content2, #self.mPlotList, function(index, part)
    local copyId = self.mPlotList[index]
    local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyId)
    UIHelper.SetText(part.tx_name, copyDisplayCfg.name)
    part.im_area:SetActive(true)
    part.im_area.transform.anchoredPosition3D = Vector2.New(self.mPx[index], self.mPy[index])
    local copyData = Data.copyData:GetCopyInfoById(copyId)
    if copyData == nil then
      part.im_area:SetActive(false)
      return
    end
    if copyData.FirstPassTime == 0 then
      UIHelper.SetImage(part.im_icon, self.copy_thumbnail_before[curtoggle][index])
    else
      UIHelper.SetImage(part.im_icon, self.copy_thumbnail_after[curtoggle][index])
    end
    local isOpen = self:_CheckPlotOpen(copyId)
    if isOpen == false then
      part.im_area:SetActive(false)
      return
    end
    if isOpen and recoredPlotTab[copyId] == nil then
      Logic.activityGalgameLogic:RecordPlotId(copyId)
    end
    UGUIEventListener.AddButtonOnClick(part.btn_fun, function()
      local chapterTypeCfg = configManager.GetDataById("config_chapter_type", self.plotType)
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
  end)
end

function SeaCopyActivityPage:_CheckPlotOpen(plotId)
  local copyData = Data.copyData:GetCopyInfoById(plotId)
  local copyPlotConfig = Logic.copyLogic:GetCopyDesConfig(plotId)
  local startTime, _ = PeriodManager:GetPeriodTime(copyPlotConfig.activity_period, copyPlotConfig.activity_period_area)
  local startTimeFormat = time.formatTimerToYMDH(startTime)
  local serverTime = time.getSvrTime()
  if startTime > serverTime then
    local str = string.format(UIHelper.GetString(6100015), startTimeFormat)
    return false, str
  end
  if copyData == nil then
    local str = UIHelper.GetString(961002)
    return false, str
  end
  return true
end

function SeaCopyActivityPage:SetToggle(toggle)
  Logic.copyLogic:SetSeaCopyActivityToggle(toggle)
end

function SeaCopyActivityPage:GetToggle()
  return Logic.copyLogic:GetSeaCopyActivityToggle()
end

function SeaCopyActivityPage:InitToggle()
  local widgets = self.widgetsTab
  self.copyList, self.plotList, self.px, self.py = self:_GetCurTogListByP()
  UIHelper.CreateSubPart(widgets.btn_actcopy, widgets.tran_actcopy, #self.copyList, function(index, luaPart)
    local chapterid = self.copyList[index]
    local chapterConfig = configManager.GetDataById("config_chapter", chapterid)
    UIHelper.SetText(luaPart.Text, chapterConfig.name)
    widgets.toggle_actcopy:RegisterToggle(luaPart.btn_actcopy)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.toggle_actcopy, self, nil, function(go, index)
    Logic.copyLogic:SetSeaCopyActivityToggleLast(self:GetToggle())
    self:SetToggle(index)
    self:ShowPlot()
    eventManager:SendEvent(LuaEvent.UpdateActSeaCopyToggle, {
      self.copyList[index + 1],
      self.plotList[index + 1]
    })
  end)
end

function SeaCopyActivityPage:_GetCurTogListByP()
  local activityConfig = configManager.GetDataById("config_activity", self.actId)
  self.activityConfig = activityConfig
  self.copyType = activityConfig.seacopy_type
  self.plotType = activityConfig.plot_type
  local copyList = activityConfig.p2
  local plotList = activityConfig.p1
  local px = activityConfig.p3
  local py = activityConfig.p4
  self.copy_thumbnail_before = activityConfig.p5
  self.copy_thumbnail_after = activityConfig.p6
  return copyList, plotList, px, py
end

function SeaCopyActivityPage:DoOnHide()
  self.m_tabWidgets.toggle_actcopy:ClearToggles()
end

function SeaCopyActivityPage:DoOnClose()
  self.m_tabWidgets.toggle_actcopy:ClearToggles()
end

return SeaCopyActivityPage
