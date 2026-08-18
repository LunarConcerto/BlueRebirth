local ActivityGalgameCopyPage = class("UI.Activity.Galgame.ActivityGalgameCopyPage", LuaUIPage)
local PlotState = {NotPass = 0, Pass = 1}

function ActivityGalgameCopyPage:DoInit()
  self.timerEffect = nil
end

function ActivityGalgameCopyPage:DoOnOpen()
  self.actId = self.param and self.param.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.actId)
  self:_UpdateCopyInfo()
end

function ActivityGalgameCopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.UpdateCopyExtraInfo, self.ShowChristmasPlot, self)
end

function ActivityGalgameCopyPage:_UpdateCopyInfo()
  self:ShowChristmasPlot()
end

function ActivityGalgameCopyPage:_ShowPlot()
  local chapterInfo = configManager.GetDataById("config_chapter", self.actConfig.p1[1])
  local plotCopyIdTab = Logic.activityGalgameLogic:GetGalgamePlotCopy(self.actConfig.p1[1], self.actConfig.p5)
  local recoredPlotTab = Logic.activityGalgameLogic:GetRecoredId()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_plotItem, self.tab_Widgets.trans_plot, #plotCopyIdTab, function(nIndex, luaPart)
    local plotCopyInfo = Logic.copyLogic:GetCopyDesConfig(plotCopyIdTab[nIndex])
    luaPart.trans_plot.anchoredPosition3D = Vector2.New(chapterInfo.copy_pos_x[nIndex], chapterInfo.copy_pos_y[nIndex])
    UIHelper.SetText(luaPart.tx_name, plotCopyInfo.name)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_plot, self._OpenPlot, self, plotCopyInfo.id)
    luaPart.obj_ending:SetActive(#plotCopyInfo.branch_id > 0)
    local isOpen = self:_CheckPlotOpen(plotCopyInfo.id)
    if isOpen and recoredPlotTab[plotCopyInfo.id] == nil then
      Logic.activityGalgameLogic:RecordPlotId(plotCopyInfo.id)
    end
    local imgBg = isOpen and plotCopyInfo.activity_plot_bg or plotCopyInfo.plot_bg_lock
    UIHelper.SetImage(luaPart.im_plot, imgBg, true)
    if 2 <= nIndex then
      local i = nIndex - 1
      local lineObj = self.tab_Widgets["obj_plotLine" .. i]
      lineObj:SetActive(isOpen)
    end
    luaPart.trans_ending.gameObject:SetActive(isOpen)
    UIHelper.CreateSubPart(luaPart.obj_endItem, luaPart.trans_ending, #plotCopyInfo.branch_id, function(index, part)
      local branchId = plotCopyInfo.branch_id[index]
      local endState = Data.copyData:GetPlotEndBranch(branchId)
      local color = endState == PlotState.NotPass and "90334c" or "ffffff"
      UIHelper.SetTextColor(part.tx_endName, "END" .. index, color)
      part.obj_locked:SetActive(false)
    end)
  end)
end

function ActivityGalgameCopyPage:_CheckPlotOpen(plotId)
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

function ActivityGalgameCopyPage:_OpenPlot(go, plotId)
  local open, msg = self:_CheckPlotOpen(plotId)
  if not open then
    noticeManager:OpenTipPage(self, msg)
    return
  end
  self.tab_Widgets.obj_effect:SetActive(true)
  self.timerEffect = self:CreateTimer(function()
    self.tab_Widgets.obj_effect:SetActive(false)
    self:StopTimer(self.timerEffect)
    plotManager:OpenPlotByType(PlotTriggerType.plot_copy_display_trigger, plotId)
  end, 0.81, 1)
  self:StartTimer(self.timerEffect)
end

function ActivityGalgameCopyPage:_ShowCopy()
  local seaCopyTab = self.actConfig.p2
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyItem, self.tab_Widgets.trans_copy, #seaCopyTab, function(nIndex, luaPart)
    local seaCopyInfo = Logic.copyLogic:GetChaperConfById(seaCopyTab[nIndex])
    local posTab = self.actConfig.p4[nIndex]
    luaPart.trans_copy.anchoredPosition3D = Vector2.New(posTab[1], posTab[2])
    local passPlot, _ = Logic.activityGalgameLogic:CheckOpenLimit(seaCopyInfo.id)
    local imgBg = passPlot and seaCopyInfo.plot_copy_cover or seaCopyInfo.plot_locked
    UIHelper.SetImage(luaPart.im_copy, imgBg, true)
    UIHelper.SetText(luaPart.tx_copyname, seaCopyInfo.name)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_copy, self._OpenSeaCopy, self, seaCopyInfo.id)
  end)
end

function ActivityGalgameCopyPage:_OpenSeaCopy(go, chapterId)
  local passPlot, msg = Logic.activityGalgameLogic:CheckOpenLimit(chapterId)
  if not passPlot then
    noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(6100016), msg))
    return
  end
  local uid = Data.userData:GetUserData().Uid
  local seaCopyInfo = Logic.copyLogic:GetChaperConfById(chapterId)
  PlayerPrefs.SetInt(uid .. "SeaCopyPage" .. seaCopyInfo.class_type, chapterId)
  UIHelper.OpenPage("SeaCopyPage", {
    nil,
    self.actId
  })
end

function ActivityGalgameCopyPage:ShowChristmasPlot()
  local plotCopyIdTab = Logic.activityGalgameLogic:GetGalgamePlotCopy_Extra(self.actConfig.p1[1], self.actConfig.p5)
  local recoredPlotTab = Logic.activityGalgameLogic:GetRecoredId()
  for idx = 1, #plotCopyIdTab do
    if self.tab_Widgets["btn_story" .. idx] then
      local plotCopyInfo = Logic.copyLogic:GetCopyDesConfig(plotCopyIdTab[idx])
      UIHelper.SetText(self.tab_Widgets["txt_storyName" .. idx], plotCopyInfo.name)
      
      local function clickFunc()
        self:OpenChristmasPlot(plotCopyInfo.id)
      end
      
      UGUIEventListener.AddButtonOnClick(self.tab_Widgets["btn_story" .. idx], clickFunc)
      local isOpen = self:_CheckPlotOpen(plotCopyInfo.id)
      if isOpen and recoredPlotTab[plotCopyInfo.id] == nil then
        Logic.activityGalgameLogic:RecordPlotId(plotCopyInfo.id)
      end
      if idx == 2 then
        self.tab_Widgets.obj_storyEnding:SetActive(#plotCopyInfo.branch_id > 0)
        UIHelper.CreateSubPart(self.tab_Widgets.obj_endItem, self.tab_Widgets.trans_end, #plotCopyInfo.branch_id, function(index, part)
          local branchId = plotCopyInfo.branch_id[index]
          local endState = Data.copyData:GetPlotEndBranch(branchId)
          UIHelper.SetText(part.tx_endName, "END" .. index)
          part.obj_locked:SetActive(endState ~= PlotState.Pass)
        end)
      end
    end
  end
end

function ActivityGalgameCopyPage:OpenChristmasPlot(plotId)
  local open, msg = self:_CheckPlotOpen(plotId)
  if not open then
    noticeManager:OpenTipPage(self, msg)
    return
  end
  plotManager:OpenPlotByType(PlotTriggerType.plot_copy_display_trigger, plotId)
end

function ActivityGalgameCopyPage:_ClickClose()
  UIHelper.ClosePage("ActivityGalgameCopyPage")
end

function ActivityGalgameCopyPage:DoOnHide()
  self:_StopTimer()
end

function ActivityGalgameCopyPage:DoOnClose()
  self:_StopTimer()
end

function ActivityGalgameCopyPage:_StopTimer()
  if self.timerEffect ~= nil then
    self:StopTimer(self.timerEffect)
    self.timerEffect = nil
  end
end

return ActivityGalgameCopyPage
