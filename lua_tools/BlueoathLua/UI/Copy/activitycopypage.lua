local ActivityCopyPage = class("UI.Copy.ActivityCopyPage", LuaUIPage)
local tabPageInfo = {
  {
    name = "PlotCopyDetailPage",
    title = "uipic_ui_copy_fo_juqing",
    icon = "uipic_ui_bigact_story",
    functionId = FunctionID.ActPlotCopy,
    mark = true
  },
  {
    name = "SeaCopyPage",
    title = "uipic_ui_copy_fo_haiyu",
    icon = "uipic_ui_bigact_copy_sea",
    functionId = FunctionID.ActSeaCopy,
    mark = true
  },
  {
    name = "MeritPage",
    title = "uipic_ui_bigactivity_fo_paihang",
    icon = "uipic_ui_bigact_copy_rank",
    functionId = FunctionID.Rank,
    mark = true
  },
  {
    name = "ShopPage",
    title = "uipic_ui_bigactivity_fo_shangdian",
    icon = "uipic_ui_bigact_copy_shop",
    functionId = FunctionID.Shop,
    mark = false
  }
}
local TogIndex = {
  Plot = 0,
  Sea = 1,
  Rank = 2,
  Shop = 3
}

function ActivityCopyPage:DoInit()
  self.actId = 0
  self.tablePart = {}
end

function ActivityCopyPage:RegisterAllEvent()
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_togGroup, self, "", self._SwitchTogs)
  self:RegisterEvent(LuaEvent.UpdateActivity, self._CheckActPeriod, self)
  self:RegisterEvent(LuaEvent.GetCopyData, function()
    self:_CheckActPeriod()
  end, self)
end

function ActivityCopyPage:DoOnOpen()
  self:OpenTopPage("ActivityCopyPage", 2, UIHelper.GetString(1001002), self, true)
  if self.param and self.param.enter == ActEnter.Memory then
    self.enter = ActEnter.Memory
    self:DoOnOpenMemory()
  else
    self.enter = ActEnter.Normal
    self:DoOnOpenNormal()
  end
end

function ActivityCopyPage:DoOnOpenNormal()
  local activityData = Logic.activityLogic:GetOpenActivityByTypes(ActivityType.Festival, ActivityType.BigActivity)
  if #activityData <= 0 then
    UIHelper.ClosePage("PlotCopyDetailPage")
    UIHelper.ClosePage("SeaCopyPage")
    UIHelper.ClosePage("MeritPage")
    UIHelper.ClosePage("ExRankPage")
    UIHelper.ClosePage("ShopPage")
    UIHelper.ClosePage("ActivityCopyPage")
    UIHelper.ClosePage("TopPage")
    UIHelper.OpenPage("HomePage")
    noticeManager:OpenTipPage(self, UIHelper.GetString(270022))
    return
  end
  SoundManager.Instance:PlayMusic("System|Expedition_bigActivity")
  local actId = self.param and self.param.activityId
  self.actId = actId or Logic.activityLogic:GetOpenBigActivity()
  self:initTabPage()
  self.activityConfig = configManager.GetDataById("config_activity", self.actId)
  self:_CreateTog()
  local index = self.param and self.param.index or Logic.activityLogic:GetBigActivityIndex(self.actId)
  index = index or TogIndex.Sea
  index = self:checkIndex(index + 1) and index or TogIndex.Rank
  self.tab_Widgets.tog_togGroup:SetActiveToggleIndex(index)
end

function ActivityCopyPage:checkIndex(nIndex)
  local info = self.tabPageInfo[nIndex]
  local functionId = info.functionId
  local param = self:getFunctionParam(functionId)
  return Logic.functionCheckLogic:Check(functionId, false, param)
end

function ActivityCopyPage:DoOnOpenMemory()
  self.tab_Widgets.Bottom:SetActive(false)
  self:OpenSubPage("PlotCopyDetailPage", {
    enter = ActEnter.Memory,
    chapterId = self.param.chapterId
  })
end

function ActivityCopyPage:_CheckActPeriod()
  if self.enter == ActEnter.Memory then
    return
  end
  for nIndex, tabPart in ipairs(self.tablePart) do
    self:_ShowTogPart(nIndex, tabPart)
  end
  local index = Logic.copyLogic:GetActSelectTog()
  index = self:checkIndex(index + 1) and index or TogIndex.Rank
  self.tab_Widgets.tog_togGroup:SetActiveToggleIndex(index)
end

function ActivityCopyPage:_CreateTog()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_togItem, self.tab_Widgets.trans_tog, #self.tabPageInfo, function(nIndex, tabPart)
    local info = self.tabPageInfo[nIndex]
    local functionId = info.functionId
    UIHelper.SetImage(tabPart.img_icon, self.tabPageInfo[nIndex].icon)
    UIHelper.SetImage(tabPart.img_title, self.tabPageInfo[nIndex].title)
    self.tab_Widgets.tog_togGroup:RegisterToggle(tabPart.tog)
    local param = self:getFunctionParam(functionId)
    local isOpen = Logic.functionCheckLogic:Check(functionId, false, param)
    tabPart.ImgOver:SetActive(not isOpen)
    self:_ShowTogPart(nIndex, tabPart)
    self.tablePart[nIndex] = tabPart
  end)
end

function ActivityCopyPage:_ShowTogPart(nIndex, tabPart)
  local info = self.tabPageInfo[nIndex]
  local functionId = info.functionId
  local param = self:getFunctionParam(functionId)
  local isOpen = Logic.functionCheckLogic:Check(functionId, false, param)
  tabPart.ImgOver:SetActive(not isOpen)
  if not Logic.functionCheckLogic:Check(functionId, false, param) then
    self.tab_Widgets.tog_togGroup:ResigterToggleUnActive(nIndex - 1, function()
      Logic.functionCheckLogic:Check(functionId, true, param)
    end)
  else
    self.tab_Widgets.tog_togGroup:RemoveToggleUnActive(nIndex - 1)
  end
  self.tablePart[nIndex] = tabPart
end

function ActivityCopyPage:_SwitchTogs(index)
  local info = self.tabPageInfo[index + 1]
  if info.mark then
    Logic.activityLogic:SetBigActivityIndex(self.actId, index)
  end
  local functionId = info.functionId
  local functionParam = self:getFunctionParam(functionId)
  if not Logic.functionCheckLogic:Check(functionId, true, functionParam) then
    return
  end
  for _, pageName in pairs(self.tabPageInfo) do
    if UIPageManager:IsExistPage(pageName.name) then
      UIHelper.ClosePage(pageName.name)
    end
  end
  local pageName = info.name
  local param
  if functionId == FunctionID.Shop then
    param = {shopId = functionParam, isActivity = true}
  elseif functionId == FunctionID.Rank then
    Logic.copyLogic:SetActSelectTog(index)
    local activityConfig = configManager.GetDataById("config_activity", self.actId)
    if activityConfig.type == ActivityType.BigActivity or activityConfig.type == ActivityType.NFestival then
      pageName = "ExRankPage"
    end
  else
    Logic.copyLogic:SetActSelectTog(index)
    param = {
      CopyDisplayType.ActivityCopy,
      self.actId
    }
  end
  if functionId == FunctionID.Shop then
    local ftimer = FrameTimer.New(function()
      UIHelper.OpenPage(pageName, param)
    end, 1, 1)
    ftimer:Start()
  else
    self:OpenSubPage(pageName, param)
  end
end

function ActivityCopyPage:getFunctionParam(functionId)
  if functionId == FunctionID.ActPlotCopy then
    return self.activityConfig.plot_type
  elseif functionId == FunctionID.ActSeaCopy then
    return self.activityConfig.seacopy_type
  elseif functionId == FunctionID.Rank then
    return self.activityConfig.rank_id
  elseif functionId == FunctionID.Shop then
    return self.activityConfig.shop_id
  end
end

function ActivityCopyPage:initTabPage()
  self.tabPageInfo = {}
  self.activityConfig = configManager.GetDataById("config_activity", self.actId)
  if self.activityConfig.plot_type > 0 then
    table.insert(self.tabPageInfo, tabPageInfo[TogIndex.Plot + 1])
  end
  if 0 < self.activityConfig.seacopy_type then
    table.insert(self.tabPageInfo, tabPageInfo[TogIndex.Sea + 1])
  end
  if 0 < self.activityConfig.rank_id then
    table.insert(self.tabPageInfo, tabPageInfo[TogIndex.Rank + 1])
  end
  if 0 < self.activityConfig.shop_id then
    table.insert(self.tabPageInfo, tabPageInfo[TogIndex.Shop + 1])
  end
end

function ActivityCopyPage:DoOnHide()
  self.tab_Widgets.tog_togGroup:ClearToggles()
end

function ActivityCopyPage:DoOnClose()
  self.tab_Widgets.tog_togGroup:ClearToggles()
end

return ActivityCopyPage
